# This code was written by Aaron Reuter on March 26th 2021
#       The goal of this code is to adjust the location and flight til when the ball is 2 meters in the area instead of 
#       where the ball lands

library("dplyr")
library("tidyverse")
library("datasets")
library("readxl")
library("xlsx")

#This line is based on your file path. If you are not sure what you need go to the Environment Tab, select import dataset, and find the positioning data file
PositioningData2021 <- read_excel("File Path")
readline(prompt="Press [enter] to continue")


my_data <- PositioningData2021
my_data.sizes <- nrow(my_data)
my_data.adjusted <- my_data

#This is used to find the new flight time, x_pos, and y_pos
# For all the physics that I did in to solve this work reference physics update in the Github Repository

#Heads up when I ran this code it took about 15 minutes so don't be surprised when it takes a while since it's iterating
  # Through every line of code
for (i in 1:my_data.sizes) {
  initial_velocity <- my_data[i, "ExitVelocity"]
  gravity <- 9.81
  exit_angle <- my_data[i, "VertAngle"] 
  
  if(!(is.na(exit_angle) == TRUE) && !(is.na(initial_velocity) == TRUE)) {
    max_height <- (((initial_velocity)^2) * (sin(exit_angle * 0.0174532925)^2)) / (2 * gravity)

  
    # if the max height is greater than 2 we are not dealing with a ground ball
    if(max_height > 2) {
      time_Max = initial_velocity*sin(exit_angle * 0.0174532925) / gravity
      time_Remaining = ((2*(max_height - 2))/gravity)^(1/2)
    

      #Now update the total time
      my_data.adjusted[i, "FlightTime"] <- time_Max + time_Remaining

      #Now update the x_pos, and y_pos
      exit_angle_xy <- my_data[i, "HorizAngle"]
      my_data.adjusted[i, "ballpos_x"] <- (initial_velocity * cos(exit_angle * 0.0174532925) * cos(exit_angle_xy * 0.0174532925)) * (my_data.adjusted[i, "FlightTime"])

      my_data.adjusted[i, "ballpos_y"] <- (initial_velocity * cos(exit_angle * 0.0174532925) * sin(exit_angle_xy * 0.0174532925)) * (my_data.adjusted[i, "FlightTime"])

      my_data.adjusted[i, "Distance"] <- ((my_data.adjusted(i, "ballpos_x"))^2 + (my_data.adjusted(i, "ballpos_y"))^2)^(1/2)
    }
  }
}

#Now upload this to the excel file

# This file was written from my file path so please update your file path to match this
write.xlsx(my_data.adjusted, file="Insert File Path here")
