program piev 
	quietly: ta `1'
	if r(r)>1 {
		local pie_col 
		local piecolor /*missing*/ angle(0) plabel(_all name, gap(10)) line(lcolor(white)) intensity(inten30) ///
			legend(rowgap(tiny) keygap(minuscule) region(lcolor(white))) ///
			graphregion(fcolor(white) lcolor(white) lwidth(none))
		*di "`piecolor'"

		local maxlen=0
		local vallab: val lab `1'
		local lenvallab: length local vallab
		if `lenvallab'>0 {
			quietly: labellist `1'
			local noflabels: word count `r(labels)'
			*di "`noflabels'" "`maxlen'"
			forvalues n=1/`noflabels' {
				local lab`n': word `n' of `r(labels)'
				local lab`n'len: length local lab`n'
				if `lab`n'len'>`maxlen' local maxlen=`lab`n'len'
				*di "`lab`n'len'**"  "`maxlen'"
			}
			*di "`maxlen'"
		}
		if `maxlen'>35 local pie_col legend(cols(1))
		graph pie, over(`1') `piecolor' `pie_col'
		graph export "img/`1'.png", replace
	}
end
