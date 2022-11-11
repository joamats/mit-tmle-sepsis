library(ggplot2)


plot_tmle_years_results <- function(results, treatment) {

    sofaIndex <- 1
    sofa_ranges <- c(c(0, 5), c(6,10), c(11, 15), c(16, 100))

    while (sofaIndex <= 4) {

        aygIndex <- 1
        F <- runif(4,1,2) 
        L <- runif(4,0,1)
        U <- runif(4,2,3)

        while (aygIndex <= 4) {

            infoIndex <- (sofaIndex - 1) * 12 +  (aygIndex - 1) * 3 + 1
            dataIndex <- infoIndex + 1
            resultIndex <- infoIndex + 2
            
            ciLow <- results[resultIndex]$result$estimates$ATE$CI[1]
            ciHigh <- results[resultIndex]$result$estimates$ATE$CI[2]
            psi <- results[resultIndex]$result$estimates$ATE$psi[1]

            F[aygIndex] <- psi
            L[aygIndex] <- ciLow
            U[aygIndex] <- ciHigh

            aygIndex <- aygIndex + 1
        }
    
        title <- paste0(treatment, " SOFA = [",sofa_ranges[sofaIndex * 2 - 1], ",", sofa_ranges[sofaIndex * 2],"]")
        df <- data.frame(x = c("2008 - 2010", "2011 - 2013", "2014 - 2016", "2017 - 2019"), F = F, L = L, U = U)
        p <- ggplot(df,aes(x = x, y = F)) + geom_point(size = 4) + geom_errorbar(aes(ymax = U, ymin = L)) + labs(title=title) + labs(x = "anchor_year_group", y = "ATE") + geom_hline(aes(yintercept = 0, color="red")) + ylim(-0.5, 0.5)
    
        ggsave(paste0("tmle_years_sofa_", sofaIndex,"_", treatment, ".png"), path="src/r_scripts/tmle/plots")

        sofaIndex <- sofaIndex + 1
  
    }

}

