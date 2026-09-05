#exec
drop table test1;
#exec
create table test1 (id AutoInc, num Integer);
#exec
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (7);
#exec
insert into test1 (num) values (4);
#exec
create unique index test1_id on test1(num desc);
#try
#exec
insert into test1 (num) values (5);
#exec
drop index test1.test1_id;
#exec
insert into test1 (num) values (5);
select num from test1 order by id
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (id AutoInc, num Integer);
#exec
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (7);
#exec
insert into test1 (num) values (4);
#exec
create unique index test1_id on test1(num);
#try
#exec
insert into test1 (num) values (5);
#exec
drop index  test1.test1_id;
#exec
insert into test1 (num) values (5);
select num from test1
