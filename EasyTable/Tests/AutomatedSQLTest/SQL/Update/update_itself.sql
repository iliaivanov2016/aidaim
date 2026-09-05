#exec
drop table test1;
#exec
create table test1 (i integer);
#exec
insert into test1(i) values(1);
#exec
insert into test1(i) values(2);
#exec
insert into test1(i) values(1);
#exec
update test1 set i=5 where i=1;
select i from test1 order by i;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (i integer);
#exec
insert into test1(i) values(1);
#exec
insert into test1(i) values(2);
#exec
insert into test1(i) values(1);
#exec
update test1 set i=5 where i=1;
select i from test1 order by i;
