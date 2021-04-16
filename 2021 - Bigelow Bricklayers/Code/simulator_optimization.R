setwd('C:/Users/jhd15/OneDrive/Desktop')
source('spray_simulation_tools.R')

df <- read_csv('PosData.csv')
df %>% filter(batterid == 518934) %>% select(ballpos_x, ballpos_y) -> lemahieu.batted.balls

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

grid %>% filter(X < Y, -X < Y, X**2 + Y**2 < 400**2) -> grid # Shrink rectangle to field dimensions
grid.infield <- grid %>% filter(X**2 + Y**2 < 140**2) # No infielders in outfield
grid.infield %>% filter(X + 120 < Y | -X + 120 < Y) -> grid.infield # No one in front of baseline
grid.outfield <- grid %>% filter(X**2 + Y**2 > 175**2) # No outfielders encroaching on infield
grid.1b <- grid.infield %>% filter((X-63.64)**2 + (Y-63.64)**2 < 30**2) # First Baseman stays near 1st


results <- replicate(10000, simulate.positions(lemahieu.batted.balls, grid.1b, grid.infield, grid.outfield,
                                               20, 60, 60, 4), 
                     simplify = FALSE)

results <- t(data.frame(results))
rownames(results) <- NULL
results <- as_tibble(results)
names(results) <- c("outs", "X3", "Y3", "X4", "Y4", "X5", "Y5", "X6", "Y6", "X7", "Y7", "X8", "Y8", "X9", "Y9")

results %>% filter(outs == max(outs)) -> final
final %>% select(X3, X4, X5, X6, X7, X8, X9) %>% t() -> X
final %>% select(Y3, Y4, Y5, Y6, Y7, Y8, Y9) %>% t() -> Y
rownames(X) <- NULL
rownames(Y) <- NULL
optimalPos <- as_tibble(cbind(X,Y))

spray_chart(lemahieu.batted.balls, aes(x = ballpos_x, y = ballpos_y)) + 
  geom_point(alpha = 0.3, color = "firebrick") + labs(x = "X", y = "Y") +
  geom_point(data = optimalPos, aes(x = V1, y = V2), col="blue") +
  ggtitle("Optimal Fielder Position for D.J LeMahieu")


