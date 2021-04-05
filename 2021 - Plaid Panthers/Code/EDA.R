setwd("~/Desktop/coding/Big Problems (Github)/2021 - Plaid Panthers/Code")
source('chainedMahalanobis.R')

# Some Exploratory Graphs of the variables for outfielders

ggplot(fielding_all) + aes(x = Age, y = rARM) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(fielding_all) + aes(x = Age, y = rGFP) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(fielding_all) + aes(x = Age, y = rPM) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(fielding_all %>% filter(Pos %in% c("LF", "CF", "RF"), !is.na(RZR))) + aes(x = Age, y = RZR) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(fielding_all %>% filter(Pos %in% c("LF", "CF", "RF"), !is.na(RZR))) + aes(x = Age, y = ErrR) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(fielding_all %>% filter(Pos %in% c("LF", "CF", "RF"), !is.na(UZR.150))) + aes(x = Age, y = UZR.150) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

# Some takeaways from this were:
#
# Age does not have a significant impact towards the rARM, rGFP, rPM, or UZR.150 stats when talking about players as a whole.
#
# ErrR went up at a very slight rate, and RZR went down at a very significant rate. It makes sense that a players RZR would go down
# as they age because RZR measures the amount of balls successfully converted to an out (which they cannot do as effectively when
# a player's body is losing strength), but strange that the components of DRS are not affected by this.

ggplot(fielding_all %>% filter(Pos %in% c("LF", "CF", "RF"))) + aes(x = RZR, y = DRS) + geom_point()

# The relationship between them is a bit strange as well.

# How about for McCutchen specifically?

fielding_all %>% filter(Name == "Andrew McCutchen")

fielding_all %>% filter(Name == "Andrew McCutchen") -> cutchData

ggplot(cutchData) + aes(x = Age, y = rARM) + geom_point() +
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(cutchData) + aes(x = Age, y = rGFP) + geom_point() +
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(cutchData) + aes(x = Age, y = rPM) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

# Similarly, not much noteworthy difference with respect to the total population. How about in a "cluster" for him?
# Exploratory using top 5 similar players from chainedMahalanobis

chained.mahalanobis("Andrew McCutchen", 32) %>% head(6) %>% select(Name) -> cutchCluster
cutchCluster <- fielding_all %>% 
  inner_join(cutchCluster, by = "Name")

ggplot(cutchCluster) + aes(x = Age, y = rARM/Inn) + geom_point() +
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(cutchCluster) + aes(x = Age, y = rGFP/Inn) + geom_point() +
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(cutchCluster) + aes(x = Age, y = rPM/Inn) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(cutchCluster) + aes(x = Age, y = DRS_per_Inning) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 1, raw = TRUE))

ggplot(cutchCluster) + aes(x = Age, y = Inn) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 2, raw = TRUE))

# A little bit more of a decline spotted when designating a cluster, but there's high variance involved.

lmARM <- lm(data = cutchCluster, rARM/Inn ~ Age)
lmGFP <- lm(data = cutchCluster, rGFP/Inn ~ Age)
lmPM <- lm(data = cutchCluster, rPM/Inn ~ Age)
lmINN <- lm(data = cutchCluster, Inn ~ Age)

predicted.lmARM <- predict.lm(lmARM, data.frame(Age = 33))
predicted.GFP <- predict.lm(lmGFP, data.frame(Age = 33))
predicted.rPM <-predict.lm(lmPM, data.frame(Age = 33))
predicted.inn <- predict.lm(lmINN, data.frame(Age = 33))

predicted.inn*(predicted.lmARM + predicted.GFP + predicted.rPM)