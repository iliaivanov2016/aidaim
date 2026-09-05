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
select * from memory test2 FULL JOIN memory test1 ON (test1.state = test2.state) order by id;
#Paradox
#exec
drop table test1;
#exec
drop table test2;
#exec
create table test1 (id autoinc, state char(20));
#exec
insert into test1 (state) values ('AZ');
#exec
insert into test1 (state) values ('CA');
#exec
insert into test1 (state) values ('CA');
#exec
insert into test1 (state) values ('CA');
#exec
insert into test1 (state) values ('CA');
#exec
create table test2 (state char(20));
select * from test2 FULL JOIN test1 ON (test1.state = test2.state) order by id;
