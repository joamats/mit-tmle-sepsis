### Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df = read_csv('data/MIMIC_data.csv', show_col_types = FALSE)
mimic_df = df

mimic_df$race_new = mimic_df$race
mimic_df <- mimic_df %>% mutate(race_new = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", "White", "Non-White"))


mimic_df$dis_expiration = mimic_df$discharge_location
mimic_df <- mimic_df %>% mutate(dis_expiration = ifelse(dis_expiration == "DIED" | dis_expiration == "HOSPICE", "Died", "Survived"))

# Treatments
mimic_df$pressor_lab = mimic_df$pressor
mimic_df$pressor_lab[mimic_df$pressor == 'TRUE'] <- "Yes"
#mimic_df$pressor_lab[is.na(mimic_df$pressor)] <- "No"

mimic_df$rrt_new = mimic_df$rrt
mimic_df$rrt_new[mimic_df$rrt == 1] <- "Yes"
#mimic_df$rrt_new[is.na(mimic_df$rrt)] <- "No"

mimic_df$vent_req = mimic_df$InvasiveVent_hr
mimic_df$vent_req[!is.na(mimic_df$vent_req)] <- "Yes"
#mimic_df$vent_req[is.na(mimic_df$vent_req)] <- "No"

# Age groups
mimic_df$age_new = mimic_df$admission_age
mimic_df$age_new[mimic_df$admission_age >= 18 
                 & mimic_df$admission_age <= 44] <- "18 - 44"

mimic_df$age_new[mimic_df$admission_age >= 45 
                 & mimic_df$admission_age <= 64] <- "45 - 64"

mimic_df$age_new[mimic_df$admission_age >= 65 
                 & mimic_df$admission_age <= 74] <- "65 - 74"

mimic_df$age_new[mimic_df$admission_age >= 75 
                 & mimic_df$admission_age <= 84] <- "75 - 84"

mimic_df$age_new[mimic_df$admission_age >= 85] <- "85 and higher"

##########SOFA############
mimic_df$SOFA_new = mimic_df$SOFA
mimic_df$SOFA_new[mimic_df$SOFA >= 0 
                  & mimic_df$SOFA <= 5] <- "0 - 5"

mimic_df$SOFA_new[mimic_df$SOFA >= 6 
                  & mimic_df$SOFA <= 10] <- "6 - 10"

mimic_df$SOFA_new[mimic_df$SOFA >= 11 
                  & mimic_df$SOFA <= 15] <- "11 - 15"

mimic_df$SOFA_new[mimic_df$SOFA >= 16] <- "16 and above"

##########Charlson Index###################
mimic_df$charlson_new = mimic_df$charlson_comorbidity_index
mimic_df$charlson_new[mimic_df$charlson_comorbidity_index >= 0 
                      & mimic_df$charlson_comorbidity_index <= 5] <- "0 - 5"

mimic_df$charlson_new[mimic_df$charlson_comorbidity_index >= 6 
                      & mimic_df$charlson_comorbidity_index <= 10] <- "6 - 10"

mimic_df$charlson_new[mimic_df$charlson_comorbidity_index >= 11 
                      & mimic_df$charlson_comorbidity_index <= 15] <- "11 - 15"

mimic_df$charlson_new[mimic_df$charlson_comorbidity_index >= 16] <- "16 and above"

# LOS groups
mimic_df$los_hosp = as.numeric(difftime(mimic_df$dischtime, mimic_df$admittime, units = 'days'))
mimic_df$los_hosp[mimic_df$los_hosp < 0] <- 0 # clean data to have minimum of 0 days

mimic_df$los_d <- mimic_df$los_hosp
mimic_df <- mimic_df %>% mutate(los_d = ifelse(dis_expiration == "Died", los_d, NA))

mimic_df$los_s <- mimic_df$los_hosp
mimic_df <- mimic_df %>% mutate(los_s = ifelse(dis_expiration =="Survived", los_s, NA))


# Factorize variables
mimic_df$gender <- factor(df$gender, levels = c('F', 'M'), 
                          labels = c('Female', 'Male'))

mimic_df$pressor_lab <- factor(mimic_df$pressor_lab)
mimic_df$rrt_new <- factor(mimic_df$rrt_new)

mimic_df$discharge_location <- factor(mimic_df$discharge_location)

mimic_df$dis_expiration <- factor(mimic_df$dis_expiration)

mimic_df$SOFA_new <- factor(mimic_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
mimic_df$charlson_new <- factor(mimic_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))


# Label variables
label(mimic_df$age_new)    <- "Age by group"
units(mimic_df$age_new)       <- "years"

label(mimic_df$admission_age)       <- "Age overall"
units(mimic_df$admission_age)       <- "years"

label(mimic_df$gender)       <- "Sex"

label(mimic_df$SOFA)          <- "SOFA overall"
label(mimic_df$SOFA_new)          <- "SOFA"

label(mimic_df$los_hosp)       <- "Length of stay"
units(mimic_df$los_hosp)       <- "days"

label(mimic_df$los_d)       <- "Length of stay, if died"
units(mimic_df$los_d)       <- "days"

label(mimic_df$los_s)       <- "Length of stay, if survived"
units(mimic_df$los_s)       <- "days"

label(mimic_df$race_new)       <- "Race"

label(mimic_df$charlson_comorbidity_index)       <- "Charlson index overall"

label(mimic_df$charlson_new) <- "Charlson index"

label(mimic_df$pressor_lab) <- "Vasopressor"

label(mimic_df$vent_req)       <- "Invasive ventilation"

label(mimic_df$dis_expiration)       <- "In-hospital mortality"
label(mimic_df$discharge_location)  <- "Location of discharge"

label(mimic_df$rrt_new)      <- "Renal replacement therapy"

# Age normal // LOS non-normal // SOFA non-normal // Charlson non-normal

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
                 los_d + los_s + charlson_new + charlson_comorbidity_index
               | race_new, data=mimic_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_MIMIC.docx")

