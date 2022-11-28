
### Code for creating Table 1 in eICU data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)


df = read_csv('data/eICU_data.csv', show_col_types = FALSE)
eicu_df = df

eicu_df$race_new = eicu_df$race
eicu_df <- eicu_df %>% mutate(race_new = ifelse(race == "Caucasian", "White", "Non-White"))

eicu_df$dis_expiration = eicu_df$hospitaldischargelocation
eicu_df <- eicu_df %>% mutate(dis_expiration = ifelse(dis_expiration == "Death", "Died", "Survived"))

# Treatments
eicu_df$pressor_lab = eicu_df$PRESSOR_final
eicu_df$pressor_lab[eicu_df$PRESSOR_final == 1] <- "Yes"
#m_e_df$pressor_lab[is.na(eicu_df$PRESSOR_final)] <- "No"

eicu_df$rrt_new = eicu_df$RRT_final
eicu_df$rrt_new[eicu_df$RRT_final == 1] <- "Yes"
#eicu_df$rrt_new[is.na(eicu_df$RRT_final)] <- "No"

eicu_df$vent_req = eicu_df$VENT_final
eicu_df$vent_req[eicu_df$VENT_final == 1] <- "Yes"
#eicu_df$vent_req[is.na(eicu_df$VENT_final)] <- "No"

# Age groups
eicu_df$age <- as.numeric(eicu_df$age) # destring age, replace >89 == 91 
eicu_df$age[is.na(eicu_df$age)] <- 91

eicu_df$age_new <- eicu_df$age

eicu_df$age_new[eicu_df$age_new >= 18 
                     & eicu_df$age_new <= 44] <- "18 - 44"

eicu_df$age_new[eicu_df$age_new >= 45 
                     & eicu_df$age_new <= 64] <- "45 - 64"

eicu_df$age_new[eicu_df$age_new >= 65 
                     & eicu_df$age_new <= 74] <- "65 - 74"

eicu_df$age_new[eicu_df$age_new >= 75 
                     & eicu_df$age_new <= 84] <- "75 - 84"

eicu_df$age_new[eicu_df$age_new >= 85] <- "85 and higher"

##########SOFA############
eicu_df$SOFA_new = eicu_df$SOFA
eicu_df$SOFA_new[eicu_df$SOFA >= 0 
                      & eicu_df$SOFA <= 5] <- "0 - 5"

eicu_df$SOFA_new[eicu_df$SOFA >= 6 
                      & eicu_df$SOFA <= 10] <- "6 - 10"

eicu_df$SOFA_new[eicu_df$SOFA >= 11 
                      & eicu_df$SOFA <= 15] <- "11 - 15"

eicu_df$SOFA_new[eicu_df$SOFA >= 16] <- "16 and above"

##########Charlson Index###################
eicu_df$charlson_new = eicu_df$charlson_comorbidity_index
eicu_df$charlson_new[eicu_df$charlson_comorbidity_index >= 0 
                          & eicu_df$charlson_comorbidity_index <= 5] <- "0 - 5"

eicu_df$charlson_new[eicu_df$charlson_comorbidity_index >= 6 
                          & eicu_df$charlson_comorbidity_index <= 10] <- "6 - 10"

eicu_df$charlson_new[eicu_df$charlson_comorbidity_index >= 11 
                          & eicu_df$charlson_comorbidity_index <= 15] <- "11 - 15"

eicu_df$charlson_new[eicu_df$charlson_comorbidity_index >= 16] <- "16 and above"

# LOS groups
eicu_df$los_hosp = (eicu_df$hospitaldischargeoffset/1440)
eicu_df$los_hosp[eicu_df$los_hosp < 0] <- 0 # clean data to have minimum of 0 days

eicu_df$los_d <- eicu_df$los_hosp
eicu_df <- eicu_df %>% mutate(los_d = ifelse(unitdischargestatus == "Expired", los_d, NA))

eicu_df$los_s <- eicu_df$los_hosp
eicu_df <- eicu_df %>% mutate(los_s = ifelse(unitdischargestatus == "Alive", los_s, NA))


# Factorize and label variables
eicu_df$gender <- factor(df$gender, levels = c('Female', 'Male'), 
                         labels = c('Female', 'Male'))

eicu_df$pressor_lab <- factor(eicu_df$pressor_lab)
eicu_df$rrt_new <- factor(eicu_df$rrt_new)

eicu_df$discharge_location <- factor(eicu_df$hospitaldischargelocation)

eicu_df$dis_expiration <- factor(eicu_df$dis_expiration)

eicu_df$SOFA_new <- factor(eicu_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
eicu_df$charlson_new <- factor(eicu_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))

label(eicu_df$age_new)    <- "Age by group"
units(eicu_df$age_new)       <- "years"

label(eicu_df$age)       <- "Age overall"
units(eicu_df$age)       <- "years"

label(eicu_df$gender)       <- "Sex"

label(eicu_df$SOFA)          <- "SOFA overall"
label(eicu_df$SOFA_new)          <- "SOFA"


label(eicu_df$los_hosp)       <- "Length of stay"
units(eicu_df$los_hosp)       <- "days"

label(eicu_df$los_d)       <- "Length of stay, if died"
units(eicu_df$los_d)       <- "days"

label(eicu_df$los_s)       <- "Length of stay, if survived"
units(eicu_df$los_s)       <- "days"

label(eicu_df$race_new)       <- "Race"

label(eicu_df$charlson_comorbidity_index)       <- "Charlson index continuous"
label(eicu_df$charlson_new) <- "Charlson index"

label(eicu_df$pressor_lab) <- "Vasopressor"

label(eicu_df$vent_req)       <- "Invasive ventilation"

label(eicu_df$dis_expiration)       <- "In-hospital mortality"
label(eicu_df$discharge_location)  <- "Location of discharge"

label(eicu_df$rrt_new)      <- "Renal replacement therapy"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
                                                                        sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create table1 object
tbl1 <- table1(~ dis_expiration + pressor_lab +  vent_req + rrt_new +
                 age_new + age + gender + SOFA_new + SOFA  + los_hosp + los_s + los_d +
                 charlson_new + charlson_comorbidity_index
               | race_new, data=eicu_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_eICU.docx")
