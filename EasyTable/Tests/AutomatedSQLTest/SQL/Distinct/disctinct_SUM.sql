#exec
drop table test1;
#exec
create table test1 (id AutoInc,
                    num Integer);
#exec
insert into test1 (num) values (2);
#exec
insert into test1 (num) values (30);
#exec
insert into test1 (num) values (2);
#exec
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (6);
#exec
insert into test1 (num) values (30);
SELECT SUM(DISTINCT NUM) [sum] FROM TEST1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (id AutoInc,
                    num Integer);
#exec
insert into test1 (num) values (2);
#exec
insert into test1 (num) values (5);
#exec
insert into test1 (num) values (6);
#exec
insert into test1 (num) values (30);
SELECT SUM(NUM) [sum] FROM TEST1;
