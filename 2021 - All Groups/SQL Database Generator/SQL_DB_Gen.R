library(tidyverse)
library(doParallel)
library(RMySQL)
library(mlbgameday)
library(Lahman)
require(DBI)
setwd("C:\\Users\\joseph\\Desktop\\SQL Database Generator")

#source('installing_packages.R')
source('parse_retrosheet_pbp.R')
source('parse_retrosheet_gamelogs.R')
source('lahman_upload.R')
source('gameday_upload.R')

conn <- dbConnect(MySQL(), 
                  dbname = "redacted",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
                  port = 3306)

map(1978:2020, pbp_to_sql, conn = conn)
map(1871:2020, append_game_logs, conn = conn)

dbDisconnect(conn)

conn <- dbConnect(MySQL(), 
                  dbname = "redacted",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
                  port = 3306)

upload_lahman(conn)

dbDisconnect(conn)

no_cores <- detectCores() - 1
cl <- makeCluster(no_cores)
registerDoParallel(cl)

year_list <- paste0("201", 2:9, "-1-1")
gameday_upload(year_list)

stopImplicitCluster()
rm(cl)
