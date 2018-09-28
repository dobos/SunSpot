IF OBJECT_ID('fJD') IS NOT NULL
DROP FUNCTION fJD

GO

CREATE FUNCTION fJD
(
	@date datetime2
)
RETURNS float
AS
BEGIN
	DECLARE @a int = FLOOR((14 - DATEPART(month, @date)) / 12)
	DECLARE @y int = DATEPART(year, @date) + 4800 - @a
	DECLARE @m int = DATEPART(month, @date) + 12 * @a - 3

	DECLARE @s int = (DATEPART(hour, @date) - 12) * 3600 + DATEPART(minute, @date) * 60 + DATEPART(second, @date)
	DECLARE @ns int = DATEPART(nanosecond, @date)

	RETURN DATEPART(day, @date) +
	       FLOOR((153 * @m + 2) / 5) +
		   365 * @y +
		   FLOOR(@y / 4) -
		   FLOOR(@y / 100) +
		   FLOOR(@y / 400) -
		   32045 +
		   (@s + @ns * 1.0e-9) / 86400.00000000
END
GO

----

IF OBJECT_ID('fFrameID') IS NOT NULL
DROP FUNCTION fFrameID

GO


CREATE FUNCTION fFrameID
(
	@DatasetID tinyint,
	@JD float
)
RETURNS int
AS
BEGIN
	-- bit layout:
	RETURN CAST(@DatasetID AS binary(1)) +
		   CAST(CAST(FLOOR((@JD - 2400000.5) * 100) AS int) AS binary(3))
END

GO

----

IF OBJECT_ID('fDatasetIDFromFrameID') IS NOT NULL
DROP FUNCTION fDatasetIDFromFrameID

GO

CREATE FUNCTION fDatasetIDFromFrameID
(
	@FrameID int
)
RETURNS tinyint
AS
BEGIN
	RETURN CAST(CAST((@FrameID & 0xFF000000) / 0x1000000 AS binary(1)) AS tinyint)
END

GO

----

/*
SELECT CAST(CAST(FLOOR((2458388.89402 - 2400000.5) * 100) AS int) AS binary(4))
SELECT CAST(CAST(FLOOR((2458388.89402 - 2400000.5) * 100) AS int) AS binary(8))

SELECT dbo.fFrameID(1, 2458388.89402), CAST(dbo.fFrameID(1, 2458388.89402) AS binary(4))
-- 22616055	0x015917F7

SELECT CAST(0x78 AS int)

SELECT CAST(CAST(0x44504478005917F7 AS bigint) & 0x000000FF00000000 AS binary(8))

SELECT dbo.fDatasetIDFromFrameID(0x015917F7)

----
*/