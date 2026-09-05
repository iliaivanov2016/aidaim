#exec
drop table test1;
#exec
create table test1 (int1 INTEGER, float1 FLOAT);
#exec
insert into test1  values (-10, -123.45);
#exec
insert into test1  values (11, 213.67);
#exec
insert into test1  values (0, 0);
select FLOOR(int1) as int_val, FLOOR(float1) as float_Val from test1 order by int_val;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (int1 INTEGER, float1 FLOAT);
#exec
insert into test1  values (-10, -123.45);
#exec
insert into test1  values (11, 213.67);
#exec
insert into test1  values (0, 0);
select FLOOR(int1) as int_val, FLOOR(float1) as float_val from test1 order by int_val;
