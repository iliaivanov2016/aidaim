DROP TABLE coders CASCADE;

CREATE TABLE coders (
	ID INTEGER,
	FIRST_NAME CHAR (20),
	LAST_NAME CHAR (20),
	EXPERIENCE FLOAT,
	SALARY INTEGER,
	JOINED TIMESTAMP,
PRIMARY KEY C_PK$ID1751736934_1448 (ID)
);
INSERT INTO coders VALUES (
	1,
	'John',
	'Connor',
	2,
	30000,
	TODATE('6/5/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	2,
	'Dave',
	'Rogerson',
	5,
	32000,
	TODATE('9/15/2001 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	3,
	'Mark',
	'Barrel',
	4.5,
	34000,
	TODATE('5/25/2002 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	4,
	'Nick',
	'Carlson',
	1.25,
	36000,
	TODATE('11/30/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	5,
	'John',
	'Smith',
	10,
	38000,
	TODATE('2/15/1998 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	6,
	'Luke',
	'Skywalker',
	0.5,
	40000,
	TODATE('2/1/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	7,
	'Bred',
	'Canvus',
	3.3,
	42000,
	TODATE('4/9/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	8,
	'Arthur',
	'Clark',
	4,
	44000,
	TODATE('5/25/2002 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	9,
	'Jimmy',
	'Toron',
	1,
	46000,
	TODATE('4/6/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO coders VALUES (
	10,
	'Ford',
	'Smith',
	2,
	48000,
	TODATE('7/18/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);

DROP TABLE projects CASCADE;

CREATE TABLE projects (
	ID INTEGER,
	CAPTION CHAR (20),
	LEADER_ID INTEGER,
	CODERS CHAR (40),
	COST FLOAT,
	DEADLINE TIMESTAMP,
PRIMARY KEY C_PK$ID118018805_1448 (ID)
);
INSERT INTO projects VALUES (
	1,
	'Engine core',
	5,
	'Dave Rogerson, Mark Barrel',
	200,
	TODATE('10/15/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	2,
	'Core patch #1',
	5,
	'Dave Rogerson',
	50,
	TODATE('11/15/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	3,
	'Audio plugin',
	2,
	'John Connor',
	100,
	TODATE('12/10/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	4,
	'Core patch #2',
	5,
	'Mark Barrel',
	25,
	TODATE('12/5/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	5,
	'Video plugin',
	10,
	'Nick Carlson',
	120,
	TODATE('12/20/2003 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	6,
	'Core patch #3',
	5,
	NULL,
	12.25,
	TODATE('1/13/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	7,
	'Skins support',
	6,
	'Luke Skywalker',
	20,
	TODATE('2/10/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	8,
	'OS integration',
	8,
	'Bred Canvus',
	50.5,
	TODATE('2/10/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	9,
	'Core patch #4',
	2,
	'Jimmy Toron, John Connor',
	10,
	TODATE('2/12/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
INSERT INTO projects VALUES (
	10,
	'*nix implementation',
	3,
	'Ford Smith',
	200,
	TODATE('11/11/2004 0:0:0:0','M/D/YYYY H24:N:S:Z')
);
