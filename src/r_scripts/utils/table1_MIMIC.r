# Code for creating Table 1 in MIMIC data

library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df = read_csv('data/MIMIC_data.csv', show_col_types = FALSE)
final_df = df

final_df$race_new = final_df$race
final_df <- final_df %>% mutate(race_new = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", "White", "Non-White"))


final_df$dis_expiration = final_df$discharge_location
final_df <- final_df %>% mutate(dis_expiration = ifelse(dis_expiration == "DIED" | dis_expiration == "HOSPICE", "Died", "Survived"))

# Treatments
final_df$pressor_lab = final_df$pressor
final_df$pressor_lab[final_df$pressor == 'TRUE'] <- "Yes"
#final_df$pressor_lab[is.na(final_df$pressor)] <- "No"

final_df$rrt_new = final_df$rrt
final_df$rrt_new[final_df$rrt == 1] <- "Yes"
#final_df$rrt_new[is.na(final_df$rrt)] <- "No"

final_df$vent_req = final_df$InvasiveVent_hr
final_df$vent_req[!is.na(final_df$vent_req)] <- "Yes"
#final_df$vent_req[is.na(final_df$vent_req)] <- "No"

# Age groups
final_df$age_new = final_df$admission_age
final_df$age_new[final_df$admission_age >= 18 
                 & final_df$admission_age <= 44] <- "18 - 44"

final_df$age_new[final_df$admission_age >= 45 
                 & final_df$admission_age <= 64] <- "45 - 64"

final_df$age_new[final_df$admission_age >= 65 
                 & final_df$admission_age <= 74] <- "65 - 74"

final_df$age_new[final_df$admission_age >= 75 
                 & final_df$admission_age <= 84] <- "75 - 84"

final_df$age_new[final_df$admission_age >= 85] <- "85 and higher"

##########SOFA############
final_df$SOFA_new = final_df$SOFA
final_df$SOFA_new[final_df$SOFA >= 0 
                  & final_df$SOFA <= 5] <- "0 - 5"

final_df$SOFA_new[final_df$SOFA >= 6 
                  & final_df$SOFA <= 10] <- "6 - 10"

final_df$SOFA_new[final_df$SOFA >= 11 
                  & final_df$SOFA <= 15] <- "11 - 15"

final_df$SOFA_new[final_df$SOFA >= 16] <- "16 and above"

##########Charlson Index###################
final_df$charlson_new = final_df$charlson_comorbidity_index
final_df$charlson_new[final_df$charlson_comorbidity_index >= 0 
                      & final_df$charlson_comorbidity_index <= 5] <- "0 - 5"

final_df$charlson_new[final_df$charlson_comorbidity_index >= 6 
                      & final_df$charlson_comorbidity_index <= 10] <- "6 - 10"

final_df$charlson_new[final_df$charlson_comorbidity_index >= 11 
                      & final_df$charlson_comorbidity_index <= 15] <- "11 - 15"

final_df$charlson_new[final_df$charlson_comorbidity_index >= 16] <- "16 and above"

final_df$los_hosp = as.numeric(difftime(final_df$dischtime, final_df$admittime, units = 'days'))
final_df$los_hosp[final_df$los_hosp < 0] <- 0 # clean data to have minimum of 0 days
final_df$gender <- factor(df$gender, levels = c('F', 'M'), 
                          labels = c('Female', 'Male'))

final_df$pressor_lab <- factor(final_df$pressor_lab)
final_df$rrt_new <- factor(final_df$rrt_new)

final_df$discharge_location <- factor(final_df$discharge_location)

final_df$dis_expiration <- factor(final_df$dis_expiration)

final_df$SOFA_new <- factor(final_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
final_df$charlson_new <- factor(final_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))


# Factorize and label variables
label(final_df$age_new)    <- "Age by group"
units(final_df$age_new)       <- "years"

label(final_df$admission_age)       <- "Age overall"
units(final_df$admission_age)       <- "years"

label(final_df$gender)       <- "Sex"

label(final_df$SOFA)          <- "SOFA overall"
label(final_df$SOFA_new)          <- "SOFA"


label(final_df$los_hosp)       <- "Length of stay"
units(final_df$los_hosp)       <- "days"

label(final_df$race_new)       <- "Race"

label(final_df$charlson_comorbidity_index)       <- "Charlson index overall"

label(final_df$charlson_new) <- "Charlson index"

label(final_df$pressor_lab) <- "Vasopressor"

label(final_df$vent_req)       <- "Invasive ventilation"

label(final_df$InvasiveVent_hr)       <- "Invasive ventilation"
units(final_df$InvasiveVent_hr)       <- "hours"

label(final_df$dis_expiration)       <- "In-hospital mortality"
label(final_df$discharge_location)  <- "Location of discharge"

label(final_df$rrt_new)      <- "Renal replacement therapy"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ dis_expiration + pressor_lab +  vent_req + rrt_new +
         age_new + admission_age + gender + SOFA_new + SOFA  + los_hosp + 
         charlson_new + charlson_comorbidity_index  + InvasiveVent_hr
       | race_new, data=final_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
       render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_MIMIC.docx")