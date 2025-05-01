options validvarname = any;
libname project "/home/u63645818/Stat3120/Final Project]";
proc import datafile = "/home/u63645818/Stat3120/Final Project]/EdStats_v01.xlsx"
	dbms = xlsx
	out = edstats
	replace;
	getnames = yes;
	run;
data project.edstats;
	set work.edstats;
	run;	
data project.tempstats;
	set project.edstats;
	run;
proc sql;
	alter table project.tempstats
      	drop "1970"n, "1971"n, "1972"n, "1973"n, "1974"n, "1975"n, "1976"n, "1977"n, "1978"n, "1979"n, 
      	"1980"n, "1981"n, "1982"n, "1983"n, "1984"n, "1985"n, "1986"n, "1987"n, "1988"n, "1989"n,
      	"1990"n, "1991"n, "1992"n, "1993"n, "1994"n, "1995"n, "1996"n, "1997"n, "1998"n, "1999"n
      	;
quit;
data project.goodstats;
	set project.tempstats;
	if "indicator name"n not in 
	("Expenditure on education as a percentage of total government expenditure (%)",
	"Government expenditure on education as a percentage of GDP (%)",
	"Literacy rate, population 25-64 years, both sexes (%)",
	"Completion rate, upper secondary education, both sexes (%)",
	"Educational attainment rate, completed Bachelor's or equivalent education or 
higher, population 25+ years, both sexes (%)",
	 "Initial household funding per primary student as a 
percentage of GDP per capita",
	"Initial household funding per secondary student as a 
percentage of GDP per capita",
	"Initial household funding per tertiary student as a 
percentage of GDP per capita"
	"Human Capital Index (HCI) (scale 0-1)") then delete;	
PROC freq data=project.goodstats;
	tables "indicator name"n;
	run;
PROC freq data=project.goodstats;
	tables "Country name"n;
	run;
proc means data = project.goodstats
    NMISS missing;
run;
proc mi data=project.goodstats out=outmi;
	mcmc;		 
	run;
*proc mi indicated that the data for 2024 does not yet exist so we drop the the 2024 value;
proc sql;
	alter table project.goodstats
      	drop "2024"n;     	
quit;
data project.goodstatsT;
	set project.goodstats;
	run;
PROC SORT DATA=project.goodstatsT OUT=project.goodstatsT;
    BY "Country name"n "indicator name"n;
RUN;
proc transpose data=project.goodstatsT 
	out=project.goodstatsT;
    by "Country name"n;
    id 'Indicator Name'n;
    run;
proc contents data=project.goodstatsT;
run;
proc means data = project.goodstatsT;
run;
proc mi data=project.goodstatsT out=outmi;
	mcmc;		 
	run;
data project.goodstatsT;
    set project.goodstatsT;
    rename
        "Expenditure on education as a pe"n = GovEdExpendPerTotal
        "Government expenditure on educat"n = GovEdExpendPerGDP
        "Literacy rate, population 25-64"n = LiteracyRate25_64
        "Completion rate, upper secondary"n = CompletionRateUpperSec
        "Educational attainment rate, com"n = BachelorsOrHigher25plus
        "Initial household funding per te"n = HouseholdFundPerTerStudent
        "Initial household funding per pr"n = HouseholdFundPerPriStudent
        "Initial household funding per se"n = HouseholdFundPerSecStudent       
        "Human Capital Index (HCI) (scale"n = HumanCapitalIndex;
run;
proc means data = project.goodstatsT nmiss;
run;
data project.finstats;
	set  project.goodstatsT;
	where _NAME_ = "2018";
	run;
data project.finstats;
	set project.finstats;
	HouseholdFundPerStudent = HouseholdFundPerSecStudent + HouseholdFundPerPriStudent + HouseholdFundPerTerStudent;
	run;
proc means data = project.finstats
    NMISS missing;
run;
proc univariate data = project.finstats cibasic (alpha=.05) normal plot;
var HumanCapitalIndex
	GovEdExpendPerGDP
	GovEdExpendPerTotal;
run;
PROC CORR data= project.finstats pearson plots(maxpoints=10000000)= matrix(histogram);
	var
	HumanCapitalIndex
	GovEdExpendPerGDP
	GovEdExpendPerTotal
	;	
	title 'Correlation Matrix of Raw Data';
	RUN;
PROC REG data= project.finstats;
model HumanCapitalIndex = 
	GovEdExpendPerGDP
	GovEdExpendPerTotal
  	/stb clb vif
  	;
output out=stdres p= predict student=resids;
RUN;
proc univariate data = stdres cibasic (alpha=.05) normal plot;
var resids;
run;
proc means data = stdres;
var resids;
run;
*Chi Code;
proc sql;
   create table project.finstats_chi as
   select GovEdExpendPerGDP ,
          CompletionRateUpperSec
   from   project.finstats;
quit;


proc rank data = project.finstats_chi
          out  = project.finstats_chi
          groups = 3
          ties   = low;
   var   GovEdExpendPerGDP
         CompletionRateUpperSec;
   ranks ExpCat               /* 0 = LOW, 1 = MED, 2 = HIGH   */
         CompCat;
quit;

data project.finstats_chi;
    set project.finstats_chi;
    length ExpCatLabel CompCatLabel $5;

    if ExpCat = 0 then ExpCatLabel = 'LOW';
    else if ExpCat = 1 then ExpCatLabel = 'MED';
    else                 ExpCatLabel = 'HIGH';

    if CompCat = 0 then CompCatLabel = 'LOW';
    else if CompCat = 1 then CompCatLabel = 'MED';
    else                 CompCatLabel = 'HIGH';
run;


proc format;
   value ExpFmt  0 = 'LOW'
                 1 = 'MED'
                 2 = 'HIGH';
run;


proc sort data=project.finstats_chi; by ExpCat; run;


title;
proc sgplot data=project.finstats_chi;
   vbar ExpCatLabel /
        group           = CompCatLabel
        groupdisplay    = cluster;
   xaxis discreteorder=data;        
quit;
title;


proc freq data = project.finstats_chi order=internal;
   tables ExpCat * CompCat /
          chisq expected cellchi2 norow nocol nopercent;
   format ExpCat  ExpFmt.
          CompCat ExpFmt.;
run;

data project.finstats_chi2;
   set project.finstats_chi;
   length Exp2 Comp2 $4;
   Exp2  = ifn(ExpCat = 0, 'LOW', 'HIGH');
   Comp2 = ifn(CompCat = 0, 'LOW', 'HIGH');
run;

proc freq data=project.finstats_chi2;
   tables Exp2 * Comp2 /
          chisq expected cellchi2 norow nocol nopercent;
run;

proc freq data=project.finstats_chi2;



proc freq data=project.finstats_chi order=internal;
   tables ExpCat * CompCat /
          chisq expected cellchi2 norow nocol nopercent;
   format ExpCat  ExpFmt.     /* ExpFmt was created earlier: 0=LOW 1=MED 2=HIGH */
          CompCat ExpFmt.;
quit;

proc univariate data=project.finstats
    var CompletionRateUpperSec;
    output out=StatsSummary
        mean=Mean
        median=Median
        std=StdDev
        skewness=Skewness
        kurtosis=Kurtosis;
run;
