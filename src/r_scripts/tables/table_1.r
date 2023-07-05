### Code for creating Table 1 in combined data
library(tidyverse)
library(table1)
library(flextable)

cohort <- c("MIMIC") 
m_e_df <- read.csv(paste0("data/", cohort, ".csv"))

##########Age groups############
m_e_df$age_cat <- m_e_df$admission_age
m_e_df$age_cat[m_e_df$age_cat >= 18 
                & m_e_df$age_cat <= 44] <- "18 - 44"
m_e_df$age_cat[m_e_df$age_cat >= 45 
                & m_e_df$age_cat <= 64] <- "45 - 64"
m_e_df$age_cat[m_e_df$age_cat >= 65 
                & m_e_df$age_cat <= 74] <- "65 - 74"
m_e_df$age_cat[m_e_df$age_cat >= 75 
                & m_e_df$age_cat <= 84] <- "75 - 84"
m_e_df$age_cat[m_e_df$age_cat >= 85] <- "85 and higher"

##########Charlson############
m_e_df$charlson_new = m_e_df$charlson_cont
m_e_df$charlson_new[m_e_df$charlson_cont >= 0 
                & m_e_df$charlson_cont <= 3] <- "0 - 3"

m_e_df$charlson_new[m_e_df$charlson_cont >= 4 
                & m_e_df$charlson_cont <= 6] <- "4 - 6"

m_e_df$charlson_new[m_e_df$charlson_cont >= 7 
                & m_e_df$charlson_cont <= 10] <- "7 - 10"

m_e_df$charlson_new[m_e_df$charlson_cont >= 11] <- "11 and above"

##########LOS groups############
m_e_df$los[m_e_df$los < 0] <- 0 # clean data to have minimum of 0 days
m_e_df$los_d <- m_e_df$los
m_e_df <- m_e_df %>% mutate(los_d = ifelse(mortality_in == 1, los_d, NA)) 

m_e_df$los_s <- m_e_df$los 
m_e_df <- m_e_df %>% mutate(los_s = ifelse(mortality_in == 0, los_s, NA))

# Factorize and label variables
m_e_df$mortality_in <- factor(m_e_df$mortality_in, levels = c(0, 1), 
                           labels = c('Survived', 'Died'))

m_e_df$discharge_hosp <- factor(m_e_df$discharge_hosp, levels = c(0, 1), 
                           labels = c('No Hospice', 'Hospice'))

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

 # Encode CKD stages as binary
m_e_df <- within(m_e_df, ckd_stages <- factor(ckd_stages, levels = c(0, 1), labels = c('CKD absent', 'CKD present')))

m_e_df$vp_elig <- factor(m_e_df$vp_elig)
m_e_df$rrt_elig <- factor(m_e_df$rrt_elig)
m_e_df$blood_yes <- factor(m_e_df$blood_yes)
m_e_df$mv_elig <- factor(m_e_df$mv_elig)


# Factorize adverse events variables
m_e_df$clabsi <- factor(m_e_df$clabsi, levels = c(0, 1), 
                           labels = c('No CLABSI', 'CLABSI'))
m_e_df$cauti <- factor(m_e_df$cauti, levels = c(0, 1), 
                           labels = c('No CAUTI', 'CAUTI'))
m_e_df$ssi <- factor(m_e_df$ssi, levels = c(0, 1), 
                           labels = c('No SSI', 'SSI'))                                            
m_e_df$vap <- factor(m_e_df$vap, levels = c(0, 1), 
                           labels = c('No VAP', 'VAP'))
m_e_df$comb_noso <- factor(m_e_df$comb_noso,
                            labels = c('No NOSO', 'NOSO'))

m_e_df$source <- cohort

m_e_df$ethnicity_white <- factor(m_e_df$ethnicity_white, levels = c(0, 1), 
                           labels = c('Non-White', 'White'))

m_e_df$charlson_new <- factor(m_e_df$charlson_new, levels = c('0 - 3', '4 - 6','7 - 10', '11 and above' ))

label(m_e_df$age_cat)     <- "Age by group"
units(m_e_df$age_cat)     <- "years"

label(m_e_df$admission_age)  <- "Age overall"
units(m_e_df$admission_age)  <- "years"

label(m_e_df$gender)      <- "Sex"

label(m_e_df$SOFA)        <- "SOFA"
label(m_e_df$OASIS_N)     <- "OASIS"

label(m_e_df$los)         <- "Length of stay"
units(m_e_df$los)         <- "days"

label(m_e_df$los_d)       <- "Length of stay, if died"
units(m_e_df$los_d)       <- "days"

label(m_e_df$los_s)       <- "Length of stay, if survived"
units(m_e_df$los_s)       <- "days"

label(m_e_df$charlson_cont)<- "Charlson index continuous"
label(m_e_df$charlson_new) <- "Charlson index categorical"

label(m_e_df$vp_elig)         <- "Vasopressor"
label(m_e_df$mv_elig)         <- "Mechanical ventilation"
label(m_e_df$rrt_elig)        <- "Renal replacement therapy"
label(m_e_df$blood_yes)       <- "Red blood cell transfusion"
label(m_e_df$mortality_in)    <- "In-hospital mortality"
label(m_e_df$discharge_hosp)  <- "Discharge to hospice"
label(m_e_df$source)          <- "Cohort"
label(m_e_df$adm_elective)    <- "Admission type"
label(m_e_df$hypertension)    <- "Hypertension"
label(m_e_df$heart_failure)   <- "Congestive heart failure"
label(m_e_df$copd)            <- "COPD"
label(m_e_df$asthma)          <- "Asthma"
label(m_e_df$ckd_stages)      <- "Chronic kidney disease"
label(m_e_df$race_group)      <- "Race group"
label(m_e_df$free_days_hosp_28)<- "Hospital free days"
label(m_e_df$free_days_mv_28) <- "Ventilation free days"
label(m_e_df$free_days_rrt_28) <- "RRT free days"
label(m_e_df$free_days_vp_28) <- "Vasopressor free days"
label(m_e_df$clabsi)          <- "Central line-associated bloodstream infection"
label(m_e_df$cauti)           <- "Catheter-associated urinary tract infection"
label(m_e_df$ssi)             <- "Surgical site infection"
label(m_e_df$vap)             <- "Ventilator-associated pneumonia"
label(m_e_df$comb_noso)       <- "Combined nosocomial infection"

# Functions to add commas between 1,000
render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
                            sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create table1 object 
tbl1 <- table1(~ race_group + mortality_in + discharge_hosp + adm_elective + vp_elig + mv_elig + rrt_elig + blood_yes +
                free_days_hosp_28 + free_days_mv_28 + free_days_vp_28 + free_days_rrt_28 + clabsi + cauti + ssi + vap + comb_noso +
                 age_cat + admission_age + gender + OASIS_N + SOFA + los + los_s + los_d +
                 charlson_new + charlson_cont + hypertension + heart_failure + copd + asthma + ckd_stages
               | ethnicity_white, data= m_e_df, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat, render.continuous=c(.="Mean (SD)", .="Median (Q1, Q3)"))

# render.missing=NULL, 
# use if you want to suppress missing lines

# Convert table to flextable
t1flex(tbl1) %>% 
  save_as_docx(path= paste0("results/tables/Table1_", cohort, ".docx"))
