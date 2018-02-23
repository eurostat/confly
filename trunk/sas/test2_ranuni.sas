/* ***********************************************************************
 *a: Application   : LFS                                                  *
 *a:                                                                      *
 *a: Program name  : /ec/prod/server/sas/0lfs/listings/frankb/CELL_KEY_TEST_Q.sas            a*
 **************************************************************************
 *a: Description   :                                                      *

 **************************************************************************
 *a: Output file(s): /ec/prod/server/sas/0lfs/listings/frankb/CELL_KEY_TEST_Q.csv            a*
 *a: -------------------------------------------------------------------- *
 *b:                                                                      *
 *b: created the 01/25/18
 *c: ==================================================================== *
 COUNTRIES : AT,BE,BG,CY,CZ,DE,DK,EE,ES,FI,FR,GR,HR,HU,IE,IT,LT,LU,LV,MT,NL,PL,PT,RO,SE,SI,SK,UK

 YEARS     : 2016

 DATABASE  :  QUARTELY ==> All quarters

 AGGREGATS : EU-28

 UNIT      : Individuals

 DIMENSIONS        :

 AGE   COUNTRY   HATLEV1D   ILOSTAT   QUARTER   REGION   SEX   YEAR

 CLASSES        :

 HATLEV1D   SEX
 *********************************************************************** */
/*******************************************************/
/*Macro to control Number of observations in Data		*/
%macro ctrl_nbobs(data=TEMP,lib=WORK,nbobs= nb_obs);
%global &nbobs;
%let &nbobs=0;
proc sql noprint;
  select nobs into : &nbobs from dictionary.TABLES
		where libname eq %upcase("&lib.")
			and memname eq %upcase("&data.")
			and memtype eq "DATA";
quit;
%put &&&nbobs observations in data &data;
%mend;

/*******************************************************/
options linesize=160 ps=97 nocenter pageno=1;
%macro debut  ;
/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* clean the library of work					  */
/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
	proc datasets lib=WORK;
	delete  TEMP
			RESONE
			RESYEAR
			RESALL
	;run;
/*-----------------------------------------------*/

 proc format library=work;
/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* Write the formats of the variables            */
/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
        value  AGE (multilabel notsorted)
-10-14 = '00-14'
15-64  = '15-64'
65-130 = '65+  '
-1E-10 = 'No answer'
       ;
        value  $HATLEV1D (multilabel notsorted)
'L'   = '1.Low'
'M'   = '2.Medium'
'H'   = '3.High'
'.'   = 'No answer'
'9'   = 'Not applicable'
other = 'invalid'
       ;
        value  $ILOSTAT (multilabel notsorted)
'1'   = '1.Employed'
'2'   = '2.Unemployed'
'3'   = '3.Inactive'
'4'   = '4.Conscript'
'9'   = 'Not applicable'
'.'   = 'No answer'
other = 'invalid'
       ;
        value  $REGION (multilabel notsorted)
'. '='No answer'
/* TOTAL can be calculated using Sub Totals only */




       ;
        value  $SEX (multilabel notsorted)
'1'     = '1.Males'
'2'     = '2.Females'
'.'     = 'No answer'
other   = 'invalid'
       ;

/*-----------------------------------------------*/

;	run;
%mend debut;


/*===============================================*/






%macro  formfile(li, co, ye, qu);


/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* BEGIN THE FORMFILE DATA     				  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
data work.temp(keep= AGE POP COUNTRY YEAR QUARTER
AGE HATLEV1D ILOSTAT REGION SEX rkey /* cell key: keep random key (rkey) throughout the program */
 ) breakflg ;

/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* BEGIN THE FORMFILE SET      				  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

 set &li..&co.&ye.&qu(keep= COEFF COUNTRY YEAR QUARTER
AGE HATLEV1D ILOSTAT REGION SEX
 HHPRIV AGE  ILOSTAT 
 HHNUM HHSEQNUM /* cell key: include HHNUM, HHSEQNUM to compute rkey */);
 
 format rkey best32.; /* cell key: define rkey format */
hash_hex = put(md5(COUNTRY||YEAR||QUARTER||HHNUM||HHSEQNUM), hex32.); /* cell key: first compute MD5 hash */
hash_int = input(hash_hex, IB4.); /*  cell key: convert to int (IB8. not accepted by RANUNI) */
call ranuni(hash_int, rkey); /* cell key: then compute actual rkey in [0, 1] */




/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* CONDITIONS FILTERS 		     				  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

		where  ((((15 le AGE le 64)  and (HHPRIV='1')  and (ILOSTAT='1' )))   );
POP = COEFF;

/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* FORMULA FOR CALCULATION ON NUMERIC DATA		  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

if AGE  = . then AGE  = -1E-10 ;
if HATLEV1D  = " " then HATLEV1D  = ".";
if ILOSTAT  = " " then ILOSTAT  = ".";
if REGION  = " " then REGION  = ".";
if SEX  = " " then SEX  = ".";
run;
data work.copytemp; set work.temp; run; 
%ctrl_nbobs(data=TEMP,lib=WORK,nbobs= tmp);
%if &tmp gt 0 %then %do;
   data work.temp (drop=CTRY); set work.temp(rename=(COUNTRY=CTRY));
        format COUNTRY $11.;
	     COUNTRY=CTRY;
run;
%end;

%MEND formfile;

/*
+------------------------------------------------*+
|                                                 |
+-------------------------------------------------+
*/
%MACRO calcfile(li, co, ye, qu);

%ctrl_nbobs(data=TEMP,lib=WORK,nbobs= ttmp);
%if &ttmp gt 0 %then %do;

/*sort the temp file on variables without sub-totals */
  proc sort data=work.TEMP; by
COUNTRY YEAR QUARTER
 AGE   HATLEV1D   ILOSTAT   REGION   SEX
;run;
%if &ye. ge 2016 %then %let aaa = B; %else %let aaa = A;
 proc summary  data=work.TEMP  missing;
by COUNTRY YEAR QUARTER ;
 format AGE   AGE. ;
class AGE  / mlf preloadfmt order=data;
 format HATLEV1D  $HATLEV1D. ;
class HATLEV1D  / mlf preloadfmt order=data;
 format ILOSTAT  $ILOSTAT. ;
class ILOSTAT  / mlf preloadfmt order=data;
 format REGION  $REGION. ;
class REGION  / mlf preloadfmt order=data;
 format SEX  $SEX. ;
class SEX  / mlf preloadfmt order=data;
    ;var POP rkey; /* cell key: add rkey to proc summary #1 */
       output   out=work.RESONE sum(POP)=POP sum(rkey)=rkey; /* cell key: compute sum(rkey) #1 */

run;


 data work.RESONE; set work.RESONE;
		freq=_FREQ_;
 if AGE  in ('.'," ") then delete;
 if ILOSTAT  in ('.'," ") then delete;
 if REGION  in ('.'," ") then REGION = "TOTAL ";
 if HATLEV1D  in ('.'," ") then HATLEV1D = "TOTAL ";
 if SEX  in ('.'," ") then SEX = "TOTAL ";
		run;

/*RELIABILITY LIMITS*/
 proc sql;
 	create table work.DICOTEMP as
		select YEAR,LIMIT_C,
 (LIMIT_A/1000) as LIMIT_A,
 (LIMIT_B/1000) as LIMIT_B
		from work.DICOFILE
      where COUNTRY="&co" and YEAR="&ye" and QUARTER="&qu"

      order by YEAR;
quit;
	 proc sort data=work.RESONE;by year;run;
	 data work.RESONE; merge work.RESONE (in=a)
							 work.DICOTEMP (in=b);
      by YEAR ;
 		if  a;
	 run;
 proc delete data=work.DICOTEMP;
%end;
%MEND calcfile;



/*
+------------------------------------------------*+
|                                                 |
+-------------------------------------------------+
*/
%MACRO calcaggr(li, co, ye, qu);
%include "/ec/prod/server/sas/0lfs/application/lfsweb/sas/macros/calcaggr.sas";
%MEND calcaggr;
/*
+------------------------------------------------*+
|                                                 |
+-------------------------------------------------+
*/
%MACRO calcyear(li, co, ye, qu);
%ctrl_nbobs(data=RES_IN,lib=WORK,nbobs= tmp10bis);
%if &tmp10bis gt 0 %then %do;
	data work.TEMP; set work.RES_IN work.RESYEAR;
run;
%end;
%else %do;
	data work.TEMP; set work.RESYEAR;
run;
%end;
  /*                                                       */
  /* added because of no EU aggregates after proc summary */
   data work.TEMP; set work.TEMP; QHHNUM=" "; REC=.;run;
  /*                                                       */
  /*compute the results and replace/append RESYEAR     */
 proc summary data=work.TEMP missing nway;
       var     POP LIMIT_A LIMIT_B LIMIT_C freq rkey; /* cell key: add rkey to proc summary #2 */
;       output   out=work.RESONE  sum(POP)=POP sum(rkey)=rkey /* cell key: compute sum(rkey) #2 */
                      sum(freq)=freq
                max(LIMIT_A)=LIMIT_A
                max(LIMIT_B)=LIMIT_B
                max(LIMIT_C)=LIMIT_C;
class COUNTRY YEAR QUARTER
AGE HATLEV1D ILOSTAT REGION SEX
;run;
/* make sure freq is an integer: */
data resone; set resone; freq=round(freq); run;
  /*                                                       */
  /* added because of no EU aggregates after proc summary */
  	data work.RESONE(drop=QHHNUM REC); set work.RESONE;
  	run;
  /*                                                       */
   data work.RESYEAR; set work.RESONE; run;
 proc datasets lib=WORK;
 delete TEMP RESONE RES_IN; run;


%MEND calcyear;
/*
+------------------------------------------------*+
|                                                 |
+-------------------------------------------------+
*/
%MACRO relbyear(li, co, ye);
%ctrl_nbobs(data=RESYEAR,lib=WORK,nbobs= ttttmp);
%if &ttttmp. gt 0 %then %do;
  data work.RESYEAR;
 		set work.RESYEAR;
 FLAG =' ';
    POPLIM=POP;
if LIMIT_A lt POPLIM le LIMIT_B then FLAG='b';
else if POPLIM le LIMIT_A then FLAG='a';
 /*if freq le LIMIT_C then FLAG='c'; cell key (FB): 'c' flag not used anymore */
run;
%end;
%MEND relbyear;




%MACRO confyear;
/*
+-------------------------------------------------+
|  Confidentiality                                |
+-------------------------------------------------+
*/
%put "WARNING : Nothing to do with the confidentiality of &country &year &quarter";
%MEND confyear;



%MACRO final;
 %let fname=/ec/prod/server/sas/0lfs/listings/melina/CELL_KEY_TEST_Q.csv           ;
 %if %sysfunc(exist(RESALL, DATA)) %then %do;

 /* APPLY country order                  */
%include "/ec/prod/server/sas/0lfs/application/lfsweb/sas/macros/fmt_ctrord.sas";
  data work.RESALL; set work.RESALL;
  keep

 /* APPLY country order                  */
COUNTRY_ORDER COUNTRY YEAR QUARTER
AGE HATLEV1D ILOSTAT REGION SEX POP FLAG rkey ckey freq /* cell key: drop rkey, ckey, freq later */
;

    format COUNTRY_ORDER $20.;
	 COUNTRY_ORDER=put(COUNTRY,$CTRORD.);
  IF COUNTRY in ('EUR17') then delete;
  IF COUNTRY in ('EUR18') then delete;
  IF COUNTRY in ('EUR19') then delete;
  IF COUNTRY in ('EU-15') then delete;
  IF COUNTRY in ('EU-27') then delete;
;   rename POP=VALUE;
format ckey best32.; ckey = mod(rkey, 1); /* cell key: define format and compute actual cell key in [0, 1] */
if freq>0 /*and COUNTRY in ('GROUP2')*/ then do; /* cell key (FB): check if freq>0 and COUNTRY in group 2 */
/* cell key (FB): country condition commented out so code should work; otherwise provide country list GROUP2 */
wgt = POP / freq; /* cell key: compute average weight of cell */
if ckey lt 0.25 then noise = -1; /* cell key: add noise according to cell key variance #1 */
else if ckey gt 0.75 then noise = 1; /* cell key: add noise according to cell key variance #2 */
else noise = 0; /* cell key: add noise according to cell key variance #3 */
POP = (freq + noise) * wgt; /* cell key: new value after cell key applied */
end; /*drop rkey ckey freq;  cell key: end of cell key method */

 /*IF FLAG in ('a') and user="general_user" then POP = . ;*/  /* cell key (FB): this suppresses POP<LIMIT_A for general users */
 /* cell key (FB): user condition commented out so no suppressions; otherwise introduce global variable to provide user info */
 
/* USER GROUP  TREATMENT Micha
 %let tabnum=%trim(2 );
  %let target=%sysfunc(compress(&tabnum));
                

   %if &target. eq "1" %then  %include "/ec/prod/server/sas/0lfs/application/lfsweb/sas/macros/user1.sas";
     %else %if &target. eq "2" %then  %include "/ec/prod/server/sas/0lfs/application/lfsweb/sas/macros/user2.sas";
           %else  %if &target. eq "3" %include "/ec/prod/server/sas/0lfs/application/lfsweb/sas/macros/user3.sas";
                %else  %include "/ec/prod/server/sas/0lfs/application/lfsweb/sas/macros/user4.sas";
*/



  ;run;
%if %sysfunc(exist(work.RESALL)) %then %do;
	%let nobs=0;
	%let any =0;
	%let dsid  = %sysfunc(open(RESALL));
	%let nobs = %sysfunc(attrn(&dsid,nobs));
	%let any   = %sysfunc(attrn(&dsid,any));
	%let rc    = %sysfunc(close(&dsid));
	%let obs   = %eval(&nobs * &any);
	%if &obs gt 0 %then %do;

   %include "/ec/prod/server/sas/0lfs/application/lfsbreaks/check_var_exist.sas";
  /* export the data set to a csv file. */
  proc export data=work.RESALL outfile="&fname "
				dbms=dlm replace;
    delimiter=',';
  quit;
%sysexec chmod 777 /ec/prod/server/sas/0lfs/listings/melina/CELL_KEY_TEST_Q.csv  ;
/* libname libuser "/ec/prod/server/sas/0lfs/listings/frankb";			*/
/* data libuser.CELL_KEY_TEST_Q  ; set work.RESALL;run;*/
/* %sysexec chmod 777 /ec/prod/server/sas/0lfs/listings/melina/CELL_KEY_TEST_Q.sas7bdat  ;*/

    %end;
	%else %do;%put ERROR :NO OUTPUT AVAILABLE; %put &fname; %end;
 %end;
 %end;
 %else %do;
	%put ERROR :NO DATASETS PRODUCE; %put &fname;
 %end;
%MEND final;




%MACRO onefile(li, co, ye, qu);


 proc datasets lib=WORK; delete RESONE; run;

 %put country: &co  period: &ye.&qu;

 %formfile(&li,&co,&ye,&qu);
  proc append base=work.copytemp2 data=work.copytemp force; run;
 %calcfile(&li,&co,&ye,&qu);

 %if %sysfunc(exist(RESONE, DATA)) %then %do;
    proc append base=work.RESYEAR data=work.RESONE force; run;
 %end;


%MEND onefile;




%MACRO allfiles;

 %local nbpi nban listpi listan libdisa ;
 %local country year quarter i j k ctradd yeradd qtradd;
 %let listpi=AT SE/* BE BG CY CZ DE DK EE ES FI FR GR HR HU IE IT LT LU LV MT NL PL PT RO SE SI SK UK IS NO CH TR MK*/;
 %let listan=2016 ;

 %debut;
 %let i=1;
 %let year=%scan(&listan,&i,%str( ));
 data WORK.DICOFILE; set DICO.DICOFILE;run;
 %do  %while(&year ne );
libname DISA&year ("/ec/prod/server/sas/0lfs/datasets/disa/&year") access=readonly;
libname DISA&year ("/ec/prod/server/sas/0lfs/datasets/disa/&year") access=readonly;
libname QUAR&year ("/ec/prod/server/sas/0lfs/datasets/disa/&year/quar") access=readonly;
   %let libdisa=QUAR&year;


   %let j=1;
   %let country=%scan(&listpi,&j,%str( ));
 %do  %while(&country ne );
		%do k= 1 %to 4;
        %let quarter= Q&k;

        %if %sysfunc(exist(&libdisa..&country.&year.&quarter, VIEW )) %then %do;
          %onefile(&libdisa,&country,&year,&quarter);
        %end;
	%end;
	%let j=%eval(&j+1);
   %let country=%scan(&listpi,&j,%str( ));
   %end;
   %if %sysfunc(exist(RESYEAR, DATA)) %then %do;
     %calcaggr(&libdisa,&country,&year);
     %calcyear(&libdisa,&country,&year);
     %relbyear(&libdisa,&country,&year);
     proc append base=RESALL data=RESYEAR force; run;
     proc datasets lib=WORK; delete RESYEAR; run;
   %end;
	%let i=%eval(&i+1);
   %let year=%scan(&listan,&i,%str( ));
%end;

%confyear;
%final;

%MEND allfiles;
proc printto log = "/ec/prod/server/sas/0lfs/listings/melina/CELL_KEY_TEST_Q.log" new;
quit;

%allfiles;

proc printto log = LOG;
quit;

 proc freq data =  resall;
 tables flag /missing;
 title 'Data with Subtotals';
 run ;

data resall_without;
set resall;
if AGE   in ("TOTAL ") then delete;
if HATLEV1D   in ("TOTAL ") then delete;
if ILOSTAT   in ("TOTAL ") then delete;
if REGION   in ("TOTAL ") then delete;
if SEX   in ("TOTAL ") then delete;
run;

 proc freq data =  resall_without;
 tables flag /missing;
 title 'Data without Subtotals';
 run ;

