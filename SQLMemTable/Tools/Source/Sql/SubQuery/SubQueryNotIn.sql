drop table test1;
create table test1 (id AutoInc(LargeInt, INITIALVALUE 3, INCREMENT 3, MAXVALUE 7 minvalue 2 CYCLED),
                    num Integer,
		    str	varchar(100));
insert into test1 (num, str) values (5,'aaa');
insert into test1 (num) values (7);
insert into test1 (num, str) values (5,'bbb');
insert into test1 (num, str) values (4,'test');
SELECT * FROM test1
WHERE num NOT IN 
 (SELECT DISTINCT num FROM test1 WHERE (str <> 'test'))
 ORDER BY num;