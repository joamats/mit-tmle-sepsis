source("src/r_scripts/load_data.R")

library(tmle)


data_between <- function(sepsis_data, sev_low, sev_high) {


    res <- sepsis_data[sepsis_data$prob_mort <= sev_high & sepsis_data$prob_mort >= sev_low, ]
    
    return(na.omit(res))
}

# TMLE
run_tmle <- function(data, treatment) {

    confounders <- c("anchor_age","gender","ethnicity_white","prob_mort","charlson_cont",
                    "hypertension", "heart_failure", "ckd", "copd", "asthma", "source")
    

    if (treatment == "ventilation_bin") {

        W <- data[, append(confounders, c("rrt", "pressor"))]
        A <- data$ventilation_bin

   } else if (treatment == "rrt") {

        W <- data[, append(confounders, c("ventilation_bin", "pressor"))]
        A <- data$rrt

    } else if (treatment == "pressor") {

        W <- data[, append(confounders, c("rrt", "ventilation_bin"))]         
        A <- data$pressor
    }

    Y <- data$death_bin

    result <- tmle(Y = Y,
                   A = A,
                   W = W,
                   family = "binomial", 
                   gbound = c(0.05, 0.95),
                   g.SL.library = c("SL.glm"),
                   Q.SL.library = c("SL.glm"),
                  )

    print(summary(result))

    return(result)
}


# run TMLE by prob of mort. (main analysis)
tmle_stratified <- function(sepsis_data, treatment, race, df, cohort) {

    sev_ranges <- list(list(0, .1), list(.1, .2), list(.2, 1))

    fn <- paste0("TMLE_", cohort)

        
    for (sev in sev_ranges) {
        
        start <- sev[1]
        end <- sev[2]

        print(paste0(treatment, " - ", race, ": ", start, " - ",end))

        if (race == "non-white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 0, ]
            
        } else if (race == "white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 1, ]
            
        } # else, nothing because race = "all" needs no further filtering

        data <- data_between(sepsis_data, start, end)
        result <- run_tmle(data, treatment)

        df[nrow(df) + 1,] <- c(treatment,
                               race,
                               start,
                               end,
                               result$estimates$ATE$psi[[1]],
                               result$estimates$ATE$CI[1],
                               result$estimates$ATE$CI[2],
                               result$estimates$ATE$pvalue[[1]],
                               nrow(data)
                              ) 
        # Saves file as we go
        write.csv(df, paste0("results/prob_mort/", fn,".csv"))
    }     
    return(df)
}

cohorts <- c("MIMIC_eICU") #"eICU", "MIMIC",

# iterate over cohorts

for (cohort in cohorts) {

    data <- read.csv(paste0('data/', cohort, '.csv'))

    treatments <- list("ventilation_bin", "rrt", "pressor")
    races <- list("all", "non-white", "white")

    # Dataframe to hold results
    df <- data.frame(matrix(ncol=9, nrow=0))
    colnames(df) <- c("treatment", "race", "sev_start", "sev_end",
                    "psi", "i_ci","s_ci", "pvalue", "n")

    # Go through all treatments
    for (treatment in treatments) {
        for (race in races){
            df <- tmle_stratified(data, treatment, race, df, cohort)
        }
    }

}


