#exec
DROP TABLE MEMORY gb_test1;
#exec
create table memory gb_test1 (id AutoInc, num Integer, num1 Integer);
#exec
insert into memory gb_test1(id,num,num1) values (1,0,0);
#exec
insert into memory gb_test1(id,num,num1) values (2,1,0);
#exec
insert into memory gb_test1(id,num,num1) values (3,0,1);
#exec
insert into memory gb_test1(id,num,num1) values (4,0,1);
#exec
insert into memory gb_test1(id,num,num1) values (5,1,1);
#exec
insert into memory gb_test1(id,num,num1) values (6,1,2);
#exec
insert into memory gb_test1(id,num,num1) values (7,2,2);
select num,count(num1) total from MEMORY gb_test1 group by num order by num
#DBISAM
#exec
drop table if exists "\memory\gb_test1";
#exec
create table "\memory\gb_test1" (id AutoInc, num Integer, num1 Integer);
#exec
insert into "\memory\gb_test1"(id,num,num1) values (1,0,0);
#exec
insert into "\memory\gb_test1" (id,num,num1) values (2,1,0);
#exec
insert into "\memory\gb_test1" (id,num,num1) values (3,0,1);
#exec
insert into "\memory\gb_test1" (id,num,num1) values (4,0,1);
#exec
insert into "\memory\gb_test1" (id,num,num1) values (5,1,1);
#exec
insert into "\memory\gb_test1" (id,num,num1) values (6,1,2);
#exec
insert into "\memory\gb_test1" (id,num,num1) values (7,2,2);
select num,count(num1) total from "\memory\gb_test1" group by num order by num
