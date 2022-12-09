library(tmle)

source("src/r_scripts/utils/rebuild_data.R")
source("src/r_scripts/tmle/plot_results.R")

# TMLE by SOFA
run_tmle_sofa <- function(data_sofa, treatment) {

    confounders <- c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_cont")#,
                     "hypertension", "heart_failure", "ckd", "copd", "asthma")

    if(treatment == "ventilation_bin") {

        W <- data_sofa[, append(confounders, c("rrt", "pressor"))]
        A <- data_sofa$ventilation_bin

    } else if(treatment == "rrt") {

        W <- data_sofa[, append(confounders, c("ventilation_bin", "pressor"))]
        A <- data_sofa$rrt

    } else if(treatment == "pressor") {

        W <- data_sofa[, append(confounders, c("rrt", "ventilation_bin"))]
                           
        A <- data_sofa$pressor
    }

    Y <- data_sofa$death_bin

    result <- tmle(Y = Y,
                   A = A,
                   W = W,
                   family = "binomial", 
                   gbound = c(0.05, 0.95)
                  )

    log <- summary(result)
    print(log)

    return(log)
}


# run TMLE by SOFA only (main analysis)
tmle_stratified_sofas <- function(sepsis_data, treatment, race, df) {

    sofa_ranges <- list(list(0, 3), list(4,6), list(7, 10), list(11, 100))

    for (sofa in sofa_ranges) {
        
        start <- sofa[1]
        end <- sofa[2]

        print(paste0(treatment, " - ", race, ": ", start, " - ",end))

        if (race == "non-white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 0, ]
            
        } else if (race == "white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 1, ]
            
        } # else, nothing because race = "all" needs no further filtering

        data_sofa <- data_between_sofa(sepsis_data, start, end)
        log <- run_tmle_sofa(data_sofa, treatment)

        df[nrow(df) + 1,] <- c(treatment,
                               race,
                               start,
                               end,
                               log$estimates$ATE$psi,
                               log$estimates$ATE$CI[1],
                               log$estimates$ATE$CI[2],
                               log$estimates$ATE$pvalue,
                               nrow(data_sofa)
                              ) 
    }  

    return (df)
}
