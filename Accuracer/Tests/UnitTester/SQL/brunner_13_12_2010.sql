DROP TABLE EGeschichte CASCADE;

CREATE TABLE EGeschichte (
	ID INTEGER,
	Datum DATETIME,
	Bezeichnung CHAR (30),
	ZusatzText CHAR (30),
	ID_Objekt INTEGER,
	ID_UeberwachungDef INTEGER,
	ID_Leistung INTEGER,
	ID_Aktion INTEGER
);
CREATE UNIQUE INDEX IDX ON EGeschichte (
	ID
);
CREATE INDEX ID_ObjektX ON EGeschichte (
	ID_Objekt
);
DROP TABLE EUeberwachungDef CASCADE;

CREATE TABLE EUeberwachungDef (
	ID INTEGER,
	SeqNr INTEGER,
	Bezeichnung CHAR (30),
	Kuerzel CHAR (6),
	Beschreibung MEMO BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0,
	Aktiv LOGICAL,
	ID_LeistungDef INTEGER,
	DefTurnus INTEGER,
	DefTurnusEinheit INTEGER,
	BaldFaelligTage INTEGER
);
CREATE UNIQUE INDEX IDX ON EUeberwachungDef (
	ID
);
DROP TABLE EUeberwachungen CASCADE;

CREATE TABLE EUeberwachungen (
	ID INTEGER,
	ID_UeberwachungDef INTEGER,
	Aktiv LOGICAL,
	ID_Objekt INTEGER,
	DefaultTurnus LOGICAL,
	Turnus INTEGER,
	TurnusEinheit INTEGER,
	BudgetZeit FLOAT,
	BudgetBetrag FLOAT,
	VertragNr CHAR (12),
	VertragDatumAb DATETIME,
	VertragDatumBis DATETIME
);
CREATE UNIQUE INDEX IDX ON EUeberwachungen (
	ID
);
CREATE INDEX ID_UeberwachungDefX ON EUeberwachungen (
	ID_UeberwachungDef
);
CREATE INDEX ID_ObjektX ON EUeberwachungen (
	ID_Objekt
);

