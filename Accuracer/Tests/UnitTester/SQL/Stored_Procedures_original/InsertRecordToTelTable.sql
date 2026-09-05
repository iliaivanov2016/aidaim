-----------------------------------------------------------------------------------------------------------------------------------------
-- create table `TelTable` and insert record with aName, aTel values if there are no records with name = aName
-----------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE InsertRecordToTelTable(aName,aTel: CHAR(20));
BEGIN
 IF (NOT EXISTS(SELECT * FROM TABLES WHERE [Table Name] = "TelTable")) THEN
  CREATE TABLE TelTable(name Char(20), tel Char(20), PRIMARY KEY (name));
 IF (NOT EXISTS(SELECT * FROM TelTable WHERE name = aName)) THEN
  INSERT INTO TelTable VALUES (aName,aTel);
END;
