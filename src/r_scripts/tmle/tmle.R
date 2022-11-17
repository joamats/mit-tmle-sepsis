library(tmle)
library(dplyr)
library(psych)

source("src/r_scripts/utils/rebuild_data.R")
source("src/r_scripts/tmle/plot_results.R")

# TMLE by SOFA
run_tmle_sofa <- function(data_sofa, sofa_low_inclusive, sofa_high_inclusive,treatment) {

    if(treatment == "ventilation_bin") {

        W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","rrt", "pressor")]
        A <- data_sofa$ventilation_bin

    } else if(treatment == "rrt") {

        W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "pressor", "ventilation_bin")]
        A <- data_sofa$rrt

    } else if(treatment == "pressor") {

        W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "rrt", "ventilation_bin")]
        A <- data_sofa$pressor
    }

    Y <- data_sofa$death_bin

    result <- tmle(Y, A, W , family = "binomial", 
                    g.SL.library = c("SL.glm", "SL.glmnet", "SL.bayesglm","SL.mean"),
                    Q.SL.library = c("SL.glm", "SL.glmnet", "SL.stepAIC","SL.mean","SL.earth","SL.ranger","SL.gam", "SL.bayesglm","SL.glm.interaction", "SL.biglasso")
                    )

    data_result <- list("data" = data_sofa, "result" = result)

    return(data_result)
}



# TMLE by SOFA and year range (just to check there are no trends throughout time)
run_tmle_sofa_ayg <- function(data_sofa, sofa_low_inclusive, sofa_high_inclusive, ayg_value, treatment) {
    # TMLE 
    print(paste0(treatment,' effect for SOFA between [', sofa_low_inclusive, ",", sofa_high_inclusive,"] with anchor_year_group = ", ayg_value))
    
    if(treatment == "ventilation_bin") {

        W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","rrt", "pressor")]
        A <- data_sofa$ventilation_bin

    } else if(treatment == "rrt") {

        W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "pressor", "ventilation_bin")]
        A <- data_sofa$rrt

    } else if(treatment == "pressor") {

        W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "rrt", "ventilation_bin")]
        A <- data_sofa$pressor
    }

    Y <- data_sofa$death_bin

    result <- tmle(Y, A, W , family = "binomial", 
                   g.SL.library = c("SL.glm", "SL.glmnet", "SL.bayesglm","SL.mean"),
                   Q.SL.library = c("SL.glm", "SL.glmnet", "SL.stepAIC","SL.mean","SL.earth","SL.ranger","SL.gam","SL.bayesglm","SL.glm.interaction", "SL.biglasso")
                   )

    data_result <- list("data" = data_sofa, "result" = result)

    return(data_result)
}


# run TMLE by SOFA only (main analysis)
tmle_stratified_sofas <- function(sepsis_data, treatment, cohort) {

    sofa_ranges <- list(list(0, 5), list(6,10), list(11, 15), list(16, 100))

    df <- data.frame("cohort", "treatment", "sofa_start", "sofa_end", "psi", "ci", "auc", "r2")

    for (sofa in sofa_ranges) {

        start <- sofa[1]
        end <- sofa[2]

        data_sofa <- data_between_sofa(sepsis_data, start, end)
        result <- run_tmle_sofa(data_sofa, start, end, treatment)
    
        df[nrow(df) + 1,] <- c(cohort,
                               treatment,
                               start,
                               end,
                               toString(result$result$estimates$ATE$psi),
                               toString(result$result$estimates$ATE$CI),
                               toString(result$result$g$AUC),
                               toString(result$result$Qinit$Rsq)
                              ) 
    }  
    write.csv(df, paste0('results/', cohort,'/tmle_', treatment,'_by_sofa.csv'))
}


# run TMLE by SOFA and year range
tmle_stratified_sofas_year <- function(sepsis_data, treatment, cohort){

    sofa_ranges <- list(list(0, 5), list(6,10), list(11, 15))#, list(16, 100))
    if (cohort == "MIMIC") {
        
        anchor_year_groups <- list("2008 - 2010", "2011 - 2013", "2014 - 2016", "2017 - 2019")

    } else if (cohort == "eICU") {

        anchor_year_groups <- list("2014", "2015")
    }
    
    results <- list()

    for (sofa in sofa_ranges) {

        start <- sofa[1]
        end <- sofa[2]

        for(ayg in anchor_year_groups) {

            data_sofa_ayg <- data_between_sofa_and_anchor_year_group(sepsis_data, start, end, ayg)
            input = paste0("SOFA = [", start, ",", end, "]; anchor_year_group: ", ayg, " total count:", nrow(data_sofa_ayg))
            result <- run_tmle_sofa_ayg(data_sofa_ayg, start, end, ayg, treatment)

            results <- append(results, input)
            results <- append(results, result)
        }
    }
    
    plot_tmle_years_results(results, treatment, cohort)
    
}