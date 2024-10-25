/*The following is an example of the mixed effects model that we ran as part of the sensitivity analyses of our target trial emulation paper
published in the AJE for looking at physical activity and its effects on body composition.

Of course, sensitive and proprietary var names are changed and no proprietary data has been uploaded*/

libname physactivity "yourpath\JerBear";

data long_final; set physactivity.WHI_physact_dxa; run;

* Generate loess curves over time by treatment groups and let's visually see our outcome with time;

proc sort data=long_final; by modactivitycat id year; run;
proc loess data=long_final;
     by modactivitycat;
     model visceralfat=year / degree=2 smooth = 0.6 1.0;
	 ods output outputstatistics=visceralfatFit;
run;

proc sort data=cd4Fit; by SmoothingParameter modactivitycat year; run;

symbol1 color=green interpol = join width=2 value=none height=3 line=1;
symbol2 color=red interpol = join width=2 value=none height=3 line=2;
symbol3 color=blue interpol = join width=2 value=none height=3 line=20;
symbol4 color=purple interpol = join width=2 value=none height=3 line=43;

proc gplot data=visceralfatFit;
by SmoothingParameter;
plot pred*year=modactivitycat;
run;quit;



/*I only copied the fully adjusted model for this example*/

/*RI only model*/
proc mixed method=reml data=long_final covtest; 
class year(ref="0") education(ref="2") income(ref="1") smoking(ref="0") slept(ref="1") 
      modactivitycat(ref="0") hormone(ref="0") marry(ref="1") racecat(ref="0") ethnicity(ref="0");
model visceralfat = modactivitycat year income racecat ethnicity education marry age
                        slept HEI2015dietscore smoking etohserving hormones ambulatory/s chisq outp=outMOD solution covb;
repeated intercept / type=un subject=id r rcorr;
ods output SolutionF=outparms CovB=mixcovb; 
Run;

/*RIAS model*/
proc mixed method=reml data=long_final covtest; 
class year(ref="0") education(ref="2") income(ref="1") smoking(ref="0") slept(ref="1") 
      modactivitycat(ref="0") hormone(ref="0") marry(ref="1") racecat(ref="0") ethnicity(ref="0");
model visceralfat = modactivitycat year income racecat ethnicity education marry age
                        slept HEI2015dietscore smoking etohserving hormones ambulatory/s chisq outp=outMOD solution covb;
repeated intercept year / type=un subject=id r rcorr;
ods output SolutionF=outparms CovB=mixcovb; 
Run; *tried un, ar(1), cs.... no major differences so kept unstructured;


/*let's see if RIAS is better than RI for first 20 observations*/
proc mixed noclprint=20 data=long_final covtest; 
class year(ref="0") education(ref="2") income(ref="1") smoking(ref="0") slept(ref="1") 
      modactivitycat(ref="0") hormone(ref="0") marry(ref="1") racecat(ref="0") ethnicity(ref="0");
model visceralfat = modactivitycat year income racecat ethnicity education marry age
                        slept HEI2015dietscore smoking etohserving hormones ambulatory/s chisq outp=outMOD solution covb;
random intercept / type=un subject=id G v vcorr;
run;

proc mixed noclprint=20 data=long_final covtest; 
class year(ref="0") education(ref="2") income(ref="1") smoking(ref="0") slept(ref="1") 
      modactivitycat(ref="0") hormone(ref="0") marry(ref="1") racecat(ref="0") ethnicity(ref="0");
model visceralfat = modactivitycat year income racecat ethnicity education marry age
                        slept HEI2015dietscore smoking etohserving hormones ambulatory/s chisq outp=outMOD solution covb;
random intercept year / type=un subject=id G v vcorr ;
run;
