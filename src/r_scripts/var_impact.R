#remotes::install_github("ck37/varimpact")
library(varimpact)

source("src/r_scripts/load_data.R")

data <- read.csv('data/MIMIC_eICU.csv')

vim <- varimpact(Y=data$death_bin,
                 data %>% select(c(gender,
                                   ventilation_bin,
                                   pressor,
                                   rrt,
                                   ethnicity_white,
                                   charlson_cont, 
                                   anchor_age,
                                   SOFA,
                                   source,
                                   hypertension,
                                   copd,
                                   ckd, 
                                   asthma, 
                                   heart_failure
                                  )
                                ),
                quantile_probs_numeric = c(0,1),
                verbose_tmle = TRUE
                )

print(vim)

exportLatex(vim, "varimpact", "results/var_impact")
