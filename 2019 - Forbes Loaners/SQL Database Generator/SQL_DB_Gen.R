library(tidyverse)
library(doParallel)
library(RMySQL)
library(mlbgameday)
require(DBI)
setwd("~/Desktop/Phillies Project/SQL Database Generator")

source('installing_packages.R')
source('parse_retrosheet_pbp.R')
source('parse_retrosheet_gamelogs.R')

conn <- dbConnect(MySQL(), dbname = "RETROSHEET", user = "r-user", password = "myPassword@123")

map(1918:2019, pbp_to_sql, conn = conn)
map(1871:2019, append_game_logs, conn = conn)

dbDisconnect(conn)

conn <- dbConnect(MySQL(), dbname = "GAMEDAY", user = "r-user", password = "myPassword@123")

no_cores <- detectCores() - 1
cl <- makeCluster(no_cores)
registerDoParallel(cl)

get_payload(start = '2012-1-1', '2013-1-1', db_con = conn)

stopImplicitCluster()
rm(cl)

dbDisconnect(conn)