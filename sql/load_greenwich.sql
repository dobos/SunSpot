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