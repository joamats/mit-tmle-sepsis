### Code for checking positivity assumption in supplement in combined data
library(tidyverse)
library(table1)
library(flextable)

cohort <- c("MIMIC")
m_e_df <- read.csv(paste0("data/", cohort, ".csv"))

# Read in probabilty bins
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")

m_e_df$mort_bins <- m_e_df$prob_mort
m_e_df$mort_bins[m_e_df$mort_bins >= prob_mort_ranges$min[1]
                & m_e_df$mort_bins <= prob_mort_ranges$max[1]] <- "0 - 6"
m_e_df$mort_bins[m_e_df$mort_bins > prob_mort_ranges$min[2]
                & m_e_df$mort_bins <= prob_mort_ranges$max[2]] <- "7 - 11"
m_e_df$mort_bins[m_e_df$mort_bins > prob_mort_ranges$min[3]
                & m_e_df$mort_bins <= prob_mort_ranges$max[3]] <- "12 - 21"
m_e_df$mort_bins[m_e_df$mort_bins > prob_mort_ranges$min[4]
                & m_e_df$mort_bins <= prob_mort_ranges$max[4]] <- "> 21"

m_e_df$mort_bins <- factor(m_e_df$mort_bins, levels = c('0 - 6', '7 - 11','12 - 21', '> 21' ))

# Factorize and label variables
m_e_df$mortality_in <- factor(m_e_df$mortality_in, levels = c(0, 1), 
                           labels = c('Survived', 'Died'))

m_e_df$vp_elig <- factor(m_e_df$vp_elig, levels = c(0, 1), 
                           labels = c('absent', 'present'))
m_e_df$rrt_elig <- factor(m_e_df$rrt_elig, levels = c(0, 1), 
                           labels = c('absent', 'present'))
m_e_df$mv_elig <- factor(m_e_df$mv_elig, levels = c(0, 1), 
                           labels = c('absent', 'present'))

m_e_df$ethnicity_white <- factor(m_e_df$ethnicity_white, levels = c(0, 1), 
                                 labels = c('Racial-ethnic group', 'White group'))

label(m_e_df$vp_elig)         <- "Vasopressor(s)"
label(m_e_df$mv_elig)         <- "Mechanical ventilation"
label(m_e_df$mortality_in)    <- "In-hospital mortality"
label(m_e_df$rrt_elig)        <- "Renal replacement therapy"
label(m_e_df$ethnicity_white) <- "Race"

# Functions to add commas between 1,000
render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), 
  function(y) with(y, sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create table1 object
tbl1 <- table1(~ mv_elig + rrt_elig + vp_elig + ethnicity_white | mortality_in*mort_bins  , 
data=m_e_df, render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/tables/Table_posA.docx")
