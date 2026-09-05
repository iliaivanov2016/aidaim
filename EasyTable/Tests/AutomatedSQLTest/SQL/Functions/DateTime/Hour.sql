#exec
DROP TABLE MEMORY Tmp;
#exec
CREATE TABLE MEMORY Tmp (id autoinc, dt DateTime);
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/14/2006 23:59:35.159','MM/DD/YYYY HH24:NN:SS.ZZZ'));
select id,HOUR(dt) f1 FROM MEMORY Tmp order by id;
#dbisam 
#exec
DROP TABLE if exists "\MEMORY\Tmp";
#exec
CREATE TABLE "\MEMORY\Tmp" (id autoinc, f1 integer);
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES(23);
SELECT id,f1 FROM "\MEMORY\Tmp" order by id;