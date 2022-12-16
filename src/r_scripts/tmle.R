source("src/r_scripts/load_data.R")

library(tmle)


data_between <- function(sepsis_data, sev_low, sev_high, sev_type) {

    if (sev_type == 'SOFA') {

        res <- sepsis_data[sepsis_data$SOFA <= sev_high & sepsis_data$SOFA >= sev_low,
        c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_cont",
          "ventilation_bin", "death_bin", "rrt", "pressor",
          "hypertension", "heart_failure", "ckd", "copd", "asthma")]


    } else if (sev_type == 'OASIS') {

        res <- sepsis_data[sepsis_data$OASIS_B <= sev_high & sepsis_data$OASIS_B >= sev_low,
        c("source","anchor_age","gender","ethnicity_white","OASIS_B","charlson_cont",
          "ventilation_bin", "death_bin", "rrt", "pressor",
          "hypertension", "heart_failure", "ckd", "copd", "asthma")]
    }
    
    return(na.omit(res))
}

# TMLE
run_tmle <- function(data, treatment, sev_type) {

    if (sev_type == "SOFA") {

        confounders <- c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_cont",
                     "hypertension", "heart_failure", "ckd", "copd", "asthma")
    
    } else if (sev_type == "OASIS") {

        confounders <- c("source","anchor_age","gender","ethnicity_white","OASIS_B","charlson_cont",
                     "hypertension", "heart_failure", "ckd", "copd", "asthma")
    }

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
                   g.SL.library = c("SL.xgboost", "SL.svm"),
                   Q.SL.library = c("SL.xgboost", "SL.svm"),
                  )

    print(summary(result))

    return(result)
}


# run TMLE by SOFA only (main analysis)
tmle_stratified <- function(sepsis_data, treatment, race, df, sev_type) {

    if (sev_type == 'SOFA') {
        sev_ranges <- list(list(0, 3), list(4,6), list(7, 10), list(11, 100))

    } else if (sev_type == 'OASIS') {
        sev_ranges <- list(list(0, 37), list(38, 45), list(46, 51), list(52, 100))
    }

    fn <- paste0("TMLE_", sev_type)

        
    for (sev in sev_ranges) {
        
        start <- sev[1]
        end <- sev[2]

        print(paste0(treatment, " - ", race, ": ", start, " - ",end))

        if (race == "non-white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 0, ]
            
        } else if (race == "white") {
            sepsis_data <- sepsis_data[sepsis_data$ethnicity_white == 1, ]
            
        } # else, nothing because race = "all" needs no further filtering

        data <- data_between(sepsis_data, start, end, sev_type)
        result <- run_tmle(data, treatment, sev_type)

        df[nrow(df) + 1,] <- c(treatment,
                               race,
                               start,
                               end,
                               result$estimates$ATE$psi[[1]],
                               result$estimates$ATE$CI[1],
                               result$estimates$ATE$CI[2],
                               result$estimates$ATE$pvalue[[1]],
                               nrow(data),
                               result$g$coef[[1]],
                               result$g$coef[[2]],
                               result$Qinit$coef[[1]],
                               result$Qinit$coef[[2]],
                               result$g$AUC[[1]],
                               result$Qinit$Rsq[[1]]
                              ) 
        # Saves file as we go
        write.csv(df, paste0("results/", fn,".csv"))

        return(df)
    }     
}


data <- read.csv('data/MIMIC_eICU.csv')

sev_type <- "SOFA"

treatments <- list("ventilation_bin", "rrt", "pressor")
races <- list("all", "non-white", "white")

# Dataframe to hold results
df <- data.frame(matrix(ncol=15, nrow=0))
colnames(df) <- c("treatment", "race", "sev_start", "sev_end",
                    "psi", "i_ci","s_ci", "pvalue", "n",
                    "g_XGBoost", "g_SVM", "Q_XGBoost", "Q_SVM",
                    "g_AUC", "Q_R2")

# Go through all treatments
for (treatment in treatments) {
    for (race in races){
        df <- tmle_stratified(data, treatment, race, df, sev_type)
    }
}
