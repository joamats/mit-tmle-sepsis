* TMLE MIMC and eICU Sepsis Project 
* Stata code for box plots of TMLE and LTMLE results

*** TMLE results 
* Get data from csv files


import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/TMLE_combined.csv", clear // substitute with your local data path
destring, replace ignore("NA" "%")
rename (psi auc) (ATE AUC)

* set missing values to 0 for nice plotting
recode ATE  AUC (. = 0)  
recode lci (. = -0.000001)
recode uci (. = 0.000001) 

replace treatment = "Pressor" if treatment == "pressor"
replace treatment = "Ventilation" if treatment == "ventilation_bin"
replace treatment = "RRT" if treatment == "rrt"
gen name = cohort+" "+treatment

gen sofa_group = "0-5" if sofa_start == 0
replace sofa_group = "6-10" if sofa_start == 6
replace sofa_group = "11-15" if sofa_start == 11
replace sofa_group = ">15" if sofa_start == 16

sort treatment  sofa_start cohort

meta set ATE lci uci, studylabel(cohort) civarlevel(95) civartolerance(10) level(95)

	meta forestplot _id sofa_group _plot _esci, scheme(s2color) subgroup(treatment)  ///
	nooverall nonotes noohetstats noohomtest noosigtest ///
	noghetstats nogwhomtests nogsigtests nogbhomtests nogmarkers ///
	xline(0, lcolor(black) lwidth(thin) lpattern(dash)) name(forestplot_TMLE, replace) saving(forestplot_TMLE.jpg, replace) ///
	columnopts(_id, title("Cohort and Intervention") ) 	columnopts(sofa_group, title("SOFA Group") )   ///
	xlabel(-40 (20) 40) ///
	columnopts(_esci, supertitle("") title("ATE (95% CI)") format(%6.2f) ) cibind(parentheses) ///
	markeropts( msymbol(o) msize( medium) ) ciopts(recast(rcap)) 
	
	

	



	fixed(ivariance)
	tau2(0) 


cd  "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/log_reg/" // substitute with your local results path
