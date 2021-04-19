setwd('C:/Users/jhd15/OneDrive/Desktop')
source('spray_simulation_tools.R')

df <- read_csv('PosData.csv')
df %>% filter(batterid == 518934) %>% select(ballpos_x, ballpos_y) -> lemahieu.batted.balls

gridResults <- get.grid('pirates')

grid.1b <- gridResults[[1]]
grid.infield <- gridResults[[2]]
grid.outfield <- gridResults[[3]]

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

names(optimalPos) <- c("X", "Y")
names(lemahieu.batted.balls) <- c("X", "Y")
lemahieu.batted.balls$Categories <- replicate(nrow(lemahieu.batted.balls), "Batted Ball Data")
optimalPos$Categories <- replicate(nrow(optimalPos), "Optimal Positions")

ggplot() + geom_mlb_stadium(stadium_ids = 'pirates', stadium_segments = 'all', 
                            stadium_transform_coords = TRUE) + 
  coord_fixed() +
  geom_point(data = bind_rows(lemahieu.batted.balls, optimalPos)) +
  aes(x= X, y= Y, color = Categories, alpha = Categories) +
  scale_color_manual(values=c("firebrick", "blue")) +
  scale_alpha_manual(values = c(0.3, 1)) +
  ggtitle("Optimal Fielder Positions for D.J LeMahieu") +
  theme(plot.title = element_text(hjust = 0.5))


