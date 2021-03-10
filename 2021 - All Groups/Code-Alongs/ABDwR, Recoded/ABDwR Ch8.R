library(tidyverse)
library(Lahman)
library(RMySQL)
library(broom)
library(ggrepel)
require(DBI)

Master %>%
  filter(nameFirst == "Mickey", nameLast == "Mantle") %>%
  pull(playerID) -> mantle_id

batting <- Batting %>% replace_na(list(SF = 0, HBP = 0))

get_stats <- function(player.id) {
  batting %>%
    filter(playerID == player.id) %>%
    inner_join(Master, by = "playerID") %>%
    mutate(birthyear = ifelse(birthMonth >= 7, birthYear + 1, birthYear),
           Age = yearID - birthyear,
           SLG = (H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/AB,
           OBP = (H + BB + HBP)/(AB + BB + HBP + SF),
           OPS = SLG + OBP) %>%
    select(Age, SLG, OBP, OPS)
}

Mantle <- get_stats(mantle_id)

ggplot(Mantle) + aes(Age, OPS) + geom_point()

fit_model <- function(d) {
  fit <- lm(OPS ~ I(Age - 30) + I((Age - 30)^2), data = d)
  b <- coef(fit)
  Age.max <- 30 - b[2] / b[3] / 2
  Max <- b[1] - b[2] ^ 2 / b[3] / 4
  list(fit = fit, Age.max = Age.max, Max = Max)
}

F2 <- fit_model(Mantle)
coef(F2$fit)
c(F2$Age.max, F2$Max)

ggplot(Mantle) + aes(Age, OPS) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 2, raw = TRUE)) +
  geom_vline(xintercept = F2$Age.max, linetype = "dashed", color = "darkgrey") +
  geom_hline(yintercept = F2$Max, linetype = "dashed", color = "darkgrey") +
  annotate(geom = "text", x = c(29, 20), y = c(0.72, 1.1), label = c("Peak Age", "Max"), size = 5)

F2 %>% pluck("fit") %>% summary()

batting %>%
  group_by(playerID) %>%
  summarize(Career.AB = sum(AB, na.rm = TRUE)) %>%
  inner_join(batting, by = "playerID") %>%
  filter(Career.AB >= 2000) -> batting_2000

Fielding %>%
  group_by(playerID, POS) %>%
  summarize(Games = sum(G)) %>%
  arrange(playerID, desc(Games)) %>%
  filter(POS == first(POS)) -> Positions

batting_2000 <- batting_2000 %>% inner_join(Positions, by = "playerID")

vars <- c("G", "AB", "R", "H", "X2B", "X3B", "HR", "RBI", "BB", "SO", "SB")

batting %>%
  group_by(playerID) %>%
  summarize_at(vars, sum, na.rm = TRUE) -> C.totals

C.totals %>%
  mutate(AVG = H/AB,
         SLG = (H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/AB) -> C.totals

C.totals %>%
  inner_join(Positions, by = "playerID") %>%
  mutate(Value.POS = case_when(
    POS == "C" ~ 240,
    POS == "SS" ~ 168,
    POS == "2B" ~ 132,
    POS == "3B" ~ 84,
    POS == "OF" ~ 48,
    POS == "1B" ~ 12,
    TRUE ~ 0)) -> C.totals

similar <- function(p, number = 10) {
  C.totals %>% filter(playerID == p) -> P
  C.totals %>%
    mutate(sim_score = 1000 -
             floor(abs(G - P$G) / 20) -
             floor(abs(AB - P$AB) / 75) -
             floor(abs(R - P$R) / 10) -
             floor(abs(H - P$H) / 15) -
             floor(abs(X2B - P$X2B) / 5) -
             floor(abs(X3B - P$X3B) / 4) -
             floor(abs(HR - P$HR) / 2) -
             floor(abs(RBI - P$RBI) / 10) -
             floor(abs(BB - P$BB) / 25) -
             floor(abs(SO - P$SO) / 150) -
             floor(abs(SB - P$SB) / 20) -
             floor(abs(AVG - P$AVG) / 0.001) -
             floor(abs(SLG - P$SLG) / 0.002) -
             abs(Value.POS - P$Value.POS)) %>%
    arrange(desc(sim_score)) %>%
    head(number)
}

similar(mantle_id, 6)

batting_2000 %>%
  group_by(playerID, yearID) %>%
  summarize(G = sum(G), AB = sum(AB), R = sum(R), H = sum(H), X2B = sum(X2B), X3B = sum(X3B), 
            HR = sum(HR), RBI = sum(RBI), SB = sum(SB), CS = sum(CS), BB = sum(BB), SH = sum(SH),
            SF = sum(SF), HBP = sum(HBP), Career.AB = first(Career.AB), POS = first(POS)) %>%
  mutate(SLG = (H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/AB,
         OBP = (H + BB + HBP)/(AB + BB + HBP + SF),
         OPS = SLG + OBP) -> batting_2000

batting_2000 %>% inner_join(Master, by = "playerID") %>%
  mutate(Birthyear = ifelse(birthMonth >= 7, birthYear + 1, birthYear),
         Age = yearID - Birthyear) -> batting_2000

batting_2000 %>% drop_na(Age) -> batting_2000

plot_trajectories <- function(player, n.similar = 5, ncol) {
  flnames <- unlist(strsplit(player, " "))
  
  Master %>%
    filter(nameFirst == flnames[1],
           nameLast == flnames[2]) %>%
    select(playerID) -> player
  
  player.list <- player %>%
    pull(playerID) %>%
    similar(n.similar) %>%
    pull(playerID)
  
  batting_2000 %>%
    filter(playerID %in% player.list) %>%
    mutate(Name = paste(nameFirst, nameLast)) -> Batting.new
  
  ggplot(Batting.new) + aes(Age, OPS) + 
    geom_smooth(method="lm", formula = y ~ x + I(x^2), size = 1.5) +
    facet_wrap(~ Name, ncol=ncol) + theme_bw()
}

plot_trajectories("Mickey Mantle", 6, 2)

dj_plot <- plot_trajectories("Derek Jeter", 9, 3)
dj_plot

regressions <- dj_plot$data %>%
  split(pull(., Name)) %>%
  map(~lm(OPS ~ I(Age-30) + I((Age - 30) ^ 2), data = .)) %>%
  map_df(tidy, .id = "Name") %>%
  as_tibble()
head(regressions)

regressions %>%
  group_by(Name) %>%
  summarize(b1 = estimate[1],
            b2 = estimate[2],
            Curve = estimate[3],
            Age.max = round(30 - b2 / Curve / 2, 1),
            Max = round(b1 - b2 ^2 / Curve / 4, 3)) -> S
S

ggplot(S) + aes(Age.max, Curve, label = Name) + geom_point() + geom_label_repel()

midcareers <- batting_2000 %>%
  group_by(playerID) %>%
  summarize(Midyear = (min(yearID) + max(yearID)) / 2,
            AB.total = first(Career.AB))

batting_2000 %>%
  inner_join(midcareers, by = "playerID") -> batting_2000

models <- batting_2000 %>%
  split(pull(., playerID)) %>%
  map(~lm(OPS ~ I(Age - 30) + I((Age - 30)^2), data = .)) %>%
  map_df(tidy, .id = "playerID")

models %>%
  group_by(playerID) %>%
  summarize(A = estimate[1],
            B = estimate[2],
            C = estimate[3]) %>%
  mutate(Peak.age = 30 - B / 2 / C) %>%
  inner_join(midcareers, by = "playerID") -> beta_coefs

age_plot <- ggplot(beta_coefs) + aes(Midyear, Peak.age) + geom_point(alpha = 0.5) + 
  geom_smooth(color = "red", method = "loess") + ylim(20, 40) + xlab("Mid Career") + ylab("Peak Age")

age_plot + aes(x = log2(AB.total)) + xlab("Log2 of Career AB")

batting_2000a <- batting_2000 %>%
  filter(Midyear >= 1985, Midyear <= 1995)

models <- batting_2000a %>%
  split(pull(., playerID)) %>%
  map(~lm(OPS ~ I(Age-30) + I((Age - 30)^2), data = .)) %>%
  map_df(tidy, .id = "playerID")

models %>%
  group_by(playerID) %>%
  summarize(A = estimate[1],
            B = estimate[2],
            C = estimate[3]) %>%
  mutate(Peak.Age = 30 - B / 2 / C) %>%
  inner_join(midcareers) %>%
  inner_join(Positions) %>%
  rename(Position = POS) -> beta_estimates

beta_estimates %>%
  filter(Position %in% c("1B", "2B", "3B", "SS", "C", "OF")) %>%
  inner_join(Master) -> beta_fielders

ggplot(beta_fielders) + aes(Position, Peak.Age) + geom_jitter(width = 0.2) + ylim(20, 40) + 
  geom_label_repel(data = filter(beta_fielders, Peak.Age > 37)) + aes(Position, Peak.Age, label = nameLast)

# Exercise 1a

get_stats('mayswi01')

# 1b

ggplot(data = get_stats('mayswi01')) + aes(Age, OPS) + geom_point() + geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 2, raw = TRUE))

# 1c

estimates <- coef(lm(OPS ~ I(Age) + I((Age-30)^2), data = get_stats('mayswi01')))
estimates[1] - estimates[2]^2 / 4 / estimates[3]

# Exercise 2a

similar('mayswi01') %>% inner_join(Master, by = "playerID") %>% select(playerID, nameFirst, nameLast, sim_score) %>% head(6) -> top5_similar_mays

# 2b

plot_trajectories('Willie Mays', 6, ncol = 3)

# 2c: Smallest peak age looks like pujols :(

# Exercise 3a

batting %>%
  group_by(playerID) %>%
  summarize(Career.H = sum(H)) %>%
  filter(Career.H > 3200) %>%
  inner_join(batting, by = "playerID") %>%
  inner_join(Master, by = "playerID") %>%
  mutate(Birthyear = ifelse(birthMonth >= 7, birthYear + 1, birthYear),
          Age = yearID - Birthyear,
          AVG = H/AB) -> batting_3200

# 3b

models3200 <- batting_3200 %>%
  split(pull(., playerID)) %>%
  map(~lm(AVG ~ I(Age-30) + I((Age - 30)^2), data = .)) %>%
  map_df(tidy, .id = "playerID")

models3200 %>%
  group_by(playerID) %>%
  summarize(A = estimate[1],
            B = estimate[2],
            C = estimate[3]) %>%
  mutate(Peak.Age = 30 - B / 2 / C,
         Max = round(A - B^2 / C / 4, 3)) %>% arrange(C) -> beta3200_estimates


ggplot(data = batting_3200, aes(Age, AVG, group=playerID, col=playerID)) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 2, raw = TRUE))

# To reduce clutter, here's the top 3:

batting_3200 %>% pull(playerID) %>% unique() %>% head(3) -> top3
batting_3200 %>% filter(playerID %in% top3) %>% mutate(Names = paste(nameFirst, nameLast)) -> batting_3200_top3

ggplot(data = batting_3200_top3, aes(Age, AVG, group=Names, col=Names)) + geom_point() + 
  geom_smooth(method = "lm", se = FALSE, size = 1.5, formula = y ~ poly(x, 2, raw = TRUE)) + ggtitle("Aging Curves, using Batting Average (AVG)")

# 3c

# I define the "most consistent" as having the smallest C value, so the smallest curvature in their parabola.
# The winner is Tris Speaker, who is found at:

beta3200_estimates %>% head(1) %>% select(playerID) %>% inner_join(Master, by = "playerID") %>% select(nameFirst, nameLast)