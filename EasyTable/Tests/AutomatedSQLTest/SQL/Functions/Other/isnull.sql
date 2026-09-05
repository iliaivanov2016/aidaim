#exec
DROP TABLE MEMORY Tmp;
#exec
CREATE TABLE MEMORY Tmp (num Integer);
#exec
INSERT INTO MEMORY Tmp VALUES(1);
#exec
INSERT INTO MEMORY Tmp VALUES(NULL);
select IsNull(num) f1,num FROM MEMORY Tmp order by num;
#dbisam 
#exec
DROP TABLE if exists "\MEMORY\Tmp";
#exec
CREATE TABLE "\MEMORY\Tmp" (f1 Boolean, num Integer);
#exec
INSERT INTO "\MEMORY\Tmp" VALUES(True,NULL);
#exec
INSERT INTO "\MEMORY\Tmp" VALUES(False,1);
SELECT f1,num FROM "\MEMORY\Tmp" order by num;