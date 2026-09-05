#exec
drop table test;
#exec
create table test (
id AutoInc,
fn string(20),
ln string(20),
Adr string(20),
a2 string(20),
a3 string(20),
a4 string(20),
p1 string(20),
p2 logical,
i integer );
#exec
insert into test (adr) values('zzz');
#exec
insert into test (adr) values('zzz');
#exec
update test set Adr = 'a1' where Id = 2;
select * from test order by id;
#DBISAM
#exec
drop table if exists test;
#exec
create table test (
id AutoInc,
fn varchar(20),
ln varchar(20),
Adr varchar(20),
a2 varchar(20),
a3 varchar(20),
a4 varchar(20),
p1 varchar(20),
p2 boolean,
i integer );
#exec
insert into test (adr) values('zzz');
#exec
insert into test (adr) values('zzz');
#exec
update test set Adr = 'a1' where Id = 2;
select * from test order by id;