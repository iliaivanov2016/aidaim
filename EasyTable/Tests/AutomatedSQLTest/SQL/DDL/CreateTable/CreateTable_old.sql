#exec
drop table test1;
#exec
create table test1 (id AutoInc, num Integer);
#exec
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (7);
#exec
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (4);
select num,id from test1 order by id /*num desc,id*/
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
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (4);
select num,id from test1 order by id /*num desc,id*/
