#exec
drop table memory test1;
#exec
create table memory test1 (id AutoInc, num Integer);
#exec
create index idx_1 on memory test1 (num);
#exec
drop index memory test1.idx_1 ;
#exec
insert into memory test1 (num) values (5);
#exec
insert into memory test1 (num) values (7);
#exec
insert into memory test1 (num) values (5);
#exec
insert into memory test1 (num) values (4);
select num,id from memory test1 order by id /*num desc,id*/
#DBISAM
#exec
drop table if exists "\memory\test1";
#exec
create table "\memory\test1" (id AutoInc, num Integer);
#exec
create index idx_1 on "\memory\test1" (num);
#exec
drop index "\memory\test1".idx_1;
#exec
insert into "\memory\test1" (num) values (5);
#exec
insert into "\memory\test1" (num) values (7);
#exec
insert into "\memory\test1" (num) values (5);
#exec
insert into "\memory\test1" (num) values (4);
select num,id from "\memory\test1" order by id /*num desc,id*/
