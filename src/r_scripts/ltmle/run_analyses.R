source("src/r_scripts/ltmle/ltmle.R")
source("src/r_scripts/utils/load_data.R")

# List with possible invasive treatments
treatments <- list("ventilation_bin", "rrt", "pressor")

# List with possible datasets
data_paths <- list("data/MIMIC_data.csv") # add eICU when ready

for (data_path in data_paths) {
    # Load Data
    sepsis_data <- load_data(file_path = data_path)
    # Go through all treatments
    for (treatment in treatments) {
        # All SOFAs
        ltmle_all_sofas(sepsis_data, treatment)

        # Stratified SOFAs
        ltmle_stratified_sofas(sepsis_data, treatment)
    }
}
