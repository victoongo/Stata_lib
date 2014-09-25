set more off
set matsize 11000
cd "D:\csvtostata"

***** variable names for mobile data
* additional complication: single select with openendedtext
*insheet using "Baseline_Survey.csv", comma clear case
insheet using "Test_Instrument_One_-_types.csv", comma clear case
*insheet using "buggy.csv", comma clear case
capture gen device_user=. //
capture gen response_time_started=. //
capture gen response_time_ended=. //
sort device_user survey_uuid short_qid response_time_ended
by device_user survey_uuid short_qid: keep if _n==_N // keep only the latest qid for each question
sort survey_uuid short_qid
tempfile original
save original, replace

* create artificial numeric survey_uuid, will be replaced by index in later version csv
keep survey_uuid
bysort survey_uuid: keep if _n==1
gen survey_uuid_n=_n // 
sort survey_uuid
*tempfile uuid
*save `uuid', replace
merge 1:m survey_uuid using original, nogen
tempfile original_n
save original_n, replace

* reshape to wide format
use original_n, clear
*drop if strmatch(question_type,"*SELECT_MULTIPLE*")
drop short_qid question_type question_text
reshape wide response response_labels special_response other_response, i(survey_uuid_n) j(qid, string)
*rename special_response* *
*rename other_response* *
*rename response_labels* *
rename response* *
tempfile original_wide
save original_wide, replace

* keep single for val lab
use original_n, clear
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
use original_n, clear
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
	*if `=qid_n[`x']'==`=qid_n2[`x']' file write varlab2 `"drop `=qid[`x']'_br"' _n
}
file close varlab2

*** create var labs. done
use original, clear
bysort short_qid /*short_qid_version*/: keep if _n==1
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

use original_wide, clear
do varlab.do
do varlab2.do
destring *, replace
do vallab.do
