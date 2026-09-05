#exec
DROP TABLE MEMORY temp1;
#exec
CREATE TABLE MEMORY temp1 (num Integer);
#exec
INSERT INTO MEMORY temp1 values(1);
#exec
INSERT INTO MEMORY temp1 values(3);
#exec
INSERT INTO MEMORY temp1 values(2);
#exec
DROP TABLE MEMORY temp2;
#exec
CREATE TABLE MEMORY temp2 (num Integer);
#exec
INSERT INTO MEMORY temp2 values(0);
#exec
INSERT INTO MEMORY temp2 values(3);
#exec
INSERT INTO MEMORY temp2 values(2);
SELECT * FROM MEMORY temp1
UNION ALL 
SELECT * FROM MEMORY temp2;
#DBISAM
#exec
DROP TABLE IF EXISTS "\MEMORY\temp1" ;
#exec
CREATE TABLE "\MEMORY\temp1" (num Integer);
#exec
INSERT INTO "\MEMORY\temp1" values(1);
#exec
INSERT INTO "\MEMORY\temp1" values(3);
#exec
INSERT INTO "\MEMORY\temp1" values(2);
#exec
INSERT INTO "\MEMORY\temp1" values(0);
#exec
INSERT INTO "\MEMORY\temp1" values(3);
#exec
INSERT INTO "\MEMORY\temp1" values(2);
SELECT * FROM "\MEMORY\temp1";