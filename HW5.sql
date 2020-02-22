/*HW5*/

--1
SELECT OwnerUserName.Name, RoleOwners.Name, RoleOwners.RoleDescription FROM OwnerUserName
	INNER JOIN RoleOwners ON (OwnerUserName.idRole = RoleOwners.id)

--2
--As query(doesn't work)
SELECT Guests.Name, Classes.Name, Levels.idClass, COUNT(Levels.idGuest) FROM Levels
	INNER JOIN Guests ON (Levels.idGuest = Guests.id)
	INNER JOIN Classes ON (Levels.idClass = Classes.id)
		--WHERE idClass IN (SELECT COUNT(Levels.idGuest) FROM Levels GROUP BY idClass)
			GROUP BY Guests.Name, Classes.Name, Levels.idClass

SELECT * FROM Classes
--SELECT * FROM Levels

--As function(does work)
IF OBJECT_ID (N'dbo.TotalGuestsPerClass', N'FN') IS NOT NULL  
    DROP FUNCTION dbo.TotalGuestsPerClass;  
GO  
CREATE FUNCTION dbo.TotalGuestsPerClass (@Guests int)
RETURNS int
AS  
BEGIN
	DECLARE @TotalGuestsPerClass int
	SELECT @TotalGuestsPerClass = COUNT(Levels.idClass)
    FROM Levels
	WHERE @Guests = Levels.idClass
		IF (@TotalGuestsPerClass IS NULL)   
			SET @TotalGuestsPerClass = 0;    
    RETURN @TotalGuestsPerClass;  
END;
GO
--How can I get the idClass's column to collapse on duplicates?
SELECT Levels.idGuest, Guests.Name, Classes.Name, Levels.idClass, dbo.TotalGuestsPerClass(idClass) AS TotalGuestsPerClass FROM Levels
	INNER JOIN Guests ON (Levels.idGuest = Guests.id)
	INNER JOIN Classes ON (Levels.idClass = Classes.id)
		GROUP BY Levels.idGuest, Levels.idClass, Guests.Name, Classes.Name, dbo.TotalGuestsPerClass(idClass)

SELECT * FROM LEVELS

--3
SELECT idGuest, Guests.Name, idClass, Classes.Name, Level,
	CASE WHEN Level BETWEEN 1 and 10 THEN 'Noob'
		 WHEN Level BETWEEN 11 and 20 THEN 'Intermediate'
		 WHEN Level BETWEEN 21 and 30 THEN 'Pro'
		 WHEN Level BETWEEN 31 and 40 THEN 'Expert'
		 WHEN Level BETWEEN 41 and 50 THEN 'Master'
END AS Brackets FROM Levels 
	INNER JOIN Guests ON (Levels.idGuest = Guests.id)
	INNER JOIN Classes ON (Levels.idClass = Classes.id)
		ORDER BY Guests.Name asc;

--4
GO
IF OBJECT_ID (N'dbo.GetBrackets', N'FN') IS NOT NULL  
    DROP FUNCTION dbo.GetBrackets;  
GO  
CREATE FUNCTION dbo.GetBrackets (@level int)  
RETURNS varchar(50)  
AS    
BEGIN
DECLARE @ret int;
	DECLARE @label varchar(50);  
SELECT @ret = (@level)   
    IF (@ret < 10)
		SET @label = 'Noob';
	IF (@ret BETWEEN 10 AND 19)
		SET @label = 'Intermediate';
	IF (@ret BETWEEN 20 AND 29)
		SET @label = 'Pro';
	IF (@ret BETWEEN 30 AND 39)
		SET @label = 'Expert';
	IF (@ret >= 40)
		SET @label = 'Master';
RETURN @label;
END;

GO

SELECT idGuest, Guests.Name, idClass, Classes.Name, Level, dbo.GetBrackets(Level) AS LevelBrackets FROM Levels
	INNER JOIN Guests ON (Levels.idGuest = Guests.id)
	INNER JOIN Classes ON (Levels.idClass = Classes.id)
		ORDER BY Guests.Name asc;
	
--5
GO
IF OBJECT_ID (N'dbo.RoomOpen', N'IF') IS NOT NULL
	DROP FUNCTION dbo.RoomOpen;
GO 
CREATE FUNCTION dbo.RoomOpen (@vacant date)
RETURNS TABLE 
AS
RETURN
(
	SELECT R.Number, T.Name, R.idTavern, R.id AS idRoom
	FROM Stays AS S
		INNER JOIN Rooms AS R ON R.id = S.idRoom
		INNER JOIN Taverns AS T ON T.id = R.idTavern
	WHERE @vacant NOT BETWEEN S.CheckedIn AND S.Checkedout
);
GO
SELECT * FROM dbo.RoomOpen('12/19/2019')

--6
GO
IF OBJECT_ID (N'dbo.PriceRange', N'IF') IS NOT NULL
	DROP FUNCTION dbo.PriceRange;
GO 
CREATE FUNCTION dbo.PriceRange (@min DECIMAL(5,2), @max DECIMAL(5,2))
RETURNS TABLE
AS
RETURN
(
	SELECT R.Number, T.Name, R.idTavern, R.id, R.Cost
	FROM Rooms AS R
		INNER JOIN Stays AS S ON R.id = S.idRoom
		INNER JOIN Taverns AS T ON T.id = R.idTavern
	WHERE R.Cost BETWEEN @min AND @max
);
GO
SELECT * FROM dbo.PriceRange(80, 130)

--7
IF OBJECT_ID (N'dbo.CreateARoom', N'P') IS NOT NULL  
    DROP PROCEDURE dbo.CreateARoom;
GO
CREATE PROCEDURE dbo.CreateARoom
	@cost DECIMAL(5,2),
	@tavernsname varchar(50),
	@tavernid int,
	@newtavernid int
AS
SET @cost = (SELECT MIN(Cost) FROM dbo.PriceRange(80, 130));
SET @tavernsname = (SELECT TOP 1 Name FROM dbo.PriceRange(80, 130) AS NewRoom
	WHERE Cost = (
        SELECT MIN(Cost)
        FROM dbo.PriceRange(80, 130)));
SET @tavernid = (SELECT id FROM Taverns WHERE @tavernsname = Name);
	IF (@tavernid = (Select COUNT(*) FROM Taverns))
			BEGIN
			SET @newtavernid = (@tavernid - (@tavernid - 1));
			END   
			ELSE 
			BEGIN 
			SET @newTavernid = (@tavernid + 1);
			END
/*Can't get INSERT to work. Error message says "Must declare the scalar variable '@cost'" when I'm pretty sure
  It's declared...*/
INSERT INTO Rooms (Cost, idTavern)
	VALUES
		((@cost - 0.01), @newtavernid);

SELECT * FROM Rooms;