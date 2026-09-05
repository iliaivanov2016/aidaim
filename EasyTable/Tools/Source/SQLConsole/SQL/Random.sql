drop table memory test1;
create table memory test1 (id AutoInc, num Integer);
insert into memory test1 (num) values (5);
insert into memory test1 (num) values (7);
insert into memory test1 (num) values (5);
insert into memory test1 (num) values (4);
select test1.*, RAND(100000) as rnd from memory test1 order by num desc,id
