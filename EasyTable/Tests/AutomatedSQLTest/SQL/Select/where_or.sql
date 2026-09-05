#exec
drop table memory tperson;
#exec
create table memory tperson (id integer ,name string(50), age integer);
#exec
insert into memory tperson (id, name, age) values(1, 'Jimmy',45);
#exec
insert into memory tperson (id, name, age) values(2, 'John',23);
#exec
insert into memory tperson (id, name, age) values(3, 'Brad',44);
#exec
insert into memory tperson (id, name, age) values(4, 'Morten',19);
#exec
insert into memory tperson (id, name, age) values(5, 'Bob',19);
select id from memory tperson p1 where id = 1 or age = 19 order by id;
#DBISAM
#exec
drop table if exists "\memory\tperson";
#exec
create table "\memory\tperson" (id integer ,name varchar(50), age integer);
#exec
insert into "\memory\tperson" (id, name, age) values(1, 'Jimmy',45);
#exec
insert into "\memory\tperson" (id, name, age) values(2, 'John',23);
#exec
insert into "\memory\tperson" (id, name, age) values(3, 'Brad',44);
#exec
insert into "\memory\tperson" (id, name, age) values(4, 'Morten',19);
#exec
insert into "\memory\tperson" (id, name, age) values(5, 'Bob',19);
select id from "\memory\tperson" p1 where id = 1 or age = 19 order by id;
