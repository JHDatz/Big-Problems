library(baseballr)
library(tidyverse)
library(RMySQL)
require(DBI)

spray_chart <- function(...) {
  ggplot(...) + geom_curve(x = 63.64, xend = -63.64, y = 63.64, yend = 63.64, curvature = .65, linetype = "dotted", color = "black") +
    geom_segment(x = 0, xend = 229.809, y = 0, yend = 229.809, color = "black") +
    geom_segment(x = 0, xend = -229.809, y = 0, yend = 229.809, color = "black") +
    geom_curve(x = -229.809, xend = 229.809, y = 229.809, yend = 229.809, curvature = -.80, color = "black") +
    coord_fixed() +
    scale_x_continuous(NULL, limits = c(-250, 250)) +
    scale_y_continuous(NULL, limits = c(-10, 450))
}

conn <- dbConnect(MySQL(), 
                  dbname = "redacted",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
                  port = 3306)

data <- dbGetQuery(conn, n = -1, "select ballpos_x, ballpos_y from rawFiltered where batterid = 621043")

positions <- read_csv("optimalPositions.csv")

positions %>% filter(v == 0) %>% filter(!is.na(f)) %>% filter(f == min(f)) %>% select(X3, X4, X5, X6, X7, X8, X9) %>% t() -> X
positions %>% filter(v == 0) %>% filter(!is.na(f)) %>% filter(f == min(f)) %>% select(Y3, Y4, Y5, Y6, Y7, Y8, Y9) %>% t() -> Y
rownames(X) <- NULL
rownames(Y) <- NULL
optimalPos <- as_tibble(cbind(X,Y))

spray_chart2(data, aes(x = ballpos_x, y = ballpos_y)) + 
  geom_point(alpha = 0.3, color = "firebrick") + labs(x = "X", y = "Y") +
  geom_point(data = optimalPos, aes(x = V1, y = V2), col="blue") +
  ggtitle("Optimal Fielder Position for Carlos Correa")