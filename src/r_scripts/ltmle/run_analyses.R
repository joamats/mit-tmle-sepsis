source("src/r_scripts/ltmle/ltmle.R")
source("src/r_scripts/utils/load_data.R")

# Get merged datasets' data
data <- get_merged_datasets()

# List with possible invasive treatments
treatments <- list("ventilation_bin", "rrt", "pressor")

# Initialize final dataframe
df <- data.frame(matrix(ncol=11, nrow=0))
colnames(df) <- c("cohort", "treatment", "analysis", "sofa_start", "sofa_end",
                      "psi", "std_dev", "pvalue", "iCI", "sCI", "n")

cohort <- "MIMIC_eICU"

# Go through all treatments
for (treatment in treatments) {
    # Stratified SOFAs, append
    df <- ltmle_stratified_sofas(data, treatment, cohort, df)

}

# Save results
write.csv(df, "results/LTMLE.csv")