CREATE TABLE Test
(
ID AutoInc
,Text String(500)
,Numeric Float
,Money Currency
,CurrentDate Date
,Picture Graphic
,Password '123'
,BlobCompressionLevel Fastest
,BlobBlockSize 1024
,LastAutoIncValue 1000
);

insert into Test password '123' (text,numeric) values ('text for insert', 233);

ALTER TABLE Test MODIFY
(
Text String(300)
,CurrentDate DateTime
,Password '123'
,New Password '1'
,BlobCompressionLevel Max
,BlobBlockSize 128
,LastAutoIncValue 2000
);

ALTER TABLE Test DROP (Numeric, Password '1');

ALTER TABLE Test ADD (UnicodeText WideString(500), Password '1');
