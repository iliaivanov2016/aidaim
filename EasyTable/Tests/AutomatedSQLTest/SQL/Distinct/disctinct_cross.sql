#exec
drop table test1;
#exec
create table test1 (id Integer,
                    num Integer,
                    str varchar(100));
#exec
insert into test1 (id, num, str) values (6,5,'aaa');
#exec
insert into test1 (id, num) values (2,7);
#exec
insert into test1 (id, num, str) values (5,5,'bbb');
#exec
insert into test1 (id, num, str) values (2,4,'test');
#exec
drop table test2;
#exec
create table test2 (id Integer,
                    num Integer,
                    str varchar(100));
#exec
insert into test2 (id, num, str) values (6,5,'aaa');
#exec
insert into test2 (id, num) values (2,7);
#exec
insert into test2 (id, num, str) values (5,55,'bbb');
#exec
insert into test2 (id, num, str) values (2,44,'test');
SELECT DISTINCT T2.NUM n2, T1.NUM n1 FROM TEST1 T1, TEST2 T2 ORDER BY n2,n1;
#DBISAM
#exec
drop table if exists test1;
#exec
create table test1 (id LargeInt,
                    num Integer,
                    str char(100));
#exec
insert into test1 (id,num, str) values (6,5,'aaa');
#exec
insert into test1 (id,num) values (2,7);
#exec
insert into test1 (id,num, str) values (5,5,'bbb');
#exec
insert into test1 (id,num, str) values (2,4,'test');
#exec
drop table if exists test2;
#exec
create table test2 (id LargeInt,
                    num Integer,
                    str char(100));
#exec
insert into test2 (id,num, str) values (6,5,'aaa');
#exec
insert into test2 (id,num) values (2,7);
#exec
insert into test2 (id,num, str) values (5,55,'bbb');
#exec
insert into test2 (id,num, str) values (2,44,'test');
SELECT DISTINCT T2.NUM n2, T1.NUM n1 FROM TEST1 T1, TEST2 T2 ORDER BY n2,n1;
