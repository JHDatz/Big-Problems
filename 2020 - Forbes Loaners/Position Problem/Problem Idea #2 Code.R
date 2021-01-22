library(tidyverse)
library(Lahman)

# This script was used to filter and merge data together from Lahman and Fangraphs.

Master.1<-Master %>% separate(debut,c("year.debut","month.debut","day.debut"),sep="-") %>% 
  mutate(year.debut=as.numeric(year.debut))
Fielding0618<-filter(Fielding,yearID>=2006) %>% 
  left_join(Master.1,by=c("playerID"="playerID")) %>%
  mutate(age=yearID-birthYear,
         exp=yearID-year.debut,
         fldperc=(PO+A)/(PO+A+E))%>% 
  select(playerID,yearID,teamID,POS,G,GS,InnOuts,E,fldperc,DP,PB,WP,SB,CS,ZR,weight,height,age,exp)
FanGraphs0618<-read_csv("~/FanGraphs0618.csv")
Master.new<-Master %>% unite(Name,nameFirst,nameLast,sep=" ")
FanGraphs0618.new<-inner_join(FanGraphs0618,Master.new,by="Name") %>% mutate(yearID=Season,teamID=Team)
Fielding0618.new<-Fielding0618 %>% left_join(FanGraphs0618.new,by=c("playerID","yearID","teamID"))