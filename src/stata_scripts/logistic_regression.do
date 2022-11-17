
* TMLE MIMC and eICU Sepsis Project 
* Stata code for logistic regression only

* Import MIMIC data from csv file
import delimited "***/mit-tmle/data/MIMIC_data_stata.csv", clear // substitute with your local data path
cd  "***/mit-tmle/results/log_reg/" // substitute with your local results path

* Transform variables for Stata
rename gender female

gen dummy = 1 if anchor_year_group ==  "2008 - 2010"
replace dummy = 2 if anchor_year_group == "2011 - 2013"
replace dummy = 3 if anchor_year_group == "2014 - 2016"
replace dummy = 4 if anchor_year_group == "2017 - 2019"
drop anchor_year_group
rename dummy anchor_year

rename charlson_comorbidity_index charlson
gen charlson_comorbidity_index = 1 if charlson ==  "0 - 5"
replace charlson_comorbidity_index = 2 if charlson == "6 - 10"
replace charlson_comorbidity_index = 3 if charlson ==  "11 - 15"
replace charlson_comorbidity_index = 4 if charlson == "16 and above"
drop charlson

gen sofa_group = 1 if sofa <=5
replace sofa_group = 2 if sofa <=10 & sofa >=6
replace sofa_group = 3 if sofa <=15 & sofa >=11
replace sofa_group = 4 if sofa >15 & sofa !=.

* LogReg on race and ventilation
putexcel set log_reg_results, replace sheet(MIMIC, replace)
putexcel A1="SOFA" B1="OR" C1="OR lCI" D1="OR uCI" E1="p-value"

    logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor
    matrix res= r(table)
    putexcel A2=("Ventilation all") B2=res[1,1] C2=res[5,1] D2=res[6,1] E2=res[4,1]

local row=3
forval i=1/4  {          
        
    logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor if sofa_group == `i' // repeform logistic across all sofa groups, then groups 1-4
	matrix res= r(table)
	putexcel A`row'=("`i'") B`row'=res[1,1] C`row'=res[5,1] D`row'=res[6,1] E`row'=res[4,1]
	local row=`row'+1

	}
	
* LogReg on race and renal replacement therapy

    logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor // across all sofa groups
    matrix res= r(table)
    putexcel A7=("RRT all") B7=res[1,1] C7=res[5,1] D7=res[6,1] E7=res[4,1]

local row=8
forval i=1/4  {          
        
    logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor if sofa_group == `i' // repeform logistic across all sofa groups, then groups 1-4
	matrix res= r(table)
	putexcel A`row'=("`i'") B`row'=res[1,1] C`row'=res[5,1] D`row'=res[6,1] E`row'=res[4,1]
	local row=`row'+1

	}

* LogReg on race and vasopressors

    logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt // repeform logistic across all sofa groups, then groups 1-4
    matrix res= r(table)
    putexcel A12=("vasopressor all") B12=res[1,1] C12=res[5,1] D12=res[6,1] E12=res[4,1]

local row=13
forval i=1/4  {          
        
   logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt if sofa_group == `i' // repeform logistic across all sofa groups, then groups 1-4
	matrix res= r(table)
	putexcel A`row'=("`i'") B`row'=res[1,1] C`row'=res[5,1] D`row'=res[6,1] E`row'=res[4,1]
	local row=`row'+1

	}


* Import eICU data from csv file
import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/data/eICU_data_stata.csv", clear // substitute with your local data path
cd  "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/log_reg/" // substitute with your local results path

* Replace NaN/missings in treatments with 0
destring rrt_final vent_final pressor_final, replace ignore("NA")
recode rrt_final vent_final pressor_final (. = 0) (. = 0) (. = 0)

* Transform variables for Stata
rename gender female

drop charlson
rename charlson_comorbidity_index charlson
gen charlson_comorbidity_index = 1 if charlson ==  "0 - 5"
replace charlson_comorbidity_index = 2 if charlson == "6 - 10"
replace charlson_comorbidity_index = 3 if charlson ==  "11 - 15"
replace charlson_comorbidity_index = 4 if charlson == "16 and above"
drop charlson

destring sofa, replace ignore("NA")
gen sofa_group = 1 if sofa <=5
replace sofa_group = 2 if sofa <=10 & sofa >=6
replace sofa_group = 3 if sofa <=15 & sofa >=11
replace sofa_group = 4 if sofa >15 & sofa !=.


* LogReg on race and ventilation
putexcel set log_reg_results, modify sheet(eICU, replace)
putexcel A1="SOFA" B1="OR" C1="OR lCI" D1="OR uCI" E1="p-value"

    logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final // across all sofa groups
    matrix res= r(table)
    putexcel A2=("Ventilation all") B2=res[1,1] C2=res[5,1] D2=res[6,1] E2=res[4,1]

local row=3
forval i=1/4  {          
        
    logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final if sofa_group == `i' // repeform logistic across all sofa groups, then groups 1-4
	matrix res= r(table)
	putexcel A`row'=("`i'") B`row'=res[1,1] C`row'=res[5,1] D`row'=res[6,1] E`row'=res[4,1]
	local row=`row'+1

	}
	
* LogReg on race and renal replacement therapy

    logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final // across all sofa groups
    matrix res= r(table)
    putexcel A7=("RRT all") B7=res[1,1] C7=res[5,1] D7=res[6,1] E7=res[4,1]

local row=8
forval i=1/4  {          
        
    logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final if sofa_group == `i' // repeform logistic across all sofa groups, then groups 1-4
	matrix res= r(table)
	putexcel A`row'=("`i'") B`row'=res[1,1] C`row'=res[5,1] D`row'=res[6,1] E`row'=res[4,1]
	local row=`row'+1

	}

* LogReg on race and vasopressors

    logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final // repeform logistic across all sofa groups, then groups 1-4
    matrix res= r(table)
    putexcel A12=("vasopressor all") B12=res[1,1] C12=res[5,1] D12=res[6,1] E12=res[4,1]

local row=13
forval i=1/4  {          
        
    capture: logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final if sofa_group == `i' // repeform logistic across all sofa groups, then groups 1-4
    matrix res= r(table)
	putexcel A`row'=("`i'") B`row'=res[1,1] C`row'=res[5,1] D`row'=res[6,1] E`row'=res[4,1]
	local row=`row'+1

	}

// Warning: no outcomes pressor_final == 0 in sofa_group >15



