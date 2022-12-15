#remotes::install_github("ck37/varimpact")
library(varimpact)

source("src/r_scripts/utils/load_data.R")

# Get merged datasets' data
data <- get_merged_datasets()


vim <- varimpact(Y=data$death_bin,
                 data %>% select(c(gender, ventilation_bin, pressor,rrt,
                                   ethnicity_white, charlson_cont, los,
                                   anchor_age, SOFA, anchor_year_group, source,
                                   hypertension, copd, ckd, asthma, heart_failure)))

print(vim)

exportLatex(vim, "varimpact", "results/var_impact")
