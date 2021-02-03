-- To be added in once I have a much stronger foundation in STATS1152 Material:
-- Chapter 11: Streakiness in Sports

-- This file was made to provide an explanation to students how some
-- analysis in the book "Mathletics" can be done in MySQL.

USE lahman;

-- Chapter 1: Baseball's Pythagorean Theorem
-- There is a minor difference in answers from book due to sigfigs being used.

CREATE TEMPORARY TABLE temp
SELECT yearID, teamID, W, L, R, RA,
R/RA AS scoring_ratio,
W/(W+L) AS winLoss,
POWER(R/RA, 2)/(POWER(R/RA, 2) + 1) AS predicted_winLoss,
ABS(W/(W+L) - POWER(R/RA, 2)/(POWER(R/RA, 2) + 1)) AS absolute_error
FROM teams
WHERE yearID BETWEEN 1980 AND 2006
ORDER BY yearID DESC;

SELECT * FROM temp;
SELECT AVG(absolute_error) FROM temp;

DROP TEMPORARY TABLE temp;

SELECT *,
POWER(scoring_ratio, 2)/(POWER(scoring_ratio, 2) + 1) AS alternate_pythag_theorem
FROM temp;

-- The best choice for the exponent in the alternate pythagorean theorem
-- is done in the complimentary R file to save some coding pains.

-- Chapter 2: Runs-Created Approach

-- Pulling up team data

CREATE TEMPORARY TABLE temp
SELECT yearID, R, AB, H,
H - X2B - X3B - HR AS singles,
X2B, X3B, HR,
BB + HBP AS Walks,
(H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP) AS runs_created,
ABS(R - (H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP)) AS absolute_error,
POWER(R - (H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP), 2) AS squared_error,
teamID
FROM teams
WHERE yearID IN (2000, 2006);

SELECT * FROM temp;

SELECT AVG(absolute_error) FROM temp;

DROP TEMPORARY TABLE temp;

-- Generating runs created for Ichiro and Barry Bonds
-- Ichiro's ID: 'suzukic01'
-- Bonds' ID: 'bondsba01'

SELECT * FROM batting
WHERE playerid IN ('bondsba01', 'suzukic01')
AND yearid = 2004;

SELECT * FROM batting
WHERE yearid = 1997
AND playerID LIKE 'n%';

SELECT * FROM people
WHERE birthyear = 1973
AND birthmonth = 7
AND birthday = 23;

SHOW TABLES;

SELECT *, 
(H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP) AS runs_created,
((H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP))*26.72/(.982*AB - H + GIDP + SF + SH + CS) AS runs_created_per_game 
FROM batting
WHERE playerid IN ('bondsba01', 'suzukic01')
AND yearid = 2004;

-- Chapter 3: Linear Weights

-- The Linear Regression is not done here. I'll just be using the weights provided and save that for the R file.
-- On page 23, Winston has made a mistake in his formula. We also need to subtract by H for computed_outs, which
-- is added back into the SQL code below.

SELECT *, 
(H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP) AS james_runs_created,
((H + BB + HBP)*(H - X2B - X3B - HR + 2*X2B + 3*X3B + 4*HR)/(AB + BB + HBP))*26.72/(.982*AB - H + GIDP + SF + SH + CS) AS james_runs_created_per_game,
.982*AB - H + SH + SF + CS + GIDP AS computed_outs,
4329/(.982*AB - H + SH + SF + CS + GIDP) AS scale_factor,
-560 + (4329/(.982*AB - H + SH + SF + CS + GIDP))*(.63*(H - X2B - X3B - HR) + 0.71*X2B + 1.26*X3B + 1.49*HR + 0.35*(BB + HBP)) AS linear_weights_runs,
(-560 + (4329/(.982*AB - H + SH + SF + CS + GIDP))*(.63*(H - X2B - X3B - HR) + 0.71*X2B + 1.26*X3B + 1.49*HR + 0.35*(BB + HBP)))/162 AS linear_weights_runs_per_game
FROM batting
WHERE playerid IN ('bondsba01', 'suzukic01')
AND yearid = 2004;

-- Chapter 4: Monte Carlo Simulations

-- The Monte Carlo simulator is reserved for the R file; it'd be a nightmare to code up in SQL.
-- We'll just show how the data might be gathered in this file.

-- For some reason sacrifice hits are counted in the total plate appearances on the teams table,
-- so we'll have to gather that from the batting table. We can then just exclude Pujols with
-- a "not in" statement.

SELECT SUM(AB + BB + SH + SF + HBP) AS PA,
ROUND(SUM(0.018*AB), 0) AS Errors,
ROUND(SUM(AB + SF + SH - H - 0.018*AB - SO), 0) AS OutsInPlay,
SUM(SO), SUM(BB), SUM(HBP),
SUM(H - X2B - X3B - HR) AS Singles,
SUM(X2B), SUM(X3B), SUM(HR)
FROM batting
WHERE teamID = 'SLN' AND yearid = 2006 AND playerID NOT IN ('pujolal01');

-- For pujols as an individual:

SELECT AB + BB + SH + SF + HBP AS PA,
ROUND(0.018*AB, 0) AS Errors,
AB + SF + SH - H - ROUND(0.018*AB, 0) - SO AS OutsInPlay,
SO, BB, HBP,
H - X2B - X3B - HR AS Singles,
X2B, X3B, HR
FROM batting
WHERE playerid = 'pujolal01' AND yearid = 2006;

-- Chapter 5: Evaluating Baseball Pitchers and Forecasting Future Performance

-- The linear regression is again done in R instead of SQL.
-- Let's predict how how future ERA holds up using linear weights. 
-- Warning: edge cases made the below code nasty.

-- It's not stated in the book how the author edge cases such as...
-- 1. How did he handle players that played in 2002 and 2004, but not 2003? Did he just ignore them for prediction purposes?
-- 2. What what the threshold for innings pitched before we factored them into the analysis? Or if it was games instead of innings?
-- So naturally my numbers disagree with his.

DROP TEMPORARY TABLE temp;
DROP TEMPORARY TABLE temp2;
DROP TEMPORARY TABLE temp3;

CREATE TEMPORARY TABLE temp
SELECT playerID, yearID, SUM(ER) AS ER, SUM(IPOuts) AS IPOuts, (SUM(ER)/(SUM(IPOuts)/3))*9 AS ERA,
2.8484 + .353*(SUM(ER)/(SUM(IPOuts)/3))*9 AS predicted_ERA
FROM pitching
GROUP BY playerID, yearID
HAVING yearID BETWEEN 2000 AND 2006;

CREATE TEMPORARY TABLE temp2
SELECT * FROM temp;

CREATE TEMPORARY TABLE temp3
SELECT t.*, t2.predicted_ERA AS prior_predicted_ERA
FROM temp t
LEFT JOIN temp2 t2 ON t.yearID = t2.yearID + 1 AND t.playerID = t2.playerID;

SELECT *, ABS(ERA - prior_predicted_ERA) AS absolute_error
FROM temp3
ORDER BY ABS(ERA - prior_predicted_ERA) DESC;

SELECT AVG(ABS(ERA - prior_predicted_ERA)) 
FROM temp3
WHERE prior_predicted_ERA IS NOT NULL;

-- Calculating DICE

SELECT playerID, yearID, 
3 + (13*HR + 3*(BB + HBP) - 2*SO)/(IPOuts/3) AS DICE 
FROM pitching
ORDER BY DICE DESC;

-- Chapter 6: Baseball Decision-Making (To be completed)

-- Run-value computations for 2000-2006:
-- A couple of notes before we begin...


-- 1. This is also calculated in Chapter 5 of Analyzing Baseball Data w/ R and most of the following
-- SQL code is an adaptation of the R script from that chapter. Also, it's just now occurred to me 
-- that Lahman's batter and pitcher data is built as summarized statistical data on top of RETROSHEET,
-- which is why that book uses a truncated section of RETROSHEET's 2016 play-by-play data to construct 
-- the dataset.

-- 2. I use the notation of states from ABDwR instead of mathletics because I find it easier to read.

-- 3. Note that this takes more computational time than doing Chapter 5 of ABDwR. That's because of how large the
-- table is (all recorded baseball data) with respect to ABDwR's dataset (just 2016).

-- 4. The data pretty much agrees but isn't exact. I don't own a copy of "Baseball Hacks" so I can't
-- explore further why that is.

-- In the future, this will be placed into its own stored procedure for conciseness of this section.

USE retrosheet;

CREATE TEMPORARY TABLE rawData
SELECT *, 
SUBSTRING(game_ID, 4, 4) AS year,
SUBSTRING(game_ID, 8, 2) AS month,
SUBSTRING(game_ID, 10, 2) AS day,
away_score_ct + home_score_ct AS runs,
CONCAT(game_id, inn_ct, bat_home_id) AS half_inning,
(IF(BAT_DEST_ID > 3, 1, 0) + IF(RUN1_DEST_ID > 3, 1, 0) + IF(RUN2_DEST_ID > 3, 1, 0) + IF(RUN3_DEST_ID > 3, 1, 0)) AS runs_scored
FROM playByPlay
WHERE SUBSTRING(game_ID, 4, 4) BETWEEN 2004 AND 2004
ORDER BY year, month, day, INN_CT, BAT_HOME_ID, BAT_LINEUP_ID;

CREATE TEMPORARY TABLE summaries
SELECT half_inning,
SUM(event_outs_ct) AS outs_inning,
SUM(runs_scored) AS runs_inning,
MIN(runs) AS runs_start,
SUM(runs_scored) + MIN(runs) AS max_runs
FROM rawData
GROUP BY half_inning;

CREATE TEMPORARY TABLE stateTracker
SELECT rd.*, outs_inning, runs_inning, runs_start, max_runs, 
max_runs - runs AS runs_roi,
CONCAT(IF(BASE1_RUN_ID IS NOT NULL, 1, 0), IF(BASE2_RUN_ID IS NOT NULL, 1, 0), IF(BASE3_RUN_ID IS NOT NULL, 1, 0), ' ', OUTS_CT) AS start_state,
CONCAT(IF(RUN1_DEST_ID = 1 OR BAT_DEST_ID = 1, 1, 0), IF(RUN1_DEST_ID = 2 OR BAT_DEST_ID = 2 OR RUN2_DEST_ID = 2, 1, 0), IF(RUN1_DEST_ID = 3 OR BAT_DEST_ID = 3 OR RUN2_DEST_ID = 3 OR RUN3_DEST_ID = 3, 1, 0), ' ', OUTS_CT + EVENT_OUTS_CT) AS end_state
FROM rawData rd
INNER JOIN summaries s ON rd.half_inning = s.half_inning;
-- where start_state != end_state or runs_scored > 0 and outs_inning = 3;

CREATE TEMPORARY TABLE stateTrackerTruncated
SELECT * FROM stateTracker
WHERE start_state != end_state OR runs_scored > 0 AND outs_inning = 3;

CREATE TEMPORARY TABLE re24_list
SELECT start_state, 
ROUND(AVG(runs_roi), 2) AS avg_runs_roi,
COUNT(*) AS No_Plate_Appearances
FROM stateTrackerTruncated
GROUP BY start_state;

SELECT * FROM re24_list
ORDER BY start_state;

-- Evaluate the success of a bunt

DROP TEMPORARY TABLE stateTrackerBunt;

CREATE TEMPORARY TABLE stateTrackerBunt
SELECT *
FROM stateTrackerTruncated
WHERE event_tx LIKE '%BG%' OR event_tx LIKE '%BP%';

CREATE TEMPORARY TABLE stateTrackerBunt2
SELECT *
FROM stateTrackerBunt
WHERE start_state = '100 0';

SELECT COUNT(*) FROM stateTrackerBunt2; -- 1010, need this for below

CREATE TEMPORARY TABLE state_transition_prob
SELECT end_state, ROUND(COUNT(*)/1010, 2) AS Prob
FROM stateTrackerBunt2
GROUP BY end_state;

SELECT SUM(prob*avg_runs_roi) AS expected_value 
FROM state_transition_prob st
INNER JOIN re24_list re ON st.end_state = re.start_state

-- Probabilities and Expected Value generally agree; a few weird scenarios pop up that are errors on retrosheet's data collection.
-- Analyzing a stolen base attempt is done using the exact same methodology as for bunts, so I will go no further.

