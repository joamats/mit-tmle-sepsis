# Logistic regression in R
library(tidyverse)
library(dplyr)
library(aod)

df = read_csv('data/MIMIC_eICU.csv')
df2 = df

##########SOFA############
df2$SOFA_new = df2$SOFA
df2$SOFA_new[df2$SOFA >= 0 
                  & df2$SOFA <= 5] <- "0 - 5"

df2$SOFA_new[df2$SOFA >= 6 
                  & df2$SOFA <= 10] <- "6 - 10"

df2$SOFA_new[df2$SOFA >= 11 
                  & df2$SOFA <= 15] <- "11 - 15"

df2$SOFA_new[df2$SOFA >= 16] <- "16 and above"

# Define factor variables
df2$SOFA_new <- factor(df2$SOFA_new)
df2$charlson_comorbidity_index <- factor(df2$charlson_comorbidity_index)
df2$anchor_year_group <- factor(df2$anchor_year_group)

### Ventilation

# Regression for SOFA all separately -> Ventilation
mylogit <- glm(ventilation_bin ~ ethnicity_white + anchor_age + 
                 gender + anchor_year_group + SOFA + charlson_comorbidity_index + rrt + pressor, 
               data = df2, family = "binomial")

# summary(mylogit) // for a glimpse at the results

res_store <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store$model <- "SOFA all"
res_store$cohort <- "combined"
res_store$outcome <- "Ventilation"

# Regression SOFA 0-5

#Get all column names to run regression on
SOFA_list = levels(df2$SOFA_new)

#Loop over them and create model for each
log_models = lapply(SOFA_list, function(x){
  glm(ventilation_bin ~ ethnicity_white + anchor_age + 
        gender + anchor_year_group + SOFA + charlson_comorbidity_index + rrt + pressor,
      data = subset(df2, SOFA_new == x) ,na.action = na.omit)
  
})

#Name the list of models to the column name
names(log_models) = SOFA_list

# Create dataframe with results 
for (i in 1:length(SOFA_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "Ventilation"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

### RRT

# Regression for SOFA all separately -> RRT
mylogit <- glm(rrt ~ ethnicity_white + anchor_age + 
                 gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + pressor, 
               data = df2, family = "binomial")

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "SOFA all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "RRT"
res_store <- rbind(res_store, res_store_new)

# Regression SOFA 0-5

# Loop over them and create model for each
log_models = lapply(SOFA_list, function(x){
  glm(rrt ~ ethnicity_white + anchor_age + 
        gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + pressor,
      data = subset(df2, SOFA_new == x) ,na.action = na.omit)
  
})

#Name the list of models to the column name
names(log_models) = SOFA_list

# Create dataframe with results 
for (i in 1:length(SOFA_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "RRT"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

### Vasopressors

# Regression for SOFA all separately -> Vasopressors
mylogit <- glm(pressor ~ ethnicity_white + anchor_age + 
                 gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + rrt, 
               data = df2, family = "binomial")

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "SOFA all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "VP"
res_store <- rbind(res_store, res_store_new)

# Regression SOFA 0-5

# Loop over them and create model for each
log_models = lapply(SOFA_list, function(x){
  glm(pressor ~ ethnicity_white + anchor_age + 
        gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + rrt,
      data = subset(df2, SOFA_new == x) ,na.action = na.omit)
  
})

#Name the list of models to the column name
names(log_models) = SOFA_list

# Create dataframe with results 
for (i in 1:length(SOFA_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "VP"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

res_store$SOFA_start[res_store$model == "SOFA all"] <- 100
res_store$SOFA_start[res_store$model == "1"] <- 0
res_store$SOFA_start[res_store$model == "2"] <- 6
res_store$SOFA_start[res_store$model == "3"] <- 10
res_store$SOFA_start[res_store$model == "4"] <- 16


write.csv(res_store, 
          'results/logit_res.csv',
          row.names=TRUE)


