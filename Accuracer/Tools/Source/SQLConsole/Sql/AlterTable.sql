drop table test1;
create table test1 (id AutoInc, num Integer);
insert into test1 (num) values (5);
insert into test1 (num) values (7);
insert into test1 (num) values (5);
insert into test1 (num) values (4);
alter table test1 add (num2 Integer);
select * from test1 order by num desc,id;
