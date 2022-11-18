# write.csv function kept crashing when trying to store results in one csv
# hence, we combine the results here

library(tibble)
library(tidyr)

# Combine LTMLE Results

# MIMIC first
df_M_ltmle_p_bysofa <- read.csv(file="results/MIMIC/ltmle_pressor_by_sofa.csv", header = TRUE)
df_M_ltmle_p <- read.csv(file="results/MIMIC/ltmle_pressor.csv", header = TRUE)
df_M_ltmle_p <- add_column(df_M_ltmle_p, sofa_start = NA, sofa_end = NA, .after = "analysis")

df_M_ltmle_rrt_bysofa <- read.csv(file="results/MIMIC/ltmle_rrt_by_sofa.csv", header = TRUE)
df_M_ltmle_rrt <- read.csv(file="results/MIMIC/ltmle_rrt.csv", header = TRUE)
df_M_ltmle_rrt <- add_column(df_M_ltmle_rrt, sofa_start = NA, sofa_end = NA, .after = "analysis")

df_M_ltmle_v_bysofa <- read.csv(file="results/MIMIC/ltmle_ventilation_bin_by_sofa.csv", header = TRUE)
df_M_ltmle_v <- read.csv(file="results/MIMIC/ltmle_ventilation_bin.csv", header = TRUE)
df_M_ltmle_v <- add_column(df_M_ltmle_v, sofa_start = NA, sofa_end = NA, .after = "analysis")

df_ltmle_all <- rbind(df_M_ltmle_p_bysofa, df_M_ltmle_p, df_M_ltmle_rrt_bysofa, df_M_ltmle_rrt, df_M_ltmle_v_bysofa, df_M_ltmle_v)

# eICU second
df_E_ltmle_p_bysofa <- read.csv(file="results/eICU/ltmle_pressor_by_sofa.csv", header = TRUE)
df_E_ltmle_p <- read.csv(file="results/eICU/ltmle_pressor.csv", header = TRUE)
df_E_ltmle_p <- add_column(df_E_ltmle_p, sofa_start = NA, sofa_end = NA, .after = "analysis")

df_E_ltmle_rrt_bysofa <- read.csv(file="results/eICU/ltmle_rrt_by_sofa.csv", header = TRUE)
df_E_ltmle_rrt <- read.csv(file="results/eICU/ltmle_rrt.csv", header = TRUE)
df_E_ltmle_rrt <- add_column(df_E_ltmle_rrt, sofa_start = NA, sofa_end = NA, .after = "analysis")

df_E_ltmle_v_bysofa <- read.csv(file="results/eICU/ltmle_ventilation_bin_by_sofa.csv", header = TRUE)
df_E_ltmle_v <- read.csv(file="results/eICU/ltmle_ventilation_bin.csv", header = TRUE)
df_E_ltmle_v <- add_column(df_E_ltmle_v, sofa_start = NA, sofa_end = NA, .after = "analysis")

df_ltmle_all <- rbind(df_ltmle_all, df_E_ltmle_p_bysofa, df_E_ltmle_p, df_E_ltmle_rrt_bysofa, df_E_ltmle_rrt, df_E_ltmle_v_bysofa, df_E_ltmle_v)

# Remove unnecessary column and split string results
df_ltmle_all <- subset(df_ltmle_all, select=-c(X))
df_ltmle_all$CI <- gsub( "c", "", as.character(df_ltmle_all$CI) ) 
df_ltmle_all$CI <- gsub("[()]", "", as.character(df_ltmle_all$CI) ) 
df_ltmle_all <- separate(df_ltmle_all, CI, c("lCI", "uCI"), sep = "," )

write.csv(df_ltmle_all, "results/LTMLE_combined.csv", row.names = FALSE)


# Combine TMLE Results

# MIMIC first
df_M_tmle_p_bysofa <- read.csv(file="results/MIMIC/tmle_pressor_by_sofa.csv", header = TRUE, skip = 1)
df_M_tmle_rrt_bysofa <- read.csv(file="results/MIMIC/tmle_rrt_by_sofa.csv", header = TRUE, skip = 1)
df_M_tmle_v_bysofa <- read.csv(file="results/MIMIC/tmle_ventilation_bin_by_sofa.csv", header = TRUE, skip = 1)

# eICU second
df_E_tmle_p_bysofa <- read.csv(file="results/eICU/tmle_pressor.csv", header = TRUE, skip = 1)
df_E_tmle_rrt_bysofa <- read.csv(file="results/eICU/tmle_rrt.csv", header = TRUE, skip = 1)
df_E_tmle_v_bysofa <- read.csv(file="results/eICU/tmle_ventilation_bin.csv", header = TRUE, skip = 1)

df_tmle_all <- rbind(df_M_tmle_p_bysofa, df_M_tmle_rrt_bysofa, df_M_tmle_v_bysofa, df_E_tmle_p_bysofa, df_E_tmle_rrt_bysofa, df_E_tmle_v_bysofa)
df_tmle_all <- subset(df_tmle_all, select=-c(X1))
df_tmle_all <- separate(df_tmle_all, ci, c("lCI", "uCI"), sep = "," )

write.csv(df_tmle_all, "results/TMLE_combined.csv", row.names = FALSE)


