unit SQLMemSQLProcessor;

{$I SQLMemVer.inc}

interface

uses Classes, SysUtils, DB,

{$IFDEF DEBUG_LOG}
     SQLMemDebug,
{$ENDIF}
{$IFDEF D12H}
     SQLMem_d12h,
{$ENDIF}
     SQLMemLexer,
     SQLMemBase,
     SQLMemRelationalAlgebra,
     SQLMemTypes,
     SQLMemExpressions,
     SQLMemVariant,
     SQLMemCompression,
     SQLMemConst,
     SQLMemConverts,
     SQLMemComMain,
     SQLMemExcept;

 type

{ TODO :
create SQL cache manager - to store frequently used table components
to avoid open/close each time new command being executed }

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTableReference
//
////////////////////////////////////////////////////////////////////////////////

  // reference to the "table" in FROM clause
  TSQLMemTableReference = class (TObject)
   public
    TableType:        TSQLMemTableType;     // Table | JoinedTable | SubQuery
    SessionName:      AnsiString;             // session name
    DatabaseName:     AnsiString;             // database1
    TableName:        WideString;             // table1
    SubQuerySQL:      WideString;             // SQL text of the sub-query
    Params:           TParams;            // paramas of the query
    Pseudonym:        WideString;             // table1 as t1
    InMemory:         Boolean;            // [MEMORY]
    NaturalJoin:      Boolean;            // Natural join?
    JoinType:         TSQLMemJoinType;      // inner | left | ...
    LeftTable:        TSQLMemTableReference; // left table in join
    RightTable:       TSQLMemTableReference; // right table in join
    UsingFields:      TSQLMemWideStringList; // join column list
    SearchCondition:  TSQLMemExpression;     // ON '(t1.Field1 = t2.Field2)'
    SystemTable:      Boolean;

    // creates
    constructor Create;
    // destroys
    destructor Destroy; override;
    // makes join (left and right node-table)
    procedure MakeJoin(RightNode: TSQLMemTableReference; JType: TSQLMemJoinType;
                     IsNatural: Boolean; Fields: TSQLMemWideStringList;
                     OnCondition: TSQLMemExpression);
    // assign
    procedure Assign(Source: TSQLMemTableReference);
    // update expression params in this node and all children
    procedure UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TSQLMemBaseSession;
                  LParams:          TSQLMemSQLParams
                                    );
  end;//TSQLMemTableReference


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLCommand
// base class for TSQLMemSQLSelect, TSQLMemSQLUpdate, ...
//
////////////////////////////////////////////////////////////////////////////////

   // base class for TSQLMemSQLSelect, TSQLMemSQLUpdate, ...
  TSQLMemSQLCommand = class (TObject)
   protected
    LLex:             TSQLMemLexer; // lexer with expression to parse
    Token:            TToken;    // current token
    RowsAffected:     Integer;
    FReopen:          Boolean;   // reopen mode for ExecSQL
    LParamExprNodes:  TSQLMemList;     // list of all parameter TSQLMemExprNodeConst objects
    LStoredFunction:  TObject;   // TSQLMemStoredFunction - needs for correct parsing of expressions based on local function parameters / variables
//    LSession:         TSQLMemBaseSession; // Session that executes the command
    LParams:          TSQLMemSQLParams; // Local params of TSQLMemStoredFunction
    // table name and database name
    IntoMemory:       Boolean;   // into memory table?  (MEMORY KEYWORD)
    IntoDatabase:     AnsiString;    // select into <database>.<table>
    IntoTable:        WideString;    // select into <database>.<table>
    DatabaseName:     AnsiString;  // database1
    TableName:        WideString;  // Table Name
    TableAlias:       WideString;  // Table Alias: Table123 AS MainTable
    FDatabaseParams:  TSQLMemSQLDatabaseParams;
   private
    // parses list of columns (without table name): field1, field2, ...
    procedure ParseColumnList(var Fields: TSQLMemWideStringList);
    // parses list of fields:  table.field1, field2, ..
    procedure ParseFieldList(var Fields: TSQLMemFields);
    // parse TableName token
    procedure ParseTableNameToken;
    // set InMemory,DatabaseName,TableName to TSQLMemDataset
    procedure SetTableNameParams(t: TDataset);
    // get current token
    function GetCurrentToken: Boolean;
    // get next token
    function GetNextToken: Boolean; overload;
    // get token and lokks at next token with check for token type restrictions
    function GetNextToken(PermittedTypes: TTokenTypes;
                          NativeErrorCode: integer;
                          ErrorText: AnsiString): Boolean; overload;
    // re-open parametrized query
    procedure Reopen(
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                    ); virtual;
   public
    // update parameter values in all expressions
    procedure UpdateParams(SQLParams: TSQLMemSQLParams); virtual;
   private
    // return InMemory if was set in FDatabaseParams
    function GetInMemory: Boolean;
    // return DatabaseName if was set in FDatabaseParams
    function GetDatabaseName: AnsiString;
    // return SessionName if was set in FDatabaseParams
    function GetSessionName: AnsiString;
    // Create SQLMemTable object and fill SQLMemTable params
    function CreateInternalSQLMemTable: TDataSet; virtual;
   public
    // creates object
    constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
    // destroys object
    destructor Destroy; override;
    // parses query
    procedure Parse; virtual;
    // executes query
    procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); virtual; abstract;
    // get result cursor
    function GetResultCursor: TSQLMemCursor; virtual;
    // gets result dataset
    function GetResultDataset: TDataset; virtual;
   protected
    procedure SetDatabaseParams(Session: TSQLMemBaseSession);
    // updates all expressions - sets LSession, LParams (needed for stored functions)
   public
    procedure UpdateExpressionParams; virtual;
    // create new instance of this class
    function CreateCopy: TSQLMemSQLCommand; virtual;
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemSQLCommand); virtual;
    // make copy of TSQLMemSQLCommand object
    function MakeCopy(aSession: TSQLMemBaseSession; LocalParams: TSQLMemSQLParams): TSQLMemSQLCommand;
   public
    property DatabaseParams: TSQLMemSQLDatabaseParams read FDatabaseParams write FDatabaseParams;
    property StoredFunction: TObject read LStoredFunction;
//    property Session: TSQLMemBaseSession read LSession;
    property Params: TSQLMemSQLParams read LParams;
  end;//TSQLMemSQLCommand



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLCursorCommand
// base class for SQL command with cursor
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLCursorCommand = class (TSQLMemSQLCommand)
  private
   FLockTablesInWriteMode:			Boolean;
{$IFDEF CORRELATED_SUBQUERIES}
   FSubQuery:                   Boolean;
   FCorrelated:                 Boolean;
{$ENDIF}
  protected
   RootAO:                TSQLMemAO;   // top level AO
   FRequestLive:          Boolean;
   OrderBySpecs:          Array of TSQLMemSortSpecification;
   OrderBySpecsCount:     Integer;
   OrderByIndex:          WideString; // indexName

  protected
    // ORDER BY
   function ParseOrderByClause: Boolean;
   // <sort key> [ <collate clause> ] [ <ordering specification> ]
   function ParseSortSpecification: Boolean;
   // applies Order By clause
   procedure ApplyOrderBy(AO: TSQLMemAO);
  private
   // update parameter values in all expressions
   procedure UpdateParams(SQLParams: TSQLMemSQLParams); override;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
   procedure AssignOrderBy(Source: TSQLMemSQLCursorCommand);
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroys object
   destructor Destroy; override;
   // executes query
   //procedure ExecSQL(query: TDataset; IsRoot: Boolean = False); override;
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                    ); override;
{$IFDEF CORRELATED_SUBQUERIES}
   // return true if the sub-query is correlated
   function PrepareSubQuery(bIn: Boolean): Boolean;
   // execute sub-query
   procedure ExecuteSubQuery;
{$ENDIF}
   // build AO tree
   function BuildAOTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO; virtual; abstract;

   // get result cursor
   function GetResultCursor: TSQLMemCursor; override;
   // get result dataset
   function GetResultDataset: TDataset; override;
  public
   property LockTablesInWriteMode: Boolean read FLockTablesInWriteMode write FLockTablesInWriteMode;
{$IFDEF CORRELATED_SUBQUERIES}
   property SubQuery: Boolean read FSubQuery write FSubQuery;
   property Correlated: Boolean read FCorrelated;
{$ENDIF}
 end;//TSQLMemSQLCursorCommand



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBaseSQLProcessor
// used for parsing stored functions or SQL scripts
// created in v.5.10
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemBaseSQLProcessor = class (TSQLMemSQLProcessor)
   private
    LStoredFunction:        TObject;
    FDefaultDatabaseParams: TSQLMemSQLDatabaseParams;
   protected
    // add SELECT query object
    function AddSelectQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add INSERT query object
    function AddInsertQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add UPDATE query object
    function AddUpdateQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add DELETE query object
    function AddDeleteQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // DDL:
    // add CREATE TABLE query object
    function AddCreateTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add DROP TABLE query object
    function AddDropTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add CREATE VIEW query object
    function AddCreateViewQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add DROP VIEW query object
    function AddDropViewQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add EMPTY TABLE query object
    function AddEmptyTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add ALTER TABLE
    function AddAlterTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add RENAME TABLE
    function AddRenameTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add CREATE INDEX
    function AddCreateIndex(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add DROP INDEX
    function AddDropIndexQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add START TRANSACTION
    function AddStartTransactionQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add COMMIT
    function AddCommitQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add ROLLBACK
    function AddRollbackQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add CREATE DATABASE
    function AddCreateDatabase(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add DROP DATABASE
    function AddDropDatabaseQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add SQL Assign (operator :=)
    function AddSQLAssign(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add CREATE FUNCTION
    function AddCreateFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add DROP FUNCTION
    function AddDropFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add ALTER FUNCTION
    function AddAlterFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add EXECUTE FUNCTION
    function AddExecuteFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add If ... Then ... Else
    function AddIfThenElse(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
    // add BEGIN ... END block
    function AddBeginEndCommandsBlock(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
   public
    // used by TSQLMemStoredFunctionManager.ParseFunctionBody - parse CREATE FUNCTION script
    constructor Create(aStoredFunction: TObject; aSession: TSQLMemBaseSession); overload;
    // used by TSQLMemQuery
    constructor Create(Query: TDataSet); overload;
    destructor Destroy; override;
    function ParseSQLCommand(Lexer: TSQLMemLexer; var Token: TToken): TSQLMemSQLCommand;
   public
    property StoredFunction: TObject read LStoredFunction write LStoredFunction;
    property DefaultDatabaseParams: TSQLMemSQLDatabaseParams read FDefaultDatabaseParams write FDefaultDatabaseParams;
  end; // TSQLMemBaseSQLProcessor

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalSQLProcessor
// used in TSQLMemQuery for executing SQL scripts
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemLocalSQLProcessor = class (TSQLMemBaseSQLProcessor)
   private
    FQuery:                 TSQLMemSQLCommand;
    FQueryList:             TList;
   private
    // destroys all queries in the script
    procedure ClearQueryList;
   public
    // used by TSQLMemQuery
    constructor Create(Query: TDataSet; CaseIns: Boolean);
    destructor Destroy; override;

    function OpenQuery(TableNames: TSQLMemWideStringList = nil): TSQLMemCursor; override;
    procedure UpdateParams; override;
    // reset result cursor of Root AO dataset - added in v.6.00 for Views
    procedure ResetRootAOCursorInResultDataset;
  end; // TSQLMemLocalSQLProcessor


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLSelect
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLSelect = class (TSQLMemSQLCursorCommand)
  protected
   Distinct:              Boolean; // ALL | DISTINCT
   TopRowCount:           Integer; // TOP (-1 | n)
   FirstRowNo:            Integer; // TOP row count [, first row]
   AllFields:             Boolean; // Select *
   SelectList:            array of TSQLMemSelectListItem; // fields list
   SelectListCount:       integer; // count of array elements
   FromTables:            array of TSQLMemTableReference; // From clause
   FromTablesCount:       integer; // count of array elements
   SearchCondition:       TSQLMemExpression;  // WHERE clause
   GroupByFields:         TSQLMemFields; // GROUP BY field1, f2, ...
   HavingCondition:       TSQLMemExpression;  // HAVING clause
   FDoNotParseOrderBy:    Boolean; // set by TSQLMemSQLUnion to its children (TSQLMemSQLSelect)

   // parse GET token
   function ParseGetToken: Boolean;
   // parse SELECT token
   function ParseSelectToken: Boolean;
   // DISTINCT | ALL ?
   function ParseSetQuantifier: Boolean;
   // TOP n ?
   function ParseTopOperator: Boolean;
   // table1.* | Table1.Field1 | Fields1 AS F1
   function ParseSelectSubList: Boolean;
   // * | <select sublist>
   function ParseSelectList: Boolean;
   // INTO <target>
   function ParseInto: Boolean;
   // ON <join condition>
   function ParseJoinCondition(var SearchCondition: TSQLMemExpression): Boolean;
   // USING <join columns>
   function ParseNamedColumnsJoin(var Fields: TSQLMemWideStringList): Boolean;
   // CROSS JOIN | INNER JOIN | ...
   function ParseJoin(var tblRef: TSQLMemTableReference): Boolean;
   // <table name> [ [ AS ] <correlation name> ...
   function ParseTableReference(tblRef: TSQLMemTableReference=nil): Boolean;
   // FROM ...
   function ParseFromClause: Boolean;
   // WHERE ...
   function ParseWhereClause: Boolean;
   // GROUP BY ...
   function ParseGroupByClause: Boolean;
   // HAVING ...
   function ParseHavingClause: Boolean;

   // creates and adjusts table AO
   function CreateTableAO(var TableRef: TSQLMemTableReference; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
   // creates and adjusts joined table AO
   function CreateJoinedTableAO(var TableRef: TSQLMemTableReference; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
   // creates and adjusts AO
   function CreateAO(var TableRef: TSQLMemTableReference; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
   // builds one-table AO
   function BuildOneTableTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
   // builds multi-tables AO tree
   function BuildMultiTablesTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;

  protected
   procedure ClearSelectList;
   procedure ClearFromTables;
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
{$IFDEF CORRELATED_SUBQUERIES}
   constructor Create(
                      Lexer:              TSQLMemLexer;
                      aDatabaseParams:    TSQLMemSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False;
                      aSubQuery:          Boolean = False
                     );
{$ELSE}
   constructor Create(
                      Lexer:              TSQLMemLexer;
                      aDatabaseParams:    TSQLMemSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False
                     );
{$ENDIF}
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // builds AO tree
   function BuildAOTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO; override;
 end;//TSQLMemSQLSelect




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemQueryExprNode
//
////////////////////////////////////////////////////////////////////////////////

 // select | union | except | ...
 TSQLMemQueryExprNode = class (TObject)
  NodeType:             TSQLMemQueryExprType;  // node is: select | union | except | ...
  Left:                 TSQLMemQueryExprNode;  // left node in union, except, ...
  Right:                TSQLMemQueryExprNode;  // right table in union, except, ...
  All:                  Boolean;            // [ALL] specified?
  Corresponding:        Boolean;            // [CORRESPONDING] specified?
  CorrespondingFields:  TSQLMemWideStringList; // column list
  SelectCommand:        TSQLMemSQLSelect;      // SELECT command (if NodeType is select)

  // creates
  constructor Create; overload;
  // creates copy
  constructor Create(Src: TSQLMemQueryExprNode); overload;
  // destroys
  destructor Destroy; override;
 protected
  // adds new node to the tree
  procedure AddNode(NewType: TSQLMemQueryExprType; RightNode: TSQLMemQueryExprNode;
                    bAll, bCorresponding: Boolean; ColumnList: TSQLMemWideStringList=nil);
  // return child node with SELECT INTO - needed for UNION, EXCEPT, INTERSECT
  function FindSelectInto: TSQLMemSQLCommand;
  // assign
  procedure Assign(Source: TSQLMemQueryExprNode);
  // update expression params in this node and all children
  procedure UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TSQLMemBaseSession;
                  LParams:          TSQLMemSQLParams
                                    );
end; // TSQLMemQueryExprNode


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLUnion
// UNION SQL command
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLUnion = class (TSQLMemSQLCursorCommand)
  protected
   FRootNode: TSQLMemQueryExprNode;         // root node in unions,excepts tree
   FUnion:    Boolean;                   // set to true if UNION, EXCEPT, INTERSECT parsed

   // parses [ALL]
   function ParseAll: Boolean;

   // parses [ <corresponding spec> ]
   function ParseCorrespondingSpec(var ColumnsList: TSQLMemWideStringList): Boolean;

   // parses SELECT ...
   function ParseQuerySpecification: TSQLMemQueryExprNode;

   // parses <query specification> | <table value constructor>  | <explicit table>
   function ParseSimpleTable: TSQLMemQueryExprNode;

   // parses <simple table> |
   // <left paren> <non-join query expression> <right paren>
   function ParseNonJoinQueryPrimary: TSQLMemQueryExprNode;

   // parses <non-join query primary> |
   // <query term> INTERSECT [ ALL ] [ <corresponding spec> ] <query primary>
   function ParseNonJoinQueryTerm: TSQLMemQueryExprNode;

   // parses <non-join query term> |
   // <query expression> UNION  [ ALL ] [ <corresponding spec> ] <query term> |
   // <query expression> EXCEPT [ ALL ] [ <corresponding spec> ] <query term>
   function ParseNonJoinQueryExpression: TSQLMemQueryExprNode;

   // parses <non-join query expression>  | <joined table>
   function ParseQueryExpression: TSQLMemQueryExprNode;

   // builds AO
   function BuildAO(Node: TSQLMemQueryExprNode; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;

  protected
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
{$IFDEF CORRELATED_SUBQUERIES}
   constructor Create(
                      Lexer:            TSQLMemLexer;
                      aDatabaseParams:  TSQLMemSQLDatabaseParams;
                      aStoredFunction:  TObject;
                      aSubQuery:        Boolean = False
                     );
{$ELSE}
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
{$ENDIF}
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // builds AO tree
   function BuildAOTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO; override;

 end;//TSQLMemSQLUnion



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLInsert
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLInsert = class (TSQLMemSQLCommand)
  protected
   FieldNames:            TSQLMemWideStringList;
   FieldValues:           TSQLMemExpressions;
   InternalSelecter:      TSQLMemSQLCursorCommand;
   FTable:                TDataset;
  protected
   procedure ParseValuesList;
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
  public
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemSQLInsert



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLUpdate
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLUpdate = class (TSQLMemSQLCommand)
  protected
   FieldNames:            TSQLMemWideStringList;
   FieldValues:           TSQLMemExpressions;
   InternalSelecter:      TSQLMemSQLSelect;
  protected
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   //clear
   procedure Clear;
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemSQLUpdate



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLDelete
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLDelete = class (TSQLMemSQLCommand)
  protected
   InternalSelecter:      TSQLMemSQLSelect;
   FullDelete:            Boolean;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
  public
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemSQLDelete



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLTableManipulation
//
////////////////////////////////////////////////////////////////////////////////


 // FieldDef element
 TSQLFieldDef = class (TObject)
  public
   FieldName:                WideString;       // field name or pseudonym

   // FieldType
   newFieldType:             Boolean;
      FieldType:             TSQLMemAdvancedFieldType;

   // field length ex: AnsiString(255)
   newLength:                Boolean;
      Length:                Integer;

   // is Requared field (NOT NULL)
   newRequired:              Boolean;
      Required:              Boolean;

   // Autoinc settings
   newAutoincIncrement:      Boolean;
      AutoincIncrement:      Int64;

   newAutoincLastValue:      Boolean;
      AutoincLastValue:      Int64;

   newAutoincMinValue:       Boolean;
      AutoincMinValue:       Int64;

   newAutoincMaxValue:       Boolean;
      AutoincMaxValue:       Int64;

   newAutoincCycled:         Boolean;
      AutoincCycled:         Boolean;

   // Blob settings
   newBlobBlockSize:         Boolean;
      BlobBlockSize:         Integer; // 1..

   newBlobCompressionAlgorithm: Boolean;
      BlobCompressionAlgorithm: TSQLMemCompressionAlgorithm;// {NONE | ZLIB | BZIP | PPM}

   newBlobCompressionMode:   Boolean;
      BlobCompressionMode:   Byte; //     {0 .. 9}

   //Default Value
   newDefaultValue:          Boolean;
      DefaultValue:          TSQLMemVariant;

   newMinValue:              Boolean;
      MinValue:              TSQLMemVariant;

   newMaxValue:              Boolean;
      MaxValue:              TSQLMemVariant;

   newPrimaryKey:            Boolean;
      PrimaryKey:            Boolean;

   newUnique:                Boolean;
      Unique:                Boolean;

  public
   constructor Create;
   destructor Destroy; override;
   procedure Assign(Source: TSQLFieldDef);
 end;


 TSQLFieldDefs = class (TObject)
  protected
   List: TList;
   function GetDef(Index: Integer): TSQLFieldDef;
  public
   constructor Create;
   destructor Destroy; override;
   procedure Clear;
   function AddCreated: TSQLFieldDef;
   function GetCount: Integer;
   procedure Assign(Source: TSQLFieldDefs);
  public
   property Items[Index: Integer]: TSQLFieldDef read GetDef; default;
   property Count: Integer read GetCount;
 end;


 TSQLMemIndexField = record
   FieldName: WideString;       // field name or pseudonym
   desc:      Boolean;      // desc/asc
   nocase:    Boolean;      // ncase/case sensitive
 end;


 TSQLMemDDLTableManipulation = class (TSQLMemSQLCommand)
  protected
   FForeignKeyDefs:       TObject;
   SQLFieldDefs:          TSQLFieldDefs; // SQLFieldDefs
   PrimaryIndexName:      WideString;
   PrimaryKeyFields:      array of TSQLMemIndexField;
   UniqueFields:          TSQLMemWideStringList;
   bLeftParethesis:       Boolean;
   FComment:              WideString;

   // table element list
   procedure ParseTableElementList;
   // parse comment
   function ParseComment: Boolean;
   // Fill table column type into Structure
   procedure FillColumnType(var FieldDef:TSQLFieldDef);
   // Fill column required value into Structure
   procedure ParseColumnRequired(var FieldDef:TSQLFieldDef);
   // parse DEFAULT {const | NULL}
   function ParseDefaultValue(var FieldDef:TSQLFieldDef): Boolean;
   // parse MINVALUE value
   function ParseMinValue(var FieldDef:TSQLFieldDef): Boolean;
   // parse MAXVALUE value
   function ParseMaxValue(var FieldDef:TSQLFieldDef): Boolean;
   // parse fiald ... PRIMARY KEY
   function ParseFieldPrimaryKey(var FieldDef:TSQLFieldDef): Boolean;
   // parse fiald ... UNIQUE
   function ParseFieldUnique(var FieldDef:TSQLFieldDef): Boolean;

   // parse Primary Key
   function ParsePrimaryKey: boolean;
   // parse foreign key
   function ParseForeignKey: Boolean;
   // go to the Next token and Parse Integer (Int64)
   function ParseInteger: Int64;

   // Create SQLMemTable object and fill SQLMemTable params
   function CreateInternalSQLMemTable: TDataSet; override;
   // Fill AdvFieldDef
   procedure FillAdvFieldDef(AdvFieldDef: TFieldDef; SQLFieldDef: TSQLFieldDef);
   // Add Primary Key into SQLMemTable
   procedure AddPrimaryKey(T: TDataSet);
   // Add UNIQUE constraint and index into SQLMemTable
   procedure AddUnique(T: TDataSet);
   // Delete PrimaryKey
   procedure DeletePrimaryKey(T: TDataSet);
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroy
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
 end;//TSQLMemDDLTableManipulation




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLCreateTable
//
////////////////////////////////////////////////////////////////////////////////



 TSQLMemDDLCreateTable = class (TSQLMemDDLTableManipulation)
  private
   FIfNotExists: Boolean;
  protected
   // Create Table
   procedure CreateTable;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLCreateTable


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLDropTable
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDDLDropTable = class (TSQLMemDDLTableManipulation)
  private
   FCascade:  Boolean;
  protected
   // Drop Table
   procedure DropTable;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLDropTable



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLEmptyTable
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDDLEmptyTable = class (TSQLMemDDLTableManipulation)
  private
   FIfExists: Boolean;
  protected
   // Empty Table
   procedure EmptyTable;
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLEmptyTable



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLAlterTable
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDDLAlterTable = class (TSQLMemDDLTableManipulation)
  protected
   // AlterType token
   AlterType:                  TAlterType;
   DropColumnNamesList:        TSQLMemWideStringList;
   RenameColumnOldNamesList:   TSQLMemWideStringList;
   RenameColumnNewNamesList:   TSQLMemWideStringList;
   NewTableName:               WideString;
   NewDatabaseName:            AnsiString;
   NewInMemory:                Boolean;
   DropConstraintName:         WideString;
   DropConstraintCascade:      Boolean;
   FModifyComment:             Boolean;
   // parse AlterType token
   procedure ParseAlterTypeToken;
   // Parse RenameColumnList
   procedure ParseRenameColumnsList;
   // parse DROP CONSTRAINT
   procedure ParseDropConstraint;
   // Alter Table
   procedure DropColumn(T: TDataSet);
   procedure AddColumn(T: TDataSet);
   procedure Modify(T: TDataSet);
   procedure RenameColumn(T: TDataSet);
   procedure ModifyComment(Session: TSQLMemBaseSession);
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroy
   destructor Destroy; override;
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLAlterTable


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLRenameTable
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemDDLRenameTable = class (TSQLMemDDLAlterTable)
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
 end;
 

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLCreateIndex
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemDDLCreateIndex = class (TSQLMemSQLCommand)
  protected
   Unique:          Boolean;
   IfNotExists:     Boolean;
   IndexName:       WideString;
   SQLMemIndexFields:  array of TSQLMemIndexField; // Index Fields
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLCreateIndex



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLDropIndex
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDDLDropIndex = class (TSQLMemSQLCommand)
  protected
   IfExists:  Boolean;
   IndexName: WideString;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLDropIndex


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStartTransaction
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemStartTransaction = class (TSQLMemSQLCommand)
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemStartTransaction


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCommit
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemCommit = class (TSQLMemSQLCommand)
  private
   FFlushFileBuffers: Boolean;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemCommit




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemRollback
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemRollback = class (TSQLMemSQLCommand)
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemRollback




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseManagement
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDatabaseManagement = class (TSQLMemSQLCommand)
  protected
   FInMemory:                 Boolean;
   FDatabaseName:             AnsiString;
   FDatabaseFileName:         AnsiString;
   FDatabaseFileNameUnicode:  WideString;
   FMaxSessionsCount:         Integer;
   FPageSize:                 Integer;
   FPassword:                 AnsiString;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
  public
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   destructor Destroy; override;
 end;// TSQLMemDatabaseManagement




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCreateDatabase
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemCreateDatabase = class (TSQLMemDatabaseManagement)
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;// TSQLMemCreateDatabase




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDropDatabase
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDropDatabase = class (TSQLMemDatabaseManagement)
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;// TSQLMemDropDatabase


{$IFDEF CORRELATED_SUBQUERIES}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQuery
//
// base class for all sub-query classes
//
////////////////////////////////////////////////////////////////////////////////


  // expression node SubQuery
  TSQLMemExprNodeSubQuery = class (TSQLMemExprNode)
  protected
    FResult: Boolean;
  private
    FQuery:                     TSQLMemSQLUnion;
    FNot:                       Boolean;  // NOT option for IN or EXISTS
    FSourceNode:                TSQLMemExprNode; // source node for IN
    FDataType:                  TSQLMemAdvancedFieldType;
    FBaseType:                  TSQLMemBaseFieldType;
    FDataSize:                  Integer;
    FQueryResult:               Boolean;
    FCorrelated:                Boolean;
    LAO:                        TSQLMemAO;
    FResultFieldNo:             Integer;
    FResultDatasetFieldNo:      Integer;
    FComparisonOperator:        TSQLMemDataOperator;
  protected
    procedure DetectType;
    procedure InternalGetDataValue(BooleanResult: Boolean); virtual;
    function GetCorrelated: Boolean;
  public
    constructor Create(
                       aParentExpr:           TSQLMemExpression;
                       Operator:              TSQLMemDataOperator;
                       aQuery:                TSQLMemSQLUnion;
                       bNot:                  Boolean = False;
                       SourceNode:            TSQLMemExprNode = nil;
                       aComparisonOperator:   TSQLMemDataOperator = doEQ;
                       CaseInsensitive:       Boolean = true;
                       PartialKey:            Boolean = false
                      ); overload;
    // destroy
    destructor Destroy; override;
    // process assign AO
    procedure AssignAO(AO: TSQLMemAO); override;
    // process assign Cursor
    procedure AssignCursor(Cursor: TSQLMemCursor); override;
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TSQLMemRecordBuffer); override;
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  override;
    // return Data Type
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
    // updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
    procedure UpdateExpressionParams; override;
   public
    property Correlated: Boolean read GetCorrelated;
  end; // TSQLMemExprNodeSubQuery
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLCreateView
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDDLCreateView = class (TSQLMemDDLTableManipulation)
  private
   FIfNotExists:      Boolean;
   FWithCheckOption:  Boolean;
   FColumnNames:      TSQLMemWideStringList;
   FSelectStatement:  WideString;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   // creates object
   constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
   // destroy
   destructor Destroy; override;
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLCreateView


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLDropView
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDDLDropView = class (TSQLMemDDLTableManipulation)
  private
   FCascade:  Boolean;
  protected
   function CreateCopy: TSQLMemSQLCommand; override;
  public
   procedure Assign(Source: TSQLMemSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TSQLMemDDLDropView


// set field value from SQLMemVariant
procedure SetSQLMemVariantIntoField(Value: TSQLMemVariant; Field: TField);
// destroy commands
procedure SQLMemClearCommands(Commands: TList);


implementation


uses  Math
      ,SQLMemMain
      ,SQLMemStoredFunctions
      ;




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemBaseSQLProcessor
// used for parsing stored functions
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// adds SELECT query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddSelectQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLUnion.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;// AddSelectQuery


//------------------------------------------------------------------------------
// adds INSERT query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddInsertQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLInsert.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddInsertQuery


//------------------------------------------------------------------------------
// adds UPDATE query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddUpdateQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLUpdate.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddUpdateQuery


//------------------------------------------------------------------------------
// adds DELETE query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddDeleteQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLDelete.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddDeleteQuery


//------------------------------------------------------------------------------
// adds CREATE TABLE query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddCreateTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDDLCreateTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddCreateTableQuery


//------------------------------------------------------------------------------
// adds DROP TABLE query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddDropTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDDLDropTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddDropTableQuery


//------------------------------------------------------------------------------
// add CREATE VIEW query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddCreateViewQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDDLCreateView.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddCreateViewQuery


//------------------------------------------------------------------------------
// add DROP VIEW query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddDropViewQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDDLDropView.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddDropViewQuery


//------------------------------------------------------------------------------
// add EMPTY TABLE query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddEmptyTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDDLEmptyTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddEmptyTableQuery


//------------------------------------------------------------------------------
// add ALTER TABLE query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddAlterTableQuery;
begin
  Result := TSQLMemDDLAlterTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddAlterTableQuery


//------------------------------------------------------------------------------
// add RENAME TABLE
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddRenameTableQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDDLRenameTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddRenameTableQuery


//------------------------------------------------------------------------------
// add CREATE INDEX query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddCreateIndex;
begin
  Result := TSQLMemDDLCreateIndex.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddCreateIndex


//------------------------------------------------------------------------------
// add DROP INDEX query object
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddDropIndexQuery;
begin
  Result := TSQLMemDDLDropIndex.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddDropIndexQuery


//------------------------------------------------------------------------------
// add START TRANSACTION
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddStartTransactionQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemStartTransaction.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddStartTransactionQuery


//------------------------------------------------------------------------------
// add COMMIT
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddCommitQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemCommit.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddCommitQuery


//------------------------------------------------------------------------------
// add ROLLBACK
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddRollbackQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemRollback.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddRollbackQuery


//------------------------------------------------------------------------------
// add CREATE DATABASE
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddCreateDatabase(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemCreateDatabase.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddCreateDatabase


//------------------------------------------------------------------------------
// add DROP DATABASE
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddDropDatabaseQuery(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDropDatabase.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddDropDatabaseQuery


//------------------------------------------------------------------------------
// add SQL Assign (operator :=)
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddSQLAssign(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLAssign.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddSQLAssign


//------------------------------------------------------------------------------
// add CREATE FUNCTION
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddCreateFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemCreateStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddCreateFunction


//------------------------------------------------------------------------------
// add DROP FUNCTION
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddDropFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemDropStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddDropFunction


//------------------------------------------------------------------------------
// add ALTER FUNCTION
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddAlterFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemAlterStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddAlterFunction


//------------------------------------------------------------------------------
// add EXECUTE FUNCTION
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddExecuteFunction(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemExecuteStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddExecuteFunction


//------------------------------------------------------------------------------
// add If ... Then ... Else
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddIfThenElse(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLIfThenElse.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddIfThenElse


//------------------------------------------------------------------------------
// add BEGIN ... END block
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.AddBeginEndCommandsBlock(Lexer: TSQLMemLexer): TSQLMemSQLCommand;
begin
  Result := TSQLMemRSQLBeginEndCommandsBlock.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddBeginEndCommandsBlock


//------------------------------------------------------------------------------
// constructor Create
// used by TSQLMemStoredFunctionManager.ParseFunctionBody - parse CREATE FUNCTION script
//------------------------------------------------------------------------------
constructor TSQLMemBaseSQLProcessor.Create(aStoredFunction: TObject; aSession: TSQLMemBaseSession);
begin
  inherited Create;
  LStoredFunction := aStoredFunction;
  FDefaultDatabaseParams.Session := aSession;
  FDefaultDatabaseParams.ParamsSet := False;
  FDefaultDatabaseParams.InMemory := False;
  FDefaultDatabaseParams.DatabaseName := '';
  FDefaultDatabaseParams.SessionName := '';
  FDefaultDatabaseParams.Params := nil;
  FDefaultDatabaseParams.RequestLive := False;
end; // Create


//------------------------------------------------------------------------------
// constructor Create
// used by TSQLMemQuery
//------------------------------------------------------------------------------
constructor TSQLMemBaseSQLProcessor.Create(Query: TDataSet);
begin
  inherited Create(Query);
  LStoredFunction := nil;
  FDefaultDatabaseParams.Session := nil;
  if (Query <> nil) then
   if (Query is TSQLMemQuery) then
    FDefaultDatabaseParams.Session := TSQLMemDataset(Query).GetBaseSession;
  if (Query <> nil) then
   begin
    FDefaultDatabaseParams.ParamsSet := True;
    FDefaultDatabaseParams.InMemory := TSQLMemQuery(Query).InMemory;
    FDefaultDatabaseParams.DatabaseName := TSQLMemQuery(Query).DatabaseName;
    FDefaultDatabaseParams.SessionName := TSQLMemQuery(Query).SessionName;
    FDefaultDatabaseParams.Params := TSQLMemQuery(Query).Params;
    FDefaultDatabaseParams.RequestLive := TSQLMemQuery(Query).RequestLive;
    FDefaultDatabaseParams.CaseInsensitive := TSQLMemQuery(Query).CaseInsensitive;
   end
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemBaseSQLProcessor.Destroy;
begin
  SQLMemClearString(FDefaultDatabaseParams.DatabaseName);
  SQLMemClearString(FDefaultDatabaseParams.SessionName);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// return SQL command if it parsed successfully
// otherwise raise exception
//------------------------------------------------------------------------------
function TSQLMemBaseSQLProcessor.ParseSQLCommand(Lexer: TSQLMemLexer; var Token: TToken): TSQLMemSQLCommand;
var token1: TToken;
begin
 Result := nil;
 FDefaultDatabaseParams.CaseInsensitive := FCaseInsensitive;
 if ((Token.TokenType = tktReservedWord) and (not IsReservedWord(token,rwRESULT))) then
   case Token.ReservedWord of
   rwSELECT, rwGET:  // SELECT
              Result := AddSelectQuery(Lexer);
   rwINSERT:  // INSERT
              Result := AddInsertQuery(Lexer);
   rwUPDATE:  // UPDATE
              Result := AddUpdateQuery(Lexer);
   rwDELETE:  // DELETE
              Result := AddDeleteQuery(Lexer);
   rwCREATE:  // CREATE
              begin
                if Lexer.GetNextToken(Token) then
                  case Token.ReservedWord of
                    rwTABLE:  // CREATE TABLE
                              Result := AddCreateTableQuery(Lexer);
                    rwVIEW:   // CREATE VIEW
                              Result := AddCreateViewQuery(Lexer);
                    rwINDEX,
                    rwUNIQUE: // CREATE INDEX or UNIQUE INDEX
                              Result := AddCreateIndex(Lexer);
                    rwDATABASE: // CREATE DATABASE
                              Result := AddCreateDatabase(Lexer);
                    rwFUNCTION,rwPROCEDURE:  // CREATE FUNCTION
                              Result := AddCreateFunction(Lexer);
                    else
                      raise ESQLMemException.Create(30147, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                else raise ESQLMemException.Create(30148, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwDROP:   // DROP
              begin
                if Lexer.GetNextToken(Token) then
                  case Token.ReservedWord of
                    rwTABLE:  // DROP TABLE
                              Result := AddDropTableQuery(Lexer);
                    rwVIEW:  // DROP VIEW
                              Result := AddDropViewQuery(Lexer);
                    rwINDEX:  // DROP INDEX
                              Result := AddDropIndexQuery(Lexer);
                    rwDATABASE:  // DROP DATABASE
                              Result := AddDropDatabaseQuery(Lexer);
                    rwFUNCTION,rwPROCEDURE:  // DROP FUNCTION
                              Result := AddDropFunction(Lexer);
                    else
                     raise ESQLMemException.Create(30149, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                else raise ESQLMemException.Create(30150, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwEMPTY:   // EMPTY
              begin
                if Lexer.GetNextToken(Token) then
                begin
                 if (IsReservedWord(Token,rwTABLE)) then
                  Result := AddEmptyTableQuery(Lexer)
                 else
                   raise ESQLMemException.Create(12459, ErorrGObjectTypeKeywordExpected,
                         [Token.Text, Token.LineNum, Token.ColumnNum]);
                end
                else raise ESQLMemException.Create(12460, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwALTER:   // ALTER
              begin
                if Lexer.GetNextToken(Token) then
                  case Token.ReservedWord of
                    rwTable:  // ALTER TABLE
                              Result := AddAlterTableQuery(Lexer);
                    rwFUNCTION, rwPROCEDURE:  // ALTER TABLE
                              Result := AddAlterFunction(Lexer);
                    else
                      raise ESQLMemException.Create(30151, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);

                  end
                else
                  raise ESQLMemException.Create(30152, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwRENAME:   // RENAME
              begin
                if (not Lexer.GetNextToken(Token)) then
                  raise ESQLMemException.Create(30353, ErrorGUnexpectedEndOfCommand,
                                             [Token.LineNum, Token.ColumnNum]);
                if IsReservedWord(Token, rwTABLE) then
                  Lexer.GetNextToken(Token);
                // RENAME TABLE
                Result := AddRenameTableQuery(Lexer)
              end;
   rwSTART:   // START TRANSACTION
              Result := AddStartTransactionQuery(Lexer);
   rwCOMMIT: // COMMIT
              Result := AddCommitQuery(Lexer);
   rwROLLBACK:  // START TRANSACTION
              Result := AddRollbackQuery(Lexer);
   rwEXECUTE:   // EXECUTE FUNCTION
              begin
                if Lexer.GetNextToken(Token) then
                  case Token.ReservedWord of
                    rwFUNCTION,rwPROCEDURE:  // EXECUTE FUNCTION
                              Result := AddExecuteFunction(Lexer);
                    else
                     raise ESQLMemException.Create(12176, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                else raise ESQLMemException.Create(12177, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwIF:     // IF ... THEN  .. ELSE ...
              Result := AddIfThenElse(Lexer);
    rwBEGIN:  // BEGIN ... END;
              Result := AddBeginEndCommandsBlock(Lexer);
   else       // unsupported SQL or unexpected token
      raise ESQLMemException.Create(30153, ErrorGSQLCommandExpected,
                               [Token.Text, Token.LineNum, Token.ColumnNum]);
   end
 else
  begin
    // Assign operator
    if (Lexer.LookNextToken(token1)) then
     if (token1.TokenType = tktAssign) then
      Result := AddSQLAssign(lexer);
    // '( SELECT ...) '?
    if (Result = nil) then
     begin
      if (Token.TokenType = tktLeftParenthesis) then
       Result := AddSelectQuery(Lexer)
      else
       raise ESQLMemException.Create(30154, ErrorGSQLCommandExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
  end;
end; // ParseSQLCommand




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLocalSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// destroys all queries in the script
//------------------------------------------------------------------------------
procedure TSQLMemLocalSQLProcessor.ClearQueryList;
var i: Integer;
begin
 if (FQuery <> nil) then
  try
   FQuery.Free;
   FQuery := nil;
  except
   FQuery := nil;
  end;
 if (FQueryList <> nil) then
   begin
    // free all commands of this SQL script
    for i := 0 to FQueryList.Count-1 do
     try
      TSQLMemSQLCommand(FQueryList.Items[i]).Free;
     except
     end;
    FQueryList.Free;
    FQueryList := nil;
   end;
end; // ClearQueryList


//------------------------------------------------------------------------------
// constructor
// used by TSQLMemQuery
//------------------------------------------------------------------------------
constructor TSQLMemLocalSQLProcessor.Create(Query: TDataSet; CaseIns: Boolean);
begin
  // commented in v.6.00 - for views
//  if (Query = nil) then
//   raise ESQLMemException.Create(12098,ErrorLNilPointer);
  inherited Create(Query);
  FQuery := nil;
  FQueryList := nil;
  FCaseInsensitive := CaseIns;
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemLocalSQLProcessor.Destroy;
begin
  ClearQueryList;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// OpenQuery
//------------------------------------------------------------------------------
function TSQLMemLocalSQLProcessor.OpenQuery(TableNames: TSQLMemWideStringList): TSQLMemCursor;
var
  Token:          TToken;
  Lexer:          TSQLMemLexer;
  i:              Integer;

  function GetOpenQueryResult: TSQLMemCursor;
  begin
    FRowsAffected := RowsAffected + FQuery.RowsAffected;
    Result := FQuery.GetResultCursor;
    if (Result <> nil) then
    begin
      Result.InternalFirst;
      // added in v.6.00 for Views
      if (TableNames <> nil) then
       if (FQuery is TSQLMemSQLCursorCommand) then
        TSQLMemSQLCursorCommand(FQuery).RootAO.GetTableNames(FDefaultDatabaseParams.Session,TableNames);
    end;
  end; // GetOpenQueryResult

begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter;
aaStartTime;
try
{$ENDIF}
  // params will be updated in the following base OpenQuery call
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('> TSQLMemLocalSQLProcessor.OpenQuery'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FNeverOpened = '+BoolToStr(FNeverOpened,True)
+#13#10+'SQLParams.Count = '+IntToStr(FSQLParams.Count)
);
{$ENDIF}
  Result := inherited OpenQuery;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 1.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FNeverOpened = '+BoolToStr(FNeverOpened,True)
+#13#10+'SQLParams.Count = '+IntToStr(FSQLParams.Count)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
  if (FNeverOpened) then
   begin
    if (FSQLParams.Count > 0) then
     FQueryList := TList.Create;
    FQuery := nil;
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStartTime(time8);
{$ENDIF}
    Lexer := TSQLMemLexer.Create(SqlText, SQLParams);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time8);
{$ENDIF}
    try
     Lexer.StartSaveScript;
     try
       // Parse and Execute queries from SQL script
       while Lexer.GetNextCommand do
        begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 2.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
         if (SQLParams.Count <= 0) then
          if (FQuery <> nil) then
           begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 3.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
            FQuery.Free;
            FQuery := nil;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 4.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
           end;
         // Parse current command
         // look at first token
         if (not Lexer.GetCurrentToken(Token)) then
          raise ESQLMemException.Create(30146, ErrorGBlankSqlCommand);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter9);
aaStartTime(time9);
{$ENDIF}
         FQuery := ParseSQLCommand(Lexer,Token);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time9);
{$ENDIF}
         Lexer.StopSaveScript(False);
         Lexer.StartSaveScript;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 5.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
if (FQuery <> nil) then
 aaWriteToLog('FQuery.ClassName = '+FQuery.ClassName);
{$ENDIF}
         // Execute query
         try
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter1);
aaStartTime(time1);
{$ENDIF}
           FQuery.ExecSQL(True, FRequestLive, FReadonly);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time1);
{$ENDIF}
         except
           try
             FQuery.Free;
             FQuery := nil;
           except
             FQuery := nil;
           end;
           raise;
         end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 6.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
         if (SQLParams.Count > 0) then
          FQueryList.Add(FQuery);
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 7.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
         Result := GetOpenQueryResult;
         // FQuery added to list - will be destroyed from list
         if (SQLParams.Count > 0) then
          FQuery := nil;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 8.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
        end; // Parse and Execute queries
      FNeverOpened := False;
      // stored in FQuery
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 9.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
      if (SQLParams.Count > 0) then
       FQuery := nil;
     except
       on e: Exception do
        begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('3 TSQLMemLocalSQLProcessor.OpenQuery Error:'
+#13#10+e.Message
+#13#10+'Self = '+IntToHex(Integer(Self),8)
);
{$ENDIF}
         ClearQueryList;
         FNeverOpened := True;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('4 TSQLMemLocalSQLProcessor.OpenQuery Error:'
+#13#10+e.Message
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FNeverOpened = '+BoolToStr(FNeverOpened,True)
+#13#10+'SQLParams.Count = '+IntToStr(FSQLParams.Count)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
         raise;
        end;
     end;
    finally
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 10.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
+#13#10+'Lexer = '+IntToHex(Integer(Lexer),8)
);
{$ENDIF}
      Lexer.Free;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 11.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
    end;
   end // query was not opened / executed
  else
   begin
    // reopen all commands of this SQL script with new parameters
    try
     FRowsAffected := 0;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 12.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
);
{$ENDIF}
     for i := 0 to FQueryList.Count-1 do
      begin
        FQuery := TSQLMemSQLCommand(FQueryList.Items[i]);
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 13.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
        FQuery.Reopen(FRequestLive,FReadonly);
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 14.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
        Result := GetOpenQueryResult;
        FQuery := nil;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('TSQLMemLocalSQLProcessor.OpenQuery 15.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
      end;
    except
       on e: Exception do
        begin
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('1 TSQLMemLocalSQLProcessor.OpenQuery Error:'
+#13#10+e.Message
+#13#10+'Self = '+IntToHex(Integer(Self),8)
);
{$ENDIF}
         FQuery := nil;
         ClearQueryList;
         FNeverOpened := True;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('2 TSQLMemLocalSQLProcessor.OpenQuery Error:'
+#13#10+e.Message
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FNeverOpened = '+BoolToStr(FNeverOpened,True)
+#13#10+'SQLParams.Count = '+IntToStr(FSQLParams.Count)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
         raise;
        end;
    end;
   end;
{$IFDEF DEBUG_TRACE_TSQLMemLocalSQLProcessor_OpenQuery}
aaWriteToLog('< TSQLMemLocalSQLProcessor.OpenQuery.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FNeverOpened = '+BoolToStr(FNeverOpened,True)
+#13#10+'SQLParams.Count = '+IntToStr(FSQLParams.Count)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime;
end;
{$ENDIF}
end;//OpenQuery


//------------------------------------------------------------------------------
// update params
//------------------------------------------------------------------------------
procedure TSQLMemLocalSQLProcessor.UpdateParams;
var
  i:      Integer;
begin
  for i := 0 to FQueryList.Count-1 do
   TSQLMemSQLCommand(FQueryList.Items[i]).UpdateParams(SQLParams);
  inherited;
end; // UpdateParams


//------------------------------------------------------------------------------
// reset result cursor of Root AO dataset - added in v.6.00 for Views
//------------------------------------------------------------------------------
procedure TSQLMemLocalSQLProcessor.ResetRootAOCursorInResultDataset;
begin
  if (FQuery = nil) then
   if (FQueryList.Count > 0) then
     FQuery := TSQLMemSQLCommand(FQueryList.Items[FQueryList.Count-1]);
  if (FQuery <> nil) then
   if (FQuery is TSQLMemSQLCursorCommand) then
    TSQLMemSQLCursorCommand(FQuery).RootAO.ResetRootAOCursorInResultDataset;
end; // ResetRootAOCursorInResultDataset




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLSelect
//
////////////////////////////////////////////////////////////////////////////////




//------------------------------------------------------------------------------
// parse GET token
// GET TABLES
// same as
// SELECT * FROM TABLES
// GET TABLES 2 DESC
// same as
// SELECT * FROM TABLES ORDER BY 2 DESC
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseGetToken: Boolean;
begin
  Result := IsReservedWord(Token, rwGET);
  if (not Result) then
   // unsupported SQL or unexpected token
   raise ESQLMemException.Create(11979, ErrorGSQLCommandExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;
  if (not IsReservedWord(Token,rwTABLES)) then
   raise ESQLMemException.Create(11978, ErrorGOtherTokenExpected,
         ['TABLES', Token.Text, Token.LineNum, Token.ColumnNum]);
  AllFields := True;
  FromTablesCount := 1;
  SetLength(FromTables,FromTablesCount);
  FromTables[0] := TSQLMemTableReference.Create;
  FromTables[0].TableName := 'TABLES';
  FromTables[0].TableType := attTable;
  FromTables[0].SystemTable := True;
  FromTables[0].InMemory := GetInMemory;
  FromTables[0].DatabaseName := GetDatabaseName;
  Inc(OrderBySpecsCount);
  SetLength(OrderBySpecs, OrderBySpecsCount);
  if (GetNextToken) then
   begin
    if (Token.TokenType = tktInt) then
     OrderBySpecs[OrderBySpecsCount-1].ColumnNumber := StrToInt(Token.Text)
    else
     OrderBySpecs[OrderBySpecsCount-1].ColumnNumber := 1;
    GetNextToken;
   end
  else
   begin
    OrderBySpecs[OrderBySpecsCount-1].ColumnNumber := 1;
   end;
end; // ParseGetToken


//------------------------------------------------------------------------------
// SELECT
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseSelectToken: Boolean;
begin
  Result := IsReservedWord(Token, rwSELECT);
  if (not Result) then
   // unsupported SQL or unexpected token
   raise ESQLMemException.Create(30156, ErrorGSQLCommandExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;
end;//ParseSelectToken


//------------------------------------------------------------------------------
// DISTINCT | ALL ?
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseSetQuantifier: Boolean;
begin
 if (IsReservedWord(Token)) then
  begin
    if (IsReservedWord(Token, rwALL)) then
     begin
      Distinct := False;
      Result := True;
     end
    else
    if (IsReservedWord(Token, rwDISTINCT)) then
     begin
      Distinct := True;
      Result := True;
     end
    else // unrecognized reserved word - give up to handle
     begin
      Distinct := False; // default value
      Result := False; // handle this token by another handler
     end;
  end
 else // not reserved-word token give up handling
  begin
    Distinct := False; // default value
    Result := False; // handle this word by another handler
  end;

 // get next token
 if (Result) then
  GetNextToken;
end;// ParseSetQuantifier


//------------------------------------------------------------------------------
// TOP n ?
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseTopOperator: Boolean;
begin
  if (IsReservedWord(Token, rwTOP)) then
   begin
    // suppose 'TOP n'
    GetNextToken;
    // integer?
    if (Token.TokenType <> tktInt) then
     raise ESQLMemException.Create(30158, ErrorGIntegerExpected,
                             [Token.Text, Token.LineNum, Token.ColumnNum]);
    TopRowCount := StrToInt(Token.Text);
    // get next token
    GetNextToken;
    // default value
    FirstRowNo := -1;
    // ','? => TOP n, first_row
    if (Token.Text = ',') then
     begin
       // get next token
       GetNextToken;
       // integer?
       if (Token.TokenType <> tktInt) then
         raise ESQLMemException.Create(30159, ErrorGIntegerExpected,
                             [Token.Text, Token.LineNum, Token.ColumnNum]);
       FirstRowNo := StrToInt(Token.Text);
       // get next token
       GetNextToken;
     end;
    Result := True;
   end
  else // unrecognized reserved word - give up to handle
   begin
    TopRowCount := -1; // default value
    FirstRowNo := -1;
    Result := False; // handle this token by another handler
   end;
end;// ParseTopOperator


//------------------------------------------------------------------------------
// <derived column>  | <qualifier> <period> <asterisk>
// table1.* | Table1.Field1 | Fields1 AS F1
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseSelectSubList: Boolean;
var
  FieldName, TableName, Pseudonym: WideString;
  AllFields: Boolean;
begin
 // handle field1 | table1.field1 | expr
  begin
   Result := True;

   // add new select list item
   inc(SelectListCount);
   SetLength(SelectList, SelectListCount);

   // parse field name | expr
   SelectList[SelectListCount-1].ValueExpr := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
   TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).Params :=
      FDatabaseParams.Params;
   TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).InMemory :=
      GetInMemory;
   TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).SessionName :=
      GetSessionName;
   TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).DatabaseName :=
      GetDatabaseName;
   TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).CaseInsensitive :=
      FDatabaseParams.CaseInsensitive;
   TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).ParseForValueExpression(LLex);

   if (TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).IsEmpty) then
    begin
     SelectList[SelectListCount-1].ValueExpr.Free;
     raise ESQLMemException.Create(30160, ErrorGExpressionExpected,
                             [Token.Text, Token.LineNum, Token.ColumnNum]);
    end;
   GetCurrentToken;

   // pseudonym is not specified yet
   Pseudonym := '';
   AllFields := False;
   // check pseudonym
   if (not AllFields) then
    // (Field1 AS F1) ?
          if (IsReservedWord(Token, rwAS)) then
           begin
             // get next token (F1?)
             GetNextToken([tktString, tktQuotedString, tktBackQuotedString,
                           tktBracketedString, tktReservedWord { added in v.5.60}],
                          30162, ErrorGFieldPseudonymExpected);
             // got pseudonym
             Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end
          else
          // (Field1 F1) ?
          if (Token.TokenType in
               [tktString, tktQuotedString, tktBackQuotedString, tktBracketedString, tktReservedWord { added in v.5.60}]) then
           if (not IsReservedWord(token,rwFROM)) and (not IsReservedWord(token,rwINTO)) then    
            begin
             // got pseudonym
             Pseudonym := Token.Text;
             // look at next token
             GetNextToken;
            end;

   // expr or field?
   SelectList[SelectListCount-1].IsExpression := not TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).IsField;

   // field?
   if (not SelectList[SelectListCount-1].IsExpression) then
    begin
     // get field name, table name
     TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).GetFieldInfo(TableName, FieldName);
     // store TableName
     SelectList[SelectListCount-1].TableName := TableName;
     // store ValueExpr (FieldName)
     SelectList[SelectListCount-1].FieldName := FieldName;
     if (FieldName = '*') then
      AllFields := True;
    end;

   // free non-expr objects (expr objects are freed by AO)
   if (not SelectList[SelectListCount-1].IsExpression) then
    begin
     TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr).Free;
     TSQLMemExpression(SelectList[SelectListCount-1].ValueExpr) := nil;
    end;

   // store AllFields ('table1.*'?)
   SelectList[SelectListCount-1].AllFields := AllFields;
   // pseudonym
   SelectList[SelectListCount-1].Pseudonym := Pseudonym;
  end;
end;// ParseSelectSubList


//------------------------------------------------------------------------------
// * | <select sublist>
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseSelectList: Boolean;
begin
  if (Token.Text = Asterisk) then
   begin
    Result := True;
    GetNextToken;
    AllFields := True; // select all fields
   end
  else
   begin
    AllFields := False;
    Result := True;
     // get FieldName
    if (ParseSelectSubList) then
     // all field expressions
     repeat
        if (Token.TokenType <> tktComma) then
           break
        else
          // skip ','token
          GetNextToken;
        // get next field expr
        if (not ParseSelectSubList) then
         raise ESQLMemException.Create(30163, ErrorGFieldNameExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
     until False
    else
     raise ESQLMemException.Create(30164, ErrorGFieldListExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
end;//ParseSelectList


//------------------------------------------------------------------------------
// INTO <target>
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseInto: Boolean;
begin
 Result := False;
 TableName := '';
 DatabaseName := '';
 IntoMemory := False;

 if (IsReservedWord(Token, rwINTO)) then
  begin
    // get table | database name
    GetNextToken([tktString, tktReservedWord, tktBackQuotedString, tktBracketedString, tktQuotedString],
                 30165, ErrorGTableNameExpected);

    ParseTableNameToken;
    IntoTable := TableName;
    IntoDatabase := DatabaseName;
{
    if (IsReservedWord(Token, rwMEMORY)) then
     begin
      IntoMemory := True;
      // next token
      GetNextToken;
     end;

    IntoTable := Token.Text;
    // next token
    GetNextToken;
    // db.table?
    if (Token.TokenType = tktDot) then
     begin
      IntoDatabase := IntoTable;
      // get table name
      GetNextToken([tktString, tktBackQuotedString, tktBracketedString, tktQuotedString],
                   30166, ErrorGTableNameExpected);
      IntoTable := Token.Text;
      // next token
      GetNextToken;
     end;
}
    Result := True;
  end;
end;// ParseInto


//------------------------------------------------------------------------------
// ON <join condition>
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseJoinCondition(var SearchCondition: TSQLMemExpression): Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwON)) then
   begin
    Result := True;
    GetNextToken; // skip ON token
    SearchCondition := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
    SearchCondition.Params := FDatabaseParams.Params;
    SearchCondition.InMemory := GetInMemory;
    SearchCondition.DatabaseName := GetDatabaseName;
    SearchCondition.SessionName := GetSessionName;
    SearchCondition.CaseInsensitive := FDatabaseParams.CaseInsensitive;
    SearchCondition.ParseForBooleanExpression(LLex);
    if (not AllFields) then
     SearchCondition.ReplacePseudonyms(SelectList);
    // get current unhandled token
    GetCurrentToken;
   end;
end;// ParseJoinCondition


//------------------------------------------------------------------------------
// USING <join columns>
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseNamedColumnsJoin(var Fields: TSQLMemWideStringList): Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwUSING)) then
   begin
    Result := True;
    GetNextToken; // skip USING token

    // '('?
    if (Token.TokenType = tktLeftParenthesis) then
     begin
      // skip '('
      GetNextToken;

      // parse fields list
      ParseColumnList(Fields);

      // skip ')'
      if (Token.TokenType = tktRightParenthesis) then
         GetNextToken; // end of query is possible here
     end
    else
     raise ESQLMemException.Create(30167, ErrorGOtherTokenExpected,
                   ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
end;// ParseNamedColumnsJoin


//------------------------------------------------------------------------------
// CROSS JOIN | INNER JOIN | ...
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseJoin(var tblRef: TSQLMemTableReference): Boolean;
var
 RightTblRef:     TSQLMemTableReference;
 JoinType:        TSQLMemJoinType;
 IsNatural:       Boolean;
 Fields:          TSQLMemWideStringList;
 SearchCondition: TSQLMemExpression;
 JoinCondition:   TSQLMemExpression;
begin
 Result := False;

 if (IsReservedWord(Token)) then
  repeat
     IsNatural := False; // default value
     JoinType := ajtInner; // default value
     // parse CROSS JOIN | [ NATURAL ] [ <join type> ] JOIN
     if (IsReservedWord(Token, rwCROSS)) then
      begin
          GetNextToken([tktReservedWord], 30168, ErrorGUnexpectedToken); // skip CROSS
          JoinType := ajtCross;
          Result := True;
      end
     else
      begin
       // [NATURAL]
       if (IsReservedWord(Token, rwNATURAL)) then
         begin
          IsNatural := True;
          GetNextToken([tktReservedWord], 30169, ErrorGUnexpectedToken);
          Result := True;
         end;
       // INNER?
       if (IsReservedWord(Token, rwINNER)) then
         begin
          JoinType := ajtInner;
          GetNextToken([tktReservedWord], 30170, ErrorGUnexpectedToken);
          Result := True;
         end
       else
        // OUTER join
        begin
         // LEFT
         if (IsReservedWord(Token, rwLEFT)) then
          begin
           JoinType := ajtLeftOuter;
           GetNextToken([tktReservedWord], 30171, ErrorGUnexpectedToken);
           Result := True;
          end
         else
         // RIGHT
         if (IsReservedWord(Token, rwRIGHT)) then
          begin
           JoinType := ajtRightOuter;
           GetNextToken([tktReservedWord], 30172, ErrorGUnexpectedToken);
           Result := True;
          end
         else
         // FULL
         if (IsReservedWord(Token, rwFULL)) then
          begin
           JoinType := ajtFullOuter;
           GetNextToken([tktReservedWord], 30173, ErrorGUnexpectedToken);
           Result := True;
          end;
         // [OUTER]
         if ((Result) and (IsReservedWord(Token, rwOUTER))) then
          begin
           GetNextToken([tktReservedWord], 30174, ErrorGUnexpectedToken);
          end;
        end;// outer join
      end; // non-cross join

     // next token - JOIN?
     if (not IsReservedWord(Token, rwJOIN)) then
      if (Result) then
       raise ESQLMemException.Create(30175, ErrorGOtherTokenExpected,
                 ['JOIN', Token.Text, Token.LineNum, Token.ColumnNum])
      else
       exit; // no joins
     GetNextToken;

     // get right table ref
     RightTblRef := TSQLMemTableReference.Create;
     if not ParseTableReference(RightTblRef) then
      raise ESQLMemException.Create(30176, ErrorGTableNameExpected,
                       [Token.Text, Token.LineNum, Token.ColumnNum]);

     // <join condition> | <named columns join>
     Fields := nil;
     if not ParseJoinCondition(JoinCondition) then
       ParseNamedColumnsJoin(Fields);

     // update tree to make join
     tblRef.MakeJoin(RightTblRef, JoinType, IsNatural, Fields, JoinCondition)
  until (not(IsReservedWord(Token, rwCROSS) or
             IsReservedWord(Token, rwNATURAL) or
             IsReservedWord(Token, rwINNER) or
             IsReservedWord(Token, rwLEFT) or
             IsReservedWord(Token, rwRIGHT) or
             IsReservedWord(Token, rwFULL) or
             IsReservedWord(Token, rwOUTER) or
             IsReservedWord(Token, rwJOIN)));
end;// ParseJoin


//------------------------------------------------------------------------------
// <table name> [ [ AS ] <correlation name> ...
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseTableReference(tblRef: TSQLMemTableReference): Boolean;
var
  DatabaseName:         AnsiString;
  TableName, Pseudonym: WideString;
  TableType:            TSQLMemTableType;
  InMemory:             Boolean;
  tRef:                 TSQLMemTableReference;
  n:                    Integer;
  s:                    WideString;
begin
 Result := False;
 // handle table1 | "database 1".table1
 if (Token.TokenType in
      [tktString, tktReservedWord, tktQuotedString,
       tktBackQuotedString, tktBracketedString]) then
  begin
   Result := True;
   if (IsReservedWord(Token, rwMEMORY)) then
    begin
      InMemory := True;
      DatabaseName := SQLMemMemoryDatabaseName;
      GetNextToken;
    end
   else
    begin
      InMemory := GetInMemory;
      DatabaseName := GetDatabaseName;
    end;
   // get table name
   TableName := Token.Text;
   // pseudonym is not specified yet
   Pseudonym := '';
   // tabletype is attTable by default
   TableType := attTable;
   // look at next token
   if (GetNextToken) then
    begin
     // db.table?
     if (Token.TokenType = tktDot) then
      begin
       DatabaseName := TableName;
       // get table name
       GetNextToken;
       TableName := Token.Text;
       // next token
       GetNextToken;
      end;
      // check pseudonym - correlation name (Table1 AS t1)
      if (IsReservedWord(Token, rwAS)) then
            begin
             // get next token (t1?)
             GetNextToken([tktString, tktQuotedString,
                           tktBackQuotedString, tktBracketedString],
                           30177, ErrorGFieldPseudonymExpected);
             // got pseudonym
             Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end
      else
        if (Token.TokenType in [tktString, tktQuotedString,
                        tktBackQuotedString, tktBracketedString]) then
            begin
             // got pseudonym
             Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end;
{
      // check password
      if (IsReservedWord(Token, rwPASSWORD)) then
       begin
        // get next token 'password'
        GetNextToken([tktQuotedString], 30178, ErrorGQuotedPasswordDataExpected);
        Password := Token.Text;
        // get next token
        GetNextToken;
       end;
}
    end;
   // first table in joins chain?
   if (tblRef = nil) then
    begin
     // add new tables list item
     Inc(FromTablesCount);
     SetLength(FromTables, FromTablesCount);
     FromTables[FromTablesCount-1] := TSQLMemTableReference.Create;
     tRef := FromTables[FromTablesCount-1];
    end
   else
    tRef := tblRef;

   // store TableType
   tRef.TableType := TableType;
   // store DatabaseName
   tRef.DatabaseName := DatabaseName;
   // store SessionName
   tRef.SessionName := GetSessionName;
   // store TableName
   tRef.TableName := TableName;
   // store Pseudonym
   tRef.Pseudonym := Pseudonym;
   // store Password
//   tRef.Password := Password;
   // store [MEMORY]
   tRef.InMemory := InMemory;
  end
 else
  // (<table reference>)
  if (Token.TokenType = tktLeftParenthesis) then
   begin
    // skip '('
    GetNextToken;
    if (IsReservedWord(Token,rwSELECT)) then
     begin
      // skip SELECT
      s := Token.Text;
      if (not GetNextToken) then
       raise ESQLMemException.Create(11656,ErrorLSubQueryInvalidStatement,[Token.Text]);
      // sub-query
      n := 1;
      if (tblRef = nil) then
       begin
         Inc(FromTablesCount);
         SetLength(FromTables, FromTablesCount);
         FromTables[FromTablesCount-1] := TSQLMemTableReference.Create;
         tRef := FromTables[FromTablesCount-1];
       end
      else
       tRef := tblRef;
      tRef.TableType := attSubQuery;
      tRef.DatabaseName := GetDatabaseName;
      tRef.SessionName := GetSessionName;
      tRef.Params := TParams.Create;
      if (FDatabaseParams.Params <> nil) then
       if (FDatabaseParams.Params.Count > 0) then
        tRef.Params.Assign(FDatabaseParams.Params);

      while (TRUE) do
       begin
        if (Token.TokenType = tktRightParenthesis) then
         Dec(n)
        else
        if (Token.TokenType = tktLeftParenthesis) then
         Inc(n);
        if (n > 0) then
         begin
          if (Token.TokenType = tktQuotedString) then
           s := s + Space + AnsiQuotedStr(Token.Text,SingleQuote)
          else
          if (Token.TokenType = tktBracketedString) then
           s := s + Space + LeftBracket + Token.Text + RightBracket
          else
          if (Token.TokenType = tktBackQuotedString) then
           s := s + Space + AnsiQuotedStr(Token.Text,BackQuote)
          else
          if (Token.TokenType = tktParameter) then
           s := s + Space + Colon + AnsiQuotedStr(Token.Text,'''')
          else
           s := s + Space + Token.Text
         end
        else
         break;
        if (not GetNextToken) then
         break;
       end;
      if (n > 0) then
       raise ESQLMemException.Create(11657,ErrorGMissingRightParenthesis,[Token.LineNum,Token.ColumnNum]);
      tRef.SubQuerySQL := s;
      // skip ')'
      // fixed in v.5.80
      GetNextToken;
//      if (not GetNextToken) then
//       raise ESQLMemException.Create(11658,ErrorGMissingRightParenthesis,[Token.LineNum,Token.ColumnNum]);
      // check pseudonym - correlation name (Table1 AS t1)
      if (IsReservedWord(Token, rwAS)) then
            begin
             // get next token (t1?)
             GetNextToken([tktString, tktQuotedString,
                           tktBackQuotedString, tktBracketedString],
                           11659, ErrorGFieldPseudonymExpected);
             // got pseudonym
             tRef.Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end
      else
        if (Token.TokenType in [tktString, tktQuotedString,
                        tktBackQuotedString, tktBracketedString]) then
            begin
             // got pseudonym
             tRef.Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end;
      Result := True;      
     end // sub-query
    else
     begin
      // joined table
      // get table reference
      Result := ParseTableReference(tblRef);
      // get its pointer
      if (tblRef = nil) then
       tRef := FromTables[FromTablesCount-1]
      else
       tRef := tblRef;

      if not Result then
       raise ESQLMemException.Create(30179, ErrorGFieldNameExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);
      // skip ')'
      if (Token.TokenType = tktRightParenthesis) then
         GetNextToken;
     end; // joined table
   end;

 // join?
 if (Result) then
   ParseJoin(tRef);
end;// ParseTableReference


//------------------------------------------------------------------------------
// FROM ...
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseFromClause: Boolean;
begin
 if (IsReservedWord(Token, rwFROM)) then
  begin
    // skip FROM token
    GetNextToken([tktString, tktReservedWord,
          tktQuotedString, tktBackQuotedString,
          tktBracketedString, tktLeftParenthesis],
                 30180, ErrorGTableNameExpected);
    Result := True;
    // get TableName
    if (ParseTableReference) then
     // get all tables
     repeat
        // end of sql command?
        if (Token.TokenType <> tktComma) then
          break
        else
          // skip ','token
          GetNextToken([tktString, tktReservedWord, tktQuotedString, tktBackQuotedString, tktBracketedString, tktLeftParenthesis],
                       30181, ErrorGTableNameExpected);
       // get next table reference
       if (not ParseTableReference) then
        raise ESQLMemException.Create(30182, ErrorGTableNameExpected,
                  [Token.Text, Token.LineNum, Token.ColumnNum]);
     until False
    else
      raise ESQLMemException.Create(30183, ErrorGTableNameExpected,
                  [Token.Text, Token.LineNum, Token.ColumnNum]);
  end
 else
   raise ESQLMemException.Create(30184, ErrorGOtherTokenExpected,
                ['FROM', Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseFromClause


//------------------------------------------------------------------------------
// WHERE ...
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseWhereClause: Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwINTO)) then
   raise ESQLMemException.Create(11337, ErrorLTokenINTOShouldBeBeforeFROM,
                [Token.LineNum, Token.ColumnNum]);
 if (IsReservedWord(Token, rwWHERE)) then
  begin
    Result := True;
    // skip WHERE token
    GetNextToken;
    SearchCondition := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
    SearchCondition.Params := FDatabaseParams.Params;
    SearchCondition.InMemory := GetInMemory;
    SearchCondition.DatabaseName := GetDatabaseName;
    SearchCondition.SessionName := GetSessionName;
    SearchCondition.CaseInsensitive := FDatabaseParams.CaseInsensitive;
    SearchCondition.ParseForBooleanExpression(LLex);

    if (not AllFields) then
     SearchCondition.ReplacePseudonyms(SelectList);
    // get current (not handled) token
    GetCurrentToken;
  end;
end;// ParseWhereClause


//------------------------------------------------------------------------------
// GROUP BY ...
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseGroupByClause: Boolean;
begin
 if (IsReservedWord(Token, rwGROUP)) then
  begin
    Result := True;
    // skip GROUP token
    GetNextToken;
    // 'BY'?
    if (not IsReservedWord(Token, rwBY)) then
     raise ESQLMemException.Create(30185, ErrorGOtherTokenExpected,
                   ['BY', Token.Text, Token.LineNum, Token.ColumnNum]);
    // skip BY token
    GetNextToken;

    // parse fields list
    ParseFieldList(GroupByFields);
  end
 else
  Result := False;
end;// ParseGroupByClause


//------------------------------------------------------------------------------
// HAVING ...
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.ParseHavingClause: Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwHAVING)) then
  begin
    Result := True;
    // skip HAVING token
    GetNextToken;
    HavingCondition := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
    HavingCondition.Params := FDatabaseParams.Params;
    HavingCondition.InMemory := GetInMemory;
    HavingCondition.DatabaseName := GetDatabaseName;
    HavingCondition.SessionName := GetSessionName;
    HavingCondition.CaseInsensitive := FDatabaseParams.CaseInsensitive;
    HavingCondition.ParseForBooleanExpression(LLex);
    if (not AllFields) then
     HavingCondition.ReplacePseudonyms(SelectList);
    // get current (not handled) token
    GetCurrentToken;
  end;
end;// ParseHavingClause


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemSQLSelect.Parse;
var
  State: integer;
  bOk: Boolean;
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter10);
aaStartTime(time10);
try
{$ENDIF}

   // get first token (for new query) or current token (for subquery)
   //bOk := LLex.GetCurrentToken(Token);

   bOk := GetCurrentToken;

   if (not bOk) then
      raise ESQLMemException.Create(30155, ErrorGBlankSqlCommand);

   state := 0;
   repeat
      // states switch (depends on a current part of query)
      case state of
       0: // SELECT
        if (IsReservedWord(Token, rwGET)) then
         begin
          ParseGetToken;
          break;
         end
        else
          ParseSelectToken;
       1: // DISTINCT | ALL ?
          ParseSetQuantifier;
       2: // TOP n ?
          ParseTopOperator;
       3: // * | <select sublist>
          ParseSelectList;
       4: // <into ...>
          ParseInto;
       5: // <from clause>
          ParseFromClause;
       6: // <where clause>
          ParseWhereClause;
       7: // <group by clause>
          ParseGroupByClause;
       8: // <where clause>
          ParseHavingClause;
       9: // <order by clause>
          if (not FDoNotParseOrderBy) then
           ParseOrderByClause;
       else
        break;
      end;// case
      inc(state);
   until (false);
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time10);
end;
{$ENDIF}
end;// Parse


//------------------------------------------------------------------------------
// creates and adjusts table AO
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.CreateTableAO(var TableRef: TSQLMemTableReference; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
var
  DatabaseName: AnsiString;
begin
  DatabaseName := TableRef.DatabaseName;
  if (DatabaseName = '') then
    DatabaseName := GetDatabaseName;

  try
    Result := TSQLMemAOTable.Create(
                                 Session,
                                 Params,
                                 DatabaseName,
                                 TableRef.SessionName,
                                 TableRef.TableName,
                                 TableRef.Pseudonym,
                                 TableRef.SubQuerySQL,
                                 TableRef.Params,
                                 TableRef.InMemory,
                                 FRequestLive,
                                 TableRef.SystemTable
                                 );
    Result.CaseInsensitive := FDatabaseParams.CaseInsensitive;
  finally
    if (TableRef.Params <> nil) then
     begin
      TableRef.Params.Free;
      TableRef.Params := nil;
     end;
  end;
end;// CreateTableAO


//------------------------------------------------------------------------------
// creates and adjusts joined table AO
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.CreateJoinedTableAO(var TableRef: TSQLMemTableReference; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
var
 LeftAO, RightAO: TSQLMemAO;
 FieldList1, FieldList2: TSQLMemFields;
 i: integer;
 Item1, Item2: TSQLMemSelectListItem;

function RecursiveExtractJoinConditions(TableRef: TSQLMemTableReference): integer;
begin
  if (TableRef.SearchCondition <> nil) then
     Result := TableRef.SearchCondition.ExtractJoinConditions(LeftAO, RightAO,
                                      FieldList1, FieldList2)
  else
   begin
     Result := 0;
     if (TableRef.TableType = attJoinedTable) then
      begin
       if (TableRef.LeftTable.SearchCondition <> nil) then
        Result := Result + TableRef.LeftTable.SearchCondition.ExtractJoinConditions(
                         LeftAO, RightAO, FieldList1, FieldList2);

       if (TableRef.RightTable.SearchCondition <> nil) then
        Result := Result + TableRef.RightTable.SearchCondition.ExtractJoinConditions(
                         LeftAO, RightAO, FieldList1, FieldList2);

      end;
   end;
end; // RecursiveExtractJoinConditions

begin
 // create joined tables
 LeftAO := CreateAO(TableRef.LeftTable,Session,Params);
 RightAO := CreateAO(TableRef.RightTable,Session,Params);

 // prepare column lists
 FieldList1 := nil;
 FieldList2 := nil;
 try
 // column lists required?
 if ((not TableRef.NaturalJoin) and
     (
      (TableRef.JoinType = ajtInner) or
      (TableRef.JoinType = ajtLeftOuter) or
      (TableRef.JoinType = ajtRightOuter) or
      (TableRef.JoinType = ajtFullOuter)
     )) then
  begin // build column lists
   // USING ?
   if (TableRef.UsingFields <> nil) then
    begin
      FieldList1 := TSQLMemFields.Create;
      FieldList2 := TSQLMemFields.Create;
      for i := 0 to TableRef.UsingFields.Count-1 do
       begin
        Item1.FieldName := TableRef.UsingFields.Strings[i];
        Item1.TableName := TableRef.LeftTable.TableName;
        Item1.ValueExpr := nil;
        Item2.FieldName := TableRef.UsingFields.Strings[i];
        Item2.TableName := TableRef.RightTable.TableName;
        Item2.ValueExpr := nil;
        FieldList1.Append(Item1);
        FieldList2.Append(Item2);
       end;
    end
   else
    begin
      FieldList1 := TSQLMemFields.Create;
      FieldList2 := TSQLMemFields.Create;
      // extract from ON clause
      RecursiveExtractJoinConditions(TableRef);
      // extract from WHERE clause
      if (SearchCondition <> nil) then
       SearchCondition.ExtractJoinConditions(LeftAO, RightAO,
                                       FieldList1, FieldList2);
    end
  end;

  // create join AO
  Result := TSQLMemAOJoin.Create(Session, Params,
                              LeftAO, RightAO, TableRef.JoinType,
                              TableRef.NaturalJoin,
                              (TableRef.UsingFields <> nil),
                              FieldList1, FieldList2);
  Result.CaseInsensitive := FDatabaseParams.CaseInsensitive;
 // try to apply join condition
 if (TableRef.SearchCondition <> nil) then
  begin
   try
     // added in v.5.10 - JOIN can have additional conditions that must be applied to this AOJoin
     if (not TableRef.SearchCondition.IsEmpty) then
       TableRef.SearchCondition.ApplyFilterParts(Result,False,True);
     if (not TableRef.SearchCondition.IsEmpty) then
     begin
       raise ESQLMemException.Create(12230, ErorrGNotApplicableCondition);
     end;
   finally
     TableRef.SearchCondition.Free;
     TableRef.SearchCondition := nil;
   end;
  end;

 // commented in v.5.70
{
 // set filter
 if (Result <> nil) then
  if (TableRef.SearchCondition <> nil) then
    TableRef.SearchCondition.ApplyFilterParts(Result,False,True);
}
 finally
  if (FieldList1 <> nil) then
   FieldList1.Free;
  if (FieldList2 <> nil) then
   FieldList2.Free;
 end;
end;// CreateJoinedTableAO


//------------------------------------------------------------------------------
// creates and adjusts AO
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.CreateAO(var TableRef: TSQLMemTableReference; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
begin
 case TableRef.TableType of
  attTable, attSubQuery:
    Result := CreateTableAO(TableRef,Session,Params);
  attJoinedTable:
    Result := CreateJoinedTableAO(TableRef,Session,Params);
  else
    Result := nil;
 end;
end;// CreateAO


//------------------------------------------------------------------------------
// builds one-table AO
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.BuildOneTableTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
begin
  // create AO
  Result := CreateAO(FromTables[0],Session,Params);
end;// BuildOneTableTree


//------------------------------------------------------------------------------
// builds multi-tables AO tree
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.BuildMultiTablesTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
var
  i, JoinConditionCount: integer;
  RightAO: TSQLMemAO;
  JoinType: TSQLMemJoinType;
  FieldList1, FieldList2: TSQLMemFields;
begin
 Result := CreateAO(FromTables[0],Session,Params);
 // create other joins
 for i := 1 to FromTablesCount-1 do
  begin
   // init column lists
   FieldList1 := nil;
   FieldList2 := nil;
   try
    RightAO := CreateAO(FromTables[i],Session,Params);
    // try to find join conditions in WHERE clause
    if (SearchCondition <> nil) then
     begin
       FieldList1 := TSQLMemFields.Create;
       FieldList2 := TSQLMemFields.Create;
       // try to extract conditions
       JoinConditionCount := SearchCondition.ExtractJoinConditions(Result, RightAO,
                                             FieldList1, FieldList2);
     end
    else
     JoinConditionCount := 0;

    if (JoinConditionCount = 0) then
     begin
      JoinType := ajtCross;
      if (FieldList1 <> nil) then
       FieldList1.Free;
      if (FieldList2 <> nil) then
       FieldList2.Free;
      FieldList1 := nil;
      FieldList2 := nil;
     end
    else
     JoinType := ajtInner;

    // create join AO
    Result := TSQLMemAOJoin.Create(Session, Params, Result, RightAO, JoinType, False,
                                False,
                                FieldList1, FieldList2);
    Result.CaseInsensitive := FDatabaseParams.CaseInsensitive;
   finally
     if (FieldList1 <> nil) then
      FieldList1.Free;
     if (FieldList2 <> nil) then
      FieldList2.Free;
   end;
  end;
end;// BuildMultiTablesTree


//------------------------------------------------------------------------------
// ClearSelectList
//------------------------------------------------------------------------------
procedure TSQLMemSQLSelect.ClearSelectList;
var i: Integer;
begin
 for i := 0 to SelectListCount-1 do
  if (SelectList[i].ValueExpr <> nil) then
   try
    SelectList[i].ValueExpr.Free;
   except
   end;
  SelectListCount := 0;
  SetLength(SelectList,SelectListCount);
end; // ClearSelectList


//------------------------------------------------------------------------------
// clear form tables
//------------------------------------------------------------------------------
procedure TSQLMemSQLSelect.ClearFromTables;
var i: Integer;
begin
  for i := 0 to FromTablesCount-1 do
   if (FromTables[i] <> nil) then
    try
     FromTables[i].Free;
    except
    end;
  FromTablesCount := 0;
  SetLength(FromTables,FromTablesCount);
end; // ClearFromTables


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLSelect.UpdateExpressionParams;
var i:    Integer;
    expr: TSQLMemExpression;
begin
  for i := 0 to SelectListCount-1 do
   begin
    expr := TSQLMemExpression(SelectList[i].ValueExpr);
    if (expr <> nil) then
     begin
      expr.StoredFunction := LStoredFunction;
      expr.LocalParams := LParams;
      expr.Session := FDatabaseParams.Session;
      expr.UpdateExpressionParams;
     end;
   end;
  for i := 0 to FromTablesCount-1 do
    FromTables[i].UpdateExpressionParams(LStoredFunction,FDatabaseParams.Session,LParams);
  if (SearchCondition <> nil) then
   begin
    SearchCondition.StoredFunction := LStoredFunction;
    SearchCondition.Session := FDatabaseParams.Session;
    SearchCondition.LocalParams := LParams;
    SearchCondition.UpdateExpressionParams;
   end;
  if (HavingCondition <> nil) then
   begin
    HavingCondition.StoredFunction := LStoredFunction;
    HavingCondition.Session := FDatabaseParams.Session;
    HavingCondition.LocalParams := LParams;
    HavingCondition.UpdateExpressionParams;
   end;
  GroupByFields.UpdateExpressionParams(LStoredFunction,FDatabaseParams.Session,LParams);
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLSelect.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemSQLSelect.Assign(Source: TSQLMemSQLCommand);
var i: Integer;
begin
  inherited Assign(Source);
  Distinct := TSQLMemSQLSelect(Source).Distinct;
  TopRowCount := TSQLMemSQLSelect(Source).TopRowCount;
  FirstRowNo := TSQLMemSQLSelect(Source).FirstRowNo;
  AllFields := TSQLMemSQLSelect(Source).AllFields;
  SelectListCount := TSQLMemSQLSelect(Source).SelectListCount;
  if (Length(SelectList) > 0) then
   ClearSelectList;
  SetLength(SelectList,SelectListCount);
  if (SelectListCount > 0) then
    for i := 0 to SelectListCount-1 do
     begin
      if (TSQLMemSQLSelect(Source).SelectList[i].ValueExpr = nil) then
       SelectList[i].ValueExpr := nil
      else
       begin
        SelectList[i].ValueExpr := TSQLMemExpression.Create;
        TSQLMemExpression(SelectList[i].ValueExpr).Assign(
          TSQLMemExpression(TSQLMemSQLSelect(Source).SelectList[i].ValueExpr));
       end;
      SelectList[i].TableName := TSQLMemSQLSelect(Source).SelectList[i].TableName;
      SelectList[i].AllFields := TSQLMemSQLSelect(Source).SelectList[i].AllFields;
      SelectList[i].FieldName := TSQLMemSQLSelect(Source).SelectList[i].FieldName;
      SelectList[i].IsExpression := TSQLMemSQLSelect(Source).SelectList[i].IsExpression;
      SelectList[i].Pseudonym := TSQLMemSQLSelect(Source).SelectList[i].Pseudonym;
     end;
  if (Length(FromTables) > 0) then
   ClearFromTables;
  FromTablesCount := TSQLMemSQLSelect(Source).FromTablesCount;
  SetLength(FromTables,FromTablesCount);
  if (FromTablesCount > 0) then
    for i := 0 to FromTablesCount-1 do
     begin
      FromTables[i] := TSQLMemTableReference.Create;
      FromTables[i].Assign(TSQLMemSQLSelect(Source).FromTables[i]);
     end;
  if (SearchCondition <> nil) then
   FreeAndNil(SearchCondition);
  if (TSQLMemSQLSelect(Source).SearchCondition <> nil) then
   begin
    SearchCondition := TSQLMemExpression.Create;
    SearchCondition.Assign(TSQLMemSQLSelect(Source).SearchCondition);
   end;
 GroupByFields.Clear;
 if (TSQLMemSQLSelect(Source).GroupByFields <> nil) then
  begin
   GroupByFields.Assign(TSQLMemSQLSelect(Source).GroupByFields);
  end;
 if (HavingCondition <> nil) then
   FreeAndNil(HavingCondition);
 if (TSQLMemSQLSelect(Source).HavingCondition <> nil) then
   begin
    HavingCondition := TSQLMemExpression.Create;
    HavingCondition.Assign(TSQLMemSQLSelect(Source).HavingCondition);
   end;
 FDoNotParseOrderBy := TSQLMemSQLSelect(Source).FDoNotParseOrderBy;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
{$IFDEF CORRELATED_SUBQUERIES}
constructor TSQLMemSQLSelect.Create(
                      Lexer:              TSQLMemLexer;
                      aDatabaseParams:    TSQLMemSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False;
                      aSubQuery:          Boolean = False
                     );
{$ELSE}
constructor TSQLMemSQLSelect.Create(
                      Lexer:              TSQLMemLexer;
                      aDatabaseParams:    TSQLMemSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False
                     );
{$ENDIF}
begin
  TopRowCount := -1; // default value
  FirstRowNo := -1;
  SelectListCount := 0;
  SetLength(SelectList, 0);
  FromTablesCount := 0;
  SetLength(FromTables, 0);
  SearchCondition := nil;
  HavingCondition := nil;
  GroupByFields := TSQLMemFields.Create;
  FDoNotParseOrderBy := DoNotParseOrderBy;
{$IFDEF CORRELATED_SUBQUERIES}
  FSubQuery := aSubQuery;
  if (FSubQuery) then
   FDoNotParseOrderBy := True;
{$ENDIF}
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;// Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemSQLSelect.Destroy;
begin
  try
    if (SearchCondition <> nil) then
     SearchCondition.Free;
    if (GroupByFields <> nil) then
     GroupByFields.Free;
    if (HavingCondition <> nil) then
     HavingCondition.Free;
    ClearSelectList;
    ClearFromTables;
  except
  end;
  inherited;
end;// Destroy


//------------------------------------------------------------------------------
// builds AO tree
//------------------------------------------------------------------------------
function TSQLMemSQLSelect.BuildAOTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
var
  i:                Integer;
  bGroupBy:         Boolean;
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter11);
aaStartTime(time11);
try
{$ENDIF}
 try
   // live result with 1 table?
   if ((FromTablesCount = 1) and (FromTables[0].TableType = attTable)) then
    Result := BuildOneTableTree(Session,Params)
   else
    Result := BuildMultiTablesTree(Session,Params);
 except
   // fixed in 4.95 - we must clear SelectList expressions if build process failed
   ClearSelectList;
   Result := nil;
   raise;
 end;
 try
  // create group by AO?
  bGroupBy := (GroupByFields.ItemCount > 0);
  // check for aggregates in select list
  if (not bGroupBy) then
   if (not AllFields) then
    begin
     for i := 0 to SelectListCount-1 do
      if (SelectList[i].ValueExpr <> nil) then
       if (TSQLMemExpression(SelectList[i].ValueExpr).IsAggregated) then
        begin
         bGroupBy := True;
         break;
        end;
    end;

  // apply parts of WHERE clause if possible
  if (SearchCondition <> nil) then
{$IFDEF CORRELATED_SUBQUERIES}
    FCorrelated := SearchCondition.ApplyFilterParts(Result,False,False,FSubQuery,True);
{$ELSE}
    SearchCondition.ApplyFilterParts(Result,False,False);
{$ENDIF}
  // create GroupByAO, apply having condition
  if (bGroupBy) then
   begin
    try
     Result := TSQLMemAOGroupBy.Create(Session, Params, Result, GroupByFields);
     Result.CaseInsensitive := FDatabaseParams.CaseInsensitive;
    except
     // to avoid duplicated destroying
     Result := nil;
     ClearSelectList;
     raise;
    end;
   end;

  // TOP n?
  if (TopRowCount > -1) then
   begin
// commented in v.4.60
{
    if (Result.FIsAOTable) then
     Result := TSQLMemAOSQLTopRowCount.Create(Result);
}
    Result.SetTopRowCount(FirstRowNo, TopRowCount);
   end;

  // sets projection
  Result.SetResultFields(SelectList,Distinct);

  // create GroupByAO, apply having condition
  if (bGroupBy) then
    if (HavingCondition <> nil) then
      if (not HavingCondition.IsEmpty) then
       begin
{$IFDEF CORRELATED_SUBQUERIES}
         if (FCorrelated) then
          HavingCondition.ApplyFilterParts(Result,True,False,True)
         else
          FCorrelated := HavingCondition.ApplyFilterParts(Result,True,False,FSubQuery,True);
{$ELSE}
         HavingCondition.ApplyFilterParts(Result,True,False);
{$ENDIF}
         if (not HavingCondition.IsEmpty) then
         begin
           // added in v.5.60
           HavingCondition.CheckInvalidFieldNames;
           raise ESQLMemException.Create(12428, ErorrGNotApplicableCondition);
         end;
       end;

  // sort - order by
  ApplyOrderBy(Result);

  // apply pseudonames parts of WHERE clause if possible
  if (SearchCondition <> nil) then
   if (not SearchCondition.IsEmpty) then
   begin
{$IFDEF CORRELATED_SUBQUERIES}
     if (FCorrelated) then
      SearchCondition.ApplyFilterParts(Result,False,False,True)
     else
      FCorrelated := SearchCondition.ApplyFilterParts(Result,False,False,FSubQuery);
{$ELSE}
     SearchCondition.ApplyFilterParts(Result,False, False);
{$ENDIF}
     if (not SearchCondition.IsEmpty) then
      begin
       // modified in 4.97 to handle invalid field name errors
       SearchCondition.CheckInvalidFieldNames;
       raise ESQLMemException.Create(30144, ErorrGNotApplicableCondition);
      end;
   end;

 except
  // commented in 4.97 to avoid double destroying expressions by Result.Free;
//  ClearSelectList;
  if (Assigned(Result)) then
   Result.Free;
  raise;
 end;
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time11);
end;
{$ENDIF}
end;//BuildAOTree




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLCommand
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLCommand.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  // will be created on first UpdateParams call
  LParamExprNodes := nil;
  {$IFDEF TRIAL_VERSION}
  {$IFNDEF TRIAL_VERSION_WITH_FULL_SQL}
   if ((not (Self is TSQLMemSQLCursorCommand)) and
       (not (Self is TSQLMemSQLSelect)) and (not (Self is TSQLMemSQLUnion))) then
    begin
     acrtrshnm;
     raise ESQLMemException.Create(10844,ErrorLCannotExecuteThisSQLStatementInTrialVersion);
    end;
  {$ENDIF}
  {$ENDIF}
  FReopen := False;
  LLex := Lexer;
  FDatabaseParams := aDatabaseParams;
  LStoredFunction := aStoredFunction;
  RowsAffected := 0;
  {$IFDEF SQLMEMTABLE}
  IntoMemory := True;
  {$ELSE}
  IntoMemory := False;
  {$ENDIF}
  DatabaseName := '';
  TableName := '';
  TableAlias := '';
  // parse with first token
  if (LLex <> nil) then
    Parse;
end;//Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemSQLCommand.Destroy;
begin
  if (LParamExprNodes <> nil) then
  begin
   LParamExprNodes.Free;
   LParamExprNodes := nil;
  end;
  SQLMemClearString(FDatabaseParams.DatabaseName);
  SQLMemClearString(FDatabaseParams.SessionName);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.Parse;
begin
;
end; // Parse


//------------------------------------------------------------------------------
// parses list of columns (without table name): field1, field2, ...
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.ParseColumnList(var Fields: TSQLMemWideStringList);

function ParseColumnName(var ColumnName: WideString): Boolean;
begin
 Result := False;
 if (Token.TokenType in [tktString, tktQuotedString, tktBackQuotedString, tktBracketedString]) then
  begin
   ColumnName := Token.Text;
   GetNextToken;
   Result := True;
  end;
end;

var
  s: WideString;

begin
  // get ColumnName
  if (ParseColumnName(s)) then
   // all columns
   repeat
    // create list if necessary
    if (Fields = nil) then
     Fields := TSQLMemWideStringList.Create;
    // add column name
    Fields.Add(s);
    // ','?
    if (Token.TokenType <> tktComma) then
       break
    else
      // skip ','token
      GetNextToken([tktString, tktQuotedString, tktBackQuotedString, tktBracketedString],10406,
        ErrorLUnexpectedToken);
    // get next field
    if (not ParseColumnName(s)) then
     raise ESQLMemException.Create(10407,ErrorLFieldNameExpected,
      [Token.Text, Token.LineNum, Token.ColumnNum]);
   until (False)
  else
   raise ESQLMemException.Create(10408, ErrorLFieldNameExpected,
    [Token.Text, Token.LineNum, Token.ColumnNum]);
end; // ParseColumnList


//------------------------------------------------------------------------------
// parses list of fields:  table.field1, field2, ..
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.ParseFieldList(var Fields: TSQLMemFields);

function ParseFieldSpecification(var Fields: TSQLMemFields): Boolean;
var
   item: TSQLMemSelectListItem;
   TableName, FieldName: WideString;
   Expr: TSQLMemExpression;
begin
 Result := True;
 // parse field as expression
 Expr := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
 try
  Expr.InMemory := GetInMemory;
  Expr.DatabaseName := GetDatabaseName;
  Expr.SessionName := GetSessionName;
  Expr.CaseInsensitive := FDatabaseParams.CaseInsensitive;
  Expr.ParseForValueExpression(LLex);
  // only field is allowed
  if (not Expr.IsField) then
   raise ESQLMemException.Create(10409, ErrorLFieldNameExpected,
            [Token.Text, Token.LineNum, Token.ColumnNum]);
  GetCurrentToken;
  // extract field name, table name
  Expr.GetFieldInfo(TableName, FieldName);
  // add item
  item.TableName := TableName;
  item.FieldName := FieldName;
  item.IsExpression := False;
  item.AllFields := false;
  item.Pseudonym := '';
  item.ValueExpr := nil;
  Fields.Append(item);
 finally
  Expr.Free;
 end;

end;

begin
    // parse field specification list
    if (ParseFieldSpecification(Fields)) then
     // get all specs
     repeat
        // end of sql command?
        if (Token.TokenType <> tktComma) then
          break
        else
          // skip ','token
          GetNextToken([tktString, tktQuotedString, tktBracketedString,
                        tktBackQuotedString,
                        tktReservedWord],10410,ErrorLUnexpectedToken);
       // get next spec
       if (not ParseFieldSpecification(Fields)) then
        raise ESQLMemException.Create(10411, ErrorLFieldNameExpected,
                  [Token.Text, Token.LineNum, Token.ColumnNum]);
     until False
    else
      raise ESQLMemException.Create(10412, ErrorLFieldNameExpected,
          [Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseFieldList


//------------------------------------------------------------------------------
// parse TableName token
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.ParseTableNameToken;
begin
  if not (Token.TokenType in [tktString, tktQuotedString, tktBackQuotedString, tktReservedWord, tktBracketedString]) then
    raise ESQLMemException.Create(30230, ErrorGTableNameExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);

  // MEMORY
  if IsReservedWord(Token, rwMEMORY) then
   begin
    IntoMemory := true;
    GetNextToken([{tktReservedWord,}tktString,tktQuotedString,tktBackQuotedString,tktBracketedString],
                  30231, ErrorGTableNameExpected);
   end;
  // table_name
  TableName := Token.Text;
  if (GetNextToken([tktDot],-1,ErrorGTableNameExpected)) then
  begin
    if (GetNextToken([{tktReservedWord,}tktString,tktQuotedString,tktBackQuotedString,tktBracketedString],
                  -1, ErrorGTableNameExpected)) then
     begin
      DatabaseName := TableName;
      TableName := Token.Text;
      GetNextToken;
    end;
  end;
  // check pseudonym - correlation name (Table1 AS t1)
  if (IsReservedWord(Token, rwAS)) then
      begin
       // get next token (t1?)
       GetNextToken([tktString, tktQuotedString,
                     tktBackQuotedString, tktBracketedString],
                     12430, ErrorGFieldPseudonymExpected);
       // got pseudonym
       TableAlias := Token.Text;
       // get next token
       GetNextToken;
      end
  else
  if (Token.TokenType in [tktString, tktQuotedString,
                  tktBackQuotedString, tktBracketedString]) then
  begin
   // got pseudonym
   TableAlias := Token.Text;
   // get next token
   GetNextToken;
  end;
  if (not IntoMemory) and (GetInMemory) then
    IntoMemory := True;
  if (IntoMemory = GetInMemory) then
   if (DatabaseName = '') then
    DatabaseName := GetDatabaseName;
end; // ParseTableNameToken


//------------------------------------------------------------------------------
// set InMemory,DatabaseName,TableName to TSQLMemDataset
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.SetTableNameParams(t: TDataset);
begin
 if (t <> nil) then
  if (t is TSQLMemDataset) then
   begin
    TSQLMemDataset(t).InMemory := GetInMemory or IntoMemory;
    if (DatabaseName <> '') then
     TSQLMemDataset(t).DatabaseName := DatabaseName
    else
    if (not IntoMemory) then
     TSQLMemDataset(t).DatabaseName := GetDatabaseName;
    if (t is TSQLMemTable) then
     TSQLMemTable(t).TableName := TableName;
    // commented in v.5.60
//   if (GetSessionName <> '') and  (TSQLMemDataset(t).DatabaseName = GetDatabaseName) then
      TSQLMemDataset(t).SessionName := GetSessionName;
     //TSQLMemDataset(t).Password := Password;
   end;
end; // SetTableNameParams


//------------------------------------------------------------------------------
// get current token
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetCurrentToken: Boolean;
begin
 Result := LLex.GetCurrentToken(Token);
end;// GetCurrentToken


//------------------------------------------------------------------------------
// get next token
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetNextToken: Boolean;
begin
 Result := LLex.GetNextToken(Token);
end;//GetNextToken


//------------------------------------------------------------------------------
// get next token
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetNextToken(PermittedTypes: TTokenTypes;
  NativeErrorCode: integer; ErrorText: AnsiString): Boolean;
begin
  // get next token
  Result := LLex.GetNextToken(Token);
  if (not Result) then
   if (NativeErrorCode <> -1) then
      raise ESQLMemException.Create(30161, ErrorGUnexpectedEndOfCommand,
                                 [Token.LineNum, Token.ColumnNum]);
  // check token type
  if (Result) then
   if (PermittedTypes <> []) then
    if (not (Token.TokenType in PermittedTypes)) then
     if (NativeErrorCode <> -1) then
       raise ESQLMemException.Create(NativeErrorCode, ErrorText,
                                 [Token.Text, Token.LineNum, Token.ColumnNum])
      else
         Result := False;
end;//GetNextToken


//------------------------------------------------------------------------------
// re-open parametrized query
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.Reopen(
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                    );

begin
  FReopen := True;
  try
    ExecSQL(True,RequestLive,ReadOnly);
  finally
    FReopen := False;
  end;
end; // Reopen


//------------------------------------------------------------------------------
// update parameter values in all expressions
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.UpdateParams(SQLParams: TSQLMemSQLParams);
var i,Index: Integer;
    Node:    TSQLMemExprNodeConst;
begin
  if (LParamExprNodes <> nil) then
   for i := 0 to LParamExprNodes.Count-1 do
    begin
     Node := TSQLMemExprNodeConst(LParamExprNodes.Items[i]);
     Index := SQLParams.FindByNameCRC(Node.ParamCRC);
     if (Index >= 0) then
      Node.SetDataValue(SQLParams.Items[Index]);
    end;
end; // UpdateParams


//------------------------------------------------------------------------------
// return InMemory if was set in FDatabaseParams
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetInMemory: Boolean;
begin
  if (FDatabaseParams.ParamsSet) then
   Result := FDatabaseParams.InMemory
  else
{$IFDEF SQLMEMTABLE}
   Result := True;
{$ELSE}
   Result := False;
{$ENDIF}
end; // GetInMemory


//------------------------------------------------------------------------------
// return DatabaseName if was set in FDatabaseParams
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetDatabaseName: AnsiString;
begin
  if (FDatabaseParams.ParamsSet and (DatabaseName = '')) then
   Result := FDatabaseParams.DatabaseName
  else
   Result := DatabaseName;
end; // GetDatabaseName


//------------------------------------------------------------------------------
// return SessionName if was set in FDatabaseParams
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetSessionName: AnsiString;
begin
  if (FDatabaseParams.ParamsSet) then
   Result := FDatabaseParams.SessionName
  else
   Result := '';
end; // GetSessionName


//------------------------------------------------------------------------------
// Create SQLMemTable object and fill SQLMemTable params
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.CreateInternalSQLMemTable: TDataSet;
begin
  Result := TSQLMemTable.Create(nil);
  SetTableNameParams(Result);
end;//CreateInternalSQLMemTable


//------------------------------------------------------------------------------
// get result cursor
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetResultCursor: TSQLMemCursor;
begin
  Result := nil;
end;//GetResultCursor


//------------------------------------------------------------------------------
// gets result dataset
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.GetResultDataset: TDataset;
begin
  Result := nil;
end;// GetResultDataset


//------------------------------------------------------------------------------
// set database params
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.SetDatabaseParams(Session: TSQLMemBaseSession);
begin
  if (Session = nil) then
   raise ESQLMemException.Create(12183,ErrorLNilPointer);
  Session.SetDatabaseParams(FDatabaseParams); 
end; // SetDatabaseParams


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.UpdateExpressionParams;
begin
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.CreateCopy: TSQLMemSQLCommand;
begin
  Result := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemSQLCommand.Assign(Source: TSQLMemSQLCommand);
begin
  if (Source = nil) then
    raise ESQLMemException.Create(12184,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise ESQLMemException.Create(12185,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  // table name and database name
  IntoMemory := Source.IntoMemory;
  IntoDatabase := Source.IntoDatabase;
  IntoTable := Source.IntoTable;
  DatabaseName := Source.DatabaseName;
  TableName := Source.TableName;
end; // Assign


//------------------------------------------------------------------------------
// make copy of TSQLMemSQLCommand object
//------------------------------------------------------------------------------
function TSQLMemSQLCommand.MakeCopy(aSession: TSQLMemBaseSession; LocalParams: TSQLMemSQLParams): TSQLMemSQLCommand;
begin
  Result := CreateCopy;
  Result.LParams := LocalParams;
  if (aSession <> nil) then
   aSession.SetDatabaseParams(Result.FDatabaseParams)
  else
   Result.FDatabaseParams := FDatabaseParams;
  Result.Assign(Self);
  Result.UpdateExpressionParams;
end; // MakeCopy




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemQueryExprNode
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemQueryExprNode.Create;
begin
  NodeType := qetSelect;
  Left := nil;
  Right := nil;
  All := False;
  Corresponding := False;
  CorrespondingFields := nil;
  SelectCommand := nil;
end;// Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemQueryExprNode.Create(Src: TSQLMemQueryExprNode);
begin
  NodeType := Src.NodeType;
  Left := Src.Left;
  Right := Src.Right;
  All := Src.All;
  Corresponding := Src.Corresponding;
  CorrespondingFields := Src.CorrespondingFields;
  SelectCommand := Src.SelectCommand;
end;// Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemQueryExprNode.Destroy;
begin
 if (Left <> nil) then
  Left.Free;
 if (Right <> nil) then
  Right.Free;

 if (SelectCommand <> nil) then
  SelectCommand.Free;
end;// Destroy

procedure TSQLMemQueryExprNode.AddNode(NewType: TSQLMemQueryExprType;
  RightNode: TSQLMemQueryExprNode; bAll, bCorresponding: Boolean;
  ColumnList: TSQLMemWideStringList);
var
  LeftNode: TSQLMemQueryExprNode;
begin
  // copy current node to left
  LeftNode := TSQLMemQueryExprNode.Create(Self);

  // set childs
  Left := LeftNode;
  Right := RightNode;

  // set current data as: union | except | ...
  SelectCommand := nil;
  NodeType := NewType;
  CorrespondingFields := ColumnList;
  All := bAll;
  Corresponding := bCorresponding;
end;// AddNode


//------------------------------------------------------------------------------
// return child node with SELECT INTO - needed for UNION, EXCEPT, INTERSECT
//------------------------------------------------------------------------------
function TSQLMemQueryExprNode.FindSelectInto: TSQLMemSQLCommand;
begin
  Result := nil;
  if (NodeType = qetSelect) then
   if (SelectCommand <> nil) then
    if (SelectCommand.IntoTable <> '') then
     begin
      Result := Self.SelectCommand;
     end;
  if (Result = nil) then
   begin
    if (Left <> nil) then
     Result := Left.FindSelectInto;
   end;
  if (Result = nil) then
   begin
    if (Right <> nil) then
     Result := Right.FindSelectInto;
   end;
end; // FindSelectInto


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemQueryExprNode.Assign(Source: TSQLMemQueryExprNode);
begin
  if (Source = nil) then
    raise ESQLMemException.Create(12194,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise ESQLMemException.Create(12195,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  if (Left <> nil) then
   FreeAndNil(Left);
  if (Right <> nil) then
   FreeAndNil(Right);
  NodeType := Source.NodeType;
  if (Source.Left <> nil) then
   begin
    Left := TSQLMemQueryExprNode.Create;
    Left.Assign(Source.Left);
   end;
  if (Source.Right <> nil) then
   begin
    Right := TSQLMemQueryExprNode.Create;
    Right.Assign(Source.Right);
   end;
  All := Source.All;
  Corresponding := Source.Corresponding;
  if (Source.CorrespondingFields = nil) then
   begin
    if (CorrespondingFields <> nil) then
     FreeAndNil(CorrespondingFields);
   end
  else
   begin
    if (CorrespondingFields = nil) then
     CorrespondingFields := TSQLMemWideStringList.Create;
    CorrespondingFields.Assign(Source.CorrespondingFields);
   end;
  if (SelectCommand <> nil) then
   FreeAndNil(SelectCommand);
  if (Source.SelectCommand <> nil) then
   begin
    SelectCommand := TSQLMemSQLSelect.Create(nil,
        Source.SelectCommand.FDatabaseParams,Source.SelectCommand.LStoredFunction);
    SelectCommand.Assign(Source.SelectCommand);
   end;
end; // Assign


//------------------------------------------------------------------------------
// update expression params in this node and all children
//------------------------------------------------------------------------------
procedure TSQLMemQueryExprNode.UpdateExpressionParams(
                LStoredFunction:  TObject;
                LSession:         TSQLMemBaseSession;
                LParams:          TSQLMemSQLParams
                                  );
begin
  if (SelectCommand <> nil) then
   begin
    SelectCommand.LStoredFunction := LStoredFunction;
    LSession.SetDatabaseParams(SelectCommand.FDatabaseParams);
    SelectCommand.LParams := LParams;
    SelectCommand.UpdateExpressionParams;
   end;
  if (Left <> nil) then
   Left.UpdateExpressionParams(LStoredFunction,LSession,LParams);
  if (Right <> nil) then
   Right.UpdateExpressionParams(LStoredFunction,LSession,LParams);
end; // UpdateExpressionParams




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLUnion
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// parses [ALL]
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseAll: Boolean;
begin
  Result := IsReservedWord(Token, rwALL);
  // skip token
  if (Result) then
   GetNextToken;
end;//ParseAll


//------------------------------------------------------------------------------
// parses [ <corresponding spec> ]
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseCorrespondingSpec(var ColumnsList: TSQLMemWideStringList): Boolean;
begin
  ColumnsList := nil;
  Result := IsReservedWord(Token, rwCORRESPONDING);
  if (Result) then
   begin
    // skip token
    GetNextToken;
    // BY (<corresponding column list>)?
    if (IsReservedWord(Token, rwBY)) then
     begin
      // skip token
      GetNextToken;
      // '('?
      if (Token.TokenType = tktLeftParenthesis) then
       begin
        // skip '('
        GetNextToken;

        // parses fields list
        ParseColumnList(ColumnsList);

        // skip ')'
        if (Token.TokenType = tktRightParenthesis) then
          GetNextToken; // end of query is possible here
       end
      else
        raise ESQLMemException.Create(30193, ErrorGOtherTokenExpected,
                    ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
   end;
end;// ParseCorrespondingSpec


//------------------------------------------------------------------------------
// parses SELECT ...
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseQuerySpecification: TSQLMemQueryExprNode;
var
  SelectNode: TSQLMemQueryExprNode;
begin
  if (IsReservedWord(Token, rwSELECT) or IsReservedWord(Token, rwGET)) then
   begin
    SelectNode := TSQLMemQueryExprNode.Create;
    SelectNode.NodeType := qetSelect;
    try
     // modified in v.5.01
{$IFDEF CORRELATED_SUBQUERIES}
     SelectNode.SelectCommand := TSQLMemSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction, FUnion, FSubQuery);
{$ELSE}
     SelectNode.SelectCommand := TSQLMemSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction, FUnion);
{$ENDIF}
     GetCurrentToken;
    except
     SelectNode.Free;
     raise;
    end;
    Result := SelectNode;
   end
  else
   raise ESQLMemException.Create(30194, ErrorGOtherTokenExpected,
              ['SELECT', Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseQuerySpecification


//------------------------------------------------------------------------------
// parses <query specification> | <table value constructor>  | <explicit table>
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseSimpleTable: TSQLMemQueryExprNode;
begin
  Result := ParseQuerySpecification;
end;// ParseSimpleTable


//------------------------------------------------------------------------------
// parses <simple table> |
// <left paren> <non-join query expression> <right paren>
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseNonJoinQueryPrimary: TSQLMemQueryExprNode;
begin
  // '('?
  if (Token.TokenType = tktLeftParenthesis) then
   begin
     // skip '('
     GetNextToken;

     // parses <query expression>
     Result := ParseQueryExpression;

     // skip ')'
     if (Token.TokenType = tktRightParenthesis) then
       GetNextToken; // end of query is possible here
   end
  else
   Result := ParseSimpleTable;
end;// ParseNonJoinQueryPrimary


//------------------------------------------------------------------------------
// parses <non-join query primary> |
// <query term> INTERSECT [ ALL ] [ <corresponding spec> ] <query primary>
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseNonJoinQueryTerm: TSQLMemQueryExprNode;
var
  RightNode: TSQLMemQueryExprNode;
  bAll, bCorresponding: Boolean; // union or except
  ColumnList: TSQLMemWideStringList; // corresponding spec
begin
  // parse <non-join query primary>
  Result := ParseNonJoinQueryPrimary;

  // intersects?
  while (IsReservedWord(Token, rwINTERSECT)) do
   begin
     // skip INTERSECT token
     GetNextToken;

     // [ALL]
     bAll := ParseAll;

     // [ <corresponding spec> ]
     bCorresponding := ParseCorrespondingSpec(ColumnList);

     // parse <non-join query primary>
     RightNode := ParseNonJoinQueryPrimary;

     // make Intersect node
     Result.AddNode(qetIntersect, RightNode, bAll, bCorresponding, ColumnList);
   end;
end;// ParseNonJoinQueryTerm


//------------------------------------------------------------------------------
// parses <non-join query term> |
// <query expression> UNION  [ ALL ] [ <corresponding spec> ] <query term> |
// <query expression> EXCEPT [ ALL ] [ <corresponding spec> ] <query term>
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseNonJoinQueryExpression: TSQLMemQueryExprNode;
var
  RightNode:            TSQLMemQueryExprNode;
  bAll, bCorresponding: Boolean; // union or except
  ColumnList:           TSQLMemWideStringList; // corresponding spec
  NewType:              TSQLMemQueryExprType;
begin
  // parse <non-join query term>
  Result := ParseNonJoinQueryTerm;
  // unions | excepts?
  while (IsReservedWord(Token, rwUNION) or
         IsReservedWord(Token, rwINTERSECT) or
         IsReservedWord(Token, rwMINUS) or
         IsReservedWord(Token, rwEXCEPT)) do
   begin
     FUnion := True;
     // union or except?
     if (IsReservedWord(Token, rwUNION)) then
      NewType := qetUnion
     else
     if (IsReservedWord(Token, rwINTERSECT)) then
      NewType := qetIntersect
     else
      NewType := qetExcept;
     // skip UNION | EXCEPT token
     GetNextToken;

     // [ALL]
     bAll := ParseAll;

     // [ <corresponding spec> ]
     bCorresponding := ParseCorrespondingSpec(ColumnList);

     // parse <non-join query term>
     RightNode := ParseNonJoinQueryTerm;

     // make union | except node
     Result.AddNode(NewType, RightNode, bAll, bCorresponding, ColumnList);
   end;
  if (FUnion) then
   begin
    ParseOrderByClause;
   end;
end;// ParseNonJoinQueryExpression


//------------------------------------------------------------------------------
// parses <non-join query expression>  | <joined table>
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.ParseQueryExpression: TSQLMemQueryExprNode;
begin
  Result := ParseNonJoinQueryExpression;
end;// ParseQueryExpression


//------------------------------------------------------------------------------
// parses query
// SELECT INTO must be the first
//------------------------------------------------------------------------------
procedure TSQLMemSQLUnion.Parse;
var Node: TSQLMemSQLCommand;
begin
  GetCurrentToken;
  FRootNode := ParseQueryExpression;
  // store INTO parameters
  // fixed in 4.95
  if (FRootNode <> nil) then
   if (FRootNode.NodeType = qetSelect) then
    begin
     if (FRootNode.SelectCommand <> nil) then
      if (FRootNode.SelectCommand.IntoTable <> '') then
       begin
        IntoTable := FRootNode.SelectCommand.IntoTable;
        IntoDatabase := FRootNode.SelectCommand.IntoDatabase;
        IntoMemory := FRootNode.SelectCommand.IntoMemory;
       end;
    end // select
   else
    if (FRootNode.NodeType = qetUnion) then
     begin
      Node := FRootNode.FindSelectInto;
      if (Node <> nil) then
        begin
         IntoTable := Node.IntoTable;
         IntoDatabase := Node.IntoDatabase;
         IntoMemory := Node.IntoMemory;
        end;
     end; // union
end;// Parse


//------------------------------------------------------------------------------
// builds AO
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.BuildAO(Node: TSQLMemQueryExprNode; Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
var
  LeftAO, RightAO:      TSQLMemAO;
  UnionType:            TSQLMemUnionType;
  CorrespondingFields:  TSQLMemFields;
  Item:                 TSQLMemSelectListItem;
  i:                    Integer;
begin
 if (Node.NodeType = qetSelect) then
 begin
   Result := Node.SelectCommand.BuildAOTree(Session,Params);
   // added in v.5.90 to avoid skipping ORDER BY
   AssignOrderBy(Node.SelectCommand);
 end
 else
  begin
    // union | except | intersect
    LeftAO := BuildAO(Node.Left,Session,Params);
    try
      // added in v.5.90 to avoid skipping ORDER BY
      AssignOrderBy(Node.Left.SelectCommand);
      RightAO := BuildAO(Node.Right,Session,Params);
      // added in v.5.90 to avoid skipping ORDER BY
      AssignOrderBy(Node.Right.SelectCommand);
    except
      // added in 4.97
      LeftAO.Free;
      raise;
    end;
    UnionType := autUnion;
    case (Node.NodeType) of
      qetUnion:
         UnionType := autUnion;
      qetExcept:
         UnionType := autExcept;
      qetIntersect:
         UnionType := autIntersect;
    end;

    if (Node.CorrespondingFields <> nil) then
     begin
      CorrespondingFields := TSQLMemFields.Create;
      // fill fields list
      Item.TableName := '';
      Item.Pseudonym := '';
      Item.AllFields := False;
      Item.IsExpression := False;
      Item.ValueExpr := nil;
      for i := 0 to Node.CorrespondingFields.Count-1 do
       begin
        Item.FieldName := Node.CorrespondingFields.Strings[i];
        CorrespondingFields.Append(Item);
       end
     end
    else
     CorrespondingFields := nil;
    try
     // create AO
     Result := TSQLMemAOUnion.Create(Session, Params,
                                  LeftAO, RightAO, UnionType,
                                  Node.Corresponding, not Node.All,
                                  CorrespondingFields);
     Result.CaseInsensitive := FDatabaseParams.CaseInsensitive;
    finally
     if (CorrespondingFields <> nil) then
      CorrespondingFields.Free;
    end;
  end;
end;// BuildAO


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLUnion.UpdateExpressionParams;
begin
  FRootNode.UpdateExpressionParams(LStoredFunction,FDatabaseParams.Session,LParams);
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLUnion.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLUnion.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  if (FRootNode <> nil) then
   FreeAndNil(FRootNode);
  if (TSQLMemSQLUnion(Source).FRootNode <> nil) then
   begin
    FRootNode := TSQLMemQueryExprNode.Create;
    FRootNode.Assign(TSQLMemSQLUnion(Source).FRootNode);
   end;
  FUnion := TSQLMemSQLUnion(Source).FUnion;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
{$IFDEF CORRELATED_SUBQUERIES}
constructor TSQLMemSQLUnion.Create(
                      Lexer:            TSQLMemLexer;
                      aDatabaseParams:  TSQLMemSQLDatabaseParams;
                      aStoredFunction:  TObject;
                      aSubQuery:        Boolean = False
                               );
{$ELSE}
constructor TSQLMemSQLUnion.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
{$ENDIF}
begin
 FRootNode := nil; // not parsed yet
 FUnion := False;
{$IFDEF CORRELATED_SUBQUERIES}
 FSubQuery := aSubQuery;
{$ENDIF}
 inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;// Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemSQLUnion.Destroy;
begin
  if (FRootNode <> nil) then
    FRootNode.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// builds AO tree
//------------------------------------------------------------------------------
function TSQLMemSQLUnion.BuildAOTree(Session: TSQLMemBaseSession; Params: TSQLMemSQLParams): TSQLMemAO;
begin
  Result := BuildAO(FRootNode,Session,Params);
  ApplyOrderBy(Result);
end;// BuildAOTree




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLCursorCommand
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// <sort key> [ <collate clause> ] [ <ordering specification> ]
//------------------------------------------------------------------------------
function TSQLMemSQLCursorCommand.ParseSortSpecification: Boolean;
begin
  Result := True;
  if (Token.TokenType in
       [tktInt, tktString, tktBracketedString, tktBackQuotedString, tktReservedWord, tktQuotedString]) then
   begin
     // new order spec
     Inc(OrderBySpecsCount);
     SetLength(OrderBySpecs, OrderBySpecsCount);
     if (Token.TokenType = tktInt) then
      OrderBySpecs[OrderBySpecsCount-1].ColumnNumber := StrToInt(Token.Text)
     else
      begin
       OrderBySpecs[OrderBySpecsCount-1].ColumnNumber := -1;
       OrderBySpecs[OrderBySpecsCount-1].ColumnName := Token.Text;
      end;
     OrderBySpecs[OrderBySpecsCount-1].CaseInsensitive := False;
     // get next token
     GetNextToken;
     // "." ?
     if (Token.TokenType = tktDot) then
      begin
       // previous token was table name
       OrderBySpecs[OrderBySpecsCount-1].TableName :=
                      OrderBySpecs[OrderBySpecsCount-1].ColumnName;
       // get next token - column name
       GetNextToken([tktString, tktQuotedString, tktBackQuotedString, tktBracketedString, tktReservedWord],
                    30186, ErrorGUnexpectedToken);
       OrderBySpecs[OrderBySpecsCount-1].ColumnName := Token.Text;
       // get next token
       GetNextToken;
      end;
     // ASC | DESC ?
     if (IsReservedWord(Token, rwASC)) then
      begin
       OrderBySpecs[OrderBySpecsCount-1].Descending := False;
       // skip ASC token
       GetNextToken;
       if (IsReservedWord(Token, rwNOCASE)) then
        begin
         OrderBySpecs[OrderBySpecsCount-1].CaseInsensitive := True;
         // skip NOCASE token
         GetNextToken;
        end;
      end
     else
     if (IsReservedWord(Token, rwDESC)) then
      begin
       OrderBySpecs[OrderBySpecsCount-1].Descending := True;
       // skip DESC token
       GetNextToken;
       if (IsReservedWord(Token, rwNOCASE)) then
        begin
         OrderBySpecs[OrderBySpecsCount-1].CaseInsensitive := True;
         // skip NOCASE token
         GetNextToken;
        end;
      end
     else
     if (IsReservedWord(Token, rwNOCASE)) then
      begin
       OrderBySpecs[OrderBySpecsCount-1].CaseInsensitive := True;
       // skip NOCASE token
       GetNextToken;
      end;
   end
  else
   raise ESQLMemException.Create(30187, ErrorGFieldNameExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseSortSpecification


//------------------------------------------------------------------------------
// ORDER BY
//------------------------------------------------------------------------------
function TSQLMemSQLCursorCommand.ParseOrderByClause: Boolean;
begin
 if (IsReservedWord(Token, rwORDER)) then
  begin
    Result := True;
    // skip ORDER token
    GetNextToken;
    // 'BY'?
    if (not IsReservedWord(Token, rwBY)) then
     raise ESQLMemException.Create(30188, ErrorGOtherTokenExpected,
                  ['BY', Token.Text, Token.LineNum, Token.ColumnNum]);
    // skip BY token
    GetNextToken;

    if (IsReservedWord(Token, rwINDEX)) then
     begin
       // get IndexName
       GetNextToken([tktString, tktQuotedString, tktBackQuotedString, tktBracketedString],
                     11244, ErrorGUnexpectedToken);
       OrderByIndex := Token.Text;
       // skip IndexName token
       GetNextToken;
     end
    else
     begin
      // parse sort specification list
      if (ParseSortSpecification) then
       // get all specs
       repeat
          // end of sql command?
          if (Token.TokenType <> tktComma) then
            break
          else
            // skip ','token
            GetNextToken([tktInt, tktString, tktQuotedString,
                          tktBackQuotedString, tktBracketedString, tktReservedWord],
                         30189, ErrorGUnexpectedToken);
         // get next spec
         if (not ParseSortSpecification) then
          raise ESQLMemException.Create(30190, ErrorGSortSpecificationExpected,
                          [Token.Text, Token.LineNum, Token.ColumnNum]);

       until False
      else
        raise ESQLMemException.Create(30191, ErrorGSortSpecificationExpected,
                          [Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
  end
 else
  Result := False;
end;// ParseOrderByClause


//------------------------------------------------------------------------------
// applies Order By clause
//------------------------------------------------------------------------------
procedure TSQLMemSQLCursorCommand.ApplyOrderBy(AO: TSQLMemAO);
begin
  if ((OrderBySpecsCount > 0) or (OrderByIndex <> '')) then
   begin
     AO.SetOrderBy(OrderBySpecs,OrderBySpecsCount,OrderByIndex);
   end;
end;// ApplyOrderBy


//------------------------------------------------------------------------------
// update parameter values in all expressions
//------------------------------------------------------------------------------
procedure TSQLMemSQLCursorCommand.UpdateParams(SQLParams: TSQLMemSQLParams);
begin
  if (LParamExprNodes = nil) and (RootAO <> nil) then
    LParamExprNodes := RootAO.ParamNodes;
  inherited;
end; // UpdateParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLCursorCommand.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLCursorCommand.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign order by
//------------------------------------------------------------------------------
procedure TSQLMemSQLCursorCommand.AssignOrderBy(Source: TSQLMemSQLCursorCommand);
var i,l: Integer;
begin
 if (Source <> nil) then
   if (Source.OrderBySpecsCount > 0) then
   begin
    l := Length(TSQLMemSQLCursorCommand(Source).OrderBySpecs);
    SetLength(OrderBySpecs,l);
    if (l > 0) then
      for i := 0 to l-1 do
       begin
        OrderBySpecs[i].TableName := TSQLMemSQLCursorCommand(Source).OrderBySpecs[i].TableName;
        OrderBySpecs[i].ColumnName := TSQLMemSQLCursorCommand(Source).OrderBySpecs[i].ColumnName;
        OrderBySpecs[i].ColumnNumber := TSQLMemSQLCursorCommand(Source).OrderBySpecs[i].ColumnNumber;
        OrderBySpecs[i].Descending := TSQLMemSQLCursorCommand(Source).OrderBySpecs[i].Descending;
        OrderBySpecs[i].CaseInsensitive := TSQLMemSQLCursorCommand(Source).OrderBySpecs[i].CaseInsensitive;
       end;
    OrderBySpecsCount := TSQLMemSQLCursorCommand(Source).OrderBySpecsCount;
    OrderByIndex := TSQLMemSQLCursorCommand(Source).OrderByIndex;
   end;
end; // AssignOrderBy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLCursorCommand.Assign(Source: TSQLMemSQLCommand);
begin
  if (Source = nil) then
   Exit;
  inherited Assign(Source);
  if (TSQLMemSQLCursorCommand(Source).RootAO = nil) then
   begin
    if (RootAO <> nil) then
      FreeAndNil(RootAO);
   end
  else
   begin
    if (RootAO <> nil) then
      FreeAndNil(RootAO);
//    RootAO := TSQLMemSQLCursorCommand(Source).RootAO.MakeCopy;
   end;
  FRequestLive := TSQLMemSQLCursorCommand(Source).FRequestLive;
  AssignOrderBy(TSQLMemSQLCursorCommand(Source));
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLCursorCommand.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
{$IFDEF CORRELATED_SUBQUERIES}
  FCorrelated := False;
{$ENDIF}
  OrderByIndex := '';
  OrderBySpecsCount := 0;
  SetLength(OrderBySpecs, 0);
  RootAO := nil;
  IntoTable := '';
  IntoDatabase := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
  FRequestLive := FDatabaseParams.RequestLive;
  FLockTablesInWriteMode := False;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemSQLCursorCommand.Destroy;
begin
  if (RootAO <> nil) then
    RootAO.Free;
  RootAO := nil;  
  LParamExprNodes := nil;
  SetLength(OrderBySpecs, 0);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemSQLCursorCommand.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                      );
var
  dest:       TSQLMemTable;
  log:        AnsiString;

begin
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('> TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter3);
aaStartTime(time3);
try
{$ENDIF}
  RowsAffected := 0;
  FRequestLive := RequestLive;
  if (FReopen) then
   RootAO.RestartMaterialization := True
  else
   begin
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('1 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
    if (RootAO <> nil) then
     RootAO.Free;
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('2 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStartTime(time12);
{$ENDIF}
    RootAO := BuildAOTree(FDatabaseParams.Session,LParams);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time12);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('3 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
   end;
  try
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('4 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStartTime(time13);
{$ENDIF}
    RootAO.LockTable(FLockTablesInWriteMode);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time13);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('5 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
  except
    RootAO.Free;
    RootAO := nil;
    raise;
  end;
  try
// commented in v.4.60 - to avoid double copying the materialized table
{
    if ((IntoTable <> '') and
       (not RootAO.FIsAOTable) and (IntoTable <> '')) then
}
    if (IntoTable <> '') then
     begin
// commneted in 4.95
//      if (not IntoMemory) then
      if (IntoDatabase = '') then
       begin
         if (IntoMemory) then
          IntoDatabase := SQLMemMemoryDatabaseName
         else
          IntoDatabase := GetDatabaseName;
       end;
      RootAO.SetResultTable(IntoMemory,IntoTable,IntoDatabase);
     end;

{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('6 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStartTime(time14);
{$ENDIF}
    RootAO.Execute(IsRoot);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time14);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('7 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}

    // specify read-only result?
    if (IsRoot) then
     begin
      if (not FRequestLive) then
       ReadOnly := True
      else
       ReadOnly := TSQLMemDataSet(RootAO.ResultDataset).Handle.IsTemporaryTable;
      TSQLMemDataSet(RootAO.ResultDataset).Handle.ReadOnly := ReadOnly;
     end;
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('8 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}

    // select into table?
// commented in v.4.60
{
    if (RootAO.FIsAOTable and (IntoTable <> '')) then
     begin
      dest := nil;
      try
        dest:= TSQLMemTable.Create(nil);
        dest.TableName := IntoTable;
        dest.InMemory := IntoMemory or TSQLMemDataset(query).InMemory;
        if (dest.InMemory) then
          dest.DatabaseName := SQLMemMemoryDatabaseName
        else
         dest.DatabaseName := TSQLMemDataset(query).DatabaseName;
        if (not dest.ImportTable(RootAO.ResultDataset,log)) then
          raise ESQLMemException.Create(10403,ErrorLImportTableCannotCopyData,[log]);
      finally
       dest.Free;
      end;
     end;
}
  finally
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('9 TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStartTime(time15);
{$ENDIF}
   if (Assigned(RootAO)) then
    RootAO.UnlockTable;
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time15);
{$ENDIF}
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecSQL}
aaWriteToLog('< TSQLMemSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
  end;
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time3);
end;
{$ENDIF}
end;// ExecSQL


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// return true if the sub-query is correlated
//------------------------------------------------------------------------------
function TSQLMemSQLCursorCommand.PrepareSubQuery(bIn: Boolean): Boolean;
var
    OrderBySpecs:          array of TSQLMemSortSpecification;
    OrderBySpecsCount:     integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_PrepareSubQuery}
aaWriteToLog('> TSQLMemSQLCursorCommand.PrepareSubQuery. Self.ClassName = '+Self.ClassName);
try
{$ENDIF}
    if (RootAO <> nil) then
     RootAO.Free;
    RootAO := BuildAOTree(FDatabaseParams.Session,LParams);
    if (RootAO = nil) then
     raise ESQLMemException.Create(12424,ErrorLNilPointer);
    RootAO.SetupSubQuery;
//    if (RootAO.FilterExpr <> nil) then
//     TSQLMemExpression(RootAO.FilterExpr).AssignAO(RootAO);
    Result := RootAO.FindExternalFieldNodes;
    if (IntoTable <> '') then
     begin
  // commneted in 4.95
  //      if (not IntoMemory) then
      if (IntoDatabase = '') then
       begin
         if (IntoMemory) then
          IntoDatabase := SQLMemMemoryDatabaseName
         else
          IntoDatabase := GetDatabaseName;
       end;
      RootAO.SetResultTable(IntoMemory,IntoTable,IntoDatabase);
     end;
    if (bIn) then
    begin
      OrderBySpecsCount := 1;
      SetLength(OrderBySpecs,OrderBySpecsCount);
      try
        OrderBySpecs[0].ColumnNumber := 1;
        RootAO.SetOrderBy(OrderBySpecs,OrderBySpecsCount,'');
      finally
        OrderBySpecs := nil;
      end;
    end;
{ TODO : add setting index for subquery IN }
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_PrepareSubQuery}
aaWriteToLog('< TSQLMemSQLCursorCommand.PrepareSubQuery. Self.ClassName = '+Self.ClassName);
except
 on e: Exception do
 begin
   aaWriteToLog('Error in TSQLMemSQLCursorCommand.PrepareSubQuery. Self.ClassName = '+Self.ClassName+', Error: '+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // PrepareSubQuery


//------------------------------------------------------------------------------
// execute sub-query
//------------------------------------------------------------------------------
procedure TSQLMemSQLCursorCommand.ExecuteSubQuery;
begin
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecuteSubQuery}
aaWriteToLog('> TSQLMemSQLCursorCommand.ExecuteSubQuery. Self.ClassName = '+Self.ClassName);
try
{$ENDIF}
  if (RootAO = nil) then
   raise ESQLMemException.Create(12426,ErrorLNilPointer);
  RootAO.LockTable(False);
  try
    // calculate values of the external field nodes
    RootAO.SetExternalFieldValues;
    if (RootAO.IsMaterialized) then
     RootAO.RestartMaterialization := True;
    RootAO.Execute(True);
    if (RootAO.ResultDataset = nil) then
     raise ESQLMemException.Create(12427,ErrorLNilPointer);
  finally
    RootAO.UnlockTable;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemSQLCursorCommand_ExecuteSubQuery}
aaWriteToLog('< TSQLMemSQLCursorCommand.ExecuteSubQuery. Self.ClassName = '+Self.ClassName);
except
 on e: Exception do
 begin
   aaWriteToLog('Error in TSQLMemSQLCursorCommand.ExecuteSubQuery. Self.ClassName = '+Self.ClassName+', Error: '+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // ExecuteSubQuery
{$ENDIF}


//------------------------------------------------------------------------------
// get result cursor
//------------------------------------------------------------------------------
function TSQLMemSQLCursorCommand.GetResultCursor: TSQLMemCursor;
begin
  Result := TSQLMemDataSet(RootAO.ResultDataset).Handle;
end;//GetResultCursor


//------------------------------------------------------------------------------
// get result dataset
//------------------------------------------------------------------------------
function TSQLMemSQLCursorCommand.GetResultDataset: TDataset;
begin
 Result := RootAO.ResultDataset;
end;// GetResultDataset



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTableReference
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemTableReference.Create;
begin
  TableType := attTable;
  LeftTable := nil;
  RightTable := nil;
  SearchCondition := nil;
  UsingFields := nil;
  Params := nil;
  SubQuerySQL := '';
  TableName := '';
  Pseudonym := '';
  SystemTable := False;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemTableReference.Destroy;
begin
  if (LeftTable <> nil) then
    LeftTable.Free;
  if (RightTable <> nil) then
    RightTable.Free;
  if (UsingFields <> nil) then
    UsingFields.Free;
  if (SearchCondition <> nil) then
    SearchCondition.Free;
end;//Destroy


//------------------------------------------------------------------------------
// makes join (left and right node-table)
//------------------------------------------------------------------------------
procedure TSQLMemTableReference.MakeJoin(RightNode: TSQLMemTableReference; JType: TSQLMemJoinType;
                 IsNatural: Boolean; Fields: TSQLMemWideStringList;
                 OnCondition: TSQLMemExpression);
var
 LeftNode: TSQLMemTableReference;
begin
 // copy current node to left
 LeftNode := TSQLMemTableReference.Create;
 LeftNode.TableType := TableType;
 LeftNode.DatabaseName := DatabaseName;
 LeftNode.SessionName := SessionName;
 LeftNode.TableName := TableName;
 LeftNode.Pseudonym := Pseudonym;
 LeftNode.InMemory := InMemory;
 LeftNode.NaturalJoin := NaturalJoin;
 LeftNode.JoinType := JoinType;
 LeftNode.LeftTable := LeftTable;
 LeftNode.RightTable := RightTable;
 LeftNode.UsingFields := nil;
 LeftNode.SearchCondition := SearchCondition;
 // fixed in 5.02
 LeftNode.SubQuerySQL := SubQuerySQL;
 LeftNode.Params := Params;
 LeftNode.SystemTable := SystemTable;

 // set childs
 LeftTable := LeftNode;
 RightTable := RightNode;

 // set current data as join
 TableType := attJoinedTable;
 JoinType := JType;
 NaturalJoin := IsNatural;
 UsingFields := Fields;
 SearchCondition := OnCondition;
end; // MakeJoin


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemTableReference.Assign(Source: TSQLMemTableReference);
begin
  if (Source = nil) then
    raise ESQLMemException.Create(12189,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise ESQLMemException.Create(12190,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  TableType := Source.TableType;
  SessionName := Source.SessionName;
  DatabaseName := Source.DatabaseName;
  TableName := Source.TableName;
  SubQuerySQL := Source.SubQuerySQL;
  if (Params <> nil) then
   FreeAndNil(Params);
  if (Source.Params <> nil) then
   begin
    Params := TParams.Create();
    Params.Assign(Source.Params);
   end;
  Pseudonym := Source.Pseudonym;
  InMemory := Source.InMemory;
  NaturalJoin := Source.NaturalJoin;
  JoinType := Source.JoinType;
  if (LeftTable <> nil) then
   FreeAndNil(LeftTable);
  if (RightTable <> nil) then
   FreeAndNil(RightTable);
  if (Source.LeftTable <> nil) then
   begin
    LeftTable := TSQLMemTableReference.Create;
    LeftTable.Assign(Source.LeftTable);
   end;
  if (Source.RightTable <> nil) then
   begin
    RightTable := TSQLMemTableReference.Create;
    RightTable.Assign(Source.RightTable);
   end;
  if (Source.UsingFields = nil) then
   begin
    if (UsingFields <> nil) then
     FreeAndNil(UsingFields);
   end
  else
   begin
    if (UsingFields = nil) then
     UsingFields := TSQLMemWideStringList.Create;
    UsingFields.Assign(Source.UsingFields);
   end;
  if (SearchCondition <> nil) then
   FreeAndNil(SearchCondition);
  if (Source.SearchCondition <> nil) then
   begin
    SearchCondition := TSQLMemExpression.Create;
    SearchCondition.Assign(Source.SearchCondition);
   end;
  SystemTable := Source.SystemTable;
end; // Assign


//------------------------------------------------------------------------------
// update expression params in this node and all children
//------------------------------------------------------------------------------
procedure TSQLMemTableReference.UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TSQLMemBaseSession;
                  LParams:          TSQLMemSQLParams
                  );
begin
  if (LeftTable <> nil) then
   LeftTable.UpdateExpressionParams(LStoredFunction,LSession,LParams);
  if (RightTable <> nil) then
   RightTable.UpdateExpressionParams(LStoredFunction,LSession,LParams);
  if (SearchCondition <> nil) then
   begin
    SearchCondition.StoredFunction := LStoredFunction;
    SearchCondition.Session := LSession;
    SearchCondition.LocalParams := LParams;
    SearchCondition.UpdateExpressionParams;
   end;
  SessionName := LSession.SessionName;
  if (not InMemory) then
  begin
   InMemory := LSession.InMemory;
   DatabaseName := LSession.DatabaseName;
  end;
  if (DatabaseName = '') then
   DatabaseName := LSession.DatabaseName;
end; // UpdateExpressionParams




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLInsert
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// ParseValuesList
//------------------------------------------------------------------------------
procedure TSQLMemSQLInsert.ParseValuesList;
var Expr: TSQLMemExpression;
begin
  // '('?
  if Token.TokenType <> tktLeftParenthesis then
    Exit;

  // list...
  repeat
    if (not GetNextToken) then
      raise ESQLMemException.Create(30203, ErrorGUnexpectedEndOfCommand,
                                 [Token.LineNum, Token.ColumnNum]);

    Expr := FieldValues.AddCreated(FDatabaseParams.Session,nil);
    Expr.StoredFunction := LStoredFunction;
    Expr.Params := FDatabaseParams.Params;
    Expr.InMemory := GetInMemory;
    Expr.DatabaseName := GetDatabaseName;
    Expr.SessionName := GetSessionName;
    Expr.ParseForValueExpression(LLex);
    GetCurrentToken;
    if Expr.IsEmpty then
      raise ESQLMemException.Create(30357, ErrorGParseParameterError,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);
    if (Expr.Params <> nil) then
     If (Expr.Params.Count > 0) then
      Expr.ExtractAllParameterNodes(LParamExprNodes);
    //GetNextToken([tktComma, tktRightParenthesis], 02074);
  until Token.TokenType = tktRightParenthesis;
  // ')'
end;//ParseValuesList


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLInsert.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to FieldValues.Count-1 do
   begin
    TSQLMemExpression(FieldValues.Items[i]).StoredFunction := LStoredFunction;
    TSQLMemExpression(FieldValues.Items[i]).LocalParams := LParams;
    TSQLMemExpression(FieldValues.Items[i]).Session := FDatabaseParams.Session;
   end;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLInsert.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLInsert.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLInsert.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FieldNames.Assign(TSQLMemSQLInsert(Source).FieldNames);
  FieldValues.Assign(TSQLMemSQLInsert(Source).FieldValues);
  if (InternalSelecter <> nil) then
    FreeAndNil(InternalSelecter);
  if (TSQLMemSQLInsert(Source).InternalSelecter <> nil) then
   begin
    InternalSelecter := TSQLMemSQLUnion.Create(nil,FDatabaseParams,LStoredFunction);
    InternalSelecter.Assign(TSQLMemSQLInsert(Source).InternalSelecter);
   end;
  if (FTable <> nil) then
   FreeAndNil(FTable);
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLInsert.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  FieldNames := TSQLMemWideStringList.Create;
  FieldValues := TSQLMemExpressions.Create;
  InternalSelecter := nil;
  FTable := nil;
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemSQLInsert.Destroy;
var
  i: integer;
begin
  FieldNames.Free;
  FieldValues.Free;
  if (InternalSelecter <> nil) then
    InternalSelecter.Free;
  if (FTable <> nil) then
   begin
    FTable.Close;
    FTable.Free;
   end;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLInsert.Parse;
begin
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    LParamExprNodes := TSQLMemList.Create;
  if not GetCurrentToken then
    raise ESQLMemException.Create(30204, ErrorGBlankSqlCommand);

  if (not GetNextToken) then
    raise ESQLMemException.Create(30205, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  // INTO
  if not IsReservedWord(Token, rwINTO) then
    raise ESQLMemException.Create(30206, ErrorGOtherTokenExpected,
                         ['INTO', Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;                       
  // table name                       
  ParseTableNameToken;
  // '('?
  if Token.TokenType = tktLeftParenthesis then
    begin
      // list...
      repeat
        GetNextToken;
        if not (Token.TokenType in [tktString,tktQuotedString,
                                    tktBackQuotedString,
                                    tktBracketedString,tktReservedWord]) then
          raise ESQLMemException.Create(02156, ErrorGFieldNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);

        //GetNextToken(02073);
        FieldNames.Add(Token.Text);

        GetNextToken([tktComma, tktRightParenthesis],
                     30212, ErrorGRightParenthesisOrCommaExpected);
      until Token.TokenType = tktRightParenthesis;
      // ')'
      if (not GetNextToken) then
        raise ESQLMemException.Create(30213, ErrorGUnexpectedEndOfCommand,
                                   [Token.LineNum, Token.ColumnNum]);
    end;
  // 'VALUES'?
  if Token.ReservedWord = rwVALUES then
    begin
      GetNextToken([tktLeftParenthesis], 30214, ErrorGLeftParenthesisExpected);
      ParseValuesList;
    end
  else
    if Token.ReservedWord = rwSELECT then
// fixed in 4.95
      InternalSelecter := TSQLMemSQLUnion.Create(LLex,FDatabaseParams,LStoredFunction);
//      InternalSelecter := TSQLMemSQLSelect.Create(LLex, LQuery);
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemSQLInsert.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                );
var
   i:         Integer;
   ds:        TDataSet;
   s:         AnsiString;
   FieldNo:   Integer;
   Data:      TSQLMemVariant;
   RecCount:  Integer;
begin
{ TODO : VERSION 6 - REMOVE REOPENING THE TABLE in all cases, optimize copying fields }
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('> TSQLMemSQLInsert.ExecSQL. FTable = '+IntToHex(Integer(FTable),8));
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter2);
aaStartTime(time2);
try
{$ENDIF}
  RowsAffected := 0;
  if (FTable = nil) then
   begin
    FTable := CreateInternalSQLMemTable as TSQLMemTable;
    try
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('1 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
      TSQLMemTable(FTable).Open;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('2 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
    except
      try
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('3 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
       TSQLMemTable(FTable).Free;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('4 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
      except
      end;
      FTable := nil;
      raise;
    end;
   end;
  try
    if (InternalSelecter = nil) then
      begin
        try
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('5 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
            TSQLMemTable(FTable).Insert;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('6 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
);
{$ENDIF}
            for i:=0 to FieldValues.Count-1 do
              begin
                // Get Field No
                FieldNo := i;
                if (FieldNames.Count = FieldValues.Count) then
                 if (FieldNames.Count > 0) then
                  if (FieldNames[i] <> '') then
                   begin
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('7 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'Field name = '+FieldNames[i]
);
{$ENDIF}
                   FieldNo := TSQLMemTable(FTable).Fields.IndexOf(
                                TSQLMemTable(FTable).Fields.FieldByName(FieldNames[i]));
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('8 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'Field name = '+FieldNames[i]
+#13#10+'FieldNo = '+IntToStr(FieldNo)
);
{$ENDIF}
                   end;

                Data := TSQLMemExpression(FieldValues[i]).GetValue;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('9 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'Data.IsNull = '+BoolToStr(Data.IsNull,True)
+#13#10+'Data.DataType = '+IntToStr(Integer(Data.DataType))
);
{$ENDIF}
                if (Data <> nil) then
                 begin
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('10 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'Data.IsNull = '+BoolToStr(Data.IsNull,True)
+#13#10+'Data.DataType = '+IntToStr(Integer(Data.DataType))
);
{$ENDIF}
                  SetSQLMemVariantIntoField(Data, TSQLMemTable(FTable).Fields.Fields[FieldNo]);
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('11 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'Data.IsNull = '+BoolToStr(Data.IsNull,True)
+#13#10+'Data.DataType = '+IntToStr(Integer(Data.DataType))
);
{$ENDIF}
                 end
                else
                  raise ESQLMemException.Create(30356, ErrorGParameterValueUndefined,
                        [FieldNames[i], AftToStr(FieldTypeToSQLMemAdvFieldType(
                         TSQLMemTable(FTable).Fields.FieldByName(FieldNames[i]).DataType))]);
              end; // for fields
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('12 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
);
{$ENDIF}
              TSQLMemTable(FTable).Post;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('13 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
);
{$ENDIF}
            except
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('14 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
              TSQLMemTable(FTable).Cancel;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('15 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
);
{$ENDIF}
              raise;
            end;
        Inc(RowsAffected);
      end
    else
      begin
        InternalSelecter.FReopen := FReopen;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('16 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
);
{$ENDIF}
        InternalSelecter.ExecSQL(IsRoot, False, ReadOnly);
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('17 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
);
{$ENDIF}
        ds := InternalSelecter.GetResultDataset;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('18 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
);
{$ENDIF}
        RecCount := TSQLMemTable(FTable).RecordCount;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('19 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
+#13#10+'RecCount = '+IntToStr(RecCount)
);
{$ENDIF}
        // fixed in v.5.80 - fiedl map by numbers
        s := CopyDatasets(ds,FTable,True,tbopCopy,False,FieldNames);
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('19 TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'TSQLMemTable(FTable).RecordCount = '+IntToStr(TSQLMemTable(FTable).RecordCount)
+#13#10+'s: '+#13#10+s
);
{$ENDIF}
        if (s <> '') then
         raise ESQLMemException.Create(11350,ErrorLInsertSelectFailed,[TSQLMemTable(FTable).TableName,s]);
        RowsAffected := TSQLMemTable(FTable).RecordCount - RecCount;
      end; // insert from select
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('< TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected)
);
{$ENDIF}
  finally
//   if ((FTable <> nil) and (LParamExprNodes = nil)) then
{ TODO -oLeo :
to Version 5 - change it to cursor and make cache for such operations
However it should be compatible with exclusive operations on other
TSQLMemTable components like EmptyTable - cached cursors should be ignored }
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('<< TSQLMemSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TSQLMemTable(FTable).DatabaseName
+#13#10+'SessionName = '+TSQLMemTable(FTable).SessionName
+#13#10+'TableName = '+TSQLMemTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TSQLMemTable(FTable).InMemory,true)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected)
+#13#10+'FTable = '+IntToHex(Integer(FTable),8)
);
{$ENDIF}
   if (FTable <> nil) then
    begin
      TSQLMemTable(FTable).Close;
      TSQLMemTable(FTable).Free;
      FTable := nil;
{$IFDEF TSQLMemSQLInsert_ExecSQL}
aaWriteToLog('<<< TSQLMemSQLInsert.ExecSQL.'
+#13#10+'RowsAffected = '+IntToStr(RowsAffected)
);
{$ENDIF}
    end;
  end;
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time2);
end;
{$ENDIF}
end;//ExecSQL



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLUpdate
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLUpdate.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to FieldValues.Count-1 do
   begin
    TSQLMemExpression(FieldValues.Items[i]).StoredFunction := LStoredFunction;
    TSQLMemExpression(FieldValues.Items[i]).LocalParams := LParams;
    TSQLMemExpression(FieldValues.Items[i]).Session := FDatabaseParams.Session;
   end;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLUpdate.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLUpdate.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLUpdate.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FieldNames.Assign(TSQLMemSQLUpdate(Source).FieldNames);
  FieldValues.Assign(TSQLMemSQLUpdate(Source).FieldValues);
  if (InternalSelecter <> nil) then
    FreeAndNil(InternalSelecter);
  if (TSQLMemSQLUpdate(Source).InternalSelecter <> nil) then
   begin
    InternalSelecter := TSQLMemSQLSelect.Create(nil,FDatabaseParams,LStoredFunction);
    InternalSelecter.Assign(TSQLMemSQLUpdate(Source).InternalSelecter);
   end;
end; // Assign


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TSQLMemSQLUpdate.Clear;
begin
  FieldNames.Clear;
  FieldValues.Clear;
end; // Clear


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLUpdate.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  InternalSelecter := nil;
  FieldNames  := TSQLMemWideStringList.Create;
  FieldValues := TSQLMemExpressions.Create;
  TableName := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemSQLUpdate.Destroy;
begin
  if (InternalSelecter <> nil) then
    InternalSelecter.Free;
  if (FieldNames <> nil) then
    FreeAndNil(FieldNames);
  if (FieldValues <> nil) then
    FreeAndNil(FieldValues);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLUpdate.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                );
var
   i:           Integer;
   ds:          TDataSet;
   oldRecCount: Integer;
   values:      array of TSQLMemVariant;
   ConstsOnly:  Boolean;
   IsBlob:      Boolean;
   AdvFieldDef: TSQLMemAdvFieldDef;

 procedure UpdateConstsOnly;
 var i: Integer;
 begin
    SetLength(values,FieldValues.Count);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('> 20 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count));
{$ENDIF}
    for i:=0 to FieldValues.Count-1 do
     begin
      values[i] := TSQLMemVariant.Create;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('21 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
      values[i].Assign(TSQLMemExpression(FieldValues[i]).GetValue,True);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('22 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
//      TSQLMemExpression(FieldValues[i]).Free;
     end;
    try
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('23 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count));
{$ENDIF}
      oldRecCount := ds.RecordCount;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('24 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount));
{$ENDIF}
      TSQLMemTable(ds).UpdateVisibleRecords(FieldNames,values);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('25 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount));
{$ENDIF}
      Inc(RowsAffected,oldRecCount);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('26 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
    finally
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('27 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
      for i:=0 to FieldValues.Count-1 do
       values[i].Free;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('28 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
      values := nil;
    end;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('< 29 TSQLMemSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
 end; // UpdateConstsOnly

 procedure UpdateGeneral;
 var i: Integer;
 begin
    ds.First;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('> 30 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'ds.Eof = '+BoolToStr(ds.Eof,True)
);
{$ENDIF}
    while (not ds.Eof) and (ds.RecordCount > 0) do
      begin
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('31 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'ds.Eof = '+BoolToStr(ds.Eof,True)
);
{$ENDIF}
        ds.Edit;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('32 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'ds.Eof = '+BoolToStr(ds.Eof,True)
);
{$ENDIF}
        for i:=0 to FieldNames.Count-1 do
         begin
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('32 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'i = '+IntToStr(i)
);
{$ENDIF}
          SetSQLMemVariantIntoField(
                                  TSQLMemExpression(FieldValues[i]).GetValue,
                                  ds.Fields.FieldByName(FieldNames[i])
                                );
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('33 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'i = '+IntToStr(i)
);
{$ENDIF}
         end;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('34 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral');
{$ENDIF}
        oldRecCount := ds.RecordCount;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('35 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
);
{$ENDIF}
        ds.post;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('36 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
);
{$ENDIF}
        Inc(RowsAffected);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('37 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
        if (oldRecCount = ds.RecordCount) then
          ds.Next;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('38 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral');
{$ENDIF}
      end;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('< 39 TSQLMemSQLUpdate.ExecSQL. UpdateGeneral');
{$ENDIF}
 end; // UpdateGeneral


begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter4);
aaStartTime(time4);
try
{$ENDIF}
  RowsAffected := 0;
  ConstsOnly := True;
  ReadOnly := False;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('> TSQLMemSQLUpdate.ExecSQL - FReopen = '+BoolToStr(FReopen,True));
{$ENDIF}
 try
  InternalSelecter.FReopen := FReopen;
  InternalSelecter.LockTablesInWriteMode := True;
  InternalSelecter.ExecSQL(IsRoot, True, ReadOnly);
  if (ReadOnly) then
   raise ESQLMemException.Create(12431,ErrorLReadOnlyDatasetReturned,[GetReservedWord(rwUPDATE),TableName]);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('1 TSQLMemSQLUpdate.ExecSQL');
{$ENDIF}
  try
    if ((LParamExprNodes <> nil) and (not FReopen)) then
     begin
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('2 TSQLMemSQLUpdate.ExecSQL');
{$ENDIF}
      InternalSelecter.RootAO.MoveParamNodes(LParamExprNodes);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('3 TSQLMemSQLUpdate.ExecSQL');
{$ENDIF}
     end;
    ds := InternalSelecter.GetResultDataset;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('4 TSQLMemSQLUpdate.ExecSQL');
{$ENDIF}
    if (TSQLMemDataset(ds).IsBeforeUpdateRecordAssigned or
        TSQLMemDataset(ds).IsAfterUpdateRecordAssigned) then
     ConstsOnly := False;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('6 TSQLMemSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count));
{$ENDIF}
    for i := 0 to FieldValues.Count-1 do
     begin
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('7 TSQLMemSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
{$IFDEF CORRELATED_SUBQUERIES}
      if (TSQLMemExpression(FieldValues[i]).CorrelatedSubQueriesExists) then
       TSQLMemExpression(FieldValues[i]).AssignAO(InternalSelecter.RootAO)
      else
       TSQLMemExpression(FieldValues[i]).AssignCursor(InternalSelecter.GetResultCursor);
{$ELSE}
      TSQLMemExpression(FieldValues[i]).AssignCursor(InternalSelecter.GetResultCursor);
{$ENDIF}
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('8 TSQLMemSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
      if (ConstsOnly) then
       begin
        if (not TSQLMemExpression(FieldValues[i]).IsConst) then
         begin
          ConstsOnly := False;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('9 TSQLMemSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
         end
        else
         begin
          // modified in v.4.70 - to prevent crash in TSQLMemCursor.SetFieldValue if not NULL
          AdvFieldDef := TSQLMemDataSet(ds).AdvFieldDefs.Find(FieldNames[i]);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('10 TSQLMemSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
          if (AdvFieldDef = nil) then
           raise ESQLMemException.Create(11590,ErrorLCannotFindFieldInTable,[FieldNames[i],TSQLMemTable(ds).TableName]);
          IsBlob := IsBLOBFieldType(AdvFieldDef.DataType);
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('11 TSQLMemSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i)
+#13#10+'IsBlob = '+BoolToStr(IsBlob,True));
{$ENDIF}
          if (IsBlob) then
            if (not TSQLMemExpression(FieldValues[i]).IsNullConst) then
               ConstsOnly := False;
         end;
       end;
     end;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('12 TSQLMemSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
    if (ConstsOnly) then
     UpdateConstsOnly
    else
     UpdateGeneral;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('13 TSQLMemSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
  finally
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('15 TSQLMemSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
     if ((InternalSelecter <> nil) and (LParamExprNodes = nil)) then
      begin
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('16 TSQLMemSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
       InternalSelecter.Free;
       InternalSelecter := nil;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('17 TSQLMemSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
      end;
  end;
 finally
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('< TSQLMemSQLUpdate.ExecSQL - FReopen = '+BoolToStr(FReopen,True));
{$ENDIF}
  if (LParamExprNodes = nil) then
   Clear;
{$IFDEF TSQLMemSQLUpdate_ExecSQL}
aaWriteToLog('<< TSQLMemSQLUpdate.ExecSQL - FReopen = '+BoolToStr(FReopen,True));
{$ENDIF}
 end;
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time4);
end;
{$ENDIF}
end;//ExecSQL


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLUpdate.Parse;
var
  oldPos, newPos, i,j,n: Integer;
  oldLen:                Integer;
  Expr:                  TSQLMemExpression;
  bDatabaseName:         Boolean;
begin
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    LParamExprNodes := TSQLMemList.Create;
  if not GetCurrentToken then
    raise ESQLMemException.Create(30216, ErrorGBlankSqlCommand);

  GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBackQuotedString,tktBracketedString],
               30217, ErrorGTableNameExpected);
  ParseTableNameToken;
  bDatabaseName := IntoMemory and (DatabaseName <> '') and
                  (DatabaseName <> SQLMemMemoryDatabaseName);
{
  // MEMORY
  if IsReservedWord(Token, rwMEMORY) then
   begin
    IntoMemory := true;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBackQuotedString,tktBracketedString],
                 30218, ErrorGTableNameExpected);
   end;
  // table_name
  TableName := Token.Text;

  // get next token
  GetNextToken;

  // PASSWORD ?
  if IsReservedWord(Token, rwPASSWORD) then
    begin
      GetNextToken([tktQuotedString],
                   30219, ErrorGQuotedPasswordDataExpected);
      Password := Token.Text;
      GetNextToken;
    end;
}
  // SET
  if not IsReservedWord(Token, rwSET) then
    raise ESQLMemException.Create(30220, ErrorGOtherTokenExpected,
             ['SET', Token.Text, Token.LineNum, Token.ColumnNum]);

  GetNextToken;

  // field_name = value, ...
  repeat
    // Field_name
    FieldNames.Add(Token.Text);
    GetNextToken;
    if Token.Text <> '='then
      raise ESQLMemException.Create(30221, ErrorGOtherTokenExpected,
                   ['=', Token.Text, Token.LineNum, Token.ColumnNum]);
    GetNextToken;

    Expr := FieldValues.AddCreated(FDatabaseParams.Session,nil);
    Expr.StoredFunction := LStoredFunction;
    Expr.Params := FDatabaseParams.Params;
    Expr.InMemory := GetInMemory;
    Expr.DatabaseName := GetDatabaseName;
    Expr.SessionName := GetSessionName;
    Expr.ParseForValueExpression(LLex);
    if (Expr.Params <> nil) then
     if (Expr.Params.Count > 0) then
      Expr.ExtractAllParameterNodes(LParamExprNodes);

    if not GetCurrentToken then
      // end of command
      break
    else
      begin
        // ','or 'WHERE'
        if Token.ReservedWord = rwWHERE then
          break;

        if Token.TokenType <> tktComma then
            raise ESQLMemException.Create(30222, ErrorGOtherTokenExpected,
                     [',', Token.Text, Token.LineNum, Token.ColumnNum]);

        // get next field_name
        if (not GetNextToken) then
            raise ESQLMemException.Create(30223, ErrorGUnexpectedEndOfCommand,
                                       [Token.LineNum, Token.ColumnNum]);
      end;
  until false;

 // sql: select f1, f2 from table_name where .......
 //      update table_name set a=b, c=d where .......
  with  LLex.CurrentCommand do
    begin
      // Free Params
      for i:=0 to CurrentTokenNo-1 do
        if Tokens[i].ParamValue <> nil then
          begin
            Tokens[i].ParamValue.Free;
            Tokens[i].ParamValue := nil;
          end;

      oldPos := CurrentTokenNo;
      newPos := 4; // select * from tablename where
      // MEMORY
      if IntoMemory then
        Inc(newPos);
      // DATABASENAME.
      if bDatabaseName then
        Inc(newPos,2);
      // TableAlias
      if Length(TableAlias) > 0 then
        Inc(newPos);
      // fixed in v.6.00
      OldLen := length(Tokens);
      n := OldLen-(oldPos-newPos);
      //  Shift Tokens (where clause) ?
      if IsReservedWord(Token, rwWHERE) then
      begin
       // move WHERE
       if (oldLen < n) then
       begin
        // extend tokens
        LLex.SetNumTokensInCurrentCommand(n);
        for i:=OldLen-1 downto oldPos do
          Tokens[newPos+i-oldPos] := Tokens[i];
       end
       else
       begin
        // shrink tokens
        for i:=oldPos to OldLen-1 do
          Tokens[newPos+i-oldPos] := Tokens[i];
        LLex.SetNumTokensInCurrentCommand(n);
       end;
      end
      else
       LLex.SetNumTokensInCurrentCommand(n);
// changed for compatibility with Delphi 2010
{
      SetLength(Tokens, n);
      NumTokens := length(Tokens);
      CurrentTokenNo:=0;
}

      Tokens[0].TokenType := tktReservedWord;
      Tokens[0].ReservedWord := rwSELECT;
      Tokens[0].Text := 'select';

      Tokens[1].TokenType := tktNone;
      Tokens[1].ReservedWord := rwNone;
      Tokens[1].Text:=Asterisk;

      Tokens[2].TokenType := tktReservedWord;
      Tokens[2].ReservedWord := rwFROM;
      Tokens[2].Text:='from';

      j := 3;
      if IntoMemory then
       begin
        Tokens[3].TokenType := tktReservedWord;
        Tokens[3].ReservedWord := rwMEMORY;
        Tokens[3].Text := SQLMemMemoryDatabaseName;
        inc(j);
       end;
      if (bDatabaseName) then
       begin
        Tokens[j].TokenType := tktString;
        Tokens[j].ReservedWord := rwNone;
        Tokens[j].Text := DatabaseName;
        inc(j);
        Tokens[j].TokenType := tktDot;
        Tokens[j].ReservedWord := rwNone;
        inc(j);
       end;
      Tokens[j].TokenType := tktString;
      Tokens[j].ReservedWord := rwNone;
      Tokens[j].Text:=TableName;
      // TableAlias
      if Length(TableAlias) > 0 then
      begin
        inc(j);
        Tokens[j].TokenType := tktString;
        Tokens[j].ReservedWord := rwNone;
        Tokens[j].Text:=TableAlias;
      end;

      InternalSelecter := TSQLMemSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction);
    end;
end;//Parse



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLDelete
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLDelete.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLDelete.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLDelete.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FullDelete := TSQLMemSQLDelete(Source).FullDelete;
  if (InternalSelecter <> nil) then
    FreeAndNil(InternalSelecter);
  if (TSQLMemSQLDelete(Source).InternalSelecter <> nil) then
   begin
    InternalSelecter := TSQLMemSQLSelect.Create(nil,FDatabaseParams,LStoredFunction);
    InternalSelecter.Assign(TSQLMemSQLDelete(Source).InternalSelecter);
   end;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLDelete.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  InternalSelecter := nil;
  FullDelete := false;
  TableName := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemSQLDelete.Destroy;
begin
  if (InternalSelecter <> nil) then
   InternalSelecter.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Execute SQL statement
//------------------------------------------------------------------------------
procedure TSQLMemSQLDelete.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                );
var
  ds:       TDataSet;

  procedure FastDelete;
  begin
   RowsAffected := ds.RecordCount;
   TSQLMemDataSet(ds).DeleteVisibleRecords;
  end;

  procedure GeneralDelete;
  begin
    RowsAffected := 0;
//    TSQLMemDataSet(ds).Handle.LockTableForRead;
//    try
      ds.First;
      while not ds.Eof do
        begin
          ds.Delete;
          Inc(RowsAffected);
        end;
//    finally
//     TSQLMemDataSet(ds).Handle.UnlockTableForRead;
//    end;
  end;

begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter5);
aaStartTime(time5);
try
{$ENDIF}
  InternalSelecter.FReopen := FReopen;
  InternalSelecter.LockTablesInWriteMode := True;
  InternalSelecter.ExecSQL(IsRoot, True, ReadOnly);
  try
   if ((LParamExprNodes <> nil) and (not FReopen)) then
    InternalSelecter.RootAO.MoveParamNodes(LParamExprNodes);
   ds := InternalSelecter.GetResultDataset;
   if (TSQLMemDataset(ds).IsBeforeDeleteRecordAssigned or
       TSQLMemDataset(ds).IsAfterDeleteRecordAssigned) then
    GeneralDelete
   else
    FastDelete;
  finally
   if ((InternalSelecter <> nil) and (LParamExprNodes = nil)) then
    begin
     InternalSelecter.Free;
     InternalSelecter := nil;
    end;
  end;
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time5);
end;
{$ENDIF}
end;//ExecSQL


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLDelete.Parse;
var
   i,n: integer;
begin
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    LParamExprNodes := TSQLMemList.Create;
  // CONVERT DELETE TO SELECT
  with  LLex.CurrentCommand do
    begin
// changed for compatibility with Delphi 2010
{
      SetLength(Tokens, length(Tokens)+1);
      inc(NumTokens);
}
      n := length(Tokens)+1;
      LLex.SetNumTokensInCurrentCommand(n);

      for i:=length(Tokens)-1 downto 1 do
        begin
          Tokens[i] := Tokens[i-1];
        end;
      Tokens[0].TokenType := tktReservedWord;
      Tokens[0].ReservedWord := rwSELECT;
      Tokens[0].Text := 'select';
      Tokens[1].TokenType := tktNone;
      Tokens[1].ReservedWord := rwNone;
      Tokens[1].Text := Asterisk;
    end;
  if not GetCurrentToken then
    raise ESQLMemException.Create(30224, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  InternalSelecter := TSQLMemSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction);

end;//Parse



////////////////////////////////////////////////////////////////////////////////
//
// TSQLFieldDef
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLFieldDef.Create;
begin
  FieldName := '';
  
  newFieldType := False;
  FieldType := aftUnknown;

  newLength := False;
  Length := 0;

  newRequired := False;

  DefaultValue := TSQLMemVariant.Create;
  MinValue := TSQLMemVariant.Create;
  MaxValue := TSQLMemVariant.Create;

  // Blob settings
  newBlobblocksize := False;
  newBlobCompressionAlgorithm := False;
  newBlobCompressionMode := False;

  //Autoinc
  newAutoincIncrement := False;
  newAutoincLastValue := False;
  newAutoincMinValue := False;
  newAutoincMaxValue := False;
  newAutoincCycled := False;

  // Default Value
  newDefaultValue := False;
  // Min
  newMinValue := False;
  // Max
  newMaxValue := False;

  // PK
  newPrimaryKey := False;
  // Unique
  newUnique := False;

end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLFieldDef.Destroy;
begin
  DefaultValue.Free;
  MinValue.Free;
  MaxValue.Free;
end;//Destroy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLFieldDef.Assign(Source: TSQLFieldDef);
begin
  if (Source = nil) then
    raise ESQLMemException.Create(12187,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise ESQLMemException.Create(12188,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  FieldName := Source.FieldName;
  newFieldType := Source.newFieldType;
  FieldType := Source.FieldType;
  newLength := Source.newLength;
  Length := Source.Length;
  newRequired := Source.newRequired;
  Required := Source.Required;
  newAutoincIncrement := Source.newAutoincIncrement;
  AutoincIncrement := Source.AutoincIncrement;
  newAutoincLastValue := Source.newAutoincLastValue;
  AutoincLastValue := Source.AutoincLastValue;
  newAutoincMinValue := Source.newAutoincMinValue;
  AutoincMinValue := Source.AutoincMinValue;
  newAutoincMaxValue := Source.newAutoincMaxValue;
  AutoincMaxValue := Source.AutoincMaxValue;
  newAutoincCycled := Source.newAutoincCycled;
  AutoincCycled := Source.AutoincCycled;
  newBlobBlockSize := Source.newBlobBlockSize;
  BlobBlockSize := Source.BlobBlockSize;
  newBlobCompressionAlgorithm := Source.newBlobCompressionAlgorithm;
  BlobCompressionAlgorithm := Source.BlobCompressionAlgorithm;
  newBlobCompressionMode := Source.newBlobCompressionMode;
  BlobCompressionMode := Source.BlobCompressionMode;
  newDefaultValue := Source.newDefaultValue;
  DefaultValue.Assign(Source.DefaultValue,True);
  newMinValue := Source.newMinValue;
  MinValue.Assign(Source.MinValue,True);
  newMaxValue := Source.newMaxValue;
  MaxValue.Assign(Source.MaxValue,True);
  newPrimaryKey := Source.newPrimaryKey;
  PrimaryKey := Source.PrimaryKey;
  newUnique := Source.newUnique;
  Unique := Source.Unique;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLFieldDefs
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Get Def
//------------------------------------------------------------------------------
function TSQLFieldDefs.GetDef(Index: Integer): TSQLFieldDef;
begin
  Result := TSQLFieldDef(List[Index]);
end;//GetDef


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLFieldDefs.Create;
begin
  List := TList.Create;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLFieldDefs.Destroy;
begin
  try
    Clear;
  except
  end;
  List.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TSQLFieldDefs.Clear;
var i: Integer;
begin
  for i:=0 to List.Count-1 do
   try
    Items[i].Free;
   except
   end;
  List.Clear;
end; // Clear


//------------------------------------------------------------------------------
// Create SQLFieldDef and add it to List
//------------------------------------------------------------------------------
function TSQLFieldDefs.AddCreated: TSQLFieldDef;
begin
  Result := TSQLFieldDef.Create;
  List.Add(Result);
end;//AddCreated


//------------------------------------------------------------------------------
// Get Count
//------------------------------------------------------------------------------
function TSQLFieldDefs.GetCount: Integer;
begin
  Result := List.Count;
end;//GetCount


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLFieldDefs.Assign(Source: TSQLFieldDefs);
var i: Integer;
begin
  Clear;
  for i := 0 to Source.Count-1 do
    AddCreated.Assign(Source.Items[i]);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLTableManipulation
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// table element list
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.ParseTableElementList;
var
  FieldDef: TSQLFieldDef;
  bFirst:   Boolean;
begin
  if ((not bLeftParethesis) and (Token.TokenType <> tktLeftParenthesis)) then
    raise ESQLMemException.Create(30226, ErrorGOtherTokenExpected,
            ['(', Token.Text, Token.LineNum, Token.ColumnNum]);

  bFirst := True;
  // Columns Loop
  repeat
    // end of create table sql ')'?
    if not LLex.GetCurrentToken(Token) then
      Break;
    if (Token.TokenType = tktRightParenthesis) then
     begin
      GetNextToken;
      break;
     end;
    if (not (bFirst and bLeftParethesis)) then
     GetNextToken([tktString, tktQuotedString, tktBackQuotedString,
                  tktBracketedString, tktReservedWord],
                 30227, ErrorGFieldNameExpected);
    bFirst := false;
    // end of column list?
{    if IsReservedWord(Token, rwPASSWORD) then
     begin
      ParsePassword;
      continue;
     end else
    if IsReservedWord(Token, rwBLOB_COMPRESSION_LEVEL) then
     begin
      ParseBlobCompressionLevel;
      continue;
     end else
    if IsReservedWord(Token, rwBLOB_BLOCK_SIZE) then
     begin
      ParseBlobBlockSize;
      continue;
     end else
}
    if ParsePrimaryKey then continue;
    if ParseForeignKey then continue;

    // Field Params

    FieldDef := SQLFieldDefs.AddCreated;


    // column name
    FieldDef.FieldName := Token.Text;

    GetNextToken([tktString, tktBracketedString, tktBackQuotedString, tktReservedWord],
                 30228, ErrorGFieldTypeExpected);


    // Fill Column Type
    FillColumnType(FieldDef);

    // until ','or ')'or 'any_word'after FIELDNAME FIELDTYPE ...
    while not (Token.TokenType in [tktComma,tktRightParenthesis]) do
     begin

      // NULL or NOT NULL
      if Token.ReservedWord in [rwNOT,rwNULL,rwCONSTRAINT] then
        // Fill Column Required value
        ParseColumnRequired(FieldDef)
      else

      // BlobBlockSize
      if IsReservedWord(Token, rwBLOBBLOCKSIZE) then
       begin
        FieldDef.newBlobBlockSize := true;
        FieldDef.BlobBlockSize := ParseInteger;
       end
      else

      // BlobCompressionMode
      if IsReservedWord(Token, rwBLOBCOMPRESSIONMODE) then
       begin
        FieldDef.newBlobCompressionMode := true;
        FieldDef.BlobCompressionMode := ParseInteger;
       end
      else

      // BlobCompressionAlgorithm
      if IsReservedWord(Token, rwBLOBCOMPRESSIONALGORITHM) then
       begin
        // {NONE | ZLIB | BZIP | PPM}
        GetNextToken;
        FieldDef.BlobCompressionAlgorithm := GetCompressionAlgorithm(Token.Text);
        FieldDef.newBlobCompressionAlgorithm := true;
       end
      // DEFAULT
      else if ParseDefaultValue(FieldDef) then Continue
      // MINVALUE
      else if ParseMinValue(FieldDef) then Continue
      // MAXVALUE
      else if ParseMaxValue(FieldDef) then Continue
      // PRIMARY KEY
      else if ParseFieldPrimaryKey(FieldDef) then Continue
      // UNIQUE
      else if ParseFieldUnique(FieldDef) then Continue;


      GetNextToken([tktComma, tktRightParenthesis,
                    tktString, tktQuotedString, tktBracketedString,
                    tktBackQuotedString,
                    tktReservedWord],
                    30229, ErrorGRightParenthesisOrCommaExpected);


     end;//while
  until False;//Columns Loop
end;//ParseTableElementList


//------------------------------------------------------------------------------
// parse comment
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseComment:Boolean;
begin
  Result := False;
  if (IsReservedWord(Token,rwCOMMENT)) then
   begin
    Result := True;
    GetNextToken([tktString, tktQuotedString, tktBackQuotedString,
                 tktBracketedString, tktReservedWord],
                11963, ErrorLCommentExpected);
    if (Token.TokenType = tktReservedWord) then
     begin
      if (Token.ReservedWord = rwNULL) then
       FComment := ''
      else
       FComment := Token.Text;
     end
    else
     FComment := Token.Text;
    GetNextToken;
   end;
end; // ParseComment


//------------------------------------------------------------------------------
// Fill table column type into Structure
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.FillColumnType(var FieldDef: TSQLFieldDef);
var s1,s2: Int64;
begin
  // column type
  if (UpperCase(AnsiString(Token.Text)) = SQLMem_GUID) then
  begin
   FieldDef.FieldType := aftChar;
   FieldDef.newFieldType := True;
   FieldDef.Length := SQLMem_GUID_LENGTH;
   FieldDef.newLength := True;
   GetNextToken;
  end // guid
  else
  if (Token.ReservedWord = rwDECIMAL) or (Token.ReservedWord = rwNUMERIC) then
  begin
   GetNextToken;
   if (Token.TokenType = tktLeftParenthesis) then
   begin
     GetNextToken;
     if (Token.TokenType <> tktInt) then
      raise ESQLMemException.Create(12517, ErrorLSizeExpected,
                   [Token.Text, Token.LineNum, Token.ColumnNum]);
     s1 := StrToInt64Def(token.Text,0);
     s2 := 0;
     GetNextToken;
     if (Token.TokenType <> tktComma) and (Token.TokenType <> tktRightParenthesis) then
      raise ESQLMemException.Create(12518, ErrorGOtherTokenExpected,
        [', or )', Token.Text,Token.LineNum,Token.ColumnNum]);
     if (Token.TokenType = tktComma) then
     begin
      GetNextToken;
      if (Token.TokenType <> tktInt) then
        raise ESQLMemException.Create(12519, ErrorLSizeExpected,
                     [Token.Text, Token.LineNum, Token.ColumnNum]);
      s2 := StrToInt64Def(token.Text,0);
      GetNextToken;
     if (Token.TokenType <> tktRightParenthesis) then
      raise ESQLMemException.Create(12520, ErrorGRightParenthesisExpected,
        [Token.Text,Token.LineNum,Token.ColumnNum]);
     end;
     GetNextToken;
     if (s2 > 0) then
     begin
       FieldDef.FieldType := aftExtended;
       FieldDef.newFieldType := True;
     end
     else
     begin
       if (s1 <= 2) then
         FieldDef.FieldType := aftShortint
       else
       if (s1 <= 4) then
         FieldDef.FieldType := aftSmallint
       else
       if (s1 <= 9) then
         FieldDef.FieldType := aftInteger
       else
         FieldDef.FieldType := aftLargeint;
       FieldDef.newFieldType := True;
     end;
   end
   else
   begin
     FieldDef.FieldType := aftInteger;
     FieldDef.newFieldType := True;
   end;
   FieldDef.Length := 0;
   FieldDef.newLength := True;
  end // NUMERIC or DECIMAL
  else
  begin
    FieldDef.FieldType := GetFieldType(Token.Text);
    FieldDef.newFieldType := True;

    // Unknown type ?
    if FieldDef.FieldType = aftUnknown then
      raise ESQLMemException.Create(30232, ErrorGUnknownFieldType,
                   [Token.Text, Token.LineNum, Token.ColumnNum]);

    // sizeble type ? ex: AnsiString(255)
    if (IsStringFieldType(FieldDef.FieldType) or
        IsBytesFieldType(FieldDef.FieldType)) then
      begin
       // '('
       GetNextToken([tktLeftParenthesis],
                    30233, ErrorGLeftParenthesisExpected);
       // Int
       GetNextToken([tktInt], 30235, ErrorGDecimalConstantExpected);

       FieldDef.Length := StrToInt(Token.Text);
       FieldDef.newLength := True;

       // ')'
       GetNextToken([tktRightParenthesis],
                    30236, ErrorGRightParenthesisOrCommaExpected);
      end
    else
      FieldDef.Length := 0;

    if IsAutoincFieldType(FieldDef.FieldType) then
     if (GetNextToken) then
      // '('
      if Token.TokenType = tktLeftParenthesis then
       begin
        repeat
         if (not GetNextToken) then
          raise ESQLMemException.Create(30290, ErrorGUnexpectedEndOfCommand,
                                    [Token.LineNum, Token.ColumnNum]);
         // ')'
         if (Token.TokenType = tktRightParenthesis) then
           break;

         // ','
         if (Token.TokenType = tktComma) then
           GetNextToken;


         case Token.ReservedWord of
           rwINCREMENT:
             begin
               FieldDef.AutoincIncrement := ParseInteger;
               FieldDef.newAutoincIncrement := True;
             end;
           rwINITIALVALUE:
             begin
               FieldDef.AutoincLastValue := ParseInteger;
               FieldDef.newAutoincLastValue := True;
             end;
           rwMINVALUE:
             begin
               FieldDef.AutoincMinValue := ParseInteger;
               FieldDef.newAutoincMinValue := True;
             end;
           rwMAXVALUE:
             begin
               FieldDef.AutoincMaxValue := ParseInteger;
               FieldDef.newAutoincMaxValue := True;
             end;
           rwCYCLED:
             begin
               FieldDef.AutoincCycled := True;
               FieldDef.newAutoincCycled := True;
             end;
           rwNOMINVALUE:
             begin
               FieldDef.AutoincMinValue := 0;//Low(Int64);
               FieldDef.newAutoincMinValue := True;
             end;
           rwNOMAXVALUE:
             begin
               FieldDef.AutoincMaxValue := High(Int64);
               FieldDef.newAutoincMaxValue := True;
             end;
           rwNOCYCLED:
             begin
               FieldDef.AutoincCycled := False;
               FieldDef.newAutoincCycled := True;
             end;
           else
             begin
               if (FieldDef.FieldType = aftAutoinc) then
                begin
                 FieldDef.FieldType := GetFieldType(Token.Text);
                 // Convert to Autoinc type
                 case FieldDef.FieldType of
                  aftShortint:  FieldDef.FieldType := aftAutoIncShortint;
                  aftSmallint:  FieldDef.FieldType := aftAutoIncSmallint;
                  aftInteger:   FieldDef.FieldType := aftAutoInc;
                  aftLargeint:  FieldDef.FieldType := aftAutoIncLargeint;
                  aftByte:      FieldDef.FieldType := aftAutoIncByte;
                  aftWord:      FieldDef.FieldType := aftAutoIncWord;
                  aftCardinal:  FieldDef.FieldType := aftAutoIncCardinal;

                  aftAutoInc,   // check for correct types
                  aftAutoIncShortint,
                  aftAutoIncSmallint,
                  aftAutoIncInteger,
                  aftAutoIncLargeint,
                  aftAutoIncByte,
                  aftAutoIncWord,
                  aftAutoIncCardinal: ;
                  else
                    raise ESQLMemException.Create(30295, ErrorGUnsupportedAutoincDataType,
                                    [Token.Text, Token.LineNum, Token.ColumnNum]);
                 end;//case

                 if FieldDef.FieldType = aftUnknown then
                  begin
                   FieldDef.FieldType := aftAutoinc;
                   raise ESQLMemException.Create(30293, ErrorGUnexpectedToken,
                                    [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                end
               else
                raise ESQLMemException.Create(30294, ErrorGUnexpectedToken,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);

             end;//if
         end;// case

        until False;
        GetNextToken;
       end
      else
     else
    else
     GetNextToken;
  end;
end;//FillColumnType


//------------------------------------------------------------------------------
// Fill column required value into Structure
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.ParseColumnRequired(var FieldDef: TSQLFieldDef);
var SavedTokenNo: Integer;
begin
  if (Token.ReservedWord = rwCONSTRAINT) then
  begin
   SavedTokenNo := LLex.GetCurrentTokenNo;
   if (GetNextToken) then
    if (Token.ReservedWord <> rwNOT) and (Token.ReservedWord <> rwNULL) then
     // skip constraint name
     GetNextToken;
  end
  else
   SavedTokenNo := -1;
  if IsReservedWord(Token, rwNOT) then
    begin
      GetNextToken([tktReservedWord], 30237, ErrorGUnexpectedEndOfCommand);
      // NOT NULL
      if IsReservedWord(Token, rwNULL) then
        begin
          FieldDef.newRequired := True;
          FieldDef.Required := True;
        end
      else
        raise ESQLMemException.Create(02011, ErrorGNullKeywordExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);
    end
  else
    // NULL
    if IsReservedWord(Token, rwNULL) then
      begin
        FieldDef.newRequired := True;
        FieldDef.Required := False;
      end;
  // if constraint and not parsed then restore position    
  if (SavedTokenNo >= 0) and (not FieldDef.newRequired) then
   LLex.SetCurrentTokenNo(SavedTokenNo,Token);
end;//ParseColumnRequared


//------------------------------------------------------------------------------
// Fill BlobBlockSize value into Structure
//------------------------------------------------------------------------------
//procedure TSQLMemDDLTableManipulation.FillBlobBlockSize(var FieldDef: TSQLFieldDef);
//begin
//  GetNextToken([tktInt], 30296, ErrorGIntegerExpected);
//  FieldDef.newBlobBlockSize := True;
//  FieldDef.BlobBlockSize := ParseInteger;
//end;//FillBlobBlockSize


//------------------------------------------------------------------------------
// parse DEFAULT {const | NULL}
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseDefaultValue(var FieldDef:TSQLFieldDef): Boolean;
var expr: TSQLMemExpression;
begin
  Result := False;
  if (Token.ReservedWord = rwDEFAULT) then
    begin
      GetNextToken([], 30297, ErrorGUnexpectedEndOfCommand);

      if FieldDef.newDefaultValue then
        raise ESQLMemException.Create(30299, ErrorGDefaultValueReDeclared, [FieldDef.FieldName]);

      // Set Value
      FieldDef.newDefaultValue := True;
      if IsReservedWord(Token, rwNULL) then
       begin
        // DEFAULT = NULL ?
        FieldDef.DefaultValue.SetNull;
        GetNextToken;
       end
      else
        begin
          expr := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
          try
            expr.CaseInsensitive := FDatabaseParams.CaseInsensitive;
            expr.ParseForValueExpression(LLex);
            FieldDef.DefaultValue.Assign(expr.GetValue(True));
            FieldDef.DefaultValue.Cast(AdvancedFieldTypeToBaseFieldType(FieldDef.FieldType));
          finally
            LLex.GetCurrentToken(Token);
            expr.Free;
          end;
        end;
      Result := True;
    end;
end;//ParseDefaultValue


//------------------------------------------------------------------------------
// parse MINVALUE value
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseMinValue(var FieldDef: TSQLFieldDef): Boolean;
begin
  Result := False;
  if (IsReservedWord(Token, rwMINVALUE)) then
    begin
      GetNextToken([], 30300, ErrorGUnexpectedEndOfCommand);
      FieldDef.MinValue.AsString := Token.Text;
      FieldDef.MinValue.Cast(bftSignedInt64);
      FieldDef.newMinValue := True;
      Result := True;
      GetNextToken;
    end
  else
  if (IsReservedWord(Token, rwNOMINVALUE)) then
    begin
      FieldDef.newMinValue := True;
      FieldDef.MinValue.SetNull;
      Result := True;
      GetNextToken;
    end
end;//ParseMinValue


//------------------------------------------------------------------------------
// parse MaxVALUE value
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseMaxValue(var FieldDef: TSQLFieldDef): Boolean;
begin
  Result := False;
  if (IsReservedWord(Token, rwMaxVALUE)) then
    begin
      GetNextToken([], 30300, ErrorGUnexpectedEndOfCommand);
      FieldDef.MaxValue.AsString := Token.Text;
      FieldDef.MaxValue.Cast(bftSignedInt64);
      FieldDef.newMaxValue := True;
      Result := True;
      GetNextToken;
    end
  else
  if (IsReservedWord(Token, rwNOMaxVALUE)) then
    begin
      FieldDef.newMaxValue := True;
      FieldDef.MaxValue.SetNull;
      Result := True;
      GetNextToken;
    end

end;//ParseMaxValue


//------------------------------------------------------------------------------
// parse fiald ... PRIMARY KEY
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseFieldPrimaryKey(var FieldDef: TSQLFieldDef): Boolean;
var
  TokenNo, i: Integer;
  desc, nocase: Boolean;
begin
  // PRIMARY [KEY] [ ASC | DESC ]  [ CASE | NOCASE ]
  Result := False;
  // PRIMARY
  if (Token.ReservedWord = rwPRIMARY) then
    begin
      TokenNo := LLex.GetCurrentTokenNo;
      GetNextToken;
      // [KEY] ?
      if (Token.ReservedWord <> rwKEY) then
       LLex.SetCurrentTokenNo(TokenNo, Token);

      desc := false;
      nocase := false;
      // ASC, CASE ?
      repeat
        GetNextToken([], 30333, ErrorGUnexpectedEndOfCommand);
        case Token.ReservedWord of
          rwASC:    desc:=false;
          rwDESC:   desc:=true;
          rwCASE:   nocase:=false;
          rwNOCASE: nocase:=true;
          else
            break;
        end;
      until false;


      FieldDef.newPrimaryKey := True;
      FieldDef.PrimaryKey := True;
      
      // add field to primary index
      i := Length(PrimaryKeyFields);
      SetLength(PrimaryKeyFields, i + 1);
      PrimaryKeyFields[i].FieldName := FieldDef.FieldName;
      PrimaryKeyFields[i].desc := desc;
      PrimaryKeyFields[i].nocase := nocase;
      Result := True;
    end;
end;//ParseFieldPrimaryKey


//------------------------------------------------------------------------------
// parse fiald ... UNIQUE
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseFieldUnique(var FieldDef: TSQLFieldDef): Boolean;
begin
  Result := False;
  // UNIQUE
  if (Token.ReservedWord = rwUNIQUE) then
    begin
      FieldDef.newUnique := True;
      FieldDef.Unique := True;
      UniqueFields.Add(FieldDef.FieldName);
      Result := True;
      GetNextToken;
    end;
end;//ParseFieldUnique


//------------------------------------------------------------------------------
// parse Primary Key
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParsePrimaryKey: boolean;
var
  desc, nocase:   Boolean;
  FieldName:      AnsiString;
  i,SavedTokenNo: Integer;
begin
  // PRIMARY [KEY] [indexname] (column1 [asc|desc] [case|nocase] [, column2...])
  // CONSTRAINT [indexname] PRIMARY [KEY] (column1 [asc|desc] [case|nocase] [, column2...])
  Result := false;
  PrimaryIndexName := '';
  if (Token.ReservedWord = rwCONSTRAINT) then
  begin
   SavedTokenNo := LLex.GetCurrentTokenNo;
   if (LLex.GetNextToken(Token)) then
   begin
    if (Token.ReservedWord <> rwPRIMARY) then
    begin
     PrimaryIndexName := Token.Text;
     LLex.GetNextToken(token);
    end;
   end;
   if (Token.ReservedWord <> rwPRIMARY) then
   begin
    LLex.SetCurrentTokenNo(SavedTokenNo,Token);
    Exit;
   end;
  end;
  // PRIMARY
  if (Token.ReservedWord = rwPRIMARY) then
    begin
      GetNextToken;
      // KEY
      if (Token.ReservedWord = rwKEY) then
      GetNextToken;

      // indexname
      if (Token.TokenType <> tktLeftParenthesis) then
        begin
          PrimaryIndexName := Token.Text;
          GetNextToken;
        end;

      // '('
      if (Token.TokenType <> tktLeftParenthesis) then
        raise ESQLMemException.Create(30327, ErrorGLeftParenthesisExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);

      repeat
        GetNextToken;
        // FieldName
        if Token.TokenType in [tktString, tktBracketedString, tktQuotedString, tktBackQuotedString, tktReservedWord] then
          FieldName := Token.Text
        else
          raise ESQLMemException.Create(30244, ErrorGFieldNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);

        GetNextToken;

        desc := false;
        nocase := false;
        // ASC, CASE ?
        repeat
            case Token.ReservedWord of
                rwASC:    desc:=false;
                rwDESC:   desc:=true;
                rwCASE:   nocase:=false;
                rwNOCASE: nocase:=true;
            else
              break;
            end;
            GetNextToken([], 30333, ErrorGUnexpectedEndOfCommand);
        until false;


        // add field to primary index
        i := Length(PrimaryKeyFields);
        SetLength(PrimaryKeyFields, i + 1);
        PrimaryKeyFields[i].FieldName := FieldName;
        PrimaryKeyFields[i].desc := desc;
        PrimaryKeyFields[i].nocase := nocase;


        // ')'or ','
        if not (Token.TokenType in [tktComma, tktRightParenthesis]) then
          raise ESQLMemException.Create(30245, ErrorGRightParenthesisOrCommaExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
      until (Token.TokenType = tktRightParenthesis);

      // get next token
      GetNextToken;
      Result := true;
    end;
end;//ParsePrimaryKey


//------------------------------------------------------------------------------
// parse Foreign Key
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseForeignKey: boolean;
var
    ForeignKeyDef:    TSQLMemForeignKeyDef;
    bUpdate:          Boolean;
    bDelete:          Boolean;
    bUpdateCompleted: Boolean;

 procedure ParseAction(Update: Boolean);
 begin
  if (IsReservedWord(Token,rwCASCADE)) then
   begin
    if (Update) then
     ForeignKeyDef.UpdateAction := fkaCascade
    else
     ForeignKeyDef.DeleteAction := fkaCascade;
   end
  else
  if (IsReservedWord(Token,rwSET)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwNULL)) then
     begin
      if (Update) then
       ForeignKeyDef.UpdateAction := fkaSetNull
      else
       ForeignKeyDef.DeleteAction := fkaSetNull;
     end
    else
    if (IsReservedWord(Token,rwDEFAULT)) then
     begin
      if (Update) then
       ForeignKeyDef.UpdateAction := fkaSetDefault
      else
       ForeignKeyDef.DeleteAction := fkaSetDefault;
     end
    else
     raise ESQLMemException.Create(11474,ErrorGOtherTokenExpected,
      [GetReservedWord(rwNULL) + 'or '+GetReservedWord(rwDEFAULT),
       Token.Text,Token.LineNum,Token.ColumnNum]);
   end
  else
  if (IsReservedWord(Token,rwNO)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwACTION)) then
     begin
      if (Update) then
       ForeignKeyDef.UpdateAction := fkaNoAction
      else
       ForeignKeyDef.DeleteAction := fkaNoAction;
     end
    else
     raise ESQLMemException.Create(11475,ErrorGOtherTokenExpected,
      [GetReservedWord(rwACTION) ,
       Token.Text,Token.LineNum,Token.ColumnNum]);
   end
  else
   raise ESQLMemException.Create(11476,ErrorGOtherTokenExpected,
     [GetReservedWord(rwCASCADE) + 'or '+GetReservedWord(rwSET)+'or '+
      GetReservedWord(rwNO),
      Token.Text,Token.LineNum,Token.ColumnNum]);
  // get next token
  GetNextToken;
 end; // ParseAction


begin
  // FOREIGN KEY [keyname] (column1 [, column2...]) REFERENCES tablename
  // [MATCH FULL | MATCH PARTIAL]
  // [ON DELETE {CASCADE | SET NULL | SET DEFAULT | NO ACTION}]
  // [ON UPDATE {CASCADE | SET NULL | SET DEFAULT | NO ACTION}]
  Result := false;
  if (Token.ReservedWord = rwCONSTRAINT) then
  begin
   if (GetNextToken) then
    if (Token.ReservedWord <> rwFOREIGN) then
    begin
     if (FForeignKeyDefs = nil) then
       FForeignKeyDefs := TSQLMemForeignKeyDefs.Create;
     ForeignKeyDef := TSQLMemForeignKeyDefs(FForeignKeyDefs).AddForeignKeyDef;
     ForeignKeyDef.Name := Token.Text;
     // skip constraint name
     GetNextToken;
    end;
  end
  else
   ForeignKeyDef := nil;
  // FOREIGN
  if (IsReservedWord(Token,rwFOREIGN)) then
    begin
      GetNextToken;
      // KEY
      if (IsReservedWord(Token,rwKEY)) then
       GetNextToken
      else
       raise ESQLMemException.Create(11467,ErrorGOtherTokenExpected,
        [GetReservedWord(rwKEY),Token.Text,Token.LineNum,Token.ColumnNum]);

      if (FForeignKeyDefs = nil) then
       FForeignKeyDefs := TSQLMemForeignKeyDefs.Create;
      if (ForeignKeyDef = nil) then
        ForeignKeyDef := TSQLMemForeignKeyDefs(FForeignKeyDefs).AddForeignKeyDef;
      // foreign key name
      if (Token.TokenType <> tktLeftParenthesis) then
        begin
          ForeignKeyDef.Name := Token.Text;
          GetNextToken;
        end;

      // '('
      if (Token.TokenType <> tktLeftParenthesis) then
        raise ESQLMemException.Create(11468, ErrorGLeftParenthesisExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);

      repeat
        GetNextToken;
        // FieldName
        if Token.TokenType in [tktQuotedString, tktString, tktBackQuotedString, tktBracketedString] then
         begin
          if (ForeignKeyDef.Columns = '') then
           ForeignKeyDef.Columns := Token.Text
          else
           ForeignKeyDef.Columns := ForeignKeyDef.Columns + SemiColon + Token.Text;
         end
        else
          raise ESQLMemException.Create(11469, ErrorGFieldNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
        GetNextToken;
        // ')'or ','
        if not (Token.TokenType in [tktComma, tktRightParenthesis]) then
          raise ESQLMemException.Create(11470, ErrorGRightParenthesisOrCommaExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
      until (Token.TokenType = tktRightParenthesis);

      // get next token
      GetNextToken;

      if (IsReservedWord(Token,rwREFERENCES)) then
       begin
        GetNextToken;
        if Token.TokenType in [tktString, tktQuotedString, tktBackQuotedString, tktBracketedString] then
         begin
          ForeignKeyDef.ReferencedTableName := Token.Text;
          GetNextToken;
         end
        else
         raise ESQLMemException.Create(11478, ErrorGTableNameExpected,
                         [Token.Text, Token.LineNum, Token.ColumnNum]);
       end
      else
       raise ESQLMemException.Create(11477,ErrorGOtherTokenExpected,
         [GetReservedWord(rwREFERENCES),Token.Text,Token.LineNum,Token.ColumnNum]);

      if (IsReservedWord(Token,rwMATCH)) then
       begin
        GetNextToken;
        if (IsReservedWord(Token,rwFULL)) then
         ForeignKeyDef.MatchType := fkmtFull
        else
        if (IsReservedWord(Token,rwPARTIAL)) then
         ForeignKeyDef.MatchType := fkmtPartial
        else
         raise ESQLMemException.Create(11471,ErrorGOtherTokenExpected,
          [GetReservedWord(rwFULL)+'or '+ GetReservedWord(rwPARTIAL),Token.Text,Token.LineNum,Token.ColumnNum]);
        GetNextToken;
       end;

      bDelete := False;
      bUpdate := False;
      if (IsReservedWord(Token,rwON)) then
       begin
        GetNextToken;
        if (IsReservedWord(Token,rwUPDATE)) then
         bUpdate := True
        else
        if (IsReservedWord(Token,rwDELETE)) then
         bDelete := True
        else
         raise ESQLMemException.Create(11472,ErrorGOtherTokenExpected,
          [GetReservedWord(rwUPDATE) + 'or '+GetReservedWord(rwDELETE),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        GetNextToken;
        ParseAction(bUpdate);
        bUpdateCompleted := bUpdate;
       end;

      if (IsReservedWord(Token,rwON)) then
       begin
        GetNextToken;
        if ((not bUpdate) and IsReservedWord(Token,rwUPDATE)) then
         bUpdate := True
        else
        if ((not bDelete) and IsReservedWord(Token,rwDELETE)) then
         bDelete := True
        else
         raise ESQLMemException.Create(11473,ErrorGOtherTokenExpected,
          [GetReservedWord(rwUPDATE) + 'or '+GetReservedWord(rwDELETE),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        GetNextToken;
        ParseAction(not bUpdateCompleted);
       end;
      Result := true;
    end; // Foreign Key
end;//ParseForeignKey


//------------------------------------------------------------------------------
// go to the Next token and Parse Integer (Int64)
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.ParseInteger: Int64;
begin
  GetNextToken([tktInt], 30292, ErrorGIntegerExpected);
  try
    Result := StrToInt64(Token.Text);
  except
    raise ESQLMemException.Create(30291, ErrorGIntegerExpected,
                               [Token.Text, Token.LineNum, Token.ColumnNum]);
  end;
  //GetNextToken;
end;//ParseInteger


//------------------------------------------------------------------------------
// Create SQLMemTable object and fill SQLMemTable params
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.CreateInternalSQLMemTable: TDataSet;
var i: Integer;
begin
  Result := inherited CreateInternalSQLMemTable;
  TSQLMemTable(Result).ClearDefinitions;
  for i := 0 to SQLFieldDefs.Count-1 do
    FillAdvFieldDef(
                    TFieldDef(TSQLMemTable(Result).AdvFieldDefs.AddFieldDef),
                    SQLFieldDefs[i]
                   );
  //FillPrimaryKey(Result);
end; // CreateInternalSQLMemTable


//------------------------------------------------------------------------------
// Add Primary Key into SQLMemTable
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.FillAdvFieldDef(
                                        AdvFieldDef: TFieldDef;
                                        SQLFieldDef: TSQLFieldDef
                                                  );
var
  fd: TSQLMemAdvFieldDef;
begin
  fd := TSQLMemAdvFieldDef(AdvFieldDef);

  fd.Name := SQLFieldDef.FieldName;

  // DataType
  if SQLFieldDef.newFieldType then
    fd.DataType := SQLFieldDef.FieldType;

  // Size
  if SQLFieldDef.newLength then
    fd.Size := SQLFieldDef.Length;

  // Required
  if SQLFieldDef.newRequired then
    fd.Required := SQLFieldDef.Required;

  // Autoinc settings
  if SQLFieldDef.newAutoincIncrement then
    fd.AutoincIncrement := SQLFieldDef.AutoincIncrement;
  if SQLFieldDef.newAutoincLastValue then
    fd.AutoincInitialValue := SQLFieldDef.AutoincLastValue;
  if SQLFieldDef.newAutoincMinValue then
    fd.AutoincMinValue  := SQLFieldDef.AutoincMinValue;
  if SQLFieldDef.newAutoincMaxValue then
    fd.AutoincMaxValue  := SQLFieldDef.AutoincMaxValue;
  if SQLFieldDef.newAutoincCycled then
    fd.AutoincCycled    := SQLFieldDef.AutoincCycled;

  // Blob settings
  if SQLFieldDef.newBlobBlockSize then
    fd.BlobBlockSize := SQLFieldDef.BlobBlockSize;
  if SQLFieldDef.newBlobCompressionAlgorithm then
    fd.BlobCompressionAlgorithm := TCompressionAlgorithm(SQLFieldDef.BlobCompressionAlgorithm);
  if SQLFieldDef.newBlobCompressionMode then
    fd.BlobCompressionMode := SQLFieldDef.BlobCompressionMode;

  // Default Value
  if SQLFieldDef.newDefaultValue then
    fd.DefaultValue.Assign(SQLFieldDef.DefaultValue);

  // MinValue
  if SQLFieldDef.newMinValue then
    fd.MinValue.Assign(SQLFieldDef.MinValue);
  // MaxValue
  if SQLFieldDef.newMaxValue then
    fd.MaxValue.Assign(SQLFieldDef.MaxValue);

end;//FillAdvFieldDef


//------------------------------------------------------------------------------
// Add Primary Key into SQLMemTable
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.AddPrimaryKey(T: TDataSet);
var
  i:                                  Integer;
  pkName:                             AnsiString;
  Fields, DescFields, CaseInsFields:  AnsiString;
begin
  // nocase, desc fields support added in 4.95
  if (Length(PrimaryKeyFields) <> 0) then
    begin
      Fields := '';
      DescFields := '';
      CaseInsFields := '';
      pkName := AutoNameConstraintPKPreffix;
      for i := 0 to Length(PrimaryKeyFields) - 1 do
        begin
         pkName := pkName + AutoNameSymbol + PrimaryKeyFields[i].FieldName;
         if (Fields = '') then
           Fields := PrimaryKeyFields[i].FieldName
         else
           Fields := Fields + Comma + PrimaryKeyFields[i].FieldName;
         if (PrimaryKeyFields[i].desc) then
          begin
           if (DescFields = '') then
             DescFields := PrimaryKeyFields[i].FieldName
           else
             DescFields := DescFields + Comma + PrimaryKeyFields[i].FieldName;
          end; // desc
         if (PrimaryKeyFields[i].nocase) then
          begin
           if (CaseInsFields = '') then
             CaseInsFields := PrimaryKeyFields[i].FieldName
           else
             CaseInsFields := CaseInsFields + Comma + PrimaryKeyFields[i].FieldName;
          end; // nocase
        end;
      //IndexDefs.Clear;
      if (PrimaryIndexName <> '') then
       pkName := PrimaryIndexName
      else
       repeat
        pkName := GetTemporaryName(pkName);
       until (TSQLMemTable(T).IndexDefs.IndexOf(pkName) < 0);
      TSQLMemTable(T).IndexDefs.Add(pkName, Fields, [ixPrimary]);
      i := TSQLMemTable(T).IndexDefs.Count-1;
      TSQLMemTable(T).IndexDefs.Items[i].DescFields := DescFields;
      TSQLMemTable(T).IndexDefs.Items[i].CaseInsFields := CaseInsFields;
      TSQLMemTable(T).RestructureIndexDefs.Add(pkName, Fields, [ixPrimary]);
      i := TSQLMemTable(T).RestructureIndexDefs.Count-1;
      TSQLMemTable(T).RestructureIndexDefs.Items[i].DescFields := DescFields;
      TSQLMemTable(T).RestructureIndexDefs.Items[i].CaseInsFields := CaseInsFields;
    end; // primary key fields defined
end;//AddPrimaryKey


//------------------------------------------------------------------------------
// Add UNIQUE constraint and index into SQLMemTable
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.AddUnique(T: TDataSet);
var
  i:      Integer;
  uName: AnsiString;
begin
  for i:=0 to UniqueFields.Count-1 do
    begin
     repeat
      uName := GetTemporaryName(AutoNameConstraintUniquePreffix +
                                AutoNameSymbol +
                                UniqueFields[i]);
     until (TSQLMemTable(T).IndexDefs.IndexOf(uName) < 0);
     TSQLMemTable(T).IndexDefs.Add(uName, UniqueFields[i], [ixUnique]);
     TSQLMemTable(T).RestructureIndexDefs.Add(uName, UniqueFields[i], [ixUnique]);
    end;
end;//AddUnique


//------------------------------------------------------------------------------
// Delete PrimaryKey
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.DeletePrimaryKey(T: TDataSet);
var
  i: integer;
  AT: TSQLMemTable;

  procedure DeleteIndexDef(idxDefs: TIndexDefs; index: integer);
  {$IFNDEF D5H}
  var
    i: integer;
    indDefs: TIndexDefs;
  {$ENDIF}

  begin
  {$IFDEF D5H}
    idxDefs.Delete(index);
  {$ELSE}
    indDefs := TIndexDefs.Create(AT);
    try
      for i:=0 to idxDefs.Count-1 do
        begin
          if i <> index then
            with indDefs[i] do
              indDefs.Add(idxDefs[i].Name, idxDefs[i].Fields, idxDefs[i].Options);
        end;
      idxDefs.assign(indDefs);
    finally
      indDefs.Free;
    end
  {$ENDIF}
  end;

begin
  AT := TSQLMemTable(T);

  if AT.IndexDefs.Count <> 0 then
    begin

      for i:=0 to AT.IndexDefs.Count-1 do
        if ixPrimary in AT.IndexDefs[i].Options then
          begin
           DeleteIndexDef(AT.IndexDefs, i);
           break;
          end;

      for i:=0 to AT.RestructureIndexDefs.Count-1 do
        if ixPrimary in AT.RestructureIndexDefs[i].Options then
          begin
            DeleteIndexDef(AT.RestructureIndexDefs, i);
            break;
          end;

    end;//if

end;//DeletePrimaryKey


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLTableManipulation.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLTableManipulation.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.Assign(Source: TSQLMemSQLCommand);
var i,l: Integer;
begin
  inherited Assign(Source);
  if (TSQLMemDDLTableManipulation(Source).FForeignKeyDefs = nil) then
   begin
    if (FForeignKeyDefs <> nil) then
     FreeAndNil(FForeignKeyDefs);
   end
  else
   begin
    if (FForeignKeyDefs = nil) then
     FForeignKeyDefs := TSQLMemForeignKeyDefs.Create;
    TSQLMemForeignKeyDefs(FForeignKeyDefs).Assign(TSQLMemForeignKeyDefs(TSQLMemDDLTableManipulation(Source).FForeignKeyDefs));
   end;
  SQLFieldDefs.Assign(TSQLFieldDefs(TSQLMemDDLTableManipulation(Source).SQLFieldDefs));
  PrimaryIndexName := TSQLMemDDLTableManipulation(Source).PrimaryIndexName;
  l := Length(TSQLMemDDLTableManipulation(Source).PrimaryKeyFields);
  SetLength(PrimaryKeyFields,l);
  if (l > 0) then
   for i := 0 to l-1 do
    begin
     PrimaryKeyFields[i].FieldName := TSQLMemDDLTableManipulation(Source).PrimaryKeyFields[i].FieldName;
     PrimaryKeyFields[i].desc := TSQLMemDDLTableManipulation(Source).PrimaryKeyFields[i].desc;
     PrimaryKeyFields[i].nocase := TSQLMemDDLTableManipulation(Source).PrimaryKeyFields[i].nocase;
    end;
  UniqueFields.Assign(TSQLMemDDLTableManipulation(Source).UniqueFields);
  bLeftParethesis := TSQLMemDDLTableManipulation(Source).bLeftParethesis;
  FComment := TSQLMemDDLTableManipulation(Source).FComment;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemDDLTableManipulation.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  // added in 4.97 - for ALTER TABLE add(...) ALTER TABLE DROP (...)
  bLeftParethesis := False;
  SQLFieldDefs := TSQLFieldDefs.Create;
  SetLength(PrimaryKeyFields, 0);
  UniqueFields := TSQLMemWideStringList.Create;
  PrimaryIndexName := '';
  FForeignKeyDefs := nil;
  FComment := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemDDLTableManipulation.Destroy;
begin
  SQLFieldDefs.Free;
  UniqueFields.Free;
  if (FForeignKeyDefs <> nil) then
   FForeignKeyDefs.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemDDLTableManipulation.Parse;
begin
  // check for not expected token
  if (LLex.LookNextToken(Token)) then
     raise ESQLMemException.Create(30246, ErrorGUnexpectedToken,
                                [Token.Text, Token.LineNum, Token.ColumnNum]);
end;//Parse




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLCreateTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLCreateTable.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLCreateTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateTable.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FIfNotExists := TSQLMemDDLCreateTable(Source).FIfNotExists;
end; // Assign


//------------------------------------------------------------------------------
// Create Table
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateTable.CreateTable;
var
  T: TSQLMemTable;
begin
{$IFDEF DEBUG_TRACE_TSQLMemDDLCreateTable_CreateTable}
aaWriteToLog('> TSQLMemDDLCreateTable.CreateTable'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(IntoMemory,True)
);
{$ENDIF}
  T := CreateInternalSQLMemTable as TSQLMemTable;
  try
    // If table already exists - raise
    if (FIfNotExists) then
     if (T.Exists) then
      Exit;
    if T.Exists then
      raise ESQLMemException.Create(30247, ErrorGTableAlreadyExists, [T.TableName]);

    try
      AddPrimaryKey(T);
      AddUnique(T);
      if (FForeignKeyDefs <> nil) then
       t.ForeignKeyDefs.Assign(TSQLMemForeignKeyDefs(FForeignKeyDefs));
{$IFDEF DEBUG_TRACE_TSQLMemDDLCreateTable_CreateTable}
aaWriteToLog('TSQLMemDDLCreateTable.CreateTable calling CreateTable...'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(IntoMemory,True)
+#13#10+'t.DatabaseName = '+TSQLMemTable(t).DatabaseName
+#13#10+'t.TableName = '+TSQLMemTable(t).TableName
+#13#10+'t.InMemory = '+BoolToStr(TSQLMemTable(t).InMemory,True)
);
{$ENDIF}
      T.Comment := FComment;
      T.CreateTable;
{$IFDEF DEBUG_TRACE_TSQLMemDDLCreateTable_CreateTable}
aaWriteToLog('< TSQLMemDDLCreateTable.CreateTable'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(IntoMemory,True)
);
{$ENDIF}
    except
      on e:Exception do
        raise ESQLMemException.Create(30248, ErrorGErrorCreatingTable, [e.Message]);
    end;

  finally
    T.Free;
  end
end;//CreateTable


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateTable.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(30249, ErrorGBlankSqlCommand);
  FIfNotExists := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (not IsReservedWord(Token,rwNOT)) then
     raise ESQLMemException.Create(12464, ErrorGOtherTokenExpected,
         ['NOT EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
     FIfNotExists := True;
    end
    else
     raise ESQLMemException.Create(12465, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;

  ParseTableNameToken;
  ParseTableElementList;
  ParseComment;

  inherited;
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                    );
begin
  CreateTable;
end;//ExecSQL



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLDropTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Drop Table - always without exception
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropTable.DropTable;
var
  T: TSQLMemTable;
begin
  T := CreateInternalSQLMemTable as TSQLMemTable;
  try
    try
      T.Exclusive := True;
      if (T.Exists) then
       T.DeleteTable(FCascade);
    except
      on e:Exception do
        raise ESQLMemException.Create(30250, ErrorGDroppingTable, [e.Message]);
    end;
  finally
    T.Free;
  end
end;//DropTable


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLDropTable.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLDropTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropTable.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FCascade := TSQLMemDDLDropTable(Source).FCascade;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropTable.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(30251,ErrorGBlankSQLCommand);
  FCascade := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
    end
    else
     raise ESQLMemException.Create(12463, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
  ParseTableNameToken;
  if (IsReservedWord(Token,rwCASCADE)) then
   begin
    FCascade := True;
    GetNextToken;
   end
  else
  if (IsReservedWord(Token,rwRESTRICT)) then
   GetNextToken;
  inherited;
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                  );
begin
  DropTable;
end;//ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLEmptyTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Empty Table
//------------------------------------------------------------------------------
procedure TSQLMemDDLEmptyTable.EmptyTable;
var T: TSQLMemTable;
begin
  T := CreateInternalSQLMemTable as TSQLMemTable;
  try
    if (not FIfExists) and (not t.Exists) then
     raise ESQLMemException.Create(12457,ErrorLTableDoesNotExist,[T.TableName]);
    try
      T.Exclusive := True;
      if (t.Exists) then
       T.EmptyTable;
    except
      on e:Exception do
        raise ESQLMemException.Create(12458, ErrorLEmptyTable, [e.Message]);
    end;
  finally
    T.Free;
  end
end;//EmptyTable


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLEmptyTable.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLEmptyTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLEmptyTable.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FIfExists := TSQLMemDDLEmptyTable(Source).FIfExists;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDDLEmptyTable.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(12461,ErrorGBlankSQLCommand);
  FIfExists := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
     FIfExists := True;
    end
    else
     raise ESQLMemException.Create(12462, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
  ParseTableNameToken;
  inherited;
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemDDLEmptyTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                  );
begin
  EmptyTable;
end;//ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLAlterTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemDDLAlterTable.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  DropColumnNamesList := TSQLMemWideStringList.Create;
  RenameColumnOldNamesList := TSQLMemWideStringList.Create;
  RenameColumnNewNamesList := TSQLMemWideStringList.Create;
  NewTableName := '';
  FModifyComment := False;
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemDDLAlterTable.Destroy;
begin
  DropColumnNamesList.Free;
  RenameColumnOldNamesList.Free;
  RenameColumnNewNamesList.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// parse AlterType token
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.ParseAlterTypeToken;
begin
  if Token.TokenType = tktReservedWord then
    case Token.ReservedWord of
     rwADD:
      begin
       // ADD [COLUMN] | ADD PRIMARY KEY | ADD FOREIGN KEY | ADD UNIQUE
       GetNextToken;
       // parethesis support added in 4.97
       if (Token.TokenType = tktLeftParenthesis) then
        begin
         bLeftParethesis := True;
         GetNextToken;
        end;
       if (IsReservedWord(Token,rwCOLUMN)) then
        begin
          AlterType := atAdd;
          GetNextToken;
        end
       else
       if (IsReservedWord(Token,rwPRIMARY)) then
        begin
          AlterType := atAddConstraintPrimaryKey;
        end
       else
       if (IsReservedWord(Token,rwFOREIGN) or IsReservedWord(Token,rwCONSTRAINT)) then
        begin
          AlterType := atAddConstraintForeignKey;
        end
{
       else
       if (IsReservedWord(Token,rwUNIQUE)) then
        begin
          AlterType := atAddConstraintUnique;
          GetNextToken;
        end
}
       else
        AlterType := atAdd; // Column
      end;
     rwDROP:
       begin
         GetNextToken;
         // parethesis support added in 4.97
         if (Token.TokenType = tktLeftParenthesis) then
          begin
           bLeftParethesis := True;
           GetNextToken;
          end;
         if (IsReservedWord(Token,rwCOLUMN)) then
          begin
           AlterType := atDrop;
           GetNextToken;
          end
         else
         if (IsReservedWord(Token,rwCONSTRAINT)) then
          begin
           AlterType := atDropConstraint;
           GetNextToken;
          end
         else
          AlterType := atDrop;
       end;
     // MODIFY <column_name> <column difinition>
     rwMODIFY:
       begin
         AlterType := atModify;
         GetNextToken;
       end;
     // ALTER [COLUMN] <column_name> <column difinition>
     rwALTER:
       begin
         AlterType := atModify;
         GetNextToken;
         if (IsReservedWord(Token,rwCOLUMN)) then
          GetNextToken;
       end;
     rwRENAME:
       begin
         // RENAME TO | RENAME [COLUMN] columnname TO
         GetNextToken;
         if IsReservedWord(Token, rwTO) then
          begin
           AlterType := atRenameTable;
           GetNextToken;
          end
         else
           begin
             AlterType := atRenameColumn;
             if IsReservedWord(Token, rwCOLUMN) then
               GetNextToken;
           end;
       end;
     else
       raise ESQLMemException.Create(30252, ErrorGAddOrDropOrModifyKeywordExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);
    end//case
  else
    raise ESQLMemException.Create(30253, ErrorGAddOrDropOrModifyKeywordExpected,
                            [Token.Text, Token.LineNum, Token.ColumnNum]);
end;//ParseAlterTypeToken


//------------------------------------------------------------------------------
// Alter Table DropColumn
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.ParseRenameColumnsList;
begin
  // OldColumnName
  RenameColumnOldNamesList.Add(Token.Text);
  GetNextToken;

  // TO
  if not IsReservedWord(Token, rwTO) then
    raise ESQLMemException.Create(30352, ErrorGOtherTokenExpected,
                          ['TO', Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;

  // NewColumnName
  RenameColumnNewNamesList.Add(Token.Text);
  GetNextToken;
end;//ParseRenameColumnsList


//------------------------------------------------------------------------------
// parse DROP CONSTRAINT
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.ParseDropConstraint;
begin
  DropConstraintCascade := False;
  if (Token.TokenType in [tktString,tktBracketedString,tktBackQuotedString,tktQuotedString]) then
   begin
    DropConstraintName := Token.Text;
    if (GetNextToken) then
     begin
      if (IsReservedWord(Token,rwRESTRICT)) then
       GetNextToken
      else
      if (IsReservedWord(Token,rwCASCADE)) then
       begin
        DropConstraintCascade := True;
        GetNextToken;
       end
      else
       raise ESQLMemException.Create(11496,ErrorGOtherTokenExpected,
         [GetReservedWord(rwCASCADE) + 'or '+GetReservedWord(rwRESTRICT),
          Token.Text,Token.LineNum,Token.ColumnNum]);
     end;
   end
  else
   raise ESQLMemException.Create(11495, ErrorLConstraintNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
end; // ParseDropConstraint


//------------------------------------------------------------------------------
// Alter Table DropColumn
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.DropColumn(T: TDataSet);
var i: Integer;
begin
  for i:=0 to DropColumnNamesList.Count-1 do
    TSQLMemTable(T).RestructureFieldDefs.DeleteFieldDef(DropColumnNamesList[i]);
end;//DropColumn


//------------------------------------------------------------------------------
// Alter Table AddColumn
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.AddColumn(T: TDataSet);
var
  i: Integer;
  fd: TSQLMemAdvFieldDef;
begin
    for i:=0 to SQLFieldDefs.Count-1 do
      begin
        fd := TSQLMemTable(T).RestructureFieldDefs.Find(SQLFieldDefs[i].FieldName);
        if fd <> nil then
          raise ESQLMemException.Create(30351, ErrorGFieldAlreadyExists,
                                     [SQLFieldDefs[i].FieldName]);
        // Add Field
        fd := TSQLMemTable(T).RestructureFieldDefs.AddFieldDef;

        // Fill Field
        FillAdvFieldDef(TFieldDef(fd), SQLFieldDefs[i]);

      end;
//  DeletePrimaryKey(T);
//  AddPrimaryKey(T);
end;//AddColumn


//------------------------------------------------------------------------------
// Alter Table Modify
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.Modify(T: TDataSet);
var
  i: Integer;
  fd: TSQLMemAdvFieldDef;
begin
  if (FModifyComment) then
   begin
    if (TSQLMemTable(T).Database <> nil) then
     TSQLMemTable(T).Database.SetTableComment(TSQLMemTable(T).TableName,FComment);
   end
  else
  for i:=0 to SQLFieldDefs.Count-1 do
    begin
      fd := TSQLMemTable(T).RestructureFieldDefs.Find(SQLFieldDefs[i].FieldName);
      if fd = nil then
        raise ESQLMemException.Create(30259, ErrorGCannotFindField,
                                   [TSQLMemTable(t).TableName+'.'+SQLFieldDefs[i].FieldName]);

      // Apply Changes
      FillAdvFieldDef(TFieldDef(fd), SQLFieldDefs[i]);

    end;
//  DeletePrimaryKey(T);
//  AddPrimaryKey(T);
end;//Modify


//------------------------------------------------------------------------------
// Rename Column
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.RenameColumn(T: TDataSet);
var  i: Integer;
begin
  for i:=0 to  RenameColumnOldNamesList.Count-1 do
   TSQLMemTable(T).RenameField(RenameColumnOldNamesList[i],
                            RenameColumnNewNamesList[i]);
end;//RenameColumn


//------------------------------------------------------------------------------
// modify comment
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.ModifyComment(Session: TSQLMemBaseSession);
begin
  if (Session = nil) then
   raise ESQLMemException.Create(12099,ErrorLNilPointer);
  Session.SetTableComment(TableName,FComment);
end; // ModifyComment


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLAlterTable.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLAlterTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  AlterType := TSQLMemDDLAlterTable(Source).AlterType;
  DropColumnNamesList.Assign(TSQLMemDDLAlterTable(Source).DropColumnNamesList);
  RenameColumnOldNamesList.Assign(TSQLMemDDLAlterTable(Source).RenameColumnOldNamesList);
  RenameColumnNewNamesList.Assign(TSQLMemDDLAlterTable(Source).RenameColumnNewNamesList);
  NewTableName := TSQLMemDDLAlterTable(Source).NewTableName;
  NewDatabaseName := TSQLMemDDLAlterTable(Source).NewDatabaseName;
  NewInMemory := TSQLMemDDLAlterTable(Source).NewInMemory;
  DropConstraintName := TSQLMemDDLAlterTable(Source).DropConstraintName;
  DropConstraintCascade := TSQLMemDDLAlterTable(Source).DropConstraintCascade;
  FModifyComment := TSQLMemDDLAlterTable(Source).FModifyComment;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(30261, ErrorGBlankSqlCommand);

  // Parse Table Name
  ParseTableNameToken;

  // Parse Alter Table Type
  ParseAlterTypeToken;
  try
    case AlterType of
     atAdd:
      ParseTableElementList;
     atModify:
      begin
        if (ParseComment) then
         FModifyComment := True
        else
         ParseTableElementList;
      end;
     atDrop:
      begin
       if (Token.TokenType = tktLeftParenthesis) then
        begin
         GetNextToken;
         ParseColumnList(DropColumnNamesList);
         GetNextToken;
        end
       else
        ParseColumnList(DropColumnNamesList);
      end;
     atRenameColumn:
      ParseRenameColumnsList;
     atRenameTable:
      NewTableName := Token.Text;
     atAddConstraintPrimaryKey:
      ParsePrimaryKey;
  {
     atAddConstraintUnique:
      ParseTableElementList;
  }
     atAddConstraintForeignKey:
      ParseForeignKey;
     atDropConstraint:
      ParseDropConstraint;
     else
      raise ESQLMemException.Create(30350, ErrorGNotImplementedYet);
    end;
  finally
   // parenthesis support added in 4.97
   if (bLeftParethesis) then
    GetNextToken;
  end;
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemDDLAlterTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                    );
var
  T:    TSQLMemTable;
  i:    Integer;
  Log:  AnsiString;
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12100,ErrorLNilPointer);
  if (FModifyComment) then
   ModifyComment(FDatabaseParams.Session)
  else
   begin
    T := CreateInternalSQLMemTable as TSQLMemTable;
    try
      try
        t.Exclusive := True;
        // get RestructureFieldDefs
        t.Open;
        t.Close;

        case AlterType of
          atDrop:
            DropColumn(T);
          atAdd:
           begin
            AddColumn(T);
            AddUnique(T);
           end;
          atModify:
            Modify(T);
          atRenameColumn:
            RenameColumn(T);
          atRenameTable:
            T.RenameTable(NewTableName);
          atAddConstraintPrimaryKey:
            AddPrimaryKey(T);
          atAddConstraintForeignKey:
           for i := 0 to TSQLMemForeignKeyDefs(FForeignKeyDefs).Count-1 do
            T.AddForeignKey(TSQLMemForeignKeyDefs(FForeignKeyDefs).Items[i]);
  //          if (FForeignKeyDefs <> nil) then
  //           T.RestructureForeignKeyDefs.Assign(TSQLMemForeignKeyDefs(FForeignKeyDefs));
          atDropConstraint:
            T.DeleteConstraint(DropConstraintName,DropConstraintCascade);
        end;

        if (AlterType in [atDrop, atAdd, atModify, atAddConstraintPrimaryKey]) then
          // RestructureTable
         if not (t.RestructureTable(Log)) then
          raise ESQLMemException.Create(30347 ,ErrorGRestructureTableError, [Log]);

      except
        on e:Exception do
          raise ESQLMemException.Create(30265, ErrorGErrorAlteringTable,[e.Message]);
      end
    finally
      T.Free;
    end
   end;
end;//ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLRenameTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLRenameTable.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLRenameTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDDLRenameTable.Parse;
begin
  if (not GetCurrentToken) then
    raise ESQLMemException.Create(30354, ErrorGBlankSqlCommand);

  AlterType := atRenameTable;

  // Parse Table Name
  ParseTableNameToken;

  // TO
  if not IsReservedWord(Token, rwTO) then
    raise ESQLMemException.Create(30355, ErrorGOtherTokenExpected,
                          ['TO', Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;

  // New Table Name
  NewTableName := Token.Text;

end;//Parse



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLCreateIndex
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLCreateIndex.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLCreateIndex.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateIndex.Assign(Source: TSQLMemSQLCommand);
var l,i: Integer;
begin
  inherited Assign(Source);
  Unique := TSQLMemDDLCreateIndex(Source).Unique;
  IfNotExists := TSQLMemDDLCreateIndex(Source).IfNotExists;
  IndexName := TSQLMemDDLCreateIndex(Source).IndexName;
  TableName := TSQLMemDDLCreateIndex(Source).TableName;
  l := Length(TSQLMemDDLCreateIndex(Source).SQLMemIndexFields);
  SetLength(SQLMemIndexFields,l);
  if (l > 0) then
   for i := 0 to l-1 do
    begin
     SQLMemIndexFields[i].FieldName := TSQLMemDDLCreateIndex(Source).SQLMemIndexFields[i].FieldName;
     SQLMemIndexFields[i].desc := TSQLMemDDLCreateIndex(Source).SQLMemIndexFields[i].desc;
     SQLMemIndexFields[i].nocase := TSQLMemDDLCreateIndex(Source).SQLMemIndexFields[i].nocase;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemDDLCreateIndex.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  Unique := False;
  IfNotExists := False;
  SetLength(SQLMemIndexFields, 0);
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateIndex.Parse;
var TempToken: TToken;
begin
  if (not GetCurrentToken) then
    raise ESQLMemException.Create(30266, ErrorGBlankSQLCommand);

  // UNIQUE
  if IsReservedWord(Token, rwUNIQUE) then
    begin
      Unique:=true;
      GetNextToken([tktReservedWord], 30267, ErrorGIndexKeywordExpected);
    end;

  // INDEX
  if not IsReservedWord(Token, rwINDEX) then
    raise ESQLMemException.Create(30268, ErrorGIndexKeywordExpected,
             [Token.Text, Token.LineNum, Token.ColumnNum]);

  LLex.LookNextToken(TempToken);
  if (IsReservedWord(TempToken, rwIF)) then
    begin
     GetNextToken;
     GetNextToken([tktReservedWord], 11236, ErrorLSQLNotKeywordExpected);
     if (not IsReservedWord(Token, rwNOT)) then
      raise ESQLMemException.Create(11237, ErrorLSQLNotKeywordExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
     GetNextToken([tktReservedWord], 11238, ErrorLSQLExistsKeywordExpected);
     if (not IsReservedWord(Token, rwEXISTS)) then
      raise ESQLMemException.Create(11239, ErrorLSQLExistsKeywordExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
     IfNotExists := True;
    end;

  // Index_name
  GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBackQuotedString,tktBracketedString],
               30269, ErrorGIndexNameExpected);
  IndexName := Token.Text;

  // ON
  GetNextToken([tktReservedWord], 30270, ErrorGOnKeywordExpected);
  if (not IsReservedWord(Token, rwON)) then
    raise ESQLMemException.Create(30271, ErrorGOnKeywordExpected,
                 [Token.Text, Token.LineNum, Token.ColumnNum]);
                 
  // table_name
  GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBackQuotedString,tktBracketedString],
               30272, ErrorGTableNameExpected);
  IntoMemory := False;
  if (IsReservedWord(Token,rwMEMORY)) then
   begin
    IntoMemory := True;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBackQuotedString,tktBracketedString],
               11301, ErrorGTableNameExpected);
   end;
  // table_name
  TableName := Token.Text;
  
  // '('
  GetNextToken([tktLeftParenthesis], 30273, ErrorGLeftParenthesisExpected);
  // column list...
  repeat
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBackQuotedString,tktBracketedString],
                 30274, ErrorGFieldNameExpected);
    SetLength(SQLMemIndexFields, Length(SQLMemIndexFields)+1);
    with SQLMemIndexFields[Length(SQLMemIndexFields)-1] do
      begin
        // Column name
        FieldName := Token.Text;
        // default ASC
        desc := false;
        // default CASE
        nocase := false;
        repeat
          GetNextToken([], 30277, ErrorGUnexpectedEndOfCommand);
          case Token.ReservedWord of
            rwASC:    desc:=false;
            rwDESC:   desc:=true;
            rwCASE:   nocase:=false;
            rwNOCASE: nocase:=true;
          end;
        until Token.TokenType in [tktComma, tktRightParenthesis];
      end;
  until Token.TokenType = tktRightParenthesis;

//  // check for not expected token
//  if (LLex.LookNextToken(Token)) then
//    raise ETblException.Create(02050,
//                [Token.Text, Token.LineNum, Token.ColumnNum]);
end;//Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateIndex.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                    );
var
   T:                                 TSQLMemTable;
   Fields, DescFields, CaseInsFields: WideString;
   delim1,delim2,delim3:              WideString;
   i:                                 Integer;
   Options:                           TIndexOptions;
   bCancel:                           Boolean;
begin
   Fields:=''; DescFields:=''; CaseInsFields:='';
   delim1:=''; delim2:=''; delim3:='';
   for i:=0 to Length(SQLMemIndexFields)-1 do
     begin
       Fields := Fields + delim1 + SQLMemIndexFields[i].FieldName;
       delim1 := ';';
       if SQLMemIndexFields[i].desc then
         begin
           DescFields := DescFields + delim2 + SQLMemIndexFields[i].FieldName;
           delim2 := ';';
         end;
       if SQLMemIndexFields[i].nocase then
         begin
           CaseInsFields := CaseInsFields + delim3 + SQLMemIndexFields[i].FieldName;
           delim3 := ';';
         end;
     end;
   // Index Options
   if Unique then
     Options:=[ixUnique]
   else
     Options:=[];


   // Creating
   T := CreateInternalSQLMemTable as TSQLMemTable;
   try
     T.Exclusive := True;
     //T.Password := Password;
     T.Open;
     bCancel := IfNotExists and (T.IndexDefs.IndexOf(IndexName) >= 0);
     if (not bCancel) then
       T.AddIndex(IndexName, Fields, Options, DescFields, CaseInsFields);
     T.Close;
   finally
     T.Free;
   end;
end;//ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLDropIndex
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLDropIndex.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLDropIndex.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropIndex.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  IfExists := TSQLMemDDLDropIndex(Source).IfExists;
  TableName := TSQLMemDDLDropIndex(Source).TableName;
  IndexName := TSQLMemDDLDropIndex(Source).IndexName;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemDDLDropIndex.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  IndexName := '';
  TableName := '';
  IfExists := False;
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropIndex.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(30278, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken([tktReservedWord], 11241, ErrorLSQLExistsKeywordExpected);
    if (not IsReservedWord(Token, rwEXISTS)) then
      raise ESQLMemException.Create(11242, ErrorLSQLExistsKeywordExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
    IfExists := True;
    if (not GetNextToken) then
      raise ESQLMemException.Create(11243, ErrorGUnexpectedEndOfCommand,
                                 [Token.LineNum, Token.ColumnNum]);
   end;

  IntoMemory := False;
  if (IsReservedWord(Token,rwMEMORY)) then
   begin
    IntoMemory := True;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBackQuotedString,tktBracketedString],
               11302, ErrorGTableNameExpected);
   end;
  // table_name
  TableName := Token.Text;
  if (not GetNextToken) then
    raise ESQLMemException.Create(30279, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  // '.'
  if (Token.TokenType <> tktDot) then
    raise ESQLMemException.Create(30280, ErrorGOtherTokenExpected,
                             ['.', Token.Text, Token.LineNum, Token.ColumnNum]);

  // index_name
  if (not GetNextToken) then
    raise ESQLMemException.Create(30281, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);
  IndexName:=Token.Text;

end;//Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropIndex.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                  );
var
   T:       TSQLMemTable;
   bCancel: Boolean;
begin
 T := CreateInternalSQLMemTable as TSQLMemTable;
 try
    T.Exclusive := True;
    T.Open;
    bCancel := IfExists and (T.IndexDefs.IndexOf(IndexName) < 0);
    if (not bCancel) then
      T.DeleteIndex(IndexName);
    T.Close;
  finally
    T.Free;
  end;
end;//ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStartTransaction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemStartTransaction.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemStartTransaction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemStartTransaction.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(10845, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);
  if (not IsReservedWord(Token, rwTransaction)) then
    raise ESQLMemException.Create(10846, ErrorGSQLCommandExpected,
                               [Token.Text,Token.LineNum, Token.ColumnNum]);
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemStartTransaction.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter6);
aaStartTime(time6);
try
{$ENDIF}
{$IFNDEF SQLMEMTABLE}
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TSQLMemStartTransaction.ExecSQL starting...'
    +', SessionID = '+
      IntToStr(TSQLMemBaseSession(Session).SessionID));
 {$ENDIF}
  FDatabaseParams.Session.StartTransaction;
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TSQLMemStartTransaction.ExecSQL starting... ok'
    +', SessionID = '+
      IntToStr(TSQLMemBaseSession(Session).SessionID));
 {$ENDIF}
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time6);
end;
{$ENDIF}
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCommit
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemCommit.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemCommit.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemCommit.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FFlushFileBuffers := TSQLMemCommit(Source).FFlushFileBuffers
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemCommit.Parse;
begin
  // modified in v.5.80
  FFLushFileBuffers := False;
  if (GetNextToken) then
   if (IsReservedWord(Token, rwFLUSH)) then
    FFlushFileBuffers := True;
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemCommit.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter7);
aaStartTime(time7);
try
{$ENDIF}
{$IFNDEF SQLMEMTABLE}
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TSQLMemStartTransaction.Commit starting...'
    +', SessionID = '+
      IntToStr(TSQLMemBaseSession(Session).SessionID));
 {$ENDIF}
  FDatabaseParams.Session.Commit(FFlushFileBuffers);
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TSQLMemStartTransaction.Commit starting...ok'
    +', SessionID = '+
      IntToStr(TSQLMemBaseSession(Session).SessionID));
 {$ENDIF}
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
finally
aaStopTime(time7);
end;
{$ENDIF}
end; // ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemRollback
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemRollback.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemRollback.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemRollback.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
begin
{$IFNDEF SQLMEMTABLE}
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TSQLMemStartTransaction.Rollback starting...'
    +', SessionID = '+
      IntToStr(TSQLMemBaseSession(Session).SessionID));
 {$ENDIF}
  FDatabaseParams.Session.Rollback;
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TSQLMemStartTransaction.Rolback starting...ok'
    +', SessionID = '+
      IntToStr(TSQLMemBaseSession(Session).SessionID));
 {$ENDIF}
{$ENDIF}
end; // ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseManagement
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDatabaseManagement.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDatabaseManagement.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseManagement.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FInMemory := TSQLMemDatabaseManagement(Source).FInMemory;
  FDatabaseName := TSQLMemDatabaseManagement(Source).FDatabaseName;
  FDatabaseFileName := TSQLMemDatabaseManagement(Source).FDatabaseFileName;
  FDatabaseFileNameUnicode := TSQLMemDatabaseManagement(Source).FDatabaseFileNameUnicode;
  FMaxSessionsCount := TSQLMemDatabaseManagement(Source).FMaxSessionsCount;
  FPageSize := TSQLMemDatabaseManagement(Source).FPageSize;
  FPassword := TSQLMemDatabaseManagement(Source).FPassword;
end; // Assign


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemDatabaseManagement.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
 {$IFDEF SQLMEMTABLE}
 FInMemory := True;
 {$ELSE}
 FInMemory := False;
 {$ENDIF}
 FDatabaseName := '';
 FDatabaseFileName := '';
 FDatabaseFileNameUnicode := '';
 FMaxSessionsCount := 0;
 FPageSize := 0;
 FPassword := '';
 inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemDatabaseManagement.Destroy;
begin
  if (FPassword <> '') then
   SQLMemClearString(FPassword);
  inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCreateDatabase
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemCreateDatabase.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemCreateDatabase.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
// CREATE DATABASE FILE FILE_NAME
// or
// CREATE DATABASE MEMORY DATABASE_NAME
// MEMORY can be skipped in SQLMemTable
//------------------------------------------------------------------------------
procedure TSQLMemCreateDatabase.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(11748, ErrorGBlankSqlCommand);
  if (not (Token.TokenType in
      [tktString, tktQuotedString, tktBackQuotedString,
       tktReservedWord, tktBracketedString])) then
    raise ESQLMemException.Create(11749, ErrorLDatabaseNameExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);
  if (IsReservedWord(Token, rwFILE)) then
   begin
    FInMemory := false;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,tktBackQuotedString,tktBracketedString],
                  11755, ErrorLDatabaseNameExpected);
    FDatabaseFileName := Token.Text;
    FDatabaseName := FDatabaseFileName;
    while (GetNextToken()) do
     if (not IsReservedWord(Token)) then
      break
     else
      begin
       if (Token.ReservedWord = rwPAGESIZE) then
        begin
         if (GetNextToken) then
          if (Token.TokenType = tktInt) then
           FPageSize := StrToIntDef(Token.Text,0);
        end
       else
       if (Token.ReservedWord = rwMAXSESSIONSCOUNT) then
        begin
         if (GetNextToken) then
          if (Token.TokenType = tktInt) then
           FMaxSessionsCount := StrToIntDef(Token.Text,0);
        end;
      end;
   end // file database
  else
   begin
    // memory database / incorrect statememt
    // MEMORY
    if (IsReservedWord(Token, rwMEMORY)) then
     begin
      FInMemory := true;
      GetNextToken([tktReservedWord,tktString,tktQuotedString,tktBackQuotedString,tktBracketedString],
                    11750, ErrorLDatabaseNameExpected);
     end
    else
     if (not FInMemory) then
      raise ESQLMemException.Create(11756,ErrorGOtherTokenExpected,
                             ['MEMORY',Token.Text,Token.LineNum,Token.ColumnNum]);
    // database name
    FDatabaseName := Token.Text;
   end;
end;// TSQLMemCreateDatabase


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemCreateDatabase.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
var db: TSQLMemDatabase;
begin
 db := TSQLMemDatabase.Create(nil);
 try
   db.SkipDatabaseNameCheck := True;
   db.InMemory := FInMemory;
   db.DatabaseName := FDatabaseName;
{$IFNDEF SQLMEMTABLE}
   if (FDatabaseFileName <> '') then
    db.DatabaseFileNameAnsi := FDatabaseFileName;
   if (FDatabaseFileNameUnicode <> '') then
    db.DatabaseFileNameUnicode := FDatabaseFileNameUnicode;
   if (FMaxSessionsCount > 0) then
    db.Options.MaxSessionCount := FMaxSessionsCount;
   if (FPageSize > 0) then
    db.Options.PageSize := FPageSize;
{$ENDIF}
   db.CreateDatabase;
 finally
   db.Free;
 end;
end;// TSQLMemCreateDatabase


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDropDatabase
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDropDatabase.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDropDatabase.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
// DROP DATABASE FILE FILE_NAME
// or
// DROP DATABASE MEMORY DATABASE_NAME
// MEMORY can be skipped in SQLMemTable
//------------------------------------------------------------------------------
procedure TSQLMemDropDatabase.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(11752, ErrorGBlankSqlCommand);
  if (not (Token.TokenType in
      [tktString, tktQuotedString, tktBackQuotedString,
       tktReservedWord, tktBracketedString])) then
    raise ESQLMemException.Create(11753, ErrorLDatabaseNameExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);

  // FILE
  if (IsReservedWord(Token, rwFILE)) then
   begin
    FInMemory := false;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,tktBackQuotedString,tktBracketedString],
                  11758, ErrorLDatabaseNameExpected);
    FDatabaseFileName := Token.Text;
    FDatabaseName := FDatabaseFileName;
   end // file database
  else
   begin
    if (IsReservedWord(Token, rwMEMORY)) then
     begin
      FInMemory := true;
      GetNextToken([tktReservedWord,tktString,tktQuotedString,tktBackQuotedString,tktBracketedString],
                    11754, ErrorLDatabaseNameExpected);
     end
    else
     if (not FInMemory) then
      raise ESQLMemException.Create(11757,ErrorGOtherTokenExpected,
                             ['MEMORY',Token.Text,Token.LineNum,Token.ColumnNum]);
     // database name
     FDatabaseName := Token.Text;
   end; // memory database or incorrect statement
end;// TSQLMemDropDatabase


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemDropDatabase.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
var db:           TSQLMemDatabase;
    dbFromQuery:  Boolean;
begin
 dbFromQuery := False;
// commented in v.5.10
{
 if (query <> nil) then
  if (query is TSQLMemQuery) then
   if (TSQLMemQuery(query).Database <> nil) then
    begin
     dbFromQuery := True;
     db := TSQLMemQuery(query).Database;
     db.RemoveDataset(query);
     db.Close;
    end;
}
 if (not dbFromQuery) then
  db := TSQLMemDatabase.Create(nil);
 try
   // we must skip ValidateName call as it will found database component
   // created by TSQLMemQuery.ExecSQL (SetDBFlag)
   db.SkipDatabaseNameCheck := True;
   db.InMemory := FInMemory;
   db.DatabaseName := FDatabaseName;
{$IFNDEF SQLMEMTABLE}
   if (FDatabaseFileName <> '') then
    db.DatabaseFileNameAnsi := FDatabaseFileName;
   if (FDatabaseFileNameUnicode <> '') then
    db.DatabaseFileNameUnicode := FDatabaseFileNameUnicode;
{$ENDIF}
   db.DeleteDatabase;
 finally
  if (not dbFromQuery) then
   db.Free;
 end;
end;// TSQLMemDropDatabase


{$IFDEF CORRELATED_SUBQUERIES}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQuery
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.DetectType;
begin
  FCorrelated := FQuery.PrepareSubQuery(Operator = doSubQueryIN);
  if (Operator <> doSubQuery) then
  begin
   FDataType := aftBoolean;
   FDataSize := 0;
  end
  else
  begin
   if (FQuery.RootAO = nil) then
    raise ESQLMemException.Create(12422,ErrorLNilPointer);
   FResultFieldNo := FQuery.RootAO.GetFirstResultFieldNo;
   FDataType := FQuery.RootAO.GetFieldType(FResultFieldNo);
   FDataSize := FQuery.RootAO.GetFieldSize(FResultFieldNo);
  end;
  FBaseType := AdvancedFieldTypeToBaseFieldType(FDataType);
  Value.Clear(FBaseType);
  if (not FCorrelated) then
  begin
    FQuery.ExecuteSubQuery;
    if (FSourceNode = nil) then
    begin
     InternalGetDataValue(False);
     if (Value.IsNull) then
      FResult := False
     else
      FResult := Value.AsBoolean;
    end;
  end;
end; // DetectType


//------------------------------------------------------------------------------
// return data value
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.InternalGetDataValue(BooleanResult: Boolean);
var v:          TSQLMemVariant;
    ds:         TSQLMemTable;
    cmpRes:     TSQLMemCompareResult;
    bNull:      Boolean;
begin
  case (Operator) of
    doSubQuery:
    begin
      if (FQuery.RootAO.Eof) then
      begin
        // no records -> null result
        Value.Clear(FBaseType);
      end
      else
      begin
        FQuery.RootAO.GetFieldValue(Value,FResultFieldNo,False,False);
      end;
    end;
    doSubQueryIN:
    begin
      if (FResultDatasetFieldNo < 0) then
         FResultDatasetFieldNo := FQuery.RootAO.GetFirstResultDatasetFieldNo;
      ds := TSQLMemTable(FQuery.GetResultDataset);
      // fixed in v.5.70 pr#3
      if (ds.RecordCount <= 0) then
      begin
        if (FNot) then
         FResult := True
        else
         FResult := False
      end
      else
      begin
        ds.SetKey;
        ds.SetFieldValue(FSourceNode.GetDataValue,FResultDatasetFieldNo,True);
        if (FNot) then
         FResult := not ds.GotoKey
        else
         FResult := ds.GotoKey;
      end;
      if (not BooleanResult) then
       Value.AsBoolean := FResult;
    end;
    doSubQueryEXISTS:
    begin
      if (BooleanResult) then
      begin
        if (FNot) then
          FResult := FQuery.RootAO.Eof
        else
          FResult := not FQuery.RootAO.Eof;
      end
      else
      begin
        if (FNot) then
          Value.AsBoolean := FQuery.RootAO.Eof
        else
          Value.AsBoolean := not FQuery.RootAO.Eof;
      end;
    end;
    doSubQueryANY:
    begin
      if (FResultDatasetFieldNo < 0) then
         FResultDatasetFieldNo := FQuery.RootAO.GetFirstResultDatasetFieldNo;
      ds := TSQLMemTable(FQuery.GetResultDataset);
      ds.First;
      FResult := False;
      if (not ds.Eof) then
      begin
       v := FSourceNode.GetDataValue;
       bNull := False;
       // scan all records
       while not ds.Eof do
       begin
        ds.GetFieldValue(Value,FResultDatasetFieldNo,True,False);
        cmpRes := v.Compare(Value,True,FCaseInsensitive,FPartialKey);
        if (cmpRes in [cmprBothNull,cmprLeftNull,cmprRightNull]) then
        begin
         bNull := True;
        end
        else
        begin
          case FComparisonOperator of
           doEQ:   FResult := (cmpRes = cmprEqual);
           doNE:   FResult := (cmpRes <> cmprEqual);
           doLT:   FResult := (cmpRes = cmprLower);
           doGT:   FResult := (cmpRes = cmprGreater);
           doLE:   FResult := (cmpRes = cmprEqual) or (cmpRes = cmprLower);
           doGE:   FResult := (cmpRes = cmprEqual) or (cmpRes = cmprGreater);
          end;
          if (FResult) then
           break;
        end;
        ds.Next;
       end;
      end;
      if (FNot) then
       FResult := not FResult;
      if (not BooleanResult) then
      begin
        // if Result = False and NULL found we cannot compare it and must return NULL as it described in ISO standard
        if ((not FResult) and bNull) then
          Value.Clear
        else
          Value.AsBoolean := FResult;
      end;
    end; // doSubQueryANY
    doSubQueryALL:
    begin
      if (FResultDatasetFieldNo < 0) then
         FResultDatasetFieldNo := FQuery.RootAO.GetFirstResultDatasetFieldNo;
      ds := TSQLMemTable(FQuery.GetResultDataset);
      ds.First;
      FResult := True;
      if (not ds.Eof) then
      begin
       v := FSourceNode.GetDataValue;
       bNull := False;
       // scan all records
       while not ds.Eof do
       begin
        ds.GetFieldValue(Value,FResultDatasetFieldNo,True,False);
        cmpRes := v.Compare(Value,True,FCaseInsensitive,FPartialKey);
        // if NULL found we cannot compare it and must return NULL as it described in ISO standard
        if (cmpRes in [cmprBothNull,cmprLeftNull,cmprRightNull]) then
        begin
         bNull := True;
        end
        else
        begin
          case FComparisonOperator of
           doEQ:   FResult := (cmpRes = cmprEqual);
           doNE:   FResult := (cmpRes <> cmprEqual);
           doLT:   FResult := (cmpRes = cmprLower);
           doGT:   FResult := (cmpRes = cmprGreater);
           doLE:   FResult := (cmpRes = cmprEqual) or (cmpRes = cmprLower);
           doGE:   FResult := (cmpRes = cmprEqual) or (cmpRes = cmprGreater);
          end;
          if (not FResult) then
           break;
        end;
        ds.Next;
       end;
      end;
      if (FNot) then
       FResult := not FResult;
      if (not BooleanResult) then
      begin
        // if Result = True and NULL found we cannot compare it and must return NULL as it described in ISO standard
        if (FResult and bNull) then
          Value.Clear
        else
          Value.AsBoolean := FResult;
      end;
    end; // doSubQueryALL
  end;
end; // InternalGetDataValue


//------------------------------------------------------------------------------
// Get FCorrelated
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetCorrelated: Boolean;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  Result := FCorrelated;
end; // GetCorrelated


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeSubQuery.Create(
                                         aParentExpr:           TSQLMemExpression;
                                         Operator:              TSQLMemDataOperator;
                                         aQuery:                TSQLMemSQLUnion;
                                         bNot:                  Boolean = False;
                                         SourceNode:            TSQLMemExprNode = nil;
                                         aComparisonOperator:   TSQLMemDataOperator = doEQ;
                                         CaseInsensitive:       Boolean = true;
                                         PartialKey:            Boolean = false
                                       );
var i:      Integer;
    Param:  TParam;
begin
  inherited Create(aParentExpr,Operator,CaseInsensitive,PartialKey);
  FQueryResult := False;
  FQuery := aQuery;
  FNot := bNot;
  FComparisonOperator := aComparisonOperator;
  FSourceNode := SourceNode;
  if (FSourceNode = nil) and (Operator <> doSubquery) and (Operator <> doSubQueryEXISTS) then
   raise ESQLMemException.Create(10850,ErrorLSubquerynoArgumentPassed);
  if (SourceNode <> nil) then
   Children.Add(SourceNode);
  FDataType := aftUnknown;
  FResultDatasetFieldNo := -1;
  FCorrelated := False;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeSubQuery.Destroy;
begin
  if (FQuery <> nil) then
  begin
   FQuery.Free;
   FQuery := nil;
  end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// process assign AO
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.AssignAO(AO: TSQLMemAO);
begin
  LAO := AO;
  if (FSourceNode <> nil) then
  begin
    FSourceNode.AssignAO(AO);
  end;
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    AO.AssignExternalFieldNodes(FQuery.RootAO);
  end;
end; // AssignAO


//------------------------------------------------------------------------------
// process assign Cursor
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.AssignCursor(Cursor: TSQLMemCursor);
begin
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    FQuery.RootAO.SetExternalFieldNodesCursor(Cursor);
  end;
  if (FSourceNode <> nil) then
  begin
    try
      FSourceNode.AssignCursor(Cursor);
    except
    end;
  end;
end; // AssignCursor


//------------------------------------------------------------------------------
// process assign New Cursor Buffer
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.AssignCursorBuffer(Buffer: TSQLMemRecordBuffer);
begin
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    FQuery.RootAO.SetExternalFieldNodesCursorBuffer(Buffer);
  end;
  if (FSourceNode <> nil) then
  begin
    FSourceNode.AssignCursorBuffer(Buffer);
  end;
end; // AssignCursorBuffer


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetDataValue: TSQLMemVariant;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    if (FQuery.RootAO = nil) then
     raise ESQLMemException.Create(12423,ErrorLNilPointer);
    if (LAO = nil) then
     raise ESQLMemException.Create(12426,ErrorLNilPointer);
    FQuery.ExecuteSubQuery;
    InternalGetDataValue(False);
  end
  else
  begin
    if (Operator <> doSubquery) then
      InternalGetDataValue(False);
  end;
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Value as Boolean
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetBooleanValue: Boolean;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    if (FQuery.RootAO = nil) then
     raise ESQLMemException.Create(12423,ErrorLNilPointer);
    if (LAO = nil) then
     raise ESQLMemException.Create(12426,ErrorLNilPointer);
    FQuery.ExecuteSubQuery;
    if (Operator = doSubquery) then
     InternalGetDataValue(False)
    else
     InternalGetDataValue(True);
  end
  else
  begin
    if (FSourceNode <> nil) then
      InternalGetDataValue(True);
  end;
  Result := FResult;
end; // GetBooleanValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetDataType: TSQLMemAdvancedFieldType;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  Result := FDataType;
end;//GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetDataSize: Integer;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  Result := FDataSize;
end;//GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeSubQuery.Create(aParentExpr);
  TSQLMemExprNodeSubQuery(Result).FQuery := TSQLMemSQLUnion(FQuery.MakeCopy(aParentExpr.Session,aParentExpr.LocalParams));
  if (FSourceNode <> nil) then
   TSQLMemExprNodeSubQuery(Result).FSourceNode := FSourceNode.MakeCopy(aParentExpr)
  else
   TSQLMemExprNodeSubQuery(Result).FSourceNode := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.Assign(Source: TSQLMemExprNode);
begin
  FResultDatasetFieldNo := -1;
  FCorrelated := False;
  FDataType := aftUnknown;
  if (FQuery <> nil) then
   FQuery.Free;
  if (TSQLMemExprNodeSubQuery(Source).FQuery <> nil) then
   FQuery := TSQLMemSQLUnion(TSQLMemExprNodeSubQuery(Source).FQuery.MakeCopy(
      TSQLMemExprNodeSubQuery(Source).FQuery.FDatabaseParams.Session,
      TSQLMemExprNodeSubQuery(Source).FQuery.LParams));
  FNot := TSQLMemExprNodeSubQuery(Source).FNot;
  Operator := TSQLMemExprNodeSubQuery(Source).Operator;
  FComparisonOperator := TSQLMemExprNodeSubQuery(Source).FComparisonOperator;
  FCaseInsensitive  := TSQLMemExprNodeSubQuery(Source).FCaseInsensitive;
  FPartialKey  := TSQLMemExprNodeSubQuery(Source).FPartialKey;
  if (FSourceNode <> nil) then
   FreeAndNil(FSourceNode);
  if (TSQLMemExprNodeSubQuery(Source).FSourceNode <> nil) then
    FSourceNode := TSQLMemExprNode(TSQLMemExprNodeSubQuery(Source).FSourceNode).MakeCopy(LParentExpr);
end; // Assign


//------------------------------------------------------------------------------
// updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.UpdateExpressionParams;
begin
  if (FQuery <> nil) then
  begin
   if (LParentExpr <> nil) then
   begin
    // set paramteres from root expression
    FQuery.LStoredFunction := LParentExpr.StoredFunction;
    FQuery.LParams := LParentExpr.LocalParams;
    if (LParentExpr.Session = nil) then
     FQuery.FDatabaseParams.Session := nil
    else
     LParentExpr.Session.SetDatabaseParams(FQuery.FDatabaseParams);
   end;
   FQuery.UpdateExpressionParams;
  end;
  inherited UpdateExpressionParams;
end; // UpdateExpressionParams
{$ENDIF}




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLCreateView
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLCreateView.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLCreateView.Create(nil,FDatabaseParams,LStoredFunction);
end; // Parse


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemDDLCreateView.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  FColumnNames := nil;
  FIfNotExists := False;
  FWithCheckOption := False;
  FSelectStatement := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemDDLCreateView.Destroy;
begin
  if (FColumnNames <> nil) then
   FreeAndNil(FColumnNames);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateView.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FIfNotExists := TSQLMemDDLCreateView(Source).FIfNotExists;
  FWithCheckOption := TSQLMemDDLCreateView(Source).FWithCheckOption;
  FSelectStatement := TSQLMemDDLCreateView(Source).FSelectStatement;
  if (FColumnNames <> nil) then
   FreeAndNil(FColumnNames);
  if (TSQLMemDDLCreateView(Source).FColumnNames <> nil) then
  begin
   FColumnNames := TSQLMemWideStringList.Create;
   FColumnNames.Assign(TSQLMemDDLCreateView(Source).FColumnNames);
  end;
end; // Assign


//------------------------------------------------------------------------------
// parses query
// CREATE VIEW [IF NOT EXISTS] View_name [(column_1,column_2,...,column_n)]
// AS
// Select_statement
// [WITH CHECK OPTION]
// [COMMENT <NULL | "Comment text"> ]
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateView.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(12585, ErrorGBlankSqlCommand);
  FIfNotExists := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (not IsReservedWord(Token,rwNOT)) then
     raise ESQLMemException.Create(12586, ErrorGOtherTokenExpected,
         ['NOT EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
     FIfNotExists := True;
    end
    else
     raise ESQLMemException.Create(12587, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;

  if (Token.TokenType in [tktString, tktQuotedString,
                tktBackQuotedString, tktBracketedString]) then
  begin
   TableName := Token.Text;
   if (not GetNextToken) then
      raise ESQLMemException.Create(12600,ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
  end
  else
   raise ESQLMemException.Create(12599,ErrorGViewNameExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);

  if (Token.TokenType = tktLeftParenthesis) then
  begin
    if (FColumnNames <> nil) then
     FColumnNames.Clear
    else
     FColumnNames := TSQLMemWideStringList.Create;
    // parse columns
    if (not GetNextToken) then
      raise ESQLMemException.Create(12588, ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
    while (token.TokenType <> tktRightParenthesis) do
    begin
     if (Token.TokenType = tktComma) then
      if (not GetNextToken) then
        raise ESQLMemException.Create(12589, ErrorGUnexpectedEndOfCommand,
              [Token.LineNum, Token.ColumnNum]);
     FColumnNames.Add(Token.Text);
     if (not GetNextToken) then
       raise ESQLMemException.Create(12590, ErrorGUnexpectedEndOfCommand,
              [Token.LineNum, Token.ColumnNum]);
     if ((Token.TokenType <> tktComma) and (Token.TokenType <> tktRightParenthesis)) then
       raise ESQLMemException.Create(12591, ErrorGRightParenthesisOrCommaExpected,
             [Token.Text,Token.LineNum, Token.ColumnNum]);
    end; // while not right parenthesis
    if (not GetNextToken) then
     raise ESQLMemException.Create(12592, ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
    if (FColumnNames <> nil) then
     if (FColumnNames.Count <= 0) then
      FreeAndNil(FColumnNames);
  end; // parse column names
  // AS
  if (Token.ReservedWord <> rwAS)  then
   raise ESQLMemException.Create(12593, ErrorGOtherTokenExpected,
         [GetReservedWord(rwAS),Token.Text,Token.LineNum, Token.ColumnNum]);
  if (not GetNextToken) then
   raise ESQLMemException.Create(12594, ErrorGUnexpectedEndOfCommand,
          [Token.LineNum, Token.ColumnNum]);
  // SELECT
  if (Token.ReservedWord <> rwSELECT)  then
   raise ESQLMemException.Create(12595, ErrorGOtherTokenExpected,
         [GetReservedWord(rwSELECT),Token.Text,Token.LineNum, Token.ColumnNum]);
  FSelectStatement := Token.Text;
  while (GetNextToken) do
  begin
   if (Token.ReservedWord = rwCOMMENT) then
   begin
    ParseComment;
    break;
   end
   else
   if (Token.ReservedWord = rwWITH) then
   begin
     if (not GetNextToken) then
       raise ESQLMemException.Create(12596, ErrorGUnexpectedEndOfCommand,
              [Token.LineNum, Token.ColumnNum]);
     if (Token.ReservedWord = rwCHECK) then
     begin
       if (not GetNextToken) then
         raise ESQLMemException.Create(12597, ErrorGUnexpectedEndOfCommand,
                [Token.LineNum, Token.ColumnNum]);
       if (Token.ReservedWord = rwOPTION) then
        FWithCheckOption := True
       else
        FSelectStatement := FSelectStatement+Space+GetReservedWord(rwWITH)+
                            Space+GetReservedWord(rwCHECK)+Space+Token.Text;
     end
     else
      FSelectStatement := FSelectStatement+Space+GetReservedWord(rwWITH)+Space+Token.Text;
   end
   else
    FSelectStatement := FSelectStatement+Space+Token.Text;
  end;
  inherited;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemDDLCreateView.ExecSQL(
            IsRoot,
            RequestLive:  Boolean;
            var ReadOnly: Boolean
           );
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12598,ErrorLNilPointer);
  if (FIfNotExists) then
   if (FDatabaseParams.Session.TableExists(TableName)) then
    Exit;
  FDatabaseParams.Session.CreateView(TableName,
      FSelectStatement,FColumnNames,FWithCheckOption,FComment);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDDLDropView
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDDLDropView.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDDLDropView.Create(nil,FDatabaseParams,LStoredFunction);
end; // ExecSQL


//------------------------------------------------------------------------------
// asign
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropView.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FCascade := TSQLMemDDLDropView(Source).FCascade;
end; // Assign


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropView.Parse;
begin
  if (not GetNextToken) then
    raise ESQLMemException.Create(12601,ErrorGBlankSQLCommand);
  FCascade := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
    end
    else
     raise ESQLMemException.Create(12602, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
  if (Token.TokenType in [tktString, tktQuotedString,
                tktBackQuotedString, tktBracketedString]) then
  begin
   TableName := Token.Text;
   if (not GetNextToken) then
      raise ESQLMemException.Create(12603,ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
  end
  else
   raise ESQLMemException.Create(12604,ErrorGViewNameExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);
  if (IsReservedWord(Token,rwCASCADE)) then
   begin
    FCascade := True;
    GetNextToken;
   end
  else
  if (IsReservedWord(Token,rwRESTRICT)) then
   GetNextToken;
  inherited;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemDDLDropView.ExecSQL(
            IsRoot,
            RequestLive:  Boolean;
            var ReadOnly: Boolean
           );
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12605,ErrorLNilPointer);
  FDatabaseParams.Session.DropView(TableName,FCascade);
end; // ExecSQL


//------------------------------------------------------------------------------
// set field value from SQLMemVariant
//------------------------------------------------------------------------------
procedure SetSQLMemVariantIntoField(Value: TSQLMemVariant; Field: TField);
var
  s:  AnsiString;
  bs: TStream;
  i:  Integer;
begin
  if Value = nil then
    raise ESQLMemException.Create(30359, ErrorGValueIsNull);

  if (Value.IsNull) then
    Field.Clear
  else
    case Field.DataType of
      ftBlob, ftMemo, ftFmtMemo, ftGraphic:
        begin
          bs := Field.DataSet.CreateBlobStream(Field,bmWrite);
          try
            if (IsBLOBFieldType(Value.DataType)) then
             bs.WriteBuffer(Value.PData^,Value.DataSize)
            else
             begin
              if (IsStringFieldType(Value.DataType)) then
               i := GetStrLength(Value.pData,
                     BaseFieldTypeToAdvancedFieldType(Value.DataType))
              else
               i := Value.DataSize;
              bs.WriteBuffer(Value.PData^,i);
             end;
          finally
            bs.Free;
          end;
        end;
{
      ftMemo,
      ftFmtMemo:
        begin
          if (Value.DataSize <= 1) then
           Field.Clear
          else
           begin
//            SetLength(s, Value.DataSize-1);
//            Value.CopyDataToAddress(PAnsiChar(s));
            Field.AsString := Value.AsString;
           end;
        end;
}
      ftLargeint:
        begin
          TLargeintField(Field).Value := Value.AsInt64;
        end;
      ftDate:
        begin
         Field.AsDateTime := Value.AsTDate;
        end;
      ftTime:
        begin
         Field.AsDateTime := Value.AsTTime;
        end;
      ftDateTime:
        begin
         Field.AsDateTime := Value.AsTDateTime;
        end;

      ftBytes:
        begin
         Field.SetData(Value.pData);
//         Field.AsVariant := Value.AsVariant;
        end;

{$IFDEF D6H}
      ftTimeStamp:
        begin
          TSQLTimeStampField(Field).AsDateTime := Value.AsTDateTime;
        end;
{$ENDIF}
      else
        Field.Value := Value.AsVariant;
    end;
end;//SetSQLMemVariantIntoField


//------------------------------------------------------------------------------
// destroy commands
//------------------------------------------------------------------------------
procedure SQLMemClearCommands(Commands: TList);
var i: Integer;
begin
  for i := 0 to Commands.Count-1 do
   try
     TSQLMemSQLCommand(Commands.Items[i]).Free;
   except
   end;
end; // SQLMemClearCommands


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemSQLProcessor> initialized');
{$ENDIF}

end.
