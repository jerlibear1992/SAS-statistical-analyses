/*
Following are examples of simple mixed effects models I helped run to compare effects of 15-weeks of diet bev consumption on
those whose A1Cs are in the average category
*/

libname myfile 'yourpath\bev_study';
*read in, removed id without any value in 3 time points;
proc import datafile="yourpath\bev_study\bg_data_2023.csv" 
  out=raw_data dbms=csv replace;
  getnames=yes;
  guessingrows=10000;
run;

Data avg; /*this has format threemosugar*/
set work.raw_data;
if 1 < sugara1c < 4;
run;

*use avg_bg tested CS,UN, Ar(1),arh(1) ;
proc mixed data=work.avg;
  class arm week id;
  model bgreading = arm week arm*week ;
  repeated week / subject=id type=cs; *AIC=4516.6;
run;
proc mixed data=work.avg;
  class arm week id;
  model bgreading = arm week arm*week ;
  repeated week / subject=id type=un; *AIC=4495.7;
run;
proc mixed data=work.avg;
  class arm week id;
  model bgreading = arm week arm*week ;
  repeated week / subject=id type=ar(1);*AIC=4509.1;
run;
proc mixed data=work.avg;
  class arm week id;
  model bgreading = arm week arm*week ;
  repeated week / subject=id type=arh(1);*AIC=4497.9;
run;
*AIC are close, decided to use unstructured;


*Now let's compare arm 1 v. 2 on cgm over time and at the end of the study;
*unadjusted model;
proc mixed data=work.avg;
  class arm week id ;
  model bgreading = arm week arm*week /solution;
  repeated week / subject=id type=un;
  *estimate 'arm 1 v 2' arm  -1 1 /cl; /* across time  overall difference btw two arms arm2-arm1 */
  lsmeans arm / pdiff cl;
  lsmeans arm*week / cl pdiff ;
 run;

 *adjusted model + print graphs of change over weeks of trial;
 proc mixed data=work.avg;
  class arm week id state gender ;
  model bgreading = arm week arm*week state gender /solution;
  repeated week / subject=id type=un;
  lsmeans arm / pdiff cl;
  lsmeans arm*week / cl pdiff ;
 run;

 proc print data=means1;
run;

ods rtf file='yourpath\bev_study\graphs.rtf';
goptions reset=all;
symbol1 c=blue v=star h=.8 i=j;
symbol2 c=red v=dot h=.8 i=j;
symbol3 c=green v=square h=.8 i=j;
axis1 order=(0 to 8 by 1) label=(a=90 'blood sugar reading');
axis2 order=(0 to 15 by 3) label=('Week');
proc gplot data=means1;
  format estimate 8.;
  plot estimate*week=arm / vaxis=axis1 haxis=axis2;
run; 
quit;
ods rtf close;
