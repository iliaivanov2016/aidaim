CREATE TABLE Test
(
ID AutoInc
,Text String(500)
,Numeric Float
,Money Currency
,CurrentDate Date
,Picture Graphic
,Password '1'
,BlobCompressionLevel Fastest
,BlobBlockSize 1024
,LastAutoInc 1000
);

insert into Test password '1' (text,numeric) values ('text for insert', 233);

CREATE UNIQUE INDEX Text_Index1 ON Test
(
Text DESC NOCASE
,ID
,Password '1'
);

DROP INDEX Test.Text_Index1 Password '1'