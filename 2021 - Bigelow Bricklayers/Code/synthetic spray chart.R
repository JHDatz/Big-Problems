setwd('C:/Users/jhd15/OneDrive/Desktop')
library(tidyverse)
source('spray_simulation_tools.R')

df <- read_csv('PosData.csv')

df %>% filter(batterid == 518934) %>% select(ballpos_x, ballpos_y) -> lemahieu.batted.balls

synthetic <- draw.spray(lemahieu.batted.balls, 2000) %>% na.omit()

spray_chart(synthetic, aes(x = ballpos_x, y = ballpos_y)) + 
  geom_point(alpha = 0.1, color = "firebrick") + 
  labs(x = "X", y = "Y")