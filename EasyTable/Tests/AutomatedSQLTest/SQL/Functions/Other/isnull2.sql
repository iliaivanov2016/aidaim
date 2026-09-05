#exec
DROP TABLE MEMORY Tmp;
#exec
CREATE TABLE MEMORY Tmp (num Integer, num2 float);
#exec
INSERT INTO MEMORY Tmp VALUES(1,1.5);
#exec
INSERT INTO MEMORY Tmp VALUES(NULL,3);
#exec
INSERT INTO MEMORY Tmp VALUES(2,NULL);
select IsNull(num*num2) f1,num FROM MEMORY Tmp WHERE ISNULL(num*num2) order by num;
#dbisam 
#exec
DROP TABLE if exists "\MEMORY\Tmp";
#exec
CREATE TABLE "\MEMORY\Tmp" (f1 Boolean, num Integer);
#exec
INSERT INTO "\MEMORY\Tmp" VALUES(True,NULL);
#exec
INSERT INTO "\MEMORY\Tmp" VALUES(True,2);
SELECT f1,num FROM "\MEMORY\Tmp" order by num;