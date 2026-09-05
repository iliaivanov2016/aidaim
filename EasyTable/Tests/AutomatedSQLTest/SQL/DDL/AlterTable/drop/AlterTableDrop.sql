#exec
drop table test;
#exec
create table test (
    id AutoInc,
    s String(10),
    z word
);
#exec
alter table test drop (z);
#exec
insert into test (s) values('a');
select * from test order by s
#DBISAM
#exec
drop table if exists test
#exec
create table test (id Integer, s varchar(100));
#exec
insert into test (id, s) values(1, 'a');
select * from test order by s

