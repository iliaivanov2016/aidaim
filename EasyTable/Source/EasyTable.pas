{$I ETblVer.inc}

{$DEFINE RECORD_ID_NAVIGATION}
unit EasyTable;

interface
{$WARNINGS OFF}
{$HINTS OFF}

//------------------------------------------------------------------------------

uses
  Math, Classes, Db, Windows, Forms, Controls, SysUtils, Dialogs, FileCtrl,
  ETblGauge, ETblBuildIndex,
 {$IFDEF D6H}
  FMTBcd, Variants, DBCommon,
 {$ENDIF}
 {$IFDEF D21H}
  System.Generics.Collections,
 {$ENDIF}
  ETblFileManage,
  ETblCommon,
  ETblExcept,
  ETblConst,
  ETblStrFunc, // contains necessary functions from QStrings,
/////////////////////////////////////////////////////
(*   QStrings 6.03.420      ( general release )    *)
(*   Quick string manipulation library             *)
(*   Copyright (C) 2000,2001 Andrew N. Driazgov    *)
(*   e-mail: andrey@asp.tstu.ru                    *)
(*   Portions (C) 2000, Sergey G. Shcherbakov      *)
(*   e-mail: mover@mail.ru, mover@rada.gov.ua      *)
(*   Last updated: January 7, 2001                 *)
/////////////////////////////////////////////////////
 ETblCipher,    // encryption library by
(*Copyright:      Hagen Reddmann  mailto:HaReddmann@AOL.COM
 Author:         Hagen Reddmann*)
 ETblFolderDialog, // directory open dialog by
(*Author:	Poul Bak*)
(*Copyright  1999-2000 : BakSoft-Denmark (Poul Bak). All rights reserved.*)
(* http://home11.inet.tele.dk/BakSoft/ *)
(*Mailto: baksoft-denmark@dk2net.dk*)
{$IFDEF NAG_SCREEN}
 Registry,
{$ENDIF}
{$IFDEF DEBUG_FLAG}
 aaDebug,
{$ENDIF}
{$IFDEF FULL_VERSION}
 ETblSQLProcessor,
{$ENDIF}
 ETblEngine;
//------------------------------------------------------------------------------

{$IFDEF RECORD_ID_NAVIGATION}
const INVALID_RECORD_ID = -1;
{$ENDIF}
type
  TCompressionLevel = (clNone, clFastest, clDefault, clMax);

  TBlobCompressionLevel = record
   Level : TCompressionLevel;
   name      : string[20];
  end;

{$IFNDEF D12H}
TRecordBuffer = PChar;
{$ENDIF}
const
   MAX_SUPPORTED_BLOB_COMPRESSION_LEVELS = 4;
   SUPPORTED_BLOB_COMPRESSION_LEVELS :
        array [1..MAX_SUPPORTED_BLOB_COMPRESSION_LEVELS] of TBlobCompressionLevel =
           (
            (Level : clNone;     name : 'NONE'),
            (Level : clFastest;  name : 'FASTEST'),
            (Level : clDefault;  name : 'DEFAULT'),
            (Level : clMax;      name : 'MAX')
           );

Type
  TaaProgressProcess = (aappImport,aappExport,aappRestructure,
                      aappRepair,aappChangeCompression,
                      aappCompactDB,aappRepairDB,
                      aappChangeEncryption, aappChangeEncryptionDB,
                      aappAddingRecords);

// log file
var logFile: TFileStream;
// max name length
const OLD_MAX_NAME_LENGTH = 20;
const MAX_NAME_LENGTH = 255;

const AutoIncOn = $F0;
const AutoIncOff = $FC;
// default blob field block size in bytes
const DEFAULT_BLOB_BLOCK_SIZE = 512;
// default blob compression
const DEFAULT_BLOB_COMPRESSION = clNone;
// file extensions
const tableFileExtension = '.dat';
const indexFileExtension = '.idx';
const blobIndexFileExtension = '.bif';
const blobDataFileExtension = '.bdf';
const DatabaseFileExtension = '.edb';
// default primary key name for table
const DEFAULT_PRIMARY_KEY_NAME = 'id';
// search
const MAX_INDEX_CHANGES = 15;
// open table errors
const TETERR_NO_ERROR = 0;
const TETERR_NO_TABLE = -1;
const TETERR_NO_PASSWORD = -2;
const TETERR_INVALID_PASSWORD = -3;
const TETERR_OPEN_FILES = -4;
const TETERR_CORRUPTED_BLOB_HEADERS = -5;

//--- TEasyDataset consts ---
const
  dbfOpened     = 0;
  dbfPrepared   = 1;
  dbfExecSQL    = 2;
  dbfTable      = 3;
  dbfFieldList  = 4;
  dbfIndexList  = 5;
  dbfStoredProc = 6;
  dbfExecProc   = 7;
  dbfProcDesc   = 8;
  dbfDatabase   = 9;
  dbfProvider   = 10;
  dbfExists     = 11;
  dbfDeleteTable= 12;

//------------------------ debug variables and methods -------------------------
const crlf = #13#10;
var startTime, stopTime : Cardinal;
    timeStarted   : Boolean = false; // if true - time is counting, else - pause
    timeRestarted : Boolean = false; // if true - restart time counting

var bDesignMode: Boolean;
// list of all database managers
var DatabaseManagerList: TList;
// list of all databasea
//var DatabaseList: TList;
// list of all data managers
var DataManagerList: TList;

// current version of the db engine (store in all tables)
var InternalCurrentVersion : double = 23.00;
// last version of the db engine, when data format was changed
var lastFormatVersion : double = 4.50;
// current version of the db engine (for visual property)
var internalCurrentVersionText : string = '';
//var internalCurrentVersionText : string = 'Prerelease version #1';


//---------------- types -----------------------------
type
  // data types
  // field header type
  FieldHeaderType = packed record
   fieldName : string[MAX_NAME_LENGTH]; // field name
   fieldType : TFieldType;  // field type
   fieldSize : Integer;     // field size in bytes
   required  : Boolean;     // if true - field value should be not null
  end;
  pFieldHeaderType = ^FieldHeaderType;
  // table header type
  TableHeaderType = packed record
   sequenceValue     : Integer; // primary key value (unique)
   sequenceName      : string[MAX_NAME_LENGTH]; // name of this key
   fieldCount        : Integer; // fields quantity
   recordCount       : Integer; // records quantity
   version	         : Double;  // version
   ShowAutoInc  	   : Byte;  	// 1 - user defined auto-inc, 0 - easytable auto-inc
   blobCompressed    : TCompressionLevel; // compression level
                                // >0 - blob fields compressed (level), 0 - not compressed
   															// (1 - clFastest, 2 - clDefault, 3 - clMax)
   cipherUsed        : Boolean; // true - cipher is used, 0 - data is not crypted
   state				     : Integer; // unique key (for synchronization)
  end;
  pTableHeaderType  = ^TableHeaderType;
  // record information type
  // field count must be <= MAX_Fields !!!
  RecordInfoType = record
   id         : Integer;  // primary key value (unique)
{
   nullValues ;  // bits corresponds null values in field
                          // if bit value = 1 then field is null
                          // lower bit is for first field, etc.

   crc32			: string[12];	// crc-32 for blob data
}
  end;
  pRecordInfoType = ^RecordInfoType;
  // bookmark information type
  BookmarkInfoType = record
   BookmarkData : Integer;        // position in table
   BookmarkFlag : TBookmarkFlag;  // bookmark flag
  end;
  pBookmarkInfoType = ^BookmarkInfoType;
  // index header type
  IndexHeaderType = packed record
   indexName 		: string[MAX_NAME_LENGTH]; 	// field name
   indexCount  	: Integer; 	 	 	// indexed fields' quantity
   indexFields	: array of Integer;
   															// index fields numbers
   indexOrders	: PAnsiChar;// bits corresponds
   												// index orders in index fields
			                    // if bit value = 1 then field is ascending
                          // lower bit is for first index field, etc.
   indexCaseIns	: PAnsiChar;// bits corresponds
   												// index orders in index fields
			                    // if bit value = 1 - string fields are compared case insensetively
                          // lower bit is for first index field, etc.
   ignoreCase   : Boolean;// if [ixCaseInsensetive] option has been specified
   descending   : Boolean;// if [ixDescending] option has been specified
   indexOptions : TIndexOptions; // index options                       
  end;
  pIndexHeaderType = ^IndexHeaderType;
  // index file header type
  IndexFileHeaderType = packed record
   state				     : Integer; // unique key (for synchronization)
   indexCount        : Integer; // index quantity
   version					 : Double;  // version
  end;
  pIndexFileHeaderType  = ^IndexFileHeaderType;
  // BLOB index file header type
  BLOBIndexFileHeaderType = packed record
   blockSize		     : Integer; // size of the block in blob data file
   numDeletedParts	 : Integer; // deleted part quantity
   fieldCount        : Integer; // BLOB fields quantity
   recordCount       : Integer; // records quantity
   version					 : Double;  // version
  end;
  // memory stream for each value and mode
  BLOBFieldType = record
   stream : TMemoryStream;
   mode		: TBLOBStreamMode;
  end;
  // search information
  SearchInfoType = record
   foundRecordPosition : Integer;	// table position for last found record
   tablePosition	: Integer;	// last index position, used by FindBase
   fieldNum       : Integer;	// field number (0..MAX_FIELDS)
   operation			: AnsiString; 	// operation ('<','>','=','<=','>=','<>'
   valueBuffer		: PAnsiChar; 		// pointer to record buffer with value
   pIndexHeader		: pIndexHeaderType; // index header (for primary index)
   indexNum				: Integer;  // index number
   ignoreCase			: Boolean;	// if true - strings are compared case insensitively
   offset					: Integer;	// offset of the field
   goForward      : Boolean;  // if true - then next record will be find, otherwise - prior record.
   reset          : Boolean;  // if true - FindFirst, else FindNext
   foundListPosition : Integer;  // position in foundVisibleRecordsList
  end;

  // Type for GetMatchedRecords return mode
  TaaGMRMode = (aagmrReturnArray, aagmrReturnCountOnly, aagmrReturnOneRecordOnly);

  //------------------ structure for keeping key data for Findkey method ------------
  TKeyIndex = (kiLookup, kiRangeStart, kiRangeEnd, kiSave);

  PKeyBuffer = ^TKeyBuffer;
  TKeyBuffer = packed record
    Modified: Boolean;
    Exclusive: Boolean;
    FieldCount: Integer;
  end;
  //------------------- end of key structure ----------------------------------------

type
  // pointers to standart data types
  pByte = ^Byte;
  pInteger = ^Integer;
  pSmallint = ^Smallint;
  pLargeInt = ^Int64;
  pWord = ^Word;
  pBoolean = ^Boolean;
  pFloat = ^Double;
  pCurrency = ^Double;
  pDateTime = ^TDateTime;
  pTETFieldType = ^TETFieldType;
  //array
  aInteger = array of Integer;
//---------------- classes -----------------------------

type
  TaaList = class (TList)
   public
    procedure Clear; override;
   end;

type
  TEasyDataset = class;
  TEasyDatabaseManager = class;


 TAddRecordsMode = (arAppend, arUpdate, arAppendUpdate, arReplace);

 // progress event
 TaaProgressEvent = procedure (
                              Sender      : TEasyDataset;
                              PercentDone : Double;
                              ProgressProcess : TaaProgressProcess)  of object;

 // progress event
 TBuildIndexesProgressEvent = procedure (
                              Sender     : 		TEasyDataset;
                              PercentDone: 		Double;
                              bStart,bFinish: Boolean
                              )  of object;

 TProgressEvent = procedure (
                              Sender: 					TComponent;
                              PercentDone: 			Double;
                              ProgressProcess: 	TaaProgressProcess;
                              var Cancel:				Boolean
                             )  of object;

  // blob stream
  TEasyBlobStream = class(TStream)
   protected
    FField: TBlobField;
    FMode: TBlobStreamMode;
    FStream : TMemoryStream;
    FModified: Boolean;
    FOpened: Boolean;
   public
    constructor Create(Field: TBlobField; Mode: TBlobStreamMode);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    procedure Truncate;
  end;

 // data manager (shareable one for each table)
 TEasyDataManager = class(TObject)
  private
     DatasetList     : TList; // datasets list
  protected
     FRepairIsRunning: Boolean; // 5.40 to avoid close table bugs

  public
     tableHeader     : TableHeaderType;	// table header
     indexFileHeader : IndexFileHeaderType;	// index file header
//     FTemporaryIndexCount: Integer;  // temporary indexes count
     tableHeaderSize : Integer;      // size of table header and all fields headers
     isTableOpened   : Boolean;      // true, if table is opened
     isBLOBUsed	     : Boolean;      // true, if blob fields exists
//     isUniqueUsed    : Boolean;      // true, if ixUnique indexes exists
     fieldHeaderList : TaaList;      // field headers list
     indexHeaderList : TaaList;      // index headers list
     blobFileHeader  : BLOBIndexFileHeaderType;	// blob file header
     FBlobCompression: TCompressionLevel; // compression levels
     FBLOBBlockSize  : Integer;       // blob block size
     FEncrypted      : Boolean;       // encrypted
     FReadOnly       : Boolean;       // read only mode
     FFilesReadOnly  : Boolean;       // table files - readonly
     FFileStoreMode  : TaaFileStoreMode; // file store mode
     FPassword       : shortString;   // this key value is used for both reading
                          // and writing data.
                          // For data encoding (decoding) this key value is
                          // hashed by Ripe Message Digest 256 method
                          // (based on MD4),
                          // and then data will be encoded (decoded)
                          // by Rijndael algorythm using that 256-bit key
     // optimization of index updating
     LastIOOpTime: integer; // time of last IO operation
     ThresholdDelay: integer; // threshold allowed delay since last operation
     ThresholdDelayNo: integer; // No of operation with large delay
     ThresholdDelayMaxCount: integer; // Max allowed count of operations with large delay
     ThresholdRecordCount: integer; // Max record count - before them indexes can be not updated
     FFlushesEnabled: Boolean; // is flush buffer log allowed?
     indexUpdated : array of Boolean; // if true then index ok
     indexChangesCount : integer;  // number of index changes
     // table data and indexes
     allRecBuffer : TaaRecordsArray;
     indexes : array of TaaIntArray; // all indexes for the table
     // files
     tableFile     : TAbstractFile; // this is a table data stream
     indexFile     : TAbstractFile; // this is an index data stream
     BLOBDataFile  : TAbstractFile; // this is a blob data stream
     BLOBIndexFile : TAbstractFile; // this is a blob index data stream
     // blob support
     blobHeaders  : TaaBLOBHeadersArray; // blob headers
     blobDelParts : TaaBLOBPartsArray;   // deleted parts
     blobMap      : TaaIntArray; // map for the blob headers
     // bufferization
     bufferLog    : TaaBufferLogArray; // optimizing disk I/O
     // offsets and buffer sizes
     recordSize      : Integer;         // record size in bytes
     bufferSize      : Integer;         // record buffer size in bytes
     fieldOffsets : aInteger; // offsets for the fields in recordBuffer
     calculatedOffset : Integer; // offsets for calc fields
     recInfoBufferSize : Integer; // size of the record ant its info
     infoBufferSize : Integer; // info buffer size
     fieldFlagsSize : Integer; // size in bytes of field flags
     recNullOffset  : Integer; // offset from the beginning of record buffer to null values
     recCrcOffset   : Integer; // offset from the beginning of record buffer to crc32
     FastOpen       : Boolean; // small pages mode
     OpenTableSucceed: Boolean; // OpenTable call succeed - (password correct)
     IsBlobConvertNeeded: boolean; // convert blobs from old version
     DesignOpenTableState: integer; // for sync at design-time
     FLockSection:      Pointer;
     FLockCount:        Integer;
     SilentMode:        Boolean;

  public
     FTableName    : AnsiString;
     DBMHandle:    TEasyDatabaseManager;
     PageRecordCount:      integer; // preallocated number of records

   // constructor
   constructor Create(TableName: AnsiString; newDBMHandle: TEasyDatabaseManager);
   // destructor
   destructor Destroy; override;
   // returns connected datasets count
   function GetDatasetCount : Integer;
   // locks (thread-safe)
   procedure LockSection;
   // unlocks section (thread-safe)
   procedure UnlockSection;

//  private
public
   // detects new file store mode
   function DetectFileStoreMode : TaaFileStoreMode;
   // set new store mode
   procedure SetFileStoreMode(newFileStoreMode: TaaFileStoreMode);
   // returns true when running in design-time
   function IsDesignMode : Boolean;
   // opens all files
   function OpenFiles(bCreate : Boolean = false): Boolean;
   // closes all files
   procedure CloseFiles;
  public
   // opens files for working at design-time
   procedure OpenFilesForDesigning;
   // closes files for working at design-time
   procedure CloseFilesForDesigning;
  private
   // intialize table
   procedure InitTable;
   // opens table
   function OpenTable(bNotDesignMode : Boolean = false): Integer;
   // closes table
   procedure CloseTable(bNotDesignMode : Boolean = false);
  public
   // if indexes are update - save them
   procedure FlushIndexesToDisk;
   // connects dataset
   function ConnectDataset(DSHandle: TEasyDataset): Integer;
   // disconnects dataset
   procedure DisconnectDataset(DSHandle: TEasyDataset);
   // close all connected datasets
   procedure CloseAllDatasets;
   // debug function
   function GetDatasetsInfo: AnsiString;

   // create table
   procedure CreateTable(
                        FieldDefs  : TFieldDefs;
                        IndexDefs : TIndexDefs;
                        AutoIndexes: Boolean;
                        PageRecordCount1: Integer
                        );
   // deletes table
   procedure DeleteTable;
   // empty table
   procedure EmptyTable;
   // rename table
   procedure RenameTable(const NewTableName : AnsiString);
   //save table
   procedure SaveTable;
   //copy table
   procedure CopyTable(const NewTableName: AnsiString; const NewDatabaseName: AnsiString = '');
   // creates new index in table
   procedure AddIndex(
              const Name, // index name
              Fields: AnsiString; // fields list (separated by ';', ',',' ' or any combination)
              Options: TIndexOptions; // ixDescending, ixCaseInsensetive are available options
              const DescFields: AnsiString =''; // desc fields list (separated by ';', ',',' ' or any combination)
              const CaseInsFields: AnsiString =''; // case insensitive fields list (separated by ';', ',',' ' or any combination)
              inMemory   : Boolean = false
              );
   // return true if index is exists
   function IsIndexExists(IndexName: AnsiString): Boolean;
   // creates temporary index
   function CreateTemporaryIndex(Fields, DescFields, CaseInsFields: AnsiString): AnsiString;
   // creates index
   procedure InternalAddIndex(
                          name : ShortString; // name
                          fieldNames : TStringList; // field names list
                          sortOrders : TStringList; // sort orders list {'up','down'}
                          caseIns : TStringList; // case insensetive fields {'yes','no'}
                          indexOptions:  TIndexOptions; // index options
                          ignoreCase : Boolean; // ixCaseInsensitive
                          descending : Boolean);  // ixDescending
   // delete index, returns index number
   function DeleteIndex(
     											const Name : AnsiString;// name
                          inMemory   : Boolean = false
                         ) : Integer;
   // delete all indexes
   procedure DeleteAllIndexes;
   // builds selected index
   procedure BuildIndex (n : integer; IndexesToBuild: Integer=1);
   // builds all indexes
   procedure BuildAllIndexes;
   // updates all indexes
   procedure UpdateAllIndexes;
protected
   // checks selected index
   function CheckIndex (n : integer):integer;
   // checks all indexes
   procedure CheckAllIndexes;
public
   // creates auto indexes
   procedure CreateAutoIndexes(AutoIndexes: Boolean);
   // returns true if need update indexes now, false - if update is delayed
   function IsUpdateIndexesNowRecommended: boolean;
   // checks disk I/O buffers for overflow
   procedure CheckBuffersOverflow;
   // Flushes all changes that have been written to the database table
   procedure FlushBuffers;
   // disable flushes (untill all BLOB field values are saved to buffer)
   procedure DisableFlushes;
   // enable flushes (after all BLOB field values are saved to buffer)
   procedure EnableFlushes(DoCheck: Boolean=True);
    // count buffer crc
    procedure CountBufferCrc(inBuffer : PAnsiChar; inSize : Integer; outBuffer : PAnsiChar);
    // check buffer crc
    function CheckBufferCrc(inBuffer : PAnsiChar; inSize : Integer;
                            crcBuffer : PAnsiChar) : Boolean;
    //change record buffer encryption
    procedure ChangeBufferEncryption(
              buffer : PAnsiChar;  // pointer to record buffer
              mode : Byte      // 1 - enable encryption, 0 - disable encryption
    				     );
    // checks password by decoding first record and comparing check sum
    // if specified password is invalid returns false
    function TryToOpenEncryptedTable: Boolean;
    // returns true if table is encrypted
    function IsTableEncrypted : Boolean;
    //--------------- I/O ------------------
    procedure SaveTableHeaders;
    procedure InternalLoadTableHeader(var hdr: TableHeaderType);
    procedure LoadTableHeaders;
    // load indexes for the table from disk
    procedure LoadIndexesFromDisk;
    // load blob headers for the table from disk
    procedure LoadBLOBHeadersFromDisk;
    // save blob headers for the table to disk
    procedure SaveBLOBHeadersToDisk(bCreate : Boolean = false);
    // save indexes for the table to disk
    procedure SaveIndexesToDisk;
    // save indexes for the table to disk
//    procedure SaveFieldHeadersToDisk;
    // converter for old versions table format
    procedure ConvertToCurrentFormat;
    // get field number
    function InternalGetFieldNo(FieldName : AnsiString; ExceptionAllowed: Boolean = True):integer;
    // get index number
    function InternalGetIndexNo(IndexName : AnsiString):integer;
    // get Field Type by FieldNo
    function InternalGetFieldType(FieldNo: integer):  TFieldType;
    // sets autoinc value
    procedure SetAutoIncValue(value : integer);
		// adds record, modifies indexes
    function aaAddRecord(
				        recordBuffer : PAnsiChar; // pointer to record buffer
                currentIndex : Integer // from source dataset
        				        ) : Integer;
		// modifies record, modifies indexes and restore tablePosition
		function aaUpdateRecord(
				        recordBuffer : PAnsiChar; // pointer to record buffer
                currentIndex : Integer; // from source dataset
                recPos       :Integer // physical record position
        				        ) : Integer;
		// deletes record, modifies indexes and restore tablePosition
    function aaDeleteRecord (
                currentIndex : Integer; // from source dataset
                recPos       :Integer // physical record position
                                              ) : Integer;
    // add blob index headers for new record - optimized
    procedure aaAddBLOBRecord;
    // delete blob index headers for current record
    procedure aaDeleteBLOBRecord(physRecNo : Integer);
    // delete blob field value for current record
    procedure aaDeleteBLOBValue(
                                fieldNo   : integer;
                                physRecNo : Integer;
                                inMemory : Boolean = false
                                );
    // read BLOB value for selected field (for current record)
    procedure aaReadBLOBValue(
          bStream : TStream; // output stream
          fieldNo : integer; // field number 0-based
          physRecPos : Integer // physical position
                                  );
    // write BLOB value for selected field (for current record)
    procedure aaWriteBLOBValue(
          bStream : TStream; // input stream
          fieldNo : integer; // field number 0-based
          physRecPos : Integer // physical position
                                );
    // returns number of indexBuffer element, which
    // is equal to the record (indentified by position in buffer)
		function aaFindIndexValue(indexNum : integer;
                              position : integer;
                              recordCount : Integer = -1
                              ) : integer;
    // finds index of the element
		function FindIndexValueForDelete(
                          indexBuffer : array of Integer; // index values
                          position		: Integer; // currentPosition
                          recordCount : Integer = -1;
                          doCheck     : Boolean = false // if false not found
                                      //raises exception, else returns -1
                          ) : Integer;
  end; // TEasyDataManager

TEasyDatabase = class;
   { TEasyMasterDataLink }

   TEasyMasterDataLink = class(TDataLink)
   private
      FDataSet: TEasyDataSet;
      FFieldNames: AnsiString;
      FFields: TList;
      FOnMasterChange: TNotifyEvent;
      FOnMasterDisable: TNotifyEvent;
      procedure SetFieldNames(const Value: AnsiString);
   protected
      procedure ActiveChanged; override;
      procedure CheckBrowseMode; override;
      procedure LayoutChanged; override;
      procedure RecordChanged(Field: TField); override;
   public
      constructor Create(DataSet: TEasyDataSet);
      destructor Destroy; override;
      property FieldNames: AnsiString read FFieldNames write SetFieldNames;
      property Fields: TList read FFields;
      property OnMasterChange: TNotifyEvent read FOnMasterChange write FOnMasterChange;
      property OnMasterDisable: TNotifyEvent read FOnMasterDisable write FOnMasterDisable;
   end;

 TEasySession = class;

 TDBFlags = set of 0..15;

 TEasyDataset = class(TDataSet)
   private
    FRecordSize: Integer;
    FDoNotBindFields: Boolean;
    FProjection: Boolean;
    FProjectionMap: TaaIntArray;
    DBHandle:  TEasyDatabase; // database component of this dataset
    DBMHandle: TEasyDatabaseManager; // database manager for database
    TableState: integer; // state from table header (current to this component)
    blobFields: array of BLOBFieldType; // streams for blob fields
    AutoIncChangeEnabled: Boolean; // can set value to auto-inc field?
    FSettingProjection: Boolean ;  // is now projection setting?
    FProjectionFieldList: TStringList;
    FProjectionAliasList: TStringList;
    FDirectAccessForGetFieldValue:  Boolean; // if true then tableposition else active buffer
    FFreezeVisibleRecordCount: Integer;
    FSessionName: AnsiString;
    FDBFlags: TDBFlags;
    FDatabase: TEasyDatabase;
    FBDELikeFilter: Boolean;
{$IFDEF RECORD_ID_NAVIGATION}
    FCurrentRecordID: Integer;
{$ENDIF}
 protected
    FRepairIsRunning: Boolean; //
 private

    // sets table name (without .ext);
    procedure SetTableName(value: AnsiString);
    // returns table name (with .ext);
    function GetTableName: AnsiString;
    // clears all blob streams
    procedure ClearBLOBStreams;
    // get file store mode (InMemory, ...)
    function GetFileStoreMode: TaaFileStoreMode;
    // check table state and update visible records if necessary
    procedure CheckTableState;

{$IFDEF D6H}
  protected
   FOnUpdateRecord: TUpdateRecordEvent;
  protected
   // IProviderSupport
   function PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError; override;
   function PSIsSQLSupported: Boolean; override;
   procedure PSReset; override;
   function PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean; override;
  protected
   // IProviderSupport
   procedure PSEndTransaction(Commit: Boolean); override;
{$IFDEF D21H}
    function PSExecuteStatement(const ASQL: string; AParams: TParams): Integer; overload; override;
    function PSExecuteStatement(const ASQL: string; AParams: TParams;
      var ResultSet: TDataSet): Integer; overload; override;
{$ELSE}
   function PSExecuteStatement(const ASQL: String; AParams: TParams;
      ResultSet: Pointer = nil): Integer; override;
{$ENDIF}
   procedure PSGetAttributes(List: TList); override;
   function PSGetQuoteChar: String; override;
   function PSInTransaction: Boolean; override;
   function PSIsSQLBased: Boolean; override;
   procedure PSStartTransaction; override;
{$ENDIF}
  protected
   FTableName: AnsiString;
   // strip file name - remove file extension
   function StripFileName(FileName: AnsiString): AnsiString;
   // create table
   procedure InternalCreateTable;
   // delete table
   procedure InternalDeleteTable;
   // empty table
   procedure InternalEmptyTable;
   // rename table
   procedure InternalRenameTable(const NewTableName : AnsiString; IgnoreDatasetCount: Boolean = False);
   // save table
   procedure InternalSaveTable;
   // copy table
   procedure InternalCopyTable(const NewTableName: AnsiString; const NewDatabaseName: AnsiString = '');
   // adds records to current table from another table
   function InternalAddRecords(Dataset: TDataSet;
                         Mode: TAddRecordsMode;
                         var Log : AnsiString) : Boolean;

   // imports table to Easy format
   function InternalImportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         var log : AnsiString) : Boolean;
   // exports table from Easy format to other DataSource
   function InternalExportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         createTablePtr : TProcedure;
                         var log : AnsiString;
                         ToParadox: Boolean=False) : Boolean;
   // restructure table with params
   procedure InternalRestructureTable(
                         NewEncrypted : Boolean;
                         NewPassword  : AnsiString;
                         NewBLOBBlockSize : Integer;
                         NewBLOBCompression : TCompressionLevel
                              ); overload;
   // restructure table
   procedure InternalRestructureTable; overload;
   // tries to repair table
   // repair is available, if table header is not corrupted,
   // i.e. table opens properly (by setting Active to true)
   function InternalRepairTable(
                          var log : AnsiString // returns error log
                         ) : Boolean;
   // closes dataset
   procedure Disconnect; virtual;
   // checks session name
   procedure CheckDBSessionName;
   // assigns / frees database
   procedure SetDBFlag(Flag: Integer; Value: Boolean); virtual;
   // opens cursor
   procedure OpenCursor(InfoQuery: Boolean); override;
   // closes cursor
   procedure CloseCursor; override;

  public
    //  Inc(Count), don't create visible records list
    procedure FreezeVisibleRecords;
    // Dec(Count), if count=0 - create visible records list
    procedure UnfreezeVisibleRecords(Force: Boolean=False);
    // if (Count > 0) - Freezed (don't create visible records list)
    function VisibleRecordsFreezed: Boolean;

   // creates new index in table
   procedure InternalAddIndex(
              const Name, // index name
              Fields: AnsiString; // fields list (separated by ';', ',',' ' or any combination)
              Options: TIndexOptions; // ixDescending, ixCaseInsensetive are available options
              const DescFields: AnsiString =''; // desc fields list (separated by ';', ',',' ' or any combination)
              const CaseInsFields: AnsiString ='' // case insensitive fields list (separated by ';', ',',' ' or any combination)
              );
  public
   // returns name of the temporary index
   function CreateTemporaryIndex(Fields, DescFields, CaseInsFields: AnsiString): AnsiString;
  protected 
   // delete index
   procedure InternalDeleteIndex(
     											const Name : String// name
                         );
   // delete all indexes
   procedure InternalDeleteAllIndexes;
  public
    DMHandle:  TEasyDataManager; // used datamanager
    debugFlag : boolean;
    PageRecordCount:      integer;

    // creates temporary table
    procedure CreateTemporaryTable(RecordCount1: integer = DefaultRecordsPerPage);
    // deletes temporary table
    procedure DeleteTemporaryTable;
    // Get list of names of all database components
    procedure GetDatabaseNameList(List: TStrings);
{$IFDEF DEBUG_FLAG}
    // save easy table state
    procedure aaWriteStateToLog(prompt : string = '');
{$ENDIF}
    // constructor
    constructor Create(
                        AOwner:TComponent // parent
                        ); override;
    // destructor
    destructor Destroy; override;
    // get index names
    procedure GetIndexNames(List: TStrings);
    // open database
    function OpenDatabase: TEasyDatabase;
    // close database
    procedure CloseDatabase(Database: TEasyDatabase);
    // open table
    procedure OpenTable;
    // close table
    procedure CloseTable;
    // returns true if table is encrypted
    function IsTableEncrypted : Boolean;
   protected
    // Flushes all changes that have been written to the database table
    procedure InternalFlushBuffers;
    //--------------------- BLOB Fields ---------------------------
    // FieldNo = number of the field
    //
    // reads blob value from file
    procedure aaReadBLOBValue(
                FieldNo : Integer;
                DoNotCheckState: Boolean = false; // for checking if record is visible
                RealPhysRecNo:   Integer = -1
                );
    // writes blob value from file
    procedure aaWriteBLOBValue(FieldNo : Integer);
    // delete blob index headers for current record
    procedure aaDeleteBLOBRecord;
    // saves all blob streams (Post)
    procedure aaSaveBLOBData;
   public
    // create blob stream
    function InternalCreateBlobStream(
    					Field: TField;
              Mode: TBlobStreamMode
              ): TMemoryStream;
    // create EasyBlobStream
    function CreateBlobStream(
    					Field: TField;
              Mode: TBlobStreamMode
              ): TStream; override;
    // close blob stream, write blob field value to blob data file
    procedure CloseBlob(Field: TField); override;
   protected
    // sets table position
    procedure SetTablePosition (value: Integer);
    // gets current id
    function GetCurrentID: Integer;
    // get current record buffer
    function GetCurrentRecordBuffer: PAnsiChar;
    // ---------- record buffer management ----------
    // allocate record buffer
    function AllocRecordBuffer: TRecordBuffer; override;
    // free memory
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
    // return record size in bytes
    function GetRecordSize: Word; override;
    // return record count
    function GetRecordCount: Integer; override;
    //----------- table management -------------------
    // initiate field definitions
    procedure InternalInitFieldDefs; override;
    // open table, create fields, initialization of fields
    procedure InternalOpen; override;
    // close table
    procedure InternalClose; override;
    // returns true if table is open, otherwise returns false
    function IsCursorOpen: Boolean; override;
{$IFDEF D21H}
    procedure InternalInitRecord(Buffer: TRecBuf); overload; override;
{$ELSE}
    // initiate record (default values)
    procedure InternalInitRecord(Buffer: TRecordBuffer); override;
{$ENDIF}
    // exception handling
    procedure InternalHandleException; override;
    //-------------- navigation ------------------------------------------------
    // go to record
    procedure SetRecNo(Value: Integer); override;
    // return current record number
    function GetRecNo: Integer; override;
    // set table position by physical record No
    procedure SetTablePositionByPhysRecNo(physRecNo: integer);
    // get table position by physical record No
    function GetTablePositionByPhysRecNo(physRecNo: integer): integer;
    //-------------- data access ------------------------------------------------
    // read record, put data to record buffer
    // getmode = {gmPrior, gmCurrent, gmNext} - determine what record to read
    function GetRecord(Buffer: TRecordBuffer;
             GetMode: TGetMode; DoCheck: Boolean):
             TGetResult; override;
   {$IFDEF D18H}
   procedure DataConvert(Field: TField; Source: TValueBuffer; var Dest: TValueBuffer; ToNative: Boolean); overload; override;
   {$ELSE}
     {$IFDEF D17H}
     procedure DataConvert(Field: TField; Source, Dest: TValueBuffer; ToNative: Boolean);
     {$ELSE}
     procedure DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);
     {$ENDIF}
    {$IFDEF D5H}
        override;
    {$ENDIF}
   {$ENDIF}
    //------------- key/range --------------------------------------------------
  private
    //structure for keep key info
    FKeyBuffers: array[TKeyIndex] of PKeyBuffer;
    FKeyBuffer: PKeyBuffer;
    //Range is active now ?
    IsRanged: Boolean;
    //allocate key info in memory
    procedure AllocKeyBuffers;
    //dispose key info from memory
    procedure FreeKeyBuffers;
    function InitKeyBuffer(Buffer: PKeyBuffer): PKeyBuffer;
    //assigned key values to key info record
    procedure SetKeyFields(KeyIndex: TKeyIndex; const Values: array of const);
    //get number of key fields in search operation
    function GetKeyFieldCount: Integer;
    //set number of key fields in search operation
    procedure SetKeyFieldCount(Value: Integer);
    //check that current state is dsSetKey
    procedure CheckSetKeyMode;
    //set what buffer will be current key bufer
    procedure SetKeyBuffer(KeyIndex: TKeyIndex; Clear: Boolean);
    function SetCursorRange: Boolean;
    function ResetCursorRange: Boolean;
    function GetKeyExclusive: Boolean;
    procedure SetKeyExclusive(Value: Boolean);
  public
    //Searches for a record containing specified field values
    function FindKey(const KeyValues: array of const): Boolean;
    //Moves the cursor to the record that most closely matches a specified set of key values
    procedure FindNearest(const KeyValues: array of const);
    //Enables modification of the search key buffer.
    procedure EditKey;
    //Moves the cursor to a record specified by the current key
    function GotoKey: Boolean;
    //Moves the cursor to the record that most closely matches the current key.
    procedure GotoNearest;
    //Enables setting of keys and ranges for a dataset prior to a search.
    procedure SetKey;
    procedure ApplyRange;
    procedure CancelRange;
    procedure EditRangeEnd;
    procedure EditRangeStart;
    procedure SetRange(const StartValues, EndValues: array of const);
    procedure SetRangeEnd;
    procedure SetRangeStart;
    //Specifies the number of fields to use key search on a multi-field key.
    property KeyFieldCount: integer read GetKeyFieldCount write SetKeyFieldCount;
    property KeyExclusive: Boolean read GetKeyExclusive write SetKeyExclusive;
    //------------------------------------------------------------------
public
//    procedure DoDataEvent(Event: TDataEvent; Info: integer);
    //--------------------------------------------------------------------------
    // Beginning of the EasyTable SQL
    //--------------------------------------------------------------------------

    // switches on projection on the dataset
    procedure SetProjection; overload;
    // sets projection on the dataset
    procedure SetProjection(
        FieldList: TStringList;
        AliasList: TStringList;
        OnlyStoreLists: Boolean = False
        ); overload;
    // sets distinct on the dataset
    procedure SetDistinct(
        DistinctFields: AnsiString
        );

    // returns field value
    procedure GetFieldValue(
                        var value: TETblDataValue;
                        FieldNo: Integer;
                        bCopy: Boolean = false);

    // returns field value for logical field #FieldNo - used in sub queries
    procedure GetFieldValueWithProjection(
                        var value: TETblDataValue;
                        FieldNo: Integer;
                        bCopy: Boolean = false);

    // sets field value
    procedure SetFieldValue(
                        var value: TETblDataValue;
                        FieldNo: Integer
                        );
    //--------------------------------------------------------------------------
    // End of the EasyTable SQL
    //--------------------------------------------------------------------------

    // locate record
    function Locate(const KeyFields: String; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; override;
    // lookup record
    function Lookup(const KeyFields: String; const KeyValues: Variant;
      const ResultFields: String): Variant; override;
  protected

    // check if field is in index
    function GetIsIndexField(Field: TField): Boolean; override;
  public
{$IFDEF D17H}
 {$IFDEF D18H}
   function GetFieldData(Field: TField; var Buffer: TValueBuffer; NativeFormat: Boolean): Boolean; overload; override;
  {$ELSE}
   function GetFieldData(Field: TField; Buffer: TValueBuffer; NativeFormat: Boolean): Boolean; overload; override;
  {$ENDIF}
{$ELSE}
   function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
{$ENDIF}
  protected
{$IFDEF D17H}
   procedure SetFieldData(Field: TField; Buffer: TValueBuffer; NativeFormat: Boolean); overload; override;
{$ELSE}
   // write field data from buffer to current record buffer
   procedure SetFieldData(Field: TField; Buffer: Pointer); override;
{$ENDIF}
  protected
    // go to first record
    procedure InternalFirst; override;
    // go to last record
    procedure InternalLast; override;

{$IFDEF D21H}
   procedure InternalSetToRecord(Buffer: TRecBuf); overload; override;
   function GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag; override;
   procedure GetBookmarkData(Buffer: TRecBuf; Data: TBookmark); override;
   // go to bookmark
   procedure InternalGotoBookmark(Bookmark: TBookmark); override;
   procedure SetBookmarkFlag(Buffer: TRecBuf; Value: TBookmarkFlag); override;
   procedure SetBookmarkData(Buffer: TRecBuf; Data: TBookmark); override;
{$ELSE}
   // go to record in buffer
   procedure InternalSetToRecord(Buffer: TRecordBuffer); override;
   // get bookmark flag
   function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override;
   // get bookmark data
   procedure GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
   procedure InternalGotoBookmark(Bookmark: Pointer); override;
   // set flag
   procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag); override;
   // set data
   procedure SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
{$ENDIF}

    // set key data
    procedure PostKeyBuffer(Commit: Boolean);
public
    // compare bookmarks
    function CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer; override;
    // checks if bookmark is valid
    function BookmarkValid(Bookmark: TBookmark): Boolean; override;
    // post with SetKey addition
    procedure Post; override;

    // direct insert
    procedure DirectInsert;
    // direct post
    procedure DirectPost;
    // set SQL Filter
    procedure SetSQLFilter(FilterExpr: TObject);
    // set SQL Top row count
    procedure SetSQLTopRowCount(SQLFirstRowNo, SQLTopRowCount: integer);

protected
    // check required fields
    procedure CheckRecordValidity(RecordBuffer: PAnsiChar);
{$IFDEF D21H}
   procedure InitRecord(Buffer: TRecBuf); overload; override;
{$ELSE}
   procedure InitRecord(Buffer: TRecordBuffer); override;
{$ENDIF}
{$IFDEF 21H}
   procedure InternalAddRecord(Buffer: TRecBuf; Append: Boolean); overload; override;
{$ELSE}
    // appending table (Append flag - ignored, record will be inserted after
    // last one)
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override;
{$ENDIF}
    // insert record
    procedure InternalInsert; override;
    // cancels updates
    procedure InternalCancel; override;
    // update record
    procedure InternalPost; override;
    // delete record
    procedure InternalDelete; override;
    // return true if table is avalaiable for editing, otherwise return false
    function GetCanModify: Boolean; override;
    // GetExists - returns true, if table exists; otherwise returns false
    function GetExists : Boolean;
    // rebuild index definitions
    procedure UpdateIndexDefs; override;
    // sets active buffer to current record (by tablePosition)
    procedure SetActiveBuffer;
    // finds records, specified by FilterText property
    function FindRecord(Restart, GoForward: Boolean): Boolean; override;
{$IFDEF D21H}
    procedure ClearCalcFields(Buffer: NativeInt); overload; override;
{$ELSE}
    // clear calculated fields
    procedure ClearCalcFields(Buffer: TRecordBuffer); override;
{$ENDIF}
    // for OnFilterRecord Event
    function FilterRecord(Buffer: TRecordBuffer): Boolean;
    // refreshes data
    procedure InternalRefresh; override;

   public
     FDistinctFields:   AnsiString; // fields used in distinct - field1;field2; ...
     visibleRecords	 : TaaIntArray;  // record positions in table
     visibleRecordCount : Integer;   // visible records count
   private
     FDistinctIndexNo:  Integer; // number of index in DataManager that corresponds
     FTemporaryRecordBuffer: TRecordBuffer; // used in DirectInsert / DirectPost / SetFieldValue / GetFieldValue
     FDirectInsert: Boolean;
     FDirectFilter: Boolean;

     FSQLFilterExpr: TObject;        // SQL filter expression
     FSQLTopRowCount: Integer;       // Select TOP n was applied
     FSQLFirstRowNo:  Integer;       // SELECT TOP first_row,n was applied

     FDatabaseName   : AnsiString;       // table path / database component name
     FDatabaseFileName : AnsiString;     // database file name
     tablePosition   : Integer;      // current record number
     tablePhysRecNo  : Integer;      // current physical record number
     isTableOpened   : Boolean;      // true if table is opened
     isIndexUsed     : Boolean;      // true, if index is used
     currentIndex    : Integer;	     // index number in indexHeaderList
     foundRecords	   : aInteger;     // found record positions in table
     foundRecordCount: Integer;      // found records count
     foundRecordNo   : Integer;      // curent found record
     foundRecordsNeedUpdate: Boolean; // after insert/edit/delete and before FindNext
//     FFiltered       : Boolean;       // if true then filter is active
//     FFilter         : AnsiString;        // filter conditions
//     FFilterOptions  : TFilterOptions;// filter options (foCaseInsensitive) only
     FEncrypted      : Boolean;       // true - cipher used, false - not used
     FPassword       : AnsiString; // this key value is used for both reading
                          // and writing data.
                          // For data encoding (decoding) this key value is
                          // hashed by Ripe Message Digest 256 method
                          // (based on MD4),
                          // and then data will be encoded (decoded)
                          // by Rijndael algorythm using that 256-bit key
     FIndexDefs     : TIndexDefs; // index definitions
     FRestructureIndexDefs : TIndexDefs; // restructure index definitions
     FRestructureFieldDefs : TFieldDefs; // restructure field definitions
     FStoreDefs : Boolean;  // for FFieldDefs
     FIndexName       : AnsiString; // index name
     FIndexFieldNames : AnsiString; //index field names
     createIndexDefs: Boolean; // if true - index defs are created by OpenTable
     FilterParser   : TSearchParser; // search parser for filtering records
     MasterDetailParser : TSearchParser; // search parser for master/detail records
     FindParser   : TSearchParser; // search parser for master/detail records
     foundVisibleRecordsList : TaaList; // list of the found visible records
     FFilterBuffer  : TRecordBuffer; // filter record buffer
     FExclusive : Boolean; // exclusive
     FMasterLink: TEasyMasterDataLink; //master detail
     insertMode : Boolean; // if true - then internal insert was called
     visRecUpdated : Boolean; // visible records updated
     FOnProgress  : TaaProgressEvent; // progress for bulk operations
     FProgress,FProgressMax : Extended; // for progress count
     FProgressProcess : TaaProgressProcess; // for detecting operation, counting progress
		 FBuildIndexesProgress:	TBuildIndexesProgressEvent; // build indexes progress
     FInMemory        : Boolean; // in memory mode
     FAutoIndexes     : Boolean; // auto-indexes enabled?
     FTemporary       : Boolean; // temporary mode
     FTemporaryTable       : Boolean; // temporary mode
     FBLOBBlockSize   : Integer; // blob block size
     FBLOBCompression : TCompressionLevel; // blob block size
     FReadOnly        : Boolean; //read only
     FSetActiveBufferFlag : Boolean;
     FFastOpen        : Boolean; // fast open mode - small pages
     FoldFastOpen     : Integer; // CB bug fix
     FoldFastOpen2    : Integer; // CB bug fix
     FSilentMode:       Boolean;
                                 // distinct fields
    //-------------------------- procedures and functions ----------------------
    // get database name or database file name
    function GetDBName: AnsiString;

    //--------------------- Indexing ------------------------------
    // ixPrimary, ixCaseInsensitive, ixDescending options supported
    // create index
    // open index
    procedure OpenIndex(
     											name : ShortString; // name
                          number : Integer = -1		// number in indexHeaderList
                         );
     // close index
     procedure CloseIndex;
public
    // builds selected index
    procedure BuildIndex (n : integer);
    // builds all indexes
    procedure BuildAllIndexes;
    // updates all indexes
    procedure UpdateAllIndexes;
    // check index; returns -1 if index ok;
    // if index is invalid returns number of first invalid element
    function CheckIndex(n : integer) : integer;
   // checks all indexes
   procedure CheckAllIndexes;
private
{
    // returns number of indexBuffer element, which
    // is equal to the record (indentified by position in buffer)
		function aaFindIndexValue(indexNum : integer;
                              position : integer;
                              recordCount : Integer = -1
                              ) : integer;
    // finds index of the element
		function FindIndexValueForDelete(
                          indexBuffer : array of Integer; // index values
                          position		: Integer; // currentPosition
                          recordCount : Integer = -1;
                          doCheck     : Boolean = false // if false not found
                                      //raises exception, else returns -1
                          ) : Integer;
 }
    // compare 2 RecordBuffers using Index settings but
    // only first IndexFieldCount fields
    // returns -1 (if RecordBuffer1 < RecordBuffer2 in sense of index order),
    // 0 (=), 1 (>)
    function CompareRecordBuffersWithIndex(
                   RecordBuffer1: PAnsiChar; // record buffer 1 to compare
                   RecordBuffer2: PAnsiChar; // record buffer 2 to compare
                   IndexNo: Integer;    // index No where compared
                   IndexFieldCount: Integer // fields from index to use when compare
                           ): integer;

    // compare RecordBuffer with record from index using Index settings but
    // only first IndexFieldCount fields
    // returns -1 (if RecordBuffer < record from index in sense of index order),
    // 0 (=), 1 (>)
    function CompareInIndex(
                   RecordBuffer: PAnsiChar; // record buffer to compare
                   IndexNo: Integer;    // index No where compared
                   PosInIndex: Integer; // record No in index
                   IndexFieldCount: Integer // fields from index to use when compare
                           ): integer;

    // find RecordBuffer in Index using its settings but
    // applying comparison for only first IndexFieldCount fields
    // for exact "=" or nearest match
    // returns position in index or -1 if not found
    function FindInIndex(
                   RecordBuffer: PAnsiChar; // record buffer to compare
                   IndexNo: Integer;    // index No where compared
                   IndexFieldCount: Integer; // fields from index to use when compare
                   bForwardDirection: Boolean; // (Forward / Backward)
                   bExact: Boolean // exact or nearest search
                           ): integer;


    // find RecordBuffer in visible records
    // using currentIndex settings but
    // applying comparison for only first IndexFieldCount fields
    // for exact "=" or nearest match
    // returns position in visibleRecords or -1 if not found
    function FindInVisibleRecords(
                   RecordBuffer: PAnsiChar; // record buffer to compare
                   IndexFieldCount: Integer; // fields from index to use when compare
                   bForwardDirection: Boolean; // (Forward / Backward)
                   bExact: Boolean // exact or nearest search
                           ): integer;

    // check is (Filter<>'' and Filtered=true)
    function IsFiltered: boolean;
    // check is master-detail active
    function IsMasterDetail: boolean;

    // returns number of indexBuffer element, after which the record
    // should be inserted
    // returns true if record matches Filter and MasterFields
    function IsRecordVisible(
				        recordBuffer : PAnsiChar; // pointer to record buffer
                bRunOnFilterRecord: Boolean = true
        				        ) : Boolean;
    // is any filter, range, SQLFilter, ...
    function IsViewConstrained: Boolean;
		// adds record, modifies indexes and restore tablePosition
		procedure aaAddRecord(
				        recordBuffer : PAnsiChar // pointer to record buffer
        				        );
		// modifies record, modifies indexes and restore tablePosition
		procedure aaUpdateRecord(
 				        recordBuffer : PAnsiChar // pointer to record buffer
                  			   );
		// deletes record, modifies indexes and restore tablePosition
		procedure aaDeleteRecord;
    // returns physical record number
    function GetVisRecValue (
                            recordNum : integer // table position
                            ) : integer; // physical record number
    // create index definitions in IndexDefs
    procedure CreateIndexDefinitions;

    // find index
    function GetIndexNoByFields(const Fields: AnsiString;
                                DescFields: string='*';
                                CaseSensitive: Boolean=True): integer;
    // set index definitions
    procedure SetIndexDefs(Value: TIndexDefs);
    // returns number of fields that comprise the current index
    function GetIndexFieldCount : Integer;
    // returns index name, if index is used; otherwise returns ''
    function GetIndexName : AnsiString;
    // open index with specified name; if name='' then closes index
    procedure SetIndexName(const Name: AnsiString);
    // returns index field names, if index is used; otherwise returns ''
    function GetIndexFieldNames : AnsiString;
    // open index with specified index fields; if name='' then closes index
    procedure SetIndexFieldNames(const Value: AnsiString);
    // get index field
    function GetIndexField(Index: Integer): TField;
    // set index field
    procedure SetIndexField(Index: Integer; Value: TField);
    // set database name
    procedure SetDatabaseName(name : AnsiString);
    // set database file name
    procedure SetDatabaseFileName(FileName : AnsiString);
    // sets session name
    procedure SetSessionName(const Value: AnsiString);
    // gets session
    function GetDBSession: TEasySession;
    // gets autoindexes
    function GetAutoIndexes: Boolean;
    // returns current version text
    function GetCurrentVersionText : AnsiString;
    // returns current version text
    procedure SetCurrentVersionText (s: AnsiString);
    // checks if table is encrypted
    function GetEncrypted : Boolean;
    // get cache enabled
    function GetCacheEnabled: Boolean;
    // set cache enabled
    procedure SetCacheEnabled(Value: Boolean);
public
    //--------------------- Internal ------------------------------
    function GetTablePositionByID(id: integer;
                                  IgnoreVisibleRecords: Boolean=False;
                                  ReturnPhysRecNo: Boolean=False): integer;
    //--------------------- Searching ------------------------------
    // return matched records bitmap
    procedure GetMatchedRecords(
     searchOperation : TSearchOperation; // search operation record
     curFilterOptions : TFilterOptions; // current search options
     var recordBits : TBitsArray // array of results (0 bit value - record doesn't match)
     );

    // return matched records array
    procedure GetMatchedRecordsArray(
     searchCondition  : TSearchOperation; // search condition
     curFilterOptions : TFilterOptions; // current search options
     mode             : TaaGMRMode; // return array or length or first record?
     var FoundRecords : aInteger; // array of found records No
     var FoundRecordCount : Integer // count of found records
     );

    // check is recordBuf satisfies search condition
    function IsRecordMatches(
     searchOperation: TSearchOperation; // search operation record
     curFilterOptions: TFilterOptions; // current search options
     recordBuf: PAnsiChar // buffer of record to compare with
     ): boolean;

    // locate first record satisfying search condition
    function InternalLocate(
     searchConditions: array of TSearchOperation; // search conditions
     ConditionCount: integer; // count of conditions
     curFilterOptions: TFilterOptions // current search options
     ): integer; // return PhysRecNo or -1

    //prepare internal array for search and call InternalLocate
    function PrepareAndLocate(
     const KeyFields: AnsiString; const KeyValues: Variant;
     so: TSearchOperator; //kind if search
     fo: TFilterOptions   // current search options
     ): integer;

    // prepare record buffer for comparison
    procedure PrepareValueBuffer(
                FieldNo:integer; // No of field
                var SearchOp:TSearchOperator; // =,<,...
                value:WideString; // AnsiString with value
                var valueBuffer:PAnsiChar); // buffer with converted value

    // returns true, if field type is supported
    function IsFieldTypeSupported(
             fType : TFieldType // field type
             ) : Boolean;
{
    //check bounds of Variant array
    procedure CheckVarArrayBounds(
             fk: integer;  //declared number of items
             V: Variant);  //variant array or simple Variant
}
public
    // creates supported types list
    procedure GetSupportedFieldTypes(typeList : TaaList);
    // returns table file extesion
    function GetTableFileExtension : AnsiString;
private
    function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean): Boolean;
    function IsWideStrMatchPattern(StrPtr: PWideChar; PatternPtr: PWideChar; bIgnoreCase:boolean): Boolean;

public
    // fills visibleRecords with record numbers
    procedure CreateVisibleRecordsList;
    // assigns visibleRecords with record numbers
    procedure AssignVisibleRecordsList(visRecords: TaaIntArray);
protected
    // sets filtered
    procedure SetFiltered(f : boolean); override;
private
    // get active buffer
    function GetActiveRecordBuffer:  PAnsiChar;
    // sets exclusive
    procedure SetExclusive(Value: Boolean);
    //
    function GetMasterFields: AnsiString;
    //
    procedure SetMasterFields(const Value: AnsiString);
    procedure CheckMasterRange;
    procedure MasterChanged(Sender: TObject);
    procedure MasterDisabled(Sender: TObject);
    procedure ChangeMasterCondition(MasterFields: TList);
    // field defs support
    function FieldDefsStored: Boolean;
    // index defs support
    function IndexDefsStored: Boolean;


protected
    function GetDataSource: TDataSource; override;
private
    procedure SetDataSource(Value: TDataSource);
    // in memory mode
    procedure SetInMemory(Value: Boolean);
    // temporary mode
    procedure SetTemporary(Value: Boolean);
    // last auto-increment value
    function GetLastAutoIncValue: LongWord;
    // get blob compression
    function GetBLOBCompression: TCompressionLevel;
    // set blob compression
    procedure SetBLOBCompression(value: TCompressionLevel);
    // get blob block size
    function GetBLOBBlockSize: Integer;
    // set blob block size
    procedure SetBLOBBlockSize(Value : Integer);
    // set read only
    procedure SetReadOnly(Value : Boolean);
{$IFNDEF ENCRYPTION_ON}
    procedure SetPassword(Value: AnsiString);
{$ENDIF}
   protected
    // on progress
    procedure DoOnProgress(Progress : Real);
    procedure DoOnBuildIndexesProgress(Progress : Real; bStart, bFinish: Boolean);
    property MasterLink: TEasyMasterDataLink read FMasterLink;
   public
    procedure SetAutoIncValue(value : integer);
    // ------- properties --------
    property SilentMode: Boolean read FSilentMode write FSilentMode;
    // number of fields that comprise the current index
    property IndexFieldCount : Integer read GetIndexFieldCount;
    // index fields
    property IndexFields[Index: Integer]: TField read GetIndexField write SetIndexField;
    // current record number
    property RecNo: Integer read GetRecNo write SetRecNo;
    // last auto-increment value - primary key value of the last added record
    property LastAutoIncValue : LongWord read GetLastAutoIncValue;
    // index definitions, used by RestructureTable;
    property RestructureIndexDefs: TIndexDefs read FRestructureIndexDefs;
    // index definitions, used by RestructureTable;
    property RestructureFieldDefs: TFieldDefs read FRestructureFieldDefs;
    // temporary mode
    property Temporary: Boolean read FTemporary write SetTemporary;
    // fast open mode
    property FastOpen: Boolean read FFastOpen write FFastOpen default true;
    // cache enabled = not FastOpen
    property CacheEnabled: Boolean read GetCacheEnabled write SetCacheEnabled;
//   published
    // index definitions, used by CreateTable;
    property IndexDefs: TIndexDefs read FIndexDefs write SetIndexDefs stored IndexDefsStored;
    // field definitions, used by CreateTable;
    property FieldDefs stored FieldDefsStored;
    // engine version
    property CurrentVersion : AnsiString read GetCurrentVersionText
      write SetCurrentVersionText;
    // name of the index; if name = '' - no index used
    property IndexName: AnsiString read GetIndexName write SetIndexName;
    // index field names
    property IndexFieldNames: AnsiString read GetIndexFieldNames write SetIndexFieldNames;
    // table name (without extension and path)
    property TableName: AnsiString Read GetTableName Write SetTableName;
    // database name or directory or flat file
    property DatabaseName: AnsiString Read FDatabaseName Write SetDatabaseName;
    // database file name (flat file)
    property DatabaseFileName: AnsiString Read FDatabaseFileName Write SetDatabaseFileName;
    // compression level
    property BLOBCompression: TCompressionLevel Read GetBlobCompression
              Write SetBLOBCompression Default DEFAULT_BLOB_COMPRESSION;
    // compression level
    property BLOBBlockSize: Integer Read GetBLOBBlockSize write SetBLOBBlockSize
              Default 512;
    // encryption on/off
    property Encrypted: Boolean Read GetEncrypted Write FEncrypted
              Default false;
    // password
{$IFDEF ENCRYPTION_ON}
    property Password: AnsiString read FPassword write FPassword;
{$ELSE}
    property Password: AnsiString read FPassword write SetPassword;
{$ENDIF}
    // filter text
//    property Filter;
    // filter options
//    property FilterOptions: TFilterOptions read FFilterOptions write FFilterOptions;
    // if true - table is filtered
//    property Filtered : Boolean read FFiltered write SetFiltered default False;
    // exists - true, if table exists; otherwise false
    property Exists : Boolean read GetExists;
    // if true - table is in read only mode
    property ReadOnly : Boolean read FReadOnly write SetReadOnly default False;
    // fielddefs support
    property StoreDefs: Boolean read FStoreDefs write FStoreDefs default False;
    // exclusive mode
    property Exclusive: Boolean read FExclusive write SetExclusive default False;
    // master detail fields
    property MasterFields: AnsiString read GetMasterFields write SetMasterFields;
    // master source
    property MasterSource: TDataSource read GetDataSource write SetDataSource;
    // Progress Event
    property OnProgress : TaaProgressEvent read FOnProgress write FOnProgress;
    // Build Indexes Progress Event
    property OnBuildIndexesProgress : TBuildIndexesProgressEvent
    	read FBuildIndexesProgress write FBuildIndexesProgress;
    // in memory mode
    property InMemory: Boolean read FInMemory write SetInMemory;
    // AutoIndexes enabled?
    property AutoIndexes: Boolean read GetAutoIndexes write FAutoIndexes;
    // session
    property DBSession: TEasySession read GetDBSession;
    // database
    property Database: TEasyDatabase read FDatabase;
    // FindFirst, FindNext ignores Filtered=True?
    property BDELikeFilter: Boolean read FBDELikeFilter write FBDELikeFilter;

    // TDataSet properties
    property AutoCalcFields;
    property Active;
    property Filtered;
    property CanModify;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
{$IFDEF D5H}
    property BeforeRefresh;
    property AfterRefresh;
{$ENDIF}
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;

   published
    // session name
    property SessionName: AnsiString read FSessionName write SetSessionName;
{$IFDEF D6H}
   property OnUpdateRecord: TUpdateRecordEvent read FOnUpdateRecord write FOnUpdateRecord;
{$ENDIF}
  end; // TEasyDataset

{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
  TEasyTable = class(TEasyDataSet)
   public
   // creates table
   procedure CreateTable; overload;
   procedure CreateTable(NewTableName: AnsiString); overload;
   // deletes table
   procedure DeleteTable;
   // empty table
   procedure EmptyTable;
   // rename table
   procedure RenameTable(const NewTableName: AnsiString);
   //copy table
   procedure CopyTable(const NewTableName: AnsiString; const NewDatabaseName: AnsiString = '');
   //save table
   procedure SaveTable;
   // adds records to current table from another table
   function AddRecords(Dataset: TDataSet;
                         Mode: TAddRecordsMode;
                         var Log : AnsiString) : Boolean;
   // imports table to Easy format
   function ImportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         var log : AnsiString) : Boolean;
   // exports table from Easy format to other DataSource
   function ExportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         createTablePtr : TProcedure;
                         var log : AnsiString;
                         ToParadox: Boolean=False ) : Boolean;
   // restructure table with params
   procedure RestructureTable(
                         NewEncrypted : Boolean;
                         NewPassword  : AnsiString;
                         NewBLOBBlockSize : Integer;
                         NewBLOBCompression : TCompressionLevel
                              ); overload;
   // restructure table
   procedure RestructureTable; overload;
  // tries to repair table
  // repair is available, if table header is not corrupted,
  // i.e. table opens properly (by setting Active to true)
   function RepairTable(
                          var log : AnsiString // returns error log
                         ) : Boolean;
   // creates new index in table
   procedure AddIndex(
              const Name, // index name
              Fields: AnsiString; // fields list (separated by ';', ',',' ' or any combination)
              Options: TIndexOptions; // ixDescending, ixCaseInsensetive are available options
              const DescFields: AnsiString =''; // desc fields list (separated by ';', ',',' ' or any combination)
              const CaseInsFields: AnsiString ='' // case insensitive fields list (separated by ';', ',',' ' or any combination)
              );
   // delete index
   procedure DeleteIndex(
     											const Name : String// name
                         );
   // delete all indexes
   procedure DeleteAllIndexes;
   // Flushes all changes that have been written to the database table
   procedure FlushBuffers;
   // creates list of supported operators
   procedure GetSupportedFieldTypes(
             typeList : TaaList
             );
   // returns true, if field type is supported
   function IsFieldTypeSupported(
             fType : TFieldType // field type
             ) : Boolean;
   // returns table file extesion
   function GetTableFileExtension : AnsiString;
    //
{    function GetMasterFields: AnsiString;
    //
    procedure SetMasterFields(const Value: AnsiString);
    procedure CheckMasterRange;
    procedure MasterChanged(Sender: TObject);
    procedure MasterDisabled(Sender: TObject);
    procedure ChangeMasterCondition(MasterFields: TList);}
    // field defs support
    function FieldDefsStored: Boolean;
    // index defs support
    function IndexDefsStored: Boolean;

    // fills table name list
    procedure GetTableNameList(List : TStrings);
{$IFDEF D6H}
  protected
    // IProviderSupport
    function PSGetDefaultOrder: TIndexDef; override;
    function PSGetKeyFields: String; override;
    function PSGetTableName: String; override;
    function PSGetIndexDefs(IndexTypes: TIndexOptions): TIndexDefs; override;
    procedure PSSetCommandText(const CommandText: String); override;
    procedure PSSetParams(AParams: TParams); override;
{$ENDIF}
protected
    function GetDataSource: TDataSource; override;
    // get master-table fields values
    procedure DoOnNewRecord; override;
    // on progress
    procedure DoOnProgress(Progress : Real);
    property MasterLink: TEasyMasterDataLink read FMasterLink;
public
    // keys
    property KeyFieldCount;
    property KeyExclusive;
    // index definitions, used by RestructureTable;
    property RestructureIndexDefs;
    // index definitions, used by RestructureTable;
    property RestructureFieldDefs;
    // last auto-increment value - primary key value of the last added record
    property LastAutoIncValue;
   published
    property Filter;
    // filter options
    property FilterOptions;
    // if true - table is filtered
    property Filtered;
    // exists - true, if table exists; otherwise false
    property Exists;
    // engine version
    property CurrentVersion;
    // table name (without extension and path)
    property TableName;
    // table path (without '\' at the end)
    property DatabaseName;
    // database file name
    property DatabaseFileName;
    // index definitions, used by CreateTable;
    property IndexDefs;
    // field definitions, used by CreateTable;
    property FieldDefs;
    // name of the index; if name = '' - no index used
    property IndexName;
    // index field names
    property IndexFieldNames;
    // compression level
    property BLOBCompression;
    // compression level
    property BLOBBlockSize;
    // encryption on/off
    property Encrypted;
    // password
    property Password;
    // if true - table is in read only mode
    property ReadOnly;
    // fielddefs support
    property StoreDefs;
    // exclusive mode
    property Exclusive;
    // master detail fields
    property MasterFields;
    // master source
    property MasterSource;
    // File store mode
    property InMemory;
    // Progress Event
    property OnProgress;
    // AutoIndexes enabled?
    property AutoIndexes;
    property OnBuildIndexesProgress;
    property CacheEnabled;
    // FindFirst, FindNext ignores Filtered=True?
    property BDELikeFilter;
   published
    // TDataSet properties
    property AutoCalcFields;
    property Active;
    property CanModify;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
{$IFDEF D5H}
    property BeforeRefresh;
    property AfterRefresh;
{$ENDIF}
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
  end;
{
    // index definitions, used by CreateTable;
    property IndexDefs: TIndexDefs read FIndexDefs write SetIndexDefs stored IndexDefsStored;
    // field definitions, used by CreateTable;
    property FieldDefs stored FieldDefsStored;
    // engine version
    property CurrentVersion : AnsiString read GetCurrentVersionText
      write SetCurrentVersionText;
    // name of the index; if name = '' - no index used
    property IndexName: AnsiString read GetIndexName write SetIndexName;
    // index field names
    property IndexFieldNames: AnsiString read GetIndexFieldNames write SetIndexFieldNames;
    // table name (without extension and path)
    property TableName: AnsiString Read GetTableName Write SetTableName;
    // database name or directory or flat file
    property DatabaseName: AnsiString Read FDatabaseName Write SetDatabaseName;
    // database file name (flat file)
    property DatabaseFileName: AnsiString Read FDatabaseFileName Write SetDatabaseFileName;
    // compression level
    property BLOBCompression: TCompressionLevel Read GetBlobCompression
              Write SetBLOBCompression Default DEFAULT_BLOB_COMPRESSION;
    // compression level
    property BLOBBlockSize: Integer Read GetBLOBBlockSize write SetBLOBBlockSize
              Default 512;
    // encryption on/off
    property Encrypted: Boolean Read GetEncrypted Write FEncrypted
              Default false;
    // password
    property Password: AnsiString read FPassword write FPassword;
    // filter text
    property Filter: AnsiString read FFilter write FFilter;
    // filter options
    property FilterOptions: TFilterOptions read FFilterOptions write FFilterOptions;
    // if true - table is filtered
    property Filtered : Boolean read FFiltered write SetFiltered default False;
    // exists - true, if table exists; otherwise false
    property Exists : Boolean read GetExists;
    // if true - table is in read only mode
    property ReadOnly : Boolean read FReadOnly write SetReadOnly default False;
    // fielddefs support
    property StoreDefs: Boolean read FStoreDefs write FStoreDefs default False;
    // exclusive mode
    property Exclusive: Boolean read FExclusive write SetExclusive default False;
    // master detail fields
    property MasterFields: AnsiString read GetMasterFields write SetMasterFields;
    // master source
    property MasterSource: TDataSource read GetDataSource write SetDataSource;
    // Progress Event
    property OnProgress : TaaProgressEvent read FOnProgress write FOnProgress;
    // Build Indexes Progress Event
    property OnBuildIndexesProgress : TBuildIndexesProgressEvent
    	read FBuildIndexesProgress write FBuildIndexesProgress;
    // in memory mode
    property InMemory: Boolean read FInMemory write SetInMemory;
    // TDataSet properties
    property AutoCalcFields;
    property Active;
    property CanModify;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property BeforeRefresh;
    property AfterRefresh;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;

}

 TEasySessionManager = class;

 // database manager (shareable for each database)
 TEasyDatabaseManager = class(TObject)
 private
  DatabaseList: TList; // list of connected databases
  DataSetList: TList; // list of connected datasets
  FReadOnly: boolean; // is read-only?
  FInMemory: boolean; // is in-memory?
  FDatabaseFileMode: TDatabaseFileMode;
  SMHandle: TEasySessionManager;

  function FPassword: AnsiString;
 protected
  // get File System for specified FileStoreMode
  function GetPFSHandle(FileStoreMode: TaaFileStoreMode): TAbstractPlainFileSystem;
 public
  bDatabaseFile: boolean; // database file or directory

  // ESFS exists?
  function GetExists: boolean;
  // in memory mode
  procedure SetInMemory(Value: Boolean);
  // if all disconnected - destroy
  procedure CheckToDestroy;

 public
  FDatabaseName: AnsiString; // working directory or ESFS FileName
  DefaultFileStoreMode: TaaFileStoreMode; // default mode - fsmDisk or fsmFlatFile

  // creates manager with specified directory
  constructor Create(EDB: TEasyDatabase); overload;
  constructor Create(EDS: TEasyDataset); overload;
  constructor Create(DBName: AnsiString); overload;
  // destructor
  destructor Destroy; override;
  // open ESFS file
  procedure OpenESFSFile;
  // close ESFS file
  procedure CloseESFSFile;
  // detects if database with specified name is included
  function HasDatabaseName(DBName: AnsiString): boolean;
  // connect database component (adds to list)
  procedure ConnectDatabase(DBHandle: TEasyDatabase);
  // disconnect database component (removes from list)
  procedure DisconnectDatabase(DBHandle: TEasyDatabase);
  // connect dataset component (adds to list)
  procedure ConnectDataset(DSHandle: TEasyDataset);
  // disconnect dataset component (removes from list)
  procedure DisconnectDataset(DSHandle: TEasyDataset);
  // returns list of names of non temporary tables
  procedure GetNonTempTablesList(List: TStrings);
  // open file
  function OpenFile(
                    FileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode; // file store mode
                    bCreateFile: boolean; // create file?
                    bExclusive: boolean; // open in exclusive mode
                    bReadOnly: boolean // open in read-only mode
                   ): TAbstractFile;
  // close file
  procedure CloseFile(FileHandle: TAbstractFile);
  // if file exists returns true
  function aaFileExists(
                    FileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode
                     ): Boolean;
  // if file deleted successfully returns true
  function aaDeleteFile(
                    FileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode
                     ): Boolean;
  // if file renamed successfully returns true
  function aaRenameFile(
                    OldFileName, NewFileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode
                     ): Boolean;
  // if file copied successfully returns true
  function aaCopyFile(
                    OldFileName, NewFileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode; // old file store mode
                    NewDatabaseName: AnsiString = ''// new databasename
                     ): Boolean;

  // save file
  procedure SaveFile(FileName: AnsiString);

  // create ESFS files
  procedure CreateDatabase;
  // delete ESFS files
  procedure DeleteDatabase;
  // rename ESFS file
  function RenameDatabase(const NewDatabaseName: AnsiString): Boolean;
  // copy ESFS file
  function CopyDatabase(const NewDatabaseName: AnsiString): Boolean;

 published
  property Exists: Boolean read GetExists;
  property InMemory: Boolean read FInMemory write SetInMemory;
 end;

{$IFDEF FULL_VERSION}
 TEasyQuery = class;

 // TEasyQueryDataLink
  TEasyQueryDataLink = class(TDetailDataLink)
  private
    FQuery: TEasyQuery;
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
    function GetDetailDataSet: TDataSet; override;
    procedure CheckBrowseMode; override;
  public
    constructor Create(AQuery: TEasyQuery);
  end;

{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
  TEasyQuery = class(TEasyDataset)
   private
    FSQLProcessor: TSQLScriptProcessor;
    FSQL2: TStrings; // CB bug fix
    FSQLBinary: PAnsiChar;
    FText: AnsiString;
    FDataLink: TDataLink;
    FParams: TParams;
    FParamCheck2: Boolean;
    FRowsAffected: Integer;
    ResultTable: TEasyTable;
    FRequestLive : Boolean;

    // sets query text
    procedure SetQuery(Value: TStrings);
    // sets param list
    procedure SetParamsList(Value: TParams);
    // sets params from datasource
    procedure SetParamsFromCursor;
    // sets query
    procedure QueryChanged(Sender: TObject);
    // reads param data
    procedure ReadParamData(Reader: TReader);
    // writes param data
    procedure WriteParamData(Writer: TWriter);
    // read sql
    procedure ReadBinaryData(Stream: TStream);
    // writes sql
    procedure WriteBinaryData(Stream: TStream);
    // refreshes params
    procedure RefreshParams;

{$IFDEF D6H}
   protected
    // IProviderSupport
    procedure PSExecute; override;
    function PSGetDefaultOrder: TIndexDef; override;
    function PSGetParams: TParams; override;
    function PSGetTableName: String; override;
    procedure PSSetCommandText(const CommandText: String); override;
    procedure PSSetParams(AParams: TParams); override;
{$ENDIF}
   protected
    FSQL3: TStrings; // CB bug fix
    FSQL: TStrings;
    FSQL5: TStrings;
    FSQL4:  TStrings;
    FParamCheck: Boolean;

    // sets params datasource
    procedure SetDataSource(Value: TDataSource);
    // gets params datasource
    function GetDataSource: TDataSource; override;
    // gets params count
    function GetParamsCount: Word;
    // writes params, sql
    procedure DefineProperties(Filer: TFiler); override;
    // opens query
    procedure InternalOpen; override;
    // closes query
    procedure InternalClose; override;

   public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ExecSQL;

{$IFDEF D21H}
    procedure GetDetailLinkFields(MasterFields, DetailFields: TList<TField>); overload; override;
{$ELSE}
    // get master-detail links
    procedure GetDetailLinkFields(MasterFields, DetailFields: TList); override;
{$ENDIF}
    // gets param by name
    function ParamByName(const Value: AnsiString): TParam;

    // opens dataset as table
    procedure InternalOpenAsTable;
    // closes dataset as table
    procedure InternalCloseAsTable;

    property ParamCount: Word read GetParamsCount;
    property RowsAffected: Integer read FRowsAffected write FRowsAffected;
    property SQLBinary: PAnsiChar read FSQLBinary write FSQLBinary;
    property Text: AnsiString read FText;

   published
    property ParamCheck: Boolean read FParamCheck write FParamCheck default True;
    property RequestLive: Boolean Read FRequestLive Write FRequestLive;
    property SQL: TStrings Read FSQL Write SetQuery;
    property Params: TParams read FParams write SetParamsList stored False;

    // derived from TEasyDataset
    property CurrentVersion;
    // database name or directory or flat file
    property DatabaseName;
    // database file name (flat file)
    property DatabaseFileName;
    // in memory mode
    property InMemory;
    // params datasource
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    // FindFirst, FindNext ignores Filtered=True?
    property BDELikeFilter;
    // password
//    property Password: AnsiString read FPassword write FPassword;
    // Progress Event
//    property OnProgress : TaaProgressEvent read FOnProgress write FOnProgress;

    // derived from TDataset
    // filter text
    property Filter;
    // filter options
    property FilterOptions;
    // if true - table is filtered
    property Filtered;
    property AutoCalcFields;
    property Active;
    property CanModify;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
{$IFDEF D5H}
    property BeforeRefresh;
    property AfterRefresh;
{$ENDIF}
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
  end; // TEasyQuery
{$ENDIF}

 // database
{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
 TEasyDatabase = class(TComponent)
 private
  FDataSets: TList;
  FKeepConnection: Boolean;
  FTemporary: Boolean;
  FStreamedConnected: Boolean;
  FAcquiredHandle: Boolean;
  FHandleShared: Boolean;
  FReadOnly: Boolean;
  FRefCount: Integer;
  FHandle: TEasyDatabaseManager;
  FSession: TEasySession;
  FSessionName: AnsiString;
  FDatabaseName: AnsiString; // name of database
  FDirectory: AnsiString; // working path
  FDatabaseFileName: AnsiString; // database file name
  FInMemory: boolean; // in memory?
  FOnProgress: TProgressEvent; // progress for bulk operations
  FCancel:		 Boolean; // cancel
  FPassword:   AnsiString;  // password
  FDatabaseFileMode: TDatabaseFileMode;

  // raises exception if not active
  procedure CheckInactive;
  // raises exception if database name is not valid
  procedure CheckDatabaseName;
  // checks session name
  procedure CheckSessionName(Required: Boolean);
  // db connected?
  function GetConnected: Boolean;
  // connected dataset
  function GetDataSet(Index: Integer): TEasyDataSet;
  // count of connected datasets
  function GetDataSetCount: Integer;
  // opens from existing DB
  function OpenFromExistingDB: Boolean;

  // sets specified file name
  procedure SetDatabaseFileName(Value: AnsiString);
  // sets specified database name
  procedure SetDatabaseName(Value: AnsiString);
  // sets handle
  procedure SetHandle(Value: TEasyDatabaseManager);
  // sets specified directory
  procedure SetDirectory(dir: AnsiString);
  // keeps connection
  procedure SetKeepConnection(Value: Boolean);
  // sets read-only mode
  procedure SetReadOnly(Value: Boolean);
  // sets session name
  procedure SetSessionName(const Value: AnsiString);

  // connect / disconnect
  procedure SetConnected(value: boolean);
  // in memory mode
  procedure SetInMemory(Value: Boolean);
  // is database file encrypted
  function GetEncrypted: boolean;
  // is database file exists
  function GetExists: boolean;
  // on progress
  procedure DoOnProgress(Progress : Real; FProgressProcess: TaaProgressProcess);
  // get database manager
  procedure CreateHandle;
  // release database manager
  procedure DestroyHandle;
{$IFNDEF ENCRYPTION_ON}
  procedure SetPassword(Value: AnsiString);
{$ENDIF}
 protected
  // loaded
  procedure Loaded; override;
  // sends notification
  procedure Notification(AComponent: TComponent; Operation: TOperation); override;

 public
  // creates databases with specified directory
  constructor Create(AOwner: TComponent); override;
  // destructor
  destructor Destroy; override;
  // connected := true
  procedure Open;
  // connected := false
  procedure Close;
  // close all datasets
  procedure CloseDataSets;
  // validates name
  procedure ValidateName(const Name: AnsiString);
  // create ESFS files
  procedure CreateDatabase; overload;
  procedure CreateDatabase(NewDatabaseFileName: AnsiString); overload;
  // delete ESFS files
  procedure DeleteDatabase;
  // compact ESFS file
  procedure CompactProgress(
                             Sender      : TObject;
                             PercentDone : Real;
                             var Cancel: Boolean
                            );
  function CompactDatabase(var log: AnsiString): Boolean;
  // repair ESFS file
  procedure RepairProgress(
                             Sender      : TObject;
                             PercentDone : Real;
                             var Cancel: Boolean
                            );
  // change encryption of ESFS file
  procedure ChangeEncryptionProgress(
                             Sender      : TObject;
                             PercentDone : Real;
                             var Cancel: Boolean
                            );
  function RepairDatabase(var log: AnsiString; DeleteCorruptedFiles: Boolean = false): Boolean;
  // rename ESFS file
  function RenameDatabase(const NewDatabaseName: AnsiString): Boolean;
  // copy ESFS file
  function CopyDatabase(const NewDatabaseName: AnsiString): Boolean;
  // sets new encryption mode
  // if newPassword = '' then encryption will be removed
  function ChangeEncryption(newPassword: AnsiString = ''):Boolean;
  // get list of tables in database file
  procedure GetTablesList(List: TStrings);
  // determine if table exists
  function TableExists(TableName: AnsiString): Boolean;
  // deletes table
  procedure DeleteTable(TableName: AnsiString);
  // makes Exe database from edb file
  procedure MakeExeDatabase(ExeFileName, ExeDatabaseFileName: AnsiString);
  // returns true if this file is an EasyTable database
  function IsEasyTableDatabaseFile(FileName: AnsiString): Boolean;

  property DataSets[Index: Integer]: TEasyDataSet read GetDataSet;
  property DataSetCount: Integer read GetDataSetCount;
  property Directory: AnsiString read FDirectory write SetDirectory;
  property Exists: Boolean read GetExists;
  property Handle: TEasyDatabaseManager read FHandle write SetHandle;
  property Session: TEasySession read FSession;
  property Temporary: Boolean read FTemporary write FTemporary;

 published
   property Connected: boolean read GetConnected write SetConnected default false;
   property DatabaseFileMode: TDatabaseFileMode Read FDatabaseFileMode
              Write FDatabaseFileMode Default dfmNormal;
   property DatabaseFileName: AnsiString read FDatabaseFileName write SetDatabaseFileName;
   property DatabaseName: AnsiString read FDatabaseName write SetDatabaseName;
   property Encrypted: Boolean read GetEncrypted;
   property InMemory: Boolean read FInMemory write SetInMemory;
{$IFDEF ENCRYPTION_ON}
    property Password: AnsiString read FPassword write FPassword;
{$ELSE}
    property Password: AnsiString read FPassword write SetPassword;
{$ENDIF}
   property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
   property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
   property HandleShared: Boolean read FHandleShared write FHandleShared default False;
   property KeepConnection: Boolean read FKeepConnection write SetKeepConnection default True;
   property SessionName: AnsiString read FSessionName write SetSessionName;
 end;

  // global list of sessions
  TEasySessionList = class(TObject)
   private
    FSessions: TThreadList;
    FSessionNumbers: TBits;

    // adds session to list
    procedure AddSession(ASession: TEasySession);
    // closes all sessions
    procedure CloseAll;
    // Gets sessions count
    function GetCount: Integer;
    // Gets session by No
    function GetSession(Index: Integer): TEasySession;
    // gets current session
    function GetCurrentSession: TEasySession;
    // Gets session by Name
    function GetSessionByName(const SessionName: AnsiString): TEasySession;
    // Sets current session
    procedure SetCurrentSession(Value: TEasySession);

   public
    constructor Create;
    destructor Destroy; override;
    // Finds session by name
    function FindSession(const SessionName: AnsiString): TEasySession;
    // Gets list of sessions names
    procedure GetSessionNames(List: TStrings);
    // Opens session by name
    function OpenSession(const SessionName: AnsiString): TEasySession;

    property Count: Integer read GetCount;
    property CurrentSession: TEasySession read GetCurrentSession write SetCurrentSession;
    property Sessions[Index: Integer]: TEasySession read GetSession; default;
    property List[const SessionName: AnsiString]: TEasySession read GetSessionByName;
  end;

  TETblDatabaseEvent = (dbOpen, dbClose, dbAdd, dbRemove);
  TETblDatabaseNotifyEvent = procedure(DBEvent: TETblDatabaseEvent; const Param) of object;
  TETblPasswordEvent = procedure(Sender: TObject; var Continue: Boolean) of Object;

  // manager for TEasySession
  TEasySessionManager = class(TObject)
   private
    FPasswords: TStringList;

   public
    constructor Create;
    destructor Destroy; override;
    // adds password to list
    procedure AddPassword(const Password: AnsiString);
    // deletes password to list
    procedure DeletePassword(const Password: AnsiString);
    // deletes all passwords
    procedure DeleteAllPasswords;
  end;

  // TSession replacement for thread-safe use
{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
  TEasySession = class(TComponent)
  private
    FHandle: TEasySessionManager;
    FDatabases: TList;
    FStreamedActive: Boolean;
    FKeepConnections: Boolean;
    FDefault: Boolean;
    FAutoSessionName: Boolean;
    FUpdatingAutoSessionName: Boolean;
    FSessionName: AnsiString;
    FSessionNumber: Integer;
    FLockCount: Integer;

    FOnDBNotify: TETblDatabaseNotifyEvent;
    FOnPassword: TETblPasswordEvent;
    FOnStartup: TNotifyEvent;

    // adds database
    procedure AddDatabase(Value: TEasyDatabase);
    // raises exception if active
    procedure CheckInactive;
    // sends notification
    procedure DBNotification(DBEvent: TETblDatabaseEvent; const Param);
    // finds database with specified owner
    function DoFindDatabase(const DatabaseName, DatabaseFileName: AnsiString; AOwner: TComponent): TEasyDatabase;
    // opens database (thread-safe)
    function DoOpenDatabase(const DatabaseName, DatabaseFileName: AnsiString;
                            AOwner: TComponent): TEasyDatabase;
    // find DB manager by db name
    function FindDatabaseHandle(const DatabaseName: AnsiString): TEasyDatabaseManager;
    // session is active?
    function GetActive: Boolean;
    // gets database by No
    function GetDatabase(Index: Integer): TEasyDatabase;
    // gets count of connected databases
    function GetDatabaseCount: Integer;
    // gets handle
    function GetHandle: TEasySessionManager;
    // not auto-session?
    function SessionNameStored: Boolean;
    // makes session current
    procedure MakeCurrent;
    // removes database from list
    procedure RemoveDatabase(Value: TEasyDatabase);
    // opens session
    procedure SetActive(Value: Boolean);
    // sets auto-session name
    procedure SetAutoSessionName(Value: Boolean);
    // sets the name of session
    procedure SetSessionName(const Value: AnsiString);
    // sets session name to datasets and databases
    procedure SetSessionNames;
    // starts session
    procedure StartSession(Value: Boolean);
    // updates auto-session name
    procedure UpdateAutoSessionName;
    // auto-session name is valid?
    procedure ValidateAutoSession(AOwner: TComponent; AllSessions: Boolean);

  protected
    // loaded
    procedure Loaded; override;
    // send notification to datasets and databases
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    property OnDBNotify: TETblDatabaseNotifyEvent read FOnDBNotify write FOnDBNotify;
    // set name of component
    procedure SetName(const NewName: TComponentName); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // locks session
    procedure LockSession;
    // unlocks session
    procedure UnlockSession;
    // adds password
    procedure AddPassword(const Password: AnsiString);
    // gets password
    function GetPassword: Boolean;
    // remove all passwords from list
    procedure RemoveAllPasswords;
    // removes password
    procedure RemovePassword(const Password: AnsiString);
    // closes session
    procedure Close;
    // closes database
    procedure CloseDatabase(Database: TEasyDatabase);
    // drops all connections
    procedure DropConnections;
    // finds database by name
    function FindDatabase(const DatabaseName, DatabaseFileName: AnsiString): TEasyDatabase;
    // get list of database names
    procedure GetDatabaseNames(List: TStrings);
    // get list of database tables
    procedure GetTableNames(const DatabaseName, DatabaseFileName: AnsiString; List: TStrings);
    // opens session
    procedure Open;
    // opens database
    function OpenDatabase(const DatabaseName, DatabaseFileName: AnsiString): TEasyDatabase;

    property DatabaseCount: Integer read GetDatabaseCount;
    property Databases[Index: Integer]: TEasyDatabase read GetDatabase;
    property Handle: TEasySessionManager read GetHandle;

  published
    property Active: Boolean read GetActive write SetActive default False;
    property AutoSessionName: Boolean read FAutoSessionName write SetAutoSessionName default False;
    property KeepConnections: Boolean read FKeepConnections write FKeepConnections default True;
    property SessionName: AnsiString read FSessionName write SetSessionName stored SessionNameStored;
    property OnPassword: TETblPasswordEvent read FOnPassword write FOnPassword;
    property OnStartup: TNotifyEvent read FOnStartup write FOnStartup;
  end;

//---------------------------- general functions --------------------------
// this function detects AnsiString params, separated by [' ',',',';']
// and put this params in paramList
// Example : params = 'param1, param2;param3 param4'
//           paramList = ['param1','param2','param3','param4']
function GetStringParams(
         params : AnsiString; // source params
         paramList : TStringList // result param list
        ) : Integer; // returns number of detected AnsiString parameters

function isStreamGraphic (stream : TStream) : Boolean;
function FindFieldInSourceTable(fieldDefinitions : TFieldDefs; name : AnsiString) : Boolean;

function DateTimeToNative(DataType: TFieldType; Data: TDateTime): TDateTimeRec;

// Database component finding
function aaFindDatabase(DBName: AnsiString; DatabaseList: TList): TEasyDatabase;

// Find Index specified by fields and case-insensitive fields
function aaFindIndexByFields(Table: TEasyDataset;
  IndexFieldNames, DescFields, CaseInsensitiveFields: AnsiString): Integer;

function aaGetDatabaseManager(EDB: TEasyDatabase): TEasyDatabaseManager;

// returns true if field type is blob
function IsBLOBFieldType(FieldType: TFieldType): Boolean;

// returns true if fields of this type could be indexed
function IsFieldTypeCanCompriseIndex(FieldType: TFieldType): Boolean;

var
    Session: TEasySession;
    Sessions: TEasySessionList;


implementation
uses
 ESingleFileSystem,
 ESFSEngine,
 ETblExpr,
 ETblRelationalAlgebra,
 ETblPasswordDialog,
 ETblCompress;
{*******************************************************}
{                                                       }
{       Borland Delphi Supplemental Components          }
{       ZLIB Data Compression Interface Unit            }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}
// ZLib 1.1.3 source files (http://www.info-zip.org/pub/infozip/zlib)

{ Modified for zlib 1.1.3 by Davide Moretti <dave@rimini.com }

{                                                            }
{ (09/20/99) Ryan Mills. <rmills@freenet.edmonton.ab.ca>     }
{ Further modified to be more compatible with the D5 version }
{ of the ZLIB component, integrating the speed enhancements  }
{ introduced by Borland.                                     }
 // and PPMd
 // variant G
 // Date    : Nov 26, 2000
 // by Dmitry Shkarin
 // E-mail: shkarin@arstel.ru


// PFS manager
var PFSManager: TPFSManager;
    CurrentSessionManager: TEasySessionManager;
    Initialized: Boolean;
    FDBMLockSection: Pointer;
    FDMLockSection:  Pointer;


//------------------------------------------------------------------------------
// inits engine
//------------------------------------------------------------------------------
procedure InitializeEasyTable;
begin
  if (not Initialized) then
   begin
     Initialized:=True;
     CurrentSessionManager:=TEasySessionManager.Create;
   end;
end;


//------------------------------------------------------------------------------
// finalizes engine
//------------------------------------------------------------------------------
procedure FinalizeEasyTable;
begin
  if (Initialized) then
   begin
     Initialized:=False;
     CurrentSessionManager.Free;
   end;
end;

//------------------------------------------------------------------------------
// gets default session
//------------------------------------------------------------------------------
function ETblDefaultSession: TEasySession;
begin
   Result:=EasyTable.Session;
end;

//------------------------------------------------------------------------------
// gets current session manager
//------------------------------------------------------------------------------
function ETblGetCurrentSession: TEasySessionManager;
begin
  if (not Initialized) then
   raise ETblException.Create(01077, nil);
  Result := CurrentSessionManager;
end;

//------------------------------------------------------------------------------
// sets current session manager
//------------------------------------------------------------------------------
procedure ETblSetCurrentSession(Value: TEasySessionManager);
begin
  CurrentSessionManager := Value;
end;

//------------------------------------------------------------------------------
// creates session manager
//------------------------------------------------------------------------------
procedure ETblStartSession(var Value: TEasySessionManager);
begin
  Value := TEasySessionManager.Create;
end;

//------------------------------------------------------------------------------
// frees session manager
//------------------------------------------------------------------------------
procedure ETblCloseSession(Value: TEasySessionManager);
begin
  if (Value <> nil) then
    Value.Free;
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
function aaIsDirectory(const DatabaseName: AnsiString): Boolean;
var
  I: Integer;
begin
  Result := True;
  if (DatabaseName = '') then Exit;
  I := 1;
  while I <= Length(DatabaseName) do
  begin
    if DatabaseName[I] in [':','\'] then Exit;
    if DatabaseName[I] in LeadBytes then Inc(I, 2)
    else Inc(I);
  end;
  Result := False;
end;


//------------------------------------------------------------------------------
// DatabaseManager
//------------------------------------------------------------------------------
function aaGetDatabaseManager(EDB: TEasyDatabase): TEasyDatabaseManager;
var
  I: Integer;
  bFound: boolean;
  DBMHandle: TEasyDatabaseManager;
  DBName: AnsiString;
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
  bFound := false;
  DBMHandle := nil;

//  if (EDB.DatabaseName <> '') then
//   DBName := EDB.DatabaseName
//  else
  if (EDB.Directory <> '') then
   DBName := EDB.Directory
  else
  if (UpperCase(EDB.DatabaseName) = 'MEMORY') then
   DBName := EDB.DatabaseName
  else
   DBName := EDB.DatabaseFileName;

 // find database manager
 if (DBName <> '') then
   for I := DatabaseManagerList.Count - 1 downto 0 do
    begin
       if (TEasyDatabaseManager(DatabaseManagerList.Items[i]).HasDatabaseName(DBName)) then
         begin
           bFound := true;
           DBMHandle := TEasyDatabaseManager(DatabaseManagerList.Items[i]);
           break;
         end;
    end;

  // if not found then create
  if bFound then
    Result := DBMHandle
  else
   begin
{    if (EDB.Directory <> '') then
     DBName := EDB.Directory
    else
     DBName := EDB.DatabaseFileName;}
//    Result := TEasyDatabaseManager.Create(DBName);
    Result := TEasyDatabaseManager.Create(EDB);
    Result.SMHandle := EDB.Session.Handle;
   end;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//aaGetDatabaseManager


//------------------------------------------------------------------------------
// Database component finding
//------------------------------------------------------------------------------

function aaFindDatabase(DBName: AnsiString; DatabaseList: TList): TEasyDatabase;
var
  i: Integer;
begin
 Result := nil;
 if (DBName <> '') then
 // find database
 for i:=0 to DatabaseList.Count-1 do
  if (TEasyDatabase(DatabaseList.Items[i]).Temporary) then
    continue
  else
    if (LowerCase(TEasyDatabase(DatabaseList.Items[i]).DatabaseName) = LowerCase(DBName)) or
     (LowerCase(TEasyDatabase(DatabaseList.Items[i]).DatabaseFileName) = LowerCase(DBName)) then
      begin
        Result := TEasyDatabase(DatabaseList.Items[i]);
        break;
      end;
end;//aaFindDatabase


//------------------------------------------------------------------------------
// Find Index specified by fields and case-insensitive fields
//------------------------------------------------------------------------------
function aaFindIndexByFields(Table: TEasyDataset;
  IndexFieldNames, DescFields, CaseInsensitiveFields: AnsiString): Integer;
var i: integer;
begin
 result := -1;
 for i := 0 to Table.IndexDefs.Count-1 do
  begin
   if (UpperCase(Table.IndexDefs.Items[i].Fields) = UpperCase(IndexFieldNames)) then
    if (UpperCase(Table.IndexDefs.Items[i].CaseInsFields) = UpperCase(CaseInsensitiveFields)) then
     if (UpperCase(Table.IndexDefs.Items[i].DescFields) = UpperCase(DescFields)) then
     begin
      result := i;
      break;
     end;
  end;
end; // aaFindIndexByFields


//------------------------------------------------------------------------------
// DataManager
//------------------------------------------------------------------------------
function aaGetDataManager(TableName: AnsiString; DBMHandle: TEasyDatabaseManager): TEasyDataManager;
var
  I: Integer;
  bFound: boolean;
  DMHandle: TEasyDataManager;
begin
 ETblEnterCriticalSection(FDMLockSection);
 Result := nil;
 try
  if (DBMHandle = nil) then
   Raise Exception.Create('aaGetDataManager - nil pointer to DatabaseManager.');

  bFound := false;
  DMHandle := nil;
  // find database manager
  for I := DataManagerList.Count - 1 downto 0 do
    begin
       if (LowerCase(TEasyDataManager(DataManagerList.Items[i]).FTableName) =
           LowerCase(TableName)) and  // 5.31 bug fix with '' databases
          (TEasyDataManager(DataManagerList.Items[i]).DBMHandle.FDatabaseName = DBMHandle.FDatabaseName) then
         begin
           bFound := true;
           DMHandle := TEasyDataManager(DataManagerList.Items[i]);
           break;
         end;
    end;

  // if not found then create
  if bFound then
    Result := DMHandle
  else
    Result := TEasyDataManager.Create(TableName, DBMHandle);
 finally
  ETblLeaveCriticalSection(FDMLockSection);
 end;
end;//aaGetDataManager


//------------------------------------------------------------------------------
// deletes all objects from lists
//------------------------------------------------------------------------------
procedure TaaList.Clear;
var i : integer;
begin
  for i := 0 to Count-1 do
   if (Items[i] <> nil) then dispose(Items[i]);
  inherited Clear;
end; //TaaList.Clear


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasySessionList
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasySessionList.Create;
begin
   inherited Create;
   FSessions:=TThreadList.Create;
   FSessionNumbers:=TBits.Create;
   FCSect:=ETblAllocCriticalSection;
   ETblInitializeCriticalSection(FCSect);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasySessionList.Destroy;
begin
  CloseAll;
  ETblDeleteCriticalSection(FCSect);
  ETblFreeCriticalSection(FCSect);
  FSessionNumbers.Free;
  FSessions.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// adds session to list
//------------------------------------------------------------------------------
procedure TEasySessionList.AddSession(ASession: TEasySession);
var
  List: TList;
begin
  List:=FSessions.LockList;
  try
{$IFNDEF FULL_VERSION}
   if (List.Count > 0) then
     raise Exception.Create('Multi-thread capabilities are disabled in EasyTable Lite. Please use other editions of EasyTable.');
{$ENDIF}
   if (List.Count=0) then
     ASession.FDefault:=True;
   List.Add(ASession);
  finally
   FSessions.UnlockList;
  end;
end;// AddSession


//------------------------------------------------------------------------------
// closes all sessions
//------------------------------------------------------------------------------
procedure TEasySessionList.CloseAll;
var
  I: Integer;
  List: TList;
begin
  List:=FSessions.LockList;
  try
    for I:=List.Count-1 downto 0 do
      TEasySession(List[I]).Free;
  finally
    FSessions.UnlockList;
  end;
end;// CloseAll


//------------------------------------------------------------------------------
// Gets sessions count
//------------------------------------------------------------------------------
function TEasySessionList.GetCount: Integer;
var
  List: TList;
begin
  List:=FSessions.LockList;
  try
    Result:=List.Count;
  finally
    FSessions.UnlockList;
  end;
end;// GetCount


//------------------------------------------------------------------------------
// gets current session
//------------------------------------------------------------------------------
function TEasySessionList.GetCurrentSession: TEasySession;
var
  Handle: TEasySessionManager;
  I: Integer;
  List: TList;
begin
  List:=FSessions.LockList;
  try
    Handle := CurrentSessionManager;
    for I:=0 to List.Count-1 do
      begin
       if (TEasySession(List[I]).FHandle=Handle) then
         begin
           Result:=TEasySession(List[I]);
           Exit;
         end;
      end;
    Result:=nil;
  finally
    FSessions.UnlockList;
  end;
end;// GetCurrentSession


//------------------------------------------------------------------------------
// Gets session by No
//------------------------------------------------------------------------------
function TEasySessionList.GetSession(Index: Integer): TEasySession;
var
  List: TList;
begin
  List:=FSessions.LockList;
  try
    Result:=TEasySession(List[Index]);
  finally
    FSessions.UnlockList;
  end;
end;// GetSession


//------------------------------------------------------------------------------
// Gets session by Name
//------------------------------------------------------------------------------
function TEasySessionList.GetSessionByName(const SessionName: AnsiString): TEasySession;
begin
  if (SessionName = '') then
    Result:=Session
  else
    Result:=FindSession(SessionName);
  if (Result=nil) then
    raise ETblException.Create(01072, [SessionName], nil);
end;// GetSessionByName


//------------------------------------------------------------------------------
// Finds session by name
//------------------------------------------------------------------------------
function TEasySessionList.FindSession(const SessionName: AnsiString): TEasySession;
var
  I: Integer;
  List: TList;
begin
  if (SessionName='') then
    Result:=Session
  else
    begin
      List:=FSessions.LockList;
      try
        for I:=0 to List.Count-1 do
          begin
            Result:=List[I];
            if AnsiCompareText(Result.SessionName,SessionName)=0 then
               Exit;
          end;
        Result:=nil;
      finally
        FSessions.UnlockList;
      end;
    end;
end;// FindSession


//------------------------------------------------------------------------------
// Gets list of sessions names
//------------------------------------------------------------------------------
procedure TEasySessionList.GetSessionNames(List: TStrings);
var
  I: Integer;
  SList: TList;
begin
  List.BeginUpdate;
  try
    List.Clear;
    SList:=FSessions.LockList;
    try
      for I:=0 to SList.Count-1 do
        with TEasySession(SList[I]) do
          List.Add(SessionName);
    finally
      FSessions.UnlockList;
    end;
  finally
    List.EndUpdate;
  end;
end;// GetSessionNames


//------------------------------------------------------------------------------
// Opens session by name
//------------------------------------------------------------------------------
function TEasySessionList.OpenSession(const SessionName: AnsiString): TEasySession;
begin
  Result:=FindSession(SessionName);
  if (Result=nil) then
    begin
      Result:=TEasySession.Create(nil);
      Result.SessionName:=SessionName;
    end;
  Result.SetActive(True);
end;// OpenSession


//------------------------------------------------------------------------------
// Sets current session
//------------------------------------------------------------------------------
procedure TEasySessionList.SetCurrentSession(Value: TEasySession);
begin
  ETblSetCurrentSession(Value.FHandle);
end;// SetCurrentSession



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasySessionManager
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasySessionManager.Create;
begin
  FPasswords := TStringList.Create;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasySessionManager.Destroy;
begin
  FPasswords.Free;
end;// Destroy


//------------------------------------------------------------------------------
// adds password to list
//------------------------------------------------------------------------------
procedure TEasySessionManager.AddPassword(const Password: AnsiString);
begin
  FPasswords.Add(Password);
end;// AddPassword


//------------------------------------------------------------------------------
// deletes password to list
//------------------------------------------------------------------------------
procedure TEasySessionManager.DeletePassword(const Password: AnsiString);
var
  I, Pos: Integer;
begin
  Pos := -1;
  for I:=0 to FPasswords.Count-1 do
   if (AnsiCompareStr(FPasswords.Strings[I], Password)=0) then
    begin
      Pos:=I;
      Break;
    end;
  FPasswords.Delete(Pos);
end;// DeletePassword


//------------------------------------------------------------------------------
// deletes all passwords
//------------------------------------------------------------------------------
procedure TEasySessionManager.DeleteAllPasswords;
begin
  FPasswords.Clear;
end;// DeleteAllPasswords



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasySession
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasySession.Create(AOwner: TComponent);
begin
  ValidateAutoSession(AOwner,False);
  inherited Create(AOwner);
  FDatabases:=TList.Create;
  Sessions.AddSession(Self);
  FKeepConnections:=True;
  FHandle := nil;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasySession.Destroy;
begin
  SetActive(False);
  Sessions.FSessions.Remove(Self);
  FDatabases.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// adds database
//------------------------------------------------------------------------------
procedure TEasySession.AddDatabase(Value: TEasyDatabase);
begin
  FDatabases.Add(Value);
  DBNotification(dbAdd,Value);
end;// AddDatabase


//------------------------------------------------------------------------------
// raises exception if active
//------------------------------------------------------------------------------
procedure TEasySession.CheckInactive;
begin
  if Active then
    raise ETblException.Create(01073, Self);
end;// CheckInactive


//------------------------------------------------------------------------------
// closes session
//------------------------------------------------------------------------------
procedure TEasySession.Close;
begin
  SetActive(False);
end;// Close


//------------------------------------------------------------------------------
// closes database
//------------------------------------------------------------------------------
procedure TEasySession.CloseDatabase(Database: TEasyDatabase);
begin
  with Database do
  begin
    if FRefCount <> 0 then Dec(FRefCount);
    if (FRefCount = 0) and not KeepConnection then
      if not Temporary then Close else
         if not (csDestroying in ComponentState) then Free;
  end;
end;// CloseDatabase


//------------------------------------------------------------------------------
// sends notification
//------------------------------------------------------------------------------
procedure TEasySession.DBNotification(DBEvent: TETblDatabaseEvent; const Param);
begin
  if Assigned(FOnDBNotify) then FOnDBNotify(DBEvent, Param);
end;// DBNotification


//------------------------------------------------------------------------------
// drops all connections
//------------------------------------------------------------------------------
procedure TEasySession.DropConnections;
var
  I: Integer;
begin
  for I := FDatabases.Count - 1 downto 0 do
    with TEasyDatabase(FDatabases[I]) do
      if Temporary and (FRefCount = 0) then
        Free;
end;// DropConnections


//------------------------------------------------------------------------------
// finds database by name
//------------------------------------------------------------------------------
function TEasySession.FindDatabase(const DatabaseName, DatabaseFileName: AnsiString): TEasyDatabase;
var
  I: Integer;
begin
  for I := 0 to FDatabases.Count - 1 do
  begin
    Result := FDatabases[I];
    if ((Result.DatabaseName <> '') or Result.Temporary) and
      (AnsiCompareText(Result.DatabaseName, DatabaseName) = 0) then
       begin
        if ((DatabaseName = '') and
            (Result.DatabaseFileName <> DatabaseFileName)) then
         Continue;
        Exit;
       end;
  end;
  Result := nil;
end;// FindDatabase


//------------------------------------------------------------------------------
// finds database with specified owner
//------------------------------------------------------------------------------
function TEasySession.DoFindDatabase(const DatabaseName, DatabaseFileName: AnsiString; AOwner: TComponent): TEasyDatabase;
var
  I: Integer;
begin
  if AOwner <> nil then
    for I := 0 to FDatabases.Count - 1 do
    begin
      Result := FDatabases[I];
      if (Result.Owner = AOwner) and (Result.HandleShared) and
        (AnsiCompareText(Result.DatabaseName, DatabaseName) = 0) then
         Exit;
    end;
  Result := FindDatabase(DatabaseName, DatabaseFileName);
end;// DoFindDatabase


//------------------------------------------------------------------------------
// session is active?
//------------------------------------------------------------------------------
function TEasySession.GetActive: Boolean;
begin
  Result := FHandle <> nil;
end;// GetActive


//------------------------------------------------------------------------------
// gets database by No
//------------------------------------------------------------------------------
function TEasySession.GetDatabase(Index: Integer): TEasyDatabase;
begin
  Result := FDatabases[Index];
end;// GetDatabase


//------------------------------------------------------------------------------
// gets count of connected databases
//------------------------------------------------------------------------------
function TEasySession.GetDatabaseCount: Integer;
begin
  Result := FDatabases.Count;
end;// GetDatabaseCount


//------------------------------------------------------------------------------
// get list of database names
//------------------------------------------------------------------------------
procedure TEasySession.GetDatabaseNames(List: TStrings);
var
  I: Integer;
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    for I := 0 to FDatabases.Count - 1 do
      with TEasyDatabase(FDatabases[I]) do
        if not aaIsDirectory(DatabaseName) then
         Names.Add(DatabaseName);
    List.Assign(Names);
  finally
    Names.Free;
  end;
end;// GetDatabaseNames


//------------------------------------------------------------------------------
// get list of database tables
//------------------------------------------------------------------------------
procedure TEasySession.GetTableNames(const DatabaseName, DatabaseFileName: AnsiString; List: TStrings);
var
   Database: TEasyDatabase;
begin
  List.BeginUpdate;
  try
    List.Clear;
    Database := OpenDatabase(DatabaseName, DatabaseFileName);
    try
      if (Database <> nil) and (Database.Handle <> nil) then
        Database.Handle.GetNonTempTablesList(List);
    finally
      CloseDatabase(Database);
    end;
  finally
     List.EndUpdate;
  end;
end;// GetTableNames


//------------------------------------------------------------------------------
// gets handle
//------------------------------------------------------------------------------
function TEasySession.GetHandle: TEasySessionManager;
begin
  if (FHandle <> nil) then
    ETblSetCurrentSession(FHandle)
  else
    SetActive(True);
  Result:=FHandle;
end;// GetHandle


//------------------------------------------------------------------------------
// loaded
//------------------------------------------------------------------------------
procedure TEasySession.Loaded;
begin
  inherited Loaded;
  if AutoSessionName then
     SetSessionNames;
  if FStreamedActive then
     SetActive(True);
end;// Loaded


//------------------------------------------------------------------------------
// locks session
//------------------------------------------------------------------------------
procedure TEasySession.LockSession;
begin
  if (FLockCount=0) then
    begin
      ETblEnterCriticalSection(FCSect);
      Inc(FLockCount);
      try
        MakeCurrent;
      except
        UnlockSession;
        raise;
      end;
   end
 else
   Inc(FLockCount);
end;


//------------------------------------------------------------------------------
// unlocks session
//------------------------------------------------------------------------------
procedure TEasySession.UnlockSession;
begin
  Dec(FLockCount);
  if (FLockCount=0) then
    ETblLeaveCriticalSection(FCSect);
end;// UnlockSession


//------------------------------------------------------------------------------
// makes session current
//------------------------------------------------------------------------------
procedure TEasySession.MakeCurrent;
begin
  if (FHandle <> nil) then
    ETblSetCurrentSession(FHandle)
  else
    SetActive(True);
end;// MakeCurrent


//------------------------------------------------------------------------------
// send notification to datasets and databases
//------------------------------------------------------------------------------
procedure TEasySession.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);
  if AutoSessionName and (Operation=opInsert) then
    begin
      if (AComponent is TEasyDataSet) then
        TEasyDataSet(AComponent).FSessionName:=Self.SessionName
      else
       if (AComponent is TEasyDatabase) then
        TEasyDatabase(AComponent).FSession:=Self;
      end;
end;// Notification


//------------------------------------------------------------------------------
// opens session
//------------------------------------------------------------------------------
procedure TEasySession.Open;
begin
  SetActive(True);
end;// Open


//------------------------------------------------------------------------------
// opens database (thread-safe)
//------------------------------------------------------------------------------
function TEasySession.DoOpenDatabase(const DatabaseName, DatabaseFileName: AnsiString;
                                     AOwner: TComponent): TEasyDatabase;
var
  TempDatabase: TEasyDatabase;
begin
  Result := nil;
  LockSession;
  try
    TempDatabase := nil;
    try
      Result := DoFindDatabase(DatabaseName, DatabaseFileName, AOwner);
      if Result = nil then
      begin
        TempDatabase := TEasyDatabase.Create(Self);
        TempDatabase.DatabaseName := DatabaseName;
        TempDatabase.DatabaseFileName := DatabaseFileName;
        TempDatabase.KeepConnection := FKeepConnections;
        TempDatabase.Temporary := True;
        if (UpperCase(DatabaseName) = 'MEMORY') then
         TempDatabase.InMemory := True;
        Result := TempDatabase;
      end;
      Result.Open;
      Inc(Result.FRefCount);
    except
      TempDatabase.Free;
      raise;
    end;
  finally
    UnLockSession;
  end;
end;// DoOpenDatabase


//------------------------------------------------------------------------------
// find DB manager by db name
//------------------------------------------------------------------------------
function TEasySession.FindDatabaseHandle(const DatabaseName: AnsiString): TEasyDatabaseManager;
var
  I: Integer;
  DB: TEasyDatabase;
begin
  for I := 0 to FDatabases.Count - 1 do
  begin
    DB := FDatabases[I];
    if (DB.Handle <> nil) and
       (AnsiCompareText(DB.DatabaseName, DatabaseName) = 0) and
       DB.HandleShared then
    begin
      Result := DB.Handle;
      Exit;
    end;
  end;
  Result := nil;
end;// FindDatabaseHandle


//------------------------------------------------------------------------------
// opens database
//------------------------------------------------------------------------------
function TEasySession.OpenDatabase(const DatabaseName, DatabaseFileName: AnsiString): TEasyDatabase;
begin
  Result := DoOpenDatabase(DatabaseName, DatabaseFileName, nil);
end;// OpenDatabase


//------------------------------------------------------------------------------
// not auto-session?
//------------------------------------------------------------------------------
function TEasySession.SessionNameStored: Boolean;
begin
  Result := not FAutoSessionName;
end;// SessionNameStored


//------------------------------------------------------------------------------
// removes database from list
//------------------------------------------------------------------------------
procedure TEasySession.RemoveDatabase(Value: TEasyDatabase);
begin
  FDatabases.Remove(Value);
  DBNotification(dbRemove, Value);
end;// RemoveDatabase


//------------------------------------------------------------------------------
// opens session
//------------------------------------------------------------------------------
procedure TEasySession.SetActive(Value: Boolean);
begin
  if csReading in ComponentState then
    FStreamedActive := Value
  else
    if Active <> Value then
      StartSession(Value);
end;// SetActive


//------------------------------------------------------------------------------
// sets auto-session name
//------------------------------------------------------------------------------
procedure TEasySession.SetAutoSessionName(Value: Boolean);
begin
  if Value <> FAutoSessionName then
  begin
    if Value then
    begin
      CheckInActive;
      ValidateAutoSession(Owner, True);
      FSessionNumber := -1;
      ETblEnterCriticalSection(FCSect);
      try
        with Sessions do
        begin
          FSessionNumber := FSessionNumbers.OpenBit;
          FSessionNumbers[FSessionNumber] := True;
        end;
      finally
        ETblLeaveCriticalSection(FCSect);
      end;
      UpdateAutoSessionName;
    end
    else
    begin
      if FSessionNumber > -1 then
      begin
        ETblEnterCriticalSection(FCSect);
        try
          Sessions.FSessionNumbers[FSessionNumber] := False;
        finally
          ETblLeaveCriticalSection(FCSect);
        end;
      end;
    end;
    FAutoSessionName := Value;
  end;
end;// SetAutoSessionName


//------------------------------------------------------------------------------
// set name of component
//------------------------------------------------------------------------------
procedure TEasySession.SetName(const NewName: TComponentName);
begin
  inherited SetName(NewName);
  if FAutoSessionName then
    UpdateAutoSessionName;
end;// SetName


//------------------------------------------------------------------------------
// sets the name of session
//------------------------------------------------------------------------------
procedure TEasySession.SetSessionName(const Value: AnsiString);
var
  Ses: TEasySession;
begin
  if FAutoSessionName and not FUpdatingAutoSessionName then
   raise ETblException.Create(01074, Self);
  CheckInActive;
  if Value <> '' then
  begin
    Ses := Sessions.FindSession(Value);
    if not ((Ses = nil) or (Ses = Self)) then
   raise ETblException.Create(01075, [Value], Self);
  end;
  FSessionName := Value
end;// SetSessionName


//------------------------------------------------------------------------------
// sets session name to datasets and databases
//------------------------------------------------------------------------------
procedure TEasySession.SetSessionNames;
var
  I: Integer;
  Component: TComponent;
begin
  if Owner <> nil then
    for I := 0 to Owner.ComponentCount - 1 do
    begin
      Component := Owner.Components[I];
      if (Component is TEasyDataSet) and
        (AnsiCompareText(TEasyDataSet(Component).SessionName, Self.SessionName) <> 0) then
        TEasyDataSet(Component).SessionName := Self.SessionName
      else if (Component is TEasyDataBase) and
        (AnsiCompareText(TEasyDatabase(Component).SessionName, Self.SessionName) <> 0) then
        TEasyDataBase(Component).SessionName := Self.SessionName
    end;
end;// SetSessionNames


//------------------------------------------------------------------------------
// starts session
//------------------------------------------------------------------------------
procedure TEasySession.StartSession(Value: Boolean);
var
  I: Integer;
begin
  ETblEnterCriticalSection(FCSect);
  try
    if Value then
      begin
        if Assigned(FOnStartup) then
          FOnStartup(Self);
        // session name missing?
        if (FSessionName='') then
         raise ETblException.Create(01076, Self);
        // activate default session
        if (ETblDefaultSession <> Self) then
            ETblDefaultSession.Active:=True;
        // default session?
        if FDefault then
          begin
            InitializeEasyTable;
            FHandle:=ETblGetCurrentSession;
          end
        else
          ETblStartSession(FHandle);
      end
    else
     begin
       ETblSetCurrentSession(FHandle);
       for I:=FDatabases.Count-1 downto 0 do
         begin
           with TEasyDatabase(FDatabases[I]) do
             begin
               if Temporary then
                 Free
               else
                 Close;
             end;
         end;
       if FDefault then
         FinalizeEasyTable
       else
         begin
           ETblCloseSession(FHandle);
           ETblSetCurrentSession(Session.FHandle);
         end;
       FHandle:=nil;
     end;
  finally
    ETblLeaveCriticalSection(FCSect);
  end;
end;// StartSession


//------------------------------------------------------------------------------
// updates auto-session name
//------------------------------------------------------------------------------
procedure TEasySession.UpdateAutoSessionName;
begin
  FUpdatingAutoSessionName := True;
  try
    SessionName := Format('%s_%d', [Name, FSessionNumber + 1]);
  finally
    FUpdatingAutoSessionName := False;
  end;
  SetSessionNames;
end;// UpdateAutoSessionName


//------------------------------------------------------------------------------
// auto-session name is valid?
//------------------------------------------------------------------------------
procedure TEasySession.ValidateAutoSession(AOwner: TComponent; AllSessions: Boolean);
var
  I: Integer;
  Component: TComponent;
begin
  if AOwner <> nil then
    for I := 0 to AOwner.ComponentCount - 1 do
    begin
      Component := AOwner.Components[I];
      if (Component <> Self) and (Component is TEasySession) then
        if AllSessions then
         raise ETblException.Create(01078, Self)
        else
        if TEasySession(Component).AutoSessionName then
         raise ETblException.Create(01079, [Component.Name], Self)
    end;
end;// ValidateAutoSession


//------------------------------------------------------------------------------
// adds password
//------------------------------------------------------------------------------
procedure TEasySession.AddPassword(const Password: AnsiString);
begin
   LockSession;
   try
      FHandle.AddPassword(Password);
   finally
      UnlockSession;
   end;
end;// AddPassword


//------------------------------------------------------------------------------
// gets password
//------------------------------------------------------------------------------
function TEasySession.GetPassword: Boolean;
begin
  if Assigned(FOnPassword) then
    begin
      Result:=False;
      FOnPassword(Self,Result);
    end
  else
    Result:=PasswordDialog(Self, '');
end;// GetPassword


//------------------------------------------------------------------------------
// remove all passwords from list
//------------------------------------------------------------------------------
procedure TEasySession.RemoveAllPasswords;
begin
  LockSession;
  try
    FHandle.DeleteAllPasswords;
  finally
    UnlockSession;
  end;
end;// RemoveAllPasswords


//------------------------------------------------------------------------------
// removes password
//------------------------------------------------------------------------------
procedure TEasySession.RemovePassword(const Password: AnsiString);
begin
  LockSession;
  try
    FHandle.DeletePassword(Password);
  finally
    UnlockSession;
  end;
end;// RemovePassword




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyBlobStream
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasyBlobStream.Create(Field: TBlobField; Mode: TBlobStreamMode);
begin
 FOpened := false;
 FField := Field;
 FMode := Mode;
 if ((Mode <> bmRead) and (TEasyDataset(Field.DataSet).ReadOnly))
  then raise Exception.Create(
      	'Error in TEasyBlobStream.Create - Dataset is read only!');
 if (TEasyDataset(Field.DataSet).GetActiveRecordBuffer = nil) then
  Exit;
 FStream := TEasyDataset(Field.DataSet).InternalCreateBlobStream(Field.DataSet.FieldByName
 (Field.FieldName),
             Mode);
 FOpened := true;

 FModified := False;
 if (Mode = bmWrite) then
  Truncate;
end; //TEasyBlobStream.Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyBlobStream.Destroy;
begin
 if (Not FOpened) then Exit;
 if FModified then
   FField.Modified:=True;
 if FModified then
  TEasyDataset(FField.DataSet).DataEvent(deFieldChange,Integer(FField));
 TEasyDataset(FField.DataSet).CloseBlob(FField.DataSet.fieldByName(FField.FieldName));
end; //TEasyBlobStream.Destroy;


//------------------------------------------------------------------------------
// read
//------------------------------------------------------------------------------
function TEasyBlobStream.Read(var Buffer; Count: Longint): Longint;
begin
 result := 0;
 if (FOpened) then
  result := Fstream.Read(Buffer,Count);
end; //TEasyBlobStream.Read


//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------
function TEasyBlobStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (FMode = bmRead) then raise Exception.Create(
      	'Error in TEasyBlobStream.Write - blob stream is read only!');
 result := 0;
 if (FOpened) then
  result := Fstream.Write(Buffer,Count);
 FModified:=True;
end; //TEasyBlobStream.Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TEasyBlobStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 result := 0;
 if (FOpened) then
  result := Fstream.Seek(Offset,Origin);
end; //TEasyBlobStream.Seek


//------------------------------------------------------------------------------
// truncate
//------------------------------------------------------------------------------
procedure TEasyBlobStream.Truncate;
begin
 if (FOpened) then
  begin
   FStream.Size := Fstream.Position;
   FModified:=True;
  end;
end; //TEasyBlobStream.Truncate;




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyDataManager
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasyDataManager.Create(TableName: AnsiString; newDBMHandle: TEasyDatabaseManager);
begin
 FRepairIsRunning := false;
 FLockSection := ETblAllocCriticalSection;
 ETblInitializeCriticalSection(FLockSection);
 FLockCount := 0;
 SilentMode := True;

// FTemporaryIndexCount := 0;

 ETblEnterCriticalSection(FDMLockSection);
 try
  // add to global list of data managers
  DataManagerList.Add(Self);
 finally
  ETblLeaveCriticalSection(FDMLockSection);
 end;

 DatasetList := TList.Create;
 FTableName := TableName;
 DBMHandle := newDBMHandle;
 // DMHandle.indexes update settings
 LastIOOpTime := GetTickCount;
 ThresholdDelay := 1000; // (in ticks) - max allowed delay
 ThresholdDelayNo := 0; // there were no delays yet
 ThresholdDelayMaxCount := 100; // after these delays - DMHandle.indexes aren't updated
 ThresholdRecordCount := 10; // after these records - DMHandle.indexes are always updated
 blobHeaders := TaaBLOBHeadersArray.Create;
 blobDelParts := TaaBLOBPartsArray.Create(0);
 blobMap := TaaIntArray.Create;
 indexHeaderList := TaaList.Create;
 fieldHeaderList := TaaList.Create;
 tableHeader.fieldCount := 0;
 FFlushesEnabled := True;
 PageRecordCount := DefaultRecordsPerPage;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyDataManager.Destroy;
begin
 ETblEnterCriticalSection(FDMLockSection);
 try
  // removes from global list of data managers
  if (isTableOpened) then
   CloseTable;
  DataManagerList.Remove(Self);
  DatasetList.Free;
  blobHeaders.Free;
  blobDelParts.Free;
  blobMap.Free;
  fieldHeaderList.Free;
  indexHeaderList.Free;
  ETblDeleteCriticalSection(FLockSection);
  ETblFreeCriticalSection(FLockSection);
 finally
  ETblLeaveCriticalSection(FDMLockSection);
 end;
end; // Destroy


//------------------------------------------------------------------------------
// returns connected datasets count
//------------------------------------------------------------------------------
function TEasyDataManager.GetDatasetCount : Integer;
begin
 Result := DatasetList.Count;
end;


//------------------------------------------------------------------------------
// locks (thread-safe)
//------------------------------------------------------------------------------
procedure TEasyDataManager.LockSection;
begin
  ETblEnterCriticalSection(FLockSection);
  Inc(FLockCount);
end;// LockSection


//------------------------------------------------------------------------------
// unlocks section (thread-safe)
//------------------------------------------------------------------------------
procedure TEasyDataManager.UnlockSection;
begin
  Dec(FLockCount);
//  if (FLockCount = 0) then
  ETblLeaveCriticalSection(FLockSection);
end;// UnlockSection


//------------------------------------------------------------------------------
// detects new file store mode
//------------------------------------------------------------------------------
function TEasyDataManager.DetectFileStoreMode : TaaFileStoreMode;
var I: Integer;
    inMemory, temp, disk : Boolean;
    ds : TEasyDataset;
begin
 inMemory := false;
 temp := false;
 disk := false;
 for I := 0 to DatasetList.Count-1 do
  begin
   //
   ds := DatasetList.Items[i];
   if (temp and (not ds.Temporary)) then
    Raise Exception.Create('TEasyDataManager.DetectFileStoreMode - more then one dataset was opened in temporary mode!');
   if (ds.Temporary) then
    temp := true
   else
    if (ds.InMemory) then
     inMemory := true
    else
     disk := true;
  end;
 if (not temp) and (not disk) and (not inMemory) then
    Raise Exception.Create('TEasyDataManager.DetectFileStoreMode - there is no datasets, datasetList.count = '+inttostr(datasetList.Count));
 if (temp) then
  Result := fsmTemporary
 else
  if (inMemory) and (disk) then
   raise Exception.Create('TEasyDataManager.DetectFileStoreMode - Cannot open table in both InMemory and not InMemory modes.')
//   Result := fsmMemDisk
  else
  if (inMemory) and (not disk) then
   Result := fsmInMemory
  else
   Result := fsmDefault;
end; //DetectFileStoreMode;


//------------------------------------------------------------------------------
// set new store mode
//------------------------------------------------------------------------------
procedure TEasyDataManager.SetFileStoreMode(newFileStoreMode: TaaFileStoreMode);
begin
 if (FFileStoreMode = newFileStoreMode) then
  Exit;
// CloseTable;
 FFileStoreMode := newFileStoreMode;
// OpenTable;
end; //SetFileStoreMode(


//------------------------------------------------------------------------------
// returns true when running in design-time
//------------------------------------------------------------------------------
function TEasyDataManager.IsDesignMode : Boolean;
begin
 Result := bDesignMode;
{
 if (DatasetList.Count <= 0) then
  Raise Exception.Create('TEasyDataManager.IsDesignMode - empty datasetList');
 if (csDesigning in TEasyDataset(DatasetList.Items[0]).ComponentState) then
}
end; // IsDesignMode


//------------------------------------------------------------------------------
// opens all files
//------------------------------------------------------------------------------
function TEasyDataManager.OpenFiles(bCreate : Boolean = false): Boolean;
var
  prevReadOnly: Boolean;
begin
 // checking file exists
 result := false;
 prevReadOnly := FReadOnly;
 if ((not bCreate) and (FFileStoreMode <> fsmInMemory) and
     (not DBMHandle.aaFileExists(FTableName+tableFileExtension,FFileStoreMode))) then
   Exit;
 // table file
 try
  tableFile := DBMHandle.OpenFile(FTableName+tableFileExtension, FFileStoreMode, bCreate,
                    false, FReadOnly);
  // when open read-only file - set to read-only
  if (not prevReadOnly) then
   if (tableFile.ReadOnly) then
    FFilesReadOnly := true;
 except
  Raise Exception.Create('TEasyDataManager.OpenFiles - can not open file "'+
    FTableName+tableFileExtension+'", bCreated = '+Inttostr(Word(bCreate))+', ReadOnly = '+
    inttostr(Word(FReadOnly)));
 end;
 result := true;
 // index file
 try
  indexFile := DBMHandle.OpenFile(FTableName+indexFileExtension, FFileStoreMode, bCreate,
                    false, FReadOnly);
  // when open read-only file - set to read-only
  if (not prevReadOnly) then
   if (indexFile.ReadOnly) then
    FFilesReadOnly := true;
 except
  if (not FReadOnly) then
   indexFile := DBMHandle.OpenFile(FTableName+indexFileExtension, FFileStoreMode, true,
                    false, FReadOnly)
  else
  Raise Exception.Create('TEasyDataManager.OpenFiles - can not open file "'+
    FTableName+indexFileExtension+'", bCreated = '+Inttostr(Word(bCreate))+', ReadOnly = '+
    inttostr(Word(FReadOnly)));
 end;

 // open table header
 if (not bCreate) then
  begin
   // read only once in design-time
   if (tableHeader.fieldCount = 0) then
    LoadTableHeaders;
  end;
 // blob index file
 if (bCreate) or (isBLOBUsed) then
  begin
   try
    blobIndexFile := DBMHandle.OpenFile(FTableName+blobIndexFileExtension, FFileStoreMode, bCreate,
                    false, FReadOnly);
    // when open read-only file - set to read-only
    if (not prevReadOnly) then
     if (blobIndexFile.ReadOnly) then
      FFilesReadOnly := true;
   except
    Raise Exception.Create('TEasyDataManager.OpenFiles - can not open file "'+
      FTableName+blobIndexFileExtension+'", bCreated = '+Inttostr(Word(bCreate))+', ReadOnly = '+
      inttostr(Word(FReadOnly)));
   end;
  end;
 if (bCreate) or (isBLOBUsed) then
  begin
   // blob data file
   try
    blobDataFile := DBMHandle.OpenFile(FTableName+blobDataFileExtension, FFileStoreMode, bCreate,
                      false, FReadOnly);
    // when open read-only file - set to read-only
    if (not prevReadOnly) then
     if (blobDataFile.ReadOnly) then
      FFilesReadOnly := true;
   except
    Raise Exception.Create('TEasyDataManager.OpenFiles - can not open file "'+
      FTableName+blobDataFileExtension+'", bCreated = '+Inttostr(Word(bCreate))+', ReadOnly = '+
      inttostr(Word(FReadOnly)));
   end;
  end;

  // update
  if (bufferLog <> nil) then
   begin
    bufferLog.dataFile := tableFile;
    bufferLog.blobFile := blobDataFile;
   end;
end; //OpenFiles


//------------------------------------------------------------------------------
// closes all files
//------------------------------------------------------------------------------
procedure TEasyDataManager.CloseFiles;
begin
 // table file
 if (tableFile <> nil) then
  begin
   DBMHandle.CloseFile(tableFile);
   tableFile := nil;
  end;
 // index file
 if (indexFile <> nil) then
  begin
   DBMHandle.CloseFile(indexFile);
   indexFile := nil;
  end;
 // blob index file
 if (blobIndexFile <> nil) then
  begin
   DBMHandle.CloseFile(blobIndexFile);
   blobIndexFile := nil;
  end;
 // blob data file
 if (blobDataFile <> nil) then
  begin
   DBMHandle.CloseFile(blobDataFile);
   blobDataFile := nil;
  end;
end; //CloseFiles


//------------------------------------------------------------------------------
// opens files for working at design-time
//------------------------------------------------------------------------------
procedure TEasyDataManager.OpenFilesForDesigning;
begin
  if (IsDesignMode) then
   begin
     DBMHandle.OpenESFSFile;
     OpenFiles;
   end;
end; //OpenFilesForDesigning


//------------------------------------------------------------------------------
// closes files for working at design-time
//------------------------------------------------------------------------------
procedure TEasyDataManager.CloseFilesForDesigning;
begin
   if (IsDesignMode) then
    begin
     CloseFiles;
     DBMHandle.CloseESFSFile;
    end;
end; //CloseFilesForDesigning


//------------------------------------------------------------------------------
// intialize table
//------------------------------------------------------------------------------
procedure TEasyDataManager.InitTable;
begin
  // creating neccessary containers
// allRecBuffer.SetSize(0);
// FTemporaryIndexCount := 0;
 blobMap.SetSize(0);
 blobHeaders.SetSize(0);
 blobDelParts.SetSize(0);
 SetLength(indexes, 0);
 SetLength(indexUpdated,0);
 fieldHeaderList.Clear;
 indexHeaderList.Clear;
 // init table header
 tableHeader.fieldCount := 0;
 tableHeader.recordCount := 0;
 tableHeader.version := lastFormatVersion;
 tableHeader.ShowAutoInc := AutoIncOff;
 tableHeader.state := 0;
 tableHeader.sequenceValue := 0;
 tableHeader.cipherUsed := FEncrypted;
 tableHeader.blobCompressed := FBlobCompression;
 // init index header
 indexFileHeader.state := 0;
 indexFileHeader.indexCount := 0;
 indexFileHeader.version := lastFormatVersion;
 // init blob header
 if (FBLOBBlockSize <= 0) then
  FBLOBBlockSize := DEFAULT_BLOB_BLOCK_SIZE;
 blobFileHeader.blockSize := FBLOBBlockSize;
 blobFileHeader.numDeletedParts := 0;
 blobFileHeader.fieldCount := 0;
 blobFileHeader.recordCount := 0;
 blobFileHeader.version := lastFormatVersion;
end; //TEasyDataManager.InitTable;


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
function TEasyDataManager.OpenTable(bNotDesignMode : Boolean = false): Integer;
var
  bOk: Boolean;

procedure UpdateBIF;
var
i: integer;
begin
  for i := tableHeader.recordCount to blobFileHeader.recordCount-1 do
    aaDeleteBLOBRecord(i);
  for i := blobFileHeader.recordCount to tableHeader.recordCount-1 do
    aaAddBLOBRecord;
  Inc(tableHeader.state);
  FlushBuffers;
end;

procedure FixBlobHeaders;
var i,n: Integer;
begin
 n := 0;
 for i := 0 to tableHeader.fieldCount-1 do
  if (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType in [ftBlob,ftMemo,ftFmtMemo,ftGraphic]) then
    Inc(n);
 blobFileHeader.recordCount := 0;
 blobFileHeader.numDeletedParts := 0;
 blobFileHeader.fieldCount := n;
 blobFileHeader.version := tableHeader.version;
end;

begin
 LockSection;
 try
  IsBlobConvertNeeded := false;
  result := TETERR_NO_ERROR;
  if (isTableOpened) then
   Exit;
  OpenTableSucceed := false;
  InitTable;
  try
   if (not OpenFiles) then
    begin
     result := TETERR_NO_TABLE;
     CloseFiles;
     Exit;
    end;
  except
     result := TETERR_OPEN_FILES;
     CloseFiles;
     Exit;
  end;

  allRecBuffer := TaaRecordsArray.Create(Self, False);
  //blob fields support
  if (isBLOBUsed) then
   begin
     // load blob fields
     try
      LoadBLOBHeadersFromDisk;
     except
      if (not FRepairIsRunning) then
       begin
        Result := TETERR_CORRUPTED_BLOB_HEADERS;
        CloseFiles;
        allRecBuffer.Free;
        Exit;
       end
      else
       FixBlobHeaders;
     end;

     blobHeaders.LastBlockNumber := BLOBDataFile.Size div
                                    blobFileHeader.blockSize;
     FBLOBBlockSize := blobFileHeader.blockSize;
   end;

  if (tableHeader.cipherUsed) then
   if (not TryToOpenEncryptedTable) then
    begin
     if (IsDesignMode) then
      begin
       bOk := false;
       repeat
        if (PasswordDialog(Self,FTableName)) then
         begin
          bOk := TryToOpenEncryptedTable;
         end
        else
         begin
          result := TETERR_NO_PASSWORD;
          CloseFiles;
          allRecBuffer.Free;
          Exit;
         end;
       until bOk;
      end // invalid password design-time
     else
      begin
       result := TETERR_INVALID_PASSWORD;
       CloseFiles;
       allRecBuffer.Free;
       Exit;
      end; // invalid password run-time
    end; // TryToOpenEncryptedTable
  isTableOpened := true;
  // buffer log
  if (isBLOBUsed) then
    bufferLog := TaaBufferLogArray.Create(tableFile,
                 BLOBDataFile,FBLOBBlockSize,tableHeaderSize)
  else
    bufferLog := TaaBufferLogArray.Create(tableFile,
                 nil,0,tableHeaderSize);

  //load indexes
  LoadIndexesFromDisk;

  // if fast open value is True - recreate records array
  if (FastOpen <> allRecBuffer.FastOpen) then
   begin
    allRecBuffer.Free;
    allRecBuffer := TaaRecordsArray.Create(Self, FastOpen);
   end;

  if (tableHeader.ShowAutoInc <> AutoIncOn) and
    (tableHeader.ShowAutoInc <> AutoIncOff) then
      tableHeader.ShowAutoInc := AutoIncOn;
  // converter for < 2.20
  if (tableHeader.version < 2.20 - 0.001) then
   begin
    if (tableHeader.version < 2.2 - 0.001) and
   		(tableHeader.blobCompressed = clFastest) then
     IsBlobConvertNeeded := true;
    ConvertToCurrentFormat;
   end;
  IsBlobConvertNeeded := false;
  if (bDesignMode) then
   begin
    // store initial table state (to determine whether save changes on table close)
    DesignOpenTableState := tableHeader.state;
    // close table files
    CloseFilesForDesigning;
   end;
  if (isBLOBUsed) then
    if (tableHeader.RecordCount <> blobFileHeader.RecordCount) then
//     raise Exception.Create('TEasyDataManager.OpenTable - tableHeader.RecordCount <> blobFileHeader.RecordCount');
     UpdateBIF;
  OpenTableSucceed := true;
  result := TETERR_NO_ERROR;
 finally
  UnlockSection;
 end;
end; // OpenTable


//------------------------------------------------------------------------------
// if indexes are updated - save them
//------------------------------------------------------------------------------
procedure TEasyDataManager.FlushIndexesToDisk;
var
  ih:  IndexFileHeaderType;
begin
 LockSection;
 try
       ih.State := -1;
       indexFile.Position := 0;
       if (IndexFile.Size >= sizeof(ih)) then
         indexFile.ReadBuffer(ih,sizeof(ih));
       if (ih.State <> tableHeader.state) then
       SaveIndexesToDisk;
 finally
  UnlockSection;
 end;
end; // FlushIndexesToDisk


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TEasyDataManager.CloseTable(bNotDesignMode : Boolean = false);
var
  size,i : integer;
  bProceedFlushes: Boolean;
begin
 LockSection;
 try
  // flush changes to disk?
  bProceedFlushes := False;
  if ((not FReadOnly) and (OpenTableSucceed)) then
   begin
    // design-time?
    if (bDesignMode) then
     begin
      // table was updated by other components at design-time?
      if (tableHeader.state <> DesignOpenTableState) then
       bProceedFlushes := True;
     end
    else
      bProceedFlushes := True;
   end;
  try
   // save changes to disk?
   if (bProceedFlushes) then
    begin
     if (bDesignMode) then
      OpenFilesForDesigning;
     if (isBLOBUsed) then
      if (tableHeader.RecordCount <> blobFileHeader.RecordCount) then
       if (not FRepairIsRunning) then
       raise Exception.Create('TEasyDataManager.CloseTable - tableHeader.RecordCount <> blobFileHeader.RecordCount');
     try
      FlushBuffers;
      FlushIndexesToDisk;
      size := tableHeaderSize + tableHeader.recordCount * recInfoBufferSize;
      if ((tableFile <> nil) and (tableFile.Size <> size)) then
        tableFile.Size := size;
     except
      on E: Exception do
       begin
        MessageDlg('TEasyDataManager.CloseTable - Cannot flush changes. Probably the table is opened by other application.',mtError,[mbOK],0);
       end;
     end;
     if (bDesignMode) then
      CloseFilesForDesigning;
   end;
  finally
   bufferLog.Free;
   bufferLog := nil;
   for i := 0 to indexHeaderList.Count-1 do
    begin
     FreeMem(pIndexHeaderType(indexHeaderList.Items[i])^.indexOrders);
     FreeMem(pIndexHeaderType(indexHeaderList.Items[i])^.indexCaseIns);
     SetLength(pIndexHeaderType(indexHeaderList.Items[i])^.indexFields,0);
     indexes[i].Free;
     dispose(indexHeaderList.Items[i]);
    end;
   while indexHeaderList.Count > 0 do
    indexHeaderList.Remove(indexHeaderList.Items[0]);
   indexFileHeader.indexCount := 0;
   SetLength(indexes,0);
   indexes := nil;
   indexUpdated := nil;
   allRecBuffer.Free;
   blobMap.SetSize(0);
   blobHeaders.SetSize(0);
   blobDelParts.SetSize(0);
   fieldHeaderList.Clear;
   indexHeaderList.Clear;
   CloseFiles;
   isTableOpened := false;
  end;
 finally
  UnlockSection;
 end;
end; // CloseTable


//------------------------------------------------------------------------------
// connects dataset
//------------------------------------------------------------------------------
function TEasyDataManager.ConnectDataset(DSHandle: TEasyDataset): Integer;
begin
 LockSection;
 try
  result := TETERR_NO_ERROR;
  if (DatasetList.Count > 1) and (DSHandle.InMemory) and (FFileStoreMode <> fsmInMemory) then
    raise Exception.Create('TEasyDataManager.ConnectDataset - Cannot open dataset in both InMemory and other modes.');
  if (DatasetList.Count > 1) and (not DSHandle.InMemory) and (FFileStoreMode = fsmInMemory) then
    raise Exception.Create('TEasyDataManager.ConnectDataset - Cannot open dataset in both InMemory and other modes.');
  if (DatasetList.Count > 1) and (DSHandle.Temporary) and (FFileStoreMode <> fsmTemporary) then
    raise Exception.Create('TEasyDataManager.ConnectDataset - Cannot open dataset in both Temporary and other modes.');
  DatasetList.Add(DSHandle);
  // if first connected dataset
  if (DatasetList.Count <= 1) then
   begin
    PageRecordCount := DSHandle.PageRecordCount;
    FPassword := DSHandle.Password;
    FastOpen := DSHandle.FastOpen;
//    if (not IsDesignMode) then
     FFileStoreMode := DetectFileStoreMode;
//    else
//     FFileStoreMode := fsmDefault;

    FReadOnly := DSHandle.ReadOnly;
    // Open table files
    result := OpenTable(not IsDesignMode);
    if (result <> TETERR_NO_ERROR) then
       begin
        DatasetList.Remove(DSHandle);
//       DisconnectDataset(DSHandle);
       end;
//     if (result = TETERR_INVALID_PASSWORD) then
//       raise Exception.Create('TEasyDataManager.ConnectDataset - invalid password.');
     // if open read-only file - set readonly
    if (FFilesReadOnly) then
      begin
       DSHandle.ReadOnly := true;
       FReadOnly := true;
      end;
   end
  else
   begin
    if ((FPassword <> DSHandle.Password) and DSHandle.Encrypted) then
     Raise Exception.Create('TEasyDataManager.ConnectDataset - Inavlid password for table "'+FTableName+'"');
     if (FReadOnly and (not DSHandle.ReadOnly) and (not FFilesReadOnly)) then
      FReadOnly := false;
    // if open read-only file - set readonly
    if (FFilesReadOnly) then
     DSHandle.ReadOnly := true;
   end;
 finally
  UnlockSection;
 end;
end;// ConnectDataset


//------------------------------------------------------------------------------
// disconnects dataset
//------------------------------------------------------------------------------
procedure TEasyDataManager.DisconnectDataset(DSHandle: TEasyDataset);
var newFileStoreMode: TaaFileStoreMode;
begin
  // if last disconnected dataset
  if (DatasetList.Count = 1) then
   begin
 //   CloseTable;
    Destroy;
   end
  else
   begin
    LockSection;
    try
     DatasetList.Remove(DSHandle);
     newFileStoreMode := DetectFileStoreMode;
     SetFileStoreMode(newFileStoreMode);
    finally
     UnlockSection;
    end;
   end;
end;// DisconnectDataset


//------------------------------------------------------------------------------
// close all datasets
//------------------------------------------------------------------------------
procedure TEasyDataManager.CloseAllDatasets;
var I: Integer;
begin
 LockSection;
 try
  for I := 0 to DatasetList.Count-1 do
   TEasyDataset(DatasetList.Items[I]).Active := false;
 finally
  UnlockSection;
 end;
end; //CloseAllDatasets;


//------------------------------------------------------------------------------
// debug function
//------------------------------------------------------------------------------
function TEasyDataManager.GetDatasetsInfo: AnsiString;
var i:  Integer;
    ds: TEasyDataset;
begin
 Result := 'Count = '+IntToStr(DatasetList.Count)+#13#10;
 for i := 0 to DatasetList.Count - 1 do
  begin
   ds := DatasetList.Items[i];
   Result := Result + #13#10+'ds = '+IntToHex(Integer(Pointer(ds)),8)+#13#10;
   if (ds <> nil) then
    begin
     Result := Result + 'ds.classname = '+ds.ClassName+#13#10;
     Result := Result + 'ds.tablename = '+ds.TableName+#13#10;
     Result := Result + 'ds.databasename = '+ds.DatabaseName+#13#10;
     Result := Result + 'ds.databasefilename = '+ds.DatabaseFileName+#13#10;
     Result := Result + 'ds.sessionname = '+ds.SessionName+#13#10;
     {$IFDEF D6H}
     Result := Result + 'ds.active = '+BoolToStr(ds.Active,True)+#13#10;
     {$ELSE}
     Result := Result + 'ds.active = '+IntToStr(Integer(ds.Active))+#13#10;
     {$ENDIF}
     if (ds.FDatabase = nil) then
      Result := Result + 'ds.Fdatabase = nil'+#13#10
     else
      begin
       Result := Result + 'ds.Fdatabase.name = '+ds.FDatabase.Name+#13#10;
       Result := Result + 'ds.Fdatabase.DatabaseName = '+ds.FDatabase.DatabaseName+#13#10;
       Result := Result + 'ds.Fdatabase.SessionName = '+ds.FDatabase.SessionName+#13#10;
       if (ds.FDatabase.Owner = nil) then
        Result := Result + 'ds.FDatabase.Owner = nil'+#13#10
       else
        begin
         Result := Result + 'ds.FDatabase.Owner.Name = '+ds.FDatabase.Owner.Name+#13#10;
         Result := Result + 'ds.FDatabase.Owner.ClassName = '+ds.FDatabase.Owner.ClassName+#13#10;
        end;
      end;
    end;
  end;
end; // GetDatasetsInfo


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TEasyDataManager.CreateTable(
                        FieldDefs  : TFieldDefs;
                        IndexDefs  : TIndexDefs;
                        AutoIndexes: Boolean;
                        PageRecordCount1: Integer
                         );
var
    i,j:          Integer;
    pFieldHeader: pFieldHeaderType;
//    nameList    : TStringList;
    name    : AnsiString;
    keyNo       : Integer;
    bInvalidFieldName: Boolean;
    bInvalidIndexName: Boolean;

function IsNameValid(Name: AnsiString): Boolean;
begin
  // must not contain '.', '[', ']', leading and trialing spaces
  if (Pos('.', Name) > 0) or
     (Pos('[', Name) > 0) or
     (Pos(']', Name) > 0) or
     (Trim(Name) <> Name) then
   Result := False
  else
   Result := True;
end;


begin
 LockSection;
 try
  // check for length of fields
  for i := 0 to FieldDefs.Count-1 do
   if (Length(FieldDefs.Items[i].Name) > (MAX_NAME_LENGTH-2)) then
    raise Exception.Create('Field name must have <= '+
    IntToStr(MAX_NAME_LENGTH-2)+
    ' chars. Please shorten field name "'+FieldDefs.Items[i].Name+'"');

  // check for length of indexes
  for i := 0 to IndexDefs.Count-1 do
   begin
    if (Length(IndexDefs.Items[i].Name) > (MAX_NAME_LENGTH-2)) then
     raise Exception.Create('Index name must have <= '+
        IntToStr(MAX_NAME_LENGTH-2)+
        ' chars. Please shorten index name "'+IndexDefs.Items[i].Name+'"');
    if (Length(IndexDefs.Items[i].Name) = 0) then
     raise Exception.Create('Index name cannot be not blank. Please set non-blank index name.');
   end;

  // check for invalid characters in field name
  bInvalidFieldName := false;
  for i := 0 to FieldDefs.Count-1 do
   begin
    if (not IsNameValid(FieldDefs.Items[i].Name)) then
     begin
       bInvalidFieldName := True;
       break
     end;
   end;
  if (bInvalidFieldName) then
    raise Exception.Create('Invalid field name "'+FieldDefs.Items[i].Name+'". '+
                           'Make sure that the name doen''t contain a period (.),'+
                           'bracket ([]) leading or trailing space, or non-printable '+
                           'character such as a carriage return');

  // check for invalid characters in index
  bInvalidIndexName := false;
  for i := 0 to IndexDefs.Count-1 do
    begin
     if (not IsNameValid(IndexDefs.Items[i].Name)) then
      begin
        bInvalidIndexName := True;
        break
      end;
    end;
  if (bInvalidIndexName) then
    raise Exception.Create('Invalid index name "'+IndexDefs.Items[i].Name+'". '+
                           'Make sure that the name doen''t contain a period (.),'+
                           'bracket ([]) leading or trailing space, or non-printable '+
                           'character such as a carriage return');

  PageRecordCount := PageRecordCount1;
  isTableOpened := false;
  InitTable;
  // detect auto-inc field
  name := '';
  keyNo := -1;
 // str := '';
 // nameList  := TStringList.Create;
 // bDefaultNameExists := false;
  for i := 0 to FieldDefs.Count-1 do
   begin
 //    if (UpperCase(FieldDefs.Items[i].Name) = UpperCase(DEFAULT_PRIMARY_KEY_NAME)) then
 //     bDefaultNameExists := true;
   if (FieldDefs.Items[i].DataType = ftAutoInc) then
    begin
     keyNo := i;
     tableHeader.ShowAutoInc := AutoIncOn; // show auto-inc
     name := FieldDefs.Items[i].Name;
     break;
    end;
   end;

{
if (str = '') then
 for i := 0 to IndexDefs.Count - 1 do
  begin
   nameList.Clear;
   if (GetStringParams(IndexDefs.Items[i].Fields,nameList) <= 0) then raise Exception.Create(
     'Error in TEasyDataManager.CreateTable without params - invalid index definition, #'
        +inttostr(i)+'.');
   if (ixPrimary in IndexDefs.Items[i].Options) then
    begin
     name := IndexDefs.Items[i].Name;
     str := nameList.Strings[0];
     if (FieldDefs.Find(str) = nil) then
       raise Exception.Create('TEasyDataManager.Create - cannot find field "'+str+'" of primary index.');
     if ((nameList.Count > 1) or
         (FieldDefs.Find(str).DataType <> ftAutoInc) and
         (FieldDefs.Find(str).DataType <> ftInteger)) then
       raise Exception.Create('TEasyDataManager.Create - Primary index should contain one field of AutoInc type.');
     break;
    end;
  end;
 nameList.Free;
}
  if (name = '') then
  begin
//  if (not bDefaultNameExists) then
//   name := DEFAULT_PRIMARY_KEY_NAME
//  else
   repeat
    name := GetTemporaryName(DEFAULT_PRIMARY_KEY_NAME);
   until (FieldDefs.IndexOf(name) < 0);
  end;
{
 else
   begin
    // searching for field, specified in indexDefs as primary index
    for i := 0 to FieldDefs.Count-1 do
     if (LowerCase(FieldDefs.Items[i].Name) = LowerCase(str)) then
       break;
    name := str;
   end; // searching for field, specified in indexDefs as primary index
 // deleting auto-inc field from list
 for i := 0 to FieldDefs.Count-1 do
  if (LowerCase(FieldDefs.Items[i].Name) = LowerCase(name)) then
   begin
    keyNo := i;
    break;
   end;
}

  // write table header, other fields set by InitTable method
  tableHeader.sequenceName := StringOfChar(#0,sizeof(tableHeader.sequenceName));
  tableHeader.sequenceName := name; // unique primary key value
  if (KeyNo >= 0) then
   tableHeader.fieldCount := FieldDefs.Count-1
  else
   tableHeader.fieldCount := FieldDefs.Count;

  // making field headers list
  j := 0; // blob fields
  for i := 0 to FieldDefs.Count-1 do
   begin
    if (i = KeyNo) then
     Continue;
    new(pFieldHeader);
    if (pFieldHeader = nil) then raise Exception.Create(
     'Error in TEasyDataManager.CreateTable without params - pFieldHeader 0 pointer.');
    pFieldHeader^.fieldName := StringOfChar(#0,sizeof(pFieldHeader^.fieldName));
    pFieldHeader^.fieldName := FieldDefs.Items[i].Name;
    if ( Length(pFieldHeader^.fieldName) <= 0) then
       Raise Exception.Create('TEasyDataManager.CreateTable - field name is empty.');
    if (FieldDefs.Items[i].DataType = ftAutoInc) then
     pFieldHeader^.fieldType := ftInteger
    else
     pFieldHeader^.fieldType := FieldDefs.Items[i].DataType;
    pFieldHeader^.fieldSize := FieldDefs.Items[i].Size;
    pFieldHeader^.required := FieldDefs.Items[i].Required;
    // calculating size of the field in bytes
    case pFieldHeader^.fieldType of
       ftSmallint:
         begin
           pFieldHeader^.fieldSize := sizeOf(smallInt); // signed 16-bit
         end;
       ftBytes:
        begin
           if (pFieldHeader^.fieldSize < 1) then raise Exception.Create(
           'Error in TEasyDataManager.CreateTable - illegal ftBytes size !' );
        end;
       ftString:
         begin
           // AnsiString is null-terminated, so inc size
           Inc(pFieldHeader^.fieldSize);
           if (pFieldHeader^.fieldSize < 1) then raise Exception.Create(
           'Error in TEasyDataManager.CreateTable - illegal string size !' );
         end;
       ftWideString:
         begin
           // every WideChar is 2 bytes
 //          pFieldHeader^.fieldSize := pFieldHeader^.fieldSize*sizeof(WideChar);
           // string is null-terminated, so inc size
           Inc(pFieldHeader^.fieldSize,2);
           if (pFieldHeader^.fieldSize < 1) then raise Exception.Create(
           'Error in TEasyDataManager.CreateTable - illegal wide string size !' );
         end;
       ftDateTime, ftDate, ftTime:
         begin
           pFieldHeader^.fieldSize := sizeOf(TDateTime);
         end;
       ftInteger:
         begin
           pFieldHeader^.fieldSize := sizeOf(Integer);
         end;
       ftWord:
         begin
           pFieldHeader^.fieldSize := sizeOf(Word);
         end;
       ftLargeInt:
         begin
           pFieldHeader^.fieldSize := sizeOf(int64);
         end;
       ftBoolean:
         begin
           pFieldHeader^.fieldSize := sizeOf(WordBool);
         end;
       ftFloat:
         begin
           pFieldHeader^.fieldSize := sizeOf(Double);
         end;
       ftBCD:
         begin
           pFieldHeader^.fieldSize := sizeOf(Comp);
         end;
       ftCurrency:
         begin
           pFieldHeader^.fieldSize := sizeOf(Double);
         end;
       ftBLOB:
         begin
           pFieldHeader^.fieldSize := 0;
           inc(j);
         end;
       ftMemo:
         begin
           pFieldHeader^.fieldSize := 0;
           inc(j);
         end;
       ftFmtMemo:
         begin
           pFieldHeader^.fieldSize := 0;
           inc(j);
         end;
       ftGraphic:
         begin
           pFieldHeader^.fieldSize := 0;
           inc(j);
         end;
       else
         begin
          raise Exception.Create(
         'Error in TEasyDataManager.CreateTable - Unsupported DB type!' );
         end;
    end; //case
    fieldHeaderList.Add(pFieldHeader);
   end;

  OpenFiles(true);

  // save table anf fields headers
  SaveTableHeaders;
  // blob fields
  if (j > 0) then
   begin
    blobFileHeader.fieldCount := j;
    SaveBLOBHeadersToDisk(true);
   end
  else
   begin
    blobDataFile.Free;
    blobIndexFile.Free;
    blobDataFile := nil;
    blobIndexFile := nil;
    DBMHandle.aaDeleteFile(FTableName+blobDataFileExtension,FFileStoreMode);
    DBMHandle.aaDeleteFile(FTableName+blobIndexFileExtension,FFileStoreMode);
   end;


  // adding indexes
  CreateAutoIndexes(AutoIndexes);
  // adding user-defined indexes
  for i := 0 to IndexDefs.Count - 1 do
   if (IndexDefs.Items[i].Name[1] <> '@') then
    AddIndex(IndexDefs.Items[i].Name, IndexDefs.Items[i].Fields,
            IndexDefs.Items[i].Options, IndexDefs.Items[i].DescFields,
            IndexDefs.Items[i].CaseInsFields,true);
  SaveIndexesToDisk;
  CloseFiles;
  isTableOpened := true;
  CloseTable(true);
  isTableOpened := false;
 finally
  UnlockSection;
 end;
end; // CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TEasyDataManager.DeleteTable;
var s,s1 : AnsiString;
begin
 LockSection;
 try
  s := FTableName;
  // blob data file
  s1 := s+blobDataFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   if (not DBMHandle.aaDeleteFile(s1, FFileStoreMode)) then raise Exception.Create(
      'Error in TEasyDataManager.DeleteTable - '+s1+' file cannot be deleted.');
  // blob index file
  s1 := s+blobIndexFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   if (not DBMHandle.aaDeleteFile(s1, FFileStoreMode)) then raise Exception.Create(
      'Error in TEasyDataManager.DeleteTable - '+s1+' file cannot be deleted.');
  // index file
  s1 := s+IndexFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   if (not DBMHandle.aaDeleteFile(s1, FFileStoreMode)) then raise Exception.Create(
      'Error in TEasyDataManager.DeleteTable - '+s1+' file cannot be deleted.');
  // table file
  s1 := s+TableFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   if (not DBMHandle.aaDeleteFile(s1, FFileStoreMode)) then raise Exception.Create(
      'Error in TEasyDataManager.DeleteTable - '+s1+' file cannot be deleted.');
 finally
  UnlockSection;
 end;
end; // DeleteTable


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TEasyDataManager.EmptyTable;
var
    i : integer;
begin
 LockSection;
 try
  isTableOpened := false;
  FReadOnly := false;
  OpenTable(true);

  tableHeader.recordCount := 0;
  tableHeader.sequenceValue := 0;
  tableHeader.state := 0;

  SaveTableHeaders;
  tableFile.Size := tableFile.Position;
  if (isBLOBUsed) then
   begin
    BLOBFileHeader.recordCount := 0;
    BLOBFileHeader.numDeletedParts := 0;
    SaveBLOBHeadersToDisk(true);
   end;

  indexFileHeader.state := 0;
  for i := 0 to indexFileHeader.indexCount-1 do
   begin
    indexUpdated[i] := true;
   end;
  SaveIndexesToDisk;
  FReadOnly := true;
  CloseTable(true);
 finally
  UnlockSection;
 end;
end; // EmptyTable


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TEasyDataManager.RenameTable(const NewTableName : AnsiString);
var
  s,s1,s2,s3 : AnsiString;
  i: integer;
begin
 LockSection;
 try
  s := FTableName;
  s2 := NewTableName;

  for i:=1 to 4 do
   begin
    case i of
     1: begin
         // blob data file
         s1 := s+blobDataFileExtension;
         s3 := s2+blobDataFileExtension;
        end;
     2: begin
         // blob index file
         s1 := s+blobIndexFileExtension;
         s3 := s2+blobIndexFileExtension;
        end;
     3: begin
         // index file
         s1 := s+IndexFileExtension;
         s3 := s2+IndexFileExtension;
        end;
     4: begin
         // table file
         s1 := s+TableFileExtension;
         s3 := s2+TableFileExtension;
        end;
    end; // case

   if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   begin
    if (AnsiLowerCase(s1) <> AnsiLowerCase(s3)) then
     if (DBMHandle.aaFileExists(s3, FFileStoreMode)) then
      if (not DBMHandle.aaDeleteFile(s3, FFileStoreMode)) then raise Exception.Create(
       'Error in TEasyDataManager.RenameTable - '+s1+' file cannot be overwritten');
    if (not DBMHandle.aaRenameFile(s1,s3, FFileStoreMode)) then raise Exception.Create(
      'Error in TEasyDataManager.RenameTable - '+s1+' file cannot be renamed.');
   end;
  end; // for

  FTableName := NewTableName;
 finally
  UnlockSection;
 end;
end; // RenameTable


//------------------------------------------------------------------------------
//save table
//------------------------------------------------------------------------------
procedure TEasyDataManager.SaveTable;
var s,s1: AnsiString;
begin
 LockSection;
 try
  FlushBuffers;
  FlushIndexesToDisk;
  s := FTableName;
  if (IsBlobUsed) then
   begin
    // blob data file
    s1 := s+blobDataFileExtension;
    DBMHandle.SaveFile(s1);
    // blob index file
    s1 := s+blobIndexFileExtension;
    DBMHandle.SaveFile(s1);
   end;
  // index file
  s1 := s+IndexFileExtension;
  DBMHandle.SaveFile(s1);
  // table file
  s1 := s+TableFileExtension;
  DBMHandle.SaveFile(s1);
 finally
  UnlockSection;
 end;
end;// TEasyDataManager.SaveTable;


//------------------------------------------------------------------------------
// copy table
//------------------------------------------------------------------------------
procedure TEasyDataManager.CopyTable(const NewTableName: AnsiString; const NewDatabaseName: AnsiString = '');
var s,s1,s2,s3 : AnsiString;
begin
 LockSection;
 try
  s := FTableName;
  s2 := NewTableName;
  // blob data file
  s1 := s+blobDataFileExtension;
  s3 := s2+blobDataFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   begin
    if (not DBMHandle.aaCopyFile(s1,s3, FFileStoreMode, NewDatabaseName)) then raise Exception.Create(
      'Error in TEasyDataset.CopyTable - '+s1+' file cannot be copied.');
   end;
  // blob index file
  s1 := s+blobIndexFileExtension;
  s3 := s2+blobIndexFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   begin
    if (not DBMHandle.aaCopyFile(s1,s3, FFileStoreMode, NewDatabaseName)) then raise Exception.Create(
      'Error in TEasyDataset.CopyTable - '+s1+' file cannot be copied.');
   end;
  // index file
  s1 := s+IndexFileExtension;
  s3 := s2+IndexFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   begin
    if (not DBMHandle.aaCopyFile(s1,s3, FFileStoreMode, NewDatabaseName)) then raise Exception.Create(
      'Error in TEasyDataset.CopyTable - '+s1+' file cannot be copied.');
   end;
  // table file
  s1 := s+TableFileExtension;
  s3 := s2+TableFileExtension;
  if (DBMHandle.aaFileExists(s1, FFileStoreMode)) then
   begin
    if (not DBMHandle.aaCopyFile(s1,s3, FFileStoreMode, NewDatabaseName)) then raise Exception.Create(
      'Error in TEasyDataset.CopyTable - '+s1+' file cannot be copied.');
   end;
 finally
  UnlockSection;
 end;
end; //CopyTable


//------------------------------------------------------------------------------
// creates new index in table
//------------------------------------------------------------------------------
procedure TEasyDataManager.AddIndex(
              const Name, // index name
              Fields: AnsiString; // fields list (separated by ';', ',',' ' or any combination)
              Options: TIndexOptions; // ixDescending, ixCaseInsensetive are available options
              const DescFields: AnsiString =''; // desc fields list (separated by ';', ',',' ' or any combination)
              const CaseInsFields: AnsiString =''; // case insensitive fields list (separated by ';', ',',' ' or any combination)
              inMemory   : Boolean = false
              );
var j,n,k,m    : integer;
    nameList     : TStringList;
    orderList    : TStringList;
    caseList     : TStringList;
    tempList     : TStringList;
    ignoreCase,descending,f : Boolean;
begin
 LockSection;
 try
  nameList  := TStringList.Create;
  orderList := TStringList.Create;
  caseList := TStringList.Create;
  tempList := TStringList.Create;
  // analyse index fields
  nameList.Clear;
  orderList.Clear;
  caseList.Clear;
  // prepare params for CreateIndex()
  // descending fields
  n := GetStringParams(Fields,nameList);
  tempList.Clear;
  m := GetStringParams(DescFields,tempList);
  if (ixDescending in Options) then
   descending := true // descending index
  else
   descending := false; // ascending index
  for j := 0 to n-1 do
   begin
    if (descending) then
     // ixDescending option selected - for all fields
     orderList.Add('down')
    else
    if (m <= 0) then
     orderList.Add('up')
    else
     begin
      // desc fields check
      f := false;
      for k := 0 to m-1 do
       if (LowerCase(tempList.Strings[k]) = LowerCase(nameList.Strings[j])) then
        begin
         f := true;
         break;
        end;
      if (f) then
        orderList.Add('down')
      else
       orderList.Add('up');
     end; // case ins fields check
   end; //for j
  // case sensitivity
  tempList.Clear;
  m := GetStringParams(CaseInsFields,tempList);
  if (ixCaseInsensitive in Options) then
   ignoreCase := true // case insensitive index
  else
   ignoreCase := false; // case sensitive index
  for j := 0 to n-1 do
   begin
    if (ignoreCase) then
     // ixCaseInsensitive option selected - for all string fields
     caseList.Add('yes')
    else
     if (m<=0) then
      caseList.Add('no')
    else
      begin
       // case ins fields check
       f := false;
       for k := 0 to m-1 do
        if (LowerCase(tempList.Strings[k]) = LowerCase(nameList.Strings[j])) then
          begin
          f := true;
          break;
         end;
       if (f) then
        caseList.Add('yes')
       else
        caseList.Add('no');
      end; // case ins fields check
   end; //for j
  try
   // check fields existence
   for j := 0 to nameList.Count-1 do
     if (InternalGetFieldNo(nameList.Strings[j], False) = -2) then
      raise ETblException.Create(01067, [nameList.Strings[j]], nil);

   InternalAddIndex(Name,nameList,orderList,caseList,Options,ignoreCase,descending);
   if (not inMemory) then
    SaveIndexesToDisk;
  finally
   nameList.Free;
   orderList.Free;
   caseList.Free;
   tempList.Free;
  end;
 finally
  UnlockSection;
 end;
end; //AddIndex


//------------------------------------------------------------------------------
// return true if index is exists
//------------------------------------------------------------------------------
function TEasyDataManager.IsIndexExists(IndexName: AnsiString): Boolean;
var i:    Integer;
    name: AnsiString;
begin
 Result := False;
 name := UpperCase(IndexName);
 for i := 0 to indexHeaderList.Count - 1 do
  if (UpperCase(PIndexHeaderType(indexHeaderList.Items[i])^.indexName) =
      name) then
   begin
    Result := True;
    break;
   end;
end; // IsIndexExists


//------------------------------------------------------------------------------
// creates temporary index
//------------------------------------------------------------------------------
function TEasyDataManager.CreateTemporaryIndex(Fields, DescFields, CaseInsFields: AnsiString): AnsiString;
begin
 LockSection;
 try
  repeat
    result := GetTemporaryName('$_IDX_');
  until (not IsIndexExists(result));
  AddIndex(result,Fields,[],DescFields,CaseInsFields,true);
 finally
  UnlockSection;
 end;
end; // CreateTemporaryIndex


//------------------------------------------------------------------------------
// internal create index
//------------------------------------------------------------------------------
procedure TEasyDataManager.InternalAddIndex(
                          name : ShortString; // name
                          fieldNames : TStringList; // field names list
                          sortOrders : TStringList; // sort orders list {'up','down'}
                          caseIns : TStringList; // case insensetive fields {'yes','no'}
                          indexOptions:  TIndexOptions; // index options
                          ignoreCase : Boolean; // ixCaseInsensitive
                          descending :   Boolean);  // ixDescending
var
    indexCount 	 : Integer;
    MAX_LENGTH:   Integer;
    i,j,f,n,k     : Integer;
    pIndexHeader : pIndexHeaderType;
    ftype				 : TFieldType;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
begin
 LockSection;
 try
  if (Length(name) = 0) then raise Exception.Create(
      'Error in TEasyDataManager.InternalAddIndex - name is empty.');
   i := fieldNames.Count;
   j := sortOrders.Count;
   if (tableHeader.version > (4.50-0.01)) then
    MAX_LENGTH := MAX_NAME_LENGTH
   else
    MAX_LENGTH := OLD_MAX_NAME_LENGTH;

   if (Length (name) > MAX_LENGTH) then
     raise Exception.Create(
      'Error in TEasyDataManager.InternalAddIndex - name length > .' + IntToStr(MAX_NAME_LENGTH-2));
   if  (i <= 0) then raise Exception.Create(
           'Error in TEasyDataManager.InternalAddIndex - empty field name list' );
   if  (j <= 0) then raise Exception.Create(
           'Error in TEasyDataManager.InternalAddIndex - empty sort orders list' );
   indexCount := i;
    i := 0;
     f := 0;
 	  while i < indexHeaderList.Count do
  	   begin
  			if (pIndexHeaderType(indexHeaderList.Items[i]) = nil) then raise Exception.Create(
  	    	'Error in TEasyDataManager.InternalAddIndex - index header 0 pointer!');
  	// ShowMessage(pIndexHeaderType(indexHeaderList.Items[i])^.indexName);
  	    if (LowerCase(name) =
  	    		LowerCase(pIndexHeaderType(indexHeaderList.Items[i])^.indexName)) then
  	     begin
   	       f := 1;
 	       break;
	     end;//found
 	    inc(i);
  	   end;// while
  	  if (f = 1) then raise Exception.Create(
 	    	'Error in TEasyDataManager.InternalAddIndex - index "'+name+'" already exists!');
   // allocate memory for indexHeader
   new(pIndexHeader);
    if  (pIndexHeader = nil) then raise Exception.Create(
           'Error in TEasyDataManager.InternalAddIndex - new(pIndexHeader) returns 0 pointer!' );
   // prepare new index header
   pIndexHeader^.indexOptions := indexOptions;
   pIndexHeader^.indexName := StringOfChar(#0,sizeof(pIndexHeader^.indexName));
   pIndexHeader^.indexName := name;
   pIndexHeader^.indexCount := indexCount;
   k := (indexCount + 7) div 8;
   pIndexHeader^.indexOrders := AllocMem(k);
   FillChar(pIndexHeader^.indexOrders^,k,$FF);
   pIndexHeader^.indexCaseIns := AllocMem(k);
   FillChar(pIndexHeader^.indexCaseIns^,k,$00);
   SetLength(pIndexHeader^.indexFields,indexCount);
   pIndexHeader^.ignoreCase := ignoreCase;
   pIndexHeader^.descending := descending;
   for i := 0 to indexCount-1 do
    begin
//   fieldNames.Strings[i] := LowerCase (fieldNames.Strings[i]);
   // searching field
//   if (name[1] <> '$') and (LowerCase(tableHeader.sequenceName) = LowerCase(fieldNames.Strings[i])) then
   // detect autoinc for temporary indexes too
    if (LowerCase(tableHeader.sequenceName) = LowerCase(fieldNames.Strings[i])) then
     begin
      // primary key
      pIndexHeader^.indexFields[i] := -1; // primary key
     end
    else
    // not primary key
     for j := 0 to fieldHeaderList.Count-1 do
     if (LowerCase(pFieldHeaderType(fieldHeaderList.Items[j])^.fieldName) =
          LowerCase(fieldNames.Strings[i])) then
       begin
        // check type of the field - not all types are supported
        ftype := pFieldHeaderType(fieldHeaderList.Items[j])^.fieldType;
         if (not IsFieldTypeCanCompriseIndex(ftype)) then
          raise Exception.Create(
           'Error in TEasyDataManager.InternalAddIndex - unsupported field type!' );
        pIndexHeader^.indexFields[i] := j;

        // index field order
        chkfld_buffer := pIndexHeader^.indexOrders;
        chkfld_fieldNum := i;
        if LowerCase(sortOrders.Strings[i]) = 'down' then
         chkfld_set := false  // down (descending)
        else
         chkfld_set := true; // up (ascending)
        {$include set_fields.inc}

        // index field case sensitivity
        chkfld_buffer := pIndexHeader^.indexCaseIns;
        if ((LowerCase(caseIns.Strings[i]) = 'yes') and
           ((ftype = ftString) or (ftype = ftWideString))) then
         chkfld_set := true  // ignore case
        else
         chkfld_set := false; // case sensitive string comparison
        {$include set_fields.inc}
        break;
       end; // index field info
    end; // for fields
  	// add index to file
  inc(indexFileHeader.indexCount);
  indexHeaderList.Add(pIndexHeader);
  n := indexFileHeader.indexCount-1;
  SetLength(indexes,n+1);
  indexes[n] := TaaIntArray.Create(tableHeader.recordCount);
  SetLength(indexUpdated,n+1);
  indexUpdated[n] := false;
  // create index
  //sort records
  BuildIndex(n);
 finally
  UnlockSection;
 end;
end; // TEasyDataManager.InternalAddIndex


//------------------------------------------------------------------------------
// delete index
//------------------------------------------------------------------------------
function TEasyDataManager.DeleteIndex(
                          const Name : AnsiString;// name
                          inMemory : Boolean = false
                         ) : Integer;
var
    i,indexCount,num,f : Integer;
begin
 LockSection;
 Result := -1;
 try
  if (not isTableOpened) then raise Exception.Create(
     'Error in TEasyDataManager.DeleteIndex - table is not opened.');
  if (Length(name) = 0) then raise Exception.Create(
     'Error in TEasyDataManager.DeleteIndex - name is empty.');
//  if (name[1] = '@') then Exit; // auto indexes skipped
	//check for existing index
  num := 0;
  f := 0;
//ShowMessage('count = '+IntToStr(.indexHeaderList.Count));
	while num < indexHeaderList.Count do
	 begin
	 	if (pIndexHeaderType(indexHeaderList.Items[num]) = nil) then raise Exception.Create(
	  	'Error in TEasyDataManager.DeleteIndex - index header 0 pointer!');
		if (LowerCase(name) =
	    		LowerCase(pIndexHeaderType(indexHeaderList.Items[num])^.indexName)) then
	   begin
	    f := 1;
	    break;
	   end;//found
	  inc(num);
	 end;// while

  if (f = 0) then raise Exception.Create(
	    	'Error in TEasyDataManager.DeleteIndex - index "'+name+'" doesn''t exist!');
  Result := num;
  pIndexHeaderType(indexHeaderList.Items[num])^.indexFields := nil;
  FreeMem(pIndexHeaderType(indexHeaderList.Items[num])^.indexOrders);
  FreeMem(pIndexHeaderType(indexHeaderList.Items[num])^.indexCaseIns);
  dispose(indexHeaderList.Items[num]);
  indexHeaderList.Delete(num);
  dec(indexFileHeader.indexCount);
//ShowMessage('ok 1');
  indexCount := indexFileHeader.indexCount;
  if (indexCount <= 0) then
   begin
    // this shall never be
    raise Exception.Create('TEasyDataManager.DeleteIndex - last index deleted!');
   end;
//ShowMessage('ok 2');
  // delete index from araay
  if (num = indexCount) then
   begin
    indexes[num].Free;
   end
  else
   begin
    indexes[num].Free;
    for i := num+1 to indexCount do
     begin
      indexes[i-1] := indexes[i];
     //Copy(.indexes[i],0,.tableHeader.recordCount);
//     pos.indexes[i-1] := Copy(pos.indexes[i],0,.tableHeader.recordCount);
      indexUpdated[i-1] := indexUpdated[i];
     end;
   end;

  SetLength(indexes,indexCount);
//  SetLength(pos.indexes,indexCount);
  SetLength(indexUpdated,indexCount);
  if (not inMemory) then
    SaveIndexesToDisk;
 finally
  UnlockSection;
 end;
end; //DeleteIndex


//------------------------------------------------------------------------------
// delete all indexes
//------------------------------------------------------------------------------
procedure TEasyDataManager.DeleteAllIndexes;
var i : integer;
begin
 LockSection;
 try
  i := 1; // skip '@id' index
  while i < indexHeaderList.Count do
   begin
{    if (pIndexHeaderType(indexHeaderList.Items[i])^.indexName[1] = '@') then
     begin
      inc(i);
      continue;
     end;}
    DeleteIndex(pIndexHeaderType(indexHeaderList.Items[i])^.indexName,true);
   end;
  SaveIndexesToDisk;
 finally
  UnlockSection;
 end;
end; //DeleteAllIndexes


//------------------------------------------------------------------------------
// builds selected index
//------------------------------------------------------------------------------
procedure TEasyDataManager.BuildIndex (n : integer; IndexesToBuild: Integer=1);
var
  DMHandle : TEasyDataManager;
  j: integer;
//---------------- variables for optimization -----------------------------
{$include compare_var.inc}

//-------------- sorting by Qsort from Borland -----------
procedure aaSortRecords (pIndexHeader : pIndexHeaderType;
                         recCount : integer;
                         var A : array of integer
                         );
var
 aLo, aHi : Integer;
 procedure QuickSort (
                    var iLo, iHi : Integer
                    );
  var
    Lo, Hi, Mid, T, j: Integer;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := A[(Lo + Hi) shr 1];
    cmpRecBuf_buffer2 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(Mid));
    allRecBuffer.LockRecordPage(Mid);
    repeat
     cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(A[Lo]));
     {$include compare.inc}
     while (cmpRecBuf_res > 0) and (Lo < recCount) do
      begin
       inc(Lo);
       cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(A[Lo]));
       {$include compare.inc}
      end;
     cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(A[Hi]));
     {$include compare.inc}
     while (cmpRecBuf_res < 0) and (Hi > 0) do
      begin
       Dec(Hi);
       cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(A[Hi]));
       {$include compare.inc}
      end;
      if Lo <= Hi then
      begin
        T := A[Lo];
        A[Lo] := A[Hi];
        A[Hi] := T;
        Inc(Lo);
        Dec(Hi);
      end;
    until Lo > Hi;
    allRecBuffer.UnlockRecordPage(Mid);
    if Hi > iLo then
     begin
      // check infinite recurse
      if (iHi = Hi) then
       raise Exception.Create('TEasyDataManager.BuildIndex - Sorting error');
      QuickSort(iLo, Hi);
     end;
    if Lo < iHi then QuickSort(Lo, iHi);

    if (not SilentMode) then
      if (recCount > 0) then
      if (IndexesToBuild = 1) then
       for j := 0 to DatasetList.Count-1 do
         TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(
                    (iHi / recCount) * 100, false, false)
      else
       for j := 0 to DatasetList.Count-1 do
         TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(
                    (n/(IndexesToBuild-1)+(1/(IndexesToBuild-1))*(iHi / recCount)) * 100, false, false)
  end; //QuickSort
//------------------------- sort end ----------------------------------------
  begin
   cmpRecBuf_pIndexHeader := pIndexHeader;
   cmpRecBuf_ignoreCase := false;
   cmpRecBuf_bPartialCompare := false;
   cmpRecBuf_find := false;
   aLo := 0;
   aHi := recCount;
   QuickSort (aLo, aHi);
  end;// aaSortRecords
// build index
var
   i,recCount   : integer;
   pIndexHeader          : pIndexHeaderType;
begin
 LockSection;
 try
  DMHandle := self;
  if (indexUpdated[n]) then
   Exit;
  indexUpdated[n] := true;
  recCount := DMHandle.tableHeader.recordCount-1;
  if (recCount < 0) then
   begin
    DMHandle.indexes[n].SetSize(0);
    Exit;
   end;

  indexes[n].SetSize(recCount+1);
  pIndexHeader := pIndexHeaderType(DMHandle.indexHeaderList.Items[n]);
  for i := 0 to recCount do
  	indexes[n].Items[i] := i; // default order : 0,1,...,n-1
 //if (n = 0) then
 // begin
 //aaStartTime;
  if (not SilentMode) then
    if (IndexesToBuild = 1) then
     for j := 0 to DatasetList.Count-1 do
      TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(0,true,false);

   aaSortRecords(pIndexHeader,recCount,indexes[n].items);

  if (not SilentMode) then
    if (IndexesToBuild = 1) then
     for j := 0 to DatasetList.Count-1 do
      TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(100,false,true);
 //aaStopTime;
 // end;
 finally
  UnlockSection;
 end;
end; //BuildIndex


//------------------------------------------------------------------------------
// builds all indexes
//------------------------------------------------------------------------------
procedure TEasyDataManager.BuildAllIndexes;
var i,j: Integer;
    FProgress:	Real;
    FProgress1:	Real;
    OldSilent: Boolean;
begin
 LockSection;
 OldSilent := SilentMode;
 try
  SilentMode := True;
  if (indexHeaderList.Count > 1) then
   if (not SilentMode) then
     for j := 0 to DatasetList.Count-1 do
       TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(0,true,false);
  for i := 0 to indexHeaderList.Count - 1 do
   begin
    indexUpdated[i] := false;
    BuildIndex(i, indexHeaderList.Count);
    FProgress := i+1;
    FProgress1 := indexHeaderList.Count;
    FProgress := FProgress / FProgress1 * 100.0;
    if (indexHeaderList.Count > 1) then
     if (not SilentMode) then
       for j := 0 to DatasetList.Count-1 do
        TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(FProgress,false,false);
   end;
  if (indexHeaderList.Count > 1) then
   for j := 0 to DatasetList.Count-1 do
    TEasyDataset(DatasetList.Items[j]).DoOnBuildIndexesProgress(100,false,true);
 finally
  UnlockSection;
  SilentMode :=  OldSilent;
 end;
end; //BuildAllIndexes


//------------------------------------------------------------------------------
// updates all indexes
//------------------------------------------------------------------------------
procedure TEasyDataManager.UpdateAllIndexes;
var I : integer;
begin
 LockSection;
 try
  for I := 0 to indexHeaderList.Count - 1 do
   BuildIndex(I);
 finally
  UnlockSection;
 end;
end; //UpdateAllIndexes


//------------------------------------------------------------------------------
// check index; returns -1 if index ok;
// if index is invalid returns number of first invalid element
//------------------------------------------------------------------------------
function TEasyDataManager.CheckIndex(n : integer) : integer;
var i : integer;
    DMHandle : TEasyDataManager;
//---------------- variables for optimization -----------------------------
{$include compare_var.inc}
begin
 DMHandle := self;
 result := -1;
 BuildIndex(n);
 if (n >= indexFileHeader.indexCount) then raise
  Exception.Create('Error in TEasyDataManager.CheckIndex - index doesn''t exist, n = '+inttostr(n));
 cmpRecBuf_pIndexHeader := pIndexHeaderType(indexHeaderList.Items[n]);
 cmpRecBuf_ignoreCase := false;
 cmpRecBuf_bPartialCompare := false;
// cmpRecBuf_res := 0;
 cmpRecBuf_find := false;
 for i := 1 to tableHeader.recordCount-1 do
  begin
   cmpRecBuf_buffer1 := allRecBuffer.GetRecordDataPtr(indexes[n].items[i-1]);
   allRecBuffer.LockRecordPage(indexes[n].items[i-1]);
   cmpRecBuf_buffer2 := allRecBuffer.GetRecordDataPtr(indexes[n].items[i]);
   allRecBuffer.UnlockRecordPage(indexes[n].items[i-1]);
   {$include compare.inc}
   if (cmpRecBuf_res < 0) then
    begin
     result := i;
// for debug 
//     {$include compare.inc}
     Exit;
    end;
  end;
end; //CheckIndex


//------------------------------------------------------------------------------
// check all indexes
//------------------------------------------------------------------------------
procedure TEasyDataManager.CheckAllIndexes;
var I : integer;
begin
 for I := 0 to indexHeaderList.Count - 1 do
  begin
   if (CheckIndex(i) > 0) then
    raise Exception.Create('Invalid index, i = '+IntToStr(i)+
    			', name = "'+pIndexHeaderType(IndexHeaderList.Items[i])^.IndexName+'"');
  end;
end; //CheckAllIndexes


//------------------------------------------------------------------------------
// creates auto indexes
//------------------------------------------------------------------------------
procedure TEasyDataManager.CreateAutoIndexes(AutoIndexes: Boolean);
var i: 	integer;
    s:  AnsiString;
    opt:TIndexOptions;
begin
 LockSection;
 try
  // create @ID for autoinc field
  AddIndex('@'+tableHeader.sequenceName,tableHeader.sequenceName,[ixUnique],'','',true);
  // creating auto-indexes
  if (AutoIndexes) then
   for i := 0 to fieldHeaderList.Count - 1 do
    begin
     if ((pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftBLOB) or
        (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftMemo) or
        (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftFmtMemo) or
        (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftBytes) or
        (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftGraphic)) then
        continue;
     s := pFieldHeaderType(fieldHeaderList.Items[i])^.fieldName;
     if (
        (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftString) or
        (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftWideString)) then
      begin
       opt := [ixCaseInsensitive];
       AddIndex('@@'+s,s,opt,'','',true);
      end;
     opt := [];
     AddIndex('@'+s,s,opt,'','',true);
    end;
 finally
  UnlockSection;
 end;
end;


//------------------------------------------------------------------------------
// returns true if need update indexes now, false - if update is delayed
//------------------------------------------------------------------------------
function TEasyDataManager.IsUpdateIndexesNowRecommended: boolean;
var curTime: integer;
begin
 LockSection;
 try
  if (tableHeader.recordCount > ThresholdRecordCount) then
   result := true
  else
   begin
    curTime := GetTickCount;
    if (curTime - LastIOOpTime < ThresholdDelay) then
     begin
      inc(ThresholdDelayNo);
      if (ThresholdDelayNo > ThresholdDelayMaxCount) then
       result := false
      else
       result := true;
     end
    else
     begin
      ThresholdDelayNo := 0;
      result := true;
     end;
      LastIOOpTime := curTime;
   end;
 finally
  UnlockSection;
 end;
end; // IsUpdateIndexesNowRecommended


//------------------------------------------------------------------------------
// checks disk I/O buffers for overflow
//------------------------------------------------------------------------------
procedure TEasyDataManager.CheckBuffersOverflow;
var size : integer;
begin
 LockSection;
 try
  if (not FFlushesEnabled) then
   Exit;
  if (FReadOnly)or bDesignMode then
   Exit;


//aaStartTime;

  size := tableHeaderSize +
                         tableHeader.recordCount * recInfoBufferSize;
  if (bufferLog.CheckOverflow) then
   begin
{   tableFile.Seek(0,soFromBeginning);
   tableFile.WriteBuffer (tableHeader,sizeOf(tableHeaderType));}
    SaveTableHeaders;
    if (tableFile.Size <> size) then
     tableFile.Size := size;
//aaStartTime;
    if (isBLOBUsed) then
     SaveBLOBHeadersToDisk;
//aaStopTime;
//aaStopTime;
   end;
//aaStopTime;
 finally
  UnlockSection;
 end;
end;


//------------------------------------------------------------------------------
// Flushes all changes that have been written to the database table
//------------------------------------------------------------------------------
procedure TEasyDataManager.FlushBuffers;
var size : integer;
    th:   TableHeaderType;
begin
 LockSection;
 try
  if (FReadOnly) then
   Exit;
  size := tableHeaderSize +
                         tableHeader.recordCount * recInfoBufferSize;
{ tableFile.Seek(0,soFromBeginning);
 tableFile.WriteBuffer (tableHeader,sizeOf(tableHeaderType));}
  th.State := -1;
  InternalLoadTableHeader(th);
  // design-time: table was modified outside IDE?
  if (bDesignMode and (th.State <> DesignOpenTableState)) then
   raise Exception.Create('TEasyDataManager.FlushBuffers - Cannot write changes in table, as it was modified outside IDE.');

  if (th.State <> tableHeader.State) then
   begin
    SaveTableHeaders;
    if (tableFile.Size <> size) then
     tableFile.Size := size;
    // flushing all file buffers
    tableFile.FlushBuffers;

  if (bufferLog <> nil) then
     if (isBLOBUsed) then
    begin
{$IFDEF DEBUG_FLAG}
aaWriteToLog('flush started, blob rec count = '+
IntToStr(blobFileHeader.recordCount)+
', record count = '+IntToStr(tableHeader.recordCount));
{$ENDIF}
     bufferLog.FlushBuffers;
     SaveBLOBHeadersToDisk;
     BLOBDataFile.FlushBuffers;
     BLOBIndexFile.FlushBuffers;
{$IFDEF DEBUG_FLAG}
aaWriteToLog('flush finished, blob rec count = '+
IntToStr(blobFileHeader.recordCount)+
', record count = '+IntToStr(tableHeader.recordCount));
{$ENDIF}
    end
   else
     bufferLog.FlushBuffers;
   end;
 finally
  UnlockSection;
 end;
end; //FlushBuffers


//------------------------------------------------------------------------------
// disable flushes (untill all BLOB field values are saved to buffer)
//------------------------------------------------------------------------------
procedure TEasyDataManager.DisableFlushes;
begin
 FFlushesEnabled := False;
end;// DisableFlushes


//------------------------------------------------------------------------------
// enable flushes (after all BLOB field values are saved to buffer)
//------------------------------------------------------------------------------
procedure TEasyDataManager.EnableFlushes(DoCheck: Boolean=True);
begin
 FFlushesEnabled := True;
 if (DoCheck) then
  CheckBuffersOverflow;
end;// EnableFlushes


//------------------------------------------------------------------------------
// count buffer crc
//------------------------------------------------------------------------------
procedure TEasyDataManager.CountBufferCrc(inBuffer : PAnsiChar; inSize : Integer; outBuffer : PAnsiChar);
var
    check         : THash_CRC32; // for checking data
    s             : string[12];  // crc
begin
   try
    check := THash_CRC32.Create(nil);
    s := check.CalcBuffer(inBuffer^,inSize,nil);
    check.Free;
    Move(s,outBuffer^,sizeof(s));
   except
    raise Exception.Create(
     'Error in TEasyDataManager.CountBufferCrc - crc calc error, encoding');
   end;
end; //CountBufferCrc


//------------------------------------------------------------------------------
// check buffer crc
//------------------------------------------------------------------------------
function TEasyDataManager.CheckBufferCrc(inBuffer : PAnsiChar; inSize : Integer;
                            crcBuffer : PAnsiChar) : Boolean;
var s,s1 : PAnsiChar;
    i : integer;
    x : byte;
begin
 result := true;
 s1 := AllocMem(13);
 CountBufferCrc(inBuffer, inSize, s1);
 s := crcBuffer;
 i := 1;
 x := Byte(s[0]);
 if (x = 0) then
  begin
   result := false;
   Exit;
  end;
// while (s[i] <> #0) and (s1[i] <> #0) do
 while i <= x do
  begin
   if ((ord(s1[i]) xor ord(s[i])) <> 0) then
    begin
     result := false;
     Exit;
    end;
   inc(i);
  end;
 FreeMem(s1); 
end; //CheckBufferCrc


//------------------------------------------------------------------------------
//change record buffer encryption
//------------------------------------------------------------------------------
procedure TEasyDataManager.ChangeBufferEncryption(
              buffer : PAnsiChar;  // pointer to record buffer
              mode : Byte      // 1 - enable encryption, 0 - disable encryption
    				     );
var
    crypto        : TCipher_Rijndael; // for decoding
begin
 if (buffer = nil) then raise Exception.Create(
    'Error in TEasyDataManager.ChangeBufferEncryption - buffer 0 pointer.');
 if (mode = 1) then
  begin
   // calculate crc32
   CountBufferCrc(buffer,recordSize,pAnsiChar(buffer+recCrcOffset));
   // encode data in buffer with s
   try
    crypto := TCipher_Rijndael.Create(FPassword,nil);
    crypto.EncodeBuffer(buffer^,buffer^,recordSize);
    crypto.free;
   except
    raise Exception.Create(
      'Error in TEasyDataManager.ChangeBufferEncryption - encoding error.');
    end;
  end // encoding
 else
  begin
  // decode data in buffer with s
   try
    crypto := TCipher_Rijndael.Create(FPassword,nil);
    crypto.DecodeBuffer(buffer^,buffer^,recordSize);
    crypto.free;
   except
    raise Exception.Create(
      'Error in TEasyDataManager.ChangeBufferEncryption - decoding error.');
    end;
   // calculate crc32
   try
    if  (not CheckBufferCrc(buffer,recordSize,pAnsiChar(buffer+recCrcOffset))) then
      raise Exception.Create('Error in TEasyDataManager.ChangeBufferEncryption - crc error, decoding');
   except
    raise Exception.Create(
     'Error in TEasyDataManager.ChangeBufferEncryption - crc calc error, decoding 2');
   end;
  end; // decoding
end; //ChangeBufferEncryption


//------------------------------------------------------------------------------
// checks password by decoding all records and comparing check sum
// if specified password is invalid exception will be raised
//------------------------------------------------------------------------------
function TEasyDataManager.TryToOpenEncryptedTable: Boolean;
label ext, ext1;
var 
    buf : PAnsiChar;
    crypto: TCipher_Rijndael;
    bTableOpened: Boolean;
begin
 LockSection;
 try
  if (FPassword = '') then
   begin
     result := false;
     Exit;
   end;
  bTableOpened := tableFile <> nil;
  if (not bTableOpened) then
   try
    OpenFiles;
   except
    result := false;
    CloseFiles;
    Exit;
   end;
  result := true;
  if (not tableHeader.cipherUsed) then
   goto ext;
// try
   if (tableHeader.RecordCount <= 0) then
    goto ext;

   buf := AllocMem(bufferSize);
   tableFile.Seek(tableHeaderSize,soFromBeginning);
   tableFile.ReadBuffer(buf^,recInfoBufferSize);
   // decode data in buffer with s
   try
    crypto := TCipher_Rijndael.Create(FPassword,nil);
    crypto.DecodeBuffer(buf^,buf^,RecordSize);
    crypto.free;
   except
    result := false;
   end;
   if (result) then
    // calculate crc32
    try
     if  (not CheckBufferCrc(buf,recordSize,pAnsiChar(buf+recCrcOffset))) then
       begin
        result := false;
       end;
    except
     result := false;
    end;

ext1:
  FreeMem(buf);

ext:
  if (not bTableOpened) then
   CloseFiles;
 finally
  UnlockSection;
 end;
end; // TryToOpenEncryptedTable


//------------------------------------------------------------------------------
// returns true if table is encrypted
//------------------------------------------------------------------------------
function TEasyDataManager.IsTableEncrypted : Boolean;
begin
 LockSection;
 try
  if (not isTableOpened) then
   begin
    try
     OpenFiles;
     Result := tableHeader.cipherUsed;
    finally
     CloseFiles;
    end;
   end
  else
   Result := tableHeader.cipherUsed;
 finally
  UnlockSection;
 end;
end; //IsTableEncrypted


//------------------------------------------------------------------------------
// Saves table headers to disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.SaveTableHeaders;
var
    i            : Integer;
    pFieldHeader : pFieldHeaderType;
begin
 LockSection;
 try
   tableFile.Seek(0,soFromBeginning);
   //seq
   tableFile.WriteBuffer(tableHeader.sequenceValue,sizeOf(Integer));
   // seq name
    if (tableHeader.version > (4.50-0.001)) then
     begin
      tableFile.WriteBuffer(pAnsiChar(@(tableHeader.sequenceName[0]))^,sizeof(pFieldHeader^.fieldName));
     end
    else
     begin
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.sequenceName[0]))^,24);
     end;
   // field count
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.fieldCount))^,sizeof(Integer));
   // field count
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.recordCount))^,sizeof(Integer));
if (tableHeader.version < (4.50-0.01)) then
 begin
   tableFile.Seek(4,soFromCurrent);
 end;
   // version
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.version))^,sizeof(Double));
   // indexed
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.ShowAutoInc))^,1);
   // blobCompressed
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.blobCompressed))^,1);
   // cipherUsed
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.cipherUsed))^,2);
   // state
   tableFile.WriteBuffer(pAnsiChar(@(tableHeader.state))^,sizeof(integer));


   // Write field headers
   for i := 0 to tableHeader.fieldCount-1 do
   begin
      pFieldHeader := pFieldHeaderType(fieldHeaderList.Items[i]);
      if (pFieldHeader = nil) then raise Exception.Create(
       'Error in TEasyDataManager.SaveTableHeaders - pFieldHeader 0 pointer!' );
      if (tableHeader.version > (4.50-0.001)) then
       begin
        tableFile.WriteBuffer (pAnsiChar(@(pFieldHeader^.fieldName[0]))^,sizeof(pFieldHeader^.fieldName));
       end
      else
       begin
        tableFile.WriteBuffer (pAnsiChar(@(pFieldHeader^.fieldName[0]))^,21);
       end;

      tableFile.WriteBuffer (pAnsiChar(@(pFieldHeader^.fieldType))^,1);
      tableFile.Seek(2,soFromCurrent);
      tableFile.WriteBuffer (pAnsiChar(@(pFieldHeader^.fieldSize))^,sizeof(Integer));
      tableFile.WriteBuffer (pAnsiChar(@(pFieldHeader^.required))^,2);
      tableFile.Seek(2,soFromCurrent);
   end; //for fields
 finally
  UnlockSection;
 end;
end;// SaveTableHeaders


//------------------------------------------------------------------------------
// load table header from .dat file
//------------------------------------------------------------------------------
procedure TEasyDataManager.InternalLoadTableHeader(var hdr: TableHeaderType);
begin
 LockSection;
 try
   tableFile.Seek(0,soFromBeginning);
   //seq
   tableFile.ReadBuffer(hdr.sequenceValue,sizeOf(Integer));
   // seq name
if (tableHeader.version < (4.50-0.01)) then
 begin
   tableFile.ReadBuffer(pAnsiChar(@(hdr.sequenceName[0]))^,24)
 end
else
 begin
   tableFile.ReadBuffer(pAnsiChar(@(hdr.sequenceName[0]))^,sizeof(hdr.sequenceName))
 end;

   // field count
   tableFile.ReadBuffer(pAnsiChar(@(hdr.fieldCount))^,sizeof(Integer));
   // field count
   tableFile.ReadBuffer(pAnsiChar(@(hdr.recordCount))^,sizeof(Integer));
if (tableHeader.version < (4.50-0.01)) then
 begin
   tableFile.Seek(4,soFromCurrent);
 end;
   // version
   tableFile.ReadBuffer(pAnsiChar(@(hdr.version))^,sizeof(Double));
   // indexed
   tableFile.ReadBuffer(pAnsiChar(@(hdr.ShowAutoInc))^,1);
   // blobCompressed
   tableFile.ReadBuffer(pAnsiChar(@(hdr.blobCompressed))^,1);
   // cipherUsed
   tableFile.ReadBuffer(pAnsiChar(@(hdr.cipherUsed))^,2);
   // state
   tableFile.ReadBuffer(pAnsiChar(@(hdr.state))^,sizeof(integer));
 finally
  UnlockSection;
 end;
end;// InternalLoadTableHeader


//------------------------------------------------------------------------------
// load indexes for the table from disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.LoadTableHeaders;
var
    s1:            string[12];
    i,j,offset   : Integer;
    pFieldHeader : pFieldHeaderType;
    oldDC        : Char;
    v            : Double;
begin
 LockSection;
 try
  s1 := '';

  tableFile.Seek(40,soFromBeginning);
  tableFile.ReadBuffer(v,sizeof(Double));
  if (v > 1.11) and (v < (lastFormatVersion + 0.001)) then
   tableHeader.version := v
  else
   begin
   tableHeader.version := 2.10;
    if (tableFile.Size > 272) then
     begin
      tableFile.Seek(268,soFromBeginning);
      tableFile.ReadBuffer(v,sizeof(Double));
      if (v > (4.50-0.001)) and (v < (lastFormatVersion + 0.001)) then
       tableHeader.version := v;
     end;
   end;

  InternalLoadTableHeader(tableHeader);
  if (tableHeader.version < 1) then
   raise Exception.Create('Error opening table - invalid version = '+FloatToStr(tableHeader.version));
  if (tableHeader.sequenceName = '') then
   tableHeader.sequenceName := 'id';

//tableFile.Seek(4,soFromCurrent);

  FEncrypted := tableHeader.cipherUsed;
  FBlobCompression := tableHeader.blobCompressed;
  //read table header
{$IFDEF D17H}
  oldDC := FormatSettings.DecimalSeparator;
  FormatSettings.decimalSeparator := '.';
  if (tableHeader.version > lastFormatVersion) then raise Exception.Create(
       'Error in TEasyDataManager.OpenTable - Invalid db engine version in file '
       + FTableName + tableFileExtension+' (version = ' +
       FloatToStrF(tableHeader.version, ffFixed, 5, 2)+ ', internalCurrentVersion = '
       + FloatToStrF(lastFormatVersion, ffFixed, 5, 2) + ') !');
  FormatSettings.decimalSeparator := oldDC;
{$ELSE}
  oldDC := DecimalSeparator;
  decimalSeparator := '.';
  if (tableHeader.version > lastFormatVersion) then raise Exception.Create(
       'Error in TEasyDataManager.OpenTable - Invalid db engine version in file '
       + FTableName + tableFileExtension+' (version = ' +
       FloatToStrF(tableHeader.version, ffFixed, 5, 2)+ ', internalCurrentVersion = '
       + FloatToStrF(lastFormatVersion, ffFixed, 5, 2) + ') !');
  decimalSeparator := oldDC;
{$ENDIF}

  // read field headers
  recordSize := 0;
  j := 0; // num blob fields
  SetLength(fieldOffsets,tableHeader.fieldCount);
  offset := 0;
  for i := 0 to tableHeader.fieldCount-1 do
   begin
    new(pFieldHeader);
    if (pFieldHeader = nil) then raise Exception.Create(
       'Error in TEasyDataManager.OpenTable - pFieldHeader 0 pointer!' );
    if (tableHeader.version > (4.50-0.001)) then
     begin
      tableFile.ReadBuffer (pAnsiChar(@(pFieldHeader^.fieldName[0]))^,sizeof(pFieldHeader^.fieldName));
     end
    else
     begin
      tableFile.ReadBuffer (pAnsiChar(@(pFieldHeader^.fieldName[0]))^,21);
     end;
      tableFile.ReadBuffer (pAnsiChar(@(pFieldHeader^.fieldType))^,1);
      tableFile.Seek(2,soFromCurrent);
      tableFile.ReadBuffer (pAnsiChar(@(pFieldHeader^.fieldSize))^,sizeof(Integer));
      tableFile.ReadBuffer (pAnsiChar(@(pFieldHeader^.required))^,1);
      tableFile.Seek(3,soFromCurrent);

//if (i < tableHeader.fieldCount-1) then
// tableFile.Seek(3,soFromCurrent);
    fieldOffsets[i] := offset;
    offset := offset + pFieldHeader^.fieldSize;
    recordSize := recordSize + pFieldHeader^.fieldSize;
    fieldHeaderList.Add(pFieldHeader);
    if ((pFieldHeader^.fieldType = ftBLOB)
        or (pFieldHeader^.fieldType = ftMemo)
        or (pFieldHeader^.fieldType = ftFmtMemo)
        or (pFieldHeader^.fieldType = ftGraphic))
     then
      inc(j);
   end; //for fields
  fieldFlagsSize := (tableheader.fieldCount+7) div 8;
  infoBufferSize := sizeOf(Integer)+ fieldFlagsSize+sizeof(s1);
//  if (fieldFlagsSize < 8) then
  recNullOffset := recordSize + sizeof(integer);
  if (tableHeader.version < 1.24) then
    fieldFlagsSize := 8; // for backward compatibility
  recCrcOffset := recNullOffset+fieldFlagsSize;

  infoBufferSize := sizeOf(Integer)+ fieldFlagsSize+sizeOf(s1);
  if (infoBufferSize < 32) then
   infoBufferSize := 32; // for backward compatibility
  recInfoBufferSize :=  recordSize + infoBufferSize;
  tableHeaderSize := tableFile.Position;
  tableFile.Seek(0,soFromBeginning);
  if (tableFile.Size > tableHeaderSize + tableHeader.recordCount * recInfoBufferSize) then
    tableFile.Size := tableHeaderSize + tableHeader.recordCount * recInfoBufferSize;
  calculatedOffset := recInfoBufferSize + sizeOf (BookmarkInfoType);
  bufferSize := calculatedOffset;
  isBLOBUsed := false;
  if j > 0 then
	  isBLOBUsed := true;
 finally
  UnlockSection;
 end;
end;// TEasyDataManager.LoadTableHeaders;


//------------------------------------------------------------------------------
// load indexes for the table from disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.LoadIndexesFromDisk;
var i,k,indSize,loadSize: integer;
    pIndexHeader : pIndexHeaderType;
    bHeadersOk,
    bIndexesOk, bAutoIndexes: Boolean;
    AutoIndexCount: integer;
begin
 LockSection;
 try
  bHeadersOk := true;
  bIndexesOk := true;
  indexFileHeader.indexCount := 0;
  indexFileHeader.state := tableHeader.state;
  indexFileHeader.version := tableHeader.version;
  if (IndexFile.size < sizeOf(indexFileHeader)) then
	 bHeadersOk := false
  else
   begin
   IndexFile.Seek(0,soFromBeginning);
   IndexFile.ReadBuffer(indexFileHeader,sizeOf(indexFileHeaderType));
     // number of indexes should be always greater or equal to number of fields
     //	due to using auto indexes
  // WRONG !!! - BLOB field don't have any index
  //   if (indexFileHeader.indexCount < tableHeader.fieldCount) then
   if (indexFileHeader.indexCount < 1) then
    begin
		 indexFileHeader.indexCount := 0;
     indexFileHeader.state := tableHeader.state;
     indexFileHeader.version := tableHeader.version;
  	 bHeadersOk := false;
    end;
  end;


  indexHeaderList.Clear;
  if (bHeadersOk) then
   begin
    // try to load all index headers
  SetLength(indexes, indexFileHeader.indexCount);
  SetLength(indexUpdated,indexFileHeader.indexCount);
  // load index headers
  for i := 0 to indexFileHeader.indexCount-1 do
   begin
    indexes[i] := TaaIntArray.Create;
    indexes[i].SetSize(tableHeader.recordCount);
    indexUpdated[i] := true;
    new (pIndexHeader);
    indexHeaderList.Add(pIndexHeader);
    pIndexHeader^.indexCount := 0;
    pIndexHeader^.indexOrders := nil;
    pIndexHeader^.indexCaseIns := nil;
	  pIndexHeader^.indexFields := nil;
    pIndexHeader^.ignoreCase := false;
    pIndexHeader^.descending := false;
    // load index header
    // load index name
    if (tableHeader.version > (4.50-0.001)) then
     begin
    loadSize := sizeOf(pIndexHeader^.indexName);
     end
    else
     begin
      loadSize := OLD_MAX_NAME_LENGTH+1;
     end;
    if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
	   IndexFile.ReadBuffer(pIndexHeader^.indexName,loadSize);
     if (pIndexHeader^.indexName = '') then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     // new index header format
     loadSize := sizeOf(Integer);
     if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     IndexFile.ReadBuffer(pIndexHeader^.indexCount,loadSize);
     k := pIndexHeader^.indexCount;
     if (k <= 0) or (k > ((tableheader.fieldCount+1)*(tableheader.fieldCount+1)*10)) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     SetLength(pIndexHeader^.indexFields,k);
     loadSize := sizeOf(Integer) * k;
     if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     IndexFile.ReadBuffer(pIndexHeader^.indexFields[0],loadSize);
     pIndexHeader^.indexOrders := AllocMem((k+7) div 8);
     loadSize := (k+7) div 8;
     if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     IndexFile.ReadBuffer(pAnsiChar(pIndexHeader^.indexOrders)^,loadSize);
     pIndexHeader^.indexCaseIns := AllocMem(loadSize);
     if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     IndexFile.ReadBuffer(pAnsiChar(pIndexHeader^.indexCaseIns)^,loadSize);
     loadSize := sizeOf(Boolean);
     if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     IndexFile.ReadBuffer(pIndexHeader^.ignoreCase,loadSize);
     if (indexFile.Size - indexFile.Position < loadSize) then
      begin
     		bHeadersOk := false;
	      break;
  	  end;
     IndexFile.ReadBuffer(pIndexHeader^.descending,loadSize);
// lastFormatVersion - 2.2.
     if (tableHeader.version + 0.001 > 2.2) then
      begin
	     loadSize := sizeOf(TIndexOptions);
	     if (indexFile.Size - indexFile.Position < loadSize) then
	      begin
	     		bHeadersOk := false;
		      break;
	  	  end;
       IndexFile.ReadBuffer(pIndexHeader^.indexOptions,loadSize);
      end;
  end; // loading all headers
  end; // if headers ok
 indexChangesCount := 0;

  if (not bHeadersOk) then
   begin
    AutoIndexCount := 0;
    // remove all loaded indexes and detect autoindexes
	  for i := 0 to indexHeaderList.Count-1 do
	   begin
      // auto-index?
      if (pIndexHeaderType(indexHeaderList.Items[i])^.indexName[1] = '@') then
       Inc(AutoIndexCount);

      if (pIndexHeaderType(indexHeaderList.Items[i])^.indexOrders <> nil) then
  	    FreeMem(pIndexHeaderType(indexHeaderList.Items[i])^.indexOrders);
      if (pIndexHeaderType(indexHeaderList.Items[i])^.indexCaseIns <> nil) then
		    FreeMem(pIndexHeaderType(indexHeaderList.Items[i])^.indexCaseIns);
      if (pIndexHeaderType(indexHeaderList.Items[i])^.indexFields <> nil) then
		    SetLength(pIndexHeaderType(indexHeaderList.Items[i])^.indexFields,0);
	    indexes[i].Free;
	    dispose(indexHeaderList.Items[i]);
	   end;
	  while indexHeaderList.Count > 0 do
	   indexHeaderList.Remove(indexHeaderList.Items[0]);
	  indexFileHeader.indexCount := 0;
	  SetLength(indexes,0);
	  indexes := nil;
	  indexUpdated := nil;
    bAutoIndexes := (AutoIndexCount > 1);
    // repair indexes
    CreateAutoIndexes(bAutoIndexes);
    BuildAllIndexes;

    if (not FReadOnly) then
     SaveIndexesToDisk;
	  Exit;
  end;

  // loading indexes
  if (tableHeader.recordCount > 0) then
   begin
    if (indexFileHeader.State <> tableHeader.State) then
     begin
      // rebuilding indexes
      BuildAllIndexes;
     end // rebuilding indexes
    else
     begin
      // loading indexes
     indSize := sizeOf(integer) * tableHeader.recordCount;
      for i := 0 to indexFileHeader.indexCount-1 do
       begin
  	     if (indexFile.Size - indexFile.Position < indSize) then
  	      begin
  	     		bIndexesOk := false;
  		      break;
  	  	  end;
        IndexFile.ReadBuffer(indexes[i].items[0],indSize);
       end; // loading indexes
      if (not bIndexesOk) then
  	     BuildAllIndexes;
     end; // if index state is correct (equalt to table state)
   end; // if there are somre records in table
 finally
  UnlockSection;
 end;
end; //LoadIndexesFromDisk


//------------------------------------------------------------------------------
// load blob headers for the table from disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.LoadBLOBHeadersFromDisk;
var   i,j,n,offset,size,size1,size2,size3,size4,size5,
      pos, recCount, fieldCount : integer;
      buffer   : PAnsiChar;
      buffer1  : PAnsiChar;
begin
 LockSection;
 try
  if (not isBLOBUsed) then
   Exit;
  size := BLOBIndexFile.Size;
  buffer := AllocMem(size);
  if (BLOBIndexFile.Position > 0) then
   BLOBIndexFile.Seek(0,soFromBeginning);

  if (tableHeader.version >= (1.25-0.001)) then
   begin
    BLOBIndexFile.ReadBuffer(n,sizeof(integer));
    size := size - sizeof(integer);
    BLOBIndexFile.ReadBuffer(pAnsiChar(buffer)^,size);

    if (tableHeader.version < 2.2 - 0.001) then
//    // old version
//    aaDecompressBuffer(buffer,size,buffer1,n,clLZO)
    raise Exception.Create('Unsupported table format. Contact us at support@aidaim.com to convert this table to a new format.')
   else
    // release
    if (not aaDecompressBuffer(buffer,size,buffer1,n,clFastest)) then
     begin
      FreeMem(buffer);
      raise Exception.Create('Table is corrupted - blob headers cannot be decompressed. TableName = '+FTableName);
     end;
    size := n;
    FreeMem(buffer);
    buffer := buffer1;
   end
  else
   BLOBIndexFile.ReadBuffer(pAnsiChar(buffer)^,size);
  // sizes
  size1 := sizeOf(BLOBindexFileHeaderType);
  size2 := sizeOf(TaaBLOBHeader);
  size3 := sizeOf(TaaBLOBPart);
  offset := 0;
  // load blob file header
  Move(buffer^,blobFileHeader,size1);
  inc(offset,size1);
  recCount := blobFileHeader.recordCount-1;
  fieldCount := blobFileHeader.fieldCount-1;
  size4 := (fieldCount+1) * (recCount + 1);
 // aaStartTime;
  blobHeaders.SetSize(size4);
 // aaStopTime;
 // blobMap.SetSize(recCount+1);
  size4 := fieldCount+1;
  size5 := blobFileHeader.numDeletedParts ;
  pos := 0;
  if (recCount < 0) then
   begin
    FreeMem(buffer);
    Exit;
   end;
  // load blob data headers
  n := size2 * size4 * (recCount+1);
  Move((buffer+offset)^,blobHeaders.headers[pos],n);
  for i := 0 to recCount do
   begin
    blobMap.Append (pos);
 //   blobMap.Insert(i,pos);
    inc(pos,size4);
   end;
  // load parts
  for i := 0 to recCount do
   begin
    pos := blobMap.items[i];
    for j := pos to pos + fieldCount do
     begin
      blobHeaders.parts[j] := nil;
      n := blobHeaders.headers[j].numParts;
      if (n <= 0) then
       continue;
      SetLength(blobHeaders.parts[j],n);
       offset := blobHeaders.headers[j].position;
      n := n * size3;
      Move((buffer+offset)^,blobHeaders.parts[j][0],n);
     end; // for j
   end;
  // save deleted parts
  blobDelParts.SetSize(size5);
  size5 := size5 * size3;
  if (size5 > 0) then
   Move((buffer+size-size5)^,blobDelParts.items[0],size5);
  FreeMem(buffer);
 finally
  UnlockSection;
 end;
end; //LoadBLOBHeadersFromDisk


//------------------------------------------------------------------------------
// save blob headers for the table to disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.SaveBLOBHeadersToDisk(bCreate : Boolean = false);
var   i,j,n,k,offset,size,size1,size2,size3,size4,size5,
      pos, recCount, fieldCount : integer;
      buffer   : PAnsiChar;
      buffer1  : PAnsiChar;
begin
 LockSection;
 try
  if (not bCreate) then
   if ((FReadOnly) or (not isBLOBUsed)) then Exit;
  if (blobFileHeader.recordCount <= 0) then
   begin
    blobFileHeader.numDeletedParts := 0;
    BLOBDataFile.Size := 0;
    BLOBIndexFile.Size := 0;
    // prepare default header
    n := sizeOf(BLOBIndexFileHeaderType);
    buffer := AllocMem(n);
    Move(blobFileHeader,buffer^,sizeOf(BLOBIndexFileHeaderType));
    aaCompressBuffer(buffer,n,buffer1,k,clFastest);
    FreeMem(buffer);
    BLOBIndexFile.WriteBuffer(n,sizeof(integer));
    BLOBIndexFile.WriteBuffer(buffer1^,k);
    FreeMem(buffer1);
    Exit;
   end;
 //Exit;
 //aaStartTime;
  recCount := blobFileHeader.recordCount-1;
  fieldCount := blobFileHeader.fieldCount-1;
  size1 := sizeOf(BLOBIndexFileHeaderType);
  size2 := sizeOf(TaaBLOBHeader);
  size3 := sizeOf(TaaBLOBPart);
  size4 := (fieldCount+1) * (recCount + 1) * size2;
  size5 := blobFileHeader.numDeletedParts * size3;
  offset := size1 + size4;
  for i := 0 to recCount do
   begin
    pos := blobMap.items[i];
    for j := pos to pos + fieldCount do
     begin
      blobHeaders.headers[j].position := offset;
      if (blobHeaders.headers[j].size <= 0) then
       begin
        blobHeaders.headers[j].size := 0;
        blobHeaders.headers[j].trueSize := 0;
        blobHeaders.headers[j].numParts:= 0;
       end;
      n := blobHeaders.headers[j].numParts;
      inc(offset, size3 * n);
     end; // for j
   end; // for i
  size :=  offset+size5;
  buffer := AllocMem(size);
  offset := 0;
  // save blob file header
  Move(blobFileHeader,(buffer+offset)^,size1);
  inc(offset,size1);
  // save blob data headers
  for i := 0 to recCount do
   begin
    pos := blobMap.items[i];
    n := size2 * (fieldCount+1);
    Move(blobHeaders.headers[pos],(buffer+offset)^,n);
    inc(offset,n);
 {   for j:=0 to fieldCount do
     begin
      Move(blobHeaders.headers[pos],(buffer+offset)^,size2);
      inc(offset,32);
      inc(pos);
     end;}
   end;
  // save parts
  for i := 0 to recCount do
   begin
    pos := blobMap.items[i];
    for j := pos to pos + fieldCount do
     begin
      n := blobHeaders.headers[j].numParts * size3;
      if (n <= 0) then
       continue;
      Move(blobHeaders.parts[j][0],(buffer+offset)^,n);
      inc(offset,n);
     end; // for j
   end;
  // save deleted parts
  if (size5 > 0) then
    Move(blobDelParts.items[0],(buffer+offset)^,size5);

  aaCompressBuffer(Buffer,size,buffer1,size1,clFastest);

  BLOBIndexFile.Size := size1+sizeof(integer);
  if (BLOBIndexFile.Position > 0) then
   BLOBIndexFile.Seek(0,soFromBeginning);
  BLOBIndexFile.WriteBuffer(size,sizeof(integer));
  BLOBIndexFile.WriteBuffer(pAnsiChar(buffer1)^,size1);
  FreeMem(buffer);
  FreeMem(buffer1);
 //aaStopTime;
 finally
  UnlockSection;
 end;
end; //SaveBLOBHeadersToDisk


//------------------------------------------------------------------------------
// save indexes for the table to disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.SaveIndexesToDisk;
var i,k: integer;
    pIndexHeader : pIndexHeaderType;
begin
 LockSection;
 try

  // counting number of temporary indexes
  k := 0;
  for i := 0 to indexHeaderList.Count-1 do
   begin
    pIndexHeader := pIndexHeaderType(indexHeaderList.Items[i]);
    if (pIndexHeader^.indexName[1] <> '$') then
      Inc(k);
   end;

{$IFDEF DEBUG_FLAG}
aaWriteToLog('save indexes. IndexCount = '+ IntToStr(k) + CRLF +
'TemporaryIndexCount = '+IntToStr(indexHeaderList.Count-k));
{$ENDIF}

  indexFileHeader.indexCount := k;
  indexFileHeader.State := tableHeader.State;
  IndexFile.Position := 0;
  IndexFile.WriteBuffer(indexFileHeader,sizeOf(indexFileHeaderType));
  // save index headers
  for i := 0 to indexHeaderList.Count-1 do
   begin
    pIndexHeader := pIndexHeaderType(indexHeaderList.Items[i]);
    // skipping temporary indexes
    if (pIndexHeader^.indexName[1] = '$') then continue;
     // new index header format
    if (tableHeader.version > (4.50-0.001)) then
     begin
     IndexFile.WriteBuffer(pIndexHeader^.indexName,sizeOf(pIndexHeader^.indexName));
     end
    else
     begin
// old versions support
       IndexFile.WriteBuffer(pIndexHeader^.indexName,OLD_MAX_NAME_LENGTH+1);
     end;

     IndexFile.WriteBuffer(pIndexHeader^.indexCount,sizeOf(Integer));
     k := pIndexHeader^.indexCount;
     IndexFile.WriteBuffer(pIndexHeader^.indexFields[0],sizeOf(Integer) * k);
     IndexFile.WriteBuffer(pAnsiChar(pIndexHeader^.indexOrders)^,(k+7) div 8);
     IndexFile.WriteBuffer(pAnsiChar(pIndexHeader^.indexCaseIns)^,(k+7) div 8);
     IndexFile.WriteBuffer(pIndexHeader^.ignoreCase,sizeOf(Boolean));
     IndexFile.WriteBuffer(pIndexHeader^.descending,sizeOf(Boolean));
     IndexFile.WriteBuffer(pIndexHeader^.indexOptions,sizeOf(TIndexOptions));
   end;
  // saving indexes
  if (tableHeader.recordCount > 0) then
   for i := 0 to indexFileHeader.indexCount-1 do
    begin
     pIndexHeader := pIndexHeaderType(indexHeaderList.Items[i]);
     BuildIndex(i);
     // skipping temporary indexes
     if (pIndexHeader^.indexName[1] = '$') then continue;
     IndexFile.WriteBuffer(indexes[i].items[0],sizeOf(integer) * tableHeader.recordCount);
    end;
  IndexFile.size := IndexFile.Position;  
 finally
  UnlockSection;
 end;
end; //SaveIndexesToDisk

{
//------------------------------------------------------------------------------
// save indexes for the table to disk
//------------------------------------------------------------------------------
procedure TEasyDataManager.SaveFieldHeadersToDisk;
var i : integer;
begin
 LockSection;
 try
  if (FReadOnly) then Exit;
  tableFile.Seek(sizeOf(tableHeaderType),soFromBeginning);
  for i := 0 to fieldHeaderList.Count-1 do
    if (tableHeader.version > (4.50-0.001)) then
     begin
    tableFile.WriteBuffer(pFieldHeaderType(fieldHeaderList.Items[i])^,sizeOf(fieldHeaderType));
     end
    else
     begin
      // old versions support
;//      tableFile.WriteBuffer(pFieldHeaderType(fieldHeaderList.Items[i])^,sizeOf(fieldHeaderType));
     end;
 finally
  UnlockSection;
 end;
end; //SaveFieldHeadersToDisk
}

//------------------------------------------------------------------------------
// converter for old versions table format
//------------------------------------------------------------------------------
procedure TEasyDataManager.ConvertToCurrentFormat;
var s : AnsiString;
    i,j,k,f : integer;
    pIndexHeader : pIndexHeaderType;
    ms:	TMemoryStream;
begin
 if (FReadOnly) then
      raise Exception.Create(
     'Error in TEasyDataManager.ConvertToCurrentTable - table is in ReadOnly mode!');
 if (tableHeader.version < (1.25 - 0.001)) and (isBLOBUsed) then
      raise Exception.Create(
     'Error in TEasyDataManager.ConvertToCurrentTable - this table format is not supported, version = '+
       FloatToStrF(tableHeader.version,ffFixed,3,2)+crlf+'Please, contact us - mailto:support@aidaim.com to solve this problem.');

 if (tableHeader.version < (2.10 - 0.001)) then
 begin
  for i:= 0 to tableHeader.fieldCount-1 do
   if (
       (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftString) or
       (pFieldHeaderType(fieldHeaderList.Items[i])^.fieldType = ftWideString)) then
    begin
     s := pFieldHeaderType(fieldHeaderList.Items[i])^.fieldName;
     AddIndex('@@'+s,s,[ixCaseInsensitive],'','',true);
    end;
  for i:= 0 to indexFileHeader.indexCount-1 do
   begin
    f := 0;
    pIndexHeader := pIndexHeaderType(indexHeaderList.Items[i]);
    for j:= 0 to pIndexHeader^.indexCount-1 do
     begin
      if (f > 0) then
       break;
      k := pIndexHeader^.indexFields[j];
      if (k >= 0) then
       if (pFieldHeaderType(fieldHeaderList.Items[k])^.fieldType = ftDateTime) or
          (pFieldHeaderType(fieldHeaderList.Items[k])^.fieldType = ftDate) or
          (pFieldHeaderType(fieldHeaderList.Items[k])^.fieldType = ftTime) then
        begin
         indexUpdated[i] := false;
         BuildIndex(i);
         inc(f);
        end;
     end;
   end;
  end; // 2,05  converter
 if (IsBlobConvertNeeded)  then
  begin
   ms := TMemoryStream.Create;
   for i := 0 to blobFileHeader.recordCount-1 do
    for j := 0 to tableHeader.fieldCount-1 do
     if (
     		(pFieldHeaderType(fieldHeaderList.Items[j])^.fieldType = ftBLOB) or
	      (pFieldHeaderType(fieldHeaderList.Items[j])^.fieldType = ftMemo) or
	      (pFieldHeaderType(fieldHeaderList.Items[j])^.fieldType = ftFmtMemo) or
	      (pFieldHeaderType(fieldHeaderList.Items[j])^.fieldType = ftGraphic)) then
      begin
       ms.Clear;
       aaReadBLOBValue(ms,j,i);
       aaWriteBLOBValue(ms,j,i);
      end;
   ms.Free;
  end;


 tableHeader.version := lastFormatVersion;
 indexFileHeader.version := tableHeader.version;
{ tableFile.Seek(0,soFromBeginning);
 tableFile.WriteBuffer(tableHeader,sizeof(tableHeaderType));}
 FlushBuffers;
 SaveIndexesToDisk;
 if (isBLOBUsed) then
  SaveBLOBHeadersToDisk;
end; //ConvertToCurrentFormat


//------------------------------------------------------------------------------
// get field number
//------------------------------------------------------------------------------
function TEasyDataManager.InternalGetFieldNo(FieldName : AnsiString; ExceptionAllowed: Boolean = True):integer;
var i,f : integer;
begin
 if (LowerCase(fieldName) = LowerCase(tableHeader.sequenceName)) then
  begin
   result := -1;
   Exit;
  end;
 i := 0;
 f := 0;
   while i < fieldHeaderList.Count do
    begin
    	if (pFieldHeaderType(fieldHeaderList.Items[i]) = nil) then raise Exception.Create(
      	'Error in TEasyDataManager.InternalGetFieldNo - field header 0 pointer!');
      if (LowerCase(fieldName) =
    		LowerCase(pFieldHeaderType(fieldHeaderList.Items[i])^.fieldName)) then
       begin
        f := 1;
        break;
       end;//found
      inc(i);
    end;// while fields
 if (f = 0) then
  if (ExceptionAllowed) then
    raise Exception.Create(
       	'Error in TEasyDataManager.InternalGetFieldNo - field "'+FieldName+'" not found!')
  else
    i := -2; // field not found

 Result := i;
end; //InternalGetFieldNo


//------------------------------------------------------------------------------
// get index number
//------------------------------------------------------------------------------
function TEasyDataManager.InternalGetIndexNo(IndexName : AnsiString):integer;
var i,f : integer;
begin
 i := 0;
 f := 0;
   while i < indexHeaderList.Count do
    begin
    	if (pIndexHeaderType(indexHeaderList.Items[i]) = nil) then raise Exception.Create(
      	'Error in TEasyDataManager.InternalGetIndexNo - Index header 0 pointer!');
      if (LowerCase(IndexName) =
    		LowerCase(pIndexHeaderType(indexHeaderList.Items[i])^.IndexName)) then
       begin
        f := 1;
        break;
       end;//found
      inc(i);
    end;// while Indexs
// if (f = 0) then raise Exception.Create(
//      	'Error in TEasyDataManager.InternalGetIndexNo - Index "'+IndexName+'" not found!');
 if (f = 0) then
  Result := -1
 else
  Result := i;
end; //InternalGetIndexNo


//------------------------------------------------------------------------------
// get Field Type by FieldNo
//------------------------------------------------------------------------------
function TEasyDataManager.InternalGetFieldType(FieldNo: integer): TFieldType;
begin
  if (FieldNo = -1) or (FieldNo = tableHeader.fieldCount) then
    Result := ftAutoInc
  else
    Result := pFieldHeaderType(fieldHeaderList.Items[FieldNo])^.fieldType;
end;//InternalGetFieldType


//------------------------------------------------------------------------------
// sets autoinc value
//------------------------------------------------------------------------------
procedure TEasyDataManager.SetAutoIncValue(value : integer);
begin
 tableHeader.sequenceValue := value - 1;
end; //SetAutoIncValue


//------------------------------------------------------------------------------
// adds record, modifies indexes and restore tablePosition
//------------------------------------------------------------------------------
function TEasyDataManager.aaAddRecord(
				        recordBuffer : PAnsiChar; // pointer to record buffer
                currentIndex : Integer // from source DataManager
        				        ) : Integer;
var recCount  : integer;
    pBuffer   : PAnsiChar;
    num,i     : Integer;
    bUpdateindexesRecommended: Boolean;
    DMHandle  : TEasyDataManager;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 LockSection;
 try
  cmpRecBuf_find :=  false;
  findValIns_array := nil;
  //aaInitTime;
  //aaStartTime;
   DMHandle := self;
   // after ThresholdRecordCount - always update DMHandle.indexes
   if (tableHeader.recordCount > ThresholdRecordCount) then
    UpdateAllIndexes;
   // update table header
   if (pRecordInfoType(recordBuffer+recordSize)^.id >= tableHeader.sequenceValue) then
    tableHeader.sequenceValue := pRecordInfoType(recordBuffer+recordSize)^.id;
   Inc(tableHeader.state);
   // count new id
//   pRecordInfoType(recordBuffer+recordSize)^.id := tableHeader.sequenceValue;
   recCount := tableHeader.recordCount;
  //aaStartTime;
   allRecBuffer.Append(recordBuffer);
  //aaStopTime;
   Inc(tableHeader.recordCount);
   // updating indexes
  result := 0;
   bUpdateIndexesRecommended := IsUpdateIndexesNowRecommended;
   for i := 0 to indexFileHeader.indexCount-1 do
    if ((i = currentIndex) or bUpdateIndexesRecommended) and indexUpdated[i] then
     begin
      findValIns_recordBuffer := recordBuffer;
      findValIns_array := aInteger(indexes[i].items);
      findValIns_pIndex := pIndexHeaderType(indexHeaderList.Items[i]);
      findValIns_recCount := recCount;
      findValIns_ignoreCase := false;
      findValIns_partialCompare := false;
      findValIns_search := false;
  //debugFlag := true;
      {$include find_ind.inc}
 // DebugFlag := false;

      num := findValIns_result;
      if (num < 0) then
        num := 0;
      indexes[i].Insert(num,recCount);
      if (i = currentIndex) then
       result := num;
     end
    else
     indexUpdated[i] := false;
   //--------------- write to disk ------------------
   // update record header
   if (FEncrypted) then
    begin
     pBuffer := AllocMem(recInfoBufferSize);
     Move(recordBuffer^,pBuffer^,recInfoBufferSize);
     ChangeBufferEncryption(pBuffer,1);
     bufferLog.Append(roMove,pBuffer,recInfoBufferSize,recCount,false);
     FreeMem(pbuffer);
    end
   else
    bufferLog.Append(roMove,recordBuffer,recInfoBufferSize,recCount);

   CheckBuffersOverflow;
  //aaStartTime;
  //aaStopTime;
  //aaStopTime;
 finally
  UnlockSection;
 end;
end; //aaAddRecord


//------------------------------------------------------------------------------
// modifies record, modifies indexes and restore tablePosition
//------------------------------------------------------------------------------
function TEasyDataManager.aaUpdateRecord(
				        recordBuffer : PAnsiChar; // pointer to record buffer
                currentIndex : Integer; // from source DataManager
                recPos       :Integer // physical record position
        				        ) : Integer;
var recCount      : integer;
    pBuffer              : PAnsiChar;
    oldNum,num,i : Integer;
    bUpdateIndexesRecommended: Boolean;
    DMHandle : TEasyDataManager;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 LockSection;
 try
  cmpRecBuf_find :=  false;
  findValIns_array := nil;
  DMHandle := self;
  // after ThresholdRecordCount - always update indexes
  if (tableHeader.recordCount > ThresholdRecordCount) then
   UpdateAllIndexes;

  // update table header
   if (pRecordInfoType(recordBuffer+recordSize)^.id >= tableHeader.sequenceValue) then
    tableHeader.sequenceValue := pRecordInfoType(recordBuffer+recordSize)^.id;
  Inc(tableHeader.state);
  recCount := tableHeader.recordCount;
  pBuffer := allRecBuffer.GetRecordDataPtr(recPos);
  allRecBuffer.LockRecordPage(recPos);
  // updating indexes
  Result := 0;
  bUpdateindexesRecommended := IsUpdateindexesNowRecommended;
  for i := 0 to indexFileHeader.indexCount-1 do
   if ((i = currentIndex) or bUpdateindexesRecommended) and indexUpdated[i] then
    begin
     // compare old and new field values using index
     cmpRecBuf_buffer1 := recordBuffer;
     cmpRecBuf_buffer2 := pBuffer;
     cmpRecBuf_bPartialCompare := false;
     cmpRecBuf_ignoreCase := false;
     cmpRecBuf_pIndexHeader := pIndexHeaderType(indexHeaderList.Items[i]);
    {$include compare.inc}

     // update index?
     if (cmpRecBuf_res <> 0) then
      begin
       oldNum := aaFindIndexValue(i,recPos,recCount);
       findValIns_recordBuffer := recordBuffer;
       findValIns_array := aInteger(indexes[i].items);
       findValIns_pIndex := cmpRecBuf_pIndexHeader;
       findValIns_recCount := recCount;
       findValIns_ignoreCase := false;
       findValIns_partialCompare := false;
       findValIns_search := false;
      {$include find_ind.inc}

       num := findValIns_result;
       if (num < 0) then
       num := 0;
       if (num <> oldNum) and
          (num <> (oldNum+1)) then
        indexes[i].MoveTo(oldNum,num);
       if (i = currentIndex) then
         Result := num;
     end
     else
        if (i = currentIndex) then
        Result := aaFindIndexValue(i,recPos,recCount);
    end
   else
    indexUpdated[i] := false;

  //aaStartTime;
  Move(recordBuffer^,pBuffer^,recInfoBufferSize);
  //--------------- write to disk ------------------
 // update record header
  if (FEncrypted) then
   begin
    pBuffer := AllocMem(recInfoBufferSize);
    Move(recordBuffer^,pBuffer^,recInfoBufferSize);
    ChangeBufferEncryption(pBuffer,1);
    bufferLog.Append(roMove,pBuffer,recInfoBufferSize,recPos,false);
    FreeMem(pbuffer);
   end
  else
   bufferLog.Append(roMove,recordBuffer,recInfoBufferSize,recPos);

  allRecBuffer.UnlockRecordPage(recPos);
  CheckBuffersOverflow;
 //aaStopTime;
 finally
  UnlockSection;
 end;
end; //aaUpdateRecord


//------------------------------------------------------------------------------
// deletes record, modifies indexes and restore tablePosition
//------------------------------------------------------------------------------
function TEasyDataManager.aaDeleteRecord (
                currentIndex : Integer; // from source DataManager
                recPos       : Integer // physical record position
                                          ): Integer;
var recCount  : integer;
    pBuffer,recordBuffer : PAnsiChar;
    num,oldNum,i : Integer;
    bUpdateIndexesRecommended: Boolean;
begin
 LockSection;
 try
 //aaStartTime;
  // after ThresholdRecordCount - always update indexes
  if (tableHeader.recordCount > ThresholdRecordCount) then
   UpdateAllindexes;

  // update table header
  Inc(tableHeader.state);
  recCount := tableHeader.recordCount;
  // updating indexes
  Result := 0;
  bUpdateindexesRecommended := IsUpdateindexesNowRecommended;
  for i := 0 to indexFileHeader.indexCount-1 do
   if ((i = currentIndex) or bUpdateindexesRecommended) and indexUpdated[i] then
    begin
     num := 0;
 {
     if (not IsViewConstrained) and (i=currentIndex) then
      oldNum := tablePosition
     else
      begin
 }
       oldNum := aaFindIndexValue(i,recPos,recCount);
       if (oldNum < 0) then
         raise
             Exception.Create('TEasyDataManager.aaDeleteRecord - invalid record Number, recPos = '+
                              inttostr(recPos));
//     end;
     if (recPos < recCount-1) then
      begin
       num := aaFindIndexValue(i,recCount-1,recCount);
       if (num < 0) then raise
            Exception.Create('TEasyDataManager.aaDeleteRecord - invalid record Number, last = '+
                             inttostr(recCount-1));
       indexes[i].items[num] := recPos;
      end;
     indexes[i].Delete(oldNum);
     if (i = CurrentIndex) then
      Result := Num;
    end
   else
    indexUpdated[i] := false;

  //--------------- write to disk ------------------
  // update record header
  Dec(tableHeader.recordCount);
  if (recPos < recCount-1) then
   begin
    recordBuffer := allRecBuffer.GetRecordDataPtr(recCount-1);
    if (FEncrypted) then
     begin
      pBuffer := AllocMem(recInfoBufferSize);
      Move(recordBuffer^,pBuffer^,recInfoBufferSize);
      ChangeBufferEncryption(pBuffer,1);
      bufferLog.Append(roMove,pBuffer,recInfoBufferSize,recPos,false);
      FreeMem(pbuffer);
     end
    else
     bufferLog.Append(roMove,recordBuffer,recInfoBufferSize,recPos);
   end;
  allRecBuffer.Delete(recPos);
  CheckBuffersOverflow;
 //aaStopTime;
 finally
  UnlockSection;
 end;
end; //aaDeleteRecord


//------------------------------------------------------------------------------
// add blob index headers for new record - optimized
//------------------------------------------------------------------------------
procedure TEasyDataManager.aaAddBLOBRecord;
var qty,pos   : Integer;
begin
 LockSection;
 try
  if (blobMap.ItemCount <> blobFileHeader.RecordCount) then
   raise Exception.Create('TEasyDataManager.aaAddBLOBRecord - blobMap.ItemCount <> blobFileHeader.RecordCount');
 // appends blobHeaders
  pos := blobHeaders.ItemCount;
  qty := blobFileHeader.fieldCount;
  blobMap.Insert(blobFileHeader.recordCount,pos);
  blobHeaders.SetSize(blobHeaders.ItemCount+qty);

  inc(blobFileHeader.recordCount);
 finally
  UnlockSection;
 end;
end; //aaAddBLOBRecord


//------------------------------------------------------------------------------
// delete blob index headers for current record
//------------------------------------------------------------------------------
procedure TEasyDataManager.aaDeleteBLOBRecord(
          physRecNo : Integer);
var
    i,j   : Integer;
    pFieldHeader: pFieldHeaderType;
begin
 LockSection;
 try
  if (blobFileHeader.recordCount <= 0) then
    Exit;
  // delete blob data from all fields of the current record
  j := blobMap.items[physRecNo] ;
 // j := j * f;
 //aaStartTime;
  for i := 0 to fieldHeaderList.Count-1 do
   begin
    pFieldHeader := pFieldHeaderType(fieldHeaderList.Items[i]);
    if ((pFieldHeader^.fieldType = ftBLOB) or
       (pFieldHeader^.fieldType = ftMemo) or
       (pFieldHeader^.fieldType = ftFmtMemo) or
       (pFieldHeader^.fieldType = ftGraphic))
     then
      begin
       if (blobHeaders.headers[j].size > 0) then
        aaDeleteBLOBValue(i,physRecNo,true);
       inc(j);
      end;
   end;
 //aaStopTime;
 // if (j > blobMap.items[physRecNo]) then
 //aaStartTime;
  blobMap.Items[physRecNo] := blobMap.Items[blobFileHeader.recordCount-1];
  blobMap.Delete(blobFileHeader.recordCount-1);
  dec(blobFileHeader.recordCount);
//aaStopTime;
 finally
  UnlockSection;
 end;
end; //aaDeleteBLOBRecord


//------------------------------------------------------------------------------
// delete blob field value for current record
//------------------------------------------------------------------------------
procedure TEasyDataManager.aaDeleteBLOBValue(
                                fieldNo : integer;
                                physRecNo : Integer;
                                inMemory : Boolean = false
                                );
var i,n,pos,fieldNum : Integer;
    pFieldHeader: pFieldHeaderType;
begin
 LockSection;
 try
  if (blobFileHeader.recordCount <= 0) then Exit;
 // pos := physRecNo;
  pos := blobMap.items[physRecNo];
  // count blob fieldNum (0,1,2,...,blobFileHeader.fieldCount-1)
  fieldNum := 0;
   for i := 0 to FieldNo-1 do
    begin
     pFieldHeader := pFieldHeaderType(fieldHeaderList.Items[i]);
     if (pFieldHeader = nil) then raise Exception.Create(
      'Error in TEasyDataManager.DeleteBLOBValue - 0 pointer to pFieldHeader, fieldNum = .'+IntToStr(i));
     if ( (pFieldHeader^.fieldType = ftBLOB) or
        (pFieldHeader^.fieldType = ftMemo) or
         (pFieldHeader^.fieldType = ftFmtMemo) or
        (pFieldHeader^.fieldType = ftGraphic)) then
      inc(fieldNum);
   end;
  // count header position
  pos := pos + fieldNum;

  n := blobHeaders.Headers[pos].numParts;
  if (n <= 0) then
    Exit;
//aaStartTime;
//ShowMessage(IntToStr());
  blobDelParts.AppendFrom(blobHeaders.Parts[pos],n);
 //aaStopTime;
  blobHeaders.ClearParts(pos);
  inc(blobFileHeader.numDeletedParts,n);
 finally
  UnlockSection;
 end;
end; //aaDeleteBLOBValue


//------------------------------------------------------------------------------
// read BLOB value for selected field (for current record)
//------------------------------------------------------------------------------
procedure TEasyDataManager.aaReadBLOBValue(
          bStream : TStream; // output stream
          fieldNo : integer; // field number 0-based
          physRecPos : Integer // physical position
                                  );
var i,k,n,c,bn,pos,offset,size,hSize,blockSize,
    fieldNum,tSize : Integer;
    buffer        : PAnsiChar;
    buffer1       : PAnsiChar;
    crypto        : TCipher_Rijndael; // for decoding
    check         : THash_CRC32; // for checking data
    s,s1          : string[12];
    pFieldHeader: pFieldHeaderType;
begin
 LockSection;
 try
  // if there is no records in table - exit
  if (blobFileHeader.recordCount <= 0)  then Exit;
  // count blob fieldNum (0,1,2,...,blobFileHeader.fieldCount-1)
  fieldNum := 0;
  for i := 0 to FieldNo-1 do
   begin
    pFieldHeader := pFieldHeaderType(fieldHeaderList.Items[i]);
 	  if (pFieldHeader = nil) then raise Exception.Create(
     'Error in TEasyDataManager.ReadBLOBValue - 0 pointer to pFieldHeader, fieldNum = .'+IntToStr(i));
    if ( (pFieldHeader^.fieldType = ftBLOB) or
        (pFieldHeader^.fieldType = ftMemo) or
        (pFieldHeader^.fieldType = ftFmtMemo) or
        (pFieldHeader^.fieldType = ftGraphic))
    then
     inc(fieldNum);
   end;


  if (bStream = nil) then raise Exception.Create(
     'Error in TEasyDataManager.aaReadBLOBValue - stream is not opened.');
  bStream.Size := 0;

  pos := blobMap.items[physRecPos];
  pos := pos + fieldNum;
  n := blobHeaders.headers[pos].numParts;


  if (n <= 0) then
   begin
    // there is no data in this field
    Exit;
   end;
 OpenFilesForDesigning;
 //aaStartTime;
  if (bufferLog.ItemCount > 0) then
   begin
    bufferLog.FlushBuffers;
    SaveBLOBHeadersToDisk;
   end;
 //aaStopTime;
 //aaStartTime;
  // loading blob data from blob data file
  hSize := blobHeaders.headers[pos].size;
  tSize := blobHeaders.headers[pos].trueSize;
  blockSize := blobFileHeader.blockSize;
  size := 0;
  for i := 0 to n - 1 do
   inc(size, blobHeaders.Parts[pos][i].blockCount);
  size := size * blockSize;
  buffer := AllocMem(size);
  if (buffer = nil) then raise Exception.Create(
     'Error in TEasyDataManager.aaReadBLOBValue - 0 pointer to buffer.');
  offset := 0;

 //aaStartTime;
  for i := 0 to n - 1 do
   begin
    bn := blobHeaders.Parts[pos][i].blockNumber * blockSize;
    c := blobHeaders.Parts[pos][i].blockCount * blockSize;
    BLOBDataFile.Seek(bn, soFromBeginning);
    BLOBDataFile.ReadBuffer(PAnsiChar(buffer+offset)^, c);
    inc(offset,c);
   end;

 //aaStopTime;
 //aaStartTime;
 // FreeMem(buffer);
 // bStream.Seek(0,soFromBeginning);
 // decryption
  if (FEncrypted) and (FPassword = '') then raise Exception.Create(
     'Error in TEasyDataManager.aaReadBLOBValue - no password specified.');
  if (FEncrypted) then
    begin
     // decode data
     try
      crypto := TCipher_Rijndael.Create(FPassword,nil);
      crypto.DecodeBuffer(buffer^,buffer^,hSize);
      crypto.free;
     except
      FreeMem(buffer);
      raise Exception.Create(
       'Error in TEasyDataManager.aaReadBLOBValue - decoding error.');
      Exit;
     end;
    end; // decoding finished

  // decompressing
  if (tableHeader.blobCompressed <> clNone) then
   begin
    // decompressing
    try
     k := tSize;

     if (tableHeader.version  < 2.2 - 0.001) and (tableHeader.blobCompressed = clFastest) then
      // old version
      begin
 //	     if (not aaDecompressBuffer(buffer,hSize,buffer1,k,clLZO)) then
   	    raise Exception.Create('Error in TEasyDataManager.aaReadBLOBValue - table version too old. Try to open it by EasyTable version 2.20');
      end
     else
      begin
  	     if (not aaDecompressBuffer(buffer,hSize,buffer1,k,tableHeader.blobCompressed)) then
	       raise Exception.Create('Error in TEasyDataManager.aaReadBLOBValue - aaDecompress decompressing error! mode = '+
          inttostr(integer(tableHeader.blobcompressed))+', k = '+inttostr(k)+
         ', tSize = '+inttostr(tsize)+', hSize = '+inttostr(hsize));
      end;


     if (k <> tSize) or (buffer1 = nil) then
       raise Exception.Create('Error in TEasyDataManager.aaReadBLOBValue - decompressing error! mode = '+
         inttostr(integer(tableHeader.blobcompressed))+', k = '+inttostr(k)+
         ', tSize = '+inttostr(tsize)+', hSize = '+inttostr(hsize));

    except
     if (buffer <> nil) then
      FreeMem(buffer);
     if (buffer1 <> nil) then
      FreeMem(buffer1);
     raise Exception.Create(
       'Error in TEasyDataManager.aaReadBLOBValue - decompressing error, mode='+
           inttostr(integer(tableHeader.blobCompressed))+'.');
     Exit;
    end; //try
    FreeMem(buffer);
    buffer := buffer1;
   end; // decompressing finished


  // writing decompressed and decrypted data to memory stream
 // bStream.size := tSize;
 // bStream.Seek(0,soFromBeginning);
  bStream.WriteBuffer(buffer^,tSize);
  bStream.Seek(0,soFromBeginning);

  // crc check
  s1 := blobHeaders.headers[pos].crc32;
  check := THash_CRC32.Create(nil);
  try
    s := check.CalcBuffer(buffer^,tSize,nil);
    for i := 1 to Length(s) do
      if ((ord(s[i]) xor ord(s1[i])) <> 0) then
       raise Exception.Create('Error in TEasyDataManager.aaReadBLOBValue - crc error');
  except
    FreeMem(buffer);
    raise Exception.Create('Error in TEasyDataManager.aaReadBLOBValue - crc error');
  end;
  check.Free;
  FreeMem(buffer);

 CloseFilesForDesigning;
 //aaStopTime;
  // crc check end;
 // ShowMessage(inttostr(blobFields[j].stream.size));
 finally
  UnlockSection;
 end;
end; //aaReadBLOBValue


//------------------------------------------------------------------------------
// write BLOB value for selected field (for current record)
//------------------------------------------------------------------------------
procedure TEasyDataManager.aaWriteBLOBValue(
          bStream : TStream; // input stream
          fieldNo : integer; // field number 0-based
          physRecPos : Integer // physical position
                                );
var n,i,pos,bc,bn,
    hSize,size,fieldNum,numDeletedParts,trueSize : Integer;
    numBlocks, blockCount, blockSize, newCount : Integer;
    newPart : TaaBLOBPart;
    buffer  : PAnsiChar;
    buffer1 : PAnsiChar;
    crypto       : TCipher_Rijndael; // for decoding
    check        : THash_CRC32; // for checking data
    s            : string[12]; // crc
    pFieldHeader: pFieldHeaderType;
begin
 LockSection;
 try
  if (blobFileHeader.recordCount <= 0)  then Exit;
  // count blob fieldNum (0,1,2,...,blobFileHeader.fieldCount-1)
  fieldNum := 0;
  for i := 0 to FieldNo-1 do
   begin
    pFieldHeader := pFieldHeaderType(fieldHeaderList.Items[i]);
 	  if (pFieldHeader = nil) then raise Exception.Create(
     'Error in TEasyDataManager.WriteBLOBValue - 0 pointer to pFieldHeader, fieldNum = .'+IntToStr(i));
    if ( (pFieldHeader^.fieldType = ftBLOB) or
         (pFieldHeader^.fieldType = ftMemo) or
        (pFieldHeader^.fieldType = ftFmtMemo) or
         (pFieldHeader^.fieldType = ftGraphic))
    then
     inc(fieldNum);
   end;

  if (bStream = nil) then raise Exception.Create(
     'Error in TEasyDataManager.aaWriteBLOBValue - stream is not opened.');
  trueSize := bStream.Size;
  if (trueSize <= 0) then
   begin
    // there is no data in this field - delete it
    aaDeleteBLOBValue(FieldNo, physRecPos);
    Exit;
   end;
  pos := blobMap.items[physRecPos];
  pos := pos + fieldNum;
  // crc check
 //aaStartTime;
  buffer := AllocMem(trueSize+blobFileHeader.blockSize);
 //aaStopTime;
  if (buffer = nil) then raise Exception.Create(
     'Error in TEasyDataManager.aaWriteBLOBValue - 0 pointer to buffer.');
 //aaStartTime;
  bStream.Seek(0,soFromBeginning);
  if (isStreamGraphic(bStream)) then
    begin
     bStream.Seek(8,soFromBeginning);
     trueSize := trueSize - 8;
     bStream.Read(buffer^,trueSize);
    end
  else
    bStream.Read(buffer^,trueSize);
  check := THash_CRC32.Create(nil);
  try
    s := check.CalcBuffer(buffer^,trueSize,nil);
  except
   FreeMem(buffer);
   raise Exception.Create(
     'Error in TEasyDataManager.aaWriteBLOBValue - crc calc error');
   Exit;
  end;
  check.Free;
  // compressing
  hSize := trueSize;
  if (tableHeader.blobCompressed <> clNone) then
   begin
    // compressing
    try
     if (not aaCompressBuffer(buffer,trueSize,buffer1,hSize,tableHeader.blobCompressed)) then
       raise Exception.Create('Error in TEasyDataManager.aaWriteBLOBValue - aaCompress compressing error! mode = '+
         inttostr(integer(tableHeader.blobcompressed))+
         ', tSize = '+inttostr(truesize)+', hSize = '+inttostr(hsize));
    except
     if (buffer <> nil) then
      FreeMem(buffer);
     if (buffer1 <> nil) then
      FreeMem(buffer1);
     raise Exception.Create(
       'Error in TEasyDataManager.aaReadBLOBValue - decompressing error, mode='+
           inttostr(integer(tableHeader.blobCompressed))+'.');
     Exit;
    end;
    FreeMem(buffer);
    buffer := buffer1;
   end; // compressing finished
 // encryption
  if (FEncrypted) and (FPassword = '') then raise Exception.Create(
     'Error in TEasyDataManager.aaWriteBLOBValue - no password specified.');
  if (FEncrypted) then
    begin
     // encode data
     try
      crypto := TCipher_Rijndael.Create(FPassword,nil);
      crypto.EncodeBuffer(buffer^,buffer^,hSize);
      crypto.free;
     except
      FreeMem(buffer);
      raise Exception.Create(
       'Error in TEasyDataManager.aaWriteBLOBValue - decoding error.');
      Exit;
     end;
    end; // encoding finished
  // set up variables
  blockSize := blobFileHeader.blockSize; // size of the block in bytes
  numBlocks := hSize div blockSize; //number of blocks for field value
  if (hSize mod blockSize) > 0 then
   inc(numBlocks); // last block
  size := numBlocks * blockSize;
 //aaStartTime;
  ReallocMem(buffer,size);
 //aaStopTime;
  numDeletedParts := blobFileHeader.numDeletedParts;
  // prepare new header
  blobHeaders.headers[pos].size := hSize;
  blobHeaders.headers[pos].trueSize := trueSize;
  blobHeaders.headers[pos].crc32 := s;
  if (numDeletedParts <= 0) then
   begin
    // if there is no deleted parts in index file
    // write to index file
 //aaStartTime;

    blobHeaders.headers[pos].numParts := 1;
    SetLength(blobHeaders.parts[pos],1);
 //   blobHeaders.parts[pos].SetSize(1);
 //   FreeMem(buffer);
 //   Exit;

    blobHeaders.parts[pos][0].blockNumber := blobHeaders.LastBlockNumber;
    blobHeaders.parts[pos][0].blockCount := numBlocks;
    inc(blobHeaders.LastBlockNumber, numBlocks);

    bufferLog.Append(roBLOBWrite,buffer,size,-1,false,blobHeaders.parts[pos],1);
    CheckBuffersOverflow;

    // write data to data file
 //aaStopTime;
    Exit;
   end;// if there is no deleted parts in index file
  // if there is deleted parts - fill them
  blobHeaders.Parts[pos] := nil;
  blockCount := 0;
  n := 0;
  i := numDeletedParts - 1;
  while i >= 0 do
   begin
    bc := blobDelParts.items[i].blockCount;
    bn := blobDelParts.items[i].blockNumber;
    if (blockCount+bc <= numBlocks) then
     begin
       // this part used without dividing
       SetLength(blobHeaders.Parts[pos],n+1);
       blobHeaders.Parts[pos][n] := blobDelParts.items[i];
       inc(blockCount,bc);
       blobDelParts.Delete(i);
       dec(numDeletedParts);
       dec(i);
       inc(n);
       if (blockCount = numBlocks) then break; // all ok
     end  // this part used without dividing
    else
     begin
      // this part used with dividing it
      // new part size and offset
      newCount := numBlocks-blockCount;
      newPart.blockNumber := bn;
      newPart.blockCount := newCount;
      SetLength(blobHeaders.Parts[pos],n+1);
      blobHeaders.Parts[pos][n] := newPart;
      // modify size and offset of deleted part
      blobDelParts.items[i].blockNumber := bn+newCount;
      blobDelParts.items[i].blockCount := bc - newCount;
      blockCount := numBlocks;
      inc(n);
      break; // all blocks defenitions added to newPart list
     end;// this part used with dividing it
   end; // while deleted parts
    // if more blocks needed
    if (blockCount < numBlocks) then
     begin
     // if new value greater then numdeletedparts
      newPart.blockCount := numBlocks-blockCount;
      newPart.blockNumber := blobHeaders.LastBlockNumber;
      inc(blobHeaders.LastBlockNumber, numBlocks - blockCount);
      SetLength(blobHeaders.Parts[pos],n+1);
      blobHeaders.Parts[pos][n] := newPart;
      inc(n);
     end;
   blobFileHeader.numDeletedParts := numDeletedParts;
   blobHeaders.headers[pos].numParts := n;

   bufferLog.Append(roBLOBWrite,buffer,size,-1,false,blobHeaders.parts[pos],n);
   CheckBuffersOverflow;
//aaStopTime;
 finally
  UnlockSection;
 end;
end; // aaWriteBLOBValue


//------------------------------------------------------------------------------
// returns number of indexBuffer element, which
// is equal to the record (indentified by position in buffer)
//------------------------------------------------------------------------------
function TEasyDataManager.aaFindIndexValue(indexNum : integer;
                              position : integer;
                              recordCount : Integer = -1
                              ) : integer;
var pos,l,h	: Integer;
    DMHandle : TEasyDataManager;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 LockSection;
 try
   cmpRecBuf_find :=  false; //?
  //aaStartTime;
   DMHandle := self;
   if (recordCount = -1) then
    recordCount := tableHeader.recordCount;
   findValIns_recordBuffer := allRecBuffer.GetRecordDataPtr(position);
   allRecBuffer.LockRecordPage(position);
   findValIns_array := aInteger(indexes[IndexNum].items);
   findValIns_pIndex := pIndexHeaderType(indexHeaderList.Items[IndexNum]);
   findValIns_recCount := recordCount;
   findValIns_ignoreCase := false;
   findValIns_partialCompare := false;
   findValIns_search := false;
   {$include find_ind.inc}
   allRecBuffer.UnlockRecordPage(position);
   pos := findValIns_result;
  //aaStopTime;
   // if pos corresponds specified record - return pos
   if (indexes[indexNum].items[pos] = position) then
    begin
     result := pos;
     Exit;
    end;
   l := pos-1;
   h := pos+1;
   while (h < recordCount) or (l >= 0) do
    begin
     if (l >= 0) then
       if (indexes[indexNum].items[l] = position) then
        begin
         result := l;
        //aaStopTime;
         Exit;
        end;
     if (h < recordCount) then
       if (indexes[indexNum].items[h] = position) then
        begin
         result := h;
        //aaStopTime;
         Exit;
        end;
     dec(l);
     inc(h);
    end;
   result := -1;
 finally
  UnlockSection;
 end;
end; //aaFindIndexValue


//------------------------------------------------------------------------------
// returns number of indexBuffer element, which
// is equal to the record (indentified by position in buffer)
//------------------------------------------------------------------------------
function TEasyDataManager.FindIndexValueForDelete(
                          indexBuffer : array of Integer; // index values
                          position		: Integer; // currentPosition
                          recordCount : Integer = -1;
                          doCheck     : Boolean = false // if false not found
                                      //raises exception, else returns -1
                          ) : Integer;
var i,recCount	: Integer;
    i1,i2: integer;
    bBreak: boolean;
begin
 LockSection;
 try
  //ShowMessage('find start');
   if (recordCount < 0) then
    recCount := tableHeader.recordCount
   else
    recCount := recordCount;
   result := -1;
   if (recCount > 0) then
    begin
     // dihotomy
     i1 := 0;
     i2 := recCount-1;
     bBreak := false;
     // acending order?
     if (indexBuffer[i1] < indexBuffer[i2]) then
       // ascending order
       repeat
        if (i1 = i2) then
         bBreak := true;
        i := (i1 + i2) div 2;
        if (indexBuffer[i] = position) then
         begin
          result := i;
          break;
         end
        else
         if (indexBuffer[i] < position) then
          if (i1 < i) then i1 := i
          else inc(i1)
         else
          if (i2 > i) then i2 := i
          else dec(i2);
       until bBreak
     else
       // descending order
       repeat
        if (i1 = i2) then
         bBreak := true;
        i := (i1 + i2) div 2;
        if (indexBuffer[i] = position) then
         begin
          result := i;
          break;
         end
        else
         if (indexBuffer[i] > position) then
          if (i1 < i) then i1 := i
          else inc(i1)
         else
          if (i2 > i) then i2 := i
          else dec(i2);
       until bBreak;
    end; // recCount > 0

    if ((result < 0) and (doCheck)) then
      raise Exception.Create(
      'Error in TEasyDataManager.FindIndexValueForDelete - indexValue not found, number = '
      +', position = '+IntToStr(position) +
      ', recordCount = '+IntToStr(recCount));
 finally
  UnlockSection;
 end;
end; //TEasyDataManager.FindIndexValueForDelete


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// The end of TEasyDataManager
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function EasyDataManagerWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
          stdcall;
{This function is called once for each window}
 Var MyString : PAnsiChar;
begin

    {Window text}
    MyString := Allocmem(255);
    GetWindowTextA(WHandle,MyString,255);
    TStringList(Parm).Add(MyString);
    FreeMem(MyString,255);
    Result := True; {Everything's okay. Continue to enumerate windows}
end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyMasterDataLink
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TEasyMasterDataLink.Create(DataSet: TEasyDataSet);
begin
   inherited Create;
   FDataSet:=DataSet;
   FFields:=TList.Create;
end;

destructor TEasyMasterDataLink.Destroy;
begin
   FFields.Free;
   inherited Destroy;
end;

procedure TEasyMasterDataLink.ActiveChanged;
begin
   FFields.Clear;
   if Active then
      begin
      try
         DataSet.GetFieldList(FFields,FFieldNames);
      except
         FFields.Clear;
         raise;
      end;
      end;
   if FDataSet.Active and (not (csDestroying in FDataSet.ComponentState)) then
      begin
      if Active and (FFields.Count > 0) then
         begin
         if Assigned(FOnMasterChange) then
            FOnMasterChange(Self);
         end
      else if Assigned(FOnMasterDisable) then
         FOnMasterDisable(Self);
      end;
end;

procedure TEasyMasterDataLink.CheckBrowseMode;
begin
   if FDataSet.Active then
      FDataSet.CheckBrowseMode;
end;

procedure TEasyMasterDataLink.LayoutChanged;
begin
   ActiveChanged;
end;

procedure TEasyMasterDataLink.RecordChanged(Field: TField);
begin
   if (DataSource.State <> dsSetKey) and FDataSet.Active and
      (FFields.Count > 0) and ((Field=nil) or
      (FFields.IndexOf(Field) >= 0)) and
      Assigned(FOnMasterChange) then
      FOnMasterChange(Self);
end;

procedure TEasyMasterDataLink.SetFieldNames(const Value: AnsiString);
begin
   if (FFieldNames <> Value) then
      begin
      FFieldNames:=Value;
      ActiveChanged;
      end;
end;



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyDataSet
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////




//------------------------------------------------------------------------------
// set table name property
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetTableName(value: AnsiString);
begin
//  FTableName := StripFileName(value);
  if csReading in ComponentState then
//    FTableName := StripFileName(value)
    FTableName := value // fixed to support names like 'dbo.systable'
//  else if (FTableName <> StripFileName(value)) then
  else if (FTableName <> value) then
  begin
    CheckInactive;
//    FTableName := StripFileName(value);
    FTableName := value;
    DataEvent(dePropertyChange, 0);
  end;
end;// SetTableName


//------------------------------------------------------------------------------
// get table name property
//------------------------------------------------------------------------------
function TEasyDataSet.GetTableName: AnsiString;
begin
 // - ext
 if (FTableName <> '') then
  Result := FTableName
 else
  result := '';
end;//GetTableName


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TEasyDataSet.ClearBLOBStreams;
var i: integer;
begin
 if (not DMHandle.isBLOBUsed) then
  Exit;
 for i := 0 to DMHandle.tableHeader.fieldCount-1 do
  if (blobFields[i].stream <> nil) then
   begin
    blobFields[i].stream.Free;
  	blobFields[i].stream := nil;
   end;
end;// ClearBLOBStreams


//------------------------------------------------------------------------------
// get file store mode (InMemory, ...)
//------------------------------------------------------------------------------
function TEasyDataSet.GetFileStoreMode: TaaFileStoreMode;
begin
 if (FTemporary) then
  result := fsmTemporary
 else
 if (FInMemory) then
  result := fsmInMemory
 else
  result := fsmDefault;
end;// GetFileStoreMode


//------------------------------------------------------------------------------
// check table state and update visible records if necessary
// (other dataset could modify records)
//------------------------------------------------------------------------------
procedure TEasyDataSet.CheckTableState;
begin
  DBSession.LockSession;
  try
   if (TableState <> DMHandle.tableHeader.state) then
    begin
     CreateVisibleRecordsList;
    end;
  finally
   DBSession.UnlockSession;
  end;
end;// CheckTableState


{$IFDEF D6H}


////////////////////////////////////////////////////////////////////////////////
//
// IProviderSupport
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetUpdateException
//------------------------------------------------------------------------------
function TEasyDataset.PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError;
begin
  Result := inherited PSGetUpdateException(E, Prev);
end; // PSGetUpdateException


//------------------------------------------------------------------------------
// IsSQLSupported
//------------------------------------------------------------------------------
function TEasyDataset.PSIsSQLSupported: Boolean;
begin
  {$IFDEF NAG_SCREEN}
  Result := False;
  {$ELSE}
  Result := True;
  {$ENDIF}
end; // PSIsSQLSupported


//------------------------------------------------------------------------------
// Reset
//------------------------------------------------------------------------------
procedure TEasyDataset.PSReset;
begin
  inherited PSReset;
end; // PSReset


//------------------------------------------------------------------------------
// UpdateRecord
//------------------------------------------------------------------------------
function TEasyDataset.PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean;
var
  UpdateAction: TUpdateAction;
begin
  Result := False;
  if Assigned(OnUpdateRecord) then
  begin
    UpdateAction := uaFail;
    if Assigned(FOnUpdateRecord) then
    begin
      FOnUpdateRecord(Delta, UpdateKind, UpdateAction);
      Result := UpdateAction = uaApplied;
    end;
  end;
end; // PSUpdateRecord


//------------------------------------------------------------------------------
// EndTransaction
//------------------------------------------------------------------------------
procedure TEasyDataset.PSEndTransaction(Commit: Boolean);
begin
;// DatabaseError('Transactions are not supported',Self);
end; // PSEndTransaction


{$IFDEF D21H}
function TEasyDataset.PSExecuteStatement(const ASQL: string; AParams: TParams): Integer;
begin
  Self.PSExecuteStatement(ASQL,AParams,nil);
end;


function TEasyDataset.PSExecuteStatement(const ASQL: string; AParams: TParams;
      var ResultSet: TDataSet): Integer;
var
  InProvider:   Boolean;
  ResultSetNil: Boolean;
begin
  SetDBFlag(dbfProvider, True);
  InProvider := dbfProvider in FDBFlags;
  ResultSetNil := (ResultSet = nil);
  try
{$IFNDEF FULL_VERSION}
   Result := 0;
{$ELSE}
    ResultSet := TEasyQuery.Create(nil);
    try
      TEasyQuery(ResultSet).InMemory := FInMemory;
      TEasyQuery(ResultSet).DatabaseName := FDatabaseName;
      TEasyQuery(ResultSet).DatabaseFileName := FDatabaseFileName;
      TEasyQuery(ResultSet).SessionName := FSessionName;
      TEasyQuery(ResultSet).SQL.Text := ASQL;
      TEasyQuery(ResultSet).FParams.Assign(AParams);
      TEasyQuery(ResultSet).ExecSQL;
      Result := TEasyQuery(ResultSet).RowsAffected;
    finally
      if (ResultSetNil) then
       begin
        TEasyQuery(ResultSet).Free;
        ResultSet := nil;
       end;
    end;
{$ENDIF}
  finally
    SetDBFlag(dbfProvider, InProvider);
  end;
end; // PSExecuteStatement
{$ELSE}
//------------------------------------------------------------------------------
// ExecuteStatemnt
//------------------------------------------------------------------------------
function TEasyDataset.PSExecuteStatement(const ASQL: String; AParams: TParams;
  ResultSet: Pointer = nil): Integer;
var
  InProvider:   Boolean;
  ResultSetNil: Boolean;
begin
  SetDBFlag(dbfProvider, True);
  InProvider := dbfProvider in FDBFlags;
  ResultSetNil := (ResultSet = nil);
  try
{$IFNDEF FULL_VERSION}
   Result := 0;
{$ELSE}
    ResultSet := TEasyQuery.Create(nil);
    try
      TEasyQuery(ResultSet).InMemory := FInMemory;
      TEasyQuery(ResultSet).DatabaseName := FDatabaseName;
      TEasyQuery(ResultSet).DatabaseFileName := FDatabaseFileName;
      TEasyQuery(ResultSet).SessionName := FSessionName;
      TEasyQuery(ResultSet).SQL.Text := ASQL;
      TEasyQuery(ResultSet).FParams.Assign(AParams);
      TEasyQuery(ResultSet).ExecSQL;
      Result := TEasyQuery(ResultSet).RowsAffected;
    finally
      if (ResultSetNil) then
       begin
        TEasyQuery(ResultSet).Free;
        ResultSet := nil;
       end;
    end;
{$ENDIF}
  finally
    SetDBFlag(dbfProvider, InProvider);
  end;
end; // PSExecuteStatement
{$ENDIF}


//------------------------------------------------------------------------------
// GetAttributes
//------------------------------------------------------------------------------
procedure TEasyDataset.PSGetAttributes(List: TList);
begin
  inherited PSGetAttributes(List);
end; // PSGetAttributes


//------------------------------------------------------------------------------
// GetQuoteAnsiChar
//------------------------------------------------------------------------------
function TEasyDataset.PSGetQuoteChar: String;
begin
  Result := '''';
end; // PSGetQuoteAnsiChar


//------------------------------------------------------------------------------
// InTransaction
//------------------------------------------------------------------------------
function TEasyDataset.PSInTransaction: Boolean;
begin
  Result := False;
end; // PSInTransaction


//------------------------------------------------------------------------------
// IsSQLBased
//------------------------------------------------------------------------------
function TEasyDataset.PSIsSQLBased: Boolean;
begin
  {$IFDEF NAG_SCREEN}
  Result := False;
  {$ELSE}
  Result := True;
  {$ENDIF}
end; // PSIsSQLBased


//------------------------------------------------------------------------------
// StartTransaction
//------------------------------------------------------------------------------
procedure TEasyDataset.PSStartTransaction;
begin
;
end; // PSStartTransaction


{$ENDIF}


//------------------------------------------------------------------------------
// strip file name - remove file extension
//------------------------------------------------------------------------------
function TEasyDataSet.StripFileName(FileName: AnsiString): AnsiString;
var i: integer;
begin
 // - ext
   i := Length(FileName);
   while (i > 0) do
    begin
     if (FileName[i] = '.') then break;
     dec(i);
    end;
   if (i > 0) then
     Result := Copy(FileName,0,i-1)
    else
     Result := FileName;
end;// StripfileName


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalCreateTable;
var i: integer;
begin
 DBSession.LockSession;
 try
   if (Active) then
    Raise Exception.Create('TEasyDataSet.InternalCreateTable - Cannot perform this operation on an open DataSet.');

   DMHandle := nil;

   if (FInMemory) and (FDatabaseName = '') and (FDatabaseFileName = '') then
    FDatabaseName := 'MEMORY';

   // if neither file nor directory - set file
   if (FDatabaseName = '') and (FDatabaseFileName = '') then
      FDatabaseFileName := GetDBName;


   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   try
     // if ESFS and database not found then create ESFS file
     if (FDatabaseFileName <> '') then
      if (not DBMHandle.Exists) then
      if not (FInMemory and not DBMHandle.InMemory) then
        DBMHandle.CreateDatabase;
     // get handle to data manager (find or create)
     DMHandle := aaGetDataManager(FTableName, DBMHandle);
     if (DMHandle.GetDataSetCount > 0) then
      Raise Exception.Create('TEasyDataSet.InternalCreateTable - Table is busy, table '+TableName);
     if (Exists) then
      begin
       InternalDeleteTable;
       // get handle to data manager (find or create)
       DMHandle := aaGetDataManager(FTableName, DBMHandle);
      end;
       // set params
       DMHandle.FBlobCompression := FBLOBCompression;
       if (FBlobBlockSize <= 0) then
        Raise Exception.Create('TEasyDataSet.InternalCreateTable - BlobBlockSize must be > 0');

       DMHandle.FBLOBBlockSize := FBLOBBlockSize;
       DMHandle.FEncrypted := FEncrypted;
       DMHandle.FPassword := FPassword;
       DMHandle.FFileStoreMode := GetFileStoreMode;
      // adding fields, specified by editor
       for i := 0 to Fields.Count - 1 do
         with Fields[i] do
          if FieldKind in [fkData] then
           if (not FindFieldInSourceTable(FieldDefs,FieldName)) then
            FieldDefs.Add(FieldName,DataType,Size,Required);
       try
        DMHandle.CreateTable(FieldDefs,IndexDefs, FAutoIndexes, PageRecordCount);
       finally
        DMHandle.Free;
        DMHandle := nil;
       end;
     finally
      SetDBFlag(dbfTable, False);
     end;
  finally
    DBSession.UnlockSession;
  end;
end; // InternalCreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalDeleteTable;
begin
 DBSession.LockSession;
 try
   if (Active) then
    Raise Exception.Create('Error in TEasyDataset.InternalDeleteTable - table is opened.');
   DMHandle := nil;

   // get handle to database manager (find or create)
   SetDBFlag(dbfDeleteTable, True);
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (not FTemporary) then
    if (DMHandle.GetDataSetCount > 0) then
     raise Exception.Create('TEasyDataSet.InternalDeleteTable - Table is busy, table '+TableName);
   if (FTemporary) then
    DMHandle.FFileStoreMode := fsmTemporary
   else
   if (FInMemory) then
    DMHandle.FFileStoreMode := fsmInMemory
   else
    DMHandle.FFileStoreMode := fsmDefault;
   DMHandle.DeleteTable;
   DMHandle.Destroy;
   DMHandle := nil;
 finally
   SetDBFlag(dbfDeleteTable, False);
   DBSession.UnlockSession;
 end;
end; // InternalDeleteTable


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalEmptyTable;
var a : Boolean;
begin
 DBSession.LockSession;
 try
   a := Active;
   if (Active) then
    Active := false;
  //  Raise Exception.Create('Error in TEasyDataset.InternalEmptyTable - table is opened.');
   DMHandle := nil;

   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (DMHandle.GetDataSetCount > 0) then
      Raise Exception.Create('TEasyDataSet.InternalEmptyTable - Table is busy, table '+TableName);
   if (FTemporary) then
      DMHandle.FFileStoreMode := fsmTemporary
   else
     if (FInMemory) then
      DMHandle.FFileStoreMode := fsmInMemory
     else
      DMHandle.FFileStoreMode := fsmDefault;
   DMHandle.FBlobCompression := FBLOBCompression;
   DMHandle.FBLOBBlockSize := FBLOBBlockSize;
   DMHandle.FEncrypted := FEncrypted;
   DMHandle.FPassword := FPassword;
   DMHandle.EmptyTable;
   DMHandle.Destroy;
   DMHandle := nil;
 finally
   SetDBFlag(dbfTable, False);
   DBSession.UnlockSession;
 end;
 Active := a;
end;  //InternalEmptyTable;


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalRenameTable(const NewTableName : AnsiString; IgnoreDatasetCount: Boolean = False);
begin
 DBSession.LockSession;
 try
   if (Active) then
    Raise Exception.Create('Error in TEasyDataset.InternalRenameTable - table is opened.');
   DMHandle := nil;
   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (not IgnoreDatasetCount) then
    if (DMHandle.GetDataSetCount > 0) then
     Raise Exception.Create('TEasyDataSet.InternalRenameTable - Table is busy, table '+TableName);
   if (FTemporary) then
    DMHandle.FFileStoreMode := fsmTemporary
   else
   if (FInMemory) then
    DMHandle.FFileStoreMode := fsmInMemory
   else
    DMHandle.FFileStoreMode := fsmDefault;
   DMHandle.RenameTable(NewTableName);
   DMHandle.Destroy;
   DMHandle := nil;
 finally
  SetDBFlag(dbfTable, False);
  DBSession.UnlockSession;
 end;
 FTableName := NewTableName;
end; // InternalRenameTable


//------------------------------------------------------------------------------
// save table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalSaveTable;
begin
 if (not Active) then
  Raise Exception.Create('TEasyDataset.InternalSaveTable - table is not opened.');
 if (not InMemory) then
  Raise Exception.Create('TEasyDataset.InternalSaveTable - table is not in in-memory mode.');
 DBSession.LockSession;
 try
  DMHandle.SaveTable;
 finally
  DBSession.UnlockSession;
 end;
end;// TEasyDataSet.InternalSaveTable;


//------------------------------------------------------------------------------
// copy table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalCopyTable(const NewTableName: AnsiString; const NewDatabaseName: AnsiString = '');
begin
 DBSession.LockSession;
 try
   if (LowerCase(NewTableName) = LowerCase(FTableName)) and (LowerCase(NewDatabaseName) = LowerCase(GetDBName)) then
    Exit;
   if (Active) then
    Raise Exception.Create('Error in TEasyDataset.InternalCopyTable - table is opened.');
   DMHandle := nil;

   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (DMHandle.GetDataSetCount > 0) then
    Raise Exception.Create('TEasyDataSet.InternalCopyTable - Table is busy, table '+TableName);
   if (FTemporary) then
    DMHandle.FFileStoreMode := fsmTemporary
   else
   if (FInMemory) then
    DMHandle.FFileStoreMode := fsmInMemory
   else
    DMHandle.FFileStoreMode := fsmDefault;
   DMHandle.CopyTable(StripFileName(NewTableName),NewDatabaseName);
   DMHandle.Destroy;
   DMHandle := nil;
 finally
   SetDBFlag(dbfTable, False);
   DBSession.UnlockSession;
 end;
end; //InternalCopyTable


//------------------------------------------------------------------------------
// Append/update records from another table
//------------------------------------------------------------------------------
function TEasyDataset.InternalAddRecords(
                         Dataset: TDataSet;
                         Mode: TAddRecordsMode;
                         var Log : AnsiString) : Boolean;
var i,k:  integer;
    name: AnsiString;
    fType                     : TFieldType;
    Stream1, Stream2          : TStream;
    autoincName1, autoincName2: AnsiString;
    autoincValue, oldAutoincValue: Integer;
    bDuplicated:              Boolean;
begin
 if (not Active) then
  Raise Exception.Create('Error in TEasyDataset.InternalAddRecords - table is not opened.');
 log := '';
 result := true;

// DBSession.LockSession;
 try
   // search for autoinc
   autoincName1 := '';
   for i:=0 to dataset.FieldCount-1 do
    if (dataset.fields[i].DataType = ftAutoInc) then
     begin
      autoincName1 := dataset.fields[i].FieldName;
      break;
     end;

   if ((autoincName1 = '') and ((Mode = arUpdate) or (Mode = arAppendUpdate))) then
    raise Exception.Create('TEasyDataset.InternalAddRecords - AutoInc field in source dataset not found. Use arReplace or arAppend mode');

   autoincName2 := '';
   for i:=0 to self.FieldCount-1 do
    if (self.fields[i].DataType = ftAutoInc) then
     begin
      autoincName2 := self.fields[i].FieldName;
      break;
     end;
   oldAutoIncValue := LastAutoIncValue;

   // if replace all records - empty table
   if (mode = arReplace) then
    InternalEmptyTable;

   // transfering data to the table
   dataset.First;
   FProgressProcess := aappAddingRecords;
   FProgress := 0;
   FProgressMax := dataset.RecordCount;
   if (FProgressMax = 0) then
    FProgressMax := 0.000001;
   while not dataset.Eof do
    begin
     try
      DoOnProgress(FProgress);
      bDuplicated := False;
      if (((Mode = arUpdate) or (Mode = arAppendUpdate)) and (autoincName1 <> '')) then
       begin
        // check for existence
        bDuplicated := self.Locate(autoincName2, dataset.FieldByName(autoincName1).Value, []);
        if (bDuplicated) then
         Edit
        else
         if ((Mode = arUpdate) or (autoincName1 = '')) then
         begin
          FProgress := FProgress + 100.0 / FProgressMax;
          dataset.Next;
          continue;
         end;
       end;
      if (self.State <> dsEdit) then
        Insert;
      for k := 0 to dataset.FieldCount-1 do
       begin
        if (k >= Self.FieldCount) then
         break;
        name := dataset.Fields[k].FieldName;
        if (FieldDefs.IndexOf(name) = -1) then
         continue;
        if (dataset.Fields[k].IsNull) then
         begin
          Self.Fields[k].Clear;
          continue;
         end;
         fType := FieldByName(name).DataType;
         case fType of
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt :
              FieldByName(name).AsInteger :=
                  dataset.Fields[k].AsInteger;
          ftString,
          ftFixedChar :
              FieldByName(name).AsString :=
                  dataset.Fields[k].AsString;
          ftWideString:
             {$IFDEF D5H}
              TWideStringField(FieldByName(name)).Value :=
                  TWideStringField(dataset.Fields[k]).Value;
              {$ELSE}
              FieldByName(name).AsString :=
                  dataset.Fields[k].AsString;
              {$ENDIF}
          ftFloat,
          ftBCD,
          ftCurrency :
              FieldByName(name).AsFloat :=
                  dataset.Fields[k].AsFloat;
          ftBoolean :
              FieldByName(name).AsBoolean :=
                  dataset.Fields[k].AsBoolean;
          ftDate,
          ftTime,
          ftDateTime :
              FieldByName(name).AsDateTime :=
                  dataset.Fields[k].AsDateTime;
          ftBLOB,
          ftMemo,
          ftFmtMemo,
          ftGraphic :
             if ((dataset.Fields[k].DataType = fType) or
                 (dataset.Fields[k].DataType = ftMemo) or
                 (dataset.Fields[k].DataType = ftFmtMemo) or
                 (dataset.Fields[k].DataType = ftGraphic)) then
              begin
               Stream1 := dataset.CreateBlobStream(dataset.Fields[k],bmRead);
               Stream2 := CreateBlobStream(
                          FieldByName(name),bmWrite);
               Stream2.CopyFrom(Stream1,Stream1.Size);
               Stream1.Free;
               Stream2.Free;
              end;
         end;
       end; // for fields
      if (autoincName1 <> '') then
       begin
        if ((not bDuplicated) and (Mode <> arAppend)) then
         begin
          autoincValue := dataset.FieldByName(autoincName1).AsInteger;
          oldAutoIncValue := LastAutoIncValue;
          SetAutoincValue(autoincValue);
          AutoincChangeEnabled := True;
          FieldByName(autoincName2).AsInteger := autoincValue;
          AutoincChangeEnabled := False;
         end;
       end;
      Post;
      if (LastAutoIncValue < oldAutoIncValue) then
        SetAutoincValue(OldAutoincValue+1);

      FProgress := FProgress + 100.0 / FProgressMax;
     except
      on E: Exception do
       begin
        if ((State = dsEdit) or (State = dsInsert)) then
         Cancel;
        result := false;
        log := log +'Adding records error, record number = '+
               inttostr(dataset.recNo)+' '+E.Message+#13#10;
       end;
     end;
     dataset.Next;
    end;

   // save Last Autoinc
   DMHandle.FlushBuffers;

   DoOnProgress(100.0);
 finally
//  DBSession.UnlockSession;
 end;
end;// InternalAddRecords


//------------------------------------------------------------------------------
// imports table to Easy format (current table will
// be replaced with imported table)
// returns true, if import was successful, log = ''
// if some errors occured, the error message will be stored
// in log variable
// if source table has no IndexDefs property
// you should pass nil to IndexDefinitions
//------------------------------------------------------------------------------
function TEasyDataset.InternalImportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         var log : AnsiString) : Boolean;
var i,j,k,size              : integer;
    name,fields,desc,case_ins : AnsiString;
    required                  : Boolean;
    fType                     : TFieldType;
    iOpt                      : TIndexOptions;
    Stream1, Stream2          : TStream;
    sourceDataSet             : TDataSet;
    indexDefsExists           : Boolean;
    autoincName               : AnsiString;
    autoincValue              : Integer;
    SkippedFields: TStringList;
    bSkipIndex: Boolean;
begin
 DBSession.LockSession;
 Result := false;
 try
   if (Active) then
    Raise Exception.Create('Error in TEasyDataset.InternalImportTable - table is opened.');
   DMHandle := nil;

   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (DMHandle.GetDataSetCount > 0) then
    Raise Exception.Create('TEasyDataSet.InternalImportTable - Table is busy, table '+TableName);
   log := '';
   result := true;
   if (indexDefinitions = nil) then
    indexDefsExists := false
   else
    indexDefsExists := true;
   if (dataSource = nil)  then raise Exception.Create(
      'Error in TEasyDataset.ImportTable - dataSource 0 pointer.');
   if (dataSource.dataSet = nil)  then raise Exception.Create(
      'Error in TEasyDataset.ImportTable - dataSet 0 pointer.');
   if (dataSource.dataSet.FieldDefs = nil)  then raise Exception.Create(
      'Error in TEasyDataset.ImportTable - dataSet.FieldDefs 0 pointer.');
   sourceDataSet := dataSource.dataSet;
   Active := false;
   // start importing
   // import table structure
   FieldDefs.Clear;
   IndexDefs.Clear;
   autoincName := '';

   SkippedFields := TStringList.Create;
   try
     // translating field definitions
     for i := 0 to sourceDataSet.FieldDefs.Count - 1 do
      begin
       // translating field definitions
       fType := sourceDataSet.FieldDefs.Items[i].DataType;
       name := sourceDataSet.FieldDefs.Items[i].Name;
       if (Length(name) > (MAX_NAME_LENGTH-2)) then
        begin
         result := false;
         name := Copy(name, 1,(MAX_NAME_LENGTH-2));
         log := log + 'Field name longer than '+IntToStr(MAX_NAME_LENGTH-2)+
           ' chars is not supported! FieldName = '+name+' is truncated.'+#13#10;
        end;
       size := sourceDataSet.FieldDefs.Items[i].Size;
       required := sourceDataSet.FieldDefs.Items[i].Required;
       // checking types
        case fType of
          ftDate,
          ftTime,
          ftDateTime :
              size := 0;
          ftInteger ,
          ftWord ,
          ftSmallInt ,
          ftLargeInt ,
          ftBoolean :
              size := 0;
          ftBCD:
             begin
              fType := ftFloat;
              size := 0;
             end;
          ftBLOB, ftMemo, ftFmtMemo, ftGraphic :
              size := 0;
          ftParadoxOle, ftDBaseOle, ftTypedBinary :
             begin
              fType := ftBLOB;
              size := 0;
             end;
          ftFixedChar, ftString:
            fType := ftString;
          ftWideString:
            fType := ftWideString;
          ftAutoInc :
            begin
    //          fType := ftInteger;
              fType := ftAutoInc;
              size := 0;
              autoincName := name;
    {          if (not isPrimaryKeySet) then
               begin
                autoincName := name;
                IndexDefs.Add(name,name,[ixPrimary]);
                isPrimaryKeySet := true;
               end;
    }
            end;
           else
            begin
            // check if field type supported
             if (not isFieldTypeSupported(fType)) then
              begin
               result := false;
  //             if (size > 0) then
                begin
                 SkippedFields.Add(name);
                 log := log + 'Field type not supported! FieldName = '+name+'. Field skipped.'+#13#10;
                 fType := ftUnknown; // replace to string
                end
  {             else
                begin
                 log := log + 'Field type not supported! FieldName = '+name+'. Field type will be replaced to ftLargeInt.'+#13#10;
                 fType := ftLargeInt; // replace to string
                end;}
              end;
            end;// end of check for supportied type
         end; //case fieldType
       if (fType <> ftUnknown) then
        FieldDefs.Add(name,fType,size,required);
      end; //for fieldDefs
     // detect primary key
    { f := -1;
     if (indexDefsExists) and (not isPrimaryKeySet) then
     begin
      for i := 0 to IndexDefinitions.Count-1 do
       if (ixPrimary in IndexDefinitions.Items[i].options) then
        begin
         f := i;
         break;
        end;
      if (f >= 0) then
       begin
        isPrimaryKeySet := true;
        fields := IndexDefinitions.Items[f].Fields;
        list := TStringList.Create;
        if (GetStringParams(fields,list) > 0) then
         name := list.Strings[0]
        else
         name := IndexDefinitions.Items[f].Name;
        list.Free;
        IndexDefs.Add(name,name,[ixPrimary]);
       end;
      end; //if indexdefs exists

     // making primary key
     if (not isPrimaryKeySet) then
      begin
       k := 0;
       while FindFieldInSourceTable(sourceDataSet.FieldDefs,'ID'+inttostr(k)) do
        inc(k);
       FieldDefs.Add('ID'+inttostr(k),ftInteger,0,false);
       IndexDefs.Add('ID'+inttostr(k),'ID'+inttostr(k),[ixPrimary]);
      end;
      }

    // all fields skipped?
    if (SkippedFields.Count = sourceDataSet.FieldDefs.Count) then
     begin
      log := log + 'All fields in table were skipped, so table is also skipped.'+#13#10;
      raise Exception.Create('Cannot create table without fields');
     end;

     // index definitions
    if (indexDefsExists) then
     for i := 0 to IndexDefinitions.Count-1 do
      begin
       iOpt := [];
       if (ixPrimary in IndexDefinitions.Items[i].Options) then
        iOpt := iOpt + [ixPrimary];
       if (ixUnique in IndexDefinitions.Items[i].Options) then
        iOpt := iOpt + [ixUnique];
       if (ixDescending in IndexDefinitions.Items[i].Options) then
        iOpt := iOpt + [ixDescending];
       if (ixCaseInsensitive in IndexDefinitions.Items[i].Options) then
        iOpt := iOpt + [ixCaseInsensitive];
       fields := IndexDefinitions.Items[i].Fields;
       name := IndexDefinitions.Items[i].Name;
       if (name = '') then continue;

       // check whether index contains skipped fields
       bSkipIndex := False;
       for j := 0 to SkippedFields.Count-1 do
        if (Pos(LowerCase(SkippedFields.Strings[j]), LowerCase(fields)) <> 0) then
         begin
           log := log + 'Index contains skipped field! IndexName = '+name+'. Index skipped.'+#13#10;
           bSkipIndex := True;
           break;
         end;
       if (bSkipIndex) then
        continue;

        // add index definition
       IndexDefs.Add(name,fields,iOpt);
       // set desc, case_ins, options
       desc := IndexDefinitions.Items[i].DescFields;
       case_ins := IndexDefinitions.Items[i].CaseInsFields;
       IndexDefs.Items[IndexDefs.Count-1].DescFields := desc;
       IndexDefs.Items[IndexDefs.Count-1].CaseInsFields := case_ins;
       IndexDefs.Items[IndexDefs.Count-1].Options := iOpt;
      end; // for index definitions
     // try to create table
     try
      InternalCreateTable;
     except
      result := false;
      log := log +#13#10+'Table cannot be created!';
      exit;
     end;
     // try to open table
     try
      Active := true;
     except
      result := false;
      log := log +#13#10+'Table cannot be opened!';
      exit;
     end;

     // importing data to new table
     // inserting records
     sourceDataSet.First;
     for k := 0 to sourceDataSet.FieldCount-1 do
      begin
       if (sourceDataSet.Fields[k].DataType <> ftBLOB) and
          (sourceDataSet.Fields[k].DataType <> ftMemo) and
          (sourceDataSet.Fields[k].DataType <> ftGraphic) and
          (sourceDataSet.Fields[k].DataType <> ftFmtMemo) and
          (sourceDataSet.Fields[k].DataType <> ftParadoxOle) and
          (sourceDataSet.Fields[k].DataType <> ftDBaseOle) and
          (sourceDataSet.Fields[k].DataType <> ftTypedBinary) then
         continue;
       name := sourceDataSet.Fields[k].FieldName;
       Stream1 := sourceDataSet.CreateBlobStream(sourceDataSet.Fields[k],bmRead);
       if (isStreamGraphic(stream1)) then
        begin
         j := DMHandle.InternalGetFieldNo(name);
         pFieldHeaderType(DMHandle.fieldHeaderList.Items[j])^.FieldType := ftGraphic;
        end;
       Stream1.Free;
      end;
     DMHandle.SaveTableHeaders;
     Active := False;
     Active := True;
     FProgressProcess := aappImport;
     FProgress := 0;
     FProgressMax := sourceDataSet.RecordCount;
     if (FProgressMax = 0) then
      FProgressMax := 0.000001;
     sourceDataSet.First;
     while not sourceDataSet.Eof do
      begin
       try
        DoOnProgress(FProgress);
        Insert;
        for k := 0 to sourceDataSet.FieldCount-1 do
         begin
          name := sourceDataSet.Fields[k].FieldName;
          if (not FindFieldInSourceTable(FieldDefs,name)) then
           continue;
          if (sourceDataSet.Fields[k].IsNull) then
           continue;
           fType := FieldByName(name).DataType;

           case fType of
            ftAutoInc:
                begin
                 AutoIncChangeEnabled := True;
                 try
                  FieldByName(name).AsInteger :=
                      sourceDataSet.Fields[k].AsInteger;
                 finally
                  AutoIncChangeEnabled := False;
                 end;
                end;
            ftInteger,
            ftSmallInt,
            ftWord,
            ftLargeInt :
                FieldByName(name).AsInteger :=
                    sourceDataSet.Fields[k].AsInteger;
            ftWideString:
              FieldByName(name).Assign(sourceDataSet.Fields[k]);
            ftString,
            ftFixedChar :
                FieldByName(name).AsString :=
                    sourceDataSet.Fields[k].AsString;
            ftFloat,
            ftBCD,
            ftCurrency :
                FieldByName(name).AsFloat :=
                    sourceDataSet.Fields[k].AsFloat;
            ftBoolean :
                FieldByName(name).AsBoolean :=
                    sourceDataSet.Fields[k].AsBoolean;
            ftDate,
            ftTime,
            ftDateTime :
                FieldByName(name).AsDateTime :=
                    sourceDataSet.Fields[k].AsDateTime;
            ftBytes:
                FieldByName(name).Value :=
                    sourceDataSet.Fields[k].Value;
            ftBLOB,
            ftMemo,
            ftFmtMemo,
            ftGraphic :
                begin
                 if (sourceDataSet.Fields[k].DataType in
                     [ftBLOB, ftMemo, ftFmtMemo, ftGraphic]) then
                  begin
                   Stream1 := sourceDataSet.CreateBlobStream(sourceDataSet.Fields[k],bmRead);
                   Stream2 := CreateBlobStream(
                              FieldByName(name),bmWrite);
                   Stream2.CopyFrom(Stream1,Stream1.Size);
                   Stream1.Free;
                   Stream2.Free;
                  end;
                end;
    //        else
    //            FieldByName(name).AsDateTime :=
    //                sourceDataSet.Fields[k].AsDateTime;
           end;
         end; // for fields
        if (autoincName <> '') then
         begin
          autoincValue := sourceDataSet.FieldByName(autoincName).AsInteger;
          SetAutoincValue(autoincValue);
         end;
        Post;
        FProgress := FProgress + 100.0 / FProgressMax;
       except
        result := false;
        log := log +'Insert records error, record number = !'+
              inttostr(sourceDataSet.recNo)+#13#10;
        // try to save changes
        try
         Post;
        except
         Cancel;
        end;
       end;
       sourceDataSet.Next;
      end;
     DoOnProgress(100.0);
  finally
   SkippedFields.Free;
  end;
 finally
   SetDBFlag(dbfTable, False);
   DBSession.UnlockSession;
 end;
end; //ImportTable


//------------------------------------------------------------------------------
// exports table from Easy format to any other table or dataset
// returns true, if export was successful, log = ''
// if some errors occured, the error message will be stored
// in log variable
// if source table has no IndexDefs property
// you should pass nil to IndexDefinitions
// createTablePtr - pointer to CreateTableMethod,
// if the destination table or its analog has no CreateTable you
// should pass pointer to function, which create table with specified struct
// (IndexDefs and FieldDefs)
//------------------------------------------------------------------------------
function TEasyDataset.InternalExportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         createTablePtr : TProcedure;
                         var log : AnsiString;
                         ToParadox: Boolean=False) : Boolean;

var i,k,size,n,max_f,autoinc_f  : integer;
    name,fields,desc,case_ins   : AnsiString;
    autoinc_name                : AnsiString;
    required,act,pkExists       : Boolean;
    fType                       : TFieldType;
    iOpt                        : TIndexOptions;
    Stream1, Stream2            : TStream;
    destinationDataSet          : TDataSet;
    indexDefsExists             : Boolean;
begin
 DBSession.LockSession;
 try
   act := Active;
   if (not isTableOpened) then
    Active := true;
   log := '';
   result := true;
   if (indexDefinitions = nil) then
    indexDefsExists := false
   else
    indexDefsExists := true;
   if (dataSource = nil)  then raise Exception.Create(
      'Error in TEasyDataset.ExportTable - dataSource 0 pointer.');
   if (dataSource.dataSet = nil)  then raise Exception.Create(
      'Error in TEasyDataset.ExportTable - dataSet 0 pointer.');
   if (dataSource.dataSet.FieldDefs = nil)  then raise Exception.Create(
      'Error in TEasyDataset.ExportTable - dataSet.FieldDefs 0 pointer.');
   destinationDataSet := dataSource.dataSet;
   destinationDataSet.Active := false;
   destinationDataSet.FieldDefs.Clear;
   // start importing
  //primary key
   autoinc_f := -1;
{
   fType := FieldDefs.Items[i].DataType;
   name := FieldDefs.Items[i].Name;
   size := FieldDefs.Items[i].Size;
   required := FieldDefs.Items[i].Required;
   destinationDataSet.FieldDefs.Add(name,fType,size,required);
}
   max_f := FieldDefs.Count - 1;
   for i := 0 to max_f do
     if (fType = ftAutoinc) then
      begin
       autoinc_f := i;
       break;
      end;
   if (ToParadox and indexDefsExists) then
    begin
     if (autoinc_f <= 0) then
      begin
        autoinc_name := 'id';
        while (destinationDataSet.FieldDefs.IndexOf(name) >= 0) do
         autoinc_name := GetTemporaryName('id');
        destinationDataSet.FieldDefs.Add(autoinc_name,ftAutoInc,0,True);
       end
      else
       autoinc_name := FieldDefs[autoinc_f].Name;
    end;
   // export table structure
   for i := 0 to max_f do
    begin
     // translating field definitions
     fType := FieldDefs.Items[i].DataType;
     name := FieldDefs.Items[i].Name;
     size := FieldDefs.Items[i].Size;
     required := FieldDefs.Items[i].Required;
     destinationDataSet.FieldDefs.Add(name,fType,size,required);
    end; //for fieldDefs


    // translating field definitions
  //indexDefsExists:= false;
   // index definitions
  if (indexDefsExists) then
  begin
   IndexDefinitions.Clear;

   pkExists := false;
   for i := 0 to IndexDefs.Count-1 do
    if (ixPrimary in IndexDefs.Items[i].Options) then
     pkExists := true;
   if (ToParadox and (not pkExists)) then
      IndexDefinitions.Add('',autoinc_name,[ixPrimary]);
   for i := 0 to IndexDefs.Count-1 do
    begin
     // auto DMHandle.indexes will be skipped
     name := IndexDefs.Items[i].Name;
     if (name[1] = '@') then
      continue;
     iOpt := IndexDefs.Items[i].Options;
     fields := IndexDefs.Items[i].Fields;
     // case-sensitive secondary index on one field
     // rename to the name of field in Paradox
     if (ToParadox and
         (not (ixCaseInsensitive in iOpt)) and
         (iOpt = []) and
         (Pos(',',fields)=0) and (Pos(';',fields)=0)) then
      begin
       if (indexDefinitions.IndexOf(fields) < 0) then
        name := fields
       else
        begin
         n := 0;
         repeat
          name := fields+IntToStr(n);
          Inc(n);
         until (indexDefinitions.IndexOf(name) < 0);
        end;
      end;
     if (ToParadox and (ixPrimary in iOpt)) then
      name := '';
      // add index definition
     IndexDefinitions.Add(name,fields,iOpt);
     // set desc, case_ins, options
     desc := IndexDefs.Items[i].DescFields;
     case_ins := IndexDefs.Items[i].CaseInsFields;
     IndexDefinitions.Items[IndexDefinitions.Count-1].DescFields := desc;
     IndexDefinitions.Items[IndexDefinitions.Count-1].CaseInsFields := case_ins;
     IndexDefinitions.Items[IndexDefinitions.Count-1].Options := iOpt;
    end; // for index definitions
  end;
   // try to create table
   try
    try
     CreateTablePtr;
    except
     on e: Exception do
      begin
       indexDefinitions.Clear;
       log := log +#13#10+'Table cannot be created with indexes - trying to create it without indexes! Error:'+#13#10+e.Message;
       CreateTablePtr;
      end;
    end;
   except
    on e: Exception do
     begin
      result := false;
      log := log +#13#10+'Table cannot be created! Error:'+#13#10+e.Message;
      Exit;
     end;
   end;
   // try to open table
   try
    destinationDataSet.Active := true;
   except
    result := false;
    log := log +#13#10+'Table cannot be opened!';
    Exit;
   end;
   // importing data to new table
   // inserting records
   First;
   FProgressProcess := aappExport;
   FProgress := 0;
   FProgressMax := RecordCount;
   if (FProgressMax = 0) then
    FProgressMax := 0.000001;
   while not Eof do
    begin
     try
      DoOnProgress(FProgress);
      destinationDataSet.Append;
      for k := 0 to FieldCount-1 do
       begin
        name := Self.Fields[k].FieldName;
        if (not FindFieldInSourceTable(destinationDataSet.FieldDefs,name)) then
         continue;
        if (Self.Fields[k].IsNull) then
         continue;
        fType := destinationDataSet.FieldByName(name).DataType;
         case fType of
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt :
              destinationDataSet.FieldByName(name).AsInteger :=
                  Self.Fields[k].AsInteger;
          ftWideString:
              destinationDataSet.FieldByName(name).Assign(Self.Fields[k]);
          ftString,
          ftFixedChar :
              destinationDataSet.FieldByName(name).AsString :=
                  Self.Fields[k].AsString;
          ftFloat,
          ftBCD,
          ftCurrency :
              destinationDataSet.FieldByName(name).AsFloat :=
                  Self.Fields[k].AsFloat;
          ftBoolean :
              destinationDataSet.FieldByName(name).AsBoolean :=
                  Self.Fields[k].AsBoolean;
          ftDate,
          ftTime,
          ftDateTime :
              destinationDataSet.FieldByName(name).AsDateTime :=
                  Self.Fields[k].AsDateTime;
          ftBLOB,
          ftMemo,
          ftFmtMemo,
          ftGraphic :
              begin
               Stream1 := CreateBlobStream(Self.Fields[k],bmRead);
               Stream2 := destinationDataSet.CreateBlobStream(
                          destinationDataSet.FieldByName(name) as TBLOBField,bmWrite);
               Stream2.CopyFrom(Stream1,Stream1.Size);
               Stream1.Free;
               Stream2.Free;
              end;
         end;
       end; // for fields
      destinationDataSet.Post;
      FProgress := FProgress + 100.0 / FProgressMax;
     except
      result := false;
      log := log +'Insert records error, record number = !'+
            inttostr(destinationDataSet.recNo)+#13#10;
     end;
     Next;
    end;

   Active := act;
   DoOnProgress(100.0);
 finally
  DBSession.UnlockSession;
 end;
end; //ExportTable


//------------------------------------------------------------------------------
// restructure table
// RestructureFieldDefs and RestructureIndexDefs will determine new table structure
// data will be saved where it is possible
// if errors occurs Exception will be rased and original table will be restored
// old table will be backuped to TableName+'_backup'
//------------------------------------------------------------------------------
procedure TEasyDataset.InternalRestructureTable(
                         NewEncrypted : Boolean;
                         NewPassword  : AnsiString;
                         NewBLOBBlockSize : Integer;
                         NewBLOBCompression : TCompressionLevel
                              );
var i,k,size                  : integer;
    old_name, name,fields,desc,case_ins: AnsiString;
    required                    : Boolean;
    fType                       : TFieldType;
    iOpt                        : TIndexOptions;
    Stream1, Stream2            : TStream;
    oldTableName,newTableName   : AnsiString;
    oldTable                    : TEasyDataset;
begin
 if (Active) then
  Raise Exception.Create('Error in TEasyDataset.InternalRestructureTable - table is opened.');
 DMHandle := nil;

 // get handle to database manager (find or create)
 SetDBFlag(dbfTable, True);
 DBSession.LockSession;
 try
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (DMHandle.GetDataSetCount > 0) then
    Raise Exception.Create('TEasyDataSet.InternalRestructureTable - Table is busy, table '+TableName);
   i := 0;
   oldTable := TEasyDataset.Create(Self);
   oldTable.StoreDefs := true;
   oldTableName := FTableName+'_backup';
   newTableName := FTableName;
   oldTable.TableName := oldTableName;
   oldTable.DatabaseName := DatabaseName;
   oldTable.DatabaseFileName := DatabaseFileName;
   oldTable.SessionName := SessionName;
   oldTable.InMemory := InMemory;
   oldTable.FastOpen := FastOpen;
   while (oldTable.Exists) do
    begin
     oldTable.TableName := oldTableName+inttostr(i);
     inc(i);
    end;
   oldTableName := oldTable.TableName;
   FieldDefs.Clear;
   IndexDefs.Clear;
   InternalRenameTable(oldTableName);
  //Active := true;

   oldTable.Password := FPassword;
   try
    oldTable.Active := true;
   except
    oldTable.Active := False;
    oldTable.InternalRenameTable(newTableName);
    oldTable.Free;
    raise;
   end;
   oldTable.RestructureFieldDefs.Clear;
   oldTable.RestructureIndexDefs.Clear;

   for i := 0 to RestructureFieldDefs.Count - 1 do
   begin
    oldTable.RestructureFieldDefs.Add(
     RestructureFieldDefs.Items[i].Name,
     RestructureFieldDefs.Items[i].DataType,
     RestructureFieldDefs.Items[i].Size,
     RestructureFieldDefs.Items[i].Required);

   end;

   for i := 0 to RestructureIndexDefs.Count - 1 do
    begin
     oldTable.RestructureIndexDefs.Add(
      RestructureIndexDefs.Items[i].Name,
      RestructureIndexDefs.Items[i].Fields,
      RestructureIndexDefs.Items[i].Options);
     oldTable.RestructureIndexDefs.Items[i].DescFields :=
       RestructureIndexDefs.Items[i].DescFields;
     oldTable.RestructureIndexDefs.Items[i].CaseInsFields :=
       RestructureIndexDefs.Items[i].CaseInsFields;
     oldTable.RestructureIndexDefs.Items[i].Options :=
       RestructureIndexDefs.Items[i].Options;
    end;

   // prepare new structure
   FieldDefs.Clear;
   for i := 0 to oldTable.RestructureFieldDefs.Count - 1 do
    begin
     // translating field definitions
     fType := oldTable.RestructureFieldDefs.Items[i].DataType;
     name := oldTable.RestructureFieldDefs.Items[i].Name;
     size := oldTable.RestructureFieldDefs.Items[i].Size;
     required := oldTable.RestructureFieldDefs.Items[i].Required;
     FieldDefs.Add(name,fType,size,required);
    end; //for fieldDefs
   // prepare DMHandle.indexes
   IndexDefs.Clear;
   for i := 0 to oldTable.RestructureIndexDefs.Count-1 do
    begin
     // auto DMHandle.indexes will be skipped
     name := oldTable.RestructureIndexDefs.Items[i].Name;
     if (name[1] = '@') then
      continue;
     iOpt := oldTable.RestructureIndexDefs.Items[i].Options;
     fields := oldTable.RestructureIndexDefs.Items[i].Fields;
      // add index definition
     IndexDefs.Add(name,fields,iOpt);
     // set desc, case_ins, options
     desc := oldTable.RestructureIndexDefs.Items[i].DescFields;
     case_ins := oldTable.RestructureIndexDefs.Items[i].CaseInsFields;
     IndexDefs.Items[IndexDefs.Count-1].DescFields := desc;
     IndexDefs.Items[IndexDefs.Count-1].CaseInsFields := case_ins;
     IndexDefs.Items[IndexDefs.Count-1].Options := iOpt;
    end; // for index definitions
   // set new properties;
   tableName := newTableName;
   FBLOBBLockSize := NewBLOBBlockSize;
   FEncrypted := NewEncrypted;
   FPassword := NewPassword;
   FBLOBCompression := NewBLOBCompression;
   try
    InternalCreateTable;
    Active := true;
   except
    on E: Exception do
     begin
      Active := false;
      oldTable.Active := False;
      oldTable.InternalRenameTable(newTableName);
      oldTable.Free;
      raise Exception.Create('Error in TEasyDataset.RestructureTable - '+E.Message);
      Exit;
     end;
   end;
   // copy data from old table
   oldTable.First;
   First;
   FProgressProcess := aappRestructure;
   FProgress := 0;
   FProgressMax := oldTable.RecordCount;
   while not oldTable.Eof do
    begin
     try
      DoOnProgress(FProgress);
      Insert;
      for k := 0 to oldTable.FieldCount-1 do
       begin
        old_name := oldTable.Fields[k].FieldName;
        name := oldTable.Fields[k].FieldName;
        if (not FindFieldInSourceTable(FieldDefs,old_name)) then
         // renamed field?
         if ((k < self.FieldCount) and
             (oldTable.FieldDefs.IndexOf(self.Fields[k].FieldName) = -1) and
             (self.Fields[k].DataType = oldTable.Fields[k].DataType)) then
          name := self.Fields[k].FieldName
         else
          continue;
        if (oldTable.Fields[k].IsNull) then
         continue;
        fType := oldTable.FieldByName(old_name).DataType;
         case fType of
          ftAutoInc:
            begin
            SetAutoIncValue(oldTable.FieldByName(old_name).AsInteger);
             AutoIncChangeEnabled := true;
             try
               FieldByName(name).AsInteger :=
                 oldTable.FieldByName(old_name).AsInteger;
             finally
               AutoIncChangeEnabled := false;
             end;
            end;

          ftInteger,
          ftSmallInt,
          ftWord:
              FieldByName(name).AsInteger :=
                oldTable.FieldByName(old_name).AsInteger;

          ftLargeInt :
              TLargeintField(FieldByName(name)).AsLargeInt :=
                TLargeintField(oldTable.FieldByName(old_name)).AsLargeInt;
          ftWideString:
              FieldByName(name).Assign(oldTable.FieldByName(old_name));
          ftString,
          ftMemo,
          ftFmtMemo,
          ftFixedChar :
              FieldByName(name).AsString :=
                oldTable.FieldByName(old_name).AsString;
          ftFloat,
          ftBCD,
          ftCurrency :
              FieldByName(name).AsFloat :=
                oldTable.FieldByName(old_name).AsFloat;
          ftBoolean :
              FieldByName(name).AsBoolean :=
                oldTable.FieldByName(old_name).AsBoolean;
          ftDate,
          ftTime,
          ftDateTime :
              FieldByName(name).AsDateTime :=
                oldTable.FieldByName(old_name).AsDateTime;
          ftBLOB,
          ftGraphic :
              begin
               Stream1 := oldTable.CreateBlobStream(oldTable.FieldByName(old_name),bmRead);
               Stream2 := CreateBlobStream(
                            FieldByName(name),bmWrite);
               Stream2.CopyFrom(Stream1,Stream1.Size);
               Stream1.Free;
               Stream2.Free;
              end;
         end;
       end; // for fields
      Post;
      FProgress := FProgress + 100.0 / FProgressMax;
     except
      on E: Exception do
       begin
       Active := false;
       oldTable.Active := False;
       oldTable.InternalRenameTable(newTableName);
       oldTable.Free;
       raise Exception.Create(
       'Error in TEasyDataset.RestructureTable - error while saving data. Restructure aborted. '+E.Message);
       end;
     end;
     oldTable.Next;
    end;

   Active := false;
   oldTable.Active := false;
   oldTable.InternalDeleteTable;
   oldTable.Free;
   DoOnProgress(100.0);
 finally
   DBSession.UnlockSession;
   SetDBFlag(dbfTable, False);
 end;
end; //RestructureTable


//------------------------------------------------------------------------------
// restructure table
//------------------------------------------------------------------------------
procedure TEasyDataset.InternalRestructureTable;
begin
 InternalRestructureTable(FEncrypted,FPassword,FBLOBBlockSize,FBLOBCompression);
end; //RestructureTable


//------------------------------------------------------------------------------
// returns true, if repair was successful (all data fully restored), log = ''
// tries to repair table
// repair is available, if table header is not corrupted,
// i.e. table opens properly (by setting Active to true)
//------------------------------------------------------------------------------
function TEasyDataset.InternalRepairTable(
                          var log : AnsiString // returns error log
                         ) : Boolean;
var i,k,size, keyValue,recCount, maxID : integer;
    oldID : aInteger;
    name,fields,desc,case_ins   : AnsiString;
    required                    : Boolean;
    fType                       : TFieldType;
    iOpt                        : TIndexOptions;
    Stream1, Stream2            : TStream;
    oldTableName,newTableName   : AnsiString;
    bBlobField                  : Boolean;
    DestinationBuffer, buffer   : PAnsiChar;
    oldTable                    : TEasyDataset;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
begin
 if (Active) then
  Raise Exception.Create('Error in TEasyDataset.InternalRepairTable - table is opened.');
 if (not Exists) then
  Raise Exception.Create('Error in TEasyDataset.InternalRepairTable - table "'+
  			TableName+ '" does not exist.');
 DMHandle := nil;
 result := False;

 // get handle to database manager (find or create)
// DBMHandle := aaGetDatabaseManager(GetDBName, self);
 SetDBFlag(dbfOpened, True);
 DBSession.LockSession;
 try
   // get handle to data manager (find or create)
   DMHandle := aaGetDataManager(FTableName, DBMHandle);
   if (DMHandle.GetDataSetCount > 0) then
    Raise Exception.Create('TEasyDataSet.InternalRepairTable - Table is busy, table '+TableName);
   log := '';
   i := 0;
   oldTable := TEasyDataset.Create(Self);
   oldTable.StoreDefs := true;
   newTableName := FTableName+'_backup';
   oldTable.DatabaseName := DatabaseName;
   oldTable.DatabaseFileName := DatabaseFileName;
   oldTable.SessionName := SessionName;
   oldTable.TableName := newTableName;
   oldTable.Password := FPassword;
   oldTable.FRepairIsRunning := true;
   while (oldTable.Exists) do
    begin
     oldTable.TableName := newTableName+inttostr(i);
     inc(i);
    end;
   oldTableName := oldTable.TableName;
   newTableName := FTableName;
   try
    Active := false;
    InternalRenameTable(oldTableName);
    oldTable.TableName := oldTableName;
   except
    raise Exception.Create(
      'Error in TEasyDataset.RepairTable - can not rename table.');
    Exit;
   end;
   try
    oldTable.Active := true;
    oldTable.DMHandle.FRepairIsRunning := True;
    AutoIndexes := oldTable.AutoIndexes;
   except
    if (oldTable.DMHandle <> nil) then
     oldTable.DMHandle.FRepairIsRunning := False;
    InternalRenameTable(newTableName,True);
    log := log + 'Error in TEasyDataset.RepairTable - can not open table:'+newTableName;
//    raise Exception.Create(
//      'Error in TEasyDataset.RepairTable - can not open table:'+newTableName);
    Exit;
   end;
  // keyName := oldTable.DMHandle.tableHeader.sequenceName;
  // FieldDefs.Add(keyName,ftAutoInc);
   // set new properties;
   tableName := newTableName;
   // prepare new structure
   FieldDefs.Clear;
   for i := 0 to oldTable.FieldDefs.Count - 1 do
    begin
     // translating field definitions
     fType := oldTable.FieldDefs.Items[i].DataType;
     name := oldTable.FieldDefs.Items[i].Name;
     size := oldTable.FieldDefs.Items[i].Size;
     required := oldTable.FieldDefs.Items[i].Required;
  //   if (fType = ftAutoInc) then
  //    fType := ftInteger;
     // truncate field name
     if Length(name) > (MAX_NAME_LENGTH-2) then
      name := Copy(name,1,(MAX_NAME_LENGTH-2));
     FieldDefs.Add(name,fType,size,required);
    end; //for fieldDefs
   // prepare DMHandle.indexes
   IndexDefs.Clear;
   for i := 0 to oldTable.IndexDefs.Count-1 do
    begin
     // auto DMHandle.indexes will be skipped
     name := oldTable.IndexDefs.Items[i].Name;
     // truncate index name
     if Length(name) > (MAX_NAME_LENGTH-2) then
      name := Copy(name,1,(MAX_NAME_LENGTH-2));
     if (name[1] = '@') then
      continue;
     iOpt := oldTable.IndexDefs.Items[i].Options;
     fields := oldTable.IndexDefs.Items[i].Fields;
      // add index definition
     IndexDefs.Add(name,fields,iOpt);
     // set desc, case_ins, options
     desc := oldTable.IndexDefs.Items[i].DescFields;
     case_ins := oldTable.IndexDefs.Items[i].CaseInsFields;
     IndexDefs.Items[IndexDefs.Count-1].DescFields := desc;
     IndexDefs.Items[IndexDefs.Count-1].CaseInsFields := case_ins;
     IndexDefs.Items[IndexDefs.Count-1].Options := iOpt;
    end; // for index definitions
   FBLOBCompression := oldTable.BLOBCompression;
   FBLOBBlockSize := oldTable.BLOBBlockSize;
   FEncrypted := oldTable.Encrypted;
   FPassword := oldTable.Password;
   try
    InternalCreateTable;
    Active := true;
   except
     Active := false;
     oldTable.Active := False;
     oldTable.InternalRenameTable(newTableName);
     oldTable.Free;
     raise Exception.Create(
      'Error in TEasyDataset.RepairTable - invalid table structure.');
     Exit;
   end;
   result := True;
   // copy data from old table
   oldTable.IndexName := '';
   oldTable.IndexFieldNames := '';
   First;
   FProgressProcess := aappRepair;
   FProgress := 0;
   FProgressMax := oldTable.RecordCount;
   recCount := oldTable.GetRecordCount;
   // get max ID
   maxID := 0;
   for I := 0 to recCount-1 do
    begin
     oldTable.RecNo := i+1;
     keyValue := oldTable.GetCurrentID;
     if (keyValue > maxID) then
      maxID := keyValue;
    end;
   SetLength(oldID,recCount);
   for I := 0 to recCount-1 do
    begin
     oldTable.RecNo := i+1;
     DoOnProgress(FProgress);
     Insert;
     try
      DestinationBuffer := GetActiveRecordBuffer;
      Buffer := oldTable.GetCurrentRecordBuffer;
      Move(Buffer^,DestinationBuffer^,DMHandle.recInfoBufferSize);
      for k := 0 to oldTable.FieldCount-1 do
       begin
        name := oldTable.Fields[k].FieldName;
        if (not FindFieldInSourceTable(FieldDefs,name)) then
         continue;
        if (oldTable.Fields[k].IsNull) then
         continue;
        fType := oldTable.FieldByName(name).DataType;
        bBLOBField := false;
        try
         case fType of
          ftLargeInt :
              TLargeintField(FieldByName(name)).AsLargeInt :=
                TLargeintField(oldTable.FieldByName(name)).AsLargeInt;
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord:
              FieldByName(name).AsInteger :=
                oldTable.FieldByName(name).AsInteger;
          ftWideString:
              FieldByName(name).Assign(oldTable.FieldByName(name));
          ftString,
          ftFixedChar :
              FieldByName(name).AsString :=
                oldTable.FieldByName(name).AsString;
          ftFloat,
          ftBCD,
          ftCurrency :
              FieldByName(name).AsFloat :=
                oldTable.FieldByName(name).AsFloat;
          ftBoolean :
              FieldByName(name).AsBoolean :=
                oldTable.FieldByName(name).AsBoolean;
          ftDate,
          ftTime,
          ftDateTime :
              FieldByName(name).AsDateTime :=
                oldTable.FieldByName(name).AsDateTime;
          ftBLOB,
          ftMemo,
          ftFmtMemo,
          ftGraphic :
              begin
              bBLOBField := true;
               Stream1 := oldTable.CreateBlobStream(oldTable.FieldByName(name),bmRead);
               Stream2 := CreateBlobStream(
                            FieldByName(name),bmWrite);
               Stream2.CopyFrom(Stream1,Stream1.Size);
               Stream1.Free;
               Stream2.Free;
              end;
         end;
        except
         if (bBLOBField) then
          begin
           Stream2 := CreateBlobStream(FieldByName(name),bmWrite);
           Stream2.Free;
           // empty blob stream value
          end
         else
          begin
           // empty value
           chkfld_set := true;
           chkfld_fieldNum := k;
           chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
           {$include set_fields.inc}
          end;
        end; // error in import field data
       end; // for fields
      keyValue := oldTable.GetCurrentID;
      if (keyValue <= 0) then
       begin
         inc(maxID);
         keyValue := maxID;
       end
      else
        for K := 0 to I-1 do
         if (oldID[k] = keyValue) then
          begin
           inc(maxID);
           keyValue := maxID;
           break;
          end;
      SetAutoIncValue(keyValue);
      oldID[i] := keyValue;
      Post;
     except
      Cancel;
      result := false;
      log := log +
      'Error in TEasyTable.RepairTable - error while saving data. Invalid record #'
        +inttostr(oldTable.RecNo)+crlf;
     end;
     FProgress := FProgress + 100.0 / FProgressMax;
  //   oldTable.Next;
    end;

   DMHandle.tableHeader.sequenceValue := maxID;
   oldTable.FRepairIsRunning := false;
   oldTable.Active := false;
   if (result) then
    oldTable.InternalDeleteTable
   else
    log := log + 'Errors occured while repairing table. Original table is copied as "'+
      oldTableName+'"';
   Active := false;
   oldTable.Free;
   DoOnProgress(100.0);
 finally
  DBSession.UnlockSession;
  SetDBFlag(dbfOpened, False);
 end;
end; //RepairTable


//------------------------------------------------------------------------------
// closes dataset
//------------------------------------------------------------------------------
procedure TEasyDataset.Disconnect;
begin
 DBSession.LockSession;
 try
  if (Active) then
   Close
  else
   if (FDatabase <> nil) then
    FDatabase.FDataSets.Remove(Self);
 finally
  DBSession.UnlockSession;
 end;
end;// Disconnect


//------------------------------------------------------------------------------
// checks session name
//------------------------------------------------------------------------------
procedure TEasyDataset.CheckDBSessionName;
var
  S: TEasySession;
  Database: TEasyDatabase;
begin
  if (SessionName <> '') and (DatabaseName <> '') then
  begin
    S := Sessions.FindSession(SessionName);
    if Assigned(S) and not Assigned(S.DoFindDatabase(DatabaseName, DatabaseFileName, Self)) then
    begin
      Database := ETblDefaultSession.DoFindDatabase(DatabaseName, DatabaseFileName, Self);
      if Assigned(Database) then Database.CheckSessionName(True);
    end;
  end;
end;// CheckDBSessionName


//------------------------------------------------------------------------------
// assigns / frees database
//------------------------------------------------------------------------------
procedure TEasyDataset.SetDBFlag(Flag: Integer; Value: Boolean);
begin
  if Value then
    begin
      if (not (Flag in FDBFlags)) then
        begin
         if (FDBFlags=[]) then
           begin
            DBMHandle := nil;
            CheckDBSessionName;
            FDatabase := OpenDatabase;
            FDatabase.FDataSets.Add(Self);
            // get dbm handle
            DBMHandle := FDatabase.Handle;
           end;
         Include(FDBFlags,Flag);
       end;
    end
  else
    begin
      if (Flag in FDBFlags) then
        begin
         Exclude(FDBFlags,Flag);
         if (FDBFlags=[]) then
           begin
            FDatabase.FDataSets.Remove(Self);
            FDatabase.Session.CloseDatabase(FDatabase);
            FDatabase := nil;
            DBMHandle := nil;
           end;
        end;
      end;
end;// SetDBFlag


//------------------------------------------------------------------------------
// opens cursor
//------------------------------------------------------------------------------
procedure TEasyDataset.OpenCursor(InfoQuery: Boolean);
begin
  DBSession.LockSession;
  try
    SetDBFlag(dbfOpened, True);
    inherited OpenCursor(InfoQuery);
  finally
   DBSession.UnlockSession;
  end;
end;// OpenCursor


//------------------------------------------------------------------------------
// closes cursor
//------------------------------------------------------------------------------
procedure TEasyDataset.CloseCursor;
begin
  DBSession.LockSession;
  try
    inherited CloseCursor;
    SetDBFlag(dbfOpened,False);
  finally
    DBSession.UnlockSession;
  end;
end;// CloseCursor


//------------------------------------------------------------------------------
//  Inc(Count), don't create visible records list
//------------------------------------------------------------------------------
procedure TEasyDataset.FreezeVisibleRecords;
begin
  Inc(FFreezeVisibleRecordCount);
end;// FreezeVisibleRecords


//------------------------------------------------------------------------------
// Dec(Count), if count=0 - create visible records list
//------------------------------------------------------------------------------
procedure TEasyDataset.UnfreezeVisibleRecords(Force: Boolean=False);
begin
 DBSession.LockSession;
 try
   if (VisibleRecordsFreezed) then
    begin
     if (not Force) then
      Dec(FFreezeVisibleRecordCount)
     else
      FFreezeVisibleRecordCount := 0;
     if (not VisibleRecordsFreezed) then
      begin
       CreateVisibleRecordsList;
//       SetActiveBuffer;
      end;
    end;
 finally
   DBSession.UnlockSession;
 end;
end;// UnfreezeVisibleRecords


//------------------------------------------------------------------------------
// if (Count > 0) - Freezed (don't create visible records list)
//------------------------------------------------------------------------------
function TEasyDataset.VisibleRecordsFreezed: Boolean;
begin
 Result := (FFreezeVisibleRecordCount > 0);
end;// VisibleRecordsFreezed


//------------------------------------------------------------------------------
// creates new index in table
//------------------------------------------------------------------------------
procedure TEasyDataset.InternalAddIndex(
              const Name, // index name
              Fields: AnsiString; // fields list (separated by ';', ',',' ' or any combination) 
              Options: TIndexOptions; // ixDescending, ixCaseInsensetive are available options
              const DescFields: AnsiString =''; // desc fields list (separated by ';', ',',' ' or any combination) 
              const CaseInsFields: AnsiString ='' // case insensitive fields list (separated by ';', ',',' ' or any combination)
              );
begin
 if (not isTableOpened) then  raise Exception.Create(
     'Error in TEasyDataset.InternalAddIndex - table is not opened.');
 DBSession.LockSession;
 try
  DMHandle.AddIndex(Name,Fields,Options,DescFields,CaseInsFields);
  CreateIndexDefinitions;
  TableState := DMHandle.tableHeader.state;
 finally
  DBSession.UnlockSession;
 end;
end; //AddIndex


//------------------------------------------------------------------------------
// creates temporary index
//------------------------------------------------------------------------------
function TEasyDataset.CreateTemporaryIndex(Fields, DescFields, CaseInsFields: AnsiString): AnsiString;
begin
 if (not isTableOpened) then  raise Exception.Create(
     'Error in TEasyDataset.CreateTemporaryIndex - table is not opened.');
 DBSession.LockSession;
 try
  result := DMHandle.CreateTemporaryIndex(Fields,DescFields,CaseInsFields);
 finally
  DBSession.UnlockSession;
 end;
end; // CreateTemporaryIndex


//------------------------------------------------------------------------------
// delete index
//------------------------------------------------------------------------------
procedure TEasyDataset.InternalDeleteIndex(
     											const Name : String// name
                         );
var num: Integer;
begin
 DBSession.LockSession;
 try
   if (not isTableOpened) then  raise Exception.Create(
       'Error in TEasyDataset.InternalDeleteIndex - table is not opened.');
   if (DMHandle.GetDataSetCount > 1) then
    Raise Exception.Create('TEasyDataSet.InternalDeleteTable - Table is busy, table '+TableName);
   num := DMHandle.DeleteIndex(Name);
   if (num = currentIndex) or (num <= 0) or (currentIndex = 0) then
    currentIndex := 0
   else
    dec(currentIndex);
   CreateIndexDefinitions;
   CreateVisibleRecordsList;
 finally
  DBSession.UnlockSession;
 end;
end; //DeleteIndex


//------------------------------------------------------------------------------
// delete all indexes
//------------------------------------------------------------------------------
procedure TEasyDataset.InternalDeleteAllIndexes;
begin
 DBSession.LockSession;
 try
  if (not isTableOpened) then  raise Exception.Create(
     'Error in TEasyDataset.InternalDeleteAllIndexes - table is not opened.');
  DMHandle.DeleteAllIndexes;
  CreateIndexDefinitions;
  // reset index to auto-inc (always exists)
  currentIndex := 0;
  FIndexName := '';
  FIndexFieldNames := '';
 finally
  DBSession.UnlockSession;
 end;
end; //DeleteAllIndexes;


//------------------------------------------------------------------------------
// creates temporary table
//------------------------------------------------------------------------------
procedure TEasyDataSet.CreateTemporaryTable(RecordCount1: integer = DefaultRecordsPerPage);
begin
 DBSession.LockSession;
 try
   if Active then
    Close;
   PageRecordCount := RecordCount1;
   InMemory := true;
   AutoIndexes := False;
   DatabaseName := '';
   repeat
     TableName := GetTemporaryName('@TABLE');
   until (not Self.Exists);  
   InternalCreateTable;
   FTemporaryTable := True;
   FSilentMode := True;
 finally
  DBSession.UnlockSession;
 end;
end;


//------------------------------------------------------------------------------
// deletes temporary table
//------------------------------------------------------------------------------
procedure TEasyDataSet.DeleteTemporaryTable;
begin
 if (FTemporaryTable) then
  begin
   DBSession.LockSession;
   try
     if Active then
      Close;
     InternalDeleteTable;
   finally
    DBSession.UnlockSession;
   end;
  end;
end;


//------------------------------------------------------------------------------
// Get list of names of all database components
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetDatabaseNameList(List: TStrings);
var i: integer;
begin
 List.Clear;
 if (DBSession <> nil) then
  for i:=0 to DBSession.FDatabases.Count-1 do
   List.Add(TEasyDatabase(DBSession.FDatabases.Items[i]).DatabaseName);
end;//TEasyDataSet.GetDatabaseNameList;


//------------------------------------------------------------------------------
// save easy table state
//------------------------------------------------------------------------------
{$IFDEF DEBUG_FLAG}
procedure TEasyDataSet.aaWriteStateToLog(prompt : string);
var i,j : integer;
    s,s1 : string;
begin
 s := crlf+'----- '+prompt+' -----'+crlf;
 if (not isTableOpened) then
 begin
  s := s + 'Table is not opened';
  aaWriteToLog(s);
  Exit;
 end;
 if (isIndexUsed) then
  s1 := ', IndexUsed = true'
 else
  s1 := ', IndexUsed = false';

 s := s+ 'Table is opened. RecCount = '+inttostr(DMHandle.tableHeader.recordCount)+
       ', FieldCount = '+inttostr(DMHandle.tableHeader.fieldCount)+
       ', Table.State = '+inttostr(DMHandle.tableHeader.state)+
       ', Index.State = '+inttostr(DMHandle.indexFileHeader.state) ;
 aaWriteToLog(s);
 if (Filtered) then
  s1 := ', Filtered = true'
 else
  s1 := ', Filtered = false';
 s := s1 + ', Filter = '+Filter;
 aaWriteToLog(s);

 j := -2;
 if ((tablePosition >= 0) and (tablePosition < visibleRecordCount)) then
  j := visibleRecords.Items[tablePosition];
 s := 'VisibleRecCount = '+inttostr(VisibleRecordCount)+
       ', tablePos = '+inttostr(tablePosition)+
       ', curRecord = '+inttostr(j)+
       ', header.indexCount = '+inttostr(DMHandle.indexFileHeader.indexCount)+
       ', indexList.Count = '+inttostr(DMHandle.indexHeaderList.Count)+', visrecords:';
 aaWriteToLog(s);

 s := '';
 for i := 0 to visibleRecordCount - 1 do
  begin
    s:=s+inttostr(visibleRecords.items[i])+crlf;
  end;
 aaWriteToLog('visible records: +'+crlf+s);
 {
 s := '';
 if (isIndexUsed) then
  begin
   for i := 0 to DMHandle.tableHeader.recordCount - 1 do
    begin
     s := s+inttostr(i)+'. ';
     s:=s+inttostr(DMHandle.indexes[currentIndex].items[i]);
     s := s+' int = ';
     s:=s+inttostr(PInteger(
        DMHandle.fieldOffsets[0]+
        DMHandle.allRecBuffer.GetRecordDataPtr(
          DMHandle.indexes[currentIndex].items[i]))^);
     s:=s+crlf;
    end;
  end;
 aaWriteToLog('current index:'+crlf +s);
} 
{
 s := 'ID: ';
 for i := 0 to visibleRecordCount - 1 do
  begin
   if (i > 0) then
     s:=s+',';
   s := s + inttostr(
     pRecordInfoType(
       DMHandle.allRecBuffer.pData+ (DMHandle.recInfoBufferSize)*i+DMHandle.recordSize)^.id
   );

  end;

   aaWriteToLog(s);
   }
end; //TEasyDataSet.aaWriteStateToLog;
{$ENDIF}


//------------------------------------------------------------------------------
// EasyDataSet constructor
//------------------------------------------------------------------------------
constructor TEasyDataSet.Create(AOwner:tComponent);
begin
  if (not bDesignMode) then
   if (Aowner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
     bDesignMode := true;
  FDoNotBindFields := false;
  FRepairIsRunning := False;
  FProjection := false;
  FDistinctFields := '';
  FDistinctIndexNo := -1;
  FDirectInsert := false;
  FDirectFilter := False;
  FSQLFilterExpr := nil;
  FSQLTopRowCount := -1;
  FSQLFirstRowNo := -1;
  FDirectAccessForGetFieldValue := false;
  FFreezeVisibleRecordCount := 0;
  FTemporaryRecordBuffer := nil;
  FSettingProjection := False;
  FProjectionFieldList := TStringList.Create;
  FProjectionAliasList := TStringList.Create;
  DBMHandle :=  nil;
  DBHandle :=  nil;
  DMHandle :=  nil;
  isTableOpened := false;
  visibleRecords := TaaIntArray.Create;
  debugFlag := false;
  createIndexDefs := true;
  visibleRecordCount := 0;
  inherited create(aOwner); // TDataSet constructor
  FProjectionMap := TaaIntArray.Create(0,1,100);
  FMasterLink := TEasyMasterDataLink.Create(Self);
  FMasterLink.OnMasterChange := MasterChanged;
  FMasterLink.OnMasterDisable := MasterDisabled;
  FIndexDefs := TIndexDefs.Create(Self);
  FRestructureIndexDefs := TIndexDefs.Create(Self);
  FRestructureFieldDefs := TFieldDefs.Create(Self);
  if (FBLOBBlockSize <= 0) then
   FBLOBBlockSize := DEFAULT_BLOB_BLOCK_SIZE;
  foundVisibleRecordsList := TaaList.Create;
  isIndexUsed := false;
  // search parser for visible records
  FilterParser := TSearchParser.Create(self);
  MasterDetailParser := TSearchParser.Create(self);
  FindParser := TSearchParser.Create(self);
  FFastOpen := false;
  FoldFastOpen := 0;
  FoldFastOpen2 := 0;
  FAutoIndexes := False;
  PageRecordCount := DefaultRecordsPerPage;
  // FindFirst, FindNext ignores Filtered=True?
  FBDELikeFilter := False;
  FSilentMode := False;
end; //TEasyDataSet.Create;


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyDataSet.Destroy;
begin
  Active := false;
  if FTemporaryRecordBuffer <> nil then
   FreeRecordBuffer(TRecordBuffer(FTemporaryRecordBuffer));
  visibleRecords.Free;
  foundVisibleRecordsList.Free;
  isIndexUsed := false;
  inherited destroy; // TDataSet destructor
  FProjectionMap.Free;
  FMasterLink.Free;
  FIndexDefs.Free;
  FRestructureIndexDefs.Free;
  FRestructureFieldDefs.Free;
  FilterParser.Free;
  MasterDetailParser.Free;
  FindParser.Free;
  FProjectionFieldList.Free;
  FProjectionAliasList.Free;
end; //TEasyDataSet.Create


//------------------------------------------------------------------------------
// get index names
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetIndexNames(List: TStrings);
begin
  IndexDefs.Update;
  IndexDefs.GetItemNames(List);
end; // TEasyDataSet.GetIndexNames


//------------------------------------------------------------------------------
// get database name or database file name
//------------------------------------------------------------------------------
function TEasyDataSet.GetDBName: AnsiString;
begin
  if (FDatabaseFileName <> '') then
   Result := FDatabaseFileName
  else
  if (FDatabaseName <> '') then
   Result := FDatabaseName;
end;// TEasyDataSet.GetDBName


//------------------------------------------------------------------------------
// open database
//------------------------------------------------------------------------------
function TEasyDataSet.OpenDatabase: TEasyDatabase;
begin
  with Sessions.List[FSessionName] do
   Result := DoOpenDatabase(FDatabaseName, FDatabaseFileName, Self.Owner);
end;// OpenDatabase


//------------------------------------------------------------------------------
// close database
//------------------------------------------------------------------------------
procedure TEasyDataSet.CloseDatabase(Database: TEasyDatabase);
begin
  if Assigned(Database) then
    Database.Session.CloseDatabase(Database);
end;// CloseDatabase


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TEasyDataSet.OpenTable;
var
  i: Integer;
  bNoDBMHandle: Boolean;
begin
 DBSession.LockSession;
 try
   bNoDBMHandle := (DBMHandle = nil);
   if (bNoDBMHandle) then
    SetDBFlag(dbfOpened, True);
   try
     // connect to database manager
     DBMHandle.ConnectDataSet(Self);
     // get handle to data manager (find or create)
     DMHandle := aaGetDataManager(FTableName, DBMHandle);
     DMHandle.FRepairIsRunning := FRepairIsRunning;
     // connect to data manager, open disk table if necessary
     i := DMHandle.ConnectDataSet(Self);
     if (i <> TETERR_NO_ERROR) then
      begin
       DBMHandle.DisconnectDataSet(Self);
       DMHandle.Free;
       DMHandle := nil;
       DBMHandle := nil;
       isTableOpened := false;
       if (i = TETERR_NO_TABLE) then
         raise Exception.Create('TEasyDataset.OpenTable - table "'+
             FTableName+'" does not exist.');
       if (i = TETERR_INVALID_PASSWORD) then
         raise Exception.Create('TEasyDataset.OpenTable - invalid password.');
       if (i = TETERR_NO_PASSWORD) then
         raise Exception.Create('TEasyDataset.OpenTable - no password specified.');
       if (i = TETERR_OPEN_FILES) then
         raise Exception.Create('TEasyDataset.OpenTable - table "'+
             FTableName+'" does not exist or some files of table are missed or locked.');
       if (i = TETERR_CORRUPTED_BLOB_HEADERS) then
         raise Exception.Create('TEasyDataset.OpenTable - table "'+
             FTableName+'" has a corrupted blob headers.')
       else
         raise Exception.Create('TEasyDataset.OpenTable - error.');
       Exit;
      end;
     isTableOpened := true;
     BookmarkSize := sizeOf(BookmarkInfoType);
     visRecUpdated := false;
     visibleRecords.SetSize(0);
     if (createIndexDefs) then
         CreateIndexDefinitions;
     tablePosition := -1;
     insertMode := false;
     if (DMHandle.isBLOBUsed) then
      begin
       SetLength(blobFields,DMHandle.tableHeader.fieldCount);
       for i := 0 to DMHandle.tableHeader.fieldCount-1 do
        blobFields[i].stream := nil;
      end;
     FSetActiveBufferFlag := false;
   finally
    if (bNoDBMHandle) then
     begin
      DBMHandle.DisconnectDataSet(Self);
      SetDBFlag(dbfOpened, False);
     end;
   end;
 finally
  DBSession.UnlockSession;
 end;
end; // TEasyDataSet.OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TEasyDataSet.CloseTable;
begin
 DBSession.LockSession;
 try
   if (DMHandle.isBLOBUsed) then
    begin
     ClearBLOBStreams;
     blobFields := nil;
    end;
   DMHandle.DisconnectDataSet(Self);
   if (DBMHandle <> nil) then
    DBMHandle.DisconnectDataSet(Self);

  // CloseDatabase(DBHandle);

   DMHandle := nil;
  // DBMHandle := nil;
   foundVisibleRecordsList.Clear;
   isIndexUsed := false;
   isTableOpened := false;
   visibleRecordCount := 0;
   visibleRecords.SetSize(0);
 finally
  DBSession.UnlockSession;
 end;
end; // TEasyDataSet.CloseTable


//------------------------------------------------------------------------------
// Flushes all changes that have been written to the database table
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalFlushBuffers;
begin
 DBSession.LockSession;
 try
  DMHandle.FlushBuffers;
 finally
  DBSession.UnlockSession;
 end;
end; //InternalFlushBuffers


//------------------------------------------------------------------------------
// returns true if table is encrypted
//------------------------------------------------------------------------------
function TEasyDataSet.IsTableEncrypted : Boolean;
begin
 if (not Active) then
  begin
   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   DBSession.LockSession;
   try
     // get handle to data manager (find or create)
     DMHandle := aaGetDataManager(FTableName, DBMHandle);
     try
  //    DMHandle.ConnectDataset(self);
      Result := DMHandle.IsTableEncrypted;
      if (DMHandle.DatasetList.Count = 0) then
       begin
        DMHandle.Free;
        DMHandle := nil;
       end;
  //    DMHandle.DisconnectDataset(self);
     except
      result := true;
     end;
   finally
     DBSession.UnlockSession;
     SetDBFlag(dbfTable, False);
   end;
  end
 else
  Result := DMHandle.IsTableEncrypted;
end; //IsTableEncrypted


//------------------------------------------------------------------------------
// reads blob value from file
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaReadBLOBValue(
                FieldNo : Integer;
                DoNotCheckState: Boolean; // for checking if record is visible
                RealPhysRecNo:   Integer
                );
var physRecNo : Integer;
begin
 DBSession.LockSession;
 try
   if (not DoNotCheckState) then
    begin
     CheckTableState;
     if (state = dsInsert) then
      Exit;
    end;
   if (tablePosition >= 0) and (tablePosition < visibleRecordCount) then
    begin
     if (not DoNotCheckState) then
      physRecNo := visibleRecords.items[tablePosition]
     else
      physRecNo := RealPhysRecNo; 
     DMHandle.aaReadBLOBValue(blobFields[FieldNo].stream,FieldNo,physRecNo);
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //aaReadBLOBValue


//------------------------------------------------------------------------------
// writes blob value from file
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaWriteBLOBValue(FieldNo : Integer);
var physRecNo, tPos, id : Integer;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
begin
 DBSession.LockSession;
 try
   CheckTableState;
   if (not insertMode) then
    begin
     Move(PAnsiChar(GetActiveRecordBuffer+DMHandle.recordSize)^,id,sizeOf(integer)); //id
     tPos := GetTablePositionByID(id);
     if (tPos >= 0) and (tPos < visibleRecordCount) then
       physRecNo := visibleRecords.items[tPos]
      else
       raise Exception.Create(
      'Error in TEasyDataSet.aaWriteBLOBValue - error while detecting physical position, '
      +'tPos = '+IntToStr(tPos));
    end
   else
    //insert to the end
    physRecNo := DMHandle.tableHeader.recordCount; //last pos
   DMHandle.aaWriteBLOBValue(blobFields[FieldNo].stream,FieldNo,physRecNo);
     chkfld_buffer := pAnsiChar(GetActiveRecordBuffer+DMHandle.recNullOffset);
     chkfld_fieldNum := FieldNo;
     if (blobFields[FieldNo].stream.size <= 0) then
      begin
       chkfld_set := true;
       {$include set_fields.inc}
      end
     else
      begin
       chkfld_set := false;
       {$include set_fields.inc}
      end;
 finally
   DBSession.UnlockSession;
 end;
end; //aaWriteBLOBValue


//------------------------------------------------------------------------------
// delete blob index headers for current record
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaDeleteBLOBRecord;
var id,tPos,physRecNo : integer;
begin
 DBSession.LockSession;
 try
   CheckTableState;
   Move(PAnsiChar(GetActiveRecordBuffer+DMHandle.recordSize)^,id,sizeOf(integer)); //id
   tPos := GetTablePositionByID(id);
   if (tPos >= 0) and (tPos < visibleRecordCount) then
    begin
     physRecNo := visibleRecords.items[tPos];
     DMHandle.aaDeleteBLOBRecord(physRecNo);
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //aaDeleteBLOBRecord;


//------------------------------------------------------------------------------
// saves all blob streams (Post)
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaSaveBLOBData;
var i : Integer;
begin
 DBSession.LockSession;
 try
   for i := 0 to DMHandle.tableHeader.fieldCount-1 do
    if (blobFields[i].stream <> nil) then
//     if (blobFields[i].mode = bmWrite) or (blobFields[i].mode = bmReadWrite) then
     begin
      aaWriteBLOBValue(i);
     end;
 finally
   DBSession.UnlockSession;
 end;
end; //aaSaveBLOBData;


//------------------------------------------------------------------------------
// Create blob stream
//------------------------------------------------------------------------------
function TEasyDataSet.InternalCreateBlobStream(
    					Field: TField; Mode: TBlobStreamMode
//              s	: shortstring	= ''// hashed password for encryption;
              										// '' - no encryption
                                  ):TMemoryStream;
var FieldNo,id,tPos : Integer;
    buf : PAnsiChar;
begin
 DBSession.LockSession;
 try
  // if (state = dsCalcFields) then
  // filter bug with memo fields
    result := nil;
    buf := GetActiveRecordBuffer;
    if (buf = nil) then Exit;
    Move(PAnsiChar(buf+DMHandle.recordSize)^,id,sizeOf(integer));
  // else
  // Move(PAnsiChar(ActiveBuffer+DMHandle.recordSize)^,id,sizeOf(integer)); //id
   // may be records are freezed
   if (FDirectInsert) then
    tPos := tablePosition+1
   else
    tPos := GetTablePositionByID(id);
   // new record will produce tPos = -1
   if (tPos <> tablePosition) and (not FDirectInsert) then
   //or ((tPos = -1) and (tPos = tablePosition))
    begin
     tablePosition := tPos;
     ClearBLOBStreams;
    end;

   if (not isTableOpened) then raise Exception.Create(
      'Error in TEasyDataSet.InternalCreateBLOBStream - table is not opened.');
   FieldNo := Field.FieldNo-1;
   // added by Leo Martin, 5.40
   // Projection for BLOB fields
   if (FProjection) then
    begin
     // physical field number
     if (FieldNo >= 0) and (FieldNo < FProjectionMap.ItemCount) then
      FieldNo := FProjectionMap.Items[FieldNo];
    end;

   if (blobFields[FieldNo].stream = nil) then
    begin
     blobFields[FieldNo].stream := TMemoryStream.Create;
    if (Mode <> bmWrite) then
     aaReadBLOBValue(FieldNo);
    end
   else
    begin
     if (State <> dsEdit) and (State <> dsInsert) then
      begin
       blobFields[FieldNo].stream.Free;
       blobFields[FieldNo].stream := TMemoryStream.Create;
      end;
     if (Mode = bmWrite) then
      blobFields[FieldNo].stream.Size := 0;
     if (Mode <> bmWrite) then
      if (State <> dsEdit) and (State <> dsInsert) then
      aaReadBLOBValue(FieldNo);
    end;
   blobFields[FieldNo].mode := mode;
   blobFields[FieldNo].stream.Seek(0,soFromBeginning);
   result :=  blobFields[FieldNo].stream;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.InternalCreateBlobStream


//------------------------------------------------------------------------------
// Create EasyBlobStream
//------------------------------------------------------------------------------
function TEasyDataSet.CreateBlobStream(
    					Field: TField; Mode: TBlobStreamMode
//              s	: shortstring	= ''// hashed password for encryption;
              										// '' - no encryption
                                  ):TStream;
begin
 DBSession.LockSession;
 Result := nil;
 try
   if ((Mode <> bmRead) and (TEasyDataset(Field.DataSet).ReadOnly))
    then raise Exception.Create(
          'Error in TEasyDataset.CreateBlobStream - Dataset is read only!');
  // result := InternalCreateBlobStream(Field,Mode);

   result := TEasyBlobStream.Create(TBlobField(Field),Mode);
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.CreateBlobStream


//------------------------------------------------------------------------------
// Close blob stream
//------------------------------------------------------------------------------
procedure TEasyDataSet.CloseBlob(Field: TField);
{$include check_var.inc}
begin
 DBSession.LockSession;
 try
   chkfld_buffer := GetActiveRecordBuffer;
   if (chkfld_buffer = nil) then
    Exit;
   inc(chkfld_buffer,DMHandle.recNullOffset);
   chkfld_fieldNum := Field.FieldNo-1;
   // added by Leo Martin, 5.40
   // Projection for BLOB fields
   if (FProjection) then
    begin
     // physical field number
     if (chkfld_fieldNum >= 0) and (chkfld_fieldNum < FProjectionMap.ItemCount) then
      chkfld_fieldNum := FProjectionMap.Items[chkfld_fieldNum];
    end;
   if (blobFields[chkfld_fieldNum].stream = nil) then
    Exit;
   if (blobFields[chkfld_fieldNum].stream.size <= 0) then
    begin
     chkfld_set := true;
     {$include set_fields.inc}
    end
   else
    begin
     chkfld_set := false;
     {$include set_fields.inc}
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.CloseBlobStream


//------------------------------------------------------------------------------
// sets table position
//------------------------------------------------------------------------------
procedure TEasyDataset.SetTablePosition (value: Integer);
begin
 DBSession.LockSession;
 try
   if (tablePosition <> value) then
    ClearBLOBStreams;
   tablePosition := value;
 finally
   DBSession.UnlockSession;
 end;
end; // SetTablePosition


//------------------------------------------------------------------------------
// get current ID
//------------------------------------------------------------------------------
function TEasyDataset.GetCurrentID: Integer;
begin
 DBSession.LockSession;
 try
   CheckTableState;
   result := pInteger(DMHandle.allRecBuffer.GetRecordDataPtr(visibleRecords.items[tablePosition])+
              DMHandle.recordSize)^;
 finally
   DBSession.UnlockSession;
 end;
end; // GetCurrentID


//------------------------------------------------------------------------------
// get current record buffer
//------------------------------------------------------------------------------
function TEasyDataset.GetCurrentRecordBuffer: PAnsiChar;
begin
 DBSession.LockSession;
 try
   CheckTableState;
   result := DMHandle.allRecBuffer.GetRecordDataPtr(visibleRecords.items[tablePosition]);
 finally
   DBSession.UnlockSession;
 end;
end; // GetCurrentRecordBuffer


//------------------------------------------------------------------------------
// allocate memory for record buffer
//------------------------------------------------------------------------------
function TEasyDataSet.AllocRecordBuffer: TRecordBuffer;
begin
// Result := AllocMem(DMHandle.bufferSize);
 Result := AllocMem(FRecordSize);
 if (Result = nil) then raise Exception.Create(
     'Error in TEasyDataSet.AllocRecordBuffer - AllocMem returns 0 pointer.');
end;// TEasyDataSet.AllocRecordBuffer


//------------------------------------------------------------------------------
// free memory
//------------------------------------------------------------------------------
procedure TEasyDataSet.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
//if (debugFlag) then ShowMessage('free record buffer');
  if (Buffer <> nil) then
   FreeMem(Buffer);
  Buffer := nil;
end;// TEasyDataSet.FreeRecordBuffer


//------------------------------------------------------------------------------
// return record size in bytes
//------------------------------------------------------------------------------
function TEasyDataSet.GetRecordSize: Word;
begin
//if (debugFlag) then ShowMessage('get record size = '+IntToStr(DMHandle.recordSize));
 if (not isTableOpened) then raise Exception.Create(
     'Error in TEasyDataSet.GetRecordCount - no table was opened.');
// Result := DMHandle.bufferSize;
 Result := FRecordSize;
end;// TEasyDataSet.GetDMHandle.recordSize


//------------------------------------------------------------------------------
// return records quantity in table
//------------------------------------------------------------------------------
function TEasyDataSet.GetRecordCount: Integer;
begin
 DBSession.LockSession;
 Result := 0;
 try
  //if (debugFlag) then
  //ShowMessage('get record count = '+IntToStr(DMHandle.tableHeader.recordCount));
   if (not isTableOpened) then raise Exception.Create(
       'Error in TEasyDataSet.GetRecordCount - no table was opened.');
   CheckTableState;
   Result := visibleRecordCount;
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.GetRecordCount


//------------------------------------------------------------------------------
// define field descriptions (in TFieldDefs)
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalInitFieldDefs;
var i             : Integer;
    pFieldHeader  : pFieldHeaderType;
    required      : Boolean;
begin
 DBSession.LockSession;
 try
   // if projection is set field defs already exists
   if (FProjection) then Exit;
   FieldDefs.Clear;
   FRestructureFieldDefs.Clear;
   if (DMHandle = nil) then
    begin
     InternalOpen;
     InternalClose;
     exit;
    end;
  //ShowMessage('init defs: fcount='+IntToStr(DMHandle.tableHeader.fieldCount));
   for i := 0 to DMHandle.tableHeader.fieldCount-1 do
    begin
      pFieldHeader := pFieldHeaderType(DMHandle.fieldHeaderList.Items[i]);
      if (pFieldHeader = nil) then raise Exception.Create(
       'Error in TEasyDataSet.InternalInitFieldDefs - 0 pointer in DMHandle.fieldHeaderList.');
      required := pFieldHeader^.required;
     //add field def
     with FieldDefs do
      begin
       if (pFieldHeader^.fieldType = ftString) then
        begin
  //       Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize-1,required);
         Add(pFieldHeader^.fieldName,ftString,pFieldHeader^.fieldSize-1,required);
         FRestructureFieldDefs.Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize-1,required);
        end
       else
       if (pFieldHeader^.fieldType = ftWideString) then
        begin
  //       Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize-1,required);
         Add(pFieldHeader^.fieldName,ftWideString,pFieldHeader^.fieldSize-2,required);
         FRestructureFieldDefs.Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize-2,required);
        end
       else
       if (pFieldHeader^.fieldType = ftBytes) then
        begin
         Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize,required);
  //       FieldDefs[FieldDefs.Count-1].Size := pFieldHeader^.fieldSize;
         FRestructureFieldDefs.Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize,required);
        end
       else
        begin
         Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,0,required);
         FRestructureFieldDefs.Add(pFieldHeader^.fieldName,pFieldHeader^.fieldType,0,required);
        end;
      end; // with fieldDefs
    end;//for fields
    if (DMHandle.tableHeader.ShowAutoInc = AutoIncOn) then
     begin
    FieldDefs.Add(DMHandle.tableHeader.sequenceName,TFieldType(ftAutoInc),0,false);
    FRestructureFieldDefs.Add(DMHandle.tableHeader.sequenceName,TFieldType(ftAutoInc),0,false);
     end;
  //  FRestructureFieldDefs.Add(DMHandle.tableHeader.sequenceName,TFieldType(ftInteger),0,false);
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.InternalInitFieldDefs


//------------------------------------------------------------------------------
// open table, create fields, initiate fields
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalOpen;
var i : integer;
    iname,ifieldnames : AnsiString;
    bIndexSet: boolean;
begin
 DBSession.LockSession;
 try
{$IFDEF RECORD_ID_NAVIGATION}
FCurrentRecordID := INVALID_RECORD_ID;
{$ENDIF}
   FreezeVisibleRecords;
   try
    // create in-memory table in design-time?
    if (not FSettingProjection) then
     begin
      if (bDesignMode) then
       if (FInMemory and not Exists) then
        begin
         // if exists disk copy of this table - open it
         FInMemory := False;
         try
          // otherwise - create memory table
          if (not Exists) then
           begin
            FInMemory := True;
            InternalCreateTable;
           end;
         except
          FInMemory := True;
         end;
        end;
      OpenTable;
      TableState := DMHandle.tableHeader.state;
     end;
    isTableOpened:= true;
    InternalInitFieldDefs;
    if DefaultFields then
      CreateFields;
    if (not FDoNotBindFields) then
      BindFields(true);
    DBSession.LockSession;
//    if (DMHandle.bufferSize + CalcFieldsSize > DMHandle.bufferSize) then
//     DMHandle.bufferSize := DMHandle.bufferSize + CalcFieldsSize;
    FRecordSize := DMHandle.bufferSize;
    if (DMHandle.bufferSize + CalcFieldsSize > FRecordSize) then
     FRecordSize := FRecordSize + CalcFieldsSize;
    DBSession.UnlockSession;
    iname := FIndexName;
    ifieldnames := FIndexFieldNames;

    isIndexUsed := true;
    bIndexSet := false;
     if (iname <> '') then
      begin
       for i := 0 to IndexDefs.Count-1 do
        if (LowerCase(IndexDefs.Items[i].Name) = LowerCase(iname)) then
         begin
          SetIndexName(iname);
          bIndexSet := true;
          break;
         end;
      end
     else
     if (ifieldnames <> '') then
      begin
{       for i := 0 to IndexDefs.Count-1 do
        if (LowerCase(IndexDefs.Items[i].Fields) = LowerCase(ifieldnames)) then}
         begin
          SetIndexFieldNames(ifieldnames);
          bIndexSet := true;
//          break;
         end;
      end;
    if (not bIndexSet) then
     if ((ifieldnames = '') and (iname = '')) then
      begin
       SetIndexName('');
       SetIndexFieldNames('');
       currentIndex := 0;
      end
     else
      if (iname <> '') then
       raise Exception.Create('TEasyDataSet.InternalOpen - Invalid index name '''
                             +iname+'''')
      else
      if (ifieldnames <> '') then
       raise Exception.Create('TEasyDataSet.InternalOpen - Invalid index field names '''
                             +ifieldnames+'''');
    AllocKeyBuffers;
   finally
    UnfreezeVisibleRecords;
   end;
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.InternalOpen


//------------------------------------------------------------------------------
// close table, destroy fields
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalClose;
begin
 DBSession.LockSession;
 try

   FreeKeyBuffers;
   if (not FDoNotBindFields) then
     BindFields(false);
   if DefaultFields then
      DestroyFields;

   if (not isTableOpened) then
    Exit;

   if (not FSettingProjection) then
    CloseTable;

   FProjection := false;
 finally
   DBSession.UnlockSession;
 end;
end; // TEasyDataSet.InternalClose


//------------------------------------------------------------------------------
// return true if table is opened
//------------------------------------------------------------------------------
function TEasyDataSet.IsCursorOpen:Boolean;
begin
//if (debugFlag) then ShowMessage('is cursor open? ');
 Result := isTableOpened;
end;// TEasyDataSet.IsCursorOpen


{$IFDEF D21H}
//------------------------------------------------------------------------------
// Initiate record buffer
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalInitRecord(Buffer: TRecBuf);
begin
 DBSession.LockSession;
 try
   FillChar (PAnsiChar(Buffer)^,DMHandle.recInfobufferSize,$00);

   //setting all field values to null
   FillChar(pAnsiChar(Buffer+DMHandle.recNullOffset)^,DMHandle.fieldFlagsSize,$FF);
   pInteger(Buffer+DMHandle.recordSize)^ := LastAutoIncValue+1;
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.InternalInitRecord
{$ELSE}
//------------------------------------------------------------------------------
// Initiate record buffer
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalInitRecord(Buffer: TRecordBuffer);
begin
 DBSession.LockSession;
 try
   FillChar (Buffer^,DMHandle.recInfobufferSize,$00);

   //setting all field values to null
   FillChar(pAnsiChar(Buffer+DMHandle.recNullOffset)^,DMHandle.fieldFlagsSize,$FF);
   pInteger(Buffer+DMHandle.recordSize)^ := LastAutoIncValue+1;
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.InternalInitRecord
{$ENDIF}


//------------------------------------------------------------------------------
// handle exceptions
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalHandleException;
begin
 Application.HandleException(Self);
end;// InternalHandleExceptions


//------------------------------------------------------------------------------
// set current record number
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetRecNo(Value: Integer);
var
  Count: Cardinal;
begin
 DBSession.LockSession;
 try
   if (not isTableOpened) then raise Exception.Create(
       'Error in TEasyDataSet.SetRecNo - no table was opened.');
   if (DMHandle.tableHeader.recordCount <= 0) then
    Exit;
   if (value < 1) or (value > DMHandle.tableHeader.recordCount) then
    Exit;
   if (Active) then
     if (Value <> RecNo) then
        begin
         DoBeforeScroll;
         tablePosition := Value-1;

         // ET 5.40 - added search closest record with OnFilterRecord=true
         if (Filtered and Assigned(OnFilterRecord)) then
          if (not FilterRecord(TRecordBuffer(DMHandle.allRecBuffer.GetRecordDataPtr(
                    visibleRecords.items[tablePosition])))) then
           begin
            DisableControls;
            First;
            Count := 1;
            while ((not Eof) and (Count < value)) do
             begin
              Next;
              Inc(Count);
             end;
            EnableControls;
           end;

         Resync([rmCenter, rmExact]);
         DoAfterScroll;
        end;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.SetRecNo


//------------------------------------------------------------------------------
// return current record number
//------------------------------------------------------------------------------
function TEasyDataSet.GetRecNo: Integer;
var id: integer;
begin
 DBSession.LockSession;
 Result := 0;
 try
  // if (debugFlag) then ShowMessage('get recNo');
   if (not isTableOpened) then raise Exception.Create(
       'Error in TEasyDataSet.GetRecNo - no table was opened.');
    CheckActive;

   CheckTableState;
   if (visibleRecordCount <= 0) then
    result := 0
   else
   if Pointer(ActiveBuffer) = nil then
    result := 1
   else
    begin
     Move(PAnsiChar(ActiveBuffer+DMHandle.recordSize)^,id,sizeOf(integer)); //id
     tablePosition := GetTablePositionByID(id);
     if (tablePosition >= 0) then
      Result := tablePosition+1
     else
     if (state = dsInsert) then
      Result := DMHandle.tableHeader.recordCount+1
     else
      Result := 0;
    end;

   ClearBLOBStreams;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.GetRecNo


//------------------------------------------------------------------------------
// set table position by physical record No
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetTablePositionByPhysRecNo(physRecNo: integer);
var pos,l,h : integer;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 DBSession.LockSession;
 try
   CheckTableState;
   findValIns_recordBuffer := DMHandle.allRecBuffer.GetRecordDataPtr(physRecNo);
   DMHandle.allRecBuffer.LockRecordPage(physRecNo);
   findValIns_array := aInteger(visiblerecords.items);
   findValIns_pIndex := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex]);
   findValIns_recCount := visibleRecordCount;
   findValIns_ignoreCase := false;
   findValIns_partialCompare := false;
   findValIns_search := false;
   {$include find_ind.inc}
   DMHandle.allRecBuffer.UnlockRecordPage(physRecNo);
   pos := findValIns_result;
   // if pos corresponds specified record - return pos
   if (visiblerecords.items[pos] = physRecNo) then
    begin
     tablePosition := pos;
     Exit;
    end;
   l := pos-1;
   h := pos+1;
   while (h < visibleRecordCount-1) or (l >= 0) do
    begin
     if (l >= 0) then
       if (visibleRecords.items[l] = physRecNo) then
        begin
         tablePosition := l;
        //aaStopTime;
         Exit;
        end;
     if (h < recordCount) then
       if (visibleRecords.items[h] = physRecNo) then
        begin
         tablePosition := h;
        //aaStopTime;
         Exit;
        end;
     dec(l);
     inc(h);
    end;

    raise Exception.Create('TEasyDataSet.SetTablePositionByPhysRecNo - record not found, physRecNo = '+
    inttostr(physRecNo)+', result = '+inttostr(findValIns_result)+', recCount = '+
    inttostr(visibleRecordCount));
  //   tablePosition := FindIndexValueForDelete(visibleRecords.items,physRecNo,
  //            visibleRecordCount);
    ClearBLOBStreams;
 finally
   DBSession.UnlockSession;
 end;
end;//TEasyDataSet.SetTablePositionByPhysRecNo


//------------------------------------------------------------------------------
// get table position by physical record No
//------------------------------------------------------------------------------
function TEasyDataSet.GetTablePositionByPhysRecNo(physRecNo: integer): integer;
var pos,l,h : integer;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 DBSession.LockSession;
 try
   CheckTableState;
   findValIns_recordBuffer := DMHandle.allRecBuffer.GetRecordDataPtr(physRecNo);
   DMHandle.allRecBuffer.LockRecordPage(physRecNo);
   findValIns_array := aInteger(visiblerecords.items);
   findValIns_pIndex := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex]);
   findValIns_recCount := visibleRecordCount;
   findValIns_ignoreCase := false;
   findValIns_partialCompare := false;
   findValIns_search := false;
   {$include find_ind.inc}
   DMHandle.allRecBuffer.UnlockRecordPage(physRecNo);
   pos := findValIns_result;

   // added by Leo Martin, 5.40
   // to avoid invalid position
   if (pos < 0) or (pos >= visibleRecords.ItemCount) then
    begin
     result := -1;
     Exit;
    end;

   // if pos corresponds specified record - return pos
   if (visiblerecords.items[pos] = physRecNo) then
    begin
     result := pos;
     Exit;
    end;
   l := pos-1;
   h := pos+1;
   while (h < visibleRecordCount) or (l >= 0) do
    begin
     if (l >= 0) then
       if (visibleRecords.items[l] = physRecNo) then
        begin
         result := l;
        //aaStopTime;
         Exit;
        end;
     if (h < visibleRecordCount) then
       if (visibleRecords.items[h] = physRecNo) then
        begin
         result := h;
        //aaStopTime;
         Exit;
        end;
     dec(l);
     inc(h);
    end;
  {  raise Exception.Create('TEasyDataSet.GetTablePositionByPhysRecNo - record not found, physRecNo = '+
    inttostr(physRecNo)+', result = '+inttostr(findValIns_result)+', recCount = '+
    inttostr(visibleRecordCount));
    }
    result := -1;
 finally
   DBSession.UnlockSession;
 end;
end;//TEasyDataSet.GetTablePositionByPhysRecNo


//------------------------------------------------------------------------------
// read record to buffer, getMode = {gmPrior, gmCurrent, gmNext}
//------------------------------------------------------------------------------
function TEasyDataSet.GetRecord(Buffer: TRecordBuffer;
             GetMode: TGetMode; DoCheck: Boolean):TGetResult;
var Acceptable : Boolean;
    id,old : Integer;
begin
 DBSession.LockSession;
 Result := grError;
 try
   if (not isTableOpened) then raise Exception.Create(
       'Error in TEasyDataSet.GetRecord - no table was opened.');
   CheckTableState;

   if (visibleRecordCount <= 0) then
    begin
     Result := grEOF;
     Exit;
    end;
{$IFDEF DEBUG_FLAG_GETRECORD}
aaWriteToLog('GetRecord #0,  GetMode = '+IntToStr(Byte(GetMode)));
{$ENDIF}
  if (not FSetActiveBufferFlag) then
  begin
   if (Pointer(ActiveBuffer) <> nil) and (Active) then
    begin
     if (CurrentRecord < BufferCount) and (CurrentRecord >= 0) then
      begin
       Move(PAnsiChar(Buffers[CurrentRecord]+DMHandle.recordSize)^,id,sizeOf(integer)); //id
{$IFDEF RECORD_ID_NAVIGATION}
 if (FCurrentRecordID <> INVALID_RECORD_ID) then
  begin
   id := FCurrentRecordID;
   FCurrentRecordID := INVALID_RECORD_ID;
{$IFDEF DEBUG_FLAG_GETRECORD}
aaWriteToLog('GetRecord #4,  id = '+IntToStr(id));
{$ENDIF}
  end;
{$ENDIF}
       if (LongWord(id) < LastAutoIncValue+1) then
        begin
         old := tablePosition;
         tablePosition := GetTablePositionByID(id);
{$IFDEF DEBUG_FLAG_GETRECORD}
aaWriteToLog('GetRecord #1,  id = '+IntToStr(id)+', old = '+
IntToStr(old)+', tablePosition = '+IntToStr(tablePosition));
{$ENDIF}
         if (tablePosition < 0) then
          tablePosition := old;
        end
       else
        begin
        tablePosition := visibleRecordCount;
{$IFDEF DEBUG_FLAG_GETRECORD}
aaWriteToLog('GetRecord #1.1,  id = '+IntToStr(id)+', old = '+
IntToStr(old)+', tablePosition = '+IntToStr(tablePosition));
{$ENDIF}

      end;
   end;
  end;
  end;

   ClearBLOBStreams;

     Acceptable := false;
     Result := grOk;
    repeat
     begin
       case GetMode of
        gmPrior:
          begin
           if (tablePosition <= 0) then
            begin
             Result := grBOF;
             tablePosition := -1;
            end
           else
             Dec(tablePosition);
          end; //gmPrior
        gmCurrent:
          begin
           if (tablePosition < 0) or (tablePosition >= visibleRecordCount) then
            Result := grError;
  {         if (VisibleRecordCount > 0) then
            begin
             if (tablePosition < 0) then
              Result := grBOF
             else
              if (tablePosition >= visibleRecordCount) then
               Result := grEOF
            end
           else
            Result := grError;}
          end;
        gmNext:
          begin
           if (tablePosition >= visibleRecordCount-1) then
            Result := grEOF
           else
            Inc(tablePosition);
          end;
       end; //case GetMode
       if (Result = grOk) then
        begin

          InternalInitRecord(Buffer);
          Move(PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
                    visibleRecords.items[tablePosition]))^,
                    Buffer^,
                    DMHandle.recInfoBufferSize
                    );


          ClearCalcFields(Buffer);
          GetCalcFields(Buffer);
         with pBookmarkInfoType(Buffer + DMHandle.recInfoBufferSize)^ do
          begin
           BookmarkData :=  pRecordInfoType(Buffer+DMHandle.recordSize)^.id;
           BookmarkFlag := bfCurrent;
          end;
{$IFDEF DEBUG_FLAG_GETRECORD}
aaWriteToLog('GetRecord #2,  tablePosition = '+IntToStr(tablePosition)+', recordID = '+
IntToStr(pRecordInfoType(Buffer+DMHandle.recordSize)^.id));
{$ENDIF}
          if (Filtered) then
           Acceptable:=FilterRecord(Buffer)
          else
           Acceptable := true;
         if ((GetMode=gmCurrent) and (not Acceptable)) then
           Result:=grError;
        end; // grOk
      end;
     until (Result<>grOk) or Acceptable;
     if (result = grError) and DoCheck then
       raise Exception.Create('TEasyDataSet.GetRecord - No records');
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.GetRecord



//-------------------------------------------------------------------------------
// format conversion
//-------------------------------------------------------------------------------
{$IFDEF D17H}
 {$IFDEF D18H}
  procedure TEasyDataset.DataConvert(Field: TField; Source: TValueBuffer; var Dest: TValueBuffer; ToNative: Boolean);
 {$ELSE}
  procedure TEasyDataset.DataConvert(Field: TField; Source, Dest: TValueBuffer; ToNative: Boolean);
 {$ENDIF}
var l,x: Cardinal;
    ptr: PAnsiChar;

  procedure ProcessWideStringOrWideMemo(WideMemo: Boolean);
  {$IFDEF D10H}
  var len: Integer;
      src: PAnsiChar;
      w:   Word;
  {$ENDIF}
  begin
    {$IFDEF D10H}
    w := 0;
    {$ENDIF}
    if ToNative then
     {$IFDEF D10H}
     begin
       len := GetStrLength(PAnsiChar(Source),True);
       Move(PAnsiChar(Source)^,PAnsiChar(Dest)^,len);
       Move(w,PAnsiChar(PAnsiChar(Dest)+len)^,SizeOf(w));
     end
     {$ELSE}
     Move(Source^,Dest^,Sizeof(PWideChar))
     {$ENDIF}
    else
     begin
      {$IFDEF D10H}
//      WideString(Dest^) := WideString(PWideChar(Source)^);
      src := PAnsiChar(PAnsiChar(Source)^);
      len := GetStrLength(src,True);
      Move(src^,PAnsiChar(Dest)^,len);
      Move(w,PAnsiChar(PAnsiChar(Dest)+len)^,SizeOf(w));
      {$ELSE}
      WideString(Dest^) := WideString(PWideChar(Source^));
      {$ENDIF}
     end;
  end; // ProcessWideStringOrWideMemo


begin
  case Field.DataType of
   ftWideString:
      ProcessWideStringOrWideMemo(False)
   else
     inherited DataConvert(Field, Source, Dest, ToNative);
  end;
end;// TEasyDataset.DataConvert

{$ELSE}
//-------------------------------------------------------------------------------
// format conversion
//-------------------------------------------------------------------------------
procedure TEasyDataset.DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);
var l,x: Cardinal;
    ptr: PAnsiChar;

  procedure ProcessWideStringOrWideMemo(WideMemo: Boolean);
  {$IFDEF D10H}
  var len: Integer;
      src: PAnsiChar;
      w:   Word;
  {$ENDIF}
  begin
    {$IFDEF D10H}
    w := 0;
    {$ENDIF}
    if ToNative then
     {$IFDEF D10H}
     begin
       len := GetStrLength(Source,True);
       Move(Source^,Dest^,len);
       Move(w,PAnsiChar(PAnsiChar(Dest)+len)^,SizeOf(w));
     end
     {$ELSE}
     Move(Source^,Dest^,Sizeof(PWideChar))
     {$ENDIF}
    else
     begin
      {$IFDEF D10H}
//      WideString(Dest^) := WideString(PWideChar(Source)^);
      src := PAnsiChar(Source^);
      len := GetStrLength(src,True);
      Move(src^,Dest^,len);
      Move(w,PAnsiChar(PAnsiChar(Dest)+len)^,SizeOf(w));
      {$ELSE}
      WideString(Dest^) := WideString(PWideChar(Source^));
      {$ENDIF}
     end;
  end; // ProcessWideStringOrWideMemo


begin
  case Field.DataType of
   ftWideString:
      ProcessWideStringOrWideMemo(False)
   else
     inherited DataConvert(Field, Source, Dest, ToNative);
  end;
end;// TEasyDataset.DataConvert
{$ENDIF}




//-------------------------------------------------------------------------------
// prepare key and range field description when index is opened
//-------------------------------------------------------------------------------
procedure TEasyDataset.AllocKeyBuffers;
var
  KeyIndex: TKeyIndex;
begin
  try
    for KeyIndex := Low(TKeyIndex) to High(TKeyIndex) do
      FKeyBuffers[KeyIndex] := InitKeyBuffer(
//        AllocMem(SizeOf(TKeyBuffer) + DMHandle.bufferSize));
        AllocMem(SizeOf(TKeyBuffer) + FRecordSize));
  except
    FreeKeyBuffers;
    raise;
  end;
  IsRanged := false;  //when index changed range is cancelled
end;  //AllocKeyBuffers


//-------------------------------------------------------------------------------
// free memory from key and range field description when index is closed
//-------------------------------------------------------------------------------
procedure TEasyDataset.FreeKeyBuffers;
var
  KeyIndex: TKeyIndex;
begin
  for KeyIndex := Low(TKeyIndex) to High(TKeyIndex) do
  if (FKeyBuffers[KeyIndex] <> nil) then
   begin
//    DisposeMem(FKeyBuffers[KeyIndex], SizeOf(TKeyBuffer) + DMHandle.bufferSize);
    FreeMem(FKeyBuffers[KeyIndex]);
    FKeyBuffers[KeyIndex] := nil;
   end;
end;// TEasyDataset.FreeKeyBuffers;


//-------------------------------------------------------------------------------
// clear old information from key buffer
//-------------------------------------------------------------------------------
function TEasyDataset.InitKeyBuffer(Buffer: PKeyBuffer): PKeyBuffer;
begin
  FillChar(Buffer^, SizeOf(TKeyBuffer) + FRecordSize, 0);
//  FillChar(Buffer^, SizeOf(TKeyBuffer) + DMHandle.bufferSize, 0);
  InternalInitRecord(TRecordBuffer(PAnsiChar(Buffer) + SizeOf(TKeyBuffer)));
  Buffer^.FieldCount := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.indexCount;
  Buffer^.Exclusive := false;
  Result := Buffer;
end;

//-------------------------------------------------------------------------------
//  Findkey - search on fields in current index
//-------------------------------------------------------------------------------
function TEasyDataset.FindKey(const KeyValues: array of const): Boolean;
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  SetKeyFields(kiLookup, KeyValues);
  Result := GotoKey;
 finally
   DBSession.UnlockSession;
 end;
end;  //Findkey


//-------------------------------------------------------------------------------
//  FindNearest - search for the record with equal or great values then key values
//-------------------------------------------------------------------------------
procedure TEasyDataset.FindNearest(const KeyValues: array of const);
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  SetKeyFields(kiLookup, KeyValues);
  GotoNearest;
 finally
   DBSession.UnlockSession;
 end;
end;   //FindNearest


//-------------------------------------------------------------------------------
// search record when key values are assigned
//-------------------------------------------------------------------------------
function TEasyDataset.GotoKey: Boolean;
var i: integer;
  RecBuffer: PAnsiChar;
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  DoBeforeScroll;
  CursorPosChanged;
  RecBuffer := PAnsiChar(FKeyBuffers[kiLookup]) + SizeOf(TKeyBuffer);
  i := FindInVisibleRecords(RecBuffer, FKeyBuffers[kiLookup]^.FieldCount, false, true);
  if (i >= 0) then
  begin
    tablePosition := i;
    result := true;
  end
  else
    result := false;
  if Result then
   begin
    Resync([rmExact, rmCenter]);
    DoAfterScroll;
   end;
 finally
   DBSession.UnlockSession;
 end;
end;  //GotoKey


//-------------------------------------------------------------------------------
// search nearest record when key values are assigned
//-------------------------------------------------------------------------------
procedure TEasyDataset.GotoNearest;
var i: integer;
  RecBuffer: PAnsiChar;
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  SetState(dsBrowse);
  CursorPosChanged;
  RecBuffer := PAnsiChar(FKeyBuffers[kiLookup]) + SizeOf(TKeyBuffer);
  i := FindInVisibleRecords(RecBuffer, FKeyBuffers[kiLookup]^.FieldCount, false, false);
  if (i >= 0) then
  begin
    tablePosition := i;
{    if (Active) then
    begin
      SetActiveBuffer;
      Refresh;
    end;}
    Resync([rmCenter]);
    DoAfterScroll;
  end;
 finally
   DBSession.UnlockSession;
 end;
end; //GotoNearest


//-------------------------------------------------------------------------------
// set dataset State to dsSetKey and clear key buffer
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetKey;
begin
  SetKeyBuffer(kiLookup, True);
end;  //SetKey


//-------------------------------------------------------------------------------
// set dataset state to dsSetKey without clearing key buffer
//-------------------------------------------------------------------------------
procedure TEasyDataset.EditKey;
begin
  SetKeyBuffer(kiLookup, False);
end;  //EditKey


//-------------------------------------------------------------------------------
// set key buffer, set dsSetKey mode
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetKeyBuffer(KeyIndex: TKeyIndex; Clear: Boolean);
begin
  CheckBrowseMode;
  FKeyBuffer := FKeyBuffers[KeyIndex];
  if Clear then InitKeyBuffer(FKeyBuffer);
  SetState(dsSetKey);
  DataEvent(deDataSetChange, 0);
end;   //SetKeyBuffer


//-------------------------------------------------------------------------------
// check dsSetKey mode, raise an exception if no
//-------------------------------------------------------------------------------
procedure TEasyDataset.CheckSetKeyMode;
begin
  if State <> dsSetKey then
    raise Exception.Create('TEasyDataset.CheckSetKeyMode: Current state is not dsSetKey');
end;  //CheckSetKeyMode


//-------------------------------------------------------------------------------
// return number of assigned key values
//-------------------------------------------------------------------------------
function TEasyDataset.GetKeyFieldCount: Integer;
begin
  CheckSetKeyMode;
  Result := FKeyBuffer^.FieldCount;
end;  //GetKeyFieldCount


//-------------------------------------------------------------------------------
// set number of key values for GotoKey or GotoNearest methods
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetKeyFieldCount(Value: Integer);
begin
  CheckSetKeyMode;
  FKeyBuffer^.FieldCount := Value;
end;  //SetKeyFieldCount


//-------------------------------------------------------------------------------
// move key value to internal key buffer
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetKeyFields(KeyIndex: TKeyIndex;
  const Values: array of const);
var
  I: Integer;
  SaveState: TDataSetState;
  Fld: TField;
begin
 DBSession.LockSession;
 try
  SaveState := SetTempState(dsSetKey);
  try
    FKeyBuffer := InitKeyBuffer(FKeyBuffers[KeyIndex]);
    for I := 0 to High(Values) do
     begin
      Fld := GetIndexField(I);
      if (Fld.DataType <> ftAutoInc) then
        Fld.AssignValue(Values[I])
      else
        pInteger(GetActiveRecordBuffer+DMHandle.recordSize)^ := Values[I].VInteger;
     end;
    FKeyBuffer^.FieldCount := High(Values) + 1;
  finally
    RestoreState(SaveState);
  end;
 finally
   DBSession.UnlockSession;
 end;
end;  //SetKeyFields


//-------------------------------------------------------------------------------
// check if range bounds are include in range
//-------------------------------------------------------------------------------
function TEasyDataset.GetKeyExclusive: Boolean;
begin
  CheckSetKeyMode;
  Result := FKeyBuffer.Exclusive;
end;  //GetKeyExclusive


//-------------------------------------------------------------------------------
// include/exclude range bounds in range
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetKeyExclusive(Value: Boolean);
begin
  CheckSetKeyMode;
  FKeyBuffer.Exclusive := Value;
end;  //SetKeyExclusive


//-------------------------------------------------------------------------------
// Set Range of records
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetRange(const StartValues, EndValues: array of const);
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  SetKeyFields(kiRangeStart, StartValues);
  SetKeyFields(kiRangeEnd, EndValues);
  ApplyRange;
 finally
   DBSession.UnlockSession;
 end;
end;  //SetRange


//-------------------------------------------------------------------------------
// set dsSetKey state for editing start range bound
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetRangeStart;
begin
  SetKeyBuffer(kiRangeStart, True);
end; //SetRangeStart


//-------------------------------------------------------------------------------
// set dsSetKey state for editing end range bound
//-------------------------------------------------------------------------------
procedure TEasyDataset.SetRangeEnd;
begin
  SetKeyBuffer(kiRangeEnd, True);
end;  //SetRangeEnd


//-------------------------------------------------------------------------------
// set dsSetKey state for continue editing start range bound
//-------------------------------------------------------------------------------
procedure TEasyDataset.EditRangeStart;
begin
  SetKeyBuffer(kiRangeStart, False);
end;  //EditRangeStart


//-------------------------------------------------------------------------------
// set dsSetKey state for continue editing end range bound
//-------------------------------------------------------------------------------
procedure TEasyDataset.EditRangeEnd;
begin
  SetKeyBuffer(kiRangeEnd, False);
end;  //EditRangeEnd


//-------------------------------------------------------------------------------
// refresh records visibility when range is applied
//-------------------------------------------------------------------------------
procedure TEasyDataset.ApplyRange;
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  SetState(dsBrowse);
  if SetCursorRange then First;
 finally
   DBSession.UnlockSession;
 end;
end;  //ApplyRange


//-------------------------------------------------------------------------------
// refresh records visibility when range is cancelled
//-------------------------------------------------------------------------------
procedure TEasyDataset.CancelRange;
begin
 DBSession.LockSession;
 try
  CheckBrowseMode;
  SetState(dsBrowse);
  UpdateCursorPos;
  if ResetCursorRange then Resync([]);
 finally
   DBSession.UnlockSession;
 end;
end;  //CancelRange


//-------------------------------------------------------------------------------
// internal function for reset cursor range
//-------------------------------------------------------------------------------
function TEasyDataset.ResetCursorRange: Boolean;
begin
 DBSession.LockSession;
 try
  IsRanged := false;
  CreateVisibleRecordsList;
  Result := true;
  if (Active) then
  begin
    SetActiveBuffer;
    Refresh;
  end;
 finally
   DBSession.UnlockSession;
 end;
end;  //ResetCursorRange


//-------------------------------------------------------------------------------
// internal function for set cursor range
//-------------------------------------------------------------------------------
function TEasyDataset.SetCursorRange: Boolean;
begin
 DBSession.LockSession;
 try
  IsRanged := true;
  CreateVisibleRecordsList;
  Result := true;
  if (Active) then
  begin
    SetActiveBuffer;
    Refresh;
  end;
 finally
   DBSession.UnlockSession;
 end;
end;  //SetCursorRange

{
procedure TEasyDataSet.DoDataEvent(Event: TDataEvent; Info: integer);
begin
 DataEvent(Event,Info);
end;
}


//------------------------------------------------------------------------------
// sets projection on the dataset
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetProjection(
        FieldList: TStringList;
        AliasList: TStringList;
        OnlyStoreLists: Boolean = False
        );
var i,j,k,l:         Integer;
    pFieldHeader:    pFieldHeaderType;
    required,bFound: Boolean;
    name,newName,
    s,s1:            AnsiString;
    bOk:             Boolean;
begin
 DBSession.LockSession;
 try
   FProjectionFieldList.Text := FieldList.Text;
   FProjectionAliasList.Text := AliasList.Text;

   // only store field and alias lists - to use them later?
   if (OnlyStoreLists) then
    exit;
  //       FRestructureFieldDefs.Add(AliasList.Strings[j],TFieldType(ftInteger),0,false);
   FieldDefs.Clear;
   FRestructureFieldDefs.Clear; // will be empty
   FProjectionMap.SetSize(0);

   if (DMHandle = nil) then
    begin
     InternalOpen;
    end;
  //ShowMessage('init defs: fcount='+IntToStr(DMHandle.tableHeader.fieldCount));
   for j := 0 to FieldList.Count-1 do
    begin
     name := FieldList.Strings[j];
     newName := AliasList.Strings[j];
     if (UpperCase(name) = UpperCase(DMHandle.tableHeader.sequenceName)) then
      begin
       if (newName = '') then
        FieldDefs.Add(DMHandle.tableHeader.sequenceName,TFieldType(ftAutoInc),0,false)
       else
        FieldDefs.Add(newName,TFieldType(ftAutoInc),0,false);
       FProjectionMap.Append(-1); // sequence
       continue;
      end; // sequence field
     // normal field
     bFound := false;
     for i := 0 to DMHandle.tableHeader.fieldCount-1 do
      begin
        pFieldHeader := pFieldHeaderType(DMHandle.fieldHeaderList.Items[i]);
        if (pFieldHeader = nil) then
         raise ETblException.Create(00012,[FTableName,i],self);
        if (UpperCase(pFieldHeader^.fieldName) <> UpperCase(name)) then
         continue;
        // field found !!!
        FProjectionMap.Append(i); // sequence
        bFound := true;
        if (newName = '') then
         newName := name;
  //       newName := pFieldHeader^.fieldName;
        required := pFieldHeader^.required;
        k := 1;
        s1 := newName;
        repeat
        s := UpperCase(newName);
        bOk := true;
         for l := 0 to FieldDefs.Count-1 do
          if (UpperCase(FieldDefs.Items[l].Name) = s) then
           begin
            newName := s1 + '_' + IntToStr(k);
            inc(k);
            bOk := false;
            break;
           end;
        until bOk;
        //add field def
        with FieldDefs do
         begin
          if (pFieldHeader^.fieldType = ftString) then
           begin
            Add(newName,ftString,pFieldHeader^.fieldSize-1,required);
           end
          else
          if (pFieldHeader^.fieldType = ftWideString) then
           begin
            Add(newName,ftWideString,pFieldHeader^.fieldSize-2,required);
           end
          else
          if (pFieldHeader^.fieldType = ftBytes) then
           begin
            Add(newName,pFieldHeader^.fieldType,pFieldHeader^.fieldSize,required);
           end
          else
           begin
            Add(newName,pFieldHeader^.fieldType,0,required);
           end;
         end; // with fieldDefs
        break;
      end;//for fields
     if (not bFound) then
      raise ETblException.Create(00013,[FTableName,name],self);
    end; // for projection fields

   FSettingProjection := True;
   try
  {$IFDEF FULL_VERSION}
    if (Self is TEasyQuery) then
     TEasyQuery(Self).InternalCloseAsTable
    else
  {$ENDIF}
     Close;
    FProjection := True;
  {$IFDEF FULL_VERSION}
    if (Self is TEasyQuery) then
     TEasyQuery(Self).InternalOpenAsTable
    else
  {$ENDIF}
     Open;
   finally
    FSettingProjection := False;
   end;
 finally
   DBSession.UnlockSession;
 end;
end; // SetProjection


//------------------------------------------------------------------------------
// switches on projection on the dataset
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetProjection;
begin
  // set projection
  if (FProjectionFieldList.Count > 0) then
     SetProjection(FProjectionFieldList, FProjectionAliasList);
end;// SetProjection


//------------------------------------------------------------------------------
// sets distinct on the dataset
// if FieldList is empty then distinct will be cancelled
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetDistinct(
        DistinctFields: AnsiString
        );
begin
 DBSession.LockSession;
 try
   FDistinctFields := DistinctFields;
   FDistinctIndexNo := -1;
   if (Active) then
    Refresh;
  {
       x := FindInIndex(pBuffer,i,
           pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexCount,
           true,true);
   }
 finally
   DBSession.UnlockSession;
 end;
end; // SetDistinct


//------------------------------------------------------------------------------
// returns field value or its copy
// FieldNo is zero based
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetFieldValue(
                        var value: TETblDataValue;
                        FieldNo: Integer;
                        bCopy: Boolean = false);
var
    SourceBuffer : PAnsiChar;
    pDT : pDateTime;
    tStamp : TTimeStamp;
    bs: TStream;
    physRecNo, id: integer;
//    Field1: TBlobField;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
 chkfld_result : Boolean;
begin
 DBSession.LockSession;
 try
  //aaStopTime;

   // removed to be compatible with AOTable and SQL filter
  {
   if (FProjection) then
    begin
     // physical field number
     if (FieldNo >= 0) and (FieldNo < FProjectionMap.ItemCount) then
      FieldNo := FProjectionMap.Items[FieldNo];
     // sequence field
    end;
   }
   if (DMHandle = nil) then
    raise Exception.Create('TEasyDataSet.GetFieldValue - DMHandle = nil');
   // sequence field
   if (FieldNo = -1) then
     FieldNo := DMHandle.tableHeader.fieldCount;

   value.IsDataLinked := not bCopy;
   chkfld_set := True;
   value.IsNull := chkfld_set;
   value.pData := nil;
   if (not FDirectAccessForGetFieldValue) then
    SourceBuffer := GetActiveRecordBuffer
   else
    SourceBuffer := DMHandle.allRecBuffer.GetRecordDataPtr(tablePhysRecNo);

   value.DataSize := 0;

   if (not isTableOpened) then
    raise ETblException.Create(00007,[FTableName],self);

   if (SourceBuffer = nil) then
    raise ETblException.Create(00008,[FTableName],self);

   if (FieldNo = DMHandle.tableHeader.fieldCount) then
    begin
     // auto inc
     value.IsNull := false;
     value.DataSize := sizeof(Integer);
     value.DataType := ftAutoInc;
     if (not bCopy) then
      value.pData := PAnsiChar(SourceBuffer+DMHandle.recordSize)
     else
      begin
       value.pData := AllocMem(sizeOf(integer));
       Move(PAnsiChar(SourceBuffer+DMHandle.recordSize)^,pAnsiChar(value.pData)^,sizeOf(integer)); //id
      end;   // copy value
  //aaStartTime;
     Exit; // return id
    end;

   // if field number is invalid - return false
   if (FieldNo < 0) or (FieldNo > DMHandle.tableHeader.fieldCount) then
    begin
     raise ETblException.Create(00009,[FTableName,FieldNo],self);
     Exit;
    end;

    value.DataType := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType;
  //  value.DataType := Fields[FieldNo].DataType;

  // no calc and lookup fields !!!

   // check fields (is null)
   chkfld_buffer := pAnsiChar(SourceBuffer+DMHandle.recNullOffset);
   chkfld_fieldNum := FieldNo;
   {$include check_fields.inc}

   if (chkfld_result) then
    begin
     // null flag set earlier
  //aaStartTime;
     Exit; //null
    end;

   value.IsNull := false;
   // BLOB value
   if ( (value.DataType = ftBLOB) or
        (value.DataType = ftMemo) or
        (value.DataType = ftFmtMemo) or
        (value.DataType = ftGraphic))
        then
         begin

  //           bs := TEasyBLOBStream.Create(FieldNo,bmRead);

  //------------------------------------------------------------------------------
  // THIS WILL NOT WORK FOR FILTERS IN QUERIES ON SINGLE TABLE WITH BLOB FIELDS !!!
  // FIELDS OBJECTS CANNOT BE USED IN INACTIVE MODE !!!
  //------------------------------------------------------------------------------
               Move(PAnsiChar(SourceBuffer+DMHandle.recordSize)^,id,sizeOf(integer));
               physRecNo := GetTablePositionByID(id, True, True);
               bs := TMemoryStream.Create;
               try
                  DMHandle.aaReadBLOBValue(bs,FieldNo,physRecNo);
// 6.20
//                  value.DataSize := bs.Size;
                  if (bs.Size > 0) then
                   begin
                    value.DataSize := bs.Size;
                    value.pData := AllocMem(value.DataSize);
                    Move (pAnsiChar(TMemoryStream(bs).Memory)^,value.pData^,value.DataSize);
                   end;
               finally
                bs.Free;
               end;

  //           bs := TEasyBLOBStream.Create(TBlobField(Fields[FieldNo]),bmRead);
  //           value.DataSize := bs.Fstream.Size;
  //           value.pData := AllocMem(value.DataSize);
  //           Move (pAnsiChar(bs.Fstream.Memory)^,value.pData^,value.DataSize);
  {
            if (bCopy) then
             begin
              value.pData := AllocMem(value.DataSize);
            Move (pAnsiChar(bs.Fstream.Memory)^,value.pData^,value.DataSize);
             end
            else
             begin
              value.pData := bs.Fstream.Memory;
             end;
  }
  //        bs.Free;
          value.IsDataLinked := false;
  //aaStartTime;
          Exit;
         end; // BLOB

   if (DMHandle.fieldHeaderList.Items[FieldNo] = nil) then
    raise ETblException.Create(00010,[FTableName,FieldNo],self);

   value.DataSize := pFieldHeaderType(
      DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize;

   // move this field data from active buffer to buffer
   if (bCopy) then
    begin
     if (value.DataType = ftString)then
      value.pData := AllocMem(value.DataSize+1)
     else
     if (value.DataType = ftWideString) then
      value.pData := AllocMem(value.DataSize+2)
     else
      value.pData := AllocMem(value.DataSize);
     Move(PAnsiChar(SourceBuffer + DMHandle.fieldOffsets[FieldNo])^,pAnsiChar(value.pData)^,
      value.DataSize)
    end // copy
   else
    begin
     value.pData := PAnsiChar(SourceBuffer + DMHandle.fieldOffsets[FieldNo]);
    end; // direct pointer

   if (value.DataType = ftDate) then
    begin
     pDT := pDateTime(value.pData);
     tStamp.Time := 0;
     tStamp.Date := TDateTimeRec(pDT^).Date;
  //    DT := TimeStampToDateTime(tStamp);
     if (tStamp.Date = 0) then
      value.IsNull := true;
    end
   else
  {
   if  (fields[n].DataType = ftTime) then
   else
    begin
     pDT := pDateTime(Buffer);
     tStamp.Date := DateDelta;;
     tStamp.Time := TDateTimeRec(pDT^).Time;
     if (tStamp.Time = 0) then
      Result := false;
    end
   else
  }
   if  (value.DataType = ftDateTime) then
    begin
     pDT := pDateTime(value.pData);
     tStamp := MSecsToTimeStamp(pDT^);
     if (tStamp.Date = 0) then
      value.IsNull := true;
    end;
  //aaStartTime;
 finally
   DBSession.UnlockSession;
 end;
end; // GetFieldValue


//------------------------------------------------------------------------------
// returns field value for logical field #FieldNo - used in sub queries
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetFieldValueWithProjection(
                    var value: TETblDataValue;
                    FieldNo: Integer;
                    bCopy: Boolean = false);
var
    projFieldNo:            integer;
begin
  if (FProjection) then
   begin
    projFieldNo := FProjectionMap.Items[fieldNo];
   end
  else
   projFieldNo := FieldNo;
  GetFieldValue(value,projFieldNo,bCopy);
end; // GetFieldValueWithProjection


//------------------------------------------------------------------------------
// sets field value
// FieldNo is 0 - based
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetFieldValue(
                        var value: TETblDataValue;
                        FieldNo: Integer
                        );
var
    size, i, projFieldNo:            integer;
    DestinationBuffer:  PAnsiChar;
    pDT:      pDateTime;
    tStamp:   TTimeStamp;
    fType:    TFieldType;
    bs:       TEasyBLOBStream;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
label sfdEnd;
begin
 DBSession.LockSession;
 try
   if (FProjection) then
    begin
     // find by physical field number
     projFieldNo := -1;
     for i := 0 to FProjectionMap.ItemCount-1 do
      if (FProjectionMap.Items[i] = FieldNo) then
       begin
        projFieldNo := i;
        break;
       end;
//     if (FieldNo >= 0) and (FieldNo < FProjectionMap.ItemCount) then
//      FieldNo := FProjectionMap.Items[FieldNo];
    end
   else
    projFieldNo := FieldNo;

   // sequence field
   if (FieldNo = -1) then
    FieldNo := DMHandle.tableHeader.fieldCount;

   DestinationBuffer := GetActiveRecordBuffer;
   if (FieldNo < 0) then Exit;
   if (FieldNo >= DMHandle.tableHeader.fieldCount) then
    begin
     // auto inc
     // this field is primary key - usually is read only
  //   if (State = dsSetKey) or (AutoIncChangeEnabled) then
      PInteger(DestinationBuffer+DMHandle.recordSize)^ := PInteger(value.pData)^;
     if (PInteger(value.pData)^ > LastAutoIncValue) then
      SetAutoIncValue(PInteger(value.pData)^);

     if (DMHandle.tableHeader.ShowAutoInc = AutoIncOn) then
      goto sfdEnd
     else
      Exit;
    end;

   // may be through it out?
   Fields[projFieldNo].Validate(value.pData);

   // check if the field value is null
   if (value.IsNull) then
    begin
     chkfld_set := true;
     chkfld_fieldNum := FieldNo;
     chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
     {$include set_fields.inc}
     goto sfdEnd;
    end;

   fType := value.DataType;
   // BLOB value
   if ( (fType = ftBLOB) or
        (fType = ftMemo) or
        (fType = ftFmtMemo) or
        (fType = ftGraphic))
        then
         begin
          bs := TEasyBLOBStream.Create(TBlobField(Fields[projFieldNo]),bmWrite);
          bs.Fstream.WriteBuffer(value.pData^,value.DataSize);
          bs.Free;
          goto sfdEnd;
         end; // BLOB

   if ((fType = ftString) and (pByte(value.pData)^ = 0)) or
      ((fType = ftWideString) and (pWord(value.pData)^ = 0)) then
    begin
     chkfld_set := true;
     chkfld_fieldNum := FieldNo;
     chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
     {$include set_fields.inc}
     goto sfdEnd;
    end;

   if ((fType = ftDate)) then
    begin
     pDT := pDateTime(value.pData);
     tStamp.Date := TDateTimeRec(pDT^).Date;
     if (tStamp.Date = 0) then
      begin
       chkfld_set := true;
       chkfld_fieldNum := FieldNo;
       chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
       {$include set_fields.inc}
       goto sfdEnd;
      end;
    end
   else
   if (fType = ftDateTime) then
    begin
     pDT := pDateTime(value.pData);
     tStamp := MSecsToTimeStamp(pDT^);
     if (tStamp.Date = 0) then
      begin
       chkfld_set := true;
       chkfld_fieldNum := FieldNo;
       chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
       {$include set_fields.inc}
       goto sfdEnd;
      end;
    end;

  //  ShowMessage('not null');
   chkfld_set := false;
   chkfld_fieldNum := FieldNo;
   chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
  {$include set_fields.inc}

   if (DestinationBuffer = nil) then
    ETblException.Create(00018,[FTableName],self);
   if (value.pData = nil) then
    ETblException.Create(00019,[FTableName],self);

   //move this field data from value.pData to Active Buffer
  // if (ftype = ftB
   if (fType = ftString) then
    size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize-1
   else
   if (fType = ftWideString) then
    size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize-2
   else
    size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize;

   Move(value.pData^,PAnsiChar(DestinationBuffer + DMHandle.fieldOffsets[FieldNo])^,min(value.DataSize,size));
  sfdEnd:
   if not (State in [dsCalcFields, dsFilter, dsNewValue]) then
    if FieldNo < DMHandle.tableHeader.fieldCount
      then DataEvent(deFieldChange, Longint(Fields[projFieldNo]));
 finally
   DBSession.UnlockSession;
 end;
end; // SetFieldValue


//------------------------------------------------------------------------------
// locate record
//------------------------------------------------------------------------------
function TEasyDataSet.Locate(const KeyFields: String; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
var i : integer;
    curFilterOptions : TFilterOptions;
begin
 DBSession.LockSession;
 try
  result := false;
  curFilterOptions := [];
  if (loCaseInsensitive in Options) then
    curFilterOptions := curFilterOptions + [foCaseInsensitive];
  if not (loPartialKey in Options) then
    curFilterOptions := curFilterOptions + [foNoPartialCompare];

  //EDH added recordcount check!!  
  if RecordCount > 0 then
   begin
    i := PrepareAndLocate(KeyFields, KeyValues, soEQ, curFilterOptions);
    if (i >= 0) then
     begin
      result := true;
      DoBeforeScroll;
      // Positioninig on record with physNo=i
      SetTablePositionByPhysRecNo(i);
      if (Active) then
       Resync([rmExact,rmCenter]);
      DoAfterScroll;
     end;
   end;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.Locate


//------------------------------------------------------------------------------
// lookup record
//------------------------------------------------------------------------------
function TEasyDataSet.Lookup(const KeyFields: String; const KeyValues: Variant;
      const ResultFields: String): Variant;
var fieldCount,i,oldTablePosition : integer;
    curFilterOptions : TFilterOptions;
    bResult: boolean;
    fieldList: TStringList;
begin
 DBSession.LockSession;
 try
//   curFilterOptions := [foNoPartialCompare];
   curFilterOptions := [];
   oldTablePosition := tablePosition;

   i := PrepareAndLocate(KeyFields, KeyValues, soEQ, curFilterOptions);
   if (i >= 0) then
    begin
     // Positioninig on record with physNo=i
     SetTablePositionByPhysRecNo(i);

     if (Active) then
      Resync([rmExact,rmCenter]);
     bResult := true;
    end
   else
    bResult := false;

   if (bResult) then
    begin  //result fields for lookup
     fieldList := TStringList.Create;
     fieldCount := GetStringParams(ResultFields, fieldList);
     if (fieldCount > 1) then
      begin
       result := VarArrayCreate([0, fieldCount-1], varVariant);
       for i:=0 to fieldCount-1 do
        result[i] := FieldByName(fieldList[i]).AsVariant;
      end
     else
      result := FieldByName(fieldList[0]).AsVariant;
      fieldList.Free;
    end
   else
    Result := Null;

  // restore current record position
   tablePosition := oldTablePosition;
   if (Active and bResult) then
    begin
     if (tablePosition < 0) then
      tablePosition := 0;
     Resync([rmExact,rmCenter]);
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.Lookup


//------------------------------------------------------------------------------
// check if field is in index
//------------------------------------------------------------------------------
function TEasyDataSet.GetIsIndexField(Field: TField): Boolean;
var
  i, n: Integer;
  pIdx: pIndexHeaderType;
begin
 DBSession.LockSession;
 try
  Result:=False;
  with Field do
   begin
    if (FieldNo > 0) then
     begin
      n := Field.FieldNo-1;
      if (FProjection) then
       begin
        // physical field number
        if (n >= 0) and (n < FProjectionMap.ItemCount) then
         n := FProjectionMap.Items[n];
        // sequence field
        if (n = -1) then
         n := DMHandle.tableHeader.fieldCount;
       end;

      pIdx := pIndexHeaderType(DMHandle.indexHeaderList.items[currentIndex]);
      for i:=0 to pIdx^.IndexCount-1 do
       begin
         if (pIdx^.indexFields[i] = n) then
           begin
            Result:=True;
            Exit;
           end;
       end;
     end;
   end;
 finally
   DBSession.UnlockSession;
 end;
end;// GetIsIndexField


//------------------------------------------------------------------------------
// get field data from active buffer
//------------------------------------------------------------------------------
{$IFDEF D17H}
 {$IFDEF D18H}
function TEasyDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer; NativeFormat: Boolean): Boolean;
 {$ELSE}
function TEasyDataSet.GetFieldData(Field: TField; Buffer: TValueBuffer; NativeFormat: Boolean): Boolean;
 {$ENDIF}
{$ELSE}
function TEasyDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
{$ENDIF}
const Zero:         Word = $0000;
var n : integer;
    Size,ZeroSize:  Integer;
    SourceBuffer : PAnsiChar;
    pDT : pDateTime;
    tStamp : TTimeStamp;
    fType:   TFieldType;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
 chkfld_result : Boolean;
begin
 DBSession.LockSession;
 try
  // if invalid call - exit
   n := Field.FieldNo-1;
   if (FProjection) then
    begin
     // physical field number
     if (n >= 0) and (n < FProjectionMap.ItemCount) then
      n := FProjectionMap.Items[n];
     // sequence field
     if (n = -1) then
      n := DMHandle.tableHeader.fieldCount;
    end;

   chkfld_set := False;
   Result := chkfld_set;
   SourceBuffer:=GetActiveRecordBuffer;
   if (not isTableOpened) or (SourceBuffer = nil)  then
    Exit;
  //Exit;
   if (n = DMHandle.tableHeader.fieldCount) then
    begin
     result := true;
     if (Buffer <> nil) then
      Move(PAnsiChar(SourceBuffer+DMHandle.recordSize)^,PAnsiChar(Buffer)^,sizeOf(integer)); //id
     Exit;
    end;

   if (Field.FieldKind=fkCalculated) or (Field.FieldKind=fkLookup) then
     begin
      Inc(SourceBuffer,DMHandle.calculatedOffset+Field.Offset);
      Result := Boolean(SourceBuffer[0]);
      if ((Result) and (Buffer <> nil)) then
       Move(SourceBuffer[1],PAnsiChar(Buffer)^,Field.DataSize);
      Exit;
     end;

   chkfld_buffer := pAnsiChar(SourceBuffer+DMHandle.recNullOffset);
   chkfld_fieldNum := n;
   {$include check_fields.inc}

   if (chkfld_result) then
    begin
      Exit; //null
    end;

   result := true;

   if (Buffer = nil) then
    Exit;

   if (n < 0) or (n > DMHandle.tableHeader.fieldCount) then
         begin
      result := false;
          Exit;
         end;

   if (DMHandle.fieldHeaderList.Items[n] = nil) then raise Exception.Create(
      'Error in TEasyDataSet.GetFieldData - FieldNo=.'+IntToStr(n+1)+' 0 pointer!');

   fType := pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldType;

   // check if blob field is null from TDataset
   if ( (fType = ftBLOB) or
        (fType = ftMemo) or
        (fType = ftFmtMemo) or
        (fType = ftGraphic))
        then
    begin
  //        result := not IsBLOBFieldEmpty(Field);
          Exit;
    end;


  // return false if field value is null
  // if no records in table - return null value

  // if (DMHandle.tableHeader.recordCount <= 0) and (State <> dsInsert)
  //  then Exit;

  // if field number is invalid - return false
    {
   if (fType = ftBoolean) then
    begin
     Result:=true;
     pInteger(Buffer)^ := 0;
     Exit;
    end;
    }


   //move this field data from active buffer to buffer
  {if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldType = ftWideString) then
   begin
    s := WideCharToAnsiString(pWideChar(SourceBuffer + DMHandle.fieldOffsets[n]));
    Move(pAnsiChar(s)^,Buffer^,
    pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize);
   end
  else
  }
   if (fType = ftWideString) then
    begin
{$IFDEF D17H}
//    PWideChar(Buffer^) := PWideChar(SourceBuffer + DMHandle.fieldOffsets[n]);
       Move(PAnsiChar(SourceBuffer + DMHandle.fieldOffsets[n])^,
         PAnsiChar(Buffer)^,
         pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize);

{$ELSE}
    PWideChar(Buffer^) := PWideChar(SourceBuffer + DMHandle.fieldOffsets[n]);
{$ENDIF}
   end
   else
    begin
     Move(PAnsiChar(SourceBuffer + DMHandle.fieldOffsets[n])^,PAnsiChar(Buffer)^,
      pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize);
    end;
   if (fType = ftDate) then
    begin
     pDT := pDateTime(Buffer);
     tStamp.Time := 0;
     tStamp.Date := TDateTimeRec(pDT^).Date;
  //    DT := TimeStampToDateTime(tStamp);
     if (tStamp.Date <= 0) then
      Result := false;
    end
   else
  {
   if  (fType = ftTime) then
   else
    begin
     pDT := pDateTime(Buffer);
     tStamp.Date := DateDelta;;
     tStamp.Time := TDateTimeRec(pDT^).Time;
     if (tStamp.Time = 0) then
      Result := false;
    end
   else
  }
   if  (fType = ftDateTime) then
    begin
     pDT := pDateTime(Buffer);
     tStamp := MSecsToTimeStamp(pDT^);
     if (tStamp.Date = 0) then
      Result := false;
    end;
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.GetFieldData


//------------------------------------------------------------------------------
// set field data to active buffer
//------------------------------------------------------------------------------
{$IFDEF D17H}
procedure TEasyDataSet.SetFieldData(Field: TField; Buffer: TValueBuffer; NativeFormat: Boolean);
{$ELSE}
procedure TEasyDataSet.SetFieldData(Field: TField; Buffer: Pointer);
{$ENDIF}
const Zero:         Word = $0000;
var n, size, MaxSize : integer;
    DestinationBuffer : PAnsiChar;
    pDT : pDateTime;
    tStamp : TTimeStamp;
    fType:   TFieldType;
    Source:    PAnsiChar;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
label sfdEnd;
begin
 DBSession.LockSession;
 try
    with Field do
    begin
      if not (State in dsWriteModes) then
        raise ETblException.Create(01085, Self);
      if (State = dsSetKey) and
         ((FieldNo < 0) or
          (pIndexHeaderType(DMHandle.indexHeaderList.items[currentIndex])^.IndexCount > 0) and
          not IsIndexField) then
        raise ETblException.Create(01086, [DisplayName], Self);
    end;

   n := Field.FieldNo-1;
   if (FProjection) then
    begin
     // physical field number
     if (n >= 0) and (n < FProjectionMap.ItemCount) then
      n := FProjectionMap.Items[n];
     // sequence field
     if (n = -1) then
      n := DMHandle.tableHeader.fieldCount;
    end;

   DestinationBuffer:=GetActiveRecordBuffer;
  // DestinationBuffer:=ActiveBuffer;
   if (Field.FieldKind=fkCalculated) or (Field.FieldKind=fkLookup) then //this is a calculated field
    begin
     Inc(DestinationBuffer,DMHandle.calculatedOffset+Field.Offset);
     Boolean(DestinationBuffer[0]):=(Buffer<>nil);
     if Boolean(DestinationBuffer[0]) then
        Move(PAnsiChar(Buffer)^,PAnsiChar(@DestinationBuffer[1])^,Field.DataSize);
     goto sfdEnd;
    end;
   if (n < 0) then Exit;
   if (n >= DMHandle.tableHeader.fieldCount) then
    begin
     // this field is primary key - usually is read only
     if (State = dsSetKey) or (AutoIncChangeEnabled) then
      PInteger(DestinationBuffer+DMHandle.recordSize)^ := PInteger(Buffer)^;
     if (DMHandle.tableHeader.ShowAutoInc = AutoIncOn) then
      goto sfdEnd
     else
      Exit;
    end;

   Field.Validate(Buffer);

   // check if the field value is null
   if (Buffer = nil) then
    begin
  {
     if (State = dsInsert) or (State = dsEdit) then
      if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.Required) then
       DatabaseError('Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = '+
        inttostr(n+1));
  }
  //     then Exit;
  //     then raise Exception.Create(
  //      'Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = '+
  //      inttostr(n+1));
     chkfld_set := true;
     chkfld_fieldNum := n;
     chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
     {$include set_fields.inc}
     goto sfdEnd;
    end;

   if (DMHandle.fieldHeaderList.Items[n] = nil) then raise Exception.Create(
      'Error in TEasyDataSet.SetFieldData - FieldNo=.'+IntToStr(n+1)+' 0 pointer!');
   fType := pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldType;

   if ((fType = ftString) and (pByte(Buffer)^ = 0)) or
      ((fType = ftWideString) and (pWord(Buffer)^ = 0)) then
    begin
  {
     if (State = dsInsert) or (State = dsEdit) then
      if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.Required) then
       DatabaseError('Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = '+
        inttostr(n+1));
  }
  //     then raise Exception.Create(
  //      'Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = .'+
  //      inttostr(n+1));
     chkfld_set := true;
     chkfld_fieldNum := n;
     chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
     {$include set_fields.inc}
     goto sfdEnd;
    end;

   if ((fType = ftDate)) then
    begin
     pDT := pDateTime(Buffer);
     tStamp.Date := TDateTimeRec(pDT^).Date;
     if (tStamp.Date = 0) then
      begin
  {
       if (State = dsInsert) or (State = dsEdit) then
         if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.Required) then
       DatabaseError('Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = '+
        inttostr(n+1));
  }
  //        then raise Exception.Create(
  //         'Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = .'+
  //         inttostr(n+1));
       chkfld_set := true;
       chkfld_fieldNum := n;
       chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
       {$include set_fields.inc}
       goto sfdEnd;
      end;
    end
   else
   if (fType = ftDateTime) then
    begin
     pDT := pDateTime(Buffer);
     tStamp := MSecsToTimeStamp(pDT^);
     if (tStamp.Date = 0) then
      begin
  {
       if (State = dsInsert) or (State = dsEdit) then
        if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.Required) then
       DatabaseError('Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = '+
        inttostr(n+1));
  }
  //       then raise Exception.Create(
  //        'Error in TEasyDataSet.SetFieldData - null value not allowed, FieldNo = .'+
  //        inttostr(n+1));
       chkfld_set := true;
       chkfld_fieldNum := n;
       chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
       {$include set_fields.inc}
       goto sfdEnd;
      end;
    end;

  //  ShowMessage('not null');
     chkfld_set := false;
     chkfld_fieldNum := n;
     chkfld_buffer := pAnsiChar(DestinationBuffer+DMHandle.recNullOffset);
     {$include set_fields.inc}
   // invalid field number
   if (not isTableOpened) or (DestinationBuffer = nil) or (Buffer = nil) then Exit;
    if (Field.FieldNo > DMHandle.tableHeader.fieldCount+1) then
     begin
      raise Exception.Create(
       'Error in TEasyDataSet.SetFieldData - FieldNo > fieldCount.');
      Exit;
     end;
   //move this field data from active buffer to buffer
   if (fType = ftString) then
    size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize-1
//   else
//   if (fType = ftWideString) then
//    size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize-2
   else
    size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize;
   if (fType = ftWideString) then
    begin
     try
      {$IFDEF D10H}
      Source := PAnsiChar(Buffer);
      {$ELSE}
      Source := PAnsiChar(Buffer^);
      {$ENDIF}
      size := GetStrLength(PAnsiChar(Source),True);
      MaxSize := pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldSize;
      if (Size + SizeOf(Zero) > MaxSize) then
       begin
        Size := MaxSize - SizeOf(Zero);
        Move(Source^,PAnsiChar(DestinationBuffer + DMHandle.fieldOffsets[n])^,
              Size);
       end
      else
       begin
        Move(Source^,PAnsiChar(DestinationBuffer + DMHandle.fieldOffsets[n])^,
             Size);
       end;
        // move zero to the end of string if it is possible
      Move(Zero,
          PAnsiChar(DestinationBuffer + DMHandle.fieldOffsets[n]+Size)^,
          SizeOf(Zero));
     except
      raise Exception.Create('TEasyDataset.SetFieldData error - Cannot set wide string field, FieldNo = '
            +IntToStr(n)+', MaxSize = '+IntToStr(MaxSize)+', Size = '+IntToStr(Size)+
            ', Offset = '+IntToStr(DMHandle.fieldOffsets[n])+
            ', Source = '+IntToHex(Integer(Source),8));
     end;
    end
   else
    Move(PAnsiChar(Buffer)^,PAnsiChar(DestinationBuffer + DMHandle.fieldOffsets[n])^,size);
  {
   if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[n])^.fieldType = ftDateTime) then
    begin
     dt := 0;
     Move(dt,PAnsiChar(DestinationBuffer + DMHandle.fieldOffsets[n])^,size);
    end;
  }
  sfdEnd:
   if not (State in [dsCalcFields, dsFilter, dsNewValue]) then
    DataEvent(deFieldChange, Longint(Field));
 finally
   DBSession.UnlockSession;
 end;
end;// TEasyDataSet.SetFieldData


//------------------------------------------------------------------------------
// go to first record (before first record to BOF)
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalFirst;
begin
//if (debugFlag) then ShowMessage('internal first');
 tablePosition := -1;
end; // TEasyDataSet.InternalFirst;


//------------------------------------------------------------------------------
// go to last record (after last record to EOF)
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalLast;
begin
 DBSession.LockSession;
 try
  //if (debugFlag) then ShowMessage('internal last');
   CheckTableState;
   tablePosition := visibleRecordCount;
 finally
   DBSession.UnlockSession;
 end;
end; // TEasyDataSet.InternalLast;


{$IFDEF D21H}

//------------------------------------------------------------------------------
// quick go to record
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalSetToRecord(Buffer: TRecBuf);
begin
 DBSession.LockSession;
 try
//if (debugFlag) then
 //ShowMessage('internal set to record');
{
 tablePosition := pBookMarkInfoType(Buffer + DMHandle.recordSize +
                  sizeOf(recordInfoType))^.BookmarkData;
 }
  InternalGotoBookmark(@pRecordInfoType(PAnsiChar(Buffer)+DMHandle.recordSize)^.id);
 finally
   DBSession.UnlockSession;
 end;
end; // NewDataSet.InternalSetToRecord


//------------------------------------------------------------------------------
// return BookmarkFlag
//------------------------------------------------------------------------------
function TEasyDataSet.GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag;
begin
 if (Pointer(Buffer) = nil) then raise Exception.Create(
    'Error in TEasyDataSet.GetBookmarkFlag - 0 pointer Buffer');
 Result := pBookMarkInfoType(Buffer + DMHandle.recInfoBufferSize).BookmarkFlag;
end; // NewDataSet.GetBookmarkFlag


//------------------------------------------------------------------------------
// get bookmark data (record number)
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
begin
if (Pointer(Data) = nil) then raise Exception.Create(
    'Error in TEasyDataSet.GetBookmarkData - 0 pointer Data');
if (Pointer(Buffer) = nil) then raise Exception.Create(
    'Error in TEasyDataSet.GetBookmarkData - 0 pointer Buffer');

  pInteger(Data)^ := PBookmarkInfoType(Buffer + DMHandle.recInfoBufferSize)^.BookmarkData;
{$IFDEF DEBUG_FLAG}
aaWriteToLog('GetBookmarkData, bookmark = '+IntToStr(pInteger(Data)^));
{$ENDIF}


end; // TEasyDataSet.GetBookmarkData


//------------------------------------------------------------------------------
// go to bookmark
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalGotoBookmark(Bookmark: TBookmark);
var x,f,oldPos : integer;
begin
 DBSession.LockSession;
 try
  //if (debugFlag) then ShowMessage('go to bookmark ');

   CheckTableState;
   if (pInteger(Bookmark) = nil) then raise Exception.Create(
      'Error in TEasyDataSet.InternalGoToBookmark - 0 pointer Bookmark');
   if (Eof and Bof) then
    exit;


{$IFDEF RECORD_ID_NAVIGATION}
    FCurrentRecordID := pInteger(Bookmark)^;
{$ENDIF}
   x := pInteger(Bookmark)^;
   f := GetTablePositionByID(x);
   oldPos := tablePosition;

   if (f < 0) then
    tablePosition := -1
   else
    if (f >= visibleRecordCount-1) then
     tablePosition := visibleRecordCount-1
    else
     tablePosition := f;
   if (tablePosition <> oldPos) and (state <> dsInsert) then
    ClearBLOBStreams;
 finally
   DBSession.UnlockSession;
 end;
{$IFDEF DEBUG_FLAG}
aaWriteToLog('InternalGotoBookmark, bookmark = '+IntToStr(x)+', f = '+
IntToStr(f)+', oldPos = '+intToStr(oldPos)+', tablePosition = '+IntToStr(tablePosition));
{$ENDIF}
end; // TEasyDataSet.InternalGotoBookmark


//------------------------------------------------------------------------------
// set bookmark flag
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetBookmarkFlag(Buffer: TRecBuf; Value: TBookmarkFlag);
begin
//if (debugFlag) then ShowMessage('set bookmark flag');
 if (Pointer(Buffer) = nil) then raise Exception.Create(
    'Error in TEasyDataSet.SetBookmarkFlag - 0 pointer Buffer');
 pBookMarkInfoType(Buffer + DMHandle.recInfoBufferSize).BookmarkFlag := Value;
//if (debugFlag) then ShowMessage('set bookmark flag ok');

end; // TEasyDataSet.SetBookmarkFlag


//------------------------------------------------------------------------------
// set bookmark data (record number)
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
begin
// if (debugFlag) then ShowMessage('set bookmark data');
 if (Pointer(Data) = nil) then Exit;
 if (Pointer(Buffer) = nil) then raise Exception.Create(
     'Error in TEasyDataSet.SetBookmarkData - 0 pointer to Buffer.');
 pBookMarkInfoType(Buffer + DMHandle.recInfoBufferSize)^.BookmarkData := pInteger(Data)^;
end; // TEasyDataSet.SetBookmarkData
{$ELSE}


//------------------------------------------------------------------------------
// quick go to record
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalSetToRecord(Buffer: TRecordBuffer);
begin
 DBSession.LockSession;
 try
//if (debugFlag) then
 //ShowMessage('internal set to record');
{
 tablePosition := pBookMarkInfoType(Buffer + DMHandle.recordSize +
                  sizeOf(recordInfoType))^.BookmarkData;
 }
  InternalGotoBookmark(@pRecordInfoType(Buffer+DMHandle.recordSize)^.id);
 finally
   DBSession.UnlockSession;
 end;
end; // NewDataSet.InternalSetToRecord


//------------------------------------------------------------------------------
// return BookmarkFlag
//------------------------------------------------------------------------------
function TEasyDataSet.GetBookmarkFlag(Buffer: TRecordBuffer):TBookmarkFlag;
begin
 if (Buffer = nil) then raise Exception.Create(
    'Error in TEasyDataSet.GetBookmarkFlag - 0 pointer Buffer');
 Result := pBookMarkInfoType(Buffer + DMHandle.recInfoBufferSize).BookmarkFlag;
end; // NewDataSet.GetBookmarkFlag


//------------------------------------------------------------------------------
// get bookmark data (record number)
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
if (Data = nil) then raise Exception.Create(
    'Error in TEasyDataSet.GetBookmarkData - 0 pointer Data');
if (Buffer = nil) then raise Exception.Create(
    'Error in TEasyDataSet.GetBookmarkData - 0 pointer Buffer');

  pInteger(Data)^ := PBookmarkInfoType(Buffer + DMHandle.recInfoBufferSize)^.BookmarkData;
{$IFDEF DEBUG_FLAG}
aaWriteToLog('GetBookmarkData, bookmark = '+IntToStr(pInteger(Data)^));
{$ENDIF}


end; // TEasyDataSet.GetBookmarkData


//------------------------------------------------------------------------------
// go to bookmark
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalGotoBookmark(Bookmark: Pointer);
var x,f,oldPos : integer;
begin
 DBSession.LockSession;
 try
  //if (debugFlag) then ShowMessage('go to bookmark ');

   CheckTableState;
   if (pInteger(Bookmark) = nil) then raise Exception.Create(
      'Error in TEasyDataSet.InternalGoToBookmark - 0 pointer Bookmark');
   if (Eof and Bof) then
    exit;


{$IFDEF RECORD_ID_NAVIGATION}
    FCurrentRecordID := pInteger(Bookmark)^;
{$ENDIF}
   x := pInteger(Bookmark)^;
   f := GetTablePositionByID(x);
   oldPos := tablePosition;

   if (f < 0) then
    tablePosition := -1
   else
    if (f >= visibleRecordCount-1) then
     tablePosition := visibleRecordCount-1
    else
     tablePosition := f;
   if (tablePosition <> oldPos) and (state <> dsInsert) then
    ClearBLOBStreams;
 finally
   DBSession.UnlockSession;
 end;
{$IFDEF DEBUG_FLAG}
aaWriteToLog('InternalGotoBookmark, bookmark = '+IntToStr(x)+', f = '+
IntToStr(f)+', oldPos = '+intToStr(oldPos)+', tablePosition = '+IntToStr(tablePosition));
{$ENDIF}
end; // TEasyDataSet.InternalGotoBookmark


//------------------------------------------------------------------------------
// set bookmark flag
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
begin
//if (debugFlag) then ShowMessage('set bookmark flag');
 if (Buffer = nil) then raise Exception.Create(
    'Error in TEasyDataSet.SetBookmarkFlag - 0 pointer Buffer');
 pBookMarkInfoType(Buffer + DMHandle.recInfoBufferSize).BookmarkFlag := Value;
//if (debugFlag) then ShowMessage('set bookmark flag ok');

end; // TEasyDataSet.SetBookmarkFlag


//------------------------------------------------------------------------------
// set bookmark data (record number)
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
// if (debugFlag) then ShowMessage('set bookmark data');
 if (Data = nil) then Exit;
 if (Buffer = nil) then raise Exception.Create(
     'Error in TEasyDataSet.SetBookmarkData - 0 pointer to Buffer.');
 pBookMarkInfoType(Buffer + DMHandle.recInfoBufferSize)^.BookmarkData := pInteger(Data)^;
end; // TEasyDataSet.SetBookmarkData

{$ENDIF}


//------------------------------------------------------------------------------
// set key data
//------------------------------------------------------------------------------
procedure TEasyDataset.PostKeyBuffer(Commit: Boolean);
begin
  DataEvent(deCheckBrowseMode, 0);
  if Commit then
    FKeyBuffer.Modified := Modified
  else
//    Move(FKeyBuffers[kiSave]^, FKeyBuffer^, SizeOf(TKeyBuffer) + DMHandle.bufferSize);
    Move(FKeyBuffers[kiSave]^, FKeyBuffer^, SizeOf(TKeyBuffer) + FRecordSize);
  SetState(dsBrowse);
  DataEvent(deDataSetChange, 0);
end;// PostBuffer after SetKey


//------------------------------------------------------------------------------
// compare bookmarks
//------------------------------------------------------------------------------
function TEasyDataset.CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
const
  RetCodes: array[Boolean, Boolean] of ShortInt=((2,-1),(1,0));
var
  x1,x2,pos1,pos2 : Integer;
begin
 DBSession.LockSession;
 try
    { Check for uninitialized bookmarks }
    Result := RetCodes[Bookmark1 = nil, Bookmark2 = nil];
    if Result = 2 then
     begin
      if DMHandle <> nil then
       begin
        x1 := pInteger(Bookmark1)^;
        x2 := pInteger(Bookmark2)^;
        if (x1 <> x2) then
         begin
          pos1 := GetTablePositionByID(x1, True);
          pos2 := GetTablePositionByID(x2, True);
          if (pos1 = pos2) then
           Result := 0
  //         Raise Exception.Create('TEasyDataset.CompareBookmarks - equal positions, pos1 = '+
  //           InttoStr(pos1)+', x1 = '+InttoStr(x1)+', x2 = '+InttoStr(x2))
          else
          if (pos1 > pos2) then
           Result := 1
          else
           Result := -1;
         end // bookmarks not equal
        else
         Result := 0;
       end;
      if (Result = 2) then
       Result := 0;
     end;
 finally
   DBSession.UnlockSession;
 end;
end; //CompareBookmarks


//------------------------------------------------------------------------------
// checks if bookmark is valid
//------------------------------------------------------------------------------
function TEasyDataset.BookmarkValid(Bookmark: TBookmark): Boolean;
var x1,pos1 : Integer;
begin
 DBSession.LockSession;
 try
   CheckTableState;
   Result := false;
   if (Bookmark <> nil) then
    begin
     x1 := pInteger(Bookmark)^;
     pos1 := GetTablePositionByID(x1);
     if (pos1 >= 0) and (pos1 < visibleRecordCount) then
      Result := true;
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //BookmarkValid


//------------------------------------------------------------------------------
// post with SetKey addition
//------------------------------------------------------------------------------
procedure TEasyDataset.Post;
begin
  DBSession.LockSession;
  try
   inherited Post;
   if State = dsSetKey then
     PostKeyBuffer(True);
  finally
   DBSession.UnlockSession;
  end;
end;// Post


//------------------------------------------------------------------------------
// direct insert
//------------------------------------------------------------------------------
procedure TEasyDataset.DirectInsert;
begin
 DBSession.LockSession;
 try
   if (FDirectInsert) then
    begin
     FreeRecordBuffer(TRecordBuffer(FTemporaryRecordBuffer));
    end;
   FTemporaryRecordBuffer := AllocRecordBuffer;
   insertMode := true;
   FDirectInsert := true;
   SetState(dsInsert);
 finally
   DBSession.UnlockSession;
 end;
end; //


//------------------------------------------------------------------------------
// direct post
//------------------------------------------------------------------------------
procedure TEasyDataset.DirectPost;
begin
 DBSession.LockSession;
 try
   if (FDirectInsert) then
    begin
     InternalPost;
     SetState(dsBrowse);
     FreeRecordBuffer(FTemporaryRecordBuffer);
     FDirectInsert := false;
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //


//------------------------------------------------------------------------------
// set SQL Filter
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetSQLFilter(FilterExpr: TObject);
begin
 FSQLFilterExpr := FilterExpr;
end;// SetSQLFilter


//------------------------------------------------------------------------------
// set SQL Top row count
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetSQLTopRowCount(SQLFirstRowNo, SQLTopRowCount: integer);
begin
 FSQLTopRowCount := SQLTopRowCount;
 FSQLFirstRowNo := SQLFirstRowNo;
end;// SetSQLTopRowCount


//------------------------------------------------------------------------------
// check required fields
//------------------------------------------------------------------------------
procedure TEasyDataSet.CheckRecordValidity(RecordBuffer: PAnsiChar);
  {$include check_var.inc}
  i: integer;
  chkfld_result : Boolean;
begin
  // check all required fields
  for i := 0 to DMHandle.fieldHeaderList.Count-1 do
   if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[i])^.Required) then
    begin
     // field is null?
     chkfld_buffer := pAnsiChar(RecordBuffer+DMHandle.recNullOffset);
     chkfld_fieldNum := i;
     {$include check_fields.inc}

     if (chkfld_result) then
      raise Exception.Create(
        'Field '''+
        pFieldHeaderType(DMHandle.fieldHeaderList.Items[i])^.fieldName+
        ''' must have a value');
    end;
end;// CheckRecordValidity


{$IFDEF D21H}
procedure TEasyDataSet.InitRecord(Buffer: TRecBuf);
begin

  inherited InitRecord(Buffer); // this does not work
  // fix comes here
  InternalInitRecord(Buffer);
  ClearCalcFields(Buffer);
  SetBookmarkFlag(Buffer, bfInserted);
  // fix comes here

  pBookmarkInfoType(PAnsiChar(Buffer) + DMHandle.recInfoBufferSize)^.BookmarkFlag := bfInserted;
  pBookmarkInfoType(PAnsiChar(Buffer) + DMHandle.recInfoBufferSize)^.BookmarkData := -1;
end;// InitRecord
{$ELSE}
//------------------------------------------------------------------------------
// InitRecord
//------------------------------------------------------------------------------
procedure TEasyDataSet.InitRecord(Buffer: TRecordBuffer);
begin
  inherited InitRecord(Buffer);
  pBookmarkInfoType(PAnsiChar(Buffer) + DMHandle.recInfoBufferSize)^.BookmarkFlag := bfInserted;
  pBookmarkInfoType(PAnsiChar(Buffer) + DMHandle.recInfoBufferSize)^.BookmarkData := -1;
end;// InitRecord
{$ENDIF}


{$IFDEF 21H}
//------------------------------------------------------------------------------
// appending table (Append flag - ignored, record will be inserted after
// last one)
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
var
    pBuffer, pBuffer1   : PAnsiChar;
    i,x: integer;
begin
 DBSession.LockSession;
 try
   if (Buffer = nil) then raise Exception.Create(
       'Error in TEasyDataSet.InternalAddRecord - 0 pointer to Buffer.');
   if (ReadOnly) then
    begin
     raise Exception.Create(
       'Error in TEasyDataSet.InternalAddRecord - table is read only.');
     Exit;
    end;
   pBuffer := Buffer;
   CheckRecordValidity(pBuffer);
   // checking unique indexes
   for i := 0 to DMHandle.indexFileHeader.indexCount-1 do
    if (ixUnique in pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexOptions) then
     begin
      // checking unique index
      x := FindInIndex(pBuffer,i,
           pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexCount,
           true,true);
      if (x >= 0) then
       begin
        pBuffer1 := DMHandle.allRecBuffer.GetRecordDataPtr(DMHandle.Indexes[i].Items[x]);
        if (pInteger(pBuffer1+DMHandle.recordSize)^ <>
            pInteger(pBuffer+DMHandle.recordSize)^) then
         begin
          DatabaseError('TEasyDataSet.InternalAddRecord - key violation.'+crlf+
                'Table name = '+AnsiQuotedStr(FTableName,'"')+'.'+crlf+
                'Unique index name = '+
                AnsiQuotedStr(
                 pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexName,'"')
                +'.');
         end;
       end; // x >= 0 - some records found
     end; // unique index check

    DMHandle.DisableFlushes;
    try
     if (DMHandle.isBLOBUsed) then
      DMHandle.aaAddBLOBRecord;
     aaAddRecord(Buffer);
     Move(PAnsiChar(pBuffer + DMHandle.recordSize)^,FCurrentRecordID,SizeOf(FCurrentRecordID));
     if (DMHandle.isBLOBUsed) then
      begin
       aaSaveBLOBData;
       ClearBLOBStreams;
      end;
    finally
     DMHandle.EnableFlushes;
    end;
    TableState := DMHandle.tableHeader.state;
 finally
  DBSession.UnlockSession;
 end;
{$ELSE}
//------------------------------------------------------------------------------
// appending table (Append flag - ignored, record will be inserted after
// last one)
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
var
    pBuffer, pBuffer1   : PAnsiChar;
    i,x: integer;
begin
 DBSession.LockSession;
 try
   if (Buffer = nil) then raise Exception.Create(
       'Error in TEasyDataSet.InternalAddRecord - 0 pointer to Buffer.');
   if (ReadOnly) then
    begin
     raise Exception.Create(
       'Error in TEasyDataSet.InternalAddRecord - table is read only.');
     Exit;
    end;
   pBuffer := Buffer;
   CheckRecordValidity(pBuffer);
   // checking unique indexes
   for i := 0 to DMHandle.indexFileHeader.indexCount-1 do
    if (ixUnique in pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexOptions) then
     begin
      // checking unique index
      x := FindInIndex(pBuffer,i,
           pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexCount,
           true,true);
      if (x >= 0) then
       begin
        pBuffer1 := DMHandle.allRecBuffer.GetRecordDataPtr(DMHandle.Indexes[i].Items[x]);
        if (pInteger(pBuffer1+DMHandle.recordSize)^ <>
            pInteger(pBuffer+DMHandle.recordSize)^) then
         begin
          DatabaseError('TEasyDataSet.InternalAddRecord - key violation.'+crlf+
                'Table name = '+AnsiQuotedStr(FTableName,'"')+'.'+crlf+
                'Unique index name = '+
                AnsiQuotedStr(
                 pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexName,'"')
                +'.');
         end;
       end; // x >= 0 - some records found
     end; // unique index check

    DMHandle.DisableFlushes;
    try
     if (DMHandle.isBLOBUsed) then
      DMHandle.aaAddBLOBRecord;
     aaAddRecord(Buffer);
     Move(PAnsiChar(pBuffer + DMHandle.recordSize)^,FCurrentRecordID,SizeOf(FCurrentRecordID));
     if (DMHandle.isBLOBUsed) then
      begin
       aaSaveBLOBData;
       ClearBLOBStreams;
      end;
    finally
     DMHandle.EnableFlushes;
    end;
    TableState := DMHandle.tableHeader.state;
 finally
  DBSession.UnlockSession;
 end;
end; //TEasyDataSet.InternalAddRecord
{$ENDIF}

//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalInsert;
begin
  insertMode := true;
end; //TEasyDataSet.InternalInsert;


//------------------------------------------------------------------------------
// cancel updating record
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalCancel;
begin
 DBSession.LockSession;
 try
   ClearBLOBStreams;
   if (FDirectInsert) then
    begin
     FDirectInsert :=  false;
     FreeRecordBuffer(FTemporaryRecordBuffer);
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.InternalCancel;


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalPost;
var pBuffer1: PAnsiChar;
    pBuffer:  PAnsiChar;
    i,x:      Integer;
begin
 DBSession.LockSession;
 try
  {$IFDEF D6H}
   if (not FDirectInsert) then
    inherited InternalPost;
  {$ENDIF}
   if (ReadOnly) then
    begin
     raise Exception.Create(
       'Error in TEasyDataSet.InternalPost - table is read only.');
     Exit;
    end;
   if (not isTableOpened) then  raise Exception.Create(
       'Error in TEasyDataSet.InternalPost - table is not open.');
  if (State <> dsEdit) and (State <> dsInsert) then raise Exception.Create(
       'Error in TEasyDataSet.InternalPost - invalid state.');
  //if (debugFlag) then  ShowMessage('InternalPost');
   if (Pointer(ActiveBuffer) = nil) then raise Exception.Create(
       'Error in TEasyDataSet.InternalPost - 0 pointer to buffer.');
  //aaStartTime;
   CheckTableState;
   if (tablePosition < 0) then tablePosition := 0
    else
     if (tablePosition >= visibleRecordCount) then
      tablePosition := visibleRecordCount-1;

   pBuffer := GetActiveRecordBuffer;
   CheckRecordValidity(pBuffer);
   // checking unique indexes
   for i := 0 to DMHandle.indexFileHeader.indexCount-1 do
    if (ixUnique in pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexOptions) or
       (ixPrimary in pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexOptions) then
     begin
      // checking unique index
      x := FindInIndex(pBuffer,i,
           pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexCount,
           true,true);
      if (x >= 0) then
       begin
        // AutoInc index?
        if ((pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexFields[0] = -1) and
            (pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexCount = 1)) and
            (State <> dsEdit) then
         // set new autoinc value
         pInteger(pBuffer+DMHandle.recordSize)^ := DMHandle.tableheader.sequenceValue+1
        else
         begin
          pBuffer1 := DMHandle.allRecBuffer.GetRecordDataPtr(DMHandle.Indexes[i].Items[x]);
          if (pInteger(pBuffer1+DMHandle.recordSize)^ <>
              pInteger(pBuffer+DMHandle.recordSize)^) then
           begin
            DatabaseError('TEasyDataSet.InternalPost - key violation.'+crlf+
                  'Table name = '+AnsiQuotedStr(FTableName,'"')+'.'+crlf+
                  'Unique index name = '+
                  AnsiQuotedStr(
                   pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexName,'"')
                  +'.')
           end;
         end
       end; // x >= 0 - some records found
     end; // unique index check
  //aaStopTime;

   // allocating memory
  // if (pBuffer = nil) then raise Exception.Create(
  //     'Error in TEasyDataSet.InternalPost - 0 pointer pBuffer.');
    DMHandle.DisableFlushes;
    Move(PAnsiChar(pBuffer + DMHandle.recordSize)^,FCurrentRecordID,SizeOf(FCurrentRecordID));
    try
     if (State = dsInsert) then
      begin
       if (DMHandle.isBLOBUsed) then
         begin
          DMHandle.aaAddBLOBRecord;
          aaSaveBLOBData;
          ClearBLOBStreams;
         end;
        aaAddRecord(pBuffer);
      end // insert
     else
      begin
       tablePosition := GetTablePositionByID(FCurrentRecordID);
       // update record
       if (DMHandle.isBLOBUsed) then
       begin
         aaSaveBLOBData;
         ClearBLOBStreams;
        end;
       aaUpdateRecord(pBuffer);
      end;
    finally
     DMHandle.EnableFlushes;
    end;
   insertMode := false;
   TableState := DMHandle.tableHeader.state;
 finally
  DBSession.UnlockSession;
 end;
//aaStopTime;
end; // InternalPost


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalDelete;
begin
 DBSession.LockSession;
 try
  if (ReadOnly) then
    begin
     raise Exception.Create(
       'Error in TEasyDataSet.InternalDelete - table is read only.');
     Exit;
    end;
  if (not isTableOpened) then raise Exception.Create(
       'Error in TEasyDataSet.InternalDelete - table is not open.');
   CheckTableState;

  if (visibleRecordCount <= 0) then
   raise Exception.Create(
       'Error in TEasyDataSet.InternalDelete - no records in table.');

{$IFDEF DEBUG_FLAG}
aaWriteToLog('Internal delete #0, blob rec count = '+
IntToStr(DMHandle.blobFileHeader.recordCount)+
', record count = '+IntToStr(DMHandle.tableHeader.recordCount));
{$ENDIF}

  if (DMHandle.isBLOBUsed) then
      aaDeleteBLOBRecord;

{$IFDEF DEBUG_FLAG}
aaWriteToLog('Internal delete #1, blob rec count = '+
IntToStr(DMHandle.blobFileHeader.recordCount)+
', record count = '+IntToStr(DMHandle.tableHeader.recordCount));
{$ENDIF}

  aaDeleteRecord;

{$IFDEF DEBUG_FLAG}
aaWriteToLog('Internal delete #2, blob rec count = '+
IntToStr(DMHandle.blobFileHeader.recordCount)+
', record count = '+IntToStr(DMHandle.tableHeader.recordCount));
{$ENDIF}

  TableState := DMHandle.tableHeader.state;
  if (Pointer(ActiveBuffer) <> nil) then
    SetActiveBuffer;
 finally
  DBSession.UnlockSession;
 end;
end; // TEasyDataSet.InternalDelete


//------------------------------------------------------------------------------
// return true if the table can be modified
//------------------------------------------------------------------------------
function TEasyDataSet.GetCanModify: Boolean;
begin
  Result := not Self.FReadOnly;
end;


//------------------------------------------------------------------------------
// GetExists - returns true, if table exists; otherwise returns false
//------------------------------------------------------------------------------
function TEasyDataSet.GetExists : Boolean;
var
  TempDatabase: TEasyDatabase;
  DBMHandle: TEasyDatabaseManager;

function CheckFile: Boolean;
begin
  Result := False;
  if (DBMHandle <> nil) then
    if FInMemory and (FDatabaseFileName = '') then
      result := DBMHandle.aaFileExists(TableName+tableFileExtension, fsmInMemory)
    else
      result := DBMHandle.aaFileExists(TableName+tableFileExtension, fsmDefault);
end;

begin
 if (Active) then
  Result := True
 else
  begin
   Result := False;
   TempDatabase := DBSession.FindDatabase(DatabaseName, DatabaseFileName);
   if (TempDatabase = nil) then
    begin
     TempDatabase := TEasyDatabase.Create(Self);
     try
       TempDatabase.DatabaseName := GetTemporaryName('temp');
       TempDatabase.DatabaseFileName := DatabaseFileName;
       TempDatabase.KeepConnection := True;
       TempDatabase.Temporary := True;
       if (TempDatabase.Exists) then
        begin
         TempDatabase.Open;
         DBMHandle := TempDatabase.Handle;
         Result := CheckFile;
        end;
     finally
       if (TempDatabase.Connected) then
        TempDatabase.Close;
       TempDatabase.Free;
     end;
    end
   else
    begin
      DBSession.LockSession;
      try
        if (TempDatabase.Connected) then
         begin
          DBMHandle := TempDatabase.Handle;
          Result := CheckFile;
         end
        else
         if (TempDatabase.Exists) then
          begin
           TempDatabase.Open;
           try
            DBMHandle := TempDatabase.Handle;
            Result := CheckFile;
           finally
            TempDatabase.Close;
           end;
          end;
      finally
       DBSession.UnlockSession;
      end;
    end;
  end;
end; // TEasyDataSet.GetExists


//------------------------------------------------------------------------------
// rebuild index definitions
//------------------------------------------------------------------------------
procedure TEasyDataSet.UpdateIndexDefs;
begin
 if (not isTableOpened) then
  begin
   OpenTable;
   CreateIndexDefs := true;
   CreateIndexDefinitions;
   CloseTable;
  end
 else
  begin
   CreateIndexDefs := true;
   CreateIndexDefinitions;
  end;
end; // TEasyDataSet.UpdateIndexDefs


//------------------------------------------------------------------------------
// sets active buffer to current record (by tablePosition)
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetActiveBuffer;
begin
 FSetActiveBufferFlag := true;
 GetRecord(ActiveBuffer,gmCurrent,false);
 FSetActiveBufferFlag := false;
end;


//------------------------------------------------------------------------------
// find record (conditions specified in FilterText property)
//------------------------------------------------------------------------------
function TEasyDataSet.FindRecord(Restart, GoForward: Boolean): Boolean;
var i,j : integer;
    foundPosition: integer;
    oldFoundRecNo: integer;
label m1;
begin
 DBSession.LockSession;
 try
   CheckBrowseMode;
   DoBeforeScroll;
   SetFound(False);
   UpdateCursorPos;
   CursorPosChanged;

   CheckTableState;
   if (Filter = '') or ((FBDELikeFilter = True) and (Filtered = False))then
    begin
     if (Restart) then
      if (GoForward) then
       First
      else
       Last
     else
      if (GoForward) then
       Next
      else
       Prior;
     if (GoForward) then
      result := not Eof
     else
      result := not Bof;
     goto m1;
    end;
   foundPosition := -1;
   if Restart then
    begin
     foundRecordsNeedUpdate := False;
     FindParser.FilterOptions := FilterOptions;
     if not (foNoPartialCompare in FilterOptions) then
      if (Filter[Length(Filter)-1] <> '*') then
       FindParser.FilterOptions := FindParser.FilterOptions+[foNoPartialCompare];
     FindParser.PreParse(Filter);
     FindParser.Parse;
     // fill found records
     SetLength(foundRecords,visibleRecordCount);
     j := 0;
     for i:=0 to visibleRecordCount-1 do
      if (FindParser.bitsArr[0].GetBit(GetVisRecValue(i))) then
       begin
        foundRecords[j] := GetVisRecValue(i);
        inc(j);
       end;
     foundRecordCount := j;
    end
   else
    // insert / edit / delete was called after FindFirst and between FindNext calls
    if (foundRecordsNeedUpdate) then
     begin
      oldFoundRecNo := foundRecordNo;
      foundRecordsNeedUpdate := False;
      FindParser.Parse;
      // fill found records
      SetLength(foundRecords,visibleRecordCount);
      j := 0;
      for i:=0 to visibleRecordCount-1 do
       if (FindParser.bitsArr[0].GetBit(GetVisRecValue(i))) then
        begin
         foundRecords[j] := GetVisRecValue(i);
         inc(j);
        end;
      foundRecordCount := j;
      // try to restore old position
      if (oldFoundRecNo < foundRecordCount) then
       foundRecordNo := oldFoundRecNo
      else
       foundRecordNo := foundRecordCount;
     end;


   if Restart then
    if GoForward then
     begin
      // First
      if (foundRecordCount > 0) then
       begin
        foundPosition := GetTablePositionByPhysRecNo(foundRecords[0]);
        foundRecordNo := 0;
        result := true;
       end
      else
        result := false;
     end
    else
     begin
      // Last
      if (foundRecordCount > 0) then
       begin
        foundPosition := GetTablePositionByPhysRecNo(foundRecords[foundRecordCount-1]);
        foundRecordNo := foundRecordCount-1;
        result := true;
       end
      else
        result := false;
     end
   else
    if GoForward then
     begin
      // Next
      result := false;
      while (foundRecordNo < foundRecordCount-1) do
       begin
        inc(foundRecordNo);
        foundPosition := GetTablePositionByPhysRecNo(foundRecords[foundRecordNo]);
        if (foundPosition <> -1) then
         begin
          result := true;
          break;
         end;
       end;
     end
    else
     begin
      // Previous
      result := false;
      while (foundRecordNo > 0) do
       begin
        dec(foundRecordNo);
        foundPosition := GetTablePositionByPhysRecNo(foundRecords[foundRecordNo]);
        if (foundPosition <> -1) then
         begin
          result := true;
          break;
         end;
       end;
     end;

   // set table position
   if (result) then
    tablePosition := foundPosition;

  m1:
   if (result and Active) then
     Resync([rmExact,rmCenter]);
   SetFound(Result);

   if Result then
        DoAfterScroll;
 finally
   DBSession.UnlockSession;
 end;
end; // TEasyDataSet.FindRecord(Restart, GoForward: Boolean): Boolean


{$IFDEF D21H}
//------------------------------------------------------------------------------
// clear calc fields
//------------------------------------------------------------------------------
procedure TEasyDataSet.ClearCalcFields(Buffer: NativeInt);
var aBuffer: TRecordBuffer;
begin
 if (CalcFieldsSize > 0) then
 begin
  aBuffer := TRecordBuffer(Pointer(Buffer));
  FillChar(aBuffer[DMHandle.calculatedOffset],CalcFieldsSize,0);
 end;
//  FillChar(PAnsiChar(Buffer+DMHandle.calculatedOffset)^,CalcFieldsSize,0);
end; //TEasyDataSet.ClearCalcFields(Buffer: PAnsiChar);
{$ELSE}
//------------------------------------------------------------------------------
// clear calc fields
//------------------------------------------------------------------------------
procedure TEasyDataSet.ClearCalcFields(Buffer: TRecordBuffer);
begin
 if (CalcFieldsSize > 0) then
  FillChar(Buffer[DMHandle.calculatedOffset],CalcFieldsSize,0);
//  FillChar(PAnsiChar(Buffer+DMHandle.calculatedOffset)^,CalcFieldsSize,0);
end; //TEasyDataSet.ClearCalcFields(Buffer: PAnsiChar);
{$ENDIF}

//------------------------------------------------------------------------------
// for OnFilterRecord Event
//------------------------------------------------------------------------------
function TEasyDataSet.FilterRecord(Buffer: TRecordBuffer): Boolean;
var
 SaveState: TDataSetState;
begin
 Result:=True;
 if ((not Filtered) or (not Assigned(OnFilterRecord)))
  then Exit;
 SaveState:=SetTempState(dsFilter);
 FFilterBuffer:=Buffer;
 OnFilterRecord(self,Result);
 RestoreState(SaveState);
end;


//------------------------------------------------------------------------------
// refreshes data
//------------------------------------------------------------------------------
procedure TEasyDataSet.InternalRefresh;
begin
 DBSession.LockSession;
 try
   if ((not isTableOpened) or (not Active)) then Exit;
    DataEvent(deDataSetChange, 0);
   CreateVisibleRecordsList;
 finally
   DBSession.UnlockSession;
 end;
end; //InternalRefresh;


//------------------------------------------------------------------------------
// use index
//------------------------------------------------------------------------------
procedure TEasyDataSet.OpenIndex(
             		  name : ShortString; // name
                          number : Integer = -1	// number in DMHandle.indexHeaderList
                              );
var
		i,f : Integer;
begin
 DBSession.LockSession;
 try
   if (not isTableOpened) then raise Exception.Create(
      'Error in TEasyDataSet.OpenIndex - table is not opened.');
    i := 0;
    f := 0;
   if (DMHandle.indexHeaderList.Count <= 0) then raise Exception.Create(
      'Error in TEasyDataSet.OpenIndex - empty index header list.');
   if (number = -1) then
    begin
    // if no number supplied
     while i < DMHandle.indexHeaderList.Count do
      begin
        if (pIndexHeaderType(DMHandle.indexHeaderList.Items[i]) = nil) then raise Exception.Create(
        'Error in TEasyDataSet.OpenIndex - index header 0 pointer!');
        if (LowerCase(name) =
          LowerCase(pIndexHeaderType(DMHandle.indexHeaderList.Items[i])^.indexName)) then
         begin
          f := 1;
          break;
         end;//found
       inc(i);
      end;// while
     if (f = 0) then raise Exception.Create(
        'Error in TEasyDataSet.OpenIndex - index "'+name+'" not found!');
     currentIndex := i;
    end // if no number supplied
   else
    begin
     if (i < 0) or (i > DMHandle.indexFileHeader.IndexCount-1) then raise Exception.Create(
        'Error in TEasyDataSet.OpenIndex - index number "'+inttostr(number)+'" not found!');
     currentIndex := number;
    end;

    isIndexUsed := true;

   if (Active and (not VisibleRecordsFreezed)) then
    begin
     CheckMasterRange;
     CreateVisibleRecordsList;
     SetActiveBuffer;
     // replaced to resync to speed up SQL
     // Refresh;
     Resync([]);
    end;
 finally
  DBSession.UnlockSession;
 end;
end; // TEasyDataSet.OpenIndex


//------------------------------------------------------------------------------
// close index
//------------------------------------------------------------------------------
procedure TEasyDataSet.CloseIndex;
begin
 DBSession.LockSession;
 try
  // if (not isIndexUsed) then Exit;
   isIndexUsed := true;
   currentIndex := 0;
   if Active and IsRanged then CancelRange;
   IsRanged := false;
   CreateVisibleRecordsList;
   if (Active and (not VisibleRecordsFreezed)) then
    begin
     SetActiveBuffer;
     // replaced to Resync to speed up SQL
     // Refresh;
     Resync([]);
    end;
 finally
  DBSession.UnlockSession;
 end;
end; // TEasyDataSet.CloseIndex


//------------------------------------------------------------------------------
// builds index
//------------------------------------------------------------------------------
procedure TEasyDataSet.BuildIndex(n : integer);
begin
 DBSession.LockSession;
 try
  DMHandle.BuildIndex(n);
 finally
  DBSession.UnlockSession;
 end;
end; //TEasyDataSet.BuildAllDMHandle.indexes;


//------------------------------------------------------------------------------
// builds all indexes
//------------------------------------------------------------------------------
procedure TEasyDataSet.BuildAllindexes;
begin
 DBSession.LockSession;
 try
  DMHandle.BuildAllIndexes;
 finally
  DBSession.UnlockSession;
 end;
end; //TEasyDataSet.BuildAllDMHandle.indexes;


//------------------------------------------------------------------------------
// updates all indexes
//------------------------------------------------------------------------------
procedure TEasyDataSet.UpdateAllIndexes;
begin
 DBSession.LockSession;
 try
  DMHandle.UpdateAllIndexes;
 finally
  DBSession.UnlockSession;
 end;
end; //TEasyDataSet.UpdateAllDMHandle.indexes;


//------------------------------------------------------------------------------
// check index; returns -1 if index ok;
// if index is invalid returns number of first invalid element
//------------------------------------------------------------------------------
function TEasyDataSet.CheckIndex(n : integer) : integer;
begin
 DBSession.LockSession;
 try
  result := DMHandle.CheckIndex(n);
 finally
  DBSession.UnlockSession;
 end;
end;


//------------------------------------------------------------------------------
// checks all indexes
//------------------------------------------------------------------------------
procedure TEasyDataSet.CheckAllIndexes;
begin
 DBSession.LockSession;
 try
  DMHandle.CheckAllIndexes;
 finally
  DBSession.UnlockSession;
 end;
end; //TEasyDataSet.UpdateAllDMHandle.indexes;


{
//------------------------------------------------------------------------------
// returns number of indexBuffer element, which
// is equal to the record (indentified by position in buffer)
//------------------------------------------------------------------------------
function TEasyDataSet.aaFindIndexValue(
                              indexNum : integer;
                              position : integer;
                              recordCount : Integer = -1
                              ) : integer;
begin
 Result := DMHandle.aaFindIndexValue(indexNum,position,recordCount);
end;


//------------------------------------------------------------------------------
// returns number of indexBuffer element, which
// is equal to the record (indentified by position in buffer)
//------------------------------------------------------------------------------
function TEasyDataset.FindIndexValueForDelete(
                          indexBuffer : array of Integer; // index values
                          position		: Integer; // currentPosition
                          recordCount : Integer = -1;
                          doCheck     : Boolean = false // if false not found
                                      //raises exception, else returns -1
                          ) : Integer;
var i,recCount	: Integer;
    i1,i2: integer;
    bBreak: boolean;
begin
//ShowMessage('find start');
 if (recordCount < 0) then
  recCount := DMHandle.tableHeader.recordCount
 else
  recCount := recordCount;
 result := -1;
 if (recCount > 0) then
  begin
   // dihotomy
   i1 := 0;
   i2 := recCount-1;
   bBreak := false;
   // acending order?
   if (indexBuffer[i1] < indexBuffer[i2]) then
     // ascending order
     repeat
      if (i1 = i2) then
       bBreak := true;
      i := (i1 + i2) div 2;
      if (indexBuffer[i] = position) then
       begin
        result := i;
        break;
       end
      else
       if (indexBuffer[i] < position) then
        if (i1 < i) then i1 := i
        else inc(i1)
       else
        if (i2 > i) then i2 := i
        else dec(i2);
     until bBreak
   else
     // descending order
     repeat
      if (i1 = i2) then
       bBreak := true;
      i := (i1 + i2) div 2;
      if (indexBuffer[i] = position) then
       begin
        result := i;
        break;
       end
      else
       if (indexBuffer[i] > position) then
        if (i1 < i) then i1 := i
        else inc(i1)
       else
        if (i2 > i) then i2 := i
        else dec(i2);
     until bBreak;
  end; // recCount > 0

  if ((result < 0) and (doCheck)) then
    raise Exception.Create(
    'Error in TEasyDataset.FindIndexValueForDelete - indexValue not found, number = '
    + inttostr(currentIndex)
    +', position = '+IntToStr(position) +
    ', recordCount = '+IntToStr(recCount));
end; //TEasyDataset.FindIndexValueForDelete
 }

//------------------------------------------------------------------------------
// compare 2 RecordBuffers using Index settings but
// only first IndexFieldCount fields
// returns -1 (if RecordBuffer1 < RecordBuffer2 in sense of index order),
// 0 (=), 1 (>)
//------------------------------------------------------------------------------
function TEasyDataset.CompareRecordBuffersWithIndex(
                   RecordBuffer1: PAnsiChar; // record buffer 1 to compare
                   RecordBuffer2: PAnsiChar; // record buffer 2 to compare
                   IndexNo: Integer;    // index No where compared
                   IndexFieldCount: Integer // fields from index to use when compare
                           ): integer;
var
   oldIndexCount: integer;
//---------------- variables for optimization -----------------------------
{$include compare_var.inc}
begin
 cmpRecBuf_buffer1 := RecordBuffer2;
 cmpRecBuf_buffer2 := RecordBuffer1;
 cmpRecBuf_pIndexHeader := PIndexHeaderType(DMHandle.IndexHeaderList.Items[IndexNo]);
 oldIndexCount := cmpRecBuf_pIndexHeader^.indexCount;
 cmpRecBuf_pIndexHeader^.indexCount := IndexFieldCount;
 cmpRecBuf_ignoreCase := false;
 cmpRecBuf_bPartialCompare := false;
 cmpRecBuf_find := true;
 {$include compare.inc}
 cmpRecBuf_pIndexHeader^.indexCount := oldIndexCount;
 result := cmpRecBuf_res;
end;// TEasyDataset.CompareRecordBuffersWithIndex


//------------------------------------------------------------------------------
// compare RecordBuffer with record from index using Index settings but
// only first IndexFieldCount fields
// returns -1 (if RecordBuffer < record from index),0 (=), 1 (>)
//------------------------------------------------------------------------------
function TEasyDataset.CompareInIndex(
                   RecordBuffer: PAnsiChar; // record buffer to compare
                   IndexNo: Integer;    // index No where compared
                   PosInIndex: Integer; // record No in index
                   IndexFieldCount: Integer // fields from index to use when compare
                           ): integer;
begin
 DMHandle.allRecBuffer.LockRecordPage(DMHandle.indexes[IndexNo].items[PosInIndex]);
 result := CompareRecordBuffersWithIndex(RecordBuffer,
    DMHandle.allRecBuffer.GetRecordDataPtr(DMHandle.indexes[IndexNo].items[PosInIndex]),
    IndexNo,IndexFieldCount);
 DMHandle.allRecBuffer.UnlockRecordPage(DMHandle.indexes[IndexNo].items[PosInIndex]);
end;// TEasyDataset.CompareInIndex


//------------------------------------------------------------------------------
// find RecordBuffer in Index using its settings but
// applying comparison for only first IndexFieldCount fields
// for exact "=" or nearest match
// returns position in index or -1 if not found
//------------------------------------------------------------------------------
function TEasyDataset.FindInIndex(
                   RecordBuffer: PAnsiChar; // record buffer to compare
                   IndexNo: Integer;    // index No where compared
                   IndexFieldCount: Integer; // fields from index to use when compare
                   bForwardDirection: Boolean; // (Forward / Backward)
                   bExact: Boolean // exact or nearest search
                           ): integer;
var
   oldIndexCount: integer;
   num: integer;
   dx: integer;
   cmp_res: integer;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
  // try to find any match in index
//  findValIns_buffer := allRecBuffer.pData;
  findValIns_recordBuffer := RecordBuffer;
  findValIns_array := aInteger(DMHandle.indexes[IndexNo].items);
  findValIns_pIndex := pIndexHeaderType(DMHandle.indexHeaderList.Items[IndexNo]);
  oldIndexCount := findValIns_pIndex^.indexCount;
  findValIns_pIndex^.indexCount := IndexFieldCount;
  findValIns_recCount := DMHandle.tableHeader.recordCount;
  findValIns_ignoreCase := false;
  findValIns_partialCompare := false;
  cmpRecBuf_find := true;
  {$include find_ind.inc}
  findValIns_pIndex^.indexCount := oldIndexCount;
  num := findValIns_result;

  if (bForwardDirection) then
   dx := 1
  else
   dx := -1;

  // out of bounds?
  if (num < 0) then
   if (bExact) then
     result := -1 // not found
   else
     result := 0 // return first
  else
   if (num >= DMHandle.tableHeader.recordCount) then
    if (bExact) then
     result := -1 // not found
    else
     result := DMHandle.tableHeader.recordCount-1 // return last
   else
     begin
      // found?
      cmp_res := CompareInIndex(RecordBuffer,IndexNo,num,IndexFieldCount);
      if (cmp_res <> 0) then
       if (bExact) then
        result := -1 // not found
       else
        result := num // return nearest
      else
       begin
        // go by direction while record from index matches the condition
        while (cmp_res = 0) do
         begin
          num := num + dx;
          // out of bounds?
          if (num < 0) then
           break;
          if (num >= DMHandle.tableHeader.recordCount) then
           break;
          // compare next index record
          cmp_res := CompareInIndex(RecordBuffer,IndexNo,num,IndexFieldCount);
         end;
        result := num - dx; // last exact match
       end;
     end;
end;// TEasyDataset.FindInIndex


//------------------------------------------------------------------------------
// find RecordBuffer in visible records
// using currentIndex settings but
// applying comparison for only first IndexFieldCount fields
// for exact "=" or nearest match
// returns position in visibleRecords or -1 if not found
//------------------------------------------------------------------------------
function TEasyDataset.FindInVisibleRecords(
                   RecordBuffer: PAnsiChar; // record buffer to compare
                   IndexFieldCount: Integer; // fields from index to use when compare
                   bForwardDirection: Boolean; // (Forward / Backward)
                   bExact: Boolean // exact or nearest search
                           ): integer;
var
   oldIndexCount: integer;
   num: integer;
   dx: integer;
   cmp_res: integer;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
  // try to find any match in index
//  findValIns_buffer := allRecBuffer.pData;
  CheckTableState;
  findValIns_recordBuffer := RecordBuffer;
  findValIns_array := aInteger(visibleRecords.items);
  findValIns_pIndex := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex]);
  oldIndexCount := findValIns_pIndex^.indexCount;
  findValIns_pIndex^.indexCount := IndexFieldCount;
  findValIns_recCount := visibleRecordCount;
  findValIns_ignoreCase := false;
  findValIns_partialCompare := false;
  cmpRecBuf_find := true;
  {$include find_ind.inc}
  findValIns_pIndex^.indexCount := oldIndexCount;
  num := findValIns_result;

  if (bForwardDirection) then
   dx := 1
  else
   dx := -1;

  // out of bounds?
  if (num < 0) then
   if (bExact) then
     result := -1 // not found
   else
     result := 0 // return first
  else
   if (num >= visibleRecordCount) then
    if (bExact) then
     result := -1 // not found
    else
     result := visibleRecordCount-1 // return last
   else
     begin
      // found?
      DMHandle.allRecBuffer.LockRecordPage(visibleRecords.items[num]);
      cmp_res := CompareRecordBuffersWithIndex(RecordBuffer,
              DMHandle.allRecBuffer.GetRecordDataPtr(visibleRecords.items[num]),
              currentIndex,IndexFieldCount);
      DMHandle.allRecBuffer.UnlockRecordPage(visibleRecords.items[num]);
      if (cmp_res <> 0) then
       if (bExact) then
        result := -1 // not found
       else
        result := num // return nearest
      else
       begin
        // go by direction while record from index matches the condition
        while (cmp_res = 0) do
         begin
          num := num + dx;
          // out of bounds?
          if (num < 0) then
           break;
          if (num >= visibleRecordCount) then
           break;
          DMHandle.allRecBuffer.LockRecordPage(visibleRecords.items[num]);
          // compare next visible record
          cmp_res := CompareRecordBuffersWithIndex(RecordBuffer,
             DMHandle.allRecBuffer.GetRecordDataPtr(visibleRecords.items[num]),
             currentIndex, IndexFieldCount);
          DMHandle.allRecBuffer.UnlockRecordPage(visibleRecords.items[num]);
         end;
        result := num - dx; // last exact match
       end;
     end;
end;// TEasyDataset.FindInVisibleRecords


//------------------------------------------------------------------------------
// check is (Filter<>'' and Filtered=true)
//------------------------------------------------------------------------------
function TEasyDataSet.IsFiltered: boolean;
begin
 if (Filtered and (Trim(Filter) <> '')) then
  result := true
 else
  result := false;
end;//TEasyDataSet.IsFiltered


//------------------------------------------------------------------------------
// check is master-detail active
//------------------------------------------------------------------------------
function TEasyDataSet.IsMasterDetail: boolean;
var
  I: integer;
  Fld: TField;
begin
   if FMasterLink.Active and (FMasterLink.Fields <> nil) and
      (FMasterLink.Fields.Count > 0) then
     begin
      // check if active index is appropriate
      Result := False;
      if (FMasterLink.Fields.Count <= GetIndexFieldCount) then
       begin
        Result := True;
        for I := 0 to MasterLink.Fields.Count - 1 do
         begin
          Fld := GetIndexField(I);
          if (Fld = nil) then
           begin
            Result := False;
            break;
           end;
          if (Fld.DataType <> TField(MasterLink.Fields.Items[I]).DataType) then
           if (IsNumericDataType(TField(MasterLink.Fields.Items[I]).DataType) <>
               IsNumericDataType(Fld.DataType)) then
           begin
            Result := False;
            break;
           end;
         end;
       end;
     end
   else
     Result := False;
end;// IsMasterDetail


//------------------------------------------------------------------------------
// returns true if record matches Filter and MasterFields
//------------------------------------------------------------------------------
function TEasyDataSet.IsRecordVisible(
				        recordBuffer :      PAnsiChar; // pointer to record buffer
                bRunOnFilterRecord: Boolean = true
        			   ) : Boolean;
var
  recordID, old: integer;
  value: TETblDataValue;
  oldBuf:        TRecordBuffer;
begin
 Result := true;
 // master/detail
 if IsMasterDetail then
   Result := MasterDetailParser.IsRecordMatches(PAnsiChar(recordBuffer));

  // Range
  if (Result and IsRanged) then
     Result := (CompareRecordBuffersWithIndex(
                   PAnsiChar(RecordBuffer),
                   PAnsiChar(FKeyBuffers[kiRangeStart])+ SizeOf(TKeyBuffer),
                   currentIndex,
                   FKeyBuffers[kiRangeStart]^.FieldCount) >= 0)
     and (CompareRecordBuffersWithIndex(
                   PAnsiChar(RecordBuffer),
                   PAnsiChar(FKeyBuffers[kiRangeEnd])+ SizeOf(TKeyBuffer),
                   currentIndex,
                   FKeyBuffers[kiRangeEnd]^.FieldCount) <= 0);

 // Filter
 if (Result and IsFiltered) then
   Result := FilterParser.IsRecordMatches(PAnsiChar(recordBuffer));

 // SQL Filter expr?
 if (Result and (FSQLFilterExpr <> nil)) then
  begin
    FDirectFilter := True;
    oldBuf := FTemporaryRecordBuffer;
    FTemporaryRecordBuffer := TRecordBuffer(recordBuffer);
    try
     value := TETblExpression(FSQLFilterExpr).GetDataValue(Self);
     if (value.DataType <> ftBoolean) then
      raise ETblException.Create(01071, [Integer(value.DataType)], nil);
     if (value.IsNull or not pBoolean(value.pData)^) then
       Result := False;
    finally
     FDirectFilter := False;
     FTemporaryRecordBuffer := oldBuf;
    end;
  end;

 // OnFilterRecord
 if bRunOnFilterRecord then
  if (Result and Filtered and Assigned(OnFilterRecord)) then
   begin
    Move(PAnsiChar(recordBuffer+DMHandle.recordSize)^,recordID,sizeOf(integer)); //id
    old := tablePosition;
    tablePosition := GetTablePositionByID(recordID);
    SetActiveBuffer;
    OnFilterRecord(self, Result);
    tablePosition := old;
    SetActiveBuffer;
   end;
end; //TEasyDataSet.IsRecordVisible


//------------------------------------------------------------------------------
// is any filter, range, SQLFilter, ...
//------------------------------------------------------------------------------
function TEasyDataSet.IsViewConstrained: Boolean;
begin
  Result := (FMasterLink.Active and (FMasterLink.Fields.Count > 0)) or
                Filtered or IsRanged or (FSQLFilterExpr <> nil) or
                (FSQLTopRowCount <> -1);
end;// IsViewConstrained


//------------------------------------------------------------------------------
// adds record, modifies DMHandle.indexes and restore tablePosition
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaAddRecord(
				        recordBuffer : PAnsiChar // pointer to record buffer
        				        );
var curNum,i,j,k : Integer;
    IsVisible : Boolean;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 CheckTableState;
 cmpRecBuf_find :=  false;
 findValIns_array := nil;
 curNum := DMHandle.aaAddRecord(recordBuffer,currentIndex);
 // update visibleRecords and tablePosition
 if (IsViewConstrained) then
 // filtered
  begin
   // if filtering or master/detail
   IsVisible := IsRecordVisible(recordBuffer,false); // FilterRecord bug fix
   if (IsVisible) then
    begin
     if (visibleRecordCount > 0) then
      begin
       findValIns_recordBuffer := recordBuffer;
       findValIns_array := aInteger(visiblerecords.items);
       findValIns_pIndex := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex]);
       findValIns_recCount := visibleRecordCount;
       findValIns_ignoreCase := false;
       findValIns_partialCompare := false;
       findValIns_search := false;
       {$include find_ind.inc}
       i := findValIns_result;
       visibleRecords.Insert(i,DMHandle.tableHeader.recordCount-1);
       tablePosition := i;
      end
     else
      begin
       visibleRecords.Insert(visibleRecordCount,DMHandle.tableHeader.recordCount-1);
       tablePosition := visibleRecordCount;
      end;
     inc(visibleRecordCount);
    end;
  end
 else
 // not filtered
  begin
     if (curNum < 0) then
      curNum := 0;
//aaStartTime;
     visibleRecords.Insert(curNum,DMHandle.tableHeader.recordCount-1);
//aaStopTime;
     tablePosition := curNum;
   inc(visibleRecordCount);
  end;
 foundRecordsNeedUpdate := True;
{$IFDEF DEBUG_FLAG}
aaWriteToLog('post, tableposition = '+
IntToStr(tablePosition)+
', record count = '+IntToStr(DMHandle.tableHeader.recordCount));
{$ENDIF}
end; //TEasyDataSet.aaAddRecord


//------------------------------------------------------------------------------
// modifies record, modifies DMHandle.indexes and restore tablePosition
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaUpdateRecord(
 				        recordBuffer : PAnsiChar // pointer to record buffer
                  			   );
var curNum,i,j,k : Integer;
    IsVisible: Boolean;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 CheckTableState;
 cmpRecBuf_find :=  false;
 findValIns_array := nil;
 curNum := DMHandle.aaUpdateRecord(recordBuffer,currentIndex,
            visibleRecords.items[tablePosition]);
 // checking filter and master fields
 if (IsViewConstrained) then
 // filtered
  begin
   // if filtering or master/detail
   IsVisible := IsRecordVisible(recordBuffer,false); // FilterRecord bug fix
   if (IsVisible) then
    begin
     if ((CurNum <> tablePosition) and
         (visibleRecordCount > 1)) then
      begin
       findValIns_recordBuffer := recordBuffer;
       findValIns_array := aInteger(visiblerecords.items);
       findValIns_pIndex := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex]);
       findValIns_recCount := visibleRecordCount;
       findValIns_ignoreCase := false;
       findValIns_partialCompare := false;
       findValIns_search := false;
       {$include find_ind.inc}
       i := findValIns_result;
       visibleRecords.MoveTo(tablePosition,i);
       tablePosition := i;
      end;
     // if not indexed or only 1 record visible - do nothing
    end //visible
   else
    //not visible
    begin
      visibleRecords.Delete(tablePosition);
      dec(visibleRecordCount);
      if (tablePosition >= visibleRecordCount) then
       dec(tablePosition);
    end;
  end
 else
 // not filtered
  begin
     if (CurNum <> tablePosition)
      and
//--------- uncommented in 5.70 ------------------------------------------------
        (CurNum <> (tablePosition+1))
        then
//--------- uncommented in 5.70 ------------------------------------------------
      visibleRecords.MoveTo(tablePosition,CurNum);
     if (CurNum < DMHandle.tableHeader.recordCount-1) then
      tablePosition := CurNum
     else
      tablePosition := DMHandle.tableHeader.recordCount-1;
  end; //end not filtered
 foundRecordsNeedUpdate := True;
end; //TEasyDataSet.aaUpdateRecord


//------------------------------------------------------------------------------
// deletes record, modifies DMHandle.indexes and restore tablePosition
//------------------------------------------------------------------------------
procedure TEasyDataSet.aaDeleteRecord;
var
    IsVisible : Boolean;
    curNum,i,recPos,recCount  : Integer;
begin
 CheckTableState;
// cmpRecBuf_find := false;
 // check filters, master/detail, etc.
 recPos := visibleRecords.items[tablePosition];
 recCount := DMHandle.tableHeader.recordCount;
 // if filtering or master/detail
 DMHandle.allRecBuffer.LockRecordPage(recCount-1);
 IsVisible := IsRecordVisible(
             DMHandle.allRecBuffer.GetRecordDataPtr(recCount-1),false); // FilterRecord bug fix
 DMHandle.allRecBuffer.UnlockRecordPage(recCount-1);
 // searching for the last physical record in visibleRecords
 if (recPos < recCount-1) and (IsVisible) then
  i := GetTablePositionByPhysRecNo(recCount-1)
 else
  i := -1;
 curNum := DMHandle.aaDeleteRecord(currentIndex,recPos);
// if not last record and index used - update visibleRecords last record element
if (recPos < recCount-1)then
begin
 if (IsViewConstrained) then
 // filtered
  begin
     if (IsVisible) then
       visibleRecords.items[i] := recPos;
  end
 else
 // not filtered
   visibleRecords.items[CurNum] := recPos;
end;
 visibleRecords.Delete(tablePosition);
 dec(visibleRecordCount);
 if (visibleRecordCount <= 0) then
  tablePosition := -1
 else
  if (tablePosition >= visibleRecordCount) then
   tablePosition := visibleRecordCount-1;
 foundRecordsNeedUpdate := True;
end; //TEasyDataSet.aaDeleteRecord


//------------------------------------------------------------------------------
// returns physical record number
//------------------------------------------------------------------------------
function TEasyDataSet.GetVisRecValue (
                            recordNum : integer // table position
                            ) : integer; // physical record number
begin
 CheckTableState;
 if (not visRecUpdated) then
  CreateVisibleRecordsList;
 Result := visibleRecords.items[recordNum];
end; //TEasyDataSet.GetVisRecValue


//------------------------------------------------------------------------------
// create index definitions in IndexDefs
//------------------------------------------------------------------------------
procedure TEasyDataSet.CreateIndexDefinitions;
var i,j         : Integer;
    indexHeader : pIndexHeaderType;
    s,s1,s2     : AnsiString;
    indCaseIns  : AnsiString;
    indDesc     : AnsiString;
    Opt         : TIndexOptions;
//---------------- variables for optimization -----------------------------
{$include check_var.inc}
 chkfld_result : Boolean;
begin
 IndexDefs.Clear;
 FRestructureIndexDefs.Clear;
 chkfld_set := not isTableOpened;
 if (chkfld_set) then
  OpenTable;
//aaWriteToLog('creation - '+inttostr(DMHandle.indexFileHeader.indexCount));
 with IndexDefs do
  for i := 0 to DMHandle.indexFileHeader.indexCount-1 do
    begin
     indexHeader := pIndexHeaderType(DMHandle.indexHeaderList.Items[i]);
     s := indexHeader.indexName;
     Opt := [];
     if (indexHeader.ignoreCase) then
      Opt:= Opt + [ixCaseInsensitive];
     if (indexHeader.descending) then
      Opt:= Opt + [ixDescending];
 //    if (indexHeader.indexFields[0] = -1) then
//       Opt:= Opt + [ixPrimary];
     if (ixPrimary in indexHeader.indexOptions) then
      Opt := Opt + [ixPrimary];
     if (ixUnique in indexHeader.indexOptions) then
      begin
       // ClientDataset bug fix
       if (DMHandle.tableHeader.ShowAutoInc = AutoIncOn) or
          (indexHeader.indexFields[0] <> -1) then
        Opt := Opt + [ixUnique];
      end;
     s1 := '';
     indCaseIns := '';
     indDesc := '';
     // analyzing names, making DescFields, CaseInsFields
     for j := 0 to indexHeader.indexCount-1 do
      begin
       if (indexHeader.indexFields[j] >= 0) then
        s2 := pFieldHeaderType(DMHandle.fieldHeaderList.Items[indexHeader.indexFields[j]])^.fieldName
       else
        begin
         s2 :=  DMHandle.tableHeader.sequenceName;
         if (j > 0) then
           s1 := s1 + ';'+s2
         else
         // first field
           s1 := s2;
         continue;
        end;
       if (j > 0) then
         s1 := s1 + ';'+s2
       else
       // first field
         s1 := s2;

       // desc fields
       chkfld_buffer := indexHeader.indexOrders;
       chkfld_fieldNum := j;
       {$include check_fields.inc}
       if (not chkfld_result) then
        begin
         if (Length(indDesc) > 0) then
          indDesc := indDesc + ';' + s2
         else
          indDesc := s2;
        end;
       // caseIns fields
       chkfld_buffer := indexHeader.indexCaseIns;
       {$include check_fields.inc}
       if (chkfld_result) then
        begin
         if (Length(indCaseIns) > 0) then
          indCaseIns := indCaseIns + ';' + s2
         else
          indCaseIns := s2;
        end;
      end; // for j=0 to indexCount-1
//    if (IndexDefsStored) then

//     if (DMHandle.tableHeader.ShowAutoInc = AutoIncOff) then
//      if (UpperCase(s1) = UpperCase(DMHandle.tableHeader.sequenceName)) then
//       continue;
     with AddIndexDef do
      begin
       name := s;
       fields := s1;
       options := opt;
       CaseInsFields := indCaseIns;
       DescFields := indDesc;
      end;
     if (s[1] <> '@') and (s[1] <> '$') then
      begin
       FRestructureIndexDefs.Add(s,s1,opt);
       FRestructureIndexDefs.Items[FRestructureIndexDefs.Count-1].CaseInsFields := indCaseIns;
       FRestructureIndexDefs.Items[FRestructureIndexDefs.Count-1].DescFields := indDesc;
       FRestructureIndexDefs.Items[FRestructureIndexDefs.Count-1].Options := opt;
       FRestructureIndexDefs.Items[FRestructureIndexDefs.Count-1].CaseInsFields := indCaseIns;
       FRestructureIndexDefs.Items[FRestructureIndexDefs.Count-1].DescFields := indDesc;
      end;
{
    if (IndexDefsStored) then
     begin
      Items[i].CaseInsFields := indCaseIns;
      Items[i].DescFields := indDesc;
      Items[i].Options := opt;
     end;
}
    end; // for i
end; // TEasyDataSet.CreateIndexDefinitions


//------------------------------------------------------------------------------
// returns number of fields that comprise the current index
//------------------------------------------------------------------------------
function TEasyDataSet.GetIndexFieldCount : Integer;
begin
 if (not isIndexUsed) then
  // index is not used
  result := 0
 else
  result := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.indexCount;
//  result := DMHandle.indexFileHeader.indexCount;
end; // TEasyDataSet.GetIndexFieldCount


//------------------------------------------------------------------------------
// returns index name, if index is used; otherwise returns ''
//------------------------------------------------------------------------------
function TEasyDataSet.GetIndexName: AnsiString;
begin
 Result := FIndexName;
end; //TEasyDataSet.GetIndexName


//------------------------------------------------------------------------------
// open index with specified name; if name='' then closes index
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetIndexName(const Name: AnsiString);
var
  OldIndexName, OldIndexFieldNames: AnsiString;
begin
 DBSession.LockSession;
 try
// if (Name <> FIndexName) then
   OldIndexName := FIndexName;
   OldIndexFieldNames := FIndexFieldNames;
   FIndexName := Name;
   FIndexFieldNames := '';
   if (not isTableOpened) then
    Exit;

   if (currentIndex >= 0) and (currentIndex < DMHandle.indexHeaderList.Count) then
    if (LowerCase(Name) =
        LowerCase(pIndexHeaderType(DMHandle.indexHeaderList.Items[CurrentIndex])^.indexName)) then
     Exit;

   if (Name <> '') then
    begin
     FreezeVisibleRecords;
     try
      CloseIndex;
      try
       OpenIndex(Name);
      except
       if (OldIndexName <> '') then
        IndexName := OldIndexName
       else
        IndexFieldNames := OldIndexFieldNames;
       raise;
      end;
     finally
      UnfreezeVisibleRecords;
      if (not VisibleRecordsFreezed) then
       if (Active) then
        begin
         UpdateCursorPos; // bug fix to restore old cursor position
         SetActiveBuffer;
         // Refresh
         Resync([]);
        end;
     end;
    end
   else
    CloseIndex;
 finally
   DBSession.UnlockSession;
 end;
end; // TEasyDataSet.SetIndexName(const Name: AnsiString)


//------------------------------------------------------------------------------
// returns index field names, if index is used; otherwise returns ''
//------------------------------------------------------------------------------
function TEasyDataSet.GetIndexFieldNames : AnsiString;
begin
 Result := FIndexFieldNames;
end; // TEasyDataSet.GetIndexFieldNames


//------------------------------------------------------------------------------
// open index with specified index fields; if name='' then closes index
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetIndexFieldNames(const Value: AnsiString);
var
  l : integer;
begin
 FIndexFieldNames := Value;
 FIndexName := '';
 if (not isTableOpened) then
  Exit;

 CloseIndex;
// CreateIndexDefinitions;
 if (value = '') then Exit;

 // find index
 l := GetIndexNoByFields(FIndexFieldNames);
 if (l > -1) then
   OpenIndex('',l) // open found index
 else
  raise Exception.Create('Index for fields "'+FIndexFieldNames+'" does not exist.');
end; // TEasyDataSet.SetIndexFieldNames(const Value: AnsiString)


//------------------------------------------------------------------------------
// get index field
//------------------------------------------------------------------------------
function TEasyDataSet.GetIndexField(Index: Integer): TField;
var
  FieldNo: Integer;
begin
  if (pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.indexFields[Index] < 0) then
   begin
    if (FindField(DMHandle.tableHeader.sequenceName) <> nil) then
     Result := FieldByName(DMHandle.tableHeader.sequenceName)
    else
     Result := nil;
    Exit;
   end;
  if  (Index >= GetIndexFieldCount) then raise Exception.Create(
    'Error in TEasyDataSet.GetIndexField - invalid index, index = '+inttostr(Index)+'.');

  FieldNo := pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.indexFields[Index];
  Result := FieldByNumber(FieldNo+1);
  if (Result = nil) then raise Exception.Create(
   'Error in TEasyDataSet.GetIndexField - no such field, FieldNo = '+inttostr(FieldNo)+'.');
end; // TEasyDataSet.GetIndexField(Index: Integer): TField


//------------------------------------------------------------------------------
// set index field
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetIndexField(Index: Integer; Value: TField);
begin
  if (not (GetIndexField(Index) is TLargeIntField)) then
    GetIndexField(Index).Assign(Value)
  else
    if (Value.IsNull) then
      GetIndexField(Index).Clear
    else
      TLargeIntField(GetIndexField(Index)).AsLargeInt := TLargeIntField(Value).AsLargeInt;
end; // TEasyDataSet.SetIndexField(Index: Integer; Value: TField);


//------------------------------------------------------------------------------
// set database name
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetDatabaseName(name : AnsiString);
begin
 Active := false;
 if (name <> '') then
  DatabaseFileName := ''; // mutually exclusive
 FDatabaseName := name;
end; //TEasyDataSet.SetDatabaseName


//------------------------------------------------------------------------------
// set database file name
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetDatabaseFileName(FileName : AnsiString);
begin
 Active := false;
 if (name <> '') then
  DatabaseName := ''; // mutually exclusive
 FDatabaseFileName := FileName;
end;// TEasyDataSet.SetDatabaseFileName


//------------------------------------------------------------------------------
// sets session name
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetSessionName(const Value: AnsiString);
begin
  CheckInactive;
  FSessionName := Value;
  DataEvent(dePropertyChange, 0);
end;// SetSessionName


//------------------------------------------------------------------------------
// gets session
//------------------------------------------------------------------------------
function TEasyDataSet.GetDBSession: TEasySession;
begin
  if (DBHandle <> nil) then
    Result := DBHandle.Session
  else
    Result := Sessions.FindSession(SessionName);
  if Result = nil then
    Result := ETblDefaultSession;
end;// GetDBSession


//------------------------------------------------------------------------------
// gets autoindexes
//------------------------------------------------------------------------------
function TEasyDataSet.GetAutoIndexes: Boolean;
var
  IndexList: TStringList;
  i, AutoIndexCount: integer;
begin
  // get from variable or detect?
  if (not Active) then
   Result := FAutoIndexes
  else
   begin
    IndexList := TStringList.Create;
    try
     // detect auto-indexes
     GetIndexNames(IndexList);
     AutoIndexCount := 0;
     for i:=0 to IndexList.Count-1 do
      if (IndexList.Strings[i][1] = '@') then
       Inc(AutoIndexCount);
     Result := (AutoIndexCount > 1);
    finally
     IndexList.Free;
    end;
   end;
end;// GetAutoIndexes


//------------------------------------------------------------------------------
// returns current version text
//------------------------------------------------------------------------------
function TEasyDataSet.GetCurrentVersionText : AnsiString;
var c : Char;
begin
{$IFDEF D17H}
 c := FormatSettings.DecimalSeparator;
 FormatSettings.DecimalSeparator := '.';
 try
   result := FloatToStrF(internalCurrentVersion,ffFixed,3,2) + ' ' + internalCurrentVersionText;
 finally
   FormatSettings.DecimalSeparator := c;
 end;
{$ELSE}
 c := DecimalSeparator;
 DecimalSeparator := '.';
 try
   result := FloatToStrF(internalCurrentVersion,ffFixed,3,2) + ' ' + internalCurrentVersionText;
 finally
   DecimalSeparator := c;
 end;
{$ENDIF}
end; // GetCurrentVersionText


//------------------------------------------------------------------------------
// returns current version text
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetCurrentVersionText (s: AnsiString);
begin
 s := GetCurrentVersionText;
end; // GetCurrentVersionText


//------------------------------------------------------------------------------
// checks if table is encrypted
//------------------------------------------------------------------------------
function TEasyDataSet.GetEncrypted : Boolean;
begin
 if (not isTableOpened) then
  result := FEncrypted
 else
  result := DMHandle.tableHeader.cipherUsed;
end; //GetEncrypted


//------------------------------------------------------------------------------
// get cache enabled
//------------------------------------------------------------------------------
function TEasyDataSet.GetCacheEnabled: Boolean;
begin
 Result := not FFastOpen;
end;// GetCacheEnabled


//------------------------------------------------------------------------------
// set cache enabled
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetCacheEnabled(Value: Boolean);
begin
 FFastOpen := not Value;
end;// SetCacheEnabled


//------------------------------------------------------------------------------
// return table position - No of record in visible records with specified ID
//------------------------------------------------------------------------------
function TEasyDataSet.GetTablePositionByID(id: integer;
                                           IgnoreVisibleRecords: Boolean=False;
                                           ReturnPhysRecNo: Boolean=False): integer;
var opArr: array of TSearchOperation;
    opCount: integer;
begin
 if (State <> dsInsert) and (State <> dsEdit) then
  CheckTableState;

 if (FFreezeVisibleRecordCount > 0) then
  raise ETblException.Create(01089, Self);

// if (visibleRecordCount > 0) then
  begin
   opCount := 1;
   SetLength(opArr, opCount);
   opArr[0].FieldName := DMHandle.tableHeader.sequenceName;
   opArr[0].FieldNo := -1;
   opArr[0].SearchOp := soEQ;
   PrepareValueBuffer(opArr[0].FieldNo,opArr[0].SearchOp,
                         IntToStr(id),opArr[0].ValueBuffer);

   if ((pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.indexFields[0] = -1)
        and (not IgnoreVisibleRecords)
        and (not ReturnPhysRecNo)) then
    begin
     // first field in current index is autoInc field -
     // this means that visible records order corresponds
     // physical order
     result := FindInVisibleRecords(opArr[0].ValueBuffer,
                      1,TRUE,TRUE);
    end
   else
    begin
     // find in current index
     result := FindInIndex(opArr[0].ValueBuffer,0,
                      1,TRUE,TRUE);
     if (result >= 0) and (not ReturnPhysRecNo) then
      begin
       result := DMHandle.indexes[0].items[result];
       result := GetTablePositionByPhysRecNo(result);
      end;
    end;

   FreeRecordBuffer(TRecordBuffer(opArr[0].ValueBuffer));
   opArr := nil;


{
   // get phys recNo
   result := InternalLocate(opArr,opCount,[]);
   // get table position
   if (result >= 0) then
    result := GetTablePositionByPhysRecNo(result);
}
  end
// else
//  result := -1;
end;


//---------------------------- Searching ---------------------------------------
// returns false if no records were found, otherwise returns true
// and set tablePosition to the first record found
// this function uses opened index, if fieldName - name of the first
// index field (primary index)
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetMatchedRecords(
     searchOperation : TSearchOperation; // search operation record
     curFilterOptions : TFilterOptions;
     var recordBits : TBitsArray);
var i : Integer;
    foundRecords : aInteger;
    recCount : Integer;
    bIgnoreCase : boolean;
    bWideString: boolean;
    offset : integer;
    bMemo:   Boolean;
    ms:      TMemoryStream;
{$HINTS OFF}
function IsFieldNull(RecNo, FieldNo: integer): Boolean;
{$include check_var.inc}
 chkfld_result : Boolean;
begin
  chkfld_fieldNum := FieldNo;
  chkfld_buffer := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(RecNo)+DMHandle.recNullOffset);
{$include check_fields.inc}
  Result := chkfld_result;
end;
{$HINTS ON}

begin
 // no records
 if (DMHandle.tableHeader.recordCount <= 0) then
  exit;

 // case sensivity flag
 if (foCaseInsensitive in curFilterOptions) then
  bIgnoreCase := true
 else
  bIgnoreCase := false;
  bMemo := false;
  bWideString := false;
  if (searchOperation.FieldNo >= 0) then
   begin
    if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[searchOperation.FieldNo])^.fieldType = ftWideString) then
     bWideString := true;
    if ((pFieldHeaderType(DMHandle.fieldHeaderList.Items[searchOperation.FieldNo])^.fieldType = ftMemo) or
        (pFieldHeaderType(DMHandle.fieldHeaderList.Items[searchOperation.FieldNo])^.fieldType = ftFmtMemo)) then
     bMemo := true;
    offset := DMHandle.fieldOffsets[searchOperation.FieldNo];
   end
  else
   offset := DMHandle.recordSize;
  // if Like or Not Like operator
  if (searchOperation.SearchOp = soLike) or
     (searchOperation.SearchOp = soNotLike) then
   begin
    if (searchOperation.SearchOp = soLike) then
     begin
      for i:=0 to DMHandle.tableHeader.RecordCount-1 do
       if (not IsFieldNull(i,searchOperation.FieldNo)) then
       if bWideString then
        begin
         if IsWideStrMatchPattern(PWideChar(DMHandle.allRecBuffer.GetRecordDataPtr(i)
                    +offset),
                     PWideChar(searchOperation.ValueBuffer+offset),
                     bIgnoreCase) then
                recordBits.SetBit(i,true);
        end
       else
        begin
         if (not bMemo) then
          begin
           if IsStrMatchPattern(PAnsiChar(PWideChar(DMHandle.allRecBuffer.GetRecordDataPtr(i)
                      +offset)),
                       PAnsiChar(searchOperation.ValueBuffer+offset),
                       bIgnoreCase) then
             recordBits.SetBit(i,true);
          end
         else
          begin
           // memo fields
           ms := TMemoryStream.Create;
           try
             try
//aaWriteToLog('memo field #'+IntToStr(searchOperation.FieldNo));
              DMHandle.aaReadBLOBValue(ms,searchOperation.FieldNo,i);
              ms.Size := ms.Size+1;
              PAnsiChar(PAnsiChar(ms.Memory) + ms.Size - 1)^ := #0;
//aaWriteToLog('memo field in record #'+IntToStr(i)+', size = '+IntToStr(ms.size)+', value: '+#13#10+AnsiString(PAnsiChar(ms.Memory)));
//aaWriteToLog('offset = '+IntToStr(offset)+', condition: '+#13#10+AnsiString(PAnsiChar(searchOperation.ValueBuffer+offset)));

              if IsStrMatchPattern(ms.Memory,
                         PAnsiChar(searchOperation.ValueBuffer+offset),
                         bIgnoreCase) then
                recordBits.SetBit(i,true);
{
               begin
                recordBits.SetBit(i,true);
                aaWriteToLog('True'+#13#10);
               end
              else
                aaWriteToLog('False'+#13#10);
}
             except
             end;
           finally
             ms.Free;
           end;
          end;
        end;
     end
    else
     begin
      for i:=0 to DMHandle.tableHeader.RecordCount-1 do
       if (not IsFieldNull(i,searchOperation.FieldNo)) then
       if bWideString then
        begin
         if not IsWideStrMatchPattern(PWideChar(PWideChar(DMHandle.allRecBuffer.GetRecordDataPtr(i)
                     +DMHandle.fieldOffsets[searchOperation.FieldNo])),
                     PWideChar(searchOperation.ValueBuffer+DMHandle.fieldOffsets[searchOperation.FieldNo]),
                     bIgnoreCase) then
                recordBits.SetBit(i,true);
        end
       else
        begin
         if not IsStrMatchPattern(PAnsiChar(PWideChar(DMHandle.allRecBuffer.GetRecordDataPtr(i)
                     +DMHandle.fieldOffsets[searchOperation.FieldNo])),
                     PAnsiChar(searchOperation.ValueBuffer+DMHandle.fieldOffsets[searchOperation.FieldNo]),
                     bIgnoreCase) then
                recordBits.SetBit(i,true);
        end;
     end;
    exit;
   end;

   // get array of found records
   GetMatchedRecordsArray(searchOperation,curFilterOptions,aagmrReturnArray,FoundRecords,recCount);

   // set bits of found records
   for i:=0 to recCount-1 do
      recordBits.SetBit(foundRecords[i],true);
end;//TEasyDataSet.GetMatchedRecords


//------------------------------------------------------------------------------
// return matched records array
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetMatchedRecordsArray(
     searchCondition  : TSearchOperation; // search condition
     curFilterOptions : TFilterOptions; // current search options
     mode             : TaaGMRMode; // return array or length or first record?
     var FoundRecords : aInteger; // array of found records No
     var FoundRecordCount : Integer // count of found records
     );
var pos,i,j,f,search_index,k : Integer;
    recCount : Integer;
    IndexHeader : IndexHeaderType;
    bIgnoreCase : boolean;
    bPartialCompare : boolean;
    IsPrimaryKey : boolean;
    bLikeValue : boolean;
    bMatches: Boolean;
//---------------- variables for optimization -----------------------------
{$include find_ind_var.inc}
begin
 // index exists?
 if (GetIndexNoByFields(SearchCondition.FieldName, '',
                        not (foCaseInsensitive in curFilterOptions)) = -1) then
  begin
    // loop for all records
    i := 0;
    recCount := 0;
    while (i < DMHandle.tableHeader.recordCount) do
     begin
      bMatches := IsRecordMatches(searchCondition, curFilterOptions,
         DMHandle.allRecBuffer.GetRecordDataPtr(i));
      if (bMatches) then
       // special branch for locate
       if (mode = aagmrReturnOneRecordOnly) then
        begin
         recCount := 1;
         SetLength(foundRecords,recCount);
         foundRecords[0] := i;
         break;
        end
       else
        begin
         Inc(recCount);
         SetLength(foundRecords,recCount);
         foundRecords[recCount-1] := i;
        end;
      inc(i);
     end;
   FoundRecordCount := recCount;
   exit;
  end;

 // index exists
 cmpRecBuf_res := 3;
 cmpRecBuf_buffer2 := nil;
 cmpRecBuf_pIndexHeader := nil;

 // case sensivity flag
 if (foCaseInsensitive in curFilterOptions) then
  bIgnoreCase := true
 else
  bIgnoreCase := false;

 // partial compare flag
 bPartialCompare := SearchCondition.bPartialCompare or
                     (not (foNoPartialCompare in curFilterOptions));

  // if Like or Not Like operator
  if (SearchCondition.SearchOp = soLike) or
     (SearchCondition.SearchOp = soNotLike) then
    Raise Exception.Create('TEasyDataSet.GetMatchedRecordsArray - Like operator is not supported in GetMatchedRecordsArray procedure.');


 //-------------------------- if index used ---------------------------
   // Get index num
   if (SearchCondition.FieldNo = -1) then
    isPrimaryKey := true
   else
    isPrimaryKey := false;


{  if (bIgnoreCase) and (not isPrimaryKey) and
  ((pFieldHeaderType(DMHandle.fieldHeaderList.Items[SearchCondition.FieldNo])^.fieldType
    = ftString) or
  (pFieldHeaderType(DMHandle.fieldHeaderList.Items[SearchCondition.FieldNo])^.fieldType
    = ftWideString)) then
   search_index := DMHandle.InternalGetIndexNo('@@'+SearchCondition.FieldName)
  else
   search_index := DMHandle.InternalGetIndexNo('@'+SearchCondition.FieldName);
}

 search_index := GetIndexNoByFields(SearchCondition.FieldName, '', not bIgnoreCase);
//aaStopTime;
 BuildIndex(search_index);
//aaStartTime;
{
  if (CheckIndex(search_Index) >= 0) then
     raise Exception.Create('');
 }
  IndexHeader.indexCount := 1; // use only primary index
  SetLength(IndexHeader.indexFields,1);
  if (IsPrimaryKey) then
   IndexHeader.indexFields[0] := -1
  else
   IndexHeader.indexFields[0] := SearchCondition.FieldNo;
  IndexHeader.indexOrders := AllocMem(1);
  IndexHeader.indexOrders^ := chr($FF);
  IndexHeader.indexCaseIns := AllocMem(1);
  IndexHeader.indexCaseIns^ := chr($00);
  IndexHeader.indexName := '';
  IndexHeader.ignoreCase := false;
  IndexHeader.descending := false;
   // set default [i,j]
 cmpRecBuf_find := true;
 findValIns_recordBuffer := SearchCondition.ValueBuffer;
 findValIns_array := aInteger(DMHandle.indexes[search_Index].items);
 findValIns_pIndex := @IndexHeader;
 findValIns_recCount := DMHandle.tableHeader.recordCount;
 findValIns_ignoreCase := bIgnoreCase;
 findValIns_partialCompare := bPartialCompare;
 findValIns_search := true;
 {$include find_ind.inc}
 pos := findValIns_result;
{
   pos := FindIndexValueForInsert(buffer,SearchCondition.ValueBuffer,
          DMHandle.indexes[search_index].items,
  	  @IndexHeader,DMHandle.tableHeader.recordCount,
          bIgnoreCase);
 }

   if (pos >= DMHandle.tableHeader.recordCount) then
    cmpRecBuf_res := 2 // no equal records, all records lower then specified by value
   else
    begin
     // special branch for locate
     if (mode = aagmrReturnOneRecordOnly) and
          (SearchCondition.SearchOp = soEQ) and
          (cmpRecBuf_res = 0) then
      begin
         recCount := 1;
         FoundRecordCount := recCount;
         SetLength(foundRecords,recCount);
         foundRecords[0] := DMHandle.indexes[search_index].items[pos];
         SetLength(IndexHeader.indexFields,0);
         FreeMem(IndexHeader.indexOrders);
         FreeMem(IndexHeader.indexCaseIns);
         exit;
      end
     else
     // special branch for FindNearest
     if (mode = aagmrReturnOneRecordOnly) and
        (
         ((SearchCondition.SearchOp = soGTE) and
          ((cmpRecBuf_res = 0) or (cmpRecBuf_res = 1))) or
         ((SearchCondition.SearchOp = soGT) and
          (cmpRecBuf_res = 1))
        ) then
      begin
         recCount := 1;
         FoundRecordCount := recCount;
         SetLength(foundRecords,recCount);
         foundRecords[0] := DMHandle.indexes[search_index].items[pos];
         SetLength(IndexHeader.indexFields,0);
         FreeMem(IndexHeader.indexOrders);
         FreeMem(IndexHeader.indexCaseIns);
         exit;
      end;

      cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
              DMHandle.indexes[search_index].items[pos]));
      cmpRecBuf_buffer2 := SearchCondition.valueBuffer;
      cmpRecBuf_pIndexHeader := @IndexHeader;
      cmpRecBuf_ignoreCase := bIgnoreCase;
      cmpRecBuf_bPartialCompare := bPartialCompare;
      {$include compare.inc}
    {
    res := CompareRecordBuffer(PAnsiChar(buffer+GetIndexValue(search_index,pos)*size),
         SearchCondition.valueBuffer,
         @IndexHeader,bIgnoreCase,SearchCondition.bPartialCompare);
         }
    end;
   i := 0;
   j := -1;
   if (cmpRecBuf_res = 0) then
    begin
     // searching first equal record
     i := pos-1;
     while (i >= 0) do
      begin
       cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
              DMHandle.indexes[search_index].items[i]));
      {$include compare.inc}
      {
       res := CompareRecordBuffer(PAnsiChar(buffer+GetIndexValue(search_index,i)*size),SearchCondition.valueBuffer,
           @IndexHeader,bIgnoreCase,SearchCondition.bPartialCompare);
           }
       if (cmpRecBuf_res <> 0) then break;
       dec(i);
      end;
     if (cmpRecBuf_res = 0) then
      i := 0 //first record
     else
      inc(i); //not first record
     cmpRecBuf_res := 0;
     // searching last equal record
     j := pos+1;
     while (j < DMHandle.tableHeader.recordCount) do
      begin
       cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
              DMHandle.indexes[search_index].items[j]));
      {$include compare.inc}
      {
        res := CompareRecordBuffer(PAnsiChar(buffer+GetIndexValue(search_index,j)*size),SearchCondition.ValueBuffer,
           @IndexHeader,bIgnoreCase,SearchCondition.bPartialCompare);
           }
       if (cmpRecBuf_res <> 0) then
        break;
       inc(j);
      end;
     if (cmpRecBuf_res = 0) then
      j := DMHandle.tableHeader.recordCount-1 //last record
     else
      dec(j); //not last record
     cmpRecBuf_res := 0;
    end; // if res=0

   // now all equal records are in [i,j] interval of the DMHandle.indexes[search_index]
   if (SearchCondition.SearchOp = soEQ) and (cmpRecBuf_res = 0) then
    begin
     // '='
     ; // [i,j] - cmpRecBuf_result set
     // no actions, [i,j] - default
    end // =
   else
   if (SearchCondition.SearchOp = soLT) then
    begin
     // '<'
       // ascending
       if (cmpRecBuf_res = 0) then
  	     j := i-1 //before first equal record
       else
         j := pos-1;
       i := 0;
    end // <
   else
   if (SearchCondition.SearchOp = soGT) then
    begin
     // '>'
       // ascending
       if (cmpRecBuf_res = 0) then
  	     i := j+1 //before first equal record
       else
         i := pos;
       j := DMHandle.tableHeader.recordCount - 1;
    end
   else
   if (SearchCondition.SearchOp = soLTE) then
    begin
     // '<='
       // ascending
       if (cmpRecBuf_res <> 0) then
         j := pos-1;
       i := 0;
    end// '<='
   else
   if (SearchCondition.SearchOp = soGTE) then
    begin
     // '>='
       // ascending
       if (cmpRecBuf_res <> 0) then
         i := pos;
       j := DMHandle.tableHeader.recordCount - 1;
    end;
   foundRecords := nil;
   foundVisibleRecordsList.Clear;
   recCount := 0;
  // filling foundRecords
   if (SearchCondition.SearchOp = soNEQ) then
    begin
     // '<>'
     if (i > j) then
      begin
       // all records not equal ('<>')
       recCount := DMHandle.tableHeader.recordCount;
       if (mode = aagmrReturnOneRecordOnly) then
        recCount := 1;
       SetLength(foundRecords,recCount);
       if (mode <> aagmrReturnCountOnly) then
        DMHandle.indexes[search_index].CopyTo(foundRecords,0,recCount);
//       foundRecords := Copy(DMHandle.indexes[search_index].items,0,recCount);
      end
     else
      if ((i = 0) and (j = DMHandle.tableHeader.recordCount-1)) then
       begin
        // all records equal
        recCount := 0;
       end
      else
       begin
        // some records are equal and some not equal
        if (i > 0) then
          recCount := i;
        if (j < DMHandle.tableHeader.recordCount-1) then
          recCount := recCount + DMHandle.tableHeader.recordCount-1 - j;
        if (mode = aagmrReturnOneRecordOnly) then
         recCount := 1;
        SetLength(foundRecords,recCount);
        f := 0;
        if (mode <> aagmrReturnCountOnly) then
         begin
          for k := 0 to i-1 do
           begin
            if ((mode = aagmrReturnOneRecordOnly) and (f > 0)) then
             break;
            foundRecords[f] := DMHandle.indexes[search_index].items[k];
            inc(f);
           end;
          for k := j+1 to DMHandle.tableHeader.recordCount-1 do
           begin
            if ((mode = aagmrReturnOneRecordOnly) and (f > 0)) then
             break;
            foundRecords[f] := DMHandle.indexes[search_index].items[k];
            inc(f);
           end;
         end;
       end; // some records are equal and some not equal
    end // '<>'
   else
    begin
     // search not '<>'
     if (j >= i) then
      begin
       recCount := j - i+1;
       if (mode = aagmrReturnOneRecordOnly) then
         recCount := 1;
       SetLength(foundRecords,recCount);
       if (mode <> aagmrReturnCountOnly) then
        DMHandle.indexes[search_index].CopyTo(foundRecords,i,recCount);
      end
     else
      recCount := 0;
    end; // search not '<>'

  SetLength(IndexHeader.indexFields,0);
  FreeMem(IndexHeader.indexOrders);
  FreeMem(IndexHeader.indexCaseIns);
  FoundRecordCount := recCount;
end;//TEasyDataSet.GetMatchedRecordsArray


//------------------------------------------------------------------------------
// check is recordBuf matches operation
//------------------------------------------------------------------------------
function TEasyDataSet.IsRecordMatches(
     searchOperation: TSearchOperation; // search operation record
     curFilterOptions: TFilterOptions;
     recordBuf: PAnsiChar): boolean;
var
    IndexHeader : IndexHeaderType;
    bIgnoreCase : boolean;
    IsPrimaryKey : boolean;
    bLikeValue : boolean;
    bs:          TEasyBlobStream;
    srcBuffer:   PAnsiChar;
    Field:       TField;
    res, bFree:       Boolean;
    bufSize:          Int64;
    tPos,PhysRecNo:   Integer;
//---------------- variables for optimization -----------------------------
{$include compare_var.inc}
begin

 bFree := false;
 // case sensivity flag
 if (foCaseInsensitive in curFilterOptions) then
  bIgnoreCase := true
 else
  bIgnoreCase := false;

 // if Like or Not Like operator
 if (searchOperation.SearchOp = soLike) or
     (searchOperation.SearchOp = soNotLike) then
  begin
    bLikeValue := (searchOperation.SearchOp = soLike);
    if (IsBLOBFieldType(pFieldHeaderType(DMHandle.fieldHeaderList.Items[searchOperation.FieldNo])^.fieldType)) then
     begin
//      if (state = dsEdit) then
//       tablePosition := GetTablePositionByID(FCurrentRecordID);
      Field := FieldByName(searchOperation.FieldName);
      if (Field = nil) then
       raise ETblException.Create(00077,[FTableName,searchOperation.FieldName],Self);
      if (blobFields[searchOperation.FieldNo].stream <> nil) then
       begin
//        srcBuffer := TMemoryStream(blobFields[searchOperation.FieldNo].stream).Memory;
       end
      else
       begin
        // read blob
        bFree := true;
        blobFields[searchOperation.FieldNo].stream := TMemoryStream.Create;
        blobFields[searchOperation.FieldNo].mode := bmRead;
        // set physical record ID
        if (state = dsInsert) then
         PhysRecNo := DMHandle.tableHeader.recordCount-1
        else
         begin
          if (state = dsEdit) then
           tPos := tablePosition
          else
           begin
             Move(PAnsiChar(recordBuf + DMHandle.recordSize)^,PhysRecNo,SizeOf(PhysRecNo));
             tPos := GetTablePositionByID(PhysRecNo);
           end;
           if (tPos >= 0) and (tPos < visibleRecordCount) then
            physRecNo := visibleRecords.items[tPos]
           else
            PhysRecNo := -1;
         end;
        try
          if (PhysRecNo >= 0) then
           aaReadBLOBValue(searchOperation.FieldNo,true,PhysRecNo);
        except
        end;
//        srcBuffer := TMemoryStream(blobFields[searchOperation.FieldNo].stream).Memory;
//        bs := TEasyBlobStream.Create(TBlobField(Field) ,bmRead);
//        srcBuffer := bs.FStream.Memory;
       end; //  read blob
      bufSize := blobFields[searchOperation.FieldNo].stream.Size;
      if (bufSize <= 0) then
       srcBuffer := nil
      else
       begin
        GetMem(srcBuffer,bufSize+1);
        Move(TMemoryStream(blobFields[searchOperation.FieldNo].stream).Memory^,
             srcBuffer^,bufSize);
        // add #0 at the end of buffer
        PAnsiChar(srcBuffer+bufSize)^ := #0;
       end;
     end // blob / memo field
    else
     begin
      srcBuffer := PAnsiChar(recordBuf+DMHandle.fieldOffsets[searchOperation.FieldNo]);
     end;
    try
      if (srcBuffer = nil) then
       res := false
      else
       res := IsStrMatchPattern(srcBuffer,
                       PAnsiChar(searchOperation.ValueBuffer+DMHandle.fieldOffsets[searchOperation.FieldNo]),
                       bIgnoreCase);
       if (res) then
         result := bLikeValue
       else
         result := not bLikeValue;
    finally
      if (bFree) then
       begin
        blobFields[searchOperation.FieldNo].stream.Free;
        FreeMem(srcBuffer);
        blobFields[searchOperation.FieldNo].stream := nil;
       end;
       //bs.Free;
    end;
    exit;
  end;

   // Get index num
   if (searchOperation.FieldNo = -1) then
    isPrimaryKey := true
   else
    isPrimaryKey := false;

//  search_index := InternalGetIndexNo('@'+searchOperation.FieldName);
  IndexHeader.indexCount := 1; // use only primary index
  SetLength(IndexHeader.indexFields,1);
  if (IsPrimaryKey) then
   IndexHeader.indexFields[0] := -1
  else
   IndexHeader.indexFields[0] := searchOperation.FieldNo;
  IndexHeader.indexOrders := AllocMem(1);
  IndexHeader.indexOrders^ := chr($FF);
  IndexHeader.indexCaseIns := AllocMem(1);
  IndexHeader.indexCaseIns^ := chr($00);
  IndexHeader.indexName := '';
  IndexHeader.ignoreCase := false;
  IndexHeader.descending := false;

  cmpRecBuf_buffer1 := recordBuf;
  cmpRecBuf_buffer2 := searchOperation.valueBuffer;
  cmpRecBuf_pIndexHeader := @IndexHeader;
  cmpRecBuf_ignoreCase := bIgnoreCase;
  cmpRecBuf_bPartialCompare := searchOperation.bPartialCompare;
  cmpRecBuf_find := true;
  {$include compare.inc}
  FreeMem(IndexHeader.indexOrders);
  FreeMem(IndexHeader.indexCaseIns);
  case searchOperation.SearchOp of
   soEQ:  result := (cmpRecBuf_res = 0);
   soNEQ: result := (cmpRecBuf_res <> 0);
   soLTE: result := (cmpRecBuf_res >= 0);
   soGTE: result := (cmpRecBuf_res <= 0);
   soLT:  result := (cmpRecBuf_res > 0);
   soGT:  result := (cmpRecBuf_res < 0);
  else
   Raise Exception.Create('TEasyDataSet.IsRecordMatches - Unsupported search operation in TEasyDataSet.IsRecordMatches');
   result := false;
  end;
end; //TEasyDataSet.IsRecordMatches


//------------------------------------------------------------------------------
// locate first record satisfying search condition
//------------------------------------------------------------------------------
function TEasyDataSet.InternalLocate(
     searchConditions: array of TSearchOperation; // search conditions
     ConditionCount: integer; // count of conditions
     curFilterOptions: TFilterOptions // current search options
     ): integer; // return PhysRecNo or -1
var
  tempRecords: aInteger;
  tempRecordCount: integer;
  foundRecords: aInteger;
  foundRecordCount: integer;
  i,j, firstRecNo, cmp: integer;
  minCount: integer;
  startConditionNo: integer;
  physRecNo: integer;
  bFound: boolean;
  isRecVis: boolean;
  bitmap: TBitsArray;

function NoIndexLocate: integer;
var
  bMatches: Boolean;
begin
 Result := -1;
 // loop for all visible records
 i := 0;
 while (i < VisibleRecordCount) do
  begin
    bMatches := IsRecordMatches(searchConditions[0], curFilterOptions,
       DMHandle.allRecBuffer.GetRecordDataPtr(visibleRecords.Items[i]));
    if (bMatches) then
     begin
         Result := VisibleRecords.Items[i];
         break;
     end;
    inc(i);
  end;
end;

begin
 DBSession.LockSession;
 try
   CheckTableState;
   // if there are no records - exit
   if (visibleRecordCount <= 0) then
    begin
     result := -1;
     exit;
    end;
   // determine condition from which we will start checking
   minCount := DMHandle.tableHeader.recordCount;
   startConditionNo := 0;

   // special case: no auto-indexes and 1 condition:
   if (ConditionCount = 1) then
   // no index?
    if (GetIndexNoByFields(SearchConditions[0].FieldName, '', not (foCaseInsensitive in curFilterOptions)) = -1) then
     begin
      Result := NoIndexLocate;
      exit;
     end;

   // if several conditions - get minimal result set
   if (ConditionCount > 1) then
     for i:=0 to ConditionCount-1 do
      begin
         // get count of found records for this condition
         GetMatchedRecordsArray(SearchConditions[i],curFilterOptions,
               aagmrReturnCountOnly,foundRecords,foundRecordCount);
         // if found records count is not more than 5% of all records
         // then select this condition as start condition
         if (foundRecordCount <= (DMHandle.tableHeader.recordCount div 20)) then
          begin
           startConditionNo := i;
           break;
          end
         else
          if (foundRecordCount < minCount) then
           begin
            minCount := foundRecordCount;
            startConditionNo := i;
           end;
      end;
   // we've got StartConditionNo
   // now get found records for this condition
   GetMatchedRecordsArray(SearchConditions[startConditionNo],curFilterOptions,
               aagmrReturnArray,tempRecords,tempRecordCount);
   // check other conditions for all these found records
   // and transfer matching and visible records to foundRecords
   foundRecordCount := 0;
   SetLength(foundRecords, tempRecordCount);
   for i:=0 to tempRecordCount-1 do
      begin
        physRecNo := tempRecords[i];
        bFound := true;
        for j:=0 to ConditionCount-1 do
         if (j <> startConditionNo) then
          begin
           DMHandle.allRecBuffer.LockRecordPage(physRecNo);
           bFound := IsRecordMatches(searchConditions[j],curFilterOptions,
                        DMHandle.allRecBuffer.GetRecordDataPtr(physRecNo));
           DMHandle.allRecBuffer.UnlockRecordPage(physRecNo);
           if not bFound then
             break;
          end;
        if (bFound) then
         begin
          DMHandle.allRecBuffer.LockRecordPage(physRecNo);
          isRecVis := IsRecordVisible(DMHandle.allRecBuffer.GetRecordDataPtr(physRecNo));
          DMHandle.allRecBuffer.UnlockRecordPage(physRecNo);
          if (isRecVis) then
           begin
             foundRecords[foundRecordCount] := physRecNo;
             inc(foundRecordCount);
           end;
         end;
      end;

     // now get first record in current index
     if (foundRecordCount > 0) then
      begin
       // sort found records algorithm?
       if (foundRecordCount < 10) then
        begin
         firstRecNo := foundRecords[0];
         for i := 1 to foundRecordCount-1 do
          begin
           physRecNo := foundRecords[i];
           DMHandle.allRecBuffer.LockRecordPage(firstRecNo);
           DMHandle.allRecBuffer.LockRecordPage(physRecNo);
           cmp := CompareRecordBuffersWithIndex(
                    DMHandle.allRecBuffer.GetRecordDataPtr(firstRecNo),
                    DMHandle.allRecBuffer.GetRecordDataPtr(physRecNo),
                    currentIndex,
                    pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.indexCount);
           DMHandle.allRecBuffer.UnlockRecordPage(physRecNo);
           DMHandle.allRecBuffer.UnlockRecordPage(firstRecNo);
           if (cmp > 0) then
            firstRecNo := physRecNo;
          end;
         result := firstRecNo;
        end
       else
        begin
         //--- bitmap algorithm ---
         firstRecNo := -1;
         bitmap := TBitsArray.Create(DMHandle.tableHeader.RecordCount);
         // set bits for found records
         for i := 0 to foundRecordCount-1 do
          bitmap.SetBit(foundRecords[i],true);
         // find first matching visible record
         for i := 0 to VisibleRecordCount-1 do
          if (bitmap.GetBit(visibleRecords.Items[i])) then
           begin
            firstRecNo := visibleRecords.Items[i];
            break;
           end;
         bitmap.Free;
         result := firstRecNo;
        end;
      end
     else
      result := -1;

    FoundRecords := nil;
 finally
  DBSession.UnlockSession;
 end;
end;//TEasyDataSet.InternalLocate


//------------------------------------------------------------------------------
// prepare search array, call InternalLocate, free internal variables
//------------------------------------------------------------------------------
function TEasyDataset.PrepareAndLocate(const KeyFields: AnsiString; const KeyValues: Variant;
 so: TSearchOperator; fo: TFilterOptions): integer;
var fieldCount,i : integer;
    fieldList : TStringList;
    v : variant;
    opArr: array of TSearchOperation;
    opCount: integer;
begin
  // get fields list
  Result := -1;
  fieldList := TStringList.Create;
  fieldCount := GetStringParams(KeyFields, fieldList);
  try
//    CheckVarArrayBounds(fieldCount, KeyValues);
  SetLength(opArr, fieldCount);
  opCount := fieldCount;
  for i:=0 to fieldCount-1 do
  begin
    opArr[i].FieldName := fieldList[i];
    opArr[i].FieldNo := DMHandle.InternalGetFieldNo(opArr[i].FieldName);
      opArr[i].SearchOp := so;
      if not (foNoPartialCompare in fo) then
     opArr[i].bPartialCompare := true
    else
     opArr[i].bPartialCompare := false;
   // is variant array?
   if (VarIsArray(KeyValues)) then
    v := KeyValues[i]
   else
    v := KeyValues;
   // get type of variant
   case (VarType(v) and varTypeMask) of
    varInteger, varSmallInt, varByte, $0012{varWord}:
      PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                         IntToStr(integer(v)),opArr[i].ValueBuffer);
    $0014{LargeInt}, $0010{varShortInt}:
      PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                         AnsiString(v),opArr[i].ValueBuffer);
    varString:
       PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                          AnsiString(v),opArr[i].ValueBuffer);
    varOleStr{$IFDEF D12H},varUString{$ENDIF}:
       PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                          WideString(v),opArr[i].ValueBuffer);
    varSingle, varDouble, varCurrency:
      PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                         FloatToStr(double(v)),opArr[i].ValueBuffer);
    varDate:
      PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                         DateTimeToStr(TDateTime(v)),opArr[i].ValueBuffer);
    varBoolean:
       if (Boolean(v)) then
         PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                            'true',opArr[i].ValueBuffer)
       else
         PrepareValueBuffer(opArr[i].FieldNo,opArr[i].SearchOp,
                            'false',opArr[i].ValueBuffer);
    varNull:
       result := -1;
    else
     Raise Exception.Create('TEasyDataset.PrepareAndLocate - Unsupported variant type '+IntToStr(VarType(v)));
   end;
  end;

   if ((VarType(v) and varTypeMask) <> varNull) then
    Result := InternalLocate(opArr, opCount, fo);

    for i := 0 to fieldCount - 1 do
      FreeRecordBuffer(TRecordBuffer(opArr[i].ValueBuffer));
    opArr := nil; //free memory from dynamic array
  finally
    fieldList.Free;
  end;
end; //TEasyDataset.PrepareAndLocate


//------------------------------------------------------------------------------
// Convert strValue and put it into valueBuffer
// and may be convert operation
//------------------------------------------------------------------------------
procedure TEasyDataSet.PrepareValueBuffer(
                FieldNo:integer; // No of field
                var SearchOp:TSearchOperator; // =,<,...
                value:WideString; // WideString with value
                var valueBuffer:PAnsiChar); // buffer with converted value
var offset : integer;
    i, size : integer;
    isPrimaryKey : boolean;
    v_int      : Integer;
    v_date     : TDateTime;
    v_float    : Double;
    v_curr     : Double;
    v_small    : SmallInt;
    v_word     : Word;
    v_largeInt : int64;
    v_bool     : WordBool;
    //---------------- variables for optimization -----------------------------
    pBuffer: PAnsiChar;
begin
 if (FieldNo > -1) then
  isPrimaryKey := false
 else
  isPrimaryKey := true;

 // count offset for field (fieldName) from the beginning of record buffer
 if (not isPrimaryKey) then
  begin
   offset := DMHandle.fieldOffsets[FieldNo];
   size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize;
  end
 else
  begin
   offset := DMHandle.recordSize;
   size := 0;
  end;
 // prepare value
 if (valueBuffer = nil) then
  valueBuffer := PAnsiChar(AllocRecordBuffer);
 if (valueBuffer = nil) then raise Exception.Create(
      	'Error in TEasyDataSet.PrepareValueBuffer - valueBuffer 0 pointer!');
 if (isPrimaryKey and (value <> '')) then
  begin
   // primary key
   i := StrToInt(value);
   InternalInitRecord(TRecordBuffer(valueBuffer));
   pRecordInfoType(valueBuffer+DMHandle.recordSize)^.id := i;
  end
 else
 if (value <> '') then
  begin
   pRecordInfoType(valueBuffer+DMHandle.recordSize)^.id := 0;
   if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType
      <>ftString) and
      (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType
      <>ftMemo) and
      (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType
      <>ftFmtMemo) and
      (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType
      <>ftWideString) and
      ((SearchOp = soLike) or (SearchOp = soNotLike))
      then raise Exception.Create(
      'Error in TEasyDataSet.PrepareValueBuffer - ''like / not like'' operation call with not AnsiString field!');
   InternalInitRecord(TRecordBuffer(valueBuffer));
  end;
 // null values search
 if (SearchOp = soIsNull) or
    ((SearchOp = soEQ) and (value = '')) then
  begin
   SearchOp := soEQ;
   pBuffer := pAnsiChar(valueBuffer+DMHandle.recNullOffset);
   FillChar(pBuffer^,DMHandle.fieldFlagsSize,$FF);
  end
 else
  if (SearchOp = soIsNotNull)  or
    ((SearchOp = soNEQ) and (value = '')) then
   begin
    SearchOp := soNEQ;
    pBuffer := pAnsiChar(valueBuffer+DMHandle.recNullOffset);
    FillChar(pBuffer^,DMHandle.fieldFlagsSize,$FF);
   end
 else
  begin
   // not null
   pBuffer := pAnsiChar(valueBuffer+DMHandle.recNullOffset);
   FillChar(pBuffer^,DMHandle.fieldFlagsSize,$00);
  end;

 if ((value <> '') and (FieldNo >= 0) and (not isPrimaryKey)) then
  begin
   case (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.FieldType) of
    ftSmallInt :
     begin
  	  v_small := SmallInt(StrToInt(value));
  	  Move(v_small,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftInteger :
     begin
  	  v_int := StrToInt(value);
  	  Move(v_int,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftLargeInt :
     begin
          v_largeInt := StrToInt64(value);
  	  Move(v_largeInt,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftWord :
     begin
          v_word := StrToInt(value);
  	  Move(v_word,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftFloat :
     begin
          v_float := StrToFloat(value);
  	  Move(v_float,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftCurrency:
     begin
   	  v_curr := StrToFloat(value);
  	  Move(v_curr,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftString,ftMemo,ftFmtMemo:
     begin
      size := Length(value);
      // truncate by field size?
      if ((pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType <> ftMemo) and
          (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType <> ftFmtMemo)) then
       if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize-1 < size) then
        size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize-1;
  	  Move(PAnsiChar(value)^,PAnsiChar(valueBuffer+offset)^,size+1);
     end;
    ftWideString :
     begin
      size := Length(value)*2;
      // truncate by field size?
      if (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize-2 < size) then
       size := pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldSize-2;
      StringToWideChar(value,PWideChar(valueBuffer+offset),size+2);
     end;
    ftDateTime,ftDate,ftTime :
     begin
      v_date := StrToDateTime(value);
      TDateTimeRec(v_date) := DateTimeToNative(Fields[FieldNo].DataType, v_date);
      Move(v_date,PAnsiChar(valueBuffer+offset)^,size);
     end;
    ftBoolean:
     begin
          if (StrIComp(PAnsiChar(value),PAnsiChar('true'))=0) then
    	   Word(v_bool) := 1
          else
    	   Word(v_bool) := 0;
  	  Move(v_bool,PAnsiChar(valueBuffer+offset)^,size);
     end;
    else raise Exception.Create(
     'Error in TEasyDataSet.PrepareValueBuffer - unsupported field type!' );
   end; // case
  end; // if value is not null

end; //TEasyDataSet.PrepareValueBuffer


//------------------------------------------------------------------------------
// returns true, if field type is supported
//------------------------------------------------------------------------------
function TEasyDataSet.IsFieldTypeSupported(
             fType : TFieldType // field type
             ) : Boolean;
var i : integer;
begin
 result := false;
 for i := 1 to MAX_SUPPORTED_FIELD_TYPES do
  if (SUPPORTED_FIELD_TYPES[i].fieldType = fType) then
   begin
    result := true;
    break;
   end;
end; //  TEasyDataSet.IsFieldTypeSupported


//------------------------------------------------------------------------------
// Check number of parameters in key fields and key values
//------------------------------------------------------------------------------
{
procedure TEasyDataset.CheckVarArrayBounds(fk: integer; V: Variant);
var
  bOK: boolean;
begin
  bOK := true;
  if (VarIsArray(V)) then
   if (fk <> VarArrayHighBound(V,1)-VarArrayLowBound(V,1)+1) then
    bOK := false;
  if ((not VarIsArray(V)) and (fk <> 1)) then
    bOK := false;
  if (not bOK) then
    raise Exception.Create('TEasyDataset.CheckVarArrayBounds - Different '+
     'quantity of items in KeyFields and KeyValues params.');
end; //TEasyDataset.CheckVarArrayBounds
}

//------------------------------------------------------------------------------
// creates list of supported operators
//------------------------------------------------------------------------------
procedure TEasyDataSet.GetSupportedFieldTypes(
             typeList : TaaList
             );
var
 p_type   : pTETFieldType;
 i : integer;
begin
 typeList.Clear;
 for i := 1 to MAX_SUPPORTED_FIELD_TYPES do
  begin
   new(p_type);
   if (p_type = nil) then raise
    Exception.Create('Error in TEasyDataSet.GetSupportedFieldTypes - 0 pointer to p_type!');
    {
   p_type.fieldType := SUPPORTED_FIELD_TYPES[i].fieldType;
   p_type.name := SUPPORTED_FIELD_TYPES[i].name;
   }
   p_type^ := SUPPORTED_FIELD_TYPES[i];
   typeList.Add(p_type);
  end;
end; //GetSupportedFieldTypes


//------------------------------------------------------------------------------
// returns table file extesion
//------------------------------------------------------------------------------
function TEasyDataSet.GetTableFileExtension : AnsiString;
begin
 result := tableFileExtension;
end; //GetTableFileExtension


//------------------------------------------------------------------------------
// Like '%_' compare for ANSI string
//------------------------------------------------------------------------------
function TEasyDataSet.IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean): Boolean;
begin
  Result := ETblStrFunc.IsStrMatchPattern(StrPtr, PatternPtr, bIgnoreCase);
end;//TEasyDataSet.IsStrMatchPattern


//------------------------------------------------------------------------------
// Like '%_' compare for WideString
//------------------------------------------------------------------------------
function TEasyDataSet.IsWideStrMatchPattern(StrPtr: PWideChar; PatternPtr: PWideChar; bIgnoreCase:boolean): Boolean;
begin
  Result := ETblStrFunc.IsWideStrMatchPattern(StrPtr, PatternPtr, bIgnoreCase);
end;//TEasyDataSet.IsWideStrMatchPattern


//------------------------------------------------------------------------------
// fills visibleRecords with record numbers
//------------------------------------------------------------------------------
procedure TEasyDataSet.CreateVisibleRecordsList;
var i,j,k,pos, iStart, iEnd, numrec, res: integer;
    resultBitsArray : TBitsArray;
    bMasterDetail : boolean;
    bParsersUsed : boolean;

  function GetNextVisibleRecordNo(RecordNo: Integer): Integer;
  var i,PhysRecNo: Integer;
  begin
   Result := -1;
   for i := RecordNo+1 to DMHandle.tableHeader.recordCount-1 do
    begin
      PhysRecNo := DMHandle.indexes[FDistinctIndexNo].Items[i];
      if (resultBitsArray.GetBit(PhysRecNo)) then
       begin
        Result := i;
        break;
       end;
    end;
  end; // GetNextVisibleRecordNo

  procedure MakeDistinct;
    {$I compare_var.inc}
    curRecord,priorRecord: Integer;
    physRecNo:            Integer;
    physRecNo2:           Integer;

  begin
   cmpRecBuf_find := true;
   cmpRecBuf_ignoreCase := false;
   cmpRecBuf_bPartialCompare := false;
   cmpRecBuf_pIndexHeader := pIndexHeaderType(DMHandle.indexHeaderList.Items[FDistinctIndexNo]);

   priorRecord := GetNextVisibleRecordNo(-1);
   if (priorRecord >= 0) then
    begin
     repeat
      curRecord := GetNextVisibleRecordNo(priorRecord);
      if (curRecord >= 0) then
       begin
        physRecNo := DMHandle.indexes[FDistinctIndexNo].Items[priorRecord];
        physRecNo2 := DMHandle.indexes[FDistinctIndexNo].Items[curRecord];
        DMHandle.allRecBuffer.LockRecordPage(physRecNo);
        DMHandle.allRecBuffer.LockRecordPage(physRecNo2);
        try
         cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
            physRecNo));
         cmpRecBuf_buffer2 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
            physRecNo2));
         {$include compare.inc}
         if (cmpRecBuf_res = 0) then
          resultBitsArray.SetBit(physRecNo2,false);
        finally
         DMHandle.allRecBuffer.UnlockRecordPage(physRecNo);
         DMHandle.allRecBuffer.UnlockRecordPage(physRecNo2);
        end;
        priorRecord := curRecord;
       end;
     until (curRecord < 0);
    end; // scan all visible records
  end; // MakeDistinct

  procedure ApplySQLFilter;
  var
    curRecord: Integer;
    physRecNo: Integer;
    value: TETblDataValue;
  begin
    FDirectAccessForGetFieldValue := true;
    try
    for curRecord := 0 to DMHandle.tableHeader.recordCount-1 do
     begin
      physRecNo := DMHandle.indexes[currentIndex].Items[curRecord];
      tablePhysRecNo := physRecNo;
//      if (resultBitsArray.GetBit(physRecNo))
//aaStartTime;
      value := TETblExpression(FSQLFilterExpr).GetDataValue(Self);
//aaStopTime;
      if (value.DataType <> ftBoolean) then
       raise ETblException.Create(00054, [Integer(value.DataType)], nil);
      if (value.IsNull or not pBoolean(value.pData)^) then
       resultBitsArray.SetBit(physRecNo, False);
     end;
    finally
      FDirectAccessForGetFieldValue := false;
    end;
  end;


begin
   if (not isTableOpened) or (VisibleRecordsFreezed) then
    Exit;
   pos := -1;
   if (visibleRecordCount > 0) then
    if ((tablePosition >= 0) and (tablePosition < visibleRecordCount)) then
      pos := visibleRecords.items[tablePosition];
   visibleRecords.SetSize(0);
  // posVisibleRecords := nil;
   visibleRecordCount := 0;
   visRecUpdated := true;

   // bug fix: FilterParser.PreParse was not called on empty table
  // if (DMHandle.tableHeader.RecordCount = 0) then
  //  exit;

   // master/detail
   bMasterDetail := false;
   if (IsMasterDetail) then
   // bug fix: to enable m/d with complex indexes
//    if (AnsiLowerCase(pIndexHeaderType(DMHandle.indexHeaderList.Items[currentIndex])^.IndexName) =
//        AnsiLowerCase(FIndexName)) then
     begin
      ChangeMasterCondition(FMasterLink.Fields);
      bMasterDetail := true;
      MasterDetailParser.Parse;
     end;

   // Filter
   if (IsFiltered) then
    begin
     // needs preparsing?
     if (Filter <> FilterParser.ParsedStr) then
      FilterParser.PreParse(Filter);
     FilterParser.Parse;
    end;

   // get results bits array
   bParsersUsed := true;
   if (bMasterDetail and IsFiltered) then
    begin
     resultBitsArray := MasterDetailParser.bitsArr[0];
     resultBitsArray.AndBits(FilterParser.bitsArr[0]);
    end
   else
    if (bMasterDetail) then
     resultBitsArray := MasterDetailParser.bitsArr[0]
    else
     if (IsFiltered) then
      resultBitsArray := FilterParser.bitsArr[0]
     else
      begin
       bParsersUsed := false; // no parsers - all records visible
       resultBitsArray := TBitsArray.Create(DMHandle.tableHeader.RecordCount);
       resultBitsArray.SetBits(true);
      end;

  // SetLength(visibleRecords,DMHandle.tableHeader.RecordCount);
   visibleRecords.SetSize(DMHandle.tableHeader.RecordCount);
  // SetLength(posVisibleRecords,DMHandle.tableHeader.RecordCount);

     // index
       j := 0;
       BuildIndex(currentIndex);

       iStart := 0;
       iEnd := DMHandle.tableHeader.RecordCount-1;
       if IsRanged then begin
        // key exclusive?
        if FKeyBuffers[kiRangeStart].Exclusive then
         begin
          iStart := FindInIndex(
                      PAnsiChar(FKeyBuffers[kiRangeStart])+ SizeOf(TKeyBuffer),
                      currentIndex, FKeyBuffers[kiRangeStart]^.FieldCount,
                      true, false);
          if (iStart >=0) then
           begin
             res := CompareInIndex(PAnsiChar(FKeyBuffers[kiRangeStart])+ SizeOf(TKeyBuffer),
                                   currentIndex, iStart,
                                   FKeyBuffers[kiRangeStart]^.FieldCount);
            if (res >= 0) then
             Inc(iStart);
           end;
         end
        else
         begin
          iStart :=  FindInIndex(
                      PAnsiChar(FKeyBuffers[kiRangeStart])+ SizeOf(TKeyBuffer),
                      currentIndex, FKeyBuffers[kiRangeStart]^.FieldCount,
                      false, false);
          if (iStart >= 0) then
           begin
            res := CompareInIndex(PAnsiChar(FKeyBuffers[kiRangeStart])+ SizeOf(TKeyBuffer),
                                 currentIndex, iStart,
                                 FKeyBuffers[kiRangeStart]^.FieldCount);
            if (res > 0) then
             Inc(iStart);
           end;
         end;
        // key exclusive?
        if FKeyBuffers[kiRangeEnd].Exclusive then
         begin
          iEnd :=  FindInIndex(
                     PAnsiChar(FKeyBuffers[kiRangeEnd])+ SizeOf(TKeyBuffer),
                     currentIndex, FKeyBuffers[kiRangeEnd]^.FieldCount,
                     true, false);
          if (iEnd >= 0) then
           begin
            res := CompareInIndex(PAnsiChar(FKeyBuffers[kiRangeEnd])+ SizeOf(TKeyBuffer),
                                  currentIndex, iEnd,
                                  FKeyBuffers[kiRangeEnd]^.FieldCount);
            if (res <= 0) then
              Dec(iEnd);
           end;
         end
        else
         begin
          iEnd :=  FindInIndex(
                     PAnsiChar(FKeyBuffers[kiRangeEnd])+ SizeOf(TKeyBuffer),
                     currentIndex, FKeyBuffers[kiRangeEnd]^.FieldCount,
                     true, false);
          if (iEnd >= 0) then
           begin
            res := CompareInIndex(PAnsiChar(FKeyBuffers[kiRangeEnd])+ SizeOf(TKeyBuffer),
                                  currentIndex, iEnd,
                                  FKeyBuffers[kiRangeEnd]^.FieldCount);
            if (res < 0) then
              Dec(iEnd);
           end;
         end;
       end;

    // SQL filter expr
    if (FSQLFilterExpr <> nil) then
     ApplySQLFilter;

    // distinct
    if (FDistinctFields <> '') then
     begin
      FDistinctIndexNo := aaFindIndexByFields(self,FDistinctFields,'','');
      if (FDistinctIndexNo < 0) then
       begin
        CreateTemporaryIndex(FDistinctFields,'','');
        CreateIndexDefinitions;
        FDistinctIndexNo := aaFindIndexByFields(self,FDistinctFields,'','');
       end;
      if (FDistinctIndexNo < 0) then
       raise ETblException.Create(00032,[FTableName,FDistinctFields],self);
      // making distinct visible records list
      MakeDistinct;
     end;

  k := 0;
   for i:=0 to DMHandle.tableHeader.RecordCount-1 do
    begin
      numrec := DMHandle.indexes[currentIndex].items[i];
      if (i < iStart) or (i > iEnd) then
        resultBitsArray.SetBit(numrec, false);
      if (resultBitsArray.GetBit(numrec)) then
      begin
        inc(k);
        // TOP first_row,n ?
        if (FSQLFirstRowNo > -1) then
         if (k < FSQLFirstRowNo) then
          continue;
        // TOP n?
        if (FSQLTopRowCount > -1) then
         if (j >= FSQLTopRowCount) then
          break;
        visibleRecords.items[j] := numrec;
        inc(j);
      end;
    end;

   visibleRecordCount := j;
   // shorten array
   visibleRecords.SetSize(visibleRecordCount);
   tablePosition := -1;
   if ((pos >= 0) and (pos < DMHandle.tableHeader.RecordCount)) then
    if (resultBitsArray.GetBit(pos)) then
     begin
  //    pos := posvisibleRecords.items[pos];
      tablePosition := GetTablePositionByPhysRecNo(pos);
  //    tablePosition := FindIndexValueForDelete(visibleRecords.items,pos,
  //            visibleRecordCount);
  // findindexvaluefordelete will be here ___!!!
  //    tablePosition := pos;
     end;

   if (not bParsersUsed) then
    resultBitsArray.Free;

   TableState := DMHandle.tableHeader.state;
end; //CreateVisibleRecordsList;


//------------------------------------------------------------------------------
// assigns visibleRecords with record numbers
//------------------------------------------------------------------------------
procedure TEasyDataSet.AssignVisibleRecordsList(visRecords: TaaIntArray);
begin
 visibleRecordCount := visRecords.ItemCount;
 visibleRecords.Assign(visRecords);
end;// AssignVisibleRecordsList


//------------------------------------------------------------------------------
// sets filtered
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetFiltered(f : boolean);
begin
 DBSession.LockSession;
 try
   inherited SetFiltered(f);
   if (not Active) then
    exit;
   if (f) then
    begin
     FilterParser.FilterOptions := FilterOptions;
     FilterParser.PreParse(Filter);
    end;
   CreateVisibleRecordsList;

   First;
  {
   if (Active) then
    begin
     First;
     SetActiveBuffer;
     Refresh;
    end;
   }
   //SetTempState(dsFilter);
 finally
   DBSession.UnlockSession;
 end;
end; //TEasyDataSet.SetFiltered(f : boolean);


//------------------------------------------------------------------------------
// get active buffer
//------------------------------------------------------------------------------
function TEasyDataSet.GetActiveRecordBuffer : PAnsiChar;
begin
 if (FDirectInsert) or (FDirectFilter) then
  Result := PAnsiChar(FTemporaryRecordBuffer)
 else
 case State of
      dsBrowse: if IsEmpty then Result := nil else Result := PAnsiChar(ActiveBuffer);
      dsCalcFields: Result := PAnsiChar(CalcBuffer);
      dsFilter: Result :=   PAnsiChar(FFilterBuffer);
      dsEdit,dsInsert: Result:=PAnsiChar(ActiveBuffer);
      dsSetKey:        Result := PAnsiChar(FKeyBuffer) + SizeOf(TKeyBuffer);
        else Result:=nil;
 end;
end; //TEasyDataSet.GetActiveRecordBuffer : PAnsiChar;


//------------------------------------------------------------------------------
// find index
//------------------------------------------------------------------------------
function TEasyDataSet.GetIndexNoByFields(const Fields: AnsiString;
                                         DescFields: string='*';
                                         CaseSensitive: Boolean=True): integer;
var i,j,n,m,l,FieldNo: integer;
    f, bIndexWithStringField: boolean;
    list1, list2: TStringList;
begin
 Result := -1;
 if (not isTableOpened) then
  Exit;

 if (Fields = '') then
  Exit;

 f := false;
 list1 := TStringList.Create;
 list2 := TStringList.Create;
 try
  l := 0;
  // searching index by specified fields
  for i := 0 to IndexDefs.Count-1 do
   begin
    list1.Clear;
    list2.Clear;
    n := GetStringParams(IndexDefs.Items[i].Fields, list1);
    m := GetStringParams(Fields, list2);

    // if no fields - exit
    if (m = 0) then break;
    // if fields number in Value more then fields number in this index - next index
    if (m > n) then continue;

    // desc fields and CaseSensivity have sense for AnsiString fields only
    bIndexWithStringField := True;
    for j := 0 to m-1 do
     begin
      FieldNo := DMHandle.InternalGetFieldNo(list1.Strings[j]);
      // auto-inc?
      if (FieldNo = -1) then
       begin
         bIndexWithStringField := False;
         break;
       end;
      // not auto-inc; string?
      if ((pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType
          <> ftString) and
          (pFieldHeaderType(DMHandle.fieldHeaderList.Items[FieldNo])^.fieldType
          <> ftWideString)) then
       begin
         bIndexWithStringField := False;
         break;
       end;
     end;

    f := true;
    for j := 0 to m-1 do
     if (LowerCase(list2.Strings[j]) <> LowerCase(list1.Strings[j])) then
      begin
       f := false;
       break;
      end;
    if (f) then
      if ((not bIndexWithStringField) or
          (CaseSensitive = not(ixCaseInsensitive in IndexDefs.Items[i].Options))) and
         ((DescFields = '*') or (DescFields = IndexDefs.Items[i].DescFields)) then
       begin
        // index found
        l := i;
        break;
       end
      else
       f := false; // index doesn't match by options or desc fields
   end; // for i
 finally
  list1.Free;
  list2.Free;
 end;

 if (f) then
  Result := l
 else
  Result := -1;
end;// GetIndexNoByFields


//------------------------------------------------------------------------------
// sets index defs
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetIndexDefs(Value: TIndexDefs);
begin
  IndexDefs.Assign(Value);
end; //TEasyDataSet.SetIndexDefs(Value: TFieldDefs);


//------------------------------------------------------------------------------
// sets exclusive
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetExclusive(Value: Boolean);
begin
  CheckInactive;
  FExclusive := Value;
end;//TEasyDataSet.SetExclusive(Value: Boolean);


{ Master / Detail }

function TEasyDataSet.GetMasterFields: AnsiString;
begin
  Result := FMasterLink.FieldNames;
end;

procedure TEasyDataSet.SetMasterFields(const Value: AnsiString);
begin
  FMasterLink.FieldNames := Value;
end;


procedure TEasyDataSet.CheckMasterRange;
begin
 DBSession.LockSession;
 try
  if FMasterLink.Active and (FMasterLink.Fields.Count > 0) then
  begin
   if (Active) then
    DoBeforeScroll;
   FMasterLink.DataSet.Refresh;
   ChangeMasterCondition(FMasterLink.Fields);
   CreateVisibleRecordsList;
   if (Active) then
    begin
     SetActiveBuffer;
     Refresh;
     DoAfterScroll;
    end;
  end;
 finally
   DBSession.UnlockSession;
 end;
end;

procedure TEasyDataSet.MasterChanged(Sender: TObject);
begin
 DBSession.LockSession;
 try
   if (Active) then
    DoBeforeScroll;
   ChangeMasterCondition(FMasterLink.Fields);
   if (isTableOpened) then
    begin
    // no need to call it twice (Refresh calls it too)
//     CreateVisibleRecordsList;
     if (Active) then
      begin
       SetActiveBuffer;
       Refresh;
       DoAfterScroll;
      end;
    end;
 finally
   DBSession.UnlockSession;
 end;
end;

procedure TEasyDataSet.MasterDisabled(Sender: TObject);
begin
 DBSession.LockSession;
 try
   if (isTableOpened) then
    begin
     CreateVisibleRecordsList;
     if (Active) then
      begin
       SetActiveBuffer;
       Refresh;
      end;
    end;
 finally
   DBSession.UnlockSession;
 end;
end;


procedure TEasyDataSet.ChangeMasterCondition(MasterFields: TList);
var i : integer;
    s,s1 : AnsiString;
    Fld : TField;
    a : Boolean;
begin
 DBSession.LockSession;
 try
   a := isTableOpened;
   if (not isTableOpened) then
    OpenTable;
   s := '';
   if (GetIndexFieldCount <= 0) then Exit;

    for I := 0 to MasterFields.Count - 1 do
     begin
      Fld := GetIndexField(I);

      if (Fld.DataType = ftString) or (Fld.DataType = ftWideString) or
         (Fld.DataType = ftDateTime) or (Fld.DataType = ftDate) or (Fld.DataType = ftTime)
       then
       s1 := AnsiQuotedStr(TField(MasterFields[I]).AsString,'''')
      else
       s1 := TField(MasterFields[I]).AsString;

      if TField(MasterFields[I]).IsNull or (s1 = '') or (s1 = '''''') then
       if (i > 0) then
        s := s + ' and (['+Fld.FieldName+'] IS NULL)'
       else
        s := s + '(['+Fld.FieldName+'] IS NULL )'
      else
       if (i > 0) then
        s := s + ' and (['+Fld.FieldName+'] = '+s1+')'
       else
        s := s + '(['+Fld.FieldName+'] = '+s1+')';
     end;
     MasterDetailParser.PreParse(s);

//  ShowMessage('master condition changed,  count = '+
//    inttostr(MasterFields.Count));
     if (not a) then
      CloseTable;
 finally
   DBSession.UnlockSession;
 end;
end; //ChangeMasterCondition


//------------------------------------------------------------------------------
// fielddefs support
//------------------------------------------------------------------------------
function TEasyDataSet.FieldDefsStored: Boolean;
begin
  Result := StoreDefs and (FieldDefs.Count > 0);
end; //FieldDefsStored: Boolean;


//------------------------------------------------------------------------------
// indexdefs support
//------------------------------------------------------------------------------
function TEasyDataSet.IndexDefsStored: Boolean;
begin
  Result := StoreDefs and (IndexDefs.Count > 0);
end; //TEasyDataSet.IndexDefsStored: Boolean;

function TEasyDataSet.GetDataSource: TDataSource;
begin
  Result := FMasterLink.DataSource;
end;

procedure TEasyDataSet.SetDataSource(Value: TDataSource);
begin
  if IsLinkedTo(Value) then
   raise Exception.Create('TEasyDataSet.SetDataSource - Invalid DataSource');
  FMasterLink.DataSource := Value;
end;


//------------------------------------------------------------------------------
// in memory mode
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetInMemory(Value: Boolean);
begin
 DBSession.LockSession;
 try
   if isTableOpened then
    begin
      if (FInMemory) and (not Value) then
        InternalSaveTable;
      Active := false;
      if (FInMemory) and (not Value) then
       InternalDeleteTable;
      FInMemory := Value;
      if (value) then
        FTemporary := false;
      Active := true;
    end
   else
    begin
     FInMemory := Value;
     if (value) then
      FTemporary := false;
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //SetInMemory


//------------------------------------------------------------------------------
// temporary mode
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetTemporary(Value: Boolean);
begin
 DBSession.LockSession;
 try
   if isTableOpened then
    begin
     CloseTable;
     FTemporary := Value;
     if (value) then
      FInMemory := false;
     OpenTable;
    end
   else
    begin
     FTemporary := Value;
     if (value) then
      FInMemory := false;
    end;
 finally
   DBSession.UnlockSession;
 end;
end; //SetTemporary


//------------------------------------------------------------------------------
// last autoinc value
//------------------------------------------------------------------------------
function TEasyDataSet.GetLastAutoIncValue : LongWord;
begin
 if (isTableOpened) and (DMHandle <> nil) then
  Result := LongWord(DMHandle.tableHeader.sequenceValue)
 else
  Result := 0;
end; //GetLastAutoIncValue


//------------------------------------------------------------------------------
// get blob compression
//------------------------------------------------------------------------------
function TEasyDataSet.GetBLOBCompression: TCompressionLevel;
begin
 if (isTableOpened) and (DMHandle <> nil) then
  Result := DMHandle.FBLOBCompression
 else
  Result := FBLOBCompression;
end; //GetBLOBCompression


//------------------------------------------------------------------------------
// set blob compression
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetBLOBCompression(value: TCompressionLevel);
begin
 if (not IsTableOpened) then
  FBLOBCompression := value;
end; //setBLOBCompression


//------------------------------------------------------------------------------
// get blob compression
//------------------------------------------------------------------------------
function TEasyDataSet.GetBLOBBlockSize: Integer;
begin
 if (isTableOpened) and (DMHandle <> nil) then
  Result := DMHandle.FBLOBBlockSize
 else
  Result := FBLOBBlockSize;
end; //GetBLOBBlockSize


//------------------------------------------------------------------------------
// set blob block size
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetBLOBBlockSize(value: Integer);
begin
 if (not IsTableOpened) then
  FBLOBBlockSize := value;
end; //setBLOBBlockSize


//------------------------------------------------------------------------------
// set read only
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetReadOnly(Value : Boolean);
begin
 if (isTableOpened) then
  Active := false;
 FReadOnly := Value;
end; //SetReadOnly


{$IFNDEF ENCRYPTION_ON}
//------------------------------------------------------------------------------
// set password
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetPassword(Value: AnsiString);
begin
  FPassword := '';
end; // SetPassword
{$ENDIF}


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TEasyDataSet.DoOnProgress(Progress : Real);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress,FProgressProcess);
end;


//------------------------------------------------------------------------------
// on build indexes progress
//------------------------------------------------------------------------------
procedure TEasyDataset.DoOnBuildIndexesProgress(Progress : Real; bStart, bFinish: Boolean);
begin
  if Assigned(FBuildIndexesProgress) then
    FBuildIndexesProgress(Self,Progress,bStart,bFinish)
  else
  if (not SilentMode) then
   begin
    Application.ProcessMessages;
    if (bStart) then
    begin
     DisableControls;
     FormBuildIndex := TFormBuildIndex.Create(Application);
     FormBuildIndex.lbTable.Caption := TableName;
     FormBuildIndex.Indicator.Progress := Round(Progress);
     FormBuildIndex.Show;
    end
    else
    if (bFinish) then
    begin
     if (FormbuildIndex <> nil) then
      begin
       FormBuildIndex.Indicator.Progress := Round(Progress);
       FormbuildIndex.Free;
       FormbuildIndex := nil;
      end;
     EnableControls;
    end
   else
    FormBuildIndex.Indicator.Progress := Round(Progress);
   end;
end;


//------------------------------------------------------------------------------
// sets autoinc value
//------------------------------------------------------------------------------
procedure TEasyDataSet.SetAutoIncValue(value : integer);
begin
 DBSession.LockSession;
 try
   DMHandle.tableHeader.sequenceValue := value - 1;
   inc(DMHandle.tableHeader.state);
 finally
   DBSession.UnlockSession;
 end;
end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyTable
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TEasyTable.CreateTable;
begin
 InternalCreateTable;
end; // TEasyTable.CreateTable

//------------------------------------------------------------------------------
// Overloaded CreateTable function which
// takes table name as parameter
//------------------------------------------------------------------------------
procedure TEasyTable.CreateTable(NewTableName : AnsiString);
begin
  FTableName := StripFileName(NewTableName);
  InternalCreateTable;
end;

//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TEasyTable.DeleteTable;
begin
 InternalDeleteTable;
end; // DeleteTable


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TEasyTable.EmptyTable;
begin
 InternalEmptyTable;
end; // EmptyTable


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TEasyTable.RenameTable(const NewTableName : AnsiString);
begin
 InternalRenameTable(NewTableName);
end; // RenameTable


//------------------------------------------------------------------------------
// copy table
//------------------------------------------------------------------------------
procedure TEasyTable.CopyTable(const NewTableName: AnsiString; const NewDatabaseName: AnsiString = '');
begin
 InternalCopyTable(NewTableName,NewDatabaseName);
end; //CopyTable


//------------------------------------------------------------------------------
//save table
//------------------------------------------------------------------------------
procedure TEasyTable.SaveTable;
begin
 InternalSaveTable;
end;// TEasyTable.SaveTable;


//------------------------------------------------------------------------------
// adds records to current table from another table
//------------------------------------------------------------------------------
function TEasyTable.AddRecords(Dataset: TDataSet;
                         Mode: TAddRecordsMode;
                         var Log : AnsiString) : Boolean;
begin
 result := InternalAddRecords(dataset,mode,log);
end;// AddRecords


//------------------------------------------------------------------------------
// imports table to EasyDataManager format (current table will
// be replaced with imported table)
// returns true, if import was successful, log = ''
// if some errors occured, the error message will be stored
// in log variable
// if source table has no IndexDefs property
// you should pass nil to IndexDefinitions
//------------------------------------------------------------------------------
function TEasyTable.ImportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         var log : AnsiString) : Boolean;
begin
 result := InternalImportTable(dataSource,indexDefinitions,log);
end; //ImportTable


//------------------------------------------------------------------------------
// exports table from EasyDataManager format to any other table or DataManager
// returns true, if export was successful, log = ''
// if some errors occured, the error message will be stored
// in log variable
// if source table has no IndexDefs property
// you should pass nil to IndexDefinitions
// createTablePtr - pointer to CreateTableMethod,
// if the destination table or its analog has no CreateTable you
// should pass pointer to function, which create table with specified struct
// (IndexDefs and FieldDefs)
//------------------------------------------------------------------------------
function TEasyTable.ExportTable(dataSource : TDataSource;
                         indexDefinitions : TIndexDefs;
                         createTablePtr : TProcedure;
                         var log : AnsiString;
                         ToParadox: Boolean=False ) : Boolean;
begin
 result := InternalExportTable(dataSource,indexDefinitions,createTablePtr,log, ToParadox);
end; //ExportTable


//------------------------------------------------------------------------------
// restructure table
// RestructureFieldDefs and RestructureIndexDefs will determine new table structure
// data will be saved where it is possible
// if errors occurs Exception will be rased and original table will be restored
// old table will be backuped to TableName+'_backup'
//------------------------------------------------------------------------------
procedure TEasyTable.RestructureTable(
                         NewEncrypted : Boolean;
                         NewPassword  : AnsiString;
                         NewBLOBBlockSize : Integer;
                         NewBLOBCompression : TCompressionLevel
                              );
begin
 InternalRestructureTable(NewEncrypted,NewPassword,NewBLOBBlockSize,NewBLOBCompression);
end; //RestructureTable


//------------------------------------------------------------------------------
// restructure table
//------------------------------------------------------------------------------
procedure TEasyTable.RestructureTable;
begin
 InternalRestructureTable;
end; //RestructureTable


//------------------------------------------------------------------------------
// returns true, if repair was successful (all data fully restored), log = ''
// tries to repair table
// repair is available, if table header is not corrupted,
// i.e. table opens properly (by setting Active to true)
//------------------------------------------------------------------------------
function TEasyTable.RepairTable(
                          var log : AnsiString // returns error log
                         ) : Boolean;
begin
 Result := InternalRepairTable(log);
end; //RepairTable


//------------------------------------------------------------------------------
// creates new index in table
//------------------------------------------------------------------------------
procedure TEasyTable.AddIndex(
              const Name, // index name
              Fields: AnsiString; // fields list (separated by ';', ',',' ' or any combination)
              Options: TIndexOptions; // ixDescending, ixCaseInsensetive are available options
              const DescFields: AnsiString =''; // desc fields list (separated by ';', ',',' ' or any combination)
              const CaseInsFields: AnsiString ='' // case insensitive fields list (separated by ';', ',',' ' or any combination)
              );
var act: Boolean;
begin
 act := Active;
 if (not act) then
  Active := true;

 DMHandle.SilentMode := False;
 InternalAddIndex(Name,Fields,Options,DescFields,CaseInsFields);
 Active := act;
end; //AddIndex


//------------------------------------------------------------------------------
// delete index
//------------------------------------------------------------------------------
procedure TEasyTable.DeleteIndex(
     											const Name : String// name
                         );
var act: Boolean;
begin
 act := Active;
 if (not act) then
  Active := true;
 InternalDeleteIndex(Name);
 Active := act;
end; //DeleteIndex


//------------------------------------------------------------------------------
// delete all DMHandle.indexes
//------------------------------------------------------------------------------
procedure TEasyTable.DeleteAllIndexes;
var act: Boolean;
begin
 act := Active;
 if (not act) then
  Active := true;
 InternalDeleteAllIndexes;
 Active := act;
end; //DeleteAllIndexes;


//------------------------------------------------------------------------------
// Flushes all changes that have been written to the database table
//------------------------------------------------------------------------------
procedure TEasyTable.FlushBuffers;
begin
 InternalFlushBuffers;
end; //FlushBuffers


//------------------------------------------------------------------------------
// creates list of supported operators
//------------------------------------------------------------------------------
procedure TEasyTable.GetSupportedFieldTypes(
             typeList : TaaList
             );
var
 p_type   : pTETFieldType;
 i : integer;
begin
 typeList.Clear;
 for i := 1 to MAX_SUPPORTED_FIELD_TYPES do
  begin
   new(p_type);
   if (p_type = nil) then raise
    Exception.Create('Error in TEasyTable.GetSupportedFieldTypes - 0 pointer to p_type!');
    {
   p_type.fieldType := SUPPORTED_FIELD_TYPES[i].fieldType;
   p_type.name := SUPPORTED_FIELD_TYPES[i].name;
   }
   p_type^ := SUPPORTED_FIELD_TYPES[i];
   typeList.Add(p_type);
  end;
end; //GetSupportedFieldTypes


//------------------------------------------------------------------------------
// returns true, if field type is supported
//------------------------------------------------------------------------------
function TEasyTable.IsFieldTypeSupported(
             fType : TFieldType // field type
             ) : Boolean;
var i : integer;
begin
 result := false;
 for i := 1 to MAX_SUPPORTED_FIELD_TYPES do
  if (SUPPORTED_FIELD_TYPES[i].fieldType = fType) then
   begin
    result := true;
    break;
   end;
end; //  TEasyTable.IsFieldTypeSupported


//------------------------------------------------------------------------------
// returns table file extesion
//------------------------------------------------------------------------------
function TEasyTable.GetTableFileExtension : AnsiString;
begin
 result := tableFileExtension;
end; //GetTableFileExtension


{ Master / Detail }
{
function TEasyTable.GetMasterFields: AnsiString;
begin
  Result := FMasterLink.FieldNames;
end;

procedure TEasyTable.SetMasterFields(const Value: AnsiString);
begin
  FMasterLink.FieldNames := Value;
end;


procedure TEasyTable.CheckMasterRange;
begin

  if FMasterLink.Active and (FMasterLink.Fields.Count > 0) then
  begin
   FMasterLink.DataSet.Refresh;
   ChangeMasterCondition(FMasterLink.Fields);
   CreateVisibleRecordsList;
   if (Active) then
    begin
     GetRecord(ActiveBuffer,gmCurrent,false);
     Refresh;
    end;
  end;

end;

procedure TEasyTable.MasterChanged(Sender: TObject);
begin
   ChangeMasterCondition(FMasterLink.Fields);
   CreateVisibleRecordsList;
   if (Active) then
    begin
     GetRecord(ActiveBuffer,gmCurrent,false);
     Refresh;
    end;
end;

procedure TEasyTable.MasterDisabled(Sender: TObject);
begin
 CreateVisibleRecordsList;
 if (Active) then
  begin
   GetRecord(ActiveBuffer,gmCurrent,false);
   Refresh;
  end;
end;


procedure TEasyTable.ChangeMasterCondition(MasterFields: TList);
var i : integer;
    s,s1 : AnsiString;
    Fld : TField;
begin
//Exit;
    s := '';
    if (GetIndexFieldCount <= 0) then Exit;
    for I := 0 to MasterFields.Count - 1 do
     begin
      if (GetActiveRecordBuffer <> nil) and (DMHandle.tableHeader.recordCount > 0) then
       GetIndexField(I).Assign(TField(MasterFields[I]));
      Fld := GetIndexField(I);

      if (Fld.DataType = ftString) or (Fld.DataType = ftWideString) then
       s1 := AnsiQuotedStr(TField(MasterFields[I]).AsString,'''')
      else
       s1 := TField(MasterFields[I]).AsString;

      if TField(MasterFields[I]).IsNull or (s1 = '') or (s1 = '''''') then
       if (i > 0) then
        s := s + ' and ('+Fld.FieldName+' IS NULL)'
       else
        s := s + '('+Fld.FieldName+' IS NULL )'
      else
       if (i > 0) then
        s := s + ' and ('+Fld.FieldName+' = '+s1+')'
       else
        s := s + '('+Fld.FieldName+' = '+s1+')';

     end;
  MasterDetailParser.PreParse(s);

//  ShowMessage('master condition changed,  count = '+
//    inttostr(MasterFields.Count));

end; //ChangeMasterCondition
}

//------------------------------------------------------------------------------
// fielddefs support
//------------------------------------------------------------------------------
function TEasyTable.FieldDefsStored: Boolean;
begin
  Result := StoreDefs and (FieldDefs.Count > 0);
end; //FieldDefsStored: Boolean;


//------------------------------------------------------------------------------
// indexdefs support
//------------------------------------------------------------------------------
function TEasyTable.IndexDefsStored: Boolean;
begin
  Result := StoreDefs and (IndexDefs.Count > 0);
end; //TEasyTable.IndexDefsStored: Boolean;


//------------------------------------------------------------------------------
// fills table name list
//------------------------------------------------------------------------------
procedure TEasyTable.GetTableNameList(List : TStrings);
begin
 if (DBMHandle <> nil) then
  DBMHandle.GetNonTempTablesList(List)
 else
  begin
   // get handle to database manager (find or create)
   SetDBFlag(dbfTable, True);
   try
    DBMHandle.GetNonTempTablesList(List);
   finally
    SetDBFlag(dbfTable, False);
   end;
  end;
end; //GetTableNameList(List : TStrings);


{$IFDEF D6H}
//------------------------------------------------------------------------------
// get default order
//------------------------------------------------------------------------------
function TEasyTable.PSGetDefaultOrder: TIndexDef;

  function GetIdx(IdxType: TIndexOption): TIndexDef;
  var
    i: Integer;
  begin
    Result := nil;
    for i := 0 to IndexDefs.Count - 1 do
      if (IdxType in IndexDefs[i].Options) then
      try
        Result := IndexDefs[i];
        if (Result.Name[1] <> '@') then
         begin
          GetFieldList(TList(nil), Result.Fields);
          break;
         end
        else
         begin
          Result := nil;
          Continue;
         end;
      except
        Result := nil;
      end;
  end;

var
  DefIdx: TIndexDef;
begin
  DefIdx := nil;
  IndexDefs.Update;
  try
    if IndexName <> '' then
      DefIdx := IndexDefs.Find(IndexName)
    else
     if IndexFieldNames <> '' then
      DefIdx := IndexDefs.FindIndexForFields(IndexFieldNames);
    if Assigned(DefIdx) then
      GetFieldList(TList(nil), DefIdx.Fields);
  except
    DefIdx := nil;
  end;
  if not Assigned(DefIdx) then
    DefIdx := GetIdx(ixPrimary);
  if not Assigned(DefIdx) then
    DefIdx := GetIdx(ixUnique);
  if Assigned(DefIdx) then
   begin
    Result := TIndexDef.Create(nil);
    Result.Assign(DefIdx);
   end
  else
   Result := nil;
end; // PSGetDefaultOrder


//------------------------------------------------------------------------------
// get key fields
//------------------------------------------------------------------------------
function TEasyTable.PSGetKeyFields: String;
var
  i, Pos: Integer;
  IndexFound: Boolean;
begin
  Result := inherited PSGetKeyFields;
  if Result = '' then
   begin
    if not Exists then
     Exit;
    IndexFound := False;
    IndexDefs.Update;
    for i := 0 to IndexDefs.Count - 1 do
      if ixUnique in IndexDefs[I].Options then
       begin
        Result := IndexDefs[I].Fields;
        IndexFound := (FieldCount = 0);
        if not IndexFound then
         begin
          Pos := 1;
          while Pos <= Length(Result) do
           begin
            IndexFound := FindField(ExtractFieldName(Result, Pos)) <> nil;
            if not IndexFound then
             Break;
           end;
         end;
        if IndexFound then
         Break;
       end;
    if not IndexFound then
     Result := '';
   end;
end; // PSGetKeyFields


//------------------------------------------------------------------------------
// get table name
//------------------------------------------------------------------------------
function TEasyTable.PSGetTableName: String;
begin
  Result := TableName;
end; // PSGetTableName


//------------------------------------------------------------------------------
// get index defs
//------------------------------------------------------------------------------
function TEasyTable.PSGetIndexDefs(IndexTypes: TIndexOptions): TIndexDefs;
begin
  Result := GetIndexDefs(IndexDefs, IndexTypes);
end; // PSGetIndexDefs


//------------------------------------------------------------------------------
// set command text
//------------------------------------------------------------------------------
procedure TEasyTable.PSSetCommandText(const CommandText: String);
begin
  if CommandText <> '' then
    TableName := CommandText;
end; // PSSetCommandText


//------------------------------------------------------------------------------
// set params
//------------------------------------------------------------------------------
procedure TEasyTable.PSSetParams(AParams: TParams);

  procedure AssignFields;
  var
    I: Integer;
  begin
    for I := 0 to AParams.Count - 1 do
      if AParams[I].Name <> '' then
        FieldByName(AParams[I].Name).Value := AParams[I].Value
      else
        IndexFields[I].Value := AParams[I].Value;
  end;

begin
  if AParams.Count > 0 then
   begin
    Open;
    SetRangeStart;
    AssignFields;
    SetRangeEnd;
    AssignFields;
    ApplyRange;
   end
  else
   if Active then
    CancelRange;
  PSReset;
end; // PSSetParams
{$ENDIF}


//------------------------------------------------------------------------------
// Get data source
//------------------------------------------------------------------------------
function TEasyTable.GetDataSource: TDataSource;
begin
  Result := FMasterLink.DataSource;
end; // GetDataSource


//------------------------------------------------------------------------------
// Get master table fields values
//------------------------------------------------------------------------------
procedure TEasyTable.DoOnNewRecord;
var
   I: Integer;
begin
   if FMasterLink.Active and (FMasterLink.Fields.Count > 0) then
      begin
      for I:=0 to FMasterLink.Fields.Count-1 do
         IndexFields[I]:=TField(FMasterLink.Fields[I]);
      end;
   inherited DoOnNewRecord;
end;// DoOnNewRecord;


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TEasyTable.DoOnProgress(Progress : Real);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress,FProgressProcess);
end; // DoOnProgress



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyDatabaseManager
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// creates manager with specified database component
//------------------------------------------------------------------------------
constructor TEasyDatabaseManager.Create(EDB: TEasyDatabase);
begin
 FDatabaseFileMode := dfmNormal;
 if (EDB.DatabaseFileName <> '') then
  begin
    FDatabaseName := EDB.DatabaseFileName;
    bDatabaseFile := true; // Database file
    DefaultFileStoreMode := fsmESFS;
    FDatabaseFileMode := EDB.DatabaseFileMode;
  end
 else
 if (UpperCase(EDB.DatabaseName) = 'MEMORY') then
  begin
    FDatabaseName := EDB.DatabaseName;
    bDatabaseFile := false; // Database file
    DefaultFileStoreMode := fsmInMemory;
    FDatabaseFileMode := EDB.DatabaseFileMode;
  end
 else
  begin
   FDatabaseName := EDB.Directory;
   bDatabaseFile := false; // Directory
   DefaultFileStoreMode := fsmDisk;
  end;
 DatabaseList := TList.Create;
 DataSetList := TList.Create;
 ETblEnterCriticalSection(FDBMLockSection);
 try
  DatabaseManagerList.Add(self);
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
 FReadOnly := EDB.ReadOnly;
 FInMemory := EDB.InMemory;
 SMHandle := EDB.Session.Handle;
end;// Create(EDB)

//------------------------------------------------------------------------------
// creates manager with specified dataset
//------------------------------------------------------------------------------
constructor TEasyDatabaseManager.Create(EDS: TEasyDataset);
begin
 FDatabaseFileMode := dfmNormal;
 if (EDS.DatabaseFileName <> '') then
  begin
    FDatabaseName := EDS.DatabaseFileName;
    bDatabaseFile := true; // Database file
    DefaultFileStoreMode := fsmESFS;
  end
 else
  begin
   FDatabaseName := EDS.DatabaseName;
   if (EDS.FInMemory) then
    begin
     bDatabaseFile := false;
     DefaultFileStoreMode := fsmInMemory;
    end
   else
   if (DirectoryExists(FDatabaseName)) then
    begin
     bDatabaseFile := false; // Directory
     DefaultFileStoreMode := fsmDisk;
    end
   else
    if (FDatabaseName <> '') then
     begin
      bDatabaseFile := true; // Database file
      DefaultFileStoreMode := fsmESFS;
     end;
  end;
 DatabaseList := TList.Create;
 DataSetList := TList.Create;
 ETblEnterCriticalSection(FDBMLockSection);
 try
  DatabaseManagerList.Add(self);
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
 FReadOnly := EDS.ReadOnly;
 FInMemory := EDS.InMemory;
end;// Create(EDS)


//------------------------------------------------------------------------------
// creates manager with specified directory
//------------------------------------------------------------------------------
constructor TEasyDatabaseManager.Create(DBName: AnsiString);
begin
 FDatabaseFileMode := dfmNormal;
 FDatabaseName := DBName;
 DatabaseList := TList.Create;
 DataSetList := TList.Create;
 ETblEnterCriticalSection(FDBMLockSection);
 try
  DatabaseManagerList.Add(self);
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
 if (not DirectoryExists(DBName)) then
  bDatabaseFile := true // Database file
 else
  bDatabaseFile := false; // Directory
 if (bDatabaseFile) then
  DefaultFileStoreMode := fsmESFS
 else
  DefaultFileStoreMode := fsmDisk;
 FReadOnly := false;
 FInMemory := false;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyDatabaseManager.Destroy;
begin
 CloseESFSFile;
 // free internal lists
 DatabaseList.Free;
 DataSetList.Free;
 DatabaseList := nil;
 DataSetList := nil;
 // remove itself from global list of database managers
 ETblEnterCriticalSection(FDBMLockSection);
 try
  DatabaseManagerList.Remove(self);
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//Destroy


//------------------------------------------------------------------------------
// open ESFS file (used in design-time)
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.OpenESFSFile;
begin
    if (bDatabaseFile and not FInMemory) then
     GetPFSHandle(fsmESFS);
end;// OpenESFSFile


//------------------------------------------------------------------------------
// close ESFS file (used in design-time)
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.CloseESFSFile;
begin
 // if disk ESFS -then close it
 if (bDatabaseFile and not FInMemory) then
  PFSManager.ClosePhysESFS(FDatabaseName, FInMemory);
end;// CloseESFSFile


//------------------------------------------------------------------------------
// detects if database with specified name is included
//------------------------------------------------------------------------------
function TEasyDatabaseManager.HasDatabaseName(DBName: AnsiString): boolean;
var i: integer;
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
   result := false;
   if (LowerCase(FDatabaseName) = LowerCase(DBName)) then
    result := true
   else
    for i:=0 to DatabaseList.Count-1 do
      if (LowerCase(TEasyDatabase(DatabaseList.Items[i]).DatabaseName) = LowerCase(DBName)) then
       begin
        result := true;
        break;
       end;
   // check props
  { if (not result) then
    begin
     EDBHandle := aaFindDatabase(DBName);
     if (EDBHandle <> nil) then
      begin
       result := (EDBHandle.DatabaseName = FDatabaseName) or
                 (EDBHandle.DatabaseFileName = FDatabaseName);
      end;

    end;}
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//HasDatabaseName


//------------------------------------------------------------------------------
// get password from manager
//------------------------------------------------------------------------------
function TEasyDatabaseManager.FPassword: AnsiString;
var EDB: TEasyDatabase;
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
  FPassword := '';
  if (DatabaseList.Count > 0) then
   begin
//    FPassword := TEasyDatabase(DatabaseList.Items[0]).Password;
    EDB := aaFindDatabase(FDatabaseName,DatabaseList);
    if (EDB <> nil) then
     FPassword := TEasyDatabase(EDB).Password;
   end;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;// FPassword


//------------------------------------------------------------------------------
// if all disconnected - destroy
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.CheckToDestroy;
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
 // check if DBM already destroyed
 if (DatabaseList = nil) or (DataSetList = nil) then
  Exit;
 if (DatabaseList.Count = 0) and (DataSetList.Count = 0) then
  begin
   if (DatabaseManagerList.IndexOf(self) <> -1) then
    Destroy;
  end;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;


//------------------------------------------------------------------------------
// connect database component (adds to list)
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.ConnectDatabase(DBHandle: TEasyDatabase);
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
   if (DatabaseList.Count = 0) then
    begin
      FReadOnly := DBHandle.ReadOnly;
      FInMemory := DBHandle.InMemory;
      FDatabaseFileMode := DBHandle.DatabaseFileMode;
      DatabaseList.Add(DBHandle);
      try
       // open database file and get read-only file attribute
       OpenESFSFile;
      except
       DatabaseList.Remove(DBHandle);
      end;
      // if database file is read-only then set property value
      if (not bDesignMode) then
       begin
        if (FReadOnly) then
         DBHandle.ReadOnly := FReadOnly;
        if (DBHandle.ReadOnly) then
         FReadOnly := DBHandle.ReadOnly;
       end
      else
       CloseESFSFile;
    end
   else
    begin
      if (DatabaseList.IndexOf(DBHandle) = -1) then
       begin
        if (FReadOnly and not DBHandle.ReadOnly and not bDesignMode) then
         DBHandle.ReadOnly := FReadOnly;
//         raise Exception.Create('TEasyDatabaseManager.ConnectDatabase - database is already open in read-only mode.');
        if (FInMemory <> DBHandle.InMemory) then
         raise Exception.Create('TEasyDatabaseManager.ConnectDatabase - database is already open with other in-memory mode value.');
        DatabaseList.Add(DBHandle);
       end;
    end;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//ConnectDatabase


//------------------------------------------------------------------------------
// disconnect database component (removes from list)
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.DisconnectDatabase(DBHandle: TEasyDatabase);
var i: integer;
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
  // bug fix
   if (DatabaseList.IndexOf(DBHandle) < 0) then
    Exit;

   // disconnect all DataSets of this database
   i := 0;
   while i < DataSetList.Count do
    begin
  //bug
     if (TEasyDataSet(DataSetList.Items[i]).DBHandle = DBHandle) then
      begin
       if (not TEasyDataSet(DataSetList.Items[i]).Active) then
        inc(i)
       else
        TEasyDataSet(DataSetList.Items[i]).Active := false;
      end
     else
      inc(i);
     if (DataSetList = nil) or (DatabaseList = nil) then
      break;
    end;

   // removes handle from list
   DatabaseList.Remove(DBHandle);
   // destroy if all disconnected
   CheckToDestroy;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//DisconnectDatabase


//------------------------------------------------------------------------------
// connect DataSet component (adds to list)
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.ConnectDataSet(DSHandle: TEasyDataSet);
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
   // if database is read-only then dataset becomes read-only too
   if (not bDesignMode) then
    begin
     if (FReadOnly) then
      DSHandle.ReadOnly := FReadOnly;
     if (DataSetList.Count = 0) then
      begin
// commented in 6.20      
//      if (DSHandle.ReadOnly) then
//       FReadOnly := DSHandle.ReadOnly;
       // set in-memory?
       if (not bDatabaseFile) then
        begin
         FInMemory := DSHandle.InMemory;
         if (FInMemory) then
          begin
           DefaultFileStoreMode := fsmInMemory
          end
         else
          DefaultFileStoreMode := fsmDisk;
        end;
      end;
    end;
   // add dataset to list
   DataSetList.Add(DSHandle);
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//ConnectDataSet


//------------------------------------------------------------------------------
// disconnect DataSet component (removes from list)
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.DisconnectDataSet(DSHandle: TEasyDataSet);
begin
 ETblEnterCriticalSection(FDBMLockSection);
 try
   if (DataSetList.IndexOf(DSHandle) < 0) then
    Exit;
   // removes handle from list
   DataSetList.Remove(DSHandle);
   // deactivate DataManager
   DSHandle.Active := false;
   // destroy if all disconnected
   CheckToDestroy;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;//DisconnectDataSet


//------------------------------------------------------------------------------
// returns list of names of non temporary tables from directory or database file
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.GetNonTempTablesList(List: TStrings);
var
    PFSHandle: TAbstractPlainFileSystem;
begin
 // get according plain file system
 PFSHandle := GetPFSHandle(DefaultFileStoreMode);
 if (PFSHandle <> nil) then
   PFSHandle.GetFilesListByExt(tableFileExtension, List);
 if (bDesignMode) then
  CloseESFSFile;
end;// GetNonTempTablesListFromDatabaseFile


//------------------------------------------------------------------------------
// open file from directory of from database file
//------------------------------------------------------------------------------
function TEasyDatabaseManager.OpenFile(
                    FileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode; // file store mode
                    bCreateFile: boolean; // create file?
                    bExclusive: boolean; // open in exclusive mode
                    bReadOnly: boolean // open in read-only mode
                 ): TAbstractFile;
var
    PFSHandle: TAbstractPlainFileSystem;
    DefaultPFSHandle: TAbstractPlainFileSystem;
    bWasAlreadyOpen: boolean;
    FHandle: TAbstractFile;
    DefaultFHandle: TAbstractFile;
begin
 // if ESFS in-memory then no need to create memory file
 if (FileStoreMode = fsmInMemory) and FInMemory and
    (DefaultFileStoreMode = fsmESFS) then
  FileStoreMode := fsmDefault;

 // get according plain file system
 PFSHandle := GetPFSHandle(FileStoreMode);
 // check if the file was already open
 bWasAlreadyOpen := (PFSHandle.GetOpenFile(FileName) <> nil);
 // open file
 // if open InMemory file that was not already open then
 if (FileStoreMode = fsmInMemory) and (not bCreateFile) and (not bWasAlreadyOpen) then
  begin
   FHandle := PFSHandle.OpenFile(FileName, true, bExclusive, bReadOnly);
   // read file data from disk or flat file into memory file
   DefaultPFSHandle := GetPFSHandle(DefaultFileStoreMode);
   // open existing disk/flat file in read-only mode
   DefaultFHandle := DefaultPFSHandle.OpenFile(FileName, false, false, true);
   // copy data
   FHandle.CopyFrom(DefaultFHandle, DefaultFHandle.Size);
   // reset position
   FHandle.Position := 0;
   DefaultPFSHandle.CloseFile(DefaultFHandle);
  end
 else
  FHandle := PFSHandle.OpenFile(FileName, bCreateFile, bExclusive, bReadOnly);
 result := FHandle;
end;// OpenFile


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.CloseFile(FileHandle: TAbstractFile);
begin
 FileHandle.FPFSHandle.CloseFile(FileHandle);
end;// CloseFile


//------------------------------------------------------------------------------
// if file exists returns true
//------------------------------------------------------------------------------
function TEasyDatabaseManager.aaFileExists(
                    FileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode
                     ): Boolean;
var
    FSMode: TaaFileStoreMode;
    PFSHandle: TAbstractPlainFileSystem;
begin
 // if default - then get default file store mode - disk or flat file
 if (FileStoreMode = fsmDefault) then
  FSMode := DefaultFileStoreMode
 else
  FSMode := FileStoreMode;
 PFSHandle := PFSManager.GetPFSHandle(FDatabaseName, FPassword, FSMode,
                                      FReadOnly, FInMemory);
 if (PFSHandle <> nil) then
  result := PFSHandle.FileExists(FileName)
 else
  result := false;
end; //FileExists


//------------------------------------------------------------------------------
// if file deleted successfully returns true
//------------------------------------------------------------------------------
function TEasyDatabaseManager.aaDeleteFile(
                    FileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode
                     ): Boolean;
var
    FSMode: TaaFileStoreMode;
    PFSHandle: TAbstractPlainFileSystem;
begin
 // if ESFS in-memory then no need to create memory file
 if (FileStoreMode = fsmInMemory) and FInMemory and
    (DefaultFileStoreMode = fsmESFS) then
  FileStoreMode := fsmDefault;

 // if default - then get default file store mode - disk or flat file
 if (FileStoreMode = fsmDefault) then
  FSMode := DefaultFileStoreMode
 else
  FSMode := FileStoreMode;
 PFSHandle := PFSManager.GetPFSHandle(FDatabaseName, FPassword, FSMode, FReadOnly, FInMemory);
 if (PFSHandle <> nil) then
  result := PFSHandle.DeleteFile(FileName)
 else
  result := false;
end; //DeleteFile


//------------------------------------------------------------------------------
// if file renamed successfully returns true
//------------------------------------------------------------------------------
function TEasyDatabaseManager.aaRenameFile(
                    OldFileName, NewFileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode
                     ): Boolean;
var
    FSMode: TaaFileStoreMode;
    PFSHandle: TAbstractPlainFileSystem;
begin
 // if ESFS in-memory then no need to create memory file
 if (FileStoreMode = fsmInMemory) and FInMemory and
    (DefaultFileStoreMode = fsmESFS) then
  FileStoreMode := fsmDefault;

 // if default - then get default file store mode - disk or flat file
 if (FileStoreMode = fsmDefault) then
  FSMode := DefaultFileStoreMode
 else
  FSMode := FileStoreMode;
 PFSHandle := PFSManager.GetPFSHandle(FDatabaseName, FPassword, FSMode, FReadOnly, FInMemory);
 if (PFSHandle <> nil) then
  result := PFSHandle.RenameFile(OldFileName, NewFileName)
 else
  result := false;
end; //RenameFile


//------------------------------------------------------------------------------
// if file copied successfully returns true
//------------------------------------------------------------------------------
function TEasyDatabaseManager.aaCopyFile(
                    OldFileName, NewFileName: AnsiString; // file name without path
                    FileStoreMode: TaaFileStoreMode; // old file store mode
                    NewDatabaseName: AnsiString = ''// new databasename
                     ): Boolean;
var
    FSMode: TaaFileStoreMode;
    NewHandle: TEasyDatabaseManager;
    OldPFSHandle, NewPFSHandle:  TAbstractPlainFileSystem;
    OldFileHandle, NewFileHandle: TAbstractFile;
    tmpDB: TEasyDatabase;
begin
 // if ESFS in-memory then no need to create memory file
 if (FileStoreMode = fsmInMemory) and FInMemory and
    (DefaultFileStoreMode = fsmESFS) then
  FileStoreMode := fsmDefault;

 // if default - then get default file store mode - disk or flat file
 if (FileStoreMode = fsmDefault) then
  FSMode := DefaultFileStoreMode
 else
  FSMode := FileStoreMode;

 tmpDB := nil;
 // get src DBMHandle
 if (NewDatabaseName <> '') then
  begin
    tmpDB := TEasyDatabase.Create(nil);
    if (SysUtils.FileExists(NewDatabaseName)) then
     tmpDB.DatabaseFileName := NewDatabaseName
    else
     tmpDB.DatabaseName := NewDatabaseName;
    tmpDB.CreateHandle;
    NewHandle := tmpDB.Handle;
  end
 else
  NewHandle := self;
 try
  try
   // get file systems
   OldPFSHandle := PFSManager.GetPFSHandle(FDatabaseName, FPassword, FSMode, FReadOnly, FInMemory);
   NewPFSHandle := PFSManager.GetPFSHandle(NewHandle.FDatabaseName, FPassword,
                     NewHandle.DefaultFileStoreMode, FReadOnly, NewHandle.FInMemory);
   // open files
   OldFileHandle := OldPFSHandle.OpenFile(OldFileName,false,false,true);
   NewFileHandle := NewPFSHandle.OpenFile(NewFileName,true,false,false);
   // copy
   NewFileHandle.CopyFrom(OldFileHandle,OldFileHandle.Size);
   // close files
   OldPFSHandle.CloseFile(OldFileHandle);
   NewPFSHandle.CloseFile(NewFileHandle);
   result := true;
  except
   result := false;
  end;
 finally
  if (tmpDB <> nil) then
   begin
    tmpDB.DestroyHandle;
    tmpDB.Free;
   end;
 end;
end; //CopyFile


//------------------------------------------------------------------------------
// save file
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.SaveFile(FileName: AnsiString);
var
    DBMHandle: TEasyDatabaseManager;
    OldPFSHandle, NewPFSHandle:  TAbstractPlainFileSystem;
    OldFileHandle, NewFileHandle: TAbstractFile;
begin
  DBMHandle := self;
  try
   // get file systems
   OldPFSHandle := PFSManager.GetPFSHandle(FDatabaseName, FPassword, fsmInMemory, FReadOnly, FInMemory);
   NewPFSHandle := PFSManager.GetPFSHandle(DBMHandle.FDatabaseName, FPassword, DefaultFileStoreMode, FReadOnly, FInMemory);
   // open files
   OldFileHandle := OldPFSHandle.OpenFile(FileName,false,false,true);
   NewFileHandle := NewPFSHandle.OpenFile(FileName,true,false,false);
   // copy
   NewFileHandle.CopyFrom(OldFileHandle,OldFileHandle.Size);
   // close files
   OldPFSHandle.CloseFile(OldFileHandle);
   NewPFSHandle.CloseFile(NewFileHandle);
  except
  end;
end;// TEasyDatabaseManager.SaveFile


//------------------------------------------------------------------------------
// create ESFS files
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.CreateDatabase;
var
  path: AnsiString;
begin
  if (DataSetList.Count > 0) then
   raise Exception.Create('TEasyDatabaseManager.CreateDatabase - Some datasets are connected.');
  if (bDatabaseFile) then
   begin
    path := ExtractFilePath(ExpandFileName(FDatabaseName));
    if not DirectoryExists(path) then
     raise Exception.Create('TEasyDatabaseManager.CreateDatabase - Cannot create database file "'+
                            FDatabaseName+'" as the directory "'+
                            path+'" does not exist');

    if (not PFSManager.CreatePhysESFS(FDatabaseName, FPassword, FInMemory,
        FDatabaseFileMode)) then
     raise Exception.Create('TEasyDatabaseManager.CreateDatabase - Cannot create database file "'+FDatabaseName+'"');
   end;
end;// CreateDatabase


//------------------------------------------------------------------------------
// delete ESFS files
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.DeleteDatabase;
begin
  if (DataSetList.Count > 0) then
   raise Exception.Create('TEasyDatabaseManager.DeleteDatabase - Some datasets are connected.');
  if (bDatabaseFile) then
   PFSManager.DeletePhysESFS(FDatabaseName, FInMemory);
end;// DeleteDatabase


//------------------------------------------------------------------------------
// rename ESFS file
//------------------------------------------------------------------------------
function TEasyDatabaseManager.RenameDatabase(const NewDatabaseName: AnsiString): Boolean;
begin
  if (DataSetList.Count > 0) then
   raise Exception.Create('TEasyDatabaseManager.RenameDatabase - Some datasets are connected.');
  if (bDatabaseFile) then
   result := PFSManager.RenamePhysESFS(FDatabaseName, FInMemory, NewDatabaseName)
  else
   result := true;

  if (result) then
   FDatabaseName := NewDatabaseName;
end;// RenameDatabase


//------------------------------------------------------------------------------
// copy ESFS file
//------------------------------------------------------------------------------
function TEasyDatabaseManager.CopyDatabase(const NewDatabaseName: AnsiString): Boolean;
var
  i: integer;
begin
  if (DataSetList.Count > 0) then
    for i:=0 to DataSetList.Count-1 do
     if not (TEasyDataset(DataSetList.Items[i]).ReadOnly) then
      begin
       TEasyDataset(DataSetList.Items[i]).InternalFlushBuffers;
       TEasyDataset(DataSetList.Items[i]).DMHandle.FlushIndexesToDisk;
      end;

  if (bDatabaseFile) then
   result := PFSManager.CopyPhysESFS(FDatabaseName, FInMemory, NewDatabaseName)
  else
   result := true;

end;// CopyDatabase


//------------------------------------------------------------------------------
// get File System for specified FileStoreMode
//------------------------------------------------------------------------------
function TEasyDatabaseManager.GetPFSHandle(FileStoreMode: TaaFileStoreMode): TAbstractPlainFileSystem;
var
    FSMode: TaaFileStoreMode;
begin
 // if ESFS in-memory then no need to create memory file
 if (FileStoreMode = fsmInMemory) and FInMemory and
    (DefaultFileStoreMode = fsmESFS) then
  FileStoreMode := fsmDefault;

 // if default - then get default file store mode - disk or flat file
 if (FileStoreMode = fsmDefault) then
  FSMode := DefaultFileStoreMode
 else
  FSMode := FileStoreMode;
 result := PFSManager.GetPFSHandle(FDatabaseName, FPassword, FSMode, FReadOnly, FInMemory);
end;// GetPFSHandle


//------------------------------------------------------------------------------
// ESFS exists?
//------------------------------------------------------------------------------
function TEasyDatabaseManager.GetExists: boolean;
begin
  if (not bDatabaseFile) then
   if (FInMemory) then
    result := true
   else
    result := DirectoryExists(FDatabaseName)
  else
   if (FInMemory) then
    result := (GetPFSHandle(fsmESFS) <> nil)
   else
    result := SysUtils.FileExists(FDatabaseName);
end;// GetExists


//------------------------------------------------------------------------------
// in memory mode
//------------------------------------------------------------------------------
procedure TEasyDatabaseManager.SetInMemory(Value: Boolean);
var
  esfsPFS: TESFSPlainFileSystem;
begin
 esfsPFS := nil;
 if (bDatabaseFile) then
  esfsPFS := TESFSPlainFileSystem(GetPFSHandle(fsmESFS));
 if (esfsPFS <> nil) then
  esfsPFS.InMemory := Value;
 FInMemory := Value;
end;// SetInMemory


{$IFDEF FULL_VERSION}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyQueryDataLink
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TEasyQueryDataLink.Create(AQuery: TEasyQuery);
begin
  inherited Create;
  FQuery := AQuery;
end;

procedure TEasyQueryDataLink.ActiveChanged;
begin
  if FQuery.Active then FQuery.RefreshParams;
end;

function TEasyQueryDataLink.GetDetailDataSet: TDataSet;
begin
  Result := FQuery;
end;

procedure TEasyQueryDataLink.RecordChanged(Field: TField);
begin
  if (Field = nil) and FQuery.Active then FQuery.RefreshParams;
end;

procedure TEasyQueryDataLink.CheckBrowseMode;
begin
  if FQuery.Active then FQuery.CheckBrowseMode;
end;



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyQuery
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets query text
//------------------------------------------------------------------------------
procedure TEasyQuery.SetQuery(Value: TStrings);
begin
  if SQL.Text <> Value.Text then
  begin
    Active := false;
    SQL.BeginUpdate;
    try
      SQL.Assign(Value);
    finally
      SQL.EndUpdate;
    end;
  end;
end; //SetQuery/


//------------------------------------------------------------------------------
// sets params
//------------------------------------------------------------------------------
procedure TEasyQuery.SetParamsList(Value: TParams);
begin
  FParams.AssignValues(Value);
end; //SetParamsList


//------------------------------------------------------------------------------
// sets params from datasource
//------------------------------------------------------------------------------
procedure TEasyQuery.SetParamsFromCursor;
var
  I: Integer;
  DataSet: TDataSet;
begin
  if FDataLink.DataSource <> nil then
  begin
    DataSet := FDataLink.DataSource.DataSet;
    if DataSet <> nil then
    begin
      DataSet.FieldDefs.Update;
      for I := 0 to FParams.Count - 1 do
        with FParams[I] do
          if not Bound then
          begin
            AssignField(DataSet.FieldByName(Name));
            Bound := False;
          end;
    end;
  end;
end;// SetParamsFromCursor


//------------------------------------------------------------------------------
// changes query
//------------------------------------------------------------------------------
procedure TEasyQuery.QueryChanged(Sender: TObject);
var
  List: TParams;
begin
  if not (csReading in ComponentState) then
  begin
    Close;
    StrDispose(SQLBinary);
    SQLBinary := nil;
    if ParamCheck or (csDesigning in ComponentState) then
    begin
      List := TParams.Create(Self);
      try
        // CB bug fix
        if (FSQL.Text <> '') then
         FText := FSQL.Text
        else
         FText := FSQL4.Text;
        FText := List.ParseSQL(FText, True);
        List.AssignValues(FParams);
        FParams.Clear;
        FParams.Assign(List);
      finally
        List.Free;
      end;
    end else
      FText := SQL.Text;
    DataEvent(dePropertyChange, 0);
  end else
    FText := FParams.ParseSQL(SQL.Text, False);
end; //QueryChanged


//------------------------------------------------------------------------------
// sets params datasource
//------------------------------------------------------------------------------
procedure TEasyQuery.SetDataSource(Value: TDataSource);
begin
  if IsLinkedTo(Value) then
    raise ETblException.Create(01056, Self);
  FDataLink.DataSource := Value;
end;// SetDataSource


//------------------------------------------------------------------------------
// gets params datasource
//------------------------------------------------------------------------------
function TEasyQuery.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;// GetDataSource


//------------------------------------------------------------------------------
// gets params count
//------------------------------------------------------------------------------
function TEasyQuery.GetParamsCount: Word;
begin
  Result := FParams.Count;
end;// GetParamsCount


//------------------------------------------------------------------------------
// writes params
//------------------------------------------------------------------------------
procedure TEasyQuery.DefineProperties(Filer: TFiler);

  function WriteData: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not FParams.IsEqual(TEasyQuery(Filer.Ancestor).FParams) else
      Result := FParams.Count > 0;
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', ReadBinaryData, WriteBinaryData, SQLBinary <> nil);
  Filer.DefineProperty('ParamData', ReadParamData, WriteParamData, WriteData);
end;// DefineProperties


//------------------------------------------------------------------------------
// read param data
//------------------------------------------------------------------------------
procedure TEasyQuery.ReadParamData(Reader: TReader);
begin
  Reader.ReadValue;
  Reader.ReadCollection(FParams);
end;// ReadParamData


//------------------------------------------------------------------------------
// writes param data
//------------------------------------------------------------------------------
procedure TEasyQuery.WriteParamData(Writer: TWriter);
begin
  Writer.WriteCollection(Params);
end;// WriteParamData


//------------------------------------------------------------------------------
// read sql
//------------------------------------------------------------------------------
procedure TEasyQuery.ReadBinaryData(Stream: TStream);
begin
  SQLBinary := {$IFDEF D12H}AnsiStrAlloc(Stream.Size){$ELSE}StrAlloc(Stream.Size){$ENDIF};
  Stream.ReadBuffer(SQLBinary^, Stream.Size);
end;// ReadBinaryData


//------------------------------------------------------------------------------
// writes sql
//------------------------------------------------------------------------------
procedure TEasyQuery.WriteBinaryData(Stream: TStream);
begin
  Stream.WriteBuffer(SQLBinary^, StrBufSize(SQLBinary));
end;// WriteBinaryData


//------------------------------------------------------------------------------
// refreshes params
//------------------------------------------------------------------------------
procedure TEasyQuery.RefreshParams;
var
  DataSet: TDataSet;
begin
  DisableControls;
  try
    if FDataLink.DataSource <> nil then
    begin
      DataSet := FDataLink.DataSource.DataSet;
      if DataSet <> nil then
        if DataSet.Active and (DataSet.State <> dsSetKey) then
        begin
          Close;
          Open;
        end;
    end;
  finally
    EnableControls;
  end;
end;// RefreshParams


{$IFDEF D6H}
//------------------------------------------------------------------------------
// execute
//------------------------------------------------------------------------------
procedure TEasyQuery.PSExecute;
begin
  ExecSQL;
end; // PSExecute


//------------------------------------------------------------------------------
// get default order
//------------------------------------------------------------------------------
function TEasyQuery.PSGetDefaultOrder: TIndexDef;
begin
  Result := inherited PSGetDefaultOrder;
  if not Assigned(Result) then
    Result := GetIndexForOrderBy(SQL.Text, Self);
end; // PSGetDefaultOrder


//------------------------------------------------------------------------------
// get params
//------------------------------------------------------------------------------
function TEasyQuery.PSGetParams: TParams;
begin
  Result := Params;
end; // PSGetParams


//------------------------------------------------------------------------------
// get table name
//------------------------------------------------------------------------------
function TEasyQuery.PSGetTableName: String;
begin
  Result := GetTableNameFromSQL(SQL.Text);
end; // PSGetTableName


//------------------------------------------------------------------------------
// set command text
//------------------------------------------------------------------------------
procedure TEasyQuery.PSSetCommandText(const CommandText: String);
begin
  if CommandText <> '' then
    SQL.Text := CommandText;
end; // PSSetCommandText


//------------------------------------------------------------------------------
// set params
//------------------------------------------------------------------------------
procedure TEasyQuery.PSSetParams(AParams: TParams);
begin
  if AParams.Count <> 0 then
    Params.Assign(AParams);
  Close;
end; // PSSetParams
{$ENDIF}


//------------------------------------------------------------------------------
// opens query
//------------------------------------------------------------------------------
procedure TEasyQuery.InternalOpen;
var
  OldDatabaseName, OldDatabaseFileName: AnsiString;
  OldInMemory: Boolean;
begin
 if (FSQLProcessor = nil) then
  begin
   FTemporaryTable := False;

   // CB bug fix
   if (FSQL4.Text <> '') then
    FText := FSQL4.Text
   else
    FText := FSQL.Text;
   {
   if (FSQL.Text <> '') then
    FText := FSQL.Text
   else
    FText := FSQL4.Text;
   }
   // prepare params
   if FDataLink.DataSource <> nil then SetParamsFromCursor;

   // here will be executing query
   FSQLProcessor := TSQLScriptProcessor.Create(FText, FParams);
   FreezeVisibleRecords;
   try
    FSQLProcessor.ExecSQL(Self);
    ResultTable := TEasyTable(FSQLProcessor.GetResultDataset);
    if (ResultTable = nil) then
//     raise Exception.Create('FText = '+FText+' FSQL.Text = '+FSQL.Text+' FSQL2.Text = '+FSQL2.Text+' FSQL3.Text = '+FSQL3.Text+' FSQL4.Text = '+FSQL4.Text);
     raise ETblException.Create(01088, Self);
    // init query
    OldDatabaseName := FDatabaseName;
    OldDatabaseFileName := FDatabaseFileName;
    OldInMemory := FInMemory;
    try
     FDatabaseName := ResultTable.DatabaseName;
     FDatabaseFileName := ResultTable.DatabaseFileName;
     FTableName := ResultTable.TableName;
     FInMemory := ResultTable.InMemory;
     FTemporaryTable := ResultTable.FTemporaryTable;
     if (FSQLProcessor.GetResultAO is TEasyAOTable) then
      begin
       SetSQLFilter(FSQLProcessor.GetResultAO.FFilterExpr);
      end;
     SetSQLTopRowCount(FSQLProcessor.GetResultAO.FFirstRowNo,
                       FSQLProcessor.GetResultAO.FTopRowCount);
     FIndexName := ResultTable.IndexName;
     FDistinctFields := ResultTable.FDistinctFields;
     try
       // reopen database to connect it
       SetDBFlag(dbfOpened, False);
       SetDBFlag(dbfOpened, True);
       // connect query to table
       if (ResultTable.FProjectionFieldList.Count > 0) then
        FDoNotBindFields := True;
       inherited InternalOpen;
       FDoNotBindFields := False;
     except
       FDoNotBindFields := False;
       // disconnect query from the table
       inherited InternalClose;
       raise;
     end;
     // set projection
     if (ResultTable.FProjectionFieldList.Count > 0) then
      SetProjection(ResultTable.FProjectionFieldList, ResultTable.FProjectionAliasList);

     UnfreezeVisibleRecords;
    finally
     FDatabaseName := OldDatabaseName;
     FDatabaseFileName := OldDatabaseFileName;
     FInMemory := OldInMemory;
    end;
   except
    UnfreezeVisibleRecords;
    FSQLProcessor.Free;
    FSQLProcessor := nil;
    raise;
   end;
  end;
end; //InternalOpen


//------------------------------------------------------------------------------
// closes query
//------------------------------------------------------------------------------
procedure TEasyQuery.InternalClose;
begin
 if (FSQLProcessor <> nil) then
  FSQLProcessor.Free;
 FSQLProcessor := nil;
 SetSQLFilter(nil);
 inherited InternalClose;
 DeleteTemporaryTable;
end;// TEasyQuery.InternalClose


//------------------------------------------------------------------------------
// creates query
//------------------------------------------------------------------------------
constructor TEasyQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  // CB bug fixes
  FSQL2 := TStringList.Create;
  FSQL3 := TStringList.Create;
  FSQL4 := TStringList.Create;
  FSQL5 := nil;
  TStringList(SQL).OnChange := QueryChanged;
  TStringList(FSQL4).OnChange := QueryChanged;
  FParams  := TParams.Create(Self);
  FDataLink := TEasyQueryDataLink.Create(Self);
  RequestLive := False;
  FParamCheck := True;
  // CB bug fixes
  FParamCheck2 := True;
  FRowsAffected := -1;
  FSQLProcessor := nil;
end; //Create


//------------------------------------------------------------------------------
// destroys query
//------------------------------------------------------------------------------
destructor TEasyQuery.Destroy;
begin
  Destroying;
  Active := false;
  FSQL.Free;
  FSQL2.Free;
  FSQL3.Free;
  FSQL4.Free;
  FParams.Free;
  FDataLink.Free;
  StrDispose(SQLBinary);
  inherited Destroy;
end; //Destroy


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TEasyQuery.ExecSQL;
begin
  // get handle to database manager (find or create)
  SetDBFlag(dbfExecSQL, True);
  try
    // CB bug fix
    if (FSQL.Text <> '') then
     FText := FSQL.Text
    else
     FText := FSQL4.Text;

    // prepare params
    if FDataLink.DataSource <> nil then SetParamsFromCursor;

    FSQLProcessor := TSQLScriptProcessor.Create(FText, FParams);
    try
      FSQLProcessor.ExecSQL(Self);
    finally
      FSQLProcessor.Free;
      FSQLProcessor := nil;
    end;
  finally
    SetDBFlag(dbfExecSQL, False);
  end;
end;  //ExecSQL


{$IFDEF D21H}
//------------------------------------------------------------------------------
// get master-detail links
//------------------------------------------------------------------------------
procedure TEasyQuery.GetDetailLinkFields(MasterFields, DetailFields: TList<TField>);

  function AddFieldToList(const FieldName: AnsiString; DataSet: TDataSet;
    List: TList<TField>): Boolean;
  var
    Field: TField;
  begin
    Field := DataSet.FindField(FieldName);
    if (Field <> nil) then
      List.Add(Field);
    Result := Field <> nil;
  end;

var
  i: Integer;
begin
  MasterFields.Clear;
  DetailFields.Clear;
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then
    for i := 0 to Params.Count - 1 do
      if AddFieldToList(Params[i].Name, DataSource.DataSet, MasterFields) then
        AddFieldToList(Params[i].Name, Self, DetailFields);
end;// GetDetailLinkFields
{$ELSE}
//------------------------------------------------------------------------------
// get master-detail links
//------------------------------------------------------------------------------
procedure TEasyQuery.GetDetailLinkFields(MasterFields, DetailFields: TList);

  function AddFieldToList(const FieldName: AnsiString; DataSet: TDataSet;
    List: TList): Boolean;
  var
    Field: TField;
  begin
    Field := DataSet.FindField(FieldName);
    if (Field <> nil) then
      List.Add(Field);
    Result := Field <> nil;
  end;

var
  i: Integer;
begin
  MasterFields.Clear;
  DetailFields.Clear;
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then
    for i := 0 to Params.Count - 1 do
      if AddFieldToList(Params[i].Name, DataSource.DataSet, MasterFields) then
        AddFieldToList(Params[i].Name, Self, DetailFields);
end;// GetDetailLinkFields
{$ENDIF}


//------------------------------------------------------------------------------
// gets param by name
//------------------------------------------------------------------------------
function TEasyQuery.ParamByName(const Value: AnsiString): TParam;
begin
  Result := FParams.ParamByName(Value);
end;// ParamByName


//------------------------------------------------------------------------------
// opens dataset as table
//------------------------------------------------------------------------------
procedure TEasyQuery.InternalOpenAsTable;
begin
 inherited InternalOpen;
end;// InternalOpenAsTable


//------------------------------------------------------------------------------
// closes dataset as table
//------------------------------------------------------------------------------
procedure TEasyQuery.InternalCloseAsTable;
begin
 inherited InternalClose;
end;// InternalCloseAsTable
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TEasyDatabase
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// creates databases with specified directory
//------------------------------------------------------------------------------
constructor TEasyDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if (FSession=nil) then
    begin
      if (AOwner is TEasySession) then
        FSession:=TEasySession(AOwner)
      else
        FSession:=ETblDefaultSession;
    end;
  SessionName:=FSession.SessionName;
  FSession.AddDatabase(Self);
  FDataSets:=TList.Create;
  FKeepConnection:=True;
  if (not bDesignMode) then
   if (Aowner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
     bDesignMode := true;
  FHandle := nil; // no manager
  FDatabaseFileMode := dfmNormal;
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyDatabase.Destroy;
begin
  Destroying;
  Close;
  FDataSets.Free;
  if (FSession <> nil) then
     FSession.RemoveDatabase(Self);
  inherited Destroy;
end;//Destroy


//------------------------------------------------------------------------------
// create ESFS file
//------------------------------------------------------------------------------
procedure TEasyDatabase.CreateDatabase;
begin
  if (FDatabaseFileName = '') then
   raise Exception.Create('DatabaseFileName property is blank.');

  if (Connected) then
   raise Exception.Create('CreateDatabase error. Database is connected.');

  CreateHandle;
  try
   FHandle.CreateDatabase;
  finally
   DestroyHandle;
  end;
end;// CreateDatabase


//------------------------------------------------------------------------------
// CreateDatabase with parameter
//------------------------------------------------------------------------------
procedure TEasyDatabase.CreateDatabase(NewDatabaseFileName: AnsiString);
begin
  FDatabaseFileName := NewDatabaseFileName;
  CreateDatabase;
end;// CreateDatabase


//------------------------------------------------------------------------------
// delete ESFS files
//------------------------------------------------------------------------------
procedure TEasyDatabase.DeleteDatabase;
begin
  if (FDatabaseFileName = '') then
   raise Exception.Create('DatabaseFileName property is blank.');

  if (Connected) then
   raise Exception.Create('DeleteDatabase error. Database is connected.');

  CreateHandle;
  try
   FHandle.DeleteDatabase;
  finally
   DestroyHandle;
  end;
end;// DeleteDatabase


//------------------------------------------------------------------------------
// Compact progress
//------------------------------------------------------------------------------
procedure TEasyDatabase.CompactProgress(
                             Sender      : TObject;
                             PercentDone : Real;
                             var Cancel: Boolean
                            );
begin
 FCancel := Cancel;
 DoOnProgress(PercentDone,aappCompactDB);
 Cancel := FCancel;
end;


//------------------------------------------------------------------------------
// compact ESFS file
//------------------------------------------------------------------------------
function TEasyDatabase.CompactDatabase(var log: AnsiString): Boolean;
var
  PFSHandle: TESFSPlainFileSystem;
  ronly: boolean;
begin
  log := '';
  result := true;
  FCancel := false;
  if (FDatabaseFileName = '') then
   raise Exception.Create('TEasyDatabase.CompactDatabase - DatabaseFileName property is blank.');
  if (Connected) then
   raise Exception.Create('TEasyDatabase.CompactDatabase -  Database is connected.');
  DoOnProgress(0,aappCompactDB);

  CreateHandle;
  try
    if (FHandle <> nil) then
     if (not FHandle.bDatabaseFile)then
       Exit;
     if (FHandle.DataSetList.Count > 0) then
      raise Exception.Create('TEasyDatabase.CompactDatabase - Some datasets are connected.');
     // if ESFS is closed - open it
     ronly := false;
     PFSHandle := TESFSPlainFileSystem(PFSManager.GetPFSHandle(DatabaseFileName, FPassword, fsmESFS, ronly, InMemory));
     if (PFSHandle = nil) then
      if (Encrypted) then
       raise Exception.Create('TEasyDatabase.CompactDatabase - Invalid password.')
      else
       raise Exception.Create('TEasyDatabase.CompactDatabase - PFSHandle = nil.');
     PFSHandle.ESFSHandle.OnProgress := CompactProgress;
     result := PFSHandle.ESFSHandle.Repair(log, false);
    DoOnProgress(100.0,aappCompactDB);
    if (FCancel) then
     begin
      result := false;
      log := log + #13#10 +'CompactDatabase cancelled. Original database file restored.';
     end;
  finally
    DestroyHandle;
  end;
end;


//------------------------------------------------------------------------------
// Repair progress
//------------------------------------------------------------------------------
procedure TEasyDatabase.RepairProgress(
                             Sender      : TObject;
                             PercentDone : Real;
                             var Cancel: Boolean
                            );
begin
 FCancel := Cancel;
 DoOnProgress(PercentDone/2,aappRepairDB);
 Cancel := FCancel;
end;


//------------------------------------------------------------------------------
// Progress - change encryption of ESFS file
//------------------------------------------------------------------------------
procedure TEasyDatabase.ChangeEncryptionProgress(
                             Sender      : TObject;
                             PercentDone : Real;
                             var Cancel: Boolean
                            );
begin
 FCancel := Cancel;
 DoOnProgress(PercentDone,aappChangeEncryptionDB);
 Cancel := FCancel;
end;


//------------------------------------------------------------------------------
// repair ESFS file
//------------------------------------------------------------------------------
function TEasyDatabase.RepairDatabase(var log: AnsiString; DeleteCorruptedFiles: Boolean = false): Boolean;
label m0,m1;
var
  PFSHandle: TESFSPlainFileSystem;
  ronly: boolean;
  i: integer;
  list: TStringList;
  FProgress:	Extended;
  FProgressMax:Extended;
  tempTable:	TEasyTable;
  s:					AnsiString;
begin
  log := '';
  result := true;
  FCancel := false;
  tempTable := nil;
  list := nil;
  try
   if (Connected) then
    raise Exception.Create('TEasyDatabase.RepairDatabase -  Database is connected.');
   DoOnProgress(0,aappRepairDB);

   // get DBM handle
   CreateHandle;

   try
     // not ESFS repair
     if (FDatabaseFileName = '') then
       begin
        // repairing tables
        list := TStringList.Create;
        tempTable := TEasyTable.Create(nil);
        tempTable.DatabaseName := FDirectory;
        tempTable.GetTableNameList(list);
        goto m0;
       end;

     if (not FHandle.bDatabaseFile) then
      Exit;

     if (FHandle.DataSetList.Count > 0) then
      raise Exception.Create('TEasyDatabase.RepairDatabase - Some datasets are connected.');
     // if ESFS is closed - open it
     ronly := false;
     PFSHandle := TESFSPlainFileSystem(PFSManager.GetPFSHandle(DatabaseFileName, FPassword, fsmESFS, ronly, InMemory));
     if (PFSHandle = nil) then
      if (Encrypted) then
       raise Exception.Create('TEasyDatabase.RepairDatabase - Invalid password.')
      else
       raise Exception.Create('TEasyDatabase.RepairDatabase -  PFSHandle = nil.');
     PFSHandle.ESFSHandle.OnProgress := RepairProgress;
     result := PFSHandle.ESFSHandle.Repair(log, DeleteCorruptedFiles);
     DoOnProgress(50.0,aappRepairDB);
     // repairing tables
     list := TStringList.Create;
     tempTable := TEasyTable.Create(nil);
//     tempTable.DatabaseFileName := DatabaseFileName;
     tempTable.DatabaseName := Self.FDatabaseName;
     tempTable.GetTableNameList(list);
  m0:
   for i := 0 to list.Count-1 do
    begin
     if (FCancel) then
      break;
     tempTable.TableName := list.Strings[i];
     if (tempTable.Exists) then
      begin
       if (tempTable.IsTableEncrypted) then
        begin
         tempTable.DMHandle := TEasyDataManager.Create(tempTable.TableName, FHandle);
  m1:
         s := tempTable.TableName;
         s := AnsiQuotedStr(s,'"');
         if (PasswordDialog(tempTable.DMHandle,s)) then
          begin
           tempTable.Password := tempTable.DMHandle.FPassword;
           if (not tempTable.DMHandle.TryToOpenEncryptedTable) then
               goto m1;
          end
         else
          begin
           FCancel := true;
           tempTable.DMHandle.Free;
           break;
          end;
         tempTable.DMHandle.Free;
        end; // encrypted

       if (not tempTable.RepairTable(s)) then
        begin
         if (DeleteCorruptedFiles) then
          begin
           tempTable.DeleteTable;
           log := log + 'Table "'+tempTable.TableName+'" repaired with errors. Error log:'+
              #13#10 + s +#13#10+'Table deleted.'+#13#10;
          end
         else
          log := log + 'Table "'+tempTable.TableName+'" repaired with errors. Error log:'+
              #13#10 + s +#13#10;
        end;
      end;
     FProgressMax := list.Count;
     FProgress := i+1;
     FProgress := 50.0 + FProgress / FProgressMax * 50.0;
     DoOnProgress(FProgress,aappRepairDB);
    end;
   finally
    // finalization
    tempTable.Free;
    list.Free;
   end;
   DoOnProgress(100.0,aappRepairDB);
   if (FCancel) then
    begin
     result := false;
     log := log + #13#10 +'RepairDatabase cancelled. Original database file restored.';
    end;
  finally
   DestroyHandle;
  end;
end;// RepairDatabase


//------------------------------------------------------------------------------
// rename ESFS file
//------------------------------------------------------------------------------
function TEasyDatabase.RenameDatabase(const NewDatabaseName: AnsiString): Boolean;
begin
  if (FDatabaseFileName = '') then
   raise Exception.Create('DatabaseFileName property is blank.');

  if (Connected) then
   raise Exception.Create('RenameDatabase error. Database is connected.');

  if (FInMemory) then
   raise Exception.Create('Cannot rename in-memory database. Only disk database can be renamed.');

  CreateHandle;
  try
    result := FHandle.RenameDatabase(NewDatabaseName);
  finally
    DestroyHandle;
  end;
  if (result) then
   FDatabaseFileName := ExtractFilePath(FDatabaseFileName)+
                        ExtractFileName(NewDatabaseName);
end;// RenameDatabase


//------------------------------------------------------------------------------
// copy ESFS file
//------------------------------------------------------------------------------
function TEasyDatabase.CopyDatabase(const NewDatabaseName: AnsiString): Boolean;
var
  bConnected: boolean;
begin
  if (FDatabaseFileName = '') then
   raise Exception.Create('DatabaseFileName property is blank.');

  bConnected := Connected;
  if (not bConnected) then
   CreateHandle;

  try
    result := FHandle.CopyDatabase(NewDatabaseName);
  finally
   if (not bConnected) then
    DestroyHandle;
  end;
end;// CopyDatabase


//------------------------------------------------------------------------------
// sets new encryption mode
// if newPassword = '' then encryption will be removed
//------------------------------------------------------------------------------
function TEasyDatabase.ChangeEncryption(newPassword: AnsiString = ''):Boolean;
var
  bConnected: Boolean;
  PFSHandle: TESFSPlainFileSystem;
begin
  if (newPassword = FPassword) then
   begin
    result := true;
    Exit;
   end;

  if (FDatabaseFileName = '') then
   raise Exception.Create('TEasyDatabase.ChangeEncryption - DatabaseFileName property is blank.');
  bConnected := Connected;
  if (Connected) then
   Connected := false;
  FCancel := false;
  PFSHandle := TESFSPlainFileSystem(PFSManager.GetPFSHandle(DatabaseFileName, FPassword, fsmESFS, FReadOnly, FInMemory));
  PFSHandle.ESFSHandle.OnProgress := ChangeEncryptionProgress;
  DoOnProgress(0,aappChangeEncryptionDB);
  result := PFSHandle.ESFSHandle.ChangeEncryption(newPassword);
  DoOnProgress(100,aappChangeEncryptionDB);
  Connected := bConnected;
  if (result) then
   FPassword := newPassword;
end;


//------------------------------------------------------------------------------
// connected := true
//------------------------------------------------------------------------------
procedure TEasyDatabase.Open;
var
  bCatchException: Boolean;
begin
  if (FHandle=nil) then
   begin
    bCatchException := False;
{$IFDEF D6H}
     // fix: to enable open forms with incorrect properties
     if (csDesigning in ComponentState)
       and (not (csFreeNotification in ComponentState)) then
      bCatchException := True;
{$ENDIF}
    try
     CheckDatabaseName;
     CheckSessionName(True);

     if not (HandleShared and OpenFromExistingDB) then
       begin
         FSession.LockSession;
         try
           try
             if aaIsDirectory(FDatabaseName) then
               FDirectory := FDatabaseName;

             // directory or file?
             if (FDirectory <> '') then
              begin
               if (not DirectoryExists(FDirectory)) then
                raise Exception.Create('TEasyDatabase.Open - Directory "'+
                                        FDirectory+'" doesn''t exist.');
               CreateHandle;
              end
             else
             if (FDatabaseFileName <> '') then
              begin
                if (not FInMemory) then
                 begin
                  if (not FileExists(FDatabaseFileName)) then
                   if (not bDesignMode) then
                    CreateDatabase(FDatabaseFileName);
                 end
                else
                 // create in-memory database?
                 if (not Exists) then
                  CreateDatabase(FDatabaseFileName);

                CreateHandle;
                // if not encrypted then empty password
                if (not Encrypted) then
                 FPassword := '';
                if (FHandle.GetPFSHandle(fsmESFS) = nil) then
                 begin
                  DestroyHandle;
                  raise Exception.Create('TEasyDatabase.Open - Invalid password or corrupted database file.')
                 end
                else
                 if (bDesignMode) then
                   FHandle.CloseESFSFile;
              end
             else
              CreateHandle;
             // send notification
             Session.DBNotification(dbOpen,Self);
           except
             raise;
           end;
         finally
           FSession.UnlockSession;
         end;
       end
      else
        FAcquiredHandle:=False;
    except
     if (not bCatchException) then
      raise;
    end;
   end;
end;// Open


//------------------------------------------------------------------------------
// connected := false
//------------------------------------------------------------------------------
procedure TEasyDatabase.Close;
begin
  if (FHandle <> nil) then
    begin
      Session.DBNotification(dbClose,Self);
      CloseDataSets;
      if (not FAcquiredHandle) then
        begin
         if (FHandle <> nil) then
           DestroyHandle;
        end
      else
        FAcquiredHandle:=False;
      FHandle:=nil;
      FRefCount:=0;
    end;
end;// Close


//------------------------------------------------------------------------------
// close all datasets
//------------------------------------------------------------------------------
procedure TEasyDatabase.CloseDataSets;
begin
  while DataSetCount <> 0 do
   TEasyDataSet(DataSets[DataSetCount-1]).Disconnect;
end;// CloseDataSets


//------------------------------------------------------------------------------
// get list of tables in database file
//------------------------------------------------------------------------------
procedure TEasyDatabase.GetTablesList(List: TStrings);
begin
  if (not Connected) then
   Connected := True;
  if (Assigned(FHandle)) then
   FHandle.GetNonTempTablesList(List);
end;// GetTablesList


//------------------------------------------------------------------------------
// determine if table exists
//------------------------------------------------------------------------------
function TEasyDatabase.TableExists(TableName: AnsiString) : Boolean;
var
  FEasyDataSet: TEasyDataset;
  OldConnected: Boolean;
begin
  OldConnected := Connected;
  FEasyDataSet := TEasyDataset.Create(self);
  try
   FEasyDataSet.DatabaseFileName := self.FDatabaseFileName;
   FEasyDataSet.DatabaseName := self.FDatabaseName;
   FEasyDataSet.SessionName := self.FSessionName;
   FEasyDataSet.SetTableName(TableName);
   Result := FEasyDataSet.Exists;
  finally
   FEasyDataSet.Free;
   Connected := OldConnected;
  end;
end;// TableExists


//------------------------------------------------------------------------------
// deletes table
//------------------------------------------------------------------------------
procedure TEasyDatabase.DeleteTable(TableName: AnsiString);
var
  FEasyTable: TEasyTable;
  OldConnected: Boolean;
begin
  FEasyTable := TEasyTable.Create(self);
  OldConnected := Connected;
  try
   FEasyTable.DatabaseFileName := self.FDatabaseFileName;
   FEasyTable.SetTableName(TableName);
   FEasyTable.DeleteTable;
  finally
   FEasyTable.Free;
   Connected := OldConnected;
  end;
end;


//------------------------------------------------------------------------------
// makes Exe database from edb file
//------------------------------------------------------------------------------
procedure TEasyDatabase.MakeExeDatabase(ExeFileName, ExeDatabaseFileName: AnsiString);
begin
 ESingleFileSystem.MakeSFX(DatabaseFileName,ExeFileName,ExeDatabaseFileName);
end;// MakeSFX


//------------------------------------------------------------------------------
// returns true if this file is an EasyTable database
//------------------------------------------------------------------------------
function TEasyDatabase.IsEasyTableDatabaseFile(FileName: AnsiString): Boolean;
begin
  result := IsESFSFile(FileName);
end;// MakeSFX


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetConnected(value: boolean);
begin
  if (csReading in ComponentState) then
    FStreamedConnected:=Value
  else
   begin
    if Value = GetConnected then
     Exit;
    if Value then
     Open
    else
     Close;
   end;
end;//SetConnected


//------------------------------------------------------------------------------
// set specified database name
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetDatabaseName(Value: AnsiString);
begin
  if csReading in ComponentState then
    FDatabaseName := Value
  else
  if FDatabaseName <> Value then
   begin
    CheckInactive;
    ValidateName(Value);
    FDatabaseName := Value;
   end;
end;//SetDatabaseName


//------------------------------------------------------------------------------
// sets handle
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetHandle(Value: TEasyDatabaseManager);
var
  DBSession: TEasySessionManager;
begin
   if Connected then
      Close;
   if (Value <> nil) then
     begin
      DBSession:=Value.SMHandle;
      CheckDatabaseName;
      CheckSessionName(True);
      // database handle owned by another session
      if (FSession.FHandle <> DBSession) then
        raise ETblException.Create(01084, Self);
      FHandle:=Value;
      Session.DBNotification(dbOpen,Self);
      FAcquiredHandle:=True;
     end;
end;// SetHandle


//------------------------------------------------------------------------------
// set specified directory
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetDirectory(dir: AnsiString);
begin
  if FDirectory <> dir then
   begin
    CheckInactive;
    if (dir <> '') then
     FDatabaseFileName := ''; // Directory and DatabaseFileName are mutually exclusive
    FDirectory := dir;
   end;
end;//SetDirectory


//------------------------------------------------------------------------------
// set specified file name
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetDatabaseFileName(Value: AnsiString);
begin
  if csReading in ComponentState then
    FDatabaseFileName := Value
  else
  if FDatabaseFileName <> Value then
   begin
//    CheckInactive;
    Connected := False;
    FDatabaseFileName := Value;
    if (Value <> '') then
     Directory := ''; // Directory and DatabaseFileName are mutually exclusive
   end;
end;// SetDatabaseFileName


//------------------------------------------------------------------------------
// in memory mode
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetInMemory(Value: Boolean);
begin
  if csReading in ComponentState then
    FInMemory := Value
  else
  if FInMemory <> Value then
   begin
    CheckInactive;
    FInMemory := Value;
   end;
end;// SetInMemory


//------------------------------------------------------------------------------
// is database file encrypted
//------------------------------------------------------------------------------
function TEasyDatabase.GetEncrypted: boolean;
var
 PFSHandle: TESFSPlainFileSystem;
begin
  result := false;
  if (Connected) then
   begin
    if (FDatabaseFileName <> '') then
     begin
       PFSHandle := TESFSPlainFileSystem(PFSManager.FindPFS(FDatabaseFileName, fsmESFS, FInMemory));
       if (PFSHandle <> nil) then
         result := PFSHandle.ESFSHandle.Encrypted
       else
        if (SysUtils.FileExists(FDatabaseFileName)) then
         Result := IsSingleFileEncrypted(FDatabaseFileName);
     end;
   end
  else
   begin
    if (SysUtils.FileExists(FDatabaseFileName)) then
     Result := IsSingleFileEncrypted(FDatabaseFileName);
   end;
end;// GetEncrypted


//------------------------------------------------------------------------------
// is database file exists
//------------------------------------------------------------------------------
function TEasyDatabase.GetExists: boolean;
begin
  if (Connected) then
    Result := FHandle.Exists
  else
    if (FDatabaseFileName <> '') then
      if (FInMemory) then
       Result := (PFSManager.FindPFS(FDatabaseFileName, fsmESFS, FInMemory) <> nil)
      else
       Result := SysUtils.FileExists(FDatabaseFileName)
    else
     Result := DirectoryExists(FDirectory);
end;// GetExists


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TEasyDatabase.DoOnProgress(Progress : Real; FProgressProcess: TaaProgressProcess);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress,FProgressProcess,FCancel);
end;


//------------------------------------------------------------------------------
// get database manager
//------------------------------------------------------------------------------
procedure TEasyDatabase.CreateHandle;
begin
  ETblEnterCriticalSection(FDBMLockSection);
  try
   FHandle := aaGetDatabaseManager(Self);
   FHandle.ConnectDatabase(Self);
 //  if (FHandle.DatabaseList.Count = 1) then
   FAcquiredHandle := False;
  finally
   ETblLeaveCriticalSection(FDBMLockSection);
  end;
end;// CreateHandle


//------------------------------------------------------------------------------
// release database manager
//------------------------------------------------------------------------------
procedure TEasyDatabase.DestroyHandle;
begin
  ETblEnterCriticalSection(FDBMLockSection);
  try
   if (Assigned(FHandle)) then
    FHandle.DisconnectDatabase(Self);
   FHandle := nil;
 finally
  ETblLeaveCriticalSection(FDBMLockSection);
 end;
end;// DestroyHandle


{$IFNDEF ENCRYPTION_ON}
//------------------------------------------------------------------------------
// set password
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetPassword(Value: AnsiString);
begin
  FPassword := '';
end; // SetPassword
{$ENDIF}


//------------------------------------------------------------------------------
// loaded
//------------------------------------------------------------------------------
procedure TEasyDatabase.Loaded;
begin
  inherited Loaded;
  if FStreamedConnected then
    Open
  else
    CheckSessionName(False);
end;// Loaded


//------------------------------------------------------------------------------
// sends notification
//------------------------------------------------------------------------------
procedure TEasyDatabase.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);
  if (Operation = opRemove) and (AComponent = FSession) and
     (FSession <> ETblDefaultSession) then
    begin
      Close;
      SessionName := '';
    end;
end;// Notification


//------------------------------------------------------------------------------
// keep connection
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetKeepConnection(Value: Boolean);
begin
  if FKeepConnection <> Value then
  begin
    FKeepConnection := Value;
    if not Value and (FRefCount = 0) then
     Close;
  end;
end;// SetKeepConnection


//------------------------------------------------------------------------------
// sets read-only mode
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetReadOnly(Value: Boolean);
begin
//  CheckInactive;
  FReadOnly := Value;
end;// SetReadOnly


//------------------------------------------------------------------------------
// set session name
//------------------------------------------------------------------------------
procedure TEasyDatabase.SetSessionName(const Value: AnsiString);
begin
  if csReading in ComponentState then
    FSessionName := Value
  else
  begin
    CheckInactive;
    if FSessionName <> Value then
    begin
      FSessionName := Value;
      if not (csDestroying in ComponentState) then
        CheckSessionName(False);
    end;
  end;
end;// SetSessionName


//------------------------------------------------------------------------------
// checks session name
//------------------------------------------------------------------------------
procedure TEasyDatabase.CheckSessionName(Required: Boolean);
var
  NewSession: TEasySession;
begin
  if Required then
    NewSession := Sessions.List[FSessionName]
  else
    NewSession := Sessions.FindSession(FSessionName);
  if (NewSession <> nil) and (NewSession <> FSession) then
  begin
    if (FSession <> nil) then FSession.RemoveDatabase(Self);
    FSession := NewSession;
    FSession.FreeNotification(Self);
    FSession.AddDatabase(Self);
    try
      ValidateName(FDatabaseName);
    except
      FDatabaseName := '';
      raise;
    end;
  end;
  if Required then FSession.Active := True;
end;// CheckSessionName


//------------------------------------------------------------------------------
// db connected?
//------------------------------------------------------------------------------
function TEasyDatabase.GetConnected: Boolean;
begin
  Result := (FHandle <> nil);
end;// GetConnected


//------------------------------------------------------------------------------
// connected dataset
//------------------------------------------------------------------------------
function TEasyDatabase.GetDataSet(Index: Integer): TEasyDataSet;
begin
  Result := FDataSets[Index];
end;// GetDataSet


//------------------------------------------------------------------------------
// count of connected datasets
//------------------------------------------------------------------------------
function TEasyDatabase.GetDataSetCount: Integer;
begin
  Result := FDataSets.Count;
end;// GetDataSetCount


//------------------------------------------------------------------------------
// opens from existing DB
//------------------------------------------------------------------------------
function TEasyDatabase.OpenFromExistingDB: Boolean;
begin
  FHandle := FSession.FindDatabaseHandle(DatabaseName);
  Result := (FHandle <> nil);
  FAcquiredHandle := Result;
end;// OpenFromExistingDB


//------------------------------------------------------------------------------
// validates name
//------------------------------------------------------------------------------
procedure TEasyDatabase.ValidateName(const Name: AnsiString);
var
  Database: TEasyDatabase;
begin
  if (Name <> '') and (FSession <> nil) then
  begin
    Database := FSession.FindDatabase(Name, DatabaseFileName);
    if (Database <> nil) and (Database <> Self) and
      not (Database.HandleShared and HandleShared) then
    begin
      if not Database.Temporary or (Database.FRefCount <> 0) then
       raise ETblException.Create(01080, [Name], Self);
      Database.Free;
    end;
  end;
end;// ValidateName


//------------------------------------------------------------------------------
// raises exception if not active
//------------------------------------------------------------------------------
procedure TEasyDatabase.CheckInactive;
begin
  if FHandle <> nil then
    if csDesigning in ComponentState then
      Close
    else
      raise ETblException.Create(01080, Self);
end;// CheckInactive


//------------------------------------------------------------------------------
// raises exception if database name is not valid
//------------------------------------------------------------------------------
procedure TEasyDatabase.CheckDatabaseName;
begin
 if (FDatabaseName = '') and not Temporary then
    raise ETblException.Create(01081, Self);
end;// CheckDatabaseName




//------------------------------------------------------------------------------
// this function detects string params, separated by [' ',',',';']
// and put this params in paramList
// Example : params = 'param1, param2;param3 param4'
//           paramList = ['param1','param2','param3','param4']
//------------------------------------------------------------------------------
function GetStringParams(
         params : AnsiString; // source params
         paramList : TStringList // result param list
        ) : Integer; // returns number of detected string parameters
var i,j,n   : integer;
    charSet : set of AnsiChar;
    sym     : AnsiChar;
    flag    : Boolean;
begin
 result := 0;
 if (Length(params) <= 0) then Exit;
 i := 1;
 j := 1;
 n := 0;
 flag := false;
 charSet := [',',';'];
 while (i <= Length(params)) do
  begin
   sym := params[i];
   if ((not flag) and (sym in charSet)) then
    begin
     flag := true;
     paramList.Add(Trim(Copy(params,j,i-j)));
     inc(n);
    end;
   if ((flag) and (not (sym in charSet))) then
    begin
     flag := false;
     j := i;
    end;
   inc(i);
  end;
 if ((j <= Length(params)) and (not flag)) then
  begin
   inc(n);
   paramList.Add(Trim(Copy(params,j,Length(params)-j+1)));
  end;
 if (n <= 0) then
  begin
   n := 1;
   paramList.Clear;
   paramList.Add(params);
  end;

 result := n;
end; // GetStringParams


//------------------------------------------------------------------------------
// checks for graphic
//------------------------------------------------------------------------------
function isStreamGraphic (stream : TStream) : Boolean;
var
      buf : PAnsiChar;
begin
 buf := AllocMem(10);
   if (buf = nil)  then raise Exception.Create(
    'Error in TEasyDataManager.IsStreamGraphic - buf 0 pointer.');
 try
   stream.Seek(0,soFromBeginning);
   if (stream.Size >= 10) then
    begin
     stream.ReadBuffer(buf^,10);
     result := true;
     if (buf[0] <> #01) then
      result := false
     else
     if (buf[1] <> #00) then
      result := false
     else
     if (buf[2] <> #00) then
      result := false
     else
     if (buf[3] <> #01) then
      result := false
     else
     if (buf[8] <> 'B') then
      result := false
     else
     if (buf[9] <> 'M') then
      result := false;
     stream.Seek(0,soFromBeginning);
    end
   else
    result := false;
 finally
   FreeMem(buf);
 end;
end; //isStreamGraphic (stream : TStream) : Boolean;


//------------------------------------------------------------------------------
// returns true if field exists
//------------------------------------------------------------------------------
function FindFieldInSourceTable(fieldDefinitions : TFieldDefs; name : AnsiString) : Boolean;
var ii : integer;
    ff : Boolean;
begin
    ff := false;
    for ii := 0 to fieldDefinitions.Count -1 do
     if (LowerCase(fieldDefinitions.Items[ii].Name) = LowerCase(name)) then
      begin
        ff := true;
        break;
      end;
     result := ff;
end; // FindFieldInSourceTable


  function DateTimeToNative(DataType: TFieldType; Data: TDateTime): TDateTimeRec;
  var
    TimeStamp: TTimeStamp;
  begin
    TimeStamp := DateTimeToTimeStamp(Data);
    case DataType of
      ftDate: Result.Date := TimeStamp.Date;
      ftTime: Result.Time := TimeStamp.Time;
    else
      Result.DateTime := TimeStampToMSecs(TimeStamp);
    end;
  end;

// returns true if field type is blob
function IsBLOBFieldType(FieldType: TFieldType): Boolean;
begin
 result := false;
 case (FieldType) of
  ftGraphic,ftBLOB,ftMemo,ftFmtMemo: result := true;
 end;
end;

// returns true if fields of this type could be indexed
function IsFieldTypeCanCompriseIndex(FieldType: TFieldType): Boolean;
begin
 result := false;
 case FieldType of
        ftSmallInt,
        ftInteger,
        ftWord,
        ftLargeInt,
        ftBoolean,
        ftFloat,
        ftBCD,
        ftCurrency,
        ftString,
        ftWideString,
        ftDateTime, ftTime, ftDate: result := true;
 end;
end;

{$IFDEF NAG_SCREEN}
var i: integer;
    WindowLst: TStringList;
    IsIDERunning: boolean;
    IsDelphiOrBuilderInstalled: boolean;
    capt, msg: String;
    Reg: TRegistry;
{$ENDIF}

initialization
  Sessions:=TEasySessionList.Create;
  Session:=TEasySession.Create(nil);
  Session.SessionName := 'Default';
  // DB manager
  FDBMLockSection := ETblAllocCriticalSection;
  ETblInitializeCriticalSection(FDBMLockSection);
  // Data manager
  FDMLockSection := ETblAllocCriticalSection;
  ETblInitializeCriticalSection(FDMLockSection);

  bDesignMode := false;
  DatabaseManagerList := TList.Create;
//  DatabaseList := TList.Create;
  DataManagerList := TList.Create;
  PFSManager := TPFSManager.Create;
  {$IFDEF NAG_SCREEN}
  WindowLst := TStringList.Create;
  EnumWindows(@EasyDataManagerWindowCallback,Longint(@WindowLst));
  // IDE detection
  IsIDERunning := false;
  for i:=0 to WindowLst.Count-1 do
    if ((Pos('Delphi',WindowLst[i]) = 1) or
        (Pos('Borland',WindowLst[i]) > 0) or
        (Pos('Embarcadero',WindowLst[i]) > 0) or
        (Pos('RAD Studio',WindowLst[i]) > 0) or
        (Pos('CodeGear',WindowLst[i]) > 0) or
        (Pos('Highlander',WindowLst[i]) > 0) or
        (Pos('C++Builder',WindowLst[i]) = 1)) then
      begin
       IsIDERunning := true;
       break;
      end;
  // Delphi/Builder installation detection
  Reg:=TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  if ((Reg.KeyExists('\Software\Borland\Delphi')) or
      (Reg.KeyExists('\Software\Borland\BDS')) or
      (Reg.KeyExists('\Software\Embarcadero\BDS')) or
      (Reg.KeyExists('\Software\Codegear\BDS')) or
      (Reg.KeyExists('\Software\Borland\C++Builder'))) then
    IsDelphiOrBuilderInstalled := true
  else
    IsDelphiOrBuilderInstalled := false;
  Reg.Free;
  // nag screen
  if ((not IsIDERunning) or (not IsDelphiOrBuilderInstalled)) then
     begin
capt := 'EasyTable Trial -  v.'+FormatFloat('0.00',internalCurrentVersion);
msg :=             'This is the full functional trial version of EasyTable by'#13+
             'AidAim Software (c) 2000-2025.'#13#13+
						 'This screen is created to remind you that your free version is'#13+
             'provided to you for evaluation purposes only.'#13+
             'If you don''t want to see this screen any more, or if you intend'#13+
             'to create a commercial product, please, register and download'#13+
             'the appropriate version of this component at https://aidaim.com'#13+
             'Also visit our site for all the new versions of our products.'#13#13+
             'Should you have any questions or problems with our product,'#13+
             'be sure to contact us at https://aidaim.com/help_osticket/';
	
{$IFDEF D12H}
      MessageBoxW(0,PChar(@msg[1]),PChar(@capt[1]),
{$ELSE}
      MessageBoxA(0,PAnsiChar(@msg[1]),PAnsiChar(@capt[1]),
{$ENDIF}						 
						 MB_OK+MB_ICONINFORMATION+MB_DEFBUTTON1);
     end;
   WindowLst.Free;
  {$ENDIF}

finalization
  Sessions.Free;
  while DataManagerList.Count > 0 do
    TEasyDataManager(DataManagerList.Items[0]).Free;
  while DatabaseManagerList.Count > 0 do
   TEasyDatabaseManager(DatabaseManagerList.Items[0]).Free;
  DatabaseManagerList.Free;
{
  while DatabaseList.Count > 0 do
   TEasyDatabase(DatabaseList.Items[0]).Free;
  DatabaseList.Free;
  }
  ETblDeleteCriticalSection(FDBMLockSection);
  ETblFreeCriticalSection(FDBMLockSection);
  ETblDeleteCriticalSection(FDMLockSection);
  ETblFreeCriticalSection(FDMLockSection);

  DataManagerList.Free;
  PFSManager.Free;
end.

