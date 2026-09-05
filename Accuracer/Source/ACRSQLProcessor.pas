unit ACRSQLProcessor;

{$I ACRVer.inc}

interface

uses Classes, SysUtils, DB,

{$IFDEF DEBUG_LOG}
     ACRDebug,
{$ENDIF}
{$IFDEF D12H}
     ACR_d12h,
{$ENDIF}
     ACRLexer,
     ACRBase,
     ACRRelationalAlgebra,
     ACRTypes,
     ACRExpressions,
     ACRVariant,
     ACRCompression,
     ACRConst,
     ACRConverts,
     ACRComMain,
     ACRExcept;

 type

{ TODO :
create SQL cache manager - to store frequently used table components
to avoid open/close each time new command being executed }

////////////////////////////////////////////////////////////////////////////////
//
// TACRTableReference
//
////////////////////////////////////////////////////////////////////////////////

  // reference to the "table" in FROM clause
  TACRTableReference = class (TObject)
   public
    TableType:        TACRTableType;     // Table | JoinedTable | SubQuery
    SessionName:      AnsiString;             // session name
    DatabaseName:     AnsiString;             // database1
    TableName:        WideString;             // table1
    SubQuerySQL:      WideString;             // SQL text of the sub-query
    Params:           TParams;            // paramas of the query
    Pseudonym:        WideString;             // table1 as t1
    InMemory:         Boolean;            // [MEMORY]
    NaturalJoin:      Boolean;            // Natural join?
    JoinType:         TACRJoinType;      // inner | left | ...
    LeftTable:        TACRTableReference; // left table in join
    RightTable:       TACRTableReference; // right table in join
    UsingFields:      TACRWideStringList; // join column list
    SearchCondition:  TACRExpression;     // ON '(t1.Field1 = t2.Field2)'
    SystemTable:      Boolean;

    // creates
    constructor Create;
    // destroys
    destructor Destroy; override;
    // makes join (left and right node-table)
    procedure MakeJoin(RightNode: TACRTableReference; JType: TACRJoinType;
                     IsNatural: Boolean; Fields: TACRWideStringList;
                     OnCondition: TACRExpression);
    // assign
    procedure Assign(Source: TACRTableReference);
    // update expression params in this node and all children
    procedure UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TACRBaseSession;
                  LParams:          TACRSQLParams
                                    );
  end;//TACRTableReference


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLCommand
// base class for TACRSQLSelect, TACRSQLUpdate, ...
//
////////////////////////////////////////////////////////////////////////////////

   // base class for TACRSQLSelect, TACRSQLUpdate, ...
  TACRSQLCommand = class (TObject)
   protected
    LLex:             TACRLexer; // lexer with expression to parse
    Token:            TToken;    // current token
    RowsAffected:     Integer;
    FReopen:          Boolean;   // reopen mode for ExecSQL
    LParamExprNodes:  TACRList;     // list of all parameter TACRExprNodeConst objects
    LStoredFunction:  TObject;   // TACRStoredFunction - needs for correct parsing of expressions based on local function parameters / variables
//    LSession:         TACRBaseSession; // Session that executes the command
    LParams:          TACRSQLParams; // Local params of TACRStoredFunction
    // table name and database name
    IntoMemory:       Boolean;   // into memory table?  (MEMORY KEYWORD)
    IntoDatabase:     AnsiString;    // select into <database>.<table>
    IntoTable:        WideString;    // select into <database>.<table>
    DatabaseName:     AnsiString;  // database1
    TableName:        WideString;  // Table Name
    TableAlias:       WideString;  // Table Alias: Table123 AS MainTable
    FDatabaseParams:  TACRSQLDatabaseParams;
   private
    // parses list of columns (without table name): field1, field2, ...
    procedure ParseColumnList(var Fields: TACRWideStringList);
    // parses list of fields:  table.field1, field2, ..
    procedure ParseFieldList(var Fields: TACRFields);
    // parse TableName token
    procedure ParseTableNameToken;
    // set InMemory,DatabaseName,TableName to TACRDataset
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
    procedure UpdateParams(SQLParams: TACRSQLParams); virtual;
   private
    // return InMemory if was set in FDatabaseParams
    function GetInMemory: Boolean;
    // return DatabaseName if was set in FDatabaseParams
    function GetDatabaseName: AnsiString;
    // return SessionName if was set in FDatabaseParams
    function GetSessionName: AnsiString;
    // Create ACRTable object and fill ACRTable params
    function CreateInternalACRTable: TDataSet; virtual;
   public
    // creates object
    constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
    function GetResultCursor: TACRCursor; virtual;
    // gets result dataset
    function GetResultDataset: TDataset; virtual;
   protected
    procedure SetDatabaseParams(Session: TACRBaseSession);
    // updates all expressions - sets LSession, LParams (needed for stored functions)
   public
    procedure UpdateExpressionParams; virtual;
    // create new instance of this class
    function CreateCopy: TACRSQLCommand; virtual;
    // assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TACRSQLCommand); virtual;
    // make copy of TACRSQLCommand object
    function MakeCopy(aSession: TACRBaseSession; LocalParams: TACRSQLParams): TACRSQLCommand;
   public
    property DatabaseParams: TACRSQLDatabaseParams read FDatabaseParams write FDatabaseParams;
    property StoredFunction: TObject read LStoredFunction;
//    property Session: TACRBaseSession read LSession;
    property Params: TACRSQLParams read LParams;
  end;//TACRSQLCommand



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLCursorCommand
// base class for SQL command with cursor
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLCursorCommand = class (TACRSQLCommand)
  private
   FLockTablesInWriteMode:			Boolean;
{$IFDEF CORRELATED_SUBQUERIES}
   FSubQuery:                   Boolean;
   FCorrelated:                 Boolean;
{$ENDIF}
  protected
   RootAO:                TACRAO;   // top level AO
   FRequestLive:          Boolean;
   OrderBySpecs:          Array of TACRSortSpecification;
   OrderBySpecsCount:     Integer;
   OrderByIndex:          WideString; // indexName

  protected
    // ORDER BY
   function ParseOrderByClause: Boolean;
   // <sort key> [ <collate clause> ] [ <ordering specification> ]
   function ParseSortSpecification: Boolean;
   // applies Order By clause
   procedure ApplyOrderBy(AO: TACRAO);
  private
   // update parameter values in all expressions
   procedure UpdateParams(SQLParams: TACRSQLParams); override;
  protected
   function CreateCopy: TACRSQLCommand; override;
   procedure AssignOrderBy(Source: TACRSQLCursorCommand);
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
   function BuildAOTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO; virtual; abstract;

   // get result cursor
   function GetResultCursor: TACRCursor; override;
   // get result dataset
   function GetResultDataset: TDataset; override;
  public
   property LockTablesInWriteMode: Boolean read FLockTablesInWriteMode write FLockTablesInWriteMode;
{$IFDEF CORRELATED_SUBQUERIES}
   property SubQuery: Boolean read FSubQuery write FSubQuery;
   property Correlated: Boolean read FCorrelated;
{$ENDIF}
 end;//TACRSQLCursorCommand



////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseSQLProcessor
// used for parsing stored functions or SQL scripts
// created in v.5.10
//
////////////////////////////////////////////////////////////////////////////////


  TACRBaseSQLProcessor = class (TACRSQLProcessor)
   private
    LStoredFunction:        TObject;
    FDefaultDatabaseParams: TACRSQLDatabaseParams;
   protected
    // add SELECT query object
    function AddSelectQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add INSERT query object
    function AddInsertQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add UPDATE query object
    function AddUpdateQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add DELETE query object
    function AddDeleteQuery(Lexer: TACRLexer): TACRSQLCommand;
    // DDL:
    // add CREATE TABLE query object
    function AddCreateTableQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add DROP TABLE query object
    function AddDropTableQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add CREATE VIEW query object
    function AddCreateViewQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add DROP VIEW query object
    function AddDropViewQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add EMPTY TABLE query object
    function AddEmptyTableQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add ALTER TABLE
    function AddAlterTableQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add RENAME TABLE
    function AddRenameTableQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add CREATE INDEX
    function AddCreateIndex(Lexer: TACRLexer): TACRSQLCommand;
    // add DROP INDEX
    function AddDropIndexQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add START TRANSACTION
    function AddStartTransactionQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add COMMIT
    function AddCommitQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add ROLLBACK
    function AddRollbackQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add CREATE DATABASE
    function AddCreateDatabase(Lexer: TACRLexer): TACRSQLCommand;
    // add DROP DATABASE
    function AddDropDatabaseQuery(Lexer: TACRLexer): TACRSQLCommand;
    // add SQL Assign (operator :=)
    function AddSQLAssign(Lexer: TACRLexer): TACRSQLCommand;
    // add CREATE FUNCTION
    function AddCreateFunction(Lexer: TACRLexer): TACRSQLCommand;
    // add DROP FUNCTION
    function AddDropFunction(Lexer: TACRLexer): TACRSQLCommand;
    // add ALTER FUNCTION
    function AddAlterFunction(Lexer: TACRLexer): TACRSQLCommand;
    // add EXECUTE FUNCTION
    function AddExecuteFunction(Lexer: TACRLexer): TACRSQLCommand;
    // add If ... Then ... Else
    function AddIfThenElse(Lexer: TACRLexer): TACRSQLCommand;
    // add BEGIN ... END block
    function AddBeginEndCommandsBlock(Lexer: TACRLexer): TACRSQLCommand;
   public
    // used by TACRStoredFunctionManager.ParseFunctionBody - parse CREATE FUNCTION script
    constructor Create(aStoredFunction: TObject; aSession: TACRBaseSession); overload;
    // used by TACRQuery
    constructor Create(Query: TDataSet); overload;
    destructor Destroy; override;
    function ParseSQLCommand(Lexer: TACRLexer; var Token: TToken): TACRSQLCommand;
   public
    property StoredFunction: TObject read LStoredFunction write LStoredFunction;
    property DefaultDatabaseParams: TACRSQLDatabaseParams read FDefaultDatabaseParams write FDefaultDatabaseParams;
  end; // TACRBaseSQLProcessor

////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalSQLProcessor
// used in TACRQuery for executing SQL scripts
//
////////////////////////////////////////////////////////////////////////////////


  TACRLocalSQLProcessor = class (TACRBaseSQLProcessor)
   private
    FQuery:                 TACRSQLCommand;
    FQueryList:             TList;
   private
    // destroys all queries in the script
    procedure ClearQueryList;
   public
    // used by TACRQuery
    constructor Create(Query: TDataSet; CaseIns: Boolean);
    destructor Destroy; override;

    function OpenQuery(TableNames: TACRWideStringList = nil): TACRCursor; override;
    procedure UpdateParams; override;
    // reset result cursor of Root AO dataset - added in v.6.00 for Views
    procedure ResetRootAOCursorInResultDataset;
  end; // TACRLocalSQLProcessor


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLSelect
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLSelect = class (TACRSQLCursorCommand)
  protected
   Distinct:              Boolean; // ALL | DISTINCT
   TopRowCount:           Integer; // TOP (-1 | n)
   FirstRowNo:            Integer; // TOP row count [, first row]
   AllFields:             Boolean; // Select *
   SelectList:            array of TACRSelectListItem; // fields list
   SelectListCount:       integer; // count of array elements
   FromTables:            array of TACRTableReference; // From clause
   FromTablesCount:       integer; // count of array elements
   SearchCondition:       TACRExpression;  // WHERE clause
   GroupByFields:         TACRFields; // GROUP BY field1, f2, ...
   HavingCondition:       TACRExpression;  // HAVING clause
   FDoNotParseOrderBy:    Boolean; // set by TACRSQLUnion to its children (TACRSQLSelect)

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
   function ParseJoinCondition(var SearchCondition: TACRExpression): Boolean;
   // USING <join columns>
   function ParseNamedColumnsJoin(var Fields: TACRWideStringList): Boolean;
   // CROSS JOIN | INNER JOIN | ...
   function ParseJoin(var tblRef: TACRTableReference): Boolean;
   // <table name> [ [ AS ] <correlation name> ...
   function ParseTableReference(tblRef: TACRTableReference=nil): Boolean;
   // FROM ...
   function ParseFromClause: Boolean;
   // WHERE ...
   function ParseWhereClause: Boolean;
   // GROUP BY ...
   function ParseGroupByClause: Boolean;
   // HAVING ...
   function ParseHavingClause: Boolean;

   // creates and adjusts table AO
   function CreateTableAO(var TableRef: TACRTableReference; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
   // creates and adjusts joined table AO
   function CreateJoinedTableAO(var TableRef: TACRTableReference; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
   // creates and adjusts AO
   function CreateAO(var TableRef: TACRTableReference; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
   // builds one-table AO
   function BuildOneTableTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
   // builds multi-tables AO tree
   function BuildMultiTablesTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;

  protected
   procedure ClearSelectList;
   procedure ClearFromTables;
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TACRSQLCommand; override;
  public
   // assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
{$IFDEF CORRELATED_SUBQUERIES}
   constructor Create(
                      Lexer:              TACRLexer;
                      aDatabaseParams:    TACRSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False;
                      aSubQuery:          Boolean = False
                     );
{$ELSE}
   constructor Create(
                      Lexer:              TACRLexer;
                      aDatabaseParams:    TACRSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False
                     );
{$ENDIF}
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // builds AO tree
   function BuildAOTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO; override;
 end;//TACRSQLSelect




////////////////////////////////////////////////////////////////////////////////
//
// TACRQueryExprNode
//
////////////////////////////////////////////////////////////////////////////////

 // select | union | except | ...
 TACRQueryExprNode = class (TObject)
  NodeType:             TACRQueryExprType;  // node is: select | union | except | ...
  Left:                 TACRQueryExprNode;  // left node in union, except, ...
  Right:                TACRQueryExprNode;  // right table in union, except, ...
  All:                  Boolean;            // [ALL] specified?
  Corresponding:        Boolean;            // [CORRESPONDING] specified?
  CorrespondingFields:  TACRWideStringList; // column list
  SelectCommand:        TACRSQLSelect;      // SELECT command (if NodeType is select)

  // creates
  constructor Create; overload;
  // creates copy
  constructor Create(Src: TACRQueryExprNode); overload;
  // destroys
  destructor Destroy; override;
 protected
  // adds new node to the tree
  procedure AddNode(NewType: TACRQueryExprType; RightNode: TACRQueryExprNode;
                    bAll, bCorresponding: Boolean; ColumnList: TACRWideStringList=nil);
  // return child node with SELECT INTO - needed for UNION, EXCEPT, INTERSECT
  function FindSelectInto: TACRSQLCommand;
  // assign
  procedure Assign(Source: TACRQueryExprNode);
  // update expression params in this node and all children
  procedure UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TACRBaseSession;
                  LParams:          TACRSQLParams
                                    );
end; // TACRQueryExprNode


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLUnion
// UNION SQL command
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLUnion = class (TACRSQLCursorCommand)
  protected
   FRootNode: TACRQueryExprNode;         // root node in unions,excepts tree
   FUnion:    Boolean;                   // set to true if UNION, EXCEPT, INTERSECT parsed

   // parses [ALL]
   function ParseAll: Boolean;

   // parses [ <corresponding spec> ]
   function ParseCorrespondingSpec(var ColumnsList: TACRWideStringList): Boolean;

   // parses SELECT ...
   function ParseQuerySpecification: TACRQueryExprNode;

   // parses <query specification> | <table value constructor>  | <explicit table>
   function ParseSimpleTable: TACRQueryExprNode;

   // parses <simple table> |
   // <left paren> <non-join query expression> <right paren>
   function ParseNonJoinQueryPrimary: TACRQueryExprNode;

   // parses <non-join query primary> |
   // <query term> INTERSECT [ ALL ] [ <corresponding spec> ] <query primary>
   function ParseNonJoinQueryTerm: TACRQueryExprNode;

   // parses <non-join query term> |
   // <query expression> UNION  [ ALL ] [ <corresponding spec> ] <query term> |
   // <query expression> EXCEPT [ ALL ] [ <corresponding spec> ] <query term>
   function ParseNonJoinQueryExpression: TACRQueryExprNode;

   // parses <non-join query expression>  | <joined table>
   function ParseQueryExpression: TACRQueryExprNode;

   // builds AO
   function BuildAO(Node: TACRQueryExprNode; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;

  protected
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
{$IFDEF CORRELATED_SUBQUERIES}
   constructor Create(
                      Lexer:            TACRLexer;
                      aDatabaseParams:  TACRSQLDatabaseParams;
                      aStoredFunction:  TObject;
                      aSubQuery:        Boolean = False
                     );
{$ELSE}
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
{$ENDIF}
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // builds AO tree
   function BuildAOTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO; override;

 end;//TACRSQLUnion



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLInsert
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLInsert = class (TACRSQLCommand)
  protected
   FieldNames:            TACRWideStringList;
   FieldValues:           TACRExpressions;
   InternalSelecter:      TACRSQLCursorCommand;
   FTable:                TDataset;
  protected
   procedure ParseValuesList;
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
  public
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
 end;//TACRSQLInsert



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLUpdate
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLUpdate = class (TACRSQLCommand)
  protected
   FieldNames:            TACRWideStringList;
   FieldValues:           TACRExpressions;
   InternalSelecter:      TACRSQLSelect;
  protected
   // updates all expressions - sets LSession, LParams (needed for stored functions)
   procedure UpdateExpressionParams; override;
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   //clear
   procedure Clear;
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
 end;//TACRSQLUpdate



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLDelete
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLDelete = class (TACRSQLCommand)
  protected
   InternalSelecter:      TACRSQLSelect;
   FullDelete:            Boolean;
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
  public
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
 end;//TACRSQLDelete



////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLTableManipulation
//
////////////////////////////////////////////////////////////////////////////////


 // FieldDef element
 TSQLFieldDef = class (TObject)
  public
   FieldName:                WideString;       // field name or pseudonym

   // FieldType
   newFieldType:             Boolean;
      FieldType:             TACRAdvancedFieldType;

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
      BlobCompressionAlgorithm: TACRCompressionAlgorithm;// {NONE | ZLIB | BZIP | PPM}

   newBlobCompressionMode:   Boolean;
      BlobCompressionMode:   Byte; //     {0 .. 9}

   //Default Value
   newDefaultValue:          Boolean;
      DefaultValue:          TACRVariant;

   newMinValue:              Boolean;
      MinValue:              TACRVariant;

   newMaxValue:              Boolean;
      MaxValue:              TACRVariant;

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


 TACRIndexField = record
   FieldName: WideString;       // field name or pseudonym
   desc:      Boolean;      // desc/asc
   nocase:    Boolean;      // ncase/case sensitive
 end;


 TACRDDLTableManipulation = class (TACRSQLCommand)
  protected
   FForeignKeyDefs:       TObject;
   SQLFieldDefs:          TSQLFieldDefs; // SQLFieldDefs
   PrimaryIndexName:      WideString;
   PrimaryKeyFields:      array of TACRIndexField;
   UniqueFields:          TACRWideStringList;
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

   // Create ACRTable object and fill ACRTable params
   function CreateInternalACRTable: TDataSet; override;
   // Fill AdvFieldDef
   procedure FillAdvFieldDef(AdvFieldDef: TFieldDef; SQLFieldDef: TSQLFieldDef);
   // Add Primary Key into ACRTable
   procedure AddPrimaryKey(T: TDataSet);
   // Add UNIQUE constraint and index into ACRTable
   procedure AddUnique(T: TDataSet);
   // Delete PrimaryKey
   procedure DeletePrimaryKey(T: TDataSet);
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
   // destroy
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
 end;//TACRDDLTableManipulation




////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLCreateTable
//
////////////////////////////////////////////////////////////////////////////////



 TACRDDLCreateTable = class (TACRDDLTableManipulation)
  private
   FIfNotExists: Boolean;
  protected
   // Create Table
   procedure CreateTable;
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLCreateTable


////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLDropTable
//
////////////////////////////////////////////////////////////////////////////////


 TACRDDLDropTable = class (TACRDDLTableManipulation)
  private
   FCascade:  Boolean;
  protected
   // Drop Table
   procedure DropTable;
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLDropTable



////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLEmptyTable
//
////////////////////////////////////////////////////////////////////////////////


 TACRDDLEmptyTable = class (TACRDDLTableManipulation)
  private
   FIfExists: Boolean;
  protected
   // Empty Table
   procedure EmptyTable;
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLEmptyTable



////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLAlterTable
//
////////////////////////////////////////////////////////////////////////////////


 TACRDDLAlterTable = class (TACRDDLTableManipulation)
  protected
   // AlterType token
   AlterType:                  TAlterType;
   DropColumnNamesList:        TACRWideStringList;
   RenameColumnOldNamesList:   TACRWideStringList;
   RenameColumnNewNamesList:   TACRWideStringList;
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
   procedure ModifyComment(Session: TACRBaseSession);
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
 end;//TACRDDLAlterTable


////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLRenameTable
//
////////////////////////////////////////////////////////////////////////////////

 TACRDDLRenameTable = class (TACRDDLAlterTable)
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
 end;
 

////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLCreateIndex
//
////////////////////////////////////////////////////////////////////////////////

 TACRDDLCreateIndex = class (TACRSQLCommand)
  protected
   Unique:          Boolean;
   IfNotExists:     Boolean;
   IndexName:       WideString;
   ACRIndexFields:  array of TACRIndexField; // Index Fields
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLCreateIndex



////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLDropIndex
//
////////////////////////////////////////////////////////////////////////////////


 TACRDDLDropIndex = class (TACRSQLCommand)
  protected
   IfExists:  Boolean;
   IndexName: WideString;
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLDropIndex


////////////////////////////////////////////////////////////////////////////////
//
// TACRStartTransaction
//
////////////////////////////////////////////////////////////////////////////////


 TACRStartTransaction = class (TACRSQLCommand)
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRStartTransaction


////////////////////////////////////////////////////////////////////////////////
//
// TACRCommit
//
////////////////////////////////////////////////////////////////////////////////


 TACRCommit = class (TACRSQLCommand)
  private
   FFlushFileBuffers: Boolean;
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRCommit




////////////////////////////////////////////////////////////////////////////////
//
// TACRRollback
//
////////////////////////////////////////////////////////////////////////////////


 TACRRollback = class (TACRSQLCommand)
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRRollback




////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseManagement
//
////////////////////////////////////////////////////////////////////////////////


 TACRDatabaseManagement = class (TACRSQLCommand)
  protected
   FInMemory:                 Boolean;
   FDatabaseName:             AnsiString;
   FDatabaseFileName:         AnsiString;
   FDatabaseFileNameUnicode:  WideString;
   FMaxSessionsCount:         Integer;
   FPageSize:                 Integer;
   FPassword:                 AnsiString;
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
  public
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
   destructor Destroy; override;
 end;// TACRDatabaseManagement




////////////////////////////////////////////////////////////////////////////////
//
// TACRCreateDatabase
//
////////////////////////////////////////////////////////////////////////////////


 TACRCreateDatabase = class (TACRDatabaseManagement)
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;// TACRCreateDatabase




////////////////////////////////////////////////////////////////////////////////
//
// TACRDropDatabase
//
////////////////////////////////////////////////////////////////////////////////


 TACRDropDatabase = class (TACRDatabaseManagement)
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   // parse query
   procedure Parse; override;
   // execute query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;// TACRDropDatabase


{$IFDEF CORRELATED_SUBQUERIES}
////////////////////////////////////////////////////////////////////////////////
//
// TACRExprNodeSubQuery
//
// base class for all sub-query classes
//
////////////////////////////////////////////////////////////////////////////////


  // expression node SubQuery
  TACRExprNodeSubQuery = class (TACRExprNode)
  protected
    FResult: Boolean;
  private
    FQuery:                     TACRSQLUnion;
    FNot:                       Boolean;  // NOT option for IN or EXISTS
    FSourceNode:                TACRExprNode; // source node for IN
    FDataType:                  TACRAdvancedFieldType;
    FBaseType:                  TACRBaseFieldType;
    FDataSize:                  Integer;
    FQueryResult:               Boolean;
    FCorrelated:                Boolean;
    LAO:                        TACRAO;
    FResultFieldNo:             Integer;
    FResultDatasetFieldNo:      Integer;
    FComparisonOperator:        TACRDataOperator;
  protected
    procedure DetectType;
    procedure InternalGetDataValue(BooleanResult: Boolean); virtual;
    function GetCorrelated: Boolean;
  public
    constructor Create(
                       aParentExpr:           TACRExpression;
                       Operator:              TACRDataOperator;
                       aQuery:                TACRSQLUnion;
                       bNot:                  Boolean = False;
                       SourceNode:            TACRExprNode = nil;
                       aComparisonOperator:   TACRDataOperator = doEQ;
                       CaseInsensitive:       Boolean = true;
                       PartialKey:            Boolean = false
                      ); overload;
    // destroy
    destructor Destroy; override;
    // process assign AO
    procedure AssignAO(AO: TACRAO); override;
    // process assign Cursor
    procedure AssignCursor(Cursor: TACRCursor); override;
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TACRRecordBuffer); override;
    // return Data Value
    function GetDataValue: TACRVariant; override;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  override;
    // return Data Type
    function GetDataType: TACRAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TACRExpression): TACRExprNode; override;
   public
    // assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TACRExprNode); override;
    // updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
    procedure UpdateExpressionParams; override;
   public
    property Correlated: Boolean read GetCorrelated;
  end; // TACRExprNodeSubQuery
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLCreateView
//
////////////////////////////////////////////////////////////////////////////////


 TACRDDLCreateView = class (TACRDDLTableManipulation)
  private
   FIfNotExists:      Boolean;
   FWithCheckOption:  Boolean;
   FColumnNames:      TACRWideStringList;
   FSelectStatement:  WideString;
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   // creates object
   constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
   // destroy
   destructor Destroy; override;
   procedure Assign(Source: TACRSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLCreateView


////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLDropView
//
////////////////////////////////////////////////////////////////////////////////


 TACRDDLDropView = class (TACRDDLTableManipulation)
  private
   FCascade:  Boolean;
  protected
   function CreateCopy: TACRSQLCommand; override;
  public
   procedure Assign(Source: TACRSQLCommand); override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                     ); override;
 end;//TACRDDLDropView


// set field value from ACRVariant
procedure SetACRVariantIntoField(Value: TACRVariant; Field: TField);
// destroy commands
procedure ACRClearCommands(Commands: TList);


implementation


uses  Math
      ,ACRMain
      ,ACRStoredFunctions
      ;




////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseSQLProcessor
// used for parsing stored functions
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// adds SELECT query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddSelectQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRSQLUnion.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;// AddSelectQuery


//------------------------------------------------------------------------------
// adds INSERT query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddInsertQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRSQLInsert.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddInsertQuery


//------------------------------------------------------------------------------
// adds UPDATE query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddUpdateQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRSQLUpdate.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddUpdateQuery


//------------------------------------------------------------------------------
// adds DELETE query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddDeleteQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRSQLDelete.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddDeleteQuery


//------------------------------------------------------------------------------
// adds CREATE TABLE query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddCreateTableQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDDLCreateTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddCreateTableQuery


//------------------------------------------------------------------------------
// adds DROP TABLE query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddDropTableQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDDLDropTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddDropTableQuery


//------------------------------------------------------------------------------
// add CREATE VIEW query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddCreateViewQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDDLCreateView.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddCreateViewQuery


//------------------------------------------------------------------------------
// add DROP VIEW query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddDropViewQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDDLDropView.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddDropViewQuery


//------------------------------------------------------------------------------
// add EMPTY TABLE query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddEmptyTableQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDDLEmptyTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddEmptyTableQuery


//------------------------------------------------------------------------------
// add ALTER TABLE query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddAlterTableQuery;
begin
  Result := TACRDDLAlterTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddAlterTableQuery


//------------------------------------------------------------------------------
// add RENAME TABLE
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddRenameTableQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDDLRenameTable.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddRenameTableQuery


//------------------------------------------------------------------------------
// add CREATE INDEX query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddCreateIndex;
begin
  Result := TACRDDLCreateIndex.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddCreateIndex


//------------------------------------------------------------------------------
// add DROP INDEX query object
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddDropIndexQuery;
begin
  Result := TACRDDLDropIndex.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end;//AddDropIndexQuery


//------------------------------------------------------------------------------
// add START TRANSACTION
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddStartTransactionQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRStartTransaction.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddStartTransactionQuery


//------------------------------------------------------------------------------
// add COMMIT
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddCommitQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRCommit.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddCommitQuery


//------------------------------------------------------------------------------
// add ROLLBACK
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddRollbackQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRRollback.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddRollbackQuery


//------------------------------------------------------------------------------
// add CREATE DATABASE
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddCreateDatabase(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRCreateDatabase.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddCreateDatabase


//------------------------------------------------------------------------------
// add DROP DATABASE
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddDropDatabaseQuery(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDropDatabase.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddDropDatabaseQuery


//------------------------------------------------------------------------------
// add SQL Assign (operator :=)
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddSQLAssign(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRSQLAssign.Create(Lexer, FDefaultDatabaseParams, LStoredFunction);
end; // AddSQLAssign


//------------------------------------------------------------------------------
// add CREATE FUNCTION
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddCreateFunction(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRCreateStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddCreateFunction


//------------------------------------------------------------------------------
// add DROP FUNCTION
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddDropFunction(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRDropStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddDropFunction


//------------------------------------------------------------------------------
// add ALTER FUNCTION
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddAlterFunction(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRAlterStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddAlterFunction


//------------------------------------------------------------------------------
// add EXECUTE FUNCTION
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddExecuteFunction(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRExecuteStoredFunction.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddExecuteFunction


//------------------------------------------------------------------------------
// add If ... Then ... Else
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddIfThenElse(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRSQLIfThenElse.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddIfThenElse


//------------------------------------------------------------------------------
// add BEGIN ... END block
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.AddBeginEndCommandsBlock(Lexer: TACRLexer): TACRSQLCommand;
begin
  Result := TACRRSQLBeginEndCommandsBlock.Create(Lexer,FDefaultDatabaseParams,LStoredFunction);
end; // AddBeginEndCommandsBlock


//------------------------------------------------------------------------------
// constructor Create
// used by TACRStoredFunctionManager.ParseFunctionBody - parse CREATE FUNCTION script
//------------------------------------------------------------------------------
constructor TACRBaseSQLProcessor.Create(aStoredFunction: TObject; aSession: TACRBaseSession);
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
// used by TACRQuery
//------------------------------------------------------------------------------
constructor TACRBaseSQLProcessor.Create(Query: TDataSet);
begin
  inherited Create(Query);
  LStoredFunction := nil;
  FDefaultDatabaseParams.Session := nil;
  if (Query <> nil) then
   if (Query is TACRQuery) then
    FDefaultDatabaseParams.Session := TACRDataset(Query).GetBaseSession;
  if (Query <> nil) then
   begin
    FDefaultDatabaseParams.ParamsSet := True;
    FDefaultDatabaseParams.InMemory := TACRQuery(Query).InMemory;
    FDefaultDatabaseParams.DatabaseName := TACRQuery(Query).DatabaseName;
    FDefaultDatabaseParams.SessionName := TACRQuery(Query).SessionName;
    FDefaultDatabaseParams.Params := TACRQuery(Query).Params;
    FDefaultDatabaseParams.RequestLive := TACRQuery(Query).RequestLive;
    FDefaultDatabaseParams.CaseInsensitive := TACRQuery(Query).CaseInsensitive;
   end
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRBaseSQLProcessor.Destroy;
begin
  ACRClearString(FDefaultDatabaseParams.DatabaseName);
  ACRClearString(FDefaultDatabaseParams.SessionName);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// return SQL command if it parsed successfully
// otherwise raise exception
//------------------------------------------------------------------------------
function TACRBaseSQLProcessor.ParseSQLCommand(Lexer: TACRLexer; var Token: TToken): TACRSQLCommand;
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
                      raise EACRException.Create(30147, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                else raise EACRException.Create(30148, ErrorGUnexpectedEndOfCommand,
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
                     raise EACRException.Create(30149, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                else raise EACRException.Create(30150, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwEMPTY:   // EMPTY
              begin
                if Lexer.GetNextToken(Token) then
                begin
                 if (IsReservedWord(Token,rwTABLE)) then
                  Result := AddEmptyTableQuery(Lexer)
                 else
                   raise EACRException.Create(12459, ErorrGObjectTypeKeywordExpected,
                         [Token.Text, Token.LineNum, Token.ColumnNum]);
                end
                else raise EACRException.Create(12460, ErrorGUnexpectedEndOfCommand,
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
                      raise EACRException.Create(30151, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);

                  end
                else
                  raise EACRException.Create(30152, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwRENAME:   // RENAME
              begin
                if (not Lexer.GetNextToken(Token)) then
                  raise EACRException.Create(30353, ErrorGUnexpectedEndOfCommand,
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
                     raise EACRException.Create(12176, ErorrGObjectTypeKeywordExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                else raise EACRException.Create(12177, ErrorGUnexpectedEndOfCommand,
                          [Token.LineNum, Token.ColumnNum]);
              end;
    rwIF:     // IF ... THEN  .. ELSE ...
              Result := AddIfThenElse(Lexer);
    rwBEGIN:  // BEGIN ... END;
              Result := AddBeginEndCommandsBlock(Lexer);
   else       // unsupported SQL or unexpected token
      raise EACRException.Create(30153, ErrorGSQLCommandExpected,
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
       raise EACRException.Create(30154, ErrorGSQLCommandExpected,
                           [Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
  end;
end; // ParseSQLCommand




////////////////////////////////////////////////////////////////////////////////
//
// TACRLocalSQLProcessor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// destroys all queries in the script
//------------------------------------------------------------------------------
procedure TACRLocalSQLProcessor.ClearQueryList;
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
      TACRSQLCommand(FQueryList.Items[i]).Free;
     except
     end;
    FQueryList.Free;
    FQueryList := nil;
   end;
end; // ClearQueryList


//------------------------------------------------------------------------------
// constructor
// used by TACRQuery
//------------------------------------------------------------------------------
constructor TACRLocalSQLProcessor.Create(Query: TDataSet; CaseIns: Boolean);
begin
  // commented in v.6.00 - for views
//  if (Query = nil) then
//   raise EACRException.Create(12098,ErrorLNilPointer);
  inherited Create(Query);
  FQuery := nil;
  FQueryList := nil;
  FCaseInsensitive := CaseIns;
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRLocalSQLProcessor.Destroy;
begin
  ClearQueryList;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// OpenQuery
//------------------------------------------------------------------------------
function TACRLocalSQLProcessor.OpenQuery(TableNames: TACRWideStringList): TACRCursor;
var
  Token:          TToken;
  Lexer:          TACRLexer;
  i:              Integer;

  function GetOpenQueryResult: TACRCursor;
  begin
    FRowsAffected := RowsAffected + FQuery.RowsAffected;
    Result := FQuery.GetResultCursor;
    if (Result <> nil) then
    begin
      Result.InternalFirst;
      // added in v.6.00 for Views
      if (TableNames <> nil) then
       if (FQuery is TACRSQLCursorCommand) then
        TACRSQLCursorCommand(FQuery).RootAO.GetTableNames(FDefaultDatabaseParams.Session,TableNames);
    end;
  end; // GetOpenQueryResult

begin
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter;
aaStartTime;
try
{$ENDIF}
  // params will be updated in the following base OpenQuery call
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('> TACRLocalSQLProcessor.OpenQuery'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FNeverOpened = '+BoolToStr(FNeverOpened,True)
+#13#10+'SQLParams.Count = '+IntToStr(FSQLParams.Count)
);
{$ENDIF}
  Result := inherited OpenQuery;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 1.'
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
    Lexer := TACRLexer.Create(SqlText, SQLParams);
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaStopTime(time8);
{$ENDIF}
    try
     Lexer.StartSaveScript;
     try
       // Parse and Execute queries from SQL script
       while Lexer.GetNextCommand do
        begin
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 2.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
         if (SQLParams.Count <= 0) then
          if (FQuery <> nil) then
           begin
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 3.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
            FQuery.Free;
            FQuery := nil;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 4.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
           end;
         // Parse current command
         // look at first token
         if (not Lexer.GetCurrentToken(Token)) then
          raise EACRException.Create(30146, ErrorGBlankSqlCommand);
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 5.'
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 6.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
         if (SQLParams.Count > 0) then
          FQueryList.Add(FQuery);
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 7.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
         Result := GetOpenQueryResult;
         // FQuery added to list - will be destroyed from list
         if (SQLParams.Count > 0) then
          FQuery := nil;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 8.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
        end; // Parse and Execute queries
      FNeverOpened := False;
      // stored in FQuery
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 9.'
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('3 TACRLocalSQLProcessor.OpenQuery Error:'
+#13#10+e.Message
+#13#10+'Self = '+IntToHex(Integer(Self),8)
);
{$ENDIF}
         ClearQueryList;
         FNeverOpened := True;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('4 TACRLocalSQLProcessor.OpenQuery Error:'
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 10.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
+#13#10+'Lexer = '+IntToHex(Integer(Lexer),8)
);
{$ENDIF}
      Lexer.Free;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 11.'
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 12.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
);
{$ENDIF}
     for i := 0 to FQueryList.Count-1 do
      begin
        FQuery := TACRSQLCommand(FQueryList.Items[i]);
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 13.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
        FQuery.Reopen(FRequestLive,FReadonly);
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 14.'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'FQueryList.Count = '+IntToStr(FQueryList.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FQuery = '+IntToHex(Integer(FQuery),8)
);
{$ENDIF}
        Result := GetOpenQueryResult;
        FQuery := nil;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('TACRLocalSQLProcessor.OpenQuery 15.'
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('1 TACRLocalSQLProcessor.OpenQuery Error:'
+#13#10+e.Message
+#13#10+'Self = '+IntToHex(Integer(Self),8)
);
{$ENDIF}
         FQuery := nil;
         ClearQueryList;
         FNeverOpened := True;
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('2 TACRLocalSQLProcessor.OpenQuery Error:'
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
{$IFDEF DEBUG_TRACE_TACRLocalSQLProcessor_OpenQuery}
aaWriteToLog('< TACRLocalSQLProcessor.OpenQuery.'
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
procedure TACRLocalSQLProcessor.UpdateParams;
var
  i:      Integer;
begin
  for i := 0 to FQueryList.Count-1 do
   TACRSQLCommand(FQueryList.Items[i]).UpdateParams(SQLParams);
  inherited;
end; // UpdateParams


//------------------------------------------------------------------------------
// reset result cursor of Root AO dataset - added in v.6.00 for Views
//------------------------------------------------------------------------------
procedure TACRLocalSQLProcessor.ResetRootAOCursorInResultDataset;
begin
  if (FQuery = nil) then
   if (FQueryList.Count > 0) then
     FQuery := TACRSQLCommand(FQueryList.Items[FQueryList.Count-1]);
  if (FQuery <> nil) then
   if (FQuery is TACRSQLCursorCommand) then
    TACRSQLCursorCommand(FQuery).RootAO.ResetRootAOCursorInResultDataset;
end; // ResetRootAOCursorInResultDataset




////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLSelect
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
function TACRSQLSelect.ParseGetToken: Boolean;
begin
  Result := IsReservedWord(Token, rwGET);
  if (not Result) then
   // unsupported SQL or unexpected token
   raise EACRException.Create(11979, ErrorGSQLCommandExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;
  if (not IsReservedWord(Token,rwTABLES)) then
   raise EACRException.Create(11978, ErrorGOtherTokenExpected,
         ['TABLES', Token.Text, Token.LineNum, Token.ColumnNum]);
  AllFields := True;
  FromTablesCount := 1;
  SetLength(FromTables,FromTablesCount);
  FromTables[0] := TACRTableReference.Create;
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
function TACRSQLSelect.ParseSelectToken: Boolean;
begin
  Result := IsReservedWord(Token, rwSELECT);
  if (not Result) then
   // unsupported SQL or unexpected token
   raise EACRException.Create(30156, ErrorGSQLCommandExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;
end;//ParseSelectToken


//------------------------------------------------------------------------------
// DISTINCT | ALL ?
//------------------------------------------------------------------------------
function TACRSQLSelect.ParseSetQuantifier: Boolean;
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
function TACRSQLSelect.ParseTopOperator: Boolean;
begin
  if (IsReservedWord(Token, rwTOP)) then
   begin
    // suppose 'TOP n'
    GetNextToken;
    // integer?
    if (Token.TokenType <> tktInt) then
     raise EACRException.Create(30158, ErrorGIntegerExpected,
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
         raise EACRException.Create(30159, ErrorGIntegerExpected,
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
function TACRSQLSelect.ParseSelectSubList: Boolean;
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
   SelectList[SelectListCount-1].ValueExpr := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
   TACRExpression(SelectList[SelectListCount-1].ValueExpr).Params :=
      FDatabaseParams.Params;
   TACRExpression(SelectList[SelectListCount-1].ValueExpr).InMemory :=
      GetInMemory;
   TACRExpression(SelectList[SelectListCount-1].ValueExpr).SessionName :=
      GetSessionName;
   TACRExpression(SelectList[SelectListCount-1].ValueExpr).DatabaseName :=
      GetDatabaseName;
   TACRExpression(SelectList[SelectListCount-1].ValueExpr).CaseInsensitive :=
      FDatabaseParams.CaseInsensitive;
   TACRExpression(SelectList[SelectListCount-1].ValueExpr).ParseForValueExpression(LLex);

   if (TACRExpression(SelectList[SelectListCount-1].ValueExpr).IsEmpty) then
    begin
     SelectList[SelectListCount-1].ValueExpr.Free;
     raise EACRException.Create(30160, ErrorGExpressionExpected,
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
   SelectList[SelectListCount-1].IsExpression := not TACRExpression(SelectList[SelectListCount-1].ValueExpr).IsField;

   // field?
   if (not SelectList[SelectListCount-1].IsExpression) then
    begin
     // get field name, table name
     TACRExpression(SelectList[SelectListCount-1].ValueExpr).GetFieldInfo(TableName, FieldName);
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
     TACRExpression(SelectList[SelectListCount-1].ValueExpr).Free;
     TACRExpression(SelectList[SelectListCount-1].ValueExpr) := nil;
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
function TACRSQLSelect.ParseSelectList: Boolean;
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
         raise EACRException.Create(30163, ErrorGFieldNameExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
     until False
    else
     raise EACRException.Create(30164, ErrorGFieldListExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
end;//ParseSelectList


//------------------------------------------------------------------------------
// INTO <target>
//------------------------------------------------------------------------------
function TACRSQLSelect.ParseInto: Boolean;
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
function TACRSQLSelect.ParseJoinCondition(var SearchCondition: TACRExpression): Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwON)) then
   begin
    Result := True;
    GetNextToken; // skip ON token
    SearchCondition := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
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
function TACRSQLSelect.ParseNamedColumnsJoin(var Fields: TACRWideStringList): Boolean;
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
     raise EACRException.Create(30167, ErrorGOtherTokenExpected,
                   ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
end;// ParseNamedColumnsJoin


//------------------------------------------------------------------------------
// CROSS JOIN | INNER JOIN | ...
//------------------------------------------------------------------------------
function TACRSQLSelect.ParseJoin(var tblRef: TACRTableReference): Boolean;
var
 RightTblRef:     TACRTableReference;
 JoinType:        TACRJoinType;
 IsNatural:       Boolean;
 Fields:          TACRWideStringList;
 SearchCondition: TACRExpression;
 JoinCondition:   TACRExpression;
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
       raise EACRException.Create(30175, ErrorGOtherTokenExpected,
                 ['JOIN', Token.Text, Token.LineNum, Token.ColumnNum])
      else
       exit; // no joins
     GetNextToken;

     // get right table ref
     RightTblRef := TACRTableReference.Create;
     if not ParseTableReference(RightTblRef) then
      raise EACRException.Create(30176, ErrorGTableNameExpected,
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
function TACRSQLSelect.ParseTableReference(tblRef: TACRTableReference): Boolean;
var
  DatabaseName:         AnsiString;
  TableName, Pseudonym: WideString;
  TableType:            TACRTableType;
  InMemory:             Boolean;
  tRef:                 TACRTableReference;
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
      DatabaseName := ACRMemoryDatabaseName;
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
     FromTables[FromTablesCount-1] := TACRTableReference.Create;
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
       raise EACRException.Create(11656,ErrorLSubQueryInvalidStatement,[Token.Text]);
      // sub-query
      n := 1;
      if (tblRef = nil) then
       begin
         Inc(FromTablesCount);
         SetLength(FromTables, FromTablesCount);
         FromTables[FromTablesCount-1] := TACRTableReference.Create;
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
       raise EACRException.Create(11657,ErrorGMissingRightParenthesis,[Token.LineNum,Token.ColumnNum]);
      tRef.SubQuerySQL := s;
      // skip ')'
      // fixed in v.5.80
      GetNextToken;
//      if (not GetNextToken) then
//       raise EACRException.Create(11658,ErrorGMissingRightParenthesis,[Token.LineNum,Token.ColumnNum]);
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
       raise EACRException.Create(30179, ErrorGFieldNameExpected,
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
function TACRSQLSelect.ParseFromClause: Boolean;
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
        raise EACRException.Create(30182, ErrorGTableNameExpected,
                  [Token.Text, Token.LineNum, Token.ColumnNum]);
     until False
    else
      raise EACRException.Create(30183, ErrorGTableNameExpected,
                  [Token.Text, Token.LineNum, Token.ColumnNum]);
  end
 else
   raise EACRException.Create(30184, ErrorGOtherTokenExpected,
                ['FROM', Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseFromClause


//------------------------------------------------------------------------------
// WHERE ...
//------------------------------------------------------------------------------
function TACRSQLSelect.ParseWhereClause: Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwINTO)) then
   raise EACRException.Create(11337, ErrorLTokenINTOShouldBeBeforeFROM,
                [Token.LineNum, Token.ColumnNum]);
 if (IsReservedWord(Token, rwWHERE)) then
  begin
    Result := True;
    // skip WHERE token
    GetNextToken;
    SearchCondition := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
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
function TACRSQLSelect.ParseGroupByClause: Boolean;
begin
 if (IsReservedWord(Token, rwGROUP)) then
  begin
    Result := True;
    // skip GROUP token
    GetNextToken;
    // 'BY'?
    if (not IsReservedWord(Token, rwBY)) then
     raise EACRException.Create(30185, ErrorGOtherTokenExpected,
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
function TACRSQLSelect.ParseHavingClause: Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwHAVING)) then
  begin
    Result := True;
    // skip HAVING token
    GetNextToken;
    HavingCondition := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
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
procedure TACRSQLSelect.Parse;
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
      raise EACRException.Create(30155, ErrorGBlankSqlCommand);

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
function TACRSQLSelect.CreateTableAO(var TableRef: TACRTableReference; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
var
  DatabaseName: AnsiString;
begin
  DatabaseName := TableRef.DatabaseName;
  if (DatabaseName = '') then
    DatabaseName := GetDatabaseName;

  try
    Result := TACRAOTable.Create(
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
function TACRSQLSelect.CreateJoinedTableAO(var TableRef: TACRTableReference; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
var
 LeftAO, RightAO: TACRAO;
 FieldList1, FieldList2: TACRFields;
 i: integer;
 Item1, Item2: TACRSelectListItem;

function RecursiveExtractJoinConditions(TableRef: TACRTableReference): integer;
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
      FieldList1 := TACRFields.Create;
      FieldList2 := TACRFields.Create;
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
      FieldList1 := TACRFields.Create;
      FieldList2 := TACRFields.Create;
      // extract from ON clause
      RecursiveExtractJoinConditions(TableRef);
      // extract from WHERE clause
      if (SearchCondition <> nil) then
       SearchCondition.ExtractJoinConditions(LeftAO, RightAO,
                                       FieldList1, FieldList2);
    end
  end;

  // create join AO
  Result := TACRAOJoin.Create(Session, Params,
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
       raise EACRException.Create(12230, ErorrGNotApplicableCondition);
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
function TACRSQLSelect.CreateAO(var TableRef: TACRTableReference; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
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
function TACRSQLSelect.BuildOneTableTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
begin
  // create AO
  Result := CreateAO(FromTables[0],Session,Params);
end;// BuildOneTableTree


//------------------------------------------------------------------------------
// builds multi-tables AO tree
//------------------------------------------------------------------------------
function TACRSQLSelect.BuildMultiTablesTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
var
  i, JoinConditionCount: integer;
  RightAO: TACRAO;
  JoinType: TACRJoinType;
  FieldList1, FieldList2: TACRFields;
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
       FieldList1 := TACRFields.Create;
       FieldList2 := TACRFields.Create;
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
    Result := TACRAOJoin.Create(Session, Params, Result, RightAO, JoinType, False,
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
procedure TACRSQLSelect.ClearSelectList;
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
procedure TACRSQLSelect.ClearFromTables;
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
procedure TACRSQLSelect.UpdateExpressionParams;
var i:    Integer;
    expr: TACRExpression;
begin
  for i := 0 to SelectListCount-1 do
   begin
    expr := TACRExpression(SelectList[i].ValueExpr);
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
function TACRSQLSelect.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLSelect.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TACRSQLSelect.Assign(Source: TACRSQLCommand);
var i: Integer;
begin
  inherited Assign(Source);
  Distinct := TACRSQLSelect(Source).Distinct;
  TopRowCount := TACRSQLSelect(Source).TopRowCount;
  FirstRowNo := TACRSQLSelect(Source).FirstRowNo;
  AllFields := TACRSQLSelect(Source).AllFields;
  SelectListCount := TACRSQLSelect(Source).SelectListCount;
  if (Length(SelectList) > 0) then
   ClearSelectList;
  SetLength(SelectList,SelectListCount);
  if (SelectListCount > 0) then
    for i := 0 to SelectListCount-1 do
     begin
      if (TACRSQLSelect(Source).SelectList[i].ValueExpr = nil) then
       SelectList[i].ValueExpr := nil
      else
       begin
        SelectList[i].ValueExpr := TACRExpression.Create;
        TACRExpression(SelectList[i].ValueExpr).Assign(
          TACRExpression(TACRSQLSelect(Source).SelectList[i].ValueExpr));
       end;
      SelectList[i].TableName := TACRSQLSelect(Source).SelectList[i].TableName;
      SelectList[i].AllFields := TACRSQLSelect(Source).SelectList[i].AllFields;
      SelectList[i].FieldName := TACRSQLSelect(Source).SelectList[i].FieldName;
      SelectList[i].IsExpression := TACRSQLSelect(Source).SelectList[i].IsExpression;
      SelectList[i].Pseudonym := TACRSQLSelect(Source).SelectList[i].Pseudonym;
     end;
  if (Length(FromTables) > 0) then
   ClearFromTables;
  FromTablesCount := TACRSQLSelect(Source).FromTablesCount;
  SetLength(FromTables,FromTablesCount);
  if (FromTablesCount > 0) then
    for i := 0 to FromTablesCount-1 do
     begin
      FromTables[i] := TACRTableReference.Create;
      FromTables[i].Assign(TACRSQLSelect(Source).FromTables[i]);
     end;
  if (SearchCondition <> nil) then
   FreeAndNil(SearchCondition);
  if (TACRSQLSelect(Source).SearchCondition <> nil) then
   begin
    SearchCondition := TACRExpression.Create;
    SearchCondition.Assign(TACRSQLSelect(Source).SearchCondition);
   end;
 GroupByFields.Clear;
 if (TACRSQLSelect(Source).GroupByFields <> nil) then
  begin
   GroupByFields.Assign(TACRSQLSelect(Source).GroupByFields);
  end;
 if (HavingCondition <> nil) then
   FreeAndNil(HavingCondition);
 if (TACRSQLSelect(Source).HavingCondition <> nil) then
   begin
    HavingCondition := TACRExpression.Create;
    HavingCondition.Assign(TACRSQLSelect(Source).HavingCondition);
   end;
 FDoNotParseOrderBy := TACRSQLSelect(Source).FDoNotParseOrderBy;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
{$IFDEF CORRELATED_SUBQUERIES}
constructor TACRSQLSelect.Create(
                      Lexer:              TACRLexer;
                      aDatabaseParams:    TACRSQLDatabaseParams;
                      aStoredFunction:    TObject;
                      DoNotParseOrderBy:  Boolean = False;
                      aSubQuery:          Boolean = False
                     );
{$ELSE}
constructor TACRSQLSelect.Create(
                      Lexer:              TACRLexer;
                      aDatabaseParams:    TACRSQLDatabaseParams;
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
  GroupByFields := TACRFields.Create;
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
destructor TACRSQLSelect.Destroy;
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
function TACRSQLSelect.BuildAOTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
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
       if (TACRExpression(SelectList[i].ValueExpr).IsAggregated) then
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
     Result := TACRAOGroupBy.Create(Session, Params, Result, GroupByFields);
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
     Result := TACRAOSQLTopRowCount.Create(Result);
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
           raise EACRException.Create(12428, ErorrGNotApplicableCondition);
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
       raise EACRException.Create(30144, ErorrGNotApplicableCondition);
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
// TACRSQLCommand
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLCommand.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  // will be created on first UpdateParams call
  LParamExprNodes := nil;
  {$IFDEF TRIAL_VERSION}
  {$IFNDEF TRIAL_VERSION_WITH_FULL_SQL}
   if ((not (Self is TACRSQLCursorCommand)) and
       (not (Self is TACRSQLSelect)) and (not (Self is TACRSQLUnion))) then
    begin
     acrtrshnm;
     raise EACRException.Create(10844,ErrorLCannotExecuteThisSQLStatementInTrialVersion);
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
destructor TACRSQLCommand.Destroy;
begin
  if (LParamExprNodes <> nil) then
  begin
   LParamExprNodes.Free;
   LParamExprNodes := nil;
  end;
  ACRClearString(FDatabaseParams.DatabaseName);
  ACRClearString(FDatabaseParams.SessionName);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TACRSQLCommand.Parse;
begin
;
end; // Parse


//------------------------------------------------------------------------------
// parses list of columns (without table name): field1, field2, ...
//------------------------------------------------------------------------------
procedure TACRSQLCommand.ParseColumnList(var Fields: TACRWideStringList);

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
     Fields := TACRWideStringList.Create;
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
     raise EACRException.Create(10407,ErrorLFieldNameExpected,
      [Token.Text, Token.LineNum, Token.ColumnNum]);
   until (False)
  else
   raise EACRException.Create(10408, ErrorLFieldNameExpected,
    [Token.Text, Token.LineNum, Token.ColumnNum]);
end; // ParseColumnList


//------------------------------------------------------------------------------
// parses list of fields:  table.field1, field2, ..
//------------------------------------------------------------------------------
procedure TACRSQLCommand.ParseFieldList(var Fields: TACRFields);

function ParseFieldSpecification(var Fields: TACRFields): Boolean;
var
   item: TACRSelectListItem;
   TableName, FieldName: WideString;
   Expr: TACRExpression;
begin
 Result := True;
 // parse field as expression
 Expr := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
 try
  Expr.InMemory := GetInMemory;
  Expr.DatabaseName := GetDatabaseName;
  Expr.SessionName := GetSessionName;
  Expr.CaseInsensitive := FDatabaseParams.CaseInsensitive;
  Expr.ParseForValueExpression(LLex);
  // only field is allowed
  if (not Expr.IsField) then
   raise EACRException.Create(10409, ErrorLFieldNameExpected,
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
        raise EACRException.Create(10411, ErrorLFieldNameExpected,
                  [Token.Text, Token.LineNum, Token.ColumnNum]);
     until False
    else
      raise EACRException.Create(10412, ErrorLFieldNameExpected,
          [Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseFieldList


//------------------------------------------------------------------------------
// parse TableName token
//------------------------------------------------------------------------------
procedure TACRSQLCommand.ParseTableNameToken;
begin
  if not (Token.TokenType in [tktString, tktQuotedString, tktBackQuotedString, tktReservedWord, tktBracketedString]) then
    raise EACRException.Create(30230, ErrorGTableNameExpected,
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
// set InMemory,DatabaseName,TableName to TACRDataset
//------------------------------------------------------------------------------
procedure TACRSQLCommand.SetTableNameParams(t: TDataset);
begin
 if (t <> nil) then
  if (t is TACRDataset) then
   begin
    TACRDataset(t).InMemory := GetInMemory or IntoMemory;
    if (DatabaseName <> '') then
     TACRDataset(t).DatabaseName := DatabaseName
    else
    if (not IntoMemory) then
     TACRDataset(t).DatabaseName := GetDatabaseName;
    if (t is TACRTable) then
     TACRTable(t).TableName := TableName;
    // commented in v.5.60
//   if (GetSessionName <> '') and  (TACRDataset(t).DatabaseName = GetDatabaseName) then
      TACRDataset(t).SessionName := GetSessionName;
     //TACRDataset(t).Password := Password;
   end;
end; // SetTableNameParams


//------------------------------------------------------------------------------
// get current token
//------------------------------------------------------------------------------
function TACRSQLCommand.GetCurrentToken: Boolean;
begin
 Result := LLex.GetCurrentToken(Token);
end;// GetCurrentToken


//------------------------------------------------------------------------------
// get next token
//------------------------------------------------------------------------------
function TACRSQLCommand.GetNextToken: Boolean;
begin
 Result := LLex.GetNextToken(Token);
end;//GetNextToken


//------------------------------------------------------------------------------
// get next token
//------------------------------------------------------------------------------
function TACRSQLCommand.GetNextToken(PermittedTypes: TTokenTypes;
  NativeErrorCode: integer; ErrorText: AnsiString): Boolean;
begin
  // get next token
  Result := LLex.GetNextToken(Token);
  if (not Result) then
   if (NativeErrorCode <> -1) then
      raise EACRException.Create(30161, ErrorGUnexpectedEndOfCommand,
                                 [Token.LineNum, Token.ColumnNum]);
  // check token type
  if (Result) then
   if (PermittedTypes <> []) then
    if (not (Token.TokenType in PermittedTypes)) then
     if (NativeErrorCode <> -1) then
       raise EACRException.Create(NativeErrorCode, ErrorText,
                                 [Token.Text, Token.LineNum, Token.ColumnNum])
      else
         Result := False;
end;//GetNextToken


//------------------------------------------------------------------------------
// re-open parametrized query
//------------------------------------------------------------------------------
procedure TACRSQLCommand.Reopen(
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
procedure TACRSQLCommand.UpdateParams(SQLParams: TACRSQLParams);
var i,Index: Integer;
    Node:    TACRExprNodeConst;
begin
  if (LParamExprNodes <> nil) then
   for i := 0 to LParamExprNodes.Count-1 do
    begin
     Node := TACRExprNodeConst(LParamExprNodes.Items[i]);
     Index := SQLParams.FindByNameCRC(Node.ParamCRC);
     if (Index >= 0) then
      Node.SetDataValue(SQLParams.Items[Index]);
    end;
end; // UpdateParams


//------------------------------------------------------------------------------
// return InMemory if was set in FDatabaseParams
//------------------------------------------------------------------------------
function TACRSQLCommand.GetInMemory: Boolean;
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
function TACRSQLCommand.GetDatabaseName: AnsiString;
begin
  if (FDatabaseParams.ParamsSet and (DatabaseName = '')) then
   Result := FDatabaseParams.DatabaseName
  else
   Result := DatabaseName;
end; // GetDatabaseName


//------------------------------------------------------------------------------
// return SessionName if was set in FDatabaseParams
//------------------------------------------------------------------------------
function TACRSQLCommand.GetSessionName: AnsiString;
begin
  if (FDatabaseParams.ParamsSet) then
   Result := FDatabaseParams.SessionName
  else
   Result := '';
end; // GetSessionName


//------------------------------------------------------------------------------
// Create ACRTable object and fill ACRTable params
//------------------------------------------------------------------------------
function TACRSQLCommand.CreateInternalACRTable: TDataSet;
begin
  Result := TACRTable.Create(nil);
  SetTableNameParams(Result);
end;//CreateInternalACRTable


//------------------------------------------------------------------------------
// get result cursor
//------------------------------------------------------------------------------
function TACRSQLCommand.GetResultCursor: TACRCursor;
begin
  Result := nil;
end;//GetResultCursor


//------------------------------------------------------------------------------
// gets result dataset
//------------------------------------------------------------------------------
function TACRSQLCommand.GetResultDataset: TDataset;
begin
  Result := nil;
end;// GetResultDataset


//------------------------------------------------------------------------------
// set database params
//------------------------------------------------------------------------------
procedure TACRSQLCommand.SetDatabaseParams(Session: TACRBaseSession);
begin
  if (Session = nil) then
   raise EACRException.Create(12183,ErrorLNilPointer);
  Session.SetDatabaseParams(FDatabaseParams); 
end; // SetDatabaseParams


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TACRSQLCommand.UpdateExpressionParams;
begin
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRSQLCommand.CreateCopy: TACRSQLCommand;
begin
  Result := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TACRSQLCommand.Assign(Source: TACRSQLCommand);
begin
  if (Source = nil) then
    raise EACRException.Create(12184,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise EACRException.Create(12185,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  // table name and database name
  IntoMemory := Source.IntoMemory;
  IntoDatabase := Source.IntoDatabase;
  IntoTable := Source.IntoTable;
  DatabaseName := Source.DatabaseName;
  TableName := Source.TableName;
end; // Assign


//------------------------------------------------------------------------------
// make copy of TACRSQLCommand object
//------------------------------------------------------------------------------
function TACRSQLCommand.MakeCopy(aSession: TACRBaseSession; LocalParams: TACRSQLParams): TACRSQLCommand;
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
// TACRQueryExprNode
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRQueryExprNode.Create;
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
constructor TACRQueryExprNode.Create(Src: TACRQueryExprNode);
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
destructor TACRQueryExprNode.Destroy;
begin
 if (Left <> nil) then
  Left.Free;
 if (Right <> nil) then
  Right.Free;

 if (SelectCommand <> nil) then
  SelectCommand.Free;
end;// Destroy

procedure TACRQueryExprNode.AddNode(NewType: TACRQueryExprType;
  RightNode: TACRQueryExprNode; bAll, bCorresponding: Boolean;
  ColumnList: TACRWideStringList);
var
  LeftNode: TACRQueryExprNode;
begin
  // copy current node to left
  LeftNode := TACRQueryExprNode.Create(Self);

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
function TACRQueryExprNode.FindSelectInto: TACRSQLCommand;
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
procedure TACRQueryExprNode.Assign(Source: TACRQueryExprNode);
begin
  if (Source = nil) then
    raise EACRException.Create(12194,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise EACRException.Create(12195,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  if (Left <> nil) then
   FreeAndNil(Left);
  if (Right <> nil) then
   FreeAndNil(Right);
  NodeType := Source.NodeType;
  if (Source.Left <> nil) then
   begin
    Left := TACRQueryExprNode.Create;
    Left.Assign(Source.Left);
   end;
  if (Source.Right <> nil) then
   begin
    Right := TACRQueryExprNode.Create;
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
     CorrespondingFields := TACRWideStringList.Create;
    CorrespondingFields.Assign(Source.CorrespondingFields);
   end;
  if (SelectCommand <> nil) then
   FreeAndNil(SelectCommand);
  if (Source.SelectCommand <> nil) then
   begin
    SelectCommand := TACRSQLSelect.Create(nil,
        Source.SelectCommand.FDatabaseParams,Source.SelectCommand.LStoredFunction);
    SelectCommand.Assign(Source.SelectCommand);
   end;
end; // Assign


//------------------------------------------------------------------------------
// update expression params in this node and all children
//------------------------------------------------------------------------------
procedure TACRQueryExprNode.UpdateExpressionParams(
                LStoredFunction:  TObject;
                LSession:         TACRBaseSession;
                LParams:          TACRSQLParams
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
// TACRSQLUnion
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// parses [ALL]
//------------------------------------------------------------------------------
function TACRSQLUnion.ParseAll: Boolean;
begin
  Result := IsReservedWord(Token, rwALL);
  // skip token
  if (Result) then
   GetNextToken;
end;//ParseAll


//------------------------------------------------------------------------------
// parses [ <corresponding spec> ]
//------------------------------------------------------------------------------
function TACRSQLUnion.ParseCorrespondingSpec(var ColumnsList: TACRWideStringList): Boolean;
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
        raise EACRException.Create(30193, ErrorGOtherTokenExpected,
                    ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
   end;
end;// ParseCorrespondingSpec


//------------------------------------------------------------------------------
// parses SELECT ...
//------------------------------------------------------------------------------
function TACRSQLUnion.ParseQuerySpecification: TACRQueryExprNode;
var
  SelectNode: TACRQueryExprNode;
begin
  if (IsReservedWord(Token, rwSELECT) or IsReservedWord(Token, rwGET)) then
   begin
    SelectNode := TACRQueryExprNode.Create;
    SelectNode.NodeType := qetSelect;
    try
     // modified in v.5.01
{$IFDEF CORRELATED_SUBQUERIES}
     SelectNode.SelectCommand := TACRSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction, FUnion, FSubQuery);
{$ELSE}
     SelectNode.SelectCommand := TACRSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction, FUnion);
{$ENDIF}
     GetCurrentToken;
    except
     SelectNode.Free;
     raise;
    end;
    Result := SelectNode;
   end
  else
   raise EACRException.Create(30194, ErrorGOtherTokenExpected,
              ['SELECT', Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseQuerySpecification


//------------------------------------------------------------------------------
// parses <query specification> | <table value constructor>  | <explicit table>
//------------------------------------------------------------------------------
function TACRSQLUnion.ParseSimpleTable: TACRQueryExprNode;
begin
  Result := ParseQuerySpecification;
end;// ParseSimpleTable


//------------------------------------------------------------------------------
// parses <simple table> |
// <left paren> <non-join query expression> <right paren>
//------------------------------------------------------------------------------
function TACRSQLUnion.ParseNonJoinQueryPrimary: TACRQueryExprNode;
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
function TACRSQLUnion.ParseNonJoinQueryTerm: TACRQueryExprNode;
var
  RightNode: TACRQueryExprNode;
  bAll, bCorresponding: Boolean; // union or except
  ColumnList: TACRWideStringList; // corresponding spec
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
function TACRSQLUnion.ParseNonJoinQueryExpression: TACRQueryExprNode;
var
  RightNode:            TACRQueryExprNode;
  bAll, bCorresponding: Boolean; // union or except
  ColumnList:           TACRWideStringList; // corresponding spec
  NewType:              TACRQueryExprType;
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
function TACRSQLUnion.ParseQueryExpression: TACRQueryExprNode;
begin
  Result := ParseNonJoinQueryExpression;
end;// ParseQueryExpression


//------------------------------------------------------------------------------
// parses query
// SELECT INTO must be the first
//------------------------------------------------------------------------------
procedure TACRSQLUnion.Parse;
var Node: TACRSQLCommand;
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
function TACRSQLUnion.BuildAO(Node: TACRQueryExprNode; Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
var
  LeftAO, RightAO:      TACRAO;
  UnionType:            TACRUnionType;
  CorrespondingFields:  TACRFields;
  Item:                 TACRSelectListItem;
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
      CorrespondingFields := TACRFields.Create;
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
     Result := TACRAOUnion.Create(Session, Params,
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
procedure TACRSQLUnion.UpdateExpressionParams;
begin
  FRootNode.UpdateExpressionParams(LStoredFunction,FDatabaseParams.Session,LParams);
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRSQLUnion.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLUnion.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLUnion.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  if (FRootNode <> nil) then
   FreeAndNil(FRootNode);
  if (TACRSQLUnion(Source).FRootNode <> nil) then
   begin
    FRootNode := TACRQueryExprNode.Create;
    FRootNode.Assign(TACRSQLUnion(Source).FRootNode);
   end;
  FUnion := TACRSQLUnion(Source).FUnion;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
{$IFDEF CORRELATED_SUBQUERIES}
constructor TACRSQLUnion.Create(
                      Lexer:            TACRLexer;
                      aDatabaseParams:  TACRSQLDatabaseParams;
                      aStoredFunction:  TObject;
                      aSubQuery:        Boolean = False
                               );
{$ELSE}
constructor TACRSQLUnion.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
destructor TACRSQLUnion.Destroy;
begin
  if (FRootNode <> nil) then
    FRootNode.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// builds AO tree
//------------------------------------------------------------------------------
function TACRSQLUnion.BuildAOTree(Session: TACRBaseSession; Params: TACRSQLParams): TACRAO;
begin
  Result := BuildAO(FRootNode,Session,Params);
  ApplyOrderBy(Result);
end;// BuildAOTree




////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLCursorCommand
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// <sort key> [ <collate clause> ] [ <ordering specification> ]
//------------------------------------------------------------------------------
function TACRSQLCursorCommand.ParseSortSpecification: Boolean;
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
   raise EACRException.Create(30187, ErrorGFieldNameExpected,
                        [Token.Text, Token.LineNum, Token.ColumnNum]);
end;// ParseSortSpecification


//------------------------------------------------------------------------------
// ORDER BY
//------------------------------------------------------------------------------
function TACRSQLCursorCommand.ParseOrderByClause: Boolean;
begin
 if (IsReservedWord(Token, rwORDER)) then
  begin
    Result := True;
    // skip ORDER token
    GetNextToken;
    // 'BY'?
    if (not IsReservedWord(Token, rwBY)) then
     raise EACRException.Create(30188, ErrorGOtherTokenExpected,
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
          raise EACRException.Create(30190, ErrorGSortSpecificationExpected,
                          [Token.Text, Token.LineNum, Token.ColumnNum]);

       until False
      else
        raise EACRException.Create(30191, ErrorGSortSpecificationExpected,
                          [Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
  end
 else
  Result := False;
end;// ParseOrderByClause


//------------------------------------------------------------------------------
// applies Order By clause
//------------------------------------------------------------------------------
procedure TACRSQLCursorCommand.ApplyOrderBy(AO: TACRAO);
begin
  if ((OrderBySpecsCount > 0) or (OrderByIndex <> '')) then
   begin
     AO.SetOrderBy(OrderBySpecs,OrderBySpecsCount,OrderByIndex);
   end;
end;// ApplyOrderBy


//------------------------------------------------------------------------------
// update parameter values in all expressions
//------------------------------------------------------------------------------
procedure TACRSQLCursorCommand.UpdateParams(SQLParams: TACRSQLParams);
begin
  if (LParamExprNodes = nil) and (RootAO <> nil) then
    LParamExprNodes := RootAO.ParamNodes;
  inherited;
end; // UpdateParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRSQLCursorCommand.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLCursorCommand.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign order by
//------------------------------------------------------------------------------
procedure TACRSQLCursorCommand.AssignOrderBy(Source: TACRSQLCursorCommand);
var i,l: Integer;
begin
 if (Source <> nil) then
   if (Source.OrderBySpecsCount > 0) then
   begin
    l := Length(TACRSQLCursorCommand(Source).OrderBySpecs);
    SetLength(OrderBySpecs,l);
    if (l > 0) then
      for i := 0 to l-1 do
       begin
        OrderBySpecs[i].TableName := TACRSQLCursorCommand(Source).OrderBySpecs[i].TableName;
        OrderBySpecs[i].ColumnName := TACRSQLCursorCommand(Source).OrderBySpecs[i].ColumnName;
        OrderBySpecs[i].ColumnNumber := TACRSQLCursorCommand(Source).OrderBySpecs[i].ColumnNumber;
        OrderBySpecs[i].Descending := TACRSQLCursorCommand(Source).OrderBySpecs[i].Descending;
        OrderBySpecs[i].CaseInsensitive := TACRSQLCursorCommand(Source).OrderBySpecs[i].CaseInsensitive;
       end;
    OrderBySpecsCount := TACRSQLCursorCommand(Source).OrderBySpecsCount;
    OrderByIndex := TACRSQLCursorCommand(Source).OrderByIndex;
   end;
end; // AssignOrderBy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLCursorCommand.Assign(Source: TACRSQLCommand);
begin
  if (Source = nil) then
   Exit;
  inherited Assign(Source);
  if (TACRSQLCursorCommand(Source).RootAO = nil) then
   begin
    if (RootAO <> nil) then
      FreeAndNil(RootAO);
   end
  else
   begin
    if (RootAO <> nil) then
      FreeAndNil(RootAO);
//    RootAO := TACRSQLCursorCommand(Source).RootAO.MakeCopy;
   end;
  FRequestLive := TACRSQLCursorCommand(Source).FRequestLive;
  AssignOrderBy(TACRSQLCursorCommand(Source));
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLCursorCommand.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
destructor TACRSQLCursorCommand.Destroy;
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
procedure TACRSQLCursorCommand.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                      );
var
  dest:       TACRTable;
  log:        AnsiString;

begin
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('> TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('1 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
    if (RootAO <> nil) then
     RootAO.Free;
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('2 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('3 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
+#13#10+'IsRoot = '+BoolToStr(IsRoot,True)
+#13#10+'RequestLive = '+BoolToStr(RequestLive,True)
+#13#10+'ReadOnly = '+BoolToStr(ReadOnly,True)
);
{$ENDIF}
   end;
  try
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('4 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('5 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
          IntoDatabase := ACRMemoryDatabaseName
         else
          IntoDatabase := GetDatabaseName;
       end;
      RootAO.SetResultTable(IntoMemory,IntoTable,IntoDatabase);
     end;

{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('6 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('7 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
       ReadOnly := TACRDataSet(RootAO.ResultDataset).Handle.IsTemporaryTable;
      TACRDataSet(RootAO.ResultDataset).Handle.ReadOnly := ReadOnly;
     end;
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('8 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
        dest:= TACRTable.Create(nil);
        dest.TableName := IntoTable;
        dest.InMemory := IntoMemory or TACRDataset(query).InMemory;
        if (dest.InMemory) then
          dest.DatabaseName := ACRMemoryDatabaseName
        else
         dest.DatabaseName := TACRDataset(query).DatabaseName;
        if (not dest.ImportTable(RootAO.ResultDataset,log)) then
          raise EACRException.Create(10403,ErrorLImportTableCannotCopyData,[log]);
      finally
       dest.Free;
      end;
     end;
}
  finally
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('9 TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecSQL}
aaWriteToLog('< TACRSQLCursorCommand.ExecSQL. Self.ClassName = '+Self.ClassName
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
function TACRSQLCursorCommand.PrepareSubQuery(bIn: Boolean): Boolean;
var
    OrderBySpecs:          array of TACRSortSpecification;
    OrderBySpecsCount:     integer;
begin
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_PrepareSubQuery}
aaWriteToLog('> TACRSQLCursorCommand.PrepareSubQuery. Self.ClassName = '+Self.ClassName);
try
{$ENDIF}
    if (RootAO <> nil) then
     RootAO.Free;
    RootAO := BuildAOTree(FDatabaseParams.Session,LParams);
    if (RootAO = nil) then
     raise EACRException.Create(12424,ErrorLNilPointer);
    RootAO.SetupSubQuery;
//    if (RootAO.FilterExpr <> nil) then
//     TACRExpression(RootAO.FilterExpr).AssignAO(RootAO);
    Result := RootAO.FindExternalFieldNodes;
    if (IntoTable <> '') then
     begin
  // commneted in 4.95
  //      if (not IntoMemory) then
      if (IntoDatabase = '') then
       begin
         if (IntoMemory) then
          IntoDatabase := ACRMemoryDatabaseName
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
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_PrepareSubQuery}
aaWriteToLog('< TACRSQLCursorCommand.PrepareSubQuery. Self.ClassName = '+Self.ClassName);
except
 on e: Exception do
 begin
   aaWriteToLog('Error in TACRSQLCursorCommand.PrepareSubQuery. Self.ClassName = '+Self.ClassName+', Error: '+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // PrepareSubQuery


//------------------------------------------------------------------------------
// execute sub-query
//------------------------------------------------------------------------------
procedure TACRSQLCursorCommand.ExecuteSubQuery;
begin
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecuteSubQuery}
aaWriteToLog('> TACRSQLCursorCommand.ExecuteSubQuery. Self.ClassName = '+Self.ClassName);
try
{$ENDIF}
  if (RootAO = nil) then
   raise EACRException.Create(12426,ErrorLNilPointer);
  RootAO.LockTable(False);
  try
    // calculate values of the external field nodes
    RootAO.SetExternalFieldValues;
    if (RootAO.IsMaterialized) then
     RootAO.RestartMaterialization := True;
    RootAO.Execute(True);
    if (RootAO.ResultDataset = nil) then
     raise EACRException.Create(12427,ErrorLNilPointer);
  finally
    RootAO.UnlockTable;
  end;
{$IFDEF DEBUG_TRACE_TACRSQLCursorCommand_ExecuteSubQuery}
aaWriteToLog('< TACRSQLCursorCommand.ExecuteSubQuery. Self.ClassName = '+Self.ClassName);
except
 on e: Exception do
 begin
   aaWriteToLog('Error in TACRSQLCursorCommand.ExecuteSubQuery. Self.ClassName = '+Self.ClassName+', Error: '+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // ExecuteSubQuery
{$ENDIF}


//------------------------------------------------------------------------------
// get result cursor
//------------------------------------------------------------------------------
function TACRSQLCursorCommand.GetResultCursor: TACRCursor;
begin
  Result := TACRDataSet(RootAO.ResultDataset).Handle;
end;//GetResultCursor


//------------------------------------------------------------------------------
// get result dataset
//------------------------------------------------------------------------------
function TACRSQLCursorCommand.GetResultDataset: TDataset;
begin
 Result := RootAO.ResultDataset;
end;// GetResultDataset



////////////////////////////////////////////////////////////////////////////////
//
// TACRTableReference
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRTableReference.Create;
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
destructor TACRTableReference.Destroy;
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
procedure TACRTableReference.MakeJoin(RightNode: TACRTableReference; JType: TACRJoinType;
                 IsNatural: Boolean; Fields: TACRWideStringList;
                 OnCondition: TACRExpression);
var
 LeftNode: TACRTableReference;
begin
 // copy current node to left
 LeftNode := TACRTableReference.Create;
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
procedure TACRTableReference.Assign(Source: TACRTableReference);
begin
  if (Source = nil) then
    raise EACRException.Create(12189,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise EACRException.Create(12190,ErrorLErrorInAssignInvalidClass,
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
    LeftTable := TACRTableReference.Create;
    LeftTable.Assign(Source.LeftTable);
   end;
  if (Source.RightTable <> nil) then
   begin
    RightTable := TACRTableReference.Create;
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
     UsingFields := TACRWideStringList.Create;
    UsingFields.Assign(Source.UsingFields);
   end;
  if (SearchCondition <> nil) then
   FreeAndNil(SearchCondition);
  if (Source.SearchCondition <> nil) then
   begin
    SearchCondition := TACRExpression.Create;
    SearchCondition.Assign(Source.SearchCondition);
   end;
  SystemTable := Source.SystemTable;
end; // Assign


//------------------------------------------------------------------------------
// update expression params in this node and all children
//------------------------------------------------------------------------------
procedure TACRTableReference.UpdateExpressionParams(
                  LStoredFunction:  TObject;
                  LSession:         TACRBaseSession;
                  LParams:          TACRSQLParams
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
// TACRSQLInsert
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// ParseValuesList
//------------------------------------------------------------------------------
procedure TACRSQLInsert.ParseValuesList;
var Expr: TACRExpression;
begin
  // '('?
  if Token.TokenType <> tktLeftParenthesis then
    Exit;

  // list...
  repeat
    if (not GetNextToken) then
      raise EACRException.Create(30203, ErrorGUnexpectedEndOfCommand,
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
      raise EACRException.Create(30357, ErrorGParseParameterError,
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
procedure TACRSQLInsert.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to FieldValues.Count-1 do
   begin
    TACRExpression(FieldValues.Items[i]).StoredFunction := LStoredFunction;
    TACRExpression(FieldValues.Items[i]).LocalParams := LParams;
    TACRExpression(FieldValues.Items[i]).Session := FDatabaseParams.Session;
   end;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRSQLInsert.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLInsert.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLInsert.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FieldNames.Assign(TACRSQLInsert(Source).FieldNames);
  FieldValues.Assign(TACRSQLInsert(Source).FieldValues);
  if (InternalSelecter <> nil) then
    FreeAndNil(InternalSelecter);
  if (TACRSQLInsert(Source).InternalSelecter <> nil) then
   begin
    InternalSelecter := TACRSQLUnion.Create(nil,FDatabaseParams,LStoredFunction);
    InternalSelecter.Assign(TACRSQLInsert(Source).InternalSelecter);
   end;
  if (FTable <> nil) then
   FreeAndNil(FTable);
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLInsert.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  FieldNames := TACRWideStringList.Create;
  FieldValues := TACRExpressions.Create;
  InternalSelecter := nil;
  FTable := nil;
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRSQLInsert.Destroy;
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
procedure TACRSQLInsert.Parse;
begin
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    LParamExprNodes := TACRList.Create;
  if not GetCurrentToken then
    raise EACRException.Create(30204, ErrorGBlankSqlCommand);

  if (not GetNextToken) then
    raise EACRException.Create(30205, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  // INTO
  if not IsReservedWord(Token, rwINTO) then
    raise EACRException.Create(30206, ErrorGOtherTokenExpected,
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
          raise EACRException.Create(02156, ErrorGFieldNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);

        //GetNextToken(02073);
        FieldNames.Add(Token.Text);

        GetNextToken([tktComma, tktRightParenthesis],
                     30212, ErrorGRightParenthesisOrCommaExpected);
      until Token.TokenType = tktRightParenthesis;
      // ')'
      if (not GetNextToken) then
        raise EACRException.Create(30213, ErrorGUnexpectedEndOfCommand,
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
      InternalSelecter := TACRSQLUnion.Create(LLex,FDatabaseParams,LStoredFunction);
//      InternalSelecter := TACRSQLSelect.Create(LLex, LQuery);
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TACRSQLInsert.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                );
var
   i:         Integer;
   ds:        TDataSet;
   s:         AnsiString;
   FieldNo:   Integer;
   Data:      TACRVariant;
   RecCount:  Integer;
begin
{ TODO : VERSION 6 - REMOVE REOPENING THE TABLE in all cases, optimize copying fields }
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('> TACRSQLInsert.ExecSQL. FTable = '+IntToHex(Integer(FTable),8));
{$ENDIF}
{$IFDEF DEBUG_TRACE_SQL_TIME}
aaIncCounter(counter2);
aaStartTime(time2);
try
{$ENDIF}
  RowsAffected := 0;
  if (FTable = nil) then
   begin
    FTable := CreateInternalACRTable as TACRTable;
    try
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('1 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
);
{$ENDIF}
      TACRTable(FTable).Open;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('2 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
);
{$ENDIF}
    except
      try
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('3 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
);
{$ENDIF}
       TACRTable(FTable).Free;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('4 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
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
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('5 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
);
{$ENDIF}
            TACRTable(FTable).Insert;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('6 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
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
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('7 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'Field name = '+FieldNames[i]
);
{$ENDIF}
                   FieldNo := TACRTable(FTable).Fields.IndexOf(
                                TACRTable(FTable).Fields.FieldByName(FieldNames[i]));
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('8 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'Field name = '+FieldNames[i]
+#13#10+'FieldNo = '+IntToStr(FieldNo)
);
{$ENDIF}
                   end;

                Data := TACRExpression(FieldValues[i]).GetValue;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('9 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'Data.IsNull = '+BoolToStr(Data.IsNull,True)
+#13#10+'Data.DataType = '+IntToStr(Integer(Data.DataType))
);
{$ENDIF}
                if (Data <> nil) then
                 begin
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('10 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'Data.IsNull = '+BoolToStr(Data.IsNull,True)
+#13#10+'Data.DataType = '+IntToStr(Integer(Data.DataType))
);
{$ENDIF}
                  SetACRVariantIntoField(Data, TACRTable(FTable).Fields.Fields[FieldNo]);
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('11 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i)
+#13#10+'FieldNo = '+IntToStr(FieldNo)
+#13#10+'Data.IsNull = '+BoolToStr(Data.IsNull,True)
+#13#10+'Data.DataType = '+IntToStr(Integer(Data.DataType))
);
{$ENDIF}
                 end
                else
                  raise EACRException.Create(30356, ErrorGParameterValueUndefined,
                        [FieldNames[i], AftToStr(FieldTypeToACRAdvFieldType(
                         TACRTable(FTable).Fields.FieldByName(FieldNames[i]).DataType))]);
              end; // for fields
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('12 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
);
{$ENDIF}
              TACRTable(FTable).Post;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('13 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
);
{$ENDIF}
            except
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('14 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
);
{$ENDIF}
              TACRTable(FTable).Cancel;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('15 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
);
{$ENDIF}
              raise;
            end;
        Inc(RowsAffected);
      end
    else
      begin
        InternalSelecter.FReopen := FReopen;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('16 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
);
{$ENDIF}
        InternalSelecter.ExecSQL(IsRoot, False, ReadOnly);
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('17 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
);
{$ENDIF}
        ds := InternalSelecter.GetResultDataset;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('18 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
);
{$ENDIF}
        RecCount := TACRTable(FTable).RecordCount;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('19 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
+#13#10+'RecCount = '+IntToStr(RecCount)
);
{$ENDIF}
        // fixed in v.5.80 - fiedl map by numbers
        s := CopyDatasets(ds,FTable,True,tbopCopy,False,FieldNames);
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('19 TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'FReopen = '+BoolToStr(FReopen,true)
+#13#10+'RecCount = '+IntToStr(RecCount)
+#13#10+'TACRTable(FTable).RecordCount = '+IntToStr(TACRTable(FTable).RecordCount)
+#13#10+'s: '+#13#10+s
);
{$ENDIF}
        if (s <> '') then
         raise EACRException.Create(11350,ErrorLInsertSelectFailed,[TACRTable(FTable).TableName,s]);
        RowsAffected := TACRTable(FTable).RecordCount - RecCount;
      end; // insert from select
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('< TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected)
);
{$ENDIF}
  finally
//   if ((FTable <> nil) and (LParamExprNodes = nil)) then
{ TODO -oLeo :
to Version 5 - change it to cursor and make cache for such operations
However it should be compatible with exclusive operations on other
TACRTable components like EmptyTable - cached cursors should be ignored }
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('<< TACRSQLInsert.ExecSQL.'
+#13#10+'DatabaseName = '+TACRTable(FTable).DatabaseName
+#13#10+'SessionName = '+TACRTable(FTable).SessionName
+#13#10+'TableName = '+TACRTable(FTable).TableName
+#13#10+'InMemory = '+BoolToStr(TACRTable(FTable).InMemory,true)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected)
+#13#10+'FTable = '+IntToHex(Integer(FTable),8)
);
{$ENDIF}
   if (FTable <> nil) then
    begin
      TACRTable(FTable).Close;
      TACRTable(FTable).Free;
      FTable := nil;
{$IFDEF TACRSQLInsert_ExecSQL}
aaWriteToLog('<<< TACRSQLInsert.ExecSQL.'
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
// TACRSQLUpdate
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TACRSQLUpdate.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to FieldValues.Count-1 do
   begin
    TACRExpression(FieldValues.Items[i]).StoredFunction := LStoredFunction;
    TACRExpression(FieldValues.Items[i]).LocalParams := LParams;
    TACRExpression(FieldValues.Items[i]).Session := FDatabaseParams.Session;
   end;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRSQLUpdate.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLUpdate.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLUpdate.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FieldNames.Assign(TACRSQLUpdate(Source).FieldNames);
  FieldValues.Assign(TACRSQLUpdate(Source).FieldValues);
  if (InternalSelecter <> nil) then
    FreeAndNil(InternalSelecter);
  if (TACRSQLUpdate(Source).InternalSelecter <> nil) then
   begin
    InternalSelecter := TACRSQLSelect.Create(nil,FDatabaseParams,LStoredFunction);
    InternalSelecter.Assign(TACRSQLUpdate(Source).InternalSelecter);
   end;
end; // Assign


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRSQLUpdate.Clear;
begin
  FieldNames.Clear;
  FieldValues.Clear;
end; // Clear


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLUpdate.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  InternalSelecter := nil;
  FieldNames  := TACRWideStringList.Create;
  FieldValues := TACRExpressions.Create;
  TableName := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TACRSQLUpdate.Destroy;
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
procedure TACRSQLUpdate.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                );
var
   i:           Integer;
   ds:          TDataSet;
   oldRecCount: Integer;
   values:      array of TACRVariant;
   ConstsOnly:  Boolean;
   IsBlob:      Boolean;
   AdvFieldDef: TACRAdvFieldDef;

 procedure UpdateConstsOnly;
 var i: Integer;
 begin
    SetLength(values,FieldValues.Count);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('> 20 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count));
{$ENDIF}
    for i:=0 to FieldValues.Count-1 do
     begin
      values[i] := TACRVariant.Create;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('21 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
      values[i].Assign(TACRExpression(FieldValues[i]).GetValue,True);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('22 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
//      TACRExpression(FieldValues[i]).Free;
     end;
    try
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('23 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count));
{$ENDIF}
      oldRecCount := ds.RecordCount;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('24 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount));
{$ENDIF}
      TACRTable(ds).UpdateVisibleRecords(FieldNames,values);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('25 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount));
{$ENDIF}
      Inc(RowsAffected,oldRecCount);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('26 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
    finally
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('27 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
      for i:=0 to FieldValues.Count-1 do
       values[i].Free;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('28 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
      values := nil;
    end;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('< 29 TACRSQLUpdate.ExecSQL. ConstsOnly'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
 end; // UpdateConstsOnly

 procedure UpdateGeneral;
 var i: Integer;
 begin
    ds.First;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('> 30 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'ds.Eof = '+BoolToStr(ds.Eof,True)
);
{$ENDIF}
    while (not ds.Eof) and (ds.RecordCount > 0) do
      begin
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('31 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'ds.Eof = '+BoolToStr(ds.Eof,True)
);
{$ENDIF}
        ds.Edit;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('32 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'FieldNames.Count = '+IntToStr(FieldNames.Count)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'ds.Eof = '+BoolToStr(ds.Eof,True)
);
{$ENDIF}
        for i:=0 to FieldNames.Count-1 do
         begin
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('32 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'i = '+IntToStr(i)
);
{$ENDIF}
          SetACRVariantIntoField(
                                  TACRExpression(FieldValues[i]).GetValue,
                                  ds.Fields.FieldByName(FieldNames[i])
                                );
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('33 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'i = '+IntToStr(i)
);
{$ENDIF}
         end;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('34 TACRSQLUpdate.ExecSQL. UpdateGeneral');
{$ENDIF}
        oldRecCount := ds.RecordCount;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('35 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
);
{$ENDIF}
        ds.post;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('36 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
);
{$ENDIF}
        Inc(RowsAffected);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('37 TACRSQLUpdate.ExecSQL. UpdateGeneral'
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count)
+#13#10+'oldRecCount = '+IntToStr(oldRecCount)
+#13#10+'ds.RecordCount = '+IntToStr(ds.RecordCount)
+#13#10+'RowsAffected = '+IntToStr(RowsAffected));
{$ENDIF}
        if (oldRecCount = ds.RecordCount) then
          ds.Next;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('38 TACRSQLUpdate.ExecSQL. UpdateGeneral');
{$ENDIF}
      end;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('< 39 TACRSQLUpdate.ExecSQL. UpdateGeneral');
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
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('> TACRSQLUpdate.ExecSQL - FReopen = '+BoolToStr(FReopen,True));
{$ENDIF}
 try
  InternalSelecter.FReopen := FReopen;
  InternalSelecter.LockTablesInWriteMode := True;
  InternalSelecter.ExecSQL(IsRoot, True, ReadOnly);
  if (ReadOnly) then
   raise EACRException.Create(12431,ErrorLReadOnlyDatasetReturned,[GetReservedWord(rwUPDATE),TableName]);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('1 TACRSQLUpdate.ExecSQL');
{$ENDIF}
  try
    if ((LParamExprNodes <> nil) and (not FReopen)) then
     begin
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('2 TACRSQLUpdate.ExecSQL');
{$ENDIF}
      InternalSelecter.RootAO.MoveParamNodes(LParamExprNodes);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('3 TACRSQLUpdate.ExecSQL');
{$ENDIF}
     end;
    ds := InternalSelecter.GetResultDataset;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('4 TACRSQLUpdate.ExecSQL');
{$ENDIF}
    if (TACRDataset(ds).IsBeforeUpdateRecordAssigned or
        TACRDataset(ds).IsAfterUpdateRecordAssigned) then
     ConstsOnly := False;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('6 TACRSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True)
+#13#10+'FieldValues.Count = '+IntToStr(FieldValues.Count));
{$ENDIF}
    for i := 0 to FieldValues.Count-1 do
     begin
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('7 TACRSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
{$IFDEF CORRELATED_SUBQUERIES}
      if (TACRExpression(FieldValues[i]).CorrelatedSubQueriesExists) then
       TACRExpression(FieldValues[i]).AssignAO(InternalSelecter.RootAO)
      else
       TACRExpression(FieldValues[i]).AssignCursor(InternalSelecter.GetResultCursor);
{$ELSE}
      TACRExpression(FieldValues[i]).AssignCursor(InternalSelecter.GetResultCursor);
{$ENDIF}
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('8 TACRSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
      if (ConstsOnly) then
       begin
        if (not TACRExpression(FieldValues[i]).IsConst) then
         begin
          ConstsOnly := False;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('9 TACRSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
         end
        else
         begin
          // modified in v.4.70 - to prevent crash in TACRCursor.SetFieldValue if not NULL
          AdvFieldDef := TACRDataSet(ds).AdvFieldDefs.Find(FieldNames[i]);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('10 TACRSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i));
{$ENDIF}
          if (AdvFieldDef = nil) then
           raise EACRException.Create(11590,ErrorLCannotFindFieldInTable,[FieldNames[i],TACRTable(ds).TableName]);
          IsBlob := IsBLOBFieldType(AdvFieldDef.DataType);
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('11 TACRSQLUpdate.ExecSQL.'
+#13#10+'i = '+IntToStr(i)
+#13#10+'IsBlob = '+BoolToStr(IsBlob,True));
{$ENDIF}
          if (IsBlob) then
            if (not TACRExpression(FieldValues[i]).IsNullConst) then
               ConstsOnly := False;
         end;
       end;
     end;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('12 TACRSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
    if (ConstsOnly) then
     UpdateConstsOnly
    else
     UpdateGeneral;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('13 TACRSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
  finally
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('15 TACRSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
     if ((InternalSelecter <> nil) and (LParamExprNodes = nil)) then
      begin
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('16 TACRSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
       InternalSelecter.Free;
       InternalSelecter := nil;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('17 TACRSQLUpdate.ExecSQL. ConstsOnly = '+BoolToStr(ConstsOnly,True));
{$ENDIF}
      end;
  end;
 finally
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('< TACRSQLUpdate.ExecSQL - FReopen = '+BoolToStr(FReopen,True));
{$ENDIF}
  if (LParamExprNodes = nil) then
   Clear;
{$IFDEF TACRSQLUpdate_ExecSQL}
aaWriteToLog('<< TACRSQLUpdate.ExecSQL - FReopen = '+BoolToStr(FReopen,True));
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
procedure TACRSQLUpdate.Parse;
var
  oldPos, newPos, i,j,n: Integer;
  oldLen:                Integer;
  Expr:                  TACRExpression;
  bDatabaseName:         Boolean;
begin
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    LParamExprNodes := TACRList.Create;
  if not GetCurrentToken then
    raise EACRException.Create(30216, ErrorGBlankSqlCommand);

  GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBackQuotedString,tktBracketedString],
               30217, ErrorGTableNameExpected);
  ParseTableNameToken;
  bDatabaseName := IntoMemory and (DatabaseName <> '') and
                  (DatabaseName <> ACRMemoryDatabaseName);
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
    raise EACRException.Create(30220, ErrorGOtherTokenExpected,
             ['SET', Token.Text, Token.LineNum, Token.ColumnNum]);

  GetNextToken;

  // field_name = value, ...
  repeat
    // Field_name
    FieldNames.Add(Token.Text);
    GetNextToken;
    if Token.Text <> '='then
      raise EACRException.Create(30221, ErrorGOtherTokenExpected,
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
            raise EACRException.Create(30222, ErrorGOtherTokenExpected,
                     [',', Token.Text, Token.LineNum, Token.ColumnNum]);

        // get next field_name
        if (not GetNextToken) then
            raise EACRException.Create(30223, ErrorGUnexpectedEndOfCommand,
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
        Tokens[3].Text := ACRMemoryDatabaseName;
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

      InternalSelecter := TACRSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction);
    end;
end;//Parse



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLDelete
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRSQLDelete.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLDelete.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLDelete.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FullDelete := TACRSQLDelete(Source).FullDelete;
  if (InternalSelecter <> nil) then
    FreeAndNil(InternalSelecter);
  if (TACRSQLDelete(Source).InternalSelecter <> nil) then
   begin
    InternalSelecter := TACRSQLSelect.Create(nil,FDatabaseParams,LStoredFunction);
    InternalSelecter.Assign(TACRSQLDelete(Source).InternalSelecter);
   end;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLDelete.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  InternalSelecter := nil;
  FullDelete := false;
  TableName := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TACRSQLDelete.Destroy;
begin
  if (InternalSelecter <> nil) then
   InternalSelecter.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Execute SQL statement
//------------------------------------------------------------------------------
procedure TACRSQLDelete.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                );
var
  ds:       TDataSet;

  procedure FastDelete;
  begin
   RowsAffected := ds.RecordCount;
   TACRDataSet(ds).DeleteVisibleRecords;
  end;

  procedure GeneralDelete;
  begin
    RowsAffected := 0;
//    TACRDataSet(ds).Handle.LockTableForRead;
//    try
      ds.First;
      while not ds.Eof do
        begin
          ds.Delete;
          Inc(RowsAffected);
        end;
//    finally
//     TACRDataSet(ds).Handle.UnlockTableForRead;
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
   if (TACRDataset(ds).IsBeforeDeleteRecordAssigned or
       TACRDataset(ds).IsAfterDeleteRecordAssigned) then
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
procedure TACRSQLDelete.Parse;
var
   i,n: integer;
begin
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    LParamExprNodes := TACRList.Create;
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
    raise EACRException.Create(30224, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  InternalSelecter := TACRSQLSelect.Create(LLex, FDatabaseParams, LStoredFunction);

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

  DefaultValue := TACRVariant.Create;
  MinValue := TACRVariant.Create;
  MaxValue := TACRVariant.Create;

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
    raise EACRException.Create(12187,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise EACRException.Create(12188,ErrorLErrorInAssignInvalidClass,
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
// TACRDDLTableManipulation
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// table element list
//------------------------------------------------------------------------------
procedure TACRDDLTableManipulation.ParseTableElementList;
var
  FieldDef: TSQLFieldDef;
  bFirst:   Boolean;
begin
  if ((not bLeftParethesis) and (Token.TokenType <> tktLeftParenthesis)) then
    raise EACRException.Create(30226, ErrorGOtherTokenExpected,
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
function TACRDDLTableManipulation.ParseComment:Boolean;
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
procedure TACRDDLTableManipulation.FillColumnType(var FieldDef: TSQLFieldDef);
var s1,s2: Int64;
begin
  // column type
  if (UpperCase(AnsiString(Token.Text)) = ACR_GUID) then
  begin
   FieldDef.FieldType := aftChar;
   FieldDef.newFieldType := True;
   FieldDef.Length := ACR_GUID_LENGTH;
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
      raise EACRException.Create(12517, ErrorLSizeExpected,
                   [Token.Text, Token.LineNum, Token.ColumnNum]);
     s1 := StrToInt64Def(token.Text,0);
     s2 := 0;
     GetNextToken;
     if (Token.TokenType <> tktComma) and (Token.TokenType <> tktRightParenthesis) then
      raise EACRException.Create(12518, ErrorGOtherTokenExpected,
        [', or )', Token.Text,Token.LineNum,Token.ColumnNum]);
     if (Token.TokenType = tktComma) then
     begin
      GetNextToken;
      if (Token.TokenType <> tktInt) then
        raise EACRException.Create(12519, ErrorLSizeExpected,
                     [Token.Text, Token.LineNum, Token.ColumnNum]);
      s2 := StrToInt64Def(token.Text,0);
      GetNextToken;
     if (Token.TokenType <> tktRightParenthesis) then
      raise EACRException.Create(12520, ErrorGRightParenthesisExpected,
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
      raise EACRException.Create(30232, ErrorGUnknownFieldType,
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
          raise EACRException.Create(30290, ErrorGUnexpectedEndOfCommand,
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
                    raise EACRException.Create(30295, ErrorGUnsupportedAutoincDataType,
                                    [Token.Text, Token.LineNum, Token.ColumnNum]);
                 end;//case

                 if FieldDef.FieldType = aftUnknown then
                  begin
                   FieldDef.FieldType := aftAutoinc;
                   raise EACRException.Create(30293, ErrorGUnexpectedToken,
                                    [Token.Text, Token.LineNum, Token.ColumnNum]);
                  end
                end
               else
                raise EACRException.Create(30294, ErrorGUnexpectedToken,
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
procedure TACRDDLTableManipulation.ParseColumnRequired(var FieldDef: TSQLFieldDef);
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
        raise EACRException.Create(02011, ErrorGNullKeywordExpected,
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
//procedure TACRDDLTableManipulation.FillBlobBlockSize(var FieldDef: TSQLFieldDef);
//begin
//  GetNextToken([tktInt], 30296, ErrorGIntegerExpected);
//  FieldDef.newBlobBlockSize := True;
//  FieldDef.BlobBlockSize := ParseInteger;
//end;//FillBlobBlockSize


//------------------------------------------------------------------------------
// parse DEFAULT {const | NULL}
//------------------------------------------------------------------------------
function TACRDDLTableManipulation.ParseDefaultValue(var FieldDef:TSQLFieldDef): Boolean;
var expr: TACRExpression;
begin
  Result := False;
  if (Token.ReservedWord = rwDEFAULT) then
    begin
      GetNextToken([], 30297, ErrorGUnexpectedEndOfCommand);

      if FieldDef.newDefaultValue then
        raise EACRException.Create(30299, ErrorGDefaultValueReDeclared, [FieldDef.FieldName]);

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
          expr := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
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
function TACRDDLTableManipulation.ParseMinValue(var FieldDef: TSQLFieldDef): Boolean;
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
function TACRDDLTableManipulation.ParseMaxValue(var FieldDef: TSQLFieldDef): Boolean;
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
function TACRDDLTableManipulation.ParseFieldPrimaryKey(var FieldDef: TSQLFieldDef): Boolean;
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
function TACRDDLTableManipulation.ParseFieldUnique(var FieldDef: TSQLFieldDef): Boolean;
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
function TACRDDLTableManipulation.ParsePrimaryKey: boolean;
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
        raise EACRException.Create(30327, ErrorGLeftParenthesisExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);

      repeat
        GetNextToken;
        // FieldName
        if Token.TokenType in [tktString, tktBracketedString, tktQuotedString, tktBackQuotedString, tktReservedWord] then
          FieldName := Token.Text
        else
          raise EACRException.Create(30244, ErrorGFieldNameExpected,
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
          raise EACRException.Create(30245, ErrorGRightParenthesisOrCommaExpected,
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
function TACRDDLTableManipulation.ParseForeignKey: boolean;
var
    ForeignKeyDef:    TACRForeignKeyDef;
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
     raise EACRException.Create(11474,ErrorGOtherTokenExpected,
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
     raise EACRException.Create(11475,ErrorGOtherTokenExpected,
      [GetReservedWord(rwACTION) ,
       Token.Text,Token.LineNum,Token.ColumnNum]);
   end
  else
   raise EACRException.Create(11476,ErrorGOtherTokenExpected,
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
       FForeignKeyDefs := TACRForeignKeyDefs.Create;
     ForeignKeyDef := TACRForeignKeyDefs(FForeignKeyDefs).AddForeignKeyDef;
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
       raise EACRException.Create(11467,ErrorGOtherTokenExpected,
        [GetReservedWord(rwKEY),Token.Text,Token.LineNum,Token.ColumnNum]);

      if (FForeignKeyDefs = nil) then
       FForeignKeyDefs := TACRForeignKeyDefs.Create;
      if (ForeignKeyDef = nil) then
        ForeignKeyDef := TACRForeignKeyDefs(FForeignKeyDefs).AddForeignKeyDef;
      // foreign key name
      if (Token.TokenType <> tktLeftParenthesis) then
        begin
          ForeignKeyDef.Name := Token.Text;
          GetNextToken;
        end;

      // '('
      if (Token.TokenType <> tktLeftParenthesis) then
        raise EACRException.Create(11468, ErrorGLeftParenthesisExpected,
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
          raise EACRException.Create(11469, ErrorGFieldNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
        GetNextToken;
        // ')'or ','
        if not (Token.TokenType in [tktComma, tktRightParenthesis]) then
          raise EACRException.Create(11470, ErrorGRightParenthesisOrCommaExpected,
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
         raise EACRException.Create(11478, ErrorGTableNameExpected,
                         [Token.Text, Token.LineNum, Token.ColumnNum]);
       end
      else
       raise EACRException.Create(11477,ErrorGOtherTokenExpected,
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
         raise EACRException.Create(11471,ErrorGOtherTokenExpected,
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
         raise EACRException.Create(11472,ErrorGOtherTokenExpected,
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
         raise EACRException.Create(11473,ErrorGOtherTokenExpected,
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
function TACRDDLTableManipulation.ParseInteger: Int64;
begin
  GetNextToken([tktInt], 30292, ErrorGIntegerExpected);
  try
    Result := StrToInt64(Token.Text);
  except
    raise EACRException.Create(30291, ErrorGIntegerExpected,
                               [Token.Text, Token.LineNum, Token.ColumnNum]);
  end;
  //GetNextToken;
end;//ParseInteger


//------------------------------------------------------------------------------
// Create ACRTable object and fill ACRTable params
//------------------------------------------------------------------------------
function TACRDDLTableManipulation.CreateInternalACRTable: TDataSet;
var i: Integer;
begin
  Result := inherited CreateInternalACRTable;
  TACRTable(Result).ClearDefinitions;
  for i := 0 to SQLFieldDefs.Count-1 do
    FillAdvFieldDef(
                    TFieldDef(TACRTable(Result).AdvFieldDefs.AddFieldDef),
                    SQLFieldDefs[i]
                   );
  //FillPrimaryKey(Result);
end; // CreateInternalACRTable


//------------------------------------------------------------------------------
// Add Primary Key into ACRTable
//------------------------------------------------------------------------------
procedure TACRDDLTableManipulation.FillAdvFieldDef(
                                        AdvFieldDef: TFieldDef;
                                        SQLFieldDef: TSQLFieldDef
                                                  );
var
  fd: TACRAdvFieldDef;
begin
  fd := TACRAdvFieldDef(AdvFieldDef);

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
// Add Primary Key into ACRTable
//------------------------------------------------------------------------------
procedure TACRDDLTableManipulation.AddPrimaryKey(T: TDataSet);
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
       until (TACRTable(T).IndexDefs.IndexOf(pkName) < 0);
      TACRTable(T).IndexDefs.Add(pkName, Fields, [ixPrimary]);
      i := TACRTable(T).IndexDefs.Count-1;
      TACRTable(T).IndexDefs.Items[i].DescFields := DescFields;
      TACRTable(T).IndexDefs.Items[i].CaseInsFields := CaseInsFields;
      TACRTable(T).RestructureIndexDefs.Add(pkName, Fields, [ixPrimary]);
      i := TACRTable(T).RestructureIndexDefs.Count-1;
      TACRTable(T).RestructureIndexDefs.Items[i].DescFields := DescFields;
      TACRTable(T).RestructureIndexDefs.Items[i].CaseInsFields := CaseInsFields;
    end; // primary key fields defined
end;//AddPrimaryKey


//------------------------------------------------------------------------------
// Add UNIQUE constraint and index into ACRTable
//------------------------------------------------------------------------------
procedure TACRDDLTableManipulation.AddUnique(T: TDataSet);
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
     until (TACRTable(T).IndexDefs.IndexOf(uName) < 0);
     TACRTable(T).IndexDefs.Add(uName, UniqueFields[i], [ixUnique]);
     TACRTable(T).RestructureIndexDefs.Add(uName, UniqueFields[i], [ixUnique]);
    end;
end;//AddUnique


//------------------------------------------------------------------------------
// Delete PrimaryKey
//------------------------------------------------------------------------------
procedure TACRDDLTableManipulation.DeletePrimaryKey(T: TDataSet);
var
  i: integer;
  AT: TACRTable;

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
  AT := TACRTable(T);

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
function TACRDDLTableManipulation.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLTableManipulation.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDDLTableManipulation.Assign(Source: TACRSQLCommand);
var i,l: Integer;
begin
  inherited Assign(Source);
  if (TACRDDLTableManipulation(Source).FForeignKeyDefs = nil) then
   begin
    if (FForeignKeyDefs <> nil) then
     FreeAndNil(FForeignKeyDefs);
   end
  else
   begin
    if (FForeignKeyDefs = nil) then
     FForeignKeyDefs := TACRForeignKeyDefs.Create;
    TACRForeignKeyDefs(FForeignKeyDefs).Assign(TACRForeignKeyDefs(TACRDDLTableManipulation(Source).FForeignKeyDefs));
   end;
  SQLFieldDefs.Assign(TSQLFieldDefs(TACRDDLTableManipulation(Source).SQLFieldDefs));
  PrimaryIndexName := TACRDDLTableManipulation(Source).PrimaryIndexName;
  l := Length(TACRDDLTableManipulation(Source).PrimaryKeyFields);
  SetLength(PrimaryKeyFields,l);
  if (l > 0) then
   for i := 0 to l-1 do
    begin
     PrimaryKeyFields[i].FieldName := TACRDDLTableManipulation(Source).PrimaryKeyFields[i].FieldName;
     PrimaryKeyFields[i].desc := TACRDDLTableManipulation(Source).PrimaryKeyFields[i].desc;
     PrimaryKeyFields[i].nocase := TACRDDLTableManipulation(Source).PrimaryKeyFields[i].nocase;
    end;
  UniqueFields.Assign(TACRDDLTableManipulation(Source).UniqueFields);
  bLeftParethesis := TACRDDLTableManipulation(Source).bLeftParethesis;
  FComment := TACRDDLTableManipulation(Source).FComment;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDDLTableManipulation.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  // added in 4.97 - for ALTER TABLE add(...) ALTER TABLE DROP (...)
  bLeftParethesis := False;
  SQLFieldDefs := TSQLFieldDefs.Create;
  SetLength(PrimaryKeyFields, 0);
  UniqueFields := TACRWideStringList.Create;
  PrimaryIndexName := '';
  FForeignKeyDefs := nil;
  FComment := '';
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRDDLTableManipulation.Destroy;
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
procedure TACRDDLTableManipulation.Parse;
begin
  // check for not expected token
  if (LLex.LookNextToken(Token)) then
     raise EACRException.Create(30246, ErrorGUnexpectedToken,
                                [Token.Text, Token.LineNum, Token.ColumnNum]);
end;//Parse




////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLCreateTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLCreateTable.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLCreateTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRDDLCreateTable.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FIfNotExists := TACRDDLCreateTable(Source).FIfNotExists;
end; // Assign


//------------------------------------------------------------------------------
// Create Table
//------------------------------------------------------------------------------
procedure TACRDDLCreateTable.CreateTable;
var
  T: TACRTable;
begin
{$IFDEF DEBUG_TRACE_TACRDDLCreateTable_CreateTable}
aaWriteToLog('> TACRDDLCreateTable.CreateTable'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(IntoMemory,True)
);
{$ENDIF}
  T := CreateInternalACRTable as TACRTable;
  try
    // If table already exists - raise
    if (FIfNotExists) then
     if (T.Exists) then
      Exit;
    if T.Exists then
      raise EACRException.Create(30247, ErrorGTableAlreadyExists, [T.TableName]);

    try
      AddPrimaryKey(T);
      AddUnique(T);
      if (FForeignKeyDefs <> nil) then
       t.ForeignKeyDefs.Assign(TACRForeignKeyDefs(FForeignKeyDefs));
{$IFDEF DEBUG_TRACE_TACRDDLCreateTable_CreateTable}
aaWriteToLog('TACRDDLCreateTable.CreateTable calling CreateTable...'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(IntoMemory,True)
+#13#10+'t.DatabaseName = '+TACRTable(t).DatabaseName
+#13#10+'t.TableName = '+TACRTable(t).TableName
+#13#10+'t.InMemory = '+BoolToStr(TACRTable(t).InMemory,True)
);
{$ENDIF}
      T.Comment := FComment;
      T.CreateTable;
{$IFDEF DEBUG_TRACE_TACRDDLCreateTable_CreateTable}
aaWriteToLog('< TACRDDLCreateTable.CreateTable'
+#13#10+'DatabaseName = '+DatabaseName
+#13#10+'TableName = '+TableName
+#13#10+'bInMemory = '+BoolToStr(IntoMemory,True)
);
{$ENDIF}
    except
      on e:Exception do
        raise EACRException.Create(30248, ErrorGErrorCreatingTable, [e.Message]);
    end;

  finally
    T.Free;
  end
end;//CreateTable


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TACRDDLCreateTable.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(30249, ErrorGBlankSqlCommand);
  FIfNotExists := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (not IsReservedWord(Token,rwNOT)) then
     raise EACRException.Create(12464, ErrorGOtherTokenExpected,
         ['NOT EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
     FIfNotExists := True;
    end
    else
     raise EACRException.Create(12465, ErrorGOtherTokenExpected,
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
procedure TACRDDLCreateTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                    );
begin
  CreateTable;
end;//ExecSQL



////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLDropTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Drop Table - always without exception
//------------------------------------------------------------------------------
procedure TACRDDLDropTable.DropTable;
var
  T: TACRTable;
begin
  T := CreateInternalACRTable as TACRTable;
  try
    try
      T.Exclusive := True;
      if (T.Exists) then
       T.DeleteTable(FCascade);
    except
      on e:Exception do
        raise EACRException.Create(30250, ErrorGDroppingTable, [e.Message]);
    end;
  finally
    T.Free;
  end
end;//DropTable


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLDropTable.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLDropTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDDLDropTable.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FCascade := TACRDDLDropTable(Source).FCascade;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDDLDropTable.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(30251,ErrorGBlankSQLCommand);
  FCascade := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
    end
    else
     raise EACRException.Create(12463, ErrorGOtherTokenExpected,
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
procedure TACRDDLDropTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                  );
begin
  DropTable;
end;//ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLEmptyTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Empty Table
//------------------------------------------------------------------------------
procedure TACRDDLEmptyTable.EmptyTable;
var T: TACRTable;
begin
  T := CreateInternalACRTable as TACRTable;
  try
    if (not FIfExists) and (not t.Exists) then
     raise EACRException.Create(12457,ErrorLTableDoesNotExist,[T.TableName]);
    try
      T.Exclusive := True;
      if (t.Exists) then
       T.EmptyTable;
    except
      on e:Exception do
        raise EACRException.Create(12458, ErrorLEmptyTable, [e.Message]);
    end;
  finally
    T.Free;
  end
end;//EmptyTable


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLEmptyTable.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLEmptyTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDDLEmptyTable.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FIfExists := TACRDDLEmptyTable(Source).FIfExists;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDDLEmptyTable.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(12461,ErrorGBlankSQLCommand);
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
     raise EACRException.Create(12462, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
  ParseTableNameToken;
  inherited;
end;//Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TACRDDLEmptyTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                  );
begin
  EmptyTable;
end;//ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLAlterTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDDLAlterTable.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  DropColumnNamesList := TACRWideStringList.Create;
  RenameColumnOldNamesList := TACRWideStringList.Create;
  RenameColumnNewNamesList := TACRWideStringList.Create;
  NewTableName := '';
  FModifyComment := False;
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRDDLAlterTable.Destroy;
begin
  DropColumnNamesList.Free;
  RenameColumnOldNamesList.Free;
  RenameColumnNewNamesList.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// parse AlterType token
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.ParseAlterTypeToken;
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
       raise EACRException.Create(30252, ErrorGAddOrDropOrModifyKeywordExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);
    end//case
  else
    raise EACRException.Create(30253, ErrorGAddOrDropOrModifyKeywordExpected,
                            [Token.Text, Token.LineNum, Token.ColumnNum]);
end;//ParseAlterTypeToken


//------------------------------------------------------------------------------
// Alter Table DropColumn
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.ParseRenameColumnsList;
begin
  // OldColumnName
  RenameColumnOldNamesList.Add(Token.Text);
  GetNextToken;

  // TO
  if not IsReservedWord(Token, rwTO) then
    raise EACRException.Create(30352, ErrorGOtherTokenExpected,
                          ['TO', Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;

  // NewColumnName
  RenameColumnNewNamesList.Add(Token.Text);
  GetNextToken;
end;//ParseRenameColumnsList


//------------------------------------------------------------------------------
// parse DROP CONSTRAINT
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.ParseDropConstraint;
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
       raise EACRException.Create(11496,ErrorGOtherTokenExpected,
         [GetReservedWord(rwCASCADE) + 'or '+GetReservedWord(rwRESTRICT),
          Token.Text,Token.LineNum,Token.ColumnNum]);
     end;
   end
  else
   raise EACRException.Create(11495, ErrorLConstraintNameExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
end; // ParseDropConstraint


//------------------------------------------------------------------------------
// Alter Table DropColumn
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.DropColumn(T: TDataSet);
var i: Integer;
begin
  for i:=0 to DropColumnNamesList.Count-1 do
    TACRTable(T).RestructureFieldDefs.DeleteFieldDef(DropColumnNamesList[i]);
end;//DropColumn


//------------------------------------------------------------------------------
// Alter Table AddColumn
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.AddColumn(T: TDataSet);
var
  i: Integer;
  fd: TACRAdvFieldDef;
begin
    for i:=0 to SQLFieldDefs.Count-1 do
      begin
        fd := TACRTable(T).RestructureFieldDefs.Find(SQLFieldDefs[i].FieldName);
        if fd <> nil then
          raise EACRException.Create(30351, ErrorGFieldAlreadyExists,
                                     [SQLFieldDefs[i].FieldName]);
        // Add Field
        fd := TACRTable(T).RestructureFieldDefs.AddFieldDef;

        // Fill Field
        FillAdvFieldDef(TFieldDef(fd), SQLFieldDefs[i]);

      end;
//  DeletePrimaryKey(T);
//  AddPrimaryKey(T);
end;//AddColumn


//------------------------------------------------------------------------------
// Alter Table Modify
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.Modify(T: TDataSet);
var
  i: Integer;
  fd: TACRAdvFieldDef;
begin
  if (FModifyComment) then
   begin
    if (TACRTable(T).Database <> nil) then
     TACRTable(T).Database.SetTableComment(TACRTable(T).TableName,FComment);
   end
  else
  for i:=0 to SQLFieldDefs.Count-1 do
    begin
      fd := TACRTable(T).RestructureFieldDefs.Find(SQLFieldDefs[i].FieldName);
      if fd = nil then
        raise EACRException.Create(30259, ErrorGCannotFindField,
                                   [TACRTable(t).TableName+'.'+SQLFieldDefs[i].FieldName]);

      // Apply Changes
      FillAdvFieldDef(TFieldDef(fd), SQLFieldDefs[i]);

    end;
//  DeletePrimaryKey(T);
//  AddPrimaryKey(T);
end;//Modify


//------------------------------------------------------------------------------
// Rename Column
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.RenameColumn(T: TDataSet);
var  i: Integer;
begin
  for i:=0 to  RenameColumnOldNamesList.Count-1 do
   TACRTable(T).RenameField(RenameColumnOldNamesList[i],
                            RenameColumnNewNamesList[i]);
end;//RenameColumn


//------------------------------------------------------------------------------
// modify comment
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.ModifyComment(Session: TACRBaseSession);
begin
  if (Session = nil) then
   raise EACRException.Create(12099,ErrorLNilPointer);
  Session.SetTableComment(TableName,FComment);
end; // ModifyComment


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLAlterTable.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLAlterTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  AlterType := TACRDDLAlterTable(Source).AlterType;
  DropColumnNamesList.Assign(TACRDDLAlterTable(Source).DropColumnNamesList);
  RenameColumnOldNamesList.Assign(TACRDDLAlterTable(Source).RenameColumnOldNamesList);
  RenameColumnNewNamesList.Assign(TACRDDLAlterTable(Source).RenameColumnNewNamesList);
  NewTableName := TACRDDLAlterTable(Source).NewTableName;
  NewDatabaseName := TACRDDLAlterTable(Source).NewDatabaseName;
  NewInMemory := TACRDDLAlterTable(Source).NewInMemory;
  DropConstraintName := TACRDDLAlterTable(Source).DropConstraintName;
  DropConstraintCascade := TACRDDLAlterTable(Source).DropConstraintCascade;
  FModifyComment := TACRDDLAlterTable(Source).FModifyComment;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDDLAlterTable.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(30261, ErrorGBlankSqlCommand);

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
      raise EACRException.Create(30350, ErrorGNotImplementedYet);
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
procedure TACRDDLAlterTable.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                    );
var
  T:    TACRTable;
  i:    Integer;
  Log:  AnsiString;
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12100,ErrorLNilPointer);
  if (FModifyComment) then
   ModifyComment(FDatabaseParams.Session)
  else
   begin
    T := CreateInternalACRTable as TACRTable;
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
           for i := 0 to TACRForeignKeyDefs(FForeignKeyDefs).Count-1 do
            T.AddForeignKey(TACRForeignKeyDefs(FForeignKeyDefs).Items[i]);
  //          if (FForeignKeyDefs <> nil) then
  //           T.RestructureForeignKeyDefs.Assign(TACRForeignKeyDefs(FForeignKeyDefs));
          atDropConstraint:
            T.DeleteConstraint(DropConstraintName,DropConstraintCascade);
        end;

        if (AlterType in [atDrop, atAdd, atModify, atAddConstraintPrimaryKey]) then
          // RestructureTable
         if not (t.RestructureTable(Log)) then
          raise EACRException.Create(30347 ,ErrorGRestructureTableError, [Log]);

      except
        on e:Exception do
          raise EACRException.Create(30265, ErrorGErrorAlteringTable,[e.Message]);
      end
    finally
      T.Free;
    end
   end;
end;//ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLRenameTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLRenameTable.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLRenameTable.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDDLRenameTable.Parse;
begin
  if (not GetCurrentToken) then
    raise EACRException.Create(30354, ErrorGBlankSqlCommand);

  AlterType := atRenameTable;

  // Parse Table Name
  ParseTableNameToken;

  // TO
  if not IsReservedWord(Token, rwTO) then
    raise EACRException.Create(30355, ErrorGOtherTokenExpected,
                          ['TO', Token.Text, Token.LineNum, Token.ColumnNum]);
  GetNextToken;

  // New Table Name
  NewTableName := Token.Text;

end;//Parse



////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLCreateIndex
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLCreateIndex.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLCreateIndex.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDDLCreateIndex.Assign(Source: TACRSQLCommand);
var l,i: Integer;
begin
  inherited Assign(Source);
  Unique := TACRDDLCreateIndex(Source).Unique;
  IfNotExists := TACRDDLCreateIndex(Source).IfNotExists;
  IndexName := TACRDDLCreateIndex(Source).IndexName;
  TableName := TACRDDLCreateIndex(Source).TableName;
  l := Length(TACRDDLCreateIndex(Source).ACRIndexFields);
  SetLength(ACRIndexFields,l);
  if (l > 0) then
   for i := 0 to l-1 do
    begin
     ACRIndexFields[i].FieldName := TACRDDLCreateIndex(Source).ACRIndexFields[i].FieldName;
     ACRIndexFields[i].desc := TACRDDLCreateIndex(Source).ACRIndexFields[i].desc;
     ACRIndexFields[i].nocase := TACRDDLCreateIndex(Source).ACRIndexFields[i].nocase;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDDLCreateIndex.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  Unique := False;
  IfNotExists := False;
  SetLength(ACRIndexFields, 0);
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDDLCreateIndex.Parse;
var TempToken: TToken;
begin
  if (not GetCurrentToken) then
    raise EACRException.Create(30266, ErrorGBlankSQLCommand);

  // UNIQUE
  if IsReservedWord(Token, rwUNIQUE) then
    begin
      Unique:=true;
      GetNextToken([tktReservedWord], 30267, ErrorGIndexKeywordExpected);
    end;

  // INDEX
  if not IsReservedWord(Token, rwINDEX) then
    raise EACRException.Create(30268, ErrorGIndexKeywordExpected,
             [Token.Text, Token.LineNum, Token.ColumnNum]);

  LLex.LookNextToken(TempToken);
  if (IsReservedWord(TempToken, rwIF)) then
    begin
     GetNextToken;
     GetNextToken([tktReservedWord], 11236, ErrorLSQLNotKeywordExpected);
     if (not IsReservedWord(Token, rwNOT)) then
      raise EACRException.Create(11237, ErrorLSQLNotKeywordExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
     GetNextToken([tktReservedWord], 11238, ErrorLSQLExistsKeywordExpected);
     if (not IsReservedWord(Token, rwEXISTS)) then
      raise EACRException.Create(11239, ErrorLSQLExistsKeywordExpected,
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
    raise EACRException.Create(30271, ErrorGOnKeywordExpected,
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
    SetLength(ACRIndexFields, Length(ACRIndexFields)+1);
    with ACRIndexFields[Length(ACRIndexFields)-1] do
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
procedure TACRDDLCreateIndex.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                    );
var
   T:                                 TACRTable;
   Fields, DescFields, CaseInsFields: WideString;
   delim1,delim2,delim3:              WideString;
   i:                                 Integer;
   Options:                           TIndexOptions;
   bCancel:                           Boolean;
begin
   Fields:=''; DescFields:=''; CaseInsFields:='';
   delim1:=''; delim2:=''; delim3:='';
   for i:=0 to Length(ACRIndexFields)-1 do
     begin
       Fields := Fields + delim1 + ACRIndexFields[i].FieldName;
       delim1 := ';';
       if ACRIndexFields[i].desc then
         begin
           DescFields := DescFields + delim2 + ACRIndexFields[i].FieldName;
           delim2 := ';';
         end;
       if ACRIndexFields[i].nocase then
         begin
           CaseInsFields := CaseInsFields + delim3 + ACRIndexFields[i].FieldName;
           delim3 := ';';
         end;
     end;
   // Index Options
   if Unique then
     Options:=[ixUnique]
   else
     Options:=[];


   // Creating
   T := CreateInternalACRTable as TACRTable;
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
// TACRDDLDropIndex
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLDropIndex.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLDropIndex.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDDLDropIndex.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  IfExists := TACRDDLDropIndex(Source).IfExists;
  TableName := TACRDDLDropIndex(Source).TableName;
  IndexName := TACRDDLDropIndex(Source).IndexName;
end; // Assign


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDDLDropIndex.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  IndexName := '';
  TableName := '';
  IfExists := False;
  inherited Create(Lexer, aDatabaseParams, aStoredFunction);
end;//Create


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDDLDropIndex.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(30278, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken([tktReservedWord], 11241, ErrorLSQLExistsKeywordExpected);
    if (not IsReservedWord(Token, rwEXISTS)) then
      raise EACRException.Create(11242, ErrorLSQLExistsKeywordExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
    IfExists := True;
    if (not GetNextToken) then
      raise EACRException.Create(11243, ErrorGUnexpectedEndOfCommand,
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
    raise EACRException.Create(30279, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);

  // '.'
  if (Token.TokenType <> tktDot) then
    raise EACRException.Create(30280, ErrorGOtherTokenExpected,
                             ['.', Token.Text, Token.LineNum, Token.ColumnNum]);

  // index_name
  if (not GetNextToken) then
    raise EACRException.Create(30281, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);
  IndexName:=Token.Text;

end;//Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRDDLDropIndex.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                                  );
var
   T:       TACRTable;
   bCancel: Boolean;
begin
 T := CreateInternalACRTable as TACRTable;
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
// TACRStartTransaction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRStartTransaction.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRStartTransaction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRStartTransaction.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(10845, ErrorGUnexpectedEndOfCommand,
                               [Token.LineNum, Token.ColumnNum]);
  if (not IsReservedWord(Token, rwTransaction)) then
    raise EACRException.Create(10846, ErrorGSQLCommandExpected,
                               [Token.Text,Token.LineNum, Token.ColumnNum]);
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRStartTransaction.ExecSQL(
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
   aaWriteToLog('TACRStartTransaction.ExecSQL starting...'
    +', SessionID = '+
      IntToStr(TACRBaseSession(Session).SessionID));
 {$ENDIF}
  FDatabaseParams.Session.StartTransaction;
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TACRStartTransaction.ExecSQL starting... ok'
    +', SessionID = '+
      IntToStr(TACRBaseSession(Session).SessionID));
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
// TACRCommit
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRCommit.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRCommit.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRCommit.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FFlushFileBuffers := TACRCommit(Source).FFlushFileBuffers
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRCommit.Parse;
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
procedure TACRCommit.ExecSQL(
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
   aaWriteToLog('TACRStartTransaction.Commit starting...'
    +', SessionID = '+
      IntToStr(TACRBaseSession(Session).SessionID));
 {$ENDIF}
  FDatabaseParams.Session.Commit(FFlushFileBuffers);
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TACRStartTransaction.Commit starting...ok'
    +', SessionID = '+
      IntToStr(TACRBaseSession(Session).SessionID));
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
// TACRRollback
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRRollback.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRRollback.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRRollback.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
begin
{$IFNDEF SQLMEMTABLE}
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TACRStartTransaction.Rollback starting...'
    +', SessionID = '+
      IntToStr(TACRBaseSession(Session).SessionID));
 {$ENDIF}
  FDatabaseParams.Session.Rollback;
 {$IFDEF DEBUG_TRACE_SQL_TRANSACTIONS}
   aaWriteToLog('TACRStartTransaction.Rolback starting...ok'
    +', SessionID = '+
      IntToStr(TACRBaseSession(Session).SessionID));
 {$ENDIF}
{$ENDIF}
end; // ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseManagement
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDatabaseManagement.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDatabaseManagement.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDatabaseManagement.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FInMemory := TACRDatabaseManagement(Source).FInMemory;
  FDatabaseName := TACRDatabaseManagement(Source).FDatabaseName;
  FDatabaseFileName := TACRDatabaseManagement(Source).FDatabaseFileName;
  FDatabaseFileNameUnicode := TACRDatabaseManagement(Source).FDatabaseFileNameUnicode;
  FMaxSessionsCount := TACRDatabaseManagement(Source).FMaxSessionsCount;
  FPageSize := TACRDatabaseManagement(Source).FPageSize;
  FPassword := TACRDatabaseManagement(Source).FPassword;
end; // Assign


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRDatabaseManagement.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
destructor TACRDatabaseManagement.Destroy;
begin
  if (FPassword <> '') then
   ACRClearString(FPassword);
  inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TACRCreateDatabase
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRCreateDatabase.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRCreateDatabase.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
// CREATE DATABASE FILE FILE_NAME
// or
// CREATE DATABASE MEMORY DATABASE_NAME
// MEMORY can be skipped in SQLMemTable
//------------------------------------------------------------------------------
procedure TACRCreateDatabase.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(11748, ErrorGBlankSqlCommand);
  if (not (Token.TokenType in
      [tktString, tktQuotedString, tktBackQuotedString,
       tktReservedWord, tktBracketedString])) then
    raise EACRException.Create(11749, ErrorLDatabaseNameExpected,
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
      raise EACRException.Create(11756,ErrorGOtherTokenExpected,
                             ['MEMORY',Token.Text,Token.LineNum,Token.ColumnNum]);
    // database name
    FDatabaseName := Token.Text;
   end;
end;// TACRCreateDatabase


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRCreateDatabase.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
var db: TACRDatabase;
begin
 db := TACRDatabase.Create(nil);
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
end;// TACRCreateDatabase


////////////////////////////////////////////////////////////////////////////////
//
// TACRDropDatabase
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDropDatabase.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDropDatabase.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// parse query
// DROP DATABASE FILE FILE_NAME
// or
// DROP DATABASE MEMORY DATABASE_NAME
// MEMORY can be skipped in SQLMemTable
//------------------------------------------------------------------------------
procedure TACRDropDatabase.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(11752, ErrorGBlankSqlCommand);
  if (not (Token.TokenType in
      [tktString, tktQuotedString, tktBackQuotedString,
       tktReservedWord, tktBracketedString])) then
    raise EACRException.Create(11753, ErrorLDatabaseNameExpected,
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
      raise EACRException.Create(11757,ErrorGOtherTokenExpected,
                             ['MEMORY',Token.Text,Token.LineNum,Token.ColumnNum]);
     // database name
     FDatabaseName := Token.Text;
   end; // memory database or incorrect statement
end;// TACRDropDatabase


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRDropDatabase.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
var db:           TACRDatabase;
    dbFromQuery:  Boolean;
begin
 dbFromQuery := False;
// commented in v.5.10
{
 if (query <> nil) then
  if (query is TACRQuery) then
   if (TACRQuery(query).Database <> nil) then
    begin
     dbFromQuery := True;
     db := TACRQuery(query).Database;
     db.RemoveDataset(query);
     db.Close;
    end;
}
 if (not dbFromQuery) then
  db := TACRDatabase.Create(nil);
 try
   // we must skip ValidateName call as it will found database component
   // created by TACRQuery.ExecSQL (SetDBFlag)
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
end;// TACRDropDatabase


{$IFDEF CORRELATED_SUBQUERIES}
////////////////////////////////////////////////////////////////////////////////
//
// TACRExprNodeSubQuery
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
procedure TACRExprNodeSubQuery.DetectType;
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
    raise EACRException.Create(12422,ErrorLNilPointer);
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
procedure TACRExprNodeSubQuery.InternalGetDataValue(BooleanResult: Boolean);
var v:          TACRVariant;
    ds:         TACRTable;
    cmpRes:     TACRCompareResult;
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
      ds := TACRTable(FQuery.GetResultDataset);
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
      ds := TACRTable(FQuery.GetResultDataset);
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
      ds := TACRTable(FQuery.GetResultDataset);
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
function TACRExprNodeSubQuery.GetCorrelated: Boolean;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  Result := FCorrelated;
end; // GetCorrelated


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRExprNodeSubQuery.Create(
                                         aParentExpr:           TACRExpression;
                                         Operator:              TACRDataOperator;
                                         aQuery:                TACRSQLUnion;
                                         bNot:                  Boolean = False;
                                         SourceNode:            TACRExprNode = nil;
                                         aComparisonOperator:   TACRDataOperator = doEQ;
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
   raise EACRException.Create(10850,ErrorLSubquerynoArgumentPassed);
  if (SourceNode <> nil) then
   Children.Add(SourceNode);
  FDataType := aftUnknown;
  FResultDatasetFieldNo := -1;
  FCorrelated := False;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRExprNodeSubQuery.Destroy;
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
procedure TACRExprNodeSubQuery.AssignAO(AO: TACRAO);
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
procedure TACRExprNodeSubQuery.AssignCursor(Cursor: TACRCursor);
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
procedure TACRExprNodeSubQuery.AssignCursorBuffer(Buffer: TACRRecordBuffer);
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
function TACRExprNodeSubQuery.GetDataValue: TACRVariant;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    if (FQuery.RootAO = nil) then
     raise EACRException.Create(12423,ErrorLNilPointer);
    if (LAO = nil) then
     raise EACRException.Create(12426,ErrorLNilPointer);
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
function TACRExprNodeSubQuery.GetBooleanValue: Boolean;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  if (FCorrelated) then
  begin
    if (FQuery.RootAO = nil) then
     raise EACRException.Create(12423,ErrorLNilPointer);
    if (LAO = nil) then
     raise EACRException.Create(12426,ErrorLNilPointer);
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
function TACRExprNodeSubQuery.GetDataType: TACRAdvancedFieldType;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  Result := FDataType;
end;//GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TACRExprNodeSubQuery.GetDataSize: Integer;
begin
  if (FDataType = aftUnknown) then
    DetectType;
  Result := FDataSize;
end;//GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRExprNodeSubQuery.CreateCopy(aParentExpr: TACRExpression): TACRExprNode;
begin
  Result := TACRExprNodeSubQuery.Create(aParentExpr);
  TACRExprNodeSubQuery(Result).FQuery := TACRSQLUnion(FQuery.MakeCopy(aParentExpr.Session,aParentExpr.LocalParams));
  if (FSourceNode <> nil) then
   TACRExprNodeSubQuery(Result).FSourceNode := FSourceNode.MakeCopy(aParentExpr)
  else
   TACRExprNodeSubQuery(Result).FSourceNode := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TACRExprNodeSubQuery.Assign(Source: TACRExprNode);
begin
  FResultDatasetFieldNo := -1;
  FCorrelated := False;
  FDataType := aftUnknown;
  if (FQuery <> nil) then
   FQuery.Free;
  if (TACRExprNodeSubQuery(Source).FQuery <> nil) then
   FQuery := TACRSQLUnion(TACRExprNodeSubQuery(Source).FQuery.MakeCopy(
      TACRExprNodeSubQuery(Source).FQuery.FDatabaseParams.Session,
      TACRExprNodeSubQuery(Source).FQuery.LParams));
  FNot := TACRExprNodeSubQuery(Source).FNot;
  Operator := TACRExprNodeSubQuery(Source).Operator;
  FComparisonOperator := TACRExprNodeSubQuery(Source).FComparisonOperator;
  FCaseInsensitive  := TACRExprNodeSubQuery(Source).FCaseInsensitive;
  FPartialKey  := TACRExprNodeSubQuery(Source).FPartialKey;
  if (FSourceNode <> nil) then
   FreeAndNil(FSourceNode);
  if (TACRExprNodeSubQuery(Source).FSourceNode <> nil) then
    FSourceNode := TACRExprNode(TACRExprNodeSubQuery(Source).FSourceNode).MakeCopy(LParentExpr);
end; // Assign


//------------------------------------------------------------------------------
// updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
//------------------------------------------------------------------------------
procedure TACRExprNodeSubQuery.UpdateExpressionParams;
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
// TACRDDLCreateView
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLCreateView.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLCreateView.Create(nil,FDatabaseParams,LStoredFunction);
end; // Parse


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDDLCreateView.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
destructor TACRDDLCreateView.Destroy;
begin
  if (FColumnNames <> nil) then
   FreeAndNil(FColumnNames);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRDDLCreateView.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FIfNotExists := TACRDDLCreateView(Source).FIfNotExists;
  FWithCheckOption := TACRDDLCreateView(Source).FWithCheckOption;
  FSelectStatement := TACRDDLCreateView(Source).FSelectStatement;
  if (FColumnNames <> nil) then
   FreeAndNil(FColumnNames);
  if (TACRDDLCreateView(Source).FColumnNames <> nil) then
  begin
   FColumnNames := TACRWideStringList.Create;
   FColumnNames.Assign(TACRDDLCreateView(Source).FColumnNames);
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
procedure TACRDDLCreateView.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(12585, ErrorGBlankSqlCommand);
  FIfNotExists := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (not IsReservedWord(Token,rwNOT)) then
     raise EACRException.Create(12586, ErrorGOtherTokenExpected,
         ['NOT EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
     FIfNotExists := True;
    end
    else
     raise EACRException.Create(12587, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;

  if (Token.TokenType in [tktString, tktQuotedString,
                tktBackQuotedString, tktBracketedString]) then
  begin
   TableName := Token.Text;
   if (not GetNextToken) then
      raise EACRException.Create(12600,ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
  end
  else
   raise EACRException.Create(12599,ErrorGViewNameExpected,
         [Token.Text, Token.LineNum, Token.ColumnNum]);

  if (Token.TokenType = tktLeftParenthesis) then
  begin
    if (FColumnNames <> nil) then
     FColumnNames.Clear
    else
     FColumnNames := TACRWideStringList.Create;
    // parse columns
    if (not GetNextToken) then
      raise EACRException.Create(12588, ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
    while (token.TokenType <> tktRightParenthesis) do
    begin
     if (Token.TokenType = tktComma) then
      if (not GetNextToken) then
        raise EACRException.Create(12589, ErrorGUnexpectedEndOfCommand,
              [Token.LineNum, Token.ColumnNum]);
     FColumnNames.Add(Token.Text);
     if (not GetNextToken) then
       raise EACRException.Create(12590, ErrorGUnexpectedEndOfCommand,
              [Token.LineNum, Token.ColumnNum]);
     if ((Token.TokenType <> tktComma) and (Token.TokenType <> tktRightParenthesis)) then
       raise EACRException.Create(12591, ErrorGRightParenthesisOrCommaExpected,
             [Token.Text,Token.LineNum, Token.ColumnNum]);
    end; // while not right parenthesis
    if (not GetNextToken) then
     raise EACRException.Create(12592, ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
    if (FColumnNames <> nil) then
     if (FColumnNames.Count <= 0) then
      FreeAndNil(FColumnNames);
  end; // parse column names
  // AS
  if (Token.ReservedWord <> rwAS)  then
   raise EACRException.Create(12593, ErrorGOtherTokenExpected,
         [GetReservedWord(rwAS),Token.Text,Token.LineNum, Token.ColumnNum]);
  if (not GetNextToken) then
   raise EACRException.Create(12594, ErrorGUnexpectedEndOfCommand,
          [Token.LineNum, Token.ColumnNum]);
  // SELECT
  if (Token.ReservedWord <> rwSELECT)  then
   raise EACRException.Create(12595, ErrorGOtherTokenExpected,
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
       raise EACRException.Create(12596, ErrorGUnexpectedEndOfCommand,
              [Token.LineNum, Token.ColumnNum]);
     if (Token.ReservedWord = rwCHECK) then
     begin
       if (not GetNextToken) then
         raise EACRException.Create(12597, ErrorGUnexpectedEndOfCommand,
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
procedure TACRDDLCreateView.ExecSQL(
            IsRoot,
            RequestLive:  Boolean;
            var ReadOnly: Boolean
           );
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12598,ErrorLNilPointer);
  if (FIfNotExists) then
   if (FDatabaseParams.Session.TableExists(TableName)) then
    Exit;
  FDatabaseParams.Session.CreateView(TableName,
      FSelectStatement,FColumnNames,FWithCheckOption,FComment);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRDDLDropView
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDDLDropView.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDDLDropView.Create(nil,FDatabaseParams,LStoredFunction);
end; // ExecSQL


//------------------------------------------------------------------------------
// asign
//------------------------------------------------------------------------------
procedure TACRDDLDropView.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FCascade := TACRDDLDropView(Source).FCascade;
end; // Assign


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TACRDDLDropView.Parse;
begin
  if (not GetNextToken) then
    raise EACRException.Create(12601,ErrorGBlankSQLCommand);
  FCascade := False;
  if (IsReservedWord(Token,rwIF)) then
   begin
    GetNextToken;
    if (IsReservedWord(Token,rwEXISTS)) then
    begin
     GetNextToken;
    end
    else
     raise EACRException.Create(12602, ErrorGOtherTokenExpected,
         ['EXISTS', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
  if (Token.TokenType in [tktString, tktQuotedString,
                tktBackQuotedString, tktBracketedString]) then
  begin
   TableName := Token.Text;
   if (not GetNextToken) then
      raise EACRException.Create(12603,ErrorGUnexpectedEndOfCommand,
            [Token.LineNum, Token.ColumnNum]);
  end
  else
   raise EACRException.Create(12604,ErrorGViewNameExpected,
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
procedure TACRDDLDropView.ExecSQL(
            IsRoot,
            RequestLive:  Boolean;
            var ReadOnly: Boolean
           );
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12605,ErrorLNilPointer);
  FDatabaseParams.Session.DropView(TableName,FCascade);
end; // ExecSQL


//------------------------------------------------------------------------------
// set field value from ACRVariant
//------------------------------------------------------------------------------
procedure SetACRVariantIntoField(Value: TACRVariant; Field: TField);
var
  s:  AnsiString;
  bs: TStream;
  i:  Integer;
begin
  if Value = nil then
    raise EACRException.Create(30359, ErrorGValueIsNull);

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
end;//SetACRVariantIntoField


//------------------------------------------------------------------------------
// destroy commands
//------------------------------------------------------------------------------
procedure ACRClearCommands(Commands: TList);
var i: Integer;
begin
  for i := 0 to Commands.Count-1 do
   try
     TACRSQLCommand(Commands.Items[i]).Free;
   except
   end;
end; // ACRClearCommands


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRSQLProcessor> initialized');
{$ENDIF}

end.
