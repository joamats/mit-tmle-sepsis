# Function to rebuild data to accomodate a double analysis for LTMLE
rebuild_data <- function(sepsis_data, treatment) {

    # treatment should be "ventilation_bin", "rrt", or "pressor"
    # the order of the variables must be specifically this
    sepsis_data_new <- sepsis_data[, c("ethnicity_white", treatment)]
    sepsis_data_new$source1 <- sepsis_data[, c("source")]
    sepsis_data_new$gender1 <- sepsis_data[, c("gender")]
    sepsis_data_new$anchor_age1 <- sepsis_data[, c("anchor_age")]
    sepsis_data_new$charlson_comorbidity_index1 <- sepsis_data[, c("charlson_comorbidity_index")]
    sepsis_data_new$SOFA1 <- sepsis_data[, c("SOFA")]

    if (treatment == "ventilation_bin") {
        sepsis_data_new$pressor1 <- sepsis_data[, c("pressor")]
        sepsis_data_new$rrt1 <- sepsis_data[, c("rrt")]
    } else if (treatment == "rrt") {
        sepsis_data_new$pressor1 <- sepsis_data[, c("pressor")]
        sepsis_data_new$ventilation_bin1 <- sepsis_data[, c("ventilation_bin")]
    } else if (treatment == "pressor") {   
        sepsis_data_new$rrt1 <- sepsis_data[, c("rrt")]
        sepsis_data_new$ventilation_bin1 <- sepsis_data[, c("ventilation_bin")]
    }

    sepsis_data_new$anchor_year_group1  <- sepsis_data[, c("anchor_year_group")]
    sepsis_data_new$hypertension1 <- sepsis_data[, c("hypertension")]
    sepsis_data_new$heart_failure1 <- sepsis_data[, c("heart_failure")]
    sepsis_data_new$ckd1 <- sepsis_data[, c("ckd")]
    sepsis_data_new$copd1 <- sepsis_data[, c("copd")]
    sepsis_data_new$asthma1 <- sepsis_data[, c("asthma")]


    sepsis_data_new$source2 <- sepsis_data[, c("source")]
    sepsis_data_new$gender2 <- sepsis_data[, c("gender")]
    sepsis_data_new$anchor_age2 <- sepsis_data[, c("anchor_age")]
    sepsis_data_new$charlson_comorbidity_index2 <- sepsis_data[, c("charlson_comorbidity_index")]
    sepsis_data_new$SOFA2 <- sepsis_data[, c("SOFA")]

    if (treatment == "ventilation_bin") {
        sepsis_data_new$pressor2 <- sepsis_data[, c("pressor")]
        sepsis_data_new$rrt2 <- sepsis_data[, c("rrt")]
    } else if (treatment == "rrt") {
        sepsis_data_new$pressor2 <- sepsis_data[, c("pressor")]
        sepsis_data_new$ventilation_bin2 <- sepsis_data[, c("ventilation_bin")]
    } else if (treatment == "pressor") {   
        sepsis_data_new$rrt2 <- sepsis_data[, c("rrt")]
        sepsis_data_new$ventilation_bin2 <- sepsis_data[, c("ventilation_bin")]
    }

    sepsis_data_new$anchor_year_group2  <- sepsis_data[, c("anchor_year_group")]
    sepsis_data_new$hypertension2 <- sepsis_data[, c("hypertension")]
    sepsis_data_new$heart_failure2 <- sepsis_data[, c("heart_failure")]
    sepsis_data_new$ckd2 <- sepsis_data[, c("ckd")]
    sepsis_data_new$copd2 <- sepsis_data[, c("copd")]
    sepsis_data_new$asthma2 <- sepsis_data[, c("asthma")]    
    
    sepsis_data_new$death_bin <- sepsis_data[,c('death_bin')]

    return(na.omit(sepsis_data_new))
}


# Get data within SOFA ranges
data_between_sofa <- function(sepsis_data, sofa_low_inclusive, sofa_high_inclusive) {

    res <- sepsis_data[sepsis_data$SOFA <= sofa_high_inclusive & sepsis_data$SOFA >= sofa_low_inclusive,
        c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index","anchor_year_group", "ventilation_bin", "death_bin", "rrt", "pressor",
         "hypertension", "heart_failure", "ckd", "copd", "asthma")]
    
    return(na.omit(res))
}
