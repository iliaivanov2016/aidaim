-- create 2 memory databases MemDB1 and MemDB2 with same table Table1
CREATE DATABASE MEMORY MemDB1;
CREATE TABLE MEMORY MemDB1.Table1(id AutoInc, name char(20), PRIMARY KEY(id));
INSERT INTO MEMORY MemDB1.Table1(name) VALUES ("Leo Martin");
INSERT INTO MEMORY MemDB1.Table1(name) VALUES ("Ray Lahoy");
CREATE DATABASE MEMORY MemDB2;
CREATE TABLE MEMORY MemDB2.Table1(id AutoInc, name char(20), PRIMARY KEY(id));
INSERT INTO MEMORY MemDB2.Table1(name) VALUES ("Ella Perelman");
INSERT INTO MEMORY MemDB2.Table1(name) VALUES ("John Smith");
CREATE TABLE MEMORY MemDB2.Table2(id Integer, name char(20), PRIMARY KEY(id,name));

SELECT * INTO MEMORY MemDB2.Table3
FROM MEMORY MemDB1.Table1 as t11 INNER JOIN 
MEMORY MemDB2.Table1 as t21 ON (t11.id = t21.id)
ORDER BY 2 DESC, 4 DESC;