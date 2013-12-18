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



CREATE FUNCTION fFrameID
(
	@ObservatoryID int,
	@JD float
)
RETURNS int
AS
BEGIN
	RETURN 0x1000000 * @ObservatoryID + FLOOR((@JD - 2400000.5) * 100)
END

