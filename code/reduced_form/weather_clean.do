* the raw weather data can be downloaded from https://www.ncdc.noaa.gov/cdo-web/datasets
* we download the daily Summaries from the FTP for year 2020 and 2021

* the station information is from https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/
* we download ghcnd-stations.txt

clear
set more off

*2020
cd  C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\2020.csv

import delimited "2020", clear
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

save "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\station_data_2020.dta", replace


*2021
cd  C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\2021.csv
import delimited "2021", clear
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

save "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\station_data_2021.dta", replace


clear
import delimited "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\ghcnd-stations.txt"

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
save "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\US_stations.dta", replace


use "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\station_data_2020.dta", clear

append using "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\station_data_2021.dta"

joinby ID using "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\US_stations.dta", unmatched(b)

tab _m

keep if _m==3

collapse (mean) AWDR AWND DAPR DASF EVAP MDPR MDSF MNPN MXPN PGTM PRCP PSUN SN31 SN32 SN33 SN35 SN36 SN51 SN52 SN53 SN55 SN56 SNOW SNWD SX31 SX32 SX33 SX35 SX36 SX51 SX52 SX53 SX55 SX56 TAVG THIC TMAX TMIN TOBS TSUN WDF2 WDF5 WDFG WDMV WESD WESF WSF2 WSF5 WSFG WSFI WT01 WT02 WT03 WT04 WT05 WT06 WT07 WT08 WT09 WT10 WT11, by(states date)

keep PRCP SNOW  SNWD TAVG TMAX TMIN states date



save "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\US_states_weather.dta", replace

erase "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\station_data_2020.dta"
erase "C:\Users\hhuang54\Dropbox\CovidEconomics\vaccination\data\raw\weather\station_data_2021.dta"
