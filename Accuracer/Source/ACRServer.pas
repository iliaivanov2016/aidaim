//------------------------------------------------------------------------------
//
// Server classes, Server component
// Uses Local Engine
//
//------------------------------------------------------------------------------

unit ACRServer;

interface

{$WARNINGS OFF}
{$HINTS OFF}
{$I ACRVer.inc}

uses SysUtils,Classes,IniFiles,DB,

// Accuracer units
{$IFDEF DEBUG_LOG}
	ACRDebug,
{$ENDIF}
{$IFNDEF D5H}
	ACRD4Routines,
{$ENDIF}
	ACRConnection,
	ACRLexer,
	ACRExcept,
	ACRCommunication,
	ACRBase,
	ACRBaseEngine,
	ACRLocalEngine,
	ACRCompression,
	ACRCrypto,
	ACRVariant,
	ACRTypes,
  ACRTypesNetwork,
	ACRSQLProcessor,
	ACRMain,
	ACRComMain,
	ACRConst;

type

	TACRServer = class;
	TACRServerCursor = class;
	TACRServerRecordCache = class;
	TACRServerSession = class;

	TACRClientInfo = packed record
    Protocol: TACRClientProtocol;
		Host: AnsiString;
		Port: Integer;
		Application: AnsiString;
		DatabaseName: AnsiString;
		DatabaseFileName: AnsiString;
		SessionID: TACRSessionID;
	end; // TACRClientInfo

	TACRClientInfoArray = array of TACRClientInfo;

	TACROnSQL = procedure(Sender: TComponent; ClientInfo: TACRClientInfo;
		Params: TACRSQLParams; var SQL: WideString; var Abort: Boolean) of object;
	TACRServerBeforeInsertRecord = procedure(Sender: TObject;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
		var Abort: Boolean) of object;
	TACRServerAfterInsertRecord = procedure(Sender: TObject;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant)
		of object;

	TACRServerBeforeUpdateRecord = procedure(Sender: TObject;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		const TableName: WideString; const OldFieldValues: TACRArrayOfTACRVariant;
		const NewFieldValues: TACRArrayOfTACRVariant; var Abort: Boolean) of object;
	TACRServerAfterUpdateRecord = procedure(Sender: TObject;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		const TableName: WideString; const OldFieldValues: TACRArrayOfTACRVariant;
		const NewFieldValues: TACRArrayOfTACRVariant) of object;

	TACRServerBeforeDeleteRecord = procedure(Sender: TObject;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
		var Abort: Boolean) of object;
	TACRServerAfterDeleteRecord = procedure(Sender: TObject;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant)
		of object;

	TACRServerBeforeExecuteSQL = procedure(Sender: TACRQuery;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
		var Abort: Boolean) of object;
	TACRServerAfterExecuteSQL = procedure(Sender: TACRQuery;
		ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase) of object;

	TACROnServerReceiveTextMessage = procedure(const Client: TACRClientInfo;
		const Text: AnsiString) of object;
	TACROnServerReceiveUnicodeTextMessage = procedure
		(const Client: TACRClientInfo;
		const Text: WideString) of object;
	TACROnServerReceiveBinaryMessage = procedure(const Client: TACRClientInfo;
		Buffer: PAnsiChar; Size: Integer) of object;
	TACROnServerReceiveStreamMessage = procedure(const Client: TACRClientInfo;
		Stream: TStream) of object;


  TACRServerConnectParamsEditor = class;

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////

	TACRServerNetworkSettingsEditor = class(TACRNetworkSettingsEditor)
	private
    FOwner: TACRServerConnectParamsEditor;
		FServerReceiveTimeOut: Integer;
		FServerReceiveSleep: Integer;
		FMinServerSendTimeOut: Integer;
		FServerSendTimeOut: Integer;
		FServerWaitForSendSleep: Integer;
		FServerResendDelay: Integer;
		FServerRequestDelay: Integer;
		FWaitForMessagesSend: Integer;
		FWaitForServerSessionThreadTimeOut: Integer;
		FServerThreadsTerminateDelay: Integer;
		FServerSessionTerminatorSleep: Integer;
		FPingCount: Integer;
		FWaitForPingAnswer: Integer;
		FServerPingSleep: Integer;
		FPingClients: Boolean;
		FKeepConnection: Boolean;
	public
		constructor Create(Owner: TACRServerConnectParamsEditor);
		destructor Destroy; override;
		procedure Assign(Source: TPersistent); override;
		procedure CopySettingsToConnectParams(var ConnectParams: TACRConnectParams); override;
		procedure SetDefaultSettings(Value: TACRDefaultNetworkSettings); override;
	published
		property ServerReceiveTimeOut: Integer read FServerReceiveTimeOut write FServerReceiveTimeOut;
		property ServerReceiveSleep: Integer read FServerReceiveSleep write FServerReceiveSleep;
		property MinServerSendTimeOut: Integer read FMinServerSendTimeOut write FMinServerSendTimeOut;
		property ServerSendTimeOut: Integer read FServerSendTimeOut write FServerSendTimeOut;
		property ServerWaitForSendSleep: Integer read FServerWaitForSendSleep write	FServerWaitForSendSleep;
		property ServerResendDelay: Integer read FServerResendDelay write FServerResendDelay;
		property ServerRequestDelay: Integer read FServerRequestDelay write FServerRequestDelay;
		property WaitForMessagesSend: Integer read FWaitForMessagesSend write FWaitForMessagesSend;
		property WaitForServerSessionThreadTimeOut: Integer read FWaitForServerSessionThreadTimeOut write FWaitForServerSessionThreadTimeOut;
		property ServerThreadsTerminateDelay: Integer read FServerThreadsTerminateDelay write	FServerThreadsTerminateDelay;
		property ServerSessionTerminatorSleep: Integer read FServerSessionTerminatorSleep write	FServerSessionTerminatorSleep;
		property PingCount: Integer read FPingCount write FPingCount;
		property WaitForPingAnswer: Integer read FWaitForPingAnswer write FWaitForPingAnswer;
		property ServerPingSleep: Integer read FServerPingSleep write FServerPingSleep;
		property PingClients: Boolean read FPingClients write FPingClients;
		property KeepConnection: Boolean read FKeepConnection write FKeepConnection;
	end; // TACRServerNetworkSettingsEditor


////////////////////////////////////////////////////////////////////////////////
//
// TACRServerConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

	TACRServerConnectParamsEditor = class(TACRConnectionParamsEditor)
	private
//    FServer:                    TACRServer;
    FProtocol:              TACRServerProtocol;
    FLocalPortTCP,
    FLocalPortUDP:          Cardinal;
		FNetworkSettings:       TACRServerNetworkSettingsEditor;
	public
		constructor Create;
		destructor Destroy; override;
		procedure Assign(Source: TPersistent); override;
		function GetConnectParams: TACRConnectParams; override;
  protected
    procedure SetProtocol(Value: TACRServerProtocol);
    procedure SetLocalPort(Value: Cardinal); // compatibility with old UDP only component
    function GetLocalPort: Cardinal; // compatibility with old UDP only component
	public
    property LocalPort: Cardinal read GetLocalPort write SetLocalPort; // compatibility with old UDP only component
  protected
    procedure SetLocalPortTCP(Value: Cardinal);
    function GetLocalPortTCP: Cardinal;
    procedure SetLocalPortUDP(Value: Cardinal);
    function GetLocalPortUDP: Cardinal;
	published
    property Protocol: TACRServerProtocol read FProtocol write SetProtocol;
    property LocalPortTCP: Cardinal read GetLocalPortTCP write SetLocalPortTCP;
    property LocalPortUDP: Cardinal read GetLocalPortUDP write SetLocalPortUDP;
{$IFDEF RELEASE_BUILD}
	public
{$ENDIF}
		property NetworkSettings: TACRServerNetworkSettingsEditor read FNetworkSettings write	FNetworkSettings;
	end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRServer
//
////////////////////////////////////////////////////////////////////////////////
{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
	TACRServer = class(TComponent)
	private
		FUseConfigFile: Boolean;
		FMaxCommandExecutionTime: Integer; // in seconds
		FConnectionParams: TACRServerConnectParamsEditor;
//    FNetworkSettings:               TACRServerNetworkSettingsEditor;
//    FLocalHost:                     AnsiString;
//    FLocalPort:                     Integer;
//    FServerID:                      Integer;
//    FCryptoParamsEditor:            TACRCryptoParamsEditor;
		FOnError: TACROnError;
		FBeforeServerStart: TNotifyEvent;
		FAfterServerStart: TNotifyEvent;
		FBeforeServerStop: TNotifyEvent;
		FAfterServerStop: TNotifyEvent;
		FCurrentVersion: AnsiString;
		FActive: Boolean;
		FConfigFileName: AnsiString;
		FDatabaseNames: TStrings;
		FDatabaseFileNames: TStrings;
		FOpenDatabasesInExclusiveMode: Boolean;
		FLockParams: TACRLockParams;
		FOnSQL: TACROnSQL;
		FBeforeInsertRecord: TACRServerBeforeInsertRecord;
		FBeforeUpdateRecord: TACRServerBeforeUpdateRecord;
		FBeforeDeleteRecord: TACRServerBeforeDeleteRecord;
		FBeforeExecuteSQL: TACRServerBeforeExecuteSQL;
		FAfterInsertRecord: TACRServerAfterInsertRecord;
		FAfterUpdateRecord: TACRServerAfterUpdateRecord;
		FAfterDeleteRecord: TACRServerAfterDeleteRecord;
		FAfterExecuteSQL: TACRServerAfterExecuteSQL;
		FOnReceiveTextMessage: TACROnServerReceiveTextMessage;
		FOnReceiveUnicodeTextMessage: TACROnServerReceiveUnicodeTextMessage;
		FOnReceiveBinaryMessage: TACROnServerReceiveBinaryMessage;
		FOnReceiveStreamMessage: TACROnServerReceiveStreamMessage;
  public
		FConnectionManager: TACRServerConnectionManager;
	protected
		function GetDatabaseCount: Integer;
		procedure StartServer;
		procedure StopServer;
		procedure DoOnSQL(ClientInfo: TACRClientInfo; Params: TACRSQLParams;
			var SQL: WideString; var Abort: Boolean);
		procedure DoBeforeInsertRecord(Sender: TObject; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; const TableName: WideString;
			const FieldValues: TACRArrayOfTACRVariant; var Abort: Boolean);
		procedure DoAfterInsertRecord(Sender: TObject; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; const TableName: WideString;
			const FieldValues: TACRArrayOfTACRVariant);

		procedure DoBeforeUpdateRecord(Sender: TObject; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; const TableName: WideString;
			const OldFieldValues: TACRArrayOfTACRVariant;
			const NewFieldValues: TACRArrayOfTACRVariant; var Abort: Boolean);
		procedure DoAfterUpdateRecord(Sender: TObject; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; const TableName: WideString;
			const OldFieldValues: TACRArrayOfTACRVariant;
			const NewFieldValues: TACRArrayOfTACRVariant);

		procedure DoBeforeDeleteRecord(Sender: TObject; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; const TableName: WideString;
			const FieldValues: TACRArrayOfTACRVariant; var Abort: Boolean);
		procedure DoAfterDeleteRecord(Sender: TObject; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; const TableName: WideString;
			const FieldValues: TACRArrayOfTACRVariant);

		procedure DoBeforeExecuteSQL(Sender: TACRQuery; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase; var Abort: Boolean);
		procedure DoAfterExecuteSQL(Sender: TACRQuery; ClientInfo: TACRClientInfo;
			LocalDatabase: TACRDatabase);

		procedure DoOnError(const ErrorCode: Integer; const NativeError: Integer;
			const ErrorMessage: AnsiString);
	public
		procedure DoOnConnectionError(const ErrorCode: Integer;
			const NativeError: Integer; const ErrorMessage: AnsiString);
		procedure LoadDefaultSettings;
		procedure LoadSettingsFromConfigFile;
		procedure SaveSettingsToConfigFile;
	protected
		procedure LoadServerSettings;
		function GetCurrentVersion: AnsiString;
		procedure SetActive(Value: Boolean);
		procedure SetDatabaseNames(Value: TStrings);
		procedure SetDatabaseFileNames(Value: TStrings);
		function GetClientSession(const Client: TACRClientInfo): TACRServerSession;
		procedure ReceiveMessage(ServerSession: TACRServerSession;
			Buffer: PAnsiChar; Size: Integer);
	public
		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
		function FindDatabaseByName(Name: AnsiString): Integer;
		procedure GetClients(var Clients: TACRClientInfoArray);
	public
		function IsClientConnected(const Client: TACRClientInfo): Boolean;
    // disconnect client by Host:Port
		procedure Disconnect(const Host: AnsiString; const Port: Integer); overload;
    // disconnect client by SessionID
		procedure Disconnect(const SessionID: Integer); overload;
		procedure SendMessage(const Client: TACRClientInfo;
			const Text: AnsiString); overload;
		procedure SendMessage(const Client: TACRClientInfo;
			const Text: WideString); overload;
		procedure SendMessage(const Client: TACRClientInfo; Buffer: PAnsiChar;
			Size: Integer); overload;
		procedure SendMessage(const Client: TACRClientInfo; Stream: TStream);
			overload;
	public
		property DatabaseCount: Integer read GetDatabaseCount;
		property ConnectionManager
			: TACRServerConnectionManager read FConnectionManager;
		property LockParams: TACRLockParams read FLockParams;
(* old
    property CryptoParams: TACRCryptoParamsEditor read CryptoParams write CryptoParams;
    property NetworkSettings: TACRServerNetworkSettingsEditor read FNetworkSettings write FNetworkSettings;
    property LocalHost: AnsiString read FLocalHost write FLocalHost;
    property LocalPort: Integer read FLocalPort write FLocalPort;
    property ServerID: Integer read FServerID write FServerID;
*)
		procedure SetCryptoParams(CryptoParams: TACRCryptoParamsEditor);
		function GetCryptoParams: TACRCryptoParamsEditor;
		procedure SetNetworkSettings(NetworkSettings
				: TACRServerNetworkSettingsEditor);
		function GetNetworkSettings: TACRServerNetworkSettingsEditor;
		procedure SetLocalHost(Host: AnsiString);
		function GetLocalHost: AnsiString;
		procedure SetLocalPort(Port: Integer);
		function GetLocalPort: Integer;
		procedure SetServerID(ID: Integer);
		function GetServerID: Integer;
		property CryptoParams: TACRCryptoParamsEditor read GetCryptoParams write
			SetCryptoParams;
		property NetworkSettings: TACRServerNetworkSettingsEditor read
			GetNetworkSettings write SetNetworkSettings;
		property LocalHost: AnsiString read GetLocalHost write SetLocalHost;
		property LocalPort: Integer read GetLocalPort write SetLocalPort;
		property ServerID: Integer read GetServerID write SetServerID;
	published
		property ConnectionParams
			: TACRServerConnectParamsEditor read FConnectionParams write
			FConnectionParams;
		property UseConfigFile: Boolean read FUseConfigFile write FUseConfigFile;
		property Active: Boolean read FActive write SetActive;
		property CurrentVersion
			: AnsiString read GetCurrentVersion write FCurrentVersion;
		property DatabaseNames: TStrings read FDatabaseNames write SetDatabaseNames;
		property DatabaseFileNames: TStrings read FDatabaseFileNames write
			SetDatabaseFileNames;
		property ConfigFileName
			: AnsiString read FConfigFileName write FConfigFileName;
		property BeforeServerStart
			: TNotifyEvent read FBeforeServerStart write FBeforeServerStart;
		property AfterServerStart
			: TNotifyEvent read FAfterServerStart write FAfterServerStart;
		property BeforeServerStop
			: TNotifyEvent read FBeforeServerStop write FBeforeServerStop;
		property AfterServerStop
			: TNotifyEvent read FAfterServerStop write FAfterServerStop;
		property OpenDatabasesInExclusiveMode
			: Boolean read FOpenDatabasesInExclusiveMode write
			FOpenDatabasesInExclusiveMode;
		property OnSQL: TACROnSQL read FOnSQL write FOnSQL;
		property BeforeInsertRecord
			: TACRServerBeforeInsertRecord read FBeforeInsertRecord write
			FBeforeInsertRecord;
		property BeforeUpdateRecord
			: TACRServerBeforeUpdateRecord read FBeforeUpdateRecord write
			FBeforeUpdateRecord;
		property BeforeDeleteRecord
			: TACRServerBeforeDeleteRecord read FBeforeDeleteRecord write
			FBeforeDeleteRecord;
		property BeforeExecuteSQL
			: TACRServerBeforeExecuteSQL read FBeforeExecuteSQL
			write FBeforeExecuteSQL;
		property AfterInsertRecord
			: TACRServerAfterInsertRecord read FAfterInsertRecord write
			FAfterInsertRecord;
		property AfterUpdateRecord
			: TACRServerAfterUpdateRecord read FAfterUpdateRecord write
			FAfterUpdateRecord;
		property AfterDeleteRecord
			: TACRServerAfterDeleteRecord read FAfterDeleteRecord write
			FAfterDeleteRecord;
		property AfterExecuteSQL
			: TACRServerAfterExecuteSQL read FAfterExecuteSQL write
			FAfterExecuteSQL;
		property OnReceiveTextMessage
			: TACROnServerReceiveTextMessage read FOnReceiveTextMessage write
			FOnReceiveTextMessage;
		property OnReceiveUnicodeTextMessage
			: TACROnServerReceiveUnicodeTextMessage
			read FOnReceiveUnicodeTextMessage write FOnReceiveUnicodeTextMessage;
		property OnReceiveBinaryMessage
			: TACROnServerReceiveBinaryMessage read FOnReceiveBinaryMessage write
			FOnReceiveBinaryMessage;
		property OnReceiveStreamMessage
			: TACROnServerReceiveStreamMessage read FOnReceiveStreamMessage write
			FOnReceiveStreamMessage;
		property OnError: TACROnError read FOnError write FOnError;
		property MaxCommandExecutionTime
			: Integer read FMaxCommandExecutionTime write
			FMaxCommandExecutionTime; // in seconds
	end; // TACRServer

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSession
//
////////////////////////////////////////////////////////////////////////////////

	TACRServerSession = class(TACRNetworkSession)
	private
		FServer: TACRServer;
		FServerSession: Pointer;
		FDatabase: TACRDatabase;
		FHandle: TACRLocalSession;
		FLastCursorID: TACRObjectID;
		FCursorList: TList;
		FQueryList: TList; // list of parametrized queries
	protected
    // get error message and raises an excpetion
		procedure SendErrorMessage(ErrorCode: Integer; ErrorMessage: WideString);
    // find server cursor by id
		function FindServerCursor(CursorID: TACRObjectID): TACRServerCursor;
    // send vsisiblefielddefs.fieldnoreference
		procedure SendFieldNoReferences(aCursor: TACRLocalCursor);
    // create server cursor, put information about it to FSentCommandDataStream and add it to the CursorList
		function CreateServerCursor(aCursor: TACRLocalCursor;
			aQuery: TACRQuery = nil): TACRServerCursor;
    //---------------------- SQL support ---------------------------------------
    // receive SQL Params
		function ReceiveParams(FQuery: TACRQuery): Boolean;
		procedure SendLiveQuery(FQuery: TACRQuery; LocalCursor: TACRLocalCursor);
		procedure SendNotLiveQuery(FQuery: TACRQuery; LocalCursor: TACRLocalCursor);
		procedure RemoveQueryFromQueryList(FQuery: TACRQuery);
    //--------------------- base methods ---------------------------------------
		procedure SetConnected(Value: Boolean); override;
    // db connected?
		function GetConnected: Boolean; override;
		procedure DoBeforeInsertRecord(Sender: TACRDataSet;
			const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
			var Abort: Boolean);
		procedure DoAfterInsertRecord(Sender: TACRDataSet;
			const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant);
		procedure DoBeforeUpdateRecord(Sender: TACRDataSet;
			const TableName: WideString;
			const OldFieldValues: TACRArrayOfTACRVariant;
			const NewFieldValues: TACRArrayOfTACRVariant; var Abort: Boolean);
		procedure DoAfterUpdateRecord(Sender: TACRDataSet;
			const TableName: WideString;
			const OldFieldValues: TACRArrayOfTACRVariant;
			const NewFieldValues: TACRArrayOfTACRVariant);
		procedure DoBeforeDeleteRecord(Sender: TACRDataSet;
			const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
			var Abort: Boolean);
		procedure DoAfterDeleteRecord(Sender: TACRDataSet;
			const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant);

		procedure DoBeforeExecuteSQL(Sender: TACRQuery; var Abort: Boolean);
		procedure DoAfterExecuteSQL(Sender: TACRQuery);

		function IsBeforeInsertRecordAssigned: Boolean;
		function IsAfterInsertRecordAssigned: Boolean;
		function IsBeforeUpdateRecordAssigned: Boolean;
		function IsAfterUpdateRecordAssigned: Boolean;
		function IsBeforeDeleteRecordAssigned: Boolean;
		function IsAfterDeleteRecordAssigned: Boolean;
		function IsBeforeExecuteSQLAssigned: Boolean;
		function IsAfterExecuteSQLAssigned: Boolean;
	public
    // check if database exists
		function GetDatabaseExists: Boolean; override;
		procedure GetTablesList(List: TACRWideStringList); override;
		function TableExists(TableName: WideString): Boolean; override;
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
    // return true if CryptoParams are valid
		function IsCryptoParamsValid: Boolean; override;
    //------------------------ Transactions ------------------------------------
	protected
    // retrun true if database has active transaction
		function GetInTransaction: Boolean; override;
	public
    // start a transaction
		procedure StartTransaction; override;
    // apply changes made by transaction
		procedure Commit(FlushFileBuffers: Boolean = True); override;
    // cancel changes made by transaction
		procedure Rollback; override;
    // flush file buffers
		procedure FlushFileBuffers; override;
	public
    // Back link to corresponding structure (PMsgSrvrSession) in ConnectionManager.Sessions
		procedure SetServerSession(Value: Pointer);
    constructor Create(aServer: TComponent);
		destructor Destroy; override;
    // call OnError event handler
		procedure DoOnError(ErrorCode: Integer; NativeError: Integer = -1;
			ErrorMessage: AnsiString = ''); override;
		procedure DoCloseSessionOnNetworkError; override;
    // execute received command
		procedure ExecuteReceivedCommand;
    // receive data from network and move it to ReceivedCommandHeader and ReceivedCommandDataStream
		procedure ReceiveData(Buffer: PAnsiChar; BufferSize: Integer); override;
    // SendCommand
		function SendCommand: Boolean; override;
    // send buffer via established connection using connection manager
    // -- using to send command reply
		procedure SendBuffer(var Buffer: PAnsiChar; BufferSize: Integer); override;
    // send server command to client
		procedure SendServerCommand(Buffer: PAnsiChar; Size: Integer);
    // send custom message to client
		procedure SendMessage(Buffer: PAnsiChar; BufferSize: Integer); override;
    // receive custom message from client
		procedure ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer); override;
	protected
		function GetClientInfo: TACRClientInfo;
    //--------------------- Executing client requests --------------------------
    // execute ConnectDatabase request
		procedure ExecuteConnectDatabase;
    // execute IsDatabaseExists
		procedure ExecuteIsDatabaseExists;
    // execute GetTablesList
		procedure ExecuteGetTablesList;
    // execute IsTableExists
		procedure ExecuteIsTableExists;
    // execute GetFormatVersion
		procedure ExecuteGetFormatVersion;
    // execute GetTotalPageCount
		procedure ExecuteGetTotalPageCount;
    // execute GetFreePageCount
		procedure ExecuteGetFreePageCount;
    // execute IsDatabaseEncrypted
		procedure ExecuteIsDatabaseEncrypted;
    // execute IsDatabaseEncryptedByPassword
		procedure ExecuteIsDatabaseEncryptedByPassword;
    // execute IsCryptoParamsValid
		procedure ExecuteIsCryptoParamsValid;
    // execute IsInTransaction
		procedure ExecuteIsInTransaction;
    // execute StartTransaction
		procedure ExecuteStartTransaction;
    // execute Commit
		procedure ExecuteCommit;
    // execute Rollback
		procedure ExecuteRollback;

    //------------------------- Cursor Commands --------------------------------

    // execute CreateTable
		procedure ExecuteCreateTable;
    // execute DeleteTable
		procedure ExecuteDeleteTable;
    // execute EmptyTable
		procedure ExecuteEmptyTable;
    // execute RenameTable
		procedure ExecuteRenameTable;
    // execute RenameField
		procedure ExecuteRenameField;
    // execute OpenTable
		procedure ExecuteOpenTable;
    // execute CloseTable
		procedure ExecuteCloseTable;
    // execute AddIndex
		procedure ExecuteAddIndex;
    // execute DeleteIndex
		procedure ExecuteDeleteIndex;
    // execute DeleteAllIndexes
		procedure ExecuteDeleteAllIndexes;
    // execute GetRecordCount
		procedure ExecuteGetRecordCount;
    // execute GetRecordBuffer
		procedure ExecuteGetRecordBuffer;
    // execute SetRecNo
		procedure ExecuteSetRecNo;
    // execute GetRecNo
//    procedure ExecuteGetRecNo;
    // execute InternalEdit
		procedure ExecuteInternalEdit;
    // execute InternalCancel
		procedure ExecuteInternalCancel;
    // execute InternalPost
		procedure ExecuteInternalPost;
    // execute InternalDelete
		procedure ExecuteInternalDelete;
    // execute ActivateFilters
		procedure ExecuteActivateFilters;
    // execute DeactivateFilters
		procedure ExecuteDeactivateFilters;
    // execute Locate
		procedure ExecuteLocate;
    // execute FindKey
		procedure ExecuteFindKey;
    // execute ResetRange
		procedure ExecuteResetRange;
    // execute ApplyRange
		procedure ExecuteApplyRange;
    // execute ReadBLOBValue
		procedure ExecuteReadBLOBValue;

    // execute ExecSQL
		procedure ExecuteExecSQL;
    // unprepare params and free parametrized query completely
		procedure ExecuteSQLUnprepareParams;

    // execute IsRecordExists
		procedure ExecuteIsRecordExists;
    // execute ExportTableToSQL
		procedure ExecuteExportTableToSQL;
    // execute ExportDatabaseToSQL
		procedure ExecuteExportDatabaseToSQL;
		procedure ExecuteGetTablesInfo;
		procedure ExecuteGetTableState;
		procedure ExecuteGetTableStateCursor;
		procedure ExecuteGetTableComment;
		procedure ExecuteSetTableComment;
		procedure ExecuteLoadRecords;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
		procedure ExecuteCreateStoredFunction;
		procedure ExecuteDropStoredFunction;
		procedure ExecuteAlterStoredFunction;
		procedure ExecuteAlterStoredFunctionRename;
		procedure ExecuteFindStoredFunction;
		procedure ExecuteGetStoredFunctions;
		procedure ExecuteExportStoredFunctionsToSQL;
    //-------- END OF STORED FUNCTIONS AND PROCEDURES - added in v.5.10 --------
		procedure ExecuteClearCache;
		procedure ExecuteFlushFileBuffers;
    // added in v.5.90
		procedure ExecuteSetCaseInsensitive;
    // added in v.6.00
		procedure ExecuteCreateView;
		procedure ExecuteDropView;
	end; // TACRServerSession

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerRecordCache - cache class for server cursor
//
////////////////////////////////////////////////////////////////////////////////

	TACRServerRecordCache = class(TACRBaseRecordCache)
	protected
		LServerCursor: TACRServerCursor;
	protected
		function InternalLoadRecord(RecLow, RecHigh, RecNo: TACRRecordNo)
			: TACRGetRecordResult;
	public
		constructor Create(aMinRecords, aMaxRecords: Integer;
			aServerCursor: TACRServerCursor; aLocalCursor: TACRLocalCursor);
			overload;
		destructor Destroy; override;
   // all parameters are set to server cursor
		function Load(GetRecordMode: TACRGetRecordMode): TACRGetRecordResult;
   // set RecNo
		procedure SetRecNo(RecNo: TACRRecordNo; IndexID: TACRObjectID);
	public
	end; // TACRServerRecordCache

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerCursor
//
////////////////////////////////////////////////////////////////////////////////

	TACRServerCursor = class(TObject)
	private
		FCursorID: TACRObjectID;
		FLocalCursor: TACRLocalCursor;
		FQuery: TACRQuery;
		FCurrentRecordBuffer: TACRRecordBuffer;
		FEditRecordBuffer: TACRRecordBuffer;
		FSession: TACRServerSession;
		FForcedDestroy: Boolean;
    // field vlaues for insert, update, delete record events of TACRServer
		FOldFieldValues: TACRArrayOfTACRVariant; // for update / delete
		FNewFieldValues: TACRArrayOfTACRVariant; // for update / insert
		FCache: TACRServerRecordCache;
		FState: TACRTableState;
	protected
		procedure SendRecordBuffer(const ErrorCode: Integer;
			RecordBuffer: TACRRecordBuffer);
		procedure ReceiveRecordBuffer(const ErrorCode: Integer;
			RecordBuffer: TACRRecordBuffer);
		procedure ReceiveModifiedBLOBValues(ToInsert: Boolean);
    //---------------------------------------------------------------------------
    //  insert, update, delete record events of TACRServer
    //---------------------------------------------------------------------------
		procedure CreateOldNewFieldValues;
		procedure FreeOldNewFieldValues;
		procedure SaveValues(var Values: TACRArrayOfTACRVariant);
		procedure ClearValues(var Values: TACRArrayOfTACRVariant);
		function DoBeforeInsertRecord: Boolean;
		procedure DoAfterInsertRecord;
		function DoBeforeUpdateRecord: Boolean;
		procedure DoAfterUpdateRecord;
		function DoBeforeDeleteRecord: Boolean;
		procedure DoAfterDeleteRecord;
	public
		constructor Create(aCursor: TACRLocalCursor; aCursorID: TACRObjectID;
			aSession: TACRServerSession; aQuery: TACRQuery = nil);
		destructor Destroy; override;
		procedure ApplyDefaultValues;
		procedure GetRecordCount;
		procedure GetRecordBuffer;
		procedure LoadRecords;
		procedure SetRecNo;
//    procedure GetRecNo;
		procedure InternalEdit;
		procedure InternalCancel;
		procedure InternalPost;
		procedure InternalDelete;
		procedure ActivateFilters;
		procedure DeactivateFilters;
		procedure Locate;
		procedure FindKey;
		procedure ResetRange(DoNotSendReply: Boolean = False);
		procedure ApplyRange;
		procedure ReadBLOBValue;
		procedure IsRecordExists;
		procedure ExportTableToSQL;
	public
		property CursorID: TACRObjectID read FCursorID;
		property LocalCursor: TACRLocalCursor read FLocalCursor;
		property Session: TACRServerSession read FSession;
		property Query: TACRQuery read FQuery;
		property ForcedDestroy: Boolean read FForcedDestroy write FForcedDestroy;
	end; // TACRServer

function InstallingService: Boolean;
function InteractiveService: Boolean;

implementation

{$IFDEF D6H}

uses
	Variants,
	ACRMemory // last
	;
{$ELSE}

uses ACRMemory; // last
{$ENDIF}
////////////////////////////////////////////////////////////////////////////////
//
// TACRServerNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerNetworkSettingsEditor.Create(Owner: TACRServerConnectParamsEditor);
begin
  FOwner := Owner;
  inherited Create;
  FServerReceiveTimeOut := ACRServerReceiveTimeOut;
  FServerReceiveSleep := ACRServerReceiveSleep;
  FMinServerSendTimeOut := ACRMinServerSendTimeOut;
  FServerSendTimeOut := ACRServerSendTimeOut;
  FServerWaitForSendSleep := ACRServerWaitForSendSleep;
  FServerResendDelay := ACRServerResendDelay;
  FServerRequestDelay := ACRServerRequestDelay;
  FWaitForMessagesSend := ACRWaitForMessagesSend;
  FWaitForServerSessionThreadTimeOut := ACRWaitForServerSessionThreadTimeOut;
  FServerThreadsTerminateDelay := ACRServerThreadsTerminateDelay;
  FServerSessionTerminatorSleep := ACRServerSessionTerminatorSleep;
  FPingCount := ACRPingCount;
  FWaitForPingAnswer := ACRWaitForPingAnswer;
  FPingClients := ACRPingClients;
  FServerPingSleep := ACRServerPingSleep;
  FKeepConnection := ACRKeepConnection;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerNetworkSettingsEditor.Destroy;
begin
inherited Destroy;
end; // Destroy

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRServerNetworkSettingsEditor.Assign(Source: TPersistent);
begin
 if (Source <> nil) then
	if (Source is TACRServerNetworkSettingsEditor) then
   begin
    inherited Assign(Source);
    FServerReceiveTimeOut := TACRServerNetworkSettingsEditor(Source).ServerReceiveTimeOut;
    FServerReceiveSleep := TACRServerNetworkSettingsEditor(Source).ServerReceiveSleep;
    FMinServerSendTimeOut := TACRServerNetworkSettingsEditor(Source).MinServerSendTimeOut;
    FServerSendTimeOut := TACRServerNetworkSettingsEditor(Source).ServerSendTimeOut;
    FServerWaitForSendSleep := TACRServerNetworkSettingsEditor(Source).ServerWaitForSendSleep;
    FServerResendDelay := TACRServerNetworkSettingsEditor(Source).ServerResendDelay;
    FServerRequestDelay := TACRServerNetworkSettingsEditor(Source).ServerRequestDelay;
    FWaitForMessagesSend := TACRServerNetworkSettingsEditor(Source).WaitForMessagesSend;
    FWaitForServerSessionThreadTimeOut := TACRServerNetworkSettingsEditor(Source).WaitForServerSessionThreadTimeOut;
    FServerThreadsTerminateDelay := TACRServerNetworkSettingsEditor(Source).ServerThreadsTerminateDelay;
    FServerSessionTerminatorSleep := TACRServerNetworkSettingsEditor(Source).ServerSessionTerminatorSleep;
    FPingClients := TACRServerNetworkSettingsEditor(Source).PingClients;
    FPingCount := TACRServerNetworkSettingsEditor(Source).PingCount;
    FWaitForPingAnswer := TACRServerNetworkSettingsEditor(Source).WaitForPingAnswer;
    FServerPingSleep := TACRServerNetworkSettingsEditor(Source).ServerPingSleep;
    FKeepConnection := TACRServerNetworkSettingsEditor(Source).KeepConnection;
   end;
end; // Assign

//------------------------------------------------------------------------------
// Copy ServerNetwork settings to ConnectParams
//------------------------------------------------------------------------------
procedure TACRServerNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TACRConnectParams);
begin
  inherited CopySettingsToConnectParams(ConnectParams);
  if (ConnectParams.Protocol = 1) then // according to client request
   begin // UDP
    ConnectParams.PacketSize := FUDP.PacketSize;
    ConnectParams.ConnectionParamsTunning := FUDP.ConnectionParamsTunning;
    ConnectParams.TestPacketCount := FUDP.TestPacketCount;
   end
  else // TCP
   begin
    ConnectParams.PacketSize := FTCP.PacketSize;
   end;
  ConnectParams.ServerReceiveTimeOut := FServerReceiveTimeOut;
  ConnectParams.ServerReceiveSleep := FServerReceiveSleep;
  ConnectParams.MinServerSendTimeOut := FMinServerSendTimeOut;
  ConnectParams.ServerSendTimeOut := FServerSendTimeOut;
  ConnectParams.ServerWaitForSendSleep := FServerWaitForSendSleep;
  ConnectParams.ServerResendDelay := FServerResendDelay;
  ConnectParams.ServerRequestDelay := FServerRequestDelay;
  ConnectParams.WaitForMessagesSend := FWaitForMessagesSend;
  ConnectParams.WaitForServerSessionThreadTimeOut := FWaitForServerSessionThreadTimeOut;
  ConnectParams.ServerThreadsTerminateDelay := FServerThreadsTerminateDelay;
  ConnectParams.ServerSessionTerminatorSleep := FServerSessionTerminatorSleep;
  ConnectParams.PingClients := FPingClients;
  ConnectParams.PingCount := FPingCount;
  ConnectParams.WaitForPingAnswer := FWaitForPingAnswer;
  ConnectParams.ServerPingSleep := FServerPingSleep;
  ConnectParams.KeepConnection := FKeepConnection;
end; // CopySettingsToConnectParams

//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TACRServerNetworkSettingsEditor.SetDefaultSettings(Value: TACRDefaultNetworkSettings);
begin
//  if Value = RestoreDefaultSettings then Exit; // in v.6.00B2
  case Value of
   ACRLocal:
    begin
    FServerReceiveTimeOut := ACRLocalServerReceiveTimeOut;
    FServerReceiveSleep := ACRServerReceiveSleep;
    FMinServerSendTimeOut := ACRLocalMinServerSendTimeOut;
    FServerSendTimeOut := ACRLocalServerSendTimeOut;
    FServerWaitForSendSleep := ACRServerWaitForSendSleep;
    FServerResendDelay := ACRLocalServerResendDelay;
    FServerRequestDelay := ACRLocalServerRequestDelay;
    FWaitForMessagesSend := ACRLocalWaitForMessagesSend;
    FWaitForServerSessionThreadTimeOut := ACRWaitForServerSessionThreadTimeOut;
    FServerThreadsTerminateDelay := ACRServerThreadsTerminateDelay;
    FServerSessionTerminatorSleep := ACRServerSessionTerminatorSleep;
    FPingCount := ACRLocalPingCount;
    FWaitForPingAnswer := ACRLocalWaitForPingAnswer;
    FPingClients := ACRPingClients;
    FServerPingSleep := ACRServerPingSleep;
    FKeepConnection := ACRKeepConnection;
    end;
   ACRLAN:
    begin
    FServerReceiveTimeOut := ACRServerReceiveTimeOut;
    FServerReceiveSleep := ACRServerReceiveSleep;
    FMinServerSendTimeOut := ACRMinServerSendTimeOut;
    FServerSendTimeOut := ACRServerSendTimeOut;
    FServerWaitForSendSleep := ACRServerWaitForSendSleep;
    FServerResendDelay := ACRServerResendDelay;
    FServerRequestDelay := ACRServerRequestDelay;
    FWaitForMessagesSend := ACRWaitForMessagesSend;
    FWaitForServerSessionThreadTimeOut := ACRWaitForServerSessionThreadTimeOut;
    FServerThreadsTerminateDelay := ACRServerThreadsTerminateDelay;
    FServerSessionTerminatorSleep := ACRServerSessionTerminatorSleep;
    FPingCount := ACRPingCount;
    FWaitForPingAnswer := ACRWaitForPingAnswer;
    FPingClients := ACRPingClients;
    FServerPingSleep := ACRServerPingSleep;
    FKeepConnection := ACRKeepConnection;
    end;
   ACRWAN:
    begin
    FServerReceiveTimeOut := ACRWANServerReceiveTimeOut;
    FServerReceiveSleep := ACRServerReceiveSleep;
    FMinServerSendTimeOut := ACRWANMinServerSendTimeOut;
    FServerSendTimeOut := ACRWANServerSendTimeOut;
    FServerWaitForSendSleep := ACRServerWaitForSendSleep;
    FServerResendDelay := ACRWANServerResendDelay;
    FServerRequestDelay := ACRWANServerRequestDelay;
    FWaitForMessagesSend := ACRWANWaitForMessagesSend;
    FWaitForServerSessionThreadTimeOut := ACRWaitForServerSessionThreadTimeOut;
    FServerThreadsTerminateDelay := ACRServerThreadsTerminateDelay;
    FServerSessionTerminatorSleep := ACRServerSessionTerminatorSleep;
    FPingCount := ACRWANPingCount;
    FWaitForPingAnswer := ACRWANWaitForPingAnswer;
    FPingClients := ACRPingClients;
    FServerPingSleep := ACRServerPingSleep;
    FKeepConnection := ACRKeepConnection;
    end;
   ACRModem:
    begin
    FServerReceiveTimeOut := ACRModemServerReceiveTimeOut;
    FServerReceiveSleep := ACRServerReceiveSleep;
    FMinServerSendTimeOut := ACRModemMinServerSendTimeOut;
    FServerSendTimeOut := ACRModemServerSendTimeOut;
    FServerWaitForSendSleep := ACRServerWaitForSendSleep;
    FServerResendDelay := ACRModemServerResendDelay;
    FServerRequestDelay := ACRModemServerRequestDelay;
    FWaitForMessagesSend := ACRModemWaitForMessagesSend;
    FWaitForServerSessionThreadTimeOut := ACRWaitForServerSessionThreadTimeOut;
    FServerThreadsTerminateDelay := ACRServerThreadsTerminateDelay;
    FServerSessionTerminatorSleep := ACRServerSessionTerminatorSleep;
    FPingCount := ACRModemPingCount;
    FWaitForPingAnswer := ACRModemWaitForPingAnswer;
    FPingClients := ACRPingClients;
    FServerPingSleep := ACRServerPingSleep;
    FKeepConnection := ACRKeepConnection;
    end;
  end;
  inherited SetDefaultSettings(Value);
end; // SetDefaultSettings



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRServerConnectParamsEditor.Create;
begin
  inherited Create;
//  FServer := TACRServer(Owner);
  FNetworkSettings := TACRServerNetworkSettingsEditor.Create(Self);
  Protocol := ACRDefaultServerProtocol;
  FLocalPort := ACRDefaultServerPort;
  LocalPortTCP := ACRDefaultServerPortTCP;
  LocalPortUDP := ACRDefaultServerPort;
end;//Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerConnectParamsEditor.Destroy;
begin
  FNetworkSettings.Free;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRServerConnectParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
	  if (Source is TACRConnectionParamsEditor) then
     begin
      inherited Assign(Source);
      FNetworkSettings.Assign(TACRServerConnectParamsEditor(Source).NetworkSettings);
      Protocol := TACRServerConnectParamsEditor(Source).Protocol;
      LocalPort := TACRServerConnectParamsEditor(Source).LocalPort;
	   end;
end; // Assign

//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TACRServerConnectParamsEditor.GetConnectParams: TACRConnectParams;
begin
  Result := inherited GetConnectParams;
  FNetworkSettings.CopySettingsToConnectParams(Result);
end; // GetConnectParams

//------------------------------------------------------------------------------
// SetProtocol
//------------------------------------------------------------------------------
procedure TACRServerConnectParamsEditor.SetProtocol(Value: TACRServerProtocol);
begin
  if Value = FProtocol then
    Exit;
  FProtocol := Value;
{$IFDEF RELEASE_BUILD}
  if NetworkSettings.FUDP <> nil then FreeAndNil(NetworkSettings.FUDP);
  if NetworkSettings.FTCP <> nil then FreeAndNil(NetworkSettings.FTCP);
{$ENDIF}
  if (FProtocol = acrsUDP) or (FProtocol = acrsTCPandUDP) then
   begin
    if NetworkSettings.FUDP = nil then
      NetworkSettings.FUDP := TACRNetworkSettingsUDPEditor.Create(NetworkSettings);
   end;
  if (FProtocol = acrsTCP) or (FProtocol = acrsTCPandUDP) then
   begin
    if NetworkSettings.FTCP = nil then
      NetworkSettings.FTCP := TACRNetworkSettingsTCPEditor.Create(NetworkSettings);
   end;
end; // SetProtocol

//------------------------------------------------------------------------------
// SetLocalPort
//------------------------------------------------------------------------------
procedure TACRServerConnectParamsEditor.SetLocalPort(Value: Cardinal);
// compatibility with old UDP only component
begin
  if Value = FLocalPort then
    Exit;
  if NetworkSettings.FUDP <> nil then
    NetworkSettings.FUDP.LocalPort := Value
  else
  if NetworkSettings.FTCP <> nil then
    NetworkSettings.FTCP.LocalPort := Value;
end; // SetLocalPort

//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TACRServerConnectParamsEditor.GetLocalPort: Cardinal;
// compatibility with old UDP only component
begin
  Result := 0;
  if NetworkSettings.FUDP <> nil then
    Result := NetworkSettings.FUDP.LocalPort
  else
   if NetworkSettings.FTCP <> nil then
     Result := NetworkSettings.FTCP.LocalPort;
end; // GetLocalPort

//------------------------------------------------------------------------------
// SetLocalPortTCP
//------------------------------------------------------------------------------
procedure TACRServerConnectParamsEditor.SetLocalPortTCP(Value: Cardinal);
// compatibility with old TCP only server
begin
  if NetworkSettings.FTCP <> nil then
   begin
    if Value <> NetworkSettings.FTCP.LocalPort then
      NetworkSettings.FTCP.LocalPort := Value;
   end;
end; // SetLocalPortTCP

//------------------------------------------------------------------------------
// GetLocalPortTCP
//------------------------------------------------------------------------------
function TACRServerConnectParamsEditor.GetLocalPortTCP: Cardinal;
// compatibility with old TCP only server
begin
  Result := 0;
  if NetworkSettings.FTCP <> nil then
    Result := NetworkSettings.FTCP.LocalPort;
end; // GetLocalPortTCP

//------------------------------------------------------------------------------
// SetLocalPortUDP
//------------------------------------------------------------------------------
procedure TACRServerConnectParamsEditor.SetLocalPortUDP(Value: Cardinal);
// compatibility with old UDP only server
begin
  if NetworkSettings.FUDP <> nil then
   begin
    if Value <> NetworkSettings.FUDP.LocalPort then
      NetworkSettings.FUDP.LocalPort := Value;
   end;
end; // SetLocalPortUDP

//------------------------------------------------------------------------------
// GetLocalPortUDP
//------------------------------------------------------------------------------
function TACRServerConnectParamsEditor.GetLocalPortUDP: Cardinal;
// compatibility with old UDP only server
begin
  Result := 0;
  if NetworkSettings.FUDP <> nil then
    Result := NetworkSettings.FUDP.LocalPort;
end; // GetLocalPortUDP

////////////////////////////////////////////////////////////////////////////////
//
// TACRServer
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// retunr number of databases in this server
//------------------------------------------------------------------------------
function TACRServer.GetDatabaseCount: Integer;
begin
Result := FDatabaseNames.Count;
end; // GetDatabaseCount

//------------------------------------------------------------------------------
// start server
//------------------------------------------------------------------------------
procedure TACRServer.StartServer;
begin
  if (not FActive) then
   begin
    if (Assigned(FBeforeServerStart)) then
      FBeforeServerStart(Self);
    LoadServerSettings;
    FConnectionManager := TACRServerConnectionManager.Create(Self, ConnectionParams.Protocol);
    FActive := True;
    if (Assigned(FAfterServerStart)) then
      FAfterServerStart(Self);
   end;
end; // StartServer

//------------------------------------------------------------------------------
// stop server
//------------------------------------------------------------------------------
procedure TACRServer.StopServer;
begin
if (FActive) then
begin
if (Assigned(FBeforeServerStop)) then
	FBeforeServerStop(Self);
FConnectionManager.Free;
FConnectionManager := nil;
FActive := False;
if (Assigned(FAfterServerStop)) then
	FAfterServerStop(Self);
end;
end; // StopServer;

//------------------------------------------------------------------------------
// do on sql
//------------------------------------------------------------------------------
procedure TACRServer.DoOnSQL(ClientInfo: TACRClientInfo; Params: TACRSQLParams;
	var SQL: WideString; var Abort: Boolean);
begin
Abort := False;
if (Assigned(FOnSQL)) then
	FOnSQL(Self,ClientInfo,Params,SQL,Abort);
end; // DoOnSQL

//------------------------------------------------------------------------------
// Do before insert record
//------------------------------------------------------------------------------
procedure TACRServer.DoBeforeInsertRecord(Sender: TObject;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
	var Abort: Boolean);
begin
if (Assigned(FBeforeInsertRecord)) then
	FBeforeInsertRecord(Sender,ClientInfo,LocalDatabase,TableName,FieldValues,
		Abort);
end; // DoBeforeInsertRecord

//------------------------------------------------------------------------------
// Do after insert record
//------------------------------------------------------------------------------
procedure TACRServer.DoAfterInsertRecord(Sender: TObject;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant);
begin
if (Assigned(FAfterInsertRecord)) then
	FAfterInsertRecord(Sender,ClientInfo,LocalDatabase,TableName,FieldValues);
end; // DoAfterInsertRecord

//------------------------------------------------------------------------------
// Do before Update record
//------------------------------------------------------------------------------
procedure TACRServer.DoBeforeUpdateRecord(Sender: TObject;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
	const TableName: WideString; const OldFieldValues: TACRArrayOfTACRVariant;
	const NewFieldValues: TACRArrayOfTACRVariant; var Abort: Boolean);
begin
if (Assigned(FBeforeUpdateRecord)) then
	FBeforeUpdateRecord(Sender,ClientInfo,LocalDatabase,TableName, OldFieldValues,
		NewFieldValues,Abort);
end; // DoBeforeUpdateRecord

//------------------------------------------------------------------------------
// Do after Update record
//------------------------------------------------------------------------------
procedure TACRServer.DoAfterUpdateRecord(Sender: TObject;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
	const TableName: WideString; const OldFieldValues: TACRArrayOfTACRVariant;
	const NewFieldValues: TACRArrayOfTACRVariant);
begin
if (Assigned(FAfterUpdateRecord)) then
	FAfterUpdateRecord(Sender,ClientInfo,LocalDatabase,TableName, OldFieldValues,
		NewFieldValues);
end; // DoAfterUpdateRecord

//------------------------------------------------------------------------------
// do before delete
//------------------------------------------------------------------------------
procedure TACRServer.DoBeforeDeleteRecord(Sender: TObject;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
	var Abort: Boolean);
begin
if (Assigned(FBeforeDeleteRecord)) then
	FBeforeDeleteRecord(Sender,ClientInfo,LocalDatabase,TableName,FieldValues,
		Abort);
end; // DoBeforeDeleteRecord

//------------------------------------------------------------------------------
// do after delete
//------------------------------------------------------------------------------
procedure TACRServer.DoAfterDeleteRecord(Sender: TObject;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant);
begin
if (Assigned(FAfterDeleteRecord)) then
	FAfterDeleteRecord(Sender,ClientInfo,LocalDatabase,TableName,FieldValues);
end; // DoAfterDeleteRecord

//------------------------------------------------------------------------------
// do before execute SQL
//------------------------------------------------------------------------------
procedure TACRServer.DoBeforeExecuteSQL(Sender: TACRQuery;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase; var Abort: Boolean);
begin
if (Assigned(FBeforeExecuteSQL)) then
	FBeforeExecuteSQL(Sender,ClientInfo,LocalDatabase,Abort);
end; // DoBeforeExecuteSQL

//------------------------------------------------------------------------------
// do after execute SQL
//------------------------------------------------------------------------------
procedure TACRServer.DoAfterExecuteSQL(Sender: TACRQuery;
	ClientInfo: TACRClientInfo; LocalDatabase: TACRDatabase);
begin
if (Assigned(FAfterExecuteSQL)) then
	FAfterExecuteSQL(Sender,ClientInfo,LocalDatabase);
end; // DoAfterExecuteSQL

//------------------------------------------------------------------------------
// Do on error
//------------------------------------------------------------------------------
procedure TACRServer.DoOnConnectionError(const ErrorCode: Integer;
	const NativeError: Integer; const ErrorMessage: AnsiString);
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog(
	'==================================================================');
aaWriteToLog('Error in ACRConnection module. TACRServer.DoOnConnectionError.');
aaWriteToLog(
	'------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage:"'+ErrorMessage+'"');
aaWriteToLog(
	'==================================================================');
{$ENDIF}
DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnError

//------------------------------------------------------------------------------
// Do on error
//------------------------------------------------------------------------------
procedure TACRServer.DoOnError(const ErrorCode: Integer;
	const NativeError: Integer; const ErrorMessage: AnsiString);
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog(
	'==================================================================');
aaWriteToLog('Error in ACRConnection module. TACRServer.DoOnError.');
aaWriteToLog(
	'------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage:"'+ErrorMessage+'"');
aaWriteToLog(
	'==================================================================');
{$ENDIF}
if (Assigned(FOnError)) then
	FOnError(Self,ErrorCode,NativeError,ErrorMessage);
end; // DoOnError

//------------------------------------------------------------------------------
// load default settings;
//------------------------------------------------------------------------------
procedure TACRServer.LoadDefaultSettings;
begin
if (UseConfigFile) then
	if (not ACRFileExists(FConfigFileName)) then
		SaveSettingsToConfigFile;
end; // LoadDefaultSettings

//------------------------------------------------------------------------------
// load server settings from config file
//------------------------------------------------------------------------------
procedure TACRServer.LoadSettingsFromConfigFile;
const
	NetworkCaption = 'Server Network Settings';
const
	ClientNetworkCaption = 'Client Network Settings';
var
	IniFile: TIniFile;
	i,n: Integer;
	s: AnsiString;
	FileName: AnsiString;
	CryptoParams: TACRCryptoParams;
begin
  // ini file cannot be created without full path
if (ExtractFilePath(FConfigFileName) <> '') then
	FileName := FConfigFileName
else
	FileName := ExtractFilePath(ParamStr(0))+ FConfigFileName;
FDatabaseNames.Clear;
FDatabaseFileNames.Clear;
IniFile := TIniFile.Create(FileName);
try
    // connection params
	LocalHost := IniFile.ReadString('Server Connection Parameters','LocalHost',LocalHost);
	LocalPort := IniFile.ReadInteger('Server Connection Parameters','LocalPort',LocalPort);
	ServerID := IniFile.ReadInteger('Server Connection Parameters','ServerID',ServerID);
  NetworkSettings.PacketSize := IniFile.ReadInteger('Server Connection Parameters','PacketSize',NetworkSettings.PacketSize); // compatibility with old UDP only component
	NetworkSettings.ServerRequestDelay := IniFile.ReadInteger('Server Connection Parameters','ServerReceiveDelay',NetworkSettings.ServerRequestDelay);
	NetworkSettings.ServerResendDelay := IniFile.ReadInteger('Server Connection Parameters','ServerResendRequestDelay',NetworkSettings.ServerResendDelay);
	NetworkSettings.DisconnectRetryCount := IniFile.ReadInteger('Server Connection Parameters','ServerDisconnectRetryCount',NetworkSettings.DisconnectRetryCount);
	NetworkSettings.DisconnectDelay := IniFile.ReadInteger('Server Connection Parameters','ServerDisconnectDelay',NetworkSettings.DisconnectDelay);
    // crypto parameters
	CryptoParams := Self.CryptoParams.GetCryptoParams;
	CryptoParams.CryptoAlgorithm := IniFile.ReadInteger('Server Crypto Parameters','CryptoAlgorithm',CryptoParams.CryptoAlgorithm);
	CryptoParams.CryptoMode := IniFile.ReadInteger('Server Crypto Parameters','CryptoMode',CryptoParams.CryptoMode);
	CryptoParams.Password := IniFile.ReadString('Server Crypto Parameters','Password',CryptoParams.Password);
	CryptoParams.UseInitVector := IniFile.ReadBool('Server Crypto Parameters','UseInitVector',CryptoParams.UseInitVector);
	if (CryptoParams.UseInitVector) then
		for i := 0 to High(CryptoParams.InitVector) do
			CryptoParams.InitVector[i] := IniFile.ReadInteger
				('Server Crypto Parameters','InitVector'+IntToStr(i),CryptoParams.InitVector[i]);
	if ((CryptoParams.Password = '') and
			(CryptoParams.CryptoAlgorithm <> acr_Cipher_None)) then
	 begin
    CryptoParams.KeyInfo.KeySize := IniFile.ReadInteger('Server Crypto Parameters','KeySize',
                                                        CryptoParams.KeyInfo.KeySize);
    for i := 0 to CryptoParams.KeyInfo.KeySize do
      CryptoParams.KeyInfo.Key[i] := IniFile.ReadInteger('Server Crypto Parameters','Key'+IntToStr(i),
                                                         CryptoParams.KeyInfo.Key[i]);
   end;
	Self.CryptoParams.SetCryptoParams(CryptoParams);
    // server databases
	n := IniFile.ReadInteger('Server Databases','DatabaseCount',0);
	for i := 0 to n - 1 do
   begin
    s := IniFile.ReadString('Database '+IntToStr(i+1),'DatabaseName','');
    FDatabaseNames.Add(s);
    s := IniFile.ReadString('Database '+IntToStr(i+1),'DatabaseFileName','');
    FDatabaseFileNames.Add(s);
	 end;
    // database access params
	FOpenDatabasesInExclusiveMode := IniFile.ReadBool('Server Database Access Parameters', 'OpenDatabasesInExclusiveMode',FOpenDatabasesInExclusiveMode);
	FLockParams.RetryCount := IniFile.ReadInteger('Server Database Access Parameters','LockParamsRetryCount',FLockParams.RetryCount);
	FLockParams.Delay := IniFile.ReadInteger('Server Database Access Parameters','LockParamsDelay',FLockParams.Delay);
    // network settings
  s := IniFile.ReadString('Server Connection Parameters','Protocol','UDP');
  if (s = 'TCP') then ConnectionParams.Protocol := acrsTCP;
  if (s = 'UDP') then ConnectionParams.Protocol := acrsUDP;
  if (s = 'TCP and UDP') then ConnectionParams.Protocol := acrsTCPandUDP;
  if (ConnectionParams.Protocol = acrsTCP) or (ConnectionParams.Protocol = acrsTCPandUDP) then
    if NetworkSettings.FTCP <> nil then
     begin
      NetworkSettings.FTCP.PacketSize := IniFile.ReadInteger('TCP Settings','PacketSizeTCP',NetworkSettings.FTCP.PacketSize);
     end;
  if (ConnectionParams.Protocol = acrsUDP) or (ConnectionParams.Protocol = acrsTCPandUDP) then
   begin
    if NetworkSettings.FUDP <> nil then
     begin
      NetworkSettings.FUDP.PacketSize := IniFile.ReadInteger('UDP Settings','PacketSizeUDP',NetworkSettings.FUDP.PacketSize);
      NetworkSettings.FUDP.ConnectionParamsTunning := IniFile.ReadBool('UDP Settings','ConnectionParamsTunning',NetworkSettings.FUDP.ConnectionParamsTunning);
      NetworkSettings.FUDP.TestPacketCount := IniFile.ReadInteger('UDP Settings','TestPacketCount',NetworkSettings.FUDP.TestPacketCount);
     end
   end;
	NetworkSettings.MaxThreadCount := IniFile.ReadInteger(NetworkCaption,
		'MaxThreadCount',NetworkSettings.MaxThreadCount);
	NetworkSettings.MinServerSendTimeOut := IniFile.ReadInteger(NetworkCaption,
		'MinSendTimeOut',NetworkSettings.MinServerSendTimeOut);
	NetworkSettings.DisconnectRetryCount := IniFile.ReadInteger(NetworkCaption,
		'DisconnectRetryCount',NetworkSettings.DisconnectRetryCount);
	NetworkSettings.DisconnectDelay := IniFile.ReadInteger(NetworkCaption,
		'DisconnectDelay',NetworkSettings.DisconnectDelay);
	NetworkSettings.ServerReceiveTimeOut := IniFile.ReadInteger(NetworkCaption,
		'ServerReceiveTimeOut',NetworkSettings.ServerReceiveTimeOut);
	NetworkSettings.ServerReceiveSleep := IniFile.ReadInteger(NetworkCaption,
		'ServerReceiveSleep',NetworkSettings.ServerReceiveSleep);
	NetworkSettings.MinServerSendTimeOut := IniFile.ReadInteger(NetworkCaption,
		'MinServerSendTimeOut',NetworkSettings.MinServerSendTimeOut);
	NetworkSettings.ServerSendTimeOut := IniFile.ReadInteger(NetworkCaption,
		'ServerSendTimeOut',NetworkSettings.ServerSendTimeOut);
	NetworkSettings.ServerResendDelay := IniFile.ReadInteger(NetworkCaption,
		'ServerResendDelay',NetworkSettings.ServerResendDelay);
	NetworkSettings.ServerRequestDelay := IniFile.ReadInteger(NetworkCaption,
		'ServerRequestDelay',NetworkSettings.ServerRequestDelay);
	NetworkSettings.WaitForMessagesSend := IniFile.ReadInteger(NetworkCaption,
		'WaitForMessagesSend',NetworkSettings.WaitForMessagesSend);
	NetworkSettings.ServerThreadsTerminateDelay := IniFile.ReadInteger
		(NetworkCaption,'ServerThreadsTerminateDelay',
		NetworkSettings.ServerThreadsTerminateDelay);
	NetworkSettings.ServerSessionTerminatorSleep := IniFile.ReadInteger
		(NetworkCaption,'ServerSessionTerminatorSleep',
		NetworkSettings.ServerSessionTerminatorSleep);
	NetworkSettings.WaitForPingAnswer := IniFile.ReadInteger(NetworkCaption,
		'WaitForPingAnswer',NetworkSettings.WaitForPingAnswer);
	NetworkSettings.ServerPingSleep := IniFile.ReadInteger(NetworkCaption,
		'ServerPingSleep',NetworkSettings.ServerPingSleep);
    // client network settings
	NetworkSettings.StartReceiveTimeOut := IniFile.ReadInteger
		(ClientNetworkCaption,'StartReceiveTimeOut',
		NetworkSettings.StartReceiveTimeOut);
	NetworkSettings.ReceiveTimeOut := IniFile.ReadInteger(ClientNetworkCaption,
		'ReceiveTimeOut',NetworkSettings.ReceiveTimeOut);
	NetworkSettings.ReceiveSleep := IniFile.ReadInteger(ClientNetworkCaption,
		'ReceiveSleep',NetworkSettings.ReceiveSleep);
	NetworkSettings.MinSendTimeOut := IniFile.ReadInteger(ClientNetworkCaption,
		'MinSendTimeOut',NetworkSettings.MinSendTimeOut);
	NetworkSettings.SendTimeOut := IniFile.ReadInteger(ClientNetworkCaption,
		'SendTimeOut',NetworkSettings.SendTimeOut);
	NetworkSettings.WaitForSendSleep := IniFile.ReadInteger(ClientNetworkCaption,
		'WaitForSendSleep',NetworkSettings.WaitForSendSleep);
	NetworkSettings.ResendDelay := IniFile.ReadInteger(ClientNetworkCaption,
		'ResendDelay',NetworkSettings.ResendDelay);
	NetworkSettings.RequestDelay := IniFile.ReadInteger(ClientNetworkCaption,
		'RequestDelay',NetworkSettings.RequestDelay);
	NetworkSettings.WaitForTimeOut := IniFile.ReadInteger(ClientNetworkCaption,
		'WaitForTimeOut',NetworkSettings.WaitForTimeOut);
	NetworkSettings.ThreadsTerminateDelay := IniFile.ReadInteger
		(ClientNetworkCaption,'ThreadsTerminateDelay',
		NetworkSettings.ThreadsTerminateDelay);
    // Server Configuration
	FMaxCommandExecutionTime := IniFile.ReadInteger('Server Configuration',
		'MaxCommandExecutionTime',FMaxCommandExecutionTime);
finally
	IniFile.Free;
end;
if (Length(CryptoParams.Password) > 0) then
	FillChar(CryptoParams.Password[1],Length(CryptoParams.Password),$FF);
SetLength(CryptoParams.Password,0);
FillChar(CryptoParams,SizeOf(CryptoParams),$00);
end; // LoadSettingsFromConfigFile

//------------------------------------------------------------------------------
// SaveSettingsToConfigFile
//------------------------------------------------------------------------------
procedure TACRServer.SaveSettingsToConfigFile;
const
	NetworkCaption = 'Server Network Settings';
const
	ClientNetworkCaption = 'Client Network Settings';
var
	IniFile: TIniFile;
	i: Integer;
	FileName: AnsiString;
	CryptoParams: TACRCryptoParams;
begin
if (not UseConfigFile) then
	Exit;
  // ini file cannot be created without full path
if (ExtractFilePath(FConfigFileName) <> '') then
	FileName := FConfigFileName
else
	FileName := ExtractFilePath(ParamStr(0))+ FConfigFileName;
if (ACRFileExists(FileName)) then
	SysUtils.DeleteFile(FileName);
IniFile := TIniFile.Create(FileName);
try
    // connection params
  case ConnectionParams.Protocol of
   acrsTCP:
  	IniFile.WriteString('Server Connection Parameters','Protocol','TCP');
   acrsUDP:
  	IniFile.WriteString('Server Connection Parameters','Protocol','UDP');
   acrsTCPandUDP:
  	IniFile.WriteString('Server Connection Parameters','Protocol','TCP and UDP');
  end;
	IniFile.WriteString('Server Connection Parameters','LocalHost',ConnectionParams.LocalHost);
	IniFile.WriteInteger('Server Connection Parameters','LocalPortTCP',ConnectionParams.LocalPortTCP);
	IniFile.WriteInteger('Server Connection Parameters','LocalPortUDP',ConnectionParams.LocalPortUDP);
	IniFile.WriteInteger('Server Connection Parameters','ServerID',ConnectionParams.ServerID);
    // crypto parameters
	CryptoParams := Self.CryptoParams.GetCryptoParams;
	IniFile.WriteInteger('Server Crypto Parameters','CryptoAlgorithm',
		CryptoParams.CryptoAlgorithm);
	IniFile.WriteInteger('Server Crypto Parameters','CryptoMode',
		CryptoParams.CryptoMode);
	IniFile.WriteString('Server Crypto Parameters','Password',
		CryptoParams.Password);
	IniFile.WriteBool('Server Crypto Parameters','UseInitVector',
		CryptoParams.UseInitVector);
	if (CryptoParams.UseInitVector) then
		for i := 0 to High(CryptoParams.InitVector) do
			IniFile.WriteInteger('Server Crypto Parameters','InitVector'+IntToStr(i),
				CryptoParams.InitVector[i]);
	if ((CryptoParams.Password = '') and
			(CryptoParams.CryptoAlgorithm <> acr_Cipher_None)) then
	begin
	IniFile.WriteInteger('Server Crypto Parameters','KeySize',
		CryptoParams.KeyInfo.KeySize);
	for i := 0 to CryptoParams.KeyInfo.KeySize do
		IniFile.WriteInteger('Server Crypto Parameters','Key'+IntToStr(i),
			CryptoParams.KeyInfo.Key[i]);
	end;
    // server databases
	IniFile.WriteInteger('Server Databases','DatabaseCount',DatabaseCount);
	for i := 0 to DatabaseCount - 1 do
	begin
	IniFile.WriteString('Database '+IntToStr(i+1),'DatabaseName',
		FDatabaseNames.Strings[i]);
	IniFile.WriteString('Database '+IntToStr(i+1),'DatabaseFileName',
		FDatabaseFileNames.Strings[i]);
	end;
    // database access params
	IniFile.WriteBool('Server Database Access Parameters',
		'OpenDatabasesInExclusiveMode',FOpenDatabasesInExclusiveMode);
	IniFile.WriteInteger('Server Database Access Parameters',
		'LockParamsRetryCount',FLockParams.RetryCount);
	IniFile.WriteInteger('Server Database Access Parameters','LockParamsDelay',
		FLockParams.Delay);
    // network settings
  if (ConnectionParams.Protocol = acrsUDP) or (ConnectionParams.Protocol = acrsTCPandUDP) then
   begin
    if NetworkSettings.FUDP <> nil then
     begin
      IniFile.WriteInteger('UDP Settings','PacketSize',NetworkSettings.FUDP.PacketSize);
      IniFile.WriteBool('UDP Settings','ConnectionParamsTunning',NetworkSettings.FUDP.ConnectionParamsTunning);
      IniFile.WriteInteger('UDP Settings','TestPacketCount',NetworkSettings.FUDP.TestPacketCount);
     end
   end;
  if (ConnectionParams.Protocol = acrsTCP) or (ConnectionParams.Protocol = acrsTCPandUDP) then
    if NetworkSettings.FTCP <> nil then
     begin
      IniFile.WriteInteger('TCP Settings','PacketSize',NetworkSettings.FTCP.PacketSize);
     end;
	IniFile.WriteInteger(NetworkCaption,'MaxThreadCount',
		NetworkSettings.MaxThreadCount);
	IniFile.WriteBool(NetworkCaption,'ConnectionParamsTunning',
		NetworkSettings.FUDP.ConnectionParamsTunning);
	IniFile.WriteInteger(NetworkCaption,'TestPacketCount',
		NetworkSettings.FUDP.TestPacketCount);
	IniFile.WriteInteger(NetworkCaption,'MinSendTimeOut',
		NetworkSettings.MinServerSendTimeOut);
	IniFile.WriteInteger(NetworkCaption,'DisconnectRetryCount',
		NetworkSettings.DisconnectRetryCount);
	IniFile.WriteInteger(NetworkCaption,'DisconnectDelay',
		NetworkSettings.DisconnectDelay);
	IniFile.WriteInteger(NetworkCaption,'ServerReceiveTimeOut',
		NetworkSettings.ServerReceiveTimeOut);
	IniFile.WriteInteger(NetworkCaption,'ServerReceiveSleep',
		NetworkSettings.ServerReceiveSleep);
	IniFile.WriteInteger(NetworkCaption,'MinServerSendTimeOut',
		NetworkSettings.MinServerSendTimeOut);
	IniFile.WriteInteger(NetworkCaption,'ServerSendTimeOut',
		NetworkSettings.ServerSendTimeOut);
	IniFile.WriteInteger(NetworkCaption,'ServerResendDelay',
		NetworkSettings.ServerResendDelay);
	IniFile.WriteInteger(NetworkCaption,'ServerRequestDelay',
		NetworkSettings.ServerRequestDelay);
	IniFile.WriteInteger(NetworkCaption,'WaitForMessagesSend',
		NetworkSettings.WaitForMessagesSend);
	IniFile.WriteInteger(NetworkCaption,'ServerThreadsTerminateDelay',
		NetworkSettings.ServerThreadsTerminateDelay);
	IniFile.WriteInteger(NetworkCaption,'ServerSessionTerminatorSleep',
		NetworkSettings.ServerSessionTerminatorSleep);
	IniFile.WriteInteger(NetworkCaption,'WaitForPingAnswer',
		NetworkSettings.WaitForPingAnswer);
	IniFile.WriteInteger(NetworkCaption,'ServerPingSleep',
		NetworkSettings.ServerPingSleep);
    // client network settings
	IniFile.WriteInteger(ClientNetworkCaption,'StartReceiveTimeOut',
		NetworkSettings.StartReceiveTimeOut);
	IniFile.WriteInteger(ClientNetworkCaption,'ReceiveTimeOut',
		NetworkSettings.ReceiveTimeOut);
	IniFile.WriteInteger(ClientNetworkCaption,'ReceiveSleep',
		NetworkSettings.ReceiveSleep);
	IniFile.WriteInteger(ClientNetworkCaption,'MinSendTimeOut',
		NetworkSettings.MinSendTimeOut);
	IniFile.WriteInteger(ClientNetworkCaption,'SendTimeOut',
		NetworkSettings.SendTimeOut);
	IniFile.WriteInteger(ClientNetworkCaption,'WaitForSendSleep',
		NetworkSettings.WaitForSendSleep);
	IniFile.WriteInteger(ClientNetworkCaption,'ResendDelay',
		NetworkSettings.ResendDelay);
	IniFile.WriteInteger(ClientNetworkCaption,'RequestDelay',
		NetworkSettings.RequestDelay);
	IniFile.WriteInteger(ClientNetworkCaption,'WaitForTimeOut',
		NetworkSettings.WaitForTimeOut);
	IniFile.WriteInteger(ClientNetworkCaption,'ThreadsTerminateDelay',
		NetworkSettings.ThreadsTerminateDelay);
    // Server Configuration
	IniFile.WriteInteger('Server Configuration','MaxCommandExecutionTime',
		FMaxCommandExecutionTime);
	IniFile.UpdateFile;
finally
	IniFile.Free;
end;
end; // SaveSettingsToConfigFile

//------------------------------------------------------------------------------
// load server settings from ini file or set them to default
//------------------------------------------------------------------------------
procedure TACRServer.LoadServerSettings;
begin
  if (not ACRFileExists(FConfigFileName)) then
    LoadDefaultSettings
  else
    if (UseConfigFile) then
      LoadSettingsFromConfigFile;
end; // LoadServerSettings

//------------------------------------------------------------------------------
// CryptoParams
//------------------------------------------------------------------------------
procedure TACRServer.SetCryptoParams(CryptoParams: TACRCryptoParamsEditor);
begin
  FConnectionParams.CryptoParams := CryptoParams;
end;

function TACRServer.GetCryptoParams: TACRCryptoParamsEditor;
begin
  Result := FConnectionParams.CryptoParams;
end;

//------------------------------------------------------------------------------
// NetworkSettings
//------------------------------------------------------------------------------
procedure TACRServer.SetNetworkSettings(NetworkSettings
		: TACRServerNetworkSettingsEditor);
begin
  FConnectionParams.FNetworkSettings := NetworkSettings;
end;

function TACRServer.GetNetworkSettings: TACRServerNetworkSettingsEditor;
begin
  Result := FConnectionParams.NetworkSettings;
end;

//------------------------------------------------------------------------------
// LocalHost
//------------------------------------------------------------------------------
procedure TACRServer.SetLocalHost(Host: AnsiString);
begin
FConnectionParams.LocalHost := Host
end;

function TACRServer.GetLocalHost: AnsiString;
begin
  Result := FConnectionParams.LocalHost;
end;

//------------------------------------------------------------------------------
// LocalPort
//------------------------------------------------------------------------------
procedure TACRServer.SetLocalPort(Port: Integer);
begin
  FConnectionParams.LocalPort := Port;
end;

function TACRServer.GetLocalPort: Integer;
begin
  Result := FConnectionParams.LocalPort;
end;

//------------------------------------------------------------------------------
// ServerID
//------------------------------------------------------------------------------
procedure TACRServer.SetServerID(ID: Integer);
begin
  FConnectionParams.ServerID := ID;
end;

function TACRServer.GetServerID: Integer;
begin
  Result := FConnectionParams.ServerID;
end;

//------------------------------------------------------------------------------
// return current version
//------------------------------------------------------------------------------
function TACRServer.GetCurrentVersion: AnsiString;
var
	c : Char;
begin
{$IFDEF D17H}
  c := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := '.';
  try
    Result := FloatToStrF(ACRVersion,ffFixed,3,2) + ' ' + ACRVersionText;
  finally
    FormatSettings.DecimalSeparator := c;
  end;
{$ELSE}
  c := DecimalSeparator;
  DecimalSeparator := '.';
  try
    Result := FloatToStrF(ACRVersion,ffFixed,3,2) + ' ' + ACRVersionText;
  finally
    DecimalSeparator := c;
  end;
{$ENDIF}
end; // GetCurrentVersion

//------------------------------------------------------------------------------
// active
//------------------------------------------------------------------------------
procedure TACRServer.SetActive(Value: Boolean);
begin
if (Value <> FActive) then
begin
if (Value) then
	StartServer
else
	StopServer;
end;
end; // SetActive

//------------------------------------------------------------------------------
// set database names
//------------------------------------------------------------------------------
procedure TACRServer.SetDatabaseNames(Value: TStrings);
begin
  FDatabaseNames.Assign(Value);
end; // SetDatabaseFileNames

//------------------------------------------------------------------------------
// set database filenames
//------------------------------------------------------------------------------
procedure TACRServer.SetDatabaseFileNames(Value: TStrings);
begin
  FDatabaseFileNames.Assign(Value);
end; // SetDatabaseFileNames

//------------------------------------------------------------------------------
// get client session
//------------------------------------------------------------------------------
function TACRServer.GetClientSession(const Client: TACRClientInfo)
	: TACRServerSession;
var
	ClientSessions: TACRSessionsArray;
	i: Integer;
begin
  Result := nil;
  FConnectionManager.GetClientsList(ClientSessions);
  if (Length(ClientSessions) > 0) then
    for i := Low(ClientSessions) to High(ClientSessions) do
      if (ClientSessions[i].SessionID = Client.SessionID) then
      begin
      Result := TACRServerSession(ClientSessions[i]);
      break;
      end;
  ClientSessions := nil;
end; // GetClientSession

//------------------------------------------------------------------------------
// receive custom message from client
//------------------------------------------------------------------------------
procedure TACRServer.ReceiveMessage(ServerSession: TACRServerSession;
	Buffer: PAnsiChar; Size: Integer);
var
	MessageType: TACRMessageType;
	ms,ms1: TACRMemoryStream;
	Text: AnsiString;
	WideText: WideString;
	len: Integer;
	ClientInfo: TACRClientInfo;
	Buf: PAnsiChar;
	StreamSize: Int64;
begin
  ClientInfo := ServerSession.GetClientInfo;
  ms := TACRMemoryStream.Create(Buffer);
  try
    LoadDataFromStream(MessageType,SizeOf(MessageType),ms,11376);
    case MessageType of
    aamtText:
    if (Assigned(FOnReceiveTextMessage)) then
    begin
    LoadDataFromStream(len,SizeOf(len),ms,11377);
    SetLength(Text,len);
    if (len > 0) then
      LoadDataFromStream(PAnsiChar(@Text[1])^,len,ms,11378);
    FOnReceiveTextMessage(ClientInfo,Text);
    end;
    aamtUnicodeText:
    if (Assigned(FOnReceiveUnicodeTextMessage)) then
    begin
    LoadDataFromStream(len,SizeOf(len),ms,11721);
    SetLength(WideText,len);
    if (len > 0) then
      LoadDataFromStream(PAnsiChar(@WideText[1])^,len,ms,11722);
    FOnReceiveUnicodeTextMessage(ClientInfo,WideText);
    end;
    aamtBinary:
    if (Assigned(FOnReceiveBinaryMessage)) then
    begin
    LoadDataFromStream(len,SizeOf(len),ms,11379);
    if (len > 0) then
    begin
    Buf := MemoryManager.GetMem(len);
    try
      LoadDataFromStream(Buf^,len,ms,11380);
      FOnReceiveBinaryMessage(ClientInfo,Buf,len);
    finally
      MemoryManager.FreeAndNilMem(Buf);
    end;
    end
    else
      FOnReceiveBinaryMessage(ClientInfo,nil,len);
    end;
    aamtStream:
    if (Assigned(FOnReceiveStreamMessage)) then
    begin
    ms1 := TACRMemoryStream.Create;
    try
      LoadDataFromStream(StreamSize,SizeOf(StreamSize),ms,11381);
      if (StreamSize > 0) then
        ms1.LoadFromStreamWithPosition(ms,ms.Position,StreamSize);
      FOnReceiveStreamMessage(ClientInfo,ms1);
    finally
      ms1.Free;
    end;
    end;
    end;
  finally
    ms.Free;
  end;
end; // ReceiveMessage

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRServer.Create(AOwner: TComponent);
begin
  FUseConfigFile := True;
  FConfigFileName := ACRDefaultServerConfigFileName;
  FActive := False;
  FDatabaseNames := TStringList.Create;
  FDatabaseFileNames := TStringList.Create;
  FDatabaseNames.Add(ACRDefaultDBName);
  FDatabaseFileNames.Add(ACRDefaultDBFileName);
  FConnectionManager := nil;
  FLockParams.RetryCount := ACRDefaultServerLockRetryCount;
  FLockParams.Delay := ACRDefaultServerLockDelay;
  FConnectionParams := TACRServerConnectParamsEditor.Create;
  (*
    FCryptoParams := TACRCryptoParamsEditor.Create;
    FNetworkSettings := TACRServerNetworkSettingsEditor.Create;
    FLocalHost := ACRDefaultServerHost;
    FLocalPort := ACRDefaultServerPort;
    FServerID := ACRDefaultServerID;
  *)
  FMaxCommandExecutionTime := ACRDefaultMaxCommandExecutionTime;
  NetworkSettings.StartReceiveTimeOut := FMaxCommandExecutionTime * 1000; // msec
  FOpenDatabasesInExclusiveMode := True;
  inherited;
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRServer.Destroy;
begin
  Active := False;
  FDatabaseNames.Free;
  FDatabaseFileNames.Free;
  FConnectionParams.Free;
  (*
   FCryptoParams.Free;
   FNetworkSettings.Free;
  *)
  if (FConnectionManager <> nil) then
  begin
  FConnectionManager.Free;
  FConnectionManager := nil;
  end;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// returns -1 if database was not found, otherwise index in FDatabaseNames (FDatabaseFileNames)
//------------------------------------------------------------------------------
function TACRServer.FindDatabaseByName(Name: AnsiString): Integer;
var
	DBName: AnsiString;
begin
  DBName := AnsiUpperCase(Name);
  Result := FDatabaseNames.IndexOf(DBName);
end; // FindDatabaseByName

//------------------------------------------------------------------------------
// fills array with client info
//------------------------------------------------------------------------------
procedure TACRServer.GetClients(var Clients: TACRClientInfoArray);
var
	ClientSessions: TACRSessionsArray;
	i,l: Integer;
begin
  FConnectionManager.GetClientsList(ClientSessions);
  l := Length(ClientSessions);
  SetLength(Clients,l);
  if (l > 0) then
    for i := Low(ClientSessions) to High(ClientSessions) do
      Clients[i] := TACRServerSession(ClientSessions[i]).GetClientInfo;
  ClientSessions := nil;
end; // GetClients

//------------------------------------------------------------------------------
// return true if client is still connected to server
//------------------------------------------------------------------------------
function TACRServer.IsClientConnected(const Client: TACRClientInfo): Boolean;
begin
  Result := (GetClientSession(Client) <> nil);
end; // IsClientConnected

//------------------------------------------------------------------------------
// disconnect client by Host:Port
//------------------------------------------------------------------------------
procedure TACRServer.Disconnect(const Host: AnsiString; const Port: Integer);
begin
  ConnectionManager.DisconnectClient(Host, Port);
end; // Disconnect

//------------------------------------------------------------------------------
// disconnect client by SessionID
//------------------------------------------------------------------------------
procedure TACRServer.Disconnect(const SessionID: Integer);
begin
  ConnectionManager.DisconnectClient(SessionID);
end; // Disconnect

//------------------------------------------------------------------------------
// Send text message
//------------------------------------------------------------------------------
procedure TACRServer.SendMessage(const Client: TACRClientInfo;
	const Text: AnsiString);
var
	ClientSession: TACRServerSession;
	ms: TACRMemoryStream;
	MessageType: TACRMessageType;
	len: Integer;
begin
  ClientSession := GetClientSession(Client);
  if (ClientSession = nil) then
    raise EACRException.Create(11250,ErrorLClientIsNotConnected);
  MessageType := aamtText;
  len := Length(Text);
  ms := TACRMemoryStream.Create();
  try
    SaveDataToStream(MessageType,SizeOf(MessageType),ms,11253);
    SaveDataToStream(len,SizeOf(len),ms,11254);
    if (len > 0) then
      SaveDataToStream(PAnsiChar(@Text[1])^,len,ms,11255);
    ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
end; // SendMessage

//------------------------------------------------------------------------------
// Send Unicode text message
//------------------------------------------------------------------------------
procedure TACRServer.SendMessage(const Client: TACRClientInfo;
	const Text: WideString);
var
	ClientSession: TACRServerSession;
	ms: TACRMemoryStream;
	MessageType: TACRMessageType;
	len: Integer;
begin
  ClientSession := GetClientSession(Client);
  if (ClientSession = nil) then
    raise EACRException.Create(11715,ErrorLClientIsNotConnected);
  MessageType := aamtUnicodeText;
  len := Length(Text);
  ms := TACRMemoryStream.Create();
  try
    SaveDataToStream(MessageType,SizeOf(MessageType),ms,11716);
    SaveDataToStream(len,SizeOf(len),ms,11717);
    if (len > 0) then
      SaveDataToStream(PAnsiChar(@Text[1])^,len,ms,11718);
    ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
end; // SendMessage

//------------------------------------------------------------------------------
// Send binary message
//------------------------------------------------------------------------------
procedure TACRServer.SendMessage(const Client: TACRClientInfo;
	Buffer: PAnsiChar; Size: Integer);
var
	ClientSession: TACRServerSession;
	ms: TACRMemoryStream;
	MessageType: TACRMessageType;
begin
  ClientSession := GetClientSession(Client);
  if (ClientSession = nil) then
    raise EACRException.Create(11251,ErrorLClientIsNotConnected);
  MessageType := aamtBinary;
  ms := TACRMemoryStream.Create();
  try
    SaveDataToStream(MessageType,SizeOf(MessageType),ms,11256);
    SaveDataToStream(Size,SizeOf(Size),ms,11257);
    if (Size > 0) then
      SaveDataToStream(Buffer^,Size,ms,11258);
    ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
end; // SendMessage

//------------------------------------------------------------------------------
// Send stream
//------------------------------------------------------------------------------
procedure TACRServer.SendMessage(const Client: TACRClientInfo; Stream: TStream);
var
	ClientSession: TACRServerSession;
	ms: TACRMemoryStream;
	MessageType: TACRMessageType;
	Size: Int64;
begin
  ClientSession := GetClientSession(Client);
  if (ClientSession = nil) then
    raise EACRException.Create(11252,ErrorLClientIsNotConnected);
  MessageType := aamtStream;
  Size := Stream.Size;
  ms := TACRMemoryStream.Create();
  try
    SaveDataToStream(MessageType,SizeOf(MessageType),ms,11259);
    SaveDataToStream(Size,SizeOf(Size),ms,11260);
    if (Size > 0) then
    begin
    if (Stream is TACRStream) then
      TACRStream(Stream).SaveToStream(ms)
    else
      ms.CopyFrom(Stream,Size);
    end;
    ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
end; // SendMessage

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSession
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get error message and raises an excpetion
//------------------------------------------------------------------------------
procedure TACRServerSession.SendErrorMessage(ErrorCode: Integer;
	ErrorMessage: WideString);
var
	len: Integer;
begin
FSentCommandHeader.Reply := accrplOperationFailed;
FSentCommandDataStream.Size := 0;
SaveDataToStream(ErrorCode,SizeOf(ErrorCode),FSentCommandDataStream,10863);
SaveWideStringToStream(ErrorMessage,FSentCommandDataStream,10864);
SendCommand;
end; // SendErrorMessage

//------------------------------------------------------------------------------
// find server cursor by id
//------------------------------------------------------------------------------
function TACRServerSession.FindServerCursor(CursorID: TACRObjectID)
	: TACRServerCursor;
var
	i: Integer;
begin
Result := nil;
for i := 0 to FCursorList.Count - 1 do
	if (TACRServerCursor(FCursorList.Items[i]).CursorID = CursorID) then
	begin
	Result := FCursorList.Items[i];
	break;
	end;
end; // FindServerCursor

//------------------------------------------------------------------------------
// send vsisiblefielddefs.fieldnoreference
//------------------------------------------------------------------------------
procedure TACRServerSession.SendFieldNoReferences(aCursor: TACRLocalCursor);
var
	i,num: Integer;
begin
for i := 0 to aCursor.VisibleFieldDefs.Count - 1 do
begin
num := aCursor.VisibleFieldDefs.Items[i].FieldNoReference;
SaveDataToStream(num,SizeOf(num),FSentCommandDataStream,11185);
end;
end; // SendFieldNoReferences

//------------------------------------------------------------------------------
// create server cursor, put information about it to FSentCommandDataStream and add it to the CursorList
//------------------------------------------------------------------------------
function TACRServerSession.CreateServerCursor(aCursor: TACRLocalCursor;
	aQuery: TACRQuery = nil): TACRServerCursor;
var
	LocalCursor: TACRLocalCursor;
	b: Byte;
	IndexID: TACRObjectID;
begin
LocalCursor := aCursor;
Inc(FLastCursorID);
  // create server cursor and add it to cursor list of this server session
Result := TACRServerCursor.Create(LocalCursor,FLastCursorID,Self,aQuery);
FCursorList.Add(Result);
SaveDataToStream(FLastCursorID,SizeOf(FLastCursorID),FSentCommandDataStream,
	10968);
SaveWideStringToStream(LocalCursor.FComment,FSentCommandDataStream,11960);
LocalCursor.FieldDefs.SaveToStream(FSentCommandDataStream);
LocalCursor.VisibleFieldDefs.SaveToStream(FSentCommandDataStream);
LocalCursor.IndexDefs.SaveToStream(FSentCommandDataStream);
LocalCursor.ConstraintDefs.SaveToStream(FSentCommandDataStream);
if (aQuery <> nil) then
	b := 1
else
	b := 0;
  // is cursor query or table
SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,11592);
if (b = 1) then
begin
IndexID := aCursor.IndexID;
SaveDataToStream(IndexID,SizeOf(IndexID),FSentCommandDataStream,11593);
end;
Result.CreateOldNewFieldValues;
if (aQuery <> nil) then
	SendFieldNoReferences(LocalCursor);
end; // CreateServerCursor

//------------------------------------------------------------------------------
// receive SQL Params
//------------------------------------------------------------------------------
function TACRServerSession.ReceiveParams(FQuery: TACRQuery): Boolean;
var
	b: ByteBool;
begin
LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,11691);
Result := b;
if (Result) then
	TACRQuery(FQuery).StmtHandle.SQLParams.LoadFromStream
		(FReceivedCommandDataStream);
end; // SendNotLiveQuery

//------------------------------------------------------------------------------
// send live query
//------------------------------------------------------------------------------
procedure TACRServerSession.SendLiveQuery(FQuery: TACRQuery;
	LocalCursor: TACRLocalCursor);
begin
CreateServerCursor(LocalCursor,FQuery);
end; // SendNotLiveQuery

//------------------------------------------------------------------------------
// send not live query
//------------------------------------------------------------------------------
procedure TACRServerSession.SendNotLiveQuery(FQuery: TACRQuery;
	LocalCursor: TACRLocalCursor);
var
	b: Byte;
	tempTable: TACRTable;
	s: AnsiString;
begin
if (not LocalCursor.IsTemporaryTable) then
begin
    // disk / memory table returned by SELECT INTO
tempTable := TACRTable.Create(nil);
try
	tempTable.Temporary := True;
	tempTable.FieldDefs.Clear;
	tempTable.AdvIndexDefs.Clear;
	tempTable.ForeignKeyDefs.Clear;
	ConvertACRIndexDefsToIndexDefs(LocalCursor.IndexDefs,tempTable.IndexDefs);
	tempTable.IndexDefs.Assign(FQuery.IndexDefs);
	ConvertACRFieldDefsToAdvFieldDefs(LocalCursor.VisibleFieldDefs,
		LocalCursor.FieldDefs, LocalCursor.ConstraintDefs,tempTable.AdvFieldDefs);
	tempTable.CreateTable;
	tempTable.Open;
	s := ACRCopyCursors(LocalCursor,tempTable.Handle);
	if (s <> '') then
		raise EACRException.Create(11670,ErrorLCannotCopyCursors,[s]);
	tempTable.Handle.SaveTableToStream(FSentCommandDataStream,acaNone,0,0,True);
finally
	tempTable.Free;
end;
end
else
	LocalCursor.SaveTableToStream(FSentCommandDataStream,acaNone,0,0,True);
if (LocalCursor.FIsProjectionSet) then
	b := 1
else
	b := 0;
SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,11620);
if (b = 1) then
begin
LocalCursor.FVisibleFieldDefs.SaveToStream(FSentCommandDataStream);
SendFieldNoReferences(LocalCursor);
end;
//  LocalCursor.SaveProjectionToStream(Stream);
end; // SendNotLiveQuery

//------------------------------------------------------------------------------
// remove query from the list of parametrized queries
//------------------------------------------------------------------------------
procedure TACRServerSession.RemoveQueryFromQueryList(FQuery: TACRQuery);
var
	idx: Integer;
begin
idx := FQueryList.IndexOf(FQuery);
if (idx >= 0) then
	FQueryList.Delete(idx);
end; // RemoveQueryFromQueryList

//------------------------------------------------------------------------------
// db connected?
//------------------------------------------------------------------------------
function TACRServerSession.GetConnected: Boolean;
begin
Result := (FDatabase <> nil);
end; // GetConnected

//------------------------------------------------------------------------------
// before insert record
//------------------------------------------------------------------------------
procedure TACRServerSession.DoBeforeInsertRecord(Sender: TACRDataSet;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
	var Abort: Boolean);
begin
FServer.DoBeforeInsertRecord(Sender,GetClientInfo,FDatabase,TableName,
	FieldValues,Abort);
end; // DoBeforeInsertRecord

//------------------------------------------------------------------------------
// after insert record
//------------------------------------------------------------------------------
procedure TACRServerSession.DoAfterInsertRecord(Sender: TACRDataSet;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant);
begin
FServer.DoAfterInsertRecord(Sender,GetClientInfo,FDatabase,TableName,
	FieldValues);
end; // DoAfterUpdateRecord

//------------------------------------------------------------------------------
// before update record
//------------------------------------------------------------------------------
procedure TACRServerSession.DoBeforeUpdateRecord(Sender: TACRDataSet;
	const TableName: WideString;
	const OldFieldValues: TACRArrayOfTACRVariant;
	const NewFieldValues: TACRArrayOfTACRVariant; var Abort: Boolean);
begin
FServer.DoBeforeUpdateRecord(Sender,GetClientInfo,FDatabase,TableName,
	OldFieldValues,NewFieldValues,Abort);
end; // DoAfterUpdateRecord

//------------------------------------------------------------------------------
// after update record
//------------------------------------------------------------------------------
procedure TACRServerSession.DoAfterUpdateRecord(Sender: TACRDataSet;
	const TableName: WideString;
	const OldFieldValues: TACRArrayOfTACRVariant;
	const NewFieldValues: TACRArrayOfTACRVariant);
begin
FServer.DoAfterUpdateRecord(Sender,GetClientInfo,FDatabase,TableName,
	OldFieldValues,NewFieldValues);
end; // DoAfterUpdateRecord

//------------------------------------------------------------------------------
// do before delete
//------------------------------------------------------------------------------
procedure TACRServerSession.DoBeforeDeleteRecord(Sender: TACRDataSet;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant;
	var Abort: Boolean);
begin
FServer.DoBeforeDeleteRecord(Sender,GetClientInfo,FDatabase,TableName,
	FieldValues,Abort);
end; // DoAfterDeleteRecord

//------------------------------------------------------------------------------
// do after delete
//------------------------------------------------------------------------------
procedure TACRServerSession.DoAfterDeleteRecord(Sender: TACRDataSet;
	const TableName: WideString; const FieldValues: TACRArrayOfTACRVariant);
begin
FServer.DoAfterDeleteRecord(Sender,GetClientInfo,FDatabase,TableName,
	FieldValues);
end; // DoAfterDeleteRecord

//------------------------------------------------------------------------------
// do before execute SQL
//------------------------------------------------------------------------------
procedure TACRServerSession.DoBeforeExecuteSQL(Sender: TACRQuery;
	var Abort: Boolean);
begin
FServer.DoBeforeExecuteSQL(Sender,GetClientInfo,FDatabase,Abort);
end; // DoBeforeExecuteSQL

//------------------------------------------------------------------------------
// do after execute SQL
//------------------------------------------------------------------------------
procedure TACRServerSession.DoAfterExecuteSQL(Sender: TACRQuery);
begin
FServer.DoAfterExecuteSQL(Sender,GetClientInfo,FDatabase);
end; // DoAfterExecuteSQL

//------------------------------------------------------------------------------
// Before insert record assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsBeforeInsertRecordAssigned: Boolean;
begin
Result := Assigned(FServer.BeforeInsertRecord);
end; // IsBeforeInsertRecordAssigned

//------------------------------------------------------------------------------
// After insert record assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsAfterInsertRecordAssigned: Boolean;
begin
Result := Assigned(FServer.AfterInsertRecord);
end; // IsAfterInsertRecordAssigned

//------------------------------------------------------------------------------
// Before update record assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsBeforeUpdateRecordAssigned: Boolean;
begin
Result := Assigned(FServer.BeforeUpdateRecord);
end; // IsBeforeUpdateRecordAssigned

//------------------------------------------------------------------------------
// After update record assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsAfterUpdateRecordAssigned: Boolean;
begin
Result := Assigned(FServer.AfterUpdateRecord);
end; // IsAfterUpdateRecordAssigned

//------------------------------------------------------------------------------
// Before delete record assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsBeforeDeleteRecordAssigned: Boolean;
begin
Result := Assigned(FServer.BeforeDeleteRecord);
end; // IsBeforeDeleteRecordAssigned

//------------------------------------------------------------------------------
// After delete record assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsAfterDeleteRecordAssigned: Boolean;
begin
Result := Assigned(FServer.AfterDeleteRecord);
end; // IsAfterDeleteRecordAssigned

//------------------------------------------------------------------------------
// Before execute SQL assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsBeforeExecuteSQLAssigned: Boolean;
begin
Result := Assigned(FServer.BeforeExecuteSQL);
end; // IsBeforeExecuteSQLAssigned

//------------------------------------------------------------------------------
// After execute SQL assigned
//------------------------------------------------------------------------------
function TACRServerSession.IsAfterExecuteSQLAssigned: Boolean;
begin
Result := Assigned(FServer.AfterExecuteSQL);
end; // IsAfterExecuteSQLAssigned

//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TACRServerSession.SetConnected(Value: Boolean);
var
	i: Integer;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+'Server start SetConnected SessionID = '+IntToStr
		(FSessionID)+ ', DatabaseName = '+FDatabaseName+ ', Value = '+
		BoolToStr(Value,True)+ ', Connected = '+BoolToStr(GetConnected,True));
{$ENDIF}
if (Value <> GetConnected) then
begin
if (Value) then
begin
FCursorList.Clear;
if (FDatabase <> nil) then
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server SetConnected closing database ... SessionID = '+IntToStr
		(FSessionID)+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr
		(Value,True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
FreeAndNil(FDatabase);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server SetConnected database closed ... SessionID = '+IntToStr
		(FSessionID)+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr
		(Value,True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
end;
FDatabase := TACRDatabase.Create(nil);
try
	FDatabase.DatabaseFileName := Self.DatabaseFileName;
	FDatabase.DatabaseName := GetTemporaryName
		('ACRServerDBName'+'_'+IntToStr(SessionID));
	FDatabase.CryptoParams.SetCryptoParams(Self.CryptoParams);
	FDatabase.LockParams.SetLockParams(FServer.LockParams);
	FDatabase.ReadOnly := False;
	FDatabase.Exclusive := FServer.OpenDatabasesInExclusiveMode;
  FDatabase.CaseInsensitive := FCaseInsensitive;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected opening database ... SessionID = '+IntToStr
			(FSessionID)+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr
			(Value,True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
	FDatabase.Open;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected database opened... SessionID = '+IntToStr
			(FSessionID)+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr
			(Value,True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
	FHandle := TACRLocalSession(FDatabase.Handle);
	Self.FOptions := FHandle.Options;
	Self.CryptoParams := FHandle.CryptoParams;
	if (IsBeforeInsertRecordAssigned) then
		FDatabase.BeforeInsertRecord := DoBeforeInsertRecord;
	if (IsAfterInsertRecordAssigned) then
		FDatabase.AfterInsertRecord := DoAfterInsertRecord;
	if (IsBeforeUpdateRecordAssigned) then
		FDatabase.BeforeUpdateRecord := DoBeforeUpdateRecord;
	if (IsAfterUpdateRecordAssigned) then
		FDatabase.AfterUpdateRecord := DoAfterUpdateRecord;
	if (IsBeforeDeleteRecordAssigned) then
		FDatabase.BeforeDeleteRecord := DoBeforeDeleteRecord;
	if (IsAfterDeleteRecordAssigned) then
		FDatabase.AfterDeleteRecord := DoAfterDeleteRecord;
except
	FreeAndNil(FDatabase);
	raise;
end;
end // Connect
else
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server SetConnected starting diconnect... SessionID = '+IntToStr
		(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
		+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr(Value,
		True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
if (FDatabase <> nil) then
begin
try
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected starting rollback... SessionID = '+IntToStr
			(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
			+ ', FDatabase.Connected = '+BoolToStr(FDatabase.Connected,
			True)+ ', DatabaseName = '+FDatabaseName+ ', InTransaction = '+BoolToStr
			(FDatabase.InTransaction,True)+ ', Value = '+BoolToStr(Value,
			True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
	if (FDatabase.InTransaction) then
		FDatabase.Rollback;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected rollback finished. SessionID = '+IntToStr
			(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
			+ ', DatabaseName = '+FDatabaseName+ ', InTransaction = '+BoolToStr
			(FDatabase.InTransaction,True)+ ', Value = '+BoolToStr(Value,
			True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
except
	on e: EACRException do
		DoOnError(ACR_CS_ErrorClosingServerSessionRollbackFailed,e.NativeError,
			Format(ErrorL_CS_ErrorClosingServerSessionRollbackFailed, [FSessionID,
				FDatabaseName,e.Message]));
	on e: Exception do
		DoOnError(ACR_CS_ErrorClosingServerSessionRollbackFailed,-1,
			Format(ErrorL_CS_ErrorClosingServerSessionRollbackFailed, [FSessionID,
				FDatabaseName,e.Message]))
	else
		DoOnError(ACR_CS_ErrorClosingServerSessionRollbackFailed,-1,
			Format(ErrorL_CS_ErrorClosingServerSessionRollbackFailed, [FSessionID,
				FDatabaseName,'']));
end;
try
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected starting remove all locks ... SessionID = '+
			IntToStr(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
			+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr(Value,
			True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
	FDatabase.RemoveAllLocks;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected remove all locks OK. SessionID = '+IntToStr
			(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
			+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr(Value,
			True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10);
{$ENDIF}
except
	on e: EACRException do
		DoOnError(ACR_CS_ErrorClosingServerSessionRemoveAllLocks,e.NativeError,
			Format(ErrorL_CS_ErrorClosingServerSessionRemoveAllLocks, [FSessionID,
				FDatabaseName,e.Message]));
	on e: Exception do
		DoOnError(ACR_CS_ErrorClosingServerSessionRollbackFailed,-1,
			Format(ErrorL_CS_ErrorClosingServerSessionRemoveAllLocks, [FSessionID,
				FDatabaseName,e.Message]))
	else
		DoOnError(ACR_CS_ErrorClosingServerSessionRollbackFailed,-1,
			Format(ErrorL_CS_ErrorClosingServerSessionRemoveAllLocks, [FSessionID,
				FDatabaseName,'']));
end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server SetConnected starting closing cursors ... SessionID = '+
		IntToStr(FSessionID)+ ', FCursorList.Count = '+IntToStr(FCursorList.Count)
		+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr(Value,
		True)+ ', Connected = '+BoolToStr(GetConnected,True));
{$ENDIF}
for i := 0 to FCursorList.Count - 1 do
	try
		if (FCursorList.Items[i] <> nil) then
		begin
		TACRServerCursor(FCursorList.Items[i]).ForcedDestroy := True;
		TACRServerCursor(FCursorList.Items[i]).Free;
		end;
	except
		on e: EACRException do
			DoOnError(ACR_CS_ErrorClosingServerSessionCursorsClosingFailed,
				e.NativeError, Format(
					ErrorL_CS_ErrorClosingServerSessionCursorsClosingFailed, [FSessionID,
					FDatabaseName,e.Message]));
		on e: Exception do
			DoOnError(ACR_CS_ErrorClosingServerSessionCursorsClosingFailed,-1,
				Format(ErrorL_CS_ErrorClosingServerSessionCursorsClosingFailed,
					[FSessionID,FDatabaseName,e.Message]))
		else
			DoOnError(ACR_CS_ErrorClosingServerSessionCursorsClosingFailed,-1,
				Format(ErrorL_CS_ErrorClosingServerSessionCursorsClosingFailed,
					[FSessionID,FDatabaseName,'']));
	end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server SetConnected cursors closed ... SessionID = '+IntToStr
		(FSessionID)+ ', FCursorList.Count = '+IntToStr(FCursorList.Count)
		+ ', DatabaseName = '+FDatabaseName+#13#10);
{$ENDIF}
try
	FCursorList.Clear;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected starting closing database ... SessionID = '+
			IntToStr(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
			+ ', FDatabase.Connected = '+BoolToStr(FDatabase.Connected,
			True)+ ', DatabaseName = '+FDatabaseName+#13#10);
{$ENDIF}
	FreeAndNil(FDatabase);
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('Server SetConnected database closed ... SessionID = '+IntToStr
			(FSessionID)+ ', FDatabase = '+IntToStr(Integer(FDatabase))
			+ ', DatabaseName = '+FDatabaseName+ #13#10);
{$ENDIF}
	FHandle := nil;
except
	on e: EACRException do
		DoOnError(ACR_CS_ErrorClosingServerSessionDestroyingDatabaseFailed,
			e.NativeError, Format(
				ErrorL_CS_ErrorClosingServerSessionCursorsClosingFailed, [FSessionID,
				FDatabaseName,e.Message]));
	on e: Exception do
		DoOnError(ACR_CS_ErrorClosingServerSessionDestroyingDatabaseFailed,-1,
			Format(ErrorL_CS_ErrorClosingServerSessionCursorsClosingFailed,
				[FSessionID,FDatabaseName,e.Message]))
	else
		DoOnError(ACR_CS_ErrorClosingServerSessionDestroyingDatabaseFailed,-1,
			Format(ErrorL_CS_ErrorClosingServerSessionCursorsClosingFailed,
				[FSessionID,FDatabaseName,'']));
end;
end;
end; // Disconnect
end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server finish SetConnected SessionID = '+IntToStr(FSessionID)
		+ ', DatabaseName = '+FDatabaseName+ ', Value = '+BoolToStr(Value,
		True)+ ', Connected = '+BoolToStr(GetConnected,True)+#13#10+#13#10);
{$ENDIF}
end; // SetConnected

//------------------------------------------------------------------------------
// check if database exists
//------------------------------------------------------------------------------
function TACRServerSession.GetDatabaseExists: Boolean;
begin
Result := False; // never used
end; // GetDatabaseExists

//------------------------------------------------------------------------------
// get tables list
//------------------------------------------------------------------------------
procedure TACRServerSession.GetTablesList(List: TACRWideStringList);
begin
FHandle.GetTablesList(List);
end; // GetTablesList

//------------------------------------------------------------------------------
// return true if table exists
//------------------------------------------------------------------------------
function TACRServerSession.TableExists(TableName: WideString): Boolean;
begin
Result := FHandle.TableExists(TableName);
end; // TableExists

//------------------------------------------------------------------------------
// return database format version
//------------------------------------------------------------------------------
function TACRServerSession.GetFormatVersion: Double;
begin
Result := FHandle.GetFormatVersion;
end; // GetFormatVersion

//------------------------------------------------------------------------------
// return total number of pages
//------------------------------------------------------------------------------
function TACRServerSession.GetTotalPageCount: Integer;
begin
Result := FHandle.GetTotalPageCount;
end; // GetTotalPageCount

//------------------------------------------------------------------------------
// return number of free pages
//------------------------------------------------------------------------------
function TACRServerSession.GetFreePageCount: Integer;
begin
Result := FHandle.GetFreePageCount;
end; // GetFreePageCount

//------------------------------------------------------------------------------
// return true if database is encrypted
//------------------------------------------------------------------------------
function TACRServerSession.IsDatabaseEncrypted: Boolean;
begin
Result := FHandle.IsDatabaseEncrypted;
end; // IsDatabaseEncrypted

//------------------------------------------------------------------------------
// return true if database is encrypted by password or by key
//------------------------------------------------------------------------------
function TACRServerSession.IsDatabaseEncryptedByPassword: Boolean;
begin
Result := FHandle.IsDatabaseEncryptedByPassword;
end; // IsDatabaseEncryptedByPassword

//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TACRServerSession.IsCryptoParamsValid: Boolean;
begin
FHandle.CryptoParams := FCryptoParams;
Result := FHandle.IsCryptoParamsValid;
end; // IsCryptoParamsValid

//------------------------------------------------------------------------------
// retrun true if database has active transaction
//------------------------------------------------------------------------------
function TACRServerSession.GetInTransaction: Boolean;
begin
Result := FHandle.InTransaction;
end; // GetInTransaction

//------------------------------------------------------------------------------
// start a transaction
//------------------------------------------------------------------------------
procedure TACRServerSession.StartTransaction;
begin
FHandle.StartTransaction;
end; // StartTransaction

//------------------------------------------------------------------------------
// apply changes made by transaction
//------------------------------------------------------------------------------
procedure TACRServerSession.Commit(FlushFileBuffers: Boolean = True);
begin
FHandle.Commit(FlushFileBuffers);
end; // Commit

//------------------------------------------------------------------------------
// cancel changes made by transaction
//------------------------------------------------------------------------------
procedure TACRServerSession.Rollback;
begin
FHandle.Rollback;
end; // Rollback

//------------------------------------------------------------------------------
// flush changes
//------------------------------------------------------------------------------
procedure TACRServerSession.FlushFileBuffers;
begin
FHandle.FlushFileBuffers;
end; // FlushFileBuffers

//------------------------------------------------------------------------------
// Back link to corresponding structure (PMsgSrvrSession) in ConnectionManager.Sessions
//------------------------------------------------------------------------------
procedure TACRServerSession.SetServerSession(Value: Pointer);
begin
FServerSession := Value;
end; // SetServerSession

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerSession.Create(aServer: TComponent);
begin
inherited Create;
FServer := TACRServer(aServer);
FHandle := nil;
FLastCursorID := 0;
FCursorList := TList.Create;
FDatabase := nil;
FServer.NetworkSettings.CopySettingsToConnectParams(FConnectParams);
FQueryList := TList.Create;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerSession.Destroy;
var
	i: Integer;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('ServerSession Destroy starting, SessionID = '+IntToStr(FSessionID)
	);
{$ENDIF}
SetConnected(False);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('ServerSession Destroy disconnected from database, SessionID = '+
		IntToStr(FSessionID));
{$ENDIF}
FCursorList.Free;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('ServerSession Destroy starting inherited, SessionID = '+IntToStr
		(FSessionID));
{$ENDIF}
for i := 0 to FQueryList.Count - 1 do
	try
		TACRQuery(FQueryList.Items[i]).Free;
	except
	end;
FQueryList.Free;
inherited Destroy;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('ServerSession Destroy finished, SessionID = '+IntToStr(FSessionID)
	);
{$ENDIF}
end; // Destroy

//------------------------------------------------------------------------------
// call OnError event handler
//------------------------------------------------------------------------------
procedure TACRServerSession.DoOnError(ErrorCode: Integer;
	NativeError: Integer = -1; ErrorMessage: AnsiString = '');
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog(
	'==================================================================');
aaWriteToLog('Error in TACRServerSession!');
aaWriteToLog('ClassName = '+Self.ClassName);
aaWriteToLog(
	'------------------------------------------------------------------');
aaWriteToLog('SessionID='+IntToStr(Integer(Self.SessionID)));
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage:"'+ErrorMessage+'"');
aaWriteToLog('GetTickCount = '+IntToStr(aaGetTickCount));
aaWriteToLog(
	'==================================================================');
{$ENDIF}
if (FServer <> nil) then
	FServer.DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnError

//------------------------------------------------------------------------------
// Send command error occured - session must be destroyed
//------------------------------------------------------------------------------
procedure TACRServerSession.DoCloseSessionOnNetworkError;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server DoCloseSessionOnNetworkError starting, SessionID = '+
		IntToStr(FSessionID));
{$ENDIF}
FServer.FConnectionManager.TerminateSession(Self);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('Server DoCloseSessionOnNetworkError finish, SessionID = '+IntToStr
		(FSessionID));
{$ENDIF}
end; // DoCloseSessionOnNetworkError

//------------------------------------------------------------------------------
// execute received command
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteReceivedCommand;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
aaIncCounter(counter1);
aaStartTime(time1);
{$ENDIF}
try
	case FReceivedCommandHeader.Request of
    accrqConnectDatabase:                   ExecuteConnectDatabase;
    accrqIsDatabaseExists:                  ExecuteIsDatabaseExists;
    accrqGetTablesList:                     ExecuteGetTablesList;
    accrqIsTableExists:                     ExecuteIsTableExists;
    accrqGetFormatVersion:                  ExecuteGetFormatVersion;
    accrqGetTotalPageCount:                 ExecuteGetTotalPageCount;
    accrqGetFreePageCount:                  ExecuteGetFreePageCount;
    accrqIsDatabaseEncrypted:               ExecuteIsDatabaseEncrypted;
    accrqIsDatabaseEncryptedByPassword:     ExecuteIsDatabaseEncryptedByPassword;
    accrqIsCryptoParamsValid:               ExecuteIsCryptoParamsValid;
    accrqIsInTransaction:                   ExecuteIsInTransaction;
    accrqStartTransaction:                  ExecuteStartTransaction;
    accrqCommit:                            ExecuteCommit;
    accrqRollback:                          ExecuteRollback;
    accrqCreateTable:                       ExecuteCreateTable;
    accrqDeleteTable:                       ExecuteDeleteTable;
    accrqEmptyTable:                        ExecuteEmptyTable;
    accrqRenameTable:                       ExecuteRenameTable;
    accrqRenameField:                       ExecuteRenameField;
    accrqOpenTable:                         ExecuteOpenTable;
    accrqCloseTable:                        ExecuteCloseTable;
    accrqAddIndex:                          ExecuteAddIndex;
    accrqDeleteIndex:                       ExecuteDeleteIndex;
    accrqDeleteAllIndexes:                  ExecuteDeleteAllIndexes;
    accrqGetRecordCount:                    ExecuteGetRecordCount;
    accrqGetRecordBuffer:                   ExecuteGetRecordBuffer;
    accrqSetRecNo:                          ExecuteSetRecNo;
  //     accrqGetRecNo:                       ExecuteGetRecNo;
    accrqInternalEdit:                      ExecuteInternalEdit;
    accrqInternalCancel:                    ExecuteInternalCancel;
    accrqInternalPost:                      ExecuteInternalPost;
    accrqInternalDelete:                    ExecuteInternalDelete;
    accrqActivateFilters:                   ExecuteActivateFilters;
    accrqDeactivateFilters:                 ExecuteDeactivateFilters;
    accrqLocate:                            ExecuteLocate;
    accrqFindKey:                           ExecuteFindKey;
    accrqResetRange:                        ExecuteResetRange;
    accrqApplyRange:                        ExecuteApplyRange;
    accrqReadBLOBValue:                     ExecuteReadBLOBValue;
    accrqExecSQL:                           ExecuteExecSQL;
    accrqSQLUnprepareParams:                ExecuteSQLUnprepareParams;
    accrqIsRecordExists:                    ExecuteIsRecordExists;
    accrqExportTableToSQL:                  ExecuteExportTableToSQL;
    accrqGetTablesInfo:                     ExecuteGetTablesInfo;
    accrqGetTableState:                     ExecuteGetTableState;
    accrqGetTableStateCursor:               ExecuteGetTableStateCursor;
    accrqGetTableComment:                   ExecuteGetTableComment;
    accrqSetTableComment:                   ExecuteSetTableComment;
    accrqExportDatabaseToSQL:               ExecuteExportDatabaseToSQL;
    accrqCreateStoredFunction:              ExecuteCreateStoredFunction;
    accrqDropStoredFunction:                ExecuteDropStoredFunction;
    accrqAlterStoredFunction:               ExecuteAlterStoredFunction;
    accrqAlterStoredFunctionRename:         ExecuteAlterStoredFunctionRename;
    accrqFindStoredFunction:                ExecuteFindStoredFunction;
    accrqGetStoredFunctions:                ExecuteGetStoredFunctions;
    accrqExportStoredFunctionsToSQL:        ExecuteExportStoredFunctionsToSQL;
    accrqClearCache:                        ExecuteClearCache;
    accrqFlushFileBuffers:                  ExecuteFlushFileBuffers;
    accrqLoadRecords:                       ExecuteLoadRecords;
    accrqSetCaseInsensitive:                ExecuteSetCaseInsensitive;
	end; // Request
finally
	FCommandReceived := False;
	FReceivedCommandDataStream.Size := 0;
	FSentCommandHeader.Request := FReceivedCommandHeader.Request;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
	aaStopTime(time1);
{$ENDIF}
end;
end; // ExecuteReceivedCommand


//------------------------------------------------------------------------------
// receive data from network and move it to ReceivedCommandHeader and ReceivedCommandDataStream
//------------------------------------------------------------------------------
procedure TACRServerSession.ReceiveData(Buffer: PAnsiChar; BufferSize: Integer);
begin
try
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
	aaIncCounter(counter3);
	aaStartTime(time3);
{$ENDIF}
	inherited ReceiveData(Buffer,BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
	aaStopTime(time3);
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog(#13#10+
			'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
	aaWriteToLog('S> ServerSession is starting to execute a received command...');
	aaWriteToLog('S> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr
			(FServer.ServerID));
	aaWriteToLog('S> Request = '+IntToStr(Integer(FReceivedCommandHeader.Request))
		);
	aaWriteBufferToLog(Buffer,BufferSize);
	aaWriteToLog('S> Execute Start Time = '+aaGetCurrentTimeAsString);
{$ENDIF}
finally
	if (Buffer <> nil) and (BufferSize > 0) then
		MemoryManager.FreeAndNilMem(Buffer);
end;
if (FCommandReceived) then
	ExecuteReceivedCommand
{$IFDEF LOG_SERVER_COMMAND_RETRY}
else
	aaWriteToLog(
		'TACRServerSession.ReceiveData> Error: Command is not received properly')
{$ENDIF}
	;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('S> Execute End Time = '+aaGetCurrentTimeAsString);
aaWriteToLog('S> End of Request = '+IntToStr
		(Integer(FReceivedCommandHeader.Request)));
aaWriteToLog('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+
		#13#10);
{$ENDIF}
end; // ReceiveData

function TACRServerSession.SendCommand: Boolean;
begin
try
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
	aaIncCounter(counter2);
	aaStartTime(time2);
{$ENDIF}
	Result := inherited SendCommand;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
	aaStopTime(time2);
	if (not Result) then
		aaIncCounter(counter6);
{$ENDIF}
except
	Result := False;
{$IFDEF LOG_SERVER_COMMAND_RETRY}
	aaWriteToLog(
		'TACRServerSession.ExecuteReceivedCommand> Error: Command is not sent off')
{$ENDIF}
  // DoCloseSessionOnNetworkError; -- Delete to enable a client to resend a command
  // -- Client closes session when it cannot receive answer for FConnectParams.CommandRetryCount
end;
end;

//------------------------------------------------------------------------------
// SendServerCommand
//------------------------------------------------------------------------------
procedure TACRServerSession.SendServerCommand(Buffer: PAnsiChar; Size: Integer);
var
	Buf: PAnsiChar;
	BufSize: Integer;
	Code: TACRControlCode;
begin
Code := ACRServerCommand;
BufSize := Size + SizeOf(Code);
Buf := MemoryManager.GetMem(BufSize);
try
	Move(Code, Buf^, SizeOf(Code));
	Move(Buffer^, (Buf + SizeOf(Code))^, Size);
	SendMessage(Buf,BufSize);
finally
	MemoryManager.FreeAndNilMem(Buf);
end;
end;// SendServerCommand

//------------------------------------------------------------------------------
// send buffer via established connection using connection manager
//------------------------------------------------------------------------------
procedure TACRServerSession.SendBuffer(var Buffer: PAnsiChar;
	BufferSize: Integer);
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+
		'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
aaWriteToLog('S> ServerSession is starting to send a reply...');
aaWriteToLog('S> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr
		(FServer.ServerID));
aaWriteToLog('S> Request = '+IntToStr(Integer(FSentCommandHeader.Request)));
aaWriteToLog('S> Reply = '+IntToStr(Integer(FSentCommandHeader.Reply)));
aaWriteBufferToLog(Buffer,BufferSize);
aaWriteToLog('S> Send Start Time = '+aaGetCurrentTimeAsString);
{$ENDIF}
FServer.ConnectionManager.SendBuffer(Self,Buffer,BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('S> Send End Time = '+aaGetCurrentTimeAsString);
aaWriteToLog('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+
		#13#10);
{$ENDIF}
end; // SendBuffer

//------------------------------------------------------------------------------
// send custom message
//------------------------------------------------------------------------------
procedure TACRServerSession.SendMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
FServer.ConnectionManager.SendMessage(Self,Buffer,BufferSize);
end; // SendMessage

//------------------------------------------------------------------------------
// receive custom message from client
//------------------------------------------------------------------------------
procedure TACRServerSession.ReceiveMessage(Buffer: PAnsiChar;
	BufferSize: Integer);
begin
  FServer.ReceiveMessage(Self,Buffer,BufferSize);
end; // ReceiveMessage


//------------------------------------------------------------------------------
// return client info
//------------------------------------------------------------------------------
function TACRServerSession.GetClientInfo: TACRClientInfo;
var
	Host,Application:   AnsiString;
	Port:               Integer;
  Protocol:           TACRClientProtocol;
begin
  FServer.ConnectionManager.GetClientInfo(Self,Protocol,Host,Port,Application);
  Result.Protocol := Protocol;
  Result.Host := Host;
  Result.Port := Port;
  Result.Application := Application;
  Result.DatabaseName := Self.DatabaseName;
  Result.DatabaseFileName := Self.DatabaseFileName;
  Result.SessionID := Self.SessionID;
end; // GetClientInfo


//------------------------------------------------------------------------------
// execute ConnectDatabase request
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteConnectDatabase;
var
	DBNumber: Integer;
	DBName:   AnsiString;
	b:        ByteBool;
begin
  try
    LoadAnsiStringFromStream(DBName,FReceivedCommandDataStream,10866);
    LoadDataFromStream(FMinCacheSize,SizeOf(FMinCacheSize),
      FReceivedCommandDataStream,12307);
    LoadDataFromStream(FMaxCacheSize,SizeOf(FMaxCacheSize),
      FReceivedCommandDataStream,12308);
    LoadCryptoParamsFromStream(FCryptoParams,FReceivedCommandDataStream,11316);
    // added in v.5.90
    LoadDataFromStream(b, SizeOf(b), FReceivedCommandDataStream, 12550);
    FCaseInsensitive := b;
  except
    on e: Exception do
    begin
    SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
      Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
  { TODO -oAlex : make it work!!! }
  //       FServer.ConnectionManager.TerminateSession(Self);
    Exit;
    end;
  end;
  FDatabaseName := DBName;
  DBNumber := FServer.FindDatabaseByName(DBName);
  if (DBNumber < 0) then
  begin
    SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
      Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
    { TODO -oAlex : make it work!!! }
    //    FServer.ConnectionManager.TerminateSession(Self);
    Exit;
  end
  else
  begin
    DatabaseFileName := FServer.DatabaseFileNames[DBNumber];
    try
      SetConnected(True);
      FSentCommandHeader.Request := accrqConnectDatabase;
      FSentCommandHeader.Reply := accrplOperationSucceed;
      FSentCommandDataStream.Size := 0;
      SaveDataToStream(FOptions,SizeOf(FOptions),FSentCommandDataStream,10869);
      b := FHandle.Exclusive;
      SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,11067);
    except
      on e: Exception do
      begin
       SendErrorMessage(ACR_CS_ErrorDatabaseFileCannotBeOpen,
         Format(ErrorL_CS_ErrorDatabaseFileCannotBeOpen,[e.Message]));
    { TODO -oAlex : make it work!!! }
    //      FServer.ConnectionManager.TerminateSession(Self);
      Exit;
      end;
    end;
    SendCommand;
  end;
end; // ExecuteConnectDatabase

//------------------------------------------------------------------------------
// execute IsDatabaseExists
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsDatabaseExists;
var
	len: Integer;
	DBName: AnsiString;
{$IFDEF DEBUG_LOG_COMMUNICATION_SHOW_CLIENT}
	str: AnsiString;
{$ENDIF}
begin
try
	LoadDataFromStream(len,SizeOf(len),FReceivedCommandDataStream,10875);
	SetLength(DBName,len);
	LoadDataFromStream(PAnsiChar(@DBName[1])^,len,FReceivedCommandDataStream,
		10876);
{$IFDEF DEBUG_LOG_COMMUNICATION_SHOW_CLIENT}
// DEBUG!!!
	LoadDataFromStream(len,SizeOf(len),FReceivedCommandDataStream,40875);
	SetLength(str,len);
	LoadDataFromStream(PAnsiChar(@str[1])^,len,FReceivedCommandDataStream,40876);
	aaWriteToLog('CLIENT-> '+str); // DEBUG!!!
{$ENDIF}
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqIsDatabaseExists;
SentCommandDataStream.Size := 0;
if (FServer.FindDatabaseByName(DBName) < 0) then
	FSentCommandHeader.Reply := accrplNo
else
	FSentCommandHeader.Reply := accrplYes;
{$IFDEF DEBUG_TRACE_TACRServerSession.ExecuteIsDatabaseExists}
aaWriteToLog('TACRServerSession.ExecuteIsDatabaseExists, DBName = '+DBName+
		#13#10+'Reply = '+IntToStr(Integer(FSentCommandHeader.Reply)));
{$ENDIF}
SendCommand;
end; // ExecuteIsDatabaseExists

//------------------------------------------------------------------------------
// execute GetTablesList
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetTablesList;
var
	List: TACRWideStringList;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqGetTablesList;
FSentCommandHeader.Reply := accrplOperationSucceed;
SentCommandDataStream.Size := 0;
List := TACRWideStringList.Create;
try
	try
		GetTablesList(List);
		SaveTACRWideStringListToStream(List,FSentCommandDataStream,10881);
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorGetTablesList,
			Format(ErrorL_CS_ErrorGetTablesList,[e.Message]));
		Exit;
		end;
	end;
	SendCommand;
finally
	List.Free;
end;
end; // ExecuteGetTablesList

//------------------------------------------------------------------------------
// execute IsTableExists
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsTableExists;
var
	len: Integer;
	TableName: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10886);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqIsTableExists;
SentCommandDataStream.Size := 0;
if (TableExists(TableName)) then
	FSentCommandHeader.Reply := accrplYes
else
	FSentCommandHeader.Reply := accrplNo;
SendCommand;
end; // ExecuteIsTableExists

//------------------------------------------------------------------------------
// execute GetFormatVersion
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetFormatVersion;
var
	Version: Double;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
Version := GetFormatVersion;
FSentCommandHeader.Request := accrqGetFormatVersion;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SaveDataToStream(Version,SizeOf(Version),FSentCommandDataStream,10898);
SendCommand;
end; // ExecuteGetFormatVersion

//------------------------------------------------------------------------------
// execute GetTotalPageCount
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetTotalPageCount;
var
	PageCount: Integer;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
PageCount := GetTotalPageCount;
FSentCommandHeader.Request := accrqGetTotalPageCount;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SaveDataToStream(PageCount,SizeOf(PageCount),FSentCommandDataStream,10899);
SendCommand;
end; // ExecuteGetTotalPageCount

//------------------------------------------------------------------------------
// execute GetFreePageCount
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetFreePageCount;
var
	PageCount: Integer;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
PageCount := GetFreePageCount;
FSentCommandHeader.Request := accrqGetFreePageCount;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SaveDataToStream(PageCount,SizeOf(PageCount),FSentCommandDataStream,10900);
SendCommand;
end; // ExecuteGetFreePageCount

//------------------------------------------------------------------------------
// execute IsDatabaseEncrypted
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsDatabaseEncrypted;
var
	len: Integer;
	DBName: AnsiString;
	Res: Boolean;
	DBNumber: Integer;
begin
try
	LoadDataFromStream(len,SizeOf(len),FReceivedCommandDataStream,10902);
	SetLength(DBName,len);
	LoadDataFromStream(PAnsiChar(@DBName[1])^,len,FReceivedCommandDataStream,
		10903);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
if (FConnected) then
	Res := IsDatabaseEncrypted
else
begin
DBNumber := FServer.FindDatabaseByName(DBName);
if (DBNumber < 0) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
	Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
Exit;
end;
try
	FHandle := TACRLocalSession.Create;
	try
		FHandle.DatabaseName := GetTemporaryName
			('ACRServerDBName'+'_'+IntToStr(SessionID));
		FHandle.DatabaseFileName := FServer.DatabaseFileNames[DBNumber];
		Res := FHandle.IsDatabaseEncrypted;
	finally
		FHandle.Free;
	end;
except
	SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
		Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
	Exit;
end;
end; // not connected
FSentCommandHeader.Request := accrqIsDatabaseEncrypted;
if (Res) then
	FSentCommandHeader.Reply := accrplYes
else
	FSentCommandHeader.Reply := accrplNo;
SentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteIsDatabaseEncrypted

//------------------------------------------------------------------------------
// execute IsDatabaseEncryptedByPassword
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsDatabaseEncryptedByPassword;
var
	len: Integer;
	DBName: AnsiString;
	Res: Boolean;
	DBNumber: Integer;
begin
try
	LoadDataFromStream(len,SizeOf(len),FReceivedCommandDataStream,10904);
	SetLength(DBName,len);
	LoadDataFromStream(PAnsiChar(@DBName[1])^,len,FReceivedCommandDataStream,
		10905);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
if (FConnected) then
	Res := IsDatabaseEncryptedByPassword
else
begin
DBNumber := FServer.FindDatabaseByName(DBName);
if (DBNumber < 0) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
	Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
Exit;
end;
try
	FHandle := TACRLocalSession.Create;
	try
		FHandle.DatabaseName := GetTemporaryName
			('ACRServerDBName'+'_'+IntToStr(SessionID));
		FHandle.DatabaseFileName := FServer.DatabaseFileNames[DBNumber];
		Res := FHandle.IsDatabaseEncryptedByPassword;
	finally
		FHandle.Free;
	end;
except
	SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
		Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
	Exit;
end;
end; // not connected
FSentCommandHeader.Request := accrqIsDatabaseEncryptedByPassword;
if (Res) then
	FSentCommandHeader.Reply := accrplYes
else
	FSentCommandHeader.Reply := accrplNo;
SentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteIsDatabaseEncryptedByPassword

//------------------------------------------------------------------------------
// execute IsCryptoParamsValid
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsCryptoParamsValid;
var
	len: Integer;
	DBName: AnsiString;
	Res: Boolean;
	DBNumber: Integer;
begin
try
	LoadDataFromStream(len,SizeOf(len),FReceivedCommandDataStream,11317);
	SetLength(DBName,len);
	LoadDataFromStream(PAnsiChar(@DBName[1])^,len,FReceivedCommandDataStream,
		11318);
	LoadCryptoParamsFromStream(FCryptoParams,FReceivedCommandDataStream,11313);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;

if (FConnected) then
	Res := IsCryptoParamsValid
else
begin
DBNumber := FServer.FindDatabaseByName(DBName);
if (DBNumber < 0) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
	Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
Exit;
end;
try
	FHandle := TACRLocalSession.Create;
	try
		FHandle.DatabaseName := GetTemporaryName
			('ACRServerDBName'+'_'+IntToStr(SessionID));
		FHandle.DatabaseFileName := FServer.DatabaseFileNames[DBNumber];
		Res := IsCryptoParamsValid;
	finally
		FHandle.Free;
	end;
except
	SendErrorMessage(ACR_CS_ErrorDatabaseDoesNotExists,
		Format(ErrorL_CS_ErrorDatabaseDoesNotExists,[DBName]));
	Exit;
end;
end; // not connected

FSentCommandHeader.Request := accrqIsCryptoParamsValid;
if (Res) then
	FSentCommandHeader.Reply := accrplYes
else
	FSentCommandHeader.Reply := accrplNo;
SentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteIsCryptoParamsValid

//------------------------------------------------------------------------------
// execute IsInTransaction
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsInTransaction;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqIsInTransaction;
if (GetInTransaction) then
	FSentCommandHeader.Reply := accrplYes
else
	FSentCommandHeader.Reply := accrplNo;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteIsInTransaction

//------------------------------------------------------------------------------
// execute StartTransaction
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteStartTransaction;
begin
if (not Connected) then
begin
{$IFDEF DEBUG_TRACE_SERVER_ExecuteStartTransaction}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteStartTransaction error - database is not connected');
{$ENDIF}
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteStartTransaction}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteStartTransaction starting... , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
try
	StartTransaction;
except
{$IFDEF DEBUG_TRACE_SERVER_ExecuteStartTransaction}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteStartTransaction failed.. , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID));
{$ENDIF}
	SendErrorMessage(ACR_CS_ErrorStartTransactionFailed,
		Format(ErrorL_CS_ErrorStartTransactionFailed,[FDatabaseName]));
	Exit;
end;
FSentCommandHeader.Request := accrqIsInTransaction;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteStartTransaction}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteStartTransaction sending reply... , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
SendCommand;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteStartTransaction}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteStartTransaction ok , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
end; // ExecuteStartTransaction

//------------------------------------------------------------------------------
// execute Commit
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteCommit;
var
	b: ByteBool;
begin
if (not Connected) then
begin
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteCommit failed - database is not connected');
{$ENDIF}
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteCommit starting... , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
try
	LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,10914);
except
	on e: Exception do
	begin
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteCommit failed - error reading params... , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID));
{$ENDIF}
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteCommit starting commit... , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID)+', b = '+BoolToStr(b,True));
{$ENDIF}
	Commit(Boolean(b));
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteCommit starting commit... ok , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID));
{$ENDIF}
except
	on e: Exception do
	begin
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteCommit failed - error reading params... , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID)+', Error: '+#13#10+e.Message);
{$ENDIF}
	SendErrorMessage(ACR_CS_ErrorCommitFailed, Format(ErrorL_CS_ErrorCommitFailed,
			[FDatabaseName]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqCommit;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteCommit sending reply... , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
SendCommand;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteCommit}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteCommit finished ok , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
end; // ExecuteCommit

//------------------------------------------------------------------------------
// execute Rollback
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteRollback;
begin
if (not Connected) then
begin
{$IFDEF DEBUG_TRACE_SERVER_ExecuteRollback}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteRollback failed - database is not connected');
{$ENDIF}
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
{$IFDEF DEBUG_TRACE_SERVER_ExecuteRollback}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteRollback starting... , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID));
{$ENDIF}
	Rollback;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteRollback}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteRollback starting... ok , SessionID = '+IntToStr
			(FDatabase.Handle.SessionID));
{$ENDIF}
except
	on e: Exception do
	begin
{$IFDEF DEBUG_TRACE_SERVER_ExecuteRollback}
	aaWriteToLog(aaGetCurrentTimeAsString+
			' ExecuteRollback failed - error reading params... , SessionID = '+
			IntToStr(FDatabase.Handle.SessionID)+', Error: '+#13#10+e.Message);
{$ENDIF}
	SendErrorMessage(ACR_CS_ErrorRollbackFailed,
		Format(ErrorL_CS_ErrorRollbackFailed,[FDatabaseName]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqRollback;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteRollback}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteRollback sending reply... , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
SendCommand;
{$IFDEF DEBUG_TRACE_SERVER_ExecuteRollback}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteRollback finished ok , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
end; // ExecuteRollback

//------------------------------------------------------------------------------
// execute CreateTable
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteCreateTable;
var
	TempCursor: TACRLocalCursor;
	TableName: WideString;
	FieldDefs: TACRFieldDefs;
	IndexDefs: TACRIndexDefs;
	ConstraintDefs: TACRConstraintDefs;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FieldDefs := TACRFieldDefs.Create;
IndexDefs := TACRIndexDefs.Create;
ConstraintDefs := TACRConstraintDefs.Create;
try
	try
		LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10927);
		FieldDefs.LoadFromStream(FReceivedCommandDataStream);
		IndexDefs.LoadFromStream(FReceivedCommandDataStream);
		ConstraintDefs.LoadFromStream(FReceivedCommandDataStream);
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
			Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
		Exit;
		end;
	end;
	try
		TempCursor := TACRLocalCursor.Create;
		try
			TempCursor.Session := FHandle;
			TempCursor.Temporary := False;
			TempCursor.InMemory := False;
			TempCursor.TableName := TableName;
			TempCursor.ReadOnly := False;
			TempCursor.Exclusive := True;
			TempCursor.CreateTable(FieldDefs,IndexDefs,ConstraintDefs);
		finally
			TempCursor.Free;
		end;
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorCreateTableFailed,
			Format(ErrorL_CS_ErrorCreateTableFailed,[e.Message]));
		Exit;
		end;
	end;
	FSentCommandHeader.Request := accrqCreateTable;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	SendCommand;
finally
	ConstraintDefs.Free;
	IndexDefs.Free;
	FieldDefs.Free;
end;
end; // ExecuteCreateTable

//------------------------------------------------------------------------------
// execute DeleteTable
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteDeleteTable;
var
	TempCursor: TACRLocalCursor;
	TableName: WideString;
	b: ByteBool;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10945);
	LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,11480);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	TempCursor := TACRLocalCursor.Create;
	try
		TempCursor.Session := FHandle;
		TempCursor.Temporary := False;
		TempCursor.InMemory := False;
		TempCursor.TableName := TableName;
		TempCursor.ReadOnly := False;
		TempCursor.Exclusive := True;
		TempCursor.DeleteTable(b);
	finally
		TempCursor.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorDeleteTableFailed,
		Format(ErrorL_CS_ErrorDeleteTableFailed,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqDeleteTable;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteDeleteTable

//------------------------------------------------------------------------------
// execute EmptyTable
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteEmptyTable;
var
	TempCursor: TACRLocalCursor;
	len: Integer;
	TableName: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10947);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	TempCursor := TACRLocalCursor.Create;
	try
		TempCursor.Session := FHandle;
		TempCursor.Temporary := False;
		TempCursor.InMemory := False;
		TempCursor.TableName := TableName;
		TempCursor.ReadOnly := False;
		TempCursor.Exclusive := True;
		TempCursor.EmptyTable;
	finally
		TempCursor.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorEmptyTableFailed,
		Format(ErrorL_CS_ErrorEmptyTableFailed,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqEmptyTable;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteEmptyTable

//------------------------------------------------------------------------------
// execute RenameTable
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteRenameTable;
var
	TempCursor: TACRLocalCursor;
	TableName: WideString;
	NewTableName: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10949);
	LoadWideStringFromStream(NewTableName,FReceivedCommandDataStream,10950);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	TempCursor := TACRLocalCursor.Create;
	try
		TempCursor.Session := FHandle;
		TempCursor.Temporary := False;
		TempCursor.InMemory := False;
		TempCursor.TableName := TableName;
		TempCursor.ReadOnly := False;
		TempCursor.Exclusive := True;
		TempCursor.RenameTable(NewTableName);
	finally
		TempCursor.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorRenameTableFailed,
		Format(ErrorL_CS_ErrorRenameTableFailed,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqRenameTable;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteRenameTable

//------------------------------------------------------------------------------
// execute RenameField
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteRenameField;
var
	TempCursor: TACRLocalCursor;
	TableName: WideString;
	FieldName: WideString;
	NewFieldName: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10953);
	LoadWideStringFromStream(FieldName,FReceivedCommandDataStream,10956);
	LoadWideStringFromStream(NewFieldName,FReceivedCommandDataStream,10958);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	TempCursor := TACRLocalCursor.Create;
	try
		TempCursor.Session := FHandle;
		TempCursor.Temporary := False;
		TempCursor.InMemory := False;
		TempCursor.TableName := TableName;
		TempCursor.ReadOnly := False;
		TempCursor.Exclusive := True;
		TempCursor.RenameField(FieldName,NewFieldName);
	finally
		TempCursor.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorRenameFieldFailed,
		Format(ErrorL_CS_ErrorRenameFieldFailed,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqRenameField;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteRenameField

//------------------------------------------------------------------------------
// execute OpenTable
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteOpenTable;
var
	LocalCursor: TACRLocalCursor;
	TableName: WideString;
	bExclusive: ByteBool;
	len: Integer;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10965);
	LoadDataFromStream(bExclusive,SizeOf(bExclusive),FReceivedCommandDataStream,
		10967);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	LocalCursor := TACRLocalCursor.Create;
	try
		LocalCursor.Session := FHandle;
		LocalCursor.Temporary := False;
		LocalCursor.InMemory := False;
		LocalCursor.TableName := TableName;
		LocalCursor.ReadOnly := False;
		LocalCursor.Exclusive := bExclusive;
		LocalCursor.OpenTableByFieldDefs(nil,nil,nil);
		LocalCursor.InternalInitFieldDefs;
		Inc(FLastCursorID);
      // prepare reply
		FSentCommandHeader.Request := accrqOpenTable;
		FSentCommandHeader.Reply := accrplOperationSucceed;
		FSentCommandDataStream.Size := 0;
		CreateServerCursor(LocalCursor,nil);
	except
		LocalCursor.Free;
		raise;
	end;
    // send reply
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorOpenTableFailed,
		Format(ErrorL_CS_ErrorOpenTableFailed,[e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteOpenTable

//------------------------------------------------------------------------------
// execute CloseTable
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteCloseTable;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		10969);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FCursorList.Remove(ServerCursor);
	ServerCursor.Free;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorCloseTableFailed,
		Format(ErrorL_CS_ErrorCloseTableFailed,[msg]));
	Exit;
	end;
    // prepare reply
	FSentCommandHeader.Request := accrqCloseTable;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorCloseTableFailed,
		Format(ErrorL_CS_ErrorCloseTableFailed,[e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteCloseTable

//------------------------------------------------------------------------------
// execute AddIndex
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteAddIndex;
var
	TableName: WideString;
	IndexDef: TACRIndexDef;
	LocalCursor: TACRLocalCursor;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
IndexDef := TACRIndexDef.Create;
try
	try
		LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10995);
		IndexDef.LoadFromStream(FReceivedCommandDataStream);
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
			Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
		Exit;
		end;
	end;
	try
		LocalCursor := TACRLocalCursor.Create;
		try
			LocalCursor.Session := FHandle;
			LocalCursor.TableName := TableName;
			LocalCursor.Exclusive := True;
			LocalCursor.ReadOnly := False;
			LocalCursor.InMemory := False;
			LocalCursor.Temporary := False;
			LocalCursor.AddIndex(IndexDef);
		finally
			LocalCursor.Free;
		end;
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorAddIndexFailed,
			Format(ErrorL_CS_ErrorAddIndexFailed,[e.Message]));
		Exit;
		end;
	end;
finally
	IndexDef.Free;
end;
FSentCommandHeader.Request := accrqAddIndex;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteAddIndex

//------------------------------------------------------------------------------
// execute DeleteIndex
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteDeleteIndex;
var
	TableName: WideString;
	IndexName: WideString;
	LocalCursor: TACRLocalCursor;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,10997);
	LoadWideStringFromStream(IndexName,FReceivedCommandDataStream,11000);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	LocalCursor := TACRLocalCursor.Create;
	try
		LocalCursor.Session := FHandle;
		LocalCursor.TableName := TableName;
		LocalCursor.Exclusive := True;
		LocalCursor.ReadOnly := False;
		LocalCursor.InMemory := False;
		LocalCursor.Temporary := False;
		LocalCursor.DeleteIndex(IndexName);
	finally
		LocalCursor.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorDeleteIndexFailed,
		Format(ErrorL_CS_ErrorDeleteIndexFailed,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqDeleteIndex;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteDeleteIndex

//------------------------------------------------------------------------------
// execute DeleteAllIndexes
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteDeleteAllIndexes;
var
	TableName: WideString;
	LocalCursor: TACRLocalCursor;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,11001);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	LocalCursor := TACRLocalCursor.Create;
	try
		LocalCursor.Session := FHandle;
		LocalCursor.TableName := TableName;
		LocalCursor.Exclusive := True;
		LocalCursor.ReadOnly := False;
		LocalCursor.InMemory := False;
		LocalCursor.Temporary := False;
		LocalCursor.DeleteAllIndexes;
	finally
		LocalCursor.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorDeleteAllIndexesFailed,
		Format(ErrorL_CS_ErrorDeleteAllIndexesFailed,[e.Message]));
	Exit;
	end;
end;
FSentCommandHeader.Request := accrqDeleteAllIndexes;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteDeleteAllIndexes

//------------------------------------------------------------------------------
// execute GetRecordCount
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetRecordCount;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11003);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqGetRecordCount;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.GetRecordCount;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorGetRecordCountFailed,
		Format(ErrorL_CS_ErrorGetRecordCountFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetRecordCountFailed,
		Format(ErrorL_CS_ErrorGetRecordCountFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteGetRecordCount

//------------------------------------------------------------------------------
// execute GetRecordBuffer
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetRecordBuffer;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11004);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqGetRecordBuffer;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.GetRecordBuffer;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorGetRecordBufferFailed,
		Format(ErrorL_CS_ErrorGetRecordBufferFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetRecordBufferFailed,
		Format(ErrorL_CS_ErrorGetRecordBufferFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteGetRecordBuffer

//------------------------------------------------------------------------------
// execute SetRecNo
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteSetRecNo;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11016);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqSetRecNo;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.SetRecNo;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorSetRecNoFailed,
		Format(ErrorL_CS_ErrorSetRecNoFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorSetRecNoFailed,
		Format(ErrorL_CS_ErrorSetRecNoFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteSetRecNo

{
//------------------------------------------------------------------------------
// execute GetRecNo
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetRecNo;
var
    ServerCursor: TACRServerCursor;
    CursorID:     TACRObjectID;
    msg:          AnsiString;
begin
  if (not Connected) then
   begin
    SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
                     Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
    Exit;
   end;
  try
    LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,11019);
  except
    on e: Exception do
     begin
       SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
                        Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
       Exit;
     end;
  end;
  try
    ServerCursor := FindServerCursor(CursorID);
    if (ServerCursor <> nil) then
     begin
      FSentCommandHeader.Request := accrqGetRecNo;
      FSentCommandHeader.Reply := accrplOperationSucceed;
      FSentCommandDataStream.Size := 0;
      ServerCursor.GetRecNo;
     end
    else
     begin
      msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
      SendErrorMessage(ACR_CS_ErrorGetRecNoFailed,
                        Format(ErrorL_CS_ErrorGetRecNoFailed,[msg]));
      Exit;
     end;
  except
    on e: Exception do
     begin
       SendErrorMessage(ACR_CS_ErrorGetRecNoFailed,
                        Format(ErrorL_CS_ErrorGetRecNoFailed,[e.Message]));
       Exit;
     end;
  end;
end; // ExecuteSetRecNo
}

//------------------------------------------------------------------------------
// execute InternalEdit
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteInternalEdit;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11044);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqInternalEdit;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.InternalEdit;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorInternalEditFailed,
		Format(ErrorL_CS_ErrorInternalEditFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorInternalEditFailed,
		Format(ErrorL_CS_ErrorInternalEditFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteInternalEdit

//------------------------------------------------------------------------------
// execute InternalCancel
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteInternalCancel;
var
	ServerCursor:   TACRServerCursor;
	CursorID:       TACRObjectID;
	msg:            AnsiString;
begin
  if (not Connected) then
  begin
    SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
      Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
    Exit;
  end;
  try
    LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream, 11045);
  except
    on e: Exception do
    begin
    SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
      Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
    Exit;
    end;
  end;
  try
    ServerCursor := FindServerCursor(CursorID);
    if (ServerCursor <> nil) then
    begin
    FSentCommandHeader.Request := accrqInternalCancel;
    FSentCommandHeader.Reply := accrplOperationSucceed;
    FSentCommandDataStream.Size := 0;
    ServerCursor.InternalCancel;
    end
    else
    begin
    msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
    SendErrorMessage(ACR_CS_ErrorInternalCancelFailed,
      Format(ErrorL_CS_ErrorInternalCancelFailed,[msg]));
    Exit;
    end;
  except
    on e: Exception do
    begin
    SendErrorMessage(ACR_CS_ErrorInternalCancelFailed,
      Format(ErrorL_CS_ErrorInternalCancelFailed,[e.Message]));
    Exit;
    end;
  end;
end; // ExecuteInternalCancel


//------------------------------------------------------------------------------
// execute InternalPost
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteInternalPost;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
aaIncCounter(counter4);
aaStartTime(time4);
aaStartTime(time5);
try
{$ENDIF}
	if (not Connected) then
	begin
	SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
		Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
	Exit;
	end;
	try
		LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
			11046);
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
			Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
		Exit;
		end;
	end;
	try
		ServerCursor := FindServerCursor(CursorID);
		if (ServerCursor <> nil) then
		begin
		FSentCommandHeader.Request := accrqInternalPost;
		FSentCommandHeader.Reply := accrplOperationSucceed;
		FSentCommandDataStream.Size := 0;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
		aaStopTime(time5);
		aaIncCounter(counter6);
		aaStartTime(time6);
{$ENDIF}
		ServerCursor.InternalPost;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
		aaStopTime(time6);
{$ENDIF}
		end
		else
		begin
		msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
		SendErrorMessage(ACR_CS_ErrorInternalPostFailed,
			Format(ErrorL_CS_ErrorInternalPostFailed,[msg]));
		Exit;
		end;
	except
		on e: Exception do
		begin
		SendErrorMessage(ACR_CS_ErrorInternalPostFailed,
			Format(ErrorL_CS_ErrorInternalPostFailed,[e.Message]));
		Exit;
		end;
	end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
finally
	aaStopTime(time4);
end;
{$ENDIF}
end; // ExecuteInternalPost

//------------------------------------------------------------------------------
// execute InternalDelete
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteInternalDelete;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqInternalDelete;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.InternalDelete;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorInternalDeleteFailed,
		Format(ErrorL_CS_ErrorInternalDeleteFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorInternalDeleteFailed,
		Format(ErrorL_CS_ErrorInternalDeleteFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteInternalDelete

//------------------------------------------------------------------------------
// execute ActivateFilters
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteActivateFilters;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqActivateFilters;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.ActivateFilters;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorActivateFiltersFailed,
		Format(ErrorL_CS_ErrorActivateFiltersFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorActivateFiltersFailed,
		Format(ErrorL_CS_ErrorActivateFiltersFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteActivateFilters

//------------------------------------------------------------------------------
// execute DeactivateFilters
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteDeactivateFilters;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqDeactivateFilters;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.DeactivateFilters;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorDeactivateFiltersFailed,
		Format(ErrorL_CS_ErrorDeactivateFiltersFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorDeactivateFiltersFailed,
		Format(ErrorL_CS_ErrorDeactivateFiltersFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteDeactivateFilters

//------------------------------------------------------------------------------
// execute Locate
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteLocate;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqLocate;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.Locate;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorLocateFailed, Format(ErrorL_CS_ErrorLocateFailed,
			[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorLocateFailed, Format(ErrorL_CS_ErrorLocateFailed,
			[e.Message]));
	Exit;
	end;
end;
end; // ExecuteLocate

//------------------------------------------------------------------------------
// execute FindKey
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteFindKey;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqFindKey;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.FindKey;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorFindKeyFailed,
		Format(ErrorL_CS_ErrorFindKeyFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorFindKeyFailed,
		Format(ErrorL_CS_ErrorFindKeyFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteFindKey

//------------------------------------------------------------------------------
// execute ResetRange
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteResetRange;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqResetRange;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.ResetRange(False);
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorResetRangeFailed,
		Format(ErrorL_CS_ErrorResetRangeFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorResetRangeFailed,
		Format(ErrorL_CS_ErrorResetRangeFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteResetRange

//------------------------------------------------------------------------------
// execute ApplyRange
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteApplyRange;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqApplyRange;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.ApplyRange;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorApplyRangeFailed,
		Format(ErrorL_CS_ErrorApplyRangeFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorApplyRangeFailed,
		Format(ErrorL_CS_ErrorApplyRangeFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteApplyRange

//------------------------------------------------------------------------------
// execute ReadBLOBValue
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteReadBLOBValue;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11047);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqReadBLOBValue;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.ReadBLOBValue;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorReadBLOBValueFailed,
		Format(ErrorL_CS_ErrorReadBLOBValueFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadBLOBValueFailed,
		Format(ErrorL_CS_ErrorReadBLOBValueFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteReadBLOBValue


//------------------------------------------------------------------------------
// execute ExecSQL
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteExecSQL;
var
    FQuery:                         TACRQuery;
    LocalCursor:                    TACRLocalCursor;
    QueryText:                      WideString;
    idx:                            Integer;
    b:                              ByteBool;
    RowsAffected:                   Int64;
    bAbort:                         Boolean;
    ClientInfo:                     TACRClientInfo;
    TempParams:                     TACRSQLParams;
    bOK:                            Boolean;
    LQuery:                         Pointer;
    FParamsChanged:                 Boolean;
    FParametrizedQueryReopened:     Boolean;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
aaIncCounter(counter15);
aaStartTime(time15);
try
{$ENDIF}
  bOK := True;
  QueryText := '';
  FQuery := nil;
  FParametrizedQueryReopened := False;
  if (not Connected) then
  begin
  {$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
  aaWriteToLog(aaGetCurrentTimeAsString+
      ' Execute SQL failed: database is not connected');
  {$ENDIF}
  SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
    Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
  Exit;
  end;
  {$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
  aaWriteToLog(aaGetCurrentTimeAsString+
      ' ExecuteExecSQL starting... , SessionID = '+IntToStr
      (FDatabase.Handle.SessionID));
  {$ENDIF}
    // pointer to remote parametrized query or nil if first opening / not parametrized
  LoadDataFromStream(LQuery,SizeOf(LQuery),FReceivedCommandDataStream,11690);
  if (LQuery = nil) then
  begin
      // first open or not parametrized query
  FQuery := TACRQuery.Create(nil);
  FQuery.DatabaseName := FHandle.DatabaseName;
  end // first open or not parametrized query
  else
  begin
  FParametrizedQueryReopened := True;
      // reopening of the parametrized query
  idx := FQueryList.IndexOf(LQuery);
  if (idx < 0) then
  begin
  SendErrorMessage(ACR_CS_ErrorPreparedQueryNotFound,
    Format(ErrorL_CS_ErrorPreparedQueryNotFound,[FSessionID,
      IntToHex(Integer(LQuery),8)]));
  Exit;
  end;
  FQuery := TACRQuery(LQuery);
  end; // reopening of the parametrized query
  try
    if (LQuery = nil) then
    begin
      LoadWideStringFromStream(QueryText,FReceivedCommandDataStream,11178);
      FQuery.SQL.Text := QueryText;
    end;
      // load RequestLive
    LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,11180);
    FQuery.RequestLive := b;
      // load ReadOnly
    LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,11181);
    FQuery.ReadOnly := b;
      // load CaseInsensitive
    LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,12548);
    FQuery.CaseInsensitive := Boolean(b);
    if (LQuery = nil) then
      TACRQuery(FQuery).Prepare;
    FParamsChanged := ReceiveParams(FQuery);
  except
    on e: Exception do
    begin
    {$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
      aaWriteToLog(
        ' Execute SQL failed: ... error reading request params, SessionID = '+
          IntToStr(FDatabase.Handle.SessionID)+', SQL: '+#13#10+QueryText);
    {$ENDIF}
      if (LQuery = nil) then
        FQuery.Free;
      SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
        Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
      Exit;
    end;
  end;
  try
    if (Assigned(FServer.OnSQL) and (LQuery = nil)) then
    begin
    ClientInfo := GetClientInfo;
    TempParams := TACRSQLParams.Create;
    try
      TempParams.Assign(FQuery.StmtHandle.SQLParams);
      FServer.DoOnSQL(ClientInfo,TempParams,QueryText,bAbort);
      if (bAbort) then
      begin
  {$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
      aaWriteToLog(aaGetCurrentTimeAsString+
          ' Execute SQL failed: ... command rejected by server, SessionID = '+
          IntToStr(FDatabase.Handle.SessionID)+', SQL: '+#13#10+QueryText);
  {$ENDIF}
        FQuery.Free;
        SendErrorMessage(11249, ErrorLSQLCommandRejectedByServer);
        Exit;
      end
      else
      begin
        FQuery.SQL.Text := QueryText;
        TACRQuery(FQuery).Prepare;
        FQuery.StmtHandle.SQLParams.Assign(TempParams);
      end;
    finally
      TempParams.Free;
    end;
    end;
    bOK := False;
    if (IsBeforeExecuteSQLAssigned) then
    begin
    DoBeforeExecuteSQL(FQuery,bOK);
    bOK := not bOK;
    end
    else
      bOK := True;
    if (bOK) then
    begin
  {$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
  aaStartTime(time16);
  {$ENDIF}
      LocalCursor := TACRLocalCursor(FQuery.StmtHandle.OpenQuery);
  {$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
  aaStopTime(time16);
  {$ENDIF}
      if (IsAfterExecuteSQLAssigned) then
        DoAfterExecuteSQL(FQuery);
    end
    else
    begin
    {$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
      aaWriteToLog(aaGetCurrentTimeAsString+
          ' Execute SQL failed: ...blocked by database event, SessionID = '+IntToStr
          (FDatabase.Handle.SessionID)+', SQL: '+#13#10+QueryText);
    {$ENDIF}
      if (LQuery = nil) then
        FQuery.Free;
      SendErrorMessage(ACR_CS_ErrorExecutingSQLScript,
        Format(ErrorL_CS_ErrorExecutingSQLScript,[
            ErrorLExecuteSQLBlockedByDatabaseEvent]));
      Exit;
    end;
    FSentCommandHeader.Request := accrqExecSQL;
    FSentCommandHeader.Reply := accrplOperationSucceed;
    FSentCommandDataStream.Size := 0;
    RowsAffected := FQuery.StmtHandle.RowsAffected;
    if (LQuery = nil) then
    begin
      if (FQuery.Params.Count > 0) then
      begin
        LQuery := FQuery;
        FQueryList.Add(LQuery);
      end;
      // pointer to remote parametrized query or nil if first opening / not parametrized
      SaveDataToStream(LQuery,SizeOf(LQuery),FSentCommandDataStream,11692);
    end;
    b := (LocalCursor <> nil);
    SaveDataToStream(RowsAffected,SizeOf(RowsAffected),FSentCommandDataStream,
      11182);
      // if cursor returned
    SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,11183);
    if (b) then
    begin
      b := not FQuery.StmtHandle.ReadOnly;
      SaveDataToStream(b,SizeOf(b),FSentCommandDataStream,11187);
      if (b) then
      begin
        // send live cursor only for not parametrized or first opening parametrized
        if (not FParametrizedQueryReopened) then
          SendLiveQuery(FQuery,LocalCursor);
      end
      else
      begin
        SendNotLiveQuery(FQuery,LocalCursor);
        if (LQuery = nil) then
          FQuery.Free;
      end;
    end
    else
      if (LQuery = nil) then
        FQuery.Free;
  except
    on e: Exception do
    begin
  {$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
    aaWriteToLog(aaGetCurrentTimeAsString+
        ' Execute SQL failed: ... error executing script, SessionID = '+IntToStr
        (FDatabase.Handle.SessionID)+#13#10+'Error: '+#13#10+e.Message+#13#10+
        'SQL: '+#13#10+QueryText);
  {$ENDIF}
    try
      if (LQuery = nil) then
        FQuery.Free;
    except
    end;
    SendErrorMessage(ACR_CS_ErrorExecutingSQLScript,
      Format(ErrorL_CS_ErrorExecutingSQLScript,[e.Message]));
    Exit;
    end;
  end;
{$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteExecSQL ok, sending reply... , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID));
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
aaStartTime(time17);
{$ENDIF}
  SendCommand;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
aaStopTime(time17);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SERVER_SQL_ERRORS}
aaWriteToLog(aaGetCurrentTimeAsString+
		' ExecuteExecSQL ok, sending reply... ok , SessionID = '+IntToStr
		(FDatabase.Handle.SessionID)+', SQL: '+#13#10+QueryText);
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
finally
aaStopTime(time15);
end;
{$ENDIF}
end; // ExecuteExecSQL


//------------------------------------------------------------------------------
// unprepare params and free parametrized query completely
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteSQLUnprepareParams;
var
	LQuery: Pointer;
	idx: Integer;
begin
if (not Connected) then
begin
{ TODO -oLeo : remove it v.5}
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(LQuery,SizeOf(LQuery),FReceivedCommandDataStream,11687);
	idx := FQueryList.IndexOf(LQuery);
	if (idx < 0) then
		raise EACRException.Create(11688,ErrorLPreparedQueryNotFound,
			[IntToHex(Integer(LQuery),8)]);
	FQueryList.Delete(idx);
	TACRQuery(LQuery).Free;
except
	on e: Exception do
	begin
	DoOnError(ACR_CS_ErrorUnprepareSQLParams,11689,
		Format(ErrorL_CS_ErrorUnprepareSQLParams, [FSessionID,e.Message]));
	end;
end;
{ TODO -oLeo : remove it in v.5}
FSentCommandHeader.Request := accrqSQLUnprepareParams;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
SendCommand;
end; // ExecuteSQLUnprepareParams

//------------------------------------------------------------------------------
// execute IsRecordExists
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteIsRecordExists;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11285);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqIsRecordExists;
	FSentCommandHeader.Reply := accrplNo;
	FSentCommandDataStream.Size := 0;
	ServerCursor.IsRecordExists;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorIsRecordExistsFailed,
		Format(ErrorL_CS_ErrorIsRecordExistsFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorIsRecordExistsFailed,
		Format(ErrorL_CS_ErrorIsRecordExistsFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteIsRecordExists

//------------------------------------------------------------------------------
// execute ExportTableToSQL
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteExportTableToSQL;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11742);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqExportTableToSQL;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.ExportTableToSQL;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorExportTableToSQLFailed,
		Format(ErrorL_CS_ErrorExportTableToSQLFailed,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorExportTableToSQLFailed,
		Format(ErrorL_CS_ErrorExportTableToSQLFailed,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteExportTableToSQL

//------------------------------------------------------------------------------
// execute ExportDatabaseToSQL
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteExportDatabaseToSQL;
var
	SQL: WideString;
	ExportStructure: Boolean;
	AddDropTableCommand: Boolean;
	ExportIndexes: Boolean;
	AddDropIndexCommand: Boolean;
	ExportData: Boolean;
	ExportBLOBFields: Boolean;
	UseBracketsForNames: Boolean;
	ExportForeignKeys: Boolean;
	ExportStoredFunctions: Boolean;
	ExportViews: Boolean;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadBooleanFromStream(ExportStructure,FReceivedCommandDataStream,12152);
	LoadBooleanFromStream(AddDropTableCommand,FReceivedCommandDataStream,12153);
	LoadBooleanFromStream(ExportIndexes,FReceivedCommandDataStream,12154);
	LoadBooleanFromStream(AddDropIndexCommand,FReceivedCommandDataStream,12155);
	LoadBooleanFromStream(ExportData,FReceivedCommandDataStream,12156);
	LoadBooleanFromStream(ExportBLOBFields,FReceivedCommandDataStream,12157);
	LoadBooleanFromStream(UseBracketsForNames,FReceivedCommandDataStream,12158);
	LoadBooleanFromStream(ExportForeignKeys,FReceivedCommandDataStream,12159);
	LoadBooleanFromStream(ExportStoredFunctions,FReceivedCommandDataStream,12160);
  LoadBooleanFromStream(ExportViews,FReceivedCommandDataStream,12607);
	SQL := FHandle.ExportDatabaseToSQL(ExportStructure,AddDropTableCommand,
		ExportIndexes,AddDropIndexCommand,ExportData,ExportBLOBFields,
    UseBracketsForNames, ExportForeignKeys, ExportStoredFunctions, ExportViews);
	SaveWideStringToStream(SQL,FSentCommandDataStream,12161);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorExportDatabaseToSQLFailed,
		Format(ErrorL_CS_ErrorExportDatabaseToSQLFailed,[e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteExportDatabaseToSQL

//------------------------------------------------------------------------------
// get tables info
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetTablesInfo;
var
	i,Count: Integer;
	tablesInfo: TACRTableInfoArray;
	SortByTableName: Boolean;
{
 TACRTableInfo = record
   TableName:       WideString;
   Comment:         WideString;
   TableState:      TACRTableState;
   CreationDate:    TDateTime;
 end;
}
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqGetTablesInfo;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadBooleanFromStream(SortByTableName,FReceivedCommandDataStream,11988);
	tablesInfo := FHandle.GetTablesInfo(SortByTableName);
	Count := Length(tablesInfo);
	SaveDataToStream(Count,SizeOf(Count),FSentCommandDataStream,11938);
	if (Count > 0) then
	begin
	for i := 0 to Count - 1 do
	begin
	SaveWideStringToStream(tablesInfo[i].TableName,FSentCommandDataStream,11940);
	SaveWideStringToStream(tablesInfo[i].Comment,FSentCommandDataStream,12352);
	SaveDataToStream(tablesInfo[i].TableState,SizeOf(TACRTableState),
		FSentCommandDataStream,12353);
	SaveDataToStream(tablesInfo[i].CreationDate,SizeOf(TDateTime),
		FSentCommandDataStream,12354);
	end;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetTablesInfo,
		Format(ErrorL_CS_ErrorGetTablesInfo,[e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteGetTablesInfo

//------------------------------------------------------------------------------
// get table state
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetTableState;
var
	TableName: WideString;
	TableState: TACRTableState;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqGetTableState;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,11941);
	TableState := FHandle.GetTableState(TableName);
	SaveDataToStream(TableState,SizeOf(TableState),FSentCommandDataStream,11942);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetTableState,
		Format(ErrorL_CS_ErrorGetTableState,[TableName,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteGetTableState

//------------------------------------------------------------------------------
// get table state from cursor
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetTableStateCursor;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
	state: TACRTableState;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		11941);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqGetTableStateCursor;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	state := ServerCursor.LocalCursor.GetTableState;
	SaveDataToStream(state,SizeOf(state),FSentCommandDataStream,11942);
	SendCommand;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorGetTableStateCursor,
		Format(ErrorL_CS_ErrorGetTableStateCursor,[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetTableStateCursor,
		Format(ErrorL_CS_ErrorGetTableStateCursor,[e.Message]));
	Exit;
	end;
end;
end; // ExecuteGetTableStateCursor

//------------------------------------------------------------------------------
// get table comment
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetTableComment;
var
	TableName, Comment: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqGetTableComment;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,11974);
	Comment := FHandle.GetTableComment(TableName);
	SaveWideStringToStream(Comment,FSentCommandDataStream,11975);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetTableComment,
		Format(ErrorL_CS_ErrorGetTableComment,[TableName,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteGetTableComment

//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteSetTableComment;
var
	TableName, Comment: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqSetTableComment;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(TableName,FReceivedCommandDataStream,11976);
	LoadWideStringFromStream(Comment,FReceivedCommandDataStream,11977);
	FHandle.SetTableComment(TableName,Comment);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetTableComment,
		Format(ErrorL_CS_ErrorGetTableComment,[TableName,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteSetTableComment

//------------------------------------------------------------------------------
// load records
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteLoadRecords;
var
	ServerCursor: TACRServerCursor;
	CursorID: TACRObjectID;
	msg: AnsiString;
	state: TACRTableState;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
try
	LoadDataFromStream(CursorID,SizeOf(CursorID),FReceivedCommandDataStream,
		12327);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorReadingRequestParams,
		Format(ErrorL_CS_ErrorReadingRequestParams,[e.Message]));
	Exit;
	end;
end;
try
	ServerCursor := FindServerCursor(CursorID);
	if (ServerCursor <> nil) then
	begin
	FSentCommandHeader.Request := accrqLoadRecords;
	FSentCommandHeader.Reply := accrplOperationSucceed;
	FSentCommandDataStream.Size := 0;
	ServerCursor.LoadRecords;
	end
	else
	begin
	msg := Format(ErrorLCannotFindServerCursor,[CursorID]);
	SendErrorMessage(ACR_CS_ErrorLoadRecords, Format(ErrorL_CS_ErrorLoadRecords,
			[msg]));
	Exit;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorLoadRecords, Format(ErrorL_CS_ErrorLoadRecords,
			[e.Message]));
	Exit;
	end;
end;
end; // ExecuteLoadRecords

////////////////////////////////////////////////////////////////////////////////
//
//------------ STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// create stored function
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteCreateStoredFunction;
var
	SQLScript: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqCreateStoredFunction;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(SQLScript,FReceivedCommandDataStream,12259);
	FHandle.CreateStoredFunction(SQLScript);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorCreateStoredFunction,
		Format(ErrorL_CS_ErrorCreateStoredFunction,[SQLScript,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteCreateStoredFunction

//------------------------------------------------------------------------------
// drop stored function
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteDropStoredFunction;
var
	FunctionName: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqDropStoredFunction;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(FunctionName,FReceivedCommandDataStream,12261);
	FHandle.DropStoredFunction(FunctionName);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorDropStoredFunction,
		Format(ErrorL_CS_ErrorDropStoredFunction,[FunctionName,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteDropStoredFunction

//------------------------------------------------------------------------------
// alter stored function
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteAlterStoredFunction;
var
	FunctionName, SQLScript: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqAlterStoredFunction;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(FunctionName,FReceivedCommandDataStream,12264);
	LoadWideStringFromStream(SQLScript,FReceivedCommandDataStream,12265);
	FHandle.AlterStoredFunction(FunctionName,SQLScript);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorAlterStoredFunction,
		Format(ErrorL_CS_ErrorAlterStoredFunction,[FunctionName,SQLScript,
			e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteAlterStoredFunction

//------------------------------------------------------------------------------
// rename stored function
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteAlterStoredFunctionRename;
var
	FunctionName, NewFunctionName: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqAlterStoredFunctionRename;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(FunctionName,FReceivedCommandDataStream,12268);
	LoadWideStringFromStream(NewFunctionName,FReceivedCommandDataStream,12269);
	FHandle.AlterStoredFunctionRename(FunctionName,NewFunctionName);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorAlterStoredFunctionRename,
		Format(ErrorL_CS_ErrorAlterStoredFunctionRename,[FunctionName,
			NewFunctionName,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteAlterStoredFunctionRename

//------------------------------------------------------------------------------
// find stored function
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteFindStoredFunction;
var
	FunctionName, SQLScript: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqFindStoredFunction;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(FunctionName,FReceivedCommandDataStream,12272);
	SQLScript := FHandle.FindStoredFunction(FunctionName);
	SaveWideStringToStream(SQLScript,FSentCommandDataStream,12273);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorFindStoredFunction,
		Format(ErrorL_CS_ErrorFindStoredFunction,[FunctionName,SQLScript,
			e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteFindStoredFunction

//------------------------------------------------------------------------------
// get stored functions
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteGetStoredFunctions;
var
	FunctionNames, FunctionSQLScripts: TACRWideStringList;
	bGetScripts, bSortNamesByAlphabet: Boolean;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqGetStoredFunctions;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadBooleanFromStream(bGetScripts,FReceivedCommandDataStream,12282);
	LoadBooleanFromStream(bSortNamesByAlphabet,FReceivedCommandDataStream,12283);
	FunctionNames := TACRWideStringList.Create;
	if (bGetScripts) then
		FunctionSQLScripts := TACRWideStringList.Create
	else
		FunctionSQLScripts := nil;
	try
		FHandle.GetStoredFunctions(FunctionNames,FunctionSQLScripts,
			bSortNamesByAlphabet);
		SaveTACRWideStringListToStream(FunctionNames,FSentCommandDataStream,12284);
		if (bGetScripts) then
		begin
		SaveTACRWideStringListToStream(FunctionSQLScripts,FSentCommandDataStream,
			12285);
		end;
	finally
		FunctionNames.Free;
		if (FunctionSQLScripts <> nil) then
			FunctionSQLScripts.Free;
	end;
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorGetStoredFunctions,
		Format(ErrorL_CS_ErrorGetStoredFunctions,[e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteGetStoredFunctions

//------------------------------------------------------------------------------
// export stored functions to SQL
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteExportStoredFunctionsToSQL;
var
	SQLScript: WideString;
begin
if (not Connected) then
begin
SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
	Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
Exit;
end;
FSentCommandHeader.Request := accrqExportStoredFunctionsToSQL;
FSentCommandHeader.Reply := accrplOperationSucceed;
FSentCommandDataStream.Size := 0;
try
	LoadWideStringFromStream(SQLScript,FReceivedCommandDataStream,12288);
	FHandle.ExportStoredFunctionsToSQL(SQLScript);
	SaveWideStringToStream(SQLScript,FSentCommandDataStream,12289);
except
	on e: Exception do
	begin
	SendErrorMessage(ACR_CS_ErrorExportStoredFunctionsToSQL,
		Format(ErrorL_CS_ErrorExportStoredFunctionsToSQL,[SQLScript,e.Message]));
	Exit;
	end;
end;
SendCommand;
end; // ExecuteExportStoredFunctionsToSQL


//------------ END OF STORED FUNCTIONS AND PROCEDURES - added in v.5.10 --------

//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteClearCache;
begin
  if (not Connected) then
  begin
  SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
  Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
  Exit;
  end;
  FSentCommandHeader.Request := accrqClearCache;
  FSentCommandHeader.Reply := accrplOperationSucceed;
  FSentCommandDataStream.Size := 0;
  try
  { TODO -oLeo-Ray : reply does not needed here }
  FHandle.ClearCache;
  except
  on e: Exception do
  begin
  SendErrorMessage(ACR_CS_ErrorClearCache, Format(ErrorL_CS_ErrorClearCache,
      [e.Message]));
  Exit;
  end;
  end;
  SendCommand;
end; // ExecuteClearCache


procedure TACRServerSession.ExecuteFlushFileBuffers;
begin
  if (not Connected) then
  begin
  SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
    Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
  Exit;
  end;
  FSentCommandHeader.Request := accrqFlushFileBuffers;
  FSentCommandHeader.Reply := accrplOperationSucceed;
  FSentCommandDataStream.Size := 0;
  try
  { TODO -oLeo-Ray : reply does not needed here }
    FHandle.FlushFileBuffers;
  except
    on e: Exception do
    begin
    SendErrorMessage(ACR_CS_ErrorFlushFileBuffers,
      Format(ErrorL_CS_ErrorFlushFileBuffers,[e.Message]));
    Exit;
    end;
  end;
  SendCommand;
end; // ExecuteFlushFileBuffers


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteSetCaseInsensitive;
var b: ByteBool;
begin
  try
    LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,12552);
    FCaseInsensitive := Boolean(b);
    FHandle.CaseInsensitive := FCaseInsensitive;
  except
  end;
end; // ExecuteSetCaseInsensitive


//------------------------------------------------------------------------------
// create view - added in v.6.00
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteCreateView;
var  b:                 ByteBool;
     ViewName:          WideString;
     SelectStatement:   WideString;
     Columns:           TACRWideStringList;
     bWithCheckOption:  Boolean;
     Comment:           WideString;
begin
  FSentCommandHeader.Request := accrqCreateView;
  FSentCommandHeader.Reply := accrplOperationSucceed;
  FSentCommandDataStream.Size := 0;
  if (not Connected) then
  begin
    SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
      Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
    Exit;
  end;
  try
    LoadWideStringFromStream(ViewName,FReceivedCommandDataStream,12616);
    LoadWideStringFromStream(SelectStatement,FReceivedCommandDataStream,12617);
    LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,12618);
    if (b) then
     Columns := TACRWideStringList.Create
    else
     Columns := nil;
    try
     if (b) then
      Columns.LoadFromStream(FReceivedCommandDataStream);
     LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,12619);
     bWithCheckOption := b;
     LoadWideStringFromStream(Comment,FReceivedCommandDataStream,12620);
     FHandle.CreateView(ViewName,SelectStatement,Columns,bWithCheckOption,Comment);
    finally
     if (Columns <> nil) then
      Columns.Free;
    end;
  except
    on e: Exception do
    begin
      SendErrorMessage(ACR_CS_ErrorCreateView,
        Format(ErrorL_CS_ErrorCreateView,[e.Message]));
      Exit;
    end;
  end;
  try
  except
    on e: Exception do
    begin
      SendErrorMessage(ACR_CS_ErrorCreateView,
        Format(ErrorL_CS_ErrorCreateView,[e.Message]));
      Exit;
    end;
  end;
  SendCommand;
end; // ExecuteCreateView


//------------------------------------------------------------------------------
// drop view  - added in v.6.00
//------------------------------------------------------------------------------
procedure TACRServerSession.ExecuteDropView;
var  b:                 ByteBool;
     ViewName:          WideString;
begin
  FSentCommandHeader.Request := accrqDropView;
  FSentCommandHeader.Reply := accrplOperationSucceed;
  FSentCommandDataStream.Size := 0;
  if (not Connected) then
  begin
    SendErrorMessage(ACR_CS_ErrorDatabaseIsNotConnected,
      Format(ErrorL_CS_ErrorDatabaseIsNotConnected,[FDatabaseName]));
    Exit;
  end;
  try
    LoadWideStringFromStream(ViewName,FReceivedCommandDataStream,12621);
    LoadDataFromStream(b,SizeOf(b),FReceivedCommandDataStream,12622);
    FHandle.DropView(ViewName,Boolean(b));
  except
    on e: Exception do
    begin
      SendErrorMessage(ACR_CS_ErrorDropView,
        Format(ErrorL_CS_ErrorDropView,[e.Message]));
      Exit;
    end;
  end;
  try
  except
    on e: Exception do
    begin
      SendErrorMessage(ACR_CS_ErrorDropView,
        Format(ErrorL_CS_ErrorDropView,[e.Message]));
      Exit;
    end;
  end;
  SendCommand;
end; // ExecuteCreateView



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerRecordCache - cache class for server cursor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// load records
//------------------------------------------------------------------------------
function TACRServerRecordCache.InternalLoadRecord(RecLow, RecHigh,
	RecNo: TACRRecordNo): TACRGetRecordResult;
var
	pos: Pointer;
	curBuf,tempBuf: TACRRecordBuffer;
	CurRecNo,n: TACRRecordNo;
	bFirstSet, bLastSet: Boolean; // FirstRecordID, LastRecordID set

procedure SetFirst;
begin
Move(LCursor.CurrentRecordID,FFirstRecordID,SizeOf(FFirstRecordID));
bFirstSet := True;
end; // SetFirst

procedure SetLast;
begin
Move(LCursor.CurrentRecordID,FLastRecordID,SizeOf(FLastRecordID));
bLastSet := True;
end; // SetLast

begin
Result := grrOK;
bFirstSet := False;
bLastSet := False;
pos := LCursor.SavePosition;
tempBuf := LCursor.AllocateRecordBuffer;
curBuf := LCursor.CurrentRecordBuffer;
try
    // assign temporary buffer to cursor
	LCursor.CurrentRecordBuffer := tempBuf;
    // copy current record
	Move(curBuf^, PAnsiChar(FBuffer+RecLow*LCursor.RecordSize)^,
		LCursor.RecordSize);
	FRecordNumbers.Items[RecLow] := RecNo;
	FRecords.Items[RecLow] := LCursor.CurrentRecordID;
	if (RecNo = 1) then
		SetFirst;
	if (RecNo = FRecordCount) then
		SetLast;
	if (RecLow > 0) then
	begin
      // Load records before current record
	CurRecNo := RecNo-1;
	n := RecLow-1;
	while (CurRecNo >= 1) and (n >= 0) do
	begin
	Result := LCursor.GetRecordBuffer(grmPrior);
	if (Result <> grrOK) then
		Exit;
	Move(tempBuf^,PAnsiChar(FBuffer+n * LCursor.RecordSize)^, LCursor.RecordSize);
	FRecordNumbers.Items[n] := CurRecNo;
	FRecords.Items[n] := LCursor.CurrentRecordID;
	if (CurRecNo = 1) then
		SetFirst;
	Dec(n);
	Dec(CurRecNo);
	end;
	end; // Load records before current record
	if (RecHigh > 0) then
	begin
      // Load records before current record
	if (RecLow > 0) then
	begin
	LCursor.RestorePosition(pos);
	Move(curBuf^,tempBuf^,LCursor.RecordSize);
	end;
	CurRecNo := RecNo+1;
	n := RecLow+1;
	while (CurRecNo <= FRecordCount) and (n <= RecLow+RecHigh) do
	begin
	Result := LCursor.GetRecordBuffer(grmNext);
	if (Result <> grrOK) then
		Exit;
	Move(tempBuf^,PAnsiChar(FBuffer+n * LCursor.RecordSize)^, LCursor.RecordSize);
	FRecordNumbers.Items[n] := CurRecNo;
	FRecords.Items[n] := LCursor.CurrentRecordID;
	if (CurRecNo = FRecordCount) then
		SetLast;
	Inc(n);
	Inc(CurRecNo);
	end;
	end; // Load records before current record
finally
	LCursor.RestorePosition(pos);
	LCursor.FreePosition(pos);
	LCursor.FreeRecordBuffer(tempBuf);
	LCursor.CurrentRecordBuffer := curBuf;
end;
end; // InternalLoadRecord

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRServerRecordCache.Create(aMinRecords, aMaxRecords: Integer;
	aServerCursor: TACRServerCursor; aLocalCursor: TACRLocalCursor);
begin
inherited Create(aMinRecords,aMaxRecords,aLocalCursor);
LServerCursor := aServerCursor;
FLastLoadedTime := 0;
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRServerRecordCache.Destroy;
begin
inherited;
end; // Destroy

//------------------------------------------------------------------------------
// all parameters are set to server cursor
//------------------------------------------------------------------------------
function TACRServerRecordCache.Load(GetRecordMode: TACRGetRecordMode)
	: TACRGetRecordResult;
var
	bool: ByteBool;
	RecNo,RecHigh,RecLow,half: TACRRecordNo;
begin
Result := grrEOF;
FRecordCount := LCursor.GetRecordCount;
if (FNumRecords < FMinRecords) then
	FNumRecords := FMinRecords;
if (FNumRecords > FRecordCount) then
	FNumRecords := FRecordCount;
if (FNumRecords > FMaxRecords) then
	FNumRecords := FMaxRecords;
ResizeCache(FNumRecords);
if (FRecordCount <= 0) then
begin
// just for debug
Result := LCursor.GetRecordBuffer(GetRecordMode);
FillChar(FFirstRecordID,SizeOf(FFirstRecordID),$FF);
FillChar(FLastRecordID,SizeOf(FLastRecordID),$FF);
LCursor.FirstPosition := False;
LCursor.LastPosition := True;
end
else
begin
    // RecordCount > 0
Result := LCursor.GetRecordBuffer(GetRecordMode);
if ((Result = grrError) and (GetRecordMode = grmCurrent) and
		(not LCursor.FirstPosition) and (not LCursor.LastPosition)) then
begin
Result := LCursor.GetRecordBuffer(grmNext);
if (Result <> grrOK) then
begin
Result := LCursor.GetRecordBuffer(grmPrior);
end;
end;
RecNo := LCursor.GetRecNo;
if (RecNo < 0) then
	Result := grrError;
if (Result = grrOK) then
begin
      // load records to cache
if (FNumRecords = 1) then
begin
RecHigh := 0;
RecLow := 0;
end
else
begin
        // half from cache size
half := (FNumRecords - 1) div 2;
        // get current record number in the order applied for this cursor - curRecPos
        // recLow - number of records before current record to store in cache
        // recHigh - number of records after current record to store in cache
if (half = 0) then
begin
          // 2 records
if (RecNo < FRecordCount) then
begin
RecHigh := 1;
RecLow := 0;
end
else
begin
RecHigh := 0;
RecLow := 1;
end;
end
else
begin
          // 3+ records
if (FNumRecords = FRecordCount) then
begin
           // start from record #0
RecLow := RecNo-1;
RecHigh := FRecordCount - RecNo;
end
else
begin
if (RecNo <= half) then
begin
              // start from record #0
RecLow := RecNo-1;
RecHigh := FNumRecords-1-RecLow;
end
else
begin
if ((FRecordCount-RecNo) >= half) then
	RecHigh := half
else
	RecHigh := FRecordCount-RecNo;
RecLow := FNumRecords-1-RecHigh;
end;
end;
end; // 3+ records
end;
Result := InternalLoadRecord(RecLow,RecHigh,RecNo);
end; // grr OK
end; // RecordCount > 0
FState := LCursor.GetTableState;
FLastLoadedTime := aaGetTickCount;
FLoaded := True;
end; // Load

//------------------------------------------------------------------------------
// set RecNo
//------------------------------------------------------------------------------
procedure TACRServerRecordCache.SetRecNo(RecNo: TACRRecordNo;
	IndexID: TACRObjectID);
var
	RecordCount, ResultRecNo: TACRRecordNo;
begin
LCursor.LockTable(False);
try
	RecordCount := LCursor.GetRecordCount;
	if (RecordCount > 0) then
	begin
	if (LCursor.IndexID <> IndexID) then
		LCursor.IndexID := IndexID;
	LCursor.SetRecNo(RecNo);
	Load(grmCurrent);
	end;
finally
	LCursor.UnlockTable(False);
end;
end; // SetRecNo

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerCursor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// send record buffer
//------------------------------------------------------------------------------
procedure TACRServerCursor.SendRecordBuffer(const ErrorCode: Integer;
	RecordBuffer: TACRRecordBuffer);
begin
//  SaveDataToStream(RecordBuffer^,FLocalCursor.RecordBufferSize,TACRServerSession(FSession).FSentCommandDataStream,ErrorCode);
// 4.20: skip calculated and lookup as they cannot exist on server side
SaveDataToStream(RecordBuffer^,FLocalCursor.RecordSize,
	TACRServerSession(FSession).FSentCommandDataStream,ErrorCode);
end; // SendRecordBuffer

//------------------------------------------------------------------------------
// receive record buffer
//------------------------------------------------------------------------------
procedure TACRServerCursor.ReceiveRecordBuffer(const ErrorCode: Integer;
	RecordBuffer: TACRRecordBuffer);
begin
//  LoadDataFromStream(RecordBuffer^,FLocalCursor.RecordBufferSize,TACRServerSession(FSession).FReceivedCommandDataStream,ErrorCode);
// 4.20: skip calculated and lookup as they cannot exist on server side
LoadDataFromStream(RecordBuffer^,FLocalCursor.RecordSize,
	TACRServerSession(FSession).FReceivedCommandDataStream,ErrorCode);
end; // ReceiveRecordBuffer

//------------------------------------------------------------------------------
// receive modified BLOB values
//------------------------------------------------------------------------------
procedure TACRServerCursor.ReceiveModifiedBLOBValues(ToInsert: Boolean);
var
	i, FieldNumber, Count: Integer;
	Size: Int64;
	LocalBLOBStream: TACRStream;
begin
LoadDataFromStream(Count,SizeOf(Count),
	TACRServerSession(FSession).FReceivedCommandDataStream,11228);
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
aaWriteToLog('Server: receive modified blob values, Count = '+IntToStr(Count));
{$ENDIF}
for i := 0 to Count - 1 do
begin
LoadDataFromStream(FieldNumber,SizeOf(FieldNumber),
	TACRServerSession(FSession).FReceivedCommandDataStream,11229);
LoadDataFromStream(Size,SizeOf(Size),
	TACRServerSession(FSession).FReceivedCommandDataStream,11230);
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
aaWriteToLog(
	'Server: receive modified blob values - opening blob stream, FieldNumber = '+
		IntToStr(FieldNumber)+ ', Size = '+IntToStr(Size));
{$ENDIF}
LocalBLOBStream := FLocalCursor.InternalCreateBlobStream(ToInsert,FieldNumber,
	bomWrite);
LocalBLOBStream.Modified := True;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
aaWriteToLog('Server: receive modified blob values - blob stream opened ok');
{$ENDIF}
try
	if (Size > 0) then
	begin
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
	aaWriteToLog(
		'Server: receive modified blob values - loading data, Start Position = '+
			IntToStr(TACRServerSession(FSession).FReceivedCommandDataStream.Position)
			+ ', Received Stream Size = '+IntToStr(TACRServerSession(FSession)
				.FReceivedCommandDataStream.Size));
{$ENDIF}
	LocalBLOBStream.LoadFromStreamWithPosition(TACRServerSession(FSession)
			.FReceivedCommandDataStream,
		TACRServerSession(FSession).FReceivedCommandDataStream.Position,Size);
	TACRServerSession(FSession).FReceivedCommandDataStream.Position :=
		TACRServerSession(FSession).FReceivedCommandDataStream.Position + Size;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
	aaWriteToLog(
		'Server: receive modified blob values - loading data ok, End Position = '+
			IntToStr(TACRServerSession(FSession).FReceivedCommandDataStream.Position)
			+ ', LocalBLOBStream.Size = '+IntToStr(LocalBLOBStream.Size));
{$ENDIF}
	end;
finally
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
	aaWriteToLog('Server: receive modified blob values - closing blob ... ');
{$ENDIF}
	FLocalCursor.InternalCloseBLOB(FieldNumber);
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
	aaWriteToLog('Server: receive modified blob values - blob closed ok');
{$ENDIF}
end;
end;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
aaWriteToLog('Server: receive modified blob values - ok');
{$ENDIF}
end; // ReceiveModifiedBLOBValues

//------------------------------------------------------------------------------
// Create old and new field values
//------------------------------------------------------------------------------
procedure TACRServerCursor.CreateOldNewFieldValues;
var
	i: Integer;
begin
FreeOldNewFieldValues;
SetLength(FOldFieldValues,FLocalCursor.VisibleFieldDefs.Count);
SetLength(FNewFieldValues,FLocalCursor.VisibleFieldDefs.Count);
for i := 0 to FLocalCursor.VisibleFieldDefs.Count-1 do
begin
FOldFieldValues[i] := TACRVariant.Create;
FNewFieldValues[i] := TACRVariant.Create;
end;
end; // CreateOldNewFieldValues

//------------------------------------------------------------------------------
// Free old and new field values
//------------------------------------------------------------------------------
procedure TACRServerCursor.FreeOldNewFieldValues;
var
	i: Integer;
begin
if (FOldFieldValues <> nil) then
	try
		for i := 0 to High(FOldFieldValues) do
			FOldFieldValues[i].Free;
	finally
		FOldFieldValues := nil;
	end;
if (FNewFieldValues <> nil) then
	try
		for i := 0 to High(FNewFieldValues) do
			FNewFieldValues[i].Free;
	finally
		FNewFieldValues := nil;
	end;
end; // FreeOldNewFieldValues

//------------------------------------------------------------------------------
// Save field values
//------------------------------------------------------------------------------
procedure TACRServerCursor.SaveValues(var Values: TACRArrayOfTACRVariant);
var
	i: Integer;
begin
for i := 0 to FLocalCursor.VisibleFieldDefs.Count-1 do
	FLocalCursor.GetFieldValue(Values[i],i,False,True);
end; // SaveValues

//------------------------------------------------------------------------------
// Clear values
//------------------------------------------------------------------------------
procedure TACRServerCursor.ClearValues(var Values: TACRArrayOfTACRVariant);
var
	i: Integer;
begin
for i := Low(Values) to High(Values) do
	Values[i].Clear;
end; // ClearValues

//------------------------------------------------------------------------------
// do before insert record
//------------------------------------------------------------------------------
function TACRServerCursor.DoBeforeInsertRecord: Boolean;
var
	TableName: AnsiString;
begin
{ TODO -oLeo : make it unicode??? or not? }
Result := False;
TableName := FLocalCursor.TableName;
FSession.DoBeforeInsertRecord(Pointer(Self),TableName,FNewFieldValues,Result);
Result := not Result;
end; // DoBeforeInsertRecord

//------------------------------------------------------------------------------
// do after insert record
//------------------------------------------------------------------------------
procedure TACRServerCursor.DoAfterInsertRecord;
var
	TableName: AnsiString;
begin
TableName := FLocalCursor.TableName;
FSession.DoAfterInsertRecord(Pointer(Self),TableName,FNewFieldValues);
end; // DoAfterInsertRecord

//------------------------------------------------------------------------------
// do before update record
//------------------------------------------------------------------------------
function TACRServerCursor.DoBeforeUpdateRecord: Boolean;
var
	TableName: AnsiString;
begin
Result := False;
TableName := FLocalCursor.TableName;
FSession.DoBeforeUpdateRecord(Pointer(Self),TableName,FOldFieldValues,
	FNewFieldValues,Result);
Result := not Result;
end; // DoBeforeUpdateRecord

//------------------------------------------------------------------------------
// do after Update record
//------------------------------------------------------------------------------
procedure TACRServerCursor.DoAfterUpdateRecord;
var
	TableName: AnsiString;
begin
TableName := FLocalCursor.TableName;
FSession.DoAfterUpdateRecord(Pointer(Self),TableName,FOldFieldValues,
	FNewFieldValues);
end; // DoAfterUpdateRecord

//------------------------------------------------------------------------------
// do before delete record
//------------------------------------------------------------------------------
function TACRServerCursor.DoBeforeDeleteRecord: Boolean;
var
	TableName: AnsiString;
begin
Result := False;
TableName := FLocalCursor.TableName;
FSession.DoBeforeDeleteRecord(Pointer(Self),TableName,FOldFieldValues,Result);
Result := not Result;
end; // DoBeforeDeleteRecord

//------------------------------------------------------------------------------
// do after delete record
//------------------------------------------------------------------------------
procedure TACRServerCursor.DoAfterDeleteRecord;
var
	TableName: AnsiString;
begin
TableName := FLocalCursor.TableName;
FSession.DoAfterDeleteRecord(Pointer(Self),TableName,FOldFieldValues);
end; // DoAfterDeleteRecord

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerCursor.Create(aCursor: TACRLocalCursor;
	aCursorID: TACRObjectID; aSession: TACRServerSession; aQuery: TACRQuery);
var
	MinRecords, MaxRecords: Integer;
begin
FLocalCursor := aCursor;
FCursorID := aCursorID;
FSession := aSession;
FQuery := aQuery;
FForcedDestroy := False;
MinRecords := ACRGetRecordCountByBufferSize(aSession.MinCacheSize,
	aCursor.RecordSize);
if (MinRecords <= 0) then
	MinRecords := 1;
MaxRecords := ACRGetRecordCountByBufferSize(aSession.MaxCacheSize,
	aCursor.RecordSize);
if (MaxRecords <= 0) then
	MaxRecords := 1;
FCache := TACRServerRecordCache.Create(MinRecords,MaxRecords,Self,aCursor);
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerCursor.Destroy;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRServerCursor.Destroy starting .... '+ 'Session = '+IntToStr
		(Integer(Session))+ ', FLocalCursor = '+IntToStr(Integer(FLocalCursor))
		+ ', FQuery = '+IntToStr(Integer(FQuery))+#13#10);
if (FSession <> nil) then
	aaWriteToLog('TACRServerCursor.Destroy starting ... SessionID = '+IntToStr
			(FSession.SessionID));
{$ENDIF}
if (FCache <> nil) then
	try
		FCache.Free;
		FCache := nil;
	except
	end;
try
	ResetRange(True);
except
end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRServerCursor.Destroy ResetRange ok! ');
{$ENDIF}
try
	FreeOldNewFieldValues;
except
end;
try
	if (FQuery <> nil) then
	begin
	if (Query.Handle <> nil) then
		if (Query.Handle is TACRLocalCursor) then
		begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
		aaWriteToLog
			('TACRServerCursor.Destroy  setting handle.DoNotUnlockTable... ');
{$ENDIF}
		TACRLocalCursor(Query.Handle).DoNotUnlockTable := FForcedDestroy;
{$IFDEF DEBUG_LOG_COMMUNICATION}
		aaWriteToLog(
			'TACRServerCursor.Destroy  setting handle.DoNotUnlockTable... OK');
{$ENDIF}
		end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('TACRServerCursor.Destroy  destroying Query... ');
{$ENDIF}
	FSession.RemoveQueryFromQueryList(FQuery);
	FQuery.Free;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('TACRServerCursor.Destroy  destroying Query... OK');
{$ENDIF}
	end
	else
	begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog(
		'TACRServerCursor.Destroy setting LocalCursor.DoNotUnlockTable ... ');
	aaWriteToLog('TACRServerCursor.Destroy TableName = '+FLocalCursor.TableName);
{$ENDIF}
	FLocalCursor.DoNotUnlockTable := FForcedDestroy;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('TACRServerCursor.Destroy  destroying LocalCursor... ');
{$ENDIF}
	FLocalCursor.Free;
{$IFDEF DEBUG_LOG_COMMUNICATION}
	aaWriteToLog('TACRServerCursor.Destroy  destroying LocalCursor... OK');
{$ENDIF}
	end;
except
end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRServerCursor.Destroy starting inherited');
{$ENDIF}
try
	inherited;
except
end;
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRServerCursor.Destroy  finished');
{$ENDIF}
end; // Destroy

//------------------------------------------------------------------------------
// apply default values
//------------------------------------------------------------------------------
procedure TACRServerCursor.ApplyDefaultValues;
begin
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
    // read source buffer
	ReceiveRecordBuffer(10993,FCurrentRecordBuffer);
    // update buffer and send it
	FLocalCursor.InternalInitRecord(FCurrentRecordBuffer,True);
	SendRecordBuffer(10994,FCurrentRecordBuffer);
	FSession.SendCommand;
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
end;
end; // ApplyDefaultValues

//------------------------------------------------------------------------------
// apply default values
//------------------------------------------------------------------------------
procedure TACRServerCursor.GetRecordCount;
var
	RecordNo: TACRRecordNo;
begin
RecordNo := FLocalCursor.GetRecordCount;
SaveDataToStream(RecordNo,SizeOf(RecordNo),FSession.FSentCommandDataStream,
	11005);
FSession.SendCommand;
end; // GetRecordCount

//------------------------------------------------------------------------------
// get record buffer
//------------------------------------------------------------------------------
procedure TACRServerCursor.GetRecordBuffer;
var
	bool: ByteBool;
	GetRecordMode: TACRGetRecordMode;
	GetRecordResult: TACRGetRecordResult;
	RecordID: TACRRecordID;
	IndexID: TACRObjectID;
begin
LoadDataFromStream(GetRecordMode,SizeOf(GetRecordMode),
	FSession.FReceivedCommandDataStream,11006);
LoadDataFromStream(bool,SizeOf(bool),FSession.FReceivedCommandDataStream,11007);
LocalCursor.FirstPosition := bool;
LoadDataFromStream(bool,SizeOf(bool),FSession.FReceivedCommandDataStream,11008);
LocalCursor.LastPosition := bool;
LoadDataFromStream(RecordID,SizeOf(RecordID),
	FSession.FReceivedCommandDataStream,11009);
LocalCursor.CurrentRecordID := RecordID;
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11090);
LocalCursor.IndexID := IndexID;
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	LocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
    // update buffer and send it
	GetRecordResult := FLocalCursor.GetRecordBuffer(GetRecordMode);
	SaveDataToStream(GetRecordResult,SizeOf(GetRecordResult),
		FSession.FSentCommandDataStream,11010);
	bool := LocalCursor.FirstPosition;
	SaveDataToStream(bool,SizeOf(bool),FSession.FSentCommandDataStream,11134);
	bool := LocalCursor.LastPosition;
	SaveDataToStream(bool,SizeOf(bool),FSession.FSentCommandDataStream,11135);
	RecordID := LocalCursor.CurrentRecordID;
	SaveDataToStream(RecordID,SizeOf(RecordID),FSession.FSentCommandDataStream,
		11136);
	if (GetRecordResult = grrOK) then
		SendRecordBuffer(11011,FCurrentRecordBuffer);
	FSession.SendCommand;
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
end;
end; // GetRecordBuffer

//------------------------------------------------------------------------------
// load records to client cache
//------------------------------------------------------------------------------
procedure TACRServerCursor.LoadRecords;
var
	b: Byte;
	bool: ByteBool;
	GetRecordMode: TACRGetRecordMode;
	GetRecordResult: TACRGetRecordResult;
	RecordID: TACRRecordID;
	IndexID: TACRObjectID;
	i: Integer;
begin
LoadDataFromStream(GetRecordMode,SizeOf(GetRecordMode),
	FSession.FReceivedCommandDataStream,12238);
LoadDataFromStream(bool,SizeOf(bool),FSession.FReceivedCommandDataStream,11007);
LocalCursor.FirstPosition := bool;
LoadDataFromStream(bool,SizeOf(bool),FSession.FReceivedCommandDataStream,11008);
LocalCursor.LastPosition := bool;
LoadDataFromStream(RecordID,SizeOf(RecordID),
	FSession.FReceivedCommandDataStream,11009);
LocalCursor.CurrentRecordID := RecordID;
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11090);
LocalCursor.IndexID := IndexID;
LoadDataFromStream(i,SizeOf(i),FSession.FReceivedCommandDataStream,12337);
FCache.NumRecords := i;
LoadDataFromStream(bool,SizeOf(bool),FSession.FReceivedCommandDataStream,12359);
if (bool) then
begin
FLocalCursor.DisableRecordBitmap;
end;
FLocalCursor.LockTable(False);
try
	FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
	try
		FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
		GetRecordResult := FCache.Load(GetRecordMode);
		SaveDataToStream(GetRecordResult,SizeOf(GetRecordResult),
			FSession.SentCommandDataStream,12328);
		bool := FLocalCursor.FirstPosition;
		SaveDataToStream(bool,SizeOf(bool),FSession.SentCommandDataStream,12329);
		bool := FLocalCursor.LastPosition;
		SaveDataToStream(bool,SizeOf(bool),FSession.SentCommandDataStream,12330);
		SaveDataToStream(FLocalCursor.CurrentRecordID,
			SizeOf(FLocalCursor.CurrentRecordID),FSession.SentCommandDataStream,
			12331);
		if (GetRecordResult <> grrError) then
		begin
		FState := LocalCursor.GetTableState;
		FCache.SetState(FState);
		FCache.SaveToStream(FSession.SentCommandDataStream);
		end;
		FSession.SendCommand;
	finally
		FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
		FLocalCursor.CurrentRecordBuffer := nil;
		FCache.ResizeCache(0);
	end;
finally
	FLocalCursor.UnlockTable(False);
end;
end; // LoadRecords

//------------------------------------------------------------------------------
// set RecNo
//------------------------------------------------------------------------------
procedure TACRServerCursor.SetRecNo;
var
	RecNo: TACRRecordNo;
	RecordID: TACRRecordID;
	IndexID: TACRObjectID;
begin
LoadDataFromStream(RecNo,SizeOf(RecNo),FSession.FReceivedCommandDataStream,
	11020);
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11091);
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	FCache.SetRecNo(RecNo,IndexID);
	FCache.SaveToStream(FSession.SentCommandDataStream);
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
	FLocalCursor.CurrentRecordBuffer := nil;
	FCache.ResizeCache(0);
end;
FSession.SendCommand;
{
  LocalCursor.IndexID := IndexID;
  LocalCursor.SetRecNo(Value);
  RecordID := LocalCursor.CurrentRecordID;
  SaveDataToStream(RecordID,SizeOf(RecordID),FSession.FSentCommandDataStream,11021);
  FSession.SendCommand;
}
end; // SetRecNo


//------------------------------------------------------------------------------
// get RecNo
//------------------------------------------------------------------------------
{
procedure TACRServerCursor.GetRecNo;
var Value:    Int64;
    RecordID: TACRRecordID;
    IndexID:  TACRObjectID;
begin
  LoadDataFromStream(RecordID,SizeOf(RecordID),FSession.FReceivedCommandDataStream,11022);
  LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,11092);
  LocalCursor.IndexID := IndexID;
  LocalCursor.FirstPosition := False;
  LocalCursor.LastPosition := False;
  LocalCursor.CurrentRecordID := RecordID;
  Value := LocalCursor.GetRecNo;
  SaveDataToStream(Value,SizeOf(Value),FSession.FSentCommandDataStream,11023);
  FSession.SendCommand;
end; // GetRecNo
}

//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
procedure TACRServerCursor.InternalEdit;
var
	RecordID: TACRRecordID;
	GetRecordResult: TACRGetRecordResult;
begin
{$IFDEF DEBUG_LOG_SERVER_INTERNAL_EDIT}
aaWriteToLog('> TACRServerCursor.InternalEdit');
{$ENDIF}
LoadDataFromStream(RecordID,SizeOf(RecordID),
	FSession.FReceivedCommandDataStream,11048);
LocalCursor.FirstPosition := False;
LocalCursor.LastPosition := False;
LocalCursor.CurrentRecordID := RecordID;
{$IFDEF DEBUG_LOG_SERVER_INTERNAL_EDIT}
aaWriteToLog(
	'1 TACRServerCursor.InternalEdit, RecordID (PageNo . PageItemNo) = ('+IntToStr
		(RecordID.PageNo)+' . '+IntToStr(RecordID.PageItemNo)+')');
{$ENDIF}
LocalCursor.InternalEdit;
{$IFDEF DEBUG_LOG_SERVER_INTERNAL_EDIT}
aaWriteToLog('2 TACRServerCursor.InternalEdit');
{$ENDIF}
if (FSession.IsBeforeUpdateRecordAssigned or FSession.
		IsAfterUpdateRecordAssigned) then
begin
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	LocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
      // update buffer and send it
	GetRecordResult := FLocalCursor.GetRecordBuffer(grmCurrent);
	if (GetRecordResult = grrOK) then
		SaveValues(FOldFieldValues);
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
end;
end;
{$IFDEF DEBUG_LOG_SERVER_INTERNAL_EDIT}
aaWriteToLog('3 TACRServerCursor.InternalEdit');
{$ENDIF}
FSession.SendCommand;
{$IFDEF DEBUG_LOG_SERVER_INTERNAL_EDIT}
aaWriteToLog('< TACRServerCursor.InternalEdit');
{$ENDIF}
end; // InternalEdit


//------------------------------------------------------------------------------
// cancel record
//------------------------------------------------------------------------------
procedure TACRServerCursor.InternalCancel;
var
  	RecordID:   TACRRecordID;
	  b:          ByteBool;
begin
  LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11050);
  LoadDataFromStream(RecordID,SizeOf(RecordID), FSession.FReceivedCommandDataStream,11051);
  LocalCursor.FirstPosition := False;
  LocalCursor.LastPosition := False;
  LocalCursor.CurrentRecordID := RecordID;
	FCurrentRecordBuffer := LocalCursor.AllocateRecordBuffer;
  try
  	LocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
    LocalCursor.GetRecordBuffer(grmCurrent);
    LocalCursor.InternalCancel(b);
  finally
		LocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
  end;
  if (FSession.IsBeforeUpdateRecordAssigned or FSession.
      IsAfterUpdateRecordAssigned) then
    ClearValues(FOldFieldValues);
  FSession.SendCommand;
end; // InternalCancel


//------------------------------------------------------------------------------
// post record
//------------------------------------------------------------------------------
procedure TACRServerCursor.InternalPost;
var
	RecordID: TACRRecordID;
	b: ByteBool;
	ToInsert: Boolean;
	IndexID: TACRObjectID;
	bOK: Boolean;
	s: WideString;
	RecNo,recCount: TACRRecordNo;
	bReloadCache: Boolean;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
aaIncCounter(counter7);
aaStartTime(time7);
aaStartTime(time8);
try
{$ENDIF}
	bOK := True;
	bReloadCache := not FCache.Loaded;
	LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11052);
	ToInsert := b;
	LoadDataFromStream(RecordID,SizeOf(RecordID),
		FSession.FReceivedCommandDataStream,11053);
	LocalCursor.CurrentRecordID := RecordID;
	LoadDataFromStream(IndexID,SizeOf(IndexID),
		FSession.FReceivedCommandDataStream,11097);
	LocalCursor.IndexID := IndexID;
	FCurrentRecordBuffer := LocalCursor.AllocateRecordBuffer;
	FEditRecordBuffer := LocalCursor.AllocateRecordBuffer;
	try
		try
			ReceiveRecordBuffer(11054,FCurrentRecordBuffer);
			LocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
			LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11055);
			if (b) then
				LocalCursor.EditRecordBuffer := nil
			else
			begin
			ReceiveRecordBuffer(11056,FEditRecordBuffer);
			LocalCursor.EditRecordBuffer := FEditRecordBuffer;
			end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
			aaStartTime(time9);
{$ENDIF}
			ReceiveModifiedBLOBValues(ToInsert);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
			aaStopTime(time9);
{$ENDIF}
			if ((FSession.IsBeforeInsertRecordAssigned or FSession.
						IsAfterInsertRecordAssigned) and (ToInsert)) or
				((FSession.IsBeforeUpdateRecordAssigned or FSession.
						IsAfterUpdateRecordAssigned) and (not ToInsert)) then
				SaveValues(FNewFieldValues);
			try
				if ((ToInsert) and FSession.IsBeforeInsertRecordAssigned) then
					bOK := DoBeforeInsertRecord;
				if ((not ToInsert) and FSession.IsBeforeUpdateRecordAssigned) then
					bOK := DoBeforeUpdateRecord;
				if (bOK) then
				begin
				if (not bReloadCache) then
				begin
				FState := LocalCursor.GetTableState;
				bReloadCache := (FState.TableState <> FCache.state.TableState);
				end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
				aaStopTime(time8);
				aaIncCounter(counter10);
				aaStartTime(time10);
{$ENDIF}
				LocalCursor.InternalPost(ToInsert);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
				aaStopTime(time10);
				aaStartTime(time11);
{$ENDIF}
				if ((ToInsert) and FSession.IsAfterInsertRecordAssigned) then
					DoAfterInsertRecord;
				if ((not ToInsert) and FSession.IsAfterUpdateRecordAssigned) then
					DoAfterUpdateRecord;
				end;
			finally
				if ((FSession.IsBeforeInsertRecordAssigned or FSession.
							IsAfterInsertRecordAssigned) and (ToInsert)) then
					ClearValues(FNewFieldValues);
				if ((FSession.IsBeforeUpdateRecordAssigned or FSession.
							IsAfterUpdateRecordAssigned) and (not ToInsert)) then
				begin
				ClearValues(FNewFieldValues);
				ClearValues(FOldFieldValues);
				end;
			end; // LocalCursor.Post
			if (not bOK) then
			begin
			if (ToInsert) then
				s := ErrorLInsertRecordBlockedByDatabaseEvent
			else
				s := ErrorLUpdateRecordBlockedByDatabaseEvent;
			FSession.SendErrorMessage(ACR_CS_ErrorInternalPostFailed,
				Format(ErrorL_CS_ErrorInternalPostFailed,[s]));
			Exit;
			end;
			if (LocalCursor.ErrorCode <> ACR_ERR_OK) then
			begin
			LocalCursor.ClearBLOBStreams(False);
			raise EACRException.Create(11234,ErrorLPostFailed,
				[LocalCursor.ErrorMessage]);
			end;
			b := LocalCursor.FirstPosition;
			SaveDataToStream(b,SizeOf(b),FSession.FSentCommandDataStream,11057);
			b := LocalCursor.LastPosition;
			SaveDataToStream(b,SizeOf(b),FSession.FSentCommandDataStream,11058);
			RecordID := LocalCursor.CurrentRecordID;
			SaveDataToStream(RecordID,SizeOf(RecordID),
				FSession.FSentCommandDataStream,11059);
			b := bReloadCache;
			RecNo := LocalCursor.GetRecNo;
			recCount := LocalCursor.GetRecordCount;
			FState := LocalCursor.GetTableState;
			FCache.SetState(FState);
			SaveDataToStream(b,SizeOf(b),FSession.FSentCommandDataStream,12339);
			SaveDataToStream(FState,SizeOf(FState),FSession.FSentCommandDataStream,
				12348);
			SaveDataToStream(RecNo,SizeOf(RecNo),FSession.FSentCommandDataStream,
				12332);
			SaveDataToStream(recCount,SizeOf(recCount),
				FSession.FSentCommandDataStream,12333);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
			aaStopTime(time11);
			aaIncCounter(counter12);
			aaStartTime(time12);
{$ENDIF}
			SendRecordBuffer(11060,FCurrentRecordBuffer);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
			aaStopTime(time12);
{$ENDIF}
		except
			on e: Exception do
			begin
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
			aaIncCounter(counter14);
{$ENDIF}
			FSession.SendErrorMessage(ACR_CS_ErrorInternalPostFailed,
				Format(ErrorL_CS_ErrorInternalPostFailed,[e.Message]));
			Exit;
			end;
		end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
		aaIncCounter(counter13);
		aaStartTime(time13);
{$ENDIF}
		FSession.SendCommand;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
		aaStopTime(time13);
{$ENDIF}
	finally
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
		aaIncCounter(counter14);
		aaStartTime(time14);
{$ENDIF}
		LocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
		LocalCursor.FreeRecordBuffer(FEditRecordBuffer);
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
		aaStopTime(time14);
{$ENDIF}
	end;
{$IFDEF DEBUG_LOG_COMMUNICATION_TIMES_SERVER}
finally
	aaStopTime(time8);
	aaStopTime(time7);
end;
{$ENDIF}
end; // InternalPost

//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TACRServerCursor.InternalDelete;
var
	RecordID: TACRRecordID;
	b: ByteBool;
	IndexID: TACRObjectID;
	bOK: Boolean;
	RecNo,recCount: TACRRecordNo;
	bReloadCache: Boolean;
begin
bOK := True;
bReloadCache := not FCache.Loaded;
LoadDataFromStream(RecordID,SizeOf(RecordID),
	FSession.FReceivedCommandDataStream,11061);
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11098);
LocalCursor.IndexID := IndexID;
LocalCursor.FirstPosition := False;
LocalCursor.LastPosition := False;
LocalCursor.CurrentRecordID := RecordID;
FCurrentRecordBuffer := LocalCursor.AllocateRecordBuffer;
try
	LocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	Move(RecordID,PAnsiChar(FCurrentRecordBuffer + LocalCursor.BookmarkOffset)^,
		SizeOf(TACRRecordID));
	if (FSession.IsBeforeDeleteRecordAssigned or FSession.
			IsAfterDeleteRecordAssigned) then
	begin
	if (LocalCursor.GetRecordBuffer(grmCurrent) = grrOK) then
		SaveValues(FOldFieldValues);
	end;
	try
		if (FSession.IsBeforeDeleteRecordAssigned) then
			bOK := DoBeforeDeleteRecord;
		if (bOK) then
		begin
		if (not bReloadCache) then
		begin
		FState := LocalCursor.GetTableState;
		bReloadCache := (FState.TableState <> FCache.state.TableState);
		end;
		LocalCursor.InternalDelete;
		if (FSession.IsAfterDeleteRecordAssigned) then
			DoAfterDeleteRecord;
		end;
	finally
		ClearValues(FOldFieldValues);
	end;
	if (not bOK) then
	begin
	FSession.SendErrorMessage(ACR_CS_ErrorInternalPostFailed,
		Format(ErrorL_CS_ErrorInternalPostFailed,[
				ErrorLDeleteRecordBlockedByDatabaseEvent]));
	Exit;
	end;
	b := LocalCursor.FirstPosition;
	SaveDataToStream(b,SizeOf(b),FSession.FSentCommandDataStream,11062);
	b := LocalCursor.LastPosition;
	SaveDataToStream(b,SizeOf(b),FSession.FSentCommandDataStream,11063);
	RecordID := LocalCursor.CurrentRecordID;
	SaveDataToStream(RecordID,SizeOf(RecordID),FSession.FSentCommandDataStream,
		11064);
	b := bReloadCache;
	RecNo := LocalCursor.GetRecNo;
	recCount := LocalCursor.GetRecordCount;
	FState := LocalCursor.GetTableState;
	FCache.SetState(FState);
	SaveDataToStream(b,SizeOf(b),FSession.FSentCommandDataStream,12345);
	SaveDataToStream(FState,SizeOf(FState),FSession.FSentCommandDataStream,12350);
	SaveDataToStream(RecNo,SizeOf(RecNo),FSession.FSentCommandDataStream,12346);
	SaveDataToStream(recCount,SizeOf(recCount),FSession.FSentCommandDataStream,
		12347);
	if ((RecNo >= 0) and (recCount >= 0)) then
	begin
	LocalCursor.GetRecordBuffer(grmCurrent);
	SendRecordBuffer(11065,FCurrentRecordBuffer);
	end;
	FSession.SendCommand;
finally
	LocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
end;
end; // InternalDelete

//------------------------------------------------------------------------------
// Activate filters
//------------------------------------------------------------------------------
procedure TACRServerCursor.ActivateFilters;
var
	FilterText: WideString;
	b: ByteBool;
	PartialKey: Boolean;
	CaseInsensitive: Boolean;
begin
LoadWideStringFromStream(FilterText,FSession.FReceivedCommandDataStream,11077);
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11079);
CaseInsensitive := b;
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11080);
PartialKey := b;
LocalCursor.ActivateFilters(FilterText,CaseInsensitive,PartialKey);
LocalCursor.FirstPosition := True;
LocalCursor.LastPosition := False;
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	FCache.Load(grmNext);
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
	FLocalCursor.CurrentRecordBuffer := nil;
end;
FCache.SaveToStream(FSession.FSentCommandDataStream);
FSession.SendCommand;
end; // ActivateFilters

//------------------------------------------------------------------------------
// Deactivate filters
//------------------------------------------------------------------------------
procedure TACRServerCursor.DeactivateFilters;
begin
LocalCursor.DeactivateFilters;
LocalCursor.FirstPosition := True;
LocalCursor.LastPosition := False;
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	FCache.Load(grmNext);
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
	FLocalCursor.CurrentRecordBuffer := nil;
end;
FCache.SaveToStream(FSession.FSentCommandDataStream);
FSession.SendCommand;
end; // DeactivateFilters

//------------------------------------------------------------------------------
// Locate record
//------------------------------------------------------------------------------
procedure TACRServerCursor.Locate;
var
	RecordID: TACRRecordID;
	b: ByteBool;
	IndexID: TACRObjectID;
	i,ArrLen: Integer;
	KeyFields: WideString;
	CaseInsensitive: Boolean;
	PartialKey: Boolean;
	v: TACRVariant;
	KeyValues: Variant;
begin
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11114);
LoadWideStringFromStream(KeyFields,FSession.FReceivedCommandDataStream,11115);
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11117);
CaseInsensitive := b;
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11118);
PartialKey := b;
LoadDataFromStream(ArrLen,SizeOf(ArrLen),FSession.FReceivedCommandDataStream,
	11119);
v := TACRVariant.Create;
try
	if (ArrLen = 1) then
	begin
	v.LoadFromStream(FSession.FReceivedCommandDataStream);
	KeyValues := v.AsVariant;
	end
	else
	begin
	KeyValues := VarArrayCreate([0, (ArrLen-1)], varVariant);
	for i := 0 to ArrLen-1 do
	begin
	v.LoadFromStream(FSession.FReceivedCommandDataStream);
{$IFDEF D6H}
	VarArrayPut(KeyValues,v.AsVariant,i);
{$ELSE}
	KeyValues[i] := v.AsVariant;
{$ENDIF}
	end;
	end;
finally
	v.Free;
end;
LocalCursor.IndexID := IndexID;
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	LocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	b := LocalCursor.Locate(KeyFields,KeyValues,CaseInsensitive,PartialKey);
	if (b) then
	begin
	FSession.FSentCommandHeader.Reply := accrplYes;
	RecordID := LocalCursor.CurrentRecordID;
	SaveDataToStream(RecordID,SizeOf(RecordID),FSession.FSentCommandDataStream,
		11120);
	SendRecordBuffer(11121,FCurrentRecordBuffer);
	end
	else
	begin
	FSession.FSentCommandHeader.Reply := accrplNo;
	end;
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
end;
FSession.SendCommand;
end; // Locate

//------------------------------------------------------------------------------
// Find record by key
//------------------------------------------------------------------------------
procedure TACRServerCursor.FindKey;
var
	RecordID: TACRRecordID;
	b: ByteBool;
	IndexID: TACRObjectID;
	KeyFieldCount: Integer;
	sc: Byte;
	SearchCondition: TACRSearchCondition;
begin
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11124);
LoadDataFromStream(sc,SizeOf(sc),FSession.FReceivedCommandDataStream,11125);
SearchCondition := TACRSearchCondition(sc);
LoadDataFromStream(KeyFieldCount,SizeOf(KeyFieldCount),
	FSession.FReceivedCommandDataStream,11126);
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	FLocalCursor.IndexID := IndexID;
	FLocalCursor.KeyBuffer := FCurrentRecordBuffer;
	FLocalCursor.KeyFieldCount := KeyFieldCount;
	ReceiveRecordBuffer(11127,FCurrentRecordBuffer);
	b := FLocalCursor.FindKey(SearchCondition);
	if (b) then
	begin
	FSession.FSentCommandHeader.Reply := accrplYes;
	RecordID := LocalCursor.CurrentRecordID;
	SaveDataToStream(RecordID,SizeOf(RecordID),FSession.FSentCommandDataStream,
		11128);
	end
	else
		FSession.FSentCommandHeader.Reply := accrplNo;
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
end;
FSession.SendCommand;
end; // FindKey

//------------------------------------------------------------------------------
// Reset range
//------------------------------------------------------------------------------
procedure TACRServerCursor.ResetRange(DoNotSendReply: Boolean);
var
	StartBuffer,EndBuffer: TACRRecordBuffer;
begin
StartBuffer := FLocalCursor.RangeStartBuffer;
EndBuffer := FLocalCursor.RangeEndBuffer;
if (StartBuffer <> nil) then
	FLocalCursor.FreeRecordBuffer(StartBuffer);
if (EndBuffer <> nil) then
	FLocalCursor.FreeRecordBuffer(EndBuffer);
FLocalCursor.ResetRange;
if (not DoNotSendReply) then
begin
LocalCursor.FirstPosition := True;
LocalCursor.LastPosition := False;
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	FCache.Load(grmNext);
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
	FLocalCursor.CurrentRecordBuffer := nil;
end;
FCache.SaveToStream(FSession.FSentCommandDataStream);
FSession.SendCommand;
end;
end; // ResetRange

//------------------------------------------------------------------------------
// Apply range
//------------------------------------------------------------------------------
procedure TACRServerCursor.ApplyRange;
var
	StartBuffer, EndBuffer: TACRRecordBuffer;
	StartKeyFieldCount: Integer;
	EndKeyFieldCount: Integer;
	StartExclusive: Boolean;
	EndExclusive: Boolean;
	b: ByteBool;
	IndexID: TACRObjectID;
begin
ResetRange(True); // free old buffers
LoadDataFromStream(IndexID,SizeOf(IndexID),FSession.FReceivedCommandDataStream,
	11130);
FLocalCursor.IndexID := IndexID;
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11131);
StartExclusive := b;
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11132);
EndExclusive := b;
LoadDataFromStream(StartKeyFieldCount,SizeOf(StartKeyFieldCount),
	FSession.FReceivedCommandDataStream,11133);
LoadDataFromStream(EndKeyFieldCount,SizeOf(EndKeyFieldCount),
	FSession.FReceivedCommandDataStream,11134);
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11135);
if (b) then
begin
StartBuffer := nil;
end
else
begin
StartBuffer := FLocalCursor.AllocateRecordBuffer;
ReceiveRecordBuffer(11136,StartBuffer);
end;
LoadDataFromStream(b,SizeOf(b),FSession.FReceivedCommandDataStream,11137);
if (b) then
begin
EndBuffer := nil;
end
else
begin
EndBuffer := FLocalCursor.AllocateRecordBuffer;
ReceiveRecordBuffer(11138,EndBuffer);
end;
FLocalCursor.ApplyRange(StartBuffer,EndBuffer,StartKeyFieldCount,
	EndKeyFieldCount,StartExclusive,EndExclusive);
LocalCursor.FirstPosition := True;
LocalCursor.LastPosition := False;
FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
try
	FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
	FCache.Load(grmNext);
finally
	FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
	FLocalCursor.CurrentRecordBuffer := nil;
end;
FCache.SaveToStream(FSession.FSentCommandDataStream);
FSession.SendCommand;
end; // ApplyRange

//------------------------------------------------------------------------------
// read blob value
//------------------------------------------------------------------------------
procedure TACRServerCursor.ReadBLOBValue;
var
	FieldNumber: Integer;
	LocalBLOBStream: TACRStream;
	Size: Int64;
	RecordID: TACRRecordID;
begin
try
	LoadDataFromStream(FieldNumber,SizeOf(FieldNumber),
		FSession.FReceivedCommandDataStream,11217);
	LoadDataFromStream(RecordID,SizeOf(TACRRecordID),
		FSession.FReceivedCommandDataStream,12452);
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
	aaWriteToLog('Server: read blob value, fieldNo = '+IntToStr(FieldNumber)
			+ ', pageno = '+IntToStr(FLocalCursor.CurrentRecordID.PageNo)
			+ ', pageitemno = '+IntToStr(FLocalCursor.CurrentRecordID.PageNo));
{$ENDIF}
	FCurrentRecordBuffer := FLocalCursor.AllocateRecordBuffer;
	try
		FLocalCursor.CurrentRecordBuffer := FCurrentRecordBuffer;
		Move(RecordID,FLocalCursor.CurrentRecordID,SizeOf(TACRRecordID));
      // return empty stream if there is no record (DBMemo field can try to read blob on empty table)
		if (FLocalCursor.GetRecordBuffer(grmCurrent) <> grrOK) then
		begin
        // record does not exist
		Size := 0;
		SaveDataToStream(Size,SizeOf(Size),FSession.FSentCommandDataStream,11632);
		end
		else
		begin
        // record exists
// commented in 4.40
{
      if (FLocalCursor.GetRecordBuffer(grmCurrent) <> grrOK) then
       raise EACRException.Create(11231,ErrorLLoadingRecord,
              [FLocalCursor.TableName,FLocalcursor.Session.SessionID,
              FLocalCursor.CurrentRecordID.PageNo,FLocalCursor.CurrentRecordID.PageItemNo]);
}
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
		aaWriteToLog('Server: read blob value - record loaded ok');
{$ENDIF}
		LocalBLOBStream := FLocalCursor.InternalCreateBlobStream(False,FieldNumber,
			bomRead);
		if (LocalBLOBStream = nil) then
			raise EACRException.Create(11218,ErrorLNilPointer);
		try
			Size := LocalBLOBStream.Size;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
			aaWriteToLog('Server: read blob value - blob stream created, size = '+
					IntToStr(Size));
{$ENDIF}
			SaveDataToStream(Size,SizeOf(Size),FSession.FSentCommandDataStream,11219);
			if (Size > 0) then
			begin
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
			aaWriteToLog('Server: read blob value - saving stream ... ');
{$ENDIF}
			LocalBLOBStream.SaveToStream(FSession.FSentCommandDataStream);
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
			aaWriteToLog('Server: read blob value - saving stream ... ok');
{$ENDIF}
			end;
		finally
			FLocalCursor.InternalCloseBLOB(FieldNumber);
		end;
		end; // record exists
	finally
		FLocalCursor.FreeRecordBuffer(FCurrentRecordBuffer);
	end;
except
	on e: Exception do
	begin
	FSession.SendErrorMessage(ACR_CS_ErrorReadBLOBValueFailed,
		Format(ErrorL_CS_ErrorReadBLOBValueFailed,[e.Message]));
	Exit;
	end;
end;
FSession.SendCommand;
{$IFDEF DEBUG_LOG_CLIENT_BLOB}
aaWriteToLog('Server: read blob value - ok');
{$ENDIF}
end; // ReadBLOBValue

//------------------------------------------------------------------------------
// return true if current record exists
//------------------------------------------------------------------------------
procedure TACRServerCursor.IsRecordExists;
var
	RecordID: TACRRecordID;
begin
FSession.FSentCommandHeader.Reply := accrplNo;
LoadDataFromStream(RecordID,SizeOf(RecordID),
	FSession.FReceivedCommandDataStream,11284);
LocalCursor.CurrentRecordID := RecordID;
if (LocalCursor.IsRecordExists) then
	FSession.FSentCommandHeader.Reply := accrplYes;
FSession.SendCommand;
end; // IsRecordExists

//------------------------------------------------------------------------------
// export table to SQL
//------------------------------------------------------------------------------
procedure TACRServerCursor.ExportTableToSQL;
var
	SQL: WideString;
	ExportStructure: Boolean;
	AddDropTableCommand: Boolean;
	ExportIndexes: Boolean;
	AddDropIndexCommand: Boolean;
	ExportData: Boolean;
	ExportBLOBFields: Boolean;
	UseBracketsForNames: Boolean;
	ExportForeignKeys: Boolean;
begin
try
	LoadBooleanFromStream(ExportStructure,
		TACRServerSession(FSession).FReceivedCommandDataStream,11735);
	LoadBooleanFromStream(AddDropTableCommand,
		TACRServerSession(FSession).FReceivedCommandDataStream,11736);
	LoadBooleanFromStream(ExportIndexes,
		TACRServerSession(FSession).FReceivedCommandDataStream,11737);
	LoadBooleanFromStream(AddDropIndexCommand,
		TACRServerSession(FSession).FReceivedCommandDataStream,11738);
	LoadBooleanFromStream(ExportData,
		TACRServerSession(FSession).FReceivedCommandDataStream,11739);
	LoadBooleanFromStream(ExportBLOBFields,
		TACRServerSession(FSession).FReceivedCommandDataStream,11740);
	LoadBooleanFromStream(UseBracketsForNames,
		TACRServerSession(FSession).FReceivedCommandDataStream,11741);
	LoadBooleanFromStream(ExportForeignKeys,
		TACRServerSession(FSession).FReceivedCommandDataStream,12133);
	SQL := LocalCursor.ExportTableToSQL(ExportStructure,AddDropTableCommand,
		ExportIndexes,AddDropIndexCommand,ExportData,ExportBLOBFields,
		UseBracketsForNames, ExportForeignKeys);
	SaveWideStringToStream(SQL,FSession.FSentCommandDataStream,11734);
except
	on e: Exception do
	begin
	FSession.SendErrorMessage(ACR_CS_ErrorExportTableToSQLFailed,
		Format(ErrorL_CS_ErrorExportTableToSQLFailed,[e.Message]));
	Exit;
	end;
end;
FSession.SendCommand;
end; // ExportTableToSQL

////////////////////////////////////////////////////////////////////////////////
//
// General functions
//
////////////////////////////////////////////////////////////////////////////////

function InstallingService: Boolean;
begin
Result := FindCmdLineSwitch('INSTALL',['-','\','/'],True) or FindCmdLineSwitch
	('UNINSTALL',['-','\','/'],True);
end;

function InteractiveService: Boolean;
begin
Result := (not FindCmdLineSwitch('NOINTERACT',['-','\','/'],True));
end;

initialization

ACRMemoryIncUseCount;

finalization

ACRMemoryDecUseCount;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRServer> initialized');
{$ENDIF}

end.


