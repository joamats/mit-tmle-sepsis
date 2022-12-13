library(ltmle)

source("src/r_scripts/utils/load_data.R")
source("src/r_scripts/utils/rebuild_data.R")

# create Anodes
get_anodes <- function(treatment) {
    # treatment should be "ventilation_bin", "rrt", or "pressor"
    Anodes <- c("ethnicity_white", treatment)

    return(Anodes)
}

# Create Lnodes
reorganize_data <- function(data, treatment) {


    if (treatment == "ventilation_bin") {

        return (data[, c("source","anchor_age","gender",
                         "SOFA","charlson_cont",
                         "hypertension", "heart_failure", "ckd", "copd", "asthma",
                         "rrt", "pressor",
                         "ethnicity_white", "ventilation_bin",
                         "death_bin")])

    } else if (treatment == "rrt") {

        return (data[, c("source","anchor_age","gender",
                    "SOFA","charlson_cont",
                    "hypertension", "heart_failure", "ckd", "copd", "asthma",
                    "ventilation_bin", "pressor",
                    "ethnicity_white", "rrt",
                    "death_bin")])

    } else if (treatment == "pressor") {

        return (data[, c("source","anchor_age","gender",
                    "SOFA","charlson_cont",
                    "hypertension", "heart_failure", "ckd", "copd", "asthma",
                    "ventilation_bin", "rrt",
                    "ethnicity_white", "pressor",
                    "death_bin")])
    }

}


ltmle_MSM <- function(data, Anodes) {

    summary.measures <- array(1:4, dim = c(4, 1, 1))
    colnames(summary.measures) <- "level"

    rs <- list(function (row) c(0, 0),
            function (row) c(1, 0),
            function (row) c(0, 1),
            function (row) c(1, 1))

    ATE <- ltmleMSM(data = data, 
                    Anodes = Anodes,
                    Ynodes = "death_bin",
                    regimes = rs,
                    gbounds = c(0.05, 0.95),
                    summary.measures = summary.measures, 
                    working.msm = "Y ~ level"
                    )

    log <- summary(ATE)
    print(log)

    return (log)
}

run_ltmleMSM <- function(sepsis_data, treatment, df) {

    Anodes <- get_anodes(treatment)
    
    # cut data by SOFA score and run LTMLE by 2x2 WITH SL library
    sofa_ranges <- list(list(0, 3), list(4,6), list(7, 10), list(11, 100))
   
    for (sofa in sofa_ranges) {

        start <- sofa[1]
        end <- sofa[2]

        data_sofa <- data_between_sofa(sepsis_data, start, end)
        data_sofa <- reorganize_data(data_sofa, treatment)

        log <- ltmle_MSM(data_sofa, Anodes)

        # Append to df
        df[nrow(df) + 1,] <- c(treatment,
                                start,
                                end,
                                log$effect.measures$ATE["estimate"][1],
                                log$effect.measures$ATE["std.dev"],
                                log$effect.measures$ATE["pvalue"][1],
                                log$effect.measures$ATE["CI"][[1]],    
                                log$effect.measures$ATE["CI"][[2]],    
                                nrow(data_sofa)
                                ) 
    }

    return (df)
}

# Get merged datasets' data
data <- get_merged_datasets()

write.csv(data, "data/MIMIC_eICU.csv")
    
# List with possible invasive treatments
treatments <- list("ventilation_bin")#, "rrt", "pressor")

# Initialize final dataframe
df <- data.frame(matrix(ncol=9, nrow=0))
colnames(df) <- c("treatment", "sofa_start", "sofa_end",
                  "psi", "std_dev", "pvalue", "iCI", "sCI", "n")

# Go through all treatments
for (treatment in treatments) {
    # Stratified SOFAs, append
    df <- run_ltmleMSM(data, treatment, df)
}

# Save results
write.csv(df, "results/LTMLE_MSM.csv")  