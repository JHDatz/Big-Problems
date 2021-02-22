CREATE VIEW merged.vGenerateStates AS
    SELECT 
        *,
        SUBSTR(GAME_ID, 4, 4) AS `year`,
        AWAY_SCORE_CT + HOME_SCORE_CT AS runs,
        CONCAT(GAME_ID, INN_CT, BAT_HOME_ID) AS half_inning,
        IF(BAT_DEST_ID > 3, 1, 0) + IF(RUN1_DEST_ID > 3, 1, 0) + IF(RUN2_DEST_ID > 3, 1, 0) + IF(RUN3_DEST_ID > 3, 1, 0) AS runs_scored,
        CONCAT(IF((BASE1_RUN_ID IS NOT NULL), 1, 0), IF((BASE2_RUN_ID IS NOT NULL), 1, 0), IF((BASE3_RUN_ID IS NOT NULL), 1, 0), ' ', OUTS_CT) AS start_state,
        CONCAT(IF(((RUN1_DEST_ID = 1) OR (BAT_DEST_ID = 1)), 1, 0),
                IF(((RUN1_DEST_ID = 2) OR (BAT_DEST_ID = 2) OR (RUN2_DEST_ID = 2)), 1, 0), 
                IF(((RUN1_DEST_ID = 3) OR (BAT_DEST_ID = 3) OR (RUN2_DEST_ID = 3) OR (RUN3_DEST_ID = 3)), 1, 0), ' ', (OUTS_CT + EVENT_OUTS_CT)) AS end_state
    FROM
        retrosheet.playByPlay