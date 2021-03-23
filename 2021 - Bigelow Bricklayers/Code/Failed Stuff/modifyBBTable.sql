# modify batted balls table
#
# Written By: Joe Datz
# Date: 3/23/21
#
# This was leftover MySQL code from attempting to merge together RETROSHEET
# play-by-play data and data given to us from our baseball team a week ago. 
# This would allow some team members to research a bit about individual
# player skill level and see if it would provide insights on creating
# constraints for our optimization problem.
#
# Unfortunately I kept running into memory crashes in MySQL when trying to
# do this, so I moved over to R. This is kept just for documenting what we
# tried.

USE figmentLeague;

SELECT 
	count(*) 
FROM 
	test; # 774264, used to make sure my joins will not create a mess.

DROP temporary TABLE IF EXISTS temp;

CREATE TEMPORARY TABLE temp
SELECT
	t.*,
	pxrb.mergedID as batterPittID,
	pxrp.mergedID as pitcherPittID
FROM 
	test t
LEFT JOIN 
	merged.PlayerCrossRef pxrb ON t.batterID = pxrb.identifier
LEFT JOIN
	merged.PlayerCrossRef pxrp ON t.batterID = pxrp.identifier;
    
DROP temporary TABLE IF EXISTS temp2;

CREATE TEMPORARY TABLE temp2
SELECT
	t.*,
    pxrb.identifier as batterLahmanID,
    pxrp.identifier as pitcherLahmanID
FROM temp t
INNER JOIN
	merged.PlayerCrossRef pxrb ON t.batterPittID = pxrb.mergedID AND pxrb.source = 'lahman'
INNER JOIN
	merged.PlayerCrossRef pxrp ON t.pitcherPittID = pxrp.mergedID AND pxrp.source = 'lahman';

SELECT
	t.*,
	pxrb.identifier as batterLahmanID,
	pxrp.identifier as pitcherLahmanID
FROM 
	temp t
INNER JOIN
	merged.PlayerCrossRef pxrb ON t.batterPittID = pxrb.mergedID 
    	AND pxrb.source = 'lahman'
INNER JOIN
	merged.PlayerCrossRef pxrp ON t.pitcherPittID = pxrp.mergedID 
    	AND pxrp.source = 'lahman';
    

CREATE TEMPORARY TABLE temp
SELECT 
	t.*,
	pxr1b.mergedID as batterPittID, 
	pxr2b.identifier as batterLahmanID, 
	concat(lb.nameFirst, ' ', lb.nameLast) as batterName,
	pxr1p.mergedID as pitcherPittID, 
	pxr2p.identifier as pitcherLahmanID, 
	concat(lp.nameFirst, ' ', lp.nameLast) as pitcherName
FROM 
	test t
LEFT JOIN 
	merged.PlayerCrossRef pxr1b ON t.batterID = pxr1b.identifier
INNER JOIN
	merged.PlayerCrossRef pxr2b ON pxr1b.mergedID = pxr2b.mergedID AND pxr2b.source = 'lahman'
LEFT JOIN 
	lahman.master lb ON pxr2b.identifier = lb.playerID
LEFT JOIN 
	merged.PlayerCrossRef pxr1p ON t.pitcherid = pxr1p.identifier
INNER JOIN 
	merged.PlayerCrossRef pxr2p ON pxr1p.mergedID = pxr2p.mergedID AND pxr2p.source = 'lahman'
LEFT JOIN 
	lahman.master lp ON pxr2p.identifier = lp.playerID;
	

# Create a table with both Retrosheet names and MLBAM teamids to join on.
	

/*
update teamIDs set RetroName = 'CHA' where teamID = 145;
update teamIDs set RetroName = 'SEA' where teamID = 136;
update teamIDs set RetroName = 'BOS' where teamID = 111;
update teamIDs set RetroName = 'TEX' where teamID = 140;
update teamIDs set RetroName = 'MIN' where teamID = 142;
update teamIDs set RetroName = 'ANA' where teamID = 108;
update teamIDs set RetroName = 'ARI' where teamID = 109;
update teamIDs set RetroName = 'WAS' where teamID = 120;
update teamIDs set RetroName = 'PHI' where teamID = 143;
update teamIDs set RetroName = 'MIA' where teamID = 146;
update teamIDs set RetroName = 'KCA' where teamID = 118;
update teamIDs set RetroName = 'SFN' where teamID = 137;
update teamIDs set RetroName = 'CIN' where teamID = 113;
update teamIDs set RetroName = 'NYN' where teamID = 121;
update teamIDs set RetroName = 'ATL' where teamID = 144;
update teamIDs set RetroName = 'DET' where teamID = 116;
update teamIDs set RetroName = 'SLN' where teamID = 138;
update teamIDs set RetroName = 'LAN' where teamID = 119;
update teamIDs set RetroName = 'OAK' where teamID = 133;
update teamIDs set RetroName = 'BAL' where teamID = 110;
update teamIDs set RetroName = 'TBA' where teamID = 139;
update teamIDs set RetroName = 'MIL' where teamID = 158;
update teamIDs set RetroName = 'CLE' where teamID = 114;
update teamIDs set RetroName = 'CHN' where teamID = 112;
update teamIDs set RetroName = 'COL' where teamID = 115;
update teamIDs set RetroName = 'HOU' where teamID = 117;
update teamIDs set RetroName = 'PIT' where teamID = 134;
update teamIDs set RetroName = 'TOR' where teamID = 141;
update teamIDs set RetroName = 'SDN' where teamID = 135;
update teamIDs set RetroName = 'NYA' where teamID = 147;
*/

CREATE TEMPORARY TABLE temp2
SELECT 
	t.*,
    pkt.`teams.home.team.id` as homeTeamID,
    pkt.`teams.away.team.id` as awayTeamID,
    pkt.`venue.name` as park,
    pkt.doubleHeader,
    tdh.mlbamName as homeTeam,
    tdh.RetroName as homeRetroID,
    tda.mlbamName as awayTeam,
    tda.RetroName as awayRetroID,
    STR_TO_DATE(substring_index(date, " ", 1), '%m/%d/%Y') as calendarDate
FROM 
	temp t
INNER JOIN 
	mlbPKteams pkt ON t.game_pk = pkt.game_pk
INNER JOIN
	teamIDs tdh ON pkt.`teams.home.team.id` = tdh.teamID
INNER JOIN
	teamIDs tda ON pkt.`teams.away.team.id` = tda.teamID;
