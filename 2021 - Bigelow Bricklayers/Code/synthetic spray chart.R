library(tidyverse)
library(RMySQL)
require(DBI)

conn <- dbConnect(MySQL(), 
                  dbname = "figmentLeague",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
                  port = 3306)

data <- dbGetQuery(conn, n=-1, "select ballpos_x, ballpos_y from rawFiltered where batterid = 518934")


draw.rand.normal <- function(centerX) {
  u <- runif(1, 0, 1)*2*pi
  t <- log(1/(1 - runif(1, 0, 1)))
  x <- sqrt(2*t)*cos(u)
  x <- x + centerX
  return(x)
}

draw.spray <- function(buckets, data) {
  index <- sum(buckets < runif(1, 0, 1)) + 1
  x <- draw.rand.normal(data[index,1])
  y <- draw.rand.normal(data[index,2])
  return(c(x,y))
}

buckets <- seq(from=0, to=1, by = 1/dim(data)[1])

draw.spray(buckets, data)

synthetic <- as.tibble(t(as.matrix(replicate(2000, draw.spray(buckets, data)))))

spray_chart <- function(...) {
  ggplot(...) + geom_curve(x = 63.64, xend = -63.64, y = 63.64, yend = 63.64, curvature = .65, linetype = "dotted", color = "black") +
    geom_segment(x = 0, xend = 229.809, y = 0, yend = 229.809, color = "black") +
    geom_segment(x = 0, xend = -229.809, y = 0, yend = 229.809, color = "black") +
    geom_curve(x = -229.809, xend = 229.809, y = 229.809, yend = 229.809, curvature = -.80, color = "black") +
    coord_fixed() +
    scale_x_continuous(NULL, limits = c(-250, 250)) +
    scale_y_continuous(NULL, limits = c(-10, 450))
}

spray_chart(synthetic, aes(x = V1, y = V2)) + geom_point(alpha = 0.1, color = "firebrick") + labs(x = "X", y = "Y")