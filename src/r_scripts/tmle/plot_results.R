library(ggplot2)


plot_tmle_years_results <- function(results, treatment, cohort) {

    sofaIndex <- 1
    sofa_ranges <- c(c(0, 5), c(6,10), c(11, 15))#, c(16, 100))

    if (cohort == "MIMIC") {
        aygIDXS <- 4
    } else if (cohort == "eICU") {
        aygIDXS <- 2
    }

    while (sofaIndex <= 3) {

        aygIndex <- 1

        if (cohort == "MIMIC") {
            F <- runif(3,1,2) 
            L <- runif(3,0,1)
            U <- runif(3,2,3)
        } else if (cohort == "eICU") {
            F <- runif(2,1,2) 
            L <- runif(2,0,1)
            U <- runif(2,2,3)
        }

        while (aygIndex <= aygIDXS) {

            if (cohort == "MIMIC") {
                resultIndex <- (sofaIndex - 1) * 12 +  (aygIndex - 1) * 3 + 3
            } else if (cohort == "eICU") {
                resultIndex <- (sofaIndex - 1) * 6 +  aygIndex * 3 
            }

            ciLow <- results[resultIndex]$result$estimates$ATE$CI[1]
            ciHigh <- results[resultIndex]$result$estimates$ATE$CI[2]
            psi <- results[resultIndex]$result$estimates$ATE$psi[1]

            print(ciLow)
            print(ciHigh)
            print(psi)

            F[aygIndex] <- psi
            L[aygIndex] <- ciLow
            U[aygIndex] <- ciHigh

            aygIndex <- aygIndex + 1
        }
    
        title <- paste0(treatment, " SOFA = [",sofa_ranges[sofaIndex * 2 - 1], ",", sofa_ranges[sofaIndex * 2],"]")

        if (cohort == "MIMIC") {

            df <- data.frame(x = c("2008 - 2010", "2011 - 2013", "2014 - 2016", "2017 - 2019"), F = F, L = L, U = U)

        } else if (cohort == "eICU") {
            
            df <- data.frame(x = c("2014", "2015"), F = F, L = L, U = U)
        }

        p <- ggplot(df,aes(x = x, y = F)) + geom_point(size = 4) + geom_errorbar(aes(ymax = U, ymin = L)) + labs(title=title) + labs(x = "anchor_year_group", y = "ATE") + geom_hline(aes(yintercept = 0, color="red")) + ylim(-0.5, 0.5)
    
        ggsave(paste0(treatment, "_sofa_", sofaIndex, ".png"), path=paste0("results/", cohort, "/tmle/by_sofa_and_years"))

        sofaIndex <- sofaIndex + 1
  
    }

}

