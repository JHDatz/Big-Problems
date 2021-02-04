DELIMITER \\
CREATE PROCEDURE computeRunExpectancy(start_year int, end_year int)
BEGIN

	call computeStates(start_year, end_year);

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
END\\