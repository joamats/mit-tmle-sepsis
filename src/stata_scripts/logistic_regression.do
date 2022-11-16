
* TMLE MIMC and eICU Sepsis Project 
* Stata code for logistic regression only

* Import MIMIC data from csv file
import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/data/MIMIC_data_stata.csv", clear // substitute with your local path

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
logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor // across all sofa groups
logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor if sofa_group == 1 // sofa 0-5
logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor if sofa_group == 2 // sofa 6-10
logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor if sofa_group == 3 // sofa 11-15
logistic ventilation_bin ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt pressor if sofa_group == 4 // sofa >15

* LogReg on race and renal replacement therapy
logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor // across all sofa groups
logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor if sofa_group == 1 // sofa 0-5
logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor if sofa_group == 2 // sofa 6-10
logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor if sofa_group == 3 // sofa 11-15
logistic rrt ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin pressor if sofa_group == 4 // sofa >15

* LogReg on race and vasopressors
logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt // across all sofa groups
logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt if sofa_group == 1 // sofa 0-5
logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt if sofa_group == 2 // sofa 6-10
logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt if sofa_group == 3 // sofa 11-15
logistic pressor ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index ventilation_bin rrt if sofa_group == 4 // sofa >15

* Import eICU data from csv file
import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/data/eICU_data_stata.csv", clear // substitute with your local path

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
logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final // across all sofa groups
logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final if sofa_group == 1 // sofa 0-5
logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final if sofa_group == 2 // sofa 6-10
logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final if sofa_group == 3 // sofa 11-15
logistic vent_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index rrt_final pressor_final if sofa_group == 4 // sofa >15

* LogReg on race and renal replacement therapy
logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final // across all sofa groups
logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final if sofa_group == 1 // sofa 0-5
logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final if sofa_group == 2 // sofa 6-10
logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final if sofa_group == 3 // sofa 11-15
logistic rrt_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final pressor_final if sofa_group == 4 // sofa >15

* LogReg on race and vasopressors
logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final // across all sofa groups
logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final if sofa_group == 1 // sofa 0-5
logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final if sofa_group == 2 // sofa 6-10
logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final if sofa_group == 3 // sofa 11-15
capture: logistic pressor_final ethnicity_white anchor_age female i.anchor_year sofa i.charlson_comorbidity_index vent_final rrt_final if sofa_group == 4 // sofa >15
// Warning: no outcomes pressor_final == 0 in sofa_group >15



