//Covid Economics project

//May 10, 2021
//data clean process

clear
set more off
local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\US-COVID-19-vaccination\data\" 

/*******************************************************************************/
//0 pre-processing for some data

//0.1 state population data

*construct age group for each state

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


*construct racial groups for each state

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

/*******************************************************************************/
//0.2 Vaccine_Distribution_Allocations; Extended Fig 1a


clear
set more off

*Moderna

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

save "`path'\raw\US_vaccine_allocation_by_types\state_vaccines_share.dta", replace

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

*Extended Fig 1a
twoway (scatter vac_s pop_s, graphregion(color(white)) scheme(plotplain) xtitle(Population Share) ytitle(Share of Vaccines Allocated) msymbol(none) mlabel(postalcode) mlabposition(0))(line pop_s pop_s,legend(nobox region(lstyle(none)) ring(0) position(5) bmargin(large)label(1 "")  label(2 "45 degree line") )) 

/*******************************************************************************/
//0.3 Weather data

* the raw weather data can be downloaded from https://www.ncdc.noaa.gov/cdo-web/datasets
* we download the daily Summaries from the FTP for year 2020 (2020.csv) and 2021 (2021.csv)

* the station information is from https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/
* we download ghcnd-stations.txt

* change the directory the the one saving these data before running this part of the code

/*

clear
set more off

local path "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather"

import delimited "`path'\2020.csv\2020", clear
gen country =substr(v1, 1, 2)
keep if country=="US"
ren v1 ID
ren v2 date
ren v3 Element
ren v4 value
ren v5 measurement_flag
ren v6 quality_flag
ren v7 source_flag
ren v8 time

collapse (mean) value, by(ID date Element)

spread Element value

save "`path'\station_data_2020.dta", replace


*2021
import delimited "`path'\2021.csv\2021", cleargen country =substr(v1, 1, 2)
keep if country=="US"
ren v1 ID
ren v2 date
ren v3 Element
ren v4 value
ren v5 measurement_flag
ren v6 quality_flag
ren v7 source_flag
ren v8 time

collapse (mean) value, by(ID date Element)

spread Element value

save "`path'\station_data_2021.dta", replace


clear
import delimited "`path'\ghcnd-stations.txt"

gen country =substr(v1, 1, 2)
keep if country=="US"
drop country
split v1
keep v11 v15 v12 v13 v16
ren v11 ID
ren v15 states
ren v12 latitude
ren v13 longitude
ren v16 city
save "`path'\US_stations.dta", replace


use "`path'\station_data_2020.dta", clear

append using "`path'\station_data_2021.dta"

joinby ID using "`path'\US_stations.dta", unmatched(b)

tab _m

keep if _m==3

collapse (mean) AWDR AWND DAPR DASF EVAP MDPR MDSF MNPN MXPN PGTM PRCP PSUN SN31 SN32 SN33 SN35 SN36 SN51 SN52 SN53 SN55 SN56 SNOW SNWD SX31 SX32 SX33 SX35 SX36 SX51 SX52 SX53 SX55 SX56 TAVG THIC TMAX TMIN TOBS TSUN WDF2 WDF5 WDFG WDMV WESD WESF WSF2 WSF5 WSFG WSFI WT01 WT02 WT03 WT04 WT05 WT06 WT07 WT08 WT09 WT10 WT11, by(states date)

keep PRCP SNOW  SNWD TAVG TMAX TMIN states date


save "`path'\US_states_weather.dta", replace

erase "`path'\station_data_2020.dta"
erase "`path'\station_data_2021.dta"
*/


/*******************************************************************************/
//1 daily data


//1.1 US vaccination data
clear all
set more off

insheet using "`path'\raw\vaccination\us_state_vaccinations_20210308.csv"

tostring date,replace
gen year=substr(date,1,4)
gen month=substr(date,6,2)
gen day=substr(date,9,2)

gen datestring=year+month+day
destring datestring month day,replace
numdate daily date_stata=date,pattern(YMD)

drop year datestring
ren location regionname
duplicates report regionname date_stata    
ren regionname statename

save "`path'\work\vaccination_US.dta",replace


//

//1.2 US policy data
clear all
set more off

insheet using "`path'\raw\policy\OxCGRT_US_2021_03_08.csv"
numdate daily date_stata=date,pattern(YMD)
drop countryname countrycode

gen state_name=substr(regioncode,4,2)
tab state_name

//
keep if regionname!=""
tab regionname
duplicates report state_name date_stata    


ren state_name destination
merge m:1 destination using "`path'\raw\state_list.dta"

drop _merge

ren regionname statename
ren state fipcode
ren destination state

save "`path'\work\US_state_policy.dta",replace



//1.3 US state covid data daily
clear all
set more off

insheet using "`path'\raw\Covid_cases\all-states-history_0307.csv"


gen year=substr(date,1,4)
gen month=substr(date,6,2)
gen day=substr(date,9,2)

gen datestring=year+month+day
destring datestring month day,replace
numdate daily date_stata=date,pattern(YMD)

drop datestring

sort state date
keep date_stata state death hospitalized* positive positiveincrease recovered totaltestsviral totaltestresults

save "`path'\work\US_cases_daily.dta",replace


/*******************************************************************************************/


//2. clean state level controls 

//2.1 time invariant controls
clear all
set more off

insheet using "`path'\raw\state_control.csv"
ren state_name statename
//rule：statename-full name；state-name；fipcode:1-56
replace statename="Washington DC" if statename=="District of Columbia"
merge 1:m statename using "`path'\work\US_state_policy.dta",force
drop _merge

save "`path'\work\US_state_daily.dta",replace



//2.2 rally 
clear all
set more off

insheet using "`path'\raw\political_events\state_rally.csv"

ren v1 date
ren v2 city
ren v3 state

drop if city=="City"

gen year=substr(date,1,4)
gen month=substr(date,6,2)

destring year month,ignore("/") replace

numdate daily date_stata=date,pattern(YMD)

gen week=week(date_stata)
tab week
replace week=53  if week==1  //add 2021's week to 2020's

ren week rally_startweek
drop city date year month date_stata

sort state rally_startweek    //multiple rallys
duplicates drop state rally_startweek,force

gen week=rally_startweek
gen rally_endweek=rally_startweek+1

save "`path'\work\state_rally_week.dta",replace



//2.3 protest 
clear all
set more off

insheet using "`path'\raw\political_events\BLM_elephrame.csv",clear names

egen state=ends(location),punct(", ") last
tab state
egen city=ends(location),punct(",")

gen year=substr(startdate,-4,.)
tab year

egen monthdayyear=ends(startdate),punct("day, ") last

numdate daily date_stata=monthdayyear,pattern(MDY)

destring year,replace

save "`path'\work\state_protest_daily.dta",replace

drop if year<2020
tab year

ren state destination

merge m:1 destination using "`path'\raw\state_list.dta"

sort _merge
ren state fipcode
ren destination state
keep if _merge==3

collapse (count) year,by(state fipcode date_stata)
tab year

ren year protest_number
tab protest_number
sort protest

save "`path'\work\state_protest_daily.dta",replace



//2.4 weather 
clear all
set more off

use "`path'\raw\weather\US_states_weather.dta",clear

tostring date,replace
numdate daily date_stata=date,pattern(YMD)
drop date
ren states state

save "`path'\work\state_weather_daily.dta",replace


//2.5 vaccine type 
clear all
set more off

use "`path'\raw\US_vaccine_allocation_by_types\state_vaccines_share.dta",clear

numdate daily date_stata=week,pattern(MDY)

ren postal state
ren fips fipcode

destring fip,replace
xtset fip date


gen week=week(date_stata) 
tab week
replace week=week+52 if week<=11
tab week


destring fip,replace
sort week

bysort state (week):gen cul_pfizer=sum(tot_pfi) 
sort week
bysort state (week):gen cul_moderna=sum(tot_moderna)

keep state fipcode tot* cul_* week date
bysort state (week):gen cul_tot=sum(tot)
gen pfizer_share=cul_p/cul_t
sum pfi,de


save "`path'\work\state_vaccines_share.dta",replace

