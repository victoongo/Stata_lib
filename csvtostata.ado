program define csvtostata
syntax 
	local pwd: pwd
	if "`1'"~="" {
		capture: cd "`1'"
		if _rc~=0 {
			di as err "The path you specified does NOT exist!"
			cd "`pwd'"
			exit
		}
	}
	local csv_list : dir . files  "new_*.csv", respectcase
	local csv_count: word count `csv_list'
	if `csv_count'>0 {
		local csv "found"
		di "Found csv files. Start conversion."
		di ""
	}
	else {
		if "`1'"=="" di as err "The working directory does NOT contain csv files that look like new_xxxxxxxxxxxxxxxxxx.csv!"
		else di as err "The path you specified does NOT contain csv files that look like new_xxxxxxxxxxxxxxxxxx.csv!"
		cd "`pwd'"
		exit
	}
	
	clear 
	set matsize 11000
	set maxvar 32767
	
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
					quietly: gen __dir_name="`pwd'/stata"
					order __dir_name
					quietly: tostring other, replace
					quietly: save "./stata/`hash'_l.dta", replace
					hashlongtowide `hash' stata_dir
					
				}
				else di "`csv_file' is empty"
			}
		}
		cd stata
		hashtohtml 
		cd ..
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
