library(tidyverse)
library(retro)
library(RMySQL)
require(DBI)

db <- src_mysql("retrosheet", user = 'root', password='new_password')
retro <- etl("retro", db = db, dir = '~/Desktop/retro')
  
retro %>%
  etl_init() %>%
  etl_update(season = 1980:2020)

dbSendQuery(localConn, 'SET NAMES utf8mb4')

localConn <- dbConnect(MySQL(), dbname = 'retrosheet', user = 'root', password='new_password')

data <- dbGetQuery(localConn, n = -1, "select * from events")