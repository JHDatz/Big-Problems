library(tidyverse)
library(Lahman)

setwd("~/Desktop/coding/R/Phillies Project/retrosheet/unzipped")

retro_to_lahman <- function(retrosheet_table) {
  temp_array <- c("1", "2", "3", "4", "5", "6", "7", "8", "9") 
  
  for (i in 1:length(temp_array)) {
    master.names <- Master %>% select(retroID, nameFirst, nameLast, lahmanID = playerID)
    names(master.names)[1] <- temp_array[i]
    names(master.names)[2] <- paste0("Pos", temp_array[i], "nameFirst")
    names(master.names)[3] <- paste0("Pos", temp_array[i], "nameLast")
    names(master.names)[4] <- paste0("Pos", temp_array[i], "lahmanID")
    retrosheet_table %>% left_join(master.names, by=temp_array[i]) -> retrosheet_table
  }
  retrosheet_table
}

errorNum_to_retroID <- function(retrosheet_table) {
  for (i in 1:3){
    char_col_name = paste0("ERR", as.character(i), "_CHAR")
    fld_cd = paste0("ERR", as.character(i), "_FLD_CD")
    retroID_col = paste0("ERR", as.character(i), "_ID")
    retrosheet_table[char_col_name] <- map_chr(pull(retrosheet_table[fld_cd]), as.character)
    retrosheet_table[retroID_col] <- apply(retrosheet_table, 1, function(x) x[x[length(x)]])
  }
  retrosheet_table
}

create_error_table <- function(retrosheet_table) {
  retrosheet_table %>%
    filter(ERR_CT > 0) %>%
    mutate("0" = NA, "1"=PIT_ID, "2"=POS2_FLD_ID, "3"=POS3_FLD_ID, "4"=POS4_FLD_ID, "5"=POS5_FLD_ID,
           "6"=POS6_FLD_ID, "7"=POS7_FLD_ID, "8"=POS8_FLD_ID, "9"=POS9_FLD_ID,) %>% 
    errorNum_to_retroID() %>%
    select(GAME_ID,AWAY_TEAM_ID,"1","2","3","4","5","6","7","8","9",EVENT_CD,ERR_CT,
           ERR1_FLD_CD,ERR2_FLD_CD,ERR3_FLD_CD,ERR1_ID,ERR2_ID,ERR3_ID) %>% 
    retro_to_lahman() %>% 
    return()
}

data0610<-read_csv("~/retrosheet/unzipped/data0610.csv")
data1115<-read_csv("~/retrosheet/unzipped/data1115.csv")
data1619<-read_csv("~/retrosheet/unzipped/data1619.csv")

data0610.err <- create_error_table(data0610)
data1115.err <- create_error_table(data1115)
data1619.err <- create_error_table(data1619)
