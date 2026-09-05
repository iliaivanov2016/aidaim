SELECT UPPER(FString) as FS, FInteger INTO MEMORY tmp FROM jt1 order by FS asc;
#exec
insert into MEMORY tmp  (FS, FInteger) values ('AAA', -13);
#exec
delete from MEMORY tmp where FS='AAA';
select * from MEMORY tmp  order by fs, FInteger;
#DBISAM
SELECT UPPER(FString) as FS, FInteger INTO "\MEMORY\tmp" FROM jt1 order by FS asc;
#exec
insert into "\MEMORY\tmp"  (FS, FInteger) values ('AAA', -13);
#exec
delete from "\MEMORY\tmp" where FS='AAA';
select * from "\MEMORY\tmp" order by fs, FInteger;