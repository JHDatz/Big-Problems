DELIMITER \\

DROP PROCEDURE IF EXISTS merged.computeStates2;

CREATE PROCEDURE merged.computeStates2(start_year int, end_year int)
BEGIN

	DROP TEMPORARY TABLE IF EXISTS rawData;
	DROP TEMPORARY TABLE IF EXISTS summaries;
	DROP TEMPORARY TABLE IF EXISTS stateTracker;

	CREATE TEMPORARY TABLE rawData
	SELECT *
	FROM merged.vGenerateStates
	WHERE YEAR BETWEEN start_year AND end_year;
    
    CREATE TEMPORARY TABLE summaries
	SELECT half_inning,
	SUM(event_outs_ct) AS outs_inning,
	SUM(runs_scored) AS runs_inning,
	MIN(runs) AS runs_start,
	SUM(runs_scored) + MIN(runs) AS max_runs
	FROM merged.rawData
	GROUP BY half_inning;
    
    CREATE TEMPORARY TABLE stateTracker
	SELECT rd.*, outs_inning, runs_inning, runs_start, max_runs, 
	max_runs - runs AS runs_roi
	FROM merged.rawData rd
	INNER JOIN summaries s ON rd.half_inning = s.half_inning;
    
    DROP TEMPORARY TABLE rawData;
    DROP TEMPORARY TABLE summaries;

END\\