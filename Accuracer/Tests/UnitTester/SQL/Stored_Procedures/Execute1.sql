-----------------------------------------------------------------------------------------------------------------------------------------
-- create table `TestExecute1` and insert record with values aId, aName 
-----------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE Execute1(aId: Integer; aName: Char);
BEGIN
	DROP TABLE TestExecute1;
	CREATE TABLE TestExecute1 (ID INTEGER, NAME CHAR(20), PRIMARY KEY(ID)) COMMENT "The table created by Stored Procedure Execute1";
	START TRANSACTION;
	INSERT INTO TestExecute1 VALUES(aId,aName);
	COMMIT;
END;
