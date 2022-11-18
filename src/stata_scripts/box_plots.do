* TMLE MIMC and eICU Sepsis Project 
* Stata code for box plots of TMLE and LTMLE results

*** LTMLE results 
* Get data from csv files


import delimited "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/LTMLE_combined.csv", clear // substitute with your local data path
destring, replace ignore(NA)

cd  "/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/results/log_reg/" // substitute with your local results path
