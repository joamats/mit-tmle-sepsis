### Code for checking positivity assumption in supplement in combined data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df = read_csv('/Users/Tristan/Documents/Projekte/Boston Celi/1 Causal Inference/Race Interventions/mit-tmle/data/MIMIC_eICU.csv', show_col_types = FALSE)
m_e_df = df

##########SOFA############
m_e_df$SOFA_new = m_e_df$SOFA
m_e_df$SOFA_new[m_e_df$SOFA >= 0 
                & m_e_df$SOFA <= 5] <- "0 - 5"

m_e_df$SOFA_new[m_e_df$SOFA >= 6 
                & m_e_df$SOFA <= 10] <- "6 - 10"

m_e_df$SOFA_new[m_e_df$SOFA >= 11 
                & m_e_df$SOFA <= 15] <- "11 - 15"

m_e_df$SOFA_new[m_e_df$SOFA >= 16] <- "16 and above"

# Factorize and label variables
m_e_df$death_bin <- factor(m_e_df$death_bin, levels = c(0, 1), 
                           labels = c('Survived', 'Died'))

m_e_df$pressor <- factor(m_e_df$pressor)
m_e_df$rrt <- factor(m_e_df$rrt)
m_e_df$ventilation_bin <- factor(m_e_df$ventilation_bin)

m_e_df$ethnicity_white <- factor(m_e_df$ethnicity_white, levels = c(0, 1), 
                                 labels = c('Non-White', 'White'))

m_e_df$SOFA_new <- factor(m_e_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
m_e_df$charlson_comorbidity_index<- factor(m_e_df$charlson_comorbidity_index, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))

label(m_e_df$SOFA_new)          <- "SOFA"
label(m_e_df$pressor) <- "VP"
label(m_e_df$ventilation_bin)       <- "MV"
label(m_e_df$death_bin)       <- "In-hospital mortality"
label(m_e_df$rrt)      <- "RRT"
label(m_e_df$ethnicity_white)       <- "Race"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
                                                                        sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create table1 object
tbl1 <- table1(~ rrt + ventilation_bin + pressor + ethnicity_white | death_bin*SOFA_new , data=m_e_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% 
  save_as_docx(path="results/Table_posA_m_e.docx")


