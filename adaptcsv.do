set more off
set matsize 11000
cd "D:\csvtostata"

***** variable names for mobile data
* additional complication: single select with openendedtext
insheet using "Baseline_Survey.csv", comma clear case
insheet using "Test_Instrument_One_-_types.csv", comma clear case
*insheet using "buggy.csv", comma clear case
capture gen device_user=. 
capture gen response_time_started=.
capture gen response_time_ended=.
sort device_user survey_uuid short_qid response_time_ended
by device_user survey_uuid short_qid: keep if _n==_N
sort survey_uuid short_qid
tempfile original
save `original', replace
keep survey_uuid
bysort survey_uuid: keep if _n==1
gen survey_uuid_n=_n
sort survey_uuid
*tempfile uuid
*save `uuid', replace
merge 1:m survey_uuid using `original', nogen

tempfile original_n
save `original_n', replace
keep if strmatch(question_type,"*SELECT_MULTIPLE*")
tempfile multi
save `multi', replace
use `original_n', clear
*drop if strmatch(question_type,"*SELECT_MULTIPLE*")
drop short_qid question_type question_text
reshape wide response response_labels special_response other_response, i(survey_uuid_n) j(qid, string)
*rename special_response* *
*rename other_response* *
*rename response_labels* *
rename response* *
tempfile original_wide
save `original_wide', replace
/*

*/

*** create var labs
use `original', clear
keep qid question_type question_text
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



use `original', clear
*keep if strmatch(question_type,"*SELECT_MULTIPLE*") | strmatch(question_type,"*SELECT_ONE*")
split response, p(",")
split response_labels, p(",")
rename response response_original
rename response_labels response_labels_original
gen n=_n
reshape long response response_labels, i(n) j()
destring response, replace
drop if response==.
bysort qid response: keep if _n==1
keep qid question_type response response_labels
bysort qid question_type: gen noptions=_n



use `original_wide', clear
do mobile_varlab.do
do mobile_vallab.do
save day_wide_wlab, replace
