# Code for creating Table 1 in eICU data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)


df = read_csv('data/eICU_data.csv', show_col_types = FALSE)
finaleICU_df = df

finaleICU_df$race_new = finaleICU_df$race
finaleICU_df <- finaleICU_df %>% mutate(race_new = ifelse(race == "Caucasian", "White", "Non-White"))

finaleICU_df$dis_expiration = finaleICU_df$hospitaldischargelocation
finaleICU_df <- finaleICU_df %>% mutate(dis_expiration = ifelse(dis_expiration == "Death", "Died", "Survived"))

# Treatments
finaleICU_df$pressor_lab = finaleICU_df$PRESSOR_final
finaleICU_df$pressor_lab[finaleICU_df$PRESSOR_final == 1] <- "Yes"
#finaleICU_df$pressor_lab[is.na(finaleICU_df$PRESSOR_final)] <- "No"

finaleICU_df$rrt_new = finaleICU_df$RRT_final
finaleICU_df$rrt_new[finaleICU_df$RRT_final == 1] <- "Yes"
#finaleICU_df$rrt_new[is.na(finaleICU_df$RRT_final)] <- "No"

finaleICU_df$vent_req = finaleICU_df$VENT_final
finaleICU_df$vent_req[finaleICU_df$VENT_final == 1] <- "Yes"
#finaleICU_df$vent_req[is.na(finaleICU_df$VENT_final)] <- "No"

# Age groups
finaleICU_df$age <- as.numeric(finaleICU_df$age) # destring age, replace >89 == 91 
finaleICU_df$age[is.na(finaleICU_df$age)] <- 91

finaleICU_df$age_new <- finaleICU_df$age

finaleICU_df$age_new[finaleICU_df$age_new >= 18 
                 & finaleICU_df$age_new <= 44] <- "18 - 44"

finaleICU_df$age_new[finaleICU_df$age_new >= 45 
                 & finaleICU_df$age_new <= 64] <- "45 - 64"

finaleICU_df$age_new[finaleICU_df$age_new >= 65 
                 & finaleICU_df$age_new <= 74] <- "65 - 74"

finaleICU_df$age_new[finaleICU_df$age_new >= 75 
                 & finaleICU_df$age_new <= 84] <- "75 - 84"

finaleICU_df$age_new[finaleICU_df$age_new >= 85] <- "85 and higher"

##########SOFA############
finaleICU_df$SOFA_new = finaleICU_df$SOFA
finaleICU_df$SOFA_new[finaleICU_df$SOFA >= 0 
                  & finaleICU_df$SOFA <= 5] <- "0 - 5"

finaleICU_df$SOFA_new[finaleICU_df$SOFA >= 6 
                  & finaleICU_df$SOFA <= 10] <- "6 - 10"

finaleICU_df$SOFA_new[finaleICU_df$SOFA >= 11 
                  & finaleICU_df$SOFA <= 15] <- "11 - 15"

finaleICU_df$SOFA_new[finaleICU_df$SOFA >= 16] <- "16 and above"

##########Charlson Index###################
finaleICU_df$charlson_new = finaleICU_df$charlson_comorbidity_index
finaleICU_df$charlson_new[finaleICU_df$charlson_comorbidity_index >= 0 
                      & finaleICU_df$charlson_comorbidity_index <= 5] <- "0 - 5"

finaleICU_df$charlson_new[finaleICU_df$charlson_comorbidity_index >= 6 
                      & finaleICU_df$charlson_comorbidity_index <= 10] <- "6 - 10"

finaleICU_df$charlson_new[finaleICU_df$charlson_comorbidity_index >= 11 
                      & finaleICU_df$charlson_comorbidity_index <= 15] <- "11 - 15"

finaleICU_df$charlson_new[finaleICU_df$charlson_comorbidity_index >= 16] <- "16 and above"

finaleICU_df$los_hosp = (finaleICU_df$hospitaldischargeoffset/1440)

finaleICU_df$los_hosp[finaleICU_df$los_hosp < 0] <- 0 # clean data to have minimum of 0 days
finaleICU_df$gender <- factor(df$gender, levels = c('Female', 'Male'), 
                          labels = c('Female', 'Male'))

finaleICU_df$pressor_lab <- factor(finaleICU_df$pressor_lab)
finaleICU_df$rrt_new <- factor(finaleICU_df$rrt_new)

finaleICU_df$discharge_location <- factor(finaleICU_df$hospitaldischargelocation)

finaleICU_df$dis_expiration <- factor(finaleICU_df$dis_expiration)

finaleICU_df$SOFA_new <- factor(finaleICU_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
finaleICU_df$charlson_new <- factor(finaleICU_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))


# Factorize and label variables
label(finaleICU_df$age_new)    <- "Age by group"
units(finaleICU_df$age_new)       <- "years"

label(finaleICU_df$age)       <- "Age overall"
units(finaleICU_df$age)       <- "years"

label(finaleICU_df$gender)       <- "Sex"

label(finaleICU_df$SOFA)          <- "SOFA overall"
label(finaleICU_df$SOFA_new)          <- "SOFA"


label(finaleICU_df$los_hosp)       <- "Length of stay"
units(finaleICU_df$los_hosp)       <- "days"

label(finaleICU_df$race_new)       <- "Race"

label(finaleICU_df$charlson_comorbidity_index)       <- "Charlson index overall"

label(finaleICU_df$charlson_new) <- "Charlson index"

label(finaleICU_df$pressor_lab) <- "Vasopressor"

label(finaleICU_df$vent_req)       <- "Invasive ventilation"

label(finaleICU_df$dis_expiration)       <- "In-hospital mortality"
label(finaleICU_df$discharge_location)  <- "Location of discharge"

label(finaleICU_df$rrt_new)      <- "Renal replacement therapy"

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
         age_new + age + gender + SOFA_new + SOFA  + los_hosp + 
         charlson_new + charlson_comorbidity_index
       | race_new, data=finaleICU_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
       render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_eICU.docx")