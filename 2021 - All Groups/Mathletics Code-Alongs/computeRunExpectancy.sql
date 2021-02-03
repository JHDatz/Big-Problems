DELIMITER //
CREATE PROCEDURE merged.computeRunExpectancy(start_year int, end_year int)
BEGIN

	CREATE TEMPORARY TABLE rawData
	SELECT *, 
	SUBSTRING(game_ID, 4, 4) AS year,
	SUBSTRING(game_ID, 8, 2) AS month,
	SUBSTRING(game_ID, 10, 2) AS day,
	away_score_ct + home_score_ct AS runs,
	CONCAT(game_id, inn_ct, bat_home_id) AS half_inning,
	(IF(BAT_DEST_ID > 3, 1, 0) + IF(RUN1_DEST_ID > 3, 1, 0) + IF(RUN2_DEST_ID > 3, 1, 0) + IF(RUN3_DEST_ID > 3, 1, 0)) AS runs_scored
	FROM retrosheet.playByPlay
	WHERE SUBSTRING(game_ID, 4, 4) BETWEEN start_year AND end_year
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

	CREATE TEMPORARY TABLE stateTrackerTruncated
	SELECT * FROM stateTracker
	WHERE start_state != end_state OR runs_scored > 0 AND outs_inning = 3;

	CREATE TEMPORARY TABLE re24_list
	SELECT start_state, 
	ROUND(AVG(runs_roi), 2) AS avg_runs_roi,
	COUNT(*) AS No_Plate_Appearances
	FROM stateTrackerTruncated
	GROUP BY start_state;
    
    -- drop temporary table rawData;
    -- drop temporary table summaries;
    -- drop temporary table stateTracker;

	SELECT * FROM re24_list
	ORDER BY start_state;
END//