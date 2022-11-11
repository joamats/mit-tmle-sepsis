source("src/r_scripts/tmle/tmle.R")
source("src/r_scripts/utils/load_data.R")
source("src/r_scripts/tmle/plot_results.R")

# List with possible invasive treatments
treatments <- list("pressor", "ventilation_bin", "rrt")

# List with possible datasets
data_paths <- list("data/MIMIC_data.csv") # add eICU when ready

for (data_path in data_paths) {
    # Load Data
    sepsis_data <- load_data(file_path = data_path)

    # Go through all treatments
    for (treatment in treatments) {

        # Stratified SOFAs - logs as outputs
        tmle_stratified_sofas(sepsis_data, treatment)

        # Stratified SOFAs && Year - plots as outputs
        tmle_stratified_sofas_year(sepsis_data, treatment)
    }
}
