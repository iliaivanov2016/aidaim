#exec
drop table test1;
#exec
create table test1 (id AutoInc, d Date);
#exec
insert into test1 (d) values (ToDate('01.01.2003', 'DD.MM.YYYY'));
#exec
insert into test1 (d) values (ToDate('02.01.2003', 'DD.MM.YYYY'));
#exec
insert into test1 (d) values (ToDate('03.01.2003', 'DD.MM.YYYY'));
#exec
insert into test1 (d) values (ToDate('04.01.2003', 'DD.MM.YYYY'));
select d,id from test1 where d > ToDate('02.01.2003', 'DD.MM.YYYY') order by d;
#DBISAM
#exec
drop table if exists test1
#exec
create table test1 (id AutoInc, d Date);
#exec
insert into test1 (d) values ('2003-01-01');
#exec
insert into test1 (d) values ('2003-01-02');
#exec
insert into test1 (d) values ('2003-01-03');
#exec
insert into test1 (d) values ('2003-01-04');
select d,id from test1 where d > '2003-01-02' order by d

