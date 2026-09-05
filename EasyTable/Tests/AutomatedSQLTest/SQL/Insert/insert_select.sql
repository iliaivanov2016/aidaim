#exec
drop table insert_test;
#exec
create table insert_test (id AutoInc, num Integer);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (7);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (4);
#exec
insert into insert_test (num) select num from insert_test;
select num,id from insert_test order by num desc,id
#DBISAM
#exec
drop table if exists insert_test
#exec
create table insert_test (id AutoInc, num Integer);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (7);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (4);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (7);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (4);
select num,id from insert_test order by num desc,id
