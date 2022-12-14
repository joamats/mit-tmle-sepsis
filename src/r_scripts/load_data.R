library(magrittr) 
library(dplyr)
library(gdata)

load_data <- function(cohort){

  file_path <- paste0("data/", cohort, "_data.csv")

  # Load Data  
  sepsis_data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

  ventilation_bin <- sepsis_data[, c(1)] 
  death_bin <- sepsis_data[, c(1)]
  ethnicity_white <- sepsis_data[, c(1)]

  sepsis_data <- cbind(sepsis_data, ventilation_bin, death_bin, ethnicity_white)

  if (file_path == "data/MIMIC_data.csv") {

    sepsis_data <- sepsis_data %>% mutate(gender = ifelse(gender == "F", 1, 0))
    
    sepsis_data <- sepsis_data %>% mutate(ventilation_bin = ifelse(InvasiveVent_hr > 0 & !is.na(InvasiveVent_hr), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(pressor=="True", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(rrt = ifelse(is.na(rrt), 0, 1))
    sepsis_data <- sepsis_data %>% mutate(death_bin = ifelse(discharge_location == "DIED" | discharge_location == "HOSPICE" | dod != "", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", 1, 0))
    sepsis_data$charlson_cont <- sepsis_data$charlson_comorbidity_index # create unified and continous Charlson column
    
    sepsis_data <- sepsis_data %>% mutate(charlson_comorbidity_index = ifelse(
      charlson_comorbidity_index >= 0 & charlson_comorbidity_index <= 5, "0 - 5", ifelse(
        charlson_comorbidity_index >= 6 & charlson_comorbidity_index <= 10, "6 - 10", ifelse(
          charlson_comorbidity_index >= 11 & charlson_comorbidity_index <= 15, "11 - 15", "16 and above"))))
          
    sepsis_data$los <- as.numeric(difftime(sepsis_data$dischtime, sepsis_data$admittime, units = 'days')) # Length of stay MIMIC
    sepsis_data$los[sepsis_data$los < 0] <- 0 # clean data to have minimum of 0 days

    sepsis_data <- sepsis_data %>% mutate(hypertension = ifelse(!is.na(hypertension), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(heart_failure = ifelse(!is.na(heart_failure), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(ckd = ifelse(!is.na(ckd), ckd, 0))
    sepsis_data <- sepsis_data %>% mutate(copd = ifelse(!is.na(copd), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(asthma = ifelse(!is.na(asthma), 1, 0))

    sepsis_data$OASIS_W <- sepsis_data$oasis
    sepsis_data$OASIS_N <- sepsis_data$oasis
    sepsis_data$OASIS_B <- sepsis_data$oasis


  } else if (file_path == "data/eICU_data.csv") {
    
    sepsis_data <- sepsis_data %>% mutate(gender = ifelse(gender == "Female", 1, 0))

    sepsis_data <- sepsis_data %>% mutate(ventilation_bin = ifelse(is.na(VENT_final), 0, 1))
    sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(is.na(PRESSOR_final), 0, 1))
    sepsis_data <- sepsis_data %>% mutate(rrt = ifelse(is.na(RRT_final), 0, 1))
    sepsis_data <- sepsis_data %>% mutate(death_bin = ifelse(unitdischargelocation == "Death" | unitdischargestatus == "Expired" | hospitaldischargestatus == "Expired", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(race == "Caucasian", 1, 0))

    sepsis_data$charlson_cont <- sepsis_data$charlson_comorbidity_index # create unified and continous Charlson column
    sepsis_data <- sepsis_data %>% mutate(charlson_comorbidity_index = ifelse(
      charlson_comorbidity_index >= 0 & charlson_comorbidity_index <= 5, "0 - 5", ifelse(
        charlson_comorbidity_index >= 6 & charlson_comorbidity_index <= 10, "6 - 10", ifelse(
          charlson_comorbidity_index >= 11 & charlson_comorbidity_index <= 15, "11 - 15", "16 and above"))))

    sepsis_data <- sepsis_data %>% mutate(anchor_age = ifelse(anchor_age == "> 89", 91, strtoi(anchor_age)))
    sepsis_data <- sepsis_data %>% mutate(anchor_year_group = as.character(anchor_year_group))
    
    sepsis_data$los <- (sepsis_data$hospitaldischargeoffset/1440) # Generate eICU Lenght of stay

    sepsis_data <- sepsis_data %>% mutate(hypertension = ifelse(!is.na(hypertension), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(heart_failure = ifelse(!is.na(heart_failure), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(ckd = ifelse(!is.na(ckd), ckd, 0))
    sepsis_data <- sepsis_data %>% mutate(copd = ifelse(!is.na(copd), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(asthma = ifelse(!is.na(asthma), 1, 0))

    sepsis_data$OASIS_W <- sepsis_data$score_OASIS_W      # worst case scenario
    sepsis_data$OASIS_N <- sepsis_data$score_OASIS_Nulls  # embracing the nulls
    sepsis_data$OASIS_B <- sepsis_data$score_OASIS_B      # best case scenario



  } else {
    print("Wrong path or file name.")
  }

  # Return just keeping columns of interest
  return(sepsis_data[, c("gender", "los", "ventilation_bin", "pressor", "rrt", "death_bin", "ethnicity_white", "race",
                         "charlson_cont", "charlson_comorbidity_index", "anchor_age", "SOFA", "anchor_year_group",
                         "hypertension", "heart_failure", "ckd", "copd", "asthma", "adm_elective",
                         "OASIS_W", "OASIS_N", "OASIS_B")])
}

get_merged_datasets <- function() {

  mimic_data <- load_data("MIMIC")
  eicu_data <- load_data("eICU")
  # merge both datasets 
  data <- combine(mimic_data, eicu_data)

  # add column to keep the cohort source and control for it
  data <- data %>% mutate(source = ifelse(source == "mimic_data", 1, 0))

  write.csv(data, "data/MIMIC_eICU.csv")

  return (data)

}

get_merged_datasets()