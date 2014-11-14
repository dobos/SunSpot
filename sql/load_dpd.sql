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
	('SOHO', 18),
	('TASH', 19),
	('UCCL', 20),
	('USSU', 21),
	('SHMI', 22)

GO

--==========================================================
-- Load Frame table

CREATE TABLE [Frame_Load]
(
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
	[JD] real NOT NULL,
	[P0] real NOT NULL,
	[B0] real NOT NULL
) ON [LOAD]

GO

BULK INSERT [Frame_Load]
FROM 'C:\data\Temp\vo\napfolt\frameall.txt' 
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
FROM [Frame_Load]
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59


-- Fix rows with second = 60

UPDATE [Frame_Load]
SET [Minute] = [Minute] + 1,
	[Second] = 0
WHERE [Second] = 60 AND [Minute] < 59


-- Find key duplicates

SELECT dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))), *
FROM [Frame_Load]
INNER JOIN [Observatory] obs ON obs.Name = Frame_Load.Observatory
WHERE dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) IN
(
	SELECT dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
	FROM [Frame_Load]
	INNER JOIN [Observatory] obs ON obs.Name = Frame_Load.Observatory
	GROUP BY dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
	HAVING COUNT(*) > 2
)
ORDER BY 1

GO

-- Merge frame table

-- TRUNCATE TABLE [Frame]

WITH q AS
(
	SELECT
		--ROW_NUMBER() OVER (PARTITION BY dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) ORDER BY B0) rn,
		dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0))) AS FrameID,
		DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0) [Time],
		dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)) [JD],
		obs.ObservatoryID,
		[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
		[P0], [B0]
	FROM [Frame_Load]
	INNER JOIN [Observatory] obs ON obs.Name = Frame_Load.Observatory
)
INSERT [Frame] WITH (TABLOCKX)
	([FrameID],
	 [Time],
	 [JD],
	 [ObservatoryID],
	 [Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	 [P0], [B0])
SELECT
	[FrameID],
	[Time],
	[JD],
	[ObservatoryID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[P0], [B0]
FROM q
--WHERE rn = 1

GO

DROP TABLE [Frame_Load]

GO

--==========================================================
-- Load Group table

CREATE TABLE [Group_Load]
(
	[Observatory] char(4) NOT NULL,
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

BULK INSERT Group_Load
FROM 'C:\data\Temp\vo\napfolt\groupall.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

GO

-- Verify invalid dates

SELECT *
FROM [Group_Load]
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59

GO

-- Fix rows with second = 60

UPDATE [Group_Load]
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
	[B_U], [B_UP],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT
	[GroupID], [GroupRev],
	f.FrameID, f.[Time], f.[JD],
	g.[Proj_Area_U], g.[Proj_Area_UP], g.[Area_U], g.[Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	NULL,	-- B_U
	NULL,	-- B_UP
	cc.x, cc.y, cc.z, BestDR7.dbo.fHtmEq(lon, lat)
FROM [dbo].[Group_Load] g
INNER JOIN Observatory obs ON obs.Name = [Observatory]
INNER JOIN [Frame] f ON f.FrameID = dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY BestDR7.dbo.fHtmEqToXyz(lon, lat) cc

GO

DROP TABLE Group_Load

GO

--==========================================================
-- Load Spot table

CREATE TABLE [Spot_Load]
(
	[Observatory] char(4) NOT NULL,
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

BULK INSERT Spot_Load
FROM 'C:\data\Temp\vo\napfolt\spotall.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '0x0A',
   TABLOCK
)

GO

-- Verify invalid dates

SELECT *
FROM Spot_Load
WHERE [Hour] < 0 OR [Hour] > 23 OR [Minute] < 0 OR [Minute] > 59 OR [Second] < 0 OR [Second] > 59

GO

-- Fix rows with second = 60

UPDATE Spot_Load
SET [Minute] = [Minute] + 1,
	[Second] = 0
WHERE [Second] = 60 AND [Minute] < 59

--TRUNCATE TABLE Spot

INSERT INTO [dbo].[Spot] WITH (TABLOCKX)
	(
	[FrameID], [Time], [JD], [GroupID], [GroupRev], [SpotID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_UP],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT 
    f.FrameID, f.[Time], f.[JD],
	[GroupID], [GroupRev], [SpotID],
	s.[Proj_Area_U], s.[Proj_Area_UP], s.[Area_U], s.[Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	NULL, NULL, --[B_U], [B_UP],
	cc.x, cc.y, cc.z, BestDR7.dbo.fHtmEq(lon, lat)
FROM [Spot_Load] s
INNER JOIN Observatory obs ON obs.Name = [Observatory]
INNER JOIN [Frame] f ON f.FrameID = dbo.fFrameID(obs.ObservatoryID, dbo.fJD(DATETIME2FROMPARTS([Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0)))
CROSS APPLY BestDR7.dbo.fHtmEqToXyz(lon, lat) cc

GO

DROP TABLE [Spot_Load]

GO



CHECKPOINT