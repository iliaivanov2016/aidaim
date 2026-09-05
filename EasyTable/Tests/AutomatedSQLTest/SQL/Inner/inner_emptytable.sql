#exec
drop table memory test1;
#exec
create table memory test1 (id AutoInc, state char(20));
#exec
insert into memory test1 (state) values ('AZ');
#exec
insert into memory test1 (state) values ('CA');
#exec
insert into memory test1 (state) values ('CA');
#exec
insert into memory test1 (state) values ('CA');
#exec
insert into memory test1 (state) values ('CA');
#exec
drop table memory test2;
#exec
create table memory test2 (state char(20));
select * from memory test1 INNER JOIN memory test2 ON (test1.state = test2.state) order by id;
#DBISAM
#exec
drop table if exists "\memory\test1";
#exec
create table "\memory\test1" (id autoinc, state char(20));
#exec
insert into "\memory\test1" (state) values ('AZ');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
drop table if exists "\memory\test2";
#exec
create table "\memory\test2" (state char(20));
select * from "\memory\test1" INNER JOIN "\memory\test2" ON (test1.state = test2.state) order by id;
