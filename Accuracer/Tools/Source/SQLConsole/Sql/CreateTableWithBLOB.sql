drop table test;
create table test (
    id AutoIncByte,
    s String(100),
    b blob blobblocksize 1024 blobcompressionmode 5 BLOBCOMPRESSIONAlgorithm BZip,
    m memo
);
select * from test;
