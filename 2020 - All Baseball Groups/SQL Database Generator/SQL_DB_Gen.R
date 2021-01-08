library(tidyverse)
library(doParallel)
library(RMySQL)
library(mlbgameday)
library(Lahman)
require(DBI)
setwd("C:\\Users\\josep\\Desktop\\SQL Database Generator")

#source('installing_packages.R')
source('parse_retrosheet_pbp.R')
source('parse_retrosheet_gamelogs.R')
source('lahman_upload.R')
source('gameday_upload.R')

conn <- dbConnect(MySQL(), 
                  dbname = "retrosheet",
                  user = "r-user", 
                  password = "h2p@4031",
                  host = "saberbase.cn2snhhvsjfa.us-east-2.rds.amazonaws.com",
                  port = 3306)

map(1918:2020, pbp_to_sql, conn = conn)
map(1871:2020, append_game_logs, conn = conn)

dbDisconnect(conn)

conn <- dbConnect(MySQL(), 
                  dbname = "lahman",
                  user = "r-user", 
                  password = "h2p@4031",
                  host = "saberbase.cn2snhhvsjfa.us-east-2.rds.amazonaws.com",
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
