unit ACRMain;

interface

{$WARNINGS OFF}
{$HINTS OFF}
{$I ACRVer.inc}

uses SysUtils, Classes, DB, IniFiles,
     Dialogs,
{$IFDEF MSWINDOWS}
     Windows, Forms, Controls,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     Messages,
     QForms,
     DBCommon,
{$ENDIF}

{$IFDEF D6H}
{$IFDEF MSWINDOWS}
     DBCommon,
{$ENDIF}
     Variants,
     SqlTimSt,
{$ENDIF}

{$IFDEF D12H}
     ACR_d12h,
{$ENDIF}
{$IFDEF D21H}
  System.Generics.Collections,
{$ENDIF}

{$IFDEF TRIAL_VERSION}
{$IFDEF MSWINDOWS}
 Registry, ACRDECUtil, ACRDecCipher, ACRDecFmt,
{$ENDIF}
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
//  Accuracer units
//
////////////////////////////////////////////////////////////////////////////////


     ACRTypesThread,
     ACRCriticalSection,
{$IFDEF LINUX}
     ACRLinux,
{$ENDIF}

{$IFDEF LOCAL_VERSION}
     ACRLocalEngine,
{$ENDIF}

{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}

{$IFDEF DEBUG_MEMCHECK}
     MemCheck,
{$ENDIF}

{$IFDEF CLIENT_VERSION}
     ACRClient,
{$ENDIF}
     ACRComMain,
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
{$IFNDEF SQLMEMTABLE}
     ACRCrypto,
{$ENDIF}

     ACRCompression,
     ACRTypes,
{$IFNDEF SQLMEMTABLE}
     ACRTypesNetwork,
{$ENDIF}
     ACRVariant,
     ACRConverts,
     ACRExcept,
     ACRSQLProcessor,
     ACRLexer,
     ACRConst,
 {$IFDEF DEBUG_LOG}
     ACRDebug,
 {$ENDIF}
     ACRMemory;       // UNIT ACRMemory MUST BE LAST !!!


const
  // TACRDataset flags
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

type
PDateTimeRec=^TDateTimeRec;

{$IFDEF LINUX}
  // Delphi7 Controls.pas
  TDate = type TDateTime;
  TTime = type TDateTime;
{$ENDIF}

{$IFNDEF D12H}
  TRecordBuffer = PAnsiChar;
{$ENDIF}

  // forward declarations
  TACRSession = class;
  TACRDatabase = class;
  TACRDataSet = class;
  TACRTable = class;
  TACRQuery = class;
//  TACRAntifreeze = class;
  TACRAdvFieldDefs = class;
  TACRForeignKeyDefs = class;
  TACRForeignKeyDef = class;
  TACRArrayOfTACRVariant = array of TACRVariant;

  TACRBackupInfo = record
   Date:                TDateTime;
   FileSize:            Int64;
   Description:         WideString;
   Encrypted:           Boolean;
   EncryptedByPassword: Boolean;
   TableCount:          Integer;
  end;
  
  TACRDatabaseOperation = (dbopCompact,dbopRepair,dbopCopy,dbopChangeDatabaseSettings,dbopBackup,dbopRestore);
  TACRBatchMode = (batAppend, batUpdate, batAppendUpdate, batCopy, batDelete);
  TACRTableOperation = (tbopImport,tbopExport,tbopCopy,
                        tbopRestructure,tbopRepair,
                        tbopBatchAppend, tbopBatchUpdate, tbopBatchAppendUpdate,
                        tbopBatchCopy, tbopBatchDelete
                        );

  TACRDatabaseProgress = procedure (
                                      Sender:     TComponent;
                                      Progress:   Double;
                                      Operation:  TACRDatabaseOperation;
                                      var Abort:  Boolean
                                   ) of object;

  TACRTableProgress = procedure (
                                      Sender:     TComponent;
                                      Progress:   Double;
                                      Operation:  TACRTableOperation;
                                      var Abort:  Boolean
                                   ) of object;

  TACROnClientReceiveTextMessage = procedure (const Text: AnsiString)  of object;
  TACROnClientReceiveUnicodeTextMessage = procedure (const Text: WideString)  of object;
  TACROnClientReceiveBinaryMessage = procedure (Buffer: PAnsiChar; Size: Integer) of object;
  TACROnClientReceiveStreamMessage = procedure (Stream: TStream) of object;

  TACROnError = procedure (
                       Sender:             TComponent;
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: AnsiString
                     ) of object;

  TACRBeforeInsertRecord = procedure (
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant;
                       var Abort:          Boolean
                     ) of object;
  TACRAfterInsertRecord = procedure (
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant
                     ) of object;

  TACRBeforeUpdateRecord = procedure (
                       Sender:                TACRDataset;
                       const TableName:       WideString;
                       const OldFieldValues:  TACRArrayOfTACRVariant;
                       const NewFieldValues:  TACRArrayOfTACRVariant;
                       var Abort:             Boolean
                     ) of object;
  TACRAfterUpdateRecord = procedure (
                       Sender:                TACRDataset;
                       const TableName:       WideString;
                       const OldFieldValues:  TACRArrayOfTACRVariant;
                       const NewFieldValues:  TACRArrayOfTACRVariant
                     ) of object;

  TACRBeforeDeleteRecord = procedure (
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant;
                       var Abort:          Boolean
                     ) of object;
  TACRAfterDeleteRecord = procedure (
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant
                     ) of object;

  TACRBeforeExecuteSQL = procedure (
                       Sender:             TACRQuery;
                       var Abort:          Boolean
                     ) of object;
  TACRAfterExecuteSQL = procedure (
                       Sender:             TACRQuery
                     ) of object;


////////////////////////////////////////////////////////////////////////////////
//
// TACRBlobStream
//
////////////////////////////////////////////////////////////////////////////////


  TACRBlobStream = class (TACRStream)
  private
    FBlobStream: TACRStream; 
    FField:      TBlobField;
    FDataSet:    TACRDataSet;
    FWideMemo:   Boolean;
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
    constructor Create(Field: TBlobField; Mode: TBlobStreamMode);
    destructor Destroy; override;
    procedure Truncate;
  public
   // Blob stream interface
  end; // TACRBlobStream



////////////////////////////////////////////////////////////////////////////////
//
// TACRSessionList
//
////////////////////////////////////////////////////////////////////////////////

  // global list of sessions
  TACRSessionList = class(TObject)
   private
    FSessions: TThreadList;
    FSessionNumbers: TBits;

    // adds session to list
    procedure AddSession(ASession: TACRSession);
    // closes all sessions
    procedure CloseAll;
    // Gets sessions count
    function GetCount: Integer;
    // Gets session by No
    function GetSession(Index: Integer): TACRSession;
    // gets current session
    function GetCurrentSession: TACRSession;
    // Gets session by Name
    function GetSessionByName(const SessionName: AnsiString): TACRSession;
    // Sets current session
    procedure SetCurrentSession(Value: TACRSession);

   public
    constructor Create;
    destructor Destroy; override;
    // Finds session by name
    function FindSession(const SessionName: AnsiString): TACRSession;
    // Gets list of sessions names
    procedure GetSessionNames(List: TStrings);
    // Opens session by name
    function OpenSession(const SessionName: AnsiString): TACRSession;

    property Count: Integer read GetCount;
    property CurrentSession: TACRSession read GetCurrentSession write SetCurrentSession;
    property Sessions[Index: Integer]: TACRSession read GetSession; default;
    property List[const SessionName: AnsiString]: TACRSession read GetSessionByName;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRSession
//
////////////////////////////////////////////////////////////////////////////////

  TACRDatabaseEvent = (dbOpen, dbClose, dbAdd, dbRemove);
  TACRDatabaseNotifyEvent = procedure(DBEvent: TACRDatabaseEvent; const Param) of object;
  TACRPasswordEvent = procedure(Sender: TObject; var Continue: Boolean) of Object;

  // TSession replacement for thread-safe use
{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
  TACRSession = class(TComponent)
  private
    FHandle: TACRSessionComponentManager;
    FDatabases: TList;
    FStreamedActive: Boolean;
    FKeepConnections: Boolean;
    FDefault: Boolean;
    FAutoSessionName: Boolean;
    FUpdatingAutoSessionName: Boolean;
    FSessionName: AnsiString;
    FSessionNumber: Integer;
    FLockCount: Integer;

    FOnDBNotify: TACRDatabaseNotifyEvent;
    FOnStartup: TNotifyEvent;

    // adds database
    procedure AddDatabase(Value: TACRDatabase);
    // raises exception if active
    procedure CheckInactive;
    // sends notification
    procedure DBNotification(DBEvent: TACRDatabaseEvent; const Param);
    // finds database with specified owner
    function DoFindDatabase(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean;
                            AOwner:             TComponent
                           ): TACRDatabase;
    // opens database (thread-safe)
    function DoOpenDatabase(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean;
                            AOwner:             TComponent
                           ): TACRDatabase;
    // find DB manager by db name
    function FindDatabaseHandle(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean
                        ): TACRBaseSession;
    // session is active?
    function GetActive: Boolean;
    // gets database by No
    function GetDatabase(Index: Integer): TACRDatabase;
    // gets count of connected databases
    function GetDatabaseCount: Integer;
    // gets handle
    function GetHandle: TACRSessionComponentManager;
    // not auto-session?
    function SessionNameStored: Boolean;
    // makes session current
    procedure MakeCurrent;
    // removes database from list
    procedure RemoveDatabase(Value: TACRDatabase);
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
    property OnDBNotify: TACRDatabaseNotifyEvent read FOnDBNotify write FOnDBNotify;
    // set name of component
    procedure SetName(const NewName: TComponentName); override;

    // lock
    procedure Lock(WriteMode: Boolean = false);
    // unlock
    procedure Unlock;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // locks session
    procedure LockSession(WriteMode: Boolean = true);
    // unlocks session
    procedure UnlockSession;
    // closes session
    procedure Close;
    // closes database
    procedure CloseDatabase(Database: TACRDatabase);
    // drops all connections
    procedure DropConnections;
    // get list of database names
    procedure GetDatabaseNames(List: TStrings);
    // get list of database tables
    procedure GetTableNames(
                    const DatabaseName: AnsiString;
                    const InMemory:     Boolean;
                    const Temporary:    Boolean;
                    List:               TStrings
                           ); overload;
    procedure GetTableNames(
                    const DatabaseName: AnsiString;
                    const InMemory:     Boolean;
                    const Temporary:    Boolean;
                    List:               TACRWideStringList
                           ); overload;
    // opens session
    procedure Open;
    // opens database
    function OpenDatabase(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean
                          ): TACRDatabase;
  public
    property DatabaseCount: Integer read GetDatabaseCount;
    property Databases[Index: Integer]: TACRDatabase read GetDatabase;
    property Handle: TACRSessionComponentManager read GetHandle;

  published
    property Active: Boolean read GetActive write SetActive default False;
    property AutoSessionName: Boolean read FAutoSessionName write SetAutoSessionName default False;
    property KeepConnections: Boolean read FKeepConnections write FKeepConnections default True;
    property SessionName: AnsiString read FSessionName write SetSessionName stored SessionNameStored;
    property OnStartup: TNotifyEvent read FOnStartup write FOnStartup;
  end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRDataset
//
////////////////////////////////////////////////////////////////////////////////


 TACRDBFlags = set of 0..15;
 TACRDataset = class (TDataset)
  private
   FCurrentVersion:                 AnsiString;
   FHandle:                         TACRCursor;
   FSessionName:                    AnsiString;
   FFilterBuffer:                   TACRRecordBuffer; // filter record buffer
   FIndexFieldCount:                Integer;
   FIndexFieldMap:                  array of Word;
   FKeySize:                        Integer;
   FDBFlags:                        TACRDBFlags;
   FDatabase:                       TACRDatabase;
   FDatabaseName:                   AnsiString;
   FInMemory:                       Boolean;
   FTemporary:                      Boolean;
   FReadOnly:                       Boolean;
   FStoreDefs:                      Boolean;  // for FFieldDefs
   FEditRecordBuffer:               TACRRecordBuffer; // for storing record on edit
   FACRConstraintDefs:              TACRConstraintDefs;  // Constraint definitions
   FExternalHandle:                 TACRCursor;
   FInsertOrEditComplete:           Boolean; // set to True in internal post
   FIsTable:                        Boolean; // True if TACRTable, False if TACRQuery
   FIsProjectionSet:                Boolean;
   FLogComponent:                   TACRDataset; // Table or Query for INSERT, UPDATE, DELETE record event in TACRDatabase
   FOldFieldValues:                 TACRArrayOfTACRVariant; // for update / delete
   FNewFieldValues:                 TACRArrayOfTACRVariant; // for update / insert
   FValuesChangedByEventHandler:    Boolean;
   FRepair:                         Boolean;
{$IFDEF D6H}
   FOnUpdateRecord:                 TUpdateRecordEvent;
{$ENDIF}
   FCaseInsensitive:                Boolean; // added in v.5.90
protected
   FIndexDefs:                      TIndexDefs; // index definitions
   FACRFieldDefs:                   TACRFieldDefs; // fields definitions
   FAdvIndexDefs:                   TACRIndexDefs; // index definitions
   FAdvFieldDefs:                   TACRAdvFieldDefs; // USER fields definitions
   FForeignKeyDefs:                 TACRForeignKeyDefs; // foreign key definitions
   FRestructureIndexDefs:           TIndexDefs; // restructure index definitions
   FRestructureFieldDefs:           TACRAdvFieldDefs; // restructure field definitions
   FRestructureForeignKeyDefs:      TACRForeignKeyDefs; // restructure foreign key definitions
   FKeyBuffers:                     array[TACRKeyIndex] of TACRRecordBuffer;
   FKeyBuffer:                      TACRRecordBuffer;
   FDeleteRecordFlag:               Boolean;
{$IFDEF D6H}
  protected
   // IProviderSupport
   function PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError; override;
   function PSIsSQLSupported: Boolean; override;
   procedure PSReset; override;
   function PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean; override;
  protected
   // IProviderSupport
   procedure PSEndTransaction(Commit: Boolean); override;
   function FixNames(QueryText: WideString): WideString;
{$IFDEF D17H}  //fixed by Leo in v.15.10 form XE3 (before was from XE7)
    function PSExecuteStatement(const ASQL: string; AParams: TParams): Integer; overload; override;
    function PSExecuteStatement(const ASQL: string; AParams: TParams;
      var ResultSet: TDataSet): Integer; overload; override;
    //fixed by Leo in v.15.10 form XE3 (before was missed)
    procedure PSGetAttributes(List: TPacketAttributeList); override;
{$ELSE}
   function PSExecuteStatement(const ASQL: String; AParams: TParams;
      ResultSet: Pointer = nil): Integer; override;
   procedure PSGetAttributes(List: TList); override;
{$ENDIF}
   function PSGetQuoteChar: String; override;
   function PSInTransaction: Boolean; override;
   function PSIsSQLBased: Boolean; override;
   procedure PSStartTransaction; override;
{$ENDIF}
  protected
   function InitKeyBuffer(Buffer: TACRRecordBuffer): TACRRecordBuffer;
   procedure AllocKeyBuffers;
   procedure FreeKeyBuffers;
   // field defs support
   function FieldDefsStored: Boolean;
   // index defs support
   function IndexDefsStored: Boolean;
   // set index definitions
   procedure SetIndexDefs(Value: TIndexDefs);
   // get active buffer
   function GetActiveRecordBuffer: PAnsiChar;
   procedure CheckDBSessionName;
   function GetDBHandle: TACRBaseSession;
   function GetDBSession: TACRSession;
   procedure SetDatabaseName(const Value: AnsiString);
  public
   procedure ChangeCurrentDatabaseName(const Value: AnsiString);
  protected
   procedure SetSessionName(const Value: AnsiString);
   procedure SetInMemory(const Value: Boolean);
   function GetCurrentVersion: AnsiString;
  protected
   procedure OpenCursor(InfoQuery: Boolean); override;
   procedure CloseCursor; override;
   procedure Disconnect; virtual;
   procedure SetDBFlag(Flag: Integer; Value: Boolean); virtual;
   function CreateHandle: TACRCursor; virtual;
   procedure DestroyHandle; virtual;

   procedure InternalDataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);

   function IsWideMemoField(Field: TField): Boolean;

    //fixed by Leo in v.15.10 form XE3 (before was missed)
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
  public
   procedure SetWideMemoField(Field: TField; Value: WideString);
   function GetWideMemoField(Field: TField): WideString;
  protected
   procedure SetActive(Value: Boolean); override;

   //---------------------------------------------------------------------------
   // indexes and ranges
   //---------------------------------------------------------------------------

   procedure SwitchToIndex(const IndexName: WideString);
   function GetIsIndexField(Field: TField): Boolean; override;
   procedure GetIndexInfo;
   function ResetCursorRange: Boolean;

   //---------------------------------------------------------------------------
   // navigation & bookmark methods
   //---------------------------------------------------------------------------

{$IFDEF D21H}
    procedure ClearCalcFields(Buffer: NativeInt); overload;  override;
{$ELSE}
    // clear calculated fields
    procedure ClearCalcFields(Buffer: TRecordBuffer); override;
{$ENDIF}
   procedure InternalRefresh; override;
   function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override;
  public
   procedure ClearAndGetCalcFields(Buffer: TRecordBuffer);

{$IFDEF D21H}
   function GetCurrentRecord(Buffer: TRecBuf): Boolean; overload; override;
{$ELSE}
   function GetCurrentRecord(Buffer: TRecordBuffer): Boolean; override;
{$ENDIF}
   function GetCurrentRecordID: TACRRecordID;
  protected
   // return record count
   function GetRecordCount: Integer; override;
   // go to record
   procedure SetRecNo(Value: Integer); override;
   // return current record number
   function GetRecNo: Integer; override;
   // go to first record
   procedure InternalFirst; override;
   // go to last record
   procedure InternalLast; override;
{$IFDEF D21H}   { TODO : TODO: Check in XE3+ Data.DB.pas changes - cleint dataset sucks and many other bugs with master source, grids etc }
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
  public
   // compare bookmarks
   function CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer; override;
   // checks if bookmark is valid
   function BookmarkValid(Bookmark: TBookmark): Boolean; override;
  protected

   //---------------------------------------------------------------------------
   // Filters and search
   //---------------------------------------------------------------------------

   // for OnFilterRecord Event
   function IsOnFilterRecordApplied: Boolean;
  public
   function InternalFilterRecord(Buffer: TACRRecordBuffer): Boolean;
   function FilterRecord(Buffer: TACRRecordBuffer; Dataset: Pointer): Boolean;
  protected
   procedure SetOnFilterRecord(const Value: TFilterRecordEvent); override;
   function IsIndexApplied: Boolean;
   procedure PrepareCursor; virtual;
   function GetCanModify: Boolean; override;
  public
   // set SQL Filter
   procedure SetSQLFilter(FilterExpr: TObject);
   // apply projection
   procedure ApplyProjection(FieldNamesList, AliasList: TACRWideStringList);
   // FindFirst, FindNext, Filters
   procedure ActivateFilters;
   procedure DeactivateFilters;
   procedure SetFilterData(const Text: WideString; Options: TFilterOptions);
   procedure SetFiltered(Value: Boolean); override;
   procedure SetFilterOptions(Value: TFilterOptions); override;
   procedure SetFilterText(const Value: String); override;
   function FindRecord(Restart, GoForward: Boolean): Boolean; override;
   function LocateRecord(
                         const KeyFields: WideString;
                         const KeyValues: Variant;
                         Options:         TLocateOptions
                        ): Boolean;
  public
   function Locate(const KeyFields: String; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; override;
   function Lookup(const KeyFields: String; const KeyValues: Variant;
      const ResultFields: String): Variant; override;

   //---------------------------------------------------------------------------
   // insert, edit, post, delete methods
   //---------------------------------------------------------------------------
  protected
{$IFDEF D21H}
   procedure InitRecord(Buffer: TRecBuf); overload; override;
{$ELSE}
   procedure InitRecord(Buffer: TRecordBuffer); override;
{$ENDIF}
{$IFDEF 21H}
   procedure InternalAddRecord(Buffer: TRecBuf; Append: Boolean); overload; override;
{$ELSE}
   // appending table (Append flag - ignored, record will be inserted at first empty position)
   procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override;
{$ENDIF}
   // insert record
   procedure InternalInsert; override;
   // edit record
   procedure InternalEdit; override;
   // cancels updates
   procedure InternalCancel; override;
   // update record
   procedure InternalPost; override;
   // delete record
   procedure InternalDelete; override;

   //---------------------------------------------------------------------------
   //  insert, update, delete record events of TACRDababase
   //---------------------------------------------------------------------------
   procedure CreateOldNewFieldValues;
   procedure FreeOldNewFieldValues;
   procedure SaveValues(var Values: TACRArrayOfTACRVariant);
   procedure ClearValues(var Values: TACRArrayOfTACRVariant);
  public
   function IsBeforeInsertRecordAssigned: Boolean;
   function IsAfterInsertRecordAssigned: Boolean;
   function IsBeforeUpdateRecordAssigned: Boolean;
   function IsAfterUpdateRecordAssigned: Boolean;
   function IsBeforeDeleteRecordAssigned: Boolean;
   function IsAfterDeleteRecordAssigned: Boolean;
   function IsBeforeExecuteSQLAssigned: Boolean;
   function IsAfterExecuteSQLAssigned: Boolean;
  protected
   function DoBeforeInsertRecord: Boolean;
   procedure DoAfterInsertRecord;
   function DoBeforeUpdateRecord: Boolean;
   procedure DoAfterUpdateRecord;
   function DoBeforeDeleteRecord: Boolean;
   procedure DoAfterDeleteRecord;
  public
   //---------------------------------------------------------------------------
   //  methods for fast executing DELETE and UPDATE SQL statements
   //---------------------------------------------------------------------------
   procedure DeleteVisibleRecords;
   procedure UpdateVisibleRecords(
                                  FieldNames:   TACRWideStringList;
                                  values:       array of TACRVariant
                                 );
   // return optimal database page size for filling current table
   function GetOptimalPageSize: Integer;
   // return fixed size of the record in disk mode (blob and varchar takes additional space)
   function GetDiskRecordSize: Integer;
  protected
   //---------------------------------------------------------------------------
   // open, close methods
   //---------------------------------------------------------------------------

   procedure InternalHandleException; override;
   function IsCursorOpen: Boolean; override;
   procedure InternalOpen; override;
   procedure InternalClose; override;
   procedure InternalInitFieldDefs; override;


   //---------------------------------------------------------------------------
   // general methods
   //---------------------------------------------------------------------------

   // allocate record buffer
   function AllocRecordBuffer: TRecordBuffer; override;
   // free record buffer
   procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
{$IFDEF D21H}
    procedure InternalInitRecord(Buffer: TRecBuf); overload; override;
{$ELSE}
   // initialize record buffer
   procedure InternalInitRecord(Buffer: TRecordBuffer); override;
{$ENDIF}
   // return record size in bytes
   function GetRecordSize: Word; override;
   // return true if range is applied
   function IsRangeApplied: Boolean;
  protected
   property DBFlags: TACRDBFlags read FDBFlags;
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   function OpenDatabase: TACRDatabase;
   procedure CloseDatabase(Database: TACRDatabase);
  protected
   function GetCalcFieldNo(Field: TField): Integer;
  public
   // read field data to current record buffer
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
  public
   procedure GetFieldValue(Value: TACRVariant; FieldNo: Integer; DirectAccess: Boolean; CopyFlag: Boolean = True);
   procedure SetFieldValue(Value: TACRVariant; FieldNo: Integer; DirectAccess: Boolean);
   procedure LockTable(bWriteMode: Boolean);
   procedure UnlockTable(bWriteMode: Boolean);
   procedure GotoCurrent(Source: TACRDataset);

   // create Blob stream
  private
   function InternalCreateBlobStream(
    					Field: TField;
              Mode: TBlobStreamMode
              ): TACRStream;
   // added in v.5.90
   procedure SetCaseInsensitive(Value: Boolean);
  public
   // create TACRBlobStream
   function CreateBlobStream(
    					Field: TField;
              Mode: TBlobStreamMode
              ): TStream; override;
    // close Blob stream, write Blob field value to Blob data file
    procedure CloseBlob(Field: TField); override;
    // bug fix for TIndexDefs.Assign that looses DescFields and CaseInsFields
    procedure IndexDefsAssign(Source,Dest: TIndexDefs);
    // fills FieldDefs,AdvFieldDefs,IndexDefs,ForeignKeyDefs,Restructure...Defs
    // from the cursor
    procedure GetTableDefinitions(Cursor: TACRCursor);
    // for AddIndex / DeleteIndex on opened cursor(s)
    procedure UpdateIndexDefinitions(Cursor: TACRCursor);
    // clear FieldDefs,AdvFieldDefs,IndexDefs,AdvIndexDefs,ForeignKeyDefs, etc.
    // call it before CreateTable
    procedure ClearDefinitions;
    // assign definitions from Source dataset
    procedure AssignDefinitions(Source: TACRDataset);
    // return FHandle from TACRDatabase
    function GetBaseSession: TACRBaseSession;
    // set Handle to nil to avoid its destroying - needed by SQL engine
    procedure ResetHandle;
  public
   // Table or Query for INSERT, UPDATE, DELETE record event in TACRDatabase
   property LogComponent: TACRDataset read FLogComponent write FLogComponent;
   // for INSERT, UPDATE events
   property ValuesChangedByEventHandler: Boolean read FValuesChangedByEventHandler write FValuesChangedByEventHandler;
   property IsTable: Boolean read FIsTable write FIsTable;
   property Handle: TACRCursor read FHandle;
   property Database: TACRDatabase read FDatabase;
//   property DBHandle: TACRBaseSession read GetDBHandle;
   property DBSession: TACRSession read GetDBSession;
   // index definitions, used by CreateTable;
   property IndexDefs: TIndexDefs read FIndexDefs write SetIndexDefs stored IndexDefsStored;
   // field definitions, used by CreateTable;
   property FieldDefs stored FieldDefsStored;
   // index definitions, used by CreateTable;
   property AdvIndexDefs: TACRIndexDefs read FAdvIndexDefs;
   // field definitions, used by CreateTable;
   property AdvFieldDefs: TACRAdvFieldDefs read FAdvFieldDefs;
   property ForeignKeyDefs: TACRForeignKeyDefs read FForeignKeyDefs;
   property KeySize: Integer read FKeySize;
  published
   property CurrentVersion: AnsiString read GetCurrentVersion write FCurrentVersion;
   // fielddefs support
   property StoreDefs: Boolean read FStoreDefs write FStoreDefs default False;
 {$IFDEF SQLMEMTABLE}
  public
 {$ENDIF}
   property SessionName: AnsiString read FSessionName write SetSessionName;
   property InMemory: Boolean read FInMemory write SetInMemory;
 {$IFDEF SQLMEMTABLE}
  published
 {$ENDIF}
   property DatabaseName: AnsiString read FDatabaseName write SetDatabaseName;
   property ReadOnly: Boolean read FReadOnly write FReadOnly;

   property Active;
   property AutoCalcFields;
   property Filter;
   property Filtered;
   property FilterOptions;
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
{$IFDEF D6H}
   property OnUpdateRecord: TUpdateRecordEvent read FOnUpdateRecord write FOnUpdateRecord;
{$ENDIF}
   property CaseInsensitive: Boolean read FCaseInsensitive write SetCaseInsensitive; // added in v.5.90
 end; // TACRDataset


////////////////////////////////////////////////////////////////////////////////
//
// TACRTable
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
 TACRTable = class (TACRDataset)
  private
   FOnProgress:         TACRTableProgress;
   FTableName:          WideString;
   FComment:            WideString;
   FExclusive:          Boolean;
   FIndexName:          WideString;
   FFieldsIndex:        Boolean;
   FMasterLink:         TMasterDataLink;
   FMemoryTableAllocBy: Integer;

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
  private
   procedure CheckBlankTableName;
   procedure SetTemporary(const Value: Boolean);
   function GetIndexFieldNames: WideString;
   function GetIndexName: WideString;
   procedure GetIndexParams(const IndexName: WideString; FieldsIndex: Boolean;
         var IndexedName: WideString);
   function IndexDefsStored: Boolean;
   procedure SetIndex(const Value: WideString; FieldsIndex: Boolean);
   procedure SetIndexFieldNames(const Value: WideString);
   procedure SetIndexName(const Value: WideString);
   function CreateCursor(bOpenView: Boolean = True): TACRCursor;
 protected
   // progress event
   procedure DoOnProgress(
                          Progress:   Double;
                          Operation:  TACRTableOperation;
                          var Abort:  Boolean
                         );
  public
   procedure GetIndexNames(List: TStrings);
    // return index name of the index or '' if not found
   function FindIndex(FieldNamesList, AscDescList, CaseSensitivityList: TACRWideStringList): WideString;
   procedure GetTableNames(List: TStrings);
  private

   function GetTableExists: Boolean;
   //---------------------------- master-detail --------------------------------
   procedure CheckMasterRange;
   procedure UpdateRange;
   procedure MasterChanged(Sender: TObject);
   procedure MasterDisabled(Sender: TObject);
   procedure SetDataSource(Value: TDataSource);
   function GetMasterFields: WideString;
   procedure SetMasterFields(const Value: WideString);
  protected
   procedure PrepareCursor; override;
   function CreateHandle: TACRCursor; override;
{$IFDEF D16H}
   procedure DataEvent(Event: TDataEvent; Info: NativeInt); override;
{$ELSE}
   procedure DataEvent(Event: TDataEvent; Info: Longint); override;
{$ENDIF}
   procedure DefChanged(Sender: TObject); override;
   procedure InitFieldDefs; override;
   procedure DestroyHandle; override;
   function GetHandle: TACRCursor;
   // updates FieldDefs,AdvFieldDefs,IndexDefs,ForeignKeyDefs,Restructure...Defs
   // if table is closed
   procedure UpdateTableDefinitions;
   procedure UpdateIndexDefs; override;
   function GetIndexField(Index: Integer): TField;
   procedure SetIndexField(Index: Integer; Value: TField);
   procedure SetTableName(Value: WideString);

   //---------------------------- master-detail --------------------------------
   procedure SetLinkRanges(MasterFields: TList);
   function GetDataSource: TDataSource; override;
   procedure DoOnNewRecord; override;
   function GetIndexFieldCount: Integer;
  protected
   property MasterLink: TMasterDataLink read FMasterLink;
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure CreateTable;
   procedure DeleteTable(Cascade: Boolean = False);
   procedure EmptyTable;
   procedure RenameTable(NewTableName: WideString);
   procedure LoadTableFromFile(
                        FileName:             AnsiString;
                        FileNameUnicode:      WideString = ''
                       );
   procedure SaveTableToFile(
                        FileName:             AnsiString;
                        CompressionAlgorithm: TCompressionAlgorithm = caNone;
                        CompressionMode:      Byte = 0;
                        BlockSize:            Integer = ACRDefaultSaveBlockSize;
                        FileNameUnicode:      WideString = ''
                      );
   procedure LoadTableFromStream(
                        Stream: TStream
                       );
   procedure SaveTableToStream(
                        Stream: TStream;
                        CompressionAlgorithm: TCompressionAlgorithm = caNone;
                        CompressionMode:      Byte = 0;
                        BlockSize:            Integer = ACRDefaultSaveBlockSize
                      );
   procedure LoadAllTablesFromFile(
                        FileName:             AnsiString;
                        FileNameUnicode:      WideString = ''
                       );
   procedure LoadAllTablesFromStream(
                        Stream: TStream
                       );
   procedure SaveTablesToFile(
                        TableList:            TACRWideStringList;
                        FileName:             AnsiString;
                        CompressionAlgorithm: TCompressionAlgorithm = caNone;
                        CompressionMode:      Byte = 0;
                        BlockSize:            Integer = ACRDefaultSaveBlockSize;
                        FileNameUnicode:      WideString = ''
                      );
    procedure SaveTablesToStream(
                    TableList:            TACRWideStringList;
                    Stream:               TStream;
                    CompressionAlgorithm: TCompressionAlgorithm = caNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
                  );
   procedure SaveAllTablesToFile(
                        FileName:             AnsiString;
                        CompressionAlgorithm: TCompressionAlgorithm = caNone;
                        CompressionMode:      Byte = 0;
                        BlockSize:            Integer = ACRDefaultSaveBlockSize;
                        FileNameUnicode:      WideString = ''
                      );
   procedure SaveAllTablesToStream(
                        Stream: TStream;
                        CompressionAlgorithm: TCompressionAlgorithm = caNone;
                        CompressionMode:      Byte = 0;
                        BlockSize:            Integer = ACRDefaultSaveBlockSize
                      );
   function ImportTable(
                          SourceTable: TDataset;
                          var Log:     AnsiString
                        ): Boolean; overload;
   function ImportTable(SourceTable: TDataset): Boolean; overload;
   function ExportTable(
                          DestinationTable:   TDataset;
                          CreateTablePointer: TProcedure;
                          var Log:            AnsiString
                       ): Boolean; overload;
   function ExportTable(
                          DestinationTable:   TDataset;
                          CreateTablePointer: TProcedure
                       ): Boolean; overload;
   function ExportTableToSQL(
                              ExportStructure:      Boolean = True;
                              AddDropTableCommand:  Boolean = True;
                              ExportIndexes:        Boolean = True;
                              AddDropIndexCommand:  Boolean = False;
                              ExportData:           Boolean = True;
                              ExportBLOBFields:     Boolean = True;
                              UseBracketsForNames:  Boolean = False;
                              ExportForeignKeys:    Boolean = True
                            ): WideString;
   function BatchMove(ASource: TACRDataSet; AMode: TACRBatchMode): Int64;
   function RestructureTable(
                          var Log:            AnsiString
                       ): Boolean; overload;
   function RestructureTable: Boolean; overload;
   function IsSystemTable: Boolean;
   // repair table
  protected
   function InternalRepairOrRestructureTable(
                            Repair:       Boolean;
                            var Log:      AnsiString;
                            NewDatabase:  TACRDatabase = nil;
                            FKDefs:       TACRForeignKeyDefs = nil
                            ): Boolean;
  public
   function RepairTable(UseLowLevelTableAccess: Boolean = False): Boolean; overload;
   function RepairTable(
                        var Log:                AnsiString;
                        UseLowLevelTableAccess: Boolean = False;
                        NewDatabase:            TACRDatabase = nil;
                        FKDefs:                 TACRForeignKeyDefs = nil
                        ): Boolean; overload;

   // Rename Field by Name
   procedure RenameField(FieldName, NewFieldName: WideString);
   procedure AddForeignKey(ForeignKeyDef: TACRForeignKeyDef);
   procedure DeleteConstraint(Name: WideString; Cascade: Boolean = False);

   procedure AddIndex(
              const Name,
              Fields: WideString;
              Options: TIndexOptions;
              const DescFields: WideString = '';
              const CaseInsFields: WideString = ''
                     );
   procedure DeleteIndex(const Name: WideString);
   procedure DeleteAllIndexes;

   //---------------------------------------------------------------------------
   // key and range methods
   //---------------------------------------------------------------------------
  protected
    procedure CheckSetKeyMode;
    function GetKeyBuffer(KeyIndex: TACRKeyIndex): TACRRecordBuffer;
    function GetKeyExclusive: Boolean;
    function GetKeyFieldCount: Integer;
    procedure SetKeyExclusive(Value: Boolean);
    procedure SetKeyFieldCount(Value: Integer);
    procedure SetKeyBuffer(KeyIndex: TACRKeyIndex; Clear: Boolean);
    procedure SetKeyFields(KeyIndex: TACRKeyIndex; const Values: array of const);
    procedure PostKeyBuffer(Commit: Boolean);
  public
   function FindKey(const KeyValues: array of const): Boolean;
   procedure FindNearest(const KeyValues: array of const);
   function GotoKey: Boolean;
   procedure GotoNearest;
   procedure EditKey;
   procedure SetKey;

   function SetCursorRange: Boolean;
   procedure ApplyRange;
   procedure CancelRange;
   procedure EditRangeStart;
   procedure EditRangeEnd;
   procedure SetRange(const StartValues, EndValues: array of const);
   procedure SetRangeStart;
   procedure SetRangeEnd;

   procedure Post; override;

   // return LastAutoincValue for Field (FieldIndex started from 0)
   function LastAutoincValue(FieldIndex: Integer): Int64; overload;
   // return LastAutoincValue for Field
   function LastAutoincValue(FieldName: WideString): Int64; overload;
   // set LastAutoincValue for Field (FieldIndex started from 0)
   procedure SetLastAutoincValue(Value: Int64; FieldIndex: Integer); overload;
   // set LastAutoincValue for Field
   procedure SetLastAutoincValue(Value: Int64; FieldName: WideString); overload;
   // return current table state if exists
   function GetTableState: TACRTableState;

  public
   property IndexFieldCount: Integer read GetIndexFieldCount;
   property IndexFields[Index: Integer]: TField read GetIndexField write SetIndexField;
   property KeyExclusive: Boolean read GetKeyExclusive write SetKeyExclusive;
   property KeyFieldCount: Integer read GetKeyFieldCount write SetKeyFieldCount;
   property Temporary: Boolean Read FTemporary Write SetTemporary;
   // index definitions, used by RestructureTable;
   property RestructureIndexDefs: TIndexDefs read FRestructureIndexDefs;
   // field definitions, used by RestructureTable;
   property RestructureFieldDefs: TACRAdvFieldDefs read FRestructureFieldDefs;
   // foreign key definitions, used by RestructureTable;
   property RestructureForeignKeyDefs: TACRForeignKeyDefs read FRestructureForeignKeyDefs;
  published
   // fielddefs support
   property StoreDefs;
   // index definitions
   property IndexDefs: TIndexDefs read FIndexDefs write SetIndexDefs
              stored IndexDefsStored;
   property IndexFieldNames: WideString read GetIndexFieldNames write SetIndexFieldNames;
   property IndexName: WideString read GetIndexName write SetIndexName;
   // field definitions
   property FieldDefs stored FieldDefsStored;
   property Comment: WideString read FComment write FComment;
   property TableName: WideString Read FTableName Write SetTableName;
{public}
   property Exclusive: Boolean read FExclusive write FExclusive;
{published}
   property Exists: Boolean read GetTableExists;
   property MasterFields: WideString read GetMasterFields write SetMasterFields;
   property MasterSource: TDataSource read GetDataSource write SetDataSource;
   property MemoryTableAllocBy: Integer read FMemoryTableAllocBy write FMemoryTableAllocBy;
   property OnProgress: TACRTableProgress read FOnProgress write FOnProgress;
 end; // TACRTable


////////////////////////////////////////////////////////////////////////////////
//
// TACRQuery
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
TACRQuery = class (TACRDataset)
  private
    FStmtHandle:        TACRSQLProcessor;
    FSQL:               TACRWideStringList;
    FPrepared:          Boolean;
    FParams:            TParams;
    FText:              WideString;
    FDataLink:          TDataLink;
    FRowsAffected:      Integer;
    FRequestLive:       Boolean;
    FParamCheck:        Boolean;
    FExecSQL:           Boolean;
    FCheckRowsAffected: Boolean;
    FDoNotCallFixParam: Boolean;
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
    procedure GetStatementHandle(SQLText: PWideChar);
    procedure FreeStatement;
    function CreateCursor(GenHandle: Boolean): TACRCursor;
    function GetQueryCursor(GenHandle: Boolean): TACRCursor;
    function GetRowsAffected: Integer;
    procedure QueryChanged(Sender: TObject);
    function GetDataSource: TDataSource; override;
    procedure SetDataSource(Value: TDataSource);

    // fix MS params ? - replace to :Param0, :Param1, ...
    procedure FixParamsInQuery;
    procedure SetSQL(Value: TACRWideStringList);

    function GetParamsCount: Word;
    procedure RefreshParams;
    procedure SetParamsList(Value: TParams);
    procedure SetParamsFromCursor;
  public
    function ParamByName(const Value: String): TParam; 

    procedure Prepare;
    procedure UnPrepare;
  public
    procedure PrepareSQL(Value: PWideChar);
  protected
    procedure SetPrepared(Value: Boolean);
    procedure SetPrepare(Value: Boolean);
  private
    procedure ReadParamData(Reader: TReader);
    procedure WriteParamData(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function CreateHandle: TACRCursor; override;
    procedure DestroyHandle; override;
    procedure Disconnect; override;
    procedure SetDBFlag(Flag: Integer; Value: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ExecSQL;
{$IFDEF D21H}
    procedure GetDetailLinkFields(MasterFields, DetailFields: TList<TField>); overload; override;
{$ELSE}
    procedure GetDetailLinkFields(MasterFields, DetailFields: TList); override;
{$ENDIF}
  public
    property Prepared: Boolean read FPrepared write SetPrepare;
    property ParamCount: Word read GetParamsCount;
    property StmtHandle: TACRSQLProcessor read FStmtHandle;
    property Text: WideString read FText;
    property RowsAffected: Integer read GetRowsAffected;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ParamCheck: Boolean read FParamCheck write FParamCheck default True;
    property RequestLive: Boolean read FRequestLive write FRequestLive default False;
    property SQL: TACRWideStringList read FSQL write SetSQL stored True nodefault;
    property Params: TParams read FParams write SetParamsList stored False;
 end; // TACRQuery


////////////////////////////////////////////////////////////////////////////////
//
// TACRLockParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

{$IFNDEF SQLMEMTABLE}
  TACRLockParamsEditor = class (TPersistent)
   private
    FRetryCount:                   Integer;
    FDelay:                        Integer;
   public
    constructor Create;
    function GetLockParams: TACRLockParams;
    procedure SetLockParams(Params: TACRLockParams);
    procedure SetRetryCount(Value: Integer);
    procedure SetDelay(Value: Integer);
    procedure Assign(Source: TPersistent); override;
   published
    property Delay: Integer read FDelay write SetDelay;
    property RetryCount: Integer read FRetryCount write SetRetryCount;
   end;// TACRLockParamsEditor
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACROptionsEditor
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
{ TODO -oLeo : document changes in v.5 }
  TACROptionsEditor = class (TPersistent)
   private
    FMaxSessionCount:           Cardinal;
    FPageSize:                  Cardinal;
    FExtentPageCount:           Word;
    FRandomSearchRetryCount:    Cardinal;
   public
    constructor Create;
    function GetOptions: TACROptions;
    procedure SetOptions(NewOptions: TACROptions);
    procedure SetMaxSessionCount(Value: Cardinal);
    procedure SetPageSize(Value: Cardinal);
    procedure SetExtentPageCount(Value: Word);
    procedure SetRandomSearchRetryCount(Value: Cardinal);
    procedure Assign(Source: TPersistent); override;
   published
    property MaxSessionCount: Cardinal read FMaxSessionCount write SetMaxSessionCount;
    property PageSize: Cardinal read FPageSize write SetPageSize;
    property ExtentPageCount: Word read FExtentPageCount write SetExtentPageCount;
    property RandomSearchRetryCount: Cardinal read FRandomSearchRetryCount write SetRandomSearchRetryCount;
   end;// TACROptionsEditor
{$ENDIF}


{$IFNDEF SQLMEMTABLE}
  TACRBackupParamsEditor = class (TPersistent)
   private
    FCompressionAlgorithm:  TCompressionAlgorithm;
    FCompressionMode:       Byte;
    FCryptoParamsEditor:    TACRCryptoParamsEditor;
    FDescription:           WideString;
    FBlockSize:             Integer;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
   published
    property CompressionAlgorithm: TCompressionAlgorithm
              read FCompressionAlgorithm write FCompressionAlgorithm;
    property CompressionMode: Byte read FCompressionMode write FCompressionMode;
    property CryptoParams: TACRCryptoParamsEditor read FCryptoParamsEditor write FCryptoParamsEditor;
    property Description: WideString read FDescription write FDescription;
    property BlockSize: Integer read FBlockSize write FBlockSize;
  end;
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabase
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
 TACRDatabase = class (TComponent)
  private
    FOnError:                 TACROnError;
    FAfterConnect:            TNotifyEvent;
    FAfterDisconnect:         TNotifyEvent;
    FBeforeConnect:           TNotifyEvent;
    FBeforeDisconnect:        TNotifyEvent;
    FAfterServerShutdown:     TNotifyEvent;
    FBeforeServerShutdown:    TNotifyEvent;
    FAfterConnectionLost:     TNotifyEvent;
    FBeforeConnectionLost:    TNotifyEvent;
    FBeforeInsertRecord:      TACRBeforeInsertRecord;
    FBeforeUpdateRecord:      TACRBeforeUpdateRecord;
    FBeforeDeleteRecord:      TACRBeforeDeleteRecord;
    FBeforeExecuteSQL:        TACRBeforeExecuteSQL;
    FAfterInsertRecord:       TACRAfterInsertRecord;
    FAfterUpdateRecord:       TACRAfterUpdateRecord;
    FAfterDeleteRecord:       TACRAfterDeleteRecord;
    FAfterExecuteSQL:         TACRAfterExecuteSQL;
    FOnProgress:              TACRDatabaseProgress;
    FOnTableProgress:         TACRTableProgress;
    FDataSets:                TList;
    FKeepConnection:          Boolean;
    FTemporary:               Boolean;
    FStreamedConnected:       Boolean;
    FAcquiredHandle:          Boolean;
    FHandleShared:            Boolean;
    FReadOnly:                Boolean;
    FRefCount:                Integer;
    FHandle:                  TACRBaseSession;
    FSession:                 TACRSession;
    FSessionName:             AnsiString;
    FDatabaseName:            AnsiString; // name of database
    FInMemory:                Boolean;
    FDatabaseFileName:        AnsiString; // Ansi database file name
    FDatabaseFileNameUnicode: WideString; // Unicode database file name
    FExclusive:               Boolean;
    FLocalDatabase:           Boolean;
    FSkipDatabaseNameCheck:   Boolean;
    FThreadSyncRefCount:      TACRReadWriteThreadSyncBySingleCriticalSection;
    FCaseInsensitive:         Boolean; // added in v.5.90
{$IFNDEF SQLMEMTABLE}
    FBackupParams:                    TACRBackupParamsEditor;
{$IFDEF CLIENT_VERSION}
    FConnectionParams:                TACRClientConnectParamsEditor;
{$ENDIF}
    FLockParamsEditor:                TACRLockParamsEditor;
    FOptionsEditor:                   TACROptionsEditor;
    FCryptoParamsEditor:              TACRCryptoParamsEditor;
    FOnReceiveTextMessage:            TACROnClientReceiveTextMessage;
    FOnReceiveUnicodeTextMessage:     TACROnClientReceiveUnicodeTextMessage;
    FOnReceiveBinaryMessage:          TACROnClientReceiveBinaryMessage;
    FOnReceiveStreamMessage:          TACROnClientReceiveStreamMessage;
{$ENDIF}
    // raises exception if not active
    procedure CheckInactive;
    // raises exception if database name is not valid
    procedure CheckDatabaseName;
    // checks session name
    procedure CheckSessionName(Required: Boolean);
    procedure CheckConnected;
    procedure CheckDisconnected;
    // db connected?
    function GetConnected: Boolean;
    // connected dataset
    function GetDataSet(Index: Integer): TACRDataSet;
    // count of connected datasets
    function GetDataSetCount: Integer;
    // opens from existing DB
    function OpenFromExistingDB: Boolean;

    // sets specified file name
    procedure SetDatabaseFileName(Value: AnsiString);
    procedure SetDatabaseFileNameUnicode(Value: WideString);
{$IFDEF D12H}
    function GetDatabaseFileNameUnicodeAsString: String;
    procedure SetDatabaseFileNameUnicodeAsString(Value: String);
{$ENDIF}
    // sets specified database name
    procedure SetDatabaseName(Value: AnsiString);
    // sets in-memory property
    procedure SetInMemory(Value: Boolean);
    // sets handle
    procedure SetHandle(Value: TACRBaseSession);
    // keeps connection
    procedure SetKeepConnection(Value: Boolean);
    // sets read-only mode
    procedure SetReadOnly(Value: Boolean);
    // sets session name
    procedure SetSessionName(const Value: AnsiString);

    // connect / disconnect
    procedure SetConnected(value: boolean);
    // is database exists
    function GetExists: boolean;
    // get database manager
    procedure CreateHandle;
    // release database manager
    procedure DestroyHandle;
    procedure DisconnectAllRemoteDatasets(ServerShutdown: Boolean);
    procedure DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: AnsiString
                       );
  protected
    // loaded
    procedure Loaded; override;
    // sends notification
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    // progress event
    procedure DoOnProgress(Progress: Double; Operation: TACRDatabaseOperation; var Abort: Boolean);
    // progress event
    procedure DoOnTableProgress(
                                      Sender:     TComponent;
                                      Progress:   Double;
                                      Operation:  TACRTableOperation;
                                      var Abort:  Boolean
                               );
    // before insert record
    procedure DoBeforeInsertRecord(
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant;
                       var Abort:          Boolean
                     );
    // after insert record
    procedure DoAfterInsertRecord(
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant
                     );
    procedure DoBeforeUpdateRecord(
                       Sender:                TACRDataset;
                       const TableName:       WideString;
                       const OldFieldValues:  TACRArrayOfTACRVariant;
                       const NewFieldValues:  TACRArrayOfTACRVariant;
                       var Abort:             Boolean
                     );
    procedure DoAfterUpdateRecord(
                       Sender:                TACRDataset;
                       const TableName:       WideString;
                       const OldFieldValues:  TACRArrayOfTACRVariant;
                       const NewFieldValues:  TACRArrayOfTACRVariant
                     );
    procedure DoBeforeDeleteRecord(
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant;
                       var Abort:          Boolean
                     );
    procedure DoAfterDeleteRecord(
                       Sender:             TACRDataset;
                       const TableName:    WideString;
                       const FieldValues:  TACRArrayOfTACRVariant
                     );
    procedure DoBeforeExecuteSQL(
                       Sender:             TACRQuery;
                       var Abort:          Boolean
                     );
    procedure DoAfterExecuteSQL(
                       Sender:             TACRQuery
                     );
  public
    // creates databases with specified directory
    constructor Create(AOwner: TComponent); override;
    // destructor
    destructor Destroy; override;
    // connected := true
    procedure Open;
    // connected := false
    procedure Close;
    // create database
    procedure CreateDatabase;
    // delete database
    procedure DeleteDatabase;
    // rename database
    procedure RenameDatabase(NewDatabaseFileName: AnsiString; NewDatabaseFileNameUnicode: WideString = '');
    // flush file buffers
    procedure FlushFileBuffers;
    // close all datasets
    procedure CloseDataSets;
    // find and remove dataset
    procedure RemoveDataset(dataset: TDataset);
    // validates name
    procedure ValidateName(const Name: AnsiString);
    // get list of tables in database file
    procedure GetTablesList(List: TACRWideStringList); overload;
    procedure GetTablesList(List: TStrings); overload;
    function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray;
    function GetTableState(TableName: WideString): TACRTableState;
    // determine if table exists
    function TableExists(TableName: WideString): Boolean;
    procedure LoadAllTablesFromStream(
                        Stream: TStream
                       );
    procedure SaveTablesToStream(
                    TableList:            TACRWideStringList;
                    Stream:               TStream;
                    CompressionAlgorithm: TCompressionAlgorithm = caNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
                  );
    procedure SaveAllTablesToStream(
                        Stream: TStream;
                        CompressionAlgorithm: TCompressionAlgorithm = caNone;
                        CompressionMode:      Byte = 0;
                        BlockSize:            Integer = ACRDefaultSaveBlockSize
                      );
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
                            ): WideString;
    procedure LoadDatabaseFromStream(
                        Stream: TStream
                       );
    procedure SaveDatabaseToStream(
                    Stream:               TStream;
                    CompressionAlgorithm: TCompressionAlgorithm = caNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
                  );
    procedure LoadDatabaseFromFile(
                    FileName:             AnsiString;
                    FileNameUnicode:      WideString = ''
                       );
    procedure SaveDatabaseToFile(
                    FileName:             AnsiString;
                    FileNameUnicode:      WideString = '';
                    CompressionAlgorithm: TCompressionAlgorithm = caNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
                  );
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString);

    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
    // create stored function / procedure
    procedure CreateStoredFunction(SQLScript: WideString);
    // drop stored function / procedure
    procedure DropStoredFunction(FunctionName: WideString);
    // ALTER stored function - modify script
    procedure AlterStoredFunction(
                                    FunctionName,
                                    NewSQLScript: WideString
                                 );
    // ALTER stored function - rename
    procedure AlterStoredFunctionRename(
                                Session:          TACRBaseSession;
                                FunctionName,
                                NewFunctionName:  WideString
                                                        );
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    function ExecuteStoredFunction(FunctionName: WideString; ResultValue: TACRVariant; Params: TACRSQLParams = nil): Boolean;
    // return empty string if function not found; otherwise
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString);
    // return true if stored functions can be used
    function IsStoredFunctionManagerExists: Boolean;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------

    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         ViewName:          WideString;
                         SelectStatement:   WideString;
                         Columns:           TACRWideStringList = nil;
                         bWithCheckOption:  Boolean = False;
                         Comment:           WideString = ''
                        );
    // drop view
    procedure DropView(
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      );
    //------------------------- VIEWS - added in v.6.00 ------------------------
{$IFNDEF SQLMEMTABLE}
   protected
    // retrun true if database has active transaction
    function GetInTransaction: Boolean;
    // receive custom message from server and call defined event
    procedure ReceiveMessage(Buffer: PAnsiChar; Size: Integer);
   public
    // start a transaction
    procedure StartTransaction;
    // apply changes made by transaction and optionally flush file buffers
    procedure Commit(FlushFileBuffers: Boolean = False);
    // cancel changes made by transaction
    procedure Rollback;
    // remove all locks - called by disconnect of server session
    procedure RemoveAllLocks;
    // clear disk cache in single-user / multi-user
    procedure ClearCache;
   protected
    function InternalRepairDatabase(
                                     IgnoreErrors:                Boolean;
                                     var Log:                     AnsiString ;
                                     UseLowLevelTableAccess:      Boolean = False;
                                     Options:                     TACROptionsEditor = nil;
                                     CryptoParams:                TACRCryptoParamsEditor = nil;
                                     NewDatabaseFileName:         AnsiString = '';
                                     NewDatabaseFileNameUnicode:  WideString = ''
                                    ): Boolean;
   public
    // compact database
    procedure CompactDatabase;
    // repair database
    function RepairDatabase(UseLowLevelTableAccess: Boolean = False): Boolean; overload;
    function RepairDatabase(var Log: AnsiString; UseLowLevelTableAccess: Boolean = False): Boolean; overload;
    // change database settings
    function ChangeDatabaseSettings(Options: TACROptionsEditor;
                                    CryptoParams: TACRCryptoParamsEditor): Boolean;
   protected
    // return database format version
    function GetFormatVersion: Double;
    // empty proc for displaying property in Object Inspector
    procedure SetFormatVersion(Value: Double);
    // return total number of pages
    function GetTotalPageCount: Integer;
    // return number of free pages
    function GetFreePageCount: Integer;
    // return number of used pages
    function GetUsedPageCount: Integer;
    // return density = usedpagecoount / totalpagecount * 100.0 %
    function GetDensity: Double;

   public
    // return true if database is encrypted
    function IsDatabaseEncrypted: Boolean;
    // return true if database is encrypted by password or by key
    function IsDatabaseEncryptedByPassword: Boolean;
    // return true if CryptoParams are valid
    function IsCryptoParamsValid: Boolean;
    procedure SendMessage(const Text: AnsiString); overload;
    procedure SendMessage(const Text: WideString); overload;
    procedure SendMessage(Buffer: PAnsiChar; Size: Integer); overload;
    procedure SendMessage(Stream: TStream); overload;
    // makes Exe database from edb file
    procedure MakeExeDatabase(ExeFileName, ExeDatabaseFileName: AnsiString);
    // removes database file from executable database file
    procedure RemoveDatabaseFromExe;
    // returns true if this file is an Accuracer database
    function IsAccuracerDatabaseFile: Boolean;
    // return true if file was copied
    function CopyDatabase(const NewDatabaseFileName: AnsiString; const NewDatabaseFileNameUnicode: WideString = ''): Boolean; overload;
    function CopyDatabase(var Log: AnsiString; const NewDatabaseFileName: AnsiString; const NewDatabaseFileNameUnicode: WideString = ''): Boolean; overload;

   protected
    // progress event
    procedure DoOnBackupProgress(Sender: TObject; Progress: Double; var Abort: Boolean);
    procedure DoOnRestoreProgress(Sender: TObject; Progress: Double; var Abort: Boolean);
    procedure LoadBackupHeader(
                         Stream:            TACRStream;
                         var Header:        TACRBackupHeader;
                         out Description:   WideString;
                         Tables:            TACRWideStringList = nil);
{$ENDIF}
    // added in v.5.90
    function GetCaseInsensitive: Boolean;
    procedure SetCaseInsensitive(Value: Boolean);
{$IFNDEF SQLMEMTABLE}
   public
    procedure Backup(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString = '');
    procedure Restore(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString = '');
    function GetBackupInfo(const BackupFileName: AnsiString; Tables: TACRWideStringList = nil; const BackupFileNameUnicode: WideString = ''): TACRBackupInfo;
    function IsAccuracerBackupFile(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString = ''): Boolean;
    function IsAccuracerBackupFileCryptoParamsValid(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString = ''): Boolean;
{$ENDIF}
   public
{$IFNDEF SQLMEMTABLE}
    property InTransaction: Boolean read GetInTransaction;
    property TotalPageCount: Integer read GetTotalPageCount;
    property FreePageCount: Integer read GetFreePageCount;
    property UsedPageCount: Integer read GetUsedPageCount;
    property Density: Double read GetDensity;
    property Session: TACRSession read FSession;
{$ELSE}
    property KeepConnection: Boolean read FKeepConnection write SetKeepConnection default True;
{$ENDIF}
    property DataSets[Index: Integer]: TACRDataSet read GetDataSet;
    property DataSetCount: Integer read GetDataSetCount;
    property Exists: Boolean read GetExists;
    property Handle: TACRBaseSession read FHandle write SetHandle;
    property Temporary: Boolean read FTemporary write FTemporary;
    property SkipDatabaseNameCheck: Boolean read FSkipDatabaseNameCheck write FSkipDatabaseNameCheck;
  published
{$IFNDEF SQLMEMTABLE}
    property FormatVersion: Double read GetFormatVersion write SetFormatVersion;
    property OnReceiveTextMessage: TACROnClientReceiveTextMessage read FOnReceiveTextMessage write FOnReceiveTextMessage;
    property OnReceiveUnicodeTextMessage: TACROnClientReceiveUnicodeTextMessage read FOnReceiveUnicodeTextMessage write FOnReceiveUnicodeTextMessage;
    property OnReceiveBinaryMessage: TACROnClientReceiveBinaryMessage read FOnReceiveBinaryMessage write FOnReceiveBinaryMessage;
    property OnReceiveStreamMessage: TACROnClientReceiveStreamMessage read FOnReceiveStreamMessage write FOnReceiveStreamMessage;
{$ENDIF}
    property OnError: TACROnError read FOnError write FOnError;
    property BeforeInsertRecord:    TACRBeforeInsertRecord read FBeforeInsertRecord write FBeforeInsertRecord;
    property BeforeUpdateRecord:    TACRBeforeUpdateRecord read FBeforeUpdateRecord write FBeforeUpdateRecord;
    property BeforeDeleteRecord:    TACRBeforeDeleteRecord  read FBeforeDeleteRecord write FBeforeDeleteRecord;
    property BeforeExecuteSQL:      TACRBeforeExecuteSQL read FBeforeExecuteSQL write FBeforeExecuteSQL;
    property AfterInsertRecord:     TACRAfterInsertRecord read FAfterInsertRecord write FAfterInsertRecord;
    property AfterUpdateRecord:     TACRAfterUpdateRecord read FAfterUpdateRecord write FAfterUpdateRecord;
    property AfterDeleteRecord:     TACRAfterDeleteRecord read FAfterDeleteRecord write FAfterDeleteRecord;
    property AfterExecuteSQL:       TACRAfterExecuteSQL read FAfterExecuteSQL write FAfterExecuteSQL;
    property Connected: Boolean read GetConnected write SetConnected default False;
    property DatabaseName: AnsiString read FDatabaseName write SetDatabaseName;
    property InMemory: Boolean read FInMemory write SetInMemory;
{$IFNDEF SQLMEMTABLE}
    property HandleShared: Boolean read FHandleShared write FHandleShared default False;
    property SessionName: AnsiString read FSessionName write SetSessionName;
{$IFDEF CLIENT_VERSION}
    property LocalDatabase: Boolean read FLocalDatabase write FLocalDatabase default True;
{$ENDIF}
    property KeepConnection: Boolean read FKeepConnection write SetKeepConnection default True;
    // if not empty - ANSI, else - Unicode
    property DatabaseFileNameAnsi: AnsiString read FDatabaseFileName write SetDatabaseFileName;
    property DatabaseFileNameUnicode: WideString read FDatabaseFileNameUnicode write SetDatabaseFileNameUnicode;
 {$IFDEF D12H}
// wide string
    property DatabaseFileName: String read GetDatabaseFileNameUnicodeAsString write SetDatabaseFileNameUnicodeAsString;
 {$ELSE}
// ansi string
    property DatabaseFileName: String read FDatabaseFileName write SetDatabaseFileName;
 {$ENDIF}
    property Exclusive: Boolean read FExclusive write FExclusive;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property BackupParams: TACRBackupParamsEditor read FBackupParams write FBackupParams;
{$IFDEF CLIENT_VERSION}
    property ConnectionParams: TACRClientConnectParamsEditor read FConnectionParams write FConnectionParams;
{$ENDIF}
    property LockParams: TACRLockParamsEditor read FLockParamsEditor write FLockParamsEditor;
    property Options: TACROptionsEditor read FOptionsEditor write FOptionsEditor;
    property OnProgress: TACRDatabaseProgress read FOnProgress write FOnProgress;
    property OnTableProgress: TACRTableProgress read FOnTableProgress write FOnTableProgress;
    property CryptoParams: TACRCryptoParamsEditor read FCryptoParamsEditor write FCryptoParamsEditor;
    property AfterConnect: TNotifyEvent read FAfterConnect write FAfterConnect;
    property BeforeConnect: TNotifyEvent read FBeforeConnect write FBeforeConnect;
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property AfterServerShutdown: TNotifyEvent read FAfterServerShutdown write FAfterServerShutdown;
    property BeforeServerShutdown: TNotifyEvent read FBeforeServerShutdown write FBeforeServerShutdown;
    property AfterConnectionLost: TNotifyEvent read FAfterConnectionLost write FAfterConnectionLost;
    property BeforeConnectionLost: TNotifyEvent read FBeforeConnectionLost write FBeforeConnectionLost;
{$ENDIF}
    property CaseInsensitive: Boolean read GetCaseInsensitive write SetCaseInsensitive; // added in v.5.90
 end; // TACRDatabase



////////////////////////////////////////////////////////////////////////////////
//
//  TACRAdvFieldDef
//
////////////////////////////////////////////////////////////////////////////////


   TACRAdvFieldDef = class (TObject)
    private
     FName:                 WideString;
     FDataType:             TACRAdvancedFieldType;
     FRequired:             Boolean;
     FSize:                 Integer;

     FDefaultValue:         TACRVariant;
     FMinValue:             TACRVariant;
     FMaxValue:             TACRVariant;

     // Autoinc settings
     FAutoincIncrement:     Int64;
     FAutoincInitialValue:  Int64;
     FAutoincMinValue:      Int64;
     FAutoincMaxValue:      Int64;
     FAutoincCycled:        Boolean;

     FBlobCompressionAlgorithm: TCompressionAlgorithm;
     FBlobCompressionMode:      Byte;
     FBlobBlockSize:            Integer;
    public
     procedure Assign(Source: TACRAdvFieldDef);
     constructor Create;
     destructor Destroy; override;
    public
     property Name: WideString read FName write FName;
     property DataType: TACRAdvancedFieldType read FDataType write FDataType;
     property Required: Boolean read FRequired write FRequired;
     property Size: Integer read FSize write FSize;
     property DefaultValue: TACRVariant read FDefaultValue;
     property MinValue: TACRVariant read FMinValue;
     property MaxValue: TACRVariant read FMaxValue;
     property AutoincIncrement: Int64 read FAutoincIncrement write FAutoincIncrement;
     property AutoincInitialValue: Int64 read FAutoincInitialValue write FAutoincInitialValue;
     property AutoincMinValue:   Int64 read FAutoincMinValue write FAutoincMinValue;
     property AutoincMaxValue:  Int64 read FAutoincMaxValue write FAutoincMaxValue;
     property AutoincCycled:    Boolean read FAutoincCycled write FAutoincCycled;
     property BlobCompressionAlgorithm: TCompressionAlgorithm read FBlobCompressionAlgorithm write FBlobCompressionAlgorithm;
     property BlobCompressionMode: Byte read FBlobCompressionMode write FBlobCompressionMode;
     property BlobBlockSize: Integer read FBlobBlockSize write FBlobBlockSize;
   end;


////////////////////////////////////////////////////////////////////////////////
//
//  TACRAdvFieldDefs
//
////////////////////////////////////////////////////////////////////////////////

   TACRAdvFieldDefs = class (TObject)
    private
     FDefsList:      TList;
    private
     function GetCount: Integer;
     function GetDef(Index: Integer): TACRAdvFieldDef;
     procedure SetDef(Index: Integer; value: TACRAdvFieldDef);
    public
     procedure Assign(Source: TACRAdvFieldDefs);
     constructor Create;
     destructor Destroy; override;
     function AddFieldDef: TACRAdvFieldDef;
     procedure Add(const Name: WideString; DataType: TACRAdvancedFieldType; Size: Integer = 0; Required: Boolean = False);
     procedure DeleteFieldDef(const FieldName: WideString);
     function IndexOf(const Name: WideString): Integer;
     function Find(const Name: WideString): TACRAdvFieldDef;
     function IsVarcharExists: Boolean;
     procedure Clear;
    public
     property Items[Index: Integer]: TACRAdvFieldDef read GetDef write SetDef; default;
     property Count: Integer read GetCount;
   end;


////////////////////////////////////////////////////////////////////////////////
//
//  TACRForeignKeyDef
//
////////////////////////////////////////////////////////////////////////////////
   TACRForeignKeyMatchType = (fkmtDefault,fkmtFull,fkmtPartial);
   TACRForeignKeyAction = (fkaDefault,fkaCascade,fkaSetNull,fkaSetDefault,fkaNoAction);

   TACRForeignKeyDef = class (TPersistent)
    private
     FName:                WideString;
     FMatchType:           TACRForeignKeyMatchType;
     FDeleteAction:        TACRForeignKeyAction;
     FUpdateAction:        TACRForeignKeyAction;
     FReferencedTableName: WideString;
     FColumns:             WideString;
    public
     procedure Assign(Source: TPersistent); override;
     constructor Create;
     destructor Destroy; override;
    public
     property Name: WideString read FName write FName;
     property ReferencedTableName: WideString read FReferencedTableName write FReferencedTableName;
     property Columns: WideString read FColumns write FColumns;
     property MatchType: TACRForeignKeyMatchType read FMatchType write FMatchType;
     property DeleteAction: TACRForeignKeyAction read FDeleteAction write FDeleteAction;
     property UpdateAction: TACRForeignKeyAction read FUpdateAction write FUpdateAction;
   end; // TACRForeignKeyDef


////////////////////////////////////////////////////////////////////////////////
//
//  TACRForeignKeyDefs
//
////////////////////////////////////////////////////////////////////////////////


   TACRForeignKeyDefs = class (TPersistent)
    private
     FDefsList:      TList;
    private
     function GetCount: Integer;
     function GetDef(Index: Integer): TACRForeignKeyDef;
     procedure SetDef(Index: Integer; value: TACRForeignKeyDef);
    public
     procedure Assign(Source: TPersistent); override;
     constructor Create;
     destructor Destroy; override;
     function AddForeignKeyDef: TACRForeignKeyDef;
     procedure Add(const Name: WideString;
                   const Columns: WideString;
                   const ReferencedTableName: WideString;
                   const MatchType: TACRForeignKeyMatchType = fkmtDefault;
                   const DeleteAction: TACRForeignKeyAction = fkaDefault;
                   const UpdateAction: TACRForeignKeyAction = fkaDefault
                   );
     procedure DeleteForeignKeyDef(const Name: WideString);
     procedure Delete(const Index: Integer);
     function Find(const Name: WideString): TACRForeignKeyDef;
     function IndexOf(const Name: WideString): Integer;
     procedure Clear;
    public
     property Items[Index: Integer]: TACRForeignKeyDef read GetDef write SetDef; default;
     property Count: Integer read GetCount;
   end; // TACRForeignKeyDefs


////////////////////////////////////////////////////////////////////////////////
//
//  TACRQueryDataLink
//
////////////////////////////////////////////////////////////////////////////////

  TACRQueryDataLink = class(TDetailDataLink)
  private
    FQuery: TACRQuery;
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
    function GetDetailDataSet: TDataSet; override;
    procedure CheckBrowseMode; override;
  public
    constructor Create(AQuery: TACRQuery);
  end;


////////////////////////////////////////////////////////////////////////////////
//
//  TACRBatchMove
//
////////////////////////////////////////////////////////////////////////////////

{$IFDEF D16H}[ComponentPlatformsAttribute(pidWin32 or pidWin64)]{$ENDIF}
  TACRBatchMove = class(TComponent)
  private
    FOnProgress:            TACRTableProgress;
    FDestination:           TACRTable;
    FSource:                TACRDataset;
    FProblemTable:          TACRTable;
    FChangedTable:          TACRTable;
    FKeyViolTable:          TACRTable;
    FMode:                  TACRBatchMode;
    FAbortOnKeyViol:        Boolean;
    FAbortOnProblem:        Boolean;
{$IFNDEF SQLMEMTABLE}
    FUseTransactions:       Boolean;
    FCommitCount:           Int64;
{$ENDIF}
    FRecordCount:           Int64;
    FMovedCount:            Int64;
    FKeyViolCount:          Int64;
    FProblemCount:          Int64;
    FChangedCount:          Int64;
    FMappings:              TStrings;
    FKeyViolTableName:      WideString;
    FProblemTableName:      WideString;
    FChangedTableName:      WideString;
  protected
    procedure SetMappings(Value: TStrings);
    procedure SetSource(Value: TACRDataset);
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    // progress event
    procedure DoOnProgress(
                            Progress:   Double;
                            var Abort:  Boolean
                           );
    procedure CopyRecords(BatchMode:    TACRBatchMode;
                          FieldCount:   Integer;
                          SourceFields: array of Integer;
                          DestFields:   array of Integer
                          );
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute;
  public
    property ChangedCount: Int64 read FChangedCount;
    property KeyViolCount: Int64 read FKeyViolCount;
    property MovedCount: Int64 read FMovedCount;
    property ProblemCount: Int64 read FProblemCount;
  published
    property AbortOnKeyViol: Boolean read FAbortOnKeyViol write FAbortOnKeyViol default True;
    property AbortOnProblem: Boolean read FAbortOnProblem write FAbortOnProblem default True;
{$IFNDEF SQLMEMTABLE}
    property CommitCount: Int64 read FCommitCount write FCommitCount default ACRDefaultCommitCount;
{$ENDIF}
    property ChangedTableName: WideString read FChangedTableName write FChangedTableName;
    property Destination: TACRTable read FDestination write FDestination;
    property KeyViolTableName: WideString read FKeyViolTableName write FKeyViolTableName;
    property Mappings: TStrings read FMappings write SetMappings;
    property Mode: TACRBatchMode read FMode write FMode default batAppend;
    property OnProgress: TACRTableProgress read FOnProgress write FOnProgress;
    property ProblemTableName: WideString read FProblemTableName write FProblemTableName;
    property RecordCount: Int64 read FRecordCount write FRecordCount default 0;
    property Source: TACRDataset read FSource write SetSource;
{$IFNDEF SQLMEMTABLE}
    property UseTransactions: Boolean read FUseTransactions write FUseTransactions default True;
{$ENDIF}
  end; // TACRBatchMove

(*
////////////////////////////////////////////////////////////////////////////////
//
// TACRAntifreezeThread
//
////////////////////////////////////////////////////////////////////////////////
  TACRAntifreezeThread = class(TACRThread)
  private
    FOwner:             TACRAntifreeze;
  protected
    procedure Execute; override;
    procedure Process;
  public
    constructor Create(Owner: TACRAntifreeze);
    destructor Destroy; override;
  end;// TACRAntifreeze


////////////////////////////////////////////////////////////////////////////////
//
// TACRAntifreeze
//
////////////////////////////////////////////////////////////////////////////////
  TACRAntifreeze = class(TComponent)
  private
    FOwner:             TComponent;
    FAntifreezeThread:  TACRAntifreezeThread;
    FActive:            Boolean;
    FSleep,
    FTimeOut:           DWORD;
  public
    constructor Create(Owner: TComponent);
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write FActive default True;
    // time (msec) to refresh the form
    property TimeOut: DWORD read FTimeOut write FTimeOut;// default ACRAntifreezeTimeOut;
    // max time to destroy refreshing thread
    property Sleep: DWORD read FSleep write FSleep;// default ACRAntifreezeSleep;
  end;// TACRAntifreeze
*)

 procedure ACRFixForeignKeysSelfReferences(TableName, NewTableName: WideString; ForeignKeyDefs: TACRForeignKeyDefs);
 procedure ACRConvertForeignKeyDefToConstraintDef(
            ForeignKeyDef: TACRForeignKeyDef;
            ConstraintDef: TACRConstraintDefForeignKey
                            );

 // convert foreign keys to constraint defs
 procedure ACRConvertForeignKeyDefsToConstraintDefs(
            ForeignKeyDefs: TACRForeignKeyDefs;
            ConstraintDefs: TACRConstraintDefs
            );

 // convert constraint defs to foreign keys
 procedure ConvertConstraintDefsToForeignKeyDefs(
            ConstraintDefs:     TACRConstraintDefs;
            ForeignKeyDefs:     TACRForeignKeyDefs;
            ClearForeignKeys:   Boolean = True
            );

 // convert TFieldDefs to ACRFieldDefs
 procedure ConvertFieldDefsToACRFieldDefs(
                FieldDefs:      TFieldDefs;
                ACRFieldDefs:   TACRFieldDefs
                                         );

 // convert AdvFieldDefs to ACRFieldDefs
 procedure ConvertAdvFieldDefsToACRFieldDefs(
                AdvFieldDefs:      TACRAdvFieldDefs;
                ACRFieldDefs:      TACRFieldDefs;
                IndexDefs:         TACRIndexDefs;
                ACRConstraintDefs: TACRConstraintDefs;
                Temporary:         Boolean
                                            );

 // Add Unic or Primary Key constraint
 function AddConstraintForIndex(
                                  IndexDef:           TACRIndexDef;
                                  ACRConstraintDefs:  TACRConstraintDefs
                                 ): TACRConstraintDef;

 // convert ACRFieldDefs to AdvFieldDefs
 procedure ConvertACRFieldDefsToAdvFieldDefs(
                VisibleFieldDefs:   TACRFieldDefs;
                ACRFieldDefs:   TACRFieldDefs;
                ACRConstraintDefs: TACRConstraintDefs;
                AdvFieldDefs:   TACRAdvFieldDefs
                                        );


 // convert ACRFieldDefs to TFieldDefs
 procedure ConvertACRFieldDefsToFieldDefs(
                ACRFieldDefs:   TACRFieldDefs;
                ACRConstraintDefs: TACRConstraintDefs;
                FieldDefs:      TFieldDefs
                                         );


 // convert AdvFieldDefs to FieldDefs
 procedure ConvertAdvFieldDefsToFieldDefs(AdvFieldDefs: TACRAdvFieldDefs; FieldDefs: TFieldDefs);

 // convert FieldDefs to AdvFieldDefs
 procedure ConvertFieldDefsToAdvFieldDefs(FieldDefs: TFieldDefs; AdvFieldDefs: TACRAdvFieldDefs);


 // get String list from String with names
 procedure GetNamesList(List: TACRWideStringList; const Names: WideString);
 // replaces 'field1,field2' to 'field1;field2'
 function ACRReplaceCommaToSemiColonInFieldNameNames(const Names: WideString): WideString;

 // fill ACRIndexDef
 procedure FillACRIndexDef(
              ACRIndexDef:         TACRIndexDef;
              const Name,
              Fields: WideString;
              Options: TIndexOptions;
              const DescFields: WideString;
              const CaseInsFields: WideString;
              FieldDefs:           TFieldDefs;
              AdvFieldDefs:        TACRAdvFieldDefs
                           );

 // convert TIndexDef to TACRIndexDef
 procedure ConvertIndexDefToACRIndexDef(
                IndexDef:      TIndexDef;
                ACRIndexDef:   TACRIndexDef;
                FieldDefs:     TFieldDefs;
                AdvFieldDefs:  TACRAdvFieldDefs
                                         );

 // convert TIndexDefs to ACRIndexDefs
 procedure ConvertIndexDefsToACRIndexDefs(
                IndexDefs:      TIndexDefs;
                ACRIndexDefs:   TACRIndexDefs;
                FieldDefs:      TFieldDefs;
                AdvFieldDefs:   TACRAdvFieldDefs
                                         );

 // convert ACRIndexDefs to TIndexDefs
 procedure ConvertACRIndexDefsToIndexDefs(
                ACRIndexDefs:   TACRIndexDefs;
                IndexDefs:      TIndexDefs
                                         );

 // return true if field exists
 function FindFieldInFieldDefs(FieldDefs: TFieldDefs; FieldName : WideString): Boolean;

 // compression algorithm
function ConvertCompressionAlgorithmToACRCompressionAlgorithm(
            CompressionAlgorithm: TCompressionAlgorithm
          ): TACRCompressionAlgorithm;
 // compression algorithm
function ConvertACRCompressionAlgorithmToCompressionAlgorithm(
            CompressionAlgorithm: TACRCompressionAlgorithm
          ): TCompressionAlgorithm;

// copy records and return error log
function CopyDatasets(
                        SourceDataset:                TDataset;
                        DestinationDataset:           TDataset;
                        UseSourceDatasetForProgress:  Boolean;
                        Operation:                    TACRTableOperation;
                        FieldMapByFieldNames:         Boolean = True;
                        FieldNames:                   TACRWideStringList = nil
            ): WideString;

function ACRGetCurrentVersion: String;

{$IFDEF TRIAL_VERSION}
procedure acrtrshnm;
{$ENDIF}

var
  Sessions:              TACRSessionList;
  ACRDatasetsList:       TList;
  ACRDatasets:           TThreadList;

implementation

uses Math;

var
  FCSect:                TRTLCriticalSection;
  CurrentSessionManager: TACRSessionComponentManager;
  Session:               TACRSession;
  Initialized:           Boolean;


////////////////////////////////////////////////////////////////////////////////
//
//  TACRQueryDataLink
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRQueryDataLink.Create(AQuery: TACRQuery);
begin
  inherited Create;
  FQuery := AQuery;
end;// Create


//------------------------------------------------------------------------------
// ActiveChanged
//------------------------------------------------------------------------------
procedure TACRQueryDataLink.ActiveChanged;
begin
  if FQuery.Active then
    FQuery.RefreshParams;
end;// ActiveChanged


//------------------------------------------------------------------------------
// GetDetailDataSet
//------------------------------------------------------------------------------
function TACRQueryDataLink.GetDetailDataSet: TDataSet;
begin
  Result := FQuery;
end;// GetDetailDataSet


//------------------------------------------------------------------------------
// RecordChanged
//------------------------------------------------------------------------------
procedure TACRQueryDataLink.RecordChanged(Field: TField);
begin
  if (Field = nil) and FQuery.Active
    then FQuery.RefreshParams;
end;// RecordChanged


//------------------------------------------------------------------------------
// CheckBrowseMode
//------------------------------------------------------------------------------
procedure TACRQueryDataLink.CheckBrowseMode;
begin
  if FQuery.Active then
    FQuery.CheckBrowseMode;
end;// CheckBrowseMode


//------------------------------------------------------------------------------
// inits engine
//------------------------------------------------------------------------------
procedure InitializeACREngine;
begin
  if (not Initialized) then
   begin
     Initialized:=True;
     CurrentSessionManager:=TACRSessionComponentManager.Create;
   end;
end;


//------------------------------------------------------------------------------
// finalizes engine
//------------------------------------------------------------------------------
procedure FinalizeACREngine;
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
function ACRDefaultSession: TACRSession;
begin
   Result := ACRMain.Session;
end;

//------------------------------------------------------------------------------
// gets current session manager
//------------------------------------------------------------------------------
function ACRGetCurrentSession: TACRSessionComponentManager;
begin
  if (not Initialized) then
   raise EACRException.Create(20007, ErrorAEngineNotInitialized);
  Result := CurrentSessionManager;
end;

//------------------------------------------------------------------------------
// sets current session manager
//------------------------------------------------------------------------------
procedure ACRSetCurrentSession(Value: TACRSessionComponentManager);
begin
  CurrentSessionManager := Value;
end;

//------------------------------------------------------------------------------
// creates session manager
//------------------------------------------------------------------------------
procedure ACRStartSession(var Value: TACRSessionComponentManager);
begin
  Value := TACRSessionComponentManager.Create;
end;

//------------------------------------------------------------------------------
// frees session manager
//------------------------------------------------------------------------------
procedure ACRCloseSession(Value: TACRSessionComponentManager);
begin
  if (Value <> nil) then
    Value.Free;
end;


////////////////////////////////////////////////////////////////////////////////
//
//  TACRSessionList
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRSessionList.Create;
begin
  inherited Create;
  FSessions:=TThreadList.Create;
  FSessionNumbers:=TBits.Create;
  InitializeCriticalSection(FCsect);
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRSessionList.Destroy;
begin
  CloseAll;
  DeleteCriticalSection(FCsect);
  FSessionNumbers.Free;
  FSessions.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// adds session to list
//------------------------------------------------------------------------------
procedure TACRSessionList.AddSession(ASession: TACRSession);
var
  List: TList;
begin
  List:=FSessions.LockList;
  try
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
procedure TACRSessionList.CloseAll;
var
  I: Integer;
  List: TList;
begin
  List:=FSessions.LockList;
  try
    for I:=List.Count-1 downto 0 do
      TACRSession(List[I]).Free;
  finally
    FSessions.UnlockList;
  end;
end;// CloseAll


//------------------------------------------------------------------------------
// Gets sessions count
//------------------------------------------------------------------------------
function TACRSessionList.GetCount: Integer;
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
function TACRSessionList.GetCurrentSession: TACRSession;
var
  Handle: TACRSessionComponentManager;
  I: Integer;
  List: TList;
begin
  List:=FSessions.LockList;
  try
    Handle := CurrentSessionManager;
    for I:=0 to List.Count-1 do
      begin
       if (TACRSession(List[I]).FHandle=Handle) then
         begin
           Result:=TACRSession(List[I]);
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
function TACRSessionList.GetSession(Index: Integer): TACRSession;
var
  List: TList;
begin
  List:=FSessions.LockList;
  try
    Result:=TACRSession(List[Index]);
  finally
    FSessions.UnlockList;
  end;
end;// GetSession


//------------------------------------------------------------------------------
// Gets session by Name
//------------------------------------------------------------------------------
function TACRSessionList.GetSessionByName(const SessionName: AnsiString): TACRSession;
begin
  if (SessionName = '') then
    Result:=Session
  else
    Result := FindSession(SessionName);
  if (Result = nil) then
    raise EACRException.Create(20002, ErrorAInvalidSessionName, [SessionName]);
end;// GetSessionByName


//------------------------------------------------------------------------------
// Finds session by name
//------------------------------------------------------------------------------
function TACRSessionList.FindSession(const SessionName: AnsiString): TACRSession;
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
procedure TACRSessionList.GetSessionNames(List: TStrings);
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
        with TACRSession(SList[I]) do
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
function TACRSessionList.OpenSession(const SessionName: AnsiString): TACRSession;
begin
  Result := FindSession(SessionName);
  if (Result = nil) then
    begin
      Result := TACRSession.Create(nil);
      Result.SessionName := SessionName;
    end;
  Result.SetActive(True);
end;// OpenSession


//------------------------------------------------------------------------------
// Sets current session
//------------------------------------------------------------------------------
procedure TACRSessionList.SetCurrentSession(Value: TACRSession);
begin
  ACRSetCurrentSession(Value.FHandle);
end;// SetCurrentSession


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TACRSession
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRSession.Lock(WriteMode: Boolean);
begin
  EnterCriticalSection(FCSect);
end; // Lock

//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRSession.Unlock;
begin
  LeaveCriticalSection(FCSect);
end; // Unlock


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRSession.Create(AOwner: TComponent);
begin
  ValidateAutoSession(AOwner,False);
  inherited Create(AOwner);
  FDatabases:=TList.Create;
  Sessions.AddSession(Self);
  FKeepConnections:=True;
  FHandle := nil;
  {$IFDEF TRIAL_VERSION}
  if (IsDesignMode) then
   acrtrshnm;
  {$ENDIF} 
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRSession.Destroy;
begin
  SetActive(False);
  Sessions.FSessions.Remove(Self);
  FDatabases.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// adds database
//------------------------------------------------------------------------------
procedure TACRSession.AddDatabase(Value: TACRDatabase);
begin
 LockSession(True);
 try
  FDatabases.Add(Value);
 finally
  UnlockSession;
 end;
 DBNotification(dbAdd,Value);
end;// AddDatabase


//------------------------------------------------------------------------------
// raises exception if active
//------------------------------------------------------------------------------
procedure TACRSession.CheckInactive;
begin
  if Active then
    DatabaseError(ErrorASessionActive, Self);
end;// CheckInactive


//------------------------------------------------------------------------------
// closes session
//------------------------------------------------------------------------------
procedure TACRSession.Close;
begin
  SetActive(False);
end;// Close


//------------------------------------------------------------------------------
// closes database
//------------------------------------------------------------------------------
procedure TACRSession.CloseDatabase(Database: TACRDatabase);
var bClose: Boolean;
begin
  Database.FThreadSyncRefCount.Lock(true);
  try
   if (Database.FRefCount > 0) then
    Dec(Database.FRefCount)
   else
    Database.FRefCount := 0;
   bClose := (Database.FRefCount = 0) and (not Database.FKeepConnection);
  finally
    Database.FThreadSyncRefCount.Unlock
  end;
  if (bClose) then
   begin
    if not Database.Temporary then
     Database.Close
    else
     if not (csDestroying in ComponentState) then
      Database.Free;
   end;
end;// CloseDatabase


//------------------------------------------------------------------------------
// sends notification
//------------------------------------------------------------------------------
procedure TACRSession.DBNotification(DBEvent: TACRDatabaseEvent; const Param);
begin
  if Assigned(FOnDBNotify) then FOnDBNotify(DBEvent, Param);
end;// DBNotification


//------------------------------------------------------------------------------
// drops all connections
//------------------------------------------------------------------------------
procedure TACRSession.DropConnections;
var
  I:          Integer;
  Database:   TACRDatabase;
begin
 LockSession(False);
 try
  for I := FDatabases.Count - 1 downto 0 do
   begin
    Database := TACRDatabase(FDatabases[I]);
    Database.FThreadSyncRefCount.Lock(True);
    try
     if (Database.Temporary and (Database.FRefCount = 0)) then
        Database.Free;
    finally
      Database.FThreadSyncRefCount.Unlock;
    end;
   end;
 finally
  UnlockSession;
 end;
end;// DropConnections


//------------------------------------------------------------------------------
// finds database with specified owner
//------------------------------------------------------------------------------
function TACRSession.DoFindDatabase(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean;
                            AOwner:             TComponent
                                   ): TACRDatabase;
var
  I: Integer;
begin
 Result := nil;
 LockSession(False);
 try
   if AOwner <> nil then
     for I := 0 to FDatabases.Count - 1 do
      begin
        Result := FDatabases[I];
        if (Result.Owner = AOwner) and (Result.FHandleShared) and
          (AnsiCompareText(Result.DatabaseName, DatabaseName) = 0) and
          (Result.Temporary = Temporary) and
          (Result.InMemory = InMemory) then
          Exit
        else
          Result := nil;
      end;
   for I := 0 to FDatabases.Count - 1 do
    begin
      Result := FDatabases[I];
      if  (AnsiCompareText(Result.DatabaseName, DatabaseName) = 0) and
          (Result.Temporary = Temporary) and
          (Result.InMemory = InMemory) then
           Exit
      else
         Result := nil;
    end;
 finally
   UnlockSession;
 end;
end;// DoFindDatabase


//------------------------------------------------------------------------------
// session is active?
//------------------------------------------------------------------------------
function TACRSession.GetActive: Boolean;
begin
  Result := FHandle <> nil;
end;// GetActive


//------------------------------------------------------------------------------
// gets database by No
//------------------------------------------------------------------------------
function TACRSession.GetDatabase(Index: Integer): TACRDatabase;
begin
  Result := FDatabases[Index];
end;// GetDatabase


//------------------------------------------------------------------------------
// gets count of connected databases
//------------------------------------------------------------------------------
function TACRSession.GetDatabaseCount: Integer;
begin
 LockSession(False);
 try
  Result := FDatabases.Count;
 finally
  UnlockSession;
 end;
end;// GetDatabaseCount


//------------------------------------------------------------------------------
// get list of database names
//------------------------------------------------------------------------------
procedure TACRSession.GetDatabaseNames(List: TStrings);
var
  I: Integer;
  Names: TStringList;
begin
 LockSession(False);
 try
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    for I := 0 to FDatabases.Count - 1 do
      with TACRDatabase(FDatabases[I]) do
         Names.Add(DatabaseName);
    List.Assign(Names);
  finally
    Names.Free;
  end;
 finally
   UnlockSession;
 end;
end;// GetDatabaseNames


//------------------------------------------------------------------------------
// get list of database tables
//------------------------------------------------------------------------------
procedure TACRSession.GetTableNames(
                    const DatabaseName: AnsiString;
                    const InMemory:     Boolean;
                    const Temporary:    Boolean;
                    List:               TStrings
                                   );
var
   Database:        TACRDatabase;
   tempList:        TACRWideStringList;
   i:               Integer;
begin
  tempList := TACRWideStringList.Create;
  try
    List.BeginUpdate;
    try
      List.Clear;
      try
        Database := OpenDatabase(DatabaseName,InMemory,Temporary);
        if (Database <> nil) then
         try
          if (Database <> nil) and (Database.Handle <> nil) then
           begin
            Database.Handle.GetTablesList(tempList);
            for i := 0 to tempList.Count-1 do
             List.Add(String(tempList.Strings[i]));
           end;
         finally
          CloseDatabase(Database);
         end;
      except
       if (not (csDesigning in ComponentState)) then
        raise;
      end;
    finally
       List.EndUpdate;
    end;
  finally
    tempList.Free;
  end;
end;// GetTableNames


//------------------------------------------------------------------------------
// get table names in wide string list
//------------------------------------------------------------------------------
procedure TACRSession.GetTableNames(
                const DatabaseName: AnsiString;
                const InMemory:     Boolean;
                const Temporary:    Boolean;
                List:               TACRWideStringList
                       );
begin

end; // GetTableNames


//------------------------------------------------------------------------------
// gets handle
//------------------------------------------------------------------------------
function TACRSession.GetHandle: TACRSessionComponentManager;
begin
  if (FHandle <> nil) then
    ACRSetCurrentSession(FHandle)
  else
    SetActive(True);
  Result:=FHandle;
end;// GetHandle


//------------------------------------------------------------------------------
// loaded
//------------------------------------------------------------------------------
procedure TACRSession.Loaded;
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
procedure TACRSession.LockSession(WriteMode: Boolean);
begin
  if (FLockCount=0) then
    begin
      Lock(WriteMode);
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
procedure TACRSession.UnlockSession;
begin
  Dec(FLockCount);
  if (FLockCount=0) then
   Unlock;
end;// UnlockSession


//------------------------------------------------------------------------------
// makes session current
//------------------------------------------------------------------------------
procedure TACRSession.MakeCurrent;
begin
  if (FHandle <> nil) then
    ACRSetCurrentSession(FHandle)
  else
    SetActive(True);
end;// MakeCurrent


//------------------------------------------------------------------------------
// send notification to datasets and databases
//------------------------------------------------------------------------------
procedure TACRSession.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);
  if AutoSessionName and (Operation=opInsert) then
    begin
      if (AComponent is TACRDataSet) then
        TACRDataSet(AComponent).FSessionName:=Self.SessionName
      else
       if (AComponent is TACRDatabase) then
        TACRDatabase(AComponent).FSession:=Self;
      end;
end;// Notification


//------------------------------------------------------------------------------
// opens session
//------------------------------------------------------------------------------
procedure TACRSession.Open;
begin
  SetActive(True);
end;// Open


//------------------------------------------------------------------------------
// opens database (thread-safe)
//------------------------------------------------------------------------------
function TACRSession.DoOpenDatabase(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean;
                            AOwner:             TComponent
                                   ): TACRDatabase;
var
  TempDatabase: TACRDatabase;
  t: Cardinal;
begin
 TempDatabase := nil;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('> TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  Result := DoFindDatabase(DatabaseName, InMemory, Temporary, AOwner);
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('1 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
if (Result <> nil) then
aaWriteToLog('1.1 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Result.DatabaseName = '+Result.DatabaseName
);
{$ENDIF}
 if (Result = nil) then
   begin
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('4 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
    TempDatabase := TACRDatabase.Create(Self);
    TempDatabase.SkipDatabaseNameCheck := True;
    TempDatabase.Temporary := Temporary;
    TempDatabase.InMemory := InMemory;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('4.1 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
    TempDatabase.DatabaseName := DatabaseName;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('4.2 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
    TempDatabase.SkipDatabaseNameCheck := False;
    if (ACRFindDatabaseData(True,False,DatabaseName) <> nil) or
       (DatabaseName = ACRMemoryDatabaseName) then
     TempDatabase.FInMemory := True;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('4.3 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
// commented in 4.95 - to avoid problems with
// opened databases that were created temporary (for TACRQuery)
{IFNDEF SQLMEMTABLE}
//    TempDatabase.KeepConnection := FKeepConnections;
{ENDIF}
    TempDatabase.KeepConnection := False;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('5 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
    Result := TempDatabase;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('6 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
   end; // (Result = nil)
{$IFNDEF SQLMEMTABLE}
 if (Result <> nil) and
    ((not Result.FLocalDatabase) or (Result.DatabaseFileName <> '')) then
     begin
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('7 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
       if (not Result.Exists) then
        begin
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('8 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'TempDatabase = '+IntToHex(Integer(TempDatabase),8)
);
{$ENDIF}
         if (TempDatabase <> nil) then
           TempDatabase.Free;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('9 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
         Result := nil;
         Exit;
        end; // (not Result.Exists)
     end;
{$ENDIF} // not SQLMemTable
  try
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('10 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'TempDatabase = '+IntToHex(Integer(TempDatabase),8)
+#13#10+'Result.DatabaseName = '+Result.DatabaseName
);
{$ENDIF}
    Result.Open;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('11 TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'TempDatabase = '+IntToHex(Integer(TempDatabase),8)
+#13#10+'Result.FRefCount = '+IntToStr(Result.FRefCount)
);
{$ENDIF}
//    Inc(Result.FRefCount);
  except
   on e: Exception do
    begin
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('Error: TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName+#13#10+e.Message);
{$ENDIF}
      if (TempDatabase <> nil) then
        TempDatabase.Free;
      Result := nil;
    end;
  end;
{$IFDEF DEBUG_TRACE_TACRSession_DoOpenDatabase}
aaWriteToLog('< TACRSession.DoOpenDatabase. DatabaseName = '+DatabaseName
+#13#10+'Name = '+Name
+#13#10+'SessionName = '+SessionName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'TempDatabase = '+IntToHex(Integer(TempDatabase),8)
);
{$ENDIF}
end;// DoOpenDatabase


//------------------------------------------------------------------------------
// find DB manager by db name
//------------------------------------------------------------------------------
function TACRSession.FindDatabaseHandle(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean
                                       ): TACRBaseSession;
var
  I:  Integer;
  DB: TACRDatabase;
begin
 Result := nil;
 LockSession(False);
 try
  for I := 0 to FDatabases.Count - 1 do
   begin
    DB := FDatabases[I];
    if ((DB.Handle <> nil) and DB.FHandleShared)then
     if (AnsiCompareText(DB.DatabaseName, DatabaseName) = 0) and
        (DB.Temporary = Temporary) and
        (DB.InMemory = InMemory) then
      begin
        Result := DB.Handle;
        Exit;
      end;
   end;
 finally
   UnlockSession;
 end;
end;// FindDatabaseHandle


//------------------------------------------------------------------------------
// opens database
//------------------------------------------------------------------------------
function TACRSession.OpenDatabase(
                            const DatabaseName: AnsiString;
                            const InMemory:     Boolean;
                            const Temporary:    Boolean
                                  ): TACRDatabase;
begin
  Result := DoOpenDatabase(DatabaseName,InMemory,Temporary,nil);
end;// OpenDatabase


//------------------------------------------------------------------------------
// not auto-session?
//------------------------------------------------------------------------------
function TACRSession.SessionNameStored: Boolean;
begin
  Result := not FAutoSessionName;
end;// SessionNameStored


//------------------------------------------------------------------------------
// removes database from list
//------------------------------------------------------------------------------
procedure TACRSession.RemoveDatabase(Value: TACRDatabase);
begin
  FDatabases.Remove(Value);
  DBNotification(dbRemove, Value);
end;// RemoveDatabase


//------------------------------------------------------------------------------
// opens session
//------------------------------------------------------------------------------
procedure TACRSession.SetActive(Value: Boolean);
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
procedure TACRSession.SetAutoSessionName(Value: Boolean);
begin
  if Value <> FAutoSessionName then
  begin
    if Value then
    begin
      CheckInActive;
      ValidateAutoSession(Owner, True);
      FSessionNumber := -1;
      Lock(true);
      try
        with Sessions do
        begin
          FSessionNumber := FSessionNumbers.OpenBit;
          FSessionNumbers[FSessionNumber] := True;
        end;
      finally
        Unlock;
      end;
      UpdateAutoSessionName;
    end
    else
    begin
      if FSessionNumber > -1 then
      begin
        Lock(true);
        try
          Sessions.FSessionNumbers[FSessionNumber] := False;
        finally
          Unlock;
        end;
      end;
    end;
    FAutoSessionName := Value;
  end;
end;// SetAutoSessionName


//------------------------------------------------------------------------------
// set name of component
//------------------------------------------------------------------------------
procedure TACRSession.SetName(const NewName: TComponentName);
begin
  inherited SetName(NewName);
  if FAutoSessionName then
    UpdateAutoSessionName;
end;// SetName


//------------------------------------------------------------------------------
// sets the name of session
//------------------------------------------------------------------------------
procedure TACRSession.SetSessionName(const Value: AnsiString);
var
  Ses: TACRSession;
begin
  if (FAutoSessionName and (not FUpdatingAutoSessionName)) then
   DatabaseError(ErrorAAutoSessionActive,Self);
  CheckInActive;
  if Value <> '' then
   begin
    Ses := Sessions.FindSession(Value);
    if (not ((Ses = nil) or (Ses = Self))) then
      DatabaseErrorFmt(ErrorADuplicateSessionName, [Value], Self);
   end;
  FSessionName := Value
end;// SetSessionName


//------------------------------------------------------------------------------
// sets session name to datasets and databases
//------------------------------------------------------------------------------
procedure TACRSession.SetSessionNames;
var
  I: Integer;
  Component: TComponent;
begin
  if Owner <> nil then
    for I := 0 to Owner.ComponentCount - 1 do
    begin
      Component := Owner.Components[I];
      if (Component is TACRDataSet) and
        (AnsiCompareText(TACRDataSet(Component).SessionName, Self.SessionName) <> 0) then
        TACRDataSet(Component).SessionName := Self.SessionName
      else if (Component is TACRDatabase) and
        (AnsiCompareText(TACRDatabase(Component).FSessionName, Self.SessionName) <> 0) then
        TACRDatabase(Component).FSessionName := Self.FSessionName
    end;
end;// SetSessionNames


//------------------------------------------------------------------------------
// starts session
//------------------------------------------------------------------------------
procedure TACRSession.StartSession(Value: Boolean);
var
  I: Integer;
begin
  Lock(true);
  try
    if Value then
      begin
        if Assigned(FOnStartup) then
          FOnStartup(Self);
        // session name missing?
        if (FSessionName = '') then
         DatabaseError(ErrorASessionNameMissing, Self);
        // activate default session
        if (ACRDefaultSession <> Self) then
            ACRDefaultSession.Active:=True;
        // default session?
        if FDefault then
          begin
            InitializeACREngine;
            FHandle := ACRGetCurrentSession;
          end
        else
          ACRStartSession(FHandle);
      end
    else
     begin
       ACRSetCurrentSession(FHandle);
       for I:=FDatabases.Count-1 downto 0 do
         begin
           with TACRDatabase(FDatabases[I]) do
             begin
               if Temporary then
                 Free
               else
                 Close;
             end;
         end;
       if FDefault then
         FinalizeACREngine
       else
         begin
           ACRCloseSession(FHandle);
           ACRSetCurrentSession(Session.FHandle);
         end;
       FHandle:=nil;
     end;
  finally
    Unlock;
  end;
end;// StartSession


//------------------------------------------------------------------------------
// updates auto-session name
//------------------------------------------------------------------------------
procedure TACRSession.UpdateAutoSessionName;
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
procedure TACRSession.ValidateAutoSession(AOwner: TComponent; AllSessions: Boolean);
var
  I: Integer;
  Component: TComponent;
begin
  if AOwner <> nil then
    for I := 0 to AOwner.ComponentCount - 1 do
    begin
      Component := AOwner.Components[I];
      if (Component <> Self) and (Component is TACRSession) then
        if AllSessions then
         DatabaseError(ErrorAAutoSessionExclusive, Self)
        else
        if TACRSession(Component).AutoSessionName then
         DatabaseErrorFmt(ErrorAAutoSessionExists, [Component.Name], Self);
    end;
end;// ValidateAutoSession


////////////////////////////////////////////////////////////////////////////////
//
// TACRDataset
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF D6H}


////////////////////////////////////////////////////////////////////////////////
//
// IProviderSupport
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetUpdateException
//------------------------------------------------------------------------------
function TACRDataset.PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError;
begin
  Result := inherited PSGetUpdateException(E, Prev);
end; // PSGetUpdateException


//------------------------------------------------------------------------------
// IsSQLSupported
//------------------------------------------------------------------------------
function TACRDataset.PSIsSQLSupported: Boolean;
begin
  Result := True;
end; // PSIsSQLSupported


//------------------------------------------------------------------------------
// Reset
//------------------------------------------------------------------------------
procedure TACRDataset.PSReset;
begin
  inherited PSReset;
end; // PSReset


//------------------------------------------------------------------------------
// UpdateRecord
//------------------------------------------------------------------------------
function TACRDataset.PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean;
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
procedure TACRDataset.PSEndTransaction(Commit: Boolean);
begin
  try
{$IFNDEF SQLMEMTABLE}
    if (Commit) then
      Database.Commit
    else
      Database.Rollback;
{$ENDIF}
  finally
    SetDBFlag(dbfProvider, False);
  end;
end; // PSEndTransaction

//------------------------------------------------------------------------------
// fixes buggy quoted field and table names
//------------------------------------------------------------------------------
function TACRDataset.FixNames(QueryText: WideString): WideString;
var Lexer:  TACRLexer;
    token:  TToken;

  procedure AddToken(SkipSpace: Boolean = False);
  var Space: AnsiString;
  begin
    if (SkipSpace) then
     Space := ''
    else
     Space := ' ';
    case token.TokenType of
     tktNone: Result := Result+Space;
     tktLeftParenthesis,tktRightParenthesis,
     tktComma,tktDot,
     tktInt,tktFloat,
     tktReservedWord,tktString:
        Result := Result + token.Text+Space;
     tktQuotedString: Result := Result + AnsiQuotedStr(token.Text,'"')+Space;
     tktBracketedString: Result := Result + '['+token.Text+']'+Space;
     tktParameter: Result := Result + ':'+token.Text+Space;
    end;
  end;


begin
  Result := '';
  Lexer := TACRLexer.Create(QueryText,nil);
  try
    while (Lexer.GetNextCommand) do
     begin
       if (Lexer.GetCurrentToken(token)) then
        repeat
          if (token.TokenType = tktString) and (token.Text = '@') then
           begin
            Result := Result + '[';
            if (Lexer.GetNextToken(token)) then
              AddToken(True);
            if (not Lexer.GetNextToken(token)) then
             break;
            Result := Result+'] ';
            if (not Lexer.GetNextToken(token)) then
             break;
           end;
         AddToken;
        until (not Lexer.GetNextToken(token));
       Result := Result +';'+#13#10;
     end; // command
  finally
    Lexer.Free;
  end;
end; // FixNames


{$IFDEF D17H}
function TACRDataset.PSExecuteStatement(const ASQL: string; AParams: TParams): Integer;
begin
  Self.PSExecuteStatement(ASQL,AParams,nil);
end;


function TACRDataset.PSExecuteStatement(const ASQL: string; AParams: TParams;
      var ResultSet: TDataSet): Integer;
var
  InProvider:   Boolean;
  ResultSetNil: Boolean;
  i,n:          Integer;
  paramName:    AnsiString;
begin
  ResultSetNil := (ResultSet = nil);
  SetDBFlag(dbfProvider, True);
  InProvider := dbfProvider in DBFlags;
  try
    ResultSet := TACRQuery.Create(nil);
    try
      TACRQuery(ResultSet).InMemory := FInMemory;
      TACRQuery(ResultSet).DatabaseName := FDatabaseName;
      TACRQuery(ResultSet).SessionName := FSessionName;
      TACRQuery(ResultSet).SQL.Text := FixNames(ASQL);
      n := TACRQuery(ResultSet).FParams.Count;
      if (n > 0) then
       begin
        // fix in v.4.70 for ClientDataSet ApplyUpdates after insert -  ? names
        for i := 0 to AParams.Count-1 do
         if (i < n) then
          begin
           paramName := TACRQuery(ResultSet).FParams.Items[i].Name;
           TACRQuery(ResultSet).FParams.Items[i].Assign(AParams.Items[i]);
           TACRQuery(ResultSet).FParams.Items[i].Name := paramName;
          end
         else
          TACRQuery(ResultSet).FParams.Add.Assign(AParams.Items[i]);
       end
      else
       TACRQuery(ResultSet).FParams.Assign(AParams);
      // commented in v.4.60 as it is done automatically in SQL.Text assignment
{
      if (AParams <> nil) then
       if (AParams.Count > 0) then
        FixParams(ResultSet);
}
      TACRQuery(ResultSet).ExecSQL;
      Result := TACRQuery(ResultSet).RowsAffected;
    finally
      if (ResultSetNil) then
       begin
        TACRQuery(ResultSet).Free;
        ResultSet := nil;
       end;
    end;
  finally
    SetDBFlag(dbfProvider, InProvider);
  end;
end; // PSExecuteStatement

//------------------------------------------------------------------------------
// GetAttributes
//------------------------------------------------------------------------------
procedure TACRDataset.PSGetAttributes(List: TPacketAttributeList);
begin
  inherited PSGetAttributes(List);
end; // PSGetAttributes


{$ELSE}
//------------------------------------------------------------------------------
// ExecuteStatemnt
//------------------------------------------------------------------------------
function TACRDataset.PSExecuteStatement(const ASQL: String; AParams: TParams;
  ResultSet: Pointer = nil): Integer;
var
  InProvider:   Boolean;
  ResultSetNil: Boolean;
  i,n:          Integer;
  paramName:    AnsiString;
begin
  ResultSetNil := (ResultSet = nil);
  SetDBFlag(dbfProvider, True);
  InProvider := dbfProvider in DBFlags;
  try
    ResultSet := TACRQuery.Create(nil);
    try
      TACRQuery(ResultSet).InMemory := FInMemory;
      TACRQuery(ResultSet).DatabaseName := FDatabaseName;
      TACRQuery(ResultSet).SessionName := FSessionName;
      TACRQuery(ResultSet).SQL.Text := FixNames(ASQL);
      n := TACRQuery(ResultSet).FParams.Count;
      if (n > 0) then
       begin
        // fix in v.4.70 for ClientDataSet ApplyUpdates after insert -  ? names
        for i := 0 to AParams.Count-1 do
         if (i < n) then
          begin
           paramName := TACRQuery(ResultSet).FParams.Items[i].Name;
           TACRQuery(ResultSet).FParams.Items[i].Assign(AParams.Items[i]);
           TACRQuery(ResultSet).FParams.Items[i].Name := paramName;
          end
         else
          TACRQuery(ResultSet).FParams.Add.Assign(AParams.Items[i]);
       end
      else
       TACRQuery(ResultSet).FParams.Assign(AParams);
      // commented in v.4.60 as it is done automatically in SQL.Text assignment
{
      if (AParams <> nil) then
       if (AParams.Count > 0) then
        FixParams(ResultSet);
}
      TACRQuery(ResultSet).ExecSQL;
      Result := TACRQuery(ResultSet).RowsAffected;
    finally
      if (ResultSetNil) then
       begin
        TACRQuery(ResultSet).Free;
        ResultSet := nil;
       end;
    end;
  finally
    SetDBFlag(dbfProvider, InProvider);
  end;
end; // PSExecuteStatement

//------------------------------------------------------------------------------
// GetAttributes
//------------------------------------------------------------------------------
procedure TACRDataset.PSGetAttributes(List: TList);
begin
  inherited PSGetAttributes(List);
end; // PSGetAttributes


{$ENDIF}

//------------------------------------------------------------------------------
// GetQuoteAnsiChar
//------------------------------------------------------------------------------
function TACRDataset.PSGetQuoteChar: String;
begin
  Result := ACRPSQuoteChar;
end; // PSGetQuoteAnsiChar


//------------------------------------------------------------------------------
// InTransaction
//------------------------------------------------------------------------------
function TACRDataset.PSInTransaction: Boolean;
var db: TACRDatabase;
begin
  Result := False;
{$IFNDEF SQLMEMTABLE}
  if (FHandle = nil) then
   begin
    if (FDatabase <> nil) then
     Result := FDatabase.InTransaction
    else
     begin
      db := Session.DoFindDatabase(FDatabaseName,FInMemory,FTemporary,nil);
      if (db <> nil) then
       Result := db.InTransaction;
     end;
   end
  else
   Result := FHandle.Session.InTransaction;
{$ENDIF}   
end; // PSInTransaction


//------------------------------------------------------------------------------
// IsSQLBased
//------------------------------------------------------------------------------
function TACRDataset.PSIsSQLBased: Boolean;
begin
  Result := True;
end; // PSIsSQLBased


//------------------------------------------------------------------------------
// StartTransaction
//------------------------------------------------------------------------------
procedure TACRDataset.PSStartTransaction;
begin
  SetDBFlag(dbfProvider, True);
  try
{$IFNDEF SQLMEMTABLE}
    Database.StartTransaction;
{$ENDIF}
  except
    SetDBFlag(dbfProvider, False);
    raise;
  end
end; // PSStartTransaction


{$ENDIF}


//------------------------------------------------------------------------------
// init key buffer
//------------------------------------------------------------------------------
function TACRDataset.InitKeyBuffer(Buffer: TACRRecordBuffer): TACRRecordBuffer;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10280,ErrorLNilPointer);
  Result := Buffer;
  FHandle.InternalInitKeyBuffer(Result);
end; // InitKeyBuffer


//------------------------------------------------------------------------------
// allocate key buffers
//------------------------------------------------------------------------------
procedure TACRDataset.AllocKeyBuffers;
var
  KeyIndex: TACRKeyIndex;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10281,ErrorLNilPointer);
  try
    for KeyIndex := Low(TACRKeyIndex) to High(TACRKeyIndex) do
      FKeyBuffers[KeyIndex] := InitKeyBuffer(FHandle.AllocateKeyRecordBuffer);
  except
    FreeKeyBuffers;
    raise;
  end;
end; // AllocKeyBuffers


//------------------------------------------------------------------------------
// free key buffers
//------------------------------------------------------------------------------
procedure TACRDataset.FreeKeyBuffers;
var
  KeyIndex: TACRKeyIndex;
begin
  for KeyIndex := Low(TACRKeyIndex) to High(TACRKeyIndex) do
   if (FKeyBuffers[KeyIndex] <> nil) then
    begin
     FreeRecordBuffer(TRecordBuffer(FKeyBuffers[KeyIndex]));
     FKeyBuffers[KeyIndex] := nil;
    end;
end; // FreeKeyBuffers


//------------------------------------------------------------------------------
// field defs support
//------------------------------------------------------------------------------
function TACRDataset.FieldDefsStored: Boolean;
begin
  Result := StoreDefs and (FieldDefs.Count > 0);
end; // FieldDefsStored


//------------------------------------------------------------------------------
// index defs support
//------------------------------------------------------------------------------
function TACRDataset.IndexDefsStored: Boolean;
begin
  Result := StoreDefs and (IndexDefs.Count > 0);
end; // IndexDefsStored


//------------------------------------------------------------------------------
// set index definitions
//------------------------------------------------------------------------------
procedure TACRDataset.SetIndexDefs(Value: TIndexDefs);
begin
  // fixed in v.4.80
  IndexDefsAssign(Value,FIndexDefs);
//  IndexDefs.Assign(Value);
end; // SetIndexDefs


//------------------------------------------------------------------------------
// get active buffer
//------------------------------------------------------------------------------
function TACRDataSet.GetActiveRecordBuffer: PAnsiChar;
begin
 Result := nil;
 if (FHandle = nil) then
  Exit;
 case State of
      dsBrowse:
        if not IsEmpty then
          Result := PAnsiChar(ActiveBuffer);
      dsCalcFields:
        Result := PAnsiChar(CalcBuffer);
      dsFilter:
        Result := PAnsiChar(FFilterBuffer);
      dsEdit,dsInsert:
        Result:=PAnsiChar(ActiveBuffer);
      dsSetKey:
        Result := PAnsiChar(FKeyBuffer);
 end;
end; // GetActiveRecordBuffer


//------------------------------------------------------------------------------
// check session name
//------------------------------------------------------------------------------
procedure TACRDataset.CheckDBSessionName;
var
  S: TACRSession;
  Database: TACRDatabase;
begin
  if (SessionName <> '') and (DatabaseName <> '') then
  begin
    S := Sessions.FindSession(SessionName);
    if ( Assigned(S) and
        (not Assigned(S.DoFindDatabase(FDatabaseName, FInMemory, FTemporary, Self)))
       ) then
    begin
      Database := ACRDefaultSession.DoFindDatabase(DatabaseName,FInMemory,FTemporary,Self);
      if Assigned(Database) then
       Database.CheckSessionName(True);
    end;
  end;
end;// CheckDBSessionName


//------------------------------------------------------------------------------
// get base session
//------------------------------------------------------------------------------
function TACRDataset.GetDBHandle: TACRBaseSession;
begin
  if FDatabase <> nil then
    Result := FDatabase.Handle
  else
    Result := nil;
end;// GetDBHandle


//------------------------------------------------------------------------------
// get ACRSession
//------------------------------------------------------------------------------
function TACRDataset.GetDBSession: TACRSession;
begin
  if (FDatabase <> nil) then
    Result := FDatabase.FSession
  else
    Result := Sessions.FindSession(SessionName);
  if Result = nil then
   Result := ACRDefaultSession;
end;// GetDBSession


//------------------------------------------------------------------------------
// set specified database name
//------------------------------------------------------------------------------
procedure TACRDataset.SetDatabaseName(const Value: AnsiString);
begin
  if csReading in ComponentState then
   begin
    FDatabaseName := Value;
   end
  else
  if FDatabaseName <> Value then
  begin
    CheckInactive;
    if FDatabase <> nil then
     DatabaseError(ErrorADatabaseOpen+' 1', Self);
    FDatabaseName := Value;
    DataEvent(dePropertyChange, 0);
  end;
  // added in v.5.90
  if (FDatabase <> nil) then
   FCaseInsensitive := FDatabase.CaseInsensitive;
end;// SetDatabaseName


//------------------------------------------------------------------------------
// change current database name
//------------------------------------------------------------------------------
procedure TACRDataset.ChangeCurrentDatabaseName(const Value: AnsiString);
begin
  FDatabaseName := Value;
end; // ChangeCurrentDatabaseName


//------------------------------------------------------------------------------
// set specified session name
//------------------------------------------------------------------------------
procedure TACRDataset.SetSessionName(const Value: AnsiString);
begin
  CheckInactive;
  FSessionName := Value;
  DataEvent(dePropertyChange, 0);
end;// SetSessionName


//------------------------------------------------------------------------------
// set in-memory
//------------------------------------------------------------------------------
procedure TACRDataset.SetInMemory(const Value: Boolean);
begin
  CheckInactive;
  if (Value <> FInMemory) then
   begin
    FInMemory := Value;
    if (Value) then
     FDatabaseName := ACRMemoryDatabaseName;
    // added in v.5.90
    if (FDatabase <> nil) then
     FCaseInsensitive := FDatabase.CaseInsensitive;
   end;
end;// SetInMemory


//------------------------------------------------------------------------------
// return current version
//------------------------------------------------------------------------------
function TACRDataSet.GetCurrentVersion: AnsiString;
begin
  Result := ACRGetCurrentVersion;
end; // GetCurrentVersion


//------------------------------------------------------------------------------
// open cursor
//------------------------------------------------------------------------------
procedure TACRDataSet.OpenCursor(InfoQuery: Boolean);
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRDataSet.OpenCursor 0');
{$ENDIF}
 FDeleteRecordFlag := False;
 SetDBFlag(dbfOpened, True);
 if (FDatabase = nil) then
  Exit;
 if (FDatabase <> nil) then
  if (FDatabase.FReadOnly) then
   ReadOnly := True;
 if (FHandle = nil) then
    FHandle := CreateHandle;
 if (FHandle = nil) then
  begin
    if (Self.Owner <> nil) then
     if (Self.Owner is TForm) then
      if (fsCreating in TForm(Self.Owner).FormState) then
       Exit;
    raise EACRException.Create(20001, ErrorAHandleError);
  end;
 inherited OpenCursor(InfoQuery);
{$IFDEF DEBUG_TRACE_DATASET}
 if (FHandle = nil) then
    aaWriteToLog('TACRDataSet.OpenCursor nil 2');
aaWriteToLog('TACRDataSet.OpenCursor 3');
{$ENDIF}
end;// OpenCursor


//------------------------------------------------------------------------------
// close cursor
//------------------------------------------------------------------------------
procedure TACRDataSet.CloseCursor;
var bCloseAsRemote: Boolean;
begin
{$IFDEF DEBUG_TRACE_DATASET}
if (FHandle = nil) then
aaWriteToLog('> TACRDataSet.CloseCursor start - FHandle = nil'
+#13#10+'ClassName = '+Self.ClassName
)
else
aaWriteToLog('> TACRDataSet.CloseCursor start'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'FTableName = '+FHandle.TableName
+#13#10+'FInMemory = '+BoolToStr(FHandle.FInMemory,True)
+#13#10+'FTableName = '+BoolToStr(FHandle.FTemporary,True)
);
{$ENDIF}
 FDeleteRecordFlag := False;
 inherited CloseCursor;
 // added in 4.03
 bCloseAsRemote := False;
 {$IFNDEF SQLMEMTABLE}
 if (Self is TACRQuery) then
  if (FDatabase <> nil) then
   if (not FDatabase.FLocalDatabase) then
    bCloseAsRemote := True;
 {$ENDIF}
 if (bCloseAsRemote) then
  begin
   SetDBFlag(dbfOpened, False);
   if (FHandle <> nil) then
      DestroyHandle;
  end
 else
  begin
   if (FHandle <> nil) then
      DestroyHandle;
   // modified in 4.95   
   if (FExternalHandle = nil) then
     SetDBFlag(dbfOpened, False);
  end;
 FAdvFieldDefs.Clear;
 FAdvIndexDefs.Clear;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('< TACRDataSet.CloseCursor finish'
+#13#10+'ClassName = '+Self.ClassName
)
{$ENDIF}
end;// CloseCursor


//------------------------------------------------------------------------------
// disconnect
//------------------------------------------------------------------------------
procedure TACRDataset.Disconnect;
begin
  Close;
end;// Disconnect


//------------------------------------------------------------------------------
// set DBFlag
//------------------------------------------------------------------------------
procedure TACRDataset.SetDBFlag(Flag: Integer; Value: Boolean);
var bClose: Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('> TACRDataset.SetDBFlag - Self = '+IntToHex(Integer(Self),8)+', ClassName = '+Self.ClassName+', Flag = '+IntToStr(Flag)+', Value = '+BoolToStr(Value,True)
+#13#10+'FSessionName = '+FSessionName
+#13#10+'FDatabaseName = '+FDatabaseName
+#13#10+'FDatabase = '+IntToHex(Integer(FDatabase),8)
);
if (FHandle <> nil) then
 aaWriteToLog('FTableName = '+FHandle.TableName
 +#13#10+'InMemory = '+BoolToStr(FHandle.IsMemoryTable,True)
 +#13#10+'Temporary = '+BoolToStr(FHandle.IsTemporaryTable,True)
 );
{$ENDIF}
  if (Value) then
    begin
      // set flag
      if (not (Flag in FDBFlags)) then
        begin
         if (FDBFlags=[]) then
           begin
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('0 TACRDataset.SetDBFlag - True');
{$ENDIF}
            CheckDBSessionName;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('1 TACRDataset.SetDBFlag - True');
{$ENDIF}
            FDatabase := OpenDatabase;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('2 TACRDataset.SetDBFlag - True');
{$ENDIF}
            if (FDatabase = nil) then
             begin
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('3 TACRDataset.SetDBFlag - True');
{$ENDIF}
              if (Self.Owner <> nil) then
               if (Self.Owner is TForm) then
                if (fsCreating in TForm(Self.Owner).FormState) then
                 begin
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('4.1 TACRDataset.SetDBFlag - True');
{$ENDIF}
                  Exit;
                 end;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('4.2 TACRDataset.SetDBFlag - True');
{$ENDIF}
              raise EACRException.Create(11245,ErrorLCannotOpenDatabase,[FDatabaseName]);
             end;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('5 TACRDataset.SetDBFlag - True');
{$ENDIF}
            FDatabase.FDataSets.Add(Self);
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('6 TACRDataset.SetDBFlag - True');
{$ENDIF}
           end;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('7 TACRDataset.SetDBFlag - True');
{$ENDIF}
         Include(FDBFlags,Flag);
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('8 TACRDataset.SetDBFlag - True');
{$ENDIF}
       end;
    end
  else
    begin
      // reset flag
      if (Flag in FDBFlags) then
        begin
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('0 TACRDataset.SetDBFlag - False');
{$ENDIF}
         Exclude(FDBFlags,Flag);
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('1 TACRDataset.SetDBFlag - False');
{$ENDIF}
         if (FDBFlags=[]) then
           begin
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('2 TACRDataset.SetDBFlag - False');
{$ENDIF}    bClose := True;
            if (Self is TACRQuery) then
             begin
              if (FInMemory or FTemporary) then
               bClose := ACRFindDatabaseData(FInMemory,FTemporary,FDatabaseName) <> nil
              else
              if (FDatabase <> nil) then
               bClose := ACRFindDatabaseData(FInMemory,FTemporary,FDatabase.FDatabaseFileName,FDatabase.FDatabaseFileNameUnicode) <> nil
              else
               bClose := True;
             end;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('2.1 TACRDataset.SetDBFlag - False. bClose = '+BoolToStr(bClose,True));
{$ENDIF}
            if (bClose) then
             begin
              FDatabase.RemoveDataset(Self);
  {$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
  aaWriteToLog('3 TACRDataset.SetDBFlag - False');
  {$ENDIF}
              if (FDatabase.FSession <> nil) then
                FDatabase.FSession.CloseDatabase(FDatabase);
  {$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
  aaWriteToLog('4 TACRDataset.SetDBFlag - False');
  {$ENDIF}
              FDatabase := nil;
  {$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
  aaWriteToLog('5 TACRDataset.SetDBFlag - False');
  {$ENDIF}
             end
            else
             begin
              if (FDatabase <> nil) then
               begin
                FDatabase.RemoveDataset(Self);
                if (FDatabase.FHandle <> nil) then
                 if (FDatabase.FHandle is TACRLocalSession) then
                   begin
                     FDatabase.FHandle.CloseLocalSessionWithoutDatabase;
                     FDatabase.FHandle := nil;
                   end;
                if (FDatabase.FSession <> nil) then
                  FDatabase.FSession.CloseDatabase(FDatabase);
                FDatabase := nil;
               end;
             end;

           end;
        end;
      end;
{$IFDEF DEBUG_TRACE_TACRDataset_SetDBFlag}
aaWriteToLog('< TACRDataset.SetDBFlag - Self = '+IntToHex(Integer(Self),8)+', ClassName = '+Self.ClassName+', Flag = '+IntToStr(Flag)+', Value = '+BoolToStr(Value,True)
+#13#10+'FSessionName = '+FSessionName
+#13#10+'FDatabaseName = '+FDatabaseName
+#13#10+'FDatabase = '+IntToHex(Integer(FDatabase),8)
);
{$ENDIF}
end;// SetDBFlag


//------------------------------------------------------------------------------
// create handle
//------------------------------------------------------------------------------
function TACRDataSet.CreateHandle: TACRCursor;
begin
 Result := nil;
end;// CreateHandle


//------------------------------------------------------------------------------
// destroy handle
//------------------------------------------------------------------------------
procedure TACRDataSet.DestroyHandle;
begin
 if (FExternalHandle = nil) then
  if (FHandle <> nil) then
    begin
     FHandle.FSettingProjection := False;
     FHandle.Free;
    end;
 FHandle := nil;
end;// DestroyHandle


//------------------------------------------------------------------------------
// internal data convert - date, time and datetime
//------------------------------------------------------------------------------
procedure TACRDataset.InternalDataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);
begin
  case Field.DataType of
   ftDate:
     begin
      if ToNative then
        TACRDate(Dest^) := DateToACRDate(TDate(Source^))
      else
        TDate(Dest^) := ACRDateToDate(TACRDate(Source^));
     end;
   ftDateTime:
     begin
      if ToNative then
        TACRDateTime(Dest^) := DateTimeToACRDateTime(TDateTime(Source^))
      else
        TDateTime(Dest^) := ACRDateTimeToDateTime(TACRDateTime(Source^));
     end;
   ftTime:
     begin
      if ToNative then
        TACRTime(Dest^) := TimeToACRTime(TTime(Source^))
      else
        TTime(Dest^) := ACRTimeToTime(TACRTime(Source^));
     end;
{$IFDEF D6H}
   ftTimeStamp:
     begin
      if ToNative then
        begin
          TACRDateTime(Dest^) := DateTimeToACRDateTime(SQLTimeStampToDateTime(TSQLTimeStamp(Source^)));
        end
      else
        begin
          // Modified by Aleksander Oven
          TSQLTimeStamp(Dest^) := TSQLTimeStamp(Source^);
          // ---------------------------
        end;
     end;
{$ENDIF}
  end;
end; // InternalDataConvert


//------------------------------------------------------------------------------
// return true if field is wide memo
//------------------------------------------------------------------------------
function TACRDataset.IsWideMemoField(Field: TField): Boolean;
var k: Integer;
begin
  k := Field.FieldNo - 1;
  if (FHandle = nil) then
    raise EACRException.Create(11233,ErrorLNilPointer);
  if ((k < 0) or (k >= FHandle.VisibleFieldDefs.Count)) then
    raise EACRException.Create(11234,ErrorLInvalidFieldNumber,[k,FHandle.VisibleFieldDefs.Count]);
  Result := (FHandle.VisibleFieldDefs.Items[k].AdvancedFieldType = aftWideMemo);
end; // IsWideMemoField


{$IFDEF D18H}
//------------------------------------------------------------------------------
// data convert
//------------------------------------------------------------------------------
procedure TACRDataset.DataConvert(Field: TField; Source: TValueBuffer; var Dest: TValueBuffer; ToNative: Boolean);
{$ELSE}

//fixed by Leo in v.15.10 form XE3 (before was missed)
{$IFDEF D17H}
  //------------------------------------------------------------------------------
  // data convert
  //------------------------------------------------------------------------------
  procedure TACRDataset.DataConvert(Field: TField; Source, Dest: TValueBuffer; ToNative: Boolean);
  {$ELSE}
  //------------------------------------------------------------------------------
  // data convert
  //------------------------------------------------------------------------------
  procedure TACRDataset.DataConvert(Field: TField; Source, Dest: Pointer;
    ToNative: Boolean);
  {$ENDIF}
{$ENDIF}
const x: Word = $0000;

  // fixed in v. 5.30
  procedure ProcessWideStringOrWideMemo(WideMemo: Boolean);
  {$IFDEF D10H}
  var len: Integer;
      src: PAnsiChar;
{$IFDEF D17H}
      dst: PAnsiChar; //  fixed by Leo in v.15.10 form XE3 (before was missed)
{$ENDIF}
      w:   Word;
  {$ENDIF}
  begin
    if Source = nil then Exit;
    {$IFDEF D10H}
    w := 0;
    {$ENDIF}
    if ToNative then
     begin
     {$IFDEF D10H}
        {$IFDEF D17H}
          src := PAnsiChar(Source);
          dst := PAnsiChar(Dest);
          len := GetStrLength(src,aftWideString);
          if (len > 0) then
            Move(src^,dst^,len);
          Move(w,PAnsiChar(PAnsiChar(dst)+len)^,SizeOf(w));
        {$ELSE}
          src := PAnsiChar(Source^);
          len := GetStrLength(Source,aftWideString);
          if (len > 0) then
            Move(Source^,Dest^,len);
          Move(w,PAnsiChar(PAnsiChar(Dest)+len)^,SizeOf(w));
        {$ENDIF}
     {$ELSE}
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('ProcessWideStringOrWideMemo 1');
{$ENDIF}
      Move(Source^,Dest^,Sizeof(PWideChar));
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('ProcessWideStringOrWideMemo 2');
{$ENDIF}
     {$ENDIF}
     end
    else
     begin
      {$IFDEF D10H}
//      WideString(Dest^) := WideString(PWideChar(Source)^);
        {$IFDEF D17H}
          dst := PAnsiChar(Dest);
          src := PAnsiChar(Source);
          len := GetStrLength(src,aftWideString);
          if (len > 0) then
            Move(src^,dst^,len);
          Move(w,PAnsiChar(PAnsiChar(dst)+len)^,SizeOf(w));
        {$ELSE}
          src := PAnsiChar(Source^);
          len := GetStrLength(src,aftWideString);
          if (len > 0) then
            Move(src^,Dest^,len);
          Move(w,PAnsiChar(PAnsiChar(Dest)+len)^,SizeOf(w));
        {$ENDIF}
      {$ELSE}
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('ProcessWideStringOrWideMemo 3');
{$ENDIF}
//      Move(Source^,Dest^,Sizeof(PWideChar));
      WideString(Dest^) := WideString(PWideChar(Source^));
//        PWideChar(Dest^) := PWideChar(Source);
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('ProcessWideStringOrWideMemo 4');
{$ENDIF}
      {$ENDIF}
     end;
  end; // ProcessWideStringOrWideMemo

begin
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('> TACRDataset.DataConvert Field: '+Field.FieldName+', No = '+IntToStr(Field.FieldNo)+', ToNative = '+BoolToStr(ToNative,True));
{$ENDIF}
  case Field.DataType of
  {$IFDEF D6H}
   ftTimeStamp: InternalDataConvert(Field,Source,Dest,ToNative);
  {$ENDIF}
{$IFNDEF D10H}
   ftWideString:
     begin
      ProcessWideStringOrWideMemo(False);
     end;
{$ENDIF}
   else
    begin
     {$IFDEF D5H}
     inherited DataConvert(Field, Source, Dest, ToNative);
     {$ENDIF}
    end
  end;//case
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('< TACRDataset.DataConvert Field: '+Field.FieldName+', No = '+IntToStr(Field.FieldNo)+', ToNative = '+BoolToStr(ToNative,True));
{$ENDIF}
end;//DataConvert


//------------------------------------------------------------------------------
// set wide memo field
//------------------------------------------------------------------------------
procedure TACRDataset.SetWideMemoField(Field: TField; Value: WideString);
var bs: TStream;
    l:  Integer;
begin
  if (not IsWideMemoField(Field)) then
   DatabaseError(Format(ErrorLNotWideMemoField,[Field.FieldName]),nil);
  l := Length(Value) * 2;
  if (l <= 0) then
   Field.Clear
  else
   begin
     bs := Self.CreateBlobStream(Field,bmWrite);
     bs.WriteBuffer(PWideChar(@Value[1])^,l);
     bs.free;
   end;
end; // SetWideMemoField


//------------------------------------------------------------------------------
// get wide memo field
//------------------------------------------------------------------------------
function TACRDataset.GetWideMemoField(Field: TField): WideString;
var bs:   TStream;
    l:    Integer;
    w:    Word;
    buf:  PWideChar;
begin
  Result := '';
  if (not IsWideMemoField(Field)) then
   DatabaseError(Format(ErrorLNotWideMemoField,[Field.FieldName]),nil);
  try
   bs := Self.CreateBlobStream(Field,bmRead);
  except
   bs := nil;
  end;
  if (bs = nil) then Exit;
  try
   l := bs.Size;
   if (l > 0) then
    begin
     w := 0;
     buf := MemoryManager.GetMem(l+sizeof(w));
     try
       bs.ReadBuffer(buf^,l);
       Move(w,PAnsiChar(PAnsiChar(buf)+l)^,sizeof(w));
       Result := WideString(buf);
     finally
      MemoryManager.FreeAndNilMem(buf);
     end;

//     SetLength(Result,(l+sizeof(w)) div 2);
//     bs.ReadBuffer(PWideChar(@Result[1])^,l);
//     Move(w,Result[l],sizeof(w));
    end;
  finally
    bs.Free;
  end;
end; // GetWideMemoField


//------------------------------------------------------------------------------
// SetActive
//------------------------------------------------------------------------------
procedure TACRDataset.SetActive(Value: Boolean);
begin
 if (State in [dsEdit,dsInsert]) and (Value = False) then
   InternalCancel;
 inherited;
end;//SetActive


//------------------------------------------------------------------------------
// switch to index
//------------------------------------------------------------------------------
procedure TACRDataset.SwitchToIndex(const IndexName: WideString);
begin
   ResetCursorRange;
   UpdateCursorPos;
   if (FHandle <> nil) then
    begin
      if (FHandle.RecordBitmap <> nil) then
       TACRRecordBitmap(FHandle.RecordBitmap).Active := False;
      FHandle.IndexName := IndexName;
    end;
   FKeySize := 0;
   FIndexFieldCount := 0;
   GetIndexInfo;
end;// SwitchToIndex


//------------------------------------------------------------------------------
// check whether field is in index
//------------------------------------------------------------------------------
function TACRDataset.GetIsIndexField(Field: TField): Boolean;
var
  I: Integer;
begin
  Result:=False;
  with Field do
   if FieldNo > 0 then
     for I := 0 to FIndexFieldCount - 1 do
      if FIndexFieldMap[I] = FieldNo then
        begin
          Result := True;
          Exit;
        end;
end;// GetIsIndexField


//------------------------------------------------------------------------------
// get info of acive index
//------------------------------------------------------------------------------
procedure TACRDataSet.GetIndexInfo;
var
  ACRIndexDef: TACRIndexDef;
  i:           Integer;
begin
  if (FHandle <> nil) and (FHandle.IndexName <> '') then
   begin
     ACRIndexDef := FHandle.IndexDefs.GetIndexDefByName(FHandle.IndexName);
     if (ACRIndexDef = nil) then
       raise EACRException.Create(10325,ErrorLCannotFindIndex,[FHandle.IndexName]);
     FIndexFieldCount := ACRIndexDef.ColumnCount;
     SetLength(FIndexFieldMap,FIndexFieldCount);
     FKeySize := 0;
     for i := 0 to FIndexFieldCount - 1 do
      begin
        FIndexFieldMap[i] := FHandle.FieldDefs.GetDefNumberByName(
                              ACRIndexDef.Columns[i].FieldName) + 1;
        Inc(FKeySize,FHandle.FieldDefs[FIndexFieldMap[i]-1].MemoryDataSize);
      end;
   end
  else
   begin
     FIndexFieldMap := nil;
     FIndexFieldCount := 0;
     FKeySize := 0;
   end;
end;// GetIndexInfo


//------------------------------------------------------------------------------
// ResetCursorRange
//------------------------------------------------------------------------------
function TACRDataSet.ResetCursorRange: Boolean;
begin
  Result := False;
  if (FHandle = nil) then
   raise EACRException.Create(10287,ErrorLNilPointer);
  if (FHandle.SQLFilterExpression <> nil) then
   Exit;
  if (PACRKeyBuffer(FKeyBuffers[kiCurRangeStart] + FHandle.KeyOffset)^.Modified or
    PACRKeyBuffer(FKeyBuffers[kiCurRangeEnd] + FHandle.KeyOffset)^.Modified) then
   begin
    InitKeyBuffer(FKeyBuffers[kiCurRangeStart]);
    InitKeyBuffer(FKeyBuffers[kiCurRangeEnd]);
    Result := True;
   end;
  FHandle.ResetRange;
end;// ResetCursorRange


{$IFDEF D21H}
procedure TACRDataSet.ClearCalcFields(Buffer: NativeInt);
var aBuffer: TRecordBuffer;
begin
 if (Pointer(Buffer) = nil) then
  raise EACRException.Create(10039,ErrorLNilPointer);
// if (FHandle = nil) then
//  raise EACRException.Create(10040,ErrorLNilPointer);
 if (FHandle <> nil) then
  if (CalcFieldsSize > 0) then
   begin
    aBuffer := TRecordBuffer(Pointer(Buffer));
    FillChar(aBuffer[FHandle.CalculatedFieldsOffset],CalcFieldsSize,0);
   end;
end; // ClearCalcFields
{$ELSE}
//------------------------------------------------------------------------------
// clear calculated fields
//------------------------------------------------------------------------------
procedure TACRDataSet.ClearCalcFields(Buffer: TRecordBuffer);
begin
 if (Buffer = nil) then
  raise EACRException.Create(10039,ErrorLNilPointer);
// if (FHandle = nil) then
//  raise EACRException.Create(10040,ErrorLNilPointer);
 if (FHandle <> nil) then
  if (CalcFieldsSize > 0) then
    FillChar(Buffer[FHandle.CalculatedFieldsOffset],CalcFieldsSize,0);
end; // ClearCalcFields
{$ENDIF}

//------------------------------------------------------------------------------
// refresh
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalRefresh;
begin
 FDeleteRecordFlag := False;
 FInsertOrEditComplete := False;
 if (Active) then
  begin
   DataEvent(deDataSetChange, 0);
   FHandle.InternalRefresh;
  end;
end; // InternalRefresh


//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
function TACRDataSet.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
var ACRGetMode:         TACRGetRecordMode;
    ACRGetResult:       TACRGetRecordResult;
// moved to TACRCursor in v.5.30
//    Bookmark:           PACRBookmarkInfo;
    bSkipMoveRecordID:  Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRDataSet_GetRecord}
Result := grError;
aaWriteToLog('> TACRDataset.GetRecord.'
+#13#10+'Buffer = '+IntToHex(Integer(Buffer),8)
+#13#10+'GetMode = '+IntToStr(Integer(GetMode))
+#13#10+'DoCheck = '+BoolToStr(DoCheck,true));
try
{$ENDIF}
 if (FHandle = nil) then
  raise EACRException.Create(10041,ErrorLNilPointer);
{$IFDEF DEBUG_TRACE_TACRDataSet_GetRecord}
aaWriteToLog('TACRDataset.GetRecord');
{$ENDIF}
 case (GetMode) of
  gmCurrent:  ACRGetMode := grmCurrent;
  gmNext:     ACRGetMode := grmNext;
  gmPrior:    ACRGetMode := grmPrior
 else
  ACRGetMode := grmCurrent;
 end;
 bSkipMoveRecordID := False;
 if ((FInsertOrEditComplete) and (GetMode = gmCurrent)) then
  begin
   Move(FHandle.CurrentRecordBuffer^,Buffer^,FHandle.RecordSize);
   bSkipMoveRecordID := True;
  end;
 FHandle.CurrentRecordBuffer := PAnsiChar(Buffer);

 // bug fix with navigating dataset connected to DBGrid with multiple rows on the screen
// if (FDeleteRecordFlag) then
//FHandle.SetCurrentRecordIDAfterDelete
// else
 if ((not FDeleteRecordFlag) and (not bSkipMoveRecordID)) then
   if ((not FHandle.FirstPosition) and (not FHandle.LastPosition)) then
    if ((Pointer(ActiveBuffer) <> nil) and (Active)) then
     if (BufferCount > 1) then
      if ((CurrentRecord < BufferCount) and (CurrentRecord >= 0)) then
        Move(PAnsiChar(Buffers[CurrentRecord] + FHandle.BookmarkOffset)^,
          FHandle.CurrentRecordID, SizeOf(TACRRecordID));

 // avoid loading record from database file immediately after posting it
 if ((not FInsertOrEditComplete) or (GetMode <> gmCurrent)) then
  begin
   // try..except in 4.95
   try
     ACRGetResult := FHandle.GetRecordBuffer(ACRGetMode);
   except
     ACRGetResult := grrError;
   end;
  end
 else
  begin
   ACRGetResult := grrOK;
   FHandle.GetCalcFieldsAndBookMarkData;
  end;
 FInsertOrEditComplete := False;
 FDeleteRecordFlag := False;

 case (ACRGetResult) of
  grrOK:
   begin
    Result := grOK;
// moved to TACRCursor in v.5.30    
{
    ClearCalcFields(Buffer);
    GetCalcFields(Buffer);
    // write bookmark info to record buffer
    Bookmark := PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset);
    Bookmark^.BookmarkData := FHandle.CurrentRecordID;
    Bookmark^.BookmarkFlag := abfCurrent;
}
   end;
  grrBOF: Result := grBOF;
  grrEOF: Result := grEOF
 else
  Result := grError;
 end;
 if (Result = grError) and DoCheck then
  raise EACRException.Create(10026,ErrorLGetRecordFailed);
{$IFDEF DEBUG_TRACE_TACRDataSet_GetRecord}
finally
if (FHandle <> nil) then
aaWriteToLog('< TACRDataset.GetRecord.'
+#13#10+'TableName = '+FHandle.TableName
+#13#10+'SessionID = '+IntToStr(FHandle.Session.SessionID)
+#13#10+'RecordID.PageNo = '+IntToStr(FHandle.CurrentRecordID.PageNo)
+#13#10+'RecordID.PageItemNo = '+IntToStr(FHandle.CurrentRecordID.PageItemNo)
+#13#10+'Result = '+IntToStr(Integer(Result))
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'Buffer = '+IntToHex(Integer(Buffer),8)
+#13#10+'GetMode = '+IntToStr(Integer(GetMode))
+#13#10+'DoCheck = '+BoolToStr(DoCheck,true)
)
else
aaWriteToLog('< TACRDataset.GetRecord.'
+#13#10+'Result = '+IntToStr(Integer(Result))
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'Buffer = '+IntToHex(Integer(Buffer),8)
+#13#10+'GetMode = '+IntToStr(Integer(GetMode))
+#13#10+'DoCheck = '+BoolToStr(DoCheck,true)
);

end;
{$ENDIF}
end; // GetRecord


{$IFDEF D21H}
function TACRDataset.GetCurrentRecord(Buffer: TRecBuf): Boolean;
var
  OldBuffer: TACRRecordBuffer;
begin
  Result := False;
  if (FHandle <> nil) then
    begin
      if ((not IsEmpty) and (GetBookmarkFlag(ActiveBuffer) = bfCurrent)) then
         begin
           UpdateCursorPos;
           OldBuffer := FHandle.CurrentRecordBuffer;
           FHandle.CurrentRecordBuffer := PAnsiChar(Buffer);
           try
            // try..except in 4.95
            try
             Result := (FHandle.GetRecordBuffer(grmCurrent) = grrOK);
            except
             Result := False;
            end;
           finally
             FHandle.CurrentRecordBuffer := OldBuffer;
           end;
         end
      else
        Result:=False;
    end
  else
    Result:=False;
end;// GetCurrentRecord
{$ELSE}
//------------------------------------------------------------------------------
// GetCurrentRecord
//------------------------------------------------------------------------------
function TACRDataset.GetCurrentRecord(Buffer: TRecordBuffer): Boolean;
var
  OldBuffer: TACRRecordBuffer;
begin
  Result := False;
  if (FHandle <> nil) then
    begin
      if ((not IsEmpty) and (GetBookmarkFlag(ActiveBuffer) = bfCurrent)) then
         begin
           UpdateCursorPos;
           OldBuffer := FHandle.CurrentRecordBuffer;
           FHandle.CurrentRecordBuffer := PAnsiChar(Buffer);
           try
            // try..except in 4.95
            try
             Result := (FHandle.GetRecordBuffer(grmCurrent) = grrOK);
            except
             Result := False;
            end;
           finally
             FHandle.CurrentRecordBuffer := OldBuffer;
           end;
         end
      else
        Result:=False;
    end
  else
    Result:=False;
end;// GetCurrentRecord
{$ENDIF}


//------------------------------------------------------------------------------
// cleart and get calc fields
//------------------------------------------------------------------------------
procedure TACRDataset.ClearAndGetCalcFields(Buffer: TRecordBuffer);
begin
  ClearCalcFields(Buffer);
  GetCalcFields(Buffer);
end; // ClearAndGetCalcFields


//------------------------------------------------------------------------------
// returns RecordID of the current record
//------------------------------------------------------------------------------
function TACRDataset.GetCurrentRecordID: TACRRecordID;
begin
 if (FHandle = nil) then
  raise EACRException.Create(11352,ErrorLNilPointer);
 Result := FHandle.CurrentRecordID;
end; // GetCurrentRecordID


//------------------------------------------------------------------------------
// return record count
//------------------------------------------------------------------------------
function TACRDataset.GetRecordCount: Integer;
begin
 if (not Active) then
  Result := 0
 else
  begin
   if (FHandle = nil) then
    raise EACRException.Create(10056,ErrorLNilPointer);
   // try..except in 4.95
   try
     Result := FHandle.RecordCount;
   except
     Result := 0;
   end;
  end;
end; // GetRecordCount


//------------------------------------------------------------------------------
// go to record
//------------------------------------------------------------------------------
procedure TACRDataSet.SetRecNo(Value: Integer);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10042,ErrorLNilPointer);
 if (Value <= 0) then
  raise EACRException.Create(11622,ErrorLWrongRecNoValue,[Value]);
 DoBeforeScroll;
 FHandle.SetRecNo(Value);
 FDeleteRecordFlag := True;
 Resync([rmCenter]);
 DoAfterScroll;
end; // SetRecNo


//------------------------------------------------------------------------------
// return current record number
//------------------------------------------------------------------------------
function TACRDataSet.GetRecNo: Integer;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10043,ErrorLNilPointer);
 if (State = dsInsert) then
  Result := -1
 else
  begin
   FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
   if (FHandle.CurrentRecordBuffer = nil) then
    Result := -1
   else
    begin
      FHandle.FirstPosition := False;
      FHandle.LastPosition := False;
      FHandle.CurrentRecordID :=
        PACRBookmarkInfo(FHandle.CurrentRecordBuffer + FHandle.BookmarkOffset)^.BookmarkData;
      // try..except in 4.95
      try
       if (PACRBookmarkInfo(FHandle.CurrentRecordBuffer + FHandle.BookmarkOffset)^.BookmarkFlag = abfInserted) and
          (PACRBookmarkInfo(FHandle.CurrentRecordBuffer + FHandle.BookmarkOffset)^.BookmarkData.PageNo = INVALID_PAGE_NO) and
          (PACRBookmarkInfo(FHandle.CurrentRecordBuffer + FHandle.BookmarkOffset)^.BookmarkData.PageItemNo = $FFFF) then
        Result := -1
       else
        Result := FHandle.GetRecNo;
      except
        Result := -1;
      end;
    end;
  end;
end; // GetRecNo


//------------------------------------------------------------------------------
// go to first record (before first record to BOF)
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalFirst;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10044,ErrorLNilPointer);
 FHandle.InternalFirst;
end; // InternalFirst


//------------------------------------------------------------------------------
// go to last record (after last record to EOF)
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalLast;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10045,ErrorLNilPointer);
 FHandle.InternalLast;
end; // InternalLast


{$IFDEF D21H}
//------------------------------------------------------------------------------
// go to record in buffer
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalSetToRecord(Buffer: TRecBuf);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10046,ErrorLNilPointer);
 if (Pointer(Buffer) = nil) then
  raise EACRException.Create(10047,ErrorLNilPointer);
 InternalGotoBookmark(PAnsiChar(Buffer) + FHandle.BookmarkOffset);
end; // InternalSetToRecord


//------------------------------------------------------------------------------
// get bookmark flag
//------------------------------------------------------------------------------
function TACRDataSet.GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag;
var aBuffer: Pointer;
begin
 aBuffer := Pointer(Buffer);
 if (aBuffer = nil) then
  raise EACRException.Create(10059,ErrorLNilPointer);
 if (FHandle = nil) then
  raise EACRException.Create(10060,ErrorLNilPointer);
 Result := bfCurrent;
 case PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag  of
  abfCurrent:
     Result := bfCurrent;
  abfBOF:
     Result := bfBOF;
  abfEOF:
     Result := bfEOF;
  abfInserted:
     Result := bfInserted;
 end;
end; // GetBookmarkFlag


//------------------------------------------------------------------------------
// get bookmark data
//------------------------------------------------------------------------------
procedure TACRDataSet.GetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
var aBuffer: Pointer;
begin
 aBuffer := Pointer(Buffer);
 if (aBuffer = nil) then
  raise EACRException.Create(10034,ErrorLNilPointer);
 if (Data = nil) then
  raise EACRException.Create(10035,ErrorLNilPointer);
 if (FHandle = nil) then
  raise EACRException.Create(10036,ErrorLNilPointer);
 // copy bookmark
 Move(PAnsiChar(PAnsiChar(aBuffer) + FHandle.BookmarkOffset)^,PAnsiChar(Data)^,Sizeof(TACRRecordID));
end; // GetBookmarkData


//------------------------------------------------------------------------------
// go to bookmark
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalGotoBookmark(Bookmark: TBookmark);
begin
 if (Pointer(Bookmark) = nil) then
  raise EACRException.Create(10037,ErrorLNilPointer);
 if (FHandle = nil) then
  raise EACRException.Create(10038,ErrorLNilPointer);
 FHandle.CurrentRecordID :=
   PACRBookmarkInfo(Bookmark)^.BookmarkData;
 FHandle.FirstPosition := False;
 FHandle.LastPosition := False;
end; // InternalGotoBookmark


//------------------------------------------------------------------------------
// set flag
//------------------------------------------------------------------------------
procedure TACRDataSet.SetBookmarkFlag(Buffer: TRecBuf; Value: TBookmarkFlag);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10057,ErrorLNilPointer);
 case Value of
  bfCurrent:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfCurrent;
  bfBOF:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfBOF;
  bfEOF:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfEOF;
  bfInserted:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfInserted;
 end;
end; // SetBookmarkFlag


//------------------------------------------------------------------------------
// set data
//------------------------------------------------------------------------------
procedure TACRDataSet.SetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
var aBuffer: Pointer;
begin
 aBuffer := Pointer(Buffer);
 if (FHandle = nil) then
  raise EACRException.Create(10058,ErrorLNilPointer);
 if (aBuffer = nil) then
  raise EACRException.Create(10061,ErrorLNilPointer);
 if (Data = nil) then Exit;
 // copy bookmark
 Move(PAnsiChar(Data)^,PAnsiChar(PAnsiChar(aBuffer) + FHandle.BookmarkOffset)^,Sizeof(TACRRecordID));
end; // SetBookmarkData


{$ELSE}


//------------------------------------------------------------------------------
// go to record in buffer
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalSetToRecord(Buffer: TRecordBuffer);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10046,ErrorLNilPointer);
 if (Buffer = nil) then
  raise EACRException.Create(10047,ErrorLNilPointer);
 InternalGotoBookmark(Buffer + FHandle.BookmarkOffset);
end; // InternalSetToRecord


//------------------------------------------------------------------------------
// get bookmark flag
//------------------------------------------------------------------------------
function TACRDataSet.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
 if (Buffer = nil) then
  raise EACRException.Create(10059,ErrorLNilPointer);
 if (FHandle = nil) then
  raise EACRException.Create(10060,ErrorLNilPointer);
 Result := bfCurrent;
 case PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag  of
  abfCurrent:
     Result := bfCurrent;
  abfBOF:
     Result := bfBOF;
  abfEOF:
     Result := bfEOF;
  abfInserted:
     Result := bfInserted;
 end;
end; // GetBookmarkFlag


//------------------------------------------------------------------------------
// get bookmark data
//------------------------------------------------------------------------------
procedure TACRDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
 if (Buffer = nil) then
  raise EACRException.Create(10034,ErrorLNilPointer);
 if (Data = nil) then
  raise EACRException.Create(10035,ErrorLNilPointer);
 if (FHandle = nil) then
  raise EACRException.Create(10036,ErrorLNilPointer);
 // copy bookmark
 Move(PAnsiChar(Buffer + FHandle.BookmarkOffset)^,PAnsiChar(Data)^,Sizeof(TACRRecordID));
end; // GetBookmarkData


//------------------------------------------------------------------------------
// go to bookmark
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalGotoBookmark(Bookmark: Pointer);
begin
 if (Bookmark = nil) then
  raise EACRException.Create(10037,ErrorLNilPointer);
 if (FHandle = nil) then
  raise EACRException.Create(10038,ErrorLNilPointer);
 FHandle.CurrentRecordID :=
   PACRBookmarkInfo(Bookmark)^.BookmarkData;
 FHandle.FirstPosition := False;
 FHandle.LastPosition := False;
end; // InternalGotoBookmark


//------------------------------------------------------------------------------
// set flag
//------------------------------------------------------------------------------
procedure TACRDataSet.SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10057,ErrorLNilPointer);
 case Value of
  bfCurrent:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfCurrent;
  bfBOF:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfBOF;
  bfEOF:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfEOF;
  bfInserted:
    PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag :=
      abfInserted;
 end;
end; // SetBookmarkFlag


//------------------------------------------------------------------------------
// set data
//------------------------------------------------------------------------------
procedure TACRDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10058,ErrorLNilPointer);
 if (Buffer = nil) then
  raise EACRException.Create(10061,ErrorLNilPointer);
 if (Data = nil) then Exit;
 // copy bookmark
 Move(PAnsiChar(Data)^,PAnsiChar(Buffer + FHandle.BookmarkOffset)^,Sizeof(TACRRecordID));
end; // SetBookmarkData


{$ENDIF}
//------------------------------------------------------------------------------
// compare bookmarks
//------------------------------------------------------------------------------
function TACRDataSet.CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
const
  RetCodes: array[Boolean, Boolean] of ShortInt = ((2,-1),(1,0));
var Pos1, Pos2:           TACRRecordNo;
    RecordID1, RecordID2: TACRRecordID;
    OldPos:               Pointer;
    OldBuffer:            PAnsiChar;
    TempBuffer:           PAnsiChar;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10063,ErrorLNilPointer);
 Result := RetCodes[Bookmark1 = nil, Bookmark2 = nil];
 if Result = 2 then
  begin
    OldPos := FHandle.SavePosition;
    OldBuffer := FHandle.CurrentRecordBuffer;
    TempBuffer := FHandle.AllocateRecordBuffer;
    FHandle.CurrentRecordBuffer := TempBuffer;
    try
      FHandle.FirstPosition := False;
      FHandle.LastPosition := False;
      Move(PAnsiChar(Bookmark1)^,RecordID1,Sizeof(TACRRecordID));
      Move(PAnsiChar(Bookmark2)^,RecordID2,Sizeof(TACRRecordID));

      FHandle.CurrentRecordID := RecordID1;
//      if (FHandle.GetRecordBuffer(grmCurrent) <> grrOK) then
      if (not BookmarkValid(Bookmark1)) then
       Pos1 := -1
      else
       Pos1 := FHandle.GetRecNo;

      FHandle.CurrentRecordID := RecordID2;
      FHandle.FirstPosition := False;
      FHandle.LastPosition := False;
      FHandle.CurrentRecordBuffer := TempBuffer;
//      if (FHandle.GetRecordBuffer(grmCurrent) <> grrOK) then
      if (not BookmarkValid(Bookmark2)) then
       Pos2 := -1
      else
       Pos2 := FHandle.GetRecNo;

      if (Pos1 = Pos2) then
       Result := 0
      else
      if (Pos1 > Pos2) then
       Result := 1
      else
       Result := -1;
    finally
      FHandle.RestorePosition(OldPos);
      FHandle.FreePosition(OldPos);
      FHandle.FreeRecordBuffer(TempBuffer);
      FHandle.CurrentRecordBuffer := OldBuffer;
    end;
  end; // Result = 2
end; // CompareBookmarks


//------------------------------------------------------------------------------
// checks if bookmark is valid
//------------------------------------------------------------------------------
function TACRDataSet.BookmarkValid(Bookmark: TBookmark): Boolean;
var
    OldPos:               Pointer;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10064,ErrorLNilPointer);
 Result := False;
 if (Bookmark <> nil) then
  begin
   OldPos := FHandle.SavePosition;
   try
     Move(PAnsiChar(Bookmark)^,FHandle.CurrentRecordID,sizeof(TACRRecordID));
     Result := FHandle.IsRecordExists;
   finally
     FHandle.RestorePosition(OldPos);
     FHandle.FreePosition(OldPos);
   end;

{
   OldBuffer := FHandle.CurrentRecordBuffer;
   TempBuffer := FHandle.AllocateRecordBuffer;
   FHandle.CurrentRecordBuffer := TempBuffer;
   try
     Move(PAnsiChar(Bookmark)^,FHandle.CurrentRecordID,sizeof(TACRRecordID));
     Result := (FHandle.GetRecordBuffer(grmCurrent) = grrOK);
   finally
      FHandle.RestorePosition(OldPos);
      FHandle.FreePosition(OldPos);
      FHandle.FreeRecordBuffer(TempBuffer);
      FHandle.CurrentRecordBuffer := OldBuffer;
   end;
}
  end;
end; // BookmarkValid


//------------------------------------------------------------------------------
// return True if OnFilterRecord is applied and Fitlered is True
//------------------------------------------------------------------------------
function TACRDataSet.IsOnFilterRecordApplied: Boolean;
begin
  Result := Filtered and (Assigned(OnFilterRecord));
end; // IsOnFilterRecordApplied


//------------------------------------------------------------------------------
// return True if OnFilterRecord is applied and Fitlered is True
//------------------------------------------------------------------------------
function TACRDataSet.InternalFilterRecord(Buffer: TACRRecordBuffer): Boolean;
var
 SaveState: TDataSetState;
begin
 if (IsOnFilterRecordApplied) then
  begin
 SaveState := SetTempState(dsFilter);
 FFilterBuffer := Buffer;
 try
   Result := True;
   OnFilterRecord(Self,Result);
 except
     {$IFDEF D6H}
   ApplicationHandleException(Self);
     {$ELSE}
     Application.HandleException(Self)
     {$ENDIF}
 end;
 RestoreState(SaveState);
  end
 else
  Result := True;
end;


//------------------------------------------------------------------------------
// return Accept if OnFilterRecord accepts current record
//------------------------------------------------------------------------------
function TACRDataSet.FilterRecord(Buffer: TACRRecordBuffer; Dataset: Pointer): Boolean;
begin
  Result := TACRDataSet(Dataset).InternalFilterRecord(Buffer);
end; // FilterRecord


//------------------------------------------------------------------------------
// applies OnFilterRecord
//------------------------------------------------------------------------------
procedure TACRDataSet.SetOnFilterRecord(const Value: TFilterRecordEvent);
begin
  if Active then
   begin
    if (FHandle = nil) then
     raise EACRException.Create(10275,ErrorLNilPointer);
    CheckBrowseMode;
    if (Assigned(OnFilterRecord) <> Assigned(Value)) then
     begin
      if (Filtered) then
       ActivateFilters
      else
       DeactivateFilters;
    end;
    inherited SetOnFilterRecord(Value);
    if (Filtered) then First;
   end
  else
   inherited SetOnFilterRecord(Value);
end;


//------------------------------------------------------------------------------
// return true if index applied
//------------------------------------------------------------------------------
function TACRDataSet.IsIndexApplied: Boolean;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10381,ErrorLNilPointer);
 Result := (FHandle.FIndexID <> INVALID_OBJECT_ID); 
end; // IsIndexApplied


//------------------------------------------------------------------------------
// prepare cursor
//------------------------------------------------------------------------------
procedure TACRDataSet.PrepareCursor;
begin
end; // PrepareCursor


//------------------------------------------------------------------------------
// return true if dataset can be modified (not read only)
//------------------------------------------------------------------------------
function TACRDataSet.GetCanModify: Boolean;
begin
  Result := not Self.FReadOnly;
end; // GetCanModify


//------------------------------------------------------------------------------
// set SQL Filter
//------------------------------------------------------------------------------
procedure TACRDataSet.SetSQLFilter(FilterExpr: TObject);
begin
  if (FHandle = nil) then
    raise EACRException.Create(10300,ErrorLNilPointer);
  FHandle.SetSQLFilter(FilterExpr);
end; // SetSQLFilter


//------------------------------------------------------------------------------
// apply projection
//------------------------------------------------------------------------------
procedure TACRDataSet.ApplyProjection(FieldNamesList, AliasList: TACRWideStringList);
var i:      Integer;
    bExit:  Boolean;
begin
  bExit := False;
  FHandle.FSettingProjection := False;
  FIsProjectionSet := False;
  if (FieldNamesList.Count = FAdvFieldDefs.Count) then
   begin
    bExit := True;
    for i := 0 to FAdvFieldDefs.Count-1 do
     if (FAdvFieldDefs.Items[i].Name <> AliasList.Strings[i]) then
      begin
       bExit := False;
       break;
      end;
   end;
  if (bExit) then
   Exit;
  if (FHandle = nil) then
    raise EACRException.Create(10320,ErrorLNilPointer);
  FHandle.ApplyProjection(FieldNamesList,AliasList);
  FHandle.FSettingProjection := True;
  FExternalHandle := FHandle;
  try
    Close;
    Open;
    FHandle.FSettingProjection := False;
  finally
    FExternalHandle := nil;
  end;
  FIsProjectionSet := True;
  FHandle.FIsProjectionSet := True;
end; // ApplyProjection


//------------------------------------------------------------------------------
// activate filters
//------------------------------------------------------------------------------
procedure TACRDataSet.ActivateFilters;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10269,ErrorLNilPointer);
 // Filter property based filters
// 4.20
  if (Filter <> '') then
//  if (FHandle.IsFilterApplied) then
   FHandle.ActivateFilters(Filter,(foCaseInsensitive in FilterOptions),
                          (not (foNoPartialCompare in FilterOptions)))
 else
   FHandle.DeactivateFilters;
 if (Assigned(OnFilterRecord)) then
   FHandle.FilterRecord := @TACRDataset.FilterRecord
 else
   FHandle.FilterRecord := nil;
end; // ActivateFilters


//------------------------------------------------------------------------------
// deactivate filters
//------------------------------------------------------------------------------
procedure TACRDataSet.DeactivateFilters;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10270,ErrorLNilPointer);
 FHandle.DeactivateFilters;
end; // DeactivateFilters


//------------------------------------------------------------------------------
// set filter
//------------------------------------------------------------------------------
procedure TACRDataSet.SetFilterData(const Text: WideString; Options: TFilterOptions);
var bResetFilters: Boolean;
begin
  bResetFilters := False;
  if Active then
   begin
    CheckBrowseMode;
    if (FHandle = nil) then
     raise EACRException.Create(10266,ErrorLNilPointer);
    if (Filter <> Text) or (FilterOptions <> Options) then
      bResetFilters := True;
   end;
  inherited SetFilterText(Text);
  inherited SetFilterOptions(Options);
  if (Active and Filtered) then
   begin
    if (bResetFilters) then
     ActivateFilters;
    First;
   end;
end; // SetFilterData


//------------------------------------------------------------------------------
// set filtered
//------------------------------------------------------------------------------
procedure TACRDataSet.SetFiltered(Value: Boolean);
begin
  if (Active) then
   begin
    CheckBrowseMode;
    if (FHandle = nil) then
     raise EACRException.Create(10267,ErrorLNilPointer);
    if (Filtered <> Value) then
     begin
      // filtered changed
      if (Value) then
       ActivateFilters
      else
       DeactivateFilters;
      inherited SetFiltered(Value);
    end;
    First;
   end
  else
   inherited SetFiltered(Value);
end; // SetFiltered


//------------------------------------------------------------------------------
// set filter options
//------------------------------------------------------------------------------
procedure TACRDataSet.SetFilterOptions(Value: TFilterOptions);
begin
  SetFilterData(Filter, Value);
end; // SetFilterOptions


//------------------------------------------------------------------------------
// set filter text
//------------------------------------------------------------------------------
procedure TACRDataSet.SetFilterText(const Value: String);
begin
  SetFilterData(Value, FilterOptions);
end; // SetFilterText


//------------------------------------------------------------------------------
// FindFirst, FindNext, Filters
//------------------------------------------------------------------------------
function TACRDataSet.FindRecord(Restart, GoForward: Boolean): Boolean;
var Buffer:     TACRRecordBuffer;
    GetResult:  TGetResult;
begin
  CheckBrowseMode;
  DoBeforeScroll;
  SetFound(False);
  if (FHandle = nil) then
   raise EACRException.Create(10268,ErrorLNilPointer);
  UpdateCursorPos;
  CursorPosChanged;
  if (not Filtered) then
   ActivateFilters;
  Buffer := TACRRecordBuffer(AllocRecordBuffer);
  try
   if GoForward then
    begin
     if (Restart) then
      InternalFirst;
     GetResult := GetRecord(TRecordBuffer(Buffer),gmNext,False);
    end
   else
    begin
     if (Restart) then
      InternalLast;
     GetResult := GetRecord(TRecordBuffer(Buffer),gmPrior,False);
    end;
  finally
   FreeRecordBuffer(TRecordBuffer(Buffer));
   if (not Filtered) then
    DeactivateFilters;
  end;
 if (GetResult = grOK) then
  begin
    Resync([rmExact, rmCenter]);
    SetFound(True);
  end;
  Result := Found;
  if (Result) then
    DoAfterScroll;
end; // FindRecord


//------------------------------------------------------------------------------
// Locate record
//------------------------------------------------------------------------------
function TACRDataSet.LocateRecord(
                         const KeyFields: WideString;
                         const KeyValues: Variant;
                         Options:         TLocateOptions
                        ): Boolean;
var Buffer: PAnsiChar;
begin
  if (FHandle = nil) then
   raise EACRException.Create(10271,ErrorLNilPointer);
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time4);
{$ENDIF}
  CheckBrowseMode;
  CursorPosChanged;
  SetTempState(dsFilter);
  Buffer := PAnsiChar(TempBuffer);
  FFilterBuffer := Buffer;
  try
    FHandle.CurrentRecordBuffer := Buffer;
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time5);
{$ENDIF}
    Result := FHandle.Locate(
                             KeyFields,KeyValues,
                             (loCaseInsensitive in Options),
                             (loPartialKey in Options)
                            );
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time5);
{$ENDIF}
  finally
    RestoreState(dsBrowse);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time4);
{$ENDIF}
 end;
end; // LocateRecord


//------------------------------------------------------------------------------
// Locate
//------------------------------------------------------------------------------
function TACRDataSet.Locate(const KeyFields: String; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
begin
{$IFDEF DEBUG_LOCATE_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
{$ENDIF}
  DoBeforeScroll;
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time2);
{$ENDIF}
  Result := LocateRecord(KeyFields, KeyValues, Options);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time2);
{$ENDIF}
  if (Result) then
   begin
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time3);
{$ENDIF}
    Resync([rmExact, rmCenter]);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time3);
{$ENDIF}
    DoAfterScroll;
   end;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time1);
{$ENDIF}
end; // Locate


//------------------------------------------------------------------------------
// Lookup
//------------------------------------------------------------------------------
function TACRDataSet.Lookup(const KeyFields: String; const KeyValues: Variant;
      const ResultFields: String): Variant;
begin
  Result := Null;
  if (LocateRecord(KeyFields, KeyValues, [])) then
  begin
    SetTempState(dsCalcFields);
    try
      CalculateFields(TempBuffer);
      Result := FieldValues[ResultFields];
    finally
      RestoreState(dsBrowse);
    end;
  end;
end; // Lookup


{$IFDEF D21H}
procedure TACRDataSet.InitRecord(Buffer: TRecBuf);
begin

  inherited InitRecord(Buffer); // this does not work
  // fix comes here
  InternalInitRecord(Buffer);
  ClearCalcFields(Buffer);
  SetBookmarkFlag(Buffer, bfInserted);
  // fix comes here

  PACRBookmarkInfo(PAnsiChar(Buffer) + FHandle.BookmarkOffset)^.BookmarkFlag := abfInserted;
  PACRBookmarkInfo(PAnsiChar(Buffer) + FHandle.BookmarkOffset)^.BookmarkData.PageNo := INVALID_PAGE_NO;
  PACRBookmarkInfo(PAnsiChar(Buffer) + FHandle.BookmarkOffset)^.BookmarkData.PageItemNo := $FFFF;
end;// InitRecord
{$ELSE}
//------------------------------------------------------------------------------
// InitRecord
//------------------------------------------------------------------------------
procedure TACRDataSet.InitRecord(Buffer: TRecordBuffer);
begin
  inherited InitRecord(Buffer);
  PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkFlag := abfInserted;
  PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkData.PageNo := INVALID_PAGE_NO;
  PACRBookmarkInfo(Buffer + FHandle.BookmarkOffset)^.BookmarkData.PageItemNo := $FFFF;
end;// InitRecord
{$ENDIF}


{$IFDEF 21H}
procedure TACRDataSet.InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
begin
 if (not Active) then
  raise EACRException.Create(10075,ErrorLDatasetIsNotOpened);
 if (State <> dsInsert) then
  raise EACRException.Create(10076,ErrorLDatasetIsNotInInsertOrEditMode);
 if (ReadOnly) then
  raise EACRException.Create(10077,ErrorLDatasetIsInReadOnlyMode);
 if (FHandle = nil) then
  raise EACRException.Create(10078,ErrorLNilPointer);

 FHandle.CurrentRecordBuffer := Buffer;

 if (IsBeforeInsertRecordAssigned or IsAfterInsertRecordAssigned) then
   SaveValues(FNewFieldValues);
 try
   if (IsBeforeInsertRecordAssigned) then
    if (not DoBeforeInsertRecord) then
     begin
      DatabaseError(ErrorLInsertRecordBlockedByDatabaseEvent,Self);
      Exit;
     end;
   FHandle.InternalPost(True);

   if (FHandle.ErrorCode <> ACR_ERR_OK) then
    begin
     if (FHandle.ErrorCode = ACR_ERR_INSERT_RECORD) then
      DatabaseError(Format(ErrorLAddingRecord,
        [FHandle.FTableName,
         BoolToStr(FHandle.InMemory),
         BoolToStr(FHandle.Temporary)]))
     else
      DatabaseError(FHandle.ErrorMessage);
    end // not OK
   else
    begin
     FInsertOrEditComplete := True;
     if (IsAfterInsertRecordAssigned) then
      begin
       if (FValuesChangedByEventHandler) then
        SaveValues(FNewFieldValues);
       DoAfterInsertRecord;
      end;
    end;
 finally
  if (IsBeforeInsertRecordAssigned or IsAfterInsertRecordAssigned) then
   ClearValues(FNewFieldValues);
 end;
end; // InternalAddRecord
{$ELSE}
//------------------------------------------------------------------------------
// appending table (Append flag - ignored, record will be inserted at first empty position)
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
begin
 if (not Active) then
  raise EACRException.Create(10075,ErrorLDatasetIsNotOpened);
 if (State <> dsInsert) then
  raise EACRException.Create(10076,ErrorLDatasetIsNotInInsertOrEditMode);
 if (ReadOnly) then
  raise EACRException.Create(10077,ErrorLDatasetIsInReadOnlyMode);
 if (FHandle = nil) then
  raise EACRException.Create(10078,ErrorLNilPointer);

 FHandle.CurrentRecordBuffer := Buffer;

 if (IsBeforeInsertRecordAssigned or IsAfterInsertRecordAssigned) then
   SaveValues(FNewFieldValues);
 try
   if (IsBeforeInsertRecordAssigned) then
    if (not DoBeforeInsertRecord) then
     begin
      DatabaseError(ErrorLInsertRecordBlockedByDatabaseEvent,Self);
      Exit;
     end;
   FHandle.InternalPost(True);

   if (FHandle.ErrorCode <> ACR_ERR_OK) then
    begin
     if (FHandle.ErrorCode = ACR_ERR_INSERT_RECORD) then
      DatabaseError(Format(ErrorLAddingRecord,
        [FHandle.FTableName,
         BoolToStr(FHandle.InMemory),
         BoolToStr(FHandle.Temporary)]))
     else
      DatabaseError(FHandle.ErrorMessage);    
    end // not OK
   else
    begin
     FInsertOrEditComplete := True;
     if (IsAfterInsertRecordAssigned) then
      begin
       if (FValuesChangedByEventHandler) then
        SaveValues(FNewFieldValues);
       DoAfterInsertRecord;
      end;
    end;
 finally
  if (IsBeforeInsertRecordAssigned or IsAfterInsertRecordAssigned) then
   ClearValues(FNewFieldValues);
 end;
end; // InternalAddRecord
{$ENDIF}


//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalInsert;
begin
 if (not ReadOnly) then
   FHandle.InternalInsert;
end; // InternalInsert


//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalEdit;
begin
 if (not ReadOnly) then
  begin
   if (FHandle = nil) then
    raise EACRException.Create(10065,ErrorLNilPointer);
   if (Pointer(ActiveBuffer) = nil) then
    raise EACRException.Create(10067,ErrorLNilPointer);
   try
     FHandle.InternalEdit;
   except
     on e: Exception do
      begin
       DatabaseError(ErrorLEditingRecord+e.Message);
       Exit;
      end;
   end;
   if (FHandle.ErrorCode = ACR_ERR_OK) then
    begin
     FEditRecordBuffer := TACRRecordBuffer(AllocRecordBuffer);
     Move(PAnsiChar(ActiveBuffer)^,FEditRecordBuffer^,FHandle.RecordSize);
     if (IsBeforeUpdateRecordAssigned or IsAfterUpdateRecordAssigned) then
      SaveValues(FOldFieldValues);
    end
   else
    if (FHandle.ErrorCode = ACR_ERR_UPDATE_RECORD_PROHIBITED) then
     DatabaseError(ErrorLUpdateRecordProhibited);
  end;
end; // InternalEdit


//------------------------------------------------------------------------------
// cancels updates
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalCancel;
begin
 if (State = dsEdit) then
  if (IsBeforeUpdateRecordAssigned or IsAfterUpdateRecordAssigned) then
   ClearValues(FOldFieldValues);
 if (FHandle = nil) then
  raise EACRException.Create(10066,ErrorLNilPointer);
 if (FEditRecordBuffer <> nil) then
   FreeRecordBuffer(TRecordBuffer(FEditRecordBuffer));
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 FHandle.InternalCancel(State = dsInsert);
end; // InternalCancel


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalPost;
var bInsert: Boolean;
begin
 if (not Active) then
  raise EACRException.Create(10029,ErrorLDatasetIsNotOpened);
 if (State <> dsInsert) and (State <> dsEdit) then
  raise EACRException.Create(10030,ErrorLDatasetIsNotInInsertOrEditMode);
 if (ReadOnly) then
  raise EACRException.Create(10032,ErrorLDatasetIsInReadOnlyMode);
 if (FHandle = nil) then
  raise EACRException.Create(10048,ErrorLNilPointer);
 bInsert := (State = dsInsert);
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 if (not bInsert) then
  FHandle.EditRecordBuffer := FEditRecordBuffer;
 if (bInsert) then
  if (IsBeforeInsertRecordAssigned or IsAfterInsertRecordAssigned) then
   SaveValues(FNewFieldValues);
 if (not bInsert) then
  if (IsBeforeUpdateRecordAssigned or IsAfterUpdateRecordAssigned) then
   SaveValues(FNewFieldValues);
 try
   if (bInsert) then
    if (IsBeforeInsertRecordAssigned) then
     if (not DoBeforeInsertRecord) then
      begin
       DatabaseError(ErrorLInsertRecordBlockedByDatabaseEvent,Self);
       Exit;
      end;
   if (not bInsert) then
    if (IsBeforeUpdateRecordAssigned) then
     if (not DoBeforeUpdateRecord) then
      begin
       DatabaseError(ErrorLUpdateRecordBlockedByDatabaseEvent,Self);
       Exit;
      end;
   try
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time12);
{$ENDIF}
     FHandle.InternalPost(State = dsInsert);
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time12);
{$ENDIF}
   except
     on e: Exception do
      begin
       if (State = dsInsert) then
        DatabaseError(ErrorLInsertingRecord+e.Message)
       else
        DatabaseError(ErrorLUpdatingRecord+e.Message);
       Exit;
      end;
   end;
   if (not bInsert) then
    if (FHandle.ErrorCode = ACR_ERR_OK) then
    FreeRecordBuffer(TRecordBuffer(FEditRecordBuffer));
   if (FHandle.ErrorCode <> ACR_ERR_OK) then
     DatabaseError(FHandle.ErrorMessage)
   else
    begin
     FInsertOrEditComplete := True;
     if (bInsert) then
      if (IsAfterInsertRecordAssigned) then
        begin
         if (FValuesChangedByEventHandler) then
          SaveValues(FNewFieldValues);
         DoAfterInsertRecord;
        end;
     if (not bInsert) then
      if (IsAfterUpdateRecordAssigned) then
        begin
         if (FValuesChangedByEventHandler) then
          SaveValues(FNewFieldValues);
         DoAfterUpdateRecord;
        end;
    end;
 finally
   if (bInsert) then
    if (IsBeforeInsertRecordAssigned or IsAfterInsertRecordAssigned) then
     ClearValues(FNewFieldValues);
   if (not bInsert) then
    if (IsBeforeUpdateRecordAssigned or IsAfterUpdateRecordAssigned) then
     begin
       ClearValues(FOldFieldValues);
       ClearValues(FNewFieldValues);
     end;
 end;
end; // InternalPost


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalDelete;
begin
 if (not Active) then
  raise EACRException.Create(10068,ErrorLDatasetIsNotOpened);
 if (ReadOnly) then
  raise EACRException.Create(10069,ErrorLDatasetIsInReadOnlyMode);
 if (FHandle = nil) then
  raise EACRException.Create(10070,ErrorLNilPointer);
 if (Pointer(ActiveBuffer) = nil) then
  raise EACRException.Create(10071,ErrorLNilPointer);
 if (State = dsEdit) then
  Cancel;
 if (IsBeforeDeleteRecordAssigned or IsAfterDeleteRecordAssigned) then
  SaveValues(FOldFieldValues);
 try
   if (IsBeforeDeleteRecordAssigned) then
    if (not DoBeforeDeleteRecord) then
     begin
      DatabaseError(ErrorLDeleteRecordBlockedByDatabaseEvent,Self);
      Exit;
     end;
   FHandle.CurrentRecordBuffer := TACRRecordBuffer(ActiveBuffer);
   try
    FHandle.InternalDelete;
   except
     on e: Exception do
      begin
       DatabaseError(ErrorLDeletingRecord+e.Message);
       Exit;
      end;
   end;
   if (FHandle.ErrorCode <> ACR_ERR_OK) then
    begin
     if (FHandle.ErrorCode = ACR_ERR_DELETE_RECORD_PROHIBITED) then
      DatabaseError(ErrorLDeleteRecordProhibited)
     else
     if (FHandle.ErrorCode = ACR_ERR_DELETE_RECORD) then
      DatabaseError(ErrorLDeletingRecord+FHandle.ErrorMessage)
     else
     if (FHandle.ErrorCode = ACR_ERR_DELETE_RECORD_MODIFIED) then
      DatabaseError(ErrorLDeleteRecordModified)
     else
     if (FHandle.ErrorCode = ACR_ERR_DELETE_RECORD_DELETED) then
      DatabaseError(ErrorLDeleteRecordDeleted);
    end
   else
    begin
     FDeleteRecordFlag := True;
     if (IsAfterDeleteRecordAssigned) then
      DoAfterDeleteRecord;
    end;
 finally
   if (IsBeforeDeleteRecordAssigned or IsAfterDeleteRecordAssigned) then
     ClearValues(FOldFieldValues);
 end;
end; // InternalDelete


//------------------------------------------------------------------------------
// create old and new field values
//------------------------------------------------------------------------------
procedure TACRDataSet.CreateOldNewFieldValues;
var i: Integer;
begin
  FreeOldNewFieldValues;
  SetLength(FOldFieldValues,FAdvFieldDefs.Count);
  SetLength(FNewFieldValues,FAdvFieldDefs.Count);
  for i := 0 to FAdvFieldDefs.Count-1 do
   begin
    FOldFieldValues[i] := TACRVariant.Create;
    FNewFieldValues[i] := TACRVariant.Create;
   end;
end; // CreateOldNewFieldValues


//------------------------------------------------------------------------------
// free old and new field values
//------------------------------------------------------------------------------
procedure TACRDataSet.FreeOldNewFieldValues;
var i: Integer;
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
// save values
//------------------------------------------------------------------------------
procedure TACRDataSet.SaveValues(var Values: TACRArrayOfTACRVariant);
var i: Integer;
begin
  ValuesChangedByEventHandler := False;
  for i := 0 to FAdvFieldDefs.Count-1 do
   GetFieldValue(Values[i],i,False,True);
end; // SaveValues


//------------------------------------------------------------------------------
// clear values
//------------------------------------------------------------------------------
procedure TACRDataSet.ClearValues(var Values: TACRArrayOfTACRVariant);
var i: Integer;
begin
  for i := Low(Values) to High(Values) do
    Values[i].Clear;
end; // ClearValues


//------------------------------------------------------------------------------
// return true if database component for this table has event handler BeforeInsertRecord
//------------------------------------------------------------------------------
function TACRDataSet.IsBeforeInsertRecordAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.BeforeInsertRecord);
end; // IsBeforeInsertRecordAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler AfterInsertRecord
//------------------------------------------------------------------------------
function TACRDataSet.IsAfterInsertRecordAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.AfterInsertRecord);
end; // IsAfterInsertRecordAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler BeforeUpdateRecord
//------------------------------------------------------------------------------
function TACRDataSet.IsBeforeUpdateRecordAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.BeforeUpdateRecord);
end; // IsBeforeUpdateRecordAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler AfterUpdateRecord
//------------------------------------------------------------------------------
function TACRDataSet.IsAfterUpdateRecordAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.AfterUpdateRecord);
end; // IsAfterUpdateRecordAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler BeforeDeleteRecord
//------------------------------------------------------------------------------
function TACRDataSet.IsBeforeDeleteRecordAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.BeforeDeleteRecord);
end; // IsBeforeDeleteRecordAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler AfterDeleteRecord
//------------------------------------------------------------------------------
function TACRDataSet.IsAfterDeleteRecordAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.AfterDeleteRecord);
end; // IsAfterDeleteRecordAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler BeforeExecuteSQL
//------------------------------------------------------------------------------
function TACRDataSet.IsBeforeExecuteSQLAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.BeforeExecuteSQL);
end; // IsBeforeExecuteSQLAssigned


//------------------------------------------------------------------------------
// return true if database component for this table has event handler AfterExecuteSQL
//------------------------------------------------------------------------------
function TACRDataSet.IsAfterExecuteSQLAssigned: Boolean;
begin
  Result := False;
  if (FDatabase <> nil) then
   Result := Assigned(FDatabase.AfterExecuteSQL);
end; // IsAfterExecuteSQLAssigned


//------------------------------------------------------------------------------
// before insert record
//------------------------------------------------------------------------------
function TACRDataSet.DoBeforeInsertRecord: Boolean;
var TableName: WideString;
begin
  TableName := ErrorLUnknownTable;
  if (FHandle <> nil) then
   TableName := FHandle.TableName;
  FDatabase.DoBeforeInsertRecord(FLogComponent,TableName,FNewFieldValues,Result);
  Result := not Result;
end; // DoBeforeInsertRecord


//------------------------------------------------------------------------------
// after insert record
//------------------------------------------------------------------------------
procedure TACRDataSet.DoAfterInsertRecord;
var TableName: WideString;
begin
  TableName := ErrorLUnknownTable;
  if (FHandle <> nil) then
   TableName := FHandle.TableName;
  FDatabase.DoAfterInsertRecord(FLogComponent,TableName,FNewFieldValues);
end; // DoAfterInsertRecord


//------------------------------------------------------------------------------
// before update record
//------------------------------------------------------------------------------
function TACRDataSet.DoBeforeUpdateRecord: Boolean;
var TableName: WideString;
begin
  TableName := ErrorLUnknownTable;
  if (FHandle <> nil) then
   TableName := FHandle.TableName;
  FDatabase.DoBeforeUpdateRecord(FLogComponent,TableName,FOldFieldValues,FNewFieldValues,Result);
  Result := not Result;
end; // DoBeforeUpdateRecord


//------------------------------------------------------------------------------
// after update record
//------------------------------------------------------------------------------
procedure TACRDataSet.DoAfterUpdateRecord;
var TableName: WideString;
begin
  TableName := ErrorLUnknownTable;
  if (FHandle <> nil) then
   TableName := FHandle.TableName;
  FDatabase.DoAfterUpdateRecord(FLogComponent,TableName,FOldFieldValues,FNewFieldValues);
end; // DoAfterUpdateRecord


//------------------------------------------------------------------------------
// before delete record
//------------------------------------------------------------------------------
function TACRDataSet.DoBeforeDeleteRecord: Boolean;
var TableName: WideString;
begin
  TableName := ErrorLUnknownTable;
  if (FHandle <> nil) then
   TableName := FHandle.TableName;
  FDatabase.DoBeforeDeleteRecord(FLogComponent,TableName,FOldFieldValues,Result);
  Result := not Result;
end; // DoBeforeDeleteRecord


//------------------------------------------------------------------------------
// after delete record
//------------------------------------------------------------------------------
procedure TACRDataSet.DoAfterDeleteRecord;
var TableName: WideString;
begin
  TableName := ErrorLUnknownTable;
  if (FHandle <> nil) then
   TableName := FHandle.TableName;
  FDatabase.DoAfterDeleteRecord(FLogComponent,TableName,FOldFieldValues);
end; // DoAfterDeleteRecord


//------------------------------------------------------------------------------
// delete visible records
//------------------------------------------------------------------------------
procedure TACRDataSet.DeleteVisibleRecords;
begin
 if (not Active) then
  raise EACRException.Create(11304,ErrorLDatasetIsNotOpened);
 if (ReadOnly) then
  raise EACRException.Create(11305,ErrorLDatasetIsInReadOnlyMode);
 if (FHandle = nil) then
  raise EACRException.Create(11306,ErrorLNilPointer);
 First;
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 FHandle.DeleteVisibleRecords;
end; // DeleteVisibleRecords


//------------------------------------------------------------------------------
// update visible records
//------------------------------------------------------------------------------
procedure TACRDataSet.UpdateVisibleRecords(
                              FieldNames:   TACRWideStringList;
                              values:       array of TACRVariant
                             );
begin
 if (not Active) then
  raise EACRException.Create(11463,ErrorLDatasetIsNotOpened);
 if (ReadOnly) then
  raise EACRException.Create(11464,ErrorLDatasetIsInReadOnlyMode);
 if (FHandle = nil) then
  raise EACRException.Create(11465,ErrorLNilPointer);
 First;
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 FHandle.UpdateVisibleRecords(FieldNames,values,False);
end; // UpdateVisibleRecords


//------------------------------------------------------------------------------
// return optimal database page size for filling current table
//------------------------------------------------------------------------------
function TACRDataSet.GetOptimalPageSize: Integer;
var DiskRecordSize: Integer;
    PageSize:       Integer;
    HeaderSize:     Integer;
begin
 if (not Active) then
  raise EACRException.Create(11623,ErrorLDatasetIsNotOpened);
 if (FHandle = nil) then
  raise EACRException.Create(11624,ErrorLNilPointer);
 DiskRecordSize := FHandle.GetDiskRecordSize;
 if (DiskRecordSize <= 0) then
  raise EACRException.Create(11626,ErrorLInvalidRecordSize);
 HeaderSize := SizeOf(TACRDiskPageHeader);
 PageSize := ACRMaxPageSize - HeaderSize;
 Result := PageSize -  (PageSize mod DiskRecordSize) ;
 if (Result <= 0) then
  Result := DiskRecordSize;
 Inc(Result,HeaderSize);
end; // GetOptimalPageSize


//------------------------------------------------------------------------------
// return fixed size of the record in disk mode (blob and varchar takes additional space)
//------------------------------------------------------------------------------
function TACRDataSet.GetDiskRecordSize: Integer;
var DiskRecordSize: Integer;
begin
 if (not Active) then
  raise EACRException.Create(11627,ErrorLDatasetIsNotOpened);
 if (FHandle = nil) then
  raise EACRException.Create(11628,ErrorLNilPointer);
 DiskRecordSize := FHandle.GetDiskRecordSize;
 if (DiskRecordSize <= 0) then
  raise EACRException.Create(11629,ErrorLInvalidRecordSize);
 Result := DiskRecordSize;
end; // GetDiskRecordSize


//------------------------------------------------------------------------------
// internal handle exception
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalHandleException;
begin
 Application.HandleException(Self);
end; // InternalHandleException


//------------------------------------------------------------------------------
// is cusor open
//------------------------------------------------------------------------------
function TACRDataSet.IsCursorOpen: Boolean;
begin
  Result := (FHandle <> nil);
{$IFDEF DEBUG_TRACE_DATASET}
if (DebugStarted) then
 aaWriteToLog('TACRDataSet.IsCursorOpen DebugStarted = True')
else
 aaWriteToLog('TACRDataSet.IsCursorOpen DebugStarted = False');

if (Result) then
 aaWriteToLog('TACRDataSet.IsCursorOpen = True')
else
 aaWriteToLog('TACRDataSet.IsCursorOpen = False');

if (Assigned(Designer)) then
 aaWriteToLog('TACRDataSet.IsCursorOpen Designer = True')
else
 aaWriteToLog('TACRDataSet.IsCursorOpen Designer = False');
{$ENDIF}
end;// IsCursorOpen


//------------------------------------------------------------------------------
// internal open
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalOpen;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
var i: Integer;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
if (FHandle = nil) then
  aaWriteToLog('> TACRDataSet.InternalOpen - FHandle = nil ')
else
  aaWriteToLog('> TACRDataSet.InternalOpen - FHandle.TableName = '+FHandle.TableName);
aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
for i := 0 to FieldDefs.Count-1 do
 aaWriteToLog('FieldName ['+IntToStr(i)+'] = '+FieldDefs.Items[i].Name);
aaWriteToLog('AdvFieldDefs.Count = '+IntToStr(AdvFieldDefs.Count));
for i := 0 to AdvFieldDefs.Count-1 do
 aaWriteToLog('AdvFieldName ['+IntToStr(i)+'] = '+AdvFieldDefs.Items[i].Name);
if (FHandle = nil) then
  aaWriteToLog('> TACRDataSet.InternalOpen - FHandle = nil ')
else
  aaWriteToLog('> TACRDataSet.InternalOpen - FHandle.TableName = '+FHandle.TableName);
try
{$ENDIF}
  if (FHandle <> nil) then
    begin
      BookmarkSize := sizeOf(TACRBookmarkInfo);
      try
        FieldDefs.Updated := False;
        FieldDefs.Update;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen #1 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
        GetIndexInfo;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen #2 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}

        if (FEditRecordBuffer <> nil) then
         FreeRecordBuffer(TRecordBuffer(FEditRecordBuffer));
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen #3 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
        if DefaultFields then
          CreateFields;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen #4 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
        BindFields(true);
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen #5 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
      except
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen error #1 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
        if (FHandle <> nil) then
         DestroyHandle;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen error #2 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
        raise;
      end;
      // for OnFilterRecord
      FHandle.Dataset := TACRDataset(Self);
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
  aaWriteToLog('TACRDataSet.InternalOpen #6 - FHandle.TableName = '+FHandle.TableName);
{$ENDIF}
      if (FHandle.RecordBufferSize + CalcFieldsSize > FHandle.RecordBufferSize) then
       FHandle.RecordBufferSize := FHandle.RecordBufferSize + CalcFieldsSize;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
aaWriteToLog('TACRDataSet.InternalOpen #7 - FHandle.TableName = '+FHandle.TableName+#13#10+'FHandle.RecordBufferSize - '+IntToStr(FHandle.RecordBufferSize));
{$ENDIF}
      if (Filtered) then
//      if (FHandle.IsFilterApplied) then
       ActivateFilters;
// commented in v.5.30       
//      else
//       DeactivateFilters;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
aaWriteToLog('TACRDataSet.InternalOpen #8 - FHandle.TableName = '+FHandle.TableName+#13#10+'FHandle.RecordBufferSize - '+IntToStr(FHandle.RecordBufferSize));
{$ENDIF}
      AllocKeyBuffers;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
aaWriteToLog('TACRDataSet.InternalOpen #9 - FHandle.TableName = '+FHandle.TableName+#13#10+'FHandle.RecordBufferSize - '+IntToStr(FHandle.RecordBufferSize));
{$ENDIF}
// commented in v.5.30
//      ResetCursorRange;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
aaWriteToLog('TACRDataSet.InternalOpen #10 - FHandle.TableName = '+FHandle.TableName+#13#10+'FHandle.RecordBufferSize - '+IntToStr(FHandle.RecordBufferSize));
{$ENDIF}
      PrepareCursor;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
aaWriteToLog('TACRDataSet.InternalOpen #11 - FHandle.TableName = '+FHandle.TableName+#13#10+'FHandle.RecordBufferSize - '+IntToStr(FHandle.RecordBufferSize));
{$ENDIF}
      FInsertOrEditComplete := False;
      // added in 4.70
      FHandle.FirstPosition := True;
      FHandle.LastPosition := False;
    end;
{$IFDEF DEBUG_TRACE_TACRDataSet_InternalOpen}
finally
if (FHandle = nil) then
  aaWriteToLog('< TACRDataSet.InternalOpen - FHandle = nil ')
else
  aaWriteToLog('< TACRDataSet.InternalOpen - FHandle.TableName = '+FHandle.TableName);
end;
{$ENDIF}
end;// InternalOpen


//------------------------------------------------------------------------------
// internal close
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalClose;
{$IFDEF DEBUG_TRACE_DATASET}
var i: Integer;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('> TACRDataSet.InternalClose start, ClassName = '+Self.ClassName);
if (Self is TACRTable) then
 aaWriteToLog('TableName = '+TACRTable(Self).TableName);
aaWriteToLog('TACRDataSet.InternalClose - FHandle = nil #1');
{$ENDIF}
 FreeOldNewFieldValues;
 if (FHandle <> nil) then
  begin
   if (FEditRecordBuffer <> nil) then
    FreeRecordBuffer(TRecordBuffer(FEditRecordBuffer));
   FreeKeyBuffers;
  end;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRDataSet.InternalClose, Fields.Count = ' + IntToStr(Fields.Count));
if (FHandle = nil) then
  aaWriteToLog('TACRDataSet.InternalClose - FHandle = nil #2');
{$ENDIF}
 BindFields(False);
 if DefaultFields then
  DestroyFields;
 FIndexFieldCount := 0;
 FIndexFieldMap := nil;
 FKeySize := 0;
 FIsProjectionSet := False;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('< TACRDataSet.InternalClose, Fields.Count = ' + IntToStr(Fields.Count));
aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
for i := 0 to FieldDefs.Count-1 do
 aaWriteToLog('FieldDefs['+IntToStr(i)+'].Name = '+FieldDefs.Items[i].Name);
aaWriteToLog('AdvFieldDefs.Count = '+IntToStr(AdvFieldDefs.Count));
for i := 0 to AdvFieldDefs.Count-1 do
 aaWriteToLog('AdvFieldDefs['+IntToStr(i)+'].Name = '+AdvFieldDefs.Items[i].Name);
aaWriteToLog('Fields.Count = '+IntToStr(Fields.Count));
for i := 0 to Fields.Count-1 do
 aaWriteToLog('Fields['+IntToStr(i)+'].FieldName = '+Fields[i].FieldName);
{$ENDIF}
end; // InternalClose


//------------------------------------------------------------------------------
// init field defs
//------------------------------------------------------------------------------
procedure TACRDataSet.InternalInitFieldDefs;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRDataSet.InternalInitFieldDefs start');
if (FHandle = nil) then
 aaWriteToLog('TACRDataSet.InternalInitFieldDefs FHandle = nil');
{$ENDIF}
   FieldDefs.Clear;
{$IFDEF DEBUG_TRACE_DATASET}
if DebugStarted then
  aaWriteToLog('TACRDataSet.InternalInitFieldDefs debug start');
{$ENDIF}
   if (FHandle <> nil) then
    begin
     // changed in v.4.90
//     if (not FIsProjectionSet) then
//      FHandle.InternalInitFieldDefs;
     GetTableDefinitions(FHandle);
     CreateOldNewFieldValues;
    end;
{$IFDEF DEBUG_TRACE_DATASET}
if DebugStarted then
  aaWriteToLog('TACRDataSet.InternalInitFieldDefs debug finish');
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRDataSet.InternalInitFieldDefs finish');
{$ENDIF}
end;// InternalInitFieldDefs


//------------------------------------------------------------------------------
// get calc field no
//------------------------------------------------------------------------------
function TACRDataset.GetCalcFieldNo(Field: TField): Integer;
var i: Integer;
begin
 Result := 0;
 for i := 0 to Field.FieldNo-2 do
  if (Field.FieldKind = fkCalculated) or (Field.FieldKind = fkLookup) then
   Inc(Result);
end; // GetCalcFieldNo


//------------------------------------------------------------------------------
// read field data to current record buffer
//------------------------------------------------------------------------------
{$IFDEF D17H}
 {$IFDEF D18H}
function TACRDataset.GetFieldData(Field: TField; var Buffer: TValueBuffer; NativeFormat: Boolean): Boolean;
 {$ELSE}
function TACRDataset.GetFieldData(Field: TField; Buffer: TValueBuffer; NativeFormat: Boolean): Boolean;
 {$ENDIF}
{$ELSE}
function TACRDataset.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
{$ENDIF}
const Zero:         Word = $0000;
var Size,ZeroSize:  Integer;
var RecordBuffer:   PAnsiChar;
    aft:            TACRAdvancedFieldType;
    t:              TDateTime;
    xs:             Single;
    xext:           Extended;

    // Added by Aleksander Oven
{$IFDEF D6H}
    xts:            TACRDateTime;
    sts:            TSQLTimeStamp;
{$ENDIF}
    // ------------------------
begin
 Result := False;
 RecordBuffer := GetActiveRecordBuffer;
 if (not Active) or (RecordBuffer = nil) then Exit;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('Dataset.GetFieldData started - FieldNo = ' + IntToStr(Field.FieldNo));
{$ENDIF}
 if (FHandle = nil) then
  raise EACRException.Create(10050,ErrorLNilPointer);
 // this is a calculated or lookup field
 if (Field.FieldNo < 0) or (Field.FieldKind = fkCalculated) or (Field.FieldKind = fkLookup) then
  begin
   // fixed in v.5.30
   Inc(RecordBuffer,FHandle.CalculatedFieldsOffset + Field.Offset);
   // fixed in acr 6.10/smt 5.20
   Result := (Byte(RecordBuffer[0]) <> 0);
if ((Result) and (Buffer <> nil)) then
    begin
{$IFDEF D10H}
     Inc(RecordBuffer);
     aft := FieldTypeToACRAdvFieldType(Field.DataType);
     if (IsStringFieldType(aft)) then
      begin
       if (IsWideStringFieldType(aft)) then
        ZeroSize := 2
       else
        ZeroSize := 1;
       Size := GetStrLength(RecordBuffer,aft) + ZeroSize;
       if (Size > Field.DataSize) then
         Size := Field.DataSize;
       try
         Move(RecordBuffer^,PAnsiChar(Buffer)^,Size);
       except
         raise EACRException.Create(60733,
                ErrorLErrorGettingFieldData,[Field.FieldNo,
                Field.Offset,
                Size]);
       end;
      end
     else
      // just copy pointer to beginning of the zero terminated string (wide string)
      Move(RecordBuffer^,PAnsiChar(Buffer)^,Field.DataSize);
{$ELSE}
//         Move(RecordBuffer^,Buffer^,SizeOf(RecordBuffer));
//         PWideChar(Buffer^) := PWideChar(RecordBuffer);
     Move(RecordBuffer[1],PAnsiChar(Buffer)^,Field.DataSize);
{$ENDIF}
    end;
  end
 else
  begin
   aft := FAdvFieldDefs[Field.FieldNo-1].FDataType;
   if (aft = aftSingle) then
     Result := FHandle.GetFieldData(Field.FieldNo-1,@xs,RecordBuffer)
   else
   if (aft = aftExtended) then
     Result := FHandle.GetFieldData(Field.FieldNo-1,@xext,RecordBuffer)
   // Added by Aleksander Oven
{$IFDEF D6H}
   else if (aft = aftTimeStamp) then
    begin
     Result := FHandle.GetFieldData(Field.FieldNo-1,@xts,RecordBuffer);
    end
{$ENDIF}
   // ------------------------
   else
     Result := FHandle.GetFieldData(Field.FieldNo-1,Buffer,RecordBuffer);


   // Convert
   //  Single --> Double
   //  Extended --> Double
   if (Result and (Buffer <> nil)) then
    begin
     aft := FAdvFieldDefs[Field.FieldNo-1].FDataType;
     case aft of
       aftSingle:     pDouble(Buffer)^ := xs;
       aftExtended:   pDouble(Buffer)^ := xext;
       // Added by Aleksander Oven
{$IFDEF D6H}
       aftTimeStamp:
        begin
          t := ACRDateTimeToDateTime(xts);
          sts := DateTimeToSQLTimeStamp(t);
          PSQLTimeStamp(Buffer)^ := sts;
        end;
{$ENDIF}
       // ------------------------
     end;
    end;

   // call data convert
   if (Result and (Buffer <> nil)) then
    if (Field.DataType in [ftDate,ftTime,ftDateTime]) then
     begin
        InternalDataConvert(Field,Buffer,@t,False);
        {$IFDEF D17H}
        case (Field.DataType) of
         ftDate: TDateTimeRec(PDateTimeRec(Buffer)^).DateTime := t;
         ftTime: TDateTimeRec(PDateTimeRec(Buffer)^).DateTime := t;
        else
         TDateTimeRec(PDateTimeRec(Buffer)^).DateTime := t;
        end;
        {$ELSE}
        case (Field.DataType) of
         ftDate: TDateTimeRec(PDateTimeRec(Buffer)^).Date := Integer(Trunc(t)) + DateDelta;
         ftTime: TDateTimeRec(PDateTimeRec(Buffer)^).Time := Integer(Round(Frac(t) * MSecsPerDay));
        else
         TDateTimeRec(PDateTimeRec(Buffer)^).DateTime := (t + DateDelta) * MSecsPerDay;
        end;
        {$ENDIF}
     end;
  end;
{$IFDEF DEBUG_TRACE_DATASET}
 if (Result) then
  aaWriteToLog('Dataset.GetFieldData finished - FieldNo = ' +
    IntToStr(Field.FieldNo) + ', Result = True')
 else
  aaWriteToLog('Dataset.GetFieldData finished - FieldNo = ' +
    IntToStr(Field.FieldNo) + ', Result = False');
{$ENDIF}
end; // GetFieldData


//------------------------------------------------------------------------------
// write field data from buffer to current record buffer
//------------------------------------------------------------------------------
{$IFDEF D17H}
procedure TACRDataset.SetFieldData(Field: TField; Buffer: TValueBuffer; NativeFormat: Boolean);
{$ELSE}
procedure TACRDataset.SetFieldData(Field: TField; Buffer: Pointer);
{$ENDIF}
 procedure Finalize;
 begin
  if not (State in [dsCalcFields, dsFilter, dsNewValue]) then
   DataEvent(deFieldChange, Longint(Field));
 end; // Finalize

const w: Word = $0000;

var
    SourceBuffer: PAnsiChar;
    RecordBuffer: PAnsiChar;
    t:            TDateTime;
    aft:          TACRAdvancedFieldType;
    len,sz:       Integer;
begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('Dataset.SetFieldData started - FieldNo = ' + IntToStr(Field.FieldNo));
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('> Dataset.SetFieldData started - FieldNo = ' + IntToStr(Field.FieldNo)+', FieldName = '+Field.FieldName);
{$ENDIF}

 if not (State in dsWriteModes) then
  raise EACRException.Create(10007, ErrorLDatasetIsNotInEditOrInsertMode);

 if ((State = dsSetKey) and
     ((Field.FieldNo < 0) or
      (FIndexFieldCount > 0) and not Field.IsIndexField)) then
  raise EACRException.Create(20019, ErrorANotIndexField, [Field.DisplayName]);

 RecordBuffer := GetActiveRecordBuffer;

 if (FHandle = nil) then
  raise EACRException.Create(10051,ErrorLNilPointer);
 ValuesChangedByEventHandler := True;
 // this is a calculated or lookup field
 if (Field.FieldNo < 0) or (Field.FieldKind = fkCalculated) or (Field.FieldKind = fkLookup) then
  begin
    // fixed in v.5.30
    Inc(RecordBuffer,FHandle.CalculatedFieldsOffset + Field.Offset);
    ByteBool(RecordBuffer[0]) := (Buffer <> nil);
    if ByteBool(RecordBuffer[0]) then
     begin
{$IFDEF D10H}
     Inc(RecordBuffer);
      aft := FieldTypeToACRAdvFieldType(Field.DataType);
      if (IsStringFieldType(aft)) then
       begin
        // buffer is the buffer with null terminated string (wide string)
        SourceBuffer := PAnsiChar(Buffer);
        if (IsWideStringFieldType(aft)) then
         sz := 2
        else
         sz := 1;
        len := GetStrLength(SourceBuffer,aft);
        if (len > Field.DataSize) then
         len := Field.DataSize-sz;
        if (len > 0) then
         Move(SourceBuffer^,RecordBuffer^,len);
        if (len+sz <= Field.DataSize) then
         Move(w,PAnsiChar(PAnsiChar(RecordBuffer)+len)^,sz)
        else
         Move(w,PAnsiChar(PAnsiChar(RecordBuffer)+Field.DataSize-sz)^,sz);
       end
      else
        Move(PAnsiChar(Buffer)^,RecordBuffer^,Field.DataSize);
        // buffer stores pointer to the buffer with null terminated string (wide string)
//          SourceBuffer := PAnsiChar(Buffer^);
//          Move(SourceBuffer,RecordBuffer^,SizeOf(SourceBuffer));
{$ELSE}
          Move(Buffer^,RecordBuffer[1],Field.DataSize);
{$ENDIF}
  {$IFDEF DEBUG_TRACE_DATACONVERT}
  aaWriteToLog(' Dataset.SetFieldData len = '+IntToStr(len)+', sz = '+IntToStr(sz));
  {$ENDIF}
     end;
    Finalize;
  end
 else
  begin
   Field.Validate(Buffer);
   // call data convert
   if (Buffer <> nil) then
    if (Field.DataType in [ftDate,ftTime,ftDateTime]) then
     begin
      {$IFDEF D17H}
        case (Field.DataType) of
         ftDate: t := TDateTimeRec(PDateTimeRec(Buffer)^).DateTime;
         ftTime: t := TDateTimeRec(PDateTimeRec(Buffer)^).DateTime;
          else
                 t := TDateTimeRec(PDateTimeRec(Buffer)^).DateTime;
        end;
        InternalDataConvert(Field,@t,Buffer,True);
      {$ELSE}
        case (Field.DataType) of
         ftDate: t := TDateTimeRec(PDateTimeRec(Buffer)^).Date - DateDelta;
         ftTime: t := TDateTimeRec(PDateTimeRec(Buffer)^).Time / MSecsPerDay;
          else
                 t := (TDateTimeRec(PDateTimeRec(Buffer)^).DateTime / MSecsPerDay) - DateDelta;
        end;
        InternalDataConvert(Field,@t,Buffer,True);
      {$ENDIF}
     end;

   // Convert
   //  Double --> Single
   //  Extended --> Double
   if (Buffer <> nil) then
    begin
     aft := FAdvFieldDefs[Field.FieldNo-1].FDataType;
     case aft of
       aftSingle:
            begin
              //pSingle(Buffer)^ := Single(pDouble(Buffer)^);
              pSingle(Buffer)^ := StrToFloat(FloatToStr(pDouble(Buffer)^));
            end;
       aftExtended:
            begin
              pExtended(Buffer)^ := pDouble(Buffer)^;
            end;
     end;
    end;
   FHandle.SetFieldData(Field.FieldNo-1,Buffer,RecordBuffer);
   Finalize;
  end;
{$IFDEF DEBUG_TRACE_DATACONVERT}
aaWriteToLog('< Dataset.SetFieldData started - FieldNo = ' + IntToStr(Field.FieldNo)+', FieldName = '+Field.FieldName);
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('Dataset.SetFieldData finished - FieldNo = ' + IntToStr(Field.FieldNo));
{$ENDIF}
end; // SetFieldData


//------------------------------------------------------------------------------
// get field value
//------------------------------------------------------------------------------
procedure TACRDataset.GetFieldValue(Value: TACRVariant; FieldNo: Integer; DirectAccess: Boolean; CopyFlag: Boolean = True);
var
  Buffer:     PAnsiChar;
  bs:         TACRBlobStream;
  BaseType:   TACRBaseFieldType;
  BufferSize: Integer;
  w:          Word; // 2 zero bytes
begin
 if (FHandle = nil) then
  raise EACRException.Create(10315,ErrorLNilPointer);
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 BaseType := AdvancedFieldTypeToBaseFieldType(AdvFieldDefs[FieldNo].FDataType);
 if (FHandle.CurrentRecordBuffer = nil) then
 begin
  // fixed in v.5.80
//  raise EACRException.Create(12429,ErrorLNilPointer);
     // empty dataset
     Value.Clear(BaseType);
     Exit;
 end;
 if (IsBlobFieldType(AdvFieldDefs[FieldNo].FDataType)) then
   begin
     Value.Clear(BaseType);
     bs := TACRBlobStream.Create(TBlobField(Fields[FieldNo]), bmRead);
     try
      BufferSize := bs.Size;
      if (BufferSize > 0) then
       begin
{
         if (BaseType = bftClob) then
          BufferSize := bs.Size+1
         else
         if (BaseType = bftWideClob) then
          BufferSize := bs.Size+2
         else
          BufferSize := bs.Size;
         if (BufferSize = bs.Size) then
          Buffer := MemoryManager.GetMem(BufferSize)
         else
          Buffer := MemoryManager.AllocMem(BufferSize);
         try
           bs.ReadBuffer(Buffer^,bs.Size);
           Value.SetData(Buffer, BufferSize, BaseType);
         finally
           MemoryManager.FreeAndNilMem(Buffer);
         end;
}


//4.30
{
         BufferSize := bs.Size;
         Buffer := MemoryManager.GetMem(BufferSize);
//         Buffer := MemoryManager.AllocMem(BufferSize);
         try
           bs.ReadBuffer(Buffer^,bs.Size);
           Value.SetData(Buffer, BufferSize, BaseType);
         finally
           MemoryManager.FreeAndNilMem(Buffer);
         end;
}
// 4.40
          Buffer := MemoryManager.GetMem(BufferSize+2);
          w := 0;
          bs.ReadBuffer(Buffer^,BufferSize);
          Move(w,PAnsiChar(Buffer+BufferSize)^,2);
          Value.InternalSetBuffer(Buffer,BufferSize);
       end;//if
     finally
       bs.Free;
     end;
   end
 else
   begin
     FHandle.GetFieldValue(Value,FieldNo,DirectAccess,CopyFlag);
   end;
end; // GetFieldValue


//------------------------------------------------------------------------------
// set field value
//------------------------------------------------------------------------------
procedure TACRDataset.SetFieldValue(Value: TACRVariant; FieldNo: Integer; DirectAccess: Boolean);
var
  bs:       TACRBlobStream;
  DataSize: Integer;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10316,ErrorLNilPointer);
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;

 if (IsBlobFieldType(AdvFieldDefs[FieldNo].FDataType)) then
  begin
   if (not Value.IsNull) then
    begin
     bs := TACRBlobStream.Create(TBlobField(Fields[FieldNo]), bmWrite);
     try
      // 4.40
      //       bs.WriteBuffer(Value.pData^, MemoryManager.GetMemoryBufferSize(Value.pData));
      // v.4.60
      if (Value.IsStringDataType and not (value.FIsBlob)) then
        bs.WriteBuffer(Value.pData^, Value.StrLen)
       else
        bs.WriteBuffer(Value.pData^, Value.DataSize);
     finally
       bs.Free;
     end
    end
   else
    FHandle.SetFieldValue(Value,FieldNo,DirectAccess);
  end
 else
   begin
    FHandle.SetFieldValue(Value,FieldNo,DirectAccess);
   end;
end; // SetFieldValue


//------------------------------------------------------------------------------
// lock table in S mode and load internal data for fast navigation
//------------------------------------------------------------------------------
procedure TACRDataset.LockTable(bWriteMode: Boolean);
begin
  CheckActive;
  FHandle.LockTable(bWriteMode);
end; // LockTable


//------------------------------------------------------------------------------
// unlock table in S mode and free internal data
//------------------------------------------------------------------------------
procedure TACRDataset.UnlockTable(bWriteMode: Boolean);
begin
  CheckActive;
  FHandle.UnlockTable(bWriteMode);
end; // LockTable


//------------------------------------------------------------------------------
// go to current
//------------------------------------------------------------------------------
procedure TACRDataset.GotoCurrent(Source: TACRDataset);
begin
 if (not Source.Active) or (not Active) then
  DatabaseError(ErrorLGotoCurrentTablesNotOpened);
 if (GetTableNameCRC(FDatabaseName) <> GetTableNameCRC(source.FDatabaseName)) or
    (GetTableNameCRC(FHandle.TableName) <> GetTableNameCRC(source.FHandle.TableName)) or
    (FHandle.Temporary <> source.FHandle.Temporary) or
    (FHandle.InMemory <> source.FHandle.InMemory) then
  DatabaseError(ErrorLGotoCurrentTablesAreDifferent)
 else
  begin
   TACRCursor(FHandle).FirstPosition := TACRCursor(Source.FHandle).FirstPosition;
   TACRCursor(FHandle).LastPosition := TACRCursor(Source.FHandle).LastPosition;
   TACRCursor(FHandle).CurrentRecordID := TACRCursor(Source.FHandle).CurrentRecordID;
   DoBeforeScroll;
   Resync([rmExact, rmCenter]);
   DoAfterScroll;
  end;
end; // GoToCurrent

//------------------------------------------------------------------------------
// create Blob stream
//------------------------------------------------------------------------------
function TACRDataset.InternalCreateBlobStream(
    					Field:  TField;
              Mode:   TBlobStreamMode
              ): TACRStream;
var OpenMode: TACRBlobOpenMode;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10108,ErrorLNilPointer);
 if (
      ((Mode = bmReadWrite) or (Mode = bmWrite)) and
      (State <> dsInsert) and (State <> dsEdit)
    ) then
  raise EACRException.Create(10111,ErrorLDatasetIsNotInEditOrInsertMode);

 OpenMode := bomRead;
 case Mode of
  bmRead:
    OpenMode := bomRead;
  bmReadWrite:
    OpenMode := bomReadWrite;
  bmWrite:
    OpenMode := bomWrite;
 end;
// FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 if (FHandle.CurrentRecordBuffer = nil) then
  begin
   Result := FHandle.InternalCreateBlobStream(True,
    Field.FieldNo-1,OpenMode);
  end
 else
  begin
   Move(PAnsiChar(FHandle.CurrentRecordBuffer + FHandle.BookmarkOffset)^,
    FHandle.CurrentRecordID,sizeof(TACRRecordID));
   Result := FHandle.InternalCreateBlobStream((State = dsInsert),
    Field.FieldNo-1,OpenMode);
  end;
end; // InternalCreateBlobStream


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TACRDataset.SetCaseInsensitive(Value: Boolean);
begin
  FCaseInsensitive := Value;
  if (FHandle <> nil) then
   FHandle.CaseInsensitive := FCaseInsensitive;
end; // SetCaseInsensitive


//------------------------------------------------------------------------------
// create TACRBlobStream
//------------------------------------------------------------------------------
function TACRDataset.CreateBlobStream(
    					Field:  TField;
              Mode:   TBlobStreamMode
              ): TStream;
var Buffer: TACRRecordBuffer;
begin
 if ((Mode <> bmRead) and (TACRDataset(Field.DataSet).ReadOnly)) then
  raise EACRException.Create(10107,ErrorLDatasetIsInReadOnlyMode);
 Result := TACRBlobStream.Create(TBlobField(Field),Mode);
 if (Mode <> bmRead) then
  ValuesChangedByEventHandler := True;
end; // CreateBlobStream


//------------------------------------------------------------------------------
// close Blob stream, write Blob field value to Blob data file
//------------------------------------------------------------------------------
procedure TACRDataset.CloseBlob(Field: TField);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10108,ErrorLNilPointer);
 FHandle.CurrentRecordBuffer := GetActiveRecordBuffer;
 FHandle.InternalCloseBlob(Field.FieldNo-1);
end; // CloseBlob


//------------------------------------------------------------------------------
// bug fix for TIndexDefs.Assign that looses DescFields and CaseInsFields
//------------------------------------------------------------------------------
procedure TACRDataset.IndexDefsAssign(Source,Dest: TIndexDefs);
var i: Integer;
begin
  Dest.Assign(Source);
  for i := 0 to Dest.Count-1 do
   begin
     if (Source.Items[i].CaseInsFields <> '') then
      Dest.Items[i].CaseInsFields := Source.Items[i].CaseInsFields;
     if (Source.Items[i].DescFields <> '') then
      Dest.Items[i].DescFields := Source.Items[i].DescFields;
   end;
end; // IndexDefsAssign


//------------------------------------------------------------------------------
// fills FieldDefs,AdvFieldDefs,IndexDefs,ForeignKeyDefs,Restructure...Defs
// from the cursor
//------------------------------------------------------------------------------
procedure TACRDataset.GetTableDefinitions(Cursor: TACRCursor);
begin
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('> TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName+
#13#10+'Cursor = '+IntToHex(Integer(Cursor),8));
try
{$ENDIF}
 if (Cursor <> nil) then
  begin
   // Fill ACRFieldDefs
   FACRFieldDefs.Assign(Cursor.VisibleFieldDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('1 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   // Fill FieldDefs
   ConvertACRFieldDefsToFieldDefs(Cursor.VisibleFieldDefs, Cursor.FConstraintDefs, FieldDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('2 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   //Fill AdvFieldDefs
   ConvertACRFieldDefsToAdvFieldDefs(Cursor.VisibleFieldDefs,Cursor.FieldDefs, Cursor.FConstraintDefs, AdvFieldDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('3 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   // index defs
   UpdateIndexDefinitions(Cursor);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('4 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   // fill foreign key defs
   ConvertConstraintDefsToForeignKeyDefs(Cursor.FConstraintDefs,FForeignKeyDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('5 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   FACRConstraintDefs.Assign(Cursor.ConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('6 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   FRestructureFieldDefs.Assign(FAdvFieldDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('7 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   FRestructureForeignKeyDefs.Assign(FForeignKeyDefs);
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('8 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   FieldDefs.Updated := True;
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('9 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
   FIndexDefs.Updated := True;
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('10 TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName);
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TACRDataset_GetTableDefinitions}
aaWriteToLog('< TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName+
#13#10+'Cursor = '+IntToHex(Integer(Cursor),8));
except
 on E: exception do
  begin
aaWriteToLog('< TACRDataset.GetTableDefinitions. Self.ClassName = '+Self.ClassName+
#13#10+'Cursor = '+IntToHex(Integer(Cursor),8)+#13#10+'Error: '+#13#10+e.Message);
  end;
end;  
{$ENDIF}
end; // GetTableDefinitions


//------------------------------------------------------------------------------
// for AddIndex / DeleteIndex on opened cursor(s)
//------------------------------------------------------------------------------
procedure TACRDataset.UpdateIndexDefinitions(Cursor: TACRCursor);
begin
 FAdvIndexDefs.Assign(Cursor.IndexDefs);
 ConvertACRIndexDefsToIndexDefs(Cursor.IndexDefs, FIndexDefs);
 IndexDefsAssign(FIndexDefs,FRestructureIndexDefs);
 FIndexDefs.Updated := True;
end; // UpdateIndexDefinitions


//------------------------------------------------------------------------------
// clear FieldDefs,AdvFieldDefs,IndexDefs,AdvIndexDefs,ForeignKeyDefs, etc.
// call it before CreateTable
//------------------------------------------------------------------------------
procedure TACRDataset.ClearDefinitions;
begin
  FieldDefs.Clear;
  AdvFieldDefs.Clear;
  IndexDefs.Clear;
  AdvIndexDefs.Clear;
  ForeignKeyDefs.Clear;
end; // ClearDefinitions


//------------------------------------------------------------------------------
// assign definitions from Source dataset
//------------------------------------------------------------------------------
procedure TACRDataset.AssignDefinitions(Source: TACRDataset);
begin
  AdvFieldDefs.Assign(Source.AdvFieldDefs);
//    IndexDefs.Assign(TACRDataSet(SourceTable).IndexDefs);
  // fixed in v.4.80
  IndexDefsAssign(Source.IndexDefs,FIndexDefs);
  ForeignKeyDefs.Assign(Source.ForeignKeyDefs);
end; // AssignDefinitions


//------------------------------------------------------------------------------
// return FHandle from TACRDatabase
//------------------------------------------------------------------------------
function TACRDataset.GetBaseSession: TACRBaseSession;
begin
  Result := nil;
  if (FDatabase <> nil) then
   Result := FDatabase.Handle;
end; // GetBaseSession


//------------------------------------------------------------------------------
// set Handle to nil to avoid its destroying - needed by SQL engine
//------------------------------------------------------------------------------
procedure TACRDataset.ResetHandle;
begin
  InternalClose;
  FHandle := nil;
end; // ResetHandle


//------------------------------------------------------------------------------
// allocate record buffer
//------------------------------------------------------------------------------
function TACRDataset.AllocRecordBuffer: TRecordBuffer;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRDataset.AllocRecordBuffer');
 if (FHandle = nil) then
    aaWriteToLog('TACRDataset.AllocRecordBuffer - FHandle = nil');
{$ENDIF}
 if (FHandle = nil) then
  raise EACRException.Create(10052,ErrorLNilPointer);
 Result := TRecordBuffer(FHandle.AllocateRecordBuffer);
end; // AllocRecordBuffer


//------------------------------------------------------------------------------
// free record buffer
//------------------------------------------------------------------------------
procedure TACRDataset.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRDataset.FreeRecordBuffer');
 if (FHandle = nil) then
    aaWriteToLog('TACRDataset.FreeRecordBuffer - FHandle = nil');
{$ENDIF}
 if (FHandle = nil) then
   MemoryManager.FreeAndNilMem(Buffer)
 else
   FHandle.FreeRecordBuffer(TACRRecordBuffer(Buffer));
end; // FreeRecordBuffer


{$IFDEF D21H}
//------------------------------------------------------------------------------
// initialize record buffer
//------------------------------------------------------------------------------
procedure TACRDataset.InternalInitRecord(Buffer: TRecBuf);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10054,ErrorLNilPointer);
 FHandle.InternalInitRecord(TACRRecordBuffer(Buffer),True);
end;
{$ELSE}
//------------------------------------------------------------------------------
// initialize record buffer
//------------------------------------------------------------------------------
procedure TACRDataset.InternalInitRecord(Buffer: TRecordBuffer);
begin
 if (FHandle = nil) then
  raise EACRException.Create(10054,ErrorLNilPointer);
 FHandle.InternalInitRecord(TACRRecordBuffer(Buffer),True);
end;
{$ENDIF}

//------------------------------------------------------------------------------
// return record size in bytes
//------------------------------------------------------------------------------
function TACRDataset.GetRecordSize: Word;
begin
 if (FHandle = nil) then
  raise EACRException.Create(10055,ErrorLNilPointer);
 Result := FHandle.RecordSize;
end; // Get Record Size


//------------------------------------------------------------------------------
// return true if range is applied
//------------------------------------------------------------------------------
function TACRDataset.IsRangeApplied: Boolean;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10298,ErrorLNilPointer);
  Result := FHandle.IsRangeApplied;
end; // IsRangeApplied


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRDataset.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInMemory := False;
  FTemporary := False;
  {$IFDEF SQLMEMTABLE}
  FDatabaseName := ACRMemoryDatabaseName;
  FSessionName := ''; 
  FInMemory := True;
  {$ENDIF}
  FOldFieldValues := nil;
  FNewFieldValues := nil;
  FLogComponent := Self;
  ACRDatasetsList := ACRDatasets.LockList;
  ACRDatasetsList.Add(Self);
  ACRDatasets.UnlockList;
  FDatabase := nil;
  FExternalHandle := nil;
  FIsProjectionSet := False;
  FRepair := False;
  FHandle := nil;
  FEditRecordBuffer := nil;
  FIndexDefs := TIndexDefs.Create(Self);
  FACRFieldDefs := TACRFieldDefs.Create;
  FAdvIndexDefs := TACRIndexDefs.Create;
  FAdvFieldDefs := TACRAdvFieldDefs.Create;
  FForeignKeyDefs := TACRForeignKeyDefs.Create;
  FRestructureIndexDefs := TIndexDefs.Create(Self);
  FRestructureFieldDefs := TACRAdvFieldDefs.Create;
  FRestructureForeignKeyDefs := TACRForeignKeyDefs.Create;
  FACRConstraintDefs := TACRConstraintDefs.Create;
  FInsertOrEditComplete := False;
  if (not IsDesignMode) then
   if (AOwner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
     begin
      IsDesignMode := true;
     end;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRDataset.Destroy;
begin
{$IFDEF DEBUG_TRACE_DATASET}
if (FHandle = nil) then
aaWriteToLog('> TACRDataset.Destroy - FHandle = nil'
+#13#10+'ClassName = '+ClassName)
else
aaWriteToLog('> TACRDataset.Destroy'
+#13#10+'ClassName = '+ClassName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'FTableName = '+FHandle.TableName
+#13#10+'FInMemory = '+BoolToStr(FHandle.FInMemory,True)
+#13#10+'FTableName = '+BoolToStr(FHandle.FTemporary,True)
);
{$ENDIF}

 if (FEditRecordBuffer <> nil) then
  FreeRecordBuffer(TRecordBuffer(FEditRecordBuffer));
 Active := false;
 ACRDatasetsList := ACRDatasets.LockList;
 ACRDatasetsList.Remove(Self);
 ACRDatasets.UnlockList;
 inherited Destroy;
 FIndexDefs.Free;
 FACRFieldDefs.Free;
 FAdvIndexDefs.Free;
 FAdvFieldDefs.Free;
 FForeignKeyDefs.Free;
 FRestructureIndexDefs.Free;
 FRestructureFieldDefs.Free;
 FRestructureForeignKeyDefs.Free;
 FACRConstraintDefs.Free;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('< TACRDataset.Destroy - OK'
+#13#10+'ClassName = '+ClassName);
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// open database
//------------------------------------------------------------------------------
function TACRDataset.OpenDatabase: TACRDatabase;
begin
{$IFDEF DEBUG_TRACE_TACRDataset_OpenDatabase}
aaWriteToLog('> TACRDataset.OpenDatabase - Self = '+IntToHex(Integer(Self),8)+', ClassName = '+Self.ClassName
+#13#10+'FSessionName = '+FSessionName
+#13#10+'FDatabaseName = '+FDatabaseName
+#13#10+'FDatabase = '+IntToHex(Integer(FDatabase),8)
);
if (FHandle <> nil) then
 aaWriteToLog('FTableName = '+FHandle.TableName
 +#13#10+'InMemory = '+BoolToStr(FHandle.IsMemoryTable,True)
 +#13#10+'Temporary = '+BoolToStr(FHandle.IsTemporaryTable,True)
 );
{$ENDIF}
  with Sessions.List[FSessionName] do
   begin
{$IFDEF DEBUG_TRACE_TACRDataset_OpenDatabase}
aaWriteToLog('1. TACRDataset.OpenDatabase - Self = '+IntToHex(Integer(Self),8)+', ClassName = '+Self.ClassName);
{$ENDIF}
    Result := DoOpenDatabase(FDatabaseName,FInMemory,FTemporary,Self.Owner);
{$IFDEF DEBUG_TRACE_TACRDataset_OpenDatabase}
aaWriteToLog('2. TACRDataset.OpenDatabase - Self = '+IntToHex(Integer(Self),8)+', ClassName = '+Self.ClassName+#13#10+'Result = '+IntToHex(Integer(Result),8));
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRDataset_OpenDatabase}
aaWriteToLog('< TACRDataset.OpenDatabase - OK');
{$ENDIF}
end;// OpenDatabase


//------------------------------------------------------------------------------
// close database
//------------------------------------------------------------------------------
procedure TACRDataset.CloseDatabase(Database: TACRDatabase);
begin
  if Assigned(Database) then
    Database.FSession.CloseDatabase(Database);
end;// CloseDatabase



////////////////////////////////////////////////////////////////////////////////
//
//  TACRTable
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF D6H}
//------------------------------------------------------------------------------
// get default order
//------------------------------------------------------------------------------
function TACRTable.PSGetDefaultOrder: TIndexDef;

  function GetIdx(IdxType: TIndexOption): TIndexDef;
  var
    i: Integer;
  begin
    Result := nil;
    for i := 0 to IndexDefs.Count - 1 do
      if (IdxType in IndexDefs[i].Options) then
      try
        Result := IndexDefs[i];
        GetFieldList(TList(nil), Result.Fields);
        break;
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
    // fixed in v.4.80
    Result.CaseInsFields := DefIdx.CaseInsFields;
    Result.DescFields := DefIdx.DescFields;
   end
  else
   Result := nil;
end; // PSGetDefaultOrder


//------------------------------------------------------------------------------
// get key fields
//------------------------------------------------------------------------------
function TACRTable.PSGetKeyFields: String;
var
  i, Pos: Integer;
  IndexFound: Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
aaWriteToLog('> TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8));
try
{$ENDIF}

  Result := inherited PSGetKeyFields;
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
aaWriteToLog('1 TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'Result = '+#13#10+Result+#13#10+'!!!'
);
{$ENDIF}
  if Result = '' then
   begin
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
aaWriteToLog('1.1 TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'IndexDefs.Count = '+IntToStr(IndexDefs.Count)
);
{$ENDIF}
    if not Exists then
     begin
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
aaWriteToLog('< TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'IndexDefs.Count = '+IntToStr(IndexDefs.Count)
);
{$ENDIF}
     Exit;
     end;
    IndexFound := False;
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
aaWriteToLog('2 TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'IndexDefs.Count = '+IntToStr(IndexDefs.Count)
);
{$ENDIF}
    IndexDefs.Update;
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
aaWriteToLog('3 TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'IndexDefs.Count = '+IntToStr(IndexDefs.Count)
);
{$ENDIF}
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
{$IFDEF DEBUG_TRACE_TACRTable_PSGetKeyFields}
finally
aaWriteToLog('< TACRTable.PSGetKeyFields. TableName = '+FTableName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'Result = '+#13#10+Result+#13#10+'!!!'
);
end;
{$ENDIF}
end; // PSGetKeyFields


//------------------------------------------------------------------------------
// get table name
//------------------------------------------------------------------------------
function TACRTable.PSGetTableName: String;
begin
  Result := TableName;
end; // PSGetTableName


//------------------------------------------------------------------------------
// get index defs
//------------------------------------------------------------------------------
function TACRTable.PSGetIndexDefs(IndexTypes: TIndexOptions): TIndexDefs;
begin
  Result := GetIndexDefs(IndexDefs, IndexTypes);
end; // PSGetIndexDefs


//------------------------------------------------------------------------------
// set command text
//------------------------------------------------------------------------------
procedure TACRTable.PSSetCommandText(const CommandText: String);
begin
  if CommandText <> '' then
    TableName := CommandText;
end; // PSSetCommandText


//------------------------------------------------------------------------------
// set params
//------------------------------------------------------------------------------
procedure TACRTable.PSSetParams(AParams: TParams);

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
// check table name is blank?
//------------------------------------------------------------------------------
procedure TACRTable.CheckBlankTableName;
begin
 if (not FTemporary) then
  if (FTableName = '') then
    DatabaseError(ErrorANoTableName, Self);
end;// CheckBlankTableName


//------------------------------------------------------------------------------
// set temporary
//------------------------------------------------------------------------------
procedure TACRTable.SetTemporary(const Value: Boolean);
begin
  CheckInactive;
  FTemporary := Value;
  // to avoid problems with temporary databases in multi-threaded applications 
  if (Value) then
   FDatabaseName := ACRTemporaryDatabaseName+'_'+IntToStr(GetCurrentThreadId);
end;// SetTemporary


//------------------------------------------------------------------------------
// GetIndexFieldNames
//------------------------------------------------------------------------------
function TACRTable.GetIndexFieldNames: WideString;
begin
  if FFieldsIndex then
    Result := FIndexName
  else
    Result := '';
end;// GetIndexFieldNames


//------------------------------------------------------------------------------
// GetIndexName
//------------------------------------------------------------------------------
function TACRTable.GetIndexName: WideString;
begin
  if FFieldsIndex then
    Result := ''
  else
    Result := FIndexName;
end;// GetIndexName


//------------------------------------------------------------------------------
// GetIndexParams
//------------------------------------------------------------------------------
procedure TACRTable.GetIndexParams(const IndexName: WideString; FieldsIndex: Boolean;
         var IndexedName: WideString);
var
  IndexStr: AnsiString;
begin
  IndexStr := '';
  if (IndexName <> '') then
   begin
     FIndexDefs.Updated := False;
     FIndexDefs.Update;
     IndexStr := IndexName;
     if FieldsIndex then
       IndexStr := FIndexDefs.FindIndexForFields(IndexName).Name;
   end;
  IndexedName := IndexStr;
end;// GetIndexParams


//------------------------------------------------------------------------------
// IndexDefsStored
//------------------------------------------------------------------------------
function TACRTable.IndexDefsStored: Boolean;
begin
  Result := (FStoreDefs and (IndexDefs.Count > 0));
end;// IndexDefsStored


//------------------------------------------------------------------------------
// SetIndex
//------------------------------------------------------------------------------
procedure TACRTable.SetIndex(const Value: WideString; FieldsIndex: Boolean);
var
  IndexName: WideString;
begin
  if Active then
    CheckBrowseMode;
  if (FIndexName <> Value) or (FFieldsIndex <> FieldsIndex) then
    begin
      if Active then
        begin
         GetIndexParams(Value, FieldsIndex,IndexName);
         SwitchToIndex(IndexName);
         CheckMasterRange;
        end;
      FIndexName := Value;
      FFieldsIndex := FieldsIndex;
      if Active then
       Resync([]);
    end;
end;// SetIndex


//------------------------------------------------------------------------------
// SetIndexFieldNames
//------------------------------------------------------------------------------
procedure TACRTable.SetIndexFieldNames(const Value: WideString);
begin
  SetIndex(Value, Value <> '');
end;// SetIndexFieldNames


//------------------------------------------------------------------------------
// SetIndexName
//------------------------------------------------------------------------------
procedure TACRTable.SetIndexName(const Value: WideString);
begin
  SetIndex(Value, False);
end;// SetIndexName


//------------------------------------------------------------------------------
// create cursor: local or client
//------------------------------------------------------------------------------
function TACRTable.CreateCursor(bOpenView: Boolean): TACRCursor;
begin
  Result := nil;
  if (FDatabase = nil) then
   begin
    if (Self.Owner <> nil) then
     if (Self.Owner is TForm) then
      if (fsCreating in TForm(Self.Owner).FormState) then
       Exit;
    raise EACRException.Create(10915,ErrorLNilPointer);
   end;
   Result := FDatabase.Handle.CreateCursor(FTableName,bOpenView);
(*
{$IFDEF SQLMEMTABLE}
  Result := TACRLocalCursor.Create;
  Result.Repair := FRepair;
{$ELSE}
  {$IFDEF LOCAL_VERSION}
  if (FDatabase.FLocalDatabase) then
   begin
    Result := TACRLocalCursor.Create;
    Result.Repair := FRepair;
   end;
  {$ENDIF}
  {$IFDEF CLIENT_VERSION}
  if (not FDatabase.LocalDatabase) then
    Result := TACRClientCursor.Create;
  {$ENDIF}
{$ENDIF}
*)
  Result.IsDesignMode := IsDesignMode;
  Result.FCaseInsensitive := FCaseInsensitive;
  Result.Repair := FRepair;
end; // CreateCursor


//------------------------------------------------------------------------------
// progress event
//------------------------------------------------------------------------------
procedure TACRTable.DoOnProgress(
                      Progress:   Double;
                      Operation:  TACRTableOperation;
                      var Abort:  Boolean
                     );
begin
 if (Assigned(FOnProgress)) then
  FOnProgress(Self,Progress,Operation,Abort);
end; // DoOnProgress


//------------------------------------------------------------------------------
// get index names
//------------------------------------------------------------------------------
procedure TACRTable.GetIndexNames(List: TStrings);
begin
  IndexDefs.Update;
  IndexDefs.GetItemNames(List);
end; // GetIndexNames


//------------------------------------------------------------------------------
// return index name of the index or '' if not found
//------------------------------------------------------------------------------
function TACRTable.FindIndex(FieldNamesList, AscDescList, CaseSensitivityList: TACRWideStringList): WideString;
begin
  if (FHandle = nil) then
    raise EACRException.Create(11382,ErrorLNilPointer);
  Result := FHandle.FindIndex(FieldNamesList, AscDescList, CaseSensitivityList);
end; // FindIndex


//------------------------------------------------------------------------------
// get table names
//------------------------------------------------------------------------------
procedure TACRTable.GetTableNames(List: TStrings);
begin
 if (DBSession <> nil) then
  DBSession.GetTableNames(FDatabaseName,FInMemory,FTemporary,List);
end; // GetTableNames


//------------------------------------------------------------------------------
// return true if table exists
//------------------------------------------------------------------------------
function TACRTable.GetTableExists: Boolean;
var DatabaseClosed: Boolean;
begin
  if (FHandle <> nil) then
   Result := True
  else
   begin
    Result := False;
    if (Length(FTableName) <= 0) then Exit;
    if (FDatabase = nil) then
      DatabaseClosed := True
    else
      DatabaseClosed := False;
    if (DatabaseClosed) then
      FDatabase := OpenDatabase;
  {
    if (FDatabase = nil) then
      aaWriteToLog('TACRTable.GetTableExists - nil')
    else
      aaWriteToLog('TACRTable.GetTableExists - not nil');
  }
    if (FDatabase <> nil) then
     begin
      Result := FDatabase.TableExists(TableName);
      if (DatabaseClosed) then
        begin
          CloseDatabase(FDatabase);
          FDatabase := nil;
        end;
     end;
   end;
end; // GetTableExists


//------------------------------------------------------------------------------
// CheckMasterRange
//------------------------------------------------------------------------------
procedure TACRTable.CheckMasterRange;
begin
  if (FMasterLink.Active and (FMasterLink.Fields.Count > 0)) then
  begin
    SetLinkRanges(TList(FMasterLink.Fields));
    SetCursorRange;
  end;
end; // CheckMasterRange


//------------------------------------------------------------------------------
// update range
//------------------------------------------------------------------------------
procedure TACRTable.UpdateRange;
begin
  SetLinkRanges(TList(FMasterLink.Fields));
end; // UpdateRange


//------------------------------------------------------------------------------
// Master changed
//------------------------------------------------------------------------------
procedure TACRTable.MasterChanged(Sender: TObject);
begin
  CheckBrowseMode;
  UpdateRange;
  ApplyRange;
end; // MasterChanged


//------------------------------------------------------------------------------
// Master disabled
//------------------------------------------------------------------------------
procedure TACRTable.MasterDisabled(Sender: TObject);
begin
  CancelRange;
end; // MasterDisabled


//------------------------------------------------------------------------------
// Set data source
//------------------------------------------------------------------------------
procedure TACRTable.SetDataSource(Value: TDataSource);
begin
  if (IsLinkedTo(Value)) then
    DatabaseError(ErrorLCircularDataLink, Self);
  FMasterLink.DataSource := Value;
end; // SetDataSource


//------------------------------------------------------------------------------
// get master fields
//------------------------------------------------------------------------------
function TACRTable.GetMasterFields: WideString;
begin
  Result := FMasterLink.FieldNames;
end; // GetMasterFields


//------------------------------------------------------------------------------
// set master fields
//------------------------------------------------------------------------------
procedure TACRTable.SetMasterFields(const Value: WideString);
begin
  FMasterLink.FieldNames := Value;
end; // SetMasterFields


//------------------------------------------------------------------------------
// prepare cursor
//------------------------------------------------------------------------------
procedure TACRTable.PrepareCursor;
begin
  CheckMasterRange;
end; // PrepareCursor


//------------------------------------------------------------------------------
// create and open cursor
//------------------------------------------------------------------------------
function TACRTable.CreateHandle: TACRCursor;
var
   IndexName: WideString;
begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.CreateHandle start. TableName = '+FTableName);
{$ENDIF}
  CheckBlankTableName;
  if (FExternalHandle = nil) then
    Result := GetHandle
  else
    Result := FExternalHandle;
  FHandle := Result;
  if (Result = nil) then
   Exit;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.CreateHandle before IndexDefs.Update. TableName = '+FTableName);
{$ENDIF}
 // commented in v.4.90
//  FIndexDefs.Updated := False;
//  FIndexDefs.Update;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.CreateHandle after IndexDefs.Update. TableName = '+FTableName);
{$ENDIF}
  GetIndexParams(FIndexName, FFieldsIndex, IndexName);
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.CreateHandle after GetIndexParams. TableName = '+FTableName);
{$ENDIF}
  if (IndexName <> '') then
    Result.IndexName := IndexName;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.CreateHandle finish. TableName = '+FTableName);
{$ENDIF}
end;// CreateHandle


//------------------------------------------------------------------------------
// Data Event
//------------------------------------------------------------------------------
{$IFDEF D16H}
procedure TACRTable.DataEvent(Event: TDataEvent; Info: NativeInt);
{$ELSE}
procedure TACRTable.DataEvent(Event: TDataEvent; Info: Longint);
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_TACRTable_DataEvent}
aaWriteToLog('> TACRTable.DataEvent. FTableName = '+FTableName+
#13#10+'Event = '+IntToStr(Integer(Event))+#13#10+'Info = '+IntToStr(Info));
{$ENDIF}
  if ((Event = dePropertyChange) and Assigned(IndexDefs)) then
   begin
{$IFDEF DEBUG_TRACE_TACRTable_DataEvent}
aaWriteToLog('1 TACRTable.DataEvent. FTableName = '+FTableName);
{$ENDIF}
     IndexDefs.Updated := False;
{$IFDEF DEBUG_TRACE_TACRTable_DataEvent}
aaWriteToLog('2 TACRTable.DataEvent. FTableName = '+FTableName);
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRTable_DataEvent}
aaWriteToLog('3 TACRTable.DataEvent. FTableName = '+FTableName);
{$ENDIF}
  inherited DataEvent(Event, Info);
{$IFDEF DEBUG_TRACE_TACRTable_DataEvent}
aaWriteToLog('< TACRTable.DataEvent. FTableName = '+FTableName);
{$ENDIF}
end;// DataEvent


//------------------------------------------------------------------------------
// DefChanged
//------------------------------------------------------------------------------
procedure TACRTable.DefChanged(Sender: TObject);
begin
  StoreDefs := True;
end;// DefChanged


//------------------------------------------------------------------------------
// InitFieldDefs
//------------------------------------------------------------------------------
procedure TACRTable.InitFieldDefs;
var
  TmpCursor: TACRCursor;
begin
// changed in 4.90
  if (FHandle <> nil) then
    InternalInitFieldDefs
  else
   begin
    try
      OpenCursor(True);
    finally
      CloseCursor;
    end;
   end;
(*
    begin
     SetDBFlag(dbfFieldList,True);
     try
       CheckBlankTableName;
       TmpCursor := GetHandle;
       try
         TmpCursor.InternalInitFieldDefs;
         // Fill ACRFieldDefs
         FACRFieldDefs.Assign(TmpCursor.VisibleFieldDefs);
         // Fill FieldDefs
         ConvertACRFieldDefsToFieldDefs(TmpCursor.VisibleFieldDefs, TmpCursor.FConstraintDefs, FieldDefs);
         // Fill AdvFieldDefs
         ConvertACRFieldDefsToAdvFieldDefs(TmpCursor.VisibleFieldDefs,TmpCursor.FieldDefs, TmpCursor.FConstraintDefs, AdvFieldDefs);
         FRestructureFieldDefs.Assign(FAdvFieldDefs);
         FRestructureForeignKeyDefs.Assign(FForeignKeyDefs);
       finally
        TmpCursor.Free;
       end;
     finally
       SetDBFlag(dbfFieldList,False);
     end;
    end;
*)
end;// InitFieldDefs


//------------------------------------------------------------------------------
// destroy cursor
//------------------------------------------------------------------------------
procedure TACRTable.DestroyHandle;
begin
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.DestroyHandle-1');
{$ENDIF}
  inherited DestroyHandle;
{$IFDEF DEBUG_TRACE_DATASET}
 aaWriteToLog('TACRTable.DestroyHandle-2');
{$ENDIF}
end;// DestroyHandle


//------------------------------------------------------------------------------
// get cursor
//------------------------------------------------------------------------------
function TACRTable.GetHandle: TACRCursor;
var i: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('> TACRTable.GetHandle start. TableName = '+FTableName);
aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
for i := 0 to FieldDefs.Count-1 do
 aaWriteToLog('FieldDefs['+IntToStr(i)+'].Name = '+FieldDefs.Items[i].Name);
aaWriteToLog('AdvFieldDefs.Count = '+IntToStr(AdvFieldDefs.Count));
for i := 0 to AdvFieldDefs.Count-1 do
 aaWriteToLog('AdvFieldDefs['+IntToStr(i)+'].Name = '+AdvFieldDefs.Items[i].Name);
aaWriteToLog('Fields.Count = '+IntToStr(Fields.Count));
for i := 0 to Fields.Count-1 do
 aaWriteToLog('Fields['+IntToStr(i)+'].FieldName = '+Fields[i].FieldName);
{$ENDIF}
  FACRFieldDefs.Clear;
  FAdvIndexDefs.Clear;
  FACRConstraintDefs.Clear;
  Result := CreateCursor;
  if (Result = nil) then
   begin
    if (Self.Owner <> nil) then
     if (Self.Owner is TForm) then
      if (fsCreating in TForm(Self.Owner).FormState) then
       Exit;
    raise EACRException.Create(10916,ErrorLCannotCreateCursor);
   end;
  if (Result.IsView) then
   Exit;
  try
     Result.Exclusive := FExclusive;
     Result.ReadOnly := FReadOnly;
     Result.InMemory := FInMemory;
     Result.MemoryTableAllocBy := FMemoryTableAllocBy;
     Result.Temporary := FTemporary;
     // adding fields, specified by editor
     for i := 0 to Fields.Count - 1 do
      if (Fields[i].FieldKind in [fkData]) then
       if (not FindFieldInFieldDefs(FieldDefs,Fields[i].FieldName)) then
        FieldDefs.Add(Fields[i].FieldName,Fields[i].DataType,Fields[i].Size,Fields[i].Required);
       // convert field and index defs
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('1 TACRTable.GetHandle start. TableName = '+FTableName);
aaWriteToLog('FieldDefs.Count = '+IntToStr(FieldDefs.Count));
for i := 0 to FieldDefs.Count-1 do
 aaWriteToLog('FieldDefs['+IntToStr(i)+'].Name = '+FieldDefs.Items[i].Name);
aaWriteToLog('AdvFieldDefs.Count = '+IntToStr(AdvFieldDefs.Count));
for i := 0 to AdvFieldDefs.Count-1 do
 aaWriteToLog('AdvFieldDefs['+IntToStr(i)+'].Name = '+AdvFieldDefs.Items[i].Name);
aaWriteToLog('Fields.Count = '+IntToStr(Fields.Count));
for i := 0 to Fields.Count-1 do
 aaWriteToLog('Fields['+IntToStr(i)+'].FieldName = '+Fields[i].FieldName);
{$ENDIF}
     if (FieldDefs.Count > 0) then
      begin
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('2 TACRTable.GetHandle start. TableName = '+FTableName);
{$ENDIF}
        ConvertFieldDefsToACRFieldDefs(FieldDefs,FACRFieldDefs);
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('3 TACRTable.GetHandle start. TableName = '+FTableName);
{$ENDIF}
      end;
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('4 TACRTable.GetHandle start. TableName = '+FTableName);
aaWriteToLog('FACRFieldDefs.Count = '+IntToStr(FACRFieldDefs.Count));
for i := 0 to FACRFieldDefs.Count-1 do
 aaWriteToLog('FACRFieldDefs['+IntToStr(i)+'].Name = '+FACRFieldDefs.Items[i].Name);
{$ENDIF}
     if (IndexDefs.Count > 0) then
      begin
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('5 TACRTable.GetHandle start. TableName = '+FTableName);
{$ENDIF}
       ConvertIndexDefsToACRIndexDefs(IndexDefs,FAdvIndexDefs,FieldDefs,AdvFieldDefs);
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('6 TACRTable.GetHandle start. TableName = '+FTableName);
{$ENDIF}
       // fixed in v.4.80
       // FRestructureIndexDefs.Assign(IndexDefs);
       IndexDefsAssign(FIndexDefs,FRestructureIndexDefs);
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('7 TACRTable.GetHandle start. TableName = '+FTableName);
aaWriteToLog('FACRFieldDefs.Count = '+IntToStr(FACRFieldDefs.Count));
for i := 0 to FACRFieldDefs.Count-1 do
 aaWriteToLog('FACRFieldDefs['+IntToStr(i)+'].Name = '+FACRFieldDefs.Items[i].Name);
{$ENDIF}
      end;
     Result.OpenTableByFieldDefs(FACRFieldDefs,FAdvIndexDefs, FACRConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('8 TACRTable.GetHandle start. TableName = '+FTableName+#13#10+'Result = '+IntToHex(Integer(Result),8));
{$ENDIF}
     FReadOnly := Result.ReadOnly;
     FComment := Result.Comment;
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('9 TACRTable.GetHandle start. TableName = '+FTableName+#13#10+'Result = '+IntToHex(Integer(Result),8)+'ReadOnly = '+BoolToStr(FReadOnly,True));
{$ENDIF}
   except
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
on e: Exception do
begin
aaWriteToLog('TACRTable.GetHandle exception: '+#13#10+e.Message);
{$ENDIF}
     Result.Free;
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('TACRTable.GetHandle exception result destroyed');
{$ENDIF}
     raise;
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
end;
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRTable_GetHandle}
 aaWriteToLog('TACRTable.GetHandle finish. Result = '+IntToHex(Integer(Result),8));
{$ENDIF}
end;// GetHandle


//------------------------------------------------------------------------------
// updates FieldDefs,AdvFieldDefs,IndexDefs,ForeignKeyDefs,Restructure...Defs
// if table is closed
//------------------------------------------------------------------------------
procedure TACRTable.UpdateTableDefinitions;
var TmpCursor: TACRCursor;
begin
  TmpCursor := GetHandle;
  try
    GetTableDefinitions(TmpCursor);
  finally
    TmpCursor.CloseTable;
    TmpCursor.Free;
  end;
end; // UpdateTableDefinitions


//------------------------------------------------------------------------------
// UpdateIndexDefs
//------------------------------------------------------------------------------
procedure TACRTable.UpdateIndexDefs;
var
  TmpCursor: TACRCursor;
  bIsOpen:   Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('> TACRTable.UpdateIndexDefs');
{$ENDIF}
 if (FHandle = nil) then
  begin
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('1 TACRTable.UpdateIndexDefs');
{$ENDIF}
   SetDBFlag(dbfIndexList, True);
   try
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('2 TACRTable.UpdateIndexDefs');
{$ENDIF}
     UpdateTableDefinitions;
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('3 TACRTable.UpdateIndexDefs');
{$ENDIF}
   finally
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('4 TACRTable.UpdateIndexDefs');
{$ENDIF}
     SetDBFlag(dbfIndexList, False);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('< TACRTable.UpdateIndexDefs');
{$ENDIF}
   end;
  end;
(*
 if (not FIndexDefs.Updated) then
  begin
   SetDBFlag(dbfIndexList, True);
   try
     if (FHandle = nil) then
       TmpCursor := GetHandle
     else
       TmpCursor := FHandle;
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('1 TACRTable.UpdateIndexDefs');
{$ENDIF}
     try
      bIsOpen := TmpCursor.IsOpen;
      if (not FIsProjectionSet) then
       begin
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('2 TACRTable.UpdateIndexDefs');
{$ENDIF}
 // moved from here to TACRTableData.OpenTable in 4.90 -
 // to avoid crash on multi-processor machines
        if (not bIsOpen) then
         TmpCursor.OpenTableByFieldDefs(nil,nil,nil);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('3 TACRTable.UpdateIndexDefs');
{$ENDIF}
        try
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('3.1 TACRTable.UpdateIndexDefs');
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('4 TACRTable.UpdateIndexDefs');
{$ENDIF}

          ConvertACRIndexDefsToIndexDefs(TmpCursor.IndexDefs, FIndexDefs);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('3.1 TACRTable.UpdateIndexDefs');
{$ENDIF}
        finally
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('5 TACRTable.UpdateIndexDefs');
{$ENDIF}
         if (not bIsOpen) then
          TmpCursor.CloseTable;
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('5.1 TACRTable.UpdateIndexDefs');
{$ENDIF}
        end;

(*
          TmpCursor.UpdateTableDefinitions;
       end;
      FieldDefs.Update;
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('6 TACRTable.UpdateIndexDefs');
{$ENDIF}
      ConvertACRIndexDefsToIndexDefs(TmpCursor.IndexDefs, FIndexDefs);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('7 TACRTable.UpdateIndexDefs');
{$ENDIF}
      // FRestructureIndexDefs.Assign(FIndexDefs);
      // fixed in v.4.80
      IndexDefsAssign(FIndexDefs,FRestructureIndexDefs);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('7.1 TACRTable.UpdateIndexDefs');
{$ENDIF}
      FAdvIndexDefs.Assign(TmpCursor.IndexDefs);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('7.2 TACRTable.UpdateIndexDefs');
{$ENDIF}
      FIndexDefs.Updated:=True;

     finally
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('8 TACRTable.UpdateIndexDefs');
{$ENDIF}
      if (not bIsOpen) then
       begin
        TmpCursor.Free;
       end;
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('9 TACRTable.UpdateIndexDefs');
{$ENDIF}
     end;
   finally
     SetDBFlag(dbfIndexList, False);
{$IFDEF DEBUG_TRACE_TACRTable_UpdateIndexDefs}
aaWriteToLog('< TACRTable.UpdateIndexDefs');
{$ENDIF}
   end;
  end;
*)
end;// UpdateIndexDefs


//------------------------------------------------------------------------------
// return field object for the specified field in the current index
//------------------------------------------------------------------------------
function TACRTable.GetIndexField(Index: Integer): TField;
var
  FieldNo: Integer;
begin
  if (Index < 0) or (Index >= FIndexFieldCount) then
    DatabaseError(ErrorLFieldIndexError, Self);
  FieldNo := FIndexFieldMap[Index];
  Result := FieldByNumber(FieldNo);
  if Result = nil then
    DatabaseErrorFmt(ErrorLIndexFieldMissing, [FieldDefs[FieldNo - 1].Name], Self);
end; // GetIndexField


//------------------------------------------------------------------------------
// set index field
//------------------------------------------------------------------------------
procedure TACRTable.SetIndexField(Index: Integer; Value: TField);
begin
  GetIndexField(Index).Assign(Value);
end; // SetIndexField


//------------------------------------------------------------------------------
// Set table name
//------------------------------------------------------------------------------
procedure TACRTable.SetTableName(Value: WideString);
begin
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
aaWriteToLog('> TACRTable.SetTableName. Value = '+Value+', DatabaseName = '+FDatabaseName+', InMemory = '+BoolToStr(FInMemory,True)+', Temporary = '+BoolToStr(FTemporary,True));
try
{$ENDIF}
  if ((csReading in ComponentState) or (csDesigning in ComponentState)) then
   begin
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
  aaWriteToLog('1 TACRTable.SetTableName');
{$ENDIF}
    FTableName := Value;
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
  aaWriteToLog('2 TACRTable.SetTableName');
{$ENDIF}
   end
  else
  if (FTableName <> Value) then
   begin
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
  aaWriteToLog('3 TACRTable.SetTableName, Active = '+BoolToStr(Active,True));
{$ENDIF}
    CheckInactive;
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
  aaWriteToLog('4 TACRTable.SetTableName');
{$ENDIF}
    FTableName := Value;
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
  aaWriteToLog('5 TACRTable.SetTableName');
{$ENDIF}
    DataEvent(dePropertyChange, 0);
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
  aaWriteToLog('6 TACRTable.SetTableName');
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRTable_SetTableName}
 aaWriteToLog('< TACRTable.SetTableName. Value = '+Value+', DatabaseName = '+FDatabaseName+', InMemory = '+BoolToStr(FInMemory,True)+', Temporary = '+BoolToStr(FTemporary,True));
except
 on e: Exception do
  begin
   aaWriteToLog('< TACRTable.SetTableName error: '+#13#10+e.Message);
  end;
end;
{$ENDIF}
end; // SetTableName


//------------------------------------------------------------------------------
// set link ranges
//------------------------------------------------------------------------------
procedure TACRTable.SetLinkRanges(MasterFields: TList);
var
  i: Integer;
  SaveState: TDataSetState;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10299,ErrorLNilPointer);
  SaveState := SetTempState(dsSetKey);
  try
    FKeyBuffer := InitKeyBuffer(FKeyBuffers[kiRangeStart]);
    PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.Modified := True;
    for i := 0 to MasterFields.Count - 1 do
     if (TField(MasterFields[i]).DataType = ftLargeInt) then
      begin
        if (TField(MasterFields[i]).IsNull) then
         GetIndexField(i).Clear
        else
         TLargeIntField(GetIndexField(i)).AsLargeInt := TLargeIntField(MasterFields[i]).AsLargeInt;
      end
     else
      GetIndexField(i).Assign(TField(MasterFields[i]));
    PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.FieldCount := MasterFields.Count;
  finally
    RestoreState(SaveState);
  end;
  Move(FKeyBuffers[kiRangeStart]^, FKeyBuffers[kiRangeEnd]^, FHandle.KeyBufferSize);
end; // SetLinkRanges


//------------------------------------------------------------------------------
// get data source
//------------------------------------------------------------------------------
function TACRTable.GetDataSource: TDataSource;
begin
  Result := FMasterLink.DataSource;
end; // GetDataSource


//------------------------------------------------------------------------------
// on new record
//------------------------------------------------------------------------------
procedure TACRTable.DoOnNewRecord;
var
  I: Integer;
begin
  if (FMasterLink.Active and (FMasterLink.Fields.Count > 0)) then
    for I := 0 to FMasterLink.Fields.Count - 1 do
      IndexFields[I] := TField(FMasterLink.Fields[I]);
  inherited DoOnNewRecord;
end; // DoOnNewRecord


//------------------------------------------------------------------------------
// get index field count
//------------------------------------------------------------------------------
function TACRTable.GetIndexFieldCount: Integer;
begin
  Result := FIndexFieldCount;
end; // GetIndexFieldCount


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRTable.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsTable := True;
  FTemporary := False;
  FMasterLink := TMasterDataLink.Create(Self);
  FMasterLink.OnMasterChange := MasterChanged;
  FMasterLink.OnMasterDisable := MasterDisabled;
  FMemoryTableAllocBy := ACRDefaultMemoryTableAllocBy;
  {$IFDEF SQLMEMTABLE}
  FTableName := GetTemporaryName('Table');
  {$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// destory
//------------------------------------------------------------------------------
destructor TACRTable.Destroy;
begin
  inherited Destroy;
  FMasterLink.Free;
end; // Destroy


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TACRTable.CreateTable;
var i:          Integer;
    TempCursor: TACRCursor;
begin
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('> TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8)
+#13#10+'TableName = '+FTableName
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
);
{$ENDIF}
  CheckInactive;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('1 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  CheckBlankTableName;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('2 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
  SetDBFlag(dbfTable, True);
  try
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('3 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   if (FDatabase <> nil) then
    if (FDatabase.FReadOnly) then
     DatabaseError(ErrorLDatabaseFileIsInReadOnlyMode);
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('4 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   TempCursor := CreateCursor;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('5 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8)+', TempCursor = '+IntToHex(Integer(TempCursor),8));
{$ENDIF}
   if (TempCursor = nil) then
    raise EACRException.Create(10919,ErrorLCannotCreateCursor);
   try
    TempCursor.FCreateTableStarted := True;
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Comment := FComment;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.MemoryTableAllocBy := Self.MemoryTableAllocBy;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('6 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    // adding fields, specified by editor
    for i := 0 to Fields.Count - 1 do
     if (Fields[i].FieldKind in [fkData]) then
      if (not FindFieldInFieldDefs(FieldDefs,Fields[i].FieldName)) then
        FieldDefs.Add(Fields[i].FieldName,Fields[i].DataType,Fields[i].Size,Fields[i].Required);

{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('7 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8)+', AdvFieldDefs.Count = '+IntToStr(AdvFieldDefs.Count));
{$ENDIF}
    // Synchronize FieldDefs and AdvFieldDefs
    if (AdvFieldDefs.Count > 0) then
      begin
        // Copy AdvFieldDefs to FieldDefs
        ConvertAdvFieldDefsToFieldDefs(AdvFieldDefs, FieldDefs);
      end
    else
     begin
        // Copy FieldDefs to AdvFieldDefs or
        ConvertFieldDefsToAdvFieldDefs(FieldDefs, AdvFieldDefs);
     end;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('8 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8)+', IndexDefs.Count = '+IntToStr(IndexDefs.Count));
{$ENDIF}
    if (IndexDefs.Count > 0) then
     begin
      FAdvIndexDefs.Clear;
      ConvertIndexDefsToACRIndexDefs(IndexDefs,FAdvIndexDefs, FieldDefs, AdvFieldDefs);
     end;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('9 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}

    // convert field and index defs
    ConvertAdvFieldDefsToACRFieldDefs(AdvFieldDefs, FACRFieldDefs,
                                      FAdvIndexDefs, FACRConstraintDefs, FTemporary);
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('10 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    ACRConvertForeignKeyDefsToConstraintDefs(FForeignKeyDefs, FACRConstraintDefs);
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('11 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8)+', TempCursor = '+IntToHex(Integer(TempCursor),8));
{$ENDIF}
    TempCursor.CreateTable(FACRFieldDefs,FAdvIndexDefs,FACRConstraintDefs);
    if (TempCursor.Temporary) then
     FTableName := TempCursor.TableName;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('12 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   finally
    TempCursor.Free;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('13 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   end;
  finally
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('14 TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   SetDBFlag(dbfTable, False);
  end;
{$IFDEF DEBUG_TRACE_TACRTable_CreateTable}
aaWriteToLog('< TACRTable.CreateTable, Self = '+IntToHex(Integer(Self),8)
+#13#10+'TableName = '+FTableName
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
);
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TACRTable.DeleteTable(Cascade: Boolean);
var
  TempCursor:   TACRCursor;
begin
  CheckInactive;
  CheckBlankTableName;
  SetDBFlag(dbfTable, True);
  try
    if (FDatabase <> nil) then
     if (FDatabase.FReadOnly) then
      DatabaseError(ErrorLDatabaseFileIsInReadOnlyMode);
   TempCursor := CreateCursor(False);
   if (TempCursor = nil) then
    raise EACRException.Create(10920,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.DeleteTable(Cascade);
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // DeleteTable


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TACRTable.EmptyTable;
var
  TempCursor:   TACRCursor;
begin
  CheckInactive;
  SetDBFlag(dbfTable, True);
  try
    if (FDatabase <> nil) then
     if (FDatabase.FReadOnly) then
      DatabaseError(ErrorLDatabaseFileIsInReadOnlyMode);
   TempCursor := CreateCursor(False);
   if (TempCursor = nil) then
    raise EACRException.Create(10921,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.EmptyTable;
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // EmptyTable


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TACRTable.RenameTable(NewTableName: WideString);
var
  TempCursor:   TACRCursor;
begin
  CheckInactive;
  if (FDatabase <> nil) then
   if (FDatabase.FReadOnly) then
    DatabaseError(ErrorLDatabaseFileIsInReadOnlyMode);
  SetDBFlag(dbfTable, True);
  try
   if (FDatabase <> nil) then
    if (FDatabase.FReadOnly) then
     DatabaseError(ErrorLDatabaseFileIsInReadOnlyMode);
   TempCursor := CreateCursor(False);
   if (TempCursor = nil) then
    raise EACRException.Create(10922,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.RenameTable(NewTableName);
    FTableName := NewTableName;
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // RenameTable


//------------------------------------------------------------------------------
// LoadTable
//------------------------------------------------------------------------------
procedure TACRTable.LoadTableFromFile(
                        FileName:             AnsiString;
                        FileNameUnicode:      WideString
                       );
var
  Stream: TACRStream;
begin
  if (FileName <> '') then
   Stream := TACRFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite)
  else
   Stream := TACRFileStream.Create(FileNameUnicode, fmOpenRead or fmShareDenyWrite);
  try
    LoadTableFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadTableFromFile


//------------------------------------------------------------------------------
// SaveTable
//------------------------------------------------------------------------------
procedure TACRTable.SaveTableToFile(
                        FileName:             AnsiString;
                        CompressionAlgorithm: TCompressionAlgorithm;
                        CompressionMode:      Byte;
                        BlockSize:            Integer;
                        FileNameUnicode:      WideString
                      );
var
  Stream: TACRStream;
begin
  if (FileName <> '') then
   Stream := TACRFileStream.Create(FileName, fmCreate)
  else
   Stream := TACRFileStream.Create(FileNameUnicode, fmCreate);
  try
    SaveTableToStream(Stream,CompressionAlgorithm,CompressionMode,BlockSize);
  finally
    Stream.Free;
  end;
end; // SaveTableToFile


//------------------------------------------------------------------------------
// LoadTable
//------------------------------------------------------------------------------
procedure TACRTable.LoadTableFromStream(
                        Stream:               TStream
                       );
var
  TempCursor:   TACRCursor;
begin
  CheckInactive;
  SetDBFlag(dbfTable, True);
  try
   TempCursor := CreateCursor;
   if (TempCursor = nil) then
    raise EACRException.Create(10923,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.LoadTableFromStream(Stream);
    FTableName := TempCursor.FTableName;
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // LoadTableFromStream


//------------------------------------------------------------------------------
// SaveTable
//------------------------------------------------------------------------------
procedure TACRTable.SaveTableToStream(
                        Stream: TStream;
                        CompressionAlgorithm: TCompressionAlgorithm;
                        CompressionMode:      Byte;
                        BlockSize:            Integer
                      );
var
  TempCursor:   TACRCursor;
  CompAlg:      TACRCompressionAlgorithm;
begin
  CheckInactive;
  SetDBFlag(dbfTable, True);
  try
   TempCursor := CreateCursor;
   if (TempCursor = nil) then
    raise EACRException.Create(10924,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    CompAlg := ConvertCompressionAlgorithmToACRCompressionAlgorithm(CompressionAlgorithm);
    TempCursor.SaveTableToStream(Stream,CompAlg,CompressionMode,BlockSize);
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // SaveTableToStream


//------------------------------------------------------------------------------
// LoadTable
//------------------------------------------------------------------------------
procedure TACRTable.LoadAllTablesFromFile(
                        FileName:             AnsiString;
                        FileNameUnicode:      WideString
                       );
var
  Stream: TACRStream;
begin
  if (FileName <> '') then
    Stream := TACRFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite)
  else
    Stream := TACRFileStream.Create(FileNameUnicode, fmOpenRead or fmShareDenyWrite);
  try
    LoadAllTablesFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadTableFromFile


//------------------------------------------------------------------------------
// LoadTable
//------------------------------------------------------------------------------
procedure TACRTable.LoadAllTablesFromStream(
                        Stream:               TStream
                       );
begin
 CheckInactive;
 FDatabase := OpenDatabase;
 if (FDatabase = nil) then
  raise EACRException.Create(11341,ErrorLNilPointer);
 try
  FDatabase.LoadAllTablesFromStream(Stream);
 finally
  CloseDatabase(FDatabase);
  FDatabase := nil;
 end;
end; // LoadTableFromStream


//------------------------------------------------------------------------------
// SaveTables to file
//------------------------------------------------------------------------------
procedure TACRTable.SaveTablesToFile(
                        TableList:            TACRWideStringList;
                        FileName:             AnsiString;
                        CompressionAlgorithm: TCompressionAlgorithm;
                        CompressionMode:      Byte;
                        BlockSize:            Integer;
                        FileNameUnicode:      WideString
                      );
var
  Stream: TACRStream;
begin
  if (FileName <> '') then
    Stream := TACRFileStream.Create(FileName, fmCreate)
  else
    Stream := TACRFileStream.Create(FileNameUnicode, fmCreate);
  try
    SaveTablesToStream(TableList,Stream,CompressionAlgorithm,CompressionMode,BlockSize);
  finally
    Stream.Free;
  end;
end; // SaveTablesToFile


//------------------------------------------------------------------------------
// save  tables List to file
//------------------------------------------------------------------------------
procedure TACRTable.SaveTablesToStream(
                    TableList:            TACRWideStringList;
                    Stream:               TStream;
                    CompressionAlgorithm: TCompressionAlgorithm;
                    CompressionMode:      Byte;
                    BlockSize:            Integer
                  );
begin
 CheckInactive;
 FDatabase := OpenDatabase;
 if (FDatabase = nil) then
  raise EACRException.Create(11608,ErrorLNilPointer);
 try
  FDatabase.SaveTablesToStream(TableList,Stream,CompressionAlgorithm,CompressionMode,BlockSize);
 finally
  CloseDatabase(FDatabase);
  FDatabase := nil;
 end;
end; // SaveTablesToStream


//------------------------------------------------------------------------------
// SaveTable
//------------------------------------------------------------------------------
procedure TACRTable.SaveAllTablesToFile(
                        FileName:             AnsiString;
                        CompressionAlgorithm: TCompressionAlgorithm;
                        CompressionMode:      Byte;
                        BlockSize:            Integer;
                        FileNameUnicode:      WideString
                      );
var
  Stream: TACRStream;
begin
  if (FileName <> '') then
    Stream := TACRFileStream.Create(FileName, fmCreate)
  else
    Stream := TACRFileStream.Create(FileNameUnicode, fmCreate);
  try
    SaveAllTablesToStream(Stream,CompressionAlgorithm,CompressionMode,BlockSize);
  finally
    Stream.Free;
  end;
end; // SaveTableToFile


//------------------------------------------------------------------------------
// SaveTable
//------------------------------------------------------------------------------
procedure TACRTable.SaveAllTablesToStream(
                        Stream: TStream;
                        CompressionAlgorithm: TCompressionAlgorithm;
                        CompressionMode:      Byte;
                        BlockSize:            Integer
                      );
begin
 CheckInactive;
 FDatabase := OpenDatabase;
 if (FDatabase = nil) then
  raise EACRException.Create(11340,ErrorLNilPointer);
 try
  FDatabase.SaveAllTablesToStream(Stream,CompressionAlgorithm,CompressionMode,BlockSize);
 finally
  CloseDatabase(FDatabase);
  FDatabase := nil;
 end;
end; // SaveTableToStream


//------------------------------------------------------------------------------
// import table
//------------------------------------------------------------------------------
function TACRTable.ImportTable(
                      SourceTable: TDataset;
                      var Log:     AnsiString
                      ): Boolean;
var
    i:               Integer;
    FixSize:         Integer; //fix
    s,SourceLog:     AnsiString;
begin
  Result := False;
  SourceLog := Log;
  CheckInactive;
  IndexDefs.Clear;
  AdvIndexDefs.Clear;
  FieldDefs.Clear;
  AdvFieldDefs.Clear;
  ForeignKeyDefs.Clear;
  if (SourceTable is TACRDataset) then
   begin
    AssignDefinitions(TACRDataset(SourceTable));
   end
  else
   FieldDefs.Assign(SourceTable.FieldDefs);
  for i := 0 to FieldDefs.Count - 1 do
   begin
     // to import floating point values without bugs
     if (FieldDefs[i].DataType = ftBCD) then
      FieldDefs[i].DataType := ftFloat;
    {$IFNDEF SQLMEMTABLE}
     if (FieldDefs[i].DataType = ftString) then
      begin
       FixSize := FieldDefs[i].Size; //fix
      FieldDefs[i].DataType := ftFixedChar;
       FieldDefs[i].Size := FixSize; //fix
      end;
    {$ENDIF}
    {$IFNDEF D12H}
    // changed in v.4.80
    if (FieldDefs[i].DataType = ftWideString) then
     FieldDefs[i].Size := FieldDefs[i].Size * 2;
    {$ENDIF}
    {$IFDEF D5H}
    if (FieldDefs[i].DataType = ftOraBlob) then              // Added by Doug
     FieldDefs[i].DataType := ftBlob;                        // Added by Doug
    if (FieldDefs[i].DataType = ftOraClob) then              // Added by Doug
     FieldDefs[i].DataType := ftMemo;                        // Added by Doug
    {$ENDIF}
   end;
  try
    Self.CreateTable;
  except
   on e: Exception do
    begin
     Log := Log + Format(ErrorLImportTableCannotCreateTable,[e.Message]);
     Exit;
    end;
  end;
  Self.Open;
  if (FHandle = nil) then
    raise EACRException.Create(10259,ErrorLNilPointer);
  s := CopyDatasets(SourceTable,Self,False,tbopImport);
  if (s <> '') then
    Log := Log + Format(ErrorLImportTableCannotCopyData,[s]);

  Result := (Log = SourceLog);
  if (FTemporary) then
   FHandle.CreateTableStarted := True;
  Self.Close;
end; // ImportTable


//------------------------------------------------------------------------------
// import table
//------------------------------------------------------------------------------
function TACRTable.ImportTable(SourceTable: TDataset): Boolean;
var s: AnsiString;
begin
 Result := ImportTable(SourceTable,s);
end; // ImportTable


//------------------------------------------------------------------------------
// export table
//------------------------------------------------------------------------------
function TACRTable.ExportTable(
                      DestinationTable:   TDataset;
                      CreateTablePointer: TProcedure;
                      var Log:            AnsiString
                   ): Boolean;
var
    s,SourceLog:     AnsiString;
    OldActive:       Boolean;
    Bookmark:        TBookmark;
begin
  Result := False;
  SourceLog := Log;
  OldActive := Self.Active;
  DestinationTable.Close;
  if (OldActive) then
   Bookmark := Self.GetBookmark
  else
   Bookmark := nil;
  Self.Close;
  Self.Open;
  if (FHandle = nil) then
    raise EACRException.Create(10262,ErrorLNilPointer);
  if (DestinationTable is TACRDataset) then
   TACRDataset(DestinationTable).AdvFieldDefs.Assign(Self.AdvFieldDefs)
  else
   DestinationTable.FieldDefs.Assign(Self.FieldDefs);
  try
    CreateTablePointer;
  except
   on e: Exception do
    begin
     Log := Log + Format(ErrorLExportTableCannotCreateTable,[e.Message]);
     Exit;
    end;
  end;
  try
    DestinationTable.Open;
  except
   on e: Exception do
    begin
     Log := Log + Format(ErrorLExportTableCannotOpenTable,[e.Message]);
     Exit;
    end;
  end;

  s := CopyDatasets(Self,DestinationTable,True,tbopExport);
  if (s <> '') then
    Log := Log + Format(ErrorLExportTableCannotCopyData,[s]);
  Result := (Log = SourceLog);
  // restore table position
  if (OldActive) then
   begin
    try
      Self.GotoBookmark(Bookmark);
    finally
      Self.FreeBookmark(Bookmark);
    end;
   end
  else
   Self.Close;
end; // ExportTable


//------------------------------------------------------------------------------
// export table
//------------------------------------------------------------------------------
function TACRTable.ExportTable(
                      DestinationTable:   TDataset;
                      CreateTablePointer: TProcedure
                   ): Boolean;
var
  s: AnsiString;
begin
 Result := ExportTable(DestinationTable,CreateTablePointer, s);
end; // ExportTable


//------------------------------------------------------------------------------
// export table to SQL
//------------------------------------------------------------------------------
function TACRTable.ExportTableToSQL(
                            ExportStructure:      Boolean;
                            AddDropTableCommand:  Boolean;
                            ExportIndexes:        Boolean;
                            AddDropIndexCommand:  Boolean;
                            ExportData:           Boolean;
                            ExportBLOBFields:     Boolean;
                            UseBracketsForNames:  Boolean;
                            ExportForeignKeys:    Boolean
                         ): WideString;
var
    OldActive:       Boolean;
begin
  OldActive := Self.Active;
  if (not OldActive) then
   Open
  else
   begin
    InitFieldDefs;
    FieldDefs.Update;
    IndexDefs.Update;
   end;
  try
    Result := FHandle.ExportTableToSQL(ExportStructure,AddDropTableCommand,
                ExportIndexes,AddDropIndexCommand,
                ExportData,ExportBLOBFields,
                UseBracketsForNames, ExportForeignKeys
                );
  finally
    if (not OldActive) then
     Close;
  end;
end; // ExportTableToSQL


//------------------------------------------------------------------------------
// executes batch move to this table and return number of records moved
//------------------------------------------------------------------------------
function TACRTable.BatchMove(ASource: TACRDataSet; AMode: TACRBatchMode): Int64;
begin
  with TACRBatchMove.Create(nil) do
  try
    Destination := Self;
    Source := ASource;
    Mode := AMode;
    OnProgress := Self.OnProgress;
    Execute;
    Result := MovedCount;
  finally
    Free;
  end;
end; // BatchMove


//------------------------------------------------------------------------------
// restructure table
//------------------------------------------------------------------------------
function TACRTable.RestructureTable(
                      var Log:            AnsiString
                   ): Boolean;
begin
 Result := InternalRepairOrRestructureTable(False,Log,nil);
end; // RestructureTable


//------------------------------------------------------------------------------
// restructure table
//------------------------------------------------------------------------------
function TACRTable.RestructureTable: Boolean;
var s: AnsiString;
begin
 Result := RestructureTable(s);
end; // RestructureTable


//------------------------------------------------------------------------------
// return true if table specified by TableName is system (not exists and system name)
//------------------------------------------------------------------------------
function TACRTable.IsSystemTable: Boolean;
begin
  Result := False;
  if (not Active) then
   if (not Exists) then
    Result := (WideUpperCase(FTableName) = 'TABLES');
end; // IsSystemTable


//------------------------------------------------------------------------------
// repair (high level) or restructure table
//------------------------------------------------------------------------------
function TACRTable.InternalRepairOrRestructureTable(
                            Repair:       Boolean;
                            var Log:      AnsiString;
                            NewDatabase:  TACRDatabase = nil;
                            FKDefs:       TACRForeignKeyDefs = nil
                            ): Boolean;
var TempTable:           TACRTable;
    SourceLog,s:         AnsiString;
    b:                   Boolean;
    OperationName:       AnsiString;

 procedure DeleteTempTable;
 begin
  try
    if (TempTable.Active) then
      TempTable.Close;
  except
  end;
  try
    TempTable.DeleteTable(True);
  except
  end;
 end;

 procedure DoClose;
 begin
  try
    if (Active) then
     Close;
  except
  end;
 end;

 procedure RecreateForeignKeyActions;
 var i:        Integer;
     table:    TACRTable;
     FKAction: TACRConstraintDefForeignKeyAction;
     FK,FK1:   TACRForeignKeyDef;
 begin
   table := TACRTable.Create(nil);
   FK := TACRForeignKeyDef.Create;
   try
     table.DatabaseName := TempTable.DatabaseName;
     table.InMemory := Temptable.InMemory;
     table.FExclusive := True;
     for i := 0 to FACRConstraintDefs.Count-1 do
      if (FACRConstraintDefs.Items[i].ConstraintType = ctFKAction) then
       begin
        FKAction := TACRConstraintDefForeignKeyAction(FACRConstraintDefs.Items[i]);
        FK.Name := FKAction.ReferencedFKName;
        table.TableName := FKAction.ReferencedTableName;
        table.Open;
        FK1 := table.ForeignKeyDefs.Find(FK.Name);
        if (FK1 = nil) then
         raise EACRException.Create(11581,ErrorLForeignKeyDefNotFound,[FK.Name]);
        FK.Columns := FK1.Columns;
        table.Close;
        FK.ReferencedTableName := TempTable.TableName;
        FK.MatchType := TACRForeignKeyMatchType(Integer(FKAction.MatchType));
        FK.DeleteAction := TACRForeignKeyAction(Integer(FKAction.DeleteAction));
        FK.UpdateAction := TACRForeignKeyAction(Integer(FKAction.UpdateAction));
        FK.Name := ACRConstraintFKTemporaryNamePrefix+FKAction.ReferencedFKName;
        table.AddForeignKey(FK);
       end;
   finally
     FK.Free;
     table.Free;
   end;
 end;

 procedure CreateStructureForRepair;
 begin
  OperationName := 'repair';
  Open;
  TempTable.AdvFieldDefs.Assign(FAdvFieldDefs);
  // fixed in v.4.80
  //  TempTable.IndexDefs.Assign(FIndexDefs);
  TempTable.IndexDefsAssign(FIndexDefs,TempTable.IndexDefs);
  if (NewDatabase = nil) then
   begin
    TempTable.ForeignKeyDefs.Assign(FForeignKeyDefs);
    ACRFixForeignKeysSelfReferences(FTableName,TempTable.TableName,TempTable.ForeignKeyDefs);
   end
  else
   begin
    if (FKDefs <> nil) then
     FKDefs.Assign(FForeignKeyDefs);
    TempTable.ForeignKeyDefs.Clear;
   end;
  Close;
 end;

 procedure CreateStructureForRestructure;
 begin
  OperationName := 'restructure';
  TempTable.AdvFieldDefs.Assign(FRestructureFieldDefs);
  // fixed in v.4.80
  //  TempTable.IndexDefs.Assign(FIndexDefs);
  TempTable.IndexDefsAssign(FRestructureIndexDefs,TempTable.IndexDefs);
  TempTable.ForeignKeyDefs.Assign(FRestructureForeignKeyDefs);
  ACRFixForeignKeysSelfReferences(FTableName,TempTable.TableName,TempTable.ForeignKeyDefs);
 end;

begin
  Result := False;
  CheckInactive;
  b := FExclusive;
  if (not b) then
   FExclusive := True;
  SourceLog := Log;
  FRepair := Repair;
  TempTable := TACRTable.Create(nil);
  try
    TempTable.FInMemory := Self.FInMemory;
    TempTable.FTemporary := Self.FTemporary;
    if (NewDatabase = nil) then
     TempTable.DatabaseName := Self.FDatabaseName
    else
     TempTable.DatabaseName := NewDatabase.DatabaseName;
    TempTable.SessionName := SessionName;
    if (NewDatabase = nil) then
     repeat
      TempTable.FTableName := GetTemporaryName('TEMP_TABLE_'+FTableName+'_');
     until (not TempTable.Exists)
    else
     TempTable.FTableName := FTableName;
    TempTable.Comment := FComment; 
    TempTable.FieldDefs.Clear;
    TempTable.AdvIndexDefs.Clear;
    try
      if (Repair) then
       CreateStructureForRepair
      else
       CreateStructureForRestructure;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCreateStructure,[OperationName,FTableName,e.Message]);
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCreateStructure,[OperationName,FTableName,ErrorLUnknownError]);
        Exit;
      end;
    end;
    // create temporary table with new settings
    try
     TempTable.CreateTable;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCreateTable,[OperationName,FTableName,TempTable.TableName,e.Message]);
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCreateTable,[OperationName,FTableName,TempTable.TableName,ErrorLUnknownError]);
        Exit;
      end;
    end;
    try
     TempTable.Open;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotOpenTempTable,[OperationName,FTableName,TempTable.TableName,e.Message]);
        DeleteTempTable;
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotOpenTempTable,[OperationName,FTableName,TempTable.TableName,ErrorLUnknownError]);
        DeleteTempTable;
        Exit;
      end;
    end;
    // open current table
    try
     Open;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotOpenTable,[OperationName,FTableName,e.Message]);
        DoClose;
        DeleteTempTable;
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotOpenTable,[OperationName,FTableName,ErrorLUnknownError]);
        DoClose;
        DeleteTempTable;
        Exit;
      end;
    end;
    // copy records from source table to temporary table
    try
      if (Log = SourceLog) then
       begin
        if (Repair) then
         s := CopyDatasets(Self,TempTable,True,tbopRepair)
        else
         s := CopyDatasets(Self,TempTable,True,tbopRestructure);
        if (s <> '') then
         Log := Log + Format(ErrorLRestructureTableCannotCopyData,[OperationName,FTableName,s]);
       end;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCopyRecords,[OperationName,FTableName,e.Message]);
        DoClose;
        DeleteTempTable;
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCopyRecords,[OperationName,FTableName,ErrorLUnknownError]);
        DoClose;
        DeleteTempTable;
        Exit;
      end;
    end;
    if (Log <> SourceLog) then
     begin
      DoClose;
      DeleteTempTable;
      Exit;
     end;
    try
      TempTable.Close;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCloseTempTable,[OperationName,FTableName,e.Message]);
        DoClose;
        DeleteTempTable;
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotCloseTempTable,[OperationName,FTableName,ErrorLUnknownError]);
        DoClose;
        DeleteTempTable;
        Exit;
      end;
    end;
    try
     if (NewDatabase = nil) then
      RecreateForeignKeyActions;
    except
     on e: Exception do
      begin
        Log := Log + Format(ErrorLRestructureTableCannotRecreateForeignKeys,[OperationName,FTableName,e.Message]);
        DoClose;
        DeleteTempTable;
        Exit;
      end
     else
      begin
        Log := Log + Format(ErrorLRestructureTableCannotRecreateForeignKeys,[OperationName,FTableName,ErrorLUnknownError]);
        DoClose;
        DeleteTempTable;
        Exit;
      end;
    end;
    DoClose;
    if (Log = SourceLog) or (Repair) then
     begin
      try
       if (NewDatabase = nil) then
        DeleteTable(True);
      except
       on e: Exception do
        begin
          Log := Log + Format(ErrorLRestructureTableCannotDeleteTable,[OperationName,FTableName,e.Message]);
          DoClose;
          DeleteTempTable;
          Exit;
        end
       else
        begin
          Log := Log + Format(ErrorLRestructureTableCannotDeleteTable,[OperationName,FTableName,ErrorLUnknownError]);
          DoClose;
          DeleteTempTable;
          Exit;
        end;
      end;
      try
       if (NewDatabase = nil) then
        TempTable.RenameTable(Self.FTableName);
      except
       on e: Exception do
        begin
          Log := Log + Format(ErrorLRestructureTableCannotRenameTable,[OperationName,FTableName,TempTable.TableName,e.Message]);
          Exit;
        end
       else
        begin
          Log := Log + Format(ErrorLRestructureTableCannotRenameTable,[OperationName,FTableName,TempTable.TableName,ErrorLUnknownError]);
          Exit;
        end;
      end;
     end
    else
     DeleteTempTable;
    if (Repair) then
     Result := True
    else
     Result := (Log = SourceLog);
  finally
    FRepair := False;
    TempTable.Free;
    FExclusive := b;
    DoClose;
  end;
end; // InternalRepairOrRestructureTable


//------------------------------------------------------------------------------
// repair table
//------------------------------------------------------------------------------
function TACRTable.RepairTable(UseLowLevelTableAccess: Boolean = False): Boolean;
var s: AnsiString;
begin
  Result := RepairTable(s,UseLowLevelTableAccess,nil,nil);
end; // RepairTable


//------------------------------------------------------------------------------
// repair table
//------------------------------------------------------------------------------
function TACRTable.RepairTable(
                        var Log:                AnsiString;
                        UseLowLevelTableAccess: Boolean = False;
                        NewDatabase:            TACRDatabase = nil;
                        FKDefs:                 TACRForeignKeyDefs = nil
                               ): Boolean;
var
  TempCursor:       TACRCursor;
  ConstraintDefs:   TACRConstraintDefs;
begin
  if (not UseLowLevelTableAccess) then
   Result := InternalRepairOrRestructureTable(True,Log,NewDatabase,FKDefs)
  else
   begin
    CheckInactive;
    CheckBlankTableName;
    SetDBFlag(dbfTable, True);
    try
     TempCursor := CreateCursor;
     if (TempCursor = nil) then
      raise EACRException.Create(11166,ErrorLCannotCreateCursor);
     try
      TempCursor.Session := FDatabase.Handle;
      TempCursor.TableName := FTableName;
      TempCursor.Temporary := FTemporary;
      TempCursor.InMemory := FInMemory;
      TempCursor.ReadOnly := False;
      TempCursor.Exclusive := True;
      if (FKDefs <> nil) then
       ConstraintDefs := TACRConstraintDefs.Create
      else
       ConstraintDefs := nil;
      try
        if (NewDatabase <> nil) then
         Result := TempCursor.RepairTable(Log,NewDatabase.Handle,ConstraintDefs)
        else
         Result := TempCursor.RepairTable(Log,nil,nil);
        if (ConstraintDefs <> nil) then
         if (ConstraintDefs.Count > 0) then
          ConvertConstraintDefsToForeignKeyDefs(ConstraintDefs,FKDefs,True);
      finally
       if (ConstraintDefs <> nil) then
         ConstraintDefs.Free;
      end;
     finally
      TempCursor.Free;
     end;
    finally
     SetDBFlag(dbfTable, False);
    end;
   end;
end; // RepairTable


//------------------------------------------------------------------------------
// Rename Field by Name
//------------------------------------------------------------------------------
procedure TACRTable.RenameField(FieldName, NewFieldName: WideString);
var
  TempCursor:   TACRCursor;
begin
  CheckInactive;
  SetDBFlag(dbfTable, True);
  try
   TempCursor := CreateCursor;
   if (TempCursor = nil) then
    raise EACRException.Create(10959,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.RenameField(FieldName,NewFieldName);
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end;//RenameField


//------------------------------------------------------------------------------
// add foreign key to existing table
//------------------------------------------------------------------------------
procedure TACRTable.AddForeignKey(ForeignKeyDef: TACRForeignKeyDef);
var
  TempCursor:    TACRCursor;
  ConstraintDef: TACRConstraintDefForeignKey;
begin
  CheckInactive;
  SetDBFlag(dbfTable, True);
  try
   if (not Self.Exists) then
    DatabaseError(Format(ErrorLTableDoesNotExist,[FTableName]),Self);
   TempCursor := CreateCursor;
   if (TempCursor = nil) then
    raise EACRException.Create(11580,ErrorLCannotCreateCursor);
   ConstraintDef := TACRConstraintDefForeignKey.Create;
   try
    ACRConvertForeignKeyDefToConstraintDef(ForeignKeyDef,ConstraintDef);
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.OpenTableByFieldDefs(nil,nil,nil);
    TempCursor.InternalInitFieldDefs;
    TempCursor.AddForeignKey(ConstraintDef);
   finally
    TempCursor.Free;
    ConstraintDef.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // AddForeignKey


//------------------------------------------------------------------------------
// DeleteConstraint
//------------------------------------------------------------------------------
procedure TACRTable.DeleteConstraint(Name: WideString; Cascade: Boolean = False);
var
  TempCursor:   TACRCursor;
begin
  CheckInactive;
  SetDBFlag(dbfTable, True);
  try
   if (not Self.Exists) then
    DatabaseError(Format(ErrorLTableDoesNotExist,[FTableName]),Self);
   TempCursor := CreateCursor;
   if (TempCursor = nil) then
    raise EACRException.Create(11579,ErrorLCannotCreateCursor);
   try
    TempCursor.Session := FDatabase.Handle;
    TempCursor.TableName := FTableName;
    TempCursor.Temporary := FTemporary;
    TempCursor.InMemory := FInMemory;
    TempCursor.ReadOnly := False;
    TempCursor.Exclusive := True;
    TempCursor.OpenTableByFieldDefs(nil,nil,nil);
    TempCursor.DeleteConstraint(Name,Cascade,False);
   finally
    TempCursor.Free;
   end;
  finally
   SetDBFlag(dbfTable, False);
  end;
end; // DeleteConstraint


//------------------------------------------------------------------------------
// create new index
//------------------------------------------------------------------------------
procedure TACRTable.AddIndex(
              const Name,
              Fields: WideString;
              Options: TIndexOptions;
              const DescFields: WideString = '';
              const CaseInsFields: WideString = ''
                   );
var
  TmpCursor:   TACRCursor;
  ACRIndexDef: TACRIndexDef;
  bExclusive:  Boolean;
  bOpened:     Boolean;
begin
  FieldDefs.Update;
  SetDBFlag(dbfIndexList,True);
  bExclusive := FExclusive;
  try
    if (FHandle = nil) then
     begin
      bOpened := False;
      FExclusive := True;
      TmpCursor := GetHandle;
     end
    else
      begin
       bOpened := True;
       CheckBrowseMode;
       CursorPosChanged;
       TmpCursor := FHandle;
       if (not FInMemory) and (not FTemporary) then
        if (not TmpCursor.Exclusive) then
         raise EACRException.Create(11617,ErrorLTableIsNotOpenedExclusively,[FTableName]);
     end;
    ACRIndexDef := TACRIndexDef.Create;
    try
     if (Name = '') then
      raise EACRException.Create(20046, ErrorAInvalidIndexName, ['']);
     if (Fields = '') then
      raise EACRException.Create(20047, ErrorACannotFindIndexField, ['']);
     FillACRIndexDef(ACRIndexDef, Name, Fields, Options, DescFields, CaseInsFields, FieldDefs, AdvFieldDefs);
     TmpCursor.AddIndex(ACRIndexDef);
    finally
       ACRIndexDef.Free;
       if (FHandle = nil) then
        TmpCursor.Free;
    end;
// commented in v.4.90
//    FIndexDefs.Updated := False;
  finally
    SetDBFlag(dbfIndexList,False);
    FExclusive := bExclusive;
  end;
end;// AddIndex


//------------------------------------------------------------------------------
// DeleteIndex
//------------------------------------------------------------------------------
procedure TACRTable.DeleteIndex(const Name: WideString);
var
  TmpCursor:   TACRCursor;
  bExclusive:  Boolean;
  bOpened:     Boolean;
begin
  FieldDefs.Update;
  SetDBFlag(dbfIndexList,True);
  bExclusive := FExclusive;
  try
    if (FHandle = nil) then
     begin
      bOpened := False;
      FExclusive := True;
      TmpCursor := GetHandle;
     end
    else
      begin
       bOpened := True;
       CheckBrowseMode;
       CursorPosChanged;
       TmpCursor := FHandle;
       if (not FInMemory) and (not FTemporary) then
        if (not TmpCursor.Exclusive) then
         raise EACRException.Create(11618,ErrorLTableIsNotOpenedExclusively,[FTableName]);
     end;
    try
     TmpCursor.DeleteIndex(Name);
     // added in v.4.90
    finally
     if (FHandle = nil) then
      TmpCursor.Free;
    end;
// commented in v.4.90
//    FIndexDefs.Updated := False;
  finally
    SetDBFlag(dbfIndexList,False);
    FExclusive := bExclusive;
  end;
end;// DeleteIndex


//------------------------------------------------------------------------------
// DeleteAllIndexes
//------------------------------------------------------------------------------
procedure TACRTable.DeleteAllIndexes;
var
  TmpCursor:   TACRCursor;
  bExclusive : Boolean;
begin
  FieldDefs.Update;
  SetDBFlag(dbfIndexList,True);
  bExclusive := FExclusive;
  try
    if (FHandle = nil) then
     begin
      FExclusive := True;
      TmpCursor := GetHandle;
     end
    else
      begin
       CheckBrowseMode;
       CursorPosChanged;
       TmpCursor := FHandle;
       if (not FInMemory) and (not FTemporary) then
        if (not TmpCursor.Exclusive) then
         raise EACRException.Create(11619,ErrorLTableIsNotOpenedExclusively,[FTableName]);
     end;
    try
      TmpCursor.DeleteAllIndexes;
    finally
     if (FHandle = nil) then
      TmpCursor.Free;
    end;
    FIndexDefs.Updated := False;
  finally
    SetDBFlag(dbfIndexList,False);
    FExclusive := bExclusive;
  end;
end;// DeleteAllIndexes


//------------------------------------------------------------------------------
// check set key mode
//------------------------------------------------------------------------------
procedure TACRTable.CheckSetKeyMode;
begin
  if (State <> dsSetKey) then
    DatabaseError(ErrorLDatasetIsNotInEditOrInsertMode, Self);
end; // CheckSetKeyMode


//------------------------------------------------------------------------------
// get key buffer
//------------------------------------------------------------------------------
function TACRTable.GetKeyBuffer(KeyIndex: TACRKeyIndex): TACRRecordBuffer;
begin
  Result := FKeyBuffers[KeyIndex];
end; // GetKeyBuffer


//------------------------------------------------------------------------------
// return true if key is exclusive
//------------------------------------------------------------------------------
function TACRTable.GetKeyExclusive: Boolean;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10282,ErrorLNilPointer);
  CheckSetKeyMode;
  Result := PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.Exclusive;
end; // GetKeyExclusive


//------------------------------------------------------------------------------
// return key field count
//------------------------------------------------------------------------------
function TACRTable.GetKeyFieldCount: Integer;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10284,ErrorLNilPointer);
  CheckSetKeyMode;
  Result := PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.FieldCount;
end; // GetKeyFieldCount


//------------------------------------------------------------------------------
// set key exclusive
//------------------------------------------------------------------------------
procedure TACRTable.SetKeyExclusive(Value: Boolean);
begin
  if (FHandle = nil) then
    raise EACRException.Create(10283,ErrorLNilPointer);
  CheckSetKeyMode;
  PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.Exclusive := Value;
end; // SetKeyExclusive


//------------------------------------------------------------------------------
// set key field count
//------------------------------------------------------------------------------
procedure TACRTable.SetKeyFieldCount(Value: Integer);
begin
  if (FHandle = nil) then
    raise EACRException.Create(10285,ErrorLNilPointer);
  CheckSetKeyMode;
  PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.FieldCount := Value;
end; // SetKeyFieldCount


//------------------------------------------------------------------------------
// set key buffer
//------------------------------------------------------------------------------
procedure TACRTable.SetKeyBuffer(KeyIndex: TACRKeyIndex; Clear: Boolean);
begin
  if (FHandle = nil) then
    raise EACRException.Create(10286,ErrorLNilPointer);
  CheckBrowseMode;
  FKeyBuffer := FKeyBuffers[KeyIndex];
  Move(FKeyBuffer^, FKeyBuffers[kiSave]^, FHandle.KeyBufferSize);
  if (Clear) then
    InitKeyBuffer(FKeyBuffer);
  SetState(dsSetKey);
  SetModified(PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.Modified);
  DataEvent(deDataSetChange, 0);
end; // SetKeyBuffer


//------------------------------------------------------------------------------
// set key fields
//------------------------------------------------------------------------------
procedure TACRTable.SetKeyFields(KeyIndex: TACRKeyIndex; const Values: array of const);
var
    i:          Integer;
    SaveState:  TDataSetState;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10289,ErrorLNilPointer);
  if (not IsIndexApplied) then
    DatabaseError(ErrorLNoFieldIndexes, Self);
  SaveState := SetTempState(dsSetKey);
  try
    FKeyBuffer := InitKeyBuffer(FKeyBuffers[KeyIndex]);
    for i := 0 to High(Values) do
      GetIndexField(i).AssignValue(Values[i]);
    PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.FieldCount := High(Values) + 1;
    PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.Modified := Modified;
  finally
    RestoreState(SaveState);
  end;
end; // SetKeyFields


//------------------------------------------------------------------------------
// post key buffer
//------------------------------------------------------------------------------
procedure TACRTable.PostKeyBuffer(Commit: Boolean);
begin
  if (FHandle = nil) then
    raise EACRException.Create(10288,ErrorLNilPointer);
  DataEvent(deCheckBrowseMode, 0);
  if (Commit) then
    PACRKeyBuffer(FKeyBuffer + FHandle.KeyOffset)^.Modified := Modified
  else
    Move(FKeyBuffers[kiSave]^, FKeyBuffer^, FHandle.KeyBufferSize);
  SetState(dsBrowse);
  DataEvent(deDataSetChange, 0);
end; // PostKeyBuffer


//------------------------------------------------------------------------------
// find key
//------------------------------------------------------------------------------
function TACRTable.FindKey(const KeyValues: array of const): Boolean;
begin
  CheckBrowseMode;
  SetKeyFields(kiLookup, KeyValues);
  Result := GotoKey;
end; // FindKey


//------------------------------------------------------------------------------
// find nearest
//------------------------------------------------------------------------------
procedure TACRTable.FindNearest(const KeyValues: array of const);
begin
  CheckBrowseMode;
  SetKeyFields(kiLookup, KeyValues);
  GotoNearest;
end; // FindNearest


//------------------------------------------------------------------------------
// goto key
//------------------------------------------------------------------------------
function TACRTable.GotoKey: Boolean;
var
  SearchCondition:    TACRSearchCondition;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10290,ErrorLNilPointer);
  CheckBrowseMode;
  DoBeforeScroll;
  CursorPosChanged;
  SearchCondition := scEqual;
  FHandle.KeyBuffer := GetKeyBuffer(kiLookup);
  FHandle.KeyFieldCount := PACRKeyBuffer(FHandle.KeyBuffer + FHandle.KeyOffset)^.FieldCount;
  if (FHandle.KeyFieldCount = 0) then
   FHandle.KeyFieldCount := FIndexFieldCount;
  Result := FHandle.FindKey(SearchCondition);
  if (Result) then
   begin
    Resync([rmExact, rmCenter]);
    DoAfterScroll;
   end;
end; // GotoKey


//------------------------------------------------------------------------------
// goto nearest
//------------------------------------------------------------------------------
procedure TACRTable.GotoNearest;
var
  SearchCondition: TACRSearchCondition;
  Result:          Boolean;
begin
  if (FHandle = nil) then
    raise EACRException.Create(10291,ErrorLNilPointer);
  CheckBrowseMode;
  CursorPosChanged;
  FHandle.KeyBuffer := GetKeyBuffer(kiLookup);
  if (PACRKeyBuffer(FHandle.KeyBuffer + FHandle.KeyOffset)^.Exclusive) then
    SearchCondition := scGreater
  else
    SearchCondition := scGreaterEqual;
  FHandle.KeyFieldCount := PACRKeyBuffer(FHandle.KeyBuffer + FHandle.KeyOffset)^.FieldCount;
  if (FHandle.KeyFieldCount = 0) then
    FHandle.KeyFieldCount := FIndexFieldCount;
  Result := FHandle.FindKey(SearchCondition);
  // if nearest record was not find go to last record
  if (not Result) then
   Last;
  Resync([rmCenter]);
end; // GotoNearest


//------------------------------------------------------------------------------
// edit key
//------------------------------------------------------------------------------
procedure TACRTable.EditKey;
begin
  SetKeyBuffer(kiLookup, False);
end; // EditKey


//------------------------------------------------------------------------------
// set key
//------------------------------------------------------------------------------
procedure TACRTable.SetKey;
begin
  SetKeyBuffer(kiLookup, True);
end; // SetKey


//------------------------------------------------------------------------------
// set range
//------------------------------------------------------------------------------
function TACRTable.SetCursorRange: Boolean;
var StartBuffer, EndBuffer:       TACRRecordBuffer;
    StartExclusive, EndExclusive: Boolean;
    StartKeyFieldCount,
    EndKeyFieldCount:             Integer;
begin
  Result := False;
  if (FHandle = nil) then
    raise EACRException.Create(10296,ErrorLNilPointer);
  if (not (
            BuffersEqual(FKeyBuffers[kiRangeStart], FKeyBuffers[kiCurRangeStart],
              FHandle.KeyBufferSize)
           and
            BuffersEqual(FKeyBuffers[kiRangeEnd], FKeyBuffers[kiCurRangeEnd],
              FHandle.KeyBufferSize))) then
  begin
    StartBuffer := FKeyBuffers[kiRangeStart];
    StartKeyFieldCount := PACRKeyBuffer(StartBuffer + FHandle.KeyOffset)^.FieldCount;
    if (StartKeyFieldCount = 0) then
     StartKeyFieldCount := FIndexFieldCount;
    StartExclusive := PACRKeyBuffer(StartBuffer + FHandle.KeyOffset)^.Exclusive;
    EndBuffer := FKeyBuffers[kiRangeEnd];
    EndKeyFieldCount := PACRKeyBuffer(EndBuffer + FHandle.KeyOffset)^.FieldCount;
    if (EndKeyFieldCount = 0) then
     EndKeyFieldCount := FIndexFieldCount;
    EndExclusive := PACRKeyBuffer(EndBuffer + FHandle.KeyOffset)^.Exclusive;
    FHandle.ApplyRange(StartBuffer,EndBuffer,
                       StartKeyFieldCount,EndKeyFieldCount,
                       StartExclusive, EndExclusive);
    Move(FKeyBuffers[kiRangeStart]^, FKeyBuffers[kiCurRangeStart]^,
      FHandle.KeyBufferSize);
    Move(FKeyBuffers[kiRangeEnd]^, FKeyBuffers[kiCurRangeEnd]^,
      FHandle.KeyBufferSize);
    Result := True;
  end;
end; // SetCursorRange


//------------------------------------------------------------------------------
// apply range
//------------------------------------------------------------------------------
procedure TACRTable.ApplyRange;
begin
  CheckBrowseMode;
  if (SetCursorRange) then
    First;
end; // ApplyRange


//------------------------------------------------------------------------------
// cancel range
//------------------------------------------------------------------------------
procedure TACRTable.CancelRange;
begin
  CheckBrowseMode;
  UpdateCursorPos;
  if (ResetCursorRange) then
    Resync([]);
end; // CancelRange


//------------------------------------------------------------------------------
// edit range start
//------------------------------------------------------------------------------
procedure TACRTable.EditRangeStart;
begin
  SetKeyBuffer(kiRangeStart, False);
end; // EditRangeStart


//------------------------------------------------------------------------------
// edit range end
//------------------------------------------------------------------------------
procedure TACRTable.EditRangeEnd;
begin
  SetKeyBuffer(kiRangeEnd, False);
end; // EditRangeEnd


//------------------------------------------------------------------------------
// set range
//------------------------------------------------------------------------------
procedure TACRTable.SetRange(const StartValues, EndValues: array of const);
begin
  CheckBrowseMode;
  SetKeyFields(kiRangeStart, StartValues);
  SetKeyFields(kiRangeEnd, EndValues);
  ApplyRange;
end; // SetRange


//------------------------------------------------------------------------------
// set range start
//------------------------------------------------------------------------------
procedure TACRTable.SetRangeStart;
begin
  SetKeyBuffer(kiRangeStart, True);
end; // SetRangeStart


//------------------------------------------------------------------------------
// set range end
//------------------------------------------------------------------------------
procedure TACRTable.SetRangeEnd;
begin
  SetKeyBuffer(kiRangeEnd, True);
end; // SetRangeEnd


//------------------------------------------------------------------------------
// post
//------------------------------------------------------------------------------
procedure TACRTable.Post;
begin
  inherited Post;
  if (State = dsSetKey) then
    PostKeyBuffer(True);
end; // Post


//------------------------------------------------------------------------------
// LastAutoincValue
//------------------------------------------------------------------------------
function TACRTable.LastAutoincValue(FieldIndex: Integer): Int64;
begin
 if (FHandle <> nil) then
  Result := FHandle.LastAutoincValue(FieldIndex)
 else
  Result := -1;
end;//LastAutoincValue


//------------------------------------------------------------------------------
// LastAutoincValue
//------------------------------------------------------------------------------
function TACRTable.LastAutoincValue(FieldName: WideString): Int64;
begin
  Result := LastAutoincValue(Fields.IndexOf(Fields.FieldByName(FieldName)));
end;//LastAutoincValue


//------------------------------------------------------------------------------
// set LastAutoincValue for Field (FieldIndex started from 0)
//------------------------------------------------------------------------------
procedure TACRTable.SetLastAutoincValue(Value: Int64; FieldIndex: Integer);
begin
 if (FHandle <> nil) then
  FHandle.SetLastAutoincValue(Value,FieldIndex)
 else
  CheckActive;
end; // SetLastAutoincValue


//------------------------------------------------------------------------------
// set LastAutoincValue for Field
//------------------------------------------------------------------------------
procedure TACRTable.SetLastAutoincValue(Value: Int64; FieldName: WideString);
begin
  SetLastAutoincValue(Value,Fields.IndexOf(Fields.FieldByName(FieldName)));
end; // SetLastAutoincValue


//------------------------------------------------------------------------------
// return current table state if exists
//------------------------------------------------------------------------------
function TACRTable.GetTableState: TACRTableState;
begin
  if (Active) then
   Result := FHandle.GetTableState
  else
   begin
    if (FDatabase <> nil) then
     Result := FDatabase.GetTableState(FTableName)
    else
     begin
      FDatabase := OpenDatabase;
      try
        if (FDatabase <> nil) then
         Result := FDatabase.GetTableState(FTableName);
      finally
        CloseDatabase(FDatabase);
      end;
     end;
   end;
end; //


////////////////////////////////////////////////////////////////////////////////
//
// TACRQuery
//
////////////////////////////////////////////////////////////////////////////////

{$IFDEF D6H}
//------------------------------------------------------------------------------
// execute
//------------------------------------------------------------------------------
procedure TACRQuery.PSExecute;
begin
  ExecSQL;
end; // PSExecute


//------------------------------------------------------------------------------
// get default order
//------------------------------------------------------------------------------
function TACRQuery.PSGetDefaultOrder: TIndexDef;
begin
  Result := inherited PSGetDefaultOrder;
  if not Assigned(Result) then
    Result := GetIndexForOrderBy(SQL.Text, Self);
end; // PSGetDefaultOrder


//------------------------------------------------------------------------------
// get params
//------------------------------------------------------------------------------
function TACRQuery.PSGetParams: TParams;
begin
  Result := Params;
end; // PSGetParams


//------------------------------------------------------------------------------
// get table name
//------------------------------------------------------------------------------
function TACRQuery.PSGetTableName: String;
begin
  Result := GetTableNameFromSQL(SQL.Text);
end; // PSGetTableName


//------------------------------------------------------------------------------
// set command text
//------------------------------------------------------------------------------
procedure TACRQuery.PSSetCommandText(const CommandText: String);
begin
  if CommandText <> '' then
    SQL.Text := CommandText;
end; // PSSetCommandText


//------------------------------------------------------------------------------
// set params
//------------------------------------------------------------------------------
procedure TACRQuery.PSSetParams(AParams: TParams);
begin
  if AParams.Count <> 0 then
    Params.Assign(AParams);
  Close;
end; // PSSetParams


{$ENDIF}


//------------------------------------------------------------------------------
// GetStatementHandle
//------------------------------------------------------------------------------
procedure TACRQuery.GetStatementHandle(SQLText: PWideChar);
begin
  FStmtHandle := nil;
  if (FDatabase = nil) then
   begin
    {$IFDEF LOCAL_VERSION}
      FStmtHandle := TACRLocalSQLProcessor.Create(Self,FCaseInsensitive);
    {$ENDIF}
   end // local database
  else
  if (FDatabase.FLocalDatabase or FInMemory) then
   begin
    {$IFDEF LOCAL_VERSION}
      FStmtHandle := TACRLocalSQLProcessor.Create(Self, FCaseInsensitive);
    {$ENDIF}
   end // local database
  else
   begin
    {$IFDEF CLIENT_VERSION}
      FStmtHandle := TACRClientSQLProcessor.Create(Self, FDatabase.Handle, FCaseInsensitive);
    {$ENDIF}
   end; // remote database
  if (FStmtHandle = nil) then
   DatabaseError(ErrorLSQLProcessorIsSwitchedOff);
  try
    FStmtHandle.RequestLive := FRequestLive;
    FStmtHandle.InMemory := FInMemory;
    FStmtHandle.PrepareStatement(SQLText);
  except
    FStmtHandle.Free;
    FStmtHandle := nil;
    raise;
  end;
end;// GetStatementHandle


//------------------------------------------------------------------------------
// FreeStatement
//------------------------------------------------------------------------------
procedure TACRQuery.FreeStatement;
begin
  if (FStmtHandle <> nil) then
    begin
      FStmtHandle.Free;
      FStmtHandle := nil;
    end;
end;// FreeStatement


//------------------------------------------------------------------------------
// CreateCursor
//------------------------------------------------------------------------------
function TACRQuery.CreateCursor(GenHandle: Boolean): TACRCursor;
var Abort: Boolean;
begin
  if (SQL.Count > 0) then
    begin
      if (IsBeforeExecuteSQLAssigned) then
       begin
        FDatabase.DoBeforeExecuteSQL(Self,Abort);
        if (Abort) then
         begin
          Result := nil;
          DatabaseError(ErrorLExecuteSQLBlockedByDatabaseEvent,Self);
          Exit;
         end;
       end;
      FExecSQL := not GenHandle;
      try
        SetPrepared(True);
      finally
        FExecSQL := False;
      end;
      if FDataLink.DataSource <> nil then
        SetParamsFromCursor;
      Result := GetQueryCursor(GenHandle);
      if (Result <> nil) then
       Result.IsDesignMode := IsDesignMode;
      if (IsAfterExecuteSQLAssigned) then
       if (FDatabase <> nil) then 
        FDatabase.DoAfterExecuteSQL(Self);
    end
  else
    begin
      raise EACRException.Create(20034, ErrorAEmptySQLStatement);
      Result := nil;
    end;
  FCheckRowsAffected := (Result = nil);
end;// CreateCursor


//------------------------------------------------------------------------------
// GetQueryCursor
//------------------------------------------------------------------------------
function TACRQuery.GetQueryCursor(GenHandle: Boolean): TACRCursor;
var
  i,l:    Integer;
  Param:  TACRSQLParam;
{$IFDEF DEBUG_TRACE_SQL}
sqlTime: Cardinal;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_SQL}
aaWriteToLog('> TACRQuery.GetQueryCursor, SQL:'+#13#10+FSQL.Text);
sqlTime := aaGetTickCount;
try
{$ENDIF}
  Result := nil;
    // Set Params
  if FParams.Count > 0 then
   begin
    StmtHandle.SQLParams.Clear;
    for i:=0 to FParams.Count-1 do
     begin
      Param := StmtHandle.SQLParams.AddCreated;
      Param.Name := FParams[i].Name;
      if (FParams[i].IsNull) then
       Param.SetNull
      else
       begin
        Param.SetNull(AdvancedFieldTypeToBaseFieldType(
                                FieldTypeToACRAdvFieldType(FParams[i].DataType)));
// 4.40 added memo, fmtmemo
        case FParams[i].DataType of
          ftBlob,ftGraphic,ftMemo,ftFmtMemo:
            begin
              Param.DataType := bftBlob;
              l := Length(Params[i].AsBlob);
              if (l > 0) then
                Param.SetData(PAnsiChar(Params[i].AsBlob), l, bftBlob);
            end;
// 4.80 added ftWideString
           ftWideString:
            Param.AsWideString := WideString(FParams[i].Value);
{$IFDEF D12H}
// modified in v.4.80
           ftString:
            Param.AsString := AnsiString(FParams[i].Value);
//           ftString:
//            Param.AsWideString := FParams[i].Value;
{$ENDIF}
         else
          Param.AsVariant := FParams[i].Value;
        end;
      end;
     end;
    end;
{$IFDEF DEBUG_TRACE_FULL_SQL}
aaWriteToLog('TACRQuery.GetQueryCursor - Params set. GenHandle = '+BoolToStr(GenHandle,True));
{$ENDIF}
   if (GenHandle) then
    begin
      Result := StmtHandle.OpenQuery;
{$IFDEF DEBUG_TRACE_SQL}
sqlTime := ACRGetTickCountDiff(aaGetTickCount,sqlTime);
if (Result = nil) then
aaWriteToLog('< TACRQuery.GetQueryCursor, SQL error - Result = nil'+#13#10+'sqlTime = '+#9+IntTostr(sqlTime))
else
aaWriteToLog('< TACRQuery.GetQueryCursor, SQL OK, RecordCount = '+IntToStr(Result.RecordCount)+#13#10+'sqlTime = '+#9+IntTostr(sqlTime));
if (FDatabase <> nil) then
aaWriteToLog(#13#10+'SessionID = '+IntToStr(TACRBaseSession(FDatabase.Handle).SessionID));
{$ENDIF}
// commented in v.4.70
//      FExternalHandle := Result;
      FReadOnly := StmtHandle.ReadOnly;
{$IFDEF DEBUG_TRACE_FULL_SQL}
aaWriteToLog('TACRQuery.GetQueryCursor - FReadOnly = '+BoolToStr(FReadOnly,True));
{$ENDIF}
      if (Result = nil) then
       FIsProjectionSet := False
      else
       FIsProjectionSet := Result.FIsProjectionSet;
    end
   else
    begin
     StmtHandle.ExecuteQuery;
{$IFDEF DEBUG_TRACE_SQL}
sqlTime := ACRGetTickCountDiff(aaGetTickCount,sqlTime);
aaWriteToLog('< TACRQuery.GetQueryCursor, SQL OK, RowsAffected = '+IntToStr(StmtHandle.RowsAffected)+#13#10+'sqlTime = '+#9+IntTostr(sqlTime));
{$ENDIF}
    end;
{$IFDEF DEBUG_TRACE_SQL}
except
 on e: Exception do
  begin
sqlTime := ACRGetTickCountDiff(aaGetTickCount,sqlTime);
aaWriteToLog('< TACRQuery.GetQueryCursor, SQL Error:'+#13#10+e.Message+#13#10+'sqlTime = '+#9+IntTostr(sqlTime));
raise;
  end
 else
  begin
sqlTime := ACRGetTickCountDiff(aaGetTickCount,sqlTime);
aaWriteToLog('< TACRQuery.GetQueryCursor, SQL Error: - UNKNOWN ERROR'+#13#10+'sqlTime = '+#9+IntTostr(sqlTime));
raise;
  end;
end;
{$ENDIF}
end;// GetQueryCursor


//------------------------------------------------------------------------------
// GetRowsAffected
//------------------------------------------------------------------------------
function TACRQuery.GetRowsAffected: Integer;
begin
  if Prepared then
    Result := StmtHandle.RowsAffected
  else
    Result := FRowsAffected;
end;//GetRowsAffected


//------------------------------------------------------------------------------
// QueryChanged
//------------------------------------------------------------------------------
procedure TACRQuery.QueryChanged(Sender: TObject);
var
  List:             TParams;
  ParametrizedText: WideString;
begin
  if not (csReading in ComponentState) then
  begin
    Disconnect;
//    StrDispose(SQLBinary);
//    SQLBinary := nil;
    if (not FDoNotCallFixParam) then
     FixParamsInQuery;
    if ParamCheck or (csDesigning in ComponentState) then
    begin
      List := TParams.Create(Self);
      try
        ParametrizedText := List.ParseSQL(SQL.Text, True);
        List.AssignValues(FParams);
        FParams.Clear;
        FParams.Assign(List);
      finally
        List.Free;
      end;
     end;
    FText := SQL.Text;
    DataEvent(dePropertyChange, 0);
   end
  else
   begin
    FixParamsInQuery;
    ParametrizedText := FParams.ParseSQL(SQL.Text, False);
    FText := SQL.Text;
   end;
end;// QueryChanged


//------------------------------------------------------------------------------
// GetDataSource
//------------------------------------------------------------------------------
function TACRQuery.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;// GetDataSource


//------------------------------------------------------------------------------
// SetDataSource
//------------------------------------------------------------------------------
procedure TACRQuery.SetDataSource(Value: TDataSource);
begin
  if IsLinkedTo(Value) then
   DatabaseError(ErrorACircularDataLink, Self);
  FDataLink.DataSource := Value;
end;// SetDataSource


//------------------------------------------------------------------------------
// fix MS params ? - replace to :Param0, :Param1, ...
//------------------------------------------------------------------------------
procedure TACRQuery.FixParamsInQuery;
var s:    WideString;
    i,l:  Integer;
    bFix: Boolean;
begin
 s := SQL.Text;
 try
   bFix := False;
   l := Length(s);
   for i := 1 to l do
    if (s[i] = '?') then
     begin
      bFix := True;
      break;
     end;
   if (bFix) then
    begin
     FDoNotCallFixParam := True;
     try
      SQL.Text := GetFixedParamsInQuery(s);
     finally
      FDoNotCallFixParam := False;
     end;
    end;
 finally
   ACRClearString(s,True);
 end;
end; // FixParamsInQuery


//------------------------------------------------------------------------------
// SetQuery
//------------------------------------------------------------------------------
procedure TACRQuery.SetSQL(Value: TACRWideStringList);
begin
  if (SQL.Text <> Value.Text) then
   begin
    Disconnect;
    SQL.Assign(Value);
   end;
end;// SetQuery


//------------------------------------------------------------------------------
// GetParamsCount
//------------------------------------------------------------------------------
function TACRQuery.GetParamsCount: Word;
begin
  Result := FParams.Count;
end;// GetParamsCount


//------------------------------------------------------------------------------
// RefreshParams
//------------------------------------------------------------------------------
procedure TACRQuery.RefreshParams;
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


//------------------------------------------------------------------------------
// SetParamsList
//------------------------------------------------------------------------------
procedure TACRQuery.SetParamsList(Value: TParams);
begin
  FParams.AssignValues(Value);
end;// SetParamsList


//------------------------------------------------------------------------------
// SetParamsFromCursor
//------------------------------------------------------------------------------
procedure TACRQuery.SetParamsFromCursor;
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
       if not FParams[I].Bound then
          begin
           FParams[I].AssignField(DataSet.FieldByName(FParams[I].Name));
           FParams[I].Bound := False;
          end;
    end;
  end;
end;// SetParamsFromCursor


//------------------------------------------------------------------------------
// ParamByName
//------------------------------------------------------------------------------
function TACRQuery.ParamByName(const Value: String): TParam;
begin
  Result:=FParams.ParamByName(Value);
end;// ParamByName


//------------------------------------------------------------------------------
// Prepare
//------------------------------------------------------------------------------
procedure TACRQuery.Prepare;
begin
  SetDBFlag(dbfPrepared, True);
  SetPrepared(True);
end;// Prepare


//------------------------------------------------------------------------------
// UnPrepare
//------------------------------------------------------------------------------
procedure TACRQuery.UnPrepare;
begin
  SetPrepared(False);
  SetDBFlag(dbfPrepared, False);
end;// UnPrepare


//------------------------------------------------------------------------------
// PrepareSQL
//------------------------------------------------------------------------------
procedure TACRQuery.PrepareSQL(Value: PWideChar);
begin
  GetStatementHandle(Value);
end;// PrepareSQL


//------------------------------------------------------------------------------
// SetPrepared
//------------------------------------------------------------------------------
procedure TACRQuery.SetPrepared(Value: Boolean);
begin
// modified in v.4.70 - no need in this stuff,
/// done itnernally in DestroyHandle/SetPrepared(False)
(*
  if FHandle <> nil then
   if (not Value) then
     begin
       {$IFDEF CLIENT_VERSION}
       if (FHandle.IsClientCursor) then
        FHandle.Free;
       {$ENDIF}
       FHandle := nil;
       FExternalHandle := nil;
     end
   else
*)
  if ((Value) and (FHandle <> nil)) then
    raise EACRException.Create(30141, ErorrGDataSetOpen);

  if Value <> Prepared then
   begin
    if Value then
     begin
      FRowsAffected := -1;
      FCheckRowsAffected := True;
      if (Length(SQL.Text) > 0) then
        PrepareSQL(PWideChar(SQL.Text))
      else
        raise EACRException.Create(30142, ErorrGEmptySQLStatement);
     end
    else
     begin
      if FCheckRowsAffected then
        FRowsAffected := RowsAffected;
      {$IFDEF CLIENT_VERSION}
// modified in v.4.90
      if (FHandle <> nil) then
       if (FStmtHandle is TACRClientSQLProcessor) then
//        if (FParams.Count <= 0) then
// if not live query result or not parametrized - free it, as SQLProcessor cannot do it
        if ((FHandle.IsTemporaryTable) or (FParams.Count <= 0)) then
         begin
          // close client cursor, as it has no parameters
          FHandle.Free;
          FHandle := nil;
         end;
      {$ENDIF}
      FreeStatement;
      FExternalHandle := nil;
      FHandle := nil;
     end;
    FPrepared := Value;
  end;
end;// SetPrepared


//------------------------------------------------------------------------------
// SetPrepare
//------------------------------------------------------------------------------
procedure TACRQuery.SetPrepare(Value: Boolean);
  begin
  if Value then
   Prepare
  else
   UnPrepare;
end;// SetPrepare


//------------------------------------------------------------------------------
// ReadParamData
//------------------------------------------------------------------------------
procedure TACRQuery.ReadParamData(Reader: TReader);
begin
  Reader.ReadValue;
  Reader.ReadCollection(FParams);
end;// ReadParamData


//------------------------------------------------------------------------------
// WriteParamData
//------------------------------------------------------------------------------
procedure TACRQuery.WriteParamData(Writer: TWriter);
begin
  Writer.WriteCollection(Params);
end;// WriteParamData


//------------------------------------------------------------------------------
// define properties - for setting params
//------------------------------------------------------------------------------
procedure TACRQuery.DefineProperties(Filer: TFiler);

  function WriteData: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not FParams.IsEqual(TACRQuery(Filer.Ancestor).FParams)
    else
      Result := FParams.Count > 0;
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('ParamData', ReadParamData, WriteParamData, WriteData);
end; // DefineProperties


//------------------------------------------------------------------------------
// create handle
//------------------------------------------------------------------------------
function TACRQuery.CreateHandle: TACRCursor;
begin
  if (FExternalHandle = nil) then
    Result := CreateCursor(True)
  else
    Result := FExternalHandle;
end;// CreateHandle


//------------------------------------------------------------------------------
// destroy handle
//------------------------------------------------------------------------------
procedure TACRQuery.DestroyHandle;
begin
 // fixed in v.5.80
 if (FHandle <> nil) then
  if (FHandle.FSettingProjection) then
   Exit;
 if (FParams.Count <= 0) then
  FreeStatement;
{$IFDEF CLIENT_VERSION}
 // close temporary table with data received from server
 if (FStmtHandle is TACRClientSQLProcessor) then
  begin
   if (not TACRClientSQLProcessor(FStmtHandle).Live) then
     FHandle.Free;
  end;
{$ENDIF}
 FHandle := nil;
end; // DestroyHandle


//------------------------------------------------------------------------------
// Disconnect
//------------------------------------------------------------------------------
procedure TACRQuery.Disconnect;
begin
  Close;
  UnPrepare;
end;// Disconnect


//------------------------------------------------------------------------------
// SetDBFlag
//------------------------------------------------------------------------------
procedure TACRQuery.SetDBFlag(Flag: Integer; Value: Boolean);
begin
  if Value then
    inherited SetDBFlag(Flag,Value)
  else
    begin
      if ((DBFlags - [Flag]) = []) then
         SetPrepared(False);
      inherited SetDBFlag(Flag, Value);
    end;
end;// SetDBFlag


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsTable := False;
  FSQL := TACRWideStringList.Create;
  FSQL.OnChange := QueryChanged;
  FParams := TParams.Create(Self);
  FDataLink := TACRQueryDataLink.Create(Self);
  RequestLive := False;
  ParamCheck := True;
  FRowsAffected := -1;
  FDoNotCallFixParam := False;
  {$IFDEF TRIAL_VERSION}
  if (IsDesignMode) then
   acrtrshnm;
  {$ENDIF} 
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRQuery.Destroy;
begin
  Destroying;
  Disconnect;
  SQL.Free;
  FParams.Free;
  FDataLink.Free;
  ACRClearString(FText);
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// ExecSQL
//------------------------------------------------------------------------------
procedure TACRQuery.ExecSQL;
begin
  CheckInActive;
  SetDBFlag(dbfExecSQL, True);
  try
    CreateCursor(False);
  finally
    SetDBFlag(dbfExecSQL, False);
  end;
end;// ExecSQL


{$IFDEF D21H}
procedure TACRQuery.GetDetailLinkFields(MasterFields, DetailFields: TList<TField>);


  function AddFieldToList(
                          const FieldName:  WideString;
                          DataSet:          TDataSet;
                          List:             TList<TField>
                         ): Boolean;
  var
    Field: TField;
  begin
    Field := DataSet.FindField(FieldName);
    if (Field <> nil) then
      List.Add(Field);
    Result := (Field <> nil);
  end; // AddFieldToList


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
// GetDetailLinkFields
//------------------------------------------------------------------------------
procedure TACRQuery.GetDetailLinkFields(MasterFields, DetailFields: TList);


  function AddFieldToList(
                          const FieldName:  WideString;
                          DataSet:          TDataSet;
                          List:             TList
                         ): Boolean;
  var
    Field: TField;
  begin
    Field := DataSet.FindField(FieldName);
    if (Field <> nil) then
      List.Add(Field);
    Result := (Field <> nil);
  end; // AddFieldToList


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



////////////////////////////////////////////////////////////////////////////////
//
// TACRLockParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRLockParamsEditor.Create;
begin
  inherited;
  FRetryCount := ACRDefaultRetryCount;
  FDelay := ACRDefaultDelay;
end;//Create


//------------------------------------------------------------------------------
// GetLockParams
//------------------------------------------------------------------------------
function TACRLockParamsEditor.GetLockParams: TACRLockParams;
begin
  Result.RetryCount := FRetryCount;
  Result.Delay := FDelay;
end;// GetLockParams


//------------------------------------------------------------------------------
// ڥtLockParams
//------------------------------------------------------------------------------
procedure TACRLockParamsEditor.SetLockParams(Params: TACRLockParams);
begin
  FRetryCount := Params.RetryCount;
  FDelay := Params.Delay;
end; // SetLockParams


//------------------------------------------------------------------------------
// SetRetryCount
//------------------------------------------------------------------------------
procedure TACRLockParamsEditor.SetRetryCount(Value: Integer);
begin
  if (Value >= ACRMinRetryCount) then
    FRetryCount := Value;
end; // SetRetryCount


//------------------------------------------------------------------------------
// SetDelay
//------------------------------------------------------------------------------
procedure TACRLockParamsEditor.SetDelay(Value: Integer);
begin
  if (Value >= ACRMinDelay) then
    FDelay := Value;
end; // SetDelay


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRLockParamsEditor.Assign(Source: TPersistent);
begin
 FDelay := TACRLockParamsEditor(Source).Delay;
 FRetryCount := TACRLockParamsEditor(Source).RetryCount;
end; // Assign
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACROptionsEditor
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACROptionsEditor.Create;
begin
  inherited;
  FMaxSessionCount := ACRDefaultSessionCount;
  if (FMaxSessionCount > ACRMaxSessionCount) then
   FMaxSessionCount := ACRMaxSessionCount;
  FPageSize := ACRDefaultPageSize;
  FExtentPageCount := ACRDefaultExtentPageCount;
  FRandomSearchRetryCount := ACRDefaultRandomSearchRetryCount;
end;//Create


//------------------------------------------------------------------------------
// GetOptions
//------------------------------------------------------------------------------
function TACROptionsEditor.GetOptions: TACROptions;
begin
  Result.MaxSessionCount := FMaxSessionCount;
  Result.PageSize := FPageSize;
  Result.ExtentPageCount := FExtentPageCount;
  Result.RandomSearchRetryCount := FRandomSearchRetryCount;
end;// GetOptions


//------------------------------------------------------------------------------
// SetOptions
//------------------------------------------------------------------------------
procedure TACROptionsEditor.SetOptions(NewOptions: TACROptions);
begin
 FMaxSessionCount := NewOptions.MaxSessionCount;
 FPageSize := NewOptions.PageSize;
 FExtentPageCount := NewOptions.ExtentPageCount;
 FRandomSearchRetryCount := NewOptions.RandomSearchRetryCount;
end; // SetOptions


//------------------------------------------------------------------------------
// SetMaxSessionCount
//------------------------------------------------------------------------------
procedure TACROptionsEditor.SetMaxSessionCount(Value: Cardinal);
begin
  if (Value <= 0) then
    FMaxSessionCount := 1
  else
  if (Value > ACRMaxSessionCount) then
    FMaxSessionCount := ACRMaxSessionCount
  else
    FMaxSessionCount := Value;
end; // SetMaxSessionCount


//------------------------------------------------------------------------------
// SetPageSize
//------------------------------------------------------------------------------
procedure TACROptionsEditor.SetPageSize(Value: Cardinal);
begin
  if (Value > ACRMaxPageSize) then
    FPageSize := ACRMaxPageSize
  else
  if (Value < ACRMinPageSize) then
    FPageSize := ACRMinPageSize
  else
    FPageSize := Value;
end; // SetPageSize


//------------------------------------------------------------------------------
// SetExtentPageCount
//------------------------------------------------------------------------------
procedure TACROptionsEditor.SetExtentPageCount(Value: Word);
begin
  if (Value > ACRMaxExtentPageCount) then
    FExtentPageCount := ACRMaxExtentPageCount
  else
  if (Value < ACRMinExtentPageCount) then
    FExtentPageCount := ACRMinExtentPageCount
  else
    FExtentPageCount := Value;
end; // SetExtentPageCount


//------------------------------------------------------------------------------
// SetRandomSearchRetryCount
//------------------------------------------------------------------------------
procedure TACROptionsEditor.SetRandomSearchRetryCount(Value: Cardinal);
begin
  if (Value > ACRMaxRandomSearchRetryCount) then
    FRandomSearchRetryCount := ACRMaxRandomSearchRetryCount
  else
  if (Value < ACRMinRandomSearchRetryCount) then
    FRandomSearchRetryCount := ACRMinRandomSearchRetryCount
  else
    FRandomSearchRetryCount := Value;
end; // SetRandomSearchRetryCount


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACROptionsEditor.Assign(Source: TPersistent);
begin
 FMaxSessionCount := TACROptionsEditor(Source).MaxSessionCount;
 FExtentPageCount := TACROptionsEditor(Source).ExtentPageCount;
 FPageSize := TACROptionsEditor(Source).PageSize;
 FRandomSearchRetryCount := TACROptionsEditor(Source).RandomSearchRetryCount;
end; // Assign
{$ENDIF}




{$IFNDEF SQLMEMTABLE}
////////////////////////////////////////////////////////////////////////////////
//
// TACRBackupParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRBackupParamsEditor.Create;
begin
  inherited;
  FCryptoParamsEditor := TACRCryptoParamsEditor.Create;
  FCompressionAlgorithm := caNone;
  FCompressionMode := 1;
  FDescription := '';
  FBlockSize := ACRDefaultBackupBlockSize;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRBackupParamsEditor.Destroy;
begin
  FCryptoParamsEditor.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRBackupParamsEditor.Assign(Source: TPersistent);
begin
  FBlockSize := TACRBackupParamsEditor(Source).BlockSize;
  FDescription := TACRBackupParamsEditor(Source).Description;
  FCompressionAlgorithm := TACRBackupParamsEditor(Source).CompressionAlgorithm;
  FCompressionMode := TACRBackupParamsEditor(Source).CompressionMode;
  FCryptoParamsEditor.Assign(TACRBackupParamsEditor(Source).CryptoParams);
end; // Assign
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
//  TACRDatabase
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// raises exception if not active
//------------------------------------------------------------------------------
procedure TACRDatabase.CheckInactive;
begin
  if FHandle <> nil then
    if (csDesigning in ComponentState) then
      Close
    else
      DatabaseError(ErrorADatabaseOpen+' 4', Self);
end;// CheckInactive


//------------------------------------------------------------------------------
// raises exception if database name is not valid
//------------------------------------------------------------------------------
procedure TACRDatabase.CheckDatabaseName;
begin
 if ((FDatabaseName = '') and (not Temporary)) then
    DatabaseError(ErrorADatabaseNameMissing, Self);
end;// CheckDatabaseName


//------------------------------------------------------------------------------
// creates databases with specified directory
//------------------------------------------------------------------------------
constructor TACRDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSkipDatabaseNameCheck := False;
  if (FSession=nil) then
    begin
      if (AOwner is TACRSession) then
        FSession:=TACRSession(AOwner)
      else
        FSession:=ACRDefaultSession;
    end;
  FSessionName := FSession.SessionName;
  FSession.AddDatabase(Self);
  FDataSets:=TList.Create;
  FKeepConnection:=True;
  if (not IsDesignMode) then
   if (Aowner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
     IsDesignMode := true;
  FHandle := nil; // no manager
  {$IFDEF FILE_SERVER_VERSION}
  FExclusive := False;
  {$ELSE}
   {$IFNDEF SQLMEMTABLE}
  FExclusive := True;
   {$ENDIF}
  {$ENDIF}
  FLocalDatabase := True;
  FDatabaseName := GetTemporaryName('AccuracerDB_');
{$IFNDEF SQLMEMTABLE}
  FInMemory := False;
  FDatabaseFileName := '';
  FDatabaseFileNameUnicode := '';
  FBackupParams := TACRBackupParamsEditor.Create;
  FLockParamsEditor := TACRLockParamsEditor.Create;
  FOptionsEditor := TACROptionsEditor.Create;
  FCryptoParamsEditor := TACRCryptoParamsEditor.Create;
{$IFDEF CLIENT_VERSION}
  FConnectionParams := TACRClientConnectParamsEditor.Create;
{$ENDIF}
{$ELSE}
  FInMemory := True;
  FDatabaseName := ACRMemoryDatabaseName;
{$ENDIF}
  FThreadSyncRefCount := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FCaseInsensitive := False; // added in v.5.90
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRDatabase.Destroy;
begin
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Destroy starting ...'+#13#10+
              ', LocalDatabase = '+BoolToStr(FLocalDatabase,True)+#13#10+
              ', ConnectParamsDatabaseName = '+FConnectionParams.DatabaseName+#13#10+
              ', DatabaseName = '+FDatabaseName+#13#10+
              ', DatabaseFileName = '+FDatabaseFileName+#13#10+
              ', Self = '+IntToStr(Integer(Self))+#13#10+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
  Destroying;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Destroy closing ...'+#13#10+
              ', LocalDatabase = '+BoolToStr(FLocalDatabase,True)+#13#10+
              ', ConnectParamsDatabaseName = '+FConnectionParams.DatabaseName+#13#10+
              ', DatabaseName = '+FDatabaseName+#13#10+
              ', DatabaseFileName = '+FDatabaseFileName+#13#10+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
  Close;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Destroy closing ... OK'+#13#10+
              ', LocalDatabase = '+BoolToStr(FLocalDatabase,True)+#13#10+
              ', ConnectParamsDatabaseName = '+FConnectionParams.DatabaseName+#13#10+
              ', DatabaseName = '+FDatabaseName+#13#10+
              ', DatabaseFileName = '+FDatabaseFileName+#13#10+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
{$IFNDEF SQLMEMTABLE}
  FLockParamsEditor.Free;
  FOptionsEditor.Free;
  FCryptoParamsEditor.Free;
{$IFDEF CLIENT_VERSION}
  FConnectionParams.Free;
{$ENDIF}
  FBackupParams.Free;
{$ENDIF}
  FDataSets.Free;
  if (FSession <> nil) then
     FSession.RemoveDatabase(Self);
  FThreadSyncRefCount.Free;
  inherited Destroy;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Destroy finished'+#13#10+#13#10);
 {$ENDIF}
end;//Destroy


//------------------------------------------------------------------------------
// connected := true
//------------------------------------------------------------------------------
procedure TACRDatabase.Open;
var err: AnsiString;
begin
  err := '';
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('> TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'FRefCount = '+IntToStr(FRefCount)
);
{$ENDIF}
  if (FHandle = nil) then
   begin
{$IFNDEF SQLMEMTABLE}
    if Assigned(BeforeConnect) then
     BeforeConnect(Self);
{$ENDIF}
     CheckDatabaseName;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('1. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
     CheckSessionName(True);
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('2. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
     if not (FHandleShared and OpenFromExistingDB) then
       begin
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('3. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
         FSession.LockSession;
         try
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('4. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
          CreateHandle;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('5. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
         except
          on E: Exception do
           begin
            err := e.Message;
            FHandle := nil;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('Err #1. TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+err);
{$ENDIF}
           end;
         end;
         if (FHandle = nil) then
          begin
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('6. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
           FSession.UnlockSession;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('7. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
           DatabaseError(ErrorADatabaseOpenError+#13#10+err, Self);
          end;
          if (FLocalDatabase) then
           begin
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('8. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
             FHandle.ReadOnly := FReadOnly;
             FHandle.Exclusive := FExclusive;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('9. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
           end;
           try
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('10. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
            FHandle.Connected := True;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('11. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
            FReadOnly := FHandle.ReadOnly;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('12. TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FReadOnly = '+BoolToStr(FReadOnly,True)
);
{$ENDIF}
           except
            on E: Exception do
             begin
              err := e.Message;
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
aaWriteToLog('Err #2. TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+err);
{$ENDIF}
              DestroyHandle;
              FSession.UnlockSession;
              // added in 4.60 to avoid crash in TForm.Create when Connected set to true on form
              if (Self.Owner <> nil) then
               if (Self.Owner is TForm) then
                if (fsCreating in TForm(Self.Owner).FormState) then
                 Exit;
              raise;
             end;
           end;// exception
 {$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('13. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
          if (not FLocalDatabase) then
             FExclusive := FHandle.Exclusive;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('14. TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FExclusive = '+BoolToStr(FExclusive,True)
);
{$ENDIF}
           try
            {$IFNDEF SQLMEMTABLE}
            Options.SetOptions(FHandle.Options);
            CryptoParams.SetCryptoParams(FHandle.CryptoParams);
            {$ENDIF}
 {$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('15. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
            // send notification
            FSession.DBNotification(dbOpen,Self);
 {$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('16. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
            FSession.UnlockSession;
 {$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('17. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
           except
            on E: Exception do
             begin
              err := e.Message;
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
aaWriteToLog('Err #3. TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+err);
{$ENDIF}
              FSession.UnlockSession;
              // added in 4.60 to avoid crash in TForm.Create when Connected set to true on form
              if (Self.Owner <> nil) then
                if (Self.Owner is TForm) then
                 if (fsCreating in TForm(Self.Owner).FormState) then
                  Exit;
               raise;
             end;
           end;
(*
         FSession.LockSession;
         try
           try
             CreateHandle;
             if (FHandle = nil) then
              DatabaseError(ErrorADatabaseOpenError, Self);
             if (FLocalDatabase) then
              begin
               FHandle.ReadOnly := FReadOnly;
               FHandle.Exclusive := FExclusive;
              end;
             try
              FHandle.Connected := True;
              FReadOnly := FHandle.ReadOnly;
             except
              DestroyHandle;
              raise;
             end;
             if (not FLocalDatabase) then
               FExclusive := FHandle.Exclusive;
             {$IFNDEF SQLMEMTABLE}
             Options.SetOptions(FHandle.Options);
             CryptoParams.SetCryptoParams(FHandle.CryptoParams);
             {$ENDIF}
             // send notification
             Session.DBNotification(dbOpen,Self);
           except
            on e: Exception do
             if (csDesigning in ComponentState) then
              MessageDlg(e.Message,mtError,[mbOK],0)
             else
              raise;
// replaced in 4.05
//             raise;
           end;
         finally
           FSession.UnlockSession;
         end;
*)
       end
      else
        FAcquiredHandle:=False;
 {$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('18. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
{$IFNDEF SQLMEMTABLE}
    if Assigned(AfterConnect) then
     AfterConnect(Self);
{$ENDIF}
  end; // FHandle = nil
 {$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('19. TACRDatabase.Open, DatabaseName = '+FDatabaseName);
{$ENDIF}
 FThreadSyncRefCount.Lock(True);
 try
  Inc(FRefCount);
 finally
  FThreadSyncRefCount.Unlock;
 end;
{$IFDEF DEBUG_TRACE_TACRDatabase_Open}
aaWriteToLog('< TACRDatabase.Open, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+'FHandle = '+IntToHex(Integer(FHandle),8)
+#13#10+'FRefCount = '+IntToStr(FRefCount)
);
{$ENDIF}
end;// Open


//------------------------------------------------------------------------------
// connected := false
//------------------------------------------------------------------------------
procedure TACRDatabase.Close;
begin
  if (FHandle <> nil) then
    begin
{$IFNDEF SQLMEMTABLE}
      if Assigned(BeforeDisconnect) then
       BeforeDisconnect(Self);
{$ENDIF}
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Close session notification ...'+#13#10+
              ', LocalDatabase = '+BoolToStr(FLocalDatabase,True)+#13#10+
              ', ConnectParamsDatabaseName = '+FConnectionParams.DatabaseName+#13#10+
              ', DatabaseName = '+FDatabaseName+#13#10+
              ', DatabaseFileName = '+FDatabaseFileName+#13#10+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
{$ENDIF}
      Session.DBNotification(dbClose,Self);
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Close closing datasets ...'+
              ', DatabaseName = '+FDatabaseName+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
      CloseDataSets;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Close closing datasets ... OK'+
              ', DatabaseName = '+FDatabaseName+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
      if (not FAcquiredHandle) then
        begin
         if (FHandle <> nil) then
          begin
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Close closing session ...'+
              ', DatabaseName = '+FDatabaseName+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
           DestroyHandle;
 {$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
 aaWriteToLog('TACRDatabase.Close session closed'+
              ', DatabaseName = '+FDatabaseName+
              ', FHandle = '+IntToStr(Integer(FHandle))+#13#10);
 {$ENDIF}
          end;
        end
      else
        FAcquiredHandle:=False;
      FHandle:=nil;
      FThreadSyncRefCount.Lock(True);
      try
        FRefCount := 0;
      finally
        FThreadSyncRefCount.Unlock;
      end;
{$IFNDEF SQLMEMTABLE}
      if Assigned(AfterDisconnect) then
       AfterDisconnect(Self);
{$ENDIF}
    end;
end;// Close


//------------------------------------------------------------------------------
// create database
//------------------------------------------------------------------------------
procedure TACRDatabase.CreateDatabase;
begin
  CheckDatabaseName;
  CheckSessionName(True);
  CheckConnected;
  FSession.LockSession(True);
  try
    CreateHandle;
    if (FHandle = nil) then
      DatabaseError(ErrorADatabaseCreate, Self);
    try
      FHandle.CreateDatabase;
    finally
      DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end;// CreateDatabase


//------------------------------------------------------------------------------
// delete database
//------------------------------------------------------------------------------
procedure TACRDatabase.DeleteDatabase;
var
    DBData:       TACRDatabaseData;
    n:            Integer;
    StartTime:    Cardinal;
{$IFDEF LOG_DELETE_DATABASE_FILE}
    i:            Integer;
{$ENDIF}
begin
 if (not FSkipDatabaseNameCheck) then
  begin
   // DROP DATABASE:
   // we must skip it as it will found database component
   // created by TACRQuery.ExecSQL (SetDBFlag)
   CheckDatabaseName;
   CheckSessionName(True);
   CheckConnected;
  end;
 if (InMemory) then
  begin
    DBData := ACRFindDatabaseData(True,False,FDatabaseName);
    if (DBData <> nil) then
     begin
      // DROP DATABASE:
      // we must skip it as it will found database component
      // created by TACRQuery.ExecSQL (SetDBFlag)
      if (not FSkipDatabaseNameCheck) then
       if (DBData.SessionsCount > 0) then
        raise EACRException.Create(11945,ErrorLDatabaseIsUsedByOtherSessions,[FDatabaseName,DBData.SessionsCount]);
      DBData.Free;
     end;
  end
 else
  if (FLocalDatabase and (not FTemporary)) then
   begin
{$IFDEF LOG_DELETE_DATABASE_FILE}
    i := 0;
{$ENDIF}
    StartTime := aaGetTickCount;
    repeat
     begin
{$IFDEF LOG_DELETE_DATABASE_FILE}
      inc(i);
{$ENDIF}
      {$IFDEF MSWINDOWS}
      if (FDatabaseFileNameUnicode = '') then
       begin
        Windows.DeleteFileA(PAnsiChar(@FDatabaseFileName[1]));
        if not ACRFileExistsAnsi(PAnsiChar(@FDatabaseFileName[1])) then
          break;
       end
      else
       begin
        Windows.DeleteFileW(PWideChar(@FDatabaseFileNameUnicode[1]));
        if not ACRFileExistsUnicode(PWideChar(@FDatabaseFileNameUnicode[1])) then
          break;
       end;
      {$ELSE}
      SysUtils.DeleteFile(FDatabaseFileName);
      if not ACRFileExists(FDatabaseFileName) then
        break;
      {$ENDIF}
     end;
    until (ACRGetTickCountDiff(aaGetTickCount,StartTime) > ACRDatabaseFileDeleteTimeout);
    if GetExists then
     begin
{$IFDEF LOG_DELETE_DATABASE_FILE}
aaWriteToLog('ACRMain-TACRDatabase.DeleteDatabase> Cannot delete database file for ACRDatabaseFileDeleteTimeout = '+IntToStr(ACRDatabaseFileDeleteTimeout)+' msec for '+IntToStr(i)+' times');
{$ENDIF}
      raise EACRException.Create(12166,ErrorLCannotDeleteDatabaseFileExists,
            [FDatabaseFileName])
     end
    else
     begin
{$IFDEF LOG_DELETE_DATABASE_FILE}
aaWriteToLog('ACRMain-TACRDatabase.DeleteDatabase> database file deleted in '+IntToStr(aaGetTickCount - StartTime)+' msec for '+IntToStr(i)+' times');
{$ENDIF}
     end;
   end
  else
    raise EACRException.Create(12167,ErrorLOperationIsNotSupported);
end;// DeleteDatabase


//------------------------------------------------------------------------------
// rename database
//------------------------------------------------------------------------------
procedure TACRDatabase.RenameDatabase(NewDatabaseFileName: AnsiString; NewDatabaseFileNameUnicode: WideString);
var oldName:        AnsiString;
    oldUnicodeName: WideString;
begin
  CheckDatabaseName;
  CheckSessionName(True);
  CheckConnected;
  if (FDatabaseFileName <> '') then
   begin
    oldName := FDatabaseFileName;
    oldUnicodeName := WideString(oldName);
   end;
  if (FDatabaseFileNameUnicode <> '') then
   begin
    oldUnicodeName := FDatabaseFileNameUnicode;
    oldName := AnsiString(oldUnicodeName);
   end;
  if (NewDatabaseFileName <> '') then
   if (NewDatabaseFileName = FDatabaseFileName) then
    Exit;
  if (NewDatabaseFileNameUnicode <> '') then
   if (NewDatabaseFileNameUnicode = FDatabaseFileNameUnicode) then
    Exit;
  {$IFDEF MSWINDOWS}
   if (NewDatabaseFileNameUnicode = '') then
    begin
     if (MoveFileA(PAnsiChar(@oldName[1]), PAnsiChar(@NewDatabaseFileName[1]))) then
       FDatabaseFileName := NewDatabaseFileName;
    end
   else
    begin
     if (MoveFileW(PWideChar(@oldUnicodeName[1]), PWideChar(@NewDatabaseFileNameUnicode[1]))) then
       FDatabaseFileNameUnicode := NewDatabaseFileNameUnicode;
    end;
  {$ELSE}
   if (RenameFile(FDatabaseFileName, NewDatabaseFileName)) then
    FDatabaseFileName := NewDatabaseFileName;
  {$ENDIF}
end;// RenameDatabase


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TACRDatabase.FlushFileBuffers;
begin
  CheckDisconnected;
  FHandle.FlushFileBuffers;
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// close all datasets
//------------------------------------------------------------------------------
procedure TACRDatabase.CloseDataSets;
begin
  while DataSetCount <> 0 do
   TACRDataset(DataSets[DataSetCount-1]).Disconnect;
end;// CloseDataSets


//------------------------------------------------------------------------------
// find and remove dataset
//------------------------------------------------------------------------------
procedure TACRDatabase.RemoveDataset(dataset: TDataset);
var i: Integer;
begin
 for i := 0 to FDataSets.Count-1 do
  if (FDataSets.Items[i] = dataset) then
   begin
    FDataSets.Delete(i);
    break;
   end;
end; // RemoveDataset


//------------------------------------------------------------------------------
// get list of tables in database file
//------------------------------------------------------------------------------
procedure TACRDatabase.GetTablesList(List: TACRWideStringList);
var bCon: Boolean;
begin
  if (not Assigned(List)) then
    raise EACRException.Create(10877,ErrorLNilPointer);
  bCon := Connected;
  if (not bCon) then
   Connected := True;
  // if called from TForm.Create - if database cannot be opened it will not rais exception
  if (not Connected) then
   Exit;
  try
    FHandle.GetTablesList(List);
  finally
    Connected := bCon;
  end;
end;// GetTablesList


//------------------------------------------------------------------------------
// get list of tables in database file
//------------------------------------------------------------------------------
procedure TACRDatabase.GetTablesList(List: TStrings); 
var bCon:     Boolean;
    tempList: TACRWideStringList;
    i:        Integer;
begin
  if (not Assigned(List)) then
    raise EACRException.Create(11952,ErrorLNilPointer);
  bCon := Connected;
  if (not bCon) then
   Connected := True;
  // if called from TForm.Create - if database cannot be opened it will not rais exception
  if (not Connected) then
   Exit;
  tempList := TACRWideStringList.Create;
  try
    FHandle.GetTablesList(tempList);
    List.BeginUpdate;
    try
      List.Clear;
      for i := 0 to tempList.Count-1 do
       List.Add(String(tempList.Strings[i]));
    finally
      List.EndUpdate;
    end;
  finally
    tempList.Free;
    Connected := bCon;
  end;
end; // GetTablesList


//------------------------------------------------------------------------------
// return information about the table
//------------------------------------------------------------------------------
function TACRDatabase.GetTablesInfo(SortByTableName: Boolean): TACRTableInfoArray;
var bCon: Boolean;
begin
  bCon := Connected;
  if (not bCon) then
   Connected := True;
  // if called from TForm.Create - if database cannot be opened it will not rais exception
  if (not Connected) then
   Exit;
  try
    Result := FHandle.GetTablesInfo(SortByTableName);
  finally
    Connected := bCon;
  end;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// return table state
//------------------------------------------------------------------------------
function TACRDatabase.GetTableState(TableName: WideString): TACRTableState;
var bCon: Boolean;
begin
  bCon := Connected;
  if (not bCon) then
   Connected := True;
  // if called from TForm.Create - if database cannot be opened it will not rais exception
  if (not Connected) then
   Exit;
  try
    Result := FHandle.GetTableState(TableName);
  finally
    Connected := bCon;
  end;
end; // GetTableState


//------------------------------------------------------------------------------
// determine if table exists
//------------------------------------------------------------------------------
function TACRDatabase.TableExists(TableName: WideString) : Boolean;
var bCon: Boolean;
begin
  Result := False;
  if (Length(TableName) <= 0) then Exit;
  bCon := Connected;
  if (not bCon) then
   try
     Connected := True;
   except
     Exit;
   end;
  // if called from TForm.Create - if database cannot be opened it will not raised exception
  if (not Connected) then
   Exit;
  Result := FHandle.TableExists(TableName);
  Connected := bCon;
end;// TableExists


//------------------------------------------------------------------------------
// load all tables from file
//------------------------------------------------------------------------------
procedure TACRDatabase.LoadAllTablesFromStream(
                    Stream: TStream
                   );
var i,num: Integer;
    table: TACRTable;
begin
  LoadDataFromStream(num,SizeOf(num),Stream,11342);
  if (num > 0) then
   begin
    table := TACRTable.Create(Self);
    try
      for i := 0 to num - 1 do
       begin
        table.DatabaseName := Self.DatabaseName;
        table.TableName := '';
        table.LoadTableFromStream(Stream);
       end;
    finally
      table.Free;
    end;
   end;
end; // LoadAllTablesFromStream


//------------------------------------------------------------------------------
// save tables to stream
//------------------------------------------------------------------------------
procedure TACRDatabase.SaveTablesToStream(
                TableList:            TACRWideStringList;
                Stream:               TStream;
                CompressionAlgorithm: TCompressionAlgorithm;
                CompressionMode:      Byte;
                BlockSize:            Integer
              );
var num,i:  Integer;
    name:   WideString;
    table:  TACRTable;
begin
  if (TableList = nil) then
   raise EACRException.Create(11609,ErrorLNilPointer);
  num := TableList.Count;
  SaveDataToStream(num,SizeOf(num),Stream,11339);
  if (num > 0) then
   begin
    table := TACRTable.Create(Self);
    try
      table.DatabaseName := Self.DatabaseName;
      for i := 0 to num - 1 do
       begin
        name := TableList.Strings[i];
        table.TableName := name;
        table.SaveTableToStream(Stream,CompressionAlgorithm,CompressionMode,BlockSize);
       end;
    finally
      table.Free;
    end;
   end;
end; // SaveTablesToStream


//------------------------------------------------------------------------------
// save all tables to file
//------------------------------------------------------------------------------
procedure TACRDatabase.SaveAllTablesToStream(
                    Stream: TStream;
                    CompressionAlgorithm: TCompressionAlgorithm;
                    CompressionMode:      Byte;
                    BlockSize:            Integer
                  );
var num,i:  Integer;
    name:   WideString;
    table:  TACRTable;
    tables: TACRWideStringList;
begin
  tables := TACRWideStringList.Create;
  try
    GetTablesList(tables);
    SaveTablesToStream(tables,Stream,CompressionAlgorithm,CompressionMode,BlockSize);
  finally
    tables.Free;
  end;
end; // SaveAllTablesToStream


//------------------------------------------------------------------------------
// export all tables in the database to SQL script
//------------------------------------------------------------------------------
function TACRDatabase.ExportDatabaseToSQL(
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
var bConnected: Boolean;
begin
 bConnected := Connected;
 Result := '';
 if (not bConnected) then
  Open;
 try
  // rewritten in v.5.10
  Result := FHandle.ExportDatabaseToSQL(ExportStructure,AddDropTableCommand,
                ExportIndexes,AddDropIndexCommand,
                ExportData,ExportBLOBFields,
                UseBracketsForNames,
                ExportForeignKeys,
                ExportStoredFunctions,
                ExportViews
                );
 finally
  if (not bConnected) then
   Close;
 end;
end; // ExportDatabaseToSQL


//------------------------------------------------------------------------------
// load database from stream
//------------------------------------------------------------------------------
procedure TACRDatabase.LoadDatabaseFromStream(
                    Stream: TStream
                   );
var bOpened:        Boolean;
    openedDatasets: TList;
    i:              Integer;
    ds:             TACRDataset;
begin
  bOpened := Connected;
  if (bOpened) then
   begin
    openedDatasets := Tlist.Create;
    i := 0;
    while (DataSetCount > 0) do
     begin
      ds := DataSets[0];
      if (ds.Active) then
       begin
        openedDatasets.Add(ds);
        ds.Close;
       end;
     end;
    Close;
   end;
  try
    DeleteDatabase;
    CreateHandle;
    try
     try
      FHandle.LoadDatabaseFromStream(Stream);
     except on E: Exception do
      begin
        DestroyHandle;
        DeleteDatabase;
        raise;
      end;
     end;
    finally
      if (Assigned(FHandle)) then
        DestroyHandle;
      if (bOpened) then
        Open;
    end;
  finally
   if (bOpened) then
    begin
      for i := 0 to openedDatasets.Count - 1 do
       TACRDataset(openedDatasets.Items[i]).Open;
      openedDatasets.Free;
    end;
  end;
end; // LoadDatabaseFromStream


//------------------------------------------------------------------------------
// save database to stream
//------------------------------------------------------------------------------
procedure TACRDatabase.SaveDatabaseToStream(
                Stream:               TStream;
                CompressionAlgorithm: TCompressionAlgorithm = caNone;
                CompressionMode:      Byte = 0;
                BlockSize:            Integer = ACRDefaultSaveBlockSize
              );
var bOpened: Boolean;
    CompAlg: TACRCompressionAlgorithm;
begin
  bOpened := Connected;
  if (not bOpened) then
   Open;
  try
    CompAlg := ConvertCompressionAlgorithmToACRCompressionAlgorithm(CompressionAlgorithm);
    FHandle.SaveDatabaseToStream(Stream,CompAlg,CompressionMode,BlockSize);
  finally
    if (not bOpened) then
      Close;
  end;
end; // SaveDatabaseToStream


//------------------------------------------------------------------------------
// load database from file
//------------------------------------------------------------------------------
procedure TACRDatabase.LoadDatabaseFromFile(
                FileName:             AnsiString;
                FileNameUnicode:      WideString = ''
                   );
var fs: TACRFileStream;
begin
  if (FileName <> '') then
   fs := TACRFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite)
  else
   fs := TACRFileStream.Create(FileNameUnicode, fmOpenRead or fmShareDenyWrite);
  try
    LoadDatabaseFromStream(fs);
  finally
    fs.Free;
  end;
end; // LoadDatabaseFromFile


//------------------------------------------------------------------------------
// save database to file
//------------------------------------------------------------------------------
procedure TACRDatabase.SaveDatabaseToFile(
                FileName:             AnsiString;
                FileNameUnicode:      WideString = '';
                CompressionAlgorithm: TCompressionAlgorithm = caNone;
                CompressionMode:      Byte = 0;
                BlockSize:            Integer = ACRDefaultSaveBlockSize
              );
var fs: TACRFileStream;
begin
  if (FileName <> '') then
   fs := TACRFileStream.Create(FileName, fmCreate)
  else
   fs := TACRFileStream.Create(FileNameUnicode, fmCreate);
  try
    SaveDatabaseToStream(fs,CompressionAlgorithm,CompressionMode,BlockSize);
  finally
    fs.Free;
  end;
end; // SaveDatabaseToFile


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRDatabase.GetTableComment(TableName: WideString): WideString;
begin
  CheckDisconnected;
  Result := FHandle.GetTableComment(TableName);
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRDatabase.SetTableComment(TableName, Comment: WideString);
begin
  CheckDisconnected;
  FHandle.SetTableComment(TableName,Comment);
end; // SetTableComment


////////////////////////////////////////////////////////////////////////////////
//
//-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create new stored function
//------------------------------------------------------------------------------
procedure TACRDatabase.CreateStoredFunction(SQLScript: WideString);
begin
  CheckDisconnected;
  FHandle.CreateStoredFunction(SQLScript);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// drop stored function
//------------------------------------------------------------------------------
procedure TACRDatabase.DropStoredFunction(FunctionName: WideString);
begin
  CheckDisconnected;
  FHandle.DropStoredFunction(FunctionName);
end; // DropStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TACRDatabase.AlterStoredFunction(
                                FunctionName,
                                NewSQLScript: WideString
                             );
begin
  CheckDisconnected;
  FHandle.AlterStoredFunction(FunctionName,NewSQLScript);
end; // AlterStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TACRDatabase.AlterStoredFunctionRename(
                            Session:          TACRBaseSession;
                            FunctionName,
                            NewFunctionName:  WideString
                                                    );
begin
  CheckDisconnected;
  FHandle.AlterStoredFunction(FunctionName,NewFunctionName);
end; // AlterStoredFunction


//------------------------------------------------------------------------------
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
//------------------------------------------------------------------------------
function TACRDatabase.ExecuteStoredFunction(FunctionName: WideString; ResultValue: TACRVariant; Params: TACRSQLParams): Boolean;
begin
  CheckDisconnected;
  Result := FHandle.ExecuteStoredFunction(FunctionName,ResultValue,Params);
end; // ExecuteStoredFunction


//------------------------------------------------------------------------------
// return empty string if function not found; otherwise
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TACRDatabase.FindStoredFunction(FunctionName: WideString): WideString;
begin
  CheckDisconnected;
  Result := FHandle.FindStoredFunction(FunctionName);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// get list of stored functions
//------------------------------------------------------------------------------
procedure TACRDatabase.GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings; SortNamesByAlphabet: Boolean);
begin
  CheckDisconnected;
  FHandle.GetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet);
end; // GetStoredFunctionsList


//------------------------------------------------------------------------------
// get list of stored functions
//------------------------------------------------------------------------------
procedure TACRDatabase.GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList; SortNamesByAlphabet: Boolean);
begin
  CheckDisconnected;
  FHandle.GetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet);
end; // GetStoredFunctionsList


//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TACRDatabase.ExportStoredFunctionsToSQL(var SQL: WideString);
begin
  CheckDisconnected;
  FHandle.ExportStoredFunctionsToSQL(SQL);
end; // ExportStoredFunctionsToSQL


//------------------------------------------------------------------------------
// return true if stored functions can be used
//------------------------------------------------------------------------------
function TACRDatabase.IsStoredFunctionManagerExists: Boolean;
begin
  if (InMemory) then
    Result := True
{$IFDEF SQLMEMTABLE};{$ELSE}
  else
    Result := (GetFormatVersion >= (ACRStoredFunctionManagerFirstVersion-0.000000001));
{$ENDIF}    
end; // IsStoredFunctionManagerExist


//--------------------------- VIEWS - added in v.6.00 --------------------------

//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TACRDatabase.CreateView(
                     ViewName:          WideString;
                     SelectStatement:   WideString;
                     Columns:           TACRWideStringList;
                     bWithCheckOption:  Boolean;
                     Comment:           WideString
                    );
begin
  CheckDisconnected;
  FHandle.CreateView(ViewName,SelectStatement,Columns,bWithCheckOption,Comment);
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TACRDatabase.DropView(
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
begin
  CheckDisconnected;
  FHandle.DropView(ViewName,bCascade);
end; // DropView


//----------------------- END OF VIEWS - added in v.6.00 -----------------------
{$IFNDEF SQLMEMTABLE}
//------------------------------------------------------------------------------
// retrun true if database has active transaction
//------------------------------------------------------------------------------
function TACRDatabase.GetInTransaction: Boolean;
begin
  CheckDisconnected;
  Result := FHandle.InTransaction;
end; // GetInTransaction


//------------------------------------------------------------------------------
// receive custom message from server and call defined event
//------------------------------------------------------------------------------
procedure TACRDatabase.ReceiveMessage(Buffer: PAnsiChar; Size: Integer);
{$IFDEF CLIENT_VERSION}
var MessageType: TACRMessageType;
    ms,ms1:      TACRMemoryStream;
    Text:        AnsiString;
    WideText:    WideString;
    len:         Integer;
    Buf:         PAnsiChar;
    StreamSize:  Int64;
{$ENDIF}
begin
  CheckDisconnected;
  if (FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  {$IFDEF CLIENT_VERSION}
  ms := TACRMemoryStream.Create(Buffer);
  try
    LoadDataFromStream(MessageType,SizeOf(MessageType),ms,11369);
    case MessageType of
     aamtText:
      if (Assigned(FOnReceiveTextMessage)) then
       begin
         LoadDataFromStream(len,SizeOf(len),ms,11370);
         SetLength(Text,len);
         if (len > 0) then
          LoadDataFromStream(PAnsiChar(@Text[1])^,len,ms,11371);
         FOnReceiveTextMessage(Text);
       end;
     aamtUnicodeText:
      if (Assigned(FOnReceiveUnicodeTextMessage)) then
       begin
         LoadDataFromStream(len,SizeOf(len),ms,11719);
         SetLength(WideText,len);
         if (len > 0) then
          LoadDataFromStream(PAnsiChar(@WideText[1])^,len,ms,11720);
         FOnReceiveUnicodeTextMessage(WideText);
       end;
     aamtBinary:
      if (Assigned(FOnReceiveBinaryMessage)) then
       begin
         LoadDataFromStream(len,SizeOf(len),ms,11372);
         if (len > 0) then
          begin
           Buf := MemoryManager.GetMem(len);
           try
             LoadDataFromStream(Buf^,len,ms,11373);
             FOnReceiveBinaryMessage(Buf,len);
           finally
             MemoryManager.FreeAndNilMem(Buf);
           end;
          end
         else
          FOnReceiveBinaryMessage(nil,len);
       end;
     aamtStream:
      if (Assigned(FOnReceiveStreamMessage)) then
       begin
        ms1 := TACRMemoryStream.Create;
        try
          LoadDataFromStream(StreamSize,SizeOf(StreamSize),ms,11374);
          if (StreamSize > 0) then
           ms1.LoadFromStreamWithPosition(ms,ms.Position,StreamSize);
          FOnReceiveStreamMessage(ms1);
        finally
          ms1.Free;
        end;
       end;
    end;
  finally
    ms.Free;
  end;
  {$ENDIF}
end; // ReceiveMessage


//------------------------------------------------------------------------------
// start a transaction
//------------------------------------------------------------------------------
procedure TACRDatabase.StartTransaction;
begin
  CheckDisconnected;
 {$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('TACRDatabase.StartTransaction starting...'
    +', SessionID = '+
      IntToStr(TACRBaseSession(FHandle).SessionID));
 {$ENDIF}
  FHandle.StartTransaction;
 {$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('TACRDatabase.StartTransaction starting...ok'
    +', SessionID = '+
      IntToStr(TACRBaseSession(FHandle).SessionID));
 {$ENDIF}
end; // StartTransaction


//------------------------------------------------------------------------------
// apply changes made by transaction
//------------------------------------------------------------------------------
procedure TACRDatabase.Commit(FlushFileBuffers: Boolean);
begin
  CheckDisconnected;
 {$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('TACRDatabase.Commit starting...'
    +', SessionID = '+
      IntToStr(TACRBaseSession(FHandle).SessionID));
 {$ENDIF}
  FHandle.Commit(FlushFileBuffers);
 {$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('TACRDatabase.Commit starting... ok'
    +', SessionID = '+
      IntToStr(TACRBaseSession(FHandle).SessionID));
 {$ENDIF}
end; // Commit


//------------------------------------------------------------------------------
// cancel changes made by transaction
//------------------------------------------------------------------------------
procedure TACRDatabase.Rollback;
begin
  CheckDisconnected;
 {$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('TACRDatabase.Rollback starting...'
    +', SessionID = '+
      IntToStr(TACRBaseSession(FHandle).SessionID));
 {$ENDIF}
  FHandle.Rollback;
 {$IFDEF DEBUG_TRACE_TRANSACTIONS}
   aaWriteToLog('TACRDatabase.Rollback starting... ok'
    +', SessionID = '+
      IntToStr(TACRBaseSession(FHandle).SessionID));
 {$ENDIF}
end; // Rollback


//------------------------------------------------------------------------------
// remove all locks - called by disconnect of server session
//------------------------------------------------------------------------------
procedure TACRDatabase.RemoveAllLocks;
begin
  if (FHandle <> nil) then
   FHandle.RemoveAllLocks;
end; // RemoveAllLocks


//------------------------------------------------------------------------------
// clear disk cache in single-user / multi-user
//------------------------------------------------------------------------------
procedure TACRDatabase.ClearCache;
begin
  if (FHandle <> nil) then
   FHandle.ClearCache;
end; // ClearCache


//------------------------------------------------------------------------------
// repair database
//------------------------------------------------------------------------------
function TACRDatabase.InternalRepairDatabase(
                                             IgnoreErrors:                Boolean;
                                             var Log:                     AnsiString ;
                                             UseLowLevelTableAccess:      Boolean = False;
                                             Options:                     TACROptionsEditor = nil;
                                             CryptoParams:                TACRCryptoParamsEditor = nil;
                                             NewDatabaseFileName:         AnsiString = '';
                                             NewDatabaseFileNameUnicode:  WideString = ''
                                    ): Boolean;
var newDB:            TACRDatabase;
    i,j:              Integer;
    oldTable:         TACRTable;
    tableNames:       TACRWideStringList;
    Abort,bOK:        Boolean;
    Operation:        TACRDatabaseOperation;
    Progress:         Double;
    bLowLevel:        Boolean;
    FKList:           TList;
    FKDefs:           TACRForeignKeyDefs;
    bReadOnly:        Boolean;
    SourceNames,
    SourceSQL:        TACRWideStringList;

 procedure DoAbort;
 begin
  Log := Log + #13#10 + 'Operation aborted';
  newDb.Close;
  newDB.DeleteDatabase;
  Self.Close;
 end; // DoAbort;

begin
 Log := '';
 bReadOnly := FReadOnly;
 try
   // added in v.5.60 to avoid corruption of source file
   FReadOnly := true;
   Abort := False;
   if (IgnoreErrors) then
    Operation := dbopRepair
   else
    Operation := dbopCompact;
   if (Options<> nil) or (CryptoParams <> nil) then
    Operation := dbopChangeDatabaseSettings;
   if (NewDatabaseFileName <> '') then
    Operation := dbopCopy;
   if (Operation <> dbopRepair) then
     bLowLevel := False
   else
     bLowLevel := UseLowLevelTableAccess;
   CheckInactive;
   Result := False;
   if ((not FExclusive) and (Operation <> dbopCopy)) then
    raise EACRException.Create(10743,ErrorLDatabaseIsNotInExclusiveMode,[FDatabaseName]);
   tableNames := TACRWideStringList.Create;
   FKList := TList.Create;
   newDB := TACRDatabase.Create(nil);
   try
    // create new temporary database file
    newDB.DatabaseName := GetTemporaryName('TempDatabase');
    newDB.SessionName := SessionName;
    if (NewDatabaseFileName <> '') then
     newDB.DatabaseFileName := NewDatabaseFileName
    else
    if (NewDatabaseFileNameUnicode <> '') then
     newDB.DatabaseFileNameUnicode := NewDatabaseFileNameUnicode
    else
     newDB.DatabaseFileName := GetTempFileName;
    if Operation <> dbopChangeDatabaseSettings then
     begin
      newDB.Options.Assign(Self.Options);
      newDB.CryptoParams.Assign(Self.CryptoParams);
     end
    else
     begin
      newDB.Options.Assign(Options);
      newDB.CryptoParams.Assign(CryptoParams);
     end;
    newDB.LockParams.Assign(Self.LockParams);
    newDB.Exclusive := True;
    try
     newDB.CreateDatabase;
    except
    on e: Exception do
     begin
      Log := Log + Format(ErrorLRepairDatabaseCannotCreateDatabase,[newDB.DatabaseFileName,e.Message]);
      Exit;
     end;
    end;
   try
    Open;
   except
    on e: Exception do
     begin
      Log := Log + Format(ErrorLRepairDatabaseCannotOpenDatabase,[FDatabaseFileName,e.Message]);
      Exit;
     end;
   end;
   // get table names list
    try
     Self.GetTablesList(tableNames);
    except
    on e: Exception do
     begin
      Log := Log + Format(ErrorLRepairDatabaseCannotGetTableNamesList,[Self.DatabaseFileName,e.Message]);
      Exit;
     end;
    end;
    DoOnProgress(0,Operation,Abort);
    if (Abort) then
     begin
      DoAbort;
      Exit;
     end;
    try
     newDB.Open;
    except
    on e: Exception do
     begin
      Log := Log + Format(ErrorLRepairDatabaseCannotOpenDatabase,[newDB.DatabaseFileName,e.Message]);
      Exit;
     end;
    end;
    // copy stored functions
    SourceNames := TACRWideStringList.Create;
    SourceSQL := TACRWideStringList.Create;
    try
      try
        Self.GetStoredFunctions(SourceNames,SourceSQL,False);
      except
      end;
      for i := 0 to SourceSQL.Count-1 do
      begin
       try
        newDB.CreateStoredFunction(SourceSQL.Strings[i]);
       except
       end;
      end;
    finally
      SourceNames.Free;
      SourceSQL.Free;
    end;
    // copy all tables
    if (tableNames.Count > 0) then
     begin
      oldTable := TACRTable.Create(nil);
      try
        oldTable.FExclusive := True;
        oldTable.DatabaseName := Self.DatabaseName;
        oldTable.SessionName := SessionName;
        for i := 0 to tableNames.Count - 1 do
         begin
          oldTable.OnProgress := FOnTableProgress;
          oldTable.Close;
          oldTable.TableName := tableNames[i];
          FKDefs := TACRForeignKeyDefs.Create;
          FKList.Add(FKDefs);
          if (not bLowLevel) then
            bOK := oldTable.InternalRepairOrRestructureTable(True,Log,newDB,FKDefs)
          else
            bOK := oldTable.RepairTable(Log,bLowLevel,newDB,FKDefs);
          if (not bOK) then
            if (not IgnoreErrors) then
             begin
              DoAbort;
              Exit;
             end;
          Progress := (i + 1) * 100;
          Progress := Progress / tableNames.Count;
          DoOnProgress(Progress,Operation,Abort);
          if (Abort) then
           begin
            DoAbort;
            Exit;
           end;
         end; // copy tables
        // recreate foreign keys 
        for i := 0 to tableNames.Count-1 do
          begin
           oldTable.Close;
           oldTable.DatabaseName := newDB.DatabaseName;
           oldTable.TableName := tableNames[i];
           FKDefs := FKList.Items[i];
           if (FKDefs <> nil) then
            for j := 0 to FKDefs.Count-1 do
             try
              oldTable.AddForeignKey(FKDefs.Items[j]);
             except
              on e: Exception do
               begin
                 Log := Log + Format(ErrorLCannotAddForeignKey,[FKDefs.Items[j].Name,oldTable.TableName,e.Message]);
               end
              else
               begin
                 Log := Log + Format(ErrorLCannotAddForeignKey,[FKDefs.Items[j].Name,oldTable.TableName,'']);
               end;
             end;
          end;
      finally
       oldTable.Free;
      end;
     end; // there are some tables in the database
    try
     newDB.Close;
    except
    on e: Exception do
     begin
      Log := Log + Format(ErrorLRepairDatabaseCannotCloseDatabase,[newDB.DatabaseFileName,e.Message]);
      Exit;
     end;
    end;
    try
     Self.Close;
    except
    on e: Exception do
     begin
      Log := Log + Format(ErrorLRepairDatabaseCannotCloseDatabase,[Self.DatabaseFileName,e.Message]);
      Exit;
     end;
    end;
    if (Operation <> dbopCopy) then
     begin
      Self.DeleteDatabase;
      newDB.RenameDatabase(FDatabaseFileName,FDatabaseFileNameUnicode);
     end;
    DoOnProgress(100.0,Operation,Abort);
    Result := True;
   finally
    newDB.Free;
    tableNames.Free;
    for i := 0 to FKList.Count-1 do
     TACRForeignKeyDefs(FKList.Items[i]).Free;
    FKList.Free;
   end;
 finally
   FReadOnly := bReadOnly;
 end;
end; // InternalRepairDatabase


//------------------------------------------------------------------------------
// compact database
//------------------------------------------------------------------------------
procedure TACRDatabase.CompactDatabase;
var Log: AnsiString;
begin
 if (InMemory or Temporary) then
  raise EACRException.Create(10740,ErrorLOperationCanBePerformedOnlyOnDiskDatabase);
 if (not InternalRepairDatabase(False,Log)) then
  raise EACRException.Create(10739,ErrorLCompactDatabaseFailed,[FDatabaseFileName,Log]);
end; // CompactDatabase


//------------------------------------------------------------------------------
// repair database
//------------------------------------------------------------------------------
function TACRDatabase.RepairDatabase(UseLowLevelTableAccess: Boolean = False): Boolean;
var Log: AnsiString;
begin
 Result := RepairDatabase(Log, UseLowLevelTableAccess);
end; // RepairDatabase


//------------------------------------------------------------------------------
// repair database
//------------------------------------------------------------------------------
function TACRDatabase.RepairDatabase(var Log: AnsiString; UseLowLevelTableAccess: Boolean): Boolean;
begin
 if (InMemory or Temporary) then
  raise EACRException.Create(10741,ErrorLOperationCanBePerformedOnlyOnDiskDatabase);
 Result := InternalRepairDatabase(True,Log,UseLowLevelTableAccess);
end; // RepairDatabase


//------------------------------------------------------------------------------
// change database settings
//------------------------------------------------------------------------------
function TACRDatabase.ChangeDatabaseSettings(Options: TACROptionsEditor;
                                 CryptoParams: TACRCryptoParamsEditor): Boolean;
var Log: AnsiString;
begin
 if (InMemory or Temporary) then
  raise EACRException.Create(50029,ErrorFOperationCanBePerformedOnlyOnDiskDatabase);
 Result := InternalRepairDatabase(False, Log, False, Options, CryptoParams);
end; // ChangeDatabaseSettings


//------------------------------------------------------------------------------
// get total count of pages
//------------------------------------------------------------------------------
function TACRDatabase.GetFormatVersion: Double;
begin
  Result := ACRVersion;
  if (Assigned(FHandle)) then
   Result := FHandle.GetFormatVersion;
end; // GetFormatVersion


//------------------------------------------------------------------------------
// empty proc for displaying property in Object Inspector
//------------------------------------------------------------------------------
procedure TACRDatabase.SetFormatVersion(Value: Double);
begin
;
end;


//------------------------------------------------------------------------------
// get total count of pages
//------------------------------------------------------------------------------
function TACRDatabase.GetTotalPageCount: Integer;
begin
  Result := 0;
  if (Assigned(FHandle)) then
   Result := FHandle.GetTotalPageCount;
end; // GetTotalPageCount


//------------------------------------------------------------------------------
// get count of free pages
//------------------------------------------------------------------------------
function TACRDatabase.GetFreePageCount: Integer;
begin
  Result := 0;
  if (Assigned(FHandle)) then
   Result := FHandle.GetFreePageCount;
end; // GetFreePageCount


//------------------------------------------------------------------------------
// return number of used pages
//------------------------------------------------------------------------------
function TACRDatabase.GetUsedPageCount: Integer;
begin
  Result := 0;
  if (Assigned(FHandle)) then
    Result := GetTotalPageCount - GetFreePageCount;
end; // GetUsedPageCount


//------------------------------------------------------------------------------
// return density = usedpagecoount / totalpagecount * 100.0 %
//------------------------------------------------------------------------------
function TACRDatabase.GetDensity: Double;
var d,d1: Double;
begin
  Result := 0;
  if (Assigned(FHandle)) then
   begin
    d := GetTotalPageCount;
    d1 := GetUsedPageCount;
    if (d = 0) then
     Result := 0
    else
     Result := d1 / d * 100.0;
   end;
end; // GetDensity


//------------------------------------------------------------------------------
// return true if database is encrypted
//------------------------------------------------------------------------------
function TACRDatabase.IsDatabaseEncrypted: Boolean;
var DatabaseClosed: Boolean;
begin
  if (FLocalDatabase) then
   if (not Self.Exists) then
    raise EACRException.Create(10735,ErrorLDatabaseFileDoesNotExitst,[FDatabaseFileName]);
  CheckDatabaseName;
  CheckSessionName(True);

  FSession.LockSession;
  try
    DatabaseClosed := (FHandle = nil);
    if (DatabaseClosed) then
     CreateHandle;
    try
      if (FHandle = nil) then
        DatabaseError(ErrorADatabaseCreate, Self);
      Result := FHandle.IsDatabaseEncrypted;
    finally
      if (DatabaseClosed) then
        DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end; // IsDatabaseEncrypted


//------------------------------------------------------------------------------
// return true if database is encrypted by password, false if by key
//------------------------------------------------------------------------------
function TACRDatabase.IsDatabaseEncryptedByPassword: Boolean;
var DatabaseClosed: Boolean;
begin
  if (FLocalDatabase) then
   if (not Self.Exists) then
    raise EACRException.Create(10736,ErrorLDatabaseFileDoesNotExitst,[FDatabaseFileName]);
  CheckDatabaseName;
  CheckSessionName(True);

  FSession.LockSession;
  try
    DatabaseClosed := (FHandle = nil);
    if (DatabaseClosed) then
     CreateHandle;
    try
      if (FHandle = nil) then
        DatabaseError(ErrorADatabaseCreate, Self);
      Result := FHandle.IsDatabaseEncryptedByPassword;
    finally
      if (DatabaseClosed) then
        DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end; // IsDatabaseEncryptedByPassword


//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TACRDatabase.IsCryptoParamsValid: Boolean;
var DatabaseClosed: Boolean;
begin
  if (FLocalDatabase) then
   if (not Self.Exists) then
    raise EACRException.Create(10737,ErrorLDatabaseFileDoesNotExitst,[FDatabaseFileName]);
  CheckDatabaseName;
  CheckSessionName(True);

  FSession.LockSession;
  try
    DatabaseClosed := (FHandle = nil);
    if (DatabaseClosed) then
     CreateHandle;
    try
      if (FHandle = nil) then
        DatabaseError(ErrorADatabaseCreate, Self);
      FHandle.CryptoParams := FCryptoParamsEditor.GetCryptoParams;
      Result := FHandle.IsCryptoParamsValid;
    finally
      if (DatabaseClosed) then
        DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end; // IsCryptoParamsValid


//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
procedure TACRDatabase.SendMessage(const Text: AnsiString);
{$IFDEF CLIENT_VERSION}
var
  ClientSession:  TACRClientSession;
  ms:             TACRMemoryStream;
  MessageType:    TACRMessageType;
  len:            Integer;
{$ENDIF}
begin
  CheckDisconnected;
  if (FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  {$IFDEF CLIENT_VERSION}
  ClientSession := TACRClientSession(FHandle);
  MessageType := aamtText;
  len := Length(Text);
  ms := TACRMemoryStream.Create();
  try
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11273);
   SaveDataToStream(len,SizeOf(len),ms,11274);
   if (len > 0) then
     SaveDataToStream(PAnsiChar(@Text[1])^,len,ms,11275);
   ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
  {$ENDIF}
end; // SendMessage


//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
procedure TACRDatabase.SendMessage(const Text: WideString);
{$IFDEF CLIENT_VERSION}
var
  ClientSession:  TACRClientSession;
  ms:             TACRMemoryStream;
  MessageType:    TACRMessageType;
  len:            Integer;
{$ENDIF}
begin
  CheckDisconnected;
  if (FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  {$IFDEF CLIENT_VERSION}
  ClientSession := TACRClientSession(FHandle);
  MessageType := aamtUnicodeText;
  len := Length(Text);
  ms := TACRMemoryStream.Create();
  try
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11712);
   SaveDataToStream(len,SizeOf(len),ms,11713);
   if (len > 0) then
     SaveDataToStream(PAnsiChar(@Text[1])^,len,ms,11714);
   ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
  {$ENDIF}
end; // SendMessage


//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
procedure TACRDatabase.SendMessage(Buffer: PAnsiChar; Size: Integer);
{$IFDEF CLIENT_VERSION}
var
  ClientSession:  TACRClientSession;
  ms:             TACRMemoryStream;
  MessageType:    TACRMessageType;
{$ENDIF}
begin
  CheckDisconnected;
  if (FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  {$IFDEF CLIENT_VERSION}
  ClientSession := TACRClientSession(FHandle);
  if (ClientSession = nil) then
   raise EACRException.Create(11251,ErrorLClientIsNotConnected);
  MessageType := aamtBinary;
  ms := TACRMemoryStream.Create();
  try
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11276);
   SaveDataToStream(Size,SizeOf(Size),ms,11277);
   if (Size > 0) then
     SaveDataToStream(Buffer^,Size,ms,11278);
   ClientSession.SendMessage(ms.Buffer,ms.Size);
  finally
    ms.Free;
  end;
  {$ENDIF}
end; // SendMessage


//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
procedure TACRDatabase.SendMessage(Stream: TStream);
{$IFDEF CLIENT_VERSION}
var
  ClientSession:  TACRClientSession;
  ms:             TACRMemoryStream;
  MessageType:    TACRMessageType;
  Size:           Int64;
{$ENDIF}
begin
  CheckDisconnected;
  if (FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  {$IFDEF CLIENT_VERSION}
  ClientSession := TACRClientSession(FHandle);
  if (ClientSession = nil) then
   raise EACRException.Create(11252,ErrorLClientIsNotConnected);
  MessageType := aamtStream;
  Size := Stream.Size;
  ms := TACRMemoryStream.Create();
  try
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11279);
   SaveDataToStream(Size,SizeOf(Size),ms,11280);
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
  {$ENDIF}
end; // SendMessage


//------------------------------------------------------------------------------
// makes Exe database from edb file
//------------------------------------------------------------------------------
procedure TACRDatabase.MakeExeDatabase(ExeFileName, ExeDatabaseFileName: AnsiString);
var DatabaseClosed: Boolean;
begin
  CheckDatabaseName;
  CheckSessionName(True);
  CheckConnected;
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  if (FLocalDatabase) then
   if (not Self.Exists) then
    raise EACRException.Create(11286,ErrorLDatabaseFileDoesNotExitst,[FDatabaseFileName]);
  if (not FExclusive) then
   raise EACRException.Create(11287,ErrorLDatabaseIsNotInExclusiveMode,[FDatabaseName]);
  FSession.LockSession;
  try
    DatabaseClosed := (FHandle = nil);
    if (DatabaseClosed) then
      CreateHandle;
    try
      if (FHandle = nil) then
        DatabaseError(ErrorADatabaseCreate, Self);
      FHandle.MakeExeDatabase(ExeFileName,ExeDatabaseFileName);
    finally
      if (DatabaseClosed) then
        DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end; // MakeExeDatabase


//------------------------------------------------------------------------------
// removes database file from executable database file
//------------------------------------------------------------------------------
procedure TACRDatabase.RemoveDatabaseFromExe;
var DatabaseClosed: Boolean;
begin
  CheckDatabaseName;
  CheckSessionName(True);
  CheckConnected;
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  if (FLocalDatabase) then
   if (not Self.Exists) then
    raise EACRException.Create(11297,ErrorLDatabaseFileDoesNotExitst,[FDatabaseFileName]);
  if (not FExclusive) then
   raise EACRException.Create(11299,ErrorLDatabaseIsNotInExclusiveMode,[FDatabaseName]);
  FSession.LockSession;
  try
    DatabaseClosed := (FHandle = nil);
    if (DatabaseClosed) then
      CreateHandle;
    try
      if (FHandle = nil) then
        DatabaseError(ErrorADatabaseCreate, Self);
      FHandle.RemoveDatabaseFromExe;
    finally
      if (DatabaseClosed) then
        DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end; // RemoveDatabaseFromExe


//------------------------------------------------------------------------------
// returns true if this file is an Accuracer database
//------------------------------------------------------------------------------
function TACRDatabase.IsAccuracerDatabaseFile: Boolean;
var DatabaseClosed: Boolean;
begin
  CheckDatabaseName;
  CheckSessionName(True);
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  if (not Self.Exists) then
   begin
     Result := False;
     Exit;
   end;
  FSession.LockSession;
  try
    DatabaseClosed := (FHandle = nil);
    if (DatabaseClosed) then
      CreateHandle;
    try
      if (FHandle = nil) then
        DatabaseError(ErrorADatabaseCreate, Self);
      Result := FHandle.IsAccuracerDatabaseFile;
    finally
      if (DatabaseClosed) then
        DestroyHandle;
    end;
  finally
   FSession.UnlockSession;
  end;
end; // IsAccuracerDatabaseFile


//------------------------------------------------------------------------------
// return true if file was copied
//------------------------------------------------------------------------------
function TACRDatabase.CopyDatabase(const NewDatabaseFileName: AnsiString; const NewDatabaseFileNameUnicode: WideString): Boolean;
var Log: AnsiString;
begin
  Result := CopyDatabase(Log,NewDatabaseFileName,NewDatabaseFileNameUnicode);
end; // CopyDatabase


//------------------------------------------------------------------------------
// return true if file was copied
//------------------------------------------------------------------------------
function TACRDatabase.CopyDatabase(var Log: AnsiString; const NewDatabaseFileName: AnsiString; const NewDatabaseFileNameUnicode: WideString): Boolean;
begin
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  CheckConnected;
  Result := InternalRepairDatabase(False,Log,False,nil,nil,NewDatabaseFileName,NewDatabaseFileNameUnicode);
end; // CopyDatabase


//------------------------------------------------------------------------------
// on backup progress
//------------------------------------------------------------------------------
procedure TACRDatabase.DoOnBackupProgress(Sender: TObject; Progress: Double; var Abort: Boolean);
begin
  if (Assigned(FOnProgress)) then
   FOnProgress(Self,Progress,dbopBackup,Abort);
end; // DoOnBackupProgress


//------------------------------------------------------------------------------
// on restore progress
//------------------------------------------------------------------------------
procedure TACRDatabase.DoOnRestoreProgress(Sender: TObject; Progress: Double; var Abort: Boolean);
begin
  if (Assigned(FOnProgress)) then
   FOnProgress(Self,Progress,dbopRestore,Abort);
end; // DoOnRestoreProgress


//------------------------------------------------------------------------------
// load backup header
//------------------------------------------------------------------------------
procedure TACRDatabase.LoadBackupHeader(
                     Stream:            TACRStream;
                     var Header:        TACRBackupHeader;
                     out Description:   WideString;
                     Tables:            TACRWideStringList = nil);
var
    MS:             TACRMemoryStream;
    CryptoInfo:     TACRCryptoInfo;
    I:              Integer;
    S:              WideString;
begin
  Stream.Position := 0;
  CryptoInfo := FBackupParams.CryptoParams.GetCryptoParams;
  LoadDataFromStream(Header,SizeOf(Header),Stream,11356);
  CryptoInfo.CryptoAlgorithm := Header.CryptoHeader.CryptoAlgorithm;
  CryptoInfo.CryptoMode := Header.CryptoHeader.CryptoMode;
  if (Header.CryptoHeader.CryptoAlgorithm <> ACR_Cipher_None) then
   ACRDecryptBuffer(CryptoInfo,PAnsiChar(@Header.DescHeader),SizeOf(Header.DescHeader));
  if (Header.DescHeader.Size > 0) then
   begin
    MS := TACRMemoryStream.Create;
    try
      MS.LoadFromStreamWithPosition(Stream,Stream.Position,Header.DescHeader.Size);
      if (Header.CryptoHeader.CryptoAlgorithm <> ACR_Cipher_None) then
       ACRDecryptBuffer(CryptoInfo,MS.Buffer,MS.Size);
      MS.Position := 0;
      LoadWideStringFromStream(Description,MS,11357);
      if (Tables <> nil) then
        Tables.LoadFromStream(MS);
    finally
      MS.Free;
    end;
   end;
end; // LoadBackupHeader


{$ENDIF}
//------------------------------------------------------------------------------
// return if search is case insensitive ('a' = 'A')
//------------------------------------------------------------------------------
function TACRDatabase.GetCaseInsensitive: Boolean;
begin
  Result := FCaseInsensitive;
end; // GetCaseInsensitive




//------------------------------------------------------------------------------
// set case insensitive search ('a' = 'A')
//------------------------------------------------------------------------------
procedure TACRDatabase.SetCaseInsensitive(Value: Boolean);
var i: Integer;
begin
  FCaseInsensitive := Value;
  if (FHandle <> nil) then
   FHandle.CaseInsensitive := Value;
  if (FLocalDatabase) then
  begin
    for i := 0 to DataSetCount-1 do
    begin
      TACRDataset(DataSets[i]).CaseInsensitive := Value;
    end;
  end;
end; // SetCaseInsensitive
{$IFNDEF SQLMEMTABLE}


//------------------------------------------------------------------------------
// backup
//------------------------------------------------------------------------------
procedure TACRDatabase.Backup(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString);
var
    DBFile,
    BackupFile:     TACRFileStream;
    MS:             TACRMemoryStream;
    Header:         TACRBackupHeader;
    CryptoInfo:     TACRCryptoInfo;
    OnFileProgress: TACRProgressEvent;
    I:              Integer;
    Tables:         TACRWideStringList;
    s:              WideString;
begin
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  CheckInactive;
  if (BackupFileName = '') and (BackupFileNameUnicode = '') then
   raise EACRException.Create(11745,ErrorLBackupFileNameIsEmpty);
  OnFileProgress := nil;
  if (Assigned(FOnProgress)) then
   OnFileProgress := DoOnBackupProgress;
  CryptoInfo := FBackupParams.CryptoParams.GetCryptoParams;
  Tables := TACRWideStringList.Create;
  try
    GetTablesList(Tables);
    Header.Signature := ACRBackupSignature;
    Header.BlockSize := FBackupParams.BlockSize;
    Header.CompressionAlgorithm := Byte(FBackupParams.CompressionAlgorithm);
    Header.CompressionMode := FBackupParams.CompressionMode;
    Header.CryptoHeader := ACRCreateCryptoHeader(CryptoInfo);
    Header.DescHeader.TableCount := Tables.Count;
    Header.DescHeader.DescLength := Length(FBackupParams.Description)*2;
    if (FDatabaseFileName <> '') then
     DBFile := TACRFileStream.Create(FDatabaseFileName,fmOpenRead and fmShareExclusive)
    else
     DBFile := TACRFileStream.Create(FDatabaseFileNameUnicode,fmOpenRead and fmShareExclusive);
    try
     Header.DescHeader.Date := Now;
     Header.DescHeader.FileSize := DBFile.Size;
     if (BackupFileName <> '') then
      BackupFile := TACRFileStream.Create(BackupFileName,fmCreate)
     else
      BackupFile := TACRFileStream.Create(BackupFileNameUnicode,fmCreate);
     try
       MS := TACRMemoryStream.Create;
       try
         s := FBackupParams.Description;
         SaveWideStringToStream(s,MS,11353);
         Tables.SaveToStream(MS);
         Header.DescHeader.Size := MS.Size;
         if (CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) then
          begin
           ACREncryptBuffer(CryptoInfo,PAnsiChar(@Header.DescHeader),SizeOf(Header.DescHeader));
           ACREncryptBuffer(CryptoInfo,MS.Buffer,MS.Size);
          end;
         BackupFile.WriteBuffer(Header,SizeOf(Header));
         MS.SaveToStream(BackupFile);
       finally
         MS.Free;
       end;
       BackupFile.Position := BackupFile.Size;
       CompressAndEncryptStream(CryptoInfo,
                                Header.CompressionAlgorithm,
                                Header.CompressionMode,
                                Header.BlockSize,
                                DBFile,
                                BackupFile,
                                OnFileProgress);
     finally
       BackupFile.Free;
     end;
    finally
      DBFile.Free;
    end;
  finally
    Tables.Free;
  end;
end; // Backup


//------------------------------------------------------------------------------
// restore
//------------------------------------------------------------------------------
procedure TACRDatabase.Restore(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString);
var BackupFile:         TACRFileStream;
    DBFile:             TACRFileStream;
    Header:             TACRBackupHeader;
    CryptoInfo:         TACRCryptoInfo;
    OnFileProgress:     TACRProgressEvent;
begin
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  CheckInactive;
  if (BackupFileName = '') and (BackupFileNameUnicode = '') then
   raise EACRException.Create(11746,ErrorLBackupFileNameIsEmpty);
  OnFileProgress := nil;
  if (Assigned(FOnProgress)) then
   OnFileProgress := DoOnRestoreProgress;
  if (not ACRFileExists(BackupFileName,BackupFileNameUnicode)) then
   DatabaseError(ErrorLBackupFileDoesNotExists);
  CryptoInfo := FBackupParams.CryptoParams.GetCryptoParams;
  if (BackupFileName <> '') then
   BackupFile := TACRFileStream.Create(BackupFileName,fmOpenRead or fmShareDenyWrite)
  else
   BackupFile := TACRFileStream.Create(BackupFileNameUnicode,fmOpenRead or fmShareDenyWrite);
  try
    if (BackupFile.Size < SizeOf(Header)) then
     DatabaseError(ErrorLInvalidBackupFile)
    else
     begin
      BackupFile.ReadBuffer(Header,SizeOf(Header));
      CryptoInfo.CryptoAlgorithm := Header.CryptoHeader.CryptoAlgorithm;
      CryptoInfo.CryptoMode := Header.CryptoHeader.CryptoMode;
      if (Header.Signature <> ACRBackupSignature) then
       DatabaseError(ErrorLInvalidBackupFile);
      if (Header.CryptoHeader.CryptoAlgorithm <> ACR_Cipher_None) then
       if (not ACRIsKeyValid(Header.CryptoHeader,FBackupParams.CryptoParams.GetCryptoParams)) then
        DatabaseError(ErrorLBackupFileInvalidCryptoParams)
       else
        ACRDecryptBuffer(CryptoInfo,PAnsiChar(@Header.DescHeader),SizeOf(Header.DescHeader));
      BackupFile.Position := BackupFile.Position + Header.DescHeader.Size;
      if (FDatabaseFileName <> '') then
       DBFile := TACRFileStream.Create(FDatabaseFileName,fmCreate)
      else
       DBFile := TACRFileStream.Create(FDatabaseFileNameUnicode,fmCreate);
      try
        DecompressAndDecryptStream(CryptoInfo,
                                Header.CompressionAlgorithm,
                                Header.CompressionMode,
                                Header.BlockSize,
                                BackupFile,
                                DBFile,
                                OnFileProgress);
      finally
        DBFile.Free;
      end;
     end;
  finally
    BackupFile.Free;
  end;
end; // Restore


//------------------------------------------------------------------------------
// get backup info
//------------------------------------------------------------------------------
function TACRDatabase.GetBackupInfo(const BackupFileName: AnsiString; Tables: TACRWideStringList; const BackupFileNameUnicode: WideString): TACRBackupInfo;
var FS:         TACRFileStream;
    Header:     TACRBackupHeader;
    bShow:      Boolean;
    CryptoInfo: TACRCryptoInfo;
begin
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  if (not ACRFileExists(BackupFileName,BackupFileNameUnicode)) then
   DatabaseError(ErrorLBackupFileDoesNotExists);
  if (BackupFileName = '') and (BackupFileNameUnicode = '') then
   raise EACRException.Create(11747,ErrorLBackupFileNameIsEmpty);
  if (BackupFileName <> '') then
   FS := TACRFileStream.Create(BackupFileName,fmOpenRead or fmShareDenyNone)
  else
   FS := TACRFileStream.Create(BackupFileNameUnicode,fmOpenRead or fmShareDenyNone);
  try
    if (FS.Size < SizeOf(Header)) then
     DatabaseError(ErrorLInvalidBackupFile)
    else
     begin
      FS.ReadBuffer(Header,SizeOf(Header));
      if (Header.Signature <> ACRBackupSignature) then
       DatabaseError(ErrorLInvalidBackupFile);
      Result.Encrypted := (Header.CryptoHeader.CryptoAlgorithm <> ACR_Cipher_None);
      Result.EncryptedByPassword := (Header.CryptoHeader.CryptoAskPassword <> 0);
      bShow := True;
      CryptoInfo := FBackupParams.CryptoParams.GetCryptoParams;
      CryptoInfo.CryptoAlgorithm := Header.CryptoHeader.CryptoAlgorithm;
      CryptoInfo.CryptoMode := Header.CryptoHeader.CryptoMode;
      if (Result.Encrypted) then
       if (not ACRIsKeyValid(Header.CryptoHeader,CryptoInfo)) then
         bShow := False;
      if (bShow) then
       begin
        LoadBackupHeader(FS,Header,Result.Description,Tables);
        Result.TableCount := Header.DescHeader.TableCount;
        Result.Date := Header.DescHeader.Date;
        Result.FileSize := Header.DescHeader.FileSize;
       end;
     end;
  finally
    FS.Free;
  end;
end; // GetBackupInfo


//------------------------------------------------------------------------------
// is Accuracer backup file
//------------------------------------------------------------------------------
function TACRDatabase.IsAccuracerBackupFile(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString): Boolean;
var FS:       TACRFileStream;
    Header:   TACRBackupHeader;
begin
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  Result := ACRFileExists(BackupFileName,BackupFileNameUnicode);
  if (Result) then
   begin
    if (BackupFileName <> '') then
     FS := TACRFileStream.Create(BackupFileName,fmOpenRead or fmShareDenyNone)
    else
     FS := TACRFileStream.Create(BackupFileNameUnicode,fmOpenRead or fmShareDenyNone);
    try
      if (FS.Size < SizeOf(Header)) then
       Result := False
      else
       begin
        FS.ReadBuffer(Header,SizeOf(Header));
        Result := (Header.Signature = ACRBackupSignature);
       end;
    finally
      FS.Free;
    end;
   end;
end; // IsAccuracerBackupFile


//------------------------------------------------------------------------------
// is Accuracer backup file can be restored using these crypto params
//------------------------------------------------------------------------------
function TACRDatabase.IsAccuracerBackupFileCryptoParamsValid(const BackupFileName: AnsiString; const BackupFileNameUnicode: WideString): Boolean;
var FS:         TACRFileStream;
    Header:     TACRBackupHeader;
    CryptoInfo: TACRCryptoInfo;
begin
  if (not FLocalDatabase) then
   DatabaseError(ErrorLOperationIsNotSupported);
  Result := ACRFileExists(BackupFileName,BackupFileNameUnicode);
  if (Result) then
   begin
    if (BackupFileName <> '') then
     FS := TACRFileStream.Create(BackupFileName,fmOpenRead or fmShareDenyNone)
    else
     FS := TACRFileStream.Create(BackupFileNameUnicode,fmOpenRead or fmShareDenyNone);
    try
      if (FS.Size < SizeOf(Header)) then
       Result := False
      else
       begin
        FS.ReadBuffer(Header,SizeOf(Header));
        Result := (Header.Signature = ACRBackupSignature);
        if (Result) then
         if (Header.CryptoHeader.CryptoAlgorithm <> ACR_Cipher_None) then
          begin
            CryptoInfo := FBackupParams.CryptoParams.GetCryptoParams;
            CryptoInfo.CryptoAlgorithm := Header.CryptoHeader.CryptoAlgorithm;
            CryptoInfo.CryptoMode := Header.CryptoHeader.CryptoMode;
            Result := ACRIsKeyValid(Header.CryptoHeader,CryptoInfo);
          end;
       end;
    finally
      FS.Free;
    end;
   end;
end; // IsAccuracerBackupFileCryptoParamsValid
{$ENDIF}


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TACRDatabase.SetConnected(value: boolean);
begin
  if (csReading in ComponentState) then
    FStreamedConnected := Value
  else
   begin
    if Value = GetConnected then
     Exit;
    try
      if Value then
       Open
      else
       Close;
    except
     on e: Exception do
      begin
       if (csDesigning in ComponentState) then
        MessageDlg(e.Message,mtError,[mbOK],0)
       else
        raise;
      end
    end;
   end;
end;//SetConnected


//------------------------------------------------------------------------------
// set specified database name
//------------------------------------------------------------------------------
procedure TACRDatabase.SetDatabaseName(Value: AnsiString);
var i: Integer;
begin
  if (FDatabaseName <> Value) then
   begin
    if (not FSkipDatabaseNameCheck) then
     begin
      if (Connected) then
        Close;
      if (not (csReading in ComponentState)) then
       begin
        CheckInactive;
        ValidateName(Value);
       end;
     end;
    FDatabaseName := Value;
   end;
end;//SetDatabaseName


//------------------------------------------------------------------------------
// sets in-memory property
//------------------------------------------------------------------------------
procedure TACRDatabase.SetInMemory(Value: Boolean);
begin
 if (FInMemory <> Value) then
  begin
    if (Connected) then
     begin
      Close;
      if (not (csReading in ComponentState)) then
       begin
        CheckInactive;
        ValidateName(FDatabaseName);
       end;
     end;
    FInMemory := Value;
  end;
end; // SetInMemory


//------------------------------------------------------------------------------
// sets handle
//------------------------------------------------------------------------------
procedure TACRDatabase.SetHandle(Value: TACRBaseSession);
var
  DBSession: TACRSessionComponentManager;
begin
   if Connected then
      Close;
   if (Value <> nil) then
     begin
      DBSession := Value.SessionComponentManager;
      CheckDatabaseName;
      CheckSessionName(True);
      // database handle owned by another session
      if (FSession.FHandle <> DBSession) then
        DatabaseError(ErrorADatabaseHandleSet, Self);
      FHandle:=Value;
      Session.DBNotification(dbOpen,Self);
      FAcquiredHandle:=True;
     end;
end;// SetHandle


//------------------------------------------------------------------------------
// set specified ANSI file name
//------------------------------------------------------------------------------
procedure TACRDatabase.SetDatabaseFileName(Value: AnsiString);
begin
  if csReading in ComponentState then
    FDatabaseFileName := Value
  else
  if FDatabaseFileName <> Value then
   begin
    Connected := False;
    FDatabaseFileName := Value;
   end;
  FDatabaseFileNameUnicode := '';
end;// SetDatabaseFileName


//------------------------------------------------------------------------------
// set specified Unicode file name
//------------------------------------------------------------------------------
procedure TACRDatabase.SetDatabaseFileNameUnicode(Value: WideString);
begin
  if csReading in ComponentState then
    FDatabaseFileNameUnicode := Value
  else
  if FDatabaseFileNameUnicode <> Value then
   begin
    Connected := False;
    FDatabaseFileNameUnicode := Value;
   end;
  FDatabaseFileName := '';
end; // SetDatabaseFileNameUnicode


{$IFDEF D12H}
//------------------------------------------------------------------------------
// return database file name (Unicode)
//------------------------------------------------------------------------------
function TACRDatabase.GetDatabaseFileNameUnicodeAsString: String;
begin
  Result := String(FDatabaseFileNameUnicode);
end; // GetDatabaseFileNameUnicodeAsString


//------------------------------------------------------------------------------
// set database file name (Unicode)
//------------------------------------------------------------------------------
procedure TACRDatabase.SetDatabaseFileNameUnicodeAsString(Value: String);
begin
  SetDatabaseFileNameUnicode(WideString(Value));
end; // SetDatabaseFileNameUnicodeAsString
{$ENDIF}


//------------------------------------------------------------------------------
// is database file exists
//------------------------------------------------------------------------------
function TACRDatabase.GetExists: boolean;
var bCon: Boolean;

begin
  Result := False;
  bCon := Assigned(FHandle);
  // optimized in v.4.80 - otherwise will hang in multi-threaded mode
  if (bCon) then
   Result := True
  else
   begin
    if (FInMemory) then
     begin
      Result := (ACRFindDatabaseData(True,False,FDatabaseName) <> nil);
     end
    else
     begin
      // modified in 4.95
      if (FLocalDatabase) then
       begin
        // check if local database already opened by other sessions
        if (FTemporary) then
         Result := (ACRFindDatabaseData(False,True,FDatabaseName,FDatabaseFileNameUnicode) <> nil)
        else
         Result := (ACRFindDatabaseData(False,False,FDatabaseFileName,FDatabaseFileNameUnicode) <> nil);
       end;
      if (not Result) then
       begin
        if (not bCon) then
         CreateHandle;
        Result := FHandle.GetDatabaseExists;
        if (not bCon) then
         DestroyHandle;
       end; // The database is already opened
     end;
   end;
end;// GetExists


//------------------------------------------------------------------------------
// get database manager
//------------------------------------------------------------------------------
procedure TACRDatabase.CreateHandle;
begin
  FHandle := nil;
  if (FLocalDatabase) then
   begin
    FHandle := TACRLocalSession.Create;
{
aaWriteToLog('1 TACRDatabase.CreateHandle, DatabaseName = '+FDatabaseName
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
);
}
    FHandle.InMemory := FInMemory;
    FHandle.DatabaseName := FDatabaseName;
    FHandle.SessionName := FSessionName;
    FHandle.Temporary := FTemporary and (not FInMemory);
    if (FHandle.Temporary) then
     FHandle.InMemory := False;
    if (FInMemory or FHandle.Temporary) then
     FHandle.DatabaseFileName := FDatabaseName
    else
     FHandle.DatabaseFileName := FDatabaseFileName;
    FHandle.DatabaseFileNameUnicode := FDatabaseFileNameUnicode;
    {$IFNDEF SQLMEMTABLE}
    FHandle.LockParams := FLockParamsEditor.GetLockParams;
    FHandle.Options := FOptionsEditor.GetOptions;
    FHandle.CryptoParams := FCryptoParamsEditor.GetCryptoParams;
    {$ENDIF}
   end // LocalDatabase
  else
   begin
    {$IFDEF CLIENT_VERSION}
    {$IFNDEF SQLMEMTABLE}
      FHandle := TACRClientSession.Create;
      FHandle.DatabaseName := FConnectionParams.DatabaseName;
      FHandle.SessionName := FSessionName;
      FHandle.ConnectParams := FConnectionParams.GetConnectParams;
      FHandle.LockParams := FLockParamsEditor.GetLockParams;
      FHandle.Options := FOptionsEditor.GetOptions;
      FHandle.CryptoParams := FCryptoParamsEditor.GetCryptoParams;
      TACRClientSession(FHandle).OnReceiveMessage := Self.ReceiveMessage;
      TACRClientSession(FHandle).OnDisconnectRemoteDatasets := Self.DisconnectAllRemoteDatasets;
      TACRClientSession(FHandle).OnError := Self.DoOnError;
      TACRClientSession(FHandle).MinCacheSize := FConnectionParams.MinCacheSize;
      TACRClientSession(FHandle).MaxCacheSize := FConnectionParams.MaxCacheSize;
    {$ENDIF}
    {$ENDIF}
   end;
  FAcquiredHandle := False;
end;// CreateHandle


//------------------------------------------------------------------------------
// release database manager
//------------------------------------------------------------------------------
procedure TACRDatabase.DestroyHandle;
begin
 if (Assigned(FHandle)) then
  begin
   try
     if (FHandle.Connected) then
      FHandle.Connected := False;
   except
    on e: Exception do
     begin
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
aaWriteToLog('1. TACRDatabase.DestroyHandle, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+e.Message);
{$ENDIF}
     end;
   end;
   try
    FHandle.Free;
   except
    on e: Exception do
     begin
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
aaWriteToLog('2. TACRDatabase.DestroyHandle, DatabaseName = '+FDatabaseName
+#13#10+'FLocalDatabase = '+BoolToStr(FLocalDatabase,True)
+#13#10+'FInMemory = '+BoolToStr(FInMemory,True)
+#13#10+'FTemporary = '+BoolToStr(FTemporary,True)
+#13#10+'DatabaseFileName = '+FDatabaseFileName
+#13#10+e.Message);
{$ENDIF}
     end;
   end;
  end;
 FHandle := nil;
end;// DestroyHandle


//------------------------------------------------------------------------------
// disconnect all remote datasets
//------------------------------------------------------------------------------
procedure TACRDatabase.DisconnectAllRemoteDatasets(ServerShutdown: Boolean);
var i: Integer;
begin
  if ((not FLocalDatabase) and (Connected)) then
   begin
    if (ServerShutdown) then
     begin
      if (Assigned(FBeforeServerShutdown)) then
        FBeforeServerShutdown(Self);
     end
    else
     begin
      if (Assigned(FBeforeConnectionLost)) then
        FBeforeConnectionLost(Self);
     end;
    try
      for i := 0 to FDataSets.Count - 1 do
       if (TDataset(FDatasets[i]).Active) then
        begin
          if (TACRDataset(FDataSets[i]).IsTable) then
           if (TACRTable(FDataSets[i]).Handle <> nil) then
            // skip sending CloseTable request to server
            TACRTable(FDataSets[i]).Handle.IsOpen := False;
          TDataset(FDatasets[i]).Close;
        end;
    finally
      if (ServerShutdown) then
       begin
        if (Assigned(FAfterServerShutdown)) then
          FAfterServerShutdown(Self);
       end
      else
       begin
        if (Assigned(FAfterConnectionLost)) then
          FAfterConnectionLost(Self);
       end;
    end;
   end;
end; // DisconnectAllRemoteDatasets


//------------------------------------------------------------------------------
// on error
//------------------------------------------------------------------------------
procedure TACRDatabase.DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: AnsiString
                       );
begin
  if (Assigned(FOnError)) then
   FOnError(Self,ErrorCode,NativeError,ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// loaded
//------------------------------------------------------------------------------
procedure TACRDatabase.Loaded;
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
procedure TACRDatabase.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);
  if (Operation = opRemove) and (AComponent = FSession) and
     (FSession <> ACRDefaultSession) then
    begin
      Close;
      FSessionName := '';
    end;
end;// Notification


//------------------------------------------------------------------------------
// progress event
//------------------------------------------------------------------------------
procedure TACRDatabase.DoOnProgress(
            Progress:   Double;
            Operation:  TACRDatabaseOperation;
            var Abort:  Boolean);
begin
 if Assigned(FOnProgress) then
   FOnProgress(Self,Progress,Operation,Abort);
end; // DoOnProgress


//------------------------------------------------------------------------------
// progress event
//------------------------------------------------------------------------------
procedure TACRDatabase.DoOnTableProgress(
                                  Sender:     TComponent;
                                  Progress:   Double;
                                  Operation:  TACRTableOperation;
                                  var Abort:  Boolean
                           );
begin
 if (Assigned(FOnTableProgress)) then
  FOnTableProgress(Sender,Progress,Operation,Abort);
end; // DoOnTableProgress


//------------------------------------------------------------------------------
// before insert record
//------------------------------------------------------------------------------
procedure TACRDatabase.DoBeforeInsertRecord(
                   Sender:             TACRDataset;
                   const TableName:    WideString;
                   const FieldValues:  TACRArrayOfTACRVariant;
                   var Abort:          Boolean
                 );
begin
  Abort := False;
  if (Assigned(FBeforeInsertRecord)) then
   FBeforeInsertRecord(Sender,TableName,FieldValues,Abort);
end; // DoBeforeInsertRecord


//------------------------------------------------------------------------------
// after insert record
//------------------------------------------------------------------------------
procedure TACRDatabase.DoAfterInsertRecord(
                   Sender:             TACRDataset;
                   const TableName:    WideString;
                   const FieldValues:  TACRArrayOfTACRVariant
                 );
begin
  if (Assigned(FAfterInsertRecord)) then
   FAfterInsertRecord(Sender,TableName,FieldValues);
end; // DoAfterInsertRecord


//------------------------------------------------------------------------------
// before update record
//------------------------------------------------------------------------------
procedure TACRDatabase.DoBeforeUpdateRecord(
                   Sender:                TACRDataset;
                   const TableName:       WideString;
                   const OldFieldValues:  TACRArrayOfTACRVariant;
                   const NewFieldValues:  TACRArrayOfTACRVariant;
                   var Abort:             Boolean
                 );
begin
  Abort := False;
  if (Assigned(FBeforeUpdateRecord)) then
   FBeforeUpdateRecord(Sender,TableName,OldFieldValues,NewFieldValues,Abort);
end; // DoBeforeUpdateRecord


//------------------------------------------------------------------------------
// after update record
//------------------------------------------------------------------------------
procedure TACRDatabase.DoAfterUpdateRecord(
                   Sender:                TACRDataset;
                   const TableName:       WideString;
                   const OldFieldValues:  TACRArrayOfTACRVariant;
                   const NewFieldValues:  TACRArrayOfTACRVariant
                 );
begin
  if (Assigned(FAfterUpdateRecord)) then
   FAfterUpdateRecord(Sender,TableName,OldFieldValues,NewFieldValues);
end; // DoAfterUpdateRecord


//------------------------------------------------------------------------------
// before delete record
//------------------------------------------------------------------------------
procedure TACRDatabase.DoBeforeDeleteRecord(
                   Sender:             TACRDataset;
                   const TableName:    WideString;
                   const FieldValues:  TACRArrayOfTACRVariant;
                   var Abort:          Boolean
                 );
begin
  Abort := False;
  if (Assigned(FBeforeDeleteRecord)) then
   FBeforeDeleteRecord(Sender,TableName,FieldValues,Abort);
end; // DoBeforeDeleteRecord


//------------------------------------------------------------------------------
// after delete record
//------------------------------------------------------------------------------
procedure TACRDatabase.DoAfterDeleteRecord(
                   Sender:             TACRDataset;
                   const TableName:    WideString;
                   const FieldValues:  TACRArrayOfTACRVariant
                 );
begin
  if (Assigned(FAfterDeleteRecord)) then
   FAfterDeleteRecord(Sender,TableName,FieldValues);
end; // DoAfterDeleteRecord


//------------------------------------------------------------------------------
// before execute SQL script
//------------------------------------------------------------------------------
procedure TACRDatabase.DoBeforeExecuteSQL(
                   Sender:             TACRQuery;
                   var Abort:          Boolean
                 );
begin
  Abort := False;
  if (Assigned(FBeforeExecuteSQL)) then
   FBeforeExecuteSQL(Sender,Abort);
end; // DoBeforeExecuteSQL


//------------------------------------------------------------------------------
// after execute SQL script
//------------------------------------------------------------------------------
procedure TACRDatabase.DoAfterExecuteSQL(
                   Sender:             TACRQuery
                 );

begin
  if (Assigned(FAfterExecuteSQL)) then
   FAfterExecuteSQL(Sender);
end; // DoAfterExecuteSQL


//------------------------------------------------------------------------------
// keep connection
//------------------------------------------------------------------------------
procedure TACRDatabase.SetKeepConnection(Value: Boolean);
begin
 if (FKeepConnection <> Value) then
  begin
    FKeepConnection := Value;
    FThreadSyncRefCount.Lock(True);
    try
      if ((not Value) and (FRefCount = 0)) then
       Close;
    finally
      FThreadSyncRefCount.Unlock;
    end;
  end;
end;// SetKeepConnection


//------------------------------------------------------------------------------
// sets read-only mode
//------------------------------------------------------------------------------
procedure TACRDatabase.SetReadOnly(Value: Boolean);
begin
//  CheckInactive;
  FReadOnly := Value;
end;// SetReadOnly


//------------------------------------------------------------------------------
// set session name
//------------------------------------------------------------------------------
procedure TACRDatabase.SetSessionName(const Value: AnsiString);
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
procedure TACRDatabase.CheckSessionName(Required: Boolean);
var
  NewSession: TACRSession;
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
// CheckConnected
//------------------------------------------------------------------------------
procedure TACRDatabase.CheckConnected;
begin
  if (Connected) then
    DatabaseError(ErrorADatabaseOpen+' 2', Self);
end;// CheckConnected


//------------------------------------------------------------------------------
// CheckDisconnected
//------------------------------------------------------------------------------
procedure TACRDatabase.CheckDisconnected;
begin
  if (not Connected) then
    DatabaseError(ErrorLDatabaseIsNotOpened, Self);
end;// CheckDisconnected


//------------------------------------------------------------------------------
// db connected?
//------------------------------------------------------------------------------
function TACRDatabase.GetConnected: Boolean;
begin
  Result := (FHandle <> nil);
end;// GetConnected


//------------------------------------------------------------------------------
// connected dataset
//------------------------------------------------------------------------------
function TACRDatabase.GetDataSet(Index: Integer): TACRDataSet;
begin
  Result := FDataSets[Index];
end;// GetDataSet


//------------------------------------------------------------------------------
// count of connected datasets
//------------------------------------------------------------------------------
function TACRDatabase.GetDataSetCount: Integer;
begin
  Result := FDataSets.Count;
end;// GetDataSetCount


//------------------------------------------------------------------------------
// opens from existing DB
//------------------------------------------------------------------------------
function TACRDatabase.OpenFromExistingDB: Boolean;
begin
  FHandle := FSession.FindDatabaseHandle(DatabaseName,FInMemory,FTemporary);
  Result := (FHandle <> nil);
  FAcquiredHandle := Result;
end;// OpenFromExistingDB


//------------------------------------------------------------------------------
// validates name
//------------------------------------------------------------------------------
procedure TACRDatabase.ValidateName(const Name: AnsiString);
var
  Database: TACRDatabase;
  rc:       Integer;
begin
 if (not FSkipDatabaseNameCheck) and (Name <> '') and (FSession <> nil) then
  begin
    Database := FSession.DoFindDatabase(Name,FInMemory,FTemporary,nil);
    if ((Database <> nil) and (Database <> Self) and
          not (Database.FHandleShared and FHandleShared)) then
     begin
      Database.FThreadSyncRefCount.Lock(True);
      try
        rc := Database.FRefCount;
      finally
        Database.FThreadSyncRefCount.Unlock;
      end;
      if (rc <> 0) then
       DatabaseError(ErrorADatabaseOpen+' 3'
        +#13#10+'Temporary = '+BoolToStr(Database.Temporary,True)
        +#13#10+'RefCount = '+IntToStr(rc)
        +#13#10+'Name = '+Name
        +#13#10+'Database = '+IntToHex(Integer(Database),8)
        +#13#10+'Self = '+IntToHex(Integer(Self),8)
        );
// commented in v.5.10 - to avoid bug in CREATE DATABASE (utStoredProcedures,CreateDB)         
//      Database.Free;
     end;
  end;
end;// ValidateName


////////////////////////////////////////////////////////////////////////////////
//
//  TACRAdvFieldDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRAdvFieldDef.Assign(Source: TACRAdvFieldDef);
begin
  FName := Source.Name;
  FDataType := Source.DataType;
  FRequired := Source.Required;
  FSize := Source.Size;

  //FDefaultValueType := Source.DefaultValueType;
  FDefaultValue.Assign(Source.DefaultValue,True);
  FMinValue.Assign(Source.FMinValue,True);
  FMaxValue.Assign(Source.MaxValue,True);

  // Blob data
  FBlobCompressionAlgorithm := Source.BlobCompressionAlgorithm;
  FBlobCompressionMode := Source.BlobCompressionMode;
  FBlobBlockSize := Source.BlobBlockSize;

  // Autoinc settings
  FAutoincIncrement := Source.FAutoincIncrement;
  FAutoincInitialValue := Source.FAutoincInitialValue;
  FAutoincMinValue  := Source.FAutoincMinValue;
  FAutoincMaxValue  := Source.FAutoincMaxValue;
  FAutoincCycled    := Source.FAutoincCycled;

end;


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRAdvFieldDef.Create;
begin
  FName := '';
  FDataType := aftUnknown;
  FRequired := false;
  FSize := 0;

  FDefaultValue := TACRVariant.Create;
  FMinValue := TACRVariant.Create;
  FMaxValue := TACRVariant.Create;

  // Blob data
  FBlobCompressionAlgorithm := caNone;
  FBlobCompressionMode := 0;
  FBlobBlockSize := DefaultBlobBlockSize;

  // Autoinc settings
  FAutoincIncrement := 1;
  FAutoincInitialValue := 0;
  FAutoincMinValue  := 0;//Low(Int64);
  FAutoincMaxValue  := High(Int64);
  FAutoincCycled    := False;

end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRAdvFieldDef.Destroy;
begin
  FDefaultValue.Free;
  FMinValue.Free;
  FMaxValue.Free;
  inherited;
end;//Destroy




////////////////////////////////////////////////////////////////////////////////
//
//  TACRAdvFieldDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRAdvFieldDefs.Create;
begin
  FDefsList := TList.Create;
end;//Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRAdvFieldDefs.Assign(Source: TACRAdvFieldDefs);
var i:  Integer;
begin
  Clear;
  for i := 0 to Source.Count - 1 do
    AddFieldDef.Assign(Source[i]);
end;


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRAdvFieldDefs.Destroy;
begin
  Clear;
  FDefsList.Free;
  inherited;
end;//Destroy



//------------------------------------------------------------------------------
// Count
//------------------------------------------------------------------------------
function TACRAdvFieldDefs.GetCount: Integer;
begin
  Result := FDefsList.Count;
end;//GetCount


//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TACRAdvFieldDefs.GetDef(Index: Integer): TACRAdvFieldDef;
begin
  Result := TACRAdvFieldDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TACRAdvFieldDefs.SetDef(Index: Integer; value: TACRAdvFieldDef);
begin
  if (FDefsList[Index] <> nil) then
    TACRAdvFieldDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// AddFieldDef
//------------------------------------------------------------------------------
function TACRAdvFieldDefs.AddFieldDef: TACRAdvFieldDef;
begin
  Result := TACRAdvFieldDef.Create;
  FDefsList.Add(Result);
end;//AddFieldDef


//------------------------------------------------------------------------------
// Add
//------------------------------------------------------------------------------
procedure TACRAdvFieldDefs.Add(const Name: WideString;
  DataType: TACRAdvancedFieldType; Size: Integer; Required: Boolean);
var TmpAdvFieldDef: TACRAdvFieldDef;
begin
  TmpAdvFieldDef := AddFieldDef;
  TmpAdvFieldDef.Name := Name;
  TmpAdvFieldDef.DataType := DataType;
  TmpAdvFieldDef.Size := Size;
  TmpAdvFieldDef.Required := Required;
end;//Add


//------------------------------------------------------------------------------
// DeleteFieldDef
//------------------------------------------------------------------------------
procedure TACRAdvFieldDefs.DeleteFieldDef(const FieldName: WideString);
var i: Integer;
begin
  i := IndexOf(FieldName);
  if (i >= 0) then
    begin
      TACRAdvFieldDef(FDefsList[i]).Free;
      FDefsList.Delete(i);
    end
  else
    raise EACRException.Create(30349, ErrorGFieldWithNameNotFound, [FieldName]);
end;//DeleteFieldDef


//------------------------------------------------------------------------------
// return -1 if not found
//------------------------------------------------------------------------------
function TACRAdvFieldDefs.IndexOf(const Name: WideString): Integer;
var i:   Integer;
    crc: Cardinal;
    s:   WideString;
begin
  Result := -1;
  s := WideUpperCase(Name);
  crc := GetTableNameCRC(s,False);
  for i := 0 to Count-1 do
   if (GetTableNameCRC(TACRAdvFieldDef(Items[i]).Name) = crc) then
    if (WideUpperCase(TACRAdvFieldDef(Items[i]).Name) = s) then
     begin
      Result := i;
      break;
    end
end; // IndexOf


//------------------------------------------------------------------------------
// Find
//------------------------------------------------------------------------------
function TACRAdvFieldDefs.Find(const Name: WideString): TACRAdvFieldDef;
var i:   Integer;
begin
  Result := nil;
  i := IndexOf(Name);
  if (i >= 0) then
   Result := TACRAdvFieldDef(FDefsList[i]);
end; // Find


//------------------------------------------------------------------------------
// varchar exists
//------------------------------------------------------------------------------
function TACRAdvFieldDefs.IsVarcharExists: Boolean;
var i: Integer;
begin
  Result := False;
  for i:=0 to FDefsList.Count-1 do
   if (IsVarcharFieldType(TACRAdvFieldDef(FDefsList[i]).FDataType)) then
    begin
     Result := True;
     break;
    end;
end; // IsVarcharExists


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRAdvFieldDefs.Clear;
var i: Integer;
begin
  for i:=0 to FDefsList.Count-1 do
    TACRAdvFieldDef(FDefsList[i]).Free;
  FDefsList.Clear;
end;//Clear


////////////////////////////////////////////////////////////////////////////////
//
//  TACRForeignKeyDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRForeignKeyDef.Assign(Source: TPersistent);
begin
 FName := TACRForeignKeyDef(Source).Name;
 FDeleteAction := TACRForeignKeyDef(Source).DeleteAction;
 FUpdateAction := TACRForeignKeyDef(Source).UpdateAction;
 FMatchType := TACRForeignKeyDef(Source).MatchType;
 FReferencedTableName := TACRForeignKeyDef(Source).ReferencedTableName;
 FColumns := TACRForeignKeyDef(Source).Columns;
 FName := TACRForeignKeyDef(Source).FName;
end; // Assign


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRForeignKeyDef.Create;
begin
 FName := '';
 FDeleteAction := fkaDefault;
 FUpdateAction := fkaDefault;
 FMatchType := fkmtDefault;
 FColumns := '';
 FReferencedTableName := '';
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRForeignKeyDef.Destroy;
begin
  inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
//  TACRForeignKeyDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetCount
//------------------------------------------------------------------------------
function TACRForeignKeyDefs.GetCount: Integer;
begin
  Result := FDefsList.Count;
end; // GetCount


//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TACRForeignKeyDefs.GetDef(Index: Integer): TACRForeignKeyDef;
begin
  if ((Index < 0) or (Index >= FDefsList.Count)) then
    Result := nil
  else
    Result := FDefsList[Index];
end; // GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TACRForeignKeyDefs.SetDef(Index: Integer; value: TACRForeignKeyDef);
begin
  if (FDefsList[Index] <> nil) then
    TACRForeignKeyDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end; // SetDef


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRForeignKeyDefs.Assign(Source: TPersistent);
var i:  Integer;
begin
  Clear;
  for i := 0 to TACRForeignKeyDefs(Source).Count - 1 do
    AddForeignKeyDef.Assign(TACRForeignKeyDefs(Source)[i]);
end; // Assign


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRForeignKeyDefs.Create;
begin
  FDefsList := TList.Create;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRForeignKeyDefs.Destroy;
begin
  Clear;
  FDefsList.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// AddForeignKeyDef
//------------------------------------------------------------------------------
function TACRForeignKeyDefs.AddForeignKeyDef: TACRForeignKeyDef;
begin
  Result := TACRForeignKeyDef.Create;
  FDefsList.Add(Result);
end; // AddForeignKeyDef


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRForeignKeyDefs.Add(
             const Name: WideString;
             const Columns: WideString;
             const ReferencedTableName: WideString;
             const MatchType: TACRForeignKeyMatchType;
             const DeleteAction: TACRForeignKeyAction;
             const UpdateAction: TACRForeignKeyAction
             );
var Def: TACRForeignKeyDef;
begin
  Def := AddForeignKeyDef;
  Def.Name := Name;
  Def.Columns := Columns;
  Def.ReferencedTableName := ReferencedTableName;
  Def.MatchType := MatchType;
  Def.DeleteAction := DeleteAction;
  Def.UpdateAction := UpdateAction;
end; // Add


//------------------------------------------------------------------------------
// Delete ForeignKeyDef
//------------------------------------------------------------------------------
procedure TACRForeignKeyDefs.DeleteForeignKeyDef(const Name: WideString);
var i: Integer;
begin
  i := IndexOf(Name);
  if (i >= 0) then
   Delete(i)
  else
   raise EACRException.Create(11396, ErrorLForeignKeyDefNotFound, [Name]);
end; // DeleteForeignKeyDef


//------------------------------------------------------------------------------
// Delete
//------------------------------------------------------------------------------
procedure TACRForeignKeyDefs.Delete(const Index: Integer);
begin
  if (Index < 0) or (Index >= FDefsList.Count) then
   raise EACRException.Create(11397,ErrorLInvalidItemNumber,[Index,FDefsList.Count]);
  TACRForeignKeyDef(FDefsList[Index]).Free;
  FDefsList.Delete(Index);
end; // Delete


//------------------------------------------------------------------------------
// Find
//------------------------------------------------------------------------------
function TACRForeignKeyDefs.Find(const Name: WideString): TACRForeignKeyDef;
var i: Integer;
begin
  Result := nil;
  i := IndexOf(Name);
  if (i >= 0) then
   Result := FDefsList[i];
end; // Find


//------------------------------------------------------------------------------
// IndexOf
//------------------------------------------------------------------------------
function TACRForeignKeyDefs.IndexOf(const Name: WideString): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FDefsList.Count - 1 do
   if (AnsiUpperCase(TACRForeignKeyDef(FDefsList[i]).Name) = AnsiUpperCase(Name)) then
    begin
     Result := i;
     break;
    end;
end; // IndexOf


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRForeignKeyDefs.Clear;
var i: Integer;
begin
  for i:=0 to FDefsList.Count-1 do
    TACRForeignKeyDef(FDefsList[i]).Free;
  FDefsList.Clear;
end; // Clear


////////////////////////////////////////////////////////////////////////////////
//
// TACRBlobStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TACRBlobStream.InternalSetSize(const NewSize: Int64);
begin
 FBlobStream.Size := NewSize;
 if (FBlobStream.Size = NewSize) then
  FBlobStream.Modified := True;
end; // InternalSetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TACRBlobStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TACRBlobStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRBlobStream.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FBlobStream.Read(Buffer,Count);
end; // Read


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRBlobStream.Write(const Buffer; Count: Longint): Longint;
begin
 Result := FBlobStream.Write(Buffer,Count);
 if (Result > 0) then
   FBlobStream.Modified := True;
end; // Write


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRBlobStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 Result := FBlobStream.Seek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TACRBlobStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 Result := FBlobStream.Seek(Offset,Origin);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
constructor TACRBlobStream.Create(Field: TBlobField; Mode: TBlobStreamMode);
begin
 if ((Mode <> bmRead) and (TACRDataset(Field.DataSet).ReadOnly)) then
  raise EACRException.Create(10106,ErrorLDatasetIsInReadOnlyMode);
 if (not (Field.DataSet is TACRDataset)) then
  raise EACRException.Create(11633,ErrorLNotACRDataset);
 FDataset := TACRDataset(Field.DataSet);
 FDataSet.Handle.CurrentRecordBuffer := FDataSet.GetActiveRecordBuffer;

 FBlobStream := TACRDataset(Field.DataSet).InternalCreateBlobStream(
  Field.DataSet.FieldByName(Field.FieldName),Mode);
 BlockSize := FBlobStream.BlockSize;
 TACRLocalBlobStream(FBlobStream).UserBlobStream := Self;
 FField := Field;
 FBlobStream.Modified := False;
 if (Mode = bmWrite) then
  Truncate;
 FWideMemo := TACRDataset(Field.DataSet).IsWideMemoField(Field);
{
 if ((Self.Size > 0) and (FWideMemo)) then
  begin
   // convert from wide memo to AnsiString
   StrSize := Self.Size;
   SetLength(ws,StrSize div 2);
   OpenMode := TACRLocalBLOBStream(FBLOBStream).OpenMode;
   try
     TACRLocalBLOBStream(FBLOBStream).OpenMode := bomReadWrite;
     Self.Position := 0;
     Self.ReadBuffer(PWideChar(@ws[1])^,StrSize);
     FBLOBStream.Size := 0;
     SetLength(s,StrSize div 2);
     s := WideCharTOString(PWideChar(@ws[1]));
//     for i := 1 to StrSize div 2 do
//      s[i] := WideCharToAnsiChar(ws[i]);
     FBlobStream.WriteBuffer(PAnsiChar(@s[1])^,StrSize div 2);
   finally
//     MemoryManager.FreeAndNilMem(buf);
     TACRLocalBLOBStream(FBLOBStream).OpenMode := OpenMode ;
   end;
  end; // WideMemo
}
end; // Create


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
destructor TACRBlobStream.Destroy;
begin
 Modified := FBlobStream.Modified;
 TACRLocalBlobStream(FBlobStream).UserBlobStream := nil;
{
 if (Modified) then
  if ((Self.Size > 0) and (FWideMemo)) then
   begin
     // convert from wide memo to AnsiString
     StrSize := Self.Size;
     buf := MemoryManager.GetMem(StrSize * 2);
     OpenMode := TACRLocalBLOBStream(FBLOBStream).OpenMode;
     try
       TACRLocalBLOBStream(FBLOBStream).OpenMode := bomReadWrite;
       Self.Position := 0;
       SetLength(s,StrSize);
       Self.ReadBuffer(PAnsiChar(@s[1])^,StrSize);
       FBLOBStream.Size := 0;
       StringToWideChar(s,buf,StrSize*2);
       FBlobStream.WriteBuffer(buf^,StrSize*2);
     finally
       MemoryManager.FreeAndNilMem(buf);
       TACRLocalBLOBStream(FBLOBStream).OpenMode := OpenMode ;
     end;
   end; // WideMemo
}   
 FDataset.CloseBlob(FField);

 if (Modified) then
  begin
   FField.Modified := True;
   try
     FDataSet.DataEvent(deFieldChange, Longint(FField));
   except
     {$IFDEF D6H}
     ApplicationHandleException(Self);
     {$ELSE}
     Application.HandleException(Self)
     {$ENDIF}
   end;
  end;
 inherited;
end; // Destroy


//------------------------------------------------------------------------------
// truncate
//------------------------------------------------------------------------------
procedure TACRBlobStream.Truncate;
begin
 Size := Position;
end; // Truncate


////////////////////////////////////////////////////////////////////////////////
//
// TACRBatchMove
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// SetMappings
//------------------------------------------------------------------------------
procedure TACRBatchMove.SetMappings(Value: TStrings);
begin
  FMappings.Assign(Value);
end;// SetMappings


//------------------------------------------------------------------------------
// SetSource
//------------------------------------------------------------------------------
procedure TACRBatchMove.SetSource(Value: TACRDataset);
begin
  FSource := Value;
  if Value <> nil then Value.FreeNotification(Self);
end;// SetSource


//------------------------------------------------------------------------------
// Notification
//------------------------------------------------------------------------------
procedure TACRBatchMove.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if Destination = AComponent then Destination := nil;
    if Source = AComponent then Source := nil;
  end;
end;// Notification


//------------------------------------------------------------------------------
// progress event
//------------------------------------------------------------------------------
procedure TACRBatchMove.DoOnProgress(
                        Progress:   Double;
                        var Abort:  Boolean
                       );
var Operation: TACRTableOperation;
begin
 case FMode of
  batAppend: Operation := tbopBatchAppend;
  batUpdate: Operation := tbopBatchUpdate;
  batAppendUpdate: Operation := tbopBatchAppendUpdate;
  batCopy: Operation := tbopBatchCopy;
  batDelete: Operation := tbopBatchDelete;
 end;
 if (Assigned(FOnProgress)) then
  FOnProgress(Self,Progress,Operation,Abort);
end; // DoOnProgress


//------------------------------------------------------------------------------
// Copy records
//------------------------------------------------------------------------------
procedure TACRBatchMove.CopyRecords(BatchMode:    TACRBatchMode;
                                    FieldCount:   Integer;
                                    SourceFields: array of Integer;
                                    DestFields:   array of Integer
                                    );
var
    CurRecNo: Int64;
    d,MaxRec: Double;
    Abort:    Boolean;

  procedure DoAbort;
  begin
{$IFNDEF SQLMEMTABLE}
   if (FUseTransactions) then
    if (FDestination.Database.InTransaction) then
     FDestination.Database.Rollback;
{$ENDIF}
  end; // DoAbort


  procedure WriteToProblemTable;
  var i: Integer;
  begin
   Inc(FProblemCount);
   if (FProblemTable <> nil) then
    begin
     FProblemTable.Insert;
     for i := 0 to FSource.FieldCount - 1 do
      if (FSource.Fields[i] is TLargeintField) then
       begin
        if (not FSource.Fields[i].IsNull) then
         TLargeintField(FProblemTable.Fields[i]).AsLargeInt :=
          TLargeintField(FSource.Fields[i]).AsLargeInt;
       end
      else
       FProblemTable.Fields[i].Assign(Source.Fields[i]);
     FProblemTable.Post;
    end;
  end; // WriteToProblemTable


  procedure WriteToChangedTable;
  var i: Integer;
  begin
   Inc(FChangedCount);
   if (FChangedTable <> nil) then
    begin
     FChangedTable.Insert;
     for i := 0 to FDestination.FieldCount - 1 do
      if (FDestination.Fields[i] is TLargeintField) then
       begin
        if (not FDestination.Fields[i].IsNull) then
         TLargeintField(FChangedTable.Fields[i]).AsLargeInt :=
          TLargeintField(FDestination.Fields[i]).AsLargeInt;
       end
      else
       FChangedTable.Fields[i].Assign(Destination.Fields[i]);
     FChangedTable.Post;
    end;
  end; // WriteToChangedTable


  procedure WriteToKeyViolTable;
  var i: Integer;
  begin
   Inc(FKeyViolCount);
   if (FKeyViolTable <> nil) then
    begin
     FKeyViolTable.Insert;
     for i := 0 to FSource.FieldCount - 1 do
      if (FSource.Fields[i] is TLargeintField) then
       begin
        if (not FSource.Fields[i].IsNull) then
         TLargeintField(FKeyViolTable.Fields[i]).AsLargeInt :=
          TLargeintField(FSource.Fields[i]).AsLargeInt;
       end
      else
       FKeyViolTable.Fields[i].Assign(Source.Fields[i]);
     FKeyViolTable.Post;
    end;
  end; // WriteToKeyViolTable


  function WriteToDestination: Boolean;
  var i: Integer;
  begin
   Result := True;
   try
     for i := 0 to FSource.FieldCount - 1 do
      if (FSource.Fields[i] is TLargeintField) then
       begin
        if (not FSource.Fields[i].IsNull) then
         begin
          TLargeintField(FDestination.Fields[i]).AsLargeInt :=
           TLargeintField(FSource.Fields[i]).AsLargeInt;
          if (TLargeintField(FDestination.Fields[i]).AsLargeInt <>
              TLargeintField(FSource.Fields[i]).AsLargeInt) then
           begin
            Result := False;
            Exit;
           end;
         end;
       end
      else
       begin
        FDestination.Fields[i].Assign(FSource.Fields[i]);
        // fixed in v.4.80 - no need to compare blob values as variant
        if (not FDestination.Fields[i].IsBlob) then
          if (FDestination.Fields[i].Value <> FSource.Fields[i].Value) then
           begin
            Result := False;
            Exit;
           end;
       end;
   except
     Result := False;
   end;
  end; // WriteToDestination


  procedure DoAppend;
  begin
   Destination.Insert;
   if (not WriteToDestination) then
    begin
     if (FAbortOnProblem) then
      DatabaseError(ErrorLBatchMoveAbortOnProblem,Self)
     else
      begin
       WriteToProblemTable;
       Destination.Cancel;
       Exit;
      end;
    end;
   try
     Destination.Post;
     Inc(FMovedCount);
   except
     on e: Exception do
      if (FAbortOnKeyViol) then
       DatabaseError(ErrorLBatchMoveAbortOnKeyViol+e.Message,Self)
      else
       begin
        Destination.Cancel;
        WriteToKeyViolTable;
       end;
   end;
  end; // DoAppend


  procedure DoAppendUpdateOrUpdate(DoAppendUpdate: Boolean);
  var i,j,SourceFieldNo,DestFieldNo:  Integer;
      DestField:                      TField;
      bUpdate:                        Boolean;
  begin
    Destination.SetKey;
    for i := 0 to Destination.IndexFieldCount-1 do
     begin
      DestField := Destination.GetIndexField(i);
      DestFieldNo := DestField.FieldNo - 1;
      SourceFieldNo := -1;
      for j := 0 to FieldCount-1 do
       if (DestFields[j] = DestFieldNo) then
        begin
         SourceFieldNo := SourceFields[j];
         break;
        end;
      if (SourceFieldNo > -1) then
       if (not FSource.Fields[SourceFieldNo].IsNull) then
         begin
          if (DestField is TLargeintField) then
           TLargeIntField(DestField).AsLargeInt :=
            TLargeIntField(FSource.Fields[SourceFieldNo]).AsLargeInt
          else
           DestField.Assign(FSource.Fields[SourceFieldNo]);
         end;
     end; // scan all index fields in Destination and set key values
    bUpdate := Destination.GotoKey;
    if (bUpdate) then
     begin
      WriteToChangedTable;
      Destination.Edit;
     end
    else
     begin
      if (DoAppendUpdate) then
       Destination.Insert
      else
       Exit; // do nothing
     end;
    if (not WriteToDestination) then
     begin
       if (FAbortOnProblem) then
        DatabaseError(ErrorLBatchMoveAbortOnProblem,Self)
       else
        begin
         WriteToProblemTable;
         Destination.Cancel;
         Exit;
        end;
     end;
    try
     Destination.Post;
     Inc(FMovedCount);
    except
     on e: Exception do
      if (FAbortOnKeyViol) then
       DatabaseError(ErrorLBatchMoveAbortOnKeyViol+e.Message,Self)
      else
       begin
        Destination.Cancel;
        WriteToKeyViolTable;
       end;
    end;
  end; // DoAppendUpdateOrUpdate


  // AJBchanges - added in v.5.30
  procedure DoDelete;
  var i,j,SourceFieldNo,DestFieldNo:  Integer;
      DestField:                      TField;
{
  var i:                              Integer;
      SourceField:                    TField;
      KeyFields:                      AnsiString;
      KeyValues:                      variant;
}      
  begin
    Destination.SetKey;
    for i := 0 to Destination.IndexFieldCount-1 do
     begin
      DestField := Destination.GetIndexField(i);
      DestFieldNo := DestField.FieldNo - 1;
      SourceFieldNo := -1;
      for j := 0 to FieldCount-1 do
       if (DestFields[j] = DestFieldNo) then
        begin
         SourceFieldNo := SourceFields[j];
         break;
        end;
      if (SourceFieldNo > -1) then
       if (not FSource.Fields[SourceFieldNo].IsNull) then
        begin
         if (DestField is TLargeintField) then
          TLargeIntField(DestField).AsLargeInt :=
            TLargeIntField(FSource.Fields[SourceFieldNo]).AsLargeInt
         else
          DestField.Assign(FSource.Fields[SourceFieldNo]);
        end;
     end; // scan all index fields in Destination and set key values
    if Destination.GotoKey then
     begin
      try
        WriteToChangedTable;
        Destination.Delete;
        Inc(FMovedCount);
      except
       on e: Exception do
        if (FAbortOnKeyViol) then
          DatabaseError(ErrorLBatchMoveAbortOnKeyViol+e.Message,Self)
        else
          WriteToKeyViolTable;
      end;
     end; 
{
    KeyValues := VarArrayCreate([0,(FieldCount-1)],varVariant);
    KeyFields := '';
    for i := 0 to FieldCount-1 do
     begin
      SourceField := FSource.Fields[SourceFields[i]];
      KeyValues[i] := SourceField.AsVariant;
      if (KeyFields = '') then
       KeyFields := FDestination.Fields[DestFields[i]].FieldName
      else
       KeyFields := KeyFields + ';'+FDestination.Fields[DestFields[i]].FieldName;
     end;
    if (Destination.LocateRecord(KeyFields,KeyValues,[])) then
     begin
      try
       WriteToChangedTable;
       Destination.Delete;
       Inc(FMovedCount);
      except
       on e: Exception do
        if (FAbortOnKeyViol) then
         DatabaseError(ErrorLBatchMoveAbortOnKeyViol+e.Message,Self)
        else
         WriteToKeyViolTable;
      end;
     end;
}
  end; // DoDelete


  function IsBatchmoveComplete: Boolean;
  begin
   Result := (Source.Eof) or ((CurRecNo >= FRecordCount) and (FRecordCount > 0));
  end;

begin
  CurRecNo := 0;
  Abort := False;
{
  Source.First;
  if (FRecordCount > 0) then
   MaxRec := FRecordCount
  else
   MaxRec := Source.RecordCount;
}
  // fixed in v.4.80
  if (FRecordCount > 0) then
   MaxRec := FRecordCount
  else
   begin
    MaxRec := Source.RecordCount;
    Source.First;
   end;
  FMovedCount := 0;
  FProblemCount := 0;
  FKeyViolCount := 0;
  FChangedCount := 0;
  while (not IsBatchmoveComplete) do
   begin
{$IFNDEF SQLMEMTABLE}
    if (FUseTransactions and (not FDestination.Database.InTransaction)) then
      FDestination.Database.StartTransaction;
{$ENDIF}
    case (BatchMode) of
     batAppend:        DoAppend;
     batAppendUpdate:  DoAppendUpdateOrUpdate(True);
     batUpdate:        DoAppendUpdateOrUpdate(False);
     batDelete:        DoDelete;
    end;
    Source.Next;
    Inc(CurRecNo);
    // commit if necessary
{$IFNDEF SQLMEMTABLE}
    if (FUseTransactions) then
     if (FCommitCount > 0) then
      if ((CurRecNo mod FCommitCount) = 0) then
        FDestination.Database.Commit(IsBatchmoveComplete);
{$ENDIF}
    // display progress
    d := CurRecNo / MaxRec;
    DoOnProgress(d,Abort);
    if (Abort) then
     begin
      DoAbort;
      Exit;
     end;
   end; // perform batch move
{$IFNDEF SQLMEMTABLE}
 if (FUseTransactions) then
  if (FDestination.Database.InTransaction) then
   FDestination.Database.Commit(True);
{$ENDIF}
end; // CopyRecords


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRBatchMove.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAbortOnKeyViol := True;
  FAbortOnProblem := True;
  FRecordCount := 0;
{$IFNDEF SQLMEMTABLE}
  FUseTransactions := True;
  FCommitCount := ACRDefaultCommitCount;
{$ENDIF}
  FMappings := TStringList.Create;
  FProblemTableName := '';
  FKeyViolTableName := '';
  FChangedTableName := '';
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRBatchMove.Destroy;
begin
  FMappings.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRBatchMove.Execute;
var
  SourceActive, DestinationActive: Boolean;
  BatchMode:                       TACRBatchMode;
  i, FieldCount:                   Integer;
  SourceFields,DestFields:         array of Integer;
  DestName, SourceName:            AnsiString;
  SourceCursorPos:                 Pointer;

  procedure GetMappingNames;
  var
    P:        Integer;
    Mapping:  AnsiString;
  begin
    Mapping := FMappings[I];
    P := Pos('=', Mapping);
    if P > 0 then
     begin
      DestName := Copy(Mapping, 1, P - 1);
      SourceName := Copy(Mapping, P + 1, 255);
     end
    else
     begin
      DestName := Mapping;
      SourceName := Mapping;
     end;
  end; // GetMappingNames


  procedure CreateProblemTable;
  begin
    FProblemTable := TACRTable.Create(Self);
    FProblemTable.DatabaseName := Destination.DatabaseName;
    FProblemTable.InMemory := Destination.InMemory;
    FProblemTable.TableName := FProblemTableName;
    FProblemTable.FExclusive := True;
    FProblemTable.AdvFieldDefs.Assign(Source.AdvFieldDefs);
    FProblemTable.CreateTable;
    FProblemTable.Open;
  end; // CreateProblemTable


  procedure CreateKeyViolTable;
  begin
    FKeyViolTable := TACRTable.Create(Self);
    FKeyViolTable.DatabaseName := Destination.DatabaseName;
    FKeyViolTable.InMemory := Destination.InMemory;
    FKeyViolTable.TableName := FKeyViolTableName;
    FKeyViolTable.FExclusive := True;
    FKeyViolTable.AdvFieldDefs.Assign(Source.AdvFieldDefs);
    FKeyViolTable.CreateTable;
    FKeyViolTable.Open;
  end; // CreateProblemTable


  procedure CreateChangedTable;
  begin
    FChangedTable := TACRTable.Create(Self);
    FChangedTable.DatabaseName := Destination.DatabaseName;
    FChangedTable.InMemory := Destination.InMemory;
    FChangedTable.TableName := FChangedTableName;
    FChangedTable.FExclusive := True;
    FChangedTable.AdvFieldDefs.Assign(Destination.AdvFieldDefs);
    FChangedTable.CreateTable;
    FChangedTable.Open;
  end; // CreateChangedTable


begin
  if ((Destination = nil) or (Source = nil) or (Destination = Source)) then
    DatabaseError(ErrorLInvalidBatchMove, Self);
{$IFNDEF SQLMEMTABLE}
  if (FUseTransactions and (CommitCount <= 0)) then
    DatabaseError(ErrorLInvalidBatchMoveCommitCount, Self);
{$ENDIF}
  SourceActive := Source.Active;
  DestinationActive := Destination.Active;
  SourceFields := nil;
  DestFields := nil;
  FProblemTable := nil;
  FChangedTable := nil;
  FKeyViolTable := nil;
  BatchMode := FMode;
  try
    Source.DisableControls;
    Destination.DisableControls;
    if (not SourceActive) then
      Source.Open;
    Source.CheckBrowseMode;
    Source.UpdateCursorPos;
    if (SourceActive) then
     SourceCursorPos := Source.Handle.SavePosition;
    if (BatchMode = batCopy) then
     begin
      Destination.Close;
      if (FMappings.Count = 0) then
        Destination.AdvFieldDefs.Assign(Source.AdvFieldDefs)
      else
       begin
        Destination.AdvFieldDefs.Clear;
        for I := 0 to FMappings.Count - 1 do
         begin
          GetMappingNames;
          with Source.AdvFieldDefs.Find(SourceName) do
            Destination.AdvFieldDefs.Add(DestName, DataType, Size, Required);
         end;
      end;
      Destination.IndexDefs.Clear;
      // fixed in v.4.80
      // Destination.IndexDefs.Assign(Source.IndexDefs);
      Destination.IndexDefsAssign(Source.IndexDefs,Destination.IndexDefs);
      Destination.FieldDefs.Clear;
      Destination.ForeignKeyDefs.Assign(Source.ForeignKeyDefs);
      Destination.CreateTable;
      BatchMode := batAppend;
     end; // Copy
    Destination.Open;
    Destination.CheckBrowseMode;
    Destination.UpdateCursorPos;
    if ((FMode = batAppendUpdate) or (FMode = batUpdate)) then
     if (Destination.IndexFieldCount <= 0) then
      DatabaseError(ErrorLInvalidBatchMoveDestIndex,Self);
    FieldCount := Destination.AdvFieldDefs.Count;
    // fixed in v.5.30 - fieldCount is minimum between source and destination
    if (FieldCount > Source.AdvFieldDefs.Count) then
     FieldCount := Source.AdvFieldDefs.Count;
    if (FProblemTableName <> '') then
     CreateProblemTable;
    if (FKeyViolTableName <> '') then
     CreateKeyViolTable;
    if (FChangedTableName <> '') then
     CreateChangedTable;
    SetLength(SourceFields, FieldCount);
    SetLength(DestFields, FieldCount);
    if (FMappings.Count <> 0) then
     begin
      for i := 0 to FMappings.Count - 1 do
       begin
        GetMappingNames;
        SourceFields[i] := Source.FieldDefs.Find(SourceName).FieldNo-1;
        DestFields[i] := Destination.FieldDefs.Find(DestName).FieldNo-1;
       end;
     end
    else
     begin
      for i := 0 to FieldCount-1 do
       begin
        SourceFields[i] := i;
        DestFields[i] := i;
       end;
     end;
{$IFNDEF SQLMEMTABLE}
    if (FUseTransactions) then
     Destination.Database.StartTransaction;
{$ENDIF}
    try
     try
      CopyRecords(BatchMode,FieldCount,SourceFields,DestFields);
     except
{$IFNDEF SQLMEMTABLE}
      if (FUseTransactions) then
       if (Destination.Database.InTransaction) then
        Destination.Database.Rollback;
{$ENDIF}
      raise;
     end;
    finally
      SourceFields := nil;
      DestFields := nil;
      if (DestinationActive) then
        Destination.First;
      if (SourceActive) then
       begin
        Source.Handle.RestorePosition(SourceCursorPos);
        Source.Handle.FreePosition(SourceCursorPos);
        Source.UpdateCursorPos;
       end;
    end;
  finally
    if (not DestinationActive) then
      Destination.Close;
    if (not SourceActive) then
      Source.Close;
    if (FProblemTable <> nil) then
     FProblemTable.Free;
    if (FChangedTable <> nil) then
     FChangedTable.Free;
    if (FKeyViolTable <> nil) then
     FKeyViolTable.Free;
    Destination.EnableControls;
    Source.EnableControls;
  end;
end;// Execute

(*
////////////////////////////////////////////////////////////////////////////////
//
// TACRAntifreeze
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRAntifreeze.Create(Owner: TComponent);
begin
  inherited Create(Owner);
  FOwner := Owner;
  FActive := True;
  FTimeOut := ACRAntifreezeTimeOut;
  FSleep := ACRAntifreezeSleep;
  FAntifreezeThread := TACRAntifreezeThread.Create(Self);
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRAntifreeze.Destroy;
begin
  FAntifreezeThread.Terminate;
  inherited Destroy;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TACRAntifreezeThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRAntifreezeThread.Create(Owner: TACRAntifreeze);
begin
  FOwner := Owner;
  inherited Create(False);
  FRecreate := True;
  Priority := tpNormal;
  FreeOnTerminate := True;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRAntifreezeThread.Destroy;
begin
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRAntifreezeThread.Execute;
var
  StartTime:              DWORD;
begin
 try
  repeat
    StartTime := GetTickCount;
    while (GetTickCount < (StartTime + FOwner.TimeOut)) do
     begin
      if Self.IsTerminated then
       begin
        FRecreate := False;
        Exit;
       end;
      sleep(FOwner.Sleep);
     end;
    if FOwner.Active then
     begin
aaWriteToLog('TACRAntifreezeThread> ProcessMessages...');
      Synchronize(Process);
aaWriteToLog('TACRAntifreezeThread> ProcessMessages - ok');
//      if FOwner.FOwner is TForm then
//        TForm(FOwner.FOwner).Show;
//  //      TForm(FOwner.FOwner).Refresh;
     end;
  until False;
 except
 end;
end;// Execute


//------------------------------------------------------------------------------
// Process
//------------------------------------------------------------------------------
procedure TACRAntifreezeThread.Process;
begin
aaWriteToLog('TACRAntifreezeThread> Process - Synchronized!');
  Application.ProcessMessages;
end; // Process
*)


////////////////////////////////////////////////////////////////////////////////
//
// Global functions
//
////////////////////////////////////////////////////////////////////////////////


procedure ACRFixForeignKeysSelfReferences(TableName, NewTableName: WideString; ForeignKeyDefs: TACRForeignKeyDefs);
var i:       Integer;
    s:       WideString;
begin
  s := WideUpperCase(TableName);
  for i := 0 to ForeignKeyDefs.Count - 1 do
   begin
    if (s = WideUpperCase(ForeignKeyDefs.Items[i].ReferencedTableName)) then
     ForeignKeyDefs.Items[i].ReferencedTableName := NewTableName;
   end;
end; // ACRFixForeignKeysSelfReferences


//------------------------------------------------------------------------------
// convert foreign keys to constraint defs
//------------------------------------------------------------------------------
procedure ACRConvertForeignKeyDefToConstraintDef(
            ForeignKeyDef: TACRForeignKeyDef;
            ConstraintDef: TACRConstraintDefForeignKey
                            );
var j:       Integer;
    sl:      TACRWideStringList;
begin
  sl := TACRWideStringList.Create;
  try
    ConstraintDef.Name := ForeignKeyDef.Name;
    ConstraintDef.ReferencedTableName := ForeignKeyDef.ReferencedTableName;
    ConstraintDef.ObjectID := INVALID_OBJECT_ID;
    ConstraintDef.MatchType := TACRConstraintForeignKeyMatchType(Byte(ForeignKeyDef.MatchType));
    ConstraintDef.DeleteAction := TACRConstraintForeignKeyAction(Byte(ForeignKeyDef.DeleteAction));
    ConstraintDef.UpdateAction := TACRConstraintForeignKeyAction(Byte(ForeignKeyDef.UpdateAction));
    sl.Clear;
    GetNamesList(sl,ForeignKeyDef.Columns);
    if (sl.Count <= 0) then
     raise EACRException.Create(11418,ErrorLNoColumnsInForeignKeyDefinition,[ForeignKeyDef.Name,ForeignKeyDef.ReferencedTableName]);
    SetLength(ConstraintDef.Columns,sl.Count);
    for j := 0 to sl.Count - 1 do
     begin
      ConstraintDef.Columns[j].ColumnName := sl.Strings[j];
      ConstraintDef.Columns[j].ColumnObjectID := INVALID_OBJECT_ID;
     end;
  finally
    sl.Free;
  end;
end; // ACRConvertForeignKeyDefToConstraintDef


//------------------------------------------------------------------------------
// convert foreign keys to constraint defs
//------------------------------------------------------------------------------
procedure ACRConvertForeignKeyDefsToConstraintDefs(
            ForeignKeyDefs: TACRForeignKeyDefs;
            ConstraintDefs: TACRConstraintDefs
            );
var i:      Integer;
    FKDef:  TACRForeignKeyDef;
    FK:     TACRConstraintDefForeignKey;
begin
    for i := 0 to ForeignKeyDefs.Count - 1 do
     begin
      FKDef := ForeignKeyDefs.Items[i];
      FK := ConstraintDefs.AddFK;
      ACRConvertForeignKeyDefToConstraintDef(FKDef,FK);
     end;
end; // ConvertForeignKeyDefsToConstraintDefs



//------------------------------------------------------------------------------
// convert constraint defs to foreign keys
//------------------------------------------------------------------------------
procedure ConvertConstraintDefsToForeignKeyDefs(
            ConstraintDefs:     TACRConstraintDefs;
            ForeignKeyDefs:     TACRForeignKeyDefs;
            ClearForeignKeys:   Boolean
            );
var i,j:    Integer;
    FKDef:  TACRForeignKeyDef;
    FK:     TACRConstraintDefForeignKey;
begin
  if (ClearForeignKeys) then
    ForeignKeyDefs.Clear;
  for i := 0 to ConstraintDefs.Count - 1 do
   if (ConstraintDefs.Items[i].ConstraintType = ctFK) then
    begin
      FK := TACRConstraintDefForeignKey(ConstraintDefs.Items[i]);
      FKDef := ForeignKeyDefs.AddForeignKeyDef;
      FKDef.Name := FK.Name;
      FKDef.ReferencedTableName := FK.ReferencedTableName;
      FKDef.MatchType := TACRForeignKeyMatchType(Byte(FK.MatchType));
      FKDef.DeleteAction := TACRForeignKeyAction(Byte(FK.DeleteAction));
      FKDef.FUpdateAction := TACRForeignKeyAction(Byte(FK.UpdateAction));
      FKDef.Columns := '';
      for j := 0 to High(FK.Columns) do
       if (FKDef.Columns = '') then
        FKDef.Columns := FK.Columns[j].ColumnName
       else
        FKDef.Columns := FKDef.Columns + ';' + FK.Columns[j].ColumnName;
    end;
end; // ConvertForeignKeyDefsToConstraintDefs


//------------------------------------------------------------------------------
// convert TFieldDefs to ACRFieldDefs
//------------------------------------------------------------------------------
procedure ConvertFieldDefsToACRFieldDefs(
                FieldDefs:      TFieldDefs;
                ACRFieldDefs:   TACRFieldDefs
                                        );
var i:         Integer;
    FieldDef:  TACRFieldDef;
begin
 ACRFieldDefs.Clear;
 for i := 0 to FieldDefs.Count-1 do
  begin
   FieldDef := ACRFieldDefs.AddCreated;
   FieldDef.Name := FieldDefs[i].Name;
   if (FieldDefs[i].Datatype = ftGuid) then
   begin
     FieldDef.SetFieldDefDataType(
      aftChar,
      ACR_GUID_LENGTH
                               );
   end
   else
     FieldDef.SetFieldDefDataType(
      FieldTypeToACRAdvFieldType(FieldDefs[i].DataType),
      FieldDefs[i].Size
                               );
  end;
end; // ConvertFieldDefsToACRFieldDefs



//------------------------------------------------------------------------------
// convert AdvFieldDefs to FieldDefs
//------------------------------------------------------------------------------
procedure ConvertAdvFieldDefsToFieldDefs(AdvFieldDefs: TACRAdvFieldDefs; FieldDefs: TFieldDefs);
var
  i: Integer;
  FieldDef: TFieldDef;
begin
  FieldDefs.Clear;
  for i:=0 to AdvFieldDefs.Count-1 do
   begin
    FieldDef := FieldDefs.AddFieldDef;
    FieldDef.Name := AdvFieldDefs[i].Name;
    FieldDef.DataType := ACRAdvFieldTypeToFieldType(AdvFieldDefs[i].DataType);
    FieldDef.Size := AdvFieldDefs[i].Size;
    //FieldDef.Precision := AdvFieldDefs[i].Precision;
    FieldDef.Required := AdvFieldDefs[i].Required;
    //FieldDef.FieldNo := i + 1;
   end;
end;

//------------------------------------------------------------------------------
// convert FieldDefs to AdvFieldDefs
//------------------------------------------------------------------------------
procedure ConvertFieldDefsToAdvFieldDefs(FieldDefs: TFieldDefs; AdvFieldDefs: TACRAdvFieldDefs);
var
  i: Integer;
  AdvFieldDef: TACRAdvFieldDef;
begin
  AdvFieldDefs.Clear;
  for i:=0 to FieldDefs.Count-1 do
   begin
    AdvFieldDef := AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := FieldDefs[i].Name;
    AdvFieldDef.DataType := FieldTypeToACRAdvFieldType(FieldDefs[i].DataType);
    if (FieldDefs[i].DataType = ftGuid) then
    begin
      AdvFieldDef.Size := ACR_GUID_LENGTH;
      AdvFieldDef.DataType := aftChar;
    end
    else
      AdvFieldDef.Size := FieldDefs[i].Size;
    //AdvFieldDef.Precision := FieldDefs[i].Precision;
    AdvFieldDef.Required := FieldDefs[i].Required;
   end;
end;

//------------------------------------------------------------------------------
// convert AdvFieldDefs to ACRFieldDefs
//------------------------------------------------------------------------------
procedure ConvertAdvFieldDefsToACRFieldDefs(
                AdvFieldDefs:      TACRAdvFieldDefs;
                ACRFieldDefs:      TACRFieldDefs;
                IndexDefs:         TACRIndexDefs;
                ACRConstraintDefs: TACRConstraintDefs;
                Temporary:         Boolean
                                        );
var i: Integer;
    FieldDef: TACRFieldDef;
begin
 // Clear Lists
 ACRFieldDefs.Clear;
 ACRConstraintDefs.Clear;

 // Fill ACRFieldDefs
 for i := 0 to AdvFieldDefs.Count-1 do
  begin
   // Fill ACRFieldDefs
   FieldDef := ACRFieldDefs.AddCreated;
   FieldDef.Name := AdvFieldDefs[i].Name;
   FieldDef.SetFieldDefDataType(
      AdvFieldDefs[i].DataType,
      AdvFieldDefs[i].Size
                               );

   // added in v.5.30                            
   if (FieldDef.FieldSize <= 0) then
    if ((IsStringFieldType(FieldDef.BaseFieldType)) and
        (not IsBLOBFieldType(FieldDef.BaseFieldType))) then
     FieldDef.FieldSize := ACR_DEFAULT_STRING_SIZE_FOR_CREATE_TABLE;

   FieldDef.AutoincIncrement := AdvFieldDefs[i].AutoincIncrement;
   FieldDef.AutoincInitialValue := AdvFieldDefs[i].AutoincInitialValue;
   FieldDef.AutoincMinValue  := AdvFieldDefs[i].AutoincMinValue;
   FieldDef.AutoincMaxValue  := AdvFieldDefs[i].AutoincMaxValue;
   FieldDef.AutoincCycled    := AdvFieldDefs[i].AutoincCycled;

   FieldDef.DefaultValue.Assign(AdvFieldDefs[i].DefaultValue);

   FieldDef.BlobCompressionAlgorithm :=
     ConvertCompressionAlgorithmToACRCompressionAlgorithm(
      AdvFieldDefs[i].BlobCompressionAlgorithm);
   FieldDef.BlobCompressionMode := AdvFieldDefs[i].BlobCompressionMode;
   FieldDef.BlobBlockSize := AdvFieldDefs[i].BlobBlockSize;


   if (not Temporary) then
    begin
     if (AdvFieldDefs[i].Required) then
       ACRConstraintDefs.AddNotNull.ColumnName := AdvFieldDefs[i].Name;

     // Fill ACRConstraintDefs Check
     if ((not AdvFieldDefs[i].MinValue.IsNull) or (not AdvFieldDefs[i].MaxValue.IsNull)) then
      with ACRConstraintDefs.AddCheck do
      begin
        ColumnName := AdvFieldDefs[i].Name;
        MinValue.Assign(AdvFieldDefs[i].MinValue);
        MaxValue.Assign(AdvFieldDefs[i].MaxValue);
      end;
    end;//if

  end;//for

 if (not Temporary) then
   for i := 0 to IndexDefs.Count-1 do
     AddConstraintForIndex(IndexDefs[i], ACRConstraintDefs);

end;//ConvertAdvFieldDefsToACRFieldDefs


//------------------------------------------------------------------------------
// Add Unic or Primary Key constraint
//------------------------------------------------------------------------------
function AddConstraintForIndex(
                                  IndexDef:           TACRIndexDef;
                                  ACRConstraintDefs:  TACRConstraintDefs
                                 ): TACRConstraintDef;
var
  j: Integer;
  ConstraintDefPK: TACRConstraintDefPrimary;
  ConstraintDefUnique: TACRConstraintDefUnique;
begin
  Result := nil;
  if (IndexDef.Primary) then
    begin
     ConstraintDefPK := ACRConstraintDefs.AddPK;
     ConstraintDefPK.IndexName := IndexDef.Name;
     ConstraintDefPK.IndexObjectId := IndexDef.ObjectId;
     ConstraintDefPK.Name := IndexDef.Name;
//     ConstraintDefPK.Name := AutoNameConstraintPKPreffix;

     // Constraint Fields...
     SetLength(ConstraintDefPK.Columns, IndexDef.ColumnCount);
     for j:=0 to IndexDef.ColumnCount-1 do
      begin
       ConstraintDefPK.Columns[j].ColumnName := IndexDef.Columns[j].FieldName;
//       ConstraintDefPK.Name := ConstraintDefPK.Name + AutoNameSymbol +
//                               IndexDef.Columns[j].FieldName;

      end;
     Result := ConstraintDefPK;
    end
   else if (IndexDef.Unique) then
    begin
     ConstraintDefUnique := ACRConstraintDefs.AddUnique;
     ConstraintDefUnique.IndexName := IndexDef.Name;
     ConstraintDefUnique.IndexObjectId := IndexDef.ObjectId;
     ConstraintDefUnique.Name := IndexDef.Name;
//     ConstraintDefUnique.Name :=  AutoNameConstraintUniquePreffix;

     // Constraint Fields...
     SetLength(ConstraintDefUnique.Columns, IndexDef.ColumnCount);
     for j:=0 to IndexDef.ColumnCount-1 do
      begin
       ConstraintDefUnique.Columns[j].ColumnName := IndexDef.Columns[j].FieldName;
//       ConstraintDefUnique.Name := ConstraintDefUnique.Name + AutoNameSymbol +
//                               IndexDef.Columns[j].FieldName;

      end;
     Result := ConstraintDefUnique;
    end;
end;//AddCoustraintFromIndex


//------------------------------------------------------------------------------
// convert ACRFieldDefs to AdvFieldDefs
//------------------------------------------------------------------------------
procedure ConvertACRFieldDefsToAdvFieldDefs(
                VisibleFieldDefs:   TACRFieldDefs;
                ACRFieldDefs:   TACRFieldDefs;
                ACRConstraintDefs: TACRConstraintDefs;
                AdvFieldDefs:   TACRAdvFieldDefs
                                        );
var i,j,k,n:      Integer;
    AdvFieldDef: TACRAdvFieldDef;
begin
 // Clear Lists
 AdvFieldDefs.Clear;

 // Fill AdvFieldDefs
 for i := 0 to VisibleFieldDefs.Count-1 do
  begin
   AdvFieldDef := AdvFieldDefs.AddFieldDef;

   // Fill AdvFieldDefs
   AdvFieldDef.Name := VisibleFieldDefs[i].Name;
   AdvFieldDef.DataType := VisibleFieldDefs[i].AdvancedFieldType;
   AdvFieldDef.Size := VisibleFieldDefs[i].FieldSize;

   AdvFieldDef.AutoincIncrement := VisibleFieldDefs[i].AutoincIncrement;
   AdvFieldDef.AutoincInitialValue := VisibleFieldDefs[i].AutoincInitialValue;
   AdvFieldDef.AutoincMinValue   := VisibleFieldDefs[i].AutoincMinValue;
   AdvFieldDef.AutoincMaxValue  := VisibleFieldDefs[i].AutoincMaxValue;
   AdvFieldDef.AutoincCycled := VisibleFieldDefs[i].AutoincCycled;

   AdvFieldDef.BlobCompressionAlgorithm :=
    ConvertACRCompressionAlgorithmToCompressionAlgorithm(
       VisibleFieldDefs[i].BlobCompressionAlgorithm);
   AdvFieldDef.BlobCompressionMode := VisibleFieldDefs[i].BlobCompressionMode;
   AdvFieldDef.BlobBlockSize := VisibleFieldDefs[i].BlobBlockSize;

   AdvFieldDef.DefaultValue.Assign(VisibleFieldDefs[i].DefaultValue);
  end;

 // Fill Constraints Data
 for i := 0 to ACRConstraintDefs.Count-1 do
  begin
   case ACRConstraintDefs[i].ConstraintType of
     ctNotNull:
       begin
         n := ACRFieldDefs.GetDefNumberByObjectId(
                    TACRConstraintDefNotNull(ACRConstraintDefs[i]).ColumnObjectID);
         if n = -1 then
           raise EACRException.Create(30032, ErrorGFieldWithObjectIdNotFound,
                  [TACRConstraintDefNotNull(ACRConstraintDefs[i]).ColumnObjectID]);
         k := -1;
         for j := 0 to VisibleFieldDefs.Count - 1 do
           if (VisibleFieldDefs[j].FieldNoReference = n) then
            begin
             k := j;
             break;
            end;
         if (k > -1) then
          begin
           // Requared
           AdvFieldDefs[k].FRequired := True;
          end;
       end;
     ctCheck:
       begin
         n := ACRFieldDefs.GetDefNumberByObjectId(
                    TACRConstraintDefCheck(ACRConstraintDefs[i]).ColumnObjectID);
         if n = -1 then
           raise EACRException.Create(30031, ErrorGFieldWithObjectIdNotFound,
                  [TACRConstraintDefCheck(ACRConstraintDefs[i]).ColumnObjectID]);
         k := -1;
         for j := 0 to VisibleFieldDefs.Count - 1 do
           if (VisibleFieldDefs[j].FieldNoReference = n) then
            begin
             k := j;
             break;
            end;
         if (k > -1) then
          begin
           // Min
           AdvFieldDefs[k].MinValue.Assign(TACRConstraintDefCheck(ACRConstraintDefs[i]).MinValue);
           // Max
           AdvFieldDefs[k].MaxValue.Assign(TACRConstraintDefCheck(ACRConstraintDefs[i]).MaxValue);
          end;
       end;
     ctPK,
     ctFK,
     ctFKAction,
     ctUnique: ; // Nothing to do
     else
        raise EACRException.Create(30039, ErrorGNotImplementedYet);
   end;
  end;

end;//ConvertACRFieldDefsToAdvFieldDefs



//------------------------------------------------------------------------------
// convert ACRFieldDefs to TFieldDefs
//------------------------------------------------------------------------------
procedure ConvertACRFieldDefsToFieldDefs(
                ACRFieldDefs:   TACRFieldDefs;
                ACRConstraintDefs:  TACRConstraintDefs;
                FieldDefs:      TFieldDefs
                                        );
var i,j,n,Size: Integer;
    fd:    TFieldDef;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('ConvertACRFieldDefsToFieldDefs start');
{$ENDIF}
 FieldDefs.Clear;
 for i := 0 to ACRFieldDefs.Count-1 do
  begin
   Size := ACRFieldDefs[i].FieldSize;
//   if (IsWideStringFieldType(ACRFieldDefs[i].AdvancedFieldType)) then
//    Size := Size * 2;
   FieldDefs.Add(
                  ACRFieldDefs[i].Name,
                  ACRAdvFieldTypeToFieldType(ACRFieldDefs[i].AdvancedFieldType),
                  Size,
                  False
                );
  end;

 for i := 0 to ACRConstraintDefs.Count-1 do
  if ACRConstraintDefs[i].ConstraintType = ctNotNull then
   begin
    n := TACRConstraintDefNotNull(ACRConstraintDefs[i]).ColumnObjectID;
    j := ACRFieldDefs.GetDefNumberByObjectId(n);
    if j <> -1 then
      begin
        fd := FieldDefs.Find(ACRFieldDefs[j].Name);
        if (fd <> nil) then
          fd.Required := true;
      end;
   end;

{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('ConvertACRFieldDefsToFieldDefs finish');
{$ENDIF}
end; //


//------------------------------------------------------------------------------
// get AnsiString list from AnsiString with names
//------------------------------------------------------------------------------
procedure GetNamesList(List: TACRWideStringList; const Names: WideString);
var
  Pos: Integer;
  NewNames: WideString;
begin
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('> GetNamesList');
{$ENDIF}
  Pos := 1;
  // commented in v.4.90
//  NewNames := StringReplace(Names, ',', ';', [rfReplaceAll]);
  NewNames := ACRReplaceCommaToSemiColonInFieldNameNames(Names);
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('1 GetNamesList');
{$ENDIF}
  if Assigned(List) then
   begin
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('2 GetNamesList');
{$ENDIF}
    List.Clear;
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('3 GetNamesList, l = '+IntToStr(Length(NewNames)));
{$ENDIF}
    while Pos <= Length(NewNames) do
     begin
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('4 GetNamesList, Pos = '+IntToStr(Pos)+', NewNames = '+NewNames);
{$ENDIF}
       List.Add(ExtractFieldName(NewNames, Pos));
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('5 GetNamesList, Pos = '+IntToStr(Pos)+', NewNames = '+NewNames+', List = '+#13#10+List.Text);
{$ENDIF}
     end;
   end;
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('< GetNamesList');
{$ENDIF}
end;// GetNamesList


//------------------------------------------------------------------------------
// replaces 'field1,field2' to 'field1;field2'
//------------------------------------------------------------------------------
function ACRReplaceCommaToSemiColonInFieldNameNames(const Names: WideString): WideString;
var i,l : Integer;
begin
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('> ACRReplaceCommaToSemiColonInFieldNameNames, Names = '+Names);
{$ENDIF}
  Result := '';
  l := Length(Names);
  SetLength(Result,l);
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('1 ACRReplaceCommaToSemiColonInFieldNameNames, l = '+IntToStr(l));
{$ENDIF}
  for i := 1 to l do
   begin
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('2 ACRReplaceCommaToSemiColonInFieldNameNames, i = '+IntToStr(i));
{$ENDIF}
   if (Names[i] = ',') then
    Result[i] := ';'
   else
    Result[i] := Names[i];
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('3 ACRReplaceCommaToSemiColonInFieldNameNames, i = '+IntToStr(i));
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_GetNamesList}
aaWriteToLog('< ACRReplaceCommaToSemiColonInFieldNameNames, Result = '+Result);
{$ENDIF}
end; // ACRReplaceCommaToSemiColonInFieldNameNames


//------------------------------------------------------------------------------
// fill ACRIndexDef
//------------------------------------------------------------------------------
procedure FillACRIndexDef(
              ACRIndexDef:         TACRIndexDef;
              const Name,
              Fields:              WideString;
              Options:             TIndexOptions;
              const DescFields:    WideString;
              const CaseInsFields: WideString;
              FieldDefs:           TFieldDefs;
              AdvFieldDefs:        TACRAdvFieldDefs
                           );
var
  j:      Integer;
  FieldList, DescFieldList, CaseInsFieldList: TACRWideStringList;
  bIndexDesc,bIndexCaseIns: Boolean; //AJB
begin
 FieldList := TACRWideStringList.Create;
 DescFieldList := TACRWideStringList.Create;
 CaseInsFieldList := TACRWideStringList.Create;
 try
     if (Name = '') then
      raise EACRException.Create(20048, ErrorAInvalidIndexName, ['']);
     if (Fields = '') then
      raise EACRException.Create(20049, ErrorACannotFindIndexField, ['']);

     ACRIndexDef.Name := Name;
     ACRIndexDef.IndexType := itBTree;
     ACRIndexDef.Unique := (ixUnique in Options);
     ACRIndexDef.Primary := (ixPrimary in Options);
     GetNamesList(FieldList, Fields);
     GetNamesList(DescFieldList, DescFields);
     GetNamesList(CaseInsFieldList, CaseInsFields);
     ACRIndexDef.ColumnCount := FieldList.Count;
     bIndexDesc := (ixDescending in Options) and (DescFieldList.Count=0);  //inserted by AJB
     bIndexCaseIns := (ixCaseInsensitive in Options) and (CaseInsFieldList.Count=0); //inserted by AJB
     for j := 0 to FieldList.Count-1 do
      begin
       if (FieldDefs.IndexOf(FieldList.Strings[j]) = -1) then
        if (AdvFieldDefs.Find(FieldList.Strings[j]) = nil) then
         raise EACRException.Create(20050, ErrorACannotFindIndexField,
                                [FieldList.Strings[j]]);
       ACRIndexDef.Columns[j].FieldName := FieldList.Strings[j];
       ACRIndexDef.Columns[j].Descending :=
         (DescFieldList.IndexOf(FieldList.Strings[j]) >= 0) or
         (bIndexDesc); //AJB changed
       ACRIndexDef.Columns[j].CaseInsensitive :=
         (CaseInsFieldList.IndexOf(FieldList.Strings[j]) >= 0) or
         (bIndexCaseIns); //AJB changed
      end;
 finally
   FieldList.Free;
   DescFieldList.Free;
   CaseInsFieldList.Free;
 end;
end;// FillACRIndexDef


//------------------------------------------------------------------------------
// convert TIndexDef to TACRIndexDef
//------------------------------------------------------------------------------
procedure ConvertIndexDefToACRIndexDef(
                IndexDef:      TIndexDef;
                ACRIndexDef:   TACRIndexDef;
                FieldDefs:     TFieldDefs;
                AdvFieldDefs:  TACRAdvFieldDefs
                                       );
begin
 FillACRIndexDef(ACRIndexDef,
                 IndexDef.Name, IndexDef.Fields, IndexDef.Options,
                 IndexDef.DescFields, IndexDef.CaseInsFields, FieldDefs, AdvFieldDefs);
end;// ConvertIndexDefToACRIndexDef


//------------------------------------------------------------------------------
// convert TIndexDefs to ACRIndexDefs
//------------------------------------------------------------------------------
procedure ConvertIndexDefsToACRIndexDefs(
                IndexDefs:      TIndexDefs;
                ACRIndexDefs:   TACRIndexDefs;
                FieldDefs:      TFieldDefs;
                AdvFieldDefs:   TACRAdvFieldDefs
                                         );
var
  i:      Integer;
begin
  ACRIndexDefs.Clear;
  for i := 0 to IndexDefs.Count-1 do
   ConvertIndexDefToACRIndexDef(IndexDefs[i], ACRIndexDefs.AddCreated, FieldDefs, AdvFieldDefs);
end;// ConvertIndexDefsToACRIndexDefs


//------------------------------------------------------------------------------
// convert ACRIndexDefs to TIndexDefs
//------------------------------------------------------------------------------
procedure ConvertACRIndexDefsToIndexDefs(
                ACRIndexDefs:   TACRIndexDefs;
                IndexDefs:      TIndexDefs
                                         );
var
  i,j: Integer;
  Options: TIndexOptions;
  Fields, DescFields, CaseInsFields: AnsiString;
begin
 IndexDefs.Clear;
 for i := 0 to ACRIndexDefs.Count-1 do
  begin
   Fields := '';
   DescFields := '';
   CaseInsFields := '';
   for j := 0 to ACRIndexDefs[i].ColumnCount-1 do
    begin
      if (Fields <> '') then
       Fields := Fields + ';' + ACRIndexDefs[i].Columns[j].FieldName
      else
       Fields := ACRIndexDefs[i].Columns[j].FieldName;

      if (ACRIndexDefs[i].Columns[j].Descending) then
       if (DescFields <> '') then
        DescFields := DescFields + ';' + ACRIndexDefs[i].Columns[j].FieldName
       else
        DescFields := ACRIndexDefs[i].Columns[j].FieldName;

      if (ACRIndexDefs[i].Columns[j].CaseInsensitive) then
       if (CaseInsFields <> '') then
        CaseInsFields := CaseInsFields + ';' + ACRIndexDefs[i].Columns[j].FieldName
       else
        CaseInsFields := ACRIndexDefs[i].Columns[j].FieldName;
    end;

   Options := [];
   if (ACRIndexDefs[i].Unique) then
    Options := Options + [ixUnique];
   if (ACRIndexDefs[i].Primary) then
    Options := Options + [ixPrimary];

   IndexDefs.Add(ACRIndexDefs[i].Name, Fields, Options);
   IndexDefs[IndexDefs.Count-1].DescFields := DescFields;
   IndexDefs[IndexDefs.Count-1].CaseInsFields := CaseInsFields;
  end;
end;// ConvertACRIndexDefsToIndexDefs


//------------------------------------------------------------------------------
// return true if field exists
//------------------------------------------------------------------------------
function FindFieldInFieldDefs(FieldDefs: TFieldDefs; FieldName : WideString): Boolean;
var i: integer;
    f: Boolean;
begin
 f := false;
 for i := 0 to FieldDefs.Count -1 do
   if (WideUpperCase(FieldDefs.Items[i].Name) = WideUpperCase(FieldName)) then
    begin
      f := true;
      break;
    end;
 Result := f;
end; // FindFieldInFieldDefs


//------------------------------------------------------------------------------
// compression algorithm
//------------------------------------------------------------------------------
function ConvertCompressionAlgorithmToACRCompressionAlgorithm(
    CompressionAlgorithm: TCompressionAlgorithm
          ): TACRCompressionAlgorithm;
begin
 Result := acaNone;
 case (CompressionAlgorithm) of
  caZLIB: Result := acaZLIB;
  caBZIP: Result := acaBZIP;
{$IFDEF PPMD}
  caPPM: Result := acaPPM;
{$ENDIF}
{$IFDEF PPMDI}
  caPPMI: Result := acaPPMI;
{$ENDIF}
 end;
end; // ConvertCompressionAlgorithmToACRCompressionAlgorithm


//------------------------------------------------------------------------------
// compression algorithm
//------------------------------------------------------------------------------
function ConvertACRCompressionAlgorithmToCompressionAlgorithm(
            CompressionAlgorithm: TACRCompressionAlgorithm
          ): TCompressionAlgorithm;
begin
 Result := caNone;
 case (CompressionAlgorithm) of
  acaZLIB: Result := caZLIB;
  acaBZIP: Result := caBZIP;
{$IFDEF PPMD}
  acaPPM: Result := caPPM;
{$ENDIF}
{$IFDEF PPMDI}
  acaPPMI: Result := caPPMI;
{$ENDIF}
 end;
end; // ConvertACRCompressionAlgorithmToCompressionAlgorithm



//------------------------------------------------------------------------------
// copy records and return error log
//------------------------------------------------------------------------------
{$IFDEF NEW_FIELDS_COPYDATASETS}
function CopyDatasets(
                        SourceDataset:                TDataset;
                        DestinationDataset:           TDataset;
                        UseSourceDatasetForProgress:  Boolean;
                        Operation:                    TACRTableOperation;
                        FieldMapByFieldNames:         Boolean;
                        FieldNames:                   TACRWideStringList
                      ): WideString;

type
  TACRFieldCopyRecord = record
    src, Dest:        TField;
    Index:            Integer;
    AdvFldDef:        TACRAdvFieldDef;
  end;
var
  CurrentValue:       Int64;
  CurrentRecordNo:    Int64;
  SourceRecCount:     Integer;
  i, numFlds, n:      Integer;
  fldDef:             TFieldDef;
  fld:                TField;
  Bookmark:           TBookmark;
  Progress:           Double;
  bStart:             Boolean;
  bCalculateMinMax:   Boolean;
  min, max:           array of Int64;
  fldMap:             array of TACRFieldCopyRecord;
  ProgressShown:      Integer;

  function ShowProgress(Progress: Double): Boolean;
  begin
    Result := False;
    if (UseSourceDatasetForProgress) then
      TACRTable(SourceDataset).DoOnProgress(Progress, Operation, Result)
    else
      TACRTable(DestinationDataset).DoOnProgress(Progress, Operation, Result);
  end;

begin
  Result := '';
  CurrentRecordNo := 1;
  SourceDataset.CheckBrowseMode;
  SourceRecCount := SourceDataset.RecordCount;
  if (ShowProgress(0)) then
    begin
      Result := ErrorLOperationAborted;
      Exit;
    end;
  ProgressShown := 0;
  Bookmark := SourceDataset.GetBookmark;
  bStart := True;
  bCalculateMinMax := ((Operation = tbopRepair) or
    (Operation = tbopImport) or
    (Operation = tbopRestructure)) and
    (DestinationDataset is TACRDataset);
  if (bCalculateMinMax) then
    begin
      SetLength(min, DestinationDataset.FieldCount);
      SetLength(max, DestinationDataset.FieldCount);
      TACRDataSet(DestinationDataset).Handle.DirectSetAutoInc := True;
    end;
  try
    try
      SourceDataset.First;
    except
      Result := Result + ErrorLCannotRetrieveFirstRecord;
      Exit;
    end;
    //set up field map
    SetLength(fldMap, DestinationDataset.FieldCount);

    numFlds := 0;
    for i := 0 to SourceDataset.Fields.Count - 1 do
      begin
        if (FieldMapByFieldNames) then
        begin
          // map by names
          n := DestinationDataset.FieldDefs.IndexOf(SourceDataset.Fields[i].FieldName);
          if (n >= 0) and (n < DestinationDataset.FieldDefs.Count) then
           begin
            fldDef := DestinationDataset.FieldDefs.Items[n];
            if (fldDef <> nil) then
              begin
                fld := DestinationDataset.FindField(SourceDataset.Fields[i].FieldName);
                if (fld <> nil) then
                  begin
                    fldMap[numFlds].src := SourceDataset.Fields[i];
                    fldMap[numFlds].Dest := fld;
                    fldMap[numFlds].Index := fldDef.Index;
                    if (bCalculateMinMax) then
                      fldMap[numFlds].AdvFldDef := TACRDataset(DestinationDataset).AdvFieldDefs[fldDef.Index]
                    else
                      fldMap[numFlds].AdvFldDef := nil;
                    Inc(numFlds);
                  end;
              end; // field def found
           end; // field found in destination dataset
        end
        else
        begin
          // map by field numbers 0-0, 1-1, ...
          n := i;
          if (FieldNames <> nil) then
           if (FieldNames.Count > 0) and (i < FieldNames.Count) then
           begin
            n := DestinationDataset.FieldDefs.IndexOf(FieldNames[i]);
           end;
          if (n < 0) or (n >= DestinationDataset.FieldCount)  then
           continue;
          fldMap[numFlds].src := SourceDataset.Fields[i];
          fldMap[numFlds].Dest := DestinationDataset.Fields[n];
          fldMap[numFlds].Index := DestinationDataset.Fields[n].Index;
          if (bCalculateMinMax) then
            fldMap[numFlds].AdvFldDef := TACRDataset(DestinationDataset).AdvFieldDefs[n]
          else
            fldMap[numFlds].AdvFldDef := nil;
          Inc(numFlds);
        end;
      end; // for

    while not SourceDataset.EOF do
      begin
        DestinationDataset.Insert;
        for i := 0 to numFlds - 1 do
          begin
            if (fldMap[i].src.IsNull) then
              fldMap[i].Dest.Clear
            else
            try
              if (fldMap[i].Dest is TLargeintField) then
                begin
                  TLargeintField(fldMap[i].Dest).AsLargeInt :=
                    TLargeintField(fldMap[i].src).AsLargeInt
                end
              else if (fldMap[i].Dest is TBytesField) then
                begin
                  fldMap[i].Dest.AsString := fldMap[i].src.AsString;
                end
              else
                begin
                  fldMap[i].Dest.Assign(fldMap[i].src);
                end;
              // calculate autoinc min or max values
              if (bCalculateMinMax) then
                if (IsAutoincFieldType(fldMap[i].AdvFldDef.DataType)) then
                  begin
                    if (fldMap[i].Dest is TLargeintField) then
                      CurrentValue := TLargeintField(fldMap[i].Dest).AsLargeInt
                    else
                      CurrentValue := fldMap[i].Dest.AsInteger;
                    if (fldMap[i].AdvFldDef.AutoincIncrement >= 0) then
                      begin
                        if (bStart) then
                          max[fldMap[i].Index] := CurrentValue
                        else if (CurrentValue > max[fldMap[i].Index]) then
                          max[fldMap[i].Index] := CurrentValue;
                      end // increment >= 0
                    else
                      begin
                        if (bStart) then
                          min[fldMap[i].Index] := CurrentValue
                        else if (CurrentValue < min[fldMap[i].Index]) then
                          min[fldMap[i].Index] := CurrentValue;
                      end; // increment < 0
                    bStart := False;
                  end;
            except
              on e: Exception do
                begin
                  Result := Result + Format(ErrorLCopyTableInvalidFieldValue,
                  [CurrentRecordNo, fldMap[i].src.FieldName, e.Message]);
                end;
            end; // copy field value
          end; // copying fields
        try
          DestinationDataset.Post;
        except
          on e: Exception do
            Result := Result + Format(ErrorLCopyTablePostFailed, [CurrentRecordNo, e.Message]);
        end;
        Inc(CurrentRecordNo);
        try
          SourceDataset.Next;
        except
          Result := Result + #13#10 + Format(ErrorLCannotRetrieveRecord, [CurrentRecordNo, CurrentRecordNo - 1]);
          Exit;
        end;
        Progress := CurrentRecordNo * 100.0 / SourceRecCount;
        if (Trunc(Progress) > ProgressShown) then
          begin
            if (ShowProgress(Progress)) then
              begin
                Result := Result + #13#10 + 'Operation aborted';
                break;
              end;
            ProgressShown := Trunc(Progress);
          end;
      end;
  finally
    if (bCalculateMinMax and (not bStart)) then
      begin
        TACRDataSet(DestinationDataset).Handle.DirectSetAutoInc := False;
        for i := 0 to DestinationDataset.FieldCount - 1 do
          if (IsAutoincFieldType(TACRDataset(DestinationDataset).AdvFieldDefs[i].DataType)) then
            //          (not TACRDataset(DestinationDataset).AdvFieldDefs[i].AutoincCycled)) then
            begin
              if (TACRDataset(DestinationDataset).AdvFieldDefs[i].AutoincIncrement >= 0) then
                CurrentValue := max[i]
              else
                CurrentValue := min[i];
              TACRTable(DestinationDataset).SetLastAutoincValue(CurrentValue, i);
            end;
        min := nil;
        max := nil;
      end;
    try
     SourceDataset.GotoBookmark(Bookmark);
     SourceDataset.FreeBookmark(Bookmark);
    except
    end;
    ShowProgress(100);
    fldMap := nil;
  end;
end; // CopyDatasets - AJB

{$ELSE}
function CopyDatasets(
            SourceDataset:                TDataset;
            DestinationDataset:           TDataset;
            UseSourceDatasetForProgress:  Boolean;
            Operation:                    TACRTableOperation
            ): WideString;
var
    CurrentValue:     Int64;
    CurrentRecordNo:  Int64;
    SourceRecCount:   Integer;
    i:                Integer;
    Bookmark:         TBookmark;
    Progress:         Double;
    bStart:           Boolean;
    bCalculateMinMax: Boolean;
    var min,max:      array of Int64;
    FieldNo:          Integer;
    ProgressShown:    Integer;

    function ShowProgress(Progress: Double): Boolean;
    begin
     Result := False;
     if (UseSourceDatasetForProgress) then
      TACRTable(SourceDataset).DoOnProgress(Progress,Operation,Result)
     else
      TACRTable(DestinationDataset).DoOnProgress(Progress,Operation,Result);
    end;

begin
 Result := '';
 CurrentRecordNo := 1;
 SourceDataset.CheckBrowseMode;
 SourceRecCount := SourceDataset.RecordCount;
 if (ShowProgress(0)) then
  begin
   Result := ErrorLOperationAborted;
   Exit;
  end;
 ProgressShown := 0;
 Bookmark := SourceDataset.GetBookmark;
 bStart := true;
 bCalculateMinMax := ((Operation = tbopRepair) or
                      (Operation = tbopImport) or
                      (Operation = tbopRestructure)) and
                     (DestinationDataset is TACRDataset);
 if (bCalculateMinMax) then
  begin
   SetLength(min,DestinationDataset.FieldCount);
   SetLength(max,DestinationDataset.FieldCount);
  end;
 try
   try
     SourceDataset.First;
   except
     Result := Result + ErrorLCannotRetrieveFirstRecord;
     Exit;
   end;
   while not SourceDataset.Eof do
    begin
      DestinationDataset.Insert;
      for i := 0 to SourceDataset.FieldCount - 1 do
       begin
        FieldNo := DestinationDataset.FieldDefs.IndexOf(SourceDataset.Fields[i].FieldName);
        if (FieldNo >= 0) then
         // changed in v.4.05 - to avoid problem with default value in dest dataset and null in source
         if (SourceDataset.Fields[i].IsNull) then
          DestinationDataset.Fields[FieldNo].Clear
         else
          try
            if (DestinationDataset.Fields[FieldNo] is TLargeintField) then
             begin
              TLargeintField(DestinationDataset.Fields[FieldNo]).AsLargeInt :=
                TLargeintField(SourceDataset.Fields[i]).AsLargeInt
             end
            else
            if (DestinationDataset.Fields[FieldNo] is TBytesField) then
             begin
              DestinationDataset.Fields[FieldNo].AsString := SourceDataset.Fields[i].AsString;
             end
            else
             begin
               DestinationDataset.Fields[FieldNo].Assign(SourceDataset.Fields[i]);
             end;
            // calculate autoinc min or max values
            if (bCalculateMinMax) then
             if (IsAutoincFieldType(TACRDataset(DestinationDataset).AdvFieldDefs[FieldNo].DataType)) then
//             and
//                (not TACRDataset(DestinationDataset).AdvFieldDefs[FieldNo].AutoincCycled)) then
              begin
                if (DestinationDataset.Fields[FieldNo] is TLargeintField) then
                 CurrentValue := TLargeintField(DestinationDataset.Fields[FieldNo]).AsLargeInt
                else
                 CurrentValue := DestinationDataset.Fields[FieldNo].AsInteger;
                if (TACRDataset(DestinationDataset).AdvFieldDefs[FieldNo].FAutoincIncrement >= 0) then
                 begin
                  if (bStart) then
                   max[FieldNo] := CurrentValue
                  else
                   if (CurrentValue > max[FieldNo]) then
                     max[FieldNo] := CurrentValue;
                 end // increment >= 0
                else
                 begin
                  if (bStart) then
                   min[FieldNo] := CurrentValue
                  else
                   if (CurrentValue < min[FieldNo]) then
                     min[FieldNo] := CurrentValue;
                 end; // increment < 0
                bStart := False;
              end;
          except
           on e: Exception do
            begin
              Result := Result + Format(ErrorLCopyTableInvalidFieldValue,
                [CurrentRecordNo,SourceDataset.Fields[i].FieldName,e.Message]);
            end;
          end; // copy field value
       end; // copying fields
      try
       DestinationDataset.Post;
      except
       on e: Exception do
         Result := Result + Format(ErrorLCopyTablePostFailed,[CurrentRecordNo,e.Message]);
      end;
      Inc(CurrentRecordNo);
      try
       SourceDataset.Next;
      except
       Result := Result + #13#10 + Format(ErrorLCannotRetrieveRecord,[CurrentRecordNo,CurrentRecordNo-1]);
       Exit;
      end;
      Progress := CurrentRecordNo * 100.0 / SourceRecCount;
      if (Trunc(Progress) > ProgressShown) then
       begin
        if (ShowProgress(Progress)) then
         begin
          Result := Result + #13#10 + 'Operation aborted';
          break;
         end;
        ProgressShown := Trunc(Progress);
       end;
    end;
 finally
   if (bCalculateMinMax and (not bStart)) then
    begin
      for i := 0 to DestinationDataset.FieldCount - 1 do
       if (IsAutoincFieldType(TACRDataset(DestinationDataset).AdvFieldDefs[i].DataType)) then
//          (not TACRDataset(DestinationDataset).AdvFieldDefs[i].AutoincCycled)) then
        begin
         if (TACRDataset(DestinationDataset).AdvFieldDefs[i].AutoincIncrement >= 0) then
          CurrentValue := max[i]
         else
          CurrentValue := min[i];
         TACRTable(DestinationDataset).SetLastAutoincValue(CurrentValue,i);
        end;
      min := nil;
      max := nil;
    end;
   try
    SourceDataset.GotoBookmark(Bookmark);
   except
   end;
   SourceDataset.FreeBookmark(Bookmark);
   ShowProgress(100);
 end;
end; // CopyDatasets
{$ENDIF}

function ACRGetCurrentVersion: String;
var c : Char;
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
end; // ACRGetCurrentVersion

{$IFDEF TRIAL_VERSION}
procedure acrtrshnm;
var capt, msg: String;
begin
{$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
  Exit;
{$ENDIF}
  capt := 'Accuracer Trial Version - ' +  'v.'+FormatFloat('0.00',ACRVersion) + ' '+ ACRVersionText;
  msg :=
             'This is the trial version of Accuracer by'#13+
             'AidAim Software (c) 2000-2025.'#13+
             'Web site: https://aidaim.com'#13#13+

             'Limitations of this trial version: '#13+
             '- maximum number of sessions in single user mode is '+IntToStr(ACRMaxSingleUserConnections)+'.'#13+
             '- maximum number of concurrent multi-user connections is '+IntToStr(ACRMaxSessionCount)+'.'#13+

						 'This screen is created to remind you that your trial version is'#13+
             'provided to you for evaluation purposes only.'#13+
             'If you don''t want to see this screen any more, or if you intend'#13+
             'to create a commercial product, please, register and download'#13+
             'the appropriate version of this product at https://aidaim.com'#13+
             'Also visit our site for all the new versions of our products.'#13#13+
             'Should you have any questions or problems with our product,'#13+
             'be sure to contact us at https://aidaim.com/help_osticket/';

{$IFDEF D12H}
 MessageBoxW(0,PChar(@msg[1]),PChar(@capt[1]),
{$ELSE}
 MessageBoxA(0,PAnsiChar(@msg[1]),PAnsiChar(@capt[1]),
{$ENDIF}
{$IFDEF MSWINDOWS}
		 MB_OK+MB_ICONINFORMATION+MB_DEFBUTTON1
{$ENDIF}
{$IFDEF LINUX}
     [smbOK], smsInformation
{$ENDIF}
);
end;

//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function ACRWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
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
{$ENDIF}

var
  DBDatas: TList;

{$IFDEF MEMORY_ENGINE}
  MemDBData: TACRMemoryDatabaseData;
{$ENDIF}
{$IFDEF TEMPORARY_ENGINE}
  TempDBData: TACRTemporaryDatabaseData;
{$ENDIF}
{$IFDEF TRIAL_VERSION}
var i: integer;
    WindowLst: TStringList;
    IsIDERunning: boolean;
    IsDelphiOrBuilderInstalled: boolean;
 {$IFDEF MSWINDOWS}
    Reg: TRegistry;
 {$ENDIF}
{$ENDIF}


initialization
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRMain> initialization started');
{$ENDIF}

  {$IFDEF DEBUG_MEMCHECK}
  MemChk;
  {$ENDIF}

  ACRMemoryIncUseCount;
  ACRDatasets := TThreadList.Create;
  ACRDatasetsList := nil;
  DBDataList := TThreadList.Create;
  DBDatas := nil;
 {$IFDEF MEMORY_ENGINE}
  MemDBData := TACRMemoryDatabaseData.Create;
  MemDBData.DatabaseName := ACRMemoryDatabaseName;
  DBDatas := DBDataList.LockList;
  DBDatas.Add(MemDBData);
  DBDataList.UnlockList;
 {$ENDIF}
 {$IFDEF TEMPORARY_ENGINE}
  TempDBData := TACRTemporaryDatabaseData.Create;
  TempDBData.DatabaseName := ACRTemporaryDatabaseName;
  DBDatas := DBDataList.LockList;
  DBDatas.Add(TempDBData);
  DBDataList.UnlockList;
 {$ENDIF}

{$IFDEF TRIAL_VERSION}
{$IFDEF MSWINDOWS}
  WindowLst := TStringList.Create;
  EnumWindows(@ACRWindowCallback,Longint(@WindowLst));
  // IDE detection
  IsIDERunning := false;
  for i:=0 to WindowLst.Count-1 do
    if ((Pos('Delphi',WindowLst[i]) = 1) or
        (Pos('Borland',WindowLst[i]) > 0) or
        (Pos('CodeGear',WindowLst[i]) > 0) or
        (Pos('RAD Studio',WindowLst[i]) > 0) or
        (Pos('Embarcadero',WindowLst[i]) > 0) or
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
      (Reg.KeyExists('\Software\Codegear\BDS')) or
      (Reg.KeyExists('\Software\Embarcadero\BDS')) or
      (Reg.KeyExists('\Software\Borland\C++Builder'))) then
    IsDelphiOrBuilderInstalled := true
  else
    IsDelphiOrBuilderInstalled := false;
  Reg.Free;
  // nag screen
  if ((not IsIDERunning) or (not IsDelphiOrBuilderInstalled)) then
     begin
      acrtrshnm;
     end;
   WindowLst.Free;
{$ENDIF}
{$ENDIF}
  Sessions := TACRSessionList.Create;
  Session := TACRSession.Create(nil);
  Session.SessionName := 'Default';

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRMain> initialization finished');
{$ENDIF}

finalization
  Sessions.Free;

  DBDatas := DBDataList.LockList;
  while (DBDatas.Count > 0) do
    TACRDatabaseData(DBDatas.Items[0]).Free;
  DBDataList.UnlockList;
  DBDataList.Free;
  DBDataList := nil;

  ACRDatasets.Free;
  ACRDatasets := nil;

  ACRMemoryDecUseCount;


end.
