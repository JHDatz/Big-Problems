library(tidyverse)
library(mosaic)
library(dplyr)
library(Lahman)
Fielding0618<-read_csv("~/Fielding0618.csv")
Fielding0618.P<-Fielding0618 %>%
  filter(Pos=="P") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rSZ,rSB,rGFP,rPM,DRS)
Fielding0618.C<-Fielding0618 %>%
  filter(Pos=="C") %>% 
  mutate(CSP= (CS)/(CS+SB)) %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,CSP,PB,WP,FP,rSZ,rCERA,rSB,rGFP,DRS,FRM,Def)
Fielding0618.1B<-Fielding0618 %>%
  filter(Pos=="1B") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rGDP,rGFP,rPM,DRS,RZR,DPR,RngR,ErrR,"UZR","UZR/150",Def)
Fielding0618.2B<-Fielding0618 %>%
  filter(Pos=="2B") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rGDP,rGFP,rPM,DRS,RZR,DPR,RngR,ErrR,"UZR","UZR/150",Def)
Fielding0618.3B<-Fielding0618 %>%
  filter(Pos=="3B") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rGDP,rGFP,rPM,DRS,RZR,DPR,RngR,ErrR,"UZR","UZR/150",Def)
Fielding0618.SS<-Fielding0618 %>%
  filter(Pos=="SS") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rGDP,rGFP,rPM,DRS,RZR,DPR,RngR,ErrR,"UZR","UZR/150",Def)
Fielding0618.LF<-Fielding0618 %>%
  filter(Pos=="LF") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rARM,rGFP,rPM,DRS,RZR,ARM,RngR,ErrR,"UZR","UZR/150",Def)
Fielding0618.CF<-Fielding0618 %>%
  filter(Pos=="CF") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rARM,rGFP,rPM,DRS,RZR,ARM,RngR,ErrR,"UZR","UZR/150",Def)
Fielding0618.RF<-Fielding0618 %>%
  filter(Pos=="RF") %>% 
  select(Season,Name,Team,Age,Exp,G,GS,Inn,PO,A,E,FP,rARM,rGFP,rPM,DRS,RZR,ARM,RngR,ErrR,"UZR","UZR/150",Def)
