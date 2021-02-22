DELIMITER //

CREATE PROCEDURE computeRunExpectancy(start_year int, end_year int)
BEGIN

	CALL computeStates2(start_year, end_year);

	CREATE TEMPORARY TABLE re24_list
	SELECT start_state, 
	ROUND(AVG(runs_roi), 2) AS avg_runs_roi,
	COUNT(*) AS No_Plate_Appearances
	FROM stateTracker
    WHERE start_state != end_state OR runs_scored > 0 AND outs_inning = 3
	GROUP BY start_state;
    
    DROP TEMPORARY TABLE stateTracker;

	SELECT * FROM re24_list
	ORDER BY start_state;
END//