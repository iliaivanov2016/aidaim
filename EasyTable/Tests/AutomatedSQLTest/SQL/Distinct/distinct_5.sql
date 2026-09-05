#exec
create table memory tdistinct (field1 integer);
#exec
insert into memory tdistinct values(1);
#exec
insert into memory tdistinct values(2);
select FInteger into large_distinct1 from jt1,jt2 ;
select * into large_distinct from large_distinct1,memory tdistinct ;
select distinct FInteger from large_distinct order by FInteger desc
#DBISAM
#exec
drop table if exists "\memory\tdistinct";
#exec
create table "\memory\tdistinct" (field1 integer);
#exec
insert into "\memory\tdistinct" values(1);
#exec
insert into "\memory\tdistinct" values(2);
select FInteger into large_distinct1 from jt1,jt2 ;
select * into large_distinct from large_distinct1,"\memory\tdistinct";
select distinct FInteger from large_distinct order by FInteger desc
