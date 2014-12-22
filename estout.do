sysuse auto, clear
recode rep78 (1/3=1) (4/5=0), gen(rep)
global outdir "d:"
local indvar displacement gear_ratio
local count=0
foreach x of local indvar {
	xi: mvreg headroom trunk turn = i.rep price mpg `x'
	estadd beta
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mvr_results_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') `reporapp'
}
insheet using "$outdir\mvr_results_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)


global outdir "d:"
local indvar igf2_cbs1_mean igf2_dmr_mean meg3_cbs_mean meg3_ig_mean mestit1_mean nnat_mean peg3_mean sgce_mean zac_mean 
local count=0
foreach x of local indvar {
	xi: mvreg internal external EFFORT_CONTROL NEGATIVE_AFFECT surgency  = `x' ///
		MONTH_OLD i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker i.momdepanx mom_age_delv if  (MONTH_OLD >=11.9) & (cohort == 1)
	estadd beta
	if `count'==0 estout using "$outdir\mvr_results_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') replace
	else estout using "$outdir\mvr_results_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') append
	local count=`count'+1
}
insheet using "$outdir\mvr_results_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)


local fname "basc"
local indvar igf2_cbs1_mean igf2_dmr_mean meg3_cbs_mean meg3_ig_mean mestit1_mean nnat_mean peg3_mean sgce_mean zac_mean  
local count=0
foreach x of local indvar {
	xi: mvreg  BASC_HY BASC_AG BASC_AX BASC_DP BASC_SM BASC_AT BASC_WD BASC_AP  = `x' ///
		i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker mom_age_delv age_mo_SR_Surv cohort i.momdepanx if (age_mo_SR_Surv >=24) &( age_mo_SR_Surv<=72)
	estadd beta
	if `count'==0 estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') replace
	else estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') append
	local count=`count'+1
}
insheet using "$outdir\mvr_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)


local fname "basc_i"
local indvar igf2_cbs1_mean igf2_dmr_mean meg3_cbs_mean meg3_ig_mean mestit1_mean nnat_mean peg3_mean sgce_mean zac_mean  
local count=0
foreach x of local indvar {
	xi: mvreg  BASC_HY BASC_AG BASC_AX BASC_DP BASC_SM BASC_AT BASC_WD BASC_AP  = i.BABY_GENDER*`x' ///
		i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker mom_age_delv age_mo_SR_Surv cohort i.momdepanx if (age_mo_SR_Surv >=24) &( age_mo_SR_Surv<=72)
	estadd beta
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") ///
		keep(`x' _IBABY_GENDER_1 _IBABY_GENDERX`x'_1) `reporapp' 
}
insheet using "$outdir\mvr_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)



local fname "cbs_mvr"
local indvar meg3_cbs_pos1 meg3_cbs_pos2 meg3_cbs_pos3 meg3_cbs_pos4 meg3_cbs_pos5 meg3_cbs_pos6 meg3_cbs_pos7 meg3_cbs_pos8 meg3_cbs_mean  
local count=0
foreach x of local indvar {
	xi: mvreg inhibition depression anxiety seperation = `x' ///
		MONTH_OLD i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker i.momdepanx mom_age_delv if  (MONTH_OLD >=11.9) & (cohort == 1)
	estadd beta
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') `reporapp' 
}
insheet using "$outdir\mvr_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)

local fname "cbs_reg"
local indvar meg3_cbs_pos1 meg3_cbs_pos2 meg3_cbs_pos3 meg3_cbs_pos4 meg3_cbs_pos5 meg3_cbs_pos6 meg3_cbs_pos7 meg3_cbs_pos8 meg3_cbs_mean  
local count=0
foreach x of local indvar {
	xi: mvreg surgency = `x' ///
		MONTH_OLD i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker i.momdepanx mom_age_delv if  (MONTH_OLD >=11.9) & (cohort == 1)
	estadd beta
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') `reporapp' 
}
insheet using "$outdir\mvr_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)

local fname "ig_reg"
local indvar meg3_ig_pos1 meg3_ig_pos2 meg3_ig_pos3 meg3_ig_pos4 meg3_ig_mean  
local count=0
foreach x of local indvar {
	xi: mvreg surgency = `x' ///
		MONTH_OLD i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker i.momdepanx mom_age_delv if  (MONTH_OLD >=11.9) & (cohort == 1)
	estadd beta
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') `reporapp' 
}
insheet using "$outdir\mvr_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)

local fname "dmr_mvr"
local indvar igf2_dmr_pos1 igf2_dmr_pos2 igf2_dmr_pos3  igf2_dmr_mean  
local count=0
foreach x of local indvar {
	xi: mvreg peeraggression impulsivity aggression = `x' ///
		MONTH_OLD i.race_final i.BABY_GENDER i.education4 BABY_WEIGHT i.smoker i.momdepanx mom_age_delv if  (MONTH_OLD >=11.9) & (cohort == 1)
	estadd beta
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mvr_`fname'_wide.txt", unstack cells("b(fmt(2)) se(fmt(2)) beta(fmt(2)) p(fmt(2))") keep(`x') `reporapp' 
}
insheet using "$outdir\mvr_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)




local fname "BMIPCT_4cat"
local indvar BRF_IN BRF_SF BRF_EC BRF_WM BRF_PO BASC_HY BASC_AP SWAN_INR SWAN_HIR
local count=0
foreach x of local indvar {
	xi: mlogit BMIPCT_4cat `x' ///
		BABY_WEIGHT GestAge_TotalDays age_mo_SR_Surv mom_age_delv i.race_final4 i.BABY_GENDER  i.education4 days_survey_to_htwt  ///
		if NESTSR_Selectvar2 == 1, base(1) rrr
	if `count++'==0 local reporapp "replace"
	else local reporapp "append"
	estout using "$outdir\mlogit_`fname'_wide.txt", unstack eform cells("b(fmt(2) label(OR)) ci(par fmt(2) label([95% CI])) _star") ///
		starlevels(+ 0.10 * 0.05) sub("," " - " "[" "(" "]" ")") keep(`x') drop(o.`x') `reporapp' 
}
insheet using "$outdir\mlogit_`fname'_wide.txt", tab clear
keep if v1~="" | inlist(_n,2,3)
replace v4="" if _n==2
replace v7="" if _n==2
replace v10="" if _n==2
* first look
egen new0=concat(v2 v3)
egen new2=concat(v5 v6)
egen new3=concat(v8 v9)
keep v1 v4 v7 v10 new*
order v1 new0 v4 new2 v7 new3 v10

* alternative look
egen new0=concat(v2 v3 v4)
egen new2=concat(v5 v6 v7)
egen new3=concat(v8 v9 v10)



