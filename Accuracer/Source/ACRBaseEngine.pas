//------------------------------------------------------------------------------
//
// Local and File-Server Engine
// Server uses Local Engine
//
//------------------------------------------------------------------------------

unit ACRBaseEngine;
{$I ACRVer.inc}

interface

uses SysUtils,
	Classes,
{$IFDEF MSWINDOWS}
	Controls,
	Windows,
{$ENDIF}
{$IFDEF LINUX}
	Libc,
{$ENDIF}
	Math,

  // Accuracer units

	ACRCriticalSection,
{$IFDEF DEBUG_LOG}
	ACRDebug,
{$ENDIF}
{$IFDEF D12H}
	ACR_d12h,
{$ENDIF}
{$IFNDEF D6H}
	ACRD4Routines,
{$ENDIF}
	ACRPage,
	ACRExcept,
	ACRBase,
	ACRCompression,
{$IFNDEF SQLMEMTABLE}
	ACRCrypto,
	ACRDecUtil,
	ACRDecFmt,
{$ENDIF}
	ACRTypes,
	ACRConverts,
	ACRVariant,
	ACRLexer,
	ACRConst,
	ACRExpressions;
{$IFDEF LINUX}

// Windows.pas
const
	MAXWORD = 65535;
{$ENDIF}

type

	TACRDatabaseData = class;
	TACRTableData = class;
	TACRAdvancedTableData = class;
	TACRIndex = class;
	TACRBaseSequenceManager = class;
	TACRRecordBitmap = class;
	TACRTransaction = class;

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRBaseRecordManager
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRBaseRecordManager = class(TObject)
	protected
    { I ACRThreadSync_0.inc }
		FRecordBufferSize: Integer;
		FRecordCount: TACRRecordNo;
		FRepair: Boolean;

	public
    {
      // lock
      procedure Lock(WriteMode: Boolean = false);
      // unlock
      procedure Unlock;
    }
		function GetRecordCount: TACRRecordNo; virtual;
		procedure Empty(SessionID: TACRSessionID = INVALID_SESSION_ID); virtual;
			abstract;
    // add record and return its number
		function AddRecord(RecordBuffer: TACRRecordBuffer;
			var RecordID: TACRRecordID;
			SessionID: TACRSessionID = INVALID_SESSION_ID)
			: Boolean; virtual; abstract;
    // update record, return true if record was updated, false if record was deleted
		function UpdateRecord(RecordBuffer: TACRRecordBuffer;
			RecordID: TACRRecordID;
			SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean; virtual;
    // delete record, return true if record was deleted, false if record was deleted earlier
		function DeleteRecord(var RecordID: TACRRecordID;
			SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean; virtual;
    // return true if record exists
		function IsRecordExists(var RecordID: TACRRecordID;
			SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean;
			virtual; abstract;
    // get record using physical order
		procedure GetRecordBuffer(var NavigationInfo: TACRNavigationInfo); virtual;
			abstract;
    // return record no
		function GetApproximateRecNo(RecordID: TACRRecordID;
			SessionID: TACRSessionID): TACRRecordNo; virtual; abstract;
		procedure LoadFromStream(Stream: TStream); virtual;
		procedure SaveToStream(Stream: TStream); virtual;
    // add loaded record
		procedure AddLoadedRecord(RecordBuffer: TACRRecordBuffer;
			var RecordPos: Integer); virtual;
	public
		property RecordBufferSize
			: Integer read FRecordBufferSize write FRecordBufferSize;
		property Repair: Boolean read FRepair write FRepair;
	end;

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRBaseFieldManager
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRBaseFieldManager = class(TObject)
	private
		FFieldDefs: TACRFieldDefs;
		FTableData: TACRTableData;
		FSequenceManager: TACRBaseSequenceManager;
		FEngineVersion: Double;
	public
		constructor Create(TableData: TACRTableData;
			SequenceManager: TACRBaseSequenceManager);
		destructor Destroy; override;

		procedure LoadFromStream(Stream: TStream); virtual;
		procedure SaveToStream(Stream: TStream); virtual;

		procedure ApplyAutoIncValuesToRecordBuffer(Session: TACRBaseSession;
			RecordBuffer: TACRRecordBuffer);
	public
		property FieldDefs: TACRFieldDefs read FFieldDefs;
		property EngineVersion: Double read FEngineVersion write FEngineVersion;
	end; // TACRBaseFieldManager

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRBaseIndexManager
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRBaseIndexManager = class(TObject)
	protected
		LTableData: TACRTableData;
		FIndexDefs: TACRIndexDefs;
		FOpenIndexList: TList; // list of TACRIndex objects

		procedure InternalCreateIndex(Cursor: TACRCursor; IndexDef: TACRIndexDef);
		function InternalOpenIndex(IndexID: TACRObjectID): TACRIndex;

	public
		procedure LoadFromStream(Stream: TStream); virtual;
		procedure SaveToStream(Stream: TStream); virtual;
		constructor Create(aTableData: TACRTableData);
		destructor Destroy; override;

		function IsIndexExists(FieldNames, AscDescList,
			CaseSensitivityList: TACRWideStringList): Boolean;
		function FindIndex(FieldNames, AscDescList,
			CaseSensitivityList: TACRWideStringList): TACRObjectID;

    // create index definitions list
		procedure CreateIndexDefs(aIndexDefs: TACRIndexDefs); virtual;

		procedure ClearIndexCache(SessionID: TACRSessionID = INVALID_OBJECT_ID);
		function FindOpenIndex(IndexID: TACRObjectID): TACRIndex;
		function CreateIndex(Cursor: TACRCursor; IndexDef: TACRIndexDef): TACRObjectID;
		function OpenIndex(IndexID: TACRObjectID): TACRIndex;
		procedure CloseIndex(IndexID: TACRObjectID);
		procedure DropIndex(SessionID: TACRSessionID; IndexID: TACRObjectID);
		procedure DropAllIndexes(SessionID: TACRSessionID);
		procedure EmptyIndex(SessionID: TACRSessionID; IndexID: TACRObjectID);
		procedure EmptyAllIndexes(SessionID: TACRSessionID);

		procedure GetRecordBuffer(SessionID: TACRSessionID;
			var NavigationInfo: TACRNavigationInfo);
		procedure InsertRecord(Cursor: TACRCursor);
		procedure UpdateRecord(Cursor: TACRCursor);
		procedure DeleteRecord(Cursor: TACRCursor);
    // return 0 if record buffers are equal in this index
    // return 1 if Buffer1 is higher than Buffer 2 (Pos1 > Pos2)
    // return -1 if Buffer1 is lower than Buffer 2 (Pos1 < Pos2)
    // IndexFieldCount = 0 means to compare by all fields in index
		function CompareRecordBuffersByIndex(IndexID: TACRObjectID;
			Buffer1: TACRRecordBuffer; Buffer2: TACRRecordBuffer;
			IndexFieldCount: Integer = 0): Integer;
    // called from CreateTable - allocates root pages for all indexes
		procedure CreateAllIndexes(SessionID: TACRSessionID);
	public
		property IndexDefs: TACRIndexDefs read FIndexDefs;
		property TableData: TACRTableData read LTableData;
	end; // TACRBaseIndexManager

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRIndex
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRIndex = class(TObject)
	private
		FIndexDef: TACRIndexDef;
	protected
		LIndexManager: TACRBaseIndexManager;
		LTableData: TACRTableData;
	public
		constructor Create(aIndexManager: TACRBaseIndexManager);
		destructor Destroy; override;
    // clear index cache (INVALID_OBJECT_ID means all sessions)
		procedure ClearIndexCache(SessionID: TACRSessionID = INVALID_OBJECT_ID);
			virtual; abstract;
		procedure CreateIndex(Cursor: TACRCursor; aIndexDef: TACRIndexDef);
			overload; virtual;
		procedure CreateIndex(SessionID: TACRSessionID; pageNo: TACRPageNo;
			aIndexDef: TACRIndexDef); overload; virtual;
		procedure DropIndex(SessionID: TACRSessionID; EmptyIndex: Boolean = False);
			virtual; abstract;
		procedure OpenIndex(aIndexDef: TACRIndexDef); virtual;

		procedure GetRecordBuffer(SessionID: TACRSessionID;
			var NavigationInfo: TACRNavigationInfo); virtual; abstract;
		function CreateIndexPosition: TACRIndexPosition; virtual; abstract;
		procedure FreeIndexPosition(var IndexPosition: TACRIndexPosition); virtual;
			abstract;
		function GetIndexPosition(SessionID: TACRSessionID; RecordID: TACRRecordID;
			RecordBuffer: TACRRecordBuffer;
			IndexPosition: TACRIndexPosition): Boolean; virtual; abstract;
    // return 0, 1, -1 if (Pos1 = Pos2), (Pos1 > Pos2), (Pos1 < Pos2)
		function CompareRecordPositionsInIndex(RecordPosition1: TACRIndexPosition;
			RecordPosition2: TACRIndexPosition): Integer; virtual; abstract;
		function GetRecNoByRecordID(SessionID: TACRSessionID;
			RecordID: TACRRecordID; RecordBuffer: TACRRecordBuffer;
			Bitmap: TACRRecordBitmap): TACRRecordNo; virtual; abstract;
		function GetRecordIDByRecNo(SessionID: TACRSessionID; RecNo: TACRRecordNo;
			Bitmap: TACRRecordBitmap): TACRRecordID; virtual; abstract;
		function CreateSearchInfo: TACRSearchInfo; virtual; abstract;
		procedure FreeSearchInfo(SearchInfo: TACRSearchInfo); virtual; abstract;
		function FindRecord(SessionID: TACRSessionID; Restart: Boolean;
			GoForward: Boolean; StartScanCondition: TACRScanSearchCondition;
			EndScanCondition: TACRScanSearchCondition;
			RecordBuffer: TACRRecordBuffer; var RecordID: TACRRecordID;
			SearchInfo: TACRSearchInfo): Boolean; virtual; abstract;
    // return 0 if record buffers are equal in this index
    // return 1 if Buffer1 is higher than Buffer 2 (Pos1 > Pos2)
    // return -1 if Buffer1 is lower than Buffer 2 (Pos1 < Pos2)
		function CompareRecordBuffersByIndex(Buffer1: TACRRecordBuffer;
			Buffer2: TACRRecordBuffer; IndexFieldCount: Integer): Integer; virtual;
			abstract;

    // return 0 if conditions are equal in this index
    // return 1 if Condition1 is higher than Condition2
    // return -1 if Condition1 is lower than Condition2
		function CompareConditions(Condition1: TACRScanSearchCondition;
			Condition2: TACRScanSearchCondition): Integer; virtual; abstract;
    // approximate record count berween range conditions
		function GetApproxRangeRecordCount(SessionID: TACRSessionID;
			TableRecordCount: TACRRecordNo; RangeCondition1: TACRScanSearchCondition;
			RangeCondition2: TACRScanSearchCondition): TACRRecordNo; virtual;
			abstract;
		function CanInsertRecord(SessionID: TACRSessionID;
			RecordBuffer: TACRRecordBuffer): Boolean; virtual; abstract;
		function CanUpdateRecord(SessionID: TACRSessionID;
			OldRecordBuffer, NewRecordBuffer: TACRRecordBuffer): Boolean; virtual;
			abstract;
		procedure InsertRecord(Cursor: TACRCursor); virtual; abstract;
		procedure DeleteRecord(Cursor: TACRCursor); virtual; abstract;
		procedure UpdateRecord(Cursor: TACRCursor); virtual; abstract;

		property IndexDef: TACRIndexDef read FIndexDef;
		property IndexManager: TACRBaseIndexManager read LIndexManager;
	end; // TACRIndex

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRBaseSequenceManager
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRBaseSequenceManager = class(TObject)
	private
		FSequenceDefs: TACRSequenceDefs;
		FDatabaseData: TACRDatabaseData;
	public
    // constructor
		constructor Create(DatabaseData: TACRDatabaseData);
    // destructor
		destructor Destroy; override;

    // find or create SequenceDef by SequenceName
		function GetOrCreateSequenceDefByName(SequenceName: WideString)
			: TACRSequenceDef;

    // returns sequence definition
		function GetSequenceDef(SequenceID: TACRObjectID): TACRSequenceDef;
    // get next sequence value
		function GetNextVal(Session: TACRBaseSession;
			SequenceID: TACRObjectID): TACRSequenceValue; overload;
    // get next sequence value from specified value
		procedure GetNextVal(Session: TACRBaseSession; SequenceID: TACRObjectID;
			Value: TACRSequenceValue); overload;
    // get last sequence value
		function GetLastVal(Session: TACRBaseSession;
			SequenceID: TACRObjectID): TACRSequenceValue;
    // Generate unique Sequence Name
		function GenerateSequenceName(isAutoinc: Boolean; ColumnName: WideString;
			TableName: WideString = ''): WideString;
	public
		property SequenceDefs
			: TACRSequenceDefs read FSequenceDefs write FSequenceDefs;
	end; // TACRBaseSequenceManager

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRBaseConstraintManager
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRBaseConstraintManager = class(TObject)
	private
		FConstraintDefs: TACRConstraintDefs;
		FTableData: TACRTableData;
		FEmpty: Boolean;
	public
		procedure LoadFromStream(Stream: TStream);
		procedure SaveToStream(Stream: TStream);
		constructor Create(aTableData: TACRTableData); // virtual;
		destructor Destroy; override;

    // check constraint conditions
		procedure CheckConstraints(
                                Cursor:           TACRCursor;
                                SessionID:        TACRSessionID;
                                NewRecordBuffer:  TACRRecordBuffer;
                                OldRecordBuffer:  TACRRecordBuffer;
                                ToInsert:         Boolean;
                                CurrentRecordID:  TACRRecordID;
                                SkipFKCheck:      Boolean = False
                               );
    // link object id
		procedure LinkObjectId(ConstraintDef: TACRConstraintDef);
    // link object ids between constraints and fields
		procedure LinkObjectIds;
    // generate Constraint Names for empty constraints
		procedure FillConstraintAutoNames;

    // add constraint for primary or Unique index
		procedure AddConstraintFromIndex(IndexDef: TACRIndexDef);
    // delete Constraint Linked with deleted index
		procedure DeleteConstraintForIndexID(IndexObjectID: TACRObjectID);
    // add action to master table
		function AddForeignKeyAction(ConstraintDef: TACRConstraintDefForeignKey;
			ReferencedTableName: WideString; ReferencedTableObjectID: TACRObjectID)
			: TACRConstraintDefForeignKeyAction;

	public
		property ConstraintDefs
			: TACRConstraintDefs read FConstraintDefs write FConstraintDefs;
		property Empty: Boolean read FEmpty;
	end; // TACRBaseConstraintManager

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRRecordBitmap
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRRecordBitmap = class(TObject)
	private
		FVisibleRecords: TACRRecordIDArray;
		FTableData: TACRTableData;
		FActive: Boolean;
		FIndexed: Boolean; // is index applied
		FDistinct: Boolean; // for distinct without filter on disk tables
	protected
		procedure SetActive(Value: Boolean);
		procedure SetIndexed(Value: Boolean);
	public
		constructor Create(aTableData: TACRTableData);
		destructor Destroy; override;
		function GetRecordCount: TACRRecordNo;
		function GetRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo;
		function GetRecordIDByRecNo(RecNo: TACRRecordNo): TACRRecordID;
		function IsRecordVisible(RecordID: TACRRecordID): Boolean;
		procedure InsertVisibleRecord(var RecordID: TACRRecordID;
			const PriorRecordID: TACRRecordID; bFirst: Boolean; bLast: Boolean);
		procedure ShowRecord(RecordID: TACRRecordID);
		procedure HideRecord(RecordID: TACRRecordID);
		procedure ClearVisibleRecords;
	protected
		procedure GetRecordFromFirstPosition
			(var NavigationInfo: TACRNavigationInfo);
		procedure GetRecordFromLastPosition(var NavigationInfo: TACRNavigationInfo);
		procedure GetRecordFromAnyPosition(var NavigationInfo: TACRNavigationInfo);
	public
		procedure GetRecord(var NavigationInfo: TACRNavigationInfo);
		procedure PrepareBitmapForActivation;
	public
		property TableData: TACRTableData read FTableData;
		property Active: Boolean read FActive write SetActive;
		property Distinct: Boolean read FDistinct write FDistinct;
		property Indexed: Boolean read FIndexed write SetIndexed;
		property VisibleRecords: TACRRecordIDArray read FVisibleRecords;
	end; // TACRRecordBitmap




////////////////////////////////////////////////////////////////////////////////
//
// TACRRecordBufferCache
//
////////////////////////////////////////////////////////////////////////////////

	TACRRecordBufferCache = class(TObject)
	private
		FSync:          TACRReadWriteThreadSync;
		FBuffers:       TACRIntegerArray; // stores 32-bit pointers to allocated record buffers
		FBufferSize:    Integer; // size in bytes of the record buffer
		FUsedBuffers:   TACRBitsArray; // bit 1 - used, 0 - not used
	public
		constructor Create(aBufferSize: Integer);
		destructor Destroy; override;
    // returns pointer to the new buffer and marks it as used
		function GetBuffer: TACRRecordBuffer;
    // marks buffer as not used
		procedure FreeBuffer(Buffer: TACRRecordBuffer);
	public
	end; // TACRRecordBufferCache




////////////////////////////////////////////////////////////////////////////////
//
// TACRFindRecordCache
//
////////////////////////////////////////////////////////////////////////////////

  TACRFindRecordCacheItem = packed record
    FieldNamesCRC:    Cardinal;
    SearchExpression: TACRExpression;
    UseCount:         Cardinal;
  end; // TACRFindRecordCacheItem
  PACRFindRecordCacheItem = ^TACRFindRecordCacheItem;


	TACRFindRecordCache = class(TObject)
	private
		FSync:          TACRReadWriteThreadSync;
		FItems:         TACRIntegerArray; // stores 32-bit pointers to allocated cache items
    LTableData:     TACRTableData;
  protected

	public
		constructor Create(aTableData: TACRTableData);
		destructor Destroy; override;
    procedure Clear(bClearAll: Boolean = False);
    function GetCacheItem(
                          Cursor:           TACRCursor;
                          const KeyFields:  WideString;
                          const KeyValues:  Variant;
                          CaseInsensitive:  Boolean;
                          PartialKey:       Boolean
                         ): PACRFindRecordCacheItem;
    procedure PutCacheItem(pItem: PACRFindRecordCacheItem);
  end; // TACRFindRecordCache




////////////////////////////////////////////////////////////////////////////////
//
// TACRTableData
//
////////////////////////////////////////////////////////////////////////////////

	TACRTableData = class(TObject)
	private
		FThreadSync: 						TACRReadWriteThreadSync;
	protected
		FDoNotLockDatabaseData: Boolean;
		FRepair: 								Boolean;
		FDatabaseData: 					TACRDatabaseData;

		FCache: 								TACRTableCache;
		FRecordBufferCache: 		TACRRecordBufferCache; // changed to cache in v.4.97
    FFindRecordCache:       TACRFindRecordCache;

		FTableName: 						WideString;
		FComment: 							WideString;
		FCreationDate: 					TDateTime;
		FTableNameCRC: 					Cardinal;
		FBLOBCompression: 			TACRCompression;
		FActive: 								Boolean;
		FFieldManager: 					TACRBaseFieldManager;
		FConstraintManager: 		TACRBaseConstraintManager;
		FIndexManager: 					TACRBaseIndexManager;
		FRecordManager: 				TACRBaseRecordManager;
		FSequenceManager: 			TACRBaseSequenceManager;
		FCursorList: 						TList;
		FCursorListThreadSync: 	TACRReadWriteThreadSync;
		FBLOBFieldsPresent: 		Boolean;
		FInMemory: 							Boolean;
		FTemporary: 						Boolean;
		FTableState: 						TACRTableState;
		FExclusive: 						Boolean; // table opened exclusively by single session

		function GetPageManager: TACRPageManager; virtual; abstract;
		procedure SetTableName(Name: WideString);
		function GetTableID: TACRObjectID; virtual;
    // load table state
		function LoadTableState: TACRTableState; virtual;
    // save table state
		procedure SaveTableState; virtual;
		function GetLastTableOperation: TACRLastTableOperation; virtual;
		procedure UpdateTableState(Operation: TACRLastTableOperation); virtual;
		procedure UpdateTableMetadataState(Operation: TACRLastTableOperation = ltoCreateTable); virtual;
		function GenerateTableMetadataState: Byte;
		function GenerateTableState: TACRState;
		procedure SetTableFlag(ToSet: Boolean; Flag: TACRTableFlags);
		function GetTableFlag(Flag: TACRTableFlags): Boolean;
    // Fill New ObjectID for all defs
		procedure FillDefsByObjectId(Defs: TACRMetaObjectDefs);
		function GetRecordBufferSize: Integer;
		procedure CreateRecordManager; virtual; abstract;
		procedure CreateFieldManager(FieldDefs: TACRFieldDefs);
		procedure CreateIndexManager(IndexDefs: TACRIndexDefs); virtual;
		procedure CreateConstraintManager(ConstraintDefs: TACRConstraintDefs);
		procedure CreateSequenceManager;
		procedure BuildSequences;
		procedure LoadSequencesFromStream(Stream: TStream);
		procedure SaveSequencesToStream(Stream: TStream);
		procedure InitCursor(Cursor: TACRCursor); virtual;
    // function IsTableNameEqual(name: AnsiString; ToUpper: Boolean = true): Boolean;
    // lock
		procedure Lock(WriteMode: Boolean); virtual;
    // unlock
		procedure Unlock; virtual;
		procedure LockCursorList(Exclusive: Boolean = True);
		procedure UnlockCursorList;
		procedure WriteTableMetadata(SessionID: TACRSessionID); virtual;
	public
		procedure FreeIfNoSessionsConnected; virtual;
		constructor Create(aDatabaseData: TACRDatabaseData);
		destructor Destroy; override;
    //------------------------ locking methods ---------------------------------
    // lock table
		procedure LockTable(
                        bWriteMode: 			Boolean;
                        Session: 					TACRBaseSession;
                        ErrorCode: 				Integer;
                        DoNotLockThread: 	Boolean = False
                       ); virtual;
    // unlock table
		procedure UnlockTable(
    										bWriteMode: 			Boolean;
                        Session: 					TACRBaseSession;
												DoNotLockThread: 	Boolean = False
                        ); virtual;
    //------------------------ locking methods ---------------------------------

    // table operations
		procedure CreateTable(Cursor: TACRCursor; FieldDefs: TACRFieldDefs;
			IndexDefs: TACRIndexDefs; ConstraintDefs: TACRConstraintDefs); virtual;
			abstract;
		procedure DeleteTable(Session: TACRBaseSession; Cascade: Boolean;
			DesignMode: Boolean = False); virtual;
		procedure EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean = False);
			virtual;
		procedure RenameTable(Cursor: TACRCursor; NewTableName: WideString);
			virtual;
		procedure AddForeignKey(Cursor: TACRCursor;
			ConstraintDef: TACRConstraintDefForeignKey); virtual;
		procedure DeleteConstraint(
                                Cursor:           TACRCursor;
                                Name:             WideString;
                                Cascade:          Boolean;
                                FKPartialDelete:  Boolean
                               ); virtual;
		procedure RenameReferenceTableName(Cursor: TACRCursor;OldName, NewName: WideString); virtual;

		procedure LoadTableFromStream(Cursor: TACRCursor; Stream: TStream); virtual;
		procedure SaveTableToStream(Stream: TStream;
			CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
			CompressionMode: Byte = 0; BlockSize: Integer = 0;
			SkipCheckIsTableOpened: Boolean = False); virtual;
		procedure OpenTable(Cursor: TACRCursor); virtual;
		procedure CloseTable(Cursor: TACRCursor); virtual;

    // Rename Field by Field Index in FieldDefs
		procedure RenameField(Cursor: TACRCursor;
			FieldName, NewFieldName: WideString); virtual;

		procedure AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor); virtual;
		procedure DeleteIndex(IndexID: TACRObjectID; Cursor: TACRCursor); virtual;
		procedure EmptyIndex(IndexID: TACRObjectID; SessionID: TACRSessionID);
			virtual;
		procedure DeleteAllIndexes(Cursor: TACRCursor); virtual;
		procedure EmptyAllIndexes(SessionID: TACRSessionID); virtual;
    // return index name of the index or '' if not found
		function FindIndex(Cursor: TACRCursor; FieldNamesList, AscDescList,
			CaseSensitivityList: TACRWideStringList): WideString;
    // return true if Unique Constraint Failed
		function IsUniqueConstraintFailed(SessionID: TACRSessionID;
			IndexID: TACRObjectID; NewRecordBuffer: TACRRecordBuffer;
			OldRecordBuffer: TACRRecordBuffer; ToInsert: Boolean;
			CurrentRecordID: TACRRecordID): Boolean;
	protected
		procedure RenameConstraintFKTemporaryNames
			(ConstraintDef: TACRConstraintDefForeignKeyAction);
		procedure CheckRecordsCompatibleWithForeignKey(Cursor: TACRCursor;
			ReferencedCursor: TACRCursor; ConstraintDef: TACRConstraintDefForeignKey);
    // return true if current record in Cursor does not violate foreign key constraint
    // (have null field values corresponding match type)
		function IsForeignKeyNullValuesOK(Cursor: TACRCursor;
			ConstraintDef: TACRConstraintDefForeignKey;
			var Failed: Boolean): Boolean;
		procedure CheckForeignKeyOpenReferencedTable(
                  ReferencedCursor:     TACRCursor;
			            Cursor:               TACRCursor;
                  ConstraintDef:        TACRConstraintDefForeignKeyAction;
			            Exclusive:            Boolean = False;
                  SkipExistsCheck:      Boolean = False
                    ); overload;
		procedure CheckForeignKeyOpenReferencedTable(
                ReferencedCursor:     TACRCursor;
			          Session:              TACRBaseSession;
                InMemory:             Boolean;
			          ConstraintDef:        TACRConstraintDefForeignKeyAction;
			          Exclusive:            Boolean = False;
                SkipExistsCheck:      Boolean = False
      ); overload;
		procedure CheckForeignKeyCloseReferencedTable(Cursor: TACRCursor);
		function CheckForeignKeyBuildSearchExpression(ReferencedCursor: TACRCursor;
			Cursor: TACRCursor; ConstraintDef: TACRConstraintDefForeignKey)
			: TACRExpression;
		function CheckForeignKeyActionBuildSearchExpression
			(ReferencedCursor: TACRCursor; Cursor: TACRCursor;
			ConstraintDef: TACRConstraintDefForeignKeyAction;
			ToUpdate: Boolean): Boolean;
		procedure CheckFieldDefinitions(FieldDefs: TACRFieldDefs);
		procedure CheckIndexDefinitions(IndexDefs: TACRIndexDefs);
		procedure CheckConstraintDefinitions(ConstraintDefs: TACRConstraintDefs);
		function CreateForeignKeyAction(Cursor: TACRCursor;
			ConstraintDef: TACRConstraintDefForeignKey;
			ReferencedTableName: WideString; ReferencedTableObjectID: TACRObjectID)
			: TACRConstraintDefForeignKeyAction; virtual;
		procedure CheckForeignKeyDefinition
			(ConstraintDef: TACRConstraintDefForeignKey;
			ReferencedCursor: TACRCursor; SelfReference: Boolean);
		procedure CheckForeignKeyDefinitionsAndCreateForeignKeyActions
			(Cursor: TACRCursor);
		procedure RenameTableInForeignKeys(Cursor: TACRCursor;
			OldTableName: WideString; NewTableName: WideString);
		procedure ExecuteForeignKeyActionsUpdateDetailRecords
			(ReferencedCursor: TACRCursor; Cursor: TACRCursor;
			ConstraintDef: TACRConstraintDefForeignKeyAction;
			Action: TACRConstraintForeignKeyAction);
	public
    // return true if current record in Cursor violates foreign key constraint
		function IsForeignKeyConstraintFailed(Cursor: TACRCursor;
			ConstraintDef: TACRConstraintDefForeignKey): Boolean;
		function IsPrimaryKeyUpdated(Cursor: TACRCursor): Boolean;
		procedure ExecuteForeignKeyActions(
    			Cursor: TACRCursor;
          ToUpdate: Boolean // update or delete
			);
    //---------------- Search and navigation methods ---------------------------
	protected
    // build record bitmap for cursor
		procedure BuildCursorRecordBitmap(Cursor: TACRCursor);
    // function GetBitmapSize(SessionID: TACRSessionID): TACRRecordNo; virtual;
    // return filter bitmap rec no by record id
		function GetBitmapRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo;
			virtual; abstract;
    // return filter bitmap rec no by record id
		function GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo): TACRRecordID;
			virtual; abstract;
    // return true if record is in specified range
		function IsRecordInRange(Cursor: TACRCursor): Boolean;
    // return true if record is visible (with applied filters, ranges, OnFilterRecord)
		function IsRecordVisible(Cursor: TACRCursor): Boolean;

{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
		procedure MergeAndCheckSearchConditionsCompatibility(
                    Condition1:         TACRScanSearchCondition;
			              Condition2:         TACRScanSearchCondition;
                    out Incompatible:   Boolean;
			              out HaveBeenMerged: Boolean
                                                        );
    // sorts Conditions array and removes unnecessary conditions
		procedure OptimizeSearchConditions(
                    Conditions:                   TACRList;
                    out NonCompatibleConditions:  Boolean
                                      );
{$ELSE}
    // returns true if conditions are equal
		function IsEqualConditions(
                                Condition1: TACRScanSearchCondition;
			                          Condition2: TACRScanSearchCondition
                               ): Boolean;
    // removes duplicate conditions
		procedure RemoveDuplicateConditions(
                                        Conditions: TACRScanSearchConditionArray
                                       );
		procedure MergeAndCheckSearchConditionsCompatibility(
                    Condition1:         TACRScanSearchCondition;
			              Condition2:         TACRScanSearchCondition;
                    out Incompatible:   Boolean;
			              out HaveBeenMerged: Boolean
                                                        );
    // sorts Conditions array and removes unnecessary conditions
		procedure OptimizeSearchConditions(
                    var Conditions:               TACRScanSearchConditionArray;
                    out NonCompatibleConditions:  Boolean
                                      );
    // prepare conditions array
		procedure PrepareConditions(
                    Cursor:           TACRCursor;
			              Conditions:       TACRScanSearchConditionArray;
			              KeyCondition:     TACRScanSearchCondition;
                    SearchExpression: TACRExpression;
			              GoForward:        Boolean
                              );
{$ENDIF}
    // try to find the best scan condition with min range record count
		function ChooseScanConditionsWithMinRangeRecordCount(
            SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
			      CurrentIndexID:         TACRObjectID;
            CurrentRecordID:        TACRRecordID;
			      var ScanConditionNo:    Integer;
            var ScanEndConditionNo: Integer
              ): Boolean;
    // if index is defined as unique or contain unique field
		function IsIndexUnique(IndexID: TACRObjectID): Boolean;
    // try to find the best scan condition using heuristics
		function ChooseScanConditionsByHeuristsics(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
        CurrentIndexID:         TACRObjectID;
			  var ScanConditionNo:    Integer;
        var ScanEndConditionNo: Integer
        ): Boolean;
    // if any index exists in conditions without expression will use it
		function ChooseScanConditionsByAnyIndex(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
        CurrentIndexID:         TACRObjectID;
			  var ScanConditionNo:    Integer;
        var ScanEndConditionNo: Integer
        ): Boolean;
    // try to find the best scan condition
		procedure ChooseScanConditions(
                                    SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                                    CurrentIndexID:         TACRObjectID;
			                              CurrentRecordID:        TACRRecordID;
                                    GoForward:              Boolean;
			                              var ScanConditionNo:    Integer;
                                    var ScanEndConditionNo: Integer
                                  );
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // return true if record was found and is visible by cursor
   // prepares params for FindRecordByScan and calls it
		function FindRecord(
                        Cursor:                       TACRCursor;
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                       ): Boolean; virtual;
{$ELSE}
    // return true if record was found and is visible by cursor
    // prepares params for FindRecordByScan and calls it
		function FindRecord(
                        Cursor:                       TACRCursor;
                        SearchExpression:             TACRExpression;
                        // locate
                        KeyCondition:                 TACRScanSearchCondition; // find key
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                       ): Boolean; virtual;
{$ENDIF}
    // return true if record match specified condition
		function IsRecordMatchCondition(
      Condition:    TACRScanSearchCondition;
			RecordBuffer: TACRRecordBuffer
                                    ): Boolean;
    // return true if record match specified conditions
		function IsRecordMatchConditions(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
			      ExcludedConditionNo:    Integer; // INVALID_ID4 if not specified
			      ExcludedConditionNo2:   Integer; // INVALID_ID4 if not specified
			      FilterRecordPtr:        Pointer;
            Dataset:                Pointer;
			      RecordBuffer:           TACRRecordBuffer
                                    ): Boolean;
		function IsRecordMatchConditionsExists(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
            ExcludedConditionNo:    Integer;
            // INVALID_ID4 if not specified
            ExcludedConditionNo2:   Integer; // INVALID_ID4 if not specified
            FilterRecordPtr:        Pointer
                                          ): Boolean;

    // scan all records and check conditions
		function FindRecordByScanWithoutCondition(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;

    // find records by index and condition specified by ScanConditionNo
    // condition index is the same as CurrentIndex
		function FindRecordByScanWithConditionAndConditionIndex(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;

    // find records by index and condition specified by ScanConditionNo
    // there is no active index
		function FindRecordByScanWithConditionAndWihtoutCurrentIndex(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;

    // sort record ID array by positions in the index
		procedure SortRecordIDByIndex(
                                  Records:          TACRRecordIDArray;
                                  IndexPositions:   TList;
                                  CurrentIndexID:   TACRObjectID
                                  // INVALID_OBJECT_ID if not specified
                                  );

    // find records by index and condition specified by ScanConditionNo
    // condition index is NOT the same as CurrentIndex
		function FindRecordByScanWithConditionAndNonConditionIndex(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;

    // return true if record was found
		function FindRecordByScan(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;
    // used by GetRecordBuffer - find or get record
		function InternalFindOrGetRecordBuffer(
                                            Cursor:         TACRCursor;
                                            GetRecordMode:  TACRGetRecordMode;
                                            // if specified - fill record bitmap
                                            RecordBitmap:   TACRRecordBitmap = nil
                                          ): TACRGetRecordResult;
    // get record using current index or physical order
		procedure InternalGetRecordBuffer(SessionID: TACRSessionID;	var NavigationInfo: TACRNavigationInfo);
		procedure UpdateRecordBitmapAfterInsertRecord(Cursor: TACRCursor;	Pos: Pointer);
		procedure UpdateRecordBitmapAfterUpdateRecord(Cursor: TACRCursor);
	public
		function IsRecordExists(Cursor: TACRCursor): Boolean; virtual;
    // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
		function CompareRecordID(const RecordID1: TACRRecordID;
			const RecordID2: TACRRecordID): Integer; virtual; abstract;
    // read record with Distinct, SQLFilter, SQLTopRowCount, Filter, Range, OnFilterRecord
		function GetRecordBuffer(Cursor: TACRCursor;
			GetRecordMode: TACRGetRecordMode): TACRGetRecordResult; virtual;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // locate
		function Locate(
                    Cursor:           TACRCursor;
                    const KeyFields:  WideString;
                    const KeyValues:  Variant;
                    CaseInsensitive:  Boolean;
                    PartialKey:       Boolean
                   ): Boolean; virtual;
{$ELSE}
    // locate
		function Locate(Cursor: TACRCursor; SearchExpression: TACRExpression): Boolean;
{$ENDIF}
    // find key
		function FindKey(Cursor: TACRCursor; SearchCondition: TACRSearchCondition): Boolean;

    //---------------------------------------------------------------------------
    // BLOB methods
    //---------------------------------------------------------------------------
		function IsBLOBModified(RecordBuffer: TACRRecordBuffer;
			FieldDef: TACRFieldDef): Boolean;

		procedure SetBLOBModified(Modified: Boolean;
			RecordBuffer: TACRRecordBuffer; FieldDef: TACRFieldDef);

		function InternalCreateBlobStream(Cursor: TACRCursor; ToInsert: Boolean;
			FieldNo: Integer; OpenMode: TACRBLOBOpenMode): TACRStream; virtual;

		procedure WriteBLOBFieldToRecordBuffer(Cursor: TACRCursor;
			FieldNo: Integer; BLOBStream: TACRStream); virtual;

		procedure ClearBLOBFieldInRecordBuffer(var RecordBuffer: TACRRecordBuffer;
			FieldNo: Integer); virtual;

		procedure ClearBLOBFieldsInRecordBuffer(var RecordBuffer: TACRRecordBuffer);

    // check constraint conditions
		procedure CheckConstraints(Cursor: TACRCursor; SessionID: TACRSessionID;
			NewRecordBuffer: TACRRecordBuffer; OldRecordBuffer: TACRRecordBuffer;
			ToInsert: Boolean; CurrentRecordID: TACRRecordID;
			SkipFKCheck: Boolean = False); virtual;
		procedure ShowRecord(Cursor: TACRCursor);
		function InsertRecord(var Cursor: TACRCursor): Boolean; virtual; abstract;
		function DeleteRecord(Cursor: TACRCursor): Boolean; virtual; abstract;
		function UpdateRecord(Cursor: TACRCursor): Boolean; virtual; abstract;
		procedure EditRecord(Cursor: TACRCursor); virtual;
		procedure ClearTemporaryBLOBValues(Cursor: TACRCursor);
		procedure SetBLOBValuesModified(Modified: Boolean; Cursor: TACRCursor);
		procedure CancelRecord(Cursor: TACRCursor; ToInsert: Boolean); virtual;
		procedure DeleteVisibleRecords(Cursor: TACRCursor); virtual;
		procedure UpdateVisibleRecords(
                                    Cursor:         TACRCursor;
                                    FieldNames:     TACRWideStringList;
                                    values:         array of TACRVariant;
                                    SkipFKCheck:    Boolean = False
                                  ); virtual;
    // record operations
		function GetRecordCount(Cursor: TACRCursor;
			InternalCall: Boolean = False): TACRRecordNo; virtual;
		procedure SetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo); virtual;
		function GetRecNo(Cursor: TACRCursor): TACRRecordNo; virtual;

		procedure InternalSetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo);
			virtual; abstract;
		function InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo; virtual;
			abstract;
		function InternalGetRecordCount: TACRRecordNo;

		function LastAutoincValue(FieldNo: Integer;
			Session: TACRBaseSession): Int64; virtual;
		procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer;
			Cursor: TACRCursor); virtual;
    //------------------ page management for the table -------------------------
    // add page to the page manager
		function AddPage(SessionID: TACRSessionID;
      // state type of the locked object that calls this method
			StateType: TACRDBStateType;
      // current state of the locked object that calls this method
			State: TACRState;
      // if true - page will not be used without calling GetPage
			DoNotUse: Boolean = False): TACRPage;
    // delete page in the page manager
		procedure RemovePage(SessionID: TACRSessionID; pageNo: TACRPageNo;
			StateType: TACRDBStateType; State: TACRState);
    // add pages to the page manager
		procedure AddPages(
      // place page numbers of new allocated pages at the end of the array
			Pages: TACRPageArray;
      // how much pages to add
			NumPagesToAdd: Cardinal;
      // pages must be in consecutive order (n,n+1,n+2...)
			ConsecutiveOrder: Boolean; SessionID: TACRSessionID;
      // state type of the locked object that calls this method
			StateType: TACRDBStateType;
      // current state of the locked object that calls this method
			State: TACRState;
      // if true - page will not be used without calling GetPage
			DoNotUse: Boolean = False);
    // delete pages in the page manager
		procedure RemovePages(Pages: TACRPageArray; SessionID: TACRSessionID;
      // state type of the locked object that calls this method
			StateType: TACRDBStateType; State: TACRState;
			NumPagesFromEnd: Cardinal = 0);
    // read existing page from cache or from PageManager (disk / memory / temporary)
		function GetPage(SessionID: TACRSessionID; pageNo: TACRPageNo;
      // state type of the locked object that calls this method
			StateType: TACRDBStateType;
      // current state of the locked object that calls this method
			State: TACRState;
      // read current page data from page manager if not in cache
			ReadPage: Boolean = True;
      // this page will be updated
			UpdatePage: Boolean = False;
      // the page should be updated and original will be copied to shared pages
			MakeCopy: Boolean = False): TACRPage;
    // page is read or updated
		procedure PutPage(Page: TACRPage);
    // must be called before updating page data
		procedure UpdatePage(SessionID: TACRSessionID; Page: TACRPage;
      // state type of the locked object that calls this method
			StateType: TACRDBStateType;
      // current state of the locked object that calls this method
			State: TACRState;
      // the page should be updated and original will be copied to shared pages
			MakeCopy: Boolean = False);
    // apply all changes made by active session
		procedure ApplyChanges(
      // current state of the locked object that calls this method
			State1: TACRState;
      // StateType2 is for table metadata state only
			StateType2: TACRDBStateType = dbstNone;
      // State2 is for table metadata state only
			State2: TACRState = 0); virtual;
    // cancel all changes made by active session
		procedure CancelChanges;
    //------------------ page management for the table -------------------------
		function CheckCannotOpenExclusive(Cursor: TACRCursor): Boolean;
	public
		property BLOBFieldsPresent: Boolean read FBLOBFieldsPresent;
		property TableName: WideString read FTableName write SetTableName;
		property DatabaseData: TACRDatabaseData read FDatabaseData;
		property FieldManager: TACRBaseFieldManager read FFieldManager;
		property RecordManager: TACRBaseRecordManager read FRecordManager;
		property ConstraintManager
			: TACRBaseConstraintManager read FConstraintManager;
		property IndexManager: TACRBaseIndexManager read FIndexManager;
		property PageManager: TACRPageManager read GetPageManager;
		property InMemory: Boolean read FInMemory;
		property Temporary: Boolean read FTemporary;
		property TableID: TACRObjectID read GetTableID;
		property CursorList: TList read FCursorList;
		property TableNameCRC: Cardinal read FTableNameCRC;
		property TableState: TACRTableState read FTableState;
		property LastTableOperation
			: TACRLastTableOperation read GetLastTableOperation;
		property Comment: WideString read FComment write FComment;
		property CreationDate: TDateTime read FCreationDate write FCreationDate;
	end; // TACRTableData

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRTableLockManager
  //
  // manages table locking - both disk and memory engines
  //
  // ltX - exclusive lock, applied on table opening in exclusive mode
  // ltIS - shared lock, applied on table opening in shared mode
  // ltS - SELECT lock, applied before reading data / opening SELECT query
  // ltIRW - set by transaction that modified the table data, checked in EditRecord in file-server,
  // also set by SQL UPDATE / DELETE statement in case if record check events are assigned
  // ltRW - set by Commit, Insert, Delete, Update, etc.
  // ltU - set by EditRecord
  //
  // lock compatibility matrix (inc - incremental, i.e. can be applied recursively by each session):
  //
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // | Lock Type      | ltX   | ltIS  | ltS   | ltIRW | ltRW  |      ltU       |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // |     ltX        |   -   |   -   +   -   |   -   |   -   |       -        |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // |    ltIS (inc)  |   -   |   +   +   +   |   +   |   +   |       +        |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // |    ltS (inc)   |   -   |   +   +   +   |   +   |   -   |       +        |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // |   ltIRW (inc)  |   -   |   +   +   +   |   -   |   -   |       +        |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // |     ltRW       |   -   |   +   +   -   |   -   |   -   |       +        |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  // |     ltU        |   -   |   +   +   -   |   -   |   -   | different rows |
  // +----------------+-------+-------+-------+-------+-------+----------------+
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRLockTableInFileServer = function(PSessionLockInfo: PACRSessionLockInfo)
		: Boolean of object;
	TACRUnlockTableInFileServer = function(PSessionLockInfo: PACRSessionLockInfo)
		: Boolean of object;
	TACRClearWaitLevelInFileServer = procedure
		(PSessionLockInfo: PACRSessionLockInfo) of object;

	TACRTableLockManager = class(TObject)
	private
		FThreadSync:                  TACRReadWriteThreadSyncBySingleCriticalSection;
		FThreadSyncTransactions:      TACRReadWriteThreadSyncBySingleCriticalSection;
		FThreadSyncLockTable:         TACRReadWriteThreadSyncBySingleCriticalSection;
		FFileServer:                  Boolean;
		FMaxWaitLockTime:             Cardinal; // maximum time in milliseconds to lock the table
		FNormalDelay:                 Cardinal;
		FShortDelay:                  Cardinal;
		FMinDelay:                    Cardinal;
		LTableData:                   TACRAdvancedTableData;
		FLockTableInFileServer:       TACRLockTableInFileServer;
		FUnlockTableInFileServer:     TACRUnlockTableInFileServer;
		FClearWaitLevelInFileServer:  TACRClearWaitLevelInFileServer;
		FTableLockInfo:               TACRTableLockInfo;
		FSessionLocks:                TList; // list of PACRSessionLockInfo
		FWaitingSessionLocks:         TList; // list of PACRSessionLockInfo - copies of FSessionLock if isWaiting = true
		FTransactionLocks:            TList; // list of PACRSessionLockInfo
	protected
		procedure Lock(Exclusive: Boolean);
		procedure Unlock;
		procedure LockTransactions(Exclusive: Boolean);
		procedure UnlockTransactions;
		procedure IncLockCounter(PSessionLock: PACRSessionLockInfo);
		procedure DecLockCounter(PSessionLock: PACRSessionLockInfo;
			UnlockAll: Boolean);
    // return wait time for sleeping after lock failed
		function GetLockWaitTime(const CurrentWaitTime: Cardinal): Cardinal;
    // return true if we cannot lock table because of more priority sessions
    // are already waiiting it in the current process
		function IsMorePriorityLockExists(PSessionLock: PACRSessionLockInfo): Boolean;
    // return true if this lock cannot be applied due to conflict with existing locks
		function IsLockCanBeApplied(PSessionLock: PACRSessionLockInfo): Boolean;
    // if we already have this lock - ok, just increment counter
		function IsLockAlreadyApplied(PSessionLock: PACRSessionLockInfo): Boolean;
    // try to lock the table until time limit set by FMaxWaitLockTime
		function InternalLockTable(SessionID: TACRSessionID;
			LockType: TACRLockType; PRecordID: PACRRecordID;
			var PSessionLock: PACRSessionLockInfo): Boolean;
    // unlock table
		procedure InternalUnlockTable(PSessionLock: PACRSessionLockInfo;
			UnlockAll: Boolean; LockType: TACRLockType);
		procedure UnlockAll;
	public
		constructor Create(aTableData: TACRAdvancedTableData; aFileServer: Boolean);
		destructor Destroy; override;
    // try to lock the table until time limit set by FMaxWaitLockTime
		function LockTable(
                        SessionID:      TACRSessionID;
                        LockType:       TACRLockType;
			                  PRecordID:      PACRRecordID;
                        bInTransaction: Boolean = False
                      ): Boolean;
    // unlock table
		procedure UnlockTable(SessionID: TACRSessionID; LockType: TACRLockType);
    // decrement number of locks by this session and removes all locks if their number = 0
    // if PTableLockInfo = nil - all table locks by this session will be removed
		function UnlockSessionAll(SessionID: TACRSessionID): Boolean;
    // return true if lock successfully set, otherwise return false and session item
		function TryToLockRWForCommit(SessionID: TACRSessionID): Boolean;
    // remove all transaction locks
		procedure FinishTransaction(SessionID: TACRSessionID);
{$IFDEF DEBUG_LOG}
	private
		procedure WriteAllLocks;
{$ENDIF}
	public
		property LockTableInFileServer: TACRLockTableInFileServer read FLockTableInFileServer write	FLockTableInFileServer;
		property UnlockTableInFileServer: TACRUnlockTableInFileServer read FUnlockTableInFileServer write	FUnlockTableInFileServer;
		property ClearWaitLevelInFileServer: TACRClearWaitLevelInFileServer read FClearWaitLevelInFileServer	write FClearWaitLevelInFileServer;
		property FileServer: Boolean read FFileServer;
		property MaxWaitLockTime: Cardinal read FMaxWaitLockTime;  // maximum time in milliseconds to lock the table
	end; // TACRTableLockManager

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRAdvancedTableData
  // base class for TACRMemTableData and TACRDiskTableData
  // manages locking, transactions and multiple sessions
  //
  ////////////////////////////////////////////////////////////////////////////////

  {
    TACRMostUpdatedData = record
    FSequenceManager: TACRBaseSequenceManager;
    FRecordManager:   TACRBaseRecordManager;
    FIndexManager:    TACRBaseIndexManager;
    end;
  }

	TACRAdvancedTableData = class(TACRTableData)
	private
		FLockSync: TACRReadWriteThreadSyncBySingleCriticalSection;
		FLockCount: Cardinal;
    // used to prevent problems with access not thread sage RecordManager, IndexManager and SequenceManager
    // from multiple sessions - will be removed later
		FSessionsSync: TACRReadWriteThreadSyncBySingleCriticalSection;
	protected
		FMUDLoaded: 						Boolean;
		FMUDState: 							TACRState; // state of table when MUD that was loaded last time
		FTransactionMUD: 				Boolean;
		FIsTableOpened: 				Boolean;
    // transactions related parameters
    // FCurrentMUD:                  TACRMostUpdatedData; // current table parameters (Most Updated Data) that can be changed by the transaction - for other sessions reading the table
    // FActiveMUD:                   TACRMostUpdatedData; // table parameters that is being changed by the active transaction - for active session only
    // FTempMUD:                     TACRMostUpdatedData;
    // FActiveMUDCreated:            Boolean;
    // for exclusive mode
		FTransactionSync: 			TACRReadWriteThreadSyncBySingleCriticalSection;
		FTransactionCount: 			Cardinal; // total number of transactions
		FTransactionSessionID: 	TACRSessionID; // SessionID if there is writing transaction
		FLockManager: 					TACRTableLockManager;
	protected
		procedure ReadMostUpdatedData(SessionID: TACRSessionID); virtual;
		procedure WriteMostUpdatedData(SessionID: TACRSessionID); virtual;
		procedure RestoreMostUpdatedData(SessionID: TACRSessionID);
    // for memory table only
		procedure InternalEmptyTable(SessionID: TACRSessionID); virtual; abstract;
		function GetMaxWaitLockTime: Cardinal;
	public
		constructor Create(aDatabaseData: TACRDatabaseData);
		destructor Destroy; override;
    //------------------------ locking methods ---------------------------------
    // lock table
		procedure LockTable(
                        bWriteMode: 			Boolean;
                        Session: 					TACRBaseSession;
                        ErrorCode: 				Integer;
                        DoNotLockThread: 	Boolean = False
                       ); override;
    // unlock table
		procedure UnlockTable(
    										bWriteMode: 			Boolean;
                        Session: 					TACRBaseSession;
												DoNotLockThread: 	Boolean = False
                        ); override;
    // lock / unlock functions
		function TryToLockTableS(aSessionID: TACRSessionID;
			bInTransaction: Boolean): Boolean;
		procedure TryToUnlockTableS(aSessionID: TACRSessionID);
		function TryToLockTableIRW(aSessionID: TACRSessionID;
			bInTransaction: Boolean): Boolean;
		procedure TryToUnlockTableIRW(aSessionID: TACRSessionID);
		function TryToLockTableRW(aSessionID: TACRSessionID): Boolean;
		procedure TryToUnlockTableRW(aSessionID: TACRSessionID);
		function TryToLockTableX(aSessionID: TACRSessionID): Boolean;
		procedure TryToUnlockTableX(aSessionID: TACRSessionID);
		function TryToLockTableIS(aSessionID: TACRSessionID): Boolean;
		procedure TryToUnlockTableIS(aSessionID: TACRSessionID);
		function TryToLockRecordU(aSessionID: TACRSessionID;
			const aRecordID: TACRRecordID): Boolean;
		procedure TryToUnlockRecordU(aSessionID: TACRSessionID;
			const aRecordID: TACRRecordID);
		procedure RemoveAllSessionLocks(aSessionID: TACRSessionID);
    //------------------ transactions ------------------------------------------
		procedure Commit(aSessionID: TACRSessionID);
		procedure Rollback(aSessionID: TACRSessionID);
    // return true if lock set successfully, if PSessionLock = nil - no need to commit, S only
		function TryToLockRWForCommit(SessionID: TACRSessionID): Boolean;
    //--------------------- not exclusive operations with records --------------
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // locate
		function Locate(
                    Cursor:           TACRCursor;
                    const KeyFields:  WideString;
                    const KeyValues:  Variant;
                    CaseInsensitive:  Boolean;
                    PartialKey:       Boolean
                   ): Boolean; override;
    // return true if record was found and is visible by cursor
    // prepares params for FindRecordByScan and calls it
		function FindRecord(
                        Cursor:                       TACRCursor;
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                       ): Boolean; override;
{$ELSE}
    // return true if record was found and is visible by cursor
    // prepares params for FindRecordByScan and calls it
		function FindRecord(
                        Cursor:                       TACRCursor;
                        SearchExpression:             TACRExpression;
                        // locate
                        KeyCondition:                 TACRScanSearchCondition; // find key
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                       ): Boolean; override;
{$ENDIF}
		function IsRecordExists(Cursor: TACRCursor): Boolean; override;
    // read record with Distinct, SQLFilter, SQLTopRowCount, Filter, Range, OnFilterRecord
		function GetRecordBuffer(Cursor: TACRCursor;
			GetRecordMode: TACRGetRecordMode): TACRGetRecordResult; override;
		function InsertRecord(var Cursor: TACRCursor): Boolean; override;
		function DeleteRecord(Cursor: TACRCursor): Boolean; override;
		function UpdateRecord(Cursor: TACRCursor): Boolean; override;
		procedure EditRecord(Cursor: TACRCursor); override;
		procedure CancelRecord(Cursor: TACRCursor; ToInsert: Boolean); override;
		procedure DeleteVisibleRecords(Cursor: TACRCursor); override;
		procedure UpdateVisibleRecords(Cursor: TACRCursor;
			FieldNames: TACRWideStringList; values: array of TACRVariant;
			SkipFKCheck: Boolean = False); override;
    // record operations
		function GetRecordCount(Cursor: TACRCursor;
			InternalCall: Boolean = False): TACRRecordNo; override;
		procedure SetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo); override;
		function GetRecNo(Cursor: TACRCursor): TACRRecordNo; override;
		function LastAutoincValue(FieldNo: Integer;
			Session: TACRBaseSession): Int64; override;
		procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer;
			Cursor: TACRCursor); override;
    //--------------------- not exclusive operations with records --------------
    // apply all changes made by active session
		procedure ApplyChanges(
      // current state of the locked object that calls this method
			State1: TACRState;
      // StateType2 is for table metadata state only
			StateType2: TACRDBStateType = dbstNone;
      // State2 is for table metadata state only
			State2: TACRState = 0); override;
	public
		property Exclusive: Boolean read FExclusive;
    // property TransactionS: Boolean read FTransactionS;
    // property TransactionIRW: Boolean read FTransactionIRW;
		property TransactionSessionID: TACRSessionID read FTransactionSessionID;
		property MaxWaitLockTime: Cardinal read GetMaxWaitLockTime;
	end; // TACRAdvancedTableData

  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRTransaction
  // created by TACRLocalSession
  // single object can be used only by single local session and inside single thread
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRTransaction = class(TObject)
	private
		FSession: TACRBaseSession;
		FSessionID: TACRSessionID;
		FDatabaseData: TACRDatabaseData;
		FIsFinished: Boolean;
    // list of tables involved in the transaction (S/IRW)
		FTableDataList: TList;
	protected
    // return true if all tables successfully locked
		function TryToChangeIRWLockToRWLock: Boolean;
	public
		constructor Create(aSession: TACRBaseSession;
			aDatabaseData: TACRDatabaseData);
		destructor Destroy; override;
		procedure Commit(FlushFileBuffers: Boolean = True);
		procedure Rollback;
    // add table data to list of tables used by transaction
		function AddTableData(TableData: TACRTableData): Boolean;
	end; // TACRTransaction


  ////////////////////////////////////////////////////////////////////////////////
  //
  // TACRDatabaseData
  //
  ////////////////////////////////////////////////////////////////////////////////

	TACRDatabaseData = class(TObject)
	private
		FThreadSync: TACRReadWriteThreadSyncByCriticalSections;
	protected
		FSessionList: TList;
		FTableDataList: TList;
		FDatabaseName: AnsiString;
		FDatabaseNameUnicode: WideString; // file name
		FObjectIdSequence: TACRSequenceDef; // sequence for new ObjectID
		FPageManager: TACRPageManager;
		FInMemory: Boolean; // TACRMemoryDatabaseData
		FTemporary: Boolean; // TACRTemporaryDatabaseData
		FLockParams: TACRLockParams;
		FStoredFunctionsManager: TObject;
	protected
		procedure Lock(WriteMode: Boolean = False);
		procedure Unlock;
	protected
		function GetNewSessionID: TACRSessionID;
		procedure DeleteAllTables;
		procedure AddTableData(TableData: TACRTableData);
		procedure DeleteTableData(TableData: TACRTableData);
		procedure AddSession(Session: TACRBaseSession);
		procedure DeleteSession(Session: TACRBaseSession);
		function GetSessionsCount: Integer;
		procedure InternalGetTablesList(Session: TACRBaseSession;	List: TACRWideStringList); virtual;
	public
		constructor Create;
		destructor Destroy; override;
		procedure ConnectSession(Session: TACRBaseSession); virtual;
		procedure DisconnectSession(Session: TACRBaseSession); virtual;
		procedure FreeIfNoSessionsConnected; virtual;
		procedure GetTablesList(Session: TACRBaseSession;	List: TACRWideStringList); virtual;
		function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray; virtual;
		function GetTableState(TableName: WideString): TACRTableState; virtual;
		function TableExists(Session: TACRBaseSession;	TableName: WideString): Boolean; virtual;
    // load local memory database
		procedure LoadDatabaseFromStream(Session: TACRBaseSession;
			Stream: TStream); virtual; abstract;
    // save local memory database
		procedure SaveDatabaseToStream(Session: TACRBaseSession; Stream: TStream;
			CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
			CompressionMode: Byte = 0;
			BlockSize: Integer = ACRDefaultSaveBlockSize); virtual; abstract;
		procedure CreateDatabase(Session: TACRBaseSession); virtual;
    // create table data
		function CreateTableData(Cursor: TACRCursor): TACRTableData; virtual;
			abstract;
    // find table data
		function FindTableData(Cursor: TACRCursor): TACRTableData; virtual;
    // find or create table data
		function FindOrCreateTableData(Cursor: TACRCursor): TACRTableData; virtual;
    // get new ObjectId
		function GetNewObjectId: TACRObjectID;
    // flush file buffers
		procedure FlushFileBuffers; virtual;
    // return database format version
		function GetFormatVersion(Session: TACRBaseSession): Double; virtual;
    // return total number of pages
		function GetTotalPageCount(Session: TACRBaseSession): Integer; virtual;
    // return number of free pages
		function GetFreePageCount(Session: TACRBaseSession): Integer; virtual;
    // return true if database is encrypted
		function IsDatabaseEncrypted(Session: TACRBaseSession): Boolean; virtual;
    // return true if database is encrypted by password or by key
		function IsDatabaseEncryptedByPassword(Session: TACRBaseSession): Boolean;
			virtual;
    // return true if CryptoParams are valid
		function IsCryptoParamsValid(Session: TACRBaseSession): Boolean; virtual;
    // makes Exe database from edb file
		procedure MakeExeDatabase(Session: TACRBaseSession;
			ExeFileName, ExeDatabaseFileName: WideString); virtual;
    // removes database file from executable database file
		procedure RemoveDatabaseFromExe(Session: TACRBaseSession); virtual;
    // returns true if this file is an Accuracer database
		function IsAccuracerDatabaseFile(Session: TACRBaseSession): Boolean;
			virtual;
		procedure ClearCache;
		procedure RemoveAllLocks(SessionID: TACRSessionID);
    // return table comment if table exists, otherwise empty string
		function GetTableComment(TableName: WideString): WideString; virtual;
    // set table comment
		procedure SetTableComment(TableName, Comment: WideString); virtual;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
    // create stored function / procedure
		procedure CreateStoredFunction(Session: TACRBaseSession; SQLScript: WideString); overload;
    // for CREATE FUNCTON inside SQL script
    // current token is rwFUNCTION/rwPROCEDURE
		procedure CreateStoredFunction(StoredFunction: TObject; SQLScript: WideString); overload;
		procedure ParseStoredFunction(Session: TACRBaseSession; Lexer: TACRLexer;
			var Token: TToken; out StoredFunction: TObject;
			out SQLScript: WideString);
    // drop stored function / procedure
		procedure DropStoredFunction(Session: TACRBaseSession;
			FunctionName: WideString);
    // ALTER stored function - modify script
		procedure AlterStoredFunction(Session: TACRBaseSession;
			FunctionName, NewSQLScript: WideString);
    // ALTER stored function - rename
		procedure AlterStoredFunctionRename(Session: TACRBaseSession;
			FunctionName, NewFunctionName: WideString);
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    // params - list of TACRSQLParam
		function ExecuteStoredFunction(Session: TACRBaseSession;
			FunctionName: WideString; ResultValue: TACRVariant;
			Params: TACRSQLParams = nil // TACRExpressions
			): Boolean;
    // return empty string if function not found; otherwise
    // return SQL script that created this function (CREATE FUNCTION ...)
		function FindStoredFunction(FunctionName: WideString): WideString;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TACRExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TObject;
    // parse for execute
    // return stored function object (TACRStoredFunction) if found or nil
    // params - list of TACRExpression
		function ParseStoredFunctionParams(
                                        Session:          TACRBaseSession;
                                        Lexer:            TACRLexer;
                                        parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                                        var Token:        TToken;
                                        out Params:       TObject
                                      ): TObject;
    // return list of stored function names (optionally SQL scripts for their creation)
		procedure GetStoredFunctions(FunctionNames: TStrings;
			FunctionSQLScripts: TStrings = nil;
			SortNamesByAlphabet: Boolean = True); overload;
    // return list of stored function names (optionally SQL scripts for their creation)
		procedure GetStoredFunctions(FunctionNames: TACRWideStringList;
			FunctionSQLScripts: TACRWideStringList = nil;
			SortNamesByAlphabet: Boolean = True); overload;
    // export all stored functions to SQL
		procedure ExportStoredFunctionsToSQL(var SQL: WideString);
    //-------- END OF STORED FUNCTIONS AND PROCEDURES - added in v.5.10 --------

    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                        ); virtual;
    // drop view
    procedure DropView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      ); virtual;
    // return nil if not found, otherwise return view definition
    function FindView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString
                     ): TACRViewDef; virtual;
    //--------------------- END OF VIEWS - added in v.6.00 ---------------------
	public
		property DatabaseName: AnsiString read FDatabaseName write FDatabaseName;
		property DatabaseNameUnicode: WideString read FDatabaseNameUnicode write FDatabaseNameUnicode;
		property ObjectIdSequence: TACRSequenceDef read FObjectIdSequence;
		property PageManager: TACRPageManager read FPageManager write FPageManager;
		property SessionsCount: Integer read GetSessionsCount;
		property LockParams: TACRLockParams read FLockParams write FLockParams;
	end; // TACRDatabaseData

  ////////////////////////////////////////////////////////////////////////////////
  //
  // General functions and procedures
  //
  ////////////////////////////////////////////////////////////////////////////////

  // return false if field value is null
function GetFieldData(
  // field number in FieldDefs
	FieldNo: Integer;
  // field definitions
	FieldDefs: TACRFieldDefs;
  // pointer to allocated buffer for storing field value
	Buffer: Pointer;
  // record buffer
	RecordBuffer: TACRRecordBuffer): Boolean;

// returns false if field value is null
procedure SetFieldData(
  // physical field No
	FieldNo: Integer;
  // field definitions
	FieldDefs: TACRFieldDefs;
  // pointer to allocated buffer with new field value
	Buffer: Pointer;
  // record buffer
	RecordBuffer: TACRRecordBuffer);

// return true if record buffers are binary identical
function CompareRecordBuffers(RecordBuffer1, RecordBuffer2: TACRRecordBuffer;
	RecordBufferSize: Integer): Boolean;
{$IFNDEF SQLMEMTABLE}
// compresses and encrypts buffer
procedure CompressAndEncryptBuffer(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; InBuffer: PAnsiChar;
	InSize: Integer; out OutBuffer: PAnsiChar; out OutSize: Integer);
// decompresses and decrypts buffer; return true if successful
function DecompressAndDecryptBuffer(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; var Buffer: PAnsiChar;
	var BufferSize: Integer): Boolean;

procedure CompressAndEncryptStream(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; BlockSize: Integer;
	SourceStream: TACRStream; DestStream: TACRStream;
	OnProgress: TACRProgressEvent = nil);

function DecompressAndDecryptStream(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; BlockSize: Integer;
	SourceStream: TACRStream; DestStream: TACRStream;
	OnProgress: TACRProgressEvent = nil): Boolean;

procedure ACREncryptStreamTOString(ms: TACRMemoryStream; out encString: String);
procedure ACRDecryptStringToStream(ms: TACRMemoryStream;
	const encString: String);
{$ENDIF}
// find TACRDatabaseData object in global list of the databases
function ACRFindDatabaseData(InMemory, Temporary: Boolean;
	DatabaseName: AnsiString; DatabaseNameUnicode: WideString = '')
	: TACRDatabaseData;
// used for random object identifiers
function ACRGenerateRandomCardinal: Cardinal;
// return true if locks are compatible
function ACRIsLockCompatible(PNewSessionLock,
	PCurSessionLock: PACRSessionLockInfo): Boolean;
// return true if PNewSessionLock has higher priority
function ACRIsLockPriorityHigher(PNewSessionLock,
	PCurSessionLock: PACRSessionLockInfo): Boolean;
procedure ACRSetTableFlag(var TableState: TACRTableState; ToSet: Boolean;
	Flag: TACRTableFlags);
function ACRGetTableFlag(var TableState: TACRTableState;
	Flag: TACRTableFlags): Boolean;
{$IFDEF DEBUG_LOG}
procedure ACRWriteSessionLockInfo(PSessionLock: PACRSessionLockInfo;
	MaxWaitTime: Cardinal);
procedure ACRWriteTransactionLockInfo
	(PTransactionLock: PACRTransactionLockInfo);
procedure ACRWriteTableLockInfo(var TableLock: TACRTableLockInfo);
{$ENDIF}

implementation

uses

  // Accuracer units
	ACRStoredFunctions,
	ACRMain,
	ACRBTree,
	ACRLocalEngine,
	ACRMemory // last
	;

////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseRecordManager
//
////////////////////////////////////////////////////////////////////////////////

(*
//------------------------------------------------------------------------------
  // lock
//------------------------------------------------------------------------------
  procedure TACRBaseRecordManager.Lock(WriteMode: Boolean);
  begin
  {$I ACRThreadSync_3.inc}
  end;// Lock


//------------------------------------------------------------------------------
  // unlock
//------------------------------------------------------------------------------
  procedure TACRBaseRecordManager.Unlock;
  begin
  {$I ACRThreadSync_4.inc}
  end;// Unlock
*)

//------------------------------------------------------------------------------
// return record count
//------------------------------------------------------------------------------
function TACRBaseRecordManager.GetRecordCount: TACRRecordNo;
begin
Result := FRecordCount;
end; // GetRecordCount

//------------------------------------------------------------------------------
// update record, return true if record was updated, false if record was deleted
//------------------------------------------------------------------------------
function TACRBaseRecordManager.UpdateRecord(RecordBuffer: TACRRecordBuffer;
	RecordID: TACRRecordID; SessionID: TACRSessionID): Boolean;
begin
Result := False;
end; // UpdateRecord

//------------------------------------------------------------------------------
// delete record, return true if record was deleted, false if record was deleted earlier
//------------------------------------------------------------------------------
function TACRBaseRecordManager.DeleteRecord(var RecordID: TACRRecordID;
	SessionID: TACRSessionID): Boolean;
begin
Result := False;
end; // DeleteRecord

//------------------------------------------------------------------------------
// Load from stream
//------------------------------------------------------------------------------
procedure TACRBaseRecordManager.LoadFromStream(Stream: TStream);
begin ;
end; // LoadFromStream

//------------------------------------------------------------------------------
// Save from stream
//------------------------------------------------------------------------------
procedure TACRBaseRecordManager.SaveToStream(Stream: TStream);
begin ;
end; // SaveToStream

//------------------------------------------------------------------------------
// add loaded record
//------------------------------------------------------------------------------
procedure TACRBaseRecordManager.AddLoadedRecord(RecordBuffer: TACRRecordBuffer;
	var RecordPos: Integer);
begin ;
end; // SaveToStream

////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseFieldManager
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRBaseFieldManager.Create(TableData: TACRTableData;
	SequenceManager: TACRBaseSequenceManager);
begin
FTableData := TableData;
FFieldDefs := TACRFieldDefs.Create;
FSequenceManager := SequenceManager;
FEngineVersion := ACRVersion;
end; // Create

//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRBaseFieldManager.Destroy;
begin
FFieldDefs.Free;
end; // Destroy

//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRBaseFieldManager.LoadFromStream(Stream: TStream);
begin
FieldDefs.EngineVersion := FEngineVersion;
FieldDefs.LoadFromStream(Stream);
end; // LoadFromStream

//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRBaseFieldManager.SaveToStream(Stream: TStream);
begin
FieldDefs.EngineVersion := FEngineVersion;
FieldDefs.SaveToStream(Stream);
end; // SaveToStream

//------------------------------------------------------------------------------
// apply new auto-inc values to record buffer
//------------------------------------------------------------------------------
procedure TACRBaseFieldManager.ApplyAutoIncValuesToRecordBuffer(
          Session:        TACRBaseSession;
          RecordBuffer:   TACRRecordBuffer
          );
var
	  SequenceValue: TACRSequenceValue;
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
  // updated in v.5.14 - to allow set AutoIncValues for export to SQL
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  if (FFieldDefs.AutoIncFieldsExists) then
    for CHECK_NULL_FLAG_BitNo := 0 to FFieldDefs.Count - 1 do
      if (IsAutoincFieldType(FFieldDefs[CHECK_NULL_FLAG_BitNo].AdvancedFieldType)) then
      begin
        {$I ACR_check_null_flag.inc}
        if (CHECK_NULL_FLAG_Result) then
        begin
          // auto-inc is NULL, not set - generate next value from current counter
          SequenceValue := FSequenceManager.GetNextVal(Session,
            FFieldDefs[CHECK_NULL_FLAG_BitNo].SequenceDefObjectId);
          Move(SequenceValue, (RecordBuffer + FFieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset)^,
            FFieldDefs[CHECK_NULL_FLAG_BitNo].MemoryDataSize);
          SET_NULL_FLAG_ToSet := False;
          SET_NULL_FLAG_BitNo := CHECK_NULL_FLAG_BitNo;
          SET_NULL_FLAG_NullFlags := RecordBuffer;
          {$I ACR_set_null_flag.inc}
        end
        else
        begin
          // auto-inc is set - set this value, but update counter only if new values is higher then current counter value
          SequenceValue := 0;
          // copy current value
          Move((RecordBuffer + FFieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset)^, SequenceValue,
            FFieldDefs[CHECK_NULL_FLAG_BitNo].MemoryDataSize);
          FSequenceManager.GetNextVal(Session, FFieldDefs[CHECK_NULL_FLAG_BitNo].SequenceDefObjectId,
            SequenceValue);
          Move(SequenceValue, (RecordBuffer + FFieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset)^,
            FFieldDefs[CHECK_NULL_FLAG_BitNo].MemoryDataSize);
          SET_NULL_FLAG_ToSet := False;
          SET_NULL_FLAG_BitNo := CHECK_NULL_FLAG_BitNo;
          SET_NULL_FLAG_NullFlags := RecordBuffer;
          {$I ACR_set_null_flag.inc}
        end;
      end;
end; // ApplyAutoIncValuesToRecordBuffer




////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseIndexManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.LoadFromStream(Stream: TStream);
begin
  FIndexDefs.LoadFromStream(Stream);
  LTableData.PageManager.LoadFromStream(Stream);
end; // SaveToStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.SaveToStream(Stream: TStream);
begin
  FIndexDefs.SaveToStream(Stream);
  LTableData.PageManager.SaveToStream(Stream);
end; // SaveToStream

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRBaseIndexManager.Create(aTableData: TACRTableData);
begin
FOpenIndexList := TList.Create; // list of TACRIndex objects
FIndexDefs := TACRIndexDefs.Create;
LTableData := aTableData;
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRBaseIndexManager.Destroy;
begin
  // DropTemporaryIndexes(SYSTEM_SESSION_ID);
while (FOpenIndexList.Count > 0) do
	CloseIndex(TACRIndex(FOpenIndexList.Items[0]).IndexDef.ObjectID);
FOpenIndexList.Free;
FIndexDefs.Free;
end; // Destroy

//------------------------------------------------------------------------------
// return true if corresponding index was found
//------------------------------------------------------------------------------
function TACRBaseIndexManager.IsIndexExists(FieldNames, AscDescList,
	CaseSensitivityList: TACRWideStringList): Boolean;
begin
Result := FIndexDefs.IsIndexExists(FieldNames, AscDescList,
	CaseSensitivityList);
end; // IsIndexExists

//------------------------------------------------------------------------------
// return IndexID if corresponding index was found
//------------------------------------------------------------------------------
function TACRBaseIndexManager.FindIndex(FieldNames, AscDescList,
	CaseSensitivityList: TACRWideStringList): TACRObjectID;
begin
Result := FIndexDefs.FindIndex(FieldNames, AscDescList, CaseSensitivityList);
end; // FindIndex

//------------------------------------------------------------------------------
// create index definitions list
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.CreateIndexDefs(aIndexDefs: TACRIndexDefs);
begin
FIndexDefs.Assign(aIndexDefs);
end; // CreateIndexDefs

//------------------------------------------------------------------------------
// clear index cache (INVALID_OBJECT_ID means all sessions)
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.ClearIndexCache
	(SessionID: TACRSessionID = INVALID_OBJECT_ID);
var
	i: Integer;
begin
for i := 0 to FOpenIndexList.Count - 1 do
	TACRIndex(FOpenIndexList.Items[i]).ClearIndexCache(SessionID);
end; // ClearIndexCache

//------------------------------------------------------------------------------
// FindOpenIndex
//------------------------------------------------------------------------------
function TACRBaseIndexManager.FindOpenIndex(IndexID: TACRObjectID): TACRIndex;
var
	i: Integer;
begin
Result := nil;
for i := 0 to FOpenIndexList.Count - 1 do
	if (TACRIndex(FOpenIndexList.Items[i]).IndexDef.ObjectID = IndexID) then
	begin
	Result := TACRIndex(FOpenIndexList.Items[i]);
	break;
	end;
end; // FindOpenIndex

//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
function TACRBaseIndexManager.CreateIndex(Cursor: TACRCursor; IndexDef: TACRIndexDef): TACRObjectID;
begin
  IndexDef.ObjectID := LTableData.DatabaseData.GetNewObjectId;
  FIndexDefs.AddCreated.Assign(IndexDef);
  InternalCreateIndex(Cursor, IndexDef);
  Result := IndexDef.ObjectID;
end; // CreateIndex

//------------------------------------------------------------------------------
// return index ID if Index exists, otherwise return NULL_ID
//------------------------------------------------------------------------------
function TACRBaseIndexManager.OpenIndex(IndexID: TACRObjectID): TACRIndex;
begin
  Result := FindOpenIndex(IndexID);
  if (Result = nil) then
    Result := InternalOpenIndex(IndexID);
end; // OpenIndex

//------------------------------------------------------------------------------
// close index
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.CloseIndex(IndexID: TACRObjectID);
var
	Index: TACRBTreeIndex;
begin
Index := TACRBTreeIndex(FindOpenIndex(IndexID));
if (Index <> nil) then
begin
FOpenIndexList.Remove(Index);
Index.Free;
end;
end; // CloseIndex

//------------------------------------------------------------------------------
// drop index
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.DropIndex(SessionID: TACRSessionID; IndexID: TACRObjectID);
var
	  Index: TACRIndex;
begin
  Index := OpenIndex(IndexID);
  try
    Index.DropIndex(SessionID, False);
  finally
    CloseIndex(IndexID);
  end;
  FIndexDefs.Delete(FIndexDefs.GetDefNumberByObjectId(IndexID));
end; // DropIndex

//------------------------------------------------------------------------------
// DropAllIndexes
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.DropAllIndexes(SessionID: TACRSessionID);
begin
  while (IndexDefs.Count > 0) do
    DropIndex(SessionID, IndexDefs.Items[0].ObjectID);
end; // DropAllIndexes

//------------------------------------------------------------------------------
// EmptyIndex
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.EmptyIndex(SessionID: TACRSessionID; IndexID: TACRObjectID);
var
	Index: TACRIndex;
begin
  Index := OpenIndex(IndexID);
  try
    Index.DropIndex(SessionID, True);
  finally
    CloseIndex(IndexID);
  end;
end; // EmptyIndex

//------------------------------------------------------------------------------
// EmptyAllIndexes
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.EmptyAllIndexes(SessionID: TACRSessionID);
var
	i: Integer;
begin
for i := 0 to IndexDefs.Count - 1 do
	EmptyIndex(SessionID, IndexDefs.Items[i].ObjectID);
end; // EmptyAllIndexes

//------------------------------------------------------------------------------
// GetRecordBuffer
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.GetRecordBuffer(SessionID: TACRSessionID;
	var NavigationInfo: TACRNavigationInfo);
var
	NavigationInfo1: TACRNavigationInfo;
begin
NavigationInfo1.SessionID := SessionID;
NavigationInfo1 := NavigationInfo;
NavigationInfo1.GetRecordResult := grrOK;
if ((not NavigationInfo.FirstPosition) and (not NavigationInfo.LastPosition))
	then
begin
NavigationInfo1.GetRecordMode := grmCurrent;
NavigationInfo1.FirstPosition := False;
NavigationInfo1.LastPosition := False;
TableData.RecordManager.GetRecordBuffer(NavigationInfo1);
end;
if (NavigationInfo1.GetRecordResult <> grrError) then
begin
OpenIndex(NavigationInfo.IndexID).GetRecordBuffer(SessionID, NavigationInfo);
end;
end; // GetRecordBuffer

//------------------------------------------------------------------------------
// InsertRecord
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.InsertRecord(Cursor: TACRCursor);
var
	i: Integer;
	Index: TACRIndex;
  // bTemporary: Boolean;
begin
  // bTemporary := False;
for i := 0 to FIndexDefs.Count - 1 do
begin
Index := OpenIndex(FIndexDefs.Items[i].ObjectID);
Index.InsertRecord(Cursor);
Index.ClearIndexCache;
if (FIndexDefs.Items[i].RootPageNo <> Index.IndexDef.RootPageNo) then
	FIndexDefs.Items[i].RootPageNo := Index.IndexDef.RootPageNo;
    // if (Index.Temporary) then
    // bTemporary := True;
end;
  // if (bTemporary) then
  // if (not Cursor.Session.InTransaction) then
  // GetTemporaryPageManager.ApplyChanges(Cursor.Session.SessionID);
end; // InsertRecord

//------------------------------------------------------------------------------
// UpdateRecord
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.UpdateRecord(Cursor: TACRCursor);
var
	i: Integer;
	Index: TACRIndex;
  // bTemporary:     Boolean;
begin
  // bTemporary := False;
for i := 0 to FIndexDefs.Count - 1 do
begin
Index := OpenIndex(FIndexDefs.Items[i].ObjectID);
Index.UpdateRecord(Cursor);
Index.ClearIndexCache;
    // if (Index.Temporary) then
    // bTemporary := True;
end;
  // if (bTemporary) then
  // if (not Cursor.Session.InTransaction) then
  // GetTemporaryPageManager.ApplyChanges(Cursor.Session.SessionID);
end; // UpdateRecord

//------------------------------------------------------------------------------
// DeleteRecord
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.DeleteRecord(Cursor: TACRCursor);
var
	i: Integer;
	Index: TACRIndex;
	NavigationInfo: TACRNavigationInfo;
  // bTemporary:     Boolean;
begin
  // bTemporary := False;
NavigationInfo.SessionID := Cursor.Session.SessionID;
NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
NavigationInfo.RecordID := Cursor.CurrentRecordID;
NavigationInfo.FirstPosition := False;
NavigationInfo.LastPosition := False;
NavigationInfo.GetRecordMode := grmCurrent;
TableData.RecordManager.GetRecordBuffer(NavigationInfo);

if (NavigationInfo.GetRecordResult <> grrError) then
begin
for i := 0 to FIndexDefs.Count - 1 do
begin
Index := OpenIndex(FIndexDefs.Items[i].ObjectID);
Index.DeleteRecord(Cursor);
Index.ClearIndexCache;
      // if (Index.Temporary) then
      // bTemporary := True;
end;
    // if (bTemporary) then
    // if (not Cursor.Session.InTransaction) then
    // GetTemporaryPageManager.ApplyChanges(Cursor.Session.SessionID);
end;
end; // DeleteRecord

//------------------------------------------------------------------------------
// return 0 if record buffers are equal in this index
// return 1 if Buffer1 is higher than Buffer 2 (Pos1 > Pos2)
// return -1 if Buffer1 is lower than Buffer 2 (Pos1 < Pos2)
// IndexFieldCount = 0 means to compare by all fields in index
//------------------------------------------------------------------------------
function TACRBaseIndexManager.CompareRecordBuffersByIndex
	(IndexID: TACRObjectID; Buffer1: TACRRecordBuffer;
	Buffer2: TACRRecordBuffer; IndexFieldCount: Integer): Integer;
var
	Index: TACRIndex;
	FieldCount, Num: Integer;
begin
if (IndexFieldCount = 0) then
begin
Num := FIndexDefs.GetDefNumberByObjectId(IndexID);
if (Num < 0) then
	raise EACRException.Create(11497, ErrorLCannotFindIndexByID, [IndexID]);
FieldCount := FIndexDefs.Items[Num].ColumnCount;
end
else
	FieldCount := IndexFieldCount;
Index := OpenIndex(IndexID);
try
	Result := Index.CompareRecordBuffersByIndex(Buffer1, Buffer2, FieldCount);
finally
	CloseIndex(IndexID);
end;
end; // CompareRecordBuffersByIndex

//------------------------------------------------------------------------------
// called from CreateTable - allocates root pages for all indexes
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.CreateAllIndexes(SessionID: TACRSessionID);
var
	i, n: Integer;
	Pages: TACRPageArray;
	IndexID: TACRObjectID;
	Index: TACRIndex;
begin
n := FIndexDefs.Count;
if (n > 0) then
begin
Pages := TACRPageArray.Create;
try
	LTableData.AddPages(Pages, n, False, SessionID, dbstIndex,
		LTableData.TableState.TableState, True);
	for i := 0 to FIndexDefs.Count - 1 do
	begin
	IndexID := FIndexDefs.Items[i].ObjectID;
	Index := OpenIndex(IndexID);
	try
		Index.CreateIndex(SessionID, Pages.Items[i], FIndexDefs.Items[i]);
	finally
		CloseIndex(IndexID);
	end;
	end;
finally
	Pages.Free;
end;
end;
end; // CreateAllIndexes

//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
procedure TACRBaseIndexManager.InternalCreateIndex(Cursor: TACRCursor;
	IndexDef: TACRIndexDef);
var
	Index: TACRBTreeIndex;
begin
Index := TACRBTreeIndex.Create(Self);
try
	try
		Index.CreateIndex(Cursor, IndexDef);
		FIndexDefs.Items[FIndexDefs.GetDefNumberByObjectId(IndexDef.ObjectID)]
			.Assign(IndexDef);
	except
		FIndexDefs.Delete(FIndexDefs.GetDefNumberByObjectId(IndexDef.ObjectID));
		raise ;
	end;
finally
	Index.Free;
end;
end; // InternalCreateIndex

//------------------------------------------------------------------------------
// Internal open index
//------------------------------------------------------------------------------
function TACRBaseIndexManager.InternalOpenIndex(IndexID: TACRObjectID)
	: TACRIndex;
var
	Index: TACRBTreeIndex;
	IndexNo: Integer;
begin
IndexNo := FIndexDefs.GetDefNumberByObjectId(IndexID);
if (IndexNo = -1) then
	raise EACRException.Create(20018, ErrorAIndexNotFound);
Index := TACRBTreeIndex.Create(Self);
Index.OpenIndex(FIndexDefs[IndexNo]);
FOpenIndexList.Add(Index);
Result := Index;
end; // InternalOpenIndex

////////////////////////////////////////////////////////////////////////////////
//
// TACRIndex
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRIndex.Create(aIndexManager: TACRBaseIndexManager);
begin
if (aIndexManager = nil) then
	raise EACRException.Create(11881, ErrorLNilPointer);
LIndexManager := aIndexManager;
if (LIndexManager.TableData = nil) then
	raise EACRException.Create(11882, ErrorLNilPointer);
LTableData := LIndexManager.TableData;
FIndexDef := nil;
  // FTemporary := False;
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRIndex.Destroy;
begin
if (FIndexDef <> nil) then
	FIndexDef.Free;
end; // Destroy

//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
procedure TACRIndex.CreateIndex(Cursor: TACRCursor; aIndexDef: TACRIndexDef);
begin
if (FIndexDef <> nil) then
	FIndexDef.Free;
FIndexDef := TACRIndexDef.Create;
FIndexDef.Assign(aIndexDef);
end; // CreateIndex

//------------------------------------------------------------------------------
// create index
//------------------------------------------------------------------------------
procedure TACRIndex.CreateIndex(SessionID: TACRSessionID; pageNo: TACRPageNo;
	aIndexDef: TACRIndexDef);
begin
if (FIndexDef <> nil) then
	FIndexDef.Free;
FIndexDef := TACRIndexDef.Create;
FIndexDef.Assign(aIndexDef);
end; // CreateIndex

//------------------------------------------------------------------------------
// OpenIndex
//------------------------------------------------------------------------------
procedure TACRIndex.OpenIndex(aIndexDef: TACRIndexDef);
begin
if (FIndexDef <> nil) then
	FIndexDef.Free;
FIndexDef := TACRIndexDef.Create;
FIndexDef.Assign(aIndexDef);
  // FTemporary := FIndexDef.Temporary;
end; // OpenIndex

////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseSequenceManager
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRBaseSequenceManager.Create(DatabaseData: TACRDatabaseData);
begin
FDatabaseData := DatabaseData;
FSequenceDefs := TACRSequenceDefs.Create;
end; // Create

//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRBaseSequenceManager.Destroy;
begin
FSequenceDefs.Free;
end; // Destroy

//------------------------------------------------------------------------------
// find or create SequenceDef by SequenceName
//------------------------------------------------------------------------------
function TACRBaseSequenceManager.GetOrCreateSequenceDefByName
	(SequenceName: WideString): TACRSequenceDef;
var
	i: TACRObjectID;
begin
i := FSequenceDefs.GetDefNumberByName(SequenceName);
if i = INVALID_ID4 then
begin
Result := FSequenceDefs.AddCreated;
Result.Name := SequenceName;
Result.ObjectID := FDatabaseData.GetNewObjectId;
end
else
	Result := FSequenceDefs[i];
end; // GetOrCreateSequenceDefByName


//------------------------------------------------------------------------------
// get next sequence value
//------------------------------------------------------------------------------
function TACRBaseSequenceManager.GetNextVal(Session: TACRBaseSession;	SequenceID: TACRObjectID): TACRSequenceValue;
var
  	i: TACRObjectID;
 // OldSequenceValue: TACRSequenceValue;
begin
  i := FSequenceDefs.GetDefNumberByObjectId(SequenceID);
  if i = INVALID_ID4 then
    raise EACRException.Create(30010, ErrorGSequenceIdNotFound, [SequenceID]);
  // Get Next Value
  Result := FSequenceDefs[i].GetNextVal;
{$IFDEF DEBUG_TRACE_AUTOINC_NEXT_VALUE}
aaWriteToLog(FSequenceDefs[i].Name + ' value = ' + IntToStr(Int64(Result))
    + ' ');
{$ENDIF}
  Session.SetSequenceValue(FSequenceDefs[i].Name, Result);
end; // GetNextVal


//------------------------------------------------------------------------------
// get next sequence value from specified value
//------------------------------------------------------------------------------
procedure TACRBaseSequenceManager.GetNextVal(Session: TACRBaseSession;	SequenceID: TACRObjectID; Value: TACRSequenceValue);
var
	i:            TACRObjectID;
	sequenceDef:  TACRSequenceDef;
begin
  i := FSequenceDefs.GetDefNumberByObjectId(SequenceID);
  if i = INVALID_ID4 then
    raise EACRException.Create(12296, ErrorGSequenceIdNotFound, [SequenceID]);
  sequenceDef := FSequenceDefs[i];
  if (sequenceDef.Increment > 0) then
  begin
    // Value+Increment
    if (Value > sequenceDef.LastValue) then
      sequenceDef.LastValue := Value;
  end
  else
  begin
    // Value-Increment
    if (Value < sequenceDef.LastValue) then
      sequenceDef.LastValue := Value;
  end;
  Session.SetSequenceValue(sequenceDef.Name, Value);
end; // GetNextVal


//------------------------------------------------------------------------------
// get last sequence value
//------------------------------------------------------------------------------
function TACRBaseSequenceManager.GetLastVal(Session: TACRBaseSession; SequenceID: TACRObjectID): TACRSequenceValue;
var
  	Value:  TACRSessionNamedObjectSequenceValue;
	  i:      TACRObjectID;
begin
  i := FSequenceDefs.GetDefNumberByObjectId(SequenceID);
  if i = INVALID_ID4 then
    raise EACRException.Create(30011, ErrorGSequenceIdNotFound, [SequenceID]);
  Value := TACRSessionNamedObjectSequenceValue
    (Session.GetNamedObject(FSequenceDefs[i].Name));
  if Value = nil then
    raise EACRException.Create(30012, ErrorGSequenceLastValueFailed,
      [FSequenceDefs[i].Name]);
  Result := Value.Value;
end; // GetLastVal


//------------------------------------------------------------------------------
// Get GequenceDef
//------------------------------------------------------------------------------
function TACRBaseSequenceManager.GetSequenceDef(SequenceID: TACRObjectID)
	: TACRSequenceDef;
var
	i: TACRObjectID;
begin
i := FSequenceDefs.GetDefNumberByObjectId(SequenceID);
if i = INVALID_ID4 then
	raise EACRException.Create(30013, ErrorGSequenceIdNotFound, [SequenceID]);
Result := FSequenceDefs[i];
end; // GetSequenceDef

//------------------------------------------------------------------------------
// Generate unique Sequence Name
//------------------------------------------------------------------------------
function TACRBaseSequenceManager.GenerateSequenceName(isAutoinc: Boolean;
	ColumnName, TableName: WideString): WideString;
var
	i: Integer;
	s: WideString;
begin
Result := AutoNameSymbol;
if isAutoinc then
	Result := Result + AutoNameSequenceAutoIncPrefix
else
	Result := Result + AutoNameSequenceLinkedWithColumnPrefix;
Result := Result + AutoNameSymbol + TableName + AutoNameSymbol + ColumnName;
  // Check Name for Uniqueness
s := Result;
i := FSequenceDefs.GetDefNumberByName(Result);
while i <> -1 do
begin
Result := s + IntToStr(Random(MAXWORD));
i := FSequenceDefs.GetDefNumberByName(Result);
end;
end; // GenerateSequenceName

////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseConstraintManager
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.LoadFromStream(Stream: TStream);
begin
ConstraintDefs.LoadFromStream(Stream);
if (ConstraintDefs.Count > 0) then
	FEmpty := False;
end; // LoadFromStream

//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.SaveToStream(Stream: TStream);
begin
ConstraintDefs.SaveToStream(Stream);
end; // SaveToStream

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRBaseConstraintManager.Create(aTableData: TACRTableData);
begin
FTableData := aTableData;
FConstraintDefs := TACRConstraintDefs.Create;
FEmpty := True;
end; // Create

//------------------------------------------------------------------------------
// Denstructor
//------------------------------------------------------------------------------
destructor TACRBaseConstraintManager.Destroy;
begin
  FConstraintDefs.Free;
end; // Destroy


//------------------------------------------------------------------------------
// check constraint conditions
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.CheckConstraints(
                                      Cursor:           TACRCursor;
                                      SessionID:        TACRSessionID;
                                      NewRecordBuffer:  TACRRecordBuffer;
                                      OldRecordBuffer:  TACRRecordBuffer;
                                      ToInsert:         Boolean;
                                      CurrentRecordID:  TACRRecordID;
                                      SkipFKCheck:      Boolean = False
                                      );
var
	i, j:   Integer;
	ObjId:  TACRObjectID;
{$I ACR_cmp_buffers_var.inc}
{$I ACR_check_null_flag_var.inc}
begin
  for i := 0 to ConstraintDefs.Count - 1 do
    case ConstraintDefs[i].ConstraintType of
      ctNotNull:
      begin
        ObjId := TACRConstraintDefNotNull(ConstraintDefs[i]).ColumnObjectID;
        CHECK_NULL_FLAG_BitNo := FTableData.FieldManager.FieldDefs.GetDefNumberByObjectId(ObjId);
        if CHECK_NULL_FLAG_BitNo = -1 then
          raise EACRException.Create(30024, ErrorGFieldWithObjectIdNotFound, [ObjId]);
        CHECK_NULL_FLAG_NullFlags := NewRecordBuffer;
        {$I ACR_check_null_flag.inc}
        if (CHECK_NULL_FLAG_Result) then
          raise EACRException.Create(30026, ErrorGConstraintNotNull,
            [ConstraintDefs[i].Name, FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].Name]);
      end;
      ctCheck:
      begin
        ObjId := TACRConstraintDefCheck(ConstraintDefs[i]).ColumnObjectID;
        CHECK_NULL_FLAG_BitNo := FTableData.FieldManager.FieldDefs.GetDefNumberByObjectId(ObjId);
        if CHECK_NULL_FLAG_BitNo = -1 then
          raise EACRException.Create(30028, ErrorGFieldWithObjectIdNotFound, [ObjId]);
        if (not CHECK_NULL_FLAG_Result) then
        begin
          CMP_BUF_PartialCompareLength := -1;
{$IFDEF MSWINDOWS}
          CMP_BUF_LocaleID := LOCALE_USER_DEFAULT;
{$ENDIF}          // Check Min Constraint ( Min > Value ==> Raise )
          CMP_BUF_IgnoreCase := False;
          CMP_BUF_IsField1Null := False;
          CMP_BUF_IsField2Null := False;
          if (not TACRConstraintDefCheck(ConstraintDefs[i]).MinValue.IsNull) then
          begin
            // optimized in v.5.60
            CMP_BUF_Buffer1 := TACRConstraintDefCheck(ConstraintDefs[i]).MinValue.pData;
            CMP_BUF_Buffer2 := NewRecordBuffer + FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset;
            CMP_BUF_BaseFieldType1 := TACRConstraintDefCheck(ConstraintDefs[i]).MinValue.DataType;
            CMP_BUF_BaseFieldType2 := FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType;
            {$I ACR_cmp_buffers.inc}
            if (CMP_BUF_Result = cmprGreater) then
              raise EACRException.Create(30029, ErrorGConstraintCheckMinViolated,
                [ConstraintDefs[i].Name, FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].Name,
                TACRConstraintDefCheck(ConstraintDefs[i]).MinValue.AsString]);
          end;
          // Check Max Constraint ( Max < Value ==> Raise )
          if (not TACRConstraintDefCheck(ConstraintDefs[i]).MaxValue.IsNull) then
          begin
            CMP_BUF_Buffer1 := TACRConstraintDefCheck(ConstraintDefs[i]).MaxValue.pData;
            CMP_BUF_Buffer2 := NewRecordBuffer + FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset;
            CMP_BUF_BaseFieldType1 := TACRConstraintDefCheck(ConstraintDefs[i]).MaxValue.DataType;
            CMP_BUF_BaseFieldType2 := FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType;
            {$I ACR_cmp_buffers.inc}
            if (CMP_BUF_Result = cmprLower) then
              raise EACRException.Create(30030, ErrorGConstraintCheckMaxViolated,
                [ConstraintDefs[i].Name, FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].Name,
                TACRConstraintDefCheck(ConstraintDefs[i]).MaxValue.AsString]);
          end;
        end;
      end;
      ctPK:
      begin
        // Check NULL
        for j := 0 to Length(TACRConstraintDefPrimary(ConstraintDefs[i]).Columns) - 1 do
        begin
          ObjId := TACRConstraintDefPrimary(ConstraintDefs[i]).Columns[j].ColumnObjectID;
          CHECK_NULL_FLAG_BitNo := FTableData.FieldManager.FieldDefs.GetDefNumberByObjectId(ObjId);
          if CHECK_NULL_FLAG_BitNo = -1 then
            raise EACRException.Create(30329, ErrorGFieldWithObjectIdNotFound, [ObjId]);
          CHECK_NULL_FLAG_NullFlags := NewRecordBuffer;
          {$I ACR_check_null_flag.inc}
          if (CHECK_NULL_FLAG_Result) then
            raise EACRException.Create(30330, ErrorGConstraintNotNull,
              [ConstraintDefs[i].Name, FTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].Name]);
        end;
        // Check UNIQUE
        if (FTableData.IsUniqueConstraintFailed(SessionID,
            TACRConstraintDefPrimary(ConstraintDefs[i]).IndexObjectID,
            NewRecordBuffer, OldRecordBuffer, ToInsert, CurrentRecordID)) then
          raise EACRException.Create(30319, ErrorGConstraintPrimaryKeyViolated,
            [ConstraintDefs[i].Name]);
      end;
    ctUnique:
    begin
      if (FTableData.IsUniqueConstraintFailed(SessionID,
          TACRConstraintDefUnique(ConstraintDefs[i]).IndexObjectID,
          NewRecordBuffer, OldRecordBuffer, ToInsert,
          CurrentRecordID)) then
        raise EACRException.Create(30320, ErrorGConstraintUniqueViolated,
          [ConstraintDefs[i].Name]);
    end;
    ctFKAction:
    ; // do nothing
    ctFK:
    begin
      if (not SkipFKCheck) then
        if (FTableData.IsForeignKeyConstraintFailed(Cursor,
            TACRConstraintDefForeignKey(ConstraintDefs[i]))) then
          raise EACRException.Create(11420, ErrorLConstraintForeignKeyViolated,
            [ConstraintDefs[i].Name, FTableData.TableName]);
    end;
    else
      raise EACRException.Create(30036, ErrorGNotImplementedYet);
  end; // case
end; // CheckConstraints


//------------------------------------------------------------------------------
// Link object id
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.LinkObjectId
	(ConstraintDef: TACRConstraintDef);
var
	j: Integer;
	ColumnName, IndexName: TACRObjectName;
	n: Integer;
begin
  case ConstraintDef.ConstraintType of
  ctNotNull:
  begin
  ColumnName := TACRConstraintDefNotNull(ConstraintDef).ColumnName;
  n := FTableData.FieldManager.FieldDefs.GetDefNumberByName(ColumnName);
  if n = -1 then
    raise EACRException.Create(30027, ErrorGFieldWithNameNotFound, [ColumnName]);
  TACRConstraintDefNotNull(ConstraintDef).ColumnObjectID :=
    FTableData.FieldManager.FieldDefs[n].ObjectID;
  end;
  ctCheck:
  begin
  ColumnName := TACRConstraintDefCheck(ConstraintDef).ColumnName;
  n := FTableData.FieldManager.FieldDefs.GetDefNumberByName(ColumnName);
  if n = -1 then
    raise EACRException.Create(30027, ErrorGFieldWithNameNotFound, [ColumnName]);
  TACRConstraintDefCheck(ConstraintDef).ColumnObjectID :=
    FTableData.FieldManager.FieldDefs[n].ObjectID;
  end;
  ctPK:
  begin
          // Set Index Object ID
  IndexName := TACRConstraintDefPrimary(ConstraintDef).IndexName;
  n := FTableData.IndexManager.FIndexDefs.GetDefNumberByName(IndexName);
  if n = -1 then
    raise EACRException.Create(30325, ErrorGIndexNameNotFound, [IndexName]);
  TACRConstraintDefPrimary(ConstraintDef).IndexObjectID :=
    FTableData.IndexManager.FIndexDefs[n].ObjectID;

          // Set Columns Object ID
  for j := 0 to Length(TACRConstraintDefPrimary(ConstraintDef).Columns) - 1 do
  begin
  ColumnName := TACRConstraintDefPrimary(ConstraintDef).Columns[j].ColumnName;
  n := FTableData.FieldManager.FieldDefs.GetDefNumberByName(ColumnName);
  if n = -1 then
    raise EACRException.Create(30331, ErrorGFieldWithNameNotFound, [ColumnName]);
  TACRConstraintDefPrimary(ConstraintDef).Columns[j].ColumnObjectID :=
    FTableData.FieldManager.FieldDefs[n].ObjectID;

  end;
  end;
  ctUnique:
  begin
          // Set Index Object ID
  IndexName := TACRConstraintDefUnique(ConstraintDef).IndexName;
  n := FTableData.IndexManager.FIndexDefs.GetDefNumberByName(IndexName);
  if n = -1 then
    raise EACRException.Create(30326, ErrorGIndexNameNotFound, [IndexName]);
  TACRConstraintDefUnique(ConstraintDef).IndexObjectID :=
    FTableData.IndexManager.FIndexDefs[n].ObjectID;

          // Set Columns Object ID
  for j := 0 to Length(TACRConstraintDefUnique(ConstraintDef).Columns) - 1 do
  begin
  ColumnName := TACRConstraintDefUnique(ConstraintDef).Columns[j].ColumnName;
  n := FTableData.FieldManager.FieldDefs.GetDefNumberByName(ColumnName);
  if n = -1 then
    raise EACRException.Create(30332, ErrorGFieldWithNameNotFound, [ColumnName]);
  TACRConstraintDefUnique(ConstraintDef).Columns[j].ColumnObjectID :=
    FTableData.FieldManager.FieldDefs[n].ObjectID;

  end;
  end;
  ctFKAction:
  ;
  ctFK:
  begin
          // Set Columns Object ID
  for j := 0 to Length(TACRConstraintDefForeignKey(ConstraintDef).Columns) - 1 do
  begin
  ColumnName := TACRConstraintDefForeignKey(ConstraintDef).Columns[j].ColumnName;
  n := FTableData.FieldManager.FieldDefs.GetDefNumberByName(ColumnName);
  if n = -1 then
    raise EACRException.Create(11419, ErrorGFieldWithNameNotFound, [ColumnName]);
  TACRConstraintDefForeignKey(ConstraintDef).Columns[j].ColumnObjectID :=
    FTableData.FieldManager.FieldDefs[n].ObjectID;
  end;
  end;
  else
  raise EACRException.Create(30037, ErrorGNotImplementedYet);
  end;
end; // LinkObjectId

//------------------------------------------------------------------------------
// Link object ids between constraints and fields
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.LinkObjectIds;
var
	i: Integer;
begin
for i := 0 to ConstraintDefs.Count - 1 do
	LinkObjectId(ConstraintDefs[i]);
FEmpty := (FConstraintDefs.Count = 0);
end; // FillObjectIds

//------------------------------------------------------------------------------
// Generate Constraint Names for empty constraints
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.FillConstraintAutoNames;
var
	i, n: Integer;
	s, CName: WideString;
begin
for i := 0 to FConstraintDefs.Count - 1 do
	if (FConstraintDefs[i].Name = '') then
	begin
	s := AutoNameSymbol;
	case FConstraintDefs[i].ConstraintType of
	ctFK, ctFKAction:
	begin
	s := GetTemporaryName(ACRConstraintFKName);
	end;
	ctNotNull:
	begin
	s := s + AutoNameConstraintNotNullPrefix + AutoNameSymbol +
		TACRConstraintDefNotNull(FConstraintDefs[i]).ColumnName;
	end;
	ctCheck:
	begin
	s := s + AutoNameConstraintCheckPrefix + AutoNameSymbol +
		TACRConstraintDefNotNull(FConstraintDefs[i]).ColumnName;
	end;
else
raise EACRException.Create(30038, ErrorGNotImplementedYet);
end;

	CName := s;

      // Check Unique Names
	n := FConstraintDefs.GetDefNumberByName(CName);
	while n <> -1 do
	begin
	CName := s + IntToStr(Random(MAXWORD));
	n := FConstraintDefs.GetDefNumberByName(CName);
	end;

	FConstraintDefs[i].Name := CName;
	end;

end; // FillConstraintAutoNames

//------------------------------------------------------------------------------
// add constraint for primary or Unique index
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.AddConstraintFromIndex
	(IndexDef: TACRIndexDef);
var
	ConstraintDef: TACRConstraintDef;
begin
ConstraintDef := AddConstraintForIndex(IndexDef, FConstraintDefs);
if (ConstraintDef <> nil) then
begin
FEmpty := False;
ConstraintDef.ObjectID := FTableData.DatabaseData.GetNewObjectId;
LinkObjectId(ConstraintDef);
end;
end; // AddConstraintFromIndex

//------------------------------------------------------------------------------
// Delete Constraint Linked with deleted index
//------------------------------------------------------------------------------
procedure TACRBaseConstraintManager.DeleteConstraintForIndexID
	(IndexObjectID: TACRObjectID);
var
	i: Integer;
begin
for i := 0 to FConstraintDefs.Count - 1 do
	case FConstraintDefs[i].ConstraintType of
	ctPK:
	if (TACRConstraintDefPrimary(FConstraintDefs[i])
			.IndexObjectID = IndexObjectID) then
	begin
	FConstraintDefs.Delete(i);
	break;
	end;
	ctUnique:
	if (TACRConstraintDefUnique(FConstraintDefs[i])
			.IndexObjectID = IndexObjectID) then
	begin
	FConstraintDefs.Delete(i);
	break;
	end;
	end;
FEmpty := (FConstraintDefs.Count = 0);
end; // DeleteConstraintForIndexID

//------------------------------------------------------------------------------
// add action to master table
//------------------------------------------------------------------------------
function TACRBaseConstraintManager.AddForeignKeyAction
	(ConstraintDef: TACRConstraintDefForeignKey;
	ReferencedTableName: WideString; ReferencedTableObjectID: TACRObjectID)
	: TACRConstraintDefForeignKeyAction;
var
	i, h: Integer;
	name: AnsiString;
begin
name := ConstraintDef.Name + '_Action';
while (FConstraintDefs.GetDefNumberByName(name) >= 0) do
	name := GetTemporaryName(ConstraintDef.Name + '_Action_');
Result := FConstraintDefs.AddFKAction;
if (Result <> nil) then
begin
Result.Name := name;
Result.ObjectID := FTableData.DatabaseData.GetNewObjectId;
Result.ReferencedTableName := ReferencedTableName;
Result.ReferencedTableObjectID := ReferencedTableObjectID;
Result.ReferencedFKName := ConstraintDef.Name;
Result.ReferencedFKObjectID := ConstraintDef.ObjectID;
h := High(ConstraintDef.Columns);
SetLength(Result.Columns, h + 1);
for i := 0 to h do
	Result.Columns[i] := ConstraintDef.Columns[i];
Result.DeleteAction := ConstraintDef.DeleteAction;
Result.UpdateAction := ConstraintDef.UpdateAction;
Result.MatchType := ConstraintDef.MatchType;
end;
end; // AddForeignKeyAction

////////////////////////////////////////////////////////////////////////////////
//
// TACRRecordBitmap
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// set active
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.SetActive(Value: Boolean);
begin
FActive := Value;
FDistinct := False;
if (not Value) then
begin
FVisibleRecords.SetSize(0);
FVisibleRecords.Sorted := True;
end;
end; // SetActive

//------------------------------------------------------------------------------
// set indexed
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.SetIndexed(Value: Boolean);
begin
FIndexed := Value;
end; // SetActive

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRRecordBitmap.Create(aTableData: TACRTableData);
begin
if (aTableData = nil) then
	raise EACRException.Create(10425, ErrorLNilPointer);
FTableData := aTableData;
FVisibleRecords := TACRRecordIDArray.Create;
FVisibleRecords.Temporary := FTableData.Temporary;
FVisibleRecords.InMemory := FTableData.InMemory;
FActive := False;
FDistinct := False;
FIndexed := False;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRRecordBitmap.Destroy;
begin
FVisibleRecords.Free;
inherited;
end; // Destroy

//------------------------------------------------------------------------------
// return record count
//------------------------------------------------------------------------------
function TACRRecordBitmap.GetRecordCount: TACRRecordNo;
begin
Result := FVisibleRecords.ItemCount;
end; // GetRecordCount

//------------------------------------------------------------------------------
// return recno by RecordID
//------------------------------------------------------------------------------
function TACRRecordBitmap.GetRecNoByRecordID(RecordID: TACRRecordID)
	: TACRRecordNo;
begin
Result := FVisibleRecords.FindRecordByID(RecordID);
if (Result >= 0) then
	Inc(Result);
end; // GetRecNoByRecordID

//------------------------------------------------------------------------------
// return RecordID by recno
//------------------------------------------------------------------------------
function TACRRecordBitmap.GetRecordIDByRecNo(RecNo: TACRRecordNo): TACRRecordID;
begin
Dec(RecNo);
if ((RecNo < 0) or (RecNo >= FVisibleRecords.ItemCount)) then
	raise EACRException.Create(11326, ErrorLInvalidItemNumber,
		[RecNo, FVisibleRecords.ItemCount]);
Result := FVisibleRecords.Items[RecNo];
end; // GetRecordIDByRecNo

//------------------------------------------------------------------------------
// return true if record is visible
//------------------------------------------------------------------------------
function TACRRecordBitmap.IsRecordVisible(RecordID: TACRRecordID): Boolean;
begin
  if (FDistinct) then
  begin
  ShowRecord(RecordID);
  Result := True;
  end
  else
    Result := (FVisibleRecords.FindRecordByID(RecordID) >= 0);
end; // IsRecordVisible


//------------------------------------------------------------------------------
// insert new visible record to record map
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.InsertVisibleRecord(var RecordID: TACRRecordID;
	const PriorRecordID: TACRRecordID; bFirst: Boolean; bLast: Boolean);
var
	x: Integer;
begin
  FVisibleRecords.Sorted := False;
  if (bLast) then
    FVisibleRecords.Append(RecordID)
  else
    if (bFirst) then
      FVisibleRecords.Insert(0, RecordID)
    else
    begin
    x := FVisibleRecords.FindRecordByID(PriorRecordID);
    if (x < 0) then
      raise EACRException.Create(11332, ErrorLRecordDoesNotExist,
        [PriorRecordID.pageNo, PriorRecordID.PageItemNo]);
    FVisibleRecords.Insert(x + 1, RecordID);
    end;
end; // InsertVisibleRecord


//------------------------------------------------------------------------------
// show record
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.ShowRecord(RecordID: TACRRecordID);
var
	res: Integer;
begin
if (FVisibleRecords.ItemCount >= 1) then
begin
if (FVisibleRecords.Sorted) then
begin
res := FVisibleRecords.CompareRecordID(RecordID, FVisibleRecords.MaxRecordID);
if (res = 0) then
        // begin
        // aaWriteToLog(Format('ERROR - recordID already exists. PageNo = %d, PageItemNo = %d',[RecordID.PageNo,RecordID.PageItemNo]));
	raise EACRException.Create(11328, ErrorLDuplicateRecordID,
		[RecordID.pageNo, RecordID.PageItemNo]);
      // end;
end;
    // aaWriteToLog(Format('Append to record bitmap - recordID already exists. PageNo = %d, PageItemNo = %d',[RecordID.PageNo,RecordID.PageItemNo]));
FVisibleRecords.Append(RecordID);
if (FVisibleRecords.Sorted) then
begin
if (res < 0) then
	FVisibleRecords.Sorted := False
else
	FVisibleRecords.MaxRecordID := RecordID;
end;
end
else
begin
FVisibleRecords.Append(RecordID);
FVisibleRecords.MaxRecordID := RecordID;
end;
end; // ShowRecord

//------------------------------------------------------------------------------
// hide record
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.HideRecord(RecordID: TACRRecordID);
var
	RecNo: Integer;
begin
RecNo := FVisibleRecords.FindRecordByID(RecordID);
if (RecNo < 0) then
	raise EACRException.Create(11327, ErrorLRecordDoesNotExist,
		[RecordID.pageNo, RecordID.PageItemNo]);
FVisibleRecords.Delete(RecNo);
end; // HideRecord

//------------------------------------------------------------------------------
// clear visible records map
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.ClearVisibleRecords;
begin
FVisibleRecords.SetSize(0);
FVisibleRecords.Sorted := True;
end; // ClearVisibleRecords

//------------------------------------------------------------------------------
// GetRecordFromFirstPosition
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.GetRecordFromFirstPosition
	(var NavigationInfo: TACRNavigationInfo);
begin
case NavigationInfo.GetRecordMode of
grmPrior:
begin
NavigationInfo.GetRecordResult := grrBOF;
end;
grmCurrent:
begin
NavigationInfo.GetRecordResult := grrError;
end;
grmNext:
begin
NavigationInfo.GetRecordResult := grrOK;
NavigationInfo.RecordID := FVisibleRecords.Items[0];
end;
end; // GetRecordMode
end; // GetRecordFromFirstPosition

//------------------------------------------------------------------------------
// GetRecordFromLastPosition
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.GetRecordFromLastPosition
	(var NavigationInfo: TACRNavigationInfo);
begin
case NavigationInfo.GetRecordMode of
grmPrior:
begin
NavigationInfo.GetRecordResult := grrOK;
NavigationInfo.RecordID := FVisibleRecords.Items[FVisibleRecords.ItemCount - 1];
end;
grmCurrent:
begin
NavigationInfo.GetRecordResult := grrError;
end;
grmNext:
begin
NavigationInfo.GetRecordResult := grrEOF;
end;
end; // GetRecordMode
end; // GetRecordFromLastPosition

//------------------------------------------------------------------------------
// GetRecordFromAnyPosition
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.GetRecordFromAnyPosition
	(var NavigationInfo: TACRNavigationInfo);
var
	RecNo: Integer;
begin
RecNo := FVisibleRecords.FindRecordByID(NavigationInfo.RecordID);
if (RecNo < 0) then
begin
NavigationInfo.GetRecordResult := grrError;
Exit;
end;
case NavigationInfo.GetRecordMode of
grmPrior:
begin
if (RecNo = 0) then
	NavigationInfo.GetRecordResult := grrBOF
else
begin
NavigationInfo.GetRecordResult := grrOK;
NavigationInfo.RecordID := FVisibleRecords.Items[RecNo - 1];
end;
end;
grmCurrent:
begin
NavigationInfo.GetRecordResult := grrOK;
end;
grmNext:
begin
if (RecNo >= (FVisibleRecords.ItemCount - 1)) then
	NavigationInfo.GetRecordResult := grrEOF
else
begin
NavigationInfo.GetRecordResult := grrOK;
NavigationInfo.RecordID := FVisibleRecords.Items[RecNo + 1];
end;
end;
end; // GetRecordMode
end; // GetRecordFromAnyPosition

//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.GetRecord(var NavigationInfo: TACRNavigationInfo);
begin
if (not FActive) then
begin
NavigationInfo.GetRecordResult := grrError;
Exit;
end;
if (GetRecordCount = 0) then
begin
NavigationInfo.GetRecordResult := grrEOF;
Exit;
end;
if (NavigationInfo.FirstPosition) then
	GetRecordFromFirstPosition(NavigationInfo)
else
	if (NavigationInfo.LastPosition) then
		GetRecordFromLastPosition(NavigationInfo)
	else
		GetRecordFromAnyPosition(NavigationInfo);
end; // GetRecord

//------------------------------------------------------------------------------
// prepare bitmap for activation
//------------------------------------------------------------------------------
procedure TACRRecordBitmap.PrepareBitmapForActivation;
var
	da, mda: Integer;
begin
mda := FTableData.InternalGetRecordCount div 10;
if (mda <= 0) then
	mda := 1000;
da := mda div 100;
if (da <= 10) then
	da := 10;
FVisibleRecords.AllocBy := da;
FVisibleRecords.MaxAllocBy := mda;
end; // PrepareBitmapForActivation




////////////////////////////////////////////////////////////////////////////////
//
// TACRRecordBufferCache
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRRecordBufferCache.Create(aBufferSize: Integer);
begin
  FBufferSize := aBufferSize;
  FBuffers := TACRIntegerArray.Create;
  FUsedBuffers := TACRBitsArray.Create;
  FSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRRecordBufferCache.Destroy;
var
    i:    Integer;
    buf:  TACRRecordBuffer;
begin
  for i := 0 to FBuffers.ItemCount - 1 do
    try
      buf := TACRRecordBuffer(FBuffers.Items[i]);
      MemoryManager.FreeAndNilMem(buf);
    except
    end;
  FBuffers.Free;
  FUsedBuffers.Free;
  FSync.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// returns pointer to the new buffer and marks it as used
//------------------------------------------------------------------------------
function TACRRecordBufferCache.GetBuffer: TACRRecordBuffer;
var	i: Integer;
begin
  Result := nil;
  FSync.WaitAndLockForWrite;
  try
    if ((FBuffers.ItemCount <= 0) or (FUsedBuffers.NonZeroBitCount = FBuffers.ItemCount)) then
    begin
      Result := MemoryManager.GetMem(FBufferSize);
      FBuffers.Append(Integer(Result));
      FUsedBuffers.Size := FBuffers.ItemCount;
      FUsedBuffers.SetBit(FBuffers.ItemCount - 1, True);
    end
    else
    begin
      // find not used buffer
      for i := 0 to FBuffers.ItemCount - 1 do
        if (not FUsedBuffers.GetBit(i)) then
        begin
          Result := TACRRecordBuffer(FBuffers.Items[i]);
          FUsedBuffers.SetBit(i, True);
          break;
        end;
      // this should never happen
      if (Result = nil) then
        raise EACRException.Create(11763, ErrorLNilPointer);
    end;
  finally
    FSync.Unlock;
  end;
end; // GetBuffer


//------------------------------------------------------------------------------
// marks buffer as not used
//------------------------------------------------------------------------------
procedure TACRRecordBufferCache.FreeBuffer(Buffer: TACRRecordBuffer);
var	i, x: Integer;
begin
  x := Integer(Buffer);
  FSync.WaitAndLockForWrite;
  try
    // find used buffer
    for i := 0 to FBuffers.ItemCount - 1 do
      if (FBuffers.Items[i] = x) then
      begin
        // mark the buffer as unused
        FUsedBuffers.SetBit(i, False);
        break;
      end;
  finally
    FSync.Unlock;
  end;
end; // FreeBuffer




////////////////////////////////////////////////////////////////////////////////
//
// TACRFindRecordCache
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRFindRecordCache.Create(aTableData: TACRTableData);
begin
  FSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FItems := TACRIntegerArray.Create();
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRFindRecordCache.Destroy;
begin
  Clear(True);
  FSync.Free;
  FItems.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TACRFindRecordCache.Clear(bClearAll: Boolean = False);
var i:      Integer;
    pItem:  PACRFindRecordCacheItem;
begin
  FSync.WaitAndLockForWrite;
  try
    if (bClearAll) then
    begin
      for i := 0 to FItems.ItemCount-1 do
      begin
        pItem := PACRFindRecordCacheItem(FItems.Items[i]);
        try
          pItem^.SearchExpression.Free;
        except
        end;
        try
          Dispose(pItem);
        except
        end;
      end;
      FItems.SetSize(0);
    end
    else
    begin
      i := 0;
      while (i < FItems.ItemCount) do
      begin
        pItem := PACRFindRecordCacheItem(FItems.Items[i]);
        if (pItem^.UseCount = 0) then
        begin
          try
            pItem^.SearchExpression.Free;
          except
          end;
          try
            Dispose(pItem);
          except
          end;
          FItems.Delete(i);
        end
        else
          Inc(i);
      end;
    end;
  finally
    FSync.Unlock;
  end;
end; // Clear


//------------------------------------------------------------------------------
// Return cache item
//------------------------------------------------------------------------------
function TACRFindRecordCache.GetCacheItem(
                          Cursor:           TACRCursor;
                          const KeyFields:  WideString;
                          const KeyValues:  Variant;
                          CaseInsensitive:  Boolean;
                          PartialKey:       Boolean
                     ): PACRFindRecordCacheItem;
var i:    Integer;
    crc:  Cardinal;
begin
  crc := GetTableNameCRC(KeyFields);
  FSync.WaitAndLockForWrite;
  try
    Result := nil;
    for i := 0 to FItems.ItemCount - 1 do
    begin
      Result := PACRFindRecordCacheItem(FItems.Items[i]);
      if (Result^.FieldNamesCRC = crc) then
      begin
        Inc(Result^.UseCount);
        Exit;
      end;
    end;
    New(Result);
    try
      Result^.UseCount := 1;
      Result^.FieldNamesCRC := crc;
      Result^.SearchExpression := TACRExpression.Create(Cursor.Session,nil);
      try
        Result^.SearchExpression.ParseForLocate(Cursor,KeyFields,CaseInsensitive,PartialKey);
      except
        try
          Result^.SearchExpression.Free;
        except
        end;
        raise;
      end;
    except
      Dispose(Result);
      raise;
    end;
    FItems.Append(Integer(Result));
  finally
    FSync.Unlock;
  end;
end; // GetCacheItem


//------------------------------------------------------------------------------
// put cache item
//------------------------------------------------------------------------------
procedure TACRFindRecordCache.PutCacheItem(pItem: PACRFindRecordCacheItem);
var i:    Integer;
begin
  FSync.WaitAndLockForWrite;
  try
    i := FItems.IndexOf(Integer(pItem));
    if (i >= 0) then
     if (PItem^.UseCount > 0) then
       Dec(PItem^.UseCount);
  finally
    FSync.Unlock;
  end;
end; // PutCacheItem




////////////////////////////////////////////////////////////////////////////////
//
// TACRTableData
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// set table name
//------------------------------------------------------------------------------
procedure TACRTableData.SetTableName(Name: WideString);
begin
FTableName := Name;
FTableNameCRC := GetTableNameCRC(FTableName);
end; // SetTableName

//------------------------------------------------------------------------------
// get table id
//------------------------------------------------------------------------------
function TACRTableData.GetTableID: TACRObjectID;
begin
Result := INVALID_OBJECT_ID;
end; // GetTableID

//------------------------------------------------------------------------------
// load table state
//------------------------------------------------------------------------------
function TACRTableData.LoadTableState: TACRTableState;
begin
Result := FTableState;
end; // GetTableState

//------------------------------------------------------------------------------
// save table state
//------------------------------------------------------------------------------
procedure TACRTableData.SaveTableState;
begin
end; // SaveTableState

//------------------------------------------------------------------------------
// return last table operation
//------------------------------------------------------------------------------
function TACRTableData.GetLastTableOperation: TACRLastTableOperation;
begin
Result := FTableState.LastTableOperation;
end; // GetTableOperation

//------------------------------------------------------------------------------
// update table state
//------------------------------------------------------------------------------
procedure TACRTableData.UpdateTableState(Operation: TACRLastTableOperation);
begin
if (FTableState.TableState = ACR_MAX_STATE) then
	FTableState.TableState := 0
else
	Inc(FTableState.TableState);
FTableState.LastTableOperation := Operation;
FTableState.LastModificationDate := Now;
end; // UpdateTableState

//------------------------------------------------------------------------------
// update table metadata state
//------------------------------------------------------------------------------
procedure TACRTableData.UpdateTableMetadataState
	(Operation: TACRLastTableOperation);
begin
if (FTableState.TableMetaDataState = ACR_MAX_METADATA_STATE) then
	FTableState.TableMetaDataState := 0
else
	Inc(FTableState.TableMetaDataState);
FTableState.LastModificationDate := Now;
FTableState.LastTableOperation := Operation;
end; // UpdateTableMetadataState

//------------------------------------------------------------------------------
// generate table metadata state
//------------------------------------------------------------------------------
function TACRTableData.GenerateTableMetadataState: Byte;
var
	State, State2: TACRState;
  // r:     TACRState;
  // i,n:   Byte;
begin
State := GenerateTableState;
State2 := GenerateTableState mod 32;
Result := Byte($FF and (State shr State2));

  {
    Result := 0;
    for i := 0 to 7 do
    begin
    r := TACRState(Random(MaxInt));
    n := Byte(State shr (r mod 32));
    n := n and 1;
    n := n shl i;
    Result := Result or n;
    end;
  }
end; // GenerateTableMetadataState

//------------------------------------------------------------------------------
// generate table state
//------------------------------------------------------------------------------
function TACRTableData.GenerateTableState: TACRState;
begin
Result := ACRGenerateRandomCardinal;
end; // GenerateTableState

//------------------------------------------------------------------------------
// set table flag
//------------------------------------------------------------------------------
procedure TACRTableData.SetTableFlag(ToSet: Boolean; Flag: TACRTableFlags);
begin
ACRSetTableFlag(FTableState, ToSet, Flag);
end; // SetTableFlag

//------------------------------------------------------------------------------
// return true if flag set
//------------------------------------------------------------------------------
function TACRTableData.GetTableFlag(Flag: TACRTableFlags): Boolean;
begin
  Result := ACRGetTableFlag(FTableState, Flag);
end; // GetTableFlag


//------------------------------------------------------------------------------
// Fill New ObjectID for all defs
//------------------------------------------------------------------------------
procedure TACRTableData.FillDefsByObjectId(Defs: TACRMetaObjectDefs);
var	i: Integer;
begin
  for i := 0 to Defs.Count - 1 do
    Defs[i].ObjectID := FDatabaseData.GetNewObjectId;
end; // FillDefsByObjectId


//------------------------------------------------------------------------------
// calc record buffer size
//------------------------------------------------------------------------------
function TACRTableData.GetRecordBufferSize: Integer;
begin
  if (FFieldManager.FieldDefs.Count <= 0) then
    raise EACRException.Create(10131, ErrorLNoFields);
  Result := FFieldManager.FieldDefs[FFieldManager.FieldDefs.Count - 1].MemoryOffset
          + FFieldManager.FieldDefs[FFieldManager.FieldDefs.Count - 1].MemoryDataSize;
end; // GetRecordBufferSize


//------------------------------------------------------------------------------
// Create ConstraintManager
//------------------------------------------------------------------------------
procedure TACRTableData.CreateConstraintManager(ConstraintDefs: TACRConstraintDefs);
var	i: Integer;
begin
  if (FConstraintManager <> nil) then
  FConstraintManager.Free;
  // Fill New ObjectIds
  FillDefsByObjectId(ConstraintDefs);
  // Create ConstraintManager
  FConstraintManager := TACRBaseConstraintManager.Create(Self);
  FConstraintManager.ConstraintDefs.Assign(ConstraintDefs);
  // Links ObjectIds
  FConstraintManager.LinkObjectIds;
  // Set empty Names
  FConstraintManager.FillConstraintAutoNames;
end; // CreateConstraintManager


//------------------------------------------------------------------------------
// create and init FieldManager
//------------------------------------------------------------------------------
procedure TACRTableData.CreateFieldManager(FieldDefs: TACRFieldDefs);
var	i: Integer;
begin
  if (FFieldManager <> nil) then
    FFieldManager.Free;
  FFieldManager := TACRBaseFieldManager.Create(Self, FSequenceManager);
  FillDefsByObjectId(FieldDefs);
  FFieldManager.FieldDefs.Assign(FieldDefs);
  FFieldManager.FieldDefs.RecalcFieldOffsets;
  FBLOBFieldsPresent := False;
  for i := 0 to FFieldManager.FieldDefs.Count - 1 do
    if (IsBLOBFieldType(FFieldManager.FieldDefs[i].BaseFieldType)) then
    begin
      FBLOBFieldsPresent := True;
      if (FFieldManager.FieldDefs[i].BLOBBlockSize = 0) then
        raise EACRException.Create(10421, ErrorLZeroBlockSizeIsNotAllowedForField,
          [FFieldManager.FieldDefs[i].Name]);
    end;
end; // CreateFieldManager


//------------------------------------------------------------------------------
// create and init IndexManager
//------------------------------------------------------------------------------
procedure TACRTableData.CreateIndexManager(IndexDefs: TACRIndexDefs);
begin
  if (FIndexManager <> nil) then
    FIndexManager.Free;
  FillDefsByObjectId(IndexDefs);
  FIndexManager := TACRBaseIndexManager.Create(Self);
  FIndexManager.CreateIndexDefs(IndexDefs);
end; // CreateIndexManager


//------------------------------------------------------------------------------
// CreateSequenceManager
//------------------------------------------------------------------------------
procedure TACRTableData.CreateSequenceManager;
begin
  if (FSequenceManager <> nil) then
    FSequenceManager.Free;
  FSequenceManager := TACRBaseSequenceManager.Create(FDatabaseData);
end; // CreateSequenceManager


//------------------------------------------------------------------------------
// BuildSequences
//------------------------------------------------------------------------------
procedure TACRTableData.BuildSequences;
var
    i:            Integer;
    SName:        WideString;
    sequenceDef:  TACRSequenceDef;
begin
  for i := 0 to FFieldManager.FieldDefs.Count - 1 do
  if (IsAutoincFieldType(FFieldManager.FieldDefs[i].AdvancedFieldType)) then
  begin
    // SName := FFieldManager.FieldDefs[i].SequenceName;
    // // If SequenceName not found then Generate It
    // if (SName = '') then
    begin
      SName := FSequenceManager.GenerateSequenceName(True, // FFieldManager.FieldDefs[i].AdvancedFieldType = aftAutoInc,
      FFieldManager.FieldDefs[i].Name, FTableName);
        // Create Sequence
      sequenceDef := FSequenceManager.SequenceDefs.AddCreated;
      sequenceDef.Name := SName;
      sequenceDef.ObjectID := FDatabaseData.GetNewObjectId;

      sequenceDef.DataType := FFieldManager.FieldDefs[i].BaseFieldType;
      sequenceDef.MinValue := FFieldManager.FieldDefs[i].AutoincMinValue;
      sequenceDef.MaxValue := FFieldManager.FieldDefs[i].AutoincMaxValue;
      sequenceDef.LastValue := FFieldManager.FieldDefs[i].AutoincInitialValue;
      sequenceDef.Increment := FFieldManager.FieldDefs[i].AutoincIncrement;
      sequenceDef.Cycled := FFieldManager.FieldDefs[i].AutoincCycled;

      // // Set SequenceName in Field
      // FFieldManager.FieldDefs[i].SequenceName := SName;
      // end
      // else
      // begin
      // // Find Sequence by Name
      // SequenceDef := FSequenceManager.GetOrCreateSequenceDefByName(SName);
    end;
    // Make link from Field To Sequence
    FFieldManager.FieldDefs[i].SequenceDefObjectId := sequenceDef.ObjectID;
  end;
end; // BuildSequences


//------------------------------------------------------------------------------
// load sequences
//------------------------------------------------------------------------------
procedure TACRTableData.LoadSequencesFromStream(Stream: TStream);
var
	SequenceCount: Integer;
	sequenceDef: TACRSequenceDef;
	i: Integer;
begin
FSequenceManager.SequenceDefs.Clear;
LoadDataFromStream(SequenceCount, Sizeof(SequenceCount), Stream, 10218);
{$IFDEF DEBUG_TRACE_TACRTableData_LoadSequencesFromStream}
aaWriteToLog('TACRTableData.LoadSequencesFromStream, SequenceCount = ' +
		IntToStr(SequenceCount));
{$ENDIF}
for i := 0 to SequenceCount - 1 do
begin
sequenceDef := FSequenceManager.SequenceDefs.AddCreated;
sequenceDef.LoadFromStream(Stream);
{$IFDEF DEBUG_TRACE_TACRTableData_LoadSequencesFromStream}
aaWriteToLog('TACRTableData.LoadSequencesFromStream, i = ' + IntToStr(i)
		+ #9 + 'Name = ' + sequenceDef.Name + #13#10 + 'LastValue = ' + IntToStr
		(Int64(sequenceDef.LastValue)) + '.' + #13#10 + 'DataType = ' + BftToStr
		(sequenceDef.DataType) + '.' + #13#10 + 'MinValue = ' + IntToStr
		(Int64(sequenceDef.MinValue)) + #13#10 + 'MaxValue = ' + IntToStr
		(Int64(sequenceDef.MaxValue)) + #13#10 + 'Increment = ' + IntToStr
		(Int64(sequenceDef.Increment)) + #13#10 + 'Cycled = ' + BoolToStr
		(sequenceDef.Cycled, True) + #13#10 + 'ObjectID = ' + IntToStr
		(Int64(sequenceDef.ObjectID)));
{$ENDIF}
end;
end; // LoadSequencesFromStream

//------------------------------------------------------------------------------
// save sequences
//------------------------------------------------------------------------------
procedure TACRTableData.SaveSequencesToStream(Stream: TStream);
var
	SequenceCount: Integer;
	i, j, n: Integer;
	SequenceID: Integer;
	SequenceIDs: array of TACRObjectID;
	SequenceExists: Boolean;
	sequenceDef: TACRSequenceDef;
begin
SequenceCount := 0;
for i := 0 to FFieldManager.FieldDefs.Count - 1 do
	if (IsAutoincFieldType(FFieldManager.FieldDefs[i].AdvancedFieldType)) then
		Inc(SequenceCount);
SaveDataToStream(SequenceCount, Sizeof(SequenceCount), Stream, 10205);
{$IFDEF DEBUG_TRACE_TACRTableData_SaveSequencesToStream}
aaWriteToLog('TACRTableData.SaveSequencesToStream, SequenceCount = ' + IntToStr
		(SequenceCount));
{$ENDIF}
SetLength(SequenceIDs, SequenceCount);
n := 0;
for i := 0 to FFieldManager.FieldDefs.Count - 1 do
	if (IsAutoincFieldType(FFieldManager.FieldDefs[i].AdvancedFieldType)) then
	begin
	SequenceID := FFieldManager.FieldDefs[i].SequenceDefObjectId;
	SequenceExists := False;
	for j := 0 to n - 1 do
		if (SequenceIDs[j] = SequenceID) then
		begin
		SequenceExists := True;
		break;
		end;
	if (not SequenceExists) then
	begin
	sequenceDef := FSequenceManager.GetSequenceDef(SequenceID);
	sequenceDef.SaveToStream(Stream);
{$IFDEF DEBUG_TRACE_TACRTableData_SaveSequencesToStream}
	aaWriteToLog('TACRTableData.SaveSequencesToStream, n = ' + IntToStr(i)
			+ #9 + 'Name = ' + sequenceDef.Name + #13#10 + 'LastValue = ' + IntToStr
			(Int64(sequenceDef.LastValue)) + '.' + #13#10 + 'DataType = ' + BftToStr
			(sequenceDef.DataType) + '.' + #13#10 + 'MinValue = ' + IntToStr
			(Int64(sequenceDef.MinValue)) + #13#10 + 'MaxValue = ' + IntToStr
			(Int64(sequenceDef.MaxValue)) + #13#10 + 'Increment = ' + IntToStr
			(Int64(sequenceDef.Increment)) + #13#10 + 'Cycled = ' + BoolToStr
			(sequenceDef.Cycled, True) + #13#10 + 'ObjectID = ' + IntToStr
			(Int64(sequenceDef.ObjectID)));
{$ENDIF}
	SequenceIDs[n] := SequenceID;
	Inc(n);
	end;
	end; // field linked to sequence
end; // SaveSequencesToStream

//------------------------------------------------------------------------------
// init cursor
//------------------------------------------------------------------------------
procedure TACRTableData.InitCursor(Cursor: TACRCursor);
begin
Cursor.FieldValuesOffset := FFieldManager.FieldDefs[0].MemoryOffset;
Cursor.RecordSize := GetRecordBufferSize;
end; // InitCursor

//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRTableData.Lock(WriteMode: Boolean);
begin
if (WriteMode) then
	FThreadSync.WaitAndLockForWrite
else
	FThreadSync.WaitAndLockForRead;
end; // Lock

//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRTableData.Unlock;
begin
FThreadSync.Unlock;
end; // Unlock

//------------------------------------------------------------------------------
// lock cursor list
//------------------------------------------------------------------------------
procedure TACRTableData.LockCursorList(Exclusive: Boolean);
begin
if (Exclusive) then
	FCursorListThreadSync.WaitAndLockForWrite
else
	FCursorListThreadSync.WaitAndLockForRead;
end; // LockCursorList

//------------------------------------------------------------------------------
// unlock cursor list
//------------------------------------------------------------------------------
procedure TACRTableData.UnlockCursorList;
begin
FCursorListThreadSync.Unlock;
end; // UnlockCursorList

//------------------------------------------------------------------------------
// write table metadata
//------------------------------------------------------------------------------
procedure TACRTableData.WriteTableMetadata(SessionID: TACRSessionID);
begin
end; // WriteTableMetadata


//------------------------------------------------------------------------------
// free if no sessions connected
//------------------------------------------------------------------------------
procedure TACRTableData.FreeIfNoSessionsConnected;
begin
end; // FreeIfNoSessionsConnected


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRTableData.Create(aDatabaseData: TACRDatabaseData);
begin
  FThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False, Self, 'Main');
  FCursorListThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False, Self, 'CursorList');
  FCursorList := TList.Create;
  FFieldManager := nil;
  FRecordManager := nil;
  FIndexManager := nil;
  FConstraintManager := nil;
  FSequenceManager := nil;
  FDatabaseData := aDatabaseData;
  FBLOBFieldsPresent := False;
  FRepair := False;
  FDoNotLockDatabaseData := False;
  FTableState.TableState := 0;
  FTableState.LastModificationDate := Now;
  FTableName := '';
  FTableNameCRC := 0;
  if (FDatabaseData.PageManager <> nil) then
    FCache := TACRTableCache.Create(FDatabaseData.PageManager,
      FDatabaseData.PageManager.Cache)
  else
    FCache := nil;
  FRecordBufferCache := nil;
  FFindRecordCache := nil;
  FExclusive := False;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRTableData.Destroy;
begin
try
	if (FRecordBufferCache <> nil) then
		FreeAndNil(FRecordBufferCache);
	if (FFindRecordCache <> nil) then
		FreeAndNil(FFindRecordCache);
	if (FIndexManager <> nil) then
		FreeAndNil(FIndexManager);
	if (FFieldManager <> nil) then
		FreeAndNil(FFieldManager);
	if (FConstraintManager <> nil) then
		FreeAndNil(FConstraintManager);
	if (FRecordManager <> nil) then
		FreeAndNil(FRecordManager);
	if (FSequenceManager <> nil) then
		FreeAndNil(FSequenceManager);
	FreeAndNil(FCursorList);
	FreeAndNil(FThreadSync);
	FreeAndNil(FCursorListThreadSync);
	FreeAndNil(FCache);
	if (FDoNotLockDatabaseData) then
		FDatabaseData.FTableDataList.Remove(Self)
	else
		FDatabaseData.DeleteTableData(Self);
finally
	inherited;
end;
end; // Destroy


//------------------------------------------------------------------------------
// lock table
//------------------------------------------------------------------------------
procedure TACRTableData.LockTable(
                    bWriteMode: 			Boolean;
                    Session: 					TACRBaseSession;
                    ErrorCode: 				Integer;
                    DoNotLockThread: 	Boolean
                   );
begin
end; // LockTable


//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
procedure TACRTableData.UnlockTable(
                    bWriteMode: 			Boolean;
                    Session: 					TACRBaseSession;
                    DoNotLockThread: 	Boolean
                    );
begin
end; // UnlockTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TACRTableData.DeleteTable(Session: TACRBaseSession; Cascade: Boolean;
	DesignMode: Boolean);
var
	i: Integer;
	ConstraintDef: TACRConstraintDef;
	ReferencedCursor: TACRLocalCursor;
begin
  { TODO : raise  EACRException if operation that modifies metadata is performed by cursor in transaction }
  if (not DesignMode) then
    if (FCursorList.Count > 0) then
      raise EACRException.Create(20017, ErrorACannotDeleteBusyTable,
        [FTableName]);
  if (not Cascade) then
    if (FConstraintManager.ConstraintDefs.ForeignKeysActionsExists or
        FConstraintManager.ConstraintDefs.ForeignKeysExists) then
      raise EACRException.Create(11481, ErrorLCannotDeleteTableForeignKeys,
        [FTableName]);
  if (Session <> nil) then
    if ((FConstraintManager.ConstraintDefs.ForeignKeysActionsExists or
          FConstraintManager.ConstraintDefs.ForeignKeysExists)) then
    begin
      for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
      begin
        ConstraintDef := FConstraintManager.ConstraintDefs.Items[i];
        if (ConstraintDef.ConstraintType = ctFK) or
          (ConstraintDef.ConstraintType = ctFKAction) then
          if (WideUpperCase(TACRConstraintDefForeignKeyAction(ConstraintDef)
                .ReferencedTableName) <> WideUpperCase(FTableName)) then
          begin
          ReferencedCursor := TACRLocalCursor.Create;
          try
            CheckForeignKeyOpenReferencedTable(ReferencedCursor, Session, FInMemory,
              TACRConstraintDefForeignKeyAction(ConstraintDef), True, False);
            try
              ReferencedCursor.DeleteConstraint(TACRConstraintDefForeignKeyAction
                  (ConstraintDef).ReferencedFKName, False, True);
            finally
              CheckForeignKeyCloseReferencedTable(ReferencedCursor);
            end;
          finally
            try
              ReferencedCursor.Free;
            except
            end;
          end;
        end;
      end;
    end; // remove foreign keys and actions
  FConstraintManager.ConstraintDefs.ForeignKeysActionsExists := False;
  FConstraintManager.ConstraintDefs.ForeignKeysExists := False;
end; // DeleteTable

//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TACRTableData.EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean);
begin
if (FCursorList.Count > 0) then
	raise EACRException.Create(10072, ErrorLCannotDeleteBusyTable, [FTableName]);
if (Cursor <> nil) then
	EmptyAllIndexes(Cursor.Session.SessionID)
else
	raise EACRException.Create(11887, ErrorLNilPointer);
  // EmptyAllIndexes(SYSTEM_SESSION_ID);
end; // EmptyTable

//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TACRTableData.RenameTable(Cursor: TACRCursor;
	NewTableName: WideString);
begin
if (FCursorList.Count > 0) then
	raise EACRException.Create(10150, ErrorLCannotRenameBusyTable, [FTableName]);
if (FConstraintManager.ConstraintDefs.ForeignKeysExists or FConstraintManager.
		ConstraintDefs.ForeignKeysActionsExists) then
	RenameTableInForeignKeys(Cursor, FTableName, NewTableName);
FTableName := NewTableName;
FTableNameCRC := GetTableNameCRC(FTableName);
UpdateTableMetadataState;
FTableState.LastTableOperation := ltoRename;
end; // RenameTable

//------------------------------------------------------------------------------
// Add Foreign key
//------------------------------------------------------------------------------
procedure TACRTableData.AddForeignKey(Cursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKey);
var
	i, n: Integer;
	ReferencedCursor: TACRLocalCursor;
	FKAction: TACRConstraintDefForeignKeyAction;
	bSelfReference: Boolean;
begin
if (WideUpperCase(FTableName) = WideUpperCase(ConstraintDef.ReferencedTableName)
	) then
begin
    // self reference
ReferencedCursor := TACRLocalCursor(Cursor);
bSelfReference := True;
end
else
begin
bSelfReference := False;
ReferencedCursor := TACRLocalCursor.Create;
try
	CheckForeignKeyOpenReferencedTable(ReferencedCursor, Cursor, ConstraintDef,
		True, False);
except
	ReferencedCursor.Free;
	raise ;
end;
end;
try
	n := FConstraintManager.ConstraintDefs.GetDefNumberByName(ConstraintDef.Name);
	if (n >= 0) then
		raise EACRException.Create(11588,
			ErrorLCannotCreateForeignKeyAlreadyExists, [ConstraintDef.Name,
			FTableName]);
	for i := 0 to High(ConstraintDef.Columns) do
	begin
      //
	n := FFieldManager.FieldDefs.GetDefNumberByName
		(ConstraintDef.Columns[i].ColumnName);
	if (n < 0) then
		raise EACRException.Create(11587,
			ErrorLCannotCreateForeignKeyColumnDoesNotExist, [ConstraintDef.Name,
			ConstraintDef.Columns[i].ColumnName, FTableName]);
	ConstraintDef.Columns[i].ColumnObjectID := FFieldManager.FieldDefs.Items[n]
		.ObjectID;
	end;
	CheckForeignKeyDefinition(ConstraintDef, ReferencedCursor, bSelfReference);
	CheckRecordsCompatibleWithForeignKey(Cursor, ReferencedCursor, ConstraintDef);
	FKAction := ReferencedCursor.TableData.CreateForeignKeyAction
		(ReferencedCursor, ConstraintDef, FTableName,
		INVALID_OBJECT_ID);
	ConstraintDef.ReferencedFKName := FKAction.Name;
	ConstraintDef.ReferencedFKObjectID := FKAction.ObjectID;
	FConstraintManager.ConstraintDefs.AddFK.Assign(ConstraintDef);
	UpdateTableMetadataState;
	FTableState.LastTableOperation := ltoAddForeignKey;
finally
	if (ReferencedCursor <> Cursor) then
	begin
	CheckForeignKeyCloseReferencedTable(ReferencedCursor);
	ReferencedCursor.Free;
	end;
end;
end; // AddForeignKey

//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TACRTableData.DeleteConstraint(
                                          Cursor:           TACRCursor;
                                          Name:             WideString;
	                                        Cascade:          Boolean;
                                          FKPartialDelete:  Boolean
                                        );
var
	Num, i:           Integer;
	ConstraintDef:    TACRConstraintDef;
	ReferencedCursor: TACRLocalCursor;
	RefName:          WideString;
begin
  Num := FConstraintManager.ConstraintDefs.GetDefNumberByName(Name);
  if (Num < 0) then
    raise EACRException.Create(11482, ErrorLConstraintNotFound,
      [Name, FTableName]);
  ConstraintDef := FConstraintManager.ConstraintDefs.Items[Num];
  if (ConstraintDef.ConstraintType = ctPK) then
  begin
    if (not Cascade) and
      (FConstraintManager.ConstraintDefs
        .ForeignKeysActionsExists) then
      raise EACRException.Create(11483, ErrorLCannotDeletePKFKActionsExists,
        [ConstraintDef.Name, FTableName]);
    if (FConstraintManager.ConstraintDefs.ForeignKeysActionsExists) then
      for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
        if (FConstraintManager.ConstraintDefs.Items[i].ConstraintType = ctFKAction)  then
          DeleteConstraint(Cursor, FConstraintManager.ConstraintDefs.Items[i].Name,
            True, False);
    DeleteIndex(TACRConstraintDefPrimary(ConstraintDef).IndexObjectID, Cursor);
    Exit;
  end;

  if ((ConstraintDef.ConstraintType = ctFKAction) or
      (ConstraintDef.ConstraintType = ctFK)) and
    (not FKPartialDelete) then
  begin
    // fixed in v.5.40
    // check self reference
    if (GetTableNameCRC(TACRConstraintDefForeignKeyAction(ConstraintDef)
          .ReferencedTableName, True) = FTableNameCRC) then
    begin
      RefName := TACRConstraintDefForeignKeyAction(ConstraintDef).ReferencedFKName;
      Num := FConstraintManager.ConstraintDefs.GetDefNumberByName(RefName);
      if (Num < 0) then
        raise EACRException.Create(12364, ErrorLConstraintNotFound,
          [RefName, FTableName]);
      FConstraintManager.ConstraintDefs.Delete(Num);
    end
    else
    begin
      // reference to other table
      ReferencedCursor := TACRLocalCursor.Create;
      try
        CheckForeignKeyOpenReferencedTable(ReferencedCursor, Cursor,
          TACRConstraintDefForeignKeyAction(ConstraintDef), True, False);
        try
          ReferencedCursor.DeleteConstraint(TACRConstraintDefForeignKeyAction
              (ConstraintDef).ReferencedFKName, False, True);
        finally
          CheckForeignKeyCloseReferencedTable(ReferencedCursor);
        end;
      finally
        ReferencedCursor.Free;
      end;
    end;
  end; // Delete FK
  // fixed in v.5.10
  Num := FConstraintManager.ConstraintDefs.GetDefNumberByName(Name);
  if (Num < 0) then
    raise EACRException.Create(12172, ErrorLConstraintNotFound,
      [Name, FTableName]);
  FConstraintManager.ConstraintDefs.Delete(Num);
  UpdateTableMetadataState;
  FTableState.LastTableOperation := ltoDeleteConstraint;
end; // DeleteConstraint


//------------------------------------------------------------------------------
// rename ReferenceTableName in foreign keys
//------------------------------------------------------------------------------
procedure TACRTableData.RenameReferenceTableName(Cursor: TACRCursor;
	OldName, NewName: WideString);
var
	ConstraintDef: TACRConstraintDefForeignKeyAction;
	name: WideString;
	i: Integer;
begin
name := WideUpperCase(OldName);
for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
	if (FConstraintManager.ConstraintDefs.Items[i].ConstraintType = ctFK) or
		(FConstraintManager.ConstraintDefs.Items[i].ConstraintType = ctFKAction)
		then
	begin
	ConstraintDef := TACRConstraintDefForeignKeyAction
		(FConstraintManager.ConstraintDefs.Items[i]);
	if (WideUpperCase(ConstraintDef.ReferencedTableName) = name) then
	begin
	ConstraintDef.ReferencedTableName := NewName;
	end;
	RenameConstraintFKTemporaryNames(ConstraintDef);
	end;
UpdateTableMetadataState;
FTableState.LastTableOperation := ltoRenameReferencedTableName;
end; // RenameReferenceTableName

//------------------------------------------------------------------------------
// load table from stream
//------------------------------------------------------------------------------
procedure TACRTableData.LoadTableFromStream(Cursor: TACRCursor;
	Stream: TStream);
begin
if (FCursorList.Count > 0) then
	raise EACRException.Create(10152, ErrorLCannotLoadBusyTable, [FTableName]);
end; // LoadTable

//------------------------------------------------------------------------------
// save table to stream
//------------------------------------------------------------------------------
procedure TACRTableData.SaveTableToStream(Stream: TStream;
	CompressionAlgorithm: TACRCompressionAlgorithm; CompressionMode: Byte;
	BlockSize: Integer; SkipCheckIsTableOpened: Boolean);
begin
if (not SkipCheckIsTableOpened) then
	if (FCursorList.Count > 0) then
		raise EACRException.Create(10153, ErrorLCannotSaveBusyTable, [FTableName]);
end; // SaveTable

//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TACRTableData.OpenTable(Cursor: TACRCursor);
begin
{$IFDEF DEBUG_TRACE_CREATE_TABLE_CACHE}
aaWriteToLog('TACRTableCache.Create - FCache = ' + IntToHex(Integer(FCache),8) + #13#10 + 'TableName = ' + FTableName + #13#10 +'TableData.ClassName = ' + Self.ClassName);
{$ENDIF}
  FCursorList.Add(Cursor);
  if (FRecordBufferCache = nil) then
	 FRecordBufferCache := TACRRecordBufferCache.Create(GetRecordBufferSize);
  if (FFindRecordCache = nil) then
   FFindRecordCache := TACRFindRecordCache.Create(Self);
  // moved from TACRLocalCursor to TACRTableData in 4.90 -
  // to avoid crash on multi-processor machines
{$IFDEF DEBUG_TRACE_TACRTableData_OpenTable}
aaWriteToLog('TACRTableData.OpenTable before update table definitions. TableName = ' +	FTableName);
{$ENDIF}
Cursor.IsOpen := True;
Cursor.UpdateTableDefinitions;
Cursor.Comment := FComment;
{$IFDEF DEBUG_TRACE_TACRTableData_OpenTable}
aaWriteToLog('TACRTableData.OpenTable after update table definitions. TableName = ' +FTableName);
{$ENDIF}
end; // OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TACRTableData.CloseTable(Cursor: TACRCursor);
var
      i:          Integer;
      b:          Boolean;
      bExclusive: Boolean;
begin
  FCursorList.Remove(Cursor);
  if (Cursor.Session = nil) then
    raise EACRException.Create(11631, ErrorLNilPointer);
  if (IndexManager <> nil) then
    if (IndexManager.FIndexDefs.Count > 0) then
    begin
      b := True;
      bExclusive := False;
      for i := 0 to FCursorList.Count - 1 do
        if (TACRCursor(FCursorList.Items[i]).Session <> nil) then
         begin
          if (TACRCursor(FCursorList.Items[i]).Session.SessionID = Cursor.Session.SessionID) then
            b := False
          else
          if (TACRCursor(FCursorList.Items[i]).Exclusive) then
            bExclusive := True;
         end;
      if (b) then
        FIndexManager.ClearIndexCache(Cursor.Session.SessionID);
      FExclusive := bExclusive;
    end;
  if (FCursorList.Count = 0) then
  begin
    if (FRecordBufferCache <> nil) then
      FreeAndNil(FRecordBufferCache);
    if (FFindRecordCache <> nil) then
      FreeAndNil(FFindRecordCache);
  end;
end; // CloseTable


//------------------------------------------------------------------------------
// Rename Field by Field Index in FieldDefs
//------------------------------------------------------------------------------
procedure TACRTableData.RenameField(Cursor: TACRCursor;
	FieldName, NewFieldName: WideString);
var
	fd: TACRFieldDef;
	i, j: Integer;
	ConstraintDef: TACRConstraintDefForeignKey;
	IndexDef: TACRIndexDef;
begin
  // Check Field Exists
fd := FFieldManager.FieldDefs.GetFieldDefByName(FieldName);
if (fd = nil) then
	raise EACRException.Create(30343, ErrorGFieldWithNameNotFound, [FieldName]);

  // Check For Duplicate FieldName
if (FFieldManager.FieldDefs.GetFieldDefByName(NewFieldName) <> nil) then
	raise EACRException.Create(30344, ErrorGCannotRenameField,
		[FieldName, NewFieldName]);
for i := 0 to FIndexManager.IndexDefs.Count - 1 do
begin
IndexDef := FIndexManager.IndexDefs.Items[i];
for j := 0 to IndexDef.ColumnCount - 1 do
	if (WideUpperCase(IndexDef.Columns[j].FieldName) = WideUpperCase(fd.Name))
		then
		raise EACRException.Create(11489, ErrorLCannotRenameFieldInIndex,
			[fd.Name, FTableName, IndexDef.Name]);
end;

if (FConstraintManager.ConstraintDefs.ForeignKeysExists) then
begin
for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
	if (FConstraintManager.ConstraintDefs.Items[i].ConstraintType = ctFK) or
		(FConstraintManager.ConstraintDefs.Items[i].ConstraintType = ctFKAction)
		then
	begin
	ConstraintDef := TACRConstraintDefForeignKey
		(FConstraintManager.ConstraintDefs.Items[i]);
	for j := 0 to High(ConstraintDef.Columns) do
		if (ConstraintDef.Columns[j].ColumnObjectID = fd.ObjectID) then
			raise EACRException.Create(11488, ErrorLCannotRenameFieldInForeignKey,
				[fd.Name, FTableName, ConstraintDef.Name]);
	end;
end;
fd.Name := NewFieldName;
UpdateTableMetadataState;
FTableState.LastTableOperation := ltoRenameField;
end; // RenameField

//------------------------------------------------------------------------------
// add index
//------------------------------------------------------------------------------
procedure TACRTableData.AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor);
var
	OldPos: Pointer;
	i: Integer;
begin
OldPos := Cursor.SavePosition;
try
	FIndexManager.CreateIndex(Cursor, IndexDef);
	if ((not IndexDef.Temporary) and (not Cursor.Temporary)) then
		FConstraintManager.AddConstraintFromIndex(IndexDef);
    // added in v.4.90
	for i := 0 to CursorList.Count - 1 do
	begin
	TACRCursor(CursorList.Items[i]).IndexDefs.Assign(FIndexManager.IndexDefs);
	TACRCursor(CursorList.Items[i]).UpdateIndexDefinitions;
	end;
	UpdateTableMetadataState;
	UpdateTableState(ltoAddIndex);
finally
	Cursor.RestorePosition(OldPos);
	Cursor.FreePosition(OldPos);
end;
end; // AddIndex

//------------------------------------------------------------------------------
// DeleteIndex
//------------------------------------------------------------------------------
procedure TACRTableData.DeleteIndex(IndexID: TACRObjectID; Cursor: TACRCursor);
var
	IndexDef: TACRIndexDef;
	i: Integer;
begin
  // Drop Constraint
if (Cursor <> nil) then
begin
IndexDef := TACRIndexDef(FIndexManager.IndexDefs.GetDefByObjectID(IndexID));
if ((not IndexDef.Temporary) and (not Cursor.Temporary)) then
	FConstraintManager.DeleteConstraintForIndexID(IndexID);
FIndexManager.DropIndex(Cursor.Session.SessionID, IndexID);
end
else
begin
raise EACRException.Create(11888, ErrorLNilPointer);
    // FIndexManager.DropIndex(SYSTEM_SESSION_ID, IndexID);
end;
  // added in v.4.90
for i := 0 to CursorList.Count - 1 do
begin
TACRCursor(CursorList.Items[i]).IndexDefs.Assign(FIndexManager.IndexDefs);
TACRCursor(CursorList.Items[i]).UpdateIndexDefinitions;
end;
UpdateTableMetadataState;
UpdateTableState(ltoDeleteIndex);
end; // DeleteIndex

//------------------------------------------------------------------------------
// EmptyIndex
//------------------------------------------------------------------------------
procedure TACRTableData.EmptyIndex(IndexID: TACRObjectID;
	SessionID: TACRSessionID);
begin
FIndexManager.EmptyIndex(SessionID, IndexID);
UpdateTableState(ltoEmptyIndex);
end; // EmptyIndex

//------------------------------------------------------------------------------
// DeleteAllIndexes
//------------------------------------------------------------------------------
procedure TACRTableData.DeleteAllIndexes(Cursor: TACRCursor);
begin
if (FIndexManager <> nil) then
	while (FIndexManager.IndexDefs.Count > 0) do
		DeleteIndex(FIndexManager.IndexDefs.Items[0].ObjectID, Cursor);
end; // DeleteAllIndexes

//------------------------------------------------------------------------------
// EmptyAllIndexes
//------------------------------------------------------------------------------
procedure TACRTableData.EmptyAllIndexes(SessionID: TACRSessionID);
begin
if (FIndexManager <> nil) then
	FIndexManager.EmptyAllIndexes(SessionID);
end; // EmptyAllIndexes

//------------------------------------------------------------------------------
// return index name of the index or '' if not found
//------------------------------------------------------------------------------
function TACRTableData.FindIndex(Cursor: TACRCursor;
	FieldNamesList, AscDescList,
	CaseSensitivityList: TACRWideStringList): WideString;
var
	ID: TACRObjectID;
	IndexDef: TACRMetaObjectDef;
begin
ID := FIndexManager.FindIndex(FieldNamesList, AscDescList, CaseSensitivityList);
if (ID = INVALID_OBJECT_ID) then
	Result := ''
else
begin
IndexDef := FIndexManager.IndexDefs.GetDefByObjectID(ID);
if (IndexDef = nil) then
	raise EACRException.Create(11384, ErrorLCannotFindIndexByID, [ID]);
Result := IndexDef.Name;
end;
end; // FindIndex

//------------------------------------------------------------------------------
// return true if Unique Constraint Failed
//------------------------------------------------------------------------------
function TACRTableData.IsUniqueConstraintFailed(SessionID: TACRSessionID;
	IndexID: TACRObjectID; NewRecordBuffer: TACRRecordBuffer;
	OldRecordBuffer: TACRRecordBuffer; ToInsert: Boolean;
	CurrentRecordID: TACRRecordID): Boolean;
begin
if (InternalGetRecordCount > 0) then
	if (ToInsert) then
		Result := not FIndexManager.OpenIndex(IndexID).CanInsertRecord(SessionID,
			NewRecordBuffer)
	else
		Result := not FIndexManager.OpenIndex(IndexID).CanUpdateRecord(SessionID,
			OldRecordBuffer, NewRecordBuffer)
	else
		Result := False;
end; // IsUniqueConstraintFailed

//------------------------------------------------------------------------------
// check Name and ReferencedFKName for tempoary FK name prefix (set by RestructureTable / RepairTable in ACRMain)
// and if found remove name prefix;
//------------------------------------------------------------------------------
procedure TACRTableData.RenameConstraintFKTemporaryNames
	(ConstraintDef: TACRConstraintDefForeignKeyAction);

function CheckAndRename(const Name: TACRObjectName): TACRObjectName;
var
	i, l, j: Integer;
	s: WideString;
begin
Result := Name;
s := WideUpperCase(Name);
i := Pos(WideString(ACRConstraintFKTemporaryNamePrefix), s);
l := Length(ACRConstraintFKTemporaryNamePrefix);
j := Length(Name);
if (i = 1) then
begin
if (j - l <= 0) then
	raise EACRException.Create(11585, ErrorLInvalidFKTempName, [Name])
else
	Result := Copy(Name, l + 1, j - l);
end;
end; // CheckAndRename

begin
ConstraintDef.Name := CheckAndRename(ConstraintDef.Name);
ConstraintDef.ReferencedFKName := CheckAndRename
	(ConstraintDef.ReferencedFKName);
end; // RenameConstraintFKTemporaryNames

//------------------------------------------------------------------------------
// raise an exception if record not compatible with foreign key was found
//------------------------------------------------------------------------------
procedure TACRTableData.CheckRecordsCompatibleWithForeignKey
	(Cursor: TACRCursor; ReferencedCursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKey);
var
	buf, CurrentRecordBuffer: TACRRecordBuffer;
	OldPos: Pointer;

function IsConstraintFailed: Boolean;
var
	SearchExpression: TACRExpression;
	Failed: Boolean;
begin
Result := not IsForeignKeyNullValuesOK(Cursor, ConstraintDef, Failed);
if (Failed) then
	Result := True
else
	if (Result) then
	begin
	SearchExpression := CheckForeignKeyBuildSearchExpression(ReferencedCursor,
		Cursor, ConstraintDef);
	try
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // search record
		Result := not TACRLocalCursor(ReferencedCursor).TableData.FindRecord(
                    ReferencedCursor, True, True, nil, nil, False, True);
{$ELSE}
		Result := not TACRLocalCursor(ReferencedCursor).TableData.FindRecord(
                    ReferencedCursor, SearchExpression, nil, True, True,
                    nil, nil, False, True);
{$ENDIF}
	finally
		SearchExpression.Free;
	end;
	end; // if not null and not failed
end; // IsConstraintFailed

begin
buf := Cursor.CurrentRecordBuffer;
CurrentRecordBuffer := Cursor.AllocateRecordBuffer;
Cursor.CurrentRecordBuffer := CurrentRecordBuffer;
OldPos := Cursor.SavePosition;
Cursor.FirstPosition := True;
Cursor.LastPosition := False;
try
	while (Cursor.GetRecordBuffer(grmNext) = grrOK) do
	begin
	if (IsConstraintFailed) then
		raise EACRException.Create(11586, ErrorLConstraintForeignKeyViolated,
			[ConstraintDef.Name, FTableName]);
	end;
finally
	Cursor.FreeRecordBuffer(CurrentRecordBuffer);
	Cursor.CurrentRecordBuffer := buf;
	Cursor.RestorePosition(OldPos);
	Cursor.FreePosition(OldPos);
end;
end; // CheckRecordsCompatibleWithForeignKey

//------------------------------------------------------------------------------
// return true if current record in Cursor does not violate foreign key constraint
// (have null field values corresponding match type)
//------------------------------------------------------------------------------
function TACRTableData.IsForeignKeyNullValuesOK(Cursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKey; var Failed: Boolean): Boolean;
var
	i, FieldNo:   Integer;
	Value:        TACRVariant;
	NullFound:    Boolean;
begin
  Value := TACRVariant.Create;
  try
    Failed := False;
    NullFound := False;
    Result := (ConstraintDef.MatchType <> cfkmtDefault);
    for i := 0 to High(ConstraintDef.Columns) do
    begin
      FieldNo := FieldManager.FieldDefs.GetDefNumberByObjectId
        (ConstraintDef.Columns[i].ColumnObjectID);
      if (FieldNo < 0) then
        raise EACRException.Create(11422, ErrorLForeignKeyInvalidColumnID,
          [ConstraintDef.Name, FTableName, i, ConstraintDef.Columns[i].ColumnObjectID]);
      Cursor.GetFieldValue(Value, FieldNo, True, False);
      case ConstraintDef.MatchType of
        cfkmtDefault:
        begin
          if (Value.IsNull) then
          begin
            Result := True;
            break;
          end;
        end;
      cfkmtFull:
        begin
          if (not Value.IsNull) then
          begin
            Result := False;
            if (NullFound) then
              Failed := True;
          end
          else
          begin
            if (not Result) then
              Failed := True;
            NullFound := True;
          end;
        end;
      cfkmtPartial:
        begin
          if (not Value.IsNull) then
          begin
            Result := False;
            break;
          end;
        end
      else
        raise EACRException.Create(11421, ErrorLForeignKeyInvalidMatchType,
          [ConstraintDef.Name, FTableName, Byte(ConstraintDef.MatchType)]);
      end; // case
    end; // for
  finally
    Value.Free;
  end;
end; // IsForeignKeyNullValuesOK

//------------------------------------------------------------------------------
// referenced cursor open
//------------------------------------------------------------------------------
procedure TACRTableData.CheckForeignKeyOpenReferencedTable(
                  ReferencedCursor:     TACRCursor;
			            Cursor:               TACRCursor;
                  ConstraintDef:        TACRConstraintDefForeignKeyAction;
			            Exclusive:            Boolean;
                  SkipExistsCheck:      Boolean
                    );
begin
  ReferencedCursor.Session := Cursor.Session;
  ReferencedCursor.InMemory := Cursor.InMemory;
  ReferencedCursor.FTableName := ConstraintDef.ReferencedTableName;
  ReferencedCursor.IsDesignMode := Cursor.IsDesignMode;
  ReferencedCursor.Exclusive := Exclusive;
  ReferencedCursor.ReadOnly := True;
    // commented in v.4.60 - no needed, as it will be done in OpenTable
    {
      if (not SkipExistsCheck) then
      if (not ReferencedCursor.Session.TableExists(ReferencedCursor.FTableName)) then
      raise EACRException.Create(11435,ErrorLInvalidFKReferencedTable,[ConstraintDef.Name,FTableName,ReferencedCursor.FTableName]);
    }
  ReferencedCursor.SkipTableExistsCheck := SkipExistsCheck;
  ReferencedCursor.OpenTableByFieldDefs(nil, nil, nil);
  ReferencedCursor.InternalInitFieldDefs;
  ReferencedCursor.InternalFirst;
  ReferencedCursor.CurrentRecordBuffer := ReferencedCursor.AllocateRecordBuffer;
end; // CheckForeignKeyOpenReferencedTable


//------------------------------------------------------------------------------
// referenced cursor open
//------------------------------------------------------------------------------
procedure TACRTableData.CheckForeignKeyOpenReferencedTable(
                        ReferencedCursor:   TACRCursor;
                        Session:            TACRBaseSession;
                        InMemory:           Boolean;
                      	ConstraintDef:      TACRConstraintDefForeignKeyAction;
                        Exclusive:          Boolean;
                      	SkipExistsCheck:    Boolean
                        );
begin
  ReferencedCursor.Session := Session;
  ReferencedCursor.InMemory := InMemory;
  ReferencedCursor.FTableName := ConstraintDef.ReferencedTableName;
  ReferencedCursor.IsDesignMode := False;
  ReferencedCursor.Exclusive := Exclusive;
  ReferencedCursor.ReadOnly := True;
    // commented in v.4.60 - no needed, as it will be done in OpenTable
    {
      if (not SkipExistsCheck) then
      if (not ReferencedCursor.Session.TableExists(ReferencedCursor.FTableName)) then
      raise EACRException.Create(11487,ErrorLInvalidFKReferencedTable,[ConstraintDef.Name,FTableName,ReferencedCursor.FTableName]);
    }
  ReferencedCursor.SkipTableExistsCheck := SkipExistsCheck;
  ReferencedCursor.OpenTableByFieldDefs(nil, nil, nil);
  ReferencedCursor.InternalInitFieldDefs;
  ReferencedCursor.InternalFirst;
  ReferencedCursor.CurrentRecordBuffer := ReferencedCursor.AllocateRecordBuffer;
end; // CheckForeignKeyOpenReferencedTable

//------------------------------------------------------------------------------
// close referenced cursor
//------------------------------------------------------------------------------
procedure TACRTableData.CheckForeignKeyCloseReferencedTable(Cursor: TACRCursor);
var
	Buffer: PAnsiChar;
begin
Buffer := Cursor.CurrentRecordBuffer;
Cursor.FreeRecordBuffer(Buffer);
Cursor.CurrentRecordBuffer := nil;
Cursor.CloseTable;
end; // CheckForeignKeyCloseReferencedTable

//------------------------------------------------------------------------------
// build search expression for the foreign key check
//------------------------------------------------------------------------------
function TACRTableData.CheckForeignKeyBuildSearchExpression(
    ReferencedCursor:   TACRCursor;
    Cursor:             TACRCursor;
	  ConstraintDef:      TACRConstraintDefForeignKey
                                                            ): TACRExpression;
var
	PrimaryIndex: TACRIndexDef;
begin
  PrimaryIndex := ReferencedCursor.IndexDefs.FindPrimaryIndex;
  if (PrimaryIndex = nil) then
    raise EACRException.Create(11424, ErrorLForeignKeyNoPrimaryIndex,
      [ConstraintDef.Name, FTableName, ReferencedCursor.TableName]);
  if (PrimaryIndex.ColumnCount < Length(ConstraintDef.Columns)) then
    raise EACRException.Create(11425,
      ErrorLForeignKeyPrimaryIndexInvalidColumnCount, [ConstraintDef.Name,
      FTableName, PrimaryIndex.Name, ReferencedCursor.TableName]);
  Result := TACRExpression.Create(Cursor.Session, nil);
  Result.PrepareForeignKeyCheck(ReferencedCursor, Cursor, ConstraintDef,
    PrimaryIndex);
end; // CheckForeignKeyBuildSearchExpression

//------------------------------------------------------------------------------
// build foreign key action filter and return true if there is no detail records
//------------------------------------------------------------------------------
function TACRTableData.CheckForeignKeyActionBuildSearchExpression
	(ReferencedCursor: TACRCursor; Cursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKeyAction;
	ToUpdate: Boolean): Boolean;
var
	PrimaryIndex: TACRIndexDef;
	Buffer: PAnsiChar;
begin
  PrimaryIndex := FIndexManager.IndexDefs.FindPrimaryIndex;
  if (PrimaryIndex = nil) then
    raise EACRException.Create(11457, ErrorLForeignKeyNoPrimaryIndex,
      [ConstraintDef.ReferencedFKName, ReferencedCursor.TableName, FTableName]);
  if (PrimaryIndex.ColumnCount < Length(ConstraintDef.Columns)) then
    raise EACRException.Create(11458,
      ErrorLForeignKeyPrimaryIndexInvalidColumnCount,
      [ConstraintDef.ReferencedFKName, ReferencedCursor.TableName,
      PrimaryIndex.Name, FTableName]);
  if (ToUpdate) then
  begin
  Buffer := Cursor.CurrentRecordBuffer;
  Cursor.CurrentRecordBuffer := Cursor.EditRecordBuffer;
  end;
  try
    ReferencedCursor.SQLFilterExpression := TACRExpression.Create(ReferencedCursor.Session, nil);
    TACRExpression(ReferencedCursor.SQLFilterExpression).PrepareForeignKeyActionFilter(
      ReferencedCursor, Cursor, ConstraintDef, PrimaryIndex);
    if (not ReferencedCursor.InMemory) then
      TACRLocalCursor(ReferencedCursor).TableData.GetRecordCount
        (ReferencedCursor, False);
    TACRLocalCursor(ReferencedCursor).TableData.BuildCursorRecordBitmap
      (ReferencedCursor);
    Result := (TACRRecordBitmap(TACRLocalCursor(ReferencedCursor).RecordBitmap).GetRecordCount <= 0);
  finally
    if (ToUpdate) then
      Cursor.CurrentRecordBuffer := Buffer;
  end;
end; // CheckForeignKeyActionBuildSearchExpression


//------------------------------------------------------------------------------
// check field definitions for CreateTable
//------------------------------------------------------------------------------
procedure TACRTableData.CheckFieldDefinitions(FieldDefs: TACRFieldDefs);
var
	i, k: Integer;
	Name: WideString;
begin
if (FieldDefs.Count <= 0) then
	raise EACRException.Create(11429, ErrorLCreateTableNoFields, [FTableName]);
for i := 0 to FieldDefs.Count - 1 do
begin
if (FieldDefs.Items[i].Name = '') then
	raise EACRException.Create(11432, ErrorLCreateTableNoFieldName, [FTableName]);
Name := WideUpperCase(FieldDefs.Items[i].Name);
for k := 0 to FieldDefs.Count - 1 do
	if (k <> i) then
		if (WideUpperCase(FieldDefs.Items[k].Name) = Name) then
			raise EACRException.Create(11430, ErrorLCreateTableDuplicateFieldName,
				[FTableName, Name]);
end;
end; // CheckFieldDefinitions

//------------------------------------------------------------------------------
// check for duplicates in index definitions and for multiple primary keys for CreateTable
//------------------------------------------------------------------------------
procedure TACRTableData.CheckIndexDefinitions(IndexDefs: TACRIndexDefs);
var
	i, j, k: Integer;
	Name: WideString;
begin
j := 0;
for i := 0 to IndexDefs.Count - 1 do
begin
if (IndexDefs.Items[i].Name = '') then
	raise EACRException.Create(11433, ErrorLCreateTableNoIndexName, [FTableName]);
Name := WideUpperCase(IndexDefs.Items[i].Name);
if (IndexDefs.Items[i].ColumnCount <= 0) then
	raise EACRException.Create(11434, ErrorLCreateTableNoFieldsInIndex,
		[FTableName, Name]);
for k := 0 to IndexDefs.Count - 1 do
	if (k <> i) then
		if (WideUpperCase(IndexDefs.Items[k].Name) = Name) then
			raise EACRException.Create(11428, ErrorLCreateTableDuplicateIndexName,
				[FTableName, Name]);
if (IndexDefs.Items[i].Primary) then
	Inc(j);
end;
if (j > 1) then
	raise EACRException.Create(11427, ErrorLCreateTableMultiplePrimaryIndexes,
		[FTableName]);
end; // CheckPrimaryIndexDefinitions

//------------------------------------------------------------------------------
// check constraint names
//------------------------------------------------------------------------------
procedure TACRTableData.CheckConstraintDefinitions
	(ConstraintDefs: TACRConstraintDefs);
var
	i, k: Integer;
	Name: WideString;
begin
for i := 0 to ConstraintDefs.Count - 1 do
begin
Name := WideUpperCase(ConstraintDefs.Items[i].Name);
if (Name = '') then
	continue;
for k := 0 to ConstraintDefs.Count - 1 do
	if (k <> i) then
		if (WideUpperCase(ConstraintDefs.Items[k].Name) = Name) then
			raise EACRException.Create(11431,
				ErrorLCreateTableDuplicateConstraintName
					, [FTableName, Name]);
end;
end; // CheckConstraintDefinitions

//------------------------------------------------------------------------------
// create foreign key action
//------------------------------------------------------------------------------
function TACRTableData.CreateForeignKeyAction(Cursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKey; ReferencedTableName: WideString;
	ReferencedTableObjectID: TACRObjectID): TACRConstraintDefForeignKeyAction;
begin
Result := FConstraintManager.AddForeignKeyAction(ConstraintDef,
	ReferencedTableName, ReferencedTableObjectID);
if (Result <> nil) then
begin
UpdateTableMetadataState(ltoAddForeignKey);
end
else
	raise EACRException.Create(11875, ErrorLNilPointer);
end; // CreateForeignKeyAction

//------------------------------------------------------------------------------
// check foreign key definition
//------------------------------------------------------------------------------
procedure TACRTableData.CheckForeignKeyDefinition
	(ConstraintDef: TACRConstraintDefForeignKey; ReferencedCursor: TACRCursor;
	SelfReference: Boolean);
var
	FieldDefFK: TACRFieldDef;
	FieldDefIndex: TACRFieldDef;
	PrimaryIndex: TACRIndexDef;
	j, h: Integer;
begin
  // self reference support added in 4.97
if (SelfReference) then
begin
PrimaryIndex := FIndexManager.IndexDefs.FindPrimaryIndex;
end
else
begin
PrimaryIndex := ReferencedCursor.IndexDefs.FindPrimaryIndex;
end;
if (PrimaryIndex = nil) then
	raise EACRException.Create(11442,
		ErrorLCreateTableInvalidFKDefNoPrimaryIndex, [ConstraintDef.Name,
		FTableName, ConstraintDef.ReferencedTableName]);
if (PrimaryIndex.ColumnCount <> Length(ConstraintDef.Columns)) then
	raise EACRException.Create(11443,
		ErrorLCreateTableInvalidFKDefPrimaryIndexColumnCount, [ConstraintDef.Name,
		FTableName, ConstraintDef.ReferencedTableName]);
h := High(ConstraintDef.Columns);
for j := 0 to h do
begin
FieldDefFK := FFieldManager.FieldDefs.GetFieldDefByName
	(ConstraintDef.Columns[j].ColumnName);
if (FieldDefFK = nil) then
	raise EACRException.Create(11444,
		ErrorLCreateTableInvalidFKDefInvalidColumnName, [ConstraintDef.Name,
		FTableName, ConstraintDef.Columns[j].ColumnName]);
if (SelfReference) then
	FieldDefIndex := FFieldManager.FFieldDefs.GetFieldDefByName
		(PrimaryIndex.Columns[j].FieldName)
else
	FieldDefIndex := ReferencedCursor.FFieldDefs.GetFieldDefByName
		(PrimaryIndex.Columns[j].FieldName);
if (FieldDefIndex = nil) then
	raise EACRException.Create(11445,
		ErrorLCreateTableInvalidFKDefInvalidPrimaryIndexColumnName,
		[ConstraintDef.Name, FTableName, PrimaryIndex.Columns[j].FieldName,
		ConstraintDef.ReferencedTableName]);
if (GetCommonDataType(FieldDefFK.BaseFieldType, FieldDefIndex.BaseFieldType)
		= bftUnknown) or (not IsConvertableFieldType(FieldDefFK.AdvancedFieldType)
	) or (not IsConvertableFieldType(FieldDefIndex.AdvancedFieldType)) then
	raise EACRException.Create(11446, ErrorLCreateTableInvalidFKDefTypesMismatch,
		[ConstraintDef.Name, FTableName, ConstraintDef.Columns[j].ColumnName,
		PrimaryIndex.Columns[j].FieldName, ConstraintDef.ReferencedTableName]);
end;
end; // CheckForeignKeyDefinition

//------------------------------------------------------------------------------
// checks foreign key definitions and creates foreign key actions in master tables
//------------------------------------------------------------------------------
procedure TACRTableData.CheckForeignKeyDefinitionsAndCreateForeignKeyActions
	(Cursor: TACRCursor);
var
	i, j: Integer;
	ReferencedCursor: TACRLocalCursor;
	MasterTablesList: TList;
	ConstraintDef: TACRConstraintDefForeignKey;
	FKAction: TACRConstraintDefForeignKeyAction;
	bOK, bSelfReference: Boolean;
begin
bOK := False;
MasterTablesList := TList.Create;
try
	for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
		if (FConstraintManager.ConstraintDefs[i].ConstraintType = ctFK) then
		begin
		ConstraintDef := TACRConstraintDefForeignKey
			(FConstraintManager.ConstraintDefs[i]);
		if (WideUpperCase(FTableName) = WideUpperCase
				(ConstraintDef.ReferencedTableName)) then
		begin
          // self reference
		ReferencedCursor := TACRLocalCursor(Cursor);
          // fixed in 4.97
		bSelfReference := True;
		end
		else
		begin
		ReferencedCursor := nil;
		bSelfReference := False;
		for j := 0 to MasterTablesList.Count - 1 do
			if (WideUpperCase(TACRLocalCursor(MasterTablesList.Items[j]).TableName)
					= WideUpperCase(ConstraintDef.ReferencedTableName)) then
			begin
			ReferencedCursor := TACRLocalCursor(MasterTablesList.Items[j]);
			break;
			end;
		if (ReferencedCursor = nil) then
		begin
		ReferencedCursor := TACRLocalCursor.Create;
		try
			CheckForeignKeyOpenReferencedTable(ReferencedCursor, Cursor,
				ConstraintDef, True, False);
		except
			ReferencedCursor.Free;
			raise ;
		end;
		MasterTablesList.Add(ReferencedCursor);
		end;
		end;
		CheckForeignKeyDefinition(ConstraintDef, ReferencedCursor, bSelfReference);
		FKAction := ReferencedCursor.TableData.CreateForeignKeyAction
			(ReferencedCursor, ConstraintDef, FTableName, INVALID_OBJECT_ID);
		ConstraintDef.ReferencedFKName := FKAction.Name;
		ConstraintDef.ReferencedFKObjectID := FKAction.ObjectID;
		end;
	bOK := True;
finally
	for i := 0 to MasterTablesList.Count - 1 do
	begin
	try
		ReferencedCursor := TACRLocalCursor(MasterTablesList.Items[i]);
        // write metadata changes - added foreign key actions
		if (bOK) then
		begin
		ReferencedCursor.TableData.WriteTableMetadata
			(ReferencedCursor.Session.SessionID);
		ReferencedCursor.TableData.UpdateTableMetadataState(ltoAddForeignKey);
		ReferencedCursor.TableData.ApplyChanges
			(ReferencedCursor.TableData.TableState.TableState, dbstTableMetaData,
			ReferencedCursor.TableData.TableState.TableMetaDataState);
		end;
		CheckForeignKeyCloseReferencedTable(ReferencedCursor);
		ReferencedCursor.Free;
	except
		;
	end;
	end;
	MasterTablesList.Free;
end;
end; // CheckForeignKeyDefinitionsAndCreateForeignKeyActions

//------------------------------------------------------------------------------
// rename table in foreign keys
//------------------------------------------------------------------------------
procedure TACRTableData.RenameTableInForeignKeys(Cursor: TACRCursor;
	OldTableName: WideString; NewTableName: WideString);
var
	i, j: Integer;
	ReferencedCursor: TACRLocalCursor;
	MasterTablesList: TList;
	ConstraintDef: TACRConstraintDefForeignKeyAction;
begin
MasterTablesList := TList.Create;
try
	for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
		if (FConstraintManager.ConstraintDefs[i].ConstraintType = ctFK) or
			(FConstraintManager.ConstraintDefs[i].ConstraintType = ctFKAction) then
		begin
		ConstraintDef := TACRConstraintDefForeignKeyAction
			(FConstraintManager.ConstraintDefs[i]);
		if (WideUpperCase(OldTableName) <> WideUpperCase
				(ConstraintDef.ReferencedTableName)) then
		begin
		ReferencedCursor := nil;
		for j := 0 to MasterTablesList.Count - 1 do
			if (WideUpperCase(TACRLocalCursor(MasterTablesList.Items[j]).TableName)
					= WideUpperCase(ConstraintDef.ReferencedTableName)) then
			begin
			ReferencedCursor := TACRLocalCursor(MasterTablesList.Items[j]);
			break;
			end;
		if (ReferencedCursor = nil) then
		begin
		ReferencedCursor := TACRLocalCursor.Create;
		try
			CheckForeignKeyOpenReferencedTable(ReferencedCursor, Cursor,
				ConstraintDef, True, False);
		except
			ReferencedCursor.Free;
			raise ;
		end;
		MasterTablesList.Add(ReferencedCursor);
		end;
		end;
		end;
	for i := 0 to MasterTablesList.Count - 1 do
	begin
	ReferencedCursor := TACRLocalCursor(MasterTablesList.Items[i]);
	ReferencedCursor.TableData.RenameReferenceTableName(ReferencedCursor,
		OldTableName, NewTableName);
	end;
	RenameReferenceTableName(Cursor, OldTableName, NewTableName);
finally
	for i := 0 to MasterTablesList.Count - 1 do
	begin
	try
		ReferencedCursor := TACRLocalCursor(MasterTablesList.Items[i]);
		CheckForeignKeyCloseReferencedTable(ReferencedCursor);
		ReferencedCursor.Free;
	except
		;
	end;
	end;
	MasterTablesList.Free;
end;
end; // RenameTableInForeignKeys

//------------------------------------------------------------------------------
// update detail records for foreign key actions
//------------------------------------------------------------------------------
procedure TACRTableData.ExecuteForeignKeyActionsUpdateDetailRecords
	(ReferencedCursor: TACRCursor; Cursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKeyAction;
	Action: TACRConstraintForeignKeyAction);
var
	PrimaryIndex: TACRIndexDef;
	FieldNames: TACRWideStringList;
	values: array of TACRVariant;
	i, h, FieldNo: Integer;
	FieldDef: TACRFieldDef;
begin
if (Action = cfkaCascade) then
begin
PrimaryIndex := FIndexManager.IndexDefs.FindPrimaryIndex;
if (PrimaryIndex = nil) then
	raise EACRException.Create(11460, ErrorLForeignKeyNoPrimaryIndex,
		[ConstraintDef.ReferencedFKName, ReferencedCursor.TableName, FTableName]);
end;
h := High(ConstraintDef.Columns);
FieldNames := TACRWideStringList.Create;
SetLength(values, h + 1);
for i := 0 to h do
	values[i] := TACRVariant.Create;
try
	for i := 0 to h do
	begin
	FieldDef := ReferencedCursor.FFieldDefs.GetFieldDefByName
		(ConstraintDef.Columns[i].ColumnName);
	if (FieldDef = nil) then
		raise EACRException.Create(11458,
			ErrorLCreateTableInvalidFKDefInvalidColumnName, [ConstraintDef.Name,
			FTableName, ConstraintDef.Columns[i].ColumnName]);
	FieldNames.Add(FieldDef.Name);
	values[i].SetNull();
	if (Action = cfkaSetNull) then
		values[i].SetNull(FieldDef.BaseFieldType)
	else
		if (Action = cfkaSetDefault) then
			values[i].Assign(FieldDef.DefaultValue)
		else
			if (Action = cfkaCascade) then
			begin
			FieldNo := FFieldManager.FieldDefs.GetDefNumberByName
				(PrimaryIndex.Columns[i].FieldName);
			if (FieldNo < 0) then
				raise EACRException.Create(11461,
					ErrorLCreateTableInvalidFKDefInvalidColumnName, [ConstraintDef.Name,
					FTableName, PrimaryIndex.Columns[i].FieldName]);
			Cursor.GetFieldValue(values[i], FieldNo, True, False);
			end
			else
				raise EACRException.Create(11462, ErrorLForeignKeyInvalidAction,
					[Byte(Action), FTableName, ConstraintDef.ReferencedFKName,
					ConstraintDef.ReferencedTableName])
	end;
	ReferencedCursor.UpdateVisibleRecords(FieldNames, values,
		(Action = cfkaCascade));
finally
	for i := 0 to h do
		values[i].Free;
	SetLength(values, 0);
	FieldNames.Free;
end;
end; // ExecuteForeignKeyActionsUpdateDetailRecords

//------------------------------------------------------------------------------
// return true if current record in Cursor violates foreign key constraint
//------------------------------------------------------------------------------
function TACRTableData.IsForeignKeyConstraintFailed(Cursor: TACRCursor;
	ConstraintDef: TACRConstraintDefForeignKey): Boolean;
var
	ReferencedCursor: TACRCursor;
	SearchExpression: TACRExpression;
	Failed: Boolean;
begin
Result := not IsForeignKeyNullValuesOK(Cursor, ConstraintDef, Failed);
if (Failed) then
	Result := True
else
	if (Result) then
	begin
	Result := False;
	ReferencedCursor := TACRLocalCursor.Create;
	try
		try
			CheckForeignKeyOpenReferencedTable(ReferencedCursor, Cursor,
				ConstraintDef, False, True);
		except
			on E: Exception do
				raise EACRException.Create(11423,
					ErrorLForeignKeyCannotOpenReferencedTable, [ConstraintDef.Name,
					FTableName, E.Message]);
		end;
		try
			SearchExpression := CheckForeignKeyBuildSearchExpression(ReferencedCursor, Cursor, ConstraintDef);
			try
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // search record
		Result := not TACRLocalCursor(ReferencedCursor).TableData.FindRecord(
                    ReferencedCursor, True, True, nil, nil, False, True);
{$ELSE}
		Result := not TACRLocalCursor(ReferencedCursor).TableData.FindRecord(
                    ReferencedCursor, SearchExpression, nil, True, True,
                    nil, nil, False, True);
{$ENDIF}
			finally
				SearchExpression.Free;
			end;
		finally
			CheckForeignKeyCloseReferencedTable(ReferencedCursor);
		end;
	finally
		ReferencedCursor.Free;
	end;
	end; // if not null and not failed
end; // IsForeignKeyConstraintFailed


//------------------------------------------------------------------------------
// returns true of some fields of priumary key were updated
//------------------------------------------------------------------------------
function TACRTableData.IsPrimaryKeyUpdated(Cursor: TACRCursor): Boolean;
var
	PrimaryIndex: TACRIndexDef;
	i: Integer;
	Value, oldValue: TACRVariant;
begin
Result := False;
PrimaryIndex := FIndexManager.IndexDefs.FindPrimaryIndex;
if (PrimaryIndex <> nil) then
begin
Result := (FIndexManager.CompareRecordBuffersByIndex(PrimaryIndex.ObjectID,
		Cursor.CurrentRecordBuffer, Cursor.EditRecordBuffer, 0) <> 0);
end;
end; // IsPrimaryKeyUpdated

//------------------------------------------------------------------------------
// execute foreign key actions
//------------------------------------------------------------------------------
procedure TACRTableData.ExecuteForeignKeyActions(Cursor: TACRCursor;
	ToUpdate: Boolean // update or delete
	);
var
	i: Integer;
	ConstraintDef: TACRConstraintDefForeignKeyAction;
	Action: TACRConstraintForeignKeyAction;
	ReferencedCursor: TACRLocalCursor;
	NoRecords: Boolean;
begin
for i := 0 to FConstraintManager.ConstraintDefs.Count - 1 do
	if (FConstraintManager.ConstraintDefs.Items[i].ConstraintType = ctFKAction)
		then
	begin
	ConstraintDef := TACRConstraintDefForeignKeyAction
		(FConstraintManager.ConstraintDefs.Items[i]);
	if (ToUpdate) then
	begin
	Action := ConstraintDef.UpdateAction;
	if (Action <> cfkaNoAction) then
		if (not IsPrimaryKeyUpdated(Cursor)) then
			continue;
	end
	else
		Action := ConstraintDef.DeleteAction;
	if (Action = cfkaNoAction) then
		continue;
	ReferencedCursor := TACRLocalCursor.Create;
	try
		CheckForeignKeyOpenReferencedTable(ReferencedCursor, Cursor, ConstraintDef,
			False);
		try
			NoRecords := CheckForeignKeyActionBuildSearchExpression(ReferencedCursor,
				Cursor, ConstraintDef, ToUpdate);
			if (not NoRecords) then
				case Action of
				cfkaDefault:
				begin
				if (ToUpdate) then
					raise EACRException.Create(11454,
						ErrorLForeignKeyUpdateInMasterTableProhibited, [FTableName,
						ConstraintDef.ReferencedFKName, ConstraintDef.ReferencedTableName])
				else
					raise EACRException.Create(11455,
						ErrorLForeignKeyDeleteInMasterTableProhibited, [FTableName,
						ConstraintDef.ReferencedFKName, ConstraintDef.ReferencedTableName])
				end;
				cfkaCascade, cfkaSetNull, cfkaSetDefault:
				begin
				if (not ToUpdate) and (Action = cfkaCascade) then
					ReferencedCursor.DeleteVisibleRecords
				else
				begin
				ExecuteForeignKeyActionsUpdateDetailRecords(ReferencedCursor, Cursor,
					ConstraintDef, Action);
				end; // not cascade delete
				end
				else
					raise EACRException.Create(11456, ErrorLForeignKeyInvalidAction,
						[Byte(Action), FTableName, ConstraintDef.ReferencedFKName,
						ConstraintDef.ReferencedTableName])
				end; // case Action
		finally
			CheckForeignKeyCloseReferencedTable(ReferencedCursor);
		end;
	finally
		ReferencedCursor.Free;
	end;
	end; // FKAction
end; // ExecuteForeigKeyActions


//------------------------------------------------------------------------------
// build record bitmap for cursor
//------------------------------------------------------------------------------
procedure TACRTableData.BuildCursorRecordBitmap(Cursor: TACRCursor);
var
    Buffer:     TACRRecordBuffer;
    OldPos:     Pointer;
    OldBuffer:  TACRRecordBuffer;
begin
  TACRRecordBitmap(Cursor.RecordBitmap).Active := False;
  TACRRecordBitmap(Cursor.RecordBitmap).Indexed := Cursor.IsIndexApplied;
  TACRRecordBitmap(Cursor.RecordBitmap).PrepareBitmapForActivation;
  if (InternalGetRecordCount > 0) then
  begin
  OldBuffer := Cursor.CurrentRecordBuffer;
  OldPos := Cursor.SavePosition;
  Cursor.CurrentRecordBuffer := MemoryManager.AllocMem(GetRecordBufferSize);
  Cursor.FirstPosition := True;
  Cursor.LastPosition := False;
  try
    // build cursor bitmap
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    FindRecord(Cursor, True, True, nil, TACRRecordBitmap(Cursor.RecordBitmap), True, False);
{$ELSE}
    FindRecord(Cursor, nil, nil, True, True, nil, Cursor.RecordBitmap, True, False);
{$ENDIF}
        {
          // CURSOR DISTINCT IS NOT SUPPORTED
          // apply distinct
          if (Cursor.DistinctFieldCount > 0) then
          FIndexManager.OpenIndex(Cursor.IndexID).
          ApplyDistinctToRecordBitmap(Cursor.Session.SessionID,
          TACRRecordBitmap(Cursor.RecordBitmap));
        }
    TACRRecordBitmap(Cursor.RecordBitmap).Active := True;
  finally
    Buffer := Cursor.CurrentRecordBuffer;
    MemoryManager.FreeAndNilMem(Buffer);
    Cursor.CurrentRecordBuffer := OldBuffer;
    Cursor.RestorePosition(OldPos);
    Cursor.FreePosition(OldPos);
  end;
  end;
end; // BuildCursorRecordBitmap


(*
//------------------------------------------------------------------------------
  // return bitmap size
//------------------------------------------------------------------------------
  function TACRTableData.GetBitmapSize(SessionID: TACRSessionID): TACRRecordNo;
  begin
  Result := InternalGetRecordCount;
  end; // GetBitmapSize
*)

//------------------------------------------------------------------------------
// return true if record is in specified range
//------------------------------------------------------------------------------
function TACRTableData.IsRecordInRange(Cursor: TACRCursor): Boolean;
var
	res: Integer;
begin
Result := True;
if (Cursor.RangeStartBuffer <> nil) then
begin
res := FIndexManager.OpenIndex(Cursor.IndexID).CompareRecordBuffersByIndex
	(Cursor.CurrentRecordBuffer, Cursor.RangeStartBuffer,
	Cursor.RangeStartKeyFieldCount);
if (Cursor.RangeStartExclusive) then
	Result := (res > 0)
else
	Result := (res >= 0);
end;
if (Result) then
	if (Cursor.RangeEndBuffer <> nil) then
	begin
	res := FIndexManager.OpenIndex(Cursor.IndexID).CompareRecordBuffersByIndex
		(Cursor.CurrentRecordBuffer, Cursor.RangeEndBuffer,
		Cursor.RangeEndKeyFieldCount);
	if (Cursor.RangeEndExclusive) then
		Result := (res < 0)
	else
		Result := (res <= 0);
	end;
end; // IsRecordInRange


//------------------------------------------------------------------------------
// return true if record is visible (with applied filters, ranges, OnFilterRecord)
//------------------------------------------------------------------------------
{$IFDEF X64_ON}
type
  TxRecordVisblePrototype = function( FunctionAddress : pointer; aRecordBuffer : pointer; aDataSet : pointer ) : boolean; register;

function TACRTableData.IsRecordVisible(Cursor: TACRCursor): Boolean;
var
  aDataset: Pointer;
  aRecordBuffer: TACRRecordBuffer;
  FunctionAddress: Pointer;
  wFunction: TxRecordVisblePrototype absolute FunctionAddress;
begin
  Result := True;
  if (Result) then
    Result := IsRecordInRange(Cursor);
  if (Result) then
    if (Cursor.FilterExpression <> nil) then
    begin
      TACRExpression(Cursor.FilterExpression).AssignCursorBuffer
        (Cursor.CurrentRecordBuffer);
      Result := TACRExpression(Cursor.FilterExpression).GetResult;
    end;
  if (Result) then
    if (Cursor.SQLFilterExpression <> nil) then
    begin
      TACRExpression(Cursor.SQLFilterExpression).AssignCursorBuffer
        (Cursor.CurrentRecordBuffer);
      Result := TACRExpression(Cursor.SQLFilterExpression).GetResult;
    end;
  if (Result) then
    if (Pointer(Cursor.FilterRecord) <> nil) then
    begin
      aDataset := Cursor.Dataset;
      aRecordBuffer := Cursor.CurrentRecordBuffer;
          // Borland parameters transmitting bug fix
          // Get Function address from Virtual Method Table
      FunctionAddress := Pointer(PCardinal(Pointer(Cardinal(@Cursor.FilterRecord)))^);
      Result := wFunction( FunctionAddress, aRecordBuffer, aDataset );

//    asm
//      MOV    ECX, aDataset                //Dataset
//      MOV    EDX, aRecordBuffer           //Buffer
//      MOV    EAX, FunctionAddress         //Address of Function
//      CALL   EAX                          //Call Function
//      MOV    Result, AL                   //Save Result
//    end;
    end;
end; // IsRecordVisible
{$ELSE}
function TACRTableData.IsRecordVisible(Cursor: TACRCursor): Boolean;
var
	aDataset: Pointer;
	aRecordBuffer: TACRRecordBuffer;
	FunctionAddress: Pointer;
begin
Result := True;
if (Result) then
	Result := IsRecordInRange(Cursor);
if (Result) then
	if (Cursor.FilterExpression <> nil) then
	begin
	TACRExpression(Cursor.FilterExpression).AssignCursorBuffer
		(Cursor.CurrentRecordBuffer);
	Result := TACRExpression(Cursor.FilterExpression).GetResult;
	end;
if (Result) then
	if (Cursor.SQLFilterExpression <> nil) then
	begin
	TACRExpression(Cursor.SQLFilterExpression).AssignCursorBuffer
		(Cursor.CurrentRecordBuffer);
	Result := TACRExpression(Cursor.SQLFilterExpression).GetResult;
	end;
if (Result) then
	if (Pointer(Cursor.FilterRecord) <> nil) then
	begin
	aDataset := Cursor.Dataset;
	aRecordBuffer := Cursor.CurrentRecordBuffer;
      // Borland parameters transmitting bug fix
      // Get Function address from Virtual Method Table
	FunctionAddress := Pointer(PCardinal(Pointer(Cardinal(@Cursor.FilterRecord)))^);
    asm
      MOV    ECX, aDataset                //Dataset
      MOV    EDX, aRecordBuffer           //Buffer
      MOV    EAX, FunctionAddress         //Address of Function
      CALL   EAX                          //Call Function
      MOV    Result, AL                   //Save Result
    end;
	end;
end; // IsRecordVisible
{$ENDIF}


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// return true if conditions are incompatible
//------------------------------------------------------------------------------
procedure TACRTableData.MergeAndCheckSearchConditionsCompatibility(
                              Condition1:         TACRScanSearchCondition;
                              Condition2:         TACRScanSearchCondition;
                              out Incompatible:   Boolean;
                              out HaveBeenMerged: Boolean
                                                                  );
var
	ResMin:         Integer;
	IndexID:        TACRObjectID;
	MinFieldCount:  Integer;
	MaxFieldCount:  Integer;
  SwapBuf:        TACRRecordBuffer;
  SwapOwnBuf:     Boolean;

procedure SetFirstCondition;
begin
  HaveBeenMerged := True;
end; // SetFirstCondition

procedure SetSecondCondition;
begin
  HaveBeenMerged := True;
  Condition1.KeyFieldCount := Condition2.KeyFieldCount;
  SwapBuf := Condition1.KeyRecordBuffer;
  SwapOwnBuf := Condition1.OwnKeyBuffer;
  Condition1.KeyRecordBuffer := Condition2.KeyRecordBuffer;
  Condition1.OwnKeyBuffer := Condition2.OwnKeyBuffer;
  Condition2.KeyRecordBuffer := SwapBuf;
  Condition2.OwnKeyBuffer := SwapOwnBuf;
end; // SetMaxKFCCondition

procedure SetMinKFCCondition;
begin
  HaveBeenMerged := True;
  if (Condition1.KeyFieldCount = MinFieldCount) then
   SetFirstCondition
  else
   SetSecondCondition;
end; // SetMinKFCCondition

procedure SetMaxKFCCondition;
begin
  HaveBeenMerged := True;
  if (Condition1.KeyFieldCount = MaxFieldCount) then
   SetFirstCondition
  else
   SetSecondCondition;
end; // SetMaxKFCCondition

begin
  IndexID := Condition1.IndexID;
  MinFieldCount := Min(Condition1.KeyFieldCount, Condition2.KeyFieldCount);
  MaxFieldCount := Max(Condition1.KeyFieldCount, Condition2.KeyFieldCount);
  Incompatible := False;
  HaveBeenMerged := False;
    // check for distinct
  if (Condition1.KeyRecordBuffer = nil) or (Condition2.KeyRecordBuffer = nil) then
    Exit;
  ResMin := FIndexManager.OpenIndex(IndexID).CompareRecordBuffersByIndex(
              Condition1.KeyRecordBuffer, Condition2.KeyRecordBuffer, MinFieldCount);
  // check duplicates
  if (ResMin = 0) then
  begin
   if (Condition1.Condition = Condition2.Condition) then
   begin
    HaveBeenMerged := True;
    if (Condition2.KeyFieldCount > Condition1.KeyFieldCount) then
     SetSecondCondition;
    Exit;
   end;
  end;
  if (Condition1.Condition <> scNone) and (Condition2.Condition <> scNone) then
    case (Condition1.Condition) of
      scEqual:
        case (Condition2.Condition) of
          scEqual:
            begin
            if ((ResMin > 0) or (ResMin < 0)) then
              Incompatible := True
            else
              SetMaxKFCCondition;
            end;
          scGreater:
            begin
            if ((ResMin = 0) or (ResMin < 0)) then
              Incompatible := True
            else
              SetFirstCondition;
            end;
          scLower:
            begin
            if ((ResMin = 0) or (ResMin > 0)) then
              Incompatible := True
            else
              SetFirstCondition;
            end;
          scGreaterEqual:
            begin
            if (ResMin < 0) then
              Incompatible := True
            else
              if ((ResMin > 0) or
                  ((ResMin = 0) and (Condition1.KeyFieldCount = MaxFieldCount))) then
                SetFirstCondition; // otherwise not merge
            end;
          scLowerEqual:
            begin
              if (ResMin > 0) then
                Incompatible := True
              else
                if ((ResMin < 0) or
                    ((ResMin = 0) and (Condition1.KeyFieldCount = MaxFieldCount))) then
                  SetFirstCondition; // otherwise not merge
            end;
        end; // Condition2
      scGreater:
        case (Condition2.Condition) of
          scEqual:
            begin
              if ((ResMin = 0) or (ResMin > 0)) then
                Incompatible := True
              else
                SetSecondCondition;
            end;
          scGreater:
            begin
              if (ResMin > 0) then
                SetFirstCondition
              else
                if (ResMin < 0) then
                  SetSecondCondition
                else
                  SetMinKFCCondition;
            end;
          scLower:
            begin
              if ((ResMin > 0) or (ResMin = 0)) then
                Incompatible := True; // otherwise not merge
            end;
          scGreaterEqual:
            begin
              if ((ResMin = 0) or (ResMin > 0)) then
                SetFirstCondition
              else
                if (ResMin < 0) then
                  SetSecondCondition;
            end;
          scLowerEqual:
          begin
            if ((ResMin > 0) or
                ((ResMin = 0) and (Condition1.KeyFieldCount = MinFieldCount))) then
              Incompatible := True; // otherwise not merge
          end;
        end; // Condition2
      scLower:
        case (Condition2.Condition) of
          scEqual:
            begin
              if ((ResMin = 0) or (ResMin < 0)) then
                Incompatible := True
              else
                SetSecondCondition;
            end;
          scGreater:
            begin
              if ((ResMin < 0) or (ResMin = 0)) then
                Incompatible := True; // otherwise not merge
            end;
          scLower:
            begin
              if (ResMin < 0) then
                SetFirstCondition
              else
                if (ResMin > 0) then
                  SetSecondCondition
                else
                  SetMinKFCCondition;
            end;
          scGreaterEqual:
            begin
              if ((ResMin < 0) or
                  ((ResMin = 0) and (Condition1.KeyFieldCount = MinFieldCount))) then
                Incompatible := True; // otherwise not merge
            end;
          scLowerEqual:
            begin
              if ((ResMin < 0) or (ResMin = 0)) then
                SetFirstCondition
              else
                if (ResMin > 0) then
                  SetSecondCondition;
            end;
        end; // Condition2
      scGreaterEqual:
        case (Condition2.Condition) of
          scEqual:
            begin
              if (ResMin > 0) then
                Incompatible := True
              else
                if ((ResMin < 0) or ((ResMin = 0) and
                      (Condition2.KeyFieldCount = MaxFieldCount))) then
                  SetSecondCondition;
            end;
          scGreater:
            begin
              if (ResMin > 0) then
                SetFirstCondition
              else
                SetSecondCondition;
            end;
          scLower:
            begin
              if ((ResMin > 0) or ((ResMin = 0) and
                  (Condition2.KeyFieldCount = MinFieldCount))) then
                Incompatible := True; // otherwise not merge
            end;
          scGreaterEqual:
            begin
              if (ResMin > 0) then
                SetFirstCondition
              else
                if (ResMin < 0) then
                  SetSecondCondition
                else
                  SetMaxKFCCondition;
            end;
          scLowerEqual:
            begin
              if (ResMin > 0) then
                Incompatible := True // otherwise not merge
              else
              if ((ResMin = 0) and (MinFieldCount = MaxFieldCount)) then
              begin
                SetMaxKFCCondition;
                Condition1.Condition := scEqual;
              end;
            end;
        end; // Condition2
    scLowerEqual:
      case (Condition2.Condition) of
        scEqual:
          begin
            if (ResMin < 0) then
              Incompatible := True
            else
              if ((ResMin > 0) or ((ResMin = 0) and
                  (Condition2.KeyFieldCount = MaxFieldCount))) then
                SetSecondCondition; // otherwise not merge
          end;
        scGreater:
          begin
            if ((ResMin < 0) or ((ResMin = 0) and
                  (Condition2.KeyFieldCount = MinFieldCount))) then
              Incompatible := True; // otherwise not merge
          end;
        scLower:
          begin
            if (ResMin < 0) then
              SetFirstCondition
            else
            if (ResMin > 0) then
              SetSecondCondition;
          end;
        scGreaterEqual:
          begin
            if (ResMin < 0) then
              Incompatible := True // otherwise not merge
            else
            if ((ResMin = 0) and (MinFieldCount = MaxFieldCount)) then
            begin
              SetMaxKFCCondition;
              Condition1.Condition := scEqual;
            end;
          end;
        scLowerEqual:
          begin
            if (ResMin < 0) then
              SetFirstCondition
            else
            if (ResMin > 0) then
              SetSecondCondition
            else
              SetMaxKFCCondition;
          end;
      end; // Condition2
    end; // Condition1
end; // MergeAndCheckSearchConditionsCompatibility


procedure TACRTableData.OptimizeSearchConditions(
                    Conditions:                   TACRList;
                    out NonCompatibleConditions:  Boolean
                                                );
var
	IndexIDs:             TACRIntegerArray;
	IndexConditionsCount: TACRIntegerArray;
	i, j, k, n:           Integer;
	IndexID:              TACRObjectID;
	HaveBeenMerged:       Boolean;
	DoAppend:             Boolean;
  bDelete:              Boolean;
begin
  IndexIDs := TACRIntegerArray.Create(0, Conditions.Count, Conditions.Count);
  IndexConditionsCount := TACRIntegerArray.Create(0, Conditions.Count, Conditions.Count);
  NonCompatibleConditions := False;
  try
    for i := 0 to Conditions.Count - 1 do
      if (TACRScanSearchCondition(Conditions.Items[i]).IndexID <> INVALID_OBJECT_ID) then
      begin
        IndexID := TACRScanSearchCondition(Conditions.Items[i]).IndexID;
        k := IndexIDs.IndexOf(Integer(IndexID));
        if (k < 0) then
        begin
          IndexIDs.Append(Integer(IndexID));
          IndexConditionsCount.Append(1);
        end
        else
        begin
          // increment number of conditions
          IndexConditionsCount.Items[k] := IndexConditionsCount.Items[k] + 1;
        end;
      end
      else
      begin
        NonCompatibleConditions := TACRExpression(TACRScanSearchCondition(
              Conditions.Items[i]).Expression).IsIncompatible;
        if (NonCompatibleConditions) then
         Exit;
      end;
    for i := 0 to IndexIDs.ItemCount - 1 do
    begin
      IndexID := TACRObjectID(IndexIDs.Items[i]);
      n := IndexConditionsCount.Items[i];
      if (n > 1) then
      begin
        // try to merge conditions
        // find first condition
        j := 0;
        while j < Conditions.Count do
        if (TACRScanSearchCondition(Conditions.Items[j]).IndexID = IndexID) then
          begin
           break;
          end
        else
          Inc(j);
        k := j+1;
        while k < Conditions.Count do
        if (TACRScanSearchCondition(Conditions.Items[j]).IndexID = IndexID) then
          begin
           MergeAndCheckSearchConditionsCompatibility(
                                                      Conditions[j],
                                                      Conditions[k],
                                                      NonCompatibleConditions,
                                                      HaveBeenMerged
                                                     );
           if (NonCompatibleConditions) then
            Exit;
           if (HaveBeenMerged) then
           begin
            TACRScanSearchCondition(Conditions[k]).Free;
            Conditions.Delete(k);
           end;
          end
        else
          Inc(k);
      end;
    end; // try to merge index conditions
  finally
    IndexIDs.Free;
    IndexConditionsCount.Free;
  end;
end; // OptimizeSearchConditions


{$ELSE}
//------------------------------------------------------------------------------
// returns true if conditions are equal
//------------------------------------------------------------------------------
function TACRTableData.IsEqualConditions(
                                          Condition1: TACRScanSearchCondition;
                                          Condition2: TACRScanSearchCondition
                                         ): Boolean;
begin
  Result := False;
  if (Condition1.IndexID = Condition2.IndexID) then
    if ((Condition1.Condition = Condition2.Condition) and
        (Condition1.Condition <> scNone)) then
      if (Condition1.KeyFieldCount = Condition2.KeyFieldCount) then
      begin
        Result := (FIndexManager.OpenIndex(Condition1.IndexID).CompareRecordBuffersByIndex(
            Condition1.KeyRecordBuffer,
            Condition2.KeyRecordBuffer, Condition1.KeyFieldCount) = 0);
      end;
end; // IsEqualConditions


//------------------------------------------------------------------------------
// removes duplicate conditions
//------------------------------------------------------------------------------
procedure TACRTableData.RemoveDuplicateConditions(
                                        Conditions: TACRScanSearchConditionArray
                                                 );
var
	i, j:     Integer;
	ToRemove: Boolean;
begin
  i := 0;
  while (i < Conditions.Count) and (Conditions.Count > 1) do
  begin
    ToRemove := False;
    for j := 0 to Conditions.Count - 1 do
      if (j <> i) then
        if (IsEqualConditions(Conditions.Items[i], Conditions.Items[j])) then
          ToRemove := True;
    if (ToRemove) then
      Conditions.Delete(i)
    else
      Inc(i);
  end;
end; // RemoveDuplicateConditions


//------------------------------------------------------------------------------
// return true if conditions are incompatible
//------------------------------------------------------------------------------
procedure TACRTableData.MergeAndCheckSearchConditionsCompatibility(
                              Condition1:         TACRScanSearchCondition;
                              Condition2:         TACRScanSearchCondition;
                              out Incompatible:   Boolean;
                              out HaveBeenMerged: Boolean
                                                                  );
var
	ResMin:         Integer;
	IndexID:        TACRObjectID;
	MinFieldCount:  Integer;
	MaxFieldCount:  Integer;
	NewCondition:   TACRScanSearchCondition;

procedure SetFirstCondition;
begin
  HaveBeenMerged := True;
  NewCondition.KeyFieldCount := Condition1.KeyFieldCount;
  NewCondition.KeyRecordBuffer := Condition1.KeyRecordBuffer;
  NewCondition.Condition := Condition1.Condition;
end; // SetFirstCondition

procedure SetSecondCondition;
begin
  HaveBeenMerged := True;
  NewCondition.KeyFieldCount := Condition2.KeyFieldCount;
  NewCondition.KeyRecordBuffer := Condition2.KeyRecordBuffer;
  NewCondition.Condition := Condition2.Condition;
end; // SetMaxKFCCondition

procedure SetMinKFCCondition;
begin
  HaveBeenMerged := True;
  NewCondition.KeyFieldCount := MinFieldCount;
  if (Condition1.KeyFieldCount = MinFieldCount) then
  begin
    NewCondition.KeyRecordBuffer := Condition1.KeyRecordBuffer;
    NewCondition.Condition := Condition1.Condition;
  end
  else
  begin
    NewCondition.KeyRecordBuffer := Condition2.KeyRecordBuffer;
    NewCondition.Condition := Condition2.Condition;
  end
end; // SetMinKFCCondition

procedure SetMaxKFCCondition;
begin
  HaveBeenMerged := True;
  NewCondition.KeyFieldCount := MaxFieldCount;
  if (Condition1.KeyFieldCount = MaxFieldCount) then
  begin
    NewCondition.KeyRecordBuffer := Condition1.KeyRecordBuffer;
    NewCondition.Condition := Condition1.Condition;
  end
  else
  begin
    NewCondition.KeyRecordBuffer := Condition2.KeyRecordBuffer;
    NewCondition.Condition := Condition2.Condition;
  end
end; // SetMaxKFCCondition

begin
  IndexID := Condition1.IndexID;
  MinFieldCount := Min(Condition1.KeyFieldCount, Condition2.KeyFieldCount);
  MaxFieldCount := Max(Condition1.KeyFieldCount, Condition2.KeyFieldCount);
  Incompatible := False;
  HaveBeenMerged := False;
    // check for distinct
  if (Condition1.KeyRecordBuffer = nil) or (Condition2.KeyRecordBuffer = nil) then
    Exit;
  ResMin := FIndexManager.OpenIndex(IndexID).CompareRecordBuffersByIndex(
              Condition1.KeyRecordBuffer, Condition2.KeyRecordBuffer, MinFieldCount);
  NewCondition := TACRScanSearchCondition.Create;
  try
    NewCondition.IndexID := IndexID;
    NewCondition.Expression := nil;
    if (Condition1.Condition <> scNone) and (Condition2.Condition <> scNone) then
      case (Condition1.Condition) of
        scEqual:
          case (Condition2.Condition) of
            scEqual:
              begin
              if ((ResMin > 0) or (ResMin < 0)) then
                Incompatible := True
              else
                SetMaxKFCCondition;
              end;
            scGreater:
              begin
              if ((ResMin = 0) or (ResMin < 0)) then
                Incompatible := True
              else
                SetFirstCondition;
              end;
            scLower:
              begin
              if ((ResMin = 0) or (ResMin > 0)) then
                Incompatible := True
              else
                SetFirstCondition;
              end;
            scGreaterEqual:
              begin
              if (ResMin < 0) then
                Incompatible := True
              else
                if ((ResMin > 0) or
                    ((ResMin = 0) and (Condition1.KeyFieldCount = MaxFieldCount))) then
                  SetFirstCondition; // otherwise not merge
              end;
            scLowerEqual:
              begin
                if (ResMin > 0) then
                  Incompatible := True
                else
                  if ((ResMin < 0) or
                      ((ResMin = 0) and (Condition1.KeyFieldCount = MaxFieldCount))) then
                    SetFirstCondition; // otherwise not merge
              end;
          end; // Condition2
        scGreater:
          case (Condition2.Condition) of
            scEqual:
              begin
                if ((ResMin = 0) or (ResMin > 0)) then
                  Incompatible := True
                else
                  SetSecondCondition;
              end;
            scGreater:
              begin
                if (ResMin > 0) then
                  SetFirstCondition
                else
                  if (ResMin < 0) then
                    SetSecondCondition
                  else
                    SetMinKFCCondition;
              end;
            scLower:
              begin
                if ((ResMin > 0) or (ResMin = 0)) then
                  Incompatible := True; // otherwise not merge
              end;
            scGreaterEqual:
              begin
                if ((ResMin = 0) or (ResMin > 0)) then
                  SetFirstCondition
                else
                  if (ResMin < 0) then
                    SetSecondCondition;
              end;
            scLowerEqual:
            begin
              if ((ResMin > 0) or
                  ((ResMin = 0) and (Condition1.KeyFieldCount = MinFieldCount))) then
                Incompatible := True; // otherwise not merge
            end;
          end; // Condition2
        scLower:
          case (Condition2.Condition) of
            scEqual:
              begin
                if ((ResMin = 0) or (ResMin < 0)) then
                  Incompatible := True
                else
                  SetSecondCondition;
              end;
            scGreater:
              begin
                if ((ResMin < 0) or (ResMin = 0)) then
                  Incompatible := True; // otherwise not merge
              end;
            scLower:
              begin
                if (ResMin < 0) then
                  SetFirstCondition
                else
                  if (ResMin > 0) then
                    SetSecondCondition
                  else
                    SetMinKFCCondition;
              end;
            scGreaterEqual:
              begin
                if ((ResMin < 0) or
                    ((ResMin = 0) and (Condition1.KeyFieldCount = MinFieldCount))) then
                  Incompatible := True; // otherwise not merge
              end;
            scLowerEqual:
              begin
                if ((ResMin < 0) or (ResMin = 0)) then
                  SetFirstCondition
                else
                  if (ResMin > 0) then
                    SetSecondCondition;
              end;
          end; // Condition2
        scGreaterEqual:
          case (Condition2.Condition) of
            scEqual:
              begin
                if (ResMin > 0) then
                  Incompatible := True
                else
                  if ((ResMin < 0) or ((ResMin = 0) and
                        (Condition2.KeyFieldCount = MaxFieldCount))) then
                    SetSecondCondition;
              end;
            scGreater:
              begin
                if (ResMin > 0) then
                  SetFirstCondition
                else
                  SetSecondCondition;
              end;
            scLower:
              begin
                if ((ResMin > 0) or ((ResMin = 0) and
                    (Condition2.KeyFieldCount = MinFieldCount))) then
                  Incompatible := True; // otherwise not merge
              end;
            scGreaterEqual:
              begin
                if (ResMin > 0) then
                  SetFirstCondition
                else
                  if (ResMin < 0) then
                    SetSecondCondition
                  else
                    SetMaxKFCCondition;
              end;
            scLowerEqual:
              begin
                if (ResMin > 0) then
                  Incompatible := True // otherwise not merge
                else
                if ((ResMin = 0) and (MinFieldCount = MaxFieldCount)) then
                begin
                  SetMaxKFCCondition;
                  NewCondition.Condition := scEqual;
                end;
              end;
          end; // Condition2
      scLowerEqual:
        case (Condition2.Condition) of
          scEqual:
            begin
              if (ResMin < 0) then
                Incompatible := True
              else
                if ((ResMin > 0) or ((ResMin = 0) and
                    (Condition2.KeyFieldCount = MaxFieldCount))) then
                  SetSecondCondition; // otherwise not merge
            end;
          scGreater:
            begin
              if ((ResMin < 0) or ((ResMin = 0) and
                    (Condition2.KeyFieldCount = MinFieldCount))) then
                Incompatible := True; // otherwise not merge
            end;
          scLower:
            begin
              if (ResMin < 0) then
                SetFirstCondition
              else
              if (ResMin > 0) then
                SetSecondCondition;
            end;
          scGreaterEqual:
            begin
              if (ResMin < 0) then
                Incompatible := True // otherwise not merge
              else
              if ((ResMin = 0) and (MinFieldCount = MaxFieldCount)) then
              begin
                SetMaxKFCCondition;
                NewCondition.Condition := scEqual;
              end;
            end;
          scLowerEqual:
            begin
              if (ResMin < 0) then
                SetFirstCondition
              else
              if (ResMin > 0) then
                SetSecondCondition
              else
                SetMaxKFCCondition;
            end;
        end; // Condition2
      end; // Condition1
    if (HaveBeenMerged) then
    begin
      Condition1.Assign(NewCondition);
    end;
  finally
    NewCondition.Free;
  end;
end; // MergeAndCheckSearchConditionsCompatibility


//------------------------------------------------------------------------------
// sorts Conditions array and removes unnecessary conditions
//------------------------------------------------------------------------------
procedure TACRTableData.OptimizeSearchConditions(
                    var Conditions:               TACRScanSearchConditionArray;
                    out NonCompatibleConditions:  Boolean
                                                );
var
	IndexIDs:         TACRIntegerArray;
	i, j, k:          Integer;
	IndexID:          TACRObjectID;
	NewConditions:    TACRScanSearchConditionArray;
	HaveBeenMerged:   Boolean;
	DoAppend:         Boolean;
begin
  IndexIDs := TACRIntegerArray.Create(0, Conditions.Count, Conditions.Count);
  NonCompatibleConditions := False;
  NewConditions := TACRScanSearchConditionArray.Create;
  try
    for i := 0 to Conditions.Count - 1 do
      if (Conditions.Items[i].Expression = nil) then
      begin
        IndexID := Conditions.Items[i].IndexID;
        if (not IndexIDs.IsValueExists(IndexID)) then
          IndexIDs.Append(IndexID);
      end
      else
        NonCompatibleConditions := TACRExpression(Conditions.Items[i].Expression).IsIncompatible;
    for i := 0 to IndexIDs.ItemCount - 1 do
      if (NonCompatibleConditions) then
        break
      else
      begin
      IndexID := IndexIDs.Items[i];
      for k := 0 to Conditions.Count - 1 do
        if (NonCompatibleConditions) then
          break
        else
          if (Conditions.Items[k].Expression = nil) then
            if (Conditions.Items[k].IndexID = IndexID) then
            begin
            DoAppend := True;
            for j := 0 to NewConditions.Count - 1 do
              if (NewConditions.Items[j].IndexID = IndexID) then
              begin
              MergeAndCheckSearchConditionsCompatibility(NewConditions.Items[j],
                Conditions.Items[k], NonCompatibleConditions, HaveBeenMerged);
              if (NonCompatibleConditions) then
                break;
              if (HaveBeenMerged) then
                DoAppend := False;
              end; // j
            if (DoAppend) then
              NewConditions.AddCondition(Conditions.Items[k]);
            end; // k condition with current index
      end; // i
    if (not NonCompatibleConditions) then
      RemoveDuplicateConditions(NewConditions);

    if (not NonCompatibleConditions) then
      for k := 0 to Conditions.Count - 1 do
        if (Conditions.Items[k].Expression <> nil) then
          NewConditions.AddCondition(Conditions.Items[k]);
  finally
    IndexIDs.Free;
    if (NonCompatibleConditions) then
      NewConditions.Free
    else
    begin
    Conditions.Free;
    Conditions := NewConditions;
    end;
  end;
end; // OptimizeSearchConditions


//------------------------------------------------------------------------------
// prepare conditions array
//------------------------------------------------------------------------------
procedure TACRTableData.PrepareConditions(
                    Cursor:           TACRCursor;
			              Conditions:       TACRScanSearchConditionArray;
			              KeyCondition:     TACRScanSearchCondition;
                    SearchExpression: TACRExpression;
			              GoForward:        Boolean
                                         );
var
    RangeCondition: TACRScanSearchCondition;
begin
  RangeCondition := TACRScanSearchCondition.Create;
  try
    if (KeyCondition <> nil) then
      Conditions.AddCondition(KeyCondition);
    if (SearchExpression <> nil) then
      Conditions.AddExpression(SearchExpression);
    if (Cursor.FilterExpression <> nil) then
      Conditions.AddExpression(Cursor.FilterExpression);
    if (Cursor.SQLFilterExpression <> nil) then
      Conditions.AddExpression(Cursor.SQLFilterExpression);
    if (Cursor.IsRangeApplied) then
    begin
      if (Cursor.RangeStartBuffer <> nil) then
      begin
        RangeCondition.KeyRecordBuffer := Cursor.RangeStartBuffer;
        RangeCondition.KeyFieldCount := Cursor.RangeStartKeyFieldCount;
        if (Cursor.RangeStartExclusive) then
          RangeCondition.Condition := scGreater
        else
          RangeCondition.Condition := scGreaterEqual;
        RangeCondition.IndexID := Cursor.IndexID;
        RangeCondition.Expression := nil;
        Conditions.AddCondition(RangeCondition);
      end;
      if (Cursor.RangeEndBuffer <> nil) then
      begin
        RangeCondition.KeyRecordBuffer := Cursor.RangeEndBuffer;
        RangeCondition.KeyFieldCount := Cursor.RangeEndKeyFieldCount;
        if (Cursor.RangeEndExclusive) then
          RangeCondition.Condition := scLower
        else
          RangeCondition.Condition := scLowerEqual;
        RangeCondition.IndexID := Cursor.IndexID;
        RangeCondition.Expression := nil;
        Conditions.AddCondition(RangeCondition);
      end;
    end;
  finally
    RangeCondition.Free;
  end;
end; // PrepareConditions
{$ENDIF}


//------------------------------------------------------------------------------
// try to find the best scan condition with min range record count
//------------------------------------------------------------------------------
function TACRTableData.ChooseScanConditionsWithMinRangeRecordCount(
            SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
			      CurrentIndexID:         TACRObjectID;
            CurrentRecordID:        TACRRecordID;
			      var ScanConditionNo:    Integer;
            var ScanEndConditionNo: Integer
              ): Boolean;
var
    i:                          Integer;
    StartConditionNo:           Integer;
    EndConditionNo:             Integer;
    ScanConditionRecordCount:   TACRRecordNo;
    Index:                      TACRIndex;
    ScanIndexRecCount:          TACRRecordNo;
    ScanNoCondRecCount:         TACRRecordNo;
    CurrentRecordCount:         TACRRecordNo;
    TableRecordCount:           TACRRecordNo;
begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time8);
{$ENDIF}
  // scan without condition
  ScanConditionNo := INVALID_ID4;
  ScanConditionRecordCount := InternalGetRecordCount;
  CurrentRecordCount := ScanConditionRecordCount;
  // index scan
  i := 0;
  while (i < Conditions.Count) do
  begin
    if (TACRScanSearchCondition(Conditions.Items[i]).Expression = nil) then
    begin
      StartConditionNo := i;
      if (i < Conditions.Count - 1) then
        if (TACRScanSearchCondition(Conditions.Items[i]).IndexID =
            TACRScanSearchCondition(Conditions.Items[i + 1]).IndexID) then
          Inc(i);
      EndConditionNo := i;
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaIncCounter(counter9);
aaStartTime(time9);
{$ENDIF}
      Index := FIndexManager.OpenIndex(TACRScanSearchCondition(Conditions.Items[i]).IndexID);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time9);
{$ENDIF}
      if (Index = nil) then
        raise EACRException.Create(20058, ErrorANilPointer);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time10);
{$ENDIF}
      ScanIndexRecCount := Index.GetApproxRangeRecordCount(SessionID,
        CurrentRecordCount, Conditions.Items[StartConditionNo],
        Conditions.Items[EndConditionNo]);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time10);
{$ENDIF}
      if (ScanIndexRecCount < ScanConditionRecordCount) then
      begin
        ScanConditionNo := StartConditionNo;
        if (StartConditionNo <> EndConditionNo) then
          ScanEndConditionNo := EndConditionNo
        else
          ScanEndConditionNo := INVALID_ID4;
        ScanConditionRecordCount := ScanIndexRecCount;
      end;
    end;
    Inc(i);
  end;
  // compare best conditional scan with with non-conditional scan
  if (ScanConditionNo <> INVALID_OBJECT_ID) then
  begin
    if (CurrentIndexID = INVALID_OBJECT_ID) then
    begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time11);
{$ENDIF}
      TableRecordCount := FRecordManager.GetApproximateRecNo(CurrentRecordID, SessionID);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time11);
{$ENDIF}
      ScanNoCondRecCount := (CurrentRecordCount - TableRecordCount) div 5;
    end
    else
    begin
      ScanNoCondRecCount := CurrentRecordCount;
    end;
    if (ScanNoCondRecCount < ScanConditionRecordCount * ScanConditionRecordCount) then
    begin
      ScanConditionNo := INVALID_OBJECT_ID;
      ScanEndConditionNo := INVALID_OBJECT_ID;
    end;
  end;
  Result := (ScanConditionNo <> INVALID_OBJECT_ID);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
if (Result) then aaIncCounter(counter8);
aaStopTime(time8);
{$ENDIF}
end; // ChooseScanConditionsWithMinRangeRecordCount


//------------------------------------------------------------------------------
// if index is defined as unique or contain unique field
//------------------------------------------------------------------------------
function TACRTableData.IsIndexUnique(IndexID: TACRObjectID): Boolean;
var
	IndexDef: TACRIndexDef;
	FieldDef: TACRFieldDef;
begin
  IndexDef := TACRIndexDef(FIndexManager.IndexDefs.GetDefByObjectID(IndexID));
  Result := IndexDef.Unique;
  if (not Result) then
  begin
    FieldDef := FFieldManager.FieldDefs.GetFieldDefByName(IndexDef.Columns[0].FieldName);
    if (IsAutoincFieldType(FieldDef.AdvancedFieldType)) then
      Result := True;
  end;
end; // IsIndexUnique


//------------------------------------------------------------------------------
// try to find the best scan condition using heuristics
//------------------------------------------------------------------------------
function TACRTableData.ChooseScanConditionsByHeuristsics(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
        CurrentIndexID:         TACRObjectID;
			  var ScanConditionNo:    Integer;
        var ScanEndConditionNo: Integer
        ): Boolean;
var
	i,NumIndexConditions: Integer;
	Found:                Boolean;
	FoundNo:              Integer;
  LastIndexConditionNo: Integer;
begin
  FoundNo := INVALID_ID4;
  ScanConditionNo := INVALID_ID4;
  ScanEndConditionNo := INVALID_ID4;
  Result := False;
  if (Conditions.Count > 0) then
  begin
    // any condition '=' for unique index?
    NumIndexConditions := 0;
    for i := 0 to Conditions.Count - 1 do
    begin
      if ((TACRScanSearchCondition(Conditions.Items[i]).Expression = nil) and
          (TACRScanSearchCondition(Conditions.Items[i]).IndexID <> INVALID_ID4) and
          (TACRScanSearchCondition(Conditions.Items[i]).Condition = scEqual)) then
      begin
        Inc(NumIndexConditions);
        LastIndexConditionNo := i;
        if IsIndexUnique(TACRScanSearchCondition(Conditions.Items[i]).IndexID) then
        begin
          ScanConditionNo := i;
          Result := True;
          break;
        end;
      end;
    end;
  // check for single condition with current index
  if (NumIndexConditions = 1) then
  begin
   ScanConditionNo := LastIndexConditionNo;
   Result := True;
  end
  else
  if (not Result) then
  begin
    Found := False;
    for i := 0 to Conditions.Count - 1 do
      if (TACRScanSearchCondition(Conditions.Items[i]).Expression = nil) then
      begin
        if (TACRScanSearchCondition(Conditions.Items[i]).IndexID = CurrentIndexID) then
        begin
          if (not Found) then
          begin
            Found := True;
            FoundNo := i;
          end
          else
          begin
            Found := False;
            break;
          end;
        end
        else
        begin
          Found := False;
          break;
        end;
      end;
      if (Found) then
      begin
        ScanConditionNo := FoundNo;
        Result := True;
      end;
    end;
  end;
end; // ChooseScanConditionsByHeuristsics


//------------------------------------------------------------------------------
// if any index exists in conditions without expression will use it
//------------------------------------------------------------------------------
function TACRTableData.ChooseScanConditionsByAnyIndex(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
        CurrentIndexID:         TACRObjectID;
			  var ScanConditionNo:    Integer;
        var ScanEndConditionNo: Integer
        ): Boolean;
var	i: Integer;
begin
  ScanConditionNo := INVALID_ID4;
  ScanEndConditionNo := INVALID_ID4;
  Result := False;
  if (Conditions.Count > 0) then
  begin
  for i := 0 to Conditions.Count - 1 do
    if (TACRScanSearchCondition(Conditions.Items[i]).Expression = nil) and
       (TACRScanSearchCondition(Conditions.Items[i]).IndexID <> INVALID_OBJECT_ID) then
    begin
      ScanConditionNo := i;
      Result := True;
      break;
    end;
  end;
end; // ChooseScanConditionsByAnyIndex


//------------------------------------------------------------------------------
// try to find the best scan condition
//------------------------------------------------------------------------------
procedure TACRTableData.ChooseScanConditions(
                                    SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                                    CurrentIndexID:         TACRObjectID;
			                              CurrentRecordID:        TACRRecordID;
                                    GoForward:              Boolean;
			                              var ScanConditionNo:    Integer;
                                    var ScanEndConditionNo: Integer
                                  );
var
    StartConditionNo:   Integer;
    EndConditionNo:     Integer;
    Index:              TACRIndex;
    bOK:                Boolean;
    CompareIndexCond:   Integer;
begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
aaStartTime(time2);
{$ENDIF}
  bOK := ChooseScanConditionsByHeuristsics(Conditions, CurrentIndexID,
    ScanConditionNo, ScanEndConditionNo);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time2);
aaStartTime(time3);
{$ENDIF}
  if (not bOK) then
    bOK := ChooseScanConditionsWithMinRangeRecordCount(SessionID, Conditions,
      CurrentIndexID, CurrentRecordID, ScanConditionNo, ScanEndConditionNo);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time3);
aaStartTime(time4);
{$ENDIF}
  if (not bOK) then
    bOK := ChooseScanConditionsByAnyIndex(Conditions, CurrentIndexID,
      ScanConditionNo, ScanEndConditionNo);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time4);
aaStartTime(time5);
{$ENDIF}
  if (bOK) then
  begin
      // need to swap ScanEnd and Scan conditions?
    if (ScanEndConditionNo <> INVALID_ID4) then
    begin
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
      Index := FIndexManager.OpenIndex(TACRScanSearchCondition(Conditions.Items[ScanConditionNo]).IndexID);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time6);
{$ENDIF}
      if (Index = nil) then
        raise EACRException.Create(20059, ErrorANilPointer);
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStartTime(time7);
{$ENDIF}
      CompareIndexCond := Index.CompareConditions(TACRScanSearchCondition(Conditions.Items[ScanConditionNo]),
                                                  TACRScanSearchCondition(Conditions.Items[ScanEndConditionNo]));
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time7);
{$ENDIF}
      if (CompareIndexCond < 0) then
      begin
        StartConditionNo := ScanConditionNo;
        EndConditionNo := ScanEndConditionNo;
      end
      else
      begin
        StartConditionNo := ScanEndConditionNo;
        EndConditionNo := ScanConditionNo;
      end;
      if (GoForward) then
      begin
        ScanConditionNo := StartConditionNo;
        ScanEndConditionNo := EndConditionNo;
      end
      else
      begin
        ScanConditionNo := EndConditionNo;
        ScanEndConditionNo := StartConditionNo;
      end;
    end;
  end; // MinRange
{$IFDEF DEBUG_TACRTableData_ChooseScanConditions_TIME}
aaStopTime(time5);
aaStopTime(time1);
{$ENDIF}
  {
    aaWriteToLog('< TACRTableData.ChooseScanConditions. StartConditionNo = '+IntToStr(StartConditionNo)+#13#10+'EndConditionNo = '+IntToStr(EndConditionNo));
    aaWriteToLog('Count = '+IntToStr(Conditions.Count));
    if (ScanConditionNo <> INVALID_ID4) then
    begin
    aaWriteToLog('Condition: Key Fields Count = '+IntToStr(Conditions.Items[ScanConditionNo].KeyFieldCount));
    aaWriteToLog('Condition: IndexID = '+IntToStr(Conditions.Items[ScanConditionNo].IndexID));
    aaWriteToLog('Condition: Expression = '+IntToHex(Integer(Conditions.Items[ScanConditionNo].Expression),8));
    end;
    if (ScanEndConditionNo <> INVALID_ID4) then
    begin
    aaWriteToLog('EndCondition: Key Fields Count = '+IntToStr(Conditions.Items[EndConditionNo].KeyFieldCount));
    aaWriteToLog('EndCondition: IndexID = '+IntToStr(Conditions.Items[EndConditionNo].IndexID));
    aaWriteToLog('EndCondition: Expression = '+IntToHex(Integer(Conditions.Items[EndConditionNo].Expression),8));
    end;
  }
end; // ChooseScanConditions


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// return true if record was found and is visible by cursor
// prepares params for FindRecordByScan and calls it
//------------------------------------------------------------------------------
function TACRTableData.FindRecord(
                        Cursor:                       TACRCursor;
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                   ): Boolean;
var
    Condition:                          TACRScanSearchCondition;
    ScanConditionNo,ScanConditionEndNo: Integer;
    Expression:                         TACRExpression;
begin
{$IFDEF DEBUG_TRACE_TACRTableData_FindRecord}

try
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaIncCounter(counter12);
aaStartTime(time12);
try
{$ENDIF}
  if (TACRLocalCursor(Cursor).SearchOperation = lsoLocate) then
  begin
   Result := FindRecordByScan(
              Cursor.Session.SessionID,
              TACRLocalCursor(Cursor).SearchCache.Conditions,
              TACRLocalCursor(Cursor).SearchCache.LastLocateCondition^.ScanConditionNo,
              TACRLocalCursor(Cursor).SearchCache.LastLocateCondition^.ScanEndConditionNo,
              Cursor.IndexID,
              Cursor.FilterRecord,
              Cursor.Dataset,
              Cursor.CurrentRecordID,
              Restart,
              GoForward,
              ResultRecordID,
              RecordBitmap,
              InternalCall,
              StopAtFirstFoundRecord
                             );
  end
  else
  if (TACRLocalCursor(Cursor).SearchOperation = lsoFindKey) then
  begin
{$IFDEF DEBUG_FINDKEY_TIME}
aaStartTime(time6);
{$ENDIF}
   Result := FindRecordByScan(
              Cursor.Session.SessionID,
              TACRLocalCursor(Cursor).SearchCache.Conditions,
              TACRLocalCursor(Cursor).SearchCache.Conditions.Count-1,
              INVALID_ID4,
              Cursor.IndexID,
              Cursor.FilterRecord,
              Cursor.Dataset,
              Cursor.CurrentRecordID,
              Restart,
              GoForward,
              ResultRecordID,
              RecordBitmap,
              InternalCall,
              StopAtFirstFoundRecord
                             );
{$IFDEF DEBUG_FINDKEY_TIME}
aaStopTime(time6);
{$ENDIF}
  end
  else
  begin
{
var
    RangeCondition: TACRScanSearchCondition;
begin
  RangeCondition := TACRScanSearchCondition.Create;
  try
    if (Cursor.FilterExpression <> nil) then
      Conditions.AddExpression(Cursor.FilterExpression);
    if (Cursor.SQLFilterExpression <> nil) then
      Conditions.AddExpression(Cursor.SQLFilterExpression);
    if (Cursor.IsRangeApplied) then
    begin
      if (Cursor.RangeStartBuffer <> nil) then
      begin
        RangeCondition.KeyRecordBuffer := Cursor.RangeStartBuffer;
        RangeCondition.KeyFieldCount := Cursor.RangeStartKeyFieldCount;
        if (Cursor.RangeStartExclusive) then
          RangeCondition.Condition := scGreater
        else
          RangeCondition.Condition := scGreaterEqual;
        RangeCondition.IndexID := Cursor.IndexID;
        RangeCondition.Expression := nil;
        Conditions.AddCondition(RangeCondition);
      end;
      if (Cursor.RangeEndBuffer <> nil) then
      begin
        RangeCondition.KeyRecordBuffer := Cursor.RangeEndBuffer;
        RangeCondition.KeyFieldCount := Cursor.RangeEndKeyFieldCount;
        if (Cursor.RangeEndExclusive) then
          RangeCondition.Condition := scLower
        else
          RangeCondition.Condition := scLowerEqual;
        RangeCondition.IndexID := Cursor.IndexID;
        RangeCondition.Expression := nil;
        Conditions.AddCondition(RangeCondition);
      end;
    end;
  finally
    RangeCondition.Free;
  end;

}
   // prepare filter conditions
   TACRLocalCursor(Cursor).SearchCache.PrepareForFilter;
   // From Filter property of TACRDataset
   if (Cursor.FilterExpression <> nil) then
   begin
     TACRLocalCursor(Cursor).SearchCache.AddFilterExpression(Cursor.FilterExpression,FIndexManager.FIndexDefs);
   end;
   // From SQLFilterExpression
   if (Cursor.SQLFilterExpression <> nil) then
   begin
     TACRLocalCursor(Cursor).SearchCache.AddFilterExpression(Cursor.SQLFilterExpression,FIndexManager.FIndexDefs);
   end;
   if (Cursor.RangeStartBuffer <> nil) then
   begin
    Condition := TACRScanSearchCondition.Create;
    Condition.KeyRecordBuffer := Cursor.RangeStartBuffer;
    Condition.KeyFieldCount := Cursor.RangeStartKeyFieldCount;
    if (Cursor.RangeStartExclusive) then
      Condition.Condition := scGreater
    else
      Condition.Condition := scGreaterEqual;
    Condition.IndexID := Cursor.IndexID;
    Condition.Expression := nil;
    TACRLocalCursor(Cursor).SearchCache.AddFilterCondition(Condition);
   end;
   if (Cursor.RangeEndBuffer <> nil) then
   begin
    Condition := TACRScanSearchCondition.Create;
    Condition.KeyRecordBuffer := Cursor.RangeEndBuffer;
    Condition.KeyFieldCount := Cursor.RangeEndKeyFieldCount;
    if (Cursor.RangeEndExclusive) then
      Condition.Condition := scLower
    else
      Condition.Condition := scLowerEqual;
    Condition.IndexID := Cursor.IndexID;
    Condition.Expression := nil;
    TACRLocalCursor(Cursor).SearchCache.AddFilterCondition(Condition);
   end;
   Result := True;
   OptimizeSearchConditions(TACRLocalCursor(Cursor).SearchCache.Conditions,Result);
   // Filter / FindFirst
   if (Result) then
   begin
     ChooseScanConditions(
                          Cursor.Session.SessionID,
                          TACRLocalCursor(Cursor).SearchCache.Conditions,
                          Cursor.IndexID,
                          Cursor.CurrentRecordID,
                          GoForward,
                          ScanConditionNo,
                          ScanConditionEndNo
                         );
     Result := FindRecordByScan(
                Cursor.Session.SessionID,
                TACRLocalCursor(Cursor).SearchCache.Conditions,
                ScanConditionNo,
                ScanConditionEndNo,
                Cursor.IndexID,
                Cursor.FilterRecord,
                Cursor.Dataset,
                Cursor.CurrentRecordID,
                Restart,
                GoForward,
                ResultRecordID,
                RecordBitmap,
                InternalCall,
                StopAtFirstFoundRecord
                               );
   end;
  end;

{$IFDEF DEBUG_LOCATE_TIME}
finally
aaStopTime(time12);
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableData_FindRecord}
aaWriteToLog('< TACRTableData.FindRecord. TableName = ' + FTableName
+#13#10 + 'Self = ' + IntToHex(Integer(Self),8)
+#13#10 + 'ClassName = ' + Self.ClassName + #13#10 + 'Cursor = ' +IntToHex(Integer(Cursor), 8) + #13#10 + 'SessionID = ' + IntToStr
(Cursor.Session.SessionID) + #13#10 + 'SearchExpression = ' + IntToHex
(Integer(SearchExpression), 8) + #13#10 + 'KeyCondition = ' + IntToHex
(Integer(KeyCondition), 8) + #13#10 + 'Restart = ' + BoolToStr(Restart,
True) + #13#10 + 'GoForward = ' + BoolToStr(GoForward,
True) + #13#10 + 'ResultRecordID = ' + IntToHex(Integer(ResultRecordID),
8) + #13#10 + 'RecordBitmap = ' + IntToHex(Integer(RecordBitmap),
8) + #13#10 + 'InternalCall = ' + BoolToStr(InternalCall,
True) + #13#10 + 'StopAtFirstFoundRecord = ' + BoolToStr
(StopAtFirstFoundRecord, True) + #13#10 + 'Result = ' + BoolToStr
(Result, True));
except
on E: Exception do
begin
aaWriteToLog('TACRTableData.FindRecord Error:' + E.Message
+ #13#10 + 'TableName = ' + FTableName + #13#10 + 'Self = ' + IntToHex(Integer(Self), 8)
+ #13#10 + 'ClassName = ' + Self.ClassName
+ #13#10 + 'Cursor = ' + IntToHex(Integer(Cursor),8)
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'Restart = ' + BoolToStr(Restart,True)
+ #13#10 + 'GoForward = ' + BoolToStr(GoForward,True)
+ #13#10 + 'ResultRecordID = ' + IntToHex(Integer(ResultRecordID),8)
+ #13#10 + 'RecordBitmap = ' + IntToHex(Integer(RecordBitmap),8)
+ #13#10 + 'InternalCall = ' + BoolToStr(InternalCall,True)
+ #13#10 + 'StopAtFirstFoundRecord = ' + BoolToStr(StopAtFirstFoundRecord, True)
+ #13#10 + 'Result = ' + BoolToStr(Result, True));
end;
end;
{$ENDIF}
end; // FindRecord
{$ELSE}
//------------------------------------------------------------------------------
// return true if record was found and is visible by cursor
// prepares params for FindRecordByScan and calls it
//------------------------------------------------------------------------------
function TACRTableData.FindRecord(
                        Cursor:                       TACRCursor;
                        SearchExpression:             TACRExpression;
                        // locate
                        KeyCondition:                 TACRScanSearchCondition; // find key
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                       ): Boolean;
var
    Conditions:               TACRScanSearchConditionArray;
    ScanConditionNo:          Integer;
    ScanEndConditionNo:       Integer;
    bNonCompatibleConditions: Boolean;
    ExtractedConditionsInfo:  TList;
    RecCount:                 TACRRecordNo;
begin
{$IFDEF DEBUG_TRACE_TACRTableData_FindRecord}
if (Cursor = nil) then
aaWriteToLog('> TACRTableData.FindRecord - Cursor = nil. TableName = ' +
FTableName)
else
if (Cursor.Session = nil) then
aaWriteToLog(
'> TACRTableData.FindRecord - Cursor.Session = nil. TableName = ' +
FTableName)
else
aaWriteToLog('> TACRTableData.FindRecord. TableName = ' + FTableName +
#13#10 + 'Self = ' + IntToHex(Integer(Self),8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 + 'Cursor = ' +
IntToHex(Integer(Cursor), 8) + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID) + #13#10 + 'SearchExpression = ' +
IntToHex(Integer(SearchExpression),8) + #13#10 + 'KeyCondition = ' + IntToHex(Integer(KeyCondition),8) + #13#10 + 'Restart = ' + BoolToStr(Restart,True) + #13#10 + 'GoForward = ' + BoolToStr(GoForward,True) + #13#10 + 'ResultRecordID = ' + IntToHex(Integer(ResultRecordID), 8) + #13#10 + 'RecordBitmap = ' + IntToHex
(Integer(RecordBitmap), 8) + #13#10 + 'InternalCall = ' + BoolToStr(InternalCall, True) + #13#10 + 'StopAtFirstFoundRecord = ' + BoolToStr(StopAtFirstFoundRecord, True));
try
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaIncCounter(counter12);
aaStartTime(time12);
try
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time21);
{$ENDIF}
  RecCount := InternalGetRecordCount;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time21);
{$ENDIF}
	if (RecCount = 0) then
	begin
  	Result := False;
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
	aaWriteToLog('TACRTableData.FindRecord RecordCount = 0. TableName = ' +
			FTableName);
{$ENDIF}
	end
	else
	begin
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time22);
aaIncCounter(counter22);
{$ENDIF}
	  Conditions := TACRScanSearchConditionArray.Create;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time22);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 0. TableName = ' + FTableName);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time13);
{$ENDIF}
	  PrepareConditions(Cursor, Conditions, KeyCondition, SearchExpression,GoForward);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time13);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 1. TableName = ' + FTableName);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time23);
{$ENDIF}
    ExtractedConditionsInfo := TList.Create;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time23);
{$ENDIF}
    try
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 2. TableName = ' + FTableName);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time14);
{$ENDIF}
      Conditions.ExtractConditionsFromExpressions(FIndexManager.IndexDefs,ExtractedConditionsInfo);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time14);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 3. TableName = ' + FTableName);
{$ENDIF}
  		try
{$IFDEF DEBUG_LOCATE_TIME}
aaIncCounter(counter15);
aaStartTime(time15);
{$ENDIF}
  			OptimizeSearchConditions(Conditions, bNonCompatibleConditions);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time15);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 4. TableName = ' + FTableName +#13#10 + 'bNonCompatibleConditions = ' + BoolToStr(bNonCompatibleConditions, True));
{$ENDIF}
        if (bNonCompatibleConditions) then
          Result := False
        else
        begin
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 5. TableName = ' + FTableName);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time16);
aaIncCounter(counter16);
{$ENDIF}
          ChooseScanConditions(Cursor.Session.SessionID, Conditions,
                Cursor.IndexID, Cursor.CurrentRecordID, GoForward, ScanConditionNo,
                ScanEndConditionNo);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time16);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 6. TableName = ' + FTableName);
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time17);
{$ENDIF}
          Result := FindRecordByScan(Cursor.Session.SessionID, Conditions,
                      ScanConditionNo, ScanEndConditionNo, Cursor.IndexID,
                      Cursor.FilterRecord, Cursor.Dataset,
                      Cursor.CurrentRecordID, Restart, GoForward, ResultRecordID,
                      RecordBitmap, Cursor.RandomOrder, StopAtFirstFoundRecord);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time17);
{$ENDIF}
  			end;
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 7. TableName = ' + FTableName +#13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
      finally
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time18);
{$ENDIF}
        Conditions.ReturnConditionsToExpressions(ExtractedConditionsInfo);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time18);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 8. TableName = ' + FTableName +#13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
      end;
	  finally
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 9. TableName = ' + FTableName +#13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time19);
{$ENDIF}
		  ExtractedConditionsInfo.Free;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time19);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 10. TableName = ' + FTableName +#13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time20);
{$ENDIF}
		  Conditions.Free;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time20);
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_TACRTableData_FindRecord}
aaWriteToLog('TACRTableData.FindRecord 11. TableName = ' + FTableName +#13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
	  end;
	end;
{$IFDEF DEBUG_LOCATE_TIME}
finally
aaStopTime(time12);
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRTableData_FindRecord}
aaWriteToLog('< TACRTableData.FindRecord. TableName = ' + FTableName +
#13#10 + 'Self = ' + IntToHex(Integer(Self),
8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 + 'Cursor = ' +
IntToHex(Integer(Cursor), 8) + #13#10 + 'SessionID = ' + IntToStr
(Cursor.Session.SessionID) + #13#10 + 'SearchExpression = ' + IntToHex
(Integer(SearchExpression), 8) + #13#10 + 'KeyCondition = ' + IntToHex
(Integer(KeyCondition), 8) + #13#10 + 'Restart = ' + BoolToStr(Restart,
True) + #13#10 + 'GoForward = ' + BoolToStr(GoForward,
True) + #13#10 + 'ResultRecordID = ' + IntToHex(Integer(ResultRecordID),
8) + #13#10 + 'RecordBitmap = ' + IntToHex(Integer(RecordBitmap),
8) + #13#10 + 'InternalCall = ' + BoolToStr(InternalCall,
True) + #13#10 + 'StopAtFirstFoundRecord = ' + BoolToStr
(StopAtFirstFoundRecord, True) + #13#10 + 'Result = ' + BoolToStr
(Result, True));
except
on E: Exception do
begin
aaWriteToLog('TACRTableData.FindRecord Error:' + E.Message + #13#10 +
'TableName = ' + FTableName + #13#10 + 'Self = ' + IntToHex
(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
'Cursor = ' + IntToHex(Integer(Cursor),
8) + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'SearchExpression = ' + IntToHex(Integer(SearchExpression),
8) + #13#10 + 'KeyCondition = ' + IntToHex(Integer(KeyCondition),
8) + #13#10 + 'Restart = ' + BoolToStr(Restart,
True) + #13#10 + 'GoForward = ' + BoolToStr(GoForward,
True) + #13#10 + 'ResultRecordID = ' + IntToHex(Integer(ResultRecordID),
8) + #13#10 + 'RecordBitmap = ' + IntToHex(Integer(RecordBitmap),
8) + #13#10 + 'InternalCall = ' + BoolToStr(InternalCall,
True) + #13#10 + 'StopAtFirstFoundRecord = ' + BoolToStr
(StopAtFirstFoundRecord, True) + #13#10 + 'Result = ' + BoolToStr
(Result, True));
end;
end;
{$ENDIF}
end; // FindRecord
{$ENDIF}


//------------------------------------------------------------------------------
// return true if record match specified condition
//------------------------------------------------------------------------------
function TACRTableData.IsRecordMatchCondition(
      Condition:    TACRScanSearchCondition;
			RecordBuffer: TACRRecordBuffer
                                    ): Boolean;
var
	res: Integer;
begin
  res := FIndexManager.OpenIndex(Condition.IndexID).CompareRecordBuffersByIndex(
            RecordBuffer, Condition.KeyRecordBuffer, Condition.KeyFieldCount);
  case Condition.Condition of
  scEqual:
    Result := (res = 0);
  scGreater:
    Result := (res > 0);
  scLower:
    Result := (res < 0);
  scGreaterEqual:
    Result := (res >= 0);
  scLowerEqual:
    Result := (res <= 0)
  else
    Result := False
  end;
end; // IsRecordMatchCondition


//------------------------------------------------------------------------------
// return true if record match specified conditions
//------------------------------------------------------------------------------
{$IFDEF X64_ON}
//type  TxRecordVisblePrototype1 = function( Buffer : TACRRecordBuffer;) : boolean;
{$ENDIF}
function TACRTableData.IsRecordMatchConditions(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
			      ExcludedConditionNo:    Integer; // INVALID_ID4 if not specified
			      ExcludedConditionNo2:   Integer; // INVALID_ID4 if not specified
			      FilterRecordPtr:        Pointer;
            Dataset:                Pointer;
			      RecordBuffer:           TACRRecordBuffer
                                    ): Boolean;
var
	FunctionAddress: Pointer;
	i: Integer;
	OldBuffer: TACRRecordBuffer;
{$IFDEF X64_ON}
  aDataset: Pointer;
  aRecordBuffer: TACRRecordBuffer;
  wFunction: TxRecordVisblePrototype absolute FunctionAddress;
{$ENDIF}
begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter11); aaStartTime(time11); try
{$ENDIF}
  Result := True;
  if (Result) then
  begin
    for i := 0 to Conditions.Count - 1 do
      if (i <> ExcludedConditionNo) and (i <> ExcludedConditionNo2) then
      begin
        if (TACRScanSearchCondition(Conditions.Items[i]).Expression <> nil) then
        begin
          if (not TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).IsEmpty) then
          begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter12); aaStartTime(time12);
{$ENDIF}
            Result := TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).GetResult;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time12);
{$ENDIF}
          end;
        end // expression
        else
        begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter13); aaStartTime(time13);
{$ENDIF}
          Result := IsRecordMatchCondition(TACRScanSearchCondition(Conditions.Items[i]), RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time13);
{$ENDIF}
        end; // key condition
        if (not Result) then
          break;
      end;
  end;
  if (Result) then
    if (Pointer(FilterRecordPtr) <> nil) then
    begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter14); aaStartTime(time14);
{$ENDIF}
      if (Dataset = nil) then
        raise EACRException.Create(11635, ErrorLNilPointer);
      if (TACRDataSet(Dataset).Handle = nil) then
        raise EACRException.Create(11636, ErrorLNilPointer);
      OldBuffer := TACRDataSet(Dataset).Handle.CurrentRecordBuffer;
      try
            // Borland parameters transmitting bug fix
            // Get Function address from Virtual Method Table
{$IFDEF X64_ON}
        aDataset := Dataset;
        aRecordBuffer := RecordBuffer;
            // Borland parameters transmitting bug fix
            // Get Function address from Virtual Method Table
//        FunctionAddress := Pointer(PCardinal(Pointer(Cardinal(@FilterRecordPtr)))^);
//        Result := wFunction( aRecordBuffer, aDataset);
        FunctionAddress := Pointer(PCardinal(Pointer(Cardinal(@FilterRecordPtr)))^);
        Result := wFunction( FunctionAddress, aRecordBuffer, aDataset );

{
          asm
            MOV    ECX, Dataset                //Dataset
            MOV    EDX, RecordBuffer           //Buffer
            MOV    EAX, FunctionAddress        //Address of Function
            CALL   EAX                         //Call Function
            MOV    Result, AL                  //Save Result
          end;
}
{$ELSE}
        FunctionAddress := Pointer(PCardinal(Pointer(Cardinal(@FilterRecordPtr)))^);
          asm
            MOV    ECX, Dataset                //Dataset
            MOV    EDX, RecordBuffer           //Buffer
            MOV    EAX, FunctionAddress        //Address of Function
            CALL   EAX                         //Call Function
            MOV    Result, AL                  //Save Result
          end;
{$ENDIF}
      finally
        TACRDataSet(Dataset).Handle.CurrentRecordBuffer := OldBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time14);
{$ENDIF}
      end;
    end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
finally aaStopTime(time11); end;
{$ENDIF}
end; // IsRecordMatchConditions


//------------------------------------------------------------------------------
// return true if there are some active conditions except excluded
//------------------------------------------------------------------------------
function TACRTableData.IsRecordMatchConditionsExists(
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
            Conditions:             TACRList;
{$ELSE}
            Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
            ExcludedConditionNo:    Integer;
            // INVALID_ID4 if not specified
            ExcludedConditionNo2:   Integer; // INVALID_ID4 if not specified
            FilterRecordPtr:        Pointer
                                          ): Boolean;
var
	i: Integer;
begin
  Result := False;
  for i := 0 to Conditions.Count - 1 do
    if (i <> ExcludedConditionNo) and (i <> ExcludedConditionNo2) then
    begin
      if (TACRScanSearchCondition(Conditions.Items[i]).Expression <> nil) then
      begin
        if (not TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).IsEmpty) then
        begin
          Result := True;
          break;
        end;
      end // expression
      else
      begin
        Result := True;
        break;
      end; // key condition
    end;
  if (not Result) then
    if (Pointer(FilterRecordPtr) <> nil) then
      Result := True;
end; // IsRecordMatchConditionsExists


//------------------------------------------------------------------------------
// scan all records and check conditions
//------------------------------------------------------------------------------
function TACRTableData.FindRecordByScanWithoutCondition(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;
var
    NavigationInfo: TACRNavigationInfo;
    Acceptable:     Boolean;
    i:              Integer;
    OldBuffer:      TACRRecordBuffer;
begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
  if ((RecordBitmap <> nil) and (Conditions.Count = 0) and (FilterRecordPtr = nil)) then
  begin
    Result := False;
    if ((not InMemory) and (not Temporary)) then
      RecordBitmap.Distinct := True
  end
  else
  begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time2);
{$ENDIF}
    NavigationInfo.RecordID := CurrentRecordID;
    NavigationInfo.FirstPosition := (Restart and GoForward);
    NavigationInfo.LastPosition := (Restart and (not GoForward));
    if (GoForward) then
      NavigationInfo.GetRecordMode := grmNext
    else
      NavigationInfo.GetRecordMode := grmPrior;
    NavigationInfo.IndexID := CurrentIndexID;
    OldBuffer := NavigationInfo.RecordBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time3);
{$ENDIF}
    NavigationInfo.RecordBuffer := FRecordBufferCache.GetBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time3);
{$ENDIF}
    try
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time4);
{$ENDIF}
      for i := 0 to Conditions.Count - 1 do
        if (TACRScanSearchCondition(Conditions.Items[i]).Expression <> nil) then
          TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).AssignCursorBuffer
            (NavigationInfo.RecordBuffer);
          // scan without active condition - check each record
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time4);
{$ENDIF}
      repeat
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter5);
aaStartTime(time5);
{$ENDIF}
        InternalGetRecordBuffer(SessionID, NavigationInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time5);
{$ENDIF}
        Acceptable := False;
        if (NavigationInfo.GetRecordResult = grrOK) then
        begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
          Acceptable := IsRecordMatchConditions(Conditions, ScanConditionNo,
            ScanEndConditionNo, FilterRecordPtr, Dataset,
            NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time6);
{$ENDIF}
          if (RecordBitmap <> nil) then
          begin
            if (Acceptable) then
            begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter7);
aaStartTime(time7);
{$ENDIF}
              RecordBitmap.ShowRecord(NavigationInfo.RecordID);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time7);
{$ENDIF}
              Acceptable := False;
            end;
          end;
        end;
      until (Acceptable or (NavigationInfo.GetRecordResult <> grrOK));

      Result := (NavigationInfo.GetRecordResult = grrOK);
      if (Result) then
      begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter8);
aaStartTime(time8);
{$ENDIF}
        if (ResultRecordID <> nil) then
          Move(NavigationInfo.RecordID, ResultRecordID^,
            Sizeof(NavigationInfo.RecordID));
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time8);
{$ENDIF}
      end;
    finally
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time9);
{$ENDIF}
      FRecordBufferCache.FreeBuffer(NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time9);
{$ENDIF}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time10);
{$ENDIF}
      NavigationInfo.RecordBuffer := OldBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time10);
{$ENDIF}
    end;
  end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
finally aaStopTime(time1); end;
{$ENDIF}
end; // FindRecordByScanWithoutCondition


//------------------------------------------------------------------------------
// find records by index and condition specified by ScanConditionNo
// condition index is the same as CurrentIndex
//------------------------------------------------------------------------------
function TACRTableData.FindRecordByScanWithConditionAndConditionIndex(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;
var
	NavigationInfo: TACRNavigationInfo;
	Acceptable: Boolean;
	i: Integer;
	SearchInfo: TACRSearchInfo;
	ConditionsExists: Boolean;
	OldBuffer: TACRRecordBuffer;
begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
  Result := False;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time2);
{$ENDIF}
  ConditionsExists := IsRecordMatchConditionsExists(Conditions, ScanConditionNo,
    ScanEndConditionNo, FilterRecordPtr);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time2);
aaStartTime(time3);
{$ENDIF}
  NavigationInfo.IndexID := CurrentIndexID;
  NavigationInfo.RecordID := CurrentRecordID;
  NavigationInfo.FirstPosition := False;
  NavigationInfo.LastPosition := False;
  NavigationInfo.GetRecordMode := grmCurrent;
  OldBuffer := NavigationInfo.RecordBuffer;
  NavigationInfo.RecordBuffer := FRecordBufferCache.GetBuffer;
  try
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time3);
aaStartTime(time4);
{$ENDIF}
    SearchInfo := FIndexManager.OpenIndex(CurrentIndexID).CreateSearchInfo;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time4);
aaStartTime(time5);
{$ENDIF}
    // find current position in index
    try
      for i := 0 to Conditions.Count - 1 do
        if (TACRScanSearchCondition(Conditions.Items[i]).Expression <> nil) then
          TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).AssignCursorBuffer
            (NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time5);
aaStartTime(time6);
{$ENDIF}
        // load current record
      if (not Restart) then
        InternalGetRecordBuffer(SessionID, NavigationInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time6);
aaStartTime(time7);
{$ENDIF}
      if ((Restart) or ((not Restart) and (NavigationInfo.GetRecordResult = grrOK))) then
      begin
        repeat
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter12);
aaStartTime(time12);
{$ENDIF}
          if (ScanEndConditionNo <> INVALID_ID4) then
                // find record using the end condition
            Result := FIndexManager.OpenIndex(CurrentIndexID).FindRecord(SessionID,
              Restart, GoForward, Conditions.Items[ScanConditionNo],
              Conditions.Items[ScanEndConditionNo], NavigationInfo.RecordBuffer,
              NavigationInfo.RecordID, SearchInfo)
          else
                // find record not using the end condition
            Result := FIndexManager.OpenIndex(CurrentIndexID).FindRecord(SessionID,
              Restart, GoForward, Conditions.Items[ScanConditionNo], nil,
              NavigationInfo.RecordBuffer, NavigationInfo.RecordID, SearchInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time12);
{$ENDIF}
          Restart := False;
          Acceptable := False;
          if (Result) then
          begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter13);
aaStartTime(time13);
{$ENDIF}
            if (ConditionsExists) then
            begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter14);
aaStartTime(time14);
{$ENDIF}
              InternalGetRecordBuffer(SessionID, NavigationInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time14);
aaStartTime(time15);
{$ENDIF}
              Acceptable := IsRecordMatchConditions(Conditions, ScanConditionNo,
                ScanEndConditionNo, FilterRecordPtr, Dataset,
                NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time15);
{$ENDIF}
            end
            else
              Acceptable := True;
            if (RecordBitmap <> nil) then
            begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter16);
aaStartTime(time16);
{$ENDIF}
              if (Acceptable) then
                RecordBitmap.ShowRecord(NavigationInfo.RecordID);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time16);
{$ENDIF}
              Acceptable := False;
            end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time13);
{$ENDIF}
          end;
        until ((not Result) or (Result and Acceptable));
      end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time7);
aaStartTime(time8);
{$ENDIF}
      if (Result) then
        if (ResultRecordID <> nil) then
          Move(NavigationInfo.RecordID, ResultRecordID^,
            Sizeof(NavigationInfo.RecordID));
    finally
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time8);
aaStartTime(time9);
{$ENDIF}
      FIndexManager.OpenIndex(CurrentIndexID).FreeSearchInfo(SearchInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time9);
aaStartTime(time10);
{$ENDIF}
    end;
  finally
    FRecordBufferCache.FreeBuffer(NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time10);
aaStartTime(time11);
{$ENDIF}
    NavigationInfo.RecordBuffer := OldBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time11);
{$ENDIF}
  end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
finally
aaStopTime(time1);
end;
{$ENDIF}
end; // FindRecordByScanWithConditionAndConditionIndex


//------------------------------------------------------------------------------
// find records by index and condition specified by ScanConditionNo
// there is no active index
//------------------------------------------------------------------------------
function TACRTableData.FindRecordByScanWithConditionAndWihtoutCurrentIndex(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;
var
    NavigationInfo:     TACRNavigationInfo;
    Acceptable:         Boolean;
    i, res:             Integer;
    ResRecordID:        TACRRecordID;
    RecordFound:        Boolean;
    FindRestart:        Boolean;
    ConditionIndexID:   TACRObjectID;
    SearchInfo:         TACRSearchInfo;
    ConditionsExists:   Boolean;
    OldBuffer:          TACRRecordBuffer;
begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time2);
{$ENDIF}
  RecordFound := False;
  ConditionsExists := IsRecordMatchConditionsExists(Conditions, ScanConditionNo,
    ScanEndConditionNo, FilterRecordPtr);
  ConditionIndexID := TACRScanSearchCondition(Conditions.Items[ScanConditionNo]).IndexID;
  NavigationInfo.RecordID := CurrentRecordID;
  NavigationInfo.IndexID := INVALID_OBJECT_ID;
  NavigationInfo.GetRecordMode := grmCurrent;
  NavigationInfo.FirstPosition := False;
  NavigationInfo.LastPosition := False;
  OldBuffer := NavigationInfo.RecordBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time3);
{$ENDIF}
  NavigationInfo.RecordBuffer := FRecordBufferCache.GetBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time3);
{$ENDIF}
  try
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time4);
{$ENDIF}
    SearchInfo := FIndexManager.OpenIndex(ConditionIndexID).CreateSearchInfo;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time4);
{$ENDIF}
    try
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time5);
{$ENDIF}
      for i := 0 to Conditions.Count - 1 do
        if (TACRScanSearchCondition(Conditions.Items[i]).Expression <> nil) then
          TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).AssignCursorBuffer
            (NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time5);
{$ENDIF}
        // find current position in index
      FindRestart := True;
      repeat
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
        if (ScanEndConditionNo <> INVALID_ID4) then
          Result := FIndexManager.OpenIndex(ConditionIndexID).FindRecord(
            SessionID, FindRestart, GoForward,
            Conditions.Items[ScanConditionNo],
            Conditions.Items[ScanEndConditionNo], NavigationInfo.RecordBuffer,
            NavigationInfo.RecordID, SearchInfo)
        else
          Result := FIndexManager.OpenIndex(ConditionIndexID).FindRecord(
            SessionID, FindRestart, GoForward,
            Conditions.Items[ScanConditionNo], nil, NavigationInfo.RecordBuffer,
            NavigationInfo.RecordID, SearchInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time6);
{$ENDIF}
        FindRestart := False;
        Acceptable := False;
        if (Result) then
        begin
          if (ConditionsExists) then
          begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaIncCounter(counter7);
aaStartTime(time7);
{$ENDIF}
            InternalGetRecordBuffer(SessionID, NavigationInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time7);
{$ENDIF}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time8);
{$ENDIF}
            Acceptable := IsRecordMatchConditions(Conditions, ScanConditionNo,
              ScanEndConditionNo, FilterRecordPtr, Dataset,
              NavigationInfo.RecordBuffer);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time8);
{$ENDIF}
          end
          else
            Acceptable := True;
        end;
        if (Result and Acceptable) then
        begin
          if (StopAtFirstFoundRecord) then
          begin
            ResRecordID := NavigationInfo.RecordID;
            RecordFound := True;
            break;
          end;
          if (RecordBitmap <> nil) then
          begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time9);
{$ENDIF}
            RecordBitmap.ShowRecord(NavigationInfo.RecordID);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time9);
{$ENDIF}
          end
          else
          if (Restart) then
          begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time10);
{$ENDIF}
            // find minimum or maximum RecordID that meets all conditions
            if (not RecordFound) then
            begin
             // first record found
              ResRecordID := NavigationInfo.RecordID;
              RecordFound := True;
            end // first record found
            else
            begin
              // check current record for < or > result record
              res := CompareRecordID(NavigationInfo.RecordID, ResRecordID);
              if ((GoForward and (res < 0)) or ((not GoForward) and (res > 0))) then
                ResRecordID := NavigationInfo.RecordID;
            end; // not first record found
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time10);
{$ENDIF}
          end // Restart
          else
          begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time11);
{$ENDIF}
            // find next or prior record that mathces all conditions
            res := CompareRecordID(NavigationInfo.RecordID, CurrentRecordID);
            if ((GoForward) and (res > 0)) then
            begin
              // find next record
              if (not RecordFound) then
              begin
                RecordFound := True;
                ResRecordID := NavigationInfo.RecordID;
              end // first record found
              else
              begin
                res := CompareRecordID(NavigationInfo.RecordID, ResRecordID);
                if (res < 0) then
                  ResRecordID := NavigationInfo.RecordID;
              end; // not first record found
            end // find next record
            else
            if ((not GoForward) and (res < 0)) then
            begin
              // find next record
              if (not RecordFound) then
              begin
                RecordFound := True;
                ResRecordID := NavigationInfo.RecordID;
              end // first record found
              else
              begin
                res := CompareRecordID(NavigationInfo.RecordID, ResRecordID);
                if (res > 0) then
                  ResRecordID := NavigationInfo.RecordID;
              end; // not first record found
            end; // find prior record
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time11);
{$ENDIF}
          end; // Not restart
        end; // record meets conditions
      until (not Result);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time12);
{$ENDIF}
      if (RecordBitmap <> nil) then
      begin
        Result := False;
        if (not RandomOrder) then
          RecordBitmap.VisibleRecords.Sort;
      end
      else
        Result := RecordFound;
      if (Result) then
        if (ResultRecordID <> nil) then
          Move(ResRecordID, ResultRecordID^, Sizeof(ResRecordID));
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time12);
{$ENDIF}
    finally
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time13);
{$ENDIF}
      FIndexManager.OpenIndex(ConditionIndexID).FreeSearchInfo(SearchInfo);
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time13);
{$ENDIF}
    end;
  finally
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time14);
{$ENDIF}
    FRecordBufferCache.FreeBuffer(NavigationInfo.RecordBuffer);
    NavigationInfo.RecordBuffer := OldBuffer;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time14);
{$ENDIF}
  end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
finally aaStopTime(time1); end;
{$ENDIF}
end; // FindRecordByScanWithConditionAndWihtoutCurrentIndex


//------------------------------------------------------------------------------
// sort record ID array by positions in the index
//------------------------------------------------------------------------------
procedure TACRTableData.SortRecordIDByIndex(
                                  Records: TACRRecordIDArray;
                                  IndexPositions: TList;
                                  CurrentIndexID: TACRObjectID
                                  // INVALID_OBJECT_ID if not specified
                                  );
var
	aLo, aHi: Integer;
	TempRecordID: TACRRecordID;
	TempIndexPosition: Pointer;

function Compare(const Index1: Integer; IndexPos2: TObject): Integer;
begin
  Result := FIndexManager.OpenIndex(CurrentIndexID).CompareRecordPositionsInIndex(IndexPositions[Index1], IndexPos2);
end;

procedure Swap(const Index1: Integer; const Index2: Integer);
begin
  TempRecordID := Records.Items[Index1];
  TempIndexPosition := IndexPositions[Index1];
  Records.Items[Index1] := Records.Items[Index2];
  IndexPositions[Index1] := IndexPositions[Index2];
  Records.Items[Index2] := TempRecordID;
  IndexPositions[Index2] := TempIndexPosition;
end;

procedure QuickSort(var iLo, iHi: Integer);
var
	Lo, Hi: Integer;
	Mid: TObject;
begin
  Lo := iLo;
  Hi := iHi;
  Mid := IndexPositions[(Lo + Hi) shr 1];
  repeat
    while (Compare(Lo, Mid) < 0) and (Lo < iHi) do
      Inc(Lo);
    while (Compare(Hi, Mid) > 0) and (Hi > 0) do
      Dec(Hi);
    if (Lo <= Hi) then
    begin
    Swap(Lo, Hi);
    Inc(Lo);
    Dec(Hi);
    end;
  until (Lo > Hi);
  if (Hi > iLo) then
  begin
        // check infinite recurse
  if (iHi = Hi) then
    raise EACRException.Create(11330, ErrorLErrorSoringRecordsByID,
      [Hi, Lo, iHi, iLo, Records.ItemCount]);
  QuickSort(iLo, Hi);
  end;
  if (Lo < iHi) then
    QuickSort(Lo, iHi);
end;

// QuickSort
begin
  if (Records.ItemCount > 1) then
  begin
    aLo := 0;
    aHi := Records.ItemCount - 1;
    QuickSort(aLo, aHi);
  end;
end; // SortRecordIDByIndex


//------------------------------------------------------------------------------
// find records by index and condition specified by ScanConditionNo
// condition index is NOT the same as CurrentIndex
//------------------------------------------------------------------------------
function TACRTableData.FindRecordByScanWithConditionAndNonConditionIndex(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;
var
	NavigationInfo: TACRNavigationInfo;
	Acceptable: Boolean;
	i, res: Integer;
	ResultRecPosInIndex: TACRIndexPosition;
	ResRecordID: TACRRecordID;
	ResRecPosInIndex: TACRIndexPosition;
	CurRecPosInIndex: TACRIndexPosition;
	RecordFound: Boolean;
	FindRestart: Boolean;
	ConditionIndexID: TACRObjectID;
	SearchInfo: TACRSearchInfo;
	IndexPositions: TList;
	ConditionsExists: Boolean;
	OldBuffer: TACRRecordBuffer;
begin
Result := False;
RecordFound := False;
ConditionsExists := IsRecordMatchConditionsExists(Conditions, ScanConditionNo,
	ScanEndConditionNo, FilterRecordPtr);
ConditionIndexID := TACRScanSearchCondition(Conditions.Items[ScanConditionNo]).IndexID;
NavigationInfo.RecordID := CurrentRecordID;
NavigationInfo.IndexID := INVALID_OBJECT_ID;
NavigationInfo.GetRecordMode := grmCurrent;
NavigationInfo.FirstPosition := False;
NavigationInfo.LastPosition := False;
ResRecPosInIndex := nil;
ResultRecPosInIndex := nil;
OldBuffer := NavigationInfo.RecordBuffer;
NavigationInfo.RecordBuffer := FRecordBufferCache.GetBuffer;
try
	SearchInfo := FIndexManager.OpenIndex(ConditionIndexID).CreateSearchInfo;
	CurRecPosInIndex := FIndexManager.OpenIndex(CurrentIndexID)
		.CreateIndexPosition;
	if (RecordBitmap <> nil) then
		IndexPositions := TList.Create;
	try
		for i := 0 to Conditions.Count - 1 do
			if (TACRScanSearchCondition(Conditions.Items[i]).Expression <> nil) then
				TACRExpression(TACRScanSearchCondition(Conditions.Items[i]).Expression).AssignCursorBuffer
					(NavigationInfo.RecordBuffer);
      // find current position in index
		FindRestart := True;
		if (not Restart) then
		begin
        // load current record position in index
		NavigationInfo.RecordID := CurrentRecordID;
		NavigationInfo.IndexID := CurrentIndexID;
		InternalGetRecordBuffer(SessionID, NavigationInfo);
		if (NavigationInfo.GetRecordResult <> grrOK) then
			raise EACRException.Create(10387, ErrorLCannotFindRecordPositionInIndex,
				[CurrentIndexID, NavigationInfo.RecordID.pageNo,
				NavigationInfo.RecordID.PageItemNo]);
		if ((NavigationInfo.RecordID.pageNo <> CurrentRecordID.pageNo) or
				(NavigationInfo.RecordID.PageItemNo <> CurrentRecordID.PageItemNo))
			then
			raise EACRException.Create(10415, ErrorLCannotFindRecordPositionInIndex,
				[CurrentIndexID, NavigationInfo.RecordID.pageNo,
				NavigationInfo.RecordID.PageItemNo]);
        // find record pos in index
		if (not FIndexManager.OpenIndex(CurrentIndexID).GetIndexPosition(SessionID,
				CurrentRecordID, NavigationInfo.RecordBuffer, CurRecPosInIndex)) then
			raise EACRException.Create(10386, ErrorLCannotFindRecordPositionInIndex,
				[CurrentIndexID, NavigationInfo.RecordID.pageNo,
				NavigationInfo.RecordID.PageItemNo]);
		if ((NavigationInfo.RecordID.pageNo <> CurrentRecordID.pageNo) or
				(NavigationInfo.RecordID.PageItemNo <> CurrentRecordID.PageItemNo))
			then
			raise EACRException.Create(10414, ErrorLCannotFindRecordPositionInIndex,
				[CurrentIndexID, NavigationInfo.RecordID.pageNo,
				NavigationInfo.RecordID.PageItemNo]);
		end; // not restart

		repeat
			if (ScanEndConditionNo <> INVALID_ID4) then
				Result := FIndexManager.OpenIndex(ConditionIndexID).FindRecord
					(SessionID, FindRestart, GoForward,
					Conditions.Items[ScanConditionNo],
					Conditions.Items[ScanEndConditionNo], NavigationInfo.RecordBuffer,
					NavigationInfo.RecordID, SearchInfo)
			else
				Result := FIndexManager.OpenIndex(ConditionIndexID).FindRecord
					(SessionID, FindRestart, GoForward,
					Conditions.Items[ScanConditionNo], nil, NavigationInfo.RecordBuffer,
					NavigationInfo.RecordID, SearchInfo);
			if (Result) then
				InternalGetRecordBuffer(SessionID, NavigationInfo);
			FindRestart := False;
			Acceptable := False;
			if (Result) then
			begin
			if (ConditionsExists) then
			begin
			Acceptable := IsRecordMatchConditions(Conditions, ScanConditionNo,
				ScanEndConditionNo, FilterRecordPtr, Dataset,
				NavigationInfo.RecordBuffer);
			end
			else
				Acceptable := True;
			end;
			if (Result and Acceptable) then
			begin
			if (StopAtFirstFoundRecord) then
			begin
			ResRecordID := NavigationInfo.RecordID;
			RecordFound := True;
			break;
			end;

			if (Acceptable and (RecordBitmap <> nil)) then
			begin
			RecordBitmap.ShowRecord(NavigationInfo.RecordID);
			ResultRecPosInIndex := FIndexManager.OpenIndex(CurrentIndexID)
				.CreateIndexPosition;
            // find record pos in current index
			if (not FIndexManager.OpenIndex(CurrentIndexID).GetIndexPosition
					(SessionID, NavigationInfo.RecordID,
					NavigationInfo.RecordBuffer, ResultRecPosInIndex)) then
				raise EACRException.Create(11331,
					ErrorLCannotFindRecordPositionInIndex, [CurrentIndexID,
					NavigationInfo.RecordID.pageNo, NavigationInfo.RecordID.PageItemNo]);
			IndexPositions.Add(ResultRecPosInIndex);
			end // build record bitmap
			else
			begin
			ResultRecPosInIndex := FIndexManager.OpenIndex(CurrentIndexID)
				.CreateIndexPosition;
			try
              // find record pos in current index
				if (not FIndexManager.OpenIndex(CurrentIndexID).GetIndexPosition
						(SessionID, NavigationInfo.RecordID, NavigationInfo.RecordBuffer,
						ResultRecPosInIndex)) then
					raise EACRException.Create(10432,
						ErrorLCannotFindRecordPositionInIndex, [CurrentIndexID,
						NavigationInfo.RecordID.pageNo,
						NavigationInfo.RecordID.PageItemNo]);

				if (Restart) then
				begin
                // find minimum or maximum RecordID that meets all conditions
				if (not RecordFound) then
				begin
                  // first record found
				ResRecordID := NavigationInfo.RecordID;
				FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
					(ResRecPosInIndex);
				ResRecPosInIndex := ResultRecPosInIndex;
				RecordFound := True;
				end // first record found
				else
				begin
                  // check current record position for < or > result record position in index
				res := FIndexManager.OpenIndex(CurrentIndexID)
					.CompareRecordPositionsInIndex(ResultRecPosInIndex,
					ResRecPosInIndex);
				if ((GoForward and (res < 0)) or ((not GoForward) and (res > 0))) then
				begin
				ResRecordID := NavigationInfo.RecordID;
				FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
					(ResRecPosInIndex);
				ResRecPosInIndex := ResultRecPosInIndex;
				end;
				end; // not first record found
				end // Restart
				else
				begin
                // find next or prior record that mathces all conditions
				res := FIndexManager.OpenIndex(CurrentIndexID)
					.CompareRecordPositionsInIndex(ResultRecPosInIndex,
					CurRecPosInIndex);
				if ((GoForward) and (res > 0)) then
				begin
				if (not RecordFound) then
				begin
                    // first record found
				ResRecordID := NavigationInfo.RecordID;
				FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
					(ResRecPosInIndex);
				ResRecPosInIndex := ResultRecPosInIndex;
				RecordFound := True;
				end // first record found
				else
                  // find next record
				begin
				res := FIndexManager.OpenIndex(CurrentIndexID)
					.CompareRecordPositionsInIndex(ResultRecPosInIndex,
					ResRecPosInIndex);
				if (res < 0) then
				begin
				ResRecordID := NavigationInfo.RecordID;
				FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
					(ResRecPosInIndex);
				ResRecPosInIndex := ResultRecPosInIndex;
				end;
				end; // not first record found
				end // find next record
				else
					if ((not GoForward) and (res < 0)) then
					begin
					if (not RecordFound) then
					begin
                    // first record found
					ResRecordID := NavigationInfo.RecordID;
					FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
						(ResRecPosInIndex);
					ResRecPosInIndex := ResultRecPosInIndex;
					RecordFound := True;
					end // first record found
					else
					begin
					res := FIndexManager.OpenIndex(CurrentIndexID)
						.CompareRecordPositionsInIndex(ResultRecPosInIndex,
						ResRecPosInIndex);
					if (res > 0) then
					begin
					ResRecordID := NavigationInfo.RecordID;
					FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
						(ResRecPosInIndex);
					ResRecPosInIndex := ResultRecPosInIndex;
					end;
					end; // prior record found
					end; // not first record found
				end; // Not restart
			finally
				if (ResRecPosInIndex <> ResultRecPosInIndex) then
					FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
						(ResultRecPosInIndex);
			end;
			end; // do not create record bitmap
			end; // record meets conditions
		until (not Result);
		if (RecordBitmap <> nil) and (not StopAtFirstFoundRecord) then
		begin
		Result := False;
		if (not RandomOrder) then
		begin
		SortRecordIDByIndex(RecordBitmap.VisibleRecords, IndexPositions,
			CurrentIndexID);
		RecordBitmap.VisibleRecords.Sorted := False;
		end;
		end
		else
			Result := RecordFound;
		if (Result) then
		begin
		if (ResultRecordID <> nil) then
			Move(ResRecordID, ResultRecordID^, Sizeof(ResRecordID));
		end;
	finally
		FIndexManager.OpenIndex(ConditionIndexID).FreeSearchInfo(SearchInfo);
		FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition(CurRecPosInIndex);
		if (RecordBitmap <> nil) then
		begin
		for i := 0 to IndexPositions.Count - 1 do
		begin
		ResultRecPosInIndex := IndexPositions[i];
		FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
			(ResultRecPosInIndex);
		end;
		IndexPositions.Free;
		end
		else
		begin
		if (ResultRecPosInIndex <> ResRecPosInIndex) then
			FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
				(ResRecPosInIndex);
		FIndexManager.OpenIndex(CurrentIndexID).FreeIndexPosition
			(ResultRecPosInIndex);
		end;
	end;
finally
	FRecordBufferCache.FreeBuffer(NavigationInfo.RecordBuffer);
	NavigationInfo.RecordBuffer := OldBuffer;
end;
end; // FindRecordByScanWithConditionAndNonConditionIndex


//------------------------------------------------------------------------------
// return true if record was found
//------------------------------------------------------------------------------
function TACRTableData.FindRecordByScan(
                              SessionID:              TACRSessionID;
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
                              Conditions:             TACRList;
{$ELSE}
                              Conditions:             TACRScanSearchConditionArray;
{$ENDIF}
                              ScanConditionNo:        Integer;
                              // INVALID_ID4 if not specified
                              ScanEndConditionNo:     Integer; // INVALID_ID4 if not specified
                              CurrentIndexID:         TACRObjectID; // INVALID_OBJECT_ID if not specified
                              FilterRecordPtr:        Pointer;
                              Dataset:                Pointer;
                              CurrentRecordID:        TACRRecordID;
                              // find first or last record in order specified by index settings
                              Restart:                Boolean;
                              // go from first record to last or vice versa
                              GoForward:              Boolean;
                              // if record was found then return record id
                              ResultRecordID:         PACRRecordID;
                              // if specified - fill record bitmap
                              RecordBitmap:           TACRRecordBitmap = nil;
                              RandomOrder:            Boolean = False;
                              StopAtFirstFoundRecord: Boolean = False
                             ): Boolean;
begin
  if (ScanConditionNo = INVALID_ID4) then
    // no condition
    Result := FindRecordByScanWithoutCondition(SessionID, Conditions,
      ScanConditionNo, ScanEndConditionNo, CurrentIndexID, FilterRecordPtr,
      Dataset, CurrentRecordID, Restart, GoForward, ResultRecordID, RecordBitmap,
      RandomOrder, StopAtFirstFoundRecord)
  else
  begin
    if (ScanConditionNo >= Integer(Conditions.Count)) then
      raise EACRException.Create(10382, ErrorLInvalidScanConditionNo,
        [ScanConditionNo, Conditions.Count]);
    if (CurrentIndexID = INVALID_OBJECT_ID) then
      // condition and physical order
      Result := FindRecordByScanWithConditionAndWihtoutCurrentIndex(SessionID,
        Conditions, ScanConditionNo, ScanEndConditionNo, CurrentIndexID,
        FilterRecordPtr, Dataset, CurrentRecordID, Restart, GoForward,
        ResultRecordID, RecordBitmap, RandomOrder, StopAtFirstFoundRecord)
    else
    begin
      if (CurrentIndexID = TACRScanSearchCondition(Conditions.Items[ScanConditionNo]).IndexID) then
        // condition and condition.indexID = CurrentIndexID
        Result := FindRecordByScanWithConditionAndConditionIndex(SessionID,
            Conditions, ScanConditionNo, ScanEndConditionNo, CurrentIndexID,
            FilterRecordPtr, Dataset, CurrentRecordID, Restart, GoForward,
            ResultRecordID, RecordBitmap, RandomOrder, StopAtFirstFoundRecord)
      else
        // condition and condition.indexID <> CurrentIndexID
        Result := FindRecordByScanWithConditionAndNonConditionIndex(SessionID,
          Conditions, ScanConditionNo, ScanEndConditionNo, CurrentIndexID,
          FilterRecordPtr, Dataset, CurrentRecordID, Restart, GoForward,
          ResultRecordID, RecordBitmap, RandomOrder, StopAtFirstFoundRecord)
    end;
  end; // condition
end; // FindRecordByScan


//------------------------------------------------------------------------------
// used by GetRecordBuffer - find or get record
//------------------------------------------------------------------------------
function TACRTableData.InternalFindOrGetRecordBuffer(
                                                      Cursor:         TACRCursor;
                                                      GetRecordMode:  TACRGetRecordMode;
                                                      // if specified - fill record bitmap
                                                      RecordBitmap:   TACRRecordBitmap = nil
                                                     ): TACRGetRecordResult;
var
	Restart, GoForward, RecordFound: Boolean;
	RecordID: TACRRecordID;
	NavigationInfo: TACRNavigationInfo;
begin
  try
    NavigationInfo.SessionID := Cursor.Session.SessionID;
    if (GetRecordMode <> grmCurrent) and (Cursor.IsViewRestricted) then
    begin
        // find
      Restart := (Cursor.FirstPosition or Cursor.LastPosition);
      GoForward := (GetRecordMode = grmNext);
      {$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
      RecordFound := FindRecord(Cursor, Restart, GoForward, @RecordID,
                                  RecordBitmap, True, False);
      {$ELSE}
      RecordFound := FindRecord(Cursor, nil, nil, Restart, GoForward, @RecordID,
                                  RecordBitmap, True, False);
      {$ENDIF}
      if (RecordFound) then
      begin
      NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
      NavigationInfo.RecordID := RecordID;
      NavigationInfo.FirstPosition := False;
      NavigationInfo.LastPosition := False;
      NavigationInfo.GetRecordMode := grmCurrent;
      FRecordManager.GetRecordBuffer(NavigationInfo);
      Result := NavigationInfo.GetRecordResult;
      Cursor.CurrentRecordID := NavigationInfo.RecordID;
      Cursor.FirstPosition := NavigationInfo.FirstPosition;
      Cursor.LastPosition := NavigationInfo.LastPosition;
      end
      else
      begin
      if (GetRecordMode = grmNext) then
        Result := grrEOF
      else
        Result := grrBOF;
      end;
      end
      else
      begin
      NavigationInfo.IndexID := Cursor.IndexID;
      NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
      NavigationInfo.RecordID := Cursor.CurrentRecordID;
      NavigationInfo.FirstPosition := Cursor.FirstPosition;
      NavigationInfo.LastPosition := Cursor.LastPosition;
      NavigationInfo.GetRecordMode := GetRecordMode;
      InternalGetRecordBuffer(Cursor.Session.SessionID, NavigationInfo);
      Result := NavigationInfo.GetRecordResult;
      Cursor.CurrentRecordID := NavigationInfo.RecordID;
      Cursor.FirstPosition := NavigationInfo.FirstPosition;
      Cursor.LastPosition := NavigationInfo.LastPosition;
      if (Result = grrOK) and (Cursor.IsViewRestricted) then
        if (not IsRecordVisible(Cursor)) then
          Result := grrError;
    end;
  except
    on E: Exception do
    begin
  {$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
    aaWriteToLog(E.Message);
  {$ENDIF}
    Result := grrError;
    end;
  end;
end; // InternalFindOrGetRecordBuffer

//------------------------------------------------------------------------------
// get record using current index or physical order
//------------------------------------------------------------------------------
procedure TACRTableData.InternalGetRecordBuffer(SessionID: TACRSessionID;	var NavigationInfo: TACRNavigationInfo);
begin
  if (FRecordManager = nil) then
    raise EACRException.Create(10015, ErrorLNilPointer);
  if (FIndexManager = nil) then
    raise EACRException.Create(10380, ErrorLNilPointer);
  if (NavigationInfo.RecordBuffer = nil) then
    raise EACRException.Create(10016, ErrorLNilPointer);
  NavigationInfo.SessionID := SessionID;
  if ((NavigationInfo.IndexID <> INVALID_OBJECT_ID) and
      (NavigationInfo.GetRecordMode <> grmCurrent)) then
  begin
    FIndexManager.GetRecordBuffer(SessionID, NavigationInfo);
  end
  else
  begin
    FRecordManager.Repair := FRepair;
    FRecordManager.GetRecordBuffer(NavigationInfo);
  end;
end; // InternalGetRecordBuffer


//------------------------------------------------------------------------------
// update bitmap after insert record
//------------------------------------------------------------------------------
procedure TACRTableData.UpdateRecordBitmapAfterInsertRecord(Cursor: TACRCursor;	Pos: Pointer);
var	RecordVisible: Boolean;
begin
  RecordVisible := IsRecordVisible(Cursor);
  if (not RecordVisible) then
  begin
    Cursor.RestorePosition(Pos);
    if ((not Cursor.FirstPosition) and (not Cursor.LastPosition)) then
      GetRecordBuffer(Cursor, grmCurrent);
  end
  else
  begin
    if (not Cursor.IsIndexApplied) then
      TACRRecordBitmap(Cursor.RecordBitmap).InsertVisibleRecord
        (Cursor.CurrentRecordID, Cursor.CurrentRecordID, False, True)
    else
      ShowRecord(Cursor); // index applied
  end;
end; // UpdateRecordBitmapAfterInsertRecord


//------------------------------------------------------------------------------
// update bitmap after update record
//------------------------------------------------------------------------------
procedure TACRTableData.UpdateRecordBitmapAfterUpdateRecord(Cursor: TACRCursor);
var
	RecordVisible: Boolean;
	RecordID: TACRRecordID;
begin
  RecordID := Cursor.CurrentRecordID;
  RecordVisible := IsRecordVisible(Cursor);
  if (not Cursor.IsIndexApplied) then
  begin
    if (not RecordVisible) then
    begin
      if (GetRecordBuffer(Cursor, grmNext) <> grrOK) then
        GetRecordBuffer(Cursor, grmPrior);
      TACRRecordBitmap(Cursor.RecordBitmap).HideRecord(RecordID);
    end;
  end // no index applied
  else
  begin
    if (not RecordVisible) then
    begin
      // move to next visible record
      if (GetRecordBuffer(Cursor, grmNext) <> grrOK) then
        GetRecordBuffer(Cursor, grmPrior);
      TACRRecordBitmap(Cursor.RecordBitmap).HideRecord(RecordID);
    end
    else
    begin
      if (FIndexManager.CompareRecordBuffersByIndex(Cursor.IndexID,
          Cursor.CurrentRecordBuffer, Cursor.EditRecordBuffer, 0) <> 0) then
      begin
        TACRRecordBitmap(Cursor.RecordBitmap).HideRecord(RecordID);
        ShowRecord(Cursor);
      end; // visible record changed its poisition in current index
    end; // visible record
  end; // index applied
end; // UpdateRecordBitmapAfterUpdateRecord


//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRTableData.IsRecordExists(Cursor: TACRCursor): Boolean;
begin
Result := FRecordManager.IsRecordExists(Cursor.CurrentRecordID,
	Cursor.Session.SessionID);
end; // IsRecordExists

//------------------------------------------------------------------------------
// get record buffer
//------------------------------------------------------------------------------
function TACRTableData.GetRecordBuffer(Cursor: TACRCursor;
	GetRecordMode: TACRGetRecordMode): TACRGetRecordResult;
var
	IsViewRestricted: Boolean;
	Acceptable: Boolean;
	Buffer: TACRRecordBuffer;
	NavigationInfo: TACRNavigationInfo;
begin
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
aaWriteToLog('> TACRTableData.GetRecordBuffer. Cursor = ' + IntToHex
		(Integer(Cursor), 8));
if (Cursor <> nil) then
	aaWriteToLog('Self = ' + IntToHex(Integer(Self),
			8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
			'TableName = ' + FTableName + #13#10 + 'Mode = ' + IntToStr
			(Integer(GetRecordMode)) + #13#10 + 'SessionID = ' + IntToStr
			(Cursor.Session.SessionID) + #13#10 + 'FirstPosition = ' + BoolToStr
			(Cursor.FirstPosition, True) + #13#10 + 'LastPosition = ' + BoolToStr
			(Cursor.LastPosition, True) + #13#10 + 'CurrentRecordID = ' + IntToStr
			(Cursor.CurrentRecordID.pageNo) + ' - ' + IntToStr
			(Cursor.CurrentRecordID.PageItemNo));
{$ENDIF}
try
	if (InternalGetRecordCount = 0) then
	begin
	Result := grrEOF;
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
aaWriteToLog('< TACRTableData.GetRecordBuffer. Cursor = ' + IntToHex
    (Integer(Cursor), 8));
if (Cursor <> nil) then
  aaWriteToLog('Self = ' + IntToHex(Integer(Self),
      8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
      'TableName = ' + FTableName + #13#10 + 'Mode = ' +
      IntToStr(Integer(GetRecordMode)) + #13#10 + 'SessionID = ' + IntToStr
      (Cursor.Session.SessionID) + #13#10 + 'FirstPosition = ' + BoolToStr
      (Cursor.FirstPosition, True) + #13#10 + 'LastPosition = ' + BoolToStr
      (Cursor.LastPosition, True) + #13#10 + 'CurrentRecordID = ' + IntToStr
      (Cursor.CurrentRecordID.pageNo) + ' - ' + IntToStr
      (Cursor.CurrentRecordID.PageItemNo) + #13#10 +
      'Result = grrEOF, recordcount = 0');
{$ENDIF}
	Exit;
	end;
	NavigationInfo.SessionID := Cursor.Session.SessionID;
	Result := grrError;
	IsViewRestricted := Cursor.IsViewRestricted;
	try
		repeat
			Acceptable := True;
			if (IsViewRestricted) then
			begin
        if (not TACRRecordBitmap(Cursor.RecordBitmap).Active) then
        begin
          BuildCursorRecordBitmap(Cursor);
        end;
        NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
        NavigationInfo.RecordID := Cursor.CurrentRecordID;
        NavigationInfo.FirstPosition := Cursor.FirstPosition;
        NavigationInfo.LastPosition := Cursor.LastPosition;
        NavigationInfo.GetRecordMode := GetRecordMode;
        TACRRecordBitmap(Cursor.RecordBitmap).GetRecord(NavigationInfo);
        if (NavigationInfo.GetRecordResult = grrOK) then
        begin
          NavigationInfo.GetRecordMode := grmCurrent;
          NavigationInfo.FirstPosition := False;
          NavigationInfo.LastPosition := False;
          FRecordManager.GetRecordBuffer(NavigationInfo);
        end;
        Result := NavigationInfo.GetRecordResult;
        Cursor.CurrentRecordID := NavigationInfo.RecordID;
        Cursor.FirstPosition := NavigationInfo.FirstPosition;
        Cursor.LastPosition := NavigationInfo.LastPosition;
			end
			else
			begin
  			Result := InternalFindOrGetRecordBuffer(Cursor, GetRecordMode);
			end;
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
if (Cursor <> nil) then
  aaWriteToLog('TACRTableData.GetRecordBuffer. Cursor = ' + IntToHex
      (Integer(Cursor), 8));
aaWriteToLog('Self = ' + IntToHex(Integer(Self),
    8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
    'TableName = ' + FTableName + #13#10 + 'IsDistinctApplied = ' +
    BoolToStr(IsDistinctApplied,
    True) + #13#10 + 'IsViewRestricted = ' + BoolToStr(IsViewRestricted,
    True) + #13#10 + 'Mode = ' + IntToStr(Integer(GetRecordMode))
    + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
    + #13#10 + 'FirstPosition = ' + BoolToStr(Cursor.FirstPosition,
    True) + #13#10 + 'LastPosition = ' + BoolToStr(Cursor.LastPosition,
    True) + #13#10 + 'CurrentRecordID = ' + IntToStr
    (Cursor.CurrentRecordID.pageNo) + ' - ' + IntToStr
    (Cursor.CurrentRecordID.PageItemNo) + #13#10 + 'Result = ' + IntToStr
    (Byte(Result)));
{$ENDIF}
			if ((GetRecordMode = grmCurrent) and (not Acceptable)) then
				Result := grrError;
		until ((Acceptable) or (Result <> grrOK));
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
		aaWriteToLog('TACRTableData.GetRecordBuffer finished OK.' + #13#10 +
				'Result = ' + IntToStr(Byte(Result)));
{$ENDIF}
	finally
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
		aaWriteToLog('TACRTableData.GetRecordBuffer. Cursor = ' + IntToHex
				(Integer(Cursor), 8));
		aaWriteToLog
			('TACRTableData.GetRecordBuffer Cursor.DistinctRecordBuffer = ' + IntToHex(Integer(Cursor.DistinctRecordBuffer), 8));
{$ENDIF}
	end;
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
	aaWriteToLog('< TACRTableData.GetRecordBuffer. Cursor = ' + IntToHex
			(Integer(Cursor), 8));
	if (Cursor <> nil) then
		aaWriteToLog('Self = ' + IntToHex(Integer(Self),
				8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
				'TableName = ' + FTableName + #13#10 + 'Mode = ' +
				IntToStr(Integer(GetRecordMode)) + #13#10 + 'SessionID = ' + IntToStr
				(Cursor.Session.SessionID) + #13#10 + 'FirstPosition = ' + BoolToStr
				(Cursor.FirstPosition, True) + #13#10 + 'LastPosition = ' + BoolToStr
				(Cursor.LastPosition, True) + #13#10 + 'CurrentRecordID = ' + IntToStr
				(Cursor.CurrentRecordID.pageNo) + ' - ' + IntToStr
				(Cursor.CurrentRecordID.PageItemNo) + #13#10 + 'Result = ' + IntToStr
				(Byte(Result)));
{$ENDIF}
except
	on E: Exception do
	begin
   // fixed in v.5.91
   Result := grrError;
{$IFDEF DEBUG_TRACE_TACRTableData_GetRecordBuffer}
      aaWriteToLog('< TACRTableData.GetRecordBuffer. Error: ' + #13#10 + E.Message);
      aaWriteToLog('Cursor = ' + IntToHex(Integer(Cursor), 8));
      if (Cursor <> nil) then
      aaWriteToLog('Self = ' + IntToHex(Integer(Self),
      8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
      'TableName = ' + FTableName + #13#10 + 'Mode = ' +
      IntToStr(Integer(GetRecordMode)) + #13#10 + 'SessionID = ' + IntToStr
      (Cursor.Session.SessionID) + #13#10 + 'FirstPosition = ' + BoolToStr
      (Cursor.FirstPosition, True) + #13#10 + 'LastPosition = ' + BoolToStr
      (Cursor.LastPosition, True) + #13#10 + 'CurrentRecordID = ' + IntToStr
      (Cursor.CurrentRecordID.pageNo) + ' - ' + IntToStr
      (Cursor.CurrentRecordID.PageItemNo) + #13#10 + 'Result = ' + IntToStr
      (Byte(Result)));
{$ENDIF}
  end;
end;
end; // GetRecordBuffer



{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// locate
//------------------------------------------------------------------------------
function TACRTableData.Locate(
                Cursor:           TACRCursor;
                const KeyFields:  WideString;
                const KeyValues:  Variant;
                CaseInsensitive:  Boolean;
                PartialKey:       Boolean
               ): Boolean;
var
      RecordID:         TACRRecordID;
      crc:              Cardinal;
      SearchCondition:  TACRScanSearchCondition;
      FieldNamesList:   TACRWideStringList;
      Expression:       TACRExpression;
      pLocateCondition: PACRLocateCondition;
      i,n:              Integer;
      Nodes:            TACRList;

function SetParams: Boolean;
var i,j,n,fn:     Integer;
    fType:        TACRBaseFieldType;
    param:        TACRSQLParam;
    cond:         TACRScanSearchCondition;
    Params:       TACRSQLParams;
    Offset,Size:  Integer;
{$I ACR_set_null_flag_var.inc}
begin
   Result := True;
   Params := TACRSQLParams(pLocateCondition^.Params);
   // cast all paramters to field types
   for i := 0 to Params.Count-1 do
   begin
     n := pLocateCondition^.FieldDefsNumbers.Items[i];
     fType := FFieldManager.FFieldDefs.Items[n].BaseFieldType;
     param := TACRSQLParam(Params[i]);
     if (param.DataType <> fType) then
      param.Cast(fType);
     // check if string fields
//     if (param.IsStringDataType) then
     if (fType in [bftChar, bftWideChar, bftVarchar, bftWideVarchar , bftClob, bftWideClob]) then
     begin
      if (param.StrLen > FFieldManager.FFieldDefs.Items[n].FieldSize) then
      begin
       Result := False;
       Exit;
      end;
     end;
   end;
   // set KeyValues to search conditions based on index
   for i := 0 to pLocateCondition^.Conditions.Count-1 do
   begin
    cond := TACRScanSearchCondition(pLocateCondition^.Conditions[i]);
    if (cond.Expression <> nil) then
     TACRExpression(cond.Expression).LocalParams := Params
    else
    begin
     // set key fields
     for j := 0 to cond.ParamIndexes.ItemCount-1 do
     begin
      n := cond.ParamIndexes.Items[j];
      fn := pLocateCondition^.FieldDefsNumbers.Items[n];
      param := Params[n];
      SET_NULL_FLAG_ToSet := param.IsNull;
      SET_NULL_FLAG_NullFlags := cond.KeyRecordBuffer;
      SET_NULL_FLAG_BitNo := fn;
      {$I ACR_set_null_flag.inc}
      if (not SET_NULL_FLAG_ToSet) then
      begin
       Offset := FFieldManager.FFieldDefs.Items[fn].MemoryOffset;
       Size := param.DataSize;
       if (Size > FFieldManager.FFieldDefs.Items[fn].MemoryDataSize) then
        Size := FFieldManager.FFieldDefs.Items[fn].MemoryDataSize;
       Move(param.PData^, PAnsiChar(cond.KeyRecordBuffer+Offset)^,Size);
      end;
     end;
    end;
   end;
end; // SetParams

begin
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time9);
{$ENDIF}
  if (not (Cursor is TACRLocalCursor)) then
    raise EACRException.Create(12393, ErrorLInvalidClass,
            [Cursor.ClassName,'TACRLocalCursor',IntToHex(Integer(Cursor),8)]);

  Result := False;
{$IFDEF DEBUG_LOCATE_TIME}
  aaStartTime(time7);
{$ENDIF}
  // set search parameters
  Result := True;
  crc := GetTableNameCRC(KeyFields,True);
  pLocateCondition := TACRLocalCursor(Cursor).SearchCache.FindLocateCondition(
                          crc, CaseInsensitive,PartialKey);
  if (pLocateCondition = nil) then
  begin
   // parse field names
   FieldNamesList := TACRWideStringList.Create;
   try
     ACRParseFieldNames(KeyFields,FieldNamesList);
     pLocateCondition := TACRLocalCursor(Cursor).SearchCache.CreateLocateCondition;
     try
       Expression := TACRExpression.Create(Cursor.Session,nil);
       try
         Expression.LocalParams := TACRSQLParams(pLocateCondition^.Params);
         Expression.ParseForLocate(Cursor,FieldNamesList,CaseInsensitive,PartialKey);
       except
       {$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
         on e: Exception do
         begin
          aaWriteToLog('Error in TACRTableData.PrepareForLocate - Expression.ParseForLocate: '+#13#10+e.Message);
          Expression.Free;
          raise;
         end;
       {$ELSE}
         Expression.Free;
         raise;
       {$ENDIF}
       end;
       TACRSQLParams(pLocateCondition^.Params).AsVariant := KeyValues;
       pLocateCondition^.FieldsNamesCRC := crc;
       pLocateCondition^.CaseInsensitive := CaseInsensitive;
       pLocateCondition^.PartialKey := PartialKey;
       Nodes := TACRList.Create;
       try
         try
           if (Expression.ExtractIndexScanConditions(pLocateCondition^.Conditions,FIndexManager.FIndexDefs)) then
           begin
             Expression.Free;
             Expression := nil;
           end
           else
           begin
             SearchCondition := TACRScanSearchCondition.Create;
             SearchCondition.Expression := Expression;
             SearchCondition.OwnExpression := true;
             pLocateCondition^.Conditions.Add(SearchCondition);
           end;
{
       if (Expression.IsEmpty) then
       begin
         Expression.Free;
         Expression := nil;
       end
       else
       begin
         SearchCondition := TACRScanSearchCondition.Create;
         SearchCondition.Expression := Expression;
         SearchCondition.OwnExpression := true;
         pLocateCondition^.Conditions.Add(SearchCondition);
       end;
}
         except
         {$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
           on e: Exception do
           begin
            aaWriteToLog('Error in TACRTableData.PrepareForLocate - Expression.ExtractIndexScanConditions: '+#13#10+e.Message);
            Expression.Free;
            raise;
           end;
         {$ELSE}
           Expression.Free;
           raise;
         {$ENDIF}
         end;
       finally
         Nodes.Free;
       end;
     except
     {$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
       on e: Exception do
       begin
        aaWriteToLog('Error in TACRTableData.PrepareForLocate: '+#13#10+e.Message);
        TACRLocalCursor(Cursor).SearchCache.FreeLocateCondition(pLocateCondition);
        raise;
       end;
     {$ELSE}
        TACRLocalCursor(Cursor).SearchCache.FreeLocateCondition(pLocateCondition);
        raise;
     {$ENDIF}
     end;
     TACRLocalCursor(Cursor).SearchCache.AddLocateCondition(pLocateCondition);
     // set field numbers
     for i := 0 to FieldNamesList.Count-1 do
     begin
      n := FFieldManager.FFieldDefs.GetDefNumberByName(FieldNamesList[i]);
      pLocateCondition^.FieldDefsNumbers.Append(n);
     end;
     Result := SetParams;
     if (not Result) then
      Exit;
     ChooseScanConditions(
                          Cursor.Session.SessionID,
                          TACRLocalCursor(Cursor).SearchCache.Conditions,
                          Cursor.IndexID,
                          Cursor.CurrentRecordID,
                          False,
                          pLocateCondition^.ScanConditionNo,
                          pLocateCondition^.ScanEndConditionNo,
                         );
   finally
     FieldNamesList.Free;
   end;
  end // condition not found in cache
  else
  begin
    TACRSQLParams(pLocateCondition^.Params).AsVariant := KeyValues;
    // setup KeyValues
    SetParams;
  end;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time7);
aaStartTime(time10);
{$ENDIF}
  // search record
  if (Result) then
  begin
    TACRLocalCursor(Cursor).SearchOperation := lsoLocate;
    try
      Result := FindRecord(Cursor, False, False, @RecordID, nil, True, True);
    finally
      TACRLocalCursor(Cursor).SearchOperation := lsoNone;
    end;
  end;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time10);
{$ENDIF}
  if (Result) then
  begin
    Cursor.FirstPosition := False;
    Cursor.LastPosition := False;
    Cursor.CurrentRecordID := RecordID;
{$IFDEF DEBUG_LOCATE_TIME}
aaIncCounter(counter11);
aaStartTime(time11);
{$ENDIF}
    GetRecordBuffer(Cursor, grmCurrent);
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time11);
{$ENDIF}
  end;
{$IFDEF DEBUG_LOCATE_TIME}
aaStopTime(time9);
{$ENDIF}
end; // Locate
{$ELSE}
//------------------------------------------------------------------------------
// locate
//------------------------------------------------------------------------------
function TACRTableData.Locate(Cursor: TACRCursor; SearchExpression: TACRExpression): Boolean;
var
      OldPos: Pointer;
      RecordID: TACRRecordID;
begin
  if (SearchExpression = nil) then
    raise EACRException.Create(11375, ErrorLNilPointer);
{$IFDEF DEBUG_LOCATE_TIME}
aaStartTime(time9);
{$ENDIF}
  Result := False;
  OldPos := Cursor.SavePosition;
  try
{$IFDEF DEBUG_LOCATE_TIME}
  aaStartTime(time10);
{$ENDIF}
    Result := FindRecord(Cursor, SearchExpression, nil, True, True, @RecordID, nil, False, False);
{$IFDEF DEBUG_LOCATE_TIME}
  aaStopTime(time10);
{$ENDIF}
    if (Result) then
    begin
    Cursor.FirstPosition := False;
    Cursor.LastPosition := False;
    Cursor.CurrentRecordID := RecordID;
{$IFDEF DEBUG_LOCATE_TIME}
  aaIncCounter(counter11);
  aaStartTime(time11);
{$ENDIF}
    GetRecordBuffer(Cursor, grmCurrent);
{$IFDEF DEBUG_LOCATE_TIME}
  aaStopTime(time11);
{$ENDIF}
    end;
  finally
    if (not Result) then
      Cursor.RestorePosition(OldPos);
    Cursor.FreePosition(OldPos);
  {$IFDEF DEBUG_LOCATE_TIME}
    aaStopTime(time9);
  {$ENDIF}
  end;
end; // Locate
{$ENDIF}


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// find key
//------------------------------------------------------------------------------
function TACRTableData.FindKey(Cursor: TACRCursor; SearchCondition: TACRSearchCondition): Boolean;
var
    RecordID:           TACRRecordID;
    KeyCondition:       TACRScanSearchCondition;
begin
{$IFDEF DEBUG_FINDKEY_TIME}
aaStartTime(time1);
{$ENDIF}
  if (not (Cursor is TACRLocalCursor)) then
    raise EACRException.Create(12399, ErrorLInvalidClass,
            [Cursor.ClassName,'TACRLocalCursor',IntToHex(Integer(Cursor),8)]);
  if (Cursor.IndexID = INVALID_OBJECT_ID) then
    raise EACRException.Create(12400,ErrorLIndexNotSet,[FTableName]);
{$IFDEF DEBUG_FINDKEY_TIME}
aaStartTime(time2);
{$ENDIF}
  KeyCondition := TACRLocalCursor(Cursor).SearchCache.GetFindKeySearchCondition;
{$IFDEF DEBUG_FINDKEY_TIME}
aaStopTime(time2);
aaStartTime(time3);
{$ENDIF}
  if (KeyCondition = nil) then
  begin
    KeyCondition := TACRScanSearchCondition.Create;
    KeyCondition.Condition := SearchCondition;
    KeyCondition.KeyFieldCount := Cursor.KeyFieldCount;
    KeyCondition.KeyRecordBuffer := Cursor.KeyBuffer;
    KeyCondition.IndexID := Cursor.IndexID;
    KeyCondition.Expression := nil;
    TACRLocalCursor(Cursor).SearchCache.AddFindKeySearchCondition(KeyCondition);
  end;
{$IFDEF DEBUG_FINDKEY_TIME}
aaStopTime(time3);
aaStartTime(time4);
{$ENDIF}
  TACRLocalCursor(Cursor).SearchOperation := lsoFindKey;
  try
    Result := FindRecord(Cursor,True,True,@RecordID,nil,False,False);
  finally
    TACRLocalCursor(Cursor).SearchOperation := lsoNone;
  end;
{$IFDEF DEBUG_FINDKEY_TIME}
aaStopTime(time4);
aaStartTime(time5);
{$ENDIF}
  if (Result) then
  begin
    Cursor.FirstPosition := False;
    Cursor.LastPosition := False;
    Cursor.CurrentRecordID := RecordID;
  end;
{$IFDEF DEBUG_FINDKEY_TIME}
aaStopTime(time5);
aaStopTime(time1);
{$ENDIF}
end; // FindKey
{$ELSE}
//------------------------------------------------------------------------------
// find key
//------------------------------------------------------------------------------
function TACRTableData.FindKey(Cursor: TACRCursor; SearchCondition: TACRSearchCondition): Boolean;
var
    OldPos: Pointer;
    KeyCondition: TACRScanSearchCondition;
    RecordID: TACRRecordID;
begin
  Result := False;
  OldPos := Cursor.SavePosition;
  KeyCondition := TACRScanSearchCondition.Create;
  try
    KeyCondition.Condition := SearchCondition;
    KeyCondition.KeyFieldCount := Cursor.KeyFieldCount;
    KeyCondition.KeyRecordBuffer := Cursor.KeyBuffer;
    KeyCondition.IndexID := Cursor.IndexID;
    KeyCondition.Expression := nil;
    Result := FindRecord(Cursor, nil, KeyCondition, True, True, @RecordID, nil, False, False);
    if (Result) then
    begin
    Cursor.FirstPosition := False;
    Cursor.LastPosition := False;
    Cursor.CurrentRecordID := RecordID;
    end;
  finally
    if (not Result) then
      Cursor.RestorePosition(OldPos);
    Cursor.FreePosition(OldPos);
    KeyCondition.Free;
  end;
end; // FindKey
{$ENDIF}


//------------------------------------------------------------------------------
// return true if BLOB value was modified before Post or Cancel
//------------------------------------------------------------------------------
function TACRTableData.IsBLOBModified(RecordBuffer: TACRRecordBuffer;	FieldDef: TACRFieldDef): Boolean;
begin
  // fixed in v.12.10
  {$IFDEF X64_ON}
  Result := (PWord(RecordBuffer + FieldDef.MemoryOffset + FieldDef.MemoryDataSize - SizeOf(Word))^ = ACR_BLOB_MODIFIED);
  {$ELSE}
  Result := (PWord(RecordBuffer + FieldDef.MemoryOffset + FieldDef.DiskDataSize)^ = ACR_BLOB_MODIFIED);
  {$ENDIF}
end; // IsBLOBModified


//------------------------------------------------------------------------------
// set modified or not modified flag for the blob value in specified field
//------------------------------------------------------------------------------
procedure TACRTableData.SetBLOBModified(Modified: Boolean;
	RecordBuffer: TACRRecordBuffer; FieldDef: TACRFieldDef);
begin
  // fixed in v.12.10
  {$IFDEF X64_ON}
    if (Modified) then
      PWord(RecordBuffer + FieldDef.MemoryOffset + FieldDef.MemoryDataSize - SizeOf(Word))^ :=
        ACR_BLOB_MODIFIED
    else
      PWord(RecordBuffer + FieldDef.MemoryOffset + FieldDef.MemoryDataSize - SizeOf(Word))^ :=
        ACR_BLOB_NOT_MODIFIED;
  {$ELSE}
    if (Modified) then
      PWord(RecordBuffer + FieldDef.MemoryOffset + FieldDef.DiskDataSize)^ :=
        ACR_BLOB_MODIFIED
    else
      PWord(RecordBuffer + FieldDef.MemoryOffset + FieldDef.DiskDataSize)^ :=
        ACR_BLOB_NOT_MODIFIED;
  {$ENDIF}
end; // SetBLOBModified

//------------------------------------------------------------------------------
// create blob stream
//------------------------------------------------------------------------------
function TACRTableData.InternalCreateBlobStream(
    Cursor:       TACRCursor;
	  ToInsert:     Boolean;
    FieldNo:      Integer;
    OpenMode:     TACRBLOBOpenMode
    ): TACRStream;
var
	TempStream:           TACRTemporaryStream;
	CompressedStream:     TACRCompressedBLOBStream;
	Buffer:               PAnsiChar;
	Offset, BufferSize:   Integer;
	BLOBDescriptor:       TACRBLOBDescriptor;
{$I ACR_check_null_flag_var.inc}
begin
  Result := nil;
  BLOBDescriptor.CompressionAlgorithm := Byte
    (FieldManager.FieldDefs[FieldNo].BLOBCompressionAlgorithm);
  BLOBDescriptor.CompressionMode := FieldManager.FieldDefs[FieldNo]
    .BLOBCompressionMode;
  BLOBDescriptor.BlockSize := FieldManager.FieldDefs[FieldNo].BLOBBlockSize;
  if (BLOBDescriptor.BlockSize = 0) then
    raise EACRException.Create(10420, ErrorLZeroBlockSizeIsNotAllowed);
  BLOBDescriptor.StartPosition := 0;
  TempStream := TACRTemporaryStream.Create;
  if Cursor.CurrentRecordBuffer = nil then
    CHECK_NULL_FLAG_Result := True
  else
  begin
    CHECK_NULL_FLAG_BitNo := FieldNo;
    CHECK_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
    {$I ACR_check_null_flag.inc}
  end;
  // create new compressed stream
  if ((ToInsert and (OpenMode = bomWrite)) or (OpenMode = bomWrite) or
      CHECK_NULL_FLAG_Result) then
  begin
    // empty stream
    BLOBDescriptor.NumBlocks := 0;
    BLOBDescriptor.UncompressedSize := 0;
    CompressedStream := TACRCompressedBLOBStream.Create(TempStream, BLOBDescriptor,
      True);
    Result := TACRLocalBLOBStream.Create(CompressedStream, Cursor, OpenMode,
      FieldNo);
  end // empty stream
  else
  begin
    // copy value from TableData
    Offset := FieldManager.FieldDefs[FieldNo].MemoryOffset;
    // get pointer to memory buffer with blob stream content
    Buffer := PAnsiChar(PCardinal(Cursor.CurrentRecordBuffer + Offset)^);
    if (Buffer = nil) then
      raise EACRException.Create(10112, ErrorLNilPointer);
        // creating source memory stream
    Offset := Sizeof(TACRPartialBLOBDescriptor);
    BufferSize := MemoryManager.GetMemoryBufferSize(Buffer) - Offset;
        // copy partial blob descriptor
    BLOBDescriptor.NumBlocks := PACRPartialBLOBDescriptor(Buffer)^.NumBlocks;
    BLOBDescriptor.UncompressedSize := PACRPartialBLOBDescriptor(Buffer)
      ^.UncompressedSize;
    TempStream.Write(PAnsiChar(Buffer + Offset)^, BufferSize);
    TempStream.Position := 0;
    CompressedStream := TACRCompressedBLOBStream.Create(TempStream, BLOBDescriptor,
      False);
    Result := TACRLocalBLOBStream.Create(CompressedStream, Cursor, OpenMode,
      FieldNo);
  end; // copy value from TableData
end; // InternalCreateBlobStream


//------------------------------------------------------------------------------
// Write BLOB Field To Record Buffer
//------------------------------------------------------------------------------
procedure TACRTableData.WriteBLOBFieldToRecordBuffer(
        Cursor:       TACRCursor;
        FieldNo:      Integer;
        BLOBStream:   TACRStream
        );
var
    Buffer:             PAnsiChar;
    BufferSize, Offset: Integer;
    ReadBytes:          Integer;
    sz:                 Integer;
{$I ACR_set_null_flag_var.inc}
begin
  Buffer := Cursor.CurrentRecordBuffer;
  if (BLOBStream.Modified) then
  begin
    if (BLOBStream.Size = 0) then
    begin
      // empty stream
      if (IsBLOBModified(Buffer, FieldManager.FieldDefs[FieldNo])) then
        ClearBLOBFieldInRecordBuffer(Buffer, FieldNo);
      Buffer := nil;
      Move(Buffer, PAnsiChar(Cursor.CurrentRecordBuffer + FieldManager.FieldDefs
            [FieldNo].MemoryOffset)^, Sizeof(Buffer));
      SET_NULL_FLAG_ToSet := True;
      SET_NULL_FLAG_BitNo := FieldNo;
      SET_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
      {$I ACR_set_null_flag.inc}
    end
    else
    begin
      if (IsBLOBModified(Buffer, FieldManager.FieldDefs[FieldNo])) then
        ClearBLOBFieldInRecordBuffer(Buffer, FieldNo);
      Offset := Sizeof(TACRPartialBLOBDescriptor);
      BufferSize := Integer(
          TACRCompressedBLOBStream(TACRLocalBLOBStream(BLOBStream).TemporaryStream).CompressedStream.Size)
            + Offset;
      Buffer := MemoryManager.GetMem(BufferSize);
      PACRPartialBLOBDescriptor(Buffer)^.NumBlocks := TACRCompressedBLOBStream
        (TACRLocalBLOBStream(BLOBStream).TemporaryStream).BLOBDescriptor.NumBlocks;
      PACRPartialBLOBDescriptor(Buffer)^.UncompressedSize := TACRCompressedBLOBStream
        (TACRLocalBLOBStream(BLOBStream).TemporaryStream)
        .BLOBDescriptor.UncompressedSize;
      TACRCompressedBLOBStream(TACRLocalBLOBStream(BLOBStream).TemporaryStream)
        .CompressedStream.Position := 0;

      ReadBytes := TACRCompressedBLOBStream(TACRLocalBLOBStream(BLOBStream)
          .TemporaryStream).CompressedStream.Read(PAnsiChar(Buffer + Offset)^,
        (BufferSize - Offset));

      if (ReadBytes <> (BufferSize - Offset)) then
      begin
        if (ACR_ENCRYPTED_DB_USED) then
        begin
          try
            sz := MemoryManager.GetMemoryBufferSize(Buffer);
            FillChar(Buffer^, sz, $00);
          except
          end;
        end;
        MemoryManager.FreeAndNilMem(Buffer);
        raise EACRException.Create(10117, ErrorLCannotReadFromStream,
          [0, (BufferSize - Offset), (BufferSize - Offset), ReadBytes]);
      end;

      // Move(Buffer,PAnsiChar(Cursor.CurrentRecordBuffer +
      // FieldManager.FieldDefs[FieldNo].MemoryOffset)^, sizeof(Buffer));
      // fixed in 12.10 in 64 bit mode all pointers 8 bytes
      {$IFDEF X64_ON}
        PNativeUInt(Cursor.CurrentRecordBuffer +
          FieldManager.FieldDefs[FieldNo].MemoryOffset)^ := NativeUInt(Buffer);
        {$ELSE}
        PCardinal(Cursor.CurrentRecordBuffer +
          FieldManager.FieldDefs[FieldNo].MemoryOffset)^ := Cardinal(Buffer);
      {$ENDIF}
      SetBLOBModified(True, Cursor.CurrentRecordBuffer,
        FieldManager.FieldDefs[FieldNo]);
      SET_NULL_FLAG_ToSet := False;
      SET_NULL_FLAG_BitNo := FieldNo;
      SET_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
      {$I ACR_set_null_flag.inc}
    end; // not empty stream
  end; // Modified
end; // WriteBLOBFieldToRecordBuffer


//------------------------------------------------------------------------------
// clear blob field
//------------------------------------------------------------------------------
procedure TACRTableData.ClearBLOBFieldInRecordBuffer
	(var RecordBuffer: TACRRecordBuffer; FieldNo: Integer);
var
	Buffer: PAnsiChar;
	sz: Integer;
begin
if (FBLOBFieldsPresent) then
begin
    // check null
if (not((PByte(RecordBuffer + (FieldNo div 8))^) and (1 shl (FieldNo mod 8))
			<> 0)) then
begin
Move(PAnsiChar(RecordBuffer + FieldManager.FieldDefs[FieldNo].MemoryOffset)^,
	Buffer, Sizeof(Buffer));
if (Buffer = nil) then
	raise EACRException.Create(10118, ErrorLNilPointer);
if (ACR_ENCRYPTED_DB_USED) then
begin
try
	sz := MemoryManager.GetMemoryBufferSize(Buffer);
	FillChar(Buffer^, sz, $00);
except
end;
end;
MemoryManager.FreeAndNilMem(Buffer);

      // set null
PByte(RecordBuffer + (FieldNo div 8))^ := PByte(RecordBuffer + (FieldNo div 8))
	^ or (1 shl (FieldNo mod 8));
end;
end;
end; // ClearBLOBFieldInRecordBuffer

//------------------------------------------------------------------------------
// clear all blob fields in record buffer - for cancel, delete operation
//------------------------------------------------------------------------------
procedure TACRTableData.ClearBLOBFieldsInRecordBuffer
	(var RecordBuffer: TACRRecordBuffer);
var
	i: Integer;
begin
if (FBLOBFieldsPresent) then
	for i := 0 to FieldManager.FieldDefs.Count - 1 do
		if (IsBLOBFieldType(FieldManager.FieldDefs[i].BaseFieldType)) then
		begin
		ClearBLOBFieldInRecordBuffer(RecordBuffer, i);
		end;
end; // ClearBLOBFieldsInRecordBuffer

//------------------------------------------------------------------------------
// check constraint conditions
//------------------------------------------------------------------------------
procedure TACRTableData.CheckConstraints(Cursor: TACRCursor;
	SessionID: TACRSessionID; NewRecordBuffer: TACRRecordBuffer;
	OldRecordBuffer: TACRRecordBuffer; ToInsert: Boolean;
	CurrentRecordID: TACRRecordID; SkipFKCheck: Boolean = False);
begin
if (FConstraintManager.Empty) then
	Exit;
FConstraintManager.CheckConstraints(Cursor, SessionID, NewRecordBuffer,
	OldRecordBuffer, ToInsert, CurrentRecordID, SkipFKCheck);
end; // CheckConstraints

//------------------------------------------------------------------------------
// show current record
//------------------------------------------------------------------------------
procedure TACRTableData.ShowRecord(Cursor: TACRCursor);
var
	NavigationInfo: TACRNavigationInfo;
	RecordVisible: Boolean;
	Size: Integer;
begin
Size := GetRecordBufferSize;
Move(Cursor.CurrentRecordBuffer^, Cursor.FTempRecordBuffer^, Size);
try
	NavigationInfo.IndexID := Cursor.IndexID;
	NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
	NavigationInfo.FirstPosition := False;
	NavigationInfo.LastPosition := False;
	NavigationInfo.RecordID := Cursor.CurrentRecordID;
	NavigationInfo.SessionID := Cursor.Session.SessionID;
	NavigationInfo.GetRecordMode := grmPrior;
	repeat
		InternalGetRecordBuffer(Cursor.Session.SessionID, NavigationInfo);
		if (NavigationInfo.GetRecordResult <> grrOK) then
			break;
		RecordVisible := IsRecordVisible(Cursor);
	until (RecordVisible);
	if (NavigationInfo.GetRecordResult <> grrOK) then
		TACRRecordBitmap(Cursor.RecordBitmap).InsertVisibleRecord
			(Cursor.CurrentRecordID, Cursor.CurrentRecordID, True, False)
	else
		TACRRecordBitmap(Cursor.RecordBitmap).InsertVisibleRecord
			(Cursor.CurrentRecordID, NavigationInfo.RecordID, False, False);
finally
	Move(Cursor.FTempRecordBuffer^, Cursor.CurrentRecordBuffer^, Size);
end;
end; // ShowRecord

//------------------------------------------------------------------------------
// start record editing
//------------------------------------------------------------------------------
procedure TACRTableData.EditRecord(Cursor: TACRCursor);
begin ;
end; // EditRecord

//------------------------------------------------------------------------------
// ñlear temporary blob values created between Insert / Edit and Post / Cancel
//------------------------------------------------------------------------------
procedure TACRTableData.ClearTemporaryBLOBValues(Cursor: TACRCursor);
var
	i: Integer;
	RecordBuffer: TACRRecordBuffer;
begin
RecordBuffer := Cursor.CurrentRecordBuffer;
if (FBLOBFieldsPresent) then
	for i := 0 to FFieldManager.FieldDefs.Count - 1 do
		if (IsBLOBFieldType(FFieldManager.FieldDefs[i].BaseFieldType)) then
			if (IsBLOBModified(Cursor.CurrentRecordBuffer,
					FFieldManager.FieldDefs[i])) then
				ClearBLOBFieldInRecordBuffer(RecordBuffer, i);
end; // CancelRecord


//------------------------------------------------------------------------------
// ñlear temporary blob values created between Insert / Edit and Post / Cancel
//------------------------------------------------------------------------------
procedure TACRTableData.SetBLOBValuesModified(Modified: Boolean; Cursor: TACRCursor);
var
	  RecordBuffer: TACRRecordBuffer;
{$I ACR_check_null_flag_var.inc}
begin
  RecordBuffer := Cursor.CurrentRecordBuffer;
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  if (FBLOBFieldsPresent) then
    for CHECK_NULL_FLAG_BitNo := 0 to FFieldManager.FieldDefs.Count - 1 do
      if (IsBLOBFieldType(FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
      begin
        {$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
          SetBLOBModified(Modified, Cursor.CurrentRecordBuffer,
            FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
      end;
end; // SetBLOBValuesModified


//------------------------------------------------------------------------------
// cancel record inserting or editing
//------------------------------------------------------------------------------
procedure TACRTableData.CancelRecord(Cursor: TACRCursor; ToInsert: Boolean);
begin
  ClearTemporaryBLOBValues(Cursor);
end; // CancelRecord


//------------------------------------------------------------------------------
// delete all visible records
//------------------------------------------------------------------------------
procedure TACRTableData.DeleteVisibleRecords(Cursor: TACRCursor);
var
    i, RecCount:      TACRRecordNo;
	  NavigationInfo:   TACRNavigationInfo;
	  Filtered:         Boolean;
begin
  NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
  NavigationInfo.IndexID := INVALID_OBJECT_ID;
  Filtered := TACRRecordBitmap(Cursor.RecordBitmap).Active;
  Cursor.FirstPosition := False;
  Cursor.LastPosition := False;
  if (Filtered) then
  begin
    RecCount := TACRRecordBitmap(Cursor.RecordBitmap).GetRecordCount;
    NavigationInfo.GetRecordMode := grmCurrent;
    NavigationInfo.FirstPosition := False;
    NavigationInfo.LastPosition := False;
  end // filtered
  else
  begin
    RecCount := InternalGetRecordCount;
    NavigationInfo.GetRecordMode := grmNext;
    NavigationInfo.FirstPosition := True;
    NavigationInfo.LastPosition := False;
  end; // not filtered - all records are visible
  i := 1;
  while (i <= RecCount) do
  begin
    if (Filtered) then
      NavigationInfo.RecordID := TACRRecordBitmap(Cursor.RecordBitmap).GetRecordIDByRecNo(i);
    InternalGetRecordBuffer(Cursor.Session.SessionID, NavigationInfo);
    Cursor.CurrentRecordID := NavigationInfo.RecordID;
    if (NavigationInfo.GetRecordResult <> grrOK) then
      raise EACRException.Create(11466, ErrorLCannotLoadRecord,
        [NavigationInfo.RecordID.pageNo, NavigationInfo.RecordID.PageItemNo,FTableName]);
    if (FConstraintManager.ConstraintDefs.ForeignKeysActionsUpdateExists) then
      ExecuteForeignKeyActions(Cursor, False);
    if (FIndexManager.IndexDefs.Count > 0) then
      FIndexManager.DeleteRecord(Cursor);
    ClearBLOBFieldsInRecordBuffer(NavigationInfo.RecordBuffer);
    FRecordManager.DeleteRecord(Cursor.CurrentRecordID, Cursor.Session.SessionID);
    Inc(i);
  end;
end; // DeleteVisibleRecords


//------------------------------------------------------------------------------
// update all visible records
//------------------------------------------------------------------------------
procedure TACRTableData.UpdateVisibleRecords(
                                              Cursor:         TACRCursor;
                                              FieldNames:     TACRWideStringList;
                                              values:         array of TACRVariant;
                                              SkipFKCheck:    Boolean = False
                                             );
var
    j, FieldNo:       Integer;
    i, RecCount:      TACRRecordNo;
    NavigationInfo:   TACRNavigationInfo;
    Buffer:           PAnsiChar;
    Filtered:         Boolean;
begin
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('> TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
);
try
{$ENDIF}
  j := Length(values);
  if ((j <= 0) or (j <> FieldNames.Count)) then
    raise EACRException.Create(11448, ErrorLInvalidItemNumber,
      [j, FieldNames.Count]);
  NavigationInfo.RecordBuffer := Cursor.CurrentRecordBuffer;
  NavigationInfo.IndexID := INVALID_OBJECT_ID;
  Filtered := TACRRecordBitmap(Cursor.RecordBitmap).Active;
  Cursor.FirstPosition := False;
  Cursor.LastPosition := False;
  if (Filtered) then
  begin
    RecCount := TACRRecordBitmap(Cursor.RecordBitmap).GetRecordCount;
    NavigationInfo.GetRecordMode := grmCurrent;
    NavigationInfo.FirstPosition := False;
    NavigationInfo.LastPosition := False;
  end // filtered
  else
  begin
    RecCount := InternalGetRecordCount;
    NavigationInfo.GetRecordMode := grmNext;
    NavigationInfo.FirstPosition := True;
    NavigationInfo.LastPosition := False;
  end; // not filtered - all records are visible
  Cursor.EditRecordBuffer := Cursor.AllocateRecordBuffer;
  try
    i := 1;
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('1 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
);
{$ENDIF}
    while (i <= RecCount) do
    begin
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('2 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
);
{$ENDIF}
      if (Filtered) then
        NavigationInfo.RecordID := TACRRecordBitmap(Cursor.RecordBitmap).GetRecordIDByRecNo(i);
      InternalGetRecordBuffer(Cursor.Session.SessionID, NavigationInfo);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('3 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
);
{$ENDIF}
      Cursor.CurrentRecordID := NavigationInfo.RecordID;
      if (NavigationInfo.GetRecordResult <> grrOK) then
        raise EACRException.Create(11449, ErrorLCannotLoadRecord,
          [NavigationInfo.RecordID.pageNo, NavigationInfo.RecordID.PageItemNo,
          FTableName]);
      Move(Cursor.CurrentRecordBuffer^, Cursor.EditRecordBuffer^,
        Cursor.RecordBufferSize);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('4 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      for j := 0 to FieldNames.Count - 1 do
      begin
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('5 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
        FieldNo := Cursor.VisibleFieldDefs.GetDefNumberByName(FieldNames.Strings[j]);
        if (FieldNo < 0) then
          raise EACRException.Create(11447, ErrorLCannotFindFieldInTable,
            [FieldNames.Strings[j], FTableName]);
        Cursor.SetFieldValue(values[j], FieldNo, False);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('6 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      end;
      CheckConstraints(Cursor, Cursor.Session.SessionID,
        Cursor.CurrentRecordBuffer, Cursor.FEditRecordBuffer, False,
        Cursor.CurrentRecordID, SkipFKCheck);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('6.1 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      if (Cursor.IsViewWithCheckOption) then
       if (not IsRecordVisible(Cursor)) then
         raise EACRException.Create(12608,ErrorLCannotUpdateRecordInViewWithCheckOption,[FTableName,Cursor.ViewName]);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('7 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      if (FConstraintManager.ConstraintDefs.ForeignKeysActionsUpdateExists) then
      begin
        ExecuteForeignKeyActions(Cursor, True);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('7.5 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      end;
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('8 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      if (FIndexManager.IndexDefs.Count > 0) then
        FIndexManager.UpdateRecord(Cursor);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('9 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      FRecordManager.UpdateRecord(Cursor.CurrentRecordBuffer,
        Cursor.CurrentRecordID, Cursor.Session.SessionID);
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('10 TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+'i = '+IntToStr(i)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'Filtered = '+BoolToStr(Filtered,True)
+#13#10+'RecordID = ( '+IntToStr(NavigationInfo.RecordID.PageNo)+' . '+IntToStr(NavigationInfo.RecordID.PageItemNo)+' )'
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
);
{$ENDIF}
      Inc(i);
    end;
  finally
    Buffer := Cursor.EditRecordBuffer;
    Cursor.FreeRecordBuffer(Buffer);
    Cursor.EditRecordBuffer := nil;
  end;
{$IFDEF DEBUG_TRACE_UpdateVisibleRecords}
aaWriteToLog('< TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
);
except
 on e: Exception do
 begin
aaWriteToLog('Error in TACRTableData.UpdateVisibleRecords - ClassName = '+Self.ClassName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'SessionID = '+IntToStr(Cursor.Session.SessionID)
+#13#10+e.Message
);
 end;
end;
{$ENDIF}
end; // UpdateVisibleRecords


//------------------------------------------------------------------------------
// return record count
//------------------------------------------------------------------------------
function TACRTableData.GetRecordCount(Cursor: TACRCursor;
	InternalCall: Boolean): TACRRecordNo;
begin
  if (Cursor.IsViewRestricted) then
  begin
    if (not TACRRecordBitmap(Cursor.RecordBitmap).Active) then
      BuildCursorRecordBitmap(Cursor);
    Result := TACRRecordBitmap(Cursor.RecordBitmap).GetRecordCount;
  end
  else
  begin
    Result := InternalGetRecordCount;
  end;
end; // GetRecordCount


//------------------------------------------------------------------------------
// set rec no
//------------------------------------------------------------------------------
procedure TACRTableData.SetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo);
var
	NavigationInfo: TACRNavigationInfo;
	RecCount: TACRRecordNo;
begin
RecCount := GetRecordCount(Cursor, True);
if (RecCount > 0) then
begin
if (RecNo >= RecCount) then
	RecNo := RecCount;
Cursor.FirstPosition := False;
Cursor.LastPosition := False;
if (Cursor.IsViewRestricted) then
begin
Cursor.CurrentRecordID := TACRRecordBitmap(Cursor.RecordBitmap)
	.GetRecordIDByRecNo(RecNo);
end
else
	if (Cursor.IsIndexApplied) then
	begin
	NavigationInfo.RecordBuffer := MemoryManager.AllocMem(GetRecordBufferSize);
	try
		Cursor.CurrentRecordID := FIndexManager.OpenIndex(Cursor.IndexID)
			.GetRecordIDByRecNo(Cursor.Session.SessionID, RecNo,
			Cursor.RecordBitmap);
	finally
		MemoryManager.FreeAndNilMem(NavigationInfo.RecordBuffer);
	end;
	end // index applied
	else
		InternalSetRecNo(Cursor, RecNo);
end; // get recno
end; // SetRecNo

//------------------------------------------------------------------------------
// return rec no
//------------------------------------------------------------------------------
function TACRTableData.GetRecNo(Cursor: TACRCursor): TACRRecordNo;
var
	NavigationInfo: TACRNavigationInfo;
begin
if (Cursor.FirstPosition) or (Cursor.LastPosition) or (GetRecordCount(Cursor,
		True) = 0) then
	Result := -1
else
begin
if (Cursor.IsViewRestricted) then
	Result := TACRRecordBitmap(Cursor.RecordBitmap).GetRecNoByRecordID
		(Cursor.CurrentRecordID)
else
	if (Cursor.IsIndexApplied) then
	begin
	NavigationInfo.RecordBuffer := MemoryManager.AllocMem(GetRecordBufferSize);
	try
		NavigationInfo.FirstPosition := False;
		NavigationInfo.LastPosition := False;
		NavigationInfo.RecordID := Cursor.CurrentRecordID;
		NavigationInfo.GetRecordMode := grmCurrent;
		InternalGetRecordBuffer(Cursor.Session.SessionID, NavigationInfo);
		if (NavigationInfo.GetRecordResult <> grrOK) then
			Result := -1
		else
			Result := FIndexManager.OpenIndex(Cursor.IndexID).GetRecNoByRecordID
				(Cursor.Session.SessionID, Cursor.CurrentRecordID,
				NavigationInfo.RecordBuffer, Cursor.RecordBitmap);
	finally
		MemoryManager.FreeAndNilMem(NavigationInfo.RecordBuffer);
	end;
	end // index applied
	else
		Result := InternalGetRecNo(Cursor);
end; // get recno
end; // GetRecNo

//------------------------------------------------------------------------------
// get record count
//------------------------------------------------------------------------------
function TACRTableData.InternalGetRecordCount: TACRRecordNo;
begin
if (FRecordManager = nil) then
	Result := 0
else
	Result := FRecordManager.GetRecordCount;
end; // InternalGetRecordCount

//------------------------------------------------------------------------------
// return last auto inc value
//------------------------------------------------------------------------------
function TACRTableData.LastAutoincValue(FieldNo: Integer;
	Session: TACRBaseSession): Int64;
begin
Result := 0;
end; // LastAutoincValue

//------------------------------------------------------------------------------
// set autoinc value
//------------------------------------------------------------------------------
procedure TACRTableData.SetLastAutoincValue(Value: Int64; FieldNo: Integer;
	Cursor: TACRCursor);
begin
end; // SetLastAutoincValue


//------------------------------------------------------------------------------
// add page to the page manager
//------------------------------------------------------------------------------
function TACRTableData.AddPage(SessionID: TACRSessionID;
  // state type of the locked object that calls this method
	StateType: TACRDBStateType;
  // current state of the locked object that calls this method
	State: TACRState;
  // if true - page will not be used without calling GetPage
	DoNotUse: Boolean = False): TACRPage;
begin
Result := FCache.AddPage(SessionID, StateType, State, DoNotUse)
end; // AddPage

//------------------------------------------------------------------------------
// mark page as deleted - move to deleted list of the cache
//------------------------------------------------------------------------------
procedure TACRTableData.RemovePage(SessionID: TACRSessionID;
	pageNo: TACRPageNo; StateType: TACRDBStateType; State: TACRState);
begin
FCache.RemovePage(SessionID, pageNo, StateType, State);
end; // RemovePage

//------------------------------------------------------------------------------
// add pages to the page manager
//------------------------------------------------------------------------------
procedure TACRTableData.AddPages(
  // place page numbers of new allocated pages at the end of the array
	Pages: TACRPageArray;
  // how much pages to add
	NumPagesToAdd: Cardinal;
  // pages must be in consecutive order (n,n+1,n+2...)
	ConsecutiveOrder: Boolean; SessionID: TACRSessionID;
  // state type of the locked object that calls this method
	StateType: TACRDBStateType;
  // current state of the locked object that calls this method
	State: TACRState;
  // if true - page will not be used without calling GetPage
	DoNotUse: Boolean = False);
begin
FCache.AddPages(Pages, NumPagesToAdd, ConsecutiveOrder, SessionID, StateType,
	State, DoNotUse);
end; // AddPages

//------------------------------------------------------------------------------
// delete pages in the page manager
//------------------------------------------------------------------------------
procedure TACRTableData.RemovePages(Pages: TACRPageArray;
	SessionID: TACRSessionID;
  // state type of the locked object that calls this method
	StateType: TACRDBStateType; State: TACRState; NumPagesFromEnd: Cardinal = 0);
begin
FCache.RemovePages(Pages, SessionID, StateType, State, NumPagesFromEnd);
end; // RemovePages

//------------------------------------------------------------------------------
// read existing page from cache or from PageManager (disk / memory / temporary)
//------------------------------------------------------------------------------
function TACRTableData.GetPage(SessionID: TACRSessionID; pageNo: TACRPageNo;
  // state type of the locked object that calls this method
	StateType: TACRDBStateType;
  // current state of the locked object that calls this method
	State: TACRState;
  // read current page data from page manager if not in cache
	ReadPage: Boolean = True;
  // this page will be updated
	UpdatePage: Boolean = False;
  // the page should be updated and original will be copied to shared pages
	MakeCopy: Boolean = False): TACRPage;
begin
  {
    if (FActiveTransactionSessionID <> INVALID_SESSION_ID) then
    Result := FCache.GetPage(SessionID,PageNo,StateType,State,
    ReadPage,UpdatePage,True)
    else
  }
Result := FCache.GetPage(SessionID, pageNo, StateType, State, ReadPage,
	UpdatePage, MakeCopy);
end; // GetPage

//------------------------------------------------------------------------------
// page is read or updated
//------------------------------------------------------------------------------
procedure TACRTableData.PutPage(Page: TACRPage);
begin
FCache.PutPage(Page);
end; // PutPage

//------------------------------------------------------------------------------
// must be called before updating page data
//------------------------------------------------------------------------------
procedure TACRTableData.UpdatePage(SessionID: TACRSessionID; Page: TACRPage;
  // state type of the locked object that calls this method
	StateType: TACRDBStateType;
  // current state of the locked object that calls this method
	State: TACRState;
  // the page should be updated and original will be copied to shared pages
	MakeCopy: Boolean = False);
begin
  {
    if (FActiveTransactionSessionID <> INVALID_SESSION_ID) then
    FCache.UpdatePage(SessionID,Page,StateType,State,True);
    else
  }
FCache.UpdatePage(SessionID, Page, StateType, State, MakeCopy);
end; // UpdatePage

//------------------------------------------------------------------------------
// apply all changes made by active session
//------------------------------------------------------------------------------
procedure TACRTableData.ApplyChanges(
  // current state of the locked object that calls this method
	State1: TACRState;
  // StateType2 is for table metadata state only
	StateType2: TACRDBStateType = dbstNone;
  // State2 is for table metadata state only
	State2: TACRState = 0);
begin
FCache.ApplyChanges(State1, StateType2, State2);
end; // ApplyChanges

//------------------------------------------------------------------------------
// cancel all changes made by active session
//------------------------------------------------------------------------------
procedure TACRTableData.CancelChanges;
begin
FCache.CancelChanges;
end; // CancelChanges

//------------------------------------------------------------------------------
// return true if other session already opened the table
//------------------------------------------------------------------------------
function TACRTableData.CheckCannotOpenExclusive(Cursor: TACRCursor): Boolean;
var
	i: Integer;
	curs: TACRCursor;
begin
Result := False;
if (Cursor <> nil) then
	if (Cursor.Exclusive) then
	begin
	LockCursorList(False);
	try
		for i := 0 to FCursorList.Count - 1 do
		begin
		curs := TACRCursor(FCursorList.Items[i]);
		if ((curs.Session <> nil) and (Cursor.Session <> nil)) then
			if (curs.Session.SessionID <> Cursor.Session.SessionID) then
			begin
			Result := True;
			Exit;
			end;
		end;
	finally
		UnlockCursorList;
	end;
	end;
end; // CheckCannotOpenExclusive




////////////////////////////////////////////////////////////////////////////////
//
// TACRTableLockManager
//
// manages table locking - both disk and memory engines
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRTableLockManager.Lock(Exclusive: Boolean);
begin
FThreadSync.Lock(Exclusive);
end; // Lock

//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRTableLockManager.Unlock;
begin
FThreadSync.Unlock;
end; // Unlock

//------------------------------------------------------------------------------
// lock transactions
//------------------------------------------------------------------------------
procedure TACRTableLockManager.LockTransactions(Exclusive: Boolean);
begin
FThreadSyncTransactions.Lock(Exclusive);
end; // LockTransactions

//------------------------------------------------------------------------------
// unlock transactions
//------------------------------------------------------------------------------
procedure TACRTableLockManager.UnlockTransactions;
begin
FThreadSyncTransactions.Unlock;
end; // UnlockTransactions

//------------------------------------------------------------------------------
// incrememnt lock counter for LockTable
//------------------------------------------------------------------------------
procedure TACRTableLockManager.IncLockCounter
	(PSessionLock: PACRSessionLockInfo);
begin
case PSessionLock^.WaitLockType of
ltX:
begin
PSessionLock^.LockX := True;
FTableLockInfo.LockXSessionID := PSessionLock^.SessionID;
end;
ltIS:
begin
Inc(PSessionLock^.NumLocksIS);
Inc(FTableLockInfo.NumLockIS);
end;
ltS:
begin
Inc(PSessionLock^.NumLocksS);
Inc(FTableLockInfo.NumLockS);
end;
ltIRW:
begin
Inc(PSessionLock^.NumLocksIRW);
FTableLockInfo.LockIRWSessionID := PSessionLock^.SessionID;
end;
ltRW:
begin
PSessionLock^.LockRW := True;
FTableLockInfo.LockRWSessionID := PSessionLock^.SessionID;
end
else
begin
      // ltU
PSessionLock^.LockU := True;
Inc(FTableLockInfo.NumLockU);
end;
end;
end; // IncLockCounter

//------------------------------------------------------------------------------
// decrememnt lock counter for LockTable
//------------------------------------------------------------------------------
procedure TACRTableLockManager.DecLockCounter
	(PSessionLock: PACRSessionLockInfo; UnlockAll: Boolean);
begin
case PSessionLock^.WaitLockType of
ltX:
begin
PSessionLock^.LockX := False;
FTableLockInfo.LockXSessionID := INVALID_SESSION_ID;
end;
ltIS:
begin
if (UnlockAll) then
begin
if (FTableLockInfo.NumLockIS > PSessionLock^.NumLocksIS) then
	Dec(FTableLockInfo.NumLockIS, PSessionLock^.NumLocksIS)
else
	FTableLockInfo.NumLockIS := 0;
PSessionLock^.NumLocksIS := 0;
end
else
begin
if (PSessionLock^.NumLocksIS > 0) then
	Dec(PSessionLock^.NumLocksIS);
if (FTableLockInfo.NumLockIS > 0) then
	Dec(FTableLockInfo.NumLockIS);
end;
end;
ltS:
begin
if (UnlockAll) then
begin
if (FTableLockInfo.NumLockS > PSessionLock^.NumLocksS) then
	Dec(FTableLockInfo.NumLockS, PSessionLock^.NumLocksS)
else
	FTableLockInfo.NumLockS := 0;
PSessionLock^.NumLocksS := 0;
end
else
begin
if (PSessionLock^.NumLocksS > 0) then
	Dec(PSessionLock^.NumLocksS);
if (FTableLockInfo.NumLockS > 0) then
	Dec(FTableLockInfo.NumLockS);
end;
end;
ltIRW:
begin
if (UnlockAll) then
begin
FTableLockInfo.LockIRWSessionID := INVALID_SESSION_ID;
PSessionLock^.NumLocksIRW := 0;
end
else
begin
if (PSessionLock^.NumLocksIRW > 0) then
	Dec(PSessionLock^.NumLocksIRW);
if (PSessionLock^.NumLocksIRW = 0) then
	FTableLockInfo.LockIRWSessionID := INVALID_SESSION_ID;
end;
end;
ltRW:
begin
PSessionLock^.LockRW := False;
FTableLockInfo.LockRWSessionID := INVALID_SESSION_ID;
end
else
begin
      // ltU
PSessionLock^.LockU := False;
if (FTableLockInfo.NumLockU > 0) then
	Dec(FTableLockInfo.NumLockU);
end;
end;
end; // DecLockCounter

//------------------------------------------------------------------------------
// return wait time for sleeping after lock failed
//------------------------------------------------------------------------------
function TACRTableLockManager.GetLockWaitTime(const CurrentWaitTime: Cardinal)
	: Cardinal;
{
  var ElapsedWaitTime: Cardinal;
  t2,t4:           Cardinal;
}
var
	level, level2: Byte;
begin
level := ACRGetWaitLevel(CurrentWaitTime, FMaxWaitLockTime);
level2 := ACR_MAX_WAIT_LEVEL shr 1;
  // if level <= 1/2 from max level
if (level <= level2) then
	Result := FMaxWaitLockTime div (ACR_MAX_WAIT_LEVEL + 1) + 1
else
  // if level <= 3/4
	if (level <= (ACR_MAX_WAIT_LEVEL - (level2 shr 1))) then
		Result := FNormalDelay
	else
		Result := FMinDelay;

  {
    // elapsed time >= 3/4 max wait time
    Result := FMinDelay;
    ElapsedWaitTime := ACRGetTickCountDiff(aaGetTickCount,CurrentWaitTime);
    t2 := (FMaxWaitLockTime shr 1);
    if (ElapsedWaitTime < t2) then
    // elapsed time < 1/2 max wait time
    Result := FNormalDelay
    else
    begin
    t4 := t2 + (t2 shr 1);
    if (ElapsedWaitTime < t4) then
    // elapsed time < 3/4 max wait time
    Result := FShortDelay;
    end;
  }
  // Result := 0;
{$IFDEF DEBUG_TRACE_TACRTableLocksManager_GetLockWaitTime}
aaWriteToLog('TACRTableLockManager.GetLockWaitTime finished.' + #13#10 +
		'Current wait time = ' + IntToStr(CurrentWaitTime)
		+ #13#10 + 'Elapsed wait time = ' + IntToStr(ElapsedWaitTime)
		+ #13#10 + 't2 = ' + IntToStr(t2) + #13#10 + 't4 = ' + IntToStr(t4)
		+ #13#10 + 'Result = ' + IntToStr(Result));
{$ENDIF}
end; // GetLockWaitTime

//------------------------------------------------------------------------------
// return true if we cannot lock table because of more priority sessions
// already locked it in the current process
//------------------------------------------------------------------------------
function TACRTableLockManager.IsMorePriorityLockExists(PSessionLock: PACRSessionLockInfo): Boolean;
var
	WaitLevel, CurWaitLevel: 	Byte;
	i: 												Integer;
	PCurSessionLock: 					PACRSessionLockInfo;
begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_IsMorePriorityLockExists}
aaWriteToLog('> TACRTableLockManager.IsMorePriorityLockExists' + #13#10 +	'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));
{$ENDIF}
  Result := False;
  WaitLevel := ACRGetWaitLevel(PSessionLock^.WaitTime, FMaxWaitLockTime);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_IsMorePriorityLockExists}
ACRWriteSessionLockInfo(PSessionLock, FMaxWaitLockTime);aaWriteToLog('1 TACRTableLockManager.IsMorePriorityLockExists' + #13#10 + 'FWaitingSessionLocks.Count = ' + IntToStr(FWaitingSessionLocks.Count));
{$ENDIF}
  for i := 0 to FWaitingSessionLocks.Count - 1 do
  begin
    PCurSessionLock := FWaitingSessionLocks.Items[i];
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_IsMorePriorityLockExists}
ACRWriteSessionLockInfo(PCurSessionLock, FMaxWaitLockTime);aaWriteToLog('2 TACRTableLockManager.IsMorePriorityLockExists' + #13#10 +'i = ' + IntToStr(i));
{$ENDIF}
    if (PCurSessionLock <> PSessionLock) then
      if (not ACRIsLockPriorityHigher(PSessionLock, PCurSessionLock)) then
        if (not ACRIsLockCompatible(PSessionLock, PCurSessionLock)) then
        begin
          CurWaitLevel := ACRGetWaitLevel(PCurSessionLock^.WaitTime, FMaxWaitLockTime);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_IsMorePriorityLockExists}
ACRWriteSessionLockInfo(PCurSessionLock, FMaxWaitLockTime);aaWriteToLog('3 TACRTableLockManager.IsMorePriorityLockExists' + #13#10 +'i = ' + IntToStr(i) + #13#10 + 'WaitLevel = ' + IntToStr(WaitLevel)+ #13#10 + 'CurWaitLevel = ' + IntToStr(CurWaitLevel));
{$ENDIF}
          if (CurWaitLevel > WaitLevel) then
          begin
            Result := True;
            break;
          end;
        end;
  end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_IsMorePriorityLockExists}
aaWriteToLog('< TACRTableLockManager.IsMorePriorityLockExists' + #13#10 +	'Result = ' + BoolToStr(Result, True));
{$ENDIF}
end; // IsMorePriorityLockExists


//------------------------------------------------------------------------------
// return true if this lock cannot be applied due to conflict with existing locks
//------------------------------------------------------------------------------
function TACRTableLockManager.IsLockCanBeApplied(PSessionLock: PACRSessionLockInfo): Boolean;
var
    i: 								Integer;
    PCurSessionLock: 	PACRSessionLockInfo;
begin
  Result := True;
{$IFDEF DEBUG_TRACE_TACRTableLockManager_IsLockCanBeApplied}
aaWriteToLog('> TACRTableLockManager.IsLockCanBeApplied');
ACRWriteSessionLockInfo(PSessionLock,FMaxWaitLockTime);
ACRWriteTableLockInfo(FTableLockInfo);
{$ENDIF}
  // check if we can apply new lock
  case PSessionLock^.WaitLockType of
  ltX:
    begin
      // false if there is any other X lock
      Result := (FTableLockInfo.LockXSessionID = INVALID_SESSION_ID) and (FTableLockInfo.NumLockIS <= PSessionLock^.NumLocksIS);
    end;
  ltIS:
    begin
      if (PSessionLock^.NumLocksIS = 0) then
        Result := (FTableLockInfo.LockXSessionID = INVALID_SESSION_ID);
    end;
  ltS:
    begin
      if (PSessionLock^.NumLocksS = 0) then
        Result := (FTableLockInfo.LockRWSessionID = INVALID_SESSION_ID);
    end;
  ltIRW:
    begin
      if (PSessionLock^.NumLocksIRW = 0) then
        Result := (FTableLockInfo.LockIRWSessionID = INVALID_SESSION_ID) and
          (FTableLockInfo.LockRWSessionID = INVALID_SESSION_ID);
    end;
  ltRW:
    begin
      Result := (FTableLockInfo.LockRWSessionID = INVALID_SESSION_ID);
      if (Result) then
      begin
        if (FTableLockInfo.LockIRWSessionID <> INVALID_SESSION_ID) then
          Result := (FTableLockInfo.LockIRWSessionID = PSessionLock^.SessionID);
        if (Result) then
          Result := (FTableLockInfo.NumLockS = 0) or (PSessionLock^.NumLocksS > 0);
        if (Result and (FTableLockInfo.NumLockS > 0)) then
          begin
            Lock(False);
            try
              // fixed in v.5.10
              for i := 0 to FSessionLocks.Count - 1 do
              begin
                PCurSessionLock := FSessionLocks.Items[i];
                if (PCurSessionLock^.SessionID <> PSessionLock^.SessionID) then
                  if (PCurSessionLock^.NumLocksS > 0) then
                  begin
                    Result := False;
                    Exit;
                  end;
              end;
            finally
              Unlock;
            end;
          end;
      end;
    end
  else
    begin
          // ltU
      Lock(False);
      try
        for i := 0 to FSessionLocks.Count - 1 do
          if (PSessionLock^.SessionID <> i) then
          begin
            PCurSessionLock := FSessionLocks.Items[i];
            if (PCurSessionLock^.LockU) then
              if ((PCurSessionLock^.LockedRecordID.pageNo =
                    PSessionLock^.LockedRecordID.pageNo) and
                  (PCurSessionLock^.LockedRecordID.PageItemNo =
                    PSessionLock^.LockedRecordID.PageItemNo)) then
              begin
                Result := False;
                Exit;
              end;
	        end;
      finally
        Unlock;
      end;
    end;
  end;
{$IFDEF DEBUG_TRACE_TACRTableLockManager_IsLockCanBeApplied}
aaWriteToLog('< TACRTableLockManager.IsLockCanBeApplied, Result = '+BoolToStr(Result,True));
ACRWriteSessionLockInfo(PSessionLock,FMaxWaitLockTime);
ACRWriteTableLockInfo(FTableLockInfo);
{$ENDIF}
end; // IsLockCanBeApplied


//------------------------------------------------------------------------------
// if we already have this lock - ok, just increment counter
//------------------------------------------------------------------------------
function TACRTableLockManager.IsLockAlreadyApplied
	(PSessionLock: PACRSessionLockInfo): Boolean;
begin
  if (PSessionLock^.LockX) then
    Result := True
  else
    Result := ((PSessionLock^.WaitLockType = ltIS) and (PSessionLock^.NumLocksIS > 0)) or
				      ((PSessionLock^.WaitLockType = ltRW) and PSessionLock^.LockRW) or
      				((PSessionLock^.WaitLockType = ltIRW) and ((PSessionLock^.NumLocksIRW > 0) or PSessionLock^.LockRW)) or
              ((PSessionLock^.WaitLockType = ltS) and ((PSessionLock^.NumLocksS > 0) or (PSessionLock^.NumLocksIRW > 0) or PSessionLock^.LockRW));
end; // IsLockAlreadyApplied


//------------------------------------------------------------------------------
// try to lock the table until time limit set by FMaxWaitLockTime
//------------------------------------------------------------------------------
function TACRTableLockManager.InternalLockTable(SessionID: TACRSessionID;
	LockType: TACRLockType; PRecordID: PACRRecordID;
	var PSessionLock: PACRSessionLockInfo): Boolean;
var
	i: Integer;
	bUseLockTableSync: Boolean;
begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter4);
aaStartTime(time4);
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('> TACRTableLockManager.InternalLockTable, TableName = ' +LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)+ #13#10 + 'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));
WriteAllLocks;
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter5);
aaStartTime(time5);
{$ENDIF}
	Result := True;
	Lock(True);
	try
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('1. TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));
{$ENDIF}
		if (PSessionLock = nil) then
			for i := 0 to FSessionLocks.Count - 1 do
				if (PACRSessionLockInfo(FSessionLocks.Items[i])^.SessionID = SessionID) then
        begin
          PSessionLock := PACRSessionLockInfo(FSessionLocks.Items[i]);
          break;
				end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('2. TACRTableLockManager.InternalLockTable' + #13#10 + 'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' + ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));
{$ENDIF}
      // if session has no locks - create new session lock item
		if (PSessionLock = nil) then
      begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter13);
aaStartTime(time13);
{$ENDIF}
        // new item
        New(PSessionLock);
        FillChar(PSessionLock^, Sizeof(TACRSessionLockInfo), $00);
        PSessionLock^.SessionID := SessionID;
        PSessionLock^.IsWaiting := True;
        PSessionLock^.WaitLockType := LockType;
        PSessionLock^.WaitTime := aaGetTickCount;
        FSessionLocks.Add(PSessionLock);
        FWaitingSessionLocks.Add(PSessionLock);
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time13);
{$ENDIF}
      end // if session has no locks - create new session lock item
		else
      begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter16);
aaStartTime(time16);
{$ENDIF}
        // item found
        if (not PSessionLock^.IsWaiting) then
          begin
            PSessionLock^.IsWaiting := True;
            PSessionLock^.WaitLockType := LockType;
            if (PRecordID <> nil) and (LockType = ltU) then
              PSessionLock^.LockedRecordID := PRecordID^;
            PSessionLock^.WaitTime := aaGetTickCount;
            FWaitingSessionLocks.Add(PSessionLock);
          end;
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time16);
{$ENDIF}
      end; // item found
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('3. TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));ACRWriteSessionLockInfo(PSessionLock, FMaxWaitLockTime);
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStartTime(time6);
{$ENDIF}
      // if we already have this lock - ok, just increment counter
		Result := IsLockAlreadyApplied(PSessionLock);
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time6);
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('4. TACRTableLockManager.InternalLockTable' + #13#10 +	'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +	ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
		if (not Result) then
		begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter7);
aaStartTime(time7);
{$ENDIF}
        // check if lock allowed
      Result := IsLockCanBeApplied(PSessionLock);
{$IFDEF DEBUG_LOCKTABLE_TIME}
		aaStopTime(time7);
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('4.1 TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8) + #13#10 + 'Result = ' + BoolToStr(Result, True) + #13#10 + 'FWaitingSessionLocks.Count = ' + IntToStr(FWaitingSessionLocks.Count));
{$ENDIF}
		if (Result) then
			if (FWaitingSessionLocks.Count > 1) then
			begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter8);
aaStartTime(time8);
{$ENDIF}
				Result := not IsMorePriorityLockExists(PSessionLock);
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time8);
{$ENDIF}
			end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('4.2 TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8) + #13#10 + 'Result = ' + BoolToStr(Result, True) + #13#10 + 'FWaitingSessionLocks.Count = ' + IntToStr(FWaitingSessionLocks.Count));
{$ENDIF}
		if (Result) then
		begin
      if (FFileServer and (@FLockTableInFileServer <> nil)) then
      begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter9);
aaStartTime(time9);
{$ENDIF}
	      Result := FLockTableInFileServer(PSessionLock);
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time9);
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('4.3 TACRTableLockManager.InternalLockTable'+ #13#10 + 'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8)+ #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
      end
      else
        FFileServer := False;
      end;
		end; // if Result
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('5. TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
		if (Result) then
		begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('6. TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter10);
aaStartTime(time10);
{$ENDIF}
      // wait is finished
			PSessionLock^.IsWaiting := False;
      // lock set - remove from waiting list
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter19);
aaStartTime(time19);
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time19);
{$ENDIF}
      for i := 0 to FWaitingSessionLocks.Count - 1 do
        if (PACRSessionLockInfo(FWaitingSessionLocks.Items[i]) = PSessionLock) then
        begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('6.2 TACRTableLockManager.InternalLockTable' + #13#10 +'i = ' + IntToStr(i) + #13#10 + 'waitingCount = ' + IntToStr(FWaitingSessionLocks.Count));
{$ENDIF}
        	FWaitingSessionLocks.Delete(i);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('6.3 TACRTableLockManager.InternalLockTable');
{$ENDIF}
        	break;
        end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('7. TACRTableLockManager.InternalLockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID) + #13#10 + 'LockType = ' +ACRGetLockModeName(LockType) + #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID), 8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
			IncLockCounter(PSessionLock);
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time10);
{$ENDIF}
		end; // lock applied
	finally
		Unlock;
	end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_LOCKTABLE}
aaWriteToLog('< TACRTableLockManager.InternalLockTable, TableName = ' +LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)+ #13#10 + 'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock),8) + #13#10 + 'Result = ' + BoolToStr(Result, True));
WriteAllLocks;
 // ACRWriteSessionLockInfo(PSessionLock,FMaxWaitLockTime);
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
finally
	aaStopTime(time4);
end;
{$ENDIF}
end; // InternalLockTable


//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
procedure TACRTableLockManager.InternalUnlockTable(PSessionLock: PACRSessionLockInfo; UnlockAll: Boolean; // all session locks
	LockType: TACRLockType);
var
	i: Integer;
	PTransactionLock: PACRTransactionLockInfo;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_UNLOCKTABLE}
	SessionID: TACRSessionID;
{$ENDIF}

procedure UnlockFileServer(PLock: PACRSessionLockInfo);
begin
  if (FFileServer and (@FUnlockTableInFileServer <> nil)) then
  begin
    FUnlockTableInFileServer(PLock);
  end
  else
    FFileServer := False;
end; // UnlockFileServer


procedure DoUnlock(PLock: PACRSessionLockInfo; lt: TACRLockType;
	UnlockAll: Boolean);
begin
    // unlock cannot be called when this session waits for the lock
PLock^.WaitLockType := lt;
case lt of
ltX:
begin
if (PLock^.LockX) then
begin
DecLockCounter(PLock, UnlockAll);
UnlockFileServer(PLock);
end;
end;
ltIS:
begin
if (PLock^.NumLocksIS > 0) then
	DecLockCounter(PLock, UnlockAll);
if (PLock^.NumLocksIS = 0) then
	UnlockFileServer(PLock);
end;
ltS:
begin
if (PLock^.NumLocksS > 0) then
begin
if (PLock^.NumLocksS = 1) then
	UnlockFileServer(PLock);
DecLockCounter(PLock, UnlockAll);
end;
end;
ltIRW:
begin
if (PLock^.NumLocksIRW > 0) then
begin
if (PLock^.NumLocksIRW = 1) then
	UnlockFileServer(PLock);
DecLockCounter(PLock, UnlockAll);
end;
end;
ltRW:
begin
if (PLock^.LockRW) then
begin
UnlockFileServer(PLock);
DecLockCounter(PLock, UnlockAll);
end;
end
else
begin
        // ltU
if (PLock^.LockU) then
begin
DecLockCounter(PLock, UnlockAll);
UnlockFileServer(PLock);
end;
end;
end;
end; // DoUnlock

begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_UNLOCKTABLE}
aaWriteToLog('> TACRTableLockManager.InternalUnlockTable, TableName = ' +
		LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
		+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)
		+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)
		+ #13#10 + 'UnlockAll = ' + BoolToStr(UnlockAll,
		True) + #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));
if (PSessionLock <> nil) then
begin
SessionID := PSessionLock^.SessionID;
ACRWriteSessionLockInfo(PSessionLock, FMaxWaitLockTime);
end
else
	SessionID := INVALID_SESSION_ID;
{$ENDIF}
try
    // check if table is closed in transaction
	if ((not UnlockAll) and ((LockType = ltX) or (LockType = ltIS))) then
	begin
	LockTransactions(False);
	try
		PTransactionLock := nil;
		for i := 0 to FTransactionLocks.Count - 1 do
		begin
		PTransactionLock := FTransactionLocks.Items[i];
		if (PTransactionLock^.SessionID = PSessionLock^.SessionID) then
			break
		else
			PTransactionLock := nil;
		end;
	finally
		UnlockTransactions;
	end;
	if (PTransactionLock <> nil) then
	begin
	if (LockType = ltX) then
	begin
          // exclusive lock - we must add IS and (S or IRW)
	if (not PTransactionLock^.LockIS) then
		InternalLockTable(PSessionLock^.SessionID, ltIS, nil, PSessionLock);
	if (LTableData.TransactionSessionID = PSessionLock^.SessionID) then
	begin
	if (not PTransactionLock^.LockIRW) then
		InternalLockTable(PSessionLock^.SessionID, ltIRW, nil, PSessionLock);
	end
	else
	begin
	if (not PTransactionLock^.LockS) then
		InternalLockTable(PSessionLock^.SessionID, ltS, nil, PSessionLock);
	end;
	end
	else
		if (PSessionLock^.NumLocksIS = 1) then
		begin
          // shared lock - just set that it belongs transaction
		PTransactionLock^.LockIS := True;
		Exit;
		end;
	end;
	end; // check if table closed in transaction
    // unlock it
	if (UnlockAll) then
	begin
	for i := 0 to ACRMaxLockType do
		DoUnlock(PSessionLock, TACRLockType(i), True);
	end
	else
		DoUnlock(PSessionLock, LockType, False);
	if ((PSessionLock^.NumLocksIS = 0) and (not PSessionLock^.LockX)) then
	begin
      // table is totally unlocked - delete lock item
	Lock(True);
	try
		FSessionLocks.Remove(PSessionLock);
		if (PSessionLock.IsWaiting) then
			FWaitingSessionLocks.Remove(PSessionLock);
	finally
		Unlock;
	end;
	Dispose(PSessionLock);
	PSessionLock := nil;
	end;
except
end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_INTERNAL_UNLOCKTABLE}
aaWriteToLog('< TACRTableLockManager.InternalUnlockTable, TableName = ' +
		LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
		+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)
		+ #13#10 + 'SessionID = ' + IntToStr(SessionID)
		+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)
		+ #13#10 + 'PSessionLock = ' + IntToHex(Integer(PSessionLock), 8));
WriteAllLocks;
{$ENDIF}
end; // InternalUnlockTable

//------------------------------------------------------------------------------
// unlock all
//------------------------------------------------------------------------------
procedure TACRTableLockManager.UnlockAll;
var
	i: Integer;
	PSessionLocks: PACRSessionLockInfo;
begin
Lock(True);
try
	for i := 0 to FSessionLocks.Count - 1 do
	begin
	PSessionLocks := FSessionLocks.Items[i];
	InternalUnlockTable(PSessionLocks, True, ltS);
	Dispose(PSessionLocks);
	end;
	FSessionLocks.Clear;
	FWaitingSessionLocks.Clear;
finally
	Unlock;
end;
end; // UnlockAll

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRTableLockManager.Create(aTableData: TACRAdvancedTableData; aFileServer: Boolean);
begin
  if (aTableData = nil) then
    raise EACRException.Create(11944, ErrorLNilPointer);
  LTableData := aTableData;
  FFileServer := aFileServer;
  FLockTableInFileServer := nil;
  FUnlockTableInFileServer := nil;
  FMaxWaitLockTime := ACRGetMaxWaitTime(LTableData.DatabaseData.LockParams);
  FNormalDelay := LTableData.DatabaseData.LockParams.Delay;
  if (FFileServer) then
  begin
  if (FNormalDelay = 0) then
    Inc(FNormalDelay);
  FShortDelay := FNormalDelay shr 1; // 1/2 delay
  if (FShortDelay = 0) then
    Inc(FShortDelay);
  FMinDelay := 1; // sleep(1) to avoid high cpu load if we wait session from another machine
  end
  else
  begin
  FShortDelay := 0; // for exclusive multi-threaded mode
  FMinDelay := 0; // sleep(0) switches to other thread
  end;
  FSessionLocks := TList.Create;
  FWaitingSessionLocks := TList.Create;
  FTransactionLocks := TList.Create;
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FThreadSyncTransactions :=
    TACRReadWriteThreadSyncBySingleCriticalSection.Create;

  FThreadSyncLockTable := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FillChar(FTableLockInfo, Sizeof(FTableLockInfo), $00);
  FTableLockInfo.LockXSessionID := INVALID_SESSION_ID;
  FTableLockInfo.LockIRWSessionID := INVALID_SESSION_ID;
  FTableLockInfo.LockRWSessionID := INVALID_SESSION_ID;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRTableLockManager.Destroy;
begin
  UnlockAll;
  FThreadSync.Free;
  FThreadSyncTransactions.Free;
  FThreadSyncLockTable.Free;
  FSessionLocks.Free;
  FWaitingSessionLocks.Free;
  FTransactionLocks.Free;
  inherited;
end; // Destroy

//------------------------------------------------------------------------------

// try to lock the table until time limit set by FMaxWaitLockTime
//------------------------------------------------------------------------------
function TACRTableLockManager.LockTable(
                                        SessionID:      TACRSessionID;
                                        LockType:       TACRLockType;
                                        PRecordID:      PACRRecordID;
                                        bInTransaction: Boolean = False
                                      ): Boolean;
var
	i:                  Integer;
	PSessionLock:       PACRSessionLockInfo;
	PTransactionLock:   PACRTransactionLockInfo;
	bSleepLevel:        Boolean;
	SleepTime:          Cardinal;
begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter3);
aaStartTime(time3);
try
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
	aaStartTime(time11);
	aaIncCounter(counter11);
	try
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('> TACRTableLockManager.LockTable, TableName = ' +LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)
+ #13#10 + 'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)
+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction, True));
{$ENDIF}
		bSleepLevel := False;
		PTransactionLock := nil;
		if (bInTransaction and (LockType in [ltIS, ltS, ltIRW, ltRW])) then
		begin
      // check if transaction already has the lock
      LockTransactions(False);
      try
        for i := 0 to FTransactionLocks.Count - 1 do
        begin
          PTransactionLock := FTransactionLocks.Items[i];
          if (PTransactionLock^.SessionID = SessionID) then
            break
          else
            PTransactionLock := nil;
        end;
      finally
        UnlockTransactions;
      end;
    end;
		if (PTransactionLock <> nil) then
		begin
      // check if lock already exists
  		Result := (PTransactionLock^.LockIS and (LockType = ltIS)) or
		          	(PTransactionLock^.LockS and (LockType = ltS)) or
          			(PTransactionLock^.LockIRW and (LockType = ltIRW)) or
          			(PTransactionLock^.LockRW and (LockType = ltRW));
  		if (Result) then
	  		Exit;
		end;
		PSessionLock := nil;
		repeat
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('1. TACRTableLockManager.LockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,True) + #13#10 + 'Result = ' + BoolToStr(Result, True)+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8));
{$ENDIF}
			Result := InternalLockTable(SessionID, LockType, PRecordID, PSessionLock);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('2. TACRTableLockManager.LockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,True) + #13#10 + 'Result = ' + BoolToStr(Result, True)+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8));
{$ENDIF}
			if (not Result) then
			begin
			if (bSleepLevel) then
				SleepTime := 1
			else
				SleepTime := GetLockWaitTime(PSessionLock^.WaitTime);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE_SLEEP}
			aaWriteToLog('>SleepTime = ' + IntToStr(SleepTime));
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
			aaIncCounter(counter5);
			aaStartTime(time5);
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
aaStartTime(time14);
aaIncCounter(counter14);
{$ENDIF}
			Sleep(SleepTime);
{$IFDEF DEBUG_LOCK_TIMES}
aaStopTime(time14);
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
			aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE_SLEEP}
			aaWriteToLog('<SleepTime = ' + IntToStr(SleepTime));
{$ENDIF}
			bSleepLevel := not bSleepLevel;
          // Sleep(GetLockWaitTime(PSessionLock^.WaitTime));
			end;
		until ((Result) or (ACRGetTickCountDiff(aaGetTickCount,
					PSessionLock^.WaitTime) > FMaxWaitLockTime));
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('3. TACRTableLockManager.LockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,True) + #13#10 + 'Result = ' + BoolToStr(Result, True)+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8));
{$ENDIF}
		if (Result) then
		begin
      if (bInTransaction) then
      begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('4. TACRTableLockManager.LockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,True) + #13#10 + 'Result = ' + BoolToStr(Result, True)+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8));
{$ENDIF}
        if (PTransactionLock = nil) then
        begin
          New(PTransactionLock);
          FillChar(PTransactionLock^, Sizeof(TACRTransactionLockInfo), $00);
          PTransactionLock^.SessionID := SessionID;
          LockTransactions(True);
          try
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('5. TACRTableLockManager.LockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,True) + #13#10 + 'Result = ' + BoolToStr(Result, True)+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8));
{$ENDIF}
            FTransactionLocks.Add(PTransactionLock);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('6. TACRTableLockManager.LockTable' + #13#10 +'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,True) + #13#10 + 'Result = ' + BoolToStr(Result, True)+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8)+#13#10+'FTransactionLocks.Count = '+IntToStr(FTransactionLocks.Count));
{$ENDIF}
          finally
            UnlockTransactions;
          end;
        end;
        case LockType of
        ltIS:
          PTransactionLock^.LockIS := True;
        ltS:
          PTransactionLock^.LockS := True;
        ltIRW:
          PTransactionLock^.LockIRW := True;
        ltRW:
          PTransactionLock^.LockRW := True;
        end;
      end; // transaction lock set
		end // lock ok
		else
		begin
      // wait is finished - lock failed
      PSessionLock^.IsWaiting := False;
      Lock(True);
      try
        // open table lock failed (IS or X) - destroy lock item, as probably will be never used later
        for i := 0 to FWaitingSessionLocks.Count - 1 do
          if (FWaitingSessionLocks.Items[i] = PSessionLock) then
          begin
            FWaitingSessionLocks.Delete(i);
            break;
          end;
        if ((PSessionLock^.NumLocksIS = 0) and (not PSessionLock^.LockX)) then
        begin
          // open table lock failed (IS or X) - destroy lock item, as probably will be never used later
          for i := 0 to FSessionLocks.Count - 1 do
            if (FSessionLocks.Items[i] = PSessionLock) then
            begin
              FSessionLocks.Delete(i);
              break;
            end;
          Dispose(PSessionLock);
        end
        else
        begin
          // table / record lock failed
          if (FFileServer and (@FClearWaitLevelInFileServer <> nil)) then
          begin
            FClearWaitLevelInFileServer(PSessionLock);
          end
          else
            FFileServer := False;
          PSessionLock^.IsWaiting := False;
        end;
      finally
        Unlock;
      end;
		end; // lock failed
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
		aaWriteToLog('< TACRTableLockManager.LockTable, TableName = ' +
				LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
				+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)
				+ #13#10 + 'SessionID = ' + IntToStr(SessionID)
				+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType)
				+ #13#10 + 'PRecordID = ' + IntToHex(Integer(PRecordID),
				8) + #13#10 + 'bInTransaction = ' + BoolToStr(bInTransaction,
				True) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
	finally
		aaStopTime(time11);
		if (not Result) then
			aaIncCounter(counter12);
	end;
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
finally
	aaStopTime(time3);
end;
{$ENDIF}
end; // LockTable

//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
procedure TACRTableLockManager.UnlockTable(SessionID: TACRSessionID;
	LockType: TACRLockType);
var
	i: Integer;
	PSessionLock: PACRSessionLockInfo;
begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_UNLOCKTABLE}
aaWriteToLog('> TACRTableLockManager.UnlockTable, TableName = ' +
		LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
		+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)
		+ #13#10 + 'SessionID = ' + IntToStr(SessionID)
		+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType));
{$ENDIF}
Lock(True);
try
	PSessionLock := nil;
	for i := 0 to FSessionLocks.Count - 1 do
	begin
	PSessionLock := FSessionLocks.Items[i];
	if (PSessionLock^.SessionID = SessionID) then
		break
	else
		PSessionLock := nil;
	end;
finally
	Unlock;
end;
if (PSessionLock <> nil) then
begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_UNLOCKTABLE}
aaWriteToLog('1. TACRTableLockManager.UnlockTable' + #13#10 + 'SessionID = ' +
		IntToStr(SessionID) + #13#10 + 'LockType = ' + ACRGetLockModeName(LockType));
{$ENDIF}
InternalUnlockTable(PSessionLock, False, LockType);
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_UNLOCKTABLE}
aaWriteToLog('2. TACRTableLockManager.UnlockTable' + #13#10 + 'SessionID = ' +
		IntToStr(SessionID) + #13#10 + 'LockType = ' + ACRGetLockModeName(LockType));
{$ENDIF}
end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_UNLOCKTABLE}
aaWriteToLog('< TACRTableLockManager.UnlockTable, TableName = ' +
		LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
		+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive)
		+ #13#10 + 'SessionID = ' + IntToStr(SessionID)
		+ #13#10 + 'LockType = ' + ACRGetLockModeName(LockType));
{$ENDIF}
end; // UnlockTable

//------------------------------------------------------------------------------
// decrements number of locks by this session and removes all locks if their number = 0
// if PTableLockInfo = nil - all table locks by this session will be removed
//------------------------------------------------------------------------------
function TACRTableLockManager.UnlockSessionAll(SessionID: TACRSessionID)
	: Boolean;
var
	i: Integer;
	PSessionLock: PACRSessionLockInfo;
begin
Lock(True);
try
	for i := 0 to FSessionLocks.Count - 1 do
	begin
	PSessionLock := FSessionLocks.Items[i];
	if (PSessionLock^.SessionID = SessionID) then
	begin
	InternalUnlockTable(PSessionLock, True, ltS);
	break;
	end;
	end;
finally
	Unlock;
end;
end; // UnlockSessionAll

//------------------------------------------------------------------------------
// return true if lock successfully set, otherwise return false and session item
//------------------------------------------------------------------------------
function TACRTableLockManager.TryToLockRWForCommit(SessionID: TACRSessionID): Boolean;
var
	i: 								Integer;
	PTransactionLock: PACRTransactionLockInfo;
	PSessionLock: 		PACRSessionLockInfo;
begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_TryToLockRWForCommit}
aaWriteToLog('> TACRTableLockManager.TryToLockRWForCommit' + #13#10 +	'SessionID = ' + IntToStr(SessionID));
{$ENDIF}
  PTransactionLock := nil;
  PSessionLock := nil;
  LockTransactions(False);
  try
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_TryToLockRWForCommit}
aaWriteToLog('0 TACRTableLockManager.TryToLockRWForCommit' + #13#10 +	'SessionID = ' + IntToStr(SessionID)
+#13#10+'FTransactionLocks.Count = '+IntToStr(FTransactionLocks.Count));
{$ENDIF}
    for i := 0 to FTransactionLocks.Count - 1 do
    begin
      PTransactionLock := FTransactionLocks.Items[i];
      if (PTransactionLock^.SessionID = SessionID) then
        break
      else
        PTransactionLock := nil;
    end;
  finally
  UnlockTransactions;
  end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_TryToLockRWForCommit}
ACRWriteTransactionLockInfo(PTransactionLock);
{$ENDIF}
  // check if we have IRW lock
  if (PTransactionLock = nil) then
  begin
	  Result := LTableData.Exclusive;
  end
  else
  if (not PTransactionLock^.LockIRW) then
    Result := LTableData.Exclusive
  else
  begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_TryToLockRWForCommit}
aaWriteToLog('1. TACRTableLockManager.TryToLockRWForCommit' + #13#10 + 'SessionID = ' + IntToStr(SessionID));
{$ENDIF}
    try
      Result := InternalLockTable(SessionID, ltRW, nil, PSessionLock);
    except
      Result := False;
    end;
    if (Result) then
      PTransactionLock^.LockRW := True;
  end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_TryToLockRWForCommit}
aaWriteToLog('< TACRTableLockManager.TryToLockRWForCommit' + #13#10 +
		'SessionID = ' + IntToStr(SessionID) + #13#10 + 'Result = ' + BoolToStr
		(Result, True));
{$ENDIF}
end; // TryToLockRWForCommit


//------------------------------------------------------------------------------
// removes transaction locks
//------------------------------------------------------------------------------
procedure TACRTableLockManager.FinishTransaction(SessionID: TACRSessionID);
var
	i: Integer;
	PTransactionLock: PACRTransactionLockInfo;
	PSessionLock: PACRSessionLockInfo;
begin
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
aaWriteToLog('> TACRTableLockManager.FinishTransaction' + #13#10 +
		'SessionID = ' + IntToStr(SessionID));
{$ENDIF}
try
	Lock(True);
	try
		for i := 0 to FWaitingSessionLocks.Count - 1 do
		begin
		PSessionLock := FWaitingSessionLocks.Items[i];
		if (PSessionLock^.SessionID = SessionID) then
		begin
		FWaitingSessionLocks.Delete(i);
		break;
		end;
		end;
	finally
		Unlock;
	end;
except
end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
aaWriteToLog('1. TACRTableLockManager.FinishTransaction' + #13#10 +
		'SessionID = ' + IntToStr(SessionID));
{$ENDIF}
try
	PTransactionLock := nil;
	LockTransactions(True);
	try
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('2. TACRTableLockManager.FinishTransaction' + #13#10 +'SessionID = ' + IntToStr(SessionID)
+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8)+#13#10+'FTransactionLocks.Count = '+IntToStr(FTransactionLocks.Count));
{$ENDIF}
		for i := 0 to FTransactionLocks.Count - 1 do
		begin
      PTransactionLock := FTransactionLocks.Items[i];
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_LOCKTABLE}
aaWriteToLog('3. TACRTableLockManager.FinishTransaction' + #13#10 +'SessionID = ' + IntToStr(SessionID)
+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8)+#13#10+'FTransactionLocks.Count = '+IntToStr(FTransactionLocks.Count)+#13#10+'i = '+IntToStr(i));
{$ENDIF}
      if (PTransactionLock^.SessionID = SessionID) then
      begin
        FTransactionLocks.Delete(i);
        break;
      end
      else
        PTransactionLock := nil;
		end;
	finally
		UnlockTransactions;
	end;
except
end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
aaWriteToLog('4. TACRTableLockManager.FinishTransaction'
+#13#10+'SessionID = ' + IntToStr(SessionID)
+#13#10+'PTransactionLock = '+IntToHex(Integer(PTransactionLock),8)
);
{$ENDIF}
try
	if (PTransactionLock <> nil) then
	begin
    PSessionLock := nil;
    Lock(False);
    try
      for i := 0 to FSessionLocks.Count - 1 do
      begin
      PSessionLock := FSessionLocks.Items[i];
      if (PSessionLock^.SessionID = SessionID) then
        break
      else
        PSessionLock := nil;
      end;
    finally
      Unlock;
    end;
  {$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
    aaWriteToLog('2. TACRTableLockManager.FinishTransaction' + #13#10 +
        'SessionID = ' + IntToStr(SessionID) + #13#10 + 'PSessionLock = ' +
        IntToHex(Integer(PSessionLock),
        8) + #13#10 + 'PTransactionLock = ' + IntToHex
        (Integer(PTransactionLock), 8));
  {$ENDIF}
    if (PSessionLock <> nil) then
    begin
  {$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
    ACRWriteSessionLockInfo(PSessionLock, FMaxWaitLockTime);
  {$ENDIF}
    if (PTransactionLock^.LockRW) then
      InternalUnlockTable(PSessionLock, False, ltRW);
    if (PTransactionLock^.LockIRW) then
      InternalUnlockTable(PSessionLock, False, ltIRW);
    if (PTransactionLock^.LockS) then
      InternalUnlockTable(PSessionLock, False, ltS);
    if (PTransactionLock^.LockIS) then
      InternalUnlockTable(PSessionLock, False, ltIS);
  {$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
    aaWriteToLog('3. TACRTableLockManager.FinishTransaction' + #13#10 +
        'SessionID = ' + IntToStr(SessionID)
        + #13#10 + #13#10 + 'PSessionLock = ' + IntToHex
        (Integer(PSessionLock), 8) + #13#10 + 'PTransactionLock = ' + IntToHex
        (Integer(PTransactionLock), 8));
    WriteAllLocks;
  {$ENDIF}
    end;
    Dispose(PTransactionLock);
	end; // transaction found
except
end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_FinishTransaction}
aaWriteToLog('< TACRTableLockManager.FinishTransaction' + #13#10 +	'SessionID = ' + IntToStr(SessionID));
{$ENDIF}
end; // FinishTransaction


{$IFDEF DEBUG_LOG}
//------------------------------------------------------------------------------
// removes transaction locks
//------------------------------------------------------------------------------
procedure TACRTableLockManager.WriteAllLocks;
var
	i: Integer;
	PTransactionLock: PACRTransactionLockInfo;
	PSessionLock: PACRSessionLockInfo;
begin
aaWriteToLog('> TACRTableLockManager.WriteAllLocks, TableName = ' +
		LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
		+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive));
Lock(True);
try
	ACRWriteTableLockInfo(FTableLockInfo);
	aaWriteToLog('SessionLocks.Count = ' + IntToStr(FSessionLocks.Count));
	for i := 0 to FSessionLocks.Count - 1 do
	begin
	PSessionLock := PACRSessionLockInfo(FSessionLocks.Items[i]);
	ACRWriteSessionLockInfo(PSessionLock, FMaxWaitLockTime);
	end;
finally
	Unlock;
end;
LockTransactions(False);
try
	aaWriteToLog('TransactionLocks.Count = ' + IntToStr(FTransactionLocks.Count));
	for i := 0 to FTransactionLocks.Count - 1 do
	begin
	PTransactionLock := PACRTransactionLockInfo(FTransactionLocks.Items[i]);
	ACRWriteTransactionLockInfo(PTransactionLock);
	end;
finally
	UnlockTransactions;
end;
aaWriteToLog('< TACRTableLockManager.WriteAllLocks, TableName = ' +
		LTableData.TableName + ' InMemory = ' + BoolToStr(LTableData.InMemory)
		+ ' Exclusive = ' + BoolToStr(LTableData.Exclusive));
end;
{$ENDIF}




////////////////////////////////////////////////////////////////////////////////
//
// TACRAdvancedTableData
// base class for TACRMemTableData and TACRDiskTableData
// manages locking and multiple sessions
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// read most updated data
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.ReadMostUpdatedData(SessionID: TACRSessionID);
begin
FMUDState := FTableState.TableState;
FMUDLoaded := True;
end; // ReadMostUpdatedData

//------------------------------------------------------------------------------
// write most updated data
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.WriteMostUpdatedData(SessionID: TACRSessionID);
begin
end; // WriteMostUpdatedData

//------------------------------------------------------------------------------
// restore current MUD if error occurs without transactgon
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.RestoreMostUpdatedData
	(SessionID: TACRSessionID);
begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_RestoreMostUpdatedData}
aaWriteToLog('> TACRAdvancedTableData.RestoreMostUpdatedData, FTableName = ' +
		FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
		True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
		True) + #13#10 + 'SessionID = ' + IntToStr(SessionID)
		+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
if (SessionID <> FTransactionSessionID) then
begin
CancelChanges;
ReadMostUpdatedData(SessionID);
end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_RestoreMostUpdatedData}
aaWriteToLog('< TACRAdvancedTableData.RestoreMostUpdatedData, FTableName = ' +FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,		True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(SessionID)+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
end; // RestoreMostUpdatedData

//------------------------------------------------------------------------------
// return maximum time to wait for the lock
//------------------------------------------------------------------------------
function TACRAdvancedTableData.GetMaxWaitLockTime: Cardinal;
begin
  Result := FLockManager.MaxWaitLockTime;
end; // GetMaxWaitLockTime

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRAdvancedTableData.Create(aDatabaseData: TACRDatabaseData);
begin
  inherited Create(aDatabaseData);
  FTransactionSessionID := INVALID_SESSION_ID;
  FMUDLoaded := False;
  FIsTableOpened := False;
  FTransactionMUD := False;
  FLockManager := nil;
  FLockCount := 0;
  FLockSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FSessionsSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FTransactionSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FTransactionCount := 0;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRAdvancedTableData.Destroy;
begin
  if (FLockManager <> nil) then
    FreeAndNil(FLockManager);
  FreeAndNil(FLockSync);
  FreeAndNil(FTransactionSync);
  FreeAndNil(FSessionsSync);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// lock table
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.LockTable(
																					bWriteMode: 			Boolean;
																					Session: 					TACRBaseSession;
                                          ErrorCode: 				Integer;
                                          DoNotLockThread: 	Boolean
                                         );
var
    lockMode: 					AnsiString;
    bOK: 								Boolean;
    bStartTransaction: 	Boolean;

  // return true if transaction was added (start transaction)
function AddTableData(Session: TACRBaseSession): Boolean;
begin
  if (not(Session is TACRLocalSession)) then
    raise EACRException.Create(11909, ErrorLNotALocalSession, [Session.ClassName])
  else
  begin
    Result := TACRLocalSession(Session).Transaction.AddTableData(Self);
  end;
end; // AddTableData

begin
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('> TACRAdvancedTableData.LockTable, FTableName = ' +	FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,	True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'Self =' + IntToHex(Integer(Self),8) + #13#10 + 'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'DoNotLockThread = ' + BoolToStr(DoNotLockThread, True));try
{$ENDIF}
	bStartTransaction := False;
  // table already locked
	if (FExclusive and Session.InTransaction) then
	begin
    if (FTransactionCount = 0) then
    begin
      FTransactionCount := 1;
      // exclusive access - no need to lock as the thread is only that uses table
      AddTableData(Session);
    end;
    if (bWriteMode) then
      FTransactionSessionID := Session.SessionID;
	end; // end of exclusive transaction
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('1. TACRAdvancedTableData.LockTable' + #13#10 + 'WriteMode = ' +BoolToStr(bWriteMode, True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 + 'FTransactionSessionID = ' +IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' +IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True));
{$ENDIF}
  // no locks - already exclusive
	if (FExclusive) then
		Exit;
  // try to lock table
	if (Session.SessionID = FTransactionSessionID) then
		bOK := True
	else
	if ((not bWriteMode) and (not Session.InTransaction)) then
	begin
    lockMode := 'S';
    // read mode
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('2. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True));
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStartTime(time2);
{$ENDIF}
		bOK := TryToLockTableS(Session.SessionID, Session.InTransaction);
{$IFDEF DEBUG_LOCKTABLE_TIME}
aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('3. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'bOK = ' + BoolToStr(bOK, True));
{$ENDIF}
(*
    if (bOK and Session.InTransaction) then
    begin
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('4. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'bOK = ' + BoolToStr(bOK, True));
{$ENDIF}
      bStartTransaction := AddTableData(Session);
      if (bStartTransaction) then
      begin
        FTransactionSync.Lock(True);
        try
          Inc(FTransactionCount);
        finally
          FTransactionSync.Unlock;
        end;
      end;
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('5. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'bOK = ' + BoolToStr(bOK,True) + #13#10 + 'bStartTransaction = ' + BoolToStr(bStartTransaction,True));
{$ENDIF}
    end; // (bOK and Session.InTransaction)
*)
  end // read mode
  else
  begin
    // write mode or read in transaction
    if (Session.InTransaction) then
    begin
      lockMode := 'IRW';
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('6. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True));
{$ENDIF}
      bStartTransaction := AddTableData(Session);
      if (bStartTransaction) then
       begin
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('6.1. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True));
{$ENDIF}
  			bOK := TryToLockTableIRW(Session.SessionID, True);
       end
      else
       // alreay locked
       bOK := True;
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('7. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True) + #13#10 + 'bOK = ' + BoolToStr(bOK, True));
{$ENDIF}
      if (bOK) then
      begin
        // IRW can be set only by single session, so we can set it safely
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('8. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'bOK = ' + BoolToStr(bOK, True));
{$ENDIF}
        if (FTransactionSessionID = INVALID_SESSION_ID) then
        begin
          FTransactionSync.Lock(True);
          try
            if (bWriteMode) then
              FTransactionSessionID := Session.SessionID;
            if (bStartTransaction) then
              Inc(FTransactionCount);
          finally
            FTransactionSync.Unlock;
          end;
        end
        else
        if (FTransactionSessionID <> Session.SessionID) and (bWriteMode) then
        begin
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
aaWriteToLog('11943 error. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'bOK = ' + BoolToStr(bOK,True) + #13#10 + 'bStartTransaction = ' + BoolToStr(bStartTransaction, True));FLockManager.WriteAllLocks;
{$ENDIF}
          raise EACRException.Create(11943,
              ErrorLTransactionAlreadyStartTableWriting,
              [FTableName, BoolToStr(FInMemory, True), FTransactionSessionID,
              Session.SessionID]);
        end;
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('9. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'bOK = ' + BoolToStr(bOK,True) + #13#10 + 'bStartTransaction = ' + BoolToStr(bStartTransaction,True));
{$ENDIF}
      end; // (bOK and Session.InTransaction)
		end // write mode in transaction
		else
		begin
      lockMode := 'RW';
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('10. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True));
{$ENDIF}
      bOK := TryToLockTableRW(Session.SessionID);
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('11. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True) + #13#10 + 'bOK = ' + BoolToStr(bOK, True));
{$ENDIF}
		end; // write mode without transaction
	end; // write mode
  // if bOK - table locked successfully
	if (bOK) then
	begin
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('20. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive, True));
{$ENDIF}
    // if (not DoNotLockThread) then
    // to avoid MUD reloading during other process operation
    FSessionsSync.Lock(True);
    try
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('12. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'bStartTransaction = ' + BoolToStr(bStartTransaction, True));
{$ENDIF}
      FLockSync.Lock(True);
      try
        if (FLockCount = 0) then
        begin
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('13. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,True) + #13#10 + 'FTableState.TableState = ' + IntToStr(FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
            // if we access database exclusively we always have current table state
            // as it is loaded on opening
          if (not PageManager.Exclusive) then
            FTableState := LoadTableState;
          if ((not FMUDLoaded) or (FTableState.TableState <> FMUDState)) then
          begin
            ReadMostUpdatedData(Session.SessionID);
            FMUDLoaded := True;
            FMUDState := FTableState.TableState;
          end;
          FTransactionMUD := (Session.SessionID = FTransactionSessionID);
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('14. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,True) + #13#10 + 'FTableState.TableState = ' + IntToStr(FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
				end; // load first time
				Inc(FLockCount);
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('15. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,True) + #13#10 + 'FTableState.TableState = ' + IntToStr(FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
        // each transaction increases counter by 1 on starting
        // to avoid re-reading MUD
				if (bStartTransaction) then
					Inc(FLockCount);
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('16. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD, True));
{$ENDIF}
        if (FTransactionMUD <> (Session.SessionID = FTransactionSessionID)) then
        begin
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('17. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,True) + #13#10 + 'FTableState.TableState = ' + IntToStr(FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
          ReadMostUpdatedData(Session.SessionID);
          FTransactionMUD := (Session.SessionID = FTransactionSessionID);
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('18. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,True) + #13#10 + 'FTableState.TableState = ' + IntToStr(FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
				end; // reloaded MUD for active transaction or other sessions
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('19. TACRAdvancedTableData.LockTable' + #13#10 +'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID) + #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction, True) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FTransactionMUD = ' + BoolToStr(FTransactionMUD,True) + #13#10 + 'FMUDLoaded = ' + BoolToStr(FMUDLoaded,True) + #13#10 + 'FTableState.TableState = ' + IntToStr(FTableState.TableState) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
			finally
				FLockSync.Unlock;
			end;
    finally
      if (DoNotLockThread) then
        FSessionsSync.Unlock;
    end;
	end // bOK
	else
		raise EACRException.Create(ErrorCode, ErrorLCannotLockTableA,
			[lockMode, FTableName, BoolToStr(FInMemory, True), Session.SessionID]);
{$IFDEF DEBUG_TRACE_LOCKTABLE}
aaWriteToLog('< TACRAdvancedTableData.LockTable, FTableName = ' +FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'DoNotLockThread = ' + BoolToStr(DoNotLockThread, True));
except on e: Exception do begin	aaWriteToLog('Error in TACRAdvancedTableData.LockTable:' + #13#10+e.Message+#13#10+'FTableName = ' +FTableName + #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'WriteMode = ' + BoolToStr(bWriteMode,True) + #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True) + #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID) + #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount) + #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+ #13#10 + 'DoNotLockThread = ' + BoolToStr(DoNotLockThread, True)); raise; end; end;
{$ENDIF}
{$IFDEF DEBUG_LOCKTABLE_TIME}
finally
	aaStopTime(time1);
end;
{$ENDIF}
end; // LockTable


//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.UnlockTable(
                                            bWriteMode: 			Boolean;
                                            Session: 					TACRBaseSession;
                                            DoNotLockThread: 	Boolean = False
                                            );
begin
  if (FExclusive) then
    Exit;
{$IFDEF DEBUG_TRACE_UNLOCKTABLE}
aaWriteToLog('> TACRAdvancedTableData.UnlockTable, FTableName = ' +FTableName
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'WriteMode = ' + BoolToStr(bWriteMode,True)
+ #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)
+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)
+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount));
try
{$ENDIF}
  if (not Session.InTransaction) then
  begin
    if (bWriteMode) then
      // write mode
      TryToUnlockTableRW(Session.SessionID)
    else
      TryToUnlockTableS(Session.SessionID);
  end;
  FLockSync.Lock(True);
  try
    if (FLockCount > 0) then
      Dec(FLockCount);
  finally
    FLockSync.Unlock;
  end;
  if (not DoNotLockThread) then
    FSessionsSync.Unlock;
{$IFDEF DEBUG_TRACE_UNLOCKTABLE}
aaWriteToLog('< TACRAdvancedTableData.UnlockTable, FTableName = ' +FTableName
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'WriteMode = ' + BoolToStr(bWriteMode,True)
+ #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)
+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)
+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount));
except on E: Exception do begin
aaWriteToLog('Error in TACRAdvancedTableData.UnlockTable, FTableName = ' +FTableName
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'WriteMode = ' + BoolToStr(bWriteMode,True)
+ #13#10 + 'SessionID = ' + IntToStr(Session.SessionID)
+ #13#10 + 'InTransaction = ' + BoolToStr(Session.InTransaction,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)
+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount)+#13#10+e.Message);
end;
end;
{$ENDIF}
end; // UnlockTable


//------------------------------------------------------------------------------
// lock S
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockTableS(aSessionID: TACRSessionID; bInTransaction: Boolean): Boolean;
begin
  Result := FLockManager.LockTable(aSessionID, ltS, nil, bInTransaction);
end; // TryToLockTableS


//------------------------------------------------------------------------------
// unlock S
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.TryToUnlockTableS(aSessionID: TACRSessionID);
begin
  FLockManager.UnlockTable(aSessionID, ltS);
end; // TryToUnlockTableS


//------------------------------------------------------------------------------
// lock IRW
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockTableIRW(aSessionID: TACRSessionID;
	bInTransaction: Boolean): Boolean;
begin
  Result := FLockManager.LockTable(aSessionID, ltIRW, nil, bInTransaction);
end; // TryToLockTableIRW


//------------------------------------------------------------------------------
// unlock IRW
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.TryToUnlockTableIRW(aSessionID: TACRSessionID);
begin
  FLockManager.UnlockTable(aSessionID, ltIRW);
end; // TryToUnlockTableIRW

//------------------------------------------------------------------------------
// lock RW
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockTableRW(aSessionID: TACRSessionID): Boolean;
begin
  Result := FLockManager.LockTable(aSessionID, ltRW, nil);
end; // TryToLockTableRW

//------------------------------------------------------------------------------
// unlock RW
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.TryToUnlockTableRW(aSessionID: TACRSessionID);
begin
  FLockManager.UnlockTable(aSessionID, ltRW);
end; // TryToUnlockTableRW

//------------------------------------------------------------------------------
// lock X
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockTableX(aSessionID: TACRSessionID): Boolean;
begin
  Result := FLockManager.LockTable(aSessionID, ltX, nil);
end; // TryToLockTableX

//------------------------------------------------------------------------------
// unlock X
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.TryToUnlockTableX(aSessionID: TACRSessionID);
begin
  FLockManager.UnlockTable(aSessionID, ltX);
end; // TryToUnlockTableX

//------------------------------------------------------------------------------
// lock IS
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockTableIS(aSessionID: TACRSessionID): Boolean;
begin
  Result := FLockManager.LockTable(aSessionID, ltIS, nil);
end; // TryToLockTableIS

//------------------------------------------------------------------------------
// unlock IS
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.TryToUnlockTableIS(aSessionID: TACRSessionID);
begin
  FLockManager.UnlockTable(aSessionID, ltIS);
end; // TryToUnlockTableIS

//------------------------------------------------------------------------------
// lock U
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockRecordU(aSessionID: TACRSessionID; const aRecordID: TACRRecordID): Boolean;
begin
  Result := FLockManager.LockTable(aSessionID, ltU, @aRecordID);
end; // TryToLockRecordU

//------------------------------------------------------------------------------
// unlock U
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.TryToUnlockRecordU(aSessionID: TACRSessionID; const aRecordID: TACRRecordID);
begin
  FLockManager.UnlockTable(aSessionID, ltU);
end; // TryToUnlockRecordU

//------------------------------------------------------------------------------
// remove all sessionlocks
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.RemoveAllSessionLocks(aSessionID: TACRSessionID);
begin
  FLockManager.UnlockSessionAll(aSessionID);
end; // RemoveAllSessionLocks


//------------------------------------------------------------------------------
// Commit
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.Commit(aSessionID: TACRSessionID);
begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('> TACRAdvancedTableData.Commit. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount));
{$ENDIF}
  if (FTransactionSessionID = aSessionID) then
  begin
    if (not FTransactionMUD) and (FIsTableOpened) then
      ReadMostUpdatedData(aSessionID);
        // write changes only if the transaction is active
    SetTableFlag(True, tffWriteFailed);
    UpdateTableState(ltoCommit);
    SaveTableState;
    ApplyChanges(FTableState.TableState, dbstTableMetaData, FTableState.TableMetaDataState);
    SetTableFlag(False, tffWriteFailed);
    SaveTableState;
    FMUDState := FTableState.TableState;
    FMUDLoaded := True;
    FTransactionMUD := False;
  end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('1. TACRAdvancedTableData.Commit. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
  if ((not FInMemory) and (not FIsTableOpened)) then
    try
        // export cache to parent
      FCache.ExportPagesToParent;
    except
    end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('2. TACRAdvancedTableData.Commit. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
  FTransactionSync.Lock(True);
  try
      // close active transaction
    FLockManager.FinishTransaction(aSessionID);
    if (FTransactionSessionID = aSessionID) then
    begin
    FTransactionSessionID := INVALID_SESSION_ID;
    end;
    if (FTransactionCount > 0) then
      Dec(FTransactionCount);
  finally
    FTransactionSync.Unlock;
  end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('3. TACRAdvancedTableData.Commit. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
  FLockSync.Lock(True);
  try
    if (FLockCount > 0) then
      Dec(FLockCount);
  finally
    FLockSync.Unlock;
  end;
  if (not FIsTableOpened) then
   begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('4. TACRAdvancedTableData.Commit. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
     FreeIfNoSessionsConnected;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('5. TACRAdvancedTableData.Commit. ');
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Commit}
aaWriteToLog('< TACRAdvancedTableData.Commit. ');
{$ENDIF}
end; // Commit


//------------------------------------------------------------------------------
// Rollback
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.Rollback(aSessionID: TACRSessionID);
begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('> TACRAdvancedTableData.Rollback. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)+ #13#10 + 'FTransactionCount = ' + IntToStr(FTransactionCount)+ #13#10 + 'FLockCount = ' + IntToStr(FLockCount));
{$ENDIF}
  try
    CancelChanges;
  except
  end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('1. TACRAdvancedTableData.Rollback. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
  if ((not FInMemory) and (not FIsTableOpened)) then
    try
        // export cache to parent
      FCache.ExportPagesToParent;
    except
    end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('2. TACRAdvancedTableData.Rollback. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
  FTransactionSync.Lock(True);
  try
    if (FTransactionSessionID = aSessionID) then
    begin
        // to avoid parallel call of LockTable - we are may be only in IRW
    FLockSync.Lock(True);
    try
      FTransactionSessionID := INVALID_SESSION_ID;
      if (FTransactionMUD) and (FIsTableOpened) then
      begin
        ReadMostUpdatedData(aSessionID);
        FTransactionMUD := False;
      end;
    finally
      FLockSync.Unlock;
    end;
    end;
      // close active transaction
    FLockManager.FinishTransaction(aSessionID);
    if (FTransactionCount > 0) then
      Dec(FTransactionCount);
  finally
    FTransactionSync.Unlock;
  end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('3. TACRAdvancedTableData.Rollback. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
  FLockSync.Lock(True);
  try
    if (FLockCount > 0) then
      Dec(FLockCount);
  finally
    FLockSync.Unlock;
  end;
  if (not FIsTableOpened) then
   begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('4. TACRAdvancedTableData.Rollback. FTableName = ' + FTableName +', InMemory = ' + BoolToStr(FInMemory,True) + #13#10 + 'SessionID = ' + IntToStr(aSessionID) + #13#10 +'FTransactionSessionID = ' + IntToStr(FTransactionSessionID));
{$ENDIF}
     FreeIfNoSessionsConnected;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('5. TACRAdvancedTableData.Rollback. ');
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_Rollback}
aaWriteToLog('< TACRAdvancedTableData.Rollback.');
{$ENDIF}
end; // Rollback


//------------------------------------------------------------------------------
// lock RW
//------------------------------------------------------------------------------
function TACRAdvancedTableData.TryToLockRWForCommit(SessionID: TACRSessionID): Boolean;
begin
	Result := FLockManager.TryToLockRWForCommit(SessionID);
end; // TryToLockRWForCommit


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// locate
//------------------------------------------------------------------------------
function TACRAdvancedTableData.Locate(
                Cursor:           TACRCursor;
                const KeyFields:  WideString;
                const KeyValues:  Variant;
                CaseInsensitive:  Boolean;
                PartialKey:       Boolean
               ): Boolean;
begin
    LockTable(False, Cursor.Session, 12398);
    try
      Result := inherited Locate(Cursor, KeyFields, KeyValues,
                                 CaseInsensitive, PartialKey);
    finally
      UnlockTable(False, Cursor.Session);
    end;
end; // Locate


//------------------------------------------------------------------------------
// return true if record was found and is visible by cursor
// prepares params for FindRecordByScan and calls it
//------------------------------------------------------------------------------
function TACRAdvancedTableData.FindRecord(
                        Cursor:                       TACRCursor;
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                   ): Boolean;
begin
  if (InternalCall) then
  begin
    Result := inherited FindRecord(Cursor, Restart, GoForward,
                                   ResultRecordID, RecordBitmap,
                                   True, StopAtFirstFoundRecord);
  end
  else
  begin
    LockTable(False, Cursor.Session, 12394);
    try
      Result := inherited FindRecord(Cursor, Restart, GoForward,
                                     ResultRecordID, RecordBitmap,
                                     True, StopAtFirstFoundRecord);
    finally
      UnlockTable(False, Cursor.Session);
    end;
  end;
end; // FindRecord
{$ELSE}
//------------------------------------------------------------------------------
// return true if record was found and is visible by cursor
// prepares params for FindRecordByScan and calls it
//------------------------------------------------------------------------------
function TACRAdvancedTableData.FindRecord(
                        Cursor:                       TACRCursor;
                        SearchExpression:             TACRExpression;
                        // locate
                        KeyCondition:                 TACRScanSearchCondition; // find key
                        // find first or last record in order specified by index settings
                        Restart:                      Boolean;
                        // go from first record to last or vice versa
                        GoForward:                    Boolean;
                        // if record was found then return record id
                        ResultRecordID:               PACRRecordID;
                        // if specified - fill record bitmap
                        RecordBitmap:                 TACRRecordBitmap;
                        InternalCall:                 Boolean;
                        StopAtFirstFoundRecord:       Boolean
                                           ): Boolean;
begin
  if (InternalCall) then
    Result := inherited FindRecord(Cursor, SearchExpression, KeyCondition,
      Restart, GoForward, ResultRecordID, RecordBitmap, True,
      StopAtFirstFoundRecord)
  else
  begin
    LockTable(False, Cursor.Session, 11894);
    try
      Result := inherited FindRecord(Cursor, SearchExpression, KeyCondition,
        Restart, GoForward, ResultRecordID, RecordBitmap, False,
        StopAtFirstFoundRecord);
    finally
      UnlockTable(False, Cursor.Session);
    end;
  end;
end; // FindRecord
{$ENDIF}


//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRAdvancedTableData.IsRecordExists(Cursor: TACRCursor): Boolean;
begin
LockTable(False, Cursor.Session, 11895);
try
	Result := inherited IsRecordExists(Cursor);
finally
	UnlockTable(False, Cursor.Session);
end;
end; // IsRecordExists

//------------------------------------------------------------------------------
// read record with Distinct, SQLFilter, SQLTopRowCount, Filter, Range, OnFilterRecord
//------------------------------------------------------------------------------
function TACRAdvancedTableData.GetRecordBuffer(Cursor: TACRCursor;
	GetRecordMode: TACRGetRecordMode): TACRGetRecordResult;
begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_GetRecordBuffer}
aaWriteToLog('> TACRAdvancedTableData.GetRecordBuffer, FTableName = ' +
		FTableName + #13#10 + 'Self = ' + IntToHex(Integer(Self),
		8) + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
		+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
		True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
		True) + #13#10 + 'FTransactionSessionID = ' + IntToStr
		(FTransactionSessionID) + #13#10 + 'Cursor.Session.InTransaction = ' +
		BoolToStr(Cursor.Session.InTransaction, True) + #13#10 +
		'Cursor.FirstPosition = ' + BoolToStr(Cursor.FirstPosition,
		True) + #13#10 + 'Cursor.LastPosition = ' + BoolToStr(Cursor.LastPosition,
		True) + #13#10 + 'Cursor.CurrentRecordID = ' + IntToStr
		(Cursor.CurrentRecordID.pageNo) + '.' + IntToStr
		(Cursor.CurrentRecordID.PageItemNo) + #13#10 +
		'Cursor.CurrentRecordBuffer = ' + IntToHex
		(Integer(Cursor.CurrentRecordBuffer), 8) + #13#10 + 'GetRecordMode = ' +
		GetRecordModeToStr(GetRecordMode));
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
LockTable(False, Cursor.Session, 11896);
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time6);
{$ENDIF}
try
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_GetRecordBuffer}
	aaWriteToLog('1. TACRAdvancedTableData.GetRecordBuffer, FTableName = ' +
			FTableName + #13#10 + 'Self = ' + IntToHex(Integer(Self),
			8) + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID));
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
	aaStartTime(time2);
{$ENDIF}
	Result := inherited GetRecordBuffer(Cursor, GetRecordMode);
{$IFDEF DEBUG_SQL_TIME}
	aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_GetRecordBuffer}
	aaWriteToLog('2. TACRAdvancedTableData.GetRecordBuffer, FTableName = ' +
			FTableName + #13#10 + 'Self = ' + IntToHex(Integer(Self),
			8) + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
			+ #13#10 + 'GetRecordResult = ' + GetRecordResultToStr(Result));
{$ENDIF}
finally
{$IFDEF DEBUG_SQL_TIME}
	aaStartTime(time10);
{$ENDIF}
	UnlockTable(False, Cursor.Session);
{$IFDEF DEBUG_SQL_TIME}
	aaStopTime(time10);
{$ENDIF}
end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_GetRecordBuffer}
aaWriteToLog('< TACRAdvancedTableData.GetRecordBuffer, FTableName = ' +
		FTableName + #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
		+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
		True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
		True) + #13#10 + 'FTransactionSessionID = ' + IntToStr
		(FTransactionSessionID) + #13#10 + 'Cursor.Session.InTransaction = ' +
		BoolToStr(Cursor.Session.InTransaction, True) + #13#10 +
		'Cursor.FirstPosition = ' + BoolToStr(Cursor.FirstPosition,
		True) + #13#10 + 'Cursor.LastPosition = ' + BoolToStr(Cursor.LastPosition,
		True) + #13#10 + 'Cursor.CurrentRecordID = ' + IntToStr
		(Cursor.CurrentRecordID.pageNo) + '.' + IntToStr
		(Cursor.CurrentRecordID.PageItemNo) + #13#10 +
		'Cursor.CurrentRecordBuffer = ' + IntToHex
		(Integer(Cursor.CurrentRecordBuffer), 8) + #13#10 + 'GetRecordMode = ' +
		GetRecordModeToStr(GetRecordMode) + #13#10 + 'GetRecordResult = ' +
		GetRecordResultToStr(Result));
{$ENDIF}
end; // GetRecordBuffer

//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
function TACRAdvancedTableData.InsertRecord(var Cursor: TACRCursor): Boolean;
var
	OldPos: Pointer;
begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('> TACRAdvancedTableData.InsertRecord, FTableName = ' + FTableName
+ #13#10 + 'Self = ' + IntToHex(Integer(Self),8)
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr(Cursor.Session.InTransaction, True));
try
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time1);
try
{$ENDIF}
	if (FRecordManager = nil) then
		raise EACRException.Create(10531, ErrorLNilPointer);
	if (Cursor.CurrentRecordBuffer = nil) then
		raise EACRException.Create(10532, ErrorLNilPointer);
{$IFDEF DEBUG_TIMES_INSERT}
	aaStartTime(time2);
{$ENDIF}
	LockTable(True, Cursor.Session, 11897);
{$IFDEF DEBUG_TIMES_INSERT}
	aaStopTime(time2);
{$ENDIF}
	try
{$IFDEF DEBUG_TIMES_INSERT}
		aaStartTime(time4);
{$ENDIF}
		OldPos := Cursor.SavePosition;
{$IFDEF DEBUG_TIMES_INSERT}
		aaStopTime(time4);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('1. TACRAdvancedTableData.InsertRecord, FTableName = ' +
FTableName + #13#10 + 'SessionID = ' + IntToStr
(Cursor.Session.SessionID) + #13#10 + 'FExclusive = ' +
BoolToStr(FExclusive, True) + #13#10 + 'FInMemory = ' + BoolToStr
(FInMemory, True) + #13#10 + 'Cursor.Session.InTransaction = ' +
BoolToStr(Cursor.Session.InTransaction,
True) + #13#10 + 'FTransactionSessionID = ' + IntToStr
(FTransactionSessionID) + #13#10 + 'FFTransactionMUD = ' + BoolToStr
(FTransactionMUD, True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState)
);
{$ENDIF}
		try
        // add record to first empty space
{$IFDEF DEBUG_TIMES_INSERT}
			aaStartTime(time5);
{$ENDIF}
			if (FInMemory) then
				SetBLOBValuesModified(False, Cursor);
{$IFDEF DEBUG_TIMES_INSERT}
			aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('2. TACRAdvancedTableData.InsertRecord, setting auto-inc vaslues...');
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
			aaStartTime(time6);
{$ENDIF}
			if (not Cursor.FDirectSetAutoInc) then
				FFieldManager.ApplyAutoIncValuesToRecordBuffer(Cursor.Session,
					Cursor.CurrentRecordBuffer);
{$IFDEF DEBUG_TIMES_INSERT}
			aaStopTime(time6);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog(
'3. TACRAdvancedTableData.InsertRecord, checking constraints...' +
#13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
True) + #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr
(Cursor.Session.InTransaction, True) + #13#10 +
'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FFTransactionMUD = ' + BoolToStr(FTransactionMUD,
True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
			try
{$IFDEF DEBUG_TIMES_INSERT}
				aaStartTime(time7);
{$ENDIF}
				CheckConstraints(Cursor, Cursor.Session.SessionID,
					Cursor.CurrentRecordBuffer, Cursor.EditRecordBuffer, True,
					Cursor.CurrentRecordID);
        // added in v.6.00 - views with check option support  
        if (Cursor.IsViewWithCheckOption) then
        begin
          if (not IsRecordVisible(Cursor)) then
           raise EACRException.Create(12578,ErrorLCannotInsertRecordInViewWithCheckOption,[FTableName,Cursor.ViewName]);
        end;
{$IFDEF DEBUG_TIMES_INSERT}
				aaStopTime(time7);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog(
'4. TACRAdvancedTableData.InsertRecord, checking constraints... OK' +
#13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
True) + #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr
(Cursor.Session.InTransaction, True) + #13#10 +
'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FFTransactionMUD = ' + BoolToStr(FTransactionMUD,
True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
			except
				on E: Exception do
				begin
            // restore auto-inc values
				RestoreMostUpdatedData(Cursor.Session.SessionID);
				Cursor.ErrorCode := ACR_ERR_CONSTRAINT_VIOLATED;
				raise ;
				end;
			end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('5. TACRAdvancedTableData.InsertRecord, adding record...');
{$ENDIF}
      { TODO -oLeo : make it all as procedures - no need in result, as exceptions can be raised in case of some failures }
			try
          // add record to first empty space
{$IFDEF DEBUG_TIMES_INSERT}
				aaStartTime(time8);
{$ENDIF}
				Result := FRecordManager.AddRecord(Cursor.CurrentRecordBuffer,
					Cursor.CurrentRecordID, Cursor.Session.SessionID);
{$IFDEF DEBUG_TIMES_INSERT}
				aaStopTime(time8);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog(
'6. TACRAdvancedTableData.InsertRecord, adding record...OK. ' +
#13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
True) + #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr
(Cursor.Session.InTransaction, True) + #13#10 +
'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FFTransactionMUD = ' + BoolToStr(FTransactionMUD,
True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState)
+ #13#10 + 'Result = ' + BoolToStr(Result,
True) + #13#10 + 'RecordID = ' + IntToStr
(Cursor.CurrentRecordID.pageNo) + '.' + IntToStr
(Cursor.CurrentRecordID.PageItemNo)
+ #13#10 + 'RecordCount = ' + IntToStr
(FRecordManager.GetRecordCount));
{$ENDIF}
				if (Result) then
				begin
  				if (FIndexManager.IndexDefs.Count > 0) then
	  			begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('7. TACRAdvancedTableData.InsertRecord updating IndexManager...');
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time9);
{$ENDIF}
    				FIndexManager.InsertRecord(Cursor);
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time9);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog(
'8. TACRAdvancedTableData.InsertRecord updating IndexManager...OK' +
#13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
True) + #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr
(Cursor.Session.InTransaction, True) + #13#10 +
'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FFTransactionMUD = ' + BoolToStr(FTransactionMUD,
True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
  				end; // indexes
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time10);
{$ENDIF}
  				WriteMostUpdatedData(Cursor.Session.SessionID);
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time10);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog
('9. TACRAdvancedTableData.InsertRecord MUD saved' + #13#10 +
'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
True) + #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr
(Cursor.Session.InTransaction, True) + #13#10 +
'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FFTransactionMUD = ' + BoolToStr(FTransactionMUD,
True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
          if (not Cursor.Session.InTransaction) then
          begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog(
'10. TACRAdvancedTableData.InsertRecord no transaction - writing...');
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time11);
{$ENDIF}
            UpdateTableState(ltoInsert);
            SetTableFlag(True, tffWriteFailed);
            SaveTableState;
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time11);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('11. TACRAdvancedTableData.InsertRecord no transaction - calling ApplyChanges...');
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time13);
{$ENDIF}
    				ApplyChanges(FTableState.TableState);
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time13);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('12. TACRAdvancedTableData.InsertRecord no transaction - calling ApplyChanges...OK');
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time12);
{$ENDIF}
    				SetTableFlag(False, tffWriteFailed);
    				SaveTableState;
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time12);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog(
'13. TACRAdvancedTableData.InsertRecord no transaction - writing...OK'
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,
True) + #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,
True) + #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr
(Cursor.Session.InTransaction, True) + #13#10 +
'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'FFTransactionMUD = ' + BoolToStr(FTransactionMUD,
True) + #13#10 + 'FMUDState = ' + IntToStr(FMUDState));
{$ENDIF}
				  end; // not in transaction
				Cursor.FirstPosition := False;
				Cursor.LastPosition := False;
				if (TACRRecordBitmap(Cursor.RecordBitmap).Active) then
				begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('14. TACRAdvancedTableData.InsertRecord  - updateing record bitmap...'	);
{$ENDIF}
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time14);
{$ENDIF}
  				UpdateRecordBitmapAfterInsertRecord(Cursor, OldPos);
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time14);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('15. TACRAdvancedTableData.InsertRecord  - updateing record bitmap...OK');
{$ENDIF}
				end;
	    end // Record inserted
			else
				RestoreMostUpdatedData(Cursor.Session.SessionID);
			except
				RestoreMostUpdatedData(Cursor.Session.SessionID);
				raise ;
			end;
		finally
			Cursor.FreePosition(OldPos);
		end;
	finally
{$IFDEF DEBUG_TIMES_INSERT}
aaStartTime(time3);
{$ENDIF}
		UnlockTable(True, Cursor.Session);
{$IFDEF DEBUG_TIMES_INSERT}
aaStopTime(time3);
{$ENDIF}
	end;
{$IFDEF DEBUG_TIMES_INSERT}
finally
	aaStopTime(time1);
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_InsertRecord}
aaWriteToLog('< TACRAdvancedTableData.InsertRecord, FTableName = ' + FTableName
+ #13#10 + 'Result = ' + BoolToStr(Result,True)
+ #13#10 + 'RecordID = ( '+IntToStr(Cursor.CurrentRecordID.PageNo)+' . '+ IntToStr(Cursor.CurrentRecordID.PageItemNo)+' )'
+ #13#10 + 'Self = ' + IntToHex(Integer(Self),8)
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr(Cursor.Session.InTransaction, True)
);
except
on E: Exception do
begin
aaWriteToLog('Error in TACRAdvancedTableData.InsertRecord, FTableName = ' + FTableName
+ #13#10 + 'Result = ' + BoolToStr(Result,True)
+ #13#10 + 'RecordID = ( '+IntToStr(Cursor.CurrentRecordID.PageNo)+' . '+ IntToStr(Cursor.CurrentRecordID.PageItemNo)+' )'
+ #13#10 + 'Self = ' + IntToHex(Integer(Self),8)
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr(Cursor.Session.InTransaction, True));
raise;
end;
end;
{$ENDIF}
end; // InsertRecord


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
function TACRAdvancedTableData.DeleteRecord(Cursor: TACRCursor): Boolean;
var
	bOK: Boolean;
	OldPos: Pointer;
	NewRecordID: TACRRecordID;
	FRecordID: TACRRecordID;
	Buffer: TACRRecordBuffer;
	TempBuffer: TACRRecordBuffer;
begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('> TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName
+ #13#10 + 'RecordID = ( '+IntToStr(Cursor.CurrentRecordID.PageNo)+' . '+ IntToStr(Cursor.CurrentRecordID.PageItemNo)+' )'
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr(Cursor.Session.InTransaction, True));
try
{$ENDIF}
  if (Cursor.FirstPosition) then
    raise EACRException.Create(11921, ErrorLCursorIsOnBOF,
      [FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID]);
  if (Cursor.LastPosition) then
    raise EACRException.Create(11922, ErrorLCursorIsOnEOF,
      [FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID]);
  bOK := False;
  if (FRecordManager = nil) then
    raise EACRException.Create(10560, ErrorLNilPointer);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('0 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName);
{$ENDIF}
  Result := TryToLockRecordU(Cursor.Session.SessionID, Cursor.CurrentRecordID);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('1 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
  if (not Result) then
    raise EACRException.Create(10562, ErrorLCannotLockRecordA,
      ['U', FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID,
      Cursor.CurrentRecordID.pageNo, Cursor.CurrentRecordID.PageItemNo]);
  try
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('2 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
    LockTable(True, Cursor.Session, 11898);
    try
      try
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('3 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
        FRecordID := Cursor.CurrentRecordID;
        if (not FRecordManager.IsRecordExists(Cursor.CurrentRecordID,
            Cursor.Session.SessionID)) then
          raise EACRException.Create(11923, ErrorLTableRecordDoesNotExist,
            [FTableName, BoolToStr(FInMemory, True),
            Cursor.CurrentRecordID.pageNo, Cursor.CurrentRecordID.PageItemNo,
            Cursor.Session.SessionID]);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('4 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
        Buffer := Cursor.CurrentRecordBuffer;
          // clear blob fields
        ClearBLOBFieldsInRecordBuffer(Buffer);
        TempBuffer := Cursor.AllocateRecordBuffer;
        OldPos := Cursor.SavePosition;
        try
          Cursor.CurrentRecordBuffer := TempBuffer;
          if (GetRecordBuffer(Cursor, grmNext) = grrOK) then
            NewRecordID := Cursor.CurrentRecordID
          else
          begin
          Cursor.RestorePosition(OldPos);
          if (GetRecordBuffer(Cursor, grmPrior) = grrOK) then
            NewRecordID := Cursor.CurrentRecordID;
          end;
          Cursor.RestorePosition(OldPos);
          Cursor.CurrentRecordBuffer := Buffer;
          Cursor.CurrentRecordID := FRecordID;
        finally
          Cursor.FreePosition(OldPos);
          Cursor.FreeRecordBuffer(TempBuffer);
        end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('5 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
        if (FIndexManager.IndexDefs.Count > 0) then
          FIndexManager.DeleteRecord(Cursor);
        Result := FRecordManager.DeleteRecord(FRecordID,
          Cursor.Session.SessionID);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('6 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
        if (Result) then
        begin
          if (FConstraintManager.ConstraintDefs.ForeignKeysActionsDeleteExists) then
            ExecuteForeignKeyActions(Cursor, False);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('7 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
          WriteMostUpdatedData(Cursor.Session.SessionID);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('8 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
          if (not Cursor.Session.InTransaction) then
          begin
            UpdateTableState(ltoDelete);
            SetTableFlag(True, tffWriteFailed);
            SaveTableState;
            ApplyChanges(FTableState.TableState);
            SetTableFlag(False, tffWriteFailed);
            SaveTableState;
          end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('9 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
          if (TACRRecordBitmap(Cursor.RecordBitmap).Active) then
            TACRRecordBitmap(Cursor.RecordBitmap).HideRecord
              (Cursor.CurrentRecordID);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('10 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
          if (FRecordManager.GetRecordCount = 0) then
          begin
            Cursor.FirstPosition := True;
            Cursor.LastPosition := False;
          end
          else
          begin
            Cursor.FirstPosition := False;
            Cursor.LastPosition := False;
            Cursor.CurrentRecordID := NewRecordID;
          end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('11 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
        end
        else
        begin
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('12 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
          RestoreMostUpdatedData(Cursor.Session.SessionID);
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('13 TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
        end;
      except
        RestoreMostUpdatedData(Cursor.Session.SessionID);
        raise ;
      end;
    finally
      UnlockTable(True, Cursor.Session);
    end;
  finally
    TryToUnlockRecordU(Cursor.Session.SessionID, Cursor.CurrentRecordID);
  end;
{$IFDEF DEBUG_TRACE_TACRAdvancedTableData_DeleteRecord}
aaWriteToLog('< TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName
+ #13#10 + 'Result = '+BoolToStr(Result,True)
+ #13#10 + 'RecordID = ( '+IntToStr(Cursor.CurrentRecordID.PageNo)+' . '+ IntToStr(Cursor.CurrentRecordID.PageItemNo)+' )'
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr(Cursor.Session.InTransaction, True)
);
except
 on e: Exception do
 begin
aaWriteToLog('Error in TACRAdvancedTableData.DeleteRecord, FTableName = '+FTableName
+ #13#10 + 'Result = '+BoolToStr(Result,True)
+ #13#10 + 'RecordID = ( '+IntToStr(Cursor.CurrentRecordID.PageNo)+' . '+ IntToStr(Cursor.CurrentRecordID.PageItemNo)+' )'
+ #13#10 + 'SessionID = ' + IntToStr(Cursor.Session.SessionID)
+ #13#10 + 'FExclusive = ' + BoolToStr(FExclusive,True)
+ #13#10 + 'FInMemory = ' + BoolToStr(FInMemory,True)
+ #13#10 + 'FTransactionSessionID = ' + IntToStr(FTransactionSessionID)
+ #13#10 + 'Cursor.Session.InTransaction = ' + BoolToStr(Cursor.Session.InTransaction, True)
+ #13#10 + e.Message
);
   raise;
 end;
end;
{$ENDIF}
end; // DeleteRecord


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
function TACRAdvancedTableData.UpdateRecord(Cursor: TACRCursor): Boolean;
begin
  if (Cursor.FirstPosition) then
    raise EACRException.Create(11917, ErrorLCursorIsOnBOF,
      [FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID]);
  if (Cursor.LastPosition) then
    raise EACRException.Create(11918, ErrorLCursorIsOnEOF,
      [FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID]);
  LockTable(True, Cursor.Session, 11899);
  try
    if (not FRecordManager.IsRecordExists(Cursor.CurrentRecordID,
        Cursor.Session.SessionID)) then
      raise EACRException.Create(11916, ErrorLTableRecordDoesNotExist,
        [FTableName, BoolToStr(FInMemory, True),
        Cursor.CurrentRecordID.pageNo, Cursor.CurrentRecordID.PageItemNo,
        Cursor.Session.SessionID]);
    try
      CheckConstraints(Cursor, Cursor.Session.SessionID,
        Cursor.CurrentRecordBuffer, Cursor.EditRecordBuffer, False,
        Cursor.CurrentRecordID);
      // added in v.6.00 - views with check option support
      if (Cursor.IsViewWithCheckOption) then
      begin
        if (not IsRecordVisible(Cursor)) then
         raise EACRException.Create(12579,ErrorLCannotUpdateRecordInViewWithCheckOption,[FTableName,Cursor.ViewName]);
      end;
    except
      on E: Exception do
      begin
        RestoreMostUpdatedData(Cursor.Session.SessionID);
        Cursor.ErrorCode := ACR_ERR_CONSTRAINT_VIOLATED;
        raise ;
      end;
    end;
    try
      if (FIndexManager.IndexDefs.Count > 0) then
        FIndexManager.UpdateRecord(Cursor);
      Result := FRecordManager.UpdateRecord(Cursor.CurrentRecordBuffer,
        Cursor.CurrentRecordID, Cursor.Session.SessionID);
      if (Result) then
      begin
      if (FConstraintManager.ConstraintDefs.ForeignKeysActionsUpdateExists) then
        ExecuteForeignKeyActions(Cursor, True);
      if (FInMemory) then
        SetBLOBValuesModified(False, Cursor);
      WriteMostUpdatedData(Cursor.Session.SessionID);
      if (not Cursor.Session.InTransaction) then
      begin
      UpdateTableState(ltoUpdate);
      SetTableFlag(True, tffWriteFailed);
      SaveTableState;
      ApplyChanges(FTableState.TableState);
      SetTableFlag(False, tffWriteFailed);
      SaveTableState;
      end;
      if (TACRRecordBitmap(Cursor.RecordBitmap).Active) then
        UpdateRecordBitmapAfterUpdateRecord(Cursor);
      TryToUnlockRecordU(Cursor.Session.SessionID, Cursor.CurrentRecordID);
      end
      else
        RestoreMostUpdatedData(Cursor.Session.SessionID);
    except
      RestoreMostUpdatedData(Cursor.Session.SessionID);
      raise ;
    end;
  finally
    UnlockTable(True, Cursor.Session);
  end;
end; // UpdateRecord

//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.EditRecord(Cursor: TACRCursor);
begin
if (Cursor.FirstPosition) then
	raise EACRException.Create(11919, ErrorLCursorIsOnBOF,
		[FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID]);
if (Cursor.LastPosition) then
	raise EACRException.Create(11920, ErrorLCursorIsOnEOF,
		[FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID]);
if (not Cursor.Session.InTransaction) then
begin
    // check for active transactions or other locks
if (not TryToLockTableIRW(Cursor.Session.SessionID, False)) then
	raise EACRException.Create(10552, ErrorLCannotLockTable,
		['IRW', FTableName, Cursor.Session.SessionID]);
TryToUnlockTableIRW(Cursor.Session.SessionID);
end;
  // lock record
if (not TryToLockRecordU(Cursor.Session.SessionID, Cursor.CurrentRecordID)) then
	raise EACRException.Create(10583, ErrorLCannotLockRecordA,
		['U', FTableName, BoolToStr(FInMemory, True), Cursor.Session.SessionID,
		Cursor.CurrentRecordID.pageNo, Cursor.CurrentRecordID.PageItemNo]);
end; // EditRecord

//------------------------------------------------------------------------------
// cancel record
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.CancelRecord(Cursor: TACRCursor;
	ToInsert: Boolean);
begin
inherited CancelRecord(Cursor, ToInsert);
if (not ToInsert) then
	TryToUnlockRecordU(Cursor.Session.SessionID, Cursor.CurrentRecordID);
end; // CancelRecord

//------------------------------------------------------------------------------
// delete all visible records - used in SQL DELETE
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.DeleteVisibleRecords(Cursor: TACRCursor);
var
	VisibleRecordCount: TACRRecordNo;
	TableRecordCount: TACRRecordNo;
	Filtered: Boolean;
begin
  { TODO : think about how to detect if record is locked by Edit }
LockTable(True, Cursor.Session, 11900);
try
    // delete
	try
		Filtered := TACRRecordBitmap(Cursor.RecordBitmap).Active;
		TableRecordCount := FRecordManager.GetRecordCount;
		if (Filtered) then
			VisibleRecordCount := TACRRecordBitmap(Cursor.RecordBitmap).GetRecordCount
		else
			VisibleRecordCount := TableRecordCount;
		if (VisibleRecordCount > 0) then
		begin
		if (TableRecordCount < VisibleRecordCount) then
			raise EACRException.Create(11311, ErrorLInvalidRecordCount,
				[VisibleRecordCount, TableRecordCount])
		else
			if ((TableRecordCount = VisibleRecordCount) and
					(not FConstraintManager.ConstraintDefs.ForeignKeysActionsDeleteExists
					)) then
			begin
{$IFDEF DEBUG_TRACE_DeleteVisibleRecords}
			aaWriteToLog
				('DeleteVisibleRecords starting empty table..., SessionID = ' + IntToStr(Cursor.Session.SessionID) + ', FTableName = ' + FTableName);
{$ENDIF}
			if (FInMemory) then
				InternalEmptyTable(Cursor.Session.SessionID)
			else
				FRecordManager.Empty(Cursor.Session.SessionID);
			EmptyAllIndexes(Cursor.Session.SessionID);
{$IFDEF DEBUG_TRACE_DeleteVisibleRecords}
			aaWriteToLog('DeleteVisibleRecords empty table... ok, SessionID = ' +
					IntToStr(Cursor.Session.SessionID) + ', FTableName = ' + FTableName);
{$ENDIF}
			end // empty table
			else
			begin
{$IFDEF DEBUG_TRACE_DeleteVisibleRecords}
			aaWriteToLog('DeleteVisibleRecords starting inherited..., SessionID = ' +
					IntToStr(Cursor.Session.SessionID) + ', FTableName = ' + FTableName);
{$ENDIF}
			inherited DeleteVisibleRecords(Cursor);
{$IFDEF DEBUG_TRACE_DeleteVisibleRecords}
			aaWriteToLog('DeleteVisibleRecords inherited... ok, SessionID = ' +
					IntToStr(Cursor.Session.SessionID) + ', FTableName = ' + FTableName);
{$ENDIF}
			end;
		WriteMostUpdatedData(Cursor.Session.SessionID);
		if (not Cursor.Session.InTransaction) then
		begin
		UpdateTableState(ltoDelete);
		SetTableFlag(True, tffWriteFailed);
		SaveTableState;
		ApplyChanges(FTableState.TableState);
		SetTableFlag(False, tffWriteFailed);
		SaveTableState;
		end;
		Cursor.FirstPosition := True;
		Cursor.LastPosition := False;
		end; // visible records exists
	except
		RestoreMostUpdatedData(Cursor.Session.SessionID);
		raise ;
	end;
finally
	UnlockTable(True, Cursor.Session);
end;
end; // DeleteVisibleRecords

//------------------------------------------------------------------------------
// update all visible records - used in SQL UPDATE
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.UpdateVisibleRecords(Cursor: TACRCursor;
	FieldNames: TACRWideStringList; values: array of TACRVariant;
	SkipFKCheck: Boolean = False);
begin
  { TODO : think about how to detect if record is locked by Edit }
LockTable(True, Cursor.Session, 11901);
try
	inherited UpdateVisibleRecords(Cursor, FieldNames, values, SkipFKCheck);
	WriteMostUpdatedData(Cursor.Session.SessionID);
	if (not Cursor.Session.InTransaction) then
	begin
	UpdateTableState(ltoUpdate);
	SetTableFlag(True, tffWriteFailed);
	SaveTableState;
	ApplyChanges(FTableState.TableState);
	SetTableFlag(False, tffWriteFailed);
	SaveTableState;
	end;
finally
	UnlockTable(True, Cursor.Session);
end;
end; // UpdateVisibleRecords

//------------------------------------------------------------------------------
// return number of records in the table
//------------------------------------------------------------------------------
function TACRAdvancedTableData.GetRecordCount(Cursor: TACRCursor;
	InternalCall: Boolean = False): TACRRecordNo;
begin
if (InternalCall) then
	Result := inherited GetRecordCount(Cursor, True)
else
begin
LockTable(False, Cursor.Session, 11902);
try
	Result := inherited GetRecordCount(Cursor, False);
finally
	UnlockTable(False, Cursor.Session);
end;
end;
end; // GetRecordCount

//------------------------------------------------------------------------------
// set RecNo
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.SetRecNo(Cursor: TACRCursor;
	RecNo: TACRRecordNo);
begin
LockTable(False, Cursor.Session, 11903);
try
	inherited SetRecNo(Cursor, RecNo);
finally
	UnlockTable(False, Cursor.Session);
end;
end; // SetRecNo

//------------------------------------------------------------------------------
// get RecNo
//------------------------------------------------------------------------------
function TACRAdvancedTableData.GetRecNo(Cursor: TACRCursor): TACRRecordNo;
begin
LockTable(False, Cursor.Session, 11904);
try
	Result := inherited GetRecNo(Cursor);
finally
	UnlockTable(False, Cursor.Session);
end;
end; // GetRecNo

//------------------------------------------------------------------------------
// return last autoinc value
//------------------------------------------------------------------------------
function TACRAdvancedTableData.LastAutoincValue(FieldNo: Integer;
	Session: TACRBaseSession): Int64;
var
	ID: TACRObjectID;
begin
LockTable(False, Session, 11905);
try
	ID := FFieldManager.FieldDefs[FieldNo].SequenceDefObjectId;
	Result := FSequenceManager.GetLastVal(Session, ID);
finally
	UnlockTable(False, Session);
end;
end; // LastAutoincValue

//------------------------------------------------------------------------------
// set last autoinc value
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.SetLastAutoincValue(Value: Int64;
	FieldNo: Integer; Cursor: TACRCursor);
var
	ID: TACRObjectID;
begin
LockTable(True, Cursor.Session, 11906);
try
	try
		ID := FFieldManager.FieldDefs[FieldNo].SequenceDefObjectId;
		TACRSequenceDef(FSequenceManager.SequenceDefs.GetDefByObjectID(ID))
			.LastValue := Value;
		WriteMostUpdatedData(Cursor.Session.SessionID);
		UpdateTableState(ltoSetAutoInc);
		if (not Cursor.Session.InTransaction) then
		begin
		SetTableFlag(True, tffWriteFailed);
		SaveTableState;
		ApplyChanges(FTableState.TableState);
		SetTableFlag(False, tffWriteFailed);
		SaveTableState;
		end;
	except
		if (not Cursor.Session.InTransaction) then
			FCache.CancelChanges;
		ReadMostUpdatedData(Cursor.Session.SessionID);
		raise ;
	end;
finally
	UnlockTable(True, Cursor.Session);
end;
end; // SetLastAutoincValue

//------------------------------------------------------------------------------
// apply all changes made by active session
//------------------------------------------------------------------------------
procedure TACRAdvancedTableData.ApplyChanges(
  // current state of the locked object that calls this method
	State1: TACRState;
  // StateType2 is for table metadata state only
	StateType2: TACRDBStateType;
  // State2 is for table metadata state only
	State2: TACRState);
begin
inherited ApplyChanges(State1, StateType2, State2);
FMUDState := State1;
FMUDLoaded := True;
  // commit finished transaction
FTransactionMUD := False;
end; // ApplyChanges

////////////////////////////////////////////////////////////////////////////////
//
// TACRTransaction
// created by TACRLocalSession
// single object can be used only by single local session and inside single thread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// return true if all tables successfully locked
//------------------------------------------------------------------------------
function TACRTransaction.TryToChangeIRWLockToRWLock: Boolean;
var
	i: Integer;
	TableData: TACRAdvancedTableData;
	startTime: Cardinal;
	MaxWaitTime: Cardinal;
	RWTableDataList: TList;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRTransaction.TryToChangeIRWLockToRWLock for commit in tables... FSessionID = '	+ IntToStr(FSessionID));
{$ENDIF}
  Result := True;
  MaxWaitTime := 0;
  RWTableDataList := TList.Create;
  try
    for i := 0 to FTableDataList.Count - 1 do
    begin
      TableData := TACRAdvancedTableData(FTableDataList.Items[i]);
      try
        // IRW only
        if (TableData.TransactionSessionID <> INVALID_SESSION_ID) then
        begin
          RWTableDataList.Add(TableData);
          if (MaxWaitTime = 0) then
            MaxWaitTime := TableData.MaxWaitLockTime;
        end;
      except
        Result := False
      end;
    end;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('1. TACRTransaction.TryToChangeIRWLockToRWLock for commit in tables... FSessionID = '+ IntToStr(FSessionID) + #13#10 + 'Result = ' + BoolToStr(Result,True) + #13#10 + 'all tables count = ' + IntToStr(FTableDataList.Count)+ #13#10 + 'RW rables count = ' + IntToStr(RWTableDataList.Count)+ #13#10 + 'maxWaitTime = ' + IntToStr(MaxWaitTime));
{$ENDIF}
    if (not Result) then
      Exit;
    startTime := aaGetTickCount;
    repeat
        // try to lock table
      Result := True;
      i := 0;
      while (i < RWTableDataList.Count) do
      begin
        TableData := TACRAdvancedTableData(RWTableDataList.Items[i]);
        try
          if (TableData.TryToLockRWForCommit(FSessionID)) then
            RWTableDataList.Delete(i)
          else
          begin
          Result := False;
          Inc(i);
          end;
        except
          Result := False;
          Exit;
        end;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('2. TACRTransaction.TryToChangeIRWLockToRWLock for commit in tables... FSessionID = '+ IntToStr(FSessionID) + #13#10 + 'Result = ' + BoolToStr(Result,True) + #13#10 + 'all tables count = ' + IntToStr(FTableDataList.Count) + #13#10 + 'RW rables count = ' + IntToStr(RWTableDataList.Count) + #13#10 + 'maxWaitTime = ' + IntToStr(MaxWaitTime) + #13#10 + 'i = ' + IntToStr(i));
{$ENDIF}
			end; // try to lock tables in RW
    until ((Result) or (ACRGetTickCountDiff(aaGetTickCount,startTime) > MaxWaitTime));
  finally
    RWTableDataList.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('< TACRTransaction.TryToChangeIRWLockToRWLock for commit in tables... FSessionID = '  + IntToStr(FSessionID) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
  end;
end; // TryToChangeIRWLockToRWLock


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRTransaction.Create(aSession: TACRBaseSession;
	aDatabaseData: TACRDatabaseData);
var
	TempList: TList;
	i: Integer;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRTransaction.Create finished. Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
FIsFinished := False;
FSession := aSession;
FSessionID := aSession.SessionID;
FDatabaseData := aDatabaseData;
FTableDataList := TList.Create;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('< TACRTransaction.Create finished. Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRTransaction.Destroy;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRTransaction.Destroy starting... Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
if (not FIsFinished) then
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('1. TACRTransaction.Destroy starting Rollback... Self = ' +
		IntToHex(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
Rollback;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('2. TACRTransaction.Destroy Rollback... OK. Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
end;
FTableDataList.Free;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('3. TACRTransaction.Destroy starting... list free ok. Self = ' +
		IntToHex(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
inherited;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('< TACRTransaction.Destroy finished');
{$ENDIF}
end; // Destroy

//------------------------------------------------------------------------------
// commit
//------------------------------------------------------------------------------
procedure TACRTransaction.Commit(FlushFileBuffers: Boolean);
var
	i: Integer;
	TableData: TACRAdvancedTableData;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRTransaction.Commit starting... Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID)
		+ ', Flush = ' + BoolToStr(FlushFileBuffers, True));
{$ENDIF}
if (not TryToChangeIRWLockToRWLock) then
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('TACRTransaction.Commit cannot lock in RW, calling rollback...');
{$ENDIF}
Rollback;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('TACRTransaction.Commit cannot lock in RW, calling rollback...ok');
{$ENDIF}
raise EACRException.Create(10826,
	ErrorLTransactionCannotBeCommittedDueToOtherTableLocks);
end;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('TACRTransaction.Commit calling commit in tables...');
{$ENDIF}
for i := 0 to FTableDataList.Count - 1 do
begin
TableData := TACRAdvancedTableData(FTableDataList.Items[i]);
try
	TableData.Commit(FSessionID);
except
	on E: Exception do
	begin
	Rollback;
	raise ;
	end;
end;
end;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('TACRTransaction.Commit calling commit in tables...ok');
{$ENDIF}
try
	if (FlushFileBuffers) then
		FDatabaseData.FlushFileBuffers;
except
end;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('TACRTransaction.Commit flushing passed');
{$ENDIF}
FIsFinished := True;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('< TACRTransaction.Commit finished. Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
end; // Commit

//------------------------------------------------------------------------------
// rollback
//------------------------------------------------------------------------------
procedure TACRTransaction.Rollback;
var
	i: Integer;
	TableData: TACRAdvancedTableData;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRTransaction.Rollback starting... Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
for i := 0 to FTableDataList.Count - 1 do
begin
TableData := TACRAdvancedTableData(FTableDataList.Items[i]);
TableData.Rollback(FSessionID);
end;
FIsFinished := True;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('< TACRTransaction.Rollback finished. Self = ' + IntToHex
		(Integer(Self), 8) + ', SessionID = ' + IntToStr(FSessionID));
{$ENDIF}
end; // Rollback

//------------------------------------------------------------------------------
// add table data to list of tables used by transaction
//------------------------------------------------------------------------------
function TACRTransaction.AddTableData(TableData: TACRTableData): Boolean;
var
	index: Integer;
begin
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('> TACRTransaction.AddTableData, TableData =' + IntToHex(Integer(TableData), 8) + #13#10 + 'Self = ' + IntToHex(Integer(Self), 8));
{$ENDIF}
  if (TableData = nil) then
    raise EACRException.Create(11908, ErrorLNilPointer);
  Result := False;
    // add only advanced table data (supporting transactions)
  if (TableData is TACRAdvancedTableData) then
  begin
    index := FTableDataList.IndexOf(TableData);
    Result := (index < 0);
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('1. TACRTransaction.AddTableData, TableData =' + IntToHex(Integer(TableData), 8) + #13#10 + 'Self = ' + IntToHex(Integer(Self),8) + #13#10 + 'index = ' + IntToStr(index) + #13#10 + 'count = ' + IntToStr(FTableDataList.Count) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
    if (Result) then
      FTableDataList.Add(TableData);
  end;
{$IFDEF DEBUG_TRACE_TRANSACTIONS}
aaWriteToLog('< TACRTransaction.AddTableData, TableData =' + IntToHex(Integer(TableData), 8) + #13#10 + 'Self = ' + IntToHex(Integer(Self),8) + #13#10 + 'Result = ' + BoolToStr(Result, True));
{$ENDIF}
end; // AddTableData

////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseData
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRDatabaseData.Lock(WriteMode: Boolean);
begin
{$IFDEF DEBUG_TRACE_TABLE_LOCKS}
aaWriteToLog('TACRDatabaseData.Lock...');
{$ENDIF}
if (WriteMode) then
	FThreadSync.WaitAndLockForWrite
else
	FThreadSync.WaitAndLockForRead;
{$IFDEF DEBUG_TRACE_TABLE_LOCKS}
aaWriteToLog('TACRDatabaseData.Lock...ok');
{$ENDIF}
end; // Lock

//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRDatabaseData.Unlock;
begin
{$IFDEF DEBUG_TRACE_TABLE_LOCKS}
aaWriteToLog('TACRDatabaseData.Unlock..');
{$ENDIF}
FThreadSync.Unlock;
{$IFDEF DEBUG_TRACE_TABLE_LOCKS}
aaWriteToLog('TACRDatabaseData.Unlock...ok');
{$ENDIF}
end; // Unlock

//------------------------------------------------------------------------------
// returns new session ID
//------------------------------------------------------------------------------
function TACRDatabaseData.GetNewSessionID: TACRSessionID;
var
	i: Integer;
begin
Lock;
try
	Result := 1;
	i := 0;
	while (i < FSessionList.Count) do
	begin
	if (TACRBaseSession(FSessionList.Items[i]).SessionID = Result) then
	begin
	Inc(Result);
	i := 0;
	continue;
	end
	else
		Inc(i);
	end;
finally
	Unlock;
end;
end; // GetNewSessionID

//------------------------------------------------------------------------------
// neeed for TACRMemDatabaseData.Destroy
//------------------------------------------------------------------------------
procedure TACRDatabaseData.DeleteAllTables;
var
	TableData: TACRTableData;
begin
Lock(True);
try
	while (FTableDataList.Count > 0) do
		try
			TableData := TACRTableData(FTableDataList.Items[0]);
			if (TableData = nil) then
				FTableDataList.Delete(0)
			else
			begin
			TableData.FDoNotLockDatabaseData := True;
			TableData.Free;
			end;
		except
		end;
finally
	Unlock;
end;
end; // TACRDatabaseData.DeleteAllTables;

//------------------------------------------------------------------------------
// neeed for CreateTable, FindOrCreateTableData
//------------------------------------------------------------------------------
procedure TACRDatabaseData.AddTableData(TableData: TACRTableData);
begin
Lock(True);
try
	FTableDataList.Add(TableData);
finally
	Unlock;
end;
end; // AddTableData

//------------------------------------------------------------------------------
// neeed for TACRTableData.Destroy
//------------------------------------------------------------------------------
procedure TACRDatabaseData.DeleteTableData(TableData: TACRTableData);
begin
{$IFDEF DEBUG_TRACE_TACRDatabaseData_DeleteTableData}
aaWriteToLog('> TACRDatabaseData.DeleteTableData. TableData = ' + IntToHex
		(Integer(TableData), 8));
{$ENDIF}
Lock(True);
try
	FTableDataList.Remove(TableData);
{$IFDEF DEBUG_TRACE_TACRDatabaseData_DeleteTableData}
	aaWriteToLog(
		'1 TACRDatabaseData.DeleteTableData. after delete: FTableDataList.Count = '
			+ IntToStr(FTableDataList.Count));
{$ENDIF}
finally
	Unlock;
end;
{$IFDEF DEBUG_TRACE_TACRDatabaseData_DeleteTableData}
aaWriteToLog('< TACRDatabaseData.DeleteTableData. TableData = ' + IntToHex
		(Integer(TableData), 8));
{$ENDIF}
end; // DeleteTableData

//------------------------------------------------------------------------------
// neeed for ConnectSession
//------------------------------------------------------------------------------
procedure TACRDatabaseData.AddSession(Session: TACRBaseSession);
begin
Lock(True);
try
	FSessionList.Add(Session);
finally
	Unlock;
end;
end; // AddSession

//------------------------------------------------------------------------------
// neeed for Disconnect
//------------------------------------------------------------------------------
procedure TACRDatabaseData.DeleteSession(Session: TACRBaseSession);
begin
Lock(True);
try
	FSessionList.Remove(Session);
finally
	Unlock;
end;
end; // DeleteSession

//------------------------------------------------------------------------------
// return number of sessions
//------------------------------------------------------------------------------
function TACRDatabaseData.GetSessionsCount: Integer;
begin
Lock;
try
	Result := FSessionList.Count;
finally
	Unlock;
end;
end; // GetSessionsCount

//------------------------------------------------------------------------------
// get tables list
//------------------------------------------------------------------------------
procedure TACRDatabaseData.InternalGetTablesList(Session: TACRBaseSession;	List: TACRWideStringList);
var i: Integer;
begin
  for i := 0 to FTableDataList.Count - 1 do
    if (FTableDataList.Items[i] <> nil) then
      List.Add(TACRTableData(FTableDataList.Items[i]).TableName);
end; // InternalGetTablesList


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRDatabaseData.Create;
begin
  FThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False, Self);
  FSessionList := TList.Create;
  FTableDataList := TList.Create;
  FObjectIdSequence := TACRSequenceDef.Create;
  FPageManager := nil;
  FStoredFunctionsManager := nil;
end; // Create

//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRDatabaseData.Destroy;
var
	DBDatas: TList;
begin
  DeleteAllTables;
  DBDatas := DBDataList.LockList;
  try
    DBDatas.Remove(Self);
  finally
    DBDataList.UnlockList;
  end;
  if (FStoredFunctionsManager <> nil) then
  begin
    FStoredFunctionsManager.Free;
    FStoredFunctionsManager := nil;
  end;
  FObjectIdSequence.Free;
  FTableDataList.Free;
  FSessionList.Free;
  FThreadSync.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Connect local session
//------------------------------------------------------------------------------
procedure TACRDatabaseData.ConnectSession(Session: TACRBaseSession);
begin
AddSession(Session);
end; // ConnectSession

//------------------------------------------------------------------------------
// disconnect local session
//------------------------------------------------------------------------------
procedure TACRDatabaseData.DisconnectSession(Session: TACRBaseSession);
begin
DeleteSession(Session);
end; // DisconnectSession

//------------------------------------------------------------------------------
// FreeIfNoSessionsConnected
//------------------------------------------------------------------------------
procedure TACRDatabaseData.FreeIfNoSessionsConnected;
begin
end; // FreeIfNoSessionsConnected


//------------------------------------------------------------------------------
// get list of tables
//------------------------------------------------------------------------------
procedure TACRDatabaseData.GetTablesList(Session: TACRBaseSession; List: TACRWideStringList);
begin
  Lock;
  try
    InternalGetTablesList(Session, List);
  finally
    Unlock;
  end;
end; // GetTablesList


//------------------------------------------------------------------------------
// get all tables info - name, state, etc.
//------------------------------------------------------------------------------
function TACRDatabaseData.GetTablesInfo(SortByTableName: Boolean): TACRTableInfoArray;
var
      i:          Integer;
      TableData:  TACRTableData;
begin
  Lock(False);
  try
    SetLength(Result, FTableDataList.Count);
    for i := 0 to FTableDataList.Count - 1 do
    begin
      TableData := FTableDataList.Items[i];
      Result[i].TableName := TableData.TableName;
      Result[i].Comment := TableData.Comment;
      Result[i].CreationDate := TableData.CreationDate;
      Result[i].TableState := TableData.TableState;
    end;
    if ((FTableDataList.Count > 0) and SortByTableName) then
    begin
      ACRSortTableInfo(Result, 0, High(Result));
    end;
  finally
    Unlock;
  end;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// get table state
//------------------------------------------------------------------------------
function TACRDatabaseData.GetTableState(TableName: WideString): TACRTableState;
var
	i: Integer;
	nameCRC: Cardinal;
begin
  FillChar(Result, Sizeof(Result), $00);
  if (Length(TableName) <= 0) then
    Exit;
  Lock(False);
  try
    if (FTableDataList.Count > 0) then
    begin
    nameCRC := GetTableNameCRC(TableName);
    for i := 0 to FTableDataList.Count - 1 do
      if (FTableDataList.Items[i] <> nil) then
        if (TACRTableData(FTableDataList.Items[i]).FTableNameCRC = nameCRC) then
        begin
        Result := TACRTableData(FTableDataList.Items[i]).TableState;
        break;
        end;
    end;
  finally
    Unlock;
  end;
end; // GetTableState


//------------------------------------------------------------------------------
// TableExists
//------------------------------------------------------------------------------
function TACRDatabaseData.TableExists(Session: TACRBaseSession;	TableName: WideString): Boolean;
var
	i:        Integer;
	nameCRC:  Cardinal;
begin
{$IFDEF DEBUG_TRACE_TACRDatabaseData_TableExists}
aaWriteToLog('> TACRDatabaseData.TableExists' + #13#10 + 'Self = ' + IntToHex
(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
'DatabaseName = ' + FDatabaseName + #13#10 + 'TableName = ' + TableName +
#13#10 + 'Length(TableName) = ' + IntToStr(Length(TableName)));
try
{$ENDIF}
	Result := False;
	if (Length(TableName) <= 0) then
		Exit;
	Lock(False);
	try
{$IFDEF DEBUG_TRACE_TACRDatabaseData_TableExists}
aaWriteToLog('1 TACRDatabaseData.TableExists' + #13#10 + 'ClassName = ' +
Self.ClassName + #13#10 + 'DatabaseName = ' + FDatabaseName + #13#10 +
'TableName = ' + TableName + #13#10 + 'Length(TableName) = ' + IntToStr
(Length(TableName)) + #13#10 + 'FTableDataList.Count = ' + IntToStr
(FTableDataList.Count));
{$ENDIF}
		if (FTableDataList.Count > 0) then
		begin
  		nameCRC := GetTableNameCRC(TableName);
{$IFDEF DEBUG_TRACE_TACRDatabaseData_TableExists}
aaWriteToLog('2 TACRDatabaseData.TableExists' + #13#10 + 'Self = ' +
IntToHex(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName +
#13#10 + 'DatabaseName = ' + FDatabaseName + #13#10 + 'TableName = ' +
TableName + #13#10 + 'Length(TableName) = ' + IntToStr
(Length(TableName)) + #13#10 + 'FTableDataList.Count = ' + IntToStr
(FTableDataList.Count) + #13#10 + 'nameCRC = ' + IntToHex(nameCRC, 8));
{$ENDIF}
		for i := 0 to FTableDataList.Count - 1 do
			if (FTableDataList.Items[i] <> nil) then
{$IFDEF DEBUG_TRACE_TACRDatabaseData_TableExists}
begin
aaWriteToLog('3 TACRDatabaseData.TableExists' + #13#10 + 'Self = ' +
IntToHex(Integer(Self),
8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
'DatabaseName = ' + FDatabaseName + #13#10 + 'TableName = ' +
TableName + #13#10 + 'Length(TableName) = ' + IntToStr
(Length(TableName)) + #13#10 + 'FTableDataList.Count = ' + IntToStr
(FTableDataList.Count) + #13#10 + 'i = ' + IntToStr(i)
+ #13#10 + 'nameCRC = ' + IntToHex(nameCRC, 8) + #13#10 +
'TACRTableData(FTableDataList.Items[i]).FTableNameCRC = ' + IntToHex
(TACRTableData(FTableDataList.Items[i]).FTableNameCRC, 8) + #13#10 +
'TACRTableData(FTableDataList.Items[i]).FTableName = ' + TACRTableData
(FTableDataList.Items[i]).FTableName);
{$ENDIF}
			if (TACRTableData(FTableDataList.Items[i]).FTableNameCRC = nameCRC) then
			begin
        Result := True;
        break;
			end;
{$IFDEF DEBUG_TRACE_TACRDatabaseData_TableExists}
end;
{$ENDIF}
		end;
	finally
		Unlock;
	end;
{$IFDEF DEBUG_TRACE_TACRDatabaseData_TableExists}
finally
aaWriteToLog('< TACRDatabaseData.TableExists' + #13#10 + 'Self = ' + IntToHex
(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
'DatabaseName = ' + FDatabaseName + #13#10 + 'TableName = ' + TableName +
#13#10 + 'Length(TableName) = ' + IntToStr(Length(TableName))
+ #13#10 + 'Result = ' + BoolToStr(Result, True));
end;
{$ENDIF}
end; // TableExists


//------------------------------------------------------------------------------
// CreateDatabase
//------------------------------------------------------------------------------
procedure TACRDatabaseData.CreateDatabase(Session: TACRBaseSession);
begin
end; // CreateDatabase


//------------------------------------------------------------------------------
// find table data
//------------------------------------------------------------------------------
function TACRDatabaseData.FindTableData(Cursor: TACRCursor): TACRTableData;
var
	i: Integer;
	nameCRC: Cardinal;
begin
{$IFDEF DEBUG_TRACE_TACRDatabaseData_FindTableData}
aaWriteToLog('> TACRDatabaseData.FindTableData' + #13#10 + 'Self = ' + IntToHex
		(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName + #13#10 +
		'DatabaseName = ' + FDatabaseName + #13#10 + 'Cursor = ' + IntToHex
		(Integer(Cursor), 8));
try
{$ENDIF}
	Lock;
	try
		Result := nil;
{$IFDEF DEBUG_TRACE_TACRDatabaseData_FindTableData}
		aaWriteToLog('1 TACRDatabaseData.FindTableData' + #13#10 + 'Self = ' +
				IntToHex(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName +
				#13#10 + 'DatabaseName = ' + FDatabaseName + #13#10 + 'Cursor = ' +
				IntToHex(Integer(Cursor), 8) + #13#10 + 'FTableDataList.Count = ' +
				IntToStr(FTableDataList.Count) + #13#10 + 'TableName = ' +
				Cursor.TableName + #13#10 + 'Length(TableName) = ' + IntToStr
				(Length(Cursor.TableName)));
{$ENDIF}
		if (FTableDataList.Count > 0) then
		begin
		nameCRC := GetTableNameCRC(Cursor.TableName);
{$IFDEF DEBUG_TRACE_TACRDatabaseData_FindTableData}
		aaWriteToLog('2 TACRDatabaseData.FindTableData' + #13#10 + 'Self = ' +
				IntToHex(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName +
				#13#10 + 'DatabaseName = ' + FDatabaseName + #13#10 + 'Cursor = ' +
				IntToHex(Integer(Cursor), 8) + #13#10 + 'FTableDataList.Count = ' +
				IntToStr(FTableDataList.Count) + #13#10 + 'TableName = ' +
				Cursor.TableName + #13#10 + 'Length(TableName) = ' + IntToStr
				(Length(Cursor.TableName)) + #13#10 + 'nameCRC = ' + IntToHex(nameCRC,
				8));
{$ENDIF}
		for i := 0 to FTableDataList.Count - 1 do
{$IFDEF DEBUG_TRACE_TACRDatabaseData_FindTableData}
		begin
		aaWriteToLog('2 TACRDatabaseData.FindTableData' + #13#10 + 'Self = ' +
				IntToHex(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName +
				#13#10 + 'DatabaseName = ' + FDatabaseName + #13#10 + 'Cursor = ' +
				IntToHex(Integer(Cursor), 8) + #13#10 + 'FTableDataList.Count = ' +
				IntToStr(FTableDataList.Count) + #13#10 + 'i = ' + IntToStr(i)
				+ #13#10 + 'TableName = ' + Cursor.TableName + #13#10 +
				'nameCRC = ' + IntToHex(nameCRC, 8) + #13#10 +
				'TACRTableData(FTableDataList.Items[i]).TableName = ' + TACRTableData
				(FTableDataList.Items[i]).FTableName + #13#10 +
				'TACRTableData(FTableDataList.Items[i]).TableNameCRC = ' + IntToHex
				(TACRTableData(FTableDataList.Items[i]).FTableNameCRC, 8));
{$ENDIF}
		if (TACRTableData(FTableDataList.Items[i]).FTableNameCRC = nameCRC) then
		begin
		Result := FTableDataList.Items[i];
		break;
		end;
{$IFDEF DEBUG_TRACE_TACRDatabaseData_FindTableData}
		end;
{$ENDIF}
		end;
	finally
		Unlock;
	end;
{$IFDEF DEBUG_TRACE_TACRDatabaseData_FindTableData}
finally
	aaWriteToLog('< TACRDatabaseData.FindTableData' + #13#10 + 'Self = ' +
			IntToHex(Integer(Self), 8) + #13#10 + 'ClassName = ' + Self.ClassName +
			#13#10 + 'DatabaseName = ' + FDatabaseName + #13#10 + 'Cursor = ' +
			IntToHex(Integer(Cursor), 8) + #13#10 + 'Result = ' + IntToHex
			(Integer(Result), 8));
end;
{$ENDIF}
end; // FindTableData

//------------------------------------------------------------------------------
// find or create table data
//------------------------------------------------------------------------------
function TACRDatabaseData.FindOrCreateTableData(Cursor: TACRCursor)
	: TACRTableData;
begin
Result := FindTableData(Cursor);
if (Result = nil) then
	Result := CreateTableData(Cursor);
end; // FindOrCreateTableData

//------------------------------------------------------------------------------
// GetNewObjectId
//------------------------------------------------------------------------------
function TACRDatabaseData.GetNewObjectId: TACRObjectID;
begin
Result := FObjectIdSequence.GetNextVal;
end; // GetNewObjectId

//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TACRDatabaseData.FlushFileBuffers;
begin
end; // FlushFileBuffers

//------------------------------------------------------------------------------
// GetFormatVersion
//------------------------------------------------------------------------------
function TACRDatabaseData.GetFormatVersion(Session: TACRBaseSession): Double;
begin
Result := 0.0;
end; // GetFormatVersion

//------------------------------------------------------------------------------
// get count of free pages
//------------------------------------------------------------------------------
function TACRDatabaseData.GetFreePageCount(Session: TACRBaseSession): Integer;
begin
Result := 0;
end; // GetFreePageCount

//------------------------------------------------------------------------------
// get total count of pages
//------------------------------------------------------------------------------
function TACRDatabaseData.GetTotalPageCount(Session: TACRBaseSession): Integer;
begin
Result := 0;
end; // GetTotalPageCount

//------------------------------------------------------------------------------
// return true if database is encrypted
//------------------------------------------------------------------------------
function TACRDatabaseData.IsDatabaseEncrypted(Session: TACRBaseSession)
	: Boolean;
begin
Result := False;
end; // IsDatabaseEncrypted

//------------------------------------------------------------------------------
// return true if database is encrypted by password or by key
//------------------------------------------------------------------------------
function TACRDatabaseData.IsDatabaseEncryptedByPassword
	(Session: TACRBaseSession): Boolean;
begin
Result := True;
end; // IsDatabaseEncryptedByPassword

//------------------------------------------------------------------------------
// return true if CryptoParams are valid
//------------------------------------------------------------------------------
function TACRDatabaseData.IsCryptoParamsValid(Session: TACRBaseSession)
	: Boolean;
begin
Result := True;
end; // IsCryptoParamsValid

//------------------------------------------------------------------------------
// makes Exe database from edb file
//------------------------------------------------------------------------------
procedure TACRDatabaseData.MakeExeDatabase(Session: TACRBaseSession;
	ExeFileName, ExeDatabaseFileName: WideString);
begin
  // do nothing
end; // MakeExeDatabase

//------------------------------------------------------------------------------
// removes database file from executable database file
//------------------------------------------------------------------------------
procedure TACRDatabaseData.RemoveDatabaseFromExe(Session: TACRBaseSession);
begin ;
end; // RemoveDatabaseFromExe

//------------------------------------------------------------------------------
// returns true if this file is an Accuracer database
//------------------------------------------------------------------------------
function TACRDatabaseData.IsAccuracerDatabaseFile(Session: TACRBaseSession)
	: Boolean;
begin
Result := False;
end; // IsAccuracerDatabaseFile

//------------------------------------------------------------------------------
// clear disk cache in single-user / multi-user
//------------------------------------------------------------------------------
procedure TACRDatabaseData.ClearCache;
begin
if (FPageManager <> nil) then
	FPageManager.ClearCache;
end; // ClearCache

//------------------------------------------------------------------------------
// remove all locks applied to the session - for client-server if connection is lost
//------------------------------------------------------------------------------
procedure TACRDatabaseData.RemoveAllLocks(SessionID: TACRSessionID);
var
	i: Integer;
begin
Lock(False);
try
	for i := 0 to FTableDataList.Count - 1 do
		if (TObject(FTableDataList.Items[i]) is TACRAdvancedTableData) then
			TACRAdvancedTableData(FTableDataList.Items[i]).RemoveAllSessionLocks
				(SessionID);
finally
	Unlock;
end;
end; // RemoveAllLocks

//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRDatabaseData.GetTableComment(TableName: WideString): WideString;
begin
  Result := '';
end; // GetTableComment

//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRDatabaseData.SetTableComment(TableName, Comment: WideString);
begin
  // do nothing
end; // SetTableComment


//------------------------------------------------------------------------------
// create stored function / procedure
//------------------------------------------------------------------------------
procedure TACRDatabaseData.CreateStoredFunction(Session: TACRBaseSession;
	SQLScript: WideString);
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12006, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
      BoolToStr(FInMemory, True)]);
  TACRStoredFunctionManager(FStoredFunctionsManager).CreateStoredFunction(Session, SQLScript);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// for CREATE FUNCTON inside SQL script
// current token is rwFUNCTION/rwPROCEDURE
//------------------------------------------------------------------------------
procedure TACRDatabaseData.CreateStoredFunction(StoredFunction: TObject;	SQLScript: WideString);
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12105, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
      BoolToStr(FInMemory, True)]);
  TACRStoredFunctionManager(FStoredFunctionsManager).CreateStoredFunction(TACRStoredFunction(StoredFunction), SQLScript);
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// parse stored function
//------------------------------------------------------------------------------
procedure TACRDatabaseData.ParseStoredFunction(
                                                Session: TACRBaseSession;
                                                Lexer: TACRLexer; var Token: TToken;
                                                out StoredFunction: TObject;
                                                out SQLScript: WideString
                                               );
var
	f: TACRStoredFunction;
begin
  if (FStoredFunctionsManager = nil) then
  raise EACRException.Create(12107, ErrorLStoredFunctionManagerNotCreated,
    [Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
    BoolToStr(FInMemory, True)]);
  TACRStoredFunctionManager(FStoredFunctionsManager).ParseStoredFunction(Session, Lexer, Token, f, SQLScript);
  StoredFunction := f;
end; // ParseStoredFunction


//------------------------------------------------------------------------------
// drop stored function / procedure
//------------------------------------------------------------------------------
procedure TACRDatabaseData.DropStoredFunction(Session: TACRBaseSession;
	FunctionName: WideString);
begin
if (FStoredFunctionsManager = nil) then
	raise EACRException.Create(12007, ErrorLStoredFunctionManagerNotCreated,
		[Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
		BoolToStr(FInMemory, True)]);
TACRStoredFunctionManager(FStoredFunctionsManager).DropStoredFunction(Session,
	FunctionName);
end; // DropStoredFunction

//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TACRDatabaseData.AlterStoredFunction(Session: TACRBaseSession;
	FunctionName, NewSQLScript: WideString);
begin
if (FStoredFunctionsManager = nil) then
	raise EACRException.Create(12208, ErrorLStoredFunctionManagerNotCreated,
		[Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
		BoolToStr(FInMemory, True)]);
TACRStoredFunctionManager(FStoredFunctionsManager).AlterStoredFunction(Session,
	FunctionName, NewSQLScript);
end; // AlterStoredFunction

//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TACRDatabaseData.AlterStoredFunctionRename(Session: TACRBaseSession;
	FunctionName, NewFunctionName: WideString);
begin
if (FStoredFunctionsManager = nil) then
	raise EACRException.Create(12224, ErrorLStoredFunctionManagerNotCreated,
		[Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
		BoolToStr(FInMemory, True)]);
TACRStoredFunctionManager(FStoredFunctionsManager).AlterStoredFunctionRename
	(Session, FunctionName, NewFunctionName);
end; // AlterStoredFunctionRename

//------------------------------------------------------------------------------
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
//------------------------------------------------------------------------------
function TACRDatabaseData.ExecuteStoredFunction(Session: TACRBaseSession;
	FunctionName: WideString; ResultValue: TACRVariant;
	Params: TACRSQLParams): Boolean;
begin
if (FStoredFunctionsManager = nil) then
	raise EACRException.Create(12008, ErrorLStoredFunctionManagerNotCreated,
		[Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
		BoolToStr(FInMemory, True)]);
Result := TACRStoredFunctionManager(FStoredFunctionsManager)
	.ExecuteStoredFunction(Session, FunctionName, ResultValue, Params);
end; // ExecuteStoredFunction

//------------------------------------------------------------------------------
// return empty string if function not found; otherwise
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TACRDatabaseData.FindStoredFunction(FunctionName: WideString): WideString;
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12009, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode, BoolToStr(FInMemory, True)]);
  Result := TACRStoredFunctionManager(FStoredFunctionsManager).FindStoredFunction(FunctionName);
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return the stored function object if it exists in stored function manager associated with
// the atabase opened by this session
// used by TACRExprNodeStoredFunction
//------------------------------------------------------------------------------
function TACRDatabaseData.GetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TObject;
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12476, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode, BoolToStr(FInMemory, True)]);
  Result := TACRStoredFunctionManager(FStoredFunctionsManager).GetStoredFunctionByName(FunctionName,Session);
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// parse for execute
// return stored function object (TACRStoredFunction) if found or nil
// params - list of TACRExpression
//------------------------------------------------------------------------------
function TACRDatabaseData.ParseStoredFunctionParams(
                                        Session:          TACRBaseSession;
                                        Lexer:            TACRLexer;
                                        parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                                        var Token:        TToken;
                                        out Params:       TObject
                                      ): TObject;
begin
  if (FStoredFunctionsManager = nil) then
    Result := nil
  else
    Result := TACRStoredFunctionManager(FStoredFunctionsManager).ParseStoredFunctionParams(
                Session, Lexer, parentFunction, Token, Params);
end; // ParseStoredFunctionParams

//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRDatabaseData.GetStoredFunctions(
                                              FunctionNames:        TStrings;
                                              FunctionSQLScripts:   TStrings;
                                              SortNamesByAlphabet:  Boolean
                                             );
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12010, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
      BoolToStr(FInMemory, True)]);
  TACRStoredFunctionManager(FStoredFunctionsManager).GetStoredFunctions
    (FunctionNames, FunctionSQLScripts, SortNamesByAlphabet);
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRDatabaseData.GetStoredFunctions(
                                              FunctionNames:        TACRWideStringList;
                                              FunctionSQLScripts:   TACRWideStringList;
                                            	SortNamesByAlphabet:  Boolean
                                            );
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12011, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
      BoolToStr(FInMemory, True)]);
  TACRStoredFunctionManager(FStoredFunctionsManager).GetStoredFunctions
    (FunctionNames, FunctionSQLScripts, SortNamesByAlphabet);
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TACRDatabaseData.ExportStoredFunctionsToSQL(var SQL: WideString);
begin
  if (FStoredFunctionsManager = nil) then
    raise EACRException.Create(12138, ErrorLStoredFunctionManagerNotCreated,
      [Self.ClassName, FDatabaseName, FDatabaseNameUnicode,
      BoolToStr(FInMemory, True)]);
  TACRStoredFunctionManager(FStoredFunctionsManager).ExportStoredFunctionsToSQL(SQL);
end; // ExportStoredFunctionsToSQL



//--------------------------- VIEWS - added in v.6.00 --------------------------


//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TACRDatabaseData.CreateView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                                      );
begin
  raise EACRException.Create(12562,ErrorLOperationIsNotSupported);
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TACRDatabaseData.DropView(
                     Session:           TACRBaseSession;
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
begin
  raise EACRException.Create(12563,ErrorLOperationIsNotSupported);
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TACRDatabaseData.FindView(
                     Session:           TACRBaseSession;
                     ViewName:          WideString
                                  ): TACRViewDef;
begin
  Result := nil;
end; // FindView


//------------------------ END OF VIEWS - added in v.6.00 ----------------------




////////////////////////////////////////////////////////////////////////////////
//
// General functions and procedures
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return false if field value is null
//------------------------------------------------------------------------------
function GetFieldData(
                      // field number in FieldDefs
                      FieldNo: Integer;
                      // field definitions
                      FieldDefs: TACRFieldDefs;
                      // pointer to allocated buffer for storing field value
                      Buffer: Pointer;
                      // record buffer
                      RecordBuffer: TACRRecordBuffer
                     ): Boolean;
const	Zero: Word = $0000;
var	Size, ZeroSize: Integer;
{$I ACR_check_null_flag_var.inc}
begin
  // fixed in v.5.30
  Result := False;
  // check if field data is NULL
  CHECK_NULL_FLAG_BitNo := FieldNo;
  CHECK_NULL_FLAG_NullFlags := RecordBuffer;
  {$I ACR_check_null_flag.inc}
  if (CHECK_NULL_FLAG_Result) then
    Exit; // field data is NULL
  Result := True;
    // function was used only for checking a null flag - no result buffer
  if (Buffer = nil) then
    Exit;
  if (FieldNo >= Integer(FieldDefs.Count)) then
    raise EACRException.Create(10000, ErrorLInvalidFieldNumber,
      [FieldNo, FieldDefs.Count]);
    // if blob field was specified then exit
  if (IsBLOBFieldType(FieldDefs[FieldNo].AdvancedFieldType)) then
    Exit;
  if (Buffer = nil) then
    raise EACRException.Create(10001, ErrorLNilPointer);
  if (RecordBuffer = nil) then
    raise EACRException.Create(10003, ErrorLNilPointer);
  if (IsStringFieldType(FieldDefs[FieldNo].AdvancedFieldType)) then
  begin
    if (IsWideStringFieldType(FieldDefs[FieldNo].AdvancedFieldType)) then
    begin
      {$IFDEF D10H}
      ZeroSize := 2;
      Size := GetStrLength(PAnsiChar(RecordBuffer +
                FieldDefs.Items[FieldNo].MemoryOffset), FieldDefs[FieldNo].AdvancedFieldType)
                + ZeroSize;
      if (Size > FieldDefs.Items[FieldNo].MemoryDataSize) then
        Size := FieldDefs.Items[FieldNo].MemoryDataSize;
      try
        Move(PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset)^,
          Buffer^, Size);
      except
        raise EACRException.Create(70733, ErrorLErrorGettingFieldData,
          [FieldNo, FieldDefs.Items[FieldNo].MemoryOffset, Size]);
      end;
      {$ELSE}
      PWideChar(Buffer^) := PWideChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset);
      {$ENDIF}
            // WideString(Dest^) := WideString(PWideChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset));
            // ZeroSize := 2;
    end
    else
    begin
      ZeroSize := 1;
      Size := GetStrLength(PAnsiChar(RecordBuffer +
                FieldDefs.Items[FieldNo].MemoryOffset), FieldDefs[FieldNo].AdvancedFieldType)
                + ZeroSize;
      if (Size > FieldDefs.Items[FieldNo].MemoryDataSize) then
        Size := FieldDefs.Items[FieldNo].MemoryDataSize;
      try
        Move(PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset)^,
          Buffer^, Size);
      except
        raise EACRException.Create(10733, ErrorLErrorGettingFieldData,
          [FieldNo, FieldDefs.Items[FieldNo].MemoryOffset, Size]);
      end;
    end;
  end // AnsiString or wide AnsiString field
  else
    try
      Move(PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset)^,
        Buffer^, FieldDefs.Items[FieldNo].MemoryDataSize);
    except
      raise EACRException.Create(10002, ErrorLErrorGettingFieldData,
        [FieldNo, FieldDefs.Items[FieldNo].MemoryOffset,
        FieldDefs.Items[FieldNo].MemoryDataSize]);
    end;
end; // GetFieldData


//------------------------------------------------------------------------------
// return false if field value is null
//------------------------------------------------------------------------------
procedure SetFieldData(
                        // physical field No
                        FieldNo: Integer;
                        // field definitions
                        FieldDefs: TACRFieldDefs;
                        // pointer to allocated buffer with new field value
                        Buffer: Pointer;
                        // record buffer
                        RecordBuffer: TACRRecordBuffer
                      );
const Zero: Word = $0000;
var
	Size, ZeroSize: Integer;
	Source:         PAnsiChar;
{$I ACR_set_null_flag_var.inc}
begin
  // fixed in v.5.30
  if (FieldNo > Integer(FieldDefs.Count)) then
    raise EACRException.Create(10004, ErrorLInvalidFieldNumber,
      [FieldNo, FieldDefs.Count]);
  if (Buffer = nil) then
  begin
    // set null flag only
    SET_NULL_FLAG_ToSet := True;
    SET_NULL_FLAG_BitNo := FieldNo;
    SET_NULL_FLAG_NullFlags := RecordBuffer;
    {$I ACR_set_null_flag.inc}
  end // set null flag only
  else
  begin
    // not empty field
    SET_NULL_FLAG_ToSet := False;
    SET_NULL_FLAG_BitNo := FieldNo;
    SET_NULL_FLAG_NullFlags := RecordBuffer;
    {$I ACR_set_null_flag.inc}
      // copy data
    if (IsStringFieldType(FieldDefs[FieldNo].AdvancedFieldType)) then
    begin
      if (IsWideStringFieldType(FieldDefs[FieldNo].AdvancedFieldType)) then
      begin
        {$IFDEF D10H}
        Source := Buffer;
        {$ELSE}
        Source := PAnsiChar(Buffer^);
        {$ENDIF}
        ZeroSize := 2;
      end
      else
      begin
        ZeroSize := 1;
        Source := Buffer;
      end;
      Size := GetStrLength(PAnsiChar(Source), FieldDefs[FieldNo].AdvancedFieldType);
      // empty AnsiString
      if (Size <= 0) then
      begin
        SET_NULL_FLAG_ToSet := True;
        SET_NULL_FLAG_BitNo := FieldNo;
        SET_NULL_FLAG_NullFlags := RecordBuffer;
        {$I ACR_set_null_flag.inc}
      end
      else
      begin
      try
        if (Size + ZeroSize > FieldDefs.Items[FieldNo].MemoryDataSize) then
        begin
          Size := FieldDefs.Items[FieldNo].MemoryDataSize - ZeroSize;
          Move(Source^, PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset)^, Size);
        end
        else
        begin
          Move(Source^, PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset)^, Size);
        end;
        // move zero to the end of AnsiString if it is possible
        Move(Zero,
          PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo].MemoryOffset + Size)^,
          ZeroSize);
      except
        raise EACRException.Create(10734, ErrorLErrorGettingFieldData,
          [FieldNo, FieldDefs.Items[FieldNo].MemoryOffset, Size]);
      end;
    end;
  end // AnsiString or wide AnsiString field
  else
    try
      Move(Buffer^,
        PAnsiChar(RecordBuffer + FieldDefs.Items[FieldNo]
            .MemoryOffset)^, FieldDefs.Items[FieldNo].MemoryDataSize);
    except
      raise EACRException.Create(10732, ErrorLErrorGettingFieldData,
        [FieldNo, FieldDefs.Items[FieldNo].MemoryOffset,
        FieldDefs.Items[FieldNo].MemoryDataSize]);
    end;
  end; // set field data
end; // SetFieldData


//------------------------------------------------------------------------------
// return true if record buffers are binary identical
//------------------------------------------------------------------------------
function CompareRecordBuffers(RecordBuffer1, RecordBuffer2: TACRRecordBuffer;
	RecordBufferSize: Integer): Boolean;
var
	i: Integer;
begin
if (RecordBuffer1 = nil) then
	raise EACRException.Create(10122, ErrorLNilPointer);
if (RecordBuffer2 = nil) then
	raise EACRException.Create(10123, ErrorLNilPointer);
Result := True;
for i := 0 to RecordBufferSize - 1 do
	if (PAnsiChar(RecordBuffer1 + i)^ <> PAnsiChar(RecordBuffer2 + i)^) then
	begin
	Result := False;
	break;
	end;
end; // CompareRecordBuffers
{$IFNDEF SQLMEMTABLE}

//------------------------------------------------------------------------------
// compresses and encrypts buffer
//------------------------------------------------------------------------------
procedure CompressAndEncryptBuffer(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; InBuffer: PAnsiChar;
	InSize: Integer; out OutBuffer: PAnsiChar; out OutSize: Integer);
var
	ca: TACRCompressionAlgorithm;
	Buffer: PAnsiChar;
	BufferSize: Integer;
	CRC32: Cardinal;
begin
{$IFDEF DEBUG_LOG_CompressAndEncryptBuffer}
aaWriteToLog('> CompressAndEncryptBuffer: ' + #13#10 +
		'CryptoInfo.Algorithm = ' + IntToStr
		(CryptoInfo.CryptoAlgorithm) + #13#10 + 'CryptoInfo.Mode = ' + IntToStr
		(CryptoInfo.CryptoMode) + #13#10 + 'CryptoInfo.Password = ' +
		CryptoInfo.Password + #13#10 + 'CryptoInfo.UseInitVector = ' + BoolToStr
		(CryptoInfo.UseInitVector, True) + #13#10 + 'CompressionAlgorithm = ' +
		IntToStr(CompressionAlgorithm) + #13#10 + 'CompressionMode = ' + IntToStr
		(CompressionMode) + #13#10 + 'InBuffer = ' + IntToHex(Integer(InBuffer),
		8) + #13#10 + 'InSize = ' + IntToStr(InSize));
{$ENDIF}
if (CompressionAlgorithm > ACR_MAX_COMPRESSION_ALGORITHM) then
	raise EACRException.Create(12246, ErrorLInvalidCompressionAlgorithm,
		[CompressionAlgorithm]);
if (CompressionMode > ACR_MAX_COMPRESSION_MODE) then
	raise EACRException.Create(12247, ErrorLInvalidCompressionMode,
		[CompressionMode]);
if (CryptoInfo.CryptoAlgorithm > ACR_MAX_Cipher_Algorithm) then
	raise EACRException.Create(12248, ErrorLInvalidCryptoAlgorithm,
		[CryptoInfo.CryptoAlgorithm]);
if (CryptoInfo.CryptoMode > ACR_MAX_Cipher_Mode) then
	raise EACRException.Create(12249, ErrorLInvalidCryptoMode,
		[CryptoInfo.CryptoMode]);

ca := TACRCompressionAlgorithm(CompressionAlgorithm);
if ((ca = acaNone) and (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None)) or
	(InSize <= 0) or (InBuffer = nil) then
begin
OutBuffer := InBuffer;
OutSize := InSize;
{$IFDEF DEBUG_LOG_CompressAndEncryptBuffer}
aaWriteToLog('< CompressAndEncryptBuffer 1');
{$ENDIF}
Exit;
end;
if (ca <> acaNone) then
begin
ACRInternalCompressBuffer(ca, CompressionMode, InBuffer, InSize, Buffer,
	BufferSize);
{$IFDEF DEBUG_LOG_CompressAndEncryptBuffer}
if (BufferSize > 0) and (Buffer <> nil) then
	CRC32 := ACRCountCRC(0, Buffer, BufferSize)
else
	CRC32 := 0;
aaWriteToLog('COMPRESS> InSize = ' + IntToStr(InSize) + #13#10 +
		'COMPRESS> BufferSize = ' + IntToStr(BufferSize)
		+ #13#10 + 'COMPRESS> Buffer = ' + IntToHex(Integer(Buffer), 4) + #13#10 +
		'COMPRESS> CRC32  of compressed buffer = ' + IntToHex(CRC32, 4) + #13#10);
{$ENDIF}
try
	if (Buffer <> nil) and (BufferSize > 0) then
	begin
	if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
	begin
	OutSize := BufferSize + Sizeof(BufferSize);
	OutBuffer := MemoryManager.GetMem(OutSize);
	Move(InSize, OutBuffer^, Sizeof(InSize));
	Move(Buffer^, PAnsiChar(OutBuffer + Sizeof(BufferSize))^, BufferSize);
	end // no ecnryption
	else
	begin
	OutSize := BufferSize + Sizeof(CRC32) + Sizeof(BufferSize);
	OutBuffer := MemoryManager.GetMem(OutSize);
	Move(InSize, PAnsiChar(OutBuffer + Sizeof(CRC32))^, Sizeof(InSize));
	Move(Buffer^, PAnsiChar(OutBuffer + Sizeof(CRC32) + Sizeof(BufferSize))^,
		BufferSize);
	CRC32 := ACRCountCRC(0, PAnsiChar(OutBuffer + Sizeof(CRC32)),
		OutSize - Sizeof(CRC32));
	Move(CRC32, OutBuffer^, Sizeof(CRC32));
	ACREncryptBuffer(CryptoInfo, PAnsiChar(OutBuffer + Sizeof(CRC32)),
		OutSize - Sizeof(CRC32));
	end; // encryption
	end;
{$IFDEF DEBUG_LOG_CompressAndEncryptBuffer}
	if (OutSize > 0) and (OutBuffer <> nil) then
		CRC32 := ACRCountCRC(0, OutBuffer, OutSize)
	else
		CRC32 := 0;
	aaWriteToLog('COMPRESS> BufferSize = ' + IntToStr(BufferSize)
			+ #13#10 + 'COMPRESS> OutSize = ' + IntToStr(OutSize) + #13#10 +
			'COMPRESS> MemMgrOutBufferSize = ' + IntToStr
			(MemoryManager.GetMemoryBufferSize(OutBuffer)) + #13#10 +
			'COMPRESS> OutBuffer = ' + IntToHex(Integer(OutBuffer),
			4) + #13#10 + 'COMPRESS> CRC32 = ' + IntToHex(CRC32, 4) + #13#10#13#10);
{$ENDIF}
finally
	if (Buffer <> nil) then
		FreeMem(Buffer);
end;
end // compression with or without encryption
else
begin
OutSize := InSize + Sizeof(CRC32);
OutBuffer := MemoryManager.GetMem(OutSize);
CRC32 := ACRCountCRC(0, InBuffer, InSize);
Move(CRC32, OutBuffer^, Sizeof(CRC32));
Move(InBuffer^, PAnsiChar(OutBuffer + Sizeof(CRC32))^, InSize);
ACREncryptBuffer(CryptoInfo, PAnsiChar(OutBuffer + Sizeof(CRC32)), InSize);
end; // encryption without compression
{$IFDEF DEBUG_LOG_CompressAndEncryptBuffer}
aaWriteToLog('< CompressAndEncryptBuffer 2');
if (OutSize > 0) and (OutBuffer <> nil) then
	CRC32 := ACRCountCRC(0, OutBuffer, OutSize)
else
	CRC32 := 0;
aaWriteToLog('COMPRESS> InSize = ' + IntToStr(InSize)
		+ #13#10 + 'COMPRESS> OutSize = ' + IntToStr(OutSize) + #13#10 +
		'COMPRESS> MemMgrOutBufferSize = ' + IntToStr
		(MemoryManager.GetMemoryBufferSize(OutBuffer)) + #13#10 +
		'COMPRESS> OutBuffer = ' + IntToHex(Integer(OutBuffer),
		4) + #13#10 + 'COMPRESS> CRC32 = ' + IntToHex(CRC32, 4) + #13#10#13#10);
{$ENDIF}
end; // CompressAndEncryptBuffer

//------------------------------------------------------------------------------
// decompresses and decrypts buffer; return true if successful
//------------------------------------------------------------------------------
function DecompressAndDecryptBuffer(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; var Buffer: PAnsiChar;
	var BufferSize: Integer): Boolean;
var
	ca: TACRCompressionAlgorithm;
	OutBuffer: PAnsiChar;
	OutSize: Integer;
	TempBuffer: PAnsiChar;
	TempSize: Integer;
	CRC32: Cardinal;
begin
if (CompressionAlgorithm > ACR_MAX_COMPRESSION_ALGORITHM) then
	raise EACRException.Create(12250, ErrorLInvalidCompressionAlgorithm,
		[CompressionAlgorithm]);
if (CompressionMode > ACR_MAX_COMPRESSION_MODE) then
	raise EACRException.Create(12251, ErrorLInvalidCompressionMode,
		[CompressionMode]);
if (CryptoInfo.CryptoAlgorithm > ACR_MAX_Cipher_Algorithm) then
	raise EACRException.Create(12252, ErrorLInvalidCryptoAlgorithm,
		[CryptoInfo.CryptoAlgorithm]);
if (CryptoInfo.CryptoMode > ACR_MAX_Cipher_Mode) then
	raise EACRException.Create(12253, ErrorLInvalidCryptoMode,
		[CryptoInfo.CryptoMode]);
Result := True;
if (BufferSize <= 0) or (Buffer = nil) then
begin
Buffer := nil;
BufferSize := 0;
end
else
begin
ca := TACRCompressionAlgorithm(CompressionAlgorithm);
if ((ca <> acaNone) or (CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None)) then
begin
if (ca <> acaNone) then
begin
if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
begin
Move(Buffer^, OutSize, Sizeof(OutSize));
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
if (BufferSize > 0) and (Buffer <> nil) then
	CRC32 := ACRCountCRC(0, Buffer, BufferSize)
else
	CRC32 := 0;
aaWriteToLog('DECOMPRESS> BufferSize = ' + IntToStr(BufferSize)
		+ #13#10 + 'DECOMPRESS> OutSize = ' + IntToStr(OutSize) + #13#10 +
		'DECOMPRESS> MemMgrBufferSize = ' + IntToStr
		(MemoryManager.GetMemoryBufferSize(Buffer)) + #13#10 +
		'DECOMPRESS> Buffer = ' + IntToHex(Integer(Buffer),
		4) + #13#10 + 'DECOMPRESS> CRC32 = ' + IntToHex(CRC32, 4) + #13#10);
CRC32 := ACRCountCRC(0, PAnsiChar(Buffer + Sizeof(OutSize)),
	BufferSize - Sizeof(BufferSize));
aaWriteToLog('DECOMPRESS> CRC32 of compressed buffer = ' + IntToHex(CRC32,
		4) + #13#10);
{$ENDIF}
try
            {
              sz := BufferSize-SizeOf(BufferSize);
              buf := AllocMem(sz);
              try
              Move(PAnsiChar(Buffer+SizeOf(OutSize))^,buf^,sz);
              ACRInternalDecompressBuffer(ca,
              buf,sz,
              OutBuffer,OutSize);

              finally
              FreeMem(buf);
              end;
            }

	ACRInternalDecompressBuffer(ca, PAnsiChar(Buffer + Sizeof(OutSize)),
		BufferSize - Sizeof(BufferSize), OutBuffer, OutSize);
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
	aaWriteToLog('DECOMPRESS> OutSize = ' + IntToStr(OutSize) + #13#10);
{$ENDIF}
except
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
	aaWriteToLog('DECOMPRESS> FAILED!!! OutSize = ' + IntToStr(OutSize) + #13#10);
{$ENDIF}
	Result := False;
	OutBuffer := nil;
end;
try
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
	aaWriteToLog('DECOMPRESS> Trying to free buffer = ' + IntToHex
			(Integer(Buffer), 4) + #13#10);
{$ENDIF}
	MemoryManager.FreeAndNilMem(Buffer);
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
	aaWriteToLog('DECOMPRESS> Buffer freed' + #13#10);
{$ENDIF}
	BufferSize := 0;
	if (Result and (OutBuffer <> nil) and (OutSize > 0)) then
	begin
	BufferSize := OutSize;
	Buffer := MemoryManager.GetMem(OutSize);
	Move(OutBuffer^, Buffer^, OutSize);
	end;
finally
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
	aaWriteToLog('DECOMPRESS> Trying to free out buffer = ' + IntToHex
			(Integer(OutBuffer), 4) + #13#10);
{$ENDIF}
	if (OutBuffer <> nil) then
		FreeMem(OutBuffer);
{$IFDEF DEBUG_COMPRESSANDENCRYPTBUFFER}
	aaWriteToLog('DECOMPRESS> OutBuffer freed' + #13#10);
{$ENDIF}
end;
end // no encryption
else
begin
if (BufferSize > Sizeof(CRC32) + Sizeof(TempSize)) then
begin
Move(Buffer^, CRC32, Sizeof(CRC32));
TempSize := BufferSize - Sizeof(CRC32);
TempBuffer := MemoryManager.GetMem(TempSize);
try
	Move(PAnsiChar(Buffer + Sizeof(CRC32))^, TempBuffer^, TempSize);
	MemoryManager.FreeAndNilMem(Buffer);
	BufferSize := 0;
	ACRDecryptBuffer(CryptoInfo, TempBuffer, TempSize);
	if (ACRCountCRC(0, TempBuffer, TempSize) <> CRC32) then
		Result := False
	else
	begin
	Move(TempBuffer^, OutSize, Sizeof(OutSize));
	try
		ACRInternalDecompressBuffer(ca, PAnsiChar(TempBuffer + Sizeof(OutSize)),
			TempSize - Sizeof(OutSize), OutBuffer, OutSize);
		try
			if (OutBuffer <> nil) and (OutSize > 0) then
			begin
			BufferSize := OutSize;
			Buffer := MemoryManager.GetMem(BufferSize);
			Move(OutBuffer^, Buffer^, OutSize);
			end
			else
				Result := False;
		finally
			if (OutBuffer <> nil) then
				FreeMem(OutBuffer);
		end;
	except
		Result := False;
	end;
	end;
finally
	MemoryManager.FreeAndNilMem(TempBuffer);
end;
end // buffersize is correct
else
	Result := False;
end; // encryption
end // compression with or without encryption
else
begin
if (BufferSize <= Sizeof(CRC32)) then
	Result := False
else
begin
Move(Buffer^, CRC32, Sizeof(CRC32));
TempSize := BufferSize - Sizeof(CRC32);
TempBuffer := MemoryManager.GetMem(TempSize);
try
	Move(PAnsiChar(Buffer + Sizeof(CRC32))^, TempBuffer^, TempSize);
	ACRDecryptBuffer(CryptoInfo, TempBuffer, TempSize);
	if (ACRCountCRC(0, TempBuffer, TempSize) <> CRC32) then
	begin
	Result := False;
	MemoryManager.FreeAndNilMem(TempBuffer);
	end
	except
		Result := False;
		MemoryManager.FreeAndNilMem(TempBuffer);
	end;
	if (Result) then
	begin
	MemoryManager.FreeAndNilMem(Buffer);
	Buffer := TempBuffer;
	BufferSize := TempSize;
	end;
end; // buffersize is correct
end; // encryption without compression
end; // compression or encryption
end; // source buffer is not nil
end;

//------------------------------------------------------------------------------
  // compress and encrypt stream
//------------------------------------------------------------------------------
procedure CompressAndEncryptStream(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; BlockSize: Integer;
	SourceStream: TACRStream; DestStream: TACRStream;
	OnProgress: TACRProgressEvent = nil);
var
	ca: TACRCompressionAlgorithm;
	BufSize: Integer;
	buf: PAnsiChar;
	OutSize: Integer;
	OutBuf: PAnsiChar;
	Abort: Boolean;
	d: Double;
	Header: TACRBlockHeader;
begin
Abort := False;
ca := TACRCompressionAlgorithm(CompressionAlgorithm);
SourceStream.BlockSize := BlockSize;
SourceStream.OnProgress := OnProgress;
if (ca = acaNone) and (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
	SourceStream.SaveToStream(DestStream)
else
begin
d := 0;
if (Assigned(OnProgress)) then
	OnProgress(SourceStream, d, Abort);
buf := MemoryManager.GetMem(BlockSize);
try
	while ((not Abort) and (SourceStream.Position < SourceStream.Size)) do
	begin
	if ((SourceStream.Size - SourceStream.Position) > BlockSize) then
		BufSize := BlockSize
	else
		BufSize := SourceStream.Size - SourceStream.Position;
	LoadDataFromStream(buf^, BufSize, SourceStream, 11360);
	if (ca = acaNone) then
	begin
	ACREncryptBuffer(CryptoInfo, buf, BufSize);
	SaveDataToStream(buf^, BufSize, DestStream, 11361);
	end
	else
	begin
	ACRInternalCompressBuffer(ca, CompressionMode, buf, BufSize, OutBuf, OutSize);
	try
		if (CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) then
			ACREncryptBuffer(CryptoInfo, OutBuf, OutSize);
		Header.CompressedSize := OutSize;
		Header.UncompressedSize := BufSize;
		SaveDataToStream(Header, Sizeof(Header), DestStream, 11362);
		SaveDataToStream(OutBuf^, OutSize, DestStream, 11363);
	finally
		FreeMem(OutBuf);
	end;
	end; // compression
	d := SourceStream.Position / SourceStream.Size * 100.0;
	if (Assigned(OnProgress)) then
		OnProgress(SourceStream, d, Abort);
	end; // coping data
finally
	MemoryManager.FreeAndNilMem(buf);
end;
d := 100;
if (not Abort) then
	if (Assigned(OnProgress)) then
		OnProgress(SourceStream, d, Abort);
end; // compression or encryption
end; // CompressAndEncryptStream

//------------------------------------------------------------------------------
  // decompress and decrypt stream
//------------------------------------------------------------------------------
function DecompressAndDecryptStream(const CryptoInfo: TACRCryptoInfo;
	CompressionAlgorithm: Byte; CompressionMode: Byte; BlockSize: Integer;
	SourceStream: TACRStream; DestStream: TACRStream;
	OnProgress: TACRProgressEvent = nil): Boolean;
var
	ca: TACRCompressionAlgorithm;
	BufSize: Integer;
	buf: PAnsiChar;
	OutSize: Integer;
	OutBuf: PAnsiChar;
	Abort: Boolean;
	d: Double;
	Header: TACRBlockHeader;
begin
ca := TACRCompressionAlgorithm(CompressionAlgorithm);
DestStream.BlockSize := BlockSize;
DestStream.OnProgress := OnProgress;
if (ca = acaNone) and (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
	DestStream.LoadFromStreamWithPosition(SourceStream, SourceStream.Position,
		SourceStream.Size - SourceStream.Position)
else
begin
d := 0;
if (Assigned(OnProgress)) then
	OnProgress(SourceStream, d, Abort);
if (ca = acaNone) then
begin
buf := MemoryManager.GetMem(BlockSize);
try
	while ((not Abort) and (SourceStream.Position < SourceStream.Size)) do
	begin
	if ((SourceStream.Size - SourceStream.Position) > BlockSize) then
		BufSize := BlockSize
	else
		BufSize := SourceStream.Size - SourceStream.Position;
	LoadDataFromStream(buf^, BufSize, SourceStream, 11364);
	ACRDecryptBuffer(CryptoInfo, buf, BufSize);
	SaveDataToStream(buf^, BufSize, DestStream, 11365);
	d := SourceStream.Position / SourceStream.Size * 100.0;
	if (Assigned(OnProgress)) then
		OnProgress(SourceStream, d, Abort);
	end; // coping data
finally
	MemoryManager.FreeAndNilMem(buf);
end;
end // no compression
else
begin
while ((not Abort) and (SourceStream.Position < SourceStream.Size)) do
begin
LoadDataFromStream(Header, Sizeof(Header), SourceStream, 11366);
BufSize := Header.CompressedSize;
buf := MemoryManager.GetMem(BufSize);
try
	LoadDataFromStream(buf^, BufSize, SourceStream, 11367);
	if (CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None) then
		ACRDecryptBuffer(CryptoInfo, buf, BufSize);
	OutSize := Header.UncompressedSize;
	ACRInternalDecompressBuffer(ca, buf, BufSize, OutBuf, OutSize);
	try
		SaveDataToStream(OutBuf^, OutSize, DestStream, 11368);
	finally
		FreeMem(OutBuf);
	end;
finally
	MemoryManager.FreeAndNilMem(buf);
end;
d := SourceStream.Position / SourceStream.Size * 100.0;
if (Assigned(OnProgress)) then
	OnProgress(SourceStream, d, Abort);
end; // coping data
end; // compression
d := 100;
if (not Abort) then
	if (Assigned(OnProgress)) then
		OnProgress(SourceStream, d, Abort);
end; // decompression or decryption
end; // DecompressAndDecryptStream

//------------------------------------------------------------------------------
  // encrypt content of memory stream with constant password and return it as a AnsiString
//------------------------------------------------------------------------------
procedure ACREncryptStreamTOString(ms: TACRMemoryStream; out encString: String);
const
	ACRDefaultConstantPassword = 'Qc[Z?|XfUy,^r$*Ql!ix(a;l%(]K_@,Y';
var
	CryptoInfo: TACRCryptoInfo;
	BufSize: Integer;
	tmpBufSize: Integer;
	tmpBuf: PAnsiChar;
	fm: TFormat_MIME64;
begin
BufSize := ms.Size;
encString := '';
if (BufSize > 0) then
begin
CryptoInfo.Password := ACRDefaultConstantPassword;
CryptoInfo.CryptoAlgorithm := ACR_Cipher_Rijndael_256;
CryptoInfo.CryptoMode := ACR_Cipher_Mode_CTS;
CryptoInfo.UseInitVector := False;
CompressAndEncryptBuffer(CryptoInfo, Byte(acaNone), 0, ms.Buffer, BufSize,
	tmpBuf, tmpBufSize);
fm := TFormat_MIME64.Create;
try
	encString := fm.Encode(tmpBuf^, tmpBufSize);
finally
	MemoryManager.FreeAndNilMem(tmpBuf);
	fm.Free;
end;
end;
end; // ACREncryptStreamTOString

//------------------------------------------------------------------------------
  // decrypt AnsiString to memory stream
//------------------------------------------------------------------------------
procedure ACRDecryptStringToStream(ms: TACRMemoryStream;
	const encString: String);
const
	ACRDefaultConstantPassword = 'Qc[Z?|XfUy,^r$*Ql!ix(a;l%(]K_@,Y';
var
	CryptoInfo: TACRCryptoInfo;
	BufSize: Integer;
	tmpBuf: PAnsiChar;
	s: String;
	fm: TFormat_MIME64;
begin
BufSize := Length(encString);
if (BufSize <= 0) then
	raise EACRException.Create(11693, ErrorLEmptyStringPassed);
fm := TFormat_MIME64.Create;
try
	s := fm.Decode(encString);
finally
	fm.Free;
end;
BufSize := Length(s);
ms.Size := 0;
if (BufSize > 0) then
begin
CryptoInfo.Password := ACRDefaultConstantPassword;
CryptoInfo.CryptoAlgorithm := ACR_Cipher_Rijndael_256;
CryptoInfo.CryptoMode := ACR_Cipher_Mode_CTS;
CryptoInfo.UseInitVector := False;
tmpBuf := MemoryManager.GetMem(BufSize);
try
	Move(PAnsiChar(@s[1])^, tmpBuf^, BufSize);
	s := '';
	if (not DecompressAndDecryptBuffer(CryptoInfo, Byte(acaNone), 0, tmpBuf,
			BufSize)) then
	begin
	MemoryManager.FreeAndNilMem(tmpBuf);
	raise EACRException.Create(11694, ErrorLDecryptionFailed);
	end;
        // changed in 4.98, fixed in v.4.95
	ms.SetBuffer(tmpBuf, BufSize);
	tmpBuf := nil;
finally
	if (tmpBuf <> nil) then
		MemoryManager.FreeAndNilMem(tmpBuf);
end;
end;
end; // ACRDecryptStringToStream
{$ENDIF}

//------------------------------------------------------------------------------
// find TACRDatabaseData object in global list of the databases
//------------------------------------------------------------------------------
function ACRFindDatabaseData(
                             InMemory, Temporary: Boolean;
                             DatabaseName: AnsiString;
                             DatabaseNameUnicode: WideString = ''
                            )	: TACRDatabaseData;
var
	i:          Integer;
	crc:        Cardinal;
	DBData:     TACRDatabaseData;
	DBDatas:    TList;
	bUnicode:   Boolean;
begin
  Result := nil;
  bUnicode := (not InMemory) and (not Temporary) and (DatabaseNameUnicode <> '');
  if (bUnicode) then
    crc := GetTableNameCRC(DatabaseNameUnicode, True)
  else
    crc := GetTableNameCRC(DatabaseName, True);
  DBDatas := DBDataList.LockList;
  try
    for i := 0 to DBDatas.Count - 1 do
    begin
      DBData := DBDatas.Items[i];
      if (DBData <> nil) then
      begin
        // memory database data
        if (InMemory and (not Temporary) and DBData.FInMemory) then
          if (crc = GetTableNameCRC(DBData.DatabaseName, True)) then
          begin
            Result := DBData;
            break;
          end;
              // temporary database data
        if (Temporary and (not InMemory) and DBData.FTemporary) then
          if (crc = GetTableNameCRC(DBData.DatabaseName, True)) then
          begin
            Result := DBData;
            break;
          end;
              // disk database data
        if ((not Temporary) and (not InMemory)) then
          if ((crc = GetTableNameCRC(DBData.DatabaseNameUnicode,True)) or
              (crc = GetTableNameCRC(DBData.DatabaseName, True))) then
          begin
            Result := DBData;
            break;
          end;
      end;
    end;
  finally
    DBDataList.UnlockList;
  end;
end; // FindDatabaseData


//------------------------------------------------------------------------------
// used for random object identifiers
//------------------------------------------------------------------------------
function ACRGenerateRandomCardinal: Cardinal;
begin
repeat
	Result := Cardinal(Random(MaxInt)) xor Cardinal(aaGetTickCount) xor Cardinal
		(Random(MaxInt));
until ((Result <> Cardinal(INVALID_OBJECT_ID)) and
		(Result <> Cardinal(INVALID_PAGE_NO)) and (Result <> Cardinal
			(INVALID_SESSION_ID)));
end; // ACRGenerateRandomCardinal

//------------------------------------------------------------------------------
// return true if locks are compatible
//------------------------------------------------------------------------------
function ACRIsLockCompatible(PNewSessionLock,
	PCurSessionLock: PACRSessionLockInfo): Boolean;
begin
if (PNewSessionLock = PCurSessionLock) then
	Result := True
else
	case PNewSessionLock^.WaitLockType of
	ltX:
	Result := False;
	ltIS:
	Result := (not PCurSessionLock^.LockX);
	ltS, ltIRW, ltRW:
	Result := (PCurSessionLock.WaitLockType <> ltS) and
		(PCurSessionLock.WaitLockType <> ltIRW) and
		(PCurSessionLock.WaitLockType <> ltRW);
        {
          Result := (PCurSessionLock^.NumLocksIRW = 0) and (not PCurSessionLock^.LockRW)
          and (PCurSessionLock^.NumLocksS = 0) and (not PCurSessionLock^.LockX);
        }
else
begin
          // ltU
if (PCurSessionLock^.LockU) then
	Result := (PNewSessionLock^.LockedRecordID.pageNo <>
			PCurSessionLock^.LockedRecordID.pageNo) or
		(PNewSessionLock^.LockedRecordID.PageItemNo <>
			PCurSessionLock^.LockedRecordID.PageItemNo)
else
	Result := (not PCurSessionLock^.LockX);
end;
end;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_ACRIsLockCompatible}
aaWriteToLog('< ACRIsLockCompatible' + #13#10 + 'Result = ' + BoolToStr(Result,
		True));
{$ENDIF}
end; // ACRIsLockCompatible

//------------------------------------------------------------------------------
  // return true if PNewSessionLock has higher priority
//------------------------------------------------------------------------------
function ACRIsLockPriorityHigher(PNewSessionLock,
	PCurSessionLock: PACRSessionLockInfo): Boolean;
begin
    // X is higher priority then IS
if ((PNewSessionLock^.WaitLockType = ltX) and
		(PCurSessionLock^.WaitLockType = ltIS)) then
	Result := True
else
	if (PNewSessionLock^.WaitLockType = ltU) or
		(PNewSessionLock^.WaitLockType = ltIS) then
		Result := False
	else
    // if we already have S lock we have advantage over all other sessions that have no such lock
		if ((PNewSessionLock^.NumLocksS > 0) and (PCurSessionLock^.NumLocksS = 0))
			then
			Result := True
		else
    // if we already have IRW lock we have advantage over all other sessions
			if (PNewSessionLock^.NumLocksIRW > 0) then
				Result := True
			else
				Result := False;
{$IFDEF DEBUG_TRACE_LOCK_MANAGER_ACRIsLockPriorityHigher}
aaWriteToLog('< ACRIsLockPriorityHigher' + #13#10 + 'Result = ' + BoolToStr
		(Result, True));
{$ENDIF}
end; // ACRIsLockPriorityHigher

procedure ACRSetTableFlag(var TableState: TACRTableState; ToSet: Boolean;
	Flag: TACRTableFlags);
begin
case Flag of
tffWriteFailed:
if (ToSet) then
	TableState.TableFailureFlags := TableState.TableFailureFlags or $0001
else
	TableState.TableFailureFlags := TableState.TableFailureFlags and $FFFE;
      {
        if (ToSet) then
        TableState.TableFailureFlags := FTableState.TableFailureFlags or $0002
        else
        TableState.TableFailureFlags := FTableState.TableFailureFlags and $FFFD;
      }
end;
end; // ACRSetTableFlag

function ACRGetTableFlag(var TableState: TACRTableState;
	Flag: TACRTableFlags): Boolean;
begin
Result := Boolean((TableState.TableFailureFlags shr Byte(Flag)) and $0001);
end; // ACRGetTableFlag
{$IFDEF DEBUG_LOG}

procedure ACRWriteSessionLockInfo(PSessionLock: PACRSessionLockInfo;
	MaxWaitTime: Cardinal);
begin
if (PSessionLock = nil) then
	aaWriteToLog('ACRWriteSessionLockInfo, PSessionLock = nil')
else
	aaWriteToLog('ACRWriteSessionLockInfo, PSessionLock = ' + IntToHex
			(Integer(PSessionLock), 8) + #13#10 + 'SessionID = ' + IntToStr
			(PSessionLock^.SessionID) + #13#10 + 'NumLocksIS = ' + IntToStr
			(PSessionLock^.NumLocksIS) + #13#10 + 'NumLocksS = ' + IntToStr
			(PSessionLock^.NumLocksS) + #13#10 + 'NumLocksIRW = ' + IntToStr
			(PSessionLock^.NumLocksIRW) + #13#10 + 'LockedRecordID = (' + IntToStr
			(PSessionLock^.LockedRecordID.pageNo) + '.' + IntToStr
			(PSessionLock^.LockedRecordID.PageItemNo)
			+ ')' + #13#10 + 'WaitTime = ' + IntToStr
			(PSessionLock^.WaitTime) + #13#10 + 'WaitLevel = ' + IntToStr
			(ACRGetWaitLevel(PSessionLock^.WaitTime, MaxWaitTime))
			+ #13#10 + 'WaitLockType = ' + ACRGetLockModeName(PSessionLock^.WaitLockType)
			+ #13#10 + 'IsWaiting = ' + BoolToStr(PSessionLock^.IsWaiting,
			True) + #13#10 + 'LockX = ' + BoolToStr(PSessionLock^.LockX,
			True) + #13#10 + 'LockRW = ' + BoolToStr(PSessionLock^.LockRW,
			True) + #13#10 + 'LockU = ' + BoolToStr(PSessionLock^.LockU, True));
end; // ACRWriteSessionLockInfo


procedure ACRWriteTransactionLockInfo(PTransactionLock: PACRTransactionLockInfo);
begin
if (PTransactionLock = nil) then
	aaWriteToLog('ACRWriteTransactionLockInfo, PTransactionLock = nil')
else
	aaWriteToLog('ACRWriteTransactionLockInfo: ' + #13#10 + 'SessionID = ' +IntToStr(PTransactionLock^.SessionID) + #13#10 + 'LockIS = ' + BoolToStr(PTransactionLock^.LockIS, True) + #13#10 + 'LockS = ' + BoolToStr(PTransactionLock^.LockS, True) + #13#10 + 'LockIRW = ' + BoolToStr(PTransactionLock^.LockIRW, True) + #13#10 + 'LockRW = ' + BoolToStr(PTransactionLock^.LockRW, True));
end;


procedure ACRWriteTableLockInfo(var TableLock: TACRTableLockInfo);
begin
aaWriteToLog('ACRWriteTableLockInfo: ' + #13#10 + 'LockXSessionID = ' + IntToStr
		(TableLock.LockXSessionID) + #13#10 + 'LockIRWSessionID = ' + IntToStr
		(TableLock.LockIRWSessionID) + #13#10 + 'LockRWSessionID = ' + IntToStr
		(TableLock.LockRWSessionID) + #13#10 + 'NumLockIS = ' + IntToStr
		(TableLock.NumLockIS) + #13#10 + 'NumLockS = ' + IntToStr
		(TableLock.NumLockS) + #13#10 + 'NumLockU = ' + IntToStr
		(TableLock.NumLockU));
end;
{$ENDIF}



initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRBaseEngine> initialized');
{$ENDIF}
ACRMemoryIncUseCount;

finalization

ACRMemoryDecUseCount;

end.


