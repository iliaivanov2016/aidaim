#exec
create table memory test1(
Backup                          integer not null,
FileNo                          integer not null,
Generation                      integer,
Status                          smallint,
FileSize                        largeint,
primary key (Backup,FileNo)
);
#exec
create index idx1 on memory test1(FileNo);
#exec
INSERT INTO memory test1 (Backup,FileNo) VALUES (1,1);
#exec
INSERT INTO memory test1 (Backup,FileNo) VALUES (1,2);
#exec
UPDATE memory test1 SET Generation = 100, Status = 200, FileSize = 300 WHERE (Backup = 1) and (FileNo = 1);
#exec
UPDATE memory test1 SET Generation = 100, Status = 200, FileSize = 300 WHERE (FileNo = 1)  and (Backup = 1);
SELECT * FROM memory test1 order by Backup,FileNo;
#dbisam 
#exec
DROP TABLE if exists "\MEMORY\test1";
#exec
create table "\memory\test1"(
Backup                          integer not null,
FileNo                          integer not null,
Generation                      integer,
Status                          smallint,
FileSize                        largeint,
primary key (Backup,FileNo)
);
#exec
create index idx1 on "\memory\test1"(FileNo);
#exec
INSERT INTO "\memory\test1" (Backup,FileNo) VALUES (1,1);
#exec
INSERT INTO "\memory\test1" (Backup,FileNo) VALUES (1,2);
#exec
UPDATE "\memory\test1" SET Generation = 100, Status = 200, FileSize = 300 WHERE (Backup = 1) and (FileNo = 1);
#exec
UPDATE "\memory\test1" SET Generation = 100, Status = 200, FileSize = 300 WHERE (FileNo = 1) and (Backup = 1);
SELECT * FROM "\memory\test1" order by Backup,FileNo;
