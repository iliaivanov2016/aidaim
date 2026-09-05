#exec
drop table test1;
#exec
create table test1 (id AutoInc, int Integer, sm SmallInt, w Word, li LargeInt, f Float, b Boolean, cur Currency, d Date, t Time, dt DateTime, s String(20), ws WideString(40));
#exec
insert into test1 (s, ws) values ('string1', 'widestring1');
#exec
insert into test1 (s, ws) values ('string2', 13);
select * from test1 where ws like '%w%' order by id;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (id AutoInc, int Integer, sm SmallInt, w Word, li LargeInt, f Float, b Boolean, cur Float, d Date, t Time, dt TimeStamp, s varchar(20), ws varchar(40));
#exec
insert into test1 (s, ws) values ('string1', 'widestring1');
#exec
insert into test1 (s, ws) values ('string2', '13');
select * from test1 where ws like '%w%' order by id;
