SELECT UPPER(FString) as FS, FInteger INTO MEMORY tmp FROM jt1 order by FS asc;
select * from MEMORY tmp  order by FS asc
#DBISAM
SELECT UPPER(FString) as FS, FInteger INTO "MEMORY\tmp" FROM jt1 order by FS asc;
select * from "\MEMORY\tmp" order by FS asc