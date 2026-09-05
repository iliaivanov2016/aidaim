//------------------------------------------------------------------------------
//
// Client classes
//
//------------------------------------------------------------------------------

unit ACRClient;

interface

{$WARNINGS OFF}
{$HINTS OFF}
{$I ACRVer.inc}

uses SysUtils, Classes, Db,
{$IFDEF D6H}
  Variants,
{$ELSE}
  ACRD4Routines,
{$ENDIF}
  // Accuracer units
{$IFDEF DEBUG_LOG}
  ACRDebug,
{$ENDIF}
  ACRComMain,
  ACRExcept,
  ACRLexer,
  ACRVariant,
  ACRConnection,
  ACRCommunication,
  ACRCompression,
  ACRLocalEngine,
  ACRBase,
  ACRTypes,
  ACRTypesNetwork,
  ACRSQLProcessor,
  ACRConst;

const
 ACRDefaultClientProtocol = acrUDP;

type

TACRClientConnectParamsEditor = class;

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////

TACRClientNetworkSettingsEditor = class(TACRNetworkSettingsEditor)
private
  FOwner:                   TACRClientConnectParamsEditor;
  FConnectRetryCount:       Integer;
  FConnectDelay:            Integer;
  FUseServerSettings:       Boolean;
public
  constructor Create(Owner: TACRClientConnectParamsEditor);
  destructor Destroy; override;
  procedure Assign(Source: TPersistent); override;
  procedure CopySettingsToConnectParams(var ConnectParams: TACRConnectParams); override;
  procedure SetDefaultSettings(Value: TACRDefaultNetworkSettings); override;
published
  property ConnectRetryCount: Integer read FConnectRetryCount write FConnectRetryCount;
  property ConnectDelay: Integer read FConnectDelay write FConnectDelay;
  property UseServerSettings: Boolean read FUseServerSettings write FUseServerSettings;
end; // TACRClientNetworkSettingsEditor


////////////////////////////////////////////////////////////////////////////////
//
// TACRClientConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

TACRClientConnectParamsEditor = class(TACRConnectionParamsEditor)
private
  FProtocol:              TACRClientProtocol;
  FRemoteHost:            AnsiString;
  FRemotePort:            Cardinal;
  FCompressionAlgorithm:  TCompressionAlgorithm;
  FCompressionMode:       Byte;
  FNetworkSettings:       TACRClientNetworkSettingsEditor;
  FMinCacheSize,
  FMaxCacheSize:          Int64;
public
  constructor Create;
  destructor Destroy; override;
  procedure Assign(Source: TPersistent); override;
  function GetConnectParams: TACRConnectParams; override;
protected
  procedure SetProtocol(Value: TACRClientProtocol);
  procedure SetLocalPort(Value: Cardinal); // compatibility with old UDP only component
  function GetLocalPort: Cardinal; // compatibility with old UDP only component
published
  property Protocol: TACRClientProtocol read FProtocol write SetProtocol;
  property RemoteHost: AnsiString read FRemoteHost write FRemoteHost;
  property RemotePort: Cardinal read FRemotePort write FRemotePort;
  property MinCacheSize: Int64 read FMinCacheSize write FMinCacheSize;
  property MaxCacheSize: Int64 read FMaxCacheSize write FMaxCacheSize;
{$IFDEF RELEASE_BUILD}
public
{$ENDIF}
  property LocalPort: Cardinal read GetLocalPort write SetLocalPort; // compatibility with old UDP only component
  property NetworkSettings: TACRClientNetworkSettingsEditor read FNetworkSettings write	FNetworkSettings;
end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientSession
//
////////////////////////////////////////////////////////////////////////////////

TACROnClientReceiveMessage = procedure(Buffer: PAnsiChar;
  Size: Integer) of object;
TACROnClientReceiveCommand = procedure(Buffer: PAnsiChar;
  Size: Integer) of object;
TACROnDisconnectRemoteDatasets = procedure(ServerShutdown: Boolean) of object;
TACROnErrorEvent = procedure(const ErrorCode: Integer;
  const NativeError: Integer; const ErrorMessage: AnsiString) of object;

TACRClientSession = class(TACRNetworkSession)
private
  FOnReceiveMessage: TACROnClientReceiveMessage;
  FOnReceiveCommand: TACROnClientReceiveCommand;
  FConnecting: Boolean;
  FOnDisconnectRemoteDatasets: TACROnDisconnectRemoteDatasets;
  FOnError: TACROnErrorEvent;
  FDisconnected: Boolean;
  FRetry: Integer;
protected
  // Send command then receive answer, if needed
  function ExecuteCommand(AnswerNeeded: Boolean = true): Boolean;
  // get error message and raises an excpetion
  procedure CheckReceivedReply(CorrectReply: TACRCommunicationReply);
  // db connected?
  function GetConnected: Boolean; override;
  // connect / disconnect
  procedure SetConnected(Value: Boolean); override;
  // added in v.5.90
  procedure SetCaseInsensitive(Value: Boolean); override;
public
  // call OnError event handler
  procedure DoOnError(ErrorCode: Integer; NativeError: Integer = -1;
    ErrorMessage: AnsiString = ''); override;
  // check if database exists
  function GetDatabaseExists: Boolean; override;
  // fills list with table names from this database
  procedure GetTablesList(List: TACRWideStringList); override;
  function GetTablesInfo(SortByTableName: Boolean = true)
    : TACRTableInfoArray; override;
  function GetTableState(TableName: WideString): TACRTableState; override;
  // return true if table exists
  function TableExists(TableName: WideString): Boolean; override;
  // export database to SQL
  function ExportDatabaseToSQL(
                    ExportStructure:       Boolean = true;
                    AddDropTableCommand:   Boolean = true;
                    ExportIndexes:         Boolean = true;
                    AddDropIndexCommand:   Boolean = false;
                    ExportData:            Boolean = true;
                    ExportBLOBFields:      Boolean = true;
                    UseBracketsForNames:   Boolean = false;
                    ExportForeignKeys:     Boolean = true;
                    ExportStoredFunctions: Boolean = true;
                    ExportViews:           Boolean = true
                                ): WideString; override;
  // flush file buffers
  procedure FlushFileBuffers; override;
  // return database format version
  function GetFormatVersion: Double; override;
  // return total number of pages
  function GetTotalPageCount: Integer; override;
  // return number of free pages
  function GetFreePageCount: Integer; override;
  // return true if database is encrypted
  function IsDatabaseEncrypted: Boolean; override;
  // return true if database is encrypted by password or by key
  function IsDatabaseEncryptedByPassword: Boolean; override;
  // return true if CryptoParams are valid
  function IsCryptoParamsValid: Boolean; override;
  // makes Exe database from edb file
  procedure MakeExeDatabase(ExeFileName, ExeDatabaseFileName: WideString);
    override;
  // removes database file from executable database file
  procedure RemoveDatabaseFromExe; override;
  // returns true if this file is an Accuracer database
  function IsAccuracerDatabaseFile: Boolean; override;
// ------------------------ Transactions ------------------------------------
protected
  // retrun true if database has active transaction
  function GetInTransaction: Boolean; override;
public
  constructor Create;
  procedure DoCloseSessionOnNetworkError; override;
  // start a transaction
  procedure StartTransaction; override;
  // apply changes made by transaction
  procedure Commit(FlushFileBuffers: Boolean = true); override;
  // cancel changes made by transaction
  procedure Rollback; override;
  // clear disk cache
  procedure ClearCache; override;
public
  procedure OnDisconnect; override;
  // send command specified by SentCommandHeader [ optionally SentCommandDataStream ]
  function SendCommand: Boolean; override;
  // send buffer via established connection using connection manager
  procedure SendBuffer(var Buffer: PAnsiChar; BufferSize: Integer); override;
  // wait while command will not be received
  function ReceiveCommand: Boolean;
  // send custom message
  procedure SendMessage(Buffer: PAnsiChar; BufferSize: Integer); override;
  // receive custom message
  procedure ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer); override;
  // return table comment if table exists, otherwise empty string
  function GetTableComment(TableName: WideString): WideString; override;
  // set table comment
  procedure SetTableComment(TableName, Comment: WideString); override;
//  **********  STORED FUNCTIONS AND PROCEDURES - added in v.5.10  *************
  // create stored function / procedure
  procedure CreateStoredFunction(SQLScript: WideString); overload; override;
  // for CREATE FUNCTON inside SQL script
  // current token is rwFUNCTION/rwPROCEDURE
  procedure CreateStoredFunction(StoredFunction: TObject;
    SQLScript: WideString); overload; override;
  procedure ParseStoredFunction(Lexer: TACRLexer; var Token: TToken;
    out StoredFunction: TObject; out SQLScript: WideString); override;
  // drop stored function / procedure
  procedure DropStoredFunction(FunctionName: WideString); override;
  // ALTER stored function - modify script
  procedure AlterStoredFunction(FunctionName, NewSQLScript: WideString);
    override;
  // ALTER stored function - rename
  procedure AlterStoredFunctionRename(FunctionName,
    NewFunctionName: WideString); override;
  // execute stored function - return false if function does not exist
  // if function has no result (procedure) ResultValue will be set to nil
  // params - list of TACRSQLParam
  function ExecuteStoredFunction(FunctionName: WideString;
    ResultValue: TACRVariant; Params: TACRSQLParams = nil): Boolean;
    override;
  // return empty string if function not found; otherwise
  // return SQL script that created this function (CREATE FUNCTION ...)
  function FindStoredFunction(FunctionName: WideString): WideString; override;
  // parse for execute
  // return stored function object (TACRStoredFunction) if found or nil
  // params - list of TACRExpression
  function ParseStoredFunctionParams(
                                      Lexer:          TACRLexer;
                                      parentFunction: TObject;
                                      var Token:      TToken;
                                      out Params:     TObject // TACRExpressions
                                    ): TObject; override;
  // return list of stored function names (optionally SQL scripts for their creation)
  procedure GetStoredFunctions(FunctionNames: TStrings;
    FunctionSQLScripts: TStrings = nil;
    SortNamesByAlphabet: Boolean = true); overload; override;
  // return list of stored function names (optionally SQL scripts for their creation)
  procedure GetStoredFunctions(FunctionNames: TACRWideStringList;
    FunctionSQLScripts: TACRWideStringList = nil;
    SortNamesByAlphabet: Boolean = true); overload; override;
  // export all stored functions to SQL
  procedure ExportStoredFunctionsToSQL(var SQL: WideString); override;
//  #####  STORED FUNCTIONS AND PROCEDURES - added in v.5.10  #################
//  *********************  VIEWS - added in v.6.00  ***************************
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
// #########################  VIEWS - added in v.6.00  #########################

  // return cursor created for the specified table or view name
  function CreateCursor(TableName: WideString; bOpenView: Boolean = True): TACRCursor; override;
public
  property OnReceiveCommandMessage
    : TACROnClientReceiveCommand read FOnReceiveCommand write
    FOnReceiveCommand;
  property OnReceiveMessage
    : TACROnClientReceiveMessage read FOnReceiveMessage
    write FOnReceiveMessage;
  property OnDisconnectRemoteDatasets
    : TACROnDisconnectRemoteDatasets read FOnDisconnectRemoteDatasets
    write FOnDisconnectRemoteDatasets;
  property OnError: TACROnErrorEvent read FOnError write FOnError;
end; // TACRClientSession

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientRecordCache - used in client-server
// on client side (with record buffers)
//
////////////////////////////////////////////////////////////////////////////////

TACRClientRecordCache = class(TACRBaseRecordCache)
private
  FCurrentRecordPosition: Integer;
  FCurrentRecordID: TACRRecordID;
  FAllocatedRecords: Integer;
protected
{$IFDEF DEBUG_LOG}
  procedure WriteRecords;
  procedure WriteAllData(Caption: AnsiString = '');
{$ENDIF}
  procedure ResizeCache(NewRecordCount: Integer); override;
  function GetNumRecords: Integer;
  procedure ResetCache(RecNo: TACRRecordNo);
  procedure ShiftRecords(ToBeginning: Boolean;
    Position, NumRecords: TACRRecordNo);
  procedure UpdateRecNo(Increase: Boolean;
    Position, NumRecords: TACRRecordNo);
  procedure MoveCurrentRecord(RecPos, RecNo: TACRRecordNo);
  procedure InsertRecord(RecNo: TACRRecordNo);
  procedure UpdateRecord(RecNo: TACRRecordNo);
  procedure DeleteRecord(OldRecordID: TACRRecordID; RecNo: TACRRecordNo);
public
  procedure LoadFromStream(Stream: TACRMemoryStream); override;
  function GetRecordBuffer(GetRecordMode: TACRGetRecordMode)
    : TACRGetRecordResult;
  function GetRecordCount: TACRRecordNo;
  function GetRecNo: TACRRecordNo;
  function SetRecNo(RecNo: TACRRecordNo): Boolean;
  procedure SetCurrentRecord;
  procedure InternalPost(ToInsert, SingleRecordInCache: Boolean;
    RecNo, RecCount: TACRRecordNo; const NewState: TACRTableState);
  procedure InternalDelete(OldRecordID: TACRRecordID;
    SingleRecordInCache: Boolean; RecNo, RecCount: TACRRecordNo;
    const NewState: TACRTableState);
  procedure CalculateNumRecords;
  function IsRecordExists: Boolean;
  procedure EmptyTable(const NewState: TACRTableState);
public
  property AllocatedRecords
    : Integer read FAllocatedRecords write FAllocatedRecords;
end; // TACRClientRecordCache

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientCursor
//
////////////////////////////////////////////////////////////////////////////////

TACRClientCursor = class(TACRCursor)
private
  FCursorID: TACRObjectID;
  FBLOBCache: TList;
  FCache: TACRClientRecordCache;
protected
  procedure SendRecordBuffer(const ErrorCode: Integer; RecordBuffer: TACRRecordBuffer);
  procedure ReceiveRecordBuffer(const ErrorCode: Integer; RecordBuffer: TACRRecordBuffer);
  procedure SaveGetRecordParams(GetRecordMode: TACRGetRecordMode);
  function CheckToLoadCache(GetRecordMode: TACRGetRecordMode = grmCurrent): TACRGetRecordResult;
  function LoadCache(GetRecordMode: TACRGetRecordMode = grmCurrent; ResetFilters: Boolean = False): TACRGetRecordResult;
  // added in v.5.90
  procedure SetCaseInsensitive(Value: Boolean); override;

public
  procedure ReceiveServerCursor;
  constructor Create;
  destructor Destroy; override;
  // create table
  procedure CreateTable(FieldDefs: TACRFieldDefs; IndexDefs: TACRIndexDefs;
    ConstraintDefs: TACRConstraintDefs); override;
  procedure DeleteTable(Cascade: Boolean = False); override;
  procedure EmptyTable; override;
  procedure AddForeignKey(ConstraintDef: TACRConstraintDefForeignKey);
    override;
  procedure DeleteConstraint(Name: WideString; Cascade: Boolean;
    FKPartialDelete: Boolean); override;
  procedure RenameTable(NewTableName: WideString); override;
  procedure RenameField(FieldName, NewFieldName: WideString); override;
  function RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TACRConstraintDefs = nil
                                    ): Boolean; override;
  procedure LoadTableFromStream(Stream: TStream); override;
  procedure SaveTableToStream(Stream: TStream;
    CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
    CompressionMode: Byte = 0; BlockSize: Integer = 0;
    SkipCheckIsTableOpened: Boolean = False;
    DoNotCloseTable: Boolean = False); override;
  function ExportTableToSQL(ExportStructure: Boolean;
    AddDropTableCommand: Boolean; ExportIndexes: Boolean;
    AddDropIndexCommand: Boolean; ExportData: Boolean;
    ExportBLOBFields: Boolean; UseBracketsForNames: Boolean;
    ExportForeignKeys: Boolean): WideString; override;
  procedure InternalInitFieldDefs; override;
  procedure OpenTableByFieldDefs(FieldDefs: TACRFieldDefs;
    IndexDefs: TACRIndexDefs; ConstraintDefs: TACRConstraintDefs); override;
  procedure CloseTable; override;
  procedure AddIndex(IndexDef: TACRIndexDef); override;
  procedure DeleteIndex(Name: WideString); override;
  procedure DeleteAllIndexes; override;
  // return index name of the index or '' if not found
  function FindIndex(FieldNamesList, AscDescList,
    CaseSensitivityList: TACRWideStringList): WideString; override;
  function IsTemporaryTable: Boolean; override;
  function IsMemoryTable: Boolean; override;

  // ---------------------------------------------------------------------------
  // navigation & bookmark methods
  // ---------------------------------------------------------------------------

  function GetRecordCount: TACRRecordNo; override;
  // get record
  function GetRecordBuffer(GetRecordMode: TACRGetRecordMode)
    : TACRGetRecordResult; override;
  // go to record
  procedure SetRecNo(Value: TACRRecordNo); override;
  function GetRecNo: TACRRecordNo; override;

  // ---------------------------------------------------------------------------
  // insert, edit, post, delete methods
  // ---------------------------------------------------------------------------

  // refresh - added in v.5.30
  procedure InternalRefresh; override;
  // edit record
  procedure InternalEdit; override;
  // cancels updates
  procedure InternalCancel(ToInsert: Boolean); override;
  // insert or update record
  procedure InternalPost(ToInsert: Boolean); override;
  // delete record
  procedure InternalDelete; override;
  procedure DeleteVisibleRecords; override;
  procedure UpdateVisibleRecords(FieldNames: TACRWideStringList;
    values: array of TACRVariant; SkipFKCheck: Boolean = False);
    override;

  // ---------------------------------------------------------------------------
  // search & filter methods
  // ---------------------------------------------------------------------------

  // disable record bitmap
  procedure DisableRecordBitmap; override;
  // apply projection
  procedure ApplyProjection(FieldNamesList, AliasList: TACRWideStringList);
    override;
  procedure ActivateFilters(FilterText: WideString; CaseInsensitive: Boolean;
    PartialKey: Boolean); override;
  procedure DeactivateFilters; override;
  function Locate(const KeyFields: WideString; const KeyValues: Variant;
    CaseInsensitive: Boolean; PartialKey: Boolean): Boolean; override;
  function FindKey(SearchCondition: TACRSearchCondition): Boolean; override;
  procedure ResetRange; override;
  procedure ApplyRange(StartBuffer, EndBuffer: TACRRecordBuffer;
    StartKeyFieldCount: Integer; EndKeyFieldCount: Integer;
    StartExclusive: Boolean; EndExclusive: Boolean); override;
  // set SQL Filter
  procedure SetSQLFilter(FilterExpr: TObject); override;

  // ---------------------------------------------------------------------------
  // BLOB methods
  // ---------------------------------------------------------------------------

  function InternalCreateBlobStream(ToInsert: Boolean; FieldNo: Integer;
    OpenMode: TACRBLOBOpenMode): TACRStream; override;
  procedure InternalCloseBLOB(FieldNo: Integer); override;
  // clear blob streams
  procedure ClearBLOBStreams(WriteOnly: Boolean = False); override;
  procedure SendModifiedBLOBValues;

  function LastAutoincValue(FieldNo: Integer): Int64; override;
  procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer); override;
  function GetTableState: TACRTableState; override;

  procedure LockTable(bWriteMode: Boolean); override;
  procedure UnlockTable(bWriteMode: Boolean); override;
  // return true if current record exists
  function IsRecordExists: Boolean; override;
public
  property CursorID: TACRObjectID read FCursorID;
end; // TACRClientCursor

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////

TACRClientSQLProcessor = class(TACRSQLProcessor)
private
  FSession: TACRClientSession;
  LRemoteQuery: Pointer; // pointer to prepared query
  FCursor: TACRCursor;
  FLive: Boolean;
protected
  procedure SendParams(Changed: Boolean);
  function ReceiveLiveQuery: TACRCursor;
  function ReceiveNotLiveQuery: TACRCursor;
public
  constructor Create(Query: TDataSet; aSession: TACRBaseSession; CaseIns: Boolean); overload;
  destructor Destroy; override;
  function OpenQuery(TableNames: TACRWideStringList = nil): TACRCursor; override;
public
  property Session: TACRClientSession read FSession;
  property Live: Boolean read FLive;
end;

var
ClientConnectionManager: TACRClientConnectionManager;

implementation

uses ACRMain,
ACRMemory // last
;

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientNetworkSettingsEditor.Create(Owner: TACRClientConnectParamsEditor);
begin
  FOwner := Owner;
  inherited Create;
  FConnectRetryCount := ACRConnectRetryCount;
  FConnectDelay := ACRConnectDelay;
  FUseServerSettings := False;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRClientNetworkSettingsEditor.Destroy;
begin
 inherited Destroy;
end; // Destroy

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRClientNetworkSettingsEditor.Assign(Source: TPersistent);
begin
if (Source <> nil) then
  if (Source is TACRClientNetworkSettingsEditor) then
  begin
    inherited Assign(Source);
    FConnectRetryCount := TACRClientNetworkSettingsEditor(Source).ConnectRetryCount;
    FConnectDelay := TACRClientNetworkSettingsEditor(Source).ConnectDelay;
    FUseServerSettings := TACRClientNetworkSettingsEditor(Source).UseServerSettings;
  end;
end; // Assign

//------------------------------------------------------------------------------
// Copy ClientNetwork settings to ConnectParams
//------------------------------------------------------------------------------
procedure TACRClientNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TACRConnectParams);
begin
  inherited CopySettingsToConnectParams(ConnectParams);
  ConnectParams.ConnectRetryCount := FConnectRetryCount;
  ConnectParams.ConnectDelay := FConnectDelay;
  ConnectParams.UseServerSettings := FUseServerSettings;
  ConnectParams.Protocol := Byte(FOwner.FProtocol);
end; // CopySettingsToConnectParams

//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TACRClientNetworkSettingsEditor.SetDefaultSettings(Value: TACRDefaultNetworkSettings);
begin
if Value = RestoreDefaultSettings then
  Exit;
case Value of
  ACRLocal:
    begin
      FConnectRetryCount := ACRLocalConnectRetryCount;
      FConnectDelay := ACRLocalConnectDelay;
      FResendDelay := ACRLocalResendDelay;
      FRequestDelay := ACRLocalRequestDelay;
    end;
  ACRLAN:
    begin
      FConnectRetryCount := ACRConnectRetryCount;
      FConnectDelay := ACRConnectDelay;
      FResendDelay := ACRResendDelay;
      FRequestDelay := ACRRequestDelay;
    end;
  ACRWAN:
    begin
      FConnectRetryCount := ACRWANConnectRetryCount;
      FConnectDelay := ACRWANConnectDelay;
      FResendDelay := ACRWANResendDelay;
      FRequestDelay := ACRWANRequestDelay;
    end;
  ACRModem:
    begin
      FConnectRetryCount := ACRModemConnectRetryCount;
      FConnectDelay := ACRConnectDelay;
      FResendDelay := ACRResendDelay;
      FRequestDelay := ACRRequestDelay;
    end;
end;
inherited SetDefaultSettings(Value);
end; // SetDefaultSettings

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRClientConnectParamsEditor.Create;
begin
  inherited;
  FNetworkSettings := TACRClientNetworkSettingsEditor.Create(Self);
  Protocol := ACRDefaultClientProtocol;
  FLocalPort := ACRDefaultClientPort;
  FServerID := ACRDefaultServerID;
  FRemoteHost := ACRDefaultHost;
  FCompressionAlgorithm := caNone;
  FCompressionMode := 1;
  FMinCacheSize := ACRMinCacheSize;
  FMaxCacheSize := ACRMaxCacheSize;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRClientConnectParamsEditor.Destroy;
begin
  FNetworkSettings.Free;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRClientConnectParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
    if (Source is TACRConnectionParamsEditor) then
    begin
      inherited Assign(Source);
      FServerID := TACRClientConnectParamsEditor(Source).ServerID;
      Protocol := TACRClientConnectParamsEditor(Source).Protocol;
      LocalPort := TACRClientConnectParamsEditor(Source).LocalPort;
      FRemoteHost := TACRClientConnectParamsEditor(Source).RemoteHost;
      FRemotePort := TACRClientConnectParamsEditor(Source).RemotePort;
      FCompressionAlgorithm := TACRClientConnectParamsEditor(Source)
        .CompressionAlgorithm;
      FCompressionMode := TACRClientConnectParamsEditor(Source).CompressionMode;
      FNetworkSettings.Assign(TACRClientConnectParamsEditor(Source)
          .NetworkSettings);
    end;
end; // Assign

//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TACRClientConnectParamsEditor.GetConnectParams: TACRConnectParams;
begin
  Result := inherited GetConnectParams;
  Result.CompressionAlgorithm := Byte(FCompressionAlgorithm);
  Result.CompressionMode := FCompressionMode;
  Result.RemoteHost := FRemoteHost;
  Result.RemotePort := FRemotePort;
  Result.ServerID := FServerID;
  Result.Protocol := Byte(FProtocol);
  if FProtocol = acrUDP then
    Result.LocalPort := NetworkSettings.FUDP.LocalPort
  else
    Result.LocalPort := NetworkSettings.FTCP.LocalPort;
  FNetworkSettings.CopySettingsToConnectParams(Result);
end; // GetConnectParams

//------------------------------------------------------------------------------
// SetProtocol
//------------------------------------------------------------------------------
procedure TACRClientConnectParamsEditor.SetProtocol(Value: TACRClientProtocol);
begin
  if Value = FProtocol then
    Exit;
  FProtocol := Value;
{$IFDEF RELEASE_BUILD}
  if NetworkSettings.FUDP <> nil then FreeAndNil(NetworkSettings.FUDP);
  if NetworkSettings.FTCP <> nil then FreeAndNil(NetworkSettings.FTCP);
{$ENDIF}
  if (FProtocol = acrUDP) then
   begin
    if NetworkSettings.FUDP = nil then
      NetworkSettings.FUDP := TACRNetworkSettingsUDPEditor.Create(NetworkSettings);
    RemotePort := ACRDefaultServerPort;
   end
  else
   begin
    if NetworkSettings.FTCP = nil then
      NetworkSettings.FTCP := TACRNetworkSettingsTCPEditor.Create(NetworkSettings);
    RemotePort := ACRDefaultServerPortTCP;
   end;
end; // SetProtocol

//------------------------------------------------------------------------------
// SetLocalPort
//------------------------------------------------------------------------------
procedure TACRClientConnectParamsEditor.SetLocalPort(Value: Cardinal);
// compatibility with old UDP only component
begin
  if Value = FLocalPort then
    Exit;
  if NetworkSettings.FUDP <> nil then
    NetworkSettings.FUDP.LocalPort := Value
  else
  if NetworkSettings.FTCP <> nil then
    NetworkSettings.FTCP.LocalPort := Value;
  FLocalPort := Value;
end; // SetLocalPort

//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TACRClientConnectParamsEditor.GetLocalPort: Cardinal;
// compatibility with old UDP only component
begin
  Result := 0;
  if NetworkSettings.FUDP <> nil then
    Result := NetworkSettings.FUDP.LocalPort
  else
   if NetworkSettings.FTCP <> nil then
     Result := NetworkSettings.FTCP.LocalPort;
end; // GetLocalPort


////////////////////////////////////////////////////////////////////////////////
//
// TACRClientSession
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get error message and raises an excpetion
//------------------------------------------------------------------------------
procedure TACRClientSession.CheckReceivedReply
(CorrectReply: TACRCommunicationReply);
var
Len: Integer;
ErrorMessage: WideString;
ErrorCode: Integer;
begin
if (FReceivedCommandHeader.Reply <> CorrectReply) then
begin
  ErrorMessage := ErrorL_CS_UnknownError;
  ErrorCode := ACR_CS_UnknownError;
  if (FReceivedCommandDataStream.Size > (SizeOf(Len) + SizeOf(ErrorCode)))
    then
  begin
    LoadDataFromStream(ErrorCode, SizeOf(ErrorCode),
      FReceivedCommandDataStream, 10860);
    LoadWideStringFromStream(ErrorMessage, FReceivedCommandDataStream, 10860);
    FReceivedCommandDataStream.Size := 0;
  end;
  raise EACRException.Create(ErrorCode, ErrorLRemoteCommandFailed,
    [Integer(FReceivedCommandHeader.Reply), ErrorMessage]);
end;
end; // CheckReceivedReply

//------------------------------------------------------------------------------
// db connected?
//------------------------------------------------------------------------------
function TACRClientSession.GetConnected: Boolean;
begin
Result := FConnected;
end; // GetConnected

//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TACRClientSession.SetConnected(Value: Boolean);
var
Len: Integer;
b: ByteBool;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Client start SetConnected SessionID = ' + IntToStr(FSessionID)
    + ', Value = ' + BoolToStr(Value, true) + ', FConnected = ' + BoolToStr
    (FConnected, true));
{$ENDIF}
if (FConnected <> Value) then
begin
  if (Value) then
  begin
    FConnecting := true;
    try
      try
{$IFDEF DEBUG_LOG_COMMUNICATION}
        aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID)
            + 'starting sonnect ....');
{$ENDIF}
        ClientConnectionManager.Connect(Self);
{$IFDEF DEBUG_LOG_COMMUNICATION}
        aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID)
            + 'starting sonnect .... OK');
{$ENDIF}
      except
        on e: EACRException do
        begin
          DoOnError(ACR_CS_ErrorConnectingClientSession, e.NativeError,
            Format(ErrorL_CS_ErrorConnectingClientSession,
              [FConnectParams.RemoteHost, FConnectParams.RemotePort,
              FConnectParams.ServerID, e.Message]));
          raise ;
        end;
        on e: Exception do
        begin
          DoOnError(ACR_CS_ErrorConnectingClientSession, -1,
            Format(ErrorL_CS_ErrorConnectingClientSession,
              [FConnectParams.RemoteHost, FConnectParams.RemotePort,
              FConnectParams.ServerID, e.Message]));
          raise ;
        end;
        else
          begin
            DoOnError(ACR_CS_ErrorConnectingClientSession, -1,
              Format(ErrorL_CS_ErrorConnectingClientSession,
                [FConnectParams.RemoteHost, FConnectParams.RemotePort,
                FConnectParams.ServerID, '']));
            raise ;
          end;
        end;
        FConnected := Value;
        FDisconnected := False;
        try
          // connecting to a remote database
          FSentCommandHeader.Request := accrqConnectDatabase;
          FSentCommandHeader.Reply := accrplNULL;
          FSentCommandDataStream.Size := 0;
          SaveAnsiStringToStream(DatabaseName, SentCommandDataStream, 10856);
          SaveDataToStream(FMinCacheSize, SizeOf(FMinCacheSize),
            SentCommandDataStream, 12305);
          SaveDataToStream(FMaxCacheSize, SizeOf(FMinCacheSize),
            SentCommandDataStream, 12306);
          SaveCryptoParamsToStream(FCryptoParams, SentCommandDataStream,
            11315);
          b := CaseInsensitive;
          // added in v.5.90
          SaveDataToStream(b, SizeOf(b), SentCommandDataStream, 12549);
{$IFDEF DEBUG_LOG_COMMUNICATION}
          aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID)
              + 'starting send command  ....');
{$ENDIF}
          if (not SendCommand) then
            raise EACRException.Create(11512,
              ErrorLCannotConnectToServerSendCommandFailed);
{$IFDEF DEBUG_LOG_COMMUNICATION}
          aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID)
              + ' starting receive command  ....');
{$ENDIF}
          if (not ReceiveCommand) then
            raise EACRException.Create(11513,
              ErrorLCannotConnectToServerReceiveCommandFailed);
{$IFDEF DEBUG_LOG_COMMUNICATION}
          aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID) +
              ' starting checking received command, reply = ' + IntToStr
              (Integer(FReceivedCommandHeader.Reply)));
{$ENDIF}
          CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_COMMUNICATION}
          aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID) +
              ' starting checking received command ok, reply = ' + IntToStr
              (Integer(FReceivedCommandHeader.Reply)));
{$ENDIF}
          LoadDataFromStream(FOptions, SizeOf(FOptions),
            ReceivedCommandDataStream, 10871);
          LoadDataFromStream(b, SizeOf(b), ReceivedCommandDataStream, 11066);
          FExclusive := b;
          ReceivedCommandDataStream.Size := 0;
{$IFDEF DEBUG_LOG_COMMUNICATION}
          aaWriteToLog('Client Connect SessionID = ' + IntToStr(FSessionID)
              + 'connection started ok!');
{$ENDIF}
        except
          FConnected := False;
          FDisconnected := true;
          FConnecting := False;
          raise ;
        end;
        finally
          FConnecting := False;
        end;
      end
    else
    begin
      // disconnecting a remote database
      FDisconnected := true;
      FConnected := Value;
      FSentCommandDataStream.Size := 0;
      FReceivedCommandDataStream.Size := 0;
      try
{$IFDEF DEBUG_LOG_COMMUNICATION}
        aaWriteToLog('Client  SessionID = ' + IntToStr(FSessionID)
            + 'starting dicsonnect ....');
{$ENDIF}
        ClientConnectionManager.Disconnect(Self);
{$IFDEF DEBUG_LOG_COMMUNICATION}
        aaWriteToLog('Client starting disconnect SessionID = ' + IntToStr
            (FSessionID) + 'starting dicsonnect .... OK');
{$ENDIF}
      except
        on e: EACRException do
          DoOnError(ACR_CS_ErrorDisconnectingClientSession, e.NativeError,
            Format(ErrorL_CS_ErrorDisconnectingClientSession,
              [FSessionID, e.Message]));
        on e: Exception do
          DoOnError(ACR_CS_ErrorDisconnectingClientSession, -1,
            Format(ErrorL_CS_ErrorDisconnectingClientSession,
              [FSessionID, e.Message]))
        else
          DoOnError(ACR_CS_ErrorDisconnectingClientSession, -1,
            Format(ErrorL_CS_ErrorDisconnectingClientSession,
              [FSessionID, '']));
      end;
    end;
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('Client finish SetConnected SessionID = ' + IntToStr
      (FSessionID) + ', Value = ' + BoolToStr(Value,
      true) + ', FConnected = ' + BoolToStr(FConnected, true));
{$ENDIF}
end; // SetConnected


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TACRClientSession.SetCaseInsensitive(Value: Boolean);
var b: ByteBool;
begin
  inherited SetCaseInsensitive(Value);
  if (Connected) then
  begin
    FSentCommandDataStream.Size := 0;
    FSentCommandHeader.Request := accrqSetCaseInsensitive;
    FSentCommandHeader.Reply := accrplNULL;
    b := Value;
    SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,12551);
    SendCommand;
  end;
end; // SetCaseInsensitive


//------------------------------------------------------------------------------
// call OnError event handler
//------------------------------------------------------------------------------
procedure TACRClientSession.DoOnError(ErrorCode: Integer;  NativeError: Integer = -1; ErrorMessage: AnsiString = '');
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog(
'==================================================================');
aaWriteToLog('Error in TACRClientSession!');
aaWriteToLog('ClassName = '+Self.ClassName);
aaWriteToLog(
'------------------------------------------------------------------');
aaWriteToLog('SessionID=' + IntToStr(Integer(Self.SessionID)));
aaWriteToLog('ErrorCode=' + IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError=' + IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage: "' + ErrorMessage + '"');
aaWriteToLog('GetTickCount = ' + IntToStr(aaGetTickCount));
aaWriteToLog(
'==================================================================');
{$ENDIF}
  if (Assigned(FOnError)) then
    FOnError(ErrorCode, NativeError, ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// check if database exists
//------------------------------------------------------------------------------
function TACRClientSession.GetDatabaseExists: Boolean;
var
  bCon: Boolean;
  Len: Integer;
{$IFDEF DEBUG_LOG_COMMUNICATION_SHOW_CLIENT}
  str: AnsiString; // DEBUG!!!
{$ENDIF}
begin
  Result := False;
  bCon := GetConnected;
  try
    if (not bCon) then
      ClientConnectionManager.Connect(Self, False, False);
    try
      FDisconnected := False;
      // send IsDatabaseExists request
      FSentCommandHeader.Request := accrqIsDatabaseExists;
      FSentCommandHeader.Reply := accrplNULL;
      Len := Length(DatabaseName);
      SaveDataToStream(Len, SizeOf(Len), SentCommandDataStream, 10873);
      SaveDataToStream(PAnsiChar(@DatabaseName[1])^, Len,
        SentCommandDataStream, 10874);

      // DEBUG!!!
{$IFDEF DEBUG_LOG_COMMUNICATION_SHOW_CLIENT}
      str := aaGetCurrentTimeAsString;
      Len := Length(str);
      SaveDataToStream(Len, SizeOf(Len), SentCommandDataStream, 40873);
      SaveDataToStream(PAnsiChar(@str[1])^, Len, SentCommandDataStream,
        40874);
      aaWriteToLog('CLIENT-> ' + str); // DEBUG!!!
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRClientSession.GetDatabaseExists}
      aaWriteToLog(
        'TACRClientSession.GetDatabaseExists starting... DatabaseName = ' +
          DatabaseName);
{$ENDIF}
      (*
        raise EACRException.Create(11571,ErrorLCannotSendCommandToServer);
        {$IFDEF DEBUG_TRACE_TACRClientSession.GetDatabaseExists}
        aaWriteToLog('TACRClientSession.GetDatabaseExists reveiving reply... DatabaseName = '+DatabaseName);
        {$ENDIF}
        raise EACRException.Create(11572,ErrorLCannotReceiveCommandFromServer);
        {$IFDEF DEBUG_TRACE_TACRClientSession.GetDatabaseExists}
        aaWriteToLog('TACRClientSession.GetDatabaseExists finished. Reply = '+IntToStr(Integer(FReceivedCommandHeader.Reply)));
        {$ENDIF}
      *)
      if (ExecuteCommand) then
          Result := (FReceivedCommandHeader.Reply = accrplYes);
    finally
      if (not bCon) then
        ClientConnectionManager.Disconnect(Self);
      FDisconnected := not bCon;
    end;
  except
  end;
end; // GetDatabaseExists

//------------------------------------------------------------------------------
// get tables list
//------------------------------------------------------------------------------
procedure TACRClientSession.GetTablesList(List: TACRWideStringList);
begin
  // send GetTablesList request
  List.Clear;
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqGetTablesList;
  FSentCommandHeader.Reply := accrplNULL;
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // loading tables list
      LoadTACRWideStringListFromStream(List, FReceivedCommandDataStream,
        10878);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // GetTablesList

//------------------------------------------------------------------------------
// return information about all tables
//------------------------------------------------------------------------------
function TACRClientSession.GetTablesInfo(SortByTableName: Boolean)
  : TACRTableInfoArray;
var
  i, Count: Integer;
begin
  // send GetTablesList request
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqGetTablesInfo;
  FSentCommandHeader.Reply := accrplNULL;
  SaveBooleanToStream(SortByTableName, FSentCommandDataStream, 11987);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // loading tables list
      LoadDataFromStream(Count, SizeOf(Count), FReceivedCommandDataStream,
        11933);
      SetLength(Result, Count);
      if (Count > 0) then
      begin
        for i := 0 to Count - 1 do
        begin
          LoadWideStringFromStream(Result[i].TableName,
            FReceivedCommandDataStream, 11935);
          LoadWideStringFromStream(Result[i].Comment,
            FReceivedCommandDataStream, 12355);
          LoadDataFromStream(Result[i].TableState, SizeOf(TACRTableState),
            FReceivedCommandDataStream, 12356);
          LoadDataFromStream(Result[i].CreationDate, SizeOf(TDateTime),
            FReceivedCommandDataStream, 12357);
        end;
      end;
      FReceivedCommandDataStream.Size := 0;
    end;
end; // GetTablesInfo

//------------------------------------------------------------------------------
// return table state  or 0 if not found
//------------------------------------------------------------------------------
function TACRClientSession.GetTableState(TableName: WideString)
  : TACRTableState;
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqGetTableState;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(TableName, FSentCommandDataStream, 11936);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // loading tables list
      LoadDataFromStream(Result, SizeOf(Result), FReceivedCommandDataStream,
        11937);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // GetTableState

//------------------------------------------------------------------------------
// return true if table exists
//------------------------------------------------------------------------------
function TACRClientSession.TableExists(TableName: WideString): Boolean;
begin
  Result := False;
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqIsTableExists;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(TableName, FSentCommandDataStream, 10884);
  if (ExecuteCommand) then
      Result := (FReceivedCommandHeader.Reply = accrplYes);
end; // TableExists

//------------------------------------------------------------------------------
// export database to SQL
//------------------------------------------------------------------------------
function TACRClientSession.ExportDatabaseToSQL(
                    ExportStructure:       Boolean = true;
                    AddDropTableCommand:   Boolean = true;
                    ExportIndexes:         Boolean = true;
                    AddDropIndexCommand:   Boolean = false;
                    ExportData:            Boolean = true;
                    ExportBLOBFields:      Boolean = true;
                    UseBracketsForNames:   Boolean = false;
                    ExportForeignKeys:     Boolean = true;
                    ExportStoredFunctions: Boolean = true;
                    ExportViews:           Boolean = true
                                                ): WideString;
begin
  Result := '';
  SentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqExportDatabaseToSQL;
  FSentCommandHeader.Reply := accrplNULL;
  SaveBooleanToStream(ExportStructure, FSentCommandDataStream, 12141);
  SaveBooleanToStream(AddDropTableCommand, FSentCommandDataStream, 12142);
  SaveBooleanToStream(ExportIndexes, FSentCommandDataStream, 12143);
  SaveBooleanToStream(AddDropIndexCommand, FSentCommandDataStream, 12144);
  SaveBooleanToStream(ExportData, FSentCommandDataStream, 12145);
  SaveBooleanToStream(ExportBLOBFields, FSentCommandDataStream, 12145);
  SaveBooleanToStream(UseBracketsForNames, FSentCommandDataStream, 12146);
  SaveBooleanToStream(ExportForeignKeys, FSentCommandDataStream, 12147);
  SaveBooleanToStream(ExportStoredFunctions, FSentCommandDataStream, 12148);
  SaveBooleanToStream(ExportViews, FSentCommandDataStream, 12606);
  // send command
  if (not SendCommand) then
    raise EACRException.Create(12149, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not ReceiveCommand) then
    raise EACRException.Create(12150, ErrorLCannotReceiveCommandFromServer);
  CheckReceivedReply(accrplOperationSucceed);
  LoadWideStringFromStream(Result, FReceivedCommandDataStream, 12151);
end; // ExportDatabaseToSQL

//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TACRClientSession.FlushFileBuffers;
begin
  SentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqFlushFileBuffers;
  FSentCommandHeader.Reply := accrplNULL;
  if (ExecuteCommand) then
    CheckReceivedReply(accrplOperationSucceed);
end; // FlushFileBuffers

//------------------------------------------------------------------------------
// return database format version
//------------------------------------------------------------------------------
function TACRClientSession.GetFormatVersion: Double;
begin
  Result := ACRVersion;
  if (GetConnected) then
  begin
    SentCommandDataStream.Size := 0;
    FSentCommandHeader.Request := accrqGetFormatVersion;
    FSentCommandHeader.Reply := accrplNULL;
    if (ExecuteCommand) then
      begin
        if (FReceivedCommandHeader.Reply = accrplOperationSucceed) then
          LoadDataFromStream(Result, SizeOf(Result),
            FReceivedCommandDataStream, 10891);
        FReceivedCommandDataStream.Size := 0;
      end;
  end;
end; // GetFormatVersion

//------------------------------------------------------------------------------
// return total number of pages
//------------------------------------------------------------------------------
function TACRClientSession.GetTotalPageCount: Integer;
begin
  Result := 0;
  if (GetConnected) then
  begin
    SentCommandDataStream.Size := 0;
    FSentCommandHeader.Request := accrqGetTotalPageCount;
    FSentCommandHeader.Reply := accrplNULL;
    if (ExecuteCommand) then
      begin
        if (FReceivedCommandHeader.Reply = accrplOperationSucceed) then
          LoadDataFromStream(Result, SizeOf(Result),
            FReceivedCommandDataStream, 10892);
        FReceivedCommandDataStream.Size := 0;
      end;
  end;
end; // GetTotalPageCount

//------------------------------------------------------------------------------
// return number of free pages
//------------------------------------------------------------------------------
function TACRClientSession.GetFreePageCount: Integer;
begin
  Result := 0;
  if (GetConnected) then
  begin
    SentCommandDataStream.Size := 0;
    FSentCommandHeader.Request := accrqGetFreePageCount;
    FSentCommandHeader.Reply := accrplNULL;
    if (ExecuteCommand) then
      begin
        if (FReceivedCommandHeader.Reply = accrplOperationSucceed) then
          LoadDataFromStream(Result, SizeOf(Result),
            FReceivedCommandDataStream, 10893);
        FReceivedCommandDataStream.Size := 0;
      end;
  end;
end; // GetFreePageCount

//------------------------------------------------------------------------------
// return true if database is encrypted
//------------------------------------------------------------------------------
function TACRClientSession.IsDatabaseEncrypted: Boolean;
var
  bCon: Boolean;
  Len: Integer;
begin
  Result := False;
  bCon := GetConnected;
  if (not bCon) then
    ClientConnectionManager.Connect(Self, False, False);
  try
    FDisconnected := False;
    // send request
    FSentCommandHeader.Request := accrqIsDatabaseEncrypted;
    FSentCommandHeader.Reply := accrplNULL;
    SentCommandDataStream.Size := 0;
    Len := Length(DatabaseName);
    SaveDataToStream(Len, SizeOf(Len), SentCommandDataStream, 10894);
    SaveDataToStream(PAnsiChar(@DatabaseName[1])^, Len,
      SentCommandDataStream, 10895);
    if (not SendCommand) then
      raise EACRException.Create(11573, ErrorLCannotSendCommandToServer);
    if (not ReceiveCommand) then
      raise EACRException.Create(11574, ErrorLCannotReceiveCommandFromServer);
    Result := (FReceivedCommandHeader.Reply = accrplYes);
  finally
    if (not bCon) then
      ClientConnectionManager.Disconnect(Self);
    FDisconnected := not bCon;
  end;
end; // IsDatabaseEncrypted

//------------------------------------------------------------------------------
// return true if database is encrypted by password or by key
//------------------------------------------------------------------------------
function TACRClientSession.IsDatabaseEncryptedByPassword: Boolean;
var
  bCon: Boolean;
  Len: Integer;
begin
  Result := False;
  bCon := GetConnected;
  if (not bCon) then
    ClientConnectionManager.Connect(Self, False, False);
  try
    FDisconnected := False;
    // send request
    FSentCommandHeader.Request := accrqIsDatabaseEncryptedByPassword;
    FSentCommandHeader.Reply := accrplNULL;
    SentCommandDataStream.Size := 0;
    Len := Length(DatabaseName);
    SaveDataToStream(Len, SizeOf(Len), SentCommandDataStream, 10896);
    SaveDataToStream(PAnsiChar(@DatabaseName[1])^, Len,
      SentCommandDataStream, 10897);
    if (not SendCommand) then
      raise EACRException.Create(11575, ErrorLCannotSendCommandToServer);
    if (not ReceiveCommand) then
      raise EACRException.Create(11576, ErrorLCannotReceiveCommandFromServer);
    Result := (FReceivedCommandHeader.Reply = accrplYes);
  finally
    if (not bCon) then
      ClientConnectionManager.Disconnect(Self);
    FDisconnected := not bCon;
  end;
end; // IsDatabaseEncryptedByPassword

//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TACRClientSession.IsCryptoParamsValid: Boolean;
var
  bCon: Boolean;
  Len: Integer;
begin
  Result := False;
  bCon := GetConnected;
  if (not bCon) then
    ClientConnectionManager.Connect(Self, False, False);
  try
    FDisconnected := False;
    // send request
    FSentCommandHeader.Request := accrqIsCryptoParamsValid;
    FSentCommandHeader.Reply := accrplNULL;
    SentCommandDataStream.Size := 0;
    Len := Length(DatabaseName);
    SaveDataToStream(Len, SizeOf(Len), SentCommandDataStream, 10906);
    SaveDataToStream(PAnsiChar(@DatabaseName[1])^, Len,
      SentCommandDataStream, 10907);
    SaveCryptoParamsToStream(FCryptoParams, SentCommandDataStream, 11314);
    if (not SendCommand) then
      raise EACRException.Create(11577, ErrorLCannotSendCommandToServer);
    if (not ReceiveCommand) then
      raise EACRException.Create(11578, ErrorLCannotReceiveCommandFromServer);
    Result := (FReceivedCommandHeader.Reply = accrplYes);
  finally
    if (not bCon) then
      ClientConnectionManager.Disconnect(Self);
    FDisconnected := not bCon;
  end;
end; // IsCryptoParamsValid

//------------------------------------------------------------------------------
// makes Exe database from edb file
//------------------------------------------------------------------------------
procedure TACRClientSession.MakeExeDatabase(ExeFileName,
  ExeDatabaseFileName: WideString);
begin
  raise EACRException.Create(11288, ErrorLOperationIsNotSupported);
end; // MakeExeDatabase

//------------------------------------------------------------------------------
// removes database file from executable database file
//------------------------------------------------------------------------------
procedure TACRClientSession.RemoveDatabaseFromExe;
begin
  raise EACRException.Create(11298, ErrorLOperationIsNotSupported);
end; // RemoveDatabaseFromExe

//------------------------------------------------------------------------------
// returns true if this file is an Accuracer database
//------------------------------------------------------------------------------
function TACRClientSession.IsAccuracerDatabaseFile: Boolean;
begin
  Result := False;
end; // IsAccuracerDatabaseFile

//------------------------------------------------------------------------------
// retrun true if database has active transaction
//------------------------------------------------------------------------------
function TACRClientSession.GetInTransaction: Boolean;
begin
  Result := False;
  // send request
  FSentCommandHeader.Request := accrqIsInTransaction;
  FSentCommandHeader.Reply := accrplNULL;
  SentCommandDataStream.Size := 0;
  if (ExecuteCommand) then
      Result := (FReceivedCommandHeader.Reply = accrplYes);
end; // GetInTransaction

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientSession.Create;
begin
  inherited;
  if ClientConnectionManager = nil then
    ClientConnectionManager := TACRClientConnectionManager.Create;
  FOnReceiveMessage := nil;
  FConnecting := False;
  FDisconnected := true;
end; // Create

//------------------------------------------------------------------------------
// do close session on network error
//------------------------------------------------------------------------------
procedure TACRClientSession.DoCloseSessionOnNetworkError;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('Client DoCloseSessionOnNetworkError starting, SessionID = ' +
      IntToStr(FSessionID));
{$ENDIF}
  if (FConnected) then
  begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
    aaWriteToLog(
      'Client DoCloseSessionOnNetworkError starting disconnect session, SessionID = '
        + IntToStr(FSessionID));
{$ENDIF}
    // disconnecting a remote database
    FDisconnected := true;
    FConnected := False;
    FSentCommandDataStream.Size := 0;
    FReceivedCommandDataStream.Size := 0;
{$IFDEF DEBUG_LOG_COMMUNICATION}
    aaWriteToLog(
      'Client DoCloseSessionOnNetworkError starting disconnect datasets, SessionID = '
        + IntToStr(FSessionID));
{$ENDIF}
    if (Assigned(FOnDisconnectRemoteDatasets)) then
      FOnDisconnectRemoteDatasets(False);
{$IFDEF DEBUG_LOG_COMMUNICATION}
    aaWriteToLog(
      'Client DoCloseSessionOnNetworkError datasets disconnected, SessionID = '
        + IntToStr(FSessionID));
{$ENDIF}
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('Client DoCloseSessionOnNetworkError finished, SessionID = ' +
      IntToStr(FSessionID));
{$ENDIF}
end; // DoCloseSessionOnNetworkError

//------------------------------------------------------------------------------
// start a transaction
//------------------------------------------------------------------------------
procedure TACRClientSession.StartTransaction;
begin
  // send request
  FSentCommandHeader.Request := accrqStartTransaction;
  FSentCommandHeader.Reply := accrplNULL;
  SentCommandDataStream.Size := 0;
  if (ExecuteCommand) then
      CheckReceivedReply(accrplOperationSucceed);
end; // StartTransaction

//------------------------------------------------------------------------------
// apply changes made by transaction
//------------------------------------------------------------------------------
procedure TACRClientSession.Commit(FlushFileBuffers: Boolean = true);
var
  b: ByteBool;
begin
  // send request
  FSentCommandHeader.Request := accrqCommit;
  FSentCommandHeader.Reply := accrplNULL;
  SentCommandDataStream.Size := 0;
  b := FlushFileBuffers;
  SaveDataToStream(b, SizeOf(b), FSentCommandDataStream, 10913);
  if (ExecuteCommand) then
      CheckReceivedReply(accrplOperationSucceed);
end; // Commit

//------------------------------------------------------------------------------
// cancel changes made by transaction
//------------------------------------------------------------------------------
procedure TACRClientSession.Rollback;
begin
  // send request
  FSentCommandHeader.Request := accrqRollback;
  FSentCommandHeader.Reply := accrplNULL;
  SentCommandDataStream.Size := 0;
  if (ExecuteCommand) then
      CheckReceivedReply(accrplOperationSucceed);
end; // Rollback

//------------------------------------------------------------------------------
// clear disk cache
//------------------------------------------------------------------------------
procedure TACRClientSession.ClearCache;
begin
  // send request
  FSentCommandHeader.Request := accrqClearCache;
  FSentCommandHeader.Reply := accrplNULL;
  SentCommandDataStream.Size := 0;
  if (ExecuteCommand) then
      CheckReceivedReply(accrplOperationSucceed);
end; // ClearCache

//------------------------------------------------------------------------------
// disconnect occurs when server is shutting down or network socket error occurs
//------------------------------------------------------------------------------
procedure TACRClientSession.OnDisconnect;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('Client OnDisconnect starting, SessionID = ' + IntToStr
      (FSessionID));
{$ENDIF}
  if (FConnecting) then
    raise EACRException.Create(11335, ErrorLCannotConnetToRemoteServer,
      [FConnectParams.RemoteHost, FConnectParams.RemotePort,
      FConnectParams.LocalPort, FConnectParams.ServerID]);
  if (FConnected) then
  begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
    aaWriteToLog
      ('Client OnDisconnect starting closing session, SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
    FDisconnected := true;
    FConnected := False;
    FSentCommandDataStream.Size := 0;
    FReceivedCommandDataStream.Size := 0;
{$IFDEF DEBUG_LOG_COMMUNICATION}
    aaWriteToLog(
      'Client OnDisconnect starting disonnect datasets, SessionID = ' +
        IntToStr(FSessionID));
{$ENDIF}
    if (Assigned(FOnDisconnectRemoteDatasets)) then
      FOnDisconnectRemoteDatasets(true);
{$IFDEF DEBUG_LOG_COMMUNICATION}
    aaWriteToLog('Client OnDisconnect datasets disonnected, SessionID = ' +
        IntToStr(FSessionID));
{$ENDIF}
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('Client OnDisconnect ok, SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
end; // OnDisconnect

//------------------------------------------------------------------------------
// Send command then receive answer, if needed
//------------------------------------------------------------------------------
function TACRClientSession.ExecuteCommand(AnswerNeeded: Boolean = true) : Boolean;
{$IFDEF DEBUG_LOG}
var
    str: String;
{$ENDIF}
var b:   Boolean;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
  Result := False;
  FRetry := 0;
  repeat
   try
    inc(FRetry);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStartTime(time2);
aaIncCounter(counter2);
{$ENDIF}
    b := SendCommand;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time2);
if (not b) then
 aaIncCounter(counter6);
{$ENDIF}
    if b then
     begin
      if not AnswerNeeded then
       begin
        Result := true;
        break;
       end
      else
      begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStartTime(time3);
aaIncCounter(counter3);
{$ENDIF}
       b := ReceiveCommand;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time3);
if (not b) then
 aaIncCounter(counter9);
{$ENDIF}
       if b then
        begin
         Result := true;
         break;
        end
       else // command not received
        begin
{$IFDEF LOG_CLIENT_COMMAND_RETRY}
aaWriteToLog('TACRClientSession.ExecuteCommand> Error: Retry # '+IntToStr(FRetry)+' - command not received');
{$ENDIF}
         FConnectParams.StartReceiveTimeOut := trunc(FConnectParams.StartReceiveTimeOut*(1+FRetry/4));
         FConnectParams.ReceiveTimeOut := trunc(FConnectParams.ReceiveTimeOut*(1+FRetry/4));
        end;
      end;
     end
    else // command not sent
     begin
{$IFDEF LOG_CLIENT_COMMAND_RETRY}
aaWriteToLog('TACRClientSession.ExecuteCommand> Error: Retry # '+IntToStr(FRetry)+' - command not sent');
{$ENDIF}
      FConnectParams.SendTimeOut := trunc(FConnectParams.SendTimeOut*(1+FRetry/4));
     end;
   finally
{$IFDEF LOG_CLIENT_COMMAND_RETRY}
    if Result then
      str := ''
    else
      str := ' not';
    aaWriteToLog('TACRClientSession.ExecuteCommand> Retry # '+IntToStr(FRetry)+' is'+str+' successfull!');
{$ENDIF}
   end;
  until FRetry >= FConnectParams.CommandRetryCount;
  if not Result then
   begin
{$IFDEF LOG_CLIENT_COMMAND_RETRY}
aaWriteToLog('TACRClientSession.ExecuteCommand> Error: disconnecting...');
{$ENDIF}
    SetConnected(False);
{$IFDEF LOG_CLIENT_COMMAND_RETRY}
aaWriteToLog('TACRClientSession.ExecuteCommand> Error: client disconnected');
{$ENDIF}
   end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
finally
aaStopTime(time1);
end;
{$ENDIF}
end; // ExecuteCommand


//------------------------------------------------------------------------------
// send command specified by SentCommandHeader [ optionally SentCommandDataStream ]
//------------------------------------------------------------------------------
function TACRClientSession.SendCommand: Boolean;
begin
  Result := False;
  if (not FDisconnected) then
    Result := inherited SendCommand;
end; // SendCommand

//------------------------------------------------------------------------------
// send buffer via established connection using connection manager
//------------------------------------------------------------------------------
procedure TACRClientSession.SendBuffer(var Buffer: PAnsiChar;
  BufferSize: Integer);
{$IFDEF DEBUG_LOG_COMMUNICATION}
var
  i, offset: Integer;
  b: Byte;
  grm: TACRGetRecordMode;
  bool: ByteBool;
  recID: TACRRecordID;
  IndexID: TACRObjectID;
  ws: WideString;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('C> ClientSession is starting to send a request...');
  aaWriteToLog('C> SessionID = ' + IntToStr(SessionID)
      + ', ServerID = ' + IntToStr(FConnectParams.ServerID));
  aaWriteToLog('C> Request = ' + IntToStr(Integer(FSentCommandHeader.Request))
    );
  aaWriteBufferToLog(Buffer, BufferSize);
  aaWriteToLog('C> Send Start Time = ' + aaGetCurrentTimeAsString);
  case FSentCommandHeader.Request of
    accrqGetRecordBuffer:
      begin
        offset := SizeOf(TACRCommunicationCommandHeader);
        Move(PAnsiChar(Buffer + offset)^, i, SizeOf(i));
        aaWriteToLog('C> CursorID = ' + IntToStr(i));
        offset := offset + SizeOf(Integer);
        Move(PAnsiChar(Buffer + offset)^, grm, SizeOf(grm));
        offset := offset + SizeOf(grm);
        case grm of
          grmCurrent:
            aaWriteToLog('C> grmCurrent');
          grmNext:
            aaWriteToLog('C> grmNext');
          grmPrior:
            aaWriteToLog('C> grmPrior');
        end;
        Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
        offset := offset + SizeOf(bool);
        aaWriteToLog('C> FirstPosition = ' + BoolToStr(bool, true));
        Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
        offset := offset + SizeOf(bool);
        aaWriteToLog('C> LastPosition = ' + BoolToStr(bool, true));
        Move(PAnsiChar(Buffer + offset)^, recID, SizeOf(recID));
        offset := offset + SizeOf(recID);
        aaWriteToLog('C> RecordID (PageNo . PageItemNo) = (' + IntToStr
            (recID.PageNo) + ' . ' + IntToStr(recID.PageItemNo) + ')');
        Move(PAnsiChar(Buffer + offset)^, IndexID, SizeOf(IndexID));
        aaWriteToLog('C> IndexID = ' + IntToStr(IndexID));
      end; // accrqGetRecordBuffer
    accrqInternalPost:
      begin
        offset := SizeOf(TACRCommunicationCommandHeader);
        Move(PAnsiChar(Buffer + offset)^, i, SizeOf(i));
        aaWriteToLog('C> CursorID = ' + IntToStr(i));
        Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
        offset := offset + SizeOf(bool);
        aaWriteToLog('C> ToInsert = ' + BoolToStr(bool, true));
        Move(PAnsiChar(Buffer + offset)^, recID, SizeOf(recID));
        offset := offset + SizeOf(recID);
        aaWriteToLog('C> RecordID (PageNo . PageItemNo) = (' + IntToStr
            (recID.PageNo) + ' . ' + IntToStr(recID.PageItemNo) + ')');
        Move(PAnsiChar(Buffer + offset)^, IndexID, SizeOf(IndexID));
        aaWriteToLog('C> IndexID = ' + IntToStr(IndexID));
      end; // accrqInternalPost
    accrqOpenTable:
      begin
        offset := SizeOf(TACRCommunicationCommandHeader);
        Move(PAnsiChar(Buffer + offset)^, i, SizeOf(Integer));
        offset := offset + SizeOf(Integer);
        ws := '';
        if (i > 0) then
        begin
          SetLength(ws, i div 2);
          Move(PAnsiChar(Buffer + offset)^, ws[1], i);
          offset := offset + i;
        end;
        Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
        aaWriteToLog('C> OpenTable: TableName = ' + ws + ', Exclusive = ' +
            BoolToStr(bool, true));
      end; // accrqOpenTable
  end;
{$ENDIF}
  ClientConnectionManager.SendBuffer(Self, Buffer, BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('C> Send End Time = ' + aaGetCurrentTimeAsString);
{$ENDIF}
end; // SendBuffer

//------------------------------------------------------------------------------
// wait while command will not be received
//------------------------------------------------------------------------------
function TACRClientSession.ReceiveCommand: Boolean;
var
  Buffer: PAnsiChar;
  BufferSize: Integer;
{$IFDEF DEBUG_LOG_COMMUNICATION}
var
  i, offset: Integer;
  b: Byte;
  grr: TACRGetRecordResult;
  bool: ByteBool;
  recID: TACRRecordID;
  IndexID: TACRObjectID;
{$ENDIF}
begin
  Result := False;
  if (FDisconnected) then
    Exit;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter3);
  aaStartTime(time3);
{$ENDIF}
  FCommandReceived := False;
{$IFDEF DEBUG_LOG_COMMUNICATION}
  aaWriteToLog('C> ClientSession is waiting for reply...');
  aaWriteToLog('C> SessionID = ' + IntToStr(SessionID)
      + ', ServerID = ' + IntToStr(FConnectParams.ServerID));
  aaWriteToLog('C> Receive Start Time = ' + aaGetCurrentTimeAsString);
{$ENDIF}
  try
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
    aaStartTime(time4);
{$ENDIF}
    ClientConnectionManager.ReceiveBuffer(Self, Buffer, BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
    aaStopTime(time4);
{$ENDIF}
    try
      ReceiveData(Buffer, BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION}
      aaWriteBufferToLog(Buffer, BufferSize);
      aaWriteToLog('C> Request = ' + IntToStr
          (Integer(FReceivedCommandHeader.Request)));
      aaWriteToLog('C> Reply = ' + IntToStr
          (Integer(FReceivedCommandHeader.Reply)));
      aaWriteToLog('C> Receive End Time = ' + aaGetCurrentTimeAsString);
      if (FReceivedCommandHeader.Reply = accrplOperationSucceed) then
        case FReceivedCommandHeader.Request of
          accrqGetRecordBuffer:
            begin
              offset := SizeOf(TACRCommunicationCommandHeader);
              Move(PAnsiChar(Buffer + offset)^, grr, SizeOf(grr));
              offset := offset + SizeOf(grr);
              case grr of
                grrOK:
                  aaWriteToLog('C> grrOK');
                grrBOF:
                  aaWriteToLog('C> grrBOF');
                grrEOF:
                  aaWriteToLog('C> grrEOF');
                grrError:
                  aaWriteToLog('C> grrError');
              end;
              Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
              offset := offset + SizeOf(bool);
              aaWriteToLog('C> FirstPosition = ' + BoolToStr(bool, true));
              Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
              offset := offset + SizeOf(bool);
              aaWriteToLog('C> LastPosition = ' + BoolToStr(bool, true));
              Move(PAnsiChar(Buffer + offset)^, recID, SizeOf(recID));
              offset := offset + SizeOf(recID);
              aaWriteToLog('C> RecordID (PageNo . PageItemNo) = (' + IntToStr
                  (recID.PageNo) + ' . ' + IntToStr(recID.PageItemNo) + ')');
            end; // accrqGetRecordBuffer
          accrqInternalPost:
            begin
              offset := SizeOf(TACRCommunicationCommandHeader);
              Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
              offset := offset + SizeOf(bool);
              aaWriteToLog('C> FirstPosition = ' + BoolToStr(bool, true));
              Move(PAnsiChar(Buffer + offset)^, bool, SizeOf(bool));
              offset := offset + SizeOf(bool);
              aaWriteToLog('C> LastPosition = ' + BoolToStr(bool, true));
              Move(PAnsiChar(Buffer + offset)^, recID, SizeOf(recID));
              offset := offset + SizeOf(recID);
              aaWriteToLog('C> RecordID (PageNo . PageItemNo) = (' + IntToStr
                  (recID.PageNo) + ' . ' + IntToStr(recID.PageItemNo) + ')');
            end; // accrqInternalPost
          accrqOpenTable:
            begin
              offset := SizeOf(TACRCommunicationCommandHeader);
              Move(PAnsiChar(Buffer + offset)^, i, SizeOf(i));
              offset := offset + SizeOf(i);
              aaWriteToLog('C> CursorID = ' + IntToStr(i));
            end; // accrqOpenTable
        end;
{$ENDIF}
    finally
      if (Buffer <> nil) and (BufferSize > 0) then
        MemoryManager.FreeAndNilMem(Buffer);
    end;
    Result := true;
  except
    on e: EACRException do
    begin
      DoOnError(ACR_CS_ErrorReceiveCommandFailed, e.NativeError,
        Format(ErrorL_CS_ErrorReceiveCommandFailed, [FSessionID, e.Message])
        );
    end;
    on e: Exception do
    begin
      DoOnError(ACR_CS_ErrorReceiveCommandFailed, -1,
        Format(ErrorL_CS_ErrorReceiveCommandFailed, [FSessionID, e.Message])
        );
    end
    else
    begin
      DoOnError(ACR_CS_ErrorReceiveCommandFailed, -1,
        Format(ErrorL_CS_ErrorReceiveCommandFailed, [FSessionID, '']));
    end;
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time3);
{$ENDIF}
  // aaWriteToLog('1 TACRClientSession.ReceiveCommand, BufferSize = '+IntToStr(BufferSize));
  // repeat
  // until (FCommandReceived);
end; // ReceiveCommand

//------------------------------------------------------------------------------
// send custom message
//------------------------------------------------------------------------------
procedure TACRClientSession.SendMessage(Buffer: PAnsiChar;
  BufferSize: Integer);
begin
  ClientConnectionManager.SendMessage(Self, Buffer, BufferSize);
end; // SendMessage

//------------------------------------------------------------------------------
// receive custom message
//------------------------------------------------------------------------------
procedure TACRClientSession.ReceiveMessage(Buffer: PAnsiChar;
  BufferSize: Integer);
begin
  if (TACRControlCode(Buffer^) = ACRServerCommand) then
  begin
    try
      if (Assigned(FOnReceiveCommand)) then
        FOnReceiveCommand(Buffer + SizeOf(TACRControlCode),
          BufferSize - SizeOf(TACRControlCode));
    finally
      MemoryManager.FreeAndNilMem(Buffer);
    end
  end
  else if (Assigned(FOnReceiveMessage)) then
    FOnReceiveMessage(Buffer, BufferSize);
end; // ReceiveMessage

//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRClientSession.GetTableComment(TableName: WideString): WideString;
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqGetTableComment;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(TableName, FSentCommandDataStream, 11970);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // loading tables list
      LoadWideStringFromStream(Result, FReceivedCommandDataStream, 11971);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // GetTableComment

//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRClientSession.SetTableComment(TableName, Comment: WideString);
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqSetTableComment;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(TableName, FSentCommandDataStream, 11972);
  SaveWideStringToStream(Comment, FSentCommandDataStream, 11973);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // SetTableComment

////////////////////////////////////////////////////////////////////////////////
//
// -------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 -------------------
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// create stored function / procedure
//------------------------------------------------------------------------------
procedure TACRClientSession.CreateStoredFunction(SQLScript: WideString);
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqCreateStoredFunction;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(SQLScript, FSentCommandDataStream, 12258);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // CreateStoredFunction

//------------------------------------------------------------------------------
// for CREATE FUNCTON inside SQL script
// current token is rwFUNCTION/rwPROCEDURE
//------------------------------------------------------------------------------
procedure TACRClientSession.CreateStoredFunction(StoredFunction: TObject;
  SQLScript: WideString);
begin
  raise EACRException.Create(12254, ErrorLOperationIsNotSupported);
end; // CreateStoredFunction

//------------------------------------------------------------------------------
// parse stored function - used in SQL engine
//------------------------------------------------------------------------------
procedure TACRClientSession.ParseStoredFunction(Lexer: TACRLexer;
  var Token: TToken; out StoredFunction: TObject; out SQLScript: WideString);
begin
  raise EACRException.Create(12255, ErrorLOperationIsNotSupported);
end; // ParseStoredFunction

//------------------------------------------------------------------------------
// drop stored function / procedure
//------------------------------------------------------------------------------
procedure TACRClientSession.DropStoredFunction(FunctionName: WideString);
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqDropStoredFunction;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(FunctionName, FSentCommandDataStream, 12260);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // DropStoredFunction

//------------------------------------------------------------------------------
// ALTER stored function - modify script
//------------------------------------------------------------------------------
procedure TACRClientSession.AlterStoredFunction(FunctionName,
  NewSQLScript: WideString);
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqAlterStoredFunction;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(FunctionName, FSentCommandDataStream, 12262);
  SaveWideStringToStream(NewSQLScript, FSentCommandDataStream, 12263);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // AlterStoredFunction

//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TACRClientSession.AlterStoredFunctionRename(FunctionName,
  NewFunctionName: WideString);
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqAlterStoredFunctionRename;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(FunctionName, FSentCommandDataStream, 12266);
  SaveWideStringToStream(NewFunctionName, FSentCommandDataStream, 12267);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // AlterStoredFunctionRename

//------------------------------------------------------------------------------
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
// params - list of TACRSQLParam
//------------------------------------------------------------------------------
function TACRClientSession.ExecuteStoredFunction(FunctionName: WideString;
  ResultValue: TACRVariant; Params: TACRSQLParams = nil): Boolean;
begin
  raise EACRException.Create(12256, ErrorLOperationIsNotSupported);
end; // ExecuteStoredFunction

//------------------------------------------------------------------------------
// return empty string if function not found; otherwise
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TACRClientSession.FindStoredFunction(FunctionName: WideString)
  : WideString;
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqFindStoredFunction;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(FunctionName, FSentCommandDataStream, 12270);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // load stored function SQL script
      LoadWideStringFromStream(Result, FReceivedCommandDataStream, 12271);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // FindStoredFunction

//------------------------------------------------------------------------------
// parse for execute
// return stored function object (TACRStoredFunction) if found or nil
// params - list of TACRExpression
//------------------------------------------------------------------------------
function TACRClientSession.ParseStoredFunctionParams(
                                      Lexer:          TACRLexer;
                                      parentFunction: TObject;
                                      var Token:      TToken;
                                      out Params:     TObject // TACRExpressions
                                    ): TObject; 
begin
  raise EACRException.Create(12257, ErrorLOperationIsNotSupported);
end; // ParseStoredFunctionParams


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRClientSession.GetStoredFunctions(FunctionNames: TStrings;
  FunctionSQLScripts: TStrings; SortNamesByAlphabet: Boolean);
var
  bGetScripts: Boolean;
begin
  if (FunctionNames = nil) then
    raise EACRException.Create(12274, ErrorLNilPointer);
  bGetScripts := (FunctionSQLScripts <> nil);
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqGetStoredFunctions;
  FSentCommandHeader.Reply := accrplNULL;
  SaveBooleanToStream(bGetScripts, FSentCommandDataStream, 12274);
  SaveBooleanToStream(SortNamesByAlphabet, FSentCommandDataStream, 12275);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // load function names
      LoadTStringListFromStream(FunctionNames, FReceivedCommandDataStream,
        12276);
      if (bGetScripts) then
        // load function scripts
        LoadTStringListFromStream(FunctionSQLScripts,
          FReceivedCommandDataStream, 12277);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // GetStoredFunctions

//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRClientSession.GetStoredFunctions
  (FunctionNames: TACRWideStringList;
  FunctionSQLScripts: TACRWideStringList; SortNamesByAlphabet: Boolean);
var
  bGetScripts: Boolean;
begin
  if (FunctionNames = nil) then
    raise EACRException.Create(12274, ErrorLNilPointer);
  bGetScripts := (FunctionSQLScripts <> nil);
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqGetStoredFunctions;
  FSentCommandHeader.Reply := accrplNULL;
  SaveBooleanToStream(bGetScripts, FSentCommandDataStream, 12278);
  SaveBooleanToStream(SortNamesByAlphabet, FSentCommandDataStream, 12279);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // load function names
      LoadTACRWideStringListFromStream(FunctionNames,
        FReceivedCommandDataStream, 12280);
      if (bGetScripts) then
        // load function scripts
        LoadTACRWideStringListFromStream(FunctionSQLScripts,
          FReceivedCommandDataStream, 12281);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // GetStoredFunctions

//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TACRClientSession.ExportStoredFunctionsToSQL(var SQL: WideString);
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqExportStoredFunctionsToSQL;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(SQL, FSentCommandDataStream, 12286);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      // load stored function SQL script
      SQL := '';
      LoadWideStringFromStream(SQL, FReceivedCommandDataStream, 12287);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // ExportStoredFunctionsToSQL


// -------- END OF STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ------------

//------------------------- VIEWS - added in v.6.00 ------------------------


//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TACRClientSession.CreateView(
                     ViewName:          WideString;
                     SelectStatement:   WideString;
                     Columns:           TACRWideStringList;
                     bWithCheckOption:  Boolean;
                     Comment:           WideString
                    );
var b: ByteBool;
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqCreateView;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(ViewName, FSentCommandDataStream, 12609);
  SaveWideStringToStream(SelectStatement, FSentCommandDataStream, 12610);
  b := ByteBool(Columns <> nil);
  SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,12611);
  if (b) then
   Columns.SaveToStream(FSentCommandDataStream);
  b := ByteBool(bWithCheckOption);
  SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,12612);
  SaveWideStringToStream(Comment, FSentCommandDataStream, 12613);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TACRClientSession.DropView(
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
var b: ByteBool;
begin
  FSentCommandDataStream.Size := 0;
  FSentCommandHeader.Request := accrqDropView;
  FSentCommandHeader.Reply := accrplNULL;
  SaveWideStringToStream(ViewName, FSentCommandDataStream, 12614);
  b := ByteBool(bCascade);
  SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,12615);
  if (ExecuteCommand) then
    begin
      CheckReceivedReply(accrplOperationSucceed);
      FReceivedCommandDataStream.Size := 0;
    end;
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TACRClientSession.FindView(
                     ViewName:          WideString
                 ): TACRViewDef;
begin
  Result := nil;
end; // FindView


//------------------------------------------------------------------------------
// return cursor created for the specified table or view name
//------------------------------------------------------------------------------
function TACRClientSession.CreateCursor(TableName: WideString; bOpenView: Boolean): TACRCursor;
begin
  Result := TACRClientCursor.Create;
  Result.TableName := TableName;
  Result.Session := Self;
end; // CreateCursor

//------------------------- END OF VIEWS - added in v.6.00 ------------------------



////////////////////////////////////////////////////////////////////////////////
//
// TACRClientRecordCache - used in client-server
// on client side (with record buffers)
//
////////////////////////////////////////////////////////////////////////////////
{$IFDEF DEBUG_LOG}

procedure TACRClientRecordCache.WriteRecords;
var
  i: Integer;
  s: AnsiString;
begin
  s := #13#10 + 'FRecordNumbers: ItemCount = ' + IntToStr(FRecords.ItemCount);
  for i := 0 to FRecordNumbers.ItemCount - 1 do
    s := s + #13#10 + IntToStr(FRecordNumbers.Items[i]);
  s := s + #13#10 + 'FRecords: ItemCount = ' + IntToStr(FRecords.ItemCount);
  for i := 0 to FRecords.ItemCount - 1 do
    s := s + #13#10 + '(' + IntToStr(FRecords.Items[i].PageNo)
      + ' . ' + IntToStr(FRecords.Items[i].PageItemNo) + ')';
  aaWriteToLog(s);
end; // WriteRecords

procedure TACRClientRecordCache.WriteAllData(Caption: AnsiString);
begin
  aaWriteToLog(Caption + #13#10 + 'Cursor.TableName = ' + LCursor.TableName +
      ', InMemory = ' + BoolToStr(LCursor.InMemory,
      true) + ', LCursor.ServerID = ' + IntToStr(TACRClientCursor(LCursor)
        .CursorID) + #13#10 + 'FLoaded = ' + BoolToStr(FLoaded,
      true) + #13#10 + 'FLastLoadedTime = ' + IntToStr(FLastLoadedTime)
      + ACRGetTableStateAsString(FState) + #13#10 + 'FRecordCount = ' +
      IntToStr(FRecordCount) + #13#10 + 'FNumRecords = ' + IntToStr
      (FNumRecords) + #13#10 + 'FFirstRecordID (PageNo . PageItemNo) = (' +
      IntToStr(FFirstRecordID.PageNo) + ' . ' + IntToStr
      (FFirstRecordID.PageItemNo) + ')' + #13#10 +
      'FLastRecordID (PageNo . PageItemNo) = (' + IntToStr
      (FLastRecordID.PageNo) + ' . ' + IntToStr(FLastRecordID.PageItemNo)
      + ')' + #13#10 + 'FCurrentRecordID (PageNo . PageItemNo) = (' +
      IntToStr(FCurrentRecordID.PageNo) + ' . ' + IntToStr
      (FCurrentRecordID.PageItemNo) + ')' + #13#10 +
      'FCurrentRecordPosition = ' + IntToStr(FCurrentRecordPosition)
      + #13#10 + 'LCursor.CurrentRecordID (PageNo . PageItemNo) = (' +
      IntToStr(LCursor.CurrentRecordID.PageNo) + ' . ' + IntToStr
      (LCursor.CurrentRecordID.PageItemNo) + ')' + #13#10 +
      'LCursor.FirstPosition = ' + BoolToStr(LCursor.FirstPosition,
      true) + #13#10 + 'LCursor.LastPosition = ' + BoolToStr
      (LCursor.LastPosition, true) + #13#10 + 'LCursor.RecordSize = ' +
      IntToStr(LCursor.RecordSize) + #13#10 + 'FMinRecords = ' + IntToStr
      (FMinRecords) + #13#10 + 'FMaxRecords = ' + IntToStr(FMaxRecords)
      + #13#10 + 'FAllocatedRecords = ' + IntToStr(FAllocatedRecords));
  WriteRecords;
end;
{$ENDIF}

//------------------------------------------------------------------------------
// resize cache
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.ResizeCache(NewRecordCount: Integer);
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter7);
  aaStartTime(time7);
{$ENDIF}
  inherited ResizeCache(NewRecordCount);
  FAllocatedRecords := NewRecordCount;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time7);
{$ENDIF}
end; // ResizeCache

//------------------------------------------------------------------------------
// return recommneded record count to allocate
//------------------------------------------------------------------------------
function TACRClientRecordCache.GetNumRecords: Integer;
begin
  if ((not FLoaded) or (FAllocatedRecords < FMinRecords)) then
    Result := FMinRecords
  else
  if (ACRGetTickCountDiff(aaGetTickCount,
      FLastLoadedTime) > ACRMinTimeToExtendClientCache) then
  begin
    Result := FAllocatedRecords * 2;
    if (Result > FMaxRecords) then
      Result := FMaxRecords;
  end
  else
    Result := FAllocatedRecords;
end; // GetNumRecords

//------------------------------------------------------------------------------
// stores only 1 current record, but does not change FAllocatedRecords
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.ResetCache(RecNo: TACRRecordNo);
begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_RESET_ON_CLIENT}
  aaWriteToLog('> TACRClientRecordCache.ResetCache, RecNo = ' + IntToStr
      (RecNo));
{$ENDIF}
  ResizeCache(1);
  FNumRecords := 1;
  FRecords.ItemCount := 1;
  FRecordNumbers.ItemCount := 1;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_RESET_ON_CLIENT}
  aaWriteToLog('1. TACRClientRecordCache.ResetCache, RecNo = ' + IntToStr
      (RecNo));
{$ENDIF}
  MoveCurrentRecord(0, RecNo);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_RESET_ON_CLIENT}
  aaWriteToLog('2. TACRClientRecordCache.ResetCache, RecNo = ' + IntToStr
      (RecNo));
{$ENDIF}
  // other record first
  if (RecNo > 1) then
    FillChar(FFirstRecordID, SizeOf(FFirstRecordID), $FF);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_RESET_ON_CLIENT}
  aaWriteToLog('2. TACRClientRecordCache.ResetCache, RecNo = ' + IntToStr
      (RecNo));
{$ENDIF}
  // other record last
  if (RecNo < FRecordCount) then
    FillChar(FLastRecordID, SizeOf(FLastRecordID), $FF);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_RESET_ON_CLIENT}
  aaWriteToLog('< TACRClientRecordCache.ResetCache, RecNo = ' + IntToStr
      (RecNo));
{$ENDIF}
end; // ResetCache

//------------------------------------------------------------------------------
// shifts NumRecords records from Position to beginning (decrease RecNo) or to end (increase RecNo)
// shift is performed on 1 record only (RecNo -1 or RecNo+1)
// this operation does not resize cache
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.ShiftRecords(ToBeginning: Boolean;
  Position, NumRecords: TACRRecordNo);
var
  OldPos, NewPos, Count: TACRRecordNo;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter9);
  aaStartTime(time9);
{$ENDIF}
  if (NumRecords <= 0) then
    Count := FNumRecords
  else
    Count := NumRecords;
  if (Count <= 0) then
    Exit;
  if (ToBeginning) then
  begin
    // to beginning
    if (Position > 0) then
    begin
      OldPos := Position;
      NewPos := Position - 1;
    end
    else
    begin
      OldPos := 1;
      NewPos := 0;
    end;
    if (OldPos + Count > FNumRecords) then
    begin
      Count := FNumRecords - OldPos;
      if (Count <= 0) then
        Exit;
    end;
  end
  else
  begin
    if (Position >= FNumRecords - 1) then
      Exit;
    // to end
    OldPos := Position;
    NewPos := Position + 1;
    if (NewPos + Count > FNumRecords) then
    begin
      Count := FNumRecords - NewPos;
      if (Count <= 0) then
        Exit;
    end;
  end;
  Move(FRecords.Items[OldPos], FRecords.Items[NewPos],
    Count * SizeOf(TACRRecordID));
  Move(FRecordNumbers.Items[OldPos], FRecordNumbers.Items[NewPos],
    Count * SizeOf(TACRRecordNo));
  Move(PAnsiChar(FBuffer + OldPos * LCursor.RecordSize)^,
    PAnsiChar(FBuffer + NewPos * LCursor.RecordSize)^,
    Count * LCursor.RecordSize);
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time9);
{$ENDIF}
end; // ShiftRecords

//------------------------------------------------------------------------------
// update RecNo
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.UpdateRecNo(Increase: Boolean;
  Position, NumRecords: TACRRecordNo);
var
  CurPos, LastPos: TACRRecordNo;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter10);
  aaStartTime(time10);
{$ENDIF}
  CurPos := Position;
  LastPos := CurPos + NumRecords;
  while ((CurPos < FNumRecords) and (CurPos < LastPos)) do
  begin
    if (Increase) then
      FRecordNumbers.Items[CurPos] := FRecordNumbers.Items[CurPos] + 1
    else
      FRecordNumbers.Items[CurPos] := FRecordNumbers.Items[CurPos] - 1;
    inc(CurPos);
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time10);
{$ENDIF}
end; // UpdateRecNo

//------------------------------------------------------------------------------
// move current record
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.MoveCurrentRecord(RecPos,
  RecNo: TACRRecordNo);
begin
  if ((RecPos < 0) or (RecPos >= FNumRecords)) then
    raise EACRException.Create(12341, ErrorLInvalidItemNumber,
      [RecPos, FNumRecords]);
  if (RecPos >= FAllocatedRecords) then
    raise EACRException.Create(12342, ErrorLInvalidItemNumber,
      [RecPos, FAllocatedRecords]);
  FCurrentRecordPosition := RecPos;
  if (FCurrentRecordPosition = 0) then
    Move(LCursor.CurrentRecordBuffer^, FBuffer^, LCursor.RecordSize)
  else
    Move(LCursor.CurrentRecordBuffer^,
      PAnsiChar(FBuffer + FCurrentRecordPosition * LCursor.RecordSize)^,
      LCursor.RecordSize);
  Move(LCursor.CurrentRecordID, FRecords.Items[FCurrentRecordPosition],
    SizeOf(TACRRecordID));
  FRecordNumbers.Items[FCurrentRecordPosition] := RecNo;
  if (RecNo = 1) then
    Move(LCursor.CurrentRecordID, FFirstRecordID, SizeOf(FFirstRecordID));
  if (RecNo = FRecordCount) then
    Move(LCursor.CurrentRecordID, FLastRecordID, SizeOf(FLastRecordID))
end; // MoveCurrentRecord

//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.InsertRecord(RecNo: TACRRecordNo);
var
  newAllocRecCount, i, half: Integer;
  lowRecNo, Position: TACRRecordNo;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter8);
  aaStartTime(time8);
{$ENDIF}
  newAllocRecCount := GetNumRecords;
  if (newAllocRecCount > FAllocatedRecords) then
    ResizeCache(newAllocRecCount);
  if (FRecordCount <= 0) or (FNumRecords <= 0) then
  begin
    ResetCache(RecNo);
    Exit;
  end;
  lowRecNo := FRecordNumbers.Items[0];
  if ((RecNo < lowRecNo) or (RecNo > lowRecNo + FNumRecords)) then
  begin
    ResetCache(RecNo);
    Exit;
  end;
  Position := RecNo - lowRecNo; // 0 ... FNumRecords
  if (FNumRecords < FAllocatedRecords) then
  begin
    // do not remove record from cache
    if (Position < FNumRecords) then
    begin
      // not last record in cache
      // increase RecNo in all records starting from the inserted to end
      UpdateRecNo(true, Position, FNumRecords - Position);
      // add 1 record to cache
      inc(FNumRecords);
      FRecords.ItemCount := FNumRecords;
      FRecordNumbers.ItemCount := FNumRecords;
      // shift all records after the inserted one by 1 position to end
      ShiftRecords(False, Position, FNumRecords - 1 - Position);
    end
    else
    begin
      // last record in cache
      inc(FNumRecords);
      FRecords.ItemCount := FNumRecords;
      FRecordNumbers.ItemCount := FNumRecords;
    end;
    // copy current record to cache
    MoveCurrentRecord(Position, RecNo);
  end
  else
  begin
    half := FNumRecords div 2;
    // remove last record from cache
    if (Position <= half) then
    begin
      // position of inserted record is before the half of current cache
      // increase RecNo in all records starting from the inserted to end
      UpdateRecNo(true, Position, FNumRecords - Position);
      // shift all records after the inserted one by 1 position to end
      ShiftRecords(False, Position, FNumRecords - Position);
      // copy current record to cache
      MoveCurrentRecord(Position, RecNo);
    end
    else
    begin
      // position of inserted record is same or after the half of current cache
      // increase RecNo in all records starting from the inserted to end
      UpdateRecNo(true, Position, FNumRecords - Position);
      // shift all records after the inserted one by 1 position to end
      ShiftRecords(true, 1, Position - 1);
      // copy current record to cache
      MoveCurrentRecord(Position - 1, RecNo);
    end;
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time8);
{$ENDIF}
end; // InsertRecord

//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.UpdateRecord(RecNo: TACRRecordNo);
var
  lowRecNo, OldPosition, NewPosition: TACRRecordNo;
  i: Integer;
begin
  OldPosition := FRecords.FindRecordByID(LCursor.CurrentRecordID);
  if (OldPosition < 0) or (FNumRecords <= 0) then
  begin
    ResetCache(RecNo);
    Exit;
  end;
  lowRecNo := FRecordNumbers.Items[0];
  if ((RecNo < lowRecNo) or (RecNo >= (lowRecNo + FNumRecords))) then
  begin
    ResetCache(RecNo);
    Exit;
  end;
  NewPosition := RecNo - lowRecNo;
  if (NewPosition < OldPosition) then
  begin
    // increase RecNo in records [NewPosition,OldPosition-1]
    UpdateRecNo(true, NewPosition, OldPosition - NewPosition);
    // move records [NewPosition,OldPosition-1] to end by 1 record
    ShiftRecords(False, NewPosition, OldPosition - NewPosition);
  end
  else if (NewPosition > OldPosition) then
  begin
    // increase RecNo in records [OldPosition,NewPosition-1]
    UpdateRecNo(False, OldPosition + 1, NewPosition - OldPosition);
    // move records [OldPosition,NewPosition-1] to beginning by 1 record
    ShiftRecords(False, OldPosition + 1, NewPosition - OldPosition);
  end;
  MoveCurrentRecord(NewPosition, RecNo);
end; // UpdateRecord

//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.DeleteRecord(OldRecordID: TACRRecordID;
  RecNo: TACRRecordNo);
begin
  FCurrentRecordPosition := FRecords.FindRecordByID(OldRecordID);
  if (FCurrentRecordPosition >= 0) then
  begin
    if ((FNumRecords <= 1) and (FRecordCount > 0)) then
      FLoaded := False
    else
    begin
      if (FCurrentRecordPosition < (FNumRecords - 1)) then
      begin
        // decrease RecNo in all records after deleted record
        UpdateRecNo(False, FCurrentRecordPosition + 1,
          FNumRecords - FCurrentRecordPosition - 1);
        // shift all records after deleted record to beginning by 1 position
        ShiftRecords(true, FCurrentRecordPosition + 1,
          FNumRecords - FCurrentRecordPosition - 1);
      end;
      Dec(FNumRecords);
      FRecords.ItemCount := FNumRecords;
      FRecordNumbers.ItemCount := FNumRecords;
      if (FRecordCount > 0) then
      begin
        if (FNumRecords > 0) then
        begin
          if (ACRIsEqualRecordID(OldRecordID, FFirstRecordID)) then
            Move(FRecords.Items[0], FFirstRecordID, SizeOf(TACRRecordID));
          if (ACRIsEqualRecordID(OldRecordID, FLastRecordID)) then
            Move(FRecords.Items[FNumRecords - 1], FLastRecordID,
              SizeOf(TACRRecordID));
          FCurrentRecordPosition := FRecordNumbers.IndexOf(RecNo);
          if (FCurrentRecordPosition < 0) then
            ResetCache(RecNo)
          else
            Move(LCursor.CurrentRecordBuffer^,
              PAnsiChar
                (FBuffer + FCurrentRecordPosition *
                  LCursor.RecordSize)^, LCursor.RecordSize);
        end;
      end;
    end;
  end;
end; // DeleteRecord

//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.LoadFromStream(Stream: TACRMemoryStream);
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter5);
  aaStartTime(time5);
{$ENDIF}
  inherited LoadFromStream(Stream);
  FCurrentRecordPosition := -1;
  FAllocatedRecords := FNumRecords;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
  WriteAllData('TACRClientRecordCache.LoadFromStream - cache loaded: ');
{$ENDIF}
end; // LoadFromStream

//------------------------------------------------------------------------------
// get record buffer
//------------------------------------------------------------------------------
function TACRClientRecordCache.GetRecordBuffer(GetRecordMode: TACRGetRecordMode): TACRGetRecordResult;
var
  recID: TACRRecordID;
  pos: Integer;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
  debugStr: String;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
  Move(LCursor.CurrentRecordID, recID, SizeOf(recID));
  case GetRecordMode of
    grmCurrent:
      debugStr := 'TACRClientRecordCache.GetRecordBuffer: grmCurrent';
    grmNext:
      debugStr := 'TACRClientRecordCache.GetRecordBuffer: grmNext';
    grmPrior:
      debugStr := 'TACRClientRecordCache.GetRecordBuffer: grmPrior';
  end;
  WriteAllData(debugStr);
  aaWriteToLog('LCursor.CurrentRecordBuffer = ' + IntToHex
      (Integer(LCursor.CurrentRecordBuffer), 8));
  try
{$ENDIF}
    Result := grrError;
    if (LCursor.CurrentRecordBuffer = nil) then
    begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
      aaWriteToLog(
        'TACRClientRecordCache.GetRecordBuffer - CurrentRecordBuffer is nil!'
        );
{$ENDIF}
      Exit;
    end;
    Result := grrReloadCache;
    if (not FLoaded) then
    begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
      aaWriteToLog(
        'TACRClientRecordCache.GetRecordBuffer - cache is not loaded!');
{$ENDIF}
      Exit;
    end;
    if (FRecordCount <= 0) then
    begin
      Result := grrEOF;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
      aaWriteToLog('TACRClientRecordCache.GetRecordBuffer - EOF!');
{$ENDIF}
      Exit;
    end;
    if ((GetRecordMode = grmCurrent) and
        (LCursor.FirstPosition or LCursor.LastPosition)) then
    begin
      Result := grrError;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
      aaWriteToLog(
        'TACRClientRecordCache.GetRecordBuffer - Error (grmCurrent and (first or last))!');
{$ENDIF}
      Exit;
    end;
    if (GetRecordMode = grmPrior) and
      (LCursor.FirstPosition or ((not LCursor.LastPosition)
          and ACRIsEqualRecordID(LCursor.CurrentRecordID, FFirstRecordID))
      ) then
    begin
      Result := grrBOF;
      LCursor.FirstPosition := true;
      LCursor.LastPosition := False;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
      aaWriteToLog('TACRClientRecordCache.GetRecordBuffer - BOF!');
{$ENDIF}
      Exit;
    end;
    if (GetRecordMode = grmNext) and
      (LCursor.LastPosition or ((not LCursor.FirstPosition)
          and ACRIsEqualRecordID(LCursor.CurrentRecordID, FLastRecordID)))
      then
    begin
      Result := grrEOF;
      LCursor.FirstPosition := False;
      LCursor.LastPosition := true;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
      aaWriteToLog('TACRClientRecordCache.GetRecordBuffer - EOF #2!');
{$ENDIF}
      Exit;
    end;
    if (LCursor.FirstPosition) then
    begin
      // get first record
      FCurrentRecordPosition := 0;
      // reload cache if first record does not exist in current dataset record map
      if (not ACRIsEqualRecordID(FFirstRecordID,
          FRecords.Items[FCurrentRecordPosition])) then
      begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
        aaWriteToLog(
          'TACRClientRecordCache.GetRecordBuffer - reload cache, first record is before cache');
{$ENDIF}
        Exit;
      end;
      Result := grrOK;
    end
    else if (LCursor.LastPosition) then
    begin
      // get last record
      FCurrentRecordPosition := FNumRecords - 1;
      // reload cache if last record does not exist current dataset record map
      if (not ACRIsEqualRecordID(FLastRecordID,
          FRecords.Items[FCurrentRecordPosition])) then
      begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
        aaWriteToLog(
          'TACRClientRecordCache.GetRecordBuffer - reload cache, last record is after cache');
{$ENDIF}
        Exit;
      end;
      Result := grrOK;
    end
    else
    begin
      FCurrentRecordPosition := FRecords.FindRecordByID
        (LCursor.CurrentRecordID);
      if (FCurrentRecordPosition < 0) then
      begin
        // not found in cache - reload cache
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
        aaWriteToLog(
          'TACRClientRecordCache.GetRecordBuffer - current record not found!'
          );
{$ENDIF}
        Exit;
      end;
      // reload cache if we go out of cache - to the end of table
      if (GetRecordMode = grmNext) then
        if (FCurrentRecordPosition = FNumRecords - 1) then
        begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
          aaWriteToLog(
            'TACRClientRecordCache.GetRecordBuffer - next record is after end of cache!');
{$ENDIF}
          Exit;
        end
        else
        begin
          inc(FCurrentRecordPosition);
          LCursor.FirstPosition := False;
        end;
      // reload cache if we go out of cache - to the end of table
      if (GetRecordMode = grmPrior) then
        if (FCurrentRecordPosition = 0) then
        begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
          aaWriteToLog(
            'TACRClientRecordCache.GetRecordBuffer - next record is before beginning of cache!');
{$ENDIF}
          Exit;
        end
        else
        begin
          Dec(FCurrentRecordPosition);
          LCursor.LastPosition := False;
        end;
    end;
    pos := FCurrentRecordPosition * LCursor.RecordSize;
    try
      Move(FRecords.Items[FCurrentRecordPosition], FCurrentRecordID,
        SizeOf(TACRRecordID));
      Move(FCurrentRecordID, LCursor.CurrentRecordID, SizeOf(TACRRecordID));
      Move(PAnsiChar(FBuffer + pos)^, LCursor.CurrentRecordBuffer^,
        LCursor.RecordSize);
      LCursor.FirstPosition := False;
      LCursor.LastPosition := False;
      Result := grrOK;
    except
      on e: Exception do
      begin
        Result := grrError;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
        aaWriteToLog
          ('TACRClientRecordCache.GetRecordBuffer - Error:' + #13#10 +
            e.Message);
{$ENDIF}
      end;
    end;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_ON_CLIENT}
  finally
    case Result of
      grrOK:
        debugStr := 'grrOK';
      grrBOF:
        debugStr := 'grrBOF';
      grrEOF:
        debugStr := 'grrEOF';
      grrError:
        debugStr := 'grrError';
      grrReloadCache:
        debugStr := 'grrReloadCache';
    end;
    Move(LCursor.CurrentRecordID, recID, SizeOf(recID));
    if (Result = grrOK) then
      if (FCurrentRecordPosition >= 0) then
        debugStr := debugStr + #13#10 + 'Current RecNo = ' + IntToStr
          (FRecordNumbers.Items[FCurrentRecordPosition]);
    aaWriteToLog('< TACRClientRecordCache.GetRecordBuffer. ' + #13#10 +
        'CursorID = ' + IntToStr(TACRClientCursor(LCursor).CursorID)
        + #13#10 + 'TableName = ' + LCursor.TableName + #13#10 +
        debugStr + #13#10 + 'CurrentRecordID (PageNo . PageItemNo) = (' +
        IntToStr(recID.PageNo) + ' . ' + IntToStr(recID.PageItemNo)
        + ')' + #13#10 + 'FCurrentRecordID (PageNo . PageItemNo) = (' +
        IntToStr(FCurrentRecordID.PageNo) + ' . ' + IntToStr
        (FCurrentRecordID.PageItemNo) + ')' + #13#10 +
        'FCurrentRecordPosition = ' + IntToStr(FCurrentRecordPosition)
        + #13#10 + 'FirstPosition = ' + BoolToStr(LCursor.FirstPosition,
        true) + #13#10 + 'LastPosition = ' + BoolToStr
        (LCursor.LastPosition, true));
    if (Result = grrOK) then
      LCursor.WriteRecordBufferToLog(LCursor.CurrentRecordBuffer);
  end;
{$ENDIF}
end; // GetRecordBuffer

//------------------------------------------------------------------------------
// get record count
//------------------------------------------------------------------------------
function TACRClientRecordCache.GetRecordCount: TACRRecordNo;
begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_COUNT_ON_CLIENT}
  aaWriteToLog('> TACRClientRecordCache.GetRecordCount FLoaded = ' + BoolToStr
      (FLoaded, true) + #13#10 + 'FRecordCount = ' + IntToStr(FRecordCount));
{$ENDIF}
  if (FLoaded) then
    Result := FRecordCount
  else
    Result := -1;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_GET_RECORD_COUNT_ON_CLIENT}
  aaWriteToLog('< TACRClientRecordCache.GetRecordCount Result = ' + IntToStr
      (Result));
{$ENDIF}
end; // GetRecNo

//------------------------------------------------------------------------------
// get record number
//------------------------------------------------------------------------------
function TACRClientRecordCache.GetRecNo: TACRRecordNo;
begin
  if (FLoaded) then
  begin
    SetCurrentRecord;
    if (FCurrentRecordPosition < 0) then
      Result := -1
    else
      Result := FRecordNumbers.Items[FCurrentRecordPosition];
  end
  else
    Result := -1;
end; // GetRecNo

//------------------------------------------------------------------------------
// set RecNo
//------------------------------------------------------------------------------
function TACRClientRecordCache.SetRecNo(RecNo: TACRRecordNo): Boolean;
begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_SET_RECNO_ON_CLIENT}
  aaWriteToLog('> TACRClientRecordCache.SetRecNo, RecNo = ' + IntToStr(RecNo)
    );
{$ENDIF}
  if ((FRecordCount <= 0) or (RecNo > FRecordCount)) then
    Result := true
  else
  begin
    FCurrentRecordPosition := FRecordNumbers.IndexOf(RecNo);
    Result := (FCurrentRecordPosition >= 0);
    if (Result) then
    begin
      Move(FRecords.Items[FCurrentRecordPosition], LCursor.CurrentRecordID,
        SizeOf(FCurrentRecordID));
      Move(PAnsiChar(FBuffer + FCurrentRecordPosition * LCursor.RecordSize)^,
        LCursor.CurrentRecordBuffer^, LCursor.RecordSize);
    end;
  end;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_SET_RECNO_ON_CLIENT}
  aaWriteToLog('< TACRClientRecordCache.SetRecNo, RecNo = ' + IntToStr(RecNo)
      + #13#10 + 'Result = ' + BoolToStr(Result, true));
  WriteAllData;
{$ENDIF}
end; // SetRecNo

//------------------------------------------------------------------------------
// set current record
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.SetCurrentRecord;
begin
  FCurrentRecordPosition := FRecords.FindRecordByID(LCursor.CurrentRecordID);
  if (FCurrentRecordPosition >= 0) and (FCurrentRecordPosition < FNumRecords)
    then
    Move(LCursor.CurrentRecordID, FCurrentRecordID, SizeOf(FCurrentRecordID));
end; // SetCurrentRecord

//------------------------------------------------------------------------------
// internal post - update cache
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.InternalPost(ToInsert,
  SingleRecordInCache: Boolean; RecNo, RecCount: TACRRecordNo;
  const NewState: TACRTableState);
begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_POST_ON_CLIENT}
  aaWriteToLog('> TACRClientRecordCache.InternalPost' + #13#10 +
      'ToInsert = ' + BoolToStr(ToInsert,
      true) + #13#10 + 'SingleRecordInCache = ' + BoolToStr
      (SingleRecordInCache, true) + #13#10 + 'RecNo = ' + IntToStr(RecNo)
      + #13#10 + 'RecCount = ' + IntToStr(RecCount));
  WriteAllData;
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaIncCounter(counter6);
  aaStartTime(time6);
{$ENDIF}
  try
    FRecordCount := RecCount;
    Move(NewState, FState, SizeOf(NewState));
    if (not FLoaded) or SingleRecordInCache or (FNumRecords = 0) then
    begin
      ResetCache(RecNo);
    end
    else
    begin
      if (ToInsert) then
        InsertRecord(RecNo)
      else
        UpdateRecord(RecNo);
    end;
    FLoaded := true;
    FLastLoadedTime := aaGetTickCount;
  except
    on e: Exception do
    begin
      FLoaded := False;
{$IFDEF DEBUG_LOG_CLIENT_CACHE_POST_ON_CLIENT}
      aaWriteToLog('Error in TACRClientRecordCache.InternalPost: ' + #13#10 +
          e.Message);
{$ENDIF}
    end;
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
  aaStopTime(time6);
{$ENDIF}
{$IFDEF DEBUG_LOG_CLIENT_CACHE_POST_ON_CLIENT}
  aaWriteToLog('< TACRClientRecordCache.InternalPost');
  WriteAllData;
{$ENDIF}
end; // InternalPost

//------------------------------------------------------------------------------
// internal delete - update cache
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.InternalDelete(OldRecordID: TACRRecordID;
  SingleRecordInCache: Boolean; RecNo, RecCount: TACRRecordNo;
  const NewState: TACRTableState);
begin
  try
    FRecordCount := RecCount;
    Move(NewState, FState, SizeOf(NewState));
    if (not FLoaded) or SingleRecordInCache or (FNumRecords = 0) then
    begin
      ResetCache(RecNo);
    end
    else
    begin
      DeleteRecord(OldRecordID, RecNo);
    end;
    FLoaded := true;
    FLastLoadedTime := aaGetTickCount;
  except
    FLoaded := False;
  end;
end; // InternalDelete

//------------------------------------------------------------------------------
// calculate num records
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.CalculateNumRecords;
begin
  FAllocatedRecords := GetNumRecords;
end; // CalculateNumRecords

//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRClientRecordCache.IsRecordExists: Boolean;
begin
  Result := (FRecords.FindRecordByID(LCursor.CurrentRecordID) >= 0);
end; // IsRecordExists

//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TACRClientRecordCache.EmptyTable(const NewState: TACRTableState);
begin
  FRecordCount := 0;
  FNumRecords := 0;
  ResizeCache(0);
  Move(NewState, FState, SizeOf(NewState));
  FLoaded := true;
  FLastLoadedTime := aaGetTickCount;
end; // EmptyTable

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientCursor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// send record buffer
//------------------------------------------------------------------------------
procedure TACRClientCursor.SendRecordBuffer(const ErrorCode: Integer;
  RecordBuffer: TACRRecordBuffer);
begin
  // SaveDataToStream(RecordBuffer^,RecordBufferSize,TACRClientSession(FSession).FSentCommandDataStream,ErrorCode);
  // 4.20: skip calculated and lookup as they cannot exist on server side
  SaveDataToStream(RecordBuffer^, RecordSize,
    TACRClientSession(FSession).FSentCommandDataStream, ErrorCode);
end; // SendRecordBuffer

//------------------------------------------------------------------------------
// receive record buffer
//------------------------------------------------------------------------------
procedure TACRClientCursor.ReceiveRecordBuffer(const ErrorCode: Integer;
  RecordBuffer: TACRRecordBuffer);
begin
  // LoadDataFromStream(RecordBuffer^,RecordBufferSize,TACRClientSession(FSession).FReceivedCommandDataStream,ErrorCode);
  // 4.20: skip calculated and lookup as they cannot exist on server side
  LoadDataFromStream(RecordBuffer^, RecordSize,
    TACRClientSession(FSession).FReceivedCommandDataStream, ErrorCode);
end; // ReceiveRecordBuffer

//------------------------------------------------------------------------------
// save get record parameters
//------------------------------------------------------------------------------
procedure TACRClientCursor.SaveGetRecordParams
  (GetRecordMode: TACRGetRecordMode);
var
  bool: ByteBool;
begin
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 10985);
  SaveDataToStream(GetRecordMode, SizeOf(GetRecordMode),
    TACRClientSession(FSession).FSentCommandDataStream, 10986);
  bool := FirstPosition;
  SaveDataToStream(bool, SizeOf(bool),
    TACRClientSession(FSession).FSentCommandDataStream, 10987);
  bool := LastPosition;
  SaveDataToStream(bool, SizeOf(bool),
    TACRClientSession(FSession).FSentCommandDataStream, 10988);
  SaveDataToStream(CurrentRecordID, SizeOf(CurrentRecordID),
    TACRClientSession(FSession).FSentCommandDataStream,
    10989);
  SaveDataToStream(FIndexID, SizeOf(IndexID),
    TACRClientSession(FSession).FSentCommandDataStream, 11089);
end; // SaveGetRecordParams

//------------------------------------------------------------------------------
// load cache
//------------------------------------------------------------------------------
function TACRClientCursor.LoadCache(GetRecordMode: TACRGetRecordMode;
  ResetFilters: Boolean): TACRGetRecordResult;
var
  bool: ByteBool;
begin
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqLoadRecords;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveGetRecordParams(GetRecordMode);
  FCache.CalculateNumRecords;
  SaveDataToStream(FCache.AllocatedRecords, SizeOf(FCache.AllocatedRecords),
    TACRClientSession(FSession).FSentCommandDataStream, 12336);
  bool := ResetFilters;
  SaveDataToStream(bool, SizeOf(bool),
    TACRClientSession(FSession).FSentCommandDataStream, 12358);
  if (not TACRClientSession(FSession).ExecuteCommand) then
   begin
    Result := grrError;
    Exit;
   end;
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
  LoadDataFromStream(Result, SizeOf(Result),
    TACRClientSession(FSession).FReceivedCommandDataStream, 10990);
  if (Result = grrOK) then
    FCache.SetCurrentRecord;
  LoadDataFromStream(bool, SizeOf(bool),
    TACRClientSession(FSession).FReceivedCommandDataStream, 11131);
  FirstPosition := bool;
  LoadDataFromStream(bool, SizeOf(bool),
    TACRClientSession(FSession).FReceivedCommandDataStream, 11132);
  LastPosition := bool;
  LoadDataFromStream(CurrentRecordID, SizeOf(CurrentRecordID),
    TACRClientSession(FSession).FReceivedCommandDataStream, 11133);
  if (Result <> grrError) then
  begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
    aaWriteToLog('TACRClientCursor.LoadCache - loading cache... ');
{$ENDIF}
    FCache.LoadFromStream(TACRClientSession(FSession)
        .FReceivedCommandDataStream);
  end;
end; // LoadCache


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TACRClientCursor.SetCaseInsensitive(Value: Boolean);
begin
 { TODO : implement in CS mode }
 inherited SetCaseInsensitive(Value);
end; // SetCaseInsensitive


//------------------------------------------------------------------------------
// if cache is not loaded - load it
//------------------------------------------------------------------------------
function TACRClientCursor.CheckToLoadCache(GetRecordMode: TACRGetRecordMode) : TACRGetRecordResult;
begin
  Result := grrOK;
  if (not FCache.Loaded) then
  begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
    aaWriteToLog('TACRClientCursor.CheckToLoadCache - loading cache... ');
{$ENDIF}
    Result := LoadCache(GetRecordMode);
  end;
end; // CheckToLoadCache

//------------------------------------------------------------------------------
// Receive cursor information from server
//------------------------------------------------------------------------------
procedure TACRClientCursor.ReceiveServerCursor;
var
  b: Byte;
  CursorIndexID: TACRObjectID;
  MinRecords, MaxRecords: Integer;
begin
  FCursorID := INVALID_OBJECT_ID;
  FirstPosition := true;
  LastPosition := False;
  // loading ñursorID, field defs, visible field defs, index defs, constraint defs
  LoadDataFromStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FReceivedCommandDataStream, 10963);
  LoadWideStringFromStream(FComment,
    TACRClientSession(FSession).FReceivedCommandDataStream, 10961);
  if (FFieldDefs <> nil) then
    FFieldDefs.Free;
  FFieldDefs := TACRFieldDefs.Create;
  if (FVisibleFieldDefs <> nil) then
    FVisibleFieldDefs.Free;
  FVisibleFieldDefs := TACRFieldDefs.Create;
  if (FIndexDefs <> nil) then
    FIndexDefs.Free;
  FIndexDefs := TACRIndexDefs.Create;
  if (FConstraintDefs <> nil) then
    FConstraintDefs.Free;
  FConstraintDefs := TACRConstraintDefs.Create;
  FFieldDefs.LoadFromStream(TACRClientSession(FSession)
      .FReceivedCommandDataStream);
  FVisibleFieldDefs.LoadFromStream(TACRClientSession(FSession)
      .FReceivedCommandDataStream);
  FIndexDefs.LoadFromStream(TACRClientSession(FSession)
      .FReceivedCommandDataStream);
  FConstraintDefs.LoadFromStream(TACRClientSession(FSession)
      .FReceivedCommandDataStream);
  // is cursor query or table
  LoadDataFromStream(b, SizeOf(b),
    TACRClientSession(FSession).FReceivedCommandDataStream, 11594);
  if (b = 1) then
  begin
    // query cursor can have active index for ORDER BY clause
    LoadDataFromStream(CursorIndexID, SizeOf(CursorIndexID),
      TACRClientSession(FSession)
        .FReceivedCommandDataStream, 11595);
    // FIndexID := CursorIndexID;
    try
      // if (FIndexID <> INVALID_OBJECT_ID) then
      // FIndexName := FIndexDefs.GetDefByObjectId(FIndexID).Name
    except
      // no such index
      FIndexID := INVALID_OBJECT_ID;
    end;
  end;
  // create blob lists
  if (FBLOBStreams <> nil) then
    FBLOBStreams.Free;
  FBLOBStreams := TList.Create;
  if (FBLOBCache <> nil) then
    FBLOBCache.Free;
  FBLOBCache := TList.Create;
  // added in v.4.90 - needs to calculate offsets from received table definitions
  InternalInitFieldDefs;
  MinRecords := ACRGetRecordCountByBufferSize
    (TACRClientSession(FSession).MinCacheSize, FRecordSize);
  if (MinRecords <= 0) then
    MinRecords := 1;
  MaxRecords := ACRGetRecordCountByBufferSize
    (TACRClientSession(FSession).MaxCacheSize, FRecordSize);
  if (MaxRecords <= 0) then
    MaxRecords := 1;
  FCache := TACRClientRecordCache.Create(MinRecords, MaxRecords, Self);
  FIsOpen := true;
end; // ReceiveServerCursor

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientCursor.Create;
begin
  CurrentRecordBuffer := nil;
  FTempRecordBuffer := nil;
  FIsProjectionSet := False;
  FRandomOrder := False;
  FFieldDefs := nil;
  FVisibleFieldDefs := nil;
  FIndexDefs := nil;
  IsOpen := False;
  FBLOBStreams := nil;
  FBLOBCache := nil;
  FIndexName := '';
  FIndexID := INVALID_OBJECT_ID;
  FilterExpression := nil;
  SQLFilterExpression := nil;
  FilterRecord := nil;
  FSettingProjection := False;
  RecordBitmap := nil;
  FCursorID := INVALID_OBJECT_ID;
  FCreateTableStarted := False;
  FErrorMessage := '';
  FSkipTableExistsCheck := False;
  FDirectSetAutoInc := False;
  FInMemory := False;
  FTemporary := False;
  FCache := nil;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRClientCursor.Destroy;
begin
  try
    CloseTable;
  except
  end;
  if (FCache <> nil) then
  begin
    try
      FreeAndNil(FCache);
    except
    end;
  end;
  if (FTempRecordBuffer <> nil) then
  begin
    try
      FreeRecordBuffer(FTempRecordBuffer);
      FTempRecordBuffer := nil;
    except
    end;
  end;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TACRClientCursor.CreateTable(FieldDefs: TACRFieldDefs;
  IndexDefs: TACRIndexDefs; ConstraintDefs: TACRConstraintDefs);
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqCreateTable;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10929);
  FieldDefs.SaveToStream(TACRClientSession(FSession).FSentCommandDataStream);
  IndexDefs.SaveToStream(TACRClientSession(FSession).FSentCommandDataStream);
  ConstraintDefs.SaveToStream(TACRClientSession(FSession)
      .FSentCommandDataStream);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11515, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11516, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
end; // CreateTable

//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TACRClientCursor.DeleteTable(Cascade: Boolean);
var
  b: ByteBool;
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqDeleteTable;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10931);
  b := Cascade;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11479);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11517, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11518, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
end; // DeleteTable;

//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TACRClientCursor.EmptyTable;
var
  state: TACRTableState;
begin
  // this method works on temporary cuirsor that is not opened
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqEmptyTable;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10933);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11519, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11520, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
end; // EmptyTable

//------------------------------------------------------------------------------
// add foreign key
//------------------------------------------------------------------------------
procedure TACRClientCursor.AddForeignKey
  (ConstraintDef: TACRConstraintDefForeignKey);
begin
  raise EACRException.Create(11585, ErrorLOperationIsNotSupported);
end; // AddForeignKey

//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TACRClientCursor.DeleteConstraint(Name: WideString;
  Cascade: Boolean; FKPartialDelete: Boolean);
begin
  raise EACRException.Create(11485, ErrorLOperationIsNotSupported);
end; // DeleteConstraint

//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TACRClientCursor.RenameTable(NewTableName: WideString);
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqRenameTable;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10935);
  SaveWideStringToStream(NewTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10937);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11520, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11521, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
  FTableName := NewTableName;
end; // RenameTable

//------------------------------------------------------------------------------
// Rename Field
//------------------------------------------------------------------------------
procedure TACRClientCursor.RenameField(FieldName, NewFieldName: WideString);
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqRenameField;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10939);
  SaveWideStringToStream(FieldName,
    TACRClientSession(FSession).FSentCommandDataStream, 10941);
  SaveWideStringToStream(NewFieldName,
    TACRClientSession(FSession).FSentCommandDataStream, 10943);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11522, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11523, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
end; // RenameField

//------------------------------------------------------------------------------
// repair table
//------------------------------------------------------------------------------
function TACRClientCursor.RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TACRConstraintDefs = nil
                                    ): Boolean;
begin
  raise EACRException.Create(11510, ErrorLOperationIsNotSupported);
  { TODO : implement it }
end; // RepairTable

//------------------------------------------------------------------------------
// load table
//------------------------------------------------------------------------------
procedure TACRClientCursor.LoadTableFromStream(Stream: TStream);
begin
  raise EACRException.Create(10925, ErrorLCannotLoadRemoteTable);
end; // LoadTableToStream

//------------------------------------------------------------------------------
// save table
//------------------------------------------------------------------------------
procedure TACRClientCursor.SaveTableToStream(Stream: TStream;
  CompressionAlgorithm: TACRCompressionAlgorithm; CompressionMode: Byte;
  BlockSize: Integer; SkipCheckIsTableOpened: Boolean;
  DoNotCloseTable: Boolean);
begin
  raise EACRException.Create(10926, ErrorLCannotSaveRemoteTable);
end; // SaveTableToStream

//------------------------------------------------------------------------------
// export table to SQL
//------------------------------------------------------------------------------
function TACRClientCursor.ExportTableToSQL(ExportStructure: Boolean;
  AddDropTableCommand: Boolean; ExportIndexes: Boolean;
  AddDropIndexCommand: Boolean; ExportData: Boolean;
  ExportBLOBFields: Boolean; UseBracketsForNames: Boolean;
  ExportForeignKeys: Boolean): WideString;
begin
  Result := '';
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqExportTableToSQL;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11733);
  SaveBooleanToStream(ExportStructure,
    TACRClientSession(FSession).FSentCommandDataStream, 11725);
  SaveBooleanToStream(AddDropTableCommand,
    TACRClientSession(FSession).FSentCommandDataStream, 11726);
  SaveBooleanToStream(ExportIndexes,
    TACRClientSession(FSession).FSentCommandDataStream, 11727);
  SaveBooleanToStream(AddDropIndexCommand,
    TACRClientSession(FSession).FSentCommandDataStream, 11728);
  SaveBooleanToStream(ExportData,
    TACRClientSession(FSession).FSentCommandDataStream, 11729);
  SaveBooleanToStream(ExportBLOBFields,
    TACRClientSession(FSession).FSentCommandDataStream, 11730);
  SaveBooleanToStream(UseBracketsForNames,
    TACRClientSession(FSession).FSentCommandDataStream, 11731);
  SaveBooleanToStream(ExportForeignKeys,
    TACRClientSession(FSession).FSentCommandDataStream, 12132);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11520, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11521, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
  LoadWideStringFromStream(Result,
    TACRClientSession(FSession).FReceivedCommandDataStream, 11732);
end; // ExportTableToSQL

//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalInitFieldDefs;
begin
  FFieldDefs.RecalcFieldOffsets;
  FieldValuesOffset := FFieldDefs[0].MemoryOffset;
  BookmarkOffset := FFieldDefs[FFieldDefs.Count - 1].MemoryOffset + FFieldDefs
    [FFieldDefs.Count - 1].MemoryDataSize;
  KeyOffset := BookmarkOffset;
  KeyBufferSize := BookmarkOffset + SizeOf(TACRKeyBuffer);
  RecordSize := BookmarkOffset + SizeOf(TACRBookmarkInfo);
  RecordBufferSize := RecordSize;
  CalculatedFieldsOffset := RecordSize;
end; // InternalInitFieldDefs

//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TACRClientCursor.OpenTableByFieldDefs(FieldDefs: TACRFieldDefs;
  IndexDefs: TACRIndexDefs; ConstraintDefs: TACRConstraintDefs);
var
  Len, i: Integer;
  b: ByteBool;
begin
  FIsOpen := False;
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqOpenTable;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10960);
  b := FExclusive;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 10962);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11524, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11525, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
  ReceiveServerCursor;
  for i := 0 to VisibleFieldDefs.Count - 1 do
    FVisibleFieldDefs[i].FieldNoReference := i;
  FIsOpen := true;
  TACRClientSession(FSession).FReceivedCommandDataStream.Size := 0;
end; // OpenTable

//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TACRClientCursor.CloseTable;
begin
  if (FIsOpen) then
  begin
    if (FFieldDefs <> nil) then
      FFieldDefs.Free;
    FFieldDefs := nil;
    if (FVisibleFieldDefs <> nil) then
      FVisibleFieldDefs.Free;
    FVisibleFieldDefs := nil;
    if (FIndexDefs <> nil) then
      FIndexDefs.Free;
    FIndexDefs := nil;
    if (FConstraintDefs <> nil) then
      FConstraintDefs.Free;
    FConstraintDefs := nil;
    ClearBLOBStreams(False);
    if (FBLOBStreams <> nil) then
      FBLOBStreams.Free;
    FBLOBStreams := nil;
    if (FBLOBCache <> nil) then
      FBLOBCache.Free;
    FBLOBCache := nil;
    FIsOpen := False;
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqCloseTable;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID, SizeOf(FCursorID),
      TACRClientSession(FSession).FSentCommandDataStream, 10964);
    FCursorID := INVALID_OBJECT_ID;
    try
      if (FCache <> nil) then
        FreeAndNil(FCache);
    except
    end;
    // send command
    if (TACRClientSession(FSession).SendCommand) then
      { TODO -oLeo : no need to check the reply }
      // receive and check the reply
      if (TACRClientSession(FSession).ReceiveCommand) then
        TACRClientSession(FSession).CheckReceivedReply
          (accrplOperationSucceed);
  end;
end; // CloseTable

//------------------------------------------------------------------------------
// create new index
//------------------------------------------------------------------------------
procedure TACRClientCursor.AddIndex(IndexDef: TACRIndexDef);
begin
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqAddIndex;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;

  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10973);
  IndexDef.SaveToStream(TACRClientSession(FSession).FSentCommandDataStream);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11528, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11529, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
  FIndexDefs.AddCreated.Assign(IndexDef);
  UpdateIndexDefinitions;
end; // AddIndex

//------------------------------------------------------------------------------
// delete index
//------------------------------------------------------------------------------
procedure TACRClientCursor.DeleteIndex(Name: WideString);
begin
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqDeleteIndex;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10978);
  SaveWideStringToStream(Name,
    TACRClientSession(FSession).FSentCommandDataStream, 10976);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11530, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11531, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
  FIndexDefs.Delete(FIndexDefs.GetDefNumberByName(Name));
  UpdateIndexDefinitions;
end; // DeleteIndex

//------------------------------------------------------------------------------
// delete all indexes
//------------------------------------------------------------------------------
procedure TACRClientCursor.DeleteAllIndexes;
begin
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqDeleteAllIndexes;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveWideStringToStream(FTableName,
    TACRClientSession(FSession).FSentCommandDataStream, 10980);
  // send command
  if (not TACRClientSession(FSession).SendCommand) then
    raise EACRException.Create(11532, ErrorLCannotSendCommandToServer);
  // receive and check the reply
  if (not TACRClientSession(FSession).ReceiveCommand) then
    raise EACRException.Create(11533, ErrorLCannotReceiveCommandFromServer);
  TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
end; // DeleteAllIndexes

//------------------------------------------------------------------------------
// return index name of the index or '' if not found
//------------------------------------------------------------------------------
function TACRClientCursor.FindIndex(FieldNamesList, AscDescList,
  CaseSensitivityList: TACRWideStringList): WideString;
begin
  raise EACRException.Create(11383, ErrorLOperationIsNotSupported);
end; // FindIndex

//------------------------------------------------------------------------------
// return true if temporary table
//------------------------------------------------------------------------------
function TACRClientCursor.IsTemporaryTable: Boolean;
begin
  Result := False;
end; // IsTemporaryTable

//------------------------------------------------------------------------------
// return true if memory table
//------------------------------------------------------------------------------
function TACRClientCursor.IsMemoryTable: Boolean;
begin
  Result := False;
end; // IsMemoryTable

//------------------------------------------------------------------------------
// return record count
//------------------------------------------------------------------------------
function TACRClientCursor.GetRecordCount: TACRRecordNo;
begin
  Result := -1;
  if (not FIsOpen) then
    Exit;
  Result := FCache.GetRecordCount;
  {
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqGetRecordCount;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID,SizeOf(FCursorID),TACRClientSession(FSession).FSentCommandDataStream,10983);
    // send command
    if (TACRClientSession(FSession).SendCommand) then
    // receive and check the reply
    if (TACRClientSession(FSession).ReceiveCommand) then
    begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
    LoadDataFromStream(Result,SizeOf(Result),TACRClientSession(FSession).FReceivedCommandDataStream,10984);
    end;
  }
end; // GetRecordCount

//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
function TACRClientCursor.GetRecordBuffer(GetRecordMode: TACRGetRecordMode): TACRGetRecordResult;
begin
  Result := grrError;
  if (not FIsOpen) then
    Exit;
  Result := FCache.GetRecordBuffer(GetRecordMode);
  if (Result = grrReloadCache) then
  begin
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
    aaWriteToLog('TACRClientCursor.GetRecordBuffer - reloading cache... ');
{$ENDIF}
    Result := LoadCache(GetRecordMode);
    if (Result = grrOK) then
      Result := FCache.GetRecordBuffer(grmCurrent);
  end;
  if (Result = grrOK) then
   GetCalcFieldsAndBookMarkData;
  {
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqGetRecordBuffer;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    // send command
    if (TACRClientSession(FSession).SendCommand) then
    // receive and check the reply
    if (TACRClientSession(FSession).ReceiveCommand) then
    begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
    LoadDataFromStream(Result,SizeOf(Result),TACRClientSession(FSession).FReceivedCommandDataStream,10990);
    LoadDataFromStream(bool,SizeOf(bool),TACRClientSession(FSession).FReceivedCommandDataStream,11131);
    FirstPosition := bool;
    LoadDataFromStream(bool,SizeOf(bool),TACRClientSession(FSession).FReceivedCommandDataStream,11132);
    LastPosition := bool;
    LoadDataFromStream(CurrentRecordID,SizeOf(CurrentRecordID),TACRClientSession(FSession).FReceivedCommandDataStream,11133);
    if (Result = grrOK) then
    ReceiveRecordBuffer(10991,CurrentRecordBuffer);
    end;
  }
end; // GetRecordBuffer

//------------------------------------------------------------------------------
// go to record
//------------------------------------------------------------------------------
procedure TACRClientCursor.SetRecNo(Value: Int64);
var
  bOK: Boolean;
begin
  bOK := FCache.SetRecNo(Value);
  if (not bOK) then
  begin
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqSetRecNo;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID, SizeOf(FCursorID),
      TACRClientSession(FSession).FSentCommandDataStream, 11017);
    SaveDataToStream(Value, SizeOf(Value),
      TACRClientSession(FSession).FSentCommandDataStream, 11012);
    SaveDataToStream(FIndexID, SizeOf(IndexID),
      TACRClientSession(FSession).FSentCommandDataStream, 11093);
    if (TACRClientSession(FSession).ExecuteCommand) then
      begin
        TACRClientSession(FSession).CheckReceivedReply
          (accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
        aaWriteToLog('TACRClientCursor.SetRecNo - loading cache... ');
{$ENDIF}
        FCache.LoadFromStream(TACRClientSession(FSession)
            .FReceivedCommandDataStream);
        FCache.SetRecNo(Value);
      end;
  end;
  {
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqSetRecNo;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID,SizeOf(FCursorID),TACRClientSession(FSession).FSentCommandDataStream,11017);
    SaveDataToStream(Value,SizeOf(Value),TACRClientSession(FSession).FSentCommandDataStream,11012);
    SaveDataToStream(FIndexID,SizeOf(IndexID),TACRClientSession(FSession).FSentCommandDataStream,11093);
    // send command
    if (TACRClientSession(FSession).SendCommand) then
    // receive and check the reply
    if (TACRClientSession(FSession).ReceiveCommand) then
    begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
    FirstPosition := False;
    LastPosition := False;
    LoadDataFromStream(CurrentRecordID,SizeOf(CurrentRecordID),TACRClientSession(FSession).FReceivedCommandDataStream,11013);
    end;
  }
end; // SetRecNo

//------------------------------------------------------------------------------
// return current record number
//------------------------------------------------------------------------------
function TACRClientCursor.GetRecNo: Int64;
begin
  Result := -1;
  if (not FIsOpen) then
    Exit;
  Result := FCache.GetRecNo;
  {
    if ((not FirstPosition) and (not LastPosition)) then
    begin
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqGetRecNo;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID,SizeOf(FCursorID),TACRClientSession(FSession).FSentCommandDataStream,11018);
    SaveDataToStream(CurrentRecordID,SizeOf(CurrentRecordID),TACRClientSession(FSession).FSentCommandDataStream,11014);
    SaveDataToStream(FIndexID,SizeOf(IndexID),TACRClientSession(FSession).FSentCommandDataStream,11094);
    // send command
    if (TACRClientSession(FSession).SendCommand) then
    // receive and check the reply
    if (TACRClientSession(FSession).ReceiveCommand) then
    begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
    LoadDataFromStream(Result,SizeOf(Result),TACRClientSession(FSession).FReceivedCommandDataStream,11015);
    end;
    end;
  }
end; // GetRecNo

//------------------------------------------------------------------------------
// refresh - added in v.5.30
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalRefresh;
begin
  LoadCache(grmCurrent, true);
end; // InternalRefresh

//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalEdit;
begin
{$IFDEF DEBUG_LOG_CLIENT_INTERNAL_EDIT}
  aaWriteToLog('> TACRClientCursor.InternalEdit');
{$ENDIF}
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqInternalEdit;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11024);
  SaveDataToStream(CurrentRecordID, SizeOf(CurrentRecordID),
    TACRClientSession(FSession).FSentCommandDataStream,
    11025);
  if (TACRClientSession(FSession).ExecuteCommand) then
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_INTERNAL_EDIT}
  aaWriteToLog('< TACRClientCursor.InternalEdit');
{$ENDIF}
end; // InternalEdit

//------------------------------------------------------------------------------
// cancels updates
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalCancel(ToInsert: Boolean);
var
  b: ByteBool;
begin
{$IFDEF DEBUG_LOG_CLIENT_INTERNAL_CANCEL}
  aaWriteToLog('> TACRClientCursor.InternalCancel');
{$ENDIF}
  ClearBLOBStreams(true);
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqInternalCancel;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11026);
  b := ToInsert;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11049);
  SaveDataToStream(CurrentRecordID, SizeOf(CurrentRecordID),
    TACRClientSession(FSession).FSentCommandDataStream,
    11027);
{$IFDEF DEBUG_LOG_CLIENT_INTERNAL_CANCEL}
  aaWriteToLog('1. TACRClientCursor.InternalCancel');
{$ENDIF}
  if (TACRClientSession(FSession).ExecuteCommand) then
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_INTERNAL_CANCEL}
  aaWriteToLog('< TACRClientCursor.InternalCancel');
{$ENDIF}
end; // InternalCancel

//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalPost(ToInsert: Boolean);
var
  b: ByteBool;
  Bookmark: PACRBookmarkInfo;
  RecNo, RecCount: TACRRecordNo;
  state: TACRTableState;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaIncCounter(counter4);
aaStartTime(time4);
aaStartTime(time5);
try
{$ENDIF}
  if (CurrentRecordBuffer = nil) then
    raise EACRException.Create(11028, ErrorLNilPointer);
  if (not ToInsert) then
    Move(PAnsiChar(FCurrentRecordBuffer + BookmarkOffset)^, CurrentRecordID,
      SizeOf(TACRRecordID));
  ClearBLOBStreams(true);
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqInternalPost;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11026);
  b := ToInsert;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11029);
  SaveDataToStream(CurrentRecordID, SizeOf(CurrentRecordID),
    TACRClientSession(FSession).FSentCommandDataStream,
    11030);
  SaveDataToStream(FIndexID, SizeOf(IndexID),
    TACRClientSession(FSession).FSentCommandDataStream, 11095);
  SendRecordBuffer(11031, CurrentRecordBuffer);
  b := (EditRecordBuffer = nil);
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11032);
  if (not b) then
    SendRecordBuffer(11033, EditRecordBuffer);
  SendModifiedBLOBValues;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time5);
aaStartTime(time6);
{$ENDIF}
  b := TACRClientSession(FSession).ExecuteCommand;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time6);
{$ENDIF}
  // send command
  if (b) then
   begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaIncCounter(counter7);
aaStartTime(time7);
{$ENDIF}
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
    LoadDataFromStream(b, SizeOf(b),
      TACRClientSession(FSession).FReceivedCommandDataStream, 11034);
    FirstPosition := b;
    LoadDataFromStream(b, SizeOf(b),
      TACRClientSession(FSession).FReceivedCommandDataStream, 11035);
    LastPosition := b;
    LoadDataFromStream(CurrentRecordID, SizeOf(CurrentRecordID),
      TACRClientSession(FSession).FReceivedCommandDataStream, 11036);
    LoadDataFromStream(b, SizeOf(b),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12340);
    LoadDataFromStream(state, SizeOf(state),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12349);
    LoadDataFromStream(RecNo, SizeOf(RecNo),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12334);
    LoadDataFromStream(RecCount, SizeOf(RecCount),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12335);
    ReceiveRecordBuffer(11037, CurrentRecordBuffer);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStartTime(time9);
{$ENDIF}
    FCache.InternalPost(ToInsert, b, RecNo, RecCount, state);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time9);
{$ENDIF}
    if (ToInsert) then
    begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaIncCounter(counter8);
aaStartTime(time8);
{$ENDIF}
      GetCalcFieldsAndBookMarkData(true);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time8);
{$ENDIF}
    end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
aaStopTime(time7);
{$ENDIF}
   end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_CLIENT}
finally
aaStopTime(time4);
aaStopTime(time7);
end;
{$ENDIF}
end; // InternalPost


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalDelete;
var
  b: ByteBool;
  OldRecordID: TACRRecordID;
  RecNo: TACRRecordNo;
  RecordCount: TACRRecordNo;
  state: TACRTableState;
begin
  FErrorMessage := '';
  Move(PAnsiChar(FCurrentRecordBuffer + BookmarkOffset)^, CurrentRecordID,
    SizeOf(TACRRecordID));
  Move(CurrentRecordID, OldRecordID, SizeOf(TACRRecordID));
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqInternalDelete;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11038);
  SaveDataToStream(CurrentRecordID, SizeOf(CurrentRecordID),
    TACRClientSession(FSession).FSentCommandDataStream,
    11039);
  SaveDataToStream(FIndexID, SizeOf(IndexID),
    TACRClientSession(FSession).FSentCommandDataStream, 11096);
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    FErrorCode := ACR_ERR_OK;
    try
      TACRClientSession(FSession).CheckReceivedReply
        (accrplOperationSucceed);
    except
      on e: Exception do
      begin
        FErrorCode := ACR_ERR_DELETE_RECORD;
        FErrorMessage := e.Message;
        Exit;
      end;
    end;
    LoadDataFromStream(b, SizeOf(b),
      TACRClientSession(FSession).FReceivedCommandDataStream, 11040);
    FirstPosition := b;
    LoadDataFromStream(b, SizeOf(b),
      TACRClientSession(FSession).FReceivedCommandDataStream, 11041);
    LastPosition := b;
    LoadDataFromStream(CurrentRecordID, SizeOf(CurrentRecordID),
      TACRClientSession(FSession).FReceivedCommandDataStream, 11042);
    // Move(CurrentRecordID,FDeleteCurrentRecordID,SizeOf(TACRRecordID));
    LoadDataFromStream(b, SizeOf(b),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12343);
    LoadDataFromStream(state, SizeOf(state),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12351);
    LoadDataFromStream(RecNo, SizeOf(RecNo),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12344);
    LoadDataFromStream(RecordCount, SizeOf(RecordCount),
      TACRClientSession(FSession).FReceivedCommandDataStream, 12344);
    if ((RecNo >= 0) and (RecordCount >= 0)) then
      ReceiveRecordBuffer(11043, CurrentRecordBuffer);
    FCache.InternalDelete(OldRecordID, b, RecNo, RecordCount, state);
    // if (RecordCount > 0) then
    // GetRecordBuffer(grmCurrent);
   end;
end; // InternalDelete

//------------------------------------------------------------------------------
// delete all visible records
//------------------------------------------------------------------------------
procedure TACRClientCursor.DeleteVisibleRecords;
begin
  raise EACRException.Create(11303, ErrorLOperationIsNotSupported);
end; // DeleteVisibleRecords

//------------------------------------------------------------------------------
// update visible records
//------------------------------------------------------------------------------
procedure TACRClientCursor.UpdateVisibleRecords
  (FieldNames: TACRWideStringList;
  values: array of TACRVariant; SkipFKCheck: Boolean = False);
begin
  raise EACRException.Create(11459, ErrorLOperationIsNotSupported);
end; // UpdateVisibleRecords

//------------------------------------------------------------------------------
// disable record bitmap
//------------------------------------------------------------------------------
procedure TACRClientCursor.DisableRecordBitmap;
begin
  // do nothing
end; // DisableRecordBitmap

//------------------------------------------------------------------------------
// apply projection
//------------------------------------------------------------------------------
procedure TACRClientCursor.ApplyProjection(FieldNamesList,
  AliasList: TACRWideStringList);
begin
  raise EACRException.Create(11069, ErrorLOperationIsNotSupported);
end; // ApplyProjection

//------------------------------------------------------------------------------
// Activate filters
//------------------------------------------------------------------------------
procedure TACRClientCursor.ActivateFilters(FilterText: WideString;
  CaseInsensitive: Boolean; PartialKey: Boolean);
var
  b: ByteBool;
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqActivateFilters;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11075);
  SaveWideStringToStream(FilterText,
    TACRClientSession(FSession).FSentCommandDataStream, 11071);
  b := CaseInsensitive;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11073);
  b := PartialKey;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11074);
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
aaWriteToLog('TACRClientCursor.ActivateFilters - loading cache... ');
{$ENDIF}
    FCache.LoadFromStream(TACRClientSession(FSession)
        .FReceivedCommandDataStream);
   end;
end; // ActivateFilters

//------------------------------------------------------------------------------
// Deactivate filters
//------------------------------------------------------------------------------
procedure TACRClientCursor.DeactivateFilters;
begin
  if (FSQLFilterExpression <> nil) then
    Exit;
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqDeactivateFilters;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11076);
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
aaWriteToLog('TACRClientCursor.DeactivateFilters - loading cache... ');
{$ENDIF}
    FCache.LoadFromStream(TACRClientSession(FSession)
        .FReceivedCommandDataStream);
   end;
end; // DeactivateFilters

//------------------------------------------------------------------------------
// Locate
//------------------------------------------------------------------------------
function TACRClientCursor.Locate(const KeyFields: WideString;
  const KeyValues: Variant; CaseInsensitive: Boolean;
  PartialKey: Boolean): Boolean;
var
  i, ArrLen: Integer;
  v: TACRVariant;
  b: ByteBool;
  s: WideString;
begin
  s := KeyFields;
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqLocate;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11081);
  SaveDataToStream(FIndexID, SizeOf(IndexID),
    TACRClientSession(FSession).FSentCommandDataStream, 11099);
  SaveWideStringToStream(s,
    TACRClientSession(FSession).FSentCommandDataStream,
    11082);
  b := CaseInsensitive;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11084);
  b := PartialKey;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11085);
  // Determinate KeyValues count (can be array)
  if (VarType(KeyValues) and varArray) <> 0 then
    ArrLen := VarArrayHighBound(KeyValues, 1) - VarArrayLowBound(KeyValues,
      1) + 1
  else
    ArrLen := 1;
  SaveDataToStream(ArrLen, SizeOf(ArrLen),
    TACRClientSession(FSession).FSentCommandDataStream, 11086);
  v := TACRVariant.Create;
  try
    if (ArrLen = 1) then
    begin
      v.AsVariant := KeyValues;
      v.SaveToStream(TACRClientSession(FSession).FSentCommandDataStream);
    end
    else
    begin
      for i := 0 to ArrLen - 1 do
      begin
        v.AsVariant := VarArrayGet(KeyValues, i);
        v.SaveToStream(TACRClientSession(FSession).FSentCommandDataStream);
      end;
    end;
  finally
    v.Free;
  end;
  Result := False;
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    Result := (TACRClientSession(FSession).ReceivedCommandHeader.Reply =
        accrplYes);
    if (Result) then
    begin
      LoadDataFromStream(CurrentRecordID, SizeOf(CurrentRecordID),
        TACRClientSession(FSession).FReceivedCommandDataStream, 11122);
      ReceiveRecordBuffer(11123, FCurrentRecordBuffer);
      FirstPosition := False;
      LastPosition := False;
    end;
   end;
end; // Locate

//------------------------------------------------------------------------------
// FindKey
//------------------------------------------------------------------------------
function TACRClientCursor.FindKey(SearchCondition: TACRSearchCondition)
  : Boolean;
var
  sc: Byte;
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqFindKey;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11087);
  SaveDataToStream(FIndexID, SizeOf(IndexID),
    TACRClientSession(FSession).FSentCommandDataStream, 11100);
  sc := Byte(SearchCondition);
  SaveDataToStream(sc, SizeOf(sc),
    TACRClientSession(FSession).FSentCommandDataStream, 11088);
  SaveDataToStream(FKeyFieldCount, SizeOf(FKeyFieldCount),
    TACRClientSession(FSession).FSentCommandDataStream, 11101);
  SendRecordBuffer(11102, FKeyBuffer);
  Result := False;
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    Result := (TACRClientSession(FSession).ReceivedCommandHeader.Reply =
        accrplYes);
    if (Result) then
    begin
      LoadDataFromStream(CurrentRecordID, SizeOf(CurrentRecordID),
        TACRClientSession(FSession).FReceivedCommandDataStream, 11129);
      FirstPosition := False;
      LastPosition := False;
    end;
   end;
end; // FindKey

//------------------------------------------------------------------------------
// reset range
//------------------------------------------------------------------------------
procedure TACRClientCursor.ResetRange;
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqResetRange;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11103);
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
aaWriteToLog('TACRClientCursor.ResetRange - loading cache... ');
{$ENDIF}
    FCache.LoadFromStream(TACRClientSession(FSession)
        .FReceivedCommandDataStream);
   end;
end; // ResetRange

//------------------------------------------------------------------------------
// apply range
//------------------------------------------------------------------------------
procedure TACRClientCursor.ApplyRange(StartBuffer,
  EndBuffer: TACRRecordBuffer; StartKeyFieldCount: Integer;
  EndKeyFieldCount: Integer; StartExclusive: Boolean; EndExclusive: Boolean);
var
  b: ByteBool;
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request := accrqApplyRange;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11104);
  SaveDataToStream(FIndexID, SizeOf(IndexID),
    TACRClientSession(FSession).FSentCommandDataStream, 11105);
  b := StartExclusive;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11106);
  b := EndExclusive;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11107);
  SaveDataToStream(StartKeyFieldCount, SizeOf(StartKeyFieldCount),
    TACRClientSession(FSession).FSentCommandDataStream, 11108);
  SaveDataToStream(EndKeyFieldCount, SizeOf(EndKeyFieldCount),
    TACRClientSession(FSession).FSentCommandDataStream, 11109);
  b := (StartBuffer = nil);
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11112);
  if (not b) then
    SendRecordBuffer(11110, StartBuffer);
  b := (EndBuffer = nil);
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11113);
  if (not b) then
    SendRecordBuffer(11111, EndBuffer);
  if (TACRClientSession(FSession).ExecuteCommand) then
   begin
    TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_CACHE_LOAD_ON_CLIENT}
aaWriteToLog('TACRClientCursor.ApplyRange - loading cache... ');
{$ENDIF}
    FCache.LoadFromStream(TACRClientSession(FSession)
        .FReceivedCommandDataStream);
   end;
end; // ApplyRange

//------------------------------------------------------------------------------
// set SQL Filter
//------------------------------------------------------------------------------
procedure TACRClientCursor.SetSQLFilter(FilterExpr: TObject);
begin
  raise EACRException.Create(11070, ErrorLOperationIsNotSupported);
end; // SetSQLFilter

//------------------------------------------------------------------------------
// create blob stream
//------------------------------------------------------------------------------
function TACRClientCursor.InternalCreateBlobStream(ToInsert: Boolean;
  FieldNo: Integer; OpenMode: TACRBLOBOpenMode): TACRStream;
var
  FieldNumber: Integer;
  i: Integer;
  LocalBLOBStream: TACRLocalBLOBStream;
  TempStream: TACRTemporaryStream;
  Size: Int64;
begin
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
  aaWriteToLog('Client: create client blob stream 0, FieldNo = ' + IntToStr
      (FieldNo) + ', openmode = ' + IntToStr(Integer(OpenMode)));
{$ENDIF}
  Size := 0;
  if (FieldNo >= FVisibleFieldDefs.Count) then
    raise EACRException.Create(11208, ErrorLInvalidFieldNumber, [FieldNo,
      FVisibleFieldDefs.Count]);
  if (FBLOBStreams = nil) then
    raise EACRException.Create(11209, ErrorLNilPointer);
  FieldNumber := FVisibleFieldDefs.Items[FieldNo].FieldNoReference;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
  aaWriteToLog('Client: create client blob stream 01, FieldNumber = ' +
      IntToStr(FieldNumber));
{$ENDIF}
  // find existing blob stream
  if ((OpenMode = bomReadWrite) or (OpenMode = bomWrite)) then
  begin
    for i := 0 to FBLOBStreams.Count - 1 do
    begin
      LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
      if (LocalBLOBStream = nil) then
        raise EACRException.Create(11210, ErrorLNilPointer);
      if (LocalBLOBStream.FieldNo = FieldNumber) then
        if ((LocalBLOBStream.OpenMode = bomReadWrite) or
            (LocalBLOBStream.OpenMode = bomWrite)) then
          raise EACRException.Create(11211, ErrorLBLOBFieldAlreadyOpened,
            [FieldNumber, FFieldDefs.Items[FieldNumber].Name]);
    end;
    for i := 0 to FBLOBCache.Count - 1 do
    begin
      LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
      if (LocalBLOBStream = nil) then
        raise EACRException.Create(11213, ErrorLNilPointer);
      // if BLOB already was modified - reopen it
      if (LocalBLOBStream.FieldNo = FieldNumber) then
      begin
        FBLOBCache.Remove(LocalBLOBStream);
        LocalBLOBStream.OpenMode := OpenMode;
        if (OpenMode = bomWrite) then
          LocalBLOBStream.TemporaryStream.Size := 0;
        FBLOBStreams.Add(LocalBLOBStream);
        Result := LocalBLOBStream;
        Exit;
      end;
    end;
  end;
  // create temporary stream
  TempStream := TACRTemporaryStream.Create;
  LocalBLOBStream := TACRLocalBLOBStream.Create(TempStream, Self, OpenMode,
    FieldNumber);
  LocalBLOBStream.DoNotFreeCompressedStream := true;
  Result := LocalBLOBStream;
  FBLOBStreams.Add(Result);
  LocalBLOBStream.OpenMode := OpenMode;
  LocalBLOBStream.Modified := (OpenMode = bomWrite);
  if (not LocalBLOBStream.Modified) then
  begin
    // get blob stream from server
    // send request
    TACRClientSession(FSession).FSentCommandHeader.Request :=
      accrqReadBLOBValue;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID, SizeOf(FCursorID),
      TACRClientSession(FSession).FSentCommandDataStream, 11214);
    SaveDataToStream(FieldNumber, SizeOf(FieldNumber),
      TACRClientSession(FSession).FSentCommandDataStream, 11215);
    SaveDataToStream(CurrentRecordID, SizeOf(TACRRecordID),
      TACRClientSession(FSession).FSentCommandDataStream, 12451);
    if (TACRClientSession(FSession).ExecuteCommand) then
      begin
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
        aaWriteToLog('Client: create client blob stream 1');
{$ENDIF}
        try
          TACRClientSession(FSession).CheckReceivedReply
            (accrplOperationSucceed);
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
          aaWriteToLog('Client: create client blob stream 2');
{$ENDIF}
        except
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
          aaWriteToLog('Client: create client blob stream - error');
{$ENDIF}
          LocalBLOBStream.Free;
          raise ;
        end;
        LoadDataFromStream(Size, SizeOf(Size),
          TACRClientSession(FSession).FReceivedCommandDataStream, 11216);
      end;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
    aaWriteToLog('Client: create client blob stream 3, size = ' + IntToStr
        (Size));
{$ENDIF}
    if (Size > 0) then
      TempStream.LoadFromStreamWithPosition(TACRClientSession(FSession)
          .FReceivedCommandDataStream,
        TACRClientSession(FSession).FReceivedCommandDataStream.Position,
        Size);
  end; // get blob stream from server
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
  aaWriteToLog('Client: create client blob stream  - ok');
{$ENDIF}
end; // InternalCreateBlobStream

//------------------------------------------------------------------------------
// close blob field
//------------------------------------------------------------------------------
procedure TACRClientCursor.InternalCloseBLOB(FieldNo: Integer);
var
  i, j: Integer;
  FieldNumber: Integer;
  LocalBLOBStream: TACRLocalBLOBStream;
begin
  if (FieldNo >= FVisibleFieldDefs.Count) then
    raise EACRException.Create(11220, ErrorLInvalidFieldNumber, [FieldNo,
      FVisibleFieldDefs.Count]);
  if (FBLOBStreams = nil) then
    raise EACRException.Create(11221, ErrorLNilPointer);
  FieldNumber := FVisibleFieldDefs.Items[FieldNo].FieldNoReference;
  i := 0;
  while (i < FBLOBStreams.Count) do
  begin
    LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
    if (LocalBLOBStream = nil) then
      raise EACRException.Create(11222, ErrorLNilPointer);
    if (LocalBLOBStream.FieldNo = FieldNumber) then
    begin
      if (LocalBLOBStream.Modified and ((LocalBLOBStream.OpenMode = bomWrite)
            or (LocalBLOBStream.OpenMode = bomReadWrite))) then
      begin
        // move changed blob value to cache
        j := FBLOBCache.IndexOf(LocalBLOBStream);
        if (j < 0) then
          FBLOBCache.Add(LocalBLOBStream);
      end
      else
        LocalBLOBStream.Free;
      if (LocalBLOBStream.UserBLOBStream <> nil) then
        LocalBLOBStream.UserBLOBStream.Free;
      FBLOBStreams.Delete(i);
      Dec(i);
    end;
    inc(i);
  end; // scan all opened blob streams and close them if necessary
end; // InternalCloseBLOB

//------------------------------------------------------------------------------
// clear blob streams
//------------------------------------------------------------------------------
procedure TACRClientCursor.ClearBLOBStreams(WriteOnly: Boolean = False);
var
  i: Integer;
  LocalBLOBStream: TACRLocalBLOBStream;
begin
  i := 0;
  if (FBLOBStreams <> nil) then
    while (i < FBLOBStreams.Count) and (FBLOBStreams.Count > 0) do
    begin
      LocalBLOBStream := TACRLocalBLOBStream(FBLOBStreams.Items[i]);
      if (LocalBLOBStream = nil) then
        raise EACRException.Create(11223, ErrorLNilPointer);
      if ((Not WriteOnly) or ((WriteOnly) and
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
      inc(i);
    end;
  if (not WriteOnly) then
    if (FBLOBCache <> nil) then
    begin
      for i := 0 to FBLOBCache.Count - 1 do
      begin
        LocalBLOBStream := TACRLocalBLOBStream(FBLOBCache.Items[i]);
        LocalBLOBStream.Free;
      end;
      FBLOBCache.Clear;
    end;
end; // ClearBLOBStreams

//------------------------------------------------------------------------------
// send modified blob values to server
//------------------------------------------------------------------------------
procedure TACRClientCursor.SendModifiedBLOBValues;
var
  i, FieldNumber, Count: Integer;
  Size: Int64;
  LocalBLOBStream: TACRLocalBLOBStream;
begin
  Count := FBLOBCache.Count;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
  aaWriteToLog('Client: send modified blob values, Count = ' + IntToStr(Count)
    );
{$ENDIF}
  SaveDataToStream(Count, SizeOf(Count),
    TACRClientSession(FSession).FSentCommandDataStream, 11224);
  for i := 0 to Count - 1 do
  begin
    LocalBLOBStream := TACRLocalBLOBStream(FBLOBCache.Items[i]);
    if (LocalBLOBStream = nil) then
      raise EACRException.Create(11225, ErrorLNilPointer);
    FieldNumber := LocalBLOBStream.FieldNo;
    Size := LocalBLOBStream.Size;
    LocalBLOBStream.Position := 0;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
    aaWriteToLog('Client: send modified blob values ... FieldNumber = ' +
        IntToStr(FieldNumber) + ', Size = ' + IntToStr(Size)
        + ', Position = ' + IntToStr(LocalBLOBStream.Position)
        + ', openMode = ' + IntToStr(Integer(LocalBLOBStream.OpenMode))
        + ', Modified = ' + IntToStr(Integer(LocalBLOBStream.Modified)));
{$ENDIF}
    SaveDataToStream(FieldNumber, SizeOf(FieldNumber),
      TACRClientSession(FSession).FSentCommandDataStream, 11226);
    SaveDataToStream(Size, SizeOf(Size),
      TACRClientSession(FSession).FSentCommandDataStream, 11227);
    if (Size > 0) then
    begin
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
      aaWriteToLog(
        'Client: send modified blob values ... Saving stream, Start Position = '
          + IntToStr(TACRClientSession(FSession)
            .FSentCommandDataStream.Position) +
          ', LocalBLOBStream.Position = ' + IntToStr(LocalBLOBStream.Position)
        );
{$ENDIF}
      LocalBLOBStream.SaveToStream(TACRClientSession(FSession)
          .FSentCommandDataStream);
      TACRClientSession(FSession).FSentCommandDataStream.Position :=
        TACRClientSession(FSession).FSentCommandDataStream.Position + Size;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
      aaWriteToLog(
        'Client: send modified blob values ... Saving stream ok, End Position = '
          + IntToStr(TACRClientSession(FSession)
            .FSentCommandDataStream.Position) +
          ', LocalBLOBStream.Position = ' + IntToStr(LocalBLOBStream.Position)
        );
{$ENDIF}
    end;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
    aaWriteToLog('Client: send modified blob values ... closing stream ...');
{$ENDIF}
    LocalBLOBStream.DoNotFreeCompressedStream := true;
    LocalBLOBStream.Free;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
    aaWriteToLog
      ('Client: send modified blob values ... closing stream ... OK');
{$ENDIF}
  end;
  FBLOBCache.Clear;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
  aaWriteToLog('send modified blob values ok');
{$ENDIF}
end; // SendModifiedBLOBValues

//------------------------------------------------------------------------------
// LastAutoincValue
//------------------------------------------------------------------------------
function TACRClientCursor.LastAutoincValue(FieldNo: Integer): Int64;
begin
  raise EACRException.Create(11137, ErrorLOperationIsNotSupported);
end; // LastAutoincValue

//------------------------------------------------------------------------------
// SetLastAutoincValue
//------------------------------------------------------------------------------
procedure TACRClientCursor.SetLastAutoincValue(Value: Int64;
  FieldNo: Integer);
begin
  raise EACRException.Create(11138, ErrorLOperationIsNotSupported);
end; // SetLastAutoincValue

//------------------------------------------------------------------------------
// return table state
//------------------------------------------------------------------------------
function TACRClientCursor.GetTableState: TACRTableState;
begin
  // send request
  TACRClientSession(FSession).FSentCommandHeader.Request :=
    accrqGetTableStateCursor;
  TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
  TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
  // prepare params
  SaveDataToStream(FCursorID, SizeOf(FCursorID),
    TACRClientSession(FSession).FSentCommandDataStream, 11938);
  if (TACRClientSession(FSession).ExecuteCommand) then
    begin
      TACRClientSession(FSession).CheckReceivedReply(accrplOperationSucceed);
      LoadDataFromStream(Result, SizeOf(Result),
        TACRClientSession(FSession).FReceivedCommandDataStream, 11939);
    end;
end; // GetTableState


//------------------------------------------------------------------------------
// lock table for read
//------------------------------------------------------------------------------
procedure TACRClientCursor.LockTable(bWriteMode: Boolean);
begin
  { TODO : implement it }
  raise EACRException.Create(11568, ErrorLOperationIsNotSupported);
end; // LockTable


//------------------------------------------------------------------------------
// unlock table for read
//------------------------------------------------------------------------------
procedure TACRClientCursor.UnlockTable(bWriteMode: Boolean);
begin
  { TODO : implement it }
  raise EACRException.Create(11569, ErrorLOperationIsNotSupported);
end; // UnlockTable


//------------------------------------------------------------------------------
// return true if current record exists
//------------------------------------------------------------------------------
function TACRClientCursor.IsRecordExists: Boolean;
begin
  Result := FCache.IsRecordExists;
  if (not Result) then
  begin
    TACRClientSession(FSession).FSentCommandHeader.Request :=
      accrqIsRecordExists;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(FCursorID, SizeOf(FCursorID),
      TACRClientSession(FSession).FSentCommandDataStream, 11281);
    SaveDataToStream(CurrentRecordID, SizeOf(CurrentRecordID),
      TACRClientSession(FSession).FSentCommandDataStream, 11282);
    if (TACRClientSession(FSession).ExecuteCommand) then
      Result := (TACRClientSession(FSession).FReceivedCommandHeader.Reply = accrplYes);
  end;
end; // IsRecordExists

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// send params
//------------------------------------------------------------------------------
procedure TACRClientSQLProcessor.SendParams(Changed: Boolean);
var
  b: ByteBool;
begin
  b := Changed;
  SaveDataToStream(b, SizeOf(b),
    TACRClientSession(FSession).FSentCommandDataStream, 11675);
  if (Changed) then
    FSQLParams.SaveToStream(FSession.FSentCommandDataStream);
end; // SendParams

//------------------------------------------------------------------------------
// receive live query
//------------------------------------------------------------------------------
function TACRClientSQLProcessor.ReceiveLiveQuery: TACRCursor;
begin
  Result := TACRClientCursor.Create;
  Result.TableName := GetTemporaryName(ACRTemporaryTableName);
  Result.Session := FSession;
  TACRClientCursor(Result).ReceiveServerCursor;
  TACRClientCursor(Result).ReceiveFieldNoReferences
    (TACRClientSession(FSession).FReceivedCommandDataStream);
end; // ReceiveLiveQuery

//------------------------------------------------------------------------------
// receive not live query
//------------------------------------------------------------------------------
function TACRClientSQLProcessor.ReceiveNotLiveQuery: TACRCursor;
var
  TempSession: TACRLocalSession;
  b: Byte;
begin
  TempSession := TACRLocalSession.Create;
  TempSession.DatabaseName := ACRTemporaryDatabaseName;
  TempSession.Temporary := true;
  TempSession.Connected := true;
  Result := TACRLocalCursor.Create;
  Result.Temporary := true;
  Result.Session := TempSession;
  Result.LoadTableFromStream(FSession.FReceivedCommandDataStream);
  LoadDataFromStream(b, SizeOf(b), FSession.FReceivedCommandDataStream,
    11621);
  Result.OpenTableByFieldDefs(nil, nil, nil);
  Result.InternalInitFieldDefs;
  if (Result.IndexDefs.Count > 0) then
  begin
    Result.IndexName := Result.IndexDefs.Items[0].Name;
    Result.IndexID := Result.IndexDefs.Items[0].ObjectID;
  end;
  if (b = 1) then
  begin
    Result.FVisibleFieldDefs.LoadFromStream
      (FSession.FReceivedCommandDataStream);
    Result.ReceiveFieldNoReferences(FSession.FReceivedCommandDataStream);
    Result.FIsProjectionSet := true;
  end;
end; // ReceiveNotLiveQuery


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientSQLProcessor.Create(Query: TDataSet;
                                    aSession: TACRBaseSession; CaseIns: Boolean);
begin
  inherited Create(Query);
  FSession := TACRClientSession(aSession);
  FCursor := nil;
  FCaseInsensitive := CaseIns;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRClientSQLProcessor.Destroy;
begin
  if (FCursor <> nil) then
  begin
    // live parametrized query
    FCursor.Free;
  end
  else if (LRemoteQuery <> nil) then
  begin
    // unprepare and free parametrized query
    TACRClientSession(FSession).FSentCommandHeader.Request :=
      accrqSQLUnprepareParams;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    SaveDataToStream(LRemoteQuery, SizeOf(LRemoteQuery),
      TACRClientSession(FSession).FSentCommandDataStream, 11683);
    TACRClientSession(FSession).ExecuteCommand;
  end;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// Open query
//------------------------------------------------------------------------------
function TACRClientSQLProcessor.OpenQuery(TableNames: TACRWideStringList): TACRCursor;
var
  b: ByteBool;
  QueryText: WideString;
begin
  FLive := False;
  Result := inherited OpenQuery;
  QueryText := TACRQuery(FACRQuery).SQL.Text;
  if (FNeverOpened) then
  begin
    LRemoteQuery := nil;
    if (QueryText <> '') then
    begin
      // send request
      TACRClientSession(FSession).FSentCommandHeader.Request := accrqExecSQL;
      TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
      TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
      // pointer to remote parametrized query or nil if first opening / not parametrized
      SaveDataToStream(LRemoteQuery, SizeOf(LRemoteQuery),
        TACRClientSession(FSession).FSentCommandDataStream, 11676);
      // save query text
      SaveWideStringToStream(QueryText,
        TACRClientSession(FSession).FSentCommandDataStream, 11170);
      b := TACRQuery(FACRQuery).RequestLive;
      SaveDataToStream(b, SizeOf(b),
        TACRClientSession(FSession).FSentCommandDataStream, 11173);
      b := TACRQuery(FACRQuery).ReadOnly;
      SaveDataToStream(b, SizeOf(b),
        TACRClientSession(FSession).FSentCommandDataStream, 11174);
      b := FCaseInsensitive;
      SaveDataToStream(b, SizeOf(b),
        TACRClientSession(FSession).FSentCommandDataStream, 12547);
      SendParams(true);
      if (TACRClientSession(FSession).ExecuteCommand) then
        begin
          TACRClientSession(FSession).CheckReceivedReply
            (accrplOperationSucceed);
          // pointer to remote parametrized query or nil if first opening / not parametrized
          LoadDataFromStream(LRemoteQuery, SizeOf(LRemoteQuery),
            TACRClientSession(FSession).FReceivedCommandDataStream, 11678);
          // get number of rows affected by query
          LoadDataFromStream(FRowsAffected, SizeOf(FRowsAffected),
            TACRClientSession(FSession).FReceivedCommandDataStream, 11175);
          // get cursor if necessary
          LoadDataFromStream(b, SizeOf(b),
            TACRClientSession(FSession).FReceivedCommandDataStream, 11176);
          if (b) then
          begin
            // receive cursor info if live query or receive records if not live query
            LoadDataFromStream(b, SizeOf(b),
              TACRClientSession(FSession).FReceivedCommandDataStream, 11177);
            if (b) then
            begin
              Result := ReceiveLiveQuery;
              FLive := true;
              // live parametrized query
              if (LRemoteQuery <> nil) then
                FCursor := Result;
            end
            else
              Result := ReceiveNotLiveQuery;
            Result.ReadOnly := not b;
            Result.IsClientCursor := true;
            FReadOnly := Result.ReadOnly;
          end;
          TACRClientSession(FSession).FReceivedCommandDataStream.Size := 0;
        end;
    end
    else
      raise EACRException.Create(11172, ErrorLNoQueryText);
    FNeverOpened := False;
  end
  else
  begin
    // reopening parametrized query
    // send request
    TACRClientSession(FSession).FSentCommandHeader.Request := accrqExecSQL;
    TACRClientSession(FSession).FSentCommandHeader.Reply := accrplNULL;
    TACRClientSession(FSession).FSentCommandDataStream.Size := 0;
    // pointer to remote parametrized query or nil if first opening / not parametrized
    SaveDataToStream(LRemoteQuery, SizeOf(LRemoteQuery),
      TACRClientSession(FSession).FSentCommandDataStream, 11677);
    // save query text
    b := TACRQuery(FACRQuery).RequestLive;
    SaveDataToStream(b, SizeOf(b),
      TACRClientSession(FSession).FSentCommandDataStream, 11681);
    b := TACRQuery(FACRQuery).ReadOnly;
    SaveDataToStream(b, SizeOf(b),
      TACRClientSession(FSession).FSentCommandDataStream, 11682);
    SendParams(FParamsChanged);
    if (TACRClientSession(FSession).ExecuteCommand) then
      begin
        TACRClientSession(FSession).CheckReceivedReply
          (accrplOperationSucceed);
        // get number of rows affected by query
        LoadDataFromStream(FRowsAffected, SizeOf(FRowsAffected),
          TACRClientSession(FSession).FReceivedCommandDataStream, 11684);
        // get cursor if necessary
        LoadDataFromStream(b, SizeOf(b),
          TACRClientSession(FSession).FReceivedCommandDataStream, 11685);
        if (b) then
        begin
          // receive cursor info if live query or receive records if not live query
          LoadDataFromStream(b, SizeOf(b),
            TACRClientSession(FSession).FReceivedCommandDataStream, 11686);
          if (not b) then
            Result := ReceiveNotLiveQuery
          else
          begin
            Result := FCursor;
            FLive := true;
          end;
          // Result := ReceiveLiveQuery
          // else
          Result.ReadOnly := not b;
          Result.IsClientCursor := true;
          FReadOnly := Result.ReadOnly;
        end;
        TACRClientSession(FSession).FReceivedCommandDataStream.Size := 0;
      end;
  end;
end; // OpenQuery

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRClient> initializing...');
{$ENDIF}
ClientConnectionManager := nil;
ACRMemoryIncUseCount;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRClient> initialized');
{$ENDIF}

finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRClient> finalizing...');
{$ENDIF}
if (ClientConnectionManager <> nil) then
 begin
  ClientConnectionManager.Free;
  ClientConnectionManager := nil;
 end;
ACRMemoryDecUseCount;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRClient> finalized');
{$ENDIF}

end.
