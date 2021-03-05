install.packages("dplyr")


MLB <- read.csv(file="bigProblemsEvilGenuises.csv", header=TRUE, sep=",");

iData18 = read.csv(file="FanGraphsLeaderboard2015to2018.csv", header=TRUE, sep=",");
MLB$Name = sub("(\\w+),\\s(\\w+)","\\2 \\1", MLB$batterName)


iData18[,15] <- as.numeric(sub("%","",iData18[,15]))/100
iData18[,16] <- as.numeric(sub("%","",iData18[,16]))/100
for(i in 24:45)
{
  iData18[,i] <- as.numeric(sub("%","",iData18[,i]))/100
}


library(dplyr)
MLB_Verlander <- filter(MLB,pitcherName == "Verlander, Justin")

MLB$PrevPitchType <- NA

for(i in 2:nrow(MLB_Verlander))
{
  if((MLB_Verlander[i,4] == MLB_Verlander[i-1,4]+1) && (MLB_Verlander[i-1,24] != 0) && (MLB_Verlander[i-1,25] != 0))
  {
    MLB_Verlander[i,44] <- MLB_Verlander[i-1,16]
  }
}

MLB_Verlander <- na.omit(MLB_Verlander, cols="PrevPitchType")

table(is.na(MLB_Verlander$PrevPitchType))

merged <- merge(MLB_Verlander,iData18, by = "Name")
write.csv(merged, file = "merged.csv");

View(bigProblemsEvilGenuises.csv)
View(iData18)
View(MLB)
View(MLB_Verlander)
