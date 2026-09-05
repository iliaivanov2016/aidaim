unit SQLMemBase;

interface

uses SysUtils, Classes, Db,

// SQLMemTable units
{$I SQLMemVer.inc}

     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF}   
     SQLMemCompression,
     SQLMemLexer,
     SQLMemTypes,
{$IFNDEF SQLMEMTABLE}
     SQLMemTypesNetwork,
{$ENDIF}
     SQLMemConverts,
     SQLMemTypesRoutines,
     SQLMemVariant,
     SQLMemExcept,
     SQLMemConst;

type
 // Events
 TSQLMemFilterRecord = Pointer;


type

  TSQLMemBaseSession = class;
  TSQLMemCursor = class;
  TSQLMemIndexDef = class;
  TSQLMemFieldDef = class;

  TSQLMemFieldDefs = class;
  TSQLMemIndexDefs = class;

  TSQLMemCursorPos = record
   FirstPosition: Boolean;
   LastPosition:  Boolean;
   RecordID:      TSQLMemRecordID;
  end;
  PSQLMemCursorPos = ^TSQLMemCursorPos;

  TSQLMemSQLDatabaseParams = packed record
   Session:          TSQLMemBaseSession; // nil or default local session - TSQLMemLocalSession from TSQLMemQuery
   ParamsSet:        Boolean;
   DatabaseName:     AnsiString;
   SessionName:      AnsiString;
   InMemory:         Boolean;
   RequestLive:      Boolean;
   Params:           TParams;
   CaseInsensitive:  Boolean; // added in v.5.90
  end; // TSQLMemSQLDatabaseParams


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMetaObjectDef
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemMetaObjectDef = class (TObject)
   private
    FName:       TSQLMemObjectName;
    FObjectID:   TSQLMemObjectID;
    FNameCRC:    Cardinal;
   protected
    procedure SetName(NewName: TSQLMemObjectName);
   public
    constructor Create;
    procedure Assign(Source: TSQLMemMetaObjectDef); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
   public
    property Name: TSQLMemObjectName read FName write SetName;
    property ObjectID: TSQLMemObjectID read FObjectID write FObjectID;
    property NameCRC: Cardinal read FNameCRC;
  end; // TSQLMemMetaObjectDef


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSequenceDef
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemSequenceDef = class (TSQLMemMetaObjectDef)
   private
    FDataType:  TSQLMemBaseFieldType;
    FMinValue:  TSQLMemSequenceValue;
    FMaxValue:  TSQLMemSequenceValue;
    FLastValue: TSQLMemSequenceValue;
    FIncrement: TSQLMemSequenceValue;
    FCycled:    Boolean;
   public
    // constructor
    constructor Create;
    // Assign data from an another sequence
    procedure   Assign(Source: TSQLMemMetaObjectDef); override;
    // GetNextVal
    function GetNextVal: TSQLMemSequenceValue; virtual;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
     property DataType:  TSQLMemBaseFieldType read FDataType  write FDataType;
     property MinValue:  TSQLMemSequenceValue read FMinValue  write FMinValue;
     property MaxValue:  TSQLMemSequenceValue read FMaxValue  write FMaxValue;
     property LastValue: TSQLMemSequenceValue read FLastValue write FLastValue;
     property Increment: TSQLMemSequenceValue read FIncrement write FIncrement;
     property Cycled:    Boolean           read FCycled    write FCycled;
  end; // TSQLMemSequenceDef




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFieldDef
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemFieldDef = class (TSQLMemMetaObjectDef)
   private
    FBaseFieldType:             TSQLMemBaseFieldType;
    FAdvancedFieldType:         TSQLMemAdvancedFieldType;
    FFieldSize:                 Integer;
    FDiskDataSize:              Integer; // size of binary data in disk page or table file
    FMemoryDataSize:            Integer; // size of binary data in record buffer
    FDiskOffset:                Integer; // offset to binary data in disk page or table file
    FMemoryOffset:              Integer; // offset to binary data in record buffer
    FFieldNoReference:          Integer; // index of this field in TableData.FieldManager.FieldDefs

    // Default Value
    FSequenceDefObjectId:       TSQLMemObjectID;
    FDefaultValue:              TSQLMemVariant;

    // Blob data
    FBLOBCompressionAlgorithm:  TSQLMemCompressionAlgorithm;
    FBLOBCompressionMode:       TSQLMemCompressionMode;
    FBLOBBlockSize:             Integer;

    // Autoinc settings
    FAutoincIncrement:    Int64;
    FAutoincInitialValue: Int64;
    FAutoincMinValue:     Int64;
    FAutoincMaxValue:     Int64;
    FAutoincCycled:       ByteBool;

    FEngineVersion:       Double;

   private
    procedure RecalcInternalSizes;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure SetFieldDefDataType(
                                  AdvancedFieldType: TSQLMemAdvancedFieldType;
                                  FieldSize:        Integer = 0
                                 ); overload;
    procedure SetFieldDefDataType(
                                  BaseFieldType: TSQLMemBaseFieldType;
                                  FieldSize:        Integer = 0
                                 ); overload;

    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;

   public
    property BaseFieldType: TSQLMemBaseFieldType read FBaseFieldType write FBaseFieldType;
    property AdvancedFieldType: TSQLMemAdvancedFieldType read FAdvancedFieldType write FAdvancedFieldType;
    property FieldSize: Integer read FFieldSize write FFieldSize;
    property DiskOffset: Integer read FDiskOffset write FDiskOffset;
    property MemoryOffset: Integer read FMemoryOffset write FMemoryOffset;
    property DiskDataSize: Integer read FDiskDataSize write FDiskDataSize;
    property MemoryDataSize: Integer read FMemoryDataSize write FMemoryDataSize;
    property FieldNoReference: Integer read FFieldNoReference write FFieldNoReference;

    //property DefaultValueType: TSQLMemDefaultValueType read FDefaultValueType write FDefaultValueType;
    property SequenceDefObjectId: TSQLMemObjectID read FSequenceDefObjectId write FSequenceDefObjectId;
    property DefaultValue: TSQLMemVariant read FDefaultValue write FDefaultValue;

    property AutoincIncrement: Int64    read FAutoincIncrement  write   FAutoincIncrement;
    property AutoincInitialValue: Int64 read FAutoincInitialValue write FAutoincInitialValue;
    property AutoincMinValue:  Int64    read FAutoincMinValue   write   FAutoincMinValue;
    property AutoincMaxValue:  Int64    read FAutoincMaxValue   write   FAutoincMaxValue;
    property AutoincCycled:    ByteBool read FAutoincCycled     write   FAutoincCycled;

    property BLOBCompressionAlgorithm: TSQLMemCompressionAlgorithm read FBLOBCompressionAlgorithm write FBLOBCompressionAlgorithm;
    property BLOBCompressionMode: TSQLMemCompressionMode read FBLOBCompressionMode write FBLOBCompressionMode;
    property BLOBBlockSize: Integer read FBLOBBlockSize write FBLOBBlockSize;

    property EngineVersion: Double read FEngineVersion write FEngineVersion;
  end; // TSQLMemFieldDef


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexDef
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemIndexType = (itBTree,itAnotherOne);

  TSQLMemIndexColumn = class (TObject)
   private
    FFieldName:        TSQLMemObjectName;
    FNameCRC:          Cardinal;
    FDescending:       ByteBool;
    FCaseInsensitive:  ByteBool;
   protected
    procedure SetName(NewName: TSQLMemObjectName);
   public
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
   public
    property FieldName: TSQLMemObjectName read FFieldName write FFieldName;
    property NameCRC: Cardinal read FNameCRC;
    property Descending: ByteBool read FDescending write FDescending;
    property CaseInsensitive: ByteBool read FCaseInsensitive write FCaseInsensitive;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexDef
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemIndexDef = class (TSQLMemMetaObjectDef)
   private
    FIndexType:           TSQLMemIndexType; // BTree or other
    FIndexColumns:        array of TSQLMemIndexColumn;
    FUnique:              ByteBool;
    FPrimary:             ByteBool;
    FRootPageNo:          TSQLMemPageNo;
    FTemporary:           ByteBool;

    function GetIndexColumn(Index: Integer): TSQLMemIndexColumn;
    function GetColumnCount: Integer;
    procedure SetColumnCount(Value: Integer);
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure AssignByNames(FieldNames, AscDescList, CaseSensitivityList: TStringList);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    // return -1 if field was not found, otherwise return column index
    function FindField(FieldName: WideString): Integer;
   public
    property IndexType: TSQLMemIndexType read FIndexType write FIndexType;
    property Columns[Index: Integer]: TSQLMemIndexColumn read GetIndexColumn;
    property ColumnCount: Integer read GetColumnCount write SetColumnCount;
    property Unique: ByteBool read FUnique write FUnique;
    property Primary: ByteBool read FPrimary write FPrimary;
    property RootPageNo: TSQLMemPageNo read FRootPageNo write FRootPageNo;
    property Temporary: ByteBool read FTemporary write FTemporary;
  end; // TSQLMemIndexDef


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDef
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintType = (ctPK, ctFK, ctUnique, ctNotNull, ctCheck, ctFKAction);
  TSQLMemConstraintDef = class (TSQLMemMetaObjectDef)
   private
    FConstraintType:  TSQLMemConstraintType;
   public
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
   public
    property ConstraintType: TSQLMemConstraintType read FConstraintType write FConstraintType;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefNotNull
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintDefNotNull = class (TSQLMemConstraintDef)
   private
    FColumnName:               TSQLMemObjectName;  // Column
    FColumnObjectID:           TSQLMemObjectID;
   public
    constructor Create;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure SetNames(ColumnName: WideString);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property ColumnName: TSQLMemObjectName read FColumnName write FColumnName;
    property ColumnObjectID: TSQLMemObjectID read FColumnObjectID write FColumnObjectID;
  end;// TSQLMemConstraintDefNotNull


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefCheck
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintDefCheck = class (TSQLMemConstraintDef)
   private
    FColumnName:          TSQLMemObjectName;  // Column
    FColumnObjectID:      TSQLMemObjectID;
    FMinValue:            TSQLMemVariant;
    FMaxValue:            TSQLMemVariant;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure SetNames(ColumnName: WideString);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property MinValue: TSQLMemVariant read FMinValue;
    property MaxValue: TSQLMemVariant read FMaxValue;
    property ColumnName: TSQLMemObjectName read FColumnName write FColumnName;
    property ColumnObjectID: TSQLMemObjectID read FColumnObjectID write FColumnObjectID;
  end;//TSQLMemConstraintDefCheck


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefUnique
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintColumn = record
    ColumnName:          TSQLMemObjectName;  // Column
    ColumnObjectID:      TSQLMemObjectID;
  end;


  TSQLMemConstraintDefUnique = class (TSQLMemConstraintDef)
   private
    FIndexName:                TSQLMemObjectName;  // Index ID
    FIndexObjectID:            TSQLMemObjectID;
   public
    Columns: array of TSQLMemConstraintColumn; // Columns
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property IndexName: TSQLMemObjectName read FIndexName write FIndexName;
    property IndexObjectID: TSQLMemObjectID read FIndexObjectID write FIndexObjectID;
  end;//TSQLMemConstraintDefUnique


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefPrimary
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintDefPrimary = class (TSQLMemConstraintDefUnique)
   public
    constructor Create;
  end;//TSQLMemConstraintDefPrimary


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefForeignKeyAction
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintForeignKeyMatchType = (cfkmtDefault,cfkmtFull,cfkmtPartial);
  TSQLMemConstraintForeignKeyAction = (cfkaDefault, cfkaCascade,cfkaSetNull,cfkaSetDefault,cfkaNoAction);

  // FKAction is an action of master table on update or/and on delete for FK in detail table
  TSQLMemConstraintDefForeignKeyAction = class (TSQLMemConstraintDef)
   private
    FReferencedTableName:         TSQLMemObjectName;  // Referenced Table
    FReferencedTableObjectID:     TSQLMemObjectID;
    FReferencedFKName:            TSQLMemObjectName;  // Referenced FK
    FReferencedFKObjectID:        TSQLMemObjectID;
    FDeleteAction:                TSQLMemConstraintForeignKeyAction;
    FUpdateAction:                TSQLMemConstraintForeignKeyAction;
    FMatchType:                   TSQLMemConstraintForeignKeyMatchType;
   public
    Columns: array of TSQLMemConstraintColumn; // Columns in detail table for Set Null, SetDefault, Cascade
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property ReferencedTableName: TSQLMemObjectName read FReferencedTableName write FReferencedTableName;
    property ReferencedTableObjectID: TSQLMemObjectID read FReferencedTableObjectID write FReferencedTableObjectID;
    property ReferencedFKName: TSQLMemObjectName read FReferencedFKName write FReferencedFKName;
    property ReferencedFKObjectID: TSQLMemObjectID read FReferencedFKObjectID write FReferencedFKObjectID;
    property DeleteAction: TSQLMemConstraintForeignKeyAction read FDeleteAction write FDeleteAction;
    property UpdateAction: TSQLMemConstraintForeignKeyAction read FUpdateAction write FUpdateAction;
    property MatchType: TSQLMemConstraintForeignKeyMatchType read FMatchType write FMatchType;
  end;//TSQLMemConstraintDefForeignKeyAction


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefForeignKey
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConstraintDefForeignKey = class (TSQLMemConstraintDefForeignKeyAction)
   public
    constructor Create;
  end;//TSQLMemConstraintDefForeignKey


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemViewDef
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemViewDef = class (TSQLMemMetaObjectDef)
   private
    FSelectStatement:     WideString;
    FComment:             WideString;
    FWithCheckOption:     Boolean;
    FChildrenCRC:         TSQLMemIntegerArray;     // CRC32 of UpperCase view / table names
    FChildrenNames:       TSQLMemObjectNameArray;
    FColumnNames:         TSQLMemObjectNameArray;
    FCreationDate:        TDateTime;
   public
    constructor Create; overload;
    constructor Create(
                       aName:             WideString;
                       aSelectStatement:  WideString;
                       aChildrenNames:    TSQLMemWideStringList;
                       aColumnNames:      TSQLMemWideStringList = nil;
                       aCheckOption:      Boolean = False;
                       aComment:          WideString = ''
                      ); overload;
    destructor Destroy; override;
    procedure Assign(Source: TSQLMemMetaObjectDef); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    // return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
    function FindChild(crc: Cardinal): Boolean;
   public
    property Comment: WideString read FComment write FComment;
    property SelectStatement: WideString read FSelectStatement write FSelectStatement;
    property WithCheckOption: Boolean read FWithCheckOption write FWithCheckOption;
    property ChildrenNames: TSQLMemObjectNameArray read FChildrenNames;
    property ColumnNames: TSQLMemObjectNameArray read FColumnNames;
    property CreationDate: TDateTime read FCreationDate write FCreationDate;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// Meta Objects Defs
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemMetaObjectDefs = class(TObject)
  protected
   FDefsList:         TSQLMemSortedStringPtrArray;
   FLoadedItemCount:  Integer;
  private
   function GetCount: Integer; virtual;
   function GetDef(Index: Integer): TSQLMemMetaObjectDef;
   procedure SetDef(Index: Integer; Value: TSQLMemMetaObjectDef);

   function InternalAddCreated: TSQLMemMetaObjectDef; virtual;
  public
   procedure LoadFromStream(Stream: TStream); virtual;
   procedure SaveToStream(Stream: TStream); virtual;

   constructor Create;
   destructor Destroy; override;
   procedure Assign(Source: TSQLMemMetaObjectDefs); virtual;

   procedure Add(MetaObjectDef: TSQLMemMetaObjectDef); virtual;
   procedure Delete(Index: Integer); virtual;
   procedure Insert(Index: Integer; MetaObjectDef: TSQLMemMetaObjectDef); virtual;
   procedure Move(CurIndex, NewIndex: Integer); virtual;
   procedure Clear; virtual;

   function GetDefNumberByName(Name: WideString): Integer;
   function GetDefNumberByCRC(CRC: Cardinal): Integer;
   function GetDefByName(Name: WideString): TSQLMemMetaObjectDef;
   function GetDefNumberByObjectId(id: TSQLMemObjectID): Integer;
   function GetDefByObjectId(id: TSQLMemObjectID): TSQLMemMetaObjectDef;
  public
   property Count: Integer read GetCount;
   property Items[Index: Integer]: TSQLMemMetaObjectDef read GetDef write SetDef; default;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexDefs
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemIndexDefs = class(TSQLMemMetaObjectDefs)
  private
   function GetIndexDef(Index: Integer): TSQLMemIndexDef; virtual;
   procedure SetIndexDef(Index: Integer; Value: TSQLMemIndexDef); virtual;
   function InternalAddCreated: TSQLMemMetaObjectDef; override;
  public
   // AscDesc and CaseSensitivity lists should contain constants SQLMem_ASC, SQLMem_DESC, SQLMem_NO_CASE, SQLMem_CASE
   function IsIndexExists(FieldNames, AscDescList, CaseSensitivityList: TSQLMemWideStringList): Boolean;
   function FindIndex(FieldNames, AscDescList, CaseSensitivityList: TSQLMemWideStringList): TSQLMemObjectID;
   function FindPrimaryIndex: TSQLMemIndexDef;
   function AddCreated: TSQLMemIndexDef;
   function GetIndexDefByName(Name: WideString): TSQLMemIndexDef;
   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
  public
   property Items[Index: Integer]: TSQLMemIndexDef read GetIndexDef write SetIndexDef; default;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFieldDefs
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemFieldDefs = class(TSQLMemMetaObjectDefs)
  private
   FVarcharOrBLOBFieldsExists: Boolean;
   FAutoIncFieldsExists:       Boolean;
   FDefaultValuesExists:       Boolean;
   FEngineVersion:             Double;

   function GetDef(Index: Integer): TSQLMemFieldDef;
   procedure SetDef(Index: Integer; Value: TSQLMemFieldDef);
   function InternalAddCreated: TSQLMemMetaObjectDef; override;
  public
   function AddCreated: TSQLMemFieldDef;
   function GetFieldDefByName(Name: WideString): TSQLMemFieldDef;

   procedure RecalcFieldOffsets;
   function GetMemoryRecordBufferSize: Integer;

   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
   // Set default values to fields
   procedure ApplyDefaultValuesToRecordBuffer(
                                RecordBuffer: TSQLMemRecordBuffer
                                );
  public
   property Items[Index: Integer]: TSQLMemFieldDef read GetDef write SetDef; default;
   property VarcharOrBLOBFieldsExists: Boolean read FVarcharOrBLOBFieldsExists;
   property AutoIncFieldsExists: Boolean read FAutoIncFieldsExists;
   property DefaultValuesExists: Boolean read FDefaultValuesExists;
   property EngineVersion: Double read FEngineVersion write FEngineVersion;
 end;//TSQLMemFieldDefs


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefs
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemConstraintDefs = class(TSQLMemMetaObjectDefs)
  private
   FForeignKeysExists: Boolean;
   FForeignKeysActionsExists: Boolean;
  private
   function GetDef(Index: Integer): TSQLMemConstraintDef;
   procedure SetDef(Index: Integer; Value: TSQLMemConstraintDef);
   function GetForeignKeysActionsUpdateExists: Boolean;
   function GetForeignKeysActionsDeleteExists: Boolean;
  public
   constructor Create;
   procedure Assign(Source: TSQLMemMetaObjectDefs); override;
   procedure Delete(Index: Integer); override;
   // Create TSQLMemConstraintDefNotNull and add it into list
   function AddNotNull: TSQLMemConstraintDefNotNull;
   // Create TSQLMemConstraintDefCheck and add it into list
   function AddCheck: TSQLMemConstraintDefCheck;
   function AddPK: TSQLMemConstraintDefPrimary;
   function AddUnique: TSQLMemConstraintDefUnique;
   function AddFK: TSQLMemConstraintDefForeignKey;
   function AddFKAction: TSQLMemConstraintDefForeignKeyAction;

   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
   procedure ExtractForeignKeys(Dest: TSQLMemConstraintDefs);
  public
   property Items[Index: Integer]: TSQLMemConstraintDef read GetDef write SetDef; default;
   property ForeignKeysExists: Boolean read FForeignKeysExists write FForeignKeysExists;
   property ForeignKeysActionsExists: Boolean read FForeignKeysActionsExists  write FForeignKeysActionsExists;
   property ForeignKeysActionsUpdateExists: Boolean read GetForeignKeysActionsUpdateExists;
   property ForeignKeysActionsDeleteExists: Boolean read GetForeignKeysActionsDeleteExists;
 end;//TSQLMemConstraintDefs



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSequenceDefs
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemSequenceDefs = class(TSQLMemMetaObjectDefs)
  private
   function GetDef(Index: Integer): TSQLMemSequenceDef;
   procedure SetDef(Index: Integer; Value: TSQLMemSequenceDef);
   function InternalAddCreated: TSQLMemMetaObjectDef; override;
  public
   function AddCreated: TSQLMemSequenceDef;
   function GetSequenceDefByName(Name: WideString): TSQLMemSequenceDef;
  public
   property Items[Index: Integer]: TSQLMemSequenceDef read GetDef write SetDef; default;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemViewDefs
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemViewDefs = class(TSQLMemMetaObjectDefs)
  private
   function InternalAddCreated: TSQLMemMetaObjectDef; override;
  public
   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
   // return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
   function FindChildren(Name: WideString): Boolean;
   // delete all views that references view or table with specified name - for DROP [TABLE | VIEW] with CASCADE
   procedure DeleteChildren(Name: WideString);
 end; // TSQLMemViewDefs


 TSQLMemRestructureInfo = record
    FRestructureBLOBCompression:   TSQLMemCompression;
    FRestructureFieldDefs:         TSQLMemFieldDefs;
    FRestructureIndexDefs:         TSQLMemIndexDefs;
    FRestructureConstraintDefs:    TSQLMemConstraintDefs;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCursor
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemCursor = class (TObject)
   public
    FMemoryTableAllocBy:            Integer;
    FSettingProjection:             Boolean;
    FIsProjectionSet:               Boolean;
    FComment:                       WideString;
    FTableName:                     WideString;
    FIndexName:                     WideString;
    FIndexID:                       TSQLMemObjectID;
    FReadOnly:                      Boolean;
    FExclusive:                     Boolean;
    FInMemory:                      Boolean;
    FTemporary:                     Boolean;
    FSession:                       TSQLMemBaseSession;
    FIsOpen:                        Boolean;
    FPhysicalOrder:                 Boolean;
    FCurrentRecordPositionInIndex:  TSQLMemIndexPosition;
    // temp record buffer - used by TSQLMemTableData.ShowRecord -
    // show record after insert / update filtered cursor
    FTempRecordBuffer:              TSQLMemRecordBuffer;
    // current record buffer
    FCurrentRecordBuffer:           TSQLMemRecordBuffer;
    // buffer with original record, stored on InternalEdit by TSQLMemDataset
    FEditRecordBuffer:              TSQLMemRecordBuffer;
    FConstraintDefs:                TSQLMemConstraintDefs;
    FBLOBCompression:               TSQLMemCompression;
    FFieldDefs:                     TSQLMemFieldDefs;
    FVisibleFieldDefs:              TSQLMemFieldDefs; // visible fields (projection)
    FIndexDefs:                     TSQLMemIndexDefs;
    FBLOBStreams:                   TList;
    FRecordBitmap:                  Pointer;
    FIsClientCursor:                Boolean;
    FCreateTableStarted:            Boolean;
    FRandomOrder:                   Boolean;
    FSkipTableExistsCheck:          Boolean;
    FDirectSetAutoInc:              Boolean;
    FCaseInsensitive:               Boolean; // added in v.5.90
    FIsView:                        Boolean; // added in v.6.00
    FIsViewWithCheckOption:         Boolean; // added in v.6.00
    FViewName:                      WideString;
    FViewColumns:                   WideString;
    FViewSelect:                    WideString;
   protected
    // BLOBS will be stored as 6 bytes reference:
    // DiskEngine: 4 bytes PAGEID, 2 bytes ObjectID
    // TemporaryEngine: 4 bytes pointer to BLOBDescriptor record, 2 bytes not used
    // MemoryEngine: 4 bytes pointer to BLOBCompressedStream, 2 bytes not used

    // Record Buffer sizes and offsets:
    //              + FieldValuesOffset
    //                                   + BookmarkOffset
    //                                              + CalculatedFieldsOffset
    // +------------+--------------------+----------+-----------------+
    // | Null Flags | Field Values,      | Bookmark | Calculated and  |
    // |            | References To BLOB | Bookmark | Lookup Fields   |
    // +------------+--------------------+----------+-----------------+
    //                                              + RecordSize
    //                                                                + RecordBufferSize

    // Key buffer:
    //                                                   + KeyBufferSize
    //                                   + KeyOffset
    // +------------+--------------------+---------------+
    // | Null Flags | Field Values,      | TSQLMemKeyBuffer |
    // |            | References To BLOB |               |
    // +------------+--------------------+---------------+

    FErrorCode:                     TSQLMemErrorCode;
    FErrorMessage:                  WideString;
    FIsDesignMode:                  Boolean;
    FRecordBufferSize:              Integer;
    FRecordSize:                    Integer;
    FKeyBufferSize:                 Integer;
    FKeyOffset:                     Integer;
    FKeyFieldCount:                 Integer;
    FFieldValuesOffset:             Integer;
    FCalculatedFieldsOffset:        Integer;
    FBookmarkOffset:                Integer;
    FFilterExpression:              Pointer;
    FSQLFilterExpression:           Pointer;
    FKeyBuffer:                     TSQLMemRecordBuffer;
    FRangeStartBuffer:              TSQLMemRecordBuffer;
    FRangeEndBuffer:                TSQLMemRecordBuffer;
    FRangeStartExclusive:           Boolean;
    FRangeEndExclusive:             Boolean;
    FRangeStartKeyFieldCount:       Integer;
    FRangeEndKeyFieldCount:         Integer;
    FRepair:                        Boolean;
//    FDeleteCurrentRecordID:         TSQLMemRecordID;
   protected
    procedure SetIndexName(Value: WideString);
    // added in v.5.90
    procedure SetCaseInsensitive(Value: Boolean); virtual;
{$IFDEF DEBUG_LOG}
   public
    procedure WriteRecordBufferToLog(Buffer: TSQLMemRecordBuffer);
{$ENDIF}
   public
    property RecordBufferSize: Integer read FRecordBufferSize write FRecordBufferSize;
    property RecordSize: Integer read FRecordSize write FRecordSize;
    property FieldValuesOffset: Integer read FFieldValuesOffset write FFieldValuesOffset;
    property CalculatedFieldsOffset: Integer read FCalculatedFieldsOffset write FCalculatedFieldsOffset;
    property BookmarkOffset: Integer read FBookmarkOffset write FBookmarkOffset;
    property KeyOffset: Integer read FKeyOffset write FKeyOffset;
    property KeyBufferSize: Integer read FKeyBufferSize write FKeyBufferSize;
    property Repair: Boolean read FRepair write FRepair;
   public
    // set CurrentRecordID
//    procedure SetCurrentRecordIDAfterDelete;
    // table operations
    procedure CreateTable(
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                         ); virtual; abstract;
    procedure DeleteTable(Cascade: Boolean = False); virtual; abstract;
    procedure EmptyTable; virtual; abstract;
    procedure RenameTable(NewTableName: WideString); virtual; abstract;
    procedure RenameField(FieldName, NewFieldName: WideString); virtual;
    function RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TSQLMemConstraintDefs = nil
                      ): Boolean; virtual; abstract;
    procedure AddForeignKey(ConstraintDef: TSQLMemConstraintDefForeignKey); virtual; abstract;
    procedure DeleteConstraint(Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean); virtual; abstract;
    procedure LoadTableFromStream(
                        Stream:               TStream
                       ); virtual; abstract;
    procedure SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TSQLMemCompressionAlgorithm = acaNone;
                        CompressionMode:        Byte = 0;
                        BlockSize:              Integer = 0;
                        SkipCheckIsTableOpened: Boolean = false;
                        DoNotCloseTable:        Boolean = false

                      ); virtual; abstract;
    function ExportTableToSQL(
                              ExportStructure:      Boolean = True;
                              AddDropTableCommand:  Boolean = True;
                              ExportIndexes:        Boolean = True;
                              AddDropIndexCommand:  Boolean = True;
                              ExportData:           Boolean = True;
                              ExportBLOBFields:     Boolean = True;
                              UseBracketsForNames:  Boolean = True;
                              ExportForeignKeys:    Boolean = True
                            ): WideString; virtual; abstract;
    procedure InternalInitFieldDefs; virtual; abstract;
    procedure OpenTableByFieldDefs(
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                       ); virtual; abstract;
    procedure UpdateTableDefinitions; virtual;
    procedure CloseTable; virtual; abstract;
    // initialize record buffer
    procedure InternalInitRecord(RecordBuffer: TSQLMemRecordBuffer; InsertMode: Boolean); virtual;

    // index operations
    function GetIndexDefs: TSQLMemIndexDefs; virtual;
    procedure ReceiveFieldNoReferences(Stream: TStream);

    procedure AddIndex(IndexDef: TSQLMemIndexDef); virtual; abstract;
    procedure DeleteIndex(Name: WideString); virtual; abstract;
    procedure DeleteAllIndexes; virtual; abstract;
    // return index name of the index or '' if not found
    function FindIndex(FieldNamesList,
                AscDescList, CaseSensitivityList: TSQLMemWideStringList): WideString; virtual; abstract;

    // check field value and if not null move data from RecordBuffer to Buffer
    function GetFieldData(
                          FieldNo:      Integer; // field no
                          Buffer:       Pointer; // buffer
                          RecordBuffer: TSQLMemRecordBuffer // record buffer
                         ): Boolean;
    // set field data from Buffer to RecordBuffer
    procedure SetFieldData(
                            FieldNo:       Integer;
                            Buffer:        Pointer;
                            RecordBuffer:  TSQLMemRecordBuffer // record buffer
                          );
    procedure GetBLOBValue(V: TSQLMemVariant; aFieldNo: Integer);
    procedure GetFieldValue(Value: TSQLMemVariant; FieldNo: Integer; DirectAccess: Boolean; CopyFlag: Boolean = True);
    procedure SetFieldValue(
                            Value:        TSQLMemVariant;
                            FieldNo:      Integer;
                            DirectAccess: Boolean;
                            RecordBuffer: TSQLMemRecordBuffer = nil
                           );
    // allocate record buffer and set null flags
    function AllocateRecordBuffer: TSQLMemRecordBuffer;
    // free record buffer
    procedure FreeRecordBuffer(var Buffer: TSQLMemRecordBuffer);
    // allocate record buffer and set null flags
    function AllocateKeyRecordBuffer: TSQLMemRecordBuffer;
    // initialize record buffer
    procedure InternalInitKeyBuffer(RecordBuffer: TSQLMemRecordBuffer);
    function IsTemporaryTable: Boolean; virtual; abstract;
    function IsMemoryTable: Boolean; virtual; abstract;


    //---------------------------------------------------------------------------
    // navigation & bookmark methods
    //---------------------------------------------------------------------------

    // return true if current record exists
    function IsRecordExists: Boolean; virtual; abstract;
    function GetRecordCount: TSQLMemRecordNo; virtual; abstract;
    // get record
    function GetRecordBuffer(
              GetRecordMode:  TSQLMemGetRecordMode
              ): TSQLMemGetRecordResult; virtual; abstract;
    // go to record
    procedure SetRecNo(Value: Int64); virtual; abstract;
    // return current record number
    function GetRecNo: Int64; virtual; abstract;
    // go to first record
    procedure InternalFirst;
    // go to last record
    procedure InternalLast;
    function SavePosition: Pointer;
    procedure RestorePosition(Pos: Pointer);
    procedure FreePosition(var Pos: Pointer);

    //---------------------------------------------------------------------------
    // insert, edit, post, delete methods
    //---------------------------------------------------------------------------
    // added in v.5.30 - moved from TSQLMemMain.GetRecord
    procedure GetCalcFieldsAndBookMarkData(bInsert: Boolean = False);
    // refresh - added in v.5.30
    procedure InternalRefresh; virtual;
    // insert record
    procedure InternalInsert; virtual;
    // edit record
    procedure InternalEdit; virtual; abstract;
    // cancels updates
    procedure InternalCancel(ToInsert: Boolean); virtual; abstract;
    // update record
    procedure InternalPost(ToInsert: Boolean); virtual; abstract;
    // delete record
    procedure InternalDelete; virtual; abstract;
    procedure DeleteVisibleRecords; virtual; abstract;
    procedure UpdateVisibleRecords(FieldNames:   TSQLMemWideStringList;
                                   values:       array of TSQLMemVariant;
                                   SkipFKCheck:  Boolean = False
                                   ); virtual; abstract;
    // return disk record size
    function GetDiskRecordSize: Integer;

    //---------------------------------------------------------------------------
    // search & filter methods
    //---------------------------------------------------------------------------

    // disable record bitmap
    procedure DisableRecordBitmap; virtual; abstract;
    // apply projection
    procedure ApplyProjection(FieldNamesList, AliasList: TSQLMemWideStringList); virtual; abstract;
    procedure ActivateFilters(
                              FilterText:      WideString;
                              CaseInsensitive: Boolean;
                              PartialKey:      Boolean
                            ); virtual; abstract;
    procedure DeactivateFilters; virtual; abstract;
    function Locate(
                    const KeyFields: WideString;
                    const KeyValues: Variant;
                    CaseInsensitive: Boolean;
                    PartialKey:      Boolean
              ): Boolean; virtual; abstract;
    function FindKey(SearchCondition: TSQLMemSearchCondition): Boolean; virtual; abstract;
    function IsIndexApplied: Boolean;
    function IsFilterApplied: Boolean;
    function IsRangeApplied: Boolean;
    function IsViewRestricted: Boolean;
    // update index definitions in dataset
    procedure UpdateIndexDefinitions;

    procedure ResetRange; virtual; abstract;
    procedure ApplyRange(
                          StartBuffer, EndBuffer: TSQLMemRecordBuffer;
                          StartKeyFieldCount:     Integer;
                          EndKeyFieldCount:       Integer;
                          StartExclusive:         Boolean;
                          EndExclusive:           Boolean
                        ); virtual; abstract;
    // set SQL Filter
    procedure SetSQLFilter(FilterExpr: TObject); virtual; abstract;

    //---------------------------------------------------------------------------
    // BLOB methods
    //---------------------------------------------------------------------------

    function InternalCreateBlobStream(
              ToInsert: Boolean;
              FieldNo:  Integer;
              OpenMode: TSQLMemBLOBOpenMode
              ):TSQLMemStream; virtual; abstract;

    procedure InternalCloseBLOB(FieldNo: Integer); virtual; abstract;

    // clear blob streams
    procedure ClearBLOBStreams(WriteOnly: Boolean = False); virtual; abstract;

    function LastAutoincValue(FieldNo: Integer): Int64; virtual; abstract;
    procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer); virtual; abstract;
   public
    function GetTableState: TSQLMemTableState; virtual; abstract;
    procedure LockTable(bWriteMode: Boolean); virtual; abstract;
    procedure UnlockTable(bWriteMode: Boolean); virtual; abstract;
   public
    // Destroy should call DatabaseData.FreeTableData
    // for bookmarks
    CurrentRecordID:               TSQLMemRecordID;
    // position for navigation
    FirstPosition:                 Boolean;
    LastPosition:                  Boolean;
    FilterRecord:                  TSQLMemFilterRecord;
    Dataset:                       Pointer;

    property RandomOrder: Boolean read FRandomOrder write FRandomOrder;
    property RecordBitmap: Pointer read FRecordBitmap write FRecordBitmap;
    property FilterExpression: Pointer read FFilterExpression write FFilterExpression;
    property SQLFilterExpression: Pointer read FSQLFilterExpression write FSQLFilterExpression;
    property BLOBStreams: TList read FBLOBStreams;
    property ErrorCode: TSQLMemErrorCode read FErrorCode write FErrorCode;
    property ErrorMessage: WideString read FErrorMessage write FErrorMessage;
    property IsDesignMode: Boolean read FIsDesignMode write FIsDesignMode;
    property TableName: WideString read FTableName write FTableName;
    property IndexName: WideString read FIndexName write SetIndexName;
    property IndexID: TSQLMemObjectID read FIndexID write FIndexID;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Exclusive: Boolean read FExclusive write FExclusive;
    property InMemory: Boolean read FInMemory write FInMemory;
    property MemoryTableAllocBy: Integer read FMemoryTableAllocBy write FMemoryTableAllocBy;
    property Temporary: Boolean read FTemporary write FTemporary;
    property Session: TSQLMemBaseSession read FSession write FSession;
    property IsOpen: Boolean read FIsOpen write FIsOpen;
    property RecordCount: Int64 read GetRecordCount;
    property FieldDefs: TSQLMemFieldDefs read FFieldDefs;
    property VisibleFieldDefs: TSQLMemFieldDefs read FVisibleFieldDefs;
    property IndexDefs: TSQLMemIndexDefs read GetIndexDefs;
    property ConstraintDefs: TSQLMemConstraintDefs read FConstraintDefs;
    // set it before call CreateTable
    property BLOBCompression: TSQLMemCompression read FBLOBCompression
             write FBLOBCompression;
    property KeyFieldCount: Integer read FKeyFieldCount write FKeyFieldCount;
    property KeyBuffer: TSQLMemRecordBuffer read FKeyBuffer write FKeyBuffer;
    property RangeStartBuffer: TSQLMemRecordBuffer read FRangeStartBuffer
             write FRangeStartBuffer;
    property RangeEndBuffer:   TSQLMemRecordBuffer read FRangeEndBuffer
             write FRangeEndBuffer;
    property RangeStartExclusive: Boolean read FRangeStartExclusive
             write FRangeStartExclusive;
    property RangeEndExclusive: Boolean read FRangeEndExclusive
             write FRangeEndExclusive;
    property RangeStartKeyFieldCount: Integer read FRangeStartKeyFieldCount
             write FRangeStartKeyFieldCount;
    property RangeEndKeyFieldCount: Integer read FRangeEndKeyFieldCount
             write FRangeEndKeyFieldCount;
    property CurrentRecordBuffer: TSQLMemRecordBuffer read FCurrentRecordBuffer
              write FCurrentRecordBuffer;
    property EditRecordBuffer: TSQLMemRecordBuffer read FEditRecordBuffer
              write FEditRecordBuffer;
    property PhysicalOrder: Boolean read FPhysicalOrder write FPhysicalOrder;
    property CurrentRecordPositionInIndex: TSQLMemIndexPosition
              read FCurrentRecordPositionInIndex
              write FCurrentRecordPositionInIndex;
    property IsClientCursor: Boolean read FIsClientCursor write FIsClientCursor;
    property CreateTableStarted: Boolean read FCreateTableStarted write FCreateTableStarted;
    property SkipTableExistsCheck: Boolean read FSkipTableExistsCheck write FSkipTableExistsCheck;
    property DirectSetAutoInc: Boolean read FDirectSetAutoInc write FDirectSetAutoInc;
    property Comment: WideString read FComment write FComment;
    property CaseInsensitive: Boolean read FCaseInsensitive write SetCaseInsensitive; // added in v.5.90
    property IsView: Boolean read FIsView write FIsView default False; // added in v.6.00
    property IsViewWithCheckOption: Boolean read FIsViewWithCheckOption write FIsViewWithCheckOption default False; // added in v.6.00
    property ViewName: WideString read FViewName write FViewName; // added in v.6.00
    property ViewColumns: WideString read FViewColumns write FViewColumns; // added in v.6.00
    property ViewSelect: WideString read FViewSelect write FViewSelect; // added in v.6.00
end; // TSQLMemCursor



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBaseSession
//
////////////////////////////////////////////////////////////////////////////////

  // manager for TSQLMemSession
  TSQLMemSessionComponentManager = class(TObject)
  end;

  // Session object base class
  TSQLMemSessionNamedObject = class(TObject)
   private
    FName: WideString;
   public
    constructor Create(Name: WideString);
   public
    property Name: WideString read FName write FName;
  end;

  // Sequence last value stored in user session
  TSQLMemSessionNamedObjectSequenceValue = class(TSQLMemSessionNamedObject)
   public
    FValue: TSQLMemSequenceValue;
   public
    constructor Create(ValueName: WideString; Value: TSQLMemSequenceValue);
   public
    property Value: TSQLMemSequenceValue read FValue write FValue;
  end;

  // for database component
  TSQLMemBaseSession = class (TObject)
   private
    FSessionHandle:           TSQLMemSessionComponentManager;
    FSessionNamedObjectList:  TSQLMemSortedStringPtrArray;
   protected
    FDatabaseName:            AnsiString; // name of database
    FSessionName:             AnsiString; // session name from TSQLMemDatabase
    // if not empty - ANSI, else - Unicode
    FDatabaseFileName:        AnsiString;
    FDatabaseFileNameUnicode: WideString;
    FSessionID:               TSQLMemSessionID;
    FReadOnly:                Boolean;
    FExclusive:               Boolean;
    FTemporary:               Boolean;
    FInMemory:                Boolean;
    FOptions:                 TSQLMemOptions;
    FLockParams:              TSQLMemLockParams;
    FCryptoParams:            TSQLMemCryptoParams;
    FSessionVariables:        TSQLMemSQLParams;
    FCaseInsensitive:         Boolean; // added in v.5.90

   protected
    // db connected?
    function GetConnected: Boolean;  virtual;  abstract;
    // connect / disconnect
    procedure SetConnected(Value: Boolean); virtual; abstract;
    // added in v.5.90
    procedure SetCaseInsensitive(Value: Boolean); virtual;
   public
{$IFNDEF SQLMEMTABLE}
    FConnectParams:           TSQLMemConnectParams;
{$ENDIF}

   public
    // constructor
    constructor Create;
    // destructor
    destructor Destroy; override;

    // create database
    procedure CreateDatabase; virtual;
    // flush file buffers
    procedure FlushFileBuffers; virtual; abstract;
    // return database format version
    function GetFormatVersion: Double; virtual; abstract;
    // return total number of pages
    function GetTotalPageCount : Integer; virtual; abstract;
    // return number of free pages
    function GetFreePageCount : Integer; virtual; abstract;
    // return true if database is encrypted
    function IsDatabaseEncrypted: Boolean; virtual; abstract;
    // return true if database is encrypted by password or by key
    function IsDatabaseEncryptedByPassword: Boolean; virtual; abstract;
    // return true if CryptoParams are valid
    function IsCryptoParamsValid: Boolean; virtual; abstract;
    // check if database exists
    function GetDatabaseExists: Boolean; virtual; abstract;
    procedure GetTablesList(List: TSQLMemWideStringList); virtual; abstract;
    function GetTablesInfo(SortByTableName: Boolean = True): TSQLMemTableInfoArray; virtual; abstract;
    function GetTableState(TableName: WideString): TSQLMemTableState; virtual; abstract;
    function TableExists(TableName: WideString): Boolean; virtual; abstract;
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
                            ): WideString; virtual; abstract;
    // load local memory database
    procedure LoadDatabaseFromStream(
                        Stream: TStream
                       ); virtual; abstract;
    // save local memory database
    procedure SaveDatabaseToStream(
                    Stream:               TStream;
                    CompressionAlgorithm: TSQLMemCompressionAlgorithm = acaNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = SQLMemDefaultSaveBlockSize
                  ); virtual; abstract;
    // makes Exe database from edb file
    procedure MakeExeDatabase(ExeFileName, ExeDatabaseFileName: WideString); virtual; abstract;
    // removes database file from executable database file
    procedure RemoveDatabaseFromExe; virtual; abstract;
    // returns true if this file is an SQLMemTable database
    function IsSQLMemTableDatabaseFile: Boolean; virtual; abstract;

    //------------- session variables and sequence values ----------------------
    // Get Named object from session
    function GetNamedObject(ObjectName: WideString): TSQLMemSessionNamedObject;
    // Set Named object to session
    procedure SetSequenceValue(const Name: TSQLMemObjectName; const Value: TSQLMemSequenceValue);

    //------------------------ Transactions ------------------------------------
   protected
    // retrun true if database has active transaction
    function GetInTransaction: Boolean; virtual; abstract;
   public
    // start a transaction
    procedure StartTransaction; virtual; abstract;
    // apply changes made by transaction
    procedure Commit(FlushFileBuffers: Boolean); virtual; abstract;
    // cancel changes made by transaction
    procedure Rollback; virtual; abstract;

    //------------------------ ClientServer ------------------------------------
    // for client and server sessions
    procedure ReceiveData(Buffer: PAnsiChar; BufferSize: Integer); virtual;
    procedure OnDisconnect; virtual;
    procedure RemoveAllLocks; virtual;
    // clear disk cache in single-user / multi-user
    procedure ClearCache; virtual;
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString; virtual;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString); virtual;
    procedure DoOnError(ErrorCode: Integer; NativeError: Integer = -1; ErrorMessage: AnsiString = ''); virtual;
    // set database parameters - used in stored functions
    procedure SetDatabaseParams(var DBParams: TSQLMemSQLDatabaseParams);

    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------
    // create stored function / procedure
    procedure CreateStoredFunction(SQLScript: WideString); overload; virtual; abstract;
    // for CREATE FUNCTON inside SQL script
    // current token is rwFUNCTION/rwPROCEDURE
    procedure CreateStoredFunction(
                  StoredFunction:   TObject;
                  SQLScript:        WideString
                                  ); overload; virtual; abstract;
    procedure ParseStoredFunction(
                  Lexer:                TSQLMemLexer;
                  var Token:            TToken;
                  out StoredFunction:   TObject;
                  out SQLScript:        WideString
                                 ); virtual; abstract;
    // drop stored function / procedure
    procedure DropStoredFunction(FunctionName: WideString); virtual; abstract;
    // ALTER stored function - modify script
    procedure AlterStoredFunction(
                                    FunctionName,
                                    NewSQLScript:     WideString
                                 ); virtual; abstract;
    // ALTER stored function - rename
    procedure AlterStoredFunctionRename(
                                    FunctionName,
                                    NewFunctionName:  WideString
                                                        ); virtual; abstract;
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    // params - list of TSQLMemSQLParam
    function ExecuteStoredFunction(
                FunctionName:     WideString;
                ResultValue:      TSQLMemVariant;
                Params:           TSQLMemSQLParams = nil 
                ): Boolean; virtual; abstract;
    // return empty string if function not found; otherwise
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; virtual; abstract;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TSQLMemExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString): TObject; virtual; abstract;
    // parse for execute
    // return stored function object (TSQLMemStoredFunction) if found or nil
    // params - list of TSQLMemExpression
    function ParseStoredFunctionParams(
                    lexer:          TSQLMemLexer;
                    parentFunction: TObject; // parent TSQLMemStoredFunction object, where parser was called 
                    var token:      TToken;
                    out Params:     TObject // TSQLMemExpressions
                                      ): TObject; virtual; abstract;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload; virtual; abstract;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload;  virtual; abstract;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); virtual; abstract;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------

    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         ViewName:          WideString;
                         SelectStatement:   WideString;
                         Columns:           TSQLMemWideStringList = nil;
                         bWithCheckOption:  Boolean = False;
                         Comment:           WideString = ''
                        ); virtual; abstract;
    // drop view
    procedure DropView(
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      ); virtual; abstract;
    // return nil if not found, otherwise return view definition
    function FindView(
                         ViewName:          WideString
                     ): TSQLMemViewDef; virtual; abstract;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    procedure CloseLocalSessionWithoutDatabase; virtual; abstract;
    // return cursor created for the specified table or view name
    function CreateCursor(TableName: WideString; bOpenView: Boolean = True): TSQLMemCursor; virtual; abstract;
   public
    property Connected: Boolean read GetConnected write SetConnected default False;
    // if not empty - ANSI, else - Unicode
    property DatabaseFileName: AnsiString read FDatabaseFileName write FDatabaseFileName;
    property DatabaseFileNameUnicode: WideString read FDatabaseFileNameUnicode write FDatabaseFileNameUnicode;
    property DatabaseName: AnsiString read FDatabaseName write FDatabaseName;
    property SessionName: AnsiString read FSessionName write FSessionName;
    property SessionID: TSQLMemSessionID read FSessionID write FSessionID;
    property InTransaction: Boolean read GetInTransaction;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Exclusive: Boolean read FExclusive write FExclusive;
    property InMemory: Boolean read FInMemory write FInMemory;
    property Temporary: Boolean read FTemporary write FTemporary;
    property SessionComponentManager: TSQLMemSessionComponentManager
             read FSessionHandle write FSessionHandle;
    property LockParams: TSQLMemLockParams read FLockParams write FLockParams;
    property Options: TSQLMemOptions read FOptions write FOptions;
    property CryptoParams: TSQLMemCryptoParams read FCryptoParams write FCryptoParams;
{$IFNDEF SQLMEMTABLE}
    property ConnectParams: TSQLMemConnectParams read FConnectParams write FConnectParams;
{$ENDIF}
    property SessionVariables: TSQLMemSQLParams read FSessionVariables;
    property CaseInsensitive: Boolean read FCaseInsensitive write SetCaseInsensitive; // added in v.5.90
  end; // TSQLMemBaseSession


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemSQLProcessor = class (TObject)
   protected
    FSQLMemQuery:        TDataSet;
    FReadOnly:        Boolean;
    FRequestLive:     Boolean;
    FInMemory:        Boolean;
    FRowsAffected:    TSQLMemRecordNo;

    FSqlText:         WideString;
    FSQLParams:       TSQLMemSQLParams;
    FCursor:          TSQLMemCursor;
    FNeverOpened:     Boolean;
    FParamsHash:      TSQLMemRecordHashValue;
    FParamsChanged:   Boolean;
    FCaseInsensitive: Boolean; // added in v.5.90
   public
    constructor Create; overload;
    constructor Create(Query: TDataSet); overload;
    destructor Destroy; override;

    function OpenQuery(TableNames: TSQLMemWideStringList = nil): TSQLMemCursor; virtual;
    procedure ExecuteQuery;

    procedure PrepareStatement(SQLText: PWideChar);
    procedure UpdateParams; virtual;

   public
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property RequestLive: Boolean read FRequestLive write FRequestLive;
    property InMemory: Boolean read FInMemory write FInMemory;
    property RowsAffected: TSQLMemRecordNo read FRowsAffected;
    property SQLParams: TSQLMemSQLParams read FSQLParams;
    property SQLMemQuery: TDataset read FSQLMemQuery;
    property SQLText: WideString read FSQLText;
    property CaseInsensitive: Boolean read FCaseInsensitive write FCaseInsensitive; // added in v.5.90
  end; // TSQLMemSQLProcessor


function SQLMemCopyCursors(
            SourceCursor:       TSQLMemCursor;
            DestinationCursor:  TSQLMemCursor
            ): WideString;

implementation

uses

// SQLMemTable units
     SQLMemMain,
     SQLMemExpressions,
     SQLMemBaseEngine,
     SQLMemMemory // last
;



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMetaObjectDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set name
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDef.SetName(NewName: TSQLMemObjectName);
begin
  FName := NewName;
  FNameCRC := GetTableNameCRC(FName,True);
end; // SetName


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemMetaObjectDef.Create;
begin
  FName       := '';
  FObjectID   := OBJECTID_IS_NULL;
end;//Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDef.Assign(Source: TSQLMemMetaObjectDef);
begin
  SetName(Source.Name);
  FObjectID := Source.FObjectID;
end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDef.LoadFromStream(Stream: TStream);
begin
  LoadWideStringFromStream(FName,Stream,10166);
  FNameCRC := GetTableNameCRC(FName,True);
  LoadDataFromStream(FObjectID,sizeof(ObjectID),Stream,10169);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDef.SaveToStream(Stream: TStream);
begin
  SaveWideStringToStream(FName,Stream,10164);
  SaveDataToStream(FObjectID,sizeof(ObjectID),Stream,10168);
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSequenceDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSequenceDef.Create;
begin
  inherited Create;
  FDataType  := bftUnSignedInt32;
  FMinValue  := 0;
  FMaxValue  := High(Cardinal);
  FLastValue := 0;
  FIncrement := 1;
  FCycled    := true;
end;//Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemSequenceDef.Assign(Source: TSQLMemMetaObjectDef);
begin
  inherited Assign(Source);
  FDataType  := TSQLMemSequenceDef(Source).FDataType;
  FMinValue  := TSQLMemSequenceDef(Source).FMinValue;
  FMaxValue  := TSQLMemSequenceDef(Source).FMaxValue;
  FLastValue := TSQLMemSequenceDef(Source).FLastValue;
  FIncrement := TSQLMemSequenceDef(Source).FIncrement;
  FCycled    := TSQLMemSequenceDef(Source).FCycled;
end;//Assign


//------------------------------------------------------------------------------
// GetNextVal
//------------------------------------------------------------------------------
function TSQLMemSequenceDef.GetNextVal: TSQLMemSequenceValue;
begin
  FLastValue := FLastValue + FIncrement;
  if (FLastValue > FMaxValue) then
    if (FCycled) then
      FLastValue := FMinValue
    else
      raise ESQLMemException.Create(30009, ErrorGSequenceOverflow, [FName]);
  Result := FLastValue;
end;//GetNextVal


//------------------------------------------------------------------------------
// load sequence
//------------------------------------------------------------------------------
procedure TSQLMemSequenceDef.LoadFromStream(Stream: TStream);
begin
  inherited LoadFromStream(Stream);
  LoadDataFromStream(FDataType,sizeof(FDataType),Stream,10212);
  LoadDataFromStream(FMinValue,sizeof(FMinValue),Stream,10213);
  LoadDataFromStream(FMaxValue,sizeof(FMaxValue),Stream,10214);
  LoadDataFromStream(FLastValue,sizeof(FLastValue),Stream,10215);
  LoadDataFromStream(FIncrement,sizeof(FIncrement),Stream,10216);
  LoadDataFromStream(FCycled,sizeof(FCycled),Stream,10217);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save sequence
//------------------------------------------------------------------------------
procedure TSQLMemSequenceDef.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);
  SaveDataToStream(FDataType,sizeof(FDataType),Stream,10206);
  SaveDataToStream(FMinValue,sizeof(FMinValue),Stream,10207);
  SaveDataToStream(FMaxValue,sizeof(FMaxValue),Stream,10208);
  SaveDataToStream(FLastValue,sizeof(FLastValue),Stream,10209);
  SaveDataToStream(FIncrement,sizeof(FIncrement),Stream,10210);
  SaveDataToStream(FCycled,sizeof(FCycled),Stream,10211);
end; // LoadFromStream



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFieldDef
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemFieldDef.Create;
begin
  inherited Create;
  FBaseFieldType := bftUnknown;
  FAdvancedFieldType := aftUnknown;
  FFieldSize := 0;
  FDiskDataSize := 0;
  FMemoryDataSize := 0;
  FDiskOffset := 0;
  FMemoryOffset := 0;
  FFieldNoReference := 0;

  // Default Value
  //FDefaultValueType := dvtNull;
  FSequenceDefObjectId := OBJECTID_IS_NULL;
  FDefaultValue := TSQLMemVariant.Create;

  // Blob data
  FBLOBCompressionAlgorithm := acaNone;
  FBLOBCompressionMode := 0;
  FBLOBBlockSize := DefaultBLOBBlockSize;

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
destructor TSQLMemFieldDef.Destroy;
begin
  FDefaultValue.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// SetFieldDefData ( set Advanced Field Type )
//------------------------------------------------------------------------------
procedure TSQLMemFieldDef.SetFieldDefDataType(AdvancedFieldType: TSQLMemAdvancedFieldType;
                                           FieldSize: Integer);
begin
  FAdvancedFieldType := AdvancedFieldType;
  FBaseFieldType := AdvancedFieldTypeToBaseFieldType(AdvancedFieldType);
  if FBaseFieldType = bftUnknown then
   raise ESQLMemException.Create(30007,ErrorGUnsupportedDataType,
                                    [AftToStr(AdvancedFieldType)]);
  FFieldSize := FieldSize;
  RecalcInternalSizes;
end;//SetFieldDefData


//------------------------------------------------------------------------------
// SetFieldDefData ( set Advanced Field Type )
//------------------------------------------------------------------------------
procedure TSQLMemFieldDef.SetFieldDefDataType(BaseFieldType: TSQLMemBaseFieldType;
                                           FieldSize: Integer);
begin
  FBaseFieldType := BaseFieldType;
  FFieldSize := FieldSize;

  FAdvancedFieldType := BaseFieldTypeToAdvancedFieldType(BaseFieldType);
  if FAdvancedFieldType = aftUnknown then
   raise ESQLMemException.Create(30008,ErrorGUnsupportedDataType,
                                    [BftToStr(BaseFieldType)]);
  RecalcInternalSizes;
end;//SetFieldDefData



//------------------------------------------------------------------------------
// RecalcInternalSizes
//------------------------------------------------------------------------------
procedure TSQLMemFieldDef.RecalcInternalSizes;
begin
  // FMemoryDataSize ...
  FMemoryDataSize := GetDataSizeInMemory(FBaseFieldType, FFieldSize);

  // FDiskDataSize ...
  FDiskDataSize := FMemoryDataSize;
  if (IsBLOBFieldType(FBaseFieldType) or (IsVarcharFieldType(FBaseFieldType))) then
    FDiskDataSize := SizeOf(TSQLMemRecordID);
end;//RecalcInternalSizes



//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemFieldDef.Assign(Source: TSQLMemMetaObjectDef);
var s: TSQLMemFieldDef;
begin
  s := Source as TSQLMemFieldDef;
  inherited Assign(Source);
  FBaseFieldType := s.FBaseFieldType;
  FAdvancedFieldType := s.FAdvancedFieldType;
  FFieldSize := s.FFieldSize;
  FDiskDataSize := s.FDiskDataSize;
  FMemoryDataSize := s.FMemoryDataSize;
  FDiskOffset := s.FDiskOffset;
  FMemoryOffset := s.FMemoryOffset;

  // Default Value
  //FDefaultValueType := s.FDefaultValueType;
  FSequenceDefObjectId := s.FSequenceDefObjectId;
  FDefaultValue.Assign(s.FDefaultValue);

  // Blob data
  FBLOBCompressionAlgorithm := s.FBLOBCompressionAlgorithm;
  FBLOBCompressionMode      := s.FBLOBCompressionMode;
  FBLOBBlockSize            := s.FBLOBBlockSize;

  // Autoinc settings
  FAutoincIncrement := s.FAutoincIncrement;
  FAutoincInitialValue := s.FAutoincInitialValue;
  FAutoincMinValue  := s.FAutoincMinValue;
  FAutoincMaxValue  := s.FAutoincMaxValue;
  FAutoincCycled    := s.FAutoincCycled;

end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemFieldDef.LoadFromStream(Stream: TStream);
begin
  inherited LoadFromStream(Stream);

  LoadDataFromStream(FBaseFieldType,Sizeof(FBaseFieldType),Stream,10187);
  LoadDataFromStream(FAdvancedFieldType,Sizeof(FAdvancedFieldType),Stream,10188);
  LoadDataFromStream(FFieldSize,Sizeof(FFieldSize),Stream,10189);

  FDefaultValue.SetNull(FBaseFieldType);
  if (IsBlobFieldType(FBaseFieldType)
{$IFNDEF SQLMEMTABLE}
// v. 2.00 and 1.xx bug fix with not saving varchar compression in SQLMemTable
      or (IsVarcharFieldType(FBaseFieldType) and (FEngineVersion >= (2.10 - 0.001)))
{$ENDIF}      
      ) then
   begin
    // load blob params
    LoadDataFromStream(FBLOBCompressionAlgorithm,Sizeof(FBLOBCompressionAlgorithm),Stream,10192);
    LoadDataFromStream(FBLOBCompressionMode,Sizeof(FBLOBCompressionMode),Stream,10193);
    LoadDataFromStream(FBLOBBlockSize,Sizeof(FBLOBBlockSize),Stream,10194);
   end;

  //if (FDefaultValueType = dvtSequence) then
  if IsAutoincFieldType(FAdvancedFieldType) then
   begin
    // sequence
    LoadDataFromStream(FSequenceDefObjectId,Sizeof(FSequenceDefObjectId),Stream,10195);
    LoadDataFromStream(FAutoincIncrement,SizeOf(FAutoincIncrement),Stream,10690);
    LoadDataFromStream(FAutoincInitialValue,SizeOf(FAutoincInitialValue),Stream,10691);
    LoadDataFromStream(FAutoincMinValue,SizeOf(FAutoincMinValue),Stream,10692);
    LoadDataFromStream(FAutoincMaxValue,SizeOf(FAutoincMaxValue),Stream,10693);
    LoadDataFromStream(FAutoincCycled,SizeOf(FAutoincCycled),Stream,10694);
   end
  else
    // load default value
    FDefaultValue.LoadFromStream(Stream);

 RecalcInternalSizes;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemFieldDef.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);

  SaveDataToStream(FBaseFieldType,Sizeof(FBaseFieldType),Stream,10170);
  SaveDataToStream(FAdvancedFieldType,Sizeof(FAdvancedFieldType),Stream,10171);
  SaveDataToStream(FFieldSize,Sizeof(FFieldSize),Stream,10172);

  if (IsBlobFieldType(FBaseFieldType)
{$IFNDEF SQLMEMTABLE}
// v. 2.00 and 1.xx bug fix with not saving varchar compression in SQLMemTable
      or (IsVarcharFieldType(FBaseFieldType) and (FEngineVersion >= (2.10 - 0.001)))
{$ENDIF}
      ) then
   begin
    // save blob params
    SaveDataToStream(FBLOBCompressionAlgorithm,Sizeof(FBLOBCompressionAlgorithm),Stream,10175);
    SaveDataToStream(FBLOBCompressionMode,Sizeof(FBLOBCompressionMode),Stream,10176);
    SaveDataToStream(FBLOBBlockSize,Sizeof(FBLOBBlockSize),Stream,10177);
   end;

  //if (FDefaultValueType = dvtSequence) then
  if IsAutoincFieldType(FAdvancedFieldType) then
   begin
    // sequence
    SaveDataToStream(FSequenceDefObjectId,Sizeof(FSequenceDefObjectId),Stream,10178);
    SaveDataToStream(FAutoincIncrement,SizeOf(FAutoincIncrement),Stream,10685);
    SaveDataToStream(FAutoincInitialValue,SizeOf(FAutoincInitialValue),Stream,10686);
    SaveDataToStream(FAutoincMinValue,SizeOf(FAutoincMinValue),Stream,10687);
    SaveDataToStream(FAutoincMaxValue,SizeOf(FAutoincMaxValue),Stream,10688);
    SaveDataToStream(FAutoincCycled,SizeOf(FAutoincCycled),Stream,10689);
   end
  else
    // save default value
    FDefaultValue.SaveToStream(Stream);

end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexColumn
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set name
//------------------------------------------------------------------------------
procedure TSQLMemIndexColumn.SetName(NewName: TSQLMemObjectName);
begin
  FFieldName := NewName;
  FNameCRC := GetTableNameCRC(NewName,True);
end; // SetName


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemIndexColumn.LoadFromStream(Stream: TStream);
begin
  LoadWideStringFromStream(FFieldName,Stream,10358);
  FNameCRC := GetTableNameCRC(FFieldName,True);
  LoadDataFromStream(FDescending,Sizeof(FDescending),Stream,10360);
  LoadDataFromStream(FCaseInsensitive,Sizeof(FCaseInsensitive),Stream,10361);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemIndexColumn.SaveToStream(Stream: TStream);
begin
  SaveWideStringToStream(FFieldName,Stream,10354);
  SaveDataToStream(FDescending,Sizeof(FDescending),Stream,10356);
  SaveDataToStream(FCaseInsensitive,Sizeof(FCaseInsensitive),Stream,10357);
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get index column
//------------------------------------------------------------------------------
function TSQLMemIndexDef.GetIndexColumn(Index: Integer): TSQLMemIndexColumn;
begin
  Result := FIndexColumns[Index];
end;// GetIndexColumn


//------------------------------------------------------------------------------
// get column count
//------------------------------------------------------------------------------
function TSQLMemIndexDef.GetColumnCount: Integer;
begin
  Result := Length(FIndexColumns);
end;// GetColumnCount


//------------------------------------------------------------------------------
// set column count
//------------------------------------------------------------------------------
procedure TSQLMemIndexDef.SetColumnCount(Value: Integer);
var
  oldCount, i: Integer;
begin
  oldCount := Length(FIndexColumns);
  if (Value > oldCount) then
   begin
     SetLength(FIndexColumns, Value);
     for i := oldCount to Value-1 do
      FIndexColumns[i] := TSQLMemIndexColumn.Create;
   end
  else
  if (Value < oldCount) then
   begin
     for i := Value to oldCount-1 do
      FIndexColumns[i].Free;
     SetLength(FIndexColumns, Value);
   end;
end;// SetColumnCount




//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemIndexDef.Create;
begin
  FUnique := False;
  FPrimary := False;
  FIndexType := itBTree;
  FIndexColumns := nil;
  FRootPageNo := INVALID_PAGE_NO;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemIndexDef.Destroy;
begin
  ColumnCount := 0;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// assign another IndexDef
//------------------------------------------------------------------------------
procedure TSQLMemIndexDef.Assign(Source: TSQLMemMetaObjectDef);
var
  i: Integer;
begin
  inherited Assign(Source);
  IndexType := TSQLMemIndexDef(Source).IndexType;
  Unique := TSQLMemIndexDef(Source).Unique;
  Primary := TSQLMemIndexDef(Source).Primary;
  FRootPageNo := TSQLMemIndexDef(Source).RootPageNo;
  ColumnCount := TSQLMemIndexDef(Source).ColumnCount;
  FTemporary := TSQLMemIndexDef(Source).FTemporary;
  for i := 0 to ColumnCount-1 do
   begin
    Columns[i].FieldName := TSQLMemIndexDef(Source).Columns[i].FieldName;
    Columns[i].Descending := TSQLMemIndexDef(Source).Columns[i].Descending;
    Columns[i].CaseInsensitive := TSQLMemIndexDef(Source).Columns[i].CaseInsensitive;
   end;
end;// Assign


//------------------------------------------------------------------------------
// assign by names
//------------------------------------------------------------------------------
procedure TSQLMemIndexDef.AssignByNames(FieldNames, AscDescList, CaseSensitivityList: TStringList);
var i: integer;
begin
 if (FieldNames.Count <> AscDescList.Count) then
  raise ESQLMemException.Create(10278,ErrorLDifferentListsLength,
    [FieldNames.Count,AscDescList.Count]);
 if (FieldNames.Count <> CaseSensitivityList.Count) then
  raise ESQLMemException.Create(10279,ErrorLDifferentListsLength,
    [FieldNames.Count,CaseSensitivityList.Count]);
  ColumnCount := FieldNames.Count;
  for i := 0 to ColumnCount-1 do
   begin
    Columns[i].FieldName := FieldNames[i];
    Columns[i].Descending := (AscDescList[i] = SQLMem_DESC);
    Columns[i].CaseInsensitive := (CaseSensitivityList[i] = SQLMem_NO_CASE);
   end;
end;


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemIndexDef.LoadFromStream(Stream: TStream);
var i: Integer;
begin
  inherited LoadFromStream(Stream);

  LoadDataFromStream(FIndexType,Sizeof(FIndexType),Stream,10349);
  LoadDataFromStream(FUnique,Sizeof(FUnique),Stream,10350);
  LoadDataFromStream(FPrimary,Sizeof(FPrimary),Stream,10351);
  FTemporary := False;
  LoadDataFromStream(i,Sizeof(i),Stream,10352);
  ColumnCount := i;
  LoadDataFromStream(FRootPageNo,Sizeof(FRootPageNo),Stream,10353);
  for i := 0 to ColumnCount-1 do
    Columns[i].LoadFromStream(Stream);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemIndexDef.SaveToStream(Stream: TStream);
var i: Integer;
begin
  inherited SaveToStream(Stream);
  SaveDataToStream(FIndexType,Sizeof(FIndexType),Stream,10344);
  SaveDataToStream(FUnique,Sizeof(FUnique),Stream,10345);
  SaveDataToStream(FPrimary,Sizeof(FPrimary),Stream,10346);
  i := ColumnCount;
  SaveDataToStream(i,Sizeof(i),Stream,10347);
  SaveDataToStream(FRootPageNo,Sizeof(FRootPageNo),Stream,10348);
  for i := 0 to ColumnCount-1 do
    Columns[i].SaveToStream(Stream);
end; // SaveToStream


//------------------------------------------------------------------------------
// return -1 if field was not found, otherwise return column index
//------------------------------------------------------------------------------
function TSQLMemIndexDef.FindField(FieldName: WideString): Integer;
var crc: Cardinal;
    i:   Integer;
begin
  crc := GetTableNameCRC(FieldName);
  Result := -1;
  for i := 0 to ColumnCount-1 do
    if (Columns[i].NameCRC = crc) then
      begin
        Result := i;
        break;
      end;
end; // FindField




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDef.Assign(Source: TSQLMemMetaObjectDef);
begin
  inherited Assign(Source);
  FConstraintType := TSQLMemConstraintDef(Source).FConstraintType;
end;//Assign



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefNotNull
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefNotNull.Create;
begin
  FConstraintType := ctNotNull;
end;//Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefNotNull.Assign(Source: TSQLMemMetaObjectDef);
begin
  inherited Assign(Source);
  FColumnName := TSQLMemConstraintDefNotNull(Source).FColumnName;
  FColumnObjectID := TSQLMemConstraintDefNotNull(Source).FColumnObjectID;
end;//Assign

//------------------------------------------------------------------------------
// SetNames
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefNotNull.SetNames(ColumnName: WideString);
begin
  FColumnName := ColumnName;
end;//SetNames



//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefNotNull.LoadFromStream(Stream: TStream);
begin
  inherited LoadFromStream(Stream);
  LoadDataFromStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10251);
  LoadWideStringFromStream(FColumnName,Stream,10256);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefNotNull.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);
  SaveDataToStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10242);
  SaveWideStringToStream(FColumnName,Stream,10247);
end; // SaveToStream




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefCheck
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefCheck.Create;
begin
  FConstraintType := ctCheck;
  FMinValue := TSQLMemVariant.Create;
  FMaxValue := TSQLMemVariant.Create;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemConstraintDefCheck.Destroy;
begin
  FMinValue.Free;
  FMaxValue.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefCheck.Assign(Source: TSQLMemMetaObjectDef);
begin
  inherited Assign(Source);
  FColumnName := TSQLMemConstraintDefCheck(Source).FColumnName;
  FColumnObjectID := TSQLMemConstraintDefCheck(Source).FColumnObjectID;
  FMinValue.Assign(TSQLMemConstraintDefCheck(Source).FMinValue);
  FMaxValue.Assign(TSQLMemConstraintDefCheck(Source).FMaxValue);
end;//Assign


//------------------------------------------------------------------------------
// SetNames
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefCheck.SetNames(ColumnName: WideString);
begin
  FColumnName := ColumnName;
end;//SetNames


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefCheck.LoadFromStream(Stream: TStream);
begin
  inherited LoadFromStream(Stream);
  LoadDataFromStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10232);
  LoadWideStringFromStream(FColumnName,Stream,10237);

  FMinValue.LoadFromStream(Stream);
  FMaxValue.LoadFromStream(Stream);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefCheck.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);

  SaveDataToStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10229);
  SaveWideStringToStream(FColumnName,Stream,10225);

  FMinValue.SaveToStream(Stream);
  FMaxValue.SaveToStream(Stream);
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefUnique
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefUnique.Create;
begin
  inherited;
  FConstraintType := ctUnique;
  SetLength(Columns,0);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemConstraintDefUnique.Destroy;
begin
  SetLength(Columns,0);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefUnique.Assign(Source: TSQLMemMetaObjectDef);
var i,L: Integer;
begin
  inherited Assign(Source);
  L := Length(TSQLMemConstraintDefUnique(Source).Columns);
  SetLength(Columns, L);
  for i:=0 to L-1 do
    Columns[i] := TSQLMemConstraintDefUnique(Source).Columns[i];

  FIndexName := TSQLMemConstraintDefUnique(Source).FIndexName;
  FIndexObjectID := TSQLMemConstraintDefUnique(Source).FIndexObjectID;
end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefUnique.LoadFromStream(Stream: TStream);
var i,j: Integer;
begin
  inherited LoadFromStream(Stream);

  LoadDataFromStream(FIndexObjectID,  sizeof(FIndexObjectID),  Stream, 30317);
  LoadWideStringFromStream(FIndexName,Stream,30396);

  LoadDataFromStream(j,sizeof(j),Stream,30309);
  SetLength(Columns,j);
  for i:=0 to j-1 do
    begin
      LoadDataFromStream(Columns[i].ColumnObjectID,sizeof(Columns[i].ColumnObjectID),Stream,30310);
      LoadWideStringFromStream(Columns[i].ColumnName,Stream,30311);
    end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefUnique.SaveToStream(Stream: TStream);
var i,j: Integer;
begin
  inherited SaveToStream(Stream);

  SaveDataToStream(FIndexObjectID,  sizeof(FIndexObjectID),  Stream, 30318);
  SaveWideStringToStream(FIndexName,Stream,30400);

  j := Length(Columns);
// 4.30: 30319 already in BaseEngine, changed to 30394
  SaveDataToStream(j,sizeof(j),Stream,30394);
  for i:=0 to j-1 do
    begin
      SaveDataToStream(Columns[i].ColumnObjectID,sizeof(Columns[i].ColumnObjectID),Stream,30395);
      SaveWideStringToStream(Columns[i].ColumnName,Stream,30397);
    end;
end;//SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMetaObjectDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefPrimary.Create;
begin
  inherited;
  FConstraintType := ctPK;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefForeignKeyAction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefForeignKeyAction.Create;
begin
  inherited;
  FConstraintType := ctFKAction;
  FMatchType := cfkmtDefault;
  FDeleteAction := cfkaDefault;
  FUpdateAction := cfkaDefault;
  SetLength(Columns,0);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemConstraintDefForeignKeyAction.Destroy;
begin
  SetLength(Columns,0);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefForeignKeyAction.Assign(Source: TSQLMemMetaObjectDef);
var i,L: Integer;
begin
  inherited Assign(Source);
  L := Length(TSQLMemConstraintDefForeignKeyAction(Source).Columns);
  SetLength(Columns, L);
  for i:=0 to L-1 do
    Columns[i] := TSQLMemConstraintDefForeignKeyAction(Source).Columns[i];
  FReferencedTableName := TSQLMemConstraintDefForeignKeyAction(Source).FReferencedTableName;
  FReferencedTableObjectID := TSQLMemConstraintDefForeignKeyAction(Source).FReferencedTableObjectID;
  FReferencedFKName := TSQLMemConstraintDefForeignKeyAction(Source).FReferencedFKName;
  FReferencedFKObjectID := TSQLMemConstraintDefForeignKeyAction(Source).FReferencedFKObjectID;
  FDeleteAction := TSQLMemConstraintDefForeignKeyAction(Source).DeleteAction;
  FUpdateAction := TSQLMemConstraintDefForeignKeyAction(Source).UpdateAction;
  FMatchType := TSQLMemConstraintDefForeignKeyAction(Source).MatchType;
end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefForeignKeyAction.LoadFromStream(Stream: TStream);
var i,j: Integer;
begin
  inherited LoadFromStream(Stream);

  LoadWideStringFromStream(FReferencedTableName,Stream,11398);
  LoadDataFromStream(FReferencedTableObjectID,Sizeof(FReferencedTableObjectID),Stream,11400);

  LoadWideStringFromStream(FReferencedFKName,Stream,11439);
  LoadDataFromStream(FReferencedFKObjectID,Sizeof(FReferencedFKObjectID),Stream,11441);

  LoadDataFromStream(FDeleteAction,Sizeof(FDeleteAction),Stream,11402);
  LoadDataFromStream(FUpdateAction,Sizeof(FUpdateAction),Stream,11403);
  LoadDataFromStream(FMatchType,Sizeof(FMatchType),Stream,11401);

  LoadDataFromStream(j,sizeof(j),Stream,11404);
  SetLength(Columns,j);
  for i := 0 to j-1 do
    begin
      LoadDataFromStream(Columns[i].ColumnObjectID,sizeof(Columns[i].ColumnObjectID),Stream,11405);
      LoadWideStringFromStream(Columns[i].ColumnName,Stream,11406);
    end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefForeignKeyAction.SaveToStream(Stream: TStream);
var i,j: Integer;
begin
  inherited SaveToStream(Stream);

  SaveWideStringToStream(FReferencedTableName,Stream,11408);
  SaveDataToStream(FReferencedTableObjectID,SizeOf(FReferencedTableObjectID),Stream,11410);

  SaveWideStringToStream(FReferencedFKName,Stream,11436);
  SaveDataToStream(FReferencedFKObjectID,SizeOf(FReferencedFKObjectID),Stream,11438);

  SaveDataToStream(FDeleteAction,Sizeof(FDeleteAction),Stream,11412);
  SaveDataToStream(FUpdateAction,Sizeof(FUpdateAction),Stream,11413);
  SaveDataToStream(FMatchType,Sizeof(FMatchType),Stream,11411);

  j := Length(Columns);
  SaveDataToStream(j,sizeof(j),Stream,11414);
  for i:=0 to j-1 do
    begin
      SaveDataToStream(Columns[i].ColumnObjectID,SizeOf(Columns[i].ColumnObjectID),Stream,11415);
      SaveWideStringToStream(Columns[i].ColumnName,Stream,11416);
    end;
end;//SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefForeignKey
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefForeignKey.Create;
begin
  inherited;
  FConstraintType := ctFK;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemViewDef
//
////////////////////////////////////////////////////////////////////////////////

{
FSelectStatement:     WideString;
FWithCheckOption:     Boolean;
FChildViewsCRC:       TSQLMemIntegerArray; // CRC32 of UpperCase view names
FColumnNames:         TSQLMemObjectNameArray;
}

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemViewDef.Create;
begin
  FChildrenCRC := TSQLMemIntegerArray.Create;
  FChildrenNames := TSQLMemObjectNameArray.Create;
  FColumnNames := TSQLMemObjectNameArray.Create;
end; // Create


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemViewDef.Create(
                       aName:             WideString;
                       aSelectStatement:  WideString;
                       aChildrenNames:    TSQLMemWideStringList;
                       aColumnNames:      TSQLMemWideStringList;
                       aCheckOption:      Boolean;
                       aComment:          WideString
                              );
var i: Integer;
begin
  FChildrenCRC := TSQLMemIntegerArray.Create;
  FChildrenNames := TSQLMemObjectNameArray.Create;
  FColumnNames := TSQLMemObjectNameArray.Create;
  Name := aName;
  FSelectStatement := aSelectStatement;
  FComment := aComment;
  FChildrenCRC.SetSize(aChildrenNames.Count);
  FWithCheckOption := aCheckOption;
  FCreationDate := Now;
  for i := 0 to aChildrenNames.Count-1 do
  begin
   FChildrenNames.Add(aChildrenNames[i]);
   FChildrenCRC.Items[i] := Integer(GetTableNameCRC(aChildrenNames[i],True));
  end;
  if (aColumnNames <> nil) then
  begin
   for i := 0 to aColumnNames.Count-1 do
    FColumnNames.Add(aColumnNames[i]);
  end;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemViewDef.Destroy;
begin
  FChildrenCRC.Free;
  FChildrenNames.Free;
  FColumnNames.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemViewDef.Assign(Source: TSQLMemMetaObjectDef);
begin
  inherited Assign(Source);
  if (Source is TSQLMemViewDef) then
  begin
   FSelectStatement := TSQLMemViewDef(Source).FSelectStatement;
   FWithCheckOption := TSQLMemViewDef(Source).FWithCheckOption;
   FChildrenCRC.Assign(TSQLMemViewDef(Source).FChildrenCRC);
   FChildrenNames.Assign(TSQLMemViewDef(Source).FChildrenNames);
   FColumnNames.Assign(TSQLMemViewDef(Source).FColumnNames);
   FCreationDate := TSQLMemViewDef(Source).FCreationDate;
  end;
end; // Assign


//------------------------------------------------------------------------------
// load
//------------------------------------------------------------------------------
procedure TSQLMemViewDef.LoadFromStream(Stream: TStream);
var i: Integer;
begin
  inherited LoadFromStream(Stream);
  LoadWideStringFromStream(FSelectStatement,Stream,12555);
  LoadWideStringFromStream(FComment,Stream,12576);
  LoadBooleanFromStream(FWithCheckOption,Stream,12556);
  FChildrenNames.LoadFromStream(Stream);
  FChildrenCRC.SetSize(FChildrenNames.Count);
  for i := 0 to FChildrenNames.Count-1 do
   FChildrenCRC.Items[i] := Integer(GetTableNameCRC(FChildrenNames[i],True));
  FColumnNames.LoadFromStream(Stream);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save
//------------------------------------------------------------------------------
procedure TSQLMemViewDef.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);
  SaveWideStringToStream(FSelectStatement,Stream,12558);
  SaveWideStringToStream(FComment,Stream,12559);
  SaveBooleanToStream(FWithCheckOption,Stream,12575);
  FChildrenNames.SaveToStream(Stream);
  FColumnNames.SaveToStream(Stream);
end; // SaveToStream


//------------------------------------------------------------------------------
// return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
//------------------------------------------------------------------------------
function TSQLMemViewDef.FindChild(crc: Cardinal): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to FChildrenCRC.ItemCount-1 do
   if (FChildrenCRC.Items[i] = Integer(crc)) then
   begin
    Result := True;
    break;
   end;
end; // FindChildViews



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMetaObjectDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.LoadFromStream(Stream: TStream);
begin
 Clear;
 LoadDataFromStream(FLoadedItemCount,sizeof(FLoadedItemCount),Stream,10159);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.SaveToStream(Stream: TStream);
var ItemCount:  Integer;
begin
 ItemCount := Self.Count;
 SaveDataToStream(ItemCount,sizeof(ItemCount),Stream,10158);
end; // SaveToStream


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemMetaObjectDefs.Create;
begin
  FDefsList := TSQLMemSortedStringPtrArray.Create;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemMetaObjectDefs.Destroy;
begin
  Clear;
  FDefsList.Free;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.Assign(Source: TSQLMemMetaObjectDefs);
var i,k,crc: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_Assign}
aaWriteToLog('> TSQLMemMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'Source.ClassName = '+Source.ClassName
+#13#10+'Source.Count = '+IntToStr(Source.Count)
);
{$ENDIF}
  Clear;
  for i:=0 to Source.Count-1 do
   begin
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_Assign}
aaWriteToLog('1 TSQLMemMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'i = '+IntToStr(i)
);
aaWriteToLog('1.1 TSQLMemMetaObjectDefs.Assign, Source.Count = '+IntToStr(Source.Count));
aaWriteToLog('1.2 TSQLMemMetaObjectDefs.Assign, Source[i].Name = '+Source[i].Name);
{$ENDIF}
    k := GetDefNumberByName(Source[i].Name);
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_Assign}
aaWriteToLog('2 TSQLMemMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'k = '+IntToStr(k)
);
{$ENDIF}
    if (k >= 0) then
      raise ESQLMemException.Create(10424,ErrorLDuplicateFieldName,
        [Source[i].Name]);
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_Assign}
aaWriteToLog('3 TSQLMemMetaObjectDefs.Assign, ClassName = '+Self.ClassName);
{$ENDIF}
    InternalAddCreated.Assign(Source.Items[i]);
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_Assign}
aaWriteToLog('4 TSQLMemMetaObjectDefs.Assign, ClassName = '+Self.ClassName);
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_Assign}
aaWriteToLog('< TSQLMemMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'Source.ClassName = '+Source.ClassName
+#13#10+'Source.Count = '+IntToStr(Source.Count)
+#13#10+'Self.Count = '+IntToStr(Self.Count)
);
{$ENDIF}
end;//Assign


//------------------------------------------------------------------------------
// GetCount
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetCount: Integer;
begin
  Result := FDefsList.Count;
end;//GetCount



//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetDef(Index: Integer): TSQLMemMetaObjectDef;
begin
  Result := TSQLMemMetaObjectDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.SetDef(Index: Integer; Value: TSQLMemMetaObjectDef);
begin
  TSQLMemMetaObjectDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// GetDefNumberByName
//    ( if name not found, then Result = -1 )
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetDefNumberByName(Name: WideString): Integer;
var i:   Integer;
    crc: Cardinal;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_GetDefNumberByName}
aaWriteToLog('> TSQLMemMetaObjectDefs.GetDefNumberByName, ClassName = '+Self.ClassName+#13#10+Name+#13#10+'FDefsList.Count = '+IntToStr(FDefsList.Count));
{$ENDIF}
  Result := -1;
  crc := GetTableNameCRC(Name,True);
// optimized in v.5.60
  for i := 0 to FDefsList.Count-1 do
    if (TSQLMemMetaObjectDef(FDefsList.Items[i]).NameCRC = crc) then
    begin
     Result := i;
     break;
    end;
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_GetDefNumberByName}
aaWriteToLog('< TSQLMemMetaObjectDefs.GetDefNumberByName, ClassName = '+Self.ClassName+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
end;//GetDefNumberByName


//------------------------------------------------------------------------------
// GetDefNumberByName
//    ( if name not found, then Result = -1 )
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetDefNumberByCRC(CRC: Cardinal): Integer;
var i:   Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_GetDefNumberByCRC}
aaWriteToLog('> TSQLMemMetaObjectDefs.GetDefNumberByCRC, ClassName = '+Self.ClassName+#13#10+IntToHex(CRC,8)+#13#10+'FDefsList.Count = '+IntToStr(FDefsList.Count));
{$ENDIF}
  Result := -1;
  for i := 0 to FDefsList.Count-1 do
    if (TSQLMemMetaObjectDef(FDefsList.Items[i]).NameCRC = crc) then
    begin
     Result := i;
     break;
    end;
{$IFDEF DEBUG_TRACE_TSQLMemMetaObjectDefs_GetDefNumberByName}
aaWriteToLog('< TSQLMemMetaObjectDefs.GetDefNumberByCRC, ClassName = '+Self.ClassName+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
end;//GetDefNumberByCRC


//------------------------------------------------------------------------------
// GetDefByName
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetDefByName(Name: WideString): TSQLMemMetaObjectDef;
var i: Integer;
begin
  i := GetDefNumberByName(Name);
  if i = -1 then
    Result := nil
  else
    Result := TSQLMemMetaObjectDef(Items[i]);
end;//GetDefByName


//------------------------------------------------------------------------------
// GetDefNumberByObjectId
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetDefNumberByObjectId(id: TSQLMemObjectID): Integer;
var i: Integer;
begin
  Result := -1;
  for i:=0 to FDefsList.Count -1 do
    if (TSQLMemMetaObjectDef(FDefsList[i]).ObjectID = id) then
      begin
        Result := i;
        break;
      end;
end;//GetDefNumberByObjectId


//------------------------------------------------------------------------------
// GetDefByByObjectId
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.GetDefByObjectId(id: TSQLMemObjectID): TSQLMemMetaObjectDef;
var i: Integer;
begin
  i := GetDefNumberByObjectId(id);
  if i <> -1 then
    Result := Items[i]
  else
    Result := nil;
end;//GetDefByByObjectId


//------------------------------------------------------------------------------
// internal add created
//------------------------------------------------------------------------------
function TSQLMemMetaObjectDefs.InternalAddCreated: TSQLMemMetaObjectDef;
begin
  raise ESQLMemException.Create(30339, ErrorGMethodNotOverrided,
                                            ['InternalAddCreated', classname]);
end; // InternalAddCreated


//------------------------------------------------------------------------------
// Add
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.Add(MetaObjectDef: TSQLMemMetaObjectDef);
begin
  FDefsList.Add(MetaObjectDef);
end;//Add


//------------------------------------------------------------------------------
// Delete
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.Delete(Index: Integer);
begin
 if FDefsList[Index] <> nil then
    TSQLMemMetaObjectDef(FDefsList[Index]).Free;
 FDefsList.Delete(Index);
end;//Delete


//------------------------------------------------------------------------------
// Insert
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.Insert(Index: Integer; MetaObjectDef: TSQLMemMetaObjectDef);
begin
  FDefsList.Insert(Index, MetaObjectDef);
end;//Insert


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.Clear;
begin
  while (Count > 0) do
    Delete(0);
  FDefsList.Clear;
end;//Clear


//------------------------------------------------------------------------------
// Move
//------------------------------------------------------------------------------
procedure TSQLMemMetaObjectDefs.Move(CurIndex, NewIndex: Integer);
begin
  FDefsList.Move(CurIndex, NewIndex);
end;//Move




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get index def
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.GetIndexDef(Index: Integer): TSQLMemIndexDef;
begin
  Result := TSQLMemIndexDef(GetDef(Index));
end;// GetIndexDef


//------------------------------------------------------------------------------
// set index def
//------------------------------------------------------------------------------
procedure TSQLMemIndexDefs.SetIndexDef(Index: Integer; Value: TSQLMemIndexDef);
begin
  SetDef(Index, Value);
end;// SetIndexDef


//------------------------------------------------------------------------------
// InternalAddCreated
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.InternalAddCreated: TSQLMemMetaObjectDef;
begin
  Result := TSQLMemIndexDef.Create;
  Add(Result);
end;//InternalAddCreated


//------------------------------------------------------------------------------
// AscDesc and CaseSensitivity lists should contain constants SQLMem_ASC, SQLMem_DESC, SQLMem_NO_CASE, SQLMem_CASE
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.IsIndexExists(FieldNames, AscDescList, CaseSensitivityList: TSQLMemWideStringList): Boolean;
begin
  Result := not (FindIndex(FieldNames,AscDescList,CaseSensitivityList) = INVALID_OBJECT_ID);
end; // IsIndexExists


//------------------------------------------------------------------------------
// find index
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.FindIndex(FieldNames, AscDescList, CaseSensitivityList: TSQLMemWideStringList): TSQLMemObjectID;
var i,j,n:  Integer;
    bOK:    Boolean;
begin
 Result := INVALID_OBJECT_ID;
 if (FieldNames = nil) then
  raise ESQLMemException.Create(10389,ErrorLNilPointer);
 if (AscDescList = nil) then
  raise ESQLMemException.Create(10390,ErrorLNilPointer);
 if (CaseSensitivityList = nil) then
  raise ESQLMemException.Create(10391,ErrorLNilPointer);
 if (FieldNames.Count <> AscDescList.Count) then
  raise ESQLMemException.Create(10276,ErrorLDifferentListsLength,
    [FieldNames.Count,AscDescList.Count]);
 if (FieldNames.Count <> CaseSensitivityList.Count) then
  raise ESQLMemException.Create(10277,ErrorLDifferentListsLength,
    [FieldNames.Count,CaseSensitivityList.Count]);
 n := 0;   
 for i := 0 to Self.Count - 1 do
  begin
   if (Items[i].GetColumnCount < FieldNames.Count) then
    continue
   else
    n := FieldNames.Count-1;
   bOK := True;
   for j := 0 to n do
    if (AnsiUpperCase(FieldNames[j]) = AnsiUpperCase(Items[i].Columns[j].FieldName)) then
     begin
     if (
          ((AscDescList[j] = SQLMem_ASC) and (Items[i].Columns[j].FDescending)) or
          ((AscDescList[j] = SQLMem_DESC) and (not Items[i].Columns[j].FDescending)) or
          ((CaseSensitivityList[j] = SQLMem_CASE) and (Items[i].Columns[j].FCaseInsensitive)) or
          ((CaseSensitivityList[j] = SQLMem_NO_CASE) and (not Items[i].Columns[j].FCaseInsensitive))
         ) then
      begin
        bOK := False;
        break;
      end;
     end
    else
     begin
      bOK := False;
      break;
     end;
   if (bOK) then
    begin
     Result := Items[i].ObjectID;
     break;
    end;
  end;
end; // FindIndex


//------------------------------------------------------------------------------
// primary index
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.FindPrimaryIndex: TSQLMemIndexDef;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Self.Count-1 do
   if (GetIndexDef(i).Primary) then
    begin
     Result := GetIndexDef(i);
     break;
    end;
end; // FindPrimaryIndex


//------------------------------------------------------------------------------
// AddCreated
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.AddCreated: TSQLMemIndexDef;
begin
  Result := TSQLMemIndexDef(InternalAddCreated);
end;//AddCreated


//------------------------------------------------------------------------------
// GetIndexDefByIndexName
//------------------------------------------------------------------------------
function TSQLMemIndexDefs.GetIndexDefByName(Name: WideString): TSQLMemIndexDef;
var
  i: Integer;
begin
  i := GetDefNumberByName(Name);
  if i = -1 then
    Result := nil
  else
    Result := TSQLMemIndexDef(Items[i]);
end;//GetIndexDefByIndexName


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemIndexDefs.LoadFromStream(Stream: TStream);
var IndexDef: TSQLMemIndexDef;
    i:        Integer;
begin
 inherited LoadFromStream(Stream);
 for i := 0 to FLoadedItemCount-1 do
  begin
   IndexDef := TSQLMemIndexDef.Create;
   IndexDef.LoadFromStream(Stream);
   Add(IndexDef);
  end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemIndexDefs.SaveToStream(Stream: TStream);
var i:    Integer;
    qty:  Integer;
begin
 qty := 0;
 for i := 0 to Count-1 do
  if (not Items[i].FTemporary) then
   Inc(qty);
 SaveDataToStream(qty,sizeof(qty),Stream,10343);
 for i := 0 to Count-1 do
  if (not Items[i].FTemporary) then
   TSQLMemIndexDef(Items[i]).SaveToStream(Stream);
end; // SaveToStream




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFieldDefs
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// GetFieldDef
//------------------------------------------------------------------------------
function TSQLMemFieldDefs.GetDef(Index: Integer): TSQLMemFieldDef;
begin
  Result := TSQLMemFieldDef(FDefsList[Index]);
end;//GetFieldDef


//------------------------------------------------------------------------------
// SetFieldDef
//------------------------------------------------------------------------------
procedure TSQLMemFieldDefs.SetDef(Index: Integer; Value: TSQLMemFieldDef);
begin
  TSQLMemFieldDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetFieldDef


//------------------------------------------------------------------------------
// InternalAddCreated
//------------------------------------------------------------------------------
function TSQLMemFieldDefs.InternalAddCreated: TSQLMemMetaObjectDef;
begin
  Result := TSQLMemFieldDef.Create;
  Add(Result);
end;//InternalAddCreated


//------------------------------------------------------------------------------
// AddCreated
//------------------------------------------------------------------------------
function TSQLMemFieldDefs.AddCreated: TSQLMemFieldDef;
begin
  Result := TSQLMemFieldDef(InternalAddCreated);
end;//AddCreated


//------------------------------------------------------------------------------
// Recalc FieldOffsets in children fields
//------------------------------------------------------------------------------
procedure TSQLMemFieldDefs.RecalcFieldOffsets;
var i: integer;
    CurMemOffset, CurDiskOffset: Integer;
    FieldDef: TSQLMemFieldDef;
begin
  // Init Offsets
  FVarcharOrBLOBFieldsExists := False;
  FAutoIncFieldsExists := False;
  FDefaultValuesExists := False;
  CurMemOffset := Count div 8;
  if (Count mod 8 > 0) then Inc(CurMemOffset);
  CurDiskOffset := Count div 8;
  if (Count mod 8 > 0) then Inc(CurDiskOffset);
  // Fill offsets
  for i:=0 to FDefsList.Count-1 do
   begin
     FieldDef := FDefsList[i];
     if (not FVarcharOrBLOBFieldsExists) then
       if ((IsBLOBFieldType(FieldDef.BaseFieldType)) or
           (IsVarcharFieldType(FieldDef.BaseFieldType))) then
        FVarcharOrBLOBFieldsExists := True;
     if (not FAutoIncFieldsExists) then
       if (IsAutoincFieldType(FieldDef.AdvancedFieldType)) then
        FAutoIncFieldsExists := True;
     if (not FDefaultValuesExists) then
       if (not FieldDef.DefaultValue.IsNull) then
        FDefaultValuesExists := True;
     FieldDef.FMemoryOffset := CurMemOffset;
     FieldDef.FDiskOffset := CurDiskOffset;
     CurMemOffset := CurMemOffset + FieldDef.FMemoryDataSize;
     CurDiskOffset := CurDiskOffset + FieldDef.FDiskDataSize;
   end;
end;//RecalcFieldOffsets


//------------------------------------------------------------------------------
// GetMemoryRecordBufferSize
//------------------------------------------------------------------------------
function TSQLMemFieldDefs.GetMemoryRecordBufferSize: Integer;
var i: integer;
begin
  Result := 0;
  // 1 bit for each field ( NULL flags )
  Result := Result + Integer(Count) div 8;
  if (Count mod 8 > 0) then Inc(Result);
  for i:=0 to Count-1 do
    Result := Result + Items[i].FMemoryDataSize;
end;//GetMemoryRecordBufferSize


//------------------------------------------------------------------------------
// GetFieldDefByFieldName
//------------------------------------------------------------------------------
function TSQLMemFieldDefs.GetFieldDefByName(Name: WideString): TSQLMemFieldDef;
begin
  Result := TSQLMemFieldDef(GetDefByName(Name));
end;//GetFieldDefByFieldName


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemFieldDefs.LoadFromStream(Stream: TStream);
var
    FieldDef: TSQLMemFieldDef;
    i:        Integer;
begin
 inherited LoadFromStream(Stream);
 for i := 0 to FLoadedItemCount-1 do
   begin
     FieldDef := TSQLMemFieldDef.Create;
     FieldDef.EngineVersion := FEngineVersion;
     FieldDef.LoadFromStream(Stream);
     Add(FieldDef);
   end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemFieldDefs.SaveToStream(Stream: TStream);
var i: Integer;
begin
 inherited SaveToStream(Stream);
 for i := 0 to Count-1 do
  begin
   TSQLMemFieldDef(Items[i]).EngineVersion := FEngineVersion;
   TSQLMemFieldDef(Items[i]).SaveToStream(Stream);
  end;
end; // SaveToStream


//------------------------------------------------------------------------------
// Set default values to fields
//------------------------------------------------------------------------------
procedure TSQLMemFieldDefs.ApplyDefaultValuesToRecordBuffer(RecordBuffer: TSQLMemRecordBuffer);
var
    fieldDef: TSQLMemFieldDef;
{$I SQLMem_set_null_flag_var.inc}
begin
  if (FDefaultValuesExists) then
  begin
   SET_NULL_FLAG_ToSet := False;
   SET_NULL_FLAG_NullFlags := RecordBuffer;
   for SET_NULL_FLAG_BitNo := 0 to FDefsList.Count-1 do
    begin
      fieldDef := FDefsList.Items[SET_NULL_FLAG_BitNo];
      // Apply DefaultValues
      if (not fieldDef.DefaultValue.IsNull) then
        begin
          fieldDef.DefaultValue.CopyDataToAddress(RecordBuffer + fieldDef.MemoryOffset);
          {$I SQLMem_set_null_flag.inc}
        end;
    end;
  end;
end; // ApplyDefaultValuesToRecordBuffer




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConstraintDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// AddNotNull
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.AddNotNull: TSQLMemConstraintDefNotNull;
begin
  Result := TSQLMemConstraintDefNotNull.Create;
  Add(Result);
end;//AddNotNull


//------------------------------------------------------------------------------
// AddCheck
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.AddCheck: TSQLMemConstraintDefCheck;
begin
  Result := TSQLMemConstraintDefCheck.Create;
  Add(Result);
end;//AddCheck


//------------------------------------------------------------------------------
// Add PK
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.AddPK: TSQLMemConstraintDefPrimary;
begin
  Result := TSQLMemConstraintDefPrimary.Create;
  Add(Result);
end;//AddPK


//------------------------------------------------------------------------------
// Add Unique
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.AddUnique: TSQLMemConstraintDefUnique;
begin
  Result := TSQLMemConstraintDefUnique.Create;
  Add(Result);
end;//AddUnique


//------------------------------------------------------------------------------
// create FK
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.AddFK: TSQLMemConstraintDefForeignKey;
begin
  Result := TSQLMemConstraintDefForeignKey.Create;
  Add(Result);
  FForeignKeysExists := True;
end; // AddFK


//------------------------------------------------------------------------------
// create FKAction (master table action for FK in detail table)
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.AddFKAction: TSQLMemConstraintDefForeignKeyAction;
begin
  Result := TSQLMemConstraintDefForeignKeyAction.Create;
  Add(Result);
  FForeignKeysActionsExists := True;
end; // AddFKAction


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemConstraintDefs.Create;
begin
 inherited;
 FForeignKeysExists := False;
 FForeignKeysActionsExists := False;
end; // Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefs.Assign(Source: TSQLMemMetaObjectDefs);
var i: Integer;
begin
  Clear;
  FForeignKeysExists := False;
  FForeignKeysActionsExists := False;
  for i:=0 to Source.Count-1 do
   begin
    case TSQLMemConstraintDef(Source.Items[i]).ConstraintType of
     ctNotNull:
       AddNotNull.Assign(TSQLMemConstraintDefNotNull(Source.Items[i]));
     ctCheck:
       AddCheck.Assign(TSQLMemConstraintDefCheck(Source.Items[i]));
     ctPK:
       AddPK.Assign(TSQLMemConstraintDefPrimary(Source.Items[i]));
     ctUnique:
       AddUnique.Assign(TSQLMemConstraintDefUnique(Source.Items[i]));
     ctFK:
      begin
       AddFK.Assign(TSQLMemConstraintDefForeignKey(Source.Items[i]));
       FForeignKeysExists := True;
      end;
     ctFKAction:
      begin
       AddFKAction.Assign(TSQLMemConstraintDefForeignKeyAction(Source.Items[i]));
       FForeignKeysActionsExists := True;
      end
     else
       raise ESQLMemException.Create(30035, ErrorGNotImplementedYet);
    end;
   end;
end;//Assign


//------------------------------------------------------------------------------
// delete constraint
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefs.Delete(Index: Integer);
var i: Integer;
begin
  inherited Delete(Index);
  FForeignKeysExists := False;
  FForeignKeysActionsExists := False;
  for i := 0 to GetCount-1 do
   if (TSQLMemConstraintDef(FDefsList[i]).FConstraintType = ctFK) then
    FForeignKeysExists := True
   else
   if (TSQLMemConstraintDef(FDefsList[i]).FConstraintType = ctFKAction) then
    FForeignKeysActionsExists := True;
end; // Delete


//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.GetDef(Index: Integer): TSQLMemConstraintDef;
begin
  Result := TSQLMemConstraintDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefs.SetDef(Index: Integer; Value: TSQLMemConstraintDef);
begin
  if FDefsList[Index] <> nil then
    TSQLMemConstraintDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// return true if actions with update action <> NoAction exists
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.GetForeignKeysActionsUpdateExists: Boolean;
var i: Integer;
begin
  Result := FForeignKeysActionsExists;
  if (Result) then
   begin
    Result := False;
    for i := 0 to Count-1 do
     if (TSQLMemConstraintDef(FDefsList.Items[i]).ConstraintType = ctFKAction) then
      if (TSQLMemConstraintDefForeignKeyAction(FDefsList.Items[i]).UpdateAction <>
            cfkaNoAction) then
        begin
         Result := True;
         break;
        end;
   end;
end; // GetForeignKeysActionsUpdateExists


//------------------------------------------------------------------------------
// return true if actions with delete action <> NoAction exists
//------------------------------------------------------------------------------
function TSQLMemConstraintDefs.GetForeignKeysActionsDeleteExists: Boolean;
var i: Integer;
begin
  Result := FForeignKeysActionsExists;
  if (Result) then
   begin
    Result := False;
    for i := 0 to Count-1 do
     if (TSQLMemConstraintDef(FDefsList.Items[i]).ConstraintType = ctFKAction) then
      if (TSQLMemConstraintDefForeignKeyAction(FDefsList.Items[i]).DeleteAction <>
            cfkaNoAction) then
        begin
         Result := True;
         break;
        end;
   end;
end; // GetForeignKeysActionsDeleteExists


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefs.LoadFromStream(Stream: TStream);
var i:              Integer;
    ConstraintDef:  TSQLMemConstraintDef;
    ConstraintType: TSQLMemConstraintType;
begin
  FForeignKeysExists := False;
  FForeignKeysActionsExists := False;
  inherited LoadFromStream(Stream);
  for i := 0 to FLoadedItemCount - 1 do
    begin
      LoadDataFromStream(ConstraintType,sizeof(ConstraintType),Stream,10220);
      case ConstraintType of
        ctNotNull:
         ConstraintDef := AddNotNull;
        ctCheck:
         ConstraintDef := AddCheck;
        ctPK:
         ConstraintDef := AddPK;
        ctUnique:
         ConstraintDef := AddUnique;
        ctFK:
         begin
           ConstraintDef := AddFK;
           FForeignKeysExists := True;
         end;
        ctFKAction:
         begin
           ConstraintDef := AddFKAction;
           FForeignKeysActionsExists := True;
         end
        else
          raise ESQLMemException.Create(30316, ErrorGUnknownConstrainType,
                                     [Integer(ConstraintType)]);
      end;
      ConstraintDef.LoadFromStream(Stream);
    end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefs.SaveToStream(Stream: TStream);
var i: Integer;
begin
  inherited SaveToStream(Stream);
  for i := 0 to Count-1 do
   begin
    SaveDataToStream(Items[i].FConstraintType,sizeof(Items[i].ConstraintType),
      Stream,10219);
    Items[i].SaveToStream(Stream);
   end;
end; // SaveToStream


//------------------------------------------------------------------------------
// extract all foreign keys
//------------------------------------------------------------------------------
procedure TSQLMemConstraintDefs.ExtractForeignKeys(Dest: TSQLMemConstraintDefs);
var i: Integer;
begin
  i := 0;
  while (i < FDefsList.Count) do
   begin
    if (TSQLMemConstraintDef(FDefsList.Items[i]).ConstraintType in [ctFKAction,ctFK]) then
     begin
      // we must move FK to Dest if it is possible
      if ((Dest <> nil) and (TSQLMemConstraintDef(FDefsList.Items[i]).ConstraintType = ctFK)) then
       Dest.AddFK.Assign(FDefsList.Items[i]);
      // we must delete both FK and FKAction 
      FDefsList.Delete(i);
     end
    else
     Inc(i); 
   end;
end; // ExtractForeignKeys




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSequenceDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TSQLMemSequenceDefs.GetDef(Index: Integer): TSQLMemSequenceDef;
begin
  Result := TSQLMemSequenceDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TSQLMemSequenceDefs.SetDef(Index: Integer;
  Value: TSQLMemSequenceDef);
begin
  TSQLMemSequenceDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// InternalAddCreated
//------------------------------------------------------------------------------
function TSQLMemSequenceDefs.InternalAddCreated: TSQLMemMetaObjectDef;
begin
  Result := TSQLMemSequenceDef.Create;
  Add(Result);
end;//InternalAddCreated


//------------------------------------------------------------------------------
// AddCreated
//------------------------------------------------------------------------------
function TSQLMemSequenceDefs.AddCreated: TSQLMemSequenceDef;
begin
  Result := TSQLMemSequenceDef(InternalAddCreated);
end;//AddCreated


//------------------------------------------------------------------------------
// GetSequenceDefByName
//------------------------------------------------------------------------------
function TSQLMemSequenceDefs.GetSequenceDefByName(Name: WideString): TSQLMemSequenceDef;
var i: Integer;
begin
  i := GetDefNumberByName(Name);
  if i = -1 then
    Result := nil
  else
    Result := TSQLMemSequenceDef(Items[i]);
end;//GetSequenceDefByName



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemViewDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
function TSQLMemViewDefs.InternalAddCreated: TSQLMemMetaObjectDef;
begin
  Result := TSQLMemViewDef.Create;
  Add(Result);
end; // InternalAddCreated


//------------------------------------------------------------------------------
// load
//------------------------------------------------------------------------------
procedure TSQLMemViewDefs.LoadFromStream(Stream: TStream);
var i:        Integer;
    viewDef:  TSQLMemViewDef;
begin
  inherited LoadFromStream(Stream);
  for i := 0 to FLoadedItemCount-1 do
  begin
    viewDef := TSQLMemViewDef(InternalAddCreated);
    viewDef.LoadFromStream(Stream);
  end;
end; // LoadFromStreamS


//------------------------------------------------------------------------------
// save
//------------------------------------------------------------------------------
procedure TSQLMemViewDefs.SaveToStream(Stream: TStream);
var i:        Integer;
    viewDef:  TSQLMemViewDef;
begin
  inherited SaveToStream(Stream);
  for i := 0 to FDefsList.Count-1 do
  begin
    viewDef := TSQLMemViewDef(FDefsList.Items[i]);
    viewDef.SaveToStream(Stream);
  end;
end; // SaveToStream


//------------------------------------------------------------------------------
// return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
//------------------------------------------------------------------------------
function TSQLMemViewDefs.FindChildren(Name: WideString): Boolean;
var i:        Integer;
    viewDef:  TSQLMemViewDef;
    crc:      Cardinal;
begin
  Result := False;
  crc := GetTableNameCRC(Name,True);
  for i := 0 to FDefsList.Count-1 do
  begin
    viewDef := TSQLMemViewDef(FDefsList.Items[i]);
    Result := viewDef.FindChild(crc);
    if (Result) then
     break;
  end;
end; // FindChildren


//------------------------------------------------------------------------------
// delete all views that references view or table with specified name - for DROP [TABLE | VIEW] with CASCADE
//------------------------------------------------------------------------------
procedure TSQLMemViewDefs.DeleteChildren(Name: WideString);
var i:        Integer;
    viewDef:  TSQLMemViewDef;
    crc:      Cardinal;
begin
  crc := GetTableNameCRC(Name,True);
  i := 0;
  while (i < FDefsList.Count) do
  begin
    viewDef := TSQLMemViewDef(FDefsList.Items[i]);
    if (viewDef.FindChild(crc)) then
     FDefsList.Delete(i)
    else
     Inc(i);
  end;
end; // DeleteChildren



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCursor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set index name
//------------------------------------------------------------------------------
procedure TSQLMemCursor.SetIndexName(Value: WideString);
var
  SQLMemIndexDef: TSQLMemIndexDef;
begin
  FIndexName := Value;
  SQLMemIndexDef := FIndexDefs.GetIndexDefByName(Value);
  if (SQLMemIndexDef <> nil) then
   begin
     FIndexID := SQLMemIndexDef.ObjectID;
   end
  else
   FIndexID := INVALID_OBJECT_ID;
end;// SetIndexName


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TSQLMemCursor.SetCaseInsensitive(Value: Boolean);
begin
  FCaseInsensitive := Value;
end; // SetCaseInsensitive


{$IFDEF DEBUG_LOG}
procedure TSQLMemCursor.WriteRecordBufferToLog(Buffer: TSQLMemRecordBuffer);
var i,n:  Integer;
    s,pr: String;
    v:    TSQLMemVariant;
begin
  if (Buffer = nil) then
   begin
    aaWriteToLog('TSQLMemCursor.WriteRecordBufferToLog - Buffer = nil');
    Exit;
   end;
  n := FFieldDefs.Count;
  s := 'TSQLMemCursor.WriteRecordBufferToLog - Buffer = '+IntToHex(Integer(Buffer),8)
        +#13#10+'RecordSize = '+IntToStr(FRecordSize)
        +', RecordBufferSize = '+IntToStr(FRecordBufferSize)+', FieldCount = '+IntToStr(n)+#13#10;
  v := TSQLMemVariant.Create;
  for i := 0 to n-1 do
   begin
    if (i = 0) then
     pr := ''
    else
     pr := #9;
    GetFieldValue(v,i,True,False);
    if (v.IsNull) then
     s := s + pr + GetReservedWord(rwNULL)
    else
     s := s + pr + v.AsString;
   end;
  v.Free;
  aaWriteToLog(#13#10+s);
end;
{$ENDIF}

{
//------------------------------------------------------------------------------
// set CurrentRecordID
//------------------------------------------------------------------------------
procedure TSQLMemCursor.SetCurrentRecordIDAfterDelete;
begin
  Move(FDeleteCurrentRecordID,CurrentRecordID,SizeOf(TSQLMemRecordID));
end; // SetCurrentRecordIDAfterDelete
}

//------------------------------------------------------------------------------
// Rename Field by Field Index in FieldDefs
//------------------------------------------------------------------------------
procedure TSQLMemCursor.RenameField(FieldName, NewFieldName: WideString);
var
  fd: TSQLMemFieldDef;
begin
  // Check Field Exists
  fd := FFieldDefs.GetFieldDefByName(FieldName);
  if (fd = nil) then
    raise ESQLMemException.Create(30345, ErrorGFieldWithNameNotFound, [FieldName]);

  // Check For Duplicate FieldName
  if ( FFieldDefs.GetFieldDefByName(NewFieldName) <> nil ) then
   raise ESQLMemException.Create(30346, ErrorGCannotRenameField,
                                     [FieldName, NewFieldName]);

  fd.Name := NewFieldName;
end;//RenameField


//------------------------------------------------------------------------------
// update table definitions (fields, indexes, constraints)
//------------------------------------------------------------------------------
procedure TSQLMemCursor.UpdateTableDefinitions;
begin
end; // UpdateTableDefinitions


//------------------------------------------------------------------------------
// initialize record buffer
//------------------------------------------------------------------------------
procedure TSQLMemCursor.InternalInitRecord(RecordBuffer: TSQLMemRecordBuffer; InsertMode: Boolean);
var x,y: Integer;
begin
 // set null flags for all fields
 y := FFieldDefs.Count;
 x := y div 8;
 if (y mod 8 > 0) then
  Inc(x);
 FillChar(RecordBuffer^,x,$FF);
 // set Default Values...
 if ((not FTemporary) and (InsertMode)) then
  FFieldDefs.ApplyDefaultValuesToRecordBuffer(RecordBuffer);
end; // InternalInitRecord


//------------------------------------------------------------------------------
// GetIndexDefs
//------------------------------------------------------------------------------
function TSQLMemCursor.GetIndexDefs: TSQLMemIndexDefs;
begin
  Result := FIndexDefs;
end;// GetIndexDefs


//------------------------------------------------------------------------------
// Receive VisisbleFieldDefs.FieldNoReference
//------------------------------------------------------------------------------
procedure TSQLMemCursor.ReceiveFieldNoReferences(Stream: TStream);
var i, num: Integer;
begin
  for i := 0 to FVisibleFieldDefs.Count - 1 do
   begin
    LoadDataFromStream(num,SizeOf(num),Stream,11186);
    FVisibleFieldDefs.Items[i].FieldNoReference := num;
   end;
end; // ReceiveFieldNoReferences


//------------------------------------------------------------------------------
// check field value and if not null move data from RecordBuffer to Buffer
//------------------------------------------------------------------------------
function TSQLMemCursor.GetFieldData(
                          FieldNo:      Integer; // field no
                          Buffer:       Pointer; // buffer
                          RecordBuffer: TSQLMemRecordBuffer // record buffer
                                      ): Boolean;
begin
 if (FieldNo >= VisibleFieldDefs.Count) then
   raise ESQLMemException.Create(10005,ErrorLInvalidFieldNumber,[FieldNo,VisibleFieldDefs.Count]);
 Result := SQLMemBaseEngine.GetFieldData(VisibleFieldDefs[FieldNo].FieldNoReference,
                                      FieldDefs,Buffer,RecordBuffer);
end; // GetFieldData


//------------------------------------------------------------------------------
// set field data from Buffer to RecordBuffer
//------------------------------------------------------------------------------
procedure TSQLMemCursor.SetFieldData(
                            FieldNo:      Integer;
                            Buffer:       Pointer;
                            RecordBuffer: TSQLMemRecordBuffer // record buffer
                                      );
begin
 if (FieldNo >= VisibleFieldDefs.Count) then
   raise ESQLMemException.Create(10006,ErrorLInvalidFieldNumber,[FieldNo,VisibleFieldDefs.Count]);
 SQLMemBaseEngine.SetFieldData(VisibleFieldDefs[FieldNo].FieldNoReference,
                                      FieldDefs,Buffer,RecordBuffer);
end; // SetFieldData


//------------------------------------------------------------------------------
// get blob value
//------------------------------------------------------------------------------
procedure TSQLMemCursor.GetBLOBValue(V: TSQLMemVariant; aFieldNo: Integer);
var
  bs:     TSQLMemStream;
  size:   Int64;
  zero:   Word;
  l:      Integer;
begin
 zero := 0;
 V.SetNull;
 V.DataType := FieldDefs[aFieldNo].BaseFieldType;
 bs := Self.InternalCreateBlobStream(False,aFieldNo,bomRead);
 try
   size := bs.Size;
   if (size > 0) then
    begin
     if (V.DataType = bftWideClob) then
      l := 2
     else
      l := 1;
     V.SetDataSize(size+l);
     bs.ReadBuffer(V.pData^,size);
     Move(zero,PAnsiChar(V.pData + size)^,l);
    end;
 finally
   InternalCloseBLOB(aFieldNo);
//     bs.Free;
 end;
end; // GetBLOBValue


//------------------------------------------------------------------------------
// get field value
//------------------------------------------------------------------------------
procedure TSQLMemCursor.GetFieldValue(Value: TSQLMemVariant; FieldNo: Integer; DirectAccess: Boolean; CopyFlag: Boolean = True);
var
    Offset: Integer;
    Buffer: PAnsiChar;
{$I SQLMem_check_null_flag_var.inc}
begin
 if (DirectAccess) then
  begin
   if (FieldNo >= FieldDefs.Count) then
     raise ESQLMemException.Create(10317,ErrorLInvalidFieldNumber,
              [FieldNo,FieldDefs.Count]);
   CHECK_NULL_FLAG_NullFlags := CurrentRecordBuffer;
   CHECK_NULL_FLAG_BitNo := FieldNo;
   {$I SQLMem_check_null_flag.inc}
   if (CHECK_NULL_FLAG_Result) then
    Value.SetNull
   else
    begin
     if (IsBLOBFieldType(FieldDefs[FieldNo].FBaseFieldType)) then
      GetBLOBValue(Value,FieldNo)
     else
      begin
       Offset := FieldDefs[FieldNo].MemoryOffset;
       Buffer := PAnsiChar(CurrentRecordBuffer + Offset);
       Value.SetData(
                            Buffer,
                            FieldDefs[FieldNo].MemoryDataSize,
                            FieldDefs[FieldNo].FBaseFieldType,
                            CopyFlag
                           );
       end;
    end;
  end // access to base field defs, without projection
 else
  begin
   if (FieldNo >= VisibleFieldDefs.Count) then
     raise ESQLMemException.Create(10737,ErrorLInvalidFieldNumber,
              [FieldNo,VisibleFieldDefs.Count]);
   CHECK_NULL_FLAG_NullFlags := CurrentRecordBuffer;
   CHECK_NULL_FLAG_BitNo := VisibleFieldDefs[FieldNo].FieldNoReference;
   {$I SQLMem_check_null_flag.inc}
   if (CHECK_NULL_FLAG_Result) then
    Value.SetNull
   else
    begin
     if (IsBLOBFieldType(VisibleFieldDefs[FieldNo].FBaseFieldType)) then
      GetBLOBValue(Value,VisibleFieldDefs[FieldNo].FFieldNoReference)
     else
      begin
       Offset := VisibleFieldDefs[FieldNo].MemoryOffset;
       Buffer := PAnsiChar(CurrentRecordBuffer + Offset);
       Value.SetData(
                            Buffer,
                            VisibleFieldDefs[FieldNo].MemoryDataSize,
                            VisibleFieldDefs[FieldNo].FBaseFieldType,
                            CopyFlag
                           );
      end;
    end;
  end; // access to fields using projection
end; // GetFieldValue


//------------------------------------------------------------------------------
// get field value
//------------------------------------------------------------------------------
procedure TSQLMemCursor.SetFieldValue(
                            Value:        TSQLMemVariant;
                            FieldNo:      Integer;
                            DirectAccess: Boolean;
                            RecordBuffer: TSQLMemRecordBuffer = nil
                                  );
var Buffer:     PAnsiChar;
    Offset:     Integer;
{$I SQLMem_set_null_flag_var.inc}
begin
 if (RecordBuffer = nil) then
   RecordBuffer := CurrentRecordBuffer;
 if (DirectAccess) then
  begin
   if (FieldNo >= FieldDefs.Count) then
     raise ESQLMemException.Create(10318,ErrorLInvalidFieldNumber,
            [FieldNo,FieldDefs.Count]);
   if (Value.IsNull) then
    begin
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I SQLMem_set_null_flag.inc}
    end
   else
    begin
     SET_NULL_FLAG_ToSet := False;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I SQLMem_set_null_flag.inc}
     if (IsBLOBFieldType(FieldDefs[FieldNo].FBaseFieldType)) then
{ TODO -oLeo : implement normal settings of the BLOB data }
       raise ESQLMemException.Create(11589,ErrorLSetBLOBFieldValueIsNotAllowed,[FieldNo,FTableName])
     else
      begin
       Offset := FieldDefs[FieldNo].MemoryOffset;
       Buffer := PAnsiChar(RecordBuffer + Offset);
       if (Value.DataType <> FieldDefs[FieldNo].FBaseFieldType) then
         Value.Cast(FieldDefs[FieldNo].FBaseFieldType);
       Value.CopyDataToAddress(Buffer,FieldDefs[FieldNo].MemoryDataSize);
      end;
    end;
  end // access to base field defs, without projection
 else
  begin
   if (FieldNo >= VisibleFieldDefs.Count) then
     raise ESQLMemException.Create(10738,ErrorLInvalidFieldNumber,
            [FieldNo,VisibleFieldDefs.Count]);
   if (Value.IsNull) then
    begin
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := VisibleFieldDefs[FieldNo].FieldNoReference;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I SQLMem_set_null_flag.inc}
    end
   else
    begin
     SET_NULL_FLAG_ToSet := False;
     SET_NULL_FLAG_BitNo := VisibleFieldDefs[FieldNo].FieldNoReference;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I SQLMem_set_null_flag.inc}
     if (IsBLOBFieldType(VisibleFieldDefs[FieldNo].FBaseFieldType)) then
{ TODO -oLeo : implement normal settings of the BLOB data }
       raise ESQLMemException.Create(11591,ErrorLSetBLOBFieldValueIsNotAllowed,[FieldNo,FTableName])
     else
      begin
       Offset := VisibleFieldDefs[FieldNo].MemoryOffset;
       Buffer := PAnsiChar(RecordBuffer + Offset);
       Value.Cast(VisibleFieldDefs[FieldNo].FBaseFieldType);
       Value.CopyDataToAddress(Buffer,VisibleFieldDefs[FieldNo].MemoryDataSize);
      end;
    end;
  end; // access to fields using projection
end; // SetFieldValue


//------------------------------------------------------------------------------
// allocate record buffer and set null flags
//------------------------------------------------------------------------------
function TSQLMemCursor.AllocateRecordBuffer: TSQLMemRecordBuffer;
begin
 Result := MemoryManager.GetMem(RecordBufferSize);
 if (FTempRecordBuffer =  nil) then
  FTempRecordBuffer := MemoryManager.GetMem(RecordBufferSize);
end; // AllocateRecordBuffer


//------------------------------------------------------------------------------
// free record buffer
//------------------------------------------------------------------------------
procedure TSQLMemCursor.FreeRecordBuffer(var Buffer: TSQLMemRecordBuffer);
begin
  MemoryManager.FreeAndNilMem(Buffer);
end; // FreeRecordBuffer


//------------------------------------------------------------------------------
// allocate record buffer and set null flags
//------------------------------------------------------------------------------
function TSQLMemCursor.AllocateKeyRecordBuffer: TSQLMemRecordBuffer;
begin
  Result := MemoryManager.GetMem(KeyBufferSize);
end;


//------------------------------------------------------------------------------
// initialize record buffer
//------------------------------------------------------------------------------
procedure TSQLMemCursor.InternalInitKeyBuffer(RecordBuffer: TSQLMemRecordBuffer);
begin
  FillChar(RecordBuffer^,KeyBufferSize,0);
  InternalInitRecord(RecordBuffer,False);
end;


//------------------------------------------------------------------------------
// go to first record (before first record to BOF)
//------------------------------------------------------------------------------
procedure TSQLMemCursor.InternalFirst;
begin
 FirstPosition := True;
 LastPosition := False;
end; // InternalFirst


//------------------------------------------------------------------------------
// go to last record (after last record to EOF)
//------------------------------------------------------------------------------
procedure TSQLMemCursor.InternalLast;
begin
 FirstPosition := False;
 LastPosition := True;
end; // InternalLast


//------------------------------------------------------------------------------
// save position
//------------------------------------------------------------------------------
function TSQLMemCursor.SavePosition: Pointer;
begin
// Result := New(PSQLMemCursorPos);
 Result := MemoryManager.GetMem(SizeOf(TSQLMemCursorPos));
 PSQLMemCursorPos(Result)^.FirstPosition := Self.FirstPosition;
 PSQLMemCursorPos(Result)^.LastPosition := Self.LastPosition;
 PSQLMemCursorPos(Result)^.RecordID := Self.CurrentRecordID;
end; // SavePosition


//------------------------------------------------------------------------------
// restore position
//------------------------------------------------------------------------------
procedure TSQLMemCursor.RestorePosition(Pos: Pointer);
begin
 Self.FirstPosition := PSQLMemCursorPos(Pos)^.FirstPosition;
 Self.LastPosition := PSQLMemCursorPos(Pos)^.LastPosition;
 Self.CurrentRecordID := PSQLMemCursorPos(Pos)^.RecordID;
end; // RestorePosition


//------------------------------------------------------------------------------
// free position
//------------------------------------------------------------------------------
procedure TSQLMemCursor.FreePosition(var Pos: Pointer);
begin
 if (Pos <> nil) then
  MemoryManager.FreeAndNilMem(Pos);
end; // FreePosition


//------------------------------------------------------------------------------
// added in v.5.30 - moved from TSQLMemMain.GetRecord
//------------------------------------------------------------------------------
procedure TSQLMemCursor.GetCalcFieldsAndBookMarkData(bInsert: Boolean = False);
var
    Bookmark:           PSQLMemBookmarkInfo;
begin
  // fixed in v.5.60 to avoid problems with BLOB fields usage in calculated fields
  // write bookmark info to record buffer
  Bookmark := PSQLMemBookmarkInfo(FCurrentRecordBuffer + FBookmarkOffset);
  Bookmark^.BookmarkData := CurrentRecordID;
  if (bInsert) then
   Bookmark^.BookmarkFlag := abfInserted
  else
   Bookmark^.BookmarkFlag := abfCurrent;
  if (Dataset <> nil) then
    TSQLMemDataset(Dataset).ClearAndGetCalcFields(TRecordBuffer(CurrentRecordBuffer));
end; // GetCalcFieldsAndBookMarkData


//------------------------------------------------------------------------------
// refresh - added in v.5.30
//------------------------------------------------------------------------------
procedure TSQLMemCursor.InternalRefresh;
begin
 if (IsFilterApplied) then
  begin
    DeactivateFilters;
    if (Dataset <> nil) then
     TSQLMemDataset(Dataset).ActivateFilters;
  end;
 if (CurrentRecordBuffer = nil) then
  InternalFirst
 else
 //  changed in v.4.70
  if (GetRecordBuffer(grmCurrent) <> grrOK) then
   if (GetRecordBuffer(grmNext) <> grrOK) then
    if (GetRecordBuffer(grmPrior) <> grrOK) then
     InternalFirst;
end; // InternalRefresh


//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
procedure TSQLMemCursor.InternalInsert;
begin
//
end; // InternalInsert


//------------------------------------------------------------------------------
// return disk record size
//------------------------------------------------------------------------------
function TSQLMemCursor.GetDiskRecordSize: Integer;
begin
 if (FFieldDefs.Count <= 0) then
  raise ESQLMemException.Create(11625,ErrorLNoFields);
 Result := FieldDefs[FFieldDefs.Count-1].DiskOffset +
   FFieldDefs[FFieldDefs.Count-1].DiskDataSize;
end; // GetDiskRecordSize


//------------------------------------------------------------------------------
// return true if index applied
//------------------------------------------------------------------------------
function TSQLMemCursor.IsIndexApplied: Boolean;
begin
  Result := (IndexID <> INVALID_OBJECT_ID);
end; // IsIndexApplied


//------------------------------------------------------------------------------
// return true if filter applied
//------------------------------------------------------------------------------
function TSQLMemCursor.IsFilterApplied: Boolean;
begin
  Result := ((FilterExpression <> nil) or (FilterRecord <> nil) or
             (SQLFilterExpression <> nil));
end; // IsFilterApplied


//------------------------------------------------------------------------------
// return true if range is applied
//------------------------------------------------------------------------------
function TSQLMemCursor.IsRangeApplied: Boolean;
begin
  Result := ((FRangeStartBuffer <> nil) or (FRangeEndBuffer <> nil));
end; // IsRangeApplied


//------------------------------------------------------------------------------
// reset range
//------------------------------------------------------------------------------
function TSQLMemCursor.IsViewRestricted: Boolean;
begin
  Result := (IsFilterApplied or IsRangeApplied);
end; // IsViewRestricted


//------------------------------------------------------------------------------
// update index definitions in dataset
//------------------------------------------------------------------------------
procedure TSQLMemCursor.UpdateIndexDefinitions;
begin
  if (Dataset <> nil) then
   TSQLMemDataset(Dataset).UpdateIndexDefinitions(Self);
end; // UpdateIndexDefinitions


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSessionNamedObject
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSessionNamedObject.Create(Name: WideString);
begin
  FName := Name;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSessionNamedObjectSequenceValue
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSessionNamedObjectSequenceValue.Create(ValueName: WideString;
  Value: TSQLMemSequenceValue);
begin
  inherited Create(ValueName);
  FValue := Value;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBaseSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.SetCaseInsensitive(Value: Boolean);
begin
  FCaseInsensitive := Value;
end; // SetCaseInsensitive


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemBaseSession.Create;
begin
  FSessionNamedObjectList := TSQLMemSortedStringPtrArray.Create;
  FSessionID := INVALID_SESSION_ID;
  FTemporary := False;
  FInMemory := False;
  FSessionVariables := nil;
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemBaseSession.Destroy;
var i: integer;
begin
  SetConnected(False);
  if (Length(FCryptoParams.Password) > 0) then
   FillChar(FCryptoParams.Password[1],Length(FCryptoParams.Password),$00);
  FCryptoParams.Password := '';
{$IFNDEF SQLMEMTABLE}
  if (Length(FConnectParams.CryptoInfo.Password) > 0) then
   FillChar(FConnectParams.CryptoInfo.Password[1],Length(FConnectParams.CryptoInfo.Password),$00);
  FConnectParams.CryptoInfo.Password := '';
  FillChar(FCryptoParams,SizeOf(FCryptoParams),$00);
  FConnectParams.RemoteHost := '';
  FillChar(FConnectParams,SizeOf(FConnectParams),$00);
{$ENDIF}  
  for i:=0 to FSessionNamedObjectList.Count -1 do
    TSQLMemSessionNamedObject(FSessionNamedObjectList[i]).Free;
  FSessionNamedObjectList.Free;
  if (FSessionVariables <> nil) then
   FSessionVariables.Free;
  inherited; 
end;//destroy


//------------------------------------------------------------------------------
// create database
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.CreateDatabase;
begin
  raise ESQLMemException.Create(10888,ErrorLOperationIsNotSupported);
end; // CreateDatabase


//------------------------------------------------------------------------------
// Get Named object from session
//------------------------------------------------------------------------------
function TSQLMemBaseSession.GetNamedObject(ObjectName: WideString): TSQLMemSessionNamedObject;
var i: integer;
begin
  Result := nil;
  for i:=0 to FSessionNamedObjectList.Count -1 do
   if (ObjectName = TSQLMemSessionNamedObject(FSessionNamedObjectList[i]).Name) then
    begin
     Result := TSQLMemSessionNamedObject(FSessionNamedObjectList[i]);
     break;
    end;
end;//GetNamedObject


//------------------------------------------------------------------------------
// set sequence value
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.SetSequenceValue(const Name:  TSQLMemObjectName;
                                           const Value: TSQLMemSequenceValue);
var
  OldValue: TSQLMemSessionNamedObject;
begin
  OldValue := GetNamedObject(Name);
  if (OldValue = nil) then
   begin
    // create new value
    OldValue := TSQLMemSessionNamedObjectSequenceValue.Create(Name,Value);
    FSessionNamedObjectList.Add(OldValue);
   end
  else
   begin
    TSQLMemSessionNamedObjectSequenceValue(OldValue).Value := Value;
   end;
end; // SetSequenceValue


//------------------------------------------------------------------------------
// for client and server sessions
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.ReceiveData(Buffer: PAnsiChar; BufferSize: Integer);
begin
end; // ReceiveData


//------------------------------------------------------------------------------
// for client and server sessions
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.OnDisconnect;
begin
end; // OnDisconnect


//------------------------------------------------------------------------------
// for TSQLMemLocalSession called by TSQLMemServerSession
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.RemoveAllLocks;
begin
end; // RemoveAllLocks


//------------------------------------------------------------------------------
// clear disk cache in single-user / multi-user
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.ClearCache;
begin
end; // ClearCache


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TSQLMemBaseSession.GetTableComment(TableName: WideString): WideString;
begin
  Result := '';
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.SetTableComment(TableName, Comment: WideString);
begin
// do nothing
end; // SetTableComment


//------------------------------------------------------------------------------
// call OnError event handler
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.DoOnError(ErrorCode: Integer;  NativeError: Integer = -1; ErrorMessage: AnsiString = '');
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in TSQLMemBaseSession');
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
end; // DoOnError


//------------------------------------------------------------------------------
// set database params
//------------------------------------------------------------------------------
procedure TSQLMemBaseSession.SetDatabaseParams(var DBParams: TSQLMemSQLDatabaseParams);
begin
  DBParams.Session := Self;
  DBParams.ParamsSet := True;
  DBParams.DatabaseName := FDatabaseName;
  DBParams.SessionName := FSessionName;
  DBParams.InMemory := FInMemory;
  DBParams.RequestLive := True;
  DBParams.Params := nil;
  DBParams.CaseInsensitive := FCaseInsensitive;
end; // SetDatabaseParams




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLProcessor.Create;
begin
  FSQLParams := TSQLMemSQLParams.Create;
  FSQLMemQuery := nil;
  FCursor := nil;
  FSqlText := '';
  FNeverOpened := True;
  FParamsChanged := False;
  FCaseInsensitive := False;
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLProcessor.Create(Query: TDataSet);
begin
  Create;
  FSQLMemQuery := Query;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemSQLProcessor.Destroy;
begin
  FSQLParams.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// OpenQuery
//------------------------------------------------------------------------------
function TSQLMemSQLProcessor.OpenQuery(TableNames: TSQLMemWideStringList): TSQLMemCursor;
var NewHashValue: TSQLMemRecordHashValue;
begin
  FParamsChanged := False;
  if (SQLParams.Count > 0) then
   if (FNeverOpened) then
    begin
     FParamsHash := SQLParams.GetHashValue;
    end
   else
    begin
     NewHashValue := SQLParams.GetHashValue;
     // if params were changed since last opening
     if (NewHashValue <> FParamsHash) then
      UpdateParams;
     FParamsHash := NewHashValue; 
    end;
  FRowsAffected := 0;
  Result := nil;
end;//OpenQuery


//------------------------------------------------------------------------------
// ExecuteQuery
//------------------------------------------------------------------------------
procedure TSQLMemSQLProcessor.ExecuteQuery;
begin
  OpenQuery;
end;//ExecuteQuery


//------------------------------------------------------------------------------
// PrepareStatement
//------------------------------------------------------------------------------
procedure TSQLMemSQLProcessor.PrepareStatement(SQLText: PWideChar);
begin
  FSqlText := SQLText;
end;//PrepareStatement


//------------------------------------------------------------------------------
// update parameters
//------------------------------------------------------------------------------
procedure TSQLMemSQLProcessor.UpdateParams;
begin
  FParamsChanged := True;
end; // UpdateParams


//------------------------------------------------------------------------------
// internal method, used in TSQLMemServerSession for copying disk/memory table
// returned by SELECT INTO to temporary
// can be use later
//------------------------------------------------------------------------------
function SQLMemCopyCursors(
            SourceCursor:       TSQLMemCursor;
            DestinationCursor:  TSQLMemCursor
            ): WideString;
var i,j:              Integer;
    SourceFields:     TSQLMemIntegerArray;
    ResultFields:     TSQLMemIntegerArray;
    Buf1,Buf2:        PAnsiChar;
    OldBuf1,OldBuf2:  PAnsiChar;
    value:            TSQLMemVariant;
begin
  Result := '';
  if (SourceCursor = nil)  then
   raise ESQLMemException.Create(11671,ErrorLNilPointer);
  if (DestinationCursor = nil)  then
   raise ESQLMemException.Create(11672,ErrorLNilPointer);
  if (not SourceCursor.IsOpen) then
   Result := ErrorLCannotCopyCursors + Format(ErrorLCopyCursorsSourceNotOpened,[
               SourceCursor.TableName,
               BoolToStr(SourceCursor.IsMemoryTable,true),
               BoolToStr(SourceCursor.IsTemporaryTable,true)])
  else
  if (not SourceCursor.IsOpen) then
   Result := ErrorLCannotCopyCursors + Format(ErrorLCopyCursorsDestNotOpened,[
               SourceCursor.TableName,
               BoolToStr(SourceCursor.IsMemoryTable,true),
               BoolToStr(SourceCursor.IsTemporaryTable,true)])
  else
   begin
    SourceFields := TSQLMemIntegerArray.Create(0,1,SourceCursor.VisibleFieldDefs.Count);
    ResultFields := TSQLMemIntegerArray.Create(0,1,SourceCursor.VisibleFieldDefs.Count);
    value := TSQLMemVariant.Create;
    try
      for i := 0 to SourceCursor.VisibleFieldDefs.Count-1 do
       begin
        j := DestinationCursor.VisibleFieldDefs.GetDefNumberByName(SourceCursor.VisibleFieldDefs.Items[i].Name);
        if (j >= 0) then
         begin
           SourceFields.Append(i);
           ResultFields.Append(j);
         end;
       end;
      OldBuf1 := SourceCursor.CurrentRecordBuffer;
      OldBuf2 := SourceCursor.CurrentRecordBuffer;
      Buf1 := SourceCursor.AllocateRecordBuffer;
      Buf2 := DestinationCursor.AllocateRecordBuffer;
      try
        SourceCursor.CurrentRecordBuffer := Buf1;
        DestinationCursor.CurrentRecordBuffer := Buf2;
        SourceCursor.InternalFirst;
        while (SourceCursor.GetRecordBuffer(grmNext) = grrOK) do
         begin
          // copy field values
          DestinationCursor.InternalInitRecord(Buf2,True);
          for i := 0 to SourceFields.ItemCount-1 do
           begin
            value.SetNull;
            try
              SourceCursor.GetFieldValue(value,i,false,false);
              DestinationCursor.SetFieldValue(value,ResultFields.Items[i],false,Buf2);
            except
            end;
           end;
          try
           DestinationCursor.InternalPost(True);
          except
           on E: Exception do
            begin
             Result := ErrorLCannotCopyCursors+e.Message;
             Exit;
            end;
          end;
         end;
      finally
        SourceCursor.FreeRecordBuffer(Buf1);
        DestinationCursor.FreeRecordBuffer(Buf2);
        SourceCursor.CurrentRecordBuffer := OldBuf1;
        DestinationCursor.CurrentRecordBuffer := OldBuf2;
      end;
    finally
      SourceFields.Free;
      ResultFields.Free;
      value.Free;
    end;
   end;
end; // SQLMemCopyCursors


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemBase> initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.

