drop table insert_test;
create table insert_test (id AutoInc, num Integer);
insert into insert_test (num) values (5);
insert into insert_test (num) values (7);
insert into insert_test (num) values (5);
insert into insert_test (num) values (4);
insert into insert_test (num) select num from insert_test;
select num,id from insert_test order by num desc,id;

