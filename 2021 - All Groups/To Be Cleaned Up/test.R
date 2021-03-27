library(tidyverse)
library(retro)
library(RMySQL)
require(DBI)

setwd("~/Desktop")

db <- src_mysql("retrosheet", user = 'root')
retro <- etl("retro", db = db, dir = 'C:\\Users\\josep\\Desktop')

retro %>%
  etl_init()

#localConn <- dbConnect(MySQL(), dbname = 'retrosheet', user = 'root', password='new_password')
#data <- dbGetQuery(localConn, n = -1, "select * from events")

retro %>% 
  etl_extract(season = 1980:2020) %>% 
  etl_transform(season = 1980:2020)

setwd('C:\\Users\\josep\\Desktop\\load')

files <- as.character(list.files(pattern = "EVN"))

commandEvents <- paste0(".\\cwevent -n -f 0-96 -x 0-62 -y ", substring(files, 1, 4), ' ', files, ' > ', 
                  substring(files, 1, 4), substring(files, 5, 7), '_events.csv')

commandGames <- paste0(".\\cwgame -n -f 0-83 -y ", substring(files, 1, 4), ' ', files, ' > ', 
                       substring(files, 1, 4), substring(files, 5, 7), '_games.csv')

commandSubs <- paste0(".\\cwsub -n -y ", substring(files, 1, 4), ' ', files, ' > ', 
                      substring(files, 1, 4), substring(files, 5, 7), '_subs.csv')

commands <- c(commandEvents, commandGames, commandSubs)

map(commands, shell)

files <- as.character(list.files(pattern = 'events.csv|games.csv|subs.csv'))

upload_retrosheet_files <- function(file, conn) {
  df <- read.csv(file, encoding = "UTF-8")
  
  if (length(grep('event', file)) == 1) {
    
    dbWriteTable(conn, name = "events", value = df, append = TRUE, row.names = FALSE)
    
  } else if (length(grep('game', file)) == 1) {
    
    dbWriteTable(conn, name = "games", value = df, append = TRUE, row.names = FALSE)
    
  } else {
    
    dbWriteTable(conn, name = "subs", value = df, append = TRUE, row.names = FALSE)
    
  }
}

map(files, upload_retrosheet_files, conn=conn)