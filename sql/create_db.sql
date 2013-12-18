USE [master]
GO

CREATE DATABASE [SunSpot]
	CONTAINMENT = NONE
ON  PRIMARY 
( NAME = N'SunSpot_0', FILENAME = N'C:\data\Raid6_0\vo\sql_db\SunSpot\SunSpot_0.mdf' , SIZE = 512MB , MAXSIZE = UNLIMITED, FILEGROWTH = 0), 
( NAME = N'SunSpot_1', FILENAME = N'C:\data\Raid6_1\vo\sql_db\SunSpot\SunSpot_1.ndf' , SIZE = 512MB , MAXSIZE = UNLIMITED, FILEGROWTH = 0),
FILEGROUP [LOAD]
( NAME = N'Load_0', FILENAME = N'C:\data\Raid6_0\vo\sql_db\SunSpot\Load_0.mdf' , SIZE = 512MB , MAXSIZE = UNLIMITED, FILEGROWTH = 0), 
( NAME = N'Load_1', FILENAME = N'C:\data\Raid6_1\vo\sql_db\SunSpot\Load_1.ndf' , SIZE = 512MB , MAXSIZE = UNLIMITED, FILEGROWTH = 0)
LOG ON 
( NAME = N'SunSpot_0_log', FILENAME = N'C:\data\Raid6_0\vo\sql_db\SunSpot\SunSpot_0_log.ldf' , SIZE = 50MB , MAXSIZE = 2048GB , FILEGROWTH = 0), 
( NAME = N'SunSpot_1_log', FILENAME = N'C:\data\Raid6_1\vo\sql_db\SunSpot\SunSpot_1_log.ldf' , SIZE = 50MB , MAXSIZE = 2048GB , FILEGROWTH = 0)

GO

ALTER DATABASE [SunSpot] SET RECOVERY SIMPLE

GO