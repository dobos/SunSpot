INSERT Dataset
VALUES
	(1, 'DPD')

--==========================================================
-- Create observatories

-- TRUNCATE TABLE [Observatory]

GO

INSERT [Observatory]
	([Name], [ObservatoryID])
VALUES
	('ABAS', 1),
	('BOUL', 2),
	('DEBR', 3),
	('EBRO', 4),
	('GYUL', 5),
	('HELW', 6),
	('HOLL', 7),
	('KANZ', 8),
	('KIEV', 9),
	('KISL', 10),
	('KODA', 11),
	('MITA', 12),
	('MLSO', 13),
	('MWIL', 14),
	('NNNN', 15),
	('RAME', 16),
	('ROME', 17),
	('TASH', 19),
	('UCCL', 20),
	('USSU', 21),
	('SOHO', 110),
	('SHMI', 120)

--==========================================================
-- Load Frame table

IF OBJECT_ID('[load].[DPD_Frame]') IS NOT NULL
DROP TABLE [load].[DPD_Frame]

GO

CREATE TABLE [load].[DPD_Frame]
(
	[Dummy0] char NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] int NOT NULL,
	[Observatory] varchar(4) NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[JD] float NOT NULL,
	[P0] real NOT NULL,
	[B0] real NOT NULL
) ON [LOAD]

GO

BULK INSERT [load].[DPD_Frame]
FROM 'C:\Data\Raid6_0\temp\dobos\dpd_frame.txt' 
WITH ( 
	--LASTROW = 7800,			-- change this when file becomes OK
	DATAFILETYPE = 'char',
	FIELDTERMINATOR = ' ',
	ROWTERMINATOR = '0x0A',
	TABLOCK
)

GO

-- Verify invalid dates

SELECT *
FROM [load].[DPD_Frame]
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59


-- Fix rows with second = 60

UPDATE [load].[DPD_Frame]
SET [Minute] = [Minute] + 1,
	[Second] = 0
WHERE [Second] = 60 AND [Minute] < 59


-- Find key duplicates

SELECT dbo.fFrameID(d.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))), *
FROM [load].[DPD_Frame]
INNER JOIN Dataset d ON d.Name = 'DPD'
WHERE dbo.fFrameID(d.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) IN
(
	SELECT dbo.fFrameID(d.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
	FROM [load].[DPD_Frame]
	INNER JOIN Dataset d ON d.Name = 'DPD'
	GROUP BY dbo.fFrameID(d.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
	HAVING COUNT(*) > 2
)
ORDER BY 1

--

SELECT f.*, d.*
FROM [load].[DPD_Frame] d
INNER JOIN Dataset ON Dataset.Name = 'DPD'
INNER LOOP JOIN dbo.Frame f ON dbo.fFrameID(Dataset.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) = f.FrameID

-- These are SOHO observation that are used to patch missing obs from Debrecen

GO

-- Merge frame table

-- TRUNCATE TABLE [Frame]

WITH q AS
(
	SELECT
		--ROW_NUMBER() OVER (PARTITION BY dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) ORDER BY B0) rn,
		dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) AS FrameID,
		DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0) [Time],
		dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)) [JD],
		obs.ObservatoryID,
		[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
		[P0], [B0]
	FROM [load].[DPD_Frame]
	INNER JOIN [Observatory] obs ON obs.Name = [load].[DPD_Frame].Observatory
	INNER JOIN [Dataset] ds ON ds.Name = 'DPD'
)
INSERT [Frame] WITH (TABLOCKX)
	([FrameID],
	 [Time],
	 [JD],
	 [DatasetID],
	 [ObservatoryID],
	 [Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	 Pos_Angle,
	 Lat, Lon)
SELECT
	[FrameID],
	[Time],
	[JD],
	'DPD',
	[ObservatoryID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	-9999, -9999, -9999
FROM q

GO

SELECT COUNT(*)
FROM [Frame]
WHERE dbo.fDatasetIDFromFrameID(FrameID) = 1
-- 15980

GO

DROP TABLE [load].[DPD_Frame]

GO

--==========================================================
-- Load Group table

IF OBJECT_ID('[load].[DPD_Group]') IS NOT NULL
DROP TABLE [load].[DPD_Group]

GO

CREATE TABLE [load].[DPD_Group]
(
	[Dummy] char(1) NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] int NOT NULL,
	[GroupID] int NOT NULL,
	[GroupRev] varchar(2) NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[Lat] real NOT NULL,
	[Lon] real NOT NULL,
	[LCM] real NOT NULL,
	[Polar_Angle] real NOT NULL,
	[Polar_Radius] real NOT NULL/*,
	[B_U] real NULL,
	[B_UP] real NULL*/
) ON [LOAD]

GO

BULK INSERT [load].[DPD_Group]
FROM 'C:\Data\Raid6_0\temp\dobos\dpd_group.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

-- 5 errors due to invalid rows in files

GO

-- Verify invalid dates

SELECT *
FROM [load].[DPD_Group]
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59

GO

-- Fix rows with second = 60

UPDATE [load].[DPD_Group]
SET [Minute] = [Minute] + 1,
	[Second] = 0
WHERE [Second] = 60 AND [Minute] < 59

-- Merge groups

-- TRUNCATE TABLE [Group]

GO

INSERT INTO [dbo].[Group] WITH (TABLOCKX)
	(
	[GroupID], [GroupRev], [FrameID], [Time], [JD],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_P],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT
	[GroupID], [GroupRev],
	f.FrameID, f.[Time], f.[JD],
	g.[Proj_Area_U], g.[Proj_Area_UP], g.[Area_U], g.[Area_UP],
	g.[Lat], g.[Lon], [LCM], [Polar_Angle], [Polar_Radius],
	NULL,	-- B_U
	NULL,	-- B_UP
	cc.x, cc.y, cc.z, SkyQuery_CODE.htmid.FromEq(g.lon, g.lat)
FROM [load].[DPD_Group] g
INNER JOIN [Dataset] ds ON ds.Name = 'DPD'
INNER JOIN [Frame] f ON f.FrameID = dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY SkyQuery_CODE.point.EqToXyz(g.lon, g.lat) cc

GO

SELECT COUNT(*) FROM [load].[DPD_Group]
-- 111198

GO

DROP TABLE [load].[DPD_Group]

GO

--==========================================================
-- Load Spot table

DROP TABLE [load].[DPD_Spot]


CREATE TABLE [load].[DPD_Spot]
(
	[Dummy0] char(1) NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] int NOT NULL,
	[GroupID] int NOT NULL,
	[GroupRev] varchar(2) NOT NULL,
	[SpotID] tinyint NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[Lat] real NOT NULL,
	[Lon] real NOT NULL,
	[LCM] real NOT NULL,
	[Polar_Angle] real NOT NULL,
	[Polar_Radius] real NOT NULL
	/*,
	[MagneticFieldUmbra] real NULL,
	[MagneticFieldUmbraPenumbra] real NULL*/
) ON [LOAD]

GO

BULK INSERT [load].[DPD_Spot]
FROM 'C:\Data\Raid6_0\temp\dobos\dpd_spot.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)
-- 976206

GO

-- Verify invalid dates

SELECT *
FROM [load].[DPD_Spot]
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59

GO

-- Fix rows with second = 60

UPDATE [load].[DPD_Spot]
SET [Minute] = [Minute] + 1,
	[Second] = 0
WHERE [Second] = 60 AND [Minute] < 59

--TRUNCATE TABLE Spot

INSERT INTO [dbo].[Spot] WITH (TABLOCKX)
	(
	[FrameID], [Time], [JD], [GroupID], [GroupRev], [SpotID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_P],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT 
    f.FrameID, f.[Time], f.[JD],
	[GroupID], [GroupRev], [SpotID],
	s.[Proj_Area_U], s.[Proj_Area_UP], s.[Area_U], s.[Area_UP],
	s.[Lat], s.[Lon], [LCM], [Polar_Angle], [Polar_Radius],
	NULL, NULL, --[B_U], [B_UP],
	cc.x, cc.y, cc.z, SkyQuery_CODE.htmid.FromEq(s.lon, s.lat)
FROM [load].[DPD_Spot] s
INNER JOIN [Dataset] ds ON ds.Name = 'DPD'
INNER JOIN [Frame] f ON f.FrameID = dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY SkyQuery_CODE.point.EqToXyz(s.lon, s.lat) cc

-- 972395

GO

DROP TABLE [load].[DPD_Spot]

GO

CHECKPOINT

GO

-----
