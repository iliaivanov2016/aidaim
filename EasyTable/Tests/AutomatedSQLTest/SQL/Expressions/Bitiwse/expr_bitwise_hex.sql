#exec
drop table test1;
#exec
create table test1 (int1 SmallInt, int2 SmallInt);
#exec
insert into test1  values (0xff,$ff);
#exec
insert into test1  values (0x00,$0f);
#exec
insert into test1  values (0x01,$002);
#exec
insert into test1  values (0x03,$0002);
select int1, int2, int1 XOR int2 as int3, int2 ^ int1 as int4, 
HEX(int1 XOR int2) as str1, HEX(int2 ^ int1,1) as str2, HEX(int2 ^ int1,2) as str3
from test1 order by int1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (int1 SmallInt, int2 SmallInt, int3 SmallInt, str1 CHAR(4), str2 CHAR(5), str3 CHAR(6));
#exec
insert into test1  values (255,255,0,'0000','$0000','0x0000');
#exec
insert into test1  values (0,15,15,'000F','$000F','0x000f');
#exec
insert into test1  values (1,2,3,'0003','$0003','0x0003');
#exec
insert into test1  values (3,2,1,'0001','$0001','0x0001');
select int1,int2,int3, int3 as int4,str1,str2,str3 from test1 order by int1;
