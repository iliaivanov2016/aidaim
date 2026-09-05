#exec
drop table insert_test1;
#exec
create table insert_test1 (id AutoInc, num Integer, bool_field Logical);
#exec
insert into insert_test1 (num,bool_field) values (5,True);
#exec
insert into insert_test1 (num,bool_field) values (7,False);
#exec
insert into insert_test1 (num,bool_field) values (1,Null);
#exec
update insert_test1 set bool_field = Null where num = 5;
select id,num,bool_field from insert_test1 order by bool_field desc,id
#DBISAM
#exec
drop table if exists insert_test1
#exec
create table insert_test1 (id AutoInc, num Integer, bool_field Boolean);
#exec
insert into insert_test1 (num,bool_field) values (5,True);
#exec
insert into insert_test1 (num,bool_field) values (7,False);
#exec
insert into insert_test1 (num,bool_field) values (1,Null);
#exec
update insert_test1 set bool_field = Null where num = 5;
select id,num,bool_field from insert_test1 order by bool_field desc,id
