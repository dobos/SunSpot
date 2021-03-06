INSERT Dataset
VALUES
	(4, 'SDO')

GO

----

INSERT [Observatory]
	([Name], [ObservatoryID])
VALUES
	('SHMI', 120)

GO

--==========================================================
-- Load Frame table

IF OBJECT_ID('[load].[SDO_Frame]') IS NOT NULL
DROP TABLE [load].[SDO_Frame]

GO

CREATE TABLE [load].[SDO_Frame]
(
	[ObservatoryID] int NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] real NOT NULL,
	[Observatory] varchar(4) NOT NULL,
	[GroupNum] smallint NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[JD] real NOT NULL,
	[Pos_Angle] real NOT NULL,
	[Lat] real NOT NULL,
	[Lon] real NOT NULL,
	[Dummy1] int NOT NULL,
	[Dummy2] int NOT NULL,
	[Dummy3] int NOT NULL,
) ON [LOAD]

GO

BULK INSERT [load].[SDO_Frame]
FROM 'C:\Data\Raid6_0\temp\dobos\sdo_frame.txt'
WITH ( 
	--LASTROW = 7800,			-- change this when file becomes OK
	DATAFILETYPE = 'char',
	FIELDTERMINATOR = ' ',
	ROWTERMINATOR = '0x0A',
	TABLOCK
)

-- (40470 rows affected)

GO

WITH 
a AS
(
	SELECT
		dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) AS FrameID,
		DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0) [Time],
		dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)) [JD],
		ds.DatasetID,
		ObservatoryID,
		[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
		[Pos_Angle], [Lat], [Lon]
	FROM [load].[SDO_Frame]
	INNER JOIN Dataset ds ON ds.Name = 'SDO'
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

-- (40469 rows affected)

SELECT COUNT(*) FROM [Frame]
WHERE dbo.fDatasetIDFromFrameID(FrameID) = 4

-- 40469

GO

DROP TABLE [load].[SDO_Frame]

GO

--==========================================================
-- Load Group table

IF OBJECT_ID('[load].SDO_Group') IS NOT NULL
DROP TABLE [load].SDO_Group

CREATE TABLE [load].SDO_Group
(
	[ObservatoryID] tinyint NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] real NOT NULL,
	[GroupID] int NOT NULL,
	[GroupRev] varchar(2) NOT NULL,
	[GroupNum] smallint NOT NULL,
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

TRUNCATE TABLE [load].SDO_Group
GO

BULK INSERT [load].SDO_Group
FROM 'C:\Data\Raid6_0\temp\dobos\sdo_group.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

-- (532928 rows affected)

SELECT COUNT(*) FROM [load].SDO_Group

-- 532928

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
FROM [load].SDO_Group g
INNER JOIN Dataset ds ON ds.Name = 'SDO'
INNER LOOP JOIN [Frame] f ON f.FrameID = dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY SkyQuery_CODE.point.EqToXyz(g.lon, g.lat) cc

-- (532913 rows affected)

GO

DROP TABLE [load].SDO_Group

GO

--==========================================================
-- Load Spot table

IF OBJECT_ID('[load].SDO_Spot') IS NOT NULL
DROP TABLE [load].SDO_Spot

CREATE TABLE [load].SDO_Spot
(
	[ObservatoryID] tinyint NOT NULL,
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

TRUNCATE TABLE [load].SDO_Group
GO

BULK INSERT [load].SDO_Spot
FROM 'C:\Data\Raid6_0\temp\dobos\sdo_spot.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

-- 1 error during load due to corrupt file format

GO

SELECT COUNT(*) FROM load.SDO_Spot

-- 5630006
-- wc -l gives 5630008 rows

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
    f.FrameID, f.[Time], f.[JD],
	[GroupID], [GroupRev], [SpotID],
	s.[Proj_Area_U], s.[Proj_Area_UP], s.[Area_U], s.[Area_UP],
	s.[Lat], s.[Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_P],
	cc.x, cc.y, cc.z, SkyQuery_CODE.htmid.FromEq(s.lon, s.lat)
FROM [load].SDO_Spot s
INNER JOIN Dataset ds ON ds.Name = 'SDO'
INNER JOIN [Frame] f ON f.FrameID = dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY SkyQuery_CODE.point.EqToXyz(s.lon, s.lat) cc

-- (5629827 rows affected)

GO