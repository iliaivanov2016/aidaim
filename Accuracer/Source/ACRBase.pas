unit ACRBase;

interface

uses SysUtils, Classes, Db,

// Accuracer units
{$I ACRVer.inc}

     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}
{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}   
     ACRCompression,
     ACRLexer,
     ACRTypes,
{$IFNDEF SQLMEMTABLE}
     ACRTypesNetwork,
{$ENDIF}
     ACRConverts,
     ACRTypesRoutines,
     ACRVariant,
     ACRExcept,
     ACRConst;

type
 // Events
 TACRFilterRecord = Pointer;


type

  TACRBaseSession = class;
  TACRCursor = class;
  TACRIndexDef = class;
  TACRFieldDef = class;

  TACRFieldDefs = class;
  TACRIndexDefs = class;

  TACRCursorPos = record
   FirstPosition: Boolean;
   LastPosition:  Boolean;
   RecordID:      TACRRecordID;
  end;
  PACRCursorPos = ^TACRCursorPos;

  TACRSQLDatabaseParams = packed record
   Session:          TACRBaseSession; // nil or default local session - TACRLocalSession from TACRQuery
   ParamsSet:        Boolean;
   DatabaseName:     AnsiString;
   SessionName:      AnsiString;
   InMemory:         Boolean;
   RequestLive:      Boolean;
   Params:           TParams;
   CaseInsensitive:  Boolean; // added in v.5.90
  end; // TACRSQLDatabaseParams


////////////////////////////////////////////////////////////////////////////////
//
// TACRMetaObjectDef
//
////////////////////////////////////////////////////////////////////////////////


  TACRMetaObjectDef = class (TObject)
   private
    FName:       TACRObjectName;
    FObjectID:   TACRObjectID;
    FNameCRC:    Cardinal;
   protected
    procedure SetName(NewName: TACRObjectName);
   public
    constructor Create;
    procedure Assign(Source: TACRMetaObjectDef); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
   public
    property Name: TACRObjectName read FName write SetName;
    property ObjectID: TACRObjectID read FObjectID write FObjectID;
    property NameCRC: Cardinal read FNameCRC;
  end; // TACRMetaObjectDef


////////////////////////////////////////////////////////////////////////////////
//
// TACRSequenceDef
//
////////////////////////////////////////////////////////////////////////////////


  TACRSequenceDef = class (TACRMetaObjectDef)
   private
    FDataType:  TACRBaseFieldType;
    FMinValue:  TACRSequenceValue;
    FMaxValue:  TACRSequenceValue;
    FLastValue: TACRSequenceValue;
    FIncrement: TACRSequenceValue;
    FCycled:    Boolean;
   public
    // constructor
    constructor Create;
    // Assign data from an another sequence
    procedure   Assign(Source: TACRMetaObjectDef); override;
    // GetNextVal
    function GetNextVal: TACRSequenceValue; virtual;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
     property DataType:  TACRBaseFieldType read FDataType  write FDataType;
     property MinValue:  TACRSequenceValue read FMinValue  write FMinValue;
     property MaxValue:  TACRSequenceValue read FMaxValue  write FMaxValue;
     property LastValue: TACRSequenceValue read FLastValue write FLastValue;
     property Increment: TACRSequenceValue read FIncrement write FIncrement;
     property Cycled:    Boolean           read FCycled    write FCycled;
  end; // TACRSequenceDef




////////////////////////////////////////////////////////////////////////////////
//
// TACRFieldDef
//
////////////////////////////////////////////////////////////////////////////////


  TACRFieldDef = class (TACRMetaObjectDef)
   private
    FBaseFieldType:             TACRBaseFieldType;
    FAdvancedFieldType:         TACRAdvancedFieldType;
    FFieldSize:                 Integer;
    FDiskDataSize:              Integer; // size of binary data in disk page or table file
    FMemoryDataSize:            Integer; // size of binary data in record buffer
    FDiskOffset:                Integer; // offset to binary data in disk page or table file
    FMemoryOffset:              Integer; // offset to binary data in record buffer
    FFieldNoReference:          Integer; // index of this field in TableData.FieldManager.FieldDefs

    // Default Value
    FSequenceDefObjectId:       TACRObjectID;
    FDefaultValue:              TACRVariant;

    // Blob data
    FBLOBCompressionAlgorithm:  TACRCompressionAlgorithm;
    FBLOBCompressionMode:       TACRCompressionMode;
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
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure SetFieldDefDataType(
                                  AdvancedFieldType: TACRAdvancedFieldType;
                                  FieldSize:        Integer = 0
                                 ); overload;
    procedure SetFieldDefDataType(
                                  BaseFieldType: TACRBaseFieldType;
                                  FieldSize:        Integer = 0
                                 ); overload;

    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;

   public
    property BaseFieldType: TACRBaseFieldType read FBaseFieldType write FBaseFieldType;
    property AdvancedFieldType: TACRAdvancedFieldType read FAdvancedFieldType write FAdvancedFieldType;
    property FieldSize: Integer read FFieldSize write FFieldSize;
    property DiskOffset: Integer read FDiskOffset write FDiskOffset;
    property MemoryOffset: Integer read FMemoryOffset write FMemoryOffset;
    property DiskDataSize: Integer read FDiskDataSize write FDiskDataSize;
    property MemoryDataSize: Integer read FMemoryDataSize write FMemoryDataSize;
    property FieldNoReference: Integer read FFieldNoReference write FFieldNoReference;

    //property DefaultValueType: TACRDefaultValueType read FDefaultValueType write FDefaultValueType;
    property SequenceDefObjectId: TACRObjectID read FSequenceDefObjectId write FSequenceDefObjectId;
    property DefaultValue: TACRVariant read FDefaultValue write FDefaultValue;

    property AutoincIncrement: Int64    read FAutoincIncrement  write   FAutoincIncrement;
    property AutoincInitialValue: Int64 read FAutoincInitialValue write FAutoincInitialValue;
    property AutoincMinValue:  Int64    read FAutoincMinValue   write   FAutoincMinValue;
    property AutoincMaxValue:  Int64    read FAutoincMaxValue   write   FAutoincMaxValue;
    property AutoincCycled:    ByteBool read FAutoincCycled     write   FAutoincCycled;

    property BLOBCompressionAlgorithm: TACRCompressionAlgorithm read FBLOBCompressionAlgorithm write FBLOBCompressionAlgorithm;
    property BLOBCompressionMode: TACRCompressionMode read FBLOBCompressionMode write FBLOBCompressionMode;
    property BLOBBlockSize: Integer read FBLOBBlockSize write FBLOBBlockSize;

    property EngineVersion: Double read FEngineVersion write FEngineVersion;
  end; // TACRFieldDef


////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexDef
//
////////////////////////////////////////////////////////////////////////////////


  TACRIndexType = (itBTree,itAnotherOne);

  TACRIndexColumn = class (TObject)
   private
    FFieldName:        TACRObjectName;
    FNameCRC:          Cardinal;
    FDescending:       ByteBool;
    FCaseInsensitive:  ByteBool;
   protected
    procedure SetName(NewName: TACRObjectName);
   public
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
   public
    property FieldName: TACRObjectName read FFieldName write FFieldName;
    property NameCRC: Cardinal read FNameCRC;
    property Descending: ByteBool read FDescending write FDescending;
    property CaseInsensitive: ByteBool read FCaseInsensitive write FCaseInsensitive;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexDef
//
////////////////////////////////////////////////////////////////////////////////

  TACRIndexDef = class (TACRMetaObjectDef)
   private
    FIndexType:           TACRIndexType; // BTree or other
    FIndexColumns:        array of TACRIndexColumn;
    FUnique:              ByteBool;
    FPrimary:             ByteBool;
    FRootPageNo:          TACRPageNo;
    FTemporary:           ByteBool;

    function GetIndexColumn(Index: Integer): TACRIndexColumn;
    function GetColumnCount: Integer;
    procedure SetColumnCount(Value: Integer);
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure AssignByNames(FieldNames, AscDescList, CaseSensitivityList: TStringList);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    // return -1 if field was not found, otherwise return column index
    function FindField(FieldName: WideString): Integer;
   public
    property IndexType: TACRIndexType read FIndexType write FIndexType;
    property Columns[Index: Integer]: TACRIndexColumn read GetIndexColumn;
    property ColumnCount: Integer read GetColumnCount write SetColumnCount;
    property Unique: ByteBool read FUnique write FUnique;
    property Primary: ByteBool read FPrimary write FPrimary;
    property RootPageNo: TACRPageNo read FRootPageNo write FRootPageNo;
    property Temporary: ByteBool read FTemporary write FTemporary;
  end; // TACRIndexDef


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDef
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintType = (ctPK, ctFK, ctUnique, ctNotNull, ctCheck, ctFKAction);
  TACRConstraintDef = class (TACRMetaObjectDef)
   private
    FConstraintType:  TACRConstraintType;
   public
    procedure Assign(Source: TACRMetaObjectDef); override;
   public
    property ConstraintType: TACRConstraintType read FConstraintType write FConstraintType;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefNotNull
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintDefNotNull = class (TACRConstraintDef)
   private
    FColumnName:               TACRObjectName;  // Column
    FColumnObjectID:           TACRObjectID;
   public
    constructor Create;
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure SetNames(ColumnName: WideString);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property ColumnName: TACRObjectName read FColumnName write FColumnName;
    property ColumnObjectID: TACRObjectID read FColumnObjectID write FColumnObjectID;
  end;// TACRConstraintDefNotNull


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefCheck
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintDefCheck = class (TACRConstraintDef)
   private
    FColumnName:          TACRObjectName;  // Column
    FColumnObjectID:      TACRObjectID;
    FMinValue:            TACRVariant;
    FMaxValue:            TACRVariant;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure SetNames(ColumnName: WideString);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property MinValue: TACRVariant read FMinValue;
    property MaxValue: TACRVariant read FMaxValue;
    property ColumnName: TACRObjectName read FColumnName write FColumnName;
    property ColumnObjectID: TACRObjectID read FColumnObjectID write FColumnObjectID;
  end;//TACRConstraintDefCheck


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefUnique
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintColumn = record
    ColumnName:          TACRObjectName;  // Column
    ColumnObjectID:      TACRObjectID;
  end;


  TACRConstraintDefUnique = class (TACRConstraintDef)
   private
    FIndexName:                TACRObjectName;  // Index ID
    FIndexObjectID:            TACRObjectID;
   public
    Columns: array of TACRConstraintColumn; // Columns
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property IndexName: TACRObjectName read FIndexName write FIndexName;
    property IndexObjectID: TACRObjectID read FIndexObjectID write FIndexObjectID;
  end;//TACRConstraintDefUnique


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefPrimary
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintDefPrimary = class (TACRConstraintDefUnique)
   public
    constructor Create;
  end;//TACRConstraintDefPrimary


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefForeignKeyAction
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintForeignKeyMatchType = (cfkmtDefault,cfkmtFull,cfkmtPartial);
  TACRConstraintForeignKeyAction = (cfkaDefault, cfkaCascade,cfkaSetNull,cfkaSetDefault,cfkaNoAction);

  // FKAction is an action of master table on update or/and on delete for FK in detail table
  TACRConstraintDefForeignKeyAction = class (TACRConstraintDef)
   private
    FReferencedTableName:         TACRObjectName;  // Referenced Table
    FReferencedTableObjectID:     TACRObjectID;
    FReferencedFKName:            TACRObjectName;  // Referenced FK
    FReferencedFKObjectID:        TACRObjectID;
    FDeleteAction:                TACRConstraintForeignKeyAction;
    FUpdateAction:                TACRConstraintForeignKeyAction;
    FMatchType:                   TACRConstraintForeignKeyMatchType;
   public
    Columns: array of TACRConstraintColumn; // Columns in detail table for Set Null, SetDefault, Cascade
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
   public
    property ReferencedTableName: TACRObjectName read FReferencedTableName write FReferencedTableName;
    property ReferencedTableObjectID: TACRObjectID read FReferencedTableObjectID write FReferencedTableObjectID;
    property ReferencedFKName: TACRObjectName read FReferencedFKName write FReferencedFKName;
    property ReferencedFKObjectID: TACRObjectID read FReferencedFKObjectID write FReferencedFKObjectID;
    property DeleteAction: TACRConstraintForeignKeyAction read FDeleteAction write FDeleteAction;
    property UpdateAction: TACRConstraintForeignKeyAction read FUpdateAction write FUpdateAction;
    property MatchType: TACRConstraintForeignKeyMatchType read FMatchType write FMatchType;
  end;//TACRConstraintDefForeignKeyAction


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefForeignKey
//
////////////////////////////////////////////////////////////////////////////////


  TACRConstraintDefForeignKey = class (TACRConstraintDefForeignKeyAction)
   public
    constructor Create;
  end;//TACRConstraintDefForeignKey


////////////////////////////////////////////////////////////////////////////////
//
// TACRViewDef
//
////////////////////////////////////////////////////////////////////////////////


  TACRViewDef = class (TACRMetaObjectDef)
   private
    FSelectStatement:     WideString;
    FComment:             WideString;
    FWithCheckOption:     Boolean;
    FChildrenCRC:         TACRIntegerArray;     // CRC32 of UpperCase view / table names
    FChildrenNames:       TACRObjectNameArray;
    FColumnNames:         TACRObjectNameArray;
    FCreationDate:        TDateTime;
   public
    constructor Create; overload;
    constructor Create(
                       aName:             WideString;
                       aSelectStatement:  WideString;
                       aChildrenNames:    TACRWideStringList;
                       aColumnNames:      TACRWideStringList = nil;
                       aCheckOption:      Boolean = False;
                       aComment:          WideString = ''
                      ); overload;
    destructor Destroy; override;
    procedure Assign(Source: TACRMetaObjectDef); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    // return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
    function FindChild(crc: Cardinal): Boolean;
   public
    property Comment: WideString read FComment write FComment;
    property SelectStatement: WideString read FSelectStatement write FSelectStatement;
    property WithCheckOption: Boolean read FWithCheckOption write FWithCheckOption;
    property ChildrenNames: TACRObjectNameArray read FChildrenNames;
    property ColumnNames: TACRObjectNameArray read FColumnNames;
    property CreationDate: TDateTime read FCreationDate write FCreationDate;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// Meta Objects Defs
//
////////////////////////////////////////////////////////////////////////////////

 TACRMetaObjectDefs = class(TObject)
  protected
   FDefsList:         TACRSortedStringPtrArray;
   FLoadedItemCount:  Integer;
  private
   function GetCount: Integer; virtual;
   function GetDef(Index: Integer): TACRMetaObjectDef;
   procedure SetDef(Index: Integer; Value: TACRMetaObjectDef);

   function InternalAddCreated: TACRMetaObjectDef; virtual;
  public
   procedure LoadFromStream(Stream: TStream); virtual;
   procedure SaveToStream(Stream: TStream); virtual;

   constructor Create;
   destructor Destroy; override;
   procedure Assign(Source: TACRMetaObjectDefs); virtual;

   procedure Add(MetaObjectDef: TACRMetaObjectDef); virtual;
   procedure Delete(Index: Integer); virtual;
   procedure Insert(Index: Integer; MetaObjectDef: TACRMetaObjectDef); virtual;
   procedure Move(CurIndex, NewIndex: Integer); virtual;
   procedure Clear; virtual;

   function GetDefNumberByName(Name: WideString): Integer;
   function GetDefNumberByCRC(CRC: Cardinal): Integer;
   function GetDefByName(Name: WideString): TACRMetaObjectDef;
   function GetDefNumberByObjectId(id: TACRObjectID): Integer;
   function GetDefByObjectId(id: TACRObjectID): TACRMetaObjectDef;
  public
   property Count: Integer read GetCount;
   property Items[Index: Integer]: TACRMetaObjectDef read GetDef write SetDef; default;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexDefs
//
////////////////////////////////////////////////////////////////////////////////


 TACRIndexDefs = class(TACRMetaObjectDefs)
  private
   function GetIndexDef(Index: Integer): TACRIndexDef; virtual;
   procedure SetIndexDef(Index: Integer; Value: TACRIndexDef); virtual;
   function InternalAddCreated: TACRMetaObjectDef; override;
  public
   // AscDesc and CaseSensitivity lists should contain constants ACR_ASC, ACR_DESC, ACR_NO_CASE, ACR_CASE
   function IsIndexExists(FieldNames, AscDescList, CaseSensitivityList: TACRWideStringList): Boolean;
   function FindIndex(FieldNames, AscDescList, CaseSensitivityList: TACRWideStringList): TACRObjectID;
   function FindPrimaryIndex: TACRIndexDef;
   function AddCreated: TACRIndexDef;
   function GetIndexDefByName(Name: WideString): TACRIndexDef;
   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
  public
   property Items[Index: Integer]: TACRIndexDef read GetIndexDef write SetIndexDef; default;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRFieldDefs
//
////////////////////////////////////////////////////////////////////////////////


 TACRFieldDefs = class(TACRMetaObjectDefs)
  private
   FVarcharOrBLOBFieldsExists: Boolean;
   FAutoIncFieldsExists:       Boolean;
   FDefaultValuesExists:       Boolean;
   FEngineVersion:             Double;

   function GetDef(Index: Integer): TACRFieldDef;
   procedure SetDef(Index: Integer; Value: TACRFieldDef);
   function InternalAddCreated: TACRMetaObjectDef; override;
  public
   function AddCreated: TACRFieldDef;
   function GetFieldDefByName(Name: WideString): TACRFieldDef;

   procedure RecalcFieldOffsets;
   function GetMemoryRecordBufferSize: Integer;

   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
   // Set default values to fields
   procedure ApplyDefaultValuesToRecordBuffer(
                                RecordBuffer: TACRRecordBuffer
                                );
  public
   property Items[Index: Integer]: TACRFieldDef read GetDef write SetDef; default;
   property VarcharOrBLOBFieldsExists: Boolean read FVarcharOrBLOBFieldsExists;
   property AutoIncFieldsExists: Boolean read FAutoIncFieldsExists;
   property DefaultValuesExists: Boolean read FDefaultValuesExists;
   property EngineVersion: Double read FEngineVersion write FEngineVersion;
 end;//TACRFieldDefs


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefs
//
////////////////////////////////////////////////////////////////////////////////

 TACRConstraintDefs = class(TACRMetaObjectDefs)
  private
   FForeignKeysExists: Boolean;
   FForeignKeysActionsExists: Boolean;
  private
   function GetDef(Index: Integer): TACRConstraintDef;
   procedure SetDef(Index: Integer; Value: TACRConstraintDef);
   function GetForeignKeysActionsUpdateExists: Boolean;
   function GetForeignKeysActionsDeleteExists: Boolean;
  public
   constructor Create;
   procedure Assign(Source: TACRMetaObjectDefs); override;
   procedure Delete(Index: Integer); override;
   // Create TACRConstraintDefNotNull and add it into list
   function AddNotNull: TACRConstraintDefNotNull;
   // Create TACRConstraintDefCheck and add it into list
   function AddCheck: TACRConstraintDefCheck;
   function AddPK: TACRConstraintDefPrimary;
   function AddUnique: TACRConstraintDefUnique;
   function AddFK: TACRConstraintDefForeignKey;
   function AddFKAction: TACRConstraintDefForeignKeyAction;

   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
   procedure ExtractForeignKeys(Dest: TACRConstraintDefs);
  public
   property Items[Index: Integer]: TACRConstraintDef read GetDef write SetDef; default;
   property ForeignKeysExists: Boolean read FForeignKeysExists write FForeignKeysExists;
   property ForeignKeysActionsExists: Boolean read FForeignKeysActionsExists  write FForeignKeysActionsExists;
   property ForeignKeysActionsUpdateExists: Boolean read GetForeignKeysActionsUpdateExists;
   property ForeignKeysActionsDeleteExists: Boolean read GetForeignKeysActionsDeleteExists;
 end;//TACRConstraintDefs



////////////////////////////////////////////////////////////////////////////////
//
// TACRSequenceDefs
//
////////////////////////////////////////////////////////////////////////////////

 TACRSequenceDefs = class(TACRMetaObjectDefs)
  private
   function GetDef(Index: Integer): TACRSequenceDef;
   procedure SetDef(Index: Integer; Value: TACRSequenceDef);
   function InternalAddCreated: TACRMetaObjectDef; override;
  public
   function AddCreated: TACRSequenceDef;
   function GetSequenceDefByName(Name: WideString): TACRSequenceDef;
  public
   property Items[Index: Integer]: TACRSequenceDef read GetDef write SetDef; default;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRViewDefs
//
////////////////////////////////////////////////////////////////////////////////

 TACRViewDefs = class(TACRMetaObjectDefs)
  private
   function InternalAddCreated: TACRMetaObjectDef; override;
  public
   procedure LoadFromStream(Stream: TStream); override;
   procedure SaveToStream(Stream: TStream); override;
   // return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
   function FindChildren(Name: WideString): Boolean;
   // delete all views that references view or table with specified name - for DROP [TABLE | VIEW] with CASCADE
   procedure DeleteChildren(Name: WideString);
 end; // TACRViewDefs


 TACRRestructureInfo = record
    FRestructureBLOBCompression:   TACRCompression;
    FRestructureFieldDefs:         TACRFieldDefs;
    FRestructureIndexDefs:         TACRIndexDefs;
    FRestructureConstraintDefs:    TACRConstraintDefs;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRCursor
//
////////////////////////////////////////////////////////////////////////////////


  TACRCursor = class (TObject)
   public
    FMemoryTableAllocBy:            Integer;
    FSettingProjection:             Boolean;
    FIsProjectionSet:               Boolean;
    FComment:                       WideString;
    FTableName:                     WideString;
    FIndexName:                     WideString;
    FIndexID:                       TACRObjectID;
    FReadOnly:                      Boolean;
    FExclusive:                     Boolean;
    FInMemory:                      Boolean;
    FTemporary:                     Boolean;
    FSession:                       TACRBaseSession;
    FIsOpen:                        Boolean;
    FPhysicalOrder:                 Boolean;
    FCurrentRecordPositionInIndex:  TACRIndexPosition;
    // temp record buffer - used by TACRTableData.ShowRecord -
    // show record after insert / update filtered cursor
    FTempRecordBuffer:              TACRRecordBuffer;
    // current record buffer
    FCurrentRecordBuffer:           TACRRecordBuffer;
    // buffer with original record, stored on InternalEdit by TACRDataset
    FEditRecordBuffer:              TACRRecordBuffer;
    FConstraintDefs:                TACRConstraintDefs;
    FBLOBCompression:               TACRCompression;
    FFieldDefs:                     TACRFieldDefs;
    FVisibleFieldDefs:              TACRFieldDefs; // visible fields (projection)
    FIndexDefs:                     TACRIndexDefs;
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
    // | Null Flags | Field Values,      | TACRKeyBuffer |
    // |            | References To BLOB |               |
    // +------------+--------------------+---------------+

    FErrorCode:                     TACRErrorCode;
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
    FKeyBuffer:                     TACRRecordBuffer;
    FRangeStartBuffer:              TACRRecordBuffer;
    FRangeEndBuffer:                TACRRecordBuffer;
    FRangeStartExclusive:           Boolean;
    FRangeEndExclusive:             Boolean;
    FRangeStartKeyFieldCount:       Integer;
    FRangeEndKeyFieldCount:         Integer;
    FRepair:                        Boolean;
//    FDeleteCurrentRecordID:         TACRRecordID;
   protected
    procedure SetIndexName(Value: WideString);
    // added in v.5.90
    procedure SetCaseInsensitive(Value: Boolean); virtual;
{$IFDEF DEBUG_LOG}
   public
    procedure WriteRecordBufferToLog(Buffer: TACRRecordBuffer);
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
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                         ); virtual; abstract;
    procedure DeleteTable(Cascade: Boolean = False); virtual; abstract;
    procedure EmptyTable; virtual; abstract;
    procedure RenameTable(NewTableName: WideString); virtual; abstract;
    procedure RenameField(FieldName, NewFieldName: WideString); virtual;
    function RepairTable(
                      var Log:            AnsiString;
                      NewSession:         Pointer = nil;
                      ConstraintDefs:     TACRConstraintDefs = nil
                      ): Boolean; virtual; abstract;
    procedure AddForeignKey(ConstraintDef: TACRConstraintDefForeignKey); virtual; abstract;
    procedure DeleteConstraint(Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean); virtual; abstract;
    procedure LoadTableFromStream(
                        Stream:               TStream
                       ); virtual; abstract;
    procedure SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TACRCompressionAlgorithm = acaNone;
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
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                       ); virtual; abstract;
    procedure UpdateTableDefinitions; virtual;
    procedure CloseTable; virtual; abstract;
    // initialize record buffer
    procedure InternalInitRecord(RecordBuffer: TACRRecordBuffer; InsertMode: Boolean); virtual;

    // index operations
    function GetIndexDefs: TACRIndexDefs; virtual;
    procedure ReceiveFieldNoReferences(Stream: TStream);

    procedure AddIndex(IndexDef: TACRIndexDef); virtual; abstract;
    procedure DeleteIndex(Name: WideString); virtual; abstract;
    procedure DeleteAllIndexes; virtual; abstract;
    // return index name of the index or '' if not found
    function FindIndex(FieldNamesList,
                AscDescList, CaseSensitivityList: TACRWideStringList): WideString; virtual; abstract;

    // check field value and if not null move data from RecordBuffer to Buffer
    function GetFieldData(
                          FieldNo:      Integer; // field no
                          Buffer:       Pointer; // buffer
                          RecordBuffer: TACRRecordBuffer // record buffer
                         ): Boolean;
    // set field data from Buffer to RecordBuffer
    procedure SetFieldData(
                            FieldNo:       Integer;
                            Buffer:        Pointer;
                            RecordBuffer:  TACRRecordBuffer // record buffer
                          );
    procedure GetBLOBValue(V: TACRVariant; aFieldNo: Integer);
    procedure GetFieldValue(Value: TACRVariant; FieldNo: Integer; DirectAccess: Boolean; CopyFlag: Boolean = True);
    procedure SetFieldValue(
                            Value:        TACRVariant;
                            FieldNo:      Integer;
                            DirectAccess: Boolean;
                            RecordBuffer: TACRRecordBuffer = nil
                           );
    // allocate record buffer and set null flags
    function AllocateRecordBuffer: TACRRecordBuffer;
    // free record buffer
    procedure FreeRecordBuffer(var Buffer: TACRRecordBuffer);
    // allocate record buffer and set null flags
    function AllocateKeyRecordBuffer: TACRRecordBuffer;
    // initialize record buffer
    procedure InternalInitKeyBuffer(RecordBuffer: TACRRecordBuffer);
    function IsTemporaryTable: Boolean; virtual; abstract;
    function IsMemoryTable: Boolean; virtual; abstract;


    //---------------------------------------------------------------------------
    // navigation & bookmark methods
    //---------------------------------------------------------------------------

    // return true if current record exists
    function IsRecordExists: Boolean; virtual; abstract;
    function GetRecordCount: TACRRecordNo; virtual; abstract;
    // get record
    function GetRecordBuffer(
              GetRecordMode:  TACRGetRecordMode
              ): TACRGetRecordResult; virtual; abstract;
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
    // added in v.5.30 - moved from TACRMain.GetRecord
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
    procedure UpdateVisibleRecords(FieldNames:   TACRWideStringList;
                                   values:       array of TACRVariant;
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
    procedure ApplyProjection(FieldNamesList, AliasList: TACRWideStringList); virtual; abstract;
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
    function FindKey(SearchCondition: TACRSearchCondition): Boolean; virtual; abstract;
    function IsIndexApplied: Boolean;
    function IsFilterApplied: Boolean;
    function IsRangeApplied: Boolean;
    function IsViewRestricted: Boolean;
    // update index definitions in dataset
    procedure UpdateIndexDefinitions;

    procedure ResetRange; virtual; abstract;
    procedure ApplyRange(
                          StartBuffer, EndBuffer: TACRRecordBuffer;
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
              OpenMode: TACRBLOBOpenMode
              ):TACRStream; virtual; abstract;

    procedure InternalCloseBLOB(FieldNo: Integer); virtual; abstract;

    // clear blob streams
    procedure ClearBLOBStreams(WriteOnly: Boolean = False); virtual; abstract;

    function LastAutoincValue(FieldNo: Integer): Int64; virtual; abstract;
    procedure SetLastAutoincValue(Value: Int64; FieldNo: Integer); virtual; abstract;
   public
    function GetTableState: TACRTableState; virtual; abstract;
    procedure LockTable(bWriteMode: Boolean); virtual; abstract;
    procedure UnlockTable(bWriteMode: Boolean); virtual; abstract;
   public
    // Destroy should call DatabaseData.FreeTableData
    // for bookmarks
    CurrentRecordID:               TACRRecordID;
    // position for navigation
    FirstPosition:                 Boolean;
    LastPosition:                  Boolean;
    FilterRecord:                  TACRFilterRecord;
    Dataset:                       Pointer;

    property RandomOrder: Boolean read FRandomOrder write FRandomOrder;
    property RecordBitmap: Pointer read FRecordBitmap write FRecordBitmap;
    property FilterExpression: Pointer read FFilterExpression write FFilterExpression;
    property SQLFilterExpression: Pointer read FSQLFilterExpression write FSQLFilterExpression;
    property BLOBStreams: TList read FBLOBStreams;
    property ErrorCode: TACRErrorCode read FErrorCode write FErrorCode;
    property ErrorMessage: WideString read FErrorMessage write FErrorMessage;
    property IsDesignMode: Boolean read FIsDesignMode write FIsDesignMode;
    property TableName: WideString read FTableName write FTableName;
    property IndexName: WideString read FIndexName write SetIndexName;
    property IndexID: TACRObjectID read FIndexID write FIndexID;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Exclusive: Boolean read FExclusive write FExclusive;
    property InMemory: Boolean read FInMemory write FInMemory;
    property MemoryTableAllocBy: Integer read FMemoryTableAllocBy write FMemoryTableAllocBy;
    property Temporary: Boolean read FTemporary write FTemporary;
    property Session: TACRBaseSession read FSession write FSession;
    property IsOpen: Boolean read FIsOpen write FIsOpen;
    property RecordCount: Int64 read GetRecordCount;
    property FieldDefs: TACRFieldDefs read FFieldDefs;
    property VisibleFieldDefs: TACRFieldDefs read FVisibleFieldDefs;
    property IndexDefs: TACRIndexDefs read GetIndexDefs;
    property ConstraintDefs: TACRConstraintDefs read FConstraintDefs;
    // set it before call CreateTable
    property BLOBCompression: TACRCompression read FBLOBCompression
             write FBLOBCompression;
    property KeyFieldCount: Integer read FKeyFieldCount write FKeyFieldCount;
    property KeyBuffer: TACRRecordBuffer read FKeyBuffer write FKeyBuffer;
    property RangeStartBuffer: TACRRecordBuffer read FRangeStartBuffer
             write FRangeStartBuffer;
    property RangeEndBuffer:   TACRRecordBuffer read FRangeEndBuffer
             write FRangeEndBuffer;
    property RangeStartExclusive: Boolean read FRangeStartExclusive
             write FRangeStartExclusive;
    property RangeEndExclusive: Boolean read FRangeEndExclusive
             write FRangeEndExclusive;
    property RangeStartKeyFieldCount: Integer read FRangeStartKeyFieldCount
             write FRangeStartKeyFieldCount;
    property RangeEndKeyFieldCount: Integer read FRangeEndKeyFieldCount
             write FRangeEndKeyFieldCount;
    property CurrentRecordBuffer: TACRRecordBuffer read FCurrentRecordBuffer
              write FCurrentRecordBuffer;
    property EditRecordBuffer: TACRRecordBuffer read FEditRecordBuffer
              write FEditRecordBuffer;
    property PhysicalOrder: Boolean read FPhysicalOrder write FPhysicalOrder;
    property CurrentRecordPositionInIndex: TACRIndexPosition
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
end; // TACRCursor



////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseSession
//
////////////////////////////////////////////////////////////////////////////////

  // manager for TACRSession
  TACRSessionComponentManager = class(TObject)
  end;

  // Session object base class
  TACRSessionNamedObject = class(TObject)
   private
    FName: WideString;
   public
    constructor Create(Name: WideString);
   public
    property Name: WideString read FName write FName;
  end;

  // Sequence last value stored in user session
  TACRSessionNamedObjectSequenceValue = class(TACRSessionNamedObject)
   public
    FValue: TACRSequenceValue;
   public
    constructor Create(ValueName: WideString; Value: TACRSequenceValue);
   public
    property Value: TACRSequenceValue read FValue write FValue;
  end;

  // for database component
  TACRBaseSession = class (TObject)
   private
    FSessionHandle:           TACRSessionComponentManager;
    FSessionNamedObjectList:  TACRSortedStringPtrArray;
   protected
    FDatabaseName:            AnsiString; // name of database
    FSessionName:             AnsiString; // session name from TACRDatabase
    // if not empty - ANSI, else - Unicode
    FDatabaseFileName:        AnsiString;
    FDatabaseFileNameUnicode: WideString;
    FSessionID:               TACRSessionID;
    FReadOnly:                Boolean;
    FExclusive:               Boolean;
    FTemporary:               Boolean;
    FInMemory:                Boolean;
    FOptions:                 TACROptions;
    FLockParams:              TACRLockParams;
    FCryptoParams:            TACRCryptoParams;
    FSessionVariables:        TACRSQLParams;
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
    FConnectParams:           TACRConnectParams;
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
    procedure GetTablesList(List: TACRWideStringList); virtual; abstract;
    function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray; virtual; abstract;
    function GetTableState(TableName: WideString): TACRTableState; virtual; abstract;
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
                    CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
                  ); virtual; abstract;
    // makes Exe database from edb file
    procedure MakeExeDatabase(ExeFileName, ExeDatabaseFileName: WideString); virtual; abstract;
    // removes database file from executable database file
    procedure RemoveDatabaseFromExe; virtual; abstract;
    // returns true if this file is an Accuracer database
    function IsAccuracerDatabaseFile: Boolean; virtual; abstract;

    //------------- session variables and sequence values ----------------------
    // Get Named object from session
    function GetNamedObject(ObjectName: WideString): TACRSessionNamedObject;
    // Set Named object to session
    procedure SetSequenceValue(const Name: TACRObjectName; const Value: TACRSequenceValue);

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
    procedure SetDatabaseParams(var DBParams: TACRSQLDatabaseParams);

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
                  Lexer:                TACRLexer;
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
    // params - list of TACRSQLParam
    function ExecuteStoredFunction(
                FunctionName:     WideString;
                ResultValue:      TACRVariant;
                Params:           TACRSQLParams = nil 
                ): Boolean; virtual; abstract;
    // return empty string if function not found; otherwise
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; virtual; abstract;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TACRExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString): TObject; virtual; abstract;
    // parse for execute
    // return stored function object (TACRStoredFunction) if found or nil
    // params - list of TACRExpression
    function ParseStoredFunctionParams(
                    lexer:          TACRLexer;
                    parentFunction: TObject; // parent TACRStoredFunction object, where parser was called 
                    var token:      TToken;
                    out Params:     TObject // TACRExpressions
                                      ): TObject; virtual; abstract;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload; virtual; abstract;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload;  virtual; abstract;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); virtual; abstract;
    //-------- STORED FUNCTIONS AND PROCEDURES - added in v.5.10 ---------------

    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         ViewName:          WideString;
                         SelectStatement:   WideString;
                         Columns:           TACRWideStringList = nil;
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
                     ): TACRViewDef; virtual; abstract;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    procedure CloseLocalSessionWithoutDatabase; virtual; abstract;
    // return cursor created for the specified table or view name
    function CreateCursor(TableName: WideString; bOpenView: Boolean = True): TACRCursor; virtual; abstract;
   public
    property Connected: Boolean read GetConnected write SetConnected default False;
    // if not empty - ANSI, else - Unicode
    property DatabaseFileName: AnsiString read FDatabaseFileName write FDatabaseFileName;
    property DatabaseFileNameUnicode: WideString read FDatabaseFileNameUnicode write FDatabaseFileNameUnicode;
    property DatabaseName: AnsiString read FDatabaseName write FDatabaseName;
    property SessionName: AnsiString read FSessionName write FSessionName;
    property SessionID: TACRSessionID read FSessionID write FSessionID;
    property InTransaction: Boolean read GetInTransaction;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Exclusive: Boolean read FExclusive write FExclusive;
    property InMemory: Boolean read FInMemory write FInMemory;
    property Temporary: Boolean read FTemporary write FTemporary;
    property SessionComponentManager: TACRSessionComponentManager
             read FSessionHandle write FSessionHandle;
    property LockParams: TACRLockParams read FLockParams write FLockParams;
    property Options: TACROptions read FOptions write FOptions;
    property CryptoParams: TACRCryptoParams read FCryptoParams write FCryptoParams;
{$IFNDEF SQLMEMTABLE}
    property ConnectParams: TACRConnectParams read FConnectParams write FConnectParams;
{$ENDIF}
    property SessionVariables: TACRSQLParams read FSessionVariables;
    property CaseInsensitive: Boolean read FCaseInsensitive write SetCaseInsensitive; // added in v.5.90
  end; // TACRBaseSession


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////


  TACRSQLProcessor = class (TObject)
   protected
    FACRQuery:        TDataSet;
    FReadOnly:        Boolean;
    FRequestLive:     Boolean;
    FInMemory:        Boolean;
    FRowsAffected:    TACRRecordNo;

    FSqlText:         WideString;
    FSQLParams:       TACRSQLParams;
    FCursor:          TACRCursor;
    FNeverOpened:     Boolean;
    FParamsHash:      TACRRecordHashValue;
    FParamsChanged:   Boolean;
    FCaseInsensitive: Boolean; // added in v.5.90
   public
    constructor Create; overload;
    constructor Create(Query: TDataSet); overload;
    destructor Destroy; override;

    function OpenQuery(TableNames: TACRWideStringList = nil): TACRCursor; virtual;
    procedure ExecuteQuery;

    procedure PrepareStatement(SQLText: PWideChar);
    procedure UpdateParams; virtual;

   public
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property RequestLive: Boolean read FRequestLive write FRequestLive;
    property InMemory: Boolean read FInMemory write FInMemory;
    property RowsAffected: TACRRecordNo read FRowsAffected;
    property SQLParams: TACRSQLParams read FSQLParams;
    property ACRQuery: TDataset read FACRQuery;
    property SQLText: WideString read FSQLText;
    property CaseInsensitive: Boolean read FCaseInsensitive write FCaseInsensitive; // added in v.5.90
  end; // TACRSQLProcessor


function ACRCopyCursors(
            SourceCursor:       TACRCursor;
            DestinationCursor:  TACRCursor
            ): WideString;

implementation

uses

// Accuracer units
     ACRMain,
     ACRExpressions,
     ACRBaseEngine,
     ACRMemory // last
;



////////////////////////////////////////////////////////////////////////////////
//
// TACRMetaObjectDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set name
//------------------------------------------------------------------------------
procedure TACRMetaObjectDef.SetName(NewName: TACRObjectName);
begin
  FName := NewName;
  FNameCRC := GetTableNameCRC(FName,True);
end; // SetName


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRMetaObjectDef.Create;
begin
  FName       := '';
  FObjectID   := OBJECTID_IS_NULL;
end;//Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRMetaObjectDef.Assign(Source: TACRMetaObjectDef);
begin
  SetName(Source.Name);
  FObjectID := Source.FObjectID;
end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRMetaObjectDef.LoadFromStream(Stream: TStream);
begin
  LoadWideStringFromStream(FName,Stream,10166);
  FNameCRC := GetTableNameCRC(FName,True);
  LoadDataFromStream(FObjectID,sizeof(ObjectID),Stream,10169);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRMetaObjectDef.SaveToStream(Stream: TStream);
begin
  SaveWideStringToStream(FName,Stream,10164);
  SaveDataToStream(FObjectID,sizeof(ObjectID),Stream,10168);
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TACRSequenceDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSequenceDef.Create;
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
procedure TACRSequenceDef.Assign(Source: TACRMetaObjectDef);
begin
  inherited Assign(Source);
  FDataType  := TACRSequenceDef(Source).FDataType;
  FMinValue  := TACRSequenceDef(Source).FMinValue;
  FMaxValue  := TACRSequenceDef(Source).FMaxValue;
  FLastValue := TACRSequenceDef(Source).FLastValue;
  FIncrement := TACRSequenceDef(Source).FIncrement;
  FCycled    := TACRSequenceDef(Source).FCycled;
end;//Assign


//------------------------------------------------------------------------------
// GetNextVal
//------------------------------------------------------------------------------
function TACRSequenceDef.GetNextVal: TACRSequenceValue;
begin
  FLastValue := FLastValue + FIncrement;
  if (FLastValue > FMaxValue) then
    if (FCycled) then
      FLastValue := FMinValue
    else
      raise EACRException.Create(30009, ErrorGSequenceOverflow, [FName]);
  Result := FLastValue;
end;//GetNextVal


//------------------------------------------------------------------------------
// load sequence
//------------------------------------------------------------------------------
procedure TACRSequenceDef.LoadFromStream(Stream: TStream);
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
procedure TACRSequenceDef.SaveToStream(Stream: TStream);
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
// TACRFieldDef
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRFieldDef.Create;
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
  FDefaultValue := TACRVariant.Create;

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
destructor TACRFieldDef.Destroy;
begin
  FDefaultValue.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// SetFieldDefData ( set Advanced Field Type )
//------------------------------------------------------------------------------
procedure TACRFieldDef.SetFieldDefDataType(AdvancedFieldType: TACRAdvancedFieldType;
                                           FieldSize: Integer);
begin
  FAdvancedFieldType := AdvancedFieldType;
  FBaseFieldType := AdvancedFieldTypeToBaseFieldType(AdvancedFieldType);
  if FBaseFieldType = bftUnknown then
   raise EACRException.Create(30007,ErrorGUnsupportedDataType,
                                    [AftToStr(AdvancedFieldType)]);
  FFieldSize := FieldSize;
  RecalcInternalSizes;
end;//SetFieldDefData


//------------------------------------------------------------------------------
// SetFieldDefData ( set Advanced Field Type )
//------------------------------------------------------------------------------
procedure TACRFieldDef.SetFieldDefDataType(BaseFieldType: TACRBaseFieldType;
                                           FieldSize: Integer);
begin
  FBaseFieldType := BaseFieldType;
  FFieldSize := FieldSize;

  FAdvancedFieldType := BaseFieldTypeToAdvancedFieldType(BaseFieldType);
  if FAdvancedFieldType = aftUnknown then
   raise EACRException.Create(30008,ErrorGUnsupportedDataType,
                                    [BftToStr(BaseFieldType)]);
  RecalcInternalSizes;
end;//SetFieldDefData



//------------------------------------------------------------------------------
// RecalcInternalSizes
//------------------------------------------------------------------------------
procedure TACRFieldDef.RecalcInternalSizes;
begin
  // FMemoryDataSize ...
  FMemoryDataSize := GetDataSizeInMemory(FBaseFieldType, FFieldSize);

  // FDiskDataSize ...
  FDiskDataSize := FMemoryDataSize;
  if (IsBLOBFieldType(FBaseFieldType) or (IsVarcharFieldType(FBaseFieldType))) then
    FDiskDataSize := SizeOf(TACRRecordID);
end;//RecalcInternalSizes



//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRFieldDef.Assign(Source: TACRMetaObjectDef);
var s: TACRFieldDef;
begin
  s := Source as TACRFieldDef;
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
procedure TACRFieldDef.LoadFromStream(Stream: TStream);
begin
  inherited LoadFromStream(Stream);

  LoadDataFromStream(FBaseFieldType,Sizeof(FBaseFieldType),Stream,10187);
  LoadDataFromStream(FAdvancedFieldType,Sizeof(FAdvancedFieldType),Stream,10188);
  LoadDataFromStream(FFieldSize,Sizeof(FFieldSize),Stream,10189);

  FDefaultValue.SetNull(FBaseFieldType);
  if (IsBlobFieldType(FBaseFieldType)
{$IFNDEF SQLMEMTABLE}
// v. 2.00 and 1.xx bug fix with not saving varchar compression in Accuracer
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
procedure TACRFieldDef.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);

  SaveDataToStream(FBaseFieldType,Sizeof(FBaseFieldType),Stream,10170);
  SaveDataToStream(FAdvancedFieldType,Sizeof(FAdvancedFieldType),Stream,10171);
  SaveDataToStream(FFieldSize,Sizeof(FFieldSize),Stream,10172);

  if (IsBlobFieldType(FBaseFieldType)
{$IFNDEF SQLMEMTABLE}
// v. 2.00 and 1.xx bug fix with not saving varchar compression in Accuracer
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
// TACRIndexColumn
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set name
//------------------------------------------------------------------------------
procedure TACRIndexColumn.SetName(NewName: TACRObjectName);
begin
  FFieldName := NewName;
  FNameCRC := GetTableNameCRC(NewName,True);
end; // SetName


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRIndexColumn.LoadFromStream(Stream: TStream);
begin
  LoadWideStringFromStream(FFieldName,Stream,10358);
  FNameCRC := GetTableNameCRC(FFieldName,True);
  LoadDataFromStream(FDescending,Sizeof(FDescending),Stream,10360);
  LoadDataFromStream(FCaseInsensitive,Sizeof(FCaseInsensitive),Stream,10361);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRIndexColumn.SaveToStream(Stream: TStream);
begin
  SaveWideStringToStream(FFieldName,Stream,10354);
  SaveDataToStream(FDescending,Sizeof(FDescending),Stream,10356);
  SaveDataToStream(FCaseInsensitive,Sizeof(FCaseInsensitive),Stream,10357);
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get index column
//------------------------------------------------------------------------------
function TACRIndexDef.GetIndexColumn(Index: Integer): TACRIndexColumn;
begin
  Result := FIndexColumns[Index];
end;// GetIndexColumn


//------------------------------------------------------------------------------
// get column count
//------------------------------------------------------------------------------
function TACRIndexDef.GetColumnCount: Integer;
begin
  Result := Length(FIndexColumns);
end;// GetColumnCount


//------------------------------------------------------------------------------
// set column count
//------------------------------------------------------------------------------
procedure TACRIndexDef.SetColumnCount(Value: Integer);
var
  oldCount, i: Integer;
begin
  oldCount := Length(FIndexColumns);
  if (Value > oldCount) then
   begin
     SetLength(FIndexColumns, Value);
     for i := oldCount to Value-1 do
      FIndexColumns[i] := TACRIndexColumn.Create;
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
constructor TACRIndexDef.Create;
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
destructor TACRIndexDef.Destroy;
begin
  ColumnCount := 0;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// assign another IndexDef
//------------------------------------------------------------------------------
procedure TACRIndexDef.Assign(Source: TACRMetaObjectDef);
var
  i: Integer;
begin
  inherited Assign(Source);
  IndexType := TACRIndexDef(Source).IndexType;
  Unique := TACRIndexDef(Source).Unique;
  Primary := TACRIndexDef(Source).Primary;
  FRootPageNo := TACRIndexDef(Source).RootPageNo;
  ColumnCount := TACRIndexDef(Source).ColumnCount;
  FTemporary := TACRIndexDef(Source).FTemporary;
  for i := 0 to ColumnCount-1 do
   begin
    Columns[i].FieldName := TACRIndexDef(Source).Columns[i].FieldName;
    Columns[i].Descending := TACRIndexDef(Source).Columns[i].Descending;
    Columns[i].CaseInsensitive := TACRIndexDef(Source).Columns[i].CaseInsensitive;
   end;
end;// Assign


//------------------------------------------------------------------------------
// assign by names
//------------------------------------------------------------------------------
procedure TACRIndexDef.AssignByNames(FieldNames, AscDescList, CaseSensitivityList: TStringList);
var i: integer;
begin
 if (FieldNames.Count <> AscDescList.Count) then
  raise EACRException.Create(10278,ErrorLDifferentListsLength,
    [FieldNames.Count,AscDescList.Count]);
 if (FieldNames.Count <> CaseSensitivityList.Count) then
  raise EACRException.Create(10279,ErrorLDifferentListsLength,
    [FieldNames.Count,CaseSensitivityList.Count]);
  ColumnCount := FieldNames.Count;
  for i := 0 to ColumnCount-1 do
   begin
    Columns[i].FieldName := FieldNames[i];
    Columns[i].Descending := (AscDescList[i] = ACR_DESC);
    Columns[i].CaseInsensitive := (CaseSensitivityList[i] = ACR_NO_CASE);
   end;
end;


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRIndexDef.LoadFromStream(Stream: TStream);
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
procedure TACRIndexDef.SaveToStream(Stream: TStream);
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
function TACRIndexDef.FindField(FieldName: WideString): Integer;
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
// TACRConstraintDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConstraintDef.Assign(Source: TACRMetaObjectDef);
begin
  inherited Assign(Source);
  FConstraintType := TACRConstraintDef(Source).FConstraintType;
end;//Assign



////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefNotNull
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRConstraintDefNotNull.Create;
begin
  FConstraintType := ctNotNull;
end;//Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConstraintDefNotNull.Assign(Source: TACRMetaObjectDef);
begin
  inherited Assign(Source);
  FColumnName := TACRConstraintDefNotNull(Source).FColumnName;
  FColumnObjectID := TACRConstraintDefNotNull(Source).FColumnObjectID;
end;//Assign

//------------------------------------------------------------------------------
// SetNames
//------------------------------------------------------------------------------
procedure TACRConstraintDefNotNull.SetNames(ColumnName: WideString);
begin
  FColumnName := ColumnName;
end;//SetNames



//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRConstraintDefNotNull.LoadFromStream(Stream: TStream);
begin
  inherited LoadFromStream(Stream);
  LoadDataFromStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10251);
  LoadWideStringFromStream(FColumnName,Stream,10256);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRConstraintDefNotNull.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);
  SaveDataToStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10242);
  SaveWideStringToStream(FColumnName,Stream,10247);
end; // SaveToStream




////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefCheck
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRConstraintDefCheck.Create;
begin
  FConstraintType := ctCheck;
  FMinValue := TACRVariant.Create;
  FMaxValue := TACRVariant.Create;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRConstraintDefCheck.Destroy;
begin
  FMinValue.Free;
  FMaxValue.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConstraintDefCheck.Assign(Source: TACRMetaObjectDef);
begin
  inherited Assign(Source);
  FColumnName := TACRConstraintDefCheck(Source).FColumnName;
  FColumnObjectID := TACRConstraintDefCheck(Source).FColumnObjectID;
  FMinValue.Assign(TACRConstraintDefCheck(Source).FMinValue);
  FMaxValue.Assign(TACRConstraintDefCheck(Source).FMaxValue);
end;//Assign


//------------------------------------------------------------------------------
// SetNames
//------------------------------------------------------------------------------
procedure TACRConstraintDefCheck.SetNames(ColumnName: WideString);
begin
  FColumnName := ColumnName;
end;//SetNames


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRConstraintDefCheck.LoadFromStream(Stream: TStream);
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
procedure TACRConstraintDefCheck.SaveToStream(Stream: TStream);
begin
  inherited SaveToStream(Stream);

  SaveDataToStream(FColumnObjectID,sizeof(FColumnObjectID),Stream,10229);
  SaveWideStringToStream(FColumnName,Stream,10225);

  FMinValue.SaveToStream(Stream);
  FMaxValue.SaveToStream(Stream);
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefUnique
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRConstraintDefUnique.Create;
begin
  inherited;
  FConstraintType := ctUnique;
  SetLength(Columns,0);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRConstraintDefUnique.Destroy;
begin
  SetLength(Columns,0);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConstraintDefUnique.Assign(Source: TACRMetaObjectDef);
var i,L: Integer;
begin
  inherited Assign(Source);
  L := Length(TACRConstraintDefUnique(Source).Columns);
  SetLength(Columns, L);
  for i:=0 to L-1 do
    Columns[i] := TACRConstraintDefUnique(Source).Columns[i];

  FIndexName := TACRConstraintDefUnique(Source).FIndexName;
  FIndexObjectID := TACRConstraintDefUnique(Source).FIndexObjectID;
end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRConstraintDefUnique.LoadFromStream(Stream: TStream);
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
procedure TACRConstraintDefUnique.SaveToStream(Stream: TStream);
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
// TACRMetaObjectDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRConstraintDefPrimary.Create;
begin
  inherited;
  FConstraintType := ctPK;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefForeignKeyAction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRConstraintDefForeignKeyAction.Create;
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
destructor TACRConstraintDefForeignKeyAction.Destroy;
begin
  SetLength(Columns,0);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConstraintDefForeignKeyAction.Assign(Source: TACRMetaObjectDef);
var i,L: Integer;
begin
  inherited Assign(Source);
  L := Length(TACRConstraintDefForeignKeyAction(Source).Columns);
  SetLength(Columns, L);
  for i:=0 to L-1 do
    Columns[i] := TACRConstraintDefForeignKeyAction(Source).Columns[i];
  FReferencedTableName := TACRConstraintDefForeignKeyAction(Source).FReferencedTableName;
  FReferencedTableObjectID := TACRConstraintDefForeignKeyAction(Source).FReferencedTableObjectID;
  FReferencedFKName := TACRConstraintDefForeignKeyAction(Source).FReferencedFKName;
  FReferencedFKObjectID := TACRConstraintDefForeignKeyAction(Source).FReferencedFKObjectID;
  FDeleteAction := TACRConstraintDefForeignKeyAction(Source).DeleteAction;
  FUpdateAction := TACRConstraintDefForeignKeyAction(Source).UpdateAction;
  FMatchType := TACRConstraintDefForeignKeyAction(Source).MatchType;
end;//Assign


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRConstraintDefForeignKeyAction.LoadFromStream(Stream: TStream);
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
procedure TACRConstraintDefForeignKeyAction.SaveToStream(Stream: TStream);
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
// TACRConstraintDefForeignKey
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRConstraintDefForeignKey.Create;
begin
  inherited;
  FConstraintType := ctFK;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TACRViewDef
//
////////////////////////////////////////////////////////////////////////////////

{
FSelectStatement:     WideString;
FWithCheckOption:     Boolean;
FChildViewsCRC:       TACRIntegerArray; // CRC32 of UpperCase view names
FColumnNames:         TACRObjectNameArray;
}

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRViewDef.Create;
begin
  FChildrenCRC := TACRIntegerArray.Create;
  FChildrenNames := TACRObjectNameArray.Create;
  FColumnNames := TACRObjectNameArray.Create;
end; // Create


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRViewDef.Create(
                       aName:             WideString;
                       aSelectStatement:  WideString;
                       aChildrenNames:    TACRWideStringList;
                       aColumnNames:      TACRWideStringList;
                       aCheckOption:      Boolean;
                       aComment:          WideString
                              );
var i: Integer;
begin
  FChildrenCRC := TACRIntegerArray.Create;
  FChildrenNames := TACRObjectNameArray.Create;
  FColumnNames := TACRObjectNameArray.Create;
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
destructor TACRViewDef.Destroy;
begin
  FChildrenCRC.Free;
  FChildrenNames.Free;
  FColumnNames.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRViewDef.Assign(Source: TACRMetaObjectDef);
begin
  inherited Assign(Source);
  if (Source is TACRViewDef) then
  begin
   FSelectStatement := TACRViewDef(Source).FSelectStatement;
   FWithCheckOption := TACRViewDef(Source).FWithCheckOption;
   FChildrenCRC.Assign(TACRViewDef(Source).FChildrenCRC);
   FChildrenNames.Assign(TACRViewDef(Source).FChildrenNames);
   FColumnNames.Assign(TACRViewDef(Source).FColumnNames);
   FCreationDate := TACRViewDef(Source).FCreationDate;
  end;
end; // Assign


//------------------------------------------------------------------------------
// load
//------------------------------------------------------------------------------
procedure TACRViewDef.LoadFromStream(Stream: TStream);
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
procedure TACRViewDef.SaveToStream(Stream: TStream);
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
function TACRViewDef.FindChild(crc: Cardinal): Boolean;
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
// TACRMetaObjectDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.LoadFromStream(Stream: TStream);
begin
 Clear;
 LoadDataFromStream(FLoadedItemCount,sizeof(FLoadedItemCount),Stream,10159);
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.SaveToStream(Stream: TStream);
var ItemCount:  Integer;
begin
 ItemCount := Self.Count;
 SaveDataToStream(ItemCount,sizeof(ItemCount),Stream,10158);
end; // SaveToStream


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRMetaObjectDefs.Create;
begin
  FDefsList := TACRSortedStringPtrArray.Create;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRMetaObjectDefs.Destroy;
begin
  Clear;
  FDefsList.Free;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.Assign(Source: TACRMetaObjectDefs);
var i,k,crc: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_Assign}
aaWriteToLog('> TACRMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'Source.ClassName = '+Source.ClassName
+#13#10+'Source.Count = '+IntToStr(Source.Count)
);
{$ENDIF}
  Clear;
  for i:=0 to Source.Count-1 do
   begin
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_Assign}
aaWriteToLog('1 TACRMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'i = '+IntToStr(i)
);
aaWriteToLog('1.1 TACRMetaObjectDefs.Assign, Source.Count = '+IntToStr(Source.Count));
aaWriteToLog('1.2 TACRMetaObjectDefs.Assign, Source[i].Name = '+Source[i].Name);
{$ENDIF}
    k := GetDefNumberByName(Source[i].Name);
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_Assign}
aaWriteToLog('2 TACRMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'k = '+IntToStr(k)
);
{$ENDIF}
    if (k >= 0) then
      raise EACRException.Create(10424,ErrorLDuplicateFieldName,
        [Source[i].Name]);
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_Assign}
aaWriteToLog('3 TACRMetaObjectDefs.Assign, ClassName = '+Self.ClassName);
{$ENDIF}
    InternalAddCreated.Assign(Source.Items[i]);
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_Assign}
aaWriteToLog('4 TACRMetaObjectDefs.Assign, ClassName = '+Self.ClassName);
{$ENDIF}
   end;
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_Assign}
aaWriteToLog('< TACRMetaObjectDefs.Assign, ClassName = '+Self.ClassName
+#13#10+'Source.ClassName = '+Source.ClassName
+#13#10+'Source.Count = '+IntToStr(Source.Count)
+#13#10+'Self.Count = '+IntToStr(Self.Count)
);
{$ENDIF}
end;//Assign


//------------------------------------------------------------------------------
// GetCount
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetCount: Integer;
begin
  Result := FDefsList.Count;
end;//GetCount



//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetDef(Index: Integer): TACRMetaObjectDef;
begin
  Result := TACRMetaObjectDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.SetDef(Index: Integer; Value: TACRMetaObjectDef);
begin
  TACRMetaObjectDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// GetDefNumberByName
//    ( if name not found, then Result = -1 )
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetDefNumberByName(Name: WideString): Integer;
var i:   Integer;
    crc: Cardinal;
begin
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_GetDefNumberByName}
aaWriteToLog('> TACRMetaObjectDefs.GetDefNumberByName, ClassName = '+Self.ClassName+#13#10+Name+#13#10+'FDefsList.Count = '+IntToStr(FDefsList.Count));
{$ENDIF}
  Result := -1;
  crc := GetTableNameCRC(Name,True);
// optimized in v.5.60
  for i := 0 to FDefsList.Count-1 do
    if (TACRMetaObjectDef(FDefsList.Items[i]).NameCRC = crc) then
    begin
     Result := i;
     break;
    end;
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_GetDefNumberByName}
aaWriteToLog('< TACRMetaObjectDefs.GetDefNumberByName, ClassName = '+Self.ClassName+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
end;//GetDefNumberByName


//------------------------------------------------------------------------------
// GetDefNumberByName
//    ( if name not found, then Result = -1 )
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetDefNumberByCRC(CRC: Cardinal): Integer;
var i:   Integer;
begin
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_GetDefNumberByCRC}
aaWriteToLog('> TACRMetaObjectDefs.GetDefNumberByCRC, ClassName = '+Self.ClassName+#13#10+IntToHex(CRC,8)+#13#10+'FDefsList.Count = '+IntToStr(FDefsList.Count));
{$ENDIF}
  Result := -1;
  for i := 0 to FDefsList.Count-1 do
    if (TACRMetaObjectDef(FDefsList.Items[i]).NameCRC = crc) then
    begin
     Result := i;
     break;
    end;
{$IFDEF DEBUG_TRACE_TACRMetaObjectDefs_GetDefNumberByName}
aaWriteToLog('< TACRMetaObjectDefs.GetDefNumberByCRC, ClassName = '+Self.ClassName+#13#10+'Result = '+IntToStr(Result));
{$ENDIF}
end;//GetDefNumberByCRC


//------------------------------------------------------------------------------
// GetDefByName
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetDefByName(Name: WideString): TACRMetaObjectDef;
var i: Integer;
begin
  i := GetDefNumberByName(Name);
  if i = -1 then
    Result := nil
  else
    Result := TACRMetaObjectDef(Items[i]);
end;//GetDefByName


//------------------------------------------------------------------------------
// GetDefNumberByObjectId
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetDefNumberByObjectId(id: TACRObjectID): Integer;
var i: Integer;
begin
  Result := -1;
  for i:=0 to FDefsList.Count -1 do
    if (TACRMetaObjectDef(FDefsList[i]).ObjectID = id) then
      begin
        Result := i;
        break;
      end;
end;//GetDefNumberByObjectId


//------------------------------------------------------------------------------
// GetDefByByObjectId
//------------------------------------------------------------------------------
function TACRMetaObjectDefs.GetDefByObjectId(id: TACRObjectID): TACRMetaObjectDef;
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
function TACRMetaObjectDefs.InternalAddCreated: TACRMetaObjectDef;
begin
  raise EACRException.Create(30339, ErrorGMethodNotOverrided,
                                            ['InternalAddCreated', classname]);
end; // InternalAddCreated


//------------------------------------------------------------------------------
// Add
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.Add(MetaObjectDef: TACRMetaObjectDef);
begin
  FDefsList.Add(MetaObjectDef);
end;//Add


//------------------------------------------------------------------------------
// Delete
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.Delete(Index: Integer);
begin
 if FDefsList[Index] <> nil then
    TACRMetaObjectDef(FDefsList[Index]).Free;
 FDefsList.Delete(Index);
end;//Delete


//------------------------------------------------------------------------------
// Insert
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.Insert(Index: Integer; MetaObjectDef: TACRMetaObjectDef);
begin
  FDefsList.Insert(Index, MetaObjectDef);
end;//Insert


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.Clear;
begin
  while (Count > 0) do
    Delete(0);
  FDefsList.Clear;
end;//Clear


//------------------------------------------------------------------------------
// Move
//------------------------------------------------------------------------------
procedure TACRMetaObjectDefs.Move(CurIndex, NewIndex: Integer);
begin
  FDefsList.Move(CurIndex, NewIndex);
end;//Move




////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get index def
//------------------------------------------------------------------------------
function TACRIndexDefs.GetIndexDef(Index: Integer): TACRIndexDef;
begin
  Result := TACRIndexDef(GetDef(Index));
end;// GetIndexDef


//------------------------------------------------------------------------------
// set index def
//------------------------------------------------------------------------------
procedure TACRIndexDefs.SetIndexDef(Index: Integer; Value: TACRIndexDef);
begin
  SetDef(Index, Value);
end;// SetIndexDef


//------------------------------------------------------------------------------
// InternalAddCreated
//------------------------------------------------------------------------------
function TACRIndexDefs.InternalAddCreated: TACRMetaObjectDef;
begin
  Result := TACRIndexDef.Create;
  Add(Result);
end;//InternalAddCreated


//------------------------------------------------------------------------------
// AscDesc and CaseSensitivity lists should contain constants ACR_ASC, ACR_DESC, ACR_NO_CASE, ACR_CASE
//------------------------------------------------------------------------------
function TACRIndexDefs.IsIndexExists(FieldNames, AscDescList, CaseSensitivityList: TACRWideStringList): Boolean;
begin
  Result := not (FindIndex(FieldNames,AscDescList,CaseSensitivityList) = INVALID_OBJECT_ID);
end; // IsIndexExists


//------------------------------------------------------------------------------
// find index
//------------------------------------------------------------------------------
function TACRIndexDefs.FindIndex(FieldNames, AscDescList, CaseSensitivityList: TACRWideStringList): TACRObjectID;
var i,j,n:  Integer;
    bOK:    Boolean;
begin
 Result := INVALID_OBJECT_ID;
 if (FieldNames = nil) then
  raise EACRException.Create(10389,ErrorLNilPointer);
 if (AscDescList = nil) then
  raise EACRException.Create(10390,ErrorLNilPointer);
 if (CaseSensitivityList = nil) then
  raise EACRException.Create(10391,ErrorLNilPointer);
 if (FieldNames.Count <> AscDescList.Count) then
  raise EACRException.Create(10276,ErrorLDifferentListsLength,
    [FieldNames.Count,AscDescList.Count]);
 if (FieldNames.Count <> CaseSensitivityList.Count) then
  raise EACRException.Create(10277,ErrorLDifferentListsLength,
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
          ((AscDescList[j] = ACR_ASC) and (Items[i].Columns[j].FDescending)) or
          ((AscDescList[j] = ACR_DESC) and (not Items[i].Columns[j].FDescending)) or
          ((CaseSensitivityList[j] = ACR_CASE) and (Items[i].Columns[j].FCaseInsensitive)) or
          ((CaseSensitivityList[j] = ACR_NO_CASE) and (not Items[i].Columns[j].FCaseInsensitive))
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
function TACRIndexDefs.FindPrimaryIndex: TACRIndexDef;
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
function TACRIndexDefs.AddCreated: TACRIndexDef;
begin
  Result := TACRIndexDef(InternalAddCreated);
end;//AddCreated


//------------------------------------------------------------------------------
// GetIndexDefByIndexName
//------------------------------------------------------------------------------
function TACRIndexDefs.GetIndexDefByName(Name: WideString): TACRIndexDef;
var
  i: Integer;
begin
  i := GetDefNumberByName(Name);
  if i = -1 then
    Result := nil
  else
    Result := TACRIndexDef(Items[i]);
end;//GetIndexDefByIndexName


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRIndexDefs.LoadFromStream(Stream: TStream);
var IndexDef: TACRIndexDef;
    i:        Integer;
begin
 inherited LoadFromStream(Stream);
 for i := 0 to FLoadedItemCount-1 do
  begin
   IndexDef := TACRIndexDef.Create;
   IndexDef.LoadFromStream(Stream);
   Add(IndexDef);
  end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRIndexDefs.SaveToStream(Stream: TStream);
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
   TACRIndexDef(Items[i]).SaveToStream(Stream);
end; // SaveToStream




////////////////////////////////////////////////////////////////////////////////
//
// TACRFieldDefs
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// GetFieldDef
//------------------------------------------------------------------------------
function TACRFieldDefs.GetDef(Index: Integer): TACRFieldDef;
begin
  Result := TACRFieldDef(FDefsList[Index]);
end;//GetFieldDef


//------------------------------------------------------------------------------
// SetFieldDef
//------------------------------------------------------------------------------
procedure TACRFieldDefs.SetDef(Index: Integer; Value: TACRFieldDef);
begin
  TACRFieldDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetFieldDef


//------------------------------------------------------------------------------
// InternalAddCreated
//------------------------------------------------------------------------------
function TACRFieldDefs.InternalAddCreated: TACRMetaObjectDef;
begin
  Result := TACRFieldDef.Create;
  Add(Result);
end;//InternalAddCreated


//------------------------------------------------------------------------------
// AddCreated
//------------------------------------------------------------------------------
function TACRFieldDefs.AddCreated: TACRFieldDef;
begin
  Result := TACRFieldDef(InternalAddCreated);
end;//AddCreated


//------------------------------------------------------------------------------
// Recalc FieldOffsets in children fields
//------------------------------------------------------------------------------
procedure TACRFieldDefs.RecalcFieldOffsets;
var i: integer;
    CurMemOffset, CurDiskOffset: Integer;
    FieldDef: TACRFieldDef;
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
function TACRFieldDefs.GetMemoryRecordBufferSize: Integer;
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
function TACRFieldDefs.GetFieldDefByName(Name: WideString): TACRFieldDef;
begin
  Result := TACRFieldDef(GetDefByName(Name));
end;//GetFieldDefByFieldName


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRFieldDefs.LoadFromStream(Stream: TStream);
var
    FieldDef: TACRFieldDef;
    i:        Integer;
begin
 inherited LoadFromStream(Stream);
 for i := 0 to FLoadedItemCount-1 do
   begin
     FieldDef := TACRFieldDef.Create;
     FieldDef.EngineVersion := FEngineVersion;
     FieldDef.LoadFromStream(Stream);
     Add(FieldDef);
   end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRFieldDefs.SaveToStream(Stream: TStream);
var i: Integer;
begin
 inherited SaveToStream(Stream);
 for i := 0 to Count-1 do
  begin
   TACRFieldDef(Items[i]).EngineVersion := FEngineVersion;
   TACRFieldDef(Items[i]).SaveToStream(Stream);
  end;
end; // SaveToStream


//------------------------------------------------------------------------------
// Set default values to fields
//------------------------------------------------------------------------------
procedure TACRFieldDefs.ApplyDefaultValuesToRecordBuffer(RecordBuffer: TACRRecordBuffer);
var
    fieldDef: TACRFieldDef;
{$I ACR_set_null_flag_var.inc}
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
          {$I ACR_set_null_flag.inc}
        end;
    end;
  end;
end; // ApplyDefaultValuesToRecordBuffer




////////////////////////////////////////////////////////////////////////////////
//
// TACRConstraintDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// AddNotNull
//------------------------------------------------------------------------------
function TACRConstraintDefs.AddNotNull: TACRConstraintDefNotNull;
begin
  Result := TACRConstraintDefNotNull.Create;
  Add(Result);
end;//AddNotNull


//------------------------------------------------------------------------------
// AddCheck
//------------------------------------------------------------------------------
function TACRConstraintDefs.AddCheck: TACRConstraintDefCheck;
begin
  Result := TACRConstraintDefCheck.Create;
  Add(Result);
end;//AddCheck


//------------------------------------------------------------------------------
// Add PK
//------------------------------------------------------------------------------
function TACRConstraintDefs.AddPK: TACRConstraintDefPrimary;
begin
  Result := TACRConstraintDefPrimary.Create;
  Add(Result);
end;//AddPK


//------------------------------------------------------------------------------
// Add Unique
//------------------------------------------------------------------------------
function TACRConstraintDefs.AddUnique: TACRConstraintDefUnique;
begin
  Result := TACRConstraintDefUnique.Create;
  Add(Result);
end;//AddUnique


//------------------------------------------------------------------------------
// create FK
//------------------------------------------------------------------------------
function TACRConstraintDefs.AddFK: TACRConstraintDefForeignKey;
begin
  Result := TACRConstraintDefForeignKey.Create;
  Add(Result);
  FForeignKeysExists := True;
end; // AddFK


//------------------------------------------------------------------------------
// create FKAction (master table action for FK in detail table)
//------------------------------------------------------------------------------
function TACRConstraintDefs.AddFKAction: TACRConstraintDefForeignKeyAction;
begin
  Result := TACRConstraintDefForeignKeyAction.Create;
  Add(Result);
  FForeignKeysActionsExists := True;
end; // AddFKAction


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRConstraintDefs.Create;
begin
 inherited;
 FForeignKeysExists := False;
 FForeignKeysActionsExists := False;
end; // Create


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConstraintDefs.Assign(Source: TACRMetaObjectDefs);
var i: Integer;
begin
  Clear;
  FForeignKeysExists := False;
  FForeignKeysActionsExists := False;
  for i:=0 to Source.Count-1 do
   begin
    case TACRConstraintDef(Source.Items[i]).ConstraintType of
     ctNotNull:
       AddNotNull.Assign(TACRConstraintDefNotNull(Source.Items[i]));
     ctCheck:
       AddCheck.Assign(TACRConstraintDefCheck(Source.Items[i]));
     ctPK:
       AddPK.Assign(TACRConstraintDefPrimary(Source.Items[i]));
     ctUnique:
       AddUnique.Assign(TACRConstraintDefUnique(Source.Items[i]));
     ctFK:
      begin
       AddFK.Assign(TACRConstraintDefForeignKey(Source.Items[i]));
       FForeignKeysExists := True;
      end;
     ctFKAction:
      begin
       AddFKAction.Assign(TACRConstraintDefForeignKeyAction(Source.Items[i]));
       FForeignKeysActionsExists := True;
      end
     else
       raise EACRException.Create(30035, ErrorGNotImplementedYet);
    end;
   end;
end;//Assign


//------------------------------------------------------------------------------
// delete constraint
//------------------------------------------------------------------------------
procedure TACRConstraintDefs.Delete(Index: Integer);
var i: Integer;
begin
  inherited Delete(Index);
  FForeignKeysExists := False;
  FForeignKeysActionsExists := False;
  for i := 0 to GetCount-1 do
   if (TACRConstraintDef(FDefsList[i]).FConstraintType = ctFK) then
    FForeignKeysExists := True
   else
   if (TACRConstraintDef(FDefsList[i]).FConstraintType = ctFKAction) then
    FForeignKeysActionsExists := True;
end; // Delete


//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TACRConstraintDefs.GetDef(Index: Integer): TACRConstraintDef;
begin
  Result := TACRConstraintDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TACRConstraintDefs.SetDef(Index: Integer; Value: TACRConstraintDef);
begin
  if FDefsList[Index] <> nil then
    TACRConstraintDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// return true if actions with update action <> NoAction exists
//------------------------------------------------------------------------------
function TACRConstraintDefs.GetForeignKeysActionsUpdateExists: Boolean;
var i: Integer;
begin
  Result := FForeignKeysActionsExists;
  if (Result) then
   begin
    Result := False;
    for i := 0 to Count-1 do
     if (TACRConstraintDef(FDefsList.Items[i]).ConstraintType = ctFKAction) then
      if (TACRConstraintDefForeignKeyAction(FDefsList.Items[i]).UpdateAction <>
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
function TACRConstraintDefs.GetForeignKeysActionsDeleteExists: Boolean;
var i: Integer;
begin
  Result := FForeignKeysActionsExists;
  if (Result) then
   begin
    Result := False;
    for i := 0 to Count-1 do
     if (TACRConstraintDef(FDefsList.Items[i]).ConstraintType = ctFKAction) then
      if (TACRConstraintDefForeignKeyAction(FDefsList.Items[i]).DeleteAction <>
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
procedure TACRConstraintDefs.LoadFromStream(Stream: TStream);
var i:              Integer;
    ConstraintDef:  TACRConstraintDef;
    ConstraintType: TACRConstraintType;
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
          raise EACRException.Create(30316, ErrorGUnknownConstrainType,
                                     [Integer(ConstraintType)]);
      end;
      ConstraintDef.LoadFromStream(Stream);
    end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRConstraintDefs.SaveToStream(Stream: TStream);
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
procedure TACRConstraintDefs.ExtractForeignKeys(Dest: TACRConstraintDefs);
var i: Integer;
begin
  i := 0;
  while (i < FDefsList.Count) do
   begin
    if (TACRConstraintDef(FDefsList.Items[i]).ConstraintType in [ctFKAction,ctFK]) then
     begin
      // we must move FK to Dest if it is possible
      if ((Dest <> nil) and (TACRConstraintDef(FDefsList.Items[i]).ConstraintType = ctFK)) then
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
// TACRSequenceDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetDef
//------------------------------------------------------------------------------
function TACRSequenceDefs.GetDef(Index: Integer): TACRSequenceDef;
begin
  Result := TACRSequenceDef(FDefsList[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// SetDef
//------------------------------------------------------------------------------
procedure TACRSequenceDefs.SetDef(Index: Integer;
  Value: TACRSequenceDef);
begin
  TACRSequenceDef(FDefsList[Index]).Free;
  FDefsList[Index] := Value;
end;//SetDef


//------------------------------------------------------------------------------
// InternalAddCreated
//------------------------------------------------------------------------------
function TACRSequenceDefs.InternalAddCreated: TACRMetaObjectDef;
begin
  Result := TACRSequenceDef.Create;
  Add(Result);
end;//InternalAddCreated


//------------------------------------------------------------------------------
// AddCreated
//------------------------------------------------------------------------------
function TACRSequenceDefs.AddCreated: TACRSequenceDef;
begin
  Result := TACRSequenceDef(InternalAddCreated);
end;//AddCreated


//------------------------------------------------------------------------------
// GetSequenceDefByName
//------------------------------------------------------------------------------
function TACRSequenceDefs.GetSequenceDefByName(Name: WideString): TACRSequenceDef;
var i: Integer;
begin
  i := GetDefNumberByName(Name);
  if i = -1 then
    Result := nil
  else
    Result := TACRSequenceDef(Items[i]);
end;//GetSequenceDefByName



////////////////////////////////////////////////////////////////////////////////
//
// TACRViewDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
function TACRViewDefs.InternalAddCreated: TACRMetaObjectDef;
begin
  Result := TACRViewDef.Create;
  Add(Result);
end; // InternalAddCreated


//------------------------------------------------------------------------------
// load
//------------------------------------------------------------------------------
procedure TACRViewDefs.LoadFromStream(Stream: TStream);
var i:        Integer;
    viewDef:  TACRViewDef;
begin
  inherited LoadFromStream(Stream);
  for i := 0 to FLoadedItemCount-1 do
  begin
    viewDef := TACRViewDef(InternalAddCreated);
    viewDef.LoadFromStream(Stream);
  end;
end; // LoadFromStreamS


//------------------------------------------------------------------------------
// save
//------------------------------------------------------------------------------
procedure TACRViewDefs.SaveToStream(Stream: TStream);
var i:        Integer;
    viewDef:  TACRViewDef;
begin
  inherited SaveToStream(Stream);
  for i := 0 to FDefsList.Count-1 do
  begin
    viewDef := TACRViewDef(FDefsList.Items[i]);
    viewDef.SaveToStream(Stream);
  end;
end; // SaveToStream


//------------------------------------------------------------------------------
// return true if child view or table with specified name exists - for DROP [TABLE | VIEW]
//------------------------------------------------------------------------------
function TACRViewDefs.FindChildren(Name: WideString): Boolean;
var i:        Integer;
    viewDef:  TACRViewDef;
    crc:      Cardinal;
begin
  Result := False;
  crc := GetTableNameCRC(Name,True);
  for i := 0 to FDefsList.Count-1 do
  begin
    viewDef := TACRViewDef(FDefsList.Items[i]);
    Result := viewDef.FindChild(crc);
    if (Result) then
     break;
  end;
end; // FindChildren


//------------------------------------------------------------------------------
// delete all views that references view or table with specified name - for DROP [TABLE | VIEW] with CASCADE
//------------------------------------------------------------------------------
procedure TACRViewDefs.DeleteChildren(Name: WideString);
var i:        Integer;
    viewDef:  TACRViewDef;
    crc:      Cardinal;
begin
  crc := GetTableNameCRC(Name,True);
  i := 0;
  while (i < FDefsList.Count) do
  begin
    viewDef := TACRViewDef(FDefsList.Items[i]);
    if (viewDef.FindChild(crc)) then
     FDefsList.Delete(i)
    else
     Inc(i);
  end;
end; // DeleteChildren



////////////////////////////////////////////////////////////////////////////////
//
// TACRCursor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set index name
//------------------------------------------------------------------------------
procedure TACRCursor.SetIndexName(Value: WideString);
var
  ACRIndexDef: TACRIndexDef;
begin
  FIndexName := Value;
  ACRIndexDef := FIndexDefs.GetIndexDefByName(Value);
  if (ACRIndexDef <> nil) then
   begin
     FIndexID := ACRIndexDef.ObjectID;
   end
  else
   FIndexID := INVALID_OBJECT_ID;
end;// SetIndexName


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TACRCursor.SetCaseInsensitive(Value: Boolean);
begin
  FCaseInsensitive := Value;
end; // SetCaseInsensitive


{$IFDEF DEBUG_LOG}
procedure TACRCursor.WriteRecordBufferToLog(Buffer: TACRRecordBuffer);
var i,n:  Integer;
    s,pr: String;
    v:    TACRVariant;
begin
  if (Buffer = nil) then
   begin
    aaWriteToLog('TACRCursor.WriteRecordBufferToLog - Buffer = nil');
    Exit;
   end;
  n := FFieldDefs.Count;
  s := 'TACRCursor.WriteRecordBufferToLog - Buffer = '+IntToHex(Integer(Buffer),8)
        +#13#10+'RecordSize = '+IntToStr(FRecordSize)
        +', RecordBufferSize = '+IntToStr(FRecordBufferSize)+', FieldCount = '+IntToStr(n)+#13#10;
  v := TACRVariant.Create;
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
procedure TACRCursor.SetCurrentRecordIDAfterDelete;
begin
  Move(FDeleteCurrentRecordID,CurrentRecordID,SizeOf(TACRRecordID));
end; // SetCurrentRecordIDAfterDelete
}

//------------------------------------------------------------------------------
// Rename Field by Field Index in FieldDefs
//------------------------------------------------------------------------------
procedure TACRCursor.RenameField(FieldName, NewFieldName: WideString);
var
  fd: TACRFieldDef;
begin
  // Check Field Exists
  fd := FFieldDefs.GetFieldDefByName(FieldName);
  if (fd = nil) then
    raise EACRException.Create(30345, ErrorGFieldWithNameNotFound, [FieldName]);

  // Check For Duplicate FieldName
  if ( FFieldDefs.GetFieldDefByName(NewFieldName) <> nil ) then
   raise EACRException.Create(30346, ErrorGCannotRenameField,
                                     [FieldName, NewFieldName]);

  fd.Name := NewFieldName;
end;//RenameField


//------------------------------------------------------------------------------
// update table definitions (fields, indexes, constraints)
//------------------------------------------------------------------------------
procedure TACRCursor.UpdateTableDefinitions;
begin
end; // UpdateTableDefinitions


//------------------------------------------------------------------------------
// initialize record buffer
//------------------------------------------------------------------------------
procedure TACRCursor.InternalInitRecord(RecordBuffer: TACRRecordBuffer; InsertMode: Boolean);
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
function TACRCursor.GetIndexDefs: TACRIndexDefs;
begin
  Result := FIndexDefs;
end;// GetIndexDefs


//------------------------------------------------------------------------------
// Receive VisisbleFieldDefs.FieldNoReference
//------------------------------------------------------------------------------
procedure TACRCursor.ReceiveFieldNoReferences(Stream: TStream);
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
function TACRCursor.GetFieldData(
                          FieldNo:      Integer; // field no
                          Buffer:       Pointer; // buffer
                          RecordBuffer: TACRRecordBuffer // record buffer
                                      ): Boolean;
begin
 if (FieldNo >= VisibleFieldDefs.Count) then
   raise EACRException.Create(10005,ErrorLInvalidFieldNumber,[FieldNo,VisibleFieldDefs.Count]);
 Result := ACRBaseEngine.GetFieldData(VisibleFieldDefs[FieldNo].FieldNoReference,
                                      FieldDefs,Buffer,RecordBuffer);
end; // GetFieldData


//------------------------------------------------------------------------------
// set field data from Buffer to RecordBuffer
//------------------------------------------------------------------------------
procedure TACRCursor.SetFieldData(
                            FieldNo:      Integer;
                            Buffer:       Pointer;
                            RecordBuffer: TACRRecordBuffer // record buffer
                                      );
begin
 if (FieldNo >= VisibleFieldDefs.Count) then
   raise EACRException.Create(10006,ErrorLInvalidFieldNumber,[FieldNo,VisibleFieldDefs.Count]);
 ACRBaseEngine.SetFieldData(VisibleFieldDefs[FieldNo].FieldNoReference,
                                      FieldDefs,Buffer,RecordBuffer);
end; // SetFieldData


//------------------------------------------------------------------------------
// get blob value
//------------------------------------------------------------------------------
procedure TACRCursor.GetBLOBValue(V: TACRVariant; aFieldNo: Integer);
var
  bs:     TACRStream;
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
procedure TACRCursor.GetFieldValue(Value: TACRVariant; FieldNo: Integer; DirectAccess: Boolean; CopyFlag: Boolean = True);
var
    Offset: Integer;
    Buffer: PAnsiChar;
{$I ACR_check_null_flag_var.inc}
begin
 if (DirectAccess) then
  begin
   if (FieldNo >= FieldDefs.Count) then
     raise EACRException.Create(10317,ErrorLInvalidFieldNumber,
              [FieldNo,FieldDefs.Count]);
   CHECK_NULL_FLAG_NullFlags := CurrentRecordBuffer;
   CHECK_NULL_FLAG_BitNo := FieldNo;
   {$I ACR_check_null_flag.inc}
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
     raise EACRException.Create(10737,ErrorLInvalidFieldNumber,
              [FieldNo,VisibleFieldDefs.Count]);
   CHECK_NULL_FLAG_NullFlags := CurrentRecordBuffer;
   CHECK_NULL_FLAG_BitNo := VisibleFieldDefs[FieldNo].FieldNoReference;
   {$I ACR_check_null_flag.inc}
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
procedure TACRCursor.SetFieldValue(
                            Value:        TACRVariant;
                            FieldNo:      Integer;
                            DirectAccess: Boolean;
                            RecordBuffer: TACRRecordBuffer = nil
                                  );
var Buffer:     PAnsiChar;
    Offset:     Integer;
{$I ACR_set_null_flag_var.inc}
begin
 if (RecordBuffer = nil) then
   RecordBuffer := CurrentRecordBuffer;
 if (DirectAccess) then
  begin
   if (FieldNo >= FieldDefs.Count) then
     raise EACRException.Create(10318,ErrorLInvalidFieldNumber,
            [FieldNo,FieldDefs.Count]);
   if (Value.IsNull) then
    begin
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I ACR_set_null_flag.inc}
    end
   else
    begin
     SET_NULL_FLAG_ToSet := False;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I ACR_set_null_flag.inc}
     if (IsBLOBFieldType(FieldDefs[FieldNo].FBaseFieldType)) then
{ TODO -oLeo : implement normal settings of the BLOB data }
       raise EACRException.Create(11589,ErrorLSetBLOBFieldValueIsNotAllowed,[FieldNo,FTableName])
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
     raise EACRException.Create(10738,ErrorLInvalidFieldNumber,
            [FieldNo,VisibleFieldDefs.Count]);
   if (Value.IsNull) then
    begin
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := VisibleFieldDefs[FieldNo].FieldNoReference;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I ACR_set_null_flag.inc}
    end
   else
    begin
     SET_NULL_FLAG_ToSet := False;
     SET_NULL_FLAG_BitNo := VisibleFieldDefs[FieldNo].FieldNoReference;
     SET_NULL_FLAG_NullFlags := RecordBuffer;
     {$I ACR_set_null_flag.inc}
     if (IsBLOBFieldType(VisibleFieldDefs[FieldNo].FBaseFieldType)) then
{ TODO -oLeo : implement normal settings of the BLOB data }
       raise EACRException.Create(11591,ErrorLSetBLOBFieldValueIsNotAllowed,[FieldNo,FTableName])
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
function TACRCursor.AllocateRecordBuffer: TACRRecordBuffer;
begin
 Result := MemoryManager.GetMem(RecordBufferSize);
 if (FTempRecordBuffer =  nil) then
  FTempRecordBuffer := MemoryManager.GetMem(RecordBufferSize);
end; // AllocateRecordBuffer


//------------------------------------------------------------------------------
// free record buffer
//------------------------------------------------------------------------------
procedure TACRCursor.FreeRecordBuffer(var Buffer: TACRRecordBuffer);
begin
  MemoryManager.FreeAndNilMem(Buffer);
end; // FreeRecordBuffer


//------------------------------------------------------------------------------
// allocate record buffer and set null flags
//------------------------------------------------------------------------------
function TACRCursor.AllocateKeyRecordBuffer: TACRRecordBuffer;
begin
  Result := MemoryManager.GetMem(KeyBufferSize);
end;


//------------------------------------------------------------------------------
// initialize record buffer
//------------------------------------------------------------------------------
procedure TACRCursor.InternalInitKeyBuffer(RecordBuffer: TACRRecordBuffer);
begin
  FillChar(RecordBuffer^,KeyBufferSize,0);
  InternalInitRecord(RecordBuffer,False);
end;


//------------------------------------------------------------------------------
// go to first record (before first record to BOF)
//------------------------------------------------------------------------------
procedure TACRCursor.InternalFirst;
begin
 FirstPosition := True;
 LastPosition := False;
end; // InternalFirst


//------------------------------------------------------------------------------
// go to last record (after last record to EOF)
//------------------------------------------------------------------------------
procedure TACRCursor.InternalLast;
begin
 FirstPosition := False;
 LastPosition := True;
end; // InternalLast


//------------------------------------------------------------------------------
// save position
//------------------------------------------------------------------------------
function TACRCursor.SavePosition: Pointer;
begin
// Result := New(PACRCursorPos);
 Result := MemoryManager.GetMem(SizeOf(TACRCursorPos));
 PACRCursorPos(Result)^.FirstPosition := Self.FirstPosition;
 PACRCursorPos(Result)^.LastPosition := Self.LastPosition;
 PACRCursorPos(Result)^.RecordID := Self.CurrentRecordID;
end; // SavePosition


//------------------------------------------------------------------------------
// restore position
//------------------------------------------------------------------------------
procedure TACRCursor.RestorePosition(Pos: Pointer);
begin
 Self.FirstPosition := PACRCursorPos(Pos)^.FirstPosition;
 Self.LastPosition := PACRCursorPos(Pos)^.LastPosition;
 Self.CurrentRecordID := PACRCursorPos(Pos)^.RecordID;
end; // RestorePosition


//------------------------------------------------------------------------------
// free position
//------------------------------------------------------------------------------
procedure TACRCursor.FreePosition(var Pos: Pointer);
begin
 if (Pos <> nil) then
  MemoryManager.FreeAndNilMem(Pos);
end; // FreePosition


//------------------------------------------------------------------------------
// added in v.5.30 - moved from TACRMain.GetRecord
//------------------------------------------------------------------------------
procedure TACRCursor.GetCalcFieldsAndBookMarkData(bInsert: Boolean = False);
var
    Bookmark:           PACRBookmarkInfo;
begin
  // fixed in v.5.60 to avoid problems with BLOB fields usage in calculated fields
  // write bookmark info to record buffer
  Bookmark := PACRBookmarkInfo(FCurrentRecordBuffer + FBookmarkOffset);
  Bookmark^.BookmarkData := CurrentRecordID;
  if (bInsert) then
   Bookmark^.BookmarkFlag := abfInserted
  else
   Bookmark^.BookmarkFlag := abfCurrent;
  if (Dataset <> nil) then
    TACRDataset(Dataset).ClearAndGetCalcFields(TRecordBuffer(CurrentRecordBuffer));
end; // GetCalcFieldsAndBookMarkData


//------------------------------------------------------------------------------
// refresh - added in v.5.30
//------------------------------------------------------------------------------
procedure TACRCursor.InternalRefresh;
begin
 if (IsFilterApplied) then
  begin
    DeactivateFilters;
    if (Dataset <> nil) then
     TACRDataset(Dataset).ActivateFilters;
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
procedure TACRCursor.InternalInsert;
begin
//
end; // InternalInsert


//------------------------------------------------------------------------------
// return disk record size
//------------------------------------------------------------------------------
function TACRCursor.GetDiskRecordSize: Integer;
begin
 if (FFieldDefs.Count <= 0) then
  raise EACRException.Create(11625,ErrorLNoFields);
 Result := FieldDefs[FFieldDefs.Count-1].DiskOffset +
   FFieldDefs[FFieldDefs.Count-1].DiskDataSize;
end; // GetDiskRecordSize


//------------------------------------------------------------------------------
// return true if index applied
//------------------------------------------------------------------------------
function TACRCursor.IsIndexApplied: Boolean;
begin
  Result := (IndexID <> INVALID_OBJECT_ID);
end; // IsIndexApplied


//------------------------------------------------------------------------------
// return true if filter applied
//------------------------------------------------------------------------------
function TACRCursor.IsFilterApplied: Boolean;
begin
  Result := ((FilterExpression <> nil) or (FilterRecord <> nil) or
             (SQLFilterExpression <> nil));
end; // IsFilterApplied


//------------------------------------------------------------------------------
// return true if range is applied
//------------------------------------------------------------------------------
function TACRCursor.IsRangeApplied: Boolean;
begin
  Result := ((FRangeStartBuffer <> nil) or (FRangeEndBuffer <> nil));
end; // IsRangeApplied


//------------------------------------------------------------------------------
// reset range
//------------------------------------------------------------------------------
function TACRCursor.IsViewRestricted: Boolean;
begin
  Result := (IsFilterApplied or IsRangeApplied);
end; // IsViewRestricted


//------------------------------------------------------------------------------
// update index definitions in dataset
//------------------------------------------------------------------------------
procedure TACRCursor.UpdateIndexDefinitions;
begin
  if (Dataset <> nil) then
   TACRDataset(Dataset).UpdateIndexDefinitions(Self);
end; // UpdateIndexDefinitions


////////////////////////////////////////////////////////////////////////////////
//
// TACRSessionNamedObject
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSessionNamedObject.Create(Name: WideString);
begin
  FName := Name;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TACRSessionNamedObjectSequenceValue
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSessionNamedObjectSequenceValue.Create(ValueName: WideString;
  Value: TACRSequenceValue);
begin
  inherited Create(ValueName);
  FValue := Value;
end;//Create



////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// added in v.5.90
//------------------------------------------------------------------------------
procedure TACRBaseSession.SetCaseInsensitive(Value: Boolean);
begin
  FCaseInsensitive := Value;
end; // SetCaseInsensitive


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRBaseSession.Create;
begin
  FSessionNamedObjectList := TACRSortedStringPtrArray.Create;
  FSessionID := INVALID_SESSION_ID;
  FTemporary := False;
  FInMemory := False;
  FSessionVariables := nil;
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRBaseSession.Destroy;
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
    TACRSessionNamedObject(FSessionNamedObjectList[i]).Free;
  FSessionNamedObjectList.Free;
  if (FSessionVariables <> nil) then
   FSessionVariables.Free;
  inherited; 
end;//destroy


//------------------------------------------------------------------------------
// create database
//------------------------------------------------------------------------------
procedure TACRBaseSession.CreateDatabase;
begin
  raise EACRException.Create(10888,ErrorLOperationIsNotSupported);
end; // CreateDatabase


//------------------------------------------------------------------------------
// Get Named object from session
//------------------------------------------------------------------------------
function TACRBaseSession.GetNamedObject(ObjectName: WideString): TACRSessionNamedObject;
var i: integer;
begin
  Result := nil;
  for i:=0 to FSessionNamedObjectList.Count -1 do
   if (ObjectName = TACRSessionNamedObject(FSessionNamedObjectList[i]).Name) then
    begin
     Result := TACRSessionNamedObject(FSessionNamedObjectList[i]);
     break;
    end;
end;//GetNamedObject


//------------------------------------------------------------------------------
// set sequence value
//------------------------------------------------------------------------------
procedure TACRBaseSession.SetSequenceValue(const Name:  TACRObjectName;
                                           const Value: TACRSequenceValue);
var
  OldValue: TACRSessionNamedObject;
begin
  OldValue := GetNamedObject(Name);
  if (OldValue = nil) then
   begin
    // create new value
    OldValue := TACRSessionNamedObjectSequenceValue.Create(Name,Value);
    FSessionNamedObjectList.Add(OldValue);
   end
  else
   begin
    TACRSessionNamedObjectSequenceValue(OldValue).Value := Value;
   end;
end; // SetSequenceValue


//------------------------------------------------------------------------------
// for client and server sessions
//------------------------------------------------------------------------------
procedure TACRBaseSession.ReceiveData(Buffer: PAnsiChar; BufferSize: Integer);
begin
end; // ReceiveData


//------------------------------------------------------------------------------
// for client and server sessions
//------------------------------------------------------------------------------
procedure TACRBaseSession.OnDisconnect;
begin
end; // OnDisconnect


//------------------------------------------------------------------------------
// for TACRLocalSession called by TACRServerSession
//------------------------------------------------------------------------------
procedure TACRBaseSession.RemoveAllLocks;
begin
end; // RemoveAllLocks


//------------------------------------------------------------------------------
// clear disk cache in single-user / multi-user
//------------------------------------------------------------------------------
procedure TACRBaseSession.ClearCache;
begin
end; // ClearCache


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRBaseSession.GetTableComment(TableName: WideString): WideString;
begin
  Result := '';
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRBaseSession.SetTableComment(TableName, Comment: WideString);
begin
// do nothing
end; // SetTableComment


//------------------------------------------------------------------------------
// call OnError event handler
//------------------------------------------------------------------------------
procedure TACRBaseSession.DoOnError(ErrorCode: Integer;  NativeError: Integer = -1; ErrorMessage: AnsiString = '');
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in TACRBaseSession');
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
procedure TACRBaseSession.SetDatabaseParams(var DBParams: TACRSQLDatabaseParams);
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
// TACRSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLProcessor.Create;
begin
  FSQLParams := TACRSQLParams.Create;
  FACRQuery := nil;
  FCursor := nil;
  FSqlText := '';
  FNeverOpened := True;
  FParamsChanged := False;
  FCaseInsensitive := False;
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLProcessor.Create(Query: TDataSet);
begin
  Create;
  FACRQuery := Query;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRSQLProcessor.Destroy;
begin
  FSQLParams.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// OpenQuery
//------------------------------------------------------------------------------
function TACRSQLProcessor.OpenQuery(TableNames: TACRWideStringList): TACRCursor;
var NewHashValue: TACRRecordHashValue;
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
procedure TACRSQLProcessor.ExecuteQuery;
begin
  OpenQuery;
end;//ExecuteQuery


//------------------------------------------------------------------------------
// PrepareStatement
//------------------------------------------------------------------------------
procedure TACRSQLProcessor.PrepareStatement(SQLText: PWideChar);
begin
  FSqlText := SQLText;
end;//PrepareStatement


//------------------------------------------------------------------------------
// update parameters
//------------------------------------------------------------------------------
procedure TACRSQLProcessor.UpdateParams;
begin
  FParamsChanged := True;
end; // UpdateParams


//------------------------------------------------------------------------------
// internal method, used in TACRServerSession for copying disk/memory table
// returned by SELECT INTO to temporary
// can be use later
//------------------------------------------------------------------------------
function ACRCopyCursors(
            SourceCursor:       TACRCursor;
            DestinationCursor:  TACRCursor
            ): WideString;
var i,j:              Integer;
    SourceFields:     TACRIntegerArray;
    ResultFields:     TACRIntegerArray;
    Buf1,Buf2:        PAnsiChar;
    OldBuf1,OldBuf2:  PAnsiChar;
    value:            TACRVariant;
begin
  Result := '';
  if (SourceCursor = nil)  then
   raise EACRException.Create(11671,ErrorLNilPointer);
  if (DestinationCursor = nil)  then
   raise EACRException.Create(11672,ErrorLNilPointer);
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
    SourceFields := TACRIntegerArray.Create(0,1,SourceCursor.VisibleFieldDefs.Count);
    ResultFields := TACRIntegerArray.Create(0,1,SourceCursor.VisibleFieldDefs.Count);
    value := TACRVariant.Create;
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
end; // ACRCopyCursors


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRBase> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.

