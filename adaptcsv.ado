// Name: adaptcsv.ado 
// Author: Victor Wang
// Description: this program reads csv file exported from https://github.com/mnipper/rails_survey
//              and convert it to wide format Stata data, 
//              and apply variable labels, value labels, 
//              and create dummy variables for multi select type variables. 
//              It converts one csv file a time. 

// How to use it:
// 1, Set the Stata working directory to the folder the csv file is located using the "cd" command. 
// 2, Type -adaptcsv "filename"- note: do NOT add the .csv extension name and put the filename in double quote
// 3a, If the varialbe names are too long, try -adaptcsv "filename" "shorten"-. "shorten" needs to be typed as is. 
//    It will shorten the variable name to fit stata requirements but it will also add "_#" to the end of all variable names. 
// 3b, If the varialbe names are too long, you can also try -adaptcsv "filename" "short"-. "short" needs to be typed as is. 
//    It will use the short_qid in stead of qid as the variable name to fit stata requirements. 

program adaptcsv

	args filename short
	insheet using "`filename'.csv", comma clear case
	quietly tostring question_version_number, replace
	quietly replace question_version_number="n1" if question_version_number=="-1"
	if "`short'"=="short" quietly replace qid=short_qid + "_" + question_version_number
	else quietly replace qid=qid + "_" + question_version_number
	quietly replace short_qid=short_qid + "_" + question_version_number
	drop question_version_number
	sort device_user_id survey_id short_qid response_time_ended
	quietly by device_user_id survey_id short_qid: keep if _n==_N // keep only the latest qid for each question
	sort survey_id short_qid
	tempfile original
	quietly quietly save `original', replace

	* option to shorten the variable names to fit stata
	if "`short'"=="shorten" {
		use qid using `original', clear
		bysort qid: keep if _n==1
		gen qid_s=abbrev(qid,27)
		quietly replace qid_s=subinstr(qid_s,"~","",.)
		quietly bysort qid_s: gen n=_n
		quietly tostring n, replace
		quietly replace qid_s=qid_s + "_" + n
		sort qid
		drop n
		quietly merge 1:m qid using `original', nogen
		rename (qid qid_s) (qid_l qid)
		drop qid_l
		quietly save `original', replace
	}

	* reshape to wide format
	use `original', clear
	quietly rename (response response_labels special_response other_response device_user_id device_user_username) (rs_ la_ sp_ ot_ id_ nm_)
	quietly drop short_qid question_type question_text response_time_started response_time_ended
	quietly reshape wide rs_ la_ sp_ ot_ id_ nm_, i(survey_id) j(qid, string)
	rename rs_* *
	rename sp_* *_sp
	rename ot_* *_ot
	rename la_* *_la
	rename id_* *_id
	rename nm_* *_nm
	tempfile original_wide
	quietly save `original_wide', replace

	* keep single for val lab
	use `original', clear
	keep if strmatch(question_type,"*SELECT_ONE*")
	if _N>0 {
		destring response, replace
		quietly drop if response==.
		bysort qid response: keep if _n==1
		keep qid response response_labels
		bysort qid: gen qid_n=_n
		bysort qid: gen qid_n2=_N
		quietly replace response_labels="No Label Found!" if response_labels==""
		capture file close vallab
		file open vallab using "vallab.do", write text replace
		local n=_N
		* di `n'
		forvalues x=1/`n' {
			* di `=qid_n[`x']'
			if `=qid_n[`x']'==1 file write vallab `"quietly lab def `=qid[`x']' `=response[`x']' `"`=response_labels[`x']'"' "' _n
			else file write vallab `"quietly lab def `=qid[`x']' `=response[`x']' `"`=response_labels[`x']'"', add"' _n
			if `=qid_n[`x']'==`=qid_n2[`x']' file write vallab `"capture: quietly lab val `=qid[`x']' `=qid[`x']'"' _n
		}
		file close vallab
		local vallab=1
	}
	else local vallab=0

	* keep multi for val lab
	use `original', clear
	keep if strmatch(question_type,"*SELECT_MULTIPLE*")
	if _N>0 {
		split response if strmatch(question_type,"*SELECT_MULTIPLE*"), p(",")
		split response_labels if strmatch(question_type,"*SELECT_MULTIPLE*"), p(",")
		rename response response_original
		rename response_labels response_labels_original
		quietly gen n=_n
		quietly reshape long response response_labels, i(n) j()
		quietly destring response, replace
		quietly drop if response==.
		bysort qid response: keep if _n==1
		keep qid response question_type question_text response_labels
		bysort qid: gen qid_n=_n
		bysort qid: gen qid_n2=_N
		quietly gen q_multi_var_lab=string(response) + "-" + response_labels + ": " + question_text
		quietly gen q_multi_var_lab_len=strlen(q_multi_var_lab)

		capture file close varlab2
		file open varlab2 using "varlab2.do", write text replace
		local n=_N
		* di `n'
		forvalues x=1/`n' {
			if `=qid_n[`x']'==1 file write varlab2 `"quietly gen `=qid[`x']'_br = "," + `=qid[`x']' + "," "' _n
			file write varlab2 `"capture: quietly gen `=qid[`x']'_`=response[`x']'=cond(strmatch(`=qid[`x']'_br,`"*,`=response[`x']',*"'),1,cond(strmatch(`=qid[`x']'_br,""),.,0))"' _n
			file write varlab2 `"capture: quietly lab var `=qid[`x']'_`=response[`x']' "`=q_multi_var_lab[`x']'""' _n
			file write varlab2 `"capture: quietly notes `=qid[`x']'_`=response[`x']': "`=question_type[`x']'""' _n
			if q_multi_var_lab_len[`x']>77 file write varlab2 `"capture: quietly notes `=qid[`x']'_`=response[`x']': "`=q_multi_var_lab[`x']'""' _n
			if `=qid_n[`x']'==`=qid_n2[`x']' file write varlab2 `"quietly drop `=qid[`x']'_br"' _n
		}
		file close varlab2
			local varlab2=1
	}
	else local varlab2=0

	*** create var labs
	use `original', clear
	quietly bysort short_qid: keep if _n==1
	keep qid question_type question_text response response_labels
	quietly gen question_text_len=strlen(question_text)

	capture file close varlab
	file open varlab using "varlab.do", write text replace
	local n=_N
	* di `n'
	forvalues x=1/`n' {
		file write varlab `"quietly lab var `=qid[`x']' "`=question_text[`x']'""' _n
		file write varlab `"quietly notes `=qid[`x']': "`=question_type[`x']'""' _n
		if question_text_len[`x']>77 file write varlab `"quietly notes `=qid[`x']': "`=question_text[`x']'""' _n
	}
	file close varlab

	* apply all generated codes
	use `original_wide', clear
	quietly do varlab.do
	if "`varlab2'"=="1" quietly do varlab2.do
	quietly destring *, replace
	if "`va1lab'"=="1" quietly do vallab.do
	quietly order survey_id survey_uuid instrument_id instrument_version_number instrument_title ///
		device_id device_uuid participant_type ChildCaregiver participant_uuid
	save "`filename'.dta", replace

end
