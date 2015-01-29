set more off
set matsize 11000
cd "D:\Dropbox\Projects\WITL\results"

local rlst : dir .  files  "*.csv"
di `"`rlst'"'
local n_files : word count `rlst'
local newfile `: word `n_files' of `rlst''
di `"`newfile'"'
insheet using "`newfile'", names c clear
*save tempfile, replace
local 1 summary
*use tempfile, clear
rename (resultdevicename resultid screenresultanswerdate screentext screenresultanswertext) ///
	(pid svyid qtime q answer)
keep pid svyid qtime q answer
sort svyid qtime
by svyid: gen svytime=qtime[1]
by svyid: gen svyetime=qtime[_N]
gen skip=1 if answer=="SKIP"
by svyid: gen qn=_n
by svyid: gen nqsvy=_N
by svyid: egen nssvy=count(skip)
gen skiprate=nssvy/(nqsvy-1) if qn==1
sort pid svytime
by pid: egen pidskiprate=mean(skiprate)

keep if strmatch(q, "*What time of day is it*")==1
gen double tsvy=clock(svytime, "YMDhms")
gen dsvy=dofc(tsvy)
gen dowsvy=dow(dsvy)
gen hmssvy=hh(tsvy)+mm(tsvy)/60+ss(tsvy)/3600
format tsvy %tc
format dsvy %td
format hmssvy %3.1f
by pid: gen daysinsvy=dsvy[_N]-dsvy[1]+1

gen trimark=cond(answer=="Morning","AM",cond(answer=="Afternoon","AS",cond(answer=="Evening","PM","")))
sort pid dsvy trimark qtime
by pid: gen pidn=_n
foreach x in AM AS PM {
	by pid dsvy trimark: gen `x'mark=_n if trimark=="`x'"
	by pid: egen `x'count=count(`x'mark)
	by pid: egen `x'countdupi=count(`x'mark) if `x'mark>1 & `x'mark~=.
	by pid: egen `x'countdup=count(`x'countdupi)
	tostring `x'count `x'countdup, replace
	replace `x'count=`x'count + "-" + `x'countdup if `x'countdup~="0"
	by pid dsvy: egen `x'countdaily=count(`x'mark)
}
by pid: gen tricount=_N

destring AMcountdup AScountdup PMcountdup, replace
gen tricountdup=AMcountdup+AScountdup+PMcountdup
tostring tricount tricountdup, replace
replace tricount=tricount + "-" + tricountdup if tricountdup~="0"

by pid dsvy: egen nsperday=count(qn)
by pid dsvy: keep if _n==1
gen cmpltday=1 if AMcountdaily~=0 & AScountdaily~=0 & PMcountdaily~=0
by pid: replace cmpltday=1 if _n==1
by pid: egen cmpltdaycount=count(cmpltday)

keep if pidn==1
lab var pid
global vlst pid pidskiprate AMcount AScount PMcount tricount daysinsvy cmpltdaycount dsvy dowsvy
global nvlst PersonID SkipRate AMcount AScount PMcount Totalcount DaysInSvy CmpltDayCount StartDate DayOfWeek
keep $vlst
order $vlst
rename ($vlst) ($nvlst)

capture htclose
htopen using `1', replace
htput <link rel=stylesheet href="R2HTMLa.css" type=text/css>
htput <b>Time HTML Created:</b> $S_DATE $S_TIME
htlist *
htput <b>Note:</b> Values such as 5-2 means 2 of 5 surveys are unnecessary extra surveys. <br>
lab var PersonID "Person Identifier"
lab var SkipRate "Percent of Skipped Questions in All Surveys"
lab var AMcount "Number of Morning Surveys Completed"
lab var AScount "Number of Afternoon Surveys Completed"
lab var PMcount "Number of Evening Surveys Completed"
lab var Totalcount "Total Number of Surveys Completed"
lab var DaysInSvy "Number of Days in Survey Between First and Last Day with Survey"
lab var CmpltDayCount "Number of Days with All Three Surveys Completed - First Day Default Complete"
lab var StartDate "Date of First Recorded Survey"
lab var DayOfWeek "Day of Week for the First Recorded Survey"
htput <br>
htput <table cellspacing=0 border=1><td><table border="0" cellpadding="4" cellspacing="2">
htput <tr class=firstline><td>Variable Names</td><td>Varible Labels</td></tr>
foreach y of global nvlst {
	htput <tr><td>`y'</td><td> `: di " `: var label `y' ' " ' </td></tr>
}
htput </table></td></table><br>
htclose
! "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" summary.html
