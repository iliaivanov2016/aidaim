SELECT UPPER(FString) as FS, FInteger INTO MEMORY tmp FROM jt1 order by FS asc;
#exec
insert into MEMORY tmp  (FS, FInteger) values ('AAA', -13);
#exec
update MEMORY tmp set FS='BBB' where FInteger=-13;
select * from MEMORY tmp  order by fs, FInteger;
#DBISAM
SELECT UPPER(FString) as FS, FInteger INTO "\MEMORY\tmp" FROM jt1 order by FS asc;
#exec
insert into "\MEMORY\tmp"  (FS, FInteger) values ('AAA', -13);
#exec
update "\MEMORY\tmp" set FS='BBB' where FInteger=-13;
select * from "\MEMORY\tmp" order by fs, FInteger;