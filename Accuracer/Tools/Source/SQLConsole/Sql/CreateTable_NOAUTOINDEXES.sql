drop table test2;
create table test2 (id AutoInc, num Integer, noautoindexes);
insert into test2 (num) values (5);
insert into test2 (num) values (7);
insert into test2 (num) values (5);
insert into test2 (num) values (4);
select * from test2 order by num desc,id;
