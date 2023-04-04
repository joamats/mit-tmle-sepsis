library(tmle)

read_confounders <- function(j, treatments, confounders) {

    other_t <- treatments$treatment[-j]

    final_confounders <- other_t

    for (i in 1:nrow(confounders)) {
        final_confounders <- append(final_confounders, confounders$confounder[i])
    }

    return(final_confounders)
}