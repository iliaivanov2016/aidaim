#exec
drop table test1;
#exec
create table test1 (id AutoInc, int Integer, sm SmallInt, w Word, li LargeInt, f Float, b Boolean, cur Currency, d Date, t Time, dt DateTime, s String(20), ws WideString(40));
#exec
insert into test1 (int) values (2334);
#exec
insert into test1 (int) values (-3452334);
select id, CAST([int], string) expr from test1 order by id;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (id AutoInc, int Integer, sm SmallInt, w Word, li LargeInt, f Float, b Boolean, cur Float, d Date, t Time, dt TimeStamp, s varchar(20), ws varchar(40));
#exec
insert into test1 (int) values (2334);
#exec
insert into test1 (int) values (-3452334);
select id, CAST(int as Char(10)) expr from test1 order by id;
