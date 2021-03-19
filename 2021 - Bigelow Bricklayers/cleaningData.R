library(baseballr)
library(tidyverse)
library(RMySQL)
library(lubridate)
library(Lahman)
require(DBI)

# Modifying the dataset
# Written by: Joe Datz
# 3/18/21
#
# This file is split up into two days:
#
# Day 1, where I tried to fix up the data on the MySQL server and kept
# running into storage limits. The cost of free, I guess...
#
# Day 2, where I fixed up the data by pulling the existing info off MySQL
# and work entirely in R.

# Day 1

# Connect to MySQL server

conn <- dbConnect(MySQL(), 
                  dbname = "figmentLeague",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
                  port = 3306)

# Pull all listed dates from the given data. We'd like to get the game_PK numbers for these dates
# and see if there are any valuable columns we'd like to add.

dates <- pull(dbGetQuery(conn, n = -1, 'select distinct substring_index(date, " ", 1) from test'))

# Use these dates to get additional information from MLBAM.

helper_function <- function(date) {
  Sys.sleep(3)
  return(get_game_pks_mlb(date, level_ids = c(1)))
}

bind_rows(map(dates, helper_function)) -> games #%>% select(game_pk, teams.home.team.id, teams.away.team.id, venue.name) -> games

# Add a table with the game_pks, home team, away team, and park to the MySQL server.

games %>% select(game_pk, teams.home.team.id, teams.away.team.id, venue.name, doubleHeader) -> pksNteams
dbWriteTable(conn, name = "mlbPKteams", pksNteams, append = TRUE, row.names = FALSE)

# Add a new table which is the just the id number of the team and the team name.
# We add the empty column RetroName because we'd like to match this up with the RETROSHEET
# database. We'll manually add this into the MySQL server.

uhTeams %>% select(teams.away.team.id, teams.away.team.name) %>% distinct() %>% mutate(RetroName = "NA") -> teamids
teamids %>% rename(teamID = "teams.away.team.id", mlbamName = "teams.away.team.name")-> teamids
dbWriteTable(conn, name = "teamIDs", teamids, append = TRUE, row.names = FALSE)

# Day 2
#
# Unfortunately I don't have enough storage in MySQL to perform what I wanted, so I go back now
# to R to get what I want.

df <- dbGetQuery(conn, n=-1, "select * from test") %>% distinct()
teaminfo <- dbGetQuery(conn, n = -1, "select * from mlbPKteams") %>% distinct()
teamIDs <- dbGetQuery(conn, n = -1, "select * from teamIDs")
xref <- dbGetQuery(conn, n = -1, "select * from merged.PlayerCrossRef")
retrodata <- dbGetQuery(conn, n = -1, "select * from merged.vGenerateStates where year > 2017")

df$batterid <- as.character(df$batterid)
df$pitcherid <- as.character(df$pitcherid)

xref %>% filter(source == 'mlbam') -> mlbamIDs
xref %>% filter(source == 'lahman') -> lahmanIDs

# I noticed that some of my columns for teaminfo are duplicates, so I checked
# back with games in much more detail. It turns out that double-headers will
# occasionally be given the same PK value. This is unfortunate because I don't
# currently have a way to tell in df which rows are from double headers and
# which arent, so I will remove them for now.

# Games which are suspended for inclement weather and start back up later are
# also a source of duplicate rows. For those games I think it's best to mark
# them as whatever the first stadium was that was played at.
  
games %>% 
  group_by(game_pk) %>% 
  summarize(n = n(), 
            totalGames = max(gameNumber), 
            venue.name = first(venue.name)) %>% 
  arrange(desc(n)) -> duplicatedGames

games %>% 
  inner_join(duplicatedGames, by = "game_pk") %>% 
  filter(totalGames == 1) %>% 
  select(game_pk, teams.home.team.id, teams.away.team.id, venue.name.x) %>% rename(Park = "venue.name.x") %>%
  distinct() -> truncatedGames

df %>% distinct()

df %>%
  left_join(mlbamIDs, by = c('batterid' = 'identifier')) %>%
  inner_join(lahmanIDs, by = 'mergedID') %>%
  inner_join(Master, by = c('identifier' = 'playerID')) %>%
  left_join(mlbamIDs, by = c('pitcherid' = 'identifier')) %>% 
  select(Game_PK, date, pitcherid, batterid, retroID, nameFirst, nameLast, BatSide, PitcherHand, inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, 
         FlightTime, Trajectory, HitValue, RunValue, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9, ballpos_x, ballpos_y, mergedID.y) %>%
  rename(mergedID = "mergedID.y", batterFirst = "nameFirst", batterLast = "nameLast", batterRetroID = "retroID") %>%
  inner_join(lahmanIDs, by = 'mergedID') %>%
  inner_join(Master, by = c('identifier' = 'playerID')) %>%
  select(Game_PK, date, pitcherid, retroID, nameFirst, nameLast, batterid, batterRetroID, batterFirst, batterLast, BatSide, PitcherHand, inning, 
         PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9, ballpos_x, 
         ballpos_y) %>%
  mutate(pitcherName = paste(nameFirst, nameLast), batterName = paste(batterFirst, batterLast), newDate = mdy(str_sub(date, end = -6))) %>%
  select(Game_PK, newDate, pitcherid, retroID, pitcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, 
         Distance, FlightTime, Trajectory, HitValue, RunValue, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(truncatedGames, by = c("Game_PK" = "game_pk")) %>%
  select(Game_PK, Park, teams.home.team.id, teams.away.team.id, newDate, pitcherid, retroID, pitcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, inning, 
         PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9, ballpos_x, 
         ballpos_y) %>%
  rename(homeTeam = "teams.home.team.id", awayTeam = "teams.away.team.id", date = "newDate", pitcherRetroID = "retroID") %>%
  inner_join(teamIDs, by = c("homeTeam" = "teamID")) %>%
  select(Game_PK, Park, RetroName, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, inning, 
         PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9, 
         ballpos_x, ballpos_y) %>%
  rename(homeTeam = "RetroName") %>%
  inner_join(teamIDs, by = c("awayTeam" = "teamID")) %>%
  select(Game_PK, Park, homeTeam, RetroName, date, pitcherid, pitcherRetroID, pitcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, inning, PitchTypeCode, 
         ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, X3, Y3, X4, Y4, X5, Y5, X6, Y6, X7, Y7, X8, Y8, X9, Y9, ballpos_x, ballpos_y) %>%
  rename(awayTeam = "RetroName") %>%
  mutate(retrosheetGameID = paste0(homeTeam, as.character(year(date)), ifelse(month(date) > 9, as.character(month(date)), paste0("0", month(date))),
                                   ifelse(day(date) > 9, as.character(day(date)), paste0("0", day(date))), "0"))-> df2


df2 %>% 
  inner_join(retrodata, by = c("retrosheetGameID" = "GAME_ID", "pitcherRetroID" = "PIT_ID", "batterRetroID" = "BAT_ID", "inning" = "INN_CT")) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, batterid, batterRetroID, batterName, BatSide, PitcherHand, inning, 
         PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID,
         X3, Y3, POS4_FLD_ID, X4, Y4, POS5_FLD_ID, X5, Y5, POS6_FLD_ID, X6, Y6, POS7_FLD_ID, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS2_FLD_ID" = "retroID")) %>%
  mutate(catcherName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, X3, Y3, POS4_FLD_ID, X4, Y4, 
         POS5_FLD_ID, X5, Y5, POS6_FLD_ID, X6, Y6, POS7_FLD_ID, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS3_FLD_ID" = "retroID")) %>%
  mutate(firstBasemanName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID, X4, 
         Y4, POS5_FLD_ID, X5, Y5, POS6_FLD_ID, X6, Y6, POS7_FLD_ID, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS4_FLD_ID" = "retroID")) %>%
  mutate(secondBasemanName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID,
         secondBasemanName, X4, Y4, POS5_FLD_ID, X5, Y5, POS6_FLD_ID, X6, Y6, POS7_FLD_ID, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS5_FLD_ID" = "retroID")) %>%
  mutate(thirdBasemanName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID,
         secondBasemanName, X4, Y4, POS5_FLD_ID, thirdBasemanName, X5, Y5, POS6_FLD_ID, X6, Y6, POS7_FLD_ID, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, X9, Y9, ballpos_x, 
         ballpos_y) %>%
  inner_join(Master, by = c("POS6_FLD_ID" = "retroID")) %>%
  mutate(shortstopName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID,
         secondBasemanName, X4, Y4, POS5_FLD_ID, thirdBasemanName, X5, Y5, POS6_FLD_ID, shortstopName, X6, Y6, POS7_FLD_ID, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, X9, Y9, 
         ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS7_FLD_ID" = "retroID")) %>%
  mutate(leftFieldName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID,
         secondBasemanName, X4, Y4, POS5_FLD_ID, thirdBasemanName, X5, Y5, POS6_FLD_ID, shortstopName, X6, Y6, POS7_FLD_ID, leftFieldName, X7, Y7, POS8_FLD_ID, X8, Y8, POS9_FLD_ID, 
         X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS8_FLD_ID" = "retroID")) %>%
  mutate(centerFieldName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID,
         secondBasemanName, X4, Y4, POS5_FLD_ID, thirdBasemanName, X5, Y5, POS6_FLD_ID, shortstopName, X6, Y6, POS7_FLD_ID, leftFieldName, X7, Y7, POS8_FLD_ID, centerFieldName,
         X8, Y8, POS9_FLD_ID, X9, Y9, ballpos_x, ballpos_y) %>%
  inner_join(Master, by = c("POS9_FLD_ID" = "retroID")) %>%
  mutate(rightFieldName = paste(nameFirst, nameLast)) %>%
  select(Game_PK, Park, homeTeam, awayTeam, date, pitcherid, pitcherRetroID, pitcherName, POS2_FLD_ID, catcherName, batterid, batterRetroID, batterName, BatSide, PitcherHand, 
         inning, PitchTypeCode, ExitVelocity, VertAngle, HorizAngle, Distance, FlightTime, Trajectory, HitValue, RunValue, POS3_FLD_ID, firstBasemanName, X3, Y3, POS4_FLD_ID,
         secondBasemanName, X4, Y4, POS5_FLD_ID, thirdBasemanName, X5, Y5, POS6_FLD_ID, shortstopName, X6, Y6, POS7_FLD_ID, leftFieldName, X7, Y7, POS8_FLD_ID, centerFieldName,
         X8, Y8, POS9_FLD_ID, rightFieldName, X9, Y9, ballpos_x, ballpos_y) %>%
  rename("catcherID" = "POS2_FLD_ID", "firstBasemanID" = "POS3_FLD_ID", "secondBasemanID" = "POS4_FLD_ID", "thirdBasemanID" = "POS5_FLD_ID", "shortstopID" = "POS6_FLD_ID",
         "leftFieldID" = "POS7_FLD_ID", "centerFieldID" = "POS8_FLD_ID", "rightFieldID" = "POS9_FLD_ID") -> dfFinal

write_csv(dfFinal, "positioning_problem.csv")