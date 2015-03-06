set more off
set matsize 11000
*cd "C:\Users\mar60\Documents\Work\WITLstudy2013\BaselineDataPrep"
cd "D:\Dropbox\Projects\WITL\new_results"

***** variable names for baseline data
import excel "WITLvarnamesBaseline.xlsx", sheet("Sheet1") firstrow case(lower) clear
sort screentext screenresultanswertext
drop if screenresultanswertext=="" & variablename=="" & openendedtext=="" & screentext==""
replace screentext=subinstr(screentext,char(146),char(39),.) // right single quote replaced by normal single quote char(39)
replace screentext=subinstr(screentext,char(147),char(39),.) // left double quote replaced by normal single quote char(39)
replace screentext=subinstr(screentext,char(148),char(39),.) // right double quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,char(146),char(39),.) // right single quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,char(147),char(39),.) // left double quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,char(148),char(39),.) // right double quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,`"""',"",.) 
replace screentext=subinstr(screentext,`"""',"",.) 
replace screentext=trim(screentext)
*replace screentext=subinstr(screentext, " (Scroll Down)", "",.)
*replace screentext=subinstr(screentext, " (SCROLL DOWN)", "",.)
replace screenresultanswertext=trim(screenresultanswertext)
save WITLvarnamesBaseline, replace

* to deal with :
* single select, grid single select, grid scale - vallab
* openended single select - asis, string var
* multi select - create dummy
* open end of multiselect - create string var
* dropdown, Time, Numeric, Text - asis
* all have varlab

* non-multi, select (there are no openended non-multi select in baseline)
use WITLvarnamesBaseline, clear
* keep if screenresultanswertext==""  & openendedtext==""
keep if screentypename=="Grid - Single Select" | screentypename=="Single Select" | screentypename=="Grid Scale"
save WITLvarnamesBaseline_o, replace

* non-select
use WITLvarnamesBaseline, clear
keep if screentypename=="" 
save WITLvarnamesBaseline_g, replace

* multi-select without openend
use WITLvarnamesBaseline, clear
keep if screentypename=="Multi Select" & openendedtext~="Y"
save WITLvarnamesBaseline_m, replace

* openended of multi-select
use WITLvarnamesBaseline, clear
rename screentext screentext_y
keep if screentypename=="Multi Select" & openendedtext=="Y"
save WITLvarnamesBaseline_my, replace



***** get the latest baseline data
local rlst : dir .  files  "a week in the life- baseline survey (1.0) 201?????_standard_comma.csv"
di `"`rlst'"'
local n_files : word count `rlst'
local newfile `: word `n_files' of `rlst''
di `"`newfile'"'
import delimited "`newfile'", stripq(yes) bindquotes(strict) clear
forvalues x=1/999 {
	quietly: replace screentext=subinstr(screentext, "Q`x'.", "",.)
}
save baseline_temp, replace

** special case with a year 2000 time stamp. all the time stamps are in the 2000
	* except the screenresultanswerdate for the id quesion being normal. very very strange

use baseline_temp, clear
gen n=_n
gen double tlocal=clock(screenresultanswerdate, "YMDhms")
gen double tstart=clock(resultsurveyeddate, "YMDhms")
gen double tend=clock(resultsurveyedenddate, "YMDhms")
format tlocal tstart tend %tc
gen ylocal=yofd(dofc(tlocal))
gen ystart=yofd(dofc(tstart))
gen yend=yofd(dofc(tend))
* OK project management notes are needed to correct the time. I will only deal with a special case here for now
* this special case has the first screenresultanswerdate with a normal looking time, but everything else off. this affects latter program a bit
sort resultdevicename resultid screenresultanswerdate
gen dlocal=dofc(tlocal)
by resultdevicename resultid: egen double dlocal_max=max(dlocal)
by resultdevicename resultid: egen double dlocal_min=min(dlocal)
gen dlength=dlocal_max-dlocal_min

*keep screentext
replace screentext=subinstr(screentext,"’",char(39),.) // encoded right single quote, ASCII=char(226,128,153), replaced by normal single quote char(39)
replace screentext=subinstr(screentext,"“",char(39),.) // encoded left double quote, ASCII=char(226,128,156), replaced by normal single quote char(39)
replace screentext=subinstr(screentext,"”",char(39),.) // encoded right double quote, ASCII=char(226,128,157), replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,"’",char(39),.) // encoded right single quote, ASCII=char(226,128,153), replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,"“",char(39),.) // encoded left double quote, ASCII=char(226,128,156), replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,"”",char(39),.) // encoded right double quote, ASCII=char(226,128,157), replaced by normal single quote char(39)
replace screentext=trim(screentext)
replace screenresultanswertext=trim(screenresultanswertext)
*merge m:m screentext using WITLvarnamesBaseline
merge m:1 screentext screentypename using WITLvarnamesBaseline_o, keep(1 3)
rename _merge _merge_o
merge m:1 screentext using WITLvarnamesBaseline_g, keep(1 3 4 5) update
rename _merge _merge_g
merge m:1 screentext screenresultanswertext using WITLvarnamesBaseline_m, keep(1 3 4 5) update
rename _merge _merge_m
egen merge=concat(_merge_o _merge_g _merge_m)

gen screentext_y=screentext if merge=="111"
merge m:1 screentext_y using WITLvarnamesBaseline_my, keep(1 3 4 5) update
rename _merge _merge_my
*keep if inlist(_merge_my,5,2)
drop screentext_y
sort n

list n if screentext=="."
drop merge
egen merge=concat(_merge_o _merge_g _merge_m _merge_my)
ta merge
*tab1 screentypename screenresultanswertext if screentext==".", missing
*keep if merge=="1111"
save baseline_long, replace


* create data for var label
use baseline_long, clear
keep screentext variablename screenresultanswertext openendedtext
drop if inlist(variablename,"id","trimark")
bysort variablename: keep if _n==1
replace screenresultanswertext="" if strmatch(variablename,"*_*")~=1
replace screenresultanswertext="openendedtext" if screenresultanswertext~="" & openendedtext=="Y"
gen screentext77=substr(screentext,1,77)
egen label=concat(screentext screenresultanswertext), p("=")
replace label=screentext if screenresultanswertext==""
gen label77=substr(label,1,77)
gen screentext_len=strlen(screentext)
gen screenresultanswertext_len=strlen(screenresultanswertext)
gen label_len=strlen(label)
save baseline_varlab, replace

* create the do file for var label
use baseline_varlab, clear
capture file close varlab
file open varlab using "baseline_varlab.do", write text replace
local n=_N
di `n'
forvalues x=1/`n' {
	*di `x'
	if screenresultanswertext[`x']=="" & screentext_len<78 {
		*di `x'
		file write varlab  `"lab var `=variablename[`x']' "`=screentext77[`x']'""' _n
	}
	else if screenresultanswertext[`x']=="" {
		*di `x'
		file write varlab  `"lab var `=variablename[`x']' "`=screentext77[`x']'""' _n
		file write varlab  `"notes `=variablename[`x']': "`=screentext[`x']'""' _n
	}
	else if screenresultanswertext[`x']~="" & label_len<78 {
		*di `x'
		file write varlab  `"lab var `=variablename[`x']' "`=screentext[`x']'""' _n
		file write varlab  `"notes `=variablename[`x']': "`=label[`x']'""' _n
	}
	else if screenresultanswertext[`x']~="" {
		*di `x'
		file write varlab  `"lab var `=variablename[`x']' "`=label77[`x']'""' _n
		file write varlab  `"notes `=variablename[`x']': "`=label[`x']'""' _n
	}
}
file close varlab

***** reshape to wide 
use baseline_long, clear
keep resultdevicename resultid surveyname screenresultanswertext variablename dlocal_min
drop if inlist(variablename,"id","trimark")
drop if variablename==""
reshape wide screenresultanswertext, i(resultid) j(variablename, string)
compress
quietly: rename screenresultanswertext* *
compress
quietly: do baseline_varlab.do
save baseline, replace
