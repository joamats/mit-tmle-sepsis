library(tmle)
library(dplyr)
library(psych)

source("src/r_scripts/utils/rebuild_data.R")
source("src/r_scripts/tmle/plot_results.R")

# TMLE by SOFA
run_tmle_sofa <- function(data_sofa, treatment) {

    if(treatment == "ventilation_bin") {

        W <- data_sofa[, c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","rrt", "pressor")]
        A <- data_sofa$ventilation_bin

    } else if(treatment == "rrt") {

        W <- data_sofa[, c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "pressor", "ventilation_bin")]
        A <- data_sofa$rrt

    } else if(treatment == "pressor") {

        W <- data_sofa[, c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "rrt", "ventilation_bin")]
        A <- data_sofa$pressor
    }

    Y <- data_sofa$death_bin

    result <- tmle(Y, A, W , family = "binomial", 
                    g.SL.library = c("SL.glm", "SL.glmnet", "SL.bayesglm","SL.mean"),
                    Q.SL.library = c("SL.glm", "SL.glmnet", "SL.stepAIC","SL.mean","SL.earth","SL.ranger","SL.gam", "SL.bayesglm","SL.glm.interaction", "SL.biglasso"),
                    gbound = c(0.05, 0.95)
                    )

    data_result <- list("data" = data_sofa, "result" = result)

    return(data_result)
}


# run TMLE by SOFA only (main analysis)
tmle_stratified_sofas <- function(sepsis_data, treatment, cohort, df) {

    sofa_ranges <- list(list(0,100), list(0, 5), list(6,10), list(11, 15), list(16, 100))

    for (sofa in sofa_ranges) {

        start <- sofa[1]
        end <- sofa[2]

        data_sofa <- data_between_sofa(sepsis_data, start, end)
        result <- run_tmle_sofa(data_sofa, treatment)

        conf_int <- result$result$estimates$ATE$CI

        if (length(conf_int) == 2){
            # split CIs
            ci <- gsub( "c", "", as.character(conf_int)) 
            ci <- gsub( "[()]", "", ci) 
            cis <- strsplit(ci, split=', ')
            i_ci <- as.double(ci[1])
            s_ci <- as.double(ci[2])

        } else {
            i_ci <- 0
            s_ci <- 0
        }

        df[nrow(df) + 1,] <- c(cohort,
                               treatment,
                               start,
                               end,
                               toString(result$result$estimates$ATE$psi),
                               i_ci,
                               s_ci,
                               toString(result$result$estimates$ATE$pvalue),
                               toString(result$result$g$AUC),
                               toString(result$result$Qinit$Rsq),
                               nrow(data_sofa)
                              ) 
    }  

    return (df)
}
