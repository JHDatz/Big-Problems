library(tidyverse)
library(GeomMLBStadiums)

draw.rand.normal <- function(centerX) {
  u <- runif(1, 0, 1)*2*pi
  t <- log(1/(1 - runif(1, 0, 1)))
  x <- sqrt(2*t)*cos(u)
  x <- x + centerX
  return(x)
}

draw.batted.ball <- function(buckets, data) {
  index <- sum(buckets < runif(1, 0, 1))
  x <- draw.rand.normal(data[index,1])
  y <- draw.rand.normal(data[index,2])
  return(as.numeric(c(x,y)))
}

draw.spray <- function(batted_balls_data, count) {
  buckets <- seq(from=0, to=1, by = 1/nrow(batted_balls_data))
  
  synthetic.data <- replicate(count, draw.batted.ball(buckets, batted_balls_data))
  synthetic.data <- as.tibble(t(as.matrix(synthetic.data)))
  names(synthetic.data) <- c("ballpos_x", "ballpos_y")
  
  return(synthetic.data)
}

spray_chart <- function(...) {
  ggplot(...) + 
    geom_curve(x = 63.64, xend = -63.64, y = 63.64, yend = 63.64, curvature = .65, linetype = "dotted", color = "black") +
    geom_segment(x = 0, xend = 229.809, y = 0, yend = 229.809, color = "black") +
    geom_segment(x = 0, xend = -229.809, y = 0, yend = 229.809, color = "black") +
    geom_curve(x = -229.809, xend = 229.809, y = 229.809, yend = 229.809, curvature = -.80, color = "black") +
    coord_fixed() +
    scale_x_continuous(NULL, limits = c(-250, 250)) +
    scale_y_continuous(NULL, limits = c(-10, 450))
}

getWallSpline <- function(Team) {
  
  teamField <- MLBStadiumsPathData %>%
    filter(team == Team) %>% 
    mlbam_xy_transformation(x = "x", y = "y")
  
  teamField %>% 
    filter(segment == 'foul_lines') %>% 
    select(y_) %>% max() -> foulLine
  
  teamField %>% 
    filter(segment == 'outfield_outer', y_ > foulLine) -> outfieldWall
  
  outfieldWallX <- outfieldWall %>% select(x_) %>% pull()
  outfieldWallY <- outfieldWall %>% select(y_) %>% pull()
  
  spliner <- splinefun(outfieldWallX, outfieldWallY)
  
  return(list(min(outfieldWallX), max(outfieldWallX), spliner))
  
}

get.grid <- function(Team) {
  
  width <- seq(-300, 300, .5)
  depth <- seq(60, 400, .5)
  
  grid <- matrix(numeric(), nrow = length(width)*length(depth), ncol = 2)
  
  k <- 1
  
  for (i in width) {
    for (j in depth) {
      grid[[k, 1]] <- i
      grid[[k, 2]] <- j
      k <- k + 1
    }
  }
  
  grid <- as_tibble(grid)
  names(grid) <- c("X", "Y")
  
  output <- getWallSpline(Team)
  
  wallMin <- output[[1]]
  wallMax <- output[[2]]
  wallSpline <- output[[3]]
  
  grid %>% filter(X < Y, -X < Y) -> grid # No one past foul lines
  grid.infield <- grid %>% filter(X**2 + Y**2 < 140**2) # No infielders in outfield
  grid.infield %>% filter(X + 120 < Y | -X + 120 < Y) -> grid.infield # No one in front of baseline
  grid.outfield <- grid %>% filter(X**2 + Y**2 > 175**2, # No outfielders encroaching on infield
                                   X > wallMin, 
                                   X < wallMax,
                                   Y < wallSpline(X)) # Outfielders stay within outfield wall
  grid.1b <- grid.infield %>% filter((X-63.64)**2 + (Y-63.64)**2 < 30**2) # First Baseman stays near 1st
  
  return(list(grid.1b, grid.infield, grid.outfield))
  
}

apply.outfield.model <- function(synthetic) {
  
  generic.outfield.pdf <- read_csv('outfieldModel.csv', col_types = cols())
  
  synthetic %>%
    mutate(FirstBaseDistance = sqrt((X3 - ballpos_x)**2 + (Y3 - ballpos_y)**2),
           SecondBaseDistance = sqrt((X4 - ballpos_x)**2 + (Y4 - ballpos_y)**2),
           ThirdBaseDistance = sqrt((X5 - ballpos_x)**2 + (Y5 - ballpos_y)**2),
           shortstopDistance = sqrt((X6 - ballpos_x)**2 + (Y6 - ballpos_y)**2),
           leftFieldDistance = sqrt((X7 - ballpos_x)**2 + (Y7 - ballpos_y)**2),
           centerFieldDistance = sqrt((X8 - ballpos_x)**2 + (Y8 - ballpos_y)**2),
           rightFieldDistance = sqrt((X9 - ballpos_x)**2 + (Y9 - ballpos_y)**2),
           InfOf = ifelse(ballpos_x**2 + ballpos_y**2 < 175**2, "Infield", "Outfield"),
           outOfPark = ifelse(ballpos_x**2 + ballpos_y**2 < 400**2, FALSE, TRUE),
           foulOrBad = ifelse((ballpos_x < ballpos_y) && (-ballpos_x < ballpos_y), FALSE, TRUE),
           cannot.model = outOfPark || foulOrBad,
           responsibility = ifelse(InfOf == "Infield", pmin(FirstBaseDistance, SecondBaseDistance, ThirdBaseDistance, shortstopDistance),
                                   pmin(leftFieldDistance, centerFieldDistance, rightFieldDistance)),
           responsibility1B = ifelse(responsibility == FirstBaseDistance, "1B", ""),
           responsibility2B = ifelse(responsibility == SecondBaseDistance, "2B", ""),
           responsibility3B = ifelse(responsibility == ThirdBaseDistance, "3B", ""),
           responsibilitySS = ifelse(responsibility == shortstopDistance, "SS", ""),
           responsibilityLF = ifelse(responsibility == leftFieldDistance, "LF", ""),
           responsibilityCF = ifelse(responsibility == centerFieldDistance, "CF", ""),
           responsibilityRF = ifelse(responsibility == rightFieldDistance, "RF", ""),
           responsibility.text = paste0(responsibility1B, responsibility2B, responsibility3B, responsibilitySS,
                                        responsibilityLF, responsibilityCF, responsibilityRF),
           responsibility.buckets = cut(responsibility, seq(0,175,5))) -> synthetic
  
  synthetic %>% filter(cannot.model == FALSE)
  
  synthetic %>% inner_join(generic.outfield.pdf, by = c("responsibility.buckets" = "cuts")) -> synthetic
  
  synthetic$drawn.uniform <- runif(nrow(synthetic), 0, 1)
  
  synthetic %>% mutate(outs = ifelse(drawn.uniform > 1 - success, 1, 0)) -> synthetic
  
  return(synthetic)
  
}

simulate.catches <- function(batted.balls, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9) {
  
  synthetic <- draw.spray(batted.balls, 2000) %>% na.omit()
  synthetic$X3 <- replicate(nrow(synthetic), X3)
  synthetic$Y3 <- replicate(nrow(synthetic), Y3)
  synthetic$X4 <- replicate(nrow(synthetic), X4)
  synthetic$Y4 <- replicate(nrow(synthetic), Y4)
  synthetic$X5 <- replicate(nrow(synthetic), X5)
  synthetic$Y5 <- replicate(nrow(synthetic), Y5)
  synthetic$X6 <- replicate(nrow(synthetic), X6)
  synthetic$Y6 <- replicate(nrow(synthetic), Y6)
  synthetic$X7 <- replicate(nrow(synthetic), X7)
  synthetic$Y7 <- replicate(nrow(synthetic), Y7)
  synthetic$X8 <- replicate(nrow(synthetic), X8)
  synthetic$Y8 <- replicate(nrow(synthetic), Y8)
  synthetic$X9 <- replicate(nrow(synthetic), X9)
  synthetic$Y9 <- replicate(nrow(synthetic), Y9)
  
  synthetic <- apply.outfield.model(synthetic)
  
  return(sum(synthetic$outs)/nrow(synthetic))
  
}

grid.puncher <- function(grid, XCoord, YCoord, radius, angle) {
  
  grid %>% filter((XCoord - X)**2 + (YCoord - Y)**2 > radius**2, 
                  acos((XCoord*X + YCoord*Y)/(sqrt(XCoord**2 + YCoord**2)*sqrt(X**2 + Y**2)))*180/pi > angle) -> new.grid
  
  return(new.grid)
  
}

draw.coordinates <- function(grid) {
  
  index <- sample(1:nrow(grid), 1)
  
  XCoord <- grid[[index, 1]]
  YCoord <- grid[[index, 2]]
  
  return(c(XCoord, YCoord))
  
}

simulate.positions <- function(batted.balls, grid.1b, grid.infield, grid.outfield, 
                               infielder_radii, outfielder_radii, infOf_radii, angle_inhibited) {
  
  P3 <- draw.coordinates(grid.1b)
  working.grid.infield <- grid.puncher(grid.infield, P3[1], P3[2], infielder_radii, angle_inhibited)
  working.grid.outfield <- grid.puncher(grid.outfield, P3[1], P3[2], infOf_radii, angle_inhibited)
  
  P4 <- draw.coordinates(working.grid.infield)
  working.grid.infield <- grid.puncher(working.grid.infield, P4[1], P4[2], infielder_radii, angle_inhibited)
  working.grid.outfield <- grid.puncher(grid.outfield, P4[1], P4[2], infOf_radii, angle_inhibited)
  
  P5 <- draw.coordinates(working.grid.infield)
  working.grid.infield <- grid.puncher(working.grid.infield, P5[1], P5[2], infielder_radii, angle_inhibited)
  working.grid.outfield <- grid.puncher(grid.outfield, P5[1], P5[2], infOf_radii, angle_inhibited)
  
  P6 <- draw.coordinates(working.grid.infield)
  working.grid.infield <- grid.puncher(working.grid.infield, P6[1], P6[2], infielder_radii, angle_inhibited)
  working.grid.outfield <- grid.puncher(grid.outfield, P6[1], P6[2], infOf_radii, angle_inhibited)
  
  P7 <- draw.coordinates(working.grid.outfield)
  working.grid.outfield <- grid.puncher(grid.outfield, P7[1], P7[2], outfielder_radii, angle_inhibited)
  
  P8 <- draw.coordinates(working.grid.outfield)
  working.grid.outfield <- grid.puncher(grid.outfield, P8[1], P8[2], outfielder_radii, angle_inhibited)
  
  P9 <- draw.coordinates(working.grid.outfield)
  
  outs <- simulate.catches(batted.balls, P3[1], P3[2], P4[1], P4[2], P5[1], P5[2],
                           P6[1], P6[2], P7[1], P7[2], P8[1], P8[2], P9[1], P9[2])
  
  return(c(outs, P3[1], P3[2], P4[1], P4[2], P5[1], P5[2], P6[1], P6[2], P7[1], P7[2], P8[1], P8[2], P9[1], P9[2]))
  
}