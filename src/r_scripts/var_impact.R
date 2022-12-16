#remotes::install_github("ck37/varimpact")
library(varimpact)

source("src/r_scripts/load_data.R")

data <- read.csv('data/MIMIC_eICU.csv')

libs <- c("SL.svm", "SL.xgboost")

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
                Q.library = libs,
                g.library = libs,
                verbose_reduction = TRUE
                )

print(vim)

exportLatex(vim, "varimpact", "results/var_impact")