* TMLE MIMC and eICU Sepsis Project 
* Stata code for box plots of TMLE and LTMLE results

*** TMLE results 
* Get data from csv files

cd "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/Paper" // substitute with your local data path

import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/TMLE.csv", clear // substitute with your local data path
destring, replace ignore("NA" "%")
rename (psi auc) (ATE AUC)

* set missing values to 0 for nice plotting
recode ATE  AUC (. = 0)  
recode i_ci  (0 = -0.000001) if cohort == "eICU" & sofa_end == 100
recode s_ci (0 = 0.000001) if cohort == "eICU" & sofa_end == 100

* rescale results to percentages
replace ATE =  ATE*100
replace i_ci  = i_ci*100
replace s_ci = s_ci*100

replace treatment = "Pressor" if treatment == "pressor"
replace treatment = "Ventilation" if treatment == "ventilation_bin"
replace treatment = "RRT" if treatment == "rrt"
gen name = cohort+" "+treatment

gen sofa_group = "0-5" if sofa_start == 0
replace sofa_group = "6-10" if sofa_start == 6
replace sofa_group = "11-15" if sofa_start == 11
replace sofa_group = ">15" if sofa_start == 16

sort treatment  sofa_start cohort

meta set ATE i_ci s_ci, studylabel(cohort) civarlevel(95) civartolerance(10) level(95)

	meta forestplot _id sofa_group _plot _esci, scheme(s2color) subgroup(treatment)  ///
	nooverall nonotes noohetstats noohomtest noosigtest ///
	noghetstats nogwhomtests nogsigtests nogbhomtests nogmarkers ///
	xline(0, lcolor(black) lwidth(thin) lpattern(dash)) name(forestplot_TMLE, replace) saving(forestplot_TMLE.jpg, replace) ///
	columnopts(_id, title("Cohort and Intervention") ) 	columnopts(sofa_group, title("SOFA Group") )   ///
	xlabel(-40 (20) 40) ///
	columnopts(_esci, supertitle("") title("ATE (95% CI)") format(%6.2f) ) cibind(parentheses) ///
	markeropts( msymbol(o) msize( medium) ) ciopts(recast(rcap)) 
