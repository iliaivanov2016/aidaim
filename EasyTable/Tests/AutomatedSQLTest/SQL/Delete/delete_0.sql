#exec
drop table insert_test;
#exec
create table insert_test (id AutoInc, num Integer);
#exec
insert into insert_test (num) values (3);
#exec
insert into insert_test (num) values (4);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (6);
#exec
delete from insert_test where num=4;
select num,id from insert_test order by num desc,id;
#DBISAM
#exec
drop table if exists insert_test
#exec
create table insert_test (id AutoInc, num Integer);
#exec
insert into insert_test (num) values (3);
#exec
insert into insert_test (num) values (4);
#exec
insert into insert_test (num) values (5);
#exec
insert into insert_test (num) values (6);
#exec
delete from insert_test where num=4;
select num,id from insert_test order by num desc,id;