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
run_ltmle_abar_w_slLib <- function(sepsis_data, t,c, Anodes, Lnodes) {
    result <- ltmle(data = sepsis_data, 
                    Anodes = Anodes,  # Treatment Nodes
                    Lnodes = Lnodes, # Time-Dependent Covariate Nodes
                    Ynodes = c("death_bin"), # Outcome Nodes
                    abar = list(treament = t, control = c), # binary matrix of counterfactual
                    gbounds = c(0.05, 0.95), # Lower and Upper bounds on estimated cumulative probabilities
                    Qform=NULL,
                    gform=NULL,
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

        l1 <- c("source1","gender1", "anchor_age1", "charlson_comorbidity_index1", "SOFA1", "pressor1", "rrt1", "anchor_year_group1",
                "hypertension1", "heart_failure1", "ckd1", "copd1", "asthma1")

        l2 <- c("source2","gender2", "anchor_age2", "charlson_comorbidity_index2", "SOFA2", "pressor2", "rrt2", "anchor_year_group2",
                "hypertension2", "heart_failure2", "ckd2", "copd2", "asthma2")

    } else if (treatment == "rrt") {

        l1 <- c("source1","gender1", "anchor_age1", "charlson_comorbidity_index1", "SOFA1", "pressor1", "ventilation_bin1", "anchor_year_group1",
                "hypertension1", "heart_failure1", "ckd1", "copd1", "asthma1")

        l2 <- c("source2","gender2", "anchor_age2", "charlson_comorbidity_index2", "SOFA2", "pressor2", "ventilation_bin2", "anchor_year_group2",
                "hypertension2", "heart_failure2", "ckd2", "copd2", "asthma2")

    } else if (treatment == "pressor") {
        l1 <- c("source1","gender1", "anchor_age1", "charlson_comorbidity_index1", "SOFA1", "rrt1", "ventilation_bin1", "anchor_year_group1",
                "hypertension1", "heart_failure1", "ckd1", "copd1", "asthma1")
        
        l2 <- c("source2","gender2", "anchor_age2", "charlson_comorbidity_index2", "SOFA2", "rrt2", "ventilation_bin2", "anchor_year_group2",
                "hypertension2", "heart_failure2", "ckd2", "copd2", "asthma2")

    }

    Lnodes <- c(l1, l2)

    return(Lnodes)
}


# Run LTMLE analyses to stratified SOFAs
ltmle_stratified_sofas <- function(sepsis_data, treatment, cohort, df) {

    Anodes <- get_anodes(treatment)
    Lnodes <- get_lnodes(treatment)

    data_sofa <- rebuild_data(sepsis_data, treatment)

    # cut data by SOFA score and run LTMLE by 2x2 WITH SL library
    sofa_ranges <- list(list(0,100), list(0, 3), list(4,6), list(7, 10), list(11, 100))

    # controls
    cs <- c(c(0,0), c(1,0), c(0,0), c(0,1))
    # controls
    ts <- c(c(0,1), c(1,1), c(1,0), c(1,1))
    
    analyses <- list('Non-white',
                     'White',
                     'Non-Treatment',
                     'Yes-Treatment'
                    )

    # Go through different analyses
    for (i in 1:4) {

        t <- c(ts[2*(i-1) + 1], ts[2*i]) 
        c <- c(cs[2*(i-1) + 1], cs[2*i]) 
        analysis <- analyses[i]

        for (sofa in sofa_ranges) {

            start <- sofa[1]
            end <- sofa[2]
            data_sofa <- rebuild_data(data_between_sofa(sepsis_data, start, end), treatment)

            # Run LTMLE by 2x2 w/ SL library
            ATE <- run_ltmle_abar_w_slLib(data_sofa, t,c, Anodes, Lnodes)
            log <- summary(ATE)

            # split CIs
            ci <- gsub( "c", "", as.character(log$effect.measures$ATE["CI"])) 
            ci <- gsub( "[()]", "", ci) 
            i_ci <- as.double(strsplit(ci, split=', ')[[1]][1])
            s_ci <- as.double(strsplit(ci, split=', ')[[1]][2])
        
            # Append to df
            df[nrow(df) + 1,] <- c(cohort,
                                   treatment,
                                   analysis,
                                   start,
                                   end,
                                   log$effect.measures$ATE["estimate"][1],
                                   log$effect.measures$ATE["std.dev"],
                                   log$effect.measures$ATE["pvalue"][1],
                                   i_ci,    
                                   s_ci,
                                   nrow(data_sofa)
                                  ) 
        }

    
    }
    return (df)
}