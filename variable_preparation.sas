/*variable preparation*/

libname exer '\\Mac\Home\Desktop\reading\Victoria\DM\project';


data exer.life1s2;
	set exer.life1s2;
	if ranuni(5555)<=.5 then do; model_weight=1; split_weight=sample_weight; end;
	else do; model_weight=.; split_weight=.; end;
	records=1;
run;

proc freq data=exer.life1s2;
	table active*model_weight/missing nopercent nocol;
run;

proc freq data=exer.life1s2;
	table active*split_weight/missing nopercent nocol;
run;

proc freq data=exer.life1s2 (where=(model_weight=1));
	table active*split_weight/missing nopercent nocol;
run;


proc freq data=exer.life1s2;
	title 'Categorical Variables by Active Rate';
	weight split_weight;
	table active*(gender region marital_status buyer_group)/chisq missing nopercent norow;
run;

data exer.life1s2;
	set exer.life1s2;
	gender_female=(gender='F');
	region_east=(region='East');
	region_south=(region='South');
	marital_divorced=(marital_status='D');
	marital_widow=(marital_status='W');
	marital_married_single=(marital_status in ('M','S'));
	buyer_cluster1=(buyer_group in ('O','K','M'));
	buyer_cluster2=(buyer_group in ('A','B','D','G','L'));
run;


title ' ';
proc logistic data=exer.life1s2 descending namelen=30;
	weight model_weight;
	model active=		age_inferred_13pct
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
						gender_female
						buyer_cluster1
						buyer_cluster2
						region_east
						region_south
						marital_divorced
						marital_widow
						marital_married_single
	/selection=stepwise maxstep=1 details;
run;


/*all varibles probchisq<.3*/
/*
age_inferred_13pct
age_most_rec_pub_record
age_of_oldest_trade
amt_past_due_balances
avg_mos_accts_open
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
inq_promo
num_past_due_accts
num_public_record_items
risk_score
tot_accts_30d_pd_in_24m
tot_accts_60d_pd_in_24m
tot_accts_60days_ever
tot_accts_90d_pd_in_24m
tot_accts_90days_ever
tot_accts_bad_debt_24m
tot_accts_bad_debt_ever
tot_accts_on_file
tot_accts_open_last_12m
tot_accts_paid_satis
tot_accts_paid_satis_24m
tot_open_accts_on_file
tot_open_accts_ut_gt_50p
tot_open_accts_ut_gt_75p
worst_credit_rating
gender_female
buyer_cluster1
buyer_cluster2
region_south
marital_divorced
marital_widow
marital_married_single
*/

data life1s2;
	set exer.life1s2;
run;

%macro segtran(var);
title "Evaluation of &var";

data life1s2;
	set life1s2;

	&var._sqrt=sqrt(1+&var);
	&var._log =log(1+&var);
	&var._sq  =(1+&var)**2;
run;

proc logistic data=life1s2 descending namelen=30;
	title "Regression for &var";
	weight model_weight;
	model active=&var &var._sq &var._sqrt &var._log
		/selection=stepwise maxstep=2 sle=.3 sls=.3;
run;

%mend;
%segtran(age_of_last_activity)
%segtran(age_of_most_recent_inq)
%segtran(age_of_oldest_trade)
%segtran(age_of_youngest_trade)
%segtran(amt_past_due_balances)
%segtran(avg_mos_accts_open)
%segtran(bankrupt_other_hh_member)
%segtran(bankruptcy_prior)
%segtran(collection_items)
%segtran(current_accts_30day)
%segtran(current_accts_60day)
%segtran(current_accts_90day)
%segtran(current_accts_bad_debt)
%segtran(current_accts_total)
%segtran(income)
%segtran(inq_bank_promo)
%segtran(inq_fin_last_6mos)
%segtran(inq_past_12mos)
%segtran(inq_promo)
%segtran(num_past_due_accts)
%segtran(num_public_record_items)
%segtran(risk_score)
%segtran(tot_accts_30d_pd_in_24m)
%segtran(tot_accts_30days_ever)
%segtran(tot_accts_60d_pd_in_24m)
%segtran(tot_accts_60days_ever)
%segtran(tot_accts_90d_pd_in_24m)
%segtran(tot_accts_90days_ever)
%segtran(tot_accts_bad_debt_24m)
%segtran(tot_accts_bad_debt_ever)
%segtran(tot_accts_on_file)
%segtran(tot_accts_open_last_12m)
%segtran(tot_accts_open_last_24m)
%segtran(tot_accts_open_last_3m)
%segtran(tot_accts_open_last_6m)
%segtran(tot_accts_paid_satis)
%segtran(tot_accts_paid_satis_24m)
%segtran(tot_bal_open_accts)
%segtran(tot_open_accts_bal_gt_0)
%segtran(tot_open_accts_on_file)
%segtran(tot_open_accts_ut_gt_50p)
%segtran(tot_open_accts_ut_gt_75p)
%segtran(worst_credit_rating)
;

%let selected =
age_of_most_recent_inq_log
age_of_most_recent_inq_sqrt
age_of_oldest_trade
age_of_youngest_trade_log
age_of_youngest_trade_sqrt
amt_past_due_balances_log
amt_past_due_balances_sq
avg_mos_accts_open_sqrt
bankruptcy_prior
collection_items_log
collection_items_sqrt
current_accts_30day_log
current_accts_30day_sq
current_accts_60day_log
current_accts_90day_log
current_accts_90day_sq
current_accts_bad_debt_log
current_accts_bad_debt_sqrt
current_accts_total_log
current_accts_total_sqrt
income_sqrt
income_sq
inq_bank_promo_log
inq_bank_promo_sqrt
inq_fin_last_6mos
inq_past_12mos_log
inq_past_12mos_sq
inq_promo_log
inq_promo_sq
num_past_due_accts_log
num_past_due_accts_sq
num_public_record_items_log
num_public_record_items_sqrt
risk_score_sqrt
tot_accts_30d_pd_in_24m_log
tot_accts_30d_pd_in_24m
tot_accts_60d_pd_in_24m_sq
tot_accts_60days_ever_sq
tot_accts_90d_pd_in_24m_log
tot_accts_90days_ever_log
tot_accts_90days_ever_sqrt
tot_accts_bad_debt_24m_log
tot_accts_bad_debt_24m
tot_accts_bad_debt_ever_log
tot_accts_bad_debt_ever_sqrt
tot_accts_on_file_log
tot_accts_open_last_12m_log
tot_accts_paid_satis_log
tot_accts_paid_satis_sqrt
tot_accts_paid_satis_24m_log
tot_accts_paid_satis_24m_sqrt
tot_open_accts_on_file_log
tot_open_accts_ut_gt_50p_log
tot_open_accts_ut_gt_50p_sq
tot_open_accts_ut_gt_75p_log
tot_open_accts_ut_gt_75p_sq
worst_credit_rating
;

data exer.life1s3 (keep=
active
records
model_weight
sample_weight
split_weight

&selected

age_miss
gender_female
buyer_cluster1
buyer_cluster2
region_east
region_south
marital_divorced
marital_widow
marital_married_single
age_inferred_13pct
marital_status);

set life1s2;
run;

proc contents data=exer.life1s3 varnum;
run;

