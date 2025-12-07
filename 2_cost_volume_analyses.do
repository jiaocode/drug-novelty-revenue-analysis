*******************************************************
* 02_cost_volume_analyses.do
* BMJ Supplementary Code
*
* Purpose:
*      Generate:
*       - Adjusted mean spending per prescription (3×1 panels)
*       - Adjusted number of prescriptions (3×1 panels)
*       - Prescription market share (3×1 stacked area)
*******************************************************

version 17
clear all
set more off
set scheme s2color   // we override backgrounds to white per-graph


*******************************************************
* 0. User paths (EDIT THIS)
*******************************************************
local DATA_DIR "PATH_TO_DATA_DIRECTORY"   // e.g. "C:/Users/.../Pharmaproject/Data"
cd "`DATA_DIR'"


*******************************************************
*******************************************************
* ANALYSIS 1: Adjusted per-prescription cost trend
*             (3×1 panels by novelty terciles)
*******************************************************
*******************************************************
local OUTPNG_pp_cost "final_adjusted_perpatient.png"
local OUTGPH_pp_cost "final_adjusted_perpatient.gph"

* Combined graph size (stacked ⇒ tall)
local XS 10
local YS 14

* Export pixel size
local W  2800
local H  4300

* Text + style knobs
local t_title   medium
local t_label   small
local t_ticks   small
local t_legend  small
local t_axis    `t_label'   // used in some xtitle/ytitle calls

* Flat panels so axes/legend don't crowd
local flat aspectratio(0.45)

* PURE white everywhere (frame + plot)
local whitebg graphregion(fcolor(white) lcolor(white)) ///
              plotregion(fcolor(white)  lcolor(white))

* Axes template for per-prescription spending
local axes_pp_cost  xtitle("Year", size(`t_label')) ///
                    ytitle("Mean Spending per Prescription ($)", size(`t_label')) ///
                    xlabel(2000(5)2020, labsize(`t_ticks')) ylabel(, labsize(`t_ticks')) ///
                    xscale(range(2000 2020) noextend)

local bw bw(0.4)
local lw lwidth(medium)

*******************************************************
* Panel A — Molecular Structure
*******************************************************
tempfile tmpA tmpAres
use revenue_GTN_perpatient.dta, clear

keep if marketingcategoryname == "NDA" ///
    & inrange(year, 2000, 2019) ///
    & year <= exclu_year1 & exclu_year1 != .
drop if chemical_score == . | total_paid == .
capture drop score_group0 cohort_year year0

gen score_group0 = 1 if chemical_score <= $chemical_c1
replace score_group0 = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group0 = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `tmpA', replace
cap erase `tmpAres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `tmpA', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `tmpAres'
        save `tmpAres', replace
    }
}

use `tmpAres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_pp_cost' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty" 2 "Gross – Medium novelty" 3 "Gross – Low novelty" ///
                 4 "Net – High novelty"   5 "Net – Medium novelty"   6 "Net – Low novelty") ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(panelA_ppcost, replace)
graph save chemical_score_ppcost.gph, replace

*******************************************************
* Panel B — Therapeutic Target (legend OFF)
*******************************************************
tempfile tmpB tmpBres
use revenue_GTN_perpatient.dta, clear
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

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `tmpB', replace
cap erase `tmpBres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `tmpB', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `tmpBres'
        save `tmpBres', replace
    }
}

use `tmpBres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_pp_cost' `flat' `whitebg' legend(off) ///
    name(panelB_ppcost, replace)
graph save target_score_ppcost.gph, replace

*******************************************************
* Panel C — Delivery Properties (ADME) (legend OFF)
*   (typo fixed: score_group0 everywhere)
*******************************************************
tempfile tmpC tmpCres
use revenue_GTN_perpatient.dta, clear

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

fracreg logit discount i.score_group0##i.year0 i.class_num i.cohort_year
est store Net1

ppmlhdfe total_paid i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `tmpC', replace
cap erase `tmpCres'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `tmpC', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Net1
        predict net_hat

        estimates restore Gross1
        predict gross_hat, mu

        replace net_hat = gross_hat * (1 - net_hat)

        collapse (mean) net_hat gross_hat, by(score_group0 year0)

        capture append using `tmpCres'
        save `tmpCres', replace
    }
}

use `tmpCres', clear
gen year = year0 + 2000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_hat   year if score_group0==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_hat   year if score_group0==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_pp_cost' `flat' `whitebg' legend(off) ///
    name(panelC_ppcost, replace)
graph save adme_score_ppcost.gph, replace

*******************************************************
* Combine 3×1 with ONE shared legend ON TOP (outside)
*******************************************************
grc1leg2 ///
    chemical_score_ppcost.gph ///
    target_score_ppcost.gph   ///
    adme_score_ppcost.gph,    ///
    cols(1) rows(3)                     ///
    legendfrom(chemical_score_ppcost.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(all_panels_ppcost, replace)

graph save `OUTGPH_pp_cost', replace
graph export `OUTPNG_pp_cost', width(`W') height(`H') replace
di as res "Per-prescription cost figure -> `OUTPNG_pp_cost'"

*******************************************************
*******************************************************
* ANALYSIS 2: Adjusted number of prescriptions
*             (3×1, millions)
*******************************************************
*******************************************************

local OUTPNG_pp_count "final_adjusted_prescription.png"
local OUTGPH_pp_count "final_adjusted_prescription.gph"

* Axes template for prescription counts
local axes_pp_count  xtitle("Year", size(`t_label')) ///
                     ytitle("Adjusted Mean Prescriptions (Million)", size(`t_label')) ///
                     xlabel(2000(5)2020, labsize(`t_ticks')) ylabel(, labsize(`t_ticks')) ///
                     xscale(range(2000 2020) noextend)

*******************************************************
* Panel A — Molecular Structure
*******************************************************
tempfile tmpA2 tmpA2res
use revenue_GTN_perpatient.dta, clear

keep if marketingcategoryname == "NDA" ///
    & inrange(year, 2000, 2019) ///
    & year <= exclu_year1 & exclu_year1 != .
drop if chemical_score == . | total_paid == .
capture drop score_group0 cohort_year year0

gen score_group0 = 1 if chemical_score <= $chemical_c1
replace score_group0 = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group0 = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

gen cohort_year = year - year_since_launch
gen year0       = year - 2000

quietly ppmlhdfe n_p i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `tmpA2', replace
cap erase `tmpA2res'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `tmpA2', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Gross1
        predict gross_hat, mu

        collapse (mean) gross_hat, by(score_group0 year0)

        capture append using `tmpA2res'
        save `tmpA2res', replace
    }
}

use `tmpA2res', clear
gen year = year0 + 2000
replace gross_hat = gross_hat / 1_000_000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_pp_count' `flat' `whitebg' ///
    legend(order(1 "High novelty" 2 "Medium novelty" 3 "Low novelty") ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(panelA_ppcount, replace)
graph save chemical_score_ppcount.gph, replace

*******************************************************
* Panel B — Therapeutic Target (legend OFF)
*******************************************************
tempfile tmpB2 tmpB2res
use revenue_GTN_perpatient.dta, clear
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

quietly ppmlhdfe n_p i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `tmpB2', replace
cap erase `tmpB2res'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `tmpB2', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Gross1
        predict gross_hat, mu

        collapse (mean) gross_hat, by(score_group0 year0)

        capture append using `tmpB2res'
        save `tmpB2res', replace
    }
}

use `tmpB2res', clear
gen year = year0 + 2000
replace gross_hat = gross_hat / 1_000_000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_pp_count' `flat' `whitebg' legend(off) ///
    name(panelB_ppcount, replace)
graph save target_score_ppcount.gph, replace

*******************************************************
* Panel C — Delivery Properties (ADME) (legend OFF)
*******************************************************
tempfile tmpC2 tmpC2res
use revenue_GTN_perpatient.dta, clear

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

quietly ppmlhdfe n_p i.score_group0##i.year0 i.cohort_year, a(class) vce(cluster class) d
est store Gross1

save `tmpC2', replace
cap erase `tmpC2res'

forvalues y = 0/19 {
    forvalues g = 1/3 {
        use `tmpC2', clear
        replace score_group0 = `g'
        replace year0       = `y'

        estimates restore Gross1
        predict gross_hat, mu

        collapse (mean) gross_hat, by(score_group0 year0)

        capture append using `tmpC2res'
        save `tmpC2res', replace
    }
}

use `tmpC2res', clear
gen year = year0 + 2000
replace gross_hat = gross_hat / 1_000_000

twoway ///
 (lowess gross_hat year if score_group0==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_hat year if score_group0==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_hat year if score_group0==3, `bw' lcolor(gold)  `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_pp_count' `flat' `whitebg' legend(off) ///
    name(panelC_ppcount, replace)
graph save adme_score_ppcount.gph, replace

*******************************************************
* Combine 3×1 with ONE shared legend ON TOP (outside)
*******************************************************
grc1leg2 ///
    chemical_score_ppcount.gph ///
    target_score_ppcount.gph   ///
    adme_score_ppcount.gph,    ///
    cols(1) rows(3)                     ///
    legendfrom(chemical_score_ppcount.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(all_panels_ppcount, replace)

graph save `OUTGPH_pp_count', replace
graph export `OUTPNG_pp_count', width(`W') height(`H') replace
di as res "Prescription count figure -> `OUTPNG_pp_count'"

*******************************************************
*******************************************************
* ANALYSIS 3: Total prescriptions (market share, %)
*             (3×1 stacked area)
*******************************************************
*******************************************************

local OUTPNG_share "final_marketshare.png"
local OUTGPH_share "final_marketshare.gph"

*******************************************************
* Helper: stacked market-share panel by score_group0
*******************************************************
* We keep your original logic but fix score_group vs score_group0
* and t_axis usage (now defined at top via local t_axis `t_label').
*******************************************************

*------------- Panel A — Molecular Structure -------------
use revenue_GTN_perpatient.dta, clear
keep if marketingcategoryname == "NDA" ///
    & inrange(year, 2000, 2019) ///
    & year <= exclu_year1 & exclu_year1 != .
drop if chemical_score == . | total_paid == .

gen score_group0 = 1 if chemical_score <= $chemical_c1
replace score_group0 = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group0 = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

collapse (sum) n_p, by(year score_group0)
bysort year: egen total_p = total(n_p)
gen share     = n_p / total_p
gen share_pct = share * 100

tempvar n1 n2 n3
lowess share_pct year if score_group0==1, bw(0.4) gen(`n1')
lowess share_pct year if score_group0==2, bw(0.4) gen(`n2')
lowess share_pct year if score_group0==3, bw(0.4) gen(`n3')

collapse (mean) `n1' `n2' `n3', by(year)
sort year

gen cum_low  = `n3'
gen cum_med  = `n2' + `n3'
gen cum_high = `n1' + `n2' + `n3'
gen zero     = 0

twoway ///
    rarea zero     cum_low  year, color(gold) lcolor(gold) || ///
    rarea cum_low  cum_med  year, color(red)  lcolor(red)  || ///
    rarea cum_med  cum_high year, color(blue) lcolor(blue) || ///
    line  cum_high year, lcolor(blue) ||  ///
    line  cum_med  year, lcolor(red)  ||  ///
    line  cum_low  year, lcolor(gold),  ///
    title("(A) Molecular Structure", size(`t_title'))  ///
    xtitle("Year", size(`t_axis')) ///
    ytitle("Prescription market share (%)", size(`t_axis'))  ///
    graphregion(fcolor(white) lcolor(white))  ///
    plotregion(fcolor(white)  lcolor(white))  ///
    aspectratio(0.45) ///
    legend(order(3 "High novelty" 2 "Medium novelty" 1 "Low novelty")  ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2)  ///
           region(fcolor(white) lcolor(black) lwidth(thin)))  ///
    name(panelA_share, replace)
graph save chemical_score_share.gph, replace

*------------- Panel B — Therapeutic Target -------------
use revenue_GTN_perpatient.dta, clear
keep if marketingcategoryname == "NDA" ///
    & inrange(year, 2000, 2019) ///
    & year <= exclu_year1 & exclu_year1 != .
drop if target_score == . | total_paid == .

gen score_group0 = 1 if target_score <= $target_c1
replace score_group0 = 2 if target_score > $target_c1 & target_score <= $target_c2
replace score_group0 = 3 if target_score > $target_c2 & target_score <= 1000

collapse (sum) n_p, by(year score_group0)
bysort year: egen total_p = total(n_p)
gen share     = n_p / total_p
gen share_pct = share * 100

tempvar n1b n2b n3b
lowess share_pct year if score_group0==1, bw(0.4) gen(`n1b')
lowess share_pct year if score_group0==2, bw(0.4) gen(`n2b')
lowess share_pct year if score_group0==3, bw(0.4) gen(`n3b')

collapse (mean) `n1b' `n2b' `n3b', by(year)
sort year

gen cum_low  = `n3b'
gen cum_med  = `n2b' + `n3b'
gen cum_high = `n1b' + `n2b' + `n3b'
gen zero     = 0

twoway ///
    rarea zero     cum_low  year, color(gold) lcolor(gold) || ///
    rarea cum_low  cum_med  year, color(red)  lcolor(red)  || ///
    rarea cum_med  cum_high year, color(blue) lcolor(blue) || ///
    line  cum_high year, lcolor(blue) ||  ///
    line  cum_med  year, lcolor(red)  ||  ///
    line  cum_low  year, lcolor(gold),  ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    xtitle("Year", size(`t_axis')) ///
    ytitle("Prescription market share (%)", size(`t_axis'))  ///
    graphregion(fcolor(white) lcolor(white))  ///
    plotregion(fcolor(white)  lcolor(white))  ///
    aspectratio(0.45) ///
    legend(off)  ///
    name(panelB_share, replace)
graph save target_score_share.gph, replace

*------------- Panel C — Delivery Properties (ADME) -------------
use revenue_GTN_perpatient.dta, clear
keep if marketingcategoryname == "NDA" ///
    & inrange(year, 2000, 2019) ///
    & year <= exclu_year1 & exclu_year1 != .
drop if ADME_score == . | total_paid == .

gen score_group0 = 1 if ADME_score <= $ADME_c1
replace score_group0 = 2 if ADME_score > $ADME_c1 & ADME_score <= $ADME_c2
replace score_group0 = 3 if ADME_score > $ADME_c2 & ADME_score <= 1

collapse (sum) n_p, by(year score_group0)
bysort year: egen total_p = total(n_p)
gen share     = n_p / total_p
gen share_pct = share * 100

tempvar n1c n2c n3c
lowess share_pct year if score_group0==1, bw(0.4) gen(`n1c')
lowess share_pct year if score_group0==2, bw(0.4) gen(`n2c')
lowess share_pct year if score_group0==3, bw(0.4) gen(`n3c')

collapse (mean) `n1c' `n2c' `n3c', by(year)
sort year

gen cum_low  = `n3c'
gen cum_med  = `n2c' + `n3c'
gen cum_high = `n1c' + `n2c' + `n3c'
gen zero     = 0

twoway ///
    rarea zero     cum_low  year, color(gold) lcolor(gold) || ///
    rarea cum_low  cum_med  year, color(red)  lcolor(red)  || ///
    rarea cum_med  cum_high year, color(blue) lcolor(blue) || ///
    line  cum_high year, lcolor(blue) ||  ///
    line  cum_med  year, lcolor(red)  ||  ///
    line  cum_low  year, lcolor(gold),  ///
    title("(C) Delivery Properties", size(`t_title')) ///
    xtitle("Year", size(`t_axis')) ///
    ytitle("Prescription market share (%)", size(`t_axis'))  ///
    graphregion(fcolor(white) lcolor(white))  ///
    plotregion(fcolor(white)  lcolor(white))  ///
    aspectratio(0.45) ///
    legend(off)  ///
    name(panelC_share, replace)
graph save adme_score_share.gph, replace

*******************************************************
* Combine 3×1 with ONE shared legend ON TOP (outside)
*******************************************************
grc1leg2 ///
    chemical_score_share.gph ///
    target_score_share.gph   ///
    adme_score_share.gph,    ///
    cols(1) rows(3)                     ///
    legendfrom(chemical_score_share.gph) ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(all_panels_share, replace)

graph save `OUTGPH_share', replace
graph export `OUTPNG_share', width(`W') height(`H') replace
di as res "Market share figure -> `OUTPNG_share'"

*******************************************************
* END OF FILE
*******************************************************
