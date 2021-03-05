#read in file
MLB <- read.csv(file="bigProblems.csv", header=TRUE, sep=",");

#select cols with numerical data on pitch, label(pitch type) is last col.
#colums are: column_names = [Init_Vel, Plate_Vel, Plate_X, Plate_Z, Break_X, Break_Z, SpinRate, SpinDirection,PitchTypeCode]
dataPitchClass = MLB[,c(7,8,10,11,12,13,14,15,20,21,16)];
#labels = MLB[,c(16)]
 
dataPitchClass$PitcherHand <- as.character(dataPitchClass$PitcherHand)
dataPitchClass$PitcherHand[which(dataPitchClass$PitcherHand=="L")] <- "0"
dataPitchClass$PitcherHand[which(dataPitchClass$PitcherHand=="R")] <- "1"
dataPitchClass$PitcherHand <- as.numeric(dataPitchClass$PitcherHand)

dataPitchClass$BatSide <- as.character(dataPitchClass$BatSide)
dataPitchClass$BatSide[which(dataPitchClass$BatSide=="L")] <- "0"
dataPitchClass$BatSide[which(dataPitchClass$BatSide=="R")] <- "1"
dataPitchClass$BatSide <- as.numeric(dataPitchClass$BatSide)

#omit rows with n/a vals
dataPitchClass<-na.omit(dataPitchClass);

#define function to normalize data(get all data between 0-1)
range01 <- function(x){(x-min(x))/(max(x)-min(x))};

#apply function to data set and save new normalized set
for(i in 3:(length(dataPitchClass[1,])-1))
{
  dataPitchClass[,i] = range01(dataPitchClass[,i]);
}

#view normalized data
#View(dataPitchClass)

source("stratified.R")

sample = stratified(dataPitchClass, group = 11, size = 25000);

test = stratified(dataPitchClass, group = 11, size = 100);


sample <- subset(sample, (PitchTypeCode!="EP")) 
sample <- subset(sample, (PitchTypeCode!="FO"))
sample <- subset(sample, (PitchTypeCode!="KN"))
sample <- subset(sample, (PitchTypeCode!="PO"))
sample <- subset(sample, (PitchTypeCode!="SC"))
sample <- subset(sample, (PitchTypeCode!="UN"))
sample <- subset(sample, (PitchTypeCode!="AB"))
sample <- subset(sample, (PitchTypeCode!="CB"))
sample <- subset(sample, (PitchTypeCode!="IN "))
sample <- subset(sample, (PitchTypeCode!="IN"))
sample <- subset(sample, (PitchTypeCode!="SI"))
sample <- subset(sample, (PitchTypeCode!="FS"))
sample <- subset(sample, (PitchTypeCode!="SL"))
sample <- subset(sample, (PitchTypeCode!="FA"))
sample <- subset(sample, (PitchTypeCode!="KC"))

test <- subset(test, (PitchTypeCode!="EP")) 
test <- subset(test, (PitchTypeCode!="FO"))
test <- subset(test, (PitchTypeCode!="KN"))
test <- subset(test, (PitchTypeCode!="PO"))
test <- subset(test, (PitchTypeCode!="SC"))
test <- subset(test, (PitchTypeCode!="UN"))
test <- subset(test, (PitchTypeCode!="AB"))
test <- subset(test, (PitchTypeCode!="CB"))
test <- subset(test, (PitchTypeCode!="IN "))
test <- subset(test, (PitchTypeCode!="IN"))
test <- subset(test, (PitchTypeCode!="SI"))
test <- subset(test, (PitchTypeCode!="FS"))
test <- subset(test, (PitchTypeCode!="SL"))
test <- subset(test, (PitchTypeCode!="FA"))
test <- subset(test, (PitchTypeCode!="KC"))


#write normalized train and test sets to csv files
write.csv(sample,file = "pitch_train.csv");
write.csv(test, file = "pitch_test.csv");


View(table(sample[,11]))
View(table(test[,11]))



