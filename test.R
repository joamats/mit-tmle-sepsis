library(magrittr)
library(dplyr)


load_data <- function(file_path){
  # Load Data  
  raw_data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)
  # Add Gender, Ventilation, Mortality, Ethnicity
  sepsis_data <- raw_data %>% mutate(gender = ifelse(gender == "F", 1, 0))
  ventilation_bin <- raw_data[, c(1)] # just copy any column and will put them into the raw_data, and will modify it as necessary below
  death_bin <- raw_data[, c(1)]
  ethnicity_white <- raw_data[, c(1)]
  # Combine previous variables
  sepsis_data <- cbind(sepsis_data, ventilation_bin, death_bin, ethnicity_white)
  # One-Hot Encoding Ventilation
  sepsis_data <- sepsis_data %>% mutate(ventilation_bin = ifelse(InvasiveVent_hr > 0 & !is.na(InvasiveVent_hr), 1, 0))
  # One-Hot Encoding Mortality: died or survived
  sepsis_data <- sepsis_data %>% mutate(death_bin = ifelse(discharge_location == "DIED" | discharge_location == "HOSPICE", 1, ifelse(discharge_location == "", NaN, 0)))
  # One-Hot Encoding Ethnicity: white or non-white
  sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(ethnicity == "WHITE", 1, 0))
  # Put CCI into bins
  sepsis_data <- sepsis_data %>% mutate(charlson_comorbidity_index = ifelse(
    charlson_comorbidity_index >= 0 & charlson_comorbidity_index <= 5, "0 - 5", ifelse(
      charlson_comorbidity_index >= 6 & charlson_comorbidity_index <= 10, "6 - 10", ifelse(
        charlson_comorbidity_index >= 11 & charlson_comorbidity_index <= 15, "11 - 15", "16 and above")
      )  
    )
  )

  # One-Hot Encoding Pressor
  # in raw_data, pressor is either True or "", map it to 1 or 0 
  sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(pressor == "TRUE", 1, 0))
  sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(is.na(pressor), 0, 1))
  # One-Hot Encoding RRT
  sepsis_data <- sepsis_data %>% mutate(rrt = ifelse(is.na(rrt), 0, 1))

  return(sepsis_data)
}

data_between_sofa <- function(sepsis_data, sofa_low_inclusive, sofa_high_inclusive) {

    res <- sepsis_data[sepsis_data$SOFA <= sofa_high_inclusive & sepsis_data$SOFA >= sofa_low_inclusive,
        c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","anchor_year_group", "ventilation_bin", "death_bin", "rrt", "pressor")]
    
    return(na.omit(res))
}

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

# run TMLE by SOFA only (main analysis)
tmle_stratified_sofas <- function(sepsis_data, treatment){

    sofa_ranges <- list(list(0, 5), list(6,10), list(11, 15), list(16, 100))

    for (sofa in sofa_ranges) {

        start <- sofa[1]
        end <- sofa[2]

        #log_name <- paste0('results/tmle/by_sofa/', treatment, '_sofa_', start, '_', end, '.txt')
        #file_log <- file(log_name)

        data_sofa <- data_between_sofa(sepsis_data, start, end)

        result <- run_tmle_sofa(data_sofa, start, end, treatment)

        full_log <- c(paste0('TMLE Stratfied SOFAs, ', treatment), 
                      paste0("SOFA = [", start, " ,", end, "]\nn =  ", nrow(data_sofa)),
                      paste0("PSI = ", toString(result$result$estimates$ATE$psi)),
                      paste0("CI = ", toString(result$result$estimates$ATE$CI)),
                      paste0("AUC = ", toString(result$result$g$AUC)),
                      paste0("R2 = ", toString(result$result$Qinit$Rsq))
                     )
        print(full_log)
        #writeLines(full_log, file_log)
        #close(file_log)
    }    
}

treatments <- "pressor"

# List with possible datasets
data_path <- "data/MIMIC_data.csv" # add eICU when ready

sepsis_data <- load_data(file_path = data_path)

tmle_stratified_sofas(sepsis_data, treatment)