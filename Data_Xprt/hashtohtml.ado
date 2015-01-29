program hashtohtml
	di ""
	di "Creating des_all.html with descriptive tables for each data in this folder."
	local file_list : dir . files  "*_ss.dta", respectcase
	local hash_list : subinstr local file_list "_ss.dta" "", all
	capture htclose
	htopen using des_all, replace
	htput <link rel=stylesheet href="R2HTMLa.css" type=text/css>
	htput <body style="margin-top: 0; margin-bottom: 5px">
	foreach h of local hash_list {
		local hash : dir . files `"`h'_ss.dta"', respectcase
		if `"`hash'"'~="" {
			use "`h'_ss.dta", clear
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
			htput <tr><td><b>Total # of entries</b></a> </td><td>`=_N'</td><tr>
			unab qvars: q_*
			htput <tr><td><b>Total # of questions</b></a> </td><td>`: word count `qvars''</td><tr>
			htput </table></td></tr></table><br><hr>
		}
	}
	htput </body>
	htclose	
end
