unit SQLMemStoredFunctions;

interface

{$I SQLMemVer.inc}

uses
     SysUtils, Classes, Db,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}

// SQLMemTable units
{$IFDEF LINUX}
     SQLMemLinux,
{$ENDIF}
{$IFDEF DEBUG_LOG}
     SQLMemDebug,
{$ENDIF}
{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF}
     SQLMemConst,
     SQLMemTypes,
     SQLMemConverts,
     SQLMemStrUtils,
     SQLMemLexer,
     SQLMemVariant,
     SQLMemBase,
     SQLMemBaseEngine,
     SQLMemCompression,
     SQLMemRelationalAlgebra,
     SQLMemCriticalSection,
     SQLMemExpressions,
     SQLMemSQLProcessor,
     SQLMemExcept;



type

  TSQLMemStoredFunction = class;

  TSQLMemStoredFunctionHeader = packed record
    CreationDate:         TDateTime;
    LastModificationDate: TDateTime;
    NameCRC:              Cardinal;
    SQLCRC:               Cardinal;
  end; // TSQLMemStoredFunctionHeader

{
// Procedure - function with UNKNOWN result type
CREATE FUNCTION syntax:
CREATE FUNCTION <FunctionName> [(Param1,Param2,...,ParamN)] [:<ResultType>];
CREATE PROCEDURE <FunctionName> [(Param1,Param2,...,ParamN)];

DROP FUNCTION syntax:
DROP FUNCTION <FunctionName>;
DROP PROCEDURE <FunctionName>;

EXECUTE FUNCTION syntax:
EXECUTE FUNCTION <FunctionName>[(Param1,Param2,...,ParamN)];
EXECUTE PROCEDURE <FunctionName>[(Param1,Param2,...,ParamN)];
}


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeVariable
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeVariable = class (TSQLMemExprNode)
   private
    FName:            WideString;         // variable name
    FIsSessionVar:    Boolean;
    LStoredFunction:  TSQLMemStoredFunction;
    FParamIndex:      Integer;
   public
    constructor Create(aParentExpr: TSQLMemExpression; aName: WideString; aStoredFunction: TSQLMemStoredFunction; aParamIndex: Integer);
    destructor Destroy; override;
    // return Value
    function GetDataValue: TSQLMemVariant; override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
   public
    property Name: WideString read FName;
    property IsSessionVar: Boolean read FIsSessionVar;
    property StoredFunction: TSQLMemStoredFunction read LStoredFunction;
    property ParamIndex: Integer read FParamIndex;
  end; // TSQLMemExprNodeVariable


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExprNodeStoredFunction = class (TSQLMemExprNode)
   private
    FParams:              TSQLMemExpressions;    // function params
//    LStoredFunction:    TSQLMemStoredFunction;
    FStoredFunctionName:  WideString;
   protected
    function FindStoredFunction: TSQLMemStoredFunction;
   public
    constructor Create(
                          aParentExpr:          TSQLMemExpression;
                          aStoredFunctionName:  WideString;
//                          aStoredFunction: TSQLMemStoredFunction;
                          aParams:              TSQLMemExpressions
                      );
    destructor Destroy; override;
    // process assign AO
    procedure AssignAO(AO: TSQLMemAO); override;
    // process assign Cursor
    procedure AssignCursor(Cursor: TSQLMemCursor); override;
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TSQLMemRecordBuffer); override;
    // return Value
    function GetDataValue: TSQLMemVariant; override;
    // return Type of Data
    function GetDataType: TSQLMemAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode; override;
   public
    // assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TSQLMemExprNode); override;
   public
    property StoredFunctionName: WideString read FStoredFunctionName;
  end; // TSQLMemExprNodeStoredFunction


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemStoredFunction = class (TObject)
   private
    FFunctionName:    WideString;         // function name
    FResultType:      TSQLMemBaseFieldType;  // function result type
    FResultTypeSize:  Integer;            // 0 - no limit, otherwise maximum size of result string in characters
    FParams:          TSQLMemSQLParams;      // contains params and local variables
                                          // nil if no params or list with TSQLMemVariant objects
    FCommands:        TList;              // list of TSQLMemSQLcommand
    FParamCount:      Integer;
    FThreadSync:      TSQLMemReadWriteThreadSyncBySingleCriticalSection;
    FUseCount:        Integer;
    FFreeIfNotUsed:   Boolean;            // set by delete / load if function changed or deleted
   public
    // create
    constructor Create(
                aFunctionName:    WideString;
                aParams:          TSQLMemSQLParams;
                aParamCount:      Integer;
                aResultType:      TSQLMemBaseFieldType;
                aResultTypeSize:  Integer;
                aCommands:        TList
                      ); overload;
    // destroy
    destructor Destroy; override;
    // clear params and commands
    procedure Clear;
    // return nil if not found
    function FindVariable(Name: WideString): TSQLMemSQLParam;
    // return parameter index
    function GetParamIndex(Name: WideString): Integer;
    // create and return list of all paremeters with default values
    function GetParams: TSQLMemSQLParams;
    // return nil if procedure or result object
    procedure Execute(
                      Session:      TSQLMemBaseSession;
                      CallParams:   TSQLMemSQLParams;
                      ResultValue:  TSQLMemVariant
                    );
    // increment UseCount
    procedure IncUseCount;
    // decrement UseCount
    procedure DecUseCount;
   public
    property FunctionName: WideString read FFunctionName;
    property ResultType: TSQLMemBaseFieldType read FResultType;
    property ResultTypeSize: Integer read FResultTypeSize write FResultTypeSize;
    property Commands: TList read FCommands write FCommands;
    property Params: TSQLMemSQLParams read FParams;
    property ParamCount: Integer read FParamCount;
    property UseCount: Integer read FUseCount;
    property FreeIfNotUsed: Boolean read FFreeIfNotUsed write FFreeIfNotUsed; // set by delete / load if function changed or deleted
  end; // TSQLMemStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStoredFunctionManager
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemStoredFunctionManager = class (TObject)
   protected
    LDatabaseData:    TSQLMemDatabaseData;
    FThreadSync:      TSQLMemReadWriteThreadSync;
    FFunctionNames:   TSQLMemObjectNameArray;
    FFunctionSQL:     TSQLMemObjectNameArray;
    // pointers to TSQLMemStoredFunction class - binary representation of stored function
    FFunctions:       TList;
    FHeader:          TSQLMemSFMHeader;
    FFunctionHeaders: array of TSQLMemStoredFunctionHeader;
    // temporary data - used for correct load of the StoredFunctionManager
    FTempFunctions:   TList;
    FTempNamesCRC:    TSQLMemIntegerArray;
    FTempSQLCRC:      TSQLMemIntegerArray;
   protected
    procedure Lock(Exclusive: Boolean); virtual;
    procedure Unlock; virtual;
    procedure Clear;
    procedure DestroyStoredFunction(var sf: TSQLMemStoredFunction);
    procedure ParseCreateFunction(lexer: TSQLMemLexer; var token: TToken);
    function ParseFunctionName(lexer: TSQLMemLexer; var token: TToken): WideString;
    function ParseFunctionParamTypeSize(lexer: TSQLMemLexer; var token: TToken): Integer;
    function ParseFunctionParamDefaultValue(lexer: TSQLMemLexer; var token: TToken): TSQLMemSQLParam;
    procedure ParseFunctionParams(lexer: TSQLMemLexer; var token: TToken; bParseParams: Boolean; var params: TSQLMemSQLParams);
    procedure ParseResultType(lexer: TSQLMemLexer; var token: TToken; out FunctionType: TSQLMemBaseFieldType; out FunctionTypeSize: Integer);
    // parse function body (var ...; begin ... end;)
    function ParseFunctionBody(
                                Session:          TSQLMemBaseSession;
                                Lexer:            TSQLMemLexer;
                                var Token:        TToken;
                                StoredFunction:   TSQLMemStoredFunction
                                ): TList;
    // base function for parsing SQL script with CREATE FUNCTION ...; ... BEGIN ... END;
    function InternalParseCreateStoredFunction(
                    bCalledFromSQL:   Boolean;
                    Session:          TSQLMemBaseSession;
                    Lexer:            TSQLMemLexer;
                    var Token:        TToken;
                    bCreateFunction:  Boolean;
                    out SQLScript:    WideString;
                    out ErrorMessage: WideString
                      ): TSQLMemStoredFunction;
    // base function for parsing SQL script with CREATE FUNCTION ...; ... BEGIN ... END;
    function ParseCreateStoredFunction(
                    Session:          TSQLMemBaseSession;
                    SQLScript:        WideString;
                    bCreateFunction:  Boolean;
                    out ErrorMessage: WideString
                      ): TSQLMemStoredFunction;
    // return -1 if not found, otherwise return index in FunctionNames,FunctionSQL arrays
    function GetFunctionByName(Name: WideString): Integer;
    // parse function call parameters:
    // FunctionName [(<call_params>)]
    function ParseFunctionCallParams(
                        Session:          TSQLMemBaseSession;
                        Lexer:            TSQLMemLexer;
                        parentFunction:   TObject; // parent TSQLMemStoredFunction object, where parser was called
                        var Token:        TToken;
                        aStoredFunction:  TSQLMemStoredFunction
                                    ): TObject;
    procedure InternalCreateStoredFunction(
                                    StoredFunction: TSQLMemStoredFunction;
                                    SQLScript:      WideString
                                          ); virtual;
    procedure InternalDropStoredFunction(FunctionName: WideString); virtual;
    // ALTER stored function - modify script
    procedure InternalAlterStoredFunction(
                                    Session:      TSQLMemBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                                        ); virtual;
    // ALTER stored function - rename
    procedure InternalAlterStoredFunctionRename(
                                    Session:          TSQLMemBaseSession;
                                    FunctionName,
                                    NewFunctionName:  WideString
                                                        ); virtual;
    // return nil if not found, otherwise return TSQLMemStoredFunction object from FFunctions
    function InternalGetStoredFunctionByName(FunctionName: WideString; Session: TSQLMemBaseSession): TSQLMemStoredFunction;
    // get all stored functions
    procedure InternalGetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList = nil; SortNamesByAlphabet: Boolean = true);
    // export all functions to SQL
    procedure InternalExportStoredFunctionsToSQL(var SQL: WideString);
   public
    constructor Create(DatabaseData: TSQLMemDatabaseData);
    destructor Destroy; override;
    procedure Load(stream: TStream; SkipSFMHeader: Boolean = False);
    procedure Save(ms: TSQLMemMemoryStream; bSkipSFMHeader: Boolean = False); overload;
    procedure Save(stream: TStream); overload;
    // for call from TSQLMemDatabase - SQLScript can include only SINGLE STORED FUNCTION
    procedure CreateStoredFunction(Session: TSQLMemBaseSession; SQLScript: WideString); overload;
    // for CREATE FUNCTON inside SQL script
    // current token is rwFUNCTION/rwPROCEDURE
    procedure CreateStoredFunction(
                  StoredFunction:   TSQLMemStoredFunction;
                  SQLScript:        WideString
                                  ); overload;
    // parse CREATE FUNCTION
    procedure ParseStoredFunction(
                  Session:              TSQLMemBaseSession;
                  Lexer:                TSQLMemLexer;
                  var Token:            TToken;
                  out StoredFunction:   TSQLMemStoredFunction;
                  out SQLScript:        WideString
                                 );
    // DROP stored function
    procedure DropStoredFunction(
                                    Session:      TSQLMemBaseSession;
                                    FunctionName: WideString
                                 );
    // ALTER stored function
    procedure AlterStoredFunction(
                                    Session:      TSQLMemBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                 );
    // ALTER stored function
    procedure AlterStoredFunctionRename(
                                    Session:          TSQLMemBaseSession;
                                    FunctionName,
                                    NewFunctionName:  WideString
                                 );
    // for calls from TSQLMemDatabase.ExecuteStoredFunction
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    // params - list of TSQLMemSQLParam
    function ExecuteStoredFunction(
                    Session:         TSQLMemBaseSession;
                    FunctionName:    WideString;
                    ResultValue:     TSQLMemVariant;
                    Params:          TSQLMemSQLParams
                                  ): Boolean; virtual;
    // return empty string if function not found; otherwise return SQL script (CREATE FUNCTION...)
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; virtual;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TSQLMemExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString; Session: TSQLMemBaseSession): TObject; virtual;
    // parse for execute - from SQL engine (EXECUTE FUNCTION / expression, like FunctionName(Params))
    // return stored function object (TSQLMemStoredFunction) if found or nil
    // params - list of TSQLMemExpression
    function ParseStoredFunctionParams(
                Session:          TSQLMemBaseSession;
                Lexer:            TSQLMemLexer;
                parentFunction:   TObject; // parent TSQLMemStoredFunction object, where parser was called
                var Token:        TToken;
                out Params:       TObject
                                      ): TObject; virtual;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload; virtual;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload; virtual;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); virtual;
  end; // TSQLMemStoredFunctionManager




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLAssign
//
// <variable> := <expression>;
//
// can be used in scripts (session variables only)
// and
// in stored functions (local variables, params, result, session variables)
//
////////////////////////////////////////////////////////////////////////////////



  TSQLMemSQLAssign = class (TSQLMemSQLCommand)
   private
     FVariable:          TSQLMemExprNode;
     FExpression:        TSQLMemExpression;
   protected
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
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
  end; // TSQLMemRSQLAssign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemRSQLBeginEndCommandsBlock
//
// <command_block>:
// BEGIN
//                    <COMMAND_1>;
//                    <COMMAND_2>;
// ...
//                    <COMMAND_N>;
// END
//
// used in stored functions
//
////////////////////////////////////////////////////////////////////////////////



  TSQLMemRSQLBeginEndCommandsBlock = class (TSQLMemSQLCommand)
   private
     FCommands: TList;
   protected
     // update parameter values in all expressions
     procedure UpdateParams(SQLParams: TSQLMemSQLParams); override;
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
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
  end; // TSQLMemRSQLBeginEndCommandsBlock




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLIfThenElse
//
// IF <Condition> THEN
//  <command> | <command_block> ;
// [
// ELSE
//  <command> | <command_block> ;
// ]
//
// <Condition>: <Boolean Expression>
// can be used in stored functions only
//
////////////////////////////////////////////////////////////////////////////////



  TSQLMemSQLIfThenElse = class (TSQLMemSQLCommand)
   private
     FIfCondition:  TSQLMemExpression;
     FThenCommand:  TSQLMemSQLCommand;
     FElseCommand:  TSQLMemSQLCommand;
   protected
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
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
  end; // TSQLMemSQLIfThenElse


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCreateStoredFunction
//
// Syntax:
//
// CREATE PROCEDURE <FunctionName> [(<Params>)] [: <ResultType>];
// -- or
// CREATE FUNCTION <FunctionName> [(<Params>)] [: <ResultType>];
// [var <local_variables>]
// <function_body>
//
// <Params>:          <Param1>;<Param2>;...;<ParamN>
// <ParamN>:          ParamName1[,ParamName2,...,ParamNameN] [: <ParamType>]) [ = <default_value>]
// <local_variables>: VarName1[,VarName2,...,VarNameN] [: <VarType>])
// <ParamType>:       ParamTypeName [(MaximumStringLength)]
// <VarType>:         VarTypeName [(MaximumStringLength)]
// <ResulType>:       ResultTypeName [(MaximumStringLength)]
//
// <function_body>:
// BEGIN
//                    <COMMAND_1>;
//                    <COMMAND_2>;
// ...
//                    <COMMAND_N>;
// END;
//
// <COMMAND>:         <variable> := <expr2>;
//                    SELECT ...
//                    INSERT ...
//                    UPDATE ...
//                    DELETE ...
//                    EXECUTE ...
// ... any supported SQL command
//
// function result variable: Result
// <variable>:        <local_variable> | <session_variable>
// <local_variable>:          VariableName
// <session_variable>:        @VariableName
// recursive function calls - NOT SUPPORTED
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemCreateStoredFunction = class (TSQLMemSQLCommand)
   private
     LCreateStoredFunction: TSQLMemStoredFunction; // parsed function
     FSQLScript:            WideString;
   protected
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
     // creates object
     constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
     // destroys object
     destructor Destroy; override;
     // parse query
     procedure Parse; override;
     // execute query
     procedure ExecSQL(
                        IsRoot,
                        RequestLive:  Boolean;
                        var ReadOnly: Boolean
                       ); override;
  end; // TSQLMemCreateStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDropStoredFunction
//
// Syntax:
// DROP FUNCTION <FunctionName>;
// - or
// DROP PROCEDURE <FunctionName>;
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemDropStoredFunction = class (TSQLMemSQLCommand)
   private
     FFunctionName: WideString;
   protected
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
     // parse query
     procedure Parse; override;
     // execute query
     procedure ExecSQL(
                        IsRoot,
                        RequestLive:  Boolean;
                        var ReadOnly: Boolean
                       ); override;
  end; // TSQLMemDropStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemAlterStoredFunction
//
// Syntax:
//
// ALTER FUNCTION <FunctionName> MODIFY '<New SQL Script>';
// ALTER FUNCTION <FunctionName> RENAME TO <New Name>;
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemAlterStoredFunction = class (TSQLMemSQLCommand)
   private
     FFunctionName:     WideString;
     FNewScript:        WideString;
     FNewFunctionName:  WideString;
     FAlterType:        TAlterType;
     FErrLine:          Integer;
     FErrColumn:        Integer;
   protected
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
     // creates object
     constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
      // destroys object
     destructor Destroy; override;
     // parse query
     procedure Parse; override;
     // execute query
     procedure ExecSQL(
                        IsRoot,
                        RequestLive:  Boolean;
                        var ReadOnly: Boolean
                       ); override;
  end; // TSQLMemAlterStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExecuteStoredFunction
//
// Syntax:
// EXECUTE FUNCTION <FunctionName> [(<Params>)];
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemExecuteStoredFunction = class (TSQLMemSQLCommand)
   private
     LExecuteStoredFunction:  TSQLMemStoredFunction;
     FParams:                 TSQLMemExpressions;    // function params
   protected
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TSQLMemSQLCommand; override;
   public
     procedure Assign(Source: TSQLMemSQLCommand); override;
     // creates object
     constructor Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
      // destroys object
     destructor Destroy; override;
     // parse query
     procedure Parse; override;
     // execute query
     procedure ExecSQL(
                        IsRoot,
                        RequestLive:  Boolean;
                        var ReadOnly: Boolean
                       ); override;
  end; // TSQLMemExecuteStoredFunction

// return true if text is a session variable name - starting from SQLMem_SES_VAR_SIGN
function SQLMemIsSessionVariable(text: WideString): Boolean;
// parse commads block (<command> or BEGIN <command #1>;...<command #N>; END;
procedure SQLMemParseCommandsBlock(
                        SQLProcessor:     TSQLMemBaseSQLProcessor;
                        Lexer:            TSQLMemLexer;
                        var token:        TToken;
                        var commandsList: TList
                               );

implementation

uses
      Math,
      SQLMemLocalEngine, SQLMemMain,
      SQLMemMemory; // last


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeVariable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeVariable.Create(
                                        aParentExpr:      TSQLMemExpression;
                                        aName:            WideString;
                                        aStoredFunction:  TSQLMemStoredFunction;
                                        aParamIndex:      Integer
                                       );
begin
  inherited Create(aParentExpr);
  FName := aName;
  LStoredFunction := aStoredFunction;
  FIsSessionVar := ((LStoredFunction = nil) and (SQLMemIsSessionVariable(FName)));
  FParamIndex := aParamIndex;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeVariable.Destroy;
begin
  SQLMemClearString(FName);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeVariable.GetDataValue: TSQLMemVariant;
var param: TSQLMemSQLParam;
begin
 if (LParentExpr = nil) then
  raise ESQLMemException.Create(12120,ErrorLNilPointer);
 if (FIsSessionVar) then
  begin
   param := LParentExpr.Session.SessionVariables.GetParamByName(FName);
   if (param <> nil) then
    begin
      param := LParentExpr.Session.SessionVariables.AddCreated;
      param.Name := FName;
    end;
  end
 else
  begin
   if (LParentExpr.LocalParams = nil) then
    raise ESQLMemException.Create(12123,ErrorLNilPointer);
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    raise ESQLMemException.Create(12121,ErrorLInvlidParameterIndex,
      [FName,FParamIndex,LParentExpr.LocalParams.Count]);
   param := LParentExpr.LocalParams[FParamIndex];
  end;
 Result := param;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeVariable.GetDataType: TSQLMemAdvancedFieldType;
var param: TSQLMemSQLParam;
begin
 if (LParentExpr = nil) then
  raise ESQLMemException.Create(12124,ErrorLNilPointer);
 if (FIsSessionVar) then
  begin
   param := LParentExpr.Session.SessionVariables.GetParamByName(FName);
   if (param <> nil) then
    begin
      param := LParentExpr.Session.SessionVariables.AddCreated;
      param.Name := FName;
    end;
   Result := param.AdvDataType;
  end
 else
  begin
   // modified in v.5.90
{$IFDEF EXPR_PARSING_1}
   if (LParentExpr.LocalParams = nil) then
    Result := aftUnknown
   else
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    Result := aftUnknown
   else
    Result := LParentExpr.LocalParams[FParamIndex].AdvDataType;
{$ELSE}
   if (LParentExpr.LocalParams = nil) then
    raise ESQLMemException.Create(12126,ErrorLNilPointer);
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    raise ESQLMemException.Create(12127,ErrorLInvlidParameterIndex,
      [FName,FParamIndex,LParentExpr.LocalParams.Count]);
   Result := LParentExpr.LocalParams[FParamIndex].AdvDataType;
{$ENDIF}
  end;
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeVariable.GetDataSize: Integer;
var param: TSQLMemSQLParam;
begin
 if (LParentExpr = nil) then
  raise ESQLMemException.Create(12125,ErrorLNilPointer);
 if (FIsSessionVar) then
  begin
   param := LParentExpr.Session.SessionVariables.GetParamByName(FName);
   if (param <> nil) then
    begin
      param := LParentExpr.Session.SessionVariables.AddCreated;
      param.Name := FName;
    end;
   Result := param.MaxStrLen;
  end
 else
  begin
   if (LParentExpr.LocalParams = nil) then
    raise ESQLMemException.Create(12128,ErrorLNilPointer);
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    raise ESQLMemException.Create(12129,ErrorLInvlidParameterIndex,
      [FName,FParamIndex,LParentExpr.LocalParams.Count]);
   Result := LParentExpr.LocalParams[FParamIndex].MaxStrLen;
  end;
end; // GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeVariable.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeVariable.Create(aParentExpr,'',nil,0);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeVariable.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  FName := TSQLMemExprNodeVariable(Source).FName;
  FIsSessionVar := TSQLMemExprNodeVariable(Source).FIsSessionVar;
  FParamIndex := TSQLMemExprNodeVariable(Source).FParamIndex;
  LStoredFunction := TSQLMemExprNodeVariable(Source).LStoredFunction;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExprNodeStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// find stored function
//------------------------------------------------------------------------------
function TSQLMemExprNodeStoredFunction.FindStoredFunction: TSQLMemStoredFunction;
var
    ses:              TSQLMemBaseSession;
begin
  Result := nil;
  ses := TSQLMemExpression(LParentExpr).Session;
  if (ses <> nil) then
   Result := TSQLMemStoredFunction(ses.GetStoredFunctionByName(FStoredFunctionName));
end; // FindStoredFunction


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemExprNodeStoredFunction.Create(
                          aParentExpr:          TSQLMemExpression;
                          aStoredFunctionName:  WideString;
//                          aStoredFunction:    TSQLMemStoredFunction;
                          aParams:              TSQLMemExpressions
                                              );
begin
  inherited Create(aParentExpr);
//  LStoredFunction := aStoredFunction;
  FStoredFunctionName := aStoredFunctionName;
  FParams := aParams;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemExprNodeStoredFunction.Destroy;
begin
  if (FParams <> nil) then
   try
     FParams.Free;
   except
   end;
{
  if (LStoredFunction <> nil) then
   try
    LStoredFunction.DecUseCount;
   except
   end;
}   
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// process assign AO
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStoredFunction.AssignAO(AO: TSQLMemAO);
var i: Integer;
begin
 if (FParams <> nil) then
  for i := 0 to FParams.Count-1 do
   FParams[i].AssignAO(AO);
end; // AssignAO


//------------------------------------------------------------------------------
// process assign Cursor
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStoredFunction.AssignCursor(Cursor: TSQLMemCursor);
var i: Integer;
begin
 if (FParams <> nil) then
  for i := 0 to FParams.Count-1 do
   FParams[i].AssignCursor(Cursor);
end; // AssignCursor


//------------------------------------------------------------------------------
// process assign New Cursor Buffer
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStoredFunction.AssignCursorBuffer(Buffer: TSQLMemRecordBuffer);
var i: Integer;
begin
 if (FParams <> nil) then
  for i := 0 to FParams.Count-1 do
   FParams[i].AssignCursorBuffer(Buffer);
end; // AssignCursorBuffer


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TSQLMemExprNodeStoredFunction.GetDataValue: TSQLMemVariant;
var localParams:      TSQLMemSQLParams;
    i:                Integer;
    storedFunction:   TSQLMemStoredFunction;
begin
  if (LParentExpr = nil) then
   raise ESQLMemException.Create(12122,ErrorLNilPointer);
  storedFunction := FindStoredFunction;
  if (storedFunction = nil) then
   raise ESQLMemException.Create(12472,ErrorLCannotFindFunction,[FStoredFunctionName]);
  localParams := storedFunction.GetParams;
  try
   if (FParams <> nil) then
    for i := 0 to FParams.Count-1 do
    begin
      TSQLMemExpression(FParams[i]).LocalParams := LParentExpr.LocalParams;
      localParams[i].Assign(FParams[i].GetValue(True),True);
    end;
    storedFunction.IncUseCount;
    try
      storedFunction.Execute(LParentExpr.Session,localParams,Value);
    finally
      storedFunction.DecUseCount;
    end;
    Result := Value;
  finally
    if (localParams <> nil) then
     localParams.Free;
  end;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TSQLMemExprNodeStoredFunction.GetDataType: TSQLMemAdvancedFieldType;
var storedFunction:   TSQLMemStoredFunction;
begin
  storedFunction := FindStoredFunction;
  if (storedFunction = nil) then
   raise ESQLMemException.Create(12473,ErrorLCannotFindFunction,[FStoredFunctionName]);
  Result := BaseFieldTypeToAdvancedFieldType(storedFunction.ResultType);
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TSQLMemExprNodeStoredFunction.GetDataSize: Integer;
var storedFunction:   TSQLMemStoredFunction;
begin
  storedFunction := FindStoredFunction;
  if (storedFunction = nil) then
   raise ESQLMemException.Create(12474,ErrorLCannotFindFunction,[FStoredFunctionName]);
  Result := storedFunction.ResultTypeSize;
end; // GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExprNodeStoredFunction.CreateCopy(aParentExpr: TSQLMemExpression): TSQLMemExprNode;
begin
  Result := TSQLMemExprNodeStoredFunction.Create(aParentExpr,'',nil);
  TSQLMemExprNodeStoredFunction(Result).FParams := TSQLMemExpressions.Create;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TSQLMemStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TSQLMemExprNodeStoredFunction.Assign(Source: TSQLMemExprNode);
begin
  inherited Assign(Source);
  if (TSQLMemExprNodeStoredFunction(Source).FParams <> nil) then
   FParams.Assign(TSQLMemExprNodeStoredFunction(Source).FParams);
//  LStoredFunction := TSQLMemExprNodeStoredFunction(Source).LStoredFunction;
  FStoredFunctionName := TSQLMemExprNodeStoredFunction(Source).StoredFunctionName;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemStoredFunction.Create(
                aFunctionName:    WideString;
                aParams:          TSQLMemSQLParams;
                aParamCount:      Integer;
                aResultType:      TSQLMemBaseFieldType;
                aResultTypeSize:  Integer;
                aCommands:        TList
                                              );
var param: TSQLMemSQLParam;
begin
  inherited Create;
  FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  FFunctionName := aFunctionName;
  FParams := aParams;
  FParamCount := aParamCount;
  FResultType := aResultType;
  FResultTypeSize := aResultTypeSize;
  if (FResultType <> bftUnknown) then
   begin
    if (FParams = nil) then
     FParams := TSQLMemSQLParams.Create;
    param := FParams.AddCreated;
    param.Name := GetReservedWord(rwRESULT);
    param.Clear(FResultType);
    if (FResultTypeSize > 0) then
     param.MaxStrLen := FResultTypeSize;
   end;
  FCommands := aCommands;
  FUseCount := 0;
  FFreeIfNotUsed := False;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemStoredFunction.Destroy;
begin
  Clear;
  SQLMemClearString(FFunctionName);
  FThreadSync.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// clear params and commands
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunction.Clear;
begin
  FThreadSync.Lock(True);
  try
    FUseCount := 0;
    if (FCommands <> nil) then
     begin
      SQLMemClearCommands(FCommands);
      FCommands.Free;
      FCommands := nil;
     end;
    if (FParams <> nil) then
    begin
      try
        FParams.Free;
      except
      end;
      FParams := nil;
    end;
  finally
    FThreadSync.Unlock;
  end;
end; // Clear


//------------------------------------------------------------------------------
// return nil if not found
//------------------------------------------------------------------------------
function TSQLMemStoredFunction.FindVariable(Name: WideString): TSQLMemSQLParam;
begin
  Result := nil;
  if (FParams <> nil) then
   Result := FParams.GetParamByName(Name);
end; // FindVariable


//------------------------------------------------------------------------------
// return parameter index
//------------------------------------------------------------------------------
function TSQLMemStoredFunction.GetParamIndex(Name: WideString): Integer;
begin
  Result := FParams.GetParamIndexByName(Name);
end; // GetParamIndex


//------------------------------------------------------------------------------
// create and return list of all paremeters with default values
//------------------------------------------------------------------------------
function TSQLMemStoredFunction.GetParams: TSQLMemSQLParams;
var i: Integer;
begin
  Result := nil;
  if (FParams <> nil) then
   begin
    Result := TSQLMemSQLParams.Create;
    for i := 0 to FParams.Count-1 do
     begin
      Result.AddCreated.Assign(FParams[i],True);
     end;
   end;
end; // GetParams


//------------------------------------------------------------------------------
// return nil if procedure or result object
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunction.Execute(
                      Session:      TSQLMemBaseSession;
                      CallParams:   TSQLMemSQLParams;
                      ResultValue:  TSQLMemVariant
                                    );
var i,cnt1,cnt2:  Integer;
    command:      TSQLMemSQLCommand;
    readOnly:     Boolean;
    res:          TSQLMemSQLParam;
begin
 cnt1 := 0;
 cnt2 := 0;
 if (FResultType <> bftUnknown) then
  if (ResultValue = nil) then
   raise ESQLMemException.Create(12118,ErrorLNilPointer);
 if (ResultValue <> nil) then
  ResultValue.Clear(FResultType);
 // check if all params are passed - it should be if they created by GetParams
 if (CallParams <> nil) then
    cnt1 := CallParams.Count;
 if (FParams <> nil) then
    cnt2 := FParams.Count;
 if (cnt1 <> cnt2) then
  raise ESQLMemException.Create(12114,ErrorLExecuteStoredFunctionInvalidParamsCount,
      [FFunctionName,cnt1,cnt2]);
 if (FCommands <> nil) then
  for i := 0 to FCommands.Count-1 do
   begin
    command := TSQLMemSQLCommand(FCommands.Items[i]).MakeCopy(Session,CallParams);
    if (command = nil) then
     raise ESQLMemException.Create(12186,ErrorLErrorMakeCopy,[command.ClassName,IntToHex(Integer(command),8)]);
    try
      readOnly := True;
      command.ExecSQL(True,True,readOnly);
    finally
      command.Free;
    end;
{
    command := FCommands.Items[i];
    Session.SetDatabaseParams(command.FDatabaseParams);
    readOnly := True;
    command.ExecSQL(Session,True,True,readOnly,CallParams);
}
   end;
 if (FResultType <> bftUnknown) then
  begin
    res := CallParams.GetParamByName(GetReservedWord(rwRESULT));
    if (res = nil) then
     raise ESQLMemException.Create(12117,ErrorLExecuteStoredFunctionNoResult,[FFunctionName]);
    ResultValue.Assign(res,True);
    if (ResultValue.DataType <> FResultType) then
     ResultValue.Cast(FResultType);
  end;
end; // Execute


//------------------------------------------------------------------------------
// increment UseCount
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunction.IncUseCount;
begin
 FThreadSync.WaitAndLockForWrite;
 try
   Inc(FUseCount);
 finally
   FThreadSync.Unlock;
 end;
end; // IncUseCount


//------------------------------------------------------------------------------
// decrement UseCount
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunction.DecUseCount;
begin
  FThreadSync.WaitAndLockForWrite;
  try
   if (FUseCount > 0) then
    Dec(FUseCount)
   else
    FUseCount := 0;
  finally
   FThreadSync.Unlock;
  end;
  if (FFreeIfNotUsed and (FUseCount <= 0)) then
   Free;
end; // DecUseCount




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStoredFunctionManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.Lock(Exclusive: Boolean);
begin
  FThreadSync.Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.Unlock;
begin
  FThreadSync.Unlock
end; // Unlock


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.Clear;
var sf:    TSQLMemStoredFunction;
    i:     Integer;
begin
  for i := 0 to FFunctions.Count-1 do
    if (FFunctions.Items[i] <> nil) then
     begin
      sf := TSQLMemStoredFunction(FFunctions.Items[i]);
      if (sf.UseCount <= 0) then
        sf.Clear;
     end;
  for i := 0 to FFunctions.Count-1 do
   begin
    if (FFunctions.Items[i] <> nil) then
     begin
      sf := TSQLMemStoredFunction(FFunctions.Items[i]);
      DestroyStoredFunction(sf);
     end;
   end;
  FFunctions.Clear;
  FFunctionNames.Clear;
  FFunctionSQL.Clear;
  FFunctionHeaders := nil;
end; // Clear


//------------------------------------------------------------------------------
// destroy stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.DestroyStoredFunction(var sf: TSQLMemStoredFunction);
begin
  if (sf <> nil) then
   begin
     if (sf.UseCount > 0) then
      sf.FreeIfNotUsed := True
     else
     try
       sf.Free;
     except
     end;
     sf := nil; 
   end;
end; // DestroyStoredFunction


//------------------------------------------------------------------------------
// parse CREATE FUNCTION | CREATE PROCEDURE
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.ParseCreateFunction(lexer: TSQLMemLexer; var token: TToken);
begin
  if (not IsReservedWord(token,rwCREATE)) then
    raise ESQLMemException.Create(12023,ErrorGOtherTokenExpected,
      [GetReservedWord(rwCREATE),token.Text,Token.LineNum,token.ColumnNum]);
  if (not lexer.GetNextToken(token)) then
    raise ESQLMemException.Create(12024,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  if ((not IsReservedWord(token,rwFUNCTION)) and (not IsReservedWord(token,rwPROCEDURE))) then
    raise ESQLMemException.Create(12025,ErrorGOtherTokenExpected,
      [GetReservedWord(rwFUNCTION),token.Text,token.LineNum,token.ColumnNum]);
end; // ParseCreateFunction


//------------------------------------------------------------------------------
// parse stored function name
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseFunctionName(lexer: TSQLMemLexer; var token: TToken): WideString;
begin
  if (not IsStringToken(token)) then
    raise ESQLMemException.Create(12027,ErrorLInvalidTokenType,[ESQLMemTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  Result := token.Text;
end; // ParseFunctionName;


//------------------------------------------------------------------------------
// parse parameter type size
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseFunctionParamTypeSize(lexer: TSQLMemLexer; var token: TToken): Integer;
var token1:             TToken;
begin
  Result := 0;
  // parse size
  if (lexer.LookNextToken(token1)) then
   if (token1.tokenType = tktLeftParenthesis) then
    begin
     // (
     lexer.GetNextToken(token);
     if (not lexer.GetNextToken(token)) then
      raise ESQLMemException.Create(12033,ErrorLCannotParseFunctionParametersSizeExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if (token.tokenType <> tktInt) then
      raise ESQLMemException.Create(12034,ErrorLCannotParseFunctionParametersSizeExpected,[token.Text,token.LineNum,token.ColumnNum]);
     //Size
     Result := StrToIntDef(token.Text,0);
     // )
     if (not lexer.GetNextToken(token)) then
      raise ESQLMemException.Create(12035,ErrorGRightParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if (token.TokenType <> tktRightParenthesis) then
      raise ESQLMemException.Create(12036,ErrorGRightParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
    end;
end; // ParseFunctionParamTypeSize


//------------------------------------------------------------------------------
// parse <default_value>
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseFunctionParamDefaultValue(lexer: TSQLMemLexer; var token: TToken): TSQLMemSQLParam;
var token1:             TToken;
begin
  Result := nil;
  // parse size
  if (lexer.LookNextToken(token1)) then
   if (token1.Text = '=') then
    begin
     // =
     lexer.GetNextToken(token);
     // default value
     if (not lexer.GetNextToken(token)) then
      raise ESQLMemException.Create(12038,ErrorLCannotParseFunctionParametersDefaultValueExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if ((token.TokenType <> tktQuotedString) and (token.tokenType <> tktInt) and (token.tokenType <> tktFloat)) then
      raise ESQLMemException.Create(12039,ErrorLCannotParseFunctionParametersDefaultValueExpected,[token.Text,token.LineNum,token.ColumnNum]);
     try
{
       if (token.tokenType = tktInt) then
        begin
         Result := TSQLMemSQLParam.Create(bftSignedInt64);
         Result.AsInt64 := StrToInt64Def(token.Text,0);
        end
       else
       if (token.tokenType = tktFloat) then
        begin
         Result := TSQLMemSQLParam.Create(bftDouble);
         Result.AsDouble := StrToFloat(token.Text);
        end
       else
        begin
         Result := TSQLMemSQLParam.Create(bftWideChar);
         Result.AsWideString := token.Text;
        end;
}
      Result := TSQLMemSQLParam.Create(bftWideChar);
      Result.AsWideString := token.Text;
     except
      Result.Free;
      Result := nil;
     end;
    end;
end; // ParseFunctionParamDefaultValue


//------------------------------------------------------------------------------
// parse function params or local variables
// if bParseParams true - parse params, otherwise parse local variables
// <Params>:          <Param1>;<Param2>;...;<ParamN>
// <ParamN>:          ParamName1[,ParamName2,...,ParamNameN] [: <ParamType>]) [ = <default_value>]
// Example:
// (Param1, Param2: Integer; Param3: CHAR(20); Param4: WIDECHAR = "aaa")
// or
// parse <local_variables>
// var <local_variables>: var <Var1>;<Var2>;...;<VarN>
//                        begin
// <VarN>:            VarName1[,VarName2,...,VarNameN] [: <ParamType>]) [ = <default_value>]
// Example:
// var Var1, Var2: Integer;
//     Var3: CHAR(20);
//     Var4: WIDECHAR = "aaa"
// begin
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.ParseFunctionParams(lexer: TSQLMemLexer; var token: TToken; bParseParams: Boolean; var params: TSQLMemSQLParams);

 procedure AddParamsToResult(
                  paramNames:   TSQLMemWideStringList;
                  paramType:    TSQLMemBaseFieldType;
                  paramList:    TSQLMemSQLParams;
                  paramSize:    Integer;
                  paramDefault: TSQLMemSQLParam
                  );
 var i:     Integer;
     param: TSQLMemSQLParam;
     name:  WideString;

 begin
  for i := 0 to paramNames.Count-1 do
   begin
    name := paramNames[i];
    if (paramList.GetParamByName(name) <> nil) then
     raise ESQLMemException.Create(12054,ErrorLIdentifierRedeclared,[name]);
    param := paramList.AddCreated;
    if (paramDefault <> nil) then
     begin
      param.Assign(paramDefault,True);
      if ((paramType <> bftUnknown) and
          (paramType <> paramDefault.DataType) and
          (not IsStringFieldType(paramType))) then
        param.Cast(paramType);
     end
    else
      param.SetNull(paramType);
    param.Name := name;
    if (paramSize > 0) then
     begin
      // to be able to set length
      param.MaxStrLen := paramSize;
     end;
   end;
  paramNames.Clear;
 end; // AddParamsToResult

var leftBracketCount:   Integer;
    rightBracketCount:  Integer;
    bParseParamName:    Boolean;
    bParseParamType:    Boolean;
    paramName:          WideString;
    paramType:          TSQLMemBaseFieldType;
    paramSize:          Integer;
    paramDefault:       TSQLMemSQLParam;
    paramNames:         TSQLMemWideStringList;

 function IsNotFinished: Boolean;
 begin
  if (bParseParams) then
   Result := (leftBracketCount <> rightBracketCount)
  else
   Result := not IsReservedWord(token,rwBEGIN);
 end; // IsNotFinished

begin
  if (bParseParams) then
   begin
    // : - means no parameters, result type is specified
    if (token.Text = Colon) or (token.TokenType = tktParameter) then
     Exit;
    if (token.TokenType <> tktLeftParenthesis) then
     raise ESQLMemException.Create(12028,ErrorGLeftParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
    leftBracketCount := 1;
   end // parse params
  else
   begin
    // local variables
    // BEGIN means no local variables
    if (IsReservedWord(token,rwBEGIN)) then
     Exit;
    if (not IsReservedWord(token,rwVAR)) then
     raise ESQLMemException.Create(12044,ErrorGOtherTokenExpected,[GetReservedWord(rwVAR),token.Text,token.LineNum,token.ColumnNum]);
    leftBracketCount := 0;
   end; // // local variables
  rightBracketCount := 0;
  paramSize := 0;
  bParseParamName := True;
  bParseParamType := False;
  paramNames := TSQLMemWideStringList.Create;
  try
    while (IsNotFinished) do
     begin
      if (not lexer.GetNextToken(token)) then
       begin
        if (not lexer.GetNextCommand) then
         break;
        if (not lexer.GetCurrentToken(token)) then
         continue;
       end;
      if (not bParseParams) then
       if (not IsNotFinished) then
        break; 
      if (token.TokenType = tktLeftParenthesis) then
       Inc(leftBracketCount)
      else
      if (token.TokenType = tktRightParenthesis) then
       Inc(rightBracketCount)
      else
      if (token.TokenType = tktComma) then
       continue
      else
      if (token.Text = Colon) then
       begin
        // :
        bParseParamName := False;
        bParseParamType := True;
       end
      else
      if ((bParseParamName) and (token.TokenType <> tktParameter)) then
       begin
        if (token.TokenType <> tktString) then
          raise ESQLMemException.Create(12030,ErrorLInvalidTokenType,[ESQLMemTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
        paramName := token.Text;
        paramNames.Add(paramName);
       end // bParseParamName
      else
      if ((bParseParamType) or (token.TokenType = tktParameter) or (token.TokenType = tktReservedWord)) then
       begin
        if ((token.TokenType <> tktString) and (token.TokenType <> tktParameter) and
            (token.TokenType <> tktReservedWord)) then
         raise ESQLMemException.Create(12031,ErrorLCannotParseFunctionParametersTypeExpected,[token.Text,token.LineNum,token.ColumnNum]);
        paramType := SQLStrToBft(token.Text);
        // parse size
        paramSize := ParseFunctionParamTypeSize(lexer,token);
        // parse default values
        paramDefault := ParseFunctionParamDefaultValue(lexer,token);
        if (params = nil) then
         params := TSQLMemSQLParams.Create;
        try
          AddParamsToResult(paramNames,paramType,params,paramSize,paramDefault);
        finally
         if (paramDefault <> nil) then
          paramDefault.Free;
        end;
        bParseParamName := True;
        bParseParamType := False;
       end // bParseParamName
     end; //  parse field types
    if (bParseParams) and (bParseParamName) and (leftBracketCount <> rightBracketCount) then
     raise ESQLMemException.Create(12032,ErrorGOtherTokenExpected,[Colon,token.Text,token.LineNum,token.ColumnNum]);
    if (bParseParams) and (leftBracketCount <> rightBracketCount) then
     raise ESQLMemException.Create(12029,ErrorLRightParenthesisNotFound,
      [token.Text,token.LineNum,token.ColumnNum,leftBracketCount,rightBracketCount]);
    if (bParseParamType) then
      AddParamsToResult(paramNames,bftUnknown,params,0,nil);
  finally
   paramNames.Free;
  end; // finally
end; // ParseFunctionParams


//------------------------------------------------------------------------------
// parse function result type and size
// <ResulType>:       ResultTypeName [(MaximumStringLength)]
// Example:
// : Char(25);
// ;
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.ParseResultType(lexer: TSQLMemLexer; var token: TToken; out FunctionType: TSQLMemBaseFieldType; out FunctionTypeSize: Integer);
begin
 // procedure
 FunctionType := bftUnknown;
 FunctionTypeSize := 0;
 // : ResultType [ (MaxSize) ]
 if ((token.Text = Colon) or (token.TokenType = tktParameter)) then
  begin
   if (token.TokenType <> tktParameter) then
    if (not lexer.GetNextToken(token)) then
     raise ESQLMemException.Create(12040,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
   if (UpperCase(AnsiString(token.Text)) = 'GUID') then
   begin
    FunctionType := bftChar;
    FunctionTypeSize := SQLMem_GUID_LENGTH;
    lexer.GetNextToken(token);
   end
   else
   begin
     FunctionType := SQLStrToBft(token.Text);
     if (FunctionType = bftUnknown) then
      raise ESQLMemException.Create(12041,ErrorLCannotParseFunctionResultTypeExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if (lexer.GetNextToken(token)) then
      begin
       if (token.tokenType <> tktLeftParenthesis) then
        raise ESQLMemException.Create(12064,ErrorGLeftParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
       lexer.GetNextToken(token);
       if (token.tokenType <> tktInt) then
        raise ESQLMemException.Create(12042,ErrorLCannotParseFunctionResultSizeExpected,[token.Text,token.LineNum,token.ColumnNum]);
       // parse size
       FunctionTypeSize := StrToIntDef(token.Text,0);
       lexer.GetNextToken(token);
       if (token.tokenType <> tktRightParenthesis) then
        raise ESQLMemException.Create(12065,ErrorGRightParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
       if (lexer.GetNextToken(token)) then
        raise ESQLMemException.Create(12043,ErrorGUnexpectedToken,[token.Text, token.LineNum,token.ColumnNum]);
      end;
   end;
  end
 else
  if (lexer.GetNextToken(token)) then
   raise ESQLMemException.Create(12061,ErrorGUnexpectedToken,[token.Text, token.LineNum,token.ColumnNum]);
 // fixed in v.5.80
 if (IsStringFieldType(FunctionType)) then
  if (FunctionTypeSize <= 0) then
   FunctionTypeSize := SQLMemExpressionMaxVarcharSize;
end; // ParseResultType


//------------------------------------------------------------------------------
// parse <function_body>
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseFunctionBody(
                                Session:          TSQLMemBaseSession;
                                Lexer:            TSQLMemLexer;
                                var Token:        TToken;
                                StoredFunction:   TSQLMemStoredFunction
                                ): TList;
var SQLProcessor: TSQLMemBaseSQLProcessor;
    command:      TSQLMemSQLCommand;
begin
  Result := nil;
  if (not IsReservedWord(token,rwBEGIN)) then
    raise ESQLMemException.Create(12048,ErrorGOtherTokenExpected,[GetReservedWord(rwBEGIN),token.Text,token.LineNum,token.ColumnNum]);
  if (not lexer.GetNextToken(token)) then
    raise ESQLMemException.Create(12049,ErrorLFunctionBodyExpected,[token.LineNum,token.ColumnNum]);
  if (not IsReservedWord(token,rwEND)) then
   begin
     Result := TList.Create;
     try
       SQLProcessor := TSQLMemBaseSQLProcessor.Create(storedFunction,Session);
       try
        while (not IsReservedWord(token,rwEND)) do
         begin
          command := SQLProcessor.ParseSQLCommand(lexer,token);
          lexer.GetCurrentToken(token);
          if (command = nil) then
           raise ESQLMemException.Create(12238,ErrorLCannotParseSQLCommand,
            [token.Text,token.LineNum,token.ColumnNum]);
          if (command is TSQLMemCreateStoredFunction) then
           raise ESQLMemException.Create(12113,ErrorLCreateFunctionIsNotAllowedInsideFunctionBody,[token.LineNum,token.ColumnNum]);
          Result.Add(command);
          if (not lexer.GetNextCommand) then
           raise ESQLMemException.Create(12052,ErrorLCannotParseFunctionBodyMissingEnd,[token.LineNum,token.ColumnNum]);
          if (not lexer.GetCurrentToken(token)) then
           raise ESQLMemException.Create(12053,ErrorLCannotParseFunctionBodyMissingEnd,[token.LineNum,token.ColumnNum]);
         end; // while
       finally
         SQLProcessor.Free;
       end;
     except
      SQLMemClearCommands(Result);
      Result.Free;
      Result := nil;
      raise;
     end;
   end;
end; // ParseCommands


//------------------------------------------------------------------------------
// parse create stored function
//
// Syntax:
//
// CREATE PROCEDURE <FunctionName> [(<Params>)] [: <ResultType>];
// -- or
// CREATE FUNCTION <FunctionName> [(<Params>)] [: <ResultType>];
// [var <local_variables>]
// <function_body>
//
// <Params>:          <Param1>;<Param2>;...;<ParamN>
// <ParamN>:          ParamName1[,ParamName2,...,ParamNameN] [: <ParamType>]) [ = <default_value>]
// <local_variables>: VarName1[,VarName2,...,VarNameN] [: <VarType>])
// <ParamType>:       ParamTypeName [(MaximumStringLength)]
// <VarType>:         VarTypeName [(MaximumStringLength)]
// <ResulType>:       ResultTypeName [(MaximumStringLength)]
//
// <function_body>:
// BEGIN
//                    <COMMAND_1>;
//                    <COMMAND_2>;
// ...
//                    <COMMAND_N>;
// END;
//
// <COMMAND>:         <variable> := <expr2>;
//                    SELECT ...
//                    INSERT ...
//                    UPDATE ...
//                    DELETE ...
//                    EXECUTE ...
// ... any supported SQL command
//
// function result variable: Result
// <variable>:        <local_variable> | <session_variable>
// <local_variable>:          VariableName
// <session_variable>:        @VariableName
// recursive function calls - SUPPORTED
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// base function for parsing SQL script using lexer
// if bCalledFromSQL set to true - current token is rwFUNCTION/rwPROCEDURE
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.InternalParseCreateStoredFunction(
                bCalledFromSQL:   Boolean;
                Session:          TSQLMemBaseSession;
                Lexer:            TSQLMemLexer;
                var Token:        TToken;
                bCreateFunction:  Boolean;
                out SQLScript:    WideString;
                out ErrorMessage: WideString
                  ): TSQLMemStoredFunction;
var
    name:             WideString;
    resultType:       TSQLMemBaseFieldType;
    resultSize:       Integer;
    params:           TSQLMemSQLParams;
    paramCount:       Integer;
    commands:         TList;
    bParseResultType: Boolean;
begin
  SQLScript := '';
  ErrorMessage := '';
  name := '';
  Result := nil;
  params := nil;
  commands := nil;
  try
    try
     if (not bCalledFromSQL) then
      begin
       // parse CREATE FUNCTION from the beginning of script (CREATE FUNCTION FunctionName ...)
       if (not lexer.GetNextCommand) then
        raise ESQLMemException.Create(12021,ErrorGBlankSqlCommand);
       if (not lexer.GetCurrentToken(token)) then
        raise ESQLMemException.Create(12022,ErrorGBlankSqlCommand);
       // parse CREATE FUNCTION | CREATE PROCEDURE
       ParseCreateFunction(lexer,token);
      end;
//     else
//      SQLScript := GetReservedWord(rwCREATE)+Space+GetReservedWord(rwFUNCTION);
     if (not lexer.GetNextToken(token)) then
      raise ESQLMemException.Create(12026,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
     // parse <FunctionName>
     name := ParseFunctionName(lexer,token);
     if (lexer.GetNextToken(token)) then
      begin
       // parse <Params>
       ParseFunctionParams(lexer,token,true,params);
       if (params = nil) then
        paramCount := 0
       else
        paramCount := params.Count;
       if (token.TokenType = tktRightParenthesis) then
        bParseResultType := lexer.GetNextToken(token)
       else
        bParseResultType := True;
       // parse <ResultType>
       if (bParseResultType) then
         ParseResultType(lexer,token,resultType,resultSize);
       // ; - next command (VAR or BEGIN)
       if (not lexer.GetNextCommand) then
        raise ESQLMemException.Create(12063,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
       if (not lexer.GetCurrentToken(token)) then
        raise ESQLMemException.Create(12066,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
       // parse <local_variables>
       ParseFunctionParams(lexer,token,false,params);
      end
     else
      begin
       if (lexer.GetNextCommand) then
        lexer.GetCurrentToken(token)
       else
        raise ESQLMemException.Create(12062,ErrorLFunctionBodyExpected,[token.LineNum,token.ColumnNum]);
      end;
     // create stored function
     Result := TSQLMemStoredFunction.Create(name,params,paramCount,resultType,resultSize,nil);
     // parse function body
     commands := ParseFunctionBody(Session,Lexer,Token,Result);
     Result.Commands := commands;
     commands := nil;
    except
     on e: Exception do
      begin
       ErrorMessage := e.Message;
       if (Result = nil) then
        begin
          if (params <> nil) then
           params.Free;
          if (commands <> nil) then
           begin
             SQLMemClearCommands(commands);
             commands.Free;
           end;
        end;
       if (Result <> nil) then
         Result.Free;
       Result := nil;
      end;
    end;
  finally
    SQLMemClearString(name);
    if (bCalledFromSQL) then
      SQLScript := Lexer.StopSaveScript(True);
  end;
end; // InternalParseCreateStoredFunction


//------------------------------------------------------------------------------
// base function for parsing SQL script with CREATE FUNCTION ...; ... BEGIN ... END;
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseCreateStoredFunction(
                    Session:          TSQLMemBaseSession;
                    SQLScript:        WideString;
                    bCreateFunction:  Boolean;
                    out ErrorMessage: WideString
                      ): TSQLMemStoredFunction;
var lexer:  TSQLMemLexer;
    token:  TToken;
    s:      WideString;
begin
  lexer := TSQLMemLexer.Create(SQLScript);
  try
    Result := InternalParseCreateStoredFunction(False,Session,lexer,token,
                bCreateFunction,s,ErrorMessage);
  finally
    lexer.Free;
  end;
end; // ParseCreateStoredFunction


//------------------------------------------------------------------------------
// return -1 if not found, otherwise return index in FunctionNames,FunctionSQL arrays
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.GetFunctionByName(Name: WideString): Integer;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := -1;
  crc := GetTableNameCRC(Name,True);
  for i := 0 to FHeader.Count-1 do
   if (FFunctionHeaders[i].NameCRC = crc) then
    begin
     Result := i;
     break;
    end;
end; // GetFunctionByName


//------------------------------------------------------------------------------
// parse function call parameters:
// FunctionName [(<call_params>)]
// <call_params>:     <call_param1>,<call_param2>,...,<call_paramN>
// <call_paramN>:     value expression
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseFunctionCallParams(
                        Session:          TSQLMemBaseSession;
                        Lexer:            TSQLMemLexer;
                        parentFunction:   TObject; // parent TSQLMemStoredFunction object, where parser was called
                        var Token:        TToken;
                        aStoredFunction:  TSQLMemStoredFunction
                                    ): TObject;
var i,paramNo:  Integer;
    expr:       TSQLMemExpression;
    exprList:   TSQLMemExpressions;
    paramCount: Integer;
    t:          TToken;
begin
  Result := nil;
  exprList := nil;
  paramCount := 0;
  try
    if (lexer.GetNextToken(token)) then
     if (token.TokenType = tktLeftParenthesis) then
       begin
        lexer.LookNextToken(t);
        // if () - no params
        if (t.TokenType <> tktRightParenthesis) then
         begin
          exprList := TSQLMemExpressions.Create;
          while (token.TokenType <> tktRightParenthesis) do
           begin
            // get next token
            if (not lexer.GetNextToken(token)) then
               raise ESQLMemException.Create(12091,ErrorLFunctionParameterExpectedButCommandTerminated,[token.LineNum,token.ColumnNum]);
            expr := exprList.AddCreated(Session,nil);
            expr.StoredFunction := TSQLMemStoredFunction(parentFunction);
            expr.ParseForValueExpression(lexer);
            // skipe last expression token
            if (not lexer.GetCurrentToken(token)) then
               raise ESQLMemException.Create(12096,ErrorLFunctionParameterExpectedButCommandTerminated,[token.LineNum,token.ColumnNum]);
            if ((token.TokenType <> tktRightParenthesis) and (token.TokenType <> tktComma)) then
               raise ESQLMemException.Create(12098,ErrorLFunctionParameterCommaRightParenthesis,[token.text,token.LineNum,token.ColumnNum]);
           end; // while
         end
        else
         lexer.GetNextToken(token);
        // get next token - skip ')'
        lexer.GetNextToken(token);
       end; // parse params
    if (exprList <> nil) then
      paramCount := exprList.Count;
    if (paramCount > aStoredFunction.ParamCount) then
      raise ESQLMemException.Create(12119,ErrorLExecuteStoredFunctionInvalidParamsCount,
            [aStoredFunction.FunctionName,paramCount,aStoredFunction.ParamCount]);
    // check if all parameters that were not passed to this function call
    // has default values        
    for i := paramCount to aStoredFunction.ParamCount-1 do
     if (aStoredFunction.Params[i].DataType = bftUnknown) then
      raise ESQLMemException.Create(12097,ErrorLParamaterMissed,
        [i+1,aStoredFunction.FunctionName,aStoredFunction.ParamCount,token.LineNum,token.ColumnNum]);
    Result := exprList;
  except
    on e: Exception do
     begin
      if (exprList <> nil) then
       try
         exprList.Free;
       except
       end;
      raise;
     end;
  end;
end; // ParseFunctionCallParams


//------------------------------------------------------------------------------
// create function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.InternalCreateStoredFunction(
                                StoredFunction: TSQLMemStoredFunction;
                                SQLScript:      WideString
                                      );
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise ESQLMemException.Create(12077,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise ESQLMemException.Create(12078,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise ESQLMemException.Create(12079,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise ESQLMemException.Create(12080,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  if (GetFunctionByName(StoredFunction.FunctionName) >= 0) then
   raise ESQLMemException.Create(12175,ErrorLFunctionAlreadyExists,[StoredFunction.FFunctionName]);
  FFunctions.Add(StoredFunction);
  FFunctionNames.Add(StoredFunction.FunctionName);
  FFunctionSQL.Add(SQLScript);
  Inc(FHeader.Count);
  if (FHeader.State < SQLMem_MAX_STATE) then
   Inc(FHeader.State)
  else
   FHeader.State := 0;
  SetLength(FFunctionHeaders,FHeader.Count);
  FFunctionHeaders[FHeader.Count-1].CreationDate := Now;
  FFunctionHeaders[FHeader.Count-1].LastModificationDate := FFunctionHeaders[FHeader.Count-1].CreationDate;
  FFunctionHeaders[FHeader.Count-1].NameCRC := GetTableNameCRC(StoredFunction.FunctionName,True);
  FFunctionHeaders[FHeader.Count-1].SQLCRC := GetTableNameCRC(SQLScript,False);
end; // InternalCreateStoredFunction


//------------------------------------------------------------------------------
// drop stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.InternalDropStoredFunction(FunctionName: WideString);
var itemNo: Integer;
    sf:     TSQLMemStoredFunction;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise ESQLMemException.Create(12081,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise ESQLMemException.Create(12082,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise ESQLMemException.Create(12083,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise ESQLMemException.Create(12084,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  itemNo := GetFunctionByName(FunctionName);
  if (itemNo < 0) then
   raise ESQLMemException.Create(12085,ErrorLCannotFindFunction,[FunctionName]);
  sf :=  TSQLMemStoredFunction(FFunctions.Items[itemNo]);
  DestroyStoredFunction(sf);
  FFunctionNames.Delete(itemNo);
  FFunctionSQL.Delete(itemNo);
  FFunctions.Delete(itemNo);
  // if not last - move headers after it to position-1
  if (itemNo < FHeader.Count-1) then
   Move(FFunctionHeaders[itemNo+1],FFunctionHeaders[itemNo],
       (FHeader.Count - 1 - itemNo)*SizeOf(TSQLMemStoredFunctionHeader));
  Dec(FHeader.Count);
  if (FHeader.State < SQLMem_MAX_STATE) then
   Inc(FHeader.State)
  else
   FHeader.State := 0;
  SetLength(FFunctionHeaders,FHeader.Count);
end; // InternalDropStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.InternalAlterStoredFunction(
                                    Session:      TSQLMemBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                                        );
var i,itemNo:     Integer;
    sf1,sf2:      TSQLMemStoredFunction;
    crc:          Cardinal;
    ErrorMessage: WideString;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise ESQLMemException.Create(12202,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise ESQLMemException.Create(12203,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise ESQLMemException.Create(12204,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise ESQLMemException.Create(12205,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  crc := GetTableNameCRC(FunctionName,True);
  itemNo := -1;
  for i := 0 to Integer(FHeader.Count)-1 do
   begin
    if (FFunctionHeaders[i].NameCRC = crc) then
     begin
      itemNo := i;
      break;
     end;
   end;
  if (itemNo < 0) then
   raise ESQLMemException.Create(12206,ErrorLCannotFindFunction,[FunctionName]);
  ErrorMessage := '';
  sf1 := ParseCreateStoredFunction(Session,NewSQLScript,True,ErrorMessage);
  if (sf1 = nil) then
    raise ESQLMemException.Create(12207,ErrorLErrorParsingStoredFunction,[errorMessage,NewSQLScript]);
  sf2 := FFunctions.Items[itemNo];
  DestroyStoredFunction(sf2);
  crc := GetTableNameCRC(NewSQLScript);
  FFunctions.Items[itemNo] := sf1;
  FFunctionSQL[itemNo] := NewSQLScript;
  FFunctionHeaders[itemNo].LastModificationDate := Now;
  FFunctionHeaders[itemNo].SQLCRC := crc;
end; // InternalAlterStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function - rename
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.InternalAlterStoredFunctionRename(
                                    Session:          TSQLMemBaseSession;
                                    FunctionName,
                                    NewFunctionName:  WideString
                                                    );
var i,itemNo: Integer;
    crc:      Cardinal;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise ESQLMemException.Create(12218,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise ESQLMemException.Create(12219,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise ESQLMemException.Create(12220,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise ESQLMemException.Create(12221,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  crc := GetTableNameCRC(FunctionName,True);
  itemNo := -1;
  for i := 0 to FHeader.Count-1 do
   if (FFunctionHeaders[i].NameCRC = crc) then
     begin
      itemNo := i;
      break;
     end;
  if (itemNo < 0) then
   raise ESQLMemException.Create(12222,ErrorLCannotFindFunction,[FunctionName]);
  crc := GetTableNameCRC(NewFunctionName,True);
  FFunctionHeaders[itemNo].NameCRC := crc;
  FFunctionNames[itemNo] := NewFunctionName;
end; // InternalAlterStoredFunctionRename


//------------------------------------------------------------------------------
// return nil if not found, otherwise return TSQLMemStoredFunction object from FFunctions
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.InternalGetStoredFunctionByName(FunctionName: WideString; Session: TSQLMemBaseSession): TSQLMemStoredFunction;
var
    itemNo:       Integer;
    SQLScript:    WideString;
    ErrorMessage: WideString;
begin
  ErrorMessage := '';
  Result := nil;
  itemNo := GetFunctionByName(FunctionName);
  if (itemNo >= 0) then
   begin
     Result := TSQLMemStoredFunction(FFunctions.Items[itemNo]);
     if (Result = nil) then
      begin
        // parse function from SQL script
        SQLScript := FFunctionSQL.Strings[itemNo];
        Result := ParseCreateStoredFunction(Session,SQLScript,False,ErrorMessage);
        if (Result = nil) then
          raise ESQLMemException.Create(12086,ErrorLErrorParsingStoredFunction,[errorMessage,SQLScript]);
        FFunctions.Items[itemNo] := Result;
      end;
   end;
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// get all stored functions
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.InternalGetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList; SortNamesByAlphabet: Boolean);
var i,itemNo: Integer;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise ESQLMemException.Create(12069,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise ESQLMemException.Create(12070,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise ESQLMemException.Create(12071,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise ESQLMemException.Create(12072,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  if (FunctionNames.Count > 0) then
   FunctionNames.Clear;
  if (FunctionSQLScripts <> nil) then
    if (FunctionSQLScripts.Count > 0) then
     FunctionSQLScripts.Clear;
  for i := 0 to Integer(FHeader.Count)-1 do
   begin
    FunctionNames.Add(FFunctionNames.Strings[i]);
    if (not SortNamesByAlphabet) then
     if (FunctionSQLScripts <> nil) then
      FunctionSQLScripts.Add(FFunctionSQL.Strings[i]);
   end;
  if (SortNamesByAlphabet) then
   begin
     FunctionNames.Sort;
     if (FunctionSQLScripts <> nil) then
       for i := 0 to FunctionNames.Count-1 do
        begin
         itemNo := GetFunctionByName(FunctionNames[i]);
         if (itemNo < 0) then
          raise ESQLMemException.Create(12068,ErrorLCannotFindFunction,[FunctionNames[i]]);
         FunctionSQLScripts.Add(FFunctionSQL.Strings[itemNo]);
        end;
   end;
end; //InternalGetStoredFunctions


//------------------------------------------------------------------------------
// export all functions to SQL
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.InternalExportStoredFunctionsToSQL(var SQL: WideString);
var i: Integer;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise ESQLMemException.Create(12134,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise ESQLMemException.Create(12135,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise ESQLMemException.Create(12136,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise ESQLMemException.Create(12137,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  for i := 0 to Integer(FHeader.Count)-1 do
   begin
    if (SQL = '') then
     SQL := FFunctionSQL.Strings[i]
    else
     SQL := SQL + CRLF + FFunctionSQL.Strings[i];
   end;
end; // InternalExportStoredFunctionsToSQL


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemStoredFunctionManager.Create(DatabaseData: TSQLMemDatabaseData);
begin
  LDatabaseData := DatabaseData;
  FThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self);
//  FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  FFunctionNames := TSQLMemObjectNameArray.Create;
  FFunctionSQL := TSQLMemObjectNameArray.Create;
  FFunctions := TList.Create;
  FFunctionHeaders := nil;
  FillChar(FHeader,SizeOf(FHeader),$00);
  FTempFunctions := TList.Create;
  FTempNamesCRC := TSQLMemIntegerArray.CReate;
  FTempSQLCRC := TSQLMemIntegerArray.CReate;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemStoredFunctionManager.Destroy;
begin
  Clear;
  FillChar(FHeader,SizeOf(FHeader),$00);
  FTempFunctions.Free;
  FTempNamesCRC.Free;
  FTempSQLCRC.Free;
  FThreadSync.Free;
  FFunctionNames.Free;
  FFunctionSQL.Free;
  FFunctions.Free;
  FFunctionHeaders := nil;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// load all data from stream
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.Load(stream: TStream; SkipSFMHeader: Boolean);
var i,j,dataSize:             Integer;
    headerSize:               Int64;
    nameCRC,SQLCRC:           Cardinal;
    sf:                       TSQLMemStoredFunction;
begin
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('> TSQLMemStoredFunctionManager.Load');
try
{$ENDIF}
  // backup existing functions
  FTempFunctions.Clear;
  FTempNamesCRC.SetSize(0);
  FTempSQLCRC.SetSize(0);
  for i := 0 to FFunctions.Count-1 do
   if (FFunctions.Items[i] <> nil) then
    begin
     FTempFunctions.Add(FFunctions.Items[i]);
     FTempNamesCRC.Add(Integer(FFunctionHeaders[i].NameCRC));
     FTempSQLCRC.Add(Integer(FFunctionHeaders[i].SQLCRC));
    end;
  FFunctions.Clear;
  Clear;
  try
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('1 TSQLMemStoredFunctionManager.Load, stream.Size = '+IntToStr(stream.Size)+#13#10+'SkipSFMHeader = '+BoolToStr(SkipSFMHeader,True));
{$ENDIF}
    if (not SkipSFMHeader) then
      LoadDataFromStream(FHeader,SizeOf(FHeader),stream,12013);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('2 TSQLMemStoredFunctionManager.Load, stream.Size = '+IntToStr(stream.Size)
+#13#10+'FHeader.Count = '+IntToStr(FHeader.Count)
+#13#10+'FHeader.State = '+IntToStr(FHeader.State)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
    headerSize := Int64(FHeader.Count) * Int64(SizeOf(TSQLMemStoredFunctionHeader));
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('3 TSQLMemStoredFunctionManager.Load, headerSize = '+IntToStr(headerSize));
{$ENDIF}
    if (Stream.Position + headerSize > Stream.Size) then
     raise ESQLMemException.Create(12471,ErrorLCannotLoadStoredFunctionsSmallStream,[stream.Position,stream.Size,headerSize,FHeader.Count]);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('3.1 TSQLMemStoredFunctionManager.Load, headerSize = '+IntToStr(headerSize));
{$ENDIF}
    SetLength(FFunctionHeaders,FHeader.Count);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('3.2 TSQLMemStoredFunctionManager.Load, headerSize = '+IntToStr(headerSize));
{$ENDIF}
    if (FHeader.Count > 0) then
    begin
      LoadDataFromStream(FFunctionHeaders[0],headerSize,stream,12014);
    end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('4 TSQLMemStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
{$ENDIF}
    try
      FFunctionNames.LoadFromStream(stream);
    except
      on e: Exception do
       raise ESQLMemException.Create(12015,ErrorLCannotLoadStoredFunctions,[e.Message]);
    end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('5 TSQLMemStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
{$ENDIF}
    try
      FFunctionSQL.LoadFromStream(stream);
    except
      on e: Exception do
       raise ESQLMemException.Create(12016,ErrorLCannotLoadStoredFunctions,[e.Message]);
    end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('6 TSQLMemStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
{$ENDIF}
    // restore functions that were already parsed if they were not changed by other users
    for j := 0 to FHeader.Count-1 do
     begin
      sf := nil;
      for i := 0 to FTempFunctions.Count-1 do
       begin
        nameCRC := Cardinal(FTempNamesCRC.Items[i]);
        SQLCRC := Cardinal(FTempNamesCRC.Items[i]);
        if (FFunctionHeaders[j].NameCRC = nameCRC) then
         begin
           sf := FTempFunctions.Items[i];
           // check if function was modified
           if (FFunctionHeaders[j].SQLCRC <> SQLCRC) then
             DestroyStoredFunction(sf);
         end;
       end;
      FFunctions.Add(sf);
     end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('7 TSQLMemStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
{$ENDIF}
    FTempFunctions.Clear;
    FTempNamesCRC.SetSize(0);
    FTempSQLCRC.SetSize(0);
  except
    FTempFunctions.Clear;
    FTempNamesCRC.SetSize(0);
    FTempSQLCRC.SetSize(0);
    Clear;
    raise;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Load}
aaWriteToLog('< TSQLMemStoredFunctionManager.Load');
except
 on e:Exception do
 begin
   aaWriteToLog('Error in TSQLMemStoredFunctionManager.Load:'+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // Load


//------------------------------------------------------------------------------
// save all data to stream
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.Save(ms: TSQLMemMemoryStream; bSkipSFMHeader: Boolean);
var headerSize,dataSize: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('> TSQLMemStoredFunctionManager.Save(ms)');
try
{$ENDIF}
  headerSize := FHeader.Count * SizeOf(TSQLMemStoredFunctionHeader);
  dataSize := SizeOf(FHeader) + headerSize;
  dataSize := dataSize + FFunctionNames.SaveToStream(ms,True);
  dataSize := dataSize + FFunctionSQL.SaveToStream(ms,True);

  ms.Size := dataSize;
  ms.Position := 0;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('1 TSQLMemStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
);
{$ENDIF}
  if (not bSkipSFMHeader) then
    SaveDataToStream(FHeader,SizeOf(FHeader),ms,11991);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('2 TSQLMemStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
+#13#10+'FHeader.Count = '+IntToStr(FHeader.Count)
+#13#10+'FHeader.State = '+IntToStr(FHeader.State)
);
{$ENDIF}
  if (FHeader.Count > 0) then
    SaveDataToStream(FFunctionHeaders[0],headerSize,ms,11992);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('3 TSQLMemStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
);
{$ENDIF}
  try
    FFunctionNames.SaveToStream(ms);
  except
    on e: Exception do
      raise ESQLMemException.Create(11994,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('4 TSQLMemStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
);
{$ENDIF}
  try
    FFunctionSQL.SaveToStream(ms);
  except
    on e: Exception do
      raise ESQLMemException.Create(11995,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('< TSQLMemStoredFunctionManager.Save(ms)');
except
 on e:Exception do
 begin
   aaWriteToLog('Error in TSQLMemStoredFunctionManager.Save(ms):'+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // Save


//------------------------------------------------------------------------------
// save all data to stream
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.Save(stream: TStream);
var headerSize,dataSize: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('> TSQLMemStoredFunctionManager.Save(stream)');
try
{$ENDIF}
  headerSize := FHeader.Count * SizeOf(TSQLMemStoredFunctionHeader);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('1 TSQLMemStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
+#13#10+'headerSize = '+IntToStr(headerSize)
);
{$ENDIF}
  SaveDataToStream(FHeader,SizeOf(FHeader),stream,12017);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('2 TSQLMemStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
  if (FHeader.Count > 0) then
    SaveDataToStream(FFunctionHeaders[0],headerSize,stream,12018);
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('3 TSQLMemStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
  try
    FFunctionNames.SaveToStream(stream);
  except
    on e: Exception do
      raise ESQLMemException.Create(12019,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('4 TSQLMemStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
  try
    FFunctionSQL.SaveToStream(stream);
  except
    on e: Exception do
      raise ESQLMemException.Create(12020,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TSQLMemStoredFunctionManager_Save}
aaWriteToLog('< TSQLMemStoredFunctionManager.Save(stream)');
except
 on e:Exception do
 begin
   aaWriteToLog('Error in TSQLMemStoredFunctionManager.Save(stream):'+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // Save


//------------------------------------------------------------------------------
// create stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.CreateStoredFunction(Session: TSQLMemBaseSession; SQLScript: WideString);
var storedFunction: TSQLMemStoredFunction;
    errorMessage:   WideString;
begin
  storedFunction := ParseCreateStoredFunction(Session,SQLScript,True,errorMessage);
  if (storedFunction = nil) then
   raise ESQLMemException.Create(12012,ErrorLErrorParsingStoredFunction,[errorMessage,SQLScript]);
  Lock(True);
  try
    InternalCreateStoredFunction(storedFunction,SQLScript);
  finally
    Unlock;
  end;
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// for CREATE FUNCTON inside SQL script
// current token is rwFUNCTION/rwPROCEDURE
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.CreateStoredFunction(
                  StoredFunction:   TSQLMemStoredFunction;
                  SQLScript:        WideString
                              );
begin
  Lock(True);
  try
    InternalCreateStoredFunction(StoredFunction,SQLScript);
  finally
    Unlock;
  end;
end; // CreateStoredFunction


//------------------------------------------------------------------------------
// parse stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.ParseStoredFunction(
              Session:              TSQLMemBaseSession;
              Lexer:                TSQLMemLexer;
              var Token:            TToken;
              out StoredFunction:   TSQLMemStoredFunction;
              out SQLScript:        WideString
                             );
var
    errorMessage:   WideString;
begin
  StoredFunction := InternalParseCreateStoredFunction(
                      True,Session,Lexer,Token,True,SQLScript,errorMessage);
  if (storedFunction = nil) then
   raise ESQLMemException.Create(12103,ErrorLErrorParsingStoredFunction,[errorMessage,SQLScript]);
  if (Length(SQLScript) <= 0) then
   begin
     errorMessage := StoredFunction.FunctionName;
     StoredFunction.Free;
     raise ESQLMemException.Create(12112,ErrorLErrorParsingStoredFunctionEmptyScript,
            [errorMessage,Token.Text,Token.LineNum,Token.ColumnNum]);
   end;
end; // ParseStoredFunction


//------------------------------------------------------------------------------
// drop stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.DropStoredFunction(
                                    Session:      TSQLMemBaseSession;
                                    FunctionName: WideString
                                 );
begin
  Lock(True);
  try
    InternalDropStoredFunction(FunctionName);
  finally
    Unlock;
  end;
end; // DropStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.AlterStoredFunction(
                                    Session:      TSQLMemBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                                        );
begin
  Lock(True);
  try
    InternalAlterStoredFunction(Session, FunctionName, NewSQLScript);
  finally
    Unlock;
  end;
end; // AlterStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.AlterStoredFunctionRename(
                                Session:          TSQLMemBaseSession;
                                FunctionName,
                                NewFunctionName:  WideString
                             );
begin
  Lock(True);
  try
    InternalAlterStoredFunctionRename(Session, FunctionName, NewFunctionName);
  finally
    Unlock;
  end;
end; // AlterStoredFunctionRename


//------------------------------------------------------------------------------
// for calls from TSQLMemDatabase.ExecuteStoredFunction
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
// params - list of TSQLMemSQLParam
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ExecuteStoredFunction(
                                    Session:          TSQLMemBaseSession;
                                    FunctionName:     WideString;
                                    ResultValue:      TSQLMemVariant;
                                    Params:           TSQLMemSQLParams
                                                        ): Boolean;
var i:            Integer;
    sf:           TSQLMemStoredFunction;
    localParams:  TSQLMemSQLParams;
begin
  if (Params <> nil) then
   begin
    if (not (TObject(Params) is TSQLMemSQLParams)) then
     raise ESQLMemException.Create(12198,ErrorLInvalidClass,
      ['TSQLMemSQLParams',TObject(Params).ClassName,IntToHex(Integer(Params),8)]);
   end;
  sf := nil;
  Result := False;
  Lock(False);
  try
    sf := InternalGetStoredFunctionByName(FunctionName,Session);
    if (sf <> nil) then
     sf.IncUseCount;
  finally
    Unlock;
  end;
  if (sf <> nil) then
    try
      Result := True;
      localParams := sf.GetParams;
      try
       if (localParams <> nil) and (Params <> nil) then
        for i := 0 to Params.Count-1 do
         if (i < localParams.Count) then
          localParams.Items[i].Assign(Params.Items[i],True);
        sf.Execute(Session,localParams,ResultValue);
      finally
        localParams.Free;
      end;
    finally
      sf.DecUseCount;
    end;
end; // ExecuteStoredFunction


//------------------------------------------------------------------------------
// return empty string if function not found; otherwise
// return SQL script that created this function (CREATE FUNCTION ...)
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.FindStoredFunction(FunctionName: WideString): WideString;
var itemNo: Integer;
begin
  Result := '';
  Lock(False);
  try
    if (FHeader.Count <> FFunctionNames.Count) then
     raise ESQLMemException.Create(12073,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
    if (FHeader.Count <> FFunctionSQL.Count) then
     raise ESQLMemException.Create(12074,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
    if (FHeader.Count <> FFunctions.Count) then
     raise ESQLMemException.Create(12075,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
    if (FHeader.Count <> Length(FFunctionHeaders)) then
     raise ESQLMemException.Create(12076,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
    itemNo := GetFunctionByName(FunctionName);
    if (itemNo >= 0) then
     Result := FFunctionSQL.Strings[itemNo];
  finally
    Unlock;
  end;
end; // FindStoredFunction


//------------------------------------------------------------------------------
// return the stored function object if it exists in stored function manager associated with
// the atabase opened by this session
// used by TSQLMemExprNodeStoredFunction
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.GetStoredFunctionByName(FunctionName: WideString; Session: TSQLMemBaseSession): TObject;
var itemNo: Integer;
begin
  Result := nil;
  Lock(False);
  try
     Result := InternalGetStoredFunctionByName(FunctionName,Session);
  finally
    Unlock;
  end;
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// parse for execute
// return stored function object (TSQLMemStoredFunction) if found or nil
// params - list of TSQLMemExpression
//------------------------------------------------------------------------------
function TSQLMemStoredFunctionManager.ParseStoredFunctionParams(
                Session:          TSQLMemBaseSession;
                Lexer:            TSQLMemLexer;
                parentFunction:   TObject; // parent TSQLMemStoredFunction object, where parser was called
                var Token:        TToken;
                out Params:       TObject
                                  ): TObject;
begin
  Result := nil;
  Params := nil;
  Lock(False);
  try
    Result := GetStoredFunctionByName(token.Text,Session);
{
    if (Result <> nil) then
     TSQLMemStoredFunction(Result).IncUseCount;
}     
  finally
    Unlock;
  end;
  // parse params
  if (Result <> nil) then
    Params := ParseFunctionCallParams(Session,Lexer,parentFunction,Token,TSQLMemStoredFunction(Result));
end; // ParseStoredFunctionParams


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings; SortNamesByAlphabet: Boolean);
var names, scripts: TSQLMemWideStringList;
begin
  if (FunctionNames = nil) then
   raise ESQLMemException.Create(12111,ErrorLNilPointer)
  else
   names := TSQLMemWideStringList.Create;
  if (FunctionSQLScripts = nil) then
   scripts := nil
  else
   scripts := TSQLMemWideStringList.Create;
  try
    GetStoredFunctions(names,scripts,SortNamesByAlphabet);
    names.ExportToTstrings(FunctionNames);
    if (scripts <> nil) then
      scripts.ExportToTstrings(FunctionSQLScripts);
  finally
   names.Free;
   if (scripts <> nil) then
    scripts.Free;
  end;
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.GetStoredFunctions(FunctionNames: TSQLMemWideStringList; FunctionSQLScripts: TSQLMemWideStringList; SortNamesByAlphabet: Boolean);
begin
  if (FunctionNames = nil) then
   raise ESQLMemException.Create(12067,ErrorLNilPointer);
  Lock(False);
  try
    InternalGetStoredFunctions(FunctionNames,FunctionSQLScripts,SortNamesByAlphabet);
  finally
    Unlock;
  end;
end; // GetStoredFunctions


//------------------------------------------------------------------------------
// export all stored functions to SQL
//------------------------------------------------------------------------------
procedure TSQLMemStoredFunctionManager.ExportStoredFunctionsToSQL(var SQL: WideString);
begin
  Lock(False);
  try
    InternalExportStoredFunctionsToSQL(SQL);
  finally
    Unlock;
  end;
end; // ExportStoredFunctionsToSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLAssign
//
// <variable> := <expression;
//
// can be used in scripts (session variables only)
// and
// in stored functions (local variables, params, result, session variables)
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLAssign.UpdateExpressionParams;
begin
 if (FExpression <> nil) then
  begin
    FExpression.StoredFunction := LStoredFunction;
    FExpression.LocalParams := LParams;
    FExpression.Session := FDatabaseParams.Session;
    FExpression.UpdateExpressionParams;
  end;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLAssign.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemSQLAssign.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLAssign.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  if (FVariable <> nil) then
   FreeAndNil(FVariable);
  if (FExpression <> nil) then
   FreeAndNil(FExpression);
  if (TSQLMemSQLAssign(Source).FVariable <> nil) then
   begin
    FVariable := TSQLMemExprNodeVariable.Create(nil,'',nil,0);
    FVariable.Assign(TSQLMemSQLAssign(Source).FVariable);
   end;
  if (TSQLMemSQLAssign(Source).FExpression <> nil) then
   begin
    FExpression := TSQLMemExpression.Create;
    FExpression.Assign(TSQLMemSQLAssign(Source).FExpression);
   end;
  FVariable.ParentExpr := FExpression;
end; // Assign


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemSQLAssign.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  FVariable := nil;
  FExpression := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemSQLAssign.Destroy;
begin
  if (FExpression <> nil) then
  begin
   FExpression.Free;
   FExpression := nil;
  end;
  if (FVariable <> nil) then
  begin
   FVariable.Free;
   FVariable := nil;
  end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLAssign.Parse;
var token:        TToken;
    paramIndex:   Integer;
    isSessionVar: Boolean;
begin
  if (not LLex.GetCurrentToken(token)) then
   raise ESQLMemException.Create(12056,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  // parse variable name
  if (token.TokenType = tktString) or (IsReservedWord(token,rwResult)) then
   begin
    FVariable := nil;
    isSessionVar := SQLMemIsSessionVariable(token.Text);
    if (isSessionVar) then
     begin
       FVariable := TSQLMemExprNodeVariable.Create(nil,Token.Text,nil,-1);
     end
    else
     begin
       if (LStoredFunction <> nil) then
        begin
         paramIndex := TSQLMemStoredFunction(LStoredFunction).GetParamIndex(Token.Text);
         if (paramIndex >= 0) then
           FVariable := TSQLMemExprNodeVariable.Create(nil,Token.Text,
                          TSQLMemStoredFunction(LStoredFunction),paramIndex);
        end;
     end;
    if (FVariable = nil) then
      raise ESQLMemException.Create(12055,ErrorLVariableNotFound,[token.Text]);
   end
  else
   raise ESQLMemException.Create(12057,ErrorLVariableNameExpected,[token.Text,token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12058,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  // :=
  if (token.TokenType <> tktAssign) then
   raise ESQLMemException.Create(12059,ErrorGOtherTokenExpected,
         [':=',token.Text,Token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12060,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  FExpression := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
  FExpression.StoredFunction := LStoredFunction;
  FExpression.ParseForValueExpression(LLex);
  FVariable.ParentExpr := FExpression;
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    begin
      LParamExprNodes := TSQLMemList.Create;
      FExpression.ExtractAllParameterNodes(LParamExprNodes);
    end;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemSQLAssign.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
var
    v:   TSQLMemVariant;
begin
 FExpression.Session := FDatabaseParams.Session;
 FExpression.LocalParams := Params;
 v := FVariable.GetDataValue;
 // assign only value, do not copy name
 v.Assign(FExpression.GetValue,True,False);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemRSQLBeginEndCommandsBlock
//
// <command_block>:
// BEGIN
//                    <COMMAND_1>;
//                    <COMMAND_2>;
// ...
//                    <COMMAND_N>;
// END
//
// used in stored functions
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// update parameter values in all expressions
//------------------------------------------------------------------------------
procedure TSQLMemRSQLBeginEndCommandsBlock.UpdateParams(SQLParams: TSQLMemSQLParams);
var i: Integer;
begin
  for i := 0 to FCommands.Count-1 do
    TSQLMemSQLCommand(FCommands.Items[i]).UpdateParams(SQLParams);
end; // UpdateParams


//------------------------------------------------------------------------------
// update expression params
//------------------------------------------------------------------------------
procedure TSQLMemRSQLBeginEndCommandsBlock.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to FCommands.Count-1 do
    TSQLMemSQLCommand(FCommands.Items[i]).UpdateExpressionParams;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemRSQLBeginEndCommandsBlock.CreateCopy: TSQLMemSQLCommand;
begin
  Result := TSQLMemRSQLBeginEndCommandsBlock.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemRSQLBeginEndCommandsBlock.Assign(Source: TSQLMemSQLCommand);
var i:       Integer;
    command: TSQLMemSQLCommand;
begin
  inherited Assign(Source);
  SQLMemClearCommands(FCommands);
  for i := 0 to TSQLMemRSQLBeginEndCommandsBlock(Source).FCommands.Count-1 do
    begin
      command := TSQLMemRSQLBeginEndCommandsBlock(Source).FCommands.Items[i];
      command := command.MakeCopy(FDatabaseParams.Session,LParams);
      FCommands.Add(command);
    end;
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TSQLMemRSQLBeginEndCommandsBlock.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  FCommands := TList.Create;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemRSQLBeginEndCommandsBlock.Destroy;
begin
  if (FCommands <> nil) then
   begin
    SQLMemClearCommands(FCommands);
    FreeAndNil(FCommands);
   end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemRSQLBeginEndCommandsBlock.Parse;
var
    SQLProcessor: TSQLMemBaseSQLProcessor;
begin
  LLex.GetCurrentToken(token);
  if (token.ReservedWord <> rwBEGIN) then
    raise ESQLMemException.Create(12240,ErrorGOtherTokenExpected,
     [GetReservedWord(rwBEGIN),Token.Text,Token.LineNum,Token.ColumnNum]);
  SQLProcessor := TSQLMemBaseSQLProcessor.Create(LStoredFunction,FDatabaseParams.Session);
  try
    SQLMemParseCommandsBlock(SQLProcessor,LLex,token,FCommands);
    LLex.GetCurrentToken(token);
  finally
    SQLProcessor.Free;
  end;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemRSQLBeginEndCommandsBlock.ExecSQL(
                IsRoot,
                RequestLive:  Boolean;
                var ReadOnly: Boolean
                );
var i:        Integer;
    command:  TSQLMemSQLCommand;
begin
  for i := 0 to FCommands.Count-1 do
   begin
    command := TSQLMemSQLCommand(FCommands.Items[i]);
    if (command = nil) then
     raise ESQLMemException.Create(12241,ErrorLNilPointer);
    command.ExecSQL(IsRoot,RequestLive,ReadOnly);
   end;
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLIfThenElse
//
// IF <Condition> THEN
//  <command> | <command_block> [;]
// [
// ELSE
//  <command> | <command_block> [;]
// ]
//
// <Condition>: <Boolean Expression>
// <command_block>:
// BEGIN
//                    <COMMAND_1>;
//                    <COMMAND_2>;
// ...
//                    <COMMAND_N>;
// END
// can be used in stored functions only
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemSQLIfThenElse.UpdateExpressionParams;
begin
  if (FIfCondition <> nil) then
   begin
    FIfCondition.Session := FDatabaseParams.Session;
    FIfCondition.StoredFunction := LStoredFunction;
    FIfCondition.LocalParams := LParams;
    FIfCondition.UpdateExpressionParams;
   end;
 if (FThenCommand <> nil) then
  FThenCommand.UpdateExpressionParams;
 if (FElseCommand <> nil) then
  FElseCommand.UpdateExpressionParams;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemSQLIfThenElse.CreateCopy: TSQLMemSQLCommand;
begin
  Result := TSQLMemSQLIfThenElse.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemSQLIfThenElse.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  if (FIfCondition <> nil) then
   FreeAndNil(FIfCondition);
  if (FThenCommand <> nil) then
   FreeAndNil(FThenCommand);
  if (FElseCommand <> nil) then
   FreeAndNil(FElseCommand);
  if (TSQLMemSQLIfThenElse(Source).FIfCondition <> nil) then
   begin
    FIfCondition := TSQLMemExpression.Create;
    FIfCondition.Assign(TSQLMemSQLIfThenElse(Source).FIfCondition);
   end;
  if (TSQLMemSQLIfThenElse(Source).FThenCommand <> nil) then
   FThenCommand := TSQLMemSQLIfThenElse(Source).FThenCommand.MakeCopy(FDatabaseParams.Session,LParams);
  if (TSQLMemSQLIfThenElse(Source).FElseCommand <> nil) then
   FElseCommand := TSQLMemSQLIfThenElse(Source).FElseCommand.MakeCopy(FDatabaseParams.Session,LParams);
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TSQLMemSQLIfThenElse.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  FIfCondition := nil;
  FThenCommand := nil;
  FElseCommand := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemSQLIfThenElse.Destroy;
begin
  if (FIfCondition <> nil) then
    FreeAndNil(FIfCondition);
  if (FThenCommand <> nil) then
   begin
    FreeAndNil(FThenCommand);
   end;
  if (FElseCommand <> nil) then
   begin
    FreeAndNil(FElseCommand);
   end;
  inherited;
end; // Destroy;


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TSQLMemSQLIfThenElse.Parse;
var
    SQLProcessor: TSQLMemBaseSQLProcessor;
begin
  // IF
  if (not LLex.GetCurrentToken(token)) then
   raise ESQLMemException.Create(12231,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  if (token.ReservedWord <> rwIF) then
   raise ESQLMemException.Create(12232,ErrorGOtherTokenExpected,
    [GetReservedWord(rwIF),token.Text,token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12233,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  FIfCondition := TSQLMemExpression.Create(FDatabaseParams.Session,nil,nil,Self);
  FIfCondition.ParseForBooleanExpression(LLex);
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    begin
      LParamExprNodes := TSQLMemList.Create;
      FIfCondition.ExtractAllParameterNodes(LParamExprNodes);
    end;
  // THEN
  LLex.GetCurrentToken(Token);
  if (token.ReservedWord <> rwTHEN) then
   raise ESQLMemException.Create(12234,ErrorGOtherTokenExpected,
    [GetReservedWord(rwTHEN),token.Text,token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12242,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  SQLProcessor := TSQLMemBaseSQLProcessor.Create(LStoredFunction,FDatabaseParams.Session);
  try
    FThenCommand := SQLProcessor.ParseSQLCommand(LLex,Token);
    LLex.GetCurrentToken(Token);
    // check if ELSE exists
    if (Token.ReservedWord = rwELSE) then
     begin
      if (not LLex.GetNextToken(Token)) then
       raise ESQLMemException.Create(12235,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
      FElseCommand := SQLProcessor.ParseSQLCommand(LLex,Token);
      LLex.GetCurrentToken(Token);
     end;
  finally
    SQLProcessor.Free;
  end;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemSQLIfThenElse.ExecSQL(
                IsRoot,
                RequestLive:  Boolean;
                var ReadOnly: Boolean
                );
var res: Boolean;
begin
  if (FIfCondition = nil) then
   raise ESQLMemException.Create(12243,ErrorLNilPointer);
  res := FIfCondition.GetResult;
  if (res) then
   begin
    if (FThenCommand = nil) then
     raise ESQLMemException.Create(12244,ErrorLNilPointer);
    FThenCommand.ExecSQL(IsRoot,RequestLive,ReadOnly);
   end
  else
   begin
    if (FElseCommand <> nil) then
      FElseCommand.ExecSQL(IsRoot,RequestLive,ReadOnly);
   end;
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCreateStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemCreateStoredFunction.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemCreateStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemCreateStoredFunction.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  LCreateStoredFunction := TSQLMemCreateStoredFunction(Source).LCreateStoredFunction;
  FSQLScript := TSQLMemCreateStoredFunction(Source).FSQLScript;
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TSQLMemCreateStoredFunction.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  LCreateStoredFunction := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Destroy


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemCreateStoredFunction.Destroy; 
begin
  if (LCreateStoredFunction <> nil) then
   try
     LCreateStoredFunction.Free;
   except
   end;
  SQLMemClearString(FSQLScript);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemCreateStoredFunction.Parse;
var f: TObject;
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12102,ErrorLNoActiveSession);
  if (not (FDatabaseParams.Session is TSQLMemLocalSession)) then
   raise ESQLMemException.Create(12106,ErrorLNoActiveSession);
  FDatabaseParams.Session.ParseStoredFunction(LLex,Token,f,FSQLScript);
  LCreateStoredFunction := TSQLMemStoredFunction(f);
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TSQLMemCreateStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12108,ErrorLNoActiveSession);
  if (not (FDatabaseParams.Session is TSQLMemLocalSession)) then
   raise ESQLMemException.Create(12109,ErrorLNoActiveSession);
  FDatabaseParams.Session.CreateStoredFunction(LCreateStoredFunction,FSQLScript);
  LCreateStoredFunction := nil;
  SQLMemClearString(FSQLScript);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDropStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemDropStoredFunction.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemDropStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemDropStoredFunction.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FFunctionName := TSQLMemDropStoredFunction(Source).FFunctionName;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemDropStoredFunction.Parse;
begin
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12165,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
  if (not IsStringToken(token)) then
    raise ESQLMemException.Create(12162,ErrorLInvalidTokenType,[ESQLMemTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  FFunctionName := token.Text;
  LLex.GetNextToken(token);
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemDropStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12163,ErrorLNoActiveSession);
  if (not (FDatabaseParams.Session is TSQLMemLocalSession)) then
   raise ESQLMemException.Create(12164,ErrorLNoActiveSession);
  FDatabaseParams.Session.DropStoredFunction(FFunctionName);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemAlterStoredFunction
//
// Syntax:
// ALTER FUNCTION <FunctionName>;
// - or
// ALTER PROCEDURE <FunctionName>;
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemAlterStoredFunction.CreateCopy: TSQLMemSQLCommand;
begin
  Result := TSQLMemAlterStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemAlterStoredFunction.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  FFunctionName := TSQLMemAlterStoredFunction(Source).FFunctionName;
  FNewScript := TSQLMemAlterStoredFunction(Source).FNewScript;
  FNewFunctionName := TSQLMemAlterStoredFunction(Source).FNewFunctionName;
  FAlterType := TSQLMemAlterStoredFunction(Source).FAlterType;
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TSQLMemAlterStoredFunction.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  FFunctionName := '';
  FNewScript := '';
  FNewFunctionName := '';
  FAlterType := atAdd;
  inherited Create(Lexer,aDatabaseParams,StoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TSQLMemAlterStoredFunction.Destroy;
begin
  SQLMemClearString(FNewScript);
  SQLMemClearString(FFunctionName);
  SQLMemClearString(FNewFunctionName);
  inherited Destroy;
end; // Create


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemAlterStoredFunction.Parse;
begin
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12210,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
  if (not IsStringToken(token)) then
    raise ESQLMemException.Create(12211,ErrorLInvalidTokenType,[ESQLMemTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  FFunctionName := token.Text;
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12212,ErrorLAlterFunctionTypeExpected,[token.LineNum,token.ColumnNum]);
  if (IsQuotedStringToken(token)) then
   begin
    // modify
    FAlterType := atModifyFunction;
    if (not LLex.GetNextToken(token)) then
     raise ESQLMemException.Create(12225,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
    if (not IsQuotedStringToken(token)) then
     raise ESQLMemException.Create(12226,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
    FNewScript := token.Text;
   end
  else
  if (token.TokenType = tktReservedWord) then
   begin
    case token.ReservedWord of
     rwMODIFY:
      begin
        // modify
        FAlterType := atModifyFunction;
        if (not LLex.GetNextToken(token)) then
         raise ESQLMemException.Create(12227,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
        if (not IsQuotedStringToken(token)) then
         raise ESQLMemException.Create(12228,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
        FNewScript := token.Text;
      end;
     rwRENAME:
      begin
       FAlterType := atRenameFunction;
       LLex.GetNextToken(token);
       if (token.ReservedWord <> rwTO) then
         raise ESQLMemException.Create(12213,ErrorLAlterFunctionTypeExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
       LLex.GetNextToken(token);
       if (IsStringToken(token)) then
        FNewFunctionName := token.Text
       else
         raise ESQLMemException.Create(12216,ErrorLAlterFunctionNewNameExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
      end
     else
       raise ESQLMemException.Create(12214,ErrorLAlterFunctionTypeExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
    end;
   end
  else
   raise ESQLMemException.Create(12215,ErrorLAlterFunctionTypeExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
  FErrLine := token.LineNum;
  FErrColumn := token.ColumnNum;
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemAlterStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
begin
  if (FDatabaseParams.Session = nil) then
   raise ESQLMemException.Create(12217,ErrorLNilPointer);
  case FAlterType of
   atModifyFunction:
    begin
     FDatabaseParams.Session.AlterStoredFunction(FFunctionName,FNewScript);
    end;
   atRenameFunction:
    begin
     FDatabaseParams.Session.AlterStoredFunctionRename(FFunctionName,FNewFunctionName);
    end
   else
    raise ESQLMemException.Create(12229,ErrorLAlterFunctionTypeIsNotParsed,[FErrLine,FErrColumn]);
  end;
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemExecuteStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TSQLMemExecuteStoredFunction.UpdateExpressionParams;
var i: Integer;
begin
  if (FParams <> nil) then
   for i := 0 to FParams.Count-1 do
    begin
      FParams[i].StoredFunction := LStoredFunction;
      FParams[i].Session := FDatabaseParams.Session;
      FParams[i].LocalParams := LParams;
    end;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TSQLMemExecuteStoredFunction.CreateCopy: TSQLMemSQLCommand;
begin
  // do not parse again
  Result := TSQLMemExecuteStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TSQLMemExecuteStoredFunction.Assign(Source: TSQLMemSQLCommand);
begin
  inherited Assign(Source);
  LExecuteStoredFunction := TSQLMemExecuteStoredFunction(Source).LExecuteStoredFunction;
  if (FParams <> nil) then
   FreeAndNil(FParams);
  if (TSQLMemExecuteStoredFunction(Source).FParams <> nil) then
   begin
    FParams := TSQLMemExpressions.Create;
    FParams.Assign(TSQLMemExecuteStoredFunction(Source).FParams);
   end;
end; // Assign


//------------------------------------------------------------------------------
// create object
//------------------------------------------------------------------------------
constructor TSQLMemExecuteStoredFunction.Create(Lexer: TSQLMemLexer; aDatabaseParams: TSQLMemSQLDatabaseParams; aStoredFunction: TObject);
begin
  LExecuteStoredFunction := nil;
  FParams := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroy object
//------------------------------------------------------------------------------
destructor TSQLMemExecuteStoredFunction.Destroy;
begin
  if (FParams <> nil) then
   try
     FParams.Free;
   except
   end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TSQLMemExecuteStoredFunction.Parse;
var aParams: TObject;
begin
  if (not LLex.GetNextToken(token)) then
   raise ESQLMemException.Create(12178,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
  if (not IsStringToken(token)) then
    raise ESQLMemException.Create(12179,ErrorLInvalidTokenType,[ESQLMemTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  LExecuteStoredFunction := nil;
  if (FDatabaseParams.Session <> nil) then
    if (FDatabaseParams.Session is TSQLMemLocalSession) then
      begin
       LExecuteStoredFunction := TSQLMemStoredFunction(
          TSQLMemLocalSession(FDatabaseParams.Session).ParseStoredFunctionParams(LLex, LStoredFunction, Token,aParams));
       if (LExecuteStoredFunction = nil) then
        raise ESQLMemException.Create(12180,ErrorLCannotExecuteFunctionNotParsed,
              [Token.Text,Token.LineNum,Token.ColumnNum]);
      end;
  if (LExecuteStoredFunction = nil) then
   raise ESQLMemException.Create(12181,ErrorLCannotExecuteFunctionNoActiveSession,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
  LLex.GetNextToken(token);
  FParams := TSQLMemExpressions(aParams);
end; // ExecSQL


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TSQLMemExecuteStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
var localParams: TSQLMemSQLParams;
    i:           Integer;
begin
  if (LExecuteStoredFunction = nil) then
   raise ESQLMemException.Create(12182,ErrorLNilPointer);
  localParams := LExecuteStoredFunction.GetParams;
  try
   if (FParams <> nil) then
    for i := 0 to FParams.Count-1 do
      localParams[i].Assign(FParams[i].GetValue(True),True);
    LExecuteStoredFunction.Execute(FDatabaseParams.Session,localParams,nil);
  finally
    if (localParams <> nil) then
     localParams.Free;
    LExecuteStoredFunction.DecUseCount;
  end;
end; // ExecSQL


//------------------------------------------------------------------------------
// return true if text is a session variable name - starting from SQLMem_SES_VAR_SIGN
//------------------------------------------------------------------------------
function SQLMemIsSessionVariable(text: WideString): Boolean;
begin
  Result := False;
  if (Length(text) > 0) then
   Result := (text[1] = SQLMem_SES_VAR_SIGN);
end; // SQLMemIsSessionVariable


//------------------------------------------------------------------------------
// parse commads block (<command> or BEGIN <command #1>;...<command #N>; END;
//------------------------------------------------------------------------------
procedure SQLMemParseCommandsBlock(
                        SQLProcessor:     TSQLMemBaseSQLProcessor;
                        Lexer:            TSQLMemLexer;
                        var token:        TToken;
                        var commandsList: TList
                               );
var
    command:      TSQLMemSQLCommand;
    beginCount:   Integer;
begin
  if (commandsList = nil) then
    commandsList := TList.Create;
  beginCount := 0;
  repeat
   if (token.ReservedWord = rwBEGIN) then
    begin
     Inc(beginCount);
    end
   else
   if (token.ReservedWord = rwEND) then
    begin
     Dec(beginCount);
    end
   else
    begin
     command := SQLProcessor.ParseSQLCommand(Lexer,token);
     if (command = nil) then
      raise ESQLMemException.Create(12239,ErrorLCannotParseSQLCommand,
       [token.Text,token.LineNum,token.ColumnNum]);
     commandsList.Add(command);
    end;
   // get next token
   if (not Lexer.GetNextToken(token)) then
    if (beginCount > 0) then
     begin
      if (Lexer.GetNextCommand) then
       Lexer.GetCurrentToken(token)
      else
       raise ESQLMemException.Create(12245,ErrorGUnexpectedEndOfCommand,
        [token.LineNum,token.ColumnNum]);
     end;
  until (beginCount = 0);
end; // SQLMemParseCommandsBlock




initialization


{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('< SQLMemStoredFunctions initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;


finalization

  SQLMemMemoryDecUseCount;


end.