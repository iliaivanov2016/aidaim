#exec
drop table memory test1;
#exec
create table memory test1 (state char(20));
#exec
insert into memory test1 (state) values ('AZ');
#exec
insert into memory test1 (state) values ('CA');
#exec
insert into memory test1 (state) values ('CA');
#exec
insert into memory test1 (state) values ('CA');
#exec
insert into memory test1 (state) values ('CA');
select distinct state from memory test1 order by state;
#DBISAM
#exec
drop table if exists "\memory\test1";
#exec
create table "\memory\test1" (state char(20));
#exec
insert into "\memory\test1" (state) values ('AZ');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
insert into "\memory\test1" (state) values ('CA');
#exec
insert into "\memory\test1" (state) values ('CA');
select distinct state from "\memory\test1" order by state;
