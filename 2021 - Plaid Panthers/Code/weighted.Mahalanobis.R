library(devtools)
library(baseballr)
library(tidyverse)

setwd("C:/Users/jhd15/OneDrive/Desktop/coding/Big Problems (Github)/2021 - Plaid Panthers/Data")

fielding_all <- read.csv("FangraphsAll.csv")
colnames(fielding_all)[1] <- gsub('^...','',colnames(fielding_all)[1])
#fielding_all <- rename(fielding_all, c("Season" = "son")) Seems to not be an issue on new computer. 4/10/21

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
                            name_first = str_replace_all(str_trim(name_first), c(" " = "", "Ã©" = "e", "Ã­" = "i")), 
                            name_last = str_replace_all(str_trim(name_last), c(" " = "", "Ã©" = "e", "Ã­" = "i"))))

weighted.Player.Stats <- function(fielders, range, ...) {
  
  fielders %>% 
    group_by(Name) %>% 
    summarize(count = n()) %>%
    arrange(Name) -> positionCount
  
  fielders %>% 
    inner_join(positionCount, by = "Name") %>% 
    filter(count == range) -> fielders
  
  fielders %>% distinct(Name) -> fielderNames
  fielders %>% select(...) %>% names() -> fielderStatsNames
  
  fielders %>% select(...) %>% as.matrix() -> fieldersStats
  
  split(fieldersStats, rep(1:ceiling(nrow(fielders)/range), each=range, length.out=nrow(fielders))) -> fieldersSplit
  
  lapply(fieldersSplit, matrix, nrow=range) -> fieldersSplit
  lapply(fieldersSplit, t) -> fieldersSplit
  lapply(fieldersSplit, `%*%`, 1:range) -> fieldersSplit
  lapply(fieldersSplit, '/', sum(1:range)) -> fieldersSplit
  lapply(fieldersSplit, t) -> fieldersSplit
  weighted.Stats.Matrix <- t(data.frame(lapply(fieldersSplit, as.vector)))
  rownames(weighted.Stats.Matrix) <- NULL
  weighted.Stats.Matrix <- data.frame(weighted.Stats.Matrix)
  names(weighted.Stats.Matrix) <- fielderStatsNames
  weighted.Stats.Matrix$Name <- fielderNames
  
  return(weighted.Stats.Matrix)
  
}

weighted.Mahalanobis <- function(name, age, range) {
  
  age.bracket <- (age-range+1):age
  
  fielding_all %>% 
    filter(Name == name, Age %in% age.bracket) -> comparedFielder
  
  fielding_all %>% filter(Name == name) %>% 
    group_by(Season, Name, Age) %>% 
    summarize(Primary_pos_percentage = max(Inn)/sum(Inn)) %>% 
    filter(Age %in% age.bracket) -> primPosPercentage
  
  if (any(primPosPercentage$Primary_pos_percentage < .5)) {
    
    stop(paste("Player used as utility in prior"), as.character(range),  "years.")
  
  }
  
  fielding_all %>% filter(Name == name) %>% 
    group_by(Season, Name, Age) %>% 
    summarize(Inn = max(Inn)) -> primPosIndicator
  
  comparedFielder %>% 
    inner_join(primPosIndicator, by = c("Season", "Name", "Age", "Inn")) %>%
    arrange(Age) -> comparedFielder
  
  comparedFielder %>% distinct(Pos) %>% dim() -> positionSwitchTest
  
  if (positionSwitchTest[1] > 1) {
    
    stop(paste("Player's primary position has changed in prior"), as.character(range),  "years.")
    
  }
  
  comparedFielder %>% arrange(Season) -> comparedFielder
  
  comparedFielder %>% distinct(Pos) %>% pull() -> position
  
  if (position == "C") {
    
    fielding_all %>% 
      filter(Age %in% age.bracket, Pos == position, Inn >= 100) %>% 
      arrange(Name, Age) %>%
      select(Name, Inn, rSZ, rCERA, rSB, rGFP, FRM, Def) %>% na.omit() -> fielders
    
    
    weighted.Stats <- weighted.Player.Stats(fielders, range, rSZ, rCERA, rSB, rGFP, FRM, Def)
    fielderNames <- weighted.Stats[c("Name")]
    weighted.Stats <- weighted.Stats[1:length(weighted.Stats)-1]
    
    weighted.compared.player <- weighted.Player.Stats(comparedFielder, range, rSZ, rCERA, rSB, rGFP, FRM, Def)
    weighted.compared.player <- weighted.compared.player[1:length(weighted.compared.player)-1]
    
  } else if (position %in% c("1B", "2B", "3B", "SS")) {
    
    fielding_all %>% 
      filter(Age %in% age.bracket, Pos == position, Inn >= 100) %>% 
      arrange(Name, Age) %>%
      select(Name, Inn, rGDP, rGFP, rPM, RZR, DPR, RngR, ErrR, UZR.150, Def) %>% na.omit() %>%
      arrange(Name)-> fielders
    
    
    weighted.Stats <- weighted.Player.Stats(fielders, range, rGDP, rGFP, rPM, RZR, DPR, RngR, ErrR, UZR.150, Def)
    fielderNames <- weighted.Stats[c("Name")]
    weighted.Stats <- weighted.Stats[1:length(weighted.Stats)-1]
    
    weighted.compared.player <- weighted.Player.Stats(comparedFielder, range, rGDP, rGFP, rPM, RZR, DPR, RngR, ErrR, UZR.150, Def)
    weighted.compared.player <- weighted.compared.player[1:length(weighted.compared.player)-1]
    
  } else {
    
    fielding_all %>% 
      filter(Age %in% age.bracket, Pos == position, Inn >= 100) %>% 
      arrange(Name, Age) %>%
      select(Name, Inn, rARM, rGFP, rPM, RZR, RngR, ErrR, UZR.150, Def) %>% na.omit() %>%
      arrange(Name)-> fielders
    
    
    weighted.Stats <- weighted.Player.Stats(fielders, range, rARM, rGFP, rPM, RZR, RngR, ErrR, UZR.150, Def)
    fielderNames <- weighted.Stats[c("Name")]
    weighted.Stats <- weighted.Stats[1:length(weighted.Stats)-1]
    
    weighted.compared.player <- weighted.Player.Stats(comparedFielder, range, rARM, rGFP, rPM, RZR, RngR, ErrR, UZR.150, Def)
    weighted.compared.player <- weighted.compared.player[1:length(weighted.compared.player)-1]
    
  }
  
  distances <- as.numeric(mahalanobis(x = sweep(as.matrix(weighted.Stats), 2, as.matrix(weighted.compared.player)), 
                                      center = FALSE, cov = cov(weighted.Stats)))
  fielders <- cbind(fielderNames, weighted.Stats, distances)
  
  return (fielders %>% arrange(distances))
              
}

# weighted.Mahalanobis("Andrew McCutchen", 30, 3)