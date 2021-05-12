//May 10, 2021
//Main figures

/*******************************************************************************/
*note: change the directory to the directory "...\data\raw\state_population"
//note: color scheme of figures displayed in the paper is adjusted using the figure editor

clear all
set more off

//local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\data\" 
//cd "`path'work"

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\work"
use US_state_daily.dta,clear

replace statename="District of Columbia" if statename=="Washington DC"
replace statename="New York State" if statename=="New York"

merge 1:1 statename date_stata using vaccination_US.dta,force
sort _merge
drop if _merge==2
drop _merge


merge 1:1 state date_stata using US_cases_daily.dta
keep if _merge==3
drop _merge


//weather, protest, vaccaine share
merge 1:1 state date_stata using state_protest_daily.dta
drop if _merge==2
drop _merge
replace protest=0 if protest==.


merge 1:1 state date_stata using state_weather_daily.dta
drop if _merge==2
drop _merge


//
gen year=year(date_stata) 
tab year
replace month=month(date_stata) 
tab month
replace day=day(date_stata) 
tab day


egen data_num=group(date_stata)
tab data_num

tab data_num if year==2020 & month==10 & day==12  //data_num=274
replace data_num=data_num-1

gen week=int(data_num/7)
tab week

tab week if year==2020 & month==10 & day==12   //39; 39+3=42
replace week=week+3
tab week if year==2020 & month==10 & day==12 


sum people_vaccinated_per_hundred if week==62
drop if year==2020 & week<=10

//

ren stringencyindexfor stringency   //lockdown style policy
ren biden Xi_bidenwin
ren trump Xi_trumpwin
ren householdincome Xi_income
ren hospitalbed Xi_hospitalbed

gen Xi_govrepublic=1 if governorp=="Republican"
replace Xi_govrepublic=0 if Xi_govrepublic==.
tab Xi_govrepublic


collapse (max) month day date_stata ///
(mean) hospitalizedcurrently stringency popu Xi_biden Xi_trump Xi_income Xi_hospital Xi_gov ///
(max) death positive hospitalizedcumulative totaltestresults recovered people_vaccinated_per_hundred people_fully_vaccinated_per_hund SNOW TAVG ///
(sum) positiveincrease hospitalizedincrease protest,by(fipcode state week)


xtset fip week

bys state:sum people_vac

local w_var people_v people_f positive positiveincrease hospitalizedcumulative hospitalizedincrease death
foreach i in `w_var'{
replace `i'=0 if `i'==.
sum `i'
}



//merge state-weekly rally and vaccine
merge 1:1 state week using state_rally_week.dta

gen rally=1 if _merge==3
tab rally
bys state:egen rally_state=max(rally)
tab rally_state

sort _merge state rally_start
replace rally_end=rally_start+1      //rally last for two weeks

xtset fip week
gen lagweek=l1.week
replace rally=1 if lagweek==rally_endweek
tab rally
drop rally_* _merge
drop lagweek
replace rally=0 if rally==.
tab rally


merge 1:1 state week using state_vaccines_share.dta
drop if _merge==2
drop _merge

tab Xi_biden
gen lsnow=log(SNOW+1)
ren TAVG meantemp

//temp:deviation from the mean
tab state if meantemp==.

gen DCdummy=1 if state=="VA"  | state=="MD"
bys week:egen DCtemp=mean(meantemp) if DCdummy==1
bys week:egen DCtemp_max=max(DCtemp)
replace meantemp=DCtemp_max if state=="DC"
drop DC*

gen DEdummy=1 if state=="NJ"  | state=="MD"
bys week:egen DEtemp=mean(meantemp) if DEdummy==1
bys week:egen DEtemp_max=max(DEtemp)
replace meantemp=DEtemp_max if state=="DE" & meantemp==.
drop DE*


bys state:egen statetemp=mean(meantemp)
bys state:egen statede=sd(meantemp)

gen dev_temp=(meantemp-statetemp)/statede
sum dev_temp,de




//generate y variables

xtset fip week

gen lagI=l1.positive
gen infect_growth=(positive-lagI)/lagI
sum infect_growth,de
replace infect_g=0 if infect_g==.

gen InfectRate=(positive/popu)*100             //% points
gen lagInfectRate=(lagI/popu)*100

gen Iin=positiveincrease
gen logIin=log(positiveincrease+1)



//

gen lagH=l1.hospitalizedcumulative
gen hosp_growth=(hospitalizedcumulative-lagH)/lagH
sum hosp_growth,de
replace hosp_g=0 if hosp_g==.

gen HospRate=(hospitalizedcumulative/popu)*100    //% points
gen lagHospRate=(lagH/popu)*100

gen Hin=hospitalizedincrease
gen logHin=log(hospitalizedincrease+1)


//
ren Xi_bidenwin Xi_biden
drop Xi_trump
tab Xi_biden

xtset fip week

gen lstring=l1.string
gen lpeople_vac=l1.people_vac
gen lpeople_ful=l1.people_ful
replace lpeople_vac=0 if lpeople_vac==.
replace lpeople_ful=0 if lpeople_ful==.


gen TestRate=(totaltest/popu)*100
gen lagTest=l1.totaltest
gen lagTestRate=(lagTest/popu)*100

gen SuspRate=(popu-positive)/popu*100
gen lagSuspRate=(popu-lagI)/popu*100

//
xtset fip week
tabstat *_growth *in lstring lpeople_vac lpeople_ful lagInfectRate lagSuspRate lagTestRate,stat(n mean sd min p50 max) long col(stat)

list state week if lstring==.
sort state week
//3 points of obs missing stringency 
replace lstring=21.3 if state=="AL" & (week==61 | week==62)
replace lstring=50.93 if state=="RI" & (week==62)
list state week if string==.
replace string=21.3 if state=="AL" & (week==61)
replace string=50.93 if state=="RI" & (week==61)

replace hosp_growth=0.02 if hosp_growth<0   //AZ week==42 data error

ren fip panelid
sort week month day


// 21 weeks sample
keep if week>41
tab week


gen dummy_hosp=1 if hospitalizedcumulativ!=0 
replace dummy_hosp=0 if (state=="CT" | state=="NY")
replace dummy_hosp=0 if dummy_hosp==.
tab dummy_hosp

/*********************************************************************************************************************************/
//Extended Data Table 1

tabstat infect_growth Iin string people_vac people_ful SuspRate TestRate,stat(n mean sd min p50 max) long col(stat)
tabstat hosp_growth Hin if dummy_hosp==1,stat(n mean sd min p50 max) long col(stat)
tabstat rally protest SNOW dev_temp,stat(n mean sd min p50 max) long col(stat)


/*********************************************************************************************************************************/
//Extended Data Table 2

//growth rate
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t11
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t12

vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t13
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t14


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\output\US\April18"
outreg2 [t11 t12 t13 t14] using table1-1.doc,ctitle("") keep(lpeople_vac lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp) ///
stats(coef tstat se) addtext(Week FE,Yes,State FE,Yes) replace dec(3)



/*********************************************************************************************************************************/
//Figure 3a


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures"
coefplot (t11,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t12, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), legend(position(11)) ///
keep(lpeople_vac lpeople_ful) ytitle("Growth Rate of Cases",size(small)) xlabel(-0.02(0.005)0) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)
graph save figure3a1,replace


coefplot (t13,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t14, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), ///
keep(lpeople_vac lpeople_ful) ytitle("Growth Rate of Hospitalizations",size(small)) xlabel(-0.02(0.005)0) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) legend(off) fysize(80)
graph save figure3a2,replace



gr combine figure3a1.gph figure3a2.gph,col(1) iscale(1) scheme(plotplain) title("a",position(11))

graph save figure3a,replace

graph export figure3a.png,replace



/*********************************************************************************************************************************/

//Supplement Figure 4

//Supplement Figure 4a
//newly cases
vce2way reg logI lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t21
vce2way reg logI lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t22


vce2way reg logH lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t23
vce2way reg logH lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t24


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\output\US\April18"
outreg2 [t21 t22 t23 t24] using table1-2.doc,ctitle("") keep(lpeople_vac lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp) ///
stats(coef tstat se) addtext(Week FE,Yes,State FE,Yes) replace dec(3)



cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
coefplot (t21,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t22, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), legend(position(11)) ///
keep(lpeople_vac lpeople_ful) ytitle("Log (New Cases) ") xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure4a1,replace



coefplot (t23,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t24, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), legend(off) ///
keep(lpeople_vac lpeople_ful) ytitle("Log (New Hospitalizations)") xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(80)

graph save sfigure4a2,replace


gr combine sfigure4a1.gph sfigure4a2.gph,col(1) iscale(1) xcommon scheme(plotplain) title("a",position(11))
graph save sfigure4a,replace
graph export sfigure4a.png,replace




//Supplement Figure 4b
//changes in logarithms of cases / hospitalizations


gen infect_diff=log(positive)-log(lagI)
gen hosp_diff=log(hospitalizedcumulativ)-log(lagH)
replace hosp_diff=0 if hosp_diff==.


//growth rate
vce2way reg infect_diff lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t41
vce2way reg infect_diff lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t42

vce2way reg hosp_diff lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t43
vce2way reg hosp_diff lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t44


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\output\US\April18"
outreg2 [t41 t42 t43 t44] using table1-4.doc,ctitle("") keep(lpeople_vac lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp) ///
stats(coef tstat se) addtext(Week FE,Yes,State FE,Yes) replace dec(3)




cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
coefplot (t41,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t42, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), legend(position(11)) ///
keep(lpeople_vac lpeople_ful) ytitle("Δ Log (Total Cases)",size(small)) xlabel(-0.02(0.005)0) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure4b1,replace



coefplot (t43,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t44, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), legend(off) ///
keep(lpeople_vac lpeople_ful) ytitle("Δ Log (Total Hospitalizations)",size(small)) xline(0) xlabel(-0.02(0.005)0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(80)

graph save sfigure4b2,replace


gr combine sfigure4b1.gph sfigure4b2.gph,col(1) iscale(1) xcommon scheme(plotplain) title("b",position(11))
graph save sfigure4b,replace
graph export sfigure4b.png,replace


/*********************************************************************************************************************************/




/*********************************************************************************************************************************/

//Figure 3b

//effect of vaccination
tab state if week>=55

xtset panelid week
gen l2people_vac=l2.people_vac

gen delta_vac=lpeople_vac-l2people_vac
bys week:sum delta_vac 

gen infect_g_bar=infect_growth+0.0068535*delta_vac if week==56
gen positive_bar=positive*(1+infect_g_bar)
gen positive_c=positive_bar

bys state:egen positive_bar_max=max(positive_bar) if week>=56
bys state:egen infect_g_bar_max=max(infect_g_bar) if week>=56

gen hosp_g_bar=hosp_g+0.007117 *delta_vac if week==56 & dummy_hosp==1
gen hosp_bar=hospitalizedcumulative*(1+hosp_g_bar)
gen hosp_c=hosp_bar

bys state:egen hosp_bar_max=max(hosp_bar) if week>=56 & dummy_hosp==1
bys state:egen hosp_g_bar_max=max(hosp_g_bar) if week>=56 & dummy_hosp==1


sort week state


forvalues i=57/62 {

replace infect_g_bar=infect_g_bar_max+0.0068535*delta_vac if week==`i'
replace positive_bar=positive*(1+infect_g_bar) if week==`i'

replace hosp_g_bar=hosp_g_bar_max+0.007117 *delta_vac if week==`i' & dummy_hosp==1
replace hosp_bar=hospitalizedcumulative*(1+hosp_g_bar) if week==`i' & dummy_hosp==1

replace positive_c=positive_bar if positive_c==.
replace hosp_c=hosp_bar if hosp_c==.


drop *_max

bys state:egen positive_bar_max=max(positive_bar) if week>=56
bys state:egen infect_g_bar_max=max(infect_g_bar) if week>=56
bys state:egen hosp_bar_max=max(hosp_bar) if week>=56 & dummy_hosp==1
bys state:egen hosp_g_bar_max=max(hosp_g_bar) if week>=56 & dummy_hosp==1


}

sort panelid week

bys week:sum positive_c
bys week:sum hosp_c


bys week:egen positive_total=sum(positive) if week>=55
bys week:egen positive_c_total=sum(positive_c) if week>=56

 
bys week:egen hosp_total=sum(hospitalizedcumulative) if week>=55 & dummy_hosp==1
bys week:egen hosp_c_total=sum(hosp_c) if week>=56 & dummy_hosp==1

replace positive_c_t=positive_t if week==55
replace hosp_c_t=hosp_t if week==55


sort week
replace positive_t=positive_t/1000000
replace positive_c_t=positive_c_t/1000000

drop if week <55
twoway line positive_t week || line positive_c_t week, xlabel(55(1)62) ///
xtitle("") ytitle("Total Cases (Unit: Million)",size(v.small)) scheme(plotplain) ///
legend(label(1 "With Vaccine") label(2 "Without Vaccine")) legend(position(11)) fysize(100)


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures"

graph save figure3b1,replace



drop if week <55

replace hosp_t=hosp_t/1000000
replace hosp_c_t=hosp_c_t/1000000

twoway line hosp_t week || line hosp_c_t week, xlabel(55(1)62) ///
xtitle("") ytitle("Total Hospitalizations (Unit: Million)",size(v.small)) scheme(plotplain) legend(off) fysize(80)
tab date_stata

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures"
graph save figure3b2,replace


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures"

gr combine figure3b1.gph figure3b2.gph,col(1) iscale(1) scheme(plotplain) title("b",position(11))
graph save figure3b,replace
graph export figure3b.png,replace





/*********************************************************************************************************************************/
//Figure 2: scatter plots


scatter infect_growth people_vac || lfit infect_growth people_vac, ///
xtitle("Vaccination rate (at least 1 dose)") ytitle("Growth rate of cases") title("a",position(11)) scheme(plotplain) legend(off)

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures"

graph export figure2a,replace


scatter infect_growth people_ful || lfit infect_growth people_ful, ///
xtitle("Vaccination rate (2 doses)") ytitle("Growth rate of cases") title("b",position(11)) scheme(plotplain) legend(off)

graph export figure2b,replace



//
drop if dummy_hosp==0

scatter hosp_growth people_vac || lfit hosp_growth people_vac, ///
xtitle("Vaccination rate (at least 1 dose)") ytitle("Growth rate of hospitalizations") title("c",position(11)) scheme(plotplain) legend(off)
graph export figure2c,replace


scatter hosp_growth people_ful || lfit hosp_growth people_ful, ///
xtitle("Vaccination rate (2 doses)") ytitle("Growth rate of hospitalizations") title("d",position(11)) scheme(plotplain) legend(off)

graph export figure2d,replace


//

gr combine figure2a.gph figure2b.gph figure2c.gph figure2d.gph,col(2) iscale(0.8) scheme(plotplain)

graph export figure2.png,replace

/*********************************************************************************************************************************/





/*********************************************************************************************************************************/
//supplement Figure 2


bys week:sum people_vacc
bys state:egen pre_infect_rate=mean(InfectRate) if week<=54
gen hosp_rate=hospitalizedcumulative/popu if dummy_hosp==1
bys state:egen pre_hosp_rate=mean(hosp_rate) if week<=54
bys state:egen vacc_rate=mean(people_vac) if week>=55
bys state:egen vacc_ful=mean(people_ful) if week>=55

collapse (max) pre_infect_rate pre_hosp_rate vacc_rate vacc_ful,by(state)


scatter pre_infect vacc_rate || lfit pre_infect vacc_rate, title("a",position(11)) ///
xtitle("Vaccination Rate (At Least 1 Dose)") ytitle("Infection Rate") lcolor(blue) scheme(plotplain) legend(off)

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
graph save sfigure2a,replace


scatter pre_infect vacc_ful || lfit pre_infect vacc_ful, title("b",position(11)) ///
xtitle("Vaccination Rate (2 Doses)") ytitle("Infection Rate") lcolor(blue) scheme(plotplain) legend(off)

graph save sfigure2b,replace


//
scatter pre_hosp vacc_rate || lfit pre_hosp vacc_rate, title("c",position(11)) ///
xtitle("Vaccination Rate (At Least 1 Dose)") ytitle("Hospitalization Rate") lcolor(blue) scheme(plotplain) legend(off)

graph save sfigure2c,replace


scatter pre_hosp vacc_ful || lfit pre_hosp vacc_ful, title("d",position(11)) ///
xtitle("Vaccination Rate (2 Doses)") ytitle("Hospitalization Rate") lcolor(blue) scheme(plotplain) legend(off)

graph save sfigure2d,replace


gr combine sfigure2a.gph sfigure2b.gph sfigure2c.gph sfigure2d.gph,col(2) iscale(0.8) scheme(plotplain)

graph save sfigure2,replace
graph export sfigure2.png,replace

/*********************************************************************************************************************************/







/*********************************************************************************************************************************/
//supplement Table 3. daily frequency 

clear all
set more off


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\work"
use US_state_daily.dta,clear

replace statename="District of Columbia" if statename=="Washington DC"
replace statename="New York State" if statename=="New York"

merge 1:1 statename date_stata using vaccination_US.dta,force
sort _merge
drop if _merge==2
drop _merge


merge 1:1 state date_stata using US_cases_daily.dta
keep if _merge==3
drop _merge



//weather, protest, vaccaine share
merge 1:1 state date_stata using state_protest_daily.dta
drop _merge
replace protest=0 if protest==.


merge 1:1 state date_stata using state_weather_daily.dta
drop if _merge==2
drop _merge


//
gen year=year(date_stata) 
tab year
replace month=month(date_stata) 
tab month
replace day=day(date_stata) 
tab day


egen data_num=group(date_stata)
tab data_num

tab data_num if year==2020 & month==10 & day==12  //data_num=274
replace data_num=data_num-1

gen week=int(data_num/7)
tab week

tab week if year==2020 & month==10 & day==12   //39; keep consistent 之前是从42开始
replace week=week+3
tab week if year==2020 & month==10 & day==12 

drop if year==2020 & week<=10


//

ren stringencyindexfor stringency   //lockdown style policy
ren biden Xi_bidenwin
ren trump Xi_trumpwin
ren householdincome Xi_income
ren hospitalbed Xi_hospitalbed

gen Xi_govrepublic=1 if governorp=="Republican"
replace Xi_govrepublic=0 if Xi_govrepublic==.
tab Xi_govrepublic


//
keep month day date_stata ///
hospitalizedcurrently stringency popu Xi_biden Xi_trump Xi_income Xi_hospital Xi_gov ///
death positive hospitalizedcumulative totaltestresults recovered people_vaccinated_per_hundred people_fully_vaccinated_per_hund SNOW TAVG ///
positiveincrease hospitalizedincrease protest fipcode state week


local w_var people_v people_f positive positiveincrease hospitalizedcumulative hospitalizedincrease death
foreach i in `w_var'{
replace `i'=0 if `i'==.
sum `i'
}


//merge state-weekly rally and vaccine
merge m:1 state week using state_rally_week.dta
gen rally=1 if _merge==3
tab rally
bys state:egen rally_state=max(rally)
tab rally_state

sort _merge state rally_start
replace rally_end=rally_start+1

gen lagweek=week+1
replace rally=1 if lagweek==rally_endweek
tab rally
drop rally_* _merge
drop lagweek
replace rally=0 if rally==.
tab rally


merge m:1 state week using state_vaccines_share.dta
drop if _merge==2
drop _merge

tab Xi_biden
gen lsnow=log(SNOW+1)
ren TAVG meantemp

//temp:deviation from the mean
tab state if meantemp==.

gen DCdummy=1 if state=="VA"  | state=="MD"
bys date_stata:egen DCtemp=mean(meantemp) if DCdummy==1
bys date_stata:egen DCtemp_max=max(DCtemp)
replace meantemp=DCtemp_max if state=="DC"
drop DC*

gen DEdummy=1 if state=="NJ"  | state=="MD"
bys date_stata:egen DEtemp=mean(meantemp) if DEdummy==1
bys date_stata:egen DEtemp_max=max(DEtemp)
replace meantemp=DEtemp_max if state=="DE" & meantemp==.
drop DE*


bys state:egen statetemp=mean(meantemp)
bys state:egen statede=sd(meantemp)

gen dev_temp=(meantemp-statetemp)/statede
sum dev_temp,de




//

xtset fip date_stata

gen lagI=l1.positive
gen infect_growth=(positive-lagI)/lagI
sum infect_growth,de
replace infect_g=0 if infect_g==.

gen InfectRate=(positive/popu)*100            
gen lagInfectRate=(lagI/popu)*100

gen Iin=positiveincrease
gen logIin=log(positiveincrease+1)



gen lagH=l1.hospitalizedcumulative
gen hosp_growth=(hospitalizedcumulative-lagH)/lagH
sum hosp_growth,de
replace hosp_g=0 if hosp_g==.

gen HospRate=(hospitalizedcumulative/popu)*100    
gen lagHospRate=(lagH/popu)*100

gen Hin=hospitalizedincrease
gen logHin=log(hospitalizedincrease+1)


//
ren Xi_bidenwin Xi_biden
drop Xi_trump
tab Xi_biden

xtset fip date_stata

gen lstring=l1.string
gen lpeople_vac=l1.people_vac
gen lpeople_ful=l1.people_ful
replace lpeople_vac=0 if lpeople_vac==.
replace lpeople_ful=0 if lpeople_ful==.


gen lagTest=l1.totaltest
gen lagTestRate=(lagTest/popu)*100
gen lagSuspRate=(popu-lagI)/popu*100


//

tabstat *_growth *in lstring lpeople_vac lpeople_ful lagInfectRate lagSuspRate lagTestRate,stat(n mean sd min p50 max) long col(stat)

list state week if lstring==.
sort state week
replace lstring=21.3 if state=="AL" & (week==61 | week==62)
replace lstring=50.93 if state=="RI" & (week==62)
list state week if string==.
replace string=21.3 if state=="AL" & (week==61)
replace string=50.93 if state=="RI" & (week==61)

ren fip panelid


// 21 weeks sample
keep if week>41
tab week

sort infect_g
replace infect_growth=0 if infect_growth<0 
replace hosp_g=0 if hosp_g<0
 

gen dummy_hosp=1 if hospitalizedcumulativ!=0 
replace dummy_hosp=0 if (state=="CT" | state=="NY")
replace dummy_hosp=0 if dummy_hosp==.
tab dummy_hosp

tabstat hosp_g if dummy_hosp==1,stat(n mean sd min p50 max) long col(stat)
replace hosp_g=0 if hosp_g<0


set matsize 11000


//growth rate
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.date,cluster(panelid date)
est store t11
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.date,cluster(panelid date)
est store t12

vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.date if dummy_hosp==1,cluster(panelid date)
est store t13
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.date if dummy_hosp==1.,cluster(panelid date)
est store t14


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\output\US\April18"
outreg2 [t11 t12 t13 t14] using STable3.doc,ctitle("") keep(lpeople_vac lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp) stats(coef tstat se) ///
addtext(Daily FE,Yes,State FE,Yes) replace dec(4)




/*********************************************************************************************************************************/


/*********************************************************************************************************************************/

// supplement Figure 5

clear all
set more off

//local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\data\" 
//cd "`path'work"

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\work"
use US_state_daily.dta,clear

replace statename="District of Columbia" if statename=="Washington DC"
replace statename="New York State" if statename=="New York"

merge 1:1 statename date_stata using vaccination_US.dta,force
sort _merge
drop if _merge==2
drop _merge


merge 1:1 state date_stata using US_cases_daily.dta
keep if _merge==3
drop _merge


//weather, protest, vaccaine share
merge 1:1 state date_stata using state_protest_daily.dta
drop if _merge==2
drop _merge
replace protest=0 if protest==.


merge 1:1 state date_stata using state_weather_daily.dta
drop if _merge==2
drop _merge


//
gen year=year(date_stata) 
tab year
replace month=month(date_stata) 
tab month
replace day=day(date_stata) 
tab day


egen data_num=group(date_stata)
tab data_num

tab data_num if year==2020 & month==10 & day==12  //data_num=274
replace data_num=data_num-1

gen week=int(data_num/7)
tab week

tab week if year==2020 & month==10 & day==12   //39; 39+3=42
replace week=week+3
tab week if year==2020 & month==10 & day==12 


sum people_vaccinated_per_hundred if week==62
drop if year==2020 & week<=10

//

ren stringencyindexfor stringency   //lockdown style policy
ren biden Xi_bidenwin
ren trump Xi_trumpwin
ren householdincome Xi_income
ren hospitalbed Xi_hospitalbed

gen Xi_govrepublic=1 if governorp=="Republican"
replace Xi_govrepublic=0 if Xi_govrepublic==.
tab Xi_govrepublic



//OLS ipolate
drop people_vaccinated people_fully_vaccinated
bys week:sum people_vac
replace people_vac=. if people_vac==0

xtset fip date_stata
bys fip:mipolate people_vacc date_stata,gen(temp_people_vac) epolate 
bys date_stata:sum temp_people_vac
//date_num==343: 21 Dec, 2020 
replace people_vacc=temp_people_vac if temp_people_vac>0 & data_num>=343
bys date_stata:sum people_vacc


xtset fip date_stata
replace people_ful=. if people_ful==0

bys fip:mipolate people_ful date_stata,gen(temp_people_ful) epolate 
bys date_stata:sum temp_people_ful
replace people_ful=temp_people_ful if temp_people_ful>0 & data_num>=343
bys date_stata:sum people_ful
replace people_vac=0 if people_vac==.
replace people_ful=0 if people_ful==.



collapse (max) month day date_stata ///
(mean) hospitalizedcurrently stringency popu Xi_biden Xi_trump Xi_income Xi_hospital Xi_gov ///
(max) death positive hospitalizedcumulative totaltestresults recovered people_vaccinated_per_hundred people_fully_vaccinated_per_hund SNOW TAVG ///
(sum) positiveincrease hospitalizedincrease protest,by(fipcode state week)


xtset fip week

bys state:sum people_vac

local w_var people_v people_f positive positiveincrease hospitalizedcumulative hospitalizedincrease death
foreach i in `w_var'{
replace `i'=0 if `i'==.
sum `i'
}



//merge state-weekly rally and vaccine
merge 1:1 state week using state_rally_week.dta

gen rally=1 if _merge==3
tab rally
bys state:egen rally_state=max(rally)
tab rally_state

sort _merge state rally_start
replace rally_end=rally_start+1      //rally last for two weeks

xtset fip week
gen lagweek=l1.week
replace rally=1 if lagweek==rally_endweek
tab rally
drop rally_* _merge
drop lagweek
replace rally=0 if rally==.
tab rally


merge 1:1 state week using state_vaccines_share.dta
drop if _merge==2
drop _merge

tab Xi_biden
gen lsnow=log(SNOW+1)
ren TAVG meantemp

//temp:deviation from the mean
tab state if meantemp==.

gen DCdummy=1 if state=="VA"  | state=="MD"
bys week:egen DCtemp=mean(meantemp) if DCdummy==1
bys week:egen DCtemp_max=max(DCtemp)
replace meantemp=DCtemp_max if state=="DC"
drop DC*

gen DEdummy=1 if state=="NJ"  | state=="MD"
bys week:egen DEtemp=mean(meantemp) if DEdummy==1
bys week:egen DEtemp_max=max(DEtemp)
replace meantemp=DEtemp_max if state=="DE" & meantemp==.
drop DE*


bys state:egen statetemp=mean(meantemp)
bys state:egen statede=sd(meantemp)

gen dev_temp=(meantemp-statetemp)/statede
sum dev_temp,de


//generate y variables

xtset fip week

gen lagI=l1.positive
gen infect_growth=(positive-lagI)/lagI
sum infect_growth,de
replace infect_g=0 if infect_g==.

gen InfectRate=(positive/popu)*100             //% points
gen lagInfectRate=(lagI/popu)*100

gen Iin=positiveincrease
gen logIin=log(positiveincrease+1)



//

gen lagH=l1.hospitalizedcumulative
gen hosp_growth=(hospitalizedcumulative-lagH)/lagH
sum hosp_growth,de
replace hosp_g=0 if hosp_g==.

gen HospRate=(hospitalizedcumulative/popu)*100    //% points
gen lagHospRate=(lagH/popu)*100

gen Hin=hospitalizedincrease
gen logHin=log(hospitalizedincrease+1)


//
ren Xi_bidenwin Xi_biden
drop Xi_trump
tab Xi_biden

xtset fip week

gen lstring=l1.string
gen lpeople_vac=l1.people_vac
gen lpeople_ful=l1.people_ful
replace lpeople_vac=0 if lpeople_vac==.
replace lpeople_ful=0 if lpeople_ful==.


gen TestRate=(totaltest/popu)*100
gen lagTest=l1.totaltest
gen lagTestRate=(lagTest/popu)*100

gen SuspRate=(popu-positive)/popu*100
gen lagSuspRate=(popu-lagI)/popu*100

//
xtset fip week
tabstat *_growth *in lstring lpeople_vac lpeople_ful lagInfectRate lagSuspRate lagTestRate,stat(n mean sd min p50 max) long col(stat)

list state week if lstring==.
sort state week
//3 points of obs missing stringency 
replace lstring=21.3 if state=="AL" & (week==61 | week==62)
replace lstring=50.93 if state=="RI" & (week==62)
list state week if string==.
replace string=21.3 if state=="AL" & (week==61)
replace string=50.93 if state=="RI" & (week==61)

replace hosp_growth=0.02 if hosp_growth<0   //AZ week==42 data error

ren fip panelid
sort week month day


// 21 weeks sample
keep if week>41
tab week


gen dummy_hosp=1 if hospitalizedcumulativ!=0 
replace dummy_hosp=0 if (state=="CT" | state=="NY")
replace dummy_hosp=0 if dummy_hosp==.
tab dummy_hosp


//growth rate
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t11
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week,cluster(panelid week)
est store t12

vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1,cluster(panelid week)
est store t13
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if dummy_hosp==1.,cluster(panelid week)
est store t14


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\output\US\April18"
outreg2 [t11 t12 t13 t14] using Sfigure5.doc,ctitle("") keep(lpeople_vac lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp) stats(coef tstat se) ///
addtext(Week FE,Yes,State FE,Yes) replace dec(4)



cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
coefplot (t11,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t12, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), legend(position(11)) ///
keep(lpeople_vac lpeople_ful) ytitle("Growth Rate of Cases",size(small)) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)
//vertical legend(off)
graph save sfigure5a,replace


//scheme(plotplain)

coefplot (t13,color(blue) symbol(circle) msize(large) label(Vaccination Rate, At Least 1 Dose)) ///
(t14, color(red) symbol(square) msize(large) label(Vaccination Rate, 2 Doses)), ///
keep(lpeople_vac lpeople_ful) ytitle("Growth Rate of Hospitalizations",size(small)) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) legend(off) fysize(80)
graph save sfigure5b,replace


gr combine sfigure5a.gph sfigure5b.gph,col(1) iscale(1) xcommon scheme(plotplain)

graph save sfigure5,replace

graph export sfigure5.png,replace

/*********************************************************************************************************************************/


/*********************************************************************************************************************************/

// supplement Figure 3

clear all
set more off

//local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\data\" 
//cd "`path'work"


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\work"
use US_state_daily.dta,clear

replace statename="District of Columbia" if statename=="Washington DC"
replace statename="New York State" if statename=="New York"

merge 1:1 statename date_stata using vaccination_US.dta,force
sort _merge
drop if _merge==2
drop _merge


merge 1:1 state date_stata using US_cases_daily.dta
keep if _merge==3
drop _merge


//weather, protest, vaccaine share
merge 1:1 state date_stata using state_protest_daily.dta
drop if _merge==2
drop _merge
replace protest=0 if protest==.


merge 1:1 state date_stata using state_weather_daily.dta
drop if _merge==2
drop _merge


//
gen year=year(date_stata) 
tab year
replace month=month(date_stata) 
tab month
replace day=day(date_stata) 
tab day


egen data_num=group(date_stata)
tab data_num

tab data_num if year==2020 & month==10 & day==12  //data_num=274
replace data_num=data_num-1

gen week=int(data_num/7)
tab week

tab week if year==2020 & month==10 & day==12   //39; 39+3=42
replace week=week+3
tab week if year==2020 & month==10 & day==12 


sum people_vaccinated_per_hundred if week==62
drop if year==2020 & week<=10

//

ren stringencyindexfor stringency   //lockdown style policy
ren biden Xi_bidenwin
ren trump Xi_trumpwin
ren householdincome Xi_income
ren hospitalbed Xi_hospitalbed

gen Xi_govrepublic=1 if governorp=="Republican"
replace Xi_govrepublic=0 if Xi_govrepublic==.
tab Xi_govrepublic


collapse (max) month day date_stata ///
(mean) hospitalizedcurrently stringency popu Xi_biden Xi_trump Xi_income Xi_hospital Xi_gov ///
(max) death positive hospitalizedcumulative totaltestresults recovered people_vaccinated_per_hundred people_fully_vaccinated_per_hund SNOW TAVG ///
(sum) positiveincrease hospitalizedincrease protest,by(fipcode state week)


xtset fip week

bys state:sum people_vac

local w_var people_v people_f positive positiveincrease hospitalizedcumulative hospitalizedincrease death
foreach i in `w_var'{
replace `i'=0 if `i'==.
sum `i'
}



//merge state-weekly rally and vaccine
merge 1:1 state week using state_rally_week.dta

gen rally=1 if _merge==3
tab rally
bys state:egen rally_state=max(rally)
tab rally_state

sort _merge state rally_start
replace rally_end=rally_start+1      //rally last for two weeks

xtset fip week
gen lagweek=l1.week
replace rally=1 if lagweek==rally_endweek
tab rally
drop rally_* _merge
drop lagweek
replace rally=0 if rally==.
tab rally


merge 1:1 state week using state_vaccines_share.dta
drop if _merge==2
drop _merge

tab Xi_biden
gen lsnow=log(SNOW+1)
ren TAVG meantemp

//temp:deviation from the mean
tab state if meantemp==.

gen DCdummy=1 if state=="VA"  | state=="MD"
bys week:egen DCtemp=mean(meantemp) if DCdummy==1
bys week:egen DCtemp_max=max(DCtemp)
replace meantemp=DCtemp_max if state=="DC"
drop DC*

gen DEdummy=1 if state=="NJ"  | state=="MD"
bys week:egen DEtemp=mean(meantemp) if DEdummy==1
bys week:egen DEtemp_max=max(DEtemp)
replace meantemp=DEtemp_max if state=="DE" & meantemp==.
drop DE*


bys state:egen statetemp=mean(meantemp)
bys state:egen statede=sd(meantemp)

gen dev_temp=(meantemp-statetemp)/statede
sum dev_temp,de




//generate y variables

xtset fip week

gen lagI=l1.positive
gen infect_growth=(positive-lagI)/lagI
sum infect_growth,de
replace infect_g=0 if infect_g==.

gen InfectRate=(positive/popu)*100             //% points
gen lagInfectRate=(lagI/popu)*100

gen Iin=positiveincrease
gen logIin=log(positiveincrease+1)



//

gen lagH=l1.hospitalizedcumulative
gen hosp_growth=(hospitalizedcumulative-lagH)/lagH
sum hosp_growth,de
replace hosp_g=0 if hosp_g==.

gen HospRate=(hospitalizedcumulative/popu)*100    //% points
gen lagHospRate=(lagH/popu)*100

gen Hin=hospitalizedincrease
gen logHin=log(hospitalizedincrease+1)


//
ren Xi_bidenwin Xi_biden
drop Xi_trump
tab Xi_biden

xtset fip week

gen lstring=l1.string
gen lpeople_vac=l1.people_vac
gen lpeople_ful=l1.people_ful
replace lpeople_vac=0 if lpeople_vac==.
replace lpeople_ful=0 if lpeople_ful==.


gen TestRate=(totaltest/popu)*100
gen lagTest=l1.totaltest
gen lagTestRate=(lagTest/popu)*100

gen SuspRate=(popu-positive)/popu*100
gen lagSuspRate=(popu-lagI)/popu*100

//
xtset fip week
tabstat *_growth *in lstring lpeople_vac lpeople_ful lagInfectRate lagSuspRate lagTestRate,stat(n mean sd min p50 max) long col(stat)

list state week if lstring==.
sort state week
//3 points of obs missing stringency 
replace lstring=21.3 if state=="AL" & (week==61 | week==62)
replace lstring=50.93 if state=="RI" & (week==62)
list state week if string==.
replace string=21.3 if state=="AL" & (week==61)
replace string=50.93 if state=="RI" & (week==61)

replace hosp_growth=0.02 if hosp_growth<0   //AZ week==42 data error

ren fip panelid
sort week month day


// 21 weeks sample
keep if week>41
tab week


gen dummy_hosp=1 if hospitalizedcumulativ!=0 
replace dummy_hosp=0 if (state=="CT" | state=="NY")
replace dummy_hosp=0 if dummy_hosp==.
tab dummy_hosp



//s3.1 heterogeneity of politics

//growth rate
//infect
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==1,cluster(panelid week)
est store t11
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==0,cluster(panelid week)
est store t12
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==1,cluster(panelid week)
est store t13
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==0,cluster(panelid week)
est store t14

//hosp
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==1 & dummy_hosp==1,cluster(panelid week)
est store t15
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==0 & dummy_hosp==1,cluster(panelid week)
est store t16
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==1 & dummy_hosp==1,cluster(panelid week)
est store t17
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if Xi_biden==0 & dummy_hosp==1,cluster(panelid week)
est store t18


cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
outreg2 [t11 t12 t13 t14 t15 t16 t17 t18] using Sfigure3-1.doc,ctitle("") keep(lpeople_vac lpeople_ful) stats(coef se) ///
addtext(Week FE,Yes,State FE,Yes) replace dec(3)



coefplot (t11,msize(large) symbol(circle) color(blue) label(Biden Won, Growth Rate of Cases)) ///
(t12,msize(large) symbol(square) color(red) label(Trump Won, Growth Rate of Cases)) ///
(t15,msize(large) symbol(diamond) color(blue) label(Biden Won, Growth Rate of Hospitalizations)) ///
(t16,msize(large) symbol(triangle) color(red) label(Trump Won, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_vac) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, At Least 1 Dose") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3a1,replace



coefplot (t13,msize(large) symbol(circle)  color(blue) label(Biden Won, Growth Rate of Cases)) ///
(t14,msize(large) symbol(square) color(red) label(Trump Won, Growth Rate of Cases)) ///
(t17,msize(large) symbol(diamond) color(blue) label(Biden Won, Growth Rate of Hospitalizations)) ///
(t18,msize(large) symbol(triangle) color(red) label(Trump Won, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_ful) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, 2 Doses") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3a2,replace


gr combine sfigure3a1.gph sfigure3a2.gph, iscale(1) col(2) scheme(plotplain) title("a",position(11))

graph save sfigure3a,replace
graph export sfigure3a.png,replace



//s3.2 heterogeneity of policy
sum string,de
bys state:egen meanstring=mean(string)

egen policy50=median(meanstring)
gen high=1 if meanstring>=policy50
replace high=0 if high==.
tab high    //26 state vs 25 state


//growth rate
//infect
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t21
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t22
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t23
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t24

//hosp
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t25
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t26
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t27
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t28



cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"

coefplot (t21,msize(large) symbol(circle) color(blue) label(Stringency+, Growth Rate of Cases)) ///
(t22,msize(large) symbol(square) color(red) label(Stringency-, Growth Rate of Cases)) ///
(t25,msize(large) symbol(diamond) color(blue) label(Stringency+, Growth Rate of Hospitalizations)) ///
(t26,msize(large) symbol(triangle) color(red) label(Stringency-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_vac) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, At Least 1 Dose") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3b1,replace



coefplot (t23,msize(large) symbol(circle)  color(blue) label(Stringency+, Growth Rate of Cases)) ///
(t24,msize(large) symbol(square) color(red) label(Stringency-, Growth Rate of Cases)) ///
(t27,msize(large) symbol(diamond) color(blue) label(Stringency+, Growth Rate of Hospitalizations)) ///
(t28,msize(large) symbol(triangle) color(red) label(Stringency-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_ful) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, 2 Doses") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3b2,replace


gr combine sfigure3b1.gph sfigure3b2.gph, iscale(1) col(2) scheme(plotplain) title("b",position(11))

graph save sfigure3b,replace
graph export sfigure3b.png,replace


//s3.3 heterogeneity of age

//merge state-level variables
ren panelid fipcode
cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\work"
merge m:1 fipcode using US_state_pop.dta
drop _merge
ren fipcode panelid


ren elder_s elder_60
cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\raw"
merge m:1 panelid using pop_state_structure65.dta
ren elder_s elder_65
drop _merge


drop high
sum elder_65,de
tab elder_65
tab state if elder_65==.    
egen age50=median(elder_65)
gen high=1 if elder_65>=age50
replace high=0 if high==.
tab high    //26 state vs 25 state



//growth rate
//infect
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t31
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t32
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t33
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t34

//hosp
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t35
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t36
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t37
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t38



cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"

coefplot (t31,msize(large) symbol(circle) color(blue) label(Elderly+, Growth Rate of Cases)) ///
(t32,msize(large) symbol(square) color(red) label(Elderly-, Growth Rate of Cases)) ///
(t35,msize(large) symbol(diamond) color(blue) label(Elderly+, Growth Rate of Hospitalizations)) ///
(t36,msize(large) symbol(triangle) color(red) label(Elderly-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_vac) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, At Least 1 Dose") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3c1,replace



coefplot (t33,msize(large) symbol(circle)  color(blue) label(Elderly+, Growth Rate of Cases)) ///
(t34,msize(large) symbol(square) color(red) label(Elderly-, Growth Rate of Cases)) ///
(t37,msize(large) symbol(diamond) color(blue) label(Elderly+, Growth Rate of Hospitalizations)) ///
(t38,msize(large) symbol(triangle) color(red) label(Elderly-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_ful) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, 2 Doses") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3c2,replace


gr combine sfigure3c1.gph sfigure3c2.gph, iscale(1) col(2) scheme(plotplain) title("c",position(11))

graph save sfigure3c,replace
graph export sfigure3c.png,replace





//s3.4 heterogeneity of popu race
drop high

sum white,de
egen race50=median(white)
gen high=1 if white>=race50
replace high=0 if high==.
tab high    //25 state vs 25 state



//growth rate
//infect
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t41
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t42
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t43
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t44

//hosp
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t45
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t46
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t47
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t48



cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"


coefplot (t41,msize(large) symbol(circle) color(blue) label(White+, Growth Rate of Cases)) ///
(t42,msize(large) symbol(square) color(red) label(White-, Growth Rate of Cases)) ///
(t45,msize(large) symbol(diamond) color(blue) label(White+, Growth Rate of Hospitalizations)) ///
(t46,msize(large) symbol(triangle) color(red) label(White-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_vac) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, At Least 1 Dose") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3d1,replace



coefplot (t43,msize(large) symbol(circle)  color(blue) label(White+, Growth Rate of Cases)) ///
(t44,msize(large) symbol(square) color(red) label(White-, Growth Rate of Cases)) ///
(t47,msize(large) symbol(diamond) color(blue) label(White+, Growth Rate of Hospitalizations)) ///
(t48,msize(large) symbol(triangle) color(red) label(White-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_ful) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, 2 Doses") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3d2,replace


gr combine sfigure3d1.gph sfigure3d2.gph, iscale(1) col(2) scheme(plotplain) title("d",position(11))

graph save sfigure3d,replace
graph export sfigure3d.png,replace


//s4.5 heterogeneity of high vs low income 
drop high
sum Xi_income,de
tab Xi_income
tab state if Xi_income==.     //DC没有income数据
egen income50=median(Xi_income)
gen high=Xi_income>=income50
replace high=0 if high==.
tab high    //25 state vs 25 state


//growth rate
//infect
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t51
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t52
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t53
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t54


//hosp
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t55
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t56
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t57
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t58




cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"


coefplot (t51,msize(large) symbol(circle) color(blue) label(Income+, Growth Rate of Cases)) ///
(t52,msize(large) symbol(square) color(red) label(Income-, Growth Rate of Cases)) ///
(t55,msize(large) symbol(diamond) color(blue) label(Income+, Growth Rate of Hospitalizations)) ///
(t56,msize(large) symbol(triangle) color(red) label(Income-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_vac) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, At Least 1 Dose") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3e1,replace



coefplot (t53,msize(large) symbol(circle)  color(blue) label(Income+, Growth Rate of Cases)) ///
(t54,msize(large) symbol(square) color(red) label(Income-, Growth Rate of Cases)) ///
(t57,msize(large) symbol(diamond) color(blue) label(Income+, Growth Rate of Hospitalizations)) ///
(t58,msize(large) symbol(triangle) color(red) label(Income-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_ful) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, 2 Doses") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3e2,replace


gr combine sfigure3e1.gph sfigure3e2.gph, iscale(1) col(2) scheme(plotplain) title("e",position(11))

graph save sfigure3e,replace
graph export sfigure3e.png,replace




//s3.6 heterogeneity of pfizer share 
drop high

sum pfizer_share,de
tab week
sum pfizer_share if week==62

egen pfizer50=median(pfizer_share) if week==62
gen high_temp=pfizer_share>=pfizer50 & week==62
replace high_t=0 if high_==.
tab high_t

bys state:egen high=max(high_t)
replace high=0 if high==.
tab high    //25 state vs 25 state



//growth rate
//infect
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t61
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t62
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1,cluster(panelid week)
est store t63
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0,cluster(panelid week)
est store t64

//hosp
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t65 
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t66
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==1 & dummy_hosp==1,cluster(panelid week)
est store t67
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if high==0 & dummy_hosp==1,cluster(panelid week)
est store t68




cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"


coefplot (t61,msize(large) symbol(circle) color(blue) label(Pfizer+, Growth Rate of Cases)) ///
(t62,msize(large) symbol(square) color(red) label(Pfizer-, Growth Rate of Cases)) ///
(t65,msize(large) symbol(diamond) color(blue) label(Pfizer+, Growth Rate of Hospitalizations)) ///
(t66,msize(large) symbol(triangle) color(red) label(Pfizer-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_vac) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, At Least 1 Dose") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3f1,replace



coefplot (t63,msize(large) symbol(circle)  color(blue) label(Pfizer+, Growth Rate of Cases)) ///
(t64,msize(large) symbol(square) color(red) label(Pfizer-, Growth Rate of Cases)) ///
(t67,msize(large) symbol(diamond) color(blue) label(Pfizer+, Growth Rate of Hospitalizations)) ///
(t68,msize(large) symbol(triangle) color(red) label(Pfizer-, Growth Rate of Hospitalizations)), legend(position(11)) ///
keep(lpeople_ful) xline(0) xtitle("") scheme(plotplain) ylabel(,tstyle(none)) xtitle("Vaccination Rate, 2 Doses") ///
mlabel format(%9.3f) mlabposition(12) mlabsize(medium) ciopts(recast(rcap) color(red)) fysize(100)

graph save sfigure3f2,replace


gr combine sfigure3f1.gph sfigure3f2.gph, iscale(1) col(2) scheme(plotplain) title("f",position(11))

graph save sfigure3f,replace
graph export sfigure3f.png,replace
/*********************************************************************************************************************************/



/*********************************************************************************************************************************/

// supplement Figure 6

clear all
set more off

//local path "C:\Users\Hanwei\Dropbox\CovidEconomics\vaccination\GitHub\data\" 
//cd "`path'work"

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\data\work"
use US_state_daily.dta,clear

replace statename="District of Columbia" if statename=="Washington DC"
replace statename="New York State" if statename=="New York"

merge 1:1 statename date_stata using vaccination_US.dta,force
sort _merge
drop if _merge==2
drop _merge


merge 1:1 state date_stata using US_cases_daily.dta
keep if _merge==3
drop _merge


//weather, protest, vaccaine share
merge 1:1 state date_stata using state_protest_daily.dta
drop if _merge==2
drop _merge
replace protest=0 if protest==.


merge 1:1 state date_stata using state_weather_daily.dta
drop if _merge==2
drop _merge


//
gen year=year(date_stata) 
tab year
replace month=month(date_stata) 
tab month
replace day=day(date_stata) 
tab day


egen data_num=group(date_stata)
tab data_num

tab data_num if year==2020 & month==10 & day==12  //data_num=274
replace data_num=data_num-1

gen week=int(data_num/7)
tab week

tab week if year==2020 & month==10 & day==12   //39; 39+3=42
replace week=week+3
tab week if year==2020 & month==10 & day==12 


sum people_vaccinated_per_hundred if week==62
drop if year==2020 & week<=10

//

ren stringencyindexfor stringency   //lockdown style policy
ren biden Xi_bidenwin
ren trump Xi_trumpwin
ren householdincome Xi_income
ren hospitalbed Xi_hospitalbed

gen Xi_govrepublic=1 if governorp=="Republican"
replace Xi_govrepublic=0 if Xi_govrepublic==.
tab Xi_govrepublic



//OLS ipolate
drop people_vaccinated people_fully_vaccinated
bys week:sum people_vac
replace people_vac=. if people_vac==0

xtset fip date_stata
bys fip:mipolate people_vacc date_stata,gen(temp_people_vac) epolate 
bys date_stata:sum temp_people_vac
//date_num==343: 21 Dec, 2020 
replace people_vacc=temp_people_vac if temp_people_vac>0 & data_num>=343
bys date_stata:sum people_vacc


xtset fip date_stata
replace people_ful=. if people_ful==0

bys fip:mipolate people_ful date_stata,gen(temp_people_ful) epolate 
bys date_stata:sum temp_people_ful
replace people_ful=temp_people_ful if temp_people_ful>0 & data_num>=343
bys date_stata:sum people_ful
replace people_vac=0 if people_vac==.
replace people_ful=0 if people_ful==.



collapse (max) month day date_stata ///
(mean) hospitalizedcurrently stringency popu Xi_biden Xi_trump Xi_income Xi_hospital Xi_gov ///
(max) death positive hospitalizedcumulative totaltestresults recovered people_vaccinated_per_hundred people_fully_vaccinated_per_hund SNOW TAVG ///
(sum) positiveincrease hospitalizedincrease protest,by(fipcode state week)


xtset fip week

bys state:sum people_vac

local w_var people_v people_f positive positiveincrease hospitalizedcumulative hospitalizedincrease death
foreach i in `w_var'{
replace `i'=0 if `i'==.
sum `i'
}



//merge state-weekly rally and vaccine
merge 1:1 state week using state_rally_week.dta

gen rally=1 if _merge==3
tab rally
bys state:egen rally_state=max(rally)
tab rally_state

sort _merge state rally_start
replace rally_end=rally_start+1      //rally last for two weeks

xtset fip week
gen lagweek=l1.week
replace rally=1 if lagweek==rally_endweek
tab rally
drop rally_* _merge
drop lagweek
replace rally=0 if rally==.
tab rally


merge 1:1 state week using state_vaccines_share.dta
drop if _merge==2
drop _merge

tab Xi_biden
gen lsnow=log(SNOW+1)
ren TAVG meantemp

//temp:deviation from the mean
tab state if meantemp==.

gen DCdummy=1 if state=="VA"  | state=="MD"
bys week:egen DCtemp=mean(meantemp) if DCdummy==1
bys week:egen DCtemp_max=max(DCtemp)
replace meantemp=DCtemp_max if state=="DC"
drop DC*

gen DEdummy=1 if state=="NJ"  | state=="MD"
bys week:egen DEtemp=mean(meantemp) if DEdummy==1
bys week:egen DEtemp_max=max(DEtemp)
replace meantemp=DEtemp_max if state=="DE" & meantemp==.
drop DE*


bys state:egen statetemp=mean(meantemp)
bys state:egen statede=sd(meantemp)

gen dev_temp=(meantemp-statetemp)/statede
sum dev_temp,de


//generate y variables

xtset fip week

gen lagI=l1.positive
gen infect_growth=(positive-lagI)/lagI
sum infect_growth,de
replace infect_g=0 if infect_g==.

gen InfectRate=(positive/popu)*100             //% points
gen lagInfectRate=(lagI/popu)*100

gen Iin=positiveincrease
gen logIin=log(positiveincrease+1)



//

gen lagH=l1.hospitalizedcumulative
gen hosp_growth=(hospitalizedcumulative-lagH)/lagH
sum hosp_growth,de
replace hosp_g=0 if hosp_g==.

gen HospRate=(hospitalizedcumulative/popu)*100    //% points
gen lagHospRate=(lagH/popu)*100

gen Hin=hospitalizedincrease
gen logHin=log(hospitalizedincrease+1)


//
ren Xi_bidenwin Xi_biden
drop Xi_trump
tab Xi_biden

xtset fip week

gen lstring=l1.string
gen lpeople_vac=l1.people_vac
gen lpeople_ful=l1.people_ful
replace lpeople_vac=0 if lpeople_vac==.
replace lpeople_ful=0 if lpeople_ful==.


gen TestRate=(totaltest/popu)*100
gen lagTest=l1.totaltest
gen lagTestRate=(lagTest/popu)*100

gen SuspRate=(popu-positive)/popu*100
gen lagSuspRate=(popu-lagI)/popu*100

//
xtset fip week
tabstat *_growth *in lstring lpeople_vac lpeople_ful lagInfectRate lagSuspRate lagTestRate,stat(n mean sd min p50 max) long col(stat)

list state week if lstring==.
sort state week
//3 points of obs missing stringency 
replace lstring=21.3 if state=="AL" & (week==61 | week==62)
replace lstring=50.93 if state=="RI" & (week==62)
list state week if string==.
replace string=21.3 if state=="AL" & (week==61)
replace string=50.93 if state=="RI" & (week==61)

replace hosp_growth=0.02 if hosp_growth<0   //AZ week==42 data error

ren fip panelid
sort week month day

gen dummy_hosp=1 if hospitalizedcumulativ!=0 
replace dummy_hosp=0 if (state=="CT" | state=="NY")
replace dummy_hosp=0 if dummy_hosp==.
tab dummy_hosp



//growth rate + vacc

vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=18,cluster(panelid week)
est store t10
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=21,cluster(panelid week)
est store t11
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=24,cluster(panelid week)
est store t12
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=27,cluster(panelid week)
est store t13
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=30,cluster(panelid week)
est store t14
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=33,cluster(panelid week)
est store t15
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=36,cluster(panelid week)
est store t16
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=39,cluster(panelid week)
est store t17
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=42,cluster(panelid week)
est store t18
vce2way reg infect_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=45,cluster(panelid week)
est store t19


coefplot (t10, label(45 week)) (t11, label(42 week)) (t12, label(39 week)) (t13, label(36 week)) (t14, label(33 week)) ///
(t15, label(30 week)) (t16, label(27 week)) (t17, label(24 week))  (t18, label(21 week-baseline)) (t19, label(18 week)), ///
keep(lpeople_vac) ytitle("Growth rate of cases") xline(0) xlabel(-0.015(0.003)0) xtitle("Vaccination rate, at least 1 dose") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(small) ciopts(recast(rcap)) legend(off)

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
graph save sfigure6a,replace



//growth rate + ful

vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=18,cluster(panelid week)
est store t20
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=21,cluster(panelid week)
est store t21
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=24,cluster(panelid week)
est store t22
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=27,cluster(panelid week)
est store t23
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=30,cluster(panelid week)
est store t24
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=33,cluster(panelid week)
est store t25
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=36,cluster(panelid week)
est store t26
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=39,cluster(panelid week)
est store t27
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=42,cluster(panelid week)
est store t28
vce2way reg infect_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=45,cluster(panelid week)
est store t29


coefplot (t20, label(45 week)) (t21, label(42 week)) (t22, label(39 week)) (t23, label(36 week)) (t24, label(33 week)) ///
(t25, label(30 week)) (t26, label(27 week)) (t27, label(24 week))  (t28, label(21 week-baseline)) (t29, label(18 week)), ///
keep(lpeople_ful) ytitle("Growth rate of cases") xline(0) xtitle("Vaccination rate, 2 doses") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(small) ciopts(recast(rcap)) legend(off)

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
graph save sfigure6b,replace



//hosp rate + vacc
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=18 & dummy_hosp==1,cluster(panelid week)
est store t30
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=21 & dummy_hosp==1,cluster(panelid week)
est store t31
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=24 & dummy_hosp==1,cluster(panelid week)
est store t32
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=27 & dummy_hosp==1,cluster(panelid week)
est store t33
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=30 & dummy_hosp==1,cluster(panelid week)
est store t34
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=33 & dummy_hosp==1,cluster(panelid week)
est store t35
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=36 & dummy_hosp==1,cluster(panelid week)
est store t36
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=39 & dummy_hosp==1,cluster(panelid week)
est store t37
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=42 & dummy_hosp==1,cluster(panelid week)
est store t38
vce2way reg hosp_growth lpeople_vac lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=45 & dummy_hosp==1,cluster(panelid week)
est store t39


coefplot (t30, label(45 week)) (t31, label(42 week)) (t32, label(39 week)) (t33, label(36 week)) (t34, label(33 week)) ///
(t35, label(30 week)) (t36, label(27 week)) (t37, label(24 week))  (t38, label(21 week-baseline)) (t39, label(18 week)), ///
keep(lpeople_vac) ytitle("Growth rate of hospitalizations") xline(0) xlabel(-0.012(0.002)0) xtitle("Vaccination rate, at least 1 dose") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(small) ciopts(recast(rcap)) legend(off)

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
graph save sfigure6c,replace



//hosp rate + ful
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=18 & dummy_hosp==1,cluster(panelid week)
est store t40
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=21 & dummy_hosp==1,cluster(panelid week)
est store t41
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=24 & dummy_hosp==1,cluster(panelid week)
est store t42
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=27 & dummy_hosp==1,cluster(panelid week)
est store t43
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=30 & dummy_hosp==1,cluster(panelid week)
est store t44
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=33 & dummy_hosp==1,cluster(panelid week)
est store t45
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=36 & dummy_hosp==1,cluster(panelid week)
est store t46
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=39 & dummy_hosp==1,cluster(panelid week)
est store t47
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=42 & dummy_hosp==1,cluster(panelid week)
est store t48
vce2way reg hosp_growth lpeople_ful lstring lagSuspRate lagTestRate rally protest lsnow dev_temp i.panelid i.week if week>=45 & dummy_hosp==1,cluster(panelid week)
est store t49


coefplot (t40, label(45 week)) (t41, label(42 week)) (t42, label(39 week)) (t43, label(36 week)) (t44, label(33 week)) ///
(t45, label(30 week)) (t46, label(27 week)) (t47, label(24 week))  (t48, label(21 week-baseline)) (t49, label(18 week)), ///
keep(lpeople_ful) ytitle("Growth rate of hospitalizations") xline(0) xtitle("Vaccination rate, 2 doses") scheme(plotplain) ylabel(,tstyle(none)) ///
mlabel format(%9.3f) mlabposition(12) mlabsize(small) ciopts(recast(rcap))

cd "C:\Users\Jialiang\Dropbox\CovidEconomics\vaccination\draft\main_Figures\sfigures"
graph save sfigure6d,replace

gr combine sfigure6a.gph sfigure6b.gph sfigure6c.gph sfigure6d.gph, iscale(0.75) scheme(plotplain)
graph save sfigure6,replace
graph export sfigure6.png,replace





