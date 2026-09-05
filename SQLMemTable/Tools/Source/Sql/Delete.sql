drop table test2;
create table Test2 (
id Autoinc,
Name String(100)
);

INSERT INTO Test2 (Name) VALUES ('Bill');
INSERT INTO Test2 (Name) VALUES ('William');

DELETE FROM Test2 WHERE Name='Bill';

select * from Test2;