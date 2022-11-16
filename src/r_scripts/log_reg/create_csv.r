source("src/r_scripts/utils/load_data.R")

# Save MIMIC data for Stata
sepsis_data <- load_data('MIMIC')
write.csv(sepsis_data, "data/MIMIC_data_stata.csv")

# Save eICU data for Stata
sepsis_data <- load_data('eICU')
write.csv(sepsis_data, "data/eICU_data_stata.csv")
