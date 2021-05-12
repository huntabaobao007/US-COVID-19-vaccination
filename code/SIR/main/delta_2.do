 use "delta.dta"

 xtset region week 
 destring _all, replace force
 
 xtreg delta2 week i.region i.week

 outreg2 using delta_2.xls, replace bdec(7) sdec(7) ctitle(y) keep(week i.region i.week)
