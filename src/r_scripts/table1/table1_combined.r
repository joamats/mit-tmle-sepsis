### Code for creating Table 1 in combined data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)


m_e_df = read_csv('data/MIMIC_eICU.csv', 
                  show_col_types = FALSE)

# Age groups
m_e_df$age_new <- m_e_df$anchor_age
m_e_df$age_new[m_e_df$age_new >= 18 
                & m_e_df$age_new <= 44] <- "18 - 44"
m_e_df$age_new[m_e_df$age_new >= 45 
                & m_e_df$age_new <= 64] <- "45 - 64"
m_e_df$age_new[m_e_df$age_new >= 65 
                & m_e_df$age_new <= 74] <- "65 - 74"
m_e_df$age_new[m_e_df$age_new >= 75 
                & m_e_df$age_new <= 84] <- "75 - 84"
m_e_df$age_new[m_e_df$age_new >= 85] <- "85 and higher"

##########SOFA############
m_e_df$SOFA_new = m_e_df$SOFA
m_e_df$SOFA_new[m_e_df$SOFA >= 0 
                 & m_e_df$SOFA <= 3] <- "0 - 3"
m_e_df$SOFA_new[m_e_df$SOFA >= 4 
                 & m_e_df$SOFA <= 6] <- "4 - 6"
m_e_df$SOFA_new[m_e_df$SOFA >= 7 
                 & m_e_df$SOFA <= 10] <- "7 - 10"
m_e_df$SOFA_new[m_e_df$SOFA >= 11] <- "11 and above"

##########OASIS############
m_e_df$OASIS_cat = m_e_df$OASIS_N
m_e_df$OASIS_cat[m_e_df$OASIS_N >= 0 
                & m_e_df$OASIS_N <= 37] <- "0 - 37"
m_e_df$OASIS_cat[m_e_df$OASIS_N >= 38 
                & m_e_df$OASIS_N <= 45] <- "38 - 45"
m_e_df$OASIS_cat[m_e_df$OASIS_N >= 46 
                & m_e_df$OASIS_N <= 51] <- "46 - 51"
m_e_df$OASIS_cat[m_e_df$OASIS_N >= 52] <- "52 and above"

##########Charlson############
m_e_df$charlson_new = m_e_df$charlson_cont
m_e_df$charlson_new[m_e_df$charlson_cont >= 0 
                & m_e_df$charlson_cont <= 3] <- "0 - 3"

m_e_df$charlson_new[m_e_df$charlson_cont >= 4 
                & m_e_df$charlson_cont <= 6] <- "4 - 6"

m_e_df$charlson_new[m_e_df$charlson_cont >= 7 
                & m_e_df$charlson_cont <= 10] <- "7 - 10"

m_e_df$charlson_new[m_e_df$charlson_cont >= 11] <- "11 and above"

# LOS groups
m_e_df$los[m_e_df$los < 0] <- 0 # clean data to have minimum of 0 days
m_e_df$los_d <- m_e_df$los
m_e_df <- m_e_df %>% mutate(los_d = ifelse(death_bin == 1, los_d, NA)) 

m_e_df$los_s <- m_e_df$los 
m_e_df <- m_e_df %>% mutate(los_s = ifelse(death_bin == 0, los_s, NA))

# Factorize and label variables
m_e_df$death_bin <- factor(m_e_df$death_bin, levels = c(0, 1), 
                           labels = c('Survived', 'Died'))

m_e_df$gender <- factor(m_e_df$gender, levels = c(0, 1), 
                         labels = c('Female', 'Male'))

m_e_df$hypertension <- factor(m_e_df$hypertension, levels = c(0, 1), 
                        labels = c('Hypertension absent', 'Hypertension present'))

m_e_df$heart_failure <- factor(m_e_df$heart_failure, levels = c(0, 1), 
                        labels = c('CHF absent', 'CHF present'))

m_e_df$copd <- factor(m_e_df$copd, levels = c(0, 1), 
                        labels = c('COPD absent', 'COPD present'))

m_e_df$asthma <- factor(m_e_df$asthma, levels = c(0, 1), 
                        labels = c('Asthma absent', 'Asthma present'))

m_e_df$adm_elective <- factor(m_e_df$adm_elective, levels = c(0, 1), 
                        labels = c('Emergency admission', 'Elective admission'))

m_e_df$ckd <- factor(m_e_df$ckd, levels = c(0, 1, 2, 3, 4, 5), 
                      labels = c('CKD absent', 'CKD Stage 1', 'CKD Stage 2', 'CKD Stage 3', 'CKD Stage 4', 'CKD Stage 5'))

m_e_df$pressor <- factor(m_e_df$pressor)
m_e_df$rrt <- factor(m_e_df$rrt)
m_e_df$ventilation_bin <- factor(m_e_df$ventilation_bin)
m_e_df$source <- factor(m_e_df$source, levels = c(0, 1), 
                        labels = c('eICU', 'MIMIC') )

m_e_df$ethnicity_white <- factor(m_e_df$ethnicity_white, levels = c(0, 1), 
                           labels = c('Non-White', 'White'))

m_e_df$SOFA_new <- factor(m_e_df$SOFA_new, levels = c('0 - 3', '4 - 6','7 - 10', '11 and above' ))
m_e_df$OASIS_cat <- factor(m_e_df$OASIS_cat, levels = c('0 - 37', '38 - 45','46 - 51', '52 and above' ))
m_e_df$charlson_new <- factor(m_e_df$charlson_new, levels = c('0 - 3', '4 - 6','7 - 10', '11 and above' ))


label(m_e_df$age_new)    <- "Age by group"
units(m_e_df$age_new)       <- "years"

label(m_e_df$anchor_age)       <- "Age overall"
units(m_e_df$anchor_age)       <- "years"

label(m_e_df$gender)       <- "Sex"

label(m_e_df$SOFA)          <- "SOFA continuous"
label(m_e_df$SOFA_new)          <- "SOFA categorical"
label(m_e_df$OASIS_N)          <- "OASIS continuous"
label(m_e_df$OASIS_cat)          <- "OASIS categorical"

label(m_e_df$los)       <- "Length of stay"
units(m_e_df$los)       <- "days"

label(m_e_df$los_d)       <- "Length of stay, if died"
units(m_e_df$los_d)       <- "days"

label(m_e_df$los_s)       <- "Length of stay, if survived"
units(m_e_df$los_s)       <- "days"

label(m_e_df$charlson_cont)       <- "Charlson index continuous"
label(m_e_df$charlson_new) <- "Charlson index categorical"

label(m_e_df$pressor)         <- "Vasopressor"
label(m_e_df$ventilation_bin) <- "Invasive ventilation"
label(m_e_df$rrt)             <- "Renal replacement therapy"
label(m_e_df$death_bin)       <- "In-hospital mortality"
label(m_e_df$source)          <- "Cohort"
label(m_e_df$adm_elective)     <- "Admission type"
label(m_e_df$hypertension)     <- "Hypertension"
label(m_e_df$heart_failure)   <- "Congestive heart failure"
label(m_e_df$copd)            <- "COPD"
label(m_e_df$asthma)          <- "Asthma"
label(m_e_df$ckd)             <- "Chronic kidney disease"

# Functions to add commas between 1,000
render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
                            sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create table1 object for both cohorts
tbl1 <- table1(~ death_bin + source + adm_elective + pressor + ventilation_bin + rrt +
                 age_new + anchor_age + gender + SOFA_new + SOFA + OASIS_cat + OASIS_N + los + los_s + los_d +
                 charlson_new + charlson_cont + hypertension + heart_failure + copd + asthma + ckd
               | ethnicity_white, data=m_e_df, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# render.missing=NULL, 
# use if you want to suppress missing lines

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_m_e.docx")


# Create table1 object for MIMIC 
tbl1 <- table1(~ death_bin + source + adm_elective + pressor + ventilation_bin + rrt +
                 age_new + anchor_age + gender + SOFA_new + SOFA + OASIS_cat + OASIS_N + los + los_s + los_d +
                 charlson_new + charlson_cont + hypertension + heart_failure + copd + asthma + ckd
               | ethnicity_white, data= subset(m_e_df, source=='MIMIC'), topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert MIMIC table to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_MIMIC.docx")


# Create table1 object for eICU 
tbl1 <- table1(~ death_bin + source + adm_elective + pressor + ventilation_bin + rrt +
                 age_new + anchor_age + gender + SOFA_new + SOFA + OASIS_cat + OASIS_N + los + los_s + los_d +
                 charlson_new + charlson_cont + hypertension + heart_failure + copd + asthma + ckd
               | ethnicity_white, data= subset(m_e_df, source=='eICU'), topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert MIMIC table to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_eICU.docx")


###############################
# Table to check positivity assumption
###############################

label(m_e_df$SOFA_new)        <- "SOFA"
label(m_e_df$pressor)         <- "VP"
label(m_e_df$ventilation_bin) <- "MV"
label(m_e_df$death_bin)       <- "In-hospital mortality"
label(m_e_df$rrt)             <- "RRT"
label(m_e_df$ethnicity_white) <- "Race"

# Create table1 object
tbl1 <- table1(~ rrt + ventilation_bin + pressor + ethnicity_white | death_bin*SOFA_new , data=m_e_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/Table_posA_m_e.docx")
