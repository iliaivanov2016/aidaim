unit SQLMemExpressions;

interface

{$I SQLMemVer.inc}

uses Classes, SysUtils, DB,
{$IFDEF MSWINDOWS}
//     Controls,
     Windows,
{$ENDIF}
{$IFDEF D6H}
     Variants,
{$ELSE}
     SQLMemD4Routines,
{$ENDIF}

{$IFDEF DEBUG_LOG}
     SQLMemDebug,
{$ENDIF}
{$IFDEF D12H}
     SQLMem_d12h,
{$ENDIF}
     SQLMemBase,
     SQLMemVariant,
     SQLMemLexer,
     SQLMemExcept,
     SQLMemConst,
     SQLMemTypes,
     SQLMemConverts,
     SQLMemStrUtils,
     SQLMemRelationalAlgebra,
     SQLMemDateFormat;


type

 TSQLMemExprNodeType = (entField, entConst, entOperator, entSet, entNull);
 TSign = (sgnUndefined, sgnPlus, sgnMinus);

 // unary / binary Value operators
 TSQLMemDataOperator = (
    doUNDEFINED,                       // error
    //George doCMP,                             // compare <0,=0,>0
    {Comparison}
    doEQ,                              // equal
    doNE,                              // NOT equal
    doGT,                              // greater than
    doLT,                              // less than
    doGE,                              // greater or equal
    doLE,                              // less or equal
    {Boolean}
    doNOT,                             // NOT
    doAND,                             // AND
    doOR,                              // OR
    doIN,                              // in (a,b,c, ...)
    doNOTIN,                           // not in (a,b,c, ...)
    doBETWEEN,                         // between (a,b)
    doNOTBETWEEN,                      // not between (a,b)
    doLIKE,                            // like 'a?b%'
    doNOTLIKE,                         // not like
    doISNULLFUNCTION,                  // IsNull function
    doISNULL,                          // is null
    doISNOTNULL,                       // is not null
    doTRUE,                            // TRUE const
    doFALSE,                           // FALSE const
    {Arithmetic}
    doADD,                             // addition
    doSUB,                             // subtraction
    doMUL,                             // multiplication
    doDIV,                             // division
    {Functions}
    //doPOSITION,                        // Position (str1) in (str2)
    doCONCAT,                          // str1 || str2
    doUPPER,                           // Upper(str)
    doLOWER,                           // Lower(str)
    doTRIM,                            // TRIM
    doLTRIM,                           // LTRIM
    doRTRIM,                           // RTRIM
    doLENGTH,                          // LENGTH(str)
    doPOS,                             // POS(substr in|, str) { 1 - first char, 0 - not found }
    doSUBString,                       // SUBString(str from|, startindex [for|, length])
    {aggregated functions}
    doSUM,                             // SUM([distinct]expression)
    doAVG,                             // AVG([distinct]expression)
    doMIN,                             // min(expression)
    doMAX,                             // max(expression)
    doCOUNT,                           // COUNT([distinct]expression)
    doCOUNTALL,                        // count(*)
    {datetime functions}
    doSYSDATE,                         // SYSDATE - return current DateTime
    doCURRENT_DATE,                    // CURRENT_DATE
    doCURRENT_TIME,                    // CURRENT_TIME
    doTODATE,                          // TODATE(string, format)
    doTOString,                        // TOString(date, format)
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
    doMSECOND,
    // 4.40
    doABS,
    doCEILING,
    doFLOOR,
    doMOD,
    doPOWER,
    doRANDOM,
    doROUND,
    doSIGN,
    doTRUNCATE,
    doBitwiseNOT,
    doBitwiseAND,
    doBitwiseOR,
    doSHL,
    doSHR,
    doXOR,
    doHEX,
    // end of 4.40
    {cast types}
    doCAST,             // Cast(expression, type)
    {system}
    doLASTAUTOINC,
    doTOBLOB,           // TOBLOB(string, format)
    // 4.97
    doCUMSUM,
    doCUMPROD,
    // GROUP_CONCAT([DISTINCT] [DESC | ASC] field_name[, Separator])
    doGROUP_CONCAT
    // 5.80
    ,doNULLIFFUNCTION // NullIf function
    ,doSubQuery               // (SELECT id FROM Table1)
    ,doSubQueryIN             // IN (SELECT id FROM Table1)
    ,doSubQueryEXISTS         // EXISTS (SELECT id FROM Table1)
    ,doSubQueryANY            // ANY (SELECT id FROM Table1)
    ,doSubQueryALL            // ALL (SELECT id FROM Table1)
    // 5.85
    ,doDAYOFYEAR
    ,doISOWEEK
    ,doWEEK
    // 5.90
    ,doSTDDEV                 // STDDEV(expression)
    ,doASCII                  // ASCII('a')
    ,doCHR                    // CHR(65), CHAR(65)
    ,doREPEAT                 // REPEAT('a',3)
    ,doREPLACE                // REPLACE('ABABA','B','D')
    ,doEXP                    // EXP(10.1)
    ,doLOG                    // LOG = LN - natural logarithm
    ,doLOG10                  // LOG10 - decimal logarithm
    ,doCOS                    // COS
    ,doSIN                    // SIN
    ,doACOS                   // ACOS
    ,doASIN                   // ASIN
    ,doATAN                   // ATAN
    ,doATAN2                  // ATAN2
    ,doCOT                    // COT
    ,doTAN                    // TAN
    ,doSQR                    // SQR
    ,doSQRT                   // SQRT
    ,doDEGREES                // DEGREES
    ,doRADIANS                // RADIANS
    ,doPI                     // PI
 );

  TSQLMemTrimType = (attLeading,attTrailing,attBoth);

  TSQLMemBLOBValueFormat = (bvfMIME64,bvfHEX);
  // forward declarations
  TSQLMemExprNode = class;
  TSQLMemExprNodeComparison = class;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExpression
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExpression = class (TObject)
   private
    LLex:                 TSQLMemLexer;   // lexer with expression to parse
    Token:                TToken;      // current token
    LCursor:              TSQLMemCursor;
    LSQLCommand:          TObject;     // TSQLMemSQLCommand object if expression is created by SQL command
    LStoredFunction:      TObject;     // StoredFunction of TSQLMemSQLCommand if expression is created by SQL command
    LSession:             TSQLMemBaseSession; // session object that creates the expression - needed for parsing stored functions
    LParams:              TSQLMemSQLParams;   // SQL params for expression evalutaion inside stored function
    FRootExprNode:        TSQLMemExprNode;
    FCaseInsensitive:     Boolean;
    FPartialKey:          Boolean;
    F3ValueLogic:         Boolean;
    FInMemory:            Boolean;
    FDatabaseName:        AnsiString;
    FSessionName:         AnsiString;
    FParams:              TParams;
{$IFNDEF EXPR_PARSING_1}
    FNumLeftParenthesis:  Integer;
    FNumRightParenthesis: Integer;
{$ENDIF}
   private
    // gets current token
    //function GetCurrentToken: Boolean;
    // gets next token
    function GetNextToken: Boolean; overload;
    // gets next token
    //function GetNextToken(NativeErrorCode: integer): Boolean; overload;
    // gets token and lokks at next token with check for token type restrictions
    function GetNextToken(PermittedTypes: TTokenTypes;
                          RaiseExceptions: Boolean = False): Boolean; overload;

   private
    // saves internal state (to restore in case of not successful forward parsing)
    procedure SaveState(var SavedTokenNo: integer);// var SavedRootNode: TSQLMemExprNode);
    // restores internal state (in case of not successful forward parsing)
    procedure RestoreState(SavedTokenNo: integer);// SavedRootNode: TSQLMemExprNode);
{$IFNDEF EXPR_PARSING_1}
    // parses <,>,=,<>,>=,<=
    function ParseCompOp: TSQLMemDataOperator;
    // parses <row value constructor element>
    function ParseRowValueConstructorElement: TSQLMemExprNode;
    // parses <row value constructor element> | <row subquery>
    function ParseRowValueConstructor: TSQLMemExprNode;
    // parses <row value constructor> <comp op> <row value constructor>
    function ParseComparisonPredicate(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
    // parses <boolean factor> | <boolean term> AND <boolean factor>
    function ParseBooleanTerm(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
    // parses <match value> [ NOT ] LIKE <pattern> [ ESCAPE <escape character> ]
    function ParseLikePredicate(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
    // parses <row value constructor> IS [ NOT ] NULL
    function ParseNullPredicate(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
    // parses <between predicate>
    function ParseBetweenPredicate(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
    // parses <in predicate>
    function ParseInPredicate(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
{$ENDIF}
    // parses <Exists predicate>
    function ParseExistsPredicate: TSQLMemExprNode;
    // parses <true/false>
    function ParseTrueFalseConst: TSQLMemExprNode;
    // parses <NULL> const
    function ParseNullConst: TSQLMemExprNode;
{$IFDEF EXPR_PARSING_1}
    // parses <value expression>
    function ParseValueExpression(
                                  ParseOperators:   Boolean = True;
                                  bStart:           Boolean = True;
                                  bParseConcatOnly: Boolean = False
                                 ): TSQLMemExprNode;
    // parses <operator>
    function ParseOperator: TSQLMemDataOperator;
    // return operator priority (0 - low, 255 - maximum);
    function GetOperatorPriority(Operator: TSQLMemDataOperator): Byte;
    // make <operator>
    function MakeOperator(node1, node2: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
    // parses <boolean value expression>
    function ParseBooleanValueExpression: TSQLMemExprNode;
    // parses <arithmetic value expression>
    function ParseArithmeticValueExpression: TSQLMemExprNode;
    // parses <text value expression>
    function ParseTextValueExpression: TSQLMemExprNode;
    // parses <general value expression>
    function ParseGeneralValueExpression: TSQLMemExprNode;
    // parses <match value> [ NOT ] LIKE <pattern> [ ESCAPE <escape character> ]
    function ParseLike(Node: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
    // parses <between predicate>
    function ParseBetween(Node: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
    // parses <in predicate>
    function ParseIn(Node: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
{$ELSE}
    // parses <value expression>
    function ParseValueExpression: TSQLMemExprNode;
    // parses <comparison predicate> | <between predicate> | <in predicate>  |
    // <like predicate>  | <null predicate> | <quantified comparison predicate> |
    // <exists predicate> | <unique predicate> | <match predicate> | <overlaps predicate>
    function ParsePredicate: TSQLMemExprNode;
    // parses <predicate>  | <left paren> <search condition> <right paren>
    function ParseBooleanPrimary: TSQLMemExprNode;
    // parses <boolean primary> [ IS [ NOT ] <truth value> ]
    function ParseBooleanTest: TSQLMemExprNode;
    // parses [ NOT ] <boolean test>
    function ParseBooleanFactor: TSQLMemExprNode;
    // parses <boolean term> | <search condition> OR <boolean term>
    function ParseSearchCondition: TSQLMemExprNode;
    // parse <expression> <Boolean_operator> <expression>
    function ParseBooleanOperator(Node: TSQLMemExprNode): TSQLMemExprNode;
    // parses <numeric value expression>
    function ParseNumericValueExpression: TSQLMemExprNode;
    // parses <term>
    function ParseTerm: TSQLMemExprNode;
    // parses <factor>
    function ParseFactor: TSQLMemExprNode;
    // parses <sign> ('+' or '-')
    function ParseSign: TSign;
    // parses <numeric primary>
    function ParseNumericPrimary: TSQLMemExprNode;
    // parses <unsigned value specification>
    function ParseUnsignedValueSpecification: TSQLMemExprNode;
    // parses <unsigned literal>
    function ParseUnsignedLiteral: TSQLMemExprNode;
    // parses <unsigned numeric literal>
    function ParseUnsignedNumericLiteral: TSQLMemExprNode;
    // parses <character AnsiString literal>
    function ParseCharacterStringLiteral: TSQLMemExprNode;
    // parses <value expression primary>
    function ParseValueExpressionPrimary: TSQLMemExprNode;
{$ENDIF}
    // parses <column reference>
    function ParseColumnReference: TSQLMemExprNode;
{$IFDEF CORRELATED_SUBQUERIES}
    // parses <SUB QUERY>
    function ParseSubQuery(
                           Operator:      TSQLMemDataOperator;
                           bNot:          Boolean = False;
                           SourceNode:    TSQLMemExprNode = nil;
                           CompOp:        TSQLMemDataOperator = doEQ
                          ): TSQLMemExprNode;
{$ELSE}
    // parses <SUB QUERY>
    function ParseSubQuery(
                           bExists:       Boolean = False;
                           bIn:           Boolean = False;
                           bNot:          Boolean = False;
                           SourceNode:    TSQLMemExprNode = nil
                          ): TSQLMemExprNode;
{$ENDIF}
    // parses <set function specification>
    function ParseSetFunctionSpecification: TSQLMemExprNode;
    // parses <general set function>
    function ParseGeneralSetFunction: TSQLMemExprNode;
    // parses <cast specification>
    function ParseCastSpecification: TSQLMemExprNode;
    // parses <cast operand>
    function ParseCastOperand: TSQLMemExprNode;

    // parses <numeric value function>
    function ParseNumericValueFunction: TSQLMemExprNode;
    // parses <position expression>
    function ParsePositionExpression: TSQLMemExprNode;
    // parses <length expression>
    function ParseLengthExpression: TSQLMemExprNode;
    // parses <LastAutoInc expression>
    function ParseLastAutoIncExpression: TSQLMemExprNode;
    // parses <IsNull expression>
    function ParseIsNullExpression: TSQLMemExprNode;
    // parses <COALESCE expression>
    function ParseCoalesceExpression: TSQLMemExprNode;
    // parses CASE
    function ParseCase: TSQLMemExprNode;
    // parses <NullIf expression>
    function ParseNullIfExpression: TSQLMemExprNode;

{$IFNDEF EXPR_PARSING_1}
    // parses <string value expression>
    function ParseStringValueExpression: TSQLMemExprNode;
    // parses <character value expression>
    function ParseCharacterValueExpression: TSQLMemExprNode;
    // parses <concatenation>
    function ParseConcatination: TSQLMemExprNode;
    // parses <character factor>
    function ParseCharacterFactor: TSQLMemExprNode;
    // parses <character primary>
    function ParseCharacterPrimary: TSQLMemExprNode;
    // parses <general literal>
    function ParseGeneralLiteral: TSQLMemExprNode;
    // parses <string value function>
    function ParseStringValueFunction: TSQLMemExprNode;
{$ENDIF}
    // parses <character value function>
    function ParseCharacterValueFunction: TSQLMemExprNode;
    // parses <BLOB value function>
    function ParseBLOBValueFunction: TSQLMemExprNode;

    // parse <datetime value expression>
    function ParseDatetimeValueExpression: TSQLMemExprNode;
    // parse <datetime sysdate function>
    function ParseSysdateFunction: TSQLMemExprNode;
    // parse <datetime CURRENT_TIME function>
    function ParseCurrentTimeFunction: TSQLMemExprNode;
    // parse <datetime CURRENT_DATE function>
    function ParseCurrentDateFunction: TSQLMemExprNode;
    // parse <datetime TODATE function>
    function ParseToDateFunction: TSQLMemExprNode;
    // return parsed DatePart or dpUNDEFINED if it was not parsed
    function ParseDatePart: TSQLMemDatePart;
    // parse <datetime DATEADD function>
    function ParseDateAddFunction: TSQLMemExprNode;
    // parse <datetime DATEDIFF function>
    function ParseDateDiffFunction: TSQLMemExprNode;
    // parse <datetime extract functions>
    function ParseDateTimeExtractFunction: TSQLMemExprNode;
    // parse <Math function>
    function ParseMathFunction: TSQLMemExprNode;
    // parse stored function
    function ParseStoredFunction: TSQLMemExprNode;
    // parse variable
    function ParseVariable: TSQLMemExprNode;
   private
    procedure Clear;
   public
    procedure Assign(SourceExpr: TSQLMemExpression; CopyRootExprNode: Boolean = True);
    // Constructors
    constructor Create(aSession: TSQLMemBaseSession; aParams: TSQLMemSQLParams); overload;
    // creates
    constructor Create(aSession: TSQLMemBaseSession; aParams: TSQLMemSQLParams; RootNode: TSQLMemExprNode; aSQLCommand: TObject); overload;
    // Destructor
    destructor Destroy; override;
   public
    procedure PrepareForeignKeyCheck(
                                        ReferencedCursor: TSQLMemCursor;
                                        Cursor:           TSQLMemCursor;
                                        ConstraintDef:    TSQLMemConstraintDefForeignKey;
                                        PrimaryIndex:     TSQLMemIndexDef
                                     );
    procedure PrepareForeignKeyActionFilter(
                                        ReferencedCursor: TSQLMemCursor;
                                        Cursor:           TSQLMemCursor;
                                        ConstraintDef:    TSQLMemConstraintDefForeignKeyAction;
                                        PrimaryIndex:     TSQLMemIndexDef
                                     );
    // Parsing for Locate
    procedure ParseForLocate(
                              Cursor:           TSQLMemCursor;
                              FieldNames:       WideString;
                              KeyValues:        Variant;
                              CaseInsensitive:  Boolean = true;
                              PartialKey:       Boolean = false
                            ); overload;
    // added fior FindRecord cache
    // Parsing for Locate
    procedure ParseForLocate(
                              Cursor:           TSQLMemCursor;
                              FieldNamesList:   TSQLMemWideStringList;
                              CaseInsensitive:  Boolean = true;
                              PartialKey:       Boolean = false
                            ); overload;
    // set locate params
    procedure SetLocateParams(KeyValues: Variant);


    // Parsing for Filter
    procedure ParseForFilter(
                              Cursor: TSQLMemCursor;
                              Filter: WideString;
                              CaseInsensitive: boolean = true;
                              PartialKey: boolean = false
                            );
    // Parse For Boolean Expression (Filter, Where-Clause)
    procedure ParseForBooleanExpression(
                                        //Cursor: TSQLMemCursor;
                                        Lexer: TSQLMemLexer
                                        //CaseInsensitive: boolean = true;
                                        //PartialKey: boolean = false
                                       );
    // Parse ValueExpression
    procedure ParseForValueExpression(
                                        Lexer: TSQLMemLexer
                                       );
    // Return Variant
    function GetValue(TrueFalseNullLogic: boolean = true): TSQLMemVariant;
    // Get Boolean result
    function GetResult: Boolean;

    // is expression contains aggregated function
    function IsAggregated: Boolean;
    // is expression contains function COUNT(*)
    function IsCountAll: Boolean;
    // is expression contains function COUNT(*) and has no other nodes
    function IsCountAllOnly: Boolean;
    // Init for aggregated functions
    procedure Init;
    // Accumulate for group functions
    procedure Accumulate(Increment: Integer = 1);
    // process assign AO
    procedure AssignAO(AO: TSQLMemAO);
    // process assign Cursor and its RecordBuffer
    procedure AssignCursor(Cursor: TSQLMemCursor);
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TSQLMemRecordBuffer);
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer;
    // return Size of Data (for strings and arrays)
    function GetPrecision: Integer;
    // is expression contains no nodes
    function IsEmpty: Boolean;
    // return true if (FRootExprNode is TSQLMemExprNodeConst) and (FRootExprNode.Value.IsNull)
    function IsNullConst: Boolean;
    // is expression a Field (for join)
    function IsField: Boolean;
    // is expression a constant
    function IsConst: Boolean;
    // Move AndNodes To RootNode
    procedure MoveAndNodesToRoot;
    // Field Name, Table Name
    procedure GetFieldInfo(var TableName, FieldName: WideString);
    // makes filter AnsiString from related parts and sets it to AO
{$IFDEF CORRELATED_SUBQUERIES}
    // return ture if correlated field nodes were found
    function ApplyFilterParts(AO: TSQLMemAO; bHaving, bJoinOn: Boolean; bSubQuery: Boolean = False; bRootAO: Boolean = False): Boolean;
{$ELSE}
    procedure ApplyFilterParts(AO: TSQLMemAO; bHaving, bJoinOn: Boolean);
{$ENDIF}
    // replace pseudonyms to original names (f1 -> table1.field1)
    procedure ReplacePseudonyms(SelectList: array of TSQLMemSelectListItem);
    // makes join field lists
    function ExtractJoinConditions(
                                    AO1, AO2: TSQLMemAO;
                                    FieldList1, FieldList2: TSQLMemFields
                                  ): Integer;
{$IFNDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // extract conditions for index scan
    procedure TryExtractIndexScanConditionsFromNode(
                             Node:           TSQLMemExprNodeComparison;
                             IndexDefs:      TSQLMemIndexDefs;
                             ScanConditions: TSQLMemScanSearchConditionArray;
                             ExtractedConditionsInfo: TList
                                        );
    // remove extracted nodes (they included in list, but list contains more)
    procedure RemoveExtractedNodes(ExtractedConditionsInfo: TList);
    // extract conditions for index scan
    procedure ExtractIndexScanConditions(
                             IndexDefs:               TObject;
                             ScanConditions:          TSQLMemScanSearchConditionArray;
                             ExtractedConditionsInfo: TList
                                        );
{$ENDIF}
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // extract conditions for index scan - skip their evaluation in root node
    // return true if all nodex were extracted
    function ExtractIndexScanConditions(
                             ScanConditions:          TSQLMemList;
                             aIndexDefs:              TObject
                                         ): Boolean;
{$ENDIF}
    // return true if expression have incompatible conditions (like compare = for AnsiString fields with constant longer then field size)
    function IsIncompatible: Boolean;
    // add extracted node
    procedure AddNode(Node: TSQLMemExprNode);
    // return new TSQLMemExpression object with all filter conditions assigned to SourceDataset
    // return nil if there are no way to extract such conditions
    function ExtractFilterConditionsAssignedToSourceDataset(AO: TSQLMemAOTable): TSQLMemExpression;
    // fills ExtractedConditions list with all conditions from root expression node or children
    // of root expression node if it is TSQLMemExprNodeBoolean with doAND operator
    // containing TSQLMemExprNodeField that belongs to AO or its children
    procedure ExtractFilterConditionsAssignedToAO(AO: TSQLMemAO; ExtractedConditions: TList);
    // return true if there is any TSQLMemNodeField child that can be linked to AO
    function IsNodeFieldChildrenLinkedToAOExists(AO: TSQLMemAO): Boolean;
    // extract all TSQLMemExprNodeConst objects from FRootExprNode and all its children
    procedure ExtractAllParameterNodes(NodeList: TSQLMemList);
{$IFDEF CORRELATED_SUBQUERIES}
    // return true if external field nodes exists (referencing main query from sub-query node)
    function ExtractAllExternalFieldNodes(var FieldNodeList: TSQLMemList; var ConstNodeList: TSQLMemList; AO: TSQLMemAO): Boolean;
    // return true if expression has at least 1 correlated subquery
    function CorrelatedSubQueriesExists: Boolean;
{$ENDIF}
    // raises exception if FRootExprNo or its child has TSQLMemExprNodeField
    // added in 4.97 for raising correct exception if search condition cannot be
    // assigned fully to AO
    procedure CheckInvalidFieldNames;
    // add join condition to search condiition
    procedure AddJoinCondition(Expression: TSQLMemExpression);
    // updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
    procedure UpdateExpressionParams;
   public
    property InMemory: Boolean read FInMemory write FInMemory;
    property DatabaseName: AnsiString read FDatabaseName write FDatabaseName;
    property SessionName: AnsiString read FSessionName write FSessionName;
    property Params: TParams read FParams write FParams;
    property SQLCommand: TObject read LSQLCommand write LSQLCommand;
    property StoredFunction: TObject read LStoredFunction write LStoredFunction;
    property LocalParams: TSQLMemSQLParams read LParams write LParams;
    property RootExprNode: TSQLMemExprNode read FRootExprNode write FRootExprNode;
    property Session: TSQLMemBaseSession read LSession write LSession;
    property CaseInsensitive: Boolean read FCaseInsensitive write FCaseInsensitive;
  end; // TSQLMemExpression




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExpressions
//
// list of TSQLMemExpression objects
// used in stored functions
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExpressions = class (TObject)
   private
    FExprList: TList;
   private
    function GetCount: Integer;
    function GetValue(Index: Integer): TSQLMemExpression;
    procedure SetValue(Index: Integer; Value: TSQLMemExpression);
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddCreated(aSession: TSQLMemBaseSession; aParams: TSQLMemSQLParams): TSQLMemExpression;
    procedure Assign(Source: TSQLMemExpressions);
   public
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TSQLMemExpression read GetValue write SetValue; default;
  end; // TSQLMemExpressions



  
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNode
//
// base class for all expression nodes 
// fully virtual (i.e. never created)
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNode = class(TObject)
   protected
    Children:         TSQLMemList;                 // Children nodes
    Operator:         TSQLMemDataOperator;      // '<',  '>', AND, NOT, ...
    Value:            TSQLMemVariant;
    FCaseInsensitive: Boolean;
    FPartialKey:      Boolean;
    FIsParameter:     Boolean;
    FParamCRC:        Cardinal;
    LParentExpr:      TSQLMemExpression;        // parent expression
    FDoNotReassign:   Boolean;
   protected
    // converts some WideStrings to Strings
    procedure PatchWideStrings; virtual;
    // return true if this node and all its children can be linked to source table filter expression
    function IsExprNodeCanBeLinkedToSourceTable(AO: TSQLMemAOTable): Boolean; virtual;
    // return true if there is any TSQLMemNodeField child that can be linked to AO
    function IsNodeFieldChildrenLinkedToAOExists(AO: TSQLMemAO): Boolean; virtual;
    function GetChildrenCount: Integer;
{$IFDEF DEBUG_LOG}
    function GetName: AnsiString; virtual;
    function GetValue(bBool: Boolean = False): AnsiString; virtual;
{$ENDIF}
   public
    // constructors
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       Node:            TSQLMemExprNode;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       Node1, Node2:    TSQLMemExprNode;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                       ); overload;
    constructor Create(
                       aParentExpr:         TSQLMemExpression;
                       Op:                  TSQLMemDataOperator;
                       Node1, Node2, Node3: TSQLMemExprNode;
                       CaseInsensitive:     Boolean = true;
                       PartialKey:          Boolean = false
                       ); overload;
    // destroy
    destructor Destroy; override;
    // return Value
    function GetDataValue: TSQLMemVariant;  virtual; abstract;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  virtual;
    // is expression contains aggregated function
    function IsAggregated: Boolean; virtual;
    // is expression contains aggregated function COUNT(*)
    function IsCountAll: Boolean; virtual;
    // Init for group function
    procedure Init; virtual;
    // Accumulate for group functions
    procedure Accumulate(Increment: Integer = 1); virtual;

    // process assign AO
    procedure AssignAO(AO: TSQLMemAO); virtual;
    // process assign Cursor
    procedure AssignCursor(Cursor: TSQLMemCursor); virtual;
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TSQLMemRecordBuffer); virtual;

    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; virtual;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; virtual;
    // return Data Precision
    function GetPrecision: Integer; virtual;

    // can be used by the AO?
    function CanBeAssigned(AO: TSQLMemAO): Boolean; virtual;

    // is node a join condition?
    function IsJoinCondition(AO1, AO2: TSQLMemAO): Boolean; virtual;

    // replace pseudonyms to original names (f1 -> table1.field1)
    procedure ReplacePseudonyms(SelectList: array of TSQLMemSelectListItem); virtual;

    // extract all TSQLMemExprNodeConst objects from FRootExprNode and all its children
    procedure ExtractAllParameterNodes(NodeList: TSQLMemList); virtual;
{$IFDEF CORRELATED_SUBQUERIES}
    // return true if external field nodes exists (referencing main query from sub-query node)
    function ExtractAllExternalFieldNodes(var FieldNodeList: TSQLMemList; var ConstNodeList: TSQLMemList; AO: TSQLMemAO): Boolean; virtual;
    // return true if expression has at least 1 correlated subquery
    function CorrelatedSubQueriesExists: Boolean;
{$ENDIF}
    // raises exception if FRootExprNo or its child has TSQLMemExprNodeField
    // added in 4.97 for raising correct exception if search condition cannot be
    // assigned fully to AO
    procedure CheckInvalidFieldNames; virtual;
    // return true if is NULL or any child is NULL
    function HasNullValues: Boolean; virtual;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; virtual;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); virtual;
    // clear
    procedure Clear; virtual;
    // make copy of TSQLMemSQLCommand object
    function MakeCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
    // find TSQLMemExprNodeComparison (Operator = doEQ) with child TSQLMemExprNodeField with specified name
    function FindComaprisonEQWithField(FieldNameCRC: Cardinal; var Node1: TSQLMemExprNode; var Node2: TSQLMemExprNode): TSQLMemExprNode; virtual;
    // return TSQLMemExprNodeConst or TSQLMemExprNodeVar from children of TSQLMemExprNodeComparison
    function GetParameterNode: TSQLMemExprNode; virtual;
    // return TSQLMemExprNodeField of TSQLMemExprNodeComparison
    function GetFieldNode: TSQLMemExprNode; virtual;
    // updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
    procedure UpdateExpressionParams; virtual;
   public
    property IsParameter: Boolean read FIsParameter write FIsParameter default False;
    property ParamCRC: Cardinal read FParamCRC write FParamCRC default 0;
    property ParentExpr: TSQLMemExpression read LParentExpr write LParentExpr;
    property ChildrenCount: Integer read GetChildrenCount;
    property DoNotReassign: Boolean read FDoNotReassign write FDoNotReassign;
  end;




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeConst - constants
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeConst = class(TSQLMemExprNode)
   public
    // return Value
    function GetDataValue: TSQLMemVariant; override;
    // set new value - used in reopening parametrized queries for setting new values
    procedure SetDataValue(NewValue: TSQLMemVariant; CopyFlag: Boolean = True);
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;

    // can be used by the AO?
    function CanBeAssigned(AO: TSQLMemAO): Boolean; override;
    // extract all TSQLMemExprNodeConst objects from FRootExprNode and all its children
    procedure ExtractAllParameterNodes(NodeList: TSQLMemList); override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
  end; // TSQLMemExprNodeConst




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeField - field values from some cursor / AO
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeField = class(TSQLMemExprNode)
   private
    LCursor:              TSQLMemCursor; // Cursor
    LAO:                  TSQLMemAO;
    LRecordBuffer:        PAnsiChar;
    FTableName:           WideString;  // table name - Table1 (Table1.Field1)
    FTableNameCRC:        Cardinal;
    FFieldName:           WideString;  // field name - Field1
    FFieldNameCRC:        Cardinal;
    FFieldNo:             Integer;
    FFieldOffsetInBuffer: Integer;
    FFieldType:           TSQLMemAdvancedFieldType;
    FBaseFieldType:       TSQLMemBaseFieldType;
    FFieldSize:           Integer;
    FFieldPrecision:      Integer;
    FIsBlob:              Boolean;
   private
    // return true if this node and all its children can be linked to source table filter expression
    function IsExprNodeCanBeLinkedToSourceTable(AO: TSQLMemAOTable): Boolean; override;
    // return true if there is any TSQLMemNodeField child that can be linked to AO
    function IsNodeFieldChildrenLinkedToAOExists(AO: TSQLMemAO): Boolean; override;
{$IFDEF DEBUG_LOG}
    function GetName: AnsiString; override;
{$ENDIF}
   public
    constructor Create(
                        aParentExpr: TSQLMemExpression;
                        Cursor:      TSQLMemCursor;
                        FieldName:   WideString;
                        TableName:   WideString = ''
                      ); overload;
    destructor Destroy; override;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // process assign AO
    procedure AssignAO(AO: TSQLMemAO); override;
    // process assign Cursor and its buffer
    procedure AssignCursor(Cursor: TSQLMemCursor); override;
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TSQLMemRecordBuffer); override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Data Size
    function GetDataSize: Integer;  override;

    // can be used by the AO?
    function CanBeAssigned(AO: TSQLMemAO): Boolean; override;
    // fills Field Item
    procedure FillItem(var Item: TSQLMemSelectListItem);
    // replace pseudonyms to original names (f1 -> table1.field1)
    procedure ReplacePseudonyms(SelectList: array of TSQLMemSelectListItem); override;
    // raises exception if FRootExprNo or its child has TSQLMemExprNodeField
    // added in 4.97 for raising correct exception if search condition cannot be
    // assigned fully to AO
    procedure CheckInvalidFieldNames; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
{$IFDEF CORRELATED_SUBQUERIES}
    // return true if external field nodes exists (referencing main query from sub-query node)
    function ExtractAllExternalFieldNodes(var FieldNodeList: TSQLMemList; var ConstNodeList: TSQLMemList; AO: TSQLMemAO): Boolean; override;
{$ENDIF}
   public
    property TableName: WideString read FTableName;
    property FieldName: WideString read FFieldName;
    property FieldNo: Integer read FFieldNo;
    property FieldOffsetInBuffer: Integer read FFieldOffsetInBuffer;
    property FieldSize: Integer read FFieldSize;
    property BaseFieldType: TSQLMemBaseFieldType read FBaseFieldType;
    property TableNameCRC: Cardinal read FTableNameCRC;
    property FieldNameCRC: Cardinal read FFieldNameCRC;
  end;


{$IFNDEF CORRELATED_SUBQUERIES}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQuery
//
// base class for all sub-query classes
//
////////////////////////////////////////////////////////////////////////////////


  // expression node SubQuery
  TSQLMemExprNodeSubQuery = class (TSQLMemExprNode)
  private
    FQuery:           TDataset; // query
    FNot:             Boolean;  // NOT option for IN or EXISTS
    FSourceNode:      TSQLMemExprNode; // source node for IN
    FDataType:        TSQLMemAdvancedFieldType;
    FQueryResult:     Boolean;
  public
    constructor Create(
                       aParentExpr:       TSQLMemExpression;
                       QueryText:         WideString;
                       Params:            TParams;
                       InMemory:          Boolean;
                       DatabaseName:      AnsiString;
                       SessionName:       AnsiString;
                       bNot:              Boolean = False;
                       SourceNode:        TSQLMemExprNode = nil
                       ); overload;
    // destroy
    destructor Destroy; override;
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    function GetDataType: TSQLMemAdvancedFieldType; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end; // TSQLMemExprNodeSubQuery



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQueryExists
//
// expression node SubQueryIN
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeSubQueryIN = class (TSQLMemExprNodeSubQuery)
  public
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  override;
  end; // TSQLMemExprNodeSubQueryIN




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQueryExists
//
// expression node SubQueryExists
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeSubQueryExists = class (TSQLMemExprNodeSubQuery)
  public
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  override;
  end; // TSQLMemExprNodeSubQueryExists
{$ENDIF}



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeComparison
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeComparison = class(TSQLMemExprNode)
   private
    F3ValueLogic:   Boolean; // 3 Value Logic (TRUE, FALSE, NULL)
    FNode1,FNode2:  TSQLMemExprNode;
   private
    procedure PatchWideStrings; override;
   public
    // Constructor
    constructor Create(
                       aParentExpr:         TSQLMemExpression;
                       Op:                  TSQLMemDataOperator;
                       Node1, Node2:        TSQLMemExprNode;
                       TrueFalseNullLogic:  Boolean = true;
                       CaseInsensitive:     Boolean = true;
                       PartialKey:          Boolean = false
                      ); overload;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  override;
    // can use index for comparison?
    function CanUseIndex(IndexDef: TSQLMemIndexDef): Boolean;
{$IFNDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // add index scan condition
    procedure AddAsIndexScanCondition(
                   ScanConditions: TSQLMemScanSearchConditionArray;
                   IndexDef:       TSQLMemIndexDef;
                   ExtractedConditionsInfo: TList;
                   Expression:  TSQLMemExpression
                              );
{$ENDIF}
{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
    // add index scan condition
    procedure AddAsIndexScanCondition(
                                       ScanConditions: TSQLMemList;
                                       IndexDef:       TSQLMemIndexDef
                                      ); overload;
{$ENDIF}
    // return true if expr node is incompatible (node comparison)
    function IsIncompatible: Boolean;
    // is node a join condition?
    function IsJoinCondition(AO1, AO2: TSQLMemAO): Boolean; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
    // find TSQLMemExprNodeComparison (Operator = doEQ) with child TSQLMemExprNodeField with specified name
    function FindComaprisonEQWithField(FieldNameCRC: Cardinal; var Node1: TSQLMemExprNode; var Node2: TSQLMemExprNode): TSQLMemExprNode; override;
    // return TSQLMemExprNodeConst or TSQLMemExprNodeVar from children of TSQLMemExprNodeComparison
    function GetParameterNode: TSQLMemExprNode; override;
    // return TSQLMemExprNodeField of TSQLMemExprNodeComparison
    function GetFieldNode: TSQLMemExprNode; override;
  end; // TSQLMemExprNodeComparison




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeBoolean
//
// boolean operators - Like, In, Between, Not, And, Or, IS NULL, IS NOT NULL, etc.
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeBoolean = class(TSQLMemExprNode)
   private
    TempVal:        TSQLMemVariant;
    FIgnoreNodes:   TSQLMemList;
   private
    // process a Like b
    function Like: Boolean;
    // process IN (...)
    function bIn: Boolean;
    // process A BETWEEN B AND C
    function Between: Boolean;
   public
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       Node:            TSQLMemExprNode;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       Node1, Node2:    TSQLMemExprNode;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr:         TSQLMemExpression;
                       Op:                  TSQLMemDataOperator;
                       Node1, Node2, Node3: TSQLMemExprNode;
                       CaseInsensitive:     Boolean = true;
                       PartialKey:          Boolean = false
                      ); overload;
    destructor Destroy; override;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Value as Boolean
    function GetBooleanValue: Boolean;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    property IgnoreNodes: TSQLMemList read FIgnoreNodes write FIgnoreNodes;
  end;




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeIsNullFunction
//
// expression node IsNull function
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeIsNullFunction = class (TSQLMemExprNode)
  private
    FType1: TSQLMemAdvancedFieldType;
    FType2: TSQLMemAdvancedFieldType;
  public
    constructor Create(
                       aParentExpr:   TSQLMemExpression;
                       Op:            TSQLMemDataOperator;
                       Node1, Node2:  TSQLMemExprNode
                      ); overload;
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // must return false
    function HasNullValues: Boolean; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end;




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeNullIfFunction
//
// expression node NullIf function
//
// return NULL if both expressions returns the same values
// otherwise return first expression value
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeNullIfFunction = class (TSQLMemExprNode)
  public
    constructor Create(
                       aParentExpr:   TSQLMemExpression;
                       Op:            TSQLMemDataOperator;
                       Node1, Node2:  TSQLMemExprNode
                      ); overload;
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // must return false
    function HasNullValues: Boolean; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
  end;




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeVarcharResultFunction
//
// expression node that returns Varchar / WideVarchar and is based on different expressions
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeVarcharResultFunction = class (TSQLMemExprNode)
  protected
    FBaseType:    TSQLMemBaseFieldType;
    FType:        TSQLMemAdvancedFieldType;
    FSize:        Integer;
  protected
    function IsChildMustBeSkippedByDetectType(ChildNo: Integer): Boolean; virtual;
    procedure DetectType;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end; // TSQLMemExprNodeVarcharResultFunction


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeCoalesceFunction
//
// expression node Coalesce function
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeCoalesceFunction = class (TSQLMemExprNodeVarcharResultFunction)
  public
    constructor Create(
                       aParentExpr:   TSQLMemExpression;
                       NodeList:      TSQLMemList
                      ); overload;
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // must return false
    function HasNullValues: Boolean; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
  end; // TSQLMemExprNodeCoalesceFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeCase
//
// expression node CASE operator
//
// Simple Form:
// CASE case_expression
// WHEN value_expression_1 THEN result_expression_1
// WHEN value_expression_2 THEN result_expression_2
// ...
// WHEN value_expression_n THEN result_expression_n
// [ELSE else_expression]
// END
//
// Advanced Form:
// CASE
// WHEN boolean_expression_1 THEN result_expression_1
// WHEN boolean_expression_2 THEN result_expression_2
// ...
// WHEN boolean_expression_n THEN result_expression_n
// [ELSE else_expression]
// END
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeCase = class (TSQLMemExprNodeVarcharResultFunction)
   private
    FSimpleForm:          Boolean;
    FElseExists:          Boolean;
    FNumWhen:             Integer;
   protected
    function IsChildMustBeSkippedByDetectType(ChildNo: Integer): Boolean; override;
   public
    constructor Create(
                       aParentExpr:   TSQLMemExpression;
                       aSimpleForm:   Boolean;
                       aNumWhen:      Integer;
                       NodeList:      TSQLMemList
                      ); overload;
    // return Data Value
    function GetDataValue: TSQLMemVariant; override;
    // return Data Size
    function GetDataSize: Integer;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // must return false
    function HasNullValues: Boolean; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
  end; // TSQLMemExprNodeCase




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeArithmetic
//
// arithmetic operations - Sub, Add, Mul, Div, Abs...
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeArithmetic = class(TSQLMemExprNode)
   private
    FPriorValue: TSQLMemVariant; // for CUMSUM, CUMPROD, GROUP_CONCAT
   protected
    // SUB operation
    procedure SubData;
    // ADD operation
    procedure AddData;
    // MUL operation
    procedure MulData;
    // DIV operation
    procedure DivData;
    // ABS operation
    procedure AbsData;
    // CEILING operation
    procedure CeilingData;
    // FLOOR operation
    procedure FloorData;
    // MOD operation
    procedure ModData;
    // POWER operation
    procedure PowerData;
    // RAND operation
    procedure RandomData;
    // ROUND operation
    procedure RoundData;
    // SIGN operation
    procedure SignData;
    // TRUNCATE operation
    procedure TruncateData;

    // AND operation
    procedure AndData;
    // OR operation
    procedure OrData;
    // NOT operation
    procedure NotData;
    // SHL operation
    procedure ShlData;
    // SHR operation
    procedure ShrData;
    // XOR operation
    procedure XorData;
    // HEX operation
    procedure HexData;
    // CUMSUM function
    procedure CumSumData;
    // CUMPROD function
    procedure CumProdData;
    // EXP function
    procedure ExpData;
    // LOG / LN function
    procedure LogData;
    // LOG10 function
    procedure Log10Data;
    // COS function
    procedure CosData;
    // SIN function
    procedure SinData;
    // ACOS function
    procedure AcosData;
    // ASIN function
    procedure AsinData;
    // ATAN function
    procedure AtanData;
    // ATAN2 function
    procedure Atan2Data;
    // COT function
    procedure CotData;
    // TAN function
    procedure TanData;
    // SQR function
    procedure SqrData;
    // SQRT function
    procedure SqrtData;
    // DEGREES function
    procedure DegreesData;
    // RADIANS function
    procedure RadiansData;
    // PI function
    procedure PiData;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
    // Constructors
    constructor Create(
                       aParentExpr: TSQLMemExpression;
                       Op:          TSQLMemDataOperator;
                       Node:        TSQLMemExprNode
                      ); overload;
    // Destructor
    destructor Destroy; override;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeAggregated
//
// aggregated functions - SUM, AVG, COUNT, COUNT_ALL, MIN, MAX, GROUP_CONCAT
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeAggregated = class(TSQLMemExprNode)
   private
    count:                      Integer;
    xm:                         Double;
    distinct:                   Boolean;
    desc:                       Boolean;
    AvgSum:                     TSQLMemVariant;
    FTempTable:                 TDataset;
    FGroupConcatSeparatorAnsi:  AnsiString;
    FGroupConcatSeparatorWide:  WideString;
   public
    // Constructors
    constructor Create(
                       aParentExpr: TSQLMemExpression;
                       Op:          TSQLMemDataOperator
                      ); overload;
    constructor Create(
                       aParentExpr: TSQLMemExpression;
                       Op:          TSQLMemDataOperator;
                       aDistinct:   Boolean;
                       Node:        TSQLMemExprNode;
                       aDesc:       Boolean = false
                      ); overload;
    constructor Create(
                       aParentExpr: TSQLMemExpression;
                       Op:          TSQLMemDataOperator;
                       aDistinct:   Boolean;
                       Node1:       TSQLMemExprNode;
                       Node2:       TSQLMemExprNode;
                       aDesc:       Boolean = false
                      ); overload;
    // Destructor
    destructor Destroy; override;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // is expression contains aggregated function
    function IsAggregated: Boolean; override;
    // is expression contains aggregated function COUNT(*)
    function IsCountAll: Boolean; override;
    // Init for aggregated functions
    procedure Init; override;
    // Accumulate for group functions
    procedure Accumulate(Increment: Integer = 1); override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end;


  

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeCast
//
// Cast operator - converts data types
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeCast = class(TSQLMemExprNode)
  private
    FCastType: TSQLMemAdvancedFieldType;  // Type for conversion
   public
    constructor Create(
                        aParentExpr:  TSQLMemExpression;
                        Node:         TSQLMemExprNode;
                        CastType:     TSQLMemAdvancedFieldType;
                        SizeNode:     TSQLMemExprNode = nil
                      ); overload;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end; // TSQLMemExprNodeCast




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeStringFunction
//
// expression node IsNull function
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeStringFunction = class(TSQLMemExprNode)
   private
    FTrimType:        TSQLMemTrimType;
    FConcatDataSize:  Integer;
    FConcatDataType:  TSQLMemAdvancedFieldType;
   protected
    function InitStringValue: Boolean;
   protected
    procedure Concat;
    procedure Upper;
    procedure Lower;
    procedure TrimA;
    procedure TrimW;
    procedure Trim;
    procedure LTrim;
    procedure RTrim;
    procedure Length;
    procedure Pos;
    procedure SUBString;
   public
    procedure DetectConcatResultType(bForceDetect: Boolean = False);
  protected
    procedure ASCII;
    procedure CHR;
    procedure FuncRepeat;
    procedure FuncReplace;
   public
    constructor Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       Node1, Node2:    TSQLMemExprNode;
                       aTrimType:       TSQLMemTrimType;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                       ); overload;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
  end;


  TSQLMemExprNodeSystem = class(TSQLMemExprNode)
   private
    FSessionName:    AnsiString;
    FDatabaseName:   AnsiString;
    FTableName:      WideString;
    FColumnName:     WideString;
    FInMemory:       Boolean;
    FTable:          TDataSet;
    FFieldType:      TSQLMemAdvancedFieldType;
   private
    procedure LastAutoInc;
   public
    // creates
    constructor Create(
                       aParentExpr:  TSQLMemExpression;
                       Operator:     TSQLMemDataOperator;
                       TableName:    WideString;
                       ColumnName:   WideString;
                       InMemory:     Boolean;
                       SessionName:  AnsiString;
                       DatabaseName: AnsiString); overload;
    // Destructor
    destructor Destroy; override;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeDateFunction - TODATE / TOSTRING
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeDateFunction = class(TSQLMemExprNode)
   private
    DateFormater: TDateFormater;
    // ToDate
    procedure ToDate;
    // TOString
    procedure TOString;
    // extract part from date or time value
    procedure Extract;
   public
    // Constructor
    constructor Create(
                       aParentExpr:  TSQLMemExpression;
                       Op:           TSQLMemDataOperator;
                       Node:         TSQLMemExprNode = nil;
                       FormatStr:    WideString = ''
                      ); overload;
    // Destructor
    destructor Destroy; override;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end; // TSQLMemExprNodeDateFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeDateAddFunction - DATEADD
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeDateAddFunction = class(TSQLMemExprNode)
   private
    FDatePart:  TSQLMemDatePart;
    FNumber:    TSQLMemExprNode;
    FDate:      TSQLMemExprNode;
   public
    constructor Create(
                         aParentExpr:           TSQLMemExpression;
                         DatePart:              TSQLMemDatePart;
                         Number:                TSQLMemExprNode;
                         Date:                  TSQLMemExprNode
                       );
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end; // TSQLMemExprNodeDateAddFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeDateDiffFunction - DATEDIFF
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeDateDiffFunction = class(TSQLMemExprNode)
   private
    FDatePart:    TSQLMemDatePart;
    FStartDate:   TSQLMemExprNode;
    FEndDate:         TSQLMemExprNode;
   public
    constructor Create(
                         aParentExpr:           TSQLMemExpression;
                         DatePart:              TSQLMemDatePart;
                         StartDate,
                         EndDate:               TSQLMemExprNode
                      );
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
  end; // TSQLMemExprNodeDateDiffFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeBLOBFunction
//
// TOBLOB function - converts Ansi string  (MIME64, HEX) to binary data
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeBLOBFunction = class(TSQLMemExprNode)
   public
    // Constructor
    constructor Create(
                       aParentExpr:           TSQLMemExpression;
                       Op:                    TSQLMemDataOperator;
                       const BLOBValue:       AnsiString;
                       const BLOBValueFormat: TSQLMemBLOBValueFormat
                      ); overload;
    // Return Data Value
    function GetDataValue: TSQLMemVariant;  override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
  end; // TSQLMemExprNodeBLOBFunction

// get operator name
function GetOperatorName(op: TSQLMemDataOperator): AnsiString;

// return FieldType
function GetFieldType(const TypeName: AnsiString): TSQLMemAdvancedFieldType;
// return SQL field name
function GetFieldTypeSQLName(AdvFieldType: TSQLMemAdvancedFieldType): AnsiString;

function IsPartialKey(Node: TSQLMemExprNode): integer;
// return information about the operand
function SQLMemGetOperand(Node: TSQLMemExprNode): String;

implementation

uses  SQLMemMain,
      SQLMemSQLProcessor,
      SQLMemLocalEngine,
      SQLMemStoredFunctions,
      SQLMemMemory // last
      , Math;

//------------------------------------------------------------------------------
// get operator name
//------------------------------------------------------------------------------
function GetOperatorName(op: TSQLMemDataOperator): AnsiString;
begin
  case op of
    doNOT:          Result := 'NOT';
    doAND:          Result := 'AND';
    doOR:           Result := 'OR';
    doEQ:           Result := '=';
    doNE:           Result := '<>';
    doLT:           Result := '<';
    doGT:           Result := '>';
    doLE:           Result := '<=';
    doGE:           Result := '>=';
    doLIKE:         Result := 'LIKE';
    doNOTLIKE:      Result := 'NOT LIKE';
    doISNULLFUNCTION: Result := 'ISNULL';
    doISNULL:       Result := 'IS NULL';
    doISNOTNULL:    Result := 'IS NOT NULL';
    doADD:          Result := '+';
    doSUB:          Result := '-';
    doMUL:          Result := '*';
    doDIV:          Result := '/';
    doCONCAT:       Result := '||';
    doUPPER:        Result := 'UPPER';
    doLOWER:        Result := 'LOWER';
    doTRIM:         Result := 'TRIM';
    doLTRIM:        Result := 'LTRIM';
    doRTRIM:        Result := 'RTRIM';
    doSUM:          Result := 'SUM';
    doAVG:          Result := 'AVG';
    doMIN:          Result := 'MIN';
    doMAX:          Result := 'MAX';
    doCOUNT:        Result := 'COUNT';
    doCOUNTALL:     Result := 'COUNT(*)';
    doCUMSUM:       Result := 'CUMSUM';
    doCUMPROD:      Result := 'CUMPROD';
    doGROUP_CONCAT: Result := 'GROUP_CONCAT';
    doYEAR:         Result := 'YEAR';
    doQUARTER:      Result := 'QUARTER';
    doISOWEEK:      Result := 'ISOWEEK';
    doWEEK:         Result := 'WEEK';
    doDAY:          Result := 'DAY';
    doWEEKDAY:      Result := 'WEEKDAY';
    doDAYOFWEEK:    Result := 'DAYOFWEEK';
    doDAYOFYEAR:    Result := 'DAYOFYEAR';
    doHOUR:         Result := 'HOUR';
    doMINUTE:       Result := 'MINUTE';
    doSECOND:       Result := 'SECOND';
    doMSECOND:      Result := 'MSECOND';
    doSTDDEV:       Result := 'STDDEV';
    doASCII:        Result := 'ASCII';
    doCHR:          Result := 'CHR';
    doREPEAT:       Result := 'REPEAT';
    doREPLACE:      Result := 'REPLACE';
    doEXP:          Result := 'EXP';
    doLOG:          Result := 'LOG';
    doLOG10:        Result := 'LOG10';
    doCOS:          Result := 'COS';
    doSIN:          Result := 'SIN';
    doACOS:         Result := 'ACOS';
    doASIN:         Result := 'ASIN';
    doATAN:         Result := 'ATAN';
    doATAN2:        Result := 'ATAN2';
    doCOT:          Result := 'COT';
    doTAN:          Result := 'TAN';
    doSQR:          Result := 'SQR';
    doSQRT:         Result := 'SQRT';
    doDEGREES:      Result := 'DEGREES';
    doRADIANS:      Result := 'RADIANS';
    doPI:           Result := 'PI'
    else            Result:='unknown';
  end;
end;//GetOperatorName


//------------------------------------------------------------------------------
// Return FieldType
//------------------------------------------------------------------------------
function GetFieldType(const TypeName: AnsiString): TSQLMemAdvancedFieldType;
var
  i: Integer;
  s: AnsiString;
begin
  Result := aftUnknown;
  s := AnsiUpperCase(TypeName);
  for i := Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].SqlName = s then
      begin
        Result := SQLFieldTypes[i].AdvancedFieldType;
        break;
      end;
end;//GetFieldType


//------------------------------------------------------------------------------
// return SQL field name
//------------------------------------------------------------------------------
function GetFieldTypeSQLName(AdvFieldType: TSQLMemAdvancedFieldType): AnsiString;
var
  i: Integer;
begin
  Result := '';
  for i := Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].AdvancedFieldType = AdvFieldType then
     begin
      Result := SQLFieldTypes[i].SqlName;
      break;
     end;
end; // GetFieldTypeSQLDefinition




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExpression
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// gets next token
//------------------------------------------------------------------------------
function TSQLMemExpression.GetNextToken: Boolean;
begin
 Result := LLex.GetNextToken(Token);
end;// GetNextToken


//------------------------------------------------------------------------------
// gets token and looks at next token with check for token type restrictions
//------------------------------------------------------------------------------
function TSQLMemExpression.GetNextToken(PermittedTypes: TTokenTypes;
                                      RaiseExceptions: Boolean = False): Boolean;
begin
  // get next token
  Result := LLex.GetNextToken(Token);
  if (not Result) then
   if (RaiseExceptions) then
      raise ESQLMemException.Create(30063, ErrorGUnexpectedEndOfCommand,
                                 [Token.LineNum, Token.ColumnNum]);
  // check token type
  if (Result) then
   if ((PermittedTypes <> [])) then
    if not (Token.TokenType in PermittedTypes) then
      if (RaiseExceptions) then
        raise ESQLMemException.Create(30064, ErrorGUnexpectedToken,
                                   [Token.Text, Token.LineNum, Token.ColumnNum])
      else
         Result := False;
end;// GetNextToken


//------------------------------------------------------------------------------
// saves internal state (to restore in case of not successful forward parsing)
//------------------------------------------------------------------------------
procedure TSQLMemExpression.SaveState(var SavedTokenNo: integer);
//  var SavedRootNode: TSQLMemExprNode);
begin
 // save token No
 SavedTokenNo := LLex.GetCurrentTokenNo;
 // save root node
 //SavedRootNode := FRootNode;
end;// SaveState


//------------------------------------------------------------------------------
// restores internal state (in case of not successful forward parsing)
//------------------------------------------------------------------------------
procedure TSQLMemExpression.RestoreState(SavedTokenNo: integer);
//  SavedRootNode: TSQLMemExprNode);
begin
 // restore token No
 LLex.SetCurrentTokenNo(SavedTokenNo, Token);
 // restore root node
 //FRootNode.DeleteTo(SavedRootNode);
 //FRootNode := SavedRootNode;
end;// RestoreState


{$IFNDEF EXPR_PARSING_1}
//------------------------------------------------------------------------------
// parses <,>,=,<>,>=,<=
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCompOp: TSQLMemDataOperator;
var
    SavedTokenNo: Integer;
begin
  Result := doUNDEFINED;
  SaveState(SavedTokenNo);
  // fix added in 5.90 to solve problem in subquery : (SELECT ... WHERE ....) > n
  if (Token.TokenType = tktRightParenthesis) and (FNumLeftParenthesis > 0) then
   Exit;
  while ((Token.TokenType = tktLeftParenthesis) or
         (Token.TokenType = tktRightParenthesis)) do
   begin
     if (token.TokenType = tktLeftParenthesis) then
      begin
        Inc(FNumLeftParenthesis);
        GetNextToken;
      end;
     if (token.TokenType = tktRightParenthesis) then
      begin
        Inc(FNumRightParenthesis);
        GetNextToken;
      end;
   end;
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
   Result := doGE;

  if (Result = doUNDEFINED) then
   RestoreState(SavedTokenNo)
  else
   GetNextToken;

  // added in 4.95 to make
  // = NULL same as IS NULL
  // <> NULL same as IS NOT NULL
  // "" -> NULL
  if ((Result = doNE) or (Result = doEQ)) then
   if (IsReservedWord(Token,rwNULL) or (IsEmptyString(Token))) then
    begin
     if (Result = doEQ) then
      Result := doISNULL
     else
      Result := doISNOTNULL;
//     GetNextToken;
    end;
end;// ParseCompOp


//------------------------------------------------------------------------------
// parses <row value constructor element>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseRowValueConstructorElement: TSQLMemExprNode;
begin
  Result := ParseNullConst;
  if (Result = nil) then
    Result := ParseValueExpression;
end;// ParseRowValueConstructorElement


//------------------------------------------------------------------------------
// parses <row value constructor element> | <row subquery>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseRowValueConstructor: TSQLMemExprNode;
begin
 Result := ParseRowValueConstructorElement;
end;// ParseRowValueConstructor


//------------------------------------------------------------------------------
// parses <row value constructor> <comp op> <row value constructor>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseComparisonPredicate(Node: TSQLMemExprNode): TSQLMemExprNode;
var
  LeftNode, RightNode:  TSQLMemExprNode;
  CompOp:               TSQLMemDataOperator;
  pk, bNot:             Boolean;
  token1:               TToken;
begin
 RightNode := nil;
 Result := nil;
 // parse <row value constructor>
 if (Node = nil) then
   LeftNode := ParseRowValueConstructor
 else
   LeftNode := Node;
 if (LeftNode <> nil) then
  begin
   try
     // <,>,=,<>,>=,<=
     CompOp := ParseCompOp;
     // parse 2nd <row value constructor>
     if (CompOp <> doUndefined) then
      begin
  {$IFDEF CORRELATED_SUBQUERIES}
       if (IsReservedWord(Token,rwNOT)) then
       begin
        if (LLex.LookNextToken(token1)) then
        begin
         if (token1.ReservedWord in [rwANY,rwSOME,rwALL]) then
         begin
          GetNextToken;
          bNot := True;
         end;
        end;
       end
       else
        bNot := False;
       if (IsReservedWord(Token,rwANY) or IsReservedWord(Token,rwSOME)) then
       begin
         GetNextToken;
         Result := ParseSubQuery(doSubQueryANY,bNot,LeftNode,CompOp);
       end
       else
       if (IsReservedWord(Token,rwALL)) then
       begin
         GetNextToken;
         Result := ParseSubQuery(doSubQueryALL,bNot,LeftNode,CompOp);
       end
       else
       begin
  {$ENDIF}
         RightNode := ParseRowValueConstructor;
         if (RightNode <> nil) then
          begin
            pk := False;
           // Detect Partial Key
           if FPartialKey then
            pk := (IsPartialKey(LeftNode) + IsPartialKey(RightNode) > 0);
           // create <CompOp> node
           Result := TSQLMemExprNodeComparison.Create(Self, CompOp, LeftNode, RightNode,
                                                 F3ValueLogic, FCaseInsensitive, pk);

          end
         else
          begin
//           if (not (LeftNode is TSQLMemExprNodeComparison)) and (not (LeftNode is TSQLMemExprNodeBoolean)) then
           if (LeftNode <> nil) and (LeftNode <> Node) then
            FreeAndNil(LeftNode);
           Result := nil;
          end;
  {$IFDEF CORRELATED_SUBQUERIES}
       end; // Comparison
  {$ENDIF}
      end
     else
      begin

//       if (not (LeftNode is TSQLMemExprNodeComparison)) and (not (LeftNode is TSQLMemExprNodeBoolean)) then
        if (LeftNode <> nil) and (LeftNode <> Node) then
          FreeAndNil(LeftNode);
        Result := nil;
//       Result := LeftNode;
      end;
    except
     if (LeftNode <> nil) and (LeftNode <> Node) then
      FreeAndNil(LeftNode);
     if (RightNode <> nil) then
      FreeAndNil(RightNode);
     raise;
    end;
  end; // LeftNode parsed
end;// ParseComparisonPredicate


//------------------------------------------------------------------------------
// parses <boolean factor> | <boolean term> AND <boolean factor>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBooleanTerm(Node: TSQLMemExprNode = nil): TSQLMemExprNode;
var
  aNode,RightNode:    TSQLMemExprNode;
  CompOp:             TSQLMemDataOperator;
  pk,bAnd,bNot:       Boolean;
  token1:             TToken;
begin
 Result := nil;
 // parse <boolean factor>
{$IFDEF EXPR_PARSING_1}
  aNode := Node;
{$ELSE}
 if (Node = nil) then
   aNode := ParseBooleanFactor
 else
   aNode := Node;
{$ENDIF}
 if (aNode <> nil) then
  begin
   // added in v.5.90
   // { OR <boolean term> }
   // { AND <boolean term> }
   if (
       IsReservedWord(Token, rwAND) or (Token.Text = '&&') or
       IsReservedWord(Token, rwOR) or (Token.Text = '||')
      ) then
    begin
     if IsReservedWord(Token, rwAND) or (Token.Text = '&&') then
      Result := TSQLMemExprNodeBoolean.Create(Self, doAND, aNode)
     else
      Result := TSQLMemExprNodeBoolean.Create(Self, doOR, aNode);
     while (
       IsReservedWord(Token, rwAND) or (Token.Text = '&&') or
       IsReservedWord(Token, rwOR) or (Token.Text = '||')
           ) do
      begin
        bAnd := IsReservedWord(Token, rwAND) or (Token.Text = '&&');
        // skip 'AND' token
        GetNextToken;
        // parse <boolean factor>
        {$IFDEF EXPR_PARSING_1}
        aNode := ParseValueExpression;
        {$ELSE}
        aNode := ParseBooleanFactor;
        {$ENDIF}
        if (aNode = nil) then
         raise ESQLMemException.Create(30069, ErrorGBooleanExpressionExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
        // add into <AND> node
        if ((Result.Operator = doAND) and bAnd) or
           ((Result.Operator = doOR) and (not bAnd))
           then
         Result.Children.Add(aNode)
        else
        begin
         if (bAnd) then
          Result := TSQLMemExprNodeBoolean.Create(Self, doAND, Result)
         else
          Result := TSQLMemExprNodeBoolean.Create(Self, doOR, Result);
         Result.Children.Add(aNode);
        end;
      end;
    end
   else
    begin
     // ---  added in v.5.50
     // <,>,=,<>,>=,<=
     CompOp := ParseCompOp;
     // parse 2nd <row value constructor>
     if (CompOp <> doUndefined) then
      begin
  {$IFDEF CORRELATED_SUBQUERIES}
       if (IsReservedWord(Token,rwNOT)) then
       begin
        if (LLex.LookNextToken(token1)) then
        begin
         if (token1.ReservedWord in [rwANY,rwSOME,rwALL]) then
         begin
          GetNextToken;
          bNot := True;
         end;
        end;
       end
       else
        bNot := False;
       if (IsReservedWord(Token,rwANY) or IsReservedWord(Token,rwSOME)) then
       begin
         GetNextToken;
         Result := ParseSubQuery(doSubQueryANY,bNot,aNode,CompOp);
       end
       else
       if (IsReservedWord(Token,rwALL)) then
       begin
         GetNextToken;
         Result := ParseSubQuery(doSubQueryALL,bNot,aNode,CompOp);
       end
       else
       begin
  {$ENDIF}
         {$IFDEF EXPR_PARSING_1}
         RightNode := ParseValueExpression;
         {$ELSE}
         RightNode := ParseRowValueConstructor;
         {$ENDIF}
         if (RightNode <> nil) then
          begin
            pk := False;
           // Detect Partial Key
           if FPartialKey then
            pk := (IsPartialKey(aNode) + IsPartialKey(RightNode) > 0);
           // create <CompOp> node
           Result := TSQLMemExprNodeComparison.Create(Self, CompOp, aNode, RightNode,
                                                 F3ValueLogic, FCaseInsensitive, pk);

          end
         else
          begin
{
           if (not (aNode is TSQLMemExprNodeComparison)) and (not (aNode is TSQLMemExprNodeBoolean)) then
             if (aNode <> nil) and (aNode <> Node) then
              FreeAndNil(aNode);
}
           Result := aNode;
          end;
  {$IFDEF CORRELATED_SUBQUERIES}
       end; // Comparison
  {$ENDIF}
      end
     else
      begin
{
       if (not (aNode is TSQLMemExprNodeComparison)) and (not (aNode is TSQLMemExprNodeBoolean)) then
        if (aNode <> nil) and (aNode <> Node) then
          FreeAndNil(aNode);
}
       Result := aNode;
      end;
    end;
  end;
end;// ParseBooleanTerm


//------------------------------------------------------------------------------
// parses <match value> [ NOT ] LIKE <pattern> [ ESCAPE <escape character> ]
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseLikePredicate(Node: TSQLMemExprNode): TSQLMemExprNode;
var
  aNode, LeftNode, RightNode: TSQLMemExprNode;
  bNot: Boolean;
begin
 Result := nil;
 // parse <character value expression>
{$IFDEF EXPR_PARSING_1}
  LeftNode := Node;
{$ELSE}
 if (Node = nil) then
   LeftNode := ParseRowValueConstructor
 else
   LeftNode := Node;
{$ENDIF}   
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
     {$IFDEF EXPR_PARSING_1}
     RightNode := ParseValueExpression;
     {$ELSE}
     RightNode := ParseRowValueConstructor;
     {$ENDIF}
     if (not bNot) then
       aNode := TSQLMemExprNodeBoolean.Create(Self,doLIKE,FCaseInsensitive,FPartialKey)
     else
       aNode := TSQLMemExprNodeBoolean.Create(Self,doNOTLIKE,FCaseInsensitive,FPartialKey);
     aNode.Children.Add(LeftNode);
     aNode.Children.Add(RightNode);
     Result := aNode;
    end
   else
    begin
      if (LeftNode <> nil) and (LeftNode <> Node) then
       FreeAndNil(LeftNode);
    end;
  end;
end;// ParseLikePredicate


//------------------------------------------------------------------------------
// parses <row value constructor> IS [ NOT ] NULL | UNKNOWN | TRUE | FALSE
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseNullPredicate(Node: TSQLMemExprNode): TSQLMemExprNode;
var
  LeftNode: TSQLMemExprNode;
  bNot: Boolean;
  bOK: Boolean;
begin
 // parse <row value constructor>
{$IFDEF EXPR_PARSING_1}
  LeftNode := Node;
{$ELSE}
 if (Node = nil) then
   LeftNode := ParseRowValueConstructor
 else
   LeftNode := Node;
{$ENDIF}
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
{$IFDEF EXPR_PARSING_1}
     // NULL
     if (IsReservedWord(Token, rwNULL)) then
      begin
       // skip token NULL
       GetNextToken;
       if (not bNot) then
        LeftNode := TSQLMemExprNodeBoolean.Create(Self,doISNULL, LeftNode)
       else
        LeftNode := TSQLMemExprNodeBoolean.Create(Self,doISNOTNULL, LeftNode);
       bOk := True;
      end
     else
      if (IsReservedWord(Token,rwFALSE) or IsReservedWord(Token,rwTRUE)) then
      begin
       if (IsReservedWord(Token,rwFALSE)) then
        bNot := not bNot;
       if (bNot) then
        LeftNode := TSQLMemExprNodeBoolean.Create(Self,doNOT, LeftNode);
      end
     else
      raise ESQLMemException.Create(30067, ErrorGOtherTokenExpected,
         ['TRUE, FALSE, NULL or UNKNOWN', Token.Text, Token.LineNum, Token.ColumnNum]);
{$ELSE}
     // NULL
     if (IsReservedWord(Token, rwNULL)) then
      begin
       // skip token NULL
       GetNextToken;
       if (not bNot) then
        LeftNode := TSQLMemExprNodeBoolean.Create(Self,doISNULL, LeftNode)
       else
        LeftNode := TSQLMemExprNodeBoolean.Create(Self,doISNOTNULL, LeftNode);
       bOk := True;
      end;
{$ENDIF}
    end; // IS
  end;
 if (not bOK) then
  begin
    if (LeftNode <> nil) and (LeftNode <> Node) then
     LeftNode.Free;
    LeftNode := nil;
  end;
 Result := LeftNode;
end;// ParseNullPredicate


//------------------------------------------------------------------------------
// parses <between predicate>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBetweenPredicate(Node: TSQLMemExprNode): TSQLMemExprNode;
var
  arg1, arg2, arg3: TSQLMemExprNode;
  bNot: boolean;
begin
{
<between predicate> ::=
    <row value constructor> [ NOT ] BETWEEN
      <row value constructor> AND <row value constructor>
}
 Result := nil;
 arg2:=nil;
 arg3:=nil;
{$IFDEF EXPR_PARSING_1}
  arg1 := Node;
{$ELSE}
 if (Node = nil) then
   arg1 := ParseRowValueConstructor
 else
   arg1 := Node;
{$ENDIF}
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
     {$IFDEF EXPR_PARSING_1}
     arg2 := ParseValueExpression;
     {$ELSE}
     arg2 := ParseRowValueConstructor;
     {$ENDIF}
     if arg2 <> nil then
      begin
       // AND
       if (IsReservedWord(Token, rwAND)) then
        begin
         // get next token
         GetNextToken;
         {$IFDEF EXPR_PARSING_1}
         arg3 := ParseValueExpression;
         {$ELSE}
         arg3 := ParseRowValueConstructor;
         {$ENDIF}
         if arg3 <> nil then
          if bNot then
           Result := TSQLMemExprNodeBoolean.Create(Self,doNOTBETWEEN, arg1, arg2, arg3)
          else
           Result := TSQLMemExprNodeBoolean.Create(Self,doBETWEEN, arg1, arg2, arg3);
        end;
      end
    end;
  end;
 if Result = nil then
  begin
   if (arg1 <> nil) and (arg1 <> Node) then arg1.Free;
   if arg2 <> nil then arg2.Free;
   if arg3 <> nil then arg3.Free;
  end;
end;//ParseBetWeenPredicate


//------------------------------------------------------------------------------
// parses <in predicate>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseInPredicate(Node: TSQLMemExprNode): TSQLMemExprNode;
var
  bNot:         Boolean;
  arg1:         TSQLMemExprNode;
  SavedTokenNo: Integer;
begin
{
<in predicate> ::=
    <row value constructor>
      [ NOT ] IN <in predicate value>
}
  Result := nil;
{$IFDEF EXPR_PARSING_1}
  arg1 := Node;
{$ELSE}
  if (Node = nil) then
    arg1 := ParseRowValueConstructor
  else
    arg1 := Node;
{$ENDIF}    
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
{$IFDEF CORRELATED_SUBQUERIES}
      Result := ParseSubQuery(doSubQueryIN,bNot,arg1);
{$ELSE}
      Result := ParseSubQuery(False,True,bNot,arg1);
{$ENDIF}
      // '(' ?
      if (Result = nil) then
       begin
        RestoreState(SavedTokenNo);
        // '(' ?
        if (Token.TokenType = tktLeftParenthesis) then
         begin
          // get next token
          GetNextToken;
          if bNot then
            Result := TSQLMemExprNodeBoolean.Create(Self,doNOTIN, arg1)
          else
            Result := TSQLMemExprNodeBoolean.Create(Self,doIN, arg1);
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
          GetNextToken;
         end;
       end; // not a Subquery
     end;

    if (Result = nil) and (arg1 <> nil) and (arg1 <> Node) then
     begin
      arg1.Free;
     end;
   end;
end;//ParseInPredicate
{$ENDIF}


//------------------------------------------------------------------------------
// parses <Exists predicate>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseExistsPredicate: TSQLMemExprNode;
var
  bNot:           Boolean;
  SavedTokenNo:   Integer;
begin
{
<Exists predicate> ::=
      [ NOT ] EXISTS (<subquery>)
}
  Result := nil;
  SaveState(SavedTokenNo);
  try
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
{$IFDEF CORRELATED_SUBQUERIES}
        Result := ParseSubQuery(doSubQueryEXISTS,bNot);
{$ELSE}
        Result := ParseSubQuery(True,False,bNot);
{$ENDIF}
     end
  finally
    if (Result = nil) then
     RestoreState(SavedTokenNo);
  end;
end; // ParseExistsPredicate


//------------------------------------------------------------------------------
// parses <true/false>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseTrueFalseConst: TSQLMemExprNode;
begin
 Result := nil;
 if Token.ReservedWord in [rwTRUE, rwFALSE] then
   begin
     Result := TSQLMemExprNodeConst.Create(Self);
     Result.Value.AsBoolean := (Token.ReservedWord = rwTRUE);
     GetNextToken;
   end
 else if (Token.TokenType = tktParameter) then
   begin
     if (Token.ParamValue.DataType = bftLogical) then
       begin
         Result := TSQLMemExprNodeConst.Create(Self);
         Result.IsParameter := True;
         Result.ParamCRC := GetTableNameCRC(Token.Text);
         Result.Value.Assign(Token.ParamValue);
         GetNextToken;
       end;
   end
end;//ParseTrueFalseConst


//------------------------------------------------------------------------------
// parses NULL const
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseNullConst: TSQLMemExprNode;
begin
 if Token.ReservedWord = rwNULL then
   begin
     Result := TSQLMemExprNodeConst.Create(Self);
     Result.Value.DataType := bftSignedInt32;
     GetNextToken;
   end
 else
   Result := nil;
end;//ParseNullConst


{$IFDEF EXPR_PARSING_1}
//------------------------------------------------------------------------------
// parses <value expression>
// totally rewritten in v.5.90 to parse any valid expresions with parenthesises and without it
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseValueExpression(
                                  ParseOperators:   Boolean = True;
                                  bStart:           Boolean = True;
                                  bParseConcatOnly: Boolean = False
                                 ): TSQLMemExprNode;
var
    SavedTokenNo:           Integer;        // saved/restored information
    op1,op2:                TSQLMemDataOperator;
    node1,node2,node3:      TSQLMemExprNode;
    prior1,prior2,cont:     Byte;
    bNot,bOK:               Boolean;
{$IFDEF EXPR_PARSING_1}
    FNumLeftParenthesis:    Integer;
    FNumRightParenthesis:   Integer;
{$ENDIF}
begin
  // totally rewritten in v.5.90 to parse any valid expresions with parenthesises and without it
{$IFDEF EXPR_PARSING_1}
  FNumLeftParenthesis := 0;
  FNumRightParenthesis := 0;
{$ENDIF}
  cont := 0;
  Result := nil;
  node1 := nil;
  node2 := nil;
  node3 := nil;
  bNot := False;
  try
    SaveState(SavedTokenNo);
    if (Token.TokenType = tktRightParenthesis) then
      Exit;
    if (ParseOperators) then
    begin
      while (true) do
      begin
        if (cont = 0) then
        begin
          // parse node1
          if (Token.TokenType = tktLeftParenthesis) then
          begin
            if (not GetNextToken) then
              raise ESQLMemException.Create(12524,ErrorGExpressionExpected,
                [Token.Text,Token.LineNum,Token.ColumnNum]);
            Inc(FNumLeftParenthesis);
            // parse with operators inside the parenthesises
            if (node1 = nil) then
              node1 := ParseValueExpression(True,False);
          end
          else
            // parse without operators
            if (node1 = nil) then
              node1 := ParseValueExpression(False,False);
          if (node1 = nil) then
          begin
           if (bStart) then
            raise ESQLMemException.Create(12525,ErrorGExpressionExpected,
              [Token.Text,Token.LineNum,Token.ColumnNum])
           else
            break;
          end;
          while ((Token.TokenType = tktRightParenthesis) and
                 (FNumRightParenthesis < FNumLeftParenthesis)) do
          begin
            Inc(FNumRightParenthesis);
            if (not GetNextToken) then
             break;
          end;
          op1 := ParseOperator;
        end;
        if (op1 = doUNDEFINED) or
           (bParseConcatOnly and (not SQLMemIsOperatorSign(Token,'+')) and (not SQLMemIsOperatorSign(Token,'||'))) then
        begin
         Result := node1;
         break;
        end
        else
        begin
         if (cont = 0) then
         begin
            // get next token and parse node2
            if (not GetNextToken) then
            begin
             Result := MakeOperator(node1,nil,op1);
             break;
            end;
            while ((Token.TokenType = tktRightParenthesis) and
                   (FNumRightParenthesis < FNumLeftParenthesis)) do
            begin
              Inc(FNumRightParenthesis);
              if (not GetNextToken) then
               break;
            end;
            while ((Token.TokenType = tktRightParenthesis) and
                   (FNumRightParenthesis < FNumLeftParenthesis)) do
            begin
               Inc(FNumRightParenthesis);
               if (not GetNextToken) then
                break;
            end;
           // parse node2
           if (Token.TokenType = tktLeftParenthesis) then
           begin
            if (not GetNextToken) then
              raise ESQLMemException.Create(12535,ErrorGExpressionExpected,
                [Token.Text,Token.LineNum,Token.ColumnNum]);
            Inc(FNumLeftParenthesis);
            // parse with operators inside the parenthesises
            if (node2 = nil) then
              node2 := ParseValueExpression(True,False);
           end
           else
            // parse without operators
            if (node2 = nil) then
              node2 := ParseValueExpression(False,False);
           while ((Token.TokenType = tktRightParenthesis) and
                  (FNumRightParenthesis < FNumLeftParenthesis)) do
           begin
              Inc(FNumRightParenthesis);
              if (not GetNextToken) then
               break;
           end;
         end; // cont = 0
         if (node2 = nil) then
          Result := MakeOperator(node1,nil,op1)
         else
         begin
          op2 := ParseOperator;
          if (op2 = doUNDEFINED) or
             (bParseConcatOnly and (not SQLMemIsOperatorSign(Token,'+')) and (not SQLMemIsOperatorSign(Token,'||'))) then
          begin
           Result := MakeOperator(node1,node2,op1);
           break;
          end
          else
          begin
           if (not GetNextToken) then
           begin
            Result := MakeOperator(node1,node2,op1);
            break;
           end;
           while ((Token.TokenType = tktRightParenthesis) and
                  (FNumRightParenthesis < FNumLeftParenthesis)) do
           begin
              Inc(FNumRightParenthesis);
              if (not GetNextToken) then
               break;
           end;
           while ((Token.TokenType = tktRightParenthesis) and
                  (FNumRightParenthesis < FNumLeftParenthesis)) do
           begin
             Inc(FNumRightParenthesis);
             if (not GetNextToken) then
              break;
           end;
           prior1 := GetOperatorPriority(op1);
           prior2 := GetOperatorPriority(op2);
           // parse node3
           if (Token.TokenType = tktLeftParenthesis) then
           begin
             if (not GetNextToken) then
               raise ESQLMemException.Create(12536,ErrorGExpressionExpected,
                 [Token.Text,Token.LineNum,Token.ColumnNum]);
             Inc(FNumLeftParenthesis);
             // parse with operators inside the parenthesises
             if (node3 = nil) then
               node3 := ParseValueExpression(True,False);
           end
           else
             // parse without operators
             if (node3 = nil) then
               node3 := ParseValueExpression(False,False);
           while ((Token.TokenType = tktRightParenthesis) and
                  (FNumRightParenthesis < FNumLeftParenthesis)) do
           begin
              Inc(FNumRightParenthesis);
              if (not GetNextToken) then
               break;
           end;
           if (node3 = nil) then
           begin
            if (prior1 >= prior2) then
            begin
             // op1 has higher priority
             Result := MakeOperator(node1,node2,op1);
             Result := MakeOperator(Result,nil,op2);
            end
            else
            begin
             // op2 has higher priority
             Result := MakeOperator(node2,nil,op2);
             Result := MakeOperator(node1,Result,op1);
            end;
            break;
           end
           else
           begin
             // continue loop
             if (prior1 >= prior2) then
             begin
              // op1 has higher priority
              node1 := MakeOperator(node1,node2,op1);
              op1 := op2;
              node2 := node3;
              node3 := nil;
              cont := 1;
             end
             else
             begin
              // op2 has higher priority
              node2 := MakeOperator(node2,node3,op2);
              node3 := nil;
              cont := 2;
             end;
           end;
          end;
         end;
        end; // op1 parsed
      end; // parsing loop
      node1 := nil;
      node2 := nil;
      node3 := nil;
      if (FNumLeftParenthesis > FNumRightParenthesis) then
       raise ESQLMemException.Create(12518,ErrorGRightParenthesisExpected,
       [Token.Text,Token.LineNum,Token.ColumnNum]);
      if (FNumLeftParenthesis < FNumRightParenthesis) then
       raise ESQLMemException.Create(12519,ErrorGUnexpectedRightParenthesis,
       [Token.LineNum,Token.ColumnNum]);
    end // ParseOperators
    else
    begin
      // check Prefix Operators: <prefix operator> <expression>
      if (Token.ReservedWord = rwNOT) or (SQLMemIsOperatorSign(Token,'!')) then
      begin
       // NOT <boolean expression>
       if (not GetNextToken) then
        raise ESQLMemException.Create(12520,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
       if (Token.ReservedWord = rwEXISTS) then
       begin
        // NOT EXISTS (<Subquery>)
        RestoreState(SavedTokenNo);
        Result := ParseExistsPredicate; 
       end
       else
       begin
         Result := ParseValueExpression;
         if (Result <> nil) then
           Result := TSQLMemExprNodeBoolean.Create(Self,doNOT,Result,FCaseInsensitive,FPartialKey);
       end;
      end // NOT or ! - Boolean or Bitwise NOT
      else
      if (SQLMemIsOperatorSign(Token,'~')) then
      begin
       // NOT <expression>
       if (not GetNextToken) then
        raise ESQLMemException.Create(12521,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
       Result := ParseValueExpression;
       if (Result <> nil) then
         Result := TSQLMemExprNodeArithmetic.Create(Self,doBitwiseNOT,Result,FCaseInsensitive,FPartialKey);
      end // Bitwise NOT
      else
      if (SQLMemIsOperatorSign(Token,'+')) then
      begin
       // + <expression>
       if (not GetNextToken) then
        raise ESQLMemException.Create(12522,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
       Result := ParseValueExpression(ParseOperators,False);
      end // +
      else
      if (SQLMemIsOperatorSign(Token,'-')) then
      begin
       // - <expression>
       if (not GetNextToken) then
        raise ESQLMemException.Create(12523,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
       // parse n
       if (Token.TokenType = tktLeftParenthesis) then
       begin
         if (not GetNextToken) then
           raise ESQLMemException.Create(12537,ErrorGExpressionExpected,
             [Token.Text,Token.LineNum,Token.ColumnNum]);
         Inc(FNumLeftParenthesis);
         // parse with operators inside the parenthesises
         Result := ParseValueExpression(True,False);
       end
       else
         // parse without operators
         Result := ParseValueExpression(False,False);
       while ((Token.TokenType = tktRightParenthesis) and
              (FNumRightParenthesis < FNumLeftParenthesis)) do
       begin
          Inc(FNumRightParenthesis);
          if (not GetNextToken) then
           break;
       end;
       if (Result <> nil) then
         Result := TSQLMemExprNodeArithmetic.Create(Self,doSUB,Result,FCaseInsensitive,FPartialKey);
      end; // - <expression>
      // NULL const
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseNullConst;
      end;
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseTrueFalseConst;
      end;
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseBooleanValueExpression;
      end;
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseArithmeticValueExpression;
      end;
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseTextValueExpression;
      end;
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseDatetimeValueExpression;
      end;
      if (Result = nil) then
      begin
        RestoreState(SavedTokenNo);
        Result := ParseGeneralValueExpression;
      end;
    end;
    // finalizing
    if (Result = nil) then
    begin
      RestoreState(SavedTokenNo);
      if (bStart) then
       raise ESQLMemException.Create(12527,ErrorGExpressionExpected,
        [Token.Text,Token.LineNum,Token.ColumnNum]);
    end
    else
    begin
      SaveState(SavedTokenNo);
      // try to parse postfix / top priority operators :
      // IS [NOT] NULL, IS [NOT] TRUE, IS [NOT] FALSE
      // [NOT] IN
      // [NOT] BETWEEN
      // [NOT] LIKE
      // <comparison operator> [NOT] [ALL | SOMY | ANY ] (<SubQuery>)
      op1 := ParseOperator;
      if (op1 in [doISNULL,doISNOTNULL,doTRUE,doFALSE]) then
      begin
       Result := MakeOperator(Result,nil,op1);
       GetNextToken;
      end
      else
      if (op1 = doIN) or (op1 = doNOTIN) then
      begin
       GetNextToken;
       Result := ParseIn(Result,op1);
       if (Result = nil) then
        raise ESQLMemException.Create(12538,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
      end
      else
      if (op1 = doBETWEEN) or (op1 = doNOTBETWEEN) then
      begin
       GetNextToken;
       Result := ParseBetween(Result,op1);
       if (Result = nil) then
        raise ESQLMemException.Create(12539,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
      end
      else
      if (op1 = doLIKE) or (op1 = doNOTLIKE) then
      begin
       GetNextToken;
       Result := ParseLike(Result,op1);
       if (Result = nil) then
        raise ESQLMemException.Create(12540,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
      end
      else
      if (op1 in [doEQ,doNE,doLT,doGT,doLE,doGE]) then
      begin
       bOK := False;
       if (GetNextToken) then
       begin
        if (Token.ReservedWord = rwNOT) then
        begin
         if (GetNextToken) then
         begin
          bNot := True;
          bOK := True;
         end; // GetNextToken
        end // rwNOT
        else
         bOK := True;
        if (bOK) then
        begin
         if (Token.ReservedWord = rwANY) or (Token.ReservedWord = rwSOME) then
         begin
           if (GetNextToken) then
            Result := ParseSubQuery(doSubQueryANY,bNot,Result,op1)
           else
            bOK := False;
         end
         else
         if (Token.ReservedWord = rwALL) then
         begin
           if (GetNextToken) then
             Result := ParseSubQuery(doSubQueryALL,bNot,Result,op1)
           else
            bOK := False;
         end
         else
           bOK := False;
        end; // bOK
       end; // GetNextToken
       if (not bOK) then
        RestoreState(SavedTokenNo);
      end  // op1 in [doEQ,doNE,doLT,doGT,doLE,doGE]
      else
       RestoreState(SavedTokenNo);
    end; // Result <> nil
  except
   on e: Exception do
   begin
    if (node1 <> nil) then
     FreeAndNil(node1);
    if (node2 <> nil) then
     FreeAndNil(node2);
    if (node3 <> nil) then
     FreeAndNil(node3);
    if (Result <> nil) then
     FreeAndNil(Result);
    raise;
   end;
  end;
end; // ParseValueExpression


//------------------------------------------------------------------------------
// parses <operator>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseOperator: TSQLMemDataOperator;
var
    SavedTokenNo:        Integer;        // saved/restored information
begin
  Result := doUNDEFINED;
  if (Token.TokenType <> tktRightParenthesis) then
  begin
    // comparison
    if (SQLMemIsOperatorSign(Token,'<')) then
     Result := doLT
    else
    if (SQLMemIsOperatorSign(Token,'>')) then
     Result := doGT
    else
    if ((SQLMemIsOperatorSign(Token,'=')) or (SQLMemIsOperatorSign(Token,'=='))) then
     Result := doEQ
    else
    if ((SQLMemIsOperatorSign(Token,'<>')) or (SQLMemIsOperatorSign(Token,'!='))) then
     Result := doNE
    else
    if (SQLMemIsOperatorSign(Token,'<=')) then
     Result := doLE
    else
    if (SQLMemIsOperatorSign(Token,'>=')) then
     Result := doGE
    else
    // logical
    if IsReservedWord(Token, rwAND) or (SQLMemIsOperatorSign(Token,'&&')) then
     Result := doAND
    else
    if IsReservedWord(Token, rwOR) or (SQLMemIsOperatorSign(Token,'||')) then
     Result := doOR
    else
    // bitwise
    if (SQLMemIsOperatorSign(Token,'~')) then
     Result := doBitwiseNOT
    else
    if (SQLMemIsOperatorSign(Token,'&')) then
     Result := doBitwiseAND
    else
    if (SQLMemIsOperatorSign(Token,'|')) then
     Result := doBitwiseOR
    else
    if ((Token.ReservedWord = rwSHL) or (SQLMemIsOperatorSign(Token,'<<'))) then
     Result := doSHL
    else
    if ((Token.ReservedWord = rwSHR) or (SQLMemIsOperatorSign(Token,'>>'))) then
     Result := doSHR
    else
    if ((Token.ReservedWord = rwXOR) or (SQLMemIsOperatorSign(Token,'^'))) then
     Result := doXOR
    else
    // arithmetic
    if SQLMemIsOperatorSign(Token,'+') then
     Result := doADD
    else
    if SQLMemIsOperatorSign(Token,'-') then
     Result := doSUB
    else
    if SQLMemIsOperatorSign(Token,'*') then
     Result := doMUL
    else
    if ((SQLMemIsOperatorSign(Token,'%')) or (Token.ReservedWord = rwMOD)) then
     Result := doMOD
    else
    if ((SQLMemIsOperatorSign(Token,'/')) or (Token.ReservedWord = rwDIV)) then
     Result := doDIV
    else
    if (Token.ReservedWord = rwNOT) then
    begin
     SaveState(SavedTokenNo);
     if (GetNextToken) then
     begin
      if (Token.ReservedWord = rwBETWEEN) then
        Result := doNOTBETWEEN
      else
      if (Token.ReservedWord = rwIN) then
        Result := doNOTIN
      else
      if (Token.ReservedWord = rwLIKE) then
        Result := doNOTLIKE
      else
       RestoreState(SavedTokenNo);
     end;
    end
    else
    if (Token.ReservedWord = rwIS) then
    begin
     SaveState(SavedTokenNo);
     if (GetNextToken) then
     begin
      if (Token.ReservedWord = rwNULL) or (Token.ReservedWord = rwUNKNOWN) then
        Result := doISNULL
      else
      if (Token.ReservedWord = rwTRUE) then
        Result := doTRUE
      else
      if (Token.ReservedWord = rwFALSE) then
        Result := doFALSE
      else
      if (Token.ReservedWord = rwNOT) then
      begin
       if (GetNextToken) then
       begin
        if (Token.ReservedWord = rwNULL) or (Token.ReservedWord = rwUNKNOWN) then
          Result := doISNOTNULL
        else
        if (Token.ReservedWord = rwTRUE) then
          Result := doFALSE
        else
        if (Token.ReservedWord = rwFALSE) then
          Result := doTRUE
       end; // next token
      end; // NOT
     end; // next token
     if (Result = doUNDEFINED) then
       RestoreState(SavedTokenNo);
    end // IS
    else
    if (Token.ReservedWord = rwLIKE) then
     Result := doLIKE
    else
    if (Token.ReservedWord = rwIN) then
     Result := doIN
    else
    if (Token.ReservedWord = rwBETWEEN) then
     Result := doBETWEEN;
    // added in 4.95 to make
    // = NULL same as IS NULL
    // <> NULL same as IS NOT NULL
    // "" -> NULL
    if ((Result = doNE) or (Result = doEQ)) then
    begin
     SaveState(SavedTokenNo);
     GetNextToken;
     if (IsReservedWord(Token,rwNULL) or (IsEmptyString(Token))) then
     begin
       if (Result = doEQ) then
        Result := doISNULL
       else
        Result := doISNOTNULL;
  //     GetNextToken;
     end
     else
      RestoreState(SavedTokenNo);
    end;

  end; // <> )
end; // ParseOperator


//------------------------------------------------------------------------------
// return operator priority (0 - low, 255 - maximum);
//------------------------------------------------------------------------------
function TSQLMemExpression.GetOperatorPriority(Operator: TSQLMemDataOperator): Byte;
begin
{
 Delphi
 @, not	first (highest)
*, /, div, mod, and, shl, shr, as	second
+, -, or, xor	third
=, <>, <, >, <=, >=, in, is	fourth (lowest)

   doAND,
   doOR
    0
}
  Result := 0;
  case Operator of
   doNOT:
    Result := 4;
   doMUL,
   doDIV,
   doMOD,
   doSHL,
   doSHR,
   doBitwiseNOT,
   doBitwiseAND:
    Result := 3;
   doSUB,
   doADD,
   doCONCAT,
   doXOR,
   doBitwiseOR:
    Result := 2;
   doEQ,
   doNE,
   doGT,
   doLT,
   doGE,
   doLE,
   doIN,
   doNOTIN,
   doBETWEEN,
   doNOTBETWEEN,
   doLIKE,
   doNOTLIKE,
   doTRUE,
   doFALSE,
   doISNULL,
   doISNOTNULL:
    Result := 1;
  end;
end; // GetOperatorPriority


//------------------------------------------------------------------------------
// make <operator>
//------------------------------------------------------------------------------
function TSQLMemExpression.MakeOperator(node1, node2: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
begin
  Result := nil;
  case Operator of
    doEQ,
    doNE,
    doGT,
    doLT,
    doGE,
    doLE:
      begin
        if (node1 = nil) or (node2 = nil) then
         raise ESQLMemException.Create(12528,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        Result := TSQLMemExprNodeComparison.Create(Self,Operator,node1,node2,
          F3ValueLogic,FCaseInsensitive,FPartialKey);
      end;
    {Boolean}
    doISNULL,
    doISNOTNULL:
     begin
        if (node1 = nil) then
         raise ESQLMemException.Create(12532,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        Result := TSQLMemExprNodeBoolean.Create(Self,Operator,node1,FCaseInsensitive,FPartialKey);
     end;
    doNOT,
    doFALSE:
      begin
        if (node1 = nil) then
         raise ESQLMemException.Create(12529,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        Result := TSQLMemExprNodeBoolean.Create(Self,doNOT,node1,FCaseInsensitive,FPartialKey);
      end;
    doTRUE:
      begin
        Result := node1;
      end;
    doAND,
    doOR:
      begin
        if (node1 = nil) or (node2 = nil) then
         raise ESQLMemException.Create(12530,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        if (
            (Operator = doOR) and
            (
             IsStringFieldType(node1.GetDataType) or
             IsStringFieldType(node2.GetDataType) or
             (node1 is TSQLMemExprNodeStringFunction) or
             (node2 is TSQLMemExprNodeStringFunction)
            )
           ) then
        begin
          // concatenation ||
          if (node1 is TSQLMemExprNodeStringFunction) then
           if (TSQLMemExprNodeStringFunction(node1).Operator = Operator) then
           begin
            Result := node1;
            node1.Children.Add(node2);
            TSQLMemExprNodeStringFunction(node1).DetectConcatResultType(True);
           end;
          if (Result = nil) then
            Result := TSQLMemExprNodeStringFunction.Create(Self,doCONCAT,node1,node2,FCaseInsensitive,FPartialKey);
        end
        else
        begin
          if (node1 is TSQLMemExprNodeBoolean) then
           if (TSQLMemExprNodeBoolean(node1).Operator = Operator) then
           begin
            Result := node1;
            node1.Children.Add(node2);
           end;
          if (Result = nil) then
            Result := TSQLMemExprNodeBoolean.Create(Self,Operator,node1,node2,FCaseInsensitive,FPartialKey);
        end;
      end;
    doADD,
    doSUB,
    doMUL,
    doMOD,
    doDIV:
      begin
        if (node1 = nil) or (node2 = nil) then
         raise ESQLMemException.Create(12530,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        if (
            (Operator = doADD) and
            (
             IsStringFieldType(node1.GetDataType) or
             IsStringFieldType(node2.GetDataType) or
             (node1 is TSQLMemExprNodeStringFunction) or
             (node2 is TSQLMemExprNodeStringFunction)
            )
           ) then
        begin
          // concatenation +
          if (node1 is TSQLMemExprNodeStringFunction) then
           if (TSQLMemExprNodeStringFunction(node1).Operator = Operator) then
           begin
            Result := node1;
            node1.Children.Add(node2);
            TSQLMemExprNodeStringFunction(node1).DetectConcatResultType(True);
           end;
          if (Result = nil) then
            Result := TSQLMemExprNodeStringFunction.Create(Self,doCONCAT,node1,node2,FCaseInsensitive,FPartialKey);
        end // concatenation +
        else
        begin
          if (node1 is TSQLMemExprNodeArithmetic) and (Operator = doADD) then
           if (TSQLMemExprNodeBoolean(node1).Operator = Operator) then
           begin
            // +
            Result := node1;
            node1.Children.Add(node2);
           end;
          if (Result = nil) then
            Result := TSQLMemExprNodeArithmetic.Create(Self,Operator,node1,node2,FCaseInsensitive,FPartialKey);
        end; // +
      end;
    // bitwise
    doBitwiseNOT:
      begin
        if (node1 = nil) then
         raise ESQLMemException.Create(12545,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        Result := TSQLMemExprNodeArithmetic.Create(Self,doBitwiseNOT,node1,FCaseInsensitive,FPartialKey);
      end;
    doBitwiseOR,doBitwiseAND,doSHL,doSHR,doXOR:
      begin
        if (node1 = nil) or (node2 = nil) then
         raise ESQLMemException.Create(12546,ErrorLErrorMakingOperatorNilOperands,
         [SQLMemGetOperand(node1),SQLMemGetOperand(node2),GetOperatorName(Operator),
          Token.Text,Token.LineNum,Token.ColumnNum]);
        Result := TSQLMemExprNodeArithmetic.Create(Self,Operator,node1,node2,FCaseInsensitive,FPartialKey);
      end;
  end;
end; // MakeOperator


//------------------------------------------------------------------------------
// parses <boolean value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBooleanValueExpression: TSQLMemExprNode;
begin
  Result := ParseExistsPredicate;
  if (Result = nil) then
   Result := ParseIsNullExpression;
  if (Result = nil) then
    Result := ParseNullIfExpression;
  if (Result = nil) then
    Result := ParseCoalesceExpression;
  if (Result = nil) then
    Result := ParseCase;
end; // ParseBooleanValueExpression


//------------------------------------------------------------------------------
// parses <arithmetic value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseArithmeticValueExpression: TSQLMemExprNode;
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
  Result := nil;
  SaveState(SavedTokenNo);
  // parses <unsigned value specification>
  // integer
  if (Token.TokenType = tktInt) then
  begin
     Result := TSQLMemExprNodeConst.Create(Self);
     {$IFDEF D6H}
     Result.Value.DataType := bftSignedInt64;
     {$ELSE}
     Result.Value.DataType := bftSignedInt32;
     {$ENDIF}
     if Token.Text <> '' then
       Result.Value.AsString := Token.Text;
     // get next token
     GetNextToken;
  end
  else
  // float
  if (Token.TokenType = tktFloat) then
  begin
     Result := TSQLMemExprNodeConst.Create(Self);
     Result.Value.DataType := bftDouble;
     Result.Value.AsString := Token.Text;
     // get next token
     GetNextToken;
  end
  else
  // Parameter
  if (Token.TokenType = tktParameter) then
  begin
     if (Token.ParamValue.IsNull) then
      begin
       Result := TSQLMemExprNodeConst.Create(Self);
       Result.IsParameter := True;
       Result.ParamCRC := GetTableNameCRC(Token.Text);
       Result.Value.SetNull(Token.ParamValue.DataType);
       // get next token
       GetNextToken;
      end
     else
     if (Token.ParamValue.IsNumericDataType or (Token.ParamValue.DataType = bftBytes)) then
      begin
       Result := TSQLMemExprNodeConst.Create(Self);
       Result.IsParameter := True;
       Result.ParamCRC := GetTableNameCRC(Token.Text);
       Result.Value.Assign(Token.ParamValue);
       Result.Value.ConvertWideStringToAnsiStringIfNotUnicode;
       // get next token
       GetNextToken;
      end;
  end; // param
  // parses <stored function>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseStoredFunction;
   end;
  // parses <variable>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseVariable;
   end;
  // parses <column reference>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseColumnReference
   end;
  // parses <SubQuery>
  if Result = nil then
   begin
     RestoreState(SavedTokenNo);
     Result := ParseSubQuery(doSubQuery);
   end;
  // parses <set function specification>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseSetFunctionSpecification;
   end;
{
<numeric value function> ::=
      <position expression>
    | <extract expression>
    | <length expression>
    | <LastAutoInc expression>
}
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
   Result := ParsePositionExpression;
  end;
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
end; // ParseArithmeticValueExpression


//------------------------------------------------------------------------------
// parses <text value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseTextValueExpression: TSQLMemExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
 Result := nil;
 if (Token.TokenType = tktQuotedString) then
  begin
   Result := TSQLMemExprNodeConst.Create(Self);
   Result.Value.AsWideString := Token.Text;
   Result.Value.ConvertWideStringToAnsiStringIfNotUnicode;
   // get next token
   GetNextToken;
  end
 else
 if (Token.TokenType = tktParameter) and
    ((Token.ParamValue.IsStringDataType) or
     (Token.ParamValue.FIsBlob)) then
  begin
    Result := TSQLMemExprNodeConst.Create(Self);
    Result.IsParameter := True;
    Result.ParamCRC := GetTableNameCRC(Token.Text);
    Result.Value.Assign(Token.ParamValue);
    Result.Value.ConvertWideStringToAnsiStringIfNotUnicode;
    // get next token
    GetNextToken;
  end
  else
  begin
    SaveState(SavedTokenNo);
    Result := ParseCharacterValueFunction;
    if (Result = nil) then
      RestoreState(SavedTokenNo);
  end;
end; // ParseTextValueExpression


//------------------------------------------------------------------------------
// parses <general value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseGeneralValueExpression: TSQLMemExprNode;
begin
  Result := ParseBLOBValueFunction;
  if (Result = nil) then
   Result := ParseCastSpecification;
end; // ParseGeneralValueExpression


//------------------------------------------------------------------------------
// parses <match value> [ NOT ] LIKE <pattern> [ ESCAPE <escape character> ]
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseLike(Node: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
var node1:                TSQLMemExprNode;
    SavedTokenNo:         Integer;        // saved/restored information
    FNumLeftParenthesis:  Integer;
    FNumRightParenthesis: Integer;
begin
  FNumLeftParenthesis := 0;
  FNumRightParenthesis := 0;
  SaveState(SavedTokenNo);
  if (Token.TokenType = tktLeftParenthesis) then
  begin
    if (not GetNextToken) then
      raise ESQLMemException.Create(12544,ErrorGExpressionExpected,
        [Token.Text,Token.LineNum,Token.ColumnNum]);
    Inc(FNumLeftParenthesis);
    // parse with operators inside the parenthesises
    Result := ParseValueExpression(True,False);
  end
  else
    // parse without operators
    Result := ParseValueExpression(True,False,True);
  if (Result <> nil) then
  begin
    while ((Token.TokenType = tktRightParenthesis) and
           (FNumRightParenthesis < FNumLeftParenthesis)) do
    begin
      Inc(FNumRightParenthesis);
      if (not GetNextToken) then
       break;
    end;
    Result := TSQLMemExprNodeBoolean.Create(Self,Operator,Node,Result,FCaseInsensitive,FPartialKey);
    if (Token.ReservedWord = rwESCAPE) then
     if (GetNextToken) then
      begin
       node1 := ParseValueExpression(False,False);
       if (node1 <> nil) then
        Result.Children.Add(node1)
       else
       begin
        // ESCAPE not parsed
        Result.Free;
        Result := nil;
        RestoreState(SavedTokenNo);
       end;
      end;
  end
  else
    RestoreState(SavedTokenNo);
end; // ParseLikePredicate


//------------------------------------------------------------------------------
// parses <between predicate>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBetween(Node: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
var node1,node2: TSQLMemExprNode;
{$IFDEF EXPR_PARSING_1}
    FNumLeftParenthesis:  Integer;
    FNumRightParenthesis: Integer;
{$ENDIF}
    SavedTokenNo:   Integer;        // saved/restored information
begin
  SaveState(SavedTokenNo);
  FNumLeftParenthesis := 0;
  FNumRightParenthesis := 0;
  Result := nil;
  node1 := nil;
  node2 := nil;
  try
    if (Token.TokenType = tktLeftParenthesis) then
    begin
      if (not GetNextToken) then
        raise ESQLMemException.Create(12533,ErrorGExpressionExpected,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
      Inc(FNumLeftParenthesis);
      // parse with operators inside the parenthesises
      node1 := ParseValueExpression(True,False);
    end
    else
      // parse without operators
      node1 := ParseValueExpression(False,False);
    while ((Token.TokenType = tktRightParenthesis) and
           (FNumRightParenthesis < FNumLeftParenthesis)) do
    begin
      Inc(FNumRightParenthesis);
      if (not GetNextToken) then
       break;
    end;
    if (node1 <> nil) and (Token.ReservedWord = rwAND) then
     if (GetNextToken) then
      begin
        if (Token.TokenType = tktLeftParenthesis) then
        begin
          if (not GetNextToken) then
            raise ESQLMemException.Create(12534,ErrorGExpressionExpected,
              [Token.Text,Token.LineNum,Token.ColumnNum]);
          Inc(FNumLeftParenthesis);
          // parse with operators inside the parenthesises
          node2 := ParseValueExpression(True,False);
        end
        else
          // parse without operators
          node2 := ParseValueExpression(False,False);
        while ((Token.TokenType = tktRightParenthesis) and
               (FNumRightParenthesis < FNumLeftParenthesis)) do
        begin
          Inc(FNumRightParenthesis);
          if (not GetNextToken) then
           break;
        end;
      end;
    if (node1 = nil) or (node2 = nil) then
    begin
      if (node1 <> nil) then
       FreeAndNil(node1);
      if (node2 <> nil) then
       FreeAndNil(node2);
    end
    else
    begin
     Result := TSQLMemExprNodeBoolean.Create(
                Self,Operator,node,node1,node2,
                FCaseInsensitive,FPartialKey
                                         );
    end;
  except
   on e: Exception do
   begin
    if (node1 <> nil) then
     FreeAndNil(node1);
    if (node2 <> nil) then
     FreeAndNil(node2);
    if (Result <> nil) then
     FreeAndNil(Result);
   end;
  end;
  if (Result = nil) then
   RestoreState(SavedTokenNo);
end; // ParseBetween


//------------------------------------------------------------------------------
// parses <in predicate>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseIn(Node: TSQLMemExprNode; Operator: TSQLMemDataOperator): TSQLMemExprNode;
var node1:          TSQLMemExprNode;
    SavedTokenNo:   Integer;        // saved/restored information
begin
  Result := nil;
  node1 := nil;
  try
    SaveState(SavedTokenNo);
    // IN (SELECT ...)
{$IFDEF CORRELATED_SUBQUERIES}
    Result := ParseSubQuery(doSubQueryIN,(Operator = doNOTIN),Node);
{$ELSE}
    Result := ParseSubQuery(False,True,(Operator = doNOTIN),Node);
{$ENDIF}
    // '(' ?
    if (Result = nil) then
     begin
      RestoreState(SavedTokenNo);
      // '(' ?
      if (Token.TokenType = tktLeftParenthesis) then
       begin
        // get next token
        if (GetNextToken) then
        begin
          Result := TSQLMemExprNodeBoolean.Create(Self,Operator,Node);
          repeat
           node1 := ParseValueExpression;
           // if error
           if (node1 = nil) then
           begin
            FreeAndNil(Result);
            Exit;
           end;
           // add argument to IN node
           Result.Children.add(node1);
           node1 := nil;
           // ',' ?
           if Token.TokenType = tktComma then
            // get next token
            GetNextToken
           else
           // ')'
           if Token.TokenType = tktRightParenthesis then
            break;
          until false;
        end;
        // get next token
        GetNextToken;
       end;
     end; // not a Subquery
  except
   on e: Exception do
   begin
    if (node1 <> nil) then
     FreeAndNil(node1);
    if (Result <> nil) then
     FreeAndNil(Result);
   end;
  end;
  if (Result = nil) then
   RestoreState(SavedTokenNo);
end; // ParseIn


{$ELSE}


//------------------------------------------------------------------------------
// parses <value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseValueExpression: TSQLMemExprNode;
var SavedTokenNo: integer;        // saved/restored information
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
  if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseNullConst;
  end;
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
    Result := ParseBLOBValueFunction;
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
end;// ParseValueExpression


//------------------------------------------------------------------------------
// parses <comparison predicate> | <between predicate> | <in predicate>  |
// <like predicate>  | <null predicate> | <quantified comparison predicate> |
// <exists predicate> | <unique predicate> | <match predicate> | <overlaps predicate>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParsePredicate: TSQLMemExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
  //SavedRootNode: TSQLMemExprNode; // saved/restored information
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
{ TODO : 
add boolean column parsing here!!!
otherwise 
SELECT * from table WHERE BooleanField
does not work!!! }  
{
 // check for boolean column reference
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseColumnReference;
    if (Result <> nil) then
     begin
      if (Result.GetDataType <> aftBoolean) then
       begin
        Result.Free;
        Result := nil;
        RestoreState(SavedTokenNo);
       end;
     end;
  end;
}
end;// ParsePredicate


//------------------------------------------------------------------------------
// parses <predicate>  | <left paren> <search condition> <right paren>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBooleanPrimary: TSQLMemExprNode;
var leftCount,rightCount: Integer;
begin
 // '(' ?
 if (Token.TokenType = tktLeftParenthesis) then
  begin
   // skip '('
   GetNextToken;
   Inc(FNumLeftParenthesis);
   leftCount := FNumLeftParenthesis;
   rightCount := FNumRightParenthesis;
   // parse <search condition>
   Result := ParseSearchCondition;
   // skip ')'
//   if ((FNumLeftParenthesis-FNumRightParenthesis) = (leftCount-rightCount)) then
   if (token.TokenType = tktRightParenthesis) then
    begin
      Inc(FNumRightParenthesis);
      GetNextToken;
    end;
  end
 else
  Result := ParsePredicate;
end;// ParseBooleanPrimary


//------------------------------------------------------------------------------
// parses <boolean primary> [ IS [ NOT ] <truth value> ]
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBooleanTest: TSQLMemExprNode;
var
  bNot: Boolean;
  bIsNull: Boolean;
  bIsNotNull: Boolean;
  LeftNode: TSQLMemExprNode;
begin
  if (IsReservedWord(Token,rwISNULL)) then
   begin
    Result := ParseIsNullExpression;
    Exit;
   end;  // parse <boolean primary>
  if (IsReservedWord(Token,rwNULLIF)) then
   begin
    Result := ParseNullIfExpression;
    Exit;
   end;  // parse <boolean primary>
  if (IsReservedWord(Token,rwCOALESCE)) or (IsReservedWord(Token,rwIfNULL)) then
   begin
    Result := ParseCoalesceExpression;
    Exit;
   end;  // parse <boolean primary>
  if (IsReservedWord(Token,rwCASE)) then
   begin
    Result := ParseCase;
    Exit;
   end;  // parse <boolean primary>
  LeftNode := ParseBooleanPrimary;
  // modfied in v.5.90
  if (LeftNode = nil) then
  begin
   Result := nil;
   Exit;
  end;
{
  if (LeftNode = nil) then
    raise ESQLMemException.Create(30066, ErrorGBooleanExpressionExpected,
                               [Token.Text, Token.LineNum, Token.ColumnNum]);
}
  bNot := False;
  bIsNull := False;
  bIsNotNull := False;
  // [ IS [ NOT ] <truth value> ] ?
  if (IsReservedWord(Token, rwIS)) then
    begin
      // skip 'IS' token
      GetNextToken([tktReservedWord]);
      if (IsReservedWord(Token, rwNOT) or (Token.Text = '!')) then
       begin
        bNot := True;
        // skip 'NOT' token
        GetNextToken([tktReservedWord]);
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
       raise ESQLMemException.Create(30067, ErrorGOtherTokenExpected,
         ['TRUE, FALSE or UNKNOWN', Token.Text, Token.LineNum, Token.ColumnNum]);
    end;

  // create node?
  if (bNot) then
   Result := TSQLMemExprNodeBoolean.Create(Self,doNOT, LeftNode)
  else
  if (bIsNull) then
   Result := TSQLMemExprNodeBoolean.Create(Self,doISNULL, LeftNode)
  else
  if (bIsNotNull) then
   Result := TSQLMemExprNodeBoolean.Create(Self,doISNOTNULL, LeftNode)
  else
   Result := LeftNode;
end;// ParseBooleanTest


//------------------------------------------------------------------------------
// parses [ NOT ] <boolean test>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBooleanFactor: TSQLMemExprNode;
var
  bNot: Boolean;
  LeftNode: TSQLMemExprNode;
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
    // modfied in v.5.90
    if (LeftNode = nil) then
    begin
     Result := nil;
     Exit;
    end;
{
   if (LeftNode = nil) then
      raise ESQLMemException.Create(30068, ErrorGBooleanExpressionExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);
}
    // create <NOT> node?
    if (bNot) then
     Result := TSQLMemExprNodeBoolean.Create(Self, doNOT, LeftNode)
    else
     Result := LeftNode;
   end; // not EXISTS
end;// ParseBooleanFactor


//------------------------------------------------------------------------------
// parses <boolean term> | <search condition> OR <boolean term>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseSearchCondition: TSQLMemExprNode;
var
  LeftNode, RightNode: TSQLMemExprNode;
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
       raise ESQLMemException.Create(30070, ErrorGBooleanExpressionExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
      // create <OR> node
      LeftNode := TSQLMemExprNodeBoolean.Create(Self, doOR, LeftNode, RightNode);
    end;
  end;
 Result := LeftNode;
end;// ParseSearchCondition


//------------------------------------------------------------------------------
// parses <expression> <Boolean_operator> <expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBooleanOperator(Node: TSQLMemExprNode): TSQLMemExprNode;
var
   SavedTokenNo:  Integer;        // saved/restored information
   bNot:          Boolean;
begin
{
  Result := (token.ReservedWord in [rwIS,rwIN,rwBETWEEN,rwLIKE,rwNOT,rwAND,rwOR])
            or (token.Text = '>')
            or (token.Text = '<')
            or (token.Text = '=')
            or (token.Text = '!')
            ;
}
  SaveState(SavedTokenNo);
  if (token.ReservedWord = rwIS) then
  begin
   Result := ParseNullPredicate(Node);
  end
  else
  if (token.ReservedWord = rwIN) then
  begin
   Result := ParseInPredicate(Node);
  end
  else
  if (token.ReservedWord = rwBETWEEN) then
  begin
   Result := ParseBetweenPredicate(Node);
  end
  else
  if (token.ReservedWord = rwLIKE) then
  begin
   Result := ParseLikePredicate(Node);
  end
  else
  if (token.ReservedWord = rwNOT) then
  begin
   Result := ParseInPredicate(Node);
   if (Result = nil) then
    RestoreState(SavedTokenNo);
   if (Result = nil) then
    Result := ParseLikePredicate(Node);
   if (Result = nil) then
    RestoreState(SavedTokenNo);
   if (Result = nil) then
    Result := ParseBetweenPredicate(Node);
  end
  else
  begin
    Result := ParseBooleanTerm(Node);
  end;
  if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
  end;
end; // ParseBooleanOperator


//------------------------------------------------------------------------------
// parses <numeric value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseNumericValueExpression: TSQLMemExprNode;
var
  Term: TSQLMemExprNode;
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
      Result := TSQLMemExprNodeArithmetic.Create(Self, doADD, Term);
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
function TSQLMemExpression.ParseTerm: TSQLMemExprNode;
var
  Factor:       TSQLMemExprNode;
  op:           TSQLMemDataOperator;
  SavedTokenNo: Integer;        // saved/restored information
  bNot:         Boolean;
begin
{

<term> ::=
      <factor>
    | <term> <asterisk> <factor>
    | <term> <solidus> <factor>
    | NOT <factor>
}
// 4.40
  SaveState(SavedTokenNo);
  if (Token.Text = '!') then
   begin
//    Result := ParseBooleanFactor;
    GetNextToken;
    Factor := ParseFactor;
    if (Factor <> nil) then
     begin
      Result := TSQLMemExprNodeBoolean.Create(Self, doNOT, Factor);
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
      Result := TSQLMemExprNodeArithmetic.Create(Self, doBitwiseNOT, Result);
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
      Result := TSQLMemExprNodeArithmetic.Create(Self, op, Result);
      Factor := ParseFactor;
//!!      if Factor = nil then ;
      Result.Children.Add(Factor);
     end;
   end; // factor parsed
{
// <= 4.30
<term> ::=
      <factor>
    | <term> <asterisk> <factor>
    | <term> <solidus> <factor>

  Result:=ParseFactor;
  if Result <> nil then
    while (Token.Text='*') or (Token.Text='/') do
     begin
      if Token.Text='*' then
        op := doMUL
      else
        op := doDIV;
      // get next token
      GetNextToken;
      Result := TSQLMemExprNodeArithmetic.Create(op, Result);
      Factor := ParseFactor;
//!!      if Factor = nil then ;
      Result.Children.Add(Factor);
     end;
}
end;//ParseTerm

//------------------------------------------------------------------------------
// parses <factor>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseFactor: TSQLMemExprNode;
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
    Result := TSQLMemExprNodeArithmetic.Create(Self, doSUB, Result);

end;//ParseFactor

//------------------------------------------------------------------------------
// parses <sign>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseSign: TSign;
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
function TSQLMemExpression.ParseNumericPrimary: TSQLMemExprNode;
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
    if Result.ClassType = TSQLMemExprNodeConst then
     if (not Result.Value.IsNumericDataType) then
      begin
       RestoreState(SavedTokenNo);
       Result.Free;
       Result := nil;
      end;
   end;
end;//ParseNumericPrimary


//------------------------------------------------------------------------------
// parses <unsigned value specification>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseUnsignedValueSpecification: TSQLMemExprNode;
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
function TSQLMemExpression.ParseUnsignedLiteral: TSQLMemExprNode;
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
function TSQLMemExpression.ParseUnsignedNumericLiteral: TSQLMemExprNode;
begin
{
<unsigned numeric literal> ::=
      <exact numeric literal>
    | <approximate numeric literal>
}
 Result := nil;
 // integer
 if (Token.TokenType = tktInt) then
  begin
   Result := TSQLMemExprNodeConst.Create(Self);
   {$IFDEF D6H}
   Result.Value.DataType := bftSignedInt64;
   {$ELSE}
   Result.Value.DataType := bftSignedInt32;
   {$ENDIF}
   if Token.Text <> '' then
     Result.Value.AsString := Token.Text;
   // get next token
   GetNextToken;
  end
 else
 // float
 if (Token.TokenType = tktFloat) then
  begin
   Result := TSQLMemExprNodeConst.Create(Self);
   Result.Value.DataType := bftDouble;
   Result.Value.AsString := Token.Text;
   // get next token
   GetNextToken;
  end
 else
 // Parameter
 if (Token.TokenType = tktParameter) then
  begin
   if (Token.ParamValue.IsNull) then
    begin
     Result := TSQLMemExprNodeConst.Create(Self);
     Result.IsParameter := True;
     Result.ParamCRC := GetTableNameCRC(Token.Text);
     Result.Value.SetNull(Token.ParamValue.DataType);
     // get next token
     GetNextToken;
    end
   else
   if (Token.ParamValue.IsNumericDataType or (Token.ParamValue.DataType = bftBytes)) then
    begin
     Result := TSQLMemExprNodeConst.Create(Self);
     Result.IsParameter := True;
     Result.ParamCRC := GetTableNameCRC(Token.Text);
     Result.Value.Assign(Token.ParamValue);
     Result.Value.ConvertWideStringToAnsiStringIfNotUnicode;
     // get next token
     GetNextToken;
    end
  end // param
 else
  Result := nil;
end;//ParseUnsignedNumericLiteral


//------------------------------------------------------------------------------
// parses <character AnsiString literal>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCharacterStringLiteral: TSQLMemExprNode;
begin
(*
<character AnsiString literal> ::=
    [ <introducer><character set specification> ]
    <quote> [ <character representation>... ] <quote>
      [ { <separator>... <quote> [ <character representation>... ] <quote> }...]
*)
 Result := nil;

 if (Token.TokenType = tktQuotedString) then
  begin
   Result := TSQLMemExprNodeConst.Create(Self);
   Result.Value.AsWideString := Token.Text;
   Result.Value.ConvertWideStringToAnsiStringIfNotUnicode;
   // get next token
   GetNextToken;
  end
 else if (Token.TokenType = tktParameter) and
          ((Token.ParamValue.IsStringDataType) or
           (Token.ParamValue.FIsBlob)) then
  begin
    Result := TSQLMemExprNodeConst.Create(Self);
    Result.IsParameter := True;
    Result.ParamCRC := GetTableNameCRC(Token.Text);
    Result.Value.Assign(Token.ParamValue);
    Result.Value.ConvertWideStringToAnsiStringIfNotUnicode;
    // get next token
    GetNextToken;
  end

end;//ParseCharacterStringLiteral


//------------------------------------------------------------------------------
// parses <value expression primary>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseValueExpressionPrimary: TSQLMemExprNode;
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
  // parses <stored function>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseStoredFunction;
   end;
  // parses <variable>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseVariable;
   end;
  // parses <column reference>
  if Result=nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseColumnReference
   end;
  // parses <SubQuery>
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseSubQuery(doSubQuery);
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
      // fixed in v.5.90
      if (Result <> nil) and
         (Token.TokenType <> tktRightParenthesis) then
       begin
//        Result.Free;
//        RestoreState(SavedTokenNo);
        Result := ParseBooleanTerm(Result);
        if (Result = nil) then
         RestoreState(SavedTokenNo)
        else
         GetNextToken;
       end
      else
       // get next token
       GetNextToken;
{
      if (Result <> nil) and
         (Token.TokenType <> tktRightParenthesis) then
       begin
        Result.Free;
        raise ESQLMemException.Create(30071, ErrorGOtherTokenExpected,
                              [')', Token.Text, Token.LineNum,Token.ColumnNum]);
       end;
}
     end;
   end;
  // parses <cast specification>
  if Result = nil then
   begin
    RestoreState(SavedTokenNo);
    Result := ParseCastSpecification;
   end;
end;//ParseValueExpressionPrimary
{$ENDIF}


//------------------------------------------------------------------------------
// parses <column reference>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseColumnReference: TSQLMemExprNode;
var
  FieldName, TableName: WideString;
  IsResWord: boolean;
begin
 Result := nil;
 //InitDataValue(Value);
 if ((Token.TokenType = tktString) or
     (Token.TokenType = tktBracketedString) or
     (Token.TokenType = tktBackQuotedString) or
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
     Result := TSQLMemExprNodeField.Create(Self, LCursor, FieldName, TableName);
  end;
 //FinalizeDataValue(Value);
end;//ParseColumnReference


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// parses <SUB QUERY>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseSubQuery(
                                       Operator:      TSQLMemDataOperator;
                                       bNot:          Boolean;
                                       SourceNode:    TSQLMemExprNode;
                                       CompOp:        TSQLMemDataOperator
                                      ): TSQLMemExprNode;
var SubQueryText:           WideString;
    bSkipSpace:             Boolean;
    query:                  TSQLMemSQLUnion;
    FDBParams:              TSQLMemSQLDatabaseParams;
    SavedTokenNo:           Integer;
    bParenthesis:           Boolean;

begin
  Result := nil;
  SaveState(SavedTokenNo);
  // modified in v.5.90 to handle parenthesises correctly
  if (Token.TokenType = tktLeftParenthesis) then
   begin
    GetNextToken;
    bParenthesis := True;
   end
  else
    bParenthesis := False;
  if (IsReservedWord(Token,rwSELECT)) then
    begin
     FDBParams.Session := LSession;
     FDBParams.DatabaseName := DatabaseName;
     FDBParams.SessionName := SessionName;
     FDBParams.InMemory := InMemory;
     FDBParams.RequestLive := True;
     FDBParams.Params := Params;
     FDBParams.ParamsSet := True;
     query := TSQLMemSQLUnion.Create(LLex,FDBParams,LStoredFunction,True);
     LLex.GetCurrentToken(Token);
     Result := TSQLMemExprNodeSubQuery.Create(Self,Operator,query,bNot,SourceNode,CompOp);
     if ((Token.TokenType = tktRightParenthesis) and bParenthesis) then
      GetNextToken;
    end; // SubQuery
  if (Result = nil) then
  begin
   RestoreState(SavedTokenNo);
  end;
end; // ParseSubQuery
{$ELSE}
//------------------------------------------------------------------------------
// parses <SUB QUERY>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseSubQuery(
                                       bExists:       Boolean = False;
                                       bIn:           Boolean = False;
                                       bNot:          Boolean = False;
                                       SourceNode:    TSQLMemExprNode = nil
                                      ): TSQLMemExprNode;
var SubQueryText:           WideString;
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
            if (Token.TokenType = tktBackQuotedString) then
             begin
              if (bSkipSpace) then
               SubQueryText := SubQueryText + '`' + Token.Text + '`'
              else
               SubQueryText := SubQueryText + Space + '`' + Token.Text + '`';
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
            if (Token.TokenType = tktParameter) then
             begin
              SubQueryText := SubQueryText + Space + Colon + Token.Text;
              bSkipSpace := False;
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
            Result := TSQLMemExprNodeSubQueryExists.Create(Self,SubQueryText,FParams,FInMemory,
                        FDatabaseName,FSessionName, bNot,SourceNode)
           else
           if (bIn) then
            Result := TSQLMemExprNodeSubQueryIn.Create(Self,SubQueryText,FParams,FInMemory,
                        FDatabaseName,FSessionName, bNot,SourceNode)
           else
            Result := TSQLMemExprNodeSubQuery.Create(Self,SubQueryText,FParams,FInMemory,
                        FDatabaseName,FSessionName, bNot,SourceNode);
          end; // while GetNextToken
        end; // SubQuery
   end; // Left Parenthesis
end; // ParseSubQuery
{$ENDIF}


//------------------------------------------------------------------------------
// parses <set function specification>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseSetFunctionSpecification: TSQLMemExprNode;
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
       raise ESQLMemException.Create(30073, ErrorGOtherTokenExpected,
                             [')', Token.Text, Token.LineNum, Token.ColumnNum]);
       // get next token
       GetNextToken;
       Result := TSQLMemExprNodeAggregated.Create(Self, doCOUNTALL);
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
function TSQLMemExpression.ParseGeneralSetFunction: TSQLMemExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
  expr,arg:     TSQLMemExprNode;
  distinct:     boolean;
  desc:         boolean;
  oper:         TSQLMemDataOperator;
begin
{
<general set function> ::=
      <set function type>
          <left paren> [ <set quantifier> ] <value expression> <right paren>
}
 desc := false;
 Result := nil;
 arg := nil;
 SaveState(SavedTokenNo);

 oper := doUNDEFINED;
 if IsReservedWord(Token, rwCOUNT) then
  oper:=doCOUNT
 else if IsReservedWord(Token, rwAVG) then
  oper:=doAVG
 else if IsReservedWord(Token, rwMAX) then
  oper:=doMAX
 else if IsReservedWord(Token, rwMIN) then
  oper:=doMIN
 else if (IsReservedWord(Token, rwSTDDEV) or IsReservedWord(Token, rwSTDEV)) then
  oper:=doSTDDEV
 else if IsReservedWord(Token, rwSUM) then
  oper:=doSUM
 else if IsReservedWord(Token, rwGROUP_CONCAT) then
  oper:=doGROUP_CONCAT
 ;

 if oper = doUNDEFINED then Exit;

 // get next token
 GetNextToken;

 // DISTINCT
 distinct := IsReservedWord(Token, rwDISTINCT);
 if distinct then
  GetNextToken;

 // '('
 if Token.TokenType <> tktLeftParenthesis then
   raise ESQLMemException.Create(30074, ErrorGOtherTokenExpected,
                            ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
 // get next token
 GetNextToken;

 if (IsReservedWord(Token, rwDISTINCT)) then
  begin
   distinct := True;
   GetNextToken;
  end;

 if (IsReservedWord(Token, rwASC)) then
  begin
   desc := false;
   GetNextToken;
  end;

 if (IsReservedWord(Token, rwDESC)) then
  begin
   desc := True;
   GetNextToken;
  end;

 // EXPRESSION
 expr := ParseValueExpression;
 if expr = nil then
   raise ESQLMemException.Create(30102, ErrorGArgumentExpected,
            [GetOperatorName(oper), Token.LineNum, Token.ColumnNum]);

 if (oper = doGROUP_CONCAT) or (oper = doSTDDEV) then
  begin
   // GROUP_CONCAT([DISTINCT] FieldName [, Separator])
   if (Token.TokenType = tktComma) then
    begin
     GetNextToken;
     arg := ParseValueExpression;
     if arg = nil then
      begin
       expr.Free;
       raise ESQLMemException.Create(11769, ErrorGArgumentExpected,
                [GetOperatorName(oper), Token.LineNum, Token.ColumnNum]);
      end;
    end;
  end;

 // ')'
 if Token.TokenType <> tktRightParenthesis then
  begin
   expr.Free;
   if (arg <> nil) then
    arg.Free;
   raise ESQLMemException.Create(30075, ErrorGOtherTokenExpected,
                            [')', Token.Text, Token.LineNum, Token.ColumnNum]);
  end;
 // get next token
 GetNextToken;

 // Return GroupFunctionNode
 if (oper = doGROUP_CONCAT) and (arg <> nil) then
   Result := TSQLMemExprNodeAggregated.Create(Self, oper, distinct, expr, arg, desc)
 else
   Result := TSQLMemExprNodeAggregated.Create(Self, oper, distinct, expr, desc);
end;//ParseGeneralSetFunction



//------------------------------------------------------------------------------
// parses <cast specification>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCastSpecification: TSQLMemExprNode;
var
    Operand: TSQLMemExprNode;
    fType:   TSQLMemAdvancedFieldType;
    Size:    TSQLMemExprNode;
begin
{
<cast specification> ::=
    CAST <left paren> <cast operand> [as | , ]
        <cast target> <right paren>
}
 //raise Exception.Create('Not supported yet');
 Operand := nil;
 Size := nil;
 Result := nil;
 try
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
           if IsConvertableFieldType(fType) then
            begin
             // get next token
             GetNextToken;
             if (Token.TokenType = tktLeftParenthesis) then
             begin
              // Char(N)
              GetNextToken;
              // modivied in v.5.90
              {$IFDEF EXPR_PARSING_1}
               Size := ParseValueExpression;
              {$ELSE}
              Size := ParseNumericValueExpression;
              {$ENDIF}
              if (size = nil) then
              raise ESQLMemException.Create(12466, ErrorLNumericArgumentExpected,
                 ['CAST', Token.Text, Token.LineNum, Token.ColumnNum]);
              GetNextToken;
             end; // ( N )
             // ')'
             if Token.TokenType <> tktRightParenthesis then
              begin
                raise ESQLMemException.Create(30076, ErrorGOtherTokenExpected,
                                [')', Token.Text,Token.LineNum,Token.ColumnNum]);
              end;
             if (Size <> nil) then
               Result := TSQLMemExprNodeCast.Create(Self, Operand, fType, Size)
             else
               Result := TSQLMemExprNodeCast.Create(Self, Operand, fType);
             // get next token
             GetNextToken;
            end
           else
            begin
             raise ESQLMemException.Create(30077, ErrorGNotApplicableCastType,
                                        [AftToStr(fType)]);
            end;
          end;
      end;
    end; // (
  end;
 except
   on e: Exception do
   begin
    if (Operand <> nil) then
     Operand.Free;
    raise;
   end;
 end;
end;//ParseCastSpecification


//------------------------------------------------------------------------------
// parses <cast operand>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCastOperand: TSQLMemExprNode;
var
  SavedTokenNo: integer;
begin
{
<cast operand> ::=
      <value expression>
    | NULL
}
 // NULL
 SaveState(SavedTokenNo);

{$IFDEF EXPR_PARSING_1}
  Result := ParseValueExpression;
{$ELSE}
 Result := ParseNullConst;
 GetNextToken;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseValueExpression;
  end;
{$ENDIF}
end;//ParseCastOperand


//------------------------------------------------------------------------------
// parses <numeric value function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseNumericValueFunction: TSQLMemExprNode;
var
  SavedTokenNo: integer;        // saved/restored information
begin
{
<numeric value function> ::=
      <position expression>
    | <extract expression>
    | <length expression>
    | <LastAutoInc expression>
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
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseNullIfExpression;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseCoalesceExpression;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseCase;
  end;
end;//ParseNumericValueFunction


//------------------------------------------------------------------------------
// parses <position expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParsePositionExpression: TSQLMemExprNode;
var
  arg1, arg2: TSQLMemExprNode;
begin
 if IsReservedWord(Token, rwPOSITION) or IsReservedWord(Token, rwPOS) then
  begin
    // get next token
    GetNextToken;

    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ESQLMemException.Create(30078, ErrorGOtherTokenExpected,
                             ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
    // get next token
    GetNextToken;

    // arg
    // modivied in v.5.90
    {$IFDEF EXPR_PARSING_1}
    arg1 := ParseValueExpression;
    {$ELSE}
    arg1 := ParseCharacterValueExpression;
    {$ENDIF}
    if arg1 = nil then
     raise ESQLMemException.Create(30079, ErrorGArgumentExpected,
                                       ['POS', Token.LineNum, Token.ColumnNum]);

    // ',' or 'in'
    if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwIN) then
     begin
       arg1.Free;
       raise ESQLMemException.Create(30080, ErrorGOtherTokenExpected,
                [','' or ''IN', Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
    // get next token
    GetNextToken;

    // modivied in v.5.90
    {$IFDEF EXPR_PARSING_1}
    arg2 := ParseValueExpression;
    {$ELSE}
    arg2 := ParseCharacterValueExpression;
    {$ENDIF}
    if arg2 = nil then
     begin
      arg1.Free;
      raise ESQLMemException.Create(30081, ErrorGArgumentExpected,
                                       ['POS', Token.LineNum, Token.ColumnNum]);
     end;

    Result := TSQLMemExprNodeStringFunction.Create(Self, doPOS, arg1, arg2);

    // ')'
    if Token.TokenType <> tktRightParenthesis then
     begin
      Result.Free;
      raise ESQLMemException.Create(30082, ErrorGOtherTokenExpected,
                             [')', Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
    // get next token
    GetNextToken;
  end
 else
  Result := nil;
end;//ParsePositionExpression


//------------------------------------------------------------------------------
// parses <length expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseLengthExpression: TSQLMemExprNode;
begin
 if IsReservedWord(Token, rwLENGTH) then
  begin
    // get next token
    GetNextToken;

    // '('
    if Token.TokenType <> tktLeftParenthesis then
     raise ESQLMemException.Create(30083, ErrorGOtherTokenExpected,
                             ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
    // get next token
    GetNextToken;

    // argument
    // modivied in v.5.90
    {$IFDEF EXPR_PARSING_1}
    Result := ParseValueExpression;
    {$ELSE}
    Result := ParseStringValueExpression;
    {$ENDIF}
    if result = nil then
      raise ESQLMemException.Create(30085, ErrorGArgumentExpected,
                                     ['LENGTH', Token.LineNum, Token.ColumnNum]);

    Result := TSQLMemExprNodeStringFunction.Create(Self, doLENGTH, Result);

    // ')'
    if Token.TokenType <> tktRightParenthesis then
     begin
      Result.Free;
      raise ESQLMemException.Create(30084, ErrorGOtherTokenExpected,
                             [')', Token.Text, Token.LineNum, Token.ColumnNum]);
     end;

    // get next token
    GetNextToken;
  end
 else
  Result := nil;
end;//ParseLengthExpression


//------------------------------------------------------------------------------
// parses <LastAutoInc expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseLastAutoIncExpression: TSQLMemExprNode;
var
  aDatabaseName:         AnsiString;
  TableName, ColumnName: WideString;
  MemoryWord:            Boolean;
begin

 //  LastAutoinc(TableName, ColumnName)

 if IsReservedWord(Token, rwLAST_AUTOINC) then
  begin
    aDatabaseName := FDatabaseName;
    TableName := '';
    ColumnName := '';
    MemoryWord := False;

    // get next token
    GetNextToken;

    // '('
    if (Token.TokenType <> tktLeftParenthesis) then
      raise ESQLMemException.Create(30086, ErrorGOtherTokenExpected,
                             ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
      // table_name
    GetNextToken;
    // MEMORY
    if (IsReservedWord(Token, rwMEMORY)) then
     begin
      MemoryWord := True;
      GetNextToken;
      aDatabaseName := '';
     end;

    TableName := Token.Text;
    GetNextToken;

    // ','
    // databasename
    if (Token.TokenType <> tktComma) then
     begin
      aDatabaseName := TableName;
      TableName := Token.Text;
      // get ','
      GetNextToken;
      if (Token.TokenType <> tktComma) then
       raise ESQLMemException.Create(30334, ErrorGOtherTokenExpected,
                           [',', Token.Text, Token.LineNum, Token.ColumnNum]);
     end;


    // column_name
        GetNextToken;
    ColumnName := Token.Text;

      // ')'
    GetNextToken;
      if Token.TokenType <> tktRightParenthesis then
        raise ESQLMemException.Create(30089, ErrorGOtherTokenExpected,
                             [')', Token.Text, Token.LineNum, Token.ColumnNum]);


    // get next token
    GetNextToken;

    Result := TSQLMemExprNodeSystem.Create(Self, doLASTAUTOINC, TableName,
                                        ColumnName, (InMemory or MemoryWord),
                                        FSessionName,
                                        aDatabaseName);
  end
 else
  Result := nil;
end;//ParseLastAutoIncExpression


//------------------------------------------------------------------------------
// parses <IsNull expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseIsNullExpression: TSQLMemExprNode;
var expr,expr1: TSQLMemExprNode;
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
        raise ESQLMemException.Create(11597,ErrorGLeftParenthesisExpected,
                [Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      // EXPRESSION
      expr := ParseValueExpression;
      if (expr = nil) then
       raise ESQLMemException.Create(11598,ErrorGArgumentExpected,
              [GetOperatorName(doISNULLFUNCTION), Token.LineNum, Token.ColumnNum]);
      if (Token.TokenType = tktComma) then
       begin
        // get next token
        GetNextToken;
        // replacement
        expr1 := ParseValueExpression;
       end;
      if (Token.TokenType <> tktRightParenthesis) then
        raise ESQLMemException.Create(11599,ErrorGMissingRightParenthesis,
                [Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      if (expr1 = nil) then
       Result := TSQLMemExprNodeIsNullFunction.Create(Self, doISNULLFUNCTION, expr)
      else
       Result := TSQLMemExprNodeIsNullFunction.Create(Self, doISNULLFUNCTION, expr, expr1);
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
// parses <COALESCE expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCoalesceExpression: TSQLMemExprNode;
var expr:     TSQLMemExpression;
    nodeList: TSQLMemList;
    node:     TSQLMemExprNode;
    i:        Integer;
begin
  Result := nil;
  // COALESCE?
  if (IsReservedWord(Token, rwCOALESCE)) or (IsReservedWord(Token, rwIFNULL)) then
  begin
    // get next token
    GetNextToken;
    if (Token.TokenType <> tktLeftParenthesis) then
      raise ESQLMemException.Create(12403,ErrorGLeftParenthesisExpected,
              [Token.Text, Token.LineNum, Token.ColumnNum]);
    // get next token
    if (not GetNextToken) then
     raise ESQLMemException.Create(12407,ErrorGArgumentExpected,[GetReservedWord(rwCOALESCE),token.LineNum,token.ColumnNum]);
    nodeList := TSQLMemList.Create;
    try
      while (token.TokenType <> tktRightParenthesis) do
      begin
         node := ParseValueExpression;
         if (node = nil) then
          raise ESQLMemException.Create(12412,ErrorLNilPointer);
         nodeList.Add(node);
         if (token.TokenType = tktRightParenthesis) then
          break;
         // get next token
         if (not GetNextToken) then
          raise ESQLMemException.Create(12404,ErrorGArgumentExpected,[GetReservedWord(rwCOALESCE),token.LineNum,token.ColumnNum]);
         if (token.TokenType = tktComma) then
          if (not GetNextToken) then
           raise ESQLMemException.Create(12405,ErrorGArgumentExpected,[GetReservedWord(rwCOALESCE),token.LineNum,token.ColumnNum]);
      end;
      // get next token
      GetNextToken;
      if (nodeList.Count <= 0) then
       raise ESQLMemException.Create(12410,ErrorLParCannotParseCoalesceNoParams,[Token.LineNum,Token.ColumnNum]);
    except
     on e: Exception do
     begin
       for i := 0 to nodeList.Count-1 do
        TSQLMemExprNode(nodeList[i]).Free;
       nodeList.Free;
       raise ESQLMemException.Create(12406,ErrorLCannotParseCoalesceParams,[Token.LineNum,Token.ColumnNum,e.Message]);
     end;
    end;
    Result := TSQLMemExprNodeCoalesceFunction.Create(Self,nodeList);
  end;
end; // ParseCoalesceExpression


//------------------------------------------------------------------------------
// parses CASE
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCase: TSQLMemExprNode;
var expr:     TSQLMemExpression;
    nodeList: TSQLMemList;
    node:     TSQLMemExprNode;
    i,nw:     Integer;
    sf,bw:    Boolean;
    t:        TToken;
begin
  Result := nil;
  // CASE
  if (IsReservedWord(Token, rwCASE)) then
  begin
   // detect simple or advanced form
   sf := True;
   if LLex.LookNextToken(t) then
    if (IsReservedWord(t,rwWHEN)) then
     sf := False;
   // get next token
   if (not GetNextToken) then
     raise ESQLMemException.Create(12408,ErrorGArgumentExpected,[GetReservedWord(rwCASE),token.LineNum,token.ColumnNum]);
   nw := 0;
   nodeList := TSQLMemList.Create;
   try
    if (sf) then
    begin
     // parse CASE expression
     node := ParseValueExpression;
     if (node = nil) then
      raise ESQLMemException.Create(12413,ErrorLNilPointer);
     nodeList.Add(node);
    end;
    while (not IsReservedWord(Token,rwEND)) do
    begin
     if (not IsReservedWord(Token,rwWHEN)) and (not IsReservedWord(Token,rwELSE)) then
      raise ESQLMemException.Create(12414,ErrorGOtherTokenExpected,
              [GetReservedWord(rwWHEN), Token.Text, Token.LineNum, Token.ColumnNum]);
     bw := IsReservedWord(Token,rwWHEN);
     if (not GetNextToken) then
       raise ESQLMemException.Create(12415,ErrorGArgumentExpected,[GetReservedWord(rwCASE),token.LineNum,token.ColumnNum]);
     // parse WHEN / ELSE expression
     {$IFDEF EXPR_PARSING_1}
     node := ParseValueExpression;
     {$ELSE}
     if (sf or (not bw)) then
       node := ParseValueExpression
     else
       node := ParseSearchCondition;
     {$ENDIF}
     if (node = nil) then
      raise ESQLMemException.Create(12416,ErrorLNilPointer);
     nodeList.Add(node);
     if (bw) then
     begin
       Inc(nw);
       // parse THEN
       if (not IsReservedWord(Token,rwTHEN)) then
        raise ESQLMemException.Create(12418,ErrorGOtherTokenExpected,
                [GetReservedWord(rwTHEN), Token.Text, Token.LineNum, Token.ColumnNum]);
       if (not GetNextToken) then
         raise ESQLMemException.Create(12419,ErrorGArgumentExpected,[GetReservedWord(rwCASE),token.LineNum,token.ColumnNum]);
       // parse result_expression
       node := ParseValueExpression;
       if (node = nil) then
        raise ESQLMemException.Create(12420,ErrorLNilPointer);
       nodeList.Add(node);
     end
     else
     begin
       if (not IsReservedWord(Token,rwEND)) then
        raise ESQLMemException.Create(12417,ErrorGOtherTokenExpected,
                [GetReservedWord(rwEND), Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
    end;
    // fixed in v.5.70 pr#3
    // skip END
    GetNextToken;
    if (nodeList.Count <= 0) then
     raise ESQLMemException.Create(12411,ErrorLParCannotParseCASENoParams,[Token.LineNum,Token.ColumnNum]);
   except
     on e: Exception do
     begin
       for i := 0 to nodeList.Count-1 do
        TSQLMemExprNode(nodeList[i]).Free;
       nodeList.Free;
       raise ESQLMemException.Create(12409,ErrorLCannotParseCASE,[Token.LineNum,Token.ColumnNum,e.Message]);
     end;
   end;
   Result := TSQLMemExprNodeCase.Create(Self,sf,nw,nodeList);
  end;
end; // ParseCase


//------------------------------------------------------------------------------
// parses <NullIf expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseNullIfExpression: TSQLMemExprNode;
var expr,expr1: TSQLMemExprNode;
begin
  Result := nil;
  // ISNULL?
  if (IsReservedWord(Token, rwNULLIF)) then
   begin
    expr1 := nil;
    expr := nil;
    try
      // get next token
      GetNextToken;
      if (Token.TokenType <> tktLeftParenthesis) then
        raise ESQLMemException.Create(12467,ErrorGLeftParenthesisExpected,
                [Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      // EXPRESSION
      expr := ParseValueExpression;
      if (expr = nil) then
       raise ESQLMemException.Create(12468,ErrorGArgumentExpected,
              [GetOperatorName(doNULLIFFUNCTION), Token.LineNum, Token.ColumnNum]);
      if (Token.TokenType = tktComma) then
       begin
        // get next token
        GetNextToken;
        // replacement
        expr1 := ParseValueExpression;
       end;
      if (expr1 = nil) then
       raise ESQLMemException.Create(12469,ErrorGArgumentExpected,
              [GetOperatorName(doNULLIFFUNCTION), Token.LineNum, Token.ColumnNum]);
      if (Token.TokenType <> tktRightParenthesis) then
        raise ESQLMemException.Create(12470,ErrorGMissingRightParenthesis,
                [Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      Result := TSQLMemExprNodeNullIfFunction.Create(Self, doNULLIFFUNCTION, expr, expr1);
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
end; // ParseNullIfExpression


{$IFNDEF EXPR_PARSING_1}
//------------------------------------------------------------------------------
// parses <string value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseStringValueExpression: TSQLMemExprNode;
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
function TSQLMemExpression.ParseCharacterValueExpression: TSQLMemExprNode;
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
function TSQLMemExpression.ParseConcatination: TSQLMemExprNode;
var
  left, right: TSQLMemExprNode;
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
     Result := TSQLMemExprNodeStringFunction.Create(Self, doConcat, left);
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


//------------------------------------------------------------------------------
// parses <character factor>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCharacterFactor: TSQLMemExprNode;
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
function TSQLMemExpression.ParseCharacterPrimary: TSQLMemExprNode;
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
function TSQLMemExpression.ParseGeneralLiteral: TSQLMemExprNode;
begin
{
<general literal> ::=
      <character AnsiString literal>
    | <national character AnsiString literal>
    | <bit AnsiString literal>
    | <hex AnsiString literal>
    | <datetime literal>
    | <interval literal>
}
  Result := ParseCharacterStringLiteral;
end;//ParseGeneralLiteral


//------------------------------------------------------------------------------
// parses <string value function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseStringValueFunction: TSQLMemExprNode;
begin
{
<string value function> ::=
      <character value function>
    | <bit value function>
}
  Result := ParseCharacterValueFunction;
end;//ParseStringValueFunction


{$ENDIF}


//------------------------------------------------------------------------------
// parses <character value function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCharacterValueFunction: TSQLMemExprNode;
var
  arg1,arg2,arg3: TSQLMemExprNode;
  op:             TSQLMemDataOperator;
  trimType:       TSQLMemTrimType;
  bSimple:        Boolean;
begin
{
<character value function> ::=
      <character SUBString function>
    | <fold>
    | <form-of-use conversion>
    | <character translation>
    | <trim function>
}
  arg1 := nil;
  arg2 := nil;
  arg3 := nil;
  Result := nil;
  op := doUNDEFINED;
  try
    if IsReservedWord(Token, rwUPPER) then op:=doUPPER
    else if IsReservedWord(Token, rwLOWER) then op:=doLOWER
    else if IsReservedWord(Token, rwTRIM) then op:=doTRIM
    else if IsReservedWord(Token, rwLTRIM) then op:=doLTRIM
    else if IsReservedWord(Token, rwRTRIM) then op:=doRTRIM
    else if IsReservedWord(Token, rwSUBString) then op:=doSUBString
    else if IsReservedWord(Token, rwTOString) then op:=doTOString
    else if IsReservedWord(Token, rwCONCAT) then op:=doCONCAT
    else if IsReservedWord(Token, rwASCII) then op:=doASCII
    else if (IsReservedWord(Token, rwCHR) or IsReservedWord(Token, rwCHAR)) then op:=doCHR
    else if IsReservedWord(Token, rwREPEAT) then op:=doREPEAT
    else if IsReservedWord(Token, rwREPLACE) then op:=doREPLACE
    ;
    if op = doUNDEFINED then Exit;
    // get next token
    GetNextToken;

    // Functions with 1 agrument
    if op in [doUPPER, doLOWER, doLTRIM, doRTRIM, doASCII, doCHR] then
    begin
      // '('
      if Token.TokenType <> tktLeftParenthesis then
        raise ESQLMemException.Create(30090, ErrorGOtherTokenExpected,
                               ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;

      // arg1
      arg1 := ParseValueExpression;

      // ')'
      if Token.TokenType <> tktRightParenthesis then
        raise ESQLMemException.Create(30091, ErrorGOtherTokenExpected,
                               [')', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;

      if arg1 = nil then
        raise ESQLMemException.Create(30092, ErrorGStringArgumentExpected,
               [GetOperatorName(op), Token.Text, Token.LineNum, Token.ColumnNum]);
      Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1);
    end
    else
    if op = doTRIM then
    begin
      // TRAILING, LEADING, BOTH - added in v.5.80
      // '('
      if Token.TokenType <> tktLeftParenthesis then
        raise ESQLMemException.Create(30090, ErrorGOtherTokenExpected,
                               ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;

      bSimple := False;
      if (IsReservedWord(token,rwLEADING)) then
       trimType := attLeading
      else
      if (IsReservedWord(token,rwTRAILING)) then
       trimType := attTrailing
      else
      if (IsReservedWord(token,rwBOTH)) then
       trimType := attBoth
      else
      begin
       // simple Trim
       bSimple := True;
      end;
      if (bSimple) then
      begin
        // arg1
        arg1 := ParseValueExpression;
        if arg1 = nil then
          raise ESQLMemException.Create(30092, ErrorGStringArgumentExpected,
                 [GetOperatorName(op), Token.Text, Token.LineNum, Token.ColumnNum]);
        // ')'
        if Token.TokenType <> tktRightParenthesis then
          raise ESQLMemException.Create(30091, ErrorGOtherTokenExpected,
                                 [')', Token.Text, Token.LineNum, Token.ColumnNum]);
        // get next token
        GetNextToken;
        Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1);
      end
      else
      begin
        // get next token
        GetNextToken;
        // arg1
        arg1 := ParseValueExpression;
        if arg1 = nil then
          raise ESQLMemException.Create(12453, ErrorGStringArgumentExpected,
                 [GetOperatorName(op), Token.Text, Token.LineNum, Token.ColumnNum]);
        if (not IsReservedWord(Token,rwFROM)) then
         raise ESQLMemException.Create(12454,ErrorGOtherTokenExpected,
               ['FROM', Token.Text, Token.LineNum, Token.ColumnNum]);
        // get next token
        GetNextToken;
        // arg2
        arg2 := ParseValueExpression;
        if arg2 = nil then
          raise ESQLMemException.Create(12455, ErrorGStringArgumentExpected,
                 [GetOperatorName(op), Token.Text, Token.LineNum, Token.ColumnNum]);
        // ')'
        if Token.TokenType <> tktRightParenthesis then
          raise ESQLMemException.Create(12456, ErrorGOtherTokenExpected,
                                 [')', Token.Text, Token.LineNum, Token.ColumnNum]);
        // get next token
        GetNextToken;
        Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1, arg2, trimType, FCaseInsensitive, FPartialKey);
      end; // advanced trim
    end
    else
    // Functions with 2 agruments
    if (op = doTOString) or (op = doCONCAT) or (op = doREPEAT) then
     begin
      // '('
      if Token.TokenType <> tktLeftParenthesis then
        raise ESQLMemException.Create(30093, ErrorGOtherTokenExpected,
                               ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;

      //TOString(str, format)
      // AnsiString
      arg1 := ParseValueExpression;
      if arg1 = nil then
       raise ESQLMemException.Create(30094, ErrorGArgumentExpected,
                          [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
      // ','
      if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwFrom) then
       begin
        arg1.Free;
        raise ESQLMemException.Create(30095, ErrorGOtherTokenExpected,
                               [',', Token.Text, Token.LineNum, Token.ColumnNum]);
       end;
      // get next token
      GetNextToken;

      if (op = doCONCAT) or (op = doREPEAT) then
      begin
        arg2 := ParseValueExpression;
        if arg2 = nil then
         raise ESQLMemException.Create(12477, ErrorGArgumentExpected,
                          [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
        Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1, arg2);
      end
      else
      begin
        // format
        if Token.TokenType <> tktQuotedString then
         begin
          arg1.Free;
          raise ESQLMemException.Create(30096, ErrorGConstDateFormatExpected,
                                 [Token.Text, Token.LineNum, Token.ColumnNum]);
         end;
        Result := TSQLMemExprNodeDateFunction.Create(Self, op, arg1, Token.Text);
        // get next token
        GetNextToken;
      end;
      // ')'
      if Token.TokenType <> tktRightParenthesis then
        raise ESQLMemException.Create(30097, ErrorGOtherTokenExpected,
                               [')', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
     end
    else
    // Functions with 3 agruments
    if (op = doSUBString) then
     begin
      // '('
      if Token.TokenType <> tktLeftParenthesis then
        raise ESQLMemException.Create(30098, ErrorGOtherTokenExpected,
                               ['(', Token.Text, Token.LineNum, Token.ColumnNum]);

      // get next token
      GetNextToken;

      //SUBString(str from|, startindex [for|, length])
      // AnsiString
      arg1 := ParseValueExpression;
      if arg1 = nil then
       raise ESQLMemException.Create(30099, ErrorGArgumentExpected,
                         [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
      // ','
      if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwFrom) then
       begin
        arg1.Free;
        raise ESQLMemException.Create(30100, ErrorGOtherTokenExpected,
                              [','' or ''from', Token.LineNum, Token.ColumnNum]);
       end;
      // get next token
      GetNextToken;

      // StartIndex
      // modivied in v.5.90
      {$IFDEF EXPR_PARSING_1}
      arg2 := ParseValueExpression;
      {$ELSE}
      arg2 := ParseNumericValueExpression;
      {$ENDIF}
      if arg2 = nil then
       begin
        arg1.Free;
        raise ESQLMemException.Create(30101, ErrorGArgumentExpected,
                         [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
       end;

      // ','
      if (Token.TokenType <> tktComma) and not IsReservedWord(Token, rwFor) and
         (Token.TokenType <> tktRightParenthesis) then
       begin
        arg1.Free;
        arg2.Free;
        raise ESQLMemException.Create(30103, ErrorGOtherTokenExpected,
                       [')'' or '','' or ''FOR', Token.LineNum, Token.ColumnNum]);
       end;
      // lenghth
      if Token.TokenType = tktRightParenthesis then
       arg3 := nil
      else
       begin
        // get next token
        GetNextToken;
        // modified in v.5.90
        {$IFDEF EXPR_PARSING_1}
        arg3 := ParseValueExpression;
        {$ELSE}
        arg3 := ParseNumericValueExpression;
        {$ENDIF}
       end;

      // ')'
      if Token.TokenType <> tktRightParenthesis then
        raise ESQLMemException.Create(30104, ErrorGOtherTokenExpected,
                               [')', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      if arg3 = nil then
        Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1,arg2)
      else
        Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1,arg2,arg3);
     end
    else
    // Functions with 3 agruments
    if (op = doREPLACE) then
     begin
      // '('
      if Token.TokenType <> tktLeftParenthesis then
        raise ESQLMemException.Create(12478, ErrorGOtherTokenExpected,
                               ['(', Token.Text, Token.LineNum, Token.ColumnNum]);

      // get next token
      GetNextToken;

      //SUBString(str from|, startindex [for|, length])
      // AnsiString
      arg1 := ParseValueExpression;
      if arg1 = nil then
       raise ESQLMemException.Create(12479, ErrorGArgumentExpected,
                         [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
      // ','
      if (Token.TokenType <> tktComma) then
       begin
        arg1.Free;
        raise ESQLMemException.Create(12480, ErrorGOtherTokenExpected,
                              [',', Token.LineNum, Token.ColumnNum]);
       end;
      // get next token
      GetNextToken;

      // StartIndex
      arg2 := ParseValueExpression;
      if arg2 = nil then
       begin
        arg1.Free;
        raise ESQLMemException.Create(12481, ErrorGArgumentExpected,
                         [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
       end;

      // ','
      if (Token.TokenType <> tktComma) then
       begin
        arg1.Free;
        arg2.Free;
        raise ESQLMemException.Create(12482, ErrorGOtherTokenExpected,
                       [',', Token.LineNum, Token.ColumnNum]);
       end;
      // get next token
      GetNextToken;
      arg3 := ParseValueExpression;
      if arg3 = nil then
       begin
        arg1.Free;
        arg2.Free;
        raise ESQLMemException.Create(12483, ErrorGArgumentExpected,
                         [GetOperatorName(op), Token.LineNum, Token.ColumnNum]);
       end;

      // ')'
      if Token.TokenType <> tktRightParenthesis then
        raise ESQLMemException.Create(12484, ErrorGOtherTokenExpected,
                               [')', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      Result := TSQLMemExprNodeStringFunction.Create(Self, op, arg1,arg2,arg3);
     end; // REPLACE
  except
   on e: Exception do
   begin
    if (arg1 <> nil) then
    try
      arg1.Free;
    except
    end;
    if (arg2 <> nil) then
    try
      arg2.Free;
    except
    end;
    if (arg3 <> nil) then
    try
      arg3.Free;
    except
    end;
    raise;
   end;
  end;
end;//ParseCharacterValueFunction


//------------------------------------------------------------------------------
// parses <BLOB value function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseBLOBValueFunction: TSQLMemExprNode;
var
  op:              TSQLMemDataOperator;
  BLOBValue:       AnsiString;
  BLOBValueFormat: TSQLMemBLOBValueFormat;
begin
{
<BLOB value function> ::=
  TOBLOB ('BLOBValue' [, MIME64 | HEX])
}
  Result := nil;
  if IsReservedWord(Token, rwTOBLOB) then
   op:=doTOBLOB
  else
  Exit;
  // get next token
  GetNextToken;
  case op of
   doTOBLOB:
    begin
      BLOBValueFormat := bvfMIME64;
      if Token.TokenType <> tktLeftParenthesis then
        raise ESQLMemException.Create(11345, ErrorGOtherTokenExpected,
                               ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
      // get next token
      GetNextToken;
      if Token.TokenType <> tktQuotedString then
        raise ESQLMemException.Create(11346, ErrorLConstBLOBValueExpected,
                               [Token.Text, Token.LineNum, Token.ColumnNum]);
      BLOBValue := Token.Text;
      Token.Text := ''; // to avoid unnecessary memory usage
      // get next token
      GetNextToken;
      if Token.TokenType = tktComma then
       begin
        // get next token
        GetNextToken;
        if (IsReservedWord(Token,rwHEX)) then
         BLOBValueFormat := bvfHEX
        else
        if (IsReservedWord(Token,rwMIME64)) then
         BLOBValueFormat := bvfMIME64
        else
         raise ESQLMemException.Create(11347, ErrorLBLOBValueFormatExpected,
                               [Token.Text, Token.LineNum, Token.ColumnNum]);
        // get next token
        GetNextToken;
       end;
      if Token.TokenType <> tktRightParenthesis then
        raise ESQLMemException.Create(11348, ErrorGOtherTokenExpected,
                               [')', Token.Text, Token.LineNum, Token.ColumnNum]);
      Result := TSQLMemExprNodeBLOBFunction.Create(Self, op,BLOBValue,BLOBValueFormat);
    end;
  end;
 // get next token
 GetNextToken;
end; // ParseBLOBValueFunction


//------------------------------------------------------------------------------
// parses <datetime value expression>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseDatetimeValueExpression: TSQLMemExprNode;
var
     SavedTokenNo: Integer;        // saved/restored information
     Term:         TSQLMemExprNode;
begin
{
 <datetime value expression> ::=
   <datetime CURRENT_TIMESTAMP function>
   | <datetime CURRENT_TIME function>
   | <datetime CURRENT_DATE function>
   | <datetime to_date function>
   | :ParameterName
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
    Result := ParseDateAddFunction;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseDateDiffFunction;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    Result := ParseDateTimeExtractFunction;
  end;
 if (Result = nil) then
  begin
    // restore original state
    RestoreState(SavedTokenNo);
    if (Token.TokenType = tktParameter) then
      begin
        if Token.ParamValue.IsDateTimeDataType then
          begin
            Result := TSQLMemExprNodeConst.Create(Self);
            Result.IsParameter := True;
            Result.ParamCRC := GetTableNameCRC(Token.Text);
            Result.Value.Assign(Token.ParamValue);
            // get next token
            GetNextToken;
          end;
      end;
  end;
// modified in v.5.90
{$IFNDEF EXPR_PARSING_1}
  if Result <> nil then
   begin
    // date operators + / -
    if (Token.Text='+') or (Token.Text='-') then
     begin
      Result := TSQLMemExprNodeArithmetic.Create(Self, doADD, Result);
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
     end;
    if Token.Text='||' then
     begin
      Result.Free;
      Result := nil;
     end;
   end; // DateTime parsed
{$ENDIF}
end;//ParseDatetimeValueExpression


//------------------------------------------------------------------------------
// parse <datetime sysdate function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseSysdateFunction: TSQLMemExprNode;
begin
 if IsReservedWord(Token, rwSYSDATE) or
    IsReservedWord(Token, rwNOW) or
    IsReservedWord(Token, rwCURRENT_TIMESTAMP) then
  begin
   // get next token
   GetNextToken;
   Result := TSQLMemExprNodeDateFunction.Create(Self, doSYSDATE);
  end
 else
  Result := nil;
end;//ParseSysdateFunction


//------------------------------------------------------------------------------
// parse <datetime CURRENT_TIME function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCurrentTimeFunction: TSQLMemExprNode;
begin
 if IsReservedWord(Token, rwCURRENT_TIME) then
  begin
   // get next token
   GetNextToken;
   Result := TSQLMemExprNodeDateFunction.Create(Self, doCURRENT_TIME);
  end
 else
  Result := nil;
end;//ParseCurrentTimeFunction


//------------------------------------------------------------------------------
// parse <datetime CURRENT_DATE function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseCurrentDateFunction: TSQLMemExprNode;
begin
 if IsReservedWord(Token, rwCURRENT_DATE) then
  begin
   // get next token
   GetNextToken;
   Result := TSQLMemExprNodeDateFunction.Create(Self, doCURRENT_DATE);
  end
 else
  Result := nil;
end;//ParseCurrentDateFunction


//------------------------------------------------------------------------------
// parse <datetime TODATE function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseToDateFunction: TSQLMemExprNode;
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
      raise ESQLMemException.Create(30105, ErrorGOtherTokenExpected,
                             ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
   // get next token
   GetNextToken;

   // AnsiString
   {$IFDEF EXPR_PARSING_1}
   Result := ParseValueExpression;
   {$ELSE}
   Result := ParseCharacterValueExpression;
   {$ENDIF}
   if Result = nil then
    raise ESQLMemException.Create(30107, ErrorGArgumentExpected,
                                    ['ToDate', Token.LineNum, Token.ColumnNum]);
   // ','
   if Token.TokenType <> tktComma then
    begin
      Result.Free;
      raise ESQLMemException.Create(30108, ErrorGOtherTokenExpected,
                             [',', Token.Text, Token.LineNum, Token.ColumnNum]);
    end;
   // get next token
   GetNextToken;

   // format
   if Token.TokenType <> tktQuotedString then
    begin
     Result.Free;
     raise ESQLMemException.Create(30109, ErrorGConstDateFormatExpected,
                                  [Token.Text, Token.LineNum, Token.ColumnNum]);
    end;

   Result := TSQLMemExprNodeDateFunction.Create(Self, doTODATE, Result, Token.Text);

   // get next token
   GetNextToken;

   // ')'
   if Token.TokenType <> tktRightParenthesis then
    begin
     Result.Free;
      raise ESQLMemException.Create(30106, ErrorGOtherTokenExpected,
                             [')', Token.Text, Token.LineNum, Token.ColumnNum]);
    end;
   // get next token
   GetNextToken;
  end
 else
  Result := nil;
end;//ParseToDateFunction


//------------------------------------------------------------------------------
// return parsed DatePart or dpUNDEFINED if it was not parsed
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseDatePart: TSQLMemDatePart;
begin
  if (IsReservedWord(Token,rwYEAR)) then
   Result := dpYEAR
  else
  if (IsReservedWord(Token,rwQUARTER)) then
   Result := dpQUARTER
  else
  if (IsReservedWord(Token,rwMONTH)) then
   Result := dpMONTH
  else
  if (IsReservedWord(Token,rwDAY) or IsReservedWord(Token,rwDAYOFWEEK) or IsReservedWord(Token,rwWEEKDAY)) then
   Result := dpDAY
  else
  if (IsReservedWord(Token,rwWEEK)) then
   Result := dpWEEK
  else
  if (IsReservedWord(Token,rwHOUR)) then
   Result := dpHOUR
  else
  if (IsReservedWord(Token,rwMINUTE)) then
   Result := dpMINUTE
  else
  if (IsReservedWord(Token,rwSECOND)) then
   Result := dpSECOND
  else
  if (IsReservedWord(Token,rwMILLISECOND) or IsReservedWord(Token,rwMSECOND)) then
   Result := dpMILLISECOND
  else
   Result := dpUNDEFINED;
end; // ParseDatePart


//------------------------------------------------------------------------------
// parse <datetime DATEADD function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseDateAddFunction: TSQLMemExprNode;
var DatePart: TSQLMemDatePart;
    n:        Integer;
    date:     TSQLMemExprNode;
    number:   TSQLMemExprNode;
begin
  Result := nil;
  if (IsReservedWord(Token,rwDATEADD)) then
  begin
   date := nil;
   number := nil;
   try
     GetNextToken;
     if (Token.TokenType <> tktLeftParenthesis) then
      raise ESQLMemException.Create(12439,ErrorGLeftParenthesisExpected,
             [Token.Text, Token.LineNum, Token.ColumnNum]);
     GetNextToken;
     DatePart := ParseDatePart;
     GetNextToken;
     if (Token.TokenType <> tktComma) then
      raise ESQLMemException.Create(12435,ErrorGOtherTokenExpected,
           [',', Token.Text, Token.LineNum, Token.ColumnNum]);
     GetNextToken;
     number := ParseValueExpression;
     if (number = nil) then
      raise ESQLMemException.Create(12436,ErrorLNumericArgumentExpected,
           ['DATEADD', Token.Text, Token.LineNum, Token.ColumnNum]);
     if (Token.TokenType <> tktComma) then
      raise ESQLMemException.Create(12437,ErrorGOtherTokenExpected,
           [',', Token.Text, Token.LineNum, Token.ColumnNum]);
     GetNextToken;
     date := ParseValueExpression;
     if (date <> nil) then
     begin
       if (Token.TokenType <> tktRightParenthesis) then
        raise ESQLMemException.Create(12440,ErrorGrightParenthesisExpected,
               [Token.Text, Token.LineNum, Token.ColumnNum]);
       GetNextToken;
       Result := TSQLMemExprNodeDateAddFunction.Create(Self,DatePart,number,date);
     end
     else
      raise ESQLMemException.Create(12441,ErrorGArgumentExpected,[GetReservedWord(rwDATEADD),Token.LineNum,Token.ColumnNum]);
   except
     if (date <> nil) then
      FreeAndNil(date);
     if (number <> nil) then
      FreeAndNil(number);
   end;
  end; // DateAdd
end; // ParseDateAddFunction


//------------------------------------------------------------------------------
// parse <datetime DATEDIFF function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseDateDiffFunction: TSQLMemExprNode;
var DatePart:       TSQLMemDatePart;
    sNode,eNode:    TSQLMemExprNode;
begin
  Result := nil;
  if (IsReservedWord(Token,rwDATEDIFF)) then
  begin
   GetNextToken;
   if (Token.TokenType <> tktLeftParenthesis) then
    raise ESQLMemException.Create(12443,ErrorGLeftParenthesisExpected,
           [Token.Text, Token.LineNum, Token.ColumnNum]);
   GetNextToken;
   DatePart := ParseDatePart;
   GetNextToken;
   if (Token.TokenType <> tktComma) then
    raise ESQLMemException.Create(12444,ErrorGOtherTokenExpected,
         [',', Token.Text, Token.LineNum, Token.ColumnNum]);
   GetNextToken;
   eNode := nil;
   sNode := ParseValueExpression;
   if (sNode <> nil) then
   begin
     try
       if (Token.TokenType <> tktComma) then
        raise ESQLMemException.Create(12445,ErrorGOtherTokenExpected,
             [',', Token.Text, Token.LineNum, Token.ColumnNum]);
       GetNextToken;
       eNode := ParseValueExpression;
       if (eNode = nil) then
        raise ESQLMemException.Create(12446,ErrorGArgumentExpected,[GetReservedWord(rwDATEADD),Token.LineNum,Token.ColumnNum]);
     except
      if (sNode <> nil) then
       sNode.Free;
      if (eNode <> nil) then
       eNode.Free;
      raise;
     end;
     if (Token.TokenType <> tktRightParenthesis) then
      raise ESQLMemException.Create(12447,ErrorGrightParenthesisExpected,
             [Token.Text, Token.LineNum, Token.ColumnNum]);
     GetNextToken;
     Result := TSQLMemExprNodeDateDiffFunction.Create(Self,DatePart,sNode,eNode);
   end
   else
    raise ESQLMemException.Create(12448,ErrorGArgumentExpected,[GetReservedWord(rwDATEADD),Token.LineNum,Token.ColumnNum]);
  end;
end; // ParseDateDiffFunction


//------------------------------------------------------------------------------
// parse <datetime extract functions>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseDateTimeExtractFunction: TSQLMemExprNode;
var
  arg:        TSQLMemExprNode;
  Operator:   TSQLMemDataOperator;
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
     raise ESQLMemException.Create(11601, ErrorGOtherTokenExpected,
                            ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
    // get next token
    GetNextToken;
   end
  else
   bExtract := False;
  if IsReservedWord(Token, rwYEAR) then Operator:=doYEAR
  else if IsReservedWord(Token, rwQUARTER) then Operator:=doQUARTER
  else if IsReservedWord(Token, rwMONTH) then Operator:=doMONTH
  else if IsReservedWord(Token, rwDAY) then Operator:=doDAY
  else if IsReservedWord(Token, rwWEEK) then Operator:=doWEEK
  else if IsReservedWord(Token, rwISOWEEK) then Operator:=doISOWEEK
  else if IsReservedWord(Token, rwWEEKDAY) then Operator:=doWEEKDAY
  else if IsReservedWord(Token, rwDAYOFWEEK) then Operator:=doDAYOFWEEK
  else if IsReservedWord(Token, rwDAYOFYEAR) then Operator:=doDAYOFYEAR
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
      raise ESQLMemException.Create(11602,ErrorLFromOrCommaExpected,
            [Token.Text, Token.LineNum, Token.ColumnNum]);

   end
  else
   begin
    if (Token.TokenType <> tktLeftParenthesis) then
     raise ESQLMemException.Create(11603, ErrorGOtherTokenExpected,
                            ['(', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
  // get next token
  GetNextToken;
  arg := ParseValueExpression;
  if (arg = nil) then
    raise ESQLMemException.Create(11604,ErrorGArgumentExpected,
            [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum]);
  if (Token.TokenType <> tktRightParenthesis) then
   begin
    arg.Free;
    raise ESQLMemException.Create(11605, ErrorGOtherTokenExpected,
                            [')', Token.Text, Token.LineNum, Token.ColumnNum]);
   end;
   Result := TSQLMemExprNodeDateFunction.Create(Self, Operator, arg, '');
   // get next token
   GetNextToken;
end; // ParseDateTimeExtractFunction


//------------------------------------------------------------------------------
// parse <Math function>
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseMathFunction: TSQLMemExprNode;
var
  arg,arg1:   TSQLMemExprNode;
  Operator:   TSQLMemDataOperator;
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
  else if IsReservedWord(Token, rwCUMSUM) then Operator:=doCUMSUM
  else if IsReservedWord(Token, rwCUMPROD) then Operator:=doCUMPROD
  else if IsReservedWord(Token, rwEXP) then Operator:=doEXP
  else if IsReservedWord(Token, rwLOG) or IsReservedWord(Token, rwLN) then Operator:=doLOG
  else if IsReservedWord(Token, rwLOG10) then Operator:=doLOG10
  else if IsReservedWord(Token, rwCOS) then Operator:=doCOS
  else if IsReservedWord(Token, rwSIN) then Operator:=doSIN
  else if IsReservedWord(Token, rwACOS) then Operator:=doACOS
  else if IsReservedWord(Token, rwASIN) then Operator:=doASIN
  else if IsReservedWord(Token, rwATAN) then Operator:=doATAN
  else if IsReservedWord(Token, rwATAN2) then Operator:=doATAN2
  else if IsReservedWord(Token, rwCOT) then Operator:=doCOT
  else if IsReservedWord(Token, rwTAN) then Operator:=doTAN
  else if IsReservedWord(Token, rwSQR) or IsReservedWord(Token, rwSQUARE) then Operator:=doSQR
  else if IsReservedWord(Token, rwSQRT) then Operator:=doSQRT
  else if IsReservedWord(Token, rwDEGREES) then Operator:=doDEGREES
  else if IsReservedWord(Token, rwRADIANS) then Operator:=doRADIANS
  else if IsReservedWord(Token, rwPI) then Operator:=doPI
  ;
  if Operator = doUNDEFINED then Exit;

  // get next token
  GetNextToken;
  if ((Operator = doRANDOM) or (Operator = doPI)) and (Token.TokenType <> tktLeftParenthesis) then
   begin
    Result := TSQLMemExprNodeArithmetic.Create(Self, Operator);
    Exit;
   end;

   // first argument must be in all operators
   if (Token.TokenType <> tktLeftParenthesis) then
     raise ESQLMemException.Create(11639,ErrorGLeftParenthesisExpected,
             [Token.Text, Token.LineNum, Token.ColumnNum]);
   GetNextToken;
   arg := ParseValueExpression;
   if (arg = nil) then
     raise ESQLMemException.Create(11640, ErrorGArgumentExpected,
              [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum]);

   // MOD, POWER, ATAN2 always with 2 params
   if ((Operator = doMOD) or (Operator = doPOWER) or (Operator = doATAN2)) then
    begin
     if (Token.TokenType <> tktComma) then
      begin
       if (arg <> nil) then
        arg.Free;
       raise ESQLMemException.Create(11641,ErrorGOtherTokenExpected,
              [',', Token.Text, Token.LineNum, Token.ColumnNum]);
      end;
     GetNextToken;
     arg1 := ParseValueExpression;
     if (arg1 = nil) then
      begin
       if (arg <> nil) then
        arg.Free;
       raise ESQLMemException.Create(11642, ErrorGArgumentExpected,
              [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum]);
      end;
    end; // MOD

   // RANDOM with 0 or 1 parameter
   // ROUND, TRUNC, HEX, LOG can be with 1 or 2 parameters;
   if ((Operator = doROUND) or (Operator = doTRUNCATE) or (Operator = doHEX) or (Operator = doLOG)) then
    begin
     if (Token.TokenType = tktComma) then
      begin
       GetNextToken;
       arg1 := ParseValueExpression;
       if (arg1 = nil) then
        begin
         if (arg <> nil) then
          arg.Free;
         raise ESQLMemException.Create(11643, ErrorGArgumentExpected,
              [GetOperatorName(Operator), Token.LineNum, Token.ColumnNum]);
        end;
      end;
    end; // ROUND, TRUNCATE, RANDOM

   if (Token.TokenType <> tktRightParenthesis) then
     begin
      if (arg <> nil) then
       arg.Free;
      if (arg1 <> nil) then
       arg1.Free;
      raise ESQLMemException.Create(11644,ErrorGRightParenthesisExpected,
             [Token.Text, Token.LineNum, Token.ColumnNum]);
     end;
   if (arg1 = nil) then
    Result := TSQLMemExprNodeArithmetic.Create(Self, Operator, arg)
   else
    Result := TSQLMemExprNodeArithmetic.Create(Self, Operator, arg, arg1);
   GetNextToken;
end; // ParseMathFunction


//------------------------------------------------------------------------------
// parse stored function
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseStoredFunction: TSQLMemExprNode;
var storedFunction:  TSQLMemStoredFunction;
    params:          TObject;
begin
  Result := nil;
  if (LSession <> nil) then
    if (LSession is TSQLMemLocalSession) then
      begin
       storedFunction := TSQLMemStoredFunction(TSQLMemLocalSession(LSession).ParseStoredFunctionParams(LLex,LStoredFunction,Token,params));
       if (storedFunction <> nil) then
         Result := TSQLMemExprNodeStoredFunction.Create(Self,storedFunction.FunctionName,TSQLMemExpressions(params));
      end;
end; // ParseStoredFunction


//------------------------------------------------------------------------------
// parse variable
//------------------------------------------------------------------------------
function TSQLMemExpression.ParseVariable: TSQLMemExprNode;
var paramIndex: Integer;
begin
 Result := nil;
 if ((Token.TokenType = tktString) or
     ((LStoredFunction <> nil) and (Token.ReservedWord = rwResult))) then
  begin
   if (SQLMemIsSessionVariable(Token.Text)) then
    begin
     Result := TSQLMemExprNodeVariable.Create(Self, Token.Text,nil,-1);
    end
   else
   if (LStoredFunction <> nil) then
     begin
      paramIndex := TSQLMemStoredFunction(LStoredFunction).GetParamIndex(Token.Text);
      if (paramIndex >= 0) then
        Result := TSQLMemExprNodeVariable.Create(Self, Token.Text,
                    TSQLMemStoredFunction(LStoredFunction),paramIndex);
     end;
  end;
 if (Result <> nil) then
  GetNextToken;
end; // ParseVariable


//------------------------------------------------------------------------------
// Clear all Variables
//------------------------------------------------------------------------------
procedure TSQLMemExpression.Clear;
begin
  // free nodes tree
  if (FRootExprNode <> nil) then
    FreeAndNil(FRootExprNode);
end;//Clear


//------------------------------------------------------------------------------
// copy required params from source expression
//------------------------------------------------------------------------------
procedure TSQLMemExpression.Assign(SourceExpr: TSQLMemExpression; CopyRootExprNode: Boolean);
begin
  LSQLCommand := SourceExpr.LSQLCommand;
  LStoredFunction := SourceExpr.LStoredFunction;
  LSession := SourceExpr.LSession;
  Clear;
  LParams := SourceExpr.LParams;
  // make copy of root expression node
  if (CopyRootExprNode) then
   if (SourceExpr.FRootExprNode <> nil) then
    FRootExprNode := SourceExpr.FRootExprNode.MakeCopy(Self);
  LLex := SourceExpr.LLex;
  FCaseInsensitive := SourceExpr.FCaseInsensitive;
  FPartialKey := SourceExpr.FPartialKey;
  F3ValueLogic := SourceExpr.F3ValueLogic;
  if (SourceExpr.Params <> nil) then
   begin
    if (FParams = nil) then
     FParams := TParams.Create(nil);
    FParams.AssignValues(SourceExpr.Params);
   end
  else
   if (FParams <> nil) then
    begin
     FParams.Free;
     FParams := nil;
    end;
end; // Assign


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemExpression.Create(aSession: TSQLMemBaseSession; aParams: TSQLMemSQLParams);
begin
  LSession := aSession;
  LParams := aParams;
  FRootExprNode := nil;
  LLex := nil;
  LSQLCommand := nil;
  LStoredFunction := nil;
  FCaseInsensitive := False;
  FPartialKey := False;
  F3ValueLogic := True;
  Params := nil;
{$IFNDEF EXPR_PARSING_1}
  FNumLeftParenthesis := 0;
  FNumRightParenthesis := 0;
{$ENDIF}
end;//Create


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemExpression.Create(aSession: TSQLMemBaseSession; aParams: TSQLMemSQLParams; RootNode: TSQLMemExprNode; aSQLCommand: TObject);
begin
  Create(aSession,aParams);
  FRootExprNode := RootNode;
  if (aSQLCommand is TSQLMemSQLCommand) then
   LSQLCommand := aSQLCommand;
  if (LSQLCommand <> nil) then
   LStoredFunction := TSQLMemSQLCommand(LSQLCommand).StoredFunction;
end;//Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemExpression.Destroy;
begin
  Clear;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// PrepareForeignKeyCheck
//------------------------------------------------------------------------------
procedure TSQLMemExpression.PrepareForeignKeyCheck(
                                  ReferencedCursor: TSQLMemCursor;
                                  Cursor:           TSQLMemCursor;
                                  ConstraintDef:    TSQLMemConstraintDefForeignKey;
                                  PrimaryIndex:     TSQLMemIndexDef
                               );
var
    i,h,FieldNo:    Integer;
    value:          TSQLMemVariant;
    EqNode:         TSQLMemExprNode;
    NodeConst:      TSQLMemExprNodeConst;
    NodeField:      TSQLMemExprNodeField;
begin
  Clear;
  LCursor := ReferencedCursor;
  F3ValueLogic := False;
  FCaseInsensitive := Cursor.CaseInsensitive;
  FPartialKey := False;
  value := TSQLMemVariant.Create;
  try
    h := High(ConstraintDef.Columns);
    for i := 0 to h do
     begin
      FieldNo := Cursor.FieldDefs.GetDefNumberByObjectId(ConstraintDef.Columns[i].ColumnObjectID);
      Cursor.GetFieldValue(value,FieldNo,True,False);
      if (not value.IsNull) then
       begin
        // const (from record in detail table - Cursor)
        NodeConst := TSQLMemExprNodeConst.Create(Self, False, False);
        NodeConst.Value.Assign(value,True);
        NodeConst.Value.ConvertWideStringToAnsiStringIfNotUnicode;
        // field (from referenced table)
        NodeField := TSQLMemExprNodeField.Create(Self,LCursor,PrimaryIndex.Columns[i].FieldName);
        EqNode := TSQLMemExprNodeComparison.Create(Self,doEQ,NodeField,NodeConst,False,FCaseInsensitive,False);
        if (FRootExprNode = nil) then
         begin
          if (i = h) then
           FRootExprNode := EqNode
          else
           FRootExprNode := TSQLMemExprNodeBoolean.Create(Self,doAND,EqNode,FCaseInsensitive,False);
         end
        else
         FRootExprNode.Children.Add(EqNode);
       end;
     end; // for (scan constraint columns)
  finally
    value.Free;
  end;
  FRootExprNode.PatchWideStrings;
end; // PrepareForeignKeyCheck


//------------------------------------------------------------------------------
// foreign key action
//------------------------------------------------------------------------------
procedure TSQLMemExpression.PrepareForeignKeyActionFilter(
                                    ReferencedCursor: TSQLMemCursor;
                                    Cursor:           TSQLMemCursor;
                                    ConstraintDef:    TSQLMemConstraintDefForeignKeyAction;
                                    PrimaryIndex:     TSQLMemIndexDef
                                 );
var
    i,h,FieldNo:  Integer;
    value:          TSQLMemVariant;
    EqNode:         TSQLMemExprNode;
    NodeConst:      TSQLMemExprNodeConst;
    NodeField:      TSQLMemExprNodeField;
begin
  Clear;
  LCursor := ReferencedCursor;
  F3ValueLogic := (ConstraintDef.MatchType = cfkmtPartial);
  FCaseInsensitive := False;
  FPartialKey := False;
  value := TSQLMemVariant.Create;
  try
    h := High(ConstraintDef.Columns);
    for i := 0 to h do
     begin
      FieldNo := Cursor.FieldDefs.GetDefNumberByName(PrimaryIndex.Columns[i].FieldName);
      Cursor.GetFieldValue(value,FieldNo,True,False);
      if ((not value.IsNull) or (F3ValueLogic)) then
       begin
        // const (from record in master table - Cursor)
        NodeConst := TSQLMemExprNodeConst.Create(Self,False,False);
        NodeConst.Value.Assign(value,True);
        NodeConst.Value.ConvertWideStringToAnsiStringIfNotUnicode;
        // field (from detail table)
        NodeField := TSQLMemExprNodeField.Create(Self, LCursor, ConstraintDef.Columns[i].ColumnName);
        EqNode := TSQLMemExprNodeComparison.Create(Self, doEQ,NodeField,NodeConst,F3ValueLogic,FCaseInsensitive,False);
        if (FRootExprNode = nil) then
         begin
          if (i = h) then
           FRootExprNode := EqNode
          else
           FRootExprNode := TSQLMemExprNodeBoolean.Create(Self, doAND,EqNode,False,False);
         end
        else
         FRootExprNode.Children.Add(EqNode);
       end;
     end; // for (scan constraint columns)
  finally
    value.Free;
  end;
  FRootExprNode.PatchWideStrings;
end; // PrepareForeignKeyActionFilter


//------------------------------------------------------------------------------
// Parsing for Locate
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ParseForLocate(
                                          Cursor:           TSQLMemCursor;
                                          FieldNames:       WideString; // name1;name2
                                          KeyValues:        Variant; //
                                          CaseInsensitive:  Boolean = true;
                                          PartialKey:       Boolean = false
                                       );
var
  i,ArrLen:         Integer;
  FieldNamesList:   TSQLMemWideStringList;
  LeftNField:       TSQLMemExprNodeField;
  RightNConst:      TSQLMemExprNodeConst;
  EqNode:           TSQLMemExprNodeComparison;
  fieldName:        WideString;
begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStartTime(time2);
{$ENDIF}
  Clear;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time2);
{$ENDIF}
  LCursor := Cursor;
  F3ValueLogic := False;
  FCaseInsensitive := Cursor.CaseInsensitive or CaseInsensitive;
  FPartialKey := PartialKey;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStartTime(time3);
{$ENDIF}
  FieldNamesList := TSQLMemWideStringList.Create;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time3);
{$ENDIF}
  try
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStartTime(time4);
{$ENDIF}
    SQLMemParseFieldNames(FieldNames,FieldNamesList);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time4);
aaStartTime(time5);
{$ENDIF}
    // Determinate KeyValues count (can be array)
    if  (VarType(KeyValues) and varArray ) <> 0 then
      ArrLen := VarArrayHighBound(KeyValues,1) - VarArrayLowBound(KeyValues,1) + 1
    else
      ArrLen := 1;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time5);
{$ENDIF}
    if (FieldNamesList.Count <> ArrLen) then
      raise ESQLMemException.Create(30112, ErrorGNotEqualCountsOfFieldNamesAndKeyValues,
                                      [FieldNamesList.Count, ArrLen]);

    if (FieldNamesList.Count = 0) then
       raise ESQLMemException.Create(12389,ErrorLEmptyStringPassed)
    else
    if (ArrLen = 1) then
      begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
        // Field
        LeftNField := TSQLMemExprNodeField.Create(Self, LCursor, FieldNamesList[0]);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time6);
aaStartTime(time7);
{$ENDIF}
        // Const
        RightNConst := TSQLMemExprNodeConst.Create(Self);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time7);
aaStartTime(time8);
{$ENDIF}
        RightNConst.Value.AsVariant := KeyValues;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time8);
aaStartTime(time9);
{$ENDIF}
        RightNConst.Value.ConvertWideStringToAnsiStringIfNotUnicode;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time9);
aaStartTime(time10);
{$ENDIF}
        // RootNode
        FRootExprNode := TSQLMemExprNodeComparison.Create(Self, doEQ, LeftNField,
                                      RightNConst, F3ValueLogic, FCaseInsensitive, FPartialKey);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time10);
{$ENDIF}
      end
    else
      begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter11);
aaStartTime(time11);
{$ENDIF}
        FRootExprNode := TSQLMemExprNodeBoolean.Create(Self, doAND);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time11);
{$ENDIF}
        for i:=0 to ArrLen-1 do
          begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter12);
aaStartTime(time12);
{$ENDIF}
            // Field
            fieldName := FieldNamesList.FItems[i];
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time12);
aaStartTime(time20);
{$ENDIF}
            LeftNField := TSQLMemExprNodeField.Create(Self, LCursor, fieldName);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time20);
aaStartTime(time13);
{$ENDIF}
            // Check FieldExists
            // ...
            // Const
            RightNConst := TSQLMemExprNodeConst.Create(Self);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time13);
aaStartTime(time14);
{$ENDIF}
            RightNConst.Value.AsVariant := VarArrayGet(KeyValues, i);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time14);
aaStartTime(time15);
{$ENDIF}
            RightNConst.Value.ConvertWideStringToAnsiStringIfNotUnicode;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time15);
aaStartTime(time16);
{$ENDIF}
            // EqNode
            EqNode := TSQLMemExprNodeComparison.Create(Self, doEQ, LeftNField, RightNConst,
                                       F3ValueLogic, FCaseInsensitive, FPartialKey);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time16);
aaStartTime(time17);
{$ENDIF}
            // Add to RootNode
            FRootExprNode.Children.Add(EqNode);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time17);
{$ENDIF}
          end;
      end;
  finally
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStartTime(time18);
{$ENDIF}
    FieldNamesList.Free;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time18);
{$ENDIF}
  end;

  if LCursor <> nil then
  begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter19);
aaStartTime(time19);
{$ENDIF}
    FRootExprNode.PatchWideStrings;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time19);
{$ENDIF}
  end;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
finally
aaStopTime(time1);
end;
{$ENDIF}
end;//ParseForLocate


//------------------------------------------------------------------------------
// Parsing for Locate
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ParseForLocate(
                          Cursor:           TSQLMemCursor;
                          FieldNamesList:   TSQLMemWideStringList;
                          CaseInsensitive:  Boolean = true;
                          PartialKey:       Boolean = false
                        );
var
  i,l,s0,x:         Integer;
  LeftNField:       TSQLMemExprNodeField;
  RightNode:        TSQLMemExprNodeVariable;
  EqNode:           TSQLMemExprNodeComparison;
  fieldName:        WideString;
  wc:               WideChar;
begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter1);
aaStartTime(time1);
try
{$ENDIF}
  LCursor := Cursor;
  F3ValueLogic := False;
  FCaseInsensitive := Cursor.CaseInsensitive or CaseInsensitive;
  FPartialKey := PartialKey;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStartTime(time3);
{$ENDIF}
  if (FieldNamesList.Count = 0) then
     raise ESQLMemException.Create(12390,ErrorLEmptyStringPassed);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time3);
{$ENDIF}
  if (FieldNamesList.Count = 1) then
    begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter6);
aaStartTime(time6);
{$ENDIF}
      // Field
      LeftNField := TSQLMemExprNodeField.Create(Self, LCursor, FieldNamesList[0]);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time6);
aaStartTime(time7);
{$ENDIF}

{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time7);
aaStartTime(time8);
{$ENDIF}
      // Variable
      RightNode := TSQLMemExprNodeVariable.Create(Self,'',nil,0);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time8);
aaStartTime(time9);
{$ENDIF}
      // RootNode
      FRootExprNode := TSQLMemExprNodeComparison.Create(Self, doEQ, LeftNField,
                                    RightNode, F3ValueLogic, FCaseInsensitive, FPartialKey);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time9);
{$ENDIF}
    end
  else
    begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter11);
aaStartTime(time11);
{$ENDIF}
      FRootExprNode := TSQLMemExprNodeBoolean.Create(Self, doAND, FCaseInsensitive);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time11);
{$ENDIF}
      for i:=0 to FieldNamesList.Count-1 do
        begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaIncCounter(counter12);
aaStartTime(time12);
{$ENDIF}
          // Field
          fieldName := FieldNamesList.FItems[i];
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time12);
aaStartTime(time13);
{$ENDIF}
          LeftNField := TSQLMemExprNodeField.Create(Self, LCursor, fieldName);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time13);
aaStartTime(time14);
{$ENDIF}
          RightNode := TSQLMemExprNodeVariable.Create(Self,'',nil,i);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time14);
aaStartTime(time15);
{$ENDIF}
          // EqNode
          EqNode := TSQLMemExprNodeComparison.Create(Self, doEQ, LeftNField, RightNode,
                                     F3ValueLogic, FCaseInsensitive, FPartialKey);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time15);
aaStartTime(time16);
{$ENDIF}
          // Add to RootNode
          FRootExprNode.Children.Add(EqNode);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time16);
{$ENDIF}
        end;
    end;
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
finally
aaStopTime(time1);
end;
{$ENDIF}
end; // ParseForLocate


//------------------------------------------------------------------------------
// set locate params
//------------------------------------------------------------------------------
procedure TSQLMemExpression.SetLocateParams(KeyValues: Variant);
var i,ArrLen:  Integer;
    bUnicode:  Boolean;
begin
  // Determinate KeyValues count (can be array)
  if  (VarType(KeyValues) and varArray ) <> 0 then
    ArrLen := VarArrayHighBound(KeyValues,1) - VarArrayLowBound(KeyValues,1) + 1
  else
    ArrLen := 1;
  if (LParams = nil) then
    raise ESQLMemException.Create(12391,ErrorLNilPointer);
  if (ArrLen <> LParams.Count) then
    raise ESQLMemException.Create(12392, ErrorGNotEqualCountsOfFieldNamesAndKeyValues,
                                      [LParams.Count, ArrLen]);
  if (ArrLen = 1) then
  begin
   bUnicode := LParams.Items[0].IsWideStringDataType;
   LParams.Items[0].AsVariant := KeyValues;
   if ((not bUnicode) and (LParams.Items[0].IsWideStringDataType)) then
     LParams.Items[0].Cast(bftChar);
  end
  else
  for i := 0 to ArrLen-1 do
  begin
    bUnicode := LParams.Items[i].IsWideStringDataType;
    LParams.Items[i].AsVariant := VarArrayGet(KeyValues, i);
    if ((not bUnicode) and (LParams.Items[i].IsWideStringDataType)) then
      LParams.Items[i].Cast(bftChar);
  end;
end; // SetLocateParams


//------------------------------------------------------------------------------
// Parsing for Filter
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ParseForFilter(Cursor: TSQLMemCursor; Filter: WideString;
  CaseInsensitive, PartialKey: boolean);
var
  Lexer: TSQLMemLexer;
begin
  LCursor := Cursor;
  FCaseInsensitive := Cursor.CaseInsensitive or CaseInsensitive;
  FPartialKey := PartialKey;

  Lexer := TSQLMemLexer.Create(Filter);
  try
    if (not Lexer.GetNextCommand) then
       raise ESQLMemException.Create(30119, ErrorGBlankSqlCommand);

    ParseForBooleanExpression(Lexer);
  finally
    Lexer.Free;
  end;
end;//ParseForFilter


//------------------------------------------------------------------------------
// Parse For Boolean Expression (Filter, Where-Clause)
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ParseForBooleanExpression(
                                        //Cursor: TSQLMemCursor;
                                        Lexer: TSQLMemLexer
                                        //CaseInsensitive: boolean = true;
                                        //PartialKey: boolean = false
                                                   );
var SavedTokenNo: Integer;
begin
  Clear;
  LLex := Lexer;

  if (not LLex.GetCurrentToken(Token)) then
    raise ESQLMemException.Create(30118, ErrorGUnexpectedEndOfCommand,
                                              [Token.LineNum, Token.ColumnNum]);
  SaveState(SavedTokenNo);

{$IFDEF EXPR_PARSING_1}
  FRootExprNode := ParseValueExpression;
{$ELSE}
  // Parse...
  FRootExprNode := ParseSearchCondition;

  if (FRootExprNode = nil) then
  begin
   RestoreState(SavedTokenNo);
   FRootExprNode := ParseValueExpression;
  end;
{$ENDIF}
  MoveAndNodesToRoot;

  if LCursor <> nil then
    FRootExprNode.PatchWideStrings;
end;//ParseForBooleanExpression


//------------------------------------------------------------------------------
// Parse ValueExpression
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ParseForValueExpression(
                                        Lexer: TSQLMemLexer
                                                 );
var SavedTokenNo: Integer;
begin
 LLex := Lexer;
 //LCursor := Cursor;
 //FCaseInsensitive := CaseInsensitive;
 //FPartialKey := PartialKey;

 // get first token (for very beginning of the query) or current token
 if (not LLex.GetCurrentToken(Token)) then
  raise ESQLMemException.Create(30136, ErrorGUnexpectedEndOfCommand, [Token.LineNum, Token.ColumnNum]);

 SaveState(SavedTokenNo);
 // parse
 FRootExprNode := ParseValueExpression;
 {$IFDEF EXPR_PARSING_1}
 if (FRootExprNode <> nil) then
 begin
   MoveAndNodesToRoot;
   if LCursor <> nil then
      FRootExprNode.PatchWideStrings;
 end;
 {$ELSE}
 // added in v.5.90 to be able to evaluate boolean expressions like:
 // Field IS NULL
 // Field > 5
 // ... etc
 if (FRootExprNode <> nil) then
  if (LLex.SQLMemIsBoooleanOperator) then
  begin
   FRootExprNode.Free;
   RestoreState(SavedTokenNo);
   FRootExprNode := ParseSearchCondition;
   MoveAndNodesToRoot;
   if LCursor <> nil then
      FRootExprNode.PatchWideStrings;
  end;
 {$ENDIF}
end;//ParseForValueExpression


//------------------------------------------------------------------------------
// Return Variant
//------------------------------------------------------------------------------
function TSQLMemExpression.GetValue(TrueFalseNullLogic: boolean): TSQLMemVariant;
begin
  if FRootExprNode <> nil then
    begin
{$IFDEF DEBUG_EXPR_Value}
aaWriteToLog('TSQLMemExpression.GetValue - '+IntToHex(Integer(Self),8)+#13#10+FRootExprNode.GetValue(False));
{$ENDIF}
      Result := FRootExprNode.GetDataValue;
      if (Result.IsNull and (not TrueFalseNullLogic) ) then
        Result.AsBoolean := False;
    end
  else
  begin
{$IFDEF DEBUG_EXPR_Value}
aaWriteToLog('TSQLMemExpression.GetValue - '+IntToHex(Integer(Self),8)+#9+'FRootExprNode = nil');
{$ENDIF}
    Result := nil;
  end;
end;//GetValue


//------------------------------------------------------------------------------
// Get Boolean result
//------------------------------------------------------------------------------
function TSQLMemExpression.GetResult: Boolean;
//var  Value: TSQLMemVariant;
begin
{
  Value := GetValue(false);
  if Value = nil then
    raise ESQLMemException.Create(30110, ErrorGValueIsNull);
  Result := Value.AsBoolean;
}
  if FRootExprNode <> nil then
  begin
{$IFDEF DEBUG_EXPR_Result}
aaWriteToLog('TSQLMemExpression.GetResult - '+IntToHex(Integer(Self),8)+#13#10+FRootExprNode.GetValue(True));
{$ENDIF}
    Result := FRootExprNode.GetBooleanValue;
  end
  else
  begin
{$IFDEF DEBUG_EXPR_Result}
aaWriteToLog('TSQLMemExpression.GetResult - '+IntToHex(Integer(Self),8)+#9+'FRootExprNode = nil');
{$ENDIF}
    raise ESQLMemException.Create(30110, ErrorGValueIsNull);
  end;
end; // GetResult


//------------------------------------------------------------------------------
// is expression contains aggregated function
//------------------------------------------------------------------------------
function TSQLMemExpression.IsAggregated: Boolean;
begin
 if FRootExprNode <> nil then
   Result := FRootExprNode.IsAggregated
 else
   Result := False;
end;//IsAggregated


//------------------------------------------------------------------------------
// is expression contains function COUNT(*)
//------------------------------------------------------------------------------
function TSQLMemExpression.IsCountAll: Boolean;
begin
 if FRootExprNode <> nil then
   Result := FRootExprNode.IsCountAll
 else
   Result := False;
end;//IsCountAll


//------------------------------------------------------------------------------
// is expression contains function COUNT(*) and has no other nodes
//------------------------------------------------------------------------------
function TSQLMemExpression.IsCountAllOnly: Boolean;
begin
 Result := False;
 if FRootExprNode <> nil then
  if FRootExprNode.Operator = doCOUNTALL then
    Result := True;
end;//IsCountAllOnly



//------------------------------------------------------------------------------
// Init for aggregated functions
//------------------------------------------------------------------------------
procedure TSQLMemExpression.Init;
begin
  if FRootExprNode <> nil then
    FRootExprNode.Init;
end;//Init


//------------------------------------------------------------------------------
// Accumulate for group functions
//------------------------------------------------------------------------------
procedure TSQLMemExpression.Accumulate(Increment: Integer);
begin
  if FRootExprNode <> nil then
    FRootExprNode.Accumulate(Increment);
end;//Accumulate



//------------------------------------------------------------------------------
// process assign AO
//------------------------------------------------------------------------------
procedure TSQLMemExpression.AssignAO(AO: TSQLMemAO);
begin
  FCaseInsensitive := AO.CaseInsensitive;
  LSession := AO.Session;
  LParams := AO.Params;
  if (FRootExprNode <> nil) then
    begin
      FRootExprNode.AssignAO(AO);
      FRootExprNode.PatchWideStrings;
    end;
end;//AssignAO


//------------------------------------------------------------------------------
// process assign Cursor and its RecordBuffer
//------------------------------------------------------------------------------
procedure TSQLMemExpression.AssignCursor(Cursor: TSQLMemCursor);
begin
  FCaseInsensitive := Cursor.CaseInsensitive;
  LSession := Cursor.Session;
  if (FRootExprNode <> nil) then
    begin
      FRootExprNode.AssignCursor(Cursor);
      FRootExprNode.PatchWideStrings;
    end;
end;//AssignCursor


//------------------------------------------------------------------------------
// process assign New Cursor Buffer
//------------------------------------------------------------------------------
procedure TSQLMemExpression.AssignCursorBuffer(Buffer: TSQLMemRecordBuffer);
begin
  if (FRootExprNode <> nil) then
    begin
      FRootExprNode.AssignCursorBuffer(Buffer);
      FRootExprNode.PatchWideStrings;
    end;
end;//AssignCursorBuffer


//------------------------------------------------------------------------------
// return Expression DataSize
//------------------------------------------------------------------------------
function TSQLMemExpression.GetDataSize: Integer;
begin
 if FRootExprNode <> nil then
   Result := FRootExprNode.getDataSize
 else
   Result := 0;
end;//getDataSize


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExpression.GetPrecision: Integer;
begin
 if FRootExprNode <> nil then
   Result := FRootExprNode.GetPrecision
 else
   Result := 0;
end;//GetPrecision


//------------------------------------------------------------------------------
// return Expression DataType
//------------------------------------------------------------------------------
function TSQLMemExpression.GetDataType: TSQLMemAdvancedFieldType;
begin
 if FRootExprNode <> nil then
   Result := FRootExprNode.getDataType
 else
   Result := aftUnknown;
end;//GetDataType


//------------------------------------------------------------------------------
// is expression contains no nodes
//------------------------------------------------------------------------------
function TSQLMemExpression.IsEmpty: Boolean;
begin
  Result := (FRootExprNode = nil);
end;//IsEmpty


//------------------------------------------------------------------------------
// return true if (FRootExprNode is TSQLMemExprNodeConst) and (FRootExprNode.Value.IsNull)
//------------------------------------------------------------------------------
function TSQLMemExpression.IsNullConst: Boolean;
begin
  if (FRootExprNode = nil) then
   Result := False
  else
   Result := (FRootExprNode is TSQLMemExprNodeConst) and (FRootExprNode.Value.IsNull);
end; // IsNullConst


//------------------------------------------------------------------------------
// is expression a Field (for join)
//------------------------------------------------------------------------------
function TSQLMemExpression.IsField: Boolean;
begin
  Result := False;
  if FRootExprNode <> nil then
    Result := FRootExprNode is TSQLMemExprNodeField;
end;//IsField


//------------------------------------------------------------------------------
// is expression a constant
//------------------------------------------------------------------------------
function TSQLMemExpression.IsConst: Boolean;
begin
  Result := False;
  if FRootExprNode <> nil then
    Result := FRootExprNode is TSQLMemExprNodeConst;
end; // IsConst


//------------------------------------------------------------------------------
// MoveAndNodesToRoot
//------------------------------------------------------------------------------
procedure TSQLMemExpression.MoveAndNodesToRoot;
var
  i: Integer;
begin
 if (FRootExprNode <> nil) then 
  if (FRootExprNode.Operator = doAND) then
   begin
    i := 0;
    while i < FRootExprNode.Children.Count-1 do
     begin
      if (TSQLMemExprNode(FRootExprNode.Children[i]).Operator = doAND) then
       begin
        while TSQLMemExprNode(FRootExprNode.Children[i]).Children.Count > 0 do
         begin
          FRootExprNode.Children.Add(TSQLMemExprNode(FRootExprNode.Children[i]).Children[0]);
          TSQLMemExprNode(FRootExprNode.Children[i]).Children.Delete(0);
         end;
        TSQLMemExprNode(FRootExprNode.Children[i]).Free;
        FRootExprNode.Children.Delete(i);
        continue;
       end;
      Inc(i);
     end;
   end;
end; // MoveAndNodesToRoot


//------------------------------------------------------------------------------
// Field Name, Table Name
//------------------------------------------------------------------------------
procedure TSQLMemExpression.GetFieldInfo(var TableName, FieldName: WideString);
begin
  if (IsField) then
   begin
    TableName := TSQLMemExprNodeField(FRootExprNode).FTableName;
    FieldName := TSQLMemExprNodeField(FRootExprNode).FFieldName;
   end
  else
   raise ESQLMemException.Create(30198, ErrorGNodeIsNotField);
end;// GetFieldInfo


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// makes filter AnsiString from related parts and sets it to AO
// return ture if correlated field nodes were found
// changed in v.5.60
//------------------------------------------------------------------------------
function TSQLMemExpression.ApplyFilterParts(AO: TSQLMemAO; bHaving, bJoinOn, bSubQuery, bRootAO: Boolean): Boolean;
var
  NodesToDelete:    TSQLMemList;
  Node:             TSQLMemExprNode;
  bRecurseLeft:     Boolean;
  bRecurseRight:    Boolean;
  i:                Integer;
  FilterRootNode:   TSQLMemExprNode;
  bOK:              Boolean;
begin
  Result := False;
  FilterRootNode := nil;
  bRecurseLeft := True;
  bRecurseRight := True;
  // don't set filter to outer join childs
  if (AO is TSQLMemAOJoin) then
   begin
    if (TSQLMemAOJoin(AO).JoinType = ajtFullOuter) then
     begin
      bRecurseLeft := False;
      bRecurseRight := False;
     end
    else
    if (TSQLMemAOJoin(AO).JoinType = ajtLeftOuter) then
     begin
      bRecurseLeft := True;
      bRecurseRight := False;
     end
    else
    if (TSQLMemAOJoin(AO).JoinType = ajtRightOuter) then
     begin
      bRecurseLeft := False;
      bRecurseRight := True;
     end
   end;

  if (bJoinOn) then
   begin
    bRecurseLeft := True;
    bRecurseRight := True;
   end;

  if (bHaving) then
   begin
    bRecurseLeft := False;
    bRecurseRight := False;
   end;


  // try to apply to AO children
  if (bRecurseLeft or bRecurseRight) then
   begin
    if (bRecurseLeft) then
     if (AO.FLeftAO <> nil) then
      ApplyFilterParts(AO.FLeftAO,bHaving,False,bSubQuery,False);
    if (bRecurseRight) then
     if (AO.FRightAO <> nil) then
      ApplyFilterParts(AO.FRightAO,bHaving,False,bSubQuery,False);
   end;

  // traverse tree by factors: (...) AND (...) AND (...)
  if (FRootExprNode <> nil) then
   begin
     // added in v.4.60 - expression must be recreated to add new nodes
     // otherwise old nodes will be incorrectly removed
     if (AO.FilterExpr <> nil) then
      FilterRootNode := TSQLMemExpression(AO.FilterExpr).FRootExprNode;
     NodesToDelete := TSQLMemList.Create;
     try
      // -> (...) AND (...) AND (...) ?
      if (FRootExprNode is TSQLMemExprNodeBoolean) and
         (FRootExprNode.Operator = doAND) then
        for i := 0 to FRootExprNode.Children.Count-1 do
         begin
          Node := FRootExprNode.Children[i];
          bOK := Node.CanBeAssigned(AO);
          // fixed in 5.85
//          if ((not bOK) and (bSubQuery)) then
          if ((not bOK) and bSubQuery and bRootAO) then
          begin
            // correlated field node found
            // changed in v.5.70 pr#3
//            bOK := bRootAO;
            bOK := True;
            Result := True;
          end;
          // (...) can be used by the AO?
          if (bOK) then
           begin
            // no FilterRootNode
            if FilterRootNode = nil then
              FilterRootNode := Node
            else
            // FilterRootNode=AND ( ex: a=b AND c=d )
            if (FilterRootNode is TSQLMemExprNodeBoolean) and
               (FilterRootNode.Operator = doAND) then
               FilterRootNode.Children.Add(Node)
            else
              // single FilterRootNode ( ex: a=b ) - converting to AND
              FilterRootNode := TSQLMemExprNodeBoolean.Create(Self, doAND,
                                                FilterRootNode, Node);
            NodesToDelete.Add(Node);
           end;
          // -> AND (...)
         end
      else
        // (...)
        begin
          bOk := FRootExprNode.CanBeAssigned(AO);
          // fixed in 5.90
//          if ((not bOK) and (bSubQuery)) then
          if ((not bOK) and bSubQuery and bRootAO) then
          begin
            // correlated field node found
            bOK := bRootAO;
            Result := True;
          end;
          if (bOK) then
            begin
              FilterRootNode := FRootExprNode;
              FRootExprNode := nil;
            end;
        end;
      // delete used nodes
      for i:=0 to NodesToDelete.Count-1 do
       begin
        FRootExprNode.Children.Delete(
          FRootExprNode.Children.IndexOf(NodesToDelete[i]));
       end;
      // added in v.4.60 - expression must be recreated to add new nodes
      if (AO.FilterExpr <> nil) then
       begin
        TSQLMemExpression(AO.FilterExpr).FRootExprNode := nil;
        TSQLMemExpression(AO.FilterExpr).Free;
       end;
      // set extracted filter
      if FilterRootNode <> nil then
       AO.SetFilter(TSQLMemExpression.Create(LSession,LParams,FilterRootNode,LSQLCommand));

      // no children?
      if (FRootExprNode <> nil) then
       if (FRootExprNode.Children.Count = 0) then
        begin
         FRootExprNode.Free;
         FRootExprNode := nil;
        end;
//      if (FilterString <> '') then
//       AO.SetFilter(FilterString, []);
     finally
      NodesToDelete.Free;
     end;
   end;
end;// ApplyFilterParts
{$ELSE}
//------------------------------------------------------------------------------
// makes filter AnsiString from related parts and sets it to AO
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ApplyFilterParts(AO: TSQLMemAO; bHaving, bJoinOn: Boolean);
var
  NodesToDelete:    TList;
  Node:             TSQLMemExprNode;
  bRecurseLeft:     Boolean;
  bRecurseRight:    Boolean;
  i:                Integer;
  FilterRootNode:   TSQLMemExprNode;
begin
  FilterRootNode := nil;
  bRecurseLeft := True;
  bRecurseRight := True;
  // don't set filter to outer join childs
  if (AO is TSQLMemAOJoin) then
   begin
    if (TSQLMemAOJoin(AO).JoinType = ajtFullOuter) then
     begin
      bRecurseLeft := False;
      bRecurseRight := False;
     end
    else
    if (TSQLMemAOJoin(AO).JoinType = ajtLeftOuter) then
     begin
      bRecurseLeft := True;
      bRecurseRight := False;
     end
    else
    if (TSQLMemAOJoin(AO).JoinType = ajtRightOuter) then
     begin
      bRecurseLeft := False;
      bRecurseRight := True;
     end
   end;

  if (bJoinOn) then
   begin
    bRecurseLeft := True;
    bRecurseRight := True;
   end;
   
  if (bHaving) then
   begin
    bRecurseLeft := False;
    bRecurseRight := False;
   end;


  // try to apply to AO children
  if (bRecurseLeft or bRecurseRight) then
   begin
    if (bRecurseLeft) then
     if (AO.FLeftAO <> nil) then
      ApplyFilterParts(AO.FLeftAO,bHaving,False);
    if (bRecurseRight) then
     if (AO.FRightAO <> nil) then
      ApplyFilterParts(AO.FRightAO,bHaving,False);
   end;

  // traverse tree by factors: (...) AND (...) AND (...)
  if (FRootExprNode <> nil) then
   begin
     // added in v.4.60 - expression must be recreated to add new nodes
     // otherwise old nodes will be incorrectly removed
     if (AO.FilterExpr <> nil) then
      FilterRootNode := TSQLMemExpression(AO.FilterExpr).FRootExprNode;
     NodesToDelete := TList.Create;
     try
      // -> (...) AND (...) AND (...) ?
      if (FRootExprNode is TSQLMemExprNodeBoolean) and
         (FRootExprNode.Operator = doAND) then
        for i := 0 to FRootExprNode.Children.Count-1 do
         begin
          Node := FRootExprNode.Children[i];
          // (...) can be used by the AO?
          if (Node.CanBeAssigned(AO)) then
           begin
            // no FilterRootNode
            if FilterRootNode = nil then
              FilterRootNode := Node
            else
            // FilterRootNode=AND ( ex: a=b AND c=d )
            if (FilterRootNode is TSQLMemExprNodeBoolean) and
               (FilterRootNode.Operator = doAND) then
               FilterRootNode.Children.Add(Node)
            else
              // single FilterRootNode ( ex: a=b ) - converting to AND
              FilterRootNode := TSQLMemExprNodeBoolean.Create(Self, doAND,
                                                FilterRootNode, Node);
            NodesToDelete.Add(Node);
           end;
          // -> AND (...)
         end
      else
        // (...)
        begin
          if (FRootExprNode.CanBeAssigned(AO)) then
            begin
              FilterRootNode := FRootExprNode;
              FRootExprNode := nil;
            end;
        end;
      // delete used nodes
      for i:=0 to NodesToDelete.Count-1 do
       begin
        FRootExprNode.Children.Delete(
          FRootExprNode.Children.IndexOf(NodesToDelete[i]));
       end;
      // added in v.4.60 - expression must be recreated to add new nodes
      if (AO.FilterExpr <> nil) then
       begin
        TSQLMemExpression(AO.FilterExpr).FRootExprNode := nil;
        TSQLMemExpression(AO.FilterExpr).Free;
       end;
      // set extracted filter
      if FilterRootNode <> nil then
       AO.SetFilter(TSQLMemExpression.Create(LSession,LParams,FilterRootNode,LSQLCommand));

      // no children?
      if (FRootExprNode <> nil) then
       if (FRootExprNode.Children.Count = 0) then
        begin
         FRootExprNode.Free;
         FRootExprNode := nil;
        end;
//      if (FilterString <> '') then
//       AO.SetFilter(FilterString, []);
     finally
      NodesToDelete.Free;
     end;
   end;
end;// ApplyFilterParts
{$ENDIF}


//------------------------------------------------------------------------------
// gets current token
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ReplacePseudonyms(SelectList: array of TSQLMemSelectListItem);
begin
 if (FRootExprNode <> nil) then
    FRootExprNode.ReplacePseudonyms(SelectList);
end;//ReplacePseudonyms


//------------------------------------------------------------------------------
// makes join field lists
//------------------------------------------------------------------------------
function TSQLMemExpression.ExtractJoinConditions(
                                    AO1, AO2: TSQLMemAO;
                                    FieldList1, FieldList2: TSQLMemFields
                                             ): Integer;
var
  NodesToDelete: TList;
  Node: TSQLMemExprNode;
  Item1,Item2: TSQLMemSelectListItem;
  i: Integer;
begin
  Result := 0;
  if FRootExprNode = nil then Exit;
  // If 'AND'
  if ((FRootExprNode is TSQLMemExprNodeBoolean) and
      (FRootExprNode.Operator = doAND)) then
   begin
     NodesToDelete := TList.Create;
     try
      for i:=0 to FRootExprNode.Children.Count-1 do
       begin
        Node := FRootExprNode.Children[i];
        // (...) can be used by the AO?
        if (Node.IsJoinCondition(AO1,AO2)) then
         begin
          // store extracted filter
          TSQLMemExprNodeField(Node.Children[0]).FillItem(Item1);
          TSQLMemExprNodeField(Node.Children[1]).FillItem(Item2);
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
        FRootExprNode.Children.Delete(FRootExprNode.Children.IndexOf(NodesToDelete[i]));
        TSQLMemExprNode(NodesToDelete[i]).Free;
       end;
      if (FRootExprNode.Children.Count = 0) then
       begin
         FRootExprNode.Free;
         FRootExprNode := nil;
       end;
     finally
      NodesToDelete.Free;
     end;
   end
 else
 // IF '='
 if ((FRootExprNode is TSQLMemExprNodeComparison) and
    (FRootExprNode.Operator = doEQ)) then
  begin
    if (FRootExprNode.IsJoinCondition(AO1,AO2)) then
     begin
      // store extracted filter
      TSQLMemExprNodeField(FRootExprNode.Children[0]).FillItem(Item1);
      TSQLMemExprNodeField(FRootExprNode.Children[1]).FillItem(Item2);
      FieldList1.Append(Item1);
      FieldList2.Append(Item2);
      Inc(Result);
      // will delete this node
      FRootExprNode.Free;
      FRootExprNode := nil;
     end;
  end;
end; // ExtractJoinConditions


{$IFNDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// extract conditions for index scan
//------------------------------------------------------------------------------
procedure TSQLMemExpression.TryExtractIndexScanConditionsFromNode(
                         Node:           TSQLMemExprNodeComparison;
                         IndexDefs:      TSQLMemIndexDefs;
                         ScanConditions: TSQLMemScanSearchConditionArray;
                         ExtractedConditionsInfo: TList
                                    );
var
  j:  Integer;
begin
  for j := 0 to IndexDefs.Count-1 do
  if (Node.CanUseIndex(IndexDefs[j])) then
    begin
      Node.AddAsIndexScanCondition(
                                  ScanConditions,
                                  IndexDefs[j],
                                  ExtractedConditionsInfo,
                                  Self
                                  );
      break;
    end;
end;// TryExtractIndexScanConditionsFromNode


//------------------------------------------------------------------------------
// remove extracted nodes (they included in list, but list contains more)
//------------------------------------------------------------------------------
procedure TSQLMemExpression.RemoveExtractedNodes(ExtractedConditionsInfo: TList);
var
  Node: TSQLMemExprNode;
  i, k: Integer;
begin
  for i := 0 to ExtractedConditionsInfo.Count-1 do
   if (PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.Expression = Self) then
    begin
      Node := TSQLMemExprNode(PSQLMemExtractedConditionInfo(ExtractedConditionsInfo[i])^.
                           ExtractedExpressionNode);
      if (Node <> FRootExprNode) then
       begin
         k := FRootExprNode.Children.IndexOf(Node);
         if (k < 0) then
           raise ESQLMemException.Create(20059, ErrorAInvalidIndexOfNo)
         else
          FRootExprNode.Children.Delete(k);
         if (FRootExprNode.Children.Count <= 0) then
          FreeAndNil(FRootExprNode);
       end
      else
       FRootExprNode := nil;
    end;
end;// RemoveExtractedNodes


//------------------------------------------------------------------------------
// extract conditions for index scan
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ExtractIndexScanConditions(
                             IndexDefs:               TObject;
                             ScanConditions:          TSQLMemScanSearchConditionArray;
                             ExtractedConditionsInfo: TList
                                        );
var
  Node: TSQLMemExprNode;
  i:    Integer;
begin
  if ((FRootExprNode is TSQLMemExprNodeBoolean) and
      (FRootExprNode.Operator = doAND)) then
    for i := 0 to FRootExprNode.Children.Count-1 do
     begin
      Node := FRootExprNode.Children[i];
      if (Node is TSQLMemExprNodeComparison) then
        TryExtractIndexScanConditionsFromNode(
                                           TSQLMemExprNodeComparison(Node),
                                           TSQLMemIndexDefs(IndexDefs),
                                           ScanConditions,
                                           ExtractedConditionsInfo
                                             );
     end
  else
   if (FRootExprNode is TSQLMemExprNodeComparison) then
        TryExtractIndexScanConditionsFromNode(
                                 TSQLMemExprNodeComparison(FRootExprNode),
                                 TSQLMemIndexDefs(IndexDefs),
                                 ScanConditions,
                                 ExtractedConditionsInfo
                                             );

  RemoveExtractedNodes(ExtractedConditionsInfo);
end;// ExtractIndexScanConditions
{$ENDIF}


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// extract conditions for index scan - skip their evaluation in root node
// return true if all nodex were extracted
//------------------------------------------------------------------------------
function TSQLMemExpression.ExtractIndexScanConditions(
                         ScanConditions:          TSQLMemList;
                         aIndexDefs:              TObject
                                                   ): Boolean;
var
  Node:               TSQLMemExprNodeComparison;
  NodeC:              TSQLMemExprNode;
  Node1:              TSQLMemExprNode;
  Node2:              TSQLMemExprNode;
  crc:                Cardinal;
  i,j,n,k:            Integer;
  sc:                 TSQLMemScanSearchCondition;
  v:                  TSQLMemVariant;
  IndexDefs:          TSQLMemIndexDefs;
  ExtractedNodes:     TSQLMemList;
begin
  Result := True;
  if (FRootExprNode = nil) then
   Exit;
  IndexDefs := TSQLMemIndexDefs(aIndexDefs);

  if ((FRootExprNode is TSQLMemExprNodeBoolean) and
      (FRootExprNode.Operator = doAND)) then
  begin
    i := 0;
    if (TSQLMemExprNodeBoolean(FRootExprNode).FIgnoreNodes = nil) then
      TSQLMemExprNodeBoolean(FRootExprNode).FIgnoreNodes := TSQLMemList.Create;
    ExtractedNodes := TSQLMemExprNodeBoolean(FRootExprNode).FIgnoreNodes;
    while (i < FRootExprNode.Children.Count) do
    begin
      if (TObject(FRootExprNode.Children[i]) is TSQLMemExprNodeComparison) then
      begin
        Node := FRootExprNode.Children[i];
        for j := 0 to IndexDefs.Count-1 do
          if (Node.CanUseIndex(IndexDefs[j])) then
          begin
            Node.AddAsIndexScanCondition(ScanConditions,IndexDefs[j]);
            ExtractedNodes.Add(Node);
            n := 1;
            sc := TSQLMemScanSearchCondition(ScanConditions[ScanConditions.Count-1]);
            // try to add other conditions
            while (IndexDefs[j].ColumnCount > n) do
            begin
             crc := GetTableNameCRC(IndexDefs[j].Columns[n].FieldName,True);
             NodeC := FRootExprNode.FindComaprisonEQWithField(crc,Node1,Node2);
             if (NodeC = nil) then
              break
             else
             begin
              if (Node2 is TSQLMemExprNodeVariable) then
              begin
                k := TSQLMemExprNodeVariable(Node2).ParamIndex;
                sc.ParamIndexes.Append(k);
              end
              else
              if (LCursor = nil) then
              begin
               break;
              end
              else
              begin
               LCursor.SetFieldValue(Node2.Value,TSQLMemExprNodeField(Node1).FFieldNo,True,sc.KeyRecordBuffer);
              end;
              // extract NodeC
              ExtractedNodes.Add(NodeC);
              Inc(sc.KeyFieldCount);
             end;
             Inc(n);
            end;
            break;
          end;
      end;
      Inc(i);
    end; // scan all child nodes
    // true if all nodes extracted
    Result := (FRootExprNode.Children.Count <= ExtractedNodes.Count);
  end // TSQLMemExprENodeBoolean with do AND operator
  else
  begin
   if (FRootExprNode is TSQLMemExprNodeComparison) then
   begin
    Node := TSQLMemExprNodeComparison(FRootExprNode);
    for j := 0 to IndexDefs.Count-1 do
    begin
      if (Node.CanUseIndex(IndexDefs[j])) then
        begin
          Node.AddAsIndexScanCondition(
                                      ScanConditions,
                                      IndexDefs[j]
                                      );
          Exit;
        end;
    end;
   end;
  end;
end; // ExtractIndexScanConditions
{$ENDIF}


//------------------------------------------------------------------------------
// return true if expression have incompatible conditions (like compare = for AnsiString fields with constant longer then field size)
//------------------------------------------------------------------------------
function TSQLMemExpression.IsIncompatible: Boolean;
var
  Node: TSQLMemExprNode;
  i:    Integer;
begin
  Result := False;
  if ((FRootExprNode is TSQLMemExprNodeBoolean) and
      (FRootExprNode.Operator = doAND)) then
    for i := 0 to FRootExprNode.Children.Count-1 do
     begin
      Node := FRootExprNode.Children[i];
      if (Node is TSQLMemExprNodeComparison) then
       begin
        Result := TSQLMemExprNodeComparison(Node).IsIncompatible;
        if (Result) then break;
       end;
     end
  else
   if (FRootExprNode is TSQLMemExprNodeComparison) then
    begin
      Result := TSQLMemExprNodeComparison(FRootExprNode).IsIncompatible;
    end;
end; // IsExpressionHaveIncompatibleConditions


//------------------------------------------------------------------------------
// add extracted node
//------------------------------------------------------------------------------
procedure TSQLMemExpression.AddNode(Node: TSQLMemExprNode);
begin
   // fixed in v.5.90
   if (FRootExprNode <> nil) then
   begin
     if (FRootExprNode is TSQLMemExprNodeBoolean) and (FRootExprNode.Operator = doAND) then
      FRootExprNode.Children.Add(Node)
     else
     begin
      FRootExprNode := TSQLMemExprNodeBoolean.Create(Self,doAND,FRootExprNode,Node,FCaseInsensitive,FPartialKey);
     end;
   end
   else
     FRootExprNode := Node;
end;// AddNode


//------------------------------------------------------------------------------
// return new TSQLMemExpression object with all filter conditions assigned to SourceDataset
// return nil if there are no way to extract such conditions
//------------------------------------------------------------------------------
function TSQLMemExpression.ExtractFilterConditionsAssignedToSourceDataset(AO: TSQLMemAOTable): TSQLMemExpression;
var
     i:        Integer;
     NodeList: TList;
begin
   Result := nil;
   if ((FRootExprNode is TSQLMemExprNodeBoolean) and
       (FRootExprNode.Operator = doAND)) then
    begin
     NodeList := TList.Create;
     try
       // search for all children that can be moved to Result expression
       for i := 0 to FRootExprNode.Children.Count-1 do
        if (FRootExprNode.Children.Items[i] = nil) then continue
        else
         if (TSQLMemExprNode(FRootExprNode.Children.Items[i]).IsExprNodeCanBeLinkedToSourceTable(AO)) then
          NodeList.Add(FRootExprNode.Children.Items[i]);
       // children found
       if (NodeList.Count > 0) then
        begin
         // session will be set by AssignCursor
         Result := TSQLMemExpression.Create(nil,nil);
         // do not copy entire RootExprNode
         Result.Assign(Self,False);
         Result.AssignCursor(TSQLMemCursor(TSQLMemDataSet(AO.SourceDataset).Handle));
         if (NodeList.Count > 1) then
          begin
           // multiple children found
           Result.FRootExprNode := TSQLMemExprNodeBoolean.Create(Self, doAND);
           for i := 0 to NodeList.Count-1 do
            begin
             Result.FRootExprNode.Children.Add(NodeList.Items[i]);
             if (NodeList.Count < FRootExprNode.Children.Count) then
              FRootExprNode.Children.Remove(NodeList.Items[i]);
            end;
           // all nodes moved to Result expression
           if (NodeList.Count = FRootExprNode.Children.Count) then
             FRootExprNode.Children.Clear;
          end
         else
          begin
           // single child found
           Result.FRootExprNode := TSQLMemExprNode(NodeList.Items[0]);
           FRootExprNode.Children.Remove(NodeList.Items[0]);
          end;
         // empty root node if there are no children
         if (FRootExprNode.Children.Count = 0) then
          begin
           FRootExprNode.Free;
           FRootExprNode := nil;
          end;
        end; // children found
     finally
       NodeList.Free;
     end;
    end // Root node is node boolean with doAND operator
   else
    if (FRootExprNode.IsExprNodeCanBeLinkedToSourceTable(AO)) then
     begin
      // root node moved to result expression
      // session will be set by AssignCursor
      Result := TSQLMemExpression.Create(nil,nil);
      // do not copy entire RootExprNode
      Result.Assign(Self,False);
      Result.RootExprNode := FRootExprNode;
      Result.AssignCursor(TSQLMemCursor(TSQLMemDataSet(AO.SourceDataset).Handle));
      FRootExprNode := nil;
     end;
end; // ExtractFilterConditionsAssignedToCursor


//------------------------------------------------------------------------------
// fills ExtractedConditions list with all conditions from root expression node or children
// of root expression node if it is TSQLMemExprNodeBoolean with doAND operator
// containing TSQLMemExprNodeField that belongs to AO or its children
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ExtractFilterConditionsAssignedToAO(AO: TSQLMemAO; ExtractedConditions: TList);
var i: Integer;
begin
  if (FRootExprNode <> nil) then
   if  ((FRootExprNode is TSQLMemExprNodeBoolean) and
        (FRootExprNode.Operator = doAND)) then
    begin
     for i:= 0 to FRootExprNode.Children.Count-1 do
      if (FRootExprNode.Children[i] <> nil) then
       begin
        if (TSQLMemExprNode(FRootExprNode.Children[i]).CanBeAssigned(AO)) then
         ExtractedConditions.Add(FRootExprNode.Children[i]);
       end;
    end
   else
    begin
     if (FRootExprNode.CanBeAssigned(AO)) then
      ExtractedConditions.Add(FRootExprNode);
    end;
end; // ExtractFilterConditionsAssignedToAO


//------------------------------------------------------------------------------
// return true if there is any TSQLMemNodeField child that can be linked to AO
//------------------------------------------------------------------------------
function TSQLMemExpression.IsNodeFieldChildrenLinkedToAOExists(AO: TSQLMemAO): Boolean;
begin
  Result := False;
  if (FRootExprNode <> nil) then
   Result := FRootExprNode.IsNodeFieldChildrenLinkedToAOExists(AO);
end; // IsNodeFieldChildrenLinkedToAOExists


//------------------------------------------------------------------------------
// extract all TSQLMemExprNodeConst objects from FRootExprNode and all its children
//------------------------------------------------------------------------------
procedure TSQLMemExpression.ExtractAllParameterNodes(NodeList: TSQLMemList);
begin
  if (FRootExprNode <> nil) then
   FRootExprNode.ExtractAllParameterNodes(NodeList);
end; // ExtractAllParameterNodes


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// return true if external field nodes exists (referencing main query from sub-query node)
//------------------------------------------------------------------------------
function TSQLMemExpression.ExtractAllExternalFieldNodes(var FieldNodeList: TSQLMemList; var ConstNodeList: TSQLMemList; AO: TSQLMemAO): Boolean;
begin
  if (FRootExprNode <> nil) then
   Result := FRootExprNode.ExtractAllExternalFieldNodes(FieldNodeList,ConstNodeList,AO)
  else
   Result := False;
end; // ExtractAllExternalFieldNodes


//------------------------------------------------------------------------------
// return true if expression has at least 1 correlated subquery
//------------------------------------------------------------------------------
function TSQLMemExpression.CorrelatedSubQueriesExists: Boolean;
begin
  if (FRootExprNode <> nil) then
   Result := FRootExprNode.CorrelatedSubQueriesExists
  else
   Result := False;
end;
{$ENDIF}


//------------------------------------------------------------------------------
// raises exception if FRootExprNo or its child has TSQLMemExprNodeField
// added in 4.97 for raising correct exception if search condition cannot be
// assigned fully to AO
//------------------------------------------------------------------------------
procedure TSQLMemExpression.CheckInvalidFieldNames;
begin
  if (FRootExprNode <> nil) then
    FRootExprNode.CheckInvalidFieldNames;
end; // CheckInvalidFieldNames


//------------------------------------------------------------------------------
// add join condition to search condiition
//------------------------------------------------------------------------------
procedure TSQLMemExpression.AddJoinCondition(Expression: TSQLMemExpression);
begin
  if (Expression = nil) then
   raise ESQLMemException.Create(12168,ErrorLNilPointer);
  if (Expression.RootExprNode <> nil) then
   begin
    if (FRootExprNode = nil) then
     begin
      FRootExprNode := Expression.RootExprNode;
      Expression.FRootExprNode := nil;
     end
    else
     begin
      if (FRootExprNode.Operator = doAND) then
       FRootExprNode.Children.Add(Expression.RootExprNode)
      else
       FRootExprNode := TSQLMemExprNodeBoolean.Create(Self,doAND,FRootExprNode,Expression.FRootExprNode);
     end;
    Expression.FRootExprNode := nil;
   end;
end; // AddJoinCondition


//------------------------------------------------------------------------------
// updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
//------------------------------------------------------------------------------
procedure TSQLMemExpression.UpdateExpressionParams;
begin
  if (FRootExprNode <> nil) then
   FRootExprNode.UpdateExpressionParams;
end; // UpdateExpressionParams




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExpressions
//
// list of TSQLMemExpression objects
// used in stored functions
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return number of items stored
//------------------------------------------------------------------------------
function TSQLMemExpressions.GetCount: Integer;
begin
  Result := FExprList.Count;
end; // GetCount


//------------------------------------------------------------------------------
// GetValue
//------------------------------------------------------------------------------
function TSQLMemExpressions.GetValue(Index: Integer): TSQLMemExpression;
begin
  Result := TSQLMemExpression(FExprList[Index]);
end; // GetValue


//------------------------------------------------------------------------------
// SetValue
//------------------------------------------------------------------------------
procedure TSQLMemExpressions.SetValue(Index: Integer; Value: TSQLMemExpression);
begin
  TSQLMemExpression(FExprList[Index]).Free;
  FExprList[Index] := Value;
end; // SetValue


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemExpressions.Create;
begin
  FExprList := TList.Create;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemExpressions.Destroy;
begin
  Clear;
  FExprList.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TSQLMemExpressions.Clear;
var i: Integer;
begin
  for i := 0 to Count-1 do
   try
    TSQLMemExpression(FExprList[i]).Free;
   except
   end;
  FExprList.Clear;
end; // Clear


//------------------------------------------------------------------------------
// add new TSQLMemExpression and return it
//------------------------------------------------------------------------------
function TSQLMemExpressions.AddCreated(aSession: TSQLMemBaseSession; aParams: TSQLMemSQLParams): TSQLMemExpression;
begin
  Result := TSQLMemExpression.Create(aSession,aParams);
  FExprList.Add(Result);
end; // Add Created


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemExpressions.Assign(Source: TSQLMemExpressions);
var i: Integer;
begin
  if (Source = nil) then
   raise ESQLMemException.Create(12094,ErrorLNilPointer);
  if (not (Source is TSQLMemExpressions)) then
   raise ESQLMemException.Create(12095,ErrorLInvalidSourceObject,[IntToHex(Integer(Source),8),Source.ClassName]);
  Clear;
  for i := 0 to Source.Count - 1 do
    AddCreated(Source.Items[i].LSession,Source.Items[i].LParams).Assign(Source.Items[i]);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNode
//
// base class for all expression nodes 
// fully virtual (i.e. never created)
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// converts some WideStrings to Strings
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.PatchWideStrings;
var i: Integer;
begin
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).PatchWideStrings;
end;//PatchWideStrings


//------------------------------------------------------------------------------
// return true if this node and all its children can be linked to source table filter expression
//------------------------------------------------------------------------------
function TSQLMemExprNode.IsExprNodeCanBeLinkedToSourceTable(AO: TSQLMemAOTable): Boolean;
var i: Integer;
begin
  Result := True;
  for i:=0 to Children.Count-1 do
   begin
    if (Children[i] = nil) then continue;
    Result := TSQLMemExprNode(Children[i]).IsExprNodeCanBeLinkedToSourceTable(AO);
    if (not Result) then Break;
   end;
end; // IsExprNodeCanBeLinkedToSourceTable


//------------------------------------------------------------------------------
// return true if there is any TSQLMemNodeField child that can be linked to AO
//------------------------------------------------------------------------------
function TSQLMemExprNode.IsNodeFieldChildrenLinkedToAOExists(AO: TSQLMemAO): Boolean;
var i: Integer;
begin
  Result := False;
  for i:=0 to Children.Count-1 do
   begin
    if (Children[i] = nil) then continue;
    Result := TSQLMemExprNode(Children[i]).IsNodeFieldChildrenLinkedToAOExists(AO);
    if (Result) then Break;
   end;
end; // IsNodeFieldChildrenLinkedToAOExists


//------------------------------------------------------------------------------
// return number of childrens
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetChildrenCount: Integer;
begin
  Result := Children.Count
end; // GetChildrenCount


{$IFDEF DEBUG_LOG}
//------------------------------------------------------------------------------
// get name
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetName: AnsiString;
begin
  Result := Self.ClassName+' '+GetOperatorName(Operator)+' - Children.Count = '+IntToStr(Children.Count);
end; // GetName


function TSQLMemExprNode.GetValue(bBool: Boolean = False): AnsiString;
var v: TSQLMemVariant;
begin
  try
    v := GetDataValue;
    if (v.IsNull) then
    begin
     if (bBool) then
      Result := GetName+#13#10+'Result = False (NULL)'
     else
      Result := GetName+#13#10+'Result = NULL';
    end
    else
    if (bBool) then
     Result := GetName+#13#10+'Result = '+BoolToStr(v.AsBoolean,True)
    else
     Result := GetName+#13#10+'Result = '+v.AsString;
  except
    Result := GetName+#13#10+'EXCEPTION in GetDataValue.AsString, type = '+GetFieldTypeSQLName(BaseFieldTypeToAdvancedFieldType(v.DataType));
  end;
end;
{$ENDIF}


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNode.Create(
                                 aParentExpr:     TSQLMemExpression;
                                 CaseInsensitive: Boolean;
                                 PartialKey:      Boolean
                               );
begin
  LParentExpr := aParentExpr;
  Operator := doUNDEFINED;
  Value := TSQLMemVariant.Create;
  Children := TSQLMemList.Create;
  FCaseInsensitive := CaseInsensitive;
  FPartialKey := PartialKey;
  FDoNotReassign := False;
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNode.Create(
                                 aParentExpr:     TSQLMemExpression;
                                 Op:              TSQLMemDataOperator;
                                 CaseInsensitive: Boolean;
                                 PartialKey:      Boolean
                               );
begin
  Create(aParentExpr, CaseInsensitive, PartialKey);
  Operator := Op;
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNode.Create(
                                 aParentExpr:     TSQLMemExpression;
                                 Op:              TSQLMemDataOperator;
                                 Node:            TSQLMemExprNode;
                                 CaseInsensitive: Boolean;
                                 PartialKey:      Boolean
                               );
begin
  Create(aParentExpr, Op, CaseInsensitive, PartialKey);
  if (Node <> nil) then
    Children.Add(Node);
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNode.Create(
                                 aParentExpr:     TSQLMemExpression;
                                 Op:              TSQLMemDataOperator;
                                 Node1, Node2:    TSQLMemExprNode;
                                 CaseInsensitive: Boolean;
                                 PartialKey:      Boolean
                               );
begin
  Create(aParentExpr, Op, Node1, CaseInsensitive, PartialKey);
  if (Node2 <> nil) then
    Children.Add(Node2);
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNode.Create(
                                 aParentExpr:         TSQLMemExpression;
                                 Op:                  TSQLMemDataOperator;
                                 Node1, Node2, Node3: TSQLMemExprNode;
                                 CaseInsensitive:     Boolean;
                                 PartialKey:          Boolean
                               );
begin
  Create(aParentExpr, Op, Node1, Node2, CaseInsensitive, PartialKey);
  if (Node3 <> nil) then
    Children.Add(Node3);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemExprNode.Destroy;
begin
  Clear;
  Children.Free;
  if (Value <> nil) then
    FreeAndNil(Value);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// return Value as Boolean
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetBooleanValue: Boolean;
var v: TSQLMemVariant;
begin
  v := GetDataValue;
  if (v = nil) then
   raise ESQLMemException.Create(12384,ErrorLNilPointer);
  if (v.IsNull) then
    Result := False
  else
    Result := GetDataValue.AsBoolean;
end; // GetBooleanValue


//------------------------------------------------------------------------------
// is expression contains aggregated function
//------------------------------------------------------------------------------
function TSQLMemExprNode.IsAggregated: Boolean;
var i: Integer;
begin
  Result := False;
  for i:=0 to Children.Count-1 do
   begin
    if (Children[i] = nil) then continue;
    Result := TSQLMemExprNode(Children[i]).IsAggregated;
    if Result then Break;
   end;
end;//IsAggregated


//------------------------------------------------------------------------------
// is expression contains aggregated function COUNT(*)
//------------------------------------------------------------------------------
function TSQLMemExprNode.IsCountAll: Boolean;
var i: Integer;
begin
  Result := False;
  for i:=0 to Children.Count-1 do
   begin
    if (Children[i] = nil) then continue;
    Result := TSQLMemExprNode(Children[i]).IsCountAll;
    if Result then Break;
   end;
end;//IsCountAll


//------------------------------------------------------------------------------
// Init for group function
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.Init;
var i: integer;
begin
  for i:=0 to Children.Count-1 do
   if (Children[i] = nil) then continue
   else
    TSQLMemExprNode(Children[i]).Init;
end;//Init


//------------------------------------------------------------------------------
// Accumulate for group functions
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.Accumulate(Increment: Integer);
var i: integer;
begin
  for i:=0 to Children.Count-1 do
   if (Children[i] = nil) then continue
   else
    TSQLMemExprNode(Children[i]).Accumulate(Increment);
end;//Accumulate


//------------------------------------------------------------------------------
// assign AO
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.AssignAO(AO: TSQLMemAO);
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).AssignAO(AO);
end;//AssignAO


//------------------------------------------------------------------------------
// Assign Cursor
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.AssignCursor(Cursor: TSQLMemCursor);
var
  i: integer;
begin
  FCaseInsensitive := Cursor.CaseInsensitive;
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).AssignCursor(Cursor);
end;//AssignCursor


//------------------------------------------------------------------------------
// process assign New Cursor Buffer
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.AssignCursorBuffer(Buffer: TSQLMemRecordBuffer);
var i: integer;
begin
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).AssignCursorBuffer(Buffer);
end;//AssignCursorBuffer


//------------------------------------------------------------------------------
// get Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetDataSize: Integer;
var
  i: integer;
  ftype: TSQLMemBaseFieldType;
  child: TSQLMemExprNode;
  size:  Integer;
begin
  Result := 0;
  ftype := AdvancedFieldTypeToBaseFieldType(getDataType);
  //if ftype in [ftString, ftWideString, ftBytes] then
  if IsStringFieldType(ftype) then
   begin
    // added in 4.97
    if (Operator = doGROUP_CONCAT) then
      Result := SQLMemExpressionMaxStringSize
    else
    if Operator in [doADD, doCONCAT, doCAST, doMIN, doMAX] then
     for i:=0 to Children.Count-1 do
      begin
       child := TSQLMemExprNode(Children[i]);
       size := child.getDataSize;
       // fixed in v.4.50
       if (IsVarcharFieldType(ftype)) then
        size := SQLMemExpressionMaxVarcharSize
       else
       if (size <= 0) then
        size := SQLMemExpressionMaxStringSize;
       Result := Result + size;
       {case child.getDataType of
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
       }
      end
    else
    if (Operator = doHex) then
       begin
         child := TSQLMemExprNode(Children[0]);
         case child.GetDataType of
          aftAutoInc,aftAutoIncCardinal,
          aftInteger,aftCardinal:
           Result := 9;
          aftShortint,aftWord,
          aftAutoIncShortint,aftAutoIncWord:
           Result := 3;
          aftSmallInt,aftByte,
          aftAutoIncSmallint,aftAutoIncByte:
           Result := 5;
          aftLargeInt,aftAutoIncLargeint:
           Result := 17;
          aftString,aftWideString,aftChar,aftMemo,aftFormattedMemo,aftWideMemo:
           begin
            Result := child.GetDataSize * 2;
            if (Result <= 0) then
             Result := SQLMemExpressionMaxStringSize
            else
             Inc(Result,2);
           end;
         end;
         if (children.Count = 2) then
          begin
           child := TSQLMemExprNode(Children[1]);
           if (not child.Value.IsNull) then
            begin
              i := child.Value.AsInteger;
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
   end; // string type
//  if ftype = ftWideString then
//    Result := Result * 2;
end;//GetDataSize


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetDataType: TSQLMemAdvancedFieldType;
var
  i: integer;
begin
  // default ftUnknown - Error flag
  Result := aftUnknown;
  if Children.Count <> 0 then
   begin
    // Take first type
    Result := TSQLMemExprNode(Children[0]).getDataType;
    // and compare it with other
    for i:=1 to Children.Count-1 do
      begin
        Result := getCommonDataType(Result, TSQLMemExprNode(Children[i]).getDataType);
      end;
   end;
  // commented in v.5.90 - does not needed   
//  if (Result = aftUnknown) then
//    raise ESQLMemException.Create(30283, ErrorGCannotDetermineExpressionType);
end;//GetDataType


//------------------------------------------------------------------------------
// return Data Precision
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetPrecision: Integer;
begin
  Result := 0;
end;//GetPrecision


//------------------------------------------------------------------------------
// can be used by the AO?
//------------------------------------------------------------------------------
function TSQLMemExprNode.CanBeAssigned(AO: TSQLMemAO): Boolean;
var
  i: Integer;
begin
{$IFDEF DEBUG_CAN_BE_ASSIGNED}
aaWriteToLog('> TSQLMemExprNode.CanBeAssigned: '+GetName+#13#10+' AO = '+AO.GetName);
{$ENDIF}
  Result := True;
  // get childs cans
  for i:=0 to Children.Count-1 do
    begin
      Result := Result and TSQLMemExprNode(Children[i]).CanBeAssigned(AO);
{$IFDEF DEBUG_CAN_BE_ASSIGNED}
aaWriteToLog('TSQLMemExprNode.CanBeAssigned: '+GetName+#13#10+'AO = '+AO.GetName+#13#10+'i = '+IntToStr(i)+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
      if (not Result) then
        break;
    end;
{$IFDEF DEBUG_CAN_BE_ASSIGNED}
aaWriteToLog('< TSQLMemExprNode.CanBeAssigned: '+GetName+#13#10+'AO = '+AO.GetName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
end;//CanBeAssigned


//------------------------------------------------------------------------------
// is node a join condition?
//------------------------------------------------------------------------------
function TSQLMemExprNode.IsJoinCondition(AO1, AO2: TSQLMemAO): Boolean;
begin
  Result := False;
end;// IsJoinConditions


//------------------------------------------------------------------------------
// replace pseudonyms to original names (f1 -> table1.field1)
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.ReplacePseudonyms(SelectList: array of TSQLMemSelectListItem);
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).ReplacePseudonyms(SelectList);
end;//ReplacePseudonyms


//------------------------------------------------------------------------------
// extract all TSQLMemExprNodeConst objects from FRootExprNode and all its children
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.ExtractAllParameterNodes(NodeList: TSQLMemList);
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).ExtractAllParameterNodes(NodeList);
end; // ExtractAllParameterNodes


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// return true if external field nodes exists (referencing main query from sub-query node)
//------------------------------------------------------------------------------
function TSQLMemExprNode.ExtractAllExternalFieldNodes(var FieldNodeList: TSQLMemList; var ConstNodeList: TSQLMemList; AO: TSQLMemAO): Boolean;
var
    i,n:  integer;
    node: TSQLMemExprNode;
begin
  Result := False;
  i := 0;
  while i < Children.Count do
  begin
   if (TSQLMemExprNode(Children[i]).ExtractAllExternalFieldNodes(FieldNodeList,ConstNodeList,AO)) then
   begin
    // fixed in v.5.70 pr#3 - we must change only external field nodes
    n := FieldNodeList.IndexOf(Children[i]);
    if (n >= 0) then
    begin
      // replace current node field with corresponding const node
      node := ConstNodeList.Items[n];
      Children[i] := node;
    end;
    Result := True;
   end;
   Inc(i);
  end;
end; // ExtractAllExternalFieldNodes


//------------------------------------------------------------------------------
// return true if expression has at least 1 correlated subquery
//------------------------------------------------------------------------------
function TSQLMemExprNode.CorrelatedSubQueriesExists: Boolean;
var
  i: integer;
begin
  Result := False;
  if (Self is TSQLMemExprNodeSubQuery) then
   Result := TSQLMemExprNodeSubQuery(Self).Correlated;
  if (not Result) then
    for i:=0 to Children.Count-1 do
    begin
     Result := TSQLMemExprNode(Children[i]).CorrelatedSubQueriesExists;
     if (Result) then
      Exit;
    end;
end; // CorrelatedSubQueriesExists


{$ENDIF}


//------------------------------------------------------------------------------
// raises exception if FRootExprNo or its child has TSQLMemExprNodeField
// added in 4.97 for raising correct exception if search condition cannot be
// assigned fully to AO
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.CheckInvalidFieldNames;
var
  i: integer;
begin
  for i:=0 to Children.Count-1 do
    TSQLMemExprNode(Children[i]).CheckInvalidFieldNames;
end; // CheckInvalidFieldNames


//------------------------------------------------------------------------------
// return true if is NULL or any child is NULL
//------------------------------------------------------------------------------
function TSQLMemExprNode.HasNullValues: Boolean;
var
  i: integer;
begin
  Result := GetDataValue.IsNull;
  if (not Result) then
   for i:=0 to Children.Count-1 do
    begin
     Result := TSQLMemExprNode(Children[i]).HasNullValues;
     if (Result) then
      Exit;
    end;
end; // HasNullValues


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNode.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.Assign(Source: TSQLMemExprNode);
var i:    Integer;
    node: TSQLMemExprNode;
begin
  if (Source = nil) then
    raise ESQLMemException.Create(12191,ErrorLNilPointer);
  if (Source.Children = nil) then
    raise ESQLMemException.Create(12199,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise ESQLMemException.Create(12192,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  Clear;
  // copy children
  for i:=0 to Source.Children.Count-1 do
   if (Source.Children[i] <> nil) then
    begin
     node := TSQLMemExprNode(Source.Children[i]).MakeCopy(LParentExpr);
     Children.Add(node);
    end;
  Operator := Source.Operator;
  // copy value
  Value.Assign(Source.Value,True);
  FCaseInsensitive := Source.FCaseInsensitive;
  FPartialKey := Source.FPartialKey;
  FIsParameter := Source.FIsParameter;
  FParamCRC := Source.FParamCRC;
end; // Assign


//------------------------------------------------------------------------------
// clear;
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.Clear;
var i: Integer;
begin
  if (Children = nil) then
   Children := TSQLMemList.Create;
  for i:=0 to Children.Count-1 do
   if (Children[i] <> nil) then
    try
      TSQLMemExprNode(Children[i]).Free;
    except
    end;
end; // Clear


//------------------------------------------------------------------------------
// make copy of TSQLMemSQLCommand object
//------------------------------------------------------------------------------
function TSQLMemExprNode.MakeCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := CreateCopy(aParentExpr);
  if (Result = nil) then
    raise ESQLMemException.Create(12193, ErrorLErrorMakeCopy,[Self.ClassName,IntToHex(Integer(Self),8)]);
  Result.Assign(Self);
end; // MakeCopy


//------------------------------------------------------------------------------
// find TSQLMemExprNodeComparison (Operator = doEQ) with child TSQLMemExprNodeField with specified name
//------------------------------------------------------------------------------
function TSQLMemExprNode.FindComaprisonEQWithField(FieldNameCRC: Cardinal; var Node1: TSQLMemExprNode; var Node2: TSQLMemExprNode): TSQLMemExprNode;
var i:    Integer;
    Node: TSQLMemExprNode;
begin
  Result := nil;
  for i := 0 to Children.Count-1 do
  begin
   Node := TSQLMemExprNode(Children[i]);
   if (Node is TSQLMemExprNodeComparison) then
    if (Node.Operator = doEQ) then
    begin
     Result := Node.FindComaprisonEQWithField(FieldNameCRC,Node1,Node2);
     if (Result <> nil) then
      Exit;
    end;
  end;
end; // FindComaprisonEQWithField


//------------------------------------------------------------------------------
// return TSQLMemExprNodeConst or TSQLMemExprNodeVar from children of TSQLMemExprNodeComparison
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetParameterNode: TSQLMemExprNode;
begin
  Result := nil;
end; // GetParameterNode


//------------------------------------------------------------------------------
// return TSQLMemExprNodeField of TSQLMemExprNodeComparison
//------------------------------------------------------------------------------
function TSQLMemExprNode.GetFieldNode: TSQLMemExprNode;
begin
  Result := nil;
end; // GetFieldNode


//------------------------------------------------------------------------------
// updates expression params (LocalParams,LSession,LStoredFunctioh) of all expressions inside all nodes
//------------------------------------------------------------------------------
procedure TSQLMemExprNode.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to Children.Count-1 do
  begin
   if (Children.Items[i] <> nil) then
     TSQLMemExprNode(Children.Items[i]).UpdateExpressionParams;
  end;
end; // UpdateExpressionParams




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeField
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return true if this node and all its children can be linked to source table filter expression
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.IsExprNodeCanBeLinkedToSourceTable(AO: TSQLMemAOTable): Boolean;
var i:      Integer;
    nameCRC, aliasCRC, crc:  Integer;
begin
 Result := (LAO = AO) and (AO.SourceDataset.FieldDefs.IndexOf(FFieldName) >= 0);
{
  if (Length(FTableName) = 0) then
   Result := False
  else
   begin
    nameCRC := GetTableNameCRC(AO.TableName,True);
    aliasCRC := GetTableNameCRC(AO.TableAlias,True);
    crc := GetTableNameCRC(FTableName);
    Result := ((nameCRC = crc) or (aliasCRC = crc));
   end;
}
end; // IsExprNodeCanBeLinkedToSourceTable


//------------------------------------------------------------------------------
// return true if there is any TSQLMemNodeField child that can be linked to AO
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.IsNodeFieldChildrenLinkedToAOExists(AO: TSQLMemAO): Boolean;
begin
  Result := CanBeAssigned(AO);
end; // IsNodeFieldChildrenLinkedToAOExists


{$IFDEF DEBUG_LOG}
//------------------------------------------------------------------------------
// get name
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.GetName: AnsiString;
begin
  Result := Self.ClassName+' '+GetOperatorName(Operator)+' '+FTableName+'.'+FFieldName+' '+GetFieldTypeSQLName(FFieldType);
  if (LAO = nil) and (LCursor = nil) then
   Result := Result + ' UNASSIGNED'
  else
  if (LAO <> nil)  then
   Result := Result + ' LAO = '+LAO.GetName
  else
   Result := Result + ' LCursor = '+LCursor.TableName;
  if (LRecordBuffer = nil) then
   Result := Result + ' NO BUFFER'
  else
   Result := Result + ' BUFFER';
end; // GetName
{$ENDIF}


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeField.Create(
                        aParentExpr: TSQLMemExpression;
                        Cursor:      TSQLMemCursor;
                        FieldName:   WideString;
                        TableName:   WideString
                                    );
begin
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStartTime(time21);
aaStartTime(time22);
{$ENDIF}
  inherited Create(aParentExpr);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time22);
aaStartTime(time23);
{$ENDIF}

  LCursor := Cursor;
  FFieldName := FieldName;
  FFieldNameCRC := GetTableNameCRC(FFieldName,True);
  FTableName := TableName;
  FTableNameCRC := GetTableNameCRC(FTableName,True);

  FFieldNo := -1;
  FFieldOffsetInBuffer := 0;
  FFieldType := aftUnknown;
  FBaseFieldType := bftUnknown;
  FIsBlob := False;
  FFieldSize := 0;
  FFieldPrecision := 0;
  LRecordBuffer := nil;

{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time23);
aaStartTime(time24);
{$ENDIF}
  if LCursor <> nil then
    AssignCursor(Cursor);
{$IFDEF DEBUG_TSQLMemExpression_ParseForLocate}
aaStopTime(time24);
aaStopTime(time21);
{$ENDIF}
end;//Create



//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeField.Destroy;
begin
  inherited;
  SQLMemClearString(FFieldName);
  SQLMemClearString(FTableName);
end; // Destroy


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.GetDataValue: TSQLMemVariant;
var TempBuffer: PAnsiChar;
{$I SQLMem_check_null_flag_var.inc}
begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time15);
{$ENDIF}
  if (LRecordBuffer <> nil) then
    begin
      CHECK_NULL_FLAG_BitNo := FFieldNo;
      CHECK_NULL_FLAG_NullFlags := LRecordBuffer;
      {$I SQLMem_check_null_flag.inc}
    // If field not null then set Value variable
      if (CHECK_NULL_FLAG_Result) then
        Value.SetNull(FBaseFieldType)
      else  
      begin
        if (LCursor = nil) then
         raise ESQLMemException.Create(11300,ErrorLNilPointer);
  //      if (IsBLOBFieldType(FBaseFieldType)) then
        TempBuffer := LCursor.CurrentRecordBuffer;
        try
//          if (Value.FIsBlob) then
          if (FIsBlob) then
          begin
            LCursor.CurrentRecordBuffer := LRecordBuffer;
            LCursor.GetBLOBValue(Value,FFieldNo);
          end
          else
          begin
           // optimized in v.5.60 - from LCursor.GetFieldValue
           Value.FIsNull := False;
           Value.FPData := PAnsiChar(LRecordBuffer + LCursor.FieldDefs[FFieldNo].MemoryOffset);
           Value.FDataType := LCursor.FieldDefs[FFieldNo].BaseFieldType;
           Value.FIsDataLinked := True;
           Value.FDataSize := LCursor.FieldDefs[FFieldNo].MemoryDataSize;
          end;
        finally
          LCursor.CurrentRecordBuffer := TempBuffer;
        end;
  //      else
  //      Value.SetData(LRecordBuffer + FFieldOffsetInBuffer,
  //                    FFieldSize, FBaseFieldType, False)
      end;
    end // Get from Cursor RecordBuffer
    else
      if ( (LAO <> nil) and (FFieldNo <> -1) ) then
        LAO.GetFieldValue(Value, FFieldNo, true, true)
      else
        raise ESQLMemException.Create(30196, ErrorGDatasetAndAONotAssigned);
    Result := Value;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time15);
{$ENDIF}
end;//GetDataValue


//------------------------------------------------------------------------------
// process assign AO
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.AssignAO(AO: TSQLMemAO);
var
  Fields: TSQLMemIntegerArray;
begin
  if (not FDoNotReassign) then
  begin
    LCursor := nil;
    LRecordBuffer := nil;
    LAO := AO;
    if LAO <> nil then
     begin
      Fields := TSQLMemIntegerArray.Create;
      try
        LAO.FieldExists(FFieldName, FTableName, True, Fields, True);
        if Fields.ItemCount = 1 then
          begin
            // Store Field Parameters
            FFieldNo := Fields.items[0];
            FFieldOffsetInBuffer := 0;
            FFieldType := LAO.GetFieldType(FFieldNo);
            FBaseFieldType := AdvancedFieldTypeToBaseFieldType(FFieldType);
            FIsBlob := IsBLOBFieldType(FBaseFieldType);
            FFieldSize := LAO.GetFieldSize(FFieldNo);
            FFieldPrecision := LAO.GetFieldPrecision(FFieldNo);
          end
        else
          raise ESQLMemException.Create(30197, ErrorGCannotFindField,
                                     [FTableName+'.'+FFieldName]);
      finally
        Fields.Free;
      end;
    end;
  end;
end;//AssignAO


//------------------------------------------------------------------------------
// process assign Cursor and its buffer
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.AssignCursor(Cursor: TSQLMemCursor);
var i,n: Integer;
begin
  if (not FDoNotReassign) then
  begin
    if Cursor = nil then
      raise ESQLMemException.Create(30202, ErrorGValueIsNull);

    LCursor := nil;
    i := 0;
    n := -1;
    while (i < Cursor.FieldDefs.Count) do
    begin
     if (Cursor.FieldDefs.Items[i].NameCRC = FFieldNameCRC) then
     begin
      n := i;
      break;
     end
     else
      Inc(i);
    end;
    if (n = -1) then
     begin
  //    n := LCursor.VisibleFieldDefs.GetDefNumberByName(FFieldName);
        i := 0;
        n := -1;
        while (i < Cursor.VisibleFieldDefs.Count) do
        begin
         if (Cursor.VisibleFieldDefs.Items[i].NameCRC = FFieldNameCRC) then
         begin
          n := i;
          break;
         end
         else
          Inc(i);
        end;
      if (n = -1) then
       raise ESQLMemException.Create(30115, ErrorGFieldWithNameNotFound, [FFieldName]);
      n := Cursor.VisibleFieldDefs[n].FieldNoReference;
     end;
    // Store Field Parameters
    FFieldNo := n;
    FFieldOffsetInBuffer := Cursor.FieldDefs[n].MemoryOffset;
    FFieldType := Cursor.FieldDefs[n].AdvancedFieldType;
    FBaseFieldType := Cursor.FieldDefs[n].BaseFieldType;
    FIsBlob := IsBLOBFieldType(FBaseFieldType);
    FFieldSize := Cursor.FieldDefs[n].MemoryDataSize;
    LCursor := Cursor;
    LAO := nil;
    AssignCursorBuffer(Cursor.CurrentRecordBuffer);
  end;
end;//AssignCursor


//------------------------------------------------------------------------------
// process assign New Cursor Buffer
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.AssignCursorBuffer(Buffer: TSQLMemRecordBuffer);
begin
  if (LAO = nil) then
    LRecordBuffer := Buffer;
end;//AssignCursorBuffer


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.GetDataType: TSQLMemAdvancedFieldType;
begin
{
  Result := aftUnknown;
  if LCursor <> nil then
    Result := LCursor.FieldDefs[FFieldNo].AdvancedFieldType
  else
    if LAO <> nil then
      Result := LAO.GetFieldType(FFieldNo);

  if (Result = aftUnknown) then
    raise ESQLMemException.Create(30284, ErrorGCannotDetermineExpressionType);
  Value.SetNull(FBaseFieldType);
}
  Result := FFieldType;
end;//GetDataType


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.GetDataSize: Integer;
begin
  {Result := 0;
  if LCursor <> nil then
    Result := LCursor.FieldDefs[FFieldNo].MemoryDataSize
  else
    if LAO <> nil then
      Result := LAO.GetFieldSize(FFieldNo);
  }
  Result := FFieldSize;
end; // GetDataSize


//------------------------------------------------------------------------------
// can be used by the AO?
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.CanBeAssigned(AO: TSQLMemAO): Boolean;
var
  Fields: TSQLMemIntegerArray;
begin
  Result := False;
  if (AO <> nil) then
    begin
      Fields := TSQLMemIntegerArray.Create;
      try
        AO.FieldExists(FFieldName, FTableName, False, Fields);
        if (Fields.ItemCount = 1) then
          Result := True;
      finally
        Fields.Free;
      end;
    end;
{$IFDEF DEBUG_CAN_BE_ASSIGNED}
aaWriteToLog('< TSQLMemExprNodeField.CanBeAssigned: '+GetName+#13#10+'AO = '+AO.GetName+#13#10+'Result = '+BoolToStr(Result,True));
{$ENDIF}
end; // CanBeAssigned


//------------------------------------------------------------------------------
// fills Field Item
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.FillItem(var Item: TSQLMemSelectListItem);
begin
  Item.TableName := FTableName;
  Item.FieldName := FFieldName;
  Item.ValueExpr := nil;
end;// FillItem


//------------------------------------------------------------------------------
// replace pseudonyms to original names (f1 -> table1.field1)
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.ReplacePseudonyms(SelectList: array of TSQLMemSelectListItem);
var
  i: Integer;
begin
  for i := 0 to Length(SelectList)-1 do
  if (WideUpperCase(FFieldName) = WideUpperCase(SelectList[i].Pseudonym)) then
   if (not SelectList[i].IsExpression) then
    if (FTableName = '') then
     begin
      FFieldName := SelectList[i].FieldName;
      // fixed in v.5.90
      FFieldNameCRC := GetTableNameCRC(FFieldName,True);
      FTableName := SelectList[i].TableName;
      // fixed in v.5.90
      FTableNameCRC := GetTableNameCRC(FTableName,True);
     end;
end;//ReplacePseudonyms


//------------------------------------------------------------------------------
// raises exception if FRootExprNo or its child has TSQLMemExprNodeField
// added in 4.97 for raising correct exception if search condition cannot be
// assigned fully to AO
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.CheckInvalidFieldNames;
begin
  if (Length(FTableName) > 0) then
    raise ESQLMemException.Create(11764,ErrorGCannotFindField,[FTableName+'.'+FFieldName])
  else
    raise ESQLMemException.Create(11764,ErrorGCannotFindField,[FFieldName]);
end; // CheckInvalidFieldNames


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeField.Create(aParentExpr);
  TSQLMemExprNodeField(Result).LCursor := nil;
  TSQLMemExprNodeField(Result).LRecordBuffer := nil;
  TSQLMemExprNodeField(Result).LAO := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeField.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  LCursor := TSQLMemExprNodeField(Source).LCursor;
  LAO := TSQLMemExprNodeField(Source).LAO;
  LRecordBuffer := TSQLMemExprNodeField(Source).LRecordBuffer;
  FTableName := TSQLMemExprNodeField(Source).FTableName;
  FTableNameCRC := TSQLMemExprNodeField(Source).FTableNameCRC;
  FFieldName := TSQLMemExprNodeField(Source).FFieldName;
  FFieldNameCRC := TSQLMemExprNodeField(Source).FFieldNameCRC;
  FFieldNo := TSQLMemExprNodeField(Source).FFieldNo;
  FFieldOffsetInBuffer := TSQLMemExprNodeField(Source).FFieldOffsetInBuffer;
  FFieldType := TSQLMemExprNodeField(Source).FFieldType;
  FBaseFieldType := TSQLMemExprNodeField(Source).FBaseFieldType;
  FFieldSize := TSQLMemExprNodeField(Source).FFieldSize;
  FFieldPrecision := TSQLMemExprNodeField(Source).FFieldPrecision;
end; // Assign


{$IFDEF CORRELATED_SUBQUERIES}
//------------------------------------------------------------------------------
// return true if external field nodes exists (referencing main query from sub-query node)
//------------------------------------------------------------------------------
function TSQLMemExprNodeField.ExtractAllExternalFieldNodes(var FieldNodeList: TSQLMemList; var ConstNodeList: TSQLMemList; AO: TSQLMemAO): Boolean;
var n:    Integer;
    node: TSQLMemExprNodeConst;
begin
  Result := not CanBeAssigned(AO);
  if (Result) then
  begin
   if (FieldNodeList = nil) then
    FieldNodeList := TSQLMemList.Create;
   FieldNodeList.Add(Self);
   if (ConstNodeList = nil) then
    ConstNodeList := TSQLMemList.Create;
   node := TSQLMemExprNodeConst.Create(LParentExpr);
//   node.FIsParameter := True; 
   ConstNodeList.Add(node);
  end;
end; // ExtractAllExternalFieldNodes
{$ENDIF}


{$IFNDEF CORRELATED_SUBQUERIES}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQuery
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeSubQuery.Create(
                       aParentExpr:       TSQLMemExpression;
                       QueryText:         WideString;
                       Params:            TParams;
                       InMemory:          Boolean;
                       DatabaseName:      AnsiString;
                       SessionName:       AnsiString;
                       bNot:              Boolean = False;
                       SourceNode:        TSQLMemExprNode = nil
                       );
var i:      Integer;
    Param:  TParam;
begin
  inherited Create(aParentExpr);
  FQueryResult := False;
  FQuery := TSQLMemQuery.Create(nil);
  TSQLMemQuery(FQuery).SQL.Text := QueryText;
  TSQLMemQuery(FQuery).DatabaseName := DatabaseName;
  TSQLMemQuery(FQuery).SessionName := SessionName;
  TSQLMemQuery(FQuery).InMemory := InMemory;
  TSQLMemQuery(FQuery).Prepare;
  for i := 0 to TSQLMemQuery(FQuery).Params.Count-1 do
   begin
    if (Params = nil) then
     Param := nil
    else
     Param := Params.FindParam(TSQLMemQuery(FQuery).Params[i].Name);
    if (Param <> nil) then
     TSQLMemQuery(FQuery).Params[i].Assign(Param);
   end;
  FNot := bNot;
  FSourceNode := SourceNode;
  if (SourceNode <> nil) then
   Children.Add(SourceNode);
  // try to open quiery to get the result data type
  try
    TSQLMemQuery(FQuery).Open;
    if (TSQLMemQuery(FQuery).RecordCount < 1) then
     raise ESQLMemException.Create(10848,ErrorLSubqueryReturnsNoRows);
    FDataType := TSQLMemQuery(FQuery).AdvFieldDefs.Items[0].DataType;
    TSQLMemQuery(FQuery).GetFieldValue(Value,0,False);
  except
    FDataType := aftUnknown;
    Value.SetNull;
  end;
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
// return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetDataValue: TSQLMemVariant;
begin
{
  if (not FQueryExecuted) then
   begin
    FQueryExecuted := True;
    try
      TSQLMemQuery(FQuery).Open;
      if (TSQLMemQuery(FQuery).RecordCount < 1) then
       raise ESQLMemException.Create(10848,ErrorLSubqueryReturnsNoRows);
      if (TSQLMemQuery(FQuery).RecordCount > 1) then
       raise ESQLMemException.Create(10849,ErrorLSubqueryReturnsMultipleRows);

      TSQLMemQuery(FQuery).GetFieldValue(Value,0,False);
      FQuery.Close;
      FreeAndNil(FQuery);
    except
      FQuery.Free;
      Fquery := nil;
      raise;
    end;
   end;
}
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := FDataType;
end;//GetDataType


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQuery.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeSubQuery.Create(aParentExpr);
  TSQLMemExprNodeSubQuery(Result).FQuery := TSQLMemQuery.Create(nil);
  TSQLMemExprNodeSubQuery(Result).FSourceNode := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSubQuery.Assign(Source: TSQLMemExprNode);
var i:      Integer;
    Param:  TParam;
begin
  TSQLMemQuery(FQuery).SQL.Text := TSQLMemQuery(TSQLMemExprNodeSubQuery(Source).FQuery).SQL.Text;
  TSQLMemQuery(FQuery).DatabaseName := TSQLMemQuery(TSQLMemExprNodeSubQuery(Source).FQuery).DatabaseName;
  TSQLMemQuery(FQuery).SessionName := TSQLMemQuery(TSQLMemExprNodeSubQuery(Source).FQuery).SessionName;
  TSQLMemQuery(FQuery).InMemory := TSQLMemQuery(TSQLMemExprNodeSubQuery(Source).FQuery).InMemory;
  TSQLMemQuery(FQuery).Prepare;
  TSQLMemQuery(FQuery).Params.Assign(TSQLMemQuery(TSQLMemExprNodeSubQuery(Source).FQuery).Params);
  FNot := TSQLMemExprNodeSubQuery(Source).FNot;
  if (FSourceNode <> nil) then
   FreeAndNil(FSourceNode);
  if (TSQLMemExprNodeSubQuery(Source).FSourceNode <> nil) then
    FSourceNode := TSQLMemExprNode(TSQLMemExprNodeSubQuery(Source).FSourceNode).MakeCopy(LParentExpr);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQueryIn
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQueryIn.GetDataValue: TSQLMemVariant;
var v:         variant;
    FieldName: WideString;
begin
  FieldName := FQuery.Fields[0].FieldName;
  if (FSourceNode = nil) then
   raise ESQLMemException.Create(10850,ErrorLSubqueryINnoArgumentPassed);
  Result := TSQLMemExprNode(FSourceNode).GetDataValue;
  if (Result.IsNull) then
   v := varNull
  else
   v := Result.AsVariant;
  if (FNot) then
   Value.AsBoolean := not TSQLMemQuery(FQuery).Locate(FieldName,v,[])
  else
   Value.AsBoolean := TSQLMemQuery(FQuery).Locate(FieldName,v,[]);
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Value as Boolean
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQueryIn.GetBooleanValue: Boolean;
var v:         variant;
    FieldName: WideString;
    res:       TSQLMemVariant;
begin
  FieldName := FQuery.Fields[0].FieldName;
  if (FSourceNode = nil) then
   raise ESQLMemException.Create(12402,ErrorLSubqueryINnoArgumentPassed);
  res := TSQLMemExprNode(FSourceNode).GetDataValue;
  if (res.IsNull) then
   v := varNull
  else
   v := res.AsVariant;
{ TODO : replace Locate with function for direct search for this field using active index if possible }   
  if (FNot) then
   Result := not TSQLMemQuery(FQuery).Locate(FieldName,v,[])
  else
   Result := TSQLMemQuery(FQuery).Locate(FieldName,v,[]);
end; // GetBooleanValue




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSubQueryExists
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQueryExists.GetDataValue: TSQLMemVariant;
begin
  if (FNot) then
    Value.AsBoolean := TSQLMemQuery(FQuery).Eof
  else
    Value.AsBoolean := not TSQLMemQuery(FQuery).Eof;
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Value as Boolean
//------------------------------------------------------------------------------
function TSQLMemExprNodeSubQueryExists.GetBooleanValue: Boolean;
begin
  if (FNot) then
    Result := TSQLMemQuery(FQuery).Eof
  else
    Result := not TSQLMemQuery(FQuery).Eof;
end; // GetBooleanValue
{$ENDIF}



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeComparison
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// converts some WideStrings to Strings
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeComparison.PatchWideStrings;
var
   i:      Integer;
   NField: TSQLMemExprNodeField;
   NConst: TSQLMemExprNodeConst;
   dt: TSQLMemAdvancedFieldType;
begin
  NField := nil;
  NConst := nil;
  for i:=0 to Children.Count-1 do
    if TSQLMemExprNode(Children[i]) is TSQLMemExprNodeField then
      NField := Children[i]
    else if TSQLMemExprNode(Children[i]) is TSQLMemExprNodeConst then
      NConst := Children[i];

  if (NConst <> nil) and (NField <> nil) then
    begin
      dt := NField.GetDataType;
      if ( IsStringFieldType(dt) and (not IsWideStringFieldType(dt)) ) then
        if IsWideStringFieldType(NConst.GetDataType) then
          NConst.Value.Cast(bftVarchar);
    end;
end;//PatchWideStrings


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeComparison.Create(
                                           aParentExpr:         TSQLMemExpression;
                                           Op:                  TSQLMemDataOperator;
                                           Node1, Node2:        TSQLMemExprNode;
                                           TrueFalseNullLogic:  Boolean;
                                           CaseInsensitive:     Boolean;
                                           PartialKey:          Boolean
                                         );
begin
  inherited Create(aParentExpr, Op, Node1, Node2,CaseInsensitive, PartialKey);
  F3ValueLogic := TrueFalseNullLogic;
//  Value.SetNull(bftLogical);
  if (op = doEQ) then
  begin
    if (Node1 is TSQLMemExprNodeField) then
    begin
      FNode1 := Node1;
      FNode2 := Node2;
    end
    else
    begin
      FNode1 := Node2;
      FNode2 := Node1;
    end;
  end
  else
  begin
    FNode1 := Node1;
    FNode2 := Node2;
  end;
  // optimized in v.5.60
  Value.AsBoolean := False;
end;//Create


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.GetDataValue: TSQLMemVariant;
var
   {$I SQLMem_cmp_variants_var.inc}
begin
// optimized in v.5.60
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time17);
{$ENDIF}

{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time16);
{$ENDIF}
    CMP_VAR_Value1 := TSQLMemExprNode(Children[0]).GetDataValue;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time16);
{$ENDIF}
  // added in 4.95 to make
  // = NULL same as IS NULL
  // <> NULL same as IS NOT NULL
  if ((Operator = doISNULL) or (Operator = doISNOTNULL)) then
   begin
    if (Operator = doISNULL) then
     begin
      PBoolean(Value.PData)^ := CMP_VAR_Value1.IsNull;
     end
    else
     begin
      // optimized in v.5.60
      PBoolean(Value.PData)^ := not CMP_VAR_Value1.IsNull;
     end;
   end // IS NULL / IS NOT NULL
  else
   begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time18);
{$ENDIF}
      CMP_VAR_Value2 := FNode2.GetDataValue;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time18);
aaStartTime(time19);
{$ENDIF}
    // setup parameters
    CMP_VAR_TrueFalseNullLogic := F3ValueLogic;
    CMP_VAR_CaseInsensitive := FCaseInsensitive;
    CMP_VAR_PartialKey := FPartialKey;
    // compare
    //      CMP_VAR_Result := arg1.Compare(arg2, F3ValueLogic , FCaseInsensitive, FPartialKey);
    {$I SQLMem_cmp_variants.inc}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time19);
aaStartTime(time20);
{$ENDIF}
    case Operator of
     doEQ:   PBoolean(Value.FPData)^  := (CMP_VAR_Result = cmprEqual);
     doNE:   PBoolean(Value.FPData)^ := (CMP_VAR_Result <> cmprEqual);
     doLT:   PBoolean(Value.FPData)^ := (CMP_VAR_Result = cmprLower);
     doGT:   PBoolean(Value.FPData)^ := (CMP_VAR_Result = cmprGreater);
     doLE:   PBoolean(Value.FPData)^ := (CMP_VAR_Result = cmprEqual) or (CMP_VAR_Result = cmprLower);
     doGE:   PBoolean(Value.FPData)^ := (CMP_VAR_Result = cmprEqual) or (CMP_VAR_Result = cmprGreater);
     else
       raise ESQLMemException.Create(12383, ErrorGUnknownOperator, [GetOperatorName(Operator)]);
    end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time20);
{$ENDIF}
  end; // other operators
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time21);
{$ENDIF}
  Result := Value;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time21);
aaStopTime(time17);
{$ENDIF}
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := aftBoolean;
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.GetDataSize: Integer;
begin
  Result := 0;
end; // GetDataSize


//------------------------------------------------------------------------------
// return Value as Boolean
// created in v.5.60 for boolean optimization
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.GetBooleanValue: Boolean;
var
   {$I SQLMem_cmp_variants_var.inc}
begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time17);
aaStartTime(time16);
{$ENDIF}
//    arg1 := TSQLMemExprNode(Children[0]).GetDataValue;
  CMP_VAR_Value1 := FNode1.GetDataValue;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time16);
{$ENDIF}
  // added in 4.95 to make
  // = NULL same as IS NULL
  // <> NULL same as IS NOT NULL
  if ((Operator = doISNULL) or (Operator = doISNOTNULL)) then
  begin
    if (Operator = doISNULL) then
     begin
      // optimized in v.5.60
      Result := CMP_VAR_Value1.IsNull;
     end
    else
     begin
      // optimized in v.5.60
      Result := not CMP_VAR_Value1.IsNull;
     end;
  end // IS NULL / IS NOT NULL
  else
  begin
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStartTime(time18);
{$ENDIF}
      CMP_VAR_Value2 := FNode2.GetDataValue;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time18);
aaStartTime(time19);
{$ENDIF}
    // setup parameters
    CMP_VAR_TrueFalseNullLogic := F3ValueLogic;
    CMP_VAR_CaseInsensitive := FCaseInsensitive;
    CMP_VAR_PartialKey := FPartialKey;
    // compare
    //      CMP_VAR_Result := arg1.Compare(arg2, F3ValueLogic , FCaseInsensitive, FPartialKey);
    {$I SQLMem_cmp_variants.inc}
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time19);
aaStartTime(time20);
{$ENDIF}
    case Operator of
     doEQ:   Result := (CMP_VAR_Result = cmprEqual);
     doNE:   Result := (CMP_VAR_Result <> cmprEqual);
     doLT:   Result := (CMP_VAR_Result = cmprLower);
     doGT:   Result := (CMP_VAR_Result = cmprGreater);
     doLE:   Result := (CMP_VAR_Result = cmprEqual) or (CMP_VAR_Result = cmprLower);
     doGE:   Result := (CMP_VAR_Result = cmprEqual) or (CMP_VAR_Result = cmprGreater);
     else
       raise ESQLMemException.Create(12383, ErrorGUnknownOperator, [GetOperatorName(Operator)]);
    end;
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time20);
{$ENDIF}
  end; // other operators
{$IFDEF DEBUG_FIND_RECORD_BY_SCAN_TIME}
aaStopTime(time17);
{$ENDIF}
end; // GetBooleanValue


//------------------------------------------------------------------------------
// can use index for comparison?
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.CanUseIndex(IndexDef: TSQLMemIndexDef): Boolean;
var
  FieldNode: TSQLMemExprNodeField;
  ConstNode: TSQLMemExprNode;
  IsString:  Boolean;

begin
  FieldNode := nil;
  ConstNode := nil;
  if (TObject(Children[0]) is TSQLMemExprNodeField) then
    FieldNode := Children[0];
  if (TObject(Children[1]) is TSQLMemExprNodeField) then
    FieldNode := Children[1];
  if ((TObject(Children[0]) is TSQLMemExprNodeConst) or (TObject(Children[0]) is TSQLMemExprNodeVariable)) then
    ConstNode := Children[0];
  if ((TObject(Children[1]) is TSQLMemExprNodeConst) or (TObject(Children[1]) is TSQLMemExprNodeVariable)) then
    ConstNode := Children[1];
  if ((FieldNode <> nil) and (ConstNode <> nil)) then
   begin
     Result := (FPartialKey = False);
     if (Result) then
       Result := (Operator = doEQ) or
                 (Operator = doGT) or
                 (Operator = doLT) or
                 (Operator = doGE) or
                 (Operator = doLE);
     IsString := IsStringFieldType(FieldNode.BaseFieldType);
     if (Result) then
      if (IsString) then
       Result := (FCaseInsensitive = IndexDef.Columns[0].CaseInsensitive);
     if (Result) then
       Result := (FieldNode.FieldNameCRC =
                GetTableNameCRC(IndexDef.Columns[0].FieldName,True));
// commented in 4.04
//     if (Result and IsString) then
//       Result := (FieldNode.FieldSize >= ConstNode.GetDataSize);
   end
  else
   Result := False;
end;// CanUseIndex


{$IFNDEF RECORD_SEARCH_CACHE_IN_CURSOR}
//------------------------------------------------------------------------------
// add index scan condition
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeComparison.AddAsIndexScanCondition(
               ScanConditions:          TSQLMemScanSearchConditionArray;
               IndexDef:                TSQLMemIndexDef;
               ExtractedConditionsInfo: TList;
               Expression:              TSQLMemExpression
                          );
var
  FieldNode:     TSQLMemExprNodeField;
  ConstNode:     TSQLMemExprNode;
  ScanCondition: TSQLMemScanSearchCondition;
  ExCondInfo:    PSQLMemExtractedConditionInfo;
begin
  FieldNode := nil;
  ConstNode := nil;
  if (TObject(Children[0]) is TSQLMemExprNodeField) then
    FieldNode := Children[0];
  if (TObject(Children[1]) is TSQLMemExprNodeField) then
    FieldNode := Children[1];
  if ((TObject(Children[0]) is TSQLMemExprNodeConst) or (TObject(Children[0]) is TSQLMemExprNodeVariable)) then
    ConstNode := Children[0];
  if ((TObject(Children[1]) is TSQLMemExprNodeConst) or (TObject(Children[1]) is TSQLMemExprNodeVariable))then
    ConstNode := Children[1];
  if ((FieldNode <> nil) and (ConstNode <> nil)) then
   begin
    if (FieldNode.LCursor = nil) then
      raise ESQLMemException.Create(20054, ErrorANilPointer);
    if (IndexDef.ColumnCount < 1) then
      raise ESQLMemException.Create(20057, ErrorAInvalidIndexForSearch);

    ScanCondition := TSQLMemScanSearchCondition.Create;
    try
      if (IndexDef.Columns[0].Descending) then
        case Operator of
         doEQ: ScanCondition.Condition := scEqual;
         doGT: ScanCondition.Condition := scLower;
         doLT: ScanCondition.Condition := scGreater;
         doGE: ScanCondition.Condition := scLowerEqual;
         doLE: ScanCondition.Condition := scGreaterEqual;
        end
      else
        case Operator of
         doEQ: ScanCondition.Condition := scEqual;
         doGT: ScanCondition.Condition := scGreater;
         doLT: ScanCondition.Condition := scLower;
         doGE: ScanCondition.Condition := scGreaterEqual;
         doLE: ScanCondition.Condition := scLowerEqual;
        end;

      ScanCondition.KeyRecordBuffer := FieldNode.LCursor.AllocateRecordBuffer;
      FieldNode.LCursor.SetFieldValue(
                                       ConstNode.GetDataValue,
                                       FieldNode.FieldNo,
                                       True,
                                       ScanCondition.KeyRecordBuffer
                                     );
      ScanCondition.KeyFieldCount := 1;
      ScanCondition.IndexID := IndexDef.ObjectID;
      ScanCondition.Expression := nil;
      ScanConditions.AddCondition(ScanCondition);

      New(ExCondInfo);
      ExCondInfo^.KeyRecordBuffer := ScanCondition.KeyRecordBuffer;
      ExCondInfo^.ExtractedExpressionNode := Self;
      ExCondInfo^.Expression := Expression;
      ExtractedConditionsInfo.Add(ExCondInfo);
    finally
      ScanCondition.Free;
    end;
   end
  else
   raise ESQLMemException.Create(20055, ErrorANilPointer);
end;// AddScanCondition
{$ENDIF}


{$IFDEF RECORD_SEARCH_CACHE_IN_CURSOR}
// add index scan condition
procedure TSQLMemExprNodeComparison.AddAsIndexScanCondition(
               ScanConditions: TSQLMemList;
               IndexDef:       TSQLMemIndexDef
                          );
var
  FieldNode:     TSQLMemExprNodeField;
  ConstNode:     TSQLMemExprNode;
  ScanCondition: TSQLMemScanSearchCondition;
  i:             Integer;
begin
  FieldNode := nil;
  ConstNode := nil;
  if (TObject(Children[0]) is TSQLMemExprNodeField) then
    FieldNode := Children[0];
  if (TObject(Children[1]) is TSQLMemExprNodeField) then
    FieldNode := Children[1];
  if ((TObject(Children[0]) is TSQLMemExprNodeConst) or (TObject(Children[0]) is TSQLMemExprNodeVariable)) then
    ConstNode := Children[0];
  if ((TObject(Children[1]) is TSQLMemExprNodeConst) or (TObject(Children[1]) is TSQLMemExprNodeVariable))then
    ConstNode := Children[1];
  if ((FieldNode <> nil) and (ConstNode <> nil)) then
  begin
    if (FieldNode.LCursor = nil) then
      raise ESQLMemException.Create(12395, ErrorLNilPointer);
    if (IndexDef.ColumnCount < 1) then
      raise ESQLMemException.Create(12396, ErrorAInvalidIndexForSearch);

    ScanCondition := TSQLMemScanSearchCondition.Create;
    if (IndexDef.Columns[0].Descending) then
      case Operator of
       doEQ: ScanCondition.Condition := scEqual;
       doGT: ScanCondition.Condition := scLower;
       doLT: ScanCondition.Condition := scGreater;
       doGE: ScanCondition.Condition := scLowerEqual;
       doLE: ScanCondition.Condition := scGreaterEqual;
      end
    else
      case Operator of
       doEQ: ScanCondition.Condition := scEqual;
       doGT: ScanCondition.Condition := scGreater;
       doLT: ScanCondition.Condition := scLower;
       doGE: ScanCondition.Condition := scGreaterEqual;
       doLE: ScanCondition.Condition := scLowerEqual;
      end;
    ScanCondition.KeyRecordBuffer := FieldNode.LCursor.AllocateRecordBuffer;
    ScanCondition.OwnKeyBuffer := True;
    if (ConstNode is TSQLMemExprNodeVariable) then
    begin
      ScanCondition.ParamIndexes.Append(TSQLMemExprNodeVariable(ConstNode).ParamIndex);
    end
    else
    begin
      FieldNode.LCursor.SetFieldValue(
                                       ConstNode.GetDataValue,
                                       FieldNode.FieldNo,
                                       True,
                                       ScanCondition.KeyRecordBuffer
                                     );
    end;
    ScanCondition.KeyFieldCount := 1;
    ScanCondition.IndexID := IndexDef.ObjectID;
    ScanCondition.Expression := nil;
    ScanConditions.Add(ScanCondition);
   end
  else
   raise ESQLMemException.Create(12397, ErrorLNilPointer);
end; // AddAsIndexScanCondition
{$ENDIF}


//------------------------------------------------------------------------------
// incompatible
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.IsIncompatible: Boolean;
var
  FieldNode: TSQLMemExprNodeField;
  ConstNode: TSQLMemExprNodeConst;
  l:         Integer;
begin
  Result := False;
  FieldNode := nil;
  ConstNode := nil;
  if (TObject(Children[0]) is TSQLMemExprNodeField) then
    FieldNode := Children[0];
  if (TObject(Children[1]) is TSQLMemExprNodeField) then
    FieldNode := Children[1];
  if (TObject(Children[0]) is TSQLMemExprNodeConst) then
    ConstNode := Children[0];
  if (TObject(Children[1]) is TSQLMemExprNodeConst) then
    ConstNode := Children[1];

  if ((FieldNode <> nil) and (ConstNode <> nil)) then
   begin
    if (Operator = doEQ) then
     if (IsStringFieldType(FieldNode.BaseFieldType)) then
      if (not ConstNode.Value.IsNull) then
       begin
        // fixed in v.5.60
        l := ConstNode.Value.StrLen;
        Result := (FieldNode.FieldSize < l);
       end;
   end;
end; // IsIncompatible


//------------------------------------------------------------------------------
// is node a join condition?
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.IsJoinCondition(AO1,AO2: TSQLMemAO): Boolean;
var
  Left, Right: TSQLMemExprNodeField;
  FieldNumber: TSQLMemIntegerArray;
  Field1LeftCount, Field1RightCount: integer;
  Field2LeftCount, Field2RightCount: integer;
begin
  Result := false;
  if not ((TSQLMemExprNode(Children[0]) is TSQLMemExprNodeField) and
          (TSQLMemExprNode(Children[1]) is TSQLMemExprNodeField)) then Exit;

  Left := TSQLMemExprNodeField(Children[0]);
  Right := TSQLMemExprNodeField(Children[1]);
  if Operator = doEQ then
   if ((Left is TSQLMemExprNodeField) and
       (Right is TSQLMemExprNodeField)) then
    begin
     FieldNumber := TSQLMemIntegerArray.Create;
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
      // modified in v.5.90
      {
      // ambiguous field reference?
      if (Field1LeftCount+Field1RightCount > 1) then
        raise ESQLMemException.Create(10404, ErrorLAmbiguousFieldReference, [Left.FieldName]);
      if (Field2LeftCount+Field2RightCount > 1) then
        raise ESQLMemException.Create(10405, ErrorLAmbiguousFieldReference, [Right.FieldName]);
      // each field macths only 1 AO?
      if ((Field1LeftCount+Field1RightCount = 1) and
          (Field2LeftCount+Field2RightCount = 1)) then
       // boths fields match different AO?
       if (Field1LeftCount <> Field2LeftCount) then
        Result := True;
      }
      if ((Field1LeftCount+Field1RightCount >= 1) and
          (Field2LeftCount+Field2RightCount >= 1)) then
       // boths fields match different AO?
//       if (Field1LeftCount <> Field2LeftCount) then
        Result := True;
     finally
      FieldNumber.Free;
     end;
    end;
end; // IsJoinCondition


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeComparison.Create(aParentExpr);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeComparison.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  F3ValueLogic := TSQLMemExprNodeComparison(Source).F3ValueLogic;
  FCaseInsensitive := TSQLMemExprNodeComparison(Source).FCaseInsensitive;
  FNode1 := TSQLMemExprNode(Children.Items[0]);
  FNode2 := TSQLMemExprNode(Children.Items[1]);
end; // Assign


//------------------------------------------------------------------------------
// find TSQLMemExprNodeComparison (Operator = doEQ) with child TSQLMemExprNodeField with specified name
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.FindComaprisonEQWithField(FieldNameCRC: Cardinal; var Node1: TSQLMemExprNode; var Node2: TSQLMemExprNode): TSQLMemExprNode;
begin
  if (TSQLMemExprNodeField(FNode1).FFieldNameCRC = FieldNameCRC) then
  begin
    Result := Self;
    Node1 := FNode1;
    Node2 := FNode2;
  end
  else
    Result := nil;
end; // FindComaprisonEQWithField


//------------------------------------------------------------------------------
// return TSQLMemExprNodeConst or TSQLMemExprNodeVar from children of TSQLMemExprNodeComparison
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.GetParameterNode: TSQLMemExprNode;
begin
  Result := FNode2;
end; // GetParameterNode


//------------------------------------------------------------------------------
// return TSQLMemExprNodeField of TSQLMemExprNodeComparison
//------------------------------------------------------------------------------
function TSQLMemExprNodeComparison.GetFieldNode: TSQLMemExprNode;
begin
  Result := FNode1;
end; // GetFieldNode




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeSystem
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// LastAutoInc
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSystem.LastAutoInc;
begin
  Value.SetNull(AdvancedFieldTypeToBaseFieldType(GetDataType));
  Value.AsInt64 := TSQLMemTable(FTable).LastAutoincValue(FColumnName);
end;//LastAutoInc


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeSystem.Create(
                                      aParentExpr:  TSQLMemExpression;
                                      Operator:     TSQLMemDataOperator;
                                      TableName:    WideString;
                                      ColumnName:   WideString;
                                      InMemory:     Boolean;
                                      SessionName:  AnsiString;
                                      DatabaseName: AnsiString
                                     );
var
  FieldDef: TSQLMemAdvFieldDef;
begin
  inherited Create(aParentExpr,Operator);
  FTableName := TableName;
  FColumnName := ColumnName;
  FSessionName := SessionName;
  FFieldType := aftUnknown;
  FInMemory := InMemory;
  FDatabaseName := DatabaseName;

  FTable := TSQLMemTable.Create(nil);
  TSQLMemTable(FTable).SessionName := FSessionName;
  TSQLMemTable(FTable).TableName := FTableName;
  TSQLMemTable(FTable).InMemory := FInMemory;
  if (DatabaseName <> '') then
   TSQLMemTable(FTable).DatabaseName := FDatabaseName;
  TSQLMemTable(FTable).ReadOnly := True;
  TSQLMemTable(FTable).Open;

  // Field Type
  FieldDef := TSQLMemTable(FTable).AdvFieldDefs.Find(FColumnName);
  if (FieldDef = nil) then
    raise ESQLMemException.Create(30337, ErrorGFieldWithNameNotFound, [FColumnName]);
  FFieldType := FieldDef.DataType;

end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeSystem.Destroy;
begin
  TSQLMemTable(FTable).Close;
  FTable.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeSystem.GetDataValue: TSQLMemVariant;
begin
  case Operator of
    doLASTAUTOINC: LastAutoInc;
    else
      raise ESQLMemException.Create(30338, ErrorGUnknownOperator, [GetOperatorName(Operator)]);
  end;

  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeSystem.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := FFieldType;
end;//GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeSystem.GetDataSize: Integer;
begin
  Result := 0;
end;//GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeSystem.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeSystem.Create(aParentExpr);
  TSQLMemExprNodeSystem(Result).FTable := TSQLMemTable.Create(nil);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeSystem.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FSessionName := TSQLMemExprNodeSystem(Source).FSessionName;
  FDatabaseName := TSQLMemExprNodeSystem(Source).FDatabaseName;
  FTableName := TSQLMemExprNodeSystem(Source).FTableName;
  FColumnName := TSQLMemExprNodeSystem(Source).FColumnName;
  FInMemory := TSQLMemExprNodeSystem(Source).FInMemory;
  FFieldType := TSQLMemExprNodeSystem(Source).FFieldType;
  TSQLMemTable(FTable).SessionName := FSessionName;
  TSQLMemTable(FTable).TableName := FTableName;
  TSQLMemTable(FTable).InMemory := FInMemory;
  TSQLMemTable(FTable).DatabaseName := FDatabaseName;
  TSQLMemTable(FTable).ReadOnly := True;
  TSQLMemTable(FTable).Open;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeAggregated
//
// aggregated functions - SUM, AVG, COUNT, MIN, MAX, CUMPROD, CUMSUM, etc.
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeAggregated.Create(
                                           aParentExpr: TSQLMemExpression;
                                           Op:          TSQLMemDataOperator
                                         );
begin
  inherited Create(aParentExpr, Op);
  Count := 0;
  AvgSum := TSQLMemVariant.Create;
  distinct := False;
  FTempTable := nil;
  FGroupConcatSeparatorAnsi := '';
  FGroupConcatSeparatorWide := '';
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeAggregated.Create(
                                           aParentExpr: TSQLMemExpression;
                                           Op:          TSQLMemDataOperator;
                                           aDistinct:   Boolean;
                                           Node:        TSQLMemExprNode;
                                           aDesc:       Boolean
                                         );
begin
  inherited Create(aParentExpr, op, Node);
  distinct := aDistinct;
  desc := aDesc;
  AvgSum := TSQLMemVariant.Create;
  FTempTable := nil;
  FGroupConcatSeparatorAnsi := '';
  FGroupConcatSeparatorWide := '';
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeAggregated.Create(
                                           aParentExpr: TSQLMemExpression;
                                           Op:          TSQLMemDataOperator;
                                           aDistinct:   Boolean;
                                           Node1:       TSQLMemExprNode;
                                           Node2:       TSQLMemExprNode;
                                           aDesc:       Boolean
                                         );
begin
  inherited Create(aParentExpr, op, Node1, Node2);
  distinct := aDistinct;
  desc := aDesc;
  AvgSum := TSQLMemVariant.Create;
  FTempTable := nil;
  FGroupConcatSeparatorAnsi := '';
  FGroupConcatSeparatorWide := '';
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeAggregated.Destroy;
begin
  AvgSum.Free;
  if (FTempTable <> nil) then
   FTempTable.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeAggregated.GetDataValue: TSQLMemVariant;
var std,sigma,x: Extended;
begin
  case Operator of
    doCOUNT,
    doCOUNTALL:
      Value.AsInteger := Count;
    doAVG:
      begin
        //   = AvgSum / Count
        if (Count = 0) then
         Value.Clear(bftExtended)
        else
        begin
          Value.Assign(AvgSum);
          AvgSum.AsInteger := Count;
          Value.Division(AvgSum);
        end;
      end;
    doSTDDEV:
      begin
        // S = SQRT(1 / (n-1) * (SUM(SQR(x-xm)))
        if (Count = 0) then
         Value.Clear(bftDouble)
        else
        if (Count = 1) then
         Value.AsDouble := 0
        else
        begin
          FTempTable.First;
          sigma := 0;
          xm := xm / Count;
          while not FTempTable.Eof do
          begin
            x := FTempTable.Fields[0].AsFloat;
            sigma := sigma + (x-xm)* (x-xm);
            FTempTable.Next;
          end;
          std := Sqrt(1 / (Count-1) * sigma);
          Value.AsDouble := std;
        end;
      end;
  end;
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeAggregated.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := aftUnknown;
  case Operator of
    doCOUNTALL,
    doCOUNT:
      Result := aftInteger;
    doMIN,
    doMAX:
      if Children.Count <> 0 then
             Result := TSQLMemExprNode(Children[0]).getDataType;
    doSUM:
      if Children.Count <> 0 then
       begin
        Result := TSQLMemExprNode(Children[0]).getDataType;
        if not (Result in [aftSingle, aftDouble, aftExtended,
                            aftCurrency] ) then
          Result := aftLargeint;
       end;
    doAVG,doSTDDEV:
      Result := aftDouble;
    doGROUP_CONCAT:
      if Children.Count <> 0 then
       begin
        Result := TSQLMemExprNode(Children[0]).getDataType;
        if (not IsStringFieldType(Result)) then
          Result := aftWideChar; // WideChar by default
       end;
  end;
end;//GetDataType


//------------------------------------------------------------------------------
// is expression contains aggregated function
//------------------------------------------------------------------------------
function TSQLMemExprNodeAggregated.isAggregated: Boolean;
begin
  Result := True;
end;//isAggregated


//------------------------------------------------------------------------------
// is expression contains aggregated function COUNT(*)
//------------------------------------------------------------------------------
function TSQLMemExprNodeAggregated.IsCountAll: Boolean;
begin
  Result := (Operator = doCOUNTALL);
end; // IsCountAll


//------------------------------------------------------------------------------
// Init for aggregated functions
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeAggregated.Init;
var FieldDef: TSQLMemAdvFieldDef;
    TmpVal:   TSQLMemVariant;
begin
  Count := 0;
  Value.SetNull;
  if Operator = doAVG then
    AvgSum.SetNull;
  if (Operator = doGROUP_CONCAT) then
   if ((FGroupConcatSeparatorAnsi = '') and (FGroupConcatSeparatorWide = '')) then
    begin
      FGroupConcatSeparatorWide := WideString(SQLMemDefaultGroupConcatSeparator);
      FGroupConcatSeparatorAnsi := SQLMemDefaultGroupConcatSeparator;
      if (Children.Count > 1) then
       begin
        TmpVal := TSQLMemExprNode(Children[1]).GetDataValue;
        if (TmpVal <> nil) then
         begin
           FGroupConcatSeparatorWide := TmpVal.AsWideString;
           FGroupConcatSeparatorAnsi := TmpVal.AsString;
         end;
      end;
    end;
  if (distinct) or (Operator = doGROUP_CONCAT) or (Operator = doSTDDEV) then
   begin
    if (Children.Count <= 0) then
     raise ESQLMemException.Create(11338,ErrorLNoChildren);
    if (FTempTable <> nil) then
     FTempTable.Free;
    FTempTable := TSQLMemTable.Create(nil);
    TSQLMemTable(FTempTable).Temporary := True;
    repeat
      TSQLMemTable(FTempTable).TableName := GetTemporaryName(SQLMemTemporaryTableName);
    until (not TSQLMemTable(FTempTable).Exists);
    TSQLMemTable(FTempTable).FieldDefs.Clear;
    TSQLMemTable(FTempTable).AdvFieldDefs.Clear;
    TSQLMemTable(FTempTable).IndexDefs.Clear;
    TSQLMemTable(FTempTable).AdvIndexDefs.Clear;
    FieldDef := TSQLMemTable(FTempTable).AdvFieldDefs.AddFieldDef;
    FieldDef.Name := SQLMemExpressionFieldName;
    if (Operator = doSTDDEV) then
    begin
      FieldDef.DataType := aftDouble;
      FieldDef.Size := 0;
      xm := 0;
    end
    else
    begin
      FieldDef.DataType := TSQLMemExprNode(Children[0]).GetDataType;
      FieldDef.Size := TSQLMemExprNode(Children[0]).GetDataSize;
    end;
    if (desc) then
     TSQLMemTable(FTempTable).IndexDefs.Add(SQLMemDefaultIndexName,FieldDef.Name,[ixDescending])
    else
     TSQLMemTable(FTempTable).IndexDefs.Add(SQLMemDefaultIndexName,FieldDef.Name,[]);
    TSQLMemTable(FTempTable).CreateTable;
    TSQLMemTable(FTempTable).IndexName := SQLMemDefaultIndexName;
    TSQLMemTable(FTempTable).Open;
   end;
end;//Init


//------------------------------------------------------------------------------
// Accumulate for group functions
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeAggregated.Accumulate(Increment: Integer);
var
  TmpVal:  TSQLMemVariant;
  bOK:     Boolean;

  function IsDistinctHaveNewValue: Boolean;
  begin
    if (TSQLMemTable(FTempTable).RecordCount = 0) then
     Result := True
    else
     begin
      TSQLMemTable(FTempTable).SetKey;
      TSQLMemTable(FTempTable).SetFieldValue(TmpVal,0,True);
      Result := (not TSQLMemTable(FTempTable).GotoKey);
     end;
  end; // IsDistinctHaveNewValue

  procedure InsertNewDistinctValue;
  begin
    TSQLMemTable(FTempTable).Insert;
    TSQLMemTable(FTempTable).SetFieldValue(TmpVal,0,True);
    TSQLMemTable(FTempTable).Post;
  end; // InsertNewDistinctValue

  procedure DoGroupConcat;
  begin
    if (distinct) then
     begin
      if (IsDistinctHaveNewValue) then
       begin
        InsertNewDistinctValue;
       end;
     end
    else
     InsertNewDistinctValue;
    FTempTable.First;
    Value.Clear(TmpVal.DataType);
    while (not FTempTable.Eof) do
     begin
       TSQLMemdataset(FTempTable).GetFieldValue(TmpVal,0,True,False);
       if (not Value.IsNull) then
        begin
         // add separator
         if (Value.IsWideStringDataType) then
          Value.AsWideString := Value.AsWideString
            + FGroupConcatSeparatorWide + TmpVal.AsWideString
         else
          Value.AsString := Value.AsString
            + FGroupConcatSeparatorAnsi + TmpVal.AsString;
        end
       else
        begin
         Value.Assign(TmpVal,True);
        end; // first value
       FTempTable.Next;
     end;
  end; // DoGroupConcat


begin
  TmpVal := TSQLMemVariant.Create;
  try
    if Children.Count > 0 then
     begin
      // fixed in v.5.01: SUM(arg1-arg2) must ignore rows with NULL values
      if (not TSQLMemExprNode(Children[0]).HasNullValues) then
       TmpVal.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
      if (TmpVal.IsNull) then
       TmpVal.DataType := AdvancedFieldTypeToBaseFieldType(TSQLMemExprNode(Children[0]).GetDataType);
//       TmpVal.
     end;
    case Operator of
      doMIN:
        begin
         if (Value.IsNull) then
           Value.Assign(TmpVal)
         else
           if (not TmpVal.IsNull) then
             if (TmpVal.Compare(Value,False,FCaseInsensitive,False) = cmprLower) then
               Value.Assign(TmpVal);
        end;
      doMAX:
        begin
         if (Value.IsNull) then
           Value.Assign(TmpVal)
         else
           if (not TmpVal.IsNull) then
             if (TmpVal.Compare(Value,False,FCaseInsensitive,False) = cmprGreater) then
               Value.Assign(TmpVal);
        end;
      doCOUNTALL:
        begin
          Inc(count,Increment);
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
                Inc(count,Increment);
               end;
             end
            else
              Inc(count,Increment);
           end;
        end;
      doSUM:
        begin
          // If not numeric type (string for example) - raise
          if (not TmpVal.IsNull) then
           if (not TmpVal.IsNumericDataType) then
            raise ESQLMemException.Create(30132, ErrorGNotNumericDataType, ['SUM']);
          // if value is null and new value is null add 0
          if (TmpVal.IsNull) then
           begin
            // first value
            if (Value.IsNull) then
             begin
              if (TmpVal.IsIntegerDataType) then
               begin
                Value.Clear(bftSignedInt64);
                Value.AsInt64 := 0;
               end
              else
               begin
                Value.Clear(bftExtended);
                Value.AsExtended := 0;
               end;
             end;
           end
          else
           begin
            if (distinct) then
             begin
              if (IsDistinctHaveNewValue) then
               begin
                InsertNewDistinctValue;
                Value.Add(TmpVal);
               end;
             end
            else
             Value.Add(TmpVal);
           end;
        end;
      doAVG:
        begin
          // If not numeric type (string for example) - raise
          if (not TmpVal.IsNull) then
           if (not TmpVal.IsNumericDataType) then
            raise ESQLMemException.Create(30133, ErrorGNotNumericDataType, ['AVG']);
          // if value not null
          if (not TmpVal.IsNull) then
            if (distinct) then
             begin
              if (IsDistinctHaveNewValue) then
               begin
                InsertNewDistinctValue;
                AvgSum.Add(TmpVal);
                inc(count,Increment);
               end;
             end
            else
             begin
              AvgSum.Add(TmpVal);
              inc(count,Increment);
             end;
        end; // AVIG
      doGROUP_CONCAT:
        begin
          if (not TmpVal.IsNull) then
           begin
            if (distinct) then
             begin
              if (IsDistinctHaveNewValue) then
               begin
                InsertNewDistinctValue;
                DoGroupConcat;
               end;
             end
            else
              DoGroupConcat;
           end;
        end;
      doSTDDEV:
        begin
          if (not TmpVal.IsNull) then
           begin
            if (tmpVal.DataType <> bftDouble) then
             tmpVal.Cast(bftDouble);
            bOK := true;
            if (distinct) then
             bOK := IsDistinctHaveNewValue;
            if (bOK) then
            begin
              InsertNewDistinctValue;
              xm := xm + tmpVal.AsDouble;
              Inc(Count);
            end;
           end;
        end
      else
        raise ESQLMemException.Create(30134, ErrorGUnknownOperator,
                                   [GetOperatorName(Operator)]);
    end;
  finally
    TmpVal.Free;
  end;
end;//Accumulate


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeAggregated.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeAggregated.Create(aParentExpr);
  TSQLMemExprNodeAggregated(Result).AvgSum := TSQLMemVariant.Create;
  TSQLMemExprNodeAggregated(Result).FTempTable := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeAggregated.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  count := TSQLMemExprNodeAggregated(Source).count;
  distinct := TSQLMemExprNodeAggregated(Source).distinct;
  desc := TSQLMemExprNodeAggregated(Source).desc;
  AvgSum.Assign(TSQLMemExprNodeAggregated(Source).AvgSum,True);
  FGroupConcatSeparatorAnsi := TSQLMemExprNodeAggregated(Source).FGroupConcatSeparatorAnsi;
  FGroupConcatSeparatorWide := TSQLMemExprNodeAggregated(Source).FGroupConcatSeparatorWide;
  if (FTempTable <> nil) then
   FreeAndNil(FTempTable);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeCast
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeCast.Create(
                                    aParentExpr:  TSQLMemExpression;
                                    Node:         TSQLMemExprNode;
                                    CastType:     TSQLMemAdvancedFieldType;
                                    SizeNode:     TSQLMemExprNode
                                   );
begin
  if (SizeNode = nil) then
   inherited Create(aParentExpr, doCAST, Node)
  else
   inherited Create(aParentExpr, doCAST, Node, SizeNode);
  FCastType := CastType;
end;//Create


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeCast.GetDataValue: TSQLMemVariant;
begin
  if (Children.Count >= 2) then
   Value.MaxStrLen := TSQLMemExprNode(Children[1]).GetDataValue.AsInteger
  else
   Value.MaxStrLen := 0;
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.Cast(AdvancedFieldTypeToBaseFieldType(FCastType));
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeCast.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := FCastType;
end;//GetDataType


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeCast.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeCast.Create(aParentExpr);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeCast.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FCastType := TSQLMemExprNodeCast(Source).FCastType;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeDateFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// To Date
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeDateFunction.ToDate;
var
  TmpVal: TSQLMemVariant;
  dt: TDateTime;
begin
  Value.SetNull(bftDateTime);
  TmpVal := TSQLMemVariant.Create;
  try
    TmpVal.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    if (not TmpVal.IsNull) then
      begin
        dt := DateFormater.ToDate(TmpVal.AsWideString);
        Value.AsTDateTime := dt;
        if (dt <> 0) then
          if (trunc(dt) = 0 ) then
            Value.Cast(bftTime);
        if (frac(dt) = 0 ) then
           Value.Cast(bftDate);
      end;
  finally
    TmpVal.Free;
  end;
end;//ToDate


//------------------------------------------------------------------------------
// To AnsiString
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeDateFunction.TOString;
var
  TmpVal: TSQLMemVariant;
begin
  Value.SetNull(bftVarchar);
  TmpVal := TSQLMemVariant.Create;
  try
    TmpVal.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    if (not TmpVal.IsNull) then
     begin
      Value.AsWideString := DateFormater.TOString(TmpVal.AsTDateTime);
      Value.ConvertWideStringToAnsiStringIfNotUnicode;
     end;
  finally
    TmpVal.Free;
  end;
end;//TOString


//------------------------------------------------------------------------------
// extract part from date or time value
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeDateFunction.Extract;
var
    DataValue:  TSQLMemVariant;
    dt:         TDateTime;
    y,m,d,q:    Word;
    h,mm,ss,zz: Word;
begin
  if (Children.Count <=0) then
   raise ESQLMemException.Create(11606,ErrorLArgumentExpectedInSQLFunction,[GetOperatorName(Operator)]);
  DataValue := TSQLMemVariant.Create;
  try
    DataValue.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    if (DataValue.IsNull) or (DataValue.pData = nil) then
     begin
      Value.SetNull(AdvancedFieldTypeToBaseFieldType(GetDataType));
      Exit;
     end;
    dt := DataValue.AsTDateTime;
    if (Operator <> doDAYOFWEEK) and (Operator <> doWEEKDAY) and
       (Operator <> doDAYNAME) then
     begin
      if (Operator <= doMONTHNAME) then
       DecodeDate(dt,y,m,d)
      else
       DecodeTime(dt,h,mm,ss,zz);
     end;
    case Operator of
      doYEAR:       Value.AsWord := y;
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
                     Value.AsWord := q;
                    end;
      doMONTH:      Value.AsWord := m;
      doDAY:        Value.AsWord := d;
      doWEEK:       Value.AsWord := Word(aaWeek(dt));
      doISOWEEK:    Value.AsWord := Word(aaISOWeek(dt));
      doWEEKDAY:    Value.AsWord := Word(aaDayOfWeek(dt));
      doDAYOFWEEK:  Value.AsWord := Word(aaDayOfTheWeek(dt));
      doDAYOFYEAR:  Value.AsWord := Word(aaDayOfYear(dt));
      doDAYNAME:    Value.AsWideString := DayNames[aaDayOfWeek(dt)];
      doMONTHNAME:  Value.AsWideString := MonthNames[m];
      doHOUR:       Value.AsWord := h;
      doMINUTE:     Value.AsWord := mm;
      doSECOND:     Value.AsWord := ss;
      doMSECOND:    Value.AsWord := zz;
    end;
  finally
    DataValue.Free;
  end;
end; // Extract


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeDateFunction.Create(
                                             aParentExpr:  TSQLMemExpression;
                                             Op:           TSQLMemDataOperator;
                                             Node:         TSQLMemExprNode;
                                             FormatStr:    WideString
                                           );
begin
  inherited Create(aParentExpr, op, Node);
  DateFormater := TDateFormater.Create(FormatStr);
end;


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeDateFunction.Destroy;
begin
  DateFormater.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateFunction.GetDataValue: TSQLMemVariant;
begin
  case Operator of
    doSYSDATE:        Value.AsTDateTime := now;
    doCURRENT_DATE:   Value.AsTDate := now;
    doCURRENT_TIME:   Value.AsTTime := now;
    doTODATE:         ToDate;
    doTOString:       TOString;
    doYEAR,
    doQUARTER,
    doMONTH,
    doDAY,
    doWEEK,
    doISOWEEK,
    doWEEKDAY,
    doDAYOFWEEK,
    doDAYOFYEAR,
    doDAYNAME,
    doMONTHNAME,
    doHOUR,
    doMINUTE,
    doSECOND,
    doMSECOND:        Extract;
   else raise ESQLMemException.Create(30130, ErrorGUnknownOperator,
                                   [GetOperatorName(Operator)]);
  end;
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  case Operator of
    doSYSDATE,
    doCURRENT_DATE,
    doCURRENT_TIME,
    doTODATE:
                    Result := aftDateTime;
    doTOString:
                    Result := aftString;
    doYEAR:         Result := aftWord;
    doQUARTER:      Result := aftWord;
    doMONTH:        Result := aftWord;
    doDAY:          Result := aftWord;
    doISOWEEK:      Result := aftWord;
    doWEEK:         Result := aftWord;
    doWEEKDAY:      Result := aftWord;
    doDAYOFYEAR:    Result := aftWord;
    doDAYOFWEEK:    Result := aftWord;
    doDAYNAME:      Result := aftString;
    doMONTHNAME:    Result := aftString;
    doHOUR:         Result := aftWord;
    doMINUTE:       Result := aftWord;
    doSECOND:       Result := aftWord;
    doMSECOND:      Result := aftWord;
    else
                    raise ESQLMemException.Create(30287, ErrorGUnknownOperator,
                                               [GetOperatorName(Operator)]);
  end;
end;//GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateFunction.GetDataSize: Integer;
begin
  case Operator of
    doTOString:   Result := DateFormater.GetStringMaxSize;
    doDAYNAME:    Result := 9; // Wednesday
    doMONTHNAME:  Result := 9; // September
  else
    Result := 0;
  end;
end;//GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeDateFunction.Create(aParentExpr);
  TSQLMemExprNodeDateFunction(Result).DateFormater := TDateFormater.Create('');
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeDateFunction.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  DateFormater.Assign(TSQLMemExprNodeDateFunction(Source).DateFormater);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeDateAddFunction - DATEADD
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeDateAddFunction.Create(
                     aParentExpr:           TSQLMemExpression;
                     DatePart:              TSQLMemDatePart;
                     Number:                TSQLMemExprNode;
                     Date:                  TSQLMemExprNode
                   );
begin
  inherited Create(aParentExpr,doUNDEFINED);
  FDatePart := DatePart;
  FNumber := Number;
  FDate := Date;
  if (FDate <> nil) then
    Children.Add(FDate);
  if (FNumber <> nil) then
    Children.Add(FNumber);
end; // Create


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateAddFunction.GetDataValue: TSQLMemVariant;
begin
  if (FDate = nil) then
   raise ESQLMemException.Create(12438,ErrorLNilPointer);
  Value.Assign(FDate.GetDataValue,True,False);
  Value.DateAdd(FDatePart,FNumber.GetDataValue.AsInteger);
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateAddFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  if (FDate = nil) then
   raise ESQLMemException.Create(12439,ErrorLNilPointer);
  Result := FDate.GetDataType;
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateAddFunction.GetDataSize: Integer;
begin
  Result := 0;
end; // GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateAddFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeDateAddFunction.Create(aParentExpr,dpUNDEFINED,nil,nil);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeDateAddFunction.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FDatePart := TSQLMemExprNodeDateAddFunction(Source).FDatePart;
  FNumber := TSQLMemExprNodeDateAddFunction(Source).FNumber;
  if (FDate <> nil) then
   FDate.Free;
  if (FNumber <> nil) then
   FNumber.Free;
  Children.Clear;
  FDate := TSQLMemExprNodeDateAddFunction(Source).FDate.MakeCopy(LParentExpr);
  if (FDate <> nil) then
   Children.Add(FDate);
  FNumber := TSQLMemExprNodeDateAddFunction(Source).FDate.MakeCopy(LParentExpr);
  if (FNumber <> nil) then
   Children.Add(FNumber);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeDateDiffFunction - DATEDIFF
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeDateDiffFunction.Create(
                                             aParentExpr:           TSQLMemExpression;
                                             DatePart:              TSQLMemDatePart;
                                             StartDate,
                                             EndDate:               TSQLMemExprNode
                                              );
begin
  inherited Create(aParentExpr,doUNDEFINED);
  FDatePart := DatePart;
  FStartDate := StartDate;
  FEndDate := EndDate;
  if (FStartDate <> nil) then
    Children.Add(FStartDate);
  if (FEndDate <> nil) then
    Children.Add(FEndDate);
end; // Create


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateDiffFunction.GetDataValue: TSQLMemVariant;
begin
  if (FStartDate = nil) then
    raise ESQLMemException.Create(12449,ErrorLNilPointer);
  if (FEndDate = nil) then
    raise ESQLMemException.Create(12450,ErrorLNilPointer);
  Value.DateDiff(FDatePart,FStartDate.GetDataValue,FEndDate.GetDataValue);
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateDiffFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := aftInteger;
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateDiffFunction.GetDataSize: Integer;
begin
  Result := 0;
end; // GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeDateDiffFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeDateDiffFunction.Create(aParentExpr,FDatePart,nil,nil);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeDateDiffFunction.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FDatePart := TSQLMemExprNodeDateDiffFunction(Source).FDatePart;
  Children.Clear;
  if (FStartDate <> nil) then
    FStartDate.Free;
  if (FEndDate <> nil) then
    FEndDate.Free;
  FStartDate := TSQLMemExprNodeDateDiffFunction(Source).FStartDate.MakeCopy(LParentExpr);
  FEndDate := TSQLMemExprNodeDateDiffFunction(Source).FEndDate.MakeCopy(LParentExpr);
  if (FStartDate <> nil) then
    Children.Add(FStartDate);
  if (FEndDate <> nil) then
    Children.Add(FEndDate);
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeBLOBFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeBLOBFunction.Create(
                                             aParentExpr:           TSQLMemExpression;
                                             Op:                    TSQLMemDataOperator;
                                             const BLOBValue:       AnsiString;
                                             const BLOBValueFormat: TSQLMemBLOBValueFormat
                                            );
var buffer: PAnsiChar;
begin
  inherited Create(aParentExpr, op, False, False);
  Value.SetNull;
  try
    case BLOBValueFormat of
     bvfMIME64: buffer := SQLMemMIME64ToBinary(BLOBValue);
     bvfHEX: buffer := SQLMemHEXToBinary(BLOBValue);
    end;
  except
    raise ESQLMemException.Create(11344,ErrorLCannotConvertBLOBValue,[BLOBValue,Integer(BLOBValueFormat)]);
  end;
  // this dat is not linked with any record,
  // it bust be freed on destroying TSQLMemVariant object
  Value.SetData(buffer,MemoryManager.GetMemoryBufferSize(buffer),bftBLOB,False,True);
end; // Create


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeBLOBFunction.GetDataValue: TSQLMemVariant;
begin
  case Operator of
    doTOBLOB: ;
   else raise ESQLMemException.Create(11343, ErrorGUnknownOperator,
                                   [GetOperatorName(Operator)]);
  end;
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeBLOBFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := aftBLOB;
end;//GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeBLOBFunction.GetDataSize: Integer;
begin
  Result := 0;
end;//GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeBLOBFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeBLOBFunction.Create(aParentExpr);
end; // Create




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeConst
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeConst.GetDataValue: TSQLMemVariant;
begin
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// set new value - used in reopening parametrized queries for setting new values
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeConst.SetDataValue(NewValue: TSQLMemVariant; CopyFlag: Boolean);
begin
  Value.Assign(NewValue,CopyFlag);
end; // SetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeConst.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := BaseFieldTypeToAdvancedFieldType(Value.DataType);
end;//GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeConst.GetDataSize: Integer;
begin
  Result := 0;
  if (not Value.IsNull) then
    if (Value.IsStringDataType) then
      begin
        Result := Value.DataSize;
        // skip last zeros
        Dec(Result);
        if Value.IsWideStringDataType then
          Dec(Result);
      end;
end;//GetDataSize


//------------------------------------------------------------------------------
// can be used by the AO?
//------------------------------------------------------------------------------
function TSQLMemExprNodeConst.CanBeAssigned(AO: TSQLMemAO): Boolean;
begin
  Result := True;
{$IFDEF DEBUG_CAN_BE_ASSIGNED}
aaWriteToLog('< TSQLMemExprNodeConst.CanBeAssigned: '+GetName+#13#10+'AO = '+AO.GetName+#13#10+'Result = '+BoolToStr(Result,True)+#13#10+GetValue(False));
{$ENDIF}
end;//CanBeAssigned


//------------------------------------------------------------------------------
// extract all TSQLMemExprNodeConst objects from FRootExprNode and all its children
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeConst.ExtractAllParameterNodes(NodeList: TSQLMemList);
begin
  if (FIsParameter) then
   NodeList.Add(Self);
end; // ExtractAllParameterNodes


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeConst.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeConst.Create(aParentExpr);
end; // CreateCopy




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeBoolean
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.Like: Boolean;
var
  Str, Pattern:   TSQLMemVariant;
  CommonType:     TSQLMemBaseFieldType;
{$IFDEF EXPR_PARSING_1}
  Escape:         TSQLMemVariant;
{$ENDIF}
//ws: WideString;
//i: Integer;
begin
  Result := False;
  Str := TSQLMemVariant.Create(bftLogical);
  Pattern := TSQLMemVariant.Create(bftLogical);
{$IFDEF EXPR_PARSING_1}
  if (Children.Count > 2) then
   Escape := TSQLMemVariant.Create(bftChar)
  else
   Escape := nil;
{$ENDIF}
  try
    Str.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    Pattern.Assign(TSQLMemExprNode(Children[1]).GetDataValue, False);
    // If Nulls
    if (Pattern.IsNull or Str.IsNull) then
      begin
        Exit;
      end;
{$IFDEF EXPR_PARSING_1}
    if (Escape <> nil) then
     Escape.Assign(TSQLMemExprNode(Children[2]).GetDataValue, False);
{$ENDIF}
    // Get Common Data Type
    CommonType := GetCommonDataType(Str.DataType, Pattern.DataType);
    // Check for strings
    if (not IsStringFieldType(CommonType)) then
     raise ESQLMemException.Create(30120, ErrorGNotStringArgument, ['LIKE']);

//aaWriteToLog('str.pdata[0] = '+IntToHex(PByte(PAnsiChar(Str.pData)+0)^,2));
//aaWriteToLog('pattern.pdata[0] = '+IntToHex(PByte(PAnsiChar(Pattern.pData)+0)^,2));
//ws := str.AsWideString;
//for i := 1 to Length(ws) do
//aaWriteToLog('str.AsWideString['+IntToStr(i)+'] = '+IntToHex(PByte(PAnsiChar(@ws[1])+i)^,2));

{ TODO : add escape support }
    // Do Like
    if IsWideStringFieldType(CommonType) then
      Result := IsWideStrMatchPattern(
                                            PWideChar(Str.AsWideString),
                                            PWideChar(Pattern.AsWideString),
                                            FCaseInsensitive
                                          )
    else
      Result := IsStrMatchPattern(
                                            PAnsiChar(Str.AsString),
                                            PAnsiChar(Pattern.AsString),
                                            FCaseInsensitive
                                          );

  finally
//if (Value.IsNull) then
//aaWriteToLog('result = NULL')
//else
//aaWriteToLog('result = '+BoolToStr(Value.AsBoolean,True));
    Str.Free;
    Pattern.Free;
{$IFDEF EXPR_PARSING_1}
    if (Escape <> nil) then
     FreeAndNil(Escape);
{$ENDIF}
  end;
end;//Like


//------------------------------------------------------------------------------
// process IN (...)
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.bIn: Boolean;
var
  Val1, Val2: TSQLMemVariant;
  //CommonType: TSQLMemBaseFieldType;
  i: Integer;
begin
  Val1 := TSQLMemVariant.Create;
  Val2 := TSQLMemVariant.Create;
  try
    Val1.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    Result := False;
    // Val is null ?
    if (Val1.IsNull) then
      Value.SetNull(bftLogical)
    else
      for i:=1 to Children.Count-1 do
        begin
          Val2.Assign(TSQLMemExprNode(Children[i]).GetDataValue, False);
          if (Val1.Compare(Val2,False,False,False) = cmprEqual) then
            begin
              Result := true;
              Break;
            end;
        end;
  finally
    Val1.Free;
    Val2.Free;
  end;
end;//bIn


//------------------------------------------------------------------------------
// process A BETWEEN B AND C
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.Between: Boolean;
var
  ValCur, ValMin, ValMax: TSQLMemVariant;
begin
  ValCur := TSQLMemVariant.Create;
  ValMin := TSQLMemVariant.Create;
  ValMax := TSQLMemVariant.Create;
  try
    ValCur.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    ValMin.Assign(TSQLMemExprNode(Children[1]).GetDataValue, False);
    ValMax.Assign(TSQLMemExprNode(Children[2]).GetDataValue, False);
    // Nulls ?
    Result := False;
    if (ValCur.IsNull or ValMin.IsNull or ValMax.IsNull) then
      Exit;
    Result := False;
    if ValCur.Compare(ValMin,False,FCaseInsensitive,False) in [cmprEqual, cmprGreater] then
      if ValCur.Compare(ValMax,False,FCaseInsensitive,False) in [cmprEqual, cmprLower] then
         Result := True;
  finally
    ValCur.Free;
    ValMin.Free;
    ValMax.Free;
  end;
end;//Between


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeBoolean.Create(
                                       aParentExpr:     TSQLMemExpression;
                                       CaseInsensitive: Boolean;
                                       PartialKey:      Boolean
                                      );
begin
  inherited Create(aParentExpr,CaseInsensitive,PartialKey);
  TempVal := TSQLMemVariant.Create(bftLogical);
  FIgnoreNodes := nil;
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeBoolean.Create(
                                       aParentExpr:     TSQLMemExpression;
                                       Op:              TSQLMemDataOperator;
                                       CaseInsensitive: Boolean;
                                       PartialKey:      Boolean
                                      );
begin
  Create(aParentExpr, CaseInsensitive, PartialKey);
  Operator := Op;
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeBoolean.Create(
                                       aParentExpr:     TSQLMemExpression;
                                       Op:              TSQLMemDataOperator;
                                       Node:            TSQLMemExprNode;
                                       CaseInsensitive: Boolean;
                                       PartialKey:      Boolean
                                      );
begin
  Create(aParentExpr, Op, CaseInsensitive, PartialKey);
  Children.Add(Node);
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeBoolean.Create(
                                       aParentExpr:     TSQLMemExpression;
                                       Op:              TSQLMemDataOperator;
                                       Node1, Node2:    TSQLMemExprNode;
                                       CaseInsensitive: Boolean;
                                       PartialKey:      Boolean
                                      );
begin
  Create(aParentExpr, Op, Node1, CaseInsensitive, PartialKey);
  Children.Add(Node2);
end;//Create


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeBoolean.Create(
                                       aParentExpr:         TSQLMemExpression;
                                       Op:                  TSQLMemDataOperator;
                                       Node1, Node2, Node3: TSQLMemExprNode;
                                       CaseInsensitive:     Boolean = true;
                                       PartialKey:          Boolean = false
                                      );
begin
  Create(aParentExpr, Op, Node1, Node2, CaseInsensitive, PartialKey);
  Children.Add(Node3);
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeBoolean.Destroy;
begin
  TempVal.Free;
  if (FIgnoreNodes <> nil) then
    FreeAndNil(FIgnoreNodes);
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.GetDataValue: TSQLMemVariant;
var  i: Integer;
begin
   Value.SetNull(bftLogical);
   case Operator of
    doNOT: // NOT
      begin
        TempVal.Assign(TSQLMemExprNode(Children[0]).GetDataValue, false);
        // NOT <null> = NULL
        if not TempVal.IsNull then
          Value.AsBoolean := not TempVal.AsBoolean;
      end;
    doAND: // AND
      begin
        // possible result is TRUE
        Value.AsBoolean := True;
        // Loop for all childs
        for i:=0 to Children.Count-1 do
         begin
          TempVal.Assign(TSQLMemExprNode(Children[i]).GetDataValue, false);

          // x AND NULL = NULL (and check later)
          if TempVal.IsNull then
           begin
            Value.SetNull(bftLogical);
            //break;
            continue;
           end;

          // x AND FALSE = FALSE
          if (not TempVal.AsBoolean) then
           begin
            Value.AsBoolean := False;
            break;
           end;
         end;//for
      end;
    doOR: // OR
      begin
        // possible result is FALSE
        Value.AsBoolean := False;
        // Loop for all childs
        for i:=0 to Children.Count-1 do
         begin
          TempVal.Assign(TSQLMemExprNode(Children[i]).GetDataValue, false);

          // False OR NULL = NULL (and check later)
          if TempVal.IsNull then
           begin
            Value.SetNull(bftLogical);
            continue;
           end;

          // x OR TRUE=TRUE;
          if (TempVal.AsBoolean) then
           begin
            Value.AsBoolean := True;
            break;
           end;
         end;
      end;
    doISNULL:  // IS NULL
      begin
        Value.AsBoolean := TSQLMemExprNode(Children[0]).GetDataValue.IsNull;
      end;
    doISNOTNULL: // IS NOT NULL
      begin
        Value.AsBoolean := not TSQLMemExprNode(Children[0]).GetDataValue.IsNull;
      end;
    doLIKE:
      begin
        Value.AsBoolean := Like;
      end;
    doNOTLIKE:
      begin
        Value.AsBoolean := not Like;
      end;
    doIN:
      begin
        Value.AsBoolean := bIn;
      end;
    doNOTIN:
      begin
        Value.AsBoolean := not bIn;
      end;
    doBETWEEN:
      begin
        Value.AsBoolean := Between;
      end;
    doNOTBETWEEN:
      begin
        Value.AsBoolean := not Between;
      end;
    else
      raise ESQLMemException.Create(30116, ErrorGUnknownOperator,
                                                   [GetOperatorName(Operator)]);
   end;
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Value as Boolean
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.GetBooleanValue: Boolean;
var i:      Integer;
    Node:   TSQLMemExprNode;
begin
   case Operator of
    doNOT: // NOT
      begin
        Result := not TSQLMemExprNode(Children[0]).GetBooleanValue;
      end;
    doAND: // AND
      begin
        // possible result is TRUE
        Result := True;
        // Loop for all childs
        for i:=0 to Children.Count-1 do
         begin
          Node := TSQLMemExprNode(Children[i]);
          if (FIgnoreNodes <> nil) then
           if (FIgnoreNodes.IndexOf(Node) > 0) then
            continue;
          Result := Node.GetBooleanValue;
          if (not Result) then
            break;
         end;//for
      end;
    doOR: // OR
      begin
        // possible result is FALSE
        Result := False;
        // Loop for all childs
        for i:=0 to Children.Count-1 do
         begin
          Result := TSQLMemExprNode(Children[i]).GetBooleanValue;
          if (Result) then
            break;
         end;
      end;
    doISNULL:  // IS NULL
      begin
        Result := TSQLMemExprNode(Children[0]).GetDataValue.IsNull;
      end;
    doISNOTNULL: // IS NOT NULL
      begin
        Result := not TSQLMemExprNode(Children[0]).GetDataValue.IsNull;
      end;
    doLIKE:
      begin
        Result := Like;
      end;
    doNOTLIKE:
      begin
        Result := not Like;
      end;
    doIN:
      begin
        Result := bIn;
      end;
    doNOTIN:
      begin
        Result := not bIn;
      end;
    doBETWEEN:
      begin
        Result := Between;
      end;
    doNOTBETWEEN:
      begin
        Result := not Between;
      end;
    else
      raise ESQLMemException.Create(30116, ErrorGUnknownOperator,
                                                   [GetOperatorName(Operator)]);
   end;
end; // GetBooleanValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := aftBoolean;
end; // GetDataType


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeBoolean.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeBoolean.Create(aParentExpr);
  TSQLMemExprNodeBoolean(Result).TempVal := TSQLMemVariant.Create(bftLogical);
end; // CreateCopy




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeIsNullFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create with replacement
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeIsNullFunction.Create(
                                               aParentExpr:   TSQLMemExpression;
                                               Op:            TSQLMemDataOperator;
                                               Node1, Node2:  TSQLMemExprNode
                                             );
begin
  inherited Create(aParentExpr,op,Node1,Node2);
  FType1 := aftUnknown;
  FType2 := aftUnknown;
end; // Create


//------------------------------------------------------------------------------
// get data value
//------------------------------------------------------------------------------
function TSQLMemExprNodeIsNullFunction.GetDataValue: TSQLMemVariant;
begin
  if (Children.Count = 1) then
   begin
    // IsNull without replacement - returns true/false
    Value.AsBoolean := TSQLMemExprNode(Children[0]).GetDataValue.IsNull;
   end
  else
   if (Children.Count = 2) then
    begin
     // IsNull with replacement
     Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue,True);
     if (Value.IsNull) then
      begin
       if (FType1 = aftUnknown) then
        FType1 := TSQLMemExprNode(Children[0]).GetDataType;
       if (FType2 = aftUnknown) then
        FType2 := TSQLMemExprNode(Children[1]).GetDataType;
       if (FType1 <> FType2) then
        if  (not IsConvertableFieldType(FType1)) or (not IsConvertableFieldType(FType2)) then
        raise ESQLMemException.Create(11600,ErrorLTypesMismatchesInSQLFunction,
          [GetOperatorName(doISNULLFUNCTION),Integer(FType1),Integer(FType2)]);
       Value.Assign(TSQLMemExprNode(Children[1]).GetDataValue,False);
       Value.Cast(AdvancedFieldTypeToBaseFieldType(FType1));
      end;
    end;
 Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNodeIsNullFunction.GetDataSize: Integer;
var size: Integer;
begin
  Result := 0;
  if (Children.Count = 2) then
    begin
     // IsNull with replacement
     Result := TSQLMemExprNode(Children[0]).GetDataSize;
     Size := TSQLMemExprNode(Children[1]).GetDataSize;
     if (Size > Result) then
      Result := Size;
    end;
end; // GetDataSize


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeIsNullFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := aftUnknown;
  if (Children.Count = 1) then
   begin
    // IsNull without replacement - returns true/false
    Result := aftBoolean;
   end
  else
   if (Children.Count = 2) then
    begin
     // IsNull with replacement
     Result := inherited GetDataType;
    end;
end; // GetDataType


//------------------------------------------------------------------------------
// must return false
//------------------------------------------------------------------------------
function TSQLMemExprNodeIsNullFunction.HasNullValues: Boolean;
begin
  if (Children.Count = 1) then
   begin
    // IsNull without replacement - returns true/false
    Result := False;
   end
  else
  if (Children.Count = 2) then
   begin
    // IsNull with replacement (if result value not NULL)
    Result := TSQLMemExprNode(Children.Items[1]).HasNullValues;
   end;
end; // HasNullValues


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeIsNullFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeIsNullFunction.Create(aParentExpr);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeIsNullFunction.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FType1 := TSQLMemExprNodeIsNullFunction(Source).FType1;
  FType2 := TSQLMemExprNodeIsNullFunction(Source).FType2;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeNullIfFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create with replacement
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeNullIfFunction.Create(
                                               aParentExpr:   TSQLMemExpression;
                                               Op:            TSQLMemDataOperator;
                                               Node1, Node2:  TSQLMemExprNode
                                             );
begin
  inherited Create(aParentExpr,op,Node1,Node2);
end; // Create


//------------------------------------------------------------------------------
// get data value
//------------------------------------------------------------------------------
function TSQLMemExprNodeNullIfFunction.GetDataValue: TSQLMemVariant;
begin
  if (Children.Count = 2) then
  begin
     // NullIf
     Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue,True);
     if (Value.Compare(TSQLMemExprNode(Children[1]).GetDataValue,False,FCaseInsensitive,FPartialKey) = cmprEqual) then
      Value.Clear(Value.FDataType);
  end;
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNodeNullIfFunction.GetDataSize: Integer;
begin
  Result := TSQLMemExprNode(Children[0]).GetDataSize;
end; // GetDataSize


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeNullIfFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  Result := TSQLMemExprNode(Children[0]).getDataType;
end; // GetDataType


//------------------------------------------------------------------------------
// must return false
//------------------------------------------------------------------------------
function TSQLMemExprNodeNullIfFunction.HasNullValues: Boolean;
begin
  Result := TSQLMemExprNode(Children.Items[0]).HasNullValues;
end; // HasNullValues


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeNullIfFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeNullIfFunction.Create(aParentExpr);
end; // CreateCopy




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeVarcharResultfunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return true if we must skip the child in type detction loop
//------------------------------------------------------------------------------
function TSQLMemExprNodeVarcharResultFunction.IsChildMustBeSkippedByDetectType(ChildNo: Integer): Boolean;
begin
  Result := False;
end; // IsChildMustBeSkippedByDetectType


//------------------------------------------------------------------------------
// detect type
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeVarcharResultFunction.DetectType;
var i,sz:   Integer;
    node:   TSQLMemExprNode;
    typ:    TSQLMemAdvancedFieldType;
begin
  if (FType = aftUnknown) then
  begin
    // fixed in v.5.90
    FType := aftUnknown;
    FSize := 0;
    // detect data types
    for i := 0 to Children.Count-1 do
    begin
     if (IsChildMustBeSkippedByDetectType(i)) then
      continue;
     node := TSQLMemExprNode(Children[i]);
     if (node <> nil) then
     begin
      typ := node.GetDataType;
      sz := node.GetDataSize;
      if (FType = aftUnknown) then
      begin
       FType := typ;
       FSize := sz;
      end
      else
      begin
       if (IsStringFieldType(FType) and IsStringFieldType(typ)) then
       begin
        if (FSize < sz) then
          FSize := sz;
       end
       else
       begin
        FSize := 0;
       end;
       FType := GetCommonDataType(FType,typ);
      end;
     end;
    end;
    FBaseType := AdvancedFieldTypeToBaseFieldType(FType);
    if (IsStringFieldType(FType) and (FSize = 0)) then
      FSize := SQLMemExpressionMaxVarcharSize;
  end;
end; // DetectType


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeVarcharResultFunction.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FBaseType := TSQLMemExprNodeCoalesceFunction(Source).FBaseType;
  FType := TSQLMemExprNodeCoalesceFunction(Source).FType;
  FSize := TSQLMemExprNodeCoalesceFunction(Source).FSize;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeIsNullFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create with replacement
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeCoalesceFunction.Create(
                       aParentExpr:   TSQLMemExpression;
                       NodeList:      TSQLMemList
                                             );
begin
  inherited Create(aParentExpr);
  if (Children <> nil) then
  begin
   Clear;
   Children.Free;
  end;
  Children := NodeList;
  FType := aftUnknown;
end; // Create


//------------------------------------------------------------------------------
// get data value
//------------------------------------------------------------------------------
function TSQLMemExprNodeCoalesceFunction.GetDataValue: TSQLMemVariant;
var i: Integer;
begin
  DetectType;
  for i := 0 to Children.Count-1 do
  begin
   Value.Assign(TSQLMemExprNode(Children[i]).GetDataValue,True);
   if (not Value.IsNull) then
   begin
    Value.MaxStrLen := FSize;
    Value.Cast(FBaseType);
    break;
   end;
  end;
  Result := Value;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNodeCoalesceFunction.GetDataSize: Integer;
begin
  DetectType;
  Result := FSize;
end; // GetDataSize


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeCoalesceFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  DetectType;
  Result := FType;
end; // GetDataType


//------------------------------------------------------------------------------
// must return false
//------------------------------------------------------------------------------
function TSQLMemExprNodeCoalesceFunction.HasNullValues: Boolean;
begin
  Result := GetDataValue.IsNull;
end; // HasNullValues


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeCoalesceFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeCoalesceFunction.Create(aParentExpr);
end; // CreateCopy




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeCase
//
// expression node CASE operator
//
// Simple Form:
// CASE case_expression
// WHEN value_expression_1 THEN result_expression_1
// WHEN value_expression_2 THEN result_expression_2
// ...
// WHEN value_expression_n THEN result_expression_n
// ELSE else_expression
// END
//
// Advanced Form:
// CASE
// WHEN boolean_expression_1 THEN result_expression_1
// WHEN boolean_expression_2 THEN result_expression_2
// ...
// WHEN boolean_expression_n THEN result_expression_n
// ELSE else_expression
// END
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return true if we must skip the child in type detction loop
//------------------------------------------------------------------------------
function TSQLMemExprNodeCase.IsChildMustBeSkippedByDetectType(ChildNo: Integer): Boolean;
begin
  Result := (FSimpleForm and ((ChildNo mod 2) = 1) and (ChildNo <= FNumWhen * 2)) or
            ((not FSimpleForm) and ((ChildNo mod 2) = 0) and (ChildNo < FNumWhen * 2));
end; // IsChildMustBeSkippedByDetectType


//------------------------------------------------------------------------------
// create with replacement
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeCase.Create(
                       aParentExpr:   TSQLMemExpression;
                       aSimpleForm:   Boolean;
                       aNumWhen:      Integer;
                       NodeList:      TSQLMemList
                                             );
begin
  inherited Create(aParentExpr);
  if (Children <> nil) then
  begin
   Clear;
   Children.Free;
  end;
  Children := NodeList;
  FSimpleForm := aSimpleForm;
  FNumWhen := aNumWhen;
  FType := aftUnknown;
end; // Create


//------------------------------------------------------------------------------
// get data value
//------------------------------------------------------------------------------
function TSQLMemExprNodeCase.GetDataValue: TSQLMemVariant;
var i:      Integer;
    b:      Boolean;
    v1,v2:  TSQLMemVariant;
begin
  Value.Clear(FBaseType);
  if (FSimpleForm) then
  begin
   v1 := TSQLMemExprNode(Children[0]).GetDataValue;
   i := 1;
   while (i < Children.Count) do
   begin
    if (i < FNumWhen * 2 + 1) then
    begin
     v2 := TSQLMemExprNode(Children[i]).GetDataValue;
     b := (v1.Compare(v2,False,FCaseInsensitive,False) = cmprEqual);
     Inc(i);
     if (b) then
     begin
      Value.Assign(TSQLMemExprNode(Children[i]).GetDataValue,False,False);
      break;
     end;
     Inc(i);
    end
    else
    begin
     // ELSE
     Value.Assign(TSQLMemExprNode(Children[i]).GetDataValue,False,False);
     break;
    end;
   end; // while
  end // Simple Form
  else
  begin
   i := 0;
   while (i < Children.Count) do
   begin
    if (i < FNumWhen * 2) then
    begin
     b := TSQLMemExprNode(Children[i]).GetBooleanValue;
     Inc(i);
     if (b) then
     begin
      Value.Assign(TSQLMemExprNode(Children[i]).GetDataValue,False,False);
      break;
     end;
     Inc(i);
    end
    else
    begin
     // ELSE
     Value.Assign(TSQLMemExprNode(Children[i]).GetDataValue,False,False);
     break;
    end;
   end; // while
  end; // Advanced Form
  Result := Value;
{
  for i := 0 to Children.Count-1 do
  begin
   Result := TSQLMemExprNode(Children[i]).GetDataValue;
   if (not Result.IsNull) then
   begin
    Result.MaxStrLen := FSize;
    Result.Cast(FBaseType);
    break;
   end;
  end;
}
end; // GetDataValue


//------------------------------------------------------------------------------
// return Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNodeCase.GetDataSize: Integer;
begin
  DetectType;
  Result := FSize;
end; // GetDataSize


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeCase.GetDataType: TSQLMemAdvancedFieldType;
begin
  DetectType;
  Result := FType;
end; // GetDataType


//------------------------------------------------------------------------------
// must return false
//------------------------------------------------------------------------------
function TSQLMemExprNodeCase.HasNullValues: Boolean;
begin
  Result := GetDataValue.IsNull;
end; // HasNullValues


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeCase.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeCase.Create(aParentExpr);
end; // CreateCopy




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeArithmetic
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// ADD operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.AddData;
var
  i: Integer;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  // Add next values
  for i:=1 to Children.Count-1 do
  begin
    Value.MaxStrLen := 0;
    Value.Add(TSQLMemExprNode(Children[i]).GetDataValue);
  end;
  Value.MaxStrLen := 0;
end;//AddData


//------------------------------------------------------------------------------
// SUB operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.SubData;
var val2: TSQLMemVariant;
begin
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
{$IFDEF EXPR_PARSING_1}
  // fixed in v.5.90
  if (Children.Count = 1) then
    Value.InvertValue
  else
  begin
    val2 := TSQLMemExprNode(Children[1]).GetDataValue;
    Value.Sub(val2);
  end;
{$ELSE}
  Value.InvertValue;
{$ENDIF}
end;//SubData


//------------------------------------------------------------------------------
// MUL operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.MulData;
var
  i: Integer;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  // Mul next values
  for i:=1 to Children.Count-1 do
    Value.Mul(TSQLMemExprNode(Children[i]).GetDataValue);
end;//MulData


//------------------------------------------------------------------------------
// DIV operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.DivData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.Division(TSQLMemExprNode(Children[1]).GetDataValue);
end;//DivData


//------------------------------------------------------------------------------
// ABS operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.AbsData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.AbsData;
end; // AbsData


//------------------------------------------------------------------------------
// CEILING operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.CeilingData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.CeilingData;
end; // CeilingData


//------------------------------------------------------------------------------
// FLOOR operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.FloorData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.FloorData;
end; // FloorData


//------------------------------------------------------------------------------
// MOD operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.ModData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.ModData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // ModData


//------------------------------------------------------------------------------
// POWER operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.PowerData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.PowerData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // PowerData


//------------------------------------------------------------------------------
// RAND operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.RandomData;
begin
  // Get first argument
  if (Children.Count = 1) then
   Value.RandomData(TSQLMemExprNode(Children[0]).GetDataValue)
  else
   Value.RandomData;
end; // RandomData


//------------------------------------------------------------------------------
// ROUND operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.RoundData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  if (Children.Count > 1) then
   Value.RoundData(TSQLMemExprNode(Children[1]).GetDataValue)
  else
   Value.RoundData;
end; // RoundData


//------------------------------------------------------------------------------
// SIGN operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.SignData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.SignData;
end; // SignData


//------------------------------------------------------------------------------
// TRUNCATE operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.TruncateData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  if (Children.Count > 1) then
   Value.TruncateData(TSQLMemExprNode(Children[1]).GetDataValue)
  else
   Value.TruncateData;
end; // TruncateData


//------------------------------------------------------------------------------
// AND operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.AndData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.AndData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // AndData


//------------------------------------------------------------------------------
// OR operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.OrData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.OrData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // OrData


//------------------------------------------------------------------------------
// NOT operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.NotData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.NotData;
end; // NotData


//------------------------------------------------------------------------------
// SHL operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.ShlData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.ShlData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // ShlData


//------------------------------------------------------------------------------
// SHR operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.ShrData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.ShrData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // ShrData


//------------------------------------------------------------------------------
// XOR operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.XorData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.XorData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // XorData


//------------------------------------------------------------------------------
// HEX operation
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.HexData;
begin
  // Get first argument
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  if (Children.Count = 1) then
   value.HexData
  else
   value.HexData(TSQLMemHexStringFormat(TSQLMemExprNode(Children[1]).GetDataValue.AsInteger));
end; //  HexData


//------------------------------------------------------------------------------
// CUMSUM function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.CumSumData;
var TmpVal: TSQLMemVariant;
begin
  if Children.Count < 1 then
   raise ESQLMemException.Create(11766,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  TmpVal := TSQLMemExprNode(Children[0]).GetDataValue;
  // If not numeric type (string for example) - raise
  if (not TmpVal.IsNull) then
   if (not TmpVal.IsNumericDataType) then
    raise ESQLMemException.Create(11765, ErrorGNotNumericDataType, ['CUMSUM']);
  // if prior value is null then this function is first time called
  if (FPriorValue = nil) then
   begin
    FPriorValue := TSQLMemVariant.Create;
    FPriorValue.Assign(TmpVal,True);
    // first value is NULL
    if (TmpVal.IsNull) then
     begin
      if (TmpVal.IsIntegerDataType) then
       begin
        Value.Clear(bftSignedInt64);
        Value.AsInt64 := 0;
       end
      else
       begin
        Value.Clear(bftExtended);
        Value.AsExtended := 0;
       end;
     end
    else
     begin
      Value.Assign(FPriorValue,True);
     end;
   end // first time
  else
   begin
    if (not TmpVal.IsNull) then
     begin
      FPriorValue.Assign(TmpVal,True);
      Value.Add(FPriorValue);
     end;
   end;
end; // CumSumData


//------------------------------------------------------------------------------
// CUMPROD function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.CumProdData;
var TmpVal: TSQLMemVariant;
begin
  if Children.Count < 1 then
   raise ESQLMemException.Create(11767,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  TmpVal := TSQLMemExprNode(Children[0]).GetDataValue;
  // If not numeric type (string for example) - raise
  if (not TmpVal.IsNull) then
   if (not TmpVal.IsNumericDataType) then
    raise ESQLMemException.Create(11768, ErrorGNotNumericDataType, ['CUMSUM']);
  // if prior value is null then this function is first time called
  if (FPriorValue = nil) then
   begin
    FPriorValue := TSQLMemVariant.Create;
    FPriorValue.Assign(TmpVal,True);
    // first value is NULL
    if (TmpVal.IsNull) then
     begin
      if (TmpVal.IsIntegerDataType) then
       begin
        Value.Clear(bftSignedInt64);
        Value.AsInt64 := 1;
       end
      else
       begin
        Value.Clear(bftExtended);
        Value.AsExtended := 1;
       end;
     end
    else
     begin
      Value.Assign(FPriorValue,True);
     end;
   end // first time
  else
   begin
    if (not TmpVal.IsNull) then
     begin
      FPriorValue.Assign(TmpVal,True);
      Value.Mul(FPriorValue);
     end;
   end;
end; // CumProdData


//------------------------------------------------------------------------------
// EXP function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.ExpData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12485,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.ExpData;
end; // ExpData


//------------------------------------------------------------------------------
// LOG / LN function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.LogData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12486,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  if (Children.Count = 1) then
    Value.LogData(nil)
  else
    Value.LogData(TSQLMemExprNode(Children[1]).GetDataValue);
end; // LogData


//------------------------------------------------------------------------------
// LOG10 function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.Log10Data;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12487,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.Log10Data;
end; // Log10Data


//------------------------------------------------------------------------------
// COS function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.CosData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12493,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.CosData;
end; // COS


//------------------------------------------------------------------------------
// SIN function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.SinData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12494,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.SinData;
end; // SIN


//------------------------------------------------------------------------------
// ACOS function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.AcosData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12497,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.AcosData;
end; // AcosData


//------------------------------------------------------------------------------
// ASIN function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.AsinData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12498,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.AsinData;
end; // AsinData


//------------------------------------------------------------------------------
// ATAN function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.AtanData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12499,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.AtanData;
end; // AtanData


//------------------------------------------------------------------------------
// ATAN2 function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.Atan2Data;
begin
  if (Children.Count < 2) then
   raise ESQLMemException.Create(12500,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.Atan2Data(TSQLMemExprNode(Children[1]).GetDataValue);
end; // Atan2Data


//------------------------------------------------------------------------------
// COT function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.CotData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12504,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.CotData;
end; // CotData


//------------------------------------------------------------------------------
// TAN function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.TanData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12505,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.TanData;
end; // TanData


//------------------------------------------------------------------------------
// SQR function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.SqrData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12509,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.SqrData;
end; // SqrData


//------------------------------------------------------------------------------
// SQRT function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.SqrtData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12510,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.SqrtData;
end; // SqrtData


//------------------------------------------------------------------------------
// DEGREES function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.DegreesData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12515,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.DegreesData;
end; // DegreesData


//------------------------------------------------------------------------------
// RADIANS function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.RadiansData;
begin
  if (Children.Count < 1) then
   raise ESQLMemException.Create(12516,ErrorLInvalidParameterCountInExpression,
          [GetOperatorName(Operator),Children.Count,1]);
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.RadiansData;
end; // RadiansData


//------------------------------------------------------------------------------
// PI function
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.PiData;
begin
  Value.PiData;
end; // PiData


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeArithmetic.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeArithmetic.Create(aParentExpr);
  TSQLMemExprNodeArithmetic(Result).FPriorValue := nil;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeArithmetic.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  if (FPriorValue <> nil) then
   FreeAndNil(FPriorValue);
end; // Assign


//------------------------------------------------------------------------------
// Constructors
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeArithmetic.Create(
                                           aParentExpr: TSQLMemExpression;
                                           Op:          TSQLMemDataOperator;
                                           Node:        TSQLMemExprNode
                                         );
begin
  inherited Create(aParentExpr, Op, Node);
  FPriorValue := nil;
end; // Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeArithmetic.Destroy;
begin
  if (FPriorValue <> nil) then
   FreeAndNil(FPriorValue);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeArithmetic.GetDataValue: TSQLMemVariant;
begin
  case Operator of
   doSUB:       SubData;
   doADD:       AddData;
   doMUL:       MulData;
   doDIV:       DivData;
   doABS:       AbsData;
   doCEILING:   CeilingData;
   doFLOOR:     FloorData;
   doMOD:       ModData;
   doPOWER:     PowerData;
   doRANDOM:    RandomData;
   doROUND:     RoundData;
   doSIGN:      SignData;
   doTRUNCATE:  TruncateData;
   doBitwiseAND:  AndData;
   doBitwiseOR:   OrData;
   doBitwiseNOT:  NotData;
   doSHL:         ShlData;
   doSHR:         ShrData;
   doXOR:         XorData;
   doHEX:         HexData;
   doCUMSUM:      CumSumData;
   doCUMPROD:     CumProdData;
   doEXP:         ExpData;
   doLOG:         LogData;
   doLOG10:       Log10Data;
   doCOS:         CosData;
   doSIN:         SinData;
   doACOS:        AcosData;
   doASIN:        AsinData;
   doATAN:        AtanData;
   doATAN2:       Atan2Data;
   doCOT:         CotData;
   doTAN:         TanData;
   doSQR:         SqrData;
   doSQRT:        SqrtData;
   doDEGREES:     DegreesData;
   doRADIANS:     RadiansData;
   doPI:          PiData;
   else
     raise ESQLMemException.Create(30121, ErrorGUnknownOperator,
                                [GetOperatorName(Operator)]);
  end;
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeArithmetic.GetDataType: TSQLMemAdvancedFieldType;
begin
  if Operator = doMOD then
    Result := aftLargeint
  else
  if Operator = doHEX then
    Result := aftString
  else
  if ((Operator = doTRUNCATE) or (Operator = doROUND)) then
   begin
    if (Children.Count = 1) then
     Result := aftLargeint
    else
     Result := aftString;
   end
  else
  if (Operator = doRANDOM) then
   begin
    if (Children.Count = 0) then
     Result := aftExtended
    else
     Result := aftInteger;
   end
  else
  if (Operator in [doCEILING,doFLOOR]) then
    Result := aftInteger
  else
  if (Operator = doPOWER) then
   begin
    if (IsIntegerFieldType(AdvancedFieldTypeToBaseFieldType(TSQLMemExprNode(Children[0]).getDataType))) then
     Result := aftLargeint
    else
     Result := aftExtended;
   end
  else
  if (Operator in [doCUMSUM,doCUMPROD]) then
   begin
    if Children.Count <> 0 then
     begin
      Result := TSQLMemExprNode(Children[0]).getDataType;
      if not (Result in [aftSingle, aftDouble, aftExtended,
                          aftCurrency] ) then
        Result := aftLargeint;
     end;
   end
  else
  if Operator = doPI then
    Result := aftExtended
  else
    Result := inherited GetDataType;
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeArithmetic.GetDataSize: Integer;
begin
  if ((Operator = doTRUNCATE) or (Operator = doROUND)) and (Children.Count > 1) then
   Result := SQLMemMaxRoundCharacters
  else
   Result := inherited GetDataSize;
end; // GetDataSize



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeStringFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// InitStringValue and return IsNull
//------------------------------------------------------------------------------
function TSQLMemExprNodeStringFunction.InitStringValue;
begin
  if (Operator = doTrim) and (Children.Count >= 2) then
   Value.Assign(TSQLMemExprNode(Children[1]).GetDataValue, False)
  else
   Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  Value.MaxStrLen := 0;
  // Guarantee AnsiString or WideString type
  if not Value.IsStringDataType then
    Value.Cast(bftVarchar);
  Result := not Value.IsNull;
end;//InitStringValue


//------------------------------------------------------------------------------
// Concat
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.Concat;
var i: Integer;
begin
  InitStringValue;
  // Concatenation
  for i:=1 to Children.Count-1 do
   Value.Add(TSQLMemExprNode(Children[i]).GetDataValue);
end;//Concat


//------------------------------------------------------------------------------
// Upper
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.Upper;
begin
  if (not InitStringValue) then
    Exit;
  // WideString ?
//          raise Exception.Create('');
  if Value.IsWideStringDataType then
    Value.AsWideString := aaWideUpperCase(Value.AsWideString)
  else
    Value.AsString := AnsiUpperCase(Value.AsString);
end;//Upper


//------------------------------------------------------------------------------
// Lower
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.Lower;
begin
  if (not InitStringValue) then
    Exit;
  // WideString ?
  if Value.IsWideStringDataType then
    Value.AsWideString := aaWideLowerCase(Value.AsWideString)
  else
    Value.AsString := AnsiLowerCase(Value.AsString)
end;//Lower


//------------------------------------------------------------------------------
// advanced Trim ANSI
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.TrimA;
var s:      AnsiString;
    i,l:    Integer;
    x1,x2:  Integer;
    c:      AnsiChar;
    v:      TSQLMemVariant;
begin
  // trim character
  v := TSQLMemVariant.Create;
  try
    v.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    if (v.IsNull) then
    begin
     Value.Clear(Value.DataType);
     Exit;
    end;
    if not v.IsStringDataType then
      v.Cast(bftVarchar);
    c := v.AsString[1];
    s := Value.AsString;
    l := System.Length(s);
    x1 := -1;
    x2 := -1;
    // trim from the beginning
    if (FTrimType <> attTrailing) then
    begin
     i := 1;
     while (i <= l) do
     begin
      if (s[i] <> c) then
       break;
      Inc(i);
     end;
     x1 := i;
    end;
    // trim from the end
    if (FTrimType <> attLeading) then
    begin
     i := l;
     while (i > 0) do
     begin
      if (s[i] <> c) then
       break;
      Dec(i);
     end;
     x2 := i;
    end;
    if (x2 < 0) then
    begin
     // trim from beginning only
     if (x1 > l) then
     begin
      // all symbols trimmed
      Value.Clear(Value.DataType);
      Exit;
     end
     else
     if (x1 > 1) then
     begin
      s := System.Copy(s,x1,l-x1+1);
     end;
    end
    else
    if (x1 < 0) then
    begin
     // trim from end only
     if (x2 <= 0) then
     begin
      // all symbols trimmed
      Value.Clear(Value.DataType);
      Exit;
     end
     else
     if (x2 < l) then
     begin
      s := System.Copy(s,1,x2);
     end;
    end
    else
    begin
     // trim from both sides
     if (x1 > l) then
     begin
      // all symbols trimmed
      Value.Clear(Value.DataType);
      Exit;
     end;
     s := System.Copy(s,x1,x2-x1+1);
    end;
    Value.AsString := s;
  finally
    v.Free;
  end;
end; // TrimA


//------------------------------------------------------------------------------
// advanced Trim Unicode
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.TrimW;
var s:      WideString;
    i,l:    Integer;
    x1,x2:  Integer;
    c:      WideChar;
    v:      TSQLMemVariant;
begin
  // trim character
  v := TSQLMemVariant.Create;
  try
    v.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    if (v.IsNull) then
    begin
     Value.Clear(Value.DataType);
     Exit;
    end;
    if not v.IsStringDataType then
      v.Cast(bftVarchar);
    c := v.AsWideString[1];
    s := Value.AsWideString;
    l := System.Length(s);
    x1 := -1;
    x2 := -1;
    // trim from the beginning
    if (FTrimType <> attTrailing) then
    begin
     i := 1;
     while (i <= l) do
     begin
      if (s[i] <> c) then
       break;
      Inc(i);
     end;
     x1 := i;
    end;
    // trim from the end
    if (FTrimType <> attLeading) then
    begin
     i := l;
     while (i > 0) do
     begin
      if (s[i] <> c) then
       break;
      Dec(i);
     end;
     x2 := i;
    end;
    if (x2 < 0) then
    begin
     // trim from beginning only
     if (x1 > l) then
     begin
      // all symbols trimmed
      Value.Clear(Value.DataType);
      Exit;
     end
     else
     if (x1 > 1) then
     begin
      s := System.Copy(s,x1,l-x1+1);
     end;
    end
    else
    if (x1 < 0) then
    begin
     // trim from end only
     if (x2 <= 0) then
     begin
      // all symbols trimmed
      Value.Clear(Value.DataType);
      Exit;
     end
     else
     if (x2 < l) then
     begin
      s := System.Copy(s,1,x2);
     end;
    end
    else
    begin
     // trim from both sides
     if (x1 > l) then
     begin
      // all symbols trimmed
      Value.Clear(Value.DataType);
      Exit;
     end;
     s := System.Copy(s,x1,x2-x1+1);
    end;
    Value.AsWideString := s;
  finally
    v.Free;
  end;
end; // TrimW


//------------------------------------------------------------------------------
// Trim
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.Trim;
begin
  if (not InitStringValue) or (Children.Count <= 0) then
    Exit;
  if (Children.Count = 1) then
  begin
    // simple form TRIM(expr)
    // WideString ?
    if Value.IsWideStringDataType then
      Value.AsWideString := SysUtils.Trim(Value.AsWideString)
    else
      Value.AsString := SysUtils.Trim(Value.AsString)
  end
  else
  begin
    if Value.IsWideStringDataType then
      TrimW
    else
      TrimA;
  end;
end;//Trim


//------------------------------------------------------------------------------
// LTrim
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.LTrim;
begin
  if (not InitStringValue) then
    Exit;
  // WideString ?
  if Value.IsWideStringDataType then
    Value.AsWideString := SysUtils.TrimLeft(Value.AsWideString)
  else
    Value.AsString := SysUtils.TrimLeft(Value.AsString)
end;//LTrim


//------------------------------------------------------------------------------
// RTrim
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.RTrim;
begin
  if (not InitStringValue) then
    Exit;
  // WideString ?
  if Value.IsWideStringDataType then
    Value.AsWideString := SysUtils.TrimRight(Value.AsWideString)
  else
    Value.AsString := SysUtils.TrimRight(Value.AsString)
end;//RTrim


//------------------------------------------------------------------------------
// Length
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.Length;
var
  TmpVal: TSQLMemVariant;
begin
  //Value.SetNull(bftSignedInt32);
  Value.AsInteger := 0;
  TmpVal := TSQLMemVariant.Create;
  try
    TmpVal.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    // Guarantee AnsiString or WideString type
    if (not TmpVal.IsStringDataType) then
      TmpVal.Cast(bftVarchar);
    // IsNull ?
    if (not TmpVal.IsNull) then
     Value.AsInteger := TmpVal.StrLen;
{
// v.4.60
      case TmpVal.DataType of
        bftChar,
        bftVarchar:
          Value.AsInteger := System.Length(TmpVal.AsString);
        bftWideChar,
        bftWideVarchar:
          // div 2 - 1 (2 zero bytes at the end)
          Value.AsInteger := System.Length(TmpVal.AsWideString) shr 1 - 1;
      end;
}
  finally
    TmpVal.Free;
  end;
end;//Length


//------------------------------------------------------------------------------
// Pos
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.Pos;
var
  StrValue, SubstrValue: TSQLMemVariant;
begin
  StrValue := TSQLMemVariant.Create;
  SubstrValue := TSQLMemVariant.Create;
  try
    StrValue.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
    SubstrValue.Assign(TSQLMemExprNode(Children[1]).GetDataValue, False);
    if (StrValue.IsNull or SubstrValue.IsNull) then
     begin
      Value.AsInteger := 0;
      Exit;
     end;    // Guarantee AnsiString or WideString type
    if (not StrValue.IsStringDataType) then
      StrValue.Cast(bftWideVarchar);
    if (not SubStrValue.IsStringDataType) then
      SubStrValue.Cast(bftWideVarchar);
    case StrValue.DataType of
      bftChar,
      bftVarchar:
        case SubStrValue.DataType of
          bftChar,
          bftVarchar:
            Value.AsInteger := System.pos(StrValue.AsString, SubstrValue.AsString);
          bftWideChar,
          bftWideVarchar:
            Value.AsInteger := System.pos(StrValue.AsWideString, SubstrValue.AsWideString);
        end;
      bftWideChar,
      bftWideVarchar:
        case SubStrValue.DataType of
          bftChar,
          bftVarchar:
            Value.AsInteger := System.pos(StrValue.AsWideString, SubstrValue.AsWideString);
          bftWideChar,
          bftWideVarchar:
            Value.AsInteger := System.pos(StrValue.AsWideString, SubstrValue.AsWideString);
        end
    end;
  finally
    StrValue.Free;
    SubstrValue.Free;
  end;
end;//Pos


//------------------------------------------------------------------------------
// SUBString
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.SUBString;
var
  Start, Len: Integer;
begin
  // Start Position
  Start := TSQLMemExprNode(Children[1]).GetDataValue.AsInteger;

  // length
  if Children.Count >=3 then
   Len := TSQLMemExprNode(Children[2]).GetDataValue.AsInteger
  else
   begin
     Length;
     len := Value.AsInteger;
   end;

  // AnsiString
  Value.Assign(TSQLMemExprNode(Children[0]).GetDataValue, False);
  // AnsiString is null ?
  if (Value.IsNull) then
    Exit;
  // Guarantee AnsiString or WideString Type
  if (not Value.IsStringDataType) then
    Value.Cast(bftVarchar);

  // Get SUBString
  if Value.IsWideStringDataType then
    Value.AsWideString := copy(Value.AsWideString, Start, Len)
  else
    Value.AsString := copy(Value.AsString, Start, Len);

end;//SUBString


//------------------------------------------------------------------------------
// Detect Concat Result Type
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.DetectConcatResultType(bForceDetect: Boolean);
var i:      Integer;
    node:   TSQLMemExprNode;
    t,res:  TSQLMemAdvancedFieldType;
    nl:     TSQLMemIntegerArray;
begin
//    Result := inherited GetDataType
  if (not bForceDetect) then
   if ((FConcatDataType <> aftUnknown) or (Children.Count <= 0)) then
    Exit;
  FConcatDataSize := 0;
  nl := TSQLMemIntegerArray.Create;
  try
    for i := 0 to Children.Count-1 do
    begin
      node := TSQLMemExprNode(Children[i]);
      t := node.GetDataType;
      if (i > 0) then
       t := GetCommonDataType(t,FConcatDataType);
      if (not IsStringFieldType(t)) then
       nl.Add(i)
      else
      begin
        FConcatDataType := t;
        if (i = 0) then
        begin
          FConcatDataSize := node.GetDataSize;
        end
        else
        begin
          Inc(FConcatDataSize,node.GetDataSize);
        end;
      end;
    end;
    if (nl.ItemCount > 0) then
    begin
     FConcatDataSize := SQLMemExpressionMaxVarcharSize;
     for i := 0 to nl.ItemCount-1 do
     begin
      node := Children.Items[nl.Items[i]];
      if (FConcatDataType <> aftUnknown) then
       Children.Items[nl.Items[i]] := TSQLMemExprNodeCast.Create(LParentExpr, node, FConcatDataType);
     end;
    end;
  finally
    nl.Free;
  end;
end; // DetectConcatResultType


//------------------------------------------------------------------------------
// return integer code of the first symbol ('a' = 65)
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.ASCII;
var s: String;
begin
  s := TSQLMemExprNode(Children[0]).GetDataValue.AsString;
  if (System.Length(s) <= 0) then
   Value.Clear(bftSignedInt32)
  else
   Value.AsInteger := System.Ord(s[1]);
end; // ASCII


//------------------------------------------------------------------------------
// return symbol by its integer code (65 -> 'a' )
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.CHR;
begin
  Value.AsString := System.Chr(Byte(TSQLMemExprNode(Children[0]).GetDataValue.AsInteger));
end; // CHR


//------------------------------------------------------------------------------
// repeat
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.FuncRepeat;
var i,l,n,w: Integer;
    s,s1:    AnsiString;
    ws,ws1:  WideString;
    c:       AnsiChar;
    wc:      WideChar;
begin
  n := TSQLMemExprNode(Children.Items[1]).GetDataValue.AsInteger;
  if (n <= 0) then
   begin
    Value.Clear;
    Exit;
   end;
  if (TSQLMemExprNode(Children.Items[0]).GetDataValue.IsWideStringDataType) then
  begin
   // Unicode
   ws1 := TSQLMemExprNode(Children.Items[0]).GetDataValue.AsWideString;
   l := System.Length(ws1) * 2;
   SetLength(ws,n);
   for i := 1 to n do
    Move(ws1[1],ws[(i-1)*l+1],l);
   Value.AsWideString := ws;
  end
  else
  begin
   // ANSI
   s1 := TSQLMemExprNode(Children.Items[0]).GetDataValue.AsWideString;
   l := System.Length(s1);
   SetLength(s,n);
   for i := 1 to n do
    Move(s1[1],s[(i-1)*l+1],l);
   Value.AsString := s; 
  end;
end; // FuncRepeat


//------------------------------------------------------------------------------
// replace
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStringFunction.FuncReplace;
var
    s,s1,s2:      AnsiString;
    ws,ws1,ws2:   WideString;
begin
  if (TSQLMemExprNode(Children.Items[0]).GetDataValue.IsWideStringDataType) then
  begin
   // Unicode
   ws := TSQLMemExprNode(Children.Items[0]).GetDataValue.AsWideString;
   ws1 := TSQLMemExprNode(Children.Items[1]).GetDataValue.AsWideString;
   ws2 := TSQLMemExprNode(Children.Items[2]).GetDataValue.AsWideString;
   {$IFDEF D12H}
   Value.AsWideString := StringReplace(ws,ws1,ws2,[rfReplaceAll]);
   {$ELSE}
   Value.AsWideString := WideString(StringReplace(AnsiString(ws),AnsiString(ws1),AnsiString(ws2),[rfReplaceAll]));
   {$ENDIF}
  end
  else
  begin
   // ANSI
   s := TSQLMemExprNode(Children.Items[0]).GetDataValue.AsString;
   s1 := TSQLMemExprNode(Children.Items[1]).GetDataValue.AsString;
   s2 := TSQLMemExprNode(Children.Items[2]).GetDataValue.AsString;
   {$IFDEF D12H}
   Value.AsString := AnsiString(StringReplace(s,s1,s2,[rfReplaceAll]));
   {$ELSE}
   Value.AsString := StringReplace(s,s1,s2,[rfReplaceAll]);
   {$ENDIF}
  end;
end; // FuncReplace


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeStringFunction.Create(
                       aParentExpr:     TSQLMemExpression;
                       Op:              TSQLMemDataOperator;
                       Node1, Node2:    TSQLMemExprNode;
                       aTrimType:       TSQLMemTrimType;
                       CaseInsensitive: Boolean = true;
                       PartialKey:      Boolean = false
                   );
begin
  inherited Create(aParentExpr,Op,Node1,Node2,CaseInsensitive,PartialKey);
  FTrimType := aTrimType;
  FConcatDataType := aftUnknown;
end; // Create


//------------------------------------------------------------------------------
// Return Data Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeStringFunction.GetDataValue: TSQLMemVariant;
begin
  case Operator of
   doCONCAT:    Concat;
   doUPPER:     Upper;
   doLOWER:     Lower;
   doTRIM:      Trim;
   doLTRIM:     LTrim;
   doRTRIM:     RTrim;
   doSUBString: SUBString;
   doPOS:       Pos;
   doLENGTH:    Length;
   doASCII:     ASCII;
   doCHR:       CHR;
   doREPEAT:    FuncRepeat;
   doREPLACE:   FuncReplace;
   else
     raise ESQLMemException.Create(30131, ErrorGUnknownOperator,
                                 [GetOperatorName(Operator)]);
  end;
  Result := Value;
end;//GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeStringFunction.GetDataType: TSQLMemAdvancedFieldType;
begin
  if Operator in [doPOS, doLENGTH, doASCII] then
    Result := aftInteger
  else
  if (Operator = doCONCAT) then
  begin
    DetectConcatResultType;
    Result := FConcatDataType;
  end
  else
  if (Operator = doTrim) then
  begin
   if (Children.Count >= 2) then
     Result :=  TSQLMemExprNode(Children[1]).GetDataType
   else
     Result := TSQLMemExprNode(Children[0]).GetDataType;
  end
  else
  if (Operator = doCHR) then
  begin
   {$IFDEF D12H}
   Result := aftWideChar;
   {$ELSE}
   Result := aftChar;
   {$ENDIF}
  end
  else
   Result := TSQLMemExprNode(Children[0]).GetDataType;
end;//GetDataType


//------------------------------------------------------------------------------
// get Data Size
//------------------------------------------------------------------------------
function TSQLMemExprNodeStringFunction.GetDataSize: Integer;
var i: Integer;
begin
  Result := 0;
  case Operator of
    doTRIM:
    begin
      if (Children.Count >= 2) then
        Result :=  TSQLMemExprNode(Children[1]).GetDataSize
      else
        Result :=  TSQLMemExprNode(Children[0]).GetDataSize;
    end;
    doUPPER,
    doLOWER,
    doSUBString,
    doLTRIM,
    doRTRIM:
      Result :=  TSQLMemExprNode(Children[0]).GetDataSize;
    doCONCAT:
      begin
        DetectConcatResultType;
        Result := FConcatDataSize;
      end;
    doCHR:
      Result := 1;
    doREPEAT,
    doREPLACE:
      Result := SQLMemExpressionMaxVarcharSize;
  end;
end;//GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeStringFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeStringFunction.Create(aParentExpr);
end; // CreateCopy


//------------------------------------------------------------------------------
// return true if '*' occurs in the string constant
//------------------------------------------------------------------------------
function IsPartialKey(Node: TSQLMemExprNode): integer;
var i: Integer;
begin
  Result := 0;
  if Node.ClassType = TSQLMemExprNodeConst then
   begin
    i := Node.Value.StrLen;
    if (i <> -1)  then
     if Node.Value.AsString[i] = '*' then
      begin
       if (not Node.Value.FIsBlob) then
        begin
         if Node.Value.IsWideStringDataType then
           Node.Value.AsWideString := Copy(Node.Value.AsWideString,1,i-1)
         else
           Node.Value.AsString := Copy(Node.Value.AsString,1,i-1);
        end;
       Result := 1;
      end;
   end;
end; // IsPartialKey


//------------------------------------------------------------------------------
// return information about the operand
//------------------------------------------------------------------------------
function SQLMemGetOperand(Node: TSQLMemExprNode): String;
begin
 if (Node = nil) then
   Result := 'nil'
 else
 if (Node is TSQLMemExprNodeField) then
   Result := Node.ClassName+'('+TSQLMemExprNodeField(Node).FTableName+'.'+TSQLMemExprNodeField(Node).FFieldName+')'
 else
 if (Node is TSQLMemExprNodeConst) then
   Result := Node.ClassName+'('+Node.Value.AsString+')'
 else
   Result := Node.ClassName+'('+GetOperatorName(Node.Operator)+','+IntToStr(Node.ChildrenCount)+')';
end;

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemBaseEngine> initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
