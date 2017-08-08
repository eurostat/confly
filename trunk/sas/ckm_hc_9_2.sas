/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: 08 August 2017     TIME: 11:51:12
PROJECT: census_cell_key_method
PROJECT PATH: H:\B1\table_builder\CENSUS_cell_key_method\census_cell_key_method.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=Analysis
    STYLESHEET=(URL="file:///Q:/SASEG71.001/SASEnterpriseGuide/7.1/Styles/Analysis.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: ckm_hc_9_2   */
%LET _CLIENTTASKLABEL='ckm_hc_9_2';
%LET _CLIENTPROJECTPATH='H:\B1\table_builder\CENSUS_cell_key_method\census_cell_key_method.egp';
%LET _CLIENTPROJECTNAME='census_cell_key_method.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;

/* Version of the code (i.e., the date) */
%let date=20170517;


/* Step 1: Initializing */
/* -------------------- */

/* Define paths where files are located */
%let path_ptable 		= /home/user/bachfab/cell_key_method_SAS/data/ckm_&date./ ;
%let path_seeds 		= /home/user/bachfab/cell_key_method_SAS/data/ckm_&date./ ;
%let path_importfile   	= /home/user/bachfab/cell_key_method_SAS/data/ckm_&date./ ;
%let path_macros		= /home/user/bachfab/cell_key_method_SAS/data/ckm_&date./ ;
%let path_output		= /home/user/bachfab/cell_key_method_SAS/data/ckm_&date./output/ ;

/* Import of required macros */
%include "&path_macros./ckm_macros.sas" / lrecl=500;
%include "&path_macros./ckm_multilabel.sas" / lrecl=500;


/* Further Settings */

%let rkey = 0;			/* rkey = assign an rkey to imputed and swapped records (perturb cells with only swapped/imputed cells)*/
						/* 0 = assign rkey of zero (do not perturb cells with only swapped imputed cells)*/
%let mseed = 678;		/* set the seed for producing the microdata record-keys*/

%let where_list = %quote(		/*Where clause - include the where statement*/
	where usual_resident = 1  	/*Create table only on records where usual resident=1 (only usual residents)*/
	/*and age>= '016'*/			/*Can add other where statements, e.g. age>=16 for economic activity tables */
);




/* Step 2: Hypercube Preparation (Specification and Import) */
/* -------------------------------------------------------- */

/* Output table name or number */
%let table = hc_9_2;   /* will be saved as: &table._table* e.g. hc_9_2_table */

/* Input microdata library and dataset name*/
%Let input_ds 	= &table._synth;

/* Define import file name of the hypercube */
%let importfile = &table._synth.csv;

/*Geography variable */  
%let geog = geo_m;

/* Specify the REMAINING (without geography) variables of the table (sparated by blanks) */ 
%let table_var = sex age_m yae_h;



/* Import Synthetic data (Hypercube 9.2, ESSC 2016/30/2/EN, page 9) for code testing outside secure environment*/
data work.&input_ds. ;
         %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile "&path_importfile.&importfile." delimiter = ";" MISSOVER Termstr=crlf lrecl=32767 firstobs=2 ;
            informat id best32. ;
            informat geo_m best32. ;
            informat sex best32. ;
            informat age_m best32. ;
            informat yae_h best32. ;
            informat usual_resident best32. ;
            informat spv_cov_imputation_flag 2. ;
            format id best12. ;
            format geo_m best12. ;
            format sex best12. ;
            format age_m best12. ;
            format yae_h best12. ;
            format usual_resident best12. ;
            format spv_cov_imputation_flag 2. ;
         input
                     id
                     geo_m
                     sex
                     age_m
                     yae_h
                     usual_resident
                     spv_cov_imputation_flag 
        ;
         if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;


/* Some recoding (e.g., on the basis of German geo_m levels) of the input data (in order to have more realistic synthetic hypercube) */
data work.&input_ds. (drop=v1-v4);
	set work.&input_ds. (rename=(geo_m=v1 sex=v2 age_m=v3 yae_h=v4));

	geo_m = strip(put(v1, 10.));
	sex = strip(put(v2, 3.));
	age_m = strip(put(v3, 4.));
	yae_h = strip(put(v4, 6.));

	select(geo_m);
		when('1') geo_m='01051';
		when('2') geo_m='01053';
		when('3') geo_m='01054';
		when('4') geo_m='01055';
		when('5') geo_m='01056';
		when('6') geo_m='01057';
		when('7') geo_m='01058';
		when('8') geo_m='01059';
		when('9') geo_m='01060';
		when('10') geo_m='01061';
		when('11') geo_m='01062';
		when('12') geo_m='02000';
		when('13') geo_m='03151';
		when('14') geo_m='03152';
		when('15') geo_m='03153';
		when('16') geo_m='03154';
		when('17') geo_m='03155';
		when('18') geo_m='03156';
		when('19') geo_m='03157';
		when('20') geo_m='03158';
		when('21') geo_m='03251';
		when('22') geo_m='03252';
		when('23') geo_m='03254';
		when('24') geo_m='03255';
		when('25') geo_m='03256';
		when('26') geo_m='03257';
		when('27') geo_m='03351';
		when('28') geo_m='03352';
		when('29') geo_m='03353';
		when('30') geo_m='03354';
		when('31') geo_m='03355';
		when('32') geo_m='03356';
		when('33') geo_m='03357';
		when('34') geo_m='03358';
		when('35') geo_m='03359';
		when('36') geo_m='03360';
		when('37') geo_m='03361';
		when('38') geo_m='03451';
		when('39') geo_m='03452';
		when('40') geo_m='03453';
		when('41') geo_m='03454';
		when('42') geo_m='03455';
		when('43') geo_m='03456';
	end;

	if age_m = "1" then age_m = "1.1.";
		else if age_m = "2" then age_m = "1.2.";
		else if age_m = "3" then age_m = "1.3.";
		else if age_m = "4" then age_m = "2.1.";
		else if age_m = "5" then age_m = "2.2.";
		else if age_m = "6" then age_m = "2.3.";
		else if age_m = "7" then age_m = "3.1.";
		else if age_m = "8" then age_m = "3.2.";
		else if age_m = "9" then age_m = "3.3.";
		else if age_m = "10" then age_m = "3.4.";
		else if age_m = "11" then age_m = "4.1.";
		else if age_m = "12" then age_m = "4.2.";
		else if age_m = "13" then age_m = "4.3.";
		else if age_m = "14" then age_m = "5.1.";
		else if age_m = "15" then age_m = "5.2.";
		else if age_m = "16" then age_m = "5.3.";
		else if age_m = "17" then age_m = "5.4.";
		else if age_m = "18" then age_m = "6.1.";
		else if age_m = "19" then age_m = "6.2.";
		else if age_m = "20" then age_m = "6.3.";
		else if age_m = "21" then age_m = "6.4.";
		
	if yae_h = "1" then yae_h = "1.1.1.";
		else if yae_h = "2" then yae_h = "1.1.2.";
		else if yae_h = "3" then yae_h = "1.2.1.";
		else if yae_h = "4" then yae_h = "1.2.2.";
		else if yae_h = "5" then yae_h = "1.2.3.";
		else if yae_h = "6" then yae_h = "1.2.4.";
		else if yae_h = "7" then yae_h = "1.2.5.";
		else if yae_h = "8" then yae_h = "1.3.1.";
		else if yae_h = "9" then yae_h = "1.3.2.";
		else if yae_h = "10" then yae_h = "1.3.3.";
		else if yae_h = "11" then yae_h = "1.3.4.";
		else if yae_h = "12" then yae_h = "1.3.5.";
		else if yae_h = "13" then yae_h = "1.4.1.";
		else if yae_h = "14" then yae_h = "1.4.2.";
		else if yae_h = "15" then yae_h = "1.4.3.";
		else if yae_h = "16" then yae_h = "1.4.4.";
		else if yae_h = "17" then yae_h = "1.4.5.";
		else if yae_h = "18" then yae_h = "1.5.";
		else if yae_h = "19" then yae_h = "1.6.";
		else if yae_h = "20" then yae_h = "1.7.";
		else if yae_h = "21" then yae_h = "1.8.";
		else if yae_h = "22" then yae_h = "1.9.";
		else if yae_h = "23" then yae_h = "2.";
		else if yae_h = "24" then yae_h = "3.";
run;




/* Codebook: ESSC 2016/30/3/EN */
/* Value (before recoding) 	Description 	Value (after recoding)*/

/* geo_m (German NUTS3)
1	district 1 	01051
2 	district 2 	01053
...
43	district 42	03456

*/


/* sex
1	male	1
2	female	2
*/

/* yae_h (pp. 43-44)
1	2021 										1.1.1.
2	2020										1.1.2.
3	2019										1.2.1.
4	2018										1.2.2.
...	
17	2005										1.4.5.
18	2000 to 2004								1.5.
19	1995 to 1999								1.6.
...
23	Resided abroad and arrived 1979 or before	2.
24	Not stated									3.
*/

/* age_m (pp. 11-16)
1	under 5					1.1.
2	5 to 9					1.2.
3	10 to 14				1.3.
...
20	95 to 99				6.3.
21	100 years and over		6.4.
*/



/* Important: we need a copy of the geography variable (pre-swapping geography should have _preds suffix */
/* e.g. 'geo_m' is post swapping geography, 'geo_m_preds' is pre-swapping geography)*/
data &input_ds.;
	set &input_ds.;
	&geog._preds = &geog;
run;
/* i.e. since geo_m_preds is a copy of geo_m, there is no pre-swapping */






/* Step 3: Blocking Zero Cells  */
/* ---------------------------- */


/* Combinations that should not be allowed to happen will be listed here*/
	/* The category key for these combinations will be set to very low (not zero) so that these cells will */
	/* not be selected for perturbation (highest category keys selected)*/

/* The following is just an example (should be carried out more sophisticated (e.g. by creating an auxiliary variable that mesures the difference)) */
%let block_zeros =
		If yae_h = '23' AND age_m in ('1','9') 				and rs_cv=0 then catkey=0.000001 %str(;)
		/*e.g., 'Resided abroad and arrived 1979 or before' AND younger than 42 (2021-1979) --> not allowed */
		/* in this example with 'age_M' we can only check if less than '40 to 44 years', the correct edit rule could be applied when using 'age_H' */
		
	/* further rows:
		If yae_h = 22 AND age_m lt 8 				and rs_cv=0 then catkey=0.000001 %str(;) 37-41
		If yae_h = 21 AND age_m lt 7 				and rs_cv=0 then catkey=0.000001 %str(;) 32-36
		If yae_h = 20 AND age_m lt 6 				and rs_cv=0 then catkey=0.000001 %str(;)  35-31 */
		;
%put Blocking zero cells = &block_zeros.;





/* Step 4: Perturbation */
/* -------------------- */

/* Execute ONE of the four versions we provided */

*Version 01: Perturbation with D=3 and V=1 (RECOMMENDED Version: Zeroes stay zeroes);
%let ptable_ds = ptable_version_01;
%let version=01; %let D=3; %let suspend=; %let pzeroes=yes; *don't change these parameters;
%let aggregates=no; *can be changed to yes (deliverable 3.1, part II, section 4.2, option 1);
%read_in_data;
%CPmacro;

/*
*Version 02: Perturbation with D=3 and V=2 (ABS-alike Version: no pertubed values of 1 or 2);
%let ptable_ds = ptable_version_02; 
%let version=02; %let D=3; %let suspend=1 2; %let pzeroes=yes; *don't change these parameters;
%let aggregates=no; *can be changed to yes (deliverable 3.1, part II, section 4.2, option 1);
%read_in_data;
%CPmacro;


*Version 03: Perturbation with D=1 and V=0.5 (ONS-alike Version);
%let ptable_ds = ptable_version_03; 
%let version=03; %let D=1; %let suspend=; %let pzeroes=yes; *don't change these parameters;
%let aggregates=no; *can be changed to yes (deliverable 3.1, part II, section 4.2, option 1);
%read_in_data;
%CPmacro;


*Version 04: Perturbation with D=2 and V=1;
%let ptable_ds = ptable_version_04; 
%let version=04; %let D=2; %let suspend=; %let pzeroes=yes; *don't change these parameters;
%let aggregates=no; *can be changed to yes (deliverable 3.1, part II, section 4.2, option 1);
%read_in_data;
%CPmacro;
*/




GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
