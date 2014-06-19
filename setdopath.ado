program setdopath
	local file_list : dir `"`1'"' files  "lab_*.do", respectcase
	local do_count: word count `file_list'
	if `do_count'>0 {
		global dopath `"`1'"'
		di "dopath is set to " "$dopath"
	}
	else {
		di as err "The path you provided does NOT contain do files that look like lab_xxxxxxxxxxxxxxxxxx.do!"
		exit
	}
end
