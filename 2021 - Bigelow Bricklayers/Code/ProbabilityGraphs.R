# This code was written by Aaron Reuter on March 26th 2021
#       The goal of this code is to adjust the location and flight til when the ball is 2 meters in the area instead of 
#       where the ball lands

library("dplyr")
library("tidyverse")
library("datasets")
library("readxl")
library("xlsx")
library("plot3D")
library("plotly")
library("rgl")

#This line is based on your file path. If you are not sure what you need go to the Environment Tab, select import dataset, and find the positioning data file


#LOL above is just PhysicsUpdateR.R just for reference
parzen <- matrix(nrow=8, ncol=28)

for (i in 1:8) {
  for (j in 1:28) {
    parzen[i, j] <- 0
  }
}



x_array <- seq(from = -70, to = 70, by = 20)
y_array <- seq(from = 25, to = 565, by = 20)
readline(prompt="Press [enter] to continue")


for (i in 1:27067) {
  value_j <- 0
  value_k <- 0
  for (j in 1:8) {
    if((25 + 20*(j)) > my_data.adjusted[i, "ballpos_x"]) {
      value_j<- j
      break
    }
  }
  for (k in 1:28) {
    if(-70 + 20*(k) > my_data.adjusted[i, "ballpos_y"]) {
      value_k <- k
      break
    }
  }
  str(i)
  parzen[value_j, value_k] <- parzen[value_j, value_k] + 1
}

for (i in 1:8) {
  for (j in 1:28) {
    parzen[i, j] <- parzen[i, j] / (27067 * 20^2)
  }
}
#z_array <- as.vector(parzen)

#plot3d(x_array, y_array, z_array) #This is the final graph
