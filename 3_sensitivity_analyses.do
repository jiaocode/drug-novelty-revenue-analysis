*******************************************************
* 03_sensitivity_analyses.do
*
* Sensitivity Analyses for Revenue / Novelty Study
*  - SA1: Median (unadjusted) revenue trends
*  - SA2: Cohorts launched before 2013
*  - SA3: Baseline chemical / target scores
*  - SA4: Lower threshold for ADME score (sensitivity spec)
*  - SA6: No exclusivity restriction
*  - SA7: Restricted to drugs observed in both MEPS & SSR
*
* Requires: revenue_GTN.dta (product-year level)
*******************************************************

version 17
clear all
set more off
set scheme s2color   // color scheme; backgrounds forced to white in graphs

*******************************************************
* 0. User paths (EDIT THIS)
*******************************************************
local DATA_DIR "PATH_TO_DATA_DIRECTORY"   // e.g. ".../Pharmaproject/Data"
cd "`DATA_DIR'"

*******************************************************
* 1. Install grc1leg2 (if missing)
*******************************************************
cap which grc1leg2
if _rc {
    net install grc1leg2.pkg, from("http://digital.cgdev.org/doc/stata/MO/Misc/")
}

*******************************************************
* 2. Global graph controls (shared)
*******************************************************
* Combined graph sizes
local XS 10
local YS 14

* Pixel export sizes (default tall)
local W  2800
local H  4300

* Text sizes
local t_title   medium
local t_label   small
local t_ticks   small
local t_legend  small
local t_axis    `t_label'

* Flat panels so axes/legend don't crowd
local flat aspectratio(0.45)

* PURE white everywhere
local whitebg graphregion(fcolor(white) lcolor(white)) ///
              plotregion(fcolor(white)  lcolor(white))

* Lowess + line width
local bw bw(0.4)
local lw lwidth(medium)


*******************************************************
*******************************************************
* SENSITIVITY ANALYSIS 1: Median analysis (unadjusted)
*******************************************************
*******************************************************

local OUTPNG_SA1 "final_adjusted_median.png"
local OUTGPH_SA1 "final_adjusted_median.gph"

* Axes label for median revenues (no re-scaling -> actual $)
local axes_sa1  xtitle("Year", size(`t_label')) ///
                ytitle("Median Revenue ($)", size(`t_label')) ///
                xlabel(2000(5)2020, labsize(`t_ticks')) ///
                ylabel(, labsize(`t_ticks')) ///
                xscale(range(2000 2020) noextend)

*******************************************************
* SA1 Panel A — Molecular Structure
*******************************************************
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA"
keep if inrange(year, 2000, 2019) & year <= exclu_year1 & exclu_year1 != .
drop if chemical_score == . | total_paid == .

gen score_group0 = 1 if chemical_score <= $chemical_c1
replace score_group0 = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group0 = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

collapse (median) net_spending   = net_revenue ///
                 (median) gross_spending = total_paid, by(score_group0 year)

twoway ///
 (lowess gross_spending year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_spending year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_spending year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_spending   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_sa1' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty"   ///
                 2 "Gross – Medium novelty" ///
                 3 "Gross – Low novelty"    ///
                 4 "Net – High novelty"     ///
                 5 "Net – Medium novelty"   ///
                 6 "Net – Low novelty")     ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(SA1_panelA, replace)
graph save SA1_chemical_score_plot.gph, replace

*******************************************************
* SA1 Panel B — Therapeutic Target
*******************************************************
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA"
keep if inrange(year, 2000, 2019) & year <= exclu_year1 & exclu_year1 != .
drop if target_score == . | total_paid == .

gen score_group0 = 1 if target_score <= $target_c1
replace score_group0 = 2 if target_score > $target_c1 & target_score <= $target_c2
replace score_group0 = 3 if target_score > $target_c2 & target_score <= 1000

collapse (median) net_spending   = net_revenue ///
                 (median) gross_spending = total_paid, by(score_group0 year)

twoway ///
 (lowess gross_spending year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_spending year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_spending year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_spending   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_sa1' `flat' `whitebg' legend(off) ///
    name(SA1_panelB, replace)
graph save SA1_target_score_plot.gph, replace

*******************************************************
* SA1 Panel C — Delivery Properties (ADME)
*******************************************************
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if ADME_score == . | total_paid == .

gen score_group0 = 1 if ADME_score <= $ADME_c1
replace score_group0 = 2 if ADME_score > $ADME_c1 & ADME_score <= $ADME_c2
replace score_group0 = 3 if ADME_score > $ADME_c2 & ADME_score <= 1

collapse (median) net_spending   = net_revenue ///
                 (median) gross_spending = total_paid, by(score_group0 year)

twoway ///
 (lowess gross_spending year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_spending year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_spending year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_spending   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_sa1' `flat' `whitebg' legend(off) ///
    name(SA1_panelC, replace)
graph save SA1_adme_score_plot.gph, replace

*******************************************************
* SA1 Combine 3×1
*******************************************************
grc1leg2 SA1_panelA SA1_panelB SA1_panelC, ///
    cols(1) rows(3)                     ///
    legendfrom(SA1_panelA)              ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(SA1_all_panels, replace)

graph save `OUTGPH_SA1', replace
graph export `OUTPNG_SA1', width(`W') height(`H') replace
di as res "SA1 (median) -> `OUTPNG_SA1'"


*******************************************************
*******************************************************
* SENSITIVITY ANALYSIS 2: Cohorts before 2013
*******************************************************
*******************************************************

local OUTPNG_SA2 "final_adjusted_before2013.png"
local OUTGPH_SA2 "final_panels_adjusted_before2013.gph"

local axes_sa2  xtitle("Year", size(`t_label')) ///
                ytitle("Adjusted Mean Revenue (Million $)", size(`t_label')) ///
                xlabel(2000(5)2020, labsize(`t_ticks')) ///
                ylabel(, labsize(`t_ticks')) ///
                xscale(range(2000 2020) noextend)

*******************************************************
* SA2 Panel A — Molecular Structure
*******************************************************
tempfile SA2tmpA SA2tmpAres
use revenue_GTN.dta, clear
capture drop score_group0 year0 cohort_year

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1
drop if chemical_score == . | total_paid == .

gen score_group0 = 1 if chemical_score <= $chemical_c1
replace score_group0 = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group0 = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

gen cohort_year = year - year_since_launch
gen year0       = year - 2000
keep if cohort_year <= 2012

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA2tmpA', replace
cap erase `SA2tmpAres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA2tmpA', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA2tmpAres'
        save `SA2tmpAres', replace
    }
}

use `SA2tmpAres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_sa2' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty" 2 "Gross – Medium novelty" 3 "Gross – Low novelty" ///
                 4 "Net – High novelty"   5 "Net – Medium novelty"   6 "Net – Low novelty") ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(SA2_panelA, replace)
graph save SA2_chemical_score_adjusted.gph, replace

*******************************************************
* SA2 Panel B — Therapeutic Target
*******************************************************
tempfile SA2tmpB SA2tmpBres
use revenue_GTN.dta, clear
capture drop score_group0 cohort_year year0

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if target_score == . | total_paid == .

gen score_group0 = 1 if target_score <= $target_c1
replace score_group0 = 2 if target_score > $target_c1 & target_score <= $target_c2
replace score_group0 = 3 if target_score > $target_c2 & target_score <= 1000

gen cohort_year = year - year_since_launch
gen year0       = year - 2000
keep if cohort_year <= 2012

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA2tmpB', replace
cap erase `SA2tmpBres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA2tmpB', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA2tmpBres'
        save `SA2tmpBres', replace
    }
}

use `SA2tmpBres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_sa2' `flat' `whitebg' legend(off) ///
    name(SA2_panelB, replace)
graph save SA2_target_score_adjusted.gph, replace

*******************************************************
* SA2 Panel C — Delivery Properties (ADME)
*******************************************************
tempfile SA2tmpC SA2tmpCres
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if ADME_score == . | total_paid == .

capture drop score_group0 cohort_year year0

gen score_group0 = 1 if ADME_score <= $ADME_c1
replace score_group0 = 2 if ADME_score > $ADME_c1 & ADME_score <= $ADME_c2
replace score_group0 = 3 if ADME_score > $ADME_c2 & ADME_score <= 1

gen cohort_year = year - year_since_launch
gen year0       = year - 2000
keep if cohort_year <= 2012

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA2tmpC', replace
cap erase `SA2tmpCres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA2tmpC', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA2tmpCres'
        save `SA2tmpCres', replace
    }
}

use `SA2tmpCres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_sa2' `flat' `whitebg' legend(off) ///
    name(SA2_panelC, replace)
graph save SA2_adme_score_adjusted.gph, replace

*******************************************************
* SA2 Combine 3×1
*******************************************************
grc1leg2 ///
    SA2_chemical_score_adjusted.gph ///
    SA2_target_score_adjusted.gph   ///
    SA2_adme_score_adjusted.gph,    ///
    cols(1) rows(3)                     ///
    legendfrom(SA2_chemical_score_adjusted.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(SA2_all_panels, replace)

graph save `OUTGPH_SA2', replace
graph export `OUTPNG_SA2', width(`W') height(`H') replace
di as res "SA2 (cohorts <=2012) -> `OUTPNG_SA2'"


************************************************************
************************************************************
* SENSITIVITY ANALYSIS 3: Baseline chem/target scores
************************************************************
************************************************************

local OUTPNG_SA3 "final_adjusted_basescore.png"
local OUTGPH_SA3 "final_adjusted_basescore.gph"

local XS_SA3 12
local YS_SA3 10.5
local H_SA3  3153   // shorter height

local axes_sa3  xtitle("Year", size(`t_label')) ///
                ytitle("Adjusted Mean Revenue (Million $)", size(`t_label')) ///
                xlabel(2000(5)2020, labsize(`t_ticks')) ///
                ylabel(, labsize(`t_ticks')) ///
                xscale(range(2000 2020) noextend)

*******************************************************
* SA3 Panel A — Molecular Structure (baseline chemical)
*******************************************************
tempfile SA3tmpA SA3tmpAres
use revenue_GTN.dta, clear
capture drop score_group0 year0 cohort_year

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1
drop if base_chemical_score == . | total_paid == .

xtile score_group0 = base_chemical_score, n(3)

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA3tmpA', replace
cap erase `SA3tmpAres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA3tmpA', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA3tmpAres'
        save `SA3tmpAres', replace
    }
}

use `SA3tmpAres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_sa3' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty" 2 "Gross – Medium novelty" 3 "Gross – Low novelty" ///
                 4 "Net – High novelty"   5 "Net – Medium novelty"   6 "Net – Low novelty") ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(SA3_panelA, replace)
graph save SA3_chemical_score_adjusted.gph, replace

*******************************************************
* SA3 Panel B — Therapeutic Target (baseline target)
*******************************************************
tempfile SA3tmpB SA3tmpBres
use revenue_GTN.dta, clear
capture drop score_group0 cohort_year year0

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if base_target_score == . | total_paid == .

xtile score_group0 = base_target_score, n(3)

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA3tmpB', replace
cap erase `SA3tmpBres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA3tmpB', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA3tmpBres'
        save `SA3tmpBres', replace
    }
}

use `SA3tmpBres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_sa3' `flat' `whitebg' legend(off) ///
    name(SA3_panelB, replace)
graph save SA3_target_score_adjusted.gph, replace

*******************************************************
* SA3 Combine 2×1 (baseline scores)
*******************************************************
grc1leg2 ///
    SA3_chemical_score_adjusted.gph ///
    SA3_target_score_adjusted.gph,    ///
    cols(1) rows(2)                     ///
    legendfrom(SA3_chemical_score_adjusted.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS_SA3') ysize(`YS_SA3')     ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(SA3_all_panels, replace)

graph save `OUTGPH_SA3', replace
graph export `OUTPNG_SA3', width(`W') height(`H_SA3') replace
di as res "SA3 (baseline scores) -> `OUTPNG_SA3'"


***************************************************************
***************************************************************
* SENSITIVITY ANALYSIS 4: Lower ADME threshold (ADME_score_sense)
***************************************************************
***************************************************************

local OUTPNG_SA4 "final_adjusted_admesense.png"
local OUTGPH_SA4 "final_adjusted_admesense.gph"

local XS_SA4 12
local YS_SA4 8.5
local H_SA4  2313

local axes_sa4  xtitle("Year", size(`t_label')) ///
                ytitle("Adjusted Mean Revenue (Million $)", size(`t_label')) ///
                xlabel(2000(5)2020, labsize(`t_ticks')) ///
                ylabel(, labsize(`t_ticks')) ///
                xscale(range(2000 2020) noextend)

tempfile SA4tmp SA4tmpres
use revenue_GTN.dta, clear
capture drop score_group0 year0 cohort_year

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if ADME_score_sense == . | total_paid == .

xtile score_group0 = ADME_score_sense, n(3)

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA4tmp', replace
cap erase `SA4tmpres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA4tmp', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA4tmpres'
        save `SA4tmpres', replace
    }
}

use `SA4tmpres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title(" ", size(`t_title')) ///
    `axes_sa4' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty" 2 "Gross – Medium novelty" 3 "Gross – Low novelty" ///
                 4 "Net – High novelty"   5 "Net – Medium novelty"   6 "Net – Low novelty") ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(SA4_panel, replace)
graph save SA4_adme_score_adjusted.gph, replace

* For this sensitivity we only have one panel; just export directly
graph save `OUTGPH_SA4', replace
graph export `OUTPNG_SA4', width(`W') height(`H_SA4') replace
di as res "SA4 (ADME sensitivity) -> `OUTPNG_SA4'"


*******************************************************
*******************************************************
* SENSITIVITY ANALYSIS 6: No exclusivity restriction
*******************************************************
*******************************************************

local OUTPNG_SA6 "final_adjusted_noexclusivity.png"
local OUTGPH_SA6 "final_adjusted_noexclusivity.gph"

local axes_sa6  xtitle("Year", size(`t_label')) ///
                ytitle("Adjusted Mean Revenue (Million $)", size(`t_label')) ///
                xlabel(2000(5)2020, labsize(`t_ticks')) ///
                ylabel(, labsize(`t_ticks')) ///
                xscale(range(2000 2020) noextend)

*******************************************************
* SA6 Panel A — Molecular Structure
*******************************************************
tempfile SA6tmpA SA6tmpAres
use revenue_GTN.dta, clear
capture drop score_group0 year0 cohort_year

keep if marketingcategoryname == "NDA" & inrange(year, 2000, 2019)
drop if chemical_score == . | total_paid == .

gen score_group0 = 1 if chemical_score <= $chemical_c1
replace score_group0 = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group0 = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA6tmpA', replace
cap erase `SA6tmpAres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA6tmpA', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA6tmpAres'
        save `SA6tmpAres', replace
    }
}

use `SA6tmpAres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_sa6' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty" 2 "Gross – Medium novelty" 3 "Gross – Low novelty" ///
                 4 "Net – High novelty"   5 "Net – Medium novelty"   6 "Net – Low novelty") ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(SA6_panelA, replace)
graph save SA6_chemical_score_adjusted.gph, replace

*******************************************************
* SA6 Panel B — Therapeutic Target
*******************************************************
tempfile SA6tmpB SA6tmpBres
use revenue_GTN.dta, clear
capture drop score_group0 cohort_year year0

keep if marketingcategoryname == "NDA" & inrange(year, 2000, 2019)
drop if target_score == . | total_paid == .

gen score_group0 = 1 if target_score <= $target_c1
replace score_group0 = 2 if target_score > $target_c1 & target_score <= $target_c2
replace score_group0 = 3 if target_score > $target_c2 & target_score <= 1000

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA6tmpB', replace
cap erase `SA6tmpBres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA6tmpB', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA6tmpBres'
        save `SA6tmpBres', replace
    }
}

use `SA6tmpBres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_sa6' `flat' `whitebg' legend(off) ///
    name(SA6_panelB, replace)
graph save SA6_target_score_adjusted.gph, replace

*******************************************************
* SA6 Panel C — Delivery Properties (ADME)
*******************************************************
tempfile SA6tmpC SA6tmpCres
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA" & inrange(year, 2000, 2019)
drop if ADME_score == . | total_paid == .

capture drop score_group0 cohort_year year0

gen score_group0 = 1 if ADME_score <= $ADME_c1
replace score_group0 = 2 if ADME_score > $ADME_c1 & ADME_score <= $ADME_c2
replace score_group0 = 3 if ADME_score > $ADME_c2 & ADME_score <= 1

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA6tmpC', replace
cap erase `SA6tmpCres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `SA6tmpC', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA6tmpCres'
        save `SA6tmpCres', replace
    }
}

use `SA6tmpCres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_sa6' `flat' `whitebg' legend(off) ///
    name(SA6_panelC, replace)
graph save SA6_adme_score_adjusted.gph, replace

*******************************************************
* SA6 Combine 3×1
*******************************************************
grc1leg2 ///
    SA6_chemical_score_adjusted.gph ///
    SA6_target_score_adjusted.gph   ///
    SA6_adme_score_adjusted.gph,    ///
    cols(1) rows(3)                     ///
    legendfrom(SA6_chemical_score_adjusted.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(SA6_all_panels, replace)

graph save `OUTGPH_SA6', replace
graph export `OUTPNG_SA6', width(`W') height(`H') replace
di as res "SA6 (no exclusivity) -> `OUTPNG_SA6'"


****************************************************************************
****************************************************************************
* SENSITIVITY ANALYSIS 7: Common drugs in MEPS and SSR
****************************************************************************
****************************************************************************

local OUTPNG_SA7 "all_panels_adjusted_commondrugs.png"
local OUTGPH_SA7 "all_panels_adjusted_commondrugs.gph"

local axes_sa7  xtitle("Year", size(`t_label')) ///
                ytitle("Adjusted Mean Revenue (Million $)", size(`t_label')) ///
                xlabel(2005(5)2020, labsize(`t_ticks')) ///
                ylabel(, labsize(`t_ticks')) ///
                xscale(range(2005 2020) noextend)

*******************************************************
* SA7 Panel A — Molecular Structure
*******************************************************
tempfile SA7tmpA SA7tmpAres
use revenue_GTN.dta, clear
capture drop score_group0 year0 cohort_year

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1
drop if chemical_score == . | total_paid == .

gen cohort_year = year - year_since_launch
gen year0       = year - 2000
keep if observed_discount == 1

xtile score_group0 = chemical_score, n(3)

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA7tmpA', replace
cap erase `SA7tmpAres'

forvalues y = 7/19 {
    forvalues g = 1/3 {
        use `SA7tmpA', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA7tmpAres'
        save `SA7tmpAres', replace
    }
}

use `SA7tmpAres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_sa7' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty" 2 "Gross – Low novelty" ///
                 3 "Net – High novelty"   4 "Net – Low novelty") ///
           cols(2) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(SA7_panelA, replace)
graph save SA7_chemical_score_adjusted.gph, replace

*******************************************************
* SA7 Panel B — Therapeutic Target
*******************************************************
tempfile SA7tmpB SA7tmpBres
use revenue_GTN.dta, clear
capture drop score_group0 cohort_year year0

keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if target_score == . | total_paid == .

gen cohort_year = year - year_since_launch
gen year0       = year - 2000
keep if observed_discount == 1

xtile score_group0 = target_score, n(2)

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA7tmpB', replace
cap erase `SA7tmpBres'

forvalues y = 7/19 {
    forvalues g = 1/2 {
        use `SA7tmpB', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA7tmpBres'
        save `SA7tmpBres', replace
    }
}

use `SA7tmpBres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_sa7' `flat' `whitebg' legend(off) ///
    name(SA7_panelB, replace)
graph save SA7_target_score_adjusted.gph, replace

*******************************************************
* SA7 Panel C — Delivery Properties (ADME)
*******************************************************
tempfile SA7tmpC SA7tmpCres
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA" ///
     & inrange(year, 2000, 2019) ///
     & year <= exclu_year1 & exclu_year1 != .
drop if ADME_score == . | total_paid == .

capture drop score_group0 cohort_year year0

gen cohort_year = year - year_since_launch
gen year0       = year - 2000
keep if observed_discount == 1

xtile score_group0 = ADME_score, n(2)

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `SA7tmpC', replace
cap erase `SA7tmpCres'

forvalues y = 7/19 {
    forvalues g = 1/2 {
        use `SA7tmpC', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `SA7tmpCres'
        save `SA7tmpCres', replace
    }
}

use `SA7tmpCres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_sa7' `flat' `whitebg' legend(off) ///
    name(SA7_panelC, replace)
graph save SA7_adme_score_adjusted.gph, replace

*******************************************************
* SA7 Combine 3×1
*******************************************************
grc1leg2 ///
    SA7_chemical_score_adjusted.gph ///
    SA7_target_score_adjusted.gph   ///
    SA7_adme_score_adjusted.gph,    ///
    cols(1) rows(3)                     ///
    legendfrom(SA7_chemical_score_adjusted.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(SA7_all_panels, replace)

graph save `OUTGPH_SA7', replace
graph export `OUTPNG_SA7', width(`W') height(`H') replace
di as res "SA7 (common drugs) -> `OUTPNG_SA7'"


*******************************************************
* END OF FILE
*******************************************************
