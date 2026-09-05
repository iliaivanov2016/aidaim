CREATE TABLE Test
(
ID AutoInc
,Text String(500)
,Numeric Float
,Money Currency
,CurrentDate Date
,Picture Graphic
);

insert into Test (text,numeric) values ('text for insert', 233);

CREATE UNIQUE INDEX Text_Index1 ON Test
(
Text DESC NOCASE
,ID
)