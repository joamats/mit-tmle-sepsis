# Function to rebuild data to accomodate a double analysis for LTMLE
rebuild_data <- function(sepsis_data, treatment) {

    # treatment should be "ventilation_bin", "rrt", or "pressor"
    # the order of the variables must be specifically this
    sepsis_data_new <- sepsis_data[, c("ethnicity_white", treatment)]
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
    sepsis_data_new$death_bin <- sepsis_data[,c('death_bin')]

    return(na.omit(sepsis_data_new))
}


# Get data within SOFA ranges
data_between_sofa <- function(sepsis_data, sofa_low_inclusive, sofa_high_inclusive) {

    res <- sepsis_data[sepsis_data$SOFA <= sofa_high_inclusive & sepsis_data$SOFA >= sofa_low_inclusive ,
                        c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "ventilation_bin", "death_bin", "rrt", "pressor", "anchor_year_group")]
    
    return(na.omit(res))
}

# Get data within SOFA and years ranges
data_between_sofa_and_anchor_year_group <- function(sepsis_data, sofa_low_inclusive, sofa_high_inclusive,ayg_value) {
    
    res <- sepsis_data[sepsis_data$SOFA <= sofa_high_inclusive & sepsis_data$SOFA >= sofa_low_inclusive & sepsis_data$anchor_year_group == ayg_value,
                       c("anchor_age","gender","ethnicity_white","SOFA","charlson_comorbidity_index", "ventilation_bin", "death_bin", "rrt", "pressor")]
    return(na.omit(res))
}
