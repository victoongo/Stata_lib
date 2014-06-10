program define csvtostata
syntax , [NOSUBDIR] [COMBINE] [HTML]
	if "`nosubdir'"~="" & "`combine'"~="" {
		di as err "Only one of nosubdir or combine is allowed."
		exit 
	}
	
	clear 
	set matsize 11000
	set maxvar 32767
	
	if "`nosubdir'"~="" {
		local pwd: pwd
		local pwd: subinstr local pwd "\" " ", all
		local pwd_n: word count `pwd'
		local last_dir: word `pwd_n' of `pwd'
		di "`pwd' `pwd_n' `last_dir'"
		local sql_list `last_dir'
		cd ..
	}
	else {
		local dir_list: dir . dirs  *, respectcase
		local od_list `""Archive" "code" "Combined" "yaml""'
		local data_list: list dir_list - od_list
		local data_list: list clean data_list
		local sql_list
		foreach x of local data_list {
			capture confirm file "./`x'/csv/data_entry.sqlite3"
			if _rc==0 {
				local sql_list `sql_list' `x'
				confirmdir ./`x' stata
			}
			else di `"Expecting data_entry.sqlite3 in dir "`pwd'/`x'/csv/ but did not find any!""'
		}
	}
	
	local pwd: pwd
	local pwd: subinstr local pwd "\" "/", all
	di "`pwd'"
	
	if "`combine'"~="" {
		local sql_list_count: word count `sql_list'
		if `sql_list_count'>1 {
			confirmdir . Combined
			confirmdir ./Combined stata
		}
	}
	
	local file_list : dir "./code/do"  files  "lab_*.do", respectcase
	local file_list1 : subinstr local file_list ".do" "", all
	local hash_list : subinstr local file_list1 "lab_" "", all
	di `"`hash_list'"'
	foreach hash of local hash_list {
		local counter=0
		foreach dir of local sql_list {
			cd "`pwd'/`dir'"
			clear 
			local csv_file : dir "./csv" files "`hash'.csv", respectcase
			di `"`csv_file'"'
			if `"`csv_file'"'~="" {
				insheet using "./csv/`hash'.csv"
				if _N>0 {
					gen __dir_name="`dir'"
					order __dir_name
					quietly: tostring other, replace
					quietly: save "./stata/`hash'_l.dta", replace
					hashlongtowide `hash'
					
					if "`combine'"~="" {
						pwd
						di "prior"
						local ++counter
						di "`counter'"
						if `counter'==1 {
							use "./stata/`hash'_l.dta", clear
							save "../Combined/stata/`hash'_l.dta", replace
						}
						else if `counter'>1 {
							use "./stata/`hash'_l.dta", clear
							append using "../Combined/stata/`hash'_l.dta"
							save "../Combined/stata/`hash'_l.dta", replace
						}
					}
				}
			}
			else di `"`hash'.csv does not exist in `dir'"'
			
		}
		if "`combine'"~="" {
			cd "`pwd'/Combined"
			clear //all
			local dta_file : dir "./stata" files "`hash'_l.dta", respectcase
			di `"`dta_file'"'
			if `"`dta_file'"'~="" {
				use "./stata/`hash'_l.dta"
				hashlongtowide `hash'
			}
		}
	}
	di "before `sql_list'"
	pwd
	if "`html'"~="" {
		di "after "
		if "`combine'"~="" local sql_list `sql_list' Combined
		di "post `sql_list'"
		foreach dir of local sql_list {
			di "in html"
			cd "`pwd'/`dir'/stata"
			hashtohtml 
		}
	}
end

program confirmdir
	args place target
	local dir: dir "`place'" dirs "`target'", respectcase
	local dir_count: word count `dir'
	if `dir_count'==0 {
		di "./`x'/stata does not exist"
		!mkdir "`place'/`target'"
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
	*compress

	run "../code/do/lab_`hash'.do"

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
	local file_list : dir . files  "*_ss.dta", respectcase
	di `"`file_list'"'
	local hash_list : subinstr local file_list "_ss.dta" "", all
	di `"`hash_list'"'
	capture htclose
	htopen using ./des_all, replace
	htput <link rel=stylesheet href="R2HTMLa.css" type=text/css>
	htput <body style="margin-top: 0; margin-bottom: 5px">
	foreach h of local hash_list {
		di "`h'"
		local hash : dir . files `"`h'_ss.dta"', respectcase
		di `"`hash'"'
		if `"`hash'"'~="" {
			use "./`h'_ss.dta", clear
			htput <h3>`hash'</h3>
			htput <table cellspacing=0 border=1><tr><td><table border=0 cellpadding="4" cellspacing="2"><tr class= firstline><td>Variable Names</td><td>Values</td></tr>
			local tag __project_name __instrument_name __participant_type __instrument_version_name  __round_name 
			foreach t of local tag {
				quietly: levels `t', local(uniqlist)
				local uniqlst `uniqlist'
				htput <tr><td><b>`t'</b></a> </td><td>`uniqlst'</td><tr>
			}
			
			local tag __user_id __interviewer_name __entry_type 
			foreach t of local tag {
				tostring `t', replace
				quietly: levels `t', local(uniqlist)
				local n: word count `uniqlist'
				di `uniqlist'
				di "`n'" " **nn"
				local uniqlist: list clean uniqlist
				if `n'==1 local lst `uniqlist'
				else {
					forvalues x=1/`n' {
						quietly: count if `t'=="`: word `x' of `uniqlist''"
						di r(N)
						if `x'==1 local lst `: word `x' of `uniqlist''(`=r(N)')
						else local lst `: word `x' of `uniqlist''(`=r(N)'), `lst' 
						di "`: word `x' of `uniqlist''"
						di "`lst'"
					}
				}
				htput <tr><td><b>`t'</b></a> </td><td>`lst'</td><tr>
			}
			htput <tr><td><b>Sample Size</b></a> </td><td>`=_N'</td><tr>
			htput </table></td></tr></table><br><hr>
			di "ss"
		}
	}
	htput </body>
	htclose	
end
