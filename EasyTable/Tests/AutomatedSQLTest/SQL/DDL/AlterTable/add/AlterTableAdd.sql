#exec
drop table test;
#exec
create table test (
    s String(10)
);
#exec
alter table test add (id Autoinc);
#exec
insert into test (s) values('a');
select * from test order by s
#DBISAM
#exec
drop table if exists test
#exec
create table test (id Integer, s varchar(10));
#exec
insert into test (id, s) values(1, 'a');
select * from test order by s

