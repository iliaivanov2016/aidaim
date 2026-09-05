drop table Test2;
create table Test2 (
id Autoinc,
Name String(100)
);

INSERT INTO Test2 (Name) VALUES ('Bill');

UPDATE Test2 SET Name = 'New Name' WHERE ID = 1;

UPDATE Test2 SET Name = 'New Name 2' WHERE Name='New Name';
