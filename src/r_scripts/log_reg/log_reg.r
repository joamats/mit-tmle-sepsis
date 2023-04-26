# Logistic regression in R
library(tidyverse)
library(table1)
library(aod)
source("src/r_scripts/load_data.R")
source("src/r_scripts/utils.R")

# Main
cohort <- c("MIMIC") # choose "MIMIC", "eICU", or "MIMIC_eICU" for both
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")
# treatments <- read.delim("config/treatments.txt")
confounders <- read.delim(paste0("config/confounders_", cohort,".txt"))

# read data
df <- read.csv(paste0("data/", cohort, ".csv"))

########## Mortality bins from predicted mortality ############
df$mort_bins <- df$prob_mort
df$mort_bins[df$mort_bins >= prob_mort_ranges$min[1]
                & df$mort_bins <= prob_mort_ranges$max[1]] <- "0 - 6"
df$mort_bins[df$mort_bins > prob_mort_ranges$min[2]
                & df$mort_bins <= prob_mort_ranges$max[2]] <- "7 - 11"
df$mort_bins[df$mort_bins > prob_mort_ranges$min[3]
                & df$mort_bins <= prob_mort_ranges$max[3]] <- "12 - 21"
df$mort_bins[df$mort_bins > prob_mort_ranges$min[4]
                & df$mort_bins <= prob_mort_ranges$max[4]] <- "> 21"

# Define factor variables
df$mort_bins <- factor(df$mort_bins)
df$hypertension <- factor(df$hypertension)
df$heart_failure <- factor(df$heart_failure)
df$copd <- factor(df$copd)
df$asthma <- factor(df$asthma)
df$ckd_stages <- factor(df$ckd_stages)

#Get all column names to run regression on
mort_list = levels(df$mort_bins)

### Ventilation

# Regression for mort list all separately -> Ventilation
model_confounders <- unlist(c("rrt_elig", "vp_elig", confounders))
mylogit <- glm(formula=reformulate(termlabels = model_confounders, response='mv_elig'), 
               data = df, family=binomial(link='logit'))

# summary(mylogit) // for a glimpse at the results

res_store <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store$model <- "Prob Mort all"
res_store$cohort <- "combined"
res_store$outcome <- "Ventilation"

# Regression over mort list categories

#Loop over them and create model for each
log_models = lapply(mort_list, function(x){
  glm(formula=reformulate(termlabels = model_confounders, response='mv_elig'),
      data = subset(df, mort_bins == x), na.action = na.omit, family=binomial(link='logit'))
  
})

#Name the list of models to the column name
names(log_models) = mort_list

# Create dataframe with results 
for (i in 1:length(mort_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "Ventilation"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

### rrt_elig

# Regression for SOFA all separately -> rrt_elig
model_confounders <- unlist(c("mv_elig", "vp_elig", confounders))
mylogit <- glm(formula=reformulate(termlabels = model_confounders, response='rrt_elig'),
               data = df, family=binomial(link='logit'))

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "Prob Mort all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "rrt_elig"
res_store <- rbind(res_store, res_store_new)

# Regression SOFA levels

# Loop over them and create model for each
log_models = lapply(mort_list, function(x){
  glm(formula=reformulate(termlabels = model_confounders, response='rrt_elig'),
      data = subset(df, mort_bins == x) ,na.action = na.omit, family=binomial(link='logit'))
  
})

#Name the list of models to the column name
names(log_models) = mort_list

# Create dataframe with results 
for (i in 1:length(mort_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "rrt_elig"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

### Vp_eligs

# Regression for SOFA all separately -> vp_eligs
model_confounders <- unlist(c("mv_elig", "rrt_elig", confounders))
mylogit <- glm(formula=reformulate(termlabels = model_confounders, response='vp_elig'), 
               data = df, family=binomial(link='logit'))

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "Prob Mort all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "VP"
res_store <- rbind(res_store, res_store_new)

# Regression SOFA 0-5

# Loop over them and create model for each
log_models = lapply(mort_list, function(x){
  glm(formula=reformulate(termlabels = model_confounders, response='vp_elig'), 
      data = subset(df, mort_bins == x), na.action = na.omit, family=binomial(link='logit'))
  
})

#Name the list of models to the column name
names(log_models) = mort_list

# Create dataframe with results 
for (i in 1:length(mort_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "VP"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

res_store$prob_mort_start[res_store$model == "Prob Mort all"] <- prob_mort_ranges$max[4]
res_store$prob_mort_start[res_store$model == "1"] <- prob_mort_ranges$min[1]
res_store$prob_mort_start[res_store$model == "2"] <- prob_mort_ranges$min[2]
res_store$prob_mort_start[res_store$model == "3"] <- prob_mort_ranges$min[3]
res_store$prob_mort_start[res_store$model == "4"] <- prob_mort_ranges$min[4]

write.csv(res_store, 
          'results/logit_res_prob_mort.csv',
          row.names=TRUE)