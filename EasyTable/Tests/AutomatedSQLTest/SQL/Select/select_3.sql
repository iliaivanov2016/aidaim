#exec
drop table memory test1;
#exec
create table memory test1 (id AutoInc, num Integer);
#exec
insert into memory test1 (num) values (5);
#exec
insert into memory test1 (num) values (7);
#exec
insert into memory test1 (num) values (5);
#exec
insert into memory test1 (num) values (4);
select num from memory test1 where num >= 5 order by num; 
#DBISAM
#exec
drop table if exists "\memory\test1";
#exec
create table "\memory\test1" (id AutoInc, num Integer);
#exec
insert into "\memory\test1" (num) values (5);
#exec
insert into "\memory\test1" (num) values (7);
#exec
insert into "\memory\test1" (num) values (5);
#exec
insert into "\memory\test1" (num) values (4);
select num from "\memory\test1" where num >= 5 order by num; 
