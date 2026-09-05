drop table test1;
create table test1 (id AutoInc, num Integer, str Varchar(20));
insert into test1 (num) values (5);
insert into test1 (num) values (7);
insert into test1 (num) values (5);
insert into test1 (num, str) values (4, 'test');
drop table test2;
create table test2 (id AutoInc, num Integer, str Varchar(20));
insert into test2 (num) values (5);
insert into test2 (num) values (7);
insert into test2 (num) values (5);
insert into test2 (num, str) values (4, 'test');

select * from test1 join test2 on (test1.id = test2.id) order by num desc,id
