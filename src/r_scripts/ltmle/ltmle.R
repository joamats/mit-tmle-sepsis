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
ltmle_all_sofas <- function(sepsis_data, treatment, cohort) {

    Anodes <- get_anodes(treatment)
    Lnodes <- get_lnodes(treatment)

    data_sofa <- rebuild_data(sepsis_data, treatment)

    df <- data.frame(matrix(ncol=7, nrow=0))
    colnames(df) <- c("cohort", "treatment", "analysis", "psi", "std_dev", "pvalue", "CI")

    abars <- c(c(0,0), c(0,1), c(1,0), c(1,1))
    analyses <- list('Non-white & Non-Treatment',
                       'Non-white & Yes-Treatment',
                       'White & Non-Treatment',
                       'White & Yes-Treatment'
                      )

    # Go through different analyses
    for (i in 1:4) {

        abar <- c(abars[2*(i-1) + 1], abars[2*i]) 
        analysis <- analyses[i]

        # Run LTMLE by 2x2 w/ SL library, all SOFAs
        result_run_ltmle_abar_wlib <- run_ltmle_abar_w_slLib(data_sofa, abar, Anodes, Lnodes)
        log <- summary(result_run_ltmle_abar_wlib)

        # Append to df
        df[nrow(df) + 1,] <- c(cohort,
                    treatment,
                    analysis,
                    log$treatment["estimate"][1],
                    log$treatment["std.dev"],
                    log$treatment["pvalue"][1],
                    toString(log$treatment["CI"])
                    ) 
    }
    write.csv(df, paste0('results/', cohort,'/ltmle_', treatment,'.csv'))
}


# Run LTMLE analyses to stratified SOFAs
ltmle_stratified_sofas <- function(sepsis_data, treatment, cohort) {

    Anodes <- get_anodes(treatment)
    Lnodes <- get_lnodes(treatment)

    data_sofa <- rebuild_data(sepsis_data, treatment)

    # cut data by SOFA score and run LTMLE by 2x2 WITH SL library
    sofa_ranges <- list(list(0, 5), list(6,10), list(11, 15), list(16, 100))

    df <- data.frame(matrix(ncol=9, nrow=0))
    colnames(df) <- c("cohort", "treatment", "analysis", "sofa_start", "sofa_end",
                      "psi", "std_dev", "pvalue", "CI")

    abars <- c(c(0,0), c(0,1), c(1,0), c(1,1))
    analyses <- list('Non-white & Non-Treatment',
                       'Non-white & Yes-Treatment',
                       'White & Non-Treatment',
                       'White & Yes-Treatment'
                    )

    # Go through different analyses
    for (i in 1:4) {

        abar <- c(abars[2*(i-1) + 1], abars[2*i]) 
        analysis <- analyses[i]

        for (sofa in sofa_ranges) {

            start <- sofa[1]
            end <- sofa[2]
            data_sofa <- rebuild_data(data_between_sofa(sepsis_data, start, end), treatment)

            # Run LTMLE by 2x2 w/ SL library
            result_run_ltmle_abar_00_wlib <- run_ltmle_abar_w_slLib(data_sofa, abar, Anodes, Lnodes)
            log <- summary(result_run_ltmle_abar_00_wlib)
        
            # Append to df
            df[nrow(df) + 1,] <- c(cohort,
                        treatment,
                        analysis,
                        start,
                        end,
                        log$treatment["estimate"][1],
                        log$treatment["std.dev"],
                        log$treatment["pvalue"][1],
                        toString(log$treatment["CI"])
                        ) 
        }
    }
    write.csv(df, paste0('results/', cohort,'/ltmle_', treatment,'_by_sofa.csv'))
}