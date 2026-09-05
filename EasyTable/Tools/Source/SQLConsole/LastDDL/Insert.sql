create table Test2 (
id Autoinc,
Name String(100),
password '1'
);

INSERT INTO Test2 password '1' (Name) 
VALUES ('Bill');

INSERT INTO Test2 password '1' (Name, ID) 
VALUES ('Jon', 99);

INSERT INTO Test2 password '1' VALUES ('Paul', 101);

alter table Test2 MODIFY (Password '1', New Password '');

INSERT INTO Test2 (Name) VALUES ('No Password Inserted');
