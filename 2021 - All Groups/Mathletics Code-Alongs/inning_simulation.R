extrapolate_event_list <- function(truncated_event_list) {
  
}

inning_simulation <- function (event_list){
  prob_dist <- c(0, cumsum(event_list)[1:16], 1)
  outs <- 0
  base_runners <- list(0, 0, 0, 0)
  
  while (outs < 3) {
    random_number <- runif(1, 0, 1)
    
    if (random_number > prob_dist[[1]] && random_number< prob_dist[[2]]) { # Strikeout
      
      outs <- outs + 1
      
    } else if (random_number > prob_dist[[2]] && random_number < prob_dist[[3]]) { # Walk
      
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[3]] && random_number < prob_dist[[4]]) { # Hit By Pitch
      
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[4]] && random_number < prob_dist[[5]]) { # Error
      
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[5]] && random_number < prob_dist[[6]]) { # Long Single
      
      base_runners <- push_base_runners(base_runners, 2)
      base_runners <- add_base_runners(base_runners, 2)
      
    } else if (random_number > prob_dist[[6]] && random_number < prob_dist[[7]]) { # Medium Single
      
      base_runners <- push_base_runners(base_runners, 2)
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[7]] && random_number < prob_dist[[8]]) { # Short Single
      
      base_runners <- push_base_runners(base_runners, 1)
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[8]] && random_number < prob_dist[[9]]) { # Short Double
      
      base_runners <- push_base_runners(base_runners, 2)
      base_runners <- add_base_runners(base_runners, 2)
      
    } else if (random_number > prob_dist[[9]] && random_number < prob_dist[[10]]) { # Long Double
      
      base_runners <- push_base_runners(base_runners, 3)
      base_runners <- add_base_runners(base_runners, 2)
      
    } else if (random_number > prob_dist[[10]] && random_number < prob_dist[[11]]) { # Triple
      
      base_runners <- push_base_runners(base_runners, 3)
      base_runners <- add_base_runners(base_runners, 3)
      
    } else if (random_number > prob_dist[[11]] && random_number < prob_dist[[12]]) { # Home Run
      
      base_runners <- push_base_runners(base_runners, 3)
      base_runners[[4]] = base_runners[[4]] + 1
      
    } else if (random_number > prob_dist[[12]] && random_number < prob_dist[[13]]) { # Ground into double play
      
      if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 0) {
        base_runners[[1]] <- 0
        outs <- outs + 2
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 0) {
        base_runners[[3]] <- 1
        base_runners[[2]] <- 0
        base_runners[[1]] <- 0
        outs <- out + 2
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 1) {
        base_runners[[1]] <- 0
        outs <- out + 2
        if (outs < 3) {
          base_runners[[3]] <- 0
          base_runners[[4]] <- base_runners + 1
        }
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 1) {
        base_runners[[1]] <- 0
        base_runners[[2]] <- 0
        outs <- out + 2
        if (outs < 3) {
          base_runners[[4]] <- base_runners + 1
        }
      }
      
    } else if (random_number > prob_dist[[13]] && random_number < prob_dist[[14]]) { # Ground Out
      
      if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 0) {
        base_runners <- push_base_runners(base_runners, 1)
        outs <- outs + 1
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 0) {
        base_runners[[3]] <- 1
        base_runners[[0]] <- 0
        outs <- outs + 1
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 1) {
        base_runners[[2]] <- 1
        base_runners[[1]] <- 0
        outs <- outs + 1
        if (outs < 3) {
          base_runners[[3]] <- 0
          base_runners[[4]] <- base_runners[[4]] + 1
        }
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 1) {
        base_runners[[1]] <- 0
        outs <- outs + 1
        if (outs < 3) {
          base_runners[[3]] <- 0
          base_runners[[4]] <- base_runners[[4]] + 1
        }
      } else if (base_runners[[1]] == 0 && base_runners[[2]] == 1 && base_runners[[3]] == 0) {
        base_runners <- push_base_runners(base_runners, 1)
        outs <- outs + 1
      } else {
        outs <- outs + 1
      }
      
    } else if (random_number > prob_dist[[14]] && random_number < prob_dist[[15]]) { # Line Drive or Infield Fly
      
      outs <- outs + 1
      
    } else if (random_number > prob_dist[[15]] && random_number < prob_dist[[16]]) { # Long Fly Ball
      
      outs <- outs + 1
      if (outs < 3) {
        if (base_runners[[2]] == 1 || base_runners[[3]] == 1 && base_runners[[1]] == 0) {
          base_runners <- push_base_runners(base_runners, 1)
        } else if (base_runners[[2]] == 1 || base_runners[[3]] == 1 && base_runners[[1]] == 1) {
          base_runners <- push_base_runners(base_runners, 1)
          base_runners[[2]] <- 0
          base_runners[[1]] <- 1
        }
      }
      
    } else if (random_number > prob_dist[[16]] && random_number < prob_dist[[17]]) { # Medium Fly Ball
      outs <- outs + 1
      if (outs < 3 && base_runners[[3]] == 1) {
        base_runners[[3]] <- 0
        base_runners[[4]] <- base_runners[[4]] + 1
      }
    } else if (random_number > prob_dist[[17]] && random_number < prob_dist[[18]]) { # Short Fly Ball
      outs <- outs + 1
    }
    
  }
  
  return(base_runners[[4]])
    
}

push_base_runners <- function(base_runners, push) {
  
  for (i in 1:push) {
    for (j in 3:1) {
      if (base_runners[[j]] != 0) {
        base_runners[[j+1]] <- base_runners[[j+1]] + 1
        base_runners[[j]] <- base_runners[[j]] - 1
      }
    }
  }
  
  return(base_runners)
  
}

add_base_runners <- function(base_runners, position) {
  if (base_runners[[position]] != 0) {
    base_runners[[position]] <- 1
  } else if (base_runners[[position]] != 0 && base_runners[[position + 1]] == 0){
    base_runners[[position + 1]] <- 1
  } else if (base_runners[[position]] != 0 && base_runners[[position + 1]] != 0 && base_runners[[position + 2]] == 0) {
    base_runners[[position + 2]] <- 1
  } else {base_runners[[4]] <- base_runners[[4]] + 1}
  
  return(base_runners)
}

