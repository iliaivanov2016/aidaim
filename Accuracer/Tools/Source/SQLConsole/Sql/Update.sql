drop table test1;
create table test1 (id AutoInc, num Integer, str Varchar(20));
insert into test1 (num) values (5);
insert into test1 (num) values (7);
insert into test1 (num) values (5);
insert into test1 (num, str) values (4, 'test');
update test1 set str = 'blank' where str is null;
select * from test1 order by num desc,id
