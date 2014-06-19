program define csvtostata
syntax , [HTML]
	clear 
	set matsize 11000
	set maxvar 32767
	
	local csv_list : dir . files  "new_*.csv", respectcase
	local csv_count: word count `csv_list'
	if `csv_count'>0 {
		local csv "found"
		di "Found csv files. Start conversion."
		di ""
	}
	else {
		di as err "The path you provided does NOT contain csv files that look like new_xxxxxxxxxxxxxxxxxx.csv!"
		exit
	}
	
	if "`csv'"~="" {
		confirmdir stata

		local file_list : dir "$dopath" files  "lab_*.do", respectcase
		local file_list1 : subinstr local file_list ".do" "", all
		local hash_list : subinstr local file_list1 "lab_" "", all
		foreach hash of local hash_list {
			local counter=0
			clear 
			local csv_file : dir . files "new_`hash'.csv", respectcase
			if `"`csv_file'"'~="" {
				di `"Converting `csv_file' to Stata."'
				insheet using "new_`hash'.csv"
				if _N>0 {
					quietly: gen __dir_name="`dir'"
					order __dir_name
					quietly: tostring other, replace
					quietly: save "./stata/`hash'_l.dta", replace
					hashlongtowide `hash'
					
				}
				else di "`csv_file' is empty"
			}
		}
		if "`html'"~="" hashtohtml 
	}
end

program confirmdir
	args target
	local dir: dir . dirs "`target'", respectcase
	local dir_count: word count `dir'
	if `dir_count'==0 {
		di "`target' directory does NOT exist! Creating one..."
		!mkdir "`target'"
	}
end

program hashlongtowide
	args hash
	quietly: reshape wide response special other edituser edittime, i(__dir_name __entry_id) j(unique_id)
	quietly: rename response* q_*
	capture: rename special* q_*_special
	capture: rename other* q_*_other
	capture: rename edituser* q_*_edituser
	capture: rename edittime* q_*_edittime

	run "$dopath/lab_`hash'.do"

	quietly: compress
	quietly: destring *, replace
	order __*
	
	quietly: save "./stata/`hash'_all.dta", replace
	quietly: drop *edit*
	quietly: save "./stata/`hash'_s.dta", replace
	quietly: drop *other *special
	quietly: save "./stata/`hash'_ss.dta", replace
end
	
program hashtohtml
	di ""
	di "Creating des_all.html with descriptive tables for each data in this folder."
	local file_list : dir "./stata" files  "*_ss.dta", respectcase
	local hash_list : subinstr local file_list "_ss.dta" "", all
	capture htclose
	htopen using ./stata/des_all, replace
	htput <link rel=stylesheet href="R2HTMLa.css" type=text/css>
	htput <body style="margin-top: 0; margin-bottom: 5px">
	foreach h of local hash_list {
		local hash : dir "./stata" files `"`h'_ss.dta"', respectcase
		if `"`hash'"'~="" {
			use "./stata/`h'_ss.dta", clear
			htput <h3>`hash'</h3>
			htput <table cellspacing=0 border=1><tr><td><table border=0 cellpadding="4" cellspacing="2"><tr class= firstline><td>Variable Names</td><td>Values</td></tr>
			local tag __project_name __instrument_name __instrument_version_name  __round_name 
			foreach t of local tag {
				quietly: levels `t', local(uniqlist)
				local uniqlst `uniqlist'
				htput <tr><td><b>`t'</b></a> </td><td>`uniqlst'</td><tr>
			}
			
			local tag __participant_type __user_id __interviewer_name __entry_type 
			foreach t of local tag {
				quietly: tostring `t', replace
				quietly: levels `t', local(uniqlist)
				local n: word count `uniqlist'
				local uniqlist: list clean uniqlist
				if `n'==1 local lst `uniqlist'
				else {
					forvalues x=1/`n' {
						quietly: count if `t'=="`: word `x' of `uniqlist''"
						if `x'==1 local lst `: word `x' of `uniqlist''(`=r(N)')
						else local lst `: word `x' of `uniqlist''(`=r(N)'), `lst' 
					}
				}
				htput <tr><td><b>`t'</b></a> </td><td>`lst'</td><tr>
			}
			htput <tr><td><b>Sample Size</b></a> </td><td>`=_N'</td><tr>
			htput </table></td></tr></table><br><hr>
		}
	}
	htput </body>
	htclose	
end
