drop table test1;
create table test1 (id AutoInc,
                    num Integer,
		    str	varchar(100));
insert into test1 (num, str) values (5,'aaa');
insert into test1 (num) values (7);
insert into test1 (num, str) values (5,'bbb');
insert into test1 (num, str) values (4,'test');
SELECT ISNULL(str,'No Text') FROM test1;