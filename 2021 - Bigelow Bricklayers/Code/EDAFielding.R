df %>% na.omit() %>%
  mutate(FirstBaseDistance = sqrt((X3 - ballpos_x)**2 + (Y3 - ballpos_y)**2),
         SecondBaseDistance = sqrt((X4 - ballpos_x)**2 + (Y4 - ballpos_y)**2),
         ThirdBaseDistance = sqrt((X5 - ballpos_x)**2 + (Y5 - ballpos_y)**2),
         shortstopDistance = sqrt((X6 - ballpos_x)**2 + (Y6 - ballpos_y)**2),
         leftFieldDistance = sqrt((X7 - ballpos_x)**2 + (Y7 - ballpos_y)**2),
         centerFieldDistance = sqrt((X8 - ballpos_x)**2 + (Y8 - ballpos_y)**2),
         rightFieldDistance = sqrt((X9 - ballpos_x)**2 + (Y9 - ballpos_y)**2),
         InfOf = ifelse(ballpos_x**2 + ballpos_y**2 < 175**2, "Infield", "Outfield"),
         outOfPark = ifelse(ballpos_x**2 + ballpos_y**2 < 400**2, FALSE, TRUE),
         foulOrBad = ifelse((ballpos_x < ballpos_y) && (-ballpos_x < ballpos_y), FALSE, TRUE),
         cannot.model = outOfPark || foulOrBad,
         responsibility = ifelse(InfOf == "Infield", pmin(FirstBaseDistance, SecondBaseDistance, ThirdBaseDistance, shortstopDistance),
                                 pmin(leftFieldDistance, centerFieldDistance, rightFieldDistance)),
         responsibility1B = ifelse(responsibility == FirstBaseDistance, "1B", ""),
         responsibility2B = ifelse(responsibility == SecondBaseDistance, "2B", ""),
         responsibility3B = ifelse(responsibility == ThirdBaseDistance, "3B", ""),
         responsibilitySS = ifelse(responsibility == shortstopDistance, "SS", ""),
         responsibilityLF = ifelse(responsibility == leftFieldDistance, "LF", ""),
         responsibilityCF = ifelse(responsibility == centerFieldDistance, "CF", ""),
         responsibilityRF = ifelse(responsibility == rightFieldDistance, "RF", ""),
         responsibility.text = paste0(responsibility1B, responsibility2B, responsibility3B, responsibilitySS,
                                      responsibilityLF, responsibilityCF, responsibilityRF),
         ifCaught = (HitValue == 0)) -> df

ggplot(data = df %>% filter(responsibility.text == "LF")) + aes(responsibility) + geom_density()
ggplot(data = df %>% filter(responsibility.text == "CF")) + aes(responsibility) + geom_density()
ggplot(data = df %>% filter(responsibility.text == "RF")) + aes(responsibility) + geom_density()

df %>% filter(responsibility.text %in% c('LF', 'CF', 'RF')) %>% mutate(cuts = cut(responsibility, seq(0,175,5))) %>%
  group_by(cuts) %>% summarize(success = sum(ifCaught)/n()) -> generic.outfield.pdf