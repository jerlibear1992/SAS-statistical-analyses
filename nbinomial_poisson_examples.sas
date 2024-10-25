/*following example is one lecture from our intro biostatistics course covering differences between negative binomial vs poisson regression
with discrete/count events*/
/*example used is the number of asthma related hospital visits per yr due to a city's population demographics, smoking, and air pollution*/


proc means data = airpoldat;
  var asthmavisit age;
run;

proc univariate data = airpoldat;
  histogram asthmavisit / midpoints = 0 to 100 by 1 vscale = count ;
run;

proc genmod data=airpoldat;
    class gender(ref=0) income(ref=0) smoke(ref=0);
    model asthmavisit = age gender income smoke pm25lvlcat gender*smoke/ dist=negbin link=log;

    ods graphics on;
    lsmeans gender / cl diff;
    lsmeans income / cl diff;
    lsmeans smoke/ cl diff;
run;
ods graphics off;
quit; *with excessive 0's please consider a zero-inflated model;


/*if we do not care about over dispersion, we can also do a simple poisson model*/
proc genmod data=airpoldat;
     class gender(ref=0) income(ref=0) smoke(ref=0);
    model asthmavisit = age gender income smoke pm25lvlcat gender*smoke/ dist=poisson link=log type3;
    output out=diag pred=predict
        resraw=resids reschi=chisqresids resdev=devresides; *get model diagnostics;
    ods graphics on;
run;
ods graphics off;
quit;
