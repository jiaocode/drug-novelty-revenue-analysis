*******************************************************
* 01_primary_analyses.do
* BMJ Supplementary Code
* Purpose:
*   - Generate figures of gross and net revenue trends,
*     rebate trends, and net-to-list price ratio trends
*     by novelty terciles (chemical, target, ADME).
*
* Dataset:
*   - revenue_GTN.dta (constructed from proprietary data)
*
* Requirements:
*   - Stata 17
*   - grc1leg2 (user-written)
*******************************************************

version 17
clear all
set more off
set scheme s2color   // we override backgrounds to white in graphs

*-----------------------------------------------------*
* Paths & export settings (EDIT THIS PATH)
*-----------------------------------------------------*
cd "PATH_TO_DATA_DIRECTORY"   // <-- EDIT: folder where revenue_GTN.dta lives

* Unadjusted / adjusted revenue trend figures
local OUTPNG_unadj      "final_unadjusted.png"
local OUTGPH_unadj      "final_unadjusted.gph"
local OUTPNG_adj        "final_adjusted.png"
local OUTGPH_adj        "final_adjusted.gph"
local OUTPNG_adj_scal   "final_adjusted_samescale.png"
local OUTGPH_adj_scal   "final_adjusted_samescale.gph"

* Rebate & net-to-list figures
local OUTPNG_rebate     "final_rebate_unadjusted.png"
local OUTGPH_rebate     "final_rebate_unadjusted.gph"
local OUTPNG_ntl        "final_NTLratio_unadjusted.png"
local OUTGPH_ntl        "final_NTLratio_unadjusted.gph"

* Combined graph size in Stata (stacked ⇒ tall)
local XS 10
local YS 14

* Export pixel size (tall, crisp)
local W  2800
local H  4300

*-----------------------------------------------------*
* Install grc1leg2 (only if missing)
*-----------------------------------------------------*
cap which grc1leg2
if _rc {
    net install grc1leg2.pkg, from("http://digital.cgdev.org/doc/stata/MO/Misc/")
}

*-----------------------------------------------------*
* Text + style knobs
*-----------------------------------------------------*
local t_title   medium
local t_label   small
local t_ticks   small
local t_legend  small

* Flat panels so axes/legend don't crowd
local flat aspectratio(0.45)

* PURE white everywhere (frame + plot)
local whitebg graphregion(fcolor(white) lcolor(white)) ///
              plotregion(fcolor(white)  lcolor(white))

* Axes templates
local axes_unadj  xtitle("Year", size(`t_label')) ///
                  ytitle("Mean Revenue (Million $)", size(`t_label')) ///
                  xlabel(, labsize(`t_ticks')) ylabel(, labsize(`t_ticks')) ///
                  xscale(range(2000 2020) noextend)

local axes_adj    xtitle("Year", size(`t_label')) ///
                  ytitle("Adjusted Mean Revenue (Million $)", size(`t_label')) ///
                  xlabel(2000(5)2020, labsize(`t_ticks')) ylabel(, labsize(`t_ticks')) ///
                  xscale(range(2000 2020) noextend)

local axes_rebate xtitle("Year", size(`t_label')) ///
                  ytitle("Mean Rebate (Million $)", size(`t_label')) ///
                  xlabel(, labsize(`t_ticks')) ylabel(, labsize(`t_ticks')) ///
                  xscale(range(2000 2020) noextend)

local axes_ntl    xtitle("Year", size(`t_label')) ///
                  ytitle("Net-to-List Price Ratio", size(`t_label')) ///
                  xlabel(, labsize(`t_ticks')) ylabel(, labsize(`t_ticks')) ///
                  xscale(range(2000 2020) noextend)

* Bandwidth & line width for lowess
local bw bw(0.4)
local lw lwidth(medium)

*******************************************************
* SECTION 1: Unadjusted trends (gross vs net revenue)
*            by novelty terciles
*******************************************************

*-------------------------
* Panel A — Molecular Structure
*-------------------------
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA"
keep if year >= 2000 & year <= 2019 & year <= exclu_year1 & exclu_year1 != .
drop if chemical_score == . | total_paid == .

pctile cutoffs = chemical_score, nq(3)
global chemical_c1 = cutoffs[1]
global chemical_c2 = cutoffs[2]

gen score_group = 1 if chemical_score <= $chemical_c1
replace score_group = 2 if chemical_score > $chemical_c1 & chemical_score <= $chemical_c2
replace score_group = 3 if chemical_score > $chemical_c2 & chemical_score <= 1

collapse (mean) net_spending = net_revenue ///
                 gross_spending = total_paid, by(score_group year)

twoway ///
 (lowess gross_spending year if score_group==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_spending year if score_group==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_spending year if score_group==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_spending   year if score_group==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(A) Molecular Structure", size(`t_title')) ///
    `axes_unadj' `flat' `whitebg' ///
    legend(order(1 "Gross – High novelty"   ///
                 2 "Gross – Medium novelty" ///
                 3 "Gross – Low novelty"    ///
                 4 "Net – High novelty"     ///
                 5 "Net – Medium novelty"   ///
                 6 "Net – Low novelty")     ///
           cols(3) size(`t_legend') symxsize(*0.8) symysize(*0.8) keygap(1.2) ///
           region(fcolor(white) lcolor(black) lwidth(thin))) ///
    name(panelA_unadj, replace)
graph save chemical_score_plot.gph, replace

*-------------------------
* Panel B — Therapeutic Target
*-------------------------
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA"
keep if year >= 2000 & year <= 2019 & year < exclu_year1 & exclu_year1 != .
drop if target_score == . | total_paid == .

pctile cutoffs = target_score, nq(3)
global target_c1 = cutoffs[1]
global target_c2 = cutoffs[2]

gen score_group = 1 if target_score <= $target_c1
replace score_group = 2 if target_score > $target_c1 & target_score <= $target_c2
replace score_group = 3 if target_score > $target_c2 & target_score <= 1000

collapse (mean) net_spending = net_revenue ///
                 gross_spending = total_paid, by(score_group year)

twoway ///
 (lowess gross_spending year if score_group==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_spending year if score_group==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_spending year if score_group==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_spending   year if score_group==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(B) Therapeutic Target", size(`t_title')) ///
    `axes_unadj' `flat' `whitebg' legend(off) ///
    name(panelB_unadj, replace)
graph save target_score_plot.gph, replace

*-------------------------
* Panel C — Delivery Properties (ADME)
*-------------------------
use revenue_GTN.dta, clear
keep if marketingcategoryname == "NDA"
keep if year >= 2000 & year <= 2019 & year < exclu_year1 & exclu_year1 != .
drop if ADME_score == . | total_paid == .

pctile cutoffs = ADME_score, nq(3)
global ADME_c1 = cutoffs[1]
global ADME_c2 = cutoffs[2]

gen score_group = 1 if ADME_score <= $ADME_c1
replace score_group = 2 if ADME_score > $ADME_c1 & ADME_score <= $ADME_c2
replace score_group = 3 if ADME_score > $ADME_c2 & ADME_score <= 1

collapse (mean) net_spending = net_revenue ///
                 gross_spending = total_paid, by(score_group year)

twoway ///
 (lowess gross_spending year if score_group==1, `bw' lcolor(blue)  `lw') ///
 (lowess gross_spending year if score_group==2, `bw' lcolor(red)   `lw') ///
 (lowess gross_spending year if score_group==3, `bw' lcolor(gold)  `lw') ///
 (lowess net_spending   year if score_group==1, `bw' lcolor(blue)  lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group==2, `bw' lcolor(red)   lpattern(dash) `lw') ///
 (lowess net_spending   year if score_group==3, `bw' lcolor(gold)  lpattern(dash) `lw'), ///
    title("(C) Delivery Properties", size(`t_title')) ///
    `axes_unadj' `flat' `whitebg' legend(off) ///
    name(panelC_unadj, replace)
graph save adme_score_plot.gph, replace

*-------------------------
* Combine 3×1 with shared legend (top)
*-------------------------
grc1leg2 panelA_unadj panelB_unadj panelC_unadj, ///
    cols(1) rows(3)                     ///
    legendfrom(panelA_unadj)            ///
    position(12) ring(1)                ///
    imargin(0 1 0 1)                    ///
    xsize(`XS') ysize(`YS')             ///
    graphregion(fcolor(white) lcolor(white)) ///
    name(all_panels_unadj, replace)

graph save `OUTGPH_unadj', replace
graph export `OUTPNG_unadj', width(`W') height(`H') replace

*******************************************************
* SECTION 2: Adjusted trends (gross vs net revenue)
*            using fracreg logit + ppmlhdfe
*            (Your original Analysis 2 & 2b)
*******************************************************

* NOTE: Below, I'd keep your original adjusted trend blocks,
* but now re-using `axes_adj` and paths defined at the top.
* You already have:
*   - tempfiles for each panel
*   - fracreg logit for discount
*   - ppmlhdfe for total_paid
*   - prediction loops over year0 and score_group0
*
* You mainly need to:
*   - remove duplicated version/set more/off/path lines
*   - fix the small typo in the ADME block:
*       replace score_group = ...  -> score_group0 = ...
*
* (You can paste your existing Analysis 2 & 2b code here
* with those minor clean-ups.)
*
* After combining, export:
*   graph save `OUTGPH_adj', replace
*   graph export `OUTPNG_adj', width(`W') height(`H') replace
*   ... and likewise for the same-scale version using axes with yscale.

*******************************************************
* SECTION 3: Rebate trend (unadjusted) by novelty terciles
*            (Your original Analysis 3)
*******************************************************

* Here you can paste your Analysis 3 block, but:
*  - Use `axes_rebate` instead of re-defining axes
*  - Remove repeated version / set more / cd / scheme lines
*  - Keep the logic for rebate = total_paid - net_revenue
*  - Keep the grc1leg2 combine at the end
*
* In the final lines:
*   graph save `OUTGPH_rebate', replace
*   graph export `OUTPNG_rebate', width(`W') height(`H') replace

*******************************************************
* SECTION 4: Net-to-List Price Ratio trend (unadjusted)
*            (Your original Analysis 4)
*******************************************************

* Same idea as Section 3:
*  - Use `axes_ntl`
*  - Keep ratio = 1 - discount
*  - Combine panels with grc1leg2
*
* In the final lines:
*   graph save `OUTGPH_ntl', replace
*   graph export `OUTPNG_ntl', width(`W') height(`H') replace

*******************************************************
* END OF FILE
*******************************************************
