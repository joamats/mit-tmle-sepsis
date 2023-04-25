source("src/r_scripts/load_data.R")

library(tmle)
library(datawizard)


data_between <- function(sepsis_data, sev_low, sev_high) {

    res <- sepsis_data[sepsis_data$prob_mort <= sev_high & sepsis_data$prob_mort >= sev_low, ]
    
    return(na.omit(res))
}

# TMLE
run_tmle <- function(data, treatment) {


    confounders <- c("anchor_age","gender","ethnicity_white","prob_mort","charlson_cont",
                     "hypertension", "heart_failure", "ckd", "copd", "asthma")

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

    # Transform continuous LOS to be between 0 and 1
    data$los[data$los < 0] <- 0 # clean data to have minimum of 0 days
    # create a var Y that is los if > 3 days
    data <- data %>% mutate(los = ifelse(los > 3, 1, 0))
    Y <- data$los

    result <- tmle(Y = Y,
                   A = A,
                   W = W,
                   family = "gaussian", 
                   gbound = c(0.05, 0.95),
                   g.SL.library = c("SL.glm"),
                   Q.SL.library = c("SL.glm"),
                  )

    return(result)
}

tmle_stratified <- function(sepsis_data, treatment, race, df, cohort) {

    sev_ranges <- list(list(0, .1), list(.1, .2), list(.2, .3), list(.3, 1))

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
        write.csv(df, paste0("results/LOS/", fn,".csv"))
    }     
    return(df)
}


cohorts <- c("MIMIC","MIMIC_eICU", "eICU")

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