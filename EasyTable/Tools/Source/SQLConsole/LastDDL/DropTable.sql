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
,LastAutoIncValue 1000
);

DROP TABLE Test;
