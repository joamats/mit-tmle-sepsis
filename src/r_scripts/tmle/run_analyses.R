source("src/r_scripts/tmle/tmle.R")
source("src/r_scripts/utils/load_data.R")
source("src/r_scripts/tmle/plot_results.R")

# List with possible invasive treatments
treatments <- list("ventilation_bin", "rrt", "pressor")

# List with possible datasets
cohorts <- list("MIMIC", "eICU") #add eICU / MIMIC

# Dataframe to hold results
df <- data.frame(matrix(ncol=10, nrow=0))
colnames(df) <- c("cohort", "treatment", "sofa_start", "sofa_end",
                    "psi", "i_ci","s_ci", "auc", "r2", "n")
for (cohort in cohorts) {
    # Load Data
    sepsis_data <- load_data(cohort)

    # Go through all treatments
    for (treatment in treatments) {
        # Stratified SOFAs
        df <- tmle_stratified_sofas(sepsis_data, treatment, cohort, df)

        # Stratified SOFAs && Year - plots as outputs
        #tmle_stratified_sofas_year(sepsis_data, treatment, cohort)
    }
}

write.csv(df, "results/TMLE.csv")
