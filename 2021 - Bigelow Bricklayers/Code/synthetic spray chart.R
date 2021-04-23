library(tidyverse)
source('spray_simulation_tools.R')
setwd('C:/Users/jhd15/OneDrive/Desktop')

df <- read_csv('PosData.csv')

df %>% filter(batterid == 518934) %>% select(ballpos_x, ballpos_y) -> lemahieu.batted.balls

synthetic <- draw.spray(lemahieu.batted.balls, 2000) %>% na.omit()

ggplot() + geom_mlb_stadium(stadium_ids = 'yankees', stadium_segments = 'all', 
                            stadium_transform_coords = TRUE) + 
  coord_fixed() +
  geom_point(data = lemahieu.batted.balls, color = 'firebrick', alpha = 0.08) +
  aes(x = ballpos_x, y = ballpos_y) +
  ggtitle("Simulated Spray Chart for Jacob Cuffman") +
  theme(plot.title = element_text(hjust = 0.5))