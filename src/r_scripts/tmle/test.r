require(dplyr) # needed to use %>% mutate function below
library(ltmle)
require(dplyr)
library("tmle")
library("psych")


load_data <- function(){
  # Load Data  
  raw_data <- read.csv("data/MIMIC_data.csv", header = TRUE, stringsAsFactors = TRUE)
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

# by SOFA only, define a function to extract data only that meet selected SOFA group
data_between_sofa_with_rrt_pressor <- function(
    sofa_low_inclusive, sofa_high_inclusive) {
  res <- sepsis_data[sepsis_data$SOFA <= sofa_high_inclusive & sepsis_data$SOFA >= sofa_low_inclusive, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","anchor_year_group", "ventilation_bin", "death_bin", "rrt", "pressor")]
  return(na.omit(res))
}

sepsis_data <- load_data()

run_tmle_sofa_with_rtt_pressor <- function(sofa_low_inclusive, sofa_high_inclusive) {
  # TMLE 
  data_sofa = data_between_sofa_with_rrt_pressor(sofa_low_inclusive, sofa_high_inclusive)
  print(paste0('Ventilation effect for SOFA between [', sofa_low_inclusive, ",", sofa_high_inclusive,"], nrow = ", nrow(data_sofa)))
  W <- data_sofa[, c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","anchor_year_group", "rrt", "ventilation_bin")]
  A <- data_sofa$pressor
  Y <- data_sofa$death_bin
  result <- tmle(Y, A, W , family = "binomial", 
                 g.SL.library = c("SL.glm", "SL.glmnet", "SL.bayesglm","SL.mean"),
                 Q.SL.library = c("SL.glm", "SL.glmnet", "SL.stepAIC","SL.mean","SL.earth","SL.ranger","SL.gam",
                  "SL.bayesglm","SL.glm.interaction", "SL.biglasso"))
  data_result <- list("data" = data_sofa, "result" = result)
  return(data_result)
}

sofa_ranges <- list(list(0, 5), list(6,10), list(11, 15), list(16, 100))
results_by_sofa <- list()
for (sofa in sofa_ranges) {
    start <- sofa[1]
    end <- sofa[2]
    data_sofa_ayg = data_between_sofa_with_rrt_pressor(start, end)
    input = paste0("V3 Working on sofa: [", start, ",", end, "]; Total count:", nrow(data_sofa_ayg))
    print(input)
    result = run_tmle_sofa_with_rtt_pressor(start, end)
    print(paste0(paste0("Sofa: [", start, ",", end, "]: "),result$result$estimates$ATE[c("psi", "CI")]))
    results_by_sofa <- append(results_by_sofa, input)
    results_by_sofa <- append(results_by_sofa, result)
}