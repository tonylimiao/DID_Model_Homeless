clear all
cd "D:\Google Drive\My Teaching\Clemson\Independent_Studies\Austin_Sanderson\DID_Model_Homeless\Data"

import excel "CoC_Cannabis.xlsx", sheet("Sheet1") firstrow
sort state CoCNumber year FIPSStateCounty 
egen pickst=tag(state)
egen pickcoc=tag(CoCNumber)
egen pkcocyr=tag(CoCNumber year)
*br state CoCNumber FIPSStateCounty year pickst pickcoc pkcocyr

*** State-level summary stats: legalization of grass ***
bysort state: egen end   = max( C_Legal_Rec )   // end status on grass legalization
tab end if pickst==1
bysort state: egen start = min( C_Legal_Rec )   // start status on grass legalization
tab end start if pickst==1
list state if start==0 & end==1 & pickst==1     // 12 states evolved from ilegal to legal; in other words, exposed to treatment. 1 state (AK) previously treated

bysort state: gen yearlegal= year if C_Legal_Rec[_n] > C_Legal_Rec[_n-1]
xfill yearlegal, i(state_FIPS)
tab yearlegal if pickst==1
recode yearlegal (.=0)

encode CoCNumber, g(CoCid)

*** CoC-level summary stats: pre-treatment covariates ***

rename total_pop pop
rename land_area land
gen poor18_ct = subinstr(UnderAge18inPovertyCount, ",", "", .)
destring poor18_ct, replace 
gen pop18 = subinstr(UnderAge18SAIPEPovertyUnive, ",", "", .)
destring pop18, replace 
rename total_jail_pop jail 
rename total_prison_pop prsn 
rename avg_low_temp lw_temp
rename TempAnomaly19012000baseper temp_norm
gen poor_ct = pop*AllAgesinPovertyPercent

foreach i in lw_temp temp_norm{
          bysort CoCid: egen coc_`i'_t = mean(`i') if year < yearlegal & yearlegal !=0
          xfill coc_`i'_t, i(CoCid)
          bysort CoCid: egen coc_`i'_c = mean(`i') if yearlegal ==0
          xfill coc_`i'_c, i(CoCid)
          gen coc_`i' = coc_`i'_t
          replace coc_`i' = coc_`i'_c if missing(coc_`i')
          drop coc_`i'_t coc_`i'_c

}

foreach i in pop pop18 land metro_area poor_ct poor18_ct {
          bysort CoCid: egen coc_`i'_t = sum(`i') if year < yearlegal & yearlegal !=0
          xfill coc_`i'_t, i(CoCid)
          bysort CoCid: egen coc_`i'_c = sum(`i') if yearlegal ==0
          xfill coc_`i'_c, i(CoCid)
          gen coc_`i' = coc_`i'_t
          replace coc_`i' = coc_`i'_c if missing(coc_`i')
          drop coc_`i'_t coc_`i'_c
}
gen coc_popden = coc_pop / coc_land
gen coc_poverty = coc_poor_ct / coc_pop
gen coc_poverty18 = coc_poor18_ct / coc_pop18

*** use CoC-level 2007 baseline measure: aggregate over counties ***
foreach i in lw_temp temp_norm {
             bysort CoCid year: egen `i'_cocbs = mean(`i') if year == 2010
			 xfill `i'_cocbs, i(CoCid)
}
foreach i in pop pop18 land metro_area poor_ct poor18_ct {
             bysort CoCid year: egen `i'_cocbs = sum(`i') if year == 2010
			 xfill `i'_cocbs, i(CoCid)
}
gen coc_popden2010 = pop_cocbs / coc_land
gen coc_poverty2010 = poor_ct_cocbs / pop_cocbs
gen coc_poverty18_2010 = poor18_ct_cocbs / pop18_cocbs


keep if pkcocyr==1
sort state CoCid year FIPSStateCounty
br state CoCid year FIPSStateCounty yearlegal pop pop18 pop_cocbs pop18_cocbs


*** CoC-year level stats: outcomes; aggregate over counties ***
foreach i in jail prsn {
      bysort CoCid year: egen cyr_`i' = sum(`i')
	  recode cyr_`i' (0=.)
}

*** CoC-year level stats: treatment status ***
gen prepost=0 if yearlegal==0
replace prepost=0 if yearlegal >0 & year < yearlegal
replace prepost=1 if yearlegal >0 & year >= yearlegal
replace prepost=1 if state=="AK"
 
label var prepost "treatment dummy"
label var yearlegal "year legalization happen"

drop if year >2018
 
 
 

xtset CoCid
xtreg jail i.prepost i.year, fe



sort state_FIPS year
order state state_FIPS year yearlegal prepost jail prsn coc_poverty18_2010 coc_poverty2010 coc_popden2010
save "Stata_data\work_data.dta", replace

use "Stata_data\work_data.dta", clear
drop if missing(jailrate)
bysort state: egen ctocc=count(year)
tab ctocc
drop if ctocc <12
save "Stata_data\work_data_nomissing.dta", replace

mdesc prepost state_FIPS year jailrate
