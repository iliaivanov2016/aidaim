DROP TABLE customer_Sort CASCADE;
CREATE TABLE customer_Sort (
	Company CHAR (20),
	Address CHAR (20),
	Phone CHAR (20),
	FAX CHAR (20),
	TaxRate FLOAT,
	LastInvoiceDate DATETIME,
	CustNo  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE NOMAXVALUE NOCYCLED),
PRIMARY KEY PrimaryKey (CustNo)
);
CREATE UNIQUE INDEX @CustNo ON customer_Sort (
	CustNo
);
CREATE INDEX @@Company ON customer_Sort (
	Company NOCASE
);
CREATE INDEX @Company ON customer_Sort (
	Company
);
CREATE INDEX @@Address ON customer_Sort (
	Address NOCASE
);
CREATE INDEX @Address ON customer_Sort (
	Address
);
CREATE INDEX @@Phone ON customer_Sort (
	Phone NOCASE
);
CREATE INDEX @Phone ON customer_Sort (
	Phone
);
CREATE INDEX @@FAX ON customer_Sort (
	FAX NOCASE
);
CREATE INDEX @FAX ON customer_Sort (
	FAX
);
CREATE INDEX @TaxRate ON customer_Sort (
	TaxRate
);
CREATE INDEX @LastInvoiceDate ON customer_Sort (
	LastInvoiceDate
);
CREATE INDEX ByCompanyAsc ON customer_Sort (
	Company NOCASE
);
CREATE INDEX ByCompanyDesc ON customer_Sort (
	Company DESC
);
CREATE INDEX ByAddrAscCompanyDesc ON customer_Sort (
	Address DESC NOCASE,
	Company DESC NOCASE
);
INSERT INTO customer_Sort VALUES (
	'Microsoft',
	'US',
	'100',
	'001',
	10,
	TODATE('2/1/2000 0:0:0:0','M/D/YYYY H24:N:S:Z'),
	1
);
INSERT INTO customer_Sort VALUES (
	'Borland Software',
	'US',
	'001',
	NULL,
	NULL,
	NULL,
	2
);
INSERT INTO customer_Sort VALUES (
	'MicroDyn',
	'GB',
	'999',
	NULL,
	NULL,
	NULL,
	3
);
