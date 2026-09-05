#exec
DROP TABLE MEMORY temp1;
#exec
CREATE TABLE MEMORY temp1 (num Integer, str char(20));
#exec
INSERT INTO MEMORY temp1 values(1,'bbb');
#exec
INSERT INTO MEMORY temp1 values(3,'bbb');
#exec
INSERT INTO MEMORY temp1 values(2,'bbb');
#exec
DROP TABLE MEMORY temp2;
#exec
CREATE TABLE MEMORY temp2 (num Integer, str char(20));
#exec
INSERT INTO MEMORY temp2 values(4,'aaa');
#exec
INSERT INTO MEMORY temp2 values(5,'aaa');
#exec
INSERT INTO MEMORY temp2 values(6,'aaa');
SELECT num,str FROM MEMORY temp1
UNION ALL 
SELECT num,NULL FROM MEMORY temp2;
#DBISAM
#exec
DROP TABLE IF EXISTS "\MEMORY\temp1" ;
#exec
CREATE TABLE "\MEMORY\temp1" (num Integer, str char(20));
#exec
INSERT INTO "\MEMORY\temp1" values(1,'bbb');
#exec
INSERT INTO "\MEMORY\temp1" values(3,'bbb');
#exec
INSERT INTO "\MEMORY\temp1" values(2,'bbb');
#exec
INSERT INTO "\MEMORY\temp1" values(4,NULL);
#exec
INSERT INTO "\MEMORY\temp1" values(5,NULL);
#exec
INSERT INTO "\MEMORY\temp1" values(6,NULL);
SELECT num,str FROM "\MEMORY\temp1";