#exec
DROP TABLE MEMORY Tmp;
#exec
CREATE TABLE MEMORY Tmp (name char(50));
#exec
INSERT INTO MEMORY Tmp VALUES('John');
#exec
INSERT INTO MEMORY Tmp VALUES(NULL);
#exec
INSERT INTO MEMORY Tmp VALUES('Bob');
select IsNull(name,'Unknown') nm FROM MEMORY Tmp order by nm;
#dbisam 
#exec
DROP TABLE if exists "\MEMORY\Tmp";
#exec
CREATE TABLE "\MEMORY\Tmp" (nm char(50));
#exec
INSERT INTO "\MEMORY\Tmp" VALUES('Bob');
#exec
INSERT INTO "\MEMORY\Tmp" VALUES('John');
#exec
INSERT INTO "\MEMORY\Tmp" VALUES('Unknown');
SELECT * FROM "\MEMORY\Tmp" order by nm;