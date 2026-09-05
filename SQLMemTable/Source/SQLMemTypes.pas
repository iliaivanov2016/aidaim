unit SQLMemTypes;

interface

{$I SQLMemVer.inc}

uses
     SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}
{$IFDEF D6H}
     Variants,
{$ELSE}
     SQLMemD4Routines,
{$ENDIF}
// SQLMemTable units
{$IFDEF LINUX}
     SQLMemLinux,
{$ENDIF}
     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
     SQLMemConst,
     SQLMemStrUtils,
     SQLMemExcept;



type

 TSQLMemList = class;
//------------------------------------------------------------------------------
// Delphi 4,5 types
//------------------------------------------------------------------------------

{$IFNDEF D6H}
 PWord = ^Word;
 PInteger = ^Integer;
 PByte = ^Byte;
 PCardinal = ^Cardinal;
{$ENDIF}


//------------------------------------------------------------------------------
// Encryption types
//------------------------------------------------------------------------------

  TSQLMemCryptoKey = packed record
   Key:             array [0..SQLMem_MAX_KEY] of Byte;
   KeySize:         Word; // 0 by default
  end;

  TSQLMemCryptoInfo = packed record
   KeyInfo:         TSQLMemCryptoKey;
   InitVector:      array [0..SQLMem_MAX_VECTOR] of Byte;
   InitVectorSize:  Word;
   Password:        AnsiString; // SQLMemDefaultPassword by default
   CryptoAlgorithm: Byte;  // acr_Cipher_None by Default
   CryptoMode:      Byte;  // acr_CTS by Default
   UseInitVector:   Boolean; // False by default
  end;
{
   KeyInfo:         TCPSCryptoKey;
   InitVector:      array [0..CPS_MAX_VECTOR] of Byte;
   CryptoAlgorithm: Byte;  // CPS_Cipher_None by Default
   CryptoMode:      Byte;  // CPS_CTS by Default
   UseInitVector:   Boolean; // False by default
   Password:        AnsiString; // CPSDefaultPassword by default

}

  TSQLMemCryptoControlBlock = packed record
   Data:            array [0..SQLMem_MAX_CONTROL_BLOCK] of Byte;
  end; // 256

  TSQLMemCryptoHeader = packed record
   ControlBlock:      TSQLMemCryptoControlBlock;
   ControlBlockCRC:   Cardinal;
   CryptoAlgorithm:   Byte;
   CryptoMode:        Byte;
   CryptoAskPassword: Byte; // ask password (1) or key (0)
   Reserverd:         array[0..4] of Byte;
  end; // 268

 TSQLMemCryptoParams = TSQLMemCryptoInfo;

//------------------------------------------------------------------------------
// general types
//------------------------------------------------------------------------------

 TSQLMemIntegerArray = class;

 TSQLMemErrorCode = Integer;
 TSQLMemPageNo = Integer;
 PSQLMemPageNo = ^TSQLMemPageNo;
 TSQLMemPageBuffer = PAnsiChar;
 TSQLMemGetRecordMode = (grmCurrent, grmNext, grmPrior);
 TSQLMemGetRecordResult = (grrOK, grrBOF, grrEOF, grrError, grrReloadCache); // grrReloadCache - cleint cache must be reloaded
 TSQLMemBLOBOpenMode = (bomWrite, bomRead, bomReadWrite);
 TSQLMemRecordBuffer = PAnsiChar;
 TSQLMemState = Cardinal;
 TSQLMemObjectID = Integer;
 TSQLMemTableID = TSQLMemObjectID; 
 // changed in v.5
// TSQLMemObjectName = ShortString;
 TSQLMemObjectName = WideString;
 TSQLMemSessionID = Integer;
 TSQLMemRecordNo = Int64;
 TSQLMemPageItemID = Word;
 TSQLMemRecordID = packed record
  PageNo:        TSQLMemPageNo; // page number or record number (disk engine or memory, temporary engine)
  PageItemNo:    TSQLMemPageItemID;
 end;
 PSQLMemRecordID = ^TSQLMemRecordID;
 TSQLMemLockParams = packed record
  RetryCount:   Integer;
  Delay:        Integer;
 end;
 { TODO -oLeo : change to cardinal }
 TSQLMemOptions = packed record
  MaxSessionCount:            Cardinal;
  PageSize:                   Cardinal;
  ExtentPageCount:            Word;
  RandomSearchRetryCount:     Cardinal;
 end;


//------------------------------------------------------------------------------
// disk types
//------------------------------------------------------------------------------

 TSQLMemIsPageSynchronizationRequired =
  function (PageState: Cardinal): Boolean of object;

 // 65535 - page is used by other table or 100% filled 
 TSQLMemPageRecordCount = Word;
 PSQLMemPageRecordCount = ^TSQLMemPageRecordCount;
 TSQLMemDBFileType = (dbftUnknown,dbftTablesList,dbftActiveSessionsList,dbftStoredFunctionManager);
 TSQLMemLockType = (ltIS,ltS,ltIRW,ltRW,ltU,ltX);
 TSQLMemLockObjectType = (lotDatabase,lotTable,lotRecord);
 // 0 RowStart - first page for Multi-Page record (0) or page with small records
 // 1 RowContinue - pages of Multi-Page record (1..n)
 // 2 Varchar - varchar values (read for each row always)
 // 3 BLOB - BLOB values (read by client application if needed)
 TSQLMemTablePageType = (tptRowStart,tptRowContinue,tptVarchar,tptBLOB);
 TSQLMemDBStateType = (
//                     0       1               2             3
                    dbstNone,dbstAll,dbstFreeSpaceManager,dbstData,
//                     4                          5                     6
                    dbstTableMetaData,dbstTableMostUpdatedData,dbstTableLockFile,
//                     7        8           9          10         11
                    dbstRow,dbstIndex,dbstTablePFS,dbstVarchar,dbstBLOB);

// Database headers structure:
// +----------+-----------+----------+--------------+-----------------+
// | DBHeader | FSMHeader | TLHeader | Locked Bytes | [Reserved data] |
// +----------+-----------+----------+--------------+-----------------+
 TSQLMemDBHeader = packed record
  Signature:        TSQLMemSignature;
  Version:          Double;
  PageSize:         Word;
  HeaderSize:       Word;
  ExtentPageCount:  Word;
  MaxSessionCount:  Cardinal; // maximum number of file-server sessions
  ReservedSize:     Cardinal;
  CryptoHeader:     TSQLMemCryptoHeader; // for database encryption
  FSMHeaderSize:    Byte;
  TLHeaderSize:     Byte;
  LockedBytesCount: Byte;      // number of locked bytes for the database file
  FUnicodeNames:    ByteBool; // if true all object names are stored in Unicode strings

(*
  // variable part of TSQLMemDBHeader
//---------------------------------------
  // FreeSpaceManager

  // TableList

  // StoredFunctionManager - added in v.5.10
  // variable part of TSQLMemDBHeader
//---------------------------------------
*)
 end; // Database header - cannot be modified without re-creating database file

 TSQLMemFSMHeader = packed record
  TotalPageCount:   TSQLMemPageNo;
  FreePageCount:    TSQLMemPageNo;
  State:            Cardinal; // state - increment by 1 on each modification
 end; // FreeSpaceManager header - can be modified only by TSQLMemFreeSpaceManager

 TSQLMemTLHeader = packed record
  TableCount:       Cardinal;
  State:            Cardinal; // state - increment by 1 on each modification
  StatePageCount:   Cardinal; // number of table state pages
 end; // TSQLMemTableList header - can be modified only by TSQLMemTableList

 // added in v.5.10
 TSQLMemSFMHeader = packed record
  Count:        Integer;
  State:        TSQLMemState;
 end; // TSQLMemSFMHeader


 TSQLMemLockedBytes = packed record
  LockedByteCount:  Word;
 end;

 TSQLMemPageTypeID = Word;

 TSQLMemDiskPageHeader = packed record
  Signature:        Array [0..3] of AnsiChar;
  NextPageNo:       TSQLMemPageNo;
  ObjectID:         TSQLMemObjectID;
  CRC32:            Cardinal;
  PageType:         TSQLMemPageTypeID; // 2 bytes???
  CRCType:          Byte;
  CipherType:       Byte;
  Reserved:         Byte;
 end; // 21 bytes
 PSQLMemDiskPageHeader = ^TSQLMemDiskPageHeader;

 TSQLMemBackupDescHeader = packed record
  Date:                 TDateTime;
  FileSize:             Int64;
  TableCount:           Integer;
  DescLength:           Integer;
  Size:                 Integer; // size of description and tables list
  // description
  // tables names
 end; // TSQLMemBackupDescHeader

 TSQLMemBackupHeader = packed record
  Signature:            Array [0..3] of AnsiChar;
  BlockSize:            Integer;
  CompressionAlgorithm: Byte;
  CompressionMode:      Byte;
  CryptoHeader:         TSQLMemCryptoHeader; // for database encryption
  DescHeader:           TSQLMemBackupDescHeader;
 end; // TSQLMemBackupHeader


 TSQLMemBlockHeader = packed record
  CompressedSize:   Integer;
  UncompressedSize: Integer;
 end; // TSQLMemBlockHeader


  // SQLMemDatabaseFile Mode Types
  TSQLMemShareMode = (smExclusive, smShared);
  TSQLMemAccessMode = (amReadOnly, amReadWrite);
 
 // Any list header
 PSQLMemListHeader = ^TSQLMemListHeader;
 TSQLMemListHeader = packed record
   Count:       Integer;
   ItemSize:    Integer;
   NextPageNo:  TSQLMemPageNo; // or INVALID_PAGE_NO
 end;// 12 byte

 // Header for internal file
 PSQLMemInternalFileHeader = ^TSQLMemInternalFileHeader;
 TSQLMemInternalFileHeader = packed record
   Signature:             Array [0..3] of AnsiChar; // for future low-level repair to find Metadata and MUD files
   FileSize:              Cardinal;
   CompressionAlgortihm:  Byte;
   CompressionMode:       Byte;
 end; // 10 bytes

 // System Directory List Item
 TSQLMemSystemDirectoryListItem = packed record
   FirstPageNo: TSQLMemPageNo;
   FileID:      TSQLMemDBFileType;
 end;// 5 bytes


 // Table List Item
 PSQLMemTableListItem = ^TSQLMemTableListItem;
 TSQLMemTableListItem = packed record
// updated to Unicode
//   TableName:                           WideString;
// added in v.5 for fast search by name
   TableNameCRC:                        Cardinal;
   TableID:                             TSQLMemTableID;
// added in v.5 - PageNo and offset from beginning of PageBuffer to 32-bit state
   TableStateAddress:                   TSQLMemRecordID;
// added in v.5
   CreationDate:                        TDateTime;
   MetaDataFilePageNo:                  TSQLMemPageNo;
   MostUpdatedDataFilePageNo:           TSQLMemPageNo;
// commented in v.5
//   PFSPageMapFilePageNo:                TSQLMemPageNo;
   LockFilePageNo:                      TSQLMemPageNo;
//   CryptoHeader:                        TSQLMemCryptoHeader; // for table encryption
 end;//34 bytes

 TSQLMemTablePFSPageMapItem = packed record
   PageNo:          TSQLMemPageNo;
   PageRecordCount: Integer;
 end;

 TSQLMemTablePFSItem = packed record
   PageType:        TSQLMemTablePageType;
   PageRecordCount: Word; // Record Count for RowStart, otherwise Free Space
                          // $FFFF - empty or other table page
 end;

 // blob or VarChar
 TSQLMemDataItem = packed record
    ItemID:       Word;
    DataSize:     Word;
 end;
 TSQLMemDataItemsMap = array of TSQLMemDataItem;

 // added in v.5
 TSQLMemLastTableOperation = (
                            ltoCreateTable,
                            ltoInsert,
                            ltoUpdate,
                            ltoDelete,
                            ltoCommit,
                            ltoEmpty,
                            ltoAddIndex,
                            ltoDeleteIndex,
                            ltoEmptyIndex,
                            ltoAddForeignKey,
                            ltoDeleteConstraint,
                            ltoRenameReferencedTableName,
                            ltoRename,
                            ltoRenameField,
                            ltoSetAutoInc,
                            ltoCreateView
                           );

 TSQLMemTableFlags = (tffWriteFailed);
 TSQLMemTableState = packed record
   TableState:            TSQLMemState; // Most Updated Data state plus code of last operation
   TableMetaDataState:    Byte;      // MetaData state = can be changed by RenameField
   TableFailureFlags:     Word;      // table failure flags, or 0 if all is correct
   LastTableOperation:    TSQLMemLastTableOperation; // last table operation that changed MostUpdatedData
   LastModificationDate:  TDateTime;
 end; // added in v.5 - 16 bytes


 TSQLMemTableInfo = record
   TableName:       WideString;
   Comment:         WideString;
   TableState:      TSQLMemTableState;
   CreationDate:    TDateTime;
 end;
 TSQLMemTableInfoArray = array of TSQLMemTableInfo;

//------------------------------------------------------------------------------
// Lock manager types
//------------------------------------------------------------------------------

//   LockX:               Byte;     // reserved to lock byte
//   LockIRW:             Byte;     // reserved to lock byte
//   LockRW:              Byte;     // reserved to lock byte
// +----------+---------+---------+-------------------+------------+
// | IS locks | S locks | U locks | U max wait levels | U RecordID |
// +----------+---------+---------+-------------------+------------+
{
 TSQLMemTableLockFileHeader = packed record
   MaxSessionID:        TSQLMemSessionID; // for fast lock check
   MinSessionID:        TSQLMemSessionID; // for fast lock check
   IRWMaxWaitLevel:     Byte;
   RWMaxWaitLevel:      Byte;
   SMaxWaitLevel:       Byte;
 end; // 11 bytes
}
// changed in v.5.60
 TSQLMemTableLockFileHeader = packed record
   MinSessionID:          Cardinal; // number of sessions opened in table (IS)
   MaxSessionID:          Cardinal; // number of sessions locked in S mode
   IRWMaxWaitLevel:       Byte;
   RWMaxWaitLevel:        Byte;
   SMaxWaitLevel:         Byte;
 end; // 11 bytes
// +----------+---------+------------+-------------------+-----------------+
// | Not Useds locks    | U locks    | U max wait levels | U RecordID      |
// | former IS / S      | 1 - locked | 0 .. 255          | $FFFFFFFF.$FFFF |
// +----------+---------+------------+-------------------+-----------------+


 // stats for all table
 TSQLMemTableLockInfo = packed record
   LockXSessionID:      TSQLMemSessionID; // INVALID_SESSION_ID if not locked
   LockIRWSessionID:    TSQLMemSessionID; // INVALID_SESSION_ID if not locked
   LockRWSessionID:     TSQLMemSessionID; // INVALID_SESSION_ID if not locked
   NumLockIS:           Cardinal; // IS locks exists in this process
   NumLockS:            Cardinal; // S locks exists in this process
   NumLockU:            Cardinal; // U locks exists in this process
 end;

 // applied locks matrix for table opened by the session - used in transaction
 TSQLMemSessionLockInfo = packed record
   SessionID:      TSQLMemSessionID;
   NumLocksIS:     Cardinal;
   NumLocksS:      Cardinal;
   NumLocksIRW:    Cardinal;
   LockedRecordID: TSQLMemRecordID;
   WaitTime:       Cardinal; // start waiting time
   WaitLockType:   TSQLMemLockType;
   IsWaiting:      ByteBool;
   LockX:          ByteBool;
   LockRW:         ByteBool;
   LockU:          ByteBool;
 end;
 PSQLMemSessionLockInfo = ^TSQLMemSessionLockInfo;

 TSQLMemTransactionLockInfo = packed record
   SessionID:      TSQLMemSessionID;
   LockIS:         ByteBool; // table is closed completely - must to unlock on exit
   LockS:          ByteBool; // table data read
   LockIRW:        ByteBool; // table data modified
   LockRW:         ByteBool; // Commit
 end;
 PSQLMemTransactionLockInfo = ^TSQLMemTransactionLockInfo;

//------------------------------------------------------------------------------
// SQL types
//------------------------------------------------------------------------------


 // join type
 TSQLMemJoinType = (ajtCross, ajtInner, ajtLeftOuter,
                 ajtRightOuter, ajtFullOuter);

 // union type
 TSQLMemUnionType = (autUnion, autIntersect, autExcept);

 // table | joined table | subquery
 TSQLMemTableType = (attTable, attJoinedTable, attSubQuery);

 // table | joined table | subquery
 TSQLMemQueryExprType = (qetSelect, qetUnion, qetExcept, qetIntersect);

 // hash value of the record or field
 TSQLMemRecordHashValue = Cardinal;
 PSQLMemRecordHashValue = pCardinal;

 TSQLMemDistinctAlgorithm = (adaNone, adaBySourceIndex, adaByDestIndex, adaByRecordHash);

 // Types of alter table
 TAlterType = (atAdd,
               atDrop,
               atModify,
               atRenameColumn,
               atRenameTable,
               atDropConstraint,
               atAddConstraintPrimaryKey,
               atAddConstraintForeignKey,
               atModifyFunction,
               atRenameFunction
//               atAddConstraintUnique
               );

//------------------------------------------------------------------------------
// field types
//------------------------------------------------------------------------------

 TSQLMemBaseFieldType = (
                        bftUnknown,

                        bftChar,
                        bftWideChar,
                        bftVarchar,
                        bftWideVarchar,

                        bftSignedInt8,        // Shortint
                        bftSignedInt16,       // Smallint
                        bftSignedInt32,       // Integer
                        bftSignedInt64,       // Int64
                        bftUnsignedInt8,      // Byte
                        bftUnsignedInt16,     // Word
                        bftUnsignedInt32,     // Cardinal
                        //bftUnSignedInt64,

                        bftSingle,
                        bftDouble,
                        bftExtended,

                        bftDate,
                        bftTime,
                        bftDateTime,

                        bftBlob,
                        bftClob,
                        bftWideClob,

                        bftLogical,
                        bftCurrency,

                        bftBytes,
                        bftVarBytes,
                        //bftTimeStamp, == bftDateTime 
                        bftBFile
                     );


  TSQLMemAdvancedFieldType = (
    aftUnknown,

    aftChar,            // = bftChar
    aftString,          // = bftVarChar

    aftWideChar,        // = bftChar
    aftWideString,      // = bftWideVarChar

    aftShortint,        // = bftSignedInt8
    aftSmallint,        // = bftSignedInt16
    aftInteger,         // = bftSignedInt32
    aftLargeint,        // = bftSignedInt64
    aftByte,            // = bftUnsignedInt8
    aftWord,            // = bftUnsignedInt16
    aftCardinal,        // = bftUnsignedInt32

    aftAutoInc,         // = bftSignedInt32
    aftAutoIncShortint, // = bftSignedInt8
    aftAutoIncSmallint, // = bftSignedInt16
    aftAutoIncInteger,  // = bftSignedInt32
    aftAutoIncLargeint, // = bftSignedInt64
    aftAutoIncByte,     // = bftUnsignedInt8
    aftAutoIncWord,     // = bftUnsignedInt16
    aftAutoIncCardinal, // = bftUnsignedInt32


    aftSingle,          // = bftSingle
    aftDouble,          // = bftDouble
    aftExtended,        // = bftExtended

    aftBoolean,         // = bftLogical

    aftCurrency,        // = bftCurrency

    aftDate,            // = bftDate
    aftTime,            // = bftTime
    aftDateTime,        // = bftDateTime
    aftTimeStamp,       // = bftDateTime

    aftBytes,           // = bftBytes
    aftVarBytes,        // = bftVarBytes

    aftBlob,            // = bftBlob
    aftGraphic,         // = bftBlob
    aftMemo,            // = bftClob
    aftFormattedMemo,   // = bftClob
    aftWideMemo         // = bftWideClob

//    aftGuid             // = bftChar(XX)
//aftArray,
//    aftParadoxOle,
//    aftDBaseOle,
//    aftTypedBinary,
//    aftCursor,
//    aftReference,
//    aftDataSet,
//    aftVariant,
//    aftInterface,
//    aftIDispatch,
    );

 //TSQLMemDefaultValueType = (dvtNull, dvtConst, dvtSequence, dvtFunction, dvtQuery);
 TSQLMemCompareResult = (cmprEqual, cmprLower, cmprGreater,
                      cmprLeftNull, cmprRightNull, cmprBothNull);


 TSQLMemHexStringFormat = (ahexfDefault,ahexfDelphi,ahexfCPP);                     
//------------------------------------------------------------------------------
// record types
//------------------------------------------------------------------------------

 // used in SQLMemMemEngine for saving / loading table to stream
 TSQLMemMemoryTableFileHeader = packed record
  Signature:            array [0..3] of AnsiChar ;
  Version:              Double;
  RecordCount:          TSQLMemRecordNo;
  // compression params
  UncompressedSize:     Int64;
  NumBlocks:            Int64;
  BlockSize:            Integer;
  CompressionAlgorithm: Byte;
  CompressionMode:      Byte;
//NameLength:           Byte;
 end; // 43 bytes

 TSQLMemIndexPosition = TObject;
 TSQLMemSearchInfo = Pointer;

  // bookmark information type
  TSQLMemBookmarkFlag = (abfCurrent, abfBOF, abfEOF, abfInserted);
  TSQLMemBookmarkInfo = packed record
   BookmarkData: TSQLMemRecordID;      // record ID
   BookmarkFlag: TSQLMemBookmarkFlag;  // bookmark flag
  end;
  PSQLMemBookmarkInfo = ^TSQLMemBookmarkInfo;

 TSQLMemSequenceValue = Int64;

 TSQLMemTimeoutParams = record
  RetryCount:   Word;
  Timeout:      Integer;
 end;

 //------------------------- Search types --------------------------------------
  TSQLMemKeyIndex = (kiLookup, kiRangeStart, kiRangeEnd, kiCurRangeStart,
    kiCurRangeEnd, kiSave);
  TSQLMemSearchCondition = (scNone,scEqual,scLower,scGreater,scLowerEqual,scGreaterEqual);
  TSQLMemKeySearchType = (kstFirst,kstLast,kstAny);

  PSQLMemKeyBuffer = ^TSQLMemKeyBuffer;
  TSQLMemKeyBuffer = packed record
    Modified: Boolean;
    Exclusive: Boolean;
    FieldCount: Integer;
  end;

  TSQLMemNavigationInfo = packed record
    // in
    SessionID:        TSQLMemSessionID; // for disk engine only; INVALID_SESSION_ID for memory and temp engines
    GetRecordMode:    TSQLMemGetRecordMode;
    IndexID:          TSQLMemObjectID; // current index id (INVALID_OBJECT_ID if no active index)
    // in and out
    RecordID:         TSQLMemRecordID;
    RecordBuffer:     TSQLMemRecordBuffer;
    FirstPosition:    Boolean;
    LastPosition:     Boolean;
    // out
    GetRecordResult:  TSQLMemGetRecordResult;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemScanSearchCondition
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemScanSearchCondition = class(TObject)
   public
    Condition:                 TSQLMemSearchCondition;
    KeyRecordBuffer:           TSQLMemRecordBuffer; // if nil then Expression will be used
    KeyFieldCount:             Integer;
    IndexID:                   TSQLMemObjectID;
    Expression:                Pointer; // if nil then KeyBuffer will be used
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    ParamIndexes:              TSQLMemIntegerArray;
    OwnKeyBuffer:              Boolean;
    OwnExpression:             Boolean;
{$ENDIF}
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ScanSearchCondition: TSQLMemScanSearchCondition);
  end;

  TSQLMemExtractedConditionInfo = packed record
    KeyRecordBuffer:           TSQLMemRecordBuffer;
    ExtractedExpressionNode:   Pointer;
    Expression:                Pointer; // if nil then KeyBuffer will be used
  end;
  PSQLMemExtractedConditionInfo = ^TSQLMemExtractedConditionInfo;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemScanSearchConditionArray
//
////////////////////////////////////////////////////////////////////////////////

{$IFNDEF RECORD_SEARCH_CACHE_IN_CURSOR}
  TSQLMemScanSearchConditionArray = class(TObject)
   public
    Items:    array of TSQLMemScanSearchCondition;
    Count:    Integer;

    constructor Create;
    destructor Destroy; override;
    procedure Delete(ItemNo: Integer);
    procedure AddExpression(Expression: Pointer);
    procedure AddCondition(ScanSearchCondition: TSQLMemScanSearchCondition);
    procedure ExtractConditionsFromExpressions(IndexDefs: TObject; ExtractedConditionsInfo: TList);
    procedure ReturnConditionsToExpressions(ExtractedConditionsInfo: TList);
  end;
{$ENDIF}

{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemScanSearchConditionCache
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemLocateCondition = packed record
    FieldsNamesCRC:       Cardinal;
    FieldCount:           Integer;
    CaseInsensitive:      Boolean;
    PartialKey:           Boolean;
    Conditions:           TSQLMemList; // list o index conditions used in this locate
    ScanConditionNo:      Integer;
    ScanEndConditionNo:   Integer;
    FieldDefsNumbers:     TSQLMemIntegerArray;// array of numbers in FFieldDefs used in this locate
    Params:               TObject; // TSQLMemSQLParams
  end;
  PSQLMemLocateCondition = ^TSQLMemLocateCondition;


  TSQLMemLastSearchOperation = (lsoNone,lsoLocate,lsoFindKey,lsoFilterRecord);

  TSQLMemScanSearchConditionCache = class(TObject)
   private
    FConditions:              TSQLMemList;
    FLocateConditions:        TSQLMemList;
    FLastLocateCondition:     PSQLMemLocateCondition;
    FFindKeySearchCondition:  TSQLMemScanSearchCondition;
    FLastOperation:           TSQLMemLastSearchOperation;
    FFilterConditionCount:    Integer;
    FFilterConditionNo:       Integer; // ScanConditionNo
    FFilterConditionEndNo:    Integer; // ScanConditionEndNo
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function FindLocateCondition(crc: Cardinal; CaseInsensitive,PartialKey: Boolean): PSQLMemLocateCondition;
    procedure AddLocateCondition(pLocateCondition: PSQLMemLocateCondition);
    function CreateLocateCondition: PSQLMemLocateCondition;
    procedure FreeLocateCondition(pLocateCondition: PSQLMemLocateCondition);
    function GetFindKeySearchCondition: TSQLMemScanSearchCondition;
    procedure AddFindKeySearchCondition(KeyCondition: TSQLMemScanSearchCondition);
    procedure PrepareForFilter;
    procedure AddFilterCondition(Condition: TSQLMemScanSearchCondition);
    procedure AddFilterExpression(Expression,IndexDefs: TObject);
   public
    property Conditions: TSQLMemList read FConditions;
    property LocateConditions: TSQLMemList read FLocateConditions;
    property FilterConditionCount: Integer read FFilterConditionCount;
    property LastOperation: TSQLMemLastSearchOperation read FLastOperation;
    property FilterConditionNo: Integer read FFilterConditionNo write FFilterConditionNo; // ScanConditionNo
    property FilterConditionEndNo: Integer read FFilterConditionEndNo write FFilterConditionEndNo; // ScanConditionEndNo
    property LastLocateCondition: PSQLMemLocateCondition read FLastLocateCondition;
  end; // TSQLMemScanSearchConditionCache
{$ENDIF}


 // ORDER BY clause element
 TSQLMemSortSpecification = record
   TableName:       WideString;   // table or its pseudonym
   ColumnName:      WideString;  // field name or pseudonym
   ColumnNumber:    Integer; // field number (1,2 ...)
   Descending:      Boolean; // ASC | DESC
   CaseInsensitive: Boolean; // NOCASE | CASE
 end;


//----------------------- Field Types ------------------------------------------

 PSQLMemDate = ^TSQLMemDate;
 TSQLMemDate = Integer;  // Number of days from Christmas ( -5 883 516 .. 5 883 516 )

 PSQLMemTime = ^TSQLMemTime;
 TSQLMemTime = Integer; // Number of milliseconds from day begin ( 0 .. 24*60*60*1000 )

 PSQLMemDateTime = ^TSQLMemDateTime;
 TSQLMemDateTime = packed record  // Total 8 byte
   Date: TSQLMemDate;  // Number of days from Christmas ( -5 883 516 .. 5 883 516 )
   Time: TSQLMemTime; // Number of milliseconds from day begin ( 0 .. 24*60*60*1000 )
 end;//TSQLMemDateTime                                                = 86 400 000
 TSQLMemDatePart = (dpYEAR,dpQUARTER,dpMONTH,dpDAY,dpWEEK,dpHOUR,dpMINUTE,dpSECOND,dpMILLISECOND,dpUNDEFINED);

 PSQLMemLogical = ^TSQLMemLogical;
 //TSQLMemLogical = ByteBool;
 TSQLMemLogical = WordBool; //TDataset using WordBool

 PSQLMemCurrency = ^TSQLMemCurrency;
 //TSQLMemCurrency = Currency;
 TSQLMemCurrency = Double;  // Overflow fix


TSQLMemPagesArray = TSQLMemIntegerArray;

//------------------------------------------------------------------------------
// PageManager types
//------------------------------------------------------------------------------
  TSQLMemSessionPageInfo = record
    SessionID:          TSQLMemSessionID;
    DirtyPages:         TList;
    AddedPageNumbers:   TSQLMemPagesArray;
    RemovedPageNumbers: TSQLMemPagesArray;
  end;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIntegerArray
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemIntegerArray = class(TObject)
   public
     Items:          array of Integer; 
     ItemCount:      Integer;
     AllocBy:        Integer;
     deAllocBy:      Integer;
     MaxAllocBy:     Integer;
     AllocItemCount: Integer;

     constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
     );
     destructor Destroy; override;
     procedure SetSize(newSize: Integer);
     procedure Assign(v: TSQLMemIntegerArray);
     procedure Append(value: Integer);
     procedure Remove(value: Integer);
     procedure Insert(ItemNo: Integer; value: Integer);
     procedure Delete(ItemNo: Integer);
     procedure MoveTo(itemNo, newItemNo: Integer);
     procedure CopyTo(
                      var ar: array of Integer;
                      itemNo, iCount: Integer
                      );
     function IsValueExists(value: Integer): Boolean;
     function IndexOf(value: Integer): Integer;
     function Add(value: Integer): Boolean;
 end; // TSQLMemIntegerArray



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemInt64Array
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemInt64Array = class(TObject)
   public
     Items:          array of Int64;
     ItemCount:      Int64;
     AllocBy:        Integer;
     deAllocBy:      Integer;
     MaxAllocBy:     Integer;
     AllocItemCount: Int64;

     constructor Create(
      size: Int64 = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
     );
     destructor Destroy; override;
     procedure SetSize(newSize: Int64);
     procedure Realloc(NewItemCount, NewAllocItemCount: Integer);
     procedure Assign(v: TSQLMemInt64Array);
     procedure Append(value: Int64);
     procedure Remove(value: Int64);
     procedure Insert(ItemNo: Int64; value: Int64);
     procedure Delete(ItemNo: Int64);
     procedure MoveTo(itemNo, newItemNo: Int64);
     procedure CopyTo(
                      var ar: array of Int64;
                      itemNo, iCount: Int64
                      );
     function IsValueExists(value: Int64): Boolean;
     function IndexOf(value: Int64): Int64;
     function Add(value: Int64): Boolean;
 end; // TSQLMemInt64Array


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemList
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemList = class
 private
    FItems:       array of Pointer;
    FCount:       Integer;
    FCapacity:    Integer;
    FDeAllocBy:   Integer;
    FAllocBy:     Integer;
    FMaxAllocBy:  Integer;
 protected
    function GetItem(Index: Integer): Pointer;
    procedure SetItem(Index: Integer; Item: Pointer);
    procedure SetCount(value: Integer); virtual;
    procedure SetCapacity(value: Integer); virtual;
 public
    constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                       );
    destructor Destroy; override;
    procedure Clear; virtual;
    function IndexOf(Item: Pointer): Integer; virtual;
    procedure Add(Item: Pointer); virtual;
    procedure Remove(Item: Pointer); virtual;
    procedure Delete(Index: Integer); virtual;
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Pointer read GetItem write SetItem; default;
 end; // TSQLMemList



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemRecordIDArray
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemRecordIDArray = class(TObject)
   private
     FSorted:        Boolean;
     FInMemory:      Boolean;
     FTemporary:     Boolean;
     FMaxRecordID:   TSQLMemRecordID;
   public
     Items:          array of TSQLMemRecordID;
     ItemCount:      Integer;
     AllocBy:        Integer;
     deAllocBy:      Integer;
     MaxAllocBy:     Integer;
     AllocItemCount: Integer;

     constructor Create(
      Size:           Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
     );
     destructor Destroy; override;
     procedure SetSize(newSize: Integer);
     procedure Realloc(NewItemCount, NewAllocItemCount: Integer);
     procedure Assign(v: TSQLMemRecordIDArray);
     procedure Append(var value: TSQLMemRecordID);
     procedure Insert(ItemNo: Integer; const value: TSQLMemRecordID);
     procedure Delete(ItemNo: Integer);
    protected
     // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
     function CompareRecordIDMemory(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
     // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
     function CompareRecordIDTemporary(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
     // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
     function CompareRecordIDDisk(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
    public
     // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
     function CompareRecordID(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
    protected
     // return -1 if not found, otherwise return position in Items array [0..ItemCount-1]
     function FindRecordByIDSorted(const RecordID: TSQLMemRecordID): Integer;
    public
     procedure Sort;
     // return -1 if not found, otherwise return position in Items array [0..ItemCount-1]
     function FindRecordByID(const RecordID: TSQLMemRecordID): Integer;
    public
     property Sorted: Boolean read FSorted write FSorted;
     property InMemory: Boolean read FInMemory write FInMemory;
     property Temporary: Boolean read FTemporary write FTemporary;
     property MaxRecordID: TSQLMemRecordID read FMaxRecordID write FMaxRecordID;
 end; // TSQLMemRecordIDArray


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemHashArray
//
////////////////////////////////////////////////////////////////////////////////

 // stores and searches 32-bit Integer hash values (only = comparison operator) with optional data

 // Prototypes of functions for customization of algorithm that extracts key from hash
 // extracts key from Hash value
 // returns extracted key with additional count
 PSQLMemGetHashKeyFromHashFunction =
   function (
    const     HashValue: TSQLMemRecordHashValue;     // Hash value
    const     Count:     TSQLMemRecordHashValue = 0  // SetCount
            ): TSQLMemRecordHashValue of object;
 // return count from key elemenent
 PSQLMemGetCountFromHashKeyFunction =
   function (
    const     HashValue: TSQLMemRecordHashValue      // Hash value
            ): TSQLMemRecordHashValue of object;
 // return updated key element
 PSQLMemSetCountToHashKeyFunction =
   function (
    const     HashValue: TSQLMemRecordHashValue;     // Hash value
    const     Count:     TSQLMemRecordHashValue = 0  // SetCount
            ): TSQLMemRecordHashValue of object;
 PSQLMemIsHashKeysEqual =
   function (
    const     HashValue: TSQLMemRecordHashValue;     // Hash value
    const     HashKey:   TSQLMemRecordHashValue     // Hash key value
            ): Boolean of object;
 TSQLMemHashArray = class(TObject)
   private
// The data of this class consist of 2 parts: KeyData and buffers with elements
// Element format:
// | 32-bit HASH | [ OPTIONAL DATA] |
// KeyData format (number of key elements = maximum number of unique keys):
// [ | Key: FKeySize bits | Count: 32 - FKeySize bits | Data: 32-bit pointer to page buffer with elements |] .. []
// Data = 0 - no elements with such key
// Data > 0 - Count+1 elements sotred with such key

    FDataSize: Integer; // size in bytes of the data linked to each hash value
    FPageSize: Integer; // size in bytes of the page that used for storing hash values and data
    FAllocBy:  Integer; // number of elements (hash value + data) stored in the page buffer
                        // the size of buffer is always equatl to FPageSize * N

                                // Key buffer format
    FKeyStartBitNo:    Integer; // the number of first bit (0..31) of the key
                                // | ... |       KEY                | ...          |
                                // 31    FKeyStartBitNo + FKeySize  FKeyStartBitNo 0
    FKeySize:          Integer; // size in bits of the key (part of HashValue)
    FKeyData:          PAnsiChar;   // pointer to buffer with key data
    FKeyElementSize:   Integer; // size in bytes of key element:
                                // SQLMem_HASH_VALUE_SIZE + SizeOf(PChar); // 8
    FValueElementSize: Integer; // size in bytes of value element:
                                // FValueElementSize := SQLMem_HASH_VALUE_SIZE + FDataSize;
    FKeyMemAllocated:   Int64;
    FDataMemAllocated:  Int64;
    FTotalMemAllocated: Int64;
    FKeyElementCount:   Cardinal;
    FValueElementCount: Cardinal;
    FMaxKeyCount:       Cardinal; // maximum number of unqiue keys
    FMaxElementCount:   Cardinal; // maximum number of elements
    FKeyMask:           TSQLMemRecordHashValue;
    FReallocMemCount:   Integer;

    FGetHashKeyPtr:             PSQLMemGetHashKeyFromHashFunction;
    FGetCountFromHashKeyPtr:    PSQLMemGetCountFromHashKeyFunction;
    FSetCountToHashKeyPtr:      PSQLMemSetCountToHashKeyFunction;
    FIsHashKeysEqualPtr:        PSQLMemIsHashKeysEqual;
   protected
    function GetKeyElementFromHash(
      const     HashValue: TSQLMemRecordHashValue;     // Hash value
      const     Count:     TSQLMemRecordHashValue = 0  // SetCount
              ): TSQLMemRecordHashValue;
    function GetCountFromKeyElement(
      const     HashValue: TSQLMemRecordHashValue      // Hash value
              ): TSQLMemRecordHashValue;
    function SetCountToKeyElement(
      const     HashValue: TSQLMemRecordHashValue;     // Hash value
      const     Count:     TSQLMemRecordHashValue = 0  // SetCount
            ): TSQLMemRecordHashValue;
    function IsHashKeysEqual(
      const     HashValue: TSQLMemRecordHashValue;     // Hash value
      const     HashKey:   TSQLMemRecordHashValue     // Hash key value
            ): Boolean;
    procedure Init;
    function FindHashValue(
              const buf: PAnsiChar;
              const numElements: Cardinal;
              const HashValue: TSQLMemRecordHashValue
               ): Boolean;
    // debug
    procedure WriteStats;
   public
    constructor Create(
                  DataSize:       Integer = 0;
                  AllocBy:        Integer = 100;
                  KeyStartBitNo:  Integer = 0;
                  KeySize:        Integer = 8
                      );
    destructor Destroy; override;
    // appends unique hash value if it is not stored yet and returns true
    // returns false if hash value already exists
    function Append(HashValue: TSQLMemRecordHashValue; Data: PAnsiChar = nil): Boolean;
    // return true if hash value already exists
//    function IsValueExists(HashValue: TSQLMemRecordHashValue): Boolean; virtual; abstract;
    // return pointer to Data associated with hash if hash value already exists
//    function GetData(HashValue: TSQLMemRecordHashValue): PAnsiChar; virtual; abstract;
    property GetHashKeyFromHashFunction: PSQLMemGetHashKeyFromHashFunction
              read FGetHashKeyPtr write FGetHashKeyPtr;
    property GetCountFromHashKeyPtr: PSQLMemGetCountFromHashKeyFunction
      read FGetCountFromHashKeyPtr write FGetCountFromHashKeyPtr;
    property SetCountToHashKeyPtr: PSQLMemSetCountToHashKeyFunction
              read FSetCountToHashKeyPtr write FSetCountToHashKeyPtr;
    property IsHashKeysEqualPtr: PSQLMemIsHashKeysEqual read FIsHashKeysEqualPtr write FIsHashKeysEqualPtr;
    property KeyMemAllocated:   Int64 read FKeyMemAllocated;
    property DataMemAllocated:  Int64 read FDataMemAllocated;
    property TotalMemAllocated: Int64 read FTotalMemAllocated;
    property KeyElementCount: Cardinal read FKeyElementCount;
    property ValueElementCount: Cardinal read FValueElementCount;
    property MaxKeyCount: Cardinal read FMaxKeyCount;
 end; // TSQLMemHashArray


////////////////////////////////////////////////////////////////////////////////
//
// used for storing and searching object names
//
// Buffer format:
// | FSize | FItemCount | Item 0 | .... | Item N |
//
// Item format:
// | NameLength in bytes | Name in wide chracters |
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemTableNameLength = Word;
 TSQLMemSortedStringPtrArray = class(TList);
 TSQLMemObjectNameArray = class (TObject)
  private
   FItemOffsets:   TSQLMemIntegerArray; // offsets of each item from FBuffer
   FBuffer:        PAnsiChar;
   FAllocatedSize: Integer;
  protected
   function GetItemCount: Integer;
   procedure SetString(ItemIndex: Integer; Name: WideString);
   function GetString(ItemIndex: Integer): WideString;
   procedure InternalSetSize(NewSize: Integer);
   procedure UpdateOffsets(StartItemIndex,Delta: Integer);
  public
   constructor Create;
   destructor Destroy; override;
   procedure Clear;
   procedure Assign(Source: TSQLMemObjectNameArray); 
   // add element and return its number
   function Add(const Name: WideString): Integer;
   procedure Delete(ItemIndex: Integer);
   function SaveToStream(Stream: TStream; CountSize: Boolean = False): Integer;
   procedure LoadFromStream(Stream: TStream);
  public
   property Count: Integer read GetItemCount;
   property Strings[ItemIndex: Integer]: WideString read GetString write SetString; default;
   property Buffer: PAnsiChar read FBuffer;
 end; // TSQLMemObjectNameArray




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemWideStringList
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemWideStringList = class (TPersistent)
  public
    FItems:           array of WideString;
    FItemCount:       Integer;
  private
    FAllocItemCount:  Integer;
    FAllocBy:         Integer;
    FdeAllocBy:       Integer;
    FMaxAllocBy:      Integer;
    FOnChange:        TNotifyEvent;
    FUnicode:         Boolean;
    FThreadSync:      TObject;
 public
    procedure SetSize(NewSize: Integer);
    function InternalGetStrings(Index: Integer): WideString;
    procedure InternalSetStrings(Index: Integer; const Value: WideString);
    function InternalGetText: WideString;
    procedure InternalSetText(const Value: WideString);
 protected
    function GetStrings(Index: Integer): WideString;
    procedure SetStrings(Index: Integer; const Value: WideString);
    function GetText: WideString;
    procedure SetText(const Value: WideString);
    procedure DoOnChange;
    function InternalAdd(const Value: WideString): Integer;
    procedure InternalDelete(Index: Integer);
    function InternalIndexOf(const Value: WideString): Integer;
    procedure DoQuickSort(min,max: Integer);
  public
    constructor Create(
                         Size:            Integer = 0;
                         DefaultAllocBy:  Integer = 10;
                         MaximumAllocBy:  Integer = 100
                       );
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(Source: TPersistent); override;
    function Add(const Value: WideString; const bAddIfNotExists: Boolean = False): Integer;
    procedure Delete(Index: Integer);
    // deletes first occurrence of the Value
    procedure Remove(const Value: WideString);
    function IndexOf(const Value: WideString): Integer;
{$IFDEF D6H}
    procedure LoadFromFile(const FileName: WideString); overload;
{$ELSE}
    procedure LoadFromFile(const FileName: WideString; Dummy: ByteBool); overload;
{$ENDIF}
    procedure LoadFromFile(const FileName: AnsiString); overload;
    procedure LoadFromStream(Stream: TStream);
{$IFDEF D6H}
    procedure SaveToFile(const FileName: WideString); overload;
{$ELSE}
    procedure SaveToFile(const FileName: WideString; Dummy: ByteBool); overload;
{$ENDIF}
    procedure SaveToFile(const FileName: AnsiString); overload;
    procedure SaveToStream(Stream: TStream);
    procedure Lock(Exclusive: Boolean = True);
    procedure Unlock;
    procedure BeginUpdate;
    procedure EndUpdate;
    // sort alphabetically using current locale
    procedure Sort;
    // export all strings to TSTrings descendant object
    procedure ExportToTstrings(Destination: TStrings);
  public
    property Count: Integer read FItemCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Unicode: Boolean read FUnicode;
    property Strings[Index: Integer]: WideString read GetStrings write SetStrings; default;
  published
    property Text: WideString read GetText write SetText;
 end; // TSQLMemWideStringList


 

////////////////////////////////////////////////////////////////////////////////
//
// Compressed Stream Block Headers Array and related stuff
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemBLOBDescriptor = packed record
  BlockSize:             Integer; // block size
  NumBlocks:             Int64;  // number of blocks
  UncompressedSize:      Int64; // size of uncompressed data
  StartPosition:         Int64; // position in stream where first block header is stored
  CompressionAlgorithm:  Byte; // compression algorithm
  CompressionMode:       Byte; // compression mode (0-9)
  Reserved:              array [0..1] of Byte;
 end; // TSQLMemBLOBDescriptor - 32 bytes
 PSQLMemBLOBDescriptor = ^TSQLMemBLOBDescriptor;

 // blob descriptor that stores for each blob value
 TSQLMemPartialBLOBDescriptor = packed record
  NumBlocks:             Integer; // number of blocks
  UncompressedSize:      Int64; // size of uncompressed data
 end; // TSQLMemPartialBLOBDescriptor - 8 bytes
 PSQLMemPartialBLOBDescriptor = ^TSQLMemPartialBLOBDescriptor;

 // blob descriptor that stores for each blob value
 TSQLMemPartialTemporaryBLOBDescriptor = packed record
  NumBlocks:             Integer; // number of blocks
  UncompressedSize:      Int64; // size of uncompressed data
  CompressedSize:        Int64; // size of compressed data
 end; // TSQLMemPartialTemporaryBLOBDescriptor - 8 bytes
 PSQLMemPartialTemporaryBLOBDescriptor = ^TSQLMemPartialTemporaryBLOBDescriptor;


 TSQLMemCompressedStreamBlockHeader = packed record
       CompressedSize:      Integer; // packed block size
       UncompressedSize:    Integer; // unpacked block size
       Crc32:               Cardinal; // check sum for this block page
       OffsetToNextHeader:  Int64;  // offset from beginning of the compressed stream
                                    // to next block header
 end; // 20

 TSQLMemCompressedStreamBlockHeadersArray = class
    private
     AllocBy:             Int64;
     DeAllocBy:           Int64;
     MaxAllocBy:          Int64;
     AllocItemCount:      Int64;
    public
     Items:               array of TSQLMemCompressedStreamBlockHeader;
     Positions:           array of Int64; // block positions
     ItemCount:           Int64; // all files quantity (including deleted files)
    public
     constructor Create;
     destructor Destroy; override;
     procedure SetSize(NewSize: Int64);
     procedure AppendItem(Value: TSQLMemCompressedStreamBlockHeader; Pos: Int64);
     function FindPosition(Pos: Int64) : Integer;
   end; // TSQLMemCompressedStreamBlockHeadersArray


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBitsArray
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemBitsArray = class (TObject)
   private
    FBits:              PAnsiChar;
    FBitCount:          Integer; // total number of bits
    FNonZeroBitCount:   Integer; // number of bits equal to 1
    FBitsTable:         array [0..255] of byte;
   protected
    function GetNonZeroBitCount: Integer;
    procedure SetSize(NewSize: Integer);
   public
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
    constructor Create;
    destructor Destroy; override;
    function GetBit(BitNo: Integer): Boolean;
    procedure SetBit(BitNo: Integer; Value: Boolean);
    // returns number of bit = 1 in FBits array by bit position
    function GetBitNoByBitPosition(BitPosition: Integer): Integer;
    // returns position of bit = 1 by bit no in FBits array
    function GetBitPositionByBitNo(BitNo: Integer): Integer;
    procedure SetAllBits;
    function Find(
                  Value:        Boolean;
                  var BitNo:    Integer
                 ): Boolean;
   public
    property Size: Integer read FBitCount write SetSize;
    property NonZeroBitCount: Integer read FNonZeroBitCount;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// Bits functions
//
////////////////////////////////////////////////////////////////////////////////

  // return number of records (RecordSize) that can be stored in the buffer (BufferSize)
  function SQLMemGetRecordCountByBufferSize(BufferSize, RecordSize: Integer): Integer;
  // return true if RecordID1 = RecordID2
  function SQLMemIsEqualRecordID(const RecordID1, RecordID2: TSQLMemRecordID): Boolean;

{$IFNDEF DEBUG_LOG}
function aaGetTickCount: Cardinal;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//
// Other functions
//
////////////////////////////////////////////////////////////////////////////////


  // returns temporary name
  function GetTemporaryName(Prefix: AnsiString): AnsiString;
  // return difference, even if computer time was reset to zero once
  function SQLMemGetTickCountDiff(NewTime, OldTime: Cardinal): Cardinal;
  // clear string with private data (passwords, keys, etc.)
  procedure SQLMemClearString(var Value: AnsiString; EncryptedDBOnly: Boolean = False); overload;
  procedure SQLMemClearString(var Value: WideString; EncryptedDBOnly: Boolean = False); overload;
  function SQLMemGetLastTableOpertaion(operation: TSQLMemLastTableOperation): WideString;
  // Add CRC of multiple objects to get unique overall CRC
  // so ADDCRC(A,B) <> ADD CRC(B,A) in most cases
  function SQLMemAddCRC(value1,value2: Cardinal; Order: Byte): Cardinal;
  // return true if string contains any Unicode characters
  function SQLMemIsUnicodeString(Value: WideString): Boolean;
  // return 0 if value1 = value2, 1 if value1 > value2, -1 if value1 < value2
  function SQLMemCompareTableInfo(const value1, value2: TSQLMemTableInfo): Integer;
  procedure SQLMemSwapTableInfoElements(tablesInfo: TSQLMemTableInfoArray; index1, index2: Integer);
  procedure SQLMemSortTableInfo(tablesInfo: TSQLMemTableInfoArray; min,max: Integer);
  function SQLMemGetTableStateAsString(const State: TSQLMemTableState): AnsiString;
  function SQLMemGetLockModeName(const LockType: TSQLMemLockType): AnsiString;
  // return maximum time to wait for the lock before exception will be raised
  function SQLMemGetMaxWaitTime(LockParams: TSQLMemLockParams): Cardinal;
  // return level 0..MaxLevel
  // 0 - means 0 wait time or max wait time = 0
  // higher value - more time waited for the lock
  // Result / MaxLevel = dt / MaxWaitTime
  function SQLMemGetWaitLevel(const StartWaitTime, MaxWaitTime: Cardinal): Byte;
  procedure SQLMemParseFieldNames(FieldNames: WideString; FieldNamesList: TSQLMemWideStringList);
  // return maximum day number (28,29,30,31)
  function SQLMemGetMaxDayOfMonth(month,year: Word): Word;

implementation

uses Math, TypInfo
     ,SQLMemExpressions, SQLMemCompression, SQLMemCriticalSection
     ,SQLMemVariant
     ,SQLMemMemory // last
;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemScanSearchCondition
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemScanSearchCondition.Create;
begin
  KeyRecordBuffer := nil;
  IndexID := INVALID_OBJECT_ID;
  Expression := nil;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
  ParamIndexes := TSQLMemIntegerArray.Create;
  KeyFieldCount := 0;
  OwnKeyBuffer := False;
  OwnExpression := False;
{$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemScanSearchCondition.Destroy;
begin
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
  ParamIndexes.Free;
  if (OwnKeyBuffer) then
    if (KeyRecordBuffer <> nil) then
     MemoryManager.FreeAndNilMem(KeyRecordBuffer);
  if (OwnExpression) then
    if (Expression <> nil) then
    begin
     TSQLMemExpression(Expression).Free;
     Expression := nil;
    end;
{$ENDIF}
  inherited;
end;// Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchCondition.Assign(ScanSearchCondition: TSQLMemScanSearchCondition);
begin
  Condition := ScanSearchCondition.Condition;
  KeyRecordBuffer := ScanSearchCondition.KeyRecordBuffer;
  KeyFieldCount := ScanSearchCondition.KeyFieldCount;
  IndexID := ScanSearchCondition.IndexID;
  Expression := ScanSearchCondition.Expression;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
  OwnKeyBuffer := ScanSearchCondition.OwnKeyBuffer;
  OwnExpression := ScanSearchCondition.OwnExpression;
  ParamIndexes.Assign(ScanSearchCondition.ParamIndexes);
{$ENDIF}
end;// Assign



{$IFNDEF RECORD_SEARCH_CACHE_IN_CURSOR}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemScanSearchConditionArray
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemScanSearchConditionArray.Create;
begin
  Items := nil;
  Count := 0;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemScanSearchConditionArray.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].Free;
  SetLength(Items, 0);
end;// Destroy


//------------------------------------------------------------------------------
// Delete
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionArray.Delete(ItemNo: Integer);
begin
 if (ItemNo < 0) or (ItemNo >= Count) then
  raise ESQLMemException.Create(10413,ErrorLInvalidItemNumber);
 if (Items[ItemNo] = nil) then
  raise ESQLMemException.Create(10414,ErrorLNilPointer);
 Items[ItemNo].Free; 
 if (ItemNo < Count - 1) then
  Move(Items[ItemNo+ 1 ],Items[ItemNo],
      (Count - ItemNo-1) * SizeOf(TSQLMemScanSearchCondition));
 Dec(Count);
 SetLength(Items,Count);
end; // Delete


//------------------------------------------------------------------------------
// AddExpression
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionArray.AddExpression(Expression: Pointer);
begin
  SetLength(Items, Count+1);
  Items[Count] := TSQLMemScanSearchCondition.Create;
  Items[Count].Expression := Expression;
  Items[Count].Condition := scNone;
  Items[Count].KeyRecordBuffer := nil;
  Items[Count].KeyFieldCount := 0;
  Items[Count].IndexID := INVALID_OBJECT_ID;
  Inc(Count);
end;// AddExpression


//------------------------------------------------------------------------------
// AddCondition
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionArray.AddCondition(
                  ScanSearchCondition:  TSQLMemScanSearchCondition
                             );
begin
  if ((ScanSearchCondition.Expression = nil) and
      (ScanSearchCondition.IndexID = INVALID_ID4)) then
   raise ESQLMemException.Create(10388,ErrorLInvalidScanConditionNoIndex,
      [ScanSearchCondition.IndexID,Count]);
  SetLength(Items, Count+1);
  Items[Count] := TSQLMemScanSearchCondition.Create;
  Items[Count].Assign(ScanSearchCondition);
  Inc(Count);
end;// AddCondition


//------------------------------------------------------------------------------
// ExtractConditionsFromExpressions
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionArray.ExtractConditionsFromExpressions(
                                     IndexDefs:               TObject;
                                     ExtractedConditionsInfo: TList
                                     );
var
  i: Integer;
begin
  for i := 0 to Count-1 do
   if (Items[i].Expression <> nil) then
    begin
      TSQLMemExpression(Items[i].Expression).ExtractIndexScanConditions(
          IndexDefs,
          Self,
          ExtractedConditionsInfo
                                                                     );
    end;
end;// ExtractConditionsFromExpressions


//------------------------------------------------------------------------------
// ReturnConditionsToExpressions
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionArray.ReturnConditionsToExpressions(ExtractedConditionsInfo: TList);
var
  i: Integer;
begin
  for i := 0 to ExtractedConditionsInfo.Count-1 do
   begin
    if (PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.Expression = nil) then
     raise ESQLMemException.Create(20060, ErrorANilPointer);
    if (PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.
          ExtractedExpressionNode = nil) then
     raise ESQLMemException.Create(20061, ErrorANilPointer);
    if (PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.KeyRecordBuffer = nil) then
     raise ESQLMemException.Create(20062, ErrorANilPointer);

    TSQLMemExpression(PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.
        Expression).AddNode(
        PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.
        ExtractedExpressionNode
                         );
    MemoryManager.FreeAndNilMem(
                              PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.
                              KeyRecordBuffer);

    Dispose(ExtractedConditionsInfo[i]);
   end;
end;// ReturnConditionsToExpressions
{$ENDIF}




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemScanSearchConditionArray
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemScanSearchConditionCache.Create;
begin
  FConditions := TSQLMemList.Create;
  FLocateConditions := TSQLMemList.Create;
  FLastLocateCondition := nil;
  FFindKeySearchCondition := nil;
  FLastOperation := lsoNone;
  FFilterConditionNo := INVALID_ID4;
  FFilterConditionEndNo := INVALID_ID4;
  FFilterConditionCount := 0;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemScanSearchConditionCache.Destroy;
begin
  Clear;
  FConditions.Free;
  FLocateConditions.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// clear all conditions
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.Clear;
var i,j:              Integer;
    pLocateCondition: PSQLMemLocateCondition;
    SearchCondition:  TSQLMemScanSearchCondition;
begin
  for i := 0 to FLocateConditions.Count-1 do
  begin
    pLocateCondition := PSQLMemLocateCondition(FLocateConditions.Items[i]);
    FreeLocateCondition(pLocateCondition);
  end;
  FLocateConditions.Clear;
  for i := 0 to FFilterConditionCount-1 do
  begin
    // filter conditions
    SearchCondition := TSQLMemScanSearchCondition(FConditions.Items[i]);
    SearchCondition.Free;
  end;
  if (FFindKeySearchCondition <> nil) then
  begin
    // external buffer set from Cursor.KeyBuffer
    FFindKeySearchCondition.Free;
    FFindKeySearchCondition := nil;
  end;
  FConditions.Clear;
  FLastLocateCondition := nil;
  FLastOperation := lsoNone;
  FFilterConditionNo := INVALID_ID4;
  FFilterConditionEndNo := INVALID_ID4;
  FFilterConditionCount := 0;
end; // Clear


//------------------------------------------------------------------------------
// return nil if not found or locate search record
//------------------------------------------------------------------------------
function TSQLMemScanSearchConditionCache.FindLocateCondition(crc: Cardinal; CaseInsensitive,PartialKey: Boolean): PSQLMemLocateCondition;
var i,j:  Integer;
begin
  if (FLastLocateCondition <> nil) then
    if (FLastLocateCondition^.FieldsNamesCRC = crc) and
       (FLastLocateCondition^.CaseInsensitive = CaseInsensitive) and
       (FLastLocateCondition^.PartialKey = PartialKey) then
    begin
     Result := FLastLocateCondition;
     if (FLastOperation <> lsoLocate) then
     begin
      while (FConditions.Count > FFilterConditionCount) do
      begin
        // remove prior search conditions from the end of FConditions list
        FConditions.Delete(FConditions.Count-1);
      end;
      // add search conditions
      for j := 0 to Result.Conditions.Count-1 do
      begin
       FConditions.Add(Result.Conditions.Items[j]);
      end;
     end;
     Exit;
    end;
  for i := 0 to FLocateConditions.Count-1 do
  begin
    Result := PSQLMemLocateCondition(FLocateConditions.Items[i]);
    if (Result^.FieldsNamesCRC = crc) and
       (Result^.CaseInsensitive = CaseInsensitive) and
       (Result^.PartialKey = PartialKey) then
    begin
      while (FConditions.Count > FFilterConditionCount) do
      begin
        // remove prior search conditions from the end of FConditions list
        FConditions.Delete(FConditions.Count-1);
      end;
      // add search conditions
      for j := 0 to Result.Conditions.Count-1 do
      begin
       FConditions.Add(Result.Conditions.Items[j]);
      end;
      // condition found
      FLastLocateCondition := Result;
      FLastOperation := lsoLocate;
      Exit;
    end;
  end;
  Result := nil;
end; // FindLocateCondition


//------------------------------------------------------------------------------
// add locate condition
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.AddLocateCondition(pLocateCondition: PSQLMemLocateCondition);
var i:      Integer;
begin
  FLocateConditions.Add(pLocateCondition);
  while (FConditions.Count > FFilterConditionCount) do
  begin
    // remove prior search conditions from the end of FConditions list
    FConditions.Delete(FConditions.Count-1);
  end;
  // add search conditions
  for i := 0 to pLocateCondition^.Conditions.Count-1 do
  begin
   FConditions.Add(pLocateCondition^.Conditions.Items[i]);
  end;
  FLastLocateCondition := pLocateCondition;
  FLastOperation := lsoLocate;
end; // AddLocateCondition


//------------------------------------------------------------------------------
// create locate condition
//------------------------------------------------------------------------------
function TSQLMemScanSearchConditionCache.CreateLocateCondition: PSQLMemLocateCondition;
begin
  new(Result);
  Result^.Params := TSQLMemSQLParams.Create;
  Result^.Conditions := TSQLMemList.Create;
  Result^.FieldDefsNumbers := TSQLMemIntegerArray.Create;
end; // CreateLocateCondition


//------------------------------------------------------------------------------
// free locate condition
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.FreeLocateCondition(pLocateCondition: PSQLMemLocateCondition);
var i:      Integer;
begin
  // add search conditions
  for i := 0 to pLocateCondition^.Conditions.Count-1 do
  begin
    TSQLMemScanSearchCondition(pLocateCondition^.Conditions.Items[i]).Free;
  end;
  pLocateCondition^.Conditions.Free;
  pLocateCondition^.FieldDefsNumbers.Free;
  pLocateCondition^.Params.Free;
  Dispose(pLocateCondition);
  FLastLocateCondition := nil;
end; // FreeLocateCondition


//------------------------------------------------------------------------------
// get find key search condition
//------------------------------------------------------------------------------
function TSQLMemScanSearchConditionCache.GetFindKeySearchCondition: TSQLMemScanSearchCondition;
begin
  Result := FFindKeySearchCondition;
  if (FFindKeySearchCondition = nil) then
   Exit;
  if (FLastOperation <> lsoFindKey) then
  begin
    while (FConditions.Count > FFilterConditionCount) do
    begin
      // remove prior search conditions from the end of FConditions list
      FConditions.Delete(FConditions.Count-1);
    end;
    FConditions.Add(Result);
    FLastOperation := lsoFindKey;
  end;
end; // GetFindKeySearchCondition


//------------------------------------------------------------------------------
// add find key condition
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.AddFindKeySearchCondition(KeyCondition: TSQLMemScanSearchCondition);
begin
  FFindKeySearchCondition := KeyCondition;
  while (FConditions.Count > FFilterConditionCount) do
  begin
    // remove prior search conditions from the end of FConditions list
    FConditions.Delete(FConditions.Count-1);
  end;
  FConditions.Add(FFindKeySearchCondition);
  FLastOperation := lsoFindKey;
end; // AddFindKeySearchCondition


//------------------------------------------------------------------------------
// prepare for filter / FindFirst
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.PrepareForFilter;
begin
  FConditions.Clear;
  FLastOperation := lsoFilterRecord;
  FFilterConditionCount := 0;
end; // PrepareForFilter


//------------------------------------------------------------------------------
// add filter condition
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.AddFilterCondition(Condition: TSQLMemScanSearchCondition);
begin
  if (FLastOperation <> lsoFilterRecord) then
  while (FConditions.Count > FFilterConditionCount) do
  begin
    // remove prior search conditions from the end of FConditions list
    FConditions.Delete(FConditions.Count-1);
  end;
  Inc(FFilterConditionCount);
  FConditions.Add(Condition);
  FLastOperation := lsoFilterRecord;
end; // AddFilterCondition(Condition)


//------------------------------------------------------------------------------
// add filter expression
//------------------------------------------------------------------------------
procedure TSQLMemScanSearchConditionCache.AddFilterExpression(Expression,IndexDefs: TObject);
var expr:        TSQLMemExpression;
    cond:        TSQLMemScanSearchCondition;
begin
  expr := TSQLMemExpression(Expression);
  FFilterConditionCount := FConditions.Count;
  // it will remove extracted nodes from expression
  if (not expr.ExtractIndexScanConditions(FConditions,IndexDefs)) then
  begin
    cond := TSQLMemScanSearchCondition.Create;
    cond.Expression := expr;
    FConditions.Add(cond);
  end;
  FFilterConditionCount := FConditions.Count;
end; // AddFilterExpression
{$ENDIF}




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIntegerArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemIntegerArray.Create(
  size:           Integer;
  DefaultAllocBy: Integer;
  MaximumAllocBy: Integer
  );
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TSQLMemIntegerArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSQLMemIntegerArray.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TSQLMemIntegerArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.Assign(v: TSQLMemIntegerArray);
var
  i: Integer;
begin
  SetSize(v.ItemCount);
  if (v.ItemCount > 0) then
   Move(v.Items[0],Items[0],v.ItemCount * sizeOf(Integer));
//  for i := 0 to ItemCount-1 do
//    items[i] := v.items[i];
end;// Assign


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.SetSize(newSize: Integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TSQLMemIntegerArray.SetSize


//------------------------------------------------------------------------------
// inserts an element to the end of items array
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.Append(value: Integer);
begin
 Inc(ItemCount);
 SetSize(itemCount);
 Items[itemCount-1] := value;
end;//TSQLMemIntegerArray.Append


//------------------------------------------------------------------------------
// Remove first item = value
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.Remove(value: Integer);
var
  j: Integer;
begin
 j := IndexOf(value);
 if j > -1 then
   Delete(j);
end;//TSQLMemIntegerArray.Remove


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.Insert(itemNo: Integer; value: Integer);
begin
 inc(ItemCount);
 SetSize(ItemCount);
 if (itemCount <= 1) then
  items[0] := value
 else
 if (itemNo >= itemCount-1)
  then
   items[itemCount-1] := value
  else
   begin
    Move(items[itemNo],items[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(Integer));
    items[itemNo] := value;
   end;
end;//TSQLMemIntegerArray.Insert


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.Delete(itemNo: Integer);
begin
 if (itemNo < itemCount-1) then
  Move(items[itemNo+1],items[itemNo],
      (itemCount - itemNo-1) * sizeOf(Integer));
 dec(ItemCount);
 SetSize(ItemCount);
end;//TSQLMemIntegerArray.Delete


//------------------------------------------------------------------------------
// moves element to new position
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.MoveTo(itemNo, newItemNo: Integer);
var value : Integer;
begin
 if (itemNo = newItemNo) then
  Exit;
 if (itemNo - newItemNo = 1) or (newItemNo-itemNo = 1) then
  begin
   value := items[itemNo];
   items[itemNo] := items[newItemNo];
   items[newItemNo] := value;
   Exit;
  end;
 if (itemNo > newItemNo) then
  begin
   value := items[itemNo];
   Move(items[newItemNo],items[newItemNo+1],
        (itemNo-newItemNo) * sizeof(Integer));
   items[newItemNo] := value;
  end
 else
  begin
     value := items[ItemNo];
     Move(items[ItemNo+1],items[ItemNo],
        (newItemNo-ItemNo-1) * sizeof(Integer));
     items[newItemNo-1] := value;
  end;
end;// MoveTo(itemNo, newItemNo : Integer);


//------------------------------------------------------------------------------
// copies itemCount elements to ar from ItmeNo
//------------------------------------------------------------------------------
procedure TSQLMemIntegerArray.CopyTo(
                      var ar: array of Integer;
                      itemNo, iCount: Integer
                             );
begin
 if (itemCount > 0) then
  Move (items[itemNo],ar[0],sizeOf(Integer)*iCount);
end;// CopyTo(ar : array of Integer; itemNo,itemCount : Integer);


//------------------------------------------------------------------------------
// returns true if value exists in Items array
//------------------------------------------------------------------------------
function TSQLMemIntegerArray.IsValueExists(value: Integer): Boolean;
begin
 Result := (IndexOf(value) >= 0);
end; // IsValueExists


//------------------------------------------------------------------------------
// returns index in Items or -1 if not found
//------------------------------------------------------------------------------
function TSQLMemIntegerArray.IndexOf(value: Integer): Integer;
var i: Integer;
begin
 Result := -1;
 for i := 0 to ItemCount-1 do
  if Items[i] = value then
   begin
    Result := i;
    break;
   end;
end; // IndexOf


//------------------------------------------------------------------------------
// adds value if it is not existing, otherwise returns false
//------------------------------------------------------------------------------
function TSQLMemIntegerArray.Add(value: Integer): Boolean;
begin
 Result := not (IsValueExists(value));
 if Result then
   Append(value);
end; // Add


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemInt64Array
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemInt64Array.Create(
  size: Int64;
  DefaultAllocBy: Integer;
  MaximumAllocBy: Integer
  );
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TSQLMemInt64Array.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSQLMemInt64Array.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TSQLMemInt64Array.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.Assign(v: TSQLMemInt64Array);
var
  i: Int64;
begin
  SetSize(v.ItemCount);
  if (v.ItemCount > 0) then
   Move(v.Items[0],Items[0],v.ItemCount * sizeOf(Int64));
//  for i := 0 to ItemCount-1 do
//    items[i] := v.items[i];
end;// Assign


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.SetSize(newSize: Int64);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TSQLMemInt64Array.SetSize


//------------------------------------------------------------------------------
// reallocates the array
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.Realloc(NewItemCount, NewAllocItemCount: Integer);
begin
  AllocItemCount := NewAllocItemCount;
  SetLength(Items,AllocItemCount);
  if (AllocItemCount > MaxAllocBy) then
   begin
    AllocBy := MaxAllocBy;
    deAllocBy := MaxAllocBy;
   end
  else
   begin
    AllocBy := AllocItemCount;
    deAllocBy := AllocItemCount;
   end;
  ItemCount := NewItemCount;
end; // Realloc


//------------------------------------------------------------------------------
// inserts an element to the end of items array
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.Append(value: Int64);
begin
 Inc(ItemCount);
 SetSize(itemCount);
 Items[itemCount-1] := value;
end;//TSQLMemInt64Array.Append


//------------------------------------------------------------------------------
// Remove first item = value
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.Remove(value: Int64);
var
   j: Int64;
begin
 j := IndexOf(value);
 if j > -1 then
   Delete(j);
end;//TSQLMemInt64Array.Remove


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.Insert(itemNo: Int64; value: Int64);
begin
 inc(ItemCount);
 SetSize(ItemCount);
 if (itemCount <= 1) then
  items[0] := value
 else
 if (itemNo >= itemCount-1)
  then
   items[itemCount-1] := value
  else
   begin
    Move(items[itemNo],items[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(Int64));
    items[itemNo] := value;
   end;
end;//TSQLMemInt64Array.Insert


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.Delete(itemNo: Int64);
begin
 if (itemNo < itemCount-1) then
  Move(items[itemNo+1],items[itemNo],
      (itemCount - itemNo-1) * sizeOf(Int64));
 dec(ItemCount);
 SetSize(ItemCount);
end;//TSQLMemInt64Array.Delete


//------------------------------------------------------------------------------
// moves element to new position
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.MoveTo(itemNo, newItemNo: Int64);
var value : Int64;
begin
 if (itemNo = newItemNo) then
  Exit;
 if (itemNo - newItemNo = 1) or (newItemNo-itemNo = 1) then
  begin
   value := items[itemNo];
   items[itemNo] := items[newItemNo];
   items[newItemNo] := value;
   Exit;
  end;
 if (itemNo > newItemNo) then
  begin
   value := items[itemNo];
   Move(items[newItemNo],items[newItemNo+1],
        (itemNo-newItemNo) * sizeof(Int64));
   items[newItemNo] := value;
  end
 else
  begin
     value := items[ItemNo];
     Move(items[ItemNo+1],items[ItemNo],
        (newItemNo-ItemNo-1) * sizeof(Int64));
     items[newItemNo-1] := value;
  end;
end;// MoveTo(itemNo, newItemNo : Int64);


//------------------------------------------------------------------------------
// copies itemCount elements to ar from ItmeNo
//------------------------------------------------------------------------------
procedure TSQLMemInt64Array.CopyTo(
                      var ar: array of Int64;
                      itemNo, iCount: Int64
                             );
begin
 if (itemCount > 0) then
  Move (items[itemNo],ar[0],sizeOf(Int64)*iCount);
end;// CopyTo(ar : array of Int64; itemNo,itemCount : Int64);


//------------------------------------------------------------------------------
// returns true if value exists in Items array
//------------------------------------------------------------------------------
function TSQLMemInt64Array.IsValueExists(value: Int64): Boolean;
begin
 Result := (IndexOf(value) >= 0);
end; // IsValueExists


//------------------------------------------------------------------------------
// returns index in Items or -1 if not found
//------------------------------------------------------------------------------
function TSQLMemInt64Array.IndexOf(value: Int64): Int64;
var i: Int64;
begin
 Result := -1;
 i := 0;
 while (i < ItemCount) do
  begin
    if Items[i] = value then
     begin
      Result := i;
      break;
     end;
    Inc(i);
  end;
end; // IndexOf


//------------------------------------------------------------------------------
// adds value if it is not existing, otherwise returns false
//------------------------------------------------------------------------------
function TSQLMemInt64Array.Add(value: Int64): Boolean;
begin
 Result := not (IsValueExists(value));
 if Result then
   Append(value);
end; // Add


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemList
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get item
//------------------------------------------------------------------------------
function TSQLMemList.GetItem(Index: Integer): Pointer;
begin
  if ((Index < FCount) and (Index >= 0)) then
    Result := FItems[Index]
  else
   begin
    raise ESQLMemException.Create(11611,ErrorLInvalidIndex,[Index,FCount]);
   end;
end; // GetItem


//------------------------------------------------------------------------------
// set item
//------------------------------------------------------------------------------
procedure TSQLMemList.SetItem(Index: Integer; Item: Pointer);
begin
  if ((Index < FCount) and (Index >= 0)) then
    FItems[Index] := Item
  else
   begin
//    FCount := FCount;
    raise ESQLMemException.Create(11610,ErrorLInvalidIndex,[Index,FCount]);
   end;
end; // SetItem


//------------------------------------------------------------------------------
// set count
//------------------------------------------------------------------------------
procedure TSQLMemList.SetCount(value: Integer);
begin
 if (value = 0) then
  SetCapacity(0)
 else
  begin
   if (value > FCapacity) then
    SetCapacity(value);
   FCount := value;
  end;
end; // SetCount


//------------------------------------------------------------------------------
// set capacity
//------------------------------------------------------------------------------
procedure TSQLMemList.SetCapacity(value: Integer);
begin
 if (value < 0) then
  raise ESQLMemException.Create(11613,ErrorLInvalidCapacity,[value]);
 if (value = 0) then
  begin
   FCount := 0;
   FCapacity := 0;
   FItems := nil;
  end
 else
  begin
   if (value > FCapacity) then
    begin
     FAllocBy := FAllocBy * 2;
     if (FAllocBy > FMaxAllocBy) then
      FAllocBy := FMaxAllocBy;
     FCapacity := FCapacity + FAllocBy;
     if (FCapacity < value) then
      FCapacity := value;
    end // value > FCapacity
   else
    begin
     if ((FCapacity-value) > FDeAllocBy) then
      begin
       FCapacity := FCapacity - FDeAllocBy;
       FDeAllocBy := FDeAllocBy * 2;
       if (FDeAllocBy > FMaxAllocBy) then
        FDeAllocBy := FMaxAllocBy;
      end;
    end; // value < FCapacity
   SetLength(FItems,FCapacity);
  end;
end; // SetCapacity


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemList.Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                       );
begin
  FAllocBy := DefaultAllocBy;
  FDeAllocBy := FAllocBy;
  FMaxAllocBy := MaximumAllocBy;
  SetCount(0);
  SetCapacity(size);
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemList.Destroy;
begin
  SetCapacity(0);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TSQLMemList.Clear;
begin
  SetCapacity(0);
end; // Clear


//------------------------------------------------------------------------------
// IndexOf
//------------------------------------------------------------------------------
function TSQLMemList.IndexOf(Item: Pointer): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FCount-1 do
   if (FItems[i] = Item) then
    begin
     Result := i;
     break;
    end;
end; // IndexOf


//------------------------------------------------------------------------------
// add
//------------------------------------------------------------------------------
procedure TSQLMemList.Add(Item: Pointer);
begin
 if (FCount <= FCapacity) then
  SetCapacity(FCount+1);
 FItems[FCount] := Item;
 Inc(FCount);
end; // Add


//------------------------------------------------------------------------------
// remove
//------------------------------------------------------------------------------
procedure TSQLMemList.Remove(Item: Pointer);
var Index: Integer;
begin
  Index := IndexOf(Item);
  if (Index >= 0) then
    Delete(Index);
end; // Remove


//------------------------------------------------------------------------------
// delete
//------------------------------------------------------------------------------
procedure TSQLMemList.Delete(Index: Integer);
begin
  if ((Index < 0) or (Index >= FCount)) then
   begin
    raise ESQLMemException.Create(11612,ErrorLInvalidIndex,[Index,FCount]);
   end;
  if (FCount = 1) then
   SetCapacity(0)
  else
   begin
    if (Index < (FCount-1)) then
     Move(FItems[Index+1],FItems[Index],(FCount-Index)*SizeOf(Pointer));
    Dec(FCount);
    SetCapacity(FCount);
   end;
end; // Delete


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemRecordIDArray
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemRecordIDArray.Create(
  Size:           Integer;
  DefaultAllocBy: Integer;
  MaximumAllocBy: Integer
  );
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(Size);
 FSorted := True;
end;//TSQLMemRecordIDArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSQLMemRecordIDArray.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TSQLMemRecordIDArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.Assign(v: TSQLMemRecordIDArray);
var
  i: Integer;
begin
  SetSize(v.ItemCount);
  for i := 0 to ItemCount-1 do
    items[i] := v.items[i];
end;// Assign


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.SetSize(newSize: Integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Exit;
  end;
 if (newSize > allocItemCount) then
  begin
   AllocBy := AllocBy * 2;
   if (AllocBy > MaxAllocBy) then
    AllocBy := MaxAllocBy;
   if (allocItemCount + AllocBy > newSize) then
    allocItemCount := allocItemCount + AllocBy
   else
    allocItemCount := newSize;
   SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;
 ItemCount := newSize;
end;//TSQLMemRecordIDArray.SetSize


//------------------------------------------------------------------------------
// reallocates the array
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.Realloc(NewItemCount, NewAllocItemCount: Integer);
begin
  AllocItemCount := NewAllocItemCount;
  SetLength(Items,AllocItemCount);
  if (AllocItemCount > MaxAllocBy) then
   begin
    AllocBy := MaxAllocBy;
    deAllocBy := MaxAllocBy;
   end
  else
   begin
    AllocBy := AllocItemCount;
    deAllocBy := AllocItemCount;
   end;
  ItemCount := NewItemCount;
end; // Realloc


//------------------------------------------------------------------------------
// inserts an element to the end of items array
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.Append(var value: TSQLMemRecordID);
begin
 Inc(ItemCount);
 SetSize(itemCount);
 Items[itemCount-1] := value;
end;//TSQLMemRecordIDArray.Append


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.Insert(itemNo: Integer; const value: TSQLMemRecordID);
begin
 inc(ItemCount);
 SetSize(ItemCount);
 if (itemCount <= 1) then
  items[0] := value
 else
 if (itemNo >= itemCount-1)
  then
   items[itemCount-1] := value
  else
   begin
    Move(items[itemNo],items[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(TSQLMemRecordID));
    items[itemNo] := value;
   end;
end;//TSQLMemRecordIDArray.Insert


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.Delete(itemNo: Integer);
begin
 if (itemNo < itemCount-1) then
  Move(items[itemNo+1],items[itemNo],
      (itemCount - itemNo-1) * sizeOf(TSQLMemRecordID));
 dec(ItemCount);
 SetSize(ItemCount);
end;//TSQLMemRecordIDArray.Delete


//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TSQLMemRecordIDArray.CompareRecordIDMemory(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
begin
 if (RecordID1.PageNo = RecordID2.PageNo) then
  Result := 0
 else
 if (RecordID1.PageNo > RecordID2.PageNo) then
  Result := 1
 else
  Result := -1;
end; // CompareRecordIDMemory


//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TSQLMemRecordIDArray.CompareRecordIDTemporary(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
var id1,id2: TSQLMemRecordNo;
begin
 id1 := 0;
 id2 := 0;
 Move(RecordID1,id1,sizeof(RecordID1));
 Move(RecordID2,id2,sizeof(RecordID2));
 if (id1 = id2) then
  Result := 0
 else
 if (id1 > id2) then
  Result := 1
 else
  Result := -1;
end; // CompareRecordIDTemporary


//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TSQLMemRecordIDArray.CompareRecordIDDisk(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
begin
 if ((RecordID1.PageNo = RecordID2.PageNo) and
     (RecordID1.PageItemNo = RecordID2.PageItemNo)) then
  Result := 0
 else
 if (RecordID1.PageNo > RecordID2.PageNo) then
  Result := 1
 else
 if (RecordID1.PageNo < RecordID2.PageNo) then
  Result := -1
 else
 if (RecordID1.PageItemNo > RecordID2.PageItemNo) then
  Result := 1
 else
  Result := -1
end; // CompareRecordIDDisk


//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TSQLMemRecordIDArray.CompareRecordID(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
begin
  if (FInMemory) then
   Result := CompareRecordIDMemory(RecordID1,RecordID2)
  else
  if (FTemporary) then
   Result := CompareRecordIDTemporary(RecordID1,RecordID2)
  else
   Result := CompareRecordIDDisk(RecordID1,RecordID2);
end; // CompareRecordID


//------------------------------------------------------------------------------
// return -1 if not found, otherwise return position in Items array [0..ItemCount-1]
//------------------------------------------------------------------------------
function TSQLMemRecordIDArray.FindRecordByIDSorted(const RecordID: TSQLMemRecordID): Integer;
var
    i,dx,f,oldRes: Integer;
    cmpRecBuf_res: Integer;
begin
  Result := -1;
  i := ItemCount shr 1;
  dx := i;
  if (ItemCount > 0) then
    begin
     f := 0;
     cmpRecBuf_res := 2;
     while (true) do
      begin
       dx := dx shr 1;
       if (dx < 1) then dx := 1;
       oldRes := cmpRecBuf_res;
       cmpRecBuf_res := -CompareRecordID(Items[i],RecordID);
       if (cmpRecBuf_res < 0) then
        begin
        //  element in index array for record buffer should be higher then current buffer (+->0)
         i := i - dx;
        end
       else
       if (cmpRecBuf_res > 0) then
        begin
        //  element in index array for record buffer should be lower then current buffer (0->+)
         i := i + dx;
        end
       else // index values are equal
        begin
         Result := i;
         break;
        end;
       if  (i < 0) and (dx = 1) then
        begin
         break;
        end;
       if  (i > ItemCount-1) and (dx = 1) then
        begin
         break;
        end;

       if  i > ItemCount-1 then
        i := ItemCount-1;
       if  i < 0 then
        i := 0;

       if (dx = 1) and (f > 1) then
        begin
         // dx minimum
         cmpRecBuf_res := -CompareRecordID(Items[i],RecordID);
         if (cmpRecBuf_res = oldRes) then
          continue;
         break;
        end;// last step
       if (cmpRecBuf_res <> oldRes) and (dx = 1) and (oldRes <> 2) then
        inc(f);
      end;//while dx
    end; // if reccount > 0
end; // FindRecordByIDSorted


//------------------------------------------------------------------------------
// sort array by record id - ascending
//------------------------------------------------------------------------------
procedure TSQLMemRecordIDArray.Sort;
var
 aLo, aHi : Integer;

 procedure QuickSort (
                    var iLo, iHi : Integer
                    );
  var
    Lo, Hi:  Integer;
    T, Mid:  TSQLMemRecordID;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := Items[(Lo + Hi) shr 1];
    repeat
     while (CompareRecordID(Items[Lo],Mid) < 0) and (Lo < iHi) do
      Inc(Lo);
     while (CompareRecordID(Items[Hi],Mid) > 0) and (Hi > 0) do
       Dec(Hi);
      if (Lo <= Hi) then
       begin
        T := Items[Lo];
        Items[Lo] := Items[Hi];
        Items[Hi] := T;
        Inc(Lo);
        Dec(Hi);
       end;
    until (Lo > Hi);
    if (Hi > iLo) then
     begin
      // check infinite recurse
      if (iHi = Hi) then
       raise ESQLMemException.Create(11329,ErrorLErrorSoringRecordsByID,[Hi,Lo,iHi,iLo,ItemCount]);
      QuickSort(iLo, Hi);
     end;
    if (Lo < iHi) then
      QuickSort(Lo, iHi);
  end; //QuickSort
begin
  if (ItemCount > 1) then
   begin
    aLo := 0;
    aHi := ItemCount-1;
    QuickSort (aLo, aHi);
   end;
  FSorted := True;
end; // Sort


//------------------------------------------------------------------------------
// return -1 if not found, otherwise return position in Items array [0..ItemCount-1]
//------------------------------------------------------------------------------
function TSQLMemRecordIDArray.FindRecordByID(const RecordID: TSQLMemRecordID): Integer;
var i: Integer;
begin
  Result := -1;
  if (FSorted and (ItemCount > 10)) then
   begin
    Result := FindRecordByIDSorted(RecordID);
   end
  else
   begin
    for i := 0 to ItemCount-1 do
      if ((Items[i].PageNo = RecordID.PageNo) and (Items[i].PageItemNo = RecordID.PageItemNo)) then
       begin
        Result := i;
        break;
       end;
   end;
end; // FindRecordByID



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemHashArray
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// return prepared key eleement
//------------------------------------------------------------------------------
function TSQLMemHashArray.GetKeyElementFromHash(
  const     HashValue: TSQLMemRecordHashValue;     // Hash value
  const     Count:     TSQLMemRecordHashValue = 0  // SetCount
          ): TSQLMemRecordHashValue;
begin
  if (Count > FMaxElementCount) then
   raise ESQLMemException.Create(11663,ErrorLInvalidCount,[Count,FMaxKeyCount]);
  if (@FGetHashKeyPtr <> nil) then
   Result := FGetHashKeyPtr(HashValue,Count)
  else
   begin
    // result - XXYY, where XX - key bits, YY - count bits
    Result := (HashValue and FKeyMask) shl (SQLMem_MAX_HASH_KEY_SIZE - FKeySize - FKeyStartBitNo)
              or Count;
   end;
end; // GetKeyFromHash


//------------------------------------------------------------------------------
// return number of key values linked to key element
//------------------------------------------------------------------------------
function TSQLMemHashArray.GetCountFromKeyElement(
      const     HashValue: TSQLMemRecordHashValue      // Hash value
              ): TSQLMemRecordHashValue;
begin
  if (@FGetCountFromHashKeyPtr <> nil) then
   Result := FGetCountFromHashKeyPtr(HashValue)
  else
   begin
    Result := HashValue and ($FFFFFFFF shr FKeySize);
   end;
end; // GetCountFromKeyElement


//------------------------------------------------------------------------------
// set number of key values linked to key element
//------------------------------------------------------------------------------
function TSQLMemHashArray.SetCountToKeyElement(
          const     HashValue: TSQLMemRecordHashValue;     // Hash value
          const     Count:     TSQLMemRecordHashValue = 0  // SetCount
        ): TSQLMemRecordHashValue;
begin
  if (Count > FMaxElementCount) then
   raise ESQLMemException.Create(11664,ErrorLInvalidCount,[Count,FMaxKeyCount]);
  if (@FSetCountToHashKeyPtr <> nil) then
   Result := FSetCountToHashKeyPtr(HashValue,Count)
  else
   begin
    //  set new count in format XXYY, where XX - key bits, YY - count bits
    Result := (HashValue and ($FFFFFFFF shl (SQLMem_MAX_HASH_KEY_SIZE - FKeySize)))
              or Count;
   end;
end; // SetCountToKeyElement


//------------------------------------------------------------------------------
// return true if key value equal to the key value extracted from hash
// HashKey - key stored in Key elements (format XXYY, where XX - key bits, YY - count bits)
// HashValue - full hash value
//------------------------------------------------------------------------------
function TSQLMemHashArray.IsHashKeysEqual(
          const     HashValue: TSQLMemRecordHashValue;     // Hash value
          const     HashKey:   TSQLMemRecordHashValue     // Hash key value
        ): Boolean;
begin
  if (@FIsHashKeysEqualPtr <> nil) then
   Result := FIsHashKeysEqualPtr(HashValue,HashKey)
  else
   begin
    Result := (((HashKey shl FKeyStartBitNo)
               xor
               (HashValue and FKeyMask)) = 0);
   end;
end; // IsHashKeysEqual


//------------------------------------------------------------------------------
// initialization of FKeyData
//------------------------------------------------------------------------------
procedure TSQLMemHashArray.Init;
var i:            Cardinal;
    keyPtr, buf:  PAnsiChar;
    key:          TSQLMemRecordHashValue;
begin
 if (FKeyStartBitNo = 0) then
  FKeyMask := ($FFFFFFFF shl FKeySize)
 else
 if (FKeyStartBitNo = (SQLMem_MAX_HASH_KEY_SIZE-1)) then
  FKeyMask := ($FFFFFFFF shr FKeySize)
 else
  FKeyMask := ($FFFFFFFF xor ((FMaxKeyCount) shl FKeyStartBitNo));
 FKeyMask := not FKeyMask;
 keyPtr := FKeyData;
 i := 0;
 while (i <= FMaxKeyCount) do
   begin
    // format XXYY, where XX - key bits, YY - count bits
    key := (i shl (SQLMem_MAX_HASH_KEY_SIZE - FKeySize));
    Move(key,keyPtr^,SQLMem_HASH_VALUE_SIZE);
    Inc(i);
    Inc(keyPtr,FKeyElementSize);
   end;
end; // Init


//------------------------------------------------------------------------------
// return true if hash value found in value element buffer
//------------------------------------------------------------------------------
function TSQLMemHashArray.FindHashValue(
              const buf: PAnsiChar;
              const numElements: Cardinal;
              const HashValue: TSQLMemRecordHashValue
               ): Boolean;
var ptr: PAnsiChar;
    i:   Cardinal;
begin
 Result := False;
 i := 0;
 ptr := buf;
 while (i < numElements) do
  begin
   if (PSQLMemRecordHashValue(ptr)^ = HashValue) then
    begin
     Result := True;
     Exit;
    end;
   Inc(i);
   Inc(ptr,FValueElementSize);
  end;
end; // FindHashValue


//------------------------------------------------------------------------------
// debug
//------------------------------------------------------------------------------
procedure TSQLMemHashArray.WriteStats;
begin
{$IFDEF DEBUG_LOG_HASH_ARRAY}
  aaWriteToLog(#13#10+'TSQLMemHashArray.Destroy: Total memory used = '+#13#10+IntToStr(FTotalMemAllocated)
+#13#10+'TSQLMemHashArray.Destroy: Key memory used = '+#13#10+IntToStr(FKeyMemAllocated)
+#13#10+'TSQLMemHashArray.Destroy: Data memory used = '+#13#10+IntToStr(FDataMemAllocated)
+#13#10+'TSQLMemHashArray.Destroy: ReallocMem count = '+#13#10+IntToStr(FReallocMemCount)
+#13#10+'TSQLMemHashArray.Destroy: Key element count = '+#13#10+IntToStr(FKeyElementCount)
+#13#10+'TSQLMemHashArray.Destroy: Value element count = '+#13#10+IntToStr(FValueElementCount)
+#13#10+'TSQLMemHashArray.Destroy: Maximum key count = '+#13#10+IntToStr(FMaxKeyCount));
{$ENDIF}
end; // WriteStats


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemHashArray.Create(
                  DataSize:       Integer;
                  AllocBy:        Integer;
                  KeyStartBitNo:  Integer;
                  KeySize:        Integer
                      );
var bufSize: Cardinal;
begin
  if ((KeySize <= 0) or (KeySize >= SQLMem_MAX_HASH_KEY_SIZE)) then
   raise ESQLMemException.Create(11662,ErrorLInvalidKeySize,[KeySize,SQLMem_MAX_HASH_KEY_SIZE]);
  FDataSize := DataSize;
  FAllocBy := AllocBy;
  FKeyStartBitNo := KeyStartBitNo;
  FKeySize := KeySize;
  FKeyMemAllocated := 0;
  FTotalMemAllocated := 0;
  FDataMemAllocated := 0;
  FKeyElementCount := 0;
  FValueElementCount := 0;
  FKeyElementSize := SQLMem_HASH_VALUE_SIZE + SQLMem_POINTER_SIZE; // 8
  FValueElementSize := SQLMem_HASH_VALUE_SIZE + FDataSize;
  FPageSize := FAllocBy * FValueElementSize;
  FMaxKeyCount := ((1 shl FKeySize) - 1);
  FMaxElementCount := (1 shl (SQLMem_MAX_HASH_KEY_SIZE - FKeySize));
  bufSize := (FMaxKeyCount+1) * FKeyElementSize;
  FKeyData := MemoryManager.AllocMem(bufSize);
  Inc(FKeyMemAllocated,bufSize);
  Inc(FTotalMemAllocated,bufSize);
  FGetHashKeyPtr := nil;
  FGetCountFromHashKeyPtr := nil;
  FSetCountToHashKeyPtr := nil;
  FIsHashKeysEqualPtr := nil;
  FReallocMemCount := 0;
  Init;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemHashArray.Destroy;
var i, offset:    Cardinal;
    keyPtr, buf:  PAnsiChar;
begin
{$IFDEF DEBUG_LOG_HASH_ARRAY}
 WriteStats;
{$ENDIF}

  keyPtr := PAnsiChar(FKeyData+SQLMem_HASH_VALUE_SIZE);
  i := 0;
  try
    while (i <= FMaxKeyCount) do
     begin
      Move(keyPtr^,buf,SQLMem_POINTER_SIZE);
      if (buf <> nil) then
       MemoryManager.FreeAndNilMem(buf);
      Inc(i);
      Inc(keyPtr,FKeyElementSize);
     end;
  finally
   MemoryManager.FreeAndNilMem(FKeyData);
   inherited;
  end;
end; // Destroy


//------------------------------------------------------------------------------
// appends unique hash value if it is not stored yet and returns true
// returns false if hash value already exists
//------------------------------------------------------------------------------
function TSQLMemHashArray.Append(HashValue: TSQLMemRecordHashValue; Data: PAnsiChar = nil): Boolean;
var bufSize:  Cardinal;
    offset:   Cardinal;
    keyPtr:   PAnsiChar;
    buf:      PAnsiChar;
    newKey:   TSQLMemRecordHashValue;
    key:      TSQLMemRecordHashValue;
    count:    TSQLMemRecordHashValue;
begin
  // extract key from hash - XXYY, XX - key, YY - 0
  // count = 0 means 1 value element
{$IFDEF DEBUG_LOG_HASH_ARRAY}
// WriteStats;
{$ENDIF}
  newKey := GetKeyElementFromHash(HashValue,0);
  keyPtr := FKeyData +
           ((newKey shr (SQLMem_MAX_HASH_KEY_SIZE -  FKeySize)) * FKeyElementSize);
  Move(PAnsiChar(KeyPtr+SQLMem_HASH_VALUE_SIZE)^,buf,SQLMem_POINTER_SIZE);
  // empty data
  if (Integer(buf) = 0) then
   begin
    Inc(FKeyElementCount);
    Result := true;
    // this key has no elements - let's add this element
    Move(newKey,keyPtr^,SQLMem_HASH_VALUE_SIZE);
    // allocate new buffer for value elements associated with this key
    buf := MemoryManager.GetMem(FPageSize);
    Inc(FTotalMemAllocated,FPageSize);
    Inc(FDataMemAllocated,FPageSize);
    // move pointer to new buffer to key element
    Move(buf,PAnsiChar(KeyPtr+SQLMem_HASH_VALUE_SIZE)^,SQLMem_POINTER_SIZE);
    // move hash value to first value element
    Move(HashValue,buf^,SQLMem_HASH_VALUE_SIZE);
    if (Data <> nil) then
     begin
      if (FDataSize <= 0) then
       raise ESQLMemException.Create(11665,ErrorLInvalidDataSizeSimple,[FDataSize]);
      Move(Data^,PAnsiChar(buf+SQLMem_HASH_VALUE_SIZE)^,FDataSize);
     end;
    Inc(FValueElementCount);
   end // no elememnts
  else
   begin
    // get key element
    Move(KeyPtr^,key,SQLMem_HASH_VALUE_SIZE);
    // actual count = count + 1
    count := GetCountFromKeyElement(key)+1;
    Result := not FindHashValue(buf,count,HashValue);
    if (Result) then
     begin
      // this key already has some element, add this element to the end
      bufSize := MemoryManager.GetMemoryBufferSize(buf);
      // extend buffer if necessary
      if ((count+1) * FValueElementSize > bufSize) then
       begin
        MemoryManager.ReallocMem(buf,bufSize+FPageSize);
        Move(buf,PAnsiChar(KeyPtr+SQLMem_HASH_VALUE_SIZE)^,SQLMem_POINTER_SIZE);
        Inc(FReallocMemCount);
        Inc(FTotalMemAllocated,FPageSize);
        Inc(FDataMemAllocated,FPageSize);
       end;
      // move hash value to the value element
      offset := count * FValueElementSize;
      Move(HashValue,PAnsiChar(buf+offset)^,SQLMem_HASH_VALUE_SIZE);
      if (Data <> nil) then
       begin
        if (FDataSize <= 0) then
         raise ESQLMemException.Create(11665,ErrorLInvalidDataSizeSimple,[FDataSize]);
        Inc(offset,SQLMem_HASH_VALUE_SIZE);
        Move(Data^,PAnsiChar(buf + offset)^,FDataSize);
       end;
      // get new key
      key := SetCountToKeyElement(key,count);
      // store updated key element with new count
      Move(key,KeyPtr^,SQLMem_HASH_VALUE_SIZE);
      Inc(FValueElementCount);
     end;
   end; // elements exists
end; // Append




////////////////////////////////////////////////////////////////////////////////
//
// used for storing object names
// optimized for fast load / save 
//
// Buffer format:
// | FItemCount | FSize | Item 0 | .... | Item N |
//
// Item format:
// | NameLength in bytes | Name |
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return number of elements
//------------------------------------------------------------------------------
function TSQLMemObjectNameArray.GetItemCount: Integer;
begin
  Result := FItemOffsets.ItemCount;
end; // GetItemCount


//------------------------------------------------------------------------------
// set wide string
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.SetString(ItemIndex: Integer; Name: WideString);
var NextOffset, NextItemNo, OldSize, Delta, Size, Offset, OldLen, Len: Integer;
begin
  if ((ItemIndex >= 0) and (ItemIndex < FItemOffsets.ItemCount)) then
   begin
    // extend buffer
    Len := Length(Name) * 2;
    Offset := FItemOffsets.Items[ItemIndex];
    Move(PInteger(FBuffer+Offset)^,OldLen,SizeOf(Integer));
    if (OldLen = Len) then
     begin
      if (Len > 0) then
       Move(Pointer(@Name[1])^,Pointer(FBuffer + Offset + SizeOf(integer))^,Len);
     end // Len = OldLen
    else
     begin
      Move(PInteger(FBuffer)^,OldSize,SizeOf(Integer));
      if (Len > OldLen) then
       begin
        Delta := Len - OldLen;
        Size := OldSize + Delta;
        InternalSetSize(Size);
        if (ItemIndex < (FItemOffsets.ItemCount-1)) then
         begin
          NextItemNo := ItemIndex+1;
          NextOffset := FItemOffsets.Items[NextItemNo];
          Move(Pointer(FBuffer+NextOffset)^,Pointer(FBuffer+NextOffset+Delta)^,
               OldSize-NextOffset);
          UpdateOffsets(NextItemNo,Delta);
         end;
        Move(Pointer(@Name[1])^,Pointer(FBuffer + Offset + SizeOf(integer))^,Len);
       end // Len > OldLen
      else
      if (Len < OldLen) then
       begin
        // shrink buffer
        Delta := OldLen-Len;
        Size := OldSize - Delta;
        if (ItemIndex < (FItemOffsets.ItemCount-1)) then
         begin
          NextItemNo := ItemIndex+1;
          NextOffset := FItemOffsets.Items[NextItemNo];
          Move(Pointer(FBuffer+NextOffset)^,Pointer(FBuffer+NextOffset-Delta)^,
               OldSize-NextOffset);
          UpdateOffsets(NextItemNo,-Delta);
         end;
        InternalSetSize(Size);
        if (Len > 0) then
         Move(Pointer(@Name[1])^,Pointer(FBuffer + Offset + SizeOf(integer))^,Len);
       end; // Len < OldLen
      Move(Len,PInteger(FBuffer+Offset)^,SizeOf(Integer));
     end; // Len <> OldLen
   end;
end; // SetItemUnicode


//------------------------------------------------------------------------------
// return Ansi string
//------------------------------------------------------------------------------
function TSQLMemObjectNameArray.GetString(ItemIndex: Integer): WideString;
var Offset, Len: Integer;
begin
  Result := '';
  if ((ItemIndex >= 0) and (ItemIndex < FItemOffsets.ItemCount)) then
   begin
    Offset := FItemOffsets.Items[ItemIndex];
    Move(PInteger(FBuffer+Offset)^,Len,SizeOf(Integer));
    if (Len > 0) then
      begin
        SetLength(Result,Len div 2);
        Inc(Offset,SizeOf(Integer));
        Move(PInteger(FBuffer+Offset)^,Pointer(@Result[1])^,Len);
      end;
   end;
end; // GetItemUnicode


//------------------------------------------------------------------------------
// set size
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.InternalSetSize(NewSize: Integer);
var Size, Delta, ReallocDelta: Integer;
begin
  Move(PInteger(FBuffer)^,Size,SizeOf(Integer));
  if (NewSize = Size) then
   Exit;
  if (NewSize > FAllocatedSize) then
   begin
{$IFDEF DEBUG_TRACE_TSQLMemObjectNameArray_Add}
aaStopTime(time2);
aaIncCounter(counter2);
{$ENDIF}
    // we must realloc memory
    Delta := NewSize - FAllocatedSize;
    case NewSize of
      0..127:               ReallocDelta := 128;
      128..511:             ReallocDelta := 256;
      512..1023:            ReallocDelta := 512;
      1024..5*1024-1:       ReallocDelta := 1024;
      5*1024..50*1024-1:    ReallocDelta := 5*1024;
      50*1024..100*1024:    ReallocDelta := 10*1024;
     else
                            ReallocDelta := 100*1024; // 100 Kb
    end;
    if (ReallocDelta < Delta) then
      ReallocDelta := Delta;
    Inc(FAllocatedSize,ReallocDelta);
    MemoryManager.ReallocMem(FBuffer,FAllocatedSize);
{$IFDEF DEBUG_TRACE_TSQLMemObjectNameArray_Add}
aaStopTime(time2);
{$ENDIF}
   end; // we must realloc memory to add new strings
  if (NewSize < Size) then
   begin
    Delta := FAllocatedSize-NewSize;
    // if 10% not used - reallocate
    if (Delta > (FAllocatedSize div 10)) then
     begin
      FAllocatedSize := NewSize;
      MemoryManager.ReallocMem(FBuffer,FAllocatedSize);
     end;
   end;
  Move(NewSize,FBuffer^,SizeOf(Integer));
end; // InternalSetSize


//------------------------------------------------------------------------------
// update offsets
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.UpdateOffsets(StartItemIndex,Delta: Integer);
var i: Integer;
begin
  for i := StartItemIndex to FItemOffsets.ItemCount-1 do
   Inc(FItemOffsets.Items[i],Delta);
end; // UpdateOffsets


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemObjectNameArray.Create;
begin
  Clear;
  FItemOffsets := TSQLMemIntegerArray.Create;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemObjectNameArray.Destroy;
begin
  MemoryManager.FreeAndNilMem(FBuffer);
  FItemOffsets.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.Clear;
begin
  if (FBuffer <> nil) then
   MemoryManager.FreeAndNilMem(FBuffer);
  FAllocatedSize := SizeOf(Integer)*2;
  FBuffer := MemoryManager.AllocMem(FAllocatedSize);
  Move(FAllocatedSize,FBuffer^,SizeOf(Integer));
end; // Clear


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.Assign(Source: TSQLMemObjectNameArray);
begin
  if (Source is TSQLMemObjectNameArray) then
  begin
   if (Source.Count <= 0) then
    Clear
   else
   begin
      if (FBuffer <> nil) then
       MemoryManager.FreeAndNilMem(FBuffer);
      FAllocatedSize := Source.FAllocatedSize;
      FBuffer := MemoryManager.AllocMem(FAllocatedSize);
      Move(Source.FBuffer^,FBuffer^,FAllocatedSize);
      FItemOffsets.SetSize(Source.FItemOffsets.ItemCount);
      Move(Source.FItemOffsets.Items[0],FItemOffsets.Items[0],Source.Count*SizeOf(Source.FItemOffsets.Items[0]));
   end;
  end;
end; // Assign


//------------------------------------------------------------------------------
// add element and return its number
//------------------------------------------------------------------------------
function TSQLMemObjectNameArray.Add(const Name: WideString): Integer;
var ItemCount, ItemNo, Offset, Size, NewSize, Len, Delta: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemObjectNameArray_Add}
aaStartTime(time1);
{$ENDIF}
  Len := Length(Name) * 2;
  Size := PInteger(FBuffer)^;
  NewSize := Size + SizeOf(Integer) + Len;
  InternalSetSize(NewSize);
{$IFDEF DEBUG_TRACE_TSQLMemObjectNameArray_Add}
aaStopTime(time3);
aaIncCounter(counter3);
{$ENDIF}
  // move new name to the end of buffer
  ItemCount := FItemOffsets.ItemCount;
  if (ItemCount = 0) then
   begin
    Inc(ItemCount);
    ItemNo := 0;
    FItemOffsets.SetSize(1);
    Offset := SizeOf(Integer) * 2;
   end
  else
   begin
    ItemNo := ItemCount;
    Inc(ItemCount);
    FItemOffsets.SetSize(ItemCount);
    Offset := FItemOffsets.Items[ItemNo-1];
    Delta := SizeOf(Integer) + PInteger(FBuffer+Offset)^;
    Inc(Offset,Delta);
   end;
  FItemOffsets.Items[ItemNo] := Offset;
  Move(Len,PAnsiChar(FBuffer+Offset)^,SizeOf(Integer));
  if (Len > 0) then
    Move(Pointer(@Name[1])^,PAnsiChar(FBuffer+Offset+SizeOf(Integer))^,Len);
  Move(ItemCount,PInteger(FBuffer+SizeOf(Integer))^,SizeOf(Integer));
{$IFDEF DEBUG_TRACE_TSQLMemObjectNameArray_Add}
aaStopTime(time3);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemObjectNameArray_Add}
aaStopTime(time1);
{$ENDIF}
end; // Add


//------------------------------------------------------------------------------
// delete element
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.Delete(ItemIndex: Integer);
var ItemCount, NextOffset, NextItemNo, Delta, Offset, NewSize, Size, Len: Integer;
begin
  Move(PInteger(FBuffer+SizeOf(Integer))^,ItemCount,SizeOf(Integer));
  if ((ItemIndex >= 0) and (ItemIndex < FItemOffsets.ItemCount) and (ItemCount > 0)) then
   begin
    Offset := FItemOffsets.Items[ItemIndex];
    Move(PInteger(FBuffer+Offset)^,Len,SizeOf(Integer));
    Delta := SizeOf(Integer) + Len;
    Move(PInteger(FBuffer)^,Size,SizeOf(Integer));
    if (ItemIndex < (FItemOffsets.ItemCount-1)) then
     begin
      // move next items
      NextItemNo := ItemIndex+1;
      NextOffset := FItemOffsets.Items[NextItemNo];
      NewSize := Size - NextOffset;
      Move(Pointer(FBuffer+NextOffset)^,Pointer(FBuffer+Offset)^,NewSize);
      FItemOffsets.Delete(ItemIndex);
      if (ItemIndex < FItemOffsets.ItemCount) then
       UpdateOffsets(ItemIndex,-Delta);
     end
    else
     FItemOffsets.Delete(ItemIndex);
    NewSize := Size - Delta;
    InternalSetSize(NewSize);
    Dec(ItemCount);
    Move(ItemCount,PInteger(FBuffer+SizeOf(Integer))^,SizeOf(Integer));
   end;
end; // Delete


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
function TSQLMemObjectNameArray.SaveToStream(Stream: TStream; CountSize: Boolean = False): Integer;
begin
  if (CountSize) then
   Result := PInteger(FBuffer)^
  else
   SaveDataToStream(FBuffer^,PInteger(FBuffer)^,Stream,11954);
end; // SaveToStream


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemObjectNameArray.LoadFromStream(Stream: TStream);
var i,Offset,Size,ItemCount: Integer;
begin
  LoadDataFromStream(Size,SizeOf(Integer),Stream,11955);
  if (Size <= 0) then
   begin
    Size := 0;
    FAllocatedSize := SizeOf(Integer) * 2;
    MemoryManager.ReallocMem(FBuffer,FAllocatedSize);
    FillChar(FBuffer^,FAllocatedSize,$00);
    Move(FAllocatedSize,FBuffer^,SizeOf(Integer));
    FItemOffsets.SetSize(0);
   end
  else
   begin
    FAllocatedSize := Size;
    MemoryManager.ReallocMem(FBuffer,FAllocatedSize);
    Move(Size,FBuffer^,SizeOf(Integer));
    LoadDataFromStream(Pointer(FBuffer+SizeOf(Integer))^,Size-SizeOf(Integer),Stream,11956);
    Move(PInteger(FBuffer+SizeOf(Integer))^,ItemCount,SizeOf(Integer));
    FItemOffsets.SetSize(ItemCount);
    if (ItemCount > 0) then
     FItemOffsets.Items[0] := SizeOf(Integer) * 2;
    for i := 1 to ItemCount-1 do
     begin
      Offset := FItemOffsets.Items[i-1];
      FItemOffsets.Items[i] := Offset + PInteger(FBuffer+Offset)^ + SizeOf(Integer);
     end;
   end;
end; // LoadFromStream



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemWideStringList
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set size (number of strings)
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.SetSize(NewSize: Integer);
var i: Integer;
begin
 if (NewSize = 0) then
  begin
   for i := 0 to FItemCount-1 do
    SQLMemClearString(FItems[i],True);
   FItemCount := 0;
   FAllocItemCount := 0;
   FItems := nil;
   Exit;
  end;
 if (NewSize > FAllocItemCount) then
  begin
     FAllocBy := FAllocBy * 2;
     if (FAllocBy > FMaxAllocBy) then
      FAllocBy := FMaxAllocBy;
     if (FAllocItemCount + FAllocBy > NewSize) then
      FAllocItemCount := FAllocItemCount + FAllocBy
     else
      FAllocItemCount := NewSize;
     SetLength(FItems,FAllocItemCount);
  end
 else
  if (NewSize < FItemCount) then
   if (FAllocItemCount-NewSize > FdeAllocBy) then
    begin
     for i := NewSize to FItemCount-1 do
      SQLMemClearString(FItems[i],True);
     FdeAllocBy := FdeAllocBy * 2;
     if (FdeAllocBy > FMaxAllocBy) then
      FdeAllocBy := FMaxAllocBy;
     SetLength(FItems,NewSize);
     FAllocItemCount := NewSize;
    end;
 FItemCount := NewSize;
end; // SetSize


//------------------------------------------------------------------------------
// get string
//------------------------------------------------------------------------------
function TSQLMemWideStringList.InternalGetStrings(Index: Integer): WideString;
begin
 if ((Index >= 0) and (Index < FitemCount)) then
  Result := Fitems[Index]
 else
  Result := '';
end; // GetStrings


//------------------------------------------------------------------------------
// set string
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.InternalSetStrings(Index: Integer; const Value: WideString);
begin
 if ((Index >= 0) and (Index < FitemCount)) then
  begin
   SQLMemClearString(Fitems[Index],True);
   FItems[Index] := Value;
   if (not FUnicode) then
    FUnicode := SQLMemIsUnicodeString(Value);
  end;
end; // SetStrings


//------------------------------------------------------------------------------
// get text
//------------------------------------------------------------------------------
function TSQLMemWideStringList.InternalGetText: WideString;
var
    i, tSize, l: Integer;
    p:           PWideChar;
    s:           WideString;
begin
  tSize := 0;
  for i := 0 to FItemCount - 1 do
    Inc(tSize, Length(FItems[I]) + (WCrlfLength shr 1));
  SetLength(Result, tSize);
  p := Pointer(Result);
  for i := 0 to FItemCount - 1 do
   begin
    s := FItems[i];
    l := Length(s);
    if (l > 0) then
     begin
      Move(Pointer(s)^, p^, l * 2);
      Inc(p, l);
     end;
    Move(Pointer(WCrlf)^, p^, WCrlfLength);
    Inc(p, (WCrlfLength shr 1));
   end;
//aaWriteToLog('< TSQLMemWideStringList.InternalGetText, Result = '+Result);
end; // InternalGetText


//------------------------------------------------------------------------------
// set text
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.InternalSetText(const Value: WideString);
var
    i, l, len:  Integer;
    p,ps,pd:    PWideChar;
    s:          WideString;
begin
//aaWriteToLog('> TSQLMemWideStringList.InternalSetText, Value = '+Value);
  SetSize(0);
  if (Length(Value) <= 0) then
   Exit;
  p := Pointer(Value);
  if (p = nil) then
    raise ESQLMemException.Create(11948,ErrorLNilPointer);
  len := Length(Value);
  i := 0;
  while (i < len) do
   begin
    ps := p;
    while ((p^ <> #0) and (p^ <>  #10) and (p^ <> #13)) do
     Inc(p);
    l := p-ps;
    SetLength(s,l);
    Inc(i,l);
    pd := Pointer(s);
    if (l > 0) then
     Move(ps^,pd^,l * 2);
    InternalAdd(s);
    SQLMemClearString(s,True);
    if (p^ = #13)  then
     begin
       Inc(p);
       Inc(i);
     end;
    if (p^ = #10) then
     begin
       Inc(p);
       Inc(i);
     end;
    if (p^ = #0) then
     begin
       Inc(p);
       Inc(i);
     end;
   end;
  FUnicode := SQLMemIsUnicodeString(Value);
end; // InternalSetText


//------------------------------------------------------------------------------
// get string
//------------------------------------------------------------------------------
function TSQLMemWideStringList.GetStrings(Index: Integer): WideString;
begin
 Lock(False);
 try
   Result := InternalGetStrings(Index);
 finally
   Unlock;
 end;
end; // GetStrings


//------------------------------------------------------------------------------
// set string
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.SetStrings(Index: Integer; const Value: WideString);
begin
 try
   Lock(True);
   try
     InternalSetStrings(Index,Value);
   finally
     Unlock;
   end;
 finally
   DoOnChange;
 end;
end; // SetStrings


//------------------------------------------------------------------------------
// get text
//------------------------------------------------------------------------------
function TSQLMemWideStringList.GetText: WideString;
begin
 Lock(False);
 try
  Result := InternalGetText;
 finally
   Unlock;
 end;
end; // GetText


//------------------------------------------------------------------------------
// set text
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.SetText(const Value: WideString);
begin
 try
   Lock(True);
   try
     InternalSetText(Value);
   finally
     Unlock;
   end;
  finally
    DoOnChange;
  end;
end; // SetText


//------------------------------------------------------------------------------
// call OnChange event if set
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.DoOnChange;
begin
  if (Assigned(FOnChange)) then
   FOnChange(Self);
end; // DoOnChange


//------------------------------------------------------------------------------
// internal add
//------------------------------------------------------------------------------
function TSQLMemWideStringList.InternalAdd(const Value: WideString): Integer;
begin
//aaWriteToLog('TSQLMemWideStringList.InternalAdd, Value = '+Value);
  Result := FItemCount;
  SetSize(FItemCount+1);
  FItems[Result] := Value;
end; // InternalAdd


//------------------------------------------------------------------------------
// delete element by index
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.InternalDelete(Index: Integer);
var bCheckUnicode: Boolean;
begin
  bCheckUnicode := False;
  if ((Index >= 0) and (Index < FitemCount)) then
  begin
    if (FUnicode) then
      if (SQLMemIsUnicodeString(FItems[Index])) then
        bCheckUnicode := True;
    SQLMemClearString(FItems[Index],True);
    if (Index = (FItemCount-1)) then
      SetSize(Index)
    else
     begin
      Move(FItems[Index+1],FItems[Index],(FItemCount - Index - 1) * SizeOf(WideString));
      // fixed in v.5.60
      Dec(FItemCount);
     end;
  end;
  if (bCheckUnicode) then
  FUnicode := SQLMemIsUnicodeString(GetText);
end; // InternalDelete


//------------------------------------------------------------------------------
// internal add if not exists
//------------------------------------------------------------------------------
function TSQLMemWideStringList.InternalIndexOf(const Value: WideString): Integer;
var i: Integer;
{$IFDEF DEBUG_LOG}
{DEFINE DEBUG_TRACE_TSQLMemWideStringList_InternalIndexOf}
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_InternalIndexOf}
aaWriteToLog('> TSQLMemWideStringList.InternalIndexOf Value = '+Value+#13#10+'FItemCount = '+IntToStr(FItemCount));
try
{$ENDIF}
  Result := -1;
  for i := 0 to FItemCount-1 do
   begin
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_InternalIndexOf}
aaWriteToLog('1. TSQLMemWideStringList.InternalIndexOf Value = '+Value+#13#10+'i = '+IntToStr(i));
aaWriteToLog('FItems[i] = '+FItems[i]);
{$ENDIF}
    if (FItems[i] = Value) then
     begin
      Result := i;
      break;
     end;
   end;
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_InternalIndexOf}
aaWriteToLog('< TSQLMemWideStringList.InternalIndexOf Value = '+Value+#13#10+'Result = '+IntToStr(Result));
except
 on e: Exception do
  begin
    aaWriteToLog('Error in TSQLMemWideStringList.InternalIndexOf Value = '+Value+#13#10+e.Message);
    raise;
  end;
end;
{$ENDIF}
end; // InternalIndexOf


//------------------------------------------------------------------------------
// quick sort
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.DoQuickSort(min,max: Integer);

var i,j,p: Integer;
    str:   WideString;
begin
  if (FItemCount <= 1) then
   Exit;
  // QuickSort
  repeat
    i := min;
    j := max;
    p := (min + max) shr 1;
    repeat
      while (SQLMemCompareWideString(FItems[i],FItems[p]) < 0) do
        Inc(i);
      while (SQLMemCompareWideString(FItems[j],FItems[p]) > 0) do
        Dec(j);
      if (i <= j) then
       begin
        if (i <> j) then
         begin
          // swap elements
          str := FItems[i];
          FItems[i] := FItems[j];
          FItems[j] := str;
         end;
        if (p = i) then
          p := j
        else
        if (p = j) then
          p := i;
        Inc(i);
        Dec(j);
       end;
    until (i > j);
    if (min < j) then
     begin
      // check infinite recurse
      if (j = max) then
       raise ESQLMemException.Create(12130,ErrorLErrorSortingWideStringList,[i,j,min,max,FItemCount]);
      DoQuickSort(min,j);
     end;
    min := i;
  until (i >= max);
end; // DoQuickSort


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemWideStringList.Create(
                     Size:            Integer = 0;
                     DefaultAllocBy:  Integer = 10;
                     MaximumAllocBy:  Integer = 100
                   );
begin
  FItems := nil;
  FOnChange := nil;
  FItemCount := 0;
  FAllocItemCount := 0;
  FAllocBy := DefaultAllocBy;
  FdeAllocBy := FAllocBy;
  FMaxAllocBy := MaximumAllocBy;
  FUnicode := False;
  FThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self);
//  FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  SetSize(Size);
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemWideStringList.Destroy;
begin
  SetSize(0);
  FOnChange := nil;
  FThreadSync.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Clear;
begin
 try
   Lock(True);
   try
     SetSize(0);
   finally
     Unlock;
   end;
 finally
   DoOnChange;
 end;
end; // Clear


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Assign(Source: TPersistent);
var i: Integer;
begin
  try
   Lock(True);
   try
     if (Source = nil) then
       raise ESQLMemException.Create(11947,ErrorLNilPointer);
     if (Source is TSQLMemWideStringList) then
      begin
        if (FItemCount > 0) then
         SetSize(0);
        SetSize(TSQLMemWideStringList(Source).Count);
        for i := 0 to FItemCount-1 do
         FItems[i] := TSQLMemWideStringList(Source).Strings[i];
      end
     else
      if (Source is TStrings) then
       begin
        SetSize(TStrings(Source).Count);
        for i := 0 to FItemCount-1 do
         FItems[i] := TStrings(Source).Strings[i];
       end
     else
      raise ESQLMemException.Create(11946,ErrorLInvalidSourceObject,[IntToHex(Integer(Source),8),Source.ClassName]);
   finally
     Unlock;
   end;
 finally
   DoOnChange;
 end;
end; // Assign


//------------------------------------------------------------------------------
// add new string
//------------------------------------------------------------------------------
function TSQLMemWideStringList.Add(const Value: WideString; const bAddIfNotExists: Boolean): Integer;
{$IFDEF DEBUG_LOG}
{DEFINE DEBUG_TRACE_TSQLMemWideStringList_Add}
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('> TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True));
try
{$ENDIF}
  Result := -1;
  try
   Lock(True);
   try
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('1. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True));
{$ENDIF}
    if (bAddIfNotExists) then
     begin
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('2. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True));
{$ENDIF}
      if (InternalIndexOf(Value) < 0) then
       begin
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('2.1. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True));
{$ENDIF}
        Result := InternalAdd(Value);
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('3. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
       end;
     end
    else
     begin
      Result := InternalAdd(Value);
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('4. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
     end;
    if (not FUnicode) then
     begin
       FUnicode := SQLMemIsUnicodeString(Value);
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('5. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
     end;
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('6. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
   finally
    Unlock;
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('7. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
   end;
 finally
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('8. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
  DoOnChange;
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('9. TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
 end;
{$IFDEF DEBUG_TRACE_TSQLMemWideStringList_Add}
aaWriteToLog('< TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+'Result = '+IntToStr(Result));
except
 on e: Exception do
  begin
   aaWriteToLog('Error in  TSQLMemWideStringList.Add. Value = '+Value+#13#10+'bAddIfNotExists = '+BoolToStr(bAddIfNotExists,True)+#13#10+e.Message);
   raise;
  end;
end;
{$ENDIF}
end; // Add


//------------------------------------------------------------------------------
// delete string
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Delete(Index: Integer);
begin
  try
   Lock(True);
   try
    InternalDelete(Index);
   finally
    Unlock;
   end;
  finally
   DoOnChange;
  end;
end; // Delete


//------------------------------------------------------------------------------
// deletes first occurrence of the Value
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Remove(const Value: WideString);
var idx: Integer;
begin
 Lock(True);
 try
   idx := InternalIndexOf(Value);
   if (idx >= 0) then
    InternalDelete(idx);
 finally
   Unlock;
 end;
end; // Remove


//------------------------------------------------------------------------------
// return -1 if not found or index in the Items array
//------------------------------------------------------------------------------
function TSQLMemWideStringList.IndexOf(const Value: WideString): Integer;
begin
 Lock(False);
 try
   Result := InternalIndexOf(Value);
 finally
   Unlock;
 end;
end; // IndexOf


//------------------------------------------------------------------------------
// load text from file with Unicode file name
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TSQLMemWideStringList.LoadFromFile(const FileName: WideString);
{$ELSE}
procedure TSQLMemWideStringList.LoadFromFile(const FileName: WideString; Dummy: ByteBool);
{$ENDIF}
var fs: TSQLMemFileStream;
begin
  fs := TSQLMemFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(fs);
  finally
    fs.Free;
  end;
end; // LoadFromFile


//------------------------------------------------------------------------------
// load text from file with Ansi file name
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.LoadFromFile(const FileName: AnsiString);
var fs: TSQLMemFileStream;
begin
  fs := TSQLMemFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(fs);
  finally
    fs.Free;
  end;
end; // LoadFromFile


//------------------------------------------------------------------------------
// load text from stream
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.LoadFromStream(Stream: TStream);
var newSize:  Integer;
    s:        WideString;
    ansiS:    AnsiString;
    buf:      Pointer;
    bUnicode: Boolean;
    i:        Integer;
begin
 try
   Lock(True);
   try
    newSize := Stream.Size - Stream.Position;
    bUnicode := False;
    buf := MemoryManager.GetMem(newSize);
    try
      LoadDataFromStream(buf^,newSize,Stream,11949);
      if (newSize >= 2) then
        bUnicode := ((newSize mod 2) = 0) and
                    (PAnsiChar(buf)^ = SQLMemTextFileSignature_Unicode16[1]) and
                    (PAnsiChar(PAnsiChar(buf)+1)^ = SQLMemTextFileSignature_Unicode16[2]);
      if (bUnicode) then
       begin
        // Unicode 16 text
        i := (newSize shr 1) - 1;
        SetLength(s,i);
        Move(Pointer(PWideChar(buf)+1)^,Pointer(s)^,i shl 1);
       end
      else
       begin
        // ANSI text
        SetLength(ansiS,newSize);
        Move(buf^,Pointer(ansiS)^,newSize);
        s := WideString(ansiS);
        SQLMemClearString(ansiS,True);
       end;
     InternalSetText(s);
     SQLMemClearString(s,True);
    finally
      MemoryManager.FreeAndNilMem(buf);
    end;
   finally
    Unlock;
   end;
 finally
   DoOnChange;
 end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save text to file with Unicode file name
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TSQLMemWideStringList.SaveToFile(const FileName: WideString);
{$ELSE}
procedure TSQLMemWideStringList.SaveToFile(const FileName: WideString; Dummy: ByteBool);
{$ENDIF}
var fs: TSQLMemFileStream;
begin
  fs := TSQLMemFileStream.Create(FileName,fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end; // SaveToFile


//------------------------------------------------------------------------------
// save text to file with Ansi file name
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.SaveToFile(const FileName: AnsiString);
var fs: TSQLMemFileStream;
begin
  fs := TSQLMemFileStream.Create(FileName,fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end; // SaveToFile


//------------------------------------------------------------------------------
// save text to stream in Unicode 16
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.SaveToStream(Stream: TStream);
var s:    WideString;
    l:    Integer;
    ansi: AnsiString;
begin
 Lock(true);
 try
   if (FUnicode) then
    begin
      s := GetText;
      SaveDataToStream(Pointer(SQLMemTextFileSignature_Unicode16)^,2,Stream,11950);
      l := Length(s);
      if (l > 0) then
       begin
        // skip last CRLF
        l := (l-(WCrlfLength shr 1)) shl 1;
        SaveDataToStream(Pointer(s)^,l,Stream,11951);
       end;
    end
   else
    begin
      ansi := AnsiString(InternalGetText);
      l := Length(ansi);
      if (l > 0) then
       begin
        // skip last CRLF
        SaveDataToStream(PAnsiChar(@ansi[1])^,l,Stream,11953);
       end;
    end;
 finally
  Unlock;
 end;
end; // SaveToStream


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Lock(Exclusive: Boolean);
begin
  TSQLMemReadWriteThreadSync(FThreadSync).Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Unlock;
begin
  TSQLMemReadWriteThreadSync(FThreadSync).Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// for compatibility with TStringList
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.BeginUpdate;
begin
  Lock(True);
end; // BeginUpdate


//------------------------------------------------------------------------------
// for compatibility with TStringList
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.EndUpdate;
begin
  Unlock;
end; // EndUpdate


//------------------------------------------------------------------------------
// sort alphabetically using current locale
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.Sort;
begin
  Lock(True);
  try
    DoQuickSort(0,FItemCount-1);
  finally
    Unlock;
  end;
end; // Sort


//------------------------------------------------------------------------------
// export all strings to TSTrings descendant object
//------------------------------------------------------------------------------
procedure TSQLMemWideStringList.ExportToTstrings(Destination: TStrings);
var i: Integer;
begin
  if (Destination = nil) then
    raise ESQLMemException.Create(12110,ErrorLNilPointer);
  for i := 0 to FItemCount-1 do
    Destination.Add(FItems[i])
end; // ExportToTstrings




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCompressedStreamBlockHeadersArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemCompressedStreamBlockHeadersArray.Create;
begin
 AllocBy := 10; // default alloc
 DeAllocBy := 10; // default alloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 ItemCount := 0;
 SetSize(0);
end; // Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSQLMemCompressedStreamBlockHeadersArray.Destroy;
begin
 SetSize(0);
 inherited Destroy;
end;//Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TSQLMemCompressedStreamBlockHeadersArray.SetSize(NewSize: Int64);
begin
 if (NewSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Positions := nil;
   Exit;
  end;

 if (NewSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > NewSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := NewSize;
     SetLength(Items,allocItemCount);
     SetLength(Positions,allocItemCount);
  end
 else
  if (NewSize < ItemCount) then
   if (allocItemCount-NewSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,NewSize);
     SetLength(Positions,NewSize);
     allocItemCount := NewSize;
    end;
 ItemCount := NewSize;
end;// SetSize


//------------------------------------------------------------------------------
// Finds block containing specified position in user data
//------------------------------------------------------------------------------
function TSQLMemCompressedStreamBlockHeadersArray.FindPosition(Pos: Int64) : Integer;
var i,dx,f,
    oldRes,res: Int64;

 function Compare: Integer;
 begin
  //---------------------------- start of compare -----------------------------------
       // by parent
       if (Positions[i] = pos) then
        Result := 0
       else
        if (Positions[i] < pos) then
         Result := 1
        else
         Result := -1;
  //---------------------------- end of compare -----------------------------------
 end;

begin

 i := ItemCount shr 1;
 dx := i;
 Result := 0;
 if (ItemCount <= 0) then
  begin
   Result := 0;
   Exit;
  end;
  f := 0;
  res := 2;
  while (true) do
   begin
    dx := dx shr 1;
    if (dx < 1) then dx := 1;
     oldRes := res;
     // compare, ascending
     res := Compare;
    if (res < 0) then
     begin
      //  element, specified by value should be higher then current element (+->0)
      i := i - dx;
     end
    else
    if (res > 0) then
     begin
      //  element, specified by value should be lower then current element (+->0)
      i := i + dx;
     end
    else
     begin
      // values are equal
      Result := i;
      break;
     end;
    if  (i < 0) and (dx = 1) then
     begin
      // equal not found
      Result := 0;
      break;
     end;
    if  (i > ItemCount-1) and (dx = 1) then
     begin
      // equal not found
      Result := ItemCount;
      break;
     end;

    if  (i > ItemCount-1) then
     i := ItemCount-1;
    if  i < 0 then
     i := 0;

    if (dx = 1) and (f > 1) then
     begin
      // dx minimum
      // compare, ascending
      res := Compare;
      if (res < 0) and (oldRes > 0) then
       Result := i;
      if (res > 0) and (oldRes < 0) then
       Result := i+1;
      if (res = oldRes) then
       continue;
      break;
     end;// last step
    if (res <> oldRes) and (dx = 1) and (oldRes <> 2) then
     inc(f);
  end;//while dx
 if (Result >= ItemCount) then
     Result := ItemCount-1;
 if (Result > 0) then
  if (Positions[Result] > pos) then
   dec(Result);
 if (Result < 0) then
   Result := 0;
end; //FindPosition


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TSQLMemCompressedStreamBlockHeadersArray.AppendItem(Value: TSQLMemCompressedStreamBlockHeader; Pos: Int64);
begin
 Inc(ItemCount);
 SetSize(ItemCount);
 Items[ItemCount-1] := value;
 Positions[ItemCount-1] := pos;
end; // AppendItem


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBitsArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return number of bits = 1
//------------------------------------------------------------------------------
function TSQLMemBitsArray.GetNonZeroBitCount: Integer;
var i: Integer;
begin
 Result := 0;
 if (FBitCount > 0) then
  for i := 0 to FBitCount - 1 do
   if (GetBit(i)) then
    Inc(Result);
end; // GetNonZeroBitCount


//------------------------------------------------------------------------------
// set new size
//------------------------------------------------------------------------------
procedure TSQLMemBitsArray.SetSize(NewSize: Integer);
var
  SizeInBytes: Integer;
begin
  SizeInBytes := (NewSize div 8) + Integer((NewSize mod 8) > 0);
  if (NewSize = 0) then
   begin
    if (FBits <> nil) then
     MemoryManager.FreeAndNilMem(FBits);
    FNonZeroBitCount := 0;
   end // empty array
  else
   begin
    if (FBits = nil) then
     FBits := MemoryManager.AllocMem(SizeInBytes)
    else
     MemoryManager.ReallocMemAndClearTail(FBits, SizeInBytes);
   end;// not empty array
  if (NewSize < FBitCount) then
   begin
    if (NewSize = 0) then
     FNonZeroBitCount := 0
    else
     begin
      FBitCount := NewSize;
      FNonZeroBitCount := GetNonZeroBitCount;
     end;
   end;
  FBitCount := NewSize;
end;// SetSize


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemBitsArray.LoadFromStream(Stream: TStream);
var aBitsSize: Integer;
begin
 LoadDataFromStream(FBitCount,Sizeof(FBitCount),Stream,10401);
 LoadDataFromStream(FNonZeroBitCount,Sizeof(FNonZeroBitCount),Stream,10426);
 SetSize(FBitCount);
 if (FBitCount > 0) then
  begin
   aBitsSize := FBitCount div 8;
   if ((FBitCount mod 8) > 0) then
    Inc(aBitsSize);
   LoadDataFromStream(FBits^,aBitsSize,Stream,10402);
  end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemBitsArray.SaveToStream(Stream: TStream);
var aBitsSize: Integer;
begin
 SaveDataToStream(FBitCount,Sizeof(FBitCount),Stream,10398);
 SaveDataToStream(FNonZeroBitCount,Sizeof(FNonZeroBitCount),Stream,10427);
 if (FBitCount > 0) then
  begin
   if (FBits = nil) then
    raise ESQLMemException.Create(10399,ErrorLNilPointer);
   aBitsSize := FBitCount div 8;
   if ((FBitCount mod 8) > 0) then
    Inc(aBitsSize);
   SaveDataToStream(FBits^,aBitsSize,Stream,10400);
  end;
end; // SaveToStream


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemBitsArray.Create;
var
    i,c: Byte;
begin
 FBits := nil;
 SetSize(0);
 for i := 0 to 255 do
  begin
   c := 0;
   if ((i and 1) <> 0) then Inc(c);
   if ((i and 2) <> 0) then Inc(c);
   if ((i and 4) <> 0) then Inc(c);
   if ((i and 8) <> 0) then Inc(c);
   if ((i and 16) <> 0) then Inc(c);
   if ((i and 32) <> 0) then Inc(c);
   if ((i and 64) <> 0) then Inc(c);
   if ((i and 128) <> 0) then Inc(c);
   FBitsTable[i] := c;
  end;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemBitsArray.Destroy;
begin
 if (FBits <> nil) then
  MemoryManager.FreeAndNilMem(FBits);
end;// Destroy


//------------------------------------------------------------------------------
// get bit value
//------------------------------------------------------------------------------
function TSQLMemBitsArray.GetBit(BitNo: Integer): Boolean;
var
{$I SQLMem_check_null_flag_var.inc}
begin
  if (BitNo >= FBitCount) then
   raise ESQLMemException.Create(10394,ErrorLInvalidBitNo,[BitNo,FBitCount]);
  CHECK_NULL_FLAG_BitNo := BitNo;
  CHECK_NULL_FLAG_NullFlags := FBits;
  {$I SQLMem_check_null_flag.inc}
  Result := CHECK_NULL_FLAG_Result;
end;// GetBit


//------------------------------------------------------------------------------
// set bit value
//------------------------------------------------------------------------------
procedure TSQLMemBitsArray.SetBit(BitNo: Integer; Value: Boolean);
var Bit: Boolean;
{$I SQLMem_check_null_flag_var.inc}
{$I SQLMem_set_null_flag_var.inc}
begin
  if (BitNo >= FBitCount) then
   raise ESQLMemException.Create(10395,ErrorLInvalidBitNo,[BitNo,FBitCount]);
  CHECK_NULL_FLAG_BitNo := BitNo;
  CHECK_NULL_FLAG_NullFlags := FBits;
  {$I SQLMem_check_null_flag.inc}
  if (CHECK_NULL_FLAG_Result <> Value) then
   begin
    if (Value) then
     Inc(FNonZeroBitCount)
    else
     Dec(FNonZeroBitCount);
    SET_NULL_FLAG_ToSet := Value;
    SET_NULL_FLAG_BitNo := BitNo;
    SET_NULL_FLAG_NullFlags := FBits;
    {$I SQLMem_set_null_flag.inc}
   end;
end;// SetBit


//------------------------------------------------------------------------------
// returns number of bit = 1 in FBits array by bit position
//------------------------------------------------------------------------------
function TSQLMemBitsArray.GetBitNoByBitPosition(BitPosition: Integer): Integer;
var i,n:    Integer;
    b,k,l:  Byte;
begin
 if (BitPosition >= FNonZeroBitCount) then
  raise ESQLMemException.Create(10428,ErrorLInvalidBitNo,
    [BitPosition,FNonZeroBitCount]);

 if (FBitCount = FNonZeroBitCount) then
  begin
   Result := BitPosition;
   Exit;
  end;


 i := 0; // byte number
 n := 0; // bits count
 while (n <= BitPosition) do
  begin
   b := PByte(FBits + i)^;
   if (n + FBitsTable[b] > BitPosition) then
    break;
   Inc(n,FBitsTable[b]);
   Inc(i);
  end;
 Result := i * 8;
 if (Result > FBitCount) then
  raise ESQLMemException.Create(10456,ErrorLInvalidBitNo,[BitPosition,FBitCount]);
 b := PByte(FBits + i)^;
 l := 7;
 if (i = (FBitCount div 8)) then
  l := (FBitCount mod 8)-1;
 for k := 0 to l do
  begin
   if ((b and (1 shl k)) <> 0) then Inc(n);
   if (n > BitPosition) then Break;
//   if (n >= BitPosition) then Break;
   Inc(Result);
  end;
end; // GetBitNoByBitPosition


//------------------------------------------------------------------------------
// returns position of bit = 1 by bit no in FBits array
//------------------------------------------------------------------------------
function TSQLMemBitsArray.GetBitPositionByBitNo(BitNo: Integer): Integer;
var i,j:    Integer;
    b,k:      Byte;
begin
 if (BitNo >= FBitCount) then
  raise ESQLMemException.Create(10429,ErrorLInvalidBitNo,
    [BitNo,FBitCount]);
 if (FBitCount = FNonZeroBitCount) then
  begin
   Result := BitNo;
   Exit;
  end;
 Result := 0;
 i := BitNo div 8;
 for j := 0 to i-1 do
  begin
   b := PByte(FBits + j)^;
   Inc(Result,FBitsTable[b]);
  end;
 b := PByte(FBits + i)^;
 j := BitNo mod 8;
 for k := 0 to j do
  if ((b and (1 shl k)) <> 0) then
   Inc(Result);
 if (Result > 0) then
  Dec(Result);
{
 // number of byte with flags
 i := Integer(BitNo) div 8;
 Result := 0; // bits count
 if (i > 0) then
   for j := 0 to i-1 do
     for k := 7 downto 0 do
      begin
       b := PByte(FBits + j)^;
       if ((b and (1 shl k)) <> 0) then Inc(Result);
      end;
 // scan last byte
 b := PByte(FBits + i)^;
 n := Integer(BitNo) mod 8;
 for k := 0 to n do
   if ((b and (1 shl k)) <> 0) then Inc(Result);
}
end; // GetBitPositionByBitNo


//------------------------------------------------------------------------------
// set all bits to 1
//------------------------------------------------------------------------------
procedure TSQLMemBitsArray.SetAllBits;
var
    SizeInBytes: Integer;
begin
 if (FBitCount > 0) then
  begin
    SizeInBytes := (FBitCount div 8) + Integer((FBitCount mod 8) > 0);
    FillChar(FBits^,SizeInBytes,$FF);
  end;
  FNonZeroBitCount := FBitCount;
end; // SetAllBits


//------------------------------------------------------------------------------
// find any bit with specified value
//------------------------------------------------------------------------------
function TSQLMemBitsArray.Find(
                  Value:        Boolean;
                  var BitNo:    Integer
                           ): Boolean;
var i: Integer;
begin
  Result := False;
  if (FBitCount > 0) then
   for i := 0 to FBitCount-1 do
    if (GetBit(i) = Value) then
     begin
       Result := True;
       BitNo := i;
       break;
     end
end;// Find


////////////////////////////////////////////////////////////////////////////////
//
// Bits functions
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return number of records (RecordSize) that can be stored in the buffer (BufferSize)
//------------------------------------------------------------------------------
function SQLMemGetRecordCountByBufferSize(BufferSize, RecordSize: Integer): Integer;
begin
  if ((RecordSize <= 0) or (BufferSize <= 0)) then
   Result := 0
  else
   Result := BufferSize div RecordSize;
end; // SQLMemGetRecordCountByBufferSize


//------------------------------------------------------------------------------
// return true if RecordID1 = RecordID2
//------------------------------------------------------------------------------
function SQLMemIsEqualRecordID(const RecordID1, RecordID2: TSQLMemRecordID): Boolean;
begin
  Result := (RecordID1.PageNo = RecordID2.PageNo) and
            (RecordID1.PageItemNo = RecordID2.PageItemNo);
end; // SQLMemIsEqualRecordID


{$IFNDEF DEBUG_LOG}
  //------------------------------------------------------------------------------
  // aaGetTickCount
  //------------------------------------------------------------------------------
  {$IFDEF LINUX}
  function aaGetTickCount: Cardinal;
  var
    tv: timeval;
  begin
    gettimeofday(tv, nil);
    {$RANGECHECKS OFF}
    Result := int64(tv.tv_sec) * 1000 + tv.tv_usec div 1000;
  end; // aaGetTickCount
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  function aaGetTickCount: Cardinal;
  begin
    Result := Windows.GetTickCount;
  end; // aaGetTickCount
  {$ENDIF}
{$ENDIF}


//------------------------------------------------------------------------------
// return temporary name random for each thread of the process
//------------------------------------------------------------------------------
function GetTemporaryName(Prefix: AnsiString): AnsiString;
var x,x1: Cardinal;
begin
 x := Cardinal(Random(MAXINT)) xor Cardinal(aaGetTickCount);
 x1 := x xor Cardinal(Random(MAXINT)) xor Cardinal(aaGetTickCount);
 Result := Prefix + IntToStr(x1) + '_' + IntToStr(GetCurrentThreadID);
end; // GetTemporaryName


//------------------------------------------------------------------------------
// return difference, even if computer time was reset to zero once
//------------------------------------------------------------------------------
function SQLMemGetTickCountDiff(NewTime, OldTime: Cardinal): Cardinal;
const SQLMemMaxCardinal: Cardinal = $FFFFFFFF;
begin
  if (NewTime >= OldTime) then
   Result := NewTime - OldTime
  else
   Result := Cardinal((SQLMemMaxCardinal-OldTime+1)+NewTime);
end; // SQLMemGetTickCountDiff


//------------------------------------------------------------------------------
// clear string with private data (passwords, keys, etc.)
//------------------------------------------------------------------------------
procedure SQLMemClearString(var Value: AnsiString; EncryptedDBOnly: Boolean = False);
var l: Integer;
begin
 if (EncryptedDBOnly and (not SQLMem_ENCRYPTED_DB_USED)) then
  Value := ''
 else
  begin
    l := Length(Value);
    if (l > 0) then
     FillChar(Value[1],l,$FF);
    Value := '';
  end;
end; // SQLMemClearString


procedure SQLMemClearString(var Value: WideString; EncryptedDBOnly: Boolean = False);
var l: Integer;
begin
 if (EncryptedDBOnly and (not SQLMem_ENCRYPTED_DB_USED)) then
  Value := ''
 else
  begin
    l := Length(Value)*2;
    if (l > 0) then
     FillChar(Value[1],l,$FF);
    Value := '';
  end;
end; // SQLMemClearString


//------------------------------------------------------------------------------
// return text for last table operation from table state
//------------------------------------------------------------------------------
function SQLMemGetLastTableOpertaion(operation: TSQLMemLastTableOperation): WideString;
begin
  if (Integer(Operation) < Length(SQLMemLastTableOperationNames)) then
   Result := SQLMemLastTableOperationNames[Integer(Operation)]
  else
   Result := 'UNKNOWN OPERATION';
end; // SQLMemGetLastTableOpertaion


//------------------------------------------------------------------------------
// Add CRC of multiple objects to get unique overall CRC
// so ADDCRC(A,B) <> ADD CRC(B,A) in most cases
//
// 3 2 1 0
// xor
// 3 2 1 0
//------------------------------------------------------------------------------
function SQLMemAddCRC(value1,value2: Cardinal; Order: Byte): Cardinal;

 function GetByte(value: Cardinal; ByteNo: Byte): Byte;
 begin
  case ByteNo of
   0: Result := Byte(value);
   1: Result := Byte(value shr 8);
   2: Result := Byte(value shr 16);
   3: Result := Byte(value shr 24);
  end;
 end; // GetByte

begin
 case (Order mod 12) of
  // (3,2,1,0) xor (0,1,2,3)
  0: Result := ((GetByte(value1,3) xor GetByte(value2,0)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,1)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,2)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,3))
               ;
  // (3,2,1,0) xor (0,3,1,2)
  1: Result := ((GetByte(value1,3) xor GetByte(value2,0)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,3)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,1)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,2))
               ;
  // (3,2,1,0) xor (3,1,2,0)
  2: Result := ((GetByte(value1,3) xor GetByte(value2,3)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,1)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,2)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,0))
               ;
  // (3,2,1,0) xor (2,3,1,0)
  3: Result := ((GetByte(value1,3) xor GetByte(value2,2)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,3)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,1)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,0))
               ;
  // (3,2,1,0) xor (2,0,3,1)
  4: Result := ((GetByte(value1,3) xor GetByte(value2,2)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,0)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,3)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,1))
               ;
  // (3,2,1,0) xor (2,1,0,3)
  5: Result := ((GetByte(value1,3) xor GetByte(value2,2)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,1)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,0)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,3))
               ;
  // (3,2,1,0) xor (3,0,2,1)
  6: Result := ((GetByte(value1,3) xor GetByte(value2,3)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,0)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,2)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,1))
               ;
  // (3,2,1,0) xor (1,3,0,2)
  7: Result := ((GetByte(value1,3) xor GetByte(value2,1)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,3)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,0)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,2))
               ;
  // (3,2,1,0) xor (1,0,3,2)
  8: Result := ((GetByte(value1,3) xor GetByte(value2,1)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,0)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,3)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,2))
               ;
  // (3,2,1,0) xor (0,3,2,1)
  9: Result := ((GetByte(value1,3) xor GetByte(value2,0)) shl 24) or
               ((GetByte(value1,2) xor GetByte(value2,3)) shl 16) or
               ((GetByte(value1,1) xor GetByte(value2,2)) shl 8) or
                (GetByte(value1,0) xor GetByte(value2,1))
               ;
  // (3,2,1,0) xor (2,1,3,0)
  10: Result := ((GetByte(value1,3) xor GetByte(value2,2)) shl 24) or
                ((GetByte(value1,2) xor GetByte(value2,1)) shl 16) or
                ((GetByte(value1,1) xor GetByte(value2,3)) shl 8) or
                 (GetByte(value1,0) xor GetByte(value2,0))
               ;
  // (3,2,1,0) xor (1,0,2,3)
  11: Result := ((GetByte(value1,3) xor GetByte(value2,1)) shl 24) or
                ((GetByte(value1,2) xor GetByte(value2,0)) shl 16) or
                ((GetByte(value1,1) xor GetByte(value2,2)) shl 8) or
                 (GetByte(value1,0) xor GetByte(value2,3))
               ;
 end;
end; // SQLMemAddCRC


//------------------------------------------------------------------------------
// return true if string contains any Unicode characters
//------------------------------------------------------------------------------
function SQLMemIsUnicodeString(Value: WideString): Boolean;
var i, l: Integer;
    p:    PByte;
begin
  Result := False;
  l := Length(Value) * 2;
  if (l <= 0) then
   Exit;
  p := Pointer(@Value[1]);
  Inc(p);
  i := 1;
  while (i <= l) do
   begin
    if (p^ <> 0) then
     begin
      Result := True;
      Exit;
     end;
    Inc(p,2);
    Inc(i,2);
   end;
end; // SQLMemIsUnicodeString


//------------------------------------------------------------------------------
// return 0 if value1 = value2, 1 if value1 > value2, -1 if value1 < value2
//------------------------------------------------------------------------------
function SQLMemCompareTableInfo(const value1, value2: TSQLMemTableInfo): Integer;
begin
  // compare without case sensitivity
  Result := SQLMemCompareWideString(value1.TableName,value2.TableName,False);
end; // SQLMemCompareTableInfo


//------------------------------------------------------------------------------
// swap table elements
//------------------------------------------------------------------------------
procedure SQLMemSwapTableInfoElements(tablesInfo: TSQLMemTableInfoArray; index1, index2: Integer);
var temp: TSQLMemTableInfo;
begin
 if (index1 <> index2) then
  begin
    temp := tablesInfo[index1];
    tablesInfo[index1] := tablesInfo[index2];
    tablesInfo[index2] := temp;
  end;
end; // SQLMemSwapTableInfoElements


//------------------------------------------------------------------------------
// sort table info array by name case insensitive ascending (QuickSort)
//------------------------------------------------------------------------------
procedure SQLMemSortTableInfo(tablesInfo: TSQLMemTableInfoArray; min,max: Integer);
var
  i,j,p: Integer;
begin
  if (Length(tablesInfo) <= 1) then
   Exit;
  // QuickSort
  repeat
    i := min;
    j := max;
    p := (min + max) shr 1;
    repeat
      while (SQLMemCompareTableInfo(tablesInfo[i],tablesInfo[p]) < 0) do
        Inc(i);
      while (SQLMemCompareTableInfo(tablesInfo[j],tablesInfo[p]) > 0) do
        Dec(j);
      if (i <= j) then
       begin
        if (i <> j) then
         SQLMemSwapTableInfoElements(tablesInfo,i,j);
        if (p = i) then
          p := j
        else
        if (p = j) then
          p := i;
        Inc(i);
        Dec(j);
       end;
    until (i > j);
    if (min < j) then
     begin
      if (j = max) then
       raise ESQLMemException.Create(12131,ErrorLErrorSortingTableInfo,[i,j,min,max,Length(tablesInfo)]);
      SQLMemSortTableInfo(tablesInfo,min,j);
     end;
    min := i;
  until (i >= max);
end; // SQLMemSortTableInfo


function SQLMemGetTableStateAsString(const State: TSQLMemTableState): AnsiString;
begin
  Result := #13#10+'TableState = '+IntToStr(State.TableState)
            +#13#10+'LastTableOperation = '+SQLMemLastTableOperationNames[Integer(State.LastTableOperation)]
            +#13#10+'LastModificationDate = '+DateTimeToStr(State.LastModificationDate)
            +#13#10+'TableMetaDataState = '+IntToStr(State.TableMetaDataState)
            +#13#10+'TableFailureFlags = '+IntToStr(State.TableFailureFlags)
            ;
end; // SQLMemGetTableStateAsString


function SQLMemGetLockModeName(const LockType: TSQLMemLockType): AnsiString;
begin
  Result := 'Unknown';
  case LockType of
    ltX:    Result := 'ltX - Exclusive';
    ltIS:   Result := 'ltIS - Shared';
    ltS:    Result := 'ltS - Read';
    ltIRW:  Result := 'ltIRW - Transaction';
    ltRW:   Result := 'ltRW - Write';
    ltU:    Result := 'ltU - Record';
  end;
end; // SQLMemGetLockModeName


//------------------------------------------------------------------------------
// return maximum time to wait for the lock before exception will be raised
//------------------------------------------------------------------------------
function SQLMemGetMaxWaitTime(LockParams: TSQLMemLockParams): Cardinal;
begin
  if (LockParams.Delay = 0) then
    Result := LockParams.RetryCount
  else
    Result := LockParams.RetryCount * LockParams.Delay;
end; // SQLMemGetMaxWaitTime


//------------------------------------------------------------------------------
// return level 0..MaxLevel
// 0 - means 0 wait time or max wait time = 0
// higher value - more time waited for the lock
// Result / MaxLevel = dt / MaxWaitTime
//------------------------------------------------------------------------------
function SQLMemGetWaitLevel(const StartWaitTime, MaxWaitTime: Cardinal): Byte;
var	dt, levLength: Cardinal;
begin
  if (MaxWaitTime = 0) then
  begin
    Result := SQLMem_MAX_WAIT_LEVEL;
{$IFDEF DEBUG_TRACE_SQLMemGetWaitLevel}
aaWriteToLog('SQLMemGetWaitLevel' + #13#10 + 'StartWaitTime = ' + IntToStr(StartWaitTime) + #13#10 + 'MaxWaitTime = ' + IntToStr(MaxWaitTime)+ #13#10 + 'Result = ' + IntToStr(Result));
{$ENDIF}
  end
  else
  begin
    dt := SQLMemGetTickCountDiff(aaGetTickCount, StartWaitTime);
    // fixed in v.5.10
    if (dt <= 1) then
      Result := 0
    else
      if (dt >= MaxWaitTime) then
        Result := SQLMem_MAX_WAIT_LEVEL
      else
      begin
        if (MaxWaitTime <= SQLMem_MAX_WAIT_LEVEL) then
          levLength := 1
        else
          levLength := MaxWaitTime div SQLMem_MAX_WAIT_LEVEL + 1;
        Result := Byte(Cardinal(dt) div levLength);
      end;
{$IFDEF DEBUG_TRACE_SQLMemGetWaitLevel}
aaWriteToLog('SQLMemGetWaitLevel' + #13#10 + 'StartWaitTime = ' + IntToStr(StartWaitTime) + #13#10 + 'MaxWaitTime = ' + IntToStr(MaxWaitTime)
+ #13#10 + 'dt = ' + IntToStr(dt) + #13#10 + 'SQLMem_MAX_WAIT_LEVEL = ' +IntToStr(SQLMem_MAX_WAIT_LEVEL)
+ #13#10 +'dt * SQLMem_MAX_WAIT_LEVEL div MaxWaitTime = ' + IntToStr(dt * SQLMem_MAX_WAIT_LEVEL div MaxWaitTime) + #13#10 + 'Result = ' + IntToStr(Result));
{$ENDIF}
  end;
end; // SQLMemGetWaitLevel


//------------------------------------------------------------------------------
// parse field names to field names list
//------------------------------------------------------------------------------
procedure SQLMemParseFieldNames(FieldNames: WideString; FieldNamesList: TSQLMemWideStringList);
var
    i,l,s0,x:         Integer;
    fieldName:        WideString;
    wc:               WideChar;
begin
  l := Length(FieldNames);
  s0 := 1;
  i := 1;
  while (i <= l) do
  begin
    wc := FieldNames[i];
    if ((wc = ';') or (wc = ',')) then
    begin
     x := i-s0;
     if (x > 0) then
     begin
       fieldName := Trim(Copy(FieldNames,s0,x));
       FieldNamesList.Add(fieldName);
     end;
     s0 := i+1;
    end;
    Inc(i);
  end;
  if (i > l) and (s0 <= l) then
  begin
   // last symbol
   if (s0 = 1) then
    FieldNamesList.Add(FieldNames)
   else
    begin
     fieldName := Trim(Copy(FieldNames,s0,i-s0+1));
     FieldNamesList.Add(fieldName);
    end;
  end;
end; // SQLMemParseFieldNames


//------------------------------------------------------------------------------
// return maximum day number (28,29,30,31)
//------------------------------------------------------------------------------
function SQLMemGetMaxDayOfMonth(month,year: Word): Word;
begin
  if (month = 2) then
  begin
   if (IsLeapYear(year)) then
    Result := 29
   else
    Result := 28;
  end
  else
  // fix day for 30-days months
  if (month in [4,6,9,11]) then
   Result := 30
  else
   Result := 31;
end; // SQLMemGetMaxDayOfMonth


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('< SQLMemTypes initialized');
{$ENDIF}
SQLMemMaxInternalFileNotCompressedSize := SQLMemDefaultPacketSize
  - SizeOf(TSQLMemDiskPageHeader) - SizeOf(TSQLMemInternalFileHeader);
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('> SQLMemTypes initialized');
{$ENDIF}

  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
