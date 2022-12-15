# Get data within SOFA ranges
data_between_sofa <- function(sepsis_data, sofa_low_inclusive, sofa_high_inclusive) {

    res <- sepsis_data[sepsis_data$SOFA <= sofa_high_inclusive & sepsis_data$SOFA >= sofa_low_inclusive,
        c("source","anchor_age","gender","ethnicity_white","SOFA","charlson_cont",#"anchor_year_group",
          "ventilation_bin", "death_bin", "rrt", "pressor",
          "hypertension", "heart_failure", "ckd", "copd", "asthma")]
    
    return(na.omit(res))
}


data_between_oasis <- function(sepsis_data, oasis_low_inclusive, oasis_high_inclusive) {

    res <- sepsis_data[sepsis_data$OASIS_B <= oasis_high_inclusive & sepsis_data$OASIS_B >= oasis_low_inclusive,
        c("source","anchor_age","gender","ethnicity_white","OASIS_B","charlson_cont",
          "ventilation_bin", "death_bin", "rrt", "pressor",
          "hypertension", "heart_failure", "ckd", "copd", "asthma" )]
    
    return(na.omit(res))
}