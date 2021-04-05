library(devtools)
library(baseballr)
library(tidyverse)

setwd("~/Desktop/coding/Big Problems (Github)/2021 - Plaid Panthers/Data")

fielding_all <- read.csv("FangraphsAll.csv")
colnames(fielding_all)[1] <- gsub('^...','',colnames(fielding_all)[1])
fielding_all <- rename(fielding_all, c("Season" = "son"))

if(!exists("player_ids")){
  
  url <- "https://raw.githubusercontent.com/chadwickbureau/register/master/data/people.csv"
  
  player_ids <- suppressMessages(vroom::vroom(url, delim = ',') 
                                 # can change selection later 
                                 %>% select(key_mlbam, key_fangraphs, 
                                            name_last, name_first, 
                                            birth_year, birth_month, birth_day, 
                                            mlb_played_first, mlb_played_last)
                                 %>% filter(mlb_played_last >= 2003))
  
}

fielding_all <- (fielding_all 
                 %>% left_join(player_ids, by = c("playerid" = "key_fangraphs"))
                 %>% mutate(Age = Season - birth_year, DRS_per_Inning = DRS / Inn,
                            name_first = str_replace_all(str_trim(name_first), c(" " = "", "é" = "e", "í" = "i")), 
                            name_last = str_replace_all(str_trim(name_last), c(" " = "", "é" = "e", "í" = "i"))))

chained.mahalanobis <- function(name, age) {
  
  fielding_all %>% 
    filter(Name == name, Age == age) -> comparedFielder
  
  if (dim(comparedFielder)[[1]] > 1) {
    comparedFielder %>% arrange(desc(Inn)) -> comparedFielder
    comparedFielder <- comparedFielder[1,]
  }
  
  if (comparedFielder$Pos == "C") {
    
    comparedFielder %>% select(rSZ, rCERA, rSB, rGFP, FRM, Def) %>% as.matrix() -> comparedFielderStats
    
    fielding_all %>% 
      filter(Age == age, Pos == "C", Inn >= 100) %>% 
      select(Name, Inn, rSZ, rCERA, rSB, rGFP, FRM, Def) %>% na.omit() -> fielders
    
    fielders %>% select(rSZ, rCERA, rSB, rGFP, FRM, Def) %>% as.matrix() -> fieldersStats
    
  } else if (comparedFielder$Pos %in% c("1B", "2B", "3B", "SS")) {
    
    comparedFielder %>% select(rGDP, rGFP, rPM, RZR, DPR, RngR, ErrR, UZR.150, Def) %>% as.matrix() -> comparedFielderStats
    
    fielding_all %>% 
      filter(Age == age, Pos == comparedFielder$Pos, Inn >= 100) %>% 
      select(Name, Inn, rGDP, rGFP, rPM, RZR, DPR, RngR, ErrR, UZR.150, Def) %>% na.omit() -> fielders
    
    fielders %>% select(rGDP, rGFP, rPM, RZR, DPR, RngR, ErrR, UZR.150, Def) %>% as.matrix() -> fieldersStats
    
  } else {
    
    comparedFielder %>% select(rARM, rGFP, rPM, RZR, RngR, ErrR, UZR.150, Def) %>% as.matrix() -> comparedFielderStats
    
    fielding_all %>% 
      filter(Age == age, Pos == comparedFielder$Pos, Inn >= 100) %>% 
      select(Name, Inn, rARM, rGFP, rPM, RZR, RngR, ErrR, UZR.150, Def) %>% na.omit() -> fielders
    
    fielders %>% select(rARM, rGFP, rPM, RZR, RngR, ErrR, UZR.150, Def) %>% as.matrix() -> fieldersStats
    
  }
  
  distances <- as.numeric(mahalanobis(x = sweep(as.matrix(fieldersStats), 2, as.matrix(comparedFielderStats)), 
                                      center = FALSE, cov = cov(fieldersStats)))
  fielders <- cbind(fielders, distances)
  
  return (fielders %>% arrange(distances))

}
  
# chained.mahalanobis("Fernando Tatis Jr.", 21)