unit SQLMemLocalEngine;

{$I SQLMemVer.inc}

{$WARNINGS OFF}
{$HINTS OFF}

interface

uses SysUtils, Classes,

// SQLMemTable units

     SQLMemRelationalAlgebra,
     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
     SQLMemExcept,
     SQLMemBase,
     SQLMemBaseEngine,
     {$IFDEF MEMORY_ENGINE}
     SQLMemMemEngine,
     {$ENDIF}
     {$IFDEF TEMPORARY_ENGINE}
     SQLMemTempEngine,
     {$ENDIF}
     {$IFDEF DISK_ENGINE}
     SQLMemDiskEngine,
     {$ENDIF}
{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF}
     SQLMemCompression,
     SQLMemTypes,
     SQLMemSQLProcessor,
     SQLMemExpressions,
     SQLMemConst,
     SQLMemLexer,
     SQLMemVariant,
     SQLMemConverts;


type


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalBLOBStream
//
////////////////////////////////////////////////////////////////////////////////

  // local BLOB stream
  TSQLMemLocalBLOBStream = class (TSQLMemStream)
   private
    FOpenMode:                  TSQLMemBLOBOpenMode;
    FTemporaryStream:           TSQLMemStream;
    FUserBLOBStream:            TSQLMemStream;
    FFieldNo:                   Integer;
    FCursor:                    TSQLMemCursor;
    FPosition:                  Int64;
    FDoNotFreeCompressedStream: Boolean;
   protected
    // sets new size of the stream
    procedure InternalSetSize(const NewSize: Int64);
    // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
   public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint;
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    constructor Create(
                        TemporaryStream: TSQLMemStream;
                        Cursor: TSQLMemCursor;
                        OpenMode: TSQLMemBLOBOpenMode;
                        FieldNo: Integer
                      );
    destructor Destroy; override;
   public
    // blob stream interface
   public
    property Cursor: TSQLMemCursor read FCursor;
    property FieldNo: Integer read FFieldNo;
    property OpenMode: TSQLMemBLOBOpenMode read FOpenMode write FOpenMode;
    property TemporaryStream: TSQLMemStream read FTemporaryStream write FTemporaryStream;
    property UserBLOBStream: TSQLMemStream read FUserBLOBStream write FUserBLOBStream;
    property DoNotFreeCompressedStream: Boolean read FDoNotFreeCompressedStream write FDoNotFreeCompressedStream;
  end; // TSQLMemLocalBLOBtream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalCursor
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemLocalCursor = class (TSQLMemCursor)
   private
    FTableData:                     TSQLMemTableData;
    FDatabaseData:                  TSQLMemDatabaseData;
    FSavedPosition:                 Pointer;
    FSavedRecordBuffer:             TSQLMemRecordBuffer;
    FDoNotCloseTableData:           Boolean;
    FDoNotUnlockTable:              Boolean;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    FSearchCache:                   TSQLMemScanSearchConditionCache;
    FSearchOperation:               TSQLMemLastSearchOperation;
{$ENDIF}
   public
    constructor Create;
    destructor Destroy; override;
    // create table
    procedure CreateTable(
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                         ); override;
    procedure DeleteTable(Cascade: Boolean = false); override;
    procedure EmptyTable; override;
    procedure AddForeignKey(ConstraintDef: TSQLMemConstraintDefForeignKey); override;
    procedure DeleteConstraint(Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean); override;
    procedure RenameTable(NewTableName: WideString); override;
    procedure RenameField(FieldName, NewFieldName: WideString); override;
    procedure UpdateTableDefinitions; override;
   protected
    procedure TryToCopyRecords(NewCursor: TSQLMemLocalCursor; var Log: AnsiString);
   public
    function RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TSQLMemConstraintDefs = nil
                        ): Boolean; override;
    procedure LoadTableFromStream(
                        Stream:               TStream
                       ); override;
    procedure SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TSQLMemCompressionAlgorithm = acaNone;
                        CompressionMode:        Byte = 0;
                        BlockSize:              Integer = 0;
                        SkipCheckIsTableOpened: Boolean = false;
                        DoNotCloseTable:        Boolean = false
                      ); override;
   protected
    function GetDropTableCommand(aTableName: WideString): WideString;
    function GetAutoIncFieldDefinition(FieldDef: TSQLMemFieldDef): WideString;
    function GetBLOBFieldDefinition(FieldDef: TSQLMemFieldDef): WideString;
    function GetFieldDefinition(FieldDef: TSQLMemFieldDef; UseBracketsForNames:  Boolean): WideString;
    procedure GetCreateTableCommand(
                    var TableSQL:         WideString;
                    var TableFKSQL:       WideString;
                    aTableName:           WideString;
                    UseBracketsForNames:  Boolean;
                    ExportForeignKeys:    Boolean
                    );
    function GetCreateIndexCommand(aTableName: WideString; IndexName: WideString; IndexDef: TSQLMemIndexDef; UseBracketsForNames:  Boolean): WideString;
    function GetDropIndexCommand(aTableName: WideString; IndexName: WideString): WideString;
    function GetSQLBLOBFieldValue(FieldNo: Integer): WideString;
    function GetSQLFieldValue(var v: TSQLMemVariant; FieldNo: Integer; ExportBLOBFields: Boolean): WideString;
    function GetInsertCommand(var v: TSQLMemVariant; aTableName: WideString; UseBracketsForNames:  Boolean; ExportBLOBFields: Boolean): WideString;
{ TODO -oLeo : optimize it }
    procedure GetTableSQL(
                              var TableSQL:         WideString;
                              var TableFKSQL:       WideString;
                              ExportStructure:      Boolean;
                              AddDropTableCommand:  Boolean;
                              ExportIndexes:        Boolean;
                              AddDropIndexCommand:  Boolean;
                              ExportData:           Boolean;
                              ExportBLOBFields:     Boolean;
                              UseBracketsForNames:  Boolean;
                              ExportForeignKeys:    Boolean
                          );
   public
    function ExportTableToSQL(
                              ExportStructure:      Boolean;
                              AddDropTableCommand:  Boolean;
                              ExportIndexes:        Boolean;
                              AddDropIndexCommand:  Boolean;
                              ExportData:           Boolean;
                              ExportBLOBFields:     Boolean;
                              UseBracketsForNames:  Boolean;
                              ExportForeignKeys:    Boolean
                            ): WideString; override;
    procedure InternalInitFieldDefs; override;
    procedure OpenTableByFieldDefs(
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                       ); override;
    procedure OpenTable(aTableData: TSQLMemTableData);
    procedure CloseTable; override;

    // index operations
    function GetIndexDefs: TSQLMemIndexDefs; override;
    procedure AddIndex(IndexDef: TSQLMemIndexDef); override;
    procedure DeleteIndex(Name: WideString); override;
    procedure DeleteAllIndexes; override;
    // return index name of the index or '' if not found
    function FindIndex(FieldNamesList, AscDescList,
              CaseSensitivityList: TSQLMemWideStringList): WideString; override;
    function IsTemporaryTable: Boolean; override;
    function IsMemoryTable: Boolean; override;


    //---------------------------------------------------------------------------
    // navigation & bookmark methods
    //---------------------------------------------------------------------------
    // return true if current record exists
    function IsRecordExists: Boolean; override;
    function GetRecordBuffer(
              GetRecordMode:  TSQLMemGetRecordMode
              ): TSQLMemGetRecordResult; override;
    function GetRecordCount: TSQLMemRecordNo; override;
    // go to record
    procedure SetRecNo(Value: TSQLMemRecordNo); override;
    function GetRecNo: TSQLMemRecordNo; override;

    //---------------------------------------------------------------------------
    // insert, edit, post, delete methods
    //---------------------------------------------------------------------------

    // edit record
    procedure InternalEdit; override;
    // cancels updates
    procedure InternalCancel(ToInsert: Boolean); override;
    // insert or update record
    procedure InternalPost(ToInsert: Boolean); override;
    // delete record
    procedure InternalDelete; override;
    procedure DeleteVisibleRecords; override;
    procedure UpdateVisibleRecords(FieldNames:   TSQLMemWideStringList;
                                   values:       array of TSQLMemVariant;
                                   SkipFKCheck:  Boolean = False
                                   ); override;

    //---------------------------------------------------------------------------
    // search & filter methods
    //---------------------------------------------------------------------------

    // disable record bitmap
    procedure DisableRecordBitmap; override;
    // apply projection
    procedure ApplyProjection(FieldNamesList, AliasList: TSQLMemWideStringList); override;
    procedure ActivateFilters(
                              FilterText:      WideString;
                              CaseInsensitive: Boolean;
                              PartialKey:      Boolean
                            ); override;
    procedure DeactivateFilters; override;
    function Locate(
                    const KeyFields: WideString;
                    const KeyValues: Variant;
                    CaseInsensitive: Boolean;
                    PartialKey:      Boolean
                   ): Boolean; override;
    function FindKey(SearchCondition: TSQLMemSearchCondition): Boolean; override;
    procedure ResetRange; override;
    procedure ApplyRange(
                          StartBuffer, EndBuffer: TSQLMemRecordBuffer;
                          StartKeyFieldCount:     Integer;
                          EndKeyFieldCount:       Integer;
                          StartExclusive:         Boolean;
                          EndExclusive:           Boolean
                        ); override;
    // set SQL Filter
    procedure SetSQLFilter(FilterExpr: TObject); override;


    //---------------------------------------------------------------------------
    // BLOB methods
    //---------------------------------------------------------------------------

    function InternalCreateBlobStream(
              ToInsert: Boolean;
              FieldNo:  Integer;
              OpenMode: TSQLMemBLOBOpenMode
              ):TSQLMemStream; override;

    procedure InternalCloseBLOB(FieldNo: Integer); override;

    // clear blob streams
    procedure ClearBLOBStreams(WriteOnly: Boolean = False); override;

    function LastAutoincValue(FieldNo: Integer): Int64; override;
    procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer); override;
    function GetTableState: TSQLMemTableState; override;

    procedure LockTable(bWriteMode: Boolean); override;
    procedure UnlockTable(bWriteMode: Boolean); override;

    // were used in transactions in versions 1-4.
{
    procedure SaveCurrentPosition;
    procedure RestoreSavedPosition;
}
    procedure FreeSavedPosition;
   public
    property TableData: TSQLMemTableData read FTableData;
    property DatabaseData: TSQLMemDatabaseData read FDatabaseData;
    property DoNotUnlockTable: Boolean read FDoNotUnlockTable write FDoNotUnlockTable;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    property SearchCache: TSQLMemScanSearchConditionCache read FSearchCache;
    property SearchOperation: TSQLMemLastSearchOperation read FSearchOperation write FSearchOperation;
{$ENDIF}
  end; // TSQLMemLocalCursor


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalSession
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemLocalSession = class (TSQLMemBaseSession)
   private
    FDatabaseData:  TSQLMemDatabaseData;
    FTransaction:   TSQLMemTransaction;

    function FindDatabaseData: TSQLMemDatabaseData;
    function CreateDatabaseData: TSQLMemDatabaseData;
    function FindOrCreateDatabaseData: TSQLMemDatabaseData;

   protected
    // db connected?
    function GetConnected: Boolean; override;
    // connect / disconnect
    procedure SetConnected(Value: boolean); override;

   public
    // check if database exists
    function GetDatabaseExists: Boolean; override;
    // create database
    procedure CreateDatabase; override;
    // flush file buffers
    procedure FlushFileBuffers; override;
    // return database format version
    function GetFormatVersion: Double; override;
    // return total number of pages
    function GetTotalPageCount : Integer; override;
    // return number of free pages
    function GetFreePageCount : Integer; override;
    // return true if database is encrypted
    function IsDatabaseEncrypted: Boolean; override;
    // return true if database is encrypted by password or by key
    function IsDatabaseEncryptedByPassword: Boolean; override;
    // makes Exe database from adb file
    procedure MakeExeDatabase(ExeFileName, ExeDatabaseFileName: WideString); override;
    // removes database file from executable database file
    procedure RemoveDatabaseFromExe; override;
    // returns true if this file is an SQLMemTable database
    function IsSQLMemTableDatabaseFile: Boolean; override;
    // return true if CryptoParams are valid
    function IsCryptoParamsValid: Boolean; override;
    procedure GetTablesList(List: TSQLMemWideStringList); override;
    function GetTablesInfo(SortByTableName: Boolean = True): TSQLMemTableInfoArray; override;
    function GetTableState(TableName: WideString): TSQLMemTableState; override;
    function TableExists(TableName: WideString): Boolean; override;
    // export database to SQL
    function ExportDatabaseToSQL(
                              ExportStructure:        Boolean = True;
                              AddDropTableCommand:    Boolean = True;
                              ExportIndexes:          Boolean = True;
                              AddDropIndexCommand:    Boolean = False;
                              ExportData:             Boolean = True;
                              ExportBLOBFields:       Boolean = True;
                              UseBracketsForNames:    Boolean = False;
                              ExportForeignKeys:      Boolean = True;
                              ExportStoredFunctions:  Boolean = True;
                              ExportViews:            Boolean = True
                                 ): WideString; override;
    // load local memory database
    procedure LoadDatabaseFromStream(
                        Stream: TStream
                       ); override;
    // save local memory database
    procedure SaveDatabaseToStream(
                    Stream:               TStream;
                    CompressionAlgorithm: TSQLMemCompressionAlgorithm = acaNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = SQLMemDefaultSaveBlockSize
                  ); override;
   protected
    // retrun true if database has active transaction
    function GetInTransaction: Boolean; override;
   public
    constructor Create;
    destructor Destroy; override;
    // start a transaction
    procedure StartTransaction; override;
    // apply changes made by transaction
    procedure Commit(FlushFileBuffers: Boolean); override;
    // cancel changes made by transaction
    procedure Rollback; override;
    procedure RemoveAllLocks; override;
    // clear disk cache in single-user / multi-user
    procedure ClearCache; override;
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString; override;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString); override;

    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
    // create stored function / procedure
    procedure CreateStoredFunction(SQLScript: WideString); overload; override;
    // for CREATE FUNCTON inside SQL script
    // current token is rwFUNCTION/rwPROCEDURE
    procedure CreateStoredFunction(
                  StoredFunction:   TObject;
                  SQLScript:        WideString
                                  ); overload; override;
    procedure ParseStoredFunction(
                  Lexer:                TSQLMemLexer;
                  var Token:            TToken;
                  out StoredFunction:   TObject;
                  out SQLScript:        WideString
                                 ); override;
    // drop stored function / procedure
    procedure DropStoredFunction(FunctionName: WideString); override;
    // ALTER stored function - modify script
    procedure AlterStoredFunction(
                                    FunctionName,
                                    NewSQLScript: WideString
                                 ); override;
    // ALTER stored function - rename
    procedure AlterStoredFunctionRename(
                                    FunctionName,
                                    NewFunctionName:  WideString
                                                        ); override;
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    // params - list of TSQLMemExpression
    function ExecuteStoredFunction(
                FunctionName:     WideString;
                ResultValue:      TSQLMemVariant;
                Params:           TSQLMemSQLParams = nil // TSQLMemExpressions
                                  ): Boolean; override;
    // return empty string if function not found; otherwise
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; override;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TSQLMemExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString): TObject; override;
    // parse for execute
    // return stored function object (TSQLMemStoredFunction) if found or nil
    // params - list of TSQLMemExpression
    function ParseStoredFunctionParams(
                    lexer:            TSQLMemLexer;
                    parentFunction:   TObject; // parent TSQLMemStoredFunction object, where parser was called
                    var token:        TToken;
                    out Params:       TObject // TSQLMemExpressions
                                      ): TObject; override;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload;  override;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload; override;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); override;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
    //------------------------- VIEWS - added in v.6.00 ------------------------
    // added in v.6.00 for views support
    function InternalCreateSQLProcessor(SQLStatement: WideString): TSQLMemLocalSQLProcessor;
    // create view
    procedure CreateView(
                         ViewName:          WideString;
                         SelectStatement:   WideString;
                         Columns:           TSQLMemWideStringList = nil;
                         bWithCheckOption:  Boolean = False;
                         Comment:           WideString = ''
                        ); override;
    // drop view
    procedure DropView(
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      ); override;
    // return nil if not found, otherwise return view definition
    function FindView(
                         ViewName:          WideString
                     ): TSQLMemViewDef; override;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    procedure CloseLocalSessionWithoutDatabase; override;
    // return cursor created for the specified table or view name
    function CreateCursor(TableName: WideString; bOpenView: Boolean = True): TSQLMemCursor; override;
   public
    property DatabaseData: TSQLMemDatabaseData read FDatabaseData;
    property Transaction: TSQLMemTransaction read FTransaction;
  end; // TSQLMemLocalSession

var
  DBDataList: TThreadList;

implementation

{$IFDEF D6H}
uses DateUtils,
     SQLMemMemory  // last
     ;
{$ELSE}
uses SQLMemMemory;  // last

procedure DecodeDateTime(const AValue: TDateTime; out AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word);
begin
  DecodeDate(AValue, AYear, AMonth, ADay);
  DecodeTime(AValue, AHour, AMinute, ASecond, AMilliSecond);
end;
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalBLOBStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemLocalBLOBStream.InternalSetSize(const NewSize: Int64);
begin
 if (OpenMode = bomRead) then
  raise ESQLMemException.Create(10116,ErrorLCannotWriteToReadOnlyStream);
 FTemporaryStream.Size := NewSize;
end; // InternalSetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemLocalBLOBStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemLocalBLOBStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemLocalBLOBStream.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FTemporaryStream.Read(Buffer,Count);
end; // Read


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemLocalBLOBStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (OpenMode = bomRead) then
  raise ESQLMemException.Create(10115,ErrorLCannotWriteToReadOnlyStream);
 Result := FTemporaryStream.Write(Buffer,Count);
end; // Write


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemLocalBLOBStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 Result := FTemporaryStream.Seek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemLocalBLOBStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 Result := FTemporaryStream.Seek(Offset,Origin);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
constructor TSQLMemLocalBLOBStream.Create(
                        TemporaryStream: TSQLMemStream;
                        Cursor: TSQLMemCursor;
                        OpenMode: TSQLMemBLOBOpenMode;
                        FieldNo: Integer
                                       );
begin
 UserBLOBStream := nil;
 FPosition := 0;
 FTemporaryStream := TemporaryStream;
 FCursor := Cursor;
 FFieldNo := FieldNo;
 FOpenMode := OpenMode;
 FDoNotFreeCompressedStream := False;
 inherited Create;
end; // Create


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
destructor TSQLMemLocalBLOBStream.Destroy;
begin
 if (not FDoNotFreeCompressedStream) then
   TSQLMemCompressedBLOBStream(FTemporaryStream).CompressedStream.Free;
 FTemporaryStream.Free;
 inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalCursor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemLocalCursor.Create;
begin
 FIsProjectionSet := False;
 FRandomOrder := False;
 FDoNotUnlockTable := False;
 FMemoryTableAllocBy := SQLMemDefaultMemoryTableAllocBy;
 FCreateTableStarted := False;
 FSavedPosition := nil;
 FSavedRecordBuffer := nil;
 CurrentRecordBuffer := nil;
 FTempRecordBuffer := nil;
 FDatabaseData := nil;
 FTableData := nil;
 FFieldDefs := nil;
 FVisibleFieldDefs := nil;
 FIndexDefs := nil;
 IsOpen := False;
 FBLOBStreams := nil;
 FIndexName := '';
 FIndexID := INVALID_OBJECT_ID;
 FilterExpression := nil;
 SQLFilterExpression := nil;
 FilterRecord := nil;
 FSettingProjection := False;
 RecordBitmap := nil;
 FDoNotCloseTableData := False;
 FRepair := False;
 FIsClientCursor := False;
 FErrorMessage := '';
 FSkipTableExistsCheck := False;
 DirectSetAutoInc := False;
 Dataset := nil;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 FSearchCache := nil;
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemLocalCursor.Destroy;
begin
 try
  CloseTable;
 except
 end;
 try
   if (FTempRecordBuffer <> nil) then
    begin
     FreeRecordBuffer(FTempRecordBuffer);
     FTempRecordBuffer := nil;
    end;
 except
 end;
 try
   FreeSavedPosition;
 except
 end;
 inherited;
end; // Destroy


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.CreateTable
                         (
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                          );
var i: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('> TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8)
+#13#10+'TableName = '+FTableName
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
);
{$ENDIF}
  CloseTable;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('1 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('2 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8)+', FDatabaseData = '+IntToHex(Integer(FDatabaseData),8));
{$ENDIF}
   if (InMemory or Temporary) then
    if (FDatabaseData.TableExists(Session,FTableName)) then
     begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('3 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
       DeleteTable;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('4 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('5 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  FTableData := FDatabaseData.FindOrCreateTableData(Self);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('6 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8)+', FTableData = '+IntToHex(Integer(FTableData),8)+', IndexDefs.Count = '+IntToStr(IndexDefs.Count));
{$ENDIF}
  if (FTableData = nil) then
    raise ESQLMemException.Create(10523,ErrorLNilPointer);
  for i := 0 to IndexDefs.Count - 1 do
    IndexDefs[i].RootPageNo := INVALID_PAGE_NO;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('7 TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  FTableData.CreateTable(Self,FieldDefs,IndexDefs,ConstraintDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_CreateTable}
aaWriteToLog('< TSQLMemLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DeleteTable(Cascade: Boolean);
begin
  CloseTable;
  FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
   if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
   else
    begin
     if (Session.InTransaction) then
      raise ESQLMemException.Create(10838,ErrorLCannotPerformThisOperationInsideATransaction);
     FTableData := FDatabaseData.CreateTableData(Self);
    end;
   if (FTableData = nil) then
    begin
     if (FDatabaseData is TSQLMemMemoryDatabaseData) then
     begin
      FDatabaseData.DropView(Session,FTableName,Cascade);
      Exit;
     end;
     raise ESQLMemException.Create(10027,ErrorLTableDataNotFound,[TableName]);
    end;
   FTableData.DeleteTable(Session,Cascade);
// v.5   
{
   if (InMemory or Temporary) then
    FTableData := nil
   else
}
   FreeAndNil(FTableData);
end; // DeleteTable;


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.EmptyTable;
begin
  CloseTable;
  FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
  if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
  else
     FTableData := FDatabaseData.FindOrCreateTableData(Self);
// changed in 4.70     
//     FTableData := FDatabaseData.CreateTableData(Self);
  if (FTableData = nil) then
    raise ESQLMemException.Create(10073,ErrorLTableDataNotFound,[TableName]);
  FTableData.EmptyTable(Self);
  if (InMemory or Temporary) then
    FTableData := nil
  else
    FreeAndNil(FTableData);
end; // EmptyTable


//------------------------------------------------------------------------------
// add foreign key
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.AddForeignKey(ConstraintDef: TSQLMemConstraintDefForeignKey);
begin
  if (FTableData = nil) then
   raise ESQLMemException.Create(11582,ErrorLTableDataNotFound,[TableName]);
  if (not FExclusive) then
   raise ESQLMemException.Create(11583,ErrorLTableIsNotOpenedExclusively,[FTableName]);
  FTableData.AddForeignKey(Self,ConstraintDef); 
end; // AddForeignKey


//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DeleteConstraint(Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean);
begin
  if (FTableData = nil) then
   raise ESQLMemException.Create(11484,ErrorLTableDataNotFound,[TableName]);
  if (not FExclusive) then
   raise ESQLMemException.Create(11486,ErrorLTableIsNotOpenedExclusively,[FTableName]);
  FTableData.DeleteConstraint(Self,Name,Cascade,FKPartialDelete);
end; // DeleteConstraint


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.RenameTable(NewTableName: WideString);
begin
  CloseTable;
  FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
  if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
  else
    begin
     if (Session.InTransaction) then
      raise ESQLMemException.Create(10839,ErrorLCannotPerformThisOperationInsideATransaction);
     FTableData := FDatabaseData.FindOrCreateTableData(Self);
    end;
  if (FTableData = nil) then
    raise ESQLMemException.Create(10151,ErrorLTableDataNotFound,[TableName]);
  FTableData.RenameTable(Self,NewTableName);
  FTableName := NewTableName;
  if (InMemory or Temporary) then
    FTableData := nil
  else
    FreeAndNil(FTableData);
end; // RenameTable


//------------------------------------------------------------------------------
// Rename Field
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.RenameField(FieldName, NewFieldName: WideString);
begin
  CloseTable;
  FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
  if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
  else
    begin
     if (Session.InTransaction) then
      raise ESQLMemException.Create(11165,ErrorLCannotPerformThisOperationInsideATransaction);
     FTableData := FDatabaseData.CreateTableData(Self);
    end;
  if (FTableData = nil) then
    raise ESQLMemException.Create(11166,ErrorLTableDataNotFound,[TableName]);
  FTableData.OpenTable(Self);
  try
     FTableData.RenameField(Self,FieldName, NewFieldName);
  finally
     FTableData.CloseTable(Self);
  end;
  if (InMemory or Temporary) then
   FTableData := nil
  else
   FreeAndNil(FTableData);
end;//RenameField


//------------------------------------------------------------------------------
// update table definitions (fields, indexes, constraints)
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.UpdateTableDefinitions;
begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('> TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName
+#13#10+'FIsOpen = '+BoolToStr(FIsOpen,True));
{$ENDIF}
 if (FIsOpen) then
  begin
   if (FIndexDefs <> nil) then
    FIndexDefs.Free;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('1. TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
   FIndexDefs := TSQLMemIndexDefs.Create;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('2. TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
aaWriteToLog('FTableData = '+IntToHex(Integer(FTableData),8));
if (FTableData<> nil) then
begin
 aaWriteToLog('FTableData.IndexManager = '+IntToHex(Integer(FTableData.IndexManager),8));
 if (FTableData.IndexManager <> nil) then
 begin
  aaWriteToLog('FTableData.IndexManager.IndexDefs = '+IntToHex(Integer(FTableData.IndexManager.IndexDefs),8));
  if (FTableData.IndexManager.IndexDefs <> nil) then
   aaWriteToLog('FTableData.IndexManager.IndexDefs.Count = '+IntToStr(FTableData.IndexManager.IndexDefs.Count));
 end;
end;
{$ENDIF}
   FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('3. TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
   if (FConstraintDefs <> nil) then
    FConstraintDefs.Free;
   FConstraintDefs := TSQLMemConstraintDefs.Create;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('4. TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
aaWriteToLog('FTableData = '+IntToHex(Integer(FTableData),8));
if (FTableData<> nil) then
begin
 aaWriteToLog('FTableData.ConstraintManager = '+IntToHex(Integer(FTableData.ConstraintManager),8));
 if (FTableData.ConstraintManager <> nil) then
 begin
  aaWriteToLog('FTableData.ConstraintManager.ConstraintDefs = '+IntToHex(Integer(FTableData.ConstraintManager.ConstraintDefs),8));
  if (FTableData.ConstraintManager.ConstraintDefs <> nil) then
   aaWriteToLog('FTableData.ConstraintManager.ConstraintDefs.Count = '+IntToStr(FTableData.ConstraintManager.ConstraintDefs.Count));
 end;
end;
{$ENDIF}
   FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('5. TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
   InternalInitFieldDefs;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('6. TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_UpdateTableDefinitions}
aaWriteToLog('< TSQLMemLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName
+#13#10+'FIsOpen = '+BoolToStr(FIsOpen,True));
{$ENDIF}
end; // UpdateTableDefinitions


//------------------------------------------------------------------------------
// copy records
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.TryToCopyRecords(NewCursor: TSQLMemLocalCursor; var Log: AnsiString);
var GetRecordResult: TSQLMemGetRecordResult;
    bStart:           Boolean;
    bCalculateMinMax: Boolean;
    minmax:           array of Int64;
    CurrentValue:     TSQLMemVariant;
    i:                Integer;


  procedure CopyRecord;
  var i:          Integer;
      bs,bs1:     TSQLMemStream;
      BLOBExists: Boolean;
  begin
    SQLMemRefresh;
    Move(FCurrentRecordBuffer^,NewCursor.FCurrentRecordBuffer^,FRecordBufferSize);
    BLOBExists := False;
    NewCursor.InternalInsert;
    try
     if (FieldDefs.VarcharOrBLOBFieldsExists) then
      for i := 0 to FieldDefs.Count - 1 do
       if (IsBLOBFieldType(FieldDefs[i].BaseFieldType)) then
        begin
         BLOBExists := True;
         bs1 := NewCursor.InternalCreateBlobStream(True,i,bomWrite);
         try
           bs := Self.InternalCreateBlobStream(False,i,bomRead);
           try
             bs1.LoadFromStream(bs);
             bs1.Modified := True;
           finally
             bs.Free;
           end;
         except
          on e: Exception do
          begin
           bs1.Size := 0;
           bs1.Modified := True;
           Log := Log + ErrorLRepairTableCannotReadBLOBValue + FieldDefs.Items[i].Name+'.'+FTableName + #13#10+ e.Message + #13#10;
          end;
         end;
         NewCursor.InternalCloseBLOB(i);
        end;
     NewCursor.InternalPost(True);
     if (bCalculateMinMax) then
      begin
       for i := 0 to FieldDefs.Count - 1 do
        if (IsAutoincFieldType(FieldDefs[i].AdvancedFieldType) and
            (not FieldDefs[i].AutoincCycled)) then
         begin
          NewCursor.GetFieldValue(CurrentValue,i,True,True);
          if (FieldDefs[i].AutoincIncrement >= 0) then
           begin
            if (bStart) then
             minmax[i] := CurrentValue.AsInt64
            else
             if (CurrentValue.AsInt64 > minmax[i]) then
              minmax[i] := CurrentValue.AsInt64;
           end // increment >= 0
          else
           begin
            if (bStart) then
             minmax[i] := CurrentValue.AsInt64
            else
             if (CurrentValue.AsInt64 < minmax[i]) then
              minmax[i] := CurrentValue.AsInt64;
           end; // increment < 0
         end;
       bStart := False;
      end;
     if (BLOBExists) then
      FBLOBStreams.Clear;
    except
     on e: Exception do
      Log := Log + ErrorLRepairTableCannotInsertRecord + FieldDefs.Items[i].Name + '.' + FTableName + #13#10+ e.Message + #13#10;
    end;
  end;

  procedure TryToGetRecordsFromFirst;
  begin
   FirstPosition := True;
   LastPosition := False;
   repeat
    GetRecordResult := GetRecordBuffer(grmNext);
    if (GetRecordResult = grrOK) then
     CopyRecord
    else
     if (GetRecordResult = grrError) then
      raise ESQLMemException.Create(11167,ErrorLRepairTableCannotGetRecord,
            [CurrentRecordID.PageNo,CurrentRecordID.PageItemNo,FTableName]);
   until (GetRecordResult = grrEOF);
  end; // TryToGetRecordsFromFirst


  procedure TryToGetRecordsFromLast(LastRecordID: TSQLMemRecordID; bGetAll: Boolean);
  begin
   FirstPosition := False;
   LastPosition := True;
   repeat
    GetRecordResult := GetRecordBuffer(grmPrior);
    if (not bGetAll) then
     if ((CurrentRecordID.PageNo = LastRecordID.PageNo) and
         (CurrentRecordID.PageItemNo = LastRecordID.PageItemNo)) then
      break;
    if (GetRecordResult = grrOK) then
     CopyRecord
{
     begin
      NewCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
      NewCursor.InternalInsert;
      try
       NewCursor.InternalPost(True);
      except
       on e: Exception do
        Log := Log + ErrorLRepairTableCannotInsertRecord + FTableName + #13#10+ e.Message + #13#10;
      end;
     end
}     
    else
     if (GetRecordResult = grrError) then
      raise ESQLMemException.Create(11168,ErrorLRepairTableCannotGetRecord,
            [CurrentRecordID.PageNo,CurrentRecordID.PageItemNo,FTableName]);
   until (GetRecordResult = grrBOF);
  end; // TryToGetRecordsFromLast

begin
  Self.Repair := True;
  bStart := True;
  bCalculateMinMax := FieldDefs.AutoIncFieldsExists;
  if (bCalculateMinMax) then
   begin
    SetLength(minmax,FieldDefs.Count);
    CurrentValue := TSQLMemVariant.Create;
   end;
  try
    FCurrentRecordBuffer := AllocateRecordBuffer;
    NewCursor.FCurrentRecordBuffer := NewCursor.AllocateRecordBuffer;
    try
      // try to get records from beginning of the table
      try
        TryToGetRecordsFromFirst;
      except
       on e: Exception do
        begin
          Log := Log + ErrorLRepairTableCannotGetRecordsFromFirst + FTableName + #13#10 + e.Message + #13#10;
          try
           TryToGetRecordsFromLast(CurrentRecordID,FirstPosition);
          except
           on e: Exception do
            begin
             Log := Log + ErrorLRepairTableCannotGetRecordsFromLast + FTableName + #13#10+ e.Message + #13#10;
            end;
          end;
        end;
      end;
    finally
      Self.Repair := False;
      Self.FreeRecordBuffer(FCurrentRecordBuffer);
      NewCursor.FreeRecordBuffer(NewCursor.FCurrentRecordBuffer);
    end;
  finally
   if (bCalculateMinMax) then
    begin
     if (not bStart) then
       for i := 0 to FieldDefs.Count - 1 do
        if (IsAutoincFieldType(FieldDefs[i].AdvancedFieldType) and
            (not FieldDefs[i].AutoincCycled)) then
         NewCursor.SetLastAutoincValue(minmax[i],i);
     CurrentValue.Free;
     minmax := nil;
    end;
  end;
end; // TryToCopyRecords


//------------------------------------------------------------------------------
// Repair table
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TSQLMemConstraintDefs = nil
                                    ): Boolean;
var NewCursor:          TSQLMemLocalCursor;
    TempConstraintDefs: TSQLMemConstraintDefs;
begin
  if (FInMemory or FTemporary) then
     Result := True
  else
   begin
    if (not FExclusive) then
     raise ESQLMemException.Create(11165,ErrorLTableIsNotOpenedExclusively,[FTableName]);
    try
      Self.OpenTableByFieldDefs(nil,nil,nil);
      Self.InternalInitFieldDefs;
    except
      Result := False;
      Exit;
    end;
    NewCursor := TSQLMemLocalCursor.Create;
    try
      NewCursor.DirectSetAutoInc := True;
      NewCursor.InMemory := False;
      NewCursor.Temporary := False;
      NewCursor.Exclusive := True;
      if (NewSession <> nil) then
       NewCursor.Session := NewSession
      else
       NewCursor.Session := Self.Session;
      repeat
       NewCursor.TableName := GetTemporaryName(FTableName+'_REPAIRED_');
      until (not NewCursor.Session.TableExists(NewCursor.TableName));
      // create table
      try
        if (ConstraintDefs <> nil) then
         begin
          // added in v.5.50 - for low level repair database with foreign keys
          TempConstraintDefs := TSQLMemConstraintDefs.Create;
          try
            TempConstraintDefs.Assign(Self.ConstraintDefs);
            TempConstraintDefs.ExtractForeignKeys(ConstraintDefs);
            NewCursor.CreateTable(Self.FFieldDefs,Self.IndexDefs,TempConstraintDefs);
          finally
            TempConstraintDefs.Free;
          end;
         end
        else
          NewCursor.CreateTable(Self.FFieldDefs,Self.IndexDefs,Self.ConstraintDefs);
        NewCursor.OpenTableByFieldDefs(nil,nil,nil);
        NewCursor.InternalInitFieldDefs;
        Result := True;
      except
        Log := Log + ErrorLRepairTableCannotCreateTable + NewCursor.TableName + #13#10;
        Result := False;
        Exit;
      end;
      try
        TryToCopyRecords(NewCursor,Log);
        // update sequence values
{
        if (NewCursor.GetRecordCount > 0) then
          for i := 0 to NewCursor.FieldDefs.Count - 1 do
           if (IsAutoincFieldType(NewCursor.FieldDefs.Items[i].AdvancedFieldType)) then
            if (not NewCursor.FieldDefs.Items[i].AutoincCycled) then
             begin
              x := NewCursor.LastAutoincValue(i)+NewCursor.FieldDefs.Items[i].AutoincIncrement;
              y := x;
              Name := NewCursor.FieldDefs.Items[i].Name;
              while (NewCursor.Locate(Name,y,false,false)) do
               Inc(y);
              if (x <> y) then
               NewCursor.SetLastAutoincValue(y-NewCursor.FieldDefs.Items[i].AutoincIncrement,i);
             end;
}
      finally
        NewCursor.CloseTable;
        Self.CloseTable;
        // delete source table only if single repair table called
        if (NewSession = nil) then
          Self.DeleteTable;
        NewCursor.RenameTable(FTableName);
      end;
    finally
      NewCursor.Free;
    end;
   end;
end; // RepairTable


//------------------------------------------------------------------------------
// load table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.LoadTableFromStream(
                        Stream:               TStream
                       );
begin
//  CloseTable;
  FCreateTableStarted := True;
{$IFDEF MEMORY_ENGINE}
  try
    FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
    // added in v.4.80
    if (not FTemporary) then
      FTableName := SQLMemGetSavedTableNameFromStream(Stream);
    if (FDatabaseData.TableExists(Session,FTableName)) then
      DeleteTable(True);
    FTableData := FDatabaseData.FindOrCreateTableData(Self);
    if (FTableData = nil) then
      raise ESQLMemException.Create(10154,ErrorLTableDataNotFound,[TableName]);
    try
       FTableData.LoadTableFromStream(Self,Stream);
    except
     on e: Exception do
       begin
         FTableData.Free;
         FTableData := nil;
         raise;
       end;
    end;
    FTableName := FTableData.TableName;
    FTableData := nil;
  finally
   FCreateTableStarted := False;
  end;
{$ENDIF}
end; // LoadTableFromStream;


//------------------------------------------------------------------------------
// save table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
                        CompressionMode:        Byte;
                        BlockSize:              Integer;
                        SkipCheckIsTableOpened: Boolean;
                        DoNotCloseTable:        Boolean
                      );
begin
  if (Session = nil) then
    raise ESQLMemException.Create(11762,ErrorLNilPointer);
  FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
  if (FDatabaseData = nil) then
    raise ESQLMemException.Create(11761,ErrorLDatabaseDataNotFound,[TSQLMemLocalSession(Session).DatabaseName,TSQLMemLocalSession(Session).DatabaseFileName,AnsiString(TSQLMemLocalSession(Session).DatabaseFileNameUnicode),
      BoolToStr(TSQLMemLocalSession(Session).InMemory,True),
      BoolToStr(TSQLMemLocalSession(Session).Temporary,True)]);
  FTableData := FDatabaseData.FindTableData(Self);
  if (FTableData = nil) then
    raise ESQLMemException.Create(10154,ErrorLTableDataNotFound,[TableName]);
  FTableData.SaveTableToStream(Stream,CompressionAlgorithm,CompressionMode,BlockSize,SkipCheckIsTableOpened);
  if (not DoNotCloseTable) then
   begin
    FTableData.CloseTable(Self);
    FTableData := nil;
   end;
end; // SaveTableToStream


//------------------------------------------------------------------------------
// drop table
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetDropTableCommand(aTableName: WideString): WideString;
begin
  if (FIsView) then
    Result := GetReservedWord(rwDROP) + Space +
              GetReservedWord(rwVIEW) + Space +
              aTableName + Space + GetReservedWord(rwCASCADE) + SemiColon + Crlf
  else
    Result := GetReservedWord(rwDROP) + Space +
              GetReservedWord(rwTABLE) + Space +
              aTableName + Space + GetReservedWord(rwCASCADE) + SemiColon + Crlf;
end; // GetDropTableCommand


//------------------------------------------------------------------------------
// get autoinc field definition
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetAutoIncFieldDefinition(FieldDef: TSQLMemFieldDef): WideString;
var Cycled, MinValue, MaxValue: WideString;
begin
  if (FieldDef.AutoincCycled) then
   Cycled := GetReservedWord(rwCYCLED)
  else
   Cycled := GetReservedWord(rwNOCYCLED);
  if (FieldDef.AutoincMinValue = 0) then
   MinValue := GetReservedWord(rwNOMINVALUE)
  else
   MinValue := GetReservedWord(rwMINVALUE) + Space +
               IntToStr(FieldDef.AutoincMinValue);
  if (FieldDef.AutoincMaxValue = High(Int64)) then
   MaxValue := GetReservedWord(rwNOMAXVALUE)
  else
   MaxValue := GetReservedWord(rwMAXVALUE) + Space +
               IntToStr(FieldDef.AutoincMaxValue);
  Result := Result + Space + GetFieldTypeSQLName(aftAutoInc) + Space + LeftParenthesis +
            GetFieldTypeSQLName(FieldDef.AdvancedFieldType) + Space +
            GetReservedWord(rwINITIALVALUE) + Space +
            IntToStr(FieldDef.AutoincInitialValue)+ Space +
            GetReservedWord(rwINCREMENT) + Space +
            IntToStr(FieldDef.AutoincIncrement)+ Space +
            MinValue + Space + MaxValue + Space + Cycled +
            RightParenthesis;
end; // GetAutoIncFieldDefinition


//------------------------------------------------------------------------------
// blob field definition
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetBLOBFieldDefinition(FieldDef: TSQLMemFieldDef): WideString;
begin
  Result := GetReservedWord(rwBLOBBLOCKSIZE) + Space +
            IntToStr(FieldDef.BLOBBlockSize) + Space +
            GetReservedWord(rwBLOBCOMPRESSIONALGORITHM) + Space +
            GetCompressionAlgorithmSQLName(FieldDef.BLOBCompressionAlgorithm) + Space +
            GetReservedWord(rwBLOBCOMPRESSIONMODE) + Space +
            IntToStr(FieldDef.BLOBCompressionMode);
end; // GetBLOBFieldDefinition


//------------------------------------------------------------------------------
// field definition for create table
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetFieldDefinition(FieldDef:             TSQLMemFieldDef;
                                            UseBracketsForNames:  Boolean): WideString;
var i:      Integer;
    s:      WideString;
    check:  TSQLMemConstraintDefCheck;
begin
  // get name
  if (UseBracketsForNames) then
    Result := LeftBracket + FieldDef.Name + RightBracket
  else
    Result := FieldDef.Name;
 // get data type
 if (IsAutoincFieldType(FieldDef.AdvancedFieldType)) then
  Result := Result + Space + GetAutoIncFieldDefinition(FieldDef)
 else
  begin
   Result := Result + Space + GetFieldTypeSQLName(FieldDef.AdvancedFieldType);
   if (IsStringFieldType(FieldDef.AdvancedFieldType) or
       IsBytesFieldType(FieldDef.AdvancedFieldType)) then
    Result := Result + Space + LeftParenthesis +
              IntToStr(FieldDef.FieldSize) + RightParenthesis;
  end;
 if (IsBLOBFieldType(FieldDef.AdvancedFieldType)) then
  Result := Result + Space + GetBLOBFieldDefinition(FieldDef);
 if (not FieldDef.DefaultValue.IsNull) then
  begin
    if (FieldDef.DefaultValue.IsStringDataType) then
     s := AnsiQuotedStr(FieldDef.DefaultValue.AsString,SingleQuote)
    else
     s := FieldDef.DefaultValue.AsString;
    Result := Result + Space + GetReservedWord(rwDEFAULT) + Space + s;
  end;
 // check if field is required or has minimum or maximum value restrictions
 s := WideUpperCase(FieldDef.Name);
 for i := 0 to FConstraintDefs.Count - 1 do
  if (WideUpperCase(TSQLMemConstraintDefNotNull(FConstraintDefs[i]).ColumnName) = s) then
   begin
    if (FConstraintDefs[i].ConstraintType = ctNotNull) then
     Result := Result + Space + GetReservedWord(rwNOT) + Space + GetReservedWord(rwNULL)
    else
     if (FConstraintDefs[i].ConstraintType = ctCheck) then
      begin
       check := TSQLMemConstraintDefCheck(FConstraintDefs[i]);
       if (not check.MinValue.IsNull) then
        begin
          if (check.MinValue.IsStringDataType) then
           s := AnsiQuotedStr(check.MinValue.AsString,SingleQuote)
          else
           s := check.MinValue.AsString;
          Result := Result + Space + GetReservedWord(rwMINVALUE) + Space + s;
        end;
       if (not check.MaxValue.IsNull) then
        begin
          if (check.MaxValue.IsStringDataType) then
           s := AnsiQuotedStr(check.MaxValue.AsString,SingleQuote)
          else
           s := check.MaxValue.AsString;
          Result := Result + Space + GetReservedWord(rwMAXVALUE) + Space + s;
        end;
      end; // Check
   end;
end; // GetFieldDefinition


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.GetCreateTableCommand(
                    var TableSQL:         WideString;
                    var TableFKSQL:       WideString;
                    aTableName:           WideString;
                    UseBracketsForNames:  Boolean;
                    ExportForeignKeys:    Boolean
                                              );
var i,j:        Integer;
    FieldName:  WideString;
    IndexName:  WideString;
    KeyName:    WideString;
    MatchType:  WideString;
    Action:     WideString;
    IndexDef:   TSQLMemIndexDef;
    FKDef:      TSQLMemConstraintDefForeignKey;
    fkText:     WideString;
    sqlText:    WideString;
    s:          WideString;
begin
  if (FIsView) then
  begin
    sqlText := GetReservedWord(rwCREATE) + Space +
              GetReservedWord(rwVIEW) + Space +
              aTableName + Space;
    if (Length(FViewColumns) > 0) then
     sqlText := sqlText+LeftParenthesis+FViewColumns+RightParenthesis+Space;
    sqlText := sqlText + GetReservedWord(rwAS)+Crlf+FViewSelect+Crlf;
    if (FIsViewWithCheckOption) then
     sqlText := sqlText + GetReservedWord(rwWITH)+Space+GetReservedWord(rwCHECK)
               +Space+GetReservedWord(rwOPTION);
  end
  else
  begin
    sqlText := GetReservedWord(rwCREATE) + Space +
              GetReservedWord(rwTABLE) + Space +
              aTableName + Space +
              LeftParenthesis + Crlf;
    for i := 0 to FFieldDefs.Count - 1 do
     begin
      if (i > 0) then
       sqlText := sqlText + Comma + Crlf;
      sqlText := sqlText + Tab;
      sqlText := sqlText +
        GetFieldDefinition(FFieldDefs[i],UseBracketsForNames);
     end;
    // add primary key
    for i := 0 to FIndexDefs.Count - 1 do
     if (FIndexDefs[i].Primary) then
      begin
       IndexDef := FIndexDefs[i];
       if (UseBracketsForNames) then
        IndexName := LeftBracket + IndexDef.Name + RightBracket
       else
        IndexName := IndexDef.Name;
       sqlText := sqlText + Comma + Crlf + GetReservedWord(rwPRIMARY) + Space +
                 GetReservedWord(rwKEY) + Space +
                 IndexName + Space + LeftParenthesis;
       for j := 0 to IndexDef.ColumnCount - 1 do
        begin
         if (UseBracketsForNames) then
          FieldName := LeftBracket + IndexDef.Columns[j].FieldName + RightBracket
         else
          FieldName := IndexDef.Columns[j].FieldName;
         if (IndexDef.Columns[j].Descending) then
          FieldName := FieldName + Space + GetReservedWord(rwDESC);
         if (IndexDef.Columns[j].CaseInsensitive) then
          FieldName := FieldName + Space + GetReservedWord(rwNOCASE);
         if (j = 0) then
          sqlText := sqlText + FieldName
         else
          sqlText := sqlText + Comma + Space + FieldName;
        end;
        sqlText := sqlText + RightParenthesis;
      end; // Primary index
    // )
    sqlText := sqlText + Crlf + RightParenthesis;
  end;
  // comment
  if (FComment <> '') then
   sqlText := sqlText + Space + GetReservedWord(rwCOMMENT) + Space + SingleQuote +
             FComment + SingleQuote;
  sqlText := sqlText + SemiColon + Crlf;
  // foreign keys
  fkText := '';
  if (ExportForeignKeys and (not FIsView)) then
   begin
    for i := 0 to FConstraintDefs.Count-1 do
     if (FConstraintDefs.Items[i].ConstraintType = ctFK) then
      begin
       // ALTER TABLE Emp ADD FOREIGN KEY FKDeptID (DeptID) REFERENCES Dept MATCH FULL ON DELETE CASCADE ON UPDATE SET DEFAULT
       s := GetReservedWord(rwALTER) + Space + GetReservedWord(rwTABLE) + Space
             +aTableName + Space +  GetReservedWord(rwADD) + Space
             +GetReservedWord(rwFOREIGN) + Space
             +GetReservedWord(rwKEY) + Space;

       if (fkText = '') then
        fkText := s
       else
        fkText := fkText + CRLF + s;

       FKDef := TSQLMemConstraintDefForeignKey(FConstraintDefs.Items[i]);
       if (UseBracketsForNames) then
        KeyName := LeftBracket + FKDef.Name + RightBracket
       else
        KeyName := FKDef.Name;
       fkText := fkText + KeyName + Space + LeftParenthesis;
       for j := 0 to High(FKDef.Columns) do
        begin
         if (UseBracketsForNames) then
          FieldName := LeftBracket + FKDef.Columns[j].ColumnName + RightBracket
         else
          FieldName := FKDef.Columns[j].ColumnName;
         if (j = 0) then
          fkText := fkText + FieldName
         else
          fkText := fkText + Comma + Space + FieldName;
        end;
       if (UseBracketsForNames) then
        TableName := LeftBracket + FKDef.ReferencedTableName + RightBracket
       else
        TableName := FKDef.ReferencedTableName;

       MatchType := '';
       if (FKDef.MatchType = cfkmtFull) then
        MatchType := GetReservedWord(rwMATCH) + Space + GetReservedWord(rwFULL) + Space
       else
       if (FKDef.MatchType = cfkmtPartial) then
        MatchType := GetReservedWord(rwMATCH) + Space + GetReservedWord(rwPARTIAL) + Space;

       fkText := fkText + RightParenthesis + Space +
                 GetReservedWord(rwREFERENCES) + Space + TableName + Space +
                 MatchType;

       Action := '';
       case FKDef.DeleteAction of
        cfkaCascade: Action := GetReservedWord(rwON) + Space + GetReservedWord(rwDELETE)
                 + Space + GetReservedWord(rwCASCADE);
        cfkaSetNull: Action := GetReservedWord(rwON) + Space + GetReservedWord(rwDELETE)
                 + Space + GetReservedWord(rwSET) + Space + GetReservedWord(rwNULL);
        cfkaSetDefault: Action := GetReservedWord(rwON) + Space + GetReservedWord(rwDELETE)
                 + Space + GetReservedWord(rwSET) + Space + GetReservedWord(rwDEFAULT);
        cfkaNoAction: Action := GetReservedWord(rwON) + Space + GetReservedWord(rwDELETE)
                 + Space + GetReservedWord(rwNO) + Space + GetReservedWord(rwACTION);
       end;
       fkText := fkText + Action;

       Action := '';
       case FKDef.UpdateAction of
        cfkaCascade: Action := Space + GetReservedWord(rwON) + Space + GetReservedWord(rwUPDATE)
                 + Space + GetReservedWord(rwCASCADE);
        cfkaSetNull: Action := Space + GetReservedWord(rwON) + Space + GetReservedWord(rwUPDATE)
                 + Space + GetReservedWord(rwSET) + Space + GetReservedWord(rwNULL);
        cfkaSetDefault: Action := Space + GetReservedWord(rwON) + Space + GetReservedWord(rwUPDATE)
                 + Space + GetReservedWord(rwSET) + Space + GetReservedWord(rwDEFAULT);
        cfkaNoAction: Action := Space + GetReservedWord(rwON) + Space + GetReservedWord(rwUPDATE)
                 + Space + GetReservedWord(rwNO) + Space + GetReservedWord(rwACTION);
       end;
       fkText := fkText + Action + SemiColon;
      end;

    if (TableFKSQL = '') then
     TableFKSQL := fkText
    else
     TableFKSQL := TableFKSQL+CRLF+fkText;
   end; // foreign keys
  if (TableSQL = '') then
   TableSQL := sqlText
  else
   TableSQL := TableSQL+CRLF+sqlText;
end; // GetCreateTableCommand


//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetCreateIndexCommand(aTableName:          WideString;
                                               IndexName:           WideString;
                                               IndexDef:            TSQLMemIndexDef;
                                               UseBracketsForNames: Boolean): WideString;
var Unique:     WideString;
    i:          Integer;
    FieldName:  WideString;
begin
  Unique := '';
  if (IndexDef.Unique) then
   Unique := GetReservedWord(rwUNIQUE) + Space;
  Result := GetReservedWord(rwCREATE) + Space + Unique +
            GetReservedWord(rwINDEX) + Space + IndexName + Space +
            GetReservedWord(rwON) + Space + aTableName + Space + LeftParenthesis + Crlf;
  for i := 0 to IndexDef.ColumnCount - 1 do
   begin
    if (UseBracketsForNames) then
     FieldName := LeftBracket + IndexDef.Columns[i].FieldName + RightBracket
    else
     FieldName := IndexDef.Columns[i].FieldName;
    if (IndexDef.Columns[i].Descending) then
     FieldName := FieldName + Space + GetReservedWord(rwDESC);
    if (IndexDef.Columns[i].CaseInsensitive) then
     FieldName := FieldName + Space + GetReservedWord(rwNOCASE);
    if (i > 0) then
     Result := Result + Comma + Crlf;
    Result := Result  + Tab + FieldName;
   end;
  Result := Result + Crlf + RightParenthesis + SemiColon + Crlf;  
end; // GetCreateIndexCommand


//------------------------------------------------------------------------------
// drop index
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetDropIndexCommand(aTableName: WideString; IndexName: WideString): WideString;
begin
  Result := GetReservedWord(rwDROP) + Space +
            GetReservedWord(rwINDEX) + Space +
            GetReservedWord(rwIF) + Space +
            GetReservedWord(rwEXISTS) + Space +
            aTableName + Dot + IndexName + SemiColon + Crlf;
end; // GetDropIndexCommand


//------------------------------------------------------------------------------
// get BLOB field value
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetSQLBLOBFieldValue(FieldNo: Integer): WideString;
var bs:   TSQLMemStream;
    buf:  PAnsiChar;
    size: Integer;

  procedure CloseBlobStream;
  begin
   bs.Free;
   bs := nil;
  end;


begin
  bs := Self.InternalCreateBlobStream(False,FieldNo,bomRead);
  try
   size := bs.Size;
   if (size <= 0) then
    begin
     Result := 'NULL';
     CloseBlobStream;
     Exit;
    end;
   buf := MemoryManager.GetMem(size);
   try
     bs.ReadBuffer(buf^,size);
     CloseBlobStream;
     Result := GetReservedWord(rwTOBLOB) + Space + LeftParenthesis +
               SingleQuote + SQLMemBinaryToMIME64(buf,size) + SingleQuote + Comma +
               GetReservedWord(rwMIME64) + RightParenthesis;
   finally
     MemoryManager.FreeAndNilMem(buf);
   end;
  finally
   if (bs <> nil) then
    CloseBlobStream;
  end;
end; // GetBLOBFieldValue


//------------------------------------------------------------------------------
// get field value
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetSQLFieldValue(var v: TSQLMemVariant; FieldNo: Integer; ExportBLOBFields: Boolean): WideString;
var c: Char;
    y,m,d,h,n,s,z: Word;
begin
  GetFieldValue(v,FieldNo,True,False);
  if (v.IsNull) then
   Result := 'NULL'
  else
  if (v.IsDateTimeDataType) then
   begin
    DecodeDateTime(v.AsTDateTime,y,m,d,h,n,s,z);
    Result := 'TODATE('''+IntToStr(m)+'/'+IntToStr(d)+'/'+IntToStr(y)+' '+
                      IntToStr(h)+':'+IntToStr(n)+':'+IntToStr(s)+':'+IntToStr(z)+
                      ''',''M/D/YYYY H24:N:S:Z'')';
   end
  else
  if (v.IsStringDataType) then
   Result := AnsiQuotedStr(v.AsString,SingleQuote)
  else
  if (v.IsNumericDataType) then
   begin
{$IFDEF D17H}
    c := FormatSettings.DecimalSeparator;
    FormatSettings.DecimalSeparator := '.';
    try
      Result := v.AsString;
    finally
      FormatSettings.DecimalSeparator := c;
    end;
{$ELSE}
    c := DecimalSeparator;
    DecimalSeparator := '.';
    try
      Result := v.AsString;
    finally
      DecimalSeparator := c;
    end;
{$ENDIF}
   end
  else
   Result := v.AsString;
end; // GetSQLFieldValue


//------------------------------------------------------------------------------
// insert
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetInsertCommand(var v: TSQLMemVariant; aTableName: WideString; UseBracketsForNames:  Boolean; ExportBLOBFields: Boolean): WideString;
var FieldsList:   WideString;
    i:            Integer;
    FieldValues:  WideString;
    bBlobFound:   Boolean;
    FieldName:    WideString;
begin
  FieldsList := '';
  FieldValues := '';
  if (not ExportBLOBFields) then
   begin
    bBlobFound := False;
    for i := 0 to FieldDefs.Count - 1 do
     if (IsBLOBFieldType(FieldDefs[i].AdvancedFieldType)) then
       bBlobFound := True
     else
      begin
       if (UseBracketsForNames) then
        FieldName := LeftBracket + FieldDefs[i].Name + RightBracket
       else
        FieldName := FieldDefs[i].Name;
       if (FieldsList <> '') then
        FieldsList := FieldsList + Comma + Space + FieldName
       else
        FieldsList := FieldName;
      end;
    if (not bBlobFound) then
     FieldsList := ''
    else
     FieldsList := LeftParenthesis + FieldsList + RightParenthesis + Space;
   end;
  for i := 0 to FieldDefs.Count - 1 do
   begin
    if ((not ExportBLOBFields) and (IsBLOBFieldType(FieldDefs[i].AdvancedFieldType))) then
     continue;
    if (i > 0) then
     FieldValues := FieldValues + Comma + Crlf;
    FieldValues := FieldValues + Tab;
    if (IsBLOBFieldType(FieldDefs[i].AdvancedFieldType)) then
     begin
      FieldValues := FieldValues + GetSQLBLOBFieldValue(i);
      bBlobFound := True;
     end
    else
     FieldValues := FieldValues + GetSQLFieldValue(v,i,ExportBLOBFields);
   end;
  Result := GetReservedWord(rwINSERT) + Space +
            GetReservedWord(rwINTO) + Space +
            aTableName + Space +
            FieldsList +
            GetReservedWord(rwVALUES) + Space + LeftParenthesis + Crlf +
            FieldValues + Crlf +
            RightParenthesis + SemiColon + Crlf;
  if (bBlobFound and ExportBLOBFields) then
    FBLOBStreams.Clear;
end; // GetInsertCommand


//------------------------------------------------------------------------------
// export table to SQL
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.GetTableSQL(
                          var TableSQL:         WideString;
                          var TableFKSQL:       WideString;
                          ExportStructure:      Boolean;
                          AddDropTableCommand:  Boolean;
                          ExportIndexes:        Boolean;
                          AddDropIndexCommand:  Boolean;
                          ExportData:           Boolean;
                          ExportBLOBFields:     Boolean;
                          UseBracketsForNames:  Boolean;
                          ExportForeignKeys:    Boolean
                      );
var aTableName:   WideString;
    IndexName:    WideString;
    i:            Integer;
    OldRecBuffer: PAnsiChar;
    Buf:          PAnsiChar;
    OldPos:       Pointer;
    v:            TSQLMemVariant;
begin
  if (FIsView) then
  begin
    if (UseBracketsForNames) then
     aTableName := LeftBracket + FViewName + RightBracket
    else
     aTableName := FViewName;
  end
  else
  begin
    if (UseBracketsForNames) then
     aTableName := LeftBracket + FTableName + RightBracket
    else
     aTableName := FTableName;
  end;
  if (FInMemory and (not FIsView)) then
   aTableName := GetReservedWord(rwMEMORY)+ Space + aTableName;
  if (ExportStructure) then
   begin
    if (AddDropTableCommand) then
     TableSQL := TableSQL + GetDropTableCommand(aTableName);
    GetCreateTableCommand(TableSQL,TableFKSQL,aTableName,UseBracketsForNames,ExportForeignKeys);
   end;
  if (ExportIndexes and (not FIsView)) then
   begin
    for i := 0 to FIndexDefs.Count - 1 do
     begin
      if (FIndexDefs[i].Primary) then continue;
      if (UseBracketsForNames) then
       IndexName := LeftBracket + FIndexDefs[i].Name + RightBracket
      else
       IndexName := FIndexDefs[i].Name;
      if (AddDropIndexCommand) then
       TableSQL := TableSQL + GetDropIndexCommand(aTableName,IndexName);
      TableSQL := TableSQL + GetCreateIndexCommand(aTableName,IndexName,FIndexDefs[i],UseBracketsForNames);
     end;
   end;
  if (ExportData and (not FIsView)) then
   begin
    OldPos := SavePosition;
    OldRecBuffer := CurrentRecordBuffer;
    CurrentRecordBuffer := AllocateRecordBuffer;
    v := TSQLMemVariant.Create;
    ClearBLOBStreams(False);
    try
      InternalFirst;
      while (GetRecordBuffer(grmNext) = grrOK) do
       begin
        SQLMemRefresh;
        TableSQL := TableSQL + GetInsertCommand(v,aTableName,UseBracketsForNames,ExportBLOBFields);
       end;
    finally
      v.Free;
      Buf := CurrentRecordBuffer;
      FreeRecordBuffer(Buf);
      RestorePosition(OldPos);
      FreePosition(OldPos);
      CurrentRecordBuffer := OldRecBuffer;
    end;
   end; // Export Data
end; // GetTableSQL


//------------------------------------------------------------------------------
// export table to SQL
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.ExportTableToSQL(
                            ExportStructure:      Boolean;
                            AddDropTableCommand:  Boolean;
                            ExportIndexes:        Boolean;
                            AddDropIndexCommand:  Boolean;
                            ExportData:           Boolean;
                            ExportBLOBFields:     Boolean;
                            UseBracketsForNames:  Boolean;
                            ExportForeignKeys:    Boolean
                        ): WideString;
var fk: WideString;
begin
  fk := '';
  Result := '';
  GetTableSQL(Result,fk,ExportStructure,AddDropTableCommand,ExportIndexes,
              AddDropIndexCommand,ExportData,ExportBLOBFields,
              UseBracketsForNames,ExportForeignKeys);
  if (ExportForeignKeys) then
   Result := Result + fk;
end; // ExportTableToSQL


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.InternalInitFieldDefs;
var
    i: Integer;
begin
 if (FFieldDefs <> nil) then
  FFieldDefs.Free;
 FFieldDefs := TSQLMemFieldDefs.Create;
 if (not FSettingProjection) then
  begin
   if (FVisibleFieldDefs <> nil) then
    FVisibleFieldDefs.Free;
   FVisibleFieldDefs := TSQLMemFieldDefs.Create;
  end;

{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemLocalCursor.InternalInitFieldDefs, TableData.FieldDefs.Count = '+
IntToStr(FTableData.FieldManager.FieldDefs.Count));
{$ENDIF}


 FFieldDefs.Assign(FTableData.FieldManager.FieldDefs);
 FFieldDefs.RecalcFieldOffsets;

 FieldValuesOffset := FFieldDefs[0].MemoryOffset;
 BookmarkOffset := FFieldDefs[FFieldDefs.Count-1].MemoryOffset +
                   FFieldDefs[FFieldDefs.Count-1].MemoryDataSize;
 KeyOffset := BookmarkOffset;
 KeyBufferSize := BookmarkOffset + sizeof(TSQLMemKeyBuffer);
 RecordSize := BookmarkOffset + SizeOf(TSQLMemBookmarkInfo);
 RecordBufferSize := RecordSize;
 CalculatedFieldsOffset := RecordSize;

 if (not FSettingProjection) then
  begin
   FVisibleFieldDefs.Assign(FTableData.FieldManager.FieldDefs);
   // create default fields order
   for i := 0 to VisibleFieldDefs.Count-1 do
    FVisibleFieldDefs[i].FieldNoReference := i;
  end;

 // Constraints...
 if (FConstraintDefs <> nil) then
   FConstraintDefs.Free;
 FConstraintDefs := TSQLMemConstraintDefs.Create;
 FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end; // InternalInitFieldDefs


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.OpenTableByFieldDefs(
                                    FieldDefs: TSQLMemFieldDefs;
                                    IndexDefs: TSQLMemIndexDefs;
                                    ConstraintDefs: TSQLMemConstraintDefs
                                   );
function IsTableDefsChanged: Boolean;
var i: Integer;
begin
 Result := False;
 // check FieldDefs
 if (FFieldDefs.Count <> FieldDefs.Count) then
   Result := True
 else
   for i := 0 to FieldDefs.Count-1 do
    if (GetTableNameCRC(FFieldDefs[i].Name) <> GetTableNameCRC(FieldDefs[i].Name)) or
      (FFieldDefs[i].AdvancedFieldType <> FieldDefs[i].AdvancedFieldType) or
      (FFieldDefs[i].FieldSize <> FieldDefs[i].FieldSize) then
     begin
      Result := True;
      break;
     end;
 // check IndexDefs
 if (not Result) then
  begin
    if (FIndexDefs.Count <> IndexDefs.Count) then
     Result := True
    else
     for i := 0 to IndexDefs.Count-1 do
      if (GetTableNameCRC(FIndexDefs[i].Name) <> GetTableNameCRC(IndexDefs[i].Name)) or
        (FIndexDefs[i].ColumnCount <> IndexDefs[i].ColumnCount) or
        (FIndexDefs[i].IndexType <> IndexDefs[i].IndexType) or
        (FIndexDefs[i].Primary <> IndexDefs[i].Primary) or
        (FIndexDefs[i].Unique <> IndexDefs[i].Unique) then
       begin
        Result := True;
        break;
       end;
  end; // IndexDefs
 // check ConstraintDefs
 if (not Result) then
  begin
    if (FConstraintDefs.Count <> ConstraintDefs.Count) then
     Result := True
    else
     for i := 0 to ConstraintDefs.Count-1 do
      if (GetTableNameCRC(FConstraintDefs[i].Name) <> GetTableNameCRC(ConstraintDefs[i].Name)) or
        (FConstraintDefs[i].ConstraintType <> ConstraintDefs[i].ConstraintType) then
       begin
        Result := True;
        break;
       end;
  end; // IndexDefs
end; // IsTableDefsChanged


var bCreateTable: Boolean;
    i:            Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('> TSQLMemLocalCursor.OpenTableByFieldDefs start'
+#13#10+'Table name = '+FTableName
+#13#10+'InMemory = '+BoolToStr(InMemory,True)
+#13#10+'Temporary = '+BoolToStr(Temporary,True)
);
if (FieldDefs = nil) then
 aaWriteToLog('FieldDefs = nil')
else
if (FieldDefs.Count <= 0) then
 aaWriteToLog('FieldDefs.Count = 0')
else
begin
 aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
 for i := 0 to FieldDefs.Count-1 do
  aaWriteToLog('i = '+IntToStr(i)+' FieldDefs[i].Name = '+FieldDefs[i].Name);
end;
try
{$ENDIF}
 if (FIsView) then
  Exit;
 FreeSavedPosition;
 if (not IsOpen) then
  begin
    FDatabaseData := TSQLMemLocalSession(Session).DatabaseData;
    if (InMemory or Temporary) then
       FTableData := FDatabaseData.FindTableData(Self)
    else
       FTableData := FDatabaseData.FindOrCreateTableData(Self);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
if (FTableData = nil) then
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs tabledata = nil')
else
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs tabledata = '+FTableData.TableName);
{$ENDIF}
    bCreateTable := (InMemory and (FieldDefs <> nil)) and
    // fixed in 5.30
//                    (IsDesignMode or (FTableData = nil)) and
                    ((FTableData = nil) and (FieldDefs.Count > 0))
                    ;

{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs bCreateTable = '+ BoolToStr(bCreateTable,True)
+#13#10+'FTableData = '+IntToHex(Integer(FTableData),8)
+#13#10+'InMemory = '+BoolToStr(InMemory,True)
+#13#10+'FieldDefs = '+IntToHex(Integer(FieldDefs),8)
+#13#10+'IsDesignMode = '+BoolToStr(IsDesignMode,True)
);
{$ENDIF}

    if (FTableData = nil) then
      begin
// modified in v.5
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs creating TableData!');
{$ENDIF}
        // added in v.5.60 to avoid memory leaks on not existing tables
        if (not bCreateTable) then
          if (not FDatabaseData.TableExists(FSession,FTableName)) then
           raise ESQLMemException.Create(12434,ErrorLTableDoesNotExist,[FTableName]);
        FTableData := FDatabaseData.CreateTableData(Self);
        if (bCreateTable) then
         begin
          bCreateTable := False;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs creating table #1...');
{$ENDIF}
          try
            FTableData.CreateTable(Self,FieldDefs,IndexDefs, ConstraintDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs creating table #1... OK');
{$ENDIF}
          except
            // fixed in 4.95
            FTableData.Free;
            FTableData := nil;
            raise;
          end;
         end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs TableData created!');
{$ENDIF}
      end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs opening tabledata...');
{$ENDIF}
    FTableData.OpenTable(Self);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs tabledata opened successfully!');
if (FieldDefs = nil) then
 aaWriteToLog('FieldDefs = nil')
else
if (FieldDefs.Count <= 0) then
 aaWriteToLog('FieldDefs.Count = 0')
else
begin
 aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
 for i := 0 to FieldDefs.Count-1 do
  aaWriteToLog('i = '+IntToStr(i)+' FieldDefs[i].Name = '+FieldDefs[i].Name);
end;
if (FFieldDefs = nil) then
 aaWriteToLog('FFieldDefs = nil')
else
if (FFieldDefs.Count <= 0) then
 aaWriteToLog('FFieldDefs.Count = 0')
else
begin
 aaWriteToLog('FFieldDefs.Count = '+IntToStr(FFieldDefs.Count));
 for i := 0 to FFieldDefs.Count-1 do
  aaWriteToLog('i = '+IntToStr(i)+' FFieldDefs[i].Name = '+FFieldDefs[i].Name);
end;
{$ENDIF}
    // fixed in v.5.30
    if (not bCreateTable) then
     bCreateTable := (InMemory and (FieldDefs <> nil)) and ((IsDesignMode and (FieldDefs.Count > 0)) or (FTableData = nil));
    if (bCreateTable) then
     begin
      // check if table structure was changed before opening table
      bCreateTable := IsTableDefsChanged;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs IsTableDefsChanged = '+BoolToStr(bCreateTable,True));
{$ENDIF}
      // if records exists - do not re-create table to avoid loosing data
      if (bCreateTable) then
       bCreateTable := (FTableData.GetRecordCount(Self,False) <= 0);
      if (bCreateTable) then
       begin
        FTableData.CloseTable(Self);
        try
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs creating table #1...');
{$ENDIF}
          FTableData.CreateTable(Self,FieldDefs,IndexDefs, ConstraintDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs creating table #2... OK');
{$ENDIF}
          FTableData.OpenTable(Self);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs creating table - opening #2... OK');
{$ENDIF}
        except
          // fixed in 4.95
          FTableData.Free;
          FTableData := nil;
          raise;
        end;
       end;
     end; // bCreateTable

     FirstPosition := True;
     LastPosition := False;
// moved to TSQLMemTableData in 4.90 - to avoid crash on multi-processor machines      
(*
     if (FIndexDefs <> nil) then
      FIndexDefs.Free;
     FIndexDefs := TSQLMemIndexDefs.Create;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs indexdefs = '+IntToStr(FTableData.IndexManager.IndexDefs.Count));
{$ENDIF}
     FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs indexdefs2 = '+IntToStr(FIndexDefs.Count));
{$ENDIF}
     if (FConstraintDefs <> nil) then
      FConstraintDefs.Free;
     FConstraintDefs := TSQLMemConstraintDefs.Create;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs constraints created');
{$ENDIF}
     FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs constraints assigned');
{$ENDIF}
*)
     if (FBLOBStreams <> nil) then
      FBLOBStreams.Free;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs blob streams destroyed');
{$ENDIF}
     FBLOBStreams := TList.Create;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs blob streams created');
{$ENDIF}
     if (RecordBitmap <> nil) then
      TSQLMemRecordBitmap(RecordBitmap).Free;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs bitmap destroyed');
{$ENDIF}
     RecordBitmap := TSQLMemRecordBitmap.Create(FTableData);
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs bitmap created');
{$ENDIF}

{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
     if (FSearchCache <> nil) then
      FSearchCache.Free;
     FSearchCache := TSQLMemScanSearchConditionCache.Create;
     FSearchOperation := lsoNone;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs search cache created');
{$ENDIF}
{$ENDIF}

     IsOpen := True;
     FDoNotCloseTableData := False;

{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TSQLMemLocalCursor.OpenTableByFieldDefs opened');
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalCursor_OpenTableByFieldDefs}
finally
aaWriteToLog('< TSQLMemLocalCursor.OpenTableByFieldDefs finish'
+#13#10+'Table name = '+FTableName);
if (FieldDefs = nil) then
 aaWriteToLog('FieldDefs = nil')
else
if (FieldDefs.Count <= 0) then
 aaWriteToLog('FieldDefs.Count = 0')
else
begin
 aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
 for i := 0 to FieldDefs.Count-1 do
  aaWriteToLog('i = '+IntToStr(i)+' FieldDefs[i].Name = '+FieldDefs[i].Name);
end;
if (FFieldDefs = nil) then
 aaWriteToLog('FFieldDefs = nil')
else
if (FFieldDefs.Count <= 0) then
 aaWriteToLog('FFieldDefs.Count = 0')
else
begin
 aaWriteToLog('FFieldDefs.Count = '+IntToStr(FFieldDefs.Count));
 for i := 0 to FFieldDefs.Count-1 do
  aaWriteToLog('i = '+IntToStr(i)+' FFieldDefs[i].Name = '+FFieldDefs[i].Name);
end;
end; // finally
{$ENDIF}
end;// OpenTable


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.OpenTable(aTableData: TSQLMemTableData);
begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.OpenTable(aTableData) start');
{$ENDIF}
 if (FIsView) then
  Exit;
 FreeSavedPosition;
 FTableData := aTableData;
 FirstPosition := True;
 LastPosition := False;
 if (FIndexDefs <> nil) then
  FIndexDefs.Free;
 FIndexDefs := TSQLMemIndexDefs.Create;
 FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
 if (FConstraintDefs <> nil) then
  FConstraintDefs.Free;
 FConstraintDefs := TSQLMemConstraintDefs.Create;
 FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
 if (FBLOBStreams <> nil) then
  FBLOBStreams.Free;
 FBLOBStreams := TList.Create;
 InternalInitFieldDefs;
 if (RecordBitmap <> nil) then
  TSQLMemRecordBitmap(RecordBitmap).Free;
 RecordBitmap := TSQLMemRecordBitmap.Create(FTableData);
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 if (FSearchCache <> nil) then
  FSearchCache.Free;
 FSearchCache := TSQLMemScanSearchConditionCache.Create;
 FSearchOperation := lsoNone;
{$ENDIF}
 IsOpen := True;
 FDoNotCloseTableData := True;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.OpenTable(aTableData) finish');
{$ENDIF}
end; // OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.CloseTable;
var bTemp: Boolean;
begin
 bTemp := false;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable start');
{$ENDIF}
 FreeSavedPosition;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 0');
{$ENDIF}
   if (FTempRecordBuffer <> nil) then
    begin
     FreeRecordBuffer(FTempRecordBuffer);
     FTempRecordBuffer := nil;
    end;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 00');
{$ENDIF}
 if (FTableData <> nil) then
  begin
   bTemp := (FTableData is TSQLMemTemporaryTableData) and (not FDoNotCloseTableData);
   if (not FDoNotCloseTableData) then
    begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 01');
{$ENDIF}
     FTableData.CloseTable(Self);
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 02');
{$ENDIF}
     if (FTemporary) then
      FTableData := nil;
    end;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 03');
{$ENDIF}
// commented in v.4.95 - otherwise memory table cannot be created by SQL -
// it will be destroyed immediately after create table by TempCursor.Free
{
   if (IsDesignMode) and (FInMemory) and (FTableData <> nil) and (FTableData.CursorList.Count <= 0) then
     FTableData.DeleteTable(Session,True)
   else
}
     if (not FTemporary) then
       FTableData.FreeIfNoSessionsConnected;
     FTableData := nil;
  end;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 1');
{$ENDIF}
 if (RecordBitmap <> nil) then
  TSQLMemRecordBitmap(RecordBitmap).Free;
 RecordBitmap := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 2');
{$ENDIF}
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 if (FSearchCache <> nil) then
  FreeAndNil(FSearchCache);
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 2.1');
{$ENDIF}
 if (FilterExpression <> nil) then
  TSQLMemExpression(FilterExpression).Free;
 FilterExpression := nil;
 if (FSQLFilterExpression <> nil) then
  TSQLMemExpression(FSQLFilterExpression).Free;
 FSQLFilterExpression := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 3');
{$ENDIF}
 if (FFieldDefs <> nil) then
   FFieldDefs.Free;
 FFieldDefs := nil;
 if (not FSettingProjection) then
  begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 4');
{$ENDIF}
   if (FVisibleFieldDefs <> nil) then
    FVisibleFieldDefs.Free;
   FVisibleFieldDefs := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 44');
{$ENDIF}
  end;
 if (FIndexDefs <> nil) then
   FIndexDefs.Free;
 FIndexDefs := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable 5');
{$ENDIF}
 ClearBLOBStreams(False);
 if (FBLOBStreams <> nil) then
   FBLOBStreams.Free;
 FBLOBStreams := nil;
 // Constraints
 if (FConstraintDefs <> nil) then
   FConstraintDefs.Free;
 FConstraintDefs := nil;
if (FIsClientCursor) then
 if (FTemporary) then
  if (bTemp) then
   if (FSession <> nil) then
    FSession.Free;
FIsOpen := False;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TSQLMemLocalCursor.CloseTable finish');
{$ENDIF}
end; // CloseTable


//------------------------------------------------------------------------------
// GetIndexDefs
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetIndexDefs: TSQLMemIndexDefs;
begin
  if (FIndexDefs <> nil) then
   FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  Result := inherited GetIndexDefs;
end;// GetIndexDefs


//------------------------------------------------------------------------------
// add index
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.AddIndex(IndexDef: TSQLMemIndexDef);
begin
  if (FIndexDefs.GetIndexDefByName(IndexDef.Name) <> nil) then
   raise ESQLMemException.Create(20022, ErrorAIndexAlreadyExists, [IndexDef.Name]);
  FTableData.AddIndex(IndexDef, Self);
  FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  //if (not FTemporary) then
  FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end;// AddIndex


//------------------------------------------------------------------------------
// DeleteIndex
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DeleteIndex(Name: WideString);
begin
  if (FIndexDefs.GetIndexDefByName(Name) = nil) then
   raise ESQLMemException.Create(20021, ErrorACannotDeleteIndex, [Name]);
  // Delete Index
  FTableData.DeleteIndex(FIndexDefs.GetIndexDefByName(Name).ObjectID, Self);
  FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  //if (not FTemporary) then
  FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end;// DeleteIndex


//------------------------------------------------------------------------------
// DeleteAllIndexes
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DeleteAllIndexes;
begin
  FTableData.DeleteAllIndexes(Self);
  FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  //if (not FTemporary) then
   FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end;// DeleteAllIndexes


//------------------------------------------------------------------------------
// return index name of the index or '' if not found
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.FindIndex(FieldNamesList, AscDescList, CaseSensitivityList: TSQLMemWideStringList): WideString;
begin
  Result := FTableData.FindIndex(Self, FieldNamesList, AscDescList, CaseSensitivityList);
end; // FindIndex


//------------------------------------------------------------------------------
// return true if temporary table
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.IsTemporaryTable: Boolean;
begin
  if (FTableData <> nil) then
   Result := FTableData.Temporary;
end; // IsTemporaryTable


//------------------------------------------------------------------------------
// return true if memory table
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.IsMemoryTable: Boolean;
begin
  Result := False;
  if (FTableData <> nil) then
   Result := FTableData.InMemory;
end; // IsMemoryTable


//------------------------------------------------------------------------------
// return true if current record exists
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.IsRecordExists: Boolean;
begin
  Result := FTableData.IsRecordExists(Self);
end; // IsRecordExists


//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetRecordBuffer(
              GetRecordMode:  TSQLMemGetRecordMode
              ): TSQLMemGetRecordResult;
begin
  Result := FTableData.GetRecordBuffer(Self,GetRecordMode);
  if (Result = grrOK) then
   GetCalcFieldsAndBookMarkData;
end; // GetRecordBuffer


//------------------------------------------------------------------------------
// returns record count
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetRecordCount: TSQLMemRecordNo;
begin
  Result := FTableData.GetRecordCount(Self);
end; // GetRecordCount


//------------------------------------------------------------------------------
// go to record
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.SetRecNo(Value: Int64);
begin
  FTableData.SetRecNo(Self,Value);
end; // SetRecNo


//------------------------------------------------------------------------------
// return current record number
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetRecNo: Int64;
begin
  Result := FTableData.GetRecNo(Self);
end; // GetRecNo


//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.InternalEdit;
begin
  ErrorCode := SQLMem_ERR_OK;
  if (FTableData is TSQLMemTemporaryTableData) then
    ErrorCode := SQLMem_ERR_UPDATE_RECORD_PROHIBITED
  else
    FTableData.EditRecord(Self);
end; // InternalEdit


//------------------------------------------------------------------------------
// cancels updates
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.InternalCancel(ToInsert: Boolean);
begin
  ErrorCode := SQLMem_ERR_OK;
  if (FTableData is TSQLMemTemporaryTableData) then
    ErrorCode := SQLMem_ERR_CANCEL_PROHIBITED
  else
    begin
     ClearBLOBStreams(True);
     FTableData.CancelRecord(Self,ToInsert);
    end;
end; // InternalCancel


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.InternalPost(ToInsert: Boolean);
var TempCursor: TSQLMemCursor;
begin
 ErrorCode := SQLMem_ERR_OK;
 ErrorMessage := '';
 TempCursor := Self;
 ClearBLOBStreams(True);
 if (ToInsert) then
  begin
   // insert
   try
     if (not FTableData.InsertRecord(TempCursor)) then
      begin
       ErrorCode := SQLMem_ERR_INSERT_RECORD;
       ErrorMessage := Format(ErrorLAddingRecord,
        [FTableName,
         BoolToStr(InMemory),
         BoolToStr(Temporary)]);
      end;
   except
    on e: Exception do
     begin
       if (ErrorCode <> SQLMem_ERR_CONSTRAINT_VIOLATED) then
         ErrorCode := SQLMem_ERR_INSERT_RECORD;
       ErrorMessage := Format(ErrorLAddingRecord+#13#10+e.Message,
        [FTableName,
         BoolToStr(InMemory),
         BoolToStr(Temporary)]);
     end;
   end;
   GetCalcFieldsAndBookMarkData(True);
  end // insert
 else
  begin
   // update
   Move(PAnsiChar(FCurrentRecordBuffer + BookmarkOffset)^,
    CurrentRecordID,sizeof(TSQLMemRecordID));
   ErrorCode := SQLMem_ERR_OK;
   try
     if (not FTableData.UpdateRecord(TempCursor)) then
      begin
       ErrorCode := SQLMem_ERR_Update_RECORD;
       ErrorMessage := ErrorLUpdatingRecord;
      end;
   except
    on e: Exception do
     begin
      if (ErrorCode <> SQLMem_ERR_CONSTRAINT_VIOLATED) then
       ErrorCode := SQLMem_ERR_Update_RECORD;
      ErrorMessage := ErrorLUpdatingRecord+e.Message;
     end;
   end;
  end; // update;
end; // InternalPost


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.InternalDelete;
begin
 FErrorMessage := '';
 if (FTableData is TSQLMemTemporaryTableData) then
  ErrorCode := SQLMem_ERR_DELETE_RECORD_PROHIBITED
 else
  begin
   // delete
   Move(PAnsiChar(FCurrentRecordBuffer + BookmarkOffset)^,
    CurrentRecordID,sizeof(TSQLMemRecordID));
   FErrorCode := SQLMem_ERR_OK;
   try
     if (not FTableData.DeleteRecord(Self)) then
       FErrorCode := SQLMem_ERR_DELETE_RECORD;
//     Move(CurrentRecordID,FDeleteCurrentRecordID,SizeOf(TSQLMemRecordID));
   except
     on e: Exception do
      begin
        FErrorCode := SQLMem_ERR_DELETE_RECORD;
        FErrorMessage := e.Message;
      end;
   end;
  end;
end; // InternalDelete


//------------------------------------------------------------------------------
// delete all visible records
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DeleteVisibleRecords;
begin
  FTableData.DeleteVisibleRecords(Self);
end; // DeleteVisibleRecords


//------------------------------------------------------------------------------
// update visible records
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.UpdateVisibleRecords(FieldNames:   TSQLMemWideStringList;
                                               values:       array of TSQLMemVariant;
                                               SkipFKCheck:  Boolean = False
                                               );
begin
  FTableData.UpdateVisibleRecords(Self,FieldNames,values,SkipFKCheck);
end; // UpdateVisibleRecords

//------------------------------------------------------------------------------
// disable record bitmap
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DisableRecordBitmap;
begin
 if (RecordBitmap <> nil) then
  TSQLMemRecordBitmap(RecordBitmap).Active := False;
 {$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 FSearchCache.Clear;
 {$ENDIF}
end; // DisableRecordBitmap


//------------------------------------------------------------------------------
// apply projection
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.ApplyProjection(FieldNamesList, AliasList: TSQLMemWideStringList);
var i,j: Integer;
begin
  if (FieldNamesList.Count <> AliasList.Count) then
    raise ESQLMemException.Create(10321,ErrorLDifferentListsLength,
            [FieldNamesList.Count,AliasList.Count]);
  if (FieldNamesList.Count = 0) then
    raise ESQLMemException.Create(10322,ErrorLNoFieldsInProjection);
  FVisibleFieldDefs.Clear;
  for i := 0 to FieldNamesList.Count -1 do
   begin
    j := FFieldDefs.GetDefNumberByName(FieldNamesList[i]);
    if (j < 0) then
      raise ESQLMemException.Create(10323,ErrorLCannotFindField,[FieldNamesList[i]]);
    FVisibleFieldDefs.AddCreated.Assign(FFieldDefs[j]);
    FVisibleFieldDefs[FVisibleFieldDefs.Count-1].FieldNoReference := j;
    if (AliasList[i] <> '') then
     FVisibleFieldDefs[FVisibleFieldDefs.Count-1].Name := AliasList[i];
   end;
end;


//------------------------------------------------------------------------------
// activate filters
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.ActivateFilters(
                          FilterText:      WideString;
                          CaseInsensitive: Boolean;
                          PartialKey:      Boolean
                        );
begin
  if (FilterExpression <> nil) then
    TSQLMemExpression(FilterExpression).Free;
  FilterExpression := TSQLMemExpression.Create(FSession,nil);
  TSQLMemExpression(FilterExpression).ParseForFilter(Self,FilterText,CaseInsensitive,PartialKey);
  DisableRecordBitmap;
end; // ActivateFilters


//------------------------------------------------------------------------------
// deactivate filters
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.DeactivateFilters;
begin
  if (FSQLFilterExpression <> nil) then
   Exit;
  if (FilterExpression <> nil) then
    TSQLMemExpression(FilterExpression).Free;
  FilterExpression := nil;
  DisableRecordBitmap;
end; // DeactivateFilters


//------------------------------------------------------------------------------
// locate
//------------------------------------------------------------------------------
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
function TSQLMemLocalCursor.Locate(
                const KeyFields: WideString;
                const KeyValues: Variant;
                CaseInsensitive: Boolean;
                PartialKey:      Boolean
               ): Boolean;
begin
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time6);
{$ENDIF}
  Result := FTableData.Locate(Self,KeyFields,KeyValues,CaseInsensitive,PartialKey);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time6);
{$ENDIF}
end; // Locate
{$ELSE}
function TSQLMemLocalCursor.Locate(
                const KeyFields: WideString;
                const KeyValues: Variant;
                CaseInsensitive: Boolean;
                PartialKey:      Boolean
               ): Boolean;
var SearchExpression: TSQLMemExpression;
begin
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time6);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time28);
{$ENDIF}
  SearchExpression := TSQLMemExpression.Create(FSession,nil);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time28);
{$ENDIF}
  try
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time7);
{$ENDIF}
    SearchExpression.ParseForLocate(Self,KeyFields,KeyValues,CaseInsensitive,PartialKey);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time7);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time8);
{$ENDIF}
    Result := FTableData.Locate(Self,SearchExpression);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time8);
{$ENDIF}
  finally
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time29);
{$ENDIF}
    SearchExpression.Free;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time29);
{$ENDIF}
  end;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time6);
{$ENDIF}
end; // Locate
{$ENDIF}

//------------------------------------------------------------------------------
// find key
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.FindKey(SearchCondition: TSQLMemSearchCondition): Boolean;
begin
  Result := FTableData.FindKey(Self,SearchCondition);
end; // FindKey


//------------------------------------------------------------------------------
// reset range
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.ResetRange;
begin
  RangeStartBuffer := nil;
  RangeEndBuffer := nil;
  DisableRecordBitmap;
end; // ResetRange


//------------------------------------------------------------------------------
// apply range
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.ApplyRange(
                          StartBuffer, EndBuffer: TSQLMemRecordBuffer;
                          StartKeyFieldCount:     Integer;
                          EndKeyFieldCount:       Integer;
                          StartExclusive:         Boolean;
                          EndExclusive:           Boolean
                        );
begin
  RangeStartBuffer := StartBuffer;
  RangeEndBuffer := EndBuffer;
  RangeStartKeyFieldCount := StartKeyFieldCount;
  RangeEndKeyFieldCount := EndKeyFieldCount;
  RangeStartExclusive := StartExclusive;
  RangeEndExclusive := EndExclusive;
  DisableRecordBitmap;
end; // ApplyRange


//------------------------------------------------------------------------------
// set SQL Filter
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.SetSQLFilter(FilterExpr: TObject);
begin
  SQLFilterExpression := FilterExpr;
  if SQLFilterExpression <> nil then
    TSQLMemExpression(SQLFilterExpression).AssignCursor(self);
end; // SetSQLFilter



//------------------------------------------------------------------------------
// create blob stream
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.InternalCreateBlobStream(
              ToInsert: Boolean;
              FieldNo:  Integer;
              OpenMode: TSQLMemBLOBOpenMode
              ):TSQLMemStream;
var FieldNumber:      Integer;
    i:                Integer;
    LocalBLOBStream:  TSQLMemLocalBLOBStream;
begin
{
 if (FIsProjectionSet) then
  begin
    if (FieldNo >= FFieldDefs.Count) then
     raise ESQLMemException.Create(11614,ErrorLInvalidFieldNumber,
      [FieldNo,FFieldDefs.Count]);
    if (FBLOBStreams = nil) then
     raise ESQLMemException.Create(11615,ErrorLNilPointer);
    FieldNumber := FieldNo;
  end
 else
}
  begin
    if (FieldNo >= FVisibleFieldDefs.Count) then
     raise ESQLMemException.Create(10110,ErrorLInvalidFieldNumber,
      [FieldNo,FVisibleFieldDefs.Count]);
    if (FBLOBStreams = nil) then
     raise ESQLMemException.Create(10113,ErrorLNilPointer);
    FieldNumber := FVisibleFieldDefs.Items[FieldNo].FieldNoReference;
  end;
 // find existing blob stream
 if ((OpenMode = bomReadWrite) or (OpenMode = bomWrite)) then
  for i := 0 to FBLOBStreams.Count -1 do
   begin
    LocalBLOBStream := TSQLMemLocalBLOBStream(FBLOBStreams.Items[i]);
    if (LocalBLOBStream = nil) then
      raise ESQLMemException.Create(10114,ErrorLNilPointer);
    if (LocalBLOBStream.FFieldNo = FieldNumber) then
     if ((LocalBLOBStream.OpenMode = bomReadWrite) or
         (LocalBLOBStream.OpenMode = bomWrite)) then
      raise ESQLMemException.Create(10115,ErrorLBLOBFieldAlreadyOpened,[FieldNumber,
        FFieldDefs.Items[FieldNumber].Name]);
   end;

 Result := FTableData.InternalCreateBlobStream(Self,ToInsert,FieldNumber,OpenMode);
 if (Result <> nil) then
  FBLOBStreams.Add(Result);
end; // InternalCreateBlobStream


//------------------------------------------------------------------------------
// close blob
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.InternalCloseBLOB(FieldNo: Integer);
var FieldNumber:       Integer;
    i:                 Integer;
    LocalBLOBStream:   TSQLMemLocalBLOBStream;
begin
 if (FieldNo >= FVisibleFieldDefs.Count) then
  raise ESQLMemException.Create(10118,ErrorLInvalidFieldNumber,
    [FieldNo,FVisibleFieldDefs.Count]);
 if (FBLOBStreams = nil) then
  raise ESQLMemException.Create(10119,ErrorLNilPointer);
 FieldNumber := FVisibleFieldDefs.Items[FieldNo].FieldNoReference;

 i := 0;
 while (i < FBLOBStreams.Count) do
  begin
   LocalBLOBStream := TSQLMemLocalBLOBStream(FBLOBStreams.Items[i]);
   if (LocalBLOBStream = nil) then
      raise ESQLMemException.Create(10120,ErrorLNilPointer);
   if (LocalBLOBStream.FieldNo = FieldNumber) then
    begin
     if ((LocalBLOBStream.OpenMode = bomWrite) or
       (LocalBLOBStream.OpenMode = bomReadWrite)) then
      begin
        FTableData.WriteBLOBFieldToRecordBuffer(Self,FieldNumber,LocalBLOBStream);
      end;

     if (LocalBLOBStream.UserBLOBStream <> nil) then
          LocalBLOBStream.UserBLOBStream.Free;
     LocalBLOBStream.Free;
     FBLOBStreams.Delete(i);
     Dec(i);
    end;
   Inc(i);
  end;
end; // InternalCloseBLOB


//------------------------------------------------------------------------------
// clear blob streams
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.ClearBLOBStreams(WriteOnly: Boolean = False);
var i:                  Integer;
    LocalBLOBStream:    TSQLMemLocalBLOBStream;
begin
 i := 0;
 if (FBLOBStreams <> nil) then
   while (i < FBLOBStreams.Count) and (FBLOBStreams.Count > 0) do
    begin
     LocalBLOBStream := TSQLMemLocalBLOBStream(FBLOBStreams.Items[i]);
     if (LocalBLOBStream  = nil) then
      raise ESQLMemException.Create(10121,ErrorLNilPointer);
     if ((Not WriteOnly) or
         ((WriteOnly) and
          ((LocalBLOBStream.OpenMode = bomWrite) or
           (LocalBLOBStream.OpenMode = bomReadWrite)))) then
       begin
        if (LocalBLOBStream.UserBLOBStream <> nil) then
          LocalBLOBStream.UserBLOBStream.Free
        else
         begin
          LocalBLOBStream.Free;
          FBLOBStreams.Delete(i);
         end;
        Dec(i);
       end;
     Inc(i);
    end;
end; // ClearBLOBStreams


//------------------------------------------------------------------------------
//LastAutoincValue
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.LastAutoincValue(FieldNo: Integer): Int64;
begin
  Result := FTableData.LastAutoincValue(FieldNo, FSession);
end;//LastAutoincValue


//------------------------------------------------------------------------------
//SetLastAutoincValue
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.SetLastAutoincValue(Value: Int64; FieldNo: Integer);
begin
  FTableData.SetLastAutoincValue(Value, FieldNo, Self);
end;//SetLastAutoincValue


//------------------------------------------------------------------------------
// return table state
//------------------------------------------------------------------------------
function TSQLMemLocalCursor.GetTableState: TSQLMemTableState;
begin
{$IFNDEF SQLMEMTABLE}
  if (FTableData is TSQLMemDiskTableData) then
   Result := TSQLMemDiskTableData(FTableData).LoadTableState
  else
{$ENDIF}  
   Result := FTableData.TableState;
end; // TSQLMemTableState


//------------------------------------------------------------------------------
// lock table for read
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.LockTable(bWriteMode: Boolean);
begin
  FTableData.LockTable(bWriteMode,Session,11892,True);
end; // LockTableForRead;


//------------------------------------------------------------------------------
// unlock table for read
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.UnlockTable(bWriteMode: Boolean);
begin
  FTableData.UnlockTable(bWriteMode,Session,True);
end; // UnlockTableForRead;


{
//------------------------------------------------------------------------------
// save current position
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.SaveCurrentPosition;
begin
  FreeSavedPosition;
  if (FCurrentRecordBuffer <> nil) then
   begin
    FSavedRecordBuffer := AllocateRecordBuffer;
    Move(FCurrentRecordBuffer^, FSavedRecordBuffer^,RecordBufferSize);
   end;
  FSavedPosition := SavePosition;
end; // SaveCurrentPosition


//------------------------------------------------------------------------------
// restore saved position
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.RestoreSavedPosition;
begin
  if (FSavedPosition <> nil) then
   begin
    RestorePosition(FSavedPosition);
    if (FSavedRecordBuffer <> nil) then
     begin
      if (FCurrentRecordBuffer <> nil) then
       Move(FSavedRecordBuffer^,FCurrentRecordBuffer^,RecordBufferSize)
     end
    else
     FCurrentRecordBuffer := nil;
    FreeSavedPosition;
   end;
end; // RestoreSavedPosition
}

//------------------------------------------------------------------------------
// free saved position
//------------------------------------------------------------------------------
procedure TSQLMemLocalCursor.FreeSavedPosition;
begin
  if (FSavedPosition <> nil) then
   begin
    FreePosition(FSavedPosition);
    if (FSavedRecordBuffer <> nil) then
     FreeRecordBuffer(FSavedRecordBuffer);
   end;
end; // FreeSavedPosition


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// FindDatabaseData
//------------------------------------------------------------------------------
function TSQLMemLocalSession.FindDatabaseData: TSQLMemDatabaseData;
var
  DBDatas: TList;
  i: integer;
begin
  DBDatas := DBDataList.LockList;
  Result := nil;
  try
    if (Temporary) then
      Result := SQLMemFindDatabaseData(False,True,SQLMemTemporaryDatabaseName,'')
    else
    if (InMemory) then
      Result := SQLMemFindDatabaseData(True,False,DatabaseName,'')
    else
      Result := SQLMemFindDatabaseData(False,False,DatabaseFileName,DatabaseFileNameUnicode);
  finally
    DBDataList.UnlockList;
  end;
end;// FindDatabaseData


//------------------------------------------------------------------------------
// create new database data and add it to global list
//------------------------------------------------------------------------------
function TSQLMemLocalSession.CreateDatabaseData: TSQLMemDatabaseData;
var
  DBDatas: TList;
begin
  if (InMemory) then
   begin
    Result := TSQLMemMemoryDatabaseData.Create;
    TSQLMemMemoryDatabaseData(Result).DatabaseName := DatabaseFileName;
   end
  else
   begin
{$IFDEF DISK_ENGINE}
    Result := TSQLMemDiskDatabaseData.Create;
    TSQLMemDiskDatabaseData(Result).DatabaseName := DatabaseFileName;
    TSQLMemDiskDatabaseData(Result).Options := Options;
    TSQLMemDiskDatabaseData(Result).CryptoParams := CryptoParams;
    TSQLMemDiskDatabaseData(Result).LockParams := LockParams;
{$ENDIF}
   end;
  DBDatas := DBDataList.LockList;
  DBDatas.Add(Result);
  DBDataList.UnlockList;
end;// CreateDatabaseData


//------------------------------------------------------------------------------
// find or create database data
//------------------------------------------------------------------------------
function TSQLMemLocalSession.FindOrCreateDatabaseData: TSQLMemDatabaseData;
begin
  DBDataList.LockList;
  try
    Result := FindDatabaseData;
    if (Result = nil) then
      Result := CreateDatabaseData;
  finally
    DBDataList.UnlockList;
  end;
end;// FindOrCreateDatabaseData


//------------------------------------------------------------------------------
// db connected?
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetConnected: Boolean;
begin
  Result := (FDatabaseData <> nil);
end;// GetConnected


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.SetConnected(Value: boolean);
begin
 if Value <> GetConnected then
  begin
    DBDataList.LockList;
    try
     if Value then
      begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.SetConnected(true) before set FTransaction to nil. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
        FTransaction := nil;
        FDatabaseData := FindOrCreateDatabaseData;
        try
          FDatabaseData.ConnectSession(Self);
        except
          FDatabaseData.FreeIfNoSessionsConnected;// implemented for disk DB only
          FDatabaseData := nil;
          raise;
        end;
      end
     else
      begin
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TSQLMemLocalSession.SetConnected(False) starting...'+
              ', SessionID = '+IntToStr(FSessionID)+
              ', DatabaseData = '+IntToStr(Integer(FDatabaseData))+
              ', Transaction = '+IntToStr(Integer(FTransaction)));
 {$ENDIF}
        if (FDatabaseData <> nil) then
         begin
          if (FTransaction <> nil) then
           begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TSQLMemLocalSession.SetConnected(false) before Rollback. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
            FTransaction.Rollback;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TSQLMemLocalSession.SetConnected(false) after Rollback. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
            FTransaction.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TSQLMemLocalSession.SetConnected(false) after destroy. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
            FTransaction := nil;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TSQLMemLocalSession.SetConnected(false) after set nil. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
           end;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TSQLMemLocalSession.SetConnected(False) disconnecting session...'+
              ', SessionID = '+IntToStr(FSessionID)+
              ', DatabaseData.DatabaseName = '+IntToStr(Integer(FDatabaseData.DatabaseName))+
              ', Transaction = '+IntToStr(Integer(FTransaction)));
 {$ENDIF}
          FDatabaseData.DisconnectSession(Self);
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TSQLMemLocalSession.SetConnected(False) disconnecting session... OK'+
              ', DatabaseData = '+IntToStr(Integer(FDatabaseData))+
              ', Transaction = '+IntToStr(Integer(FTransaction)));
 {$ENDIF}
          FDatabaseData.FreeIfNoSessionsConnected;// implemented for disk DB only
          FDatabaseData := nil;
         end;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TSQLMemLocalSession.SetConnected(False) finished'+
              ', DatabaseData = '+IntToStr(Integer(FDatabaseData))+
              ', Transaction = '+IntToStr(Integer(FTransaction)));
 {$ENDIF}
      end;
    finally
     DBDataList.UnlockList;
    end;
  end;
end;// SetConnected


//------------------------------------------------------------------------------
// check if database exists
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetDatabaseExists: Boolean;
begin
  // changed in v.4.90
  Result := True;
  if (FInMemory) then
   Result := (FindDatabaseData <> nil)
  else
   Result := SQLMemFileExists(FDatabaseFileName,FDatabaseFileNameUnicode);
end; // GetDatabaseExists


//------------------------------------------------------------------------------
// create database
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.CreateDatabase;
begin
  DBDataList.LockList;
  try
    if (FindDatabaseData <> nil) then
      raise ESQLMemException.Create(20092, ErrorADatabaseAlreadyOpen);
    FDatabaseData := CreateDatabaseData;
    try
      FDatabaseData.CreateDatabase(Self);
    finally
      FDatabaseData.FreeIfNoSessionsConnected;// implemented for disk DB only
      FDatabaseData := nil;
    end;
  finally
    DBDataList.UnlockList;
  end;
end;// CreateDatabase


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.FlushFileBuffers;
begin
  if (FDatabaseData = nil) then
    raise ESQLMemException.Create(11235,ErrorLNilPointer);
  FDatabaseData.FlushFileBuffers;  
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// return database format version
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetFormatVersion: Double;
begin
 DBDataList.LockList;
 try
  if (FDatabaseData = nil) then
   FDatabaseData := FindOrCreateDatabaseData;
  Result := FDatabaseData.GetFormatVersion(Self);
 finally
   DBDataList.UnlockList;
 end;
end;// GetFormatVersion


//------------------------------------------------------------------------------
// get count of free pages
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetFreePageCount: Integer;
begin
 DBDataList.LockList;
 try
  if (FDatabaseData = nil) then
   FDatabaseData := FindOrCreateDatabaseData;
  Result := FDatabaseData.GetFreePageCount(Self);
 finally
   DBDataList.UnlockList;
 end;
end;// GetFreePageCount


//------------------------------------------------------------------------------
// get total count of pages
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetTotalPageCount: Integer;
begin
 DBDataList.LockList;
 try
  if (FDatabaseData = nil) then
   FDatabaseData := FindOrCreateDatabaseData;
  Result := FDatabaseData.GetTotalPageCount(Self);
 finally
   DBDataList.UnlockList;
 end;
end;// GetTotalPageCount


//------------------------------------------------------------------------------
// return true if database is encrypted
//------------------------------------------------------------------------------
function TSQLMemLocalSession.IsDatabaseEncrypted: Boolean;
var DBDataNil: Boolean;
    FreeDB:    Boolean;
begin
 DBDataList.LockList;
 try
  DBDataNil := (FDatabaseData = nil);
  if (DBDataNil) then
   begin
    FDatabaseData := FindDatabaseData;
    FreeDB := (FDatabaseData = nil);
    if (FreeDB) then
     FDatabaseData := CreateDatabaseData;
   end;
  try
    Result := FDatabaseData.IsDatabaseEncrypted(Self);
  finally
    if (DBDataNil) then
     begin
      if (FreeDB) then
        FDatabaseData.Free;
      FDatabaseData := nil;
     end;
  end;
 finally
   DBDataList.UnlockList;
 end;
end; // IsDatabaseEncrypted


//------------------------------------------------------------------------------
// return true if database is encrypted by password or by key
//------------------------------------------------------------------------------
function TSQLMemLocalSession.IsDatabaseEncryptedByPassword: Boolean;
var DBDataNil: Boolean;
    FreeDB:    Boolean;
begin
 DBDataList.LockList;
 try
  DBDataNil := (FDatabaseData = nil);
  if (DBDataNil) then
   begin
    FDatabaseData := FindDatabaseData;
    FreeDB := (FDatabaseData = nil);
    if (FreeDB) then
     FDatabaseData := CreateDatabaseData;
   end;
  try
    Result := FDatabaseData.IsDatabaseEncryptedByPassword(Self);
  finally
    if (DBDataNil) then
     begin
      if (FreeDB) then
        FDatabaseData.Free;
      FDatabaseData := nil;
     end;
  end;
 finally
   DBDataList.UnlockList;
 end;
end; // IsDatabaseEncryptedByPassword


//------------------------------------------------------------------------------
// makes Exe database from adb file
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.MakeExeDatabase(ExeFileName, ExeDatabaseFileName: WideString);
var DBDataNil: Boolean;
    FreeDB:    Boolean;
begin
 DBDataList.LockList;
 try
  DBDataNil := (FDatabaseData = nil);
  if (DBDataNil) then
   begin
    FDatabaseData := FindDatabaseData;
    FreeDB := (FDatabaseData = nil);
    if (FreeDB) then
     FDatabaseData := CreateDatabaseData;
   end;
  try
    FDatabaseData.MakeExeDatabase(Self,ExeFileName,ExeDatabaseFileName);
  finally
    if (DBDataNil) then
     begin
      if (FreeDB) then
        FDatabaseData.Free;
      FDatabaseData := nil;
     end;
  end;
 finally
   DBDataList.UnlockList;
 end;
end; // MakeExeDatabase


//------------------------------------------------------------------------------
// removes database file from executable database file
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.RemoveDatabaseFromExe;
var DBDataNil: Boolean;
    FreeDB:    Boolean;
begin
 DBDataList.LockList;
 try
  DBDataNil := (FDatabaseData = nil);
  if (DBDataNil) then
   begin
    FDatabaseData := FindDatabaseData;
    FreeDB := (FDatabaseData = nil);
    if (FreeDB) then
     FDatabaseData := CreateDatabaseData;
   end;
  try
    DatabaseData.RemoveDatabaseFromExe(Self);
  finally
    if (DBDataNil) then
     begin
      if (FreeDB) then
        FDatabaseData.Free;
      FDatabaseData := nil;
     end;
  end;
 finally
   DBDataList.UnlockList;
 end;
end; // RemoveDatabaseFromExe


//------------------------------------------------------------------------------
// returns true if this file is an SQLMemTable database
//------------------------------------------------------------------------------
function TSQLMemLocalSession.IsSQLMemTableDatabaseFile: Boolean;
var DBDataNil: Boolean;
    FreeDB:    Boolean;
begin
 DBDataList.LockList;
 try
  DBDataNil := (FDatabaseData = nil);
  if (DBDataNil) then
   begin
    FDatabaseData := FindDatabaseData;
    FreeDB := (FDatabaseData = nil);
    if (FreeDB) then
     FDatabaseData := CreateDatabaseData;
   end;
  try
    Result := FDatabaseData.IsSQLMemTableDatabaseFile(Self);
  finally
    if (DBDataNil) then
     begin
      if (FreeDB) then
        FDatabaseData.Free;
      FDatabaseData := nil;
     end;
  end;
 finally
   DBDataList.UnlockList;
 end;
end; // IsSQLMemTableDatabaseFile


//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TSQLMemLocalSession.IsCryptoParamsValid: Boolean;
var DBDataNil: Boolean;
    FreeDB:    Boolean;
begin
 DBDataList.LockList;
 try
  DBDataNil := (FDatabaseData = nil);
  if (DBDataNil) then
   begin
    FDatabaseData := FindDatabaseData;
    FreeDB := (FDatabaseData = nil);
    if (FreeDB) then
     FDatabaseData := CreateDatabaseData;
   end;
  try
    Result := FDatabaseData.IsCryptoParamsValid(Self);
  finally
    if (DBDataNil) then
     begin
      if (FreeDB) then
        FDatabaseData.Free;
      FDatabaseData := nil;
     end;
  end;
 finally
   DBDataList.UnlockList;
 end;
end; // IsCryptoParamsValid


//------------------------------------------------------------------------------
// get list of database tables
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.GetTablesList(List: TSQLMemWideStringList);
begin
  //FDatabaseData := FindOrCreateDatabaseData;
  if (FDatabaseData <> nil) then
    FDatabaseData.GetTablesList(Self,List);
end;// GetTablesList


//------------------------------------------------------------------------------
// return information about all tables
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetTablesInfo(SortByTableName: Boolean): TSQLMemTableInfoArray;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetTablesInfo(SortByTableName)
  else
    Result := nil;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// return table state  or 0 if not found
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetTableState(TableName: WideString): TSQLMemTableState;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetTableState(TableName)
  else
    FillChar(Result,SizeOf(Result),$00);
end; // GetTableState


//------------------------------------------------------------------------------
// TableExists
//------------------------------------------------------------------------------
function TSQLMemLocalSession.TableExists(TableName: WideString): Boolean;
begin
  FDatabaseData := FindOrCreateDatabaseData;
  Result := FDatabaseData.TableExists(Self,TableName);
end;// TableExists


//------------------------------------------------------------------------------
// export database to SQL
//------------------------------------------------------------------------------
function TSQLMemLocalSession.ExportDatabaseToSQL(
                              ExportStructure:        Boolean;
                              AddDropTableCommand:    Boolean;
                              ExportIndexes:          Boolean;
                              AddDropIndexCommand:    Boolean;
                              ExportData:             Boolean;
                              ExportBLOBFields:       Boolean;
                              UseBracketsForNames:    Boolean;
                              ExportForeignKeys:      Boolean;
                              ExportStoredFunctions:  Boolean;
                              ExportViews:            Boolean
                             ): WideString;
var tables:   TSQLMemWideStringList;
    cursor:   TSQLMemLocalCursor;
    i:        Integer;
    s:        WideString;
    FKSQL:    WideString;
begin
  Result := '';
  FKSQL := '';
  tables := TSQLMemWideStringList.Create();
  try
    GetTablesList(tables);
    if (tables.Count > 0) then
     begin
        for i := 0 to tables.Count-1 do
         begin
          cursor := TSQLMemLocalCursor(CreateCursor(tables[i],True));
          try
            if (Cursor.IsView and (not ExportViews)) then
             continue;
            cursor.Exclusive := False;
            cursor.ReadOnly := True;
            cursor.InMemory := Self.InMemory;
            cursor.Temporary := Self.Temporary;
            if (not cursor.IsView) then
             cursor.OpenTableByFieldDefs(nil,nil,nil);
            try
              cursor.GetTableSQL(
                  Result,FKSQL,
                  ExportStructure,
                  AddDropTableCommand,
                  ExportIndexes,
                  AddDropIndexCommand,
                  ExportData,
                  ExportBLOBFields,
                  UseBracketsForNames,
                  ExportForeignKeys
                                     );
            finally
             if (not cursor.IsView) then
              cursor.CloseTable;
            end;
          finally
            cursor.Free;
          end;
         end;
        if (ExportForeignKeys and (tables.Count > 0)) then
         Result := Result+ CRLF + FKSQL;
        if (ExportStoredFunctions) then
          ExportStoredFunctionsToSQL(Result);
     end;
  finally
    tables.Free;
  end;
end; // ExportDatabaseToSQL


//------------------------------------------------------------------------------
// load local memory database
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.LoadDatabaseFromStream(
                    Stream: TStream
                   );
begin
  if (FDatabaseData = nil) then
   FDatabaseData := FindOrCreateDatabaseData;
  FDatabaseData.LoadDatabaseFromStream(Self,Stream);
end;// LoadDatabaseFromStream


//------------------------------------------------------------------------------
// save local memory database
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.SaveDatabaseToStream(
                Stream:               TStream;
                CompressionAlgorithm: TSQLMemCompressionAlgorithm = acaNone;
                CompressionMode:      Byte = 0;
                BlockSize:            Integer = SQLMemDefaultSaveBlockSize
              );
begin
  if (FDatabaseData = nil) then
    FDatabaseData := FindOrCreateDatabaseData;
  FDatabaseData.SaveDatabaseToStream(Self,Stream,
      CompressionAlgorithm,CompressionMode,BlockSize);
end;// SaveDatabaseToStream


//------------------------------------------------------------------------------
// retrun true if database has active transaction
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetInTransaction: Boolean;
begin
  Result := (FTransaction <> nil);
end; // GetInTransaction


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemLocalSession.Create;
begin
  inherited;
  FLockParams.RetryCount := 1; // if created in server - needed for locking FreeSpaceManager to enter the loop
  FDatabaseData := nil;
  FSessionVariables := TSQLMemSQLParams.Create;
end; // Create


//------------------------------------------------------------------------------
// destroy local session
//------------------------------------------------------------------------------
destructor TSQLMemLocalSession.Destroy;
begin
  if (FTransaction <> nil) then
   FreeAndNil(FTransaction);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// start a transaction
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.StartTransaction;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TSQLMemLocalSession.StartTransaction. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
 if (FDatabaseData = nil) then
  raise ESQLMemException.Create(10813,ErrorLNilPointer);
 if (FTransaction <> nil) then
  raise ESQLMemException.Create(10814,ErrorLTransactionAlreadyStarted,[FDatabaseData.DatabaseName]);
 DBDataList.LockList;
 try
   if (FDatabaseData.DatabaseName = SQLMemTemporaryDatabaseName) then
    raise ESQLMemException.Create(10831,ErrorLTransactionOnNotDiskDatabase);
   FTransaction := TSQLMemTransaction.Create(Self,FDatabaseData);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('< TSQLMemLocalSession.StartTransaction finished OK. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
 finally
   DBDataList.UnlockList;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('<< TSQLMemLocalSession.StartTransaction finished. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
 end;
end; // StartTransaction


//------------------------------------------------------------------------------
// apply changes made by transaction
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.Commit(FlushFileBuffers: Boolean);
begin
  if (FDatabaseData = nil) then
    raise ESQLMemException.Create(10815,ErrorLNilPointer);
  if (FTransaction = nil) then
   raise ESQLMemException.Create(10816,ErrorLTransactionIsNotStarted,[FDatabaseData.DatabaseName]);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Commit before executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction.Commit(FlushFileBuffers);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Commit after executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Commit transaction destroyed. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction := nil;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Commit transaction destroyed and set to null. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
end; // Commit


//------------------------------------------------------------------------------
// cancel changes made by transaction
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.Rollback;
begin
  if (FDatabaseData = nil) then
    raise ESQLMemException.Create(10817,ErrorLNilPointer);
  if (FTransaction = nil) then
   raise ESQLMemException.Create(10818,ErrorLTransactionIsNotStarted,[FDatabaseData.DatabaseName]);
//  FTransaction.Rollback;
//  FreeAndNil(FTransaction);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Rollback before executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction.Rollback;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Rollback after executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
//  FreeAndNil(FTransaction);
  FTransaction.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TSQLMemLocalSession.Rollback transaction destroyed. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction := nil;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TSQLMemLocalSession.Rollback transaction destroyed and set to null. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}

end; // Rollback


//------------------------------------------------------------------------------
// remove all session locks - called by server session disconnect
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.RemoveAllLocks;
begin
  if (FDatabaseData <> nil) then
   FDatabaseData.RemoveAllLocks(Self.SessionID);
end; // RemoveAllLocks


//------------------------------------------------------------------------------
// clear disk cache in single-user / multi-user
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.ClearCache;
begin
  if (FDatabaseData <> nil) then
   FDatabaseData.ClearCache;
end; // ClearCache


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetTableComment(TableName: WideString): WideString;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetTableComment(TableName)
  else
    Result := '';
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.SetTableComment(TableName, Comment: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.SetTableComment(TableName,Comment)
  else
    raise ESQLMemException.Create(11969,ErrorLNilPointer);
end; // SetTableComment


//------------------------------------------------------------------------------
// create stored function / procedure
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.CreateStoredFunction(SQLScript: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.CreateStoredFunction(Self,SQLScript)
  else
    raise ESQLMemException.Create(12000,ErrorLNilPointer);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// for CREATE FUNCTON inside SQL script
// current token is rwFUNCTION/rwPROCEDURE
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.CreateStoredFunction(
              StoredFunction:   TObject;
              SQLScript:        WideString
                              );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.CreateStoredFunction(StoredFunction,SQLScript)
  else
    raise ESQLMemException.Create(12104,ErrorLNilPointer);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// parse create stored function
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.ParseStoredFunction(
              Lexer:                TSQLMemLexer;
              var Token:            TToken;
              out StoredFunction:   TObject;
              out SQLScript:        WideString
                             );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.ParseStoredFunction(Self,Lexer,Token,StoredFunction,SQLScript)
  else
    raise ESQLMemException.Create(12108,ErrorLNilPointer);
end; // ParseStoredFunction


//------------------------------------------------------------------------------
// drop stored function / procedure
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.DropStoredFunction(FunctionName: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.DropStoredFunction(Self,FunctionName)
  else
    raise ESQLMemException.Create(12001,ErrorLNilPointer);
end; // DropStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.AlterStoredFunction(
                                FunctionName,
                                NewSQLScript: WideString
                             );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.AlterStoredFunction(Self,FunctionName,NewSQLScript)
  else
    raise ESQLMemException.Create(12209,ErrorLNilPointer);
end; // AlterStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.AlterStoredFunctionRename(
                                FunctionName,
                                NewFunctionName:  WideString
                                                    );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.AlterStoredFunctionRename(Self,FunctionName,NewFunctionName)
  else
    raise ESQLMemException.Create(12223,ErrorLNilPointer);
end; // AlterStoredFunctionRename


//------------------------------------------------------------------------------
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
//------------------------------------------------------------------------------
function TSQLMemLocalSession.ExecuteStoredFunction(
                FunctionName:     WideString;
                ResultValue:      TSQLMemVariant;
                Params:           TSQLMemSQLParams
                                                ): Boolean;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.ExecuteStoredFunction(Self,FunctionName,ResultValue,Params)
  else
    raise ESQLMemException.Create(12002,ErrorLNilPointer);
end; // ExecuteStoredFunction


//------------------------------------------------------------------------------
// return empty string if function not found; otherwise
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TSQLMemLocalSession.FindStoredFunction(FunctionName: WideString): WideString;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.FindStoredFunction(FunctionName)
  else
    raise ESQLMemException.Create(12003,ErrorLNilPointer);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return the stored function object if it exists in stored function manager associated with
// the atabase opened by this session
// used by TSQLMemExprNodeStoredFunction
//------------------------------------------------------------------------------
function TSQLMemLocalSession.GetStoredFunctionByName(FunctionName: WideString): TObject;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetStoredFunctionByName(FunctionName,Self)
  else
    raise ESQLMemException.Create(12475,ErrorLNilPointer);
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// parse for execute
// return stored function object (TSQLMemStoredFunction) if found or nil
// params - list of TSQLMemExpression
//------------------------------------------------------------------------------
function TSQLMemLocalSession.ParseStoredFunctionParams(
                lexer:            TSQLMemLexer;
                parentFunction:   TObject; // parent TSQLMemStoredFunction object, where parser was called
                var token:        TToken;
                out Params:       TObject // TSQLMemExpressions
                                  ): TObject;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.ParseStoredFunctionParams(Self,Lexer,parentFunction,Token,Params)
  else
    raise ESQLMemException.Create(12090,ErrorLNilPointer);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings; SortNamesByAlphabet: Boolean);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.GetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet)
  else
    raise ESQLMemException.Create(12004,ErrorLNilPointer);
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.GetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList; SortNamesByAlphabet: Boolean);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.GetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet)
  else
    raise ESQLMemException.Create(12005,ErrorLNilPointer);
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.ExportStoredFunctionsToSQL(var SQL: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.ExportStoredFunctionsToSQL(SQL)
  else
    raise ESQLMemException.Create(12139,ErrorLNilPointer);
end; // ExportStoredFunctionsToSQL



//--------------------------- VIEWS - added in v.6.00 --------------------------


//------------------------------------------------------------------------------
// added in v.6.00 for views support
//------------------------------------------------------------------------------
function TSQLMemLocalSession.InternalCreateSQLProcessor(SQLStatement: WideString): TSQLMemLocalSQLProcessor;
var
    DBParams:       TSQLMemSQLDatabaseParams;
begin
  Result := TSQLMemLocalSQLProcessor.Create(nil,FCaseInsensitive);
  SetDatabaseParams(DBParams);
  Result.DefaultDatabaseParams := DBParams;
  Result.RequestLive := True;
  Result.InMemory := FInMemory;
  Result.PrepareStatement(PWideChar(@SQLStatement[1]));
end; // InternalCreateSQLProcessor


//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.CreateView(
                     ViewName:          WideString;
                     SelectStatement:   WideString;
                     Columns:           TSQLMemWideStringList;
                     bWithCheckOption:  Boolean;
                     Comment:           WideString
                    );
var
    SQLProcessor:   TSQLMemLocalSQLProcessor;
    ViewDef:        TSQLMemViewDef;
    ChildrenNames:  TSQLMemWideStringList;
    Cursor:         TSQLMemCursor;
begin
  if (FDatabaseData <> nil) then
  begin
    ChildrenNames := TSQLMemWideStringList.Create;
    try
      SQLProcessor := InternalCreateSQLProcessor(SelectStatement);
      try
        Cursor := SQLProcessor.OpenQuery(ChildrenNames);
        if (ChildrenNames.Count < 1) then
         raise ESQLMemException.Create(12570,ErrorLCannotCreateViewInvalidSQLStatement,[ViewName, SelectStatement]);
        if (Columns <> nil) then
         if (Cursor.FVisibleFieldDefs.Count < Columns.Count) then
          raise ESQLMemException.Create(12577,ErrorLCannotCreateViewInvalidColumnsCount,[ViewName, Columns.Count, Cursor.VisibleFieldDefs.Count, SelectStatement]);
        ViewDef := TSQLMemViewDef.Create(ViewName,SelectStatement,ChildrenNames,
                                      Columns,bWithCheckOption,Comment);
      finally
        SQLProcessor.Free;
      end;
    finally
      ChildrenNames.Free;
    end;
    try
      FDatabaseData.CreateView(Self,ViewName,ViewDef);
    except
      on e: Exception do
      begin
        ViewDef.Free;
        raise;
      end;
    end;
  end
  else
    raise ESQLMemException.Create(12565,ErrorLNilPointer);
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.DropView(
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.DropView(Self,ViewName,bCascade)
  else
    raise ESQLMemException.Create(12566,ErrorLNilPointer);
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TSQLMemLocalSession.FindView(ViewName: WideString): TSQLMemViewDef;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.FindView(Self,ViewName)
  else
    Result := nil;
end; // FindView


//----------------------- END OF VIEWS - added in v.6.00 -----------------------


//------------------------------------------------------------------------------
// closes session when database does not exist
//------------------------------------------------------------------------------
procedure TSQLMemLocalSession.CloseLocalSessionWithoutDatabase;
begin
  FDatabaseData := nil;
  Free;
end; // CloseLocalSessionWithoutDatabase


//------------------------------------------------------------------------------
// return cursor created for the specified table or view name
//------------------------------------------------------------------------------
function TSQLMemLocalSession.CreateCursor(TableName: WideString; bOpenView: Boolean = True): TSQLMemCursor;
var ViewDef:      TSQLMemViewDef;
    SQLProcessor: TSQLMemLocalSQLProcessor;
    i:            Integer;
begin
  Result := nil;
  ViewDef := nil;
  if (bOpenView) then
   ViewDef := FindView(TableName);
  if (ViewDef <> nil) then
  begin
   // open view
   try
     SQLProcessor := InternalCreateSQLProcessor(ViewDef.SelectStatement);
     try
       Result := SQLProcessor.OpenQuery;
       if (Result = nil) then
        raise ESQLMemException.Create(12574,ErrorLCannotOpenViewInvalidSQLStatement,
          [TableName,ViewDef.SelectStatement]);
       Result.IsView := True;
       Result.IsViewWithCheckOption := ViewDef.WithCheckOption;
       Result.ViewName := ViewDef.Name;
       Result.Comment := ViewDef.Comment;
       Result.ViewSelect := ViewDef.SelectStatement;
       Result.ViewColumns := '';
       SQLProcessor.ResetRootAOCursorInResultDataset;
       // apply column names
       if (ViewDef.ColumnNames.Count > 0) then
        for i := 0 to ViewDef.ColumnNames.Count-1 do
        begin
          if (i = 0) then
           Result.ViewColumns := ViewDef.ColumnNames[i]
          else
           Result.ViewColumns := Result.ViewColumns + Comma+ViewDef.ColumnNames[i];
          Result.FVisibleFieldDefs.Items[i].Name := ViewDef.ColumnNames[i];
        end;
     finally
       SQLProcessor.Free;
     end;
   finally
     ViewDef.Free;
   end;
  end // open view
  else
  begin
   // open table
   Result := TSQLMemLocalCursor.Create;
  end; // open table
  Result.TableName := TableName;
  Result.Session := Self;
end; // CreateCursor


initialization

{$IFDEF DEBUG_LOG_INIT}
// ShowMessage('SQLMemLocalEngine initialization started');
aaWriteToLog('SQLMemLocalEngine> initialization started');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
