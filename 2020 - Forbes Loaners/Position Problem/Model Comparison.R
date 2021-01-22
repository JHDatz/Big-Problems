library(tidyverse)
library(randomForest)
library(caret)
library(MASS)
library(class)
library(e1071)
setwd("~/Desktop/coding/R")

data <- read_csv('Fielding0618.csv')

# Let's start by massaging the data a bit. Firstly, since we don't have a distinction between
# pitchers and relief pitchers, lets ignore them for now.

data %>% filter(Pos != 'P') -> data

# Next, I'd like to add 3 variables:
#
# 1. switch.Pos, a variable that counts how many positions a player has played over their career.
# 2. Experience, a variable denoting years of service in the Majors.
# 3. first.Pos, a variable that stores a player's first position.

data %>% group_by(Name, Pos) %>% summarize(n = n()) %>% group_by(Name) %>% summarize(switch.Pos = n()) -> switch_Pos
data %>% merge(switch_Pos, by='Name') -> data

data %>% group_by(Name) %>% summarize(min.Season = min(Season)) -> min_season
data %>% merge(min_season, by='Name') %>% mutate(Experience = Season - min.Season) -> data

data %>% group_by(Name) %>% summarize(first.Pos = first(Pos)) -> first_Pos
data %>% merge(first_Pos, by='Name') -> data

# Now, here's my first step towards a boolean value for a Random Forest. I am going use Pos and first.Pos to determine 
# when a player has switched positions from the one he started playing at in the majors. 

data %>% mutate(Swapped = ifelse(Pos != first.Pos, 1, 0)) -> data

# Before I go any further, I'd like to note that there are 3 challenges I see in this dataset that will be difficult
# to tease out...
#
# 1. Utility players - players who are entirely defined by their flexibility and will change many positions
# during the year by default.
#
# 2. Being "demoted" - players who could play SS at the Tigers, but once being traded with the Yankees, they moved
# to an easier position because the Yankees had a better SS.
#
# 3. Emergency Situations - players that filled a position only because a teammate was injured, not necessarily because
# the team wanted them there.
#
# I can't think of good ways to get around 1 or 2 right now - handling #1 encompassed my clustering idea though. For #1
# I will skip for now by filtering out cases with high levels of switch.Pos.
#
# For #3 I think the following can be done to mitigate the issue:
#
# 1. Focus on guys for which switch.Pos == 2, that is, they changed positions once in their career. (Through some more
# massaging we can expand switch.Pos to higher numbers.)
#
# 2. Eliminate the filling in at the 13th inning situation by making sure the number of game appearances 
# given for a position is greater than 5.

data %>% filter(switch.Pos == 2, G > 5) -> data

# From here I will filter out to the variables we decided would be useful from our last group meeting.

data[c('Age',	'Experience', 'Pos',	'G',	'GS',	'Inn',	'PO',	'A',	'E',	'PB',	'WP',	'FP',	'rSZ',	'rCERA',	'rSB',
       'rGDP', 'rGFP',	'rPM',	'DRS',	'RZR',	'DPR',	'RngR',	'FRM',	'ErrR',	'UZR',	
       'Def', 'Swapped')] -> data

# Lastly, do some one-hot encoding for the position variables, fill NAs with 0s, and make sure that Swapped is
# considered a factor variable by R.

dmy <- dummyVars(" ~ .", data = data)
data <- data.frame(predict(dmy, newdata = data))
data[is.na(data)] <- 0
data$Swapped <- as.factor(data$Swapped)

# Now we'll prepare the modeling.

# Bagging

trainingSet <- sample(1:nrow(data), 0.8*nrow(data))
bag.Swapped = randomForest(Swapped~., data = data, subset = trainingSet, mtry = length(data)-1, importance = TRUE)

yhat.bag <- predict(bag.Swapped, newdata=data[-trainingSet,])

confusionMatrix(yhat.bag, data[-trainingSet,]$Swapped)
importance(bag.Swapped)

# Random Forest

forest.Swapped = randomForest(Swapped~., data = data, subset = trainingSet, 
                              mtry = sqrt(length(data)-1), importance = TRUE)

yhat.forest <- predict(forest.Swapped, newdata=data[-trainingSet,])

confusionMatrix(yhat.forest, data[-trainingSet,]$Swapped)
importance(forest.Swapped)

# Logistic Regression, for comparison purposes:

logreg.Swapped = glm(Swapped~., data =  data[trainingSet,], family='binomial')
yhat.logreg = predict(logreg.Swapped, newdata = data[-trainingSet,], type = 'response')

yhat.logreg[yhat.logreg > 0.5] <- 1
yhat.logreg[yhat.logreg <= 0.5] <- 0

confusionMatrix(as.factor(yhat.logreg), data[-trainingSet,]$Swapped)

# Linear/Quadratic Discriminant Analysis, for comparison purposes:

lda.Swapped = lda(Swapped~., data = data[trainingSet,])
yhat.lda = predict(lda.Swapped, newdata = data[-trainingSet,], type = 'response')

confusionMatrix(yhat.lda$class, data[-trainingSet,]$Swapped)

qda.Swapped = qda(Swapped~., data = data[trainingSet,])
yhat.qda = predict(qda.Swapped, newdata = data[-trainingSet,], type = 'response')

confusionMatrix(yhat.qda$class, data[-trainingSet,]$Swapped)

# k-Nearest Neighbors, for comparison purposes

knn.train = data[,names(data) != "Swapped"][trainingSet,]
knn.test = data[,names(data) != "Swapped"][-trainingSet,]
knn.predictor = data["Swapped"][trainingSet,]

knn.Swapped = knn(knn.train, knn.test, knn.predictor, k = 100)

confusionMatrix(knn.Swapped, data["Swapped"][-trainingSet,])

# Support Vector Machine, for comparison purposes

svm.Swapped = tune(svm, Swapped~., data = data[trainingSet,], kernel = 'radial', ranges = c(0.1, 0.2, 0.3, 0.4, 0.5))
summary(svm.Swapped)

svm.Swapped = tune(svm, Swapped~., data = data[trainingSet,], kernel = 'radial', 
                   ranges = list(cost = c(0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5), 
                                 gamma = c(0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1)))
summary(svm.Swapped)