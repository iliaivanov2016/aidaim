#exec
DROP TABLE MEMORY Tmp;
#exec
CREATE TABLE MEMORY Tmp (id autoinc, dt DateTime);
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/14/2006','MM/DD/YYYY'));
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/15/2006','MM/DD/YYYY'));
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/16/2006','MM/DD/YYYY'));
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/17/2006','MM/DD/YYYY'));
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/18/2006','MM/DD/YYYY'));
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/19/2006','MM/DD/YYYY'));
#exec
INSERT INTO MEMORY Tmp(dt) VALUES(TODATE('08/20/2006','MM/DD/YYYY'));
select id,DAYNAME(dt) f1 FROM MEMORY Tmp order by id;
#dbisam 
#exec
DROP TABLE if exists "\MEMORY\Tmp";
#exec
CREATE TABLE "\MEMORY\Tmp" (id autoinc, f1 char(9));
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Monday');
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Tuesday');
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Wednesday');
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Thursday');
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Friday');
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Saturday');
#exec
INSERT INTO "\MEMORY\Tmp"(f1) VALUES('Sunday');
SELECT id,f1 FROM "\MEMORY\Tmp" order by id;