### Code for creating Table 1 in combined data

source("src/r_scripts/load_data.R")
source("src/r_scripts/utils.R")

library(tidyverse)
library(table1)
library(flextable)
#library(magrittr)

# Functions to add commas between 1,000
render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
                            sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

###############################
# Table for sanity check
###############################

m_e_df = read_csv('data/MIMIC.csv', 
                  show_col_types = FALSE)

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
m_e_df$mortality_in <- factor(m_e_df$mortality_in, levels = c(0, 1), 
                           labels = c('Survived', 'Died'))
m_e_df$ethnicity_white <- factor(m_e_df$ethnicity_white, levels = c(0, 1), 
                           labels = c('Racial-ethnic group', 'White group'))                          
m_e_df$vp_elig <- factor(m_e_df$vp_elig)
m_e_df$rrt_elig <- factor(m_e_df$rrt_elig)
m_e_df$mv_elig <- factor(m_e_df$mv_elig)

# Create table1 object 
tbl1 <- table1(~ mv_elig + rrt_elig + vp_elig | mort_bins*mortality_in,
              data=m_e_df, 
              render.missing=NULL, topclass="Rtable1-grid Rtable1-shade Rtable1-times",
              render.categorical=render.categorical, render.strat=render.strat)

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/tables/Table_sanity_check.docx")

# Save also as a CSV
tbl1 %>% as.data.frame() %>% write_csv("results/tables/Table_sanity_check.csv")
