source("src/r_scripts/ltmle/ltmle.R")
source("src/r_scripts/utils/load_data.R")

# List with possible invasive treatments
treatments <- list("ventilation_bin")#, "rrt", "pressor")

# List with possible datasets
cohorts <- list("eICU") # add eICU / MIMIC

for (cohort in cohorts) {
    # Load Data
    sepsis_data <- load_data(cohort)
    # Go through all treatments
    for (treatment in treatments) {
        # All SOFAs
        ltmle_all_sofas(sepsis_data, treatment, cohort)

        # Stratified SOFAs
        #ltmle_stratified_sofas(sepsis_data, treatment, cohort)
    }
}
