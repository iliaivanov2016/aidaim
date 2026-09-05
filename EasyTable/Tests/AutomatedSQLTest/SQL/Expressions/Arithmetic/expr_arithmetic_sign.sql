#exec
drop table test1;
#exec
create table test1 (int1 INTEGER, float1 FLOAT);
#exec
insert into test1  values (-10, -123.45);
#exec
insert into test1  values (11, 213.67);
#exec
insert into test1  values (0, 0.0);
select int1, float1, sign(int1) as int_val, sign(float1) as float_Val from test1 order by int1;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (int1 INTEGER, float1 FLOAT, int_val INTEGER, float_val INTEGER);
#exec
insert into test1  values (-10, -123.45, -1, -1);
#exec
insert into test1  values (11, 213.67, 1, 1);
#exec
insert into test1  values (0, 0.0, 0 , 0);
select * from test1 order by int1;
