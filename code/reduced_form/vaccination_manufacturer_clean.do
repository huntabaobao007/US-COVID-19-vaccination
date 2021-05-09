* run after "state_pop_clean.do"
* change the directory accordingly

clear
set more off
local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\data\" 

*----------
*Moderna
*----------

cd `path'\raw\US_vaccine_allocation_by_types

import delimited "COVID-19_Vaccine_Distribution_Allocations_by_Jurisdiction_-_Moderna", clear

replace jurisdiction = subinstr( jurisdiction, "*", "",.)
 
replace jurisdiction ="Alaska" if jurisdiction=="Alaska,"

ren jurisdiction name


replace name = "Illinois" if name =="Chicago"
replace name = "New York" if name =="New York City"

collapse (sum) stdoseallocations nddoseallocations, by(weekofallocations name)

joinby name using "`path'\raw\US_state_code", unmatched(b)

tab _m

keep if _m==3

drop _m

ren stdoseallocations moderna_1st

ren nddoseallocations moderna_2nd

labe var moderna_1st "Moderna 1st dose"

labe var moderna_2nd "Moderna 2nd dose"

sum

save "`path'\raw\US_vaccine_allocation_by_types\moderna.dta", replace

*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*Pfizer
import delimited "COVID-19_Vaccine_Distribution_Allocations_by_Jurisdiction_-_Pfizer", clear

replace jurisdiction = subinstr( jurisdiction, "*", "",.)
 
replace jurisdiction ="Alaska" if jurisdiction=="Alaska,"

ren jurisdiction name


replace name = "Illinois" if name =="Chicago"
replace name = "New York" if name =="New York City"

collapse (sum) stdoseallocations nddoseallocations, by(weekofallocations name)

joinby name using "`path'\raw\US_state_code", unmatched(b)

tab _m

keep if _m==3

drop _m

ren stdoseallocations pfizer_1st

ren nddoseallocations pfizer_2nd

labe var pfizer_1st "Pfizer 1st dose"
labe var pfizer_2nd "Pfizer 2nd dose"
sum

save "`path'\raw\US_vaccine_allocation_by_types\pfizer.dta", replace

*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*put them together

use "`path'\raw\US_vaccine_allocation_by_types\pfizer.dta", clear

joinby  weekofallocations fips using "`path'\raw\US_vaccine_allocation_by_types\moderna.dta", unmatched(b)

tab _m

drop _m

replace moderna_1st=0 if moderna_1st ==.

replace moderna_2nd=0 if moderna_2nd ==.

gen tot_pfizer= pfizer_1st+ pfizer_2nd

gen tot_moderna= moderna_1st + moderna_2nd

gen tot= tot_pfizer+ tot_moderna

gen pfizer_share= tot_pfizer/ tot

sum pfizer_share

gen moderna_share=tot_moderna/tot

sum moderna_share

label var tot_pfizer "total Pfizer doses"
label var tot_moderna "total Moderna doses"
label var pfizer_share "share of Pfizer"
labe var tot "total allocation"
drop if real(fips)>56

save "`path'\raw\state\state_vaccines_share.dta", replace

egen stateID = group(name)

egen week = group( weekofallocations )

*vaccines allocated up to March 1st
drop if weekofallocations =="03/15/2021" || weekofallocations =="03/08/2021" 

collapse (sum) tot, by(name fips postalcode)
ren fips state
joinby state using "`path'\raw\state\\pop_state_race.dta", unmatched(b)
tab _m
drop _m
egen tot_vac=sum(tot)
egen tot_pop=sum(total )
gen vac_s=tot/tot_vac
gen pop_s=total/tot_pop

twoway (scatter vac_s pop_s, graphregion(color(white)) scheme(plotplain) xtitle(Population Share) ytitle(Share of Vaccines Allocated) msymbol(none) mlabel(postalcode) mlabposition(0))(line pop_s pop_s,legend(nobox region(lstyle(none)) ring(0) position(5) bmargin(large)label(1 "")  label(2 "45 degree line") )) 
