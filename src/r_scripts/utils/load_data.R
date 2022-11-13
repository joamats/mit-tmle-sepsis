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
  sepsis_data <- sepsis_data %>% mutate(death_bin = ifelse(discharge_location == "DIED" | discharge_location == "HOSPICE" | dod != "", 1, 0))
  # One-Hot Encoding Ethnicity: white or non-white
  sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", 1, 0))
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
  sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(is.na(rrt), 0, 1))
  # One-Hot Encoding RRT
  sepsis_data <- sepsis_data %>% mutate(rrt = ifelse(is.na(rrt), 0, 1))

  return(sepsis_data)
}