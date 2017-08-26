/*EDA and Data Cleansing*/

/*libname ori 'g:\course';*/
/**/
/*libname exer 'g:\course\work';*/

libname exer '\\Mac\Home\Desktop\reading\Victoria\DM\project';
/*Define the target to be predicted*/
/*proc print data=tmp1.life ;*/
/*run;*/


data exer.life1;
	set tmp1.life;
/*	the target is defined by the definition BU provided*/
	active=(premium>0);
run;
/*Total Obs=28749*/

/*use proc contents load data in*/
proc contents data=exer.life1  varnum; 
run;
/*shows the natural take-rate*/
proc freq data=exer.life1;
	table active/missing;
run;
/*active    Frequency     Percent*/
/*0         27887         97.00  */
/*1         862           3.00   */


proc sort data=exer.life1;
by active;
run;
Proc surveyselect data=exer.life1
method = srs n=(3348 862)
seed=1234 out = sample outall;
strata active;
run;
%let overSample=8.08787703;

/*...Sample1.?.....*/


data exer.life1s;
set sample1;
if active=0 then sample_weight=&overSample;
else sample_weight=1;
run;

/*total=4247*/

/*	take-rate to be 10% after Oversampled	*/
/*data exer.life1s;*/
/*	set exer.life1;*/
/*	if active=0 then do;*/
/*   		sample_weight=3.235150812;*/
/*   		if ranuni(5555)<=0.309104601 then output;*/
/*	end;*/
/*	else if active=1 then do;*/
/*   		sample_weight=1;*/
/*   		output;*/
/*	end;*/
/*run;*/

proc freq data=exer.life1s; 
	table active/missing; 
/*	weight sample_weight; */
run;

proc means data=exer.life1s n nmiss mean min max maxdec=2; 
run;

* outlier handling through capping with 1% and 99%;
proc univariate data=exer.life1s /*vardef=wgt*/ plots;
   weight sample_weight;
   var tot_bal_open_accts amt_past_due_balances;
run;

* view a single value by observation number;
proc print data=exer.life1s (firstobs=715 obs=715); run;

* test outlier for reasonability;
data test_outliers;
	set exer.life1s (where=(tot_bal_open_accts>100000));
	average_bal_open_accts=tot_bal_open_accts/tot_open_accts_on_file;
run;

proc print data=test_outliers;
	var tot_bal_open_accts tot_open_accts_on_file average_bal_open_accts;
run;

proc means data=test_outliers; 	
	var average_bal_open_accts; 
run;

proc univariate data=exer.life1s noprint /*vardef=wgt*/;
	weight sample_weight;
	var amt_past_due_balances;
	output out=outliers median=median mean=mean max=max std=std p1=p1 p99=p99;
run;

* median replacement;
data cap_rep1_test1;
	set exer.life1s;
	if (_n_=1) then set outliers; * append 'outliers' data to every record;
	if 0<=amt_past_due_balances<=1000000 then amt_past_due_balances_cap=amt_past_due_balances;
	else amt_past_due_balances_cap=median;
run;

title 'Replacement with Median';
proc means data=cap_rep1_test1 vardef=wgt;
	weight sample_weight;
	var amt_past_due_balances amt_past_due_balances_cap;
run;

* capping with 1% and 99%;
data cap_rep1_test2;
	set exer.life1s;
	if (_n_=1) then set outliers;
	amt_past_due_balances_cap=max(p1,amt_past_due_balances);
	amt_past_due_balances_cap=min(p99,amt_past_due_balances_cap);
run;

title 'After Capping Rule with 1% and 99%';
proc means data=cap_rep1_test2 vardef=wgt;
	weight sample_weight;
	var amt_past_due_balances amt_past_due_balances_cap;
run;
/*the other way:*/
* capping with x times the standard deviation from the mean (Z-score approach);
data cap_rep1_test3;
	set exer.life1s;
	if (_n_=1) then set outliers;
	amt_past_due_balances_cap3=max((mean-3*std),amt_past_due_balances);
	amt_past_due_balances_cap3=min((mean+3*std),amt_past_due_balances_cap3);
	amt_past_due_balances_cap4=max((mean-4*std),amt_past_due_balances);
	amt_past_due_balances_cap4=min((mean+4*std),amt_past_due_balances_cap4);
run;

title 'After Capping Rule with 3x & 4x the Standard Deviation';
proc means data=cap_rep1_test3 vardef=wgt;
	weight sample_weight;
	var amt_past_due_balances amt_past_due_balances_cap3 amt_past_due_balances_cap4;
run;

* use median replacement capping in production;
data exer.life1s;
	set exer.life1s;
	if (_n_=1) then set outliers;
	if 0<=amt_past_due_balances<=1000000 then amt_past_due_balances_cap=amt_past_due_balances;
	else amt_past_due_balances_cap=median;
run;

/*replacing missing values*/
proc univariate data=exer.life1s vardef=wgt plots;
	weight sample_weight;
	var age_actual;
	output out=missing_data mean=mean_age median=median_age mode=mode_age;
run;

* median replacement;
data life1s;
	set exer.life1s;
	if _n_=1 then set missing_data;
	age_miss=(age_actual<=0); * create missing indicator;
	if age_actual>0 then age_inferred_13pct=age_actual;
	else age_inferred_13pct=median_age;
run;

* compare distribution;
proc means data=life1s n mean std maxdec=2 vardef=wgt;
	title 'Single Value (Median) Substitution';
	weight sample_weight;
	var age_actual age_inferred_13pct;
run;

* class mean substitution;
proc univariate data=exer.life1s vardef=wgt noprint;
	weight sample_weight;
	var age_of_oldest_trade avg_mos_accts_open;
	output out=quartiles pctlpts=25 50 75 pctlpre=age mos;
run;

proc print data=quartiles; title 'Class Means Substitution'; run;

data life1s;
	set exer.life1s;
	if _n_=1 then set quartiles;
	if      age_of_oldest_trade<age25 then trade_age_group='Q1';
	else if age_of_oldest_trade<age50 then trade_age_group='Q2';
	else if age_of_oldest_trade<age75 then trade_age_group='Q3';
	else								   trade_age_group='Q4';

	if      avg_mos_accts_open<mos25 then ave_mos_open_group='Q1';
	else if avg_mos_accts_open<mos50 then ave_mos_open_group='Q2';
	else if avg_mos_accts_open<mos75 then ave_mos_open_group='Q3';
	else                                  ave_mos_open_group='Q4';
run;

* create a table to display values and create output data set;
proc tabulate data=life1s;
	title 'Class Mean Substitution';
	where age_actual>0;
	weight sample_weight;
	class trade_age_group ave_mos_open_group;
	var age_actual;
	table	(trade_age_group='Age of Oldest Trade'),
			(ave_mos_open_group='Average # of Months Open')*
			 age_actual=' '*mean=' '*f=comma7.
			/rts=13 box='Average Age';
	ods output table=missing_age_data;
run;

proc print data=missing_age_data; run;


proc sort data=life1s ;
	by trade_age_group ave_mos_open_group;
run;
proc sort data=missing_age_data;
	by trade_age_group ave_mos_open_group;
run;

data life1s1;
	merge life1s missing_age_data;
	by trade_age_group ave_mos_open_group;
		if age_actual>0 then do;
		age_miss=0;
		age_inferred_13pct=age_actual;
	end;
	else do;
		age_miss=1;
		age_inferred_13pct=age_actual_mean;
	end;
run;

* compare distribution;
proc means data=life1s1 n mean std maxdec=2 vardef=wgt;
	title 'Class Mean Substitution';
	weight sample_weight;
	var age_actual age_inferred_13pct;
run;

* regression substitution;
* run regression to find best predictors for missing values of age_actual;
* create data set 'age_coef' with regression coefficients;
proc reg data=exer.life1s outest=age_coef;
title 'Regression Substitution';
weight sample_weight;
age_reg: model age_actual=
						age_most_rec_pub_record
						age_of_last_activity
						age_of_most_recent_inq
						age_of_oldest_trade
						age_of_youngest_trade
						amt_past_due_balances
						avg_mos_accts_open
						bankrupt_other_hh_member
						bankruptcy_prior
						collection_items
						current_accts_30day
						current_accts_60day
						current_accts_90day
						current_accts_bad_debt
						current_accts_total
						income
						inq_bank_promo
						inq_fin_last_6mos
						inq_past_12mos
						inq_promo
						num_past_due_accts
						num_public_record_items
						risk_score
						tot_accts_30d_pd_in_24m
						tot_accts_30days_ever
						tot_accts_60d_pd_in_24m
						tot_accts_60days_ever
						tot_accts_90d_pd_in_24m
						tot_accts_90days_ever
						tot_accts_bad_debt_24m
						tot_accts_bad_debt_ever
						tot_accts_on_file
						tot_accts_open_last_12m
						tot_accts_open_last_24m
						tot_accts_open_last_3m
						tot_accts_open_last_6m
						tot_accts_paid_satis
						tot_accts_paid_satis_24m
						tot_bal_open_accts
						tot_open_accts_bal_gt_0
						tot_open_accts_on_file
						tot_open_accts_ut_gt_50p
						tot_open_accts_ut_gt_75p
						worst_credit_rating
						/selection=stepwise maxstep=5;
run;

proc print data=age_coef; run;

* score full data set with coefficient 'age_coef' data set;
* create new data set 'life1s2' for backup;
proc score data=exer.life1s score=age_coef out=life1s type=parms;
var						age_most_rec_pub_record
						age_of_last_activity
						age_of_most_recent_inq
						age_of_oldest_trade
						age_of_youngest_trade
						amt_past_due_balances
						avg_mos_accts_open
						bankrupt_other_hh_member
						bankruptcy_prior
						collection_items
						current_accts_30day
						current_accts_60day
						current_accts_90day
						current_accts_bad_debt
						current_accts_total
						income
						inq_bank_promo
						inq_fin_last_6mos
						inq_past_12mos
						inq_promo
						num_past_due_accts
						num_public_record_items
						risk_score
						tot_accts_30d_pd_in_24m
						tot_accts_30days_ever
						tot_accts_60d_pd_in_24m
						tot_accts_60days_ever
						tot_accts_90d_pd_in_24m
						tot_accts_90days_ever
						tot_accts_bad_debt_24m
						tot_accts_bad_debt_ever
						tot_accts_on_file
						tot_accts_open_last_12m
						tot_accts_open_last_24m
						tot_accts_open_last_3m
						tot_accts_open_last_6m
						tot_accts_paid_satis
						tot_accts_paid_satis_24m
						tot_bal_open_accts
						tot_open_accts_bal_gt_0
						tot_open_accts_on_file
						tot_open_accts_ut_gt_50p
						tot_open_accts_ut_gt_75p
						worst_credit_rating;
run;

* create missing indicator variable (done before) and create new variable 'age_inferred_13pct' equal to age with the missing values replaced with 'age_reg';
data exer.life1s2;
	set life1s;
		if age_actual<=0 then do;
		age_miss=1;
		age_inferred_13pct=age_reg;
	end;
	else do;
		age_miss=0;
		age_inferred_13pct=age_actual;
	end;
run;

* compare distribution;
proc means data=exer.life1s2 n mean std maxdec=2 vardef=wgt;
	title 'Regression Substitution';
	weight sample_weight;
	var age_actual age_inferred_13pct;
run;

proc freq data=exer.life1s2;
	title 'Categorical Variables';
	table gender region buyer_group marital_status/missing;
run;
