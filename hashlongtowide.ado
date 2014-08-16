program hashlongtowide
	args hash 
	if "`2'"=="combine" local combined combined_
	quietly: reshape wide response special other edituser edittime, i(__dir_name __entry_id) j(unique_id)
	quietly: rename response* q_*
	capture: rename special* q_*_special
	capture: rename other* q_*_other
	capture: rename edituser* q_*_edituser
	capture: rename edittime* q_*_edittime

	do "$dopath/lab_`hash'.do"

	quietly: compress
	quietly: destring *, replace
	order __*
	
	local stata "./stata"
	if "`2'"=="" local stata "."
	quietly: save "`stata'/`combined'`hash'_all.dta", replace
	quietly: drop *edit*
	quietly: save "`stata'/`combined'`hash'_s.dta", replace
	quietly: drop *other *special
	quietly: save "`stata'/`combined'`hash'_ss.dta", replace
end
