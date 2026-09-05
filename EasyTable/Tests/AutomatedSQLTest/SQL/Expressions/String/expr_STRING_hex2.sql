#exec
drop table test1;
#exec
create table test1 (str1 char(10));
#exec
insert into test1  values ('a');
#exec
insert into test1  values ('Test!');
#exec
insert into test1  values ('Привет!');
select str1, HEX(str1) as str2, HEX(str1,1) as str3, HEX(str1,2) as str4 from test1 order by str2;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (str1 CHAR(10), str2 CHAR(20), str3 CHAR(21), str4 CHAR(22));
#exec
insert into test1  values ('a','61','$61','0x61');
#exec
insert into test1  values ('Test!','5465737421','$5465737421','0x5465737421');
#exec
insert into test1  values ('Привет!','CFF0E8E2E5F221','$CFF0E8E2E5F221','0xcff0e8e2e5f221');
select * from test1 order by str2;
