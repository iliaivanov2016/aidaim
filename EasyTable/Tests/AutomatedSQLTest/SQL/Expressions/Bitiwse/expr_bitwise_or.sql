#exec
drop table test1;
#exec
create table test1 (int1 WORD, int2 WORD);
#exec
insert into test1  values (16,16);
#exec
insert into test1  values (8,4);
#exec
insert into test1  values (2,3);
#exec
insert into test1  values (32,0);
select int1, int2, (int1 | int2) as int3, (int2 | int1) as int4 from test1 order by int1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (int1 WORD, int2 WORD, int3 WORD);
#exec
insert into test1  values (16,16,16);
#exec
insert into test1  values (8,4,12);
#exec
insert into test1  values (2,3,3);
#exec
insert into test1  values (32,0,32);
select int1,int2, int3, int3 as int4 from test1 order by int1;