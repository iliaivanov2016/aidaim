DROP TABLE customers CASCADE;
CREATE TABLE customers (
	ID  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE NOMAXVALUE NOCYCLED),
	Name WIDECHAR (50),
	Mail WIDECHAR (50),
PRIMARY KEY PK (ID)
);
INSERT INTO customers VALUES (
	1,
	'Mark Johnson',
	'mark_johnson@aol.com'
);
INSERT INTO customers VALUES (
	2,
	'Alex Stone',
	'alex.stone@aol.com'
);
INSERT INTO customers VALUES (
	3,
	'Ann Swensson',
	'ann.swenson@yahoo.com'
);

DROP TABLE products CASCADE;
CREATE TABLE products (
	ID  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE NOMAXVALUE NOCYCLED),
	Name WIDECHAR (30),
	Version FLOAT,
PRIMARY KEY PK (ID)
);
INSERT INTO products VALUES (
	1,
	'EasyTable',
	6.4
);
INSERT INTO products VALUES (
	2,
	'Single File System',
	2.7
);
INSERT INTO products VALUES (
	3,
	'SQLMemTable',
	4.2
);
INSERT INTO products VALUES (
	4,
	'Accuracer',
	5.1
);
INSERT INTO products VALUES (
	5,
	'CryptoPressStream',
	2
);
INSERT INTO products VALUES (
	6,
	'MsgCommunicator',
	4.1
);

DROP TABLE orders CASCADE;
CREATE TABLE orders (
	ID  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE NOMAXVALUE NOCYCLED),
	CustomerID INTEGER,
	ProductID INTEGER,
	Date DATETIME,
	Price FLOAT,
	Qty UNSIGNEDINT8,
PRIMARY KEY PK (ID)
);
INSERT INTO orders VALUES (
	1,
	1,
	1,
	TODATE('12/23/2009 15:46:35:234','M/D/YYYY H24:N:S:Z'),
	50,
	2
);
INSERT INTO orders VALUES (
	2,
	2,
	2,
	TODATE('12/25/2009 14:0:0:0','M/D/YYYY H24:N:S:Z'),
	300,
	1
);
INSERT INTO orders VALUES (
	3,
	2,
	4,
	TODATE('12/25/2009 14:0:0:0','M/D/YYYY H24:N:S:Z'),
	600,
	1
);
INSERT INTO orders VALUES (
	4,
	3,
	5,
	TODATE('1/15/2010 11:0:0:0','M/D/YYYY H24:N:S:Z'),
	250,
	1
);
INSERT INTO orders VALUES (
	5,
	3,
	4,
	TODATE('1/15/2010 11:0:0:0','M/D/YYYY H24:N:S:Z'),
	350,
	1
);

