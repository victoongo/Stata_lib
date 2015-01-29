set more off
set matsize 11000
*cd "C:\Users\mar60\Documents\Work\WITLstudy2013\MobileDataPrep"
cd "D:\Dropbox\Projects\WITL\new_results"

***** variable names for mobile data
* additional complication: single select with openendedtext
import excel "WITLvarnamesMobile.xlsx", sheet("Sheet1") firstrow case(lower) clear
drop f g
gen var_order=_n
drop if screentypename=="" & screenresultanswertext=="" & variablename=="" & openendedtext=="" & screentext==""
replace screentext=subinstr(screentext,char(146),char(39),.) // right single quote replaced by normal single quote char(39)
replace screentext=subinstr(screentext,char(147),char(39),.) // left double quote replaced by normal single quote char(39)
replace screentext=subinstr(screentext,char(148),char(39),.) // right double quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,char(146),char(39),.) // right single quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,char(147),char(39),.) // left double quote replaced by normal single quote char(39)
replace screenresultanswertext=subinstr(screenresultanswertext,char(148),char(39),.) // right double quote replaced by normal single quote char(39)
replace screenresultanswertext=trim(screenresultanswertext)
replace variablename=trim(variablename)
save WITLvarnamesMobile, replace

* non-multi select
use WITLvarnamesMobile, clear
keep if screenresultanswertext==""
save WITLvarnamesMobile_o, replace

* multi-select without openend
use WITLvarnamesMobile, clear
keep if screenresultanswertext~="" & openendedtext==""
save WITLvarnamesMobile_m, replace

* openend of multi-select
use WITLvarnamesMobile, clear
rename screentext screentext_y
keep if screenresultanswertext~="" & openendedtext=="Y"
save WITLvarnamesMobile_my, replace

* create full variablename list
use WITLvarnamesMobile, clear
drop if openendedtext=="Y" 
drop if inlist(variablename,"id","trimark","amsq01","amsq02")
keep var_order variablename
save WITLvarnamesMobile_varlst, replace

***** manual insheet 1.2
insheet using "A Week in the Life- Mobile Survey (1.2) 20140925_Standard_Comma.csv", names c clear
forvalues x=1/999 {
	quietly: replace screentext=subinstr(screentext, "Q`x'.", "",.)
}
save mobile_temp12, replace
 
***** get the latest mobile data
local rlst : dir .  files  "*mobile*(1.3)*.csv"
di `"`rlst'"'
local n_files : word count `rlst'
local newfile `: word `n_files' of `rlst''
di `"`newfile'"'
insheet using "`newfile'", names c clear
forvalues x=1/999 {
	quietly: replace screentext=subinstr(screentext, "Q`x'.", "",.)
}
save mobile_temp, replace
append using mobile_temp12
save mobile_temp, replace

** special case with a year 2000 time stamp. all the time stamps are in the 2000
	* except the screenresultanswerdate for the id quesion being normal. very very strange

use mobile_temp, clear
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
gen ysed=yend-ystart
gen yled=ylocal-ystart
ta yled
sort resultdevicename resultid screenresultanswerdate
by resultdevicename resultid: egen yled_max=max(yled)
by resultdevicename resultid: egen ylocal_max=max(ylocal)
by resultdevicename resultid: egen double tlocal_max=max(tlocal)
by resultdevicename resultid: egen double tlocal_min=min(tlocal)
*keep if yled_max>1 & ylocal_max>2012
by resultdevicename resultid : gen tlocald=tlocal-tlocal_min if _n~=1 & _n~=_N & yled_max>1 & ylocal_max>2012
by resultdevicename resultid: replace tlocald=1 if _n==1 & yled_max>1 & ylocal_max>2012
by resultdevicename resultid: replace tlocald=0 if _n==_N & yled_max>1 & ylocal_max>2012
replace tlocal=tlocal_max+tlocald if yled_max>1 & ylocal_max>2012

drop tlocal_min tlocal_max tlocald
by resultdevicename resultid: egen double tlocal_max=max(tlocal)
by resultdevicename resultid: egen double tlocal_min=min(tlocal)
gen tlength=tlocal_max-tlocal_min
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
merge m:1 screentext using WITLvarnamesMobile_o, keep(1 3)
rename _merge _merge_o
merge m:1 screentext screenresultanswertext using WITLvarnamesMobile_m, keep(1 3 4 5) update
rename _merge _merge_m
egen merge=concat(_merge_o _merge_m)

gen screentext_y=screentext if merge=="11"
merge m:1 screentext_y using WITLvarnamesMobile_my, keep(1 3 4 5) update
rename _merge _merge_my
*keep if inlist(_merge_my,5,2)
drop screentext_y
sort n

list n if screentext=="."
drop merge
egen merge=concat(_merge_o _merge_m _merge_my)
ta merge
tab1 screentypename screenresultanswertext if screentext==".", missing

sort resultdevicename resultid tlocal
by resultdevicename resultid : gen nn=_n
by resultdevicename resultid : gen n2=_N
ta screentext if nn==n2
ta screenresultanswertext if nn==n2, missing
list nn n2 screenresultanswertext if screentext=="." // & nn~=n2 
gen trimarkt=cond(variablename=="trimark" & screenresultanswertext=="Morning",1, ///
	cond(variablename=="trimark" & screenresultanswertext=="Afternoon",2, ///
	cond(variablename=="trimark" & screenresultanswertext=="Evening",3,.)))
bysort resultid resultdevicename: egen trimarki=mean(trimarkt)
gen trimark=cond(trimarki==1,"am",cond(trimarki==2,"as",cond(trimarki==3,"pm","")))
replace variablename="amlastq" if screentext=="." & trimarki==1
replace variablename="aslastq" if screentext=="." & trimarki==2
replace variablename="pmlastq" if screentext=="." & trimarki==3
replace screentext="anything else? last question" if screentext=="."
save mobile_long, replace

***** reshape to day wide 
use mobile_long, clear
keep resultdevicename resultid surveyname screenresultanswertext variablename trimark dlocal_min
drop if inlist(variablename,"id","trimark")
quietly: levelsof variablename, local(varnames_original)
replace variablename=substr(variablename, 3, .)
quietly: levelsof variablename, local(varnames_short)
local varnames_new
local c: word count `varnames_short'
forvalues i=1/`c' {
	foreach x in am as pm {
		local varnames_new `varnames_new' `x'`: word `i' of `varnames_short''
	}
}
*di "`varnames_new'"
local varnames_drop: list varnames_new-varnames_original
drop if variablename==""
reshape wide screenresultanswertext, i(resultid) j(variablename, string)
compress
bysort resultdevicename dlocal_min trimark: keep if _n==1 // I have to only keep the first of the repeated surveys here (ie, for someone who did am survey twince in a day)
reshape wide resultid screenresultanswertext*, i(resultdevicename dlocal_min) j(trimark, string)
rename screenresultanswertext*am am*
rename screenresultanswertext*as as*
rename screenresultanswertext*pm pm*
drop `varnames_drop'
compress
destring *, replace
save day_wide, replace

* create data for var label
use mobile_long, clear
keep screentext variablename screenresultanswertext openendedtext screentypename
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
save mobile_varlab, replace

* create the do file for var label
use mobile_varlab, clear
capture file close varlab
file open varlab using "mobile_varlab.do", write text replace
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


***** create varname and val label list
* put the variable list in a global for value label creation
use mobile_varlab, clear
drop if openendedtext=="Y" 
drop if inlist(variablename,"amsq01","amsq02")
quietly: levelsof variablename if screentypename=="Text", clean missing
global mobile_drop `r(levels)'
di "$mobile_drop"
drop if screentypename=="Text"
keep variablename
quietly: levelsof variablename, clean missing
global mobile_allvar `r(levels)'
di "$mobile_allvar"
*global mobile_drop: list global(mobile_all) - global(mobile_allvar)
*di "$mobile_drop"

use day_wide, clear
capture file close vallab
file open vallab using "mobile_vallab.txt", write text replace
foreach x of global mobile_allvar {
	loc type: type `x'
	di "`x'"
	if substr("`type'",1,3) == "str" {
		quietly: levelsof `x', local(levels)
		di `levels'
		*quietly: ta `x'
		*di `r(r)'
		local c: word count `levels'
		di `c'
		*if `r(r)'==`c' di "******************"
		forvalues i=1/`c' {
			di `levels'
			local level: word `i' of `levels'
			file write vallab `""`x'", "`level'""' _n
		}
	}
	else global mobile_drop $mobile_drop `x'
}
file close vallab
di "$mobile_drop"

* read the val labels
insheet variablename val_lab using "mobile_vallab.txt", clear case
merge m:1 variablename using WITLvarnamesmobile_varlst, nogen // this adds the variable names not included in the data
foreach x of global mobile_drop {
	drop if variablename=="`x'"
}
sort var_order val_lab
gen numeric=regexs(1) if(regexm(val_lab, "([0-9]*)"))
replace numeric="9999" if val_lab=="SKIP"
replace numeric="0" if val_lab=="No"
replace numeric="1" if val_lab=="Yes"
export excel using "mobile_vallab", firstrow(variables) replace
*****>>>>>manual step to fill in numeric values and add val labels not in the data<<<<<*****
import excel "mobile_vallab_mod.xls", sheet("Sheet1") firstrow allstring clear
gen n=_n
tostring n, replace
*replace numeric=n if numeric==""
sort variablename val_lab
capture file close vallab
file open vallab using "mobile_vallab.do", write text replace
bysort variablename: gen first=1 if _n==1
bysort variablename: gen last=1 if _n==_N
local n2=_N
di `n2'
forvalues x=1/`n2' {
	file write vallab `"capture: replace `=variablename[`x']'="`=numeric[`x']'" if `=variablename[`x']'=="`=val_lab[`x']'""' _n
	if first[`x']==1 {
		file write vallab `"lab def `=variablename[`x']' `=numeric[`x']' "`=val_lab[`x']'""' _n
	}
	else if last[`x']==1 {
		file write vallab `"lab def `=variablename[`x']' `=numeric[`x']' "`=val_lab[`x']'", modify"' _n // add, not modify
	}
	else {
		file write vallab `"lab def `=variablename[`x']' `=numeric[`x']' "`=val_lab[`x']'", modify"' _n
	}
	if last[`x']==1 {
		file write vallab `"capture: destring `=variablename[`x']', replace"' _n
		file write vallab `"capture: lab val `=variablename[`x']' `=variablename[`x']'"' _n
	}
}
file close vallab


use day_wide, clear
quietly: do mobile_varlab.do
do mobile_vallab.do
save day_wide_wlab, replace


















* check the id match
use mobile_long, clear
keep if variablename=="id"
ta variablename if variablename=="id"
tostring resultdevicename, replace
list resultdevicename screenresultanswertext if resultdevicename~=screenresultanswertext & variablename=="id"
gen mismatch=1 if resultdevicename~=screenresultanswertext & variablename=="id"
bysort resultdevicename: egen mismatchi=mean(mismatch)
keep if mismatchi==1
compress
bysort resultdevicename: egen mismatchc=count(mismatch)
bysort resultdevicename: gen nofsurvey=_N
keep resultdevicename screenresultanswertext mismatch mismatchc nofsurvey
gen pctmismatch=mismatchc/nofsurvey
export excel using id_mismatch.xls, firstrow(variables) replace
