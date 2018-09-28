IF OBJECT_ID (N'[Dataset]', N'U') IS NOT NULL
DROP TABLE [Dataset]

CREATE TABLE [Dataset]
(
--/ <summary>Contains info on observatories</summary>
--/ <remarks></remarks>
	[DatasetID] tinyint NOT NULL,
	[Name] varchar(3) NOT NULL   --/ <column>Unique ID of the data set</column>

	CONSTRAINT [PK_Dataset] PRIMARY KEY CLUSTERED 
	(
		[DatasetID]
	)  ON [PRIMARY]
) ON [PRIMARY]

GO

IF OBJECT_ID (N'Observatory', N'U') IS NOT NULL
DROP TABLE [Observatory]

CREATE TABLE [Observatory]
(
--/ <summary>Contains info on observatories</summary>
--/ <remarks></remarks>
	[ObservatoryID] tinyint NOT NULL,--/ <column>Unique ID of the observatory</column>
	[Name] varchar(25),				--/ <column>Name of the observatory</column>

	CONSTRAINT [PK_Observatory] PRIMARY KEY CLUSTERED 
	(
		[ObservatoryID]
	)  ON [PRIMARY]
) ON [PRIMARY]

GO

IF OBJECT_ID (N'Frame', N'U') IS NOT NULL
DROP TABLE [Frame]

CREATE TABLE [Frame]
(
--/ <summary>Contains info on observed frames</summary>
--/ <remarks></remarks>
	[FrameID] bigint NOT NULL,		--/ <column>Unique ID of the frame</column>
	[Time] datetime2 NOT NULL,		--/ <column>Time of observation (UTC)</column>
	[JD] float NOT NULL,			--/ <column>Julian Date of observation</column>
	[DatasetID] char(3) NOT NULL,	--/ <column>ID of the data set</column>
	[ObservatoryID] tinyint NOT NULL,--/ <column>ID of the observatory</column>
	[Proj_Area_U] real NULL,		--/ <column unit="">Total projected area of the Umbra of the spots</column>
	[Proj_Area_UP] real NULL,		--/ <column unit="">Total projected area of the Umbra and the Penumbra of the spots</column>
	[Area_U] real NULL,				--/ <column unit="">Total corrected area of the Umbra of the spots</column>
	[Area_UP] real NULL,			--/ <column unit="">Total corrected area of the Umbra and the Penumbra of the spots</column>
	[Pos_Angle] real NOT NULL,
	[Lat] real NOT NULL,
	[Lon] real NOT NULL

	CONSTRAINT [PK_Frame] PRIMARY KEY CLUSTERED 
	(
		[FrameID]
	)  ON [PRIMARY]
) ON [PRIMARY]

GO

IF OBJECT_ID (N'Group', N'U') IS NOT NULL
DROP TABLE [Group]

CREATE TABLE [Group]
(
--/ <summary>Contains info on spot groups</summary>
--/ <remarks></remarks>
	[GroupID] int NOT NULL,			--/ <column>NOAA ID of the spot group</column>
	[GroupRev] varchar(5) NOT NULL,	--/ <column>Revised group ID extension</column>
	[FrameID] bigint NOT NULL,		--/ <column>Reference to the frame</column>
	[Time] datetime2 NOT NULL,		--/ <column>Time of observation (UTC)</column>
	[JD] float NOT NULL,			--/ <column>Julian Date of observation</column>
	[Proj_Area_U] real NULL,		--/ <column unit="">Total projected area of the Umbra of the spots of the group</column>
	[Proj_Area_UP] real NULL,		--/ <column unit="">Total projected area of the Umbra and the Penumbra of the spots of the group</column>
	[Area_U] real NULL,				--/ <column unit="">Total corrected area of the Umbra of the spots of the group</column>
	[Area_UP] real NULL,			--/ <column unit="">Total corrected area of the Umbra and the Penumbra of the spots of the group</column>
	[Lat] real NOT NULL,			--/ <column unit="deg">Carrington latitude of the weigted center of the group</column>
	[Lon] real NOT NULL,			--/ <column unit="deg">Carrington longitude of the weigted center of the group</column>
	[LCM] real NOT NULL,			--/ <column unit="deg">Distance in longitude from the central meridian of the weigted center of the group</column>
	[Polar_Angle] real NOT NULL,	--/ <column unit="deg">Polar angle of the weigted center of the group</column>
	[Polar_Radius] real NOT NULL,	--/ <column unit="R_Sol">Polar radius of the weigted center of the group</column>
	[B_U] real NULL,				--/ <column></column>
	[B_P] real NULL,				--/ <column></column>
	[CX] real NOT NULL,				--/ <column>Cartesian X coordinate computed from lat and lon</column>
	[CY] real NOT NULL,				--/ <column>Cartesian Y coordinate computed from lat and lon</column>
	[CZ] real NOT NULL,				--/ <column>Cartesian Z coordinate computed from lat and lon</column>
	[HtmID] bigint,					--/ <column>HTM ID computed from lat and lon</column>

	CONSTRAINT [PK_Group] PRIMARY KEY CLUSTERED 
	(
		[GroupID],
		[GroupRev],
		[FrameID]
	)  ON [PRIMARY]
) ON [PRIMARY]

GO

IF OBJECT_ID (N'Spot', N'U') IS NOT NULL
DROP TABLE [Spot]

CREATE TABLE [Spot]
(
--/ <summary>Contains info on individual spots</summary>
--/ <remarks></remarks>
	[FrameID] bigint NOT NULL,		--/ <column>Reference to the frame</column>
	[Time] datetime2 NOT NULL,		--/ <column>Time of observation (UTC)</column>
	[JD] float NOT NULL,			--/ <column>Julian Date of observation</column>
	[GroupID] int NOT NULL,			--/ <column>Reference to the group (NOAA standard)</column>
	[GroupRev] varchar(2) NOT NULL,	--/ <column>Revised group ID extension</column>
	[SpotID] smallint NOT NULL,		--/ <column>Unique number of spot within the group</column>
	[Proj_Area_U] real NULL,		--/ <column unit="">Projected area of the Umbra</column>
	[Proj_Area_UP] real NULL,		--/ <column unit="">Projected area of the Umbra and Penumbra</column>
	[Area_U] real NULL,				--/ <column unit="">Corrected area of the Umbra</column>
	[Area_UP] real NULL,			--/ <column unit="">Corrected area of the Umbra and Penumbra</column>
	[Lat] real NOT NULL,			--/ <column unit="deg">Carrington latitude of the center of the spot</column>
	[Lon] real NOT NULL,			--/ <column unit="deg">Carrington longitude of the center of the spot</column>
	[LCM] real NOT NULL,			--/ <column unit="deg">Distance in longitude from the central meridian</column>
	[Polar_Angle] real NOT NULL,	--/ <column unit="deg">Projected polar angle of the center of the spot</column>
	[Polar_Radius] real NOT NULL,	--/ <column unit="R_Sol">Projected polar radius of the center of the spot</column>
	[B_U] real NULL,				--/ <column unit="">Magnetic field in the Umbra</column>
	[B_P] real NULL,				--/ <column unit="">Magnetic field in the Umbra and Penumbra</column>
	[CX] real NOT NULL,				--/ <column>Cartesian X coordinate computed from lat and lon</column>
	[CY] real NOT NULL,				--/ <column>Cartesian Y coordinate computed from lat and lon</column>
	[CZ] real NOT NULL,				--/ <column>Cartesian Z coordinate computed from lat and lon</column>
	[HtmID] bigint,					--/ <column>HTM ID computed from lat and lon</column>

	CONSTRAINT [PK_Spot] PRIMARY KEY CLUSTERED 
	(
		[FrameID],
		[GroupID],
		[GroupRev],
		[SpotID]
	)  ON [PRIMARY]
) ON [PRIMARY]


