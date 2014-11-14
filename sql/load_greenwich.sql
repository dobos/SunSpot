-- Load data into temporary table

CREATE TABLE Load_Greenwich
(
	Year int,
	Month int,
	Day int,
	Time int,
	GroupID int,
	GroupRev char(1),
	GroupType char(3),
	Proj_Area_U real,
	Proj_Area_UP real,
	Area_U real,
	Area_UP real,
	Polar_Radius real,
	Polar_Angle real,
	Lon real,
	Lat real,
	LCM real
) ON [LOAD]


TRUNCATE TABLE Load_Greenwich

DECLARE @sql nvarchar(max)
DECLARE @year int = 1874

WHILE (@year < 2015)
BEGIN

	SET @sql = '
	BULK INSERT Load_Greenwich
	FROM ''C:\Data\Temp\vo\napfolt\gw\g' + CAST(@year as CHAR(4)) + '.txt''
	WITH
	(
		TABLOCK,
		FORMATFILE = ''C:\Data\Temp\vo\napfolt\gw\_bcpformat.txt''
	)'

	EXEC(@sql)

	SET @year = @year + 1

END


/* FORMAT

11.0
16
1       SQLCHAR             0       4       ""   1     Year                         ""
2       SQLCHAR             0       2       ""   2     Month                        ""
3       SQLCHAR             0       2       "."  3     Day                          ""
4       SQLCHAR             0       3       ""   4     Time                         ""
5       SQLCHAR             0       8       ""   5     GroupID                      ""
6       SQLCHAR             0       1       ""   6     GroupRev                     ""
7       SQLCHAR             0       3       ""   7     GroupType                    ""
8       SQLCHAR             0       5       ""   8     Proj_Area_U                  ""
9       SQLCHAR             0       5       ""   9     Proj_Area_UP                 ""
10      SQLCHAR             0       5       ""  10    Area_U                       ""
11      SQLCHAR             0       5       ""  11    Area_UP                      ""
12      SQLCHAR             0       6       ""  12    Polar_Radius                 ""
13      SQLCHAR             0       6       ""  13    Polar_Angle                  ""
14      SQLCHAR             0       6       ""  14    Lon                          ""
15      SQLCHAR             0       6       ""  15    Lat                          ""
16      SQLCHAR             0       6       "\n"  16    LCM                          ""


*/


GO

--==========================================================
-- Verify data

-- Find duplicate group IDs


WITH q AS
(
	SELECT 
		*,
		astro.ConvertTimePartsToJd(year, month, day, 0, 0, 0, 0) + time / 1000.0 AS JD,
		CASE
			WHEN year <= 1976 THEN 100
			WHEN year > 1976 THEN 101
		END AS ObservatoryID
	FROM Load_Greenwich
)
SELECT 
	GroupID,
	GroupRev + GroupType,
	dbo.fFrameID(ObservatoryID, JD) AS FrameID,
	COUNT(*)
FROM q
GROUP BY GroupID,
	GroupRev + GroupType,
	dbo.fFrameID(ObservatoryID, JD)
HAVING COUNT(*) > 1

-- Fix duplicates

SELECT * FROM Load_Greenwich
WHERE GroupID = 1962 AND Day = 30

UPDATE Load_Greenwich
SET GroupRev = 'B'
WHERE GroupID = 1962 AND Day = 30 AND Proj_Area_UP = 105

SELECT * FROM Load_Greenwich
WHERE GroupID = 8894 AND Day = 29

UPDATE Load_Greenwich
SET GroupRev = 'B'
WHERE GroupID = 8894 AND Day = 29 AND Proj_Area_UP = 16


--==========================================================
-- Merge into destination tables


-- Generate Observatory entries

INSERT [Observatory]
	([Name], [ObservatoryID])
VALUES
	('GreenwichPre1976', 100),
	('GreenwichPost1976', 101)

GO


-- Merge in groups

WITH q AS
(
	SELECT 
		*,
		astro.ConvertTimePartsToJd(year, month, day, 0, 0, 0, 0) + time / 1000.0 AS JD,
		CASE
			WHEN year <= 1976 THEN 100
			WHEN year > 1976 THEN 101
		END AS ObservatoryID
	FROM Load_Greenwich
)
INSERT INTO [dbo].[Group] WITH (TABLOCKX)
(
	[GroupID], [GroupRev], [FrameID], [Time], [JD],
	[Proj_Area_U], [Proj_Area_UP], [Area_U], [Area_UP],
	[Lat], [Lon], [LCM], [Polar_Angle], [Polar_Radius],
	[B_U], [B_UP],
	[CX], [CY], [CZ], [HtmID]
)
SELECT DISTINCT
	GroupID,
	GroupRev + GroupType,
	dbo.fFrameID(ObservatoryID, JD) AS FrameID,
	astro.ConvertTimeJdToTai(JD),
	JD,
	Proj_Area_U,
	Proj_Area_UP,
	Area_U,
	Area_UP,
	Lat,
	Lon,
	LCM,
	Polar_Angle,
	Polar_Radius,
	NULL, NULL,
	cc.x, cc.y, cc.z,
	BestDR7.dbo.fHtmEq(lon, lat)
FROM q
CROSS APPLY BestDR7.dbo.fHtmEqToXyz(lon, lat) cc
WHERE GroupID IS NOT NULL

-- Generate frames for groups

INSERT Frame WITH (TABLOCKX)
SELECT
	FrameID, 
	MAX(time),
	MAX(JD),
	dbo.fObservatoryIDFromFrameID(FrameID),
	SUM(Proj_Area_U),
	SUM(Proj_Area_UP),
	SUM(Area_U),
	SUM(Area_UP),
	0, 0
FROM [Group]
WHERE dbo.fObservatoryIDFromFrameID(FrameID) IN (100, 101)
GROUP BY FrameID, dbo.fObservatoryIDFromFrameID(FrameID)