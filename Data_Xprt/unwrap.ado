program unwrap
	capture: replace `1'=subinstr(`1',"---","",1)
	capture: replace `1'=subinstr(`1'," '","",1)
	capture: replace `1'=subinstr(`1',"' ","",1)
	capture: replace `1'=subinstr(`1',"  ... ","",1)
end
