library(tmle)

source("src/r_scripts/utils/rebuild_data.R")
source("src/r_scripts/tmle/plot_results.R")

# TMLE by SOFA
run_tmle <- function(data, treatment) {
    confounders <- c("source","anchor_age","gender","ethnicity_white","OASIS_B","charlson_cont",
    #confounders <- c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_cont",
                     "hypertension", "heart_failure", "ckd", "copd", "asthma")

    if(treatment == "ventilation_bin") {

        W <- data[, append(confounders, c("rrt", "pressor"))]
        A <- data$ventilation_bin

    } else if(treatment == "rrt") {

        W <- data[, append(confounders, c("ventilation_bin", "pressor"))]
        A <- data$rrt

    } else if(treatment == "pressor") {

        W <- data[, append(confounders, c("rrt", "ventilation_bin"))]
                           
        A <- data$pressor
    }

    Y <- data$death_bin

    result <- tmle(Y = Y,
                   A = A,
                   W = W,
                   family = "binomial", 
                   gbound = c(0.05, 0.95),
                   #1: g.SL.library = c("SL.glm", "tmle.SL.dbarts2", "SL.glmnet")
                   #2: g.SL.library = c("SL.randomForest","SL.glm","SL.earth","SL.stepAIC","SL.biglasso","SL.glm.interaction","SL.nnet","tmle.SL.dbarts2", "SL.glmnet")
                   #3: g.SL.library = c("SL.xgboost","SL.bartMachine", "SL.svm")
                  )

    log <- summary(result)
    print(log)

    return(log)
}


# run TMLE by SOFA only (main analysis)
tmle_stratified <- function(sepsis_data, treatment, race, df) {

    #sev_ranges <- list(list(0, 3), list(4,6), list(7, 10), list(11, 100))
    sev_ranges <- list(list(0, 37), list(38, 45), list(46, 51), list(52, 100))
    for (sev in sev_ranges) {
        
        start <- sev[1]
        end <- sev[2]

        print(paste0(treatment, " - ", race, ": ", start, " - ",end))

        if (race == "non-white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 0, ]
            
        } else if (race == "white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 1, ]
            
        } # else, nothing because race = "all" needs no further filtering

        #data <- data_between_sofa(sepsis_data, start, end)
        data <- data_between_oasis(sepsis_data, start, end)
        log <- run_tmle(data, treatment)

        df[nrow(df) + 1,] <- c(treatment,
                               race,
                               start,
                               end,
                               log$estimates$ATE$psi,
                               log$estimates$ATE$CI[1],
                               log$estimates$ATE$CI[2],
                               log$estimates$ATE$pvalue,
                               nrow(data)
                              ) 
    }  

    return (df)
}
