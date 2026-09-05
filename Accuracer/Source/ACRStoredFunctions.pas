unit ACRStoredFunctions;

interface

{$I ACRVer.inc}

uses
     SysUtils, Classes, Db,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}

// Accuracer units
{$IFDEF LINUX}
     ACRLinux,
{$ENDIF}
{$IFDEF DEBUG_LOG}
     ACRDebug,
{$ENDIF}
{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}
     ACRConst,
     ACRTypes,
     ACRConverts,
     ACRStrUtils,
     ACRLexer,
     ACRVariant,
     ACRBase,
     ACRBaseEngine,
     ACRCompression,
     ACRRelationalAlgebra,
     ACRCriticalSection,
     ACRExpressions,
     ACRSQLProcessor,
     ACRExcept;



type

  TACRStoredFunction = class;

  TACRStoredFunctionHeader = packed record
    CreationDate:         TDateTime;
    LastModificationDate: TDateTime;
    NameCRC:              Cardinal;
    SQLCRC:               Cardinal;
  end; // TACRStoredFunctionHeader

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
// TACRExprNodeVariable
//
////////////////////////////////////////////////////////////////////////////////


  TACRExprNodeVariable = class (TACRExprNode)
   private
    FName:            WideString;         // variable name
    FIsSessionVar:    Boolean;
    LStoredFunction:  TACRStoredFunction;
    FParamIndex:      Integer;
   public
    constructor Create(aParentExpr: TACRExpression; aName: WideString; aStoredFunction: TACRStoredFunction; aParamIndex: Integer);
    destructor Destroy; override;
    // return Value
    function GetDataValue: TACRVariant; override;
    // return Type of Data
    function GetDataType: TACRAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TACRExpression): TACRExprNode; override;
   public
    // assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TACRExprNode); override;
   public
    property Name: WideString read FName;
    property IsSessionVar: Boolean read FIsSessionVar;
    property StoredFunction: TACRStoredFunction read LStoredFunction;
    property ParamIndex: Integer read FParamIndex;
  end; // TACRExprNodeVariable


////////////////////////////////////////////////////////////////////////////////
//
// TACRExprNodeStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


  TACRExprNodeStoredFunction = class (TACRExprNode)
   private
    FParams:              TACRExpressions;    // function params
//    LStoredFunction:    TACRStoredFunction;
    FStoredFunctionName:  WideString;
   protected
    function FindStoredFunction: TACRStoredFunction;
   public
    constructor Create(
                          aParentExpr:          TACRExpression;
                          aStoredFunctionName:  WideString;
//                          aStoredFunction: TACRStoredFunction;
                          aParams:              TACRExpressions
                      );
    destructor Destroy; override;
    // process assign AO
    procedure AssignAO(AO: TACRAO); override;
    // process assign Cursor
    procedure AssignCursor(Cursor: TACRCursor); override;
    // process assign New Cursor Buffer
    procedure AssignCursorBuffer(Buffer: TACRRecordBuffer); override;
    // return Value
    function GetDataValue: TACRVariant; override;
    // return Type of Data
    function GetDataType: TACRAdvancedFieldType; override;
    // return Size of Data (for strings and arrays)
    function GetDataSize: Integer; override;
   protected
    function CreateCopy(aParentExpr: TACRExpression): TACRExprNode; override;
   public
    // assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
    procedure Assign(Source: TACRExprNode); override;
   public
    property StoredFunctionName: WideString read FStoredFunctionName;
  end; // TACRExprNodeStoredFunction


////////////////////////////////////////////////////////////////////////////////
//
// TACRStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


  TACRStoredFunction = class (TObject)
   private
    FFunctionName:    WideString;         // function name
    FResultType:      TACRBaseFieldType;  // function result type
    FResultTypeSize:  Integer;            // 0 - no limit, otherwise maximum size of result string in characters
    FParams:          TACRSQLParams;      // contains params and local variables
                                          // nil if no params or list with TACRVariant objects
    FCommands:        TList;              // list of TACRSQLcommand
    FParamCount:      Integer;
    FThreadSync:      TACRReadWriteThreadSyncBySingleCriticalSection;
    FUseCount:        Integer;
    FFreeIfNotUsed:   Boolean;            // set by delete / load if function changed or deleted
   public
    // create
    constructor Create(
                aFunctionName:    WideString;
                aParams:          TACRSQLParams;
                aParamCount:      Integer;
                aResultType:      TACRBaseFieldType;
                aResultTypeSize:  Integer;
                aCommands:        TList
                      ); overload;
    // destroy
    destructor Destroy; override;
    // clear params and commands
    procedure Clear;
    // return nil if not found
    function FindVariable(Name: WideString): TACRSQLParam;
    // return parameter index
    function GetParamIndex(Name: WideString): Integer;
    // create and return list of all paremeters with default values
    function GetParams: TACRSQLParams;
    // return nil if procedure or result object
    procedure Execute(
                      Session:      TACRBaseSession;
                      CallParams:   TACRSQLParams;
                      ResultValue:  TACRVariant
                    );
    // increment UseCount
    procedure IncUseCount;
    // decrement UseCount
    procedure DecUseCount;
   public
    property FunctionName: WideString read FFunctionName;
    property ResultType: TACRBaseFieldType read FResultType;
    property ResultTypeSize: Integer read FResultTypeSize write FResultTypeSize;
    property Commands: TList read FCommands write FCommands;
    property Params: TACRSQLParams read FParams;
    property ParamCount: Integer read FParamCount;
    property UseCount: Integer read FUseCount;
    property FreeIfNotUsed: Boolean read FFreeIfNotUsed write FFreeIfNotUsed; // set by delete / load if function changed or deleted
  end; // TACRStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TACRStoredFunctionManager
//
////////////////////////////////////////////////////////////////////////////////


  TACRStoredFunctionManager = class (TObject)
   protected
    LDatabaseData:    TACRDatabaseData;
    FThreadSync:      TACRReadWriteThreadSync;
    FFunctionNames:   TACRObjectNameArray;
    FFunctionSQL:     TACRObjectNameArray;
    // pointers to TACRStoredFunction class - binary representation of stored function
    FFunctions:       TList;
    FHeader:          TACRSFMHeader;
    FFunctionHeaders: array of TACRStoredFunctionHeader;
    // temporary data - used for correct load of the StoredFunctionManager
    FTempFunctions:   TList;
    FTempNamesCRC:    TACRIntegerArray;
    FTempSQLCRC:      TACRIntegerArray;
   protected
    procedure Lock(Exclusive: Boolean); virtual;
    procedure Unlock; virtual;
    procedure Clear;
    procedure DestroyStoredFunction(var sf: TACRStoredFunction);
    procedure ParseCreateFunction(lexer: TACRLexer; var token: TToken);
    function ParseFunctionName(lexer: TACRLexer; var token: TToken): WideString;
    function ParseFunctionParamTypeSize(lexer: TACRLexer; var token: TToken): Integer;
    function ParseFunctionParamDefaultValue(lexer: TACRLexer; var token: TToken): TACRSQLParam;
    procedure ParseFunctionParams(lexer: TACRLexer; var token: TToken; bParseParams: Boolean; var params: TACRSQLParams);
    procedure ParseResultType(lexer: TACRLexer; var token: TToken; out FunctionType: TACRBaseFieldType; out FunctionTypeSize: Integer);
    // parse function body (var ...; begin ... end;)
    function ParseFunctionBody(
                                Session:          TACRBaseSession;
                                Lexer:            TACRLexer;
                                var Token:        TToken;
                                StoredFunction:   TACRStoredFunction
                                ): TList;
    // base function for parsing SQL script with CREATE FUNCTION ...; ... BEGIN ... END;
    function InternalParseCreateStoredFunction(
                    bCalledFromSQL:   Boolean;
                    Session:          TACRBaseSession;
                    Lexer:            TACRLexer;
                    var Token:        TToken;
                    bCreateFunction:  Boolean;
                    out SQLScript:    WideString;
                    out ErrorMessage: WideString
                      ): TACRStoredFunction;
    // base function for parsing SQL script with CREATE FUNCTION ...; ... BEGIN ... END;
    function ParseCreateStoredFunction(
                    Session:          TACRBaseSession;
                    SQLScript:        WideString;
                    bCreateFunction:  Boolean;
                    out ErrorMessage: WideString
                      ): TACRStoredFunction;
    // return -1 if not found, otherwise return index in FunctionNames,FunctionSQL arrays
    function GetFunctionByName(Name: WideString): Integer;
    // parse function call parameters:
    // FunctionName [(<call_params>)]
    function ParseFunctionCallParams(
                        Session:          TACRBaseSession;
                        Lexer:            TACRLexer;
                        parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                        var Token:        TToken;
                        aStoredFunction:  TACRStoredFunction
                                    ): TObject;
    procedure InternalCreateStoredFunction(
                                    StoredFunction: TACRStoredFunction;
                                    SQLScript:      WideString
                                          ); virtual;
    procedure InternalDropStoredFunction(FunctionName: WideString); virtual;
    // ALTER stored function - modify script
    procedure InternalAlterStoredFunction(
                                    Session:      TACRBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                                        ); virtual;
    // ALTER stored function - rename
    procedure InternalAlterStoredFunctionRename(
                                    Session:          TACRBaseSession;
                                    FunctionName,
                                    NewFunctionName:  WideString
                                                        ); virtual;
    // return nil if not found, otherwise return TACRStoredFunction object from FFunctions
    function InternalGetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TACRStoredFunction;
    // get all stored functions
    procedure InternalGetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList = nil; SortNamesByAlphabet: Boolean = true);
    // export all functions to SQL
    procedure InternalExportStoredFunctionsToSQL(var SQL: WideString);
   public
    constructor Create(DatabaseData: TACRDatabaseData);
    destructor Destroy; override;
    procedure Load(stream: TStream; SkipSFMHeader: Boolean = False);
    procedure Save(ms: TACRMemoryStream; bSkipSFMHeader: Boolean = False); overload;
    procedure Save(stream: TStream); overload;
    // for call from TACRDatabase - SQLScript can include only SINGLE STORED FUNCTION
    procedure CreateStoredFunction(Session: TACRBaseSession; SQLScript: WideString); overload;
    // for CREATE FUNCTON inside SQL script
    // current token is rwFUNCTION/rwPROCEDURE
    procedure CreateStoredFunction(
                  StoredFunction:   TACRStoredFunction;
                  SQLScript:        WideString
                                  ); overload;
    // parse CREATE FUNCTION
    procedure ParseStoredFunction(
                  Session:              TACRBaseSession;
                  Lexer:                TACRLexer;
                  var Token:            TToken;
                  out StoredFunction:   TACRStoredFunction;
                  out SQLScript:        WideString
                                 );
    // DROP stored function
    procedure DropStoredFunction(
                                    Session:      TACRBaseSession;
                                    FunctionName: WideString
                                 );
    // ALTER stored function
    procedure AlterStoredFunction(
                                    Session:      TACRBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                 );
    // ALTER stored function
    procedure AlterStoredFunctionRename(
                                    Session:          TACRBaseSession;
                                    FunctionName,
                                    NewFunctionName:  WideString
                                 );
    // for calls from TACRDatabase.ExecuteStoredFunction
    // execute stored function - return false if function does not exist
    // if function has no result (procedure) ResultValue will be set to nil
    // params - list of TACRSQLParam
    function ExecuteStoredFunction(
                    Session:         TACRBaseSession;
                    FunctionName:    WideString;
                    ResultValue:     TACRVariant;
                    Params:          TACRSQLParams
                                  ): Boolean; virtual;
    // return empty string if function not found; otherwise return SQL script (CREATE FUNCTION...)
    // return SQL script that created this function (CREATE FUNCTION ...)
    function FindStoredFunction(FunctionName: WideString): WideString; virtual;
    // return the stored function object if it exists in stored function manager associated with
    // the atabase opened by this session
    // used by TACRExprNodeStoredFunction
    function GetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TObject; virtual;
    // parse for execute - from SQL engine (EXECUTE FUNCTION / expression, like FunctionName(Params))
    // return stored function object (TACRStoredFunction) if found or nil
    // params - list of TACRExpression
    function ParseStoredFunctionParams(
                Session:          TACRBaseSession;
                Lexer:            TACRLexer;
                parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                var Token:        TToken;
                out Params:       TObject
                                      ): TObject; virtual;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings = nil; SortNamesByAlphabet: Boolean = true); overload; virtual;
    // return list of stored function names (optionally SQL scripts for their creation)
    procedure GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList = nil; SortNamesByAlphabet: Boolean = true); overload; virtual;
    // export all stored functions to SQL
    procedure ExportStoredFunctionsToSQL(var SQL: WideString); virtual;
  end; // TACRStoredFunctionManager




////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLAssign
//
// <variable> := <expression>;
//
// can be used in scripts (session variables only)
// and
// in stored functions (local variables, params, result, session variables)
//
////////////////////////////////////////////////////////////////////////////////



  TACRSQLAssign = class (TACRSQLCommand)
   private
     FVariable:          TACRExprNode;
     FExpression:        TACRExpression;
   protected
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
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
  end; // TACRRSQLAssign




////////////////////////////////////////////////////////////////////////////////
//
// TACRRSQLBeginEndCommandsBlock
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



  TACRRSQLBeginEndCommandsBlock = class (TACRSQLCommand)
   private
     FCommands: TList;
   protected
     // update parameter values in all expressions
     procedure UpdateParams(SQLParams: TACRSQLParams); override;
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
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
  end; // TACRRSQLBeginEndCommandsBlock




////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLIfThenElse
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



  TACRSQLIfThenElse = class (TACRSQLCommand)
   private
     FIfCondition:  TACRExpression;
     FThenCommand:  TACRSQLCommand;
     FElseCommand:  TACRSQLCommand;
   protected
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
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
  end; // TACRSQLIfThenElse


////////////////////////////////////////////////////////////////////////////////
//
// TACRCreateStoredFunction
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


  TACRCreateStoredFunction = class (TACRSQLCommand)
   private
     LCreateStoredFunction: TACRStoredFunction; // parsed function
     FSQLScript:            WideString;
   protected
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
     // creates object
     constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
  end; // TACRCreateStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TACRDropStoredFunction
//
// Syntax:
// DROP FUNCTION <FunctionName>;
// - or
// DROP PROCEDURE <FunctionName>;
//
////////////////////////////////////////////////////////////////////////////////


  TACRDropStoredFunction = class (TACRSQLCommand)
   private
     FFunctionName: WideString;
   protected
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
     // parse query
     procedure Parse; override;
     // execute query
     procedure ExecSQL(
                        IsRoot,
                        RequestLive:  Boolean;
                        var ReadOnly: Boolean
                       ); override;
  end; // TACRDropStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TACRAlterStoredFunction
//
// Syntax:
//
// ALTER FUNCTION <FunctionName> MODIFY '<New SQL Script>';
// ALTER FUNCTION <FunctionName> RENAME TO <New Name>;
//
////////////////////////////////////////////////////////////////////////////////


  TACRAlterStoredFunction = class (TACRSQLCommand)
   private
     FFunctionName:     WideString;
     FNewScript:        WideString;
     FNewFunctionName:  WideString;
     FAlterType:        TAlterType;
     FErrLine:          Integer;
     FErrColumn:        Integer;
   protected
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
     // creates object
     constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
  end; // TACRAlterStoredFunction




////////////////////////////////////////////////////////////////////////////////
//
// TACRExecuteStoredFunction
//
// Syntax:
// EXECUTE FUNCTION <FunctionName> [(<Params>)];
//
////////////////////////////////////////////////////////////////////////////////


  TACRExecuteStoredFunction = class (TACRSQLCommand)
   private
     LExecuteStoredFunction:  TACRStoredFunction;
     FParams:                 TACRExpressions;    // function params
   protected
     // updates all expressions - sets LSession, LParams (needed for stored functions)
     procedure UpdateExpressionParams; override;
     function CreateCopy: TACRSQLCommand; override;
   public
     procedure Assign(Source: TACRSQLCommand); override;
     // creates object
     constructor Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
  end; // TACRExecuteStoredFunction

// return true if text is a session variable name - starting from ACR_SES_VAR_SIGN
function ACRIsSessionVariable(text: WideString): Boolean;
// parse commads block (<command> or BEGIN <command #1>;...<command #N>; END;
procedure ACRParseCommandsBlock(
                        SQLProcessor:     TACRBaseSQLProcessor;
                        Lexer:            TACRLexer;
                        var token:        TToken;
                        var commandsList: TList
                               );

implementation

uses
      Math,
      ACRLocalEngine, ACRMain,
      ACRMemory; // last


////////////////////////////////////////////////////////////////////////////////
//
// TACRExprNodeVariable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRExprNodeVariable.Create(
                                        aParentExpr:      TACRExpression;
                                        aName:            WideString;
                                        aStoredFunction:  TACRStoredFunction;
                                        aParamIndex:      Integer
                                       );
begin
  inherited Create(aParentExpr);
  FName := aName;
  LStoredFunction := aStoredFunction;
  FIsSessionVar := ((LStoredFunction = nil) and (ACRIsSessionVariable(FName)));
  FParamIndex := aParamIndex;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRExprNodeVariable.Destroy;
begin
  ACRClearString(FName);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TACRExprNodeVariable.GetDataValue: TACRVariant;
var param: TACRSQLParam;
begin
 if (LParentExpr = nil) then
  raise EACRException.Create(12120,ErrorLNilPointer);
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
    raise EACRException.Create(12123,ErrorLNilPointer);
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    raise EACRException.Create(12121,ErrorLInvlidParameterIndex,
      [FName,FParamIndex,LParentExpr.LocalParams.Count]);
   param := LParentExpr.LocalParams[FParamIndex];
  end;
 Result := param;
end; // GetDataValue


//------------------------------------------------------------------------------
// return Type of Data
//------------------------------------------------------------------------------
function TACRExprNodeVariable.GetDataType: TACRAdvancedFieldType;
var param: TACRSQLParam;
begin
 if (LParentExpr = nil) then
  raise EACRException.Create(12124,ErrorLNilPointer);
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
    raise EACRException.Create(12126,ErrorLNilPointer);
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    raise EACRException.Create(12127,ErrorLInvlidParameterIndex,
      [FName,FParamIndex,LParentExpr.LocalParams.Count]);
   Result := LParentExpr.LocalParams[FParamIndex].AdvDataType;
{$ENDIF}
  end;
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TACRExprNodeVariable.GetDataSize: Integer;
var param: TACRSQLParam;
begin
 if (LParentExpr = nil) then
  raise EACRException.Create(12125,ErrorLNilPointer);
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
    raise EACRException.Create(12128,ErrorLNilPointer);
   if (FParamIndex < 0) or (FParamIndex >= LParentExpr.LocalParams.Count) then
    raise EACRException.Create(12129,ErrorLInvlidParameterIndex,
      [FName,FParamIndex,LParentExpr.LocalParams.Count]);
   Result := LParentExpr.LocalParams[FParamIndex].MaxStrLen;
  end;
end; // GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRExprNodeVariable.CreateCopy(aParentExpr: TACRExpression): TACRExprNode;
begin
  Result := TACRExprNodeVariable.Create(aParentExpr,'',nil,0);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TACRExprNodeVariable.Assign(Source: TACRExprNode);
begin
  inherited Assign(Source);
  FName := TACRExprNodeVariable(Source).FName;
  FIsSessionVar := TACRExprNodeVariable(Source).FIsSessionVar;
  FParamIndex := TACRExprNodeVariable(Source).FParamIndex;
  LStoredFunction := TACRExprNodeVariable(Source).LStoredFunction;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TACRExprNodeStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// find stored function
//------------------------------------------------------------------------------
function TACRExprNodeStoredFunction.FindStoredFunction: TACRStoredFunction;
var
    ses:              TACRBaseSession;
begin
  Result := nil;
  ses := TACRExpression(LParentExpr).Session;
  if (ses <> nil) then
   Result := TACRStoredFunction(ses.GetStoredFunctionByName(FStoredFunctionName));
end; // FindStoredFunction


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRExprNodeStoredFunction.Create(
                          aParentExpr:          TACRExpression;
                          aStoredFunctionName:  WideString;
//                          aStoredFunction:    TACRStoredFunction;
                          aParams:              TACRExpressions
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
destructor TACRExprNodeStoredFunction.Destroy;
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
procedure TACRExprNodeStoredFunction.AssignAO(AO: TACRAO);
var i: Integer;
begin
 if (FParams <> nil) then
  for i := 0 to FParams.Count-1 do
   FParams[i].AssignAO(AO);
end; // AssignAO


//------------------------------------------------------------------------------
// process assign Cursor
//------------------------------------------------------------------------------
procedure TACRExprNodeStoredFunction.AssignCursor(Cursor: TACRCursor);
var i: Integer;
begin
 if (FParams <> nil) then
  for i := 0 to FParams.Count-1 do
   FParams[i].AssignCursor(Cursor);
end; // AssignCursor


//------------------------------------------------------------------------------
// process assign New Cursor Buffer
//------------------------------------------------------------------------------
procedure TACRExprNodeStoredFunction.AssignCursorBuffer(Buffer: TACRRecordBuffer);
var i: Integer;
begin
 if (FParams <> nil) then
  for i := 0 to FParams.Count-1 do
   FParams[i].AssignCursorBuffer(Buffer);
end; // AssignCursorBuffer


//------------------------------------------------------------------------------
// return Value
//------------------------------------------------------------------------------
function TACRExprNodeStoredFunction.GetDataValue: TACRVariant;
var localParams:      TACRSQLParams;
    i:                Integer;
    storedFunction:   TACRStoredFunction;
begin
  if (LParentExpr = nil) then
   raise EACRException.Create(12122,ErrorLNilPointer);
  storedFunction := FindStoredFunction;
  if (storedFunction = nil) then
   raise EACRException.Create(12472,ErrorLCannotFindFunction,[FStoredFunctionName]);
  localParams := storedFunction.GetParams;
  try
   if (FParams <> nil) then
    for i := 0 to FParams.Count-1 do
    begin
      TACRExpression(FParams[i]).LocalParams := LParentExpr.LocalParams;
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
function TACRExprNodeStoredFunction.GetDataType: TACRAdvancedFieldType;
var storedFunction:   TACRStoredFunction;
begin
  storedFunction := FindStoredFunction;
  if (storedFunction = nil) then
   raise EACRException.Create(12473,ErrorLCannotFindFunction,[FStoredFunctionName]);
  Result := BaseFieldTypeToAdvancedFieldType(storedFunction.ResultType);
end; // GetDataType


//------------------------------------------------------------------------------
// return Size of Data (for strings and arrays)
//------------------------------------------------------------------------------
function TACRExprNodeStoredFunction.GetDataSize: Integer;
var storedFunction:   TACRStoredFunction;
begin
  storedFunction := FindStoredFunction;
  if (storedFunction = nil) then
   raise EACRException.Create(12474,ErrorLCannotFindFunction,[FStoredFunctionName]);
  Result := storedFunction.ResultTypeSize;
end; // GetDataSize


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRExprNodeStoredFunction.CreateCopy(aParentExpr: TACRExpression): TACRExprNode;
begin
  Result := TACRExprNodeStoredFunction.Create(aParentExpr,'',nil);
  TACRExprNodeStoredFunction(Result).FParams := TACRExpressions.Create;
end; // CreateCopy


//------------------------------------------------------------------------------
// assign - called by TACRStoredFunction.Execute - to copy parsed SQL command before execute it
//------------------------------------------------------------------------------
procedure TACRExprNodeStoredFunction.Assign(Source: TACRExprNode);
begin
  inherited Assign(Source);
  if (TACRExprNodeStoredFunction(Source).FParams <> nil) then
   FParams.Assign(TACRExprNodeStoredFunction(Source).FParams);
//  LStoredFunction := TACRExprNodeStoredFunction(Source).LStoredFunction;
  FStoredFunctionName := TACRExprNodeStoredFunction(Source).StoredFunctionName;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TACRStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRStoredFunction.Create(
                aFunctionName:    WideString;
                aParams:          TACRSQLParams;
                aParamCount:      Integer;
                aResultType:      TACRBaseFieldType;
                aResultTypeSize:  Integer;
                aCommands:        TList
                                              );
var param: TACRSQLParam;
begin
  inherited Create;
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FFunctionName := aFunctionName;
  FParams := aParams;
  FParamCount := aParamCount;
  FResultType := aResultType;
  FResultTypeSize := aResultTypeSize;
  if (FResultType <> bftUnknown) then
   begin
    if (FParams = nil) then
     FParams := TACRSQLParams.Create;
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
destructor TACRStoredFunction.Destroy;
begin
  Clear;
  ACRClearString(FFunctionName);
  FThreadSync.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// clear params and commands
//------------------------------------------------------------------------------
procedure TACRStoredFunction.Clear;
begin
  FThreadSync.Lock(True);
  try
    FUseCount := 0;
    if (FCommands <> nil) then
     begin
      ACRClearCommands(FCommands);
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
function TACRStoredFunction.FindVariable(Name: WideString): TACRSQLParam;
begin
  Result := nil;
  if (FParams <> nil) then
   Result := FParams.GetParamByName(Name);
end; // FindVariable


//------------------------------------------------------------------------------
// return parameter index
//------------------------------------------------------------------------------
function TACRStoredFunction.GetParamIndex(Name: WideString): Integer;
begin
  Result := FParams.GetParamIndexByName(Name);
end; // GetParamIndex


//------------------------------------------------------------------------------
// create and return list of all paremeters with default values
//------------------------------------------------------------------------------
function TACRStoredFunction.GetParams: TACRSQLParams;
var i: Integer;
begin
  Result := nil;
  if (FParams <> nil) then
   begin
    Result := TACRSQLParams.Create;
    for i := 0 to FParams.Count-1 do
     begin
      Result.AddCreated.Assign(FParams[i],True);
     end;
   end;
end; // GetParams


//------------------------------------------------------------------------------
// return nil if procedure or result object
//------------------------------------------------------------------------------
procedure TACRStoredFunction.Execute(
                      Session:      TACRBaseSession;
                      CallParams:   TACRSQLParams;
                      ResultValue:  TACRVariant
                                    );
var i,cnt1,cnt2:  Integer;
    command:      TACRSQLCommand;
    readOnly:     Boolean;
    res:          TACRSQLParam;
begin
 cnt1 := 0;
 cnt2 := 0;
 if (FResultType <> bftUnknown) then
  if (ResultValue = nil) then
   raise EACRException.Create(12118,ErrorLNilPointer);
 if (ResultValue <> nil) then
  ResultValue.Clear(FResultType);
 // check if all params are passed - it should be if they created by GetParams
 if (CallParams <> nil) then
    cnt1 := CallParams.Count;
 if (FParams <> nil) then
    cnt2 := FParams.Count;
 if (cnt1 <> cnt2) then
  raise EACRException.Create(12114,ErrorLExecuteStoredFunctionInvalidParamsCount,
      [FFunctionName,cnt1,cnt2]);
 if (FCommands <> nil) then
  for i := 0 to FCommands.Count-1 do
   begin
    command := TACRSQLCommand(FCommands.Items[i]).MakeCopy(Session,CallParams);
    if (command = nil) then
     raise EACRException.Create(12186,ErrorLErrorMakeCopy,[command.ClassName,IntToHex(Integer(command),8)]);
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
     raise EACRException.Create(12117,ErrorLExecuteStoredFunctionNoResult,[FFunctionName]);
    ResultValue.Assign(res,True);
    if (ResultValue.DataType <> FResultType) then
     ResultValue.Cast(FResultType);
  end;
end; // Execute


//------------------------------------------------------------------------------
// increment UseCount
//------------------------------------------------------------------------------
procedure TACRStoredFunction.IncUseCount;
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
procedure TACRStoredFunction.DecUseCount;
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
// TACRStoredFunctionManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.Lock(Exclusive: Boolean);
begin
  FThreadSync.Lock(Exclusive);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.Unlock;
begin
  FThreadSync.Unlock
end; // Unlock


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.Clear;
var sf:    TACRStoredFunction;
    i:     Integer;
begin
  for i := 0 to FFunctions.Count-1 do
    if (FFunctions.Items[i] <> nil) then
     begin
      sf := TACRStoredFunction(FFunctions.Items[i]);
      if (sf.UseCount <= 0) then
        sf.Clear;
     end;
  for i := 0 to FFunctions.Count-1 do
   begin
    if (FFunctions.Items[i] <> nil) then
     begin
      sf := TACRStoredFunction(FFunctions.Items[i]);
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
procedure TACRStoredFunctionManager.DestroyStoredFunction(var sf: TACRStoredFunction);
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
procedure TACRStoredFunctionManager.ParseCreateFunction(lexer: TACRLexer; var token: TToken);
begin
  if (not IsReservedWord(token,rwCREATE)) then
    raise EACRException.Create(12023,ErrorGOtherTokenExpected,
      [GetReservedWord(rwCREATE),token.Text,Token.LineNum,token.ColumnNum]);
  if (not lexer.GetNextToken(token)) then
    raise EACRException.Create(12024,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  if ((not IsReservedWord(token,rwFUNCTION)) and (not IsReservedWord(token,rwPROCEDURE))) then
    raise EACRException.Create(12025,ErrorGOtherTokenExpected,
      [GetReservedWord(rwFUNCTION),token.Text,token.LineNum,token.ColumnNum]);
end; // ParseCreateFunction


//------------------------------------------------------------------------------
// parse stored function name
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ParseFunctionName(lexer: TACRLexer; var token: TToken): WideString;
begin
  if (not IsStringToken(token)) then
    raise EACRException.Create(12027,ErrorLInvalidTokenType,[EACRTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  Result := token.Text;
end; // ParseFunctionName;


//------------------------------------------------------------------------------
// parse parameter type size
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ParseFunctionParamTypeSize(lexer: TACRLexer; var token: TToken): Integer;
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
      raise EACRException.Create(12033,ErrorLCannotParseFunctionParametersSizeExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if (token.tokenType <> tktInt) then
      raise EACRException.Create(12034,ErrorLCannotParseFunctionParametersSizeExpected,[token.Text,token.LineNum,token.ColumnNum]);
     //Size
     Result := StrToIntDef(token.Text,0);
     // )
     if (not lexer.GetNextToken(token)) then
      raise EACRException.Create(12035,ErrorGRightParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if (token.TokenType <> tktRightParenthesis) then
      raise EACRException.Create(12036,ErrorGRightParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
    end;
end; // ParseFunctionParamTypeSize


//------------------------------------------------------------------------------
// parse <default_value>
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ParseFunctionParamDefaultValue(lexer: TACRLexer; var token: TToken): TACRSQLParam;
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
      raise EACRException.Create(12038,ErrorLCannotParseFunctionParametersDefaultValueExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if ((token.TokenType <> tktQuotedString) and (token.tokenType <> tktInt) and (token.tokenType <> tktFloat)) then
      raise EACRException.Create(12039,ErrorLCannotParseFunctionParametersDefaultValueExpected,[token.Text,token.LineNum,token.ColumnNum]);
     try
{
       if (token.tokenType = tktInt) then
        begin
         Result := TACRSQLParam.Create(bftSignedInt64);
         Result.AsInt64 := StrToInt64Def(token.Text,0);
        end
       else
       if (token.tokenType = tktFloat) then
        begin
         Result := TACRSQLParam.Create(bftDouble);
         Result.AsDouble := StrToFloat(token.Text);
        end
       else
        begin
         Result := TACRSQLParam.Create(bftWideChar);
         Result.AsWideString := token.Text;
        end;
}
      Result := TACRSQLParam.Create(bftWideChar);
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
procedure TACRStoredFunctionManager.ParseFunctionParams(lexer: TACRLexer; var token: TToken; bParseParams: Boolean; var params: TACRSQLParams);

 procedure AddParamsToResult(
                  paramNames:   TACRWideStringList;
                  paramType:    TACRBaseFieldType;
                  paramList:    TACRSQLParams;
                  paramSize:    Integer;
                  paramDefault: TACRSQLParam
                  );
 var i:     Integer;
     param: TACRSQLParam;
     name:  WideString;

 begin
  for i := 0 to paramNames.Count-1 do
   begin
    name := paramNames[i];
    if (paramList.GetParamByName(name) <> nil) then
     raise EACRException.Create(12054,ErrorLIdentifierRedeclared,[name]);
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
    paramType:          TACRBaseFieldType;
    paramSize:          Integer;
    paramDefault:       TACRSQLParam;
    paramNames:         TACRWideStringList;

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
     raise EACRException.Create(12028,ErrorGLeftParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
    leftBracketCount := 1;
   end // parse params
  else
   begin
    // local variables
    // BEGIN means no local variables
    if (IsReservedWord(token,rwBEGIN)) then
     Exit;
    if (not IsReservedWord(token,rwVAR)) then
     raise EACRException.Create(12044,ErrorGOtherTokenExpected,[GetReservedWord(rwVAR),token.Text,token.LineNum,token.ColumnNum]);
    leftBracketCount := 0;
   end; // // local variables
  rightBracketCount := 0;
  paramSize := 0;
  bParseParamName := True;
  bParseParamType := False;
  paramNames := TACRWideStringList.Create;
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
          raise EACRException.Create(12030,ErrorLInvalidTokenType,[EACRTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
        paramName := token.Text;
        paramNames.Add(paramName);
       end // bParseParamName
      else
      if ((bParseParamType) or (token.TokenType = tktParameter) or (token.TokenType = tktReservedWord)) then
       begin
        if ((token.TokenType <> tktString) and (token.TokenType <> tktParameter) and
            (token.TokenType <> tktReservedWord)) then
         raise EACRException.Create(12031,ErrorLCannotParseFunctionParametersTypeExpected,[token.Text,token.LineNum,token.ColumnNum]);
        paramType := SQLStrToBft(token.Text);
        // parse size
        paramSize := ParseFunctionParamTypeSize(lexer,token);
        // parse default values
        paramDefault := ParseFunctionParamDefaultValue(lexer,token);
        if (params = nil) then
         params := TACRSQLParams.Create;
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
     raise EACRException.Create(12032,ErrorGOtherTokenExpected,[Colon,token.Text,token.LineNum,token.ColumnNum]);
    if (bParseParams) and (leftBracketCount <> rightBracketCount) then
     raise EACRException.Create(12029,ErrorLRightParenthesisNotFound,
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
procedure TACRStoredFunctionManager.ParseResultType(lexer: TACRLexer; var token: TToken; out FunctionType: TACRBaseFieldType; out FunctionTypeSize: Integer);
begin
 // procedure
 FunctionType := bftUnknown;
 FunctionTypeSize := 0;
 // : ResultType [ (MaxSize) ]
 if ((token.Text = Colon) or (token.TokenType = tktParameter)) then
  begin
   if (token.TokenType <> tktParameter) then
    if (not lexer.GetNextToken(token)) then
     raise EACRException.Create(12040,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
   if (UpperCase(AnsiString(token.Text)) = 'GUID') then
   begin
    FunctionType := bftChar;
    FunctionTypeSize := ACR_GUID_LENGTH;
    lexer.GetNextToken(token);
   end
   else
   begin
     FunctionType := SQLStrToBft(token.Text);
     if (FunctionType = bftUnknown) then
      raise EACRException.Create(12041,ErrorLCannotParseFunctionResultTypeExpected,[token.Text,token.LineNum,token.ColumnNum]);
     if (lexer.GetNextToken(token)) then
      begin
       if (token.tokenType <> tktLeftParenthesis) then
        raise EACRException.Create(12064,ErrorGLeftParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
       lexer.GetNextToken(token);
       if (token.tokenType <> tktInt) then
        raise EACRException.Create(12042,ErrorLCannotParseFunctionResultSizeExpected,[token.Text,token.LineNum,token.ColumnNum]);
       // parse size
       FunctionTypeSize := StrToIntDef(token.Text,0);
       lexer.GetNextToken(token);
       if (token.tokenType <> tktRightParenthesis) then
        raise EACRException.Create(12065,ErrorGRightParenthesisExpected,[token.Text,token.LineNum,token.ColumnNum]);
       if (lexer.GetNextToken(token)) then
        raise EACRException.Create(12043,ErrorGUnexpectedToken,[token.Text, token.LineNum,token.ColumnNum]);
      end;
   end;
  end
 else
  if (lexer.GetNextToken(token)) then
   raise EACRException.Create(12061,ErrorGUnexpectedToken,[token.Text, token.LineNum,token.ColumnNum]);
 // fixed in v.5.80
 if (IsStringFieldType(FunctionType)) then
  if (FunctionTypeSize <= 0) then
   FunctionTypeSize := ACRExpressionMaxVarcharSize;
end; // ParseResultType


//------------------------------------------------------------------------------
// parse <function_body>
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ParseFunctionBody(
                                Session:          TACRBaseSession;
                                Lexer:            TACRLexer;
                                var Token:        TToken;
                                StoredFunction:   TACRStoredFunction
                                ): TList;
var SQLProcessor: TACRBaseSQLProcessor;
    command:      TACRSQLCommand;
begin
  Result := nil;
  if (not IsReservedWord(token,rwBEGIN)) then
    raise EACRException.Create(12048,ErrorGOtherTokenExpected,[GetReservedWord(rwBEGIN),token.Text,token.LineNum,token.ColumnNum]);
  if (not lexer.GetNextToken(token)) then
    raise EACRException.Create(12049,ErrorLFunctionBodyExpected,[token.LineNum,token.ColumnNum]);
  if (not IsReservedWord(token,rwEND)) then
   begin
     Result := TList.Create;
     try
       SQLProcessor := TACRBaseSQLProcessor.Create(storedFunction,Session);
       try
        while (not IsReservedWord(token,rwEND)) do
         begin
          command := SQLProcessor.ParseSQLCommand(lexer,token);
          lexer.GetCurrentToken(token);
          if (command = nil) then
           raise EACRException.Create(12238,ErrorLCannotParseSQLCommand,
            [token.Text,token.LineNum,token.ColumnNum]);
          if (command is TACRCreateStoredFunction) then
           raise EACRException.Create(12113,ErrorLCreateFunctionIsNotAllowedInsideFunctionBody,[token.LineNum,token.ColumnNum]);
          Result.Add(command);
          if (not lexer.GetNextCommand) then
           raise EACRException.Create(12052,ErrorLCannotParseFunctionBodyMissingEnd,[token.LineNum,token.ColumnNum]);
          if (not lexer.GetCurrentToken(token)) then
           raise EACRException.Create(12053,ErrorLCannotParseFunctionBodyMissingEnd,[token.LineNum,token.ColumnNum]);
         end; // while
       finally
         SQLProcessor.Free;
       end;
     except
      ACRClearCommands(Result);
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
function TACRStoredFunctionManager.InternalParseCreateStoredFunction(
                bCalledFromSQL:   Boolean;
                Session:          TACRBaseSession;
                Lexer:            TACRLexer;
                var Token:        TToken;
                bCreateFunction:  Boolean;
                out SQLScript:    WideString;
                out ErrorMessage: WideString
                  ): TACRStoredFunction;
var
    name:             WideString;
    resultType:       TACRBaseFieldType;
    resultSize:       Integer;
    params:           TACRSQLParams;
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
        raise EACRException.Create(12021,ErrorGBlankSqlCommand);
       if (not lexer.GetCurrentToken(token)) then
        raise EACRException.Create(12022,ErrorGBlankSqlCommand);
       // parse CREATE FUNCTION | CREATE PROCEDURE
       ParseCreateFunction(lexer,token);
      end;
//     else
//      SQLScript := GetReservedWord(rwCREATE)+Space+GetReservedWord(rwFUNCTION);
     if (not lexer.GetNextToken(token)) then
      raise EACRException.Create(12026,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
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
        raise EACRException.Create(12063,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
       if (not lexer.GetCurrentToken(token)) then
        raise EACRException.Create(12066,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
       // parse <local_variables>
       ParseFunctionParams(lexer,token,false,params);
      end
     else
      begin
       if (lexer.GetNextCommand) then
        lexer.GetCurrentToken(token)
       else
        raise EACRException.Create(12062,ErrorLFunctionBodyExpected,[token.LineNum,token.ColumnNum]);
      end;
     // create stored function
     Result := TACRStoredFunction.Create(name,params,paramCount,resultType,resultSize,nil);
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
             ACRClearCommands(commands);
             commands.Free;
           end;
        end;
       if (Result <> nil) then
         Result.Free;
       Result := nil;
      end;
    end;
  finally
    ACRClearString(name);
    if (bCalledFromSQL) then
      SQLScript := Lexer.StopSaveScript(True);
  end;
end; // InternalParseCreateStoredFunction


//------------------------------------------------------------------------------
// base function for parsing SQL script with CREATE FUNCTION ...; ... BEGIN ... END;
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ParseCreateStoredFunction(
                    Session:          TACRBaseSession;
                    SQLScript:        WideString;
                    bCreateFunction:  Boolean;
                    out ErrorMessage: WideString
                      ): TACRStoredFunction;
var lexer:  TACRLexer;
    token:  TToken;
    s:      WideString;
begin
  lexer := TACRLexer.Create(SQLScript);
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
function TACRStoredFunctionManager.GetFunctionByName(Name: WideString): Integer;
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
function TACRStoredFunctionManager.ParseFunctionCallParams(
                        Session:          TACRBaseSession;
                        Lexer:            TACRLexer;
                        parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
                        var Token:        TToken;
                        aStoredFunction:  TACRStoredFunction
                                    ): TObject;
var i,paramNo:  Integer;
    expr:       TACRExpression;
    exprList:   TACRExpressions;
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
          exprList := TACRExpressions.Create;
          while (token.TokenType <> tktRightParenthesis) do
           begin
            // get next token
            if (not lexer.GetNextToken(token)) then
               raise EACRException.Create(12091,ErrorLFunctionParameterExpectedButCommandTerminated,[token.LineNum,token.ColumnNum]);
            expr := exprList.AddCreated(Session,nil);
            expr.StoredFunction := TACRStoredFunction(parentFunction);
            expr.ParseForValueExpression(lexer);
            // skipe last expression token
            if (not lexer.GetCurrentToken(token)) then
               raise EACRException.Create(12096,ErrorLFunctionParameterExpectedButCommandTerminated,[token.LineNum,token.ColumnNum]);
            if ((token.TokenType <> tktRightParenthesis) and (token.TokenType <> tktComma)) then
               raise EACRException.Create(12098,ErrorLFunctionParameterCommaRightParenthesis,[token.text,token.LineNum,token.ColumnNum]);
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
      raise EACRException.Create(12119,ErrorLExecuteStoredFunctionInvalidParamsCount,
            [aStoredFunction.FunctionName,paramCount,aStoredFunction.ParamCount]);
    // check if all parameters that were not passed to this function call
    // has default values        
    for i := paramCount to aStoredFunction.ParamCount-1 do
     if (aStoredFunction.Params[i].DataType = bftUnknown) then
      raise EACRException.Create(12097,ErrorLParamaterMissed,
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
procedure TACRStoredFunctionManager.InternalCreateStoredFunction(
                                StoredFunction: TACRStoredFunction;
                                SQLScript:      WideString
                                      );
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise EACRException.Create(12077,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise EACRException.Create(12078,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise EACRException.Create(12079,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise EACRException.Create(12080,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  if (GetFunctionByName(StoredFunction.FunctionName) >= 0) then
   raise EACRException.Create(12175,ErrorLFunctionAlreadyExists,[StoredFunction.FFunctionName]);
  FFunctions.Add(StoredFunction);
  FFunctionNames.Add(StoredFunction.FunctionName);
  FFunctionSQL.Add(SQLScript);
  Inc(FHeader.Count);
  if (FHeader.State < ACR_MAX_STATE) then
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
procedure TACRStoredFunctionManager.InternalDropStoredFunction(FunctionName: WideString);
var itemNo: Integer;
    sf:     TACRStoredFunction;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise EACRException.Create(12081,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise EACRException.Create(12082,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise EACRException.Create(12083,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise EACRException.Create(12084,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  itemNo := GetFunctionByName(FunctionName);
  if (itemNo < 0) then
   raise EACRException.Create(12085,ErrorLCannotFindFunction,[FunctionName]);
  sf :=  TACRStoredFunction(FFunctions.Items[itemNo]);
  DestroyStoredFunction(sf);
  FFunctionNames.Delete(itemNo);
  FFunctionSQL.Delete(itemNo);
  FFunctions.Delete(itemNo);
  // if not last - move headers after it to position-1
  if (itemNo < FHeader.Count-1) then
   Move(FFunctionHeaders[itemNo+1],FFunctionHeaders[itemNo],
       (FHeader.Count - 1 - itemNo)*SizeOf(TACRStoredFunctionHeader));
  Dec(FHeader.Count);
  if (FHeader.State < ACR_MAX_STATE) then
   Inc(FHeader.State)
  else
   FHeader.State := 0;
  SetLength(FFunctionHeaders,FHeader.Count);
end; // InternalDropStoredFunction


//------------------------------------------------------------------------------
// ALTER stored function
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.InternalAlterStoredFunction(
                                    Session:      TACRBaseSession;
                                    FunctionName,
                                    NewSQLScript: WideString
                                                        );
var i,itemNo:     Integer;
    sf1,sf2:      TACRStoredFunction;
    crc:          Cardinal;
    ErrorMessage: WideString;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise EACRException.Create(12202,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise EACRException.Create(12203,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise EACRException.Create(12204,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise EACRException.Create(12205,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
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
   raise EACRException.Create(12206,ErrorLCannotFindFunction,[FunctionName]);
  ErrorMessage := '';
  sf1 := ParseCreateStoredFunction(Session,NewSQLScript,True,ErrorMessage);
  if (sf1 = nil) then
    raise EACRException.Create(12207,ErrorLErrorParsingStoredFunction,[errorMessage,NewSQLScript]);
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
procedure TACRStoredFunctionManager.InternalAlterStoredFunctionRename(
                                    Session:          TACRBaseSession;
                                    FunctionName,
                                    NewFunctionName:  WideString
                                                    );
var i,itemNo: Integer;
    crc:      Cardinal;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise EACRException.Create(12218,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise EACRException.Create(12219,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise EACRException.Create(12220,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise EACRException.Create(12221,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
  crc := GetTableNameCRC(FunctionName,True);
  itemNo := -1;
  for i := 0 to FHeader.Count-1 do
   if (FFunctionHeaders[i].NameCRC = crc) then
     begin
      itemNo := i;
      break;
     end;
  if (itemNo < 0) then
   raise EACRException.Create(12222,ErrorLCannotFindFunction,[FunctionName]);
  crc := GetTableNameCRC(NewFunctionName,True);
  FFunctionHeaders[itemNo].NameCRC := crc;
  FFunctionNames[itemNo] := NewFunctionName;
end; // InternalAlterStoredFunctionRename


//------------------------------------------------------------------------------
// return nil if not found, otherwise return TACRStoredFunction object from FFunctions
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.InternalGetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TACRStoredFunction;
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
     Result := TACRStoredFunction(FFunctions.Items[itemNo]);
     if (Result = nil) then
      begin
        // parse function from SQL script
        SQLScript := FFunctionSQL.Strings[itemNo];
        Result := ParseCreateStoredFunction(Session,SQLScript,False,ErrorMessage);
        if (Result = nil) then
          raise EACRException.Create(12086,ErrorLErrorParsingStoredFunction,[errorMessage,SQLScript]);
        FFunctions.Items[itemNo] := Result;
      end;
   end;
end; // GetStoredFunctionByName


//------------------------------------------------------------------------------
// get all stored functions
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.InternalGetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList; SortNamesByAlphabet: Boolean);
var i,itemNo: Integer;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise EACRException.Create(12069,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise EACRException.Create(12070,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise EACRException.Create(12071,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise EACRException.Create(12072,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
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
          raise EACRException.Create(12068,ErrorLCannotFindFunction,[FunctionNames[i]]);
         FunctionSQLScripts.Add(FFunctionSQL.Strings[itemNo]);
        end;
   end;
end; //InternalGetStoredFunctions


//------------------------------------------------------------------------------
// export all functions to SQL
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.InternalExportStoredFunctionsToSQL(var SQL: WideString);
var i: Integer;
begin
  if (FHeader.Count <> FFunctionNames.Count) then
   raise EACRException.Create(12134,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
  if (FHeader.Count <> FFunctionSQL.Count) then
   raise EACRException.Create(12135,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
  if (FHeader.Count <> FFunctions.Count) then
   raise EACRException.Create(12136,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
  if (FHeader.Count <> Length(FFunctionHeaders)) then
   raise EACRException.Create(12137,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
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
constructor TACRStoredFunctionManager.Create(DatabaseData: TACRDatabaseData);
begin
  LDatabaseData := DatabaseData;
  FThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self);
//  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FFunctionNames := TACRObjectNameArray.Create;
  FFunctionSQL := TACRObjectNameArray.Create;
  FFunctions := TList.Create;
  FFunctionHeaders := nil;
  FillChar(FHeader,SizeOf(FHeader),$00);
  FTempFunctions := TList.Create;
  FTempNamesCRC := TACRIntegerArray.CReate;
  FTempSQLCRC := TACRIntegerArray.CReate;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRStoredFunctionManager.Destroy;
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
procedure TACRStoredFunctionManager.Load(stream: TStream; SkipSFMHeader: Boolean);
var i,j,dataSize:             Integer;
    headerSize:               Int64;
    nameCRC,SQLCRC:           Cardinal;
    sf:                       TACRStoredFunction;
begin
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('> TACRStoredFunctionManager.Load');
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
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('1 TACRStoredFunctionManager.Load, stream.Size = '+IntToStr(stream.Size)+#13#10+'SkipSFMHeader = '+BoolToStr(SkipSFMHeader,True));
{$ENDIF}
    if (not SkipSFMHeader) then
      LoadDataFromStream(FHeader,SizeOf(FHeader),stream,12013);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('2 TACRStoredFunctionManager.Load, stream.Size = '+IntToStr(stream.Size)
+#13#10+'FHeader.Count = '+IntToStr(FHeader.Count)
+#13#10+'FHeader.State = '+IntToStr(FHeader.State)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
    headerSize := Int64(FHeader.Count) * Int64(SizeOf(TACRStoredFunctionHeader));
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('3 TACRStoredFunctionManager.Load, headerSize = '+IntToStr(headerSize));
{$ENDIF}
    if (Stream.Position + headerSize > Stream.Size) then
     raise EACRException.Create(12471,ErrorLCannotLoadStoredFunctionsSmallStream,[stream.Position,stream.Size,headerSize,FHeader.Count]);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('3.1 TACRStoredFunctionManager.Load, headerSize = '+IntToStr(headerSize));
{$ENDIF}
    SetLength(FFunctionHeaders,FHeader.Count);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('3.2 TACRStoredFunctionManager.Load, headerSize = '+IntToStr(headerSize));
{$ENDIF}
    if (FHeader.Count > 0) then
    begin
      LoadDataFromStream(FFunctionHeaders[0],headerSize,stream,12014);
    end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('4 TACRStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
{$ENDIF}
    try
      FFunctionNames.LoadFromStream(stream);
    except
      on e: Exception do
       raise EACRException.Create(12015,ErrorLCannotLoadStoredFunctions,[e.Message]);
    end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('5 TACRStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
{$ENDIF}
    try
      FFunctionSQL.LoadFromStream(stream);
    except
      on e: Exception do
       raise EACRException.Create(12016,ErrorLCannotLoadStoredFunctions,[e.Message]);
    end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('6 TACRStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
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
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('7 TACRStoredFunctionManager.Load, stream.Position = '+IntToStr(stream.Position));
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
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Load}
aaWriteToLog('< TACRStoredFunctionManager.Load');
except
 on e:Exception do
 begin
   aaWriteToLog('Error in TACRStoredFunctionManager.Load:'+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // Load


//------------------------------------------------------------------------------
// save all data to stream
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.Save(ms: TACRMemoryStream; bSkipSFMHeader: Boolean);
var headerSize,dataSize: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('> TACRStoredFunctionManager.Save(ms)');
try
{$ENDIF}
  headerSize := FHeader.Count * SizeOf(TACRStoredFunctionHeader);
  dataSize := SizeOf(FHeader) + headerSize;
  dataSize := dataSize + FFunctionNames.SaveToStream(ms,True);
  dataSize := dataSize + FFunctionSQL.SaveToStream(ms,True);

  ms.Size := dataSize;
  ms.Position := 0;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('1 TACRStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
);
{$ENDIF}
  if (not bSkipSFMHeader) then
    SaveDataToStream(FHeader,SizeOf(FHeader),ms,11991);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('2 TACRStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
+#13#10+'FHeader.Count = '+IntToStr(FHeader.Count)
+#13#10+'FHeader.State = '+IntToStr(FHeader.State)
);
{$ENDIF}
  if (FHeader.Count > 0) then
    SaveDataToStream(FFunctionHeaders[0],headerSize,ms,11992);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('3 TACRStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
);
{$ENDIF}
  try
    FFunctionNames.SaveToStream(ms);
  except
    on e: Exception do
      raise EACRException.Create(11994,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('4 TACRStoredFunctionManager.Save(ms), ms.Size = '+IntToStr(ms.Size)
+#13#10+'ms.Position = '+IntToStr(ms.Position)
);
{$ENDIF}
  try
    FFunctionSQL.SaveToStream(ms);
  except
    on e: Exception do
      raise EACRException.Create(11995,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('< TACRStoredFunctionManager.Save(ms)');
except
 on e:Exception do
 begin
   aaWriteToLog('Error in TACRStoredFunctionManager.Save(ms):'+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // Save


//------------------------------------------------------------------------------
// save all data to stream
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.Save(stream: TStream);
var headerSize,dataSize: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('> TACRStoredFunctionManager.Save(stream)');
try
{$ENDIF}
  headerSize := FHeader.Count * SizeOf(TACRStoredFunctionHeader);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('1 TACRStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
+#13#10+'headerSize = '+IntToStr(headerSize)
);
{$ENDIF}
  SaveDataToStream(FHeader,SizeOf(FHeader),stream,12017);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('2 TACRStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
  if (FHeader.Count > 0) then
    SaveDataToStream(FFunctionHeaders[0],headerSize,stream,12018);
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('3 TACRStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
  try
    FFunctionNames.SaveToStream(stream);
  except
    on e: Exception do
      raise EACRException.Create(12019,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('4 TACRStoredFunctionManager.Save(ms), stream.Size = '+IntToStr(stream.Size)
+#13#10+'stream.Position = '+IntToStr(stream.Position)
);
{$ENDIF}
  try
    FFunctionSQL.SaveToStream(stream);
  except
    on e: Exception do
      raise EACRException.Create(12020,ErrorLCannotLoadStoredFunctions,[e.Message]);
  end;
{$IFDEF DEBUG_TRACE_TACRStoredFunctionManager_Save}
aaWriteToLog('< TACRStoredFunctionManager.Save(stream)');
except
 on e:Exception do
 begin
   aaWriteToLog('Error in TACRStoredFunctionManager.Save(stream):'+#13#10+e.Message);
   raise;
 end;
end;
{$ENDIF}
end; // Save


//------------------------------------------------------------------------------
// create stored function
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.CreateStoredFunction(Session: TACRBaseSession; SQLScript: WideString);
var storedFunction: TACRStoredFunction;
    errorMessage:   WideString;
begin
  storedFunction := ParseCreateStoredFunction(Session,SQLScript,True,errorMessage);
  if (storedFunction = nil) then
   raise EACRException.Create(12012,ErrorLErrorParsingStoredFunction,[errorMessage,SQLScript]);
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
procedure TACRStoredFunctionManager.CreateStoredFunction(
                  StoredFunction:   TACRStoredFunction;
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
procedure TACRStoredFunctionManager.ParseStoredFunction(
              Session:              TACRBaseSession;
              Lexer:                TACRLexer;
              var Token:            TToken;
              out StoredFunction:   TACRStoredFunction;
              out SQLScript:        WideString
                             );
var
    errorMessage:   WideString;
begin
  StoredFunction := InternalParseCreateStoredFunction(
                      True,Session,Lexer,Token,True,SQLScript,errorMessage);
  if (storedFunction = nil) then
   raise EACRException.Create(12103,ErrorLErrorParsingStoredFunction,[errorMessage,SQLScript]);
  if (Length(SQLScript) <= 0) then
   begin
     errorMessage := StoredFunction.FunctionName;
     StoredFunction.Free;
     raise EACRException.Create(12112,ErrorLErrorParsingStoredFunctionEmptyScript,
            [errorMessage,Token.Text,Token.LineNum,Token.ColumnNum]);
   end;
end; // ParseStoredFunction


//------------------------------------------------------------------------------
// drop stored function
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.DropStoredFunction(
                                    Session:      TACRBaseSession;
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
procedure TACRStoredFunctionManager.AlterStoredFunction(
                                    Session:      TACRBaseSession;
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
procedure TACRStoredFunctionManager.AlterStoredFunctionRename(
                                Session:          TACRBaseSession;
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
// for calls from TACRDatabase.ExecuteStoredFunction
// execute stored function - return false if function does not exist
// if function has no result (procedure) ResultValue will be set to nil
// params - list of TACRSQLParam
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ExecuteStoredFunction(
                                    Session:          TACRBaseSession;
                                    FunctionName:     WideString;
                                    ResultValue:      TACRVariant;
                                    Params:           TACRSQLParams
                                                        ): Boolean;
var i:            Integer;
    sf:           TACRStoredFunction;
    localParams:  TACRSQLParams;
begin
  if (Params <> nil) then
   begin
    if (not (TObject(Params) is TACRSQLParams)) then
     raise EACRException.Create(12198,ErrorLInvalidClass,
      ['TACRSQLParams',TObject(Params).ClassName,IntToHex(Integer(Params),8)]);
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
function TACRStoredFunctionManager.FindStoredFunction(FunctionName: WideString): WideString;
var itemNo: Integer;
begin
  Result := '';
  Lock(False);
  try
    if (FHeader.Count <> FFunctionNames.Count) then
     raise EACRException.Create(12073,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionNames.Count]);
    if (FHeader.Count <> FFunctionSQL.Count) then
     raise EACRException.Create(12074,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctionSQL.Count]);
    if (FHeader.Count <> FFunctions.Count) then
     raise EACRException.Create(12075,ErrorLInvalidFunctionCount,[FHeader.Count,FFunctions.Count]);
    if (FHeader.Count <> Length(FFunctionHeaders)) then
     raise EACRException.Create(12076,ErrorLInvalidFunctionCount,[FHeader.Count,Length(FFunctionHeaders)]);
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
// used by TACRExprNodeStoredFunction
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.GetStoredFunctionByName(FunctionName: WideString; Session: TACRBaseSession): TObject;
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
// return stored function object (TACRStoredFunction) if found or nil
// params - list of TACRExpression
//------------------------------------------------------------------------------
function TACRStoredFunctionManager.ParseStoredFunctionParams(
                Session:          TACRBaseSession;
                Lexer:            TACRLexer;
                parentFunction:   TObject; // parent TACRStoredFunction object, where parser was called
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
     TACRStoredFunction(Result).IncUseCount;
}     
  finally
    Unlock;
  end;
  // parse params
  if (Result <> nil) then
    Params := ParseFunctionCallParams(Session,Lexer,parentFunction,Token,TACRStoredFunction(Result));
end; // ParseStoredFunctionParams


//------------------------------------------------------------------------------
// return list of stored function names (optionally SQL scripts for their creation)
//------------------------------------------------------------------------------
procedure TACRStoredFunctionManager.GetStoredFunctions(FunctionNames: TStrings; FunctionSQLScripts: TStrings; SortNamesByAlphabet: Boolean);
var names, scripts: TACRWideStringList;
begin
  if (FunctionNames = nil) then
   raise EACRException.Create(12111,ErrorLNilPointer)
  else
   names := TACRWideStringList.Create;
  if (FunctionSQLScripts = nil) then
   scripts := nil
  else
   scripts := TACRWideStringList.Create;
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
procedure TACRStoredFunctionManager.GetStoredFunctions(FunctionNames: TACRWideStringList; FunctionSQLScripts: TACRWideStringList; SortNamesByAlphabet: Boolean);
begin
  if (FunctionNames = nil) then
   raise EACRException.Create(12067,ErrorLNilPointer);
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
procedure TACRStoredFunctionManager.ExportStoredFunctionsToSQL(var SQL: WideString);
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
// TACRSQLAssign
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
procedure TACRSQLAssign.UpdateExpressionParams;
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
function TACRSQLAssign.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRSQLAssign.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLAssign.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  if (FVariable <> nil) then
   FreeAndNil(FVariable);
  if (FExpression <> nil) then
   FreeAndNil(FExpression);
  if (TACRSQLAssign(Source).FVariable <> nil) then
   begin
    FVariable := TACRExprNodeVariable.Create(nil,'',nil,0);
    FVariable.Assign(TACRSQLAssign(Source).FVariable);
   end;
  if (TACRSQLAssign(Source).FExpression <> nil) then
   begin
    FExpression := TACRExpression.Create;
    FExpression.Assign(TACRSQLAssign(Source).FExpression);
   end;
  FVariable.ParentExpr := FExpression;
end; // Assign


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRSQLAssign.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  FVariable := nil;
  FExpression := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRSQLAssign.Destroy;
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
procedure TACRSQLAssign.Parse;
var token:        TToken;
    paramIndex:   Integer;
    isSessionVar: Boolean;
begin
  if (not LLex.GetCurrentToken(token)) then
   raise EACRException.Create(12056,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  // parse variable name
  if (token.TokenType = tktString) or (IsReservedWord(token,rwResult)) then
   begin
    FVariable := nil;
    isSessionVar := ACRIsSessionVariable(token.Text);
    if (isSessionVar) then
     begin
       FVariable := TACRExprNodeVariable.Create(nil,Token.Text,nil,-1);
     end
    else
     begin
       if (LStoredFunction <> nil) then
        begin
         paramIndex := TACRStoredFunction(LStoredFunction).GetParamIndex(Token.Text);
         if (paramIndex >= 0) then
           FVariable := TACRExprNodeVariable.Create(nil,Token.Text,
                          TACRStoredFunction(LStoredFunction),paramIndex);
        end;
     end;
    if (FVariable = nil) then
      raise EACRException.Create(12055,ErrorLVariableNotFound,[token.Text]);
   end
  else
   raise EACRException.Create(12057,ErrorLVariableNameExpected,[token.Text,token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12058,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  // :=
  if (token.TokenType <> tktAssign) then
   raise EACRException.Create(12059,ErrorGOtherTokenExpected,
         [':=',token.Text,Token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12060,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  FExpression := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
  FExpression.StoredFunction := LStoredFunction;
  FExpression.ParseForValueExpression(LLex);
  FVariable.ParentExpr := FExpression;
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    begin
      LParamExprNodes := TACRList.Create;
      FExpression.ExtractAllParameterNodes(LParamExprNodes);
    end;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TACRSQLAssign.ExecSQL(
                      IsRoot,
                      RequestLive:  Boolean;
                      var ReadOnly: Boolean
                 );
var
    v:   TACRVariant;
begin
 FExpression.Session := FDatabaseParams.Session;
 FExpression.LocalParams := Params;
 v := FVariable.GetDataValue;
 // assign only value, do not copy name
 v.Assign(FExpression.GetValue,True,False);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRRSQLBeginEndCommandsBlock
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
procedure TACRRSQLBeginEndCommandsBlock.UpdateParams(SQLParams: TACRSQLParams);
var i: Integer;
begin
  for i := 0 to FCommands.Count-1 do
    TACRSQLCommand(FCommands.Items[i]).UpdateParams(SQLParams);
end; // UpdateParams


//------------------------------------------------------------------------------
// update expression params
//------------------------------------------------------------------------------
procedure TACRRSQLBeginEndCommandsBlock.UpdateExpressionParams;
var i: Integer;
begin
  for i := 0 to FCommands.Count-1 do
    TACRSQLCommand(FCommands.Items[i]).UpdateExpressionParams;
end; // UpdateExpressionParams


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRRSQLBeginEndCommandsBlock.CreateCopy: TACRSQLCommand;
begin
  Result := TACRRSQLBeginEndCommandsBlock.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRRSQLBeginEndCommandsBlock.Assign(Source: TACRSQLCommand);
var i:       Integer;
    command: TACRSQLCommand;
begin
  inherited Assign(Source);
  ACRClearCommands(FCommands);
  for i := 0 to TACRRSQLBeginEndCommandsBlock(Source).FCommands.Count-1 do
    begin
      command := TACRRSQLBeginEndCommandsBlock(Source).FCommands.Items[i];
      command := command.MakeCopy(FDatabaseParams.Session,LParams);
      FCommands.Add(command);
    end;
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TACRRSQLBeginEndCommandsBlock.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  FCommands := TList.Create;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TACRRSQLBeginEndCommandsBlock.Destroy;
begin
  if (FCommands <> nil) then
   begin
    ACRClearCommands(FCommands);
    FreeAndNil(FCommands);
   end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parses query
//------------------------------------------------------------------------------
procedure TACRRSQLBeginEndCommandsBlock.Parse;
var
    SQLProcessor: TACRBaseSQLProcessor;
begin
  LLex.GetCurrentToken(token);
  if (token.ReservedWord <> rwBEGIN) then
    raise EACRException.Create(12240,ErrorGOtherTokenExpected,
     [GetReservedWord(rwBEGIN),Token.Text,Token.LineNum,Token.ColumnNum]);
  SQLProcessor := TACRBaseSQLProcessor.Create(LStoredFunction,FDatabaseParams.Session);
  try
    ACRParseCommandsBlock(SQLProcessor,LLex,token,FCommands);
    LLex.GetCurrentToken(token);
  finally
    SQLProcessor.Free;
  end;
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TACRRSQLBeginEndCommandsBlock.ExecSQL(
                IsRoot,
                RequestLive:  Boolean;
                var ReadOnly: Boolean
                );
var i:        Integer;
    command:  TACRSQLCommand;
begin
  for i := 0 to FCommands.Count-1 do
   begin
    command := TACRSQLCommand(FCommands.Items[i]);
    if (command = nil) then
     raise EACRException.Create(12241,ErrorLNilPointer);
    command.ExecSQL(IsRoot,RequestLive,ReadOnly);
   end;
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLIfThenElse
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
procedure TACRSQLIfThenElse.UpdateExpressionParams;
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
function TACRSQLIfThenElse.CreateCopy: TACRSQLCommand;
begin
  Result := TACRSQLIfThenElse.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLIfThenElse.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  if (FIfCondition <> nil) then
   FreeAndNil(FIfCondition);
  if (FThenCommand <> nil) then
   FreeAndNil(FThenCommand);
  if (FElseCommand <> nil) then
   FreeAndNil(FElseCommand);
  if (TACRSQLIfThenElse(Source).FIfCondition <> nil) then
   begin
    FIfCondition := TACRExpression.Create;
    FIfCondition.Assign(TACRSQLIfThenElse(Source).FIfCondition);
   end;
  if (TACRSQLIfThenElse(Source).FThenCommand <> nil) then
   FThenCommand := TACRSQLIfThenElse(Source).FThenCommand.MakeCopy(FDatabaseParams.Session,LParams);
  if (TACRSQLIfThenElse(Source).FElseCommand <> nil) then
   FElseCommand := TACRSQLIfThenElse(Source).FElseCommand.MakeCopy(FDatabaseParams.Session,LParams);
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TACRSQLIfThenElse.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  FIfCondition := nil;
  FThenCommand := nil;
  FElseCommand := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TACRSQLIfThenElse.Destroy;
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
procedure TACRSQLIfThenElse.Parse;
var
    SQLProcessor: TACRBaseSQLProcessor;
begin
  // IF
  if (not LLex.GetCurrentToken(token)) then
   raise EACRException.Create(12231,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  if (token.ReservedWord <> rwIF) then
   raise EACRException.Create(12232,ErrorGOtherTokenExpected,
    [GetReservedWord(rwIF),token.Text,token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12233,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  FIfCondition := TACRExpression.Create(FDatabaseParams.Session,nil,nil,Self);
  FIfCondition.ParseForBooleanExpression(LLex);
  if (FDatabaseParams.Params <> nil) then
   if (FDatabaseParams.Params.Count > 0) then
    begin
      LParamExprNodes := TACRList.Create;
      FIfCondition.ExtractAllParameterNodes(LParamExprNodes);
    end;
  // THEN
  LLex.GetCurrentToken(Token);
  if (token.ReservedWord <> rwTHEN) then
   raise EACRException.Create(12234,ErrorGOtherTokenExpected,
    [GetReservedWord(rwTHEN),token.Text,token.LineNum,token.ColumnNum]);
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12242,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
  SQLProcessor := TACRBaseSQLProcessor.Create(LStoredFunction,FDatabaseParams.Session);
  try
    FThenCommand := SQLProcessor.ParseSQLCommand(LLex,Token);
    LLex.GetCurrentToken(Token);
    // check if ELSE exists
    if (Token.ReservedWord = rwELSE) then
     begin
      if (not LLex.GetNextToken(Token)) then
       raise EACRException.Create(12235,ErrorGUnexpectedEndOfCommand,[token.LineNum,token.ColumnNum]);
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
procedure TACRSQLIfThenElse.ExecSQL(
                IsRoot,
                RequestLive:  Boolean;
                var ReadOnly: Boolean
                );
var res: Boolean;
begin
  if (FIfCondition = nil) then
   raise EACRException.Create(12243,ErrorLNilPointer);
  res := FIfCondition.GetResult;
  if (res) then
   begin
    if (FThenCommand = nil) then
     raise EACRException.Create(12244,ErrorLNilPointer);
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
// TACRCreateStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRCreateStoredFunction.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRCreateStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRCreateStoredFunction.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  LCreateStoredFunction := TACRCreateStoredFunction(Source).LCreateStoredFunction;
  FSQLScript := TACRCreateStoredFunction(Source).FSQLScript;
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TACRCreateStoredFunction.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  LCreateStoredFunction := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Destroy


//------------------------------------------------------------------------------
// destroys object
//------------------------------------------------------------------------------
destructor TACRCreateStoredFunction.Destroy; 
begin
  if (LCreateStoredFunction <> nil) then
   try
     LCreateStoredFunction.Free;
   except
   end;
  ACRClearString(FSQLScript);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRCreateStoredFunction.Parse;
var f: TObject;
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12102,ErrorLNoActiveSession);
  if (not (FDatabaseParams.Session is TACRLocalSession)) then
   raise EACRException.Create(12106,ErrorLNoActiveSession);
  FDatabaseParams.Session.ParseStoredFunction(LLex,Token,f,FSQLScript);
  LCreateStoredFunction := TACRStoredFunction(f);
end; // Parse


//------------------------------------------------------------------------------
// executes query
//------------------------------------------------------------------------------
procedure TACRCreateStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12108,ErrorLNoActiveSession);
  if (not (FDatabaseParams.Session is TACRLocalSession)) then
   raise EACRException.Create(12109,ErrorLNoActiveSession);
  FDatabaseParams.Session.CreateStoredFunction(LCreateStoredFunction,FSQLScript);
  LCreateStoredFunction := nil;
  ACRClearString(FSQLScript);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRDropStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create copy
//------------------------------------------------------------------------------
function TACRDropStoredFunction.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRDropStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRDropStoredFunction.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FFunctionName := TACRDropStoredFunction(Source).FFunctionName;
end; // Assign


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRDropStoredFunction.Parse;
begin
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12165,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
  if (not IsStringToken(token)) then
    raise EACRException.Create(12162,ErrorLInvalidTokenType,[EACRTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  FFunctionName := token.Text;
  LLex.GetNextToken(token);
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRDropStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12163,ErrorLNoActiveSession);
  if (not (FDatabaseParams.Session is TACRLocalSession)) then
   raise EACRException.Create(12164,ErrorLNoActiveSession);
  FDatabaseParams.Session.DropStoredFunction(FFunctionName);
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRAlterStoredFunction
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
function TACRAlterStoredFunction.CreateCopy: TACRSQLCommand;
begin
  Result := TACRAlterStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRAlterStoredFunction.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  FFunctionName := TACRAlterStoredFunction(Source).FFunctionName;
  FNewScript := TACRAlterStoredFunction(Source).FNewScript;
  FNewFunctionName := TACRAlterStoredFunction(Source).FNewFunctionName;
  FAlterType := TACRAlterStoredFunction(Source).FAlterType;
end; // Assign


//------------------------------------------------------------------------------
// creates object
//------------------------------------------------------------------------------
constructor TACRAlterStoredFunction.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
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
destructor TACRAlterStoredFunction.Destroy;
begin
  ACRClearString(FNewScript);
  ACRClearString(FFunctionName);
  ACRClearString(FNewFunctionName);
  inherited Destroy;
end; // Create


//------------------------------------------------------------------------------
// parse query
//------------------------------------------------------------------------------
procedure TACRAlterStoredFunction.Parse;
begin
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12210,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
  if (not IsStringToken(token)) then
    raise EACRException.Create(12211,ErrorLInvalidTokenType,[EACRTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  FFunctionName := token.Text;
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12212,ErrorLAlterFunctionTypeExpected,[token.LineNum,token.ColumnNum]);
  if (IsQuotedStringToken(token)) then
   begin
    // modify
    FAlterType := atModifyFunction;
    if (not LLex.GetNextToken(token)) then
     raise EACRException.Create(12225,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
    if (not IsQuotedStringToken(token)) then
     raise EACRException.Create(12226,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
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
         raise EACRException.Create(12227,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
        if (not IsQuotedStringToken(token)) then
         raise EACRException.Create(12228,ErrorLAlterFunctionScriptExpected,[token.LineNum,token.ColumnNum]);
        FNewScript := token.Text;
      end;
     rwRENAME:
      begin
       FAlterType := atRenameFunction;
       LLex.GetNextToken(token);
       if (token.ReservedWord <> rwTO) then
         raise EACRException.Create(12213,ErrorLAlterFunctionTypeExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
       LLex.GetNextToken(token);
       if (IsStringToken(token)) then
        FNewFunctionName := token.Text
       else
         raise EACRException.Create(12216,ErrorLAlterFunctionNewNameExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
      end
     else
       raise EACRException.Create(12214,ErrorLAlterFunctionTypeExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
    end;
   end
  else
   raise EACRException.Create(12215,ErrorLAlterFunctionTypeExpectedButFound,[token.Text,token.LineNum,token.ColumnNum]);
  FErrLine := token.LineNum;
  FErrColumn := token.ColumnNum;
end; // Parse


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRAlterStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
begin
  if (FDatabaseParams.Session = nil) then
   raise EACRException.Create(12217,ErrorLNilPointer);
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
    raise EACRException.Create(12229,ErrorLAlterFunctionTypeIsNotParsed,[FErrLine,FErrColumn]);
  end;
end; // ExecSQL




////////////////////////////////////////////////////////////////////////////////
//
// TACRExecuteStoredFunction
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// updates all expressions - sets LSession, LParams (needed for stored functions)
//------------------------------------------------------------------------------
procedure TACRExecuteStoredFunction.UpdateExpressionParams;
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
function TACRExecuteStoredFunction.CreateCopy: TACRSQLCommand;
begin
  // do not parse again
  Result := TACRExecuteStoredFunction.Create(nil,FDatabaseParams,LStoredFunction);
end; // CreateCopy


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRExecuteStoredFunction.Assign(Source: TACRSQLCommand);
begin
  inherited Assign(Source);
  LExecuteStoredFunction := TACRExecuteStoredFunction(Source).LExecuteStoredFunction;
  if (FParams <> nil) then
   FreeAndNil(FParams);
  if (TACRExecuteStoredFunction(Source).FParams <> nil) then
   begin
    FParams := TACRExpressions.Create;
    FParams.Assign(TACRExecuteStoredFunction(Source).FParams);
   end;
end; // Assign


//------------------------------------------------------------------------------
// create object
//------------------------------------------------------------------------------
constructor TACRExecuteStoredFunction.Create(Lexer: TACRLexer; aDatabaseParams: TACRSQLDatabaseParams; aStoredFunction: TObject);
begin
  LExecuteStoredFunction := nil;
  FParams := nil;
  inherited Create(Lexer,aDatabaseParams,aStoredFunction);
end; // Create


//------------------------------------------------------------------------------
// destroy object
//------------------------------------------------------------------------------
destructor TACRExecuteStoredFunction.Destroy;
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
procedure TACRExecuteStoredFunction.Parse;
var aParams: TObject;
begin
  if (not LLex.GetNextToken(token)) then
   raise EACRException.Create(12178,ErrorLFunctionNameExpected,[token.LineNum,token.ColumnNum]);
  if (not IsStringToken(token)) then
    raise EACRException.Create(12179,ErrorLInvalidTokenType,[EACRTokenType[Integer(token.TokenType)],token.Text,token.LineNum,token.ColumnNum]);
  LExecuteStoredFunction := nil;
  if (FDatabaseParams.Session <> nil) then
    if (FDatabaseParams.Session is TACRLocalSession) then
      begin
       LExecuteStoredFunction := TACRStoredFunction(
          TACRLocalSession(FDatabaseParams.Session).ParseStoredFunctionParams(LLex, LStoredFunction, Token,aParams));
       if (LExecuteStoredFunction = nil) then
        raise EACRException.Create(12180,ErrorLCannotExecuteFunctionNotParsed,
              [Token.Text,Token.LineNum,Token.ColumnNum]);
      end;
  if (LExecuteStoredFunction = nil) then
   raise EACRException.Create(12181,ErrorLCannotExecuteFunctionNoActiveSession,
          [Token.Text,Token.LineNum,Token.ColumnNum]);
  LLex.GetNextToken(token);
  FParams := TACRExpressions(aParams);
end; // ExecSQL


//------------------------------------------------------------------------------
// execute query
//------------------------------------------------------------------------------
procedure TACRExecuteStoredFunction.ExecSQL(
                  IsRoot,
                  RequestLive:  Boolean;
                  var ReadOnly: Boolean
                 );
var localParams: TACRSQLParams;
    i:           Integer;
begin
  if (LExecuteStoredFunction = nil) then
   raise EACRException.Create(12182,ErrorLNilPointer);
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
// return true if text is a session variable name - starting from ACR_SES_VAR_SIGN
//------------------------------------------------------------------------------
function ACRIsSessionVariable(text: WideString): Boolean;
begin
  Result := False;
  if (Length(text) > 0) then
   Result := (text[1] = ACR_SES_VAR_SIGN);
end; // ACRIsSessionVariable


//------------------------------------------------------------------------------
// parse commads block (<command> or BEGIN <command #1>;...<command #N>; END;
//------------------------------------------------------------------------------
procedure ACRParseCommandsBlock(
                        SQLProcessor:     TACRBaseSQLProcessor;
                        Lexer:            TACRLexer;
                        var token:        TToken;
                        var commandsList: TList
                               );
var
    command:      TACRSQLCommand;
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
      raise EACRException.Create(12239,ErrorLCannotParseSQLCommand,
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
       raise EACRException.Create(12245,ErrorGUnexpectedEndOfCommand,
        [token.LineNum,token.ColumnNum]);
     end;
  until (beginCount = 0);
end; // ACRParseCommandsBlock




initialization


{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('< ACRStoredFunctions initialized');
{$ENDIF}
  ACRMemoryIncUseCount;


finalization

  ACRMemoryDecUseCount;


end.