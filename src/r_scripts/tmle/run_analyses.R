source("src/r_scripts/tmle/tmle.R")
source("src/r_scripts/utils/load_data.R")
source("src/r_scripts/tmle/plot_results.R")

# Get merged datasets' data
data <- get_merged_datasets()

write.csv(data, "data/d.csv")


# List with possible invasive treatments
treatments <- list("ventilation_bin", "rrt", "pressor")

# Dataframe to hold results
df <- data.frame(matrix(ncol=11, nrow=0))
colnames(df) <- c("cohort", "treatment", "sofa_start", "sofa_end",
                    "psi", "i_ci","s_ci", "pvalue", "auc", "r2", "n")

cohort <- "MIMIC_eICU"

# Go through all treatments
for (treatment in treatments) {

    print(treatment)

    # Stratified SOFAs
    df <- tmle_stratified_sofas(data, treatment, cohort, df)

}

write.csv(df, "results/TMLE.csv")
