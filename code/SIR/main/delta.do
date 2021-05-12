 use "delta.dta"

 xtset region week 
 destring _all, replace force
 
 xtreg delta1 i.region i.week

 outreg2 using delta.xls, replace bdec(7) sdec(7) ctitle(y) keep(i.region i.week)
