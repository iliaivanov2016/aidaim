{$I ETblVer.inc}

unit ETblSQLCommand;

interface

uses classes, windows, sysutils, db,
     ETblConst, ETblExcept, ETblLexer, ETblCommon, ETblRelationalAlgebra,
{$IFDEF DEBUG_FLAG}
 aaDebug,
{$ENDIF}
     ETblExpr;

type
 // ORDER BY clause element
 TETblSortSpecification = record
  TableName: AnsiString;   // table or its pseudonym
  ColumnName: AnsiString;  // field name or pseudonym
  Descending: Boolean; // ASC | DESC
 end;

 // table | joined table | subquery
 TETblTableType = (ettTable, ettJoinedTable, ettSubQuery);
 // reference to the "table" in FROM clause
 TETblTableReference = class (TObject)
  TableType:        TETblTableType;     // Table | JoinedTable | SubQuery
  DatabaseName:     AnsiString;             // database1
  TableName:        AnsiString;             // table1
  Pseudonym:        AnsiString;             // table1 as t1
  Password:         AnsiString;             // table1 PASSWORD 'password'
  InMemory:         Boolean;            // [MEMORY]
  NaturalJoin:      Boolean;            // Natural join?
  JoinType:         TETblJoinType;      // inner | left | ...
  LeftTable:        TETblTableReference; // left table in join
  RightTable:       TETblTableReference; // right table in join
  UsingFields:      TStringList;         // join column list
  SearchCondition:  TETblExpression;     // ON '(t1.Field1 = t2.Field2)'

  // creates
  constructor Create;
  // destroys
  destructor Destroy; override;
  // makes join (left and right node-table)
  procedure MakeJoin(RightNode: TETblTableReference; JType: TETblJoinType;
                     IsNatural: Boolean; Fields: TStringList;
                     OnCondition: TETblExpression);
 end;

 // base class for TEasySQLSelect, TEasySQLUpdate, ...
 TEasySQLCommand = class (TEasyParser)
  protected
   IntoMemory:            Boolean;   // into memory table?

   // parses list of columns (without table name): field1, field2, ...
   procedure ParseColumnList(var Fields: TStringList);
   // parses list of fields:  table.field1, field2, ..
   procedure ParseFieldList(var Fields: TETblFields);

  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = False); virtual;
   // gets result dataset
   function GetResultDataset: TDataset; virtual;
 end;

 // base class for SQL command with cursor
 TEasySQLCursorCommand = class (TEasySQLCommand)
  protected
   FQueryComponent:       TDataset;  // source query component
   RootAO:                TEasyAO;   // top level AO
   ResultDataset:         TDataset;  // query component
   IntoDatabase:          AnsiString;    // select into <database>.<table>
   IntoTable:             AnsiString;    // select into <database>.<table>
   //IntoMemory:            Boolean;   // select into memory table?

  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroys object
   destructor Destroy; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = False); override;
   // builds AO tree
   function BuildAOTree(query: TDataset): TEasyAO; virtual;
   // gets result dataset
   function GetResultDataset: TDataset; override;
   // gets result AO
   function GetResultAO: TEasyAO;
 end;

 // Select SQL command
 TEasySQLSelect = class (TEasySQLCursorCommand)
  protected
   Distinct:              Boolean; // ALL | DISTINCT
   TopRowCount:           Integer; // TOP (-1 | n)
   FirstRowNo:            Integer; // TOP row count [, first row] 
   AllFields:             Boolean; // Select *
   SelectList:            array of TETblSelectListItem; // fields list
   SelectListCount:       integer; // count of array elements
   FromTables:            array of TETblTableReference; // From clause
   FromTablesCount:       integer; // count of array elements
   SearchCondition:       TETblExpression;  // WHERE clause
   GroupByFields:         TETblFields; // GROUP BY field1, f2, ...
   HavingCondition:       TETblExpression;  // HAVING clause
   OrderBySpecs:          array of TETblSortSpecification;
   OrderBySpecsCount:     integer;

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
   function ParseJoinCondition(var SearchCondition: TETblExpression): Boolean;
   // USING <join columns>
   function ParseNamedColumnsJoin(var Fields: TStringList): Boolean;
   // CROSS JOIN | INNER JOIN | ...
   function ParseJoin(var tblRef: TETblTableReference): Boolean;
   // <table name> [ [ AS ] <correlation name> ...
   function ParseTableReference(tblRef: TETblTableReference=nil): Boolean;
   // FROM ...
   function ParseFromClause: Boolean;
   // WHERE ...
   function ParseWhereClause: Boolean;
   // GROUP BY ...
   function ParseGroupByClause: Boolean;
   // HAVING ...
   function ParseHavingClause: Boolean;
   // <sort key> [ <collate clause> ] [ <ordering specification> ]
   function ParseSortSpecification: Boolean;
   // ORDER BY
   function ParseOrderByClause: Boolean;

   // gets default database name
   function GetDefaultDatabaseName: AnsiString;
   // creates and adjusts table AO
   function CreateTableAO(var TableRef: TETblTableReference): TEasyAO;
   // creates and adjusts joined table AO
   function CreateJoinedTableAO(var TableRef: TETblTableReference): TEasyAO;
   // creates and adjusts AO
   function CreateAO(var TableRef: TETblTableReference): TEasyAO;
   // builds one-table AO
   function BuildOneTableTree: TEasyAO;
   // builds multi-tables AO tree
   function BuildMultiTablesTree: TEasyAO;
   // applies Order By clause
   procedure ApplyOrderBy(AO: TEasyAO);
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // builds AO tree
   function BuildAOTree(query: TDataset): TEasyAO; override;
 end;

 // table | joined table | subquery
 TETblQueryExprType = (qetSelect, qetUnion, qetExcept, qetIntersect);

 // select | union | except | ...
 TETblQueryExprNode = class (TObject)
  NodeType:         TETblQueryExprType; // node is: select | union | except | ...
  Left:             TETblQueryExprNode; // left node in union, except, ...
  Right:            TETblQueryExprNode; // right table in union, except, ...
  All:              Boolean;            // [ALL] specified?
  Corresponding:    Boolean;            // [CORRESPONDING] specified?
  CorrespondingFields: TStringList;     // column list
  SelectCommand:    TEasySQLSelect;     // SELECT command (if NodeType is select)

  // creates
  constructor Create; overload;
  // creates copy
  constructor Create(Src: TETblQueryExprNode); overload;
  // destroys
  destructor Destroy; override;
  // adds new node to the tree
  procedure AddNode(NewType: TETblQueryExprType; RightNode: TETblQueryExprNode;
                    bAll, bCorresponding: Boolean; ColumnList: TStringList=nil);
 end;

 // UNION SQL command
 TEasySQLUnion = class (TEasySQLCursorCommand)
  protected
   FRootNode: TETblQueryExprNode;         // root node in unions,excepts tree

   // parses [ALL]
   function ParseAll: Boolean;

   // parses [ <corresponding spec> ]
   function ParseCorrespondingSpec(var ColumnsList: TStringList): Boolean;

   // parses SELECT ...
   function ParseQuerySpecification: TETblQueryExprNode;

   // parses <query specification> | <table value constructor>  | <explicit table>
   function ParseSimpleTable: TETblQueryExprNode;

   // parses <simple table> |
   // <left paren> <non-join query expression> <right paren>
   function ParseNonJoinQueryPrimary: TETblQueryExprNode;

   // parses <non-join query primary> |
   // <query term> INTERSECT [ ALL ] [ <corresponding spec> ] <query primary>
   function ParseNonJoinQueryTerm: TETblQueryExprNode;

   // parses <non-join query term> |
   // <query expression> UNION  [ ALL ] [ <corresponding spec> ] <query term> |
   // <query expression> EXCEPT [ ALL ] [ <corresponding spec> ] <query term>
   function ParseNonJoinQueryExpression: TETblQueryExprNode;

   // parses <non-join query expression>  | <joined table>
   function ParseQueryExpression: TETblQueryExprNode;

   // builds AO
   function BuildAO(Node: TETblQueryExprNode): TEasyAO;

  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // builds AO tree
   function BuildAOTree(query: TDataset): TEasyAO; override;
 end;

 TEasySQLInsert = class (TEasySQLCommand)
  protected
   TableName:             AnsiString;  // Table Name
   Password:              AnsiString;  // table password
   FieldNames:            TStringList;
   FieldValues:           TList;
   InternalSelecter:      TEasySQLSelect;
   procedure ParseValuesList;
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = False); override;
 end;

 TEasySQLUpdate = class (TEasySQLCommand)
  protected
   TableName:             AnsiString;  // Table Name
   Password:              AnsiString;  // table password
   FieldNames:            TStringList;
   FieldValues:           TList;
   InternalSelecter:      TEasySQLSelect;
   procedure SetFieldValue(field: TField; value: AnsiString);
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override;
 end;
 
 TEasySQLDelete = class (TEasySQLCommand)
  protected
   InternalSelecter:      TEasySQLSelect;
   TableName:             AnsiString;  // Table Name
   FullDelete: boolean;
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroys object
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = False); override;
 end;

 TRequaredType = (rtRequared, rtNotRequared, rtUndefined);

 // FieldDef element
 TEasyFieldDef = record
  FieldName: AnsiString;       // field name or pseudonym
  FieldType: TFieldType;   // field type
  Length: Integer;         // field length ex: AnsiString(255)
  Required: TRequaredType; // is Requared field
 end;

 TEasyDDLTableManipulation = class (TEasySQLCommand)
  protected
   Password:              AnsiString;  // table password
   BlobBlockSize:         integer; // BLOB block size
   BlobCompressionLevel:  integer; // BLOB Compression Mode (0-undefined)
                                   // (clNone=1,clFastest=2,clDefault=3,clMax=4)
   LastAutoIncValue:      integer; // Last AutoInc Value
   TableName:             AnsiString;  // Table Name
   TETFieldDefs:          array of TEasyFieldDef; // FieldDefs
   PrimaryKey:            TStringList;
   UseAutoIndexes:        boolean; // Auto Creating Indexes

   // table element list
   procedure ParseTableElementList;
   // parse TableName token
   procedure ParseTableNameToken;
   // Fill table column type into Structure
   procedure FillColumnType(var FieldDef:TEasyFieldDef);
   // Fill column requared value into Structure
   procedure FillColumnRequared(var FieldDef:TEasyFieldDef);
   // parse PASSWORD 'aaa'
   procedure ParsePassword;
   // parse BlobCompressionLevel
   procedure ParseBlobCompressionLevel;
   // parse BlobBlockSize
   procedure ParseBlobBlockSize;
   // parse LastAutoIncValue
   procedure ParseLastAutoIncValue;
   // parse Primary Key
   function ParsePrimaryKey: boolean;
   // parse AutoIndexes
   procedure ParseAutoIndexes;
   // Create EasyTable object and fill EasyTable params
   function CreateInternalEasyTable(query: TDataSet): TDataSet;
   // alter table modify AutoIncValue
   procedure UpdateAutoInc(tet: TDataSet);
   // fill PrimaryKey for TET
   procedure AddPrimaryKey(tet: TDataSet);
   // Delete PrimaryKey
   procedure DeletePrimaryKey(tet: TDataSet);
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // destroy
   destructor Destroy; override;
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override; abstract;
 end;

 TEasyDDLCreateTable = class (TEasyDDLTableManipulation)
  protected
   // Create Table
   procedure CreateTable(query: TDataSet);
  public
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override;
 end;

 TEasyDDLDropTable = class (TEasyDDLTableManipulation)
  protected
   // parse TableName token
   //procedure ParseTableNameToken;
   // Drop Table
   procedure DropTable(query: TDataSet);
  public
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override;
 end;

 // Types of alter table
 TAlterType = (atAdd, atDrop, atModify);

 TEasyDDLAlterTable = class (TEasyDDLTableManipulation)
  protected
   // AlterType token
   AlterType: TAlterType;
   NewPassword: AnsiString;
   NewEncrypted: Boolean;
   // parse AlterType token
   procedure ParseAlterTypeToken;
   // parse AlterType token
   procedure ParseNewPasswordToken;
   // Alter Table
   procedure DropColumn(tet: TDataSet);
   procedure AddColumn(tet: TDataSet);
   procedure Modify(tet: TDataSet);
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override;
 end;

 // IndexFieldDef element

 TEasyIndexField  = record
  FieldName: AnsiString;       // field name or pseudonym
  desc: boolean;           // desc/asc
  nocase: boolean;         // ncase/case sensitive
 end;

 TEasyDDLCreateIndex = class (TEasySQLCommand)
  protected
   Unique: boolean;
   IndexName: AnsiString;
   TableName: AnsiString;
   Password: AnsiString;
   TETIndexFields: array of TEasyIndexField; // Index Fields
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override;
 end;

 TEasyDDLDropIndex = class (TEasySQLCommand)
  protected
   TableName: AnsiString;
   IndexName: AnsiString;
   Password: AnsiString;
  public
   // creates object
   constructor Create(Lexer: TEasyLexer);
   // parses query
   procedure Parse; override;
   // executes query
   procedure ExecSQL(query: TDataset; IsRoot: Boolean = True); override;
 end;


implementation

uses EasyTable, ETblEngine;

////////////////////////////////////////////////////////////////////////////////
//
// TETblTableReference
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Creates
//------------------------------------------------------------------------------
constructor TETblTableReference.Create;
begin
  TableType := ettTable;
  LeftTable := nil;
  RightTable := nil;
  SearchCondition := nil;
  UsingFields := nil;
end;// Create


//------------------------------------------------------------------------------
// destory
//------------------------------------------------------------------------------
destructor TETblTableReference.Destroy;
begin
 if (LeftTable <> nil) then
  LeftTable.Free;
 if (RightTable <> nil) then
  RightTable.Free;
 if (UsingFields <> nil) then
  UsingFields.Free;
 if (SearchCondition <> nil) then
  SearchCondition.Free;
end;// Destroy


//------------------------------------------------------------------------------
// makes join (left and right node-table)
//------------------------------------------------------------------------------
procedure TETblTableReference.MakeJoin(RightNode: TETblTableReference; JType: TETblJoinType;
                     IsNatural: Boolean; Fields: TStringList;
                     OnCondition: TETblExpression);
var
 LeftNode: TETblTableReference;
begin
 // copy current node to left
 LeftNode := TETblTableReference.Create;
 LeftNode.TableType := TableType;
 LeftNode.DatabaseName := DatabaseName;
 LeftNode.TableName := TableName;
 LeftNode.Pseudonym := Pseudonym;
 LeftNode.Password := Password;
 LeftNode.InMemory := InMemory;
 LeftNode.NaturalJoin := NaturalJoin;
 LeftNode.JoinType := JoinType;
 LeftNode.LeftTable := LeftTable;
 LeftNode.RightTable := RightTable;
 LeftNode.UsingFields := UsingFields;
 LeftNode.SearchCondition := SearchCondition;

 // set childs
 LeftTable := LeftNode;
 RightTable := RightNode;

 // set current data as join
 TableType := ettJoinedTable;
 JoinType := JType;
 NaturalJoin := IsNatural;
 UsingFields := Fields;
 SearchCondition := OnCondition;
end;// MakeJoin



////////////////////////////////////////////////////////////////////////////////
//
// TEasySQLCommand
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Creates
//------------------------------------------------------------------------------
constructor TEasySQLCommand.Create(Lexer: TEasyLexer);
begin
  IntoMemory := False;
  FLex := Lexer;
  // parse with first token
  Parse;
end;// Create


//------------------------------------------------------------------------------
// parses list of columns (without table name): field1, field2, ...
//------------------------------------------------------------------------------
procedure TEasySQLCommand.ParseColumnList(var Fields: TStringList);
var
  s: AnsiString;

function ParseColumnName(var ColumnName: AnsiString): Boolean;
begin
 Result := False;
 if (Token.TokenType in [tktString, tktQuotedString, tktBracketedString]) then
  begin
   ColumnName := Token.Text;
   GetNextToken;
   Result := True;
  end;
end;

begin
      // get ColumnName
      if (ParseColumnName(s)) then
       // all columns
       repeat
        // create list if necessary
        if (Fields = nil) then
         Fields := TStringList.Create;
        // add column name
        Fields.Add(s);
        // ',' ?
        if (Token.TokenType <> tktComma) then
           break
        else
          // skip ',' token
          GetNextToken([tktString, tktQuotedString, tktBracketedString],01034);
        // get next field
        if (not ParseColumnName(s)) then
         raise ETblException.Create(01035, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
       until False
      else
       raise ETblException.Create(01036, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;


//------------------------------------------------------------------------------
// parses list of fields:  table.field1, field2, ..
//------------------------------------------------------------------------------
procedure TEasySQLCommand.ParseFieldList(var Fields: TETblFields);

function ParseFieldSpecification(var Fields: TETblFields): Boolean;
var
   item: TETblSelectListItem;
   TableName, FieldName: AnsiString;
   Expr: TETblExpression;
begin
 Result := True;
 // parse field as expression
 Expr := TETblExpression.Create(FLex);
 try
  Expr.ParseValueExpr;
  // only field is allowed
  if (not Expr.IsField) then
   raise ETblException.Create(01066,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);
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
          // skip ',' token
          GetNextToken([tktString, tktQuotedString, tktBracketedString,
                        tktReservedWord],01046);
       // get next spec
       if (not ParseFieldSpecification(Fields)) then
        raise ETblException.Create(01064,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     until False
    else
      raise ETblException.Create(01065,
          [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;// ParseFieldList


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TEasySQLCommand.ExecSQL(query: TDataset; IsRoot: Boolean = False);
begin
end;// ExecSQL


//------------------------------------------------------------------------------
// gets result dataset
//------------------------------------------------------------------------------
function TEasySQLCommand.GetResultDataset: TDataset;
begin
 Result := nil;
end;// GetResultDataset



////////////////////////////////////////////////////////////////////////////////
//
// TEasySQLCursorCommand
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TEasySQLCursorCommand.Create(Lexer: TEasyLexer);
begin
  RootAO := nil;
  IntoTable := '';
  IntoDatabase := '';
  //IntoMemory := False;
  inherited Create(Lexer);
end;// Create


//------------------------------------------------------------------------------
// destroy object
//------------------------------------------------------------------------------
destructor TEasySQLCursorCommand.Destroy;
begin
  if (RootAO <> nil) then
   RootAO.Free;
end;// Destroy


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TEasySQLCursorCommand.ExecSQL(query: TDataset; IsRoot: Boolean = False);
var
  NewDB: TEasyDatabase;
  dest: TEasyTable;
  ds: TDataSource;
  log: AnsiString;
begin
  FQueryComponent := query;
  RootAO := BuildAOTree(query);

  if not (IntoMemory or TEasyDataset(query).InMemory) then
   if (IntoDatabase = '') then
    IntoDatabase := TEasyDataset(query).DatabaseFileName;

  if ((not RootAO.FIsAOTable) and (IntoTable <> '')) then
   RootAO.SetResultTable(IntoMemory or TEasyDataset(query).InMemory,IntoTable,IntoDatabase);

  RootAO.Execute(IsRoot);

  // specify read-only result?
  if (IsRoot) then
   begin
    TEasyQuery(query).ReadOnly := False;
    if (not TEasyQuery(query).RequestLive) then
      TEasyQuery(query).ReadOnly := True
    else
     begin
      // not table => not updatable result
      if (not (RootAO is TEasyAOTable)) then
       TEasyQuery(query).ReadOnly := True;
     end;
   end;

  // select into table?
  if (RootAO.FIsAOTable and (IntoTable <> '')) then
   begin
    ds := nil;
    dest := nil;
    try
      ds := TDataSource.Create(nil);
      ds.DataSet := RootAO.ResultDataset;
      // set projection
      TEasyDataset(RootAO.ResultDataset).SetProjection;

      dest:= TEasyTable.Create(nil);
      dest.TableName := IntoTable;
      NewDB := TEasyDatabase.Create(nil);
      NewDB.DatabaseName :=
                  GetTemporaryName(TEasyDataset(query).Database.DatabaseName);
      if (IntoDatabase <> '') then
        NewDB.DatabaseFileName := IntoDatabase
      else
       begin
        NewDB.Handle := TEasyDataset(query).Database.Handle;
       end;
      if (NewDB.Handle <> nil) then
       begin
           if (NewDB.Handle.bDatabaseFile) then
            dest.DatabaseFileName := NewDB.Handle.FDatabaseName
           else
            dest.DatabaseName := NewDB.Handle.FDatabaseName;
           // check - if no datasets connected - destroy
           NewDB.Free;
       end;
      // set filter
      if (RootAO is TEasyAOTable) and (RootAO.FFilterExpr <> nil) then
        TEasyDataset(ds.Dataset).SetSQLFilter(RootAO.FFilterExpr);
      // unfreeze vis records
      if (TEasyDataset(ds.Dataset).VisibleRecordsFreezed) then
        TEasyDataset(ds.Dataset).UnfreezeVisibleRecords;
      dest.InMemory := IntoMemory or TEasyDataset(query).InMemory;
      if (dest.InMemory) then
       dest.DatabaseName := 'MEMORY';
      if (not dest.ImportTable(ds,nil,log)) then
       raise Exception.Create(log);
    finally
     ds.Free;
     dest.Free;
    end;
   end;
end;// ExecSQL


//------------------------------------------------------------------------------
// builds AO tree
//------------------------------------------------------------------------------
function TEasySQLCursorCommand.BuildAOTree(query: TDataset): TEasyAO;
begin
 Result := nil;
end;// BuildAOTree


//------------------------------------------------------------------------------
// gets result dataset
//------------------------------------------------------------------------------
function TEasySQLCursorCommand.GetResultDataset: TDataset;
begin
 Result := RootAO.ResultDataset;
end;// GetResultDataset


//------------------------------------------------------------------------------
// gets result AO
//------------------------------------------------------------------------------
function TEasySQLCursorCommand.GetResultAO: TEasyAO;
begin
 Result := RootAO;
end;// GetResultAO




////////////////////////////////////////////////////////////////////////////////
//
// TEasySQLSelect
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// SELECT
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseSelectToken: Boolean;
begin
  Result := IsReservedWord(Token, rwSELECT);
  if (not Result) then
   // unsupported SQL or unexpected token
   raise ETblException.Create(01005, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  GetNextToken;
end;// ParseSelectToken


//------------------------------------------------------------------------------
// DISTINCT | ALL ?
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseSetQuantifier: Boolean;
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
function TEasySQLSelect.ParseTopOperator: Boolean;
begin
  if (IsReservedWord(Token, rwTOP)) then
   begin
    // suppose 'TOP n'
    GetNextToken;
    // integer?
    if (Token.TokenType <> tktInt) then
     raise ETblException.Create(01091,
                             [Token.Text, Token.LineNum, Token.ColumnNum], nil);
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
        raise ETblException.Create(01092,
                             [Token.Text, Token.LineNum, Token.ColumnNum], nil);
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
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseSelectSubList: Boolean;
var
  FieldName, TableName, Pseudonym: AnsiString;
  AllFields: Boolean;
begin
 // handle field1 | table1.field1 | expr
  begin
   Result := True;

   // add new select list item
   inc(SelectListCount);
   SetLength(SelectList, SelectListCount);

   // parse field name | expr
   SelectList[SelectListCount-1].ValueExpr := TETblExpression.Create(FLex);
   TETblExpression(SelectList[SelectListCount-1].ValueExpr).ParseValueExpr;
   if (TETblExpression(SelectList[SelectListCount-1].ValueExpr).IsEmpty) then
    begin
     SelectList[SelectListCount-1].ValueExpr.Free;
     raise ETblException.Create(01090,
                             [Token.Text, Token.LineNum, Token.ColumnNum], nil);
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
             GetNextToken([tktString, tktQuotedString, tktBracketedString], 01010);
             // got pseudonym
             Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end
          else
          // (Field1 F1) ?
          if (Token.TokenType in
               [tktString, tktQuotedString, tktBracketedString]) then
            begin
             // got pseudonym
             Pseudonym := Token.Text;
             // look at next token
             GetNextToken;
            end;

   // expr or field?
   SelectList[SelectListCount-1].IsExpression :=
          not TETblExpression(SelectList[SelectListCount-1].ValueExpr).IsField;

   // field?
   if (not SelectList[SelectListCount-1].IsExpression) then
    begin
     // get field name, table name
     TETblExpression(SelectList[SelectListCount-1].ValueExpr).GetFieldInfo(TableName, FieldName);
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
     TETblExpression(SelectList[SelectListCount-1].ValueExpr).Free;
     TETblExpression(SelectList[SelectListCount-1].ValueExpr) := nil;
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
function TEasySQLSelect.ParseSelectList: Boolean;
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
          // skip ',' token
          GetNextToken;
        // get next field expr
        if (not ParseSelectSubList) then
         raise ETblException.Create(01021, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     until False
    else
     raise ETblException.Create(01017, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
   end;
end;// ParseSelectList


//------------------------------------------------------------------------------
// INTO <target>
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseInto: Boolean;
begin
 Result := False;
 IntoTable := '';
 IntoDatabase := '';
 IntoMemory := False;

 if (IsReservedWord(Token, rwINTO)) then
  begin
    // get table | database name
    GetNextToken([tktString, tktReservedWord, tktBracketedString, tktQuotedString],01012);
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
      GetNextToken([tktString, tktBracketedString, tktQuotedString],01012);
      IntoTable := Token.Text;
      // next token
      GetNextToken;
     end;
    Result := True;
  end;
end;// ParseInto


//------------------------------------------------------------------------------
// ON <join condition>
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseJoinCondition(var SearchCondition: TETblExpression): Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwON)) then
   begin
    Result := True;
    GetNextToken; // skip ON token
    SearchCondition := TETblExpression.Create(FLex);
    SearchCondition.ParseSearchExpression;
    if (not AllFields) then
     SearchCondition.ReplacePseudonyms(SelectList);
    // get current unhandled token
    FLex.GetCurrentToken(Token);
   end;
end;// ParseJoinCondition


//------------------------------------------------------------------------------
// USING <join columns>
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseNamedColumnsJoin(var Fields: TStringList): Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwUSING)) then
   begin
    Result := True;
    GetNextToken; // skip USING token

    // '(' ?
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
     raise ETblException.Create(01033, ['(', Token.Text, Token.LineNum, Token.ColumnNum], nil)
   end;
end;// ParseNamedColumnsJoin


//------------------------------------------------------------------------------
// CROSS JOIN | INNER JOIN | ...
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseJoin(var tblRef: TETblTableReference): Boolean;
var
 RightTblRef: TETblTableReference;
 JoinType: TETblJoinType;
 IsNatural: Boolean;
 Fields: TStringList;
 SearchCondition: TETblExpression;
begin
 Result := False;

 if (IsReservedWord(Token)) then
  repeat
     IsNatural := False; // default value
     JoinType := ejtInner; // default value
     // parse CROSS JOIN | [ NATURAL ] [ <join type> ] JOIN
     if (IsReservedWord(Token, rwCROSS)) then
      begin
          GetNextToken([tktReservedWord], 01026); // skip CROSS
          JoinType := ejtCross;
          Result := True;
      end
     else
      begin
       // [NATURAL]
       if (IsReservedWord(Token, rwNATURAL)) then
         begin
          IsNatural := True;
          GetNextToken([tktReservedWord], 01025);
          Result := True;
         end;
       // INNER?
       if (IsReservedWord(Token, rwINNER)) then
         begin
          JoinType := ejtInner;
          GetNextToken([tktReservedWord], 01027);
          Result := True;
         end
       else
        // OUTER join
        begin
         // LEFT
         if (IsReservedWord(Token, rwLEFT)) then
          begin
           JoinType := ejtLeftOuter;
           GetNextToken([tktReservedWord], 01028);
           Result := True;
          end
         else
         // RIGHT
         if (IsReservedWord(Token, rwRIGHT)) then
          begin
           JoinType := ejtRightOuter;
           GetNextToken([tktReservedWord], 01029);
           Result := True;
          end
         else
         // FULL
         if (IsReservedWord(Token, rwFULL)) then
          begin
           JoinType := ejtFullOuter;
           GetNextToken([tktReservedWord], 01030);
           Result := True;
          end;
         // [OUTER]
         if ((Result) and (IsReservedWord(Token, rwOUTER))) then
          begin
           GetNextToken([tktReservedWord], 01031);
          end;
        end;// outer join
      end; // non-cross join

     // next token - JOIN?
     if (not IsReservedWord(Token, rwJOIN)) then
      if (Result) then
       raise ETblException.Create(01024, ['JOIN', Token.Text, Token.LineNum, Token.ColumnNum], nil)
      else
       exit; // no joins
     GetNextToken;

     // get right table ref
     RightTblRef := TETblTableReference.Create;
     if not ParseTableReference(RightTblRef) then
      raise ETblException.Create(01032, [Token.Text, Token.LineNum, Token.ColumnNum], nil);

     // <join condition> | <named columns join>
     Fields := nil;
     SearchCondition := nil;
     if not ParseJoinCondition(SearchCondition) then
       ParseNamedColumnsJoin(Fields);

     // update tree to make join
     tblRef.MakeJoin(RightTblRef, JoinType, IsNatural, Fields, SearchCondition)
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
function TEasySQLSelect.ParseTableReference(tblRef: TETblTableReference=nil): Boolean;
var
  DatabaseName, TableName, Pseudonym, Password: AnsiString;
  TableType: TETblTableType;
  InMemory: Boolean;
  tRef: TETblTableReference;
begin
 Result := False;
 // handle table1 | "database 1".table1
 if (Token.TokenType in [tktString, tktReservedWord, tktQuotedString,tktBracketedString]) then
  begin
   Result := True;
   if (IsReservedWord(Token, rwMEMORY)) then
    begin
      InMemory := True;
      GetNextToken;
    end
   else
    InMemory := False;
   DatabaseName := '';
   // get table name
   TableName := Token.Text;
   // pseudonym is not specified yet
   Pseudonym := '';
   // password too
   Password := '';
   // tabletype is ettTable by default
   TableType := ettTable;
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
                           tktBracketedString], 01018);
             // got pseudonym
             Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end
      else
        if (Token.TokenType in [tktString, tktBracketedString]) then
            begin
             // got pseudonym
             Pseudonym := Token.Text;
             // get next token
             GetNextToken;
            end;
      // check password
      if (IsReservedWord(Token, rwPASSWORD)) then
       begin
        // get next token 'password'
        GetNextToken([tktQuotedString], 01058);
        Password := Token.Text;
        // get next token
        GetNextToken;
       end;
    end;
   // first table in joins chain?
   if (tblRef = nil) then
    begin
     // add new tables list item
     inc(FromTablesCount);
     SetLength(FromTables, FromTablesCount);
     FromTables[FromTablesCount-1] := TETblTableReference.Create;
     tRef := FromTables[FromTablesCount-1];
    end
   else
    tRef := tblRef;

   // store TableType
   tRef.TableType := TableType;
   // store DatabaseName
   tRef.DatabaseName := DatabaseName;
   // store TableName
   tRef.TableName := TableName;
   // store Pseudonym
   tRef.Pseudonym := Pseudonym;
   // store Password
   tRef.Password := Password;
   // store [MEMORY]
   tRef.InMemory := InMemory;
  end
 else
  // (<table reference>)
  if (Token.TokenType = tktLeftParenthesis) then
   begin
    // skip '('
    GetNextToken;
    // get table reference
    Result := ParseTableReference(tblRef);
    // get its pointer
    if (tblRef = nil) then
     tRef := FromTables[FromTablesCount-1]
    else
     tRef := tblRef;

    if not Result then
     raise ETblException.Create(01022, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // skip ')'
    if (Token.TokenType = tktRightParenthesis) then
       GetNextToken;
   end;

 // join?
 if (Result) then
   ParseJoin(tRef);
end;// ParseTableReference


//------------------------------------------------------------------------------
// FROM ...
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseFromClause: Boolean;
begin
 if (IsReservedWord(Token, rwFROM)) then
  begin
    // skip FROM token
    GetNextToken([tktString, tktReservedWord, tktQuotedString, tktBracketedString, tktLeftParenthesis],01015);
    Result := True;
    // get TableName
    if (ParseTableReference) then
     // get all tables
     repeat
        // end of sql command?
        if (Token.TokenType <> tktComma) then
          break
        else
          // skip ',' token
          GetNextToken([tktString, tktReservedWord, tktQuotedString, tktBracketedString, tktLeftParenthesis],01016);
       // get next table reference
       if (not ParseTableReference) then
        raise ETblException.Create(01020,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);

     until False
    else
      raise ETblException.Create(01019,
          [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  end
 else
   raise ETblException.Create(01014, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;// ParseFromClause


//------------------------------------------------------------------------------
// WHERE ...
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseWhereClause: Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwWHERE)) then
  begin
    Result := True;
    // skip WHERE token
    GetNextToken;
    SearchCondition := TETblExpression.Create(FLex);
    SearchCondition.ParseSearchExpression;
    if (not AllFields) then
     SearchCondition.ReplacePseudonyms(SelectList);
    // get current (not handled) token
    GetCurrentToken;
  end;
end;// ParseWhereClause


//------------------------------------------------------------------------------
// GROUP BY ...
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseGroupByClause: Boolean;
begin
 if (IsReservedWord(Token, rwGROUP)) then
  begin
    Result := True;
    // skip GROUP token
    GetNextToken;
    // 'BY' ?
    if (not IsReservedWord(Token, rwBY)) then
     raise ETblException.Create(01063, ['BY', Token.Text, Token.LineNum, Token.ColumnNum], nil);
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
function TEasySQLSelect.ParseHavingClause: Boolean;
begin
 Result := False;
 if (IsReservedWord(Token, rwHAVING)) then
  begin
    Result := True;
    // skip HAVING token
    GetNextToken;
    HavingCondition := TETblExpression.Create(FLex);
    HavingCondition.ParseSearchExpression;
    if (not AllFields) then
     HavingCondition.ReplacePseudonyms(SelectList);
    // get current (not handled) token
    GetCurrentToken;
  end;
end;// ParseHavingClause


//------------------------------------------------------------------------------
// <sort key> [ <collate clause> ] [ <ordering specification> ]
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseSortSpecification: Boolean;
begin
  Result := True;
  if (Token.TokenType in
       [tktString, tktBracketedString, tktReservedWord, tktQuotedString]) then
   begin
     // new order spec
     Inc(OrderBySpecsCount);
     SetLength(OrderBySpecs, OrderBySpecsCount);
     OrderBySpecs[OrderBySpecsCount-1].ColumnName := Token.Text;
     // get next token
     GetNextToken;
     // "." ?
     if (Token.TokenType = tktDot) then
      begin
       // previous token was table name
       OrderBySpecs[OrderBySpecsCount-1].TableName :=
                      OrderBySpecs[OrderBySpecsCount-1].ColumnName;
       // get next token - column name
       GetNextToken([tktString, tktQuotedString, tktBracketedString,
                     tktReservedWord],01050);
       OrderBySpecs[OrderBySpecsCount-1].ColumnName := Token.Text;
       // get next token
       GetNextToken;
      end;
     // ASC | DESC ?
     if (IsReservedWord(Token, rwASC)) then
      begin
       OrderBySpecs[OrderBySpecsCount-1].Descending := False;
       // skip ASC token
       GetNextToken
      end
     else
     if (IsReservedWord(Token, rwDESC)) then
      begin
       OrderBySpecs[OrderBySpecsCount-1].Descending := True;
       // skip DESC token
       GetNextToken;
      end;
   end
  else
   raise ETblException.Create(01049,
       [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;// ParseSortSpecification


//------------------------------------------------------------------------------
// ORDER BY
//------------------------------------------------------------------------------
function TEasySQLSelect.ParseOrderByClause: Boolean;
begin
 if (IsReservedWord(Token, rwORDER)) then
  begin
    Result := True;
    // skip ORDER token
    GetNextToken;
    // 'BY' ?
    if (not IsReservedWord(Token, rwBY)) then
     raise ETblException.Create(01045, ['BY', Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // skip BY token
    GetNextToken;

    // parse sort specification list
    if (ParseSortSpecification) then
     // get all specs
     repeat
        // end of sql command?
        if (Token.TokenType <> tktComma) then
          break
        else
          // skip ',' token
          GetNextToken([tktString, tktQuotedString, tktBracketedString,
                        tktReservedWord],01046);
       // get next spec
       if (not ParseSortSpecification) then
        raise ETblException.Create(01047,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);

     until False
    else
      raise ETblException.Create(01048,
          [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  end
 else
  Result := False;
end;// ParseOrderByClause


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TEasySQLSelect.Parse;
var
  State: integer;
  bOk: Boolean;
begin
   // get first token (for new query) or current token (for subquery)
   bOk := FLex.GetCurrentToken(Token);

   if (not bOk) then
      raise ETblException.Create(01004);

   state := 0;
   repeat
      // states switch (depends on a current part of query)
      case state of
       0: // SELECT
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
          ParseOrderByClause;
       else
        break;
      end;// case
      inc(state);
   until (false);

end;// Parse


//------------------------------------------------------------------------------
// gets default database name
//------------------------------------------------------------------------------
function TEasySQLSelect.GetDefaultDatabaseName: AnsiString;
begin
 Result := TEasyDataset(ResultDataset).DatabaseName;
end;// GetDefaultDatabaseName


//------------------------------------------------------------------------------
// creates and adjusts table AO
//------------------------------------------------------------------------------
function TEasySQLSelect.CreateTableAO(var TableRef: TETblTableReference): TEasyAO;
var
  DatabaseName: AnsiString;
begin
  DatabaseName := TableRef.DatabaseName;
  if (DatabaseName = '') then
   DatabaseName := GetDefaultDatabaseName;
  Result := TEasyAOTable.Create(TableRef.TableName, TableRef.Pseudonym,
                                DatabaseName,
                                TEasyDataset(ResultDataset).DatabaseFileName,
                                TEasyDataset(ResultDataset).SessionName,
                                TableRef.InMemory or TEasyTable(ResultDataset).InMemory,
                                TableRef.Password);
  // apply parts of WHERE clause if possible
//  if (SearchCondition <> nil) then
//    SearchCondition.ApplyFilterParts(Result);
end;// CreateTableAO


//------------------------------------------------------------------------------
// creates and adjusts joined table AO
//------------------------------------------------------------------------------
function TEasySQLSelect.CreateJoinedTableAO(var TableRef: TETblTableReference): TEasyAO;
var
 LeftAO, RightAO: TEasyAO;
 FieldList1, FieldList2: TETblFields;
 i: integer;
 Item1, Item2: TETblSelectListItem;

function RecursiveExtractJoinConditions(TableRef: TETblTableReference): integer;
begin
  if (TableRef.SearchCondition <> nil) then
     Result := TableRef.SearchCondition.ExtractJoinConditions(LeftAO, RightAO,
                                      FieldList1, FieldList2)
  else
   begin
     Result := 0;
     if (TableRef.TableType = ettJoinedTable) then
      begin
       if (TableRef.LeftTable.SearchCondition <> nil) then
        Result := Result + TableRef.LeftTable.SearchCondition.ExtractJoinConditions(
                         LeftAO, RightAO, FieldList1, FieldList2);

       if (TableRef.RightTable.SearchCondition <> nil) then
        Result := Result + TableRef.RightTable.SearchCondition.ExtractJoinConditions(
                         LeftAO, RightAO, FieldList1, FieldList2);

      end;
   end;
end;

begin
 // create joined tables
 LeftAO := CreateAO(TableRef.LeftTable);
 RightAO := CreateAO(TableRef.RightTable);

 // prepare column lists
 FieldList1 := nil;
 FieldList2 := nil;
 try
 // column lists required?
 if ((not TableRef.NaturalJoin) and
     (
      (TableRef.JoinType = ejtInner) or
      (TableRef.JoinType = ejtLeftOuter) or
      (TableRef.JoinType = ejtRightOuter) or
      (TableRef.JoinType = ejtFullOuter)
     )) then
  begin // build column lists
   // USING ?
   if (TableRef.UsingFields <> nil) then
    begin
      FieldList1 := TETblFields.Create;
      FieldList2 := TETblFields.Create;
      for i := 0 to TableRef.UsingFields.Count-1 do
       begin
        Item1.FieldName := TableRef.UsingFields.Strings[i];
        Item1.TableName := TableRef.LeftTable.TableName;
        Item2.FieldName := TableRef.UsingFields.Strings[i];
        Item2.TableName := TableRef.RightTable.TableName;
        FieldList1.Append(Item1);
        FieldList2.Append(Item2);
       end;
    end
   else
    begin
      FieldList1 := TETblFields.Create;
      FieldList2 := TETblFields.Create;
      // extract from ON clause
      RecursiveExtractJoinConditions(TableRef);
      // extract from WHERE clause
      if (SearchCondition <> nil) then
       SearchCondition.ExtractJoinConditions(LeftAO, RightAO,
                                       FieldList1, FieldList2);
    end
  end;

  // create join AO
  Result := TEasyAOJoin.Create(LeftAO, RightAO, TableRef.JoinType,
                               TableRef.NaturalJoin,
                              FieldList1, FieldList2);
 // set filter
 if (Result <> nil) then
  if (TableRef.SearchCondition <> nil) then
    TableRef.SearchCondition.ApplyFilterParts(Result);

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
function TEasySQLSelect.CreateAO(var TableRef: TETblTableReference): TEasyAO;
begin
 case TableRef.TableType of
  ettTable:
    Result := CreateTableAO(TableRef);
  ettJoinedTable:
    Result := CreateJoinedTableAO(TableRef);
  else
    Result := nil;
 end;
end;// CreateAO


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TEasySQLSelect.Create(Lexer: TEasyLexer);
begin
 SelectListCount := 0;
 SetLength(SelectList, 0);
 FromTablesCount := 0;
 SetLength(FromTables, 0);
 OrderBySpecsCount := 0;
 SetLength(OrderBySpecs, 0);
 SearchCondition := nil;
 HavingCondition := nil;
 GroupByFields := TETblFields.Create;
 inherited Create(Lexer);
end;// Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TEasySQLSelect.Destroy;
var
  i: integer;
begin
  if (SearchCondition <> nil) then
   SearchCondition.Free;
  if (GroupByFields <> nil) then
   GroupByFields.Free;
  if (HavingCondition <> nil) then
   HavingCondition.Free;

  for i := 0 to FromTablesCount-1 do
   FromTables[i].Free;
   
  inherited Destroy;
end;// Destroy

//------------------------------------------------------------------------------
// builds one-table AO
//------------------------------------------------------------------------------
function TEasySQLSelect.BuildOneTableTree: TEasyAO;
begin
  // create AO
  Result := CreateAO(FromTables[0]);
end;// BuildOneTableTree


//------------------------------------------------------------------------------
// builds multi-tables AO tree
//------------------------------------------------------------------------------
function TEasySQLSelect.BuildMultiTablesTree: TEasyAO;
var
  i, JoinConditionCount: integer;
  RightAO: TEasyAO;
  JoinType: TETblJoinType;
  FieldList1, FieldList2: TETblFields;
begin
 Result := CreateAO(FromTables[0]);
 // create other joins
 for i := 1 to FromTablesCount-1 do
  begin
   // init column lists
   FieldList1 := nil;
   FieldList2 := nil;
   try
    RightAO := CreateAO(FromTables[i]);
    // try to find join conditions in WHERE clause
    if (SearchCondition <> nil) then
     begin
       FieldList1 := TETblFields.Create;
       FieldList2 := TETblFields.Create;
       // try to extract conditions
       JoinConditionCount := SearchCondition.ExtractJoinConditions(Result, RightAO,
                                             FieldList1, FieldList2);
     end
    else
     JoinConditionCount := 0;

    if (JoinConditionCount = 0) then
     begin
      JoinType := ejtCross;
      if (FieldList1 <> nil) then
       FieldList1.Free;
      if (FieldList2 <> nil) then
       FieldList2.Free;
      FieldList1 := nil;
      FieldList2 := nil;
     end
    else
     JoinType := ejtInner;

    // create join AO
    Result := TEasyAOJoin.Create(Result, RightAO, JoinType, False,
                              FieldList1, FieldList2);
   finally
     if (FieldList1 <> nil) then
      FieldList1.Free;
     if (FieldList2 <> nil) then
      FieldList2.Free;
   end;
  end;
end;// BuildMultiTablesTree


//------------------------------------------------------------------------------
// builds AO tree
//------------------------------------------------------------------------------
function TEasySQLSelect.BuildAOTree(query: TDataset): TEasyAO;
var
  i: integer;
  bAnyExpressions: Boolean;
  bGroupBy: Boolean;
begin
  ResultDataset := query;
  // live result with 1 table?
  if ((FromTablesCount = 1) and (FromTables[0].TableType = ettTable)) then
    Result := BuildOneTableTree
  else
    Result := BuildMultiTablesTree;

 try
  // create group by AO?
  bGroupBy := (GroupByFields.ItemCount > 0);
  // check for aggregates in select list
  if (not bGroupBy) then
   if (not AllFields) then
    begin
     for i := 0 to SelectListCount-1 do
      if (SelectList[i].ValueExpr <> nil) then
       if (TETblExpression(SelectList[i].ValueExpr).IsAggregated) then
        begin
         bGroupBy := True;
         break;
        end;
    end;

  // if expressions, then AOTable -> AOTableExpr?
  if (not bGroupBy) and (Result is TEasyAOTable) then
   begin
    bAnyExpressions := False;
    for i := 0 to SelectListCount-1 do
     if (SelectList[i].ValueExpr <> nil) then
      if (not TETblExpression(SelectList[i].ValueExpr).IsField) then
       begin
        bAnyExpressions := True;
        break;
       end;
    // create table wrapper with expression-fields?
    if (bAnyExpressions) then
      Result := TEasyAOTableExpr.Create(Result);
   end;

  // apply parts of WHERE clause if possible
  if (SearchCondition <> nil) then
     SearchCondition.ApplyFilterParts(Result); 
 
  // create GroupByAO, apply having condition
  if (bGroupBy) then 
   begin
    try
     Result := TEasyAOGroupBy.Create(Result, GroupByFields); 
    except
     // to avoid duplicated destroying 
     Result := nil;
     for i := 0 to SelectListCount-1 do 
      if (SelectList[i].ValueExpr <> nil) then
       begin 
        SelectList[i].ValueExpr.Free; 
        SelectList[i].ValueExpr := nil; 
       end;
	
     raise;
    end; 
    if (HavingCondition <> nil) then 
      HavingCondition.ApplyFilterParts(Result); 
   end;
 
  // sets projection
  Result.SetResultFields(SelectList,Distinct);
 
  // check pseudonyms duplicates
  Result.CheckDuplicatedTablePseudonyms; 
	
  // apply pseudonames parts of WHERE clause if possible 
  if (SearchCondition <> nil) then 
   begin
     SearchCondition.ApplyFilterParts(Result); 
     if (not SearchCondition.IsEmpty) then
       raise ETblException.Create(01069, [SearchCondition.GetFilter(Result)], nil); 
   end;
	
  // sort - order by 
  ApplyOrderBy(Result);
	
  // TOP n?
  if (TopRowCount > -1) then
   Result.SetTopRowCount(FirstRowNo, TopRowCount);
 except 
  if (Assigned(Result)) then
   Result.Free;
  raise;
 end;
end;// BuildAOTree 
	
 
//------------------------------------------------------------------------------
// applies Order By clause
//------------------------------------------------------------------------------
procedure TEasySQLSelect.ApplyOrderBy(AO: TEasyAO);
var 
  i: integer;
  ColumnName, TableName: AnsiString; 
  FieldNumber: TaaIntArray; 
  FieldName: AnsiString;
  IndexFieldNames, DescFields: AnsiString; 
begin 
  if (OrderBySpecsCount = 0) then
   exit;
  FieldNumber := TaaIntArray.Create;
  try 
    // for all sort specs
    for i := 0 to OrderBySpecsCount-1 do 
     begin 
      ColumnName := OrderBySpecs[i].ColumnName;
      TableName := OrderBySpecs[i].TableName; 
      // get field No in AO
      FieldNumber.SetSize(0); 
      AO.FieldExists(ColumnName, TableName, 
                     not (AO is TEasyAOGroupBy), FieldNumber); 
      if (FieldNumber.ItemCount = 0) then 
       raise ETblException.Create(01051, [ColumnName], nil);
	
// commented by Leo Martin - duplicate field names ok if one of them is hidden       
	
//      else 
//      if (FieldNumber.ItemCount > 1) then
//       raise ETblException.Create(01057, [ColumnName], nil); 
      FieldName := AO.GetFieldName(FieldNumber.Items[0], False); 
      // all index fields
      if (IndexFieldNames = '') then
       IndexFieldNames := FieldName
      else 
       IndexFieldNames := IndexFieldNames + ';'+FieldName;
      // desc index fields
      if (OrderBySpecs[i].Descending) then 
       if (DescFields = '') then 
        DescFields := FieldName 
       else
        DescFields := DescFields + ';'+FieldName;
     end;
     AO.SetIndex(IndexFieldNames, DescFields, '');
  finally 
   FieldNumber.Free;
  end; 
end;// ApplyOrderBy 
 
	
 
 
	
//////////////////////////////////////////////////////////////////////////////// 
//
// TETblQueryExprNode (UNION, EXCEPT, ...)
//
////////////////////////////////////////////////////////////////////////////////
	
	
//------------------------------------------------------------------------------ 
// creates object 
//------------------------------------------------------------------------------ 
constructor TETblQueryExprNode.Create; 
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
// creates copy
//------------------------------------------------------------------------------
constructor TETblQueryExprNode.Create(Src: TETblQueryExprNode);
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
// destroys object
//------------------------------------------------------------------------------
destructor TETblQueryExprNode.Destroy;
begin
 if (Left <> nil) then
  Left.Free;
 if (Right <> nil) then
  Right.Free;

 if (SelectCommand <> nil) then
  SelectCommand.Free;
end;// Destroy


//------------------------------------------------------------------------------
// adds new node to the tree
//------------------------------------------------------------------------------
procedure TETblQueryExprNode.AddNode(NewType: TETblQueryExprType; RightNode: TETblQueryExprNode;
                    bAll, bCorresponding: Boolean; ColumnList: TStringList=nil);
var
 LeftNode: TETblQueryExprNode;
begin
 // copy current node to left
 LeftNode := TETblQueryExprNode.Create(Self);

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



////////////////////////////////////////////////////////////////////////////////
//
// TEasySQLUnion
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TEasySQLUnion.Create(Lexer: TEasyLexer);
begin
 FRootNode := nil; // not parsed yet
 inherited Create(Lexer);
end;// Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TEasySQLUnion.Destroy;
begin
  if (FRootNode <> nil) then
   FRootNode.Free;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// parses [ALL]
//------------------------------------------------------------------------------
function TEasySQLUnion.ParseAll: Boolean;
begin
  Result := IsReservedWord(Token, rwALL);
  // skip token
  if (Result) then
   GetNextToken;
end;// ParseAll


//------------------------------------------------------------------------------
// parses [ <corresponding spec> ]
//------------------------------------------------------------------------------
function TEasySQLUnion.ParseCorrespondingSpec(var ColumnsList: TStringList): Boolean;
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
      // '(' ?
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
       raise ETblException.Create(01060, ['(', Token.Text, Token.LineNum, Token.ColumnNum], nil)
     end;
   end;
end;// ParseCorrespondingSpec


//------------------------------------------------------------------------------
// parses SELECT ...
//------------------------------------------------------------------------------
function TEasySQLUnion.ParseQuerySpecification: TETblQueryExprNode;
var
  SelectNode: TETblQueryExprNode;
begin
  if (IsReservedWord(Token, rwSELECT)) then
   begin
    SelectNode := TETblQueryExprNode.Create;
    SelectNode.NodeType := qetSelect;
    try
     SelectNode.SelectCommand := TEasySQLSelect.Create(FLex);
     GetCurrentToken;
    except
     SelectNode.Free;
     raise;
    end;
    Result := SelectNode;
   end
  else
   raise ETblException.Create(01061, ['SELECT', Token.Text, Token.LineNum, Token.ColumnNum], nil)
end;// ParseQuerySpecification


//------------------------------------------------------------------------------
// parses <query specification> | <table value constructor>  | <explicit table>
//------------------------------------------------------------------------------
function TEasySQLUnion.ParseSimpleTable: TETblQueryExprNode;
begin
  Result := ParseQuerySpecification;
end;// ParseSimpleTable


//------------------------------------------------------------------------------
// parses <simple table> |
// <left paren> <non-join query expression> <right paren>
//------------------------------------------------------------------------------
function TEasySQLUnion.ParseNonJoinQueryPrimary: TETblQueryExprNode;
begin
  // '(' ?
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
function TEasySQLUnion.ParseNonJoinQueryTerm: TETblQueryExprNode;
var
  RightNode: TETblQueryExprNode;
  bAll, bCorresponding: Boolean; // union or except
  ColumnList: TStringList; // corresponding spec
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
function TEasySQLUnion.ParseNonJoinQueryExpression: TETblQueryExprNode;
var
  RightNode: TETblQueryExprNode;
  bUnion, bAll, bCorresponding: Boolean; // union or except
  ColumnList: TStringList; // corresponding spec
  NewType: TETblQueryExprType;
begin
  // parse <non-join query term>
  Result := ParseNonJoinQueryTerm;

  // unions | excepts?
  while (IsReservedWord(Token, rwUNION) or
         IsReservedWord(Token, rwMINUS) or
         IsReservedWord(Token, rwEXCEPT)) do
   begin
     // union or except?
     bUnion := IsReservedWord(Token, rwUNION);
     // skip UNION | EXCEPT token
     GetNextToken;
     if (bUnion) then
      NewType := qetUnion
     else
      NewType := qetExcept;

     // [ALL]
     bAll := ParseAll;

     // [ <corresponding spec> ]
     bCorresponding := ParseCorrespondingSpec(ColumnList);

     // parse <non-join query term>
     RightNode := ParseNonJoinQueryTerm;

     // make union | except node
     Result.AddNode(NewType, RightNode, bAll, bCorresponding, ColumnList);
   end;
end;// ParseNonJoinQueryExpression


//------------------------------------------------------------------------------
// parses <non-join query expression>  | <joined table>
//------------------------------------------------------------------------------
function TEasySQLUnion.ParseQueryExpression: TETblQueryExprNode;
begin
  Result := ParseNonJoinQueryExpression;
end;// ParseQueryExpression


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TEasySQLUnion.Parse;
begin
  GetCurrentToken;
  FRootNode := ParseQueryExpression;
  // store INTO parameters
  if (FRootNode.NodeType = qetSelect) then
   begin
    IntoTable := FRootNode.SelectCommand.IntoTable;
    IntoDatabase := FRootNode.SelectCommand.IntoDatabase;
    IntoMemory := FRootNode.SelectCommand.IntoMemory;
   end;
end;// Parse


//------------------------------------------------------------------------------
// builds AO
//------------------------------------------------------------------------------
function TEasySQLUnion.BuildAO(Node: TETblQueryExprNode): TEasyAO;
var
  LeftAO, RightAO: TEasyAO;
  UnionType: TETblUnionType;
  CorrespondingFields: TETblFields;
  Item: TETblSelectListItem;
  i: integer;
begin
 if (Node.NodeType = qetSelect) then
   Result := Node.SelectCommand.BuildAOTree(ResultDataset)
 else
  begin
    // union | except | intersect
    LeftAO := BuildAO(Node.Left);
    RightAO := BuildAO(Node.Right);

    UnionType := eutUnion;
    case (Node.NodeType) of
      qetUnion:
         UnionType := eutUnion;
      qetExcept:
         UnionType := eutExcept;
      qetIntersect:
         UnionType := eutIntersect;
    end;

    if (Node.CorrespondingFields <> nil) then
     begin
      CorrespondingFields := TETblFields.Create;
      // fill fields list
      Item.TableName := '';
      Item.Pseudonym := '';
      Item.AllFields := False;
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
     Result := TEasyAOUnion.Create(LeftAO, RightAO, UnionType,
                                  Node.Corresponding, not Node.All,
                                  CorrespondingFields);
    finally
     if (CorrespondingFields <> nil) then
      CorrespondingFields.Free;
    end;
  end;
end;// BuildAO


//------------------------------------------------------------------------------
// builds AO tree
//------------------------------------------------------------------------------
function TEasySQLUnion.BuildAOTree(query: TDataset): TEasyAO;
begin
  ResultDataset := query;
  Result := BuildAO(FRootNode);
end;// BuildAOTree



{ TEasySQLCreateTable }

procedure TEasyDDLCreateTable.CreateTable(query: TDataset);
var
  tet: TEasyTable;
begin
  tet := CreateInternalEasyTable(query) as TEasyTable;
  // If table already exists - raise
  if tet.Exists then
   raise ETblException.Create(02117,[tet.TableName], nil);
  try
    try
      AddPrimaryKey(tet);
      tet.CreateTable;
      UpdateAutoInc(tet);
    except
      on e:Exception do
        raise ETblException.Create(02014, [e.Message], nil);
    end
  finally
    tet.Free;
  end
end;

procedure TEasyDDLCreateTable.ExecSQL(query: TDataset; IsRoot: Boolean = True);
begin
  CreateTable(query);
end;

procedure TEasyDDLCreateTable.Parse;
begin
  if (not GetNextToken) then raise ETblException.Create(01004);
  ParseTableNameToken;
  ParseTableElementList;
  inherited;
end;// Parse

{ TEasyDDLDropTable }

procedure TEasyDDLDropTable.DropTable(query: TDataSet);
var
  tet: TEasyTable;
begin
  tet := CreateInternalEasyTable(query) as TEasyTable;
  try
    try
      tet.DeleteTable;
    except
      on e:Exception do
        raise ETblException.Create(02033, [e.Message], nil);
    end;
  finally
    tet.Free;
  end
end;

procedure TEasyDDLDropTable.ExecSQL(query: TDataset; IsRoot: Boolean = True);
begin
  DropTable(query);
end;

procedure TEasyDDLDropTable.Parse;
begin
  if (not GetNextToken) then raise ETblException.Create(02037);
  ParseTableNameToken;
  inherited;
end;

{procedure TEasyDDLDropTable.ParseTableNameToken;
begin
  if Token.TokenType in [tktString, tktQuotedString, tktBracketedString] then
    TableName := Token.Text
  else
    raise ETblException.Create(02038,
                   [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;
}
{ TEasyDDLTableManipulation }

constructor TEasyDDLTableManipulation.Create(Lexer: TEasyLexer);
begin
  Password := '';
  BlobBlockSize := 0;        // BLOB block size
  BlobCompressionLevel := 0; // BLOB Compression Mode
  LastAutoIncValue := 0;     // Last AutoInc Value
  TableName:='';             // Table Name
  UseAutoIndexes := false;   // AutoIndexes OFF
  SetLength(TETFieldDefs,0);
  PrimaryKey := TStringList.Create;
  inherited Create(Lexer);
end;

function TEasyDDLTableManipulation.CreateInternalEasyTable(
  query: TDataset): TDataSet;
var
  i: Integer;
begin
  Result := TEasyTable.Create(query.Owner);
  with Result as TEasyTable do
    begin
      DatabaseName := TEasyQuery(query).DatabaseName;
      if ((query as TEasyQuery).DatabaseFileName <> '') then
       DatabaseFileName := (query as TEasyQuery).DatabaseFileName;
      SessionName := TEasyQuery(query).SessionName;
      // Table Name
      TableName := Self.TableName;
      // Memory
      InMemory := IntoMemory or TEasyDataset(query).InMemory;
      if InMemory then DatabaseName := 'memory';
      // Password
      if Self.Password <> '' then Password := Self.Password;
      Encrypted := Self.Password <> '';
      // Autoindexes
      AutoIndexes := UseAutoIndexes;
      // Blob Compression Level
      if Self.BlobCompressionLevel <> 0 then
        BLOBCompression :=
          SUPPORTED_BLOB_COMPRESSION_LEVELS[Self.BlobCompressionLevel].Level;
      // Blob Blok Size
      if self.BlobBlockSize <> 0 then
        BLOBBlockSize := self.BlobBlockSize;
      //Active := false;
      //FieldDefs.Clear;
      for i:=0 to length(TETFieldDefs)-1 do
        with TETFieldDefs[i] do
          FieldDefs.Add(FieldName,FieldType,Length,Required=rtRequared);
      //FillPrimaryKey(Result);
    end;
end;

procedure TEasyDDLTableManipulation.Parse;
begin
   // check for not expected token
   if (FLex.LookNextToken(Token)) then
    raise ETblException.Create(02015, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

procedure TEasyDDLTableManipulation.ParseBlobBlockSize;
begin
  if Token.ReservedWord <> rwBLOB_BLOCK_SIZE then exit;
  GetNextToken([tktInt],02023);
  BlobBlockSize := StrToInt(Token.Text);
  GetNextSpecifiedToken([tktComma, tktRightParenthesis],02024);
end;

procedure TEasyDDLTableManipulation.ParseBlobCompressionLevel;
var s: AnsiString;
    i: Integer;
begin
  if Token.ReservedWord <> rwBLOB_COMPRESSION_LEVEL then exit;
  GetNextToken([tktString, tktReservedWord],02019);
  s := UpperCase(Token.Text);
  for i:=1 to MAX_SUPPORTED_BLOB_COMPRESSION_LEVELS do
    with SUPPORTED_BLOB_COMPRESSION_LEVELS[i] do
      if name = s then begin
        BlobCompressionLevel := i;
        break;
      end;
  if BlobCompressionLevel=0 then
    raise ETblException.Create(02020,
                  [Token.Text,Token.LineNum,Token.ColumnNum], nil);

  GetNextSpecifiedToken([tktComma, tktRightParenthesis],02021);
end;

procedure TEasyDDLTableManipulation.FillColumnType(
  var FieldDef:TEasyFieldDef);
begin
  // column type
  FieldDef.FieldType := GetFieldType(Token.Text);
  // Unknown type ?
  if FieldDef.FieldType = ftUnknown then
    raise ETblException.Create(02007,
                 [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  // sizeble type ? ex: AnsiString(255)
  if FieldDef.FieldType in [ftString, ftWideString, ftBytes] then
    begin
     // '('
     GetNextToken([tktLeftParenthesis],02008);
     // Int
     GetNextToken([tktInt],02009);
     FieldDef.Length := StrToInt(Token.Text);
     // ')'
     GetNextToken([tktRightParenthesis],02010);
    end
  else
    FieldDef.Length := 0;
end;

procedure TEasyDDLTableManipulation.ParseLastAutoIncValue;
begin
  if not IsReservedWord(Token, rwLAST_AUTOINC) then exit;
  GetNextToken([tktInt],02026);
  LastAutoIncValue := StrToInt(Token.Text);
  GetNextSpecifiedToken([tktComma, tktRightParenthesis],02027);
end;

procedure TEasyDDLTableManipulation.ParsePassword;
begin
  if Token.ReservedWord <> rwPASSWORD then exit;
  GetNextToken([tktQuotedString],02016);
  Password := Token.Text;
  GetNextSpecifiedToken([tktComma, tktRightParenthesis],02017);
end;

procedure TEasyDDLTableManipulation.ParseTableElementList;
var
  FieldDef: TEasyFieldDef;
begin
  if Token.TokenType <> tktLeftParenthesis then
    raise ETblException.Create(02004,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  repeat
    // end of create table sql ')' ?
    if Token.TokenType=tktRightParenthesis then break;
    GetNextToken([tktString, tktQuotedString, tktBracketedString, tktReservedWord],02005);
    // end of column list?
    if IsReservedWord(Token, rwPASSWORD) then
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
    if IsReservedWord(Token, rwLAST_AUTOINC) then
     begin
      ParseLastAutoIncValue;
      continue;
     end else
    if IsReservedWord(Token, rwPRIMARY) then
     begin
      if ParsePrimaryKey then continue;
     end else
    if IsReservedWord(Token, rwAUTOINDEXES) or
       IsReservedWord(Token, rwNOAUTOINDEXES) then
     begin
      ParseAutoIndexes;
      continue;
     end;

    // column name
    FieldDef.FieldName := Token.Text;

    GetNextToken([tktString, tktBracketedString, tktReservedWord],02006);

    // Fill Column Type
    FillColumnType(FieldDef);

    // Default Not Required
    FieldDef.Required := rtNotRequared;
    // until ',' or ')' or 'any_word' after FIELDNAME FIELDTYPE ...
    repeat
      GetNextSpecifiedToken([tktComma, tktRightParenthesis,
                             tktString, tktQuotedString, tktBracketedString,
                             tktReservedWord],2044);
      if Token.ReservedWord in [rwNOT,rwNULL] then
        // Fill Column Required value
        FillColumnRequared(FieldDef);
    until Token.TokenType in [tktComma,tktRightParenthesis];

    SetLength(TETFieldDefs, length(TETFieldDefs) + 1);
    TETFieldDefs[length(TETFieldDefs)-1] := FieldDef;
  until False;
end;

procedure TEasyDDLTableManipulation.ParseTableNameToken;
begin
  if not (Token.TokenType in [tktString, tktReservedWord, tktBracketedString]) then
    raise ETblException.Create(02003,
                   [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  // MEMORY
  if IsReservedWord(Token, rwMEMORY) then
   begin
    IntoMemory := true;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBracketedString],02152);
   end;
  // table_name
  TableName := Token.Text;
  GetNextToken;
  {if not GetNextToken then raise ETblException.Create(02029,
                            [Token.LineNum, Token.ColumnNum], nil);}
end;

// Update AutoInc (don't worked !!!)
procedure TEasyDDLTableManipulation.UpdateAutoInc(tet: TDataSet);
begin
  if LastAutoIncValue = TEasyTable(tet).LastAutoIncValue then Exit;
  with tet as TEasyTable do
    begin
      Open;
      SetAutoIncValue(self.LastAutoIncValue+1);
      Close;
    end;
end;

procedure TEasyDDLTableManipulation.FillColumnRequared(
  var FieldDef: TEasyFieldDef);
begin
  FieldDef.Required := rtNotRequared;
  if IsReservedWord(Token, rwNOT) then
    begin
      GetNextToken([tktReservedWord],02012);
      if IsReservedWord(Token, rwNULL) then
        FieldDef.Required := rtRequared
      else raise ETblException.Create(02011,
                 [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    end
  else
    if IsReservedWord(Token, rwNULL) then
      FieldDef.Required := rtNotRequared;
end;

//------------------------------------------------------------------------------
// parse Primary Key
//------------------------------------------------------------------------------
function TEasyDDLTableManipulation.ParsePrimaryKey: boolean;
var
  TokenNo: Integer;
begin
  Result := false;
  // PRIMARY
  if Token.ReservedWord <> rwPRIMARY then exit;
  TokenNo := FLex.GetCurrentTokenNo;
  GetNextToken;
  // KEY
  if Token.ReservedWord <> rwKEY then
   begin
    FLex.SetCurrentTokenNo(TokenNo, Token);
    exit;
   end;
  GetNextToken;
  // '('
  if Token.TokenType <> tktLeftParenthesis then
   begin
    PrimaryKey.Add('');   
    exit;
   end;
//    raise ETblException.Create(02118,
//                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  repeat
   GetNextToken;
   // FieldName
   if Token.TokenType in [tktString, tktReservedWord] then
    PrimaryKey.Add(Token.Text)
   else raise ETblException.Create(02119,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
   // ')' or ','
   GetNextToken;
   if not (Token.TokenType in [tktComma, tktRightParenthesis]) then
    raise ETblException.Create(02120,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  until Token.TokenType = tktRightParenthesis;
  // get next token
  GetNextToken;
  Result := true;
end;//ParsePrimaryKey


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyDDLTableManipulation.Destroy;
begin
  PrimaryKey.Free;
  inherited;
end;//Destroy

procedure TEasyDDLTableManipulation.AddPrimaryKey(tet: TDataSet);
var
  i: integer;
  s,d: AnsiString;
  pkName: AnsiString;
begin
 if PrimaryKey.Count = 0 then exit;
 with tet as TEasyTable do
  begin
   d:='';
   s:='';
   for i:=0 to PrimaryKey.Count-1 do
    begin
     s := s + d + PrimaryKey[i];
     d := ',';
    end;
   //IndexDefs.Clear;
   repeat
     pkName := GetTemporaryName('PK_'+PrimaryKey[0]);
   until (IndexDefs.IndexOf(pkName) < 0);  
   IndexDefs.Add(pkName,s,[ixPrimary]);
   RestructureIndexDefs.Add(pkName,s,[ixPrimary]);
  end;
end;

procedure TEasyDDLTableManipulation.DeletePrimaryKey(tet: TDataSet);
var
  i: integer;

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
  indDefs := TIndexDefs.Create(tet);
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
  if TEasyTable(tet).IndexDefs.Count <> 0 then
   with TEasyTable(tet) do
    begin
     for i:=0 to IndexDefs.Count-1 do
      begin
       if ixPrimary in IndexDefs[i].Options then
        begin
         DeleteIndexDef(IndexDefs, i);
         break;
        end;
      end;
     for i:=0 to RestructureIndexDefs.Count-1 do
      begin
       if ixPrimary in IndexDefs[i].Options then
        begin
         DeleteIndexDef(RestructureIndexDefs, i);
         break;
        end;
      end;
    end;
end;

procedure TEasyDDLTableManipulation.ParseAutoIndexes;
begin
  UseAutoIndexes := (Token.ReservedWord = rwAUTOINDEXES);
  GetNextSpecifiedToken([tktComma, tktRightParenthesis],-1);
end;

{ TEasyDDLAlterTable }

procedure TEasyDDLAlterTable.AddColumn(tet: TDataSet);
var
  i: integer;
begin
  with (tet as TEasyTable).RestructureFieldDefs do
   begin
    for i:=0 to length(TETFieldDefs)-1 do with TETFieldDefs[i] do
      Add(FieldName, FieldType, Length, Required=rtRequared);
   end;
  DeletePrimaryKey(tet);
  AddPrimaryKey(tet);
end;

constructor TEasyDDLAlterTable.Create(Lexer: TEasyLexer);
begin
  NewPassword := '';
  NewEncrypted := false;
  inherited Create(Lexer);
end;

procedure TEasyDDLAlterTable.DropColumn(tet: TDataSet);
var
  i, ind: Integer;
  {$IFNDEF D5H}
  fds: TFieldDefs;
  j: Integer;
  {$ENDIF}
begin
  {$IFDEF D5H}
  with (tet as TEasyTable).RestructureFieldDefs do
    for i:=0 to length(TETFieldDefs)-1 do
      begin
        ind := IndexOf(TETFieldDefs[i].FieldName);
        if ind <> -1 then Delete(ind);
      end;
  {$ELSE}
  fds := TFieldDefs.Create(tet);
  try
    for i:=0 to TEasyTable(tet).RestructureFieldDefs.Count-1 do
      begin
        ind := -1;
        for j:=0 to length(TETFieldDefs)-1 do
          if AnsiCompareText(TETFieldDefs[j].FieldName,
               TEasyTable(tet).RestructureFieldDefs[i].Name) = 0 then
            begin
              ind := j;
              break;
            end;
        if ind = -1 then
          with TEasyTable(tet).RestructureFieldDefs[i] do
            fds.Add(Name,DataType,Size, Required);
      end;
    TEasyTable(tet).RestructureFieldDefs.assign(fds);
  finally
    fds.Free;
  end;
  {$ENDIF}
  DeletePrimaryKey(tet);
end;

procedure TEasyDDLAlterTable.ExecSQL(query: TDataset; IsRoot: Boolean = True);
var
  tet: TEasyTable;
  compr: TCompressionLevel;
begin
  tet := TEasyTable.Create(query.Owner);
  try
    try
      with tet do
        begin
          DatabaseName := TEasyQuery(query).DatabaseName;
          if ((query as TEasyQuery).DatabaseFileName <> '') then
          tet.DatabaseFileName := (query as TEasyQuery).DatabaseFileName;
          SessionName := TEasyQuery(query).SessionName;
          // Table Name
          TableName := Self.TableName;
          // Password
          if Self.Password <> '' then Password := Self.Password;
          Encrypted := Self.Password <> '';
          // Memory
          InMemory := IntoMemory or TEasyDataset(query).InMemory;
          if InMemory then DatabaseName := 'memory';
          // get RestructureFieldDefs
          Open;
          case AlterType of
            atDrop:    DropColumn(tet);
            atAdd:     AddColumn(tet);
            atModify:  Modify(tet);
          end;
          // Last AutoInc Value
          if self.LastAutoIncValue = 0 then
            self.LastAutoIncValue := tet.LastAutoIncValue;
          // Blob Block Size
          if self.BlobBlockSize = 0 then
            self.BlobBlockSize := tet.BLOBBlockSize;
          // Blob Compression Level
          compr:=tet.BLOBCompression;
          if self.BlobCompressionLevel <> 0 then
            compr := SUPPORTED_BLOB_COMPRESSION_LEVELS[
                       Self.BlobCompressionLevel].Level;
          // new password
          if not NewEncrypted then
            self.NewPassword := self.Password;
          Close;
          // Autoindexes
          AutoIndexes := UseAutoIndexes;
          // Restructure
          RestructureTable(self.NewPassword<>'', self.NewPassword,
                           self.BlobBlockSize, compr);
          // LastAutoIncValue
          if self.LastAutoIncValue <> 0 then UpdateAutoInc(tet);
        end;
    except
      on e:Exception do
        raise ETblException.Create(02047, [e.Message], nil);
    end
  finally
    tet.Free;
  end
end;

procedure TEasyDDLAlterTable.Modify(tet: TDataSet);
var
  i, ind: Integer;
begin
  with (tet as TEasyTable).RestructureFieldDefs do
    for i:=0 to length(TETFieldDefs)-1 do
      begin
        ind := IndexOf(TETFieldDefs[i].FieldName);
        if ind = -1 then
          raise ETblException.Create(02048, [TETFieldDefs[i].FieldName], nil);
        // Field Type
        if TETFieldDefs[i].FieldType <> ftUnknown then
          begin
            items[ind].DataType := TETFieldDefs[i].FieldType;
            items[ind].Size := TETFieldDefs[i].Length;
          end;
        // Field Required
        if TETFieldDefs[i].Required <> rtUndefined then
          items[ind].Required := TETFieldDefs[i].Required=rtRequared;
      end;
  DeletePrimaryKey(tet);
  AddPrimaryKey(tet);
end;

procedure TEasyDDLAlterTable.Parse;
var
  FieldDef: TEasyFieldDef;
begin
  if (not GetNextToken) then raise ETblException.Create(02039);

  // Parse Table Name
  ParseTableNameToken;

  // Parse Alter Table Type
  ParseAlterTypeToken;

  if Token.TokenType <> tktLeftParenthesis then
    raise ETblException.Create(02004,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  repeat
    // end of create table sql ')' ?
    if Token.TokenType=tktRightParenthesis then break;
    GetNextToken([tktString, tktQuotedString, tktBracketedString, tktReservedWord],02005);
    // end of column list?
    if Token.ReservedWord in [rwPASSWORD, rwBLOB_COMPRESSION_LEVEL,
         rwBLOB_BLOCK_SIZE, rwLAST_AUTOINC, rwNEW, rwPRIMARY,
         rwAUTOINDEXES, rwNOAUTOINDEXES] then
      begin
        case Token.ReservedWord of
          rwPASSWORD: ParsePassword;
          rwBLOB_COMPRESSION_LEVEL: ParseBlobCompressionLevel;
          rwBLOB_BLOCK_SIZE: ParseBlobBlockSize;
          rwLAST_AUTOINC: ParseLastAutoIncValue;
          rwNEW: ParseNewPasswordToken;
          rwPRIMARY: ParsePrimaryKey;
          rwAUTOINDEXES,
          rwNOAUTOINDEXES: ParseAutoIndexes;
        end;
        continue;
      end;

    // column name
    FieldDef.FieldName := Token.Text;
    //GetNextToken([tktString, tktReservedWord],02006);

    // Fill Column Type and (NULL or NOT NULL)
    FieldDef.FieldType := ftUnknown;

    // until ',' or ')' or 'any_word' after FIELDNAME FIELDTYPE ...
    repeat
      GetNextSpecifiedToken([tktComma, tktRightParenthesis,
                             tktString, tktQuotedString, tktBracketedString,
                             tktReservedWord],2044);
      case Token.ReservedWord of
        rwNOT,rwNULL: // Fill Column Requared value
                      FillColumnRequared(FieldDef);
        else          // data type ?
          if GetFieldType(Token.Text) <> ftUnknown then
            begin
              FillColumnType(FieldDef);
              if Token.TokenType in [tktComma,tktRightParenthesis] then
                GetNextToken;
            end;
      end;
    until Token.TokenType in [tktComma,tktRightParenthesis];

    SetLength(TETFieldDefs, length(TETFieldDefs) + 1);
    with TETFieldDefs[length(TETFieldDefs)-1] do
      begin
        FieldName := FieldDef.FieldName;
        FieldType := FieldDef.FieldType;
        Length := FieldDef.Length;
        Required := FieldDef.Required;
      end;
  until False
end;

procedure TEasyDDLAlterTable.ParseAlterTypeToken;
begin
  if Token.TokenType = tktReservedWord then
    case Token.ReservedWord of
     rwADD:    AlterType := atAdd;
     rwDROP:   AlterType := atDrop;
     rwMODIFY: AlterType := atModify;
    else
      raise ETblException.Create(02040,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    end
  else
    raise ETblException.Create(02041,
                   [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  if not GetNextToken then raise ETblException.Create(02042,
                             [Token.LineNum, Token.ColumnNum], nil);
end;

procedure TEasyDDLAlterTable.ParseNewPasswordToken;
begin
  GetNextToken([tktReservedWord],02016);
  if Token.ReservedWord <> rwPASSWORD then exit;
  GetNextToken([tktQuotedString],02016);
  NewPassword := Token.Text;
  NewEncrypted := true;
  GetNextSpecifiedToken([tktComma, tktRightParenthesis],02017);
end;

{ TEasyDDLCreateIndex }

constructor TEasyDDLCreateIndex.Create(Lexer: TEasyLexer);
begin
  Unique:=false;
  SetLength(TETIndexFields,0);
  inherited Create(Lexer);
end;

procedure TEasyDDLCreateIndex.ExecSQL(query: TDataset; IsRoot: Boolean = True);
var
   tet:TEasyTable;
   Fields, DescFields, CaseInsFields: AnsiString;
   delim1,delim2,delim3: AnsiString;
   i: Integer;
   Options: TIndexOptions;
begin
   Fields:=''; DescFields:=''; CaseInsFields:='';
   delim1:=''; delim2:=''; delim3:='';
   for i:=0 to Length(TETIndexFields)-1 do
     begin
       Fields := Fields + delim1 + TETIndexFields[i].FieldName;
       delim1 := ';';
       if TETIndexFields[i].desc then
         begin
           DescFields := DescFields + delim2 + TETIndexFields[i].FieldName;
           delim2 := ';';
         end;
       if TETIndexFields[i].nocase then
         begin
           CaseInsFields := CaseInsFields + delim3 + TETIndexFields[i].FieldName;
           delim3 := ';';
         end;
     end;
   // Index Options
   if Unique then
     Options:=[ixUnique]
   else
     Options:=[];
   // Creating
   tet := TEasyTable.Create(query.Owner);
   try
     tet.DatabaseName := TEasyQuery(query).DatabaseName;
     if ((query as TEasyQuery).DatabaseFileName <> '') then
       tet.DatabaseFileName := (query as TEasyQuery).DatabaseFileName;
     tet.SessionName := TEasyQuery(query).SessionName;
     // Table Name
     tet.TableName := TableName;
     // Memory
     tet.InMemory := IntoMemory or TEasyDataset(query).InMemory;
     if tet.InMemory then
      tet.DatabaseName := 'memory';
     tet.Password := Password;
     tet.Open;
     tet.AddIndex(IndexName, Fields, Options, DescFields, CaseInsFields);
     tet.Close;
   finally
     tet.Free;
   end;
end;

procedure TEasyDDLCreateIndex.Parse;
begin
  if not FLex.GetCurrentToken(Token) then
    raise ETblException.Create(02051);
  // UNIQUE
  if IsReservedWord(Token, rwUNIQUE) then
    begin
      Unique:=true;
      GetNextToken([tktReservedWord],02052);
    end;
  // INDEX
  if not IsReservedWord(Token, rwINDEX) then
    raise ETblException.Create(02052,
             [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  // Index_name
  GetNextToken([tktReservedWord,tktString,tktQuotedString,tktBracketedString],02053);
  IndexName := Token.Text;
  // ON
  GetNextToken([tktReservedWord],02054);
  if not IsReservedWord(Token, rwON) then
    raise ETblException.Create(02054,
                 [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  // table_name
  GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBracketedString],02055);
  IntoMemory := False;              
  if (IsReservedWord(Token,rwMEMORY)) then
   begin
    IntoMemory := True;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBracketedString],02160);
   end;

  TableName := Token.Text;
  // '('
  GetNextToken([tktLeftParenthesis],02056);
  // column list...
  repeat
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBracketedString],02057);
    // Password
    if IsReservedWord(Token, rwPassword) then
      begin
        GetNextToken([tktQuotedString],02059);
        Password := Token.Text;
        GetNextSpecifiedToken([tktComma, tktRightParenthesis]);
      end
    else
      begin
        SetLength(TETIndexFields, Length(TETIndexFields)+1);
        with TETIndexFields[Length(TETIndexFields)-1] do
          begin
            // Column name
            FieldName := Token.Text;
            // default ASC
            desc := false;
            // default CASE
            nocase := false;
            repeat
              GetNextToken(02058);
              case Token.ReservedWord of
                rwASC:    desc:=false;
                rwDESC:   desc:=true;
                rwCASE:   nocase:=false;
                rwNOCASE: nocase:=true;
              end;
            until Token.TokenType in [tktComma, tktRightParenthesis];
          end;
      end;
  until Token.TokenType = tktRightParenthesis;

  // check for not expected token
  if (FLex.LookNextToken(Token)) then
    raise ETblException.Create(02050,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

{ TEasyDDLDropIndex }

constructor TEasyDDLDropIndex.Create(Lexer: TEasyLexer);
begin
  Password:='';
  inherited Create(Lexer);
end;

procedure TEasyDDLDropIndex.ExecSQL(query: TDataset; IsRoot: Boolean = True);
var
   tet:TEasyTable;
begin
   tet := TEasyTable.Create(query.Owner);
   try
     tet.DatabaseName := TEasyQuery(query).DatabaseName;
     if ((query as TEasyQuery).DatabaseFileName <> '') then
       tet.DatabaseFileName := (query as TEasyQuery).DatabaseFileName;
     tet.SessionName := TEasyQuery(query).SessionName;
     // Table Name
     tet.TableName := TableName;
     // Memory
     tet.InMemory := IntoMemory or TEasyDataset(query).InMemory;
     if tet.InMemory then
      tet.DatabaseName := 'memory';
     tet.Password := Password;
     tet.Open;
     tet.DeleteIndex(IndexName);
     tet.Close;
   finally
     tet.Free;
   end;
end;

procedure TEasyDDLDropIndex.Parse;
begin
  GetNextToken(02060);
  IntoMemory := False;
  if (IsReservedWord(Token,rwMEMORY)) then
   begin
    IntoMemory := True;
    GetNextToken(02161);
   end;
  // table_name
  TableName:=Token.Text;
  GetNextToken(02063);
  // '.'
  if Token.TokenType <> tktDot then
    raise ETblException.Create(02064,
             ['.', Token.Text, Token.LineNum, Token.ColumnNum], nil);
  // index_name
  GetNextToken( 02065);
  IndexName:=Token.Text;
  // password
  if GetNextToken then
    if IsReservedWord(Token, rwPassword) then
      begin
        GetNextToken([tktQuotedString],02066);
        Password := Token.Text;
      end;

  // check for not expected token
  if (FLex.LookNextToken(Token)) then
    raise ETblException.Create(02061,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

{ TEasySQLInsert }

constructor TEasySQLInsert.Create(Lexer: TEasyLexer);
begin
  FieldNames := TStringList.Create;
  FieldValues := TList.Create;
  InternalSelecter := nil;
  inherited Create(Lexer);
end;

destructor TEasySQLInsert.Destroy;
var
  i: integer;
begin
  Password:='';
  FieldNames.Free;
  for i:=0 to FieldValues.Count-1 do
    TETblExpression(FieldValues[i]).Free;
  FieldValues.Free;
  if Assigned(InternalSelecter) then
    InternalSelecter.Free;
  inherited;
end;

procedure TEasySQLInsert.ExecSQL(query: TDataset; IsRoot: Boolean = False);
var
   tet:TEasyTable;
   i: Integer;
   ds: TDataSet;
   TmpTable: TEasyTable;
   TmpDataSource: TDataSource;
   s: AnsiString;
   DataValue: TETblDataValue;
   FieldNo: Integer;
   BlobParamName: AnsiString;
   Param:         TParam;
begin
  tet := TEasyTable.Create(query.Owner);
  try
    tet.DatabaseName := (query as TEasyQuery).DatabaseName;
    if ((query as TEasyQuery).DatabaseFileName <> '') then
     tet.DatabaseFileName := (query as TEasyQuery).DatabaseFileName;
    tet.SessionName := (query as TEasyQuery).SessionName;
    tet.TableName := TableName;
    tet.Password := Password;
    tet.FastOpen := True;
    tet.InMemory := IntoMemory or TEasyDataset(query).InMemory;
    if tet.InMemory then tet.DatabaseName := 'memory';
     tet.Open;
    if not Assigned(InternalSelecter) then
      begin
        tet.Insert;
        for i:=0 to FieldValues.Count-1 do
          begin
            // Get Value
            DataValue := TETblExpression(FieldValues[i]).GetDataValue(query);
            try
              // check for blob data
              if AnsiPos('$Blob$Marker$',AnsiString(DataValue.pData)) > 0 then
               begin
                BlobParamName := AnsiString(DataValue.pData);
                Delete(BlobParamName,1,13);
                FinalizeDataValue(DataValue);
                DataValue.DataType := ftBlob;
                Param := (query as TEasyQuery).ParamByName(BlobParamName);
                DataValue.DataSize := Param.GetDataSize;
                DataValue.IsNull := DataValue.DataSize = 0;
                if not DataValue.IsNull then
                 begin
                  DataValue.pData := AllocMem(DataValue.DataSize);
                  Param.GetData(DataValue.pData);
  //                DataValue.IsDataLinked := true;
                  DataValue.IsDataLinked := false;
                 end;
               end;
              // Get Field No
              if (FieldNames.Count = FieldValues.Count) and
                 (FieldNames[i]<>'') then
                FieldNo := tet.DMHandle.InternalGetFieldNo(FieldNames[i])
              else
                FieldNo := i;
              // Cast Type of Data to Field DataType
              if DataValue.DataType <> ftBlob then
               Cast(DataValue, tet.DMHandle.InternalGetFieldType(FieldNo));

              // Check for dublicate
              if DataValue.DataType = ftAutoInc then
               if TEasyDataset(tet).GetTablePositionByID(
                    GetDataValueAsInteger(DataValue), true, true) <> -1 then
                begin
                 tet.Cancel;
                 raise ETblException.Create(02158, [GetDataValueAsInteger(DataValue)],nil);
                end;

              // Set Data to Field
              tet.SetFieldValue(DataValue, FieldNo);
            finally
             FinalizeDataValue(DataValue);
            end;
          end;
        tet.Post;
      end
    else
      begin

// Not supportied yet
//raise ETblException.Create(02078);

        InternalSelecter.ExecSQL(query, IsRoot);
        ds := InternalSelecter.GetResultDataset;
        // AOTable requires additional set of SQLFilterExpr
        if (InternalSelecter.GetResultAO is TEasyAOTable) then
         begin
          TEasyDataset(ds).SetSQLFilter(InternalSelecter.GetResultAO.FFilterExpr);
          // apply filter
          TEasyDataset(ds).UnfreezeVisibleRecords;
         end;
        // apply filter
        TEasyDataset(ds).UnfreezeVisibleRecords;
        // set projection
        TEasyDataset(ds).SetProjection;

        TmpDataSource := TDataSource.Create(nil);
        TmpDataSource.DataSet := ds;

        TmpTable := TEasyTable.Create(nil);
        TmpTable.DatabaseName := 'MEMORY';
        TmpTable.InMemory := true;
        repeat
          TmpTable.TableName := GetTemporaryName('TAidAimInsert');
        until (not TmpTable.Exists);
        TmpTable.ImportTable(TmpDataSource,nil,s);

        ds := TmpTable;
        ds.First;

        try
        while not ds.Eof do
          begin
           tet.Insert;
            for i:=0 to ds.fields.Count-1 do
              begin

                // Get Src Value
                TEasyDataset(ds).GetFieldValue(DataValue,
                  TEasyDataset(ds).DMHandle.InternalGetFieldNo(ds.Fields[i].FieldName));

                // Get Dst Field No
                FieldNo := i;
//                if (FieldNames.Count = FieldValues.Count) then
                 if (FieldNames.Count > 0) then
                   if (FieldNames[i]<>'') then
                    FieldNo := tet.DMHandle.InternalGetFieldNo(FieldNames[i]);
  
                // Cast Type of Data to Field DataType
                cast(DataValue, tet.DMHandle.InternalGetFieldType(FieldNo));
                // Check for dublicate
                if DataValue.DataType = ftAutoInc then
                 if TEasyDataset(tet).GetTablePositionByID(
                      GetDataValueAsInteger(DataValue), true, true) <> -1 then
                  begin
                   tet.Cancel;
                   raise ETblException.Create(02159, [GetDataValueAsInteger(DataValue)],nil);
                  end;
                // Set Data to Field
                tet.SetFieldValue(DataValue, FieldNo);
              end;
            tet.Post;
            ds.Next;
          end;
        finally
          TmpTable.Free;
          TmpDataSource.Free;
        end;
      end;
    tet.Close;
  finally
    tet.Free;
  end;
end;

procedure TEasySQLInsert.Parse;
begin
  if not FLex.GetCurrentToken(Token) then
    raise ETblException.Create(02070);
  GetNextToken(02071);
  // INTO
  if not IsReservedWord(Token, rwINTO) then
    raise ETblException.Create(02071,
             [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  // MEMORY
  GetNextToken([tktReservedWord,tktString,tktQuotedString,
                tktBracketedString],02072);

  if IsReservedWord(Token, rwMEMORY) then
   begin
    IntoMemory := true;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBracketedString],02150);
   end;
  // table_name
  TableName := Token.Text;

  // PASSWORD ?
  GetNextToken(02075);
  if IsReservedWord(Token, rwPASSWORD) then
    begin
      GetNextToken([tktQuotedString],02080);
      Password := Token.Text;
      GetNextToken(02079);
    end;
  // '(' ?
  if Token.TokenType = tktLeftParenthesis then
    begin
      // list...
      repeat
        GetNextToken;
        if not (Token.TokenType in [tktString,tktQuotedString,
                                    tktBracketedString,tktReservedWord]) then
          raise ETblException.Create(02156,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);

        //GetNextToken(02073);
        FieldNames.Add(Token.Text);

        GetNextToken([tktComma, tktRightParenthesis], 02074);
      until Token.TokenType = tktRightParenthesis;
      // ')'
      GetNextToken(02076);
    end;
  // 'VALUES' ?
  if Token.ReservedWord = rwVALUES then
    begin
      GetNextToken([tktLeftParenthesis],02077);
      ParseValuesList;
    end
  else
    if Token.ReservedWord = rwSELECT then
      InternalSelecter := TEasySQLSelect.Create(FLex);
end;

procedure TEasySQLInsert.ParseValuesList;
var
  expr: TETblExpression;
begin
  // '(' ?
  if Token.TokenType <> tktLeftParenthesis then Exit;
  // list...
  repeat
    GetNextToken(02073);
    expr := TETblExpression.Create(FLex);
    expr.ParseValueExpr;
    GetCurrentToken;
    FieldValues.Add(expr);

    //GetNextToken([tktComma, tktRightParenthesis], 02074);
  until Token.TokenType = tktRightParenthesis;
  // ')'
end;

{ TEasySQLDelete }

constructor TEasySQLDelete.Create(Lexer: TEasyLexer);
begin
  InternalSelecter := nil;
  FullDelete := false;
  TableName := '';
  inherited Create(Lexer);
end;

destructor TEasySQLDelete.Destroy;
begin
  if Assigned(InternalSelecter) then
    InternalSelecter.Free;
  inherited;
end;

procedure TEasySQLDelete.ExecSQL(query: TDataset; IsRoot: Boolean = False);
var
  ds: TDataSet;
  RowsAffected: integer;
begin
  InternalSelecter.ExecSQL(query, IsRoot);
  ds := InternalSelecter.GetResultDataset;

  // AOTable requires additional set of SQLFilterExpr
  if (InternalSelecter.GetResultAO is TEasyAOTable) then
   begin
    TEasyDataset(ds).SetSQLFilter(InternalSelecter.GetResultAO.FFilterExpr);
    // apply filter
    TEasyDataset(ds).UnfreezeVisibleRecords;
   end;

  TEasyDataset(ds).DBSession.LockSession;
  RowsAffected := 0;
  try
   ds.First;
   while not ds.Eof do
    begin
     ds.Delete;
     Inc(RowsAffected);
    end;
  finally
   TEasyDataset(ds).DBSession.UnlockSession;
   TEasyQuery(query).RowsAffected := RowsAffected;
  end;
end;

procedure TEasySQLDelete.Parse;
var
   i: integer;
begin
  // CONVERT DELETE TO SELECT
  with  FLex.Commands[FLex.CurrentCommandNo] do
    begin
      SetLength(Tokens, length(Tokens)+1);
      inc(NumTokens);
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
  if not FLex.GetCurrentToken(Token) then
    raise ETblException.Create(02081);

  InternalSelecter := TEasySQLSelect.Create(FLex);

end;

{ TEasySQLUpdate }

constructor TEasySQLUpdate.Create(Lexer: TEasyLexer);
begin
  InternalSelecter := nil;
  FieldNames  := TStringList.Create;
  FieldValues := TList.Create;
  TableName := '';
  inherited Create(Lexer);
end;

destructor TEasySQLUpdate.Destroy;
var
  i: integer;
begin
  if Assigned(InternalSelecter) then
    InternalSelecter.Free;
  FieldNames.Free;
  for i:=0 to FieldValues.Count-1 do
    ETblException(FieldValues[i]).Free;
  FieldValues.Free;
  inherited;
end;

procedure TEasySQLUpdate.ExecSQL(query: TDataset; IsRoot: Boolean = True);
var
  ds: TDataSet;
  i: Integer;
  DataValue: TETblDataValue;
  FieldNo: Integer;
  RowsAffected: integer;

  BlobParamName: AnsiString;
  Param:         TParam;

  oldRecCount: Integer;
begin
  InternalSelecter.ExecSQL(query, IsRoot);
  ds := InternalSelecter.GetResultDataset;

  // AOTable requires additional set of SQLFilterExpr
  if (InternalSelecter.GetResultAO is TEasyAOTable) then
   begin
    TEasyDataset(ds).SetSQLFilter(InternalSelecter.GetResultAO.FFilterExpr);
    // apply filter
    TEasyDataset(ds).UnfreezeVisibleRecords;
   end;
  // set projection
//  TEasyDataset(ds).SetProjection;

  TEasyDataset(ds).DBSession.LockSession;
  RowsAffected := 0;
  try
    ds.First;

    for i:=0 to FieldNames.Count-1 do
     TETblExpression(FieldValues[i]).AssignAO(InternalSelecter.GetResultAO);

    while not ds.Eof do
      begin

        ds.Edit;
        for i:=0 to FieldNames.Count-1 do
         begin
          // Get Data Value
          DataValue := TETblExpression(FieldValues[i]).GetDataValue;
          // check for blob data
          if AnsiPos('$Blob$Marker$',AnsiString(DataValue.pData)) > 0 then
           begin
            BlobParamName := AnsiString(DataValue.pData);
            Delete(BlobParamName,1,13);
            FinalizeDataValue(DataValue);
            DataValue.DataType := ftBlob;
            Param := (query as TEasyQuery).ParamByName(BlobParamName);
            DataValue.DataSize := Param.GetDataSize;
            DataValue.IsNull := DataValue.DataSize = 0;
            if not DataValue.IsNull then
             begin
              DataValue.pData := AllocMem(DataValue.DataSize);
              Param.GetData(DataValue.pData);
              DataValue.IsDataLinked := true;
             end;
           end;

          // Get Field No
          FieldNo := TEasyDataset(ds).DMHandle.InternalGetFieldNo(FieldNames[i]);
          // Cast Type of Data to Field DataType
          if DataValue.DataType <> ftBlob then
           Cast(DataValue, TEasyDataset(ds).DMHandle.InternalGetFieldType(FieldNo));
          if DataValue.DataType = ftAutoInc then
            if TEasyDataset(ds).GetTablePositionByID(
                  GetDataValueAsInteger(DataValue), true, true) <> -1 then
             begin
              ds.Cancel;
              RowsAffected := -1;
              raise ETblException.Create(02157, [GetDataValueAsInteger(DataValue)],nil);
             end;
          // Set Data to Field
          TEasyDataset(ds).SetFieldValue(DataValue, FieldNo);
         end;
        oldRecCount := ds.RecordCount;
        ds.post;

        Inc(RowsAffected);
        if (oldRecCount = ds.RecordCount) then
          ds.Next;
      end;
  finally
   TEasyDataset(ds).DBSession.UnlockSession;
   TEasyQuery(query).RowsAffected := RowsAffected;
  end;
end;

procedure TEasySQLUpdate.Parse;
var
  oldPos, newPos, i,j: Integer;
  Expr: TETblExpression;
begin
  if not FLex.GetCurrentToken(Token) then
    raise ETblException.Create(02082);

  if (not GetNextToken) or
     (not (Token.TokenType in [tktReservedWord,tktString,tktQuotedString,
                               tktBracketedString])) then
    raise ETblException.Create(02083,
             [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  // MEMORY
  if IsReservedWord(Token, rwMEMORY) then
   begin
    IntoMemory := true;
    GetNextToken([tktReservedWord,tktString,tktQuotedString,
                  tktBracketedString],02151);
   end;
  // table_name
  TableName := Token.Text;

  // get next token
  GetNextToken;

  // PASSWORD ?
  if IsReservedWord(Token, rwPASSWORD) then
    begin
      GetNextToken([tktQuotedString],02084);
      Password := Token.Text;
      GetNextToken;
    end;

  // SET
  if not IsReservedWord(Token, rwSET) then
    raise ETblException.Create(02085,
             [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  GetNextToken;

  // field_name = value, ...
  repeat
    // Field_name
    FieldNames.Add(Token.Text);
    GetNextToken;
    if Token.Text <> '=' then
      raise ETblException.Create(02086,
               [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    GetNextToken;

    Expr := TETblExpression.Create(FLex);
    expr.ParseValueExpr;
    // Field_value
    //FieldValues.Add(Token.Text);
    FieldValues.Add(Expr);
    //;

    if not GetCurrentToken then
      // end of command
      break
    else
      begin
        // ',' or 'WHERE'
        if Token.ReservedWord = rwWHERE then break;
        if Token.TokenType <> tktComma then
            raise ETblException.Create(02088,
                     [',', Token.Text, Token.LineNum, Token.ColumnNum], nil);
        // get next field_name
        GetNextToken(02087);
      end;
  until false;

 // sql: select f1, f2 from table_name where .......
 //      update table_name set a=b, c=d where .......
  with  FLex.Commands[FLex.CurrentCommandNo] do
    begin
      oldPos := CurrentTokenNo;
      //newPos := oldPos - FieldNames.Count*2;
      //newPos := 3 + FieldNames.Count;
      newPos := 2 + FieldNames.Count*2;
      if IntoMemory then Inc(newPos);
      //  Shift Tokens (where clause) ?
      if IsReservedWord(Token, rwWHERE) then
        for i:=oldPos to length(Tokens)-1 do
          Tokens[newPos+i-oldPos] := Tokens[i];
      SetLength(Tokens, length(Tokens)-(oldPos-newPos));
      NumTokens := length(Tokens);
      CurrentTokenNo:=0;

      Tokens[0].TokenType := tktReservedWord;
      Tokens[0].ReservedWord := rwSELECT;
      Tokens[0].Text := 'select';
      j:=1;
      for i:=0 to FieldNames.Count-1 do
        begin
          // add ','
          if j<>1 then
            begin
              Tokens[j].TokenType := tktComma;
              Tokens[j].ReservedWord := rwNone;
              Tokens[j].Text:=',';
              inc(j);
            end;
          // add field_name
          Tokens[j].TokenType := tktString;
          Tokens[j].ReservedWord := rwNone;
          Tokens[j].Text:=FieldNames[i];
          inc(j);
        end;
      Tokens[j].TokenType := tktReservedWord;
      Tokens[j].ReservedWord := rwFROM;
      Tokens[j].Text:='from';
      inc(j);
      if IntoMemory then
       begin
        Tokens[j].TokenType := tktReservedWord;
        Tokens[j].ReservedWord := rwMEMORY;
        Tokens[j].Text:='memory';
        inc(j);
       end;
      Tokens[j].TokenType := tktString;
      Tokens[j].ReservedWord := rwNone;
      Tokens[j].Text:=TableName;
      InternalSelecter := TEasySQLSelect.Create(FLex);
    end;
end;

procedure TEasySQLUpdate.SetFieldValue(field: TField; value: AnsiString);
var ds: Char;
begin
  case field.DataType of
    ftAutoInc:  // AUTOINC
                  TEasyTable(field.DataSet).SetAutoIncValue(StrToInt(value));
    ftFloat,
    ftBCD,
    ftCurrency: // FLOAT
                begin
{$IFDEF D17H}
                  ds := FormatSettings.DecimalSeparator;
                  FormatSettings.DecimalSeparator := '.';
                  try
                    field.AsFloat := StrToFloat(value);
                  finally
                    FormatSettings.DecimalSeparator := ds;
                  end;
{$ELSE}
                  ds := DecimalSeparator;
                  DecimalSeparator := '.';
                  try
                    field.AsFloat := StrToFloat(value);
                  finally
                    DecimalSeparator := ds;
                  end;
{$ENDIF}
                end;
    {ftDate,
    ftTime,
    ftDateTime:;}
    else field.AsString := value;
  end
end;

end.
