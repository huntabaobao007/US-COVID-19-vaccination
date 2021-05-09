*note: change the directory to the directory "...\data\raw\state_population"
clear
set more off
local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\data\" 

*----------------------------------
*construct age group for each state
*----------------------------------
local list : dir "`path'\raw\state_population" files "*"

loc count1 = 1
foreach file of loc list {
*dis "`count1'"
dis "`file'"
	if substr("`file'",-4,.) == "xlsx" {
		import excel "`path'\raw\state_population/`file'", cellrange(A6:AK92) firstrow clear
		gen age=substr(Total, 2, 3)
		gen age2=real(age)
		replace age2=85 if age2==.
		keep age2 AI
		egen tot_pop=sum(AI)
		gen elder=age>=65
		egen tot_elder=sum(AI*elder )
		gen youth=age<18
		egen tot_youth=sum(AI*youth)
		gen elder_s=tot_elder / tot_pop
		gen youth_s= tot_youth /tot_pop
		keep elder_s youth_s
		collapse (mean)  elder_s youth_s
		label var elder_s "65+"
		gen state = substr("`file'",-7,2)
		loc sc=real(substr("`file'",-7,2))
		save "`path'\raw\state_population\\pop_s`sc'.dta", replace
	}
	loc count1 = `count1' + 1
}

use "`path'\raw\state_population\\pop_s1.dta"
local list : dir "`path'\raw\state_population" files "*"
foreach file of loc list {
dis "`file'"
	if substr("`file'",-3,.) == "dta"{
	append using "`path'\raw\state_population/`file'"
	}
	
}
drop if state==state[_n+1]
save "`path'\raw\state\\pop_state_structure65.dta", replace


*---------------------------------------------------
*construct racial groups for each state
*---------------------------------------------------

local list : dir "`path'\raw\state_race" files "*"
loc count1 = 1
foreach file of loc list {
*dis "`count1'"
dis "`file'"
	if substr("`file'",-4,.) == "xlsx" {
		import excel "`path'\raw\state_race/`file'", cellrange(M4:M33) firstrow clear
		gen state = substr("`file'",-7,2)
		gen n=_n
		egen total=max(M)
		gen white_s= M/total if n==3
		gen black_s=M/total if n==4
		collapse (min) white_s black_s (mean) total , by(state)
		
		loc sc=real(substr("`file'",-7,2))
		save "`path'\raw\state_race\\pop_r`sc'.dta", replace
	}
	loc count1 = `count1' + 1
}

use "`path'\raw\state_race\\pop_r1.dta"
local list : dir "`path'\raw\state_race" files "*"
foreach file of loc list {
dis "`file'"
	if substr("`file'",-3,.) == "dta"{
	append using "`path'\raw\state_race/`file'"
	}
	
}
so state
drop if state==state[_n+1]
save "`path'\raw\state\\pop_state_race.dta", replace

