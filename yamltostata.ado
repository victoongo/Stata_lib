program yamltostata
	cd D:/share/yaml
	local file_list : dir "./do"  files "lab_*.do", respectcase
	local file_list1 : subinstr local file_list ".do" "", all
	local hash_list : subinstr local file_list1 "lab_" "", all
	local n_hash: word count `hash_list'
	di "`n_hash'"
	forvalues i=1/`n_hash' {
		local hash: word `i' of `hash_list'
		di "`hash'"
		insheet using "./csv/q_`hash'.csv", clear
		replace response_options_number=999 if response_options_number==.
		rename response_options_text response_options_text_
		quietly: reshape wide response_options_text, i(unique_id) j(response_options_number)
		gen hash="`hash'"
		order hash section question_order_number variable_name unique_id question_identifier question_type question_text
		capture drop response_options_text_999
		sort hash section question_order_number
		save "q_`hash'.dta", replace
		if `i'==1 save q_all.dta, replace
		else {
			quietly: append using q_all
			*sort 
			save q_all, replace
		}
		!del q_`hash'.dta
	}
end
