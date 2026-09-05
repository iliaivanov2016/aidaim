#exec
drop table test1;
#exec
create table test1 (int1 INTEGER, int2 INTEGER);
#exec
insert into test1  values (-10, 3);
#exec
insert into test1  values (11, 2);
#exec
insert into test1  values (0, 1);
#exec
insert into test1  values (-20, 1);
#exec
insert into test1  values (30, 30);
#exec
insert into test1  values (124594300, 10);
#exec
insert into test1  values (12459430, 7);
#exec
insert into test1  values (2, 3);
select int1 as i1,int2 as i2,mod(int1,int2) as int_val, int1 % int2 as int_Val2, int1 MOD int2 as int_Val3 from test1 order by int1;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (i1 INTEGER, i2 INTEGER, i3 INTEGER);
#exec
insert into test1  values (-10, 3, -1);
#exec
insert into test1  values (11, 2, 1);
#exec
insert into test1  values (0, 1, 0);
#exec
insert into test1  values (-20, 1, 0);
#exec
insert into test1  values (30, 30, 0);
#exec
insert into test1  values (124594300, 10, 0);
#exec
insert into test1  values (12459430, 7, 4);
#exec
insert into test1  values (2, 3, 2);
select i1,i2,i3 as int_val, i3 as int_val2, i3 as int_Val3 from test1 order by i1;
