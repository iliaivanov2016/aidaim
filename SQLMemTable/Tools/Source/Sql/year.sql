drop table test1;
create table test1 (
                    id AutoInc,
                    dt DateTime
                   );
insert into test1 (dt) values (TODATE('5/12/2005','MM/DD/YYYY'));
insert into test1 (dt) values (TODATE('10/18/2006','MM/DD/YYYY'));
SELECT YEAR(dt) FROM test1;