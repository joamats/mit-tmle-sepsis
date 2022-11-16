
* TMLE MIMC and eICU Sepsis Project 
* Stata code for logistic regression only

* Import MIMIC data from csv file
import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/data/MIMIC_data.csv", clear // substitute with your local path

* LogReg on race and ventilation
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor // across all SOFA groups
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 1 // SOFA 0-5
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 2 // SOFA 6-10
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 3 // SOFA 11-15
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 4 // SOFA >15

* LogReg on race and renal replacement therapy
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor // across all SOFA groups
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 1 // SOFA 0-5
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 2 // SOFA 6-10
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 3 // SOFA 11-15
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 4 // SOFA >15


* LogReg on race and vasopressors
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt // across all SOFA groups
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 1 // SOFA 0-5
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 2 // SOFA 6-10
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 3 // SOFA 11-15
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 4 // SOFA >15

* Import eICU data from csv file
import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/data/eICU_data.csv", clear // substitute with your local path

* Replace NaN/missings in treatments with 0
recode rrt_final vent_final pressor_final (. = 0) (. = 0) (. = 0)

* LogReg on race and ventilation
logistic vent_final white age female i.year SOFA i.CCIgroup rrt_final pressor_final // across all SOFA groups
logistic vent_final white age female i.year SOFA i.CCIgroup rrt_final pressor_final if SOFA group == 1 // SOFA 0-5
logistic vent_final white age female i.year SOFA i.CCIgroup rrt_final pressor_final if SOFA group == 2 // SOFA 6-10
logistic vent_final white age female i.year SOFA i.CCIgroup rrt_final pressor_final if SOFA group == 3 // SOFA 11-15
logistic vent_final white age female i.year SOFA i.CCIgroup rrt_final pressor_final if SOFA group == 4 // SOFA >15

* LogReg on race and renal replacement therapy
logistic rrt_final white age female i.year SOFA i.CCIgroup vent_final pressor_final // across all SOFA groups
logistic rrt_final white age female i.year SOFA i.CCIgroup vent_final pressor_final if SOFA group == 1 // SOFA 0-5
logistic rrt_final white age female i.year SOFA i.CCIgroup vent_final pressor_final if SOFA group == 2 // SOFA 6-10
logistic rrt_final white age female i.year SOFA i.CCIgroup vent_final pressor_final if SOFA group == 3 // SOFA 11-15
logistic rrt_final white age female i.year SOFA i.CCIgroup vent_final pressor_final if SOFA group == 4 // SOFA >15

* LogReg on race and vasopressors
logistic pressor_final white age female i.year SOFA i.CCIgroup vent_final rrt_final // across all SOFA groups
logistic pressor_final white age female i.year SOFA i.CCIgroup vent_final rrt_final if SOFA group == 1 // SOFA 0-5
logistic pressor_final white age female i.year SOFA i.CCIgroup vent_final rrt_final if SOFA group == 2 // SOFA 6-10
logistic pressor_final white age female i.year SOFA i.CCIgroup vent_final rrt_final if SOFA group == 3 // SOFA 11-15
logistic pressor_final white age female i.year SOFA i.CCIgroup vent_final rrt_final if SOFA group == 4 // SOFA >15



