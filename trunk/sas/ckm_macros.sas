

/*z02*/
/*This macro prints the date and time to the SAS log; used for identifying how long it takes a program to run*/
/*type = S to show when code starts running, type = E to show when code stops running*/
%macro get_time(type);
	%if &type = S %then %put NOTE: Tab start time: %sysfunc(datetime(),datetime20.);
	%else %if &type = E %then %put NOTE: Tab stop time: %sysfunc(datetime(),datetime20.);
%mend get_time;



/*z19*/
%Macro read_in_data;

	/*Imports ptable from csv file */
	data work.&ptable_ds;
	     %let _EFIERR_ = 0; 
	    infile "&path_ptable.&ptable_ds..csv" delimiter = ';' MISSOVER Termstr=crlf lrecl=32767 firstobs=2 ;
	        informat pcv 8. ;
	        informat ckey 8. ;
	        informat pvalue 8. ;
	        format pcv 8. ;
	        format ckey 8. ;
	        format pvalue 8. ;
	     input
	                 pcv
	                 ckey
	                 pvalue
	     ;
	     if _ERROR_ then call symputx('_EFIERR_',1);  
	run;
	
	/*get number of rows (prows) and columns (m) in ptable*/
	proc sql noprint;
		select max(pcv), max(ckey) into :prows, :pcols
		from &ptable_ds;
	quit;
	%let m = %left(&pcols); /*m will now be used for the number of ckeys - M was used in early methodology papers*/
	%put m = &m.;
	/*(This code is present in both %cpmacro and %read_in_data, since it is*/ 
	/*necessary for either, and they may be run in isolation from each other*/


	/*create rkey based on ptable column number*/
	data mdata_rkey;
		set &input_ds;
		rkey = int(&m*ranuni(&mseed)+1);
			%if &rkey = 0 %then %do;
				if spv_cov_imputation_flag > 0 then rkey = 0;
				/*if oa_code_2011 ne oa_code_2011_preds then rkey = 0;*/ /* REPLACED, DESTATIS 31.07.2017 by: */
				if &geog ne &geog._preds then rkey = 0; 
				
			%end;
	run;


	/*This arbitrary data must also be read in from excel*/
	/*This set is needed for generating category keys based on variable name*/
	data WORK.GEN_SEEDS ;
         %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile "&path_seeds.genseeds.csv" delimiter = ";" MISSOVER Termstr=crlf lrecl=32767 firstobs=2 ;
            informat number 1. ;
            informat letter $1. ;
            format number 1. ;
            format letter $1. ;
         input
                     number
                     letter $
         ;
         if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
	run;

%Mend read_in_data;



/*z20*/
%macro gen_seeds;
	/*These macros generate seeds, based on variable names, for producing category keys (which are independent but consistent)*/
	/*They save these seeds (one for each variable) as a macro variable to be called later*/
	/*'gen_seeds is case specific, so all macro variable names are converted to lower case*/
	%Let var1=%lowcase(&var1);
	%Let var2=%lowcase(&var2);
	%Let var3=%lowcase(&var3);
	%Let var4=%lowcase(&var4);
	%Let var5=%lowcase(&var5);
	%Let var6=%lowcase(&var6);
	%Let var7=%lowcase(&var7);
	%Let var8=%lowcase(&var8);

	%do i =1 %to &vnum;
		/*Take the first 3 letters of each variable name*/
		%Let a&i.1=%substr(&&var&i.,1,1);
		%Let a&i.2=%substr(&&var&i.,2,1);
		%Let a&i.3=%substr(&&var&i.,3,1);

		/*Create variables containing letters used in var names and "map" these to numbers (0-9)*/
		/*One digit (0-9) is produced for each of the 3 first varname letters*/
		Data gen_seeds2&i.;
			set gen_seeds;
			a&i.1="&&a&i.1";
			a&i.2="&&a&i.2";
			a&i.3="&&a&i.3";

			if letter=a&i.1 then b&i.1=number;
			if letter=a&i.2 then b&i.2=number;
			if letter=a&i.3 then b&i.3=number;
		run;


		/*z21*/
		/*Save these numbers as macro variables*/
		Proc summary data=gen_seeds2&i. max;var b&i.1;output out=b&i.1 max=max;run;
		data _null_;set b&i.1;call symput("b&i.1",put(max,1.));run;

		Proc summary data=gen_seeds2&i. max;var b&i.2;output out=b&i.2 max=max;run;
		data _null_;set b&i.2;call symput("b&i.2",put(max,1.));run;

		Proc summary data=gen_seeds2&i. max;var b&i.3;output out=b&i.3 max=max;run;
		data _null_;set b&i.3;call symput("b&i.3",put(max,1.));run;

		/*Use random numbers to produce 3 digit seeds*/
		Data gen_seeds3&i.;
			set gen_seeds2&i.;
			seed&i.=100*&&b&i.1.+10*&&b&i.2.+&&b&i.3.;
		run;

	%end;
%mend gen_seeds;



/*Save these seeds as macro variables*/
%macro gen_seeds2;
	%Do i=1 %to &vnum;
		Proc summary data=gen_seeds3&i. max;var seed&i.;output out=seed&i. max=max;run;
		data _null_;set seed&i.;call symput("seed&i.",put(max,3.));run;
	%end;
%mend gen_seeds2;






/*
CP macro (with optional pzeros code)
This code takes microdata, creates a frequency table and applies the cell key method
It also creates a category key to perturb some zero cells. The output table contains

base_cv	= 	the cell value before records swapping and person imputation,
rs_cv 	= 	the cell value after record swapping and person imputation, 
cp_cv 	= 	the cell value after record swapping, person imputation and cell perturbation

As well as the data, this code needs to read in a ptable file and a small excel/csv file 
called 'seeds converter' currently being saved as 'ptable' and 'gen_seeds'

This version has the option of not assigning record keys to perturbed/swapped records
so that cells with only swapped/imputed records will not be perturbed. Currently the
input dataset lists post-swapping geography as 'geo_m' and pre-swapping geography
as 'geo_m_preds'. The imputation flag is currently called 'spv_cov_imputation_flag'.
*/


%macro CPmacro;
	/***************************************************************************************************/
	/*		INPUT ERROR CHECKING		*/
	/*		Check for errors in the macro variables specified by the user	*/
	/*		If an error is detected then the code will stop running and a message will output to the SAS log	*/

	/*z08*/
	%let errcode = 0;
	
	%if &rkey ne rkey %then %do;
		%if &rkey ne 0 %then %do; %put ERROR: rkey must be either rkey for assignment of an rkey or 0 for rkey = 0.; %let errcode = %eval(&errcode+1); %end;
	%end;

	/*check if mseed is numeric*/
	%if &mseed =  %then %do; %put ERROR: mseed variable must be populated.; %let errcode = %eval(&errcode+1); %end;
	%else %if %sysfunc(notdigit(&mseed)) ne 0 %then %do; %put ERROR: mseed must be numeric only.; %let errcode = %eval(&errcode+1); %end;

	/*check library and input dataset exists*/
	%if &input_ds =  %then %do; %put ERROR: input_ds variable must be populated.; %let errcode = %eval(&errcode+1); %end;
	%else %if %sysfunc(exist(&input_ds)) = 0 %then %do; %put ERROR: Dataset &input_ds does not exist.; %let errcode = %eval(&errcode+1); %end;

	%if &geog =  %then %do; %put ERROR: geog variable must be populated.; %let errcode = %eval(&errcode+1); %end;

	

	/* ADDED, DESTATIS 03.05.2017 */

	data _NULL_;
		c=symget("table_var");
		ct=strip(countw(c," "));
		call symput("ct",ct);
	run;

	%put ct=&ct.;

	%let select_list=;
	%do i=1 %to &ct.;
		%let select_list = &select_list. %scan(&table_var,&i.," "), ;
	%end;

	%let select_list=%quote(&select_list.);
	%put select_list = &select_list.;

	

	/*Other variables - include name as in select statement e.g. "end as age_25yr," age should be listed as age_25yr*/
	/*Unused variables must be left as blank (not commented out) for determining how many variables are used*/
	%Let var1=&geog;
	%Let var2=%scan(&select_list., 1, ",");
	%Let var3=%scan(&select_list., 2, ",");
	%Let var4=%scan(&select_list., 3, ",");
	%Let var5=%scan(&select_list., 4, ",");
	%Let var6=%scan(&select_list., 5, ",");
	%Let var7=%scan(&select_list., 6, ",");
	%Let var8=%scan(&select_list., 7, ",");
	%put Other Variables = &var1. &var2. &var3. &var4. &var5. &var6. &var7. &var8. ;


	data _NULL_;
		c=symget("select_list");
		ct=strip(countw(c,","));
		call symput("ct",ct);
	run;

	%let group_list = 1 ;
	%do i=2 %to &ct.;
		%let group_list = &group_list.,&i. ;
	%end;

	%let group_list=%quote(&group_list.);
	%put group_list = &group_list.;
	/* End ADDED*/


	/*check for SELECT in select_list, check for comma at the end*/
	%if &select_list =  %then %do; %put ERROR: select_list variable must be populated.; %let errcode = %eval(&errcode+1); %end;
	%else %do;
		%if %upcase(%scan(&select_list,1)) = SELECT %then %do; %put ERROR: Remove SELECT from the select_list variable and try again.; %let errcode = %eval(&errcode+1); %end;
		%if %substr(%qtrim(&select_list),%length(%qtrim(&select_list)),1) ne , %then %do; %put ERROR: Ensure select_list has a comma at then end.; %let errcode = %eval(&errcode+1); %end;
	%end;

	%if &group_list =  %then %do; %put ERROR: group_list variable must be populated.; %let errcode = %eval(&errcode+1); %end;
	%if &errcode ne 0 %then %do; %put ERROR: There were &errcode errors. Macro aborted.; %return; %end;

	/*		END OF ERROR CHECKING 		*/

	/***************************************************************************************************/

	/*z09*/
	/*get number of rows (prows) and columns (m) in ptable*/
	/*max(pcv) is the number of rows of the ptable. pcv is explained below*/
	proc sql noprint;
		select max(pcv), max(ckey) into :prows, :pcols
		from &ptable_ds;
	quit;
	%let m = %left(&pcols); /*m will now be used for the number of ckeys*/
	%put m (number of ckeys) = &m.;

	/* pcv is short for ptable cell-value, this is the row of the ptable to be merged onto the dataset for each cell*/
	

	%put;
	%put geog=&geog.;
	%put select_list=&select_list;
	
	%put where_list=&where_list;
	%put group_list=&group_list;
	%put;


	/*create table with cellkey and ptable merge value, rs_cv = cell value after record swapping*/
	/* %let pmod = %eval(&prows-2); CHANGED, DESTATIS 02.05.2017 */
	%let pmod = %eval(&prows);
	%put pmod = &pmod.;

	proc sql;
		create table cp_tab1 as
		select &geog.,
			&select_list

			count(*) as rs_cv,
			case
				when (sum(rkey)=0) then 0 /* NO Perturbation */
				else 1 + (mod(sum(rkey),&m))
			end as ckey,
			
			/*ptable merge value - see below for explanation of pcv*/
			/*
			case
				when calculated rs_cv > 2 and mod(calculated rs_cv,&pmod) in (0 1 2) then mod(calculated rs_cv,&pmod) + &pmod
				else mod(calculated rs_cv,&pmod)
			end as pcv
			*/
			/* CHANGED, DESTATIS 02.02.2017 */
			case
				when calculated rs_cv < &pmod. then calculated rs_cv
				else &pmod.
			end as pcv
			/* CHANGED end --> now we don't need 302 rows any longer */

		from mdata_rkey
		&where_list
		group by &group_list;
	quit;


	/* CHANGED, DESTATIS 21.03.2017 */
	/* Append aggregates: Computing missing higher level combinations and totals (pmod=300)*/
	%if &aggregates = yes %then %do;
		%fifi_aggregates(input=cp_tab1, pmod=&pmod.); 

		data cp_tab1;
			set cp_tab1_totals2;
		run;
	%end;

	/* CHANGED end */





	/*z10*/
	/*Merge on ptable by cell-key and pcv (ptable merge cell value) and apply perturbation */
	/*cp_cv is cell value after perturbation  (rs_cv+pvalue = cp_cv*/
	proc sql;
		create table cp_tab2a as
		select a.*, 
				b.pvalue,
			case
				when a.ckey=0 then a.rs_cv /* No Perturbation */
				else a.rs_cv + b.pvalue
			end as cp_cv

		from cp_tab1 as a left join &ptable_ds as b
			on a.pcv = b.pcv
			and a.ckey = b.ckey
		order by &group_list;
	quit;






	/****************************************************/
	/*Start of determining imbalance parameter(s) */

	/* Rate at which extra one are perturbed down (negative imbalance to be corrected by 0's) */
	/* this depends on which ptable is being used*/
	
	%imbalance_par(D=&D.);

	/*%put &ibp1.;
	%put &ibp2.;
	%put &ibp3.;*/

	/*End of determining imbalance parameter(s) */
	/****************************************************/	





	/****************************************************/
	/*Start of perturbing zero code */

	/*z11*/
	/*generate a macro with number of variables used*/
	%let len = %length(&group_list);
	%let vnum = %substr(&group_list,&len,1);
	%put len=&len.;
	%put vnum=&vnum.;
	%Let i=1; 								/* ---------------------- ??? can I remove this line ??? --------------------- */

	/* As well as a seed for creating the record keys (rkey), a seed will also be needed for */
	/* creating the category keys for each variable */
	/* To avoid perturbing the same cells (by position) in every table despite variable choice e.g.: */
	/* In an age by sex table, the 4th row, 3rd column cell (in the first geography) is perturbed,  */
	/* in an ethnicity by religion table, the 4th row, 3rd column cell (in the first geography)is perturbed, */
	/* the category key for each variable must be different (created using a different seed). */
	/* And to ensure the same cells in a given table are perturbed each time e.g.: */
	/* In age by sex table, the 6th row, 2rd column cell (in the first geography) is perturbed, */
	/* in the same age by sex table, the 6th row, 2rd column cell (in the first geography) must also be perturbed, */
	/* the category key should depend on the variable being used in the frequency table.  */

	/* In order to create distinct/different results for different frequency tables, but the same (repeatable)  */
	/* results for any given table, the seed (and thereby the category key) is generated based on the name of the variable used */
	/* The first three characters of each variable are converted to a 3 digit number, through the  */
	/* 'gen_seeds' excel file. This 3 digit number is used as the seed */
	/* e.g. a variable named "abc" will use the seed 123, a variable named "bedrooms" will use 254*/
	/* This creates the &seed1 macro variable containing the seed for &var1, &seed2 for &var2 and so on*/
	
	%gen_seeds; 	/*Converts variable names into seed numbers*/
	%gen_seeds2;	/*Saves seed numbers as macro variables*/



	/*z12*/
	/*These 4 blocks of code allow different number of variables to be used (up to 8)*/

	/*Create datasets containing all category levels and corresponding category keys*/
	%If &vnum>=1 %then %do;	proc freq data =cp_tab1(keep = &var1); tables &var1 / out = f1 (keep = &var1) noprint; run;
							data f1r; set f1; catkey_1=round((ranuni(&seed1)),0.000001); &var1._num=_N_;run; %end;
	%If &vnum>=2 %then %do;	proc freq data =cp_tab1(keep = &var2); tables &var2 / out = f2 (keep = &var2) noprint; run;
							data f2r; set f2; catkey_2=round((ranuni(&seed2)),0.000001); &var2._num=_N_;run; %end;
	%If &vnum>=3 %then %do;	proc freq data =cp_tab1(keep = &var3); tables &var3 / out = f3 (keep = &var3) noprint; run;
							data f3r; set f3; catkey_3=round((ranuni(&seed3)),0.000001); &var3._num=_N_;run; %end;
	%If &vnum>=4 %then %do;	proc freq data =cp_tab1(keep = &var4); tables &var4 / out = f4 (keep = &var4) noprint; run;
							data f4r; set f4; catkey_4=round((ranuni(&seed4)),0.000001); &var4._num=_N_;run; %end;
	%If &vnum>=5 %then %do; proc freq data =cp_tab1(keep = &var5); tables &var5 / out = f5 (keep = &var5) noprint; run;
						   	data f5r; set f5; catkey_5=round((ranuni(&seed5)),0.000001); &var5._num=_N_;run; %end;
	%If &vnum>=6 %then %do; proc freq data =cp_tab1(keep = &var6); tables &var6 / out = f6 (keep = &var6) noprint; run;
						   	data f6r; set f6; catkey_6=round((ranuni(&seed6)),0.000001); &var6._num=_N_;run; %end;
	%If &vnum>=7 %then %do; proc freq data =cp_tab1(keep = &var7); tables &var7 / out = f7 (keep = &var7) noprint; run;
						  	data f7r; set f7; catkey_7=round((ranuni(&seed7)),0.000001); &var7._num=_N_;run; %end;
	%If &vnum=8 %then %do;	proc freq data =cp_tab1(keep = &var8); tables &var8 / out = f8 (keep = &var8) noprint; run;
						  	data f8r; set f8; catkey_8=round((ranuni(&seed8)),0.000001); &var8._num=_N_;run; %end;


	/*'c1_from_list' used to create table of all possible cells (c1)(includes empty cells) */
	%Let c1_from_list=;
	%If 	  &var8^= %then %do; %Let c1_from_list= f1r,f2r,f3r,f4r,f5r,f6r,f7r,f8r; 	%end;
	%else %if &var7^= %then %do; %Let c1_from_list= f1r,f2r,f3r,f4r,f5r,f6r,f7r;		%end;
	%else %if &var6^= %then %do; %Let c1_from_list= f1r,f2r,f3r,f4r,f5r,f6r;			%end;
	%else %if &var5^= %then %do; %Let c1_from_list= f1r,f2r,f3r,f4r,f5r;				%end;
	%else %if &var4^= %then %do; %Let c1_from_list= f1r,f2r,f3r,f4r;					%end;
	%else %if &var3^= %then %do; %Let c1_from_list= f1r,f2r,f3r;						%end;
	%else %if &var2^= %then %do; %Let c1_from_list= f1r,f2r;							%end;
	%else %if &var1^= %then %do; %Let c1_from_list= f1r;								%end;
	%else %do; %put Error: variable list must be populated.; %let errcode = %eval(&errcode+1); %end; 

	/*'tab2b_merge_list' used to merge populated table (tab2b) with table of all possible cells (c1)*/
	%Let tab2b_merge_list=;
	%If 	  &var8^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1 and a.&var2=b.&var2 and a.&var3=b.&var3 and a.&var4=b.&var4 and a.&var5=b.&var5 and a.&var6=b.&var6	and a.&var7=b.&var7 and a.&var8=b.&var8; %end;
	%else %if &var7^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1	and a.&var2=b.&var2 and a.&var3=b.&var3 and a.&var4=b.&var4 and a.&var5=b.&var5 and a.&var6=b.&var6 and a.&var7=b.&var7; %end;
	%else %if &var6^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1	and a.&var2=b.&var2 and a.&var3=b.&var3 and a.&var4=b.&var4 and a.&var5=b.&var5 and a.&var6=b.&var6; %end;
	%else %if &var5^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1	and a.&var2=b.&var2 and a.&var3=b.&var3 and a.&var4=b.&var4 and a.&var5=b.&var5; %end;
	%else %if &var4^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1	and a.&var2=b.&var2 and a.&var3=b.&var3 and a.&var4=b.&var4; %end;
	%else %if &var3^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1	and a.&var2=b.&var2 and a.&var3=b.&var3; %end;
	%else %if &var2^= %then %do; %Let tab2b_merge_list= a.&var1=b.&var1	and a.&var2=b.&var2; %end;
	%else %if &var1^= %then	%do; %Let tab2b_merge_list= a.&var1=b.&var1; %end;
	%else %do; %put Error: variable list must be populated.; %let errcode = %eval(&errcode+1); %end; 

		/*Create macro catkey for each geography*/
	%let catkey_formula=;
	%If 	  &vnum=8 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2+catkey_3+catkey_4+catkey_5+catkey_6+catkey_7+catkey_8,1); %end;
	%else %if &vnum=7 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2+catkey_3+catkey_4+catkey_5+catkey_6+catkey_7,1);%end;
	%else %if &vnum=6 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2+catkey_3+catkey_4+catkey_5+catkey_6,1);%end;
	%else %if &vnum=5 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2+catkey_3+catkey_4+catkey_5,1);%end;
	%else %if &vnum=4 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2+catkey_3+catkey_4,1);%end;
	%else %if &vnum=3 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2+catkey_3,1);%end;
	%else %if &vnum=2 %then %do; %Let catkey_formula=mod(catkey_1+catkey_2,1);%end;
	%else %if &vnum=1 %then %do; %Let catkey_formula=mod(catkey_1,1);%end;
	%else %do; %put Error: variable list must be populated.; %let errcode = %eval(&errcode+1); %end; 

	%put;
	%put number of variables: &vnum.;
	%put c1_from_list: &c1_from_list.;
	%put tab2b_merge_list: &tab2b_merge_list.;
	%put catkey_formula: &catkey_formula.;
	%put;



	/*z13*/
	/*Create c1, table of all possible table values (but no counts)*/
	proc sql;
		create table c1 as
		select *
		from &c1_from_list;
	quit;

	/*Merge on populated table (with counts) to full list of possible values*/
	Proc sql;
		create table cp_tab2b as
		select
			a.*,
			b.ckey,
			b.rs_cv,
			b.pvalue,
			b.cp_cv
		from c1 as a left join cp_tab2a as b
		on &tab2b_merge_list;
	quit;

	/*Give empty (zero) cells value after swapping of zero (rs_cv=0)*/
	Data cp_tab2c;
		set cp_tab2b;
		if rs_cv in ('.') then rs_cv=0;
		catkey=0;
	run;


	/* ADDED, DESTATIS 02.05.2017: Perturb zeroes? */

%if &pzeroes = yes %then %do;
	
	/**/



	/*z14*/
	/*Dealing with global macro variables*/
	/*Extract number of 0s and number of 1s in the table and covert to macro variable for later use*/
	proc summary data = cp_tab2c;
		where rs_cv=0;
		var rs_cv; 
		output out = N0 N = N0;
	run;

	%let N0=0;
	data _null_; 
		set N0; 
		call symput('N0',put(N0,10.)); 
	run;

	proc summary data = cp_tab2c;
		where rs_cv=1 and ckey^=0 ;
		var rs_cv; 
		output out = N1 N = N1;
	run;

	%let N1=0;
	data _null_; 
		set N1; 
		call symput('N1',put(N1,10.)); 
	run;

	/* ADDED, DESTATIS 31.01.2017: Extract (if necessary) exact number of 2s, 3s and so on */
	%do i=2 %to &D.;

		
		proc summary data = cp_tab2c;
			where rs_cv=&i. and ckey^=0 ;
			var rs_cv; 
			output out = N&i. N = N&i.;
		run;
		%let N&i.=0;
		data _null_; 
			set N&i.; 
			call symput("N&i.",put(N&i.,10.)); 
		run;
		

	%end;


	%do i=0 %to &D.;
		%put N&i.=&&N&i;
	%end;	

	%put;

	%do i=1 %to &D.;
		%put ibp&i = &&ibp&i.;
	%end;
	


	/* END ADDED */

	/* ADDED, DESTATIS 02.05.2017 */
	data perturb_biased;
		do i=1 to &D.;
			ibp_i = Input(symget(cats('ibp',i)), 8.6);
			/*if ibp_i<0 then ibp_i = 0;*/
			N_i = Input(symget(cats('N',i)), 10.);
			j=0;
			changes_ij=N_i*ibp_i;
			output;
		end;
	run;

	data perturb_zeroes;
		set perturb_biased (keep=changes_ij i rename=(i=j));
		i=0;
		N_0 = Input(symget('N0'), 10.);	
		if N_0 gt 0 then p_ij=changes_ij/N_0;
		else p_ij=0;
		if _n_=1 then changes_ij_cum = 0;
		changes_ij_cum + changes_ij;
		call symputx("changes_i"||strip(put(j,2.)),changes_ij,"G");
	run;

	title "Imbalanced perturbations to zero (i.e. biased perturbations)";
	proc print data=perturb_biased noobs;
	run;

	title "How many zeroes should be perturbed (to correct for the bias)?";
	proc print data=perturb_zeroes noobs;
	run;

	/* Check, wheather there are enough 0s, 1s, 2s and so on, that can be preturbed */
	/* --> if not, stop executing */
	data _null_;
		set perturb_zeroes;
		exit=0;
		if changes_ij_cum gt N_0 then exit=1;
		call symputx("exit"||strip(put(j,2.)),exit,"G");
	run;

	%do j=1 %to &D.;
		%if &&exit&j = 1 %then %do;
			%put ERROR: Not enough zeroes that can be perturbed into j=&j. (see table work.perturb_zeroes).; 
			%let errcode = %eval(&errcode+1);
		%end;
	%end;

	%if &errcode ne 0 %then %do; %put ERROR: There were &errcode errors. Macro aborted.; %return; %end;

	/* END ADDED */


	/*z15*/
	/* Create the category key, using levels of each variable */
	/* e.g. mod(0.25+0.92,1)=0.17  mod(0.25+0.56,1)=0.81 */
	Data cp_tab2d;
		set cp_tab2c;
		If rs_cv=0 then catkey=&catkey_formula;
	run;

	/*Blocking zero cells*/
	
	Data cp_tab2e(keep = &var1 &var2 &var3 &var4 &var5 &var6 &var7 &var8 ckey catkey rs_cv pvalue cp_cv);
		set cp_tab2d;
		/* REPLACED by macro variable "block_zeros" , DESTATIS 31.01.2017
		If age_T004A in ('03to15') and age_T004A not in ('.')				and rs_cv=0 then catkey=0.000001;
		If age_T007A in ('00to24') and age_T007A not in ('.') 				and rs_cv=0 then catkey=0.000001;
		If age_T010A in ('Age under 10') and ageT010A not in ('.') 			and rs_cv=0 then catkey=0.000001;
		If age_T079A in ('003','004','005','006','007','008','009','010',
		'011','012','013','014','015','016') and age_T079A not in ('.') 	and rs_cv=0 then catkey=0.000001;
		If rooms<bedrooms and rooms not in ('.') and bedrooms not in ('.') 	and rs_cv=0 then catkey=0.000001;
		If yrarrpuk11<CoB and yrarrpuk11 not in ('.') and CoB not in ('.') 	and rs_cv=0 then catkey=0.000001;
		*/
		&block_zeros.
	run;


	/*z16*/
	/*Percentiles using proc freq */
	/*Proc freq to get cumulative frequency of catkeys */
	Proc freq data=cp_tab2e noprint;
		where catkey>0;
		tables catkey /out=data2 outcum nofreq;
	run;

/* ADDED, DESTATIS 01.02.2017 */

	/* Calculate number of zero cells we would like to perturb up to 1's, to 2's, to 3's ... */
	/* Then compute the cumulative numbers 'cum_freq_value' */
	data _NULL_;
		cum_value=0;
		do d=1 to &D.;
			ibp = Input(symget(cats('ibp',d)), 8.6);
			if ibp<0 then ibp = 0;
			N = Input(symget(cats('N',d)), 10.);
			value= ibp*N;
			cum_value = value + cum_value;
			out= Input(symget("N0"), 10.) - cum_value;
			call symputx("cum_freq_value"||left(trim(put(d,2.))),out,"G");
			output;
		end;
	run;
/* END ADDED */



	


/* MODIEFIED (i.e., the loop), DESTATIS 01.02.2017 */
	%do i=1 %to &D.;

		%put i=&i.;
		%Let imbalance_parameter=&&ibp&i.;

		/*Calculate number of zero cells we would like to perturb up (based on ptable, N0 N1) */
		/*Find 'categorykey level' (catlevel) that would achieve this, using cumulative frequency of catkeys */
		/*If category key > catlevel then zero-cell will be perturbed */
		/*If categpry key < catlevel then zero-cell will not be perturbed */
		proc summary data=data2;
			where cum_freq>=&&cum_freq_value&i.;
			var catkey;
			output out=min min=min;
		run;

		/*Correction for if zeros are not perturbed at all*/
		/* %If &imbalance_parameter=0 %then %let catlevel=1; */




		/*Save category key level as macro variable*/
		/*	data _NULL_;
			set min;
			call symput("catlevel",put(min,8.6));
		run; */
		%put imbalance_parameter = &imbalance_parameter.;
		%if &imbalance_parameter. ~= 0 %then %do;
			data _NULL_;
				set min;
				call symput("catlevel"||left(trim(put(&i.,2.))),put(min,8.6));
			run;
		%end;
		%else %do;
			%let catlevel&i = 0;
		%end;

		%put i = &i.;
		%put cum_freq_value: &&cum_freq_value&i.;
		%put Imbalance parameter = &imbalance_parameter.;
		%put catlevel &i.: &&catlevel&i;



		%let catlevel = &&catlevel&i.;

		/*Perturb chosen 0s to 1 (those with highest category key)*/
		/* REPLACED, DESTATIS 31.01.2017
		Data cp_tab2;
			set cp_tab2e;
			where catkey=0 or catkey>=&catlevel;
			if catkey>=&catlevel then pvalue=1;
			if rs_cv=0 then cp_cv=rs_cv+pvalue;
			if cp_cv in ('.') then cp_cv=0;
			run;
		*/


		%if &catlevel. = 0 %then %let replace_pvalue = 0;
		%else %let replace_pvalue = &i.;

		%put i=&i. --> Replacement of pvalue by: &replace_pvalue.;
		%put;
	/*	%let erg=%eval(&&ibp&i. * %trim(&&N&i.));
		%put erg=&erg.;*/
		%put;
		
		%if &catlevel. ~= 0 %then %do;
			Data cp_tab2e;
				set cp_tab2e;
				if catkey=0 or catkey>=&catlevel then do;
					/*if catkey>=&catlevel AND pvalue = . then pvalue=Input(symget('i'), 2.);*/
					if catkey>=&catlevel AND pvalue = . then pvalue=Input(symget('replace_pvalue'), 2.);
				end;
			run;
		%end;

	%end;


	Data cp_tab2;
		set cp_tab2e;
		if catkey=0 or catkey>=&catlevel then do;
			if rs_cv=0 then cp_cv=rs_cv+pvalue;
			if cp_cv in ('.') then cp_cv=0;
		end;
	run;
/* END MODIFICATION, DESTATIS 01.02.2017 */


	/*End of zeros section*/
	/****************************************************/

	/* END of if-condition: pzeroes = yes */
%end;
	/**/

%if &pzeroes = no %then %do;

	data cp_tab2;
		set cp_tab2c;
		if cp_cv in ('.') then cp_cv=0;
	run;

%end;



	/*z17*/
	/*create table before person imputation and record swapping*/
	/*(for comparisons between each level of disclosure control)*/
	proc sql;
		create table base_tab1 as
		select &geog._preds as &geog,
			&select_list

			count(*) as base_cv	
		from mdata_rkey
		group by &group_list;
	quit;

	/*produce list of variables in dataset*/
	proc contents data = cp_tab1 noprint out = cont1; run;
	/*sort contents output to get variables in the order they appear in the dataset*/
	proc sort data = cont1; by VARNUM; run;
	/*save the table dimension variable names in macro variables*/
	data _null_;
	set cont1;
	if VARNUM <= &vnum then call symputx('m'||compress(_N_),compress(NAME));
	run;

	/*generate a list of dimension variables*/
	/* merge_list with spaces for dataset merging */
	/* ad_select with commas for later use in PROC SQL statements */
	%let merge_list =;
	%let ad_select =;
	%do i = 1 %to &vnum;
		%let merge_list = &merge_list &&m&i;
		%let ad_select = &ad_select &&m&i..,;
	%end;

	/*z18*/
	/*Sort cp_tab2 for merging with base_tab1*/
	proc sort data=cp_tab2;
	by &merge_list;
	run;

	%put merge_list = &merge_list;
	%put;

	/*merge table from different stages and replace blanks with zeros*/
/*	data &table._table;
	merge cp_tab2 base_tab1;
	by &merge_list;
	array cvs{3} base_cv rs_cv cp_cv;
	do i = 1 to 3;
		if cvs(i) = . then cvs(i) = 0;
	end;
	drop i;
	run;
*/
	/* Replaced, 22.03.2017, DESTATIS */
	data &table._table;
		set cp_tab2;
		array cvs{2} rs_cv cp_cv;
		do i = 1 to 2;
			if cvs(i) = . then cvs(i) = 0;
		end;
		drop i;
	run;

	/* End Replaced */


	/* ADDED, DESTATIS 31.01.2017 */
	/* Check distribution of perturbation */
		
	/* Perturbation of 1's */
	/*	title "Perturbation of 1's";
		proc freq data=cp_tab2A (where=(rs_cv = 1));
			table pvalue;
		run;
	*/

	
	ods pdf file="&path_output.Output_&table._V&version..pdf";


		data cp_tab2B_check;
			set cp_tab2B (keep=pvalue rs_cv);
			if pvalue=. then pvalue=0;
		run;

		title "Before perturbing zeros: Perturbation of zeros";
		proc freq data=cp_tab2B_check (where=(rs_cv=.));
			table pvalue;
		run;

		title "Before perturbing zeros: Perturbation of cell values larger than 3 ";
		proc freq data=cp_tab2B_check (where=(rs_cv gt 3));
			table pvalue;
		run;


		title "Before perturbing zeros: Perturbation of all cell values";
		proc freq data=cp_tab2B_check;
			table pvalue;
		run;

		data &table._table_check (keep=perturbation);
			set &table._table ;
			perturbation = cp_cv - rs_cv;
		run;

		title "Final perturbation: Perturbation of all cell values";
		proc freq data=&table._table_check;
			table perturbation;
		run;

		title "Before perturbing zeros: Mean and Variance of perturbations";
		proc means data=cp_tab2B_check
		            mean var min max N;
		         var pvalue;
		run;

		title "Final perturbation: Mean and Variance of perturbations";
		proc means data=&table._table_check
		            mean var min max N;
		         var perturbation;
		run;

		proc format;
		   Value frq 	0 = "0"
		                1 = "1"
						2 = "2"
						3 = "3"
						4 = "4"
						5 = "5"
						6 = "6"
						7 = "7"
						8 = "8"
						9 = "9"
						10 = ">= 10"
	;
		
		run;

		data &table._table;
			set &table._table;
			format cp_cv_cat frq. rs_cv_cat frq.;
			cp_cv_cat = cp_cv;
			if cp_cv > 10 then cp_cv_cat = 10;
			
			rs_cv_cat = rs_cv;
			if rs_cv > 10 then rs_cv_cat = 10;
		run;




		title "Distribution of original and final cell values";
		proc freq data=&table._table;
			table rs_cv_cat cp_cv_cat;
		run;

		title "Empirical perturbation table";
		proc freq data=&table._table;
			 tables rs_cv_cat * cp_cv_cat /
			   NOFREQ NOCOL NOPERCENT NOCUM SCORES=TABLE ALPHA=0.05;
		run;

	ods pdf close;

	/* END ADDED */


	/* ADDED, DESTATIS 05.05.2017*/
	data &table._table_V&version.;
		set &table._table;
	run;

	/*END ADDED */
%mend CPmacro;




/* Macro: Determine the balance parameter for each original cell frequency */
/* we now will allow 2's, 3's, 4's .... to become zeros */
/* then zeros must become 2's, 3's, 4's and so on */

%macro imbalance_par(D=);

	%put IMBALANCE PARAMETER DETERMINATION;
	%put =================================;
	%put;
	
	data WORK.OPTPAR     ;
	     %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	     infile "&path_ptable.&ptable_ds._optpar.csv" delimiter = "," MISSOVER Termstr=crlf lrecl=32767 firstobs=2 ;
	        informat op 12.10 ;    
	        format op 12.10 ;
	     input
	                 op           
	     ;
	     if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
		 call symputx("op"||left(trim(put(_n_,2.))),op,"G");
	run;

	%do i=1 %to &D.;

		%put i=&i.;
		%global ibp&i.;
		%let ibp&i. = 0 ; /* Initializing */


		title "Before perturbing zeros: Perturbation of &i.'s ";
		proc freq data=CP_TAB2A (where=(rs_cv=&i.));
			table pvalue / out=CP_TAB2A_freq;
		run;

		%let dsempty=0;
		data _null_;
		  if eof then
		    do;
		     call symput('dsempty',strip(1));
		     put 'NOTE: EOF - no records in data!';
		    end;
		  stop;
		  set CP_TAB2A_freq end=eof;
		run;
		%put dsempty = &dsempty.;
		%put;


		
		
		%let val = %eval(0-&i.);
		%put val = &val.;

		%if &dsempty. %then %do;
			data CP_TAB2A_freq;
				pvalue=&val.;
				percent=0;
			run;
	    %end;

		data tobitest2_&i.;
			set CP_TAB2A_freq (where=(pvalue eq &val.));
			diff = percent - 100*&&op&i.;
			
			if diff<0 then diff = 0;

			i=left(trim(Put(&i.,2.)));
			suspend=left(trim(symget('suspend')));
			check=find(suspend,i);
			if check > 0 then diff = 0;

		/*	pzeroes = left(trim(symget('pzeroes')));
			if pzeroes="no" then diff = 0;
*/
			call symputx("ibp&i.",round(diff,1)/100,"G");
		run;

		%put ibp&i.;
		%put Balance parameter for perturbation 0%str(`)s to &i.%str(`)s must be: &&ibp&i.;
		%put;
	%end;

	%put;
	%put End of IMBALANCE PARAMETER DETERMINATION;
	%put ========================================;
	%put;

%mend imbalance_par;


/* Aggregation (optional)*/
/* can be set by local variable: %let aggregates=no/yes; */
%macro fifi_aggregates(input=, pmod=);
	
	%let path_data		= work;
	%let f_orig	= rs_cv;
/*
	proc summary data=&path_data..&input. nway completetypes;
		class geo_m/mlf;
		class sex/mlf; 
		class age_m/mlf;
		class yae_h/mlf;
		var &f_orig. ckey;
		output out=&input._totals (drop=_type_ _freq_) sum(&f_orig.)=&f_orig. sum(ckey)=ckey;
		format geo_m $geo_m. sex $sex. age_m $age_m. yae_h $yae_h.;
	run;
*/

	%let class = class &geog./mlf %str(;) ;
	%let format = format &geog. $&geog..;
	%let count = %sysfunc(countw(&table_var.));
	%do i=1 %to &count.;
		%let var = %scan(&table_var., &i. ," ");
		%put var=t&var.t;
		%let class = &class. class &var./mlf %str(;); 
		%let format = &format. &var. $&var..;
	%end;
	%put class=&class.;
	%put format=&format.;

	proc summary data=&path_data..&input. nway completetypes;
		&class.
		var &f_orig. ckey;
		output out=&input._totals (drop=_type_ _freq_) sum(&f_orig.)=&f_orig. sum(ckey)=ckey;
		&format. ;
	run;

		
	data &input._totals2;
		set &input._totals;

		/*if ckey ne 200 then ckey= mod(ckey,200) ;*/
		if ckey ne &m. then ckey= mod(ckey,&m.) ;

		if rs_cv < &pmod. then pcv=rs_cv;
			else if rs_cv >= &pmod. then pcv=&pmod.;
	run;


%mend;





