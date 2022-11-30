
### Code for creating Table 1 in combined data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)


df = read_csv('data/MIMIC_eICU.csv', show_col_types = FALSE)
m_e_df = df

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
                 & m_e_df$SOFA <= 5] <- "0 - 5"

m_e_df$SOFA_new[m_e_df$SOFA >= 6 
                 & m_e_df$SOFA <= 10] <- "6 - 10"

m_e_df$SOFA_new[m_e_df$SOFA >= 11 
                 & m_e_df$SOFA <= 15] <- "11 - 15"

m_e_df$SOFA_new[m_e_df$SOFA >= 16] <- "16 and above"

##########Charlson Index###################
m_e_df$charlson_new = m_e_df$charlson_comorbidity_index
m_e_df$charlson_new[m_e_df$charlson_comorbidity_index >= 0 
                     & m_e_df$charlson_comorbidity_index <= 5] <- "0 - 5"

m_e_df$charlson_new[m_e_df$charlson_comorbidity_index >= 6 
                     & m_e_df$charlson_comorbidity_index <= 10] <- "6 - 10"

m_e_df$charlson_new[m_e_df$charlson_comorbidity_index >= 11 
                     & m_e_df$charlson_comorbidity_index <= 15] <- "11 - 15"

m_e_df$charlson_new[m_e_df$charlson_comorbidity_index >= 16] <- "16 and above"

# LOS groups
m_e_df$los[m_e_df$los < 0] <- 0 # clean data to have minimum of 0 days
m_e_df$los_d <- m_e_df$los
m_e_df <- m_e_df %>% mutate(los_d = ifelse(death_bin == 1, los_d, NA)) 

m_e_df$los_s <- m_e_df$los 
m_e_df <- m_e_df %>% mutate(los_s = ifelse(death_bin == 0, los_s, NA))

# Factorize and label variables
m_e_df$death_bin <- factor(m_e_df$death_bin, levels = c(0, 1), 
                           labels = c('Survived', 'Died'))

m_e_df$gender <- factor(df$gender, levels = c(0, 1), 
                         labels = c('Female', 'Male'))

m_e_df$source <- factor(m_e_df$source, levels = c(0, 1), 
                           labels = c('eICU', 'MIMIC'))

m_e_df$pressor <- factor(m_e_df$pressor)
m_e_df$rrt <- factor(m_e_df$rrt)
m_e_df$ventilation_bin <- factor(m_e_df$ventilation_bin)

m_e_df$ethnicity_white <- factor(m_e_df$ethnicity_white, levels = c(0, 1), 
                           labels = c('Non-White', 'White'))

m_e_df$SOFA_new <- factor(m_e_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
m_e_df$charlson_new <- factor(m_e_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))

label(m_e_df$age_new)    <- "Age by group"
units(m_e_df$age_new)       <- "years"

label(m_e_df$anchor_age)       <- "Age overall"
units(m_e_df$anchor_age)       <- "years"

label(m_e_df$gender)       <- "Sex"

label(m_e_df$SOFA)          <- "SOFA overall"
label(m_e_df$SOFA_new)          <- "SOFA"

label(m_e_df$los)       <- "Length of stay"
units(m_e_df$los)       <- "days"

label(m_e_df$los_d)       <- "Length of stay, if died"
units(m_e_df$los_d)       <- "days"

label(m_e_df$los_s)       <- "Length of stay, if survived"
units(m_e_df$los_s)       <- "days"

label(m_e_df$charlson_cont)       <- "Charlson index continuous"
label(m_e_df$charlson_new) <- "Charlson index categorical"

label(m_e_df$pressor) <- "Vasopressor"

label(m_e_df$ventilation_bin)       <- "Invasive ventilation"

label(m_e_df$death_bin)       <- "In-hospital mortality"
label(m_e_df$source)    <- "Cohort"
label(m_e_df$rrt)      <- "Renal replacement therapy"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
                                                                        sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create table1 object
tbl1 <- table1(~ death_bin + source + pressor + ventilation_bin + rrt +
                 age_new + anchor_age + gender + SOFA_new + SOFA  + los + los_s + los_d +
                 charlson_new + charlson_cont
               | ethnicity_white, data=m_e_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table1_m_e.docx")


