library(RMySQL)
library(tidyverse)
library(modelr)
library(Lahman)
require(DBI)
setwd("~/Desktop/Mathletics Code-Alongs")
source('inning_simulation.R')

# Chapter 1 - Baseball's Pythagorean Theorem
# Here we find the best choice for the exponent in formula (2).

# To Math Majors and Statisticians: since the book uses absolute error and not the least squares
# error, this is done with brute force instead of some linear algebra.

conn <- dbConnect(MySQL(), 
                  dbname = "lahman",
                  user = "r-user", 
                  password = "h2p@4031",
                  host = "saberbase.cn2snhhvsjfa.us-east-2.rds.amazonaws.com",
                  port = 3306)

grid_search <- function(conn, string) {
  
  modified_string <- paste0('select yearID, teamID, W, L, R, RA,
          R/RA as scoring_ratio,
          W/(W+L) as winLoss,
          power(R/RA, ' , string, ')/(power(R/RA, ', string, ') + 1) as predicted_winLoss,
          abs(W/(W+L) - power(R/RA, ', string, ')/(power(R/RA, ', string, ') + 1)) as absolute_error
          from teams
          where yearID between 1980 and 2006
          order by yearID desc;')
  
  data <- dbGetQuery(conn, n = -1, modified_string)
  
  return(mean(data$absolute_error))

}

iterations <- as.character(seq(0.1, 3, 0.1))

results <- map(iterations, conn = conn, grid_search)
framed_results <- data.frame(exponent_choice = iterations, mean_abs_error = unlist(results))

# The best result by hundreths of a decimal place is 1.9 (effectively just 2).

# Chapter 2 is entirely done in the MySQL file.

# Chapter 3: Linear Weights

data <- dbGetQuery(conn, n = -1, 'select yearID, R, AB, H,
                  H - X2B - X3B - HR as Singles,
                  X2B, X3B, HR,
                  BB + HBP as Walks,
                  SB, CS
                  from teams
                  where yearID in (2000, 2006)')

lm.fit <- lm(R~Walks + Singles + X2B + X3B + HR + SB + CS, data=data)

summary(lm.fit)
anova(lm.fit)

rmse(lm.fit, data = data)

# My analysis resulted in generally agreeing, but not-quite-the-same numbers for coefficients of each variable.
# I'm fairly certain this is because R and Excel are using different algorithms for convergence (ie least squares
# versus gradient descent), but since I don't own excel I can't pursue why further.

# Chapter 4 - Monte Carlo Simulation
#
# Let's do Joe Hardy First.

event_list <- c(.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, .5, 0, 0, 0, 0, 0, 0)

mean(replicate(10000, inning_simulation(event_list)))

# The function for simulating an inning is huge, so it is resting in the file inning_simulation.R with some added commentary there.
# Now, let's get the data together for Ichiro to simulate his innings. Some extrapolation for the events is done using the
# computations available in the book.

dbGetQuery(conn, 'select sum(AB + BB + SH + SF + HBP) as PA,
            sum(ceiling(0.018*AB)) as Errors,
            sum(AB + SF + SH - H - ceiling(0.018*AB) - SO) as OutsInPlay,
            sum(SO), sum(BB), sum(HBP),
            sum(H - X2B - X3B - HR) as Singles,
            sum(X2B), sum(X3B), sum(HR)
            from batting
            where playerid = \'suzukic01\'
            and yearid = 2004;') %>% as.numeric() -> IchiroVector

IchiroVector <- (IchiroVector/IchiroVector[[1]])[2:length(IchiroVector)]
IchiroExtrap <- extrapolate_event_list(IchiroVector)

mean(replicate(100000, inning_simulation(IchiroExtrap)))*26.72/3

# I get a few extra runs over the prediction of the author. I'm not certain
# what the cause of this is. I will snoop around for what the cause may be.