CREATE VIEW fgTotal AS
SELECT
	 fanS.Season,
     fanS.playerid,
     fanS.Name,
     STR_TO_DATE(id.BIRTHDATE, '%m/%d/%Y') as Birthdate,
     fanS.Season - IF(month(STR_TO_DATE(id.BIRTHDATE, '%m/%d/%Y')) >= 7, year(STR_TO_DATE(id.BIRTHDATE, '%m/%d/%Y')) + 1, year(STR_TO_DATE(id.BIRTHDATE, '%m/%d/%Y'))) as age,
     fanS.Team,
     fanS.Pos,
     fanS.G,
     fanS.GS,
     fanS.Inn,
     fanS.PO,
     fanS.A,
     fanS.E,
     fanS.FE,
     fanS.TE,
     fanS.DP,
	 fanS.DPS,
     fanS.DPT,
     fanS.DPF,
     fanS.Scp,
     fanS.SB,
     fanS.CS,
     fanS.PB,
     fanS.WP,
     fanS.FP,
     fanS.TZ,
     fanA.rSZ,
     fanA.rCERA,
     fanA.rSB,
     fanA.rGDP,
     fanA.rARM,
     fanA.rGFP,
     fanA.rPM,
     fanA.rTS,
     fanA.DRS,
     fanA.BIZ,
     fanA.Plays,
     fanA.RZR,
     fanA.OOZ,
     fanA.FSR,
     fanA.FRM,
     fanA.ARM,
     fanA.DPR,
     fanA.RNGR,
     fanA.ErrR,
     fanA.UZR,
     fanA.`UZR/150`,
     fanA.Def
FROM 
	fgStandard fanS
INNER JOIN
	fgAdvanced fanA 
    ON fanA.playerid = fanS.playerid 
    AND fanA.season = fanS.season
    AND fanA.team = fanS.team
    AND fanA.Pos = fanS.Pos
LEFT JOIN
	idMapper id ON
    fanS.playerid = id.IDFANGRAPHS;