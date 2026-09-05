#exec
drop table test1;
#exec
create table test1 (int1 INTEGER, int2 INTEGER);
#exec
insert into test1  values (16,1 << 4);
#exec
insert into test1  values (8,1 SHL 3);
#exec
insert into test1  values (4,16 SHR 2);
#exec
insert into test1  values (1,2 >> 1);
select int1, int2 from test1 order by int1, int2;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (int1 INTEGER, int2 INTEGER);
#exec
insert into test1  values (16,16);
#exec
insert into test1  values (8,8);
#exec
insert into test1  values (4,4);
#exec
insert into test1  values (1,1);
select int1, int2 from test1 order by int1, int2;
