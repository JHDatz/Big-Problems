extrapolate_event_list <- function(truncated_event_list) {
  
  extrapolated <- c(truncated_event_list[[3]], # Strikeout
    truncated_event_list[[4]], # Walk
    truncated_event_list[[5]], # Hit By Pitch 
    truncated_event_list[[1]], # Error 
    0.3*truncated_event_list[[6]], # Long Single 
    0.5*truncated_event_list[[6]], # Medium Single 
    0.2*truncated_event_list[[6]], # Short Single 
    0.8*truncated_event_list[[7]], # Short Double 
    0.2*truncated_event_list[[7]], # Long Double  
    truncated_event_list[[8]], # Triple
    truncated_event_list[[9]], # Home Run
    0.538*0.5*truncated_event_list[[2]], # GIDP 
    0.538*0.5*truncated_event_list[[2]], # Ground Out 
    0.153*truncated_event_list[[2]], # Line Drives 
    0.309*0.2*truncated_event_list[[2]], # Long Fly Balls 
    0.309*0.5*truncated_event_list[[2]], # Medium Fly Balls 
    0.309*0.3*truncated_event_list[[2]]) # Short Fly Balls
  
  return(extrapolated/sum(extrapolated)) # Made sure to normalize in case precision error causes vector to be slightly greater/less than 1
  
}

inning_simulation <- function (event_list){
  prob_dist <- c(0, cumsum(event_list)[1:16], 1)
  outs <- 0
  base_runners <- list(0, 0, 0, 0)
  
  while (outs < 3) {
    random_number <- runif(1, 0, 1)
    #print(random_number)
    #str(base_runners)
    #print(outs)
    
    if (random_number > prob_dist[[1]] && random_number < prob_dist[[2]]) {  #print('Strikeout')
      
      outs <- outs + 1
      
    } else if (random_number > prob_dist[[2]] && random_number < prob_dist[[3]]) {  #print('Walk')
      
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[3]] && random_number < prob_dist[[4]]) {  #print('Hit By Pitch')
      
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[4]] && random_number < prob_dist[[5]]) {  #print('Error')
      
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[5]] && random_number < prob_dist[[6]]) {  #print('Long Single')
      
      base_runners <- push_base_runners(base_runners, 2)
      base_runners <- add_base_runners(base_runners, 2)
      
    } else if (random_number > prob_dist[[6]] && random_number < prob_dist[[7]]) {  #print('Medium Single')
      
      base_runners <- push_base_runners(base_runners, 2)
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[7]] && random_number < prob_dist[[8]]) {  #print('Short Single')
      
      base_runners <- push_base_runners(base_runners, 1)
      base_runners <- add_base_runners(base_runners, 1)
      
    } else if (random_number > prob_dist[[8]] && random_number < prob_dist[[9]]) {  #print('Short Double')
      
      base_runners <- push_base_runners(base_runners, 2)
      base_runners <- add_base_runners(base_runners, 2)
      
    } else if (random_number > prob_dist[[9]] && random_number < prob_dist[[10]]) {  #print('Long Double')
      
      base_runners <- push_base_runners(base_runners, 3)
      base_runners <- add_base_runners(base_runners, 2)
      
    } else if (random_number > prob_dist[[10]] && random_number < prob_dist[[11]]) {  #print('Triple')
      
      base_runners <- push_base_runners(base_runners, 3)
      base_runners <- add_base_runners(base_runners, 3)
      
    } else if (random_number > prob_dist[[11]] && random_number < prob_dist[[12]]) {  #print('Home Run')
      
      base_runners <- push_base_runners(base_runners, 3)
      base_runners[[4]] = base_runners[[4]] + 1
      
    } else if (random_number > prob_dist[[12]] && random_number < prob_dist[[13]]) {  #print('Ground into double play')
      
      if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 0) {
        base_runners[[1]] <- 0
        outs <- outs + 2
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 0) {
        base_runners[[3]] <- 1
        base_runners[[2]] <- 0
        base_runners[[1]] <- 0
        outs <- outs + 2
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 1) {
        base_runners[[1]] <- 0
        outs <- outs + 2
        if (outs < 3) {
          base_runners[[3]] <- 0
          base_runners[[4]] <- base_runners[[4]] + 1
        }
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 1) {
        base_runners[[1]] <- 0
        outs <- outs + 2
      } else {
        
        outs <- outs + 1 
        
      }
      
    } else if (random_number > prob_dist[[13]] && random_number < prob_dist[[14]]) {  #print('Ground Out')
      
      if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 0) {
        base_runners <- push_base_runners(base_runners, 1)
        outs <- outs + 1
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 1 && base_runners[[3]] == 0) {
        base_runners <- push_base_runners(base_runners, 1)
        outs <- outs + 1
      } else if (base_runners[[1]] == 1 && base_runners[[2]] == 0 && base_runners[[3]] == 1) {
        base_runners <- push_base_runners(base_runners, 1)
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
      
    } else if (random_number > prob_dist[[14]] && random_number < prob_dist[[15]]) {  #print('Line Drive or Infield Fly')
      
      outs <- outs + 1
      
    } else if (random_number > prob_dist[[15]] && random_number < prob_dist[[16]]) {  #print('Long Fly Ball')
      
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
      
    } else if (random_number > prob_dist[[16]] && random_number < prob_dist[[17]]) {  #print('Medium Fly Ball')
      outs <- outs + 1
      if (outs < 3 && base_runners[[3]] == 1) {
        base_runners[[3]] <- 0
        base_runners[[4]] <- base_runners[[4]] + 1
      }
    } else if (random_number > prob_dist[[17]] && random_number < prob_dist[[18]]) {  #print('Short Fly Ball')
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
  if (base_runners[[position]] == 0) {
    base_runners[[position]] <- 1
  } else if (base_runners[[position]] != 0 && base_runners[[position + 1]] == 0){
    base_runners[[position + 1]] <- 1
  } else if (base_runners[[position]] != 0 && base_runners[[position + 1]] != 0 && base_runners[[position + 2]] == 0) {
    base_runners[[position + 2]] <- 1
  } else {base_runners[[4]] <- base_runners[[4]] + 1}
  
  return(base_runners)
}

