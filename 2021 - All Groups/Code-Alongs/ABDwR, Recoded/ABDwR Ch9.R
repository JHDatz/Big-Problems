library(tidyverse)
library(Lahman)
library(RMySQL)
require(DBI)

source("helper_code/one_simulation_68.R")

# This code is a shortened and modified version of Chapter 9 in ABDwR.
# It is modified to:
#   Make calls to the MySQL server instead of heavily modifying a CSV file.
#   By referring to a pre-constructed view, many lines can be simplified.
#   Provide some commentary to compare/contrast methods with other books.
#   Fix some minor errors in code in the book (ex: mislabling column names).

# Get data from MySQL server

conn <- dbConnect(MySQL(), 
                  dbname = "merged",
                  user = "redacted", 
                  password = "redacted",
                  host = "redacted",
                  port = 3306)

dbGetQuery(conn, n = -1, 'call computeStates2(2016, 2016)')
data2016 <- dbGetQuery(conn, n = -1, 'select * from stateTracker')

dbDisconnect(conn)

# Remove innings that don't go to 3 outs, innings where no scores
# are made, and stick to ABs. Lastly, coalesce all 3 out transitions
# to just a single 3 out state, regardless of runners on base. This
# drops the 32 states in the end_state column to 25 states.

data2016 %>% filter(start_state != end_state | runs_scored > 0) %>%
  filter(outs_inning == 3, BAT_EVENT_FL == TRUE) %>%
  mutate(end_state = gsub("[0-1]{3} 3", "3", end_state)) -> data2016C

# Create the transition matrix T and the prob. matrix P. Add a row 
# to P so that it's clear that the 3 out state is an absorbing state.

data2016C %>% select(start_state, end_state) %>% table() -> T_matrix
T_matrix %>% prop.table(1) -> P_matrix
P_matrix <- rbind(P_matrix, c(rep(0, 24), 1))

# Lets look at P_matrix like it's a list and see some particular states.

P_matrix %>% as_tibble(rownames = "start_state") %>%
  filter(start_state == "010 2") %>%
  gather(key = "end_state", value = "Prob", -start_state) %>%
  filter(Prob > 0)

# Create a function which sums up the number
# of runners and outs. This is to aid us in creating
# the equation on page 206 for every permutation of
# state changes.

count_runners_out <- function(s) {
  s %>% str_split("") %>%
    pluck(1) %>%
    as.numeric() %>%
    sum(na.rm = TRUE)
}

runners_out <- sapply(row.names(T_matrix), count_runners_out)[-25]

R <- outer(runners_out + 1, runners_out, FUN="-")
names(R) <- dimnames(T_matrix)$start_state[-25]
R <- cbind(R, rep(0, 24))

simulate_half_inning <- function(P, R, start = 1) {
  s <- start
  path <- NULL
  runs <- 0
  while (s < 25) {
    s.new <- sample(1:25, size = 1, prob = P[s,])
    path <- c(path, s.new)
    runs <- runs + R[s, s.new]
    s <- s.new
  }
  runs
}

set.seed(111653)

# Use Markov Chains to get Run Expectancy Matrix

RUNS <- replicate(10000, simulate_half_inning(P_matrix, R, 1))

RUNS.j <- function(j) {
  mean(replicate(10000, simulate_half_inning(P_matrix, R, j)))
}

RE_bat <- sapply(1:24, RUNS.j) %>%
  matrix(nrow = 8, ncol = 3, byrow = TRUE,
         dimnames = list(c("000", "001", "010", "011", "100", "101", "110", "111"),
                         c("0 outs", "1 out", "2 outs")))

# Use Markov Chains to analyze the Prob of moving to a particular state after
# 3 states, and see the average number of state changes (i.e, PAs) before
# moving to the 3-out absorbing state.

P_matrix_3 <- P_matrix %*% P_matrix %*% P_matrix

P_matrix_3 %>%
  as_tibble(rownames = 'start_state') %>%
  filter(start_state == "000 0") %>%
  gather(key = "end_state", value = "Prob", -start_state) %>%
  arrange(desc(Prob)) %>%
  head()

Q <- P_matrix[-25, -25]
N <- solve(diag(rep(1,24)) - Q)

N.0000 <- round(N["000 0", ], 2)
head(data.frame(N = N.0000))

sum(N.0000)

Length <- round(t(N %*% rep(1, 24)), 2)
data.frame(Length = Length[1, 1:8])

# We'll now take a look at the Markov Chain distributions
# For individual teams. When getting to the team level, we might
# not have enough data to adequately represent the team's true
# probability distribution, so we introduce a smoothing curve from
# all team data to fill in the gaps a bit.

data2016C %>%
  mutate(HOME_TEAM_ID = str_sub(GAME_ID, 1, 3),
         BATTING.TEAM = ifelse(BAT_HOME_ID == 0, AWAY_TEAM_ID, HOME_TEAM_ID)) -> data2016C

data2016C %>%
  group_by(BATTING.TEAM, start_state, end_state) %>%
  count() -> Team.T

Team.T %>%
  filter(BATTING.TEAM == "ANA") %>%
  head()

data2016C %>%
  filter(start_state == "100 2") %>%
  group_by(BATTING.TEAM, start_state, end_state) %>%
  tally() -> Team.T.S

Team.T.S %>%
  ungroup() %>%
  sample_n(size = 6)

# Now let's look at the Nationals, with a smoothing curve
# introduced.

Team.T.S %>%
  filter(BATTING.TEAM == "WAS") %>%
  mutate(p = n / sum(n)) -> WAS.Trans

data2016C %>%
  filter(start_state == "100 2") %>%
  group_by(end_state) %>%
  tally() %>%
  mutate(p = n / sum(n)) -> ALL.Trans

WAS.Trans %>%
  inner_join(ALL.Trans, by = "end_state") %>%
  mutate(p.EST = n.x / (1274 + n.x) * p.x + 1274 / (1274 + n.x) * p.y) %>%
  select(BATTING.TEAM, start_state, p.x, p.y, p.EST)

# Moving on to 9.3 - Simulating a Baseball Season...
#
# The functions used in this analysis were moved to the file
# one_simulation_68.R after creating them. Additional commentary
# can be found there.

s.talent <- 0.20
RESULTS <- one.simulation.68(0.20)

display_standings <- function(data, league) {
  data %>%
    filter(League == league) %>%
    select(Team, Wins) %>%
    mutate(Losses = 162 - Wins) %>%
    arrange(desc(Wins))
}

map(1:2, display_standings, data = RESULTS) %>%
  bind_cols()

RESULTS %>%
  filter(Winner.Lg == 1) %>%
  select(Team, Winner.WS)       

# Let's simulate many seasons to see how closely
# Talent allows a team to win.

Many.Results <- map_df(rep(0.2, 1000), one.simulation.68)

ggplot(Many.Results, aes(Talent, Wins)) + geom_point(alpha = 0.05)

ggplot(filter(Many.Results, Talent > -0.05, Talent < 0.05), aes(Wins)) + geom_histogram(color = "red", fill = "white")

fit1 <- glm(Winner.Lg ~ Talent, data = Many.Results, family = "binomial")
fit2 <- glm(Winner.WS ~ Talent, data = Many.Results, family = "binomial")

talent_values <- seq(-0.4, 0.4, length.out = 100)
tdf <- tibble(Talent = talent_values)
df1 <- tibble(
  Talent = talent_values,
  Probability = predict(fit1, tdf, type = "response"),
  Outcome = "Pennant")
df2 <- tibble(
  Talent = talent_values,
  Probability = predict(fit2, tdf, type = "response"),
  Outcome = "World Series")

ggplot(bind_rows(df1, df2), aes(Talent, Probability, linetype = Outcome)) + geom_line() + ylim(0,1)