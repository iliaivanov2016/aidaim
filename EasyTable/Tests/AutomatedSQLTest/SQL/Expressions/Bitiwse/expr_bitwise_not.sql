#exec
drop table test1;
#exec
create table test1 (int1 WORD);
#exec
insert into test1  values (16);
#exec
insert into test1  values (0);
select int1, (!int1) as int2, (~ int1) as int3, (~int1) as int4 from test1 order by int1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (int1 WORD, int2 BOOLEAN, int3 WORD, int4 WORD);
#exec
insert into test1  values (16,FALSE,65519,65519);
#exec
insert into test1  values (0,TRUE,65535,65535);
select int1,int2, int3, int4 from test1 order by int1;