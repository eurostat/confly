/* *********************************************************************** 
 *a: Application   : LFS                                                  *
 *a:                                                                      *
 *a: Program name  : /ec/prod/server/sas/1lfs/listings/bachfab/user_test1.sas            a*
 **************************************************************************
 *a: Description   :                                                      *
First test with core user DGs extraction table following Fabienne#1#s indications
 **************************************************************************
 *a: Output file(s): /ec/prod/server/sas/1lfs/listings/bachfab/user_test1.csv            a*
 *a: -------------------------------------------------------------------- *
 *b:                                                                      *
 *b: created the 10/03/17
 *c: ==================================================================== *
 COUNTRIES : BE,CY,DE,FR
                                                                           
 YEARS     : 2015
                                                                           
 DATABASE  :  ANNUAL 
                                                                           
 AGGREGATS : "
                                                                           
 UNIT      : Individuals                  
                                                                      
 DIMENSIONS        : 													
                                                                      
 AGE   COUNTRY   COUNTRYB   ILOSTAT   ISCO1D   QUARTER   SEX   YEAR  
                                                                           
 CLASSES        : 
                                                                           
 AGE   COUNTRY   COUNTRYB   ILOSTAT   ISCO1D   QUARTER   SEX   YEAR  
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
15-19  = '15-19'
20-24  = '20-24'
25-29  = '25-29'
30-34  = '30-34'
35-39  = '35-39'
40-44  = '40-44'
45-49  = '45-49'
50-54  = '50-54'
55-59  = '55-59'
60-64  = '60-64'
65-69  = '65-69'
70-74  = '70-74'
75-130 = '75+  '
-1E-10 = 'No answer'
       ;
/*        value  AGE (multilabel notsorted)
-10-14 = '00-14'
15-64  = '15-64'
65-130 = '65+  '
-1E-10 = 'No answer'
       ;*/
        value  $COUNTRYB (multilabel notsorted)
/* for individual country groupings (e.g. OECD), comment/delete everything except NOANSWER/REPORTCY/NOTAPPLI */
'NOANSWER','.'        = 'No answer'
'REPORTCY'            = 'Reporting country'
'NOTAPPLI'            = 'Not applicable'
'G4_15FOR','G4_15EXT',
'G5_15FOR','G5_12FOR',
'G5_HRFOR','G5_28EXT' = 'Foreign country'
'G4_15FOR','G5_15FOR' = 'EU-15 countries except reporting country'
'G4_15EXT','G5_12FOR',
'G5_HRFOR','G5_28EXT' = 'Non-EU15 countries nor reporting country'
'G5_15FOR','G5_12FOR' = 'EU-27 countries except reporting country'
'G5_HRFOR','G5_28EXT' = 'Non-EU27 countries nor reporting country'
'G5_15FOR','G5_12FOR',
'G5_HRFOR'            = 'EU-28 countries except reporting country'
'G5_28EXT'            = 'Non-EU28 countries nor reporting country'
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
        value  $ISCO1D (multilabel notsorted)
'000' = 'Armed forces'
'100' = 'Legislators senior officials and managers'
'200' = 'Professionals'
'300' = 'Technicians and associate professionals'
'400' = 'Clerks'
'500' = 'Service workers and shop and market sales workers'
'600' = 'Skilled agricultural and fishery workers'
'700' = 'Craft and related trades workers'
'800' = 'Plant and machine operators and assemblers'
'900' = 'Elementary occupations'
'999' = 'Not applicable'
'.'   = 'No answer'
       ;
        value  $SEX (multilabel notsorted)
'1'     = '1.Males'
'2'     = '2.Females'
'.'     = 'No answer'
other   = 'invalid'
       ;
value $origin5f /* EU27+EU28 2006+ */
	'  ' 									= 'NOANSWER'
	'00' 									= 'REPORTCY'
	'99' 									= 'NOTAPPLI'
/* for individual country groupings (e.g. OECD), comment/delete from here ... */
	'01','BE','DK','DE','GR','ES','FR','IE',
	'IT','LU','NL','PT','AT','FI','SE','UK' = 'G5_15FOR'
	'15','CZ','CY','EE','HU','LV','LT','MT',
	'PL','SI','SK','BG','RO' 				= 'G5_12FOR'
	'HR' 									= 'G5_HRFOR'
	other 									= 'G5_28EXT'
/* ... to here and change COUNTRYB/NATIONAL/COUNTRYW/COUNTR1Y formats as requested! */
;
value $origin4f /* EU15 1995-2005 */
	'  ' 									= 'NOANSWER'
	'00' 									= 'REPORTCY'
	'99' 									= 'NOTAPPLI'
/* for individual country groupings (e.g. OECD), comment/delete from here ... */
	'01','BE','DK','DE','GR','ES','FR','IE',
	'IT','LU','NL','PT','AT','FI','SE','UK' = 'G4_15FOR'
	other 									= 'G4_15EXT'
/* ... to here and change COUNTRYB/NATIONAL/COUNTRYW/COUNTR1Y formats as requested! */
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
AGE COUNTRYB ILOSTAT ISCO1D SEX
 ) breakflg ;
   
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* BEGIN THE FORMFILE SET      				  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
   
 set &li..&co.&ye.&qu(keep= COEFF COUNTRY YEAR QUARTER
AGE COUNTRYB ILOSTAT ISCO1D SEX
 HHPRIV AGE   ); 
   
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* CONDITIONS FILTERS 		     				  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
   
		where  ((((15 le AGE)  and (HHPRIV='1')  and (ILOSTAT='1' )))   );
POP = COEFF;
   
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/* FORMULA FOR CALCULATION ON NUMERIC DATA		  */
/* $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
   
/* specific format for country of birth */
%include "/ec/prod/server/sas/1lfs/0lfs.copy/application/lfsweb/sas/macros/correction_variables/COUNTRYB.sas";
format origcob $40.;
if COUNTRYB=COUNTRY or COUNTRYB='99' then COUNTRYB='00';
/* -- the formats below are defined in the autoexec file */
if (YEAR ge '2006') then do;
	if NATGROUB in ('1') then origcob=put(COUNTRYB,$origin5f.);
	else origcob='NOANSWER';
end;
else if (YEAR eq '2005') then do;
	if NATGROUB in ('1','2') then origcob=put(COUNTRYB,$origin4f.);
	else origcob='NOANSWER';
end;
else if ('1995' le YEAR le '2004') then do;
	if NATGROUB in ('1','2','3') then origcob=put(COUNTRYB,$origin4f.);
	else origcob='NOANSWER';
end;
else origcob='NOANSWER';
drop COUNTRYB; rename origcob=COUNTRYB;
/* using only 1 digit from 3 digits code*/
   IF (ISCO1D not in ('9','9  ','999','   ',' ')) THEN ISCO1D=substr(ISCO1D,1,1)||'00'; 
if AGE  = . then AGE  = -1E-10 ;
if COUNTRYB  = " " then COUNTRYB  = ".";
if ILOSTAT  = " " then ILOSTAT  = ".";
if ISCO1D  = " " then ISCO1D  = ".";
if SEX  = " " then SEX  = ".";
run;   
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
 AGE   COUNTRYB   ILOSTAT   ISCO1D   SEX  
;run;														 
%if &ye. ge 2016 %then %let aaa = B; %else %let aaa = A;    
 proc summary  data=work.TEMP  missing; 				 
by COUNTRY YEAR QUARTER ;
 format AGE   AGE. ;
class AGE  / mlf preloadfmt order=data;
 format COUNTRYB  $COUNTRYB. ;
class COUNTRYB  / mlf preloadfmt order=data;
 format ILOSTAT  $ILOSTAT. ;
class ILOSTAT  / mlf preloadfmt order=data;
 format ISCO1D  $ISCO1D. ;
class ISCO1D  / mlf preloadfmt order=data;
 format SEX  $SEX. ;
class SEX  / mlf preloadfmt order=data;
    ;var POP;
       output   out=work.RESONE sum(POP)=POP ;               
 
run;   										
       										
 
 data work.RESONE; set work.RESONE;						   
		freq=_FREQ_;
 if AGE  in ('.'," ") then AGE = "TOTAL ";
 if COUNTRYB  in ('.'," ") then COUNTRYB = "TOTAL ";
 if ILOSTAT  in ('.'," ") then ILOSTAT = "TOTAL ";
 if ISCO1D  in ('.'," ") then ISCO1D = "TOTAL ";
 if SEX  in ('.'," ") then SEX = "TOTAL ";
		run;                                   							
      		                                   							
/*RELIABILITY LIMITS*/                             					
 proc sql;																
 	create table work.DICOTEMP as										
		select YEAR,LIMIT_C,											
 (WLIMIT_A/1000) as LIMIT_A,			                        
 (WLIMIT_B/1000) as LIMIT_B                                   
		from work.DICOFILE										
       where COUNTRY="&co" and YEAR="&ye" and SPRING="Y"		
																
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
               														
                														
                                          								
%MACRO calcyear(li, co, ye, qu);                        
  /*                                                       */ 
  /* added because of no EU aggregates after proc summary */ 
   data work.TEMP; set work.TEMP; QHHNUM=" "; REC=.;run;       
  /*                                                       */ 
  /*                                                       */ 
  /* added because of no EU aggregates after proc summary */ 
  	data work.RESONE(drop=QHHNUM REC); set work.RESONE;   							
  	run;                                                                                           	
  /*                                                       */ 
 
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
 if freq le LIMIT_C then FLAG='c';      
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
 %let fname=/ec/prod/server/sas/1lfs/listings/bachfab/user_test1.csv           ;           				
 %if %sysfunc(exist(RESALL, DATA)) %then %do;           
											
 /* APPLY country order                  */
%include "/ec/prod/server/sas/1lfs/0lfs.copy/application/lfsweb/sas/macros/fmt_ctrord.sas";
  data work.RESALL; set work.RESALL;                         
  keep                  
											
 /* APPLY country order                  */
COUNTRY_ORDER COUNTRY YEAR QUARTER
AGE COUNTRYB ILOSTAT ISCO1D SEX POP FLAG
;
											
    format COUNTRY_ORDER $20.;
	 COUNTRY_ORDER=put(COUNTRY,$CTRORD.);
 IF YEAR le 2004 then QUARTER = '_S'; else QUARTER = '_Y'; 
  IF COUNTRY in ('EUR17') then delete;     
  IF COUNTRY in ('EUR18') then delete;     
  IF COUNTRY in ('EUR19') then delete;     
  IF COUNTRY in ('EU-15') then delete;     
  IF COUNTRY in ('EU-27') then delete;     
  IF COUNTRY in ('EU-28') then delete;     
;   rename POP=VALUE;                 
 IF FLAG in ('c','a') then POP = . ;  
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
                                           
   %include "/ec/prod/server/sas/1lfs/0lfs.copy/application/lfsbreaks/check_var_exist.sas"; 
  /* export the data set to a csv file. */
  proc export data=work.RESALL outfile="&fname "
				dbms=dlm replace; 			
    delimiter=',';                         
  quit;									
%sysexec chmod 777 /ec/prod/server/sas/1lfs/listings/bachfab/user_test1.csv  ;
/* libname libuser "/ec/prod/server/sas/1lfs/listings/bachfab";			*/
/* data libuser.user_test1  ; set work.RESALL;run;*/
/* %sysexec chmod 777 /ec/prod/server/sas/1lfs/listings/bachfab/user_test1.sas7bdat  ;*/
                                           
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
 %calcfile(&li,&co,&ye,&qu);                            
                                                        
 %if %sysfunc(exist(RESONE, DATA)) %then %do;		 
    proc append base=work.RESYEAR data=work.RESONE force; run;             
 %end;                                                  
                                                        
                                                        
%MEND onefile;                                          
                                                        
                                                        
											
                                                        
%MACRO allfiles;                                        
                                                        
 %local nbpi nban listpi listan libdisa ;               
 %local country year quarter i j k ctradd yeradd qtradd;
 %let listpi=BE CY DE FR;
 %let listan=2015 ;
                                                        
 %debut;                                                
 %let i=1;                                              
 %let year=%scan(&listan,&i,%str( ));                   
 data WORK.DICOFILE; set DICO.DICOFILE;run;
 %do  %while(&year ne );                                
libname DISA&year ("/ec/prod/server/sas/1lfs/0lfs.copy/datasets/disa/&year") access=readonly;
libname DISA&year ("/ec/prod/server/sas/1lfs/0lfs.copy/datasets/disa/&year") access=readonly;
libname YEAR&year ("/ec/prod/server/sas/1lfs/0lfs.copy/datasets/disa/&year/year") access=readonly;
   %let libdisa=YEAR&year;                              
                                                        
                                                        
   %let j=1;											 
   %let country=%scan(&listpi,&j,%str( ));              
 %do  %while(&country ne );                                
                                                        
       %let quarter=_Y;                                 
       %if %sysfunc(exist(&libdisa..&country.&year._Y, VIEW ))      
          %then %onefile(&libdisa,&country,&year,&quarter);            
                                                        
	%let j=%eval(&j+1);                                  
   %let country=%scan(&listpi,&j,%str( ));              
   %end;                                                
   %if %sysfunc(exist(RESYEAR, DATA)) %then %do;     
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
proc printto log = "/ec/prod/server/sas/1lfs/listings/bachfab/user_test1.log" new;          
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
if COUNTRYB   in ("TOTAL ") then delete;
if ILOSTAT   in ("TOTAL ") then delete;
if ISCO1D   in ("TOTAL ") then delete;
if SEX   in ("TOTAL ") then delete;
run;   
      
 proc freq data =  resall_without; 
 tables flag /missing; 
 title 'Data without Subtotals'; 
 run ; 
      
