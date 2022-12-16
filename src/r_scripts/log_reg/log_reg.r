
# Logistic regression in R
library(tidyverse)
library(table1)
library(dplyr)
library(aod)

df = read_csv('data/MIMIC_eICU.csv')
df2 = df

##########SOFA############
df2$SOFA_new = df2$SOFA
df2$SOFA_new[df2$SOFA >= 0 
             & df2$SOFA <= 3] <- "0 - 3"
df2$SOFA_new[df2$SOFA >= 4 
             & df2$SOFA <= 6] <- "4 - 6"
df2$SOFA_new[df2$SOFA >= 7 
             & df2$SOFA <= 10] <- "7 - 10"
df2$SOFA_new[df2$SOFA >= 11] <- "11 and above"
##########Charlson############
df2$charlson_new = df2$charlson_cont
df2$charlson_new[df2$charlson_cont >= 0 
                 & df2$charlson_cont <= 3] <- "0 - 3"
df2$charlson_new[df2$charlson_cont >= 4 
                 & df2$charlson_cont <= 6] <- "4 - 6"
df2$charlson_new[df2$charlson_cont >= 7 
                 & df2$charlson_cont <= 10] <- "7 - 10"
df2$charlson_new[df2$charlson_cont >= 11] <- "11 and above"

##########OASIS############
df2$OASIS_cat = df2$OASIS_B
df2$OASIS_cat[df2$OASIS_B >= 0 
              & df2$OASIS_B <= 37] <- "0 - 37"
df2$OASIS_cat[df2$OASIS_B >= 38 
              & df2$OASIS_B <= 45] <- "38 - 45"
df2$OASIS_cat[df2$OASIS_B >= 46 
              & df2$OASIS_B <= 51] <- "46 - 51"
df2$OASIS_cat[df2$OASIS_B >= 52] <- "52 and above"

# Assign eICU years to MIMIC year bins
df2$anchor_year_group[df2$anchor_year_group == "2014"] <- "2014 - 2016" 
df2$anchor_year_group[df2$anchor_year_group == "2015"] <- "2014 - 2016" 

# Define factor variables
df2$SOFA_new <- factor(df2$SOFA_new)
df2$charlson_new <- factor(df2$charlson_new)
df2$OASIS_cat <- factor(df2$OASIS_cat)
df2$anchor_year_group <- factor(df2$anchor_year_group)
df2$hypertension <- factor(df2$hypertension)
df2$heart_failure <- factor(df2$heart_failure)
df2$copd <- factor(df2$copd)
df2$asthma <- factor(df2$asthma)
df2$ckd <- factor(df2$ckd)

#Get all column names to run regression on
SOFA_list = levels(df2$SOFA_new)
OASIS_list = levels(df2$OASIS_cat)

### Ventilation

# Regression for SOFA all separately -> Ventilation
mylogit <- glm(ventilation_bin ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
                 gender + anchor_year_group + SOFA + charlson_comorbidity_index + rrt + pressor, 
               data = df2, family=binomial(link='logit'))

# summary(mylogit) // for a glimpse at the results

res_store <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store$model <- "SOFA all"
res_store$cohort <- "combined"
res_store$outcome <- "Ventilation"

# Regression SOFA categories

#Loop over them and create model for each
log_models = lapply(SOFA_list, function(x){
  glm(ventilation_bin ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
        gender + anchor_year_group + SOFA + charlson_comorbidity_index + rrt + pressor,
      data = subset(df2, SOFA_new == x), na.action = na.omit, family=binomial(link='logit'))
  
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
mylogit <- glm(rrt ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
                 gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + pressor, 
               data = df2, family=binomial(link='logit'))

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "SOFA all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "RRT"
res_store <- rbind(res_store, res_store_new)

# Regression SOFA levels

# Loop over them and create model for each
log_models = lapply(SOFA_list, function(x){
  glm(rrt ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
        gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + pressor,
      data = subset(df2, SOFA_new == x) ,na.action = na.omit, family=binomial(link='logit'))
  
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
mylogit <- glm(pressor ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
                 gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + rrt, 
               data = df2, family=binomial(link='logit'))

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "SOFA all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "VP"
res_store <- rbind(res_store, res_store_new)

# Regression SOFA 0-5

# Loop over them and create model for each
log_models = lapply(SOFA_list, function(x){
  glm(pressor ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
        gender + anchor_year_group + SOFA + charlson_comorbidity_index + ventilation_bin + rrt,
      data = subset(df2, SOFA_new == x), na.action = na.omit, family=binomial(link='logit'))
  
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
res_store$SOFA_start[res_store$model == "2"] <- 4
res_store$SOFA_start[res_store$model == "3"] <- 7
res_store$SOFA_start[res_store$model == "4"] <- 11


################ OASIS ###############  
### Ventilation

# Regression for OASIS all separately -> Ventilation
mylogit <- glm(ventilation_bin ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
                 gender + anchor_year_group + OASIS_B + charlson_new + rrt + pressor, 
               data = df2, family=binomial(link='logit'))

# summary(mylogit) // for a glimpse at the results

res_store <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store$model <- "OASIS all"
res_store$cohort <- "combined"
res_store$outcome <- "Ventilation"

# Regression OASIS categories
# Loop over them and create model for each
log_models = lapply(OASIS_list, function(x){
  glm(ventilation_bin ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
        gender + anchor_year_group + OASIS_B + charlson_new + rrt + pressor,
      data = subset(df2, OASIS_cat == x), na.action = na.omit, family=binomial(link='logit'))
})

#Name the list of models to the column name
names(log_models) = OASIS_list

# Create dataframe with results 
for (i in 1:length(OASIS_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "Ventilation"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
}

### RRT

# Regression for OASIS all separately -> RRT
mylogit <- glm(rrt ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
                 gender + anchor_year_group + OASIS_B + charlson_new + ventilation_bin + pressor, 
               data = df2, family=binomial(link='logit'))

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "OASIS all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "RRT"
res_store <- rbind(res_store, res_store_new)

# Regression OASIS levels

# Loop over them and create model for each
log_models = lapply(OASIS_list, function(x){
  glm(rrt ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
        gender + anchor_year_group + OASIS_B + charlson_new + ventilation_bin + pressor,
      data = subset(df2, OASIS_cat == x) ,na.action = na.omit, family=binomial(link='logit'))
})

#Name the list of models to the column name
names(log_models) = OASIS_list

# Create dataframe with results 
for (i in 1:length(OASIS_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "RRT"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
  
}

### Vasopressors

# Regression for SOFA all separately -> Vasopressors
mylogit <- glm(pressor ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
                 gender + anchor_year_group + OASIS_B + charlson_new + ventilation_bin + rrt, 
               data = df2, family=binomial(link='logit'))

res_store_new <- as.data.frame(exp(cbind(OR = coef(mylogit), confint(mylogit))) )
res_store_new$model <- "OASIS all"
res_store_new$cohort <- "combined"
res_store_new$outcome <- "VP"
res_store <- rbind(res_store, res_store_new)

# Regression OASIS groups

# Loop over them and create model for each
log_models = lapply(OASIS_list, function(x){
  glm(pressor ~ ethnicity_white + anchor_age + hypertension + heart_failure + copd + asthma + ckd +
        gender + anchor_year_group + OASIS_B + charlson_new + ventilation_bin + rrt,
      data = subset(df2, OASIS_cat == x), na.action = na.omit, family=binomial(link='logit'))
})


#Name the list of models to the column name
names(log_models) = OASIS_list

# Create dataframe with results 
for (i in 1:length(OASIS_list)) {
  res_store_new <- as.data.frame(exp(cbind(OR = coef(log_models[[i]]), confint(log_models[[i]]))) )
  res_store_new$cohort <- "combined"
  res_store_new$outcome <- "VP"
  res_store_new$model <- i
  res_store <- rbind(res_store, res_store_new)
}

res_store$OASIS_start[res_store$model == "OASIS all"] <- 100
res_store$OASIS_start[res_store$model == "1"] <- 0
res_store$OASIS_start[res_store$model == "2"] <- 36
res_store$OASIS_start[res_store$model == "3"] <- 48
res_store$OASIS_start[res_store$model == "4"] <- 52

write.csv(res_store, 
          'results/logit_res.csv',
          row.names=TRUE)


