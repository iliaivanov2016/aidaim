#exec
drop table test1;
#exec
create table test1 (i integer, a integer);
#exec
insert into test1(i,a) values(1,2);
#exec
update test1 set i=a+1;
select i from test1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (i integer, a integer);
#exec
insert into test1(i,a) values(1,2);
#exec
update test1 set i=a+1;
select i from test1;
