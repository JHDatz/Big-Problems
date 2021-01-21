library(RMySQL)
library(tidyverse)
library(modelr)
require(DBI)

# Chapter 1 - Baseball's Pythagorean Theorem
# Here we find the best choice for the exponent in formula (2).

# To Math Majors and Statisticians: since the book uses absolute error and not the least squares
# error, this is done with brute force instead of some linear algebra.

conn <- dbConnect(MySQL(), 
                  dbname = "lahman",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
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