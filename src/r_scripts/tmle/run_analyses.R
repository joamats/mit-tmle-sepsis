source("src/r_scripts/tmle/tmle.R")
source("src/r_scripts/utils/load_data.R")
source("src/r_scripts/tmle/plot_results.R")

# List with possible invasive treatments
treatments <- list("ventilation_bin","rrt", "pressor")

# List with possible datasets
cohorts <- list("eICU") #add eICU / MIMIC

for (cohort in cohorts) {
    # Load Data
    sepsis_data <- load_data(cohort)

    # Go through all treatments
    for (treatment in treatments) {

        # Stratified SOFAs - logs as outputs
        tmle_stratified_sofas(sepsis_data, treatment, cohort)

        # Stratified SOFAs && Year - plots as outputs
        tmle_stratified_sofas_year(sepsis_data, treatment, cohort)
        
    }
}
