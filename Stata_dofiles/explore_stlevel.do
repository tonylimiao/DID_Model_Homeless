clear all
import excel "D:\Google Drive\My Teaching\Clemson\Independent_Studies\Austin_Sanderson\CoC_Cannabis.xlsx", sheet("Sheet1") firstrow
sort state year
egen pickst=tag( state )
egen pickyr=tag(state year)
egen pickcoc=tag( CoCNumber)

br state CoCNumber year pickst pickyr pickcoc

bysort state: egen legalevr=max( C_Legal_Rec )
tab legalevr if pickst==1
bysort state: egen ilegalevr=min( C_Legal_Rec )
tab legalevr ilegalevr if pickst==1
list state if ilegalevr==0 & legalevr==1 & pickst==1     // 12 states evolved from ilegal to legal; in other words, exposed to treatment. 1 state (AK) previously treated

bysort state: gen yearlegal= year if C_Legal_Rec[_n] > C_Legal_Rec[_n-1]
xfill yearlegal, i(state_FIPS)
tab yearlegal if pickst==1

gen treat=1 if ilegalevr==1 | legalevr==1
replace treat=0 if ilegalevr==0 & legalevr==0
xfill treat, i(state_FIPS)

foreach i in total_pop land_area metro_area total_jail_pop_rate total_prison_pop_rate{
       bysort state year: egen st_`i' = sum(`i')
}
gen st_pop_den = st_total_pop / st_land_area

rename total_jail_pop_rate jailrate
rename total_prison_pop_rate prsnrate

keep state year state_FIPS pickst pickyr st_pop_den st_metro_area treat yearlegal jailrate prsnrate
keep if pickyr==1

gen prepost=0 if treat==0
replace prepost=0 if treat==1 & year < yearlegal
replace prepost=1 if treat==1 & year >= yearlegal
replace prepost=1 if state=="AK"

xtset state_FIPS
xtreg jailrate i.prepost i.year, fe

list state if treat==1 & pickst==1
label var treat "ever treated: legalization occured"
label var prepost "treatment dummy"
label var yearlegal "year legalization happen"

sort state_FIPS year
order state state_FIPS year yearlegal prepost jailrate prsnrate
save "D:\Google Drive\My Teaching\Clemson\Independent_Studies\Austin_Sanderson\work_data.dta", replace

use "D:\Google Drive\My Teaching\Clemson\Independent_Studies\Austin_Sanderson\work_data.dta", clear
drop if missing(jailrate)
bysort state: egen ctocc=count(year)
tab ctocc
drop if ctocc <12
save "D:\Google Drive\My Teaching\Clemson\Independent_Studies\Austin_Sanderson\work_data_nomissing.dta", replace

mdesc prepost state_FIPS year jailrate
