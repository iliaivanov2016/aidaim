
{$I ETblVer.inc}

unit ETblExpr;

interface

uses SysUtils, Classes, db,
     ETblCommon, ETblLexer, ETblConst, ETblExcept, ETblRelationalAlgebra,
     ETblStrFunc, ETblDateFormat;

type

 // expression node kind
 TETblExprNodeKind = (enkField, enkConst, enkOperator, enkSet, enkNull);
 TSign = (sgnUndefined, sgnPlus, sgnMinus);

 // expression node
  TETblExprNode = class
  public
    Children: TList;                  // Children nodes
    Operator: TETblDataOperator;      // '<',  '>', AND, NOT, ...
    Data: TETblDataValue;             // data value
    TestIndentString: AnsiChar;

    // creates
    constructor Create; overload;
    constructor Create(Op: TETblDataOperator); overload;
    constructor Create(Op: TETblDataOperator;
                       Node: TETblExprNode); overload;
    constructor Create(Op: TETblDataOperator;
                       Node1, Node2: TETblExprNode); overload;
    constructor Create(Op: TETblDataOperator;
                       Node1, Node2, Node3: TETblExprNode); overload;
    // destroys
    destructor Destroy; override;

    // can be used by the AO?
    function CanBeAssigned(AO: TEasyAO): Boolean; virtual;

    // makes filter AnsiString for specified AO
    function GetFilter(AO: TEasyAO): AnsiString; virtual;

    // is node a join condition?
    function IsJoinCondition(AO1, AO2: TEasyAO): Boolean; virtual;

    // replace pseudonyms to original names (f1 -> table1.field1)
    procedure ReplacePseudonyms(SelectList: array of TETblSelectListItem); virtual;

    // assigning AO
    procedure AssignAO(AO: TEasyAO); virtual;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue;  virtual; abstract;
    // Init for group function
    procedure Init; virtual;
    // Accumulate for group functions
    procedure Accumulate; virtual;
    // return Data Size
    function GetDataSize: Integer;  virtual;
    // return Type of Data
    function GetDataType: TFieldType; virtual;
    // is expression contains aggregated function
    function isAggregated: boolean; virtual;
    // is expression a Constant
    function isConstant: boolean; virtual;
    // return Nodes Hierarchy as AnsiString
    function TestTree(Indent: Integer): AnsiString;  virtual;
  end;


 // virtual parser
 TEasyParser = class
 protected
   FLex: TEasyLexer;            // lexer with expression to parse
   Token:           TToken;     // current token
 public
   // gets current token
   function GetCurrentToken: Boolean;
   // gets next token
   function GetNextToken: Boolean; overload;
   // gets next token
   function GetNextToken(NativeErrorCode: integer): Boolean; overload;
   // gets token and lokks at next token with check for token type restrictions
   function GetNextToken(PermittedTypes: TTokenTypes;
                          NativeErrorCode: integer=-1;
                          RaiseExceptions: Boolean = True): Boolean; overload;
   // gets next token specified type with check and check token absent
   function GetNextSpecifiedToken(PermittedTypes: TTokenTypes;
                          NativeErrorCode: integer = -1;
                          RaiseExceptions: Boolean = True): Boolean;
   // parses query
   procedure Parse; virtual; abstract;
  end;


  // expression node CONST
  TETblExprNodeConst = class (TETblExprNode)
  public
    // creates
    constructor Create(Value: TETblDataValue); overload;

    // can be used by the AO?
    function CanBeAssigned(AO: TEasyAO): Boolean; override;
      // makes filter AnsiString for specified AO
    function GetFilter(AO: TEasyAO): AnsiString;  override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue;  override;
    // return Type of Data
    function GetDataType: TFieldType; override;
    // return Data Size
    function GetDataSize: Integer; override;
    // return Nodes Hierarchy as AnsiString
    function TestTree(Indent: Integer): AnsiString; override;
  end;


  // expression node FIELD
  TETblExprNodeField = class (TETblExprNode)
  protected
    FAO: TEasyAO;                // AO
    FieldNumber: Integer;
    FieldName: AnsiString;           // field name - Field1
    TableName: AnsiString;           // table name - Table1 (Table1.Field1)
  public
    constructor Create(FieldName1, TableName1: AnsiString); overload;

    // can be used by the AO?
    function CanBeAssigned(AO: TEasyAO): Boolean; override;
    // makes filter AnsiString for specified AO
    function GetFilter(AO: TEasyAO): AnsiString; override;
    // fills Field Item
    procedure FillItem(var Item: TETblSelectListItem);
    // replace pseudonyms to original names (f1 -> table1.field1)
    procedure ReplacePseudonyms(SelectList: array of TETblSelectListItem); override;
    // is expression a Constant
    function isConstant: boolean; override;
    // return Nodes Hierarchy as AnsiString
    function TestTree(Indent: Integer): AnsiString; override;
    // assigning AO
    procedure AssignAO(AO: TEasyAO); override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue;  override;
    // return Type of Data
    function GetDataType: TFieldType; override;
    // return Data Size
    function GetDataSize: Integer;  override;
  end;

  // expression node SubQuery
  TETblExprNodeSubQuery = class (TETblExprNode)
  private
    FSQLText:     AnsiString;   // text of sub query
    FQuery:       TDataset; // query
    FNot:         Boolean;  // NOT option for IN or EXISTS
    FSourceNode:  TEtblExprNode; // source node for IN
  public
    constructor Create(QueryText:         AnsiString;
                       bNot:              Boolean = False;
                       SourceNode:        TETblExprNode = nil
                       ); overload;
    // destroy
    destructor Destroy; override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
  end;

  // expression node SubQueryIN
  TETblExprNodeSubQueryIN = class (TETblExprNodeSubQuery)
  public
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
  end;

  // expression node SubQueryExists
  TETblExprNodeSubQueryExists = class (TETblExprNodeSubQuery)
  public
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
  end;

  // expression node Arithmetic ( + - * / )
  TETblExprNodeArithmetic = class (TETblExprNode)
  protected
    // SUB operation
    procedure SubData(DataSet: TDataSet = nil);
    // ADD operation
    procedure AddData(DataSet: TDataSet = nil);
    // MUL operation
    procedure MulData(DataSet: TDataSet = nil);
    // DIV operation
    procedure DivData(DataSet: TDataSet = nil);
    // ABS operation
    procedure AbsData(DataSet: TDataSet = nil);
    // CEILING operation
    procedure CeilingData(DataSet: TDataSet = nil);
    // FLOOR operation
    procedure FloorData(DataSet: TDataSet = nil);
    // MOD operation
    procedure ModData(DataSet: TDataSet = nil);
    // POWER operation
    procedure PowerData(DataSet: TDataSet = nil);
    // RAND operation
    procedure RandomData(DataSet: TDataSet = nil);
    // ROUND operation
    procedure RoundData(DataSet: TDataSet = nil);
    // SIGN operation
    procedure SignData(DataSet: TDataSet = nil);
    // TRUNCATE operation
    procedure TruncateData(DataSet: TDataSet = nil);

    // AND operation
    procedure AndData(DataSet: TDataSet = nil);
    // OR operation
    procedure OrData(DataSet: TDataSet = nil);
    // NOT operation
    procedure NotData(DataSet: TDataSet = nil);
    // SHL operation
    procedure ShlData(DataSet: TDataSet = nil);
    // SHR operation
    procedure ShrData(DataSet: TDataSet = nil);
    // XOR operation
    procedure XorData(DataSet: TDataSet = nil);
    // HEX operation
    procedure HexData(DataSet: TDataSet = nil);
  public
    // makes filter AnsiString for specified AO
    function GetFilter(AO: TEasyAO): AnsiString; override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue;  override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Type of Data
    function GetDataType: TFieldType; override;
    // return Nodes Hierarchy as AnsiString
    function TestTree(Indent: Integer): AnsiString; override;
  end;

  // expression node Comparison ( =, <>, >, <, >=, <= )
  TETblExprNodeComparison = class (TETblExprNode)
    // is node a join condition?
    function IsJoinCondition(AO1, AO2: TEasyAO): Boolean; override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
  end;

  // expression node Boolean ( NOT, AND, OR, IN, BETWEEN, LIKE,
  //                           NOT LIKE, IS NULL, IS NOT NULL )
  TETblExprNodeBoolean = class (TETblExprNode)
  private
    // process a Like b
    procedure Like(DataSet: TDataSet = nil);
    // process IN (...)
    procedure bIn(DataSet: TDataSet = nil);
    // process A BETWEEN B AND C
    procedure Between(DataSet: TDataSet = nil);
  public
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
    // return Type of Data
    function GetDataType: TFieldType; override;
  end;

  // expression node IsNull function
  TETblExprNodeIsNullFunction = class (TETblExprNode)
  private
   FType1: TFieldType;
   FType2: TFieldType;
  public
    constructor Create(Op: TETblDataOperator;
                       Node1, Node2: TETblExprNode); overload;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Type of Data
    function GetDataType: TFieldType; override;
  end;

  // expression node CAST
  TETblExprNodeCast = class (TETblExprNode)
  private
    CastType: TFieldType;  // Type for convertation
  public
    // creates
    constructor Create(Node: TETblExprNode; CastType: TFieldType); overload;
    // return Type of Data
    function GetDataType: TFieldType; override;
    // return Data Size
    //function GetDataSize: Integer;  override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
  end;

  TETblExprNodeSystem = class (TETblExprNode)
  private
    FAO: TEasyAO;
    TableName: AnsiString;
    Password: AnsiString;
    InMemory: boolean;
    procedure LastAutoInc(DataSet: TDataSet = nil);
  public
    // creates
    constructor Create(TableName: AnsiString; Password: AnsiString; InMemory: boolean); overload;
    // return Type of Data
    function GetDataType: TFieldType; override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
    // assigning AO
    procedure AssignAO(AO: TEasyAO); override;
  end;

  // expression node GroupFunction
  TETblExprNodeAggregated = class (TETblExprNode)
  private
    count:        integer;
    distinct:     Boolean;
    AvgSum:       TETblDataValue;
    FTempTable:   TDataset;
  public
    // creates
    constructor Create(Op: TETblDataOperator); overload;
    constructor Create(Op: TETblDataOperator;
                       distinct: boolean;
                       Node: TETblExprNode); overload;
    // destroys
    destructor Destroy; override;
    // get data value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
    // return Type of Data
    function GetDataType: TFieldType; override;
    // Init for aggregated functions
    procedure Init; override;
    // Accumulate for group functions
    procedure Accumulate; override;
    // is expression contains aggregated function
    function isAggregated: boolean; override;
    // return Nodes Hierarchy as AnsiString
    function TestTree(Indent: Integer): AnsiString; override;
  end;

  // expression node StringFunction
  TETblExprNodeStringFunction = class (TETblExprNode)
  protected
    procedure Concat(DataSet: TDataSet = nil);
    procedure Upper(DataSet: TDataSet = nil);
    procedure Lower(DataSet: TDataSet = nil);
    procedure Trim(DataSet: TDataSet = nil);
    procedure LTrim(DataSet: TDataSet = nil);
    procedure RTrim(DataSet: TDataSet = nil);
    procedure Length(DataSet: TDataSet = nil);
    procedure Pos(DataSet: TDataSet = nil);
    procedure Substring(DataSet: TDataSet = nil);
  public
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Data Type
    function GetDataType: TFieldType; override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
    // return Nodes Hierarchy as AnsiString
    function TestTree(Indent: Integer): AnsiString; override;
  end;

  // expression node DateFunction
  TETblExprNodeDateFunction = class (TETblExprNode)
  private
    DateFormater: TDateFormater;
    // ToDate
    procedure ToDate(DataSet: TDataSet = nil);
    // ToString
    procedure ToString(DataSet: TDataSet = nil);
    // extract part from date or time value
    procedure Extract(DataSet: TDataSet = nil);
  public
    // Constructor
    constructor Create(Op: TETblDataOperator;
                       Node: TETblExprNode;
                       FormatStr: AnsiString); overload;
    // destroys
    destructor Destroy; override;
    // return Data Type
    function GetDataType: TFieldType; override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Data Value
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue; override;
  end;

  // expression
  TETblExpression = class (TEasyParser)
  private
    FRootNode:        TETblExprNode;     // expression nodes tree

    // saves internal state (to restore in case of not successful forward parsing)
    procedure SaveState(var SavedTokenNo: integer);// var SavedRootNode: TETblExprNode);
    // restores internal state (in case of not successful forward parsing)
    procedure RestoreState(SavedTokenNo: integer);// SavedRootNode: TETblExprNode);

    // parses <,>,=,<>,>=,<=
    function ParseCompOp: TETblDataOperator;
    // parses <row value constructor element>
    function ParseRowValueConstructorElement: TETblExprNode;
    // parses <row value constructor element> | <row subquery>
    function ParseRowValueConstructor: TETblExprNode;
    // parses <row value constructor> <comp op> <row value constructor>
    function ParseComparisonPredicate: TETblExprNode;
    // parses <match value> [ NOT ] LIKE <pattern> [ ESCAPE <escape character> ]
    function ParseLikePredicate: TETblExprNode;
    // parses <row value constructor> IS [ NOT ] NULL
    function ParseNullPredicate: TETblExprNode;
    // parses <between predicate>
    function ParseBetweenPredicate: TETblExprNode;
    // parses <in predicate>
    function ParseInPredicate: TETblExprNode;
    // parses <Exists predicate>
    function ParseExistsPredicate: TETblExprNode;
    // parses <true/false>
    function ParseTrueFalseConst: TETblExprNode;
    // parses <NULL> const
    function ParseNullConst: TETblExprNode;
    // parses <comparison predicate> | <between predicate> | <in predicate>  |
    // <like predicate>  | <null predicate> | <quantified comparison predicate> |
    // <exists predicate> | <unique predicate> | <match predicate> | <overlaps predicate>
    function ParsePredicate: TETblExprNode;
    // parses <predicate>  | <left paren> <search condition> <right paren>
    function ParseBooleanPrimary: TETblExprNode;
    // parses <boolean primary> [ IS [ NOT ] <truth value> ]
    function ParseBooleanTest: TETblExprNode;
    // parses [ NOT ] <boolean test>
    function ParseBooleanFactor: TETblExprNode;
    // parses <boolean factor> | <boolean term> AND <boolean factor>
    function ParseBooleanTerm: TETblExprNode;
    // parses <boolean term> | <search condition> OR <boolean term>
    function ParseSearchCondition: TETblExprNode;

    // parses <value expression>
    function ParseValueExpression: TETblExprNode;
    // parses <numeric value expression>
    function ParseNumericValueExpression: TETblExprNode;
    // parses <term>
    function ParseTerm: TETblExprNode;
    // parses <factor>
    function ParseFactor: TETblExprNode;
    // parses <sign> ('+' or '-')
    function ParseSign: TSign;
    // parses <numeric primary>
    function ParseNumericPrimary: TETblExprNode;
    // parses <value expression primary>
    function ParseValueExpressionPrimary: TETblExprNode;
    // parses <unsigned value specification>
    function ParseUnsignedValueSpecification: TETblExprNode;
    // parses <unsigned literal>
    function ParseUnsignedLiteral: TETblExprNode;
    // parses <unsigned numeric literal>
    function ParseUnsignedNumericLiteral: TETblExprNode;
    // parses <column reference>
    function ParseColumnReference: TETblExprNode;
    // parses <SUB QUERY>
    function ParseSubQuery(bExists:       Boolean = False;
                           bIn:           Boolean = False;
                           bNot:          Boolean = False;
                           SourceNode:    TETblExprNode = nil
                           ): TETblExprNode;
    // parses <set function specification>
    function ParseSetFunctionSpecification: TETblExprNode;
    // parses <general set function>
    function ParseGeneralSetFunction: TETblExprNode;
    // parses <cast specification>
    function ParseCastSpecification: TETblExprNode;
    // parses <cast operand>
    function ParseCastOperand: TETblExprNode;

    // parses <numeric value function>
    function ParseNumericValueFunction: TETblExprNode;
    // parses <position expression>
    function ParsePositionExpression: TETblExprNode;
    // parses <length expression>
    function ParseLengthExpression: TETblExprNode;
    // parses <LastAutoInc expression>
    function ParseLastAutoIncExpression: TETblExprNode;
    // parses <IsNull expression>
    function ParseIsNullExpression: TETblExprNode;

    // parses <string value expression>
    function ParseStringValueExpression: TETblExprNode;
    // parses <character value expression>
    function ParseCharacterValueExpression: TETblExprNode;
    // parses <concatenation>
    function ParseConcatination: TETblExprNode;
    // parses <character factor>
    function ParseCharacterFactor: TETblExprNode;
    // parses <character primary>
    function ParseCharacterPrimary: TETblExprNode;
    // parses <general literal>
    function ParseGeneralLiteral: TETblExprNode;
    // parses <character string literal>
    function ParseCharacterStringLiteral: TETblExprNode;
    // parses <string value function>
    function ParseStringValueFunction: TETblExprNode;
    // parses <character value function>
    function ParseCharacterValueFunction: TETblExprNode;

    // parse <datetime value expression>
    function ParseDatetimeValueExpression: TETblExprNode;
    // parse <datetime sysdate function>
    function ParseSysdateFunction: TETblExprNode;
    // parse <datetime CURRENT_TIME function>
    function ParseCurrentTimeFunction: TETblExprNode;
    // parse <datetime CURRENT_DATE function>
    function ParseCurrentDateFunction: TETblExprNode;
    // parse <datetime TODATE function>
    function ParseToDateFunction: TETblExprNode;
    // parse <datetime extract functions>
    function ParseDateTimeExtractFunction: TETblExprNode;
    // parse <Math function>
    function ParseMathFunction: TETblExprNode;


  public
    // creates
    constructor Create(Lexer: TEasyLexer); overload;
    // creates
    constructor Create(RootNode: TETblExprNode); overload;
    // destroys
    destructor Destroy; override;
    // parses expression and builds a tree
    procedure ParseSearchExpression;

    procedure ParseValueExpr;

    procedure Parse; override;
    // makes filter string from related parts and sets it to AO
    procedure ApplyFilterParts(AO: TEasyAO);
    // makes join field lists
    function ExtractJoinConditions(AO1, AO2: TEasyAO;
                                  FieldList1, FieldList2: TETblFields): integer;
    // makes filter AnsiString for specified AO
    function GetFilter(AO: TEasyAO): AnsiString;
    // replace pseudonyms to original names (f1 -> table1.field1)
    procedure ReplacePseudonyms(SelectList: array of TETblSelectListItem);
    // is expression contains no nodes
    function IsEmpty: Boolean;

    // process assign AO
    procedure AssignAO(AO: TEasyAO);
    // Return DataValue
    function GetDataValue(DataSet: TDataSet = nil): TETblDataValue;
    // return Type of Data
    function GetDataType(AO: TEasyAO): TFieldType;
    // return Size of Data (for strings and arrays)
    function GetDataSize(AO: TEasyAO): Integer;
    // Init for aggregate functions
    procedure Init;
    // Accumulate for aggregate functions
    procedure Accumulate;
    // return Nodes Hierarchy as AnsiString
    function TestTree: AnsiString;
    // is expression contains aggregated function
    function IsAggregated: boolean;
    // is expression a Constant
    function isConstant: boolean; virtual;
    // is expression a Field (for join)
    function IsField: boolean;
    // Field Name, Table Name
    procedure GetFieldInfo(var TableName: AnsiString; var FieldName: AnsiString);

  end;

implementation

uses ETblEngine, EasyTable, Math;

////////////////////////////////////////////////////////////////////////////////
//
// TETblExprNode
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Destroys
//------------------------------------------------------------------------------
destructor TETblExprNode.Destroy;
var i: Integer;
begin
   for i:=0 to Children.Count-1 do
     TETblExprNode(Children[i]).Free;
  Children.Free;
  FinalizeDataValue(Data);
end;// Destroy



//------------------------------------------------------------------------------
// is node a join condition?
//------------------------------------------------------------------------------
function TETblExprNode.IsJoinCondition(AO1, AO2: TEasyAO): Boolean;
begin
  Result := False;
end;// IsJoinConditions


//------------------------------------------------------------------------------
// replace pseudonyms to original names (f1 -> table1.field1)
//------------------------------------------------------------------------------
procedure TETblExprNode.ReplacePseudonyms(SelectList: array of TETblSelectListItem);
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
    TETblExprNode(Children[i]).ReplacePseudonyms(SelectList);
end;// ReplacePseudonyms


////////////////////////////////////////////////////////////////////////////////
//
// TEasyParser
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// gets current token
//------------------------------------------------------------------------------
function TEasyParser.GetCurrentToken: Boolean;
begin
 Result := FLex.GetCurrentToken(Token);
end;// GetCurrentToken


//------------------------------------------------------------------------------
// gets next token
//------------------------------------------------------------------------------
function TEasyParser.GetNextToken: Boolean;
begin
 Result := FLex.GetNextToken(Token);
end;// GetNextToken


//------------------------------------------------------------------------------
// gets next token
//------------------------------------------------------------------------------
function TEasyParser.GetNextToken(NativeErrorCode: integer): Boolean;
begin
  Result := GetNextToken;
  if (not result) then
    raise ETblException.Create(NativeErrorCode,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;// GetNextToken


//------------------------------------------------------------------------------
// gets token and looks at next token with check for token type restrictions
//------------------------------------------------------------------------------
function TEasyParser.GetNextToken(PermittedTypes: TTokenTypes;
                                      NativeErrorCode: integer = -1;
                                      RaiseExceptions: Boolean = True): Boolean;
begin
  // get next token
  Result := FLex.GetNextToken(Token);
  if (not Result) then
   if (RaiseExceptions) then
      raise ETblException.Create(01008,
                  [Token.LineNum], nil);
  // check token type
  if (Result) then
   if ((PermittedTypes <> []) and (NativeErrorCode <> -1)) then
    if not (Token.TokenType in PermittedTypes) then
      if (RaiseExceptions) then
         raise ETblException.Create(NativeErrorCode,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil)
      else
         Result := False;
end;// GetNextToken

//------------------------------------------------------------------------------
// gets next token specified type with check and check token absent
//------------------------------------------------------------------------------
function TEasyParser.GetNextSpecifiedToken(PermittedTypes: TTokenTypes;
                                      NativeErrorCode: integer = -1;
                                      RaiseExceptions: Boolean = True): Boolean;
begin
  // get next token
  Result := FLex.GetNextToken(Token);
  if (not Result) then
   if (RaiseExceptions) then
      raise ETblException.Create(01008,
                  [Token.LineNum], nil);
  // check token type
  if (Result) then
   if ((PermittedTypes <> []) and (NativeErrorCode <> -1)) then
    if not (Token.TokenType in PermittedTypes) then
      if (RaiseExceptions) then
         raise ETblException.Create(NativeErrorCode,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil)
      else
         Result := False;
end;// GetNextSpecifiedToken


////////////////////////////////////////////////////////////////////////////////
//
// TETblExpression
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Creates
//------------------------------------------------------------------------------
constructor TETblExpression.Create(Lexer: TEasyLexer);
begin
  FLex := Lexer;
  FRootNode := nil;
end;// Create


constructor TETblExpression.Create(RootNode: TETblExprNode);
begin
  FLex := nil;
  FRootNode := RootNode;
end; // Create


//------------------------------------------------------------------------------
// Destroys
//------------------------------------------------------------------------------
destructor TETblExpression.Destroy;
begin
  // free nodes tree
  if (FRootNode <> nil) then FRootNode.Free;
  inherited;
end;// Destroy


//------------------------------------------------------------------------------
// saves internal state (to restore in case of not successful forward parsing)
//------------------------------------------------------------------------------
procedure TETblExpression.SaveState(var SavedTokenNo: integer);
//  var SavedRootNode: TETblExprNode);
begin
 // save token No
 SavedTokenNo := FLex.GetCurrentTokenNo;
 // save root node
 //SavedRootNode := FRootNode;
end;// SaveState


//------------------------------------------------------------------------------
// restores internal state (in case of not successful forward parsing)
//------------------------------------------------------------------------------
procedure TETblExpression.RestoreState(SavedTokenNo: integer);
//  SavedRootNode: TETblExprNode);
begin
 // restore token No
 FLex.SetCurrentTokenNo(SavedTokenNo, Token);
 // restore root node
 //FRootNode.DeleteTo(SavedRootNode);
 //FRootNode := SavedRootNode;
end;// RestoreState


//------------------------------------------------------------------------------
// parses <,>,=,<>,>=,<=
//------------------------------------------------------------------------------
function TETblExpression.ParseCompOp: TETblDataOperator;
begin
  if (Token.Text = '<') then
   Result := doLT
  else
  if (Token.Text = '>') then
   Result := doGT
  else
  if ((Token.Text = '=') or (Token.Text = '==')) then
   Result := doEQ
  else
  if ((Token.Text = '<>') or (Token.Text = '!=')) then
   Result := doNE
  else
  if (Token.Text = '<=') then
   Result := doLE
  else
  if (Token.Text = '>=') then
   Result := doGE
  else
   Result := doUNDEFINED;

  if (Result <> doUNDEFINED) then
   GetNextToken;
end;// ParseCompOp


//------------------------------------------------------------------------------
// parses <row value constructor element>
//------------------------------------------------------------------------------
function TETblExpression.ParseRowValueConstructorElement: TETblExprNode;
begin
 if IsReservedWord(Token, rwNULL) then
  begin
   Result := TETblExprNodeConst.Create;
  end
 else
  Result := ParseValueExpression;
end;// ParseRowValueConstructorElement


//------------------------------------------------------------------------------
// parses <row value constructor element> | <row subquery>
//------------------------------------------------------------------------------
function TETblExpression.ParseRowValueConstructor: TETblExprNode;
begin
 Result := ParseRowValueConstructorElement;
end;// ParseRowValueConstructor


//------------------------------------------------------------------------------
// parses <row value constructor> <comp op> <row value constructor>
//------------------------------------------------------------------------------
function TETblExpression.ParseComparisonPredicate: TETblExprNode;
var
  LeftNode, RightNode: TETblExprNode;
  CompOp: TETblDataOperator;
begin
 // parse <row value constructor>
 LeftNode := ParseRowValueConstructor;
 if (LeftNode <> nil) then
  begin
   // <,>,=,<>,>=,<=
   CompOp := ParseCompOp;
   // parse 2nd <row value constructor>
   if (CompOp <> doUndefined) then
    begin
     RightNode := ParseRowValueConstructor;
     if (RightNode <> nil) then
      // create <CompOp> node
      LeftNode := TETblExprNodeComparison.Create(CompOp, LeftNode, RightNode)
     else
      begin
       LeftNode.Free;
       LeftNode := nil;
      end;
    end
   else
    begin
     LeftNode.Free;
     LeftNode := nil;
    end;
  end;
 Result := LeftNode;
end;// ParseComparisonPredicate


//------------------------------------------------------------------------------
// parses <match value> [ NOT ] LIKE <pattern> [ ESCAPE <escape character> ]
//------------------------------------------------------------------------------
function TETblExpression.ParseLikePredicate: TETblExprNode;
var
  Node, LeftNode, RightNode: TETblExprNode;
  bNot: Boolean;
begin
 // parse <character value expression>
 LeftNode := ParseRowValueConstructor;
 if (LeftNode <> nil) then
  begin
   // [NOT]
   if (IsReservedWord(Token, rwNOT)) then
     begin
      bNot := True;
      GetNextToken;
     end
   else
     bNot := False;
   // LIKE
   if (IsReservedWord(Token, rwLIKE)) then
    begin
     // get <pattern>
     GetNextToken;
     RightNode := ParseRowValueConstructor;
     if (not bNot) then
       Node := TETblExprNodeBoolean.Create(doLIKE)
     else
       Node := TETblExprNodeBoolean.Create(doNOTLIKE);
     Node.Children.Add(LeftNode);
     Node.Children.Add(RightNode);
     LeftNode := Node;
    end
   else
    begin
      LeftNode.Free;
      LeftNode := nil;
    end;
  end;
 Result := LeftNode;
end;// ParseLikePredicate


//------------------------------------------------------------------------------
// parses <row value constructor> IS [ NOT ] NULL
//------------------------------------------------------------------------------
function TETblExpression.ParseNullPredicate: TETblExprNode;
var
  LeftNode: TETblExprNode;
  bNot: Boolean;
  bOK: Boolean;
begin
 // parse <row value constructor>
 LeftNode := ParseRowValueConstructor;
 bOK := False;
 if (LeftNode <> nil) then
  begin
   // IS?
   if (IsReservedWord(Token, rwIS)) then
    begin
     // get next token
     GetNextToken;
     // [NOT]
     if (IsReservedWord(Token, rwNOT)) then
      begin
       bNot := True;
       GetNextToken;
      end
     else
      bNot := False;
     // NULL
     if (IsReservedWord(Token, rwNULL)) then
      begin
       // skip token NULL
       GetNextToken;
       if (not bNot) then
        LeftNode := TETblExprNodeBoolean.Create(doISNULL, LeftNode)
       else
        LeftNode := TETblExprNodeBoolean.Create(doISNOTNULL, LeftNode);
       bOk := True;
      end;
    end
  end;
 if (not bOK) then
    begin
      if (LeftNode <> nil) then
       LeftNode.Free;
      LeftNode := nil;
    end;
 Result := LeftNode;
end;// ParseNullPredicate


//------------------------------------------------------------------------------
// parses <comparison predicate> | <between predicate> | <in predicate>  |
// <like predicate>  | <null predicate> | <quantified comparison predicate> |
// <exists predicate> | <unique predicate> | <match predicate> | <overlaps predicate>
//------------------------------------------------------------------------------
function TETblExpression.ParsePredicate: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
  //SavedRootNode: TETblExprNode; // saved/restored information
begin
 // save current state
 SaveState(SavedTokenNo);
 Result := ParseTrueFalseConst;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    // try to parse next tokens as a comparison predicate
    Result := ParseComparisonPredicate;
  end;
 // if failed comparison - try like
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    // try to parse next tokens as a like predicate
    Result := ParseLikePredicate;
  end;
 // if failed like - try null
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    // try to parse next tokens as a null predicate
    Result := ParseNullPredicate;
  end;
 // if failed null - try between
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    // try to parse next tokens as a between predicate
    Result := ParseBetweenPredicate;
  end;
 // if failed between - try in
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    // try to parse next tokens as a IN predicate
    Result := ParseInPredicate;
  end;
 // if failed in - try Exists
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    // try to parse next tokens as a IN predicate
    Result := ParseExistsPredicate;
  end;
end;// ParsePredicate


//------------------------------------------------------------------------------
// parses <predicate>  | <left paren> <search condition> <right paren>
//------------------------------------------------------------------------------
function TETblExpression.ParseBooleanPrimary: TETblExprNode;
begin
 // '(' ?
 if (Token.TokenType = tktLeftParenthesis) then
  begin
   // skip '('
   GetNextToken;
   // parse <search condition>
   Result := ParseSearchCondition;
   // skip ')'
   GetNextToken;
  end
 else
  Result := ParsePredicate;
end;// ParseBooleanPrimary


//------------------------------------------------------------------------------
// parses <boolean primary> [ IS [ NOT ] <truth value> ]
//------------------------------------------------------------------------------
function TETblExpression.ParseBooleanTest: TETblExprNode;
var
  bNot: Boolean;
  bIsNull: Boolean;
  bIsNotNull: Boolean;
  LeftNode: TETblExprNode;
begin
  if (IsReservedWord(Token,rwISNULL)) then
   begin
    Result := ParseIsNullExpression;
    Exit;
   end;
  // parse <boolean primary>
  LeftNode := ParseBooleanPrimary;
  if (LeftNode = nil) then
    raise ETblException.Create(01041, [Token.Text, Token.LineNum, Token.ColumnNum], nil);

  bNot := False;
  bIsNull := False;
  bIsNotNull := False;
  // [ IS [ NOT ] <truth value> ] ?
  if (IsReservedWord(Token, rwIS)) then
    begin
      // skip 'IS' token
      GetNextToken([tktReservedWord], 01042);
      if (IsReservedWord(Token, rwNOT) or (Token.Text = '!')) then
       begin
        bNot := True;
        // skip 'NOT' token
        GetNextToken([tktReservedWord], 01043);
       end;
      // TRUE | FALSE | UNKNOWN ?
      if (IsReservedWord(Token, rwTRUE)) then
        // skip 'TRUE' token
        GetNextToken
      else
      if (IsReservedWord(Token, rwFALSE)) then
       begin
        bNot := not bNot;
        // skip 'FALSE' token
        GetNextToken
       end
      else
      if (IsReservedWord(Token, rwUNKNOWN)) then
       begin
        if (bNot) then
          bIsNotNull := True
        else
          bIsNull := True;
        bNot := False;
        // skip 'UNKNOWN' token
        GetNextToken
       end
      else
       raise ETblException.Create(01044, ['TRUE, FALSE or UNKNOWN',
                             Token.Text, Token.LineNum, Token.ColumnNum], nil);
    end;

  // create node?
  if (bNot) then
   Result := TETblExprNodeBoolean.Create(doNOT, LeftNode)
  else
  if (bIsNull) then
   Result := TETblExprNodeBoolean.Create(doISNULL, LeftNode)
  else
  if (bIsNotNull) then
   Result := TETblExprNodeBoolean.Create(doISNOTNULL, LeftNode)
  else
   Result := LeftNode;
end;// ParseBooleanTest


//------------------------------------------------------------------------------
// parses [ NOT ] <boolean test>
//------------------------------------------------------------------------------
function TETblExpression.ParseBooleanFactor: TETblExprNode;
var
  bNot: Boolean;
  LeftNode: TETblExprNode;
begin
  Result := ParseExistsPredicate;
  if (Result = nil) then
   begin
    // [NOT]?
    if (IsReservedWord(Token, rwNOT) or (Token.Text = '!')) then
      begin
        // skip 'NOT' token
        GetNextToken;
        bNot := True;
      end
    else
      bNot := False;
    // parse <boolean test>
    LeftNode := ParseBooleanTest;
    if (LeftNode = nil) then
      raise ETblException.Create(01040, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // create <NOT> node?
    if (bNot) then
     Result := TETblExprNodeComparison.Create(doNOT, LeftNode)
    else
     Result := LeftNode;
   end;
end;// ParseBooleanFactor


//------------------------------------------------------------------------------
// parses <boolean factor> | <boolean term> AND <boolean factor>
//------------------------------------------------------------------------------
function TETblExpression.ParseBooleanTerm: TETblExprNode;
var
  Node: TETblExprNode;
  AndOperatorNode: TETblExprNode;

begin
 AndOperatorNode := nil;
 // parse <boolean factor>
 Node := ParseBooleanFactor;
 if (Node <> nil) then
  begin
   // { AND <boolean term> }
   if (IsReservedWord(Token, rwAND) or (Token.Text = '&&')) then
    begin
     AndOperatorNode := TETblExprNodeBoolean.Create(doAND, Node);
     while (IsReservedWord(Token, rwAND)) do
      begin
        // skip 'AND' token
        GetNextToken;
        // parse <boolean factor>
        Node := ParseBooleanFactor;
        if (Node = nil) then
         raise ETblException.Create(01038, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
        // add into <AND> node
        AndOperatorNode.Children.Add(Node);
      end;
    end
   else
    AndOperatorNode := Node;
  end;
 Result := AndOperatorNode;
end;// ParseBooleanTerm


//------------------------------------------------------------------------------
// parses <boolean term> | <search condition> OR <boolean term>
//------------------------------------------------------------------------------
function TETblExpression.ParseSearchCondition: TETblExprNode;
var
  LeftNode, RightNode: TETblExprNode;
begin
 // <boolean term>
 LeftNode := ParseBooleanTerm;
 if (LeftNode <> nil) then
  begin
   // { OR <boolean term> }
   while (IsReservedWord(Token, rwOR)) do
    begin
      // skip 'OR' token
      GetNextToken;
      // parse <boolean term>
      RightNode := ParseBooleanTerm;
      if (RightNode = nil) then
       raise ETblException.Create(01037, [Token.Text, Token.LineNum, Token.ColumnNum], nil);
      // create <OR> node
      LeftNode := TETblExprNodeBoolean.Create(doOR, LeftNode, RightNode);
    end;
  end;
 Result := LeftNode;
end;// ParseSearchCondition


//------------------------------------------------------------------------------
// parses expression and builds a tree
//------------------------------------------------------------------------------
procedure TETblExpression.ParseSearchExpression;
var
  bOk: Boolean;
  i,j,c: integer;
  DelList: TList;
begin
 // get first token (for very beginning of the query) or current token
 bOk := FLex.GetCurrentToken(Token);

 if (not bOk) then
  raise ETblException.Create(01039, [Token.LineNum], nil);

 // parse
 FRootNode := ParseSearchCondition;

 // Up to Top And-nodes
 if TETblExprNode(FRootNode).Operator = doAND then
  begin
   DelList := TList.Create;
   try
     c := FRootNode.Children.Count - 1;
     for i:=0 to c do
      if TETblExprNode(FRootNode.Children[i]).Operator = doAND then
       begin
        for j:=0 to TETblExprNode(FRootNode.Children[i]).Children.Count-1 do
         FRootNode.Children.Add(TETblExprNode(FRootNode.Children[i]).Children[j]);
        DelList.Add(Pointer(i));
       end;
   finally
    for i:=0 to DelList.Count-1 do
     FRootNode.Children.Delete(Integer(DelList[i]));
    DelList.Free;
   end;
  end;

end;// ParseSearchExpression


//------------------------------------------------------------------------------
// makes filter string from related parts and sets it to AO
//------------------------------------------------------------------------------
procedure TETblExpression.ApplyFilterParts(AO: TEasyAO);
var
  NodesToDelete: TList;
  Node: TETblExprNode;
  bRecurse: Boolean;
  i: Integer;
  //FilterExpr: TETblExpression;
  FilterRootNode: TETblExprNode;
begin
  FilterRootNode := nil;
  bRecurse := True;
  // don't set filter to outer join childs
  if (AO is TEasyAOJoin) then
   bRecurse := not TEasyAOJoin(AO).OuterJoin;

  // try to apply to AO children
  if (bRecurse) then
   begin
    if (AO.FLeftAO <> nil) then
     ApplyFilterParts(AO.FLeftAO);
    if (AO.FRightAO <> nil) then
     ApplyFilterParts(AO.FRightAO);
   end;

  // traverse tree by factors: (...) AND (...) AND (...)
  if (FRootNode <> nil) then
   begin
     NodesToDelete := TList.Create;
     try
      // -> (...) AND (...) AND (...) ?
      if (FRootNode is TETblExprNodeBoolean) and
         (FRootNode.Operator = doAND) then
        for i:=0 to FRootNode.Children.Count-1 do
         begin
          Node := FRootNode.Children[i];
          // (...) can be used by the AO?
          if (Node.CanBeAssigned(AO)) then
           begin
            // no FilterRootNode
            if FilterRootNode = nil then
              FilterRootNode := Node
            else
            // FilterRootNode=AND ( ex: a=b AND c=d )
            if (FilterRootNode is TETblExprNodeBoolean) and
               (FilterRootNode.Operator = doAND) then
               FilterRootNode.Children.Add(Node)
            else
              // single FilterRootNode ( ex: a=b ) - converting to AND
              FilterRootNode := TETblExprNodeBoolean.Create(doAND,
                                                FilterRootNode, Node);
            NodesToDelete.Add(Node);
           end;
          // -> AND (...)
         end
      else
        // (...)
        begin
          if (FRootNode.CanBeAssigned(AO)) then
            begin
              FilterRootNode := FRootNode;
              FRootNode := nil;
            end;
        end;
      // delete used nodes
      for i:=0 to NodesToDelete.Count-1 do
       begin
        FRootNode.Children.Delete(
          FRootNode.Children.IndexOf(NodesToDelete[i]));
       end;
      // set extracted filter
      if FilterRootNode <> nil then
       AO.SetFilter(TETblExpression.Create(FilterRootNode));

      // no children?
      if (FRootNode <> nil) then
       if (FRootNode.Children.Count = 0) then
        begin
         FRootNode.Free;
         FRootNode := nil;
        end;
//      if (FilterString <> '') then
//       AO.SetFilter(FilterString, []);
     finally
      NodesToDelete.Free;
     end;
   end;
end;// ApplyFilterParts


//------------------------------------------------------------------------------
// makes join field lists
//------------------------------------------------------------------------------
function TETblExpression.ExtractJoinConditions(AO1, AO2: TEasyAO;
                               FieldList1, FieldList2: TETblFields): integer;
var
  NodesToDelete: TList;
  Node: TETblExprNode;
  Item1,Item2: TETblSelectListItem;
  i: Integer;
begin
  Result := 0;
  if FRootNode = nil then Exit;
  // If 'AND'
  if ((FRootNode is TETblExprNodeBoolean) and
      (FRootNode.Operator = doAND)) then
   begin
     NodesToDelete := TList.Create;
     try
      for i:=0 to FRootNode.Children.Count-1 do
       begin
        Node := FRootNode.Children[i];
        // (...) can be used by the AO?
        if (Node.IsJoinCondition(AO1,AO2)) then
         begin
          // store extracted filter
          TETblExprNodeField(Node.Children[0]).FillItem(Item1);
          TETblExprNodeField(Node.Children[1]).FillItem(Item2);
          FieldList1.Append(Item1);
          FieldList2.Append(Item2);
          Inc(Result);
          // will delete this node
          NodesToDelete.Add(Node);
         end;
        // -> AND (...)
        //Node := Node.NextFactor;
       end;
      // delete used nodes
      for i:=0 to NodesToDelete.Count-1 do
       begin
        FRootNode.Children.Delete(FRootNode.Children.IndexOf(NodesToDelete[i]));
        TETblExprNode(NodesToDelete[i]).Free;
       end;
      if (FRootNode.Children.Count = 0) then
       begin
         FRootNode.Free;
         FRootNode := nil;
       end;
     finally
      NodesToDelete.Free;
     end;
   end
 else
 // IF '='
 if ((FRootNode is TETblExprNodeComparison) and
    (FRootNode.Operator = doEQ)) then
  begin
    if (FRootNode.IsJoinCondition(AO1,AO2)) then
     begin
      // store extracted filter
      TETblExprNodeField(FRootNode.Children[0]).FillItem(Item1);
      TETblExprNodeField(FRootNode.Children[1]).FillItem(Item2);
      FieldList1.Append(Item1);
      FieldList2.Append(Item2);
      Inc(Result);
      // will delete this node
      FRootNode.Free;
      FRootNode := nil;
     end;
  end;
end;// ExtractJoinConditions


//------------------------------------------------------------------------------
// makes filter string for specified AO
//------------------------------------------------------------------------------
function TETblExpression.GetFilter(AO: TEasyAO): AnsiString;
begin
 Result := FRootNode.GetFilter(AO);
end;// GetFilter


//------------------------------------------------------------------------------
// replace pseudonyms to original names (f1 -> table1.field1)
//------------------------------------------------------------------------------
procedure TETblExpression.ReplacePseudonyms(SelectList: array of TETblSelectListItem);
begin
 if (FRootNode <> nil) then
  FRootNode.ReplacePseudonyms(SelectList);
end;// ReplacePseudonyms


//------------------------------------------------------------------------------
// is expression contains no nodes
//------------------------------------------------------------------------------
function TETblExpression.IsEmpty: Boolean;
begin
 Result := (FRootNode = nil);
end;// IsEmpty


procedure TETblExpression.ParseValueExpr;
var
  bOk: Boolean;
begin
 // get first token (for very beginning of the query) or current token
 bOk := FLex.GetCurrentToken(Token);

 if (not bOk) then
  raise ETblException.Create(01039, [Token.LineNum], nil);

 // parse
 FRootNode := ParseValueExpression;
end;// Parse


//------------------------------------------------------------------------------
// Accumulate for aggregate functions
//------------------------------------------------------------------------------
procedure TETblExpression.Accumulate;
begin
 FRootNode.Accumulate;
end;//Accumulate


//------------------------------------------------------------------------------
// return Expression DataType
//------------------------------------------------------------------------------
function TETblExpression.getDataType(AO: TEasyAO): TFieldType;
begin
 Result := FRootNode.getDataType;
end;//getDataType


//------------------------------------------------------------------------------
// return Expression DataSize
//------------------------------------------------------------------------------
function TETblExpression.getDataSize(AO: TEasyAO): Integer;
begin
 if FRootNode <> nil then
   Result := FRootNode.getDataSize
 else
   Result := 0;
end;//getDataSize


//------------------------------------------------------------------------------
// Return DataValue
//------------------------------------------------------------------------------
function TETblExpression.getDataValue(DataSet: TDataSet = nil): TETblDataValue;
begin
  if (FRootNode <> nil) then
   begin
  //InitDataValue(Result);
  //CopyDataValue(FRootNode.getDataValue(AO), Result);
  Result := FRootNode.getDataValue(DataSet);
  Result.IsDataLinked := true;
   end
  else
   raise ETblException.Create(01070, nil);
end;//getDataValue


//------------------------------------------------------------------------------
// Init for aggregate functions
//------------------------------------------------------------------------------
procedure TETblExpression.Init;
begin
 if FRootNode <> nil then
  FRootNode.Init;
end;//Init


//------------------------------------------------------------------------------
// parses <value expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseValueExpression: TETblExprNode;
var
 SavedTokenNo: integer;        // saved/restored information
begin
{
<value expression> ::=
      <numeric value expression>
    | <string value expression>
    | <datetime value expression>
    | <interval value expression>
}
 SaveState(SavedTokenNo);
 Result := ParseNumericValueExpression;
 {if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseSearchCondition;
  end;}
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseStringValueExpression;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseDatetimeValueExpression;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseTrueFalseConst;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseNullConst;
  end;
end;// ParseValueExpression

//------------------------------------------------------------------------------
// parses <numeric value expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseNumericValueExpression: TETblExprNode;
var
  Term: TETblExprNode;
begin
{
<numeric value expression> ::=
      <term>
    | <numeric value expression> <plus sign> <term>
    | <numeric value expression> <minus sign> <term>
}
  Result:=nil;
  Term := ParseTerm;
  if Term <> nil then
   begin
    if (Token.Text='+') or (Token.Text='-') then
     begin
      Result := TETblExprNodeArithmetic.Create(doADD, Term);
      while (Token.Text='+') or (Token.Text='-') do
       begin
         Term := ParseTerm;
         if Term = nil then
          begin
           Result.Free;
           Result := nil;
           break;
          end;
         Result.Children.Add(Term);
       end;
     end
    else
     Result := Term;
    if Token.Text='||' then
     begin
      Result.Free;
      Result := nil;
     end;
   end
end;//ParseNumericValueExpression

//------------------------------------------------------------------------------
// parses <term>
//------------------------------------------------------------------------------
function TETblExpression.ParseTerm: TETblExprNode;
var
  Factor: TETblExprNode;
  op: TETblDataOperator;
  SavedTokenNo: integer;        // saved/restored information
  bNot:         boolean;
begin
{

<term> ::=
      <factor>
    | <term> <asterisk> <factor>
    | <term> <solidus> <factor>
    | NOT <factor>
}
  SaveState(SavedTokenNo);
  if (Token.Text = '!') then
   begin
//    Result := ParseBooleanFactor;
    GetNextToken;
    Factor := ParseFactor;
    if (Factor <> nil) then
     begin
      Result := TETblExprNodeBoolean.Create(doNOT, Factor);
      Exit;
     end
    else
     RestoreState(SavedTokenNo);
   end;
  SaveState(SavedTokenNo);
  bNot := false;
  // NOT bitwise or comparison
  if (Token.Text = '~') then
   begin
    bNot := true;
    GetNextToken;
   end;
  Result:=ParseFactor;

  if Result = nil then
   RestoreState(SavedTokenNo)
  else
   begin
    if (bNot) then
     begin
      Result := TETblExprNodeArithmetic.Create(doBitwiseNOT, Result);
     end
    else
    while (Token.Text='*') or (Token.Text='/')  or
          (Token.ReservedWord = rwMOD) or (Token.Text = '%') or
          (Token.Text = '&') or
          (Token.Text = '|') or
          (Token.ReservedWord = rwSHL) or (Token.Text = '<<') or
          (Token.ReservedWord = rwSHR) or (Token.Text = '>>') or
          (Token.ReservedWord = rwXOR) or (Token.Text = '^')
          do
     begin
      if Token.Text='*' then
        op := doMUL
      else
      if ((Token.Text='%') or (Token.ReservedWord = rwMOD)) then
        op := doMOD
      else
      if (Token.Text = '&') then
        op := doBitwiseAND
      else
      if (Token.Text = '|') then
        op := doBitwiseOR
      else
      if ((Token.ReservedWord = rwSHL) or (Token.Text = '<<')) then
        op := doSHL
      else
      if ((Token.ReservedWord = rwSHR) or (Token.Text = '>>')) then
        op := doSHR
      else
      if ((Token.ReservedWord = rwXOR) or (Token.Text = '^')) then
        op := doXOR
      else
        op := doDIV;
      // get next token
      GetNextToken;
      Result := TETblExprNodeArithmetic.Create(op, Result);
      Factor := ParseFactor;
//!!      if Factor = nil then ;
      Result.Children.Add(Factor);
     end;
   end; // factor parsed
end;//ParseTerm

//------------------------------------------------------------------------------
// parses <factor>
//------------------------------------------------------------------------------
function TETblExpression.ParseFactor: TETblExprNode;
var
  minus: boolean;
begin
{
<factor> ::=
    [ <sign> ] <numeric primary>
}
  minus := false;
  if ParseSign = sgnMinus then minus := true;
  Result:=ParseNumericPrimary;
  if (result <> nil) and minus then
    Result := TETblExprNodeArithmetic.Create(doSUB, Result);

end;//ParseFactor

//------------------------------------------------------------------------------
// parses <sign>
//------------------------------------------------------------------------------
function TETblExpression.ParseSign: TSign;
begin
  if Token.Text = '+' then Result := sgnPlus
  else
  if Token.Text = '-' then Result := sgnMinus
  else Result := sgnUndefined;
  if Result <> sgnUndefined then GetNextToken;
end;//ParseSign

//------------------------------------------------------------------------------
// parses <numeric primary>
//------------------------------------------------------------------------------
function TETblExpression.ParseNumericPrimary: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<numeric primary> ::=
      <value expression primary>
    | <numeric value function>
}
  Result := ParseValueExpressionPrimary;
  // save current state
  SaveState(SavedTokenNo);
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseNumericValueFunction;
   end;
  // Check for numeric content condition
  if Result <> nil then
   begin
    if Result.ClassType = TETblExprNodeConst then
     if not IsNumericDataType(Result.Data.DataType) then
      begin
       RestoreState(SavedTokenNo);
       Result.Free;
       Result := nil;
      end;
   end;

end;//ParseNumericPrimary

//------------------------------------------------------------------------------
// parses <value expression primary>
//------------------------------------------------------------------------------
function TETblExpression.ParseValueExpressionPrimary: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<value expression primary> ::=
      <unsigned value specification>
    | <column reference>
    | <set function specification>
    | <scalar subquery>
    | <case expression>
    | <left paren> <value expression> <right paren>
    | <cast specification>
}
  SaveState(SavedTokenNo);
  // parses <unsigned value specification>
  Result := ParseUnsignedValueSpecification;
  // parses <column reference>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseColumnReference;
   end;
  // parses <SubQuery>
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseSubQuery;
   end;
  // parses <set function specification>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseSetFunctionSpecification;
   end;
  // parses ( <value expression> )
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    // '('
    if Token.TokenType = tktLeftParenthesis then
     begin
      // get next token
      GetNextToken;
      Result := ParseValueExpression;
      if (Result<>nil) and
         (Token.TokenType <> tktRightParenthesis) then
       begin
        Result.Free;
        raise ETblException.Create(02111,
                 [Token.Text, Token.LineNum,Token.ColumnNum], nil);
       end;
      // get next token
      GetNextToken;
     end;
   end;
  // parses <cast specification>
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseCastSpecification;
   end;
end;//ParseValueExpressionPrimary

//------------------------------------------------------------------------------
// parses <unsigned value specification>
//------------------------------------------------------------------------------
function TETblExpression.ParseUnsignedValueSpecification: TETblExprNode;
begin
{
<unsigned value specification> ::=
      <unsigned literal>
    | <general value specification>
}
  Result := ParseUnsignedLiteral;
end;//ParseUnsignedValueSpecification

//------------------------------------------------------------------------------
// parses <unsigned literal>
//------------------------------------------------------------------------------
function TETblExpression.ParseUnsignedLiteral: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<unsigned literal> ::=
      <unsigned numeric literal>
    | <general literal>
}
  // save current state
  SaveState(SavedTokenNo);
  Result := ParseUnsignedNumericLiteral;
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseGeneralLiteral;
   end;
end;//ParseUnsignedLiteral


//------------------------------------------------------------------------------
// parses <unsigned numeric literal>
//------------------------------------------------------------------------------
function TETblExpression.ParseUnsignedNumericLiteral: TETblExprNode;
var
  Value: TETblDataValue;
  oldSeparator: Char;
begin
{
<unsigned numeric literal> ::=
      <exact numeric literal>
    | <approximate numeric literal>
}
 InitDataValue(Value);
 // integer
 if (Token.TokenType = tktInt) then
  begin

   if Token.Text = '' then
     SetDataValueAsNull(Value, ftInteger)
   else
     SetDataValueAsInteger(Value, StrToInt(Token.Text));
    
   Result := TETblExprNodeConst.Create(Value);
   // get next token
   GetNextToken;
  end
 else
 // float
 if (Token.TokenType = tktFloat) then
  begin
{$IFDEF D17H}
   oldSeparator := FormatSettings.DecimalSeparator;
   FormatSettings.DecimalSeparator := '.';
   try
    SetDataValueAsFloat(Value, StrToFloat(Token.Text));
   finally
    FormatSettings.DecimalSeparator := oldSeparator;
   end;
{$ELSE}
   oldSeparator := DecimalSeparator;
   DecimalSeparator := '.';
   try
    SetDataValueAsFloat(Value, StrToFloat(Token.Text));
   finally
    DecimalSeparator := oldSeparator;
   end;
{$ENDIF}
   Result := TETblExprNodeConst.Create(Value);
   // get next token
   GetNextToken;
  end
 else
  Result := nil;
 FinalizeDataValue(Value);
end;//ParseUnsignedNumericLiteral


{ TETblExprNodeConst }

function TETblExprNodeConst.CanBeAssigned(AO: TEasyAO): Boolean;
begin
  Result := True;
end;

constructor TETblExprNodeConst.Create(Value: TETblDataValue);
begin
  Inherited Create;
  CopyDataValue(Value, Data);
end;


function TETblExprNodeConst.getDataSize: Integer;
begin
  Result := 0;
  if Data.DataType = ftString then
    Result := Length(GetDataValueAsString(Data));
end;


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TETblExprNodeConst.getDataType: TFieldType;
begin
  Result := Data.DataType;
end;//getDataType


function TETblExprNodeConst.getDataValue(DataSet: TDataSet = nil): TETblDataValue;
begin
  Result := Data;
end;

function TETblExprNodeConst.GetFilter(AO: TEasyAO): AnsiString;
begin
  Result := GetDataValueAsString(Data);
  if (Data.DataType in [ftString]) then
    Result := QuotedStr(Result);
end;

function TETblExprNodeConst.TestTree(Indent: Integer): AnsiString;
var
  Value: TETblDataValue;
begin
  InitDataValue(Value);
  CopyDataValue(Data, Value);
  cast(Value, ftString);
  Result := StringOfChar(TestIndentString, Indent*2) + '(' +
            GetDataValueAsString(Value) + ')  ' + GetDataTypeName(Data.DataType) +
            '  <const>'#13#10;
  FinalizeDataValue(Value);
end;

{ TETblExprNodeField }

//------------------------------------------------------------------------------
// Assign AO
//------------------------------------------------------------------------------
procedure TETblExprNodeField.AssignAO(AO: TEasyAO);
var
  Fields: TaaIntArray;
begin
  FAO := AO;
  if FAO <> nil then
   begin
    Fields := TaaIntArray.Create;
    try
//      FAO.FieldExists(FieldName, TableName, False, Fields);
      // Andrew: (5.20) - unhide fields used in expressions
//      FAO.FieldExists(FieldName, TableName, True, Fields);
      // Leo: modified to unhide only children (5.30);
      FAO.FieldExists(FieldName, TableName, True, Fields, True);
      if Fields.ItemCount = 1 then
        FieldNumber := Fields.items[0]
      else
        raise ETblException.Create(02108, [TableName+'.'+FieldName], nil);
    finally
      Fields.Free;
    end;
  end;
end;//AssignAO


function TETblExprNodeField.CanBeAssigned(AO: TEasyAO): Boolean;
var
  Fields: TaaIntArray;
  n: integer;
begin
  n := -1;
  if AO <> nil then
   begin
    Fields := TaaIntArray.Create;
  try
      AO.FieldExists(FieldName, TableName, False, Fields);
      if Fields.ItemCount = 1 then n := Fields.items[0];
  finally
      Fields.Free;
  end;
end;
  Result := n <> -1;
end;


constructor TETblExprNodeField.Create(FieldName1, TableName1: AnsiString);
begin
   inherited Create;
   FieldNumber := -1;
   FieldName := FieldName1;
   TableName := TableName1;
end;

//------------------------------------------------------------------------------
// fills Field Item
//------------------------------------------------------------------------------
procedure TETblExprNodeField.FillItem(var Item: TETblSelectListItem);
begin
  Item.TableName := TableName;
  Item.FieldName := FieldName;
end;// FillItem


//------------------------------------------------------------------------------
// return Size of Data
//------------------------------------------------------------------------------
function TETblExprNodeField.getDataSize: Integer;
begin
  Result := 0;
  if FAO <> nil then
    Result := FAO.GetFieldSize(FieldNumber);
end;//getDataSize


//------------------------------------------------------------------------------
// Return Type of Data or ftUnknown, if it's impossible
//------------------------------------------------------------------------------
function TETblExprNodeField.getDataType: TFieldType;
begin
  Result := ftUnknown;
  if FAO <> nil then
   Result := FAO.GetFieldType(FieldNumber);
end;//getDataType


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TETblExprNodeField.getDataValue(DataSet: TDataSet): TETblDataValue;
begin
 // Finalize Data
 FinalizeDataValue(Data);
 // Copy GetFieldValue to Data
 if DataSet <> nil then
   TEasyDataset(DataSet).GetFieldValue(Data, FieldNumber, true)
 else
   FAO.GetFieldValue(Data, FieldNumber, true, true);
 Result := Data;
end;


function TETblExprNodeField.GetFilter(AO: TEasyAO): AnsiString;
var
  FieldNumber: TaaIntArray;
  //LeftFilter, RightFilter, Op: AnsiString;
begin
  FieldNumber := TaaIntArray.Create;
  try
    AO.FieldExists(FieldName, TableName, False, FieldNumber);
    if (FieldNumber.ItemCount = 0) then
      raise ETblException.Create(01052, [FieldName], nil);
    Result := AO.GetFieldName(FieldNumber.Items[0], False);
    // [Field Name] ?
    if (Pos(' ', Result) <> 0) then
      Result := '['+Result+']';
  finally
    FieldNumber.Free;
  end;
end;

function TETblExprNodeField.isConstant: boolean;
begin
  Result:=false;
end;

procedure TETblExprNodeField.ReplacePseudonyms(
  SelectList: array of TETblSelectListItem);
var
  i: Integer;
begin
  for i := 0 to Length(SelectList)-1 do
  if (AnsiUpperCase(FieldName) = AnsiUpperCase(SelectList[i].Pseudonym)) then
   if (not SelectList[i].IsExpression) then
    begin
      FieldName := SelectList[i].FieldName;
      TableName := SelectList[i].TableName;
    end;
end;

function TETblExprNodeField.TestTree(Indent: Integer): AnsiString;
begin
  Result := StringOfChar(TestIndentString, Indent*2) + '(';
  if TableName <> '' then  Result := Result + TableName + '.';
  Result := Result + FieldName + ')  [field]'#13#10;
end;


///////////////////////////////////////////////////////////////////////////////
//
// TETblExprNodeSubQuery
//
///////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TETblExprNodeSubQuery.Create(
                       QueryText:         AnsiString;
                       bNot:              Boolean = False;
                       SourceNode:        TETblExprNode = nil
                       );
begin
  inherited Create;
  FSQLText := QueryText;
  FQuery := nil;
  FNot := bNot;
  FSourceNode := SourceNode;
  if (SourceNode <> nil) then
   Children.Add(SourceNode);
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TETblExprNodeSubQuery.Destroy;
begin
  if (FQuery <> nil) then
   FQuery.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TETblExprNodeSubQuery.GetDataValue(DataSet: TDataSet = nil): TETblDataValue;
begin
  if (FQuery = nil) then
   begin
{$IFDEF FULL_VERSION}
    FQuery := TEasyQuery.Create(nil);
    try
      TEasyQuery(FQuery).SQL.Text := FSQLText;
      if (DataSet = nil) then
       raise ETblException.Create(00055);
      TEasyQuery(FQuery).DatabaseName := TEasyDataset(Dataset).DatabaseName;
      TEasyQuery(FQuery).SessionName := TEasyDataset(Dataset).SessionName;
      TEasyQuery(FQuery).DatabaseFileName := TEasyDataset(Dataset).DatabaseFileName;
      TEasyQuery(FQuery).Open;
      if (TEasyQuery(FQuery).RecordCount < 1) then
       raise ETblException.Create(00056);
      if (TEasyQuery(FQuery).RecordCount > 1) then
       raise ETblException.Create(00057);
      TEasyQuery(FQuery).GetFieldValueWithProjection(Data,0,True);
      FQuery.Close;
    except
      FQuery.Free;
      Fquery := nil;
      raise;
    end;
{$ENDIF}
   end;
  Result := Data;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TETblExprNodeSubQueryIn.GetDataValue(DataSet: TDataSet = nil): TETblDataValue;
var v:         variant;
    FieldName: AnsiString;
    value:     Boolean;
begin
{$IFDEF FULL_VERSION}
  if (FQuery = nil) then
   begin
    FQuery := TEasyQuery.Create(nil);
    try
      TEasyQuery(FQuery).SQL.Text := FSQLText;
      if (DataSet = nil) then
       raise ETblException.Create(00058);
      TEasyQuery(FQuery).DatabaseName := TEasyDataset(Dataset).DatabaseName;
      TEasyQuery(FQuery).SessionName := TEasyDataset(Dataset).SessionName;
      TEasyQuery(FQuery).DatabaseFileName := TEasyDataset(Dataset).DatabaseFileName;
      TEasyQuery(FQuery).Open;
    except
      FQuery.Free;
      Fquery := nil;
      raise;
    end;
   end;
  FieldName := FQuery.Fields[0].FieldName;
  if (FSourceNode = nil) then
   raise ETblException.Create(00065);
  Result := TETblExprNode(FSourceNode).GetDataValue(Dataset);
  v := GetDataValueAsVariant(Result);
  value := TEasyQuery(FQuery).Locate(FieldName,v,[]);
  if (FNot) then
   value := not value;
  SetDataValueAsBoolean(Data,value);
{$ENDIF}
  Result := Data;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TETblExprNodeSubQueryExists.GetDataValue(DataSet: TDataSet = nil): TETblDataValue;
var value: Boolean;
begin
{$IFDEF FULL_VERSION}
  if (FQuery = nil) then
   begin
    FQuery := TEasyQuery.Create(nil);
    try
      TEasyQuery(FQuery).SQL.Text := FSQLText;
      if (DataSet = nil) then
       raise ETblException.Create(00059);
      TEasyQuery(FQuery).DatabaseName := TEasyDataset(Dataset).DatabaseName;
      TEasyQuery(FQuery).SessionName := TEasyDataset(Dataset).SessionName;
      TEasyQuery(FQuery).DatabaseFileName := TEasyDataset(Dataset).DatabaseFileName;
      TEasyQuery(FQuery).Open;
      if (FNot) then
        value := TEasyQuery(FQuery).Eof
      else
        value := not TEasyQuery(FQuery).Eof;
      SetDataValueAsBoolean(Data,value);
      FQuery.Close;
    except
      FQuery.Free;
      Fquery := nil;
      raise;
    end;
   end;
{$ENDIF}
  Result := Data;
end; // GetDataValue


////////////////////////////////////////////////////////////////////////////////
//
// TETblExprNodeArithmetic
//
////////////////////////////////////////////////////////////////////////////////


{constructor TETblExprNodeArithmetic.Create(Op: TETblDataOperator;
  Node: TETblExprNode);
    begin
  inherited Create;
  Operator := Op;
  Children.Add(Node);
end;

constructor TETblExprNodeArithmetic.Create(Op: TETblDataOperator; Node1,
  Node2: TETblExprNode);
begin
  inherited Create;
  Operator := Op;
  Children.Add(Node1);
  Children.Add(Node2);
end;
}


//------------------------------------------------------------------------------
// Add operation
//------------------------------------------------------------------------------
procedure TETblExprNodeArithmetic.AddData(DataSet: TDataSet = nil);
var
  i: Integer;
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Add next values
  for i:=1 to Children.Count-1 do
    AddDataValues(Data,TETblExprNode(Children[i]).getDataValue(DataSet));
end;//AddData


function TETblExprNodeArithmetic.getDataValue(DataSet: TDataSet = nil): TETblDataValue;
begin
  case Operator of
   doSUB:       SubData(DataSet);
   doADD:       AddData(DataSet);
   doMUL:       MulData(DataSet);
   doDIV:       DivData(DataSet);
   doABS:       AbsData(DataSet);
   doCEILING:   CeilingData(DataSet);
   doFLOOR:     FloorData(DataSet);
   doMOD:       ModData(DataSet);
   doPOWER:     PowerData(DataSet);
   doRANDOM:    RandomData(DataSet);
   doROUND:     RoundData(DataSet);
   doSIGN:      SignData(Dataset);
   doTRUNCATE:  TruncateData(Dataset);
   doBitwiseAND:  AndData(DataSet);
   doBitwiseOR:   OrData(DataSet);
   doBitwiseNOT:  NotData(DataSet);
   doSHL:         ShlData(DataSet);
   doSHR:         ShrData(DataSet);
   doXOR:         XorData(DataSet);
   doHEX:         HexData(DataSet);
  else
     raise Exception.Create('Unknown Operator');
  end;
  Result := Data;
end;

procedure TETblExprNodeArithmetic.DivData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Division to second argument
  DivDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end;

// ABS operation
procedure TETblExprNodeArithmetic.AbsData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // ABS
  AbsDataValues(Data);
end; // AbsData


// CEILING operation
procedure TETblExprNodeArithmetic.CeilingData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // ceiling
  CeilingDataValues(Data);
end; // CeilingData


// FLOOR operation
procedure TETblExprNodeArithmetic.FloorData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // floor
  FloorDataValues(Data);
end; // FloorData


// MOD operation
procedure TETblExprNodeArithmetic.ModData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  ModDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; // ModData


// POWER operation
procedure TETblExprNodeArithmetic.PowerData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  PowerDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; //  PowerData


// RAND operation
procedure TETblExprNodeArithmetic.RandomData(DataSet: TDataSet = nil);
begin
  if (Children.Count = 1) then
   begin
    CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
    RandomDataValues(Data,true);
   end
  else
   RandomDataValues(Data);
end; // RandomData


// ROUND operation
procedure TETblExprNodeArithmetic.RoundData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  if (Children.Count = 1) then
   RoundDataValues(Data,Data,false)
  else
   RoundDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet),true);
end; // RoundDate


// SIGN operation
procedure TETblExprNodeArithmetic.SignData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  SignDataValues(Data);
end; // SignData


// TRUNCATE operation
procedure TETblExprNodeArithmetic.TruncateData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  if (Children.Count = 1) then
   TruncateDataValues(Data,Data,false)
  else
   TruncateDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet),true);
end; // TruncateData


// AND operation
procedure TETblExprNodeArithmetic.AndData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  AndDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; // AndData


// OR operation
procedure TETblExprNodeArithmetic.OrData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  OrDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; // OrData


// NOT operation
procedure TETblExprNodeArithmetic.NotData(DataSet: TDataSet = nil);
begin
 CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
 NotDataValues(Data);
end; // NotData


// SHL operation
procedure TETblExprNodeArithmetic.ShlData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  ShlDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; // SHLData


// SHR operation
procedure TETblExprNodeArithmetic.ShrData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  ShrDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; // SHRData


// XOR operation
procedure TETblExprNodeArithmetic.XorData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  XorDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end; // XORData


// HEX operation
procedure TETblExprNodeArithmetic.HexData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  if (Children.Count = 1) then
   HexDataValues(Data,Data,false)
  else
   HexDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet),true);
end;


function TETblExprNodeArithmetic.GetFilter(AO: TEasyAO): AnsiString;
var
  Op: AnsiString;
  i: integer;
  Separator: AnsiString;
begin
  Result := '';
  // get operator string
  Op := ' ' + GetOperatorName(Operator) + ' ';

  // Unary operator
  if Operator in [doNOT,doISNULL,doISNOTNULL] then
    begin
      if (Operator = doNOT) then
        Result := Op + TETblExprNode(Children[0]).GetFilter(AO)
      else
        Result := TETblExprNode(Children[0]).GetFilter(AO) + Op;
    end
  else
  // Binary operator
  if Operator in [doEQ,doNE,doLT,doGT,doLE,doGE,doLIKE,doNOTLIKE] then
    Result := TETblExprNode(Children[0]).GetFilter(AO) +
              Op + TETblExprNode(Children[1]).GetFilter(AO)
  else
  // Multiple operator ( ... and ... and ... )
  if Operator in [doOR,doAND] then
   begin
    Separator := '';
    for i:=0 to Children.Count-1 do
     begin
      Result := Result + Separator +
                TETblExprNode(Children[i]).GetFilter(AO);
      Separator := Op;
     end
   end;
end;

procedure TETblExprNodeArithmetic.SubData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Data := -Data
  NegativeDataValues(Data);
end;

procedure TETblExprNodeArithmetic.MulData(DataSet: TDataSet = nil);
begin
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Mul to next argument
  MulDataValues(Data,TETblExprNode(Children[1]).getDataValue(DataSet));
end;

function TETblExprNodeArithmetic.TestTree(Indent: Integer): AnsiString;
var
  i: Integer;
begin
  Result := StringOfChar(TestIndentString, Indent*2) + '(' +
            GetOperatorName(Operator) + ') ' +
            ClassName + #13#10;
  for i:=0 to Children.Count-1 do
   begin
     Result := Result + TETblExprNode(Children[i]).TestTree(Indent+1);
   end;
end;



function TETblExprNodeArithmetic.getDataSize: Integer;
var
  i: integer;
  ftype: TFieldType;
  child: TETblExprNode;
  s: AnsiString;
begin
  s:=IntToStr( high(int64));
  Result := 0;
  ftype := getDataType;
  if ftype in [ftString, ftWideString, ftBytes] then
   begin
    if Operator in [doADD, doCONCAT] then
     for i:=0 to Children.Count-1 do
      begin
       child := TETblExprNode(Children[i]);
       case child.getDataType of
         ftString,
         ftWideString,
         ftBytes:
           Result := Result + child.getDataSize;
         ftAutoInc,
         ftInteger:
           Result := Result + 11;
         ftSmallInt:
           Result := Result + 6;
         ftWord:
           Result := Result + 5;
         ftLargeInt:
           Result := Result + 20;
         ftFloat,
         ftDate,
         ftTime,
         ftDateTime:
           Result := Result + 26;
         ftBoolean:
           Result := Result + 5;
         ftCurrency:
           Result := Result + 21;
       end;
      end; // doHex, doAdd, doConcat
    if (Operator = doHex) then
       begin
         child := TETblExprNode(Children[0]);
         case child.getDataType of
          ftAutoInc,
          ftInteger:
           Result := 9;
          ftSmallInt:
           Result := 5;
          ftWord:
           Result := 5;
          ftLargeInt:
           Result := 17;
          ftString,ftWideString:
           Result := child.getDataSize * 2;
         end;
         if (children.Count = 2) then
          begin
           child := TETblExprNode(Children[1]);
           if (not child.Data.IsNull) then
            begin
              i := GetDataValueAsInteger(child.Data);
              if (i = 2) then
             // oxff
               Inc(Result,2)
              else
              if (i = 1) then
             // $FF
               Inc(Result);
            end;
          end;
       end // doHex
   end; // string, widestring or bytes
end;


function TETblExprNodeArithmetic.GetDataType: TFieldType;
begin
  if Operator = doDIV then
    Result := ftFloat
  else
  if Operator = doMOD then
    Result := ftLargeint
  else
  if Operator = doHEX then
    Result := ftString
  else
  if ((Operator = doTRUNCATE) or (Operator = doROUND)) then
   begin
    if (Children.Count = 1) then
     Result := ftInteger
    else
     Result := ftFloat;
   end
  else
  if (Operator = doRANDOM) then
   begin
    if (Children.Count = 0) then
     Result := ftFloat
    else
     Result := ftLargeInt;
   end
  else
  if (Operator = doPOWER) then
   begin
    if (IsIntegerDataType(TETblExprNode(Children[0]).getDataType)) then
     Result := ftLargeint
    else
     Result := ftFloat;
   end
  else
  if (Operator in [doCEILING,doFLOOR,doSIGN]) then
    Result := ftInteger
  else
    Result := inherited getDataType;
end;

{ TETblExprNodeFunction }

{constructor TETblExprNodeFunction.Create(Op: TETblDataOperator);
begin
  Inherited Create;
  Operator := Op;
end;}

//------------------------------------------------------------------------------
// parses <column reference>
//------------------------------------------------------------------------------
function TETblExpression.ParseColumnReference: TETblExprNode;
var
  FieldName, TableName: AnsiString;
  IsResWord: boolean;
begin
 Result := nil;
 //InitDataValue(Value);
 if ((Token.TokenType = tktString) or
     (Token.TokenType = tktBracketedString) or
     (Token.TokenType = tktReservedWord)) then
  begin
   //SavedTokenNo := FLex.GetCurrentTokenNo;
   FieldName := Token.Text;
   TableName := '';
   IsResWord := Token.ReservedWord <> rwNone;
   // get next token
   GetNextToken;
   // table.field?
   if (Token.TokenType = tktDot) then
    begin
     TableName := FieldName;
     GetNextToken;
     FieldName := Token.Text;
     IsResWord := Token.ReservedWord <> rwNone;
     // get next token
     GetNextToken;
    end;
   // function ?
   if (Token.TokenType <> tktLeftParenthesis) and (not IsResWord) then
     Result := TETblExprNodeField.Create(FieldName, TableName);
  end;
 //FinalizeDataValue(Value);
end;//ParseColumnReference


//------------------------------------------------------------------------------
// parses <SUB QUERY>
//------------------------------------------------------------------------------
function TETblExpression.ParseSubQuery(bExists:       Boolean = False;
                                       bIn:           Boolean = False;
                                       bNot:          Boolean = False;
                                       SourceNode:    TETblExprNode = nil
                                       ): TETblExprNode;
var SubQueryText:           AnsiString;
    LeftParenthesisCount:   Integer;
    bSkipSpace:             Boolean;
    
begin
  Result := nil;
  if (Token.TokenType = tktLeftParenthesis) then
   begin
    LeftParenthesisCount := 1;
    if (GetNextToken) then
      if (Token.TokenType = tktReservedWord) then
       if (Token.ReservedWord = rwSELECT) then
        begin
         SubQueryText := Token.Text;
         bSkipSpace := False;
         while (GetNextToken) do
          begin
            if (Token.TokenType = tktLeftParenthesis) then
             Inc(LeftParenthesisCount)
            else
            if (Token.TokenType = tktRightParenthesis) then
             Dec(LeftParenthesisCount);
            if (LeftParenthesisCount = 0) then
             begin
              GetNextToken;
              break;
             end;
            if (Token.TokenType = tktBracketedString) then
             begin
              if (bSkipSpace) then
               SubQueryText := SubQueryText + '[' + Token.Text + ']'
              else
               SubQueryText := SubQueryText + Space + '[' + Token.Text + ']';
              bSkipSpace := False;
             end
            else
            if (Token.TokenType = tktQuotedString) then
             begin
              if (bSkipSpace) then
               SubQueryText := SubQueryText + SingleQuote + Token.Text + SingleQuote
              else
               SubQueryText := SubQueryText + Space + SingleQuote + Token.Text + SingleQuote;
              bSkipSpace := False;
             end
            else
            if (Token.TokenType = tktDot) then
             begin
              SubQueryText := SubQueryText + Token.Text;
              bSkipSpace := True;
             end
            else
             begin
              if (bSkipSpace) then
               SubQueryText := SubQueryText + Token.Text
              else
               SubQueryText := SubQueryText + Space + Token.Text;
              bSkipSpace := False;
             end;
          end; // building SubQuery text
         if (LeftParenthesisCount = 0) then
          begin
           if (bExists) then
            Result := TETblExprNodeSubQueryExists.Create(SubQueryText,
                        bNot,SourceNode)
           else
           if (bIn) then
            Result := TETblExprNodeSubQueryIn.Create(SubQueryText,
                        bNot,SourceNode)
           else
            Result := TETblExprNodeSubQuery.Create(SubQueryText,
                        bNot,SourceNode);
          end; // while GetNextToken
        end; // SubQuery
   end; // Left Parenthesis
end; // ParseSubQuery


//------------------------------------------------------------------------------
// TestTree
//------------------------------------------------------------------------------
function TETblExpression.TestTree: AnsiString; 
begin
  Result:='';
  if FRootNode <> nil then
    Result:=FRootNode.TestTree(0);
end;


//------------------------------------------------------------------------------
// parses <string value expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseStringValueExpression: TETblExprNode;
begin
{
<string value expression> ::=
      <character value expression>
    | <bit value expression>
}
  Result := ParseCharacterValueExpression;
end;//ParseStringValueExpression


//------------------------------------------------------------------------------
// parses <character value expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseCharacterValueExpression: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<character value expression> ::=
      <concatenation>
    | <character factor>
}
  // save current state
  SaveState(SavedTokenNo);
  Result := ParseConcatination;
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseCharacterFactor;
   end;
end;//ParseCharacterValueExpression


//------------------------------------------------------------------------------
// parses <concatenation>
//------------------------------------------------------------------------------
function TETblExpression.ParseConcatination: TETblExprNode;
var
  left, right: TETblExprNode;
begin
{
<concatenation> ::=
    <character value expression> <concatenation operator>
        <character factor>
}
  Result := nil;
  left := ParseCharacterFactor;
  //left := ParseCharacterValueExpression;
  if left <> nil then
   if (Token.Text = '||') or (Token.Text = '+') then
    begin
     Result := TETblExprNodeStringFunction.Create(doConcat, left);
     while (Token.Text = '||') or (Token.Text = '+') do
      begin
       GetNextToken;
       right := ParseCharacterFactor;
       if right <> nil then
        Result.Children.add(right);
      end;
    end
   else
    left.Free;
end;//ParseConcatination


{constructor TETblExprNodeFunction.Create(Op: TETblDataOperator;
  Node: TETblExprNode);
begin
  Inherited Create;
  Operator := Op;
  Children.Add(Node);
end;

constructor TETblExprNodeFunction.Create(Op: TETblDataOperator; Node1,
  Node2: TETblExprNode);
begin
  Inherited Create;
  Operator := Op;
  Children.Add(Node1);
  Children.Add(Node2);
end;
}

//------------------------------------------------------------------------------
// parses <character factor>
//------------------------------------------------------------------------------
function TETblExpression.ParseCharacterFactor: TETblExprNode;
begin
{
<character factor> ::=
    <character primary> [ <collate clause> ]
}
  Result := ParseCharacterPrimary;
end;//ParseCharacterFactor


//------------------------------------------------------------------------------
// parses <character primary>
//------------------------------------------------------------------------------
function TETblExpression.ParseCharacterPrimary: TETblExprNode;
begin
{
<character primary> ::=
      <value expression primary>
    | <string value function>
}
  Result := ParseValueExpressionPrimary;
  if Result = nil then
   begin
    Result := ParseStringValueFunction;
   end;
end;//ParseCharacterPrimary


//------------------------------------------------------------------------------
// parses <general literal>
//------------------------------------------------------------------------------
function TETblExpression.ParseGeneralLiteral: TETblExprNode;
begin
{
<general literal> ::=
      <character string literal>
    | <national character string literal>
    | <bit string literal>
    | <hex string literal>
    | <datetime literal>
    | <interval literal>
}
  Result := ParseCharacterStringLiteral;
end;//ParseGeneralLiteral


//------------------------------------------------------------------------------
// parses <character string literal>
//------------------------------------------------------------------------------
function TETblExpression.ParseCharacterStringLiteral: TETblExprNode;
var
  Value: TETblDataValue;
begin
(*
<character string literal> ::=
    [ <introducer><character set specification> ]
    <quote> [ <character representation>... ] <quote>
      [ { <separator>... <quote> [ <character representation>... ] <quote> }...]
*)
 Result := nil;
 if Token.TokenType = tktQuotedString then
  begin
   InitDataValue(value);
   if (Token.UnicodeText = '') then
    SetDataValueAsString(Value, Token.Text)
   else
    SetDataValueAsWideString(Value, Token.UnicodeText);
   Result := TETblExprNodeConst.Create(value);
   FinalizeDataValue(value);
   // get next token
   GetNextToken;
  end;
end;//ParseCharacterStringLiteral

{function TETblExprNodeFunction.getDataValue(DataSet: TDataSet = nil): TETblDataValue;
begin
  Result := Data;
end;}

{ TETblExprNodeStringFunction }

procedure TETblExprNodeStringFunction.Concat(DataSet: TDataSet = nil);
var
  ChildData: TETblDataValue;
  i: Integer;
begin
  InitDataValue(ChildData);
  // Get first argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Add next values
  for i:=1 to Children.Count-1 do
   begin
    CopyDataValue(TETblExprNode(Children[i]).getDataValue(DataSet), ChildData);
    // Types not equals
    {if ChildData.DataType <> Data.DataType then
     begin
       CommonType := getCommonDataType(ChildData.DataType, Data.DataType);
       if ChildData.DataType <> CommonType then
         Cast(ChildData, CommonType);
       if Data.DataType <> CommonType then
         Cast(Data, CommonType);
     end;}
    AddDataValues(Data, ChildData);
    {case ChildData.DataType of
     ftString:   SetDataValueAsString(Data, GetDataValueAsString(Data) +
                                            GetDataValueAsString(ChildData));
     else raise ETblException.Create(02097,['||'],nil);
    end;}
   end;
  FinalizeDataValue(ChildData);
end;


//------------------------------------------------------------------------------
// return DataSize
//------------------------------------------------------------------------------
function TETblExprNodeStringFunction.GetDataSize: Integer;
begin
  if Operator in [doPOS,doLENGTH] then
    Result:=0
  else
  if Operator = doCONCAT then
    Result := inherited GetDataSize
  else
    Result := TETblExprNode(Children[0]).getDataSize;
end;//GetDataSize


//------------------------------------------------------------------------------
// return DataType
//------------------------------------------------------------------------------
function TETblExprNodeStringFunction.GetDataType: TFieldType;
begin
  if Operator in [doPOS,doLENGTH] then
    Result := ftInteger
  else
    Result := inherited GetDataType;
end;//GetDataType


function TETblExprNodeStringFunction.getDataValue(
  DataSet: TDataSet = nil): TETblDataValue;
begin
  case Operator of
   doCONCAT:    Concat(DataSet);
   doUPPER:     Upper(DataSet);
   doLOWER:     Lower(DataSet);
   doTRIM:      Trim(DataSet);
   doLTRIM:     LTrim(DataSet);
   doRTRIM:     RTrim(DataSet);
   doSUBSTRING: Substring(DataSet);
   doPOS:       Pos(DataSet);
   doLENGTH:    Length(DataSet);
   else         raise Exception.Create('Unknown Operator');
  end;
  Result := Data;
end;

procedure TETblExprNodeStringFunction.Length(DataSet: TDataSet);
begin
  // Get argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Swich for type
  case Data.DataType of
   ftString,ftMemo:
     SetDataValueAsInteger(Data, System.Length(GetDataValueAsString(Data)));
   ftWideString:
     SetDataValueAsInteger(Data, System.Length(GetDataValueAsWideString(Data)));
   else raise ETblException.Create(02121,['LENGTH'],nil);
  end;
end;

procedure TETblExprNodeStringFunction.Lower(DataSet: TDataSet = nil);
begin
  // Get argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // cast to string
  if Data.DataType <> ftString then cast(Data, ftString);
  // process UPPER
  case Data.DataType of
   ftString:
     SetDataValueAsString(Data, AnsiLowerCase(GetDataValueAsString(Data)));
   else raise ETblException.Create(02099,['LOWER'],nil);
  end;
end;

procedure TETblExprNodeStringFunction.LTrim(DataSet: TDataSet = nil);
begin
  // Get argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // cast to string
  if Data.DataType <> ftString then cast(Data, ftString);
  // process UPPER
  case Data.DataType of
   ftString:
     SetDataValueAsString(Data, TrimLeft(GetDataValueAsString(Data)));
   else raise ETblException.Create(02101,['LTRIM'],nil);
  end;
end;

procedure TETblExprNodeStringFunction.Pos(DataSet: TDataSet);
var
  p: integer;
  SubstrData: TETblDataValue;
begin
  // 0 - Not Found
  //p := 0;
  // Get argument
  CopyDataValue(TETblExprNode(Children[1]).getDataValue(DataSet), Data);
  SubstrData := TETblExprNode(Children[0]).getDataValue(DataSet);

  // Swich for type
  case Data.DataType of
   ftString:
     case SubstrData.DataType of
      ftString:
        p := System.pos(GetDataValueAsString(SubstrData), GetDataValueAsString(Data));
      ftWideString:
        p := System.pos(GetDataValueAsWideString(SubstrData), GetDataValueAsString(Data));
      else raise ETblException.Create(02122,['POS'],nil);
     end;
   ftWideString:
     case SubstrData.DataType of
      ftString:
        p := System.pos(GetDataValueAsString(SubstrData), GetDataValueAsWideString(Data));
      ftWideString:
        p := System.pos(GetDataValueAsWideString(SubstrData), GetDataValueAsWideString(Data));
      else raise ETblException.Create(02123,['POS'],nil);
     end;
   else raise ETblException.Create(02124,['POS'],nil);
  end;
  SetDataValueAsInteger(Data, p);
end;

procedure TETblExprNodeStringFunction.RTrim(DataSet: TDataSet = nil);
begin
  // Get argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // cast to string
  if Data.DataType <> ftString then cast(Data, ftString);
  // process UPPER
  case Data.DataType of
   ftString:
     SetDataValueAsString(Data, TrimRight(GetDataValueAsString(Data)));
   else raise ETblException.Create(02102,['RTRIM'],nil);
  end;
end;

procedure TETblExprNodeStringFunction.Substring(DataSet: TDataSet);
var
  start, len: Integer;
  s: TETblDataValue;
begin
  // SUBSTRING(str, startindex, length)
  // SUBSTRING(str, startindex)

  // start
  start := GetDataValueAsInteger(TETblExprNode(Children[1]).getDataValue(DataSet));

  // string
  s := TETblExprNode(Children[0]).getDataValue(DataSet);

  // length
  if Children.Count >=3 then
   len := GetDataValueAsInteger(TETblExprNode(Children[2]).getDataValue(DataSet))
  else
   begin
     Length(DataSet);
     len := GetDataValueAsInteger(Data);
   end;

  // substring
  case s.DataType of
   ftString:
     SetDataValueAsString(Data, Copy(GetDataValueAsString(s),start,len));
   ftWideString:
     SetDataValueAsWideString(Data, Copy(GetDataValueAsWideString(s),start,len));
   else raise ETblException.Create(02125,['SUBSTRING'],nil);
  end;
end;

function TETblExprNodeStringFunction.TestTree(Indent: Integer): AnsiString;
var
  i: Integer;
begin
  Result := StringOfChar(TestIndentString, Indent*2) + '(' +
            GetOperatorName(Operator) + ') ' +
            '  <string function>'#13#10;
  for i:=0 to Children.Count-1 do
   begin
     Result := Result + TETblExprNode(Children[i]).TestTree(Indent+1);
   end;
end;

procedure TETblExprNodeStringFunction.Trim(DataSet: TDataSet = nil);
begin
  // Get argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // cast to string
  if Data.DataType <> ftString then cast(Data, ftString);
  // process UPPER
  case Data.DataType of
   ftString:
     SetDataValueAsString(Data, Sysutils.Trim(GetDataValueAsString(Data)));
   else raise ETblException.Create(02100,['TRIM'],nil);
  end;
end;

procedure TETblExprNodeStringFunction.Upper(DataSet: TDataSet = nil);
begin
  // Get argument
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // cast to string
  if Data.DataType <> ftString then cast(Data, ftString);
  // process UPPER
  case Data.DataType of
   ftString:
     SetDataValueAsString(Data, AnsiUpperCase(GetDataValueAsString(Data)));
   else raise ETblException.Create(02098,['UPPER'],nil);
  end;
end;
//------------------------------------------------------------------------------
// parses <string value function>
//------------------------------------------------------------------------------
function TETblExpression.ParseStringValueFunction: TETblExprNode;
begin
{
<string value function> ::=
      <character value function>
    | <bit value function>
}
  Result := ParseCharacterValueFunction;
end;//ParseStringValueFunction


//------------------------------------------------------------------------------
// parses <character value function>
//------------------------------------------------------------------------------
function TETblExpression.ParseCharacterValueFunction: TETblExprNode;
var
  arg1,arg2,arg3: TETblExprNode;
  op: TETblDataOperator;
begin
{
<character value function> ::=
      <character substring function>
    | <fold>
    | <form-of-use conversion>
    | <character translation>
    | <trim function>
}
  Result := nil;
  op := doUNDEFINED;
  if IsReservedWord(Token, rwUPPER) then op:=doUPPER
  else if IsReservedWord(Token, rwLOWER) then op:=doLOWER
  else if IsReservedWord(Token, rwTRIM) then op:=doTRIM
  else if IsReservedWord(Token, rwLTRIM) then op:=doLTRIM
  else if IsReservedWord(Token, rwRTRIM) then op:=doRTRIM
  else if IsReservedWord(Token, rwSUBSTRING) then op:=doSUBSTRING
  else if IsReservedWord(Token, rwTOSTRING) then op:=doTOSTRING
  ;
  if op = doUNDEFINED then Exit;
  // get next token
  GetNextToken;

  // Functions with 1 agrument
  if op in [doUPPER, doLOWER, doTRIM, doLTRIM, doRTRIM] then
   begin
    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ETblException.Create(02094,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;

    // arg1 
    arg1 := ParseCharacterValueExpression;

    // ')'
    if Token.TokenType <> tktRightParenthesis then
     raise ETblException.Create(02095,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;

    if arg1 = nil then
      raise ETblException.Create(02096,
        [GetOperatorName(op), Token.Text, Token.LineNum, Token.ColumnNum], nil);
    Result := TETblExprNodeStringFunction.Create(op, arg1);
   end
  else
  // Functions with 2 agruments
  if op = doTOSTRING then
   begin
    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ETblException.Create(02147,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;

    //TOSTRING(str, format)
    // string
    arg1 := ParseValueExpression;
    if arg1 = nil then
     raise ETblException.Create(02148,
              [GetOperatorName(op), Token.LineNum, Token.ColumnNum], nil);
    // ','
    if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwFrom) then
     begin
      arg1.Free;
      raise ETblException.Create(02149,
              [',', Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;
    // get next token
    GetNextToken;

    // format
    if Token.TokenType <> tktQuotedString then
     begin
      arg1.Free;
      raise ETblException.Create(02144,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;

    Result := TETblExprNodeDateFunction.Create(doTOSTRING, arg1, Token.Text);

    // get next token
    GetNextToken;

    // ')'
    if Token.TokenType <> tktRightParenthesis then
     raise ETblException.Create(02131,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;
   end
  else
  // Functions with 3 agruments
  if op = doSUBSTRING then
   begin
    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ETblException.Create(02126,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;

    //SUBSTRING(str from|, startindex [for|, length])
    // string
    arg1 := ParseCharacterValueExpression;
    if arg1 = nil then
     raise ETblException.Create(02127,
              [GetOperatorName(op), Token.LineNum, Token.ColumnNum], nil);
    // ','
    if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwFrom) then
     begin
      arg1.Free;
      raise ETblException.Create(02128,
              [','' or ''from', Token.LineNum, Token.ColumnNum], nil);
     end;
    // get next token
    GetNextToken;

    // StartIndex
    arg2 := ParseNumericValueExpression;
    if arg2 = nil then
     begin
      arg1.Free;
      raise ETblException.Create(02129,
              [GetOperatorName(op), Token.LineNum, Token.ColumnNum], nil);
     end;

    // ','
    if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwFor) and
       (Token.TokenType <> tktRightParenthesis) then
     begin
      arg1.Free;
      arg2.Free;
      raise ETblException.Create(02130,
              [')'' or '','' or ''FOR', Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;
    // lenghth
    if Token.TokenType = tktRightParenthesis then
     arg3 := nil
    else
     begin
      // get next token
      GetNextToken;
      arg3 := ParseNumericValueExpression;
     end;
     
    // ')'
    if Token.TokenType <> tktRightParenthesis then
     raise ETblException.Create(02131,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;
    if arg3 = nil then
      Result := TETblExprNodeStringFunction.Create(op, arg1,arg2)
    else
    Result := TETblExprNodeStringFunction.Create(op, arg1,arg2,arg3);
   end;
end;//ParseCharacterValueFunction


////////////////////////////////////////////////////////////////////////////////
//
// TETblExprNodeAggregated
//
////////////////////////////////////////////////////////////////////////////////


constructor TETblExprNodeAggregated.Create(Op: TETblDataOperator);
begin
  inherited Create(op);
  InitDataValue(AvgSum);
  distinct := false;
  count := 0;
  FTempTable := nil;
end;

constructor TETblExprNodeAggregated.Create(Op: TETblDataOperator;
  distinct: boolean; Node: TETblExprNode);
begin
  inherited Create(op);
  InitDataValue(AvgSum);
  self.distinct := distinct;
  Children.Add(Node);
  count := 0;
  FTempTable := nil;
end;


destructor TETblExprNodeAggregated.Destroy;
begin
  FinalizeDataValue(AvgSum);
  if (FTempTable <> nil) then
   begin
    FTempTable.Close;
    TEasyTable(FTempTable).DeleteTable;
    FTempTable.Free;
   end;
  inherited;
end;


//------------------------------------------------------------------------------
// return Data value (result)
//------------------------------------------------------------------------------
function TETblExprNodeAggregated.getDataValue(
  DataSet: TDataSet = nil): TETblDataValue;
var
  value: TETblDataValue;
begin
  if ((Operator = doCOUNT) or (Operator = doCOUNTALL)) then
    SetDataValueAsInteger(Data, count)
  else
  if (Operator = doAVG) then
   begin
    InitDataValue(value);
    // 1-st argument
    SetDataValueAsInteger(value, count);
    // 2-nd argument
    CopyDataValue(AvgSum, Data);
    // DIV
    DivDataValues(Data, value);
    FinalizeDataValue(value);
   end;
  Result := Data;
end; // getDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TETblExprNodeAggregated.getDataType: TFieldType;
var
  dt: TFieldType;
begin
  Result := ftUnknown;
  case Operator of
    doCOUNTALL,
    doCOUNT:
      Result := ftInteger;
    doMIN,
    doMAX:
      if (Children.Count <> 0) then
             Result := TETblExprNode(Children[0]).getDataType;
    doSUM:
      if (Children.Count <> 0) then
       begin
        dt := TETblExprNode(Children[0]).getDataType;
        if (dt = ftFloat) then
          Result := ftFloat
        else
        if (dt = ftCurrency) then
          Result := ftCurrency
        else
          Result := ftLargeint;
       end;
    doAVG:
     begin
      Result := TETblExprNode(Children[0]).getDataType;
     end;
  end;
end;//getDataType


//------------------------------------------------------------------------------
// Init for aggregated functions
//------------------------------------------------------------------------------
procedure TETblExprNodeAggregated.Init;
var FieldDef: TFieldDef;
begin
  count := 0;
  FinalizeDataValue(Data);
  if (Operator = doAVG) then
    FinalizeDataValue(AvgSum);
  if Operator = doSUM then
   Data.DataType := GetDataType;
  if (distinct) then
   begin
    if (Children.Count <= 0) then
     raise ETblException.Create(00076,nil);
    FTempTable := TEasyTable.Create(nil);
    TEasyTable(FTempTable).InMemory := True;
    repeat
      TEasyTable(FTempTable).TableName := GetTemporaryName('TEMP_TABLE_');
    until (not TEasyTable(FTempTable).Exists);
    TEasyTable(FTempTable).FieldDefs.Clear;
    TEasyTable(FTempTable).IndexDefs.Clear;
    FieldDef := TEasyTable(FTempTable).FieldDefs.AddFieldDef;
    FieldDef.Name := 'Expr';
    FieldDef.DataType := TETblExprNode(Children[0]).GetDataType;
    FieldDef.Size := TETblExprNode(Children[0]).GetDataSize;
    TEasyTable(FTempTable).IndexDefs.Add('Index',FieldDef.Name,[]);
    TEasyTable(FTempTable).CreateTable;
    TEasyTable(FTempTable).IndexName := 'Index';
    TEasyTable(FTempTable).Open;
   end;
end;//Init


//------------------------------------------------------------------------------
// Accumulate
//------------------------------------------------------------------------------
procedure TETblExprNodeAggregated.Accumulate;
var
  TmpVal: TETblDataValue;

  function IsDistinctHaveNewValue: Boolean;
  begin
    if (TEasyTable(FTempTable).RecordCount = 0) then
     Result := True
    else
     begin
      TEasyTable(FTempTable).SetKey;
      TEasyTable(FTempTable).SetFieldValue(TmpVal,0);
      Result := (not TEasyTable(FTempTable).GotoKey);
     end;
  end; // IsDistinctHaveNewValue

  procedure InsertNewDistinctValue;
  begin
    TEasyTable(FTempTable).Insert;
    TEasyTable(FTempTable).SetFieldValue(TmpVal,0);
    TEasyTable(FTempTable).Post;
  end; // InsertNewDistinctValue

begin
  if Children.Count <> 0 then
    TmpVal := TETblExprNode(Children[0]).getDataValue;
  case Operator of
    doMIN:
      begin
       if Data.IsNull then
        CopyDataValue(TmpVal, Data)
       else
       if not TmpVal.IsNull then
        if CompareDataValues(TmpVal, Data) = ecrLower then
         CopyDataValue(TmpVal, Data);
      end;
    doMAX:
      begin
        if Data.IsNull then
          CopyDataValue(TmpVal, Data)
        else
        if not TmpVal.IsNull then
         if CompareDataValues(TmpVal, Data) = ecrGreater then
          CopyDataValue(TmpVal, Data);
      end;
    doCOUNTALL:
      begin
        Inc(count);
      end;
    doCOUNT:
      begin
        if (not TmpVal.IsNull) then
         begin
          if (distinct) then
           begin
            if (IsDistinctHaveNewValue) then
             begin
              InsertNewDistinctValue;
              Inc(count);
             end;
           end
          else
            Inc(count);
         end;
      end;
    doSUM:
      begin
        // If not numeric type (string for example) - raise
        if (not TmpVal.IsNull) then
         if (not IsNumericDataType(TmpVal.DataType)) then
          raise ETblException.Create(02109,['sum'],nil);
        // if value not null
        if (not TmpVal.IsNull) then
          if (distinct) then
           begin
            if (IsDistinctHaveNewValue) then
             begin
              InsertNewDistinctValue;
              if not TmpVal.IsNull then
                AddDataValues(Data, TmpVal, true);
             end;
           end
          else
           begin
             if not TmpVal.IsNull then
               AddDataValues(Data, TmpVal, true);
           end;
      end;
    doAVG:
      begin
        // If not numeric type (string for example) - raise
        if (not TmpVal.IsNull) then
         if (not IsNumericDataType(TmpVal.DataType)) then
          raise ETblException.Create(02109,['avg'],nil);
        // if value not null
        if (not TmpVal.IsNull) then
          if (distinct) then
           begin
            if (IsDistinctHaveNewValue) then
             begin
              InsertNewDistinctValue;
              AddDataValues(AvgSum, TmpVal, true);
              inc(count);
             end;
           end
          else
           begin
            AddDataValues(AvgSum, TmpVal, true);
            inc(count);
           end;
      end;
  end;
end; // Accumulate


//------------------------------------------------------------------------------
// is expression contains aggregated function
//------------------------------------------------------------------------------
function TETblExprNodeAggregated.isAggregated: boolean;
begin
  Result := True;
end;//isAggregated


//------------------------------------------------------------------------------
// return Nodes Hierarchy as String
//------------------------------------------------------------------------------
function TETblExprNodeAggregated.TestTree(Indent: Integer):AnsiString;
var
  i: Integer;
begin
  Result := StringOfChar(TestIndentString, Indent*2) + '(' +
            GetOperatorName(Operator) + ') ' +
            '  <group function>'#13#10;
  for i:=0 to Children.Count-1 do
   begin
     Result := Result + TETblExprNode(Children[i]).TestTree(Indent+1);
   end;

end;//TestTree


//------------------------------------------------------------------------------
// parses <set function specification>
//------------------------------------------------------------------------------
function TETblExpression.ParseSetFunctionSpecification: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<set function specification> ::=
      COUNT <left paren> <asterisk> <right paren>
    | <general set function>
}
 Result := nil;
 SaveState(SavedTokenNo);
 if IsReservedWord(Token, rwCOUNT) then
  begin
   // get next token
   GetNextToken;
   // '('
   if Token.TokenType = tktLeftParenthesis then
    begin
     // get next token
     GetNextToken;
     // '*'
     if Token.Text='*' then
      begin
       // get next token
       GetNextToken;
       // ')'
       if Token.TokenType <> tktRightParenthesis then
       raise ETblException.Create(02103,
               [Token.Text, Token.LineNum, Token.ColumnNum], nil);
       // get next token
       GetNextToken;
       Result := TETblExprNodeAggregated.Create(doCOUNTALL);
      end;
    end;
  end;
 if Result = nil then
  begin
   RestoreState(SavedTokenNo);
   Result := ParseGeneralSetFunction;
  end;
 if Result = nil then
  begin
   RestoreState(SavedTokenNo);
   Result := ParseMathFunction;
  end;
end;//ParseSetFunctionSpecification


//------------------------------------------------------------------------------
// parses <general set function>
//------------------------------------------------------------------------------
function TETblExpression.ParseGeneralSetFunction: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
  expr: TETblExprNode;
  distinct: boolean;
  oper: TETblDataOperator;
begin
{
<general set function> ::=
      <set function type>
          <left paren> [ <set quantifier> ] <value expression> <right paren>
}
 Result := nil;
 SaveState(SavedTokenNo);

 oper := doUNDEFINED;
 if AnsiCompareText(Token.Text,'COUNT') = 0 then
  oper:=doCOUNT
 else if AnsiCompareText(Token.Text,'AVG') = 0 then
  oper:=doAVG
 else if AnsiCompareText(Token.Text,'MAX') = 0 then
  oper:=doMAX
 else if AnsiCompareText(Token.Text,'MIN') = 0 then
  oper:=doMIN
 else if AnsiCompareText(Token.Text,'SUM') = 0 then
  oper:=doSUM;

 if oper = doUNDEFINED then Exit;

 // get next token
 GetNextToken;

 // DISTINCT
 distinct := IsReservedWord(Token, rwDISTINCT);
 if distinct then
  GetNextToken;

 // '('
 if Token.TokenType <> tktLeftParenthesis then
   raise ETblException.Create(02104,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
 // get next token
 GetNextToken;

 if (IsReservedWord(Token, rwDISTINCT)) then
  begin
   distinct := True;
   GetNextToken;
  end;

 // EXPRESSION
 expr := ParseValueExpression;
 if expr = nil then
   raise ETblException.Create(02105,
            [GetOperatorName(oper), Token.LineNum, Token.ColumnNum], nil);

 // ')'
 if Token.TokenType <> tktRightParenthesis then
  begin
   expr.Free;
    raise ETblException.Create(02106,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
  end;
 // get next token
 GetNextToken;

 // Return GroupFunctionNode
 Result := TETblExprNodeAggregated.Create(oper, distinct, expr);
end;//ParseGeneralSetFunction


//------------------------------------------------------------------------------
// Init for group function
//------------------------------------------------------------------------------
procedure TETblExprNode.Init;
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
   TETblExprNode(Children[i]).Init;
end;//Init


//------------------------------------------------------------------------------
// Accumulate for group functions
//------------------------------------------------------------------------------
procedure TETblExprNode.Accumulate;
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
   TETblExprNode(Children[i]).Accumulate;
end;//Accumulate


//------------------------------------------------------------------------------
// is expression contains aggregated function
//------------------------------------------------------------------------------
function TETblExpression.isAggregated: boolean;
begin
  if FRootNode <> nil then
    Result := FRootNode.isAggregated
  else
    Result := false; 
end;//isAggregated


//------------------------------------------------------------------------------
// is expression a constant
//------------------------------------------------------------------------------
function TETblExpression.isConstant: boolean;
begin
 if FRootNode <> nil then
   Result := FRootNode.isConstant
 else
   Result := false;
end;//isConstant


//------------------------------------------------------------------------------
// is expression a Field (for join)
//------------------------------------------------------------------------------
function TETblExpression.isField: boolean;
begin
  Result := False;
  if FRootNode <> nil then
    Result := FRootNode is TETblExprNodeField;
end;//isField


//------------------------------------------------------------------------------
// is expression contains aggregated function
//------------------------------------------------------------------------------
function TETblExprNode.isAggregated: boolean;
var
  i: Integer;
begin
  Result := False;
  for i:=0 to Children.Count-1 do
   begin
    if Children[i] = nil then continue;
    Result := TETblExprNode(Children[i]).isAggregated;
    if Result then Break;
   end;
end;//isAggregated


////////////////////////////////////////////////////////////////////////////////
//
//  TETblExpression
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// is expression node a constant
//------------------------------------------------------------------------------
function TETblExprNode.isConstant: boolean;
var
  i: Integer;
begin
  Result := true;
  for i:=0 to Children.Count-1 do
   begin
    Result := TETblExprNode(Children[i]).isConstant;
    if not Result then Break;
   end;
end;//isConstant


//------------------------------------------------------------------------------
// Field Name, Table Name
//------------------------------------------------------------------------------
procedure TETblExpression.GetFieldInfo(var TableName: AnsiString; var FieldName: AnsiString);
begin
  if (IsField) then
   begin
    TableName := TETblExprNodeField(FRootNode).TableName;
    FieldName := TETblExprNodeField(FRootNode).FieldName;
   end
  else
   raise ETblException.Create(01062, nil);
end;// GetFieldInfo


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TETblExprNode.getDataType: TFieldType;
var
  i: integer;
begin
  // default ftUnknown - Error flag
  Result := ftUnknown;
  if Children.Count <> 0 then
   begin
    // Take first type
    Result := TETblExprNode(Children[0]).getDataType;
    // and compare it with other
    for i:=1 to Children.Count-1 do
     Result := getCommonDataType(Result,
                           TETblExprNode(Children[i]).getDataType);
   end;
end;//getDataType


function TETblExprNode.getDataSize: Integer;
var
  i: integer;
  ftype: TFieldType;
  child: TETblExprNode;
begin
  Result := 0;
  ftype := getDataType;
  if ftype in [ftString, ftWideString, ftBytes] then
   begin
    if Operator in [doADD, doCONCAT, doCAST, doMIN, doMAX] then
     for i:=0 to Children.Count-1 do
      begin
       child := TETblExprNode(Children[i]);
       case child.getDataType of
         ftString,
         ftBytes,
         ftWideString:
           Result := Result + child.getDataSize;
         ftAutoInc,
         ftInteger:
           Result := Result + 11;
         ftSmallInt:
           Result := Result + 6;
         ftWord:
           Result := Result + 5;
         ftLargeInt:
           Result := Result + 20;
         ftFloat,
         ftDate,
         ftTime,
         ftDateTime:
           Result := Result + 26;
         ftBoolean:
           Result := Result + 5;
         ftCurrency:
           Result := Result + 21;
       end;
      end;
   end;
  if ftype = ftWideString then
    Result := Result * 2;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TEtblExprNode
//
////////////////////////////////////////////////////////////////////////////////


constructor TETblExprNode.Create;
begin
  Children := TList.Create;
  Operator := doUNDEFINED;
  InitDataValue(Data);
  TestIndentString := ' ';
end;


constructor TETblExprNode.Create(Op: TETblDataOperator);
begin
  Children := TList.Create;
  Operator := doUNDEFINED;
  InitDataValue(Data);
  TestIndentString := ' ';
  Operator := Op;
end;

constructor TETblExprNode.Create(Op: TETblDataOperator;
  Node: TETblExprNode);
begin
  Children := TList.Create;
  Operator := doUNDEFINED;
  InitDataValue(Data);
  TestIndentString := ' ';
  Operator := Op;
  Children.Add(Node);
end;

constructor TETblExprNode.Create(Op: TETblDataOperator;
  Node1, Node2: TETblExprNode);
begin
  Children := TList.Create;
  Operator := doUNDEFINED;
  InitDataValue(Data);
  TestIndentString := ' ';
  Operator := Op;
  Children.Add(Node1);
  Children.Add(Node2);
end;

constructor TETblExprNode.Create(Op: TETblDataOperator;
  Node1, Node2, Node3: TETblExprNode);
begin
  Children := TList.Create;
  Operator := doUNDEFINED;
  InitDataValue(Data);
  TestIndentString := ' ';
  Operator := Op;
  Children.Add(Node1);
  Children.Add(Node2);
  Children.Add(Node3);
end;


{ TETblExprNodeComparison }

function TETblExprNodeComparison.GetDataValue(DataSet: TDataSet = nil): TETblDataValue;
var
  cmpRes: TETblCompareResult;
  arg1, arg2: TETblDataValue;
begin
  InitDataValue(arg1);
  InitDataValue(arg2);
  CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet), arg1);
  CopyDataValue(TETblExprNode(Children[1]).GetDataValue(DataSet), arg2);
  cmpRes := CompareDataValues(arg1,arg2);
  if cmpRes in [ecrLeftNull,ecrRightNull,ecrBothNull] then
   begin
    FinalizeDataValue(Data);
    Data.DataType := ftBoolean;
   end
  else
  case Operator of
   doEQ:   SetDataValueAsBoolean(Data, cmpRes = ecrEqual);
   doNE:   SetDataValueAsBoolean(Data, cmpRes <> ecrEqual);
   doLT:   SetDataValueAsBoolean(Data, cmpRes = ecrLower);
   doGT:   SetDataValueAsBoolean(Data, cmpRes = ecrGreater);
   doLE:   SetDataValueAsBoolean(Data, cmpRes in [ecrEqual,ecrLower]);
   doGE:   SetDataValueAsBoolean(Data, cmpRes in [ecrEqual,ecrGreater]);
   else
     raise Exception.Create('Unknown Operator');
  end;
  FinalizeDataValue(arg1);
  FinalizeDataValue(arg2);
  Result := Data;
end;//GetDataValue

function TETblExprNode.CanBeAssigned(AO: TEasyAO): Boolean;
var
  i: Integer;
begin
  Result := True;
  // get childs cans
  for i:=0 to Children.Count-1 do
    begin
      Result := Result and TETblExprNode(Children[i]).CanBeAssigned(AO);
      if not Result then break;
    end;
end;


//------------------------------------------------------------------------------
// makes filter string for specified AO
//------------------------------------------------------------------------------
function TETblExprNode.GetFilter(AO: TEasyAO): AnsiString;
var
 i: integer;
begin
  Result := '';
  for i:=0 to Children.Count-1 do
   Result := Result + ' ' + TETblExprNode(Children[i]).GetFilter(AO);
end;


function TETblExprNodeComparison.IsJoinCondition(AO1,
  AO2: TEasyAO): Boolean;
var
  Left, Right: TETblExprNodeField;
  FieldNumber: TaaIntArray;
  Field1LeftCount, Field1RightCount: integer;
  Field2LeftCount, Field2RightCount: integer;
begin
  Result := false;
  if not ((TETblExprNode(Children[0]) is TETblExprNodeField) and
          (TETblExprNode(Children[1]) is TETblExprNodeField)) then Exit;
    
  Left := TETblExprNodeField(Children[0]);
  Right := TETblExprNodeField(Children[1]);
  if Operator = doEQ then
   if ((Left is TETblExprNodeField) and
       (Right is TETblExprNodeField)) then
    begin
     FieldNumber := TaaIntArray.Create;
     try
      // map fields
      FieldNumber.SetSize(0);
      Field1LeftCount := AO1.FieldExists(Left.FieldName, Left.TableName, True, FieldNumber);
      FieldNumber.SetSize(0);
      Field2LeftCount := AO1.FieldExists(Right.FieldName, Right.TableName, True, FieldNumber);
      FieldNumber.SetSize(0);
      Field1RightCount := AO2.FieldExists(Left.FieldName, Left.TableName, True, FieldNumber);
      FieldNumber.SetSize(0);
      Field2RightCount := AO2.FieldExists(Right.FieldName, Right.TableName, True, FieldNumber);
      // ambiguous field reference?
      if (Field1LeftCount+Field1RightCount > 1) then
        raise ETblException.Create(01054, [Left.FieldName], nil);
      if (Field2LeftCount+Field2RightCount > 1) then
        raise ETblException.Create(01055, [Right.FieldName], nil);
      // each field macths only 1 AO?
      if ((Field1LeftCount+Field1RightCount = 1) and
          (Field2LeftCount+Field2RightCount = 1)) then
       // boths fields match different AO?
       if (Field1LeftCount <> Field2LeftCount) then
        Result := True;
     finally
      FieldNumber.Free;
     end;
    end;
end;

{ TETblExprNodeBoolean }

//------------------------------------------------------------------------------
// process IN (...)
//------------------------------------------------------------------------------
procedure TETblExprNodeBoolean.bIn(DataSet: TDataSet);
var
  i: integer;
  val1,val2: TETblDataValue;
begin
 if TETblExprNode(Children[0]).GetDataValue(DataSet).IsNull then
  begin
   FinalizeDataValue(Data);
   Data.DataType := ftBoolean;
  end
 else
  begin
   // set result = false
   SetDataValueAsBoolean(Data, false);
   // init vars
   InitDataValue(val1);
   InitDataValue(val2);
   CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet),val1);
   for i:= 1 to Children.Count-1 do
    begin
     CopyDataValue(TETblExprNode(Children[i]).GetDataValue(DataSet),val2);
     // arg2 = NULL
     if val2.IsNull then
      begin
       FinalizeDataValue(Data);
       Data.DataType := ftBoolean;
      end
     else
     // arg2 = arg1
     if CompareDataValues(val1, val2) = ecrEqual then
      begin
       SetDataValueAsBoolean(Data, true);
       break;
      end;
    end;
   FinalizeDataValue(val1);
   FinalizeDataValue(val2);
  end;
end;//bIn


//------------------------------------------------------------------------------
// process a BETWEEN b AND c
//------------------------------------------------------------------------------
procedure TETblExprNodeBoolean.Between(DataSet: TDataSet);
var
  value,valMin,valMax: TETblDataValue;
  bExit: Boolean;
begin
 if TETblExprNode(Children[0]).GetDataValue(DataSet).IsNull then
  begin
   FinalizeDataValue(Data);
   Data.DataType := ftBoolean;
  end
 else
  begin
   // set result = true
   SetDataValueAsBoolean(Data, true);
   // init vars
   InitDataValue(value);
   InitDataValue(valMin);
   InitDataValue(valMax);
   // Set data
   CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet),value);
   CopyDataValue(TETblExprNode(Children[1]).GetDataValue(DataSet),valMin);
   CopyDataValue(TETblExprNode(Children[2]).GetDataValue(DataSet),valMax);
   bExit := false;
   // value >= valMin ?
   if not valMin.IsNull then
    if not (CompareDataValues(value,valMin) in [ecrEqual,ecrGreater]) then
     begin
      SetDataValueAsBoolean(Data, false);
      bExit := true;
     end;
   // value <= valMax ?
   if not valMax.IsNull then
    if not (CompareDataValues(value,valMax) in [ecrEqual,ecrLower]) then
     begin
      SetDataValueAsBoolean(Data, false);
      bExit := true;
     end;
   if (valMin.IsNull or valMax.IsNull) and not bExit then
    begin
     FinalizeDataValue(Data);
     Data.DataType := ftBoolean;
    end;
   FinalizeDataValue(value);
   FinalizeDataValue(valMin);
   FinalizeDataValue(valMax);
  end;
end;//Between


//------------------------------------------------------------------------------
// get data value
//------------------------------------------------------------------------------
function TETblExprNodeBoolean.GetDataValue(
  DataSet: TDataSet = nil): TETblDataValue;
var
  i: integer;
  ChildData: TETblDataValue;
begin
  InitDataValue(ChildData);
  case Operator of
   doNOT: // NOT
     begin
       // get first chidl
       CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet),ChildData);
       // NOT <null> = NULL
       if ChildData.IsNull then
         FinalizeDataValue(Data)
       else
        begin
         // cast to boolean, if need
       if ChildData.DataType <> ftBoolean then
        Cast(ChildData, ftBoolean);
       SetDataValueAsBoolean(Data, not GetDataValueAsBoolean(ChildData));
     end;
     end;
   doAND: // AND
     begin
       // possible result is TRUE
       SetDataValueAsBoolean(Data, true);
       // Loop for all childs
       for i:=0 to Children.Count-1 do
        begin
         CopyDataValue(TETblExprNode(Children[i]).GetDataValue(DataSet),ChildData);
         // x AND NULL = NULL
         if ChildData.IsNull then
          begin
           FinalizeDataValue(Data);
           Data.DataType := ftBoolean;
           break;
          end;
         // cast to boolean, if need
         if ChildData.DataType <> ftBoolean then
           Cast(ChildData, ftBoolean);
         // x AND FALSE = FALSE
         if not GetDataValueAsBoolean(ChildData) then
          begin
           SetDataValueAsBoolean(Data, false);
           break;
          end;
        end;
     end;
   doOR: // OR
     begin
       // possible result is FALSE
       SetDataValueAsBoolean(Data, false);
       // Loop for all childs
       for i:=0 to Children.Count-1 do
        begin
         CopyDataValue(TETblExprNode(Children[i]).GetDataValue(DataSet),ChildData);
         // False OR NULL = NULL (and check later)
         if ChildData.IsNull then
          begin
           FinalizeDataValue(Data);
           Data.DataType := ftBoolean;
           continue;
          end;
         // cast to boolean, if need
         if ChildData.DataType <> ftBoolean then
           Cast(ChildData, ftBoolean);
         // x OR TRUE=TRUE;
         if GetDataValueAsBoolean(ChildData) then
          begin
           SetDataValueAsBoolean(Data, true);
           break;
          end;
        end;
     end;
   doISNULL:  // IS NULL
     begin
       SetDataValueAsBoolean(Data,
          TETblExprNode(Children[0]).GetDataValue(DataSet).IsNull);
     end;
   doISNOTNULL: // IS NOT NULL
     begin
       SetDataValueAsBoolean(Data,
          not TETblExprNode(Children[0]).GetDataValue(DataSet).IsNull);
     end;
   doLIKE:
     begin
       Like(DataSet);
     end;
   doNOTLIKE:
     begin
       Like(DataSet);
       if not Data.IsNull then
        SetDataValueAsBoolean(Data, not GetDataValueAsBoolean(Data));
     end;
   doIN:
     begin
       bIn(DataSet);
     end;
   doNOTIN:
     begin
       bIn(DataSet);
       if not Data.IsNull then
        SetDataValueAsBoolean(Data, not GetDataValueAsBoolean(Data));
     end;
   doBETWEEN:
     begin
       Between(DataSet);
     end;
   doNOTBETWEEN:
     begin
       Between(DataSet);
       if not Data.IsNull then
        SetDataValueAsBoolean(Data, not GetDataValueAsBoolean(Data));
     end;
   else
     raise Exception.Create('Unknown Operator');
  end;
  FinalizeDataValue(ChildData);
  Result := Data;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TETblExprNodeBoolean.GetDataType: TFieldType;
begin
 Result := ftBoolean;
end; // GetDataType


////////////////////////////////////////////////////////////////////////////////
//
// TETblExprNodeIsNullFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create with replacement
//------------------------------------------------------------------------------
constructor TETblExprNodeIsNullFunction.Create(Op: TETblDataOperator;
  Node1, Node2: TETblExprNode);
begin
  inherited Create(op,Node1,Node2);
  FType1 := ftUnknown;
  FType2 := ftUnknown;
end;


//------------------------------------------------------------------------------
// get data value
//------------------------------------------------------------------------------
function TETblExprNodeIsNullFunction.GetDataValue(
  DataSet: TDataSet = nil): TETblDataValue;
begin
  if (Children.Count = 1) then
   begin
    // IsNull without replacement - returns true/false
    SetDataValueAsBoolean(Data,
          TETblExprNode(Children[0]).GetDataValue(DataSet).IsNull);
   end
  else
   if (Children.Count = 2) then
    begin
     // IsNull with replacement
     CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet),Data);
     if (Data.IsNull) then
      begin
       if (FType1 = ftUnknown) then
        FType1 := TETblExprNode(Children[0]).GetDataType;
       if (FType2 = ftUnknown) then
        FType2 := TETblExprNode(Children[1]).GetDataType;
       if (FType1 <> FType2) then
        raise ETblException.Create(00068,
          [GetOperatorName(doISNULLFUNCTION),Integer(FType1),Integer(FType2)],nil);
       CopyDataValue(TETblExprNode(Children[1]).GetDataValue(DataSet),Data);
      end;
    end;
 Result := Data;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TETblExprNodeIsNullFunction.GetDataSize: Integer;
var size: Integer;
begin
  Result := 0;
  if (Children.Count = 2) then
    begin
     // IsNull with replacement
     Result := TETblExprNode(Children[0]).GetDataSize;
     Size := TETblExprNode(Children[1]).GetDataSize;
     if (Size > Result) then
      Result := Size;
    end;
end; // GetDataSize


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TETblExprNodeIsNullFunction.GetDataType: TFieldType;
begin
  Result := ftUnknown;
  if (Children.Count = 1) then
   begin
    // IsNull without replacement - returns true/false
    Result := ftBoolean;
   end
  else
   if (Children.Count = 2) then
    begin
     // IsNull with replacement
     Result := inherited GetDataType;
    end;
end; // GetDataType


//------------------------------------------------------------------------------
// process assign AO
//------------------------------------------------------------------------------
procedure TETblExpression.AssignAO(AO: TEasyAO);
begin
  FRootNode.AssignAO(AO);
end;//AssignAO


//------------------------------------------------------------------------------
// assign AO
//------------------------------------------------------------------------------
procedure TETblExprNode.AssignAO(AO: TEasyAO);
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
   TETblExprNode(Children[i]).AssignAO(AO);
end;//AssignAO

procedure TETblExprNodeBoolean.Like(DataSet: TDataSet);
var
  Pattern: TETblDataValue;
  CommonType: TFieldType;
begin
  InitDataValue(Pattern);
  // Get 1-st string
  CopyDataValue(TETblExprNode(Children[0]).getDataValue(DataSet), Data);
  // Get 2-st pattern
  CopyDataValue(TETblExprNode(Children[1]).getDataValue(DataSet), Pattern);
  // get Common Data Type
  CommonType := getCommonDataType(Data.DataType, Pattern.DataType);
  // check for strings
  if CommonType in [ftString, ftWideString] then
   else raise ETblException.Create(02114,['LIKE'],nil);
  // cast to CommonType
  if Data.DataType <> CommonType then cast(Data, CommonType);
  if Pattern.DataType <> CommonType then cast(Pattern, CommonType);
  // do Like
  case CommonType of
   ftString:
     SetDataValueAsBoolean(Data, IsStrMatchPattern(
       PAnsiChar(GetDataValueAsString(Data)),
       PAnsiChar(GetDataValueAsString(Pattern)),false));
   ftWideString:
     SetDataValueAsBoolean(Data, IsWideStrMatchPattern(
       PWideChar(GetDataValueAsWideString(Data)),
       PWideChar(GetDataValueAsWideString(Pattern)),false));
  end;
  FinalizeDataValue(Pattern);
end;//Like


//------------------------------------------------------------------------------
// parses <in predicate>
//------------------------------------------------------------------------------
function TETblExpression.ParseInPredicate: TETblExprNode;
var
  bNot:         boolean;
  arg1:         TETblExprNode;
  SavedTokenNo: Integer;
begin
{
<in predicate> ::=
    <row value constructor>
      [ NOT ] IN <in predicate value>
}
  Result := nil;
  arg1 := ParseRowValueConstructor;
  if arg1 <> nil then
   begin
    // [NOT]
    if (IsReservedWord(Token, rwNOT)) then
     begin
      bNot := True;
      // and Get next token
      GetNextToken;
     end
    else
     bNot := False;

    // IN
    if (IsReservedWord(Token, rwIN)) then
     begin
      // get next token
      GetNextToken;

      SaveState(SavedTokenNo);
      // IN (SELECT ...)
      Result := ParseSubQuery(False,True,bNot,arg1);
      // '(' ?
      if (Result = nil) then
       begin
        RestoreState(SavedTokenNo);
        if (Token.TokenType = tktLeftParenthesis) then
         begin
          // get next token
          GetNextToken;
          if bNot then
            Result := TETblExprNodeBoolean.Create(doNOTIN, arg1)
          else
            Result := TETblExprNodeBoolean.Create(doIN, arg1);
          repeat
           arg1 := ParseValueExpression;
           // if error
           if arg1 = nil then
            begin
             Result.Free;
             Result := nil;
            end;
           // add argument to IN node
           Result.Children.add(arg1);
           arg1 := nil;
           // ',' ?
           if Token.TokenType = tktComma then
            // get next token
            GetNextToken
           else
           // ')'
           if Token.TokenType = tktRightParenthesis then
            break;
          until false;
          // get next token
          GetNextToken
         end;
       end; // IN (list of constants)
     end;
    if (Result = nil) and (arg1 <> nil) then
     begin
      arg1.Free;
     end;
   end;
end;//ParseInPredicate


//------------------------------------------------------------------------------
// parses <Exists predicate>
//------------------------------------------------------------------------------
function TETblExpression.ParseExistsPredicate: TETblExprNode;
var
  bNot: boolean;
begin
{
<Exists predicate> ::=
      [ NOT ] EXISTS (<subquery>)
}
  Result := nil;
  // [NOT]
  if (IsReservedWord(Token, rwNOT)) then
   begin
    bNot := True;
    // and Get next token
    GetNextToken;
   end
  else
   bNot := False;
  if (IsReservedWord(Token, rwEXISTS)) then
   begin
    if (GetNextToken) then
      Result := ParseSubQuery(True,False,bNot);
   end;
end; // ParseExistsPredicate


//------------------------------------------------------------------------------
// parses <between predicate>
//------------------------------------------------------------------------------
function TETblExpression.ParseBetweenPredicate: TETblExprNode;
var
  arg1, arg2, arg3: TETblExprNode;
  bNot: boolean;
begin
{
<between predicate> ::=
    <row value constructor> [ NOT ] BETWEEN
      <row value constructor> AND <row value constructor>
}
 Result := nil;
 arg2:=nil; arg3:=nil;
 arg1 := ParseRowValueConstructor;
 if arg1 <> nil then
  begin
   // [NOT]
   if (IsReservedWord(Token, rwNOT)) then
    begin
     bNot := True;
     // and Get next token
     GetNextToken;
    end
   else
    bNot := False;
   // BETWEEN
   if (IsReservedWord(Token, rwBETWEEN)) then
    begin
     // get next token
     GetNextToken;
     arg2 := ParseRowValueConstructor;
     if arg2 <> nil then
      begin
       // AND
       if (IsReservedWord(Token, rwAND)) then
        begin
         // get next token
         GetNextToken;
         arg3 := ParseRowValueConstructor;
         if arg3 <> nil then
          if bNot then
           Result := TETblExprNodeBoolean.Create(doNOTBETWEEN, arg1, arg2, arg3)
          else
           Result := TETblExprNodeBoolean.Create(doBETWEEN, arg1, arg2, arg3);
        end;
      end
    end;
  end;
 if Result = nil then
  begin
   if arg1 <> nil then arg1.Free;
   if arg2 <> nil then arg2.Free;
   if arg3 <> nil then arg3.Free;
  end;
end;//ParseBetWeenPredicate


//------------------------------------------------------------------------------
// parses <cast specification>
//------------------------------------------------------------------------------
function TETblExpression.ParseCastSpecification: TETblExprNode;
var
  Operand: TETblExprNode;
  fType: TFieldType;
begin
{
<cast specification> ::=
    CAST <left paren> <cast operand> [as | , ]
        <cast target> <right paren>
}
 //raise Exception.Create('Not supported yet');
 Result := nil;
 if IsReservedWord(Token, rwCAST) then
  begin
   // get next token
   GetNextToken;
   // '('
   if Token.TokenType = tktLeftParenthesis then
    begin
     // get next token
     GetNextToken;
     // Operand
     Operand := ParseCastOperand;
     if Operand <> nil then
      begin
       if (Token.TokenType = tktComma) or
          IsReservedWord(Token, rwAS) then
        begin
         // get next token
         GetNextToken;
         // Get Field Type
         fType := GetFieldType(Token.Text);
         // If correct fType
         if fType in [ftWord, ftSmallInt, ftInteger, ftLargeInt, ftFloat,
                      ftCurrency, ftDate, ftDateTime, ftTime, ftBoolean,
                      ftString, ftWideString] then
          begin
           // get next token
           GetNextToken;
           // ')'
           if Token.TokenType <> tktRightParenthesis then
            begin
              Operand.Free;
              raise ETblException.Create(02116,
                        [Token.Text,Token.LineNum,Token.ColumnNum], nil);
            end;
           Result := TETblExprNodeCast.Create(Operand, fType);
           // get next token
           GetNextToken;
          end
         else
          begin
           Operand.Free;
           raise ETblException.Create(02115,[GetDataTypeName(fType)],nil);
          end;
        end;
      end;
    end;
  end;
end;//ParseCastSpecification


//------------------------------------------------------------------------------
// parses <cast operand>
//------------------------------------------------------------------------------
function TETblExpression.ParseCastOperand: TETblExprNode;
begin
{
<cast operand> ::=
      <value expression>
    | NULL
}
 // NULL
 if IsReservedWord(Token, rwNULL) then
  begin
   Result := TETblExprNodeConst.Create;
   // get next token
   GetNextToken;
  end
 else
  // <value expression>
  Result := ParseValueExpression;
end;//ParseCastOperand

{ TETblExprNodeCast }


//------------------------------------------------------------------------------
// Create Node - CAST
//------------------------------------------------------------------------------
constructor TETblExprNodeCast.Create(Node: TETblExprNode;
  CastType: TFieldType);
begin
  Inherited Create;
  Operator:=doCAST;
  Children.Add(Node);
  self.CastType := CastType;
end;//Create


{
//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TETblExprNodeCast.GetDataSize: Integer;
begin

end;//GetDataSize
}

//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TETblExprNodeCast.GetDataType: TFieldType;
begin
  Result := CastType;
end;//GetDataType


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TETblExprNodeCast.GetDataValue(DataSet: TDataSet): TETblDataValue;
begin
  CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet), Data);
  Cast(Data, CastType);
  Result := Data;
end;//GetDataValue

function TETblExprNode.TestTree(Indent: Integer): AnsiString;
var
  i: Integer;
begin
  Result := StringOfChar(TestIndentString, Indent*2) + '(' +
            GetOperatorName(Operator) + ') ' +
            ClassName + #13#10;
  for i:=0 to Children.Count-1 do
   begin
     Result := Result + TETblExprNode(Children[i]).TestTree(Indent+1);
   end;
end;

procedure TETblExpression.Parse;
begin
  raise Exception.Create('This Method is not supported');
end;


function TETblExpression.ParseNumericValueFunction: TETblExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<numeric value function> ::=
      <position expression>
    | <extract expression>
    | <length expression>
    | <LastAutoInc expression>
    | <IsNull expression>
}
 // save current state
 SaveState(SavedTokenNo);
 Result := ParsePositionExpression;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseLengthExpression;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseLastAutoIncExpression;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseIsNullExpression;
  end;
end;//ParseNumericValueFunction

function TETblExpression.ParsePositionExpression: TETblExprNode;
var
  arg1, arg2: TETblExprNode;
begin
 if IsReservedWord(Token, rwPOSITION) or IsReservedWord(Token, rwPOS) then
  begin
    // get next token
    GetNextToken;

    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ETblException.Create(02132,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;

    // arg
    arg1 := ParseCharacterValueExpression;
    if arg1 = nil then
     raise ETblException.Create(02134,
              ['POS', Token.LineNum, Token.ColumnNum], nil);

    // ',' or 'in'
    if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwIN) then
     begin
       arg1.Free;
       raise ETblException.Create(02135,
                [','' or ''IN', Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;
    // get next token
    GetNextToken;

    arg2 := ParseCharacterValueExpression;
    if arg2 = nil then
     begin
      arg1.Free;
      raise ETblException.Create(02136,
              ['POS', Token.LineNum, Token.ColumnNum], nil);
     end;

    Result := TETblExprNodeStringFunction.Create(doPOS, arg1, arg2);

    // ')'
    if Token.TokenType <> tktRightParenthesis then
     begin
      Result.Free;
      raise ETblException.Create(02133,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;
    // get next token
    GetNextToken;
  end
 else
  Result := nil;
end;


//------------------------------------------------------------------------------
// parses <length expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseLengthExpression: TETblExprNode;
begin
 if IsReservedWord(Token, rwLENGTH) then
  begin
    // get next token
    GetNextToken;

    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ETblException.Create(02137,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;

    // argument
    Result := ParseStringValueExpression;
    if result = nil then
      raise ETblException.Create(02138,
              ['LENGTH', Token.LineNum, Token.ColumnNum], nil);

    Result := TETblExprNodeStringFunction.Create(doLENGTH, Result);

    // ')'
    if Token.TokenType <> tktRightParenthesis then
     begin
      Result.Free;
      raise ETblException.Create(02139,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;

    // get next token
    GetNextToken;
  end
 else
  Result := nil;
end;


//------------------------------------------------------------------------------
// parses <LastAutoInc expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseLastAutoIncExpression: TETblExprNode;
var
  TableName, Password: AnsiString;
  IntoMemory : boolean;
begin
 TableName := '';
 Password := '';
 IntoMemory := false;
 if IsReservedWord(Token, rwLAST_AUTOINC) then
  begin
    // get next token
    GetNextToken;

    // LastAutoInc
    if Token.TokenType <> tktLeftParenthesis then
      raise ETblException.Create(02155,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);

    // get next token
    GetNextToken;

    if Token.TokenType in [tktString, tktReservedWord,
                           tktQuotedString, tktBracketedString] then
     begin
      // LastAutoInc()

      // MEMORY
      if IsReservedWord(Token, rwMEMORY) then
       begin
        IntoMemory := true;
        GetNextToken([tktReservedWord,tktString,tktQuotedString,
                      tktBracketedString],02152);
       end;

      // table_name
      TableName := Token.Text;

      // get next token
      GetNextToken;

      // PASSWORD
      if IsReservedWord(Token, rwPASSWORD) then
       begin
        // get next token
        GetNextToken;
        // Password_value
        if not (Token.TokenType in [tktString, tktReservedWord,
                                    tktQuotedString, tktBracketedString]) then
         raise ETblException.Create(02153,
              [Token.text, Token.LineNum, Token.ColumnNum], nil);
        Password := Token.text;

        // get next token
        GetNextToken;
       end;
      // ')'
      if Token.TokenType <> tktRightParenthesis then
        raise ETblException.Create(02154,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;


    // get next token
    GetNextToken;
    Result := TETblExprNodeSystem.Create(TableName, Password, IntoMemory);
  end
 else
  Result := nil;
end;//ParseLastAutoIncExpression


//------------------------------------------------------------------------------
// parses <IsNull expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseIsNullExpression: TETblExprNode;
var expr,expr1: TEtblExprNode;
begin
  Result := nil;
  // ISNULL?
  if (IsReservedWord(Token, rwISNULL)) then
   begin
    expr1 := nil;
    expr := nil;
    try
      // get next token
      GetNextToken;
      if (Token.TokenType <> tktLeftParenthesis) then
        raise ETblException.Create(00069,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
      // get next token
      GetNextToken;
      // EXPRESSION
      expr := ParseValueExpression;
      if (expr = nil) then
       raise ETblException.Create(00066,
              [GetOperatorName(doISNULLFUNCTION), Token.LineNum, Token.ColumnNum], nil);
      if (Token.TokenType = tktComma) then
       begin
        // get next token
        GetNextToken;
        // replacement
        expr1 := ParseValueExpression;
       end;
      if (Token.TokenType <> tktRightParenthesis) then
        raise ETblException.Create(00067,
                [Token.Text, Token.LineNum, Token.ColumnNum], nil);
      // get next token
      GetNextToken;
      if (expr1 = nil) then
       Result := TETblExprNodeIsNullFunction.Create(doISNULLFUNCTION, expr)
      else
       Result := TETblExprNodeIsNullFunction.Create(doISNULLFUNCTION, expr, expr1);
    except
       begin
        if (expr <> nil) then
         expr.Free;
        if (expr1 <> nil) then
         expr1.Free;
        raise;
       end;
    end;
   end;
end; // ParseIsNullExpression


//------------------------------------------------------------------------------
// parses <datetime value expression>
//------------------------------------------------------------------------------
function TETblExpression.ParseDatetimeValueExpression: TETblExprNode;
var
 SavedTokenNo: integer;        // saved/restored information
begin
{
 <datetime value expression> ::=
   <datetime CURRENT_TIMESTAMP function>
   | <datetime CURRENT_TIME function>
   | <datetime CURRENT_DATE function>
   | <datetime to_date function>
}

 SaveState(SavedTokenNo);
 Result := ParseSysdateFunction;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseCurrentTimeFunction;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseCurrentDateFunction;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseToDateFunction;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseDateTimeExtractFunction;
  end;
end;//ParseDatetimeValueExpression



//------------------------------------------------------------------------------
// parse <datetime sysdate function>
//------------------------------------------------------------------------------
function TETblExpression.ParseSysdateFunction: TETblExprNode;
begin
 if IsReservedWord(Token, rwSYSDATE) or
    IsReservedWord(Token, rwNOW) or
    IsReservedWord(Token, rwCURRENT_TIMESTAMP) then
  begin
   // get next token
   GetNextToken;
   Result := TETblExprNodeDateFunction.Create(doSYSDATE);
  end
 else
  Result := nil;
end;//ParseSysdateFunction


//------------------------------------------------------------------------------
// parse <datetime CURRENT_TIME function>
//------------------------------------------------------------------------------
function TETblExpression.ParseCurrentTimeFunction: TETblExprNode;
begin
 if IsReservedWord(Token, rwCURRENT_TIME) then
  begin
   // get next token
   GetNextToken;
   Result := TETblExprNodeDateFunction.Create(doCURRENT_TIME);
  end
 else
  Result := nil;
end;//ParseCurrentTimeFunction


//------------------------------------------------------------------------------
// parse <datetime CURRENT_DATE function>
//------------------------------------------------------------------------------
function TETblExpression.ParseCurrentDateFunction: TETblExprNode;
begin
 if IsReservedWord(Token, rwCURRENT_DATE) then
  begin
   // get next token
   GetNextToken;
   Result := TETblExprNodeDateFunction.Create(doCURRENT_DATE);
  end
 else
  Result := nil;
end;//ParseCurrentDateFunction


//------------------------------------------------------------------------------
// parse <datetime TODATE function>
//------------------------------------------------------------------------------
function TETblExpression.ParseToDateFunction: TETblExprNode;
begin
{
   ToDate(string, format)
}
 if IsReservedWord(Token, rwTODATE) then
  begin
   // get next token
   GetNextToken;
   // '('
   if Token.TokenType <> tktLeftParenthesis then
     raise ETblException.Create(02142,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
   // get next token
   GetNextToken;

   // string
   Result := ParseCharacterValueExpression;
   if Result = nil then
    raise ETblException.Create(02141,
              ['ToDate', Token.LineNum, Token.ColumnNum], nil);
   // ','
   if Token.TokenType <> tktComma then
    begin
      Result.Free;
      raise ETblException.Create(02143,
               [',', Token.Text, Token.LineNum, Token.ColumnNum], nil);
    end;
   // get next token
   GetNextToken;

   // format
   if Token.TokenType <> tktQuotedString then
    begin
     Result.Free;
     raise ETblException.Create(02144,
               [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    end;

   Result := TETblExprNodeDateFunction.Create(doTODATE, Result, Token.Text);

   // get next token
   GetNextToken;

   // ')'
   if Token.TokenType <> tktRightParenthesis then
    begin
     Result.Free;
     raise ETblException.Create(02145,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    end;
   // get next token
   GetNextToken;
  end
 else
  Result := nil;
end;//ParseToDateFunction


//------------------------------------------------------------------------------
// parse <datetime extract functions>
//------------------------------------------------------------------------------
function TETblExpression.ParseDateTimeExtractFunction: TETblExprNode;
var
  arg:        TETblExprNode;
  Operator:   TETblDataOperator;
  bExtract:   Boolean;
begin
  Result := nil;
  Operator := doUNDEFINED;
  if IsReservedWord(Token, rwEXTRACT) then
   begin
    bExtract := True;
    // get next token
    GetNextToken;
    if (Token.TokenType <> tktLeftParenthesis) then
       raise ETblException.Create(00074,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
    // get next token
    GetNextToken;
   end
  else
   bExtract := False;
  if IsReservedWord(Token, rwYEAR) then Operator:=doYEAR
  else if IsReservedWord(Token, rwQUARTER) then Operator:=doQUARTER
  else if IsReservedWord(Token, rwMONTH) then Operator:=doMONTH
  else if IsReservedWord(Token, rwDAY) then Operator:=doDAY
  else if IsReservedWord(Token, rwWEEKDAY) then Operator:=doWEEKDAY
  else if IsReservedWord(Token, rwDAYOFWEEK) then Operator:=doDAYOFWEEK
  else if IsReservedWord(Token, rwDAYNAME) then Operator:=doDAYNAME
  else if IsReservedWord(Token, rwMONTHNAME) then Operator:=doMONTHNAME
  else if IsReservedWord(Token, rwHOUR) then Operator:=doHOUR
  else if IsReservedWord(Token, rwMINUTE) then Operator:=doMINUTE
  else if IsReservedWord(Token, rwSECOND) then Operator:=doSECOND
  else if IsReservedWord(Token, rwMSECOND) then Operator:=doMSECOND
  ;
  if Operator = doUNDEFINED then Exit;
  // get next token
  GetNextToken;
  if (bExtract) then
   begin
    if ((Token.TokenType <> tktComma) and (not IsReservedWord(Token, rwFROM))) then
      raise ETblException.Create(00075,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);

   end
  else
   begin
    if (Token.TokenType <> tktLeftParenthesis) then
     raise ETblException.Create(00071,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);
   end;
  // get next token
  GetNextToken;
  arg := ParseValueExpression;
  if (arg = nil) then
    raise ETblException.Create(00073,
            [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum], nil);
  if (Token.TokenType <> tktRightParenthesis) then
   begin
    arg.Free;
    raise ETblException.Create(00072,
            [Token.Text, Token.LineNum, Token.ColumnNum], nil);
   end;
   Result := TETblExprNodeDateFunction.Create(Operator,arg);
   // get next token
   GetNextToken;
end; // ParseDateTimeExtractFunction


//------------------------------------------------------------------------------
// parse <Math function>
//------------------------------------------------------------------------------
function TETblExpression.ParseMathFunction: TETblExprNode;
var
  arg,arg1:   TETblExprNode;
  Operator:   TETblDataOperator;
begin
  Result := nil;
  arg1 := nil;
  Operator := doUNDEFINED;
  if IsReservedWord(Token, rwABS) then Operator:=doABS
  else if (IsReservedWord(Token, rwCEIL) or IsReservedWord(Token, rwCEILING)) then Operator:=doCEILING
  else if IsReservedWord(Token, rwFLOOR) then Operator:=doFLOOR
  else if IsReservedWord(Token, rwMOD) then Operator:=doMOD
  else if (IsReservedWord(Token, rwPOWER) or IsReservedWord(Token, rwPOW)) then Operator:=doPOWER
  else if (IsReservedWord(Token, rwRANDOM) or IsReservedWord(Token, rwRAND)) then Operator:=doRANDOM
  else if IsReservedWord(Token, rwROUND) then Operator:=doROUND
  else if IsReservedWord(Token, rwSIGN) then Operator:=doSIGN
  else if (IsReservedWord(Token, rwTRUNC) or IsReservedWord(Token, rwTRUNCATE)) then Operator:=doTRUNCATE
  else if IsReservedWord(Token, rwHEX) then Operator:=doHex
  ;
  if Operator = doUNDEFINED then Exit;

  // get next token
  GetNextToken;
  if (Operator = doRANDOM) and (Token.TokenType <> tktLeftParenthesis) then
   begin
    Result := TETblExprNodeArithmetic.Create(Operator);
    Exit;
   end;

   // first argument must be in all operators
   if (Token.TokenType <> tktLeftParenthesis) then
    raise ETblException.Create(00078,
          [Token.Text, Token.LineNum, Token.ColumnNum], nil);
   GetNextToken;
   arg := ParseValueExpression;
   if (arg = nil) then
      raise ETblException.Create(00079,
              [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum], nil);

   // MOD, POWER always with 2 params
   if ((Operator = doMOD) or (Operator = doPOWER)) then
    begin
     if (Token.TokenType <> tktComma) then
      begin
       if (arg <> nil) then
        arg.Free;
       raise ETblException.Create(00081,
              [',', Token.Text, Token.LineNum, Token.ColumnNum], nil);
      end;
     GetNextToken;
     arg1 := ParseValueExpression;
     if (arg1 = nil) then
      begin
       if (arg <> nil) then
        arg.Free;
       raise ETblException.Create(00082,
              [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum], nil);
      end;
    end; // MOD

   // RANDOM with 0 or 1 parameter
   // ROUND, TRUNC, HEX can be with 1 or 2 parameters;
   if ((Operator = doROUND) or (Operator = doTRUNCATE) or (Operator = doHEX)) then
    begin
     if (Token.TokenType = tktComma) then
      begin
       GetNextToken;
       arg1 := ParseValueExpression;
       if (arg1 = nil) then
        begin
         if (arg <> nil) then
          arg.Free;
         raise ETblException.Create(00083,
                [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum], nil);
        end;
      end;
    end; // ROUND, TRUNCATE, RANDOM

   if (Token.TokenType <> tktRightParenthesis) then
     begin
      if (arg <> nil) then
       arg.Free;
      if (arg1 <> nil) then
       arg1.Free;
      raise ETblException.Create(00080,
              [Token.Text, Token.LineNum, Token.ColumnNum], nil);
     end;
   if (arg1 = nil) then
    Result := TETblExprNodeArithmetic.Create(Operator,arg)
   else
    Result := TETblExprNodeArithmetic.Create(Operator,arg,arg1);
   GetNextToken;
end; // ParseMathFunction


////////////////////////////////////////////////////////////////////////////////
//
// TETblExprNodeDateFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TETblExprNodeDateFunction.Create(Op: TETblDataOperator;
  Node: TETblExprNode; FormatStr: AnsiString);
begin
  inherited Create(op, Node);
  DateFormater := TDateFormater.Create(FormatStr);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TETblExprNodeDateFunction.Destroy;
begin
  DateFormater.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TETblExprNodeDateFunction.GetDataSize: Integer;
begin
  case Operator of
    doTOSTRING:   Result := DateFormater.GetStringMaxSize;
    doDAYNAME:    Result := 9; // Wednesday
    doMONTHNAME:  Result := 9; // September
   else
    Result := 0;
  end;
end;//GetDataSize


//------------------------------------------------------------------------------
// return Data Type
//------------------------------------------------------------------------------
function TETblExprNodeDateFunction.GetDataType: TFieldType;
begin
  case Operator of
    doSYSDATE:        Result := ftDateTime;
    doCURRENT_DATE:   Result := ftDate;
    doCURRENT_TIME:   Result := ftTime;
    doTODATE:         Result := ftDateTime;
    doTOSTRING:       Result := ftString;
    doYEAR:           Result := ftWord;
    doQUARTER:        Result := ftWord;
    doMONTH:          Result := ftWord;
    doDAY:            Result := ftWord;
    doWEEKDAY:        Result := ftWord;
    doDAYOFWEEK:      Result := ftWord;
    doDAYNAME:        Result := ftString;
    doMONTHNAME:      Result := ftString;
    doHOUR:           Result := ftWord;
    doMINUTE:         Result := ftWord;
    doSECOND:         Result := ftWord;
    doMSECOND:        Result := ftWord;
   else
    raise Exception.Create('Unknown Operator');
  end;
end;//GetDataType


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TETblExprNodeDateFunction.GetDataValue(
  DataSet: TDataSet): TETblDataValue;
begin
  case Operator of
    doSYSDATE:        SetDataValueAsDateTime(Data, now);
    doCURRENT_DATE:   SetDataValueAsDate(Data, now);
    doCURRENT_TIME:   SetDataValueAsTime(Data, now);
    doTODATE:         ToDate(DataSet);
    doTOSTRING:       ToString(DataSet);
    doYEAR,
    doQUARTER,
    doMONTH,
    doDAY,
    doWEEKDAY,
    doDAYOFWEEK,
    doDAYNAME,
    doMONTHNAME,
    doHOUR,
    doMINUTE,
    doSECOND,
    doMSECOND:        Extract(DataSet);
   else raise Exception.Create('Unknown Operator');
  end;
  Result := Data;
end;//GetDataValue


//------------------------------------------------------------------------------
// ToDate
//------------------------------------------------------------------------------
procedure TETblExprNodeDateFunction.ToDate(DataSet: TDataSet);
var
  dt: TDateTime;
  val: TETblDataValue;
begin
  InitDataValue(val);
  CopyDataValue(TETblExprNode(Children[0]).GetDataValue(DataSet), val);
  Cast(val, ftString);
  dt := DateFormater.ToDate(GetDataValueAsString(val));
  SetDataValueAsDateTime(Data, dt);
  FinalizeDataValue(val);
end; // ToDate


//------------------------------------------------------------------------------
// ToString
//------------------------------------------------------------------------------
procedure TETblExprNodeDateFunction.ToString(DataSet: TDataSet);
var
  DataValue: TETblDataValue;
begin
  DataValue := TETblExprNode(Children[0]).GetDataValue(DataSet);
  if (DataValue.IsNull) or (DataValue.pData = nil) then
    FinalizeDataValue(Data)
  else
    SetDataValueAsString(Data, DateFormater.ToString(
                                GetDataValueAsDateTime(DataValue)));
end; // ToString


//------------------------------------------------------------------------------
// extract part from date or time value
//------------------------------------------------------------------------------
procedure TETblExprNodeDateFunction.Extract(DataSet: TDataSet = nil);
var
    DataValue:  TETblDataValue;
    dt:         TDateTime;
    y,m,d,q:    Word;
    h,mm,ss,zz: Word;
begin
  if (Children.Count <=0) then
   raise ETblException.Create(00070,[GetOperatorName(Operator)],nil);
  DataValue := TETblExprNode(Children[0]).GetDataValue(DataSet);
  if (DataValue.IsNull) or (DataValue.pData = nil) then
   begin
    SetDataValueAsNull(Data,GetDataType);
    exit;
   end;
  dt := GetDataValueAsDateTime(DataValue);
  if (Operator <> doDAYOFWEEK) and (Operator <> doWEEKDAY) and
     (Operator <> doDAYNAME) then
   begin
    if (Operator <= doMONTHNAME) then
     DecodeDate(dt,y,m,d)
    else
     DecodeTime(dt,h,mm,ss,zz);
   end;
  case Operator of
    doYEAR:       SetDataValueAsWord(Data,y);
    doQUARTER:
                  begin
                   if (m < 4) then
                    q := 1
                   else
                   if (m < 7) then
                    q := 2
                   else
                   if (m < 10) then
                    q := 3
                   else
                    q := 4;
                   SetDataValueAsWord(Data,q);
                  end;
    doMONTH:      SetDataValueAsWord(Data,m);
    doDAY:        SetDataValueAsWord(Data,d);
    doWEEKDAY:    SetDataValueAsWord(Data,Word(aaDayOfWeek(dt)));
    doDAYOFWEEK:  SetDataValueAsWord(Data,Word(aaDayOfTheWeek(dt)));
    doDAYNAME:    SetDataValueAsString(Data,DayNames[aaDayOfWeek(dt)]);
    doMONTHNAME:  SetDataValueAsString(Data,MonthNames[m]);
    doHOUR:       SetDataValueAsWord(Data,h);
    doMINUTE:     SetDataValueAsWord(Data,mm);
    doSECOND:     SetDataValueAsWord(Data,ss);
    doMSECOND:    SetDataValueAsWord(Data,zz);
  end;
end; // Extract


////////////////////////////////////////////////////////////////////////////////
//
// TETblExprNodeSystem
//
////////////////////////////////////////////////////////////////////////////////

procedure TETblExprNodeSystem.AssignAO(AO: TEasyAO);
begin
  FAO := AO;
end;

constructor TETblExprNodeSystem.Create(TableName: AnsiString; Password: AnsiString; InMemory: boolean);
begin
  Inherited Create;
  Self.TableName := TableName;
  Self.Password := Password;
  Self.InMemory := InMemory;
end;

function TETblExprNodeSystem.GetDataType: TFieldType;
begin
  Result := ftInteger;
end;

function TETblExprNodeSystem.GetDataValue(
  DataSet: TDataSet): TETblDataValue;
begin
  LastAutoInc(DataSet);
  Result := Data;
end;

procedure TETblExprNodeSystem.LastAutoInc(DataSet: TDataSet);
var
  tet: TEasyTable;
  SessionName, DatabaseName: AnsiString;
begin
  tet := TEasyTable.Create(nil);
  try
   if FAO <> nil then
    begin
   FAO.GetDbInfo(SessionName, DatabaseName);
   tet.SessionName := SessionName;
   tet.DatabaseName := DatabaseName;
    end
   else
    begin
     tet.SessionName := TEasyDataset(DataSet).SessionName;
     tet.DatabaseName := TEasyDataset(DataSet).DatabaseName;
    end;
   tet.TableName := TableName;
   tet.Password := Password;
   tet.FastOpen := true;
   tet.InMemory := InMemory;
   tet.Open;
   SetDataValueAsInteger(Data, tet.LastAutoIncValue);
   tet.Close;
  finally
   tet.Free;
  end;
end;




//------------------------------------------------------------------------------
// parses <true/false>
//------------------------------------------------------------------------------
function TETblExpression.ParseTrueFalseConst: TETblExprNode;
var
  DataValue: TETblDataValue;
begin
 if Token.ReservedWord in [rwTRUE, rwFALSE] then
  begin
   InitDataValue(DataValue);
   SetDataValueAsBoolean(DataValue, Token.ReservedWord = rwTRUE);

   Result := TETblExprNodeConst.Create(DataValue);
   FinalizeDataValue(DataValue);
   GetNextToken;
  end
 else
  Result := nil;
end;//ParseTrueFalseConst


//------------------------------------------------------------------------------
// parses NULL const
//------------------------------------------------------------------------------
function TETblExpression.ParseNullConst: TETblExprNode;
begin
 if Token.ReservedWord = rwNULL then
  begin
   Result := TETblExprNodeConst.Create;
   Result.Data.DataType := ftInteger;
   GetNextToken;
  end
 else
  Result := nil;
end;//ParseNullConst


end.


