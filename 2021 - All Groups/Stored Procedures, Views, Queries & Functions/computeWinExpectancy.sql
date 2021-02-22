DELIMITER //

DROP PROCEDURE IF EXISTS merged.computeWinExpectancy;

CREATE PROCEDURE merged.computeWinExpectancy(start_year int, end_year int, score_diff int, state varchar(5), inning int)
BEGIN

	DROP TEMPORARY TABLE IF EXISTS found_gameIDs;
	DROP TEMPORARY TABLE IF EXISTS gameWins;
	
    create temporary table found_gameIDs
	select distinct game_id as game_id2
	from merged.vGenerateStates
	where year between start_year and end_year
	and home_score_ct - away_score_ct = score_diff
	and start_state = state
	and inn_ct = inning
	and bat_home_id = 1;
    
    create temporary table gameWins
	select game_ID, IF(max(home_score_ct) >= max(away_score_ct), 1, 0) as win
	from merged.vGenerateStates gs
	inner join found_gameIDs fg on fg.game_id2 = gs.game_id
	group by game_ID;

	select sum(win)/count(*) from gameWins;
    
END//