 use "panel.dta"
 
 xtset region week
 xtreg infection_g policy i.region i.week
 
outreg2 using beta.xls,replace bdec(7) sdec(7) ctitle(y) keep(policy i.region i.week)
