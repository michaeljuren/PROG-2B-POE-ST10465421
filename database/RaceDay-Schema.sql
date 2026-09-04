/* ================================================================
   RaceDay Database Schema
   South African road running / walking / cycling event platform
   ----------------------------------------------------------------
   How to run this script in SSMS:
     1. Open SQL Server Management Studio and connect to a SQL
        Server instance (local, LocalDB, or a Docker container).
     2. File > Open > File... and select this script.
     3. Press F5 (or click Execute) to run the whole script.
   The script drops and recreates a database called RaceDayDB,
   creates all tables with their constraints, and inserts a small
   set of representative seed data.
   ================================================================ */

IF DB_ID(N'RaceDayDB') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

/* ================================================================
   TABLES
   ================================================================ */

/* ----------------------------------------------------------------
   1. Roles - lookup of the roles a user account can hold
   ---------------------------------------------------------------- */
CREATE TABLE Roles (
    RoleId   INT IDENTITY(1,1) NOT NULL,
    RoleName NVARCHAR(20)      NOT NULL,
    CONSTRAINT PK_Roles PRIMARY KEY (RoleId),
    CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName)
);
GO

/* ----------------------------------------------------------------
   2. Clubs - athletics/cycling clubs participants may belong to
   ---------------------------------------------------------------- */
CREATE TABLE Clubs (
    ClubId            INT IDENTITY(1,1) NOT NULL,
    ClubName          NVARCHAR(150)     NOT NULL,
    Province          NVARCHAR(20)      NOT NULL,
    AffiliationNumber NVARCHAR(30)      NULL,
    ContactEmail      NVARCHAR(255)     NULL,
    CONSTRAINT PK_Clubs PRIMARY KEY (ClubId),
    CONSTRAINT UQ_Clubs_ClubName UNIQUE (ClubName),
    CONSTRAINT CHK_Clubs_Province CHECK (Province IN (
        N'Eastern Cape', N'Free State', N'Gauteng', N'KwaZulu-Natal',
        N'Limpopo', N'Mpumalanga', N'North West', N'Northern Cape', N'Western Cape'))
);
GO

/* ----------------------------------------------------------------
   3. Users - every account: admins, organizers and participants
   ---------------------------------------------------------------- */
CREATE TABLE Users (
    UserId                INT IDENTITY(1,1) NOT NULL,
    FirstName             NVARCHAR(100)     NOT NULL,
    LastName              NVARCHAR(100)     NOT NULL,
    Email                 NVARCHAR(255)     NOT NULL,
    PasswordHash          NVARCHAR(255)     NOT NULL,
    PhoneNumber           NVARCHAR(20)      NULL,
    DateOfBirth           DATE              NOT NULL,
    Gender                NVARCHAR(10)      NOT NULL,
    ClubId                INT               NULL,
    EmergencyContactName  NVARCHAR(100)     NULL,
    EmergencyContactPhone NVARCHAR(20)      NULL,
    CreatedAt             DATETIME2         NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    IsActive              BIT               NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CHK_Users_Gender CHECK (Gender IN (N'Male', N'Female', N'Other')),
    CONSTRAINT FK_Users_Clubs FOREIGN KEY (ClubId) REFERENCES Clubs(ClubId) ON DELETE SET NULL
);
GO

/* ----------------------------------------------------------------
   4. UserRoles - many-to-many: a user can be Organizer and
      Participant at the same time
   ---------------------------------------------------------------- */
CREATE TABLE UserRoles (
    UserId INT NOT NULL,
    RoleId INT NOT NULL,
    CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId) ON DELETE CASCADE
);
GO

/* ----------------------------------------------------------------
   5. Venues - physical locations events are held at
   ---------------------------------------------------------------- */
CREATE TABLE Venues (
    VenueId     INT IDENTITY(1,1) NOT NULL,
    VenueName   NVARCHAR(150)     NOT NULL,
    AddressLine NVARCHAR(200)     NULL,
    City        NVARCHAR(100)     NOT NULL,
    Province    NVARCHAR(20)      NOT NULL,
    PostalCode  NVARCHAR(10)      NULL,
    Latitude    DECIMAL(9,6)      NULL,
    Longitude   DECIMAL(9,6)      NULL,
    CONSTRAINT PK_Venues PRIMARY KEY (VenueId),
    CONSTRAINT CHK_Venues_Province CHECK (Province IN (
        N'Eastern Cape', N'Free State', N'Gauteng', N'KwaZulu-Natal',
        N'Limpopo', N'Mpumalanga', N'North West', N'Northern Cape', N'Western Cape'))
);
GO

/* ----------------------------------------------------------------
   6. Routes - a specific course at a venue (distance, elevation,
      map) that one or more categories can be run/ridden on
   ---------------------------------------------------------------- */
CREATE TABLE Routes (
    RouteId               INT IDENTITY(1,1) NOT NULL,
    VenueId               INT               NOT NULL,
    RouteName             NVARCHAR(150)     NOT NULL,
    DistanceKm            DECIMAL(6,2)      NOT NULL,
    ElevationGainM        INT               NULL,
    MapUrl                NVARCHAR(500)     NULL,
    StartPointDescription NVARCHAR(255)     NULL,
    EndPointDescription   NVARCHAR(255)     NULL,
    CONSTRAINT PK_Routes PRIMARY KEY (RouteId),
    CONSTRAINT FK_Routes_Venues FOREIGN KEY (VenueId) REFERENCES Venues(VenueId),
    CONSTRAINT CHK_Routes_DistanceKm CHECK (DistanceKm > 0),
    CONSTRAINT CHK_Routes_ElevationGainM CHECK (ElevationGainM IS NULL OR ElevationGainM >= 0)
);
GO

/* ----------------------------------------------------------------
   7. Events - a race day, created and managed by an organizer
   ---------------------------------------------------------------- */
CREATE TABLE Events (
    EventId               INT IDENTITY(1,1) NOT NULL,
    OrganizerId           INT               NOT NULL,
    VenueId               INT               NOT NULL,
    EventName             NVARCHAR(150)     NOT NULL,
    Description           NVARCHAR(MAX)     NULL,
    Discipline            NVARCHAR(20)      NOT NULL,
    EventDate             DATE              NOT NULL,
    StartTime             TIME(0)           NOT NULL,
    RegistrationOpenDate  DATETIME2         NOT NULL,
    RegistrationCloseDate DATETIME2         NOT NULL,
    Status                NVARCHAR(20)      NOT NULL CONSTRAINT DF_Events_Status DEFAULT (N'Draft'),
    BannerImageUrl        NVARCHAR(500)     NULL,
    CreatedAt             DATETIME2         NOT NULL CONSTRAINT DF_Events_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt             DATETIME2         NOT NULL CONSTRAINT DF_Events_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Events PRIMARY KEY (EventId),
    CONSTRAINT FK_Events_Users_Organizer FOREIGN KEY (OrganizerId) REFERENCES Users(UserId),
    CONSTRAINT FK_Events_Venues FOREIGN KEY (VenueId) REFERENCES Venues(VenueId),
    CONSTRAINT CHK_Events_Discipline CHECK (Discipline IN (N'Running', N'Walking', N'Cycling', N'Multisport')),
    CONSTRAINT CHK_Events_Status CHECK (Status IN (N'Draft', N'Published', N'Cancelled', N'Completed')),
    CONSTRAINT CHK_Events_RegDates CHECK (RegistrationOpenDate < RegistrationCloseDate)
);
GO

/* ----------------------------------------------------------------
   8. Categories - a distance/class within an event, e.g. "10km
      Individual" or "21.1km Half Marathon"
   ---------------------------------------------------------------- */
CREATE TABLE Categories (
    CategoryId        INT IDENTITY(1,1) NOT NULL,
    EventId           INT               NOT NULL,
    RouteId           INT               NULL,
    CategoryName      NVARCHAR(100)     NOT NULL,
    DistanceKm        DECIMAL(6,2)      NOT NULL,
    MinAge            INT               NULL,
    GenderRestriction NVARCHAR(10)      NOT NULL CONSTRAINT DF_Categories_GenderRestriction DEFAULT (N'Open'),
    EntryFee          DECIMAL(8,2)      NOT NULL CONSTRAINT DF_Categories_EntryFee DEFAULT (0),
    MaxParticipants   INT               NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryId),
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventId) REFERENCES Events(EventId) ON DELETE CASCADE,
    CONSTRAINT FK_Categories_Routes FOREIGN KEY (RouteId) REFERENCES Routes(RouteId) ON DELETE SET NULL,
    CONSTRAINT UQ_Categories_Event_Name UNIQUE (EventId, CategoryName),
    CONSTRAINT CHK_Categories_DistanceKm CHECK (DistanceKm > 0),
    CONSTRAINT CHK_Categories_MinAge CHECK (MinAge IS NULL OR MinAge >= 0),
    CONSTRAINT CHK_Categories_GenderRestriction CHECK (GenderRestriction IN (N'Open', N'Male', N'Female')),
    CONSTRAINT CHK_Categories_EntryFee CHECK (EntryFee >= 0),
    CONSTRAINT CHK_Categories_MaxParticipants CHECK (MaxParticipants IS NULL OR MaxParticipants > 0)
);
GO

/* ----------------------------------------------------------------
   9. Entries - a participant registering for a category
   ---------------------------------------------------------------- */
CREATE TABLE Entries (
    EntryId       INT IDENTITY(1,1) NOT NULL,
    CategoryId    INT               NOT NULL,
    ParticipantId INT               NOT NULL,
    BibNumber     NVARCHAR(10)      NULL,
    EntryDate     DATETIME2         NOT NULL CONSTRAINT DF_Entries_EntryDate DEFAULT (SYSUTCDATETIME()),
    Status        NVARCHAR(20)      NOT NULL CONSTRAINT DF_Entries_Status DEFAULT (N'Pending'),
    AmountPaid    DECIMAL(8,2)      NOT NULL CONSTRAINT DF_Entries_AmountPaid DEFAULT (0),
    PaymentStatus NVARCHAR(10)      NOT NULL CONSTRAINT DF_Entries_PaymentStatus DEFAULT (N'Unpaid'),
    CONSTRAINT PK_Entries PRIMARY KEY (EntryId),
    CONSTRAINT FK_Entries_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId) ON DELETE CASCADE,
    CONSTRAINT FK_Entries_Users_Participant FOREIGN KEY (ParticipantId) REFERENCES Users(UserId),
    CONSTRAINT UQ_Entries_Category_Participant UNIQUE (CategoryId, ParticipantId),
    CONSTRAINT CHK_Entries_Status CHECK (Status IN (N'Pending', N'Confirmed', N'Cancelled', N'Withdrawn')),
    CONSTRAINT CHK_Entries_AmountPaid CHECK (AmountPaid >= 0),
    CONSTRAINT CHK_Entries_PaymentStatus CHECK (PaymentStatus IN (N'Unpaid', N'Paid', N'Refunded'))
);
GO

/* ----------------------------------------------------------------
   10. Results - the outcome recorded against a single entry
   ---------------------------------------------------------------- */
CREATE TABLE Results (
    ResultId         INT IDENTITY(1,1) NOT NULL,
    EntryId          INT               NOT NULL,
    FinishTime       TIME(3)           NULL,
    GunTime          TIME(3)           NULL,
    ChipTime         TIME(3)           NULL,
    OverallPosition  INT               NULL,
    CategoryPosition INT               NULL,
    GenderPosition   INT               NULL,
    FinishStatus     NVARCHAR(10)      NOT NULL CONSTRAINT DF_Results_FinishStatus DEFAULT (N'Finished'),
    RecordedByUserId INT               NULL,
    RecordedAt       DATETIME2         NOT NULL CONSTRAINT DF_Results_RecordedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Results PRIMARY KEY (ResultId),
    CONSTRAINT FK_Results_Entries FOREIGN KEY (EntryId) REFERENCES Entries(EntryId) ON DELETE CASCADE,
    CONSTRAINT FK_Results_Users_RecordedBy FOREIGN KEY (RecordedByUserId) REFERENCES Users(UserId) ON DELETE SET NULL,
    CONSTRAINT UQ_Results_EntryId UNIQUE (EntryId),
    CONSTRAINT CHK_Results_OverallPosition CHECK (OverallPosition IS NULL OR OverallPosition > 0),
    CONSTRAINT CHK_Results_CategoryPosition CHECK (CategoryPosition IS NULL OR CategoryPosition > 0),
    CONSTRAINT CHK_Results_GenderPosition CHECK (GenderPosition IS NULL OR GenderPosition > 0),
    CONSTRAINT CHK_Results_FinishStatus CHECK (FinishStatus IN (N'Finished', N'DNF', N'DNS', N'DSQ'))
);
GO

/* ----------------------------------------------------------------
   Indexes on foreign key columns (PKs/UNIQUE constraints already
   create their own indexes, so those FK columns are excluded)
   ---------------------------------------------------------------- */
CREATE INDEX IX_Users_ClubId ON Users(ClubId);
CREATE INDEX IX_Events_OrganizerId ON Events(OrganizerId);
CREATE INDEX IX_Events_VenueId ON Events(VenueId);
CREATE INDEX IX_Routes_VenueId ON Routes(VenueId);
CREATE INDEX IX_Categories_EventId ON Categories(EventId);
CREATE INDEX IX_Categories_RouteId ON Categories(RouteId);
CREATE INDEX IX_Entries_ParticipantId ON Entries(ParticipantId);
CREATE INDEX IX_Results_RecordedByUserId ON Results(RecordedByUserId);
GO

/* ================================================================
   SEED DATA
   Inserted in dependency order into a freshly created database, so
   IDENTITY values are predictable and referenced directly below.
   PasswordHash values are placeholders only - the real application
   must hash passwords (e.g. ASP.NET Core Identity's PBKDF2 hasher)
   and never store plain text or fake-looking hashes as real ones.
   ================================================================ */

-- Roles: 1=Admin, 2=Organizer, 3=Participant
INSERT INTO Roles (RoleName) VALUES
    (N'Admin'),
    (N'Organizer'),
    (N'Participant');
GO

-- Clubs: 1=Bay Athletic Club, 2=Randburg Harriers, 3=Stellenbosch Long Runners
INSERT INTO Clubs (ClubName, Province, AffiliationNumber, ContactEmail) VALUES
    (N'Bay Athletic Club', N'Eastern Cape', N'EP-0142', N'info@bayac.co.za'),
    (N'Randburg Harriers', N'Gauteng', N'GA-0871', N'info@randburgharriers.co.za'),
    (N'Stellenbosch Long Runners', N'Western Cape', N'WP-0356', N'info@stellenboschlr.co.za');
GO

-- Users: 1=Admin, 2=Sarah (organizer), 3=Thabo (organizer),
--        4=Lindiwe (participant), 5=Johan (participant),
--        6=Aisha (organizer + participant)
INSERT INTO Users (FirstName, LastName, Email, PasswordHash, PhoneNumber, DateOfBirth, Gender, ClubId, EmergencyContactName, EmergencyContactPhone) VALUES
    (N'Admin',   N'User',           N'admin@raceday.co.za',      N'PLACEHOLDER_HASH_NOT_REAL', N'0110000000', '1990-01-01', N'Other',  NULL, NULL,                  NULL),
    (N'Sarah',   N'van der Merwe',  N'sarah.vdm@raceday.co.za',  N'PLACEHOLDER_HASH_NOT_REAL', N'0721234567', '1985-03-14', N'Female', NULL, N'Pieter van der Merwe', N'0721234500'),
    (N'Thabo',   N'Nkosi',          N'thabo.nkosi@raceday.co.za',N'PLACEHOLDER_HASH_NOT_REAL', N'0731234567', '1988-07-22', N'Male',   NULL, N'Nomsa Nkosi',         N'0731234500'),
    (N'Lindiwe', N'Dlamini',        N'lindiwe.d@example.co.za',  N'PLACEHOLDER_HASH_NOT_REAL', N'0741234567', '1994-11-02', N'Female', 2,    N'Sipho Dlamini',       N'0741234500'),
    (N'Johan',   N'Botha',          N'johan.botha@example.co.za',N'PLACEHOLDER_HASH_NOT_REAL', N'0761234567', '1990-05-30', N'Male',   3,    N'Marie Botha',         N'0761234500'),
    (N'Aisha',   N'Patel',          N'aisha.patel@example.co.za',N'PLACEHOLDER_HASH_NOT_REAL', N'0781234567', '1992-09-18', N'Female', 1,    N'Farida Patel',        N'0781234500');
GO

-- UserRoles
INSERT INTO UserRoles (UserId, RoleId) VALUES
    (1, 1), -- Admin -> Admin
    (2, 2), -- Sarah -> Organizer
    (3, 2), -- Thabo -> Organizer
    (4, 3), -- Lindiwe -> Participant
    (5, 3), -- Johan -> Participant
    (6, 2), -- Aisha -> Organizer
    (6, 3); -- Aisha -> Participant
GO

-- Venues: 1=Green Point Park, 2=Zwartkops Raceway Grounds, 3=Durban Beachfront Promenade
INSERT INTO Venues (VenueName, AddressLine, City, Province, PostalCode, Latitude, Longitude) VALUES
    (N'Green Point Park',            N'Fritz Sonnenberg Rd',  N'Cape Town', N'Western Cape',  N'8005', -33.902800, 18.406500),
    (N'Zwartkops Raceway Grounds',   N'Rabie Ring Rd',        N'Centurion', N'Gauteng',       N'0157', -25.845400, 28.187900),
    (N'Durban Beachfront Promenade', N'Snell Parade',         N'Durban',    N'KwaZulu-Natal', N'4001', -29.837500, 31.043600);
GO

-- Routes: 1,2 at Green Point (Venue 1), 3 at Zwartkops (Venue 2), 4 at Durban (Venue 3)
INSERT INTO Routes (VenueId, RouteName, DistanceKm, ElevationGainM, MapUrl, StartPointDescription, EndPointDescription) VALUES
    (1, N'Green Point Loop 10km',            10.00, 45,  N'https://maps.example.com/routes/green-point-10k',  N'Green Point Park main gate',   N'Green Point Park main gate'),
    (1, N'Green Point Double Loop 21.1km',   21.10, 90,  N'https://maps.example.com/routes/green-point-21k',  N'Green Point Park main gate',   N'Green Point Park main gate'),
    (2, N'Centurion Cycle Circuit 40km',     40.00, 220, N'https://maps.example.com/routes/centurion-40k',    N'Zwartkops Raceway pit lane',   N'Zwartkops Raceway pit lane'),
    (3, N'Durban Beachfront 5km Route',       5.00, 10,  N'https://maps.example.com/routes/durban-beach-5k',  N'uShaka Marine World',          N'Suncoast Casino');
GO

-- Events: 1=Cape Town Peninsula Marathon (Sarah), 2=Centurion Cycle Classic (Thabo),
--         3=Durban Beachfront Fun Run (Aisha, still a Draft)
INSERT INTO Events (OrganizerId, VenueId, EventName, Description, Discipline, EventDate, StartTime, RegistrationOpenDate, RegistrationCloseDate, Status) VALUES
    (2, 1, N'Cape Town Peninsula Marathon', N'An annual road running event through Cape Town''s Atlantic seaboard.', N'Running', '2026-04-19', '06:00:00', '2026-01-05T00:00:00', '2026-04-10T23:59:59', N'Published'),
    (3, 2, N'Centurion Cycle Classic',      N'A closed-circuit road cycling race at the Zwartkops Raceway grounds.', N'Cycling', '2026-05-10', '07:00:00', '2026-01-15T00:00:00', '2026-05-01T23:59:59', N'Published'),
    (6, 3, N'Durban Beachfront Fun Run',    N'A family-friendly 5km fun run along the Durban promenade.',           N'Running', '2026-03-22', '06:30:00', '2026-01-20T00:00:00', '2026-03-15T23:59:59', N'Draft');
GO

-- Categories: 1,2 under Event 1, 3 under Event 2, 4 under Event 3
INSERT INTO Categories (EventId, RouteId, CategoryName, DistanceKm, MinAge, GenderRestriction, EntryFee, MaxParticipants) VALUES
    (1, 1, N'10km Individual',        10.00, 12,  N'Open', 150.00, 3000),
    (1, 2, N'21.1km Half Marathon',   21.10, 16,  N'Open', 250.00, 2000),
    (2, 3, N'40km Road Race',         40.00, 18,  N'Open', 300.00, 500),
    (3, 4, N'5km Fun Run',             5.00, NULL,N'Open',  80.00, 1000);
GO

-- Entries: Lindiwe in the half marathon and the cycle race, Johan in the 10km, Aisha in the cycle race
INSERT INTO Entries (CategoryId, ParticipantId, BibNumber, Status, AmountPaid, PaymentStatus) VALUES
    (2, 4, N'1042', N'Confirmed', 250.00, N'Paid'),
    (1, 5, N'2031', N'Confirmed', 150.00, N'Paid'),
    (3, 6, NULL,    N'Pending',     0.00, N'Unpaid'),
    (3, 4, N'305',  N'Confirmed', 300.00, N'Paid');
GO

-- Results: recorded for Lindiwe's half marathon entry and Johan's 10km entry
INSERT INTO Results (EntryId, FinishTime, GunTime, ChipTime, OverallPosition, CategoryPosition, GenderPosition, FinishStatus, RecordedByUserId) VALUES
    (1, '01:52:34.000', '01:53:10.000', '01:52:34.000', 15, 3, 2, N'Finished', 2),
    (2, '00:48:10.000', '00:48:40.000', '00:48:10.000', 22, 8, 6, N'Finished', 2);
GO
