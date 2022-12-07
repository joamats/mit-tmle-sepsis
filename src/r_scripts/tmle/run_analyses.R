source("src/r_scripts/tmle/tmle.R")
source("src/r_scripts/utils/load_data.R")
source("src/r_scripts/tmle/plot_results.R")

# Get merged datasets' data
data <- get_merged_datasets()


# List with possible invasive treatments
treatments <- list("ventilation_bin", "rrt", "pressor")
races <- list("all", "non-white", "white")

# Dataframe to hold results
df <- data.frame(matrix(ncol=9, nrow=0))
colnames(df) <- c("treatment", "race", "sofa_start", "sofa_end",
                    "psi", "i_ci","s_ci", "pvalue", "n")

# Go through all treatments
for (treatment in treatments) {
    for (race in races){
        df <- tmle_stratified_sofas(data, treatment, race, df)
    }
}

write.csv(df, "results/TMLE.csv")
