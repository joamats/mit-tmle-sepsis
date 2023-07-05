library(magrittr) 
library(dplyr)
library(gdata)

load_data <- function(cohort){

  file_path <- paste0("data/", cohort, "_coh.csv")

  # Load Data  
  sepsis_data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

  # Define outcomes
  discharge_hosp <- sepsis_data[, c(1)]
  ethnicity_white <- sepsis_data[, c(1)]
  blood_yes <- sepsis_data[, c(1)]
  comb_noso <- sepsis_data[, c(1)]

  free_days_hosp_28 <- sepsis_data[, c(1)]
  free_days_mv_28 <- sepsis_data[, c(1)]
  free_days_rrt_28 <- sepsis_data[, c(1)]
  free_days_vp_28 <- sepsis_data[, c(1)]

  sepsis_data <- cbind(sepsis_data, discharge_hosp, comb_noso,
                      ethnicity_white, blood_yes, free_days_hosp_28,
                      free_days_mv_28, free_days_rrt_28, free_days_vp_28)

  # Common data cleaning steps

  # labs
  # PO2 is within its physiological range
  sepsis_data$po2_min[sepsis_data$po2_min < 0] <- 0
  sepsis_data$po2_min[sepsis_data$po2_min > 1000] <- 0
  sepsis_data$po2_min[sepsis_data$po2_min == 0 |
                      is.na(sepsis_data$po2_min)] <- 90

  # PCO2 is within its physiological range
  sepsis_data$pco2_max[sepsis_data$pco2_max < 0] <- 0
  sepsis_data$pco2_max[sepsis_data$pco2_max > 200] <- 0 
  sepsis_data$pco2_max[sepsis_data$pco2_max == 0 |
                        is.na(sepsis_data$pco2_max)] <- 40

  # pH is within its physiological range
  sepsis_data$ph_min[sepsis_data$ph_min < 5] <- 0
  sepsis_data$ph_min[sepsis_data$ph_min > 10] <- 0
  sepsis_data$ph_min[sepsis_data$ph_min == 0 |
                      is.na(sepsis_data$ph_min)] <- 7.35

  # Lactate is within its physiological range
  sepsis_data$lactate_max[sepsis_data$lactate_max < 0] <- 0
  sepsis_data$lactate_max[sepsis_data$lactate_max > 30] <- 0
  sepsis_data$lactate_max[sepsis_data$lactate_max == 0 |
                          is.na(sepsis_data$lactate_max)] <- 1.05

  # Glucose is within its physiological range
  sepsis_data$glucose_max[sepsis_data$glucose_max < 0] <- 0
  sepsis_data$glucose_max[sepsis_data$glucose_max > 2000] <- 0
  sepsis_data$glucose_max[sepsis_data$glucose_max == 0 |
                          is.na(sepsis_data$glucose_max)] <- 95

  # Sodium
  sepsis_data$sodium_min[is.na(sepsis_data$sodium_min)] <- 0
  sepsis_data$sodium_min[sepsis_data$sodium_min < 0] <- 0
  sepsis_data$sodium_min[sepsis_data$sodium_min > 160] <- 0
  sepsis_data$sodium_min[sepsis_data$sodium_min == 0 |
                          is.na(sepsis_data$sodium_min)] <- 140

  # Potassium
  sepsis_data$potassium_max[sepsis_data$potassium_max < 0] <- 0
  sepsis_data$potassium_max[sepsis_data$potassium_max > 9.9] <- 0
  sepsis_data$potassium_max[sepsis_data$potassium_max == 0 |
                            is.na(sepsis_data$potassium_max)] <- 3.5

  # Cortisol
  sepsis_data$cortisol_min[sepsis_data$cortisol_min < 0] <- 0
  sepsis_data$cortisol_min[sepsis_data$cortisol_min > 70] <- 0
  sepsis_data$cortisol_min[sepsis_data$cortisol_min == 0 |
                            is.na(sepsis_data$cortisol_min)] <- 20

  # Hemoglobin
  sepsis_data$hemoglobin_min[sepsis_data$hemoglobin_min < 3
                            & (sepsis_data$gender == "M" | sepsis_data$gender == "Male" | sepsis_data$gender == 0)] <- 13.5
  sepsis_data$hemoglobin_min[sepsis_data$hemoglobin_min < 3
                            & (sepsis_data$gender == "F" | sepsis_data$gender == "Female" | sepsis_data$gender == 1)] <- 12 

  sepsis_data$hemoglobin_min[sepsis_data$hemoglobin_min > 30] <- 0

  sepsis_data$hemoglobin_min[(sepsis_data$hemoglobin_min == 0 |
                              is.na(sepsis_data$hemoglobin_min))
                              & (sepsis_data$gender == "M" | sepsis_data$gender == "Male" | sepsis_data$gender == 0)] <- 13.5

  sepsis_data$hemoglobin_min[(sepsis_data$hemoglobin_min == 0 |
                              is.na(sepsis_data$hemoglobin_min))
                              & (sepsis_data$gender == "F" | sepsis_data$gender == "Female" | sepsis_data$gender == 1)] <- 12
  # Fibrinogen
  sepsis_data$fibrinogen_min[sepsis_data$fibrinogen_min < 0] <- 0
  sepsis_data$fibrinogen_min[sepsis_data$fibrinogen_min > 1000] <- 400
  sepsis_data$fibrinogen_min[sepsis_data$fibrinogen_min == 0 |
                              is.na(sepsis_data$fibrinogen_min)] <- 200
  # INR
  sepsis_data$inr_max[sepsis_data$inr_max < 0] <- 0
  sepsis_data$inr_max[sepsis_data$inr_max > 10] <- 0
  sepsis_data$inr_max[sepsis_data$inr_max == 0 |
                      is.na(sepsis_data$inr_max)] <- 1.1

  # Respiratory rate
  sepsis_data$resp_rate_mean[sepsis_data$resp_rate_mean < 0] <- 0
  sepsis_data$resp_rate_mean[sepsis_data$resp_rate_mean > 50] <- 0
  sepsis_data$resp_rate_mean[sepsis_data$resp_rate_mean == 0 |
                            is.na(sepsis_data$resp_rate_mean)] <- 15
  # Heart rate
  sepsis_data$heart_rate_mean[sepsis_data$heart_rate_mean < 0] <- 0
  sepsis_data$heart_rate_mean[sepsis_data$heart_rate_mean > 250] <- 0
  sepsis_data$heart_rate_mean[sepsis_data$heart_rate_mean == 0 |
                            is.na(sepsis_data$heart_rate_mean)] <- 90

  # MBP
  sepsis_data$mbp_mean[sepsis_data$mbp_mean < 0] <- 0
  sepsis_data$mbp_mean[sepsis_data$mbp_mean > 200] <- 0
  sepsis_data$mbp_mean[sepsis_data$mbp_mean == 0 |
                        is.na(sepsis_data$mbp_mean)] <- 85
  # Temperature
  sepsis_data$temperature_mean[sepsis_data$temperature_mean < 32] <- 0
  sepsis_data$temperature_mean[sepsis_data$temperature_mean > 45] <- 0
  sepsis_data$temperature_mean[sepsis_data$temperature_mean == 0 |
                              is.na(sepsis_data$temperature_mean)] <- 36.5

  # SpO2
  sepsis_data$spo2_mean[sepsis_data$spo2_mean < 0] <- 0
  sepsis_data$spo2_mean[sepsis_data$spo2_mean > 100] <- 0
  sepsis_data$spo2_mean[sepsis_data$spo2_mean == 0 |
                        is.na(sepsis_data$spo2_mean)] <- 95

  # dummy for complications
  sepsis_data <- sepsis_data %>% mutate(clabsi = ifelse(is.na(clabsi), 0, 1))
  sepsis_data <- sepsis_data %>% mutate(cauti = ifelse(is.na(cauti), 0, 1))
  sepsis_data <- sepsis_data %>% mutate(ssi = ifelse(is.na(ssi), 0, 1))
  sepsis_data <- sepsis_data %>% mutate(vap = ifelse(is.na(vap), 0, 1))

  # combine complications
  sepsis_data <- sepsis_data %>% mutate(comb_noso = ifelse(clabsi == 1 | cauti == 1 | ssi == 1 | vap == 1, 1, 0))

  # create dummy vars for comorbidities
  sepsis_data <- sepsis_data %>% mutate(hypertension_present = ifelse(!is.na(hypertension_present), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(heart_failure_present = ifelse(!is.na(heart_failure_present), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(ckd_stages = ifelse(!is.na(ckd_stages), ckd_stages, 0))
  sepsis_data <- sepsis_data %>% mutate(copd_present = ifelse(!is.na(copd_present), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(asthma_present = ifelse(!is.na(asthma_present), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(diabetes_types = ifelse(!is.na(diabetes_types), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(connective_disease = ifelse(!is.na(connective_disease), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(cad_present = ifelse(!is.na(cad_present), 1, 0))

  # transform CKD stages into binary variable, 1 if CKD stage 3 and greater, 0 otherwise
  sepsis_data <- sepsis_data %>% mutate(ckd_stages = ifelse(ckd_stages >= 3, 1, 0))

  # create dummy vars for conditions POA / source of infection
  sepsis_data <- sepsis_data %>% mutate(pneumonia = ifelse(!is.na(pneumonia), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(uti = ifelse(!is.na(uti), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(biliary = ifelse(!is.na(biliary), 1, 0))
  sepsis_data <- sepsis_data %>% mutate(skin = ifelse(!is.na(skin), 1, 0))

  # if sofa is na impute best case scenario, 0
  sepsis_data$respiration[is.na(sepsis_data$respiration)] <- 0
  sepsis_data$coagulation[is.na(sepsis_data$coagulation)] <- 0
  sepsis_data$cardiovascular[is.na(sepsis_data$cardiovascular)] <- 0
  sepsis_data$renal[is.na(sepsis_data$renal)] <- 0
  sepsis_data$cns[is.na(sepsis_data$cns)] <- 0
  sepsis_data$liver[is.na(sepsis_data$liver)] <- 0
  sepsis_data$SOFA[is.na(sepsis_data$SOFA)] <- 0

  # dummy for major surgery, if = 1, then 1, else 0
  sepsis_data <- sepsis_data %>% mutate(major_surgery = ifelse(major_surgery == 1, 1, 0))
  sepsis_data <- sepsis_data %>% mutate(major_surgery = ifelse(is.na(major_surgery), 0, 1))

  # encode anchor_year_group by: MIMIC, 2008-2010, 2011-2013, 2014-2016, 2017-2019 into 1, 2, 3, 4
  sepsis_data$anchor_year_group <- as.numeric(sepsis_data$anchor_year_group)

  sepsis_data <- sepsis_data %>% mutate(blood_yes = ifelse(is.na(transfusion_yes), 0, 1))
  sepsis_data <- sepsis_data %>% mutate(insulin_yes = ifelse(is.na(insulin_yes), 0, 1))
  

  if (file_path == "data/MIMIC_coh.csv") {
    
    sepsis_data <- sepsis_data %>% mutate(gender = ifelse(gender == "F", 1, 0))
    
    mech_vent <- sepsis_data[, c(1)] 
    sepsis_data <- cbind(sepsis_data, mech_vent)

    sepsis_data <- sepsis_data %>% mutate(mech_vent = ifelse((InvasiveVent_hr > 0 & !is.na(InvasiveVent_hr)) |
                                                                   (Trach_hr > 0 & !is.na(Trach_hr)), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(pressor=="True", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(rrt = ifelse(is.na(rrt), 0, 1))

    sepsis_data <- sepsis_data %>% mutate(discharge_hosp = ifelse(discharge_location == "HOSPICE", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", 1, 0))

    sepsis_data$charlson_cont <- sepsis_data$charlson_comorbidity_index # create unified and continous Charlson column
    
    sepsis_data <- sepsis_data %>% mutate(charlson_comorbidity_index = ifelse(
      charlson_comorbidity_index >= 0 & charlson_comorbidity_index <= 5, "0 - 5", ifelse(
        charlson_comorbidity_index >= 6 & charlson_comorbidity_index <= 10, "6 - 10", ifelse(
          charlson_comorbidity_index >= 11 & charlson_comorbidity_index <= 15, "11 - 15", "16 and above"))))
          
    sepsis_data$los <- as.numeric(difftime(sepsis_data$dischtime, sepsis_data$admittime, units = 'days')) # Length of stay MIMIC

    sepsis_data$OASIS_W <- sepsis_data$oasis
    sepsis_data$OASIS_N <- sepsis_data$oasis
    sepsis_data$OASIS_B <- sepsis_data$oasis

    # drop row if oasis_prob is nan
    sepsis_data <- sepsis_data[!is.na(sepsis_data$oasis_prob), ]

    # rename oasis_prob into prob_mort
    sepsis_data <- sepsis_data %>% rename(prob_mort = oasis_prob)

    # clean fluids_volume: if fluids_volume_norm_by_los_icu is over 4000, set it to 4000
    # and then adjust fluids_volume accordingly, given the los_icu
    sepsis_data$fluids_volume_norm_by_los_icu[sepsis_data$fluids_volume_norm_by_los_icu > 4000] <- 4000
    sepsis_data$fluids_volume <- sepsis_data$fluids_volume_norm_by_los_icu * sepsis_data$los_icu

    # add 0 to fluids_volume if it is NA
    sepsis_data$fluids_volume[is.na(sepsis_data$fluids_volume)] <- 0

    # MV_time_perc_of_stay: make 0 if na
    sepsis_data$MV_time_perc_of_stay[is.na(sepsis_data$MV_time_perc_of_stay)] <- 0
    # VP_time_perc_of_stay: make 0 if na
    sepsis_data$VP_time_perc_of_stay[is.na(sepsis_data$VP_time_perc_of_stay)] <- 0
    # MV_init_offset_perc: make 0 if na
    sepsis_data$MV_init_offset_perc[is.na(sepsis_data$MV_init_offset_perc)] <- 0
    sepsis_data$MV_init_offset_d_abs[is.na(sepsis_data$MV_init_offset_d_abs)] <- 0
    # RRT_time_perc_of_stay: make 0 if na
    sepsis_data$RRT_init_offset_perc[is.na(sepsis_data$RRT_init_offset_perc)] <- 0
    sepsis_data$RRT_init_offset_d_abs[is.na(sepsis_data$RRT_init_offset_d_abs)] <- 0
    # VP_init_offset_perc: make 0 if na
    sepsis_data$VP_init_offset_perc[is.na(sepsis_data$VP_init_offset_perc)] <- 0
    sepsis_data$VP_init_offset_d_abs[is.na(sepsis_data$VP_init_offset_d_abs)] <- 0

    # If FiO2 is not available and Oxygen_hr, HighFlow_hr, and NonInvasiveVent_hr are all na, then FiO2 = 21%
    # i.e, no oxygen therapy at all -> room air
    sepsis_data$FiO2_mean_24h[is.na(sepsis_data$FiO2_mean_24h) & is.na(sepsis_data$oxygen_hr) &
                     is.na(sepsis_data$highflow_hr) & is.na(sepsis_data$noninvasivevent_hr) &
                     is.na(sepsis_data$InvasiveVent_hr) & is.na(sepsis_data$Trach_hr)] <- 21

    # else if FiO2_mean_24h is na, set it to -1 bc we don't know how to impute it
    sepsis_data$FiO2_mean_24h[is.na(sepsis_data$FiO2_mean_24h)] <- -1

    # encode insurance as numeric
    sepsis_data$insurance <- as.numeric(sepsis_data$insurance)    

    # Encode outcomes

    # Definition of "free days" outcomes:
    # “Free day” outcomes were calculated as 28 minus the number of days on therapy (MV, RRT, or VP)
    # Patients who died in the hospital were assigned 0 “free days”

    sepsis_data$free_days_mv_28 <- pmax(round((28 - sepsis_data$mv_time_d), 0), 0)
    sepsis_data$free_days_rrt_28 <- pmax(round((28 - sepsis_data$rrt_time_d), 0), 0)
    sepsis_data$free_days_vp_28 <- pmax(round((28 - sepsis_data$vp_time_d), 0), 0)
    sepsis_data$los_icu[sepsis_data$los_icu < 0] <- 0 # clean data to have minimum of 0 days
    sepsis_data$free_days_hosp_28 <- pmax(round((28 - sepsis_data$los_icu), 0), 0)
    # round to closest integer day, use pmax to convert values < 0 to 0

    # set free days to 0 if NA
    sepsis_data <- sepsis_data %>% mutate(free_days_hosp_28 = ifelse(is.na(free_days_hosp_28), 0, free_days_hosp_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_mv_28 = ifelse(is.na(free_days_mv_28), 0, free_days_mv_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_rrt_28 = ifelse(is.na(free_days_rrt_28), 0, free_days_rrt_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_vp_28 = ifelse(is.na(free_days_vp_28), 0, free_days_vp_28))
    
    # set free days to 0 in case of death
    sepsis_data <- sepsis_data %>% mutate(free_days_hosp_28 = ifelse(mortality_in == 1, 0, free_days_hosp_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_mv_28 = ifelse(mortality_in == 1, 0, free_days_mv_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_rrt_28 = ifelse(mortality_in == 1, 0, free_days_rrt_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_vp_28 = ifelse(mortality_in == 1, 0, free_days_vp_28))

    # Therapy within eligibility period
    sepsis_data <- sepsis_data %>% mutate(mv_elig = ifelse(mech_vent == 1 & (MV_init_offset_d_abs <= 1), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(vp_elig = ifelse(pressor == 1 & (VP_init_offset_d_abs <= 1), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(rrt_elig = ifelse(rrt == 1 & (RRT_init_offset_d_abs <= 3), 1, 0))

    # Drop observations with LOS <= 1 day
    sepsis_data <- sepsis_data[sepsis_data$los_icu >= 1, ]
    sepsis_data <- sepsis_data[sepsis_data$los_icu <= 30, ]

    # odd hours for negative control outcome
    sepsis_data$dischtime <- as.POSIXct(sepsis_data$dischtime)

    # Extract hour from 'dischtime'
    sepsis_data$hour <- format(sepsis_data$dischtime, "%H")

    # Convert hour to numeric
    sepsis_data$hour <- as.numeric(sepsis_data$hour)

    # Create new column 'odd_hour' based on 'hour'
    sepsis_data$odd_hour <- ifelse(sepsis_data$hour %% 2 == 1, 1, 0)

    # Return just keeping columns of interest
    return(sepsis_data[, c("admission_age", "gender", "ethnicity_white", "race_group", "insurance", "odd_hour",
                          #  "weight_admit",  "eng_prof",
                          "anchor_year_group", 
                          "adm_elective", "major_surgery", "is_full_code_admission",
                          "is_full_code_discharge", "prob_mort", "discharge_hosp", "OASIS_N",
                          "SOFA", "respiration", "coagulation", "liver", "cardiovascular",
                          "cns", "renal", "charlson_cont",
                          "MV_time_perc_of_stay", "FiO2_mean_24h","VP_time_perc_of_stay",
                          "MV_init_offset_perc","RRT_init_offset_perc","VP_init_offset_perc",
                          "fluids_volume", 
                          "resp_rate_mean", "mbp_mean", "heart_rate_mean", "temperature_mean",
                          "spo2_mean", "po2_min", "pco2_max", "ph_min", "lactate_max", "glucose_max",
                          "sodium_min", "potassium_max", "cortisol_min", "hemoglobin_min",
                          "fibrinogen_min", "inr_max", "hypertension_present", "heart_failure_present",
                          "copd_present", "asthma_present", "cad_present", "ckd_stages", "diabetes_types",
                          "connective_disease", "pneumonia", "uti", "biliary", "skin", "mortality_in",
                          "blood_yes", "insulin_yes", "los", "mortality_90", "comb_noso", "clabsi", "cauti", "ssi", "vap",
                          "mech_vent", "rrt", "pressor", "mv_elig", "rrt_elig", "vp_elig",
                          "free_days_rrt_28", "free_days_mv_28", "free_days_vp_28", "free_days_hosp_28") 
                          ])


  } else {
    print("Wrong path or file name.")
  }

  
}

get_merged_datasets <- function() {

  mimic_data <- load_data("MIMIC")

  # add column to keep the cohort source and control for it
  #data <- data %>% mutate(source = ifelse(source == "mimic_data", 1, 0))

  write.csv(mimic_data, "data/MIMIC.csv")

  return (data)

}

get_merged_datasets()