DROP TABLE Test;
CREATE TABLE Test (id AutoInc, str CHAR(100) DEFAULT "aaa", num Integer);
INSERT INTO Test(num) VALUES(5);
SELECT * FROM Test;
