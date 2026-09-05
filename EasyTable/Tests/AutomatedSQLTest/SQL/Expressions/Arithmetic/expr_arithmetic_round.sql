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
select float1, ROUND(float1) as float_Val1, ROUND(float1,1) as float_Val2, ROUND(float1,2) as float_Val3 from test1 order by float1;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (float1 FLOAT);
#exec
insert into test1  values (123.455);
#exec
insert into test1  values (213.674);
#exec
insert into test1  values (0.01);
select float1, ROUND(float1) as float_Val1, ROUND(float1,1) as float_Val2, ROUND(float1,2) as float_Val3 from test1 order by float1;
