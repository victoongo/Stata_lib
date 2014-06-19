program yamltostata
	local pwd: pwd
	if "`1'"~="" {
		capture: cd "`1'"
		if _rc~=0 {
			di as err "The path you specified does NOT exist!"
			cd "`pwd'"
			exit
		}
	}
	else local lookuppath "."
	
	cd "$dopath"
	local file_list : dir . files "lab_*.do", respectcase
	local file_list1 : subinstr local file_list ".do" "", all
	local hash_list : subinstr local file_list1 "lab_" "", all
	local n_hash: word count `hash_list'
	di "`n_hash'"
	forvalues i=1/`n_hash' {
		local hash: word `i' of `hash_list'
		di "`hash'"
		insheet using "q_`hash'.csv", clear
		replace response_options_number=999 if response_options_number==.
		rename response_options_text response_options_text_
		quietly: reshape wide response_options_text, i(unique_id) j(response_options_number)
		gen hash="`hash'"
		order hash section question_order_number variable_name unique_id question_identifier question_type question_text
		capture drop response_options_text_999
		sort hash section question_order_number
		if `i'>1 quietly: append using "`lookuppath'/lookup_table.dta"
		save "`lookuppath'/lookup_table.dta", replace
	}
end
