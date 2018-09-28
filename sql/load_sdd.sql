INSERT Dataset
VALUES
	(3, 'SDD')

--

INSERT [Observatory]
	([Name], [ObservatoryID])
VALUES
	('SOHO', 110)

GO

--==========================================================
-- Load Frame table

IF OBJECT_ID('[load].[SDD_Frame]') IS NOT NULL
DROP TABLE [load].[SDD_Frame]

GO

CREATE TABLE [load].[SDD_Frame]
(
	[Dummy0] char(1) NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] real NOT NULL,
	[Observatory] varchar(4) NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[JD] real NOT NULL,
	[Pos_Angle] real NOT NULL,
	[Lat] real NOT NULL
) ON [LOAD]

GO

BULK INSERT [load].[SDD_Frame]
FROM 'C:\Data\Raid6_0\temp\dobos\sdd_frame.txt'
WITH ( 
	--LASTROW = 7800,			-- change this when file becomes OK
	DATAFILETYPE = 'char',
	FIELDTERMINATOR = ' ',
	ROWTERMINATOR = '0x0A',
	TABLOCK
)

GO

WITH 
a AS
(
	SELECT
		dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) AS FrameID,
		DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0) [Time],
		dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)) [JD],
		ds.[DatasetID],
		obs.[ObservatoryID],
		[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
		[Pos_Angle], [Lat], -9999 AS [Lon]
	FROM [load].[SDD_Frame]
	INNER JOIN Observatory obs ON obs.Name = 'SOHO'
	INNER JOIN Dataset ds ON ds.Name = 'SDD'
),
b AS
(
	SELECT
		ROW_NUMBER() OVER (PARTITION BY FrameID ORDER BY Lat) rn,
		a.*
	FROM a
)
INSERT [Frame] WITH (TABLOCKX)
	([FrameID],
	 [Time],
	 [JD],
	 [DatasetID],
	 [ObservatoryID],
	 [Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	 [Pos_Angle], [Lat], [Lon])
SELECT
	[FrameID],
	[Time],
	[JD],
	[DatasetID],
	[ObservatoryID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Pos_Angle], [Lat], [Lon]
FROM b
WHERE rn = 1

-- (41332 rows affected)

GO

--

DROP TABLE [load].[SDD_Frame]

GO

--==========================================================
-- Load Group table

IF OBJECT_ID('[load].SDD_Group') IS NOT NULL
DROP TABLE [load].SDD_Group

CREATE TABLE [load].SDD_Group
(
	[Dummy0] char(1) NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] real NOT NULL,
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
	[Polar_Radius] real NOT NULL,
	[B_U] real NULL,
	[B_P] real NULL
) ON [LOAD]

GO

TRUNCATE TABLE [load].SDD_Group
GO

BULK INSERT [load].SDD_Group
FROM 'C:\Data\Raid6_0\temp\dobos\sdd_group.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

-- (349271 rows affected)

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
	B_U,
	B_P,
	cc.x, cc.y, cc.z, SkyQuery_CODE.htmid.FromEq(g.lon, g.lat)
FROM [load].SDD_Group g
INNER JOIN Dataset ds ON ds.Name = 'SDD'
INNER LOOP JOIN [Frame] f ON f.FrameID = dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY SkyQuery_CODE.point.EqToXyz(g.lon, g.lat) cc

-- (290378 rows affected)

SELECT COUNT(*)
FROM [dbo].[Group]
WHERE dbo.fDatasetIDFromFrameID(FrameID) = 3

-- 290378

--

GO

DROP TABLE [load].SDD_Group

GO

--==========================================================
-- Load Spot table

IF OBJECT_ID('[load].SDD_Spot') IS NOT NULL
DROP TABLE [load].SDD_Spot

CREATE TABLE [load].SDD_Spot
(
	[Dummy0] char(1) NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] real NOT NULL,
	[GroupID] int NOT NULL,
	[GroupRev] varchar(2) NOT NULL,
	[SpotID] smallint NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[Lat] real NOT NULL,
	[Lon] real NOT NULL,
	[LCM] real NOT NULL,
	[Polar_Angle] real NOT NULL,
	[Polar_Radius] real NOT NULL,
	[B_U] real NOT NULL,
	[B_P] real NOT NULL
) ON [LOAD]

GO

TRUNCATE TABLE [load].SDD_Group
GO

BULK INSERT [load].SDD_Spot
FROM 'C:\Data\Raid6_0\temp\dobos\sdd_spot.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

GO

-- (2677827 rows affected)

SELECT COUNT(*) FROM load.SDD_Spot

-- 2677827

GO

INSERT INTO [dbo].[Spot] WITH (TABLOCKX)
	(
	[FrameID], [Time], [JD], [GroupID], [GroupRev], [SpotID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_P],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT 
    dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))), 
	DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0) [Time],
	dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)) [JD],
	[GroupID], [GroupRev], [SpotID],
	s.[Proj_Area_U], s.[Proj_Area_UP], s.[Area_U], s.[Area_UP],
	s.[Lat], s.[Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_P],
	cc.x, cc.y, cc.z, SkyQuery_CODE.htmid.FromEq(s.lon, s.lat)
FROM [load].SDD_Spot s
INNER JOIN [Dataset] ds ON ds.Name = 'SDD'
CROSS APPLY SkyQuery_CODE.point.EqToXyz(s.lon, s.lat) cc

-- (2677827 rows affected)

SELECT COUNT(*) FROM dbo.Spot
WHERE dbo.fDatasetIDFromFrameID(FrameID) = 3

-- 2677827

GO
