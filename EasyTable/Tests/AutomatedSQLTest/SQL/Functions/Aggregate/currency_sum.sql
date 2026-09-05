#exec
drop table test1;
#exec
create table test1 (id AutoInc, cur Currency);
#exec
insert into test1 (cur) values (12.51);
#exec
insert into test1 (cur) values (12.5);
select SUM(cur) as c from test1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (id AutoInc, cur Float);
#exec
insert into test1 (cur) values (12.51);
#exec
insert into test1 (cur) values (12.5);
select SUM(cur) as c from test1;
