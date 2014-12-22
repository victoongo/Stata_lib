***** development test program for adaptcsv.ado *****
set more off
set matsize 11000
cd "D:\Dropbox\Projects\WITL\csvtostata"

/*
adaptcsv "Test_Instrument_One_-_types"
*/

********** instrument level 
***** variable names for mobile data
* additional complication: single select with openendedtext
*insheet using "Baseline_Survey.csv", comma clear case
insheet using "Test_Instrument_One_-_types.csv", comma clear case
*insheet using "buggy.csv", comma clear case
*insheet using "first_test.csv", comma clear case
*insheet using "Week_In_The_Life.csv", comma clear case
tostring question_version_number, replace
replace question_version_number="n1" if question_version_number=="-1"
replace qid=qid + "_v" + question_version_number
replace short_qid=short_qid + "_v" + question_version_number
drop question_version_number
*egen qidv=concat(qid question_version_number)
*replace qid=qidv
*egen s_qidv=concat(short_qid question_version_number)
*replace short_qid=s_qidv
*drop qidv s_qidv
sort device_user_id survey_id short_qid response_time_ended
by device_user_id survey_id short_qid: keep if _n==_N // keep only the latest qid for each question
sort survey_id short_qid
drop if device_user_id==.
tempfile original
save `original', replace

* reshape to wide format
use `original', clear
rename (response response_labels special_response other_response device_user_id device_user_username) (response_ labels_ special_ other_ du_id_ du_name_)
*drop if strmatch(question_type,"*SELECT_MULTIPLE*")
drop short_qid question_type question_text response_time_started response_time_ended
reshape wide response labels_ special_ other_ du_id_ du_name_, i(survey_id) j(qid, string)
rename special_* *_sp
rename other_* *_oth
rename labels_* *_lab
rename response_* *
rename du_id_* *_du_id
rename du_name_* *_du_name
tempfile original_wide
save `original_wide', replace

* keep single for val lab
use `original', clear
keep if strmatch(question_type,"*SELECT_ONE*")
drop if response==""
bysort qid response: keep if _n==1
keep qid response response_labels
bysort qid: gen qid_n=_n
bysort qid: gen qid_n2=_N
capture file close vallab
file open vallab using "vallab.do", write text replace
local n=_N
di `n'
forvalues x=1/`n' {
	di `=qid_n[`x']'
	if `=qid_n[`x']'==1 file write vallab `"lab def `=qid[`x']' `=response[`x']' `"`=response_labels[`x']'"' "' _n
	else file write vallab `"lab def `=qid[`x']' `=response[`x']' `"`=response_labels[`x']'"', add"' _n
	if `=qid_n[`x']'==`=qid_n2[`x']' file write vallab `"capture: lab val `=qid[`x']' `=qid[`x']'"' _n
}
file close vallab

* keep multi for val lab
use `original', clear
keep if strmatch(question_type,"*SELECT_MULTIPLE*")
*keep if strmatch(question_type,"*SELECT_MULTIPLE*") | strmatch(question_type,"*SELECT_ONE*")
split response if strmatch(question_type,"*SELECT_MULTIPLE*"), p(",")
split response_labels if strmatch(question_type,"*SELECT_MULTIPLE*"), p(",")
rename response response_original
rename response_labels response_labels_original
gen n=_n
reshape long response response_labels, i(n) j()
destring response, replace
drop if response==.
bysort qid response: keep if _n==1
keep qid response question_type question_text response_labels
bysort qid: gen qid_n=_n
bysort qid: gen qid_n2=_N
gen q_multi_var_lab=string(response) + "-" + response_labels + ": " + question_text
gen q_multi_var_lab_len=strlen(q_multi_var_lab)

capture file close varlab2
file open varlab2 using "varlab2.do", write text replace
local n=_N
di `n'
forvalues x=1/`n' {
	if `=qid_n[`x']'==1 file write varlab2 `"gen `=qid[`x']'_br = "," + `=qid[`x']' + "," "' _n
	file write varlab2 `"capture: gen `=qid[`x']'_`=response[`x']'=cond(strmatch(`=qid[`x']'_br,`"*,`=response[`x']',*"'),1,cond(strmatch(`=qid[`x']'_br,""),.,0))"' _n
	file write varlab2 `"capture: lab var `=qid[`x']'_`=response[`x']' "`=q_multi_var_lab[`x']'""' _n
	file write varlab2 `"capture: notes `=qid[`x']'_`=response[`x']': "`=question_type[`x']'""' _n
	if q_multi_var_lab_len[`x']>77 file write varlab2 `"capture: notes `=qid[`x']'_`=response[`x']': "`=q_multi_var_lab[`x']'""' _n
	if `=qid_n[`x']'==`=qid_n2[`x']' file write varlab2 `"drop `=qid[`x']'_br"' _n
}
file close varlab2

*** create var labs. 
use `original', clear
bysort short_qid: keep if _n==1
keep qid question_type question_text response response_labels
gen question_text_len=strlen(question_text)

capture file close varlab
file open varlab using "varlab.do", write text replace
local n=_N
di `n'
forvalues x=1/`n' {
	file write varlab `"lab var `=qid[`x']' "`=question_text[`x']'""' _n
	file write varlab `"notes `=qid[`x']': "`=question_type[`x']'""' _n
	if question_text_len[`x']>77 file write varlab `"notes `=qid[`x']': "`=question_text[`x']'""' _n
}
file close varlab

use `original_wide', clear
do varlab.do
*!del varlab.do
do varlab2.do
destring *, replace
do vallab.do

save "filename.dta", replace
