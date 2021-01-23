-- To be added in once I have a much stronger foundation in STATS1152 Material:
-- Chapter 11: Streakiness in Sports

-- This file was made to provide an explanation to students how some
-- analysis in the book "Mathletics" can be done in MySQL.

use lahman;

-- Chapter 1: Baseball's Pythagorean Theorem
-- There is a minor difference in answers from book due to sigfigs being used.

create temporary table temp
select yearID, teamID, W, L, R, RA,
R/RA as scoring_ratio,
W/(W+L) as winLoss,
power(R/RA, 2)/(power(R/RA, 2) + 1) as predicted_winLoss,
abs(W/(W+L) - power(R/RA, 2)/(power(R/RA, 2) + 1)) as absolute_error
from teams
where yearID between 1980 and 2006
order by yearID desc;

select * from temp;
select avg(absolute_error) from temp;

drop temporary table temp;

select *,
power(scoring_ratio, 2)/(power(scoring_ratio, 2) + 1) as alternate_pythag_theorem
from temp;

-- The best choice for the exponent in the alternate pythagorean theorem
-- is done in the complimentary R file to save some coding pains.

-- Chapter 2: Runs-Created Approach

-- Pulling up team data

create temporary table temp
select yearID, R, AB, H,
H - X2B - X3B - HR as singles,
X2B, X3B, HR,
BB + HBP as Walks,
(H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP) as runs_created,
abs(R - (H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP)) as absolute_error,
power(R - (H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP), 2) as squared_error,
teamID
from teams
where yearID in (2000, 2006);

select * from temp;

select avg(absolute_error) from temp;

drop temporary table temp;

-- Generating runs created for Ichiro and Barry Bonds
-- Ichiro's ID: 'suzukic01'
-- Bonds' ID: 'bondsba01'

select * from batting
where playerid in ('bondsba01', 'suzukic01')
and yearid = 2004;

select * from batting
where yearid = 1997
and playerID like 'n%';

select * from people
where birthyear = 1973
and birthmonth = 7
and birthday = 23;

show tables;

select *, 
(H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP) as runs_created,
((H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP))*26.72/(.982*AB - H + GIDP + SF + SH + CS) as runs_created_per_game 
from batting
where playerid in ('bondsba01', 'suzukic01')
and yearid = 2004;

-- Chapter 3: Linear Weights

-- The Linear Regression is not done here. I'll just be using the weights provided and save that for the R file.
-- On page 23, Winston has made a mistake in his formula. We also need to subtract by H for computed_outs, which
-- is added back into the SQL code below.

select *, 
(H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP) as james_runs_created,
((H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP))*26.72/(.982*AB - H + GIDP + SF + SH + CS) as james_runs_created_per_game,
.982*AB - H + SH + SF + CS + GIDP as computed_outs,
4329/(.982*AB - H + SH + SF + CS + GIDP) as scale_factor,
-560 + (4329/(.982*AB - H + SH + SF + CS + GIDP))*(.63*(H - X2B - X3B - HR) + 0.71*X2B + 1.26*X3B + 1.49*HR + 0.35*(BB + HBP)) as linear_weights_runs,
(-560 + (4329/(.982*AB - H + SH + SF + CS + GIDP))*(.63*(H - X2B - X3B - HR) + 0.71*X2B + 1.26*X3B + 1.49*HR + 0.35*(BB + HBP)))/162 as linear_weights_runs_per_game
from batting
where playerid in ('bondsba01', 'suzukic01')
and yearid = 2004;

-- Chapter 4: Monte Carlo Simulations

-- The Monte Carlo simulator is reserved for the R file; it'd be a nightmare to code up in SQL.
-- We'll just show how the data might be gathered in this file.

-- For some reason sacrifice hits are counted in the total plate appearances on the teams table,
-- so we'll have to gather that from the batting table. We can then just exclude Pujols with
-- a "not in" statement.

select sum(AB + BB + SH + SF + HBP) as PA,
round(sum(0.018*AB), 0) as Errors,
round(sum(AB + SF + SH - H - 0.018*AB - SO), 0) as OutsInPlay,
sum(SO), sum(BB), sum(HBP),
sum(H - X2B - X3B - HR) as Singles,
sum(X2B), sum(X3B), sum(HR)
from batting
where teamID = 'SLN' and yearid = 2006 and playerID not in ('pujolal01');

-- For pujols as an individual:

select AB + BB + SH + SF + HBP as PA,
round(0.018*AB, 0) as Errors,
AB + SF + SH - H - round(0.018*AB, 0) - SO as OutsInPlay,
SO, BB, HBP,
H - X2B - X3B - HR as Singles,
X2B, X3B, HR
from batting
where playerid = 'pujolal01' and yearid = 2006;