library(tidyverse)
setwd("~/Desktop/coding/Python/scraping/rotowire")

mlb_players <- read_csv('data/mlb_dump.csv')
rotowire_players <- read_csv('data/rotowire_dump.csv')
already_found <- read_csv('data/playerxref.csv')

as.Date(rotowire_players$DOB, format = "%m/%d/%Y") -> rotowire_players$DOB
as.Date(mlb_players$birthDate, format = "%Y-%m-%d") -> mlb_players$DOB

rotowire_players %>%
  inner_join(mlb_players, by = c("fullName", "DOB")) %>%
  distinct(fullName, MLBAMID = PlayerID, RotowireID = id) %>%
  anti_join(already_found, by = c("fullName", "MLBAMID", "RotowireID")) %>%
  rbind(already_found) %>%
  write_csv("data/playerxref.csv")
