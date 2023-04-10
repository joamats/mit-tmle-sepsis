source("src/r_scripts/load_data.R")
source("src/r_scripts/utils.R")

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome,
                     cohort, race, sev_min, sev_max, results_df) {


    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]

    result <- tmle(
                Y = Y,
                A = A,
                W = W,
                family = "binomial", 
                gbound = c(0.05, 0.95),
                g.SL.library = c("SL.glm"),
                Q.SL.library = c("SL.glm"),
                )

    log <- summary(result)     

    results_df[nrow(results_df) + 1,] <- c(
                                            treatment,
                                            cohort,
                                            race,
                                            sev_min,
                                            sev_max,
                                            log$estimates$ATE$psi,
                                            log$estimates$ATE$CI[1],
                                            log$estimates$ATE$CI[2],
                                            log$estimates$ATE$pvalue,
                                            nrow(data)
                                            ) 
    return (results_df)
}

# Main
cohorts <- c("MIMIC")
races <- c("white", "non-white") 
outcomes <- c("blood_yes", "mortality_in")
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")
treatments <- read.delim("config/treatments.txt")


for (c in cohorts) {
    print(paste0("Cohort: ", c))

    # Read Data for this database and cohort
    data <- read.csv(paste0("data/", c, ".csv"))

    confounders <- read.delim(paste0("config/confounders_", c,".txt"))

    for (outcome in outcomes) {
        print(paste0("Outcome: ", outcome))

        # Dataframe to hold results
        results_df <- data.frame(matrix(ncol=10, nrow=0))
        colnames(results_df) <- c(
                                "treatment",
                                "cohort",
                                "race",
                                "prob_mort_start",
                                "prob_mort_end",
                                "psi",
                                "i_ci",
                                "s_ci",
                                "pvalue",
                                "n")

        for (j in 1:nrow(treatments)) {
            # Treatment
            treatment <- treatments$treatment[j]
            print(paste0("Treatment: ", treatment))

            # Get formula with confounders and treatment
            model_confounders <- read_confounders(j, treatments, confounders) 

            for (r in races) {

                print(paste0("Race: ", r))

                if (r == "non-white") {
                    subset_data <- subset(data, ethnicity_white == 0)
                    
                } else if (r == "white") {
                    subset_data <- subset(data, ethnicity_white == 1)
                    
                } # else, nothing because race = "all" needs no further filtering

                for (i in 1:nrow(prob_mort_ranges)) {
                    
                    sev_min <- prob_mort_ranges$min[i]
                    sev_max <- prob_mort_ranges$max[i]

                    print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                    # Stratify by prob_mort
                    subsubset_data <- subset(subset_data, prob_mort >= sev_min & prob_mort < sev_max)

                    # Run TMLE
                    results_df <- run_tmle(subsubset_data, treatment, model_confounders, outcome,
                                        c, r, sev_min, sev_max, results_df)

                    # Save Results
                    write.csv(results_df, paste0("results/NEW/", c, "/", outcome, ".csv"))

                }
            }           
        }
    }
}
