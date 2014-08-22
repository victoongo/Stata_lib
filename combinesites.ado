program combinesites
	if "`3'"=="" {
		di as err "Requires two or more source directories to combine!"
		exit
	}
	* insert a marker so that combined data are named differently. 
	* check to make sure there are no duplicates in the list of path. 
	* ask yes/no to continue with default action
	local pwd: pwd
	forvalues x=1/100 {
		if "``x''"~="" {
			capture: cd "``x''"
			if _rc~=0 {
				if "`x'"=="1" di as err "The first path (destination for combined data) does NOT exist!"
				else di as err "Path ``x'' (a path where source data is located) does NOT exist!"
				exit
			}
			else if "`x'"~="1" {
				if "``x''"~="`1'" {
					local dta_lst : dir . files "*.dta", respectcase
					if `"`dta_lst'"'=="" {
						di as err "The path you provided does NOT contain stata data files for combining!"
						quietly: cd "`pwd'"
						exit
					}
				}
				else di as err "The No. `=`x'-1' source path is the same as the destination path."
			}
		}
		else {
			local nofpath=`x'-1
			continue, break
		}
	}
	
	clear 
	set matsize 11000
	set maxvar 32767
	local file_list : dir "$dopath"  files  "lab_*.do", respectcase
	local file_list1 : subinstr local file_list ".do" "", all
	local hash_list : subinstr local file_list1 "lab_" "", all
	foreach hash of local hash_list {
		local counter=0
		forvalues x=2/`nofpath' {
			quietly: cd "``x''"
			clear 
			local dta_file : dir . files "`hash'_l.dta", respectcase
			if `"`dta_file'"'~="" {
				if `counter'==1 di "Combining `hash'"
				local ++counter
				use "`hash'_l.dta", clear
				capture tostring special, replace
				if `counter'>1 append using "`1'/combined_`hash'_l.dta"
				quietly: save "`1'/combined_`hash'_l.dta", replace
			}
		}
		quietly: cd "`1'"
		clear 
		local dta_file : dir . files "`hash'_l.dta", respectcase
		if `"`dta_file'"'~="" {
			use "combined_`hash'_l.dta"
			hashlongtowide `hash' combine
		}
	}
	quietly: cd "`1'"
	hashtohtml 
end
