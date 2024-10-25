/**/

libname OUTDIR "yourpath/jerbear/WHI_coxDMASCVD"; *set an output directory;
%let format_library = "yourpath/jerbear/WHI_coxDMASCVD"/whi_dxa_cardiomet_formats"; *pull in WHI formats;
%let SASDATA = "yourpath/jerbear/WHI_coxDMASCVD"/whidxadat"; *pull in wide data;
%let VISITYEAR = 0; *change this based on year of analysis, this one is baseline;

options fmtsearch=(OUTDIR.whi_formats);
PROC OPTIONS OPTION=FMTSEARCH;RUN;
proc format library=OUTDIR.whi_formats;
VALUE racec
     0="White"
     1="Black"
     2="Hispanic";

VALUE EDUCATF
     0="up to high school"
     1="beyond high school up to college"
     2="post-graduate, Master's, Doctoral";
VALUE ALCOHOLF
     0="non-drinker"
     1="past drinker"
     2="current drinker";
VALUE AGEF
     1="<55"
     2="55-59"
     3="60-64"
     4="65-69"
     5="70+";
VALUE BMIF
     1="BMI<25"
     2="25<=BMI<30"
     3="BMI>=30";
RUN;

%macro getCoxBaselineWideDataAnalysis(event, /* event status: 0=censored, 1=event occurred */
timedy, /* Time in days */
covar_interest, /* covariate of interest (one of these): subcutaneousfat, visceralfat */
adjustcovars=, /*list of confounders*/
stratvar=); /*variable used for stratified analyses*/

/* WIDE FORMAT WITH BASELINE (wbvy=&VISITYEAR) DXA calibrated measures */
DATA WORK.CARDIOMETWIDE_wbvy&VISITYEAR;
set &SASDATA;
    /*SUBSET on the visityear of choice: usually at baseline 0, 1, 3 */
	 IF wbvy= &VISITYEAR;


	 /* CREATE TIMEINTERVAL for EVENT of interest*/
	 &timedy.TIME=.;
    if &event=1 then  &timedy.TIME = &timedy;
    else if &event=0 then &timedy.TIME=ENDFOLLOWDY;

    /* create user-defined variables/formats and save dataset to WORK directory*/
    * code racec variable: white is the baseline;
    * create race strat variable;
    racec=.;
    if race=4 then racec=1;
    if race=5 then racec=0;
    if ethnic=1 then racec=2;


   /* education variable */
    EDUCAT=.;
    if 1<=edu<=5 then EDUCAT=0;
    if 6<=edu<=8 then EDUCAT=1;
    if 9<=edu<=11 then EDUCAT=2;

   /* Alcohol categories: 1= non-drinker, 2=past-drinker, 3 to 6=current drinker;*/
    ALCOHOLCAT=.;
    if alc=1 then ALCOHOLCAT=0;
    if alc=2 then ALCOHOLCAT=1;
    if 3<=alc<=6 then ALCOHOLCAT=2;

  /* age stratification variable;*/
    age55=(agec=1);
    age55to59=(agec=2);
    age60to64=(agec=3);
    age65to69=(agec=4);
    agege70 =(agec=5);

   /* BMI category variable;*/
    BMICAT=.;
    if bmi<25 then BMICAT=1;
    if 25<=bmi<30 then BMICAT=2;
    if bmi>=30 then BMICAT=3;
    if bmi=. then BMICAT=.;

    /*format all the user defined variables */

    format racec racecf.;

    format EDUCAT EDUCATF.;
    format ALCOHOLCAT ALCOHOLF.;
    format bmic BMIF.;
    format agec AGEF.;

	 /*keep only variables of interest */
	 keep &event &timedy &timedy.TIME  ENDFOLLOWDY &covar_interest &adjustcovars &stratvar racestrat racenih ethnicnih educ alcohol agestrat bmi;
RUN;

/* first sort &covar_interest by racestrat and get basic means of all covariates*/
proc sort data=WORK.CARDIOMETWIDE_wbvy&VISITYEAR out=WORK.CARDIOMETWIDE_wbvy&VISITYEAR._SORT;
   by &stratvar &covar_interest;
   RUN;
proc stdize data=WORK.CARDIOMETWIDE_wbvy&VISITYEAR._SORT out=WORK.CARDIOMETWIDE_wbvy&VISITYEAR._StdDXA method=std;
   by &stratvar;
   var &covar_interest;
run;
title "Table 1. Summarizing &event Time & Event WIDE Data Set at wbvy=&VISITYEAR";
proc means data=WORK.CARDIOMETWIDE_wbvy&VISITYEAR._StdDXA n nmiss min max median mean std clm maxdec=2 nolabels;
class &stratvar;
   var &event &timedy.TIME &timedy &covar_interest &adjustcovars;
run;

title "Table 2: Hazard ratio for &event event according to &covar_interest at wbvy=&VISITYEAR ";

proc phreg data=WORK.CARDIOMETWIDE_wbvy&VISITYEAR._StdDXA plots(overlay)=(survival);
    class racestrat agestrat;
    by &stratvar;
model &timedy.TIME*&event(0) = &covar_interest &adjustcovars/ RL ; *bodycompvar_1;
hazardratio &covar_interest / CL=BOTH;
ods select ModelInfo ParameterEstimates NObs;
ods trace on;
ods show;
*hazardratio bodycompvar_1 / CL=BOTH;
*baseline covariates=covs out=base / rowid=racestrat;
run;


%mend getCoxBaselineWideDataAnalysis;

/*****************************************/
/* MACRO to iteratively run analyses on all outcomes (if we like) */
/*****************************************/
%macro runall;
    %let outcomelist = diabetes /*afib heartfail coronaryheart stroke tia pad cvdtot*/ ;
	 %let timelist = diabetestime /*afibtime heartfailtime coronaryhearttime stroketime tiatime padtime cvdtottime*/ ;
/*outcomes of interest: T2D, Atherosclerotic CVD, heart failure, stroke, coronary heart disease, TIA, peripheral arterial disease.*/

%local i event;
%do i=1 %to %sysfunc(countw(&outcomelist));
 %let event = %scan(&outcomelist, &i);
%let time = %scan(&timelist, &i);


%getCoxBaselineWideDataAnalysis(&event, 
&time, 
subcutaneousfat, 
adjustcovars=agec bmi educat, 
stratvar=/*racestrat */ );
%getCoxBaselineWideDataAnalysis(&event, 
&time, 
visceralfat, 
adjustcovars=agec bmi educat, 
stratvar=/*racestrat*/);

%end;
%mend runall;


/** output results to RTF file */
ods rtf style=journal file="yourpath/JerBear/outputs.rtf" sasdate;
%runall;
ods rtf close;
