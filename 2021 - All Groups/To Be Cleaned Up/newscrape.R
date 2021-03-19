library(baseballr)
library(tidyverse)
library(RMySQL)
require(DBI)

# This is a preliminary script for obtaining player IDs to be uploaded to both the
# statcast and staging tables in the MySQL server. In the future it will be merged
# to SQL Database Generator for future projects.  

conn <- dbConnect(MySQL(), 
                  dbname = "figmentLeague",
                  user = "r-user", 
                  password = "h2p@4031",
                  host = "saberbase.cn2snhhvsjfa.us-east-2.rds.amazonaws.com",
                  port = 3306)


startDate <- as.Date("2017-03-01")
endDate   <- as.Date("2017-11-1")
datelist <- as.Date(startDate:endDate, origin="1970-01-01")
  
for (i in 1:(length(datelist) - 1)) {
  data <- scrape_statcast_savant(
    start_date = datelist[[i]],
    end_date = datelist[[i+1]],
    playerid = NULL,
    player_type = "pitcher",
  )
  
  dbWriteTable(conn, name = "pitching", value = data, append = TRUE, row.names = FALSE)
}

pull(dbGetQuery(conn, n=-1, "select distinct pitcher from statcast.pitching")) -> players
bind_rows(map(players, playername_lookup)) %>% select(key_mlbam, key_retro, key_bbref, key_fangraphs) -> playerIDs
dbWriteTable(conn, name = "mlbIDScrape", value = playerIDs, append = TRUE, row.names = FALSE)

dbDisconnect(conn)

dates <- pull(dbGetQuery(conn, n = -1, 'select distinct substring_index(date, " ", 1) from test'))

get_game_pks_mlb("2018-10-01", level_ids = c(1)) %>% select(game_pk, teams.home.team.id, teams.away.team.id)

bind_rows(map(dates, get_game_pks_mlb, level_ids = c(1))) %>% select(game_pk, teams.home.team.id, teams.away.team.id, venue.name) -> uhTeams

uhTeams %>% select(game_pk, teams.home.team.id, teams.away.team.id, venue.name) -> idsNteams

uhTeams %>% select(teams.away.team.id, teams.away.team.name) %>% distinct()