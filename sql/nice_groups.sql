------ Lek�rni az �sszes "sz�p" foltcsoportot

WITH
greenwich AS
(
	SELECT g.*
	FROM [Group] g
	INNER JOIN [Frame] f ON f.FrameID = g.FrameID
	WHERE ObservatoryID = 100
),
ordered AS
(
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY GroupID ORDER BY JD) AS row
	FROM greenwich
	WHERE Proj_Area_UP > 0
)
SELECT GroupID, COUNT(*), AVG(JD), MAX(Proj_Area_UP)
FROM ordered
GROUP BY GroupID
HAVING COUNT(*) > 10


-- Lek�ri az �sszes olyan foltcsoportot, ahol legal�bb 2 �szlel�s
-- van a maximum el�tt �s ut�n

WITH
greenwich AS
(
	SELECT g.*, ROW_NUMBER() OVER (PARTITION BY GroupID ORDER BY g.JD) AS row
	FROM [Group] g
	INNER JOIN [Frame] f ON f.FrameID = g.FrameID
	WHERE ObservatoryID = 100
),
nice AS
(
	SELECT 
		GroupID, COUNT(*) cnt, MAX(Proj_Area_UP) max_area, AVG(JD) avg_jd
	FROM greenwich
	GROUP BY GroupID
	HAVING COUNT(*) > 10
)
SELECT nice.*, row
FROM nice
INNER JOIN greenwich AS maximumok
	ON maximumok.GroupID = nice.GroupID AND maximumok.Proj_Area_UP = nice.max_area
WHERE row > 2 AND row < cnt - 1
ORDER BY GroupID


-- Lek�rni az egy foltcsoporthoz tartoz� �szlel�seket

DECLARE @GroupID int = 10741;

WITH
greenwich AS
(
	SELECT g.*
	FROM [Group] g
	INNER JOIN [Frame] f ON f.FrameID = g.FrameID
	WHERE ObservatoryID = 100
),
q AS
(
	SELECT
		GroupID, GroupRev, JD,
		Proj_Area_UP, Area_UP, Lat, Lon
	FROM greenwich
	WHERE GroupID = @GroupID AND JD < 2443509.500000 -- 1977
	      AND Proj_Area_UP > 0
)
SELECT * FROM q
ORDER BY JD


