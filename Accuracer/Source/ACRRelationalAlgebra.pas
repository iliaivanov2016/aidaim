unit ACRRelationalAlgebra;

interface

{$I ACRVer.inc}
uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  Classes, DB, SysUtils, Math,

// Accuracer units

{$IFDEF DEBUG_LOG}
 ACRDebug,
{$ENDIF}
{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}
 ACRConst,
 ACRConverts,
 ACRStrUtils,
 ACRExcept,
 ACRBase,
 ACRTypes,
 ACRCompression,
 ACRComMain,
 ACRVariant
 ;

type

 TACRAO = class;
 TACRFieldLink = record
  FieldName:                WideString;   // field name
  DisplayName:              WideString;   // result field name
  OriginalFieldName:        WideString;   // original filed name for joins
  TableName:                WideString;   // name of the source table of the field
  TableAlias:               WideString;   // alias of the source table of the field
  FieldType:                TACRAdvancedFieldType;
  FieldPrecision:           Integer;
  FieldSize:                Integer;
  BLOBCompressionAlgorithm: Byte;
  BLOBCompressionMode:      Byte;
  BLOBBlockSize:            Integer;
  AO:                       Pointer;  // was TACRAO type, CB4 bug fix
  Dataset:                  TDataset; // dataset
  IsHidden:                 Boolean;
  FieldNo:                  Integer;  // field number in AO or FieldNo
  IsExpression:             Boolean;  // Expression or field?
  IsAggregate:              Boolean;  // Expression is aggregate (contains agg. functions)?
  Expr:                     TObject;  // TACRExpression
 end;

 // fields (expressions) list in select
 TACRSelectListItem = record
  TableName:    WideString;   // 'table1.' | 't1'
  AllFields:    Boolean;  // 'table1.*' ?
  FieldName:    WideString;   // field1
  IsExpression: Boolean;  // field or expr?
  ValueExpr:    TObject;  // TACRExpression
  Pseudonym:    WideString;   // field1 as f1
 end;

 // array of fields
 TACRFields = class (TObject)
 public
   Items:           array of TACRSelectListItem; // fields
   ItemCount:       Integer;                     // length
   CaseInsensitive: Boolean;
   // create
   constructor Create;
   // destroy
   destructor Destroy; override;
   // adds item to the end
   procedure Append(var Item: TACRSelectListItem);
   // clear
   procedure Clear;
   // assign
   procedure Assign(Source: TACRFields);
   // update expression params in this node and all children
   procedure UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TACRBaseSession;
                  LParams:          TACRSQLParams
                                    );
 end;

 // binary comparison for records based on field values with NULL support
 TACRRecordComparison = class (TObject)
  private
   FNumFields:        Integer;
   FCurrentHashValue: TACRRecordHashValue;
   FFieldHashValues:  array of TACRRecordHashValue;
{$IFDEF HASH_ARRAY_RECORD_COMPARISON}
   FRecordHashValues: TACRHashArray;
{$ELSE}
   FRecordHashValues: TACRIntegerArray;
{$ENDIF}
  public
   constructor Create(NumFields: Integer; ApproximateRecordCount: Integer = 0);
   destructor Destroy; override;
   procedure AddFieldHash(FieldValue: TACRVariant; FieldNo: Integer);
   procedure CalculateRecordHash;
   // appends hash value if it does not exist and return true
   // return false if value already exists
   function AppendRecordHash: Boolean;
   property CurrentHashValue: TACRRecordHashValue read FCurrentHashValue;
 end;

 // SQL optimizer - will be implemented in Accuracer v.6 / SQLMemTable v.5
{ TODO -oLeo : to version 5: filter optimizations (OR. AND NOT), joins in single AO,
inner joins must be evaluated starting from the table with smaller record count }
 TACRSQLOptimizer = class (TObject)
  private
   LAO:     TACRAO;
  public
   constructor Create(AO: TACRAO);
   destructor Destroy; override;
   procedure OptimizeAll;
  protected
   procedure OptimizeFilters; 
   procedure OptimizeOR; virtual; abstract;
   procedure OptimizeNOT; virtual; abstract;
   procedure OptimizeJoins; virtual; abstract;
 end; // TACRSQLOptimizer

 // base class for relational algebra operations
 TACRAO = class (TObject)
 private
  FIsRootAO:                  Boolean;
  FIsAOTable:                 Boolean;
  FIsAOGroupBy:               Boolean;
  FFilterExpr:                TObject; // TACRExpression
  FTopRowCount:               Int64;
  FFirstRowNo:                Int64;
  FRecordComparison:          TACRRecordComparison; // used in DISTINCT
  FSQLOptimizer:              TACRSQLOptimizer; // not implemented yet
  FParametrized:              Boolean; // true if the AO has at least 1 parameter
                                       // or any of its children AO has parameters
  FParamNodes:                TACRList;   // list of all ParamNodes of Root AO
                                       // and all its children AO
  FRestartMaterialization:    Boolean; // true if parametrized query or correlated subquery is reopening
 protected
  FMaterializationDataSaved:  Boolean;
  FRequestLive:               Boolean;
  FResultInMemory:            Boolean; // for SELECT INTO optimization
  FResultTableName:           WideString;  // for SELECT INTO optimization
  FResultDatabaseName:        AnsiString;  // for SELECT INTO optimization
  FTableName:                 WideString;
  FTableAlias:                WideString;
  FIsMaterialized:            Boolean;
  FResultDataset:             TDataset; // result dataset
  FResultFieldsOrder:         TACRIntegerArray;
  FFieldCount:                Integer;
  FLeftAONull:                Boolean;
  FRightAONull:               Boolean;
  FNotFilterExpression:       Boolean; // set to true if NOT was a root expression node in FilterExpression
                                       // so the result of FilterExpr must be inverted (Not Result)

  // number of fields specified in SELECT list
  // FResultFieldCount can be <= FVisibleFieldCount, as some fields should be visible for creating index
  // (some fields are used only in coditions / ORDER BY, they are hidden in the result dataset by projection)
  FResultFieldCount:          Integer;
  // current value of the field
  FFieldValue:                TACRVariant;

  // DISTINCT related
  FDistinctApplied:           Boolean;
  // number of visible result fields
//  FDistinctFieldCount:        Integer;
  // index of visible result fields in FResultDataset
//  FDistinctFieldNumbers:       array of integer;
  // for adaByDestIndex distinct algorithm - to create index in result dataset
  FDistinctFields:            WideString;
  FDistinctAlgorithm:         TACRDistinctAlgorithm;
  // values of all visible fields in current record
  FDistinctFieldValues:       array of TACRVariant;
  // for adaBySourceIndex - hash of values of all visible fields in prior record
  FPriorRecordHash:           TACRRecordHashValue;

  FResultIndexFieldsList:             TACRWideStringList;
  FResultIndexAscDescFieldsList:      TACRWideStringList;
  FResultIndexCaseInsFieldsList:      TACRWideStringList;
  FResultIndexFieldNumbers:           TACRIntegerArray; // field number in FFieldLinks
  FResultIndexName:                   WideString;
  FExpressionsExists:                 Boolean;
  FAggregateExpressionsExists:        Boolean;
  FActivateIndexAfterMaterialize:     Boolean;
  FAllFieldsNull:                     Boolean;
  // added in v.4.60 for correct ORDER BY with UNION
  // (applied to right node in prior version instead of result of union)
  FIndexFieldNames:                   WideString;
  FDescFields:                        WideString;
  FCaseInsensitiveFields:             WideString;
  // set to true if materialization will create temporary table
  // and ApplyTop will copy the result data to table specified by
  // FResultTableName, FResultInMemory, FResultDatabaseName
  FApplyTopWillCopyToResultTable:     Boolean;
  FTopApplied:                        Boolean; // TOP option applied
  FTopInside:                         Boolean; // TOP option can be applied inside materialization process

  FSavedFieldLinks:                   array of TACRFieldLink; // for parametrized
  FSavedSourceDatasetFilter:          TObject;                // queries
  // needed for expressions evalation (called from stored functions)
  LSession:                           TACRBaseSession;
  LParams:                            TACRSQLParams;
{$IFDEF CORRELATED_SUBQUERIES}
  // added in v.5.60
  FExternalFieldNodes:                TACRList; // list of external TACRExprNodeField objects
                                                // in correlated subquery
  FExternalConstNodes:                TACRList; // list of external TACRExprNodeConst objects
                                                // in correlated subquery to store field value
                                                // referencing root TACRAO object from main query
  FSubQuery:                                Boolean;
  FExternalFieldNodesLinkedToSubQueryAO:    TACRList;
{$ENDIF}
  FCaseInsensitive:                         Boolean; // added in v.5.90
 protected
  FFieldLinks:                        array of TACRFieldLink;
 public
  FLeftAO,FRightAO:           TACRAO;
 protected
  procedure InternalCreate(
                      Session:      TACRBaseSession;
                      Params:       TACRSQLParams;
                      LeftAO:       TACRAO = nil;
                      RightAO:      TACRAO = nil;
                      TableName:    WideString = '';
                      TableAlias:   WideString = '';
                      SubQuerySQL:  WideString = ''
                      );
   // navigating
   procedure InternalFirst; virtual;
   procedure InternalNext; virtual;
   function InternalGetEof: Boolean; virtual;
   function InternalGetRecordCount: Integer; virtual;
   procedure First; virtual;
   procedure Next; virtual;
   function GetEof: Boolean; virtual;
   function GetRecordCount: Integer; virtual;
   // sets names to FieldLinks list for unnamed expressions
   procedure SetFieldNames;
   // rename field to avoid duplicates in materialization
   procedure RenameField(FieldNo: Integer; NewName: WideString);
   // materialization routines
   procedure CreateIndexForMaterialize;
   procedure CreateTableForMaterializeFillFieldDefs;
   procedure CreateTableForMaterialize; virtual;
   function CheckDistinctAndCopyRecord(var ResultRecNo: Int64): Boolean;
   function IsRecordVisible: Boolean; virtual;
   procedure FillTableForMaterialize;
   // finish the materialization - applies projection, clear filters, expressions, etc.
   procedure FinalizeMaterialize;
   // clear filters, expressions, etc.
   procedure Clear(ResetFieldLinks, ClearAll: Boolean);
   // return true if materialization will create temporary table
   // and ApplyTop will copy the result data to table specified by
   // FResultTableName, FResultInMemory, FResultDatabaseName
   function IsApplyTopWillCopyToResultTable: Boolean;
   // TOP FTopRowCount [, FFirstRowNo]
   function IsTopApplied: Boolean; virtual;
   // returns true if TOP otpion can be applied in materialization process
   function IsTopCanBeAppliedInMaterialization: Boolean;
   // applies TOP option on materalized temporary table (FResultDataset)
   procedure ApplyTop;
   // initializes the materialization process - create objects
   procedure InitMaterialization; virtual;
   // materializes AO
   procedure DoMaterialize; virtual;
   // finalizes the materialization process - destroy objects
   procedure FinalizeMaterialization; virtual;
   // runs all necessary optimizations before executing AO
   procedure Optimize; virtual;

   // return true if binary record comparison will be used in materialziation
   function IsRecordComparisonNeeded: Boolean; virtual;
   procedure ChooseDistinctAlgorithm; virtual;
   function IsRecordMatchesDistinct: Boolean;
   function IsRecordMatchesDistinctByRecordHash: Boolean; virtual;
   function IsRecordMatchesDistinctByDestIndex: Boolean; virtual; abstract;
   function IsRecordMatchesDistinctBySourceIndex: Boolean; virtual; abstract;
  public
   destructor Destroy; override;
   // gets all result records
   procedure Execute(IsRootAO: Boolean = False); virtual;

   // sets filter
   procedure SetFilter(FilterExpr: TObject);
   // for SELECT INTO optimization
   procedure SetResultTable(InMemory: Boolean; TableName: WideString; DatabaseName: AnsiString);
   // sets Top row count
   procedure SetTopRowCount(FirstRowNo, TopRowCount: Integer);
   // applies distinct
   procedure ApplyDistinct;
   // sets projection for other TACRAO
   procedure SetResultFields(var FieldRefs: array of TACRSelectListItem;
                            bDistinct: Boolean); virtual;
   // mapping function - return number of found fields and found field No
   // also optionally unhides fields in AO
   function FieldExists(
                  FieldName, TableName: WideString;
                  Unhide:               Boolean;
                  FieldNumbers:         TACRIntegerArray = nil;
                  UnhideChildrenOnly:   Boolean = False
                      ): Integer; virtual;
   function GetFieldName(FieldNo: Integer; ApplyOrderBy: Boolean = False): WideString;
   // return DiplayName if it is not empty, otherwise - field name
   function GetResultFieldName(FieldNo: Integer): WideString;
   // return value (copy or direct pointer)
   procedure GetFieldValue(
                        Value:      TACRVariant;
                        FieldNo:        Integer;
                        bCopy:          Boolean = False;
                        AccessToHidden: Boolean = False
                        ); virtual;
   function GetFieldType(FieldNo: Integer): TACRAdvancedFieldType; overload;
   function GetFieldSize(FieldNo: Integer): Integer;
   function GetFieldPrecision(FieldNo: Integer): Integer;
   procedure LockTable(bWriteMode: Boolean); virtual;
   procedure UnlockTable; virtual;
   // sets index
  private
   procedure CreateResultIndexLists(ToClear: Boolean; NumFields: Integer = 0);
   procedure FreeResultIndexLists;
   procedure CheckIfProjectionNeededToHideOrderByField(FieldNo: Integer);
  public
   procedure SetOrderBy(
                       OrderBySpecs:          array of TACRSortSpecification;
                       OrderBySpecsCount:     integer;
                       OrderByIndex:          WideString // indexName
                      ); virtual;
  protected
   // enumerates all expressions
   function EnumAllExpressions(var ExprNo: Integer; SkipFieldLinks: Boolean; out ExprAO: TACRAO): TObject; virtual;
   // extract all TACRExprNodeConst objects from all expressions
   procedure ExtractAllParameterNodes(var NodeList: TACRList);
  public
   // move all parameter nodes from FParamNodes to NodeList
   procedure MoveParamNodes(NodeList: TACRList);
{$IFDEF CORRELATED_SUBQUERIES}
   // return true and fill FExternalFieldNodes list with field nodes from main query
   // if the query is correlated
   function FindExternalFieldNodes: Boolean;
   // assign field node to current AO / Cursor
   procedure AssignExternalFieldNodes(SubQueryAO: TACRAO);
   // setup cursor buffer in all external field nodes linked to SubQuery AO
   procedure SetCursorBufferInExternalFieldNodesLinkedToSubQueryAO;
   // set Cursor all external fields
   procedure SetExternalFieldNodesCursor(Cursor: TACRCursor);
   // set Buffer all external fields
   procedure SetExternalFieldNodesCursorBuffer(Buffer: TACRRecordBuffer);
   // find first result field, otherwise return -1
   function GetFirstResultFieldNo: Integer;
   // find first result field no in FResultDataset, otherwise return -1
   function GetFirstResultDatasetFieldNo: Integer;
   // this AO and all its children are used in sub-query
   procedure SetupSubQuery;
   // setup external field values
   procedure SetExternalFieldValues;
{$ENDIF}
{$IFDEF DEBUG_LOG}
    function GetName(Level: Integer = 0): AnsiString; virtual;
{$ENDIF}
   // added in v.6.00 for Views
   procedure GetTableNames(Session: TACRBaseSession; TableNames: TACRWideStringList); virtual;
   // reset result cursor of Root AO dataset - added in v.6.00 for Views
   procedure ResetRootAOCursorInResultDataset; virtual;
  protected
   // restart the materialization
   procedure SetRestartMaterialization(Value: Boolean); virtual;
   // saves materialization data for parametrized query to be able to restore it
   procedure SaveMaterializationData; virtual;
   // load materialization data for reopening parametrized query
   procedure LoadMaterializationData; virtual;
  public
   property RestartMaterialization: Boolean read FRestartMaterialization write SetRestartMaterialization;
   property IsMaterialized: Boolean read FIsMaterialized;
   property IsRootAO: Boolean read FIsRootAO;
   property FilterExpr: TObject read FFilterExpr; // TACRExpression
   property FieldCount: Integer read FFieldCount;
   property RecordCount: Integer read GetRecordCount;
   property ResultDataset: TDataset read FResultDataset;
   property Eof: Boolean read GetEof;
   property RequestLive: Boolean read FRequestLive;
   property TableName:  WideString read FTableName;
   property TableAlias: WideString read FTableAlias;
   property Session: TACRBaseSession read LSession;
   property Params: TACRSQLParams read LParams;
   property ParamNodes: TACRList read FParamNodes;
   property Parametrized: Boolean read FParametrized write FParametrized;
{$IFDEF CORRELATED_SUBQUERIES}
   property ExternalFieldNodes: TACRList read FExternalFieldNodes;
{$ENDIF}
   property CaseInsensitive: Boolean read FCaseInsensitive write FCaseInsensitive; // added in v.5.90
 end;

 // table
 TACRAOTable = class (TACRAO)
 private
  FSourceDataset: 								TDataset;
  FLive:          								Boolean; // if true - live query (updateable), else - read only
  FSystemTable:   								Boolean;
  FTableLocked:   								Boolean;
  FTableLockedInWriteMode:				Boolean;
  FMaterializationRequired:       Boolean;
  FInMemory:                      Boolean;
  FSessionName:                   AnsiString;
  FDatabaseName:                  AnsiString;
 protected
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  // optimizes filters before materialization -
  // moves all filter conditions assigned to cursor to the SQLFilter
  // applied to FSourceDataset before scanning records
  procedure OptimizeFiltersBeforeMaterialization;
  procedure CreateTableForMaterialize; override;
  // materializes AO
  procedure DoMaterialize; override;
  function InternalGetRecordCount: Integer; override;
  // enumerates all expressions
  function EnumAllExpressions(var ExprNo: Integer; SkipFieldLinks: Boolean; out ExprAO: TACRAO): TObject; override;
  // restart the materialization
  procedure SetRestartMaterialization(Value: Boolean); override;
  // saves materialization data for parametrized query to be able to restore it
  procedure SaveMaterializationData; override;
  // load materialization data for reopening parametrized query
  procedure LoadMaterializationData; override;
  // for GET TABLES / SELECT * FROM TABLES
  procedure PrepareSystemTableData;
  // added in v.6.00 for Views
  procedure GetTableNames(Session: TACRBaseSession; TableNames: TACRWideStringList); override;
 public
  constructor Create(
                      aSession:     TACRBaseSession;
                      aParams:      TACRSQLParams;
                      DatabaseName: AnsiString;
                      SessionName:  AnsiString;
                      TableName:    WideString;
                      TableAlias:   WideString;
                      SubQuerySQL:  WideString;
                      Params:       TParams;
                      bInMemory:    Boolean = false;
                      bRequestLive: Boolean = false;
                      bSystemTable: Boolean = false
                      );
  destructor Destroy; override;
  procedure LockTable(bWriteMode: Boolean); override;
  procedure UnlockTable; override;
  procedure SetOrderBy(
                       OrderBySpecs:          array of TACRSortSpecification;
                       OrderBySpecsCount:     integer;
                       OrderByIndex:          WideString // indexName
                      ); override;
  // reset result cursor of Root AO dataset - added in v.6.00 for Views
  procedure ResetRootAOCursorInResultDataset; override;
 public
  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
  property SourceDataset: TDataset read FSourceDataset;
 end;


 // joins and dekart
{ TODO -oLeo :
to version 5: make it single for all  joined datasets
to avoid unnecessary temporary materialization } 
 TACRAOJoin = class (TACRAO)
 private
  FDekart:            Boolean;
  FOuterJoin:         Boolean;
  FInnerJoin:         Boolean;
  FFirstTimeCalled:   Boolean; // true if Next called First time
  FEof:               Boolean; // Eof is set
  FIsNatural:         Boolean; // added in v.5.90 to make NATURAL JOIN like in standard: (t1.ID = t2.ID) -> ID
  FUsing:             Boolean; // added in v.5.90 to make JOIN with USING like in standard: (t1.ID = t2.ID) -> ID

  FJoinType:    TACRJoinType;
  FFields1:     TACRIntegerArray;
  FFields2:     TACRIntegerArray;

  // algorithm 2 (fast)
  FFieldNames1:                   TACRWideStringList;
  FFieldNames2:                   TACRWideStringList;
  FTempFilterExpr:                TObject;
  FScanTable:                     TDataset;
  FFilterTable:                   TDataset;
  FScanLeft:                      Boolean;
  FConstList:                     TList; // const nodes for filter
  FSearchingCorrespondingRecords: Boolean; // ScanTable
  FScanningRestRecords:           Boolean; // for full outer join
  FFilterApplied:                 Boolean;
  FScannedRecords:                TACRRecordIDArray;
  FFilterTableEmpty:              Boolean;

  // inner / outer joins
  FCompareResult:     TACRCompareResult;
  FBookmark:          Pointer;
  FEqualStarted:      Boolean; // true if equal values in both AO

 protected
  procedure CompareRecords;
  // algorithm #2: scannng first table with filtering second table
  function IsIndexExists(Table: TDataset; FieldNames: TACRWideStringList): Boolean;
  procedure ChooseScanTable;
  procedure BuildFilterExpression;
  procedure PrepareFilterForCurrentRecord;
  function ApplyFilterAndCheckIfRecordsFound: Boolean;
  procedure ClearFilter;
  procedure SetLeftNull;
  procedure SetRightNull;
  procedure SwitchToScanningRest;
  // full outer join stores record ID for all scanned records matching filters
  procedure StoreCurrentRecordID;
  procedure Init2;
  procedure InternalFirst2;
  procedure InternalNext2;
  function InternalGetEof2: Boolean;

  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;

  // finalizes the materialization process - destroy objects
  procedure FinalizeMaterialization; override;
  // mapping function - return number of found fields and found field No
  // also optionally unhides fields in AO
  function FieldExists(
                FieldName, TableName: WideString;
                Unhide:               Boolean;
                FieldNumbers:         TACRIntegerArray = nil;
                UnhideChildrenOnly:   Boolean = False
                    ): Integer; override;
 public
  constructor Create(
                      aSession:   TACRBaseSession;
                      aParams:    TACRSQLParams;
                      LeftChild:  TACRAO;
                      RightChild: TACRAO;
                      JoinType:   TACRJoinType;
                      IsNatural:  Boolean;
                      IsUsing:    Boolean;
                      FieldList1: TACRFields; // join fields
                      FieldList2: TACRFields  // field1 = field2
                      );
  destructor Destroy; override;

 public
  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
  property OuterJoin: Boolean read FOuterJoin;
  property JoinType: TACRJoinType read FJoinType;
 end; // TACRAOJoin


{ TODO -oLeo :
to version 5: make it single for all quries joined by UNION, EXCEPT, INTERSECT
and use TACRRecordComparison for records detection if possible }
 TACRAOUnion = class (TACRAO)
 private
  FUnionType:         TACRUnionType;
  FFields1:           TACRIntegerArray;
  FFields2:           TACRIntegerArray;
  FFirstTimeCalled:   Boolean; // true if Next called First time
  FShowLeft:          Boolean; // if then leftAO records will be added otherwise right
  //----------------------- used in EXCEPT and INTERSECT -----------------------
  FSearchAO:          TACRAO; // to search records
  FScanAO:            TACRAO; // to scan from first to last and
                              //  check if record exists / not exists in FRecordCRC
  FRecordCRCValues:   TACRIntegerArray;
  FValue:             TACRVariant;
 protected
  //------------- these methods are for Except and Intersect -------------------
  function CompareRecords: Boolean;
  procedure SearchRecord;
  procedure CalculateRecordCRCValues;
  //------------- these methods are for Except and Intersect -------------------

  procedure CreateFieldMaps(IsCorresponding, bDistinct: Boolean; FieldList: TACRFields);
  procedure ShowLeftAO;
  procedure ShowRightAO;
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;
 public
  constructor Create(
                      aSession:   TACRBaseSession;
                      aParams:    TACRSQLParams;
                      LeftChild:  TACRAO;
                      RightChild: TACRAO;
                      UnionType:   TACRUnionType;
                      IsCorresponding:  Boolean = False;
                      bDistinct: Boolean = True;
                      FieldList: TACRFields = nil // corresponding fields
                      );
  destructor Destroy; override;
 public
  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
 end; // TACRAOUnion - union, intersect, except

 // table expression
{ TODO -oLeo : 
to version 5: remove it completely and built this into TACRAO using TACRRecordComparison
expression should also support it (Load/Save aggregated values) } 
 TACRAOGroupBy = class (TACRAO)
 protected
  FAllFields:         Boolean;
  FFields:            TACRIntegerArray;
  FValues:            array of TACRVariant;
  FEof:               Boolean;
  FRecordCountOnly:   Boolean;
  FCountAllOnly:      Boolean;
 protected
  // return true if new group is started from current record
  function CompareRecords(bFirstTime: Boolean = false): Boolean;
  procedure Init;
  procedure Accumulate(Increment: Integer = 1);
  procedure ScanGroup;
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;
  procedure CheckFieldIsNotInGroupByList(FieldName, TableName: WideString);
 public
  procedure GetFieldValue(
                        Value:          TACRVariant;
                        FieldNo:        Integer;
                        bCopy:          Boolean = False;
                        AccessToHidden: Boolean = False
                        ); override;
  // sets projection
  procedure SetResultFields(var FieldRefs: array of TACRSelectListItem;
                      bDistinct: Boolean); override;
  constructor Create(
                     aSession:     TACRBaseSession;
                     aParams:      TACRSQLParams;
                     Child:        TACRAO;
                     FieldList:    TACRFields = nil // corresponding fields
                    );
  destructor Destroy; override;
 public
  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
 end;


 procedure ConvertListsToIndexFieldNames(
                var FieldNames:    WideString;
                var DescNames:     WideString;
                var CaseInsNames:  WideString;
                FieldList, AscDescList, CaseInsList:    TACRWideStringList
                );

implementation

uses ACRMain,ACRExpressions,ACRBaseEngine,ACRMemory;


////////////////////////////////////////////////////////////////////////////////
//
// TACRFields
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// creates
//------------------------------------------------------------------------------
constructor TACRFields.Create;
begin
 ItemCount := 0;
 CaseInsensitive := False;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRFields.Destroy;
begin
 Clear;
 inherited;
end; // Destroy;


//------------------------------------------------------------------------------
// add item to the end
//------------------------------------------------------------------------------
procedure TACRFields.Append(var Item: TACRSelectListItem);
begin
  Inc(ItemCount);
  SetLength(Items, ItemCount);
  Items[ItemCount-1] := Item;
end;// Append


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TACRFields.Clear;
var i: Integer;
begin
  for i := 0 to ItemCount-1 do
   begin
    if (Items[i].ValueExpr <> nil) then
     try
       TACRExpression(Items[i].ValueExpr).Free;
     except
     end;
    ACRClearString(Items[i].TableName);
    ACRClearString(Items[i].FieldName);
    ACRClearString(Items[i].Pseudonym);
   end;
  SetLength(Items,0);
end; //Clear


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRFields.Assign(Source: TACRFields);
var i: Integer;
begin
  if (Source = nil) then
    raise EACRException.Create(12196,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise EACRException.Create(12197,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  Clear;
  ItemCount := Source.ItemCount;
  SetLength(Items,ItemCount);
  for i := 0 to ItemCount - 1 do
   begin
    if (Source.Items[i].ValueExpr = nil) then
     Items[i].ValueExpr := nil
    else
     begin
      Items[i].ValueExpr := TACRExpression.Create;
      TACRExpression(Items[i].ValueExpr).CaseInsensitive := CaseInsensitive;
      TACRExpression(Items[i].ValueExpr).Assign(TACRExpression(Source.Items[i].ValueExpr));
     end;
    Items[i].TableName := Source.Items[i].TableName;
    Items[i].AllFields := Source.Items[i].AllFields;
    Items[i].FieldName := Source.Items[i].FieldName;
    Items[i].IsExpression := Source.Items[i].IsExpression;
    Items[i].Pseudonym := Source.Items[i].Pseudonym;
   end;
end; // Assign


//------------------------------------------------------------------------------
// update expression params in this node and all children
//------------------------------------------------------------------------------
procedure TACRFields.UpdateExpressionParams(
              LStoredFunction:  TObject;
              LSession:         TACRBaseSession;
              LParams:          TACRSQLParams
                                );
var i:    Integer;
    expr: TACRExpression;
begin
  for i := 0 to ItemCount-1 do
   begin
    expr := TACRExpression(Items[i].ValueExpr);
    if (expr <> nil) then
     begin
      expr.StoredFunction := LStoredFunction;
      expr.Session := LSession;
      expr.LocalParams := LParams;
     end;
   end;
end; // UpdateExpressionParams




////////////////////////////////////////////////////////////////////////////////
//
// TACRRecordComparison
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRRecordComparison.Create(NumFields: Integer; ApproximateRecordCount: Integer);
var allocBy: Integer;
begin
{$IFDEF HASH_ARRAY_RECORD_COMPARISON}
  allocBy := ApproximateRecordCount div 100;
  if (ApproximateRecordCount < 100) then      //<=
   allocBy := 100;
  FRecordHashValues := TACRHashArray.Create(0,allocBy);
{$ELSE}
  allocBy := ApproximateRecordCount div 10;
  if (ApproximateRecordCount <= 0) then
   allocBy := 1000;
  FRecordHashValues := TACRIntegerArray.Create(0,allocBy,allocBy*10);
{$ENDIF}
  FNumFields := NumFields;
  SetLength(FFieldHashValues,NumFields);
  FCurrentHashValue := 0;
end; // Destroy


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRRecordComparison.Destroy;
begin
  FFieldHashValues := nil;
  FRecordHashValues.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// add has of the field value to current hash
//------------------------------------------------------------------------------
procedure TACRRecordComparison.AddFieldHash(FieldValue: TACRVariant; FieldNo: Integer);
begin
  if (FieldNo < 0) or (FieldNo >= FNumFields) then
   raise EACRException.Create(11661, ErrorLInvalidItemNumber,[FieldNo,FNumFields]);
  FFieldHashValues[FieldNo] := FieldValue.GetBinaryHash;
end; // AddFieldHash


//------------------------------------------------------------------------------
// calculate current record hash
//------------------------------------------------------------------------------
procedure TACRRecordComparison.CalculateRecordHash;
var i: Integer;
    x: Cardinal;
begin
 // fixed in 4.98
 i := 1;
 x := FFieldHashValues[0];
 while (i < FNumFields) do
  begin
   x := ACRAddCRC(x,FFieldHashValues[i],i);
   Inc(i);
  end;
 FCurrentHashValue := x;
end; // CalculateRecordHash


//------------------------------------------------------------------------------
// appends current record hash
//------------------------------------------------------------------------------
function TACRRecordComparison.AppendRecordHash: Boolean;
begin
{$IFDEF HASH_ARRAY_RECORD_COMPARISON}
  Result := FRecordHashValues.Append(FCurrentHashValue);
{$ELSE}
  Result := (FRecordHashValues.IndexOf(Integer(FCurrentHashValue)) < 0);
  if (Result) then
   FRecordHashValues.Append(Integer(FCurrentHashValue));
{$ENDIF}
end; // AppendRecordHash


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLOptimizer
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRSQLOptimizer.Create(AO: TACRAO);
begin
  LAO := AO;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRSQLOptimizer.Destroy;
begin
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// run all possible optimizations for the root AO and all its children
//------------------------------------------------------------------------------
procedure TACRSQLOptimizer.OptimizeAll;
begin
  OptimizeFilters;
end; // OptimizeAll


//------------------------------------------------------------------------------
// optimize filters
//------------------------------------------------------------------------------
procedure TACRSQLOptimizer.OptimizeFilters;
begin

end; // OptimizeFilters


////////////////////////////////////////////////////////////////////////////////
//
// TACRAO
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TACRAO.InternalCreate(
                      Session:      TACRBaseSession;
                      Params:       TACRSQLParams;
                      LeftAO:       TACRAO;
                      RightAO:      TACRAO;
                      TableName:    WideString;
                      TableAlias:   WideString;
                      SubQuerySQL:  WideString
                      );
begin
  LSession := Session;
  LParams := Params;
  if (Length(SubQuerySQL) <= 0) then
   FResultDataset := TACRTable.Create(nil)
  else
   begin
    // commented in v.5.80
//    if (Length(TableAlias) <= 0) then
//     raise EACRException.Create(11655,ErrorLSubQueryTableMustHaveAlias+SubQuerySQL);
    FResultDataset := TACRQuery.Create(nil);
    TACRQuery(FResultDataset).SQL.Text := SubQuerySQL;
   end;
  FActivateIndexAfterMaterialize := False;
  FAllFieldsNull := False;
  FResultIndexName := '';
  FRequestLive := False;
  FIsRootAO := False;
  FIsAOTable := False;
  FIsAOGroupBy := False;
  FTableName := TableName;
  FTableAlias := TableAlias;
  FLeftAO := LeftAO;
  FRightAO := RightAO;
  FResultFieldsOrder := TACRIntegerArray.Create(0,1,100);
  FIsMaterialized := False;
  FFieldCount := 0;
  FLeftAONull := False;
  FRightAONull := False;
  FDistinctApplied := False;
  FDistinctFields := '';
  FDistinctAlgorithm := adaNone;
  FFilterExpr := nil;
  FTopRowCount := -1;
  FFirstRowNo := -1;
  FExpressionsExists := False;
  FAggregateExpressionsExists := False;
  FResultIndexFieldsList := nil;
  FResultIndexAscDescFieldsList := nil;
  FResultIndexCaseInsFieldsList := nil;
  FResultIndexFieldNumbers := nil;
  FResultTableName := '';
  FResultDatabaseName := '';
  FResultInMemory := False;
  FRecordComparison := nil;
  FFieldValue := nil;
  FDistinctFieldValues := nil;
  FIndexFieldNames := '';
  FDescFields := '';
  FCaseInsensitiveFields := '';
  FSQLOptimizer := nil;
  FNotFilterExpression := False;
  FTopApplied := False;
  FTopInside := False;
  FApplyTopWillCopyToResultTable := False;
  FParametrized := False;
  FParamNodes := nil;
  FMaterializationDataSaved := False;
  FRestartMaterialization := False;
  FSavedFieldLinks := nil;
  FSavedSourceDatasetFilter := nil;
{$IFDEF CORRELATED_SUBQUERIES}
  FExternalFieldNodes := nil;
  FExternalConstNodes := nil;
  FSubQuery := False;
  FExternalFieldNodesLinkedToSubQueryAO := nil;
{$ENDIF}
end; // InternalCreate


//------------------------------------------------------------------------------
// go to first record
//------------------------------------------------------------------------------
procedure TACRAO.InternalFirst;
begin
;
end; // First


//------------------------------------------------------------------------------
// go to next record
//------------------------------------------------------------------------------
procedure TACRAO.InternalNext;
begin
;
end; // Next


//------------------------------------------------------------------------------
// return true if cursor points to the last record
//------------------------------------------------------------------------------
function TACRAO.InternalGetEof: Boolean;
begin
 Result := False;
end; // InternalGetEof


//------------------------------------------------------------------------------
// return number of records
//------------------------------------------------------------------------------
function TACRAO.InternalGetRecordCount: Integer;
begin
 Result := 0;
 if (FIsMaterialized) then
   Result := FResultDataset.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// go to first record
//------------------------------------------------------------------------------
procedure TACRAO.First;
begin
  if (FIsMaterialized) then
    FResultDataset.First
  else
    InternalFirst;
end; // First


//------------------------------------------------------------------------------
// go to next record
//------------------------------------------------------------------------------
procedure TACRAO.Next;
begin
  if (FIsMaterialized) then
    FResultDataset.Next
  else
    InternalNext;
end; // Next


//------------------------------------------------------------------------------
// return true if cursor points to the last record
//------------------------------------------------------------------------------
function TACRAO.GetEof: Boolean;
begin
  if (FIsMaterialized) then
    Result := FResultDataset.Eof
  else
    Result := InternalGetEof;
end; // GetEof


//------------------------------------------------------------------------------
// return number of records
//------------------------------------------------------------------------------
function TACRAO.GetRecordCount: Integer;
begin
  if (FIsMaterialized) then
    Result := FResultDataset.RecordCount
  else
    Result := InternalGetRecordCount;
end; // GetRecordCount


//------------------------------------------------------------------------------
// sets names to FieldLinks list and renames duplicate names
//------------------------------------------------------------------------------
procedure TACRAO.SetFieldNames;
var i,j,k:    Integer;
    name,s:   WideString;
    bOk:      Boolean;
begin
  for i := 0 to FFieldCount-1 do
    begin
      FFieldLinks[i].FieldName := GetFieldName(i);
      // renaming fields without name (calculated, expressions...)
      if (FFieldLinks[i].FieldName = '') then
        FFieldLinks[i].FieldName := GetTemporaryName(ACRExpressionFieldName);
    end;
end;


//------------------------------------------------------------------------------
// rename field to avoid duplicates in materialization
//------------------------------------------------------------------------------
procedure TACRAO.RenameField(FieldNo: Integer; NewName: WideString);
var i: Integer;
begin
  FFieldLinks[FieldNo].DisplayName := NewName;
  // fix names in result index
  if (FResultIndexFieldsList <> nil) then
   begin
    for i := 0 to FResultIndexFieldsList.Count-1 do
     begin
       if (FResultIndexFieldNumbers.Items[i] = FieldNo) then
        FResultIndexFieldsList[i] := NewName;
     end;
   end;
end; // RenameField


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TACRAO.CreateIndexForMaterialize;
var IndexDef:                            TIndexDef;
    FieldNames, DescNames, CaseInsNames: WideString;
    IndexName:                           WideString;
begin
  ConvertListsToIndexFieldNames(FieldNames,DescNames,CaseInsNames,
    FResultIndexFieldsList,FResultIndexAscDescFieldsList,
    FResultIndexCaseInsFieldsList);
  repeat
    IndexName := GetTemporaryName(ACRTemporaryTableIndexName);
  until (TACRTable(FResultDataset).IndexDefs.IndexOf(IndexName) = -1);
  IndexDef := TACRTable(FResultDataset).IndexDefs.AddIndexDef;
  IndexDef.Name := IndexName;
  IndexDef.Fields := FieldNames;
  IndexDef.DescFields := DescNames;
  IndexDef.CaseInsFields := CaseInsNames;
  IndexDef.Options := [];
end; // CreateIndexForMaterialize


procedure TACRAO.CreateTableForMaterializeFillFieldDefs;
var i:  Integer;

 procedure AddFieldDef(FieldNo: Integer);
 var FieldDef:   TACRAdvFieldDef;
     name:       WideString;
     tName:      WideString;
     s:          WideString;
     i,n:        Integer;
 begin
  FieldDef := TACRTable(FResultDataset).AdvFieldDefs.AddFieldDef;
  if (Length(FFieldLinks[FieldNo].DisplayName) > 0) then
     name := FFieldLinks[FieldNo].DisplayName
  else
     name := FFieldLinks[FieldNo].FieldName;
  n := 0;
  s := name;
  while (TACRTable(FResultDataset).AdvFieldDefs.Find(s) <> nil) do
    begin
     if (FFieldLinks[FieldNo].TableAlias <> '') then
      tName := FFieldLinks[FieldNo].TableAlias
     else
      tName := FFieldLinks[FieldNo].TableName;
     if (n = 0) then
      s := tName + '_' + name
     else
      s := tName + '_' + name + '_' + IntToStr(n);
     Inc(n);
    end;
  if (n > 0) then
   RenameField(FieldNo,s);
  FieldDef.Name := s;
  if (IsAutoincFieldType(FFieldLinks[FieldNo].FieldType)) then
   FieldDef.DataType := BaseFieldTypeToAdvancedFieldType(AdvancedFieldTypeToBaseFieldType(FFieldLinks[FieldNo].FieldType))
  else
   FieldDef.DataType := FFieldLinks[FieldNo].FieldType;
  FieldDef.Size := FFieldLinks[FieldNo].FieldSize;
  FieldDef.BLOBCompressionAlgorithm :=
    TCompressionAlgorithm(FFieldLinks[FieldNo].BLOBCompressionAlgorithm);
  FieldDef.BLOBCompressionMode := FFieldLinks[FieldNo].BLOBCompressionMode;
  FieldDef.BLOBBlockSize := FFieldLinks[FieldNo].BLOBBlockSize;
 end; // AddFieldDef

begin
 for i := 0 to FResultFieldsOrder.ItemCount-1 do
  AddFieldDef(FResultFieldsOrder.Items[i]);
end; // CreateTableForMaterializeFillFields


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TACRAO.CreateTableForMaterialize;
var
    IndexName:  WideString;
begin
{$IFDEF DEBUG_TRACE_TACRAO_CreateTableForMaterialize}
aaWriteToLog('> TACRAO.CreateTableForMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
+#13#10+'FIsMaterialized = '+BoolToStr(FIsMaterialized,True)
);
{$ENDIF}
   if TACRTable(FResultDataset).Active then
   begin
    TACRTable(FResultDataset).Handle.SQLFilterExpression := nil;
    TACRTable(FResultDataset).Close;
   end;
   // prepare field defs
   TACRTable(FResultDataset).ClearDefinitions;
   CreateTableForMaterializeFillFieldDefs;
   // create table
   if ((FResultTableName <> '') and (not FApplyTopWillCopyToResultTable)) then
    begin
     TACRTable(FResultDataset).InMemory := FResultInMemory;
     TACRTable(FResultDataset).DatabaseName := FResultDatabaseName;
     TACRTable(FResultDataset).Temporary := False;
     TACRTable(FResultDataset).TableName := FResultTableName;
    end // result table
   else
    begin
     TACRTable(FResultDataset).InMemory := False;
     TACRTable(FResultDataset).Temporary := True;
// commented in v.4.60 - as there is no need to set table name, it is already done
// by TACRTempDatabaseData.CreateTableData
{
     repeat
      TACRTable(FResultDataset).TableName := GetTemporaryName(ACRTemporaryTableName);
     until (not TACRTable(FResultDataset).Exists);
}
    end; // temporary table
{$IFDEF DEBUG_TRACE_TACRAO_CreateTableForMaterialize}
aaWriteToLog('1 TACRAO.CreateTableForMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
+#13#10+'FIsMaterialized = '+BoolToStr(FIsMaterialized,True)
);
{$ENDIF}
   if (FResultIndexFieldsList <> nil) then
     CreateIndexForMaterialize;
{$IFDEF DEBUG_TRACE_TACRAO_CreateTableForMaterialize}
aaWriteToLog('2 TACRAO.CreateTableForMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
+#13#10+'FIsMaterialized = '+BoolToStr(FIsMaterialized,True)
);
{$ENDIF}
   // fixed in v.5.30
   TACRTable(FResultDataset).IndexName := '';
   // added in v.5.90
   TACRTable(FResultDataset).CaseInsensitive := FCaseInsensitive;
   TACRTable(FResultDataset).CreateTable;
{$IFDEF DEBUG_TRACE_TACRAO_CreateTableForMaterialize}
aaWriteToLog('3 TACRAO.CreateTableForMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
+#13#10+'FIsMaterialized = '+BoolToStr(FIsMaterialized,True)
);
{$ENDIF}
   TACRTable(FResultDataset).Open;
{$IFDEF DEBUG_TRACE_TACRAO_CreateTableForMaterialize}
aaWriteToLog('< TACRAO.CreateTableForMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
+#13#10+'FIsMaterialized = '+BoolToStr(FIsMaterialized,True)
);
{$ENDIF}
end; // CreateTableForMaterialize


//------------------------------------------------------------------------------
// checks distinct if applied and copies record from AO to FResultDataset
// return true if record matches distinct and is copied to FResultDataset
//------------------------------------------------------------------------------
function TACRAO.CheckDistinctAndCopyRecord(var ResultRecNo: Int64): Boolean;
var i,j,FieldNo : Integer;
begin
  Result := False;
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time3);
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('> TACRAO.CheckDistinctAndCopyRecord'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
try
{$ENDIF}
case FDistinctAlgorithm of
   adaNone:
     begin
       if (FTopInside and (FFirstRowNo >= 0)) then
        begin
          Inc(ResultRecNo);
          if (ResultRecNo < FFirstRowNo) then
            Exit;
        end;
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: before Insert'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
       TACRDataset(FResultDataset).Insert;
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: after Insert'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
       // not result table
       for i := 0 to FResultFieldsOrder.ItemCount-1 do
        begin
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: before GetFieldValue'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FResultFieldsOrder.Items[i])
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
         // get field value
         GetFieldValue(FFieldValue,FResultFieldsOrder.Items[i],false,true);
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: after GetFieldValue'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FResultFieldsOrder.Items[i])
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time4);
aaIncCounter(counter4);
{$ENDIF}
         // set value
         TACRDataset(FResultDataset).SetFieldValue(FFieldValue,i,False);
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time4);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: after SetFieldValue'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FResultFieldsOrder.Items[i])
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
         FFieldValue.SetNull;
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: after SetNull'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FResultFieldsOrder.Items[i])
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
        end; // not result table
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: before Post'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time5);
aaIncCounter(counter5);
{$ENDIF}
       // insert record
       TACRDataset(FResultDataset).Post;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time5);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaNone: after Post'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
       Result := True;
     end; // adaNone
   adaByRecordHash:
     begin
       // not result table
      for i := 0 to FResultFieldsOrder.ItemCount-1 do
       begin
         FieldNo := FResultFieldsOrder.Items[i];
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaByRecordHash: before GetFieldValue'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
         // get field value
         GetFieldValue(FDistinctFieldValues[i],FieldNo,false,true);
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaByRecordHash: after GetFieldValue'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
         // caclulate its hash
         if (i < FResultFieldCount) then
          FRecordComparison.AddFieldHash(FDistinctFieldValues[i],FieldNo);
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaByRecordHash: after AddFieldHash'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
        end; // not result table
       // insert record
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaByRecordHash: before Post'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
       if (IsRecordMatchesDistinct) then
        begin
         if (FTopInside and (FFirstRowNo >= 0)) then
          begin
            Inc(ResultRecNo);
            if (ResultRecNo < FFirstRowNo) then
              Exit;
          end;
         TACRDataset(FResultDataset).Insert;
         for i := 0 to FResultFieldsOrder.ItemCount-1 do
           TACRDataset(FResultDataset).SetFieldValue(FDistinctFieldValues[i],i,False);
         TACRDataset(FResultDataset).Post;
         Result := True;
        end;
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaByRecordHash: after Post'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
       for i := 0 to FResultFieldsOrder.ItemCount-1 do
        FDistinctFieldValues[i].SetNull;
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
aaWriteToLog('TACRAO.CheckDistinctAndCopyRecord - adaByRecordHash: after SetNull'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
{$ENDIF}
     end; // adaByRecordHash
  end; // distinct algorithm
{$IFDEF DEBUG_TRACE_TACRAO_CheckDistinctAndCopyRecord}
finally
aaWriteToLog('< TACRAO.CheckDistinctAndCopyRecord'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'ResultRecNo = '+IntToStr(ResultRecNo)
+#13#10+'FDistinctAlgorithm = '+IntToStr(Integer(FDistinctAlgorithm))
);
end;
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
finally
aaStopTime(time3);
end;
{$ENDIF}
end; // CheckDistinctAndCopyRecord


//------------------------------------------------------------------------------
// return true if current record matches all filters so it is visble
// and will be inserted to result dataset
//------------------------------------------------------------------------------
function TACRAO.IsRecordVisible: Boolean;
begin
  if (FFilterExpr = nil) then
  begin
   Result := True;
{$IFDEF DEBUG_TRACE_TACRAO_IsRecordVisible}
aaWriteToLog('< TACRAO.IsRecordVisible'+#13#10+GetName+#13#10+'Result = True, NO FILTER');
{$ENDIF}
  end
  else
   begin
    if (FNotFilterExpression) then
     Result := not TACRExpression(FFilterExpr).GetResult
    else
     Result := TACRExpression(FFilterExpr).GetResult;
{$IFDEF DEBUG_TRACE_TACRAO_IsRecordVisible}
aaWriteToLog('< TACRAO.IsRecordVisible'+#13#10+GetName+#13#10+'Result = '+BoolToStr(Result,True)+#13#10+'FFilterExpr = '+IntToHex(Integer(FFilterExpr),8)+#13#10+'FNotFilterExpression = '+BoolToStr(FNotFilterExpression,True));
{$ENDIF}
   end;
end; // IsCurrentRecordVisible


//------------------------------------------------------------------------------
// fill table
//------------------------------------------------------------------------------
procedure TACRAO.FillTableForMaterialize;
var i,j,d,n,dc:       Integer;
    bOK,Res:          Boolean;
    k,q:              Int64;
begin
 // filling table with data
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
aaWriteToLog('> TACRAO.FillTableForMaterialize.'
+#13#10+GetName
);
try
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time9);
{$ENDIF}
 First;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time9);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
aaWriteToLog('TACRAO.FillTableForMaterialize - after First'
+#13#10+GetName
);
{$ENDIF}
 k := 0; // FFirstRowNo start with 1, but first compare will Inc it before checking
 q := 0;
 while Not Eof do
  begin
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
aaWriteToLog('TACRAO.FillTableForMaterialize - beginning of the main loop'
+#13#10+GetName
+#13#10+'q = '+IntToStr(q)
+#13#10+'k = '+IntToStr(k)
+#13#10+'FTopRowCount = '+IntToStr(FTopRowCount)
+#13#10+'FTopInside = '+BoolToStr(FTopInside,True)
);
{$ENDIF}
   // check TOP n?
   if (FTopInside and (FTopRowCount >= 0)) then
    begin
      if (q >= FTopRowCount) then
       break;
    end;
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time10);
{$ENDIF}
   Res := IsRecordVisible;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time10);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
aaWriteToLog('TACRAO.FillTableForMaterialize - after IsRecordVisible'
+#13#10+GetName
+#13#10+'q = '+IntToStr(q)
+#13#10+'k = '+IntToStr(k)
+#13#10+'FTopRowCount = '+IntToStr(FTopRowCount)
+#13#10+'FTopInside = '+BoolToStr(FTopInside,True)
+#13#10+'Visible = '+BoolToStr(Res,True)
);
{$ENDIF}
   if (not Res) then
    begin
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time9);
{$ENDIF}
      Next;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time9);
{$ENDIF}
      Continue;
    end;
   if (CheckDistinctAndCopyRecord(k)) then
    Inc(q);
   // go to next record
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
aaWriteToLog('TACRAO.FillTableForMaterialize - before Next'
+#13#10+GetName
+#13#10+'q = '+IntToStr(q)
+#13#10+'k = '+IntToStr(k));
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time9);
{$ENDIF}
   Next;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time9);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
aaWriteToLog('TACRAO.FillTableForMaterialize - after Next'
+#13#10+GetName
+#13#10+'q = '+IntToStr(q)
+#13#10+'k = '+IntToStr(k));
{$ENDIF}
  end; // enf of inserting records loop
{$IFDEF DEBUG_TRACE_TACRAO_FillTableForMaterialize}
finally
aaWriteToLog('< TACRAO.FillTableForMaterialize.'
+#13#10+GetName
);
end;
{$ENDIF}

end; // FillTableForMaterialize


//------------------------------------------------------------------------------
// finalize materialize
//------------------------------------------------------------------------------
procedure TACRAO.FinalizeMaterialize;
var i,j:        Integer;
   IndexName:   WideString;
   FieldList:   TACRWideStringList;
begin
 if ((FResultIndexFieldsList <> nil) and (FActivateIndexAfterMaterialize)) then
  begin
   if (FResultDataset <> nil) then
    if (FResultDataset is TACRTable) then
     begin
       if (TACRTable(FResultDataset).IndexDefs.Count <> 1) then
        raise EACRException.Create(11385,ErrorLInvalidIndexCount,[TACRTable(FResultDataset).IndexDefs.Count]);
       IndexName := TACRTable(FResultDataset).IndexDefs[0].Name;
       TACRTable(FResultDataset).IndexName := IndexName;
     end;
  end;
  // apply projection to hide ORDER BY fields that are not specified in SELECT field list
  if ((FResultFieldCount > 0) and (FResultFieldCount < FResultFieldsOrder.ItemCount)) then
   begin
    FieldList := TACRWideStringList.Create;
    try
      for i := 0 to FResultFieldCount-1 do
       FieldList.Add(FFieldLinks[FResultFieldsOrder.Items[i]].DisplayName);
      TACRDataSet(FResultDataset).ApplyProjection(FieldList,FieldList);
    finally
      FieldList.Free;
    end;
   end;

// Clear objects moved lower
 if (FApplyTopWillCopyToResultTable and (not FTopApplied)) then
  begin
   // result index is created, so we must copy all records in correct order
   // to table specified by FResultTableName to provide correct SELECT INTO
   FFirstRowNo := 1;
   FTopRowCount := TACRDataset(FResultDataset).Handle.RecordCount;
   ApplyTop;
  end
 else
 if (FTopApplied and (not FTopInside)) then
   ApplyTop;
 FIsMaterialized := True;
// Clear((FResultFieldCount <= 0),False);
 // changed in v.5
{$IFDEF CORRELATED_SUBQUERIES}
 Clear((not FIsRootAO) or FSubQuery,False);
{$ELSE}
 Clear((not FIsRootAO),False);
{$ENDIF}
end; // FinalizeMaterialize


//------------------------------------------------------------------------------
// clear all expressions, fieldlinks, child AO, etc.
// used in destroy and after materialization none-parametrized query
//------------------------------------------------------------------------------
procedure TACRAO.Clear(ResetFieldLinks, ClearAll: Boolean);
var i,j: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('> TACRAO.Clear - ClassName = '+Self.ClassName
+#13#10+'Reset = '+BoolToStr(ResetFieldLinks,True)
+#13#10+'ClearAll = '+BoolToStr(ClearAll,True));
{$ENDIF}
 j := 0;
 if (not (FParametrized and ClearAll)) then
 for i := 0 to FFieldCount-1 do
  begin
   if (FParametrized) then
    // parametrized query already saved this pointer - it will be freed in
    // Clear(false,true) called from Destroy
    FFieldLinks[i].Expr := nil
   else
     if (FFieldLinks[i].IsExpression) then
      if (FFieldLinks[i].Expr <> nil) then
       try
        TACRExpression(FFieldLinks[i].Expr).Free;
        FFieldLinks[i].Expr := nil;
       except
        FFieldLinks[i].Expr := nil;
       end;
   if (FFieldLinks[i].IsHidden) then continue;
   if (ResetFieldLinks) then
    begin
     FFieldLinks[i].AO := nil;
     FFieldLinks[i].IsExpression := False;
     FFieldLinks[i].IsAggregate := False;
     FFieldLinks[i].Expr := nil;
     FFieldLinks[i].Dataset := FResultDataset;
     if (FResultFieldsOrder.ItemCount > 0) then
       FFieldLinks[i].FieldNo := FResultFieldsOrder.IndexOf(i)
     else
      begin
       FFieldLinks[i].FieldNo := j;
       inc(j);
      end;
    end;
  end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 1 - ClassName = '+Self.ClassName);
{$ENDIF}
 //---------------------- destroy child operations -----------------------------
 if ((not FParametrized) or (ClearAll)) then
  begin
   if (Self is TACRAOJoin) then
    TACRAOJoin(Self).ClearFilter;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 2 - ClassName = '+Self.ClassName);
{$ENDIF}
   if (FLeftAO <> nil) then
    begin
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear - calling FLeftAO.Free...');
aaWriteToLog('FLeftAO.ClassName = '+FLeftAO.ClassName);
{$ENDIF}
      FLeftAO.Free;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear - calling FLeftAO.Free...OK');
{$ENDIF}
    end;
   if (FRightAO <> nil) then
    begin
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear - calling FRightAO.Free...');
aaWriteToLog('FRightAO.ClassName = '+FRightAO.ClassName);
{$ENDIF}
      FRightAO.Free;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
  aaWriteToLog('TACRAO.Clear - calling FRightAO.Free...OK');
{$ENDIF}
    end;
   FRightAO := nil;
   FLeftAO := nil;
  end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 3 - ClassName = '+Self.ClassName+#13#10+'FFieldCount = '+IntToStr(FFieldCount));
{$ENDIF}
 if (ClearAll) then
  begin
    if (FSavedFieldLinks <> nil) then
     begin
      for i := 0 to FFieldCount-1 do
        begin
         if (FSavedFieldLinks[i].IsExpression) then
          if (FSavedFieldLinks[i].Expr <> nil) then
           try
            TACRExpression(FSavedFieldLinks[i].Expr).Free;
            FSavedFieldLinks[i].Expr := nil;
           except
           end;
        end;
      FSavedFieldLinks := nil;
     end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 4 - ClassName = '+Self.ClassName);
{$ENDIF}
    if (FParamNodes <> nil) then
     begin
      FParamNodes.Free;
      FParamNodes := nil;
     end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 4.1 - ClassName = '+Self.ClassName);
{$ENDIF}
{$IFDEF CORRELATED_SUBQUERIES}
    if (FExternalFieldNodes <> nil) then
     begin
      // destroy unlinked field nodes
      for i := 0 to FExternalFieldNodes.Count-1 do
       TACRExprNode(FExternalFieldNodes.Items[i]).Free;
      FExternalFieldNodes.Free;
      FExternalFieldNodes := nil;
     end;
    if (FExternalConstNodes <> nil) then
     begin
      FExternalConstNodes.Free;
      FExternalConstNodes := nil;
     end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 5 - ClassName = '+Self.ClassName);
{$ENDIF}
    if (FFilterExpr <> nil) then
     begin
      TACRExpression(FFilterExpr).Free;
      FFilterExpr := nil;
     end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 6 - ClassName = '+Self.ClassName);
{$ENDIF}
    // destroy
    FFieldLinks := nil;
    if (FResultDataset <> nil) then
     begin
      FResultDataset.Free;
      FResultDataset := nil;
     end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 7 - ClassName = '+Self.ClassName);
{$ENDIF}
    if (FResultFieldsOrder <> nil) then
      FResultFieldsOrder.Free;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 8 - ClassName = '+Self.ClassName);
{$ENDIF}
    FreeResultIndexLists;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('TACRAO.Clear 9 - ClassName = '+Self.ClassName);
{$ENDIF}
    if (FSQLOptimizer <> nil) then
     FSQLOptimizer.Free;
  end;
{$IFDEF DEBUG_TRACE_TACRAO_Clear}
aaWriteToLog('< TACRAO.Clear - ClassName = '+Self.ClassName
+#13#10+'Reset = '+BoolToStr(ResetFieldLinks,True)
+#13#10+'ClearAll = '+BoolToStr(ClearAll,True));
{$ENDIF}
end; // Clear


//------------------------------------------------------------------------------
// return true if materialization will create temporary table
// and ApplyTop will copy the result data to table specified by
// FResultTableName, FResultInMemory, FResultDatabaseName
//------------------------------------------------------------------------------
function TACRAO.IsApplyTopWillCopyToResultTable: Boolean;
begin
  Result := (FResultTableName <> '');
  if (Result) then
   Result := (
              (FTopApplied and (not FTopInside)) or
              (FResultIndexFieldsList <> nil)
             );
end; // IsApplyTopWillCopyToResultTable


//------------------------------------------------------------------------------
// TOP FTopRowCount [, FFirstRowNo]
//------------------------------------------------------------------------------
function TACRAO.IsTopApplied: Boolean;
begin
 Result := ((FTopRowCount > -1) or (FFirstRowNo > -1));
end; // IsTopApplied


//------------------------------------------------------------------------------
// returns true if TOP otpion can be applied in materialization process
//------------------------------------------------------------------------------
function TACRAO.IsTopCanBeAppliedInMaterialization: Boolean;
begin
  Result := (FResultIndexFieldsList = nil);
end; // IsTopCanBeAppliedInMaterialization


//------------------------------------------------------------------------------
// applies TOP option on materalized temporary table (FResultDataset):
// creates new temporary table with only visible fields and without any index
// and copies data from FResultDataset
//------------------------------------------------------------------------------
procedure TACRAO.ApplyTop;
var ResultTable:      TACRTable;
    value:            TACRVariant;
    i:                Integer;
    k,n:              Int64;
    visibleFieldDefs: TACRFieldDefs;
begin
 value := TACRVariant.Create();
 visibleFieldDefs := TACRCursor(TACRDataSet(FResultDataset).Handle).VisibleFieldDefs;
 try
   ResultTable := TACRTable.Create(nil);
   try
     // prepare field defs
     ResultTable.FieldDefs.Clear;
     ResultTable.IndexDefs.Clear;
     ResultTable.AdvFieldDefs.Clear;
     ResultTable.AdvIndexDefs.Clear;
     ResultTable.ForeignKeyDefs.Clear;
     if (FApplyTopWillCopyToResultTable) then
      begin
       // result table is table specified by FResultTableName
       TACRTable(ResultTable).InMemory := FResultInMemory;
       TACRTable(ResultTable).DatabaseName := FResultDatabaseName;
       TACRTable(ResultTable).Temporary := False;
       TACRTable(ResultTable).TableName := FResultTableName;
      end
     else
      begin
       // result table is temporary table
       ResultTable.InMemory := False;
       ResultTable.Temporary := True;
      end;
     ConvertACRFieldDefsToAdvFieldDefs(
      visibleFieldDefs,
      TACRCursor(TACRDataSet(FResultDataset).Handle).FieldDefs,
      TACRCursor(TACRDataSet(FResultDataset).Handle).ConstraintDefs,
      ResultTable.AdvFieldDefs
     );
     ResultTable.CreateTable;
     ResultTable.Open;
     FResultDataset.First;
     k := 0;
     n := 0;
     while (not FResultDataset.Eof) do
      begin
       inc(k);
       if (FTopRowCount >= 0) then
        if (n >= FTopRowCount) then
         break;
       if (((FFirstRowNo >= 0) and (k >= FFirstRowNo))
          or (FFirstRowNo < 0)) then
        begin
         ResultTable.Insert;
         for i := 0 to visibleFieldDefs.count-1 do
          begin
           TACRDataset(FResultDataset).GetFieldValue(value,i,false,false);
           ResultTable.SetFieldValue(value,i,False);
          end;
         ResultTable.Post;
         inc(n);
        end;
       FResultDataset.Next;
      end;
     FResultDataset.Free;
     FResultDataset := ResultTable; 
   except
     on e: Exception do
      begin
       ResultTable.Free;
       raise;
      end;
   end;
 finally
   value.Free;
 end;
end; // ApplyTop


//------------------------------------------------------------------------------
// initializes the materialization process
//------------------------------------------------------------------------------
procedure TACRAO.InitMaterialization;
var i,j:  Integer;
begin
  if (FDistinctApplied) then
   ChooseDistinctAlgorithm
  else
   FFieldValue := TACRVariant.Create;
  // search for all fields that should be in materialized table, but not in SELECT fields list
  if (FResultFieldCount = 0) then
   begin
    // all visible fields should be in result table
    for i := 0 to FFieldCount-1 do
     if (not FFieldLinks[i].IsHidden) then
       FResultFieldsOrder.Append(i);
   end;
{
  else
   begin
    for i := 0 to FFieldCount-1 do
     if (not FFieldLinks[i].IsHidden) then
       FResultFieldsOrder.Append(i);
   end;
}

{
  if (FResultFieldsOrder.ItemCount > 0) then
   begin
    // result table - fields will be in result order
    FVisibleFieldCount := FResultFieldsOrder.ItemCount;
    FResultFieldCount := FVisibleFieldCount;
    SetLength(FSourceFieldNumbers,FVisibleFieldCount);
    for i := 0 to FVisibleFieldCount-1 do
     begin
      j := FResultFieldsOrder.Items[i];
      if (FFieldLinks[j].IsHidden) then
        raise EACRException.Create(10312,ErrorLCannotAccessHiddenField,[FTableName,
                FFieldLinks[j].FieldName,FFieldLinks[j].DisplayName,j]);
      FSourceFieldNumbers[i] := j;
     end;
   end
  else
   begin
    FResultFieldCount := 0;
    FVisibleFieldCount := 0;
    SetLength(FSourceFieldNumbers,FFieldCount);
    for i := 0 to FFieldCount-1 do
      begin
        if (not FFieldLinks[i].IsHidden) then
         begin
          FSourceFieldNumbers[FVisibleFieldCount] := i;
          Inc(FVisibleFieldCount);
         end;
      end;
   end;
}
  if (FDistinctAlgorithm <> adaNone) then
   begin
    SetLength(FDistinctFieldValues,FResultFieldsOrder.ItemCount);
    for i := 0 to FResultFieldsOrder.ItemCount-1 do
     FDistinctFieldValues[i] := TACRVariant.Create;
   end;
  if (IsRecordComparisonNeeded) then
    FRecordComparison := TACRRecordComparison.Create(FFieldCount,GetRecordCount);
 FTopApplied := IsTopApplied;
 if (FTopApplied) then
  FTopInside := IsTopCanBeAppliedInMaterialization;
 FApplyTopWillCopyToResultTable := IsApplyTopWillCopyToResultTable;
end; // InitMaterialization


//------------------------------------------------------------------------------
// materializes AO
//------------------------------------------------------------------------------
procedure TACRAO.DoMaterialize;
begin
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('> TACRAO.DoMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
+#13#10+'FIsMaterialized = '+BoolToStr(FIsMaterialized,True)
);
{$ENDIF}
 if (not FIsMaterialized) then
  begin
   try
     InitMaterialization;
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - before create table'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
     CreateTableForMaterialize;
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - before fill table'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time8);
{$ENDIF}
     FillTableForMaterialize;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time8);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - after fill table'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
     if (FParametrized) then
      if (not FMaterializationDataSaved) then
       begin
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - saving materialization data...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
        SaveMaterializationData;
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - saving materialization data...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
       end;
     FinalizeMaterialize;
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - FinalizeMaterialize OK.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
   finally
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - calling FinalizeMaterialization...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
     FinalizeMaterialization;
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('TACRAO.DoMaterialize - calling FinalizeMaterialization...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
   end;
  end;
{$IFDEF DEBUG_TRACE_TACRAO_DoMaterialize}
aaWriteToLog('< TACRAO.DoMaterialize'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
end; // DoMaterialize


//------------------------------------------------------------------------------
// finalizes the materialization process
//------------------------------------------------------------------------------
procedure TACRAO.FinalizeMaterialization;
var i:  Integer;
begin
{$IFDEF DEBUG_TRACE_TACRAO_FinalizeMaterialization}
aaWriteToLog('> TACRAO.FinalizeMaterialization'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Distinct = '+BoolToStr((FDistinctAlgorithm <> adaNone),True)
);
{$ENDIF}
  if (FFieldValue <> nil) then
   begin
    FFieldValue.Free;
    FFieldValue := nil;
   end;
{$IFDEF DEBUG_TRACE_TACRAO_FinalizeMaterialization}
aaWriteToLog('TACRAO.FinalizeMaterialization 1'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
if (FDistinctAlgorithm <> adaNone) then
  aaWriteToLog('High(FDistinctFieldValues) = '+IntToStr(High(FDistinctFieldValues)));
{$ENDIF}
  if (FDistinctAlgorithm <> adaNone) then
   begin
    for i := 0 to High(FDistinctFieldValues) do
      FDistinctFieldValues[i].Free;
    FDistinctFieldValues := nil;
   end;
{$IFDEF DEBUG_TRACE_TACRAO_FinalizeMaterialization}
aaWriteToLog('TACRAO.FinalizeMaterialization 2'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
  if (FRecordComparison <> nil) then
   begin
    FRecordComparison.Free;
    FRecordComparison := nil;
   end;
{$IFDEF DEBUG_TRACE_TACRAO_FinalizeMaterialization}
aaWriteToLog('< TACRAO.FinalizeMaterialization'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
end; // FinalizeMaterialization


//------------------------------------------------------------------------------
// runs all necessary optimizations before executing AO
//------------------------------------------------------------------------------
procedure TACRAO.Optimize;
begin
{$IFDEF SQL_OPTIMIZER}
  if (FSQLOptimizer = nil) then
   if ((FFilterExpr <> nil) or (Self is TACRAOJoin) or (Self is TACRAOUnion)) then
    FSQLOptimizer := TACRSQLOptimizer.Create(Self);
  if (FSQLOptimizer <> nil) then
   begin
    FSQLOptimizer.OptimizeAll;
    FSQLOptimizer.Free;
    FSQLOptimizer := nil;
   end;
{$ENDIF}
end; // Optimize


//------------------------------------------------------------------------------
// return true if binary record comparison will be used in materialziation
//------------------------------------------------------------------------------
function TACRAO.IsRecordComparisonNeeded: Boolean;
begin
  Result := ((FDistinctAlgorithm = adaBySourceIndex) or (FDistinctAlgorithm = adaByRecordHash));
end; // IsRecordComparisonNeeded


//------------------------------------------------------------------------------
// set FDistinctAlgorithm to the best distinct algorithm for this query
//------------------------------------------------------------------------------
procedure TACRAO.ChooseDistinctAlgorithm;
begin
  FDistinctAlgorithm := adaByRecordHash;
end; // ChooseDistinctAlgorithm


//------------------------------------------------------------------------------
// return true if record must be inserted to result dataset
//------------------------------------------------------------------------------
function TACRAO.IsRecordMatchesDistinct: Boolean;
begin
  Result := true;
  case FDistinctAlgorithm of
   adaBySourceIndex:  Result := IsRecordMatchesDistinctBySourceIndex;
   adaByDestIndex:    Result := IsRecordMatchesDistinctByDestIndex;
   adaByRecordHash:   Result := IsRecordMatchesDistinctByRecordHash;
  end;
end; // IsRecordMatchesDistinct


//------------------------------------------------------------------------------
// distinct algorithm - by record hash
//------------------------------------------------------------------------------
function TACRAO.IsRecordMatchesDistinctByRecordHash: Boolean;
begin
  FRecordComparison.CalculateRecordHash;
  Result := FRecordComparison.AppendRecordHash;
end; // IsRecordMatchesDistinctByRecordHash


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRAO.Destroy;
begin
{$IFDEF DEBUG_TRACE_TACRAO_Destroy}
aaWriteToLog('> TACRAO.Destroy'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
  // destroy all used objects and links
  Clear(True,True);
{$IFDEF DEBUG_TRACE_TACRAO_Destroy}
aaWriteToLog('TACRAO.Destroy after clear'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
{$IFDEF CORRELATED_SUBQUERIES}
  if (FExternalFieldNodesLinkedToSubQueryAO <> nil) then
   begin
    FExternalFieldNodesLinkedToSubQueryAO.Free;
    FExternalFieldNodesLinkedToSubQueryAO := nil;
{$IFDEF DEBUG_TRACE_TACRAO_Destroy}
aaWriteToLog('TACRAO.Destroy after free list of external AO'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
   end;
{$ENDIF}
  inherited Destroy;
{$IFDEF DEBUG_TRACE_TACRAO_Destroy}
aaWriteToLog('< TACRAO.Destroy'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// getting all result records
//------------------------------------------------------------------------------
procedure TACRAO.Execute(IsRootAO : Boolean = false);
begin
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('> TACRAO.Execute.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
 FIsRootAO := IsRootAO;
// commented to avoid loosing new data changed between Close / Open by other users
// if (FRestartMaterialization and (not FParametrized)) then
//  Exit;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. FIsRootAO = '+BoolToStr(FIsRootAO,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
 try
  if (FParametrized and FMaterializationDataSaved) then
   begin
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - loading materialization data...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    LoadMaterializationData;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - loading materialization data...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
   end
  else
   begin
    // filter - moved here in v.4.60
    // to avoid bug with hidden fields in WHERE that are not in result field list
    // in join
    if (FFilterExpr <> nil) then
     TACRExpression(FFilterExpr).AssignAO(Self);
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. FFilterExpr = '+IntToHex(Integer(FFilterExpr),8)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    if (FIsRootAO) then
     begin
       Optimize;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Optimized.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     end;
   end;
  if (not FParametrized) then
   if (FParamNodes = nil) then
     begin
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - extracting all parameter nodes...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
      ExtractAllParameterNodes(FParamNodes);
      if (FParamNodes <> nil) then
       FParametrized := True;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - extracting all parameter nodes...OK'
+#13#10+'FParamNodes.Count = '+IntToStr(FParamNodes.Count)
+#13#10+'FParametrized = '+BoolToStr(FParametrized,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     end; // extract parameter nodes
  // execute child AO
  if (FLeftAO <> nil) then
   begin
    // fixed in v.5.30
    FLeftAO.FRestartMaterialization := FRestartMaterialization;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - executing LeftAO...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     FLeftAO.Execute;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - executing LeftAO...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FParametrized = '+BoolToStr(FParametrized,True)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    if (FLeftAO.FParametrized) then
      FParametrized := True;
    if (IsRootAO and (FLeftAO.FParamNodes <> nil) and
        (not FMaterializationDataSaved)) then
     begin
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - moving parameter nodes...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
      FLeftAO.MoveParamNodes(FParamNodes);
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - moving parameter nodes...OK'
+#13#10+'FParamNodes.Count = '+IntToStr(FParamNodes.Count)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     end;
   end; // LeftAO.Execute
  if (FRightAO <> nil) then
   begin
    // fixed in v.5.30
    FRightAO.FRestartMaterialization := FRestartMaterialization;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - executing RightAO...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    FRightAO.Execute;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - executing RightAO...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FParametrized = '+BoolToStr(FParametrized,True)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    if (FRightAO.FParametrized) then
     FParametrized := True;
    if (IsRootAO and (FRightAO.FParamNodes <> nil) and
        (not FMaterializationDataSaved)) then
     begin
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - moving parameter nodes...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
      FRightAO.MoveParamNodes(FParamNodes);
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Parameters - moving parameter nodes...OK'
+#13#10+'FParamNodes.Count = '+IntToStr(FParamNodes.Count)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     end;
   end;
  DoMaterialize;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. DoMaterialize OK!'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
 finally
  if (not FParametrized) then
   if (FResultIndexFieldsList <> nil) then
    begin
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Destroying index lists...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     FreeResultIndexLists;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('TACRAO.Execute. Destroying index lists...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    end;
{$IFDEF DEBUG_TRACE_TACRAO_Execute}
aaWriteToLog('< TACRAO.Execute.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
 end; // finally
end;// Execute


//------------------------------------------------------------------------------
// set filter
//------------------------------------------------------------------------------
procedure TACRAO.SetFilter(FilterExpr: TObject);
begin
 FFilterExpr := FilterExpr;
 TACRExpression(FFilterExpr).CaseInsensitive := FCaseInsensitive;
{$IFDEF DEBUG_TRACE_TACRAO_SetFilter}
  aaWriteToLog('TACRAO.SetFilter - '+GetName+#13#10+'FFilter = '+IntToHex(Integer(FFilterExpr),8));
{$ENDIF}
end; // SetFilter


//------------------------------------------------------------------------------
// for SELECT INTO optimization
//------------------------------------------------------------------------------
procedure TACRAO.SetResultTable(InMemory: Boolean; TableName: WideString; DatabaseName: AnsiString);
begin
  FResultInMemory := InMemory;
  FResultTableName := TableName;
  FResultDatabaseName := DatabaseName;
end; // SetResultTable


//------------------------------------------------------------------------------
// sets Top row count
//------------------------------------------------------------------------------
procedure TACRAO.SetTopRowCount(FirstRowNo, TopRowCount: integer);
begin
  FTopRowCount := TopRowCount;
  if (FirstRowNo < 0) then
   FFirstRowNo := 1
  else
   FFirstRowNo := FirstRowNo;
end;// SetTopRowCount


//------------------------------------------------------------------------------
// applies distinct
//------------------------------------------------------------------------------
procedure TACRAO.ApplyDistinct;
begin
  FDistinctApplied := True;
end; // ApplyDistinct


//------------------------------------------------------------------------------
// sets projection for other TACRAO
//------------------------------------------------------------------------------
procedure TACRAO.SetResultFields(var FieldRefs: array of TACRSelectListItem;
                                  bDistinct: Boolean);


var i,j,k,x,res,f: Integer;
    fname,tname:   WideString;
    tempArray:     TACRIntegerArray;

procedure AddField(FieldNo: Integer);
begin
  if (FResultFieldsOrder.IsValueExists(FieldNo)) then
   begin
    Inc(FFieldCount);
    SetLength(FFieldLinks,FFieldCount);
    FFieldLinks[FFieldCount-1] := FFieldLinks[FieldNo];
    FieldNo := FFieldCount-1;
   end;
  FResultFieldsOrder.Append(FieldNo);
  if (FieldRefs[i].Pseudonym <> '') then
   // set pseudonym
    FFieldLinks[FieldNo].DisplayName := FieldRefs[i].Pseudonym
  else
   // use name like it was written in query
   if (fname <> '*') then
    begin
{
     if (WideUpperCase(FFieldLinks[FieldNo].FieldName) <> WideUpperCase(fname)) then
       FFieldLinks[FieldNo].DisplayName := FFieldLinks[FieldNo].FieldName
     else
}     
       FFieldLinks[FieldNo].DisplayName := fname;
    end;
end; // AddField

begin
 j := Length(FieldRefs);
 if (j <= 0) then
  begin
   FieldExists('*','',true,FResultFieldsOrder);
  end
 else
 begin
  tempArray := TACRIntegerArray.Create;
  try
    for i := 0 to j-1 do
     begin
      if (FieldRefs[i].AllFields) then
       fname := '*'
      else
       fname := FieldRefs[i].FieldName;
      tname := FieldRefs[i].TableName;
      if (FieldRefs[i].IsExpression and (FieldRefs[i].ValueExpr <> nil)) then
       begin
        inc(FFieldCount);
        SetLength(FFieldLinks,FFieldCount);
        FFieldLinks[FFieldCount-1].Expr := FieldRefs[i].ValueExpr;
        TACRExpression(FFieldLinks[FFieldCount-1].Expr).AssignAO(self);
        // create new field for this expression
        if (FieldRefs[i].Pseudonym <> '') then
         // pseudonim specified
         FFieldLinks[FFieldCount-1].FieldName := FieldRefs[i].Pseudonym
        else
         // random name
         FFieldLinks[FFieldCount-1].FieldName := GetTemporaryName(ACRExpressionFieldName);
        FFieldLinks[FFieldCount-1].DisplayName := FFieldLinks[FFieldCount-1].FieldName;
        FFieldLinks[FFieldCount-1].OriginalFieldName := FFieldLinks[FFieldCount-1].FieldName;
        FFieldLinks[FFieldCount-1].TableName := '';
        FFieldLinks[FFieldCount-1].TableAlias := '';
        // get field type
        FFieldLinks[FFieldCount-1].FieldType :=
          TACRExpression(FieldRefs[i].ValueExpr).GetDataType;
        if (IsBLOBFieldType(FFieldLinks[FFieldCount-1].FieldType)) then
         begin
          FFieldLinks[FFieldCount-1].BLOBCompressionAlgorithm := 0;
          FFieldLinks[FFieldCount-1].BLOBCompressionMode := 0;
          FFieldLinks[FFieldCount-1].BLOBBlockSize := DefaultBLOBBlockSize;
         end;
        // get field size
        FFieldLinks[FFieldCount-1].FieldSize :=
          TACRExpression(FieldRefs[i].ValueExpr).GetDataSize;
        // get field precision
        FFieldLinks[FFieldCount-1].FieldPrecision :=
          TACRExpression(FieldRefs[i].ValueExpr).GetPrecision;
        // AO
        FFieldLinks[FFieldCount-1].AO := self;
        FFieldLinks[FFieldCount-1].Dataset := nil;
        FFieldLinks[FFieldCount-1].IsHidden := false;
        FFieldLinks[FFieldCount-1].IsExpression := true;
        FFieldLinks[FFieldCount-1].IsAggregate :=
          TACRExpression(FieldRefs[i].ValueExpr).IsAggregated;
        FExpressionsExists := True;
        if (not FAggregateExpressionsExists) then
         FAggregateExpressionsExists := FFieldLinks[FFieldCount-1].IsAggregate;
        FResultFieldsOrder.Append(FFieldCount-1);
        // added in v.5.10 to avoid double destroying from TACRSQLSelect ClearSelectList call from Destroy
        FieldRefs[i].ValueExpr := nil;
        continue;
       end; // Expression
      tempArray.SetSize(0);
      res := FieldExists(fname,tname,true,TempArray);
      if (res = 0) then
        raise EACRException.Create(10305, ErrorLCannotFindField, [fname]);
      if (fname = '*') then
       begin
         // modified in 4.97
         // we must skip adding expressions if TableName.* occured
         // as they are always in the result
         for x := 0 to TempArray.ItemCount - 1 do
          begin
            f := TempArray.Items[x];
            if ((j <= 1) or (not FFieldLinks[f].IsExpression)) then
              AddField(f);
          end;
       end
      else
       AddField(TempArray.Items[0]);
     end;
  finally
    tempArray.Free;
  end;
 end;

 for i := 0 to FResultFieldsOrder.ItemCount - 1 do
  begin
   k := FResultFieldsOrder.Items[i];
   if (FFieldLinks[k].DisplayName = '') then
    FFieldLinks[k].DisplayName :=
      FFieldLinks[k].FieldName;
  end;
  if (bDistinct) then
   ApplyDistinct;
  // changed in 5.02 
  FResultFieldCount := FResultFieldsOrder.ItemCount;
end;// SetResultFields


//------------------------------------------------------------------------------
// mapping function - return number of found fields and found field No
// also optionally unhides fields in AO
//------------------------------------------------------------------------------
function TACRAO.FieldExists(
                  FieldName, TableName: WideString;
                  Unhide:               Boolean;
                  FieldNumbers:         TACRIntegerArray = nil;
                  UnhideChildrenOnly:   Boolean = False
                  ): Integer;
var i,j,k:      Integer;
    fname:      WideString;
    tempArray:  TACRIntegerArray;
begin
 result := 0;
 if (FIsAOTable) then
   if (TableName <> '') then
    if (WideUpperCase(TableName) <> WideUpperCase(FTableName)) and
      (WideUpperCase(TableName) <> WideUpperCase(FTableAlias)) then
     Exit; // another table

 // all fields
 if (FieldName = '*') then
  begin
   // unhide or field numbers
   tempArray := TACRIntegerArray.Create(0,1,100);
   try
     if (FLeftAO <> nil) then
       FLeftAO.FieldExists(FieldName,TableName,Unhide, tempArray);

     for i := 0 to FFieldCount-1 do
      if (FIsAOTable) or
         ((WideUpperCase(TableName) = WideUpperCase(FTableName)) and
         (FFieldLinks[i].IsExpression)) or
         ((FLeftAO <> nil) and
            (FFieldLinks[i].AO = FLeftAO) and
            (tempArray.IsValueExists(FFieldLinks[i].FieldNo))) then
       begin
        inc(result);
        if (FieldNumbers <> nil) then
         FieldNumbers.Append(i);
        // group by does not needs in unhiding
        // it will cause hidden fields to be appeared in result dataset
        if (Unhide) and (not UnhideChildrenOnly) then
         if (not FIsAOGroupBy) then
          FFieldLinks[i].IsHidden := false;
       end;
     tempArray.SetSize(0);

     if (FRightAO <> nil) then
      begin
       FRightAO.FieldExists(FieldName,TableName,Unhide, tempArray);
       for i := 0 to FFieldCount-1 do
       if ((FRightAO <> nil) and
            (FFieldLinks[i].AO = FRightAO) and
            (tempArray.IsValueExists(FFieldLinks[i].FieldNo))) then
         begin
          inc(result);
          if (FieldNumbers <> nil) then
           FieldNumbers.Append(i);
          // group by does not needs in unhiding
          // it will cause hidden fields to be appeared in result dataset
          if (Unhide) and (not UnhideChildrenOnly) then
           FFieldLinks[i].IsHidden := false;
         end;
      end; // RightAO is not materialized
   finally
    tempArray.Free;
   end;
 end // all fields
else
 begin
   fname := WideUpperCase(FieldName);
   // not TACRAOTable
   tempArray := nil;
   if (FieldNumbers <> nil) then
    tempArray := TACRIntegerArray.Create(0,1,100);
   if (FLeftAO <> nil) then
    begin
     result := result + FLeftAO.FieldExists(FieldName,TableName,Unhide,tempArray);
     if (FieldNumbers <> nil) then
      begin
       for i := 0 to tempArray.ItemCount-1 do
        begin
         k := tempArray.Items[i];
         for j := 0 to FFieldCount-1 do
          if (FFieldLinks[j].AO = FLeftAO) then
           if (FFieldLinks[j].FieldNo = k) then
            begin
             // return FieldNo in current FFieldLinks
             FieldNumbers.Append(j);
             // group by does not needs in unhiding
             // it will cause hidden fields to be appeared in result dataset
             if (Unhide) and (not UnhideChildrenOnly) then
              FFieldLinks[j].IsHidden := false;
            end;
        end;
       tempArray.SetSize(0); // empty temp array
      end; // fieldNumbers exists
    end; // LeftAO
   if (FRightAO <> nil) then
    begin
     result := result + FRightAO.FieldExists(FieldName,TableName,Unhide,tempArray);
     if (FieldNumbers <> nil) then
      begin
       for i := 0 to tempArray.ItemCount-1 do
        begin
         k := tempArray.Items[i];
         for j := 0 to FFieldCount-1 do
          if (FFieldLinks[j].AO = FRightAO) then
           if (FFieldLinks[j].FieldNo = k) then
            begin
             // return FieldNo in current FFieldLinks
             FieldNumbers.Append(j);
             // group by does not needs in unhiding
             // it will cause hidden fields to be appeared in result dataset
             if (Unhide) and (not UnhideChildrenOnly) then
              FFieldLinks[j].IsHidden := false;
            end;
        end;
        tempArray.SetSize(0);
      end; // fieldNumbers exists
    end; // RightAO
   if (tempArray <> nil) then
    tempArray.Free;

   // find field
   for i := 0 to FFieldCount-1 do
    if (WideUpperCase(FFieldLinks[i].FieldName) = fname) or
       (WideUpperCase(FFieldLinks[i].DisplayName) = fname) then
     if (
     (TableName = '') or
         (WideUpperCase(TableName) = WideUpperCase(FFieldLinks[i].TableName)) or
         (WideUpperCase(TableName) = WideUpperCase(FFieldLinks[i].TableAlias))) then
        begin
         if (FieldNumbers <> nil) then
          if (not FieldNumbers.IsValueExists(i)) then
           begin
            FieldNumbers.Append(i);
            Inc(result);
           end;
         // group by does not needs in unhiding
         // it will cause hidden fields to be appeared in result dataset
         if (Unhide) and (not UnhideChildrenOnly) then
          FFieldLinks[i].IsHidden := false;
         break;
        end;
 end; // not all fields
end;// FieldExists


//------------------------------------------------------------------------------
// return FieldName from AOTable for specified internal field
//------------------------------------------------------------------------------
function TACRAO.GetFieldName(FieldNo: Integer; ApplyOrderBy: Boolean = False): WideString;
begin
 if (FieldNo < 0) or (FieldNo >= FieldCount) then
  raise EACRException.Create(10306,ErrorLInvalidFieldNumber,[FieldNo,FieldCount]);
 Result := '';
 if (ApplyOrderBy) then
  begin
   // apply order by
   if (FFieldLinks[FieldNo].Dataset <> nil) then
    begin
     if (FFieldLinks[FieldNo].Dataset = FResultDataset) then
      Result := FFieldLinks[FieldNo].FieldName
     else
      Result := FFieldLinks[FieldNo].Dataset.Fields[FFieldLinks[FieldNo].FieldNo].FieldName;
    end
   else
    begin
      Result := FFieldLinks[FieldNo].FieldName;
    end;
  end
 else
  begin
   // set field names for join
   if (FFieldLinks[FieldNo].Dataset <> nil) then
    begin
     if (FFieldLinks[FieldNo].Dataset = FResultDataset) then
      Result := FFieldLinks[FieldNo].FieldName
     else
      Result := FFieldLinks[FieldNo].Dataset.Fields[FFieldLinks[FieldNo].FieldNo].FieldName
    end
   else
    Result := TACRAO(FFieldLinks[FieldNo].AO).GetFieldName(FFieldLinks[FieldNo].FieldNo)
  end;
end; // GetFieldName


//------------------------------------------------------------------------------
// return DiplayName if it is not empty, otherwise - field name
//------------------------------------------------------------------------------
function TACRAO.GetResultFieldName(FieldNo: Integer): WideString;
begin
 if (FieldNo < 0) or (FieldNo >= FFieldCount) then
  Result := ''
 else
 if (FFieldLinks[FieldNo].DisplayName <> '') then
  Result := FFieldLinks[FieldNo].DisplayName
 else
  Result := FFieldLinks[FieldNo].FieldName;
end; // GetResultFieldName


//------------------------------------------------------------------------------
// return field value
//------------------------------------------------------------------------------
procedure TACRAO.GetFieldValue(
                        Value:          TACRVariant;
                        FieldNo:        Integer;
                        bCopy:          Boolean = False;
                        AccessToHidden: Boolean = False
                              );
var
  TmpValue: TACRVariant;
begin
  if ((FieldNo < 0) or (FieldNo >= FieldCount)) then
    raise EACRException.Create(10307, ErrorLInvalidFieldNumber,
                               [FieldNo,FieldCount]);

  Value.SetNull;
  if (FAllFieldsNull and (not FFieldLinks[FieldNo].IsAggregate)) then
   Exit;
  // AO = Dataset = nil
  if ((FFieldLinks[FieldNo].Dataset = nil) and (FFieldLinks[FieldNo].AO = nil)) then
    raise EACRException.Create(10309, ErrorLInvalidFieldLink, [FTableName,FieldNo]);

 // hiden field
 if not AccessToHidden then
   if (FFieldLinks[FieldNo].IsHidden) then
     raise EACRException.Create(10310,ErrorLCannotAccessHiddenField,
                    [FTableName,FFieldLinks[FieldNo].FieldName,
                     FFieldLinks[FieldNo].DisplayName, FieldNo]);

 if (FFieldLinks[FieldNo].IsExpression) then
   begin
     TmpValue := TACRExpression(FFieldLinks[FieldNo].Expr).GetValue;
     if (TmpValue <> nil) then
       Value.Assign(TmpValue, False);
   end // Expression
 else
   if (FFieldLinks[FieldNo].Dataset <> nil) then
     TACRDataset(FFieldLinks[FieldNo].Dataset).GetFieldValue(value,
                                                 FFieldLinks[FieldNo].FieldNo,False,bCopy)
 else
   begin
     if (FLeftAONull and (FFieldLinks[FieldNo].AO = FLeftAO)) or
        (FRightAONull and (FFieldLinks[FieldNo].AO = FRightAO)) then
       begin
         // return null value
         Exit;
       end;
     TACRAO(FFieldLinks[FieldNo].AO).GetFieldValue(value,
                          FFieldLinks[FieldNo].FieldNo, bCopy, AccessToHidden);
   end;
end; // GetFieldValue


//------------------------------------------------------------------------------
// get field type
//------------------------------------------------------------------------------
function TACRAO.GetFieldType(FieldNo: Integer): TACRAdvancedFieldType;
begin
  if ((FieldNo < 0) or (FieldNo >= FieldCount)) then
    raise EACRException.Create(10376, ErrorLInvalidFieldNumber,
                               [FieldNo,FieldCount]);
  Result := FFieldLinks[FieldNo].FieldType;
end; // GetFieldType


//------------------------------------------------------------------------------
// get field size
//------------------------------------------------------------------------------
function TACRAO.GetFieldSize(FieldNo: Integer): Integer;
begin
  if ((FieldNo < 0) or (FieldNo >= FieldCount)) then
    raise EACRException.Create(10377, ErrorLInvalidFieldNumber,
                               [FieldNo,FieldCount]);
  Result := FFieldLinks[FieldNo].FieldSize;
end; // GetFieldSize


//------------------------------------------------------------------------------
// get field precision
//------------------------------------------------------------------------------
function TACRAO.GetFieldPrecision(FieldNo: Integer): Integer;
begin
  if ((FieldNo < 0) or (FieldNo >= FieldCount)) then
    raise EACRException.Create(10378, ErrorLInvalidFieldNumber,
                               [FieldNo,FieldCount]);
  Result := FFieldLinks[FieldNo].FieldPrecision;
end; // GetFieldPrecision


//------------------------------------------------------------------------------
// lock table
//------------------------------------------------------------------------------
procedure TACRAO.LockTable(bWriteMode: Boolean);
begin
{$IFDEF DEBUG_TRACE_TACRAO_LockTable}
aaWriteToLog('> TACRAO.LockTable.'
+#13#10+'bWriteMode = '+BoolToStr(bWriteMode,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);

{$ENDIF}
 if (FLeftAO <> nil) then
  begin
{$IFDEF DEBUG_TRACE_TACRAO_LockTable}
aaWriteToLog('TACRAO.LockTable locking FLeftAO...'
+#13#10+'bWriteMode = '+BoolToStr(bWriteMode,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
   FLeftAO.LockTable(bWriteMode);
{$IFDEF DEBUG_TRACE_TACRAO_LockTable}
aaWriteToLog('TACRAO.LockTable locking FLeftAO...OK'
+#13#10+'bWriteMode = '+BoolToStr(bWriteMode,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
  end;
 if (FRightAO <> nil) then
  begin
{$IFDEF DEBUG_TRACE_TACRAO_LockTable}
aaWriteToLog('TACRAO.LockTable locking FRightAO...'
+#13#10+'bWriteMode = '+BoolToStr(bWriteMode,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
   FRightAO.LockTable(bWriteMode);
{$IFDEF DEBUG_TRACE_TACRAO_LockTable}
aaWriteToLog('TACRAO.LockTable locking FRightAO...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TACRAO_LockTable}
aaWriteToLog('< TACRAO.LockTable.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
end; // LockTable


//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
procedure TACRAO.UnlockTable;
begin
{$IFDEF DEBUG_TRACE_TACRAO_UnlockTable}
aaWriteToLog('> TACRAO.UnlockTable.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
 if (FLeftAO <> nil) then
  begin
{$IFDEF DEBUG_TRACE_TACRAO_UnlockTable}
aaWriteToLog('TACRAO.UnlockTable. Unlocking FLeftAO...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    FLeftAO.UnlockTable;
{$IFDEF DEBUG_TRACE_TACRAO_UnlockTable}
aaWriteToLog('TACRAO.UnlockTable. Unlocking FLeftAO...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
  end;
 if (FRightAO <> nil) then
  begin
{$IFDEF DEBUG_TRACE_TACRAO_UnlockTable}
aaWriteToLog('TACRAO.UnlockTable. Unlocking FRightAO...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
    FRightAO.UnlockTable;
{$IFDEF DEBUG_TRACE_TACRAO_UnlockTable}
aaWriteToLog('TACRAO.UnlockTable. Unlocking FRightAO...OK'
+#13#10+'bWriteMode = '+BoolToStr(bWriteMode,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_TACRAO_UnlockTable}
aaWriteToLog('< TACRAO.UnlockTable.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
end; // LockTable


//------------------------------------------------------------------------------
// create result index lists
//------------------------------------------------------------------------------
procedure TACRAO.CreateResultIndexLists(ToClear: Boolean; NumFields: Integer);
begin
 if (FResultIndexFieldsList = nil) then
   FResultIndexFieldsList := TACRWideStringList.Create
 else
  if (ToClear) then
   FResultIndexFieldsList.Clear;
 if (FResultIndexAscDescFieldsList = nil) then
   FResultIndexAscDescFieldsList := TACRWideStringList.Create
 else
  if (ToClear) then
   FResultIndexAscDescFieldsList.Clear;
 if (FResultIndexCaseInsFieldsList = nil) then
   FResultIndexCaseInsFieldsList := TACRWideStringList.Create
 else
  if (ToClear) then
   FResultIndexCaseInsFieldsList.Clear;
 if (FResultIndexFieldNumbers = nil) then
   FResultIndexFieldNumbers := TACRIntegerArray.Create
 else
  if (ToClear) then
   FResultIndexFieldNumbers.SetSize(0);
 if (NumFields > 0) then
  begin
   FResultIndexFieldNumbers.SetSize(NumFields);
   FResultIndexFieldsList.SetSize(NumFields);
   FResultIndexAscDescFieldsList.SetSize(NumFields);
   FResultIndexCaseInsFieldsList.SetSize(NumFields);
  end;
end; // CreateResultIndexLists


//------------------------------------------------------------------------------
// free and nil result index lists
//------------------------------------------------------------------------------
procedure TACRAO.FreeResultIndexLists;
begin
 if (FResultIndexFieldsList <> nil) then
  FResultIndexFieldsList.Free;
 if (FResultIndexAscDescFieldsList <> nil) then
  FResultIndexAscDescFieldsList.Free;
 if (FResultIndexCaseInsFieldsList <> nil) then
  FResultIndexCaseInsFieldsList.Free;
 if (FResultIndexFieldNumbers <> nil) then
  FResultIndexFieldNumbers.Free;
 FResultIndexFieldsList := nil;
 FResultIndexAscDescFieldsList := nil;
 FResultIndexCaseInsFieldsList := nil;
 FResultIndexFieldNumbers := nil;
end; // FreeResultIndexLists


//------------------------------------------------------------------------------
// the ORDER BY can be on the fields that are not specified in SELECT field list
// so we should unhide and add them to the end of FResultFieldsOrder
// and later apply projection to hide them from the result
//------------------------------------------------------------------------------
procedure TACRAO.CheckIfProjectionNeededToHideOrderByField(FieldNo: Integer);
begin
  if (not FResultFieldsOrder.IsValueExists(FieldNo)) then
   begin
    FFieldLinks[FieldNo].IsHidden := False;
    FResultFieldsOrder.Append(FieldNo);
   end;
end; // CheckIfProjectionNeededToHideOrderByField


//------------------------------------------------------------------------------
// set index for ORDER BY
//------------------------------------------------------------------------------
procedure TACRAO.SetOrderBy(
                       OrderBySpecs:          array of TACRSortSpecification;
                       OrderBySpecsCount:     integer;
                       OrderByIndex:          WideString // indexName
                      );

function GetIndexFieldName(FieldNo: Integer): WideString;
begin
 if (FFieldLinks[FieldNo].Dataset <> nil) then
  begin
   if (FFieldLinks[FieldNo].Dataset = FResultDataset) then
    begin
      if (Length(FFieldLinks[FieldNo].DisplayName) > 0) then
       Result := FFieldLinks[FieldNo].DisplayName
      else
       Result := FFieldLinks[FieldNo].FieldName;
    end
   else
    Result := FFieldLinks[FieldNo].Dataset.Fields[FFieldLinks[FieldNo].FieldNo].FieldName;
  end
 else
  begin
    if (Length(FFieldLinks[FieldNo].DisplayName) > 0) then
     Result := FFieldLinks[FieldNo].DisplayName
    else
     Result := FFieldLinks[FieldNo].FieldName;
  end;
end; // GetIndexFieldName


var
  i,FieldNo,n:           Integer;
  ColumnName, TableName: WideString;
  FieldNumbers:          TACRIntegerArray;
  FieldName:             WideString;
begin
  FActivateIndexAfterMaterialize := True;
  // rewritten in v.5.01
  if (Length(OrderByIndex) > 0) then
   begin
     FResultIndexName := OrderByIndex;
     Exit;
   end;
  FieldNumbers := TACRIntegerArray.Create;
  try
    CreateResultIndexLists(False,OrderBySpecsCount);
    // for all sort specs
    for i := 0 to OrderBySpecsCount-1 do
     begin
      n := OrderBySpecs[i].ColumnNumber-1;
      if (n >= 0) then
       begin
        // number specified - ORDER BY 1, 2 DESC
        if (n >= FResultFieldsOrder.ItemCount) then
         raise EACRException.Create(11666,ErrorLInvalidOrderByNumber,[n,FResultFieldsOrder.ItemCount]);
        FieldNo := FResultFieldsOrder.Items[n];
       end
      else
       begin
         // column name specified - ORDER BY ID DESC, STR NOCASE
         ColumnName := OrderBySpecs[i].ColumnName;
         TableName := OrderBySpecs[i].TableName;
         // get field No in AO
         FieldNumbers.SetSize(0);
         FieldExists(ColumnName, TableName, not (Self is TACRAOGroupBy), FieldNumbers);
         if (FieldNumbers.ItemCount = 0) then
          raise EACRException.Create(30195, ErrorGColumnFromOrderByNotFound, [ColumnName]);
         FieldNo := FieldNumbers.Items[0];
       end;
      FieldName := GetIndexFieldName(FieldNo);
      CheckIfProjectionNeededToHideOrderByField(FieldNo);
      // all index fields
      FResultIndexFieldNumbers.Items[i] := FieldNo;
      FResultIndexFieldsList[i] := FieldName;
      // desc index fields
      if (OrderBySpecs[i].Descending) then
       FResultIndexAscDescFieldsList[i] := ACR_DESC
      else
       FResultIndexAscDescFieldsList[i] := ACR_ASC;
      // case insensitive index fields
      if (OrderBySpecs[i].CaseInsensitive) then
       FResultIndexCaseInsFieldsList[i] := ACR_NO_CASE
      else
       FResultIndexCaseInsFieldsList[i] := ACR_CASE;
     end;
  finally
   FieldNumbers.Free;
  end;
end; // SetOrderBy


//------------------------------------------------------------------------------
// enumerates all expressions
//------------------------------------------------------------------------------
function TACRAO.EnumAllExpressions(var ExprNo: Integer; SkipFieldLinks: Boolean; out ExprAO: TACRAO): TObject;
var n,sf,lf,rf: Integer;
begin
  if (Self is TACRAOTable) then
   sf := FFieldCount+2
  else
   sf := FFieldCount+1;
  if (FLeftAO = nil) then
   lf := 0
  else
  if (FLeftAO is TACRAOTable) then
   lf := FLeftAO.FieldCount+2
  else
   lf := FLeftAO.FieldCount+1;
  if (FRightAO = nil) then
   rf := 0
  else
  if (FRightAO is TACRAOTable) then
   rf := FRightAO.FieldCount+2
  else
   rf := FRightAO.FieldCount+1;
  Result := nil;
  if (not SkipFieldLinks) then
    while (ExprNo < FFieldCount) do
    begin
     if (FFieldLinks[ExprNo].Expr <> nil) then
     begin
      Result := FFieldLinks[ExprNo].Expr;
      Inc(ExprNo);
      ExprAO := Self;
      Exit;
     end
     else
      Inc(ExprNo);
    end;
  if (ExprNo <= FFieldCount) then
  begin
   ExprNo := FFieldCount+1;
   Result := FFilterExpr;
   if (Result <> nil) then
    ExprAO := Self;
  end;
  if (Result = nil) then
   if (lf > 0) then
   begin
    n := ExprNo - sf;
    if (n < lf) then
    begin
      Result := FLeftAO.EnumAllExpressions(n,True,ExprAO);
      if (Result <> nil) then
       ExprNo := sf + n
      else
       ExprNo := sf + lf;
    end;
   end;
  if (Result = nil) then
   if (rf > 0) then
   begin
    n := ExprNo - sf - lf;
    if (n < rf) then
    begin
      Result := FRightAO.EnumAllExpressions(n,True,ExprAO);
      ExprNo := sf + n + lf;
    end;
   end;
end; // EnumAllExpressions


//------------------------------------------------------------------------------
// extract all TACRExprNodeConst objects from all expressions
//------------------------------------------------------------------------------
procedure TACRAO.ExtractAllParameterNodes(var NodeList: TACRList);
var Expr:   TACRExpression;
    ExprNo: Integer;
    n:      Integer;
    ao:     TACRAO;
begin
  ExprNo := 0;
  n := 0;
  while (True) do
  begin
    Expr := TACRExpression(EnumAllExpressions(ExprNo,False,ao));
    if (Expr = nil) then
     break;
    if (NodeList = nil) then
     NodeList := TACRList.Create;
    TACRExpression(Expr).ExtractAllParameterNodes(NodeList);
  end;
end; // ExtractAllParameterNodes


//------------------------------------------------------------------------------
// move all parameter nodes from FParamNodes to NodeList
//------------------------------------------------------------------------------
procedure TACRAO.MoveParamNodes(NodeList: TACRList);
var i: Integer;
begin
  if (FParamNodes <> nil) then
   begin
    for i := 0 to FParamNodes.Count - 1 do
     NodeList.Add(FParamNodes.Items[i]);
   end;
  FParamNodes.Free;
  FParamNodes := nil;
  if (FLeftAO <> nil) then
   FLeftAO.MoveParamNodes(NodeList);
  if (FRightAO <> nil) then
   FRightAO.MoveParamNodes(NodeList);
end; // MoveParamNodes


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// return true and fill FExternalFieldNodes list with field nodes from main query
// if the query is correlated
//------------------------------------------------------------------------------
function TACRAO.FindExternalFieldNodes: Boolean;
var Expr:   TACRExpression;
    ExprNo: Integer;
    AO:     TACRAO;
begin
  ExprNo := 0;
  while (True) do
  begin
    Expr := TACRExpression(EnumAllExpressions(ExprNo,False,ao));
    if (Expr = nil) then
     break;
    TACRExpression(Expr).ExtractAllExternalFieldNodes(FExternalFieldNodes,FExternalConstNodes,AO);
  end;
  Result := (FExternalFieldNodes <> nil);
end; // FindExternalFieldNodes


//------------------------------------------------------------------------------
// assign field node to current AO / Cursor
//------------------------------------------------------------------------------
procedure TACRAO.AssignExternalFieldNodes(SubQueryAO: TACRAO);
var i,n:    Integer;
    node:   TACRExprNodeField;
    fields: TACRIntegerArray;
begin
  fields := TACRIntegerArray.Create;
  try
    if (SubQueryAO.FExternalFieldNodes <> nil)  then
    begin
      for i := 0 to SubQueryAO.FExternalFieldNodes.Count - 1 do
      begin
       node := TACRExprNodeField(SubQueryAO.FExternalFieldNodes[i]);
       fields.SetSize(0);
       if (Self is TACRAOTable) then
       begin
         FieldExists(node.FieldName,node.TableName,True,fields,False);
         if (fields.ItemCount >= 1) then
         begin
          // try to link it directly to main AO
          n := fields.Items[0];
          if (FFieldLinks[n].IsExpression) then
          begin
           node.AssignAO(Self);
           node.DoNotReassign := True;
          end
          else
          begin
           try
             node.AssignCursor(TACRDataset(TACRAOTable(Self).FSourceDataset).Handle);
           except
            on E: Exception do
            begin
              raise EACRException.Create(12433,ErrorLCannotFindFieldInTable,[node.FieldName,node.TableName+#13#10+e.Message]);
            end;
           end;
           node.DoNotReassign := True;
          end;
         end
         else
         begin
          raise EACRException.Create(12432,ErrorLCannotFindFieldInTable,[node.FieldName,node.TableName]);
         end;
       end
       else
       begin
         node.AssignAO(Self);
         node.DoNotReassign := True;
       end;
       if (FExternalFieldNodesLinkedToSubQueryAO = nil) then
        FExternalFieldNodesLinkedToSubQueryAO := TACRList.Create;
       FExternalFieldNodesLinkedToSubQueryAO.Add(node);
      end; // scan all external field nodes of the SuqbEury AO and all its childrem
    end;
  finally
    fields.Free;
  end;
end; // AssignExternalFieldNodes


//------------------------------------------------------------------------------
// setup cursor buffer in all external field nodes linked to SubQuery AO
//------------------------------------------------------------------------------
procedure TACRAO.SetCursorBufferInExternalFieldNodesLinkedToSubQueryAO;
var i:      Integer;
    node:   TACRExprNodeField;
begin
  if (FExternalFieldNodesLinkedToSubQueryAO <> nil) and (Self is TACRAOTable) then
  begin
    for i := 0 to FExternalFieldNodesLinkedToSubQueryAO.Count-1 do
    begin
      node := TACRExprNodeField(FExternalFieldNodesLinkedToSubQueryAO.Items[i]);
      node.AssignCursorBuffer(TACRDataset(TACRAOTable(Self).FSourceDataset).Handle.CurrentRecordBuffer);
    end;
  end;
end; // SetCursorBufferInExternalFieldNodesLinkedToSubQueryAO


//------------------------------------------------------------------------------
// set Cursor all external fields
//------------------------------------------------------------------------------
procedure TACRAO.SetExternalFieldNodesCursor(Cursor: TACRCursor);
var
    i:     Integer;
    node:  TACRExprNodeField;
    crc:   Cardinal;
begin
  if (FExternalFieldNodes <> nil) and (Cursor <> nil) then
  begin
    crc := GetTableNameCRC(Cursor.TableName,True);
    for i := 0 to FExternalFieldNodes.Count - 1 do
    begin
     node := TACRExprNodeField(FExternalFieldNodes[i]);
     if (node.TableNameCRC <> crc) or (LSession <> Cursor.Session) then
      continue;
     try
       node.AssignCursor(Cursor);
       node.DoNotReassign := True;
     except
     end;
    end;
  end;
end; // SetExternalFieldNodesCursor


//------------------------------------------------------------------------------
// set Buffer all external fields
//------------------------------------------------------------------------------
procedure TACRAO.SetExternalFieldNodesCursorBuffer(Buffer: TACRRecordBuffer);
var i:    Integer;
    node: TACRExprNodeField;
begin
  if (FExternalFieldNodes <> nil) then
   for i := 0 to FExternalFieldNodes.Count-1 do
   begin
    node := TACRExprNodeField(FExternalFieldNodes.Items[i]);
    node.AssignCursorBuffer(Buffer);
   end;
end; // SetExternalFieldNodesCursorBuffer


//------------------------------------------------------------------------------
// find first result field, otherwise return -1
//------------------------------------------------------------------------------
function TACRAO.GetFirstResultFieldNo: Integer;
begin
  if (FResultFieldsOrder.ItemCount = 0) then
   Result := -1
  else
   Result := FResultFieldsOrder.Items[0];
end; // GetFirstResultFieldNo


//------------------------------------------------------------------------------
// find first result field no in FResultDataset, otherwise return -1
//------------------------------------------------------------------------------
function TACRAO.GetFirstResultDatasetFieldNo: Integer;
begin
  if (FResultFieldsOrder.ItemCount = 0) then
   Result := -1
  else
  begin
   Result := FResultFieldsOrder.Items[0];
   Result := FFieldLinks[Result].FieldNo;
  end;
end; // GetFirstResultDatasetFieldNo


//------------------------------------------------------------------------------
// this AO and all its children are used in sub-query
//------------------------------------------------------------------------------
procedure TACRAO.SetupSubQuery;
begin
  if (FLeftAO <> nil) then
   FLeftAO.SetupSubQuery;
  if (FRightAO <> nil) then
   FRightAO.SetupSubQuery;
  FSubQuery := True;
  FParametrized := True;
end; // SetupSubQuery


//------------------------------------------------------------------------------
// setup external field values
//------------------------------------------------------------------------------
procedure TACRAO.SetExternalFieldValues;
var i:          Integer;
    fieldNode:  TACRExprNode;
    constNode:  TACRExprNode;
begin
  if (FExternalFieldNodes <> nil) then
    for i := 0 to FExternalFieldNodes.Count-1 do
    begin
      fieldNode := TACRExprNodeField(FExternalFieldNodes.Items[i]);
      constNode := TACRExprNodeConst(FExternalConstNodes.Items[i]);
      constNode.GetDataValue.Assign(fieldNode.GetDataValue,True,False);
    end;
end; // SetExternalFieldValues
{$ENDIF}


{$IFDEF DEBUG_LOG}
//------------------------------------------------------------------------------
// get table name
//------------------------------------------------------------------------------
function TACRAO.GetName(Level: Integer = 0): AnsiString;
var i: Integer;
    s,s1,s2: AnsiString;
begin
  s := '';
  s1 := '';
  for i := 0 to Level-1 do
   s := s + #9;
  for i := 0 to Level do
   s1 := s1 + #9;
  if (FResultDataset <> nil) then
   s2 := IntToStr(FResultDataset.RecordCount)
  else
   s2 := '0';
  Result := s + Self.ClassName+' = '+IntToHex(Integer(Self),8)+': RecordCount = '+s2;
  if (Length(FTableName) > 0) then
    Result := Result + ' '+FTableName;
  if (Length(FTableAlias) > 0) then
    Result := Result + ' AS '+FTableAlias;
  if (FLeftAO = nil) then
    Result := Result + #13#10 + s1 +'LeftAO = nil'
  else
    Result := Result + #13#10 + s1 +'LeftAO: RecordCount = '+IntToStr(FLeftAO.InternalGetRecordCount)+#13#10+FLeftAO.GetName(Level+1);
  if (FRightAO = nil) then
    Result := Result + #13#10 + s1 +'RightAO = nil'
  else
    Result := Result + #13#10 + s1 +'RightAO: RecordCount = '+IntToStr(FLeftAO.InternalGetRecordCount)+#13#10+FRightAO.GetName(Level+1);
end;
{$ENDIF}


//------------------------------------------------------------------------------
// added in v.6.00 for Views
//------------------------------------------------------------------------------
procedure TACRAO.GetTableNames(Session: TACRBaseSession; TableNames: TACRWideStringList);
begin
  if (FLeftAO <> nil) then
   FLeftAO.GetTableNames(Session,TableNames);
  if (FRightAO <> nil) then
   FRightAO.GetTableNames(Session,TableNames);
end; // GetTableNamesList


//------------------------------------------------------------------------------
// reset result cursor of Root AO dataset - added in v.6.00 for Views
//------------------------------------------------------------------------------
procedure TACRAO.ResetRootAOCursorInResultDataset;
begin
  if (FIsRootAO) then
   if (FResultDataset <> nil) then
    TACRDataSet(FResultDataset).ResetHandle;
end; // ResetRootAOCursorInResultDataset
 

//------------------------------------------------------------------------------
// restart the materialization
//------------------------------------------------------------------------------
procedure TACRAO.SetRestartMaterialization(Value: Boolean);
begin
  FRestartMaterialization := Value;
  if (FLeftAO <> nil) then
    FLeftAO.SetRestartMaterialization(Value);
  if (FRightAO <> nil) then
    FRightAO.SetRestartMaterialization(Value);
end; // RestartMaterialization


//------------------------------------------------------------------------------
// saves materialization data for parametrized query to be able to restore it
//------------------------------------------------------------------------------
procedure TACRAO.SaveMaterializationData;
var i: Integer;
begin
 FMaterializationDataSaved := True;
 SetLength(FSavedFieldLinks,FFieldCount);
 for i := 0 to FFieldCount-1 do
  FSavedFieldLinks[i] := FFieldLinks[i];
end; // SaveMaterializationData


//------------------------------------------------------------------------------
// load materialization data for reopening parametrized query
//------------------------------------------------------------------------------
procedure TACRAO.LoadMaterializationData;
var i: Integer;
begin
 FIsMaterialized := False;
 if (not FIsAOTable) then
  if (FResultDataset <> nil) then
   begin
//    FResultDataset.Free;
//    FResultDataset := nil;
    // fixed in v.5.30
    FResultDataset.Close;
   end;
 SetLength(FFieldLinks,FFieldCount);
 for i := 0 to FFieldCount-1 do
  FFieldLinks[i] := FSavedFieldLinks[i];
end; // LoadMaterializationData




////////////////////////////////////////////////////////////////////////////////
//
// TACRAOTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TACRAOTable.InternalFirst;
begin
  if (FSourceDataset <> nil) then
  begin
   FSourceDataset.First;
{$IFDEF CORRELATED_SUBQUERIES}
   SetCursorBufferInExternalFieldNodesLinkedToSubQueryAO;
{$ENDIF}
  end
  else
   FResultDataset.First;
end; // InternalFirst


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TACRAOTable.InternalNext;
begin
  if (FSourceDataset <> nil) then
  begin
   FSourceDataset.Next;
{$IFDEF CORRELATED_SUBQUERIES}
   SetCursorBufferInExternalFieldNodesLinkedToSubQueryAO;
{$ENDIF}
  end
  else
   FResultDataset.Next;
end; // InternalNext


//------------------------------------------------------------------------------
// eof
//------------------------------------------------------------------------------
function TACRAOTable.InternalGetEof: Boolean;
begin
  if (FSourceDataset <> nil) then
   Result := FSourceDataset.Eof
  else
   Result := FResultDataset.Eof;
end; // InternalGetEof


//------------------------------------------------------------------------------
// optimizes filters before materialization -
// moves all filter conditions assigned to cursor to the SQLFilter
// applied to FSourceDataset before scanning records
//------------------------------------------------------------------------------
procedure TACRAOTable.OptimizeFiltersBeforeMaterialization;
var newFilter: TACRExpression;
begin
  // if restart parametrized query - no need to optimize
  if (FRestartMaterialization) or (FFilterExpr = nil) then
   Exit;
{$IFDEF CORRELATED_SUBQUERIES}
//  if (TACRExpression(FFilterExpr).CorrelatedSubQueriesExists) then
//   Exit;
{$ENDIF}
  newFilter := TACRExpression(FFilterExpr).ExtractFilterConditionsAssignedToSourceDataset(Self);
  if (newFilter <> nil) then
   begin
    TACRDataset(FSourceDataset).SetSQLFilter(newFilter);
    if (TACRExpression(FFilterExpr).IsEmpty) then
     begin
      FFilterExpr.Free;
      FFilterExpr := nil;
     end;
   end;
end; // OptimizeFiltersBeforeMaterialization


//------------------------------------------------------------------------------
// create temporary table
//------------------------------------------------------------------------------
procedure TACRAOTable.CreateTableForMaterialize;
begin
  inherited CreateTableForMaterialize;
  // added in v.4.60
  if (FFilterExpr <> nil) then
   OptimizeFiltersBeforeMaterialization;
end; // CreateTableForMaterialize


//------------------------------------------------------------------------------
// materializes AO
//------------------------------------------------------------------------------
procedure TACRAOTable.DoMaterialize;
var s:                WideString;
    i,dc,j:           Integer;
    bOK:              Boolean;
    Distinct1:        Boolean;
    FieldList:        TACRWideStringList;
    AliasList:        TACRWideStringList;
    Res:              Boolean;

function IsMaterializationRequired: Boolean;
var IndexName: WideString;
begin
 Result := (FIsRootAO and (not FRequestLive));
 // TOP option
 if (FTopRowCount >= 0) then
  Result := True;
 // expressions exists
{ TODO -oLeo : add FIsRootAO check to optimize UNION - source TACRAOTable must be live in any cases }
// if ((FFieldCount > FSourceDataset.FieldCount) and (FIsRootAO)) then
 if (FFieldCount > FSourceDataset.FieldCount) then
  Result := True
 else
 // distinct option
 if (FDistinctApplied) then
  Result := True
 else
 // select into
 if (Length(FResultTableName) > 0) then
  Result := True;
{$IFDEF CORRELATED_SUBQUERIES}
// if (not Result) then
//  if (FFilterExpr <> nil) then
//   Result := TACRExpression(FFilterExpr).CorrelatedSubQueriesExists;
{$ENDIF}
 if (FResultIndexFieldsList <> nil) then
   begin
     if (FSourceDataset is TACRQuery) then
      begin
       Result := True;
       Exit;
      end;
     IndexName := TACRTable(FSourceDataset).FindIndex(FResultIndexFieldsList,
                                           FResultIndexAscDescFieldsList,
                                           FResultIndexCaseInsFieldsList);
     TACRTable(FSourceDataset).IndexName := IndexName;
     if (TACRTable(FSourceDataset).IndexName = '') then
      begin
       // we must do materialize as there is no index in source table for ORDER BY
       if (not Result) then
         Result := True;
      end
     else
      begin
        // index found - no need to create it
        if (not FParametrized) then
         FreeResultIndexLists;
      end;
   end;
end; // IsMaterializationRequired


procedure FinalizeMaterialize(Live: Boolean);
var i,j: Integer;
begin
 FLive := Live;
 if (Live) then
  begin
   if (FParametrized) then
    if (not FMaterializationDataSaved) then
     SaveMaterializationData;
   // live query
//   if (FIsRootAO) then
//    begin
     j := 0;
     for i := 0 to FFieldCount-1 do
      begin

// commented in 4.70 as never used - expressions in SELECT list always makes
// read-only result dataset (not live)
//
{
       if (FFieldLinks[i].IsExpression) then
        if (FFieldLinks[i].Expr <> nil) then
          TACRExpression(FFieldLinks[i].Expr).Free;
       FFieldLinks[i].Expr := nil;
  //
       FFieldLinks[i].IsExpression := False;
       FFieldLinks[i].IsAggregate := False;
}
       // fixed in v.5
       j := FResultFieldsOrder.IndexOf(i);
       if (j >= 0) then
        begin
{$IFDEF CORRELATED_SUBQUERIES}
         if (not FSubQuery) then
{$ENDIF}         
          FFieldLinks[i].FieldNo := j;
         FFieldLinks[i].AO := nil;
         FFieldLinks[i].Dataset := FResultDataset;
        end;

       // stored in FResultDataset.Handle.SQLFilterExpression - no need to destroy
       // changed in v.5.60
//       if (not FParametrized)  then
       FFilterExpr := nil;
      end; // for
//    end; // FIsRootAO
  end // live query
 else
  begin
   // read-only query
   FLive := False;
   if (FTableLocked) then
     begin
      // 4.40 - live table should not be unlocked
      TACRDataSet(FSourceDataset).UnlockTable(FTableLockedInWriteMode);
      FTableLocked := False;
      FTableLockedInWriteMode := False;
     end;
   if (not FParametrized) then
    begin
     // avoid double free of the SQLFilter that exact same as FFilterExpr
     if ((TACRDataSet(FSourceDataset).Handle.SQLFilterExpression =
          FFilterExpr) and (FFilterExpr <> nil)) then
      TACRDataSet(FSourceDataset).Handle.SQLFilterExpression := nil;
     FSourceDataset.Free;
     FSourceDataset := nil;
     if (FFilterExpr <> nil) then
      FFilterExpr.Free;
     FFilterExpr := nil;
    end;
  end;
 FIsMaterialized := True;
end; // finalizes materialization

begin
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time1);
try
{$ENDIF}
 if (FIsMaterialized) then
  Exit;
  TACRDataset(FSourceDataset).CaseInsensitive := FCaseInsensitive;
  if (Length(FResultIndexName) > 0) then
   begin
    i := TACRDataSet(FSourceDataset).IndexDefs.IndexOf(FResultIndexName);
    if (i < 0) then
     raise EACRException.Create(11667,ErrorLIndexDoesNotExist,[FResultIndexName,TACRDataSet(FSourceDataset).Handle.TableName]);
    if (FSourceDataset is TACRTable) then
     TACRTable(FSourceDataset).IndexName := FResultIndexName;
   end;
  if (not FRestartMaterialization) then
    FMaterializationRequired := IsMaterializationRequired;
  if (FMaterializationRequired) then
   begin
    // fixed in v.5.30
    if (not FRestartMaterialization) then
     begin
      FResultDataset := TACRTable.Create(nil);
      TACRDataset(FResultDataset).CaseInsensitive := FCaseInsensitive;
     end;
    try
      inherited DoMaterialize;
    finally
      FinalizeMaterialize(False);
    end;
   end
  else
{$IFDEF CORRELATED_SUBQUERIES}
  if (FSubQuery) then
   begin
    // fixed in v.5.02#2
    if ((FFilterExpr <> nil) {and (FSourceDataset is TACRTable)}) then
     begin
      TACRDataset(FSourceDataset).SetSQLFilter(FFilterExpr);
//commented in 4.70 - no needed, as First will be called always
//      TACRDataset(FSourceDataset).First;
     end;
    FSourceDataset.First;
    FinalizeMaterialize(True);
   end
  else
{$ENDIF}
   begin
    FieldList := TACRWideStringList.Create;
    AliasList := TACRWideStringList.Create;
    try
//      if (FSourceDataset <> FResultDataset) then
//       TACRDataset(FSourceDataset).SetSQLFilter(FFilterExpr);
      if ((FResultFieldsOrder.ItemCount > 0)) then
       begin
         for i := 0 to FResultFieldsOrder.ItemCount-1 do
          begin
           j := FResultFieldsOrder.Items[i];
           if (FFieldLinks[j].IsHidden) then
            raise EACRException.Create(11498,ErrorLCannotAccessHiddenField,[FTableName,
                    FFieldLinks[j].FieldName,FFieldLinks[j].DisplayName,j]);
           if (FFieldLinks[j].DisplayName = '') then
            raise EACRException.Create(11500,ErrorLEmptyDisplayName,
                    [FTableName,FFieldLinks[j].FieldName,j]);
           FieldList.Add(FFieldLinks[j].FieldName);
           AliasList.Add(FFieldLinks[j].DisplayName);
          end;
        FResultDataset.First;
        TACRDataSet(FResultDataset).ApplyProjection(FieldList,AliasList);
       end; // just set a projection
    // fixed in v.5.02#2
    if ((FFilterExpr <> nil) {and (FSourceDataset is TACRTable)}) then
     begin
      TACRDataset(FSourceDataset).SetSQLFilter(FFilterExpr);
//commented in 4.70 - no needed, as First will be called always
//      TACRDataset(FSourceDataset).First;
      TACRRecordBitmap(TACRDataset(FSourceDataset).Handle.RecordBitmap).Active := False;
      FSourceDataset.First;
     end;
    finally
     FinalizeMaterialize(True);
     FieldList.Free;
     AliasList.Free;
    end;
   end; // Live query
{$IFDEF DEBUG_SQL_TIME}
finally
aaStopTime(time1);
end;
{$ENDIF}
end; // DoMaterialize


//------------------------------------------------------------------------------
// return number of records
//------------------------------------------------------------------------------
function TACRAOTable.InternalGetRecordCount: Integer;
begin
  Result := 0;
  if (FIsMaterialized) then
   Result := FResultDataset.RecordCount
  else
   Result := FSourceDataset.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// enumerates all expressions
//------------------------------------------------------------------------------
function TACRAOTable.EnumAllExpressions(var ExprNo: Integer; SkipFieldLinks: Boolean; out ExprAO: TACRAO): TObject;
begin
  Result := inherited EnumAllExpressions(ExprNo,SkipFieldLinks,ExprAO);
  if (Result = nil) and (ExprNo < (FFieldCount+2)) then
    begin
      Inc(ExprNo);
      if (FSourceDataset <> nil) then
        Result := TACRDataSet(FSourceDataset).Handle.SQLFilterExpression;
    end;
  if (Result <> nil) then
    ExprAO := Self;
end; // EnumAllExpressions


//------------------------------------------------------------------------------
// restart the materialization
//------------------------------------------------------------------------------
procedure TACRAOTable.SetRestartMaterialization(Value: Boolean);
begin
  inherited SetRestartMaterialization(Value);
  if (Value) then
   if (TACRDataset(FSourceDataset).Handle <> nil) then
     TACRDataset(FSourceDataset).Handle.DisableRecordBitmap;
end; // SetRestartMaterialization


//------------------------------------------------------------------------------
// saves materialization data for parametrized query to be able to restore it
//------------------------------------------------------------------------------
procedure TACRAOTable.SaveMaterializationData;
begin
  inherited;
  FSavedSourceDatasetFilter := TACRDataSet(FSourceDataset).Handle.SQLFilterExpression;
end; // SaveMaterializationData


//------------------------------------------------------------------------------
// load materialization data for reopening parametrized query
//------------------------------------------------------------------------------
procedure TACRAOTable.LoadMaterializationData;
begin
  inherited;
  if (not FLive) then
   if (FResultDataset <> nil) then
    begin
//     FResultDataset.Free;
//     FResultDataset := nil;
     // fixed in v.5.30
     FResultDataset.Close;
    end;
  TACRDataSet(FSourceDataset).SetSQLFilter(FSavedSourceDatasetFilter);
  TACRDataset(FSourceDataset).Handle.DisableRecordBitmap;
end; // LoadMaterializationData


//------------------------------------------------------------------------------
// for GET TABLES / SELECT * FROM TABLES
//------------------------------------------------------------------------------
procedure TACRAOTable.PrepareSystemTableData;
var i,j,l,maxNL,maxCL:  Cardinal;
    tableInfo:          TACRTableInfoArray;
    table:              TACRTable;
    db:                 TACRDatabase;
    bOpen:              Boolean;
    v:                  TACRVariant;
begin
  table := TACRTable(FSourceDataset);
  bOpen := (table.Database = nil);
  if (bOpen) then
   db := table.OpenDatabase
  else
   db := table.Database;
  try
   tableInfo := db.GetTablesInfo;
  finally
    if (bOpen) then
     table.CloseDatabase(db);
  end;
  maxNL := 1;
  maxCL := 1;
  i := 0;
  l := Length(tableInfo);
  while (i < l) do
   begin
    j := Length(tableInfo[i].TableName);
    if (j > maxNL) then
     maxNL := j;
    j := Length(tableInfo[i].Comment);
    if (j > maxCL) then
     maxCL := j;
    Inc(i);
   end; // scan all tables
  table.InMemory := False;
  table.Temporary := True;
  table.ClearDefinitions;
  // 1
  table.AdvFieldDefs.Add('Table Name',aftWideChar,MaxNL);
  // 2
  table.AdvFieldDefs.Add('Creation Date',aftDateTime);
  // 3
  table.AdvFieldDefs.Add('Last Modification Date',aftDateTime);
  // 4
  table.AdvFieldDefs.Add('Last Operation',aftWideChar,ACRMaxLastTableOperationNamesLength);
  // 5
  table.AdvFieldDefs.Add('Status',aftChar,4);
  // 6
  table.AdvFieldDefs.Add('State',aftChar,8);
  // 7
  table.AdvFieldDefs.Add('MetaData State',aftChar,2);
  // 8
  table.AdvFieldDefs.Add('Comment',aftWideChar,MaxCL);
  table.CreateTable;
  table.Open;
  i := 0;
  if (l > 0) then
   begin
    v := TACRVariant.Create;
    try
      while (i < l) do
       begin
        table.Insert;
        // table name
        v.Clear(bftWideChar);
        v.AsWideString := tableInfo[i].TableName;
        table.SetFieldValue(v,0,True);
        // creation date
        v.Clear(bftDateTime);
        v.AsTDateTime := tableInfo[i].CreationDate;
        table.SetFieldValue(v,1,True);
        // last modification date
        v.Clear(bftDateTime);
        v.AsTDateTime := tableInfo[i].TableState.LastModificationDate;
        table.SetFieldValue(v,2,True);
        // last operation
        v.Clear(bftWideChar);
        v.AsWideString := ACRGetLastTableOpertaion(tableInfo[i].TableState.LastTableOperation);
        table.SetFieldValue(v,3,True);
        // status
        v.Clear(bftChar);
        v.AsString := IntToHex(tableInfo[i].TableState.TableFailureFlags,4);
        table.SetFieldValue(v,4,True);
        // state
        v.Clear(bftChar);
        v.AsString := IntToHex(tableInfo[i].TableState.TableState,8);
        table.SetFieldValue(v,5,True);
        // metadata state
        v.Clear(bftChar);
        v.AsString := IntToHex(tableInfo[i].TableState.TableMetaDataState,2);
        table.SetFieldValue(v,6,True);
        // table comment
        v.Clear(bftWideChar);
        v.AsWideString := tableInfo[i].Comment;
        table.SetFieldValue(v,7,True);
        // post
        table.Post;
        Inc(i);
       end; // scan all tables
    finally
      v.Free;
    end;
   end;
end; // PrepareGetTablesData


//------------------------------------------------------------------------------
// added in v.6.00 for Views
//------------------------------------------------------------------------------
procedure TACRAOTable.GetTableNames(Session: TACRBaseSession; TableNames: TACRWideStringList);
begin
 if (Session.InMemory = FInMemory) and
    (Session.SessionName = FSessionName) and
    (Session.DatabaseName = FDatabaseName) then
    TableNames.Add(FTableName,True);
end; // GetTableNames


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRAOTable.Create(
                      aSession:     TACRBaseSession;
                      aParams:      TACRSQLParams;
                      DatabaseName: AnsiString;
                      SessionName:  AnsiString;
                      TableName:    WideString;
                      TableAlias:   WideString;
                      SubQuerySQL:  WideString;
                      Params:       TParams;
                      bInMemory:    Boolean = false;
                      bRequestLive: Boolean = false;
                      bSystemTable: Boolean = false
                      );
var i: integer;
begin
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('> TACRAOTable.Create...'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'SessionName = '+SessionName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(bInMemory,True)
);
{$ENDIF}
 InternalCreate(aSession,aParams,nil,nil,TableName,TableAlias,SubQuerySQL);
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('1 TACRAOTable.Create...OK. TableName = '+TableName);
{$ENDIF}
 FInMemory := bInMemory or aSession.InMemory;
 FSessionName := SessionName;
 FDatabaseName := DatabaseName;
 FSystemTable := False;
 FSourceDataset := FResultDataset;
 FTableLocked := False;
 FTableLockedInWriteMode := False;
 FRequestLive := bRequestLive;
// FRequestLive := True;
 FIsMaterialized := False;
 FIsAOTable := true;
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('2 TACRAOTable.Create... TableName = '+TableName);
{$ENDIF}
 if (FResultDataset is TACRTable) then
  begin
   TACRTable(FResultDataset).InMemory := bInMemory;
   TACRTable(FResultDataset).DatabaseName := DatabaseName;
   TACRTable(FResultDataset).SessionName := SessionName;
   TACRTable(FResultDataset).TableName := TableName;
   FSystemTable := bSystemTable;
   if (not FSystemTable) then
     FSystemTable := TACRTable(FResultDataset).IsSystemTable;
   if (FSystemTable) then
     PrepareSystemTableData;
   if (bInMemory) then
    if (not TACRTable(FResultDataset).Exists) then
     raise EACRException.Create(11505,ErrorLTableDoesNotExist,[TableName]);
  end
 else
  begin
   TACRQuery(FResultDataset).InMemory := bInMemory;
   TACRQuery(FResultDataset).DatabaseName := DatabaseName;
   TACRQuery(FResultDataset).SessionName := SessionName;
   TACRQuery(FResultDataset).RequestLive := True;
   if (Params <> nil) then
    TACRQuery(FResultDataset).Params.Assign(Params);
  end;
 try
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('2.1 TACRAOTable.Create... TableName = '+TableName+#13#10+'TACRTable(FResultDataset).InMemory = '+BoolToStr(TACRTable(FResultDataset).InMemory,True));
{$ENDIF}
  FResultDataset.Open;
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('2.2 TACRAOTable.Create... TableName = '+TableName);
{$ENDIF}
 except
  on e: Exception do
   begin
     raise EACRException.Create(10303,ErrorLCannotOpenTable,
      [TableName,DatabaseName,SessionName,BoolToStr(bInMemory,True),SubQuerySQL
      ,e.Message]);
   end;
 end;
 FFieldCount := FResultDataset.FieldCount;
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('3 TACRAOTable.Create... TableName = '+TableName+#13#10+'FFieldCount = '+IntToStr(FFieldCount));
{$ENDIF}
 SetLength(FFieldLinks,FFieldCount);
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].AO := nil;
   FFieldLinks[i].Dataset := FResultDataset;
   FFieldLinks[i].FieldNo := i;
   FFieldLinks[i].IsHidden := True;
   FFieldLinks[i].IsExpression := False;
   FFieldLinks[i].IsAggregate  := False;
   FFieldLinks[i].FieldName := TACRDataSet(FResultDataset).AdvFieldDefs.Items[i].Name;
   FFieldLinks[i].DisplayName := '';
   FFieldLinks[i].TableName := FTableName;
   FFieldLinks[i].TableAlias := FTableAlias;
   FFieldLinks[i].FieldType := TACRDataSet(FResultDataset).AdvFieldDefs.Items[i].DataType;
   FFieldLinks[i].FieldSize := TACRDataSet(FResultDataset).AdvFieldDefs.Items[i].Size;
   FFieldLinks[i].BLOBCompressionAlgorithm :=
    Byte(TACRDataSet(FResultDataset).AdvFieldDefs.Items[i].BLOBCompressionAlgorithm);
   FFieldLinks[i].BLOBCompressionMode := TACRDataSet(FResultDataset).AdvFieldDefs.Items[i].BLOBCompressionMode;
   FFieldLinks[i].BLOBBlockSize := TACRDataSet(FResultDataset).AdvFieldDefs.Items[i].BLOBBlockSize;
  end;
{$IFDEF DEBUG_TRACE_TACRAOTable_Create}
aaWriteToLog('< TACRAOTable.Create - ok. TableName = '+TableName);
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRAOTable.Destroy;
begin
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('> TACRAOTable.Destroy.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
  if (FTableLocked) then
  begin
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('> TACRAOTable.Destroy. Calling UnlockTable... '
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked,True)
+#13#10+'FTableLockedInWriteMode = '+BoolToStr(FTableLockedInWriteMode,True)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
   TACRDataSet(FResultDataset).UnlockTable(FTableLockedInWriteMode);
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('TACRAOTable.Destroy. Calling UnlockTable...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked,True)
+#13#10+'FTableLockedInWriteMode = '+BoolToStr(FTableLockedInWriteMode,True)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
  end;
  if (FSourceDataset <> nil) then
   begin
    // added in 4.80
    if (TACRDataSet(FSourceDataset).Handle <> nil) then
     if ((TACRDataSet(FSourceDataset).Handle.SQLFilterExpression =
          FFilterExpr) and (FFilterExpr <> nil)) then
      TACRDataSet(FSourceDataset).Handle.SQLFilterExpression := nil;
    if (FSourceDataset = FResultDataset) then
     begin
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('TACRAOTable.Destroy. Calling FSourceDataset.Close...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
      FSourceDataset.Close;
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('TACRAOTable.Destroy. Calling FSourceDataset.Close...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
     end
    else
     begin
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('TACRAOTable.Destroy. Calling FSourceDataset.Free...'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
);
{$ENDIF}
      FSourceDataset.Free;
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('TACRAOTable.Destroy. Calling FSourceDataset.Free...OK'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
      FSourceDataset := nil;
     end;
   end;
  inherited;
{$IFDEF DEBUG_TRACE_TACRAOTable_Destroy}
aaWriteToLog('< TACRAOTable.Destroy.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName
+#13#10+'FTableLocked = '+BoolToStr(FTableLocked)
+#13#10+'FSourceDataset = '+IntToHex(Integer(FSourceDataset),8)
+#13#10+'FResultDataset = '+IntToHex(Integer(FResultDataset),8)
);
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// lock table
//------------------------------------------------------------------------------
procedure TACRAOTable.LockTable(bWriteMode: Boolean);
begin
  if ((not FTableLocked) and (TACRDataSet(FResultDataset).Handle <> nil)) then
   if (not TACRDataSet(FResultDataset).Handle.Temporary) then
//      ((not TACRTable(FResultDataset).InMemory) and
//       (not TACRTable(FResultDataset).Temporary)) then
    begin
{$IFDEF DEBUG_TRACE_TACRAOTable_LockTable}
aaWriteToLog('> TACRAOTable.LockTable.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     TACRDataSet(FResultDataset).LockTable(bWriteMode);
{$IFDEF DEBUG_TRACE_TACRAOTable_LockTable}
aaWriteToLog('< TACRAOTable.LockTable.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     FTableLocked := True;
     FTableLockedInWriteMode := bWriteMode;
    end;
end; // LockTable


//------------------------------------------------------------------------------
// unlock table
//------------------------------------------------------------------------------
procedure TACRAOTable.UnlockTable;
begin
  if ((FTableLocked) and (TACRDataSet(FResultDataset).Handle <> nil)) then
   if (not TACRDataSet(FResultDataset).Handle.Temporary) then
//   if ((not TACRTable(FResultDataset).InMemory) and
//       (not TACRTable(FResultDataset).Temporary)) then
    begin
{$IFDEF DEBUG_TRACE_TACRAOTable_UnlockTable}
aaWriteToLog('> TACRAOTable.UnlockTable.'
+#13#10+'FTableLockedInWriteMode = '+BoolToStr(FTableLockedInWriteMode,True)
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'TableName = '+FTableName);
{$ENDIF}
     TACRDataSet(FResultDataset).UnlockTable(FTableLockedInWriteMode);
{$IFDEF DEBUG_TRACE_TACRAOTable_UnlockTable}
aaWriteToLog('< TACRAOTable.UnlockTable.');
{$ENDIF}
     FTableLocked := False;
     FTableLockedInWriteMode := False;
    end;
end; // LockTable


//------------------------------------------------------------------------------
// set index
//------------------------------------------------------------------------------
procedure TACRAOTable.SetOrderBy(
                       OrderBySpecs:          array of TACRSortSpecification;
                       OrderBySpecsCount:     integer;
                       OrderByIndex:          WideString // indexName
                      );
var DescFieldNames,IndexFieldNames: WideString;
    i:                          Integer;
begin
  if (FSystemTable) then
   begin
    IndexFieldNames := '';
    DescFieldNames := '';
    for i := 0 to OrderBySpecsCount-1 do
     begin
       if (OrderBySpecs[i].ColumnName = '') then
        IndexFieldNames := FFieldLinks[OrderBySpecs[i].ColumnNumber-1].FieldName
       else
        begin
         if (i = 0) then
          IndexFieldNames := OrderBySpecs[i].ColumnName
         else
          IndexFieldNames := IndexFieldNames + SemiColon + OrderBySpecs[i].ColumnName;
        end;
       if (OrderBySpecs[i].Descending) then
         if (DescFieldNames = '') then
          DescFieldNames := OrderBySpecs[i].ColumnName
         else
          DescFieldNames := DescFieldNames + SemiColon + OrderBySpecs[i].ColumnName;
     end;
    TACRTable(FSourceDataset).IndexDefs.Update;
    if (TACRTable(FSourceDataset).IndexDefs.IndexOf('OrderByIndex') < 0) then
     TACRTable(FSourceDataset).AddIndex('OrderByIndex',IndexFieldNames,[ixCaseInsensitive],DescFieldNames,IndexFieldNames);
    TACRTable(FSourceDataset).IndexName := 'OrderByIndex';
    FreeResultIndexLists;
   end
  else
    inherited SetOrderBy(OrderBySpecs,OrderBySpecsCount,OrderByIndex);
end; // SetIndex


//------------------------------------------------------------------------------
// reset result cursor of Root AO dataset - added in v.6.00 for Views
//------------------------------------------------------------------------------
procedure TACRAOTable.ResetRootAOCursorInResultDataset;
begin
  if (FIsRootAO) then
  begin
   if (FIsMaterialized) then
    TACRDataSet(FResultDataset).ResetHandle
   else
    TACRDataSet(FSourceDataset).ResetHandle;
  end;
end; // ResetRootAOCursorInResultDataset




////////////////////////////////////////////////////////////////////////////////
//
// TACRAOJoin
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// records are called Equal if all their join attributes are equal
//------------------------------------------------------------------------------
procedure TACRAOJoin.CompareRecords;
var i,j,k:            Integer;
    value1, value2:   TACRVariant;
begin
 FLeftAONull := False;
 FRightAONull := False;
 value1 := TACRVariant.Create;
 value2 := TACRVariant.Create;
 try
   for i := 0 to FFields1.ItemCount - 1 do
    begin
     // get first value
     j := FFields1.Items[i];
     GetFieldValue(value1,j);

     // get second value
     k := FFields2.Items[i];
     GetFieldValue(value2,k);

     // compare values
     try
      FCompareResult := value1.Compare(value2,False,False,False);
     except
      on e: EACRException do
       begin
         raise EACRException.Create(10328,ErrorLCompareFieldValues,
          [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName,e.Message]);
       end;
      else
       raise;
     end;
     if (FCompareResult <> cmprEqual) then
       break;
    end;
 finally
   value1.Free;
   value2.Free;
 end; // try .. finally
end; // CompareRecords


function TACRAOJoin.IsIndexExists(Table: TDataset; FieldNames: TACRWideStringList): Boolean;
var i,j,k:     Integer;
    s,name:    WideString;
    bString:   Boolean;
begin
  Result := False;
  for i := 0 to TACRDataSet(Table).IndexDefs.Count - 1 do
   for j := 0 to FieldNames.Count - 1 do
    begin
     name := WideUpperCase(FieldNames[j]);
     bString := IsStringFieldType(TACRDataset(Table).AdvFieldDefs.Find(name).DataType);
     s := WideUpperCase(TACRDataset(Table).IndexDefs[i].Fields);
     k := Pos(';',s);
     if (k > 0) then
      begin
       s := Copy(s,1,k-1);
      end;
     if (name = s) then
      begin
       Result := True;
       if (bString) then
        begin
         if (ixCaseInsensitive in TACRDataset(Table).IndexDefs[i].Options) then
          Result := False;
         if (Result) then
          if (Pos(name,WideUpperCase(TACRDataset(Table).IndexDefs[i].CaseInsFields)) > 0) then
           Result := False;
        end;
       if (Result) then
        Exit;
      end; // index for this field found
    end;
end; // IsIndexExists


//------------------------------------------------------------------------------
// Choose Scan Table
//------------------------------------------------------------------------------
procedure TACRAOJoin.ChooseScanTable;
var bIndexExists1, bIndexExists2: Boolean;
    RecCount1, RecCount2:         Int64;
begin
 if (FJoinType = ajtLeftOuter) then
  begin
   FScanLeft := True;
  end // left
 else
 if (FJoinType = ajtRightOuter) then
  begin
   FScanLeft := False;
  end // right
 else
  begin
   bIndexExists1 := IsIndexExists(FLeftAO.ResultDataset, FFieldNames1);
   bIndexExists2 := IsIndexExists(FRightAO.ResultDataset, FFieldNames2);
   if (bIndexExists1 <> bIndexExists2) then
    begin
     FScanLeft := bIndexExists2;
    end
   else
    begin
     RecCount1 := TACRDataset(FLeftAO.ResultDataset).Handle.GetRecordCount;
     RecCount2 := TACRDataset(FRightAO.ResultDataset).Handle.GetRecordCount;
     if ((not TACRDataset(FLeftAO.ResultDataset).InMemory) and
         (not TACRDataset(FLeftAO.ResultDataset).Handle.Temporary)) then
      if (TACRDataset(FLeftAO.ResultDataset).AdvFieldDefs.IsVarcharExists) then
       RecCount1 := RecCount1 * ACRVarcharSlowDownRate;
     if ((not TACRDataset(FRightAO.ResultDataset).InMemory) and
         (not TACRDataset(FRightAO.ResultDataset).Handle.Temporary)) then
      if (TACRDataset(FRightAO.ResultDataset).AdvFieldDefs.IsVarcharExists) then
       RecCount2 := RecCount2 * ACRVarcharSlowDownRate;
     FScanLeft := (RecCount1 <= RecCount2);
    end;
  end; // inner or full
 if (FScanLeft) then
  begin
   FScanTable := FLeftAO.ResultDataset;
   FFilterTable := FRightAO.ResultDataset;
  end
 else
  begin
   FScanTable := FRightAO.ResultDataset;
   FFilterTable := FLeftAO.ResultDataset;
  end;
end; // ChooseScanTable


//------------------------------------------------------------------------------
// Build Filter Expression
//------------------------------------------------------------------------------
procedure TACRAOJoin.BuildFilterExpression;
var Expr:     TACRExpression;
    i:        Integer;
    count:    Integer;
    Cursor:   TACRCursor;
    RootNode: TACRExprNode;


  function AddComparison(Expr: TACRExpression; FieldName: WideString): TACRExprNode;
  var NodeField, NodeConst: TACRExprNode;
  begin
   NodeField := TACRExprNodeField.Create(Expr,Cursor,FieldName,TACRDataset(FFilterTable).Handle.TableName);
   NodeConst := TACRExprNodeConst.Create(Expr,False,False);
   FConstList.Add(NodeConst);
   Result := TACRExprNodeComparison.Create(Expr,doEQ,NodeField,NodeConst,Expr.CaseInsensitive,False);
  end;

begin
 RootNode := TACRExprNodeBoolean.Create(nil,doAND,False,False);
 Expr := TACRExpression.Create(LSession,LParams,RootNode,nil);
 Expr.CaseInsensitive := FCaseInsensitive;
 RootNode.ParentExpr := Expr;
 Cursor := TACRDataset(FFilterTable).Handle;
 FTempFilterExpr := Expr;
 count := FFields1.ItemCount;

 for i := 0 to count -1 do
  begin
   if (FScanLeft) then
    Expr.AddNode(AddComparison(Expr,FFieldNames2.Strings[i]))
   else
    Expr.AddNode(AddComparison(Expr,FFieldNames1.Strings[i]));
  end;
 
end; // BuildFilterExpression


//------------------------------------------------------------------------------
// prepare filter for current record
//------------------------------------------------------------------------------
procedure TACRAOJoin.PrepareFilterForCurrentRecord;
var
    i,FieldNo:  Integer;
    v:          TACRVariant;
begin
 for i := 0 to FConstList.Count - 1 do
  begin
   v := TACRExprNodeConst(FConstList[i]).GetDataValue;
   if (FScanLeft) then
    FieldNo := FFields1.Items[i]
   else
    FieldNo := FFields2.Items[i];
//TACRTable(FScanTable).
   GetFieldValue(v,FieldNo,True,False);
  end;
end; // PrepareFilterForCurrentRecord


//------------------------------------------------------------------------------
// apply filter and return true if records were found
//------------------------------------------------------------------------------
function TACRAOJoin.ApplyFilterAndCheckIfRecordsFound: Boolean;
var Cursor: TACRCursor;
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter18);
aaStartTime(time18);
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('> TACRAOJoin.ApplyFilterAndCheckIfRecordsFound'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FFilterTableEmpty = '+BoolToStr(FFilterTableEmpty,True)
+#13#10+'FTempFilterExpr = '+IntToHex(Integer(FTempFilterExpr),8)
);
{$ENDIF}
 Result := not FFilterTableEmpty;
 if (Result) then
  begin
   if (FTempFilterExpr <> nil) then
    begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - destroying FTempFilterExpr...'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     TACRExpression(FTempFilterExpr).Free;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - destroying FTempFilterExpr...OK'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     FTempFilterExpr := nil;
    end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - befoe clear const list'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   FConstList.Clear;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - before build expression'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   BuildFilterExpression;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - after build expression'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FTempFilterExpr = '+IntToHex(Integer(FTempFilterExpr),8)
);
{$ENDIF}
   PrepareFilterForCurrentRecord;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - after prepare filter'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FFilterTable = '+IntToHex(Integer(FFilterTable),8)
);
if FFilterTable <> nil then
begin
  aaWriteToLog('FFilterTable.ClassName = '+FFilterTable.ClassName
+#13#10+'Handle = '+IntToHex(Integer(TACRDataSet(FFilterTable).Handle),8)
  );
end;
{$ENDIF}
   Cursor := TACRDataSet(FFilterTable).Handle;
   Cursor.FilterExpression := FTempFilterExpr;
   FFilterApplied := True;
   Cursor.DisableRecordBitmap;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - 1'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FTempFilterExpr = '+IntToHex(Integer(FTempFilterExpr),8)
);
try
{$ENDIF}
   FFilterTable.First;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - 1.5'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FTempFilterExpr = '+IntToHex(Integer(FTempFilterExpr),8)
);
except
 on e: Exception do
  begin
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - Error'
+#13#10+e.Message
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+BoolToStr(Result)
);
  end
 else
  begin
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - Error'
+#13#10+'UNKNOWN ERROR'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+BoolToStr(Result)
);
  end;
end;
{$ENDIF}
   Result := (FFilterTable.RecordCount > 0);
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - 2'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FFilterTable.RecordCount = '+IntToStr(FFilterTable.RecordCount)
+#13#10+'Result = '+BoolToStr(Result)
);
{$ENDIF}
   if (Result) then
    begin
     FLeftAONull := False;
     FRightAONull := False;
    end;
  end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('< TACRAOJoin.ApplyFilterAndCheckIfRecordsFound'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+BoolToStr(Result)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time18);
end;
{$ENDIF}
end; // ApplyFilter


//------------------------------------------------------------------------------
// clear filter
//------------------------------------------------------------------------------
procedure TACRAOJoin.ClearFilter;
var Cursor: TACRCursor;
begin
 if (FFilterApplied) then
  begin
   Cursor := TACRDataset(FFilterTable).Handle;
   Cursor.DisableRecordBitmap;
   Cursor.FilterExpression := nil;
   FFilterTable.First;
   FFilterApplied := False;
  end;
end; // ClearFilter


//------------------------------------------------------------------------------
// Left table is null
//------------------------------------------------------------------------------
procedure TACRAOJoin.SetLeftNull;
begin
  FRightAONull := False;
  FLeftAONull := True;
end; // SetLeftNull


//------------------------------------------------------------------------------
// Right table is null
//------------------------------------------------------------------------------
procedure TACRAOJoin.SetRightNull;
begin
  FRightAONull := True;
  FLeftAONull := False;
end; // SetRightNull


//------------------------------------------------------------------------------
// for full join: switch to scanning rest records in FFilterTable (not found FScanTable)
//------------------------------------------------------------------------------
procedure TACRAOJoin.SwitchToScanningRest;
begin
  ClearFilter;
  FSearchingCorrespondingRecords := False;
  FScanningRestRecords := True;
  if (FScanLeft) then
   SetLeftNull
  else
   SetRightNull;
  FScannedRecords.Sort;
end; // SwitchToScanningRest


//------------------------------------------------------------------------------
// full outer join stores record ID for all scanned records mathcing filters
//------------------------------------------------------------------------------
procedure TACRAOJoin.StoreCurrentRecordID;
var RecordID: TACRRecordID;
begin
  RecordID := TACRDataset(FFilterTable).GetCurrentRecordID;
//  FScannedRecords.Append(RecordID);
  if (FScannedRecords.FindRecordByID(RecordID) < 0) then
    FScannedRecords.Append(RecordID);
end; // StoreCurrentRecordID


//------------------------------------------------------------------------------
// init
//------------------------------------------------------------------------------
procedure TACRAOJoin.Init2;
var i,j,k:     Integer;
    tempList:  TList;
    fields:    TACRIntegerArray;
    sl:        TStringList;
    node:      TACRExprNode;
    nameCRC:   Cardinal;
begin
  for i := 0 to FFieldNames1.Count-1 do
   begin
    j := FFieldLinks[FFields1.Items[i]].FieldNo;
    // check if field was renamed during child materialization
    if (FLeftAO.FFieldLinks[j].DisplayName <> '') and (FLeftAO.IsMaterialized) then
     if (ACRCompareWideString(FFieldNames1[i],FLeftAO.FFieldLinks[j].DisplayName) <> 0) then
      FFieldNames1[i] := FLeftAO.FFieldLinks[j].DisplayName;
   end;
  for i := 0 to FFieldNames2.Count-1 do
   begin
    j := FFieldLinks[FFields2.Items[i]].FieldNo;
    // check if field was renamed during child materialization
    if (FRightAO.FFieldLinks[j].DisplayName <> '') and (FRightAO.IsMaterialized) then
     if (ACRCompareWideString(FFieldNames2[i],FRightAO.FFieldLinks[j].DisplayName) <> 0) then
      FFieldNames2[i] := FRightAO.FFieldLinks[j].DisplayName;
   end;
  FLeftAONull := False;
  FRightAONull := False;
  ChooseScanTable;
  BuildFilterExpression;
  FFilterApplied := False;
  TACRDataset(FFilterTable).Handle.RandomOrder := True;
  FEof := False;
  if (FJoinType = ajtFullOuter) then
   FScannedRecords := TACRRecordIDArray.Create(0,FScanTable.RecordCount div 10,FScanTable.RecordCount);
end; // Init2


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TACRAOJoin.InternalFirst2;
var b: Boolean;
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter16);
aaStartTime(time16);
try
{$ENDIF}
 Init2;
 FScanTable.First;
 FFilterTable.First;
 FSearchingCorrespondingRecords := True;
 FScanningRestRecords := False;
 FFilterTableEmpty := (FFilterTable.RecordCount <= 0);
 if (FJoinType = ajtFullOuter) then
   if (FScanTable.Eof) then
     SwitchToScanningRest;
 if ((not FScanningRestRecords) and (not InternalGetEof)) then
  begin
   b := ApplyFilterAndCheckIfRecordsFound;
   if (b) then
    begin
     if (FJoinType = ajtFullOuter) then
      StoreCurrentRecordID;
    end
   else
    begin
     if (FJoinType = ajtInner) then
      begin
       InternalNext2;
      end
     else
      begin
       if (FScanLeft) then
        SetRightNull
       else
        SetLeftNull;
{
       FNoLinkedRecords := True;
       FShowBlankRecord := True;
}
      end; // outer join
    end;
  end; // scanning scan table
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time16);
end;
{$ENDIF}
end; // InternalFirst2


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TACRAOJoin.InternalNext2;
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter17);
aaStartTime(time17);
try
{$ENDIF}

{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('> TACRAOJoin.InternalNext2.'
+#13#10+'Self = '+IntToHex(Integer(Self),8));
try
{$ENDIF}
 repeat
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - start main loop.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FScanTable.TableName = '+TACRDataset(FScanTable).Handle.TableName
+#13#10+'FFilterTable.TableName = '+TACRDataset(FFilterTable).Handle.TableName
+#13#10+'FScanTable.Eof = '+BoolToStr(FScanTable.Eof,True)
+#13#10+'FFilterTable.Eof = '+BoolToStr(FFilterTable.Eof,True)
+#13#10+'FScanningRestRecords = '+BoolToStr(FScanningRestRecords,True)
+#13#10+'FFilterApplied = '+BoolToStr(FFilterApplied,True)
+#13#10+'FScanLeft = '+BoolToStr(FScanLeft,True)
+#13#10+'FJoinType = '+IntToStr(Integer(FJoinType))
+#13#10+'FScanTable.RecNo = '+IntToStr(TACRDataset(FScanTable).RecNo)
+#13#10+'FFilterTable.RecNo = '+IntToStr(TACRDataset(FFilterTable).RecNo)
+#13#10+'FScanTable.RecordCount = '+IntToStr(TACRDataset(FScanTable).RecordCount)
+#13#10+'FFilterTable.RecordCount = '+IntToStr(TACRDataset(FFilterTable).RecordCount)
);
{$ENDIF}
  if (FScanningRestRecords) then
   begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #0.'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    FFilterTable.Next;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #1.'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    if (not FFilterTable.Eof) then
     begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #1.1.'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
      if (FScannedRecords.FindRecordByID(TACRDataset(FFilterTable).GetCurrentRecordID) < 0) then
       begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #1.1.1'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
        break;
       end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #1.1.2'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     end;
   end // scanning rest records in full outer join
  else
  if (FFilterApplied) then
   begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #2'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    FFilterTable.Next;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #3'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    if (not FFilterTable.Eof) then
     begin
      if (FJoinType = ajtFullOuter) then
       begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #4'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
        StoreCurrentRecordID;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #5'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
       end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #6'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
      Break;
     end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #7'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    ClearFilter;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #8'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
   end // scanning corresponding records
  else
   begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #9'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    FScanTable.Next;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #10'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    if (FScanTable.Eof) then
     begin
      if (FJoinType = ajtFullOuter) then
       begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #11'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
        SwitchToScanningRest;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #12.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FScanTable.TableName = '+TACRDataset(FScanTable).Handle.TableName
+#13#10+'FFilterTable.TableName = '+TACRDataset(FFilterTable).Handle.TableName
+#13#10+'FScanTable.Eof = '+BoolToStr(FScanTable.Eof,True)
+#13#10+'FFilterTable.Eof = '+BoolToStr(FFilterTable.Eof,True)
+#13#10+'FScanningRestRecords = '+BoolToStr(FScanningRestRecords,True)
+#13#10+'FFilterApplied = '+BoolToStr(FFilterApplied,True)
+#13#10+'FScanLeft = '+BoolToStr(FScanLeft,True)
);
{$ENDIF}
        if (not FFilterTable.Eof) then
         if (FScannedRecords.FindRecordByID(TACRDataset(FFilterTable).GetCurrentRecordID) < 0) then
          begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #12.1'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
           break;
          end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #12.2'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
        Continue;
       end
      else
       begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #13'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
         Break;
       end;
     end;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #14'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
    if (ApplyFilterAndCheckIfRecordsFound) then
     begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #15'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
      if (FJoinType = ajtFullOuter) then
       StoreCurrentRecordID;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #16'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
      Break;
     end
    else
     if (FJoinType <> ajtInner) then
      begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #17.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FScanTable.TableName = '+TACRDataset(FScanTable).Handle.TableName
+#13#10+'FFilterTable.TableName = '+TACRDataset(FFilterTable).Handle.TableName
+#13#10+'FScanTable.Eof = '+BoolToStr(FScanTable.Eof,True)
+#13#10+'FFilterTable.Eof = '+BoolToStr(FFilterTable.Eof,True)
+#13#10+'FScanningRestRecords = '+BoolToStr(FScanningRestRecords,True)
+#13#10+'FFilterApplied = '+BoolToStr(FFilterApplied,True)
+#13#10+'FScanLeft = '+BoolToStr(FScanLeft,True)
);
{$ENDIF}
       if (FScanLeft) then
        SetRightNull
       else
        SetLeftNull;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
aaWriteToLog('TACRAOJoin.InternalNext2 - #18'+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
       Break;
      end; // outer join
   end; // scanning FScanTable
 until (Eof);
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalNext2}
finally
aaWriteToLog('< TACRAOJoin.InternalNext2.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FScanTable.RecNo = '+IntToStr(TACRDataset(FScanTable).RecNo)
+#13#10+'FFilterTable.RecNo = '+IntToStr(TACRDataset(FFilterTable).RecNo)
+#13#10+'FScanTable.RecordCount = '+IntToStr(TACRDataset(FScanTable).RecordCount)
+#13#10+'FFilterTable.RecordCount = '+IntToStr(TACRDataset(FFilterTable).RecordCount)
);
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time17);
end;
{$ENDIF}
end; // InternalNext2


//------------------------------------------------------------------------------
// EOF
//------------------------------------------------------------------------------
function TACRAOJoin.InternalGetEof2: Boolean;
begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalGetEof2}
aaWriteToLog('> TACRAOJoin.InternalGetEof2.'
+#13#10+'Self = '+IntToHex(Integer(Self),8));
try
{$ENDIF}
 if (FJoinType = ajtFullOuter) then
  Result := (FFilterTable.Eof and FScanningRestRecords)
 else
 if ((FJoinType = ajtInner) and FFilterTableEmpty) then
  Result := True
 else
  Result := FScanTable.Eof;
{$IFDEF DEBUG_TRACE_TACRAOJoin_InternalGetEof2}
finally
  aaWriteToLog('< TACRAOJoin.InternalGetEof2.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+BoolToStr(Result,True));
end;
{$ENDIF}
end; // InternalGetEof2


//------------------------------------------------------------------------------
// go to first record
//------------------------------------------------------------------------------
procedure TACRAOJoin.InternalFirst;
begin
 FEof := False;
 if (FDekart) then
  begin
   FLeftAO.First;
   FRightAO.First;
   if (FLeftAO.Eof or FRightAO.Eof) then
    FEof := true;
  end
 else
  begin
    InternalFirst2;
  end; // inner ot outer join
end; // First


//------------------------------------------------------------------------------
// go to next record
//------------------------------------------------------------------------------
procedure TACRAOJoin.InternalNext;
begin
 if (FDekart) then
  begin
   FRightAO.Next;
   if (FRightAO.Eof) then
    begin
     FLeftAO.Next;
     if (not FLeftAO.Eof) then
      FRightAO.First;
    end // Eof
  end // Dekart
 else
  begin
    InternalNext2;
  end; // inner or outer
end; // InternalNext


//------------------------------------------------------------------------------
// return true if cursor points to the last record
//------------------------------------------------------------------------------
function TACRAOJoin.InternalGetEof: Boolean;
begin
 if (FDekart) then
  Result := FLeftAO.Eof or FRightAO.Eof
 else
  begin
    Result := InternalGetEOF2;
  end;
end; // InternalGetEof


//------------------------------------------------------------------------------
// return number of records
//------------------------------------------------------------------------------
function TACRAOJoin.InternalGetRecordCount: Integer;
begin
 Result := 0;
 if (FIsMaterialized) then
  Result := FResultDataset.RecordCount
 else
 begin
   // aproximate record count
   if (FDekart) then
    Result := FLeftAO.RecordCount * FRightAO.RecordCount
   else
    begin
     if (FOuterJoin) then
      begin
       if (FLeftAO.RecordCount <= 0) then
        Result := FRightAO.RecordCount
       else
       if (FRightAO.RecordCount <= 0) then
        Result := FLeftAO.RecordCount
       else
      end
     else
      begin
       if ((FLeftAO.RecordCount > 0) and (FRightAO.RecordCount > 0)) then
        Result := Max(FLeftAO.RecordCount,FRightAO.RecordCount);
      end;
    end;
 end;
end; // GetRecordCount


//------------------------------------------------------------------------------
// finalizes the materialization process - destroy objects
//------------------------------------------------------------------------------
procedure TACRAOJoin.FinalizeMaterialization;
begin
 // implemented in v.5.30
 ClearFilter;
 if (FTempFilterExpr <> nil) then
  begin
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - destroying FTempFilterExpr...'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     TACRExpression(FTempFilterExpr).Free;
{$IFDEF DEBUG_TRACE_TACRAOJoin_ApplyFilterAndCheckIfRecordsFound}
aaWriteToLog('TACRAOJoin.ApplyFilterAndCheckIfRecordsFound - destroying FTempFilterExpr...OK'
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
     FTempFilterExpr := nil;
  end;
 inherited FinalizeMaterialization;
end; // FinalizeMaterialization


//------------------------------------------------------------------------------
// mapping function - return number of found fields and found field No
// also optionally unhides fields in AO
//------------------------------------------------------------------------------
function TACRAOJoin.FieldExists(
              FieldName, TableName: WideString;
              Unhide:               Boolean;
              FieldNumbers:         TACRIntegerArray;
              UnhideChildrenOnly:   Boolean
                  ): Integer;
var i,j,k:      Integer;
    fname:      WideString;
    tempArray:  TACRIntegerArray;
begin
  if ((FIsNatural or FUsing) and (FieldName = '*')) then
  begin
   // unhide or field numbers
   tempArray := TACRIntegerArray.Create(0,1,100);
   try
     if (FLeftAO <> nil) then
       FLeftAO.FieldExists(FieldName,TableName,Unhide, tempArray);
     for i := 0 to FFieldCount-1 do
      if ((WideUpperCase(TableName) = WideUpperCase(FTableName)) and
         (FFieldLinks[i].IsExpression)) or
         ((FLeftAO <> nil) and
            (FFieldLinks[i].AO = FLeftAO) and
            (tempArray.IsValueExists(FFieldLinks[i].FieldNo))) then
       begin
        inc(result);
        if (FieldNumbers <> nil) then
         FieldNumbers.Append(i);
        // group by does not needs in unhiding
        // it will cause hidden fields to be appeared in result dataset
        if (Unhide) and (not UnhideChildrenOnly) then
          FFieldLinks[i].IsHidden := false;
       end;
     tempArray.SetSize(0);
     if (FRightAO <> nil) then
      begin
       FRightAO.FieldExists(FieldName,TableName,Unhide, tempArray);
       for i := 0 to FFieldCount-1 do
       if ((FRightAO <> nil) and
            (FFieldLinks[i].AO = FRightAO) and
            (not FFields2.IsValueExists(i)) and
            (tempArray.IsValueExists(FFieldLinks[i].FieldNo))) then
         begin
          inc(result);
          if (FieldNumbers <> nil) then
           FieldNumbers.Append(i);
          // group by does not needs in unhiding
          // it will cause hidden fields to be appeared in result dataset
          if (Unhide) and (not UnhideChildrenOnly) then
           FFieldLinks[i].IsHidden := false;
         end;
      end; // RightAO is not materialized
   finally
    tempArray.Free;
   end;
  end
  else
   Result := inherited FieldExists(FieldName,TableName,Unhide,FieldNumbers,UnhideChildrenOnly);
end; // FieldExists


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRAOJoin.Create(
                      aSession:   TACRBaseSession;
                      aParams:    TACRSQLParams;
                      LeftChild:  TACRAO;
                      RightChild: TACRAO;
                      JoinType:   TACRJoinType;
                      IsNatural:  Boolean;
                      IsUsing:    Boolean;
                      FieldList1: TACRFields; // join fields
                      FieldList2: TACRFields  // field1 = field2
                      );
var i,j,k,l1,l2:            Integer;
    bIndexExists:           Boolean;

 procedure FillIndexNames;
 var s: WideString;
 begin
   if (FFieldLinks[j].AO = FLeftAO) then
    begin
      s := FLeftAO.FFieldLinks[FFieldLinks[j].FieldNo].FieldName;
      FFieldNames1.Add(s);
    end // LeftAO
   else
    begin
      s := FRightAO.FFieldLinks[FFieldLinks[j].FieldNo].FieldName;
      FFieldNames2.Add(s);
    end; // RightAO
 end;


begin
 InternalCreate(aSession,aParams,LeftChild,RightChild);
 FFieldNames1 := nil;
 FFieldNames2 := nil;
 FConstList := nil;
 FBookmark := nil;
 FScannedRecords := nil;
 FTempFilterExpr := nil;
 FJoinType := JoinType;
 FIsNatural := IsNatural;
 FUsing := IsUsing;
 FInnerJoin := (FJoinType = ajtInner);
 FDekart := (FJoinType = ajtCross);
 FOuterJoin := (FJoinType = ajtLeftOuter) or
               (FJoinType = ajtRightOuter) or
               (FJoinType = ajtFullOuter);
 l1 := 0;
 l2 := 0;
 if (not FDekart) and (not IsNatural) then
  begin
   l1 := FieldList1.ItemCount;
   l2 := FieldList2.ItemCount;
   if (l1 <> l2) then
     raise EACRException.Create(10330,ErrorLDifferentListsLength,[l1,l2]);
  end;
 FEof := false;
 FEqualStarted := false;
 FFirstTimeCalled := true;
 FFields1 :=  TACRIntegerArray.Create(0,1,FLeftAO.FieldCount);
 FFields2 := TACRIntegerArray.Create(0,1,FRightAO.FieldCount);
 // creating field links for none-union joins
 FFieldCount := FLeftAO.FieldCount + FRightAO.FieldCount;
 SetLength(FFieldLinks,FFieldCount);
 // linking left child
 j := FLeftAO.FieldCount-1;
 for i := 0 to j do
  begin
   FFieldLinks[i].FieldNo := i;
   FFieldLinks[i].Dataset := nil;
   FFieldLinks[i].AO := FLeftAO;
   FFieldLinks[i].FieldName := FLeftAO.FFieldLinks[i].FieldName;
   FFieldLinks[i].OriginalFieldName := FFieldLinks[i].FieldName;
   FFieldLinks[i].DisplayName := '';
   FFieldLinks[i].TableName := FLeftAO.FFieldLinks[i].TableName;
   FFieldLinks[i].TableAlias := FLeftAO.FFieldLinks[i].TableAlias;
   FFieldLinks[i].FieldType := FLeftAO.FFieldLinks[i].FieldType;
   FFieldLinks[i].FieldSize := FLeftAO.FFieldLinks[i].FieldSize;
   FFieldLinks[i].IsHidden := FLeftAO.FFieldLinks[i].IsHidden;
   FFieldLinks[i].IsExpression := FLeftAO.FFieldLinks[i].IsExpression;
   FFieldLinks[i].IsAggregate := FLeftAO.FFieldLinks[i].IsAggregate;
   FFieldLinks[i].BLOBCompressionAlgorithm := FLeftAO.FFieldLinks[i].BLOBCompressionAlgorithm;
   FFieldLinks[i].BLOBCompressionMode := FLeftAO.FFieldLinks[i].BLOBCompressionMode;
   FFieldLinks[i].BLOBBlockSize := FLeftAO.FFieldLinks[i].BLOBBlockSize;
  end;
 inc(j);
 // linking right child
 for i := 0 to FRightAO.FieldCount-1 do
  begin
   FFieldLinks[j+i].FieldNo := i;
   FFieldLinks[j+i].Dataset := nil;
   FFieldLinks[j+i].AO := FRightAO;
   FFieldLinks[j+i].FieldName := FRightAO.FFieldLinks[i].FieldName;
   FFieldLinks[j+i].OriginalFieldName := FFieldLinks[j+i].FieldName;
   FFieldLinks[j+i].DisplayName := '';
   FFieldLinks[j+i].TableName := FRightAO.FFieldLinks[i].TableName;
   FFieldLinks[j+i].TableAlias := FRightAO.FFieldLinks[i].TableAlias;
   FFieldLinks[j+i].FieldType := FRightAO.FFieldLinks[i].FieldType;
   FFieldLinks[j+i].FieldSize := FRightAO.FFieldLinks[i].FieldSize;
   FFieldLinks[j+i].IsHidden := FRightAO.FFieldLinks[i].IsHidden;
   FFieldLinks[j+i].IsExpression := FRightAO.FFieldLinks[i].IsExpression;
   FFieldLinks[j+i].IsAggregate := FRightAO.FFieldLinks[i].IsAggregate;
   FFieldLinks[j+i].BLOBCompressionAlgorithm := FRightAO.FFieldLinks[i].BLOBCompressionAlgorithm;
   FFieldLinks[j+i].BLOBCompressionMode := FRightAO.FFieldLinks[i].BLOBCompressionMode;
   FFieldLinks[j+i].BLOBBlockSize := FRightAO.FFieldLinks[i].BLOBBlockSize;
   if (IsNatural) then
    for k := 0 to j-1 do
     if (WideUpperCase(FFieldLinks[j+i].FieldName) =
         WideUpperCase(FFieldLinks[k].FieldName)) then
      begin
       FFields1.Append(k);
       FFields2.Append(j+i);
       FFieldLinks[k].IsHidden := false;
       FFieldLinks[j+i].IsHidden := false;
       FLeftAO.FieldExists(FFieldLinks[k].FieldName,'',True);
       FRightAO.FieldExists(FFieldLinks[j+i].FieldName,'',True);
      end; // natural join
  end;
 if (FInnerJoin or FOuterJoin)  then
  begin
   if (not IsNatural) then
    begin
     // creating join fields lists
     for i := 0 to l1-1 do
      begin
       // join fields should not be hidden
       j := FieldExists(
        FieldList1.Items[i].FieldName,
        FieldList1.Items[i].TableName,True,FFields1);
       // modified in v.5.90
//       if (j <> 1) then
       if (j < 1) then
         raise EACRException.Create(10331,ErrorLInvalidJoinField,
          [FieldList1.Items[i].TableName,FieldList1.Items[i].FieldName,i,j]);
      end;
     for i := 0 to l2-1 do
      begin
       j := FieldExists(
        FieldList2.Items[i].FieldName,
        FieldList2.Items[i].TableName,True,FFields2);
       // modified in v.5.90
//     if (j <> 1) then
       if (j < 1) then
         raise EACRException.Create(10332,ErrorLInvalidJoinField,
          [FieldList2.Items[i].TableName,FieldList2.Items[i].FieldName,i,j]);
      end;
    end; // not natural
   // commented in v.5.90
//   if (FFields1.ItemCount <> FFields2.ItemCount) then
//    raise EACRException.Create(10332,ErrorLDifferentListsLength,[FFields1.ItemCount,FFields2.ItemCount]);
   if (FFields1.ItemCount <= 0) then
    raise EACRException.Create(10333,ErrorLEmptyFieldList,[FFields1.ItemCount]);
   FFieldNames1 := TACRWideStringList.Create;
   FFieldNames2 := TACRWideStringList.Create;
   FConstList := TList.Create;
   // filling Left and Right fields
   for i := 0 to FFields1.ItemCount-1 do
    begin
     j := FFields1.Items[i];
     k := FFields2.Items[i];
     if (FFieldLinks[j].AO = FFieldLinks[k].AO) then
      raise EACRException.Create(10334,ErrorLBothJoinAOEqual,[FFieldLinks[j].FieldName,
        FFieldLinks[k].FieldName,j,k])
     else
      if (FFieldLinks[j].AO = FRightAO) then
       begin
        // swap left / right join fields
        FFields1.Items[i] := k;
        FFields2.Items[i] := j;
        j := FFields1.Items[i];
        k := FFields2.Items[i];
       end;
     FillIndexNames;
     j := k;
     FillIndexNames;
    end;
  end; // inner or outer joins
  SetFieldNames;
  // create index for join fields in one of child AO
  // if it does not exist
  bIndexExists := False;
  if (FInnerJoin or (FJoinType = ajtFullOuter)) then
   begin
    if (FLeftAO.FIsAOTable) then
      bIndexExists := IsIndexExists(TACRAOTable(FLeftAO).FSourceDataset, FFieldNames1);
    if (not bIndexExists) then
      if (FRightAO.FIsAOTable) then
        bIndexExists := IsIndexExists(TACRAOTable(FRightAO).FSourceDataset, FFieldNames2);
    if (not bIndexExists) then
     begin
      FLeftAO.CreateResultIndexLists(False,FFieldNames1.Count);
      for i := 0 to FFieldNames1.Count-1 do
       begin
        FLeftAO.FResultIndexFieldNumbers.Items[i] := FFieldLinks[FFields1.Items[i]].FieldNo;
        FLeftAO.FResultIndexFieldsList[i] := FFieldNames1[i];
        FLeftAO.FResultIndexCaseInsFieldsList[i] := ACR_CASE;
        FLeftAO.FResultIndexAscDescFieldsList[i] := ACR_ASC;
       end;
     end;
   end // (FInnerJoin or (FJoinType = ajtFullOuter))
  else
  if (FOuterJoin) then
   begin
    if (FJoinType = ajtLeftOuter) then
     begin
      // left outer join
      if (FRightAO.FIsAOTable) then
        bIndexExists := IsIndexExists(TACRAOTable(FRightAO).FSourceDataset, FFieldNames2);
      if (not bIndexExists) then
       begin
        FRightAO.CreateResultIndexLists(False,FFieldNames2.Count);
        for i := 0 to FFieldNames1.Count-1 do
         begin
          FRightAO.FResultIndexFieldNumbers.Items[i] := FFieldLinks[FFields2.Items[i]].FieldNo;
          FRightAO.FResultIndexFieldsList[i] := FFieldNames2[i];
          FRightAO.FResultIndexCaseInsFieldsList[i] := ACR_CASE;
          FRightAO.FResultIndexAscDescFieldsList[i] := ACR_ASC;
         end;
       end;
     end // left outer join
    else
     begin
      // right outer join
      if (FLeftAO.FIsAOTable) then
        bIndexExists := IsIndexExists(TACRAOTable(FLeftAO).FSourceDataset, FFieldNames1);
      if (not bIndexExists) then
       begin
        FLeftAO.CreateResultIndexLists(False,FFieldNames1.Count);
        for i := 0 to FFieldNames1.Count-1 do
         begin
          FLeftAO.FResultIndexFieldNumbers.Items[i] := FFieldLinks[FFields1.Items[i]].FieldNo;
          FLeftAO.FResultIndexFieldsList[i] := FFieldNames1[i];
          FLeftAO.FResultIndexCaseInsFieldsList[i] := ACR_CASE;
          FLeftAO.FResultIndexAscDescFieldsList[i] := ACR_ASC;
         end;
       end;
     end; // // right outer join
   end; // FOuterJoin
  FIsMaterialized := False;
end; // create;


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRAOJoin.Destroy;
begin
 if (FFields1 <> nil) then
   FFields1.Free;
 if (FFields2 <> nil) then
  FFields2.Free;
 if (FFieldNames1 <> nil) then
   FFieldNames1.Free;
 if (FFieldNames2 <> nil) then
  FFieldNames2.Free;
 if (FConstList <> nil) then
  FConstList.Free;
 if (FTempFilterExpr <> nil) then
  FTempFilterExpr.Free;
 if (FScannedRecords <> nil) then
  FScannedRecords.Free;
 inherited Destroy;
end; // destroy


////////////////////////////////////////////////////////////////////////////////
//
// TACRAOUnion
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// records are called Equal if all their join attributes are equal
// return true if search ao has record like in scan ao
//------------------------------------------------------------------------------
function TACRAOUnion.CompareRecords: Boolean;
var i,j,k:   Integer;
    crc:     Cardinal;
    Fields:  TACRIntegerArray;
begin
 if (FRecordCRCValues.ItemCount <= 0) then
  Result := False
 else
  begin
    if (FScanAO = FLeftAO) then
      Fields := FFields1
    else
      Fields := FFields2;
    crc := 0;
    for i := 0 to Fields.ItemCount-1 do
      begin
       FScanAO.GetFieldValue(FValue,Fields.Items[i],False,False);
       if (i = 0) then
        crc := FValue.GetBinaryHash
       else
        crc := ACRAddCRC(crc,FValue.GetBinaryHash,i);
      end;
    Result := (FRecordCRCValues.IndexOf(Integer(crc)) >= 0);  
  end;
end; // CompareRecords


//------------------------------------------------------------------------------
// search next record starting from current position
//------------------------------------------------------------------------------
procedure TACRAOUnion.SearchRecord;
var b: Boolean;

 function IsRecordSuitable: Boolean;
 begin
  Result := ((FUnionType = autExcept) and (not b)) or
            ((FUnionType = autIntersect) and b);
 end; // IsRecordSuitable

begin
  b := CompareRecords;
  while ((not Eof) and (not IsRecordSuitable)) do
   begin
    FScanAO.Next;
    if (not Eof) then
     b := CompareRecords;
   end;
end; // SearchRecord


//------------------------------------------------------------------------------
// calculate record CRC values
//------------------------------------------------------------------------------
procedure TACRAOUnion.CalculateRecordCRCValues;
var i,n:    Integer;
    crc:    Cardinal;
    Fields: TACRIntegerArray;

begin
 if (FUnionType = autExcept) then
  begin
   // except
   FScanAO := FLeftAO;
   FSearchAO := FRightAO;
   Fields := FFields2;
   ShowLeftAO;
  end
 else
  begin
   // intersect
   if (FLeftAO.RecordCount <= FRightAO.RecordCount) then
    begin
      FScanAO := FRightAO;
      FSearchAO := FLeftAO;
      Fields := FFields1;
      ShowRightAO;
    end
   else
    begin
      FScanAO := FLeftAO;
      FSearchAO := FRightAO;
      Fields := FFields2;
      ShowLeftAO;
    end;
  end;
 FRecordCRCValues.SetSize(FSearchAO.RecordCount);
 if (FRecordCRCValues.ItemCount > 0) then
  begin
   FSearchAO.First;
   n := 0;
   while ((not FSearchAO.Eof) and (n < FRecordCRCValues.ItemCount)) do
    begin
     crc := 0;
     for i := 0 to Fields.ItemCount-1 do
      begin
       FSearchAO.GetFieldValue(FValue,Fields.Items[i],False,False);
       if (i = 0) then
        crc := FValue.GetBinaryHash
       else
        crc := ACRAddCRC(crc,FValue.GetBinaryHash,i);
      end;
     FRecordCRCValues.Items[n] := Integer(crc);
     Inc(n);
     FSearchAO.Next;
    end;
  end;
end; // CalculateRecordCRCValues


//------------------------------------------------------------------------------
// create field maps
//------------------------------------------------------------------------------
procedure TACRAOUnion.CreateFieldMaps(IsCorresponding, bDistinct: Boolean; FieldList: TACRFields);

procedure AddFieldToFieldLists(LeftIndex: integer; RightIndex: integer);
var LeftFieldName: WideString;
begin
      if (GetCommonDataType(
          FLeftAO.FFieldLinks[LeftIndex].FieldType,
          FRightAO.FFieldLinks[RightIndex].FieldType) <> aftUnknown) then
       if (((FUnionType = autUnion) and (bDistinct)) or
           IsConvertableFieldType(FLeftAO.FFieldLinks[LeftIndex].FieldType)) then
        begin
         inc(FFieldCount);
         SetLength(FFieldLinks,FFieldCount);
         if (FLeftAO.FFieldLinks[LeftIndex].DisplayName <> '') then
          LeftFieldName := FLeftAO.FFieldLinks[LeftIndex].DisplayName
         else
          LeftFieldName := FLeftAO.FFieldLinks[LeftIndex].FieldName;
         FFieldLinks[FFieldCount-1].FieldName := LeftFieldName;
         FFieldLinks[FFieldCount-1].DisplayName := LeftFieldName;
         FFieldLinks[FFieldCount-1].TableName := FLeftAO.FFieldLinks[LeftIndex].TableName;
         FFieldLinks[FFieldCount-1].TableAlias := FLeftAO.FFieldLinks[LeftIndex].TableAlias;
         FFieldLinks[FFieldCount-1].FieldType := FLeftAO.FFieldLinks[LeftIndex].FieldType;
         FFieldLinks[FFieldCount-1].FieldSize := Max(FLeftAO.FFieldLinks[LeftIndex].FieldSize,
                                                     FRightAO.FFieldLinks[RightIndex].FieldSize);
         FFieldLinks[FFieldCount-1].FieldPrecision := Max(FLeftAO.FFieldLinks[LeftIndex].FieldPrecision,
                                                     FRightAO.FFieldLinks[RightIndex].FieldPrecision);
         FFieldLinks[FFieldCount-1].BLOBCompressionAlgorithm := FLeftAO.FFieldLinks[LeftIndex].BLOBCompressionAlgorithm;
         FFieldLinks[FFieldCount-1].BLOBCompressionMode := FLeftAO.FFieldLinks[LeftIndex].BLOBCompressionMode;
         FFieldLinks[FFieldCount-1].BLOBBlockSize := Max(FLeftAO.FFieldLinks[LeftIndex].BLOBBlockSize,
                                                         FRightAO.FFieldLinks[RightIndex].BLOBBlockSize);
         FFieldLinks[FFieldCount-1].IsHidden := False;
         FFieldLinks[FFieldCount-1].AO := FLeftAO;
         FFieldLinks[FFieldCount-1].Dataset := nil;
         FFieldLinks[FFieldCount-1].FieldNo := LeftIndex;
         FFieldLinks[FFieldCount-1].IsExpression := False;
         FFieldLinks[FFieldCount-1].IsAggregate := False;

         FFields1.Append(LeftIndex);
         FFields2.Append(RightIndex);
        end;
end; // AddFieldToFieldLists

var LeftFieldName,RightFieldName: WideString;
var maxFieldNo,i,j,k,n,f1,f2:      Integer;
begin
 FFields1 :=  TACRIntegerArray.Create(0,1,FLeftAO.FieldCount);
 FFields2 := TACRIntegerArray.Create(0,1,FRightAO.FieldCount);
 if (FieldList = nil) then
  begin
   // modified in 5.01
   // automatic fields detection
   if (FLeftAO.FResultFieldsOrder.ItemCount <= 0) then
    raise EACRException.Create(11985,ErrorLLeftAOHasNoResultFields,[Integer(FUnionType),
            Self.ClassName,FLeftAO.ClassName,IntToHex(Integer(FLeftAO),8)]);
   if (FRightAO.FResultFieldsOrder.ItemCount <= 0) then
    raise EACRException.Create(11986,ErrorLRightAOHasNoResultFields,[Integer(FUnionType),
            Self.ClassName,FRightAO.ClassName,IntToHex(Integer(FRightAO),8)]);
   maxFieldNo := Min(FLeftAO.FResultFieldsOrder.ItemCount,
                    FRightAO.FResultFieldsOrder.ItemCount)-1;
   if (IsCorresponding) then
    begin
     for i := 0 to maxFieldNo do
      begin
        FResultFieldsOrder.Append(i);
        f1 := FLeftAO.FResultFieldsOrder.Items[i];
        LeftFieldName := FLeftAO.GetResultFieldName(f1);
        f2 := -1;
        for j := 0 to FRightAO.FResultFieldsOrder.ItemCount-1 do
         begin
          k := FRightAO.FResultFieldsOrder.Items[i];
          RightFieldName := FRightAO.GetResultFieldName(k);
          if (LeftFieldName = RightFieldName) then
           begin
            f2 := k;
            break;
           end;
         end;
        if (f2 >= 0) then
         AddFieldToFieldLists(f1,f2);
      end;
    end
   else
    begin
     for i := 0 to maxFieldNo do
      begin
        FResultFieldsOrder.Append(i);
        f1 := FLeftAO.FResultFieldsOrder.Items[i];
        f2 := FRightAO.FResultFieldsOrder.Items[i];
        AddFieldToFieldLists(f1,f2);
      end;
    end;
{
   // last field index in FRightAO that was added to FFields2
   k := -1;
   // scanning all fields in FLeftAO
   for i := 0 to FLeftAO.FieldCount-1 do
    begin
     if (FLeftAO.FFieldLinks[i].IsHidden) then
      continue;
     if (IsCorresponding) then
      begin
       k := -1;
       LeftFieldName := FLeftAO.GetResultFieldName(i);
       for j := 0 to FRightAO.FieldCount-1 do
        begin
         if (FRightAO.FFieldLinks[j].IsHidden) then
           continue;
         RightFieldName := FRightAO.GetResultFieldName(j);
         if (LeftFieldName = RightFieldName) then
          begin
           k := j;
           break;
          end;
        end;
      end // searching for corresponding field
     else
      begin
       if (k < 0) then
        f2 := 0
       else
        Inc(f2);
       if (f2 >= FRightAO.FieldCount) then
        begin
         // all fields are linked - exit from the loop
         break;
        end
       else
       // scan FRightAO fields
         while (f2 < FRightAO.FieldCount) do
          begin
           if (FRightAO.FResultFieldCount > 0) then
            begin
             if (FRightAO.FResultFieldsOrder.IndexOf(f2) < 0) then
              Inc(f2)
             else
              begin
               k := f2;
               break;
              end;
            end
           else
            begin
             if (FRightAO.FFieldLinks[f2].IsHidden) then
              Inc(f2)
             else
              begin
               k := f2;
               break;
              end;
            end;
          end; // scanning right AO
      end; // corresponding fields by number (not IsCorresponding)
     if (k >= 0) then
      AddFieldToFieldLists(i,k);
    end; // scanning all fields in FLeftAO
}
  end // no corresponding fields were specified
 else
  begin
   // scanning FieldList
   n := FieldList.ItemCount;
   FResultFieldsOrder.SetSize(n);
   if (n <= 0) then
    raise EACRException.Create(10337,ErrorLEmptyFieldList,[n]);
   for i := 0 to n-1 do
    begin
     // store field name
     LeftFieldName := WideUpperCase(FieldList.Items[i].FieldName);
     // scanning LeftAO
     f1 := -1;
     for j := 0 to FLeftAO.FieldCount-1 do
      begin
       if (FLeftAO.FFieldLinks[j].IsHidden) then
        continue;
       if (LeftFieldName = WideUpperCase(FLeftAO.GetResultFieldName(j))) then
        begin
         f1 := j;
         break;
        end;
      end; // scanning LeftAO
     // scanning RightAO
     f2 := -1;
     for j := 0 to FRightAO.FResultDataset.FieldCount-1 do
      begin
       if (FRightAO.FFieldLinks[j].IsHidden) then
        continue;
       if (LeftFieldName = WideUpperCase(FRightAO.GetResultFieldName(j))) then
        begin
         f2 := j;
         break;
        end;
      end; // scanning RightAO
     if (f1 >= 0) and (f2 >= 0) then
      begin
        FResultFieldsOrder.Items[i] := i;
        AddFieldToFieldLists(f1,f2);
      end; // adding field to the union field list
    end; // scanning FieldList
  end; // corresponding fields were specified
 if (FFields1.ItemCount <> FFields2.ItemCount) then
  raise EACRException.Create(10338,ErrorLDifferentListsLength,
        [FFields1.ItemCount,FFields2.ItemCount]);
 if (FFields1.ItemCount <= 0) then
  raise EACRException.Create(10339,ErrorLEmptyFieldList,[FFields1.ItemCount]);
 FResultFieldCount := FResultFieldsOrder.ItemCount;
end; // CreateFieldMaps


//------------------------------------------------------------------------------
// show recrod from LeftAO
//------------------------------------------------------------------------------
procedure TACRAOUnion.ShowLeftAO;
var i: Integer;
begin
 FShowLeft := True;
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].AO := FLeftAO;
   FFieldLinks[i].FieldNo := FFields1.Items[i];
  end;
end; // ShowLeftAO


//------------------------------------------------------------------------------
// show recrod from RightAO
//------------------------------------------------------------------------------
procedure TACRAOUnion.ShowRightAO;
var i: Integer;
begin
 FShowLeft := False;
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].AO := FRightAO;
   FFieldLinks[i].FieldNo := FFields2.Items[i];
  end;
end; // ShowRightAO


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TACRAOUnion.InternalFirst;
begin
 FLeftAO.First;
 FRightAO.First;
 if (FUnionType = autUnion) then
  begin
   if (not Eof) then
    if (FLeftAO.Eof) then
     ShowRightAO;
  end
 else
  begin
    CalculateRecordCRCValues;
    if (Eof) then Exit;
    SearchRecord;
  end;
end; // InternalFirst


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TACRAOUnion.InternalNext;
begin
 if (Eof) then Exit;
 if (FUnionType = autUnion) then
  begin
   if (not FShowLeft) then
    FRightAO.Next
   else
    FLeftAO.Next;
   if (FShowLeft and (FLeftAO.Eof) and (not FRightAO.Eof)) then
    begin
     ShowRightAO;
     FShowLeft := false;
     // switch to the right AO
    end;
  end
 else
  begin
    FScanAO.Next;
    SearchRecord;
  end;
end; // InternalNext



//------------------------------------------------------------------------------
// Eof
//------------------------------------------------------------------------------
function TACRAOUnion.InternalGetEof: Boolean;
begin
 case FUnionType of
  autUnion: Result := FLeftAO.Eof and FRightAO.Eof;
  autExcept: Result := FScanAO.Eof;
  autIntersect: Result := (FScanAO.Eof or (FRecordCRCValues.ItemCount = 0));
 end;
end; // InternalGetEof


//------------------------------------------------------------------------------
// return recordcount
//------------------------------------------------------------------------------
function TACRAOUnion.InternalGetRecordCount: Integer;
begin
 result := 0;
 if (FIsMaterialized) then
  result := FResultDataset.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRAOUnion.Create(
                      aSession:   TACRBaseSession;
                      aParams:    TACRSQLParams;
                      LeftChild:  TACRAO;
                      RightChild: TACRAO;
                      UnionType:   TACRUnionType;
                      IsCorresponding:  Boolean = False;
                      bDistinct: Boolean = True;
                      FieldList: TACRFields = nil // corresponding fields
                      );
var i,j,k,n: Integer;
begin
 InternalCreate(aSession,aParams,LeftChild,RightChild);
 FIsMaterialized := False;
 FFirstTimeCalled := false;
 FLeftAONull := false;
 FRightAONull := false;
 FShowLeft := true;
 FUnionType := UnionType;
 if (FUnionType = autUnion) then
  begin
   FRecordCRCValues := nil;
   FValue := nil;
  end
 else
  begin
   FValue := TACRVariant.Create;
   FRecordCRCValues := TACRIntegerArray.Create;
  end;
// commented 5.01  
{
 if (FRightAO.FIndexFieldNames <> '') then
  begin
   // apply it to the union
   SetIndex(FRightAO.FIndexFieldNames,FRightAO.FDescFields,FRightAO.FCaseInsensitiveFields,'',True);
   FRightAO.FIndexFieldNames := '';
   FRightAO.FDescFields := '';
   FRightAO.FCaseInsensitiveFields := '';
   FRightAO.FreeResultIndexLists;
  end;
}
 FFields1 := nil;
 FFields2 := nil;
 // modified in 5.01
 CreateFieldMaps(IsCorresponding,bDistinct,FieldList);
 if (bDistinct) then
   ApplyDistinct;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRAOUnion.Destroy;
begin
 if (FRecordCRCValues <> nil) then
   FreeAndNil(FRecordCRCValues);
 if (FValue <> nil) then
   FreeAndNil(FValue);
 if (FFields1 <> nil) then
   FreeAndNil(FFields1);
 if (FFields2 <> nil) then
   FreeAndNil(FFields2);
 inherited Destroy;
end; // destroy


////////////////////////////////////////////////////////////////////////////////
//
// TACRAOGroupBy
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return true if new group is started from current record
//------------------------------------------------------------------------------
function TACRAOGroupBy.CompareRecords(bFirstTime: Boolean = false): Boolean;
var i,j:    Integer;
    value1: TACRVariant;
begin
 Result := False;
 value1 := TACRVariant.Create;
 try
   for i := 0 to FFields.ItemCount - 1 do
    begin
     // get Current value
     j := FFields.Items[i];
     FLeftAO.GetFieldValue(value1,j);
     // compare values
     if (not bFirstTime) then
      if (not Result) then
       Result := (value1.Compare(FValues[i],False,False,False) <> cmprEqual);
     FValues[i].Assign(value1,True); 
    end;
 finally
   value1.Free;
 end;
end; // CompareRecords


//------------------------------------------------------------------------------
// initialize expressions
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.Init;
var i: integer;
begin
 if (FAggregateExpressionsExists) then
  for i := 0 to FFieldCount-1 do
   if ((FFieldLinks[i].IsAggregate) and (FFieldLinks[i].Expr <> nil)) then
     TACRExpression(FFieldLinks[i].Expr).Init;
 if (FFilterExpr <> nil) then
  if (TACRExpression(FFilterExpr).IsAggregated) then
   TACRExpression(FFilterExpr).Init;
end; // initialize expressions


//------------------------------------------------------------------------------
// accumulate aggregate expressions
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.Accumulate(Increment: Integer);
var i: integer;
begin
 if (FAggregateExpressionsExists) then
  for i := 0 to FFieldCount-1 do
   if ((FFieldLinks[i].IsAggregate) and (FFieldLinks[i].Expr <> nil)) then
     TACRExpression(FFieldLinks[i].Expr).Accumulate(Increment);
 if (FFilterExpr <> nil) then
  if (TACRExpression(FFilterExpr).IsAggregated) then
   TACRExpression(FFilterExpr).Accumulate(Increment);
end; // accumulate aggregate expressions


//------------------------------------------------------------------------------
// scan group
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.ScanGroup;
var
    bCompare: Boolean;
begin
 Init;
 CompareRecords(True);
 Accumulate;
 FLeftAO.Next;
 while (not FLeftAO.Eof) do
  begin
   bCompare := CompareRecords(False);
   if (bCompare) then
    begin
     FLeftAO.FResultDataset.Prior;
     break;
    end;
   Accumulate;
   FLeftAO.Next;
  end;
end; // ScanGroup


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.InternalFirst;
begin
 FLeftAO.First;
 FEof := False;
 if (FLeftAO.Eof) then
  begin
   if (FAggregateExpressionsExists) then
    begin
     FAllFieldsNull := True;
     Init;
    end
   else
    FEof := True
  end
 else
  begin
   // added in v.5.70
   FAllFieldsNull := False;
   if (FAllFields) then
    begin
     Init;
     if (not FRecordCountOnly) then
      while (not FLeftAO.Eof) do
       begin
        Accumulate;
        FLeftAO.Next;
       end;
    end
   else
    ScanGroup;
  end;
end; // InternalFirst


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.InternalNext;
begin
 if (FAllFields) then
   FEof := True
 else
  begin
   FLeftAO.Next;
   FEof := FLeftAO.Eof;
   if (not FEof) then
    ScanGroup;
  end;
end; // InternalNext


//------------------------------------------------------------------------------
// EOF
//------------------------------------------------------------------------------
function TACRAOGroupBy.InternalGetEof: Boolean;
begin
 Result := FEof;
end; // InternalGetEof


//------------------------------------------------------------------------------
// Record count
//------------------------------------------------------------------------------
function TACRAOGroupBy.InternalGetRecordCount: Integer;
begin
 Result := FLeftAO.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// raises an exception if field is not included in GROUP BY list 
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.CheckFieldIsNotInGroupByList(FieldName, TableName: WideString);
var i,n,l:          Integer;
    fn,tn,fa,ta:  WideString;
    ufn,utn:      WideString;
    bOK:          Boolean;
begin
  bOK := False;
  ufn := WideUpperCase(FieldName);
  utn := WideUpperCase(TableName);
  l := Length(utn);
  for i := 0 to FFields.ItemCount-1 do
   begin
    n := FFields.Items[i];
    fn := WideUpperCase(FFieldLinks[n].FieldName);
    fa := WideUpperCase(FFieldLinks[n].DisplayName);
    tn := WideUpperCase(FFieldLinks[n].TableName);
    ta := WideUpperCase(FFieldLinks[n].TableAlias);
    if ((utn = tn) or (utn = ta) or (l = 0)) then
      if ((ufn = fn) or (ufn = fa)) then
       begin
        bOK := true;
        break;
       end;
   end;
  if (not bOK) then
   raise EACRException.Create(10342,ErrorLFieldDoesNotIncludedInGroupByList,
    [TableName,FieldName]);
end; // CheckFieldIsNotInGroupByList


//------------------------------------------------------------------------------
// get field value
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.GetFieldValue(
                        Value:          TACRVariant;
                        FieldNo:        Integer;
                        bCopy:          Boolean = False;
                        AccessToHidden: Boolean = False
                        );
begin
  if (FRecordCountOnly) then
   begin
    if (FCountAllOnly) then
     Value.AsInteger := InternalGetRecordCount
    else
     begin
      Accumulate(InternalGetRecordCount);
      inherited GetFieldValue(Value,FieldNo,true,AccessToHidden);
     end;
   end
  else
   inherited GetFieldValue(Value,FieldNo,bCopy,AccessToHidden);
end; // GetFieldValue


//------------------------------------------------------------------------------
// sets projection for TACRAOTable
//------------------------------------------------------------------------------
procedure TACRAOGroupBy.SetResultFields(var FieldRefs: array of TACRSelectListItem;
          bDistinct: Boolean);
var i,j,k,x:      integer;
    fname,tname:  WideString;
    fno:          TACRIntegerArray;
begin
 j := Length(FieldRefs);
 // check for invalid fields in select list
 FRecordCountOnly := (FAllFields and (j = 1));
 FCountAllOnly := true;
 // modified in v.5.10 - SetResultFields sets nil to FieldRefs[i].ValueExpr
 // to avoid double destroy
 for i := 0 to j-1 do
   if (FieldRefs[i].IsExpression) then
    begin
     if (j = 1) then
      if (FieldRefs[i].ValueExpr <> nil) then
       if (FieldRefs[i].ValueExpr is TACRExpression) then
        begin
         FRecordCountOnly := TACRExpression(FieldRefs[i].ValueExpr).IsCountAll;
         FCountAllOnly := TACRExpression(FieldRefs[i].ValueExpr).IsCountAllOnly;
        end;
     continue;
    end;
 if (j <= 0) then
  begin
   inherited SetResultFields(FieldRefs,False);
   Exit;
  end;
 inherited SetResultFields(FieldRefs,False);
 fno := TACRIntegerArray.Create(0,1,1);
 for i := 0 to j-1 do
  begin
   if (FieldRefs[i].IsExpression) then
    continue;
   fname := FieldRefs[i].FieldName;
   tname := FieldRefs[i].TableName;
   // modified in v.5.40 to support SELECT num,num FROM Test GROUP BY num
   CheckFieldIsNotInGroupByList(fname,tname);
{
   fno.SetSize(0);
   if (FieldExists(fname,tname,False,fno) <= 0) then
    begin
     fno.Free;
     raise EACRException.Create(10341,ErrorLCannotFindFieldInTable,[fname,tname]);
    end;
   // added in 4.97 to avoid problems with SELECT field,CUMSUM(field)
   // and etc.
   if (not FAllFields) then
     for k := 0 to fno.ItemCount-1 do
      begin
       x := fno.Items[k];
       if (not FFields.IsValueExists(x)) then
        begin
         fno.Free;
         raise EACRException.Create(10342,ErrorLFieldDoesNotIncludedInGroupByList,
          [tname,fname,x,FFieldLinks[x].FieldName]);
        end;
      end;
}
  end;
 fno.Free;
 // added in v.4.60 - to unhide all fields, otherwise select count(*) from jt1,jt2
 // will not work, as there will be no result fields
 if (FRecordCountOnly) then
   FieldExists('*','',true,nil);
end; // SetResultFields


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRAOGroupBy.Create(
                     aSession:     TACRBaseSession;
                     aParams:      TACRSQLParams;
                     Child:        TACRAO;
                     FieldList:    TACRFields = nil // corresponding fields
                    );
var i,j,k: integer;
    GroupByFields: WideString;
begin
 InternalCreate(aSession,aParams,Child);
 FRecordCountOnly := False;
 FAllFields := (FieldList = nil);
 if (not FAllFields) then
  if (FieldList.ItemCount = 0) then
   FAllFields := true;
 FIsAOGroupBy := true;
 FIsMaterialized := false;
 FFields := TACRIntegerArray.Create(0,1,FLeftAO.FieldCount);
 if (not FAllFields) then
  begin
   SetLength(FValues,FieldList.ItemCount);
   for i := 0 to FieldList.ItemCount-1 do
    FValues[i] := TACRVariant.Create;
  end;
 FFieldCount := FLeftAO.FieldCount;
 SetLength(FFieldLinks,FFieldCount);
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].AO := FLeftAO;
   FFieldLinks[i].Dataset := nil;
   FFieldLinks[i].FieldNo := i;
   FFieldLinks[i].IsHidden := True;
   FFieldLinks[i].FieldName := FLeftAO.FFieldLinks[i].FieldName;
   FFieldLinks[i].FieldType := FLeftAO.FFieldLinks[i].FieldType;
   FFieldLinks[i].FieldSize := FLeftAO.FFieldLinks[i].FieldSize;
   FFieldLinks[i].TableName := FLeftAO.FFieldLinks[i].TableName;
   FFieldLinks[i].TableAlias := FLeftAO.FFieldLinks[i].TableAlias;
   FFieldLinks[i].IsExpression := FLeftAO.FFieldLinks[i].IsExpression;
   FFieldLinks[i].IsAggregate := FLeftAO.FFieldLinks[i].IsAggregate;
   FFieldLinks[i].BLOBCompressionAlgorithm := FLeftAO.FFieldLinks[i].BLOBCompressionAlgorithm;
   FFieldLinks[i].BLOBCompressionMode := FLeftAO.FFieldLinks[i].BLOBCompressionMode;
   FFieldLinks[i].BLOBBlockSize := FLeftAO.FFieldLinks[i].BLOBBlockSize;
  end;
 if (not FAllFields) then
  begin
   FLeftAO.CreateResultIndexLists(False,FieldList.ItemCount);
   for i := 0 to FieldList.ItemCount-1 do
    begin
     // unhide Group BY field in children and move it to FFields array
     j := FieldExists(
           FieldList.Items[i].FieldName,
           FieldList.Items[i].TableName,True,FFields);
//     if (j <> 1) then
//      continue;
     if (j <> 1) then
       raise EACRException.Create(10343,ErrorLInvalidJoinField,
         [FieldList.Items[i].TableName,FieldList.Items[i].FieldName,i,j]);


     k := FFields.Items[FFields.ItemCount-1];
     // modified in v.5.01
     FLeftAO.FResultIndexFieldNumbers.Items[i] := FFieldLinks[k].FieldNo;
     FLeftAO.FResultIndexFieldsList[i] := FLeftAO.GetResultFieldName(FFieldLinks[k].FieldNo);
     FLeftAO.FResultIndexAscDescFieldsList[i] := ACR_ASC;
     FLeftAO.FResultIndexCaseInsFieldsList[i] := ACR_CASE;
     FLeftAO.FActivateIndexAfterMaterialize := True;
    end;
  end; // not all fields
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRAOGroupBy.Destroy;
var i: Integer;
begin
 if (FFields <> nil) then
  FFields.Free;
 if (not FAllFields) then
  begin
   for i := Low(FValues) to High(FValues) do
    FValues[i].Free;
   FValues := nil;
  end;
 inherited Destroy;
end; // destroy


//------------------------------------------------------------------------------
// convert FieldList, AscDescList, CaseInsList
// to FieldNames, DescFields, CaseInsFields
//------------------------------------------------------------------------------
procedure ConvertListsToIndexFieldNames(
                var FieldNames:                       WideString;
                var DescNames:                        WideString;
                var CaseInsNames:                     WideString;
                FieldList, AscDescList, CaseInsList:  TACRWideStringList
                );
var i: Integer;
begin
  FieldNames := '';
  DescNames := '';
  CaseInsNames := '';
  for i := 0 to FieldList.Count - 1 do
   begin
    if (FieldNames = '') then
      FieldNames := FieldList[i]
    else
      FieldNames := FieldNames + ';' + FieldList[i];
    if (AscDescList[i] = ACR_DESC) then
     begin
       if (DescNames = '') then
        DescNames := FieldList[i]
       else
        DescNames := DescNames + ';' + FieldList[i];
     end;
    if (CaseInsList[i] = ACR_NO_CASE) then
     begin
       if (CaseInsNames = '') then
        CaseInsNames := FieldList[i]
       else
        CaseInsNames := CaseInsNames + ';' + FieldList[i];
     end;
   end;
end; // ConvertListsToIndexFieldNames


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRRelationalAlgebra> initialized');
{$ENDIF}


end.
