#exec
drop table test1;
#exec
create table test1 (str CHAR(20));
#exec
insert into test1  values ("test");
#exec
insert into test1  values (':test1');
#exec
insert into test1  values (":test2");
select * from test1 order by str;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (str CHAR(20));
#exec
insert into test1  values ('test');
#exec
insert into test1  values (':test1');
#exec
insert into test1  values (':test2');
select * from test1 order by str;
