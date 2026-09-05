#exec
drop table test1;
#exec
create table test1 (float1 FLOAT);
#exec
insert into test1  values (123.455);
#exec
insert into test1  values (213.674);
#exec
insert into test1  values (0.01);
select float1, TRUNCATE(float1) as float_val1, TRUNC(float1,1) as float_val2, TRUNC(float1,2) as float_val3 from test1 order by float1;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (float1 FLOAT, float_val1 INTEGER, float_val2 FLOAT, float_val3 FLOAT);
#exec
insert into test1  values (123.455, 123, 123.4, 123.45);
#exec
insert into test1  values (213.674, 213, 213.6, 213.67);
#exec
insert into test1  values (0.01, 0, 0, 0.01);
select * from test1 order by float1;
