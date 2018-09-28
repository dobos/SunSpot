INSERT Dataset
VALUES
	(2, 'GPR')

--

INSERT [Observatory]
	([Name], [ObservatoryID])
VALUES
	('GREE', 100),
	('GRE2', 101)


-- Load data into temporary table

IF OBJECT_ID('[load].[GPR_Frame]') IS NOT NULL
DROP TABLE [load].[GPR_Frame]

GO

CREATE TABLE [load].[GPR_Frame]
(
	[Dummy] char(1) NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] int NOT NULL,
	[Observatory] char(4) NOT NULL,
	[Proj_Area_U] real NULL,
	[Proj_Area_UP] real NULL,
	[Area_U] real NULL,
	[Area_UP] real NULL,
	[JD] float NOT NULL,
	[P0] real NOT NULL,
	[B0] real NOT NULL
) ON [LOAD]

GO

BULK INSERT [load].[GPR_Frame]
FROM 'C:\Data\Raid6_0\temp\dobos\gpr_frame.txt' 
WITH ( 
	DATAFILETYPE = 'char',
	FIELDTERMINATOR = ' ',
	ROWTERMINATOR = '0x0A',
	TABLOCK
)
-- 37794

GO

-- Verify invalid dates

SELECT *
FROM [load].[GPR_Frame]
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59 OR
	  [Year] < 1870 OR
      [Month] < 0 OR [Month] > 12 OR [Day] < 0 OR [Day] > 31 OR
	  [Month] = 2 AND [Day] > 28 AND [Year] % 4 != 0 OR
	  [Month] = 4 AND [Day] > 30 OR
	  [Month] = 6 AND [Day] > 30 OR
	  [Month] = 9 AND [Day] > 30 OR
	  [Month] = 11 AND [Day] > 30

-- Merge frame table


WITH q AS
(
	SELECT
		--ROW_NUMBER() OVER (PARTITION BY dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) ORDER BY B0) rn,
		dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) AS FrameID,
		DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0) [Time],
		dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)) [JD],
		ds.DatasetID,
		CASE WHEN [Year] < 1976 THEN 100 ELSE 101 END AS ObservatoryID,
		[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
		[P0], [B0]
	FROM [load].[GPR_Frame]
	INNER JOIN [Dataset] ds ON ds.Name = 'GPR'
	WHERE [Year] > 0
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
	[DatasetID],
	[ObservatoryID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	-9999, -9999, -9999
FROM q
WHERE [Time] != '1890-05-16 09:36:00'		-- filter out duplicate

-- (37061 rows affected)

SELECT COUNT(*)
FROM dbo.Frame
WHERE dbo.fDatasetIDFromFrameID(FrameID) = 2
-- 37061


--==========================================================
-- Load Group table

IF OBJECT_ID('[load].[GPR_Group]') IS NOT NULL
DROP TABLE [load].[GPR_Group]

GO

CREATE TABLE [load].[GPR_Group]
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
	[Polar_Radius] real NOT NULL,
	[B_U] real NULL,
	[B_P] real NULL
) ON [LOAD]

GO

BULK INSERT [load].[GPR_Group]
FROM 'C:\Data\Raid6_0\temp\dobos\gpr_group.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

-- 1 error due to invalid rows in files

GO

SELECT COUNT(*) FROM [load].[GPR_Group]
-- 161819

-- Merge groups

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
FROM [load].[GPR_Group] g
INNER JOIN [Dataset] ds ON ds.Name = 'GPR'
INNER JOIN [Frame] f ON f.FrameID = dbo.fFrameID(ds.DatasetID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY SkyQuery_CODE.point.EqToXyz(g.lon, g.lat) cc

-- (161819 rows affected)

SELECT COUNT(*)
FROM dbo.[Group]
WHERE dbo.fDatasetIDFromFrameID(FrameID) = 2
-- 161819

