unit ACRLocalEngine;

{$I ACRVer.inc}

{$WARNINGS OFF}
{$HINTS OFF}

interface

uses SysUtils, Classes,

// Accuracer units

     ACRRelationalAlgebra,
     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}
     ACRExcept,
     ACRBase,
     ACRBaseEngine,
     {$IFDEF MEMORY_ENGINE}
     ACRMemEngine,
     {$ENDIF}
     {$IFDEF TEMPORARY_ENGINE}
     ACRTempEngine,
     {$ENDIF}
     {$IFDEF DISK_ENGINE}
     ACRDiskEngine,
     {$ENDIF}
{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}
     ACRCompression,
     ACRTypes,
     ACRSQLProcessor,
     ACRExpressions,
     ACRConst,
     ACRLexer,
     ACRVariant,
     ACRConverts;


type


////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalBLOBStream
//
////////////////////////////////////////////////////////////////////////////////

  // local BLOB stream
  TACRLocalBLOBStream = class (TACRStream)
   private
    FOpenMode:                  TACRBLOBOpenMode;
    FTemporaryStream:           TACRStream;
    FUserBLOBStream:            TACRStream;
    FFieldNo:                   Integer;
    FCursor:                    TACRCursor;
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
                        TemporaryStream: TACRStream;
                        Cursor: TACRCursor;
                        OpenMode: TACRBLOBOpenMode;
                        FieldNo: Integer
                      );
    destructor Destroy; override;
   public
    // blob stream interface
   public
    property Cursor: TACRCursor read FCursor;
    property FieldNo: Integer read FFieldNo;
    property OpenMode: TACRBLOBOpenMode read FOpenMode write FOpenMode;
    property TemporaryStream: TACRStream read FTemporaryStream write FTemporaryStream;
    property UserBLOBStream: TACRStream read FUserBLOBStream write FUserBLOBStream;
    property DoNotFreeCompressedStream: Boolean read FDoNotFreeCompressedStream write FDoNotFreeCompressedStream;
  end; // TACRLocalBLOBtream


////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalCursor
//
////////////////////////////////////////////////////////////////////////////////


  TACRLocalCursor = class (TACRCursor)
   private
    FTableData:                     TACRTableData;
    FDatabaseData:                  TACRDatabaseData;
    FSavedPosition:                 Pointer;
    FSavedRecordBuffer:             TACRRecordBuffer;
    FDoNotCloseTableData:           Boolean;
    FDoNotUnlockTable:              Boolean;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    FSearchCache:                   TACRScanSearchConditionCache;
    FSearchOperation:               TACRLastSearchOperation;
{$ENDIF}
   public
    constructor Create;
    destructor Destroy; override;
    // create table
    procedure CreateTable(
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                         ); override;
    procedure DeleteTable(Cascade: Boolean = false); override;
    procedure EmptyTable; override;
    procedure AddForeignKey(ConstraintDef: TACRConstraintDefForeignKey); override;
    procedure DeleteConstraint(Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean); override;
    procedure RenameTable(NewTableName: WideString); override;
    procedure RenameField(FieldName, NewFieldName: WideString); override;
    procedure UpdateTableDefinitions; override;
   protected
    procedure TryToCopyRecords(NewCursor: TACRLocalCursor; var Log: AnsiString);
   public
    function RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TACRConstraintDefs = nil
                        ): Boolean; override;
    procedure LoadTableFromStream(
                        Stream:               TStream
                       ); override;
    procedure SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TACRCompressionAlgorithm = acaNone;
                        CompressionMode:        Byte = 0;
                        BlockSize:              Integer = 0;
                        SkipCheckIsTableOpened: Boolean = false;
                        DoNotCloseTable:        Boolean = false
                      ); override;
   protected
    function GetDropTableCommand(aTableName: WideString): WideString;
    function GetAutoIncFieldDefinition(FieldDef: TACRFieldDef): WideString;
    function GetBLOBFieldDefinition(FieldDef: TACRFieldDef): WideString;
    function GetFieldDefinition(FieldDef: TACRFieldDef; UseBracketsForNames:  Boolean): WideString;
    procedure GetCreateTableCommand(
                    var TableSQL:         WideString;
                    var TableFKSQL:       WideString;
                    aTableName:           WideString;
                    UseBracketsForNames:  Boolean;
                    ExportForeignKeys:    Boolean
                    );
    function GetCreateIndexCommand(aTableName: WideString; IndexName: WideString; IndexDef: TACRIndexDef; UseBracketsForNames:  Boolean): WideString;
    function GetDropIndexCommand(aTableName: WideString; IndexName: WideString): WideString;
    function GetSQLBLOBFieldValue(FieldNo: Integer): WideString;
    function GetSQLFieldValue(var v: TACRVariant; FieldNo: Integer; ExportBLOBFields: Boolean): WideString;
    function GetInsertCommand(var v: TACRVariant; aTableName: WideString; UseBracketsForNames:  Boolean; ExportBLOBFields: Boolean): WideString;
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
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                       ); override;
    procedure OpenTable(aTableData: TACRTableData);
    procedure CloseTable; override;

    // index operations
    function GetIndexDefs: TACRIndexDefs; override;
    procedure AddIndex(IndexDef: TACRIndexDef); override;
    procedure DeleteIndex(Name: WideString); override;
    procedure DeleteAllIndexes; override;
    // return index name of the index or '' if not found
    function FindIndex(FieldNamesList, AscDescList,
              CaseSensitivityList: TACRWideStringList): WideString; override;
    function IsTemporaryTable: Boolean; override;
    function IsMemoryTable: Boolean; override;


    //---------------------------------------------------------------------------
    // navigation & bookmark methods
    //---------------------------------------------------------------------------
    // return true if current record exists
    function IsRecordExists: Boolean; override;
    function GetRecordBuffer(
              GetRecordMode:  TACRGetRecordMode
              ): TACRGetRecordResult; override;
    function GetRecordCount: TACRRecordNo; override;
    // go to record
    procedure SetRecNo(Value: TACRRecordNo); override;
    function GetRecNo: TACRRecordNo; override;

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
    procedure UpdateVisibleRecords(FieldNames:   TACRWideStringList;
                                   values:       array of TACRVariant;
                                   SkipFKCheck:  Boolean = False
                                   ); override;

    //---------------------------------------------------------------------------
    // search & filter methods
    //---------------------------------------------------------------------------

    // disable record bitmap
    procedure DisableRecordBitmap; override;
    // apply projection
    procedure ApplyProjection(FieldNamesList, AliasList: TACRWideStringList); override;
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
    function FindKey(SearchCondition: TACRSearchCondition): Boolean; override;
    procedure ResetRange; override;
    procedure ApplyRange(
                          StartBuffer, EndBuffer: TACRRecordBuffer;
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
              OpenMode: TACRBLOBOpenMode
              ):TACRStream; override;

    procedure InternalCloseBLOB(FieldNo: Integer); override;

    // clear blob streams
    procedure ClearBLOBStreams(WriteOnly: Boolean = False); override;

    function LastAutoincValue(FieldNo: Integer): Int64; override;
    procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer); override;
    function GetTableState: TACRTableState; override;

    procedure LockTable(bWriteMode: Boolean); override;
    procedure UnlockTable(bWriteMode: Boolean); override;

    // were used in transactions in versions 1-4.
{
    procedure SaveCurrentPosition;
    procedure RestoreSavedPosition;
}
    procedure FreeSavedPosition;
   public
    property TableData: TACRTableData read FTableData;
    property DatabaseData: TACRDatabaseData read FDatabaseData;
    property DoNotUnlockTable: Boolean read FDoNotUnlockTable write FDoNotUnlockTable;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    property SearchCache: TACRScanSearchConditionCache read FSearchCache;
    property SearchOperation: TACRLastSearchOperation read FSearchOperation write FSearchOperation;
{$ENDIF}
  end; // TACRLocalCursor


////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalSession
//
////////////////////////////////////////////////////////////////////////////////


  TACRLocalSession = class (TACRBaseSession)
   private
    FDatabaseData:  TACRDatabaseData;
    FTransaction:   TACRTransaction;

    function FindDatabaseData: TACRDatabaseData;
    function CreateDatabaseData: TACRDatabaseData;
    function FindOrCreateDatabaseData: TACRDatabaseData;

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
    // returns true if this file is an Accuracer database
    function IsAccuracerDatabaseFile: Boolean; override;
    // return true if CryptoParams are valid
    function IsCryptoParamsValid: Boolean; override;
    procedure GetTablesList(List: TACRWideStringList); override;
    function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray; override;
    function GetTableState(TableName: WideString): TACRTableState; override;
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
                    CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
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
                  Lexer:                TACRLexer;
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
    // params - list of TACRExpression
    function ExecuteStoredFunction(
                FunctionName:     WideString;
                ResultValue:      TACRVariant;
                Params:           TACRSQLParams = nil // TACRExpressions
                                  ): Boolean; override;
    // return empty string if function not found; otherwise
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; override;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TACRExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString): TObject; override;
    // parse for execute
    // return stored function object (TACRStoredFunction) if found or nil
    // params - list of TACRExpression
    function ParseStoredFunctionParams(
                    lexer:            TACRLexer;
                    parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                    var token:        TToken;
                    out Params:       TObject // TACRExpressions
                                      ): TObject; override;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload;  override;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload; override;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); override;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
    //------------------------- VIEWS - added in v.6.00 ------------------------
    // added in v.6.00 for views support
    function InternalCreateSQLProcessor(SQLStatement: WideString): TACRLocalSQLProcessor;
    // create view
    procedure CreateView(
                         ViewName:          WideString;
                         SelectStatement:   WideString;
                         Columns:           TACRWideStringList = nil;
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
                     ): TACRViewDef; override;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    procedure CloseLocalSessionWithoutDatabase; override;
    // return cursor created for the specified table or view name
    function CreateCursor(TableName: WideString; bOpenView: Boolean = True): TACRCursor; override;
   public
    property DatabaseData: TACRDatabaseData read FDatabaseData;
    property Transaction: TACRTransaction read FTransaction;
  end; // TACRLocalSession

var
  DBDataList: TThreadList;

implementation

{$IFDEF D6H}
uses DateUtils,
     ACRMemory  // last
     ;
{$ELSE}
uses ACRMemory;  // last

procedure DecodeDateTime(const AValue: TDateTime; out AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word);
begin
  DecodeDate(AValue, AYear, AMonth, ADay);
  DecodeTime(AValue, AHour, AMinute, ASecond, AMilliSecond);
end;
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalBLOBStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TACRLocalBLOBStream.InternalSetSize(const NewSize: Int64);
begin
 if (OpenMode = bomRead) then
  raise EACRException.Create(10116,ErrorLCannotWriteToReadOnlyStream);
 FTemporaryStream.Size := NewSize;
end; // InternalSetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TACRLocalBLOBStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TACRLocalBLOBStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRLocalBLOBStream.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FTemporaryStream.Read(Buffer,Count);
end; // Read


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRLocalBLOBStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (OpenMode = bomRead) then
  raise EACRException.Create(10115,ErrorLCannotWriteToReadOnlyStream);
 Result := FTemporaryStream.Write(Buffer,Count);
end; // Write


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRLocalBLOBStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 Result := FTemporaryStream.Seek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRLocalBLOBStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 Result := FTemporaryStream.Seek(Offset,Origin);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
constructor TACRLocalBLOBStream.Create(
                        TemporaryStream: TACRStream;
                        Cursor: TACRCursor;
                        OpenMode: TACRBLOBOpenMode;
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
destructor TACRLocalBLOBStream.Destroy;
begin
 if (not FDoNotFreeCompressedStream) then
   TACRCompressedBLOBStream(FTemporaryStream).CompressedStream.Free;
 FTemporaryStream.Free;
 inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalCursor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRLocalCursor.Create;
begin
 FIsProjectionSet := False;
 FRandomOrder := False;
 FDoNotUnlockTable := False;
 FMemoryTableAllocBy := ACRDefaultMemoryTableAllocBy;
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
destructor TACRLocalCursor.Destroy;
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
procedure TACRLocalCursor.CreateTable
                         (
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                          );
var i: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('> TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8)
+#13#10+'TableName = '+FTableName
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
);
{$ENDIF}
  CloseTable;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('1 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  FDatabaseData := TACRLocalSession(Session).DatabaseData;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('2 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8)+', FDatabaseData = '+IntToHex(Integer(FDatabaseData),8));
{$ENDIF}
   if (InMemory or Temporary) then
    if (FDatabaseData.TableExists(Session,FTableName)) then
     begin
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('3 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
       DeleteTable;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('4 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     end;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('5 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  FTableData := FDatabaseData.FindOrCreateTableData(Self);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('6 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8)+', FTableData = '+IntToHex(Integer(FTableData),8)+', IndexDefs.Count = '+IntToStr(IndexDefs.Count));
{$ENDIF}
  if (FTableData = nil) then
    raise EACRException.Create(10523,ErrorLNilPointer);
  for i := 0 to IndexDefs.Count - 1 do
    IndexDefs[i].RootPageNo := INVALID_PAGE_NO;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('7 TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  FTableData.CreateTable(Self,FieldDefs,IndexDefs,ConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_CreateTable}
aaWriteToLog('< TACRLocalCursor.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DeleteTable(Cascade: Boolean);
begin
  CloseTable;
  FDatabaseData := TACRLocalSession(Session).DatabaseData;
   if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
   else
    begin
     if (Session.InTransaction) then
      raise EACRException.Create(10838,ErrorLCannotPerformThisOperationInsideATransaction);
     FTableData := FDatabaseData.CreateTableData(Self);
    end;
   if (FTableData = nil) then
    begin
     if (FDatabaseData is TACRMemoryDatabaseData) then
     begin
      FDatabaseData.DropView(Session,FTableName,Cascade);
      Exit;
     end;
     raise EACRException.Create(10027,ErrorLTableDataNotFound,[TableName]);
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
procedure TACRLocalCursor.EmptyTable;
begin
  CloseTable;
  FDatabaseData := TACRLocalSession(Session).DatabaseData;
  if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
  else
     FTableData := FDatabaseData.FindOrCreateTableData(Self);
// changed in 4.70     
//     FTableData := FDatabaseData.CreateTableData(Self);
  if (FTableData = nil) then
    raise EACRException.Create(10073,ErrorLTableDataNotFound,[TableName]);
  FTableData.EmptyTable(Self);
  if (InMemory or Temporary) then
    FTableData := nil
  else
    FreeAndNil(FTableData);
end; // EmptyTable


//------------------------------------------------------------------------------
// add foreign key
//------------------------------------------------------------------------------
procedure TACRLocalCursor.AddForeignKey(ConstraintDef: TACRConstraintDefForeignKey);
begin
  if (FTableData = nil) then
   raise EACRException.Create(11582,ErrorLTableDataNotFound,[TableName]);
  if (not FExclusive) then
   raise EACRException.Create(11583,ErrorLTableIsNotOpenedExclusively,[FTableName]);
  FTableData.AddForeignKey(Self,ConstraintDef); 
end; // AddForeignKey


//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DeleteConstraint(Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean);
begin
  if (FTableData = nil) then
   raise EACRException.Create(11484,ErrorLTableDataNotFound,[TableName]);
  if (not FExclusive) then
   raise EACRException.Create(11486,ErrorLTableIsNotOpenedExclusively,[FTableName]);
  FTableData.DeleteConstraint(Self,Name,Cascade,FKPartialDelete);
end; // DeleteConstraint


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TACRLocalCursor.RenameTable(NewTableName: WideString);
begin
  CloseTable;
  FDatabaseData := TACRLocalSession(Session).DatabaseData;
  if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
  else
    begin
     if (Session.InTransaction) then
      raise EACRException.Create(10839,ErrorLCannotPerformThisOperationInsideATransaction);
     FTableData := FDatabaseData.FindOrCreateTableData(Self);
    end;
  if (FTableData = nil) then
    raise EACRException.Create(10151,ErrorLTableDataNotFound,[TableName]);
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
procedure TACRLocalCursor.RenameField(FieldName, NewFieldName: WideString);
begin
  CloseTable;
  FDatabaseData := TACRLocalSession(Session).DatabaseData;
  if (InMemory or Temporary) then
     FTableData := FDatabaseData.FindTableData(Self)
  else
    begin
     if (Session.InTransaction) then
      raise EACRException.Create(11165,ErrorLCannotPerformThisOperationInsideATransaction);
     FTableData := FDatabaseData.CreateTableData(Self);
    end;
  if (FTableData = nil) then
    raise EACRException.Create(11166,ErrorLTableDataNotFound,[TableName]);
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
procedure TACRLocalCursor.UpdateTableDefinitions;
begin
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('> TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName
+#13#10+'FIsOpen = '+BoolToStr(FIsOpen,True));
{$ENDIF}
 if (FIsOpen) then
  begin
   if (FIndexDefs <> nil) then
    FIndexDefs.Free;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('1. TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
   FIndexDefs := TACRIndexDefs.Create;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('2. TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
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
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('3. TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
   if (FConstraintDefs <> nil) then
    FConstraintDefs.Free;
   FConstraintDefs := TACRConstraintDefs.Create;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('4. TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
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
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('5. TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
   InternalInitFieldDefs;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('6. TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName);
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_UpdateTableDefinitions}
aaWriteToLog('< TACRLocalCursor.UpdateTableDefinitions, FTableName = '+FTableName
+#13#10+'FIsOpen = '+BoolToStr(FIsOpen,True));
{$ENDIF}
end; // UpdateTableDefinitions


//------------------------------------------------------------------------------
// copy records
//------------------------------------------------------------------------------
procedure TACRLocalCursor.TryToCopyRecords(NewCursor: TACRLocalCursor; var Log: AnsiString);
var GetRecordResult: TACRGetRecordResult;
    bStart:           Boolean;
    bCalculateMinMax: Boolean;
    minmax:           array of Int64;
    CurrentValue:     TACRVariant;
    i:                Integer;


  procedure CopyRecord;
  var i:          Integer;
      bs,bs1:     TACRStream;
      BLOBExists: Boolean;
  begin
    ACRRefresh;
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
      raise EACRException.Create(11167,ErrorLRepairTableCannotGetRecord,
            [CurrentRecordID.PageNo,CurrentRecordID.PageItemNo,FTableName]);
   until (GetRecordResult = grrEOF);
  end; // TryToGetRecordsFromFirst


  procedure TryToGetRecordsFromLast(LastRecordID: TACRRecordID; bGetAll: Boolean);
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
      raise EACRException.Create(11168,ErrorLRepairTableCannotGetRecord,
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
    CurrentValue := TACRVariant.Create;
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
function TACRLocalCursor.RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TACRConstraintDefs = nil
                                    ): Boolean;
var NewCursor:          TACRLocalCursor;
    TempConstraintDefs: TACRConstraintDefs;
begin
  if (FInMemory or FTemporary) then
     Result := True
  else
   begin
    if (not FExclusive) then
     raise EACRException.Create(11165,ErrorLTableIsNotOpenedExclusively,[FTableName]);
    try
      Self.OpenTableByFieldDefs(nil,nil,nil);
      Self.InternalInitFieldDefs;
    except
      Result := False;
      Exit;
    end;
    NewCursor := TACRLocalCursor.Create;
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
          TempConstraintDefs := TACRConstraintDefs.Create;
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
procedure TACRLocalCursor.LoadTableFromStream(
                        Stream:               TStream
                       );
begin
//  CloseTable;
  FCreateTableStarted := True;
{$IFDEF MEMORY_ENGINE}
  try
    FDatabaseData := TACRLocalSession(Session).DatabaseData;
    // added in v.4.80
    if (not FTemporary) then
      FTableName := ACRGetSavedTableNameFromStream(Stream);
    if (FDatabaseData.TableExists(Session,FTableName)) then
      DeleteTable(True);
    FTableData := FDatabaseData.FindOrCreateTableData(Self);
    if (FTableData = nil) then
      raise EACRException.Create(10154,ErrorLTableDataNotFound,[TableName]);
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
procedure TACRLocalCursor.SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TACRCompressionAlgorithm;
                        CompressionMode:        Byte;
                        BlockSize:              Integer;
                        SkipCheckIsTableOpened: Boolean;
                        DoNotCloseTable:        Boolean
                      );
begin
  if (Session = nil) then
    raise EACRException.Create(11762,ErrorLNilPointer);
  FDatabaseData := TACRLocalSession(Session).DatabaseData;
  if (FDatabaseData = nil) then
    raise EACRException.Create(11761,ErrorLDatabaseDataNotFound,[TACRLocalSession(Session).DatabaseName,TACRLocalSession(Session).DatabaseFileName,AnsiString(TACRLocalSession(Session).DatabaseFileNameUnicode),
      BoolToStr(TACRLocalSession(Session).InMemory,True),
      BoolToStr(TACRLocalSession(Session).Temporary,True)]);
  FTableData := FDatabaseData.FindTableData(Self);
  if (FTableData = nil) then
    raise EACRException.Create(10154,ErrorLTableDataNotFound,[TableName]);
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
function TACRLocalCursor.GetDropTableCommand(aTableName: WideString): WideString;
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
function TACRLocalCursor.GetAutoIncFieldDefinition(FieldDef: TACRFieldDef): WideString;
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
function TACRLocalCursor.GetBLOBFieldDefinition(FieldDef: TACRFieldDef): WideString;
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
function TACRLocalCursor.GetFieldDefinition(FieldDef:             TACRFieldDef;
                                            UseBracketsForNames:  Boolean): WideString;
var i:      Integer;
    s:      WideString;
    check:  TACRConstraintDefCheck;
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
  if (WideUpperCase(TACRConstraintDefNotNull(FConstraintDefs[i]).ColumnName) = s) then
   begin
    if (FConstraintDefs[i].ConstraintType = ctNotNull) then
     Result := Result + Space + GetReservedWord(rwNOT) + Space + GetReservedWord(rwNULL)
    else
     if (FConstraintDefs[i].ConstraintType = ctCheck) then
      begin
       check := TACRConstraintDefCheck(FConstraintDefs[i]);
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
procedure TACRLocalCursor.GetCreateTableCommand(
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
    IndexDef:   TACRIndexDef;
    FKDef:      TACRConstraintDefForeignKey;
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

       FKDef := TACRConstraintDefForeignKey(FConstraintDefs.Items[i]);
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
function TACRLocalCursor.GetCreateIndexCommand(aTableName:          WideString;
                                               IndexName:           WideString;
                                               IndexDef:            TACRIndexDef;
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
function TACRLocalCursor.GetDropIndexCommand(aTableName: WideString; IndexName: WideString): WideString;
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
function TACRLocalCursor.GetSQLBLOBFieldValue(FieldNo: Integer): WideString;
var bs:   TACRStream;
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
               SingleQuote + ACRBinaryToMIME64(buf,size) + SingleQuote + Comma +
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
function TACRLocalCursor.GetSQLFieldValue(var v: TACRVariant; FieldNo: Integer; ExportBLOBFields: Boolean): WideString;
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
function TACRLocalCursor.GetInsertCommand(var v: TACRVariant; aTableName: WideString; UseBracketsForNames:  Boolean; ExportBLOBFields: Boolean): WideString;
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
procedure TACRLocalCursor.GetTableSQL(
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
    v:            TACRVariant;
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
    v := TACRVariant.Create;
    ClearBLOBStreams(False);
    try
      InternalFirst;
      while (GetRecordBuffer(grmNext) = grrOK) do
       begin
        ACRRefresh;
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
function TACRLocalCursor.ExportTableToSQL(
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
procedure TACRLocalCursor.InternalInitFieldDefs;
var
    i: Integer;
begin
 if (FFieldDefs <> nil) then
  FFieldDefs.Free;
 FFieldDefs := TACRFieldDefs.Create;
 if (not FSettingProjection) then
  begin
   if (FVisibleFieldDefs <> nil) then
    FVisibleFieldDefs.Free;
   FVisibleFieldDefs := TACRFieldDefs.Create;
  end;

{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLocalCursor.InternalInitFieldDefs, TableData.FieldDefs.Count = '+
IntToStr(FTableData.FieldManager.FieldDefs.Count));
{$ENDIF}


 FFieldDefs.Assign(FTableData.FieldManager.FieldDefs);
 FFieldDefs.RecalcFieldOffsets;

 FieldValuesOffset := FFieldDefs[0].MemoryOffset;
 BookmarkOffset := FFieldDefs[FFieldDefs.Count-1].MemoryOffset +
                   FFieldDefs[FFieldDefs.Count-1].MemoryDataSize;
 KeyOffset := BookmarkOffset;
 KeyBufferSize := BookmarkOffset + sizeof(TACRKeyBuffer);
 RecordSize := BookmarkOffset + SizeOf(TACRBookmarkInfo);
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
 FConstraintDefs := TACRConstraintDefs.Create;
 FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end; // InternalInitFieldDefs


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TACRLocalCursor.OpenTableByFieldDefs(
                                    FieldDefs: TACRFieldDefs;
                                    IndexDefs: TACRIndexDefs;
                                    ConstraintDefs: TACRConstraintDefs
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
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('> TACRLocalCursor.OpenTableByFieldDefs start'
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
    FDatabaseData := TACRLocalSession(Session).DatabaseData;
    if (InMemory or Temporary) then
       FTableData := FDatabaseData.FindTableData(Self)
    else
       FTableData := FDatabaseData.FindOrCreateTableData(Self);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
if (FTableData = nil) then
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs tabledata = nil')
else
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs tabledata = '+FTableData.TableName);
{$ENDIF}
    bCreateTable := (InMemory and (FieldDefs <> nil)) and
    // fixed in 5.30
//                    (IsDesignMode or (FTableData = nil)) and
                    ((FTableData = nil) and (FieldDefs.Count > 0))
                    ;

{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs bCreateTable = '+ BoolToStr(bCreateTable,True)
+#13#10+'FTableData = '+IntToHex(Integer(FTableData),8)
+#13#10+'InMemory = '+BoolToStr(InMemory,True)
+#13#10+'FieldDefs = '+IntToHex(Integer(FieldDefs),8)
+#13#10+'IsDesignMode = '+BoolToStr(IsDesignMode,True)
);
{$ENDIF}

    if (FTableData = nil) then
      begin
// modified in v.5
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs creating TableData!');
{$ENDIF}
        // added in v.5.60 to avoid memory leaks on not existing tables
        if (not bCreateTable) then
          if (not FDatabaseData.TableExists(FSession,FTableName)) then
           raise EACRException.Create(12434,ErrorLTableDoesNotExist,[FTableName]);
        FTableData := FDatabaseData.CreateTableData(Self);
        if (bCreateTable) then
         begin
          bCreateTable := False;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs creating table #1...');
{$ENDIF}
          try
            FTableData.CreateTable(Self,FieldDefs,IndexDefs, ConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs creating table #1... OK');
{$ENDIF}
          except
            // fixed in 4.95
            FTableData.Free;
            FTableData := nil;
            raise;
          end;
         end;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs TableData created!');
{$ENDIF}
      end;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs opening tabledata...');
{$ENDIF}
    FTableData.OpenTable(Self);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs tabledata opened successfully!');
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
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs IsTableDefsChanged = '+BoolToStr(bCreateTable,True));
{$ENDIF}
      // if records exists - do not re-create table to avoid loosing data
      if (bCreateTable) then
       bCreateTable := (FTableData.GetRecordCount(Self,False) <= 0);
      if (bCreateTable) then
       begin
        FTableData.CloseTable(Self);
        try
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs creating table #1...');
{$ENDIF}
          FTableData.CreateTable(Self,FieldDefs,IndexDefs, ConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs creating table #2... OK');
{$ENDIF}
          FTableData.OpenTable(Self);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs creating table - opening #2... OK');
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
// moved to TACRTableData in 4.90 - to avoid crash on multi-processor machines      
(*
     if (FIndexDefs <> nil) then
      FIndexDefs.Free;
     FIndexDefs := TACRIndexDefs.Create;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs indexdefs = '+IntToStr(FTableData.IndexManager.IndexDefs.Count));
{$ENDIF}
     FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs indexdefs2 = '+IntToStr(FIndexDefs.Count));
{$ENDIF}
     if (FConstraintDefs <> nil) then
      FConstraintDefs.Free;
     FConstraintDefs := TACRConstraintDefs.Create;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs constraints created');
{$ENDIF}
     FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs constraints assigned');
{$ENDIF}
*)
     if (FBLOBStreams <> nil) then
      FBLOBStreams.Free;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs blob streams destroyed');
{$ENDIF}
     FBLOBStreams := TList.Create;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs blob streams created');
{$ENDIF}
     if (RecordBitmap <> nil) then
      TACRRecordBitmap(RecordBitmap).Free;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs bitmap destroyed');
{$ENDIF}
     RecordBitmap := TACRRecordBitmap.Create(FTableData);
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs bitmap created');
{$ENDIF}

{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
     if (FSearchCache <> nil) then
      FSearchCache.Free;
     FSearchCache := TACRScanSearchConditionCache.Create;
     FSearchOperation := lsoNone;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs search cache created');
{$ENDIF}
{$ENDIF}

     IsOpen := True;
     FDoNotCloseTableData := False;

{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
  aaWriteToLog('TACRLocalCursor.OpenTableByFieldDefs opened');
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TACRLocalCursor_OpenTableByFieldDefs}
finally
aaWriteToLog('< TACRLocalCursor.OpenTableByFieldDefs finish'
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
procedure TACRLocalCursor.OpenTable(aTableData: TACRTableData);
begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.OpenTable(aTableData) start');
{$ENDIF}
 if (FIsView) then
  Exit;
 FreeSavedPosition;
 FTableData := aTableData;
 FirstPosition := True;
 LastPosition := False;
 if (FIndexDefs <> nil) then
  FIndexDefs.Free;
 FIndexDefs := TACRIndexDefs.Create;
 FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
 if (FConstraintDefs <> nil) then
  FConstraintDefs.Free;
 FConstraintDefs := TACRConstraintDefs.Create;
 FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
 if (FBLOBStreams <> nil) then
  FBLOBStreams.Free;
 FBLOBStreams := TList.Create;
 InternalInitFieldDefs;
 if (RecordBitmap <> nil) then
  TACRRecordBitmap(RecordBitmap).Free;
 RecordBitmap := TACRRecordBitmap.Create(FTableData);
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 if (FSearchCache <> nil) then
  FSearchCache.Free;
 FSearchCache := TACRScanSearchConditionCache.Create;
 FSearchOperation := lsoNone;
{$ENDIF}
 IsOpen := True;
 FDoNotCloseTableData := True;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.OpenTable(aTableData) finish');
{$ENDIF}
end; // OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TACRLocalCursor.CloseTable;
var bTemp: Boolean;
begin
 bTemp := false;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable start');
{$ENDIF}
 FreeSavedPosition;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 0');
{$ENDIF}
   if (FTempRecordBuffer <> nil) then
    begin
     FreeRecordBuffer(FTempRecordBuffer);
     FTempRecordBuffer := nil;
    end;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 00');
{$ENDIF}
 if (FTableData <> nil) then
  begin
   bTemp := (FTableData is TACRTemporaryTableData) and (not FDoNotCloseTableData);
   if (not FDoNotCloseTableData) then
    begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 01');
{$ENDIF}
     FTableData.CloseTable(Self);
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 02');
{$ENDIF}
     if (FTemporary) then
      FTableData := nil;
    end;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 03');
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
 aaWriteToLog('TACRLocalCursor.CloseTable 1');
{$ENDIF}
 if (RecordBitmap <> nil) then
  TACRRecordBitmap(RecordBitmap).Free;
 RecordBitmap := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 2');
{$ENDIF}
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 if (FSearchCache <> nil) then
  FreeAndNil(FSearchCache);
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 2.1');
{$ENDIF}
 if (FilterExpression <> nil) then
  TACRExpression(FilterExpression).Free;
 FilterExpression := nil;
 if (FSQLFilterExpression <> nil) then
  TACRExpression(FSQLFilterExpression).Free;
 FSQLFilterExpression := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 3');
{$ENDIF}
 if (FFieldDefs <> nil) then
   FFieldDefs.Free;
 FFieldDefs := nil;
 if (not FSettingProjection) then
  begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 4');
{$ENDIF}
   if (FVisibleFieldDefs <> nil) then
    FVisibleFieldDefs.Free;
   FVisibleFieldDefs := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 44');
{$ENDIF}
  end;
 if (FIndexDefs <> nil) then
   FIndexDefs.Free;
 FIndexDefs := nil;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRLocalCursor.CloseTable 5');
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
 aaWriteToLog('TACRLocalCursor.CloseTable finish');
{$ENDIF}
end; // CloseTable


//------------------------------------------------------------------------------
// GetIndexDefs
//------------------------------------------------------------------------------
function TACRLocalCursor.GetIndexDefs: TACRIndexDefs;
begin
  if (FIndexDefs <> nil) then
   FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  Result := inherited GetIndexDefs;
end;// GetIndexDefs


//------------------------------------------------------------------------------
// add index
//------------------------------------------------------------------------------
procedure TACRLocalCursor.AddIndex(IndexDef: TACRIndexDef);
begin
  if (FIndexDefs.GetIndexDefByName(IndexDef.Name) <> nil) then
   raise EACRException.Create(20022, ErrorAIndexAlreadyExists, [IndexDef.Name]);
  FTableData.AddIndex(IndexDef, Self);
  FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  //if (not FTemporary) then
  FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end;// AddIndex


//------------------------------------------------------------------------------
// DeleteIndex
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DeleteIndex(Name: WideString);
begin
  if (FIndexDefs.GetIndexDefByName(Name) = nil) then
   raise EACRException.Create(20021, ErrorACannotDeleteIndex, [Name]);
  // Delete Index
  FTableData.DeleteIndex(FIndexDefs.GetIndexDefByName(Name).ObjectID, Self);
  FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  //if (not FTemporary) then
  FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end;// DeleteIndex


//------------------------------------------------------------------------------
// DeleteAllIndexes
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DeleteAllIndexes;
begin
  FTableData.DeleteAllIndexes(Self);
  FIndexDefs.Assign(FTableData.IndexManager.IndexDefs);
  //if (not FTemporary) then
   FConstraintDefs.Assign(FTableData.ConstraintManager.ConstraintDefs);
end;// DeleteAllIndexes


//------------------------------------------------------------------------------
// return index name of the index or '' if not found
//------------------------------------------------------------------------------
function TACRLocalCursor.FindIndex(FieldNamesList, AscDescList, CaseSensitivityList: TACRWideStringList): WideString;
begin
  Result := FTableData.FindIndex(Self, FieldNamesList, AscDescList, CaseSensitivityList);
end; // FindIndex


//------------------------------------------------------------------------------
// return true if temporary table
//------------------------------------------------------------------------------
function TACRLocalCursor.IsTemporaryTable: Boolean;
begin
  if (FTableData <> nil) then
   Result := FTableData.Temporary;
end; // IsTemporaryTable


//------------------------------------------------------------------------------
// return true if memory table
//------------------------------------------------------------------------------
function TACRLocalCursor.IsMemoryTable: Boolean;
begin
  Result := False;
  if (FTableData <> nil) then
   Result := FTableData.InMemory;
end; // IsMemoryTable


//------------------------------------------------------------------------------
// return true if current record exists
//------------------------------------------------------------------------------
function TACRLocalCursor.IsRecordExists: Boolean;
begin
  Result := FTableData.IsRecordExists(Self);
end; // IsRecordExists


//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
function TACRLocalCursor.GetRecordBuffer(
              GetRecordMode:  TACRGetRecordMode
              ): TACRGetRecordResult;
begin
  Result := FTableData.GetRecordBuffer(Self,GetRecordMode);
  if (Result = grrOK) then
   GetCalcFieldsAndBookMarkData;
end; // GetRecordBuffer


//------------------------------------------------------------------------------
// returns record count
//------------------------------------------------------------------------------
function TACRLocalCursor.GetRecordCount: TACRRecordNo;
begin
  Result := FTableData.GetRecordCount(Self);
end; // GetRecordCount


//------------------------------------------------------------------------------
// go to record
//------------------------------------------------------------------------------
procedure TACRLocalCursor.SetRecNo(Value: Int64);
begin
  FTableData.SetRecNo(Self,Value);
end; // SetRecNo


//------------------------------------------------------------------------------
// return current record number
//------------------------------------------------------------------------------
function TACRLocalCursor.GetRecNo: Int64;
begin
  Result := FTableData.GetRecNo(Self);
end; // GetRecNo


//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
procedure TACRLocalCursor.InternalEdit;
begin
  ErrorCode := ACR_ERR_OK;
  if (FTableData is TACRTemporaryTableData) then
    ErrorCode := ACR_ERR_UPDATE_RECORD_PROHIBITED
  else
    FTableData.EditRecord(Self);
end; // InternalEdit


//------------------------------------------------------------------------------
// cancels updates
//------------------------------------------------------------------------------
procedure TACRLocalCursor.InternalCancel(ToInsert: Boolean);
begin
  ErrorCode := ACR_ERR_OK;
  if (FTableData is TACRTemporaryTableData) then
    ErrorCode := ACR_ERR_CANCEL_PROHIBITED
  else
    begin
     ClearBLOBStreams(True);
     FTableData.CancelRecord(Self,ToInsert);
    end;
end; // InternalCancel


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
procedure TACRLocalCursor.InternalPost(ToInsert: Boolean);
var TempCursor: TACRCursor;
begin
 ErrorCode := ACR_ERR_OK;
 ErrorMessage := '';
 TempCursor := Self;
 ClearBLOBStreams(True);
 if (ToInsert) then
  begin
   // insert
   try
     if (not FTableData.InsertRecord(TempCursor)) then
      begin
       ErrorCode := ACR_ERR_INSERT_RECORD;
       ErrorMessage := Format(ErrorLAddingRecord,
        [FTableName,
         BoolToStr(InMemory),
         BoolToStr(Temporary)]);
      end;
   except
    on e: Exception do
     begin
       if (ErrorCode <> ACR_ERR_CONSTRAINT_VIOLATED) then
         ErrorCode := ACR_ERR_INSERT_RECORD;
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
    CurrentRecordID,sizeof(TACRRecordID));
   ErrorCode := ACR_ERR_OK;
   try
     if (not FTableData.UpdateRecord(TempCursor)) then
      begin
       ErrorCode := ACR_ERR_Update_RECORD;
       ErrorMessage := ErrorLUpdatingRecord;
      end;
   except
    on e: Exception do
     begin
      if (ErrorCode <> ACR_ERR_CONSTRAINT_VIOLATED) then
       ErrorCode := ACR_ERR_Update_RECORD;
      ErrorMessage := ErrorLUpdatingRecord+e.Message;
     end;
   end;
  end; // update;
end; // InternalPost


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TACRLocalCursor.InternalDelete;
begin
 FErrorMessage := '';
 if (FTableData is TACRTemporaryTableData) then
  ErrorCode := ACR_ERR_DELETE_RECORD_PROHIBITED
 else
  begin
   // delete
   Move(PAnsiChar(FCurrentRecordBuffer + BookmarkOffset)^,
    CurrentRecordID,sizeof(TACRRecordID));
   FErrorCode := ACR_ERR_OK;
   try
     if (not FTableData.DeleteRecord(Self)) then
       FErrorCode := ACR_ERR_DELETE_RECORD;
//     Move(CurrentRecordID,FDeleteCurrentRecordID,SizeOf(TACRRecordID));
   except
     on e: Exception do
      begin
        FErrorCode := ACR_ERR_DELETE_RECORD;
        FErrorMessage := e.Message;
      end;
   end;
  end;
end; // InternalDelete


//------------------------------------------------------------------------------
// delete all visible records
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DeleteVisibleRecords;
begin
  FTableData.DeleteVisibleRecords(Self);
end; // DeleteVisibleRecords


//------------------------------------------------------------------------------
// update visible records
//------------------------------------------------------------------------------
procedure TACRLocalCursor.UpdateVisibleRecords(FieldNames:   TACRWideStringList;
                                               values:       array of TACRVariant;
                                               SkipFKCheck:  Boolean = False
                                               );
begin
  FTableData.UpdateVisibleRecords(Self,FieldNames,values,SkipFKCheck);
end; // UpdateVisibleRecords

//------------------------------------------------------------------------------
// disable record bitmap
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DisableRecordBitmap;
begin
 if (RecordBitmap <> nil) then
  TACRRecordBitmap(RecordBitmap).Active := False;
 {$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
 FSearchCache.Clear;
 {$ENDIF}
end; // DisableRecordBitmap


//------------------------------------------------------------------------------
// apply projection
//------------------------------------------------------------------------------
procedure TACRLocalCursor.ApplyProjection(FieldNamesList, AliasList: TACRWideStringList);
var i,j: Integer;
begin
  if (FieldNamesList.Count <> AliasList.Count) then
    raise EACRException.Create(10321,ErrorLDifferentListsLength,
            [FieldNamesList.Count,AliasList.Count]);
  if (FieldNamesList.Count = 0) then
    raise EACRException.Create(10322,ErrorLNoFieldsInProjection);
  FVisibleFieldDefs.Clear;
  for i := 0 to FieldNamesList.Count -1 do
   begin
    j := FFieldDefs.GetDefNumberByName(FieldNamesList[i]);
    if (j < 0) then
      raise EACRException.Create(10323,ErrorLCannotFindField,[FieldNamesList[i]]);
    FVisibleFieldDefs.AddCreated.Assign(FFieldDefs[j]);
    FVisibleFieldDefs[FVisibleFieldDefs.Count-1].FieldNoReference := j;
    if (AliasList[i] <> '') then
     FVisibleFieldDefs[FVisibleFieldDefs.Count-1].Name := AliasList[i];
   end;
end;


//------------------------------------------------------------------------------
// activate filters
//------------------------------------------------------------------------------
procedure TACRLocalCursor.ActivateFilters(
                          FilterText:      WideString;
                          CaseInsensitive: Boolean;
                          PartialKey:      Boolean
                        );
begin
  if (FilterExpression <> nil) then
    TACRExpression(FilterExpression).Free;
  FilterExpression := TACRExpression.Create(FSession,nil);
  TACRExpression(FilterExpression).ParseForFilter(Self,FilterText,CaseInsensitive,PartialKey);
  DisableRecordBitmap;
end; // ActivateFilters


//------------------------------------------------------------------------------
// deactivate filters
//------------------------------------------------------------------------------
procedure TACRLocalCursor.DeactivateFilters;
begin
  if (FSQLFilterExpression <> nil) then
   Exit;
  if (FilterExpression <> nil) then
    TACRExpression(FilterExpression).Free;
  FilterExpression := nil;
  DisableRecordBitmap;
end; // DeactivateFilters


//------------------------------------------------------------------------------
// locate
//------------------------------------------------------------------------------
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
function TACRLocalCursor.Locate(
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
function TACRLocalCursor.Locate(
                const KeyFields: WideString;
                const KeyValues: Variant;
                CaseInsensitive: Boolean;
                PartialKey:      Boolean
               ): Boolean;
var SearchExpression: TACRExpression;
begin
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time6);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time28);
{$ENDIF}
  SearchExpression := TACRExpression.Create(FSession,nil);
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
function TACRLocalCursor.FindKey(SearchCondition: TACRSearchCondition): Boolean;
begin
  Result := FTableData.FindKey(Self,SearchCondition);
end; // FindKey


//------------------------------------------------------------------------------
// reset range
//------------------------------------------------------------------------------
procedure TACRLocalCursor.ResetRange;
begin
  RangeStartBuffer := nil;
  RangeEndBuffer := nil;
  DisableRecordBitmap;
end; // ResetRange


//------------------------------------------------------------------------------
// apply range
//------------------------------------------------------------------------------
procedure TACRLocalCursor.ApplyRange(
                          StartBuffer, EndBuffer: TACRRecordBuffer;
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
procedure TACRLocalCursor.SetSQLFilter(FilterExpr: TObject);
begin
  SQLFilterExpression := FilterExpr;
  if SQLFilterExpression <> nil then
    TACRExpression(SQLFilterExpression).AssignCursor(self);
end; // SetSQLFilter



//------------------------------------------------------------------------------
// create blob stream
//------------------------------------------------------------------------------
function TACRLocalCursor.InternalCreateBlobStream(
              ToInsert: Boolean;
              FieldNo:  Integer;
              OpenMode: TACRBLOBOpenMode
              ):TACRStream;
var FieldNumber:      Integer;
    i:                Integer;
    LocalBLOBStream:  TACRLocalBLOBStream;
begin
{
 if (FIsProjectionSet) then
  begin
    if (FieldNo >= FFieldDefs.Count) then
     raise EACRException.Create(11614,ErrorLInvalidFieldNumber,
      [FieldNo,FFieldDefs.Count]);
    if (FBLOBStreams = nil) then
     raise EACRException.Create(11615,ErrorLNilPointer);
    FieldNumber := FieldNo;
  end
 else
}
  begin
    if (FieldNo >= FVisibleFieldDefs.Count) then
     raise EACRException.Create(10110,ErrorLInvalidFieldNumber,
      [FieldNo,FVisibleFieldDefs.Count]);
    if (FBLOBStreams = nil) then
     raise EACRException.Create(10113,ErrorLNilPointer);
    FieldNumber := FVisibleFieldDefs.Items[FieldNo].FieldNoReference;
  end;
 // find existing blob stream
 if ((OpenMode = bomReadWrite) or (OpenMode = bomWrite)) then
  for i := 0 to FBLOBStreams.Count -1 do
   begin
    LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
    if (LocalBLOBStream = nil) then
      raise EACRException.Create(10114,ErrorLNilPointer);
    if (LocalBLOBStream.FFieldNo = FieldNumber) then
     if ((LocalBLOBStream.OpenMode = bomReadWrite) or
         (LocalBLOBStream.OpenMode = bomWrite)) then
      raise EACRException.Create(10115,ErrorLBLOBFieldAlreadyOpened,[FieldNumber,
        FFieldDefs.Items[FieldNumber].Name]);
   end;

 Result := FTableData.InternalCreateBlobStream(Self,ToInsert,FieldNumber,OpenMode);
 if (Result <> nil) then
  FBLOBStreams.Add(Result);
end; // InternalCreateBlobStream


//------------------------------------------------------------------------------
// close blob
//------------------------------------------------------------------------------
procedure TACRLocalCursor.InternalCloseBLOB(FieldNo: Integer);
var FieldNumber:       Integer;
    i:                 Integer;
    LocalBLOBStream:   TACRLocalBLOBStream;
begin
 if (FieldNo >= FVisibleFieldDefs.Count) then
  raise EACRException.Create(10118,ErrorLInvalidFieldNumber,
    [FieldNo,FVisibleFieldDefs.Count]);
 if (FBLOBStreams = nil) then
  raise EACRException.Create(10119,ErrorLNilPointer);
 FieldNumber := FVisibleFieldDefs.Items[FieldNo].FieldNoReference;

 i := 0;
 while (i < FBLOBStreams.Count) do
  begin
   LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
   if (LocalBLOBStream = nil) then
      raise EACRException.Create(10120,ErrorLNilPointer);
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
procedure TACRLocalCursor.ClearBLOBStreams(WriteOnly: Boolean = False);
var i:                  Integer;
    LocalBLOBStream:    TACRLocalBLOBStream;
begin
 i := 0;
 if (FBLOBStreams <> nil) then
   while (i < FBLOBStreams.Count) and (FBLOBStreams.Count > 0) do
    begin
     LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
     if (LocalBLOBStream  = nil) then
      raise EACRException.Create(10121,ErrorLNilPointer);
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
function TACRLocalCursor.LastAutoincValue(FieldNo: Integer): Int64;
begin
  Result := FTableData.LastAutoincValue(FieldNo, FSession);
end;//LastAutoincValue


//------------------------------------------------------------------------------
//SetLastAutoincValue
//------------------------------------------------------------------------------
procedure TACRLocalCursor.SetLastAutoincValue(Value: Int64; FieldNo: Integer);
begin
  FTableData.SetLastAutoincValue(Value, FieldNo, Self);
end;//SetLastAutoincValue


//------------------------------------------------------------------------------
// return table state
//------------------------------------------------------------------------------
function TACRLocalCursor.GetTableState: TACRTableState;
begin
{$IFNDEF SQLMEMTABLE}
  if (FTableData is TACRDiskTableData) then
   Result := TACRDiskTableData(FTableData).LoadTableState
  else
{$ENDIF}  
   Result := FTableData.TableState;
end; // TACRTableState


//------------------------------------------------------------------------------
// lock table for read
//------------------------------------------------------------------------------
procedure TACRLocalCursor.LockTable(bWriteMode: Boolean);
begin
  FTableData.LockTable(bWriteMode,Session,11892,True);
end; // LockTableForRead;


//------------------------------------------------------------------------------
// unlock table for read
//------------------------------------------------------------------------------
procedure TACRLocalCursor.UnlockTable(bWriteMode: Boolean);
begin
  FTableData.UnlockTable(bWriteMode,Session,True);
end; // UnlockTableForRead;


{
//------------------------------------------------------------------------------
// save current position
//------------------------------------------------------------------------------
procedure TACRLocalCursor.SaveCurrentPosition;
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
procedure TACRLocalCursor.RestoreSavedPosition;
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
procedure TACRLocalCursor.FreeSavedPosition;
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
// TACRLocalSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// FindDatabaseData
//------------------------------------------------------------------------------
function TACRLocalSession.FindDatabaseData: TACRDatabaseData;
var
  DBDatas: TList;
  i: integer;
begin
  DBDatas := DBDataList.LockList;
  Result := nil;
  try
    if (Temporary) then
      Result := ACRFindDatabaseData(False,True,ACRTemporaryDatabaseName,'')
    else
    if (InMemory) then
      Result := ACRFindDatabaseData(True,False,DatabaseName,'')
    else
      Result := ACRFindDatabaseData(False,False,DatabaseFileName,DatabaseFileNameUnicode);
  finally
    DBDataList.UnlockList;
  end;
end;// FindDatabaseData


//------------------------------------------------------------------------------
// create new database data and add it to global list
//------------------------------------------------------------------------------
function TACRLocalSession.CreateDatabaseData: TACRDatabaseData;
var
  DBDatas: TList;
begin
  if (InMemory) then
   begin
    Result := TACRMemoryDatabaseData.Create;
    TACRMemoryDatabaseData(Result).DatabaseName := DatabaseFileName;
   end
  else
   begin
{$IFDEF DISK_ENGINE}
    Result := TACRDiskDatabaseData.Create;
    TACRDiskDatabaseData(Result).DatabaseName := DatabaseFileName;
    TACRDiskDatabaseData(Result).Options := Options;
    TACRDiskDatabaseData(Result).CryptoParams := CryptoParams;
    TACRDiskDatabaseData(Result).LockParams := LockParams;
{$ENDIF}
   end;
  DBDatas := DBDataList.LockList;
  DBDatas.Add(Result);
  DBDataList.UnlockList;
end;// CreateDatabaseData


//------------------------------------------------------------------------------
// find or create database data
//------------------------------------------------------------------------------
function TACRLocalSession.FindOrCreateDatabaseData: TACRDatabaseData;
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
function TACRLocalSession.GetConnected: Boolean;
begin
  Result := (FDatabaseData <> nil);
end;// GetConnected


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TACRLocalSession.SetConnected(Value: boolean);
begin
 if Value <> GetConnected then
  begin
    DBDataList.LockList;
    try
     if Value then
      begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.SetConnected(true) before set FTransaction to nil. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
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
 aaWriteToLog('TACRLocalSession.SetConnected(False) starting...'+
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
    ' TACRLocalSession.SetConnected(false) before Rollback. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
            FTransaction.Rollback;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TACRLocalSession.SetConnected(false) after Rollback. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
            FTransaction.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TACRLocalSession.SetConnected(false) after destroy. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
            FTransaction := nil;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TACRLocalSession.SetConnected(false) after set nil. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
           end;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRLocalSession.SetConnected(False) disconnecting session...'+
              ', SessionID = '+IntToStr(FSessionID)+
              ', DatabaseData.DatabaseName = '+IntToStr(Integer(FDatabaseData.DatabaseName))+
              ', Transaction = '+IntToStr(Integer(FTransaction)));
 {$ENDIF}
          FDatabaseData.DisconnectSession(Self);
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRLocalSession.SetConnected(False) disconnecting session... OK'+
              ', DatabaseData = '+IntToStr(Integer(FDatabaseData))+
              ', Transaction = '+IntToStr(Integer(FTransaction)));
 {$ENDIF}
          FDatabaseData.FreeIfNoSessionsConnected;// implemented for disk DB only
          FDatabaseData := nil;
         end;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRLocalSession.SetConnected(False) finished'+
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
function TACRLocalSession.GetDatabaseExists: Boolean;
begin
  // changed in v.4.90
  Result := True;
  if (FInMemory) then
   Result := (FindDatabaseData <> nil)
  else
   Result := ACRFileExists(FDatabaseFileName,FDatabaseFileNameUnicode);
end; // GetDatabaseExists


//------------------------------------------------------------------------------
// create database
//------------------------------------------------------------------------------
procedure TACRLocalSession.CreateDatabase;
begin
  DBDataList.LockList;
  try
    if (FindDatabaseData <> nil) then
      raise EACRException.Create(20092, ErrorADatabaseAlreadyOpen);
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
procedure TACRLocalSession.FlushFileBuffers;
begin
  if (FDatabaseData = nil) then
    raise EACRException.Create(11235,ErrorLNilPointer);
  FDatabaseData.FlushFileBuffers;  
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// return database format version
//------------------------------------------------------------------------------
function TACRLocalSession.GetFormatVersion: Double;
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
function TACRLocalSession.GetFreePageCount: Integer;
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
function TACRLocalSession.GetTotalPageCount: Integer;
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
function TACRLocalSession.IsDatabaseEncrypted: Boolean;
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
function TACRLocalSession.IsDatabaseEncryptedByPassword: Boolean;
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
procedure TACRLocalSession.MakeExeDatabase(ExeFileName, ExeDatabaseFileName: WideString);
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
procedure TACRLocalSession.RemoveDatabaseFromExe;
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
// returns true if this file is an Accuracer database
//------------------------------------------------------------------------------
function TACRLocalSession.IsAccuracerDatabaseFile: Boolean;
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
    Result := FDatabaseData.IsAccuracerDatabaseFile(Self);
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
end; // IsAccuracerDatabaseFile


//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TACRLocalSession.IsCryptoParamsValid: Boolean;
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
procedure TACRLocalSession.GetTablesList(List: TACRWideStringList);
begin
  //FDatabaseData := FindOrCreateDatabaseData;
  if (FDatabaseData <> nil) then
    FDatabaseData.GetTablesList(Self,List);
end;// GetTablesList


//------------------------------------------------------------------------------
// return information about all tables
//------------------------------------------------------------------------------
function TACRLocalSession.GetTablesInfo(SortByTableName: Boolean): TACRTableInfoArray;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetTablesInfo(SortByTableName)
  else
    Result := nil;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// return table state  or 0 if not found
//------------------------------------------------------------------------------
function TACRLocalSession.GetTableState(TableName: WideString): TACRTableState;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetTableState(TableName)
  else
    FillChar(Result,SizeOf(Result),$00);
end; // GetTableState


//------------------------------------------------------------------------------
// TableExists
//------------------------------------------------------------------------------
function TACRLocalSession.TableExists(TableName: WideString): Boolean;
begin
  FDatabaseData := FindOrCreateDatabaseData;
  Result := FDatabaseData.TableExists(Self,TableName);
end;// TableExists


//------------------------------------------------------------------------------
// export database to SQL
//------------------------------------------------------------------------------
function TACRLocalSession.ExportDatabaseToSQL(
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
var tables:   TACRWideStringList;
    cursor:   TACRLocalCursor;
    i:        Integer;
    s:        WideString;
    FKSQL:    WideString;
begin
  Result := '';
  FKSQL := '';
  tables := TACRWideStringList.Create();
  try
    GetTablesList(tables);
    if (tables.Count > 0) then
     begin
        for i := 0 to tables.Count-1 do
         begin
          cursor := TACRLocalCursor(CreateCursor(tables[i],True));
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
procedure TACRLocalSession.LoadDatabaseFromStream(
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
procedure TACRLocalSession.SaveDatabaseToStream(
                Stream:               TStream;
                CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
                CompressionMode:      Byte = 0;
                BlockSize:            Integer = ACRDefaultSaveBlockSize
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
function TACRLocalSession.GetInTransaction: Boolean;
begin
  Result := (FTransaction <> nil);
end; // GetInTransaction


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRLocalSession.Create;
begin
  inherited;
  FLockParams.RetryCount := 1; // if created in server - needed for locking FreeSpaceManager to enter the loop
  FDatabaseData := nil;
  FSessionVariables := TACRSQLParams.Create;
end; // Create


//------------------------------------------------------------------------------
// destroy local session
//------------------------------------------------------------------------------
destructor TACRLocalSession.Destroy;
begin
  if (FTransaction <> nil) then
   FreeAndNil(FTransaction);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// start a transaction
//------------------------------------------------------------------------------
procedure TACRLocalSession.StartTransaction;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRLocalSession.StartTransaction. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
 if (FDatabaseData = nil) then
  raise EACRException.Create(10813,ErrorLNilPointer);
 if (FTransaction <> nil) then
  raise EACRException.Create(10814,ErrorLTransactionAlreadyStarted,[FDatabaseData.DatabaseName]);
 DBDataList.LockList;
 try
   if (FDatabaseData.DatabaseName = ACRTemporaryDatabaseName) then
    raise EACRException.Create(10831,ErrorLTransactionOnNotDiskDatabase);
   FTransaction := TACRTransaction.Create(Self,FDatabaseData);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('< TACRLocalSession.StartTransaction finished OK. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
 finally
   DBDataList.UnlockList;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('<< TACRLocalSession.StartTransaction finished. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
 end;
end; // StartTransaction


//------------------------------------------------------------------------------
// apply changes made by transaction
//------------------------------------------------------------------------------
procedure TACRLocalSession.Commit(FlushFileBuffers: Boolean);
begin
  if (FDatabaseData = nil) then
    raise EACRException.Create(10815,ErrorLNilPointer);
  if (FTransaction = nil) then
   raise EACRException.Create(10816,ErrorLTransactionIsNotStarted,[FDatabaseData.DatabaseName]);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Commit before executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction.Commit(FlushFileBuffers);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Commit after executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Commit transaction destroyed. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction := nil;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Commit transaction destroyed and set to null. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
end; // Commit


//------------------------------------------------------------------------------
// cancel changes made by transaction
//------------------------------------------------------------------------------
procedure TACRLocalSession.Rollback;
begin
  if (FDatabaseData = nil) then
    raise EACRException.Create(10817,ErrorLNilPointer);
  if (FTransaction = nil) then
   raise EACRException.Create(10818,ErrorLTransactionIsNotStarted,[FDatabaseData.DatabaseName]);
//  FTransaction.Rollback;
//  FreeAndNil(FTransaction);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Rollback before executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction.Rollback;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Rollback after executing. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
//  FreeAndNil(FTransaction);
  FTransaction.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(' TACRLocalSession.Rollback transaction destroyed. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}
  FTransaction := nil;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog(aaGetCurrentTimeAsString+
    ' TACRLocalSession.Rollback transaction destroyed and set to null. FTransaction = '+IntToHex(Integer(FTransaction),8)+', SessionID = '+IntToStr(FSessionID));
{$ENDIF}

end; // Rollback


//------------------------------------------------------------------------------
// remove all session locks - called by server session disconnect
//------------------------------------------------------------------------------
procedure TACRLocalSession.RemoveAllLocks;
begin
  if (FDatabaseData <> nil) then
   FDatabaseData.RemoveAllLocks(Self.SessionID);
end; // RemoveAllLocks


//------------------------------------------------------------------------------
// clear disk cache in single-user / multi-user
//------------------------------------------------------------------------------
procedure TACRLocalSession.ClearCache;
begin
  if (FDatabaseData <> nil) then
   FDatabaseData.ClearCache;
end; // ClearCache


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRLocalSession.GetTableComment(TableName: WideString): WideString;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetTableComment(TableName)
  else
    Result := '';
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRLocalSession.SetTableComment(TableName, Comment: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.SetTableComment(TableName,Comment)
  else
    raise EACRException.Create(11969,ErrorLNilPointer);
end; // SetTableComment


//------------------------------------------------------------------------------
// create stored function / procedure
//------------------------------------------------------------------------------
procedure TACRLocalSession.CreateStoredFunction(SQLScript: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.CreateStoredFunction(Self,SQLScript)
  else
    raise EACRException.Create(12000,ErrorLNilPointer);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// for CREATE FUNCTON inside SQL script
// current token is rwFUNCTION/rwPROCEDURE
//------------------------------------------------------------------------------
procedure TACRLocalSession.CreateStoredFunction(
              StoredFunction:   TObject;
              SQLScript:        WideString
                              );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.CreateStoredFunction(StoredFunction,SQLScript)
  else
    raise EACRException.Create(12104,ErrorLNilPointer);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// parse create stored function
//------------------------------------------------------------------------------
procedure TACRLocalSession.ParseStoredFunction(
              Lexer:                TACRLexer;
              var Token:            TToken;
              out StoredFunction:   TObject;
              out SQLScript:        WideString
                             );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.ParseStoredFunction(Self,Lexer,Token,StoredFunction,SQLScript)
  else
    raise EACRException.Create(12108,ErrorLNilPointer);
end; // ParseStoredFunction


//------------------------------------------------------------------------------
// drop stored function / procedure
//------------------------------------------------------------------------------
procedure TACRLocalSession.DropStoredFunction(FunctionName: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.DropStoredFunction(Self,FunctionName)
  else
    raise EACRException.Create(12001,ErrorLNilPointer);
end; // DropStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TACRLocalSession.AlterStoredFunction(
                                FunctionName,
                                NewSQLScript: WideString
                             );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.AlterStoredFunction(Self,FunctionName,NewSQLScript)
  else
    raise EACRException.Create(12209,ErrorLNilPointer);
end; // AlterStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TACRLocalSession.AlterStoredFunctionRename(
                                FunctionName,
                                NewFunctionName:  WideString
                                                    );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.AlterStoredFunctionRename(Self,FunctionName,NewFunctionName)
  else
    raise EACRException.Create(12223,ErrorLNilPointer);
end; // AlterStoredFunctionRename


//------------------------------------------------------------------------------
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
//------------------------------------------------------------------------------
function TACRLocalSession.ExecuteStoredFunction(
                FunctionName:     WideString;
                ResultValue:      TACRVariant;
                Params:           TACRSQLParams
                                                ): Boolean;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.ExecuteStoredFunction(Self,FunctionName,ResultValue,Params)
  else
    raise EACRException.Create(12002,ErrorLNilPointer);
end; // ExecuteStoredFunction


//------------------------------------------------------------------------------
// return empty string if function not found; otherwise
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TACRLocalSession.FindStoredFunction(FunctionName: WideString): WideString;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.FindStoredFunction(FunctionName)
  else
    raise EACRException.Create(12003,ErrorLNilPointer);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return the stored function object if it exists in stored function manager associated with
// the atabase opened by this session
// used by TACRExprNodeStoredFunction
//------------------------------------------------------------------------------
function TACRLocalSession.GetStoredFunctionByName(FunctionName: WideString): TObject;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.GetStoredFunctionByName(FunctionName,Self)
  else
    raise EACRException.Create(12475,ErrorLNilPointer);
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// parse for execute
// return stored function object (TACRStoredFunction) if found or nil
// params - list of TACRExpression
//------------------------------------------------------------------------------
function TACRLocalSession.ParseStoredFunctionParams(
                lexer:            TACRLexer;
                parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                var token:        TToken;
                out Params:       TObject // TACRExpressions
                                  ): TObject;
begin
  if (FDatabaseData <> nil) then
    Result := FDatabaseData.ParseStoredFunctionParams(Self,Lexer,parentFunction,Token,Params)
  else
    raise EACRException.Create(12090,ErrorLNilPointer);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRLocalSession.GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings; SortNamesByAlphabet: Boolean);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.GetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet)
  else
    raise EACRException.Create(12004,ErrorLNilPointer);
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRLocalSession.GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList; SortNamesByAlphabet: Boolean);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.GetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet)
  else
    raise EACRException.Create(12005,ErrorLNilPointer);
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TACRLocalSession.ExportStoredFunctionsToSQL(var SQL: WideString);
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.ExportStoredFunctionsToSQL(SQL)
  else
    raise EACRException.Create(12139,ErrorLNilPointer);
end; // ExportStoredFunctionsToSQL



//--------------------------- VIEWS - added in v.6.00 --------------------------


//------------------------------------------------------------------------------
// added in v.6.00 for views support
//------------------------------------------------------------------------------
function TACRLocalSession.InternalCreateSQLProcessor(SQLStatement: WideString): TACRLocalSQLProcessor;
var
    DBParams:       TACRSQLDatabaseParams;
begin
  Result := TACRLocalSQLProcessor.Create(nil,FCaseInsensitive);
  SetDatabaseParams(DBParams);
  Result.DefaultDatabaseParams := DBParams;
  Result.RequestLive := True;
  Result.InMemory := FInMemory;
  Result.PrepareStatement(PWideChar(@SQLStatement[1]));
end; // InternalCreateSQLProcessor


//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TACRLocalSession.CreateView(
                     ViewName:          WideString;
                     SelectStatement:   WideString;
                     Columns:           TACRWideStringList;
                     bWithCheckOption:  Boolean;
                     Comment:           WideString
                    );
var
    SQLProcessor:   TACRLocalSQLProcessor;
    ViewDef:        TACRViewDef;
    ChildrenNames:  TACRWideStringList;
    Cursor:         TACRCursor;
begin
  if (FDatabaseData <> nil) then
  begin
    ChildrenNames := TACRWideStringList.Create;
    try
      SQLProcessor := InternalCreateSQLProcessor(SelectStatement);
      try
        Cursor := SQLProcessor.OpenQuery(ChildrenNames);
        if (ChildrenNames.Count < 1) then
         raise EACRException.Create(12570,ErrorLCannotCreateViewInvalidSQLStatement,[ViewName, SelectStatement]);
        if (Columns <> nil) then
         if (Cursor.FVisibleFieldDefs.Count < Columns.Count) then
          raise EACRException.Create(12577,ErrorLCannotCreateViewInvalidColumnsCount,[ViewName, Columns.Count, Cursor.VisibleFieldDefs.Count, SelectStatement]);
        ViewDef := TACRViewDef.Create(ViewName,SelectStatement,ChildrenNames,
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
    raise EACRException.Create(12565,ErrorLNilPointer);
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TACRLocalSession.DropView(
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
begin
  if (FDatabaseData <> nil) then
    FDatabaseData.DropView(Self,ViewName,bCascade)
  else
    raise EACRException.Create(12566,ErrorLNilPointer);
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TACRLocalSession.FindView(ViewName: WideString): TACRViewDef;
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
procedure TACRLocalSession.CloseLocalSessionWithoutDatabase;
begin
  FDatabaseData := nil;
  Free;
end; // CloseLocalSessionWithoutDatabase


//------------------------------------------------------------------------------
// return cursor created for the specified table or view name
//------------------------------------------------------------------------------
function TACRLocalSession.CreateCursor(TableName: WideString; bOpenView: Boolean = True): TACRCursor;
var ViewDef:      TACRViewDef;
    SQLProcessor: TACRLocalSQLProcessor;
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
        raise EACRException.Create(12574,ErrorLCannotOpenViewInvalidSQLStatement,
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
   Result := TACRLocalCursor.Create;
  end; // open table
  Result.TableName := TableName;
  Result.Session := Self;
end; // CreateCursor


initialization

{$IFDEF DEBUG_LOG_INIT}
// ShowMessage('ACRLocalEngine initialization started');
aaWriteToLog('ACRLocalEngine> initialization started');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
