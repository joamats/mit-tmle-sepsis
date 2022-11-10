require(arm)
require(earth)
require(ranger)
require(rpart)
require(xgboost)
library(hal9001)
library(haldensify)
library(biglasso)
library(ltmle)
require(dplyr)
library(psych)

source("src/r_scripts/utils/rebuild_data.R")

# Without Super Learner Library 
run_ltmle_abar_w_slLib <- function(sepsis_data, abar, Anodes, Lnodes) {
    result <- ltmle(data = sepsis_data, 
        Anodes = Anodes,  # Treatment Nodes
        Lnodes = Lnodes, # Time-Dependent Covariate Nodes
        Ynodes = c("death_bin"), # Outcome Nodes
        abar = abar, # binary matrix of counterfactual
        gbounds = c(0.01, 1), # Lower and Upper bounds on estimated cumulative probabilities
        Qform=NULL,
        gform=NULL,
        #SL.library = c("SL.glm", "SL.glmnet", "SL.stepAIC","SL.mean","SL.earth","SL.ranger","SL.gam","SL.bayesglm","SL.glm.interaction", "SL.biglasso")
    )
    return(result)
}

# Create Anodes
get_anodes <- function(treatment) {
    # treatment should be "ventilation_bin", "rrt", or "pressor"
    Anodes <- c("ethnicity_white", treatment)

    return(Anodes)
}

# Create Lnodes
get_lnodes <- function(treatment) {

    if (treatment == "ventilation_bin") {

        l1 <- c("gender1", "anchor_age1", "charlson_comorbidity_index1", "SOFA1", "pressor1", "rrt1", "anchor_year_group1")
        l2 <- c("gender2", "anchor_age2", "charlson_comorbidity_index2", "SOFA2", "pressor2", "rrt2", "anchor_year_group2")

    } else if (treatment == "rrt") {

        l1 <- c("gender1", "anchor_age1", "charlson_comorbidity_index1", "SOFA1", "pressor1", "ventilation_bin1", "anchor_year_group1")
        l2 <- c("gender2", "anchor_age2", "charlson_comorbidity_index2", "SOFA2", "pressor2", "ventilation_bin2", "anchor_year_group2")

    } else if (treatment == "pressor") {
        l1 <- c("gender1", "anchor_age1", "charlson_comorbidity_index1", "SOFA1", "rrt1", "ventilation_bin1", "anchor_year_group1")
        l2 <- c("gender2", "anchor_age2", "charlson_comorbidity_index2", "SOFA2", "rrt2", "ventilation_bin2", "anchor_year_group2")
    }

    Lnodes <- c(l1, l2)

    return(Lnodes)
}

# Run LTMLE analyses to all SOFAs
ltmle_all_sofas <- function(sepsis_data, treatment) {

    Anodes <- get_anodes(treatment)
    Lnodes <- get_lnodes(treatment)

    data_sofa <- rebuild_data(sepsis_data, treatment)
    write.csv(data_sofa, "d.csv")
    log_name <- paste0('src/r_scripts/log/ltmle_', treatment, '_all_sofas.txt')
    file_log <- file(log_name)

    # Run LTMLE by 2x2 w/ SL library, all SOFAs
    result_run_ltmle_abar_00_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(0,0), Anodes, Lnodes)
    log1 <- summary(result_run_ltmle_abar_00_wlib)
    

    result_run_ltmle_abar_01_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(0,1), Anodes, Lnodes)
    log2 <- summary(result_run_ltmle_abar_01_wlib)

    result_run_ltmle_abar_10_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(1,0), Anodes, Lnodes)
    log3 <- summary(result_run_ltmle_abar_10_wlib)

    result_run_ltmle_abar_11_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(1,1), Anodes, Lnodes)
    log4 <- summary(result_run_ltmle_abar_11_wlib)

    full_log <- c(paste0('LTMLE All SOFAs, Race + ', treatment), 
                  '\nNon-white & Non-Treatment\n', toString(log1),
                  '\nNon-white & Yes-Treatment\n', toString(log2),
                  '\nWhite & Non-Treatment\n', toString(log3),
                  '\nWhite & Yes-Treatment\n', toString(log4)
                 )

    writeLines(full_log, file_log)
    close(file_log)

}


# Run LTMLE analyses to stratified SOFAs
ltmle_stratified_sofas <- function(sepsis_data, treatment) {

    Anodes <- get_anodes(treatment)
    Lnodes <- get_lnodes(treatment)

    data_sofa <- rebuild_data(sepsis_data, treatment)

    # cut data by SOFA score and run LTMLE by 2x2 WITH SL library
    sofa_ranges <- list(list(0, 5), list(6,10), list(11, 15), list(16, 100))

    for (sofa in sofa_ranges) {

        log_name <- paste0('src/r_scripts/log/ltmle_', treatment, '_sofa_', sofa[1], '_', sofa[2], '.txt')
        file_log <- file(log_name)

        start <- sofa[1]
        end <- sofa[2]
        data_sofa <- rebuild_data(data_between_sofa(sepsis_data, start, end), treatment)

        # Run LTMLE by 2x2 w/ SL library
        result_run_ltmle_abar_00_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(0,0), Anodes, Lnodes)
        log1 <- summary(result_run_ltmle_abar_00_wlib)

        result_run_ltmle_abar_01_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(0,1), Anodes, Lnodes)
        log2 <- summary(result_run_ltmle_abar_01_wlib)

        result_run_ltmle_abar_10_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(1,0), Anodes, Lnodes)
        log3 <- summary(result_run_ltmle_abar_10_wlib)

        result_run_ltmle_abar_11_wlib <- run_ltmle_abar_w_slLib(data_sofa, c(1,1), Anodes, Lnodes)
        log4 <- summary(result_run_ltmle_abar_11_wlib)

        full_log <- c(paste0('LTMLE Stratfied SOFAs, Race + ', treatment), 
                      paste0("SOFA = [", start, " ,", end, "]\nn =  ", nrow(data_sofa)),
                      '\nNon-white & Non-Treatment\n', toString(log1),
                      '\nNon-white & Yes-Treatment\n', toString(log2),
                      '\nWhite & Non-Treatment\n', toString(log3),
                      '\nWhite & Yes-Treatment\n', toString(log4)
                    )

        writeLines(full_log, file_log)
        close(file_log)

    }
}