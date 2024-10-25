


%include 'yourpath\JerBear\gformula4.0.sas';
libname CVD 'yourpath\JerBear\dissertationanalysis';
options notes;

*options mprint;
proc import datafile="yourpath\JerBear\CVDraw12232023.csv"
        out=cvddat
        dbms=csv
        replace;
		 getnames=yes;
run;

proc sort data=cvddat; by ID; run;

PROC SQL;
    SELECT COUNT(DISTINCT ID) AS Unique_ID_Count
    INTO :unique_id_count
    FROM cvddat;
QUIT;
%PUT Total Unique ID Count: &unique_id_count; *this uses proc sql to count unique IDs in this dataset;

/*************************************/
/*** Parametric-g formula analysis ***/
/*************************************/

*alcohol intervention: alc = alcohol intake variable, 
categorized into none (0), light (1), moderate (2), heavy (3), and extremely heavy drinking (4);

%let interv1= intno=1, nintvar=1,
    intlabel='All sujects: 0 drinks/d',
    intvar1=alc, inttype1=1, intvalue1=0, inttimes1=0 1 2 3 4 5 6;
%let interv2= intno=2, nintvar=1,
    intlabel='M: 0<alc<=1; W: 0<alc<=0.5',
    intvar1=alc, inttype1=1, intvalue1=1, inttimes1=0 1 2 3 4 5 6;
%let interv3= intno=3, nintvar=1,
    intlabel='M: 1<alc<=2; W: 0.5<alc<=1',
    intvar1=alc, inttype1=1, intvalue1=2, inttimes1=0 1 2 3 4 5 6;
%let interv4= intno=4, nintvar=1,
    intlabel='M: 2<alc<=3; W: 1<alc<=2',
    intvar1=alc, inttype1=1, intvalue1=3, inttimes1=0 1 2 3 4 5 6;
%let interv5= intno=5, nintvar=1,
    intlabel='M: alc > 3; W: alc > 2',
    intvar1=alc, inttype1=1, intvalue1=4, inttimes1=0 1 2 3 4 5 6;

%gformula(data=cvddat,id=ID,time=time,timepoints=7,timeptype=concat,
survdata=work._survdata_all,nsimul=10000,nsamples=500,
outc=cvd,outctype=bineofu,maxipw=1000,censor=censored,compevent=death,compevent_cens=1,
numint=5,refint=0,
fixedcov=alcpb sex race age edpb incpb marrypb bmipb physpb deppb smopb dietpb
diabpb bppb cholpb healthpb hearthxpb pregpb /**/,
ncov=11, 
cov1=edcat, cov1otype=1, cov1ptype=lag1cat,	cov1knots=2 3 4,		
cov2=inccat, cov2otype=1, cov2ptype=lag1cat, cov2knots=2 3 4,			
cov3=mrragecat, cov3otype=1, cov3ptype=lag1cat, cov3knots=2 3,		
cov4=bmi, cov4otype=7, cov4ptype=lag1spl, cov4knots=1 ,			
cov5=physcat, cov5otype=1, cov5ptype=lag1cat, cov5knots=1 2,		
cov6=dep, cov6otype=7, cov6ptype=lag1spl, cov6knots=1 2,			
cov7=smocat, cov7otype=1, cov7ptype=lag1cat, cov7knots=1 2,			
cov8=diet, cov8otype=7, cov8ptype=lag1spl, cov8knots=1,		
cov9=diab, cov9otype=2, cov9ptype=lag1bin, cov9knots=2,
cov10=alc, cov10otype=1, cov10ptype=lag1bin,
cov11=preg, cov11otype=1, cov11ptype=lag1bin); /*risk ratios based on drinking vs natural course: 0.98 1.06 1.11 1.18 1.24*/


/**********************************************************************************************************/
/*** simple logistic regression formula that generates OR based on baseline confounders for sensitivity ***/
/**********************************************************************************************************/

proc logistic data=cvddat_wide;
    class alc(ref='0') edcat(ref='0') inccat(ref='0') mrragecat(ref='0') physcat(ref='0') smocat(ref='0') diab(ref='0') preg(ref='0')
          sex(ref='0') race(ref='0');
    model cvd = alc sex race age edcat inccat mrragecat bmi physcat dep smocat diet diab preg/ expb lackfit 
	; *check goodness of fit and gets us OR;
    
    output out=diag p=pred lower=lcl upper=ucl
        reschi=chisqresid resdev=devresid difchisq=difchisq difdev=difdev
        h=lever;
    ods graphics on;
run;
ods graphics off;
quit;

/*keep in mind the above proc logistic is a very simple stratified analysis... useful for sensitivity but lacks ability to adjust for
time varying confounding*/
