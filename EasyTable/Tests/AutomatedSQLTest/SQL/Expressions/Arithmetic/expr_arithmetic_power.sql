#exec
drop table test1;
#exec
create table test1 (int1 LargeInt, int2 Integer, float1 FLOAT);
#exec
insert into test1  values (-10, 12, -0.1);
#exec
insert into test1  values (7, 12, -0.000015);
#exec
insert into test1  values (2, 16, 0.15);
#exec
insert into test1  values (-9, 7, -1.5);
#exec
insert into test1  values (0, 2, -0.0);
select int1, int2, float1, POWER(int1,int2) as exp1, POW(float1,int2) as exp2 from test1 order by int1;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (int1 LargeInt, int2 Integer, float1 FLOAT);
#exec
insert into test1  values (-10, 12, -0.1);
#exec
insert into test1  values (7, 12, -0.000015);
#exec
insert into test1  values (2, 16, 0.15);
#exec
insert into test1  values (-9, 7, -1.5);
#exec
insert into test1  values (0, 2, -0.0);
select int1, int2, float1, POWER(int1,int2) as exp1, POWER(float1,int2) as exp2 from test1 order by int1;
