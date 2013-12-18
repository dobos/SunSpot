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
	[FrameID] int NOT NULL,
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
FROM 'C:\data\Temp\vo\napfolt\frame_DPDfull.txt' 
WITH ( 
	LASTROW = 7800,			-- change this when file becomes OK
	DATAFILETYPE = 'char',
	FIELDTERMINATOR = ' ',
	ROWTERMINATOR = '\n',
	TABLOCK
)

GO

-- Merge frame table

-- TRUNCATE TABLE [Frame]

INSERT [Frame] WITH (TABLOCKX)
	([FrameID],
	 [Time],
	 [JD], [ObservatoryID],
	 [Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	 [P0], [B0])
SELECT
	[FrameID],
	DATETIME2FROMPARTS ( [Year], [Month], [Day], [Hour], [Minute], [Second], 0, 0),
	[JD], obs.ObservatoryID,
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[P0], [B0]
FROM [Frame_Load]
INNER JOIN [Observatory] obs ON obs.Name = Frame_Load.Observatory

GO

DROP TABLE [Frame_Load]

GO

--==========================================================
-- Load Group table

CREATE TABLE [Group_Load]
(
	[FrameID] int NOT NULL,
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
FROM 'C:\data\Temp\vo\napfolt\group_DPDfull.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '\n',
   TABLOCK
)

GO

-- Verify key uniqueness

SELECT [FrameID], [GroupID], [GroupRev], COUNT(*)
FROM [Group_Load]
GROUP BY [FrameID], [GroupID], [GroupRev]
HAVING COUNT(*) > 1

-- Merge groups

-- TRUNCATE TABLE [Group]

GO

INSERT INTO [dbo].[Group] WITH (TABLOCKX)
	(
	[GroupID], [GroupRev], [FrameID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_UP],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT
	[GroupID], [GroupRev], [FrameID],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	NULL,	-- B_U
	NULL,	-- B_UP
	cc.x, cc.y, cc.z, BestDR7.dbo.fHtmEq(lon, lat)
FROM [dbo].[Group_Load]
CROSS APPLY BestDR7.dbo.fHtmEqToXyz(lon, lat) cc
WHERE FrameID NOT IN (54794257, 55594054)		-- delete if fixed

GO

DROP TABLE Group_Load

GO

--==========================================================
-- Load Spot table

CREATE TABLE [Spot_Load]
(
	[FrameID] int NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[Day] int NOT NULL,
	[Hour] int NOT NULL,
	[Minuteg int NOT NULL,
	[Second] int NOT NULL,
	[GroupID] int NOT NULL,
	[GroupRev] varchar(2) NOT NULL,
	[Number] tinyint NOT NULL,
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
FROM 'C:\data\Temp\vo\napfolt\spot_DPDfull.txt' 
WITH ( 
	CODEPAGE = 'ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR = ' ',
   ROWTERMINATOR = '\n',
   TABLOCK
)

GO

--TRUNCATE TABLE Spot

INSERT INTO [dbo].[Spot] WITH (TABLOCKX)
	(
	[SpotID],
	[FrameID], [GroupID], [GroupRev], [Number],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_UP],
	[CX], [CY], [CZ], [HtmID]
	)
SELECT DISTINCT 
	-- calculatestopidhere
    [FrameID], [GroupID], [GroupRev], [Number],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	NULL, NULL, --[B_U], [B_UP],
	cc.x, cc.y, cc.z, BestDR7.dbo.fHtmEq(lon, lat)
FROM [Spot_Load]
CROSS APPLY BestDR7.dbo.fHtmEqToXyz(lon, lat) cc

GO

DROP TABLE [Spot_Load]

GO
