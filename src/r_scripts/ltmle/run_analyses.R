source("src/r_scripts/ltmle/ltmle.R")
source("src/r_scripts/utils/load_data.R")

# List with possible invasive treatments
treatments <- list("ventilation_bin", "rrt", "pressor")

# List with possible datasets
cohorts <- list("eICU", "MIMIC") # add eICU / MIMIC

# Initialize final dataframe
df <- data.frame(matrix(ncol=11, nrow=0))
colnames(df) <- c("cohort", "treatment", "analysis", "sofa_start", "sofa_end",
                      "psi", "std_dev", "pvalue", "iCI", "sCI", "n")

for (cohort in cohorts) {
    # Load Data
    sepsis_data <- load_data(cohort)
    # Go through all treatments
    for (treatment in treatments) {
        # Stratified SOFAs, append
        df <- ltmle_stratified_sofas(sepsis_data, treatment, cohort, df)

    }
}

write.csv(df, "results/LTMLE.csv")