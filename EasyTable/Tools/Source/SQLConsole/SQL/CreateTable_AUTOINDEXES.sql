drop table test1;
create table test1 (id AutoInc, num Integer, autoindexes);
insert into test1 (num) values (5);
insert into test1 (num) values (7);
insert into test1 (num) values (5);
insert into test1 (num) values (4);
select * from test1 order by num desc,id
