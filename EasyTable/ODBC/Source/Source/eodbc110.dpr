{DEFINE DEBUG_LOG}
{DEFINE DEBUG_MEMCHECK}

{DEFINE SQLCOLUMNS_TABLE_NOT_FOUND_DEBUG_LOG}

library eodbc;

uses
//  ShareMem,
  windows,
  SysUtils,
  dialogs,
  Classes,
  Forms,
//  Math,
  Db,
{$IFDEF DEBUG_MEMCHECK}
  MemCheck,
{$ENDIF}
  EasyTable,
  constSQL in 'constSQL.pas',
  DSNsetup in 'DSNsetup.pas' {DSNsetupForm},
  constODBC in 'constODBC.pas';

{$R *.res}

Const
// Driver
  DRIVER_ODBC_VERSION       = '02.50';
  DRIVER_VERSION            = '01.10.00';
  ODBC_DRIVER               = 'ODBC v.2 Driver';
  DRIVER_NAME               = 'EasyTable ODBC v.2 Driver';
  DBMS_NAME                 = 'EasyTable';
  DRIVER_NONDSN_TAG         = 'DRIVER={EasyTable ODBC v.2 Driver}';
  DRIVER_DLL_NAME           = 'eodbc.dll';

// EasyTable
  DEFAULT_TXN_ISOLATION     = SQL_TC_NONE;// - transactions are not supported
  IDENTIFIER_QUOTE          = ' ';
  CONSTANT_QUOTE            = '''';
  MAX_IDENTIFIER_LENGTH     = 253;
  MAX_SQL_TEXT_LENGTH       = 4096;//4294967295;

// General
  _MAX_PATH = 260; //stdlib.h
  MAX_NAME_LENGTH = 256;
  SQL_MAX_MESSAGE_LENGTH = 512; //SQL.H

Type

//  UDWORD = SQLSMALLINT; - error!
  UDWORD = SQLUINTEGER;

// Enviroment Handle
  PEnv = ^TEnv;
  TEnv = Record
    TypeInfo:TEasyTable;
  end;

// Connection Handle
  PConnection = ^TConnection;
  TConnection = Record
    TypeInfo:TEasyTable;
    Database: Array [0.._MAX_PATH-1] of Char;
    DSN: Array [0..MAX_NAME_LENGTH-1] of Char;
  end;

//BindParam
  pBindParam = ^TBindParam;
  TBindParam = Record
        		 ParameterNumber:SQLUSMALLINT;
        		 IOType:SQLSMALLINT;
        		 ValueType:SQLSMALLINT;
        		 ParameterType:SQLSMALLINT;
        		 ColumnSize:SQLUINTEGER;
        		 DecimalDigits:SQLSMALLINT;
        		 ParameterValuePtr:Pointer;
        		 BufferLength:SQLINTEGER;
        		 StrLen_or_IndPtr:PInteger //{UNALIGNED} SDWORD
  end;

// Statement Handle
  PStmt = ^TStmt;
  TStmt = Record
    Options: Array [SQL_STMT_OPT_MIN..SQL_STMT_OPT_MAX] of UDWORD;
    Database:PChar;
//    DSN:PChar;
    TypeInfo:TEasyTable;
    SQLtext:PChar;
    Result:TEasyQuery;
    FreshResult:Boolean;
    Bind:TEasyTable;
    BindingOffset:Integer;
    BindParam: Array of TBindParam;
    Fetched:Boolean;   // Fix for MS Query due it doesnot call SQLFreeStmt with SQL_UNBIND
  end;

{
Const
  ConnectionHandleSize : Integer = SizeOf(TConnection);
  EnvHandleSize : Integer = SizeOf(TEnv);
  StmtHandleSize : Integer = SizeOf(TStmt);
}
type
  HENV = LongInt;
  PHENV = ^HENV;
  HDBC = Integer;
  PHDBC = ^ HDBC;
  HSTMT = Integer;
  PHSTMT = ^ HSTMT;
//  HWND = handle;
  UWORD = SQLUSMALLINT;
  SWORD = SQLSMALLINT;
  PTR = SQLPOINTER;
  SDWORD = SQLINTEGER;
  UCHAR = PCHAR;
{
//SQLTYPES.H
#ifdef WIN32
#define SQL_API  __stdcall
}

  RETCODE = SmallInt;
{
//SQLFRONT.H
#define RETCODE INT
}
  INT = Smallint;

// SQLPostInstallerError - to post *pfErrorCode value to the installer error buffer
// Never used :)))

procedure WriteToLog(s : string);
 {$IFDEF DEBUG_LOG}
var
 f : Text;
 LogFileName : String;
 {$ENDIF}
begin
 {$IFDEF DEBUG_LOG}
// GetModuleFileName(GetModuleHandle('eodbc.dll'),PChar(LogFileName),_MAX_PATH);
// LogFileName := ExtractFilePath(LogFileName)+'MemCheck.log';
 LogFileName := 'T:\_DelphiProjects\_eodbc-test\eodbc.log';
 Assign(f,LogFileName);
 if (FileExists(LogFileName)) then
  Append(f)
 else
  ReWrite(f);
 Writeln(f,s);
 Close(f);
 {$ENDIF}
end;

////////////////////////////////
//       Installer DLL        //
////////////////////////////////
{
Function SQLInstallDriverManager(
            lpszPath:lpStr;
            cbPathMax:Word;
            var pcbPathOut:Word
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLInstallDriverEx(
            lpszDriver:lpcStr;
            lpszPathIn:lpcStr;
            lpszPathOut:lpStr;
            cbPathOutMax:Word;
            var pcbPathOut:Word;
            fRequest:Word;
            var lpdwUsageCount:DWord
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLConfigDriver(
            hwndParent:hwnd;
            fRequest:Word;
            lpszDriver:lpcStr;
            lpszArgs:lpcStr;
            lpsMsg:lpStr;
            cbMsgMax:Word;
            var pcbMsgOut:Word
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLInstallerError(
            iError:Word;
            var pfErrorCode:DWord;
            lpszErrorMsg:lpStr;
            cbErrorMsgMax:Word;
            var pcbErrorMsg:Word
                            ):Smallint;far;external 'odbccp32.dll'
}
Function SQLWriteDSNToIni(
            lpszDSN:        LPCSTR;
            lpszDriver:     LPCSTR
                            ):Boolean;stdcall;far;external 'odbccp32.dll'

Function SQLRemoveDSNFromIni(
            lpszDSN:LPCSTR
                            ):Boolean;stdcall;far;external 'odbccp32.dll'

Function SQLWritePrivateProfileString(
            lpszSection:LPCSTR;
            lpszEntry:LPCSTR;
            lpszString:LPCSTR;
            lpszFilename:LPCSTR
                            ):Boolean;stdcall;far;external 'odbccp32.dll'

Function SQLGetPrivateProfileString(
            lpszSection:LPCSTR;
            lpszEntry:LPCSTR;
            lpszDefault:LPCSTR;
            RetBuffer:LPCSTR;
            cbRetBuffer:INT;
            lpszFilename:LPCSTR
                            ):INT;stdcall;far;external 'odbccp32.dll'
{
Function SQLConfigDataSource(
            hwndParent:HWND;
            fRequest:WORD;
            lpszDriver:LPCSTR;
            lpszAttributes:LPCSTR
                            ):Boolean;far;external 'odbccp32.dll'
}

////////////////////////////////
//         Driver DLL         //
////////////////////////////////

procedure InitTypeInfo(Stmt:PStmt); Forward;// Prepare TypeInfo data about dataset's SQL data types

///// SQLAllocHandle /////

Function SQLAllocHandle  (
     arg0:SQLSMALLINT;
		 arg1:SQLHANDLE;
		 var arg2:SQLHANDLE): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLAllocHandle called');
	Result:=SQL_SUCCESS;
end;

///// SQLAllocEnv /////

Function SQLAllocEnv  (var Env:PEnv//HENV
                        ): RETCODE; stdcall;
//var Handle: pointer;
begin
	WriteToLog('>>> SQLAllocEnv called');
  Env:=AllocMem(SizeOf(TEnv));
//  Move(Handle,EnvHandle,4);
  Env.TypeInfo := TEasyTable.Create(nil);
WriteToLog('    @TypeInfo='+IntToHex(Integer(Env.TypeInfo),8));
	Result:=SQL_SUCCESS;
end;

///// SQLAllocConnect /////

Function SQLAllocConnect  (
           Env: pEnv;//        HENV;
		    	 var Connection:PConnection//  HDBC
       ): RETCODE; stdcall;
//var table22:TEasyTable;
begin
WriteToLog('>>> SQLAllocConnect called');
  Connection:=AllocMem(SizeOf(TConnection));
  Connection.TypeInfo := Env.TypeInfo;
  Connection.DSN := '';
  Connection.Database := '';
	Result := SQL_SUCCESS;
WriteToLog('### SQLAllocConnect');
end;

///// SQLAllocStmt /////
Function SQLAllocStmt  (
            Connection:PConnection;//HDBC;
		        var Stmt:PStmt//HSTMT
                        ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLAllocStmt called');
WriteToLog('    @Connection='+IntToHex(Integer(Connection),6));
  Stmt:=AllocMem(SizeOf(TStmt));

  Stmt.Database:=Connection.Database;
WriteToLog('    @Database='+IntToHex(Integer(Stmt.Database),6));
WriteToLog('    Database='+Stmt.Database);
WriteToLog('    @Connection='+IntToHex(Integer(Connection),6));
WriteToLog('    @Connection.TypeInfo='+IntToHex(Integer(Connection.TypeInfo),6));

  Stmt.TypeInfo := Connection.TypeInfo;
WriteToLog('    @Stmt.TypeInfo='+IntToHex(Integer(Stmt.TypeInfo),6));

  // Set default statement options
  Stmt.Options[SQL_ROWSET_SIZE]:=1;
  Stmt.Options[SQL_BIND_TYPE]:=SQL_BIND_TYPE_DEFAULT;
  Stmt.Options[SQL_USE_BOOKMARKS]:=SQL_UB_OFF;
  Stmt.BindingOffset := SQL_NULL_HANDLE;

  // Create binding array (i.e. table :)
      try
  Stmt.Bind := TEasyTable.Create(nil);
  Stmt.Bind.TableName := 'Bind'
    +IntToStr(Integer(Stmt)); // Unique TableName for InMemory table
  Stmt.Bind.InMemory := True;
//  Stmt.Bind.CreateTable;
  Stmt.Bind.FieldDefs.Add('ColumnNumber',ftInteger,0,True);
  Stmt.Bind.FieldDefs.Add('TargetType',ftInteger,0,True);
  Stmt.Bind.FieldDefs.Add('Buffer',ftInteger,0,True);
  Stmt.Bind.FieldDefs.Add('BufferLength',ftInteger,0,True);
  Stmt.Bind.FieldDefs.Add('StrLen_or_Ind',ftInteger,0,True);
  Stmt.Bind.CreateTable;
  Stmt.Bind.Active := True;
  Stmt.Fetched := False; // Fix for MS Query -- see SQLBindCol and SQLFetch
      except
       on e: Exception do
        begin
WriteToLog('Error - Unable to create Stmt.Bind: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end; // try
WriteToLog('    @Bind='+IntToHex(Integer(Stmt.Bind),6));

  // Create result set
      try
  Stmt.Result := TEasyQuery.Create(nil);
  Stmt.Result.InMemory := True;
      except
       on e: Exception do
        begin
WriteToLog('Error - Unable to create Stmt.Result: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end; // try
  Stmt.FreshResult := False; // No result yet
      try
  Stmt.SQLtext:=AllocMem(MAX_SQL_TEXT_LENGTH);
      except
       on e: Exception do
        begin
WriteToLog('Error - Unable to alloc memory for Stmtm.SQLtext: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end; // try
WriteToLog('    @Result='+IntToHex(Integer(Stmt.Result),6));

  // finish
WriteToLog('    Stmt='+IntToHex(Integer(Stmt),8));
WriteToLog('### SQLAllocStmt finished');
  Result:=SQL_SUCCESS;
end;

{
Function SQLAllocStmt  (
            arg0:HDBC;
		        var StmtHandle:HSTMT
                        ): RETCODE; stdcall;
var Handle: pointer;
begin
	WriteToLog('>>> SQLAllocStmt called');
  Handle:=AllocMem(SizeOf(TStmt));
  Move(Handle,StmtHandle,4);
	Result:=SQL_SUCCESS;
end;
}
///// SQLFreeConnect /////

Function SQLFreeConnect  (Connection:PConnection): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLFreeConnect called');
  FreeMem(Connection);
	Result:=SQL_SUCCESS;
end;

///// SQLFreeStmt /////

Function SQLFreeStmt  (
//            StmtHandle:HSTMT;
            Stmt:PStmt;
            Option:UWORD): RETCODE; stdcall;
begin
WriteToLog('>>> SQLFreeStmt');
WriteToLog('    Stmt='+IntToHex(Integer(Stmt),6));
{
SQL_CLOSE: Closes the cursor associated with StatementHandle (if one was defined) and discards all pending results. The application can reopen this cursor later by executing a SELECT statement again with the same or different parameter values. If no cursor is open, this option has no effect for the application. SQLCloseCursor can also be called to close a cursor. For more information, see Closing the Cursor.
SQL_DROP: This option is deprecated. A call to SQLFreeStmt with an Option of SQL_DROP is mapped in the Driver Manager to SQLFreeHandle.
SQL_UNBIND: Sets the SQL_DESC_COUNT field of the ARD to 0, releasing all column buffers bound by SQLBindCol for the given StatementHandle. This does not unbind the bookmark column; to do that, the SQL_DESC_DATA_PTR field of the ARD for the bookmark column is set to NULL. Note that if this operation is performed on an explicitly allocated descriptor that is shared by more than one statement, the operation will affect the bindings of all statements that share the descriptor. For more information, see Overview of Retrieving Results (Basic).
SQL_RESET_PARAMS: Sets the SQL_DESC_COUNT field of the APD to 0, releasing all parameter buffers set by SQLBindParameter for the given StatementHandle. If this operation is performed on an explicitly allocated descriptor that is shared by more than one statement, this operation will affect the bindings of all the statements that share the descriptor.
}
  Result:=SQL_SUCCESS;
  Case Option of
   SQL_CLOSE:  // 0
     ;
   SQL_DROP: // 1
     begin
      WriteToLog('    @Result='+IntToHex(Integer(Stmt.Result),6));
      Stmt.Result.Free;
      //Stmt.Result := nil;
WriteToLog('    @Result='+IntToHex(Integer(Stmt.Result),6));
      Stmt.Bind.Active:=False;
WriteToLog('    @Bind='+IntToHex(Integer(Stmt.Bind),6));
      Stmt.Bind.Free;
      //Stmt.Bind := nil;
      SetLength(Stmt.BindParam,0);
      //Stmt.BindParam := nil;
WriteToLog('    @Bind='+IntToHex(Integer(Stmt.Bind),6));
WriteToLog('    Tables freed');
WriteToLog('    @Database='+IntToHex(Integer(Stmt.Database),6));
WriteToLog('    Database='+Stmt.Database);
      try
        FreeMem(Stmt.SQLtext);
      except
       on e: Exception do
        begin
WriteToLog('Error - FreeMem(Stmt.SQLtext): ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end;
      try
        FreeMem(Stmt);
      except
       on e: Exception do
        begin
WriteToLog('Error - FreeMem(Stmt): ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end;
     end; // SQL_DROP:
   SQL_UNBIND: // 2
     begin
WriteToLog('    Bind='+IntToHex(Integer(Stmt.Bind),6));
      Stmt.Bind.Active:=False;
WriteToLog('    Bind.Active=False');
      Stmt.Bind.EmptyTable;
      try
  Stmt.Bind.Active := True;
      except
       on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end; //try
      //Stmt.Bind := nil;
WriteToLog('    Bind='+IntToHex(Integer(Stmt.Bind),6));
     end;
   SQL_RESET_PARAMS: // 3
     begin
WriteToLog('    Length(BindParam)='+IntToStr(Length(Stmt.BindParam)));
      SetLength(Stmt.BindParam,0);
WriteToLog('    Length(BindParam)='+IntToStr(Length(Stmt.BindParam)));
     end;
  else // case
WriteToLog('    Unknown Option');
    Result:=SQL_ERROR;
  end;

WriteToLog('### SQLFreeStmt called with option '+IntToStr(Option));
end;

///// SQLFreeEnv /////

Function SQLFreeEnv  (Env:PEnv): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLFreeEnv called');

WriteToLog('    @TypeInfo='+IntToHex(Integer(Env.TypeInfo),8));
  try
    Env.TypeInfo.Free;
  except
   on e: Exception do
    begin
WriteToLog('Error - FreeMem(Env):' + e.Message);
      Result:=SQL_ERROR;
      Exit;
    end;
  end; //try
WriteToLog('    @TypeInfo='+IntToHex(Integer(Env.TypeInfo),8));
  Env.TypeInfo := nil;
WriteToLog('    @TypeInfo='+IntToHex(Integer(Env.TypeInfo),8));

WriteToLog('    try FreeMem(Env)');
  try
    FreeMem(Env);
  except
   on e: Exception do
    begin
WriteToLog('Error - FreeMem(Env):' + e.Message);
      Result:=SQL_ERROR;
      Exit;
    end;
  end; //try
	Result:=SQL_SUCCESS;
	WriteToLog('### SQLFreeEnv');
end;

///// SQLFreeHandle /////

Function SQLFreeHandle  (arg0:SQLSMALLINT;
		 arg1:SQLHANDLE): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLFreeHandle called');
	Result:=SQL_SUCCESS;
end;

///// SQLDescribeCol /////

function GetDataTypeName(dt: TFieldType): String;
begin
{
      (fieldType : ftAutoInc;     sqlName : 'AUTOINC';    name : 'AutoInc'),
      (fieldType : ftInteger;     sqlName : 'INTEGER';    name : 'Integer'),
      (fieldType : ftString;      sqlName : 'STRING';     name : 'String'),
      (fieldType : ftWideString;  sqlName : 'WIDESTRING'; name : 'Wide String'),
      (fieldType : ftDate;        sqlName : 'DATE';       name : 'Date'),
      (fieldType : ftTime;        sqlName : 'TIME';       name : 'Time'),
      (fieldType : ftDateTime;    sqlName : 'DATETIME';   name : 'DateTime'),
      (fieldType : ftCurrency;    sqlName : 'CURRENCY';   name : 'Currency'),
      (fieldType : ftBoolean;     sqlName : 'LOGICAL';    name : 'Logical'),
      (fieldType : ftMemo;        sqlName : 'MEMO';       name : 'Memo'),
      (fieldType : ftFmtMemo;     sqlName : 'FMTMEMO';    name : 'Formatted Memo'),
      (fieldType : ftGraphic;     sqlName : 'GRAPHIC';    name : 'Graphic'),
      (fieldType : ftBLOB;        sqlName : 'BLOB';       name : 'BLOB'),
      (fieldType : ftSmallInt;    sqlName : 'SMALLINT';   name : 'Small Integer'),
      (fieldType : ftWord;        sqlName : 'WORD';       name : 'Word'),
      (fieldType : ftFloat;       sqlName : 'FLOAT';      name : 'Float'),
      (fieldType : ftBCD;         sqlName : 'BCD';        name : 'BCD'),
      (fieldType : ftBytes;       sqlName : 'BYTES';      name : 'Bytes'),
      (fieldType : ftLargeInt;    sqlName : 'LARGEINT';   name : 'Large Integer')

  if s = 'BOOLEAN' then s := 'LOGICAL';
  if (s = 'CHAR') or (s = 'VARCHAR') or (s = 'VARCHAR2') then s := 'STRING';
}
  Result:='unknown';
  case dt of
    ftAutoInc:      Result := 'AutoInc';
    ftInteger:      Result := 'Integer';
    ftSmallInt:     Result := 'SmallInt';
    ftWord:         Result := 'Word';
    ftLargeInt:     Result := 'LargeInt';
    ftFloat:        Result := 'Float';
    ftBoolean:      Result := 'Boolean';
    ftCurrency:     Result := 'Currency';
    ftDate:         Result := 'Date';
    ftTime:         Result := 'Time';
    ftDateTime:     Result := 'DateTime';
    ftString:       Result := 'String';
    ftWideString:   Result := 'WideString';
    ftBlob:         Result := 'BLOB';
    ftBytes:        Result := 'Bytes';
    ftMemo:         Result := 'Memo';
    ftFmtMemo:      Result := 'FmtMemo';
    ftGraphic:      Result := 'Graphic';
    ftBCD :         Result := 'BCD';
  else
    Result := 'UNKNOWN';
  end;
end;//GetDataTypeName

Function SQLDescribeCol  (
             Stmt:PStmt;
//             StatementHandle:HSTMT;
             ColumnNumber:SWORD;
             ColumnName:UCHAR;
		         BufferLength:SWORD;
        		 NameLength: {UNALIGNED} PSmallInt;// SWORD;
        		 DataType: {UNALIGNED}  PSmallInt;// SWORD;
             ColumnSize: {UNALIGNED} PInteger;//SQLUINTEGER; //UDWORD;
        		 DecimalDigits: {UNALIGNED} PSmallInt;// SWORD;
        		 Nullable: {UNALIGNED} PSmallInt//SWORD
                            ): RETCODE; stdcall;
var
		 LocalNameLength: Integer;
begin
WriteToLog('>>> SQLDescribeCol called');
  if ColumnNumber=0
    then
      begin
        if Integer(DataType)=SQL_NULL_HANDLE
          then
WriteToLog('    @DataType=0 - Skip DataType')
          else DataType^:=SQL_BINARY;
       	Result:=SQL_SUCCESS;
WriteToLog('### ColumnNumber=0');
        Exit;
      end;
  if ColumnNumber>Stmt.Result.FieldCount
    then
      begin
       	Result:=SQL_ERROR;
WriteToLog('### ColumnNumber=0');
        Exit;
      end;

// Get ColumnName
  if Integer(ColumnName)=SQL_NULL_HANDLE
    then
WriteToLog('    @ColumnName=0 - Skip ColumnName')
    else
      begin
WriteToLog('    Getting ColumnName...');
        LocalNameLength:=Length(Stmt.Result.Fields[ColumnNumber-1].FieldName);
        if LocalNameLength>=BufferLength then LocalNameLength:=BufferLength-1;
        StrCopy(ColumnName,PChar(Copy(Stmt.Result.Fields[ColumnNumber-1].FieldName,1,LocalNameLength)));
        if Integer(NameLength)=SQL_NULL_HANDLE
         then
WriteToLog('    @NameLength=0 - Skip')
         else NameLength^:=LocalNameLength;
WriteToLog('    Has got');
      end;

// Prepare to get other parameters
  if not Stmt.TypeInfo.Exists then InitTypeInfo(Stmt);
//  Stmt.TypeInfo.Active:=True;

WriteToLog('    Filtering TypeInfo...');
  Stmt.TypeInfo.FilterOptions := [foCaseInsensitive];
  Stmt.TypeInfo.Filter := 'TYPE_NAME="'+GetDataTypeName(Stmt.Result.FieldDefs[ColumnNumber-1].DataType)+'"';
  Stmt.TypeInfo.Filtered := True;
WriteToLog('    TypeInfo filtered');

if Stmt.TypeInfo.Exists and (Stmt.TypeInfo.Active=TRUE)
then
begin
  Stmt.TypeInfo.First;
WriteToLog('    TypeInfo.First');
end
else
WriteToLog('    TypeInfo is not active or does not exist');

// Get DataType
  if Integer(DataType)=SQL_NULL_HANDLE
    then
WriteToLog('    @DataType=0 - Skip DataType')
    else
      begin
        DataType^ := Stmt.TypeInfo.Fields[1].AsInteger;
WriteToLog('    DataType='+IntToStr(DataType^))
      end;

// Get ColumnSize
  if Integer(ColumnSize)=SQL_NULL_HANDLE
   then
WriteToLog('    @ColumnSize=0 - Skip')
   else
    if Stmt.TypeInfo.Fields[2].IsNull
     then ColumnSize^ := 0
     else
      begin
WriteToLog('    Getting ColumnSize');
        if (DataType^=SQL_CHAR) or (DataType^=SQL_WCHAR) or (DataType^=SQL_BINARY) or
            (DataType^=SQL_VARCHAR) or (DataType^=SQL_WVARCHAR) or (DataType^=SQL_VARBINARY)
          then ColumnSize^ := Stmt.Result.Fields[ColumnNumber-1].Size
          else ColumnSize^ := Stmt.TypeInfo.Fields[2].AsInteger;
WriteToLog('    ColumnSize='+IntToStr(ColumnSize^));
      end;
//WriteToLog('   :>'+IntToStr(DecimalDigits));

// Get DecimalDigits
WriteToLog('    DecimalDigits getting...');
  if Integer(DecimalDigits)=SQL_NULL_HANDLE
   then
WriteToLog('    @DecimalDigits=0 - Skip')
   else
begin
WriteToLog('    @DecimalDigits<>0');
WriteToLog('    precision in '+Stmt.TypeInfo.Fields[5].AsString);
if pos('precision',Stmt.TypeInfo.Fields[5].AsString)=0  then WriteToLog('    NO!!!') else WriteToLog('    YES!!!');
    if pos('precision',Stmt.TypeInfo.Fields[5].AsString)=0
     then DecimalDigits^ := 0
     else
      if Stmt.TypeInfo.Fields[2].IsNull
       then DecimalDigits^ := 0
       else DecimalDigits^ := Stmt.TypeInfo.Fields[2].AsInteger;
//DecimalDigits^ := 11;//Stmt.TypeInfo.Fields[2].AsInteger;
end;

// Get Nullable
WriteToLog('    Nullable getting...');
  if Integer(Nullable)=SQL_NULL_HANDLE
    then
WriteToLog('    @Nullable=0 - Skip')
    else Nullable^ := Stmt.TypeInfo.Fields[6].AsInteger;

WriteToLog('    Output parameters:');
WriteToLog('    ColumnNumber='+IntToStr(ColumnNumber)+';');
if Integer(ColumnName)<>SQL_NULL_HANDLE then WriteToLog('    ColumnName='+ColumnName+';');
if Integer(DataType)<>SQL_NULL_HANDLE then WriteToLog('    DataType='+IntToStr(DataType^)+';');
if Integer(ColumnSize)<>SQL_NULL_HANDLE then WriteToLog('    ColumnSize='+IntToStr(ColumnSize^)+';');
if Integer(DecimalDigits)<>SQL_NULL_HANDLE then WriteToLog('    DecimalDigits='+IntToStr(DecimalDigits^)+';');
if Integer(Nullable)<>SQL_NULL_HANDLE then WriteToLog('    Nullable='+IntToStr(Nullable^)+'.');
WriteToLog('### SQLDescribeCol finished');
	Result:=SQL_SUCCESS;
end;


///// SQLColAttribute /////

Function SQLColAttribute  (
               Stmt:PStmt;//HSTMT;
               ColumnNumber:SQLUSMALLINT;
               FieldIdentifier:SQLUSMALLINT;
               CharacterAttributePtr:SQLPOINTER;
               BufferLength:SQLSMALLINT;
               StringLengthPtr:pSmallInt;//{UNALIGNED} SQLSMALLINT;
               NumericAttributePtr:SQLPOINTER
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLColAttribute called');
	Result:=SQL_SUCCESS;
end;

///// SQLColAttributes /////

Function SQLColAttributes (
               Stmt:PStmt;//HSTMT;
               ColumnNumber:UWORD;
               FieldIdentifier:UWORD;
               CharacterAttributePtr:PTR;
               BufferLength:SWORD;
               StringLengthPtr:PInteger;// {UNALIGNED} SWORD;
               NumericAttributePtr:PInteger //{UNALIGNED} SDWORD
                            ): RETCODE; stdcall;

Function SetNumAttr(Value,Default:Integer):RETCODE;
  begin
    if Integer(NumericAttributePtr)=SQL_NULL_HANDLE
     then
      begin
WriteToLog('    Error: NumericAttributePtr=SQL_NULL_HANDLE');
       Result:=SQL_ERROR;
       exit;
      end;
    if ColumnNumber=0
      then
    NumericAttributePtr^ := Default
      else
    NumericAttributePtr^ := Value;
    Result:=SQL_SUCCESS;
WriteToLog('    NumericAttribute='+IntToStr(NumericAttributePtr^));
  end;

Function SetCharAttr(Value:pChar):RETCODE;
  begin
    Result:=SQL_SUCCESS;
    if Integer(CharacterAttributePtr)=SQL_NULL_HANDLE
     then
      begin
WriteToLog('    Error: CharacterAttributePtr=SQL_NULL_HANDLE');
       Result:=SQL_SUCCESS_WITH_INFO;
       exit;
      end;

    if ColumnNumber<>0
      then
       begin
WriteToLog('    Move...');
        if BufferLength=-3
          then
        StrCopy(CharacterAttributePtr,Value)
          else
        Move(Value^,CharacterAttributePtr^,BufferLength);
WriteToLog('    >'+IntToStr(StrLen(Value)));
WriteToLog('    Moved');
WriteToLog('    CharacterAttribute='+pChar(CharacterAttributePtr));
        if Integer(StringLengthPtr)=SQL_NULL_HANDLE
         then
          begin
WriteToLog('    Error: StringLengthPtr=SQL_NULL_HANDLE');
            Result:=SQL_INVALID_HANDLE;
            exit;
          end
         else
          begin
            StringLengthPtr^ := StrLen(Value);
WriteToLog('    StringLength='+IntToStr(StringLengthPtr^));
            if StringLengthPtr^>=BufferLength
            then
              begin
                Result:=SQL_SUCCESS_WITH_INFO;
WriteToLog('    Data truncated');
              end
            else
              begin
                Result:=SQL_SUCCESS;
WriteToLog('    Success');
              end;
          end;
       end;
  end;

var
  DataType,i:Integer;
begin
WriteToLog('>>> SQLColAttributes called');

if Stmt.Result.Active then
WriteToLog('    Result.RecordCount='+IntToStr(Stmt.Result.RecordCount))
else
WriteToLog('    Result.Active=False!!!');

WriteToLog('    ColumnNumber='+IntToStr(ColumnNumber));

  if ColumnNumber>Stmt.Result.FieldCount
   then
    begin
WriteToLog('    Error: ColumnNumber='+IntToStr(ColumnNumber)+' > Result.FieldCount');
      Result:=SQL_ERROR;
    end
   else
    begin
     // Prepare to get parameters
WriteToLog('    Prepare  to get parameters:');
     if not Stmt.TypeInfo.Exists then InitTypeInfo(Stmt);
WriteToLog('    Filtering TypeInfo...');
     Stmt.TypeInfo.FilterOptions := [foCaseInsensitive];

WriteToLog('    Specify TypeInfo.Filter');
          try
     Stmt.TypeInfo.Filter := 'TYPE_NAME="'+GetDataTypeName(Stmt.Result.FieldDefs[ColumnNumber-1].DataType)+'"';
WriteToLog('    TypeInfo.Filter='+Stmt.TypeInfo.Filter);
          except
           on e: Exception do
            begin
WriteToLog('TypeInfo.Filter - Error: ' + e.Message);
              Result:=SQL_ERROR;
              Exit;
            end;
          end; // try

WriteToLog('    Set TypeInfo.Filtered=True');
          try
     Stmt.TypeInfo.Filtered := True;
          except
           on e: Exception do
            begin
WriteToLog('TypeInfo.Filtered - Error: ' + e.Message);
              Result:=SQL_ERROR;
              Exit;
            end;
          end; // try
WriteToLog('    TypeInfo filtered');

     if Stmt.TypeInfo.Exists and (Stmt.TypeInfo.Active=TRUE)
       then
        begin
          try
           Stmt.TypeInfo.First;
          except
           on e: Exception do
            begin
WriteToLog('TypeInfo.First - Error: ' + e.Message);
              Result:=SQL_ERROR;
              Exit;
            end;
          end;
WriteToLog('    TypeInfo.First');
        end
       else
        begin
WriteToLog('    Error: TypeInfo is not active or does not exist');
          Result:=SQL_ERROR;
          exit;
        end;
     // Get DataType
     if ColumnNumber>0
     then DataType := Stmt.TypeInfo.Fields[1].AsInteger
     else DataType := SQL_UNKNOWN_TYPE;

     // Get attribute value
     case FieldIdentifier of
//      SQL_DESC_LENGTH,
      //(ODBC 3.0)	NumericAttributePtr
      SQL_COLUMN_LENGTH:
      //(ODBC 2)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_LENGTH');
        // Get ColumnSize
        if (DataType=SQL_CHAR) or (DataType=SQL_WCHAR) or (DataType=SQL_BINARY) or
          (DataType=SQL_VARCHAR) or (DataType=SQL_WVARCHAR) or (DataType=SQL_VARBINARY)
        then Result:=SetNumAttr(Stmt.Result.Fields[ColumnNumber-1].Size,0)
        else Result:=SetNumAttr(Stmt.TypeInfo.Fields[2].AsInteger,0);
       end;

//      SQL_DESC_PRECISION,
      //(ODBC 3.0)	NumericAttributePtr
      SQL_COLUMN_PRECISION:
      //(ODBC 2)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_PRECISION');
        if DataType=SQL_TIME
          then
        Result:=SetNumAttr(0,0) // No fractional seconds component
          else
        if DataType=SQL_TIMESTAMP
          then
        Result:=SetNumAttr(3,0) // Fractional seconds component
          else
        if (DataType=SQL_CHAR) or (DataType=SQL_WCHAR) or (DataType=SQL_BINARY) or
          (DataType=SQL_VARCHAR) or (DataType=SQL_WVARCHAR) or (DataType=SQL_VARBINARY)
          then
        Result:=SetNumAttr(Stmt.Result.Fields[ColumnNumber-1].Size,0)
          else
        Result:=SetNumAttr(Stmt.TypeInfo.Fields[2].AsInteger,0);
       end;

//      SQL_DESC_SCALE,
      //(ODBC 3.0)	NumericAttributePtr
      SQL_COLUMN_SCALE:
      //(ODBC 2)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_SCALE');
        if (DataType=SQL_CHAR) or (DataType=SQL_WCHAR) or (DataType=SQL_BINARY) or
          (DataType=SQL_VARCHAR) or (DataType=SQL_WVARCHAR) or (DataType=SQL_VARBINARY)
        then
          begin
            Result:=SetNumAttr(Stmt.Result.Fields[ColumnNumber-1].Size,0);
            if Result > 255 then Result:= 255; // No more space on screen
          end
        else Result:=SetNumAttr(Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger,0);
       end;

//      SQL_DESC_AUTO_UNIQUE_VALUE, //v.3
  		SQL_COLUMN_AUTO_INCREMENT:  //v.2
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_AUTO_INCREMENT');
        if Stmt.Result.FieldDefs[ColumnNumber-1].DataType=ftAutoInc
          then
        Result:=SetNumAttr(SQL_TRUE,0)
          else
        Result:=SetNumAttr(SQL_FALSE,0);
       end;

      SQL_COLUMN_CASE_SENSITIVE:
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_CASE_SENSITIVE');
        Result:=SetNumAttr(Stmt.Result.FieldByName('CASE_SENSITIVE').AsInteger,0);
       end;

//      SQL_DESC_CATALOG_NAME,       //v.3
			SQL_COLUMN_QUALIFIER_NAME:   //v.2
      //(ODBC 2.0)	CharacterAttributePtr
       begin
WriteToLog('    SQL_COLUMN_QUALIFIER_NAME');
        Result:=SetCharAttr(Stmt.Database);
        StringLengthPtr^ := 0;// catalog name blocked;
       end;

//      SQL_DESC_CONCISE_TYPE,      //v.3
      SQL_COLUMN_TYPE:            //v.2
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_TYPE');
        Result:=SetNumAttr(DataType,SQL_UNKNOWN_TYPE);
       end;

      SQL_COLUMN_COUNT:
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_COUNT');
        Result:=SetNumAttr(Stmt.Result.RecordCount,0);
       end;

      SQL_COLUMN_DISPLAY_SIZE:
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_DISPLAY_SIZE');
        case DataType of
          SQL_CHAR,
          SQL_WCHAR,
          SQL_BINARY,
          SQL_VARCHAR,
          SQL_WVARCHAR,
          SQL_VARBINARY:
            i := Stmt.Result.Fields[ColumnNumber-1].Size;
          SQL_DECIMAL,
          SQL_NUMERIC:
            i := Stmt.TypeInfo.Fields[2].AsInteger+2;
          SQL_BIT:
            i := 1;
          SQL_TINYINT:
            if Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger=SQL_TRUE
              then i:=3
              else i:=4;
          SQL_SMALLINT:
            if Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger=SQL_TRUE
              then i:=5
              else i:=6;
          SQL_INTEGER:
            if Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger=SQL_TRUE
              then i:=10
              else i:=11;
          SQL_BIGINT:
            i := 20;
          SQL_REAL:
            i := 14;
          SQL_FLOAT,
          SQL_DOUBLE:
            i := 24;
          SQL_DATE:
            i := 10;
          SQL_TIME:
            i := 8;
          SQL_TIMESTAMP:
            i := 20+3;// 3 - fractional seconds precision
        else
            i := 0;
        end;
        Result:=SetNumAttr(i,0)
       end;

//      SQL_DESC_FIXED_PREC_SCALE,  //v.3
      SQL_COLUMN_MONEY:           //v.2
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_MONEY');
        Result:=SetNumAttr(Stmt.TypeInfo.Fields[10].AsInteger,0);
       end;

      SQL_COLUMN_LABEL:
      //(ODBC 2.0)	CharacterAttributePtr
       begin
WriteToLog('    SQL_COLUMN_LABEL');
        Result:=SetCharAttr(''); // does not supported
        // pChar(Stmt.Result.Fields[ColumnNumber-1].FieldName) - shows Query name like Expr2869
       end;

//      SQL_DESC_SCHEMA_NAME,
      SQL_COLUMN_OWNER_NAME:
      //(ODBC 2.0)	CharacterAttributePtr
       begin
WriteToLog('    SQL_COLUMN_OWNER_NAME (schema)');
        Result:=SetCharAttr(pChar('')); // do not support shemas
       end;

      SQL_COLUMN_SEARCHABLE:
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_SEARCHABLE');
        Result:=SetNumAttr(Stmt.TypeInfo.Fields[8].AsInteger,0);
       end;

      SQL_COLUMN_TYPE_NAME:
      //(ODBC 1.0)	CharacterAttributePtr
       begin
WriteToLog('    SQL_COLUMN_TYPE_NAME');
        Result:=SetCharAttr(pChar(Stmt.TypeInfo.Fields[0].AsString));
       end;

      SQL_COLUMN_UNSIGNED:
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_UNSIGNED');
        Result:=SetNumAttr(Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger,0);
       end;

      SQL_COLUMN_UPDATABLE:
      //(ODBC 1.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_UPDATABLE');
        if Stmt.Result.ReadOnly
          then
        Result:=SetNumAttr(SQL_ATTR_READONLY,SQL_ATTR_READWRITE_UNKNOWN)
          else
        Result:=SetNumAttr(SQL_ATTR_WRITE,SQL_ATTR_READWRITE_UNKNOWN);
       end;

      SQL_COLUMN_TABLE_NAME:
      //(ODBC 2.0)	CharacterAttributePtr
       begin
WriteToLog('    SQL_COLUMN_TYPE_NAME');
        Result:=SetCharAttr(''); // Does not supported
       end;

      SQL_DESC_NULLABLE:
      //(ODBC 3.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_CASE_SENSITIVE');
        Result:=SetNumAttr(Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger,0);
                          //Stmt.TypeInfo.Fields[6].AsInteger;
       end;

      SQL_DESC_NUM_PREC_RADIX:
      //(ODBC 3.0)	NumericAttributePtr
       begin
WriteToLog('    SQL_COLUMN_CASE_SENSITIVE');
        Result:=SetNumAttr(Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger,0);
       end;

{
      SQL_DESC_BASE_COLUMN_NAME:
      //(ODBC 3.0)	CharacterAttributePtr
        ;
      SQL_DESC_BASE_TABLE_NAME:
      //(ODBC 3.0)	CharacterAttributePtr
        ;
      SQL_DESC_LITERAL_PREFIX:
      //(ODBC 3.0)	CharacterAttributePtr
        ;
      SQL_DESC_LITERAL_SUFFIX:
      //(ODBC 3.0)	CharacterAttributePtr
        ;
      SQL_DESC_LOCAL_TYPE_NAME:
      //(ODBC 3.0)	CharacterAttributePtr
        ;
      SQL_DESC_NAME:
      //(ODBC 3.0)	CharacterAttributePtr
        ;
      SQL_DESC_OCTET_LENGTH:
      //(ODBC 3.0)	NumericAttributePtr //ColumnNumber may be 0
        ;
      SQL_DESC_TYPE:
      //(ODBC 3.0)	NumericAttributePtr //ColumnNumber may be 0
        ;
      SQL_DESC_UNNAMED:
      //(ODBC 3.0)	NumericAttributePtr
        ;
}
     else
WriteToLog('    Error: FieldIdentifier='+IntToStr(FieldIdentifier));
      Result:=SQL_ERROR;
     end; // case
    end; // if

	WriteToLog('### SQLColAttributes');
end;

///// SQLBindCol /////

Function SQLBindCol  (
              Stmt:PStmt;
              ColumnNumber:UWORD;
              TargetType:SWORD;
              Buffer:PTR;
              BufferLength:SDWORD;
              StrLen_or_Ind:PInteger//{UNALIGNED} SDWORD
                        ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLBindCol called:');
WriteToLog('    Stmt='+IntToHex(Integer(Stmt),8));
  // Unbind fetched columns -- Fix for MS Query due it doesnot call SQLFreeStmt with SQL_UNBIND -- see SQLFetch
  if Stmt.Fetched then
   begin
    SQLFreeStmt(Stmt,SQL_UNBIND);
    Stmt.Fetched := False;
   end;

 	Result:=SQL_ERROR;
      try
    Stmt.Bind.Active:=True;
      except
       on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
          Exit;
        end;
      end;
    Stmt.Bind.Insert;
    Stmt.Bind.FieldByName('ColumnNumber').AsInteger := ColumnNumber;
    Stmt.Bind.FieldByName('TargetType').AsInteger := TargetType;
    Stmt.Bind.FieldByName('Buffer').AsInteger := Integer(Buffer);
    Stmt.Bind.FieldByName('BufferLength').AsInteger := BufferLength;

    Stmt.Bind.FieldByName('StrLen_or_Ind').AsInteger := Integer(StrLen_or_Ind);
    Stmt.Bind.Post;

WriteToLog('    ColumnNumber='+IntToStr(ColumnNumber)+';');
WriteToLog('    TargetType='+IntToStr(TargetType)+';');
WriteToLog('    BufferPtr='+IntToHex(Integer(Buffer),8)+';');
WriteToLog('    BufferLength='+IntToStr(BufferLength)+';');
WriteToLog('    StrLen_or_IndPtr='+IntToHex(Integer(StrLen_or_Ind),8)+'.');
WriteToLog('### SQLBindCol');

{ OLD CODE:
  if Integer(Integer(Buffer))=SQL_NULL_HANDLE
    then
     begin
WriteToLog('    @Buffer=0 - SKIP!');
     end
    else
  begin
WriteToLog('    @Buffer='+IntToHex(Integer(Buffer),8));
    Stmt.Bind.Active:=True;
WriteToLog('    .Insert:');
    Stmt.Bind.Insert;
WriteToLog('    ColumnNumber:');
    Stmt.Bind.FieldByName('ColumnNumber').AsInteger := ColumnNumber;
WriteToLog('    TargetType:');
    Stmt.Bind.FieldByName('TargetType').AsInteger := TargetType;
WriteToLog('    Buffer:');
    Stmt.Bind.FieldByName('Buffer').AsInteger := Integer(Buffer);
WriteToLog('    BufferLength:');
    Stmt.Bind.FieldByName('BufferLength').AsInteger := BufferLength;
WriteToLog('    StrLen_or_Ind:');
    if Integer(StrLen_or_Ind)<>SQL_NULL_HANDLE
      then
       begin
WriteToLog('    StrLen_or_IndPtr='+IntToHex(Integer(StrLen_or_Ind),8)+'.');
    Stmt.Bind.FieldByName('StrLen_or_Ind').AsInteger := Integer(StrLen_or_Ind);
       end
      else WriteToLog('    @StrLen_or_IndPtr=0.');
WriteToLog('    Post:');
    Stmt.Bind.Post;

WriteToLog('    ColumnNumber='+IntToStr(ColumnNumber)+';');
WriteToLog('    TargetType='+IntToStr(TargetType)+';');
WriteToLog('    BufferPtr='+IntToHex(Integer(Buffer),8)+';');
WriteToLog('    BufferLength='+IntToStr(BufferLength)+';');
WriteToLog('    StrLen_or_IndPtr='+IntToHex(Integer(StrLen_or_Ind),8)+'.');
WriteToLog('### SQLBindCol');
  end;
}
 	Result:=SQL_SUCCESS;
end;

///// SQLCancel /////

Function SQLCancel  (arg0:HSTMT): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLCancel called');
	Result:=SQL_SUCCESS;
end;

///// SQLConnect /////

Function SQLConnect  (
           Connection:pConnection;//HDBC;
      		 ServerName:UCHAR;
      		 ServerNameLength:SWORD;
      		 UserName:UCHAR;
      		 UserNameLength:SWORD;
		       Authentication:UCHAR;
      		 AuthLength:SWORD
                      ): RETCODE; stdcall;
var
  FileName:PChar;
  Path, Default : String;
begin
WriteToLog('>>> SQLConnect called with parameters:');
  FileName:=AllocMem(_MAX_PATH+1);
  StrCopy(FileName,'ODBC.INI');
  Path := 'Path';
  Default :='?';
  if (Connection=Nil) or (Integer(Connection)=SQL_NULL_HDBC)
    then
      begin
WriteToLog('    Connection=Nil - > Exit!');
      	Result:=SQL_INVALID_HANDLE;
      end
    else
      begin
WriteToLog('    Connection='+IntToHex(Integer(Connection),8)+';');
        if Integer(ServerName)=SQL_NULL_HANDLE
          then
            begin
WriteToLog('    Server=Nil - > Exit!');
            	Result:=SQL_ERROR;
            end
          else
            begin
WriteToLog('    Server='+ServerName+';');
WriteToLog('    ServerNameLength='+IntToStr(ServerNameLength));
              if ServerNameLength = SQL_NTS then
                StrCopy(Connection.DSN,ServerName)
              else
               begin
                Move(ServerName^,Connection.DSN,ServerNameLength);
                //Connection.DSN := Connection.DSN + #0;
               end;
WriteToLog('    Connection.DSN='+Connection.DSN+';');
              // copy Path from ODBC.INI to Connection.Database
              //SQLGetPrivateProfileString(ServerName,pChar(Path),pChar(Default),Connection.Database,_MAX_PATH,FileName);
              SQLGetPrivateProfileString(Connection.DSN,pChar(Path),pChar(Default),Connection.Database,_MAX_PATH,FileName);
WriteToLog('    DatabasePath="'+Connection.Database+'"');
              if Connection.Database=Default
                then
                  Result:=SQL_ERROR
                else
                	Result:=SQL_SUCCESS;
            end;
      end;
    FreeMem(FileName);
if UserName=Nil then WriteToLog('    User=Nil;') else WriteToLog('    User='+UserName+';');
if Authentication=Nil then WriteToLog('    Authentication=Nil.') else WriteToLog('    Authentication'+Authentication+'.');

WriteToLog('### SQLConnect');
end;

///// SQLDisconnect /////

Function SQLDisconnect  (arg0: HDBC): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLDisconnect called');
	Result:=SQL_SUCCESS;
end;

///// SQLError /////

Function SQLError  (
             Env:PEnv; //HENV;
        		 Connection:PConnection;// HDBC;
        		 Stmt:PStmt; // HSTMT;
        		 var Sqlstate:Char;//UCHAR;
        		 var NativeError: {UNALIGNED} SDWORD;
        		 var MessageText:Char;//UCHAR;
        		 BufferLength: SWORD;
        		 var TextLength: {UNALIGNED} SWORD
                      ): RETCODE; stdcall;
{
RETCODE SQL_API SQLError  (
     HENV arg0,
		 HDBC arg1,
		 HSTMT arg2,
		 UCHAR * arg3,
		 UNALIGNED SDWORD * arg4,
		 UCHAR * arg5,
		 SWORD arg6,
		 UNALIGNED SWORD * arg7)
}
// SQLError(henv, hdbc, hstmt, szSqlState, pfNativeError, szErrorMsg, cbErrorMsgMax, pcbErrorMsg)
begin
	WriteToLog('>>> SQLError called');
  Sqlstate:=#0; //  HYC00 (Optional feature not implemented)
  NativeError:=0;
  MessageText:=#0;
  TextLength:=0;
  Result:=SQL_NO_DATA; //	= SQL_NO_DATA_FOUND
end;

///// SQLExecDirect /////

Function SQLExecDirect (
               Stmt:PStmt;//HSTMT;
          		 StatementText: UCHAR;
          		 TextLength: SDWORD): RETCODE; stdcall;
var
  str:string;
  i:Integer;
  DateTime: PSQL_TIMESTAMP_STRUCT;
  Date:     PSQL_DATE_STRUCT;
  Time:     PSQL_TIME_STRUCT;
begin
WriteToLog('>>> SQLExecDirect called');
WriteToLog('    Stmt='+IntToHex(Integer(Stmt),8));
  if Integer(StatementText)=SQL_NULL_HANDLE then
    begin
WriteToLog('### SQLExecDirect Error: StatementTextPtr=SQL_NULL_HANDLE!');
    	Result:=SQL_ERROR;
      Exit;
    end;
  // Prepare for new result
  Stmt.Result.DatabaseFileName:=Stmt.Database;
WriteToLog('    DatabaseFileName='+Stmt.Result.DatabaseFileName);
  Stmt.Result.Active:=False;
  Stmt.Result.InMemory:=False;
WriteToLog('    Old data erased');
WriteToLog('    StatementText='+StatementText);
WriteToLog('    TextLength='+IntToStr(TextLength));
  if TextLength=SQL_NTS
    then
  Stmt.Result.SQL.Text:=StatementText
    else
      begin
  Stmt.Result.SQL.Text:=Copy(StatementText,1,TextLength);
WriteToLog('    copied');
      end;
WriteToLog('    Statement='+Stmt.Result.SQL.Text);

  // set parameters
  i:=0;
  Move(i,Pointer(Integer(Stmt.Result.SQL.Text)+TextLength)^,1);// Null-terminated char
  while pos('?',Stmt.Result.SQL.Text)>0 do
    begin
WriteToLog('    Parameter #'+IntToStr(i+1));
      case Stmt.BindParam[i].ParameterType of
        SQL_C_CHAR:
          begin
WriteToLog('    BufferLength'+IntToStr(Stmt.BindParam[i].BufferLength));
WriteToLog('    Buffer'+PChar(Stmt.BindParam[i].ParameterValuePtr));
//            StrLCopy(PChar(str),PChar(Stmt.BindParam[i].ParameterValuePtr),Stmt.BindParam[i].BufferLength);
//            str := Copy(str,1,pos('=',str))
//                    +'"'+Copy(str,pos('=',str)+1,Length(str))+'"';
            str := PChar(Stmt.BindParam[i].ParameterValuePtr);
            str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
          end;
        SQL_TIMESTAMP:
          begin
WriteToLog('    SQL_TIMESTAMP');
            if Stmt.BindParam[i].ValueType=SQL_CHAR
              then
                begin
                  StrCopy(PChar(str),Stmt.BindParam[i].ParameterValuePtr);
                  str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
                end
              else
                begin
                  DateTime := Stmt.BindParam[i].ParameterValuePtr;
                  str := IntToStr(DateTime.Month)+'/'+
                         IntToStr(DateTime.Day)+'/'+
                         IntToStr(DateTime.Year)+' '+
                         IntToStr(DateTime.Hour)+':'+
                         IntToStr(DateTime.Minute)+':'+
                         IntToStr(DateTime.Second)+','+
                         IntToStr(DateTime.Fraction);
                  str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
                  str := 'TODATE('+str+','+CONSTANT_QUOTE+'m/d/year h24:n:s'+CONSTANT_QUOTE+')';
                end;
WriteToLog('    DateTime='+str);
          end;
        SQL_DATE:
          begin
            if Stmt.BindParam[i].ValueType=SQL_CHAR
              then
                begin
                  StrCopy(PChar(str),Stmt.BindParam[i].ParameterValuePtr);
                  str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
                end
              else
                begin
                  Date := Stmt.BindParam[i].ParameterValuePtr;
                  str := IntToStr(Date.Month)+'/'+
                         IntToStr(Date.Day)+'/'+
                         IntToStr(Date.Year);
                  str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
                  str := 'TODATE('+str+','+CONSTANT_QUOTE+'m/d/year'+CONSTANT_QUOTE+')';
                end;
WriteToLog('    Date='+str);
          end;
        SQL_TIME:
          begin
WriteToLog('    SQL_TIME');
            if Stmt.BindParam[i].ValueType=SQL_CHAR
              then
                begin
                  StrCopy(PChar(str),Stmt.BindParam[i].ParameterValuePtr);
                  str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
                end
              else
                begin
                  Time := Stmt.BindParam[i].ParameterValuePtr;
                  str := IntToStr(Time.Hour)+':'+
                         IntToStr(Time.Minute)+':'+
                         IntToStr(Time.Second);
                  str := CONSTANT_QUOTE+str+CONSTANT_QUOTE;
                  str := 'TODATE('+str+','+CONSTANT_QUOTE+'h24:n:s'+CONSTANT_QUOTE+')';
                end;
WriteToLog('    Time='+str);
          end;
        SQL_INTEGER:
          begin
WriteToLog('    Integer');
          if Stmt.BindParam[i].ValueType=SQL_CHAR
            then
              StrCopy(PChar(str),Stmt.BindParam[i].ParameterValuePtr)
            else
              str := IntToStr(PInteger(Stmt.BindParam[i].ParameterValuePtr)^);
WriteToLog('    Integer='+str);
          end;
        SQL_SMALLINT:
          begin
WriteToLog('    SmallInt');
          if Stmt.BindParam[i].ValueType=SQL_CHAR
            then
              StrCopy(PChar(str),Stmt.BindParam[i].ParameterValuePtr)
            else
              str := IntToStr(PSmallInt(Stmt.BindParam[i].ParameterValuePtr)^);
WriteToLog('    SmallInt='+str);
          end;
        SQL_BIT:
          begin
WriteToLog('    Boolean');
            if pSmallInt(Stmt.BindParam[i].ParameterValuePtr)^=0
              then str:='FALSE'
              else str:='TRUE';
WriteToLog('    Boolean='+str);
          end;
        SQL_NUMERIC,
        SQL_DECIMAL,
        SQL_FLOAT,
        SQL_REAL,
        SQL_DOUBLE:
          begin
WriteToLog('    Float');
          if Stmt.BindParam[i].ValueType=SQL_CHAR
            then
              str:=pChar(Stmt.BindParam[i].ParameterValuePtr)
//              StrCopy(PChar(str),Stmt.BindParam[i].ParameterValuePtr)
            else
              str := FloatToStr(PDouble(Stmt.BindParam[i].ParameterValuePtr)^);
WriteToLog('    Float='+str);
          end;
      else
WriteToLog('    Unknown type, '+IntToStr(Stmt.BindParam[i].ParameterType));
        str := '#####';
      end; // case
      Stmt.Result.SQL.Text:=Copy(Stmt.Result.SQL.Text,1,pos('?',Stmt.Result.SQL.Text)-1)
                            + str
                            + Copy(Stmt.Result.SQL.Text,pos('?',Stmt.Result.SQL.Text)+1,Length(Stmt.Result.SQL.Text));
      inc(i);
      if i>Length(Stmt.BindParam)
        then
          begin
WriteToLog('    Too many parameters, '+IntToStr(i));
            Break;
          end; // if
    end;// while

WriteToLog('    Statement='+Stmt.Result.SQL.Text);
// for whom does not support core level and use multipart names, f.e. Excel XP
  Stmt.Result.SQL.Text:=StringReplace(Stmt.Result.SQL.Text,'_edb','.edb',[rfReplaceAll]);
  Stmt.Result.SQL.Text:=StringReplace(Stmt.Result.SQL.Text,'"."','.',[rfReplaceAll]);            // multipart names does not supported:
// for MSQuery
  Stmt.Result.SQL.Text:=StringReplace(Stmt.Result.SQL.Text,'ALL_DEFAULT.','',[rfReplaceAll]);            // schema name should absent but used ny MS Query
  Stmt.Result.SQL.Text:=StringReplace(Stmt.Result.SQL.Text,'ALL_DEFAULT .','',[rfReplaceAll]);            // schema name should absent but used ny MFC DBFetch demo
{ //Accuracer
  if Stmt.DB.LocalDatabase=True then
    Stmt.Result.SQL.Text:=StringReplace(Stmt.Result.SQL.Text,Stmt.DB.DatabaseFileName+' ','',[rfReplaceAll]); // remove database name (= database file path)
}
  Stmt.Result.SQL.Text:=StringReplace(Stmt.Result.SQL.Text,Stmt.Database+' ','',[rfReplaceAll]); // remove database name (= database file path)
WriteToLog('    Statement='+Stmt.Result.SQL.Text);
if Stmt.Result.InMemory
then WriteToLog('    InMemory=True')
else WriteToLog('    InMemory=False');

  if Pos('select',LowerCase(Stmt.Result.SQL.Text))=0
    then  // Not Select
      begin
WriteToLog('    Try to run ExecSQL...');
        try
          Stmt.Result.ExecSQL;
        except
         on e: Exception do
          begin
WriteToLog('Error: ' + e.Message);
           	Result:=SQL_ERROR;
            Exit;
          end;
        end;
      end
    else // Select
      begin
WriteToLog('    Try to set Active in True...');
        try
          Stmt.Result.Active:=True;
        except
         on e: Exception do
          begin
WriteToLog('Error: ' + e.Message);
          	Result:=SQL_ERROR;
            Exit;
          end;
        end;
       Stmt.Result.FindFirst; // Select the first record - it is not necessary because TEasyQuery set to first auto
       Stmt.FreshResult:=True; // Set Flag - new result
WriteToLog('    Result.RecordCount='+IntToStr(Stmt.Result.RecordCount));
WriteToLog('    Result.FieldCount='+IntToStr(Stmt.Result.FieldCount));
      end; // if
WriteToLog('    ... End of execution');
	Result:=SQL_SUCCESS;
WriteToLog('### SQLExecDirect finished');
end;

///// SQLPrepare /////

Function SQLPrepare  (
               Stmt:PStmt;//HSTMT;
          		 StatementText: UCHAR;
          		 TextLength: SDWORD): RETCODE; stdcall;
var
  i:byte;
begin
WriteToLog('>>> SQLPrepare called');
  i:=0;
WriteToLog('    TextLength='+IntToStr(TextLength));
      try
  FreeMem(Stmt.SQLtext);
  if TextLength>0
    then Stmt.SQLtext:=AllocMem(TextLength+1)
    else Stmt.SQLtext:=AllocMem(MAX_SQL_TEXT_LENGTH);
      except
       on e: Exception do
        begin
WriteToLog('Error AllocMem for SQLtext: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end;
  if Integer(StatementText)=SQL_NULL_HANDLE
    then
      begin
WriteToLog('    StatementTextPtr=0!');
        Move(i,Stmt.SQLtext^,1);
      	Result:=SQL_ERROR;
      end
    else
      begin
WriteToLog('    StatementTextPtr<>0');
WriteToLog('    StatementText='+StatementText);
        if TextLength=SQL_NTS
        then
            StrCopy(Stmt.SQLtext,StatementText)
        else
          begin
            Move(StatementText^,Stmt.SQLtext^,TextLength+1);
            Move(i,Pointer(Integer(Stmt.SQLtext)+TextLength)^,1);
          end;
WriteToLog('    SQLtext:"'+Stmt.SQLtext+'"');
WriteToLog('    Call SQLExecDirect with Statemnet="'+StatementText+'"');
      	Result:=SQLExecDirect(Stmt,StatementText,TextLength);
Result:=0;
      end;
WriteToLog('    SQLtext:"'+Stmt.SQLtext+'"');
WriteToLog('### SQLPrepare:Result='+IntToStr(Result));
end;

///// SQLExecute /////

Function SQLExecute (Stmt:PStmt): RETCODE; stdcall;
begin
WriteToLog('>>> SQLExecute called');
 	Result:=SQLExecDirect(Stmt,Stmt.SQLtext,StrLen(Stmt.SQLtext));
WriteToLog('### SQLExecute');
end;

/////////////////////////////////////////////////////////////////////////////
//                          Fetching data                                  //
/////////////////////////////////////////////////////////////////////////////

// FetchData //
Function FetchData (
             Stmt:pStmt;
             FetchOrientation:UWORD;
             FetchOffset:SDWORD;
             RowCountPtr: PInteger;
             RowStatusArray: PSmallInt;
             Count: Integer
                    ): RETCODE; stdcall;
var
  i,row,Buf,IndBuf,StrLen_or_Ind,Columns,Offset:Integer;
  AllColumnsLength:Integer;
  pBuf,pIndBuf:Pointer;
  str:String;
  int16:SmallInt;
  int32:Integer;
  double8:Double;
  DateTime:SQL_TIMESTAMP_STRUCT;
  Date:SQL_DATE_STRUCT;
  Time:SQL_TIME_STRUCT;
  BS:TStream;
label
  Type_Char,
  Type_Integer,
  Type_SmallInt,
  Type_BLOB,
  Type_Unknown;
begin
WriteToLog(' >> FetchData');
  Result:=SQL_SUCCESS;
//  Result:=SQL_ERROR;
WriteToLog('    Stmt='+IntToHex(Integer(Stmt),8));

  // prepere to copy data to bound columns
//WriteToLog('    Bind.RecordCount='+IntToStr(Stmt.Bind.RecordCount));
//WriteToLog('    Result.FieldCount='+IntToStr(Stmt.Result.FieldCount));
  if Stmt.BindingOffset = SQL_NULL_HANDLE
    then Offset := 0
    else Offset := Stmt.BindingOffset;
//WriteToLog('    Offset='+IntToStr(Offset));
  Columns:=Stmt.Bind.RecordCount;
WriteToLog('    Columns Bound = '+IntToStr(Columns));
  if Stmt.Result.FieldCount<Columns
    then Columns:=Stmt.Result.FieldCount; // There are more bound columns than they are in result set
WriteToLog('    Columns To Fetch ='+IntToStr(Columns));

  AllColumnsLength:=0;
  for i:=1 to Columns do
    AllColumnsLength := AllColumnsLength
                        + Stmt.Bind.FieldByName('BufferLength').AsInteger;
WriteToLog('    AllColumnsLength='+IntToStr(AllColumnsLength));

  for row:=1 to Count do
 begin

WriteToLog('    Iteration # '+IntToStr(row));
if Stmt.Result.Active=True then WriteToLog('    Get row # '+IntToStr(Stmt.Result.RecNo));

  // set bind position
WriteToLog('    Bind.FindFirst');
  Stmt.Bind.FindFirst;

  if Stmt.Bind.FieldByName('StrLen_or_Ind').IsNull
  or Stmt.Bind.FieldByName('Buffer').IsNull
  or (Stmt.Bind.FieldByName('StrLen_or_Ind').AsInteger = SQL_NULL_HANDLE)
  or (Stmt.Bind.FieldByName('Buffer').AsInteger = SQL_NULL_HANDLE)
    then  // Error fetching data - see SQLBindCol specification
      begin
        Result:=SQL_SUCCESS_WITH_INFO;
WriteToLog('#### No bound columns - Error fetching data, scrolling only.');
        exit;
      end;

  // copy data to bound columns
  for i:=0 to Columns-1 do
    begin
WriteToLog('    i='+IntToStr(i));
WriteToLog('    ColumnNumber='+IntToStr(Stmt.Bind.FieldByName('ColumnNumber').AsInteger));
if Stmt.Result.Active=True then WriteToLog('    Result.RecNo='+IntToStr(Stmt.Result.RecNo));

WriteToLog('    Stmt.Bind.Buffer='+IntToHex(Stmt.Bind.FieldByName('Buffer').AsInteger,8));
WriteToLog('    Stmt.Bind.Buffer='+IntToStr(Stmt.Bind.FieldByName('Buffer').AsInteger));
WriteToLog('    Offset='+IntToStr(Offset));
WriteToLog('    *='+IntToStr((row-1) * AllColumnsLength));
//if Stmt.Result.Active=True then WriteToLog('    *='+IntToStr((Stmt.Result.RecNo-1) * AllColumnsLength));
      Buf := Stmt.Bind.FieldByName('Buffer').AsInteger
             + Offset;
      if Stmt.Options[SQL_BIND_TYPE]=SQL_BIND_BY_COLUMN
      then
      // Column-Wise Binding
      Buf := Buf + (row-1) * Stmt.Bind.FieldByName('BufferLength').AsInteger
      else
      // Row-Wise Binding
      Buf := Buf + (row-1) * AllColumnsLength;
{
      Buf := Stmt.Bind.FieldByName('Buffer').AsInteger
             + Offset//
if Stmt.Result.Active=True then
      Buf := Buf
             + ((Stmt.Result.RecNo-1) * AllColumnsLength);
}
WriteToLog('    Buf='+IntToStr(Buf));
WriteToLog('    Buf='+IntToHex(Buf,8));
     IndBuf := Stmt.Bind.FieldByName('StrLen_or_Ind').AsInteger
               + Offset
               + (row-1) * 4;
{
      // Withou multiple rows - CODE WORKS!!!
      Buf := Stmt.Bind.FieldByName('Buffer').AsInteger
             + Offset;
}
WriteToLog('    Buf='+IntToHex(Buf,8));
     pBuf := Pointer(Buf);
//WriteToLog('    pBuf='+IntToHex(Integer(pBuf),8));
{
      // Withou multiple rows - CODE WORKS!!!
     IndBuf := Stmt.Bind.FieldByName('StrLen_or_Ind').AsInteger
               + Offset;
}
WriteToLog('    StrLen_or_Ind='+IntToHex(IndBuf,8));
     pIndBuf := Pointer(IndBuf);

  // Set a row attribute in Row Status Array
  if Integer(RowStatusArray)<>SQL_NULL_HANDLE then
    begin
WriteToLog('    RowStatusArray['+IntToStr(row)+']='+IntToStr(pSmallInt(Integer(RowStatusArray)+(row-1)*2)^)+', @='+IntToHex((Integer(RowStatusArray)+(row-1)*2),8));
      if Stmt.Result.EOF
        then pWord(Integer(RowStatusArray)+(row-1)*2)^ := SQL_ROW_NOROW
        else pWord(Integer(RowStatusArray)+(row-1)*2)^ := SQL_ROW_SUCCESS;
WriteToLog('    RowStatusArray['+IntToStr(row)+']='+IntToStr(pSmallInt(Integer(RowStatusArray)+(row-1)*2)^)+', @='+IntToHex((Integer(RowStatusArray)+(row-1)*2),8));
    end
else WriteToLog('    @RowStatusArray=0')
;

  // check Null
  if Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].IsNull
  or Stmt.Result.EOF // Row Status Array might be unavailable - send NULL data
    then
      begin
WriteToLog('    >NULL: ColumnNumber='+IntToStr(Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1)+'; FieldCount='+IntToStr(Stmt.Result.FieldCount));
        StrLen_or_Ind := SQL_NULL_DATA;
        if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
      end
    else
      case Stmt.Bind.FieldByName('TargetType').AsInteger of
        SQL_C_DEFAULT:
          begin
WriteToLog('    SQL_C_DEFAULT');
           if (Stmt.Bind.FieldByName('BufferLength').AsInteger=2) then
             goto Type_SmallInt;
           if (Stmt.Bind.FieldByName('BufferLength').AsInteger=4) then
             goto Type_Integer;
           if (Stmt.Bind.FieldByName('BufferLength').AsInteger>=1)
           or (Stmt.Bind.FieldByName('BufferLength').AsInteger=SQL_NTS) then
             goto Type_Char;
           goto Type_Unknown;
          end;
        SQL_WCHAR,
        SQL_CHAR:
          begin
  Type_Char:
WriteToLog('    SQL_CHAR');
{// doesnot work with BDE!!!
            if (Stmt.Result.FieldDefs[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].DataType=ftMemo)
            or (Stmt.Result.FieldDefs[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].DataType=ftFmtMemo)
              then goto type_BLOB;
// doesnot work with BDE!!!}
//            str:=Stmt.Result.FieldByName(Stmt.Result.Fields.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].FieldName).AsString;
            str:=Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsString;
WriteToLog('    str='''+str+'''');
//WriteToLog('    Offset='+IntToStr(Offset));
if (Stmt.Bind.FieldByName('BufferLength').AsInteger>0) then WriteToLog('    buffer='+pChar(Buf));
            int32:=Length(str);
            inc(int32);
WriteToLog('    length='+IntToStr(int32));
WriteToLog('    buffer_length='+IntToStr(Stmt.Bind.FieldByName('BufferLength').AsInteger));
            if  (Stmt.Bind.FieldByName('BufferLength').AsInteger<>SQL_NTS)
            and (int32>Stmt.Bind.FieldByName('BufferLength').AsInteger) then
              begin
                int32:=Stmt.Bind.FieldByName('BufferLength').AsInteger;
                Result:=SQL_SUCCESS_WITH_INFO;
WriteToLog('    Data truncated!');
              end;
{
if  Stmt.Bind.FieldByName('BufferLength').AsInteger=32771 then
begin
Result:=SQL_SUCCESS;
exit;
end;
if  Stmt.Bind.FieldByName('BufferLength').AsInteger=32771 then
begin
str:='';
WriteToLog('int=32771');
exit;
end;
if  IntToStr(Stmt.Bind.FieldByName('BufferLength').AsInteger)='32771' then
begin
str:='';
WriteToLog('str=32771');
end;
}
WriteToLog('AsInteger='+IntToStr(Stmt.Bind.FieldByName('BufferLength').AsInteger));
WriteToLog('AsString ='+Stmt.Bind.FieldByName('BufferLength').AsString);

WriteToLog('    Compare...');
// (Stmt.Bind.FieldByName('BufferLength').AsInteger<>'32771') then
begin
WriteToLog('    No!');
if (Stmt.Bind.FieldByName('BufferLength').AsInteger=-3) then
WriteToLog('    -3-!!!!!!!!!!!!!!!!!!!!!!');
WriteToLog('    Prepare to Copy...');
WriteToLog('    Coping '+IntToStr(int32)+' Characters...');
            if  (Stmt.Bind.FieldByName('BufferLength').AsInteger>0)
              then Move(pchar(str)^,pBuf^,int32);
WriteToLog('    Copied:');
if (Stmt.Bind.FieldByName('BufferLength').AsInteger>0) then WriteToLog('    buffer='+pChar(Buf));
            StrLen_or_Ind := Length(str);
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4)
//;
else
WriteToLog('    -32771-!!!!!!!!!!!!!!!!!!!!!!');
end;
          end;
        -18,  // MS VS 2003
        SQL_INTEGER:
          begin
  Type_Integer:
WriteToLog('    SQL_INTEGER');
            int32:=Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsInteger;
{
//if pos('COUNT(*)',Stmt.Result.SQL.Text)>0 then
inc(int32); // BDE multi-user access checking blocked
}
            Move(int32,pBuf^,4);
WriteToLog('    :'+IntToStr(int32));
            StrLen_or_Ind:=4;
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
          end;
        -15, -17,  // MS VS 2003
        SQL_SMALLINT:
          begin
  Type_SmallInt:
WriteToLog('    SQL_SMALLINT');
            if Stmt.Result.FieldDefs[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].DataType = ftBoolean
              then  // Boolean for BDE
                begin
                  if Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsBoolean
                    then int16:=1
                    else int16:=0;
WriteToLog('    Boolean');
                end
              else int16:=SmallInt(Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsInteger);
            Move(int16,pBuf^,2);
            StrLen_or_Ind:=2;
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
          end;
        SQL_DOUBLE:
          begin
WriteToLog('    SQL_DOUBLE');
            // Excel: cannot load AutoInc and Logical as Float
            double8:=Stmt.Result.Fields.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsFloat;
WriteToLog('    Got');
            Move(double8,pBuf^,8);
WriteToLog('    Moved');
            StrLen_or_Ind:=8;
WriteToLog('    Len');
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
WriteToLog('    OK!');
          end;
        SQL_TIMESTAMP:
          begin
WriteToLog('    SQL_TIMESTAMP');
//DateTimeToString(str,'yyyy',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime);
            DateTime.Year     := StrToInt(FormatDateTime('yyyy',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            DateTime.Month    := StrToInt(FormatDateTime('m',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            DateTime.Day      := StrToInt(FormatDateTime('d',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            DateTime.Hour     := StrToInt(FormatDateTime('h',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            DateTime.Minute   := StrToInt(FormatDateTime('n',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            DateTime.Second   := StrToInt(FormatDateTime('s',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            DateTime.Fraction := StrToInt(FormatDateTime('z',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Move(DateTime,pBuf^,SizeOf(DateTime));
            StrLen_or_Ind:=SizeOf(DateTime);
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
          end;
        SQL_DATE:
          begin
WriteToLog('    SQL_DATE');
            Date.Year  := StrToInt(FormatDateTime('yyyy',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Date.Month := StrToInt(FormatDateTime('m',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Date.Day   := StrToInt(FormatDateTime('d',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Move(Date,pBuf^,SizeOf(Date));
            StrLen_or_Ind:=SizeOf(Date);
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
          end;
        SQL_TIME:
          begin
WriteToLog('    SQL_TIME');
            Time.Hour     := StrToInt(FormatDateTime('h',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Time.Minute   := StrToInt(FormatDateTime('n',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Time.Second   := StrToInt(FormatDateTime('s',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1].AsDateTime));
            Move(Time,pBuf^,SizeOf(Time));
            StrLen_or_Ind:=SizeOf(Time);
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
          end;
-12,-13,-14,-16,-19,
-79..-20,
        SQL_VARCHAR,
        SQL_LONGVARCHAR,
        SQL_VARBINARY,
        SQL_LONGVARBINARY,
        SQL_BINARY:
          begin
  Type_BLOB:
WriteToLog('    SQL_BINARY');
            BS := TEasyBlobStream.Create(TBLOBField(Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger-1]),bmRead);
WriteToLog('    created');
            BS.Position:=0;
WriteToLog('    positioned');
WriteToLog('    buffer length = '+Stmt.Bind.FieldByName('BufferLength').AsString+' bytes');

            pSmallInt(pBuf)^:=0;  // First 2 Bytes must be Null - BDE
            Buf := Buf + 2;       // BLOB field copyes into buffer starting with 2 Bytes later - BDE
            pBuf:= Pointer(Buf);
            StrLen_or_Ind := BS.Read(pBuf^,Stmt.Bind.FieldByName('BufferLength').AsInteger-2); // StrLen_or_Ind = length
WriteToLog('    '+IntToStr(StrLen_or_Ind)+' bytes placed into buffer');
            // Set Len indicator
            if BS.Size > (Stmt.Bind.FieldByName('BufferLength').AsInteger-2)
              then
                begin
//                  StrLen_or_Ind := SQL_NO_TOTAL;
                  Result:=SQL_SUCCESS_WITH_INFO;
WriteToLog('    Data truncated:');
                end;
WriteToLog('    Len='+IntToStr(StrLen_or_Ind));
WriteToLog('    pIndBuf='+IntToHex(Integer(pIndBuf),8));
            if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pIndBuf^,4);
WriteToLog('    StrLen_or_Ind has been set');
            BS.Free;
WriteToLog('    freed');
          end;
      else
  Type_Unknown:
WriteToLog('    Unknown binding DataType='+IntToStr(Stmt.Bind.FieldByName('TargetType').AsInteger));
        pchar(pBuf)^:=#0; // set 1-st byte of out buffer to 0
{
       int32:=0;
       Move(int32,pBuf^,4);
       Move(int32,Pointer(integer(pBuf)+4)^,4); // 8 bytes = 0
}
WriteToLog('    StrLen_or_Ind='+IntToHex(Buf,8));
        StrLen_or_Ind := SQL_NULL_DATA;
        if IndBuf<>SQL_NULL_HANDLE then Move(StrLen_or_Ind,pBuf^,4);
      end; // case
      Stmt.Bind.FindNext;
    end; //for i
  if not Stmt.Result.Eof then
    if Integer(RowCountPtr)<>SQL_NULL_HANDLE then RowCountPtr^:=row;
  Stmt.Result.Next;
 end; // for row
 if not Stmt.Result.EOF then Stmt.Result.Prior;

WriteToLog(' ## FetchData');
end;

///// SQLFetch /////

Function SQLFetch  (Stmt:PStmt): RETCODE; stdcall;
begin
WriteToLog('>>> SQLFetch called');
{
if Stmt.Result.FieldCount=15
then
begin
Result:=SQL_NO_DATA;
exit;
end;
}
if Stmt.Result.Active=True then WriteToLog('    RecNo='+IntToStr(Stmt.Result.RecNo));

  // set cursor position
WriteToLog('    Set cursos position:');
  if Stmt.FreshResult=True
    then Stmt.FreshResult:=False
    else Stmt.Result.Next;

  if Stmt.Result.EOF
    then
      begin
WriteToLog('    EOF - SQL_NO_DATA');
        Result:=SQL_NO_DATA;
      end
    else
      begin
        // get data
WriteToLog('    getting data...');
        Result:=FetchData(Stmt,1,1,nil,nil,1);
      end;

if Stmt.Result.Active=True then WriteToLog('    New record No.'+IntToStr(Stmt.Result.RecNo));

  Stmt.Fetched := True; // Fix for MS Query due it doesnot call SQLFreeStmt with SQL_UNBIND

WriteToLog('### SQLFetch');
end;

///// SQLExtendedFetch /////

Function SQLExtendedFetch  (
{
     SQLHSTMT     StatementHandle,
     SQLUSMALLINT     FetchOrientation,
     SQLINTEGER     FetchOffset,
     SQLUINTEGER *     RowCountPtr,
     SQLUSMALLINT *     RowStatusArray);
}
     Stmt:pStmt;//HSTMT;
		 FetchOrientation:UWORD;
		 FetchOffset:SDWORD;
		 RowCountPtr: PInteger;//{UNALIGNED} UDWORD;
		 RowStatusArray: PSmallInt//{UNALIGNED} UWORD
                            ): RETCODE; stdcall;
var
  i: Integer;
label
  Last;
begin
WriteToLog('>>> SQLExtendedFetch');
//	Result:=SQL_SUCCESS;
WriteToLog('    FetchOffset='+IntToStr(FetchOffset));

if Integer(RowCountPtr)=SQL_NULL_HANDLE
then
WriteToLog('    RowCountPtr=NULL')
else
WriteToLog('    RowCount='+IntToStr(RowCountPtr^));

if Integer(RowStatusArray)=SQL_NULL_HANDLE
then
WriteToLog('    RowStatusArray=NULL')
else
WriteToLog('    @RowStatusArray='+IntToHex(Integer(RowStatusArray),8));

  if Integer(FetchOrientation)<>SQL_NULL_HANDLE
    then
      begin
WriteToLog('    FetchOrientation='+IntToStr(FetchOrientation));
        case FetchOrientation of
          SQL_FETCH_NEXT     : // 1
            begin
if Stmt.Result.Active=True then WriteToLog('    RecNo='+IntToStr(Stmt.Result.RecNo));
              // Scrolling
              if Stmt.FreshResult=True
                then Stmt.FreshResult:=False
                else Stmt.Result.Next;
              // Fetching
              if Stmt.Result.EOF
                then
                  begin
WriteToLog('    EOF - SQL_NO_DATA');
                    Result:=SQL_NO_DATA;
                  end
                else
                  begin
WriteToLog('    getting data...');
{
                    if (Stmt.Result.RecNo+Stmt.Options[SQL_ROWSET_SIZE])
                        > (Stmt.Result.RecordCount+1)
}
{
                    if Word(Stmt.Result.RecordCount-Stmt.Result.RecNo)
                        < (Stmt.Options[SQL_ROWSET_SIZE]-1)
                      then goto Last;
}
                    Result:=FetchData(Stmt,FetchOrientation,FetchOffset,RowCountPtr,RowStatusArray,Stmt.Options[SQL_ROWSET_SIZE]);
                  end;
if Stmt.Result.Active=True then WriteToLog('    RecNo='+IntToStr(Stmt.Result.RecNo));
            end;
          SQL_FETCH_FIRST    : // 2
            begin
              Stmt.Result.First;
              Result:=FetchData(Stmt,FetchOrientation,FetchOffset,RowCountPtr,RowStatusArray,Stmt.Options[SQL_ROWSET_SIZE]);
            end;
          SQL_FETCH_LAST     : // 3
            begin
Last:         Stmt.Result.Last;
              for i:=2 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
              Result:=FetchData(Stmt,FetchOrientation,FetchOffset,RowCountPtr,RowStatusArray,Stmt.Options[SQL_ROWSET_SIZE]);
              for i:=2 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
            end;
          SQL_FETCH_PRIOR    : // 4
            begin
              // Set cursor position
              for i:=1 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
//              if Stmt.Result.Eof then  for i:=2 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
//              Stmt.Result.Prior;               // Check BOF
              if Stmt.Result.BOF
                then
                  begin
WriteToLog('    BOF-SQL_NO_DATA');
                    Result:=SQL_NO_DATA;
                  end
                else
                  begin
WriteToLog('    getting data...');
                    // Get data
                    Result:=FetchData(Stmt,FetchOrientation,FetchOffset,RowCountPtr,RowStatusArray,Stmt.Options[SQL_ROWSET_SIZE]);
                    // Set cursor position
                    for i:=2 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
                  end;
{
              if Stmt.Result.RecNo=1
                then Stmt.FreshResult:=True;
              Result:=SQLFetch(Stmt);
              if Stmt.Result.RecNo=1
                then Stmt.FreshResult:=True
                else Stmt.Result.RecNo:=Stmt.Result.RecNo-1;
}
            end;
          SQL_FETCH_ABSOLUTE : // 5
            begin
              Stmt.Result.RecNo:=FetchOffset;
              if Stmt.Result.RecNo=1
                then Stmt.FreshResult:=True;
              Result:=FetchData(Stmt,FetchOrientation,FetchOffset,RowCountPtr,RowStatusArray,Stmt.Options[SQL_ROWSET_SIZE]);
              if Stmt.Result.RecNo=1
                then Stmt.FreshResult:=True
                else
                  for i:=1 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
            end;
          SQL_FETCH_RELATIVE : // 6
            begin
              if (Stmt.Result.RecNo+FetchOffset)<1
                then Stmt.Result.RecNo:=1
                else Stmt.Result.RecNo:=Stmt.Result.RecNo+FetchOffset;
              if Stmt.Result.RecNo=1
                then Stmt.FreshResult:=True;
              Result:=FetchData(Stmt,FetchOrientation,FetchOffset,RowCountPtr,RowStatusArray,Stmt.Options[SQL_ROWSET_SIZE]);
              if Stmt.Result.RecNo=1
                then Stmt.FreshResult:=True
                else
                  for i:=1 to Stmt.Options[SQL_ROWSET_SIZE] do Stmt.Result.Prior;
            end;
        else
            begin
              Result:=SQL_ERROR;
WriteToLog('    Unknown FetchOrientation');
            end;
        end; // case
      end
    else
      begin
        Result:=SQL_ERROR;
WriteToLog('    FetchOrientationPtr=SQL_NULL_HANDLE');
      end;

WriteToLog('### SQLExtendedFetch');
end;

///// SQLFetchScroll /////

Function SQLFetchScroll (
     arg0:SQLHSTMT;
		 arg1:SQLSMALLINT;
		 arg2:SQLINTEGER
                          ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLFetchScroll called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetCursorName /////

Function SQLGetCursorName  (
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 var arg3:{UNALIGNED} SWORD
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetCursorName called');
	Result:=SQL_SUCCESS;
end;

///// SQLNumResultCols /////

Function SQLNumResultCols (
             Stmt:PStmt;//HSTMT;
        		 ColumnCount:PSmallInt// {UNALIGNED} SWORD
                          ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLNumResultCols called');
WriteToLog('    Stmt='+IntToHex(Integer(Stmt),8));
{
  Move(StatementHandle,p,4);
  Move(p^,ResultTable,4);
}
  if Integer(ColumnCount)<>SQL_NULL_HANDLE
    then ColumnCount^:=Stmt.Result.FieldCount;

{
// for MFC!!!
if Integer(ColumnCount)<>SQL_NULL_HANDLE
  then
if pos('UPDATE ',Stmt.Result.SQL.Text)>0 then ColumnCount^ := 3;
// end - for MFC!!!
}

	Result:=SQL_SUCCESS;

WriteToLog('### SQLNumResultCols RESULT='+IntToStr(ColumnCount^));
end;

///// SQLRowCount /////

Function SQLRowCount  (
            Stmt:pStmt;//:HSTMT;
		        RecordCount:PInteger// {UNALIGNED} SDWORD
                      ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLRowCount called');

WriteToLog('    Stmt='+IntToHex(Integer(Stmt),8));

  if Integer(RecordCount)<>SQL_NULL_HANDLE
    then
      if Stmt.Result.Active=False
        then RecordCount^ := Stmt.Result.RowsAffected // for BDE!!!
        else RecordCount^ := Stmt.Result.RecordCount;

{
// for BDE!!!
if Integer(RecordCount)<>SQL_NULL_HANDLE
  then
if pos('UPDATE',Stmt.Result.SQL.Text)>0 then RecordCount^ := 1;
// end - for BDE!!!
}

WriteToLog('### SQLRowCount RESULT='+IntToStr(RecordCount^));

	Result:=SQL_SUCCESS;
end;

///// SQLSetCursorName /////

Function SQLSetCursorName  (arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetCursorName called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetParam /////

Function SQLSetParam  (arg0:HSTMT;
		  arg1:UWORD;
		  arg2:SWORD;
		  arg3:SWORD;
		  arg4:UDWORD;
		  arg5:SWORD;
		  arg6:PTR;
		  var arg7: {UNALIGNED} SDWORD
                      ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetParam called');
	Result:=SQL_SUCCESS;
end;

///// SQLTransact /////

Function SQLTransact  (arg0:HENV;
		  arg1:HDBC;
		  arg2:UWORD): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLTransact called');
	Result:=SQL_SUCCESS;
end;

///// SQLDriverConnect /////

Function SQLDriverConnect  (
     Connection:PConnection;//HDBC;
		 WindowHandle: HWND;
		 InConnectionStr:UCHAR;
		 InStrLength:smallint;//SWORD;
		 OutConnectionStr:UCHAR;
		 OutStrBufferLength:SWORD;
		 var OutStrOutLength: {UNALIGNED} SWORD;
		 DriverCompletion:UWORD
                            ): RETCODE; stdcall;
var
{
    Connection : TConnection;
    p: pointer;
}
  str1: String;
  DBtest:TEasyDatabase;
  DatabasePath, FileName:PChar;
  Path, Default,DSN : String;
  len: Integer;
begin
WriteToLog('>>> SQLDriverConnect called with parameters'+#10+#13+
'    "'+InConnectionStr+'"'+#10+#13+
'    and Mode='+IntToStr(DriverCompletion));

  FileName:=AllocMem(_MAX_PATH+1);
 try
  StrCopy(FileName,'ODBC.INI');
  DatabasePath:=AllocMem(_MAX_PATH+1);
 try
  StrCopy(DatabasePath,'');
  Path := 'Path';
  Default := '';
  DSN := '';

  if pos('DATABASE=',InConnectionStr)=0
    then
      begin
        if pos('DSN=',InConnectionStr)=0
          then str1:=''
          else
            begin
              DSN:=Copy(InConnectionStr,pos('DSN=',InConnectionStr)+4,_MAX_PATH);
WriteToLog('    DSN='+DSN+'!');
              DSN:=Copy(DSN,1,pos(';',DSN)-1);
WriteToLog('    DSN='+DSN+'!');
              StrCopy(Connection.DSN,pChar(DSN));
              try   // copy Path from ODBC.INI to str1
                SQLGetPrivateProfileString(pChar(DSN),pChar(Path),pChar(Default),DatabasePath,_MAX_PATH,FileName);
              except
              on E: Exception do
WriteToLog('    SQLGetPrivateProfileString failed: ' + e.Message);
              end;
WriteToLog('    Path='+DatabasePath+'!');
                Str1:=DatabasePath;
WriteToLog('    Path='+str1+'!');
            end;
      end
    else // Get Database parameter from InConnectionStr
      begin
        str1:=Copy(InConnectionStr,pos('DATABASE=',InConnectionStr)+9,_MAX_PATH);
        str1:=Copy(str1,1,pos(';',str1)-1);
      end;
  StrCopy(Connection.Database,pChar(Str1));
  DBtest:=TEasyDatabase.Create(Nil);
  try
  if DBtest.IsEasyTableDatabaseFile(Connection.Database) then Result:=SQL_SUCCESS else Result:=SQL_ERROR;

  if (DriverCompletion=SQL_DRIVER_PROMPT)
  or ( (Result=SQL_ERROR)
    and //  if not DriverCompletion=SQL_DRIVER_NOPROMPT
    ((DriverCompletion=SQL_DRIVER_COMPLETE) or (DriverCompletion=SQL_DRIVER_COMPLETE_REQUIRED)) )
   then // Dialog form
    begin
     DSNsetupForm := TDSNsetupForm.Create(Nil);
     try
     repeat
  // Show dialog
      DSNsetupForm.DatabaseFile.Text:=str1;   // Copy path to Dialog fields
      DSNsetupForm.DSN.Text:=DSN;             // Copy DSN to Dialog fields
      try
        DSNsetupForm.Show;
      except
      on E: Exception do
WriteToLog('DSNsetupForm.Show failed: ' + e.Message);
      end;
      repeat
       Application.ProcessMessages;
      until not DSNsetupForm.Visible;
 	    if DSNsetupForm.Button=btnCancel then
        begin
WriteToLog('    DSNsetupForm - Cancel Pressed');
WriteToLog('### SQLDriverConnect finished');
          Result := SQL_ERROR;
          Exit;
        end;
      StrCopy(Connection.Database,pChar(DSNsetupForm.DatabaseFile.Text));
      StrCopy(Connection.DSN,pChar(DSNsetupForm.DSN.Text));
{ ================= OLD CODE =================
      try //Check database path
        DBtest.DatabaseName:='DBtest';
        DBtest.DatabaseFileName:=Connection.Database;
        DBtest.Open;
      except
      on E: Exception do
WriteToLog('    Database.Open failed: ' + e.Message);
      end;
     until DBtest.Connected;
================= OLD CODE =================}
     until DBtest.IsEasyTableDatabaseFile(Connection.Database);
     Result:=SQL_SUCCESS;
     finally
     DSNsetupForm.Free;
     end;
    end;
  finally
  DBtest.Free;
  end;
 finally
  FreeMem(DatabasePath);
 end;
WriteToLog('    Database='+Connection.Database+'!');
WriteToLog('    DSN='+Connection.DSN+'!');

{
  if InStrLength=SQL_NTS
    then Len1:=Length(InConnectionStr)
    else Len1:=InStrLength;

  if Len1>OutStrBufferLength
    then
     begin
//      str1:='DATABASE='+str1+';';
      OutConnectionStr:='DATABASE='+str1+';';
//      Move(str1,OutConnectionStr,length(str1)+1);
//      (PChar(OutConnectionStr)+length(str1))^:=#0;
//      Move(InConnectionStr,OutConnectionStr,Length(InConnectionStr)+1)
//      Move(InConnectionStr,OutConnectionStr,InStrLength+1)
//      StrCopy(PChar(OutConnectionStr),InConnectionStr)
     end
    else
     begin
      Move(InConnectionStr,OutConnectionStr,OutStrBufferLength-1);
      (PChar(OutConnectionStr)+OutStrBufferLength)^:=#0;
WriteToLog('Buffer is too short. Truncated.');
     end;
}

  if OutStrBufferLength=0
    then OutStrOutLength:=0
    else
begin
  str1:='DSN='+Connection.DSN+';'+
        'DATABASE='+Connection.Database+';';

{  if OutStrBufferLength > Length(str1)
    then StrCopy(OutConnectionStr,pChar(str1))
    else
}

  OutStrOutLength:=Length(str1);

//  StrLCopy(OutConnectionStr,pChar(str1),OutStrBufferLength-1);
  if OutStrOutLength < OutStrBufferLength then
    len := OutStrOutLength+1
  else
    len := OutStrBufferLength;
  Move(pChar(str1)^,OutConnectionStr^,len);
  if  (OutStrBufferLength<>-3)
  and (OutStrOutLength>OutStrBufferLength)
    then Result:=SQL_SUCCESS_WITH_INFO;

end;

 finally
  FreeMem(FileName);
 end;

{
  Move(ConnectionHandle,p,4);
  Move(Connection,p^,SizeOf(Connection));
}
if OutStrBufferLength>0 then WriteToLog(
'### SQLDriverConnect finished with:'+#10+#13+
'    InConnectionStr="'+InConnectionStr+'";'+#10+#13+
'    OutConnectionStr="'+OutConnectionStr+'";'+#10+#13+
'    InStrLength='+IntToStr(InStrLength)+';'+#10+#13+
'    OutStrBufferLength='+IntToStr(OutStrBufferLength)+';'+#10+#13+
'    OutStrOutLength='+IntToStr(OutStrOutLength)+'.'+#10+#13+
#10+#13+
'    Connection="'+Connection.Database+'"'
)else WriteToLog(
'### SQLDriverConnect finished with:'+#10+#13+
'    InConnectionStr="'+InConnectionStr+'";'+#10+#13+
'    OutConnectionStr=Not Changed'+#10+#13+
'    InStrLength='+IntToStr(InStrLength)+';'+#10+#13+
'    OutStrBufferLength='+IntToStr(OutStrBufferLength)+';'+#10+#13+
'    OutStrOutLength='+IntToStr(OutStrOutLength)+'.'+#10+#13+
#10+#13+
'    Connection="'+Connection.Database+'"');

	// This really doesn't show nearly all that you need to know
	// about driver connect, read the programmer's reference

{
	if ((InStrLength == SQL_NTS) && (InConnectionStr))
		InStrLength = strlen(InConnectionStr);

	MessageBox(WindowHandle,
		   "Connection dialog would go here",
		   "Sample driver",
		   MB_OK);

	if ((OutConnectionStr) && cbConnStrOut > 0): RETCODE; stdcall;
	begin
		strncpy(OutConnectionStr,
		        InConnectionStr,
			(InStrLength == SQL_NTS) ? cbConnStrOut - 1 :
						min(cbConnStrOut,InStrLength));

		OutConnectionStr[cbConnStrOut - 1] = '\0';
	end;

	if (OutStrOutLength)
		*OutStrOutLength = InStrLength;
}
WriteToLog('    Result='+IntToStr(Result));
end;

///// SQLSetStmtOption /////

Function SQLSetStmtOption  (
                Stmt:pStmt;//HSTMT;
                fOption:UWORD;
                vParam:UDWORD
                            ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLSetStmtOption called');

WriteToLog('    fOption='+IntToStr(fOption));
WriteToLog('    vParam='+IntToStr(vParam));

  if // (fOption>=SQL_STMT_OPT_MIN) and
    (fOption<=SQL_STMT_OPT_MAX) and
    (fOption<>SQL_USE_BOOKMARKS) // bookmarks are not supported yet!!!
    then
      begin
    Stmt.Options[fOption] := vParam;
	  Result:=SQL_SUCCESS;
      end
    else
      begin
WriteToLog('    Unknown parameter!');
	  Result:=SQL_ERROR;
      end;

WriteToLog('### SQLSetStmtOption');
end;

///// SQLGetStmtOption /////

Function SQLGetStmtOption  (
{
     arg0:HSTMT;
		 arg1:UWORD;
		 arg2:PTR
}
                Stmt:pStmt;//HSTMT;
                fOption:UWORD;
                pvParam:PInteger
                            ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLGetStmtOption called');
  if // (fOption>=SQL_STMT_OPT_MIN) and
  (fOption<=SQL_STMT_OPT_MAX)
    then
      if Integer(pvParam)<>SQL_NULL_HANDLE
        then
          begin
            pvParam^ := Stmt.Options[fOption];
        	  Result:=SQL_SUCCESS;
          end
        else
          begin
        	  Result:=SQL_INVALID_HANDLE;
          end
    else
      begin
WriteToLog('    Unknown parameter!');
	  Result:=SQL_ERROR;
      end;

WriteToLog('### SQLGetStmtOption');
end;

///// SQLSetConnectOption /////

Function SQLSetConnectOption  (arg0:HDBC;
		 arg1:UWORD;
		 arg2:UDWORD): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetConnectOption called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetConnectOption /////

Function SQLGetConnectOption  (
     Connection:PConnection;//HDBC;
		 Attribute:UWORD;
		 Value:PTR
                               ): RETCODE; stdcall;
Procedure SetAttrStr(Val:String);
  begin
    StrCopy(pChar(Value),pChar(Val));
//    ValueLength:=Length(Val);
  end;
{
Procedure SetAttrSmallInt(Val:SmallInt);
  begin
    pSmallInt(Value)^:=Val;
//    ValueLength:=2;
  end;
}
Procedure SetAttrInt(Val:LongWord);
  begin
    pLongWord(Value)^:=Val;
//    ValueLength:=4;
  end;
begin
WriteToLog('>>> SQLGetConnectOption called');
WriteToLog('    Attribute='+IntToStr(Attribute));

  if Integer(Value)=SQL_NULL_HANDLE then
    begin
WriteToLog('    ValuePtr=SQL_NULL_HANDLE');
      Result:=SQL_ERROR;
      Exit;
    end;

  Result:=SQL_SUCCESS;
  case Attribute of
    SQL_ATTR_ACCESS_MODE         : ;  //(ODBC 1.0)
//  SQL_ATTR_ASYNC_ENABLE        : ;  //(ODBC 3.0)
//  SQL_ATTR_AUTO_IPD            : ;  //(ODBC 3.0)
    SQL_ATTR_AUTOCOMMIT          : ;  //(ODBC 1.0)
//  SQL_ATTR_CONNECTION_DEAD     : ;  //(ODBC 3.5)
//  SQL_ATTR_CONNECTION_TIMEOUT  : ;  //(ODBC 3.0)
    SQL_ATTR_CURRENT_CATALOG     : SetAttrStr(Connection.Database);  // =109 (ODBC 2.0)
    SQL_ATTR_LOGIN_TIMEOUT       : ;  //(ODBC 1.0)
//  SQL_ATTR_METADATA_ID         : ;  //(ODBC 3.0)
    SQL_ATTR_ODBC_CURSORS        : ;  //(ODBC 2.0)
    SQL_ATTR_PACKET_SIZE         : ;  //(ODBC 2.0)
    SQL_ATTR_QUIET_MODE          : ;  //(ODBC 2.0)
    SQL_ATTR_TRACE               : ;  //(ODBC 1.0)
    SQL_ATTR_TRACEFILE           : ;  //(ODBC 1.0)
    SQL_ATTR_TRANSLATE_LIB       : ;  //(ODBC 1.0)
    SQL_ATTR_TRANSLATE_OPTION    : ;  //(ODBC 1.0)
    SQL_ATTR_TXN_ISOLATION       : ;  //(ODBC 1.0)
    SQL_ATTR_CONNECTION_DEAD     : SetAttrInt(SQL_CD_FALSE); // =1209 SQL_CD_TRUE
  else
WriteToLog('    Unknown Attribute!');
  	Result:=SQL_ERROR;
  end;

WriteToLog('    Value='+PChar(Value));
WriteToLog('>>> SQLGetConnectOption finished');
end;

///// SQLGetData /////

Function SQLGetData  (
               Stmt:PStmt;
          		 ColumnNumber:UWORD;
          		 TargetType:SWORD;
          		 TargetValue:PTR;
          		 BufferLength:Integer;//SDWORD;
          		 StrLen_or_IndPtr: PInteger//{UNALIGNED} SDWORD
                               ): RETCODE; stdcall;
var
  DateTime:SQL_TIMESTAMP_STRUCT;
  Date:SQL_DATE_STRUCT;
  Time:SQL_TIME_STRUCT;
  BS:TStream;
label
  Type_Char,
  Type_Integer,
  Type_SmallInt,
  Type_Unknown;
begin
WriteToLog('>>> SQLGetData called');
	Result:=SQL_SUCCESS;

WriteToLog('    ColumnNumber='+IntToStr(ColumnNumber)+';');
WriteToLog('    TargetType='+IntToStr(TargetType)+';');
WriteToLog('    BufferLength='+IntToStr(BufferLength)+';');
if Integer(StrLen_or_IndPtr)<>SQL_NULL_HANDLE then WriteToLog('    @StrLen_or_IndPtr='+IntToHex(Integer(StrLen_or_IndPtr),8)+'.') else WriteToLog('    @StrLen_or_IndPtr=0.');;

  // check Null
  if Stmt.Result.Fields[ColumnNumber-1].IsNull
    then
      begin
WriteToLog('    @StrLen_or_IndPtr='+IntToHex(Integer(StrLen_or_IndPtr),8));
        StrLen_or_IndPtr^ := SQL_NULL_DATA;
WriteToLog('    StrLen_or_IndPtr^=SQL_NULL_DATA');
      end
    else // data is not null
  if Integer(TargetValue)=SQL_NULL_HANDLE
    then
WriteToLog('    @TargetValue=0 - Skip result')
    else
  case TargetType of
    SQL_C_DEFAULT:
      begin
WriteToLog('    SQL_C_DEFAULT');
           if BufferLength=2 then
             goto Type_SmallInt;
           if BufferLength=4 then
             goto Type_Integer;
           if (BufferLength>=1)
           or (BufferLength=SQL_NTS)
           then
             goto Type_Char;
           goto Type_Unknown;
      end;
    -18,  // MS VS 2003
    SQL_INTEGER :
      begin
  Type_Integer:
WriteToLog('    Integer');
        PInteger(TargetValue)^ := Stmt.Result.Fields[ColumnNumber-1].AsInteger;
        StrLen_or_IndPtr^ := 4;
WriteToLog('    Value:='+IntToStr(PInteger(TargetValue)^));
      end;
    -15, -17,  // MS VS 2003
    SQL_SMALLINT:
      begin
  Type_SmallInt:
        if Stmt.Result.FieldDefs[ColumnNumber-1].DataType = ftBoolean
          then  // Boolean for BDE
            begin
              if Stmt.Result.Fields[ColumnNumber-1].AsBoolean
                then PSmallInt(TargetValue)^:=1
                else PSmallInt(TargetValue)^:=0;
WriteToLog('    Boolean');
            end
          else
            begin
              PSmallInt(TargetValue)^ := SmallInt(Stmt.Result.Fields[ColumnNumber-1].AsInteger);
WriteToLog('    SmallInt');
            end;
        StrLen_or_IndPtr^ := 2;
WriteToLog('    Value:='+IntToStr(PSmallInt(TargetValue)^));
      end;
    SQL_DOUBLE:
      begin
        PDouble(TargetValue)^ := Stmt.Result.Fields.Fields[ColumnNumber-1].AsFloat;
        StrLen_or_IndPtr^ := 8;
      end;
    SQL_TIMESTAMP:
      begin
WriteToLog('    SQL_TIMESTAMP');
//DateTimeToString(str,'yyyy',Stmt.Result.Fields[Stmt.Bind.FieldByName('ColumnNumber').AsInteger].AsDateTime);
        DateTime.Year     := StrToInt(FormatDateTime('yyyy',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        DateTime.Month    := StrToInt(FormatDateTime('m',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        DateTime.Day      := StrToInt(FormatDateTime('d',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        DateTime.Hour     := StrToInt(FormatDateTime('h',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        DateTime.Minute   := StrToInt(FormatDateTime('n',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        DateTime.Second   := StrToInt(FormatDateTime('s',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        DateTime.Fraction := StrToInt(FormatDateTime('z',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        PSQL_TIMESTAMP_STRUCT(TargetValue)^ := DateTime;
        StrLen_or_IndPtr^ := SizeOf(DateTime);
      end;
    SQL_DATE:
      begin
WriteToLog('    SQL_DATE');
        Date.Year  := StrToInt(FormatDateTime('yyyy',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        Date.Month := StrToInt(FormatDateTime('m',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        Date.Day   := StrToInt(FormatDateTime('d',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        PSQL_DATE_STRUCT(TargetValue)^ := Date;
        StrLen_or_IndPtr^ := SizeOf(Date);
      end;
    SQL_TIME:
      begin
WriteToLog('    SQL_TIME');
        Time.Hour     := StrToInt(FormatDateTime('h',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        Time.Minute   := StrToInt(FormatDateTime('n',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        Time.Second   := StrToInt(FormatDateTime('s',Stmt.Result.Fields[ColumnNumber-1].AsDateTime));
        PSQL_TIME_STRUCT(TargetValue)^ := Time;
        StrLen_or_IndPtr^ := SizeOf(Time);
      end;
    SQL_WCHAR,
    SQL_CHAR:
           begin
  Type_Char:
WriteToLog('    Char');
{
        if (Integer(Pointer(BufferLength)) = SQL_NULL_HANDLE) then
        StrCopy(PChar(TargetValue),PChar(Stmt.Result.Fields[ColumnNumber-1].AsString))
         else
}
             StrCopy(PChar(TargetValue),
             PChar(Copy(Stmt.Result.Fields[ColumnNumber-1].AsString,
                        1,BufferLength)));
             PChar(Integer(TargetValue)+BufferLength)^ := #0;
             StrLen_or_IndPtr^ := Length(PChar(TargetValue));
WriteToLog('    Value:="'+PChar(TargetValue)+'"');
           end;
    SQL_VARCHAR,
    SQL_LONGVARCHAR,
    SQL_VARBINARY,
    SQL_LONGVARBINARY,
    SQL_BINARY:
      begin
WriteToLog('    SQL_BINARY');
      BS := TEasyBlobStream.Create(TBLOBField(Stmt.Result.Fields[ColumnNumber-1]),bmRead);
WriteToLog('    created');
      BS.Position:=0;
WriteToLog('    positioned');

            pSmallInt(TargetValue)^:=0;  // First 2 Bytes must be Null - BDE
                    // BLOB field copyes into buffer starting with 2 Bytes later - BDE
            StrLen_or_IndPtr^ := BS.Read(Pointer(Integer(TargetValue)+2)^,Stmt.Bind.FieldByName('BufferLength').AsInteger-2); // StrLen_or_IndPtr = length
WriteToLog('    '+IntToStr(StrLen_or_IndPtr^)+' bytes placed into buffer');
            // Set Len indicator
            if BS.Size > (Stmt.Bind.FieldByName('BufferLength').AsInteger-2)
              then StrLen_or_IndPtr^ := SQL_NO_TOTAL;      // if no all the data has been got
            BS.Free;

WriteToLog('    freed');
      if StrLen_or_IndPtr^ > Stmt.Bind.FieldByName('BufferLength').AsInteger
        then StrLen_or_IndPtr^ := SQL_NO_TOTAL;
WriteToLog('    Len='+IntToStr(StrLen_or_IndPtr^));
      end
  else
  Type_Unknown:
WriteToLog('    Unsupported TargetType='+IntToStr(TargetType));
	Result:=SQL_ERROR;
  end;
if Integer(StrLen_or_IndPtr)<>SQL_NULL_HANDLE then WriteToLog('    StrLen_or_IndPtr='+IntToStr(StrLen_or_IndPtr^)+'.');
WriteToLog('### SQLGetData');
end;

///// SQLGetFunctions /////

Function SQLGetFunctions  (
              ConnectionHandle:HDBC;
              FunctionId:UWORD;
              Supported:Pointer
                            ): RETCODE; stdcall;
var
  i: integer;
  AllFunctions      : array [0..99] of UWORD;
  ODBC3_AllFunctions : array [1..SQL_API_ODBC3_ALL_FUNCTIONS_SIZE] of word;
begin

WriteToLog('>>> SQLGetFunctions called with FunctionId='+IntToStr(FunctionId));

{
SQL_API_ALL_FUNCTIONS returns an array
of 'booleans' representing whether a
function is implemented by the driver.
CAUTION: Only functions defined in ODBC
version 2.0 and earlier are returned, the
new high-range function numbers defined by
X/Open break this scheme.   See the new
method below -- SQL_API_ODBC3_ALL_FUNCTIONS
}

  // Clear array
  for i:=0 to 99
    do AllFunctions[i]:=SQL_FALSE;

{
// Allow all functions!!! - For testing only!
  for i:=0 to 99
    do AllFunctions[i]:=SQL_TRUE;
}

// ISO'92 Functions
// ===========================
//  AllFunctions[SQL_API_SQLALLOCHANDLE      ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLBINDCOL          ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLCANCEL           ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLCLOSECURSOR      ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLCOLATTRIBUTE     ] := SQL_TRUE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLCONNECT          ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLCOPYDESC         ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLDATASOURCES      ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLDESCRIBECOL      ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLDISCONNECT       ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLDRIVERS          ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLENDTRAN          ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLEXECDIRECT       ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLEXECUTE          ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLFETCH            ] := SQL_TRUE;  // Core level; ODBC v.2.x - only for single row, ODBC v.3.x - for multiple rows
//  AllFunctions[SQL_API_SQLFETCHSCROLL      ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLFREEHANDLE       ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLFREESTMT         ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLGETCONNECTATTR   ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLGETCURSORNAME    ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLGETDATA          ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLGETDESCFIELD     ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLGETDESCREC       ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLGETDIAGFIELD     ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLGETDIAGREC       ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLGETENVATTR       ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLGETFUNCTIONS     ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLGETINFO          ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLGETSTMTATTR      ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLGETTYPEINFO      ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLNUMRESULTCOLS    ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLPARAMDATA        ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLPREPARE          ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLPUTDATA          ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLROWCOUNT         ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLSETCONNECTATTR   ] := SQL_FALSE;  // Core level; ODBC v.3.x
  AllFunctions[SQL_API_SQLSETCURSORNAME    ] := SQL_TRUE;  // Core level; ODBC v.2.x
//  AllFunctions[SQL_API_SQLSETDESCFIELD     ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLSETDESCREC       ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLSETENVATTR       ] := SQL_FALSE;  // Core level; ODBC v.3.x
//  AllFunctions[SQL_API_SQLSETSTMTATTR      ] := SQL_FALSE;  // Core level; ODBC v.3.x

// X_Open Functions
// ===========================
  AllFunctions[SQL_API_SQLCOLUMNS          ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLSPECIALCOLUMNS   ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLSTATISTICS       ] := SQL_TRUE;  // Core level; ODBC v.2.x   // BDE needed
  AllFunctions[SQL_API_SQLTABLES           ] := SQL_TRUE;  // Core level; ODBC v.2.x

// ODBC Standard Functions
// ===========================
  AllFunctions[SQL_API_SQLBINDPARAMETER    ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLBROWSECONNECT    ] := SQL_FALSE;
  AllFunctions[SQL_API_SQLBULKOPERATIONS   ] := SQL_FALSE; // ODBC v.3.x
  AllFunctions[SQL_API_SQLCOLUMNPRIVILEGES ] := SQL_FALSE;
  AllFunctions[SQL_API_SQLDESCRIBEPARAM    ] := SQL_FALSE;
  AllFunctions[SQL_API_SQLDRIVERCONNECT    ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLFOREIGNKEYS      ] := SQL_FALSE;
  AllFunctions[SQL_API_SQLMORERESULTS      ] := SQL_TRUE;  // for MFC
  AllFunctions[SQL_API_SQLNATIVESQL        ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLNUMPARAMS        ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLPRIMARYKEYS      ] := SQL_FALSE;
  AllFunctions[SQL_API_SQLPROCEDURECOLUMNS ] := SQL_FALSE;
  AllFunctions[SQL_API_SQLPROCEDURES       ] := SQL_FALSE;
//  AllFunctions[SQL_API_SQLSETPOS           ] := SQL_TRUE; // ODBC v.2.x Level1
  AllFunctions[SQL_API_SQLSETSCROLLOPTIONS ] := SQL_TRUE; // Abs
  AllFunctions[SQL_API_SQLTABLEPRIVILEGES  ] := SQL_FALSE;

// ODBC v.2.x Functions
// ===========================
  AllFunctions[SQL_API_SQLALLOCCONNECT     ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLALLOCENV         ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLALLOCSTMT        ] := SQL_TRUE;  // Core level; ODBC v.2.x

  AllFunctions[SQL_API_SQLFREEENV          ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLFREECONNECT      ] := SQL_TRUE;  // Core level; ODBC v.2.x

  AllFunctions[SQL_API_SQLTRANSACT         ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLEXTENDEDFETCH    ] := SQL_TRUE;  // Core level; ODBC v.2.x - we do not support block cursors
  AllFunctions[SQL_API_SQLGETCONNECTOPTION ] := SQL_TRUE;  // Core level; ODBC v.2.x

// - not released yet
AllFunctions[SQL_API_SQLSETSTMTOPTION    ] := SQL_TRUE;  // Core level; ODBC v.2.x

  AllFunctions[SQL_API_SQLERROR            ] := SQL_TRUE;  // Core level; ODBC v.2.x
  AllFunctions[SQL_API_SQLGETSTMTOPTION    ] := SQL_TRUE;  // Core level; ODBC v.2.x

// - not released yet
AllFunctions[SQL_API_SQLSETCONNECTOPTION ] := SQL_TRUE;  // Core level; ODBC v.2.x

// - not released yet
AllFunctions[SQL_API_SQLCOLATTRIBUTES    ] := SQL_TRUE;  // Core Level ;ODBC v.2.x

//WriteToLog('ODBC2 Array Filled');


{
SQL_API_ODBC3_ALL_FUNCTIONS
This returns a bitmap, which allows us to
handle the higher-valued function numbers.
Use  SQL_FUNC_EXISTS(bitmap,function_number)
to determine if the function exists.
}
  for i:=1 to SQL_API_ODBC3_ALL_FUNCTIONS_SIZE
    do ODBC3_AllFunctions[i]:=0;  // v.3.x not supported
//WriteToLog('ODBC3 Array Filled Out');

{
  for i:=0 to 99
    do AllFunctions[i]:=SQL_TRUE;
  AllFunctions[61] := SQL_TRUE;  // MR
  AllFunctions[64] := SQL_TRUE;  // PO
  AllFunctions[64] := SQL_TRUE;  // SO
}

	Result:=SQL_SUCCESS;
  case FunctionId of
// v.2.x or v.3.x All Functions
    SQL_API_ODBC3_ALL_FUNCTIONS:    //v.3
      begin
        Move(ODBC3_AllFunctions,Supported^,SQL_API_ODBC3_ALL_FUNCTIONS_SIZE*2);
        Result := SQL_ERROR;
      end;
    SQL_API_ALL_FUNCTIONS      :    //v.2
      begin
        Move(AllFunctions,Supported^,100*2);
      end;
  else   // single function request
    if FunctionId<=100
      then PWord(Supported)^ := AllFunctions[FunctionId]
      else PWord(Supported)^ := SQL_FALSE;
  end;
WriteToLog('    SQLGetFunctions returned:'
+#10+#13+pchar(Supported)
);
WriteToLog('### SQLGetFunctions Finished');

end;

///// SQLGetInfo /////

Function SQLGetInfo  (
      Connection:PConnection;//HDBC;
		  InfoType:UWORD;
		  Info:PTR;
		  BufferLength:SWORD;
      InfoLength: PSmallInt //{UNALIGNED} SWORD
                      ): RETCODE; stdcall;

Procedure SetInfoChar(Value:String);
  begin
WriteToLog('    SetInfoChar');
//    StrCopy(pChar(Info),pChar(Value));
    if Integer(Info)<>SQL_NULL_HANDLE
      then
        begin
          Move(PChar(Value)^,Info^,1);
WriteToLog('    >Info='+pchar(Info));
        end;
    // set InfoLength
    if Integer(InfoLength)=SQL_NULL_HANDLE then Exit; //  Impossible!
    InfoLength^:=1;
WriteToLog('    Length=1');
  end;

Procedure SetInfoStr(Value:String);
  var
    Terminator: Char;
  begin
WriteToLog('    SetInfoStr');
//    StrCopy(pChar(Info),pChar(Value));
    if Integer(Info)<>SQL_NULL_HANDLE then
      begin
        Move(PChar(Value)^,Info^,BufferLength);
        // set the latest byte in the buffer to 0
        Terminator:=#0;
        Move(Terminator,pointer(Integer(Info)+BufferLength-1)^,1);
WriteToLog('    >Info='+pchar(Info));
      end;
    // set InfoLength
    if Integer(InfoLength)=SQL_NULL_HANDLE then Exit; //  Impossible!
WriteToLog('    not NULL_HANDLE');
    InfoLength^:=Length(Value);
WriteToLog('    >Length='+IntToStr(InfoLength^));
  end;

Procedure SetSmallInt(Value:Word);
  begin
WriteToLog('    SetSmallInt');
    if Integer(Info)<>SQL_NULL_HANDLE
      then
        begin
          pWord(Info)^:=Value;
WriteToLog('    >Info='+IntToStr(pWord(Info)^));
        end;
    if Integer(InfoLength)<>SQL_NULL_HANDLE
      then InfoLength^:=2;
  end;

Procedure SetInteger(Value:LongWord);
  begin
WriteToLog('    SetInteger');
    if Integer(Info)<>SQL_NULL_HANDLE
      then
        begin
          pLongWord(Info)^:=Value;
WriteToLog('    >Info='+IntToStr(pLongWord(Info)^));
        end;
    if Integer(InfoLength)<>SQL_NULL_HANDLE
      then InfoLength^:=4;
  end;
{
const
  SpecCharsMaxCount = 40;
type
  NTS =  Array [0..SpecCharsMaxCount] of Char;
}
var
  sqlSpecChars:String;
{
function  SpecCharsArray:pchar; assembler;
asm
    MOV   EAX,OFFSET @sqlSpecChars
    RET
  @sqlSpecChars:
    DB  307O, 374O, 351O, 342O, 344O, 340O, 345O, 347O, 352O, 353O
    DB  350O, 357O, 356O, 354O, 304O, 305O, 311O, 346O, 306O, 364O
    DB  366O, 362O, 373O, 371O, 377O, 326O, 334O, 341O, 355O, 363O
    DB  372O, 361O, 321O, 000O
end;
}

begin
WriteToLog('>>> SQLGetInfo about '+IntToStr(InfoType));

{
Result:=SQL_SUCCESS;
exit;
}

//  sqlSpecChars:=SpecCharsArray; // - MySQL
  sqlSpecChars:='~@#$%^&*_-+=\}{"'';:?/><,.![]|'; //- Access
//WriteToLog('sqlSpecChars:'+sqlSpecChars);
//WriteToLog('sqlSpecChars:'+IntToHex(PWord(PChar(sqlSpecChars))^,4));

{
if InfoType<>SQL_DRIVER_ODBC_VER then
begin
Result:=SQL_ERROR;
exit;
end;
}

	Result:=SQL_SUCCESS;

  case InfoType of

    SQL_DRIVER_NAME:
      SetInfoStr(DRIVER_DLL_NAME);
    SQL_DRIVER_ODBC_VER:
      SetInfoStr(DRIVER_ODBC_VERSION);
    SQL_DRIVER_VER:
      SetInfoStr(DRIVER_VERSION);

    SQL_DBMS_NAME:
      SetInfoStr(DBMS_NAME);
    SQL_DBMS_VER:
      SetInfoStr(FloatToStr(InternalCurrentVersion));

    SQL_DATABASE_NAME:
      SetInfoStr(Connection.Database);
    SQL_DATA_SOURCE_NAME:
      SetInfoStr(Connection.DSN);

    SQL_SERVER_NAME:
      SetInfoStr(UpperCase(DBMS_NAME));

    SQL_SEARCH_PATTERN_ESCAPE:
      SetInfoChar('\'); // Abs

    SQL_ACTIVE_CONNECTIONS: // MAX_DRIVER_CONNECTIONS
      SetSmallInt(64);//- Access         (1);//- MySQL
    SQL_ACTIVE_STATEMENTS:  // MAX_CONCURRENT_ACTIVITIES
      SetSmallInt(0);

    SQL_CURSOR_COMMIT_BEHAVIOR,
    SQL_CURSOR_ROLLBACK_BEHAVIOR:
      SetSmallInt(0);//Paradox      (SQL_CB_CLOSE);//- Access        (SQL_CB_PRESERVE);//- MySQL

    SQL_DATA_SOURCE_READ_ONLY,
    SQL_INTEGRITY,  // - Access, MySQL
    SQL_NEED_LONG_DATA_LEN:
      SetInfoChar('N');

    SQL_PROCEDURES:
//      SetInfoChar('N');// - MySQL
//      SetInfoChar('Y');// - Access
      SetInfoChar('N');// - Paradox

    SQL_ACCESSIBLE_PROCEDURES:
//      SetInfoChar('N');// - MySql
      SetInfoChar('N');// - Paradox
//      SetInfoChar('Y');// - Access

//    SQL_MAX_COLUMNS_IN_TABLE,
//      SetSmallInt(0);

    SQL_MAX_COLUMNS_IN_TABLE:
      SetSmallInt(32767); // 2147483647
    SQL_MAX_COLUMNS_IN_INDEX:
      SetSmallInt(32767); // 2147483647

    SQL_MAX_COLUMNS_IN_ORDER_BY,
    SQL_MAX_COLUMNS_IN_SELECT,
    SQL_MAX_COLUMNS_IN_GROUP_BY:
// 0 - MySQL ,   10 - Access
      SetSmallInt(32767); // 2147483647 - Right value

    SQL_NULL_COLLATION:
      SetSmallInt(SQL_NC_LOW);// - Access       (SQL_NC_START); // - MySql
    SQL_NON_NULLABLE_COLUMNS:
      SetSmallInt(SQL_NNC_NULL);//- Access

    SQL_ACCESSIBLE_TABLES:
      SetInfoChar('N'); // Abs
//      SetInfoChar('Y'); // !***! - Access, MySQL

    SQL_ORDER_BY_COLUMNS_IN_SELECT:
      SetInfoChar('N');

    SQL_MULT_RESULT_SETS:
      SetInfoChar('N'); // - Access
//      SetInfoChar('Y'); // MySQL
//      SetInfoChar('Y'); // - Access

    SQL_DESCRIBE_PARAMETER,
    SQL_ROW_UPDATES:
      SetInfoChar('Y');
    SQL_TXN_CAPABLE: // Transaction Capabilities: DDL and DML support
      SetSmallInt(SQL_TC_NONE);// Paradox    (SQL_TC_ALL);//- Access        (SQL_TC_NONE);//- MySQL

    SQL_MAX_PROCEDURE_NAME_LEN:
      SetSmallInt(0);
    SQL_MAX_SCHEMA_NAME_LEN,
    SQL_MAX_CATALOG_NAME_LEN,
    SQL_MAX_COLUMN_NAME_LEN,
    SQL_MAX_IDENTIFIER_LEN,
    SQL_MAX_TABLE_NAME_LEN:
      SetSmallInt(MAX_IDENTIFIER_LENGTH);

    SQL_CATALOG_NAME,
    SQL_COLUMN_ALIAS,
    SQL_EXPRESSIONS_IN_ORDERBY,
    SQL_LIKE_ESCAPE_CLAUSE, // NOT - Access
    SQL_OUTER_JOINS:
      SetInfoChar('Y');

    SQL_MULTIPLE_ACTIVE_TXN:
      SetInfoChar('N'); // Paradox
//      SetInfoChar('Y'); // Access

    SQL_MAX_ROW_SIZE_INCLUDES_LONG:
//      SetInfoChar('Y'); // - MySQL
      SetInfoChar('N'); // - Access

    SQL_STRING_FUNCTIONS:
      SetInteger(
       SQL_FN_STR_CONCAT + SQL_FN_STR_INSERT +
       SQL_FN_STR_LEFT + SQL_FN_STR_LTRIM + SQL_FN_STR_LENGTH +
       SQL_FN_STR_LOCATE + SQL_FN_STR_LCASE + SQL_FN_STR_REPEAT +
       SQL_FN_STR_REPLACE + SQL_FN_STR_RIGHT + SQL_FN_STR_RTRIM +
       SQL_FN_STR_SUBSTRING + SQL_FN_STR_UCASE + SQL_FN_STR_ASCII +
       SQL_FN_STR_CHAR + SQL_FN_STR_LOCATE_2 + SQL_FN_STR_SOUNDEX +
       SQL_FN_STR_SPACE);

  SQL_POS_OPERATIONS:
      SetInteger(
            SQL_POS_POSITION +
            SQL_POS_UPDATE  +
            SQL_POS_DELETE +
            SQL_POS_ADD +
            SQL_POS_REFRESH +
                       0);

    SQL_PARAM_ARRAY_ROW_COUNTS:
      SetSmallInt(SQL_PARC_NO_BATCH); // only one row is available for SQLBindParameter
    SQL_PARAM_ARRAY_SELECTS:
      SetSmallInt(SQL_PAS_NO_SELECT); // the driver does not allow a result set-generating statement to be executed with an array of parameters in SQLBindParameter
// Non supported options:
    SQL_CONVERT_FUNCTIONS,
    SQL_CONVERT_WCHAR,
    SQL_CONVERT_WVARCHAR,
    SQL_CONVERT_WLONGVARCHAR,
    SQL_CREATE_ASSERTION,
    SQL_CREATE_CHARACTER_SET,
    SQL_CREATE_COLLATION,
    SQL_CREATE_DOMAIN,
    SQL_CREATE_SCHEMA,
    SQL_CREATE_TRANSLATION,
    SQL_CREATE_VIEW,
    SQL_DROP_ASSERTION,
    SQL_DROP_CHARACTER_SET,
    SQL_DROP_COLLATION,
    SQL_DROP_DOMAIN,
    SQL_DROP_SCHEMA,
    SQL_DROP_TRANSLATION,
    SQL_DROP_VIEW,
    SQL_KEYSET_CURSOR_ATTRIBUTES1,
    SQL_KEYSET_CURSOR_ATTRIBUTES2,
    SQL_INFO_SCHEMA_VIEWS,
    SQL_SCHEMA_USAGE,   // Checked
    SQL_SQL92_FOREIGN_KEY_DELETE_RULE,
    SQL_SQL92_FOREIGN_KEY_UPDATE_RULE,
    SQL_SQL92_NUMERIC_VALUE_FUNCTIONS,
    SQL_SQL92_PREDICATES,
    SQL_SQL92_VALUE_EXPRESSIONS,
    SQL_SUBQUERIES,    // SQL_SQ_COMPARISON | SQL_SQ_EXISTS | SQL_SQ_IN | SQL_SQ_QUANTIFIED | SQL_SQ_CORRELATED_SUBQUERIES - Access
    SQL_TIMEDATE_ADD_INTERVALS,
    SQL_TIMEDATE_DIFF_INTERVALS,
//    SQL_UNION,
    SQL_LOCK_TYPES:
      SetInteger(0);
    SQL_USER_NAME:
      SetInfoStr('user');

    SQL_GETDATA_EXTENSIONS:
      SetInteger(SQL_GD_ANY_COLUMN + SQL_GD_ANY_ORDER + SQL_GD_BOUND +
      SQL_GD_BLOCK + // Paradox, Access
      0);

    SQL_STATIC_SENSITIVITY:
      SetInteger(SQL_SS_ADDITIONS + SQL_SS_DELETIONS + SQL_SS_UPDATES);

    SQL_TXN_ISOLATION_OPTION:
      SetInteger(
//                  SQL_TXN_READ_COMMITTED +
//                  SQL_TXN_READ_UNCOMMITTED +
//                  SQL_TXN_REPEATABLE_READ +
//                  SQL_TXN_SERIALIZABLE +
                  0);
{
// Pradox - not defined
    SQL_BOOKMARK_PERSISTENCE:
      SetInteger(0);
}
    SQL_SCROLL_OPTIONS:
      SetInteger(
          SQL_SO_FORWARD_ONLY +
          SQL_SO_KEYSET_DRIVEN + //  YES - Access
          SQL_SO_DYNAMIC +
          SQL_SO_MIXED +
          SQL_SO_STATIC +         // YES - Access
                0);

    SQL_SCROLL_CONCURRENCY: // as Paradox
      SetInteger(
                  SQL_SCCO_READ_ONLY  +
//                  SQL_SCCO_LOCK       +
//                  SQL_SCCO_OPT_ROWVER +
                  SQL_SCCO_OPT_VALUES +
//                 SQL_SS_ADDITIONS +
//                 SQL_SS_DELETIONS +
//                 SQL_SS_UPDATES +
                 0);

    SQL_FETCH_DIRECTION:
//      SetInteger(SQL_FD_FETCH_NEXT);
      SetInteger(
              SQL_FD_FETCH_NEXT +
              SQL_FD_FETCH_FIRST +
              SQL_FD_FETCH_LAST +
              SQL_FD_FETCH_PRIOR +
              SQL_FD_FETCH_ABSOLUTE +
              SQL_FD_FETCH_RELATIVE+
//              SQL_FD_FETCH_BOOKMARK + // Paradox, Access
                 0);
    SQL_CATALOG_TERM:
      SetInfoStr('DATABASE');//- Access
    SQL_CATALOG_USAGE:
      SetInteger(0);
{
      SetInteger(SQL_QU_DML_STATEMENTS +
                      SQL_QU_TABLE_DEFINITION +
                      SQL_QU_INDEX_DEFINITION +
                      SQL_QU_PRIVILEGE_DEFINITION);
}

    SQL_PROCEDURE_TERM:
      SetInfoStr('QUERY');//- Access

    SQL_OWNER_TERM:
      SetInfoStr('');//- Access

    SQL_TABLE_TERM:
      SetInfoStr('TABLE');//- Access

    SQL_SPECIAL_CHARACTERS:
      SetInfoStr(sqlSpecChars);

//BREAK EXCELL!!!
    SQL_QUOTED_IDENTIFIER_CASE:
      SetSmallInt(SQL_IC_MIXED);
//BREAK EXCELL!!!

    SQL_IDENTIFIER_CASE:
      SetSmallInt(SQL_IC_MIXED); //- MySQL     SQL_IC_SENSITIVE - Access
    SQL_IDENTIFIER_QUOTE_CHAR:
      SetInfoChar(IDENTIFIER_QUOTE);
    SQL_QUALIFIER_NAME_SEPARATOR:
      SetInfoChar(' ');// does not support multipart names            ('.');//- Access

    SQL_CONCAT_NULL_BEHAVIOR:
      SetSmallInt(SQL_CB_NON_NULL);//- Access     (SQL_CB_NULL);//- MySQL
    SQL_GROUP_BY:
      SetSmallInt(SQL_GB_GROUP_BY_CONTAINS_SELECT);//- Access             (SQL_GB_NO_RELATION);//- MySQL
    SQL_MAX_INDEX_SIZE:
      SetInteger(2147483647); // 255 - Access
    SQL_MAX_ROW_SIZE:
      SetInteger(2147483647); // 4052 - Access
    SQL_MAX_TABLES_IN_SELECT:
      SetSmallInt(32767);//(65535); // Correct Value - Unsigned! // 16 - Access

    SQL_OJ_CAPABILITIES:
      SetInteger(
          SQL_OJ_LEFT +
          SQL_OJ_RIGHT +
          SQL_OJ_FULL + // not - Access
          SQL_OJ_NESTED + // not - Access
          SQL_OJ_NOT_ORDERED +
//          SQL_OJ_INNER +
          SQL_OJ_ALL_COMPARISON_OPS
                  );
    SQL_NUMERIC_FUNCTIONS:
      SetInteger(0);
{
                (
          SQL_FN_NUM_ABS +
          SQL_FN_NUM_ACOS +
          SQL_FN_NUM_ASIN +
          SQL_FN_NUM_ATAN  +
          SQL_FN_NUM_ATAN2  +
          SQL_FN_NUM_CEILING +
          SQL_FN_NUM_COS +
          SQL_FN_NUM_COT +
          SQL_FN_NUM_EXP +
          SQL_FN_NUM_FLOOR +
          SQL_FN_NUM_LOG +
          SQL_FN_NUM_MOD +
          SQL_FN_NUM_SIGN +
          SQL_FN_NUM_SIN +
          SQL_FN_NUM_SQRT +
          SQL_FN_NUM_TAN +
          SQL_FN_NUM_PI +
          SQL_FN_NUM_RAND +
          SQL_FN_NUM_DEGREES +
          SQL_FN_NUM_LOG10 +
          SQL_FN_NUM_POWER +
          SQL_FN_NUM_RADIANS +
          SQL_FN_NUM_ROUND +
          SQL_FN_NUM_TRUNCATE
                  );
}

    SQL_SYSTEM_FUNCTIONS:
      SetInteger(
//             SQL_FN_SYS_DBNAME + // Not - Access
//             SQL_FN_SYS_IFNULL + // Not - Access
//             SQL_FN_SYS_USERNAME +
                  0);
    SQL_TIMEDATE_FUNCTIONS:
      SetInteger(
            SQL_FN_TD_NOW           +
            SQL_FN_TD_CURDATE       +
//            SQL_FN_TD_DAYOFMONTH    +
//            SQL_FN_TD_DAYOFWEEK     +
//            SQL_FN_TD_DAYOFYEAR     +
//            SQL_FN_TD_MONTH         +
//            SQL_FN_TD_QUARTER       +
//            SQL_FN_TD_WEEK          +
//            SQL_FN_TD_YEAR          +
            SQL_FN_TD_CURTIME       +
//            SQL_FN_TD_HOUR          +
//            SQL_FN_TD_MINUTE        +
//            SQL_FN_TD_SECOND        +
//            SQL_FN_TD_TIMESTAMPADD  +
//            SQL_FN_TD_TIMESTAMPDIFF +
//            SQL_FN_TD_DAYNAME       +
//            SQL_FN_TD_MONTHNAME     +
{
          //#if (ODBCVER >= = $0300)
            SQL_FN_TD_CURRENT_DATE  +
            SQL_FN_TD_CURRENT_TIME  +
            SQL_FN_TD_CURRENT_TIMESTAMP	+
            SQL_FN_TD_EXTRACT       +
}

                  0);

    SQL_ALTER_TABLE:
      SetInteger(SQL_AT_ADD_COLUMN+SQL_AT_DROP_COLUMN);

    SQL_FILE_USAGE:
      SetSmallInt(SQL_FILE_NOT_SUPPORTED);
//      SetSmallInt(SQL_FILE_QUALIFIER); // - Access

    SQL_DEFAULT_TXN_ISOLATION:
      SetInteger(DEFAULT_TXN_ISOLATION);
    SQL_POSITIONED_STATEMENTS:
      SetInteger(
//            SQL_PS_POSITIONED_DELETE +
//            SQL_PS_POSITIONED_UPDATE +
//            SQL_PS_SELECT_FOR_UPDATE +
                 0);
    SQL_CATALOG_LOCATION:
      SetSmallInt(SQL_CL_START);

    SQL_ODBC_SAG_CLI_CONFORMANCE:
      SetSmallInt(SQL_OSCC_COMPLIANT);

    SQL_ODBC_SQL_CONFORMANCE:
      SetSmallInt(SQL_OSC_CORE);//(SQL_OSC_MINIMUM);// - Access (SQL_OSC_CORE);
    SQL_ODBC_API_CONFORMANCE:
      SetSmallInt(
//            SQL_OAC_NONE       //core level
            SQL_OAC_LEVEL1
//            SQL_OAC_LEVEL2
                  );
  else
//    pSmallInt(Info)^:=0; // not supported
    Result:=SQL_ERROR; // not released
WriteToLog('>>> SQLGetInfo: Unsupported InfoType='+IntToStr(InfoType)+'!');
    Exit;
  end;

  if Integer(Info)=SQL_NULL_HANDLE then
    begin
WriteToLog('    InfoValuePtr=SQL_NULL_HANDLE');
      if Integer(InfoLength)=SQL_NULL_HANDLE
        then Result:=SQL_ERROR
        else Result:=SQL_SUCCESS_WITH_INFO;
    end;

  if Integer(InfoLength)<>SQL_NULL_HANDLE
    then
      if  (InfoLength^<>2)
      and (InfoLength^<>4)
        then
          if BufferLength<=InfoLength^ then
            begin
              Result:=SQL_SUCCESS_WITH_INFO;
              if BufferLength>0 then InfoLength^:=BufferLength-1; // truncated data, else specify the length for new buffer
WriteToLog('    truncated data');
            end;

WriteToLog('### SQLGetInfo');
end;

///// SQLGetTypeInfo /////

procedure InitTypeInfo(Stmt:PStmt);
// Used by SQLGetTypeInfo
// and SQLDescribeCol (when it called before SQLGetTypeInfo)
// if the Stmt.TypeInfo does not exist
const
  MaxTypeLength = 100;
 begin
WriteToLog(' >> InitTypeInfo: data preparing...');
WriteToLog('    Init @TypeInfo='+IntToHex(Integer(Stmt.TypeInfo),6));
  Stmt.TypeInfo.TableName := 'TypeInfo';
  Stmt.TypeInfo.InMemory := True;
  Stmt.TypeInfo.FieldDefs.Add('TYPE_NAME',ftString,MaxTypeLength,True);
  Stmt.TypeInfo.FieldDefs.Add('DATA_TYPE',ftSmallInt,0,True);
//  Stmt.TypeInfo.FieldDefs.Add('COLUMN_SIZE',ftInteger,0);  // v.3.xx
  Stmt.TypeInfo.FieldDefs.Add('PRECISION',ftInteger,0);    // v.2.xx
  Stmt.TypeInfo.FieldDefs.Add('LITERAL_PREFIX',ftString,10);
  Stmt.TypeInfo.FieldDefs.Add('LITERAL_SUFFIX',ftString,10);
  Stmt.TypeInfo.FieldDefs.Add('CREATE_PARAMS',ftWideString,100);
  Stmt.TypeInfo.FieldDefs.Add('NULLABLE',ftSmallInt,0,True);
  Stmt.TypeInfo.FieldDefs.Add('CASE_SENSITIVE',ftSmallInt,0,True);
  Stmt.TypeInfo.FieldDefs.Add('SEARCHABLE',ftSmallInt,0,True);
  Stmt.TypeInfo.FieldDefs.Add('UNSIGNED_ATTRIBUTE',ftSmallInt,0);
//  Stmt.TypeInfo.FieldDefs.Add('FIXED_PREC_SCALE',ftSmallInt,0,True); // v.3.xx
  Stmt.TypeInfo.FieldDefs.Add('MONEY',ftSmallInt,0,True);              // v.2.xx
//  Stmt.TypeInfo.FieldDefs.Add('AUTO_UNIQUE_VALUE',ftSmallInt,0);  // v.3.xx
  Stmt.TypeInfo.FieldDefs.Add('AUTO_INCREMENT',ftSmallInt,0);       // v.2.xx
  Stmt.TypeInfo.FieldDefs.Add('LOCAL_TYPE_NAME',ftWideString,100);
  Stmt.TypeInfo.FieldDefs.Add('MINIMUM_SCALE',ftSmallInt,0);
  Stmt.TypeInfo.FieldDefs.Add('MAXIMUM_SCALE',ftSmallInt,0);
//  Stmt.TypeInfo.FieldDefs.Add('SQL_DATATYPE',ftSmallInt,0,True);   // v.3.xx
//  Stmt.TypeInfo.FieldDefs.Add('SQL_DATETIME_SUB',ftSmallInt,0);    // v.3.xx
  Stmt.TypeInfo.FieldDefs.Add('NUM_PREC_RADIX',ftInteger,0);       // v.3.xx - needed for SQLColumns
//  Stmt.TypeInfo.FieldDefs.Add('INTERVAL_PRECISION',ftSmallInt,0);  // v.3.xx
  Stmt.TypeInfo.IndexDefs.Add('index1','DATA_TYPE;TYPE_NAME',[ixCaseInsensitive]);
  Stmt.TypeInfo.InMemory := True;
  Stmt.TypeInfo.CreateTable;
  Stmt.TypeInfo.Active := True;

// STRING = SQL_CHAR
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'STRING()';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_CHAR;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 2147483647;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_TRUE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_SEARCHABLE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := NULL;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// WIDESTRING = SQL_WCHAR
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'WIDESTRING()';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_CHAR;//SQL_WCHAR; - does not work in BDE
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 2147483647;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_TRUE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_SEARCHABLE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := NULL;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// FLOAT = SQL_DOUBLE
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'FLOAT';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_DOUBLE;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 15;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 15;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
//  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 1;
//  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 15;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// INTEGER = SQL_INTEGER
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'INTEGER';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_INTEGER;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 10;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 10;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := SQL_FALSE;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 0;
  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 0;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// SMALLINT = SQL_SMALLINT
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'SMALLINT';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_TINYINT; // !***! SQL_SMALLINT;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 5;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 5;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := SQL_FALSE;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 0;
  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 0;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// WORD = SQL_SMALLINT - unsigned
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'WORD';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_SMALLINT;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 5;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 5;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := SQL_FALSE;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 0;
  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 0;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// LARGEINT = SQL_BIGINT - signed
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'LARGEINT';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_BIGINT;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 19;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 19;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// LARGEINT = SQL_BIGINT - unsigned
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'LARGEINT';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_BIGINT;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 19;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 20;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// DATE = SQL_DATE
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'DATE';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_DATE;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := ;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 100;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := NULL;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// TIME = SQL_TIME
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'TIME()';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_TIME;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := ;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 30;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'precision';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := NULL;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 0;
  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 0;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// DATETIME = SQL_TIMESTAMP
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'DATETIME()';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_TIMESTAMP;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := ;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 100;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'precision';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := NULL;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 3;
  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 3;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// BYTES = SQL_BINARY
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'BYTES()';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_BINARY;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 2147483647;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_UNSEARCHABLE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// AUTOINC = SQL_INTEGER
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'AUTOINC';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_INTEGER;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 10;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 10;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := SQL_TRUE;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// CURRENCY = SQL_DOUBLE
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'CURRENCY';
//  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_NUMERIC; // Access - not worked in BDE level1
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_DOUBLE;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 15;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 19;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_TRUE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := SQL_FALSE;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 4;
  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 19; // Access - 4
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// LOGICAL = BIT
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'BOOLEAN';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_BIT;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 1;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 1;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_LIKE_ONLY;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  2;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// MEMO = SQL_VARCHAR
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'MEMO';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_LONGVARCHAR;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 10;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_UNSEARCHABLE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// FMTMEMO = SQL_LONGVARCHAR
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'FMTMEMO';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_LONGVARCHAR;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 10;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_UNSEARCHABLE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// GRAPHIC = SQL_LONGVARBINARY
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'GRAPHIC';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_LONGVARBINARY;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 10;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_UNSEARCHABLE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// BLOB = SQL_LONGVARBINARY
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'BLOB';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_LONGVARBINARY;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 10;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 2147483647;    // v.2.xx
  Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := CONSTANT_QUOTE;
  Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := 'length';
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_UNSEARCHABLE;
  //Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_TRUE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
  //Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := ;
  //Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := ;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  NULL;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

// BCD = SQL_DOUBLE
  Stmt.TypeInfo.Insert;
  Stmt.TypeInfo.FieldByName('TYPE_NAME').AsString := 'BCD';
  Stmt.TypeInfo.FieldByName('DATA_TYPE').AsInteger := SQL_DOUBLE;
//  Stmt.TypeInfo.FieldByName('COLUMN_SIZE').AsInteger := 20;     // v.3.xx
  Stmt.TypeInfo.FieldByName('PRECISION').AsInteger := 20;    // v.2.xx
  //Stmt.TypeInfo.FieldByName('LITERAL_PREFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('LITERAL_SUFFIX').AsString := NULL;
  //Stmt.TypeInfo.FieldByName('CREATE_PARAMS').AsString := NULL;
  Stmt.TypeInfo.FieldByName('NULLABLE').AsInteger := SQL_NULLABLE;
  Stmt.TypeInfo.FieldByName('CASE_SENSITIVE').AsInteger := SQL_FALSE;
  Stmt.TypeInfo.FieldByName('SEARCHABLE').AsInteger := SQL_ALL_EXCEPT_LIKE;
  Stmt.TypeInfo.FieldByName('UNSIGNED_ATTRIBUTE').AsInteger := SQL_FALSE;
//  Stmt.TypeInfo.FieldByName('FIXED_PREC_SCALE').AsInteger := SQL_FALSE; // v.3.xx
  Stmt.TypeInfo.FieldByName('MONEY').AsInteger := SQL_FALSE;              // v.2.xx
//  Stmt.TypeInfo.FieldByName('AUTO_UNIQUE_VALUE').AsInteger := ;         // v.3.xx
  //Stmt.TypeInfo.FieldByName('AUTO_INCREMENT').AsInteger := ;       // v.2.xx
  //Stmt.TypeInfo.FieldByName('LOCAL_TYPE_NAME').AsString := ;
//  Stmt.TypeInfo.FieldByName('MINIMUM_SCALE').AsInteger := 1;
//  Stmt.TypeInfo.FieldByName('MAXIMUM_SCALE').AsInteger := 15;
//  Stmt.TypeInfo.FieldByName('SQL_DATATYPE').AsInteger := SQL_CHAR;      // v.3.xx
//  Stmt.TypeInfo.FieldByName('SQL_DATETIME_SUB').AsInteger := NULL;      // v.3.xx
  Stmt.TypeInfo.FieldByName('NUM_PREC_RADIX').AsInteger :=  10;       // v.3.xx
//  Stmt.TypeInfo.FieldByName('INTERVAL_PRECISION').AsInteger :=  NULL;   // v.3.xx
  Stmt.TypeInfo.Post;

WriteToLog(' ## InitTypeInfo: data prepared');
  end;

Function SQLGetTypeInfo  (
            Stmt:PStmt;//HSTMT;
        		DataType:SWORD
                          ): RETCODE; stdcall;
{
var TypeInfo: TEasyTable;
    p: pointer;
}
Procedure SetFilter(Filter:String);
  begin
{
    Stmt.TypeInfo.Filter := Filter;
    Stmt.TypeInfo.Filtered := True;
}
WriteToLog('    SetFilter called');
WriteToLog(Stmt.Result.CurrentVersion);
  Stmt.Result.Active:=False;

  if not Stmt.Result.InMemory then
    Stmt.Result.InMemory:=True;
{
  Stmt.Result.Active:=False;
WriteToLog('    Old data erased');
  Stmt.Result.SQL.Text:='select * from memory TypeInfo'+Filter;
WriteToLog('    Filter='+Stmt.Result.SQL.Text);
      try
  Stmt.Result.Active:=True;
      except
       on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end;
WriteToLog('    RecordCount='+IntToStr(Stmt.Result.RecordCount));

WriteToLog('    SetFilter doubled');
}
  Stmt.Result.Active:=False;
WriteToLog('    Old data erased');
  Stmt.Result.SQL.Text:='select '+
    'TYPE_NAME, '+
    'DATA_TYPE, '+
//    'COLUMN_SIZE, '+  // v.3.xx
    '[PRECISION], '+ // v.2.xx
    'LITERAL_PREFIX, '+
    'LITERAL_SUFFIX, '+
    'CREATE_PARAMS, '+
    'NULLABLE, '+
    'CASE_SENSITIVE, '+
    'SEARCHABLE, '+
    'UNSIGNED_ATTRIBUTE, '+
//    'FIXED_PREC_SCALE, '+ // v.3.xx
    'MONEY, '+              // v.2.xx
//    'AUTO_UNIQUE_VALUE, '+  // v.3.xx
    'AUTO_INCREMENT, '+       // v.2.xx
    'LOCAL_TYPE_NAME, '+
    'MINIMUM_SCALE, '+
    'MAXIMUM_SCALE'+//, '+
//    'SQL_DATATYPE, '+   // v.3.xx
//    'SQL_DATETIME_SUB, '+    // v.3.xx
//    'NUM_PREC_RADIX, '+       // v.3.xx
//    'INTERVAL_PRECISION, '+  // v.3.xx
  ' from memory TypeInfo'+Filter;
WriteToLog('    Filter='+Stmt.Result.SQL.Text);
      try
  Stmt.Result.Active:=True;
      except
       on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end;
WriteToLog('    RecordCount='+IntToStr(Stmt.Result.RecordCount));
  Stmt.Result.FindFirst;
  Stmt.FreshResult:=True;
  end;
begin // SQLGetTypeInfo
WriteToLog('>>> SQLGetTypeInfo about '+IntToStr(DataType));
  if not Stmt.TypeInfo.Exists then InitTypeInfo(Stmt);
WriteToLog('    SQLGetTypeInfo: prepare to select DataType '+IntToStr(DataType));
	Result:=SQL_SUCCESS;
  case DataType of
// Full table
    SQL_ALL_TYPES:          SetFilter('');
// Numeric
    SQL_REAL,
    SQL_FLOAT,
    SQL_DOUBLE:             SetFilter(' where DATA_TYPE='+IntToStr(SQL_DOUBLE));
// character strings
    SQL_CHAR,
    SQL_VARCHAR,
    SQL_LONGVARCHAR,
    SQL_WCHAR,
    SQL_WVARCHAR,
    SQL_WLONGVARCHAR,
// Exact Numeric
    SQL_DECIMAL,
    SQL_NUMERIC,
    SQL_SMALLINT,
    SQL_BIGINT,
    SQL_INTEGER,
    SQL_TINYINT, // needed for MSAccess - not available
// single bit binary data -  not available
    SQL_BIT,
// binary data -  not available
    SQL_BINARY,
    SQL_VARBINARY,
    SQL_LONGVARBINARY,
// Date-Time v.2.xx
    SQL_DATE,
    SQL_TIME,
    SQL_TIMESTAMP,
{
// Date-Time v.3.xx
    SQL_TYPE_DATE,
    SQL_TYPE_TIME,
    SQL_TYPE_TIMESTAMP,
}
{
don't know what is this
-----------------------
    SQL_TYPE_UTCDATETIME,
    SQL_TYPE_UTCTIME,
}

// Interval data types -  not available
    SQL_INTERVAL_MONTH,
    SQL_INTERVAL_YEAR,
    SQL_INTERVAL_YEAR_TO_MONTH,
    SQL_INTERVAL_DAY,
    SQL_INTERVAL_HOUR,
    SQL_INTERVAL_MINUTE,
    SQL_INTERVAL_SECOND,
    SQL_INTERVAL_DAY_TO_HOUR,
    SQL_INTERVAL_DAY_TO_MINUTE,
    SQL_INTERVAL_DAY_TO_SECOND,
    SQL_INTERVAL_HOUR_TO_MINUTE,
    SQL_INTERVAL_HOUR_TO_SECOND,
    SQL_INTERVAL_MINUTE_TO_SECOND,
// Fixed length Globally Unique Identifier
    SQL_GUID
    :                       SetFilter(' where DATA_TYPE='+IntToStr(DataType));

  else
WriteToLog('    SQLGetTypeInfo: Unknown datatype: '+IntToStr(DataType));
  	Result:=SQL_ERROR;
  end;

{
WriteToLog('    SQLGetTypeInfo: preparing to out...');
  Move(StatementHandle,p,4);
  Move(Pointer(TypeInfo),p^,4);
  StatementHandle:=StatementHandle+4;
  Move(StatementHandle,p,4);
  Move(Pointer(TypeInfo),p^,4);
WriteToLog('    SQLGetTypeInfo: data outed');
}

{
  Stmt.TypeInfo.AddIndex('index2','field1;field2',[],'field2','field1');
//                                                dec     Insens
  Stmt.TypeInfo.Filtered := False;
}

{
  Stmt.TypeInfo.First;
  while not Stmt.TypeInfo.EOF do
   begin
    //:=Stmt.TypeInfo.FieldByName('field1').AsString;
    Stmt.TypeInfo.Next;
   end;
}
WriteToLog('### SQLGetTypeInfo finished');
end;  // SQLGetTypeInfo

///// SQLTables /////

Function SQLTables  (
             Stmt:pStmt;//HSTMT;
		         CatalogName:UCHAR;
        		 CatalogLength:SWORD;
        		 SchemaName:UCHAR;
        		 SchemaLength:SWORD;
        		 TableName:UCHAR;
        		 TableLength:SWORD;
        		 TableType:UCHAR;
        		 TypeLength:SWORD
                         ): RETCODE; stdcall;
var
  EDB:TEasyDatabase;
  TablesList:TStringList;
  i:Integer;
  str:String;
  MSQuery : Boolean;
begin
WriteToLog('>>> SQLTables called');

if Integer(CatalogName)=SQL_NULL_HANDLE then WriteToLog('    CatalogName=0') else WriteToLog('    CatalogName="'+CatalogName+'"');
WriteToLog('    CatalogLength='+IntToStr(CatalogLength));
if Integer(SchemaName)=SQL_NULL_HANDLE then WriteToLog('    SchemaName=0') else WriteToLog('    SchemaName="'+SchemaName+'"');
WriteToLog('    SchemaLength='+IntToStr(SchemaLength));
if Integer(TableName)=SQL_NULL_HANDLE then WriteToLog('    TableName=0') else WriteToLog('    TableName="'+TableName+'"');
WriteToLog('    TableLength='+IntToStr(TableLength));
if Integer(TableType)=SQL_NULL_HANDLE then WriteToLog('    TableType=0') else WriteToLog('    TableType="'+TableType+'"');
WriteToLog('    TypeLength='+IntToStr(TypeLength));

  MSQuery := False;
{
  if CatalogName='' then
  if CatalogLength=0 then
}
  if Integer(SchemaName)=SQL_NULL_HANDLE then
  if Integer(SchemaLength)=SQL_NTS then
  if Integer(TableName)=SQL_NULL_HANDLE then
  if Integer(TableLength)=SQL_NTS then
  if TableType='''TABLE'',''SYNONYM''' then
  if TypeLength=17 then
    MSQuery := True;

if MSQuery then
WriteToLog('    MSQuery!');

  // Create Result table
WriteToLog('    Database.create');
  EDB := TEasyDatabase.Create(Nil);
  EDB.DatabaseName := 'TempOpenDB1';
WriteToLog('    TStringList.Create');
  TablesList:=TStringList.Create;
WriteToLog('    DatabaseFileName');
  if Integer(CatalogName)=SQL_NULL_HANDLE
    then EDB.DatabaseFileName := Stmt.Database
    else
      begin
        if CatalogLength = SQL_NTS
          then str := CatalogName
          else str := Copy(CatalogName,1,CatalogLength);
        str := StringReplace(str,'''',' ',[rfReplaceAll]);
        str := StringReplace(str,'"',' ',[rfReplaceAll]);
        str := StringReplace(str,'ALL_DEFAULT','',[rfReplaceAll]); // For VS 2003 Query Builder
        str := Trim(str);
        if ( str = ''  )
        or ( str = '%' )
          then EDB.DatabaseFileName := Stmt.Database
          else EDB.DatabaseFileName := str;
      end;
WriteToLog('    "'+EDB.DatabaseFileName+'"');

WriteToLog('    Result='+IntToStr(Integer(Pointer(Stmt.Result))));
if Stmt.Result.InMemory then
WriteToLog('    Result.InMemory=True')
else
WriteToLog('    Active=False...');
  Stmt.Result.Active:=False;
WriteToLog('    Result.InMemory=False');
WriteToLog('    InMemory=True...');
  if not Stmt.Result.InMemory then
    Stmt.Result.InMemory:=True;
WriteToLog('    Drop table...');
  Stmt.Result.SQL.Text := 'drop table Tables';

    try
  Stmt.Result.ExecSQL;
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    Create Table');
  Stmt.Result.SQL.Text :=
    'create table Tables('+
    'TABLE_QUALIFIER STRING('+IntToStr(_MAX_PATH)+'),'+
    'TABLE_OWNER STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'TABLE_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'TABLE_TYPE STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'REMARKS STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+')'+
    ')'; //v.2
//  'create table Tables(TABLE_CAT STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),TABLE_SCHEM STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),TABLE_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),TABLE_TYPE STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),REMARKS STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'))'; //v.3
    try
  Stmt.Result.ExecSQL;
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    GetTablesList');
    try
  EDB.Open;
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    DB opened');
    try
  EDB.GetTablesList(TablesList);
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    OK');
  for i:=0 to TablesList.Count - 1 do
    begin
WriteToLog('    insert '+IntToStr(i)+' = '+TablesList[i]);
      Stmt.Result.SQL.Text :=
        'insert into Tables(TABLE_QUALIFIER,TABLE_NAME,TABLE_TYPE';
      if MSQuery then
      Stmt.Result.SQL.Text := Stmt.Result.SQL.Text+
        ',TABLE_OWNER';
      Stmt.Result.SQL.Text := Stmt.Result.SQL.Text+
        ') values('+
        CONSTANT_QUOTE+Stmt.Database+CONSTANT_QUOTE+','+
        CONSTANT_QUOTE+TablesList[i]+CONSTANT_QUOTE+','+
        CONSTANT_QUOTE+'TABLE'+CONSTANT_QUOTE;
      if MSQuery then
      Stmt.Result.SQL.Text := Stmt.Result.SQL.Text+
        ','+CONSTANT_QUOTE+'ALL_DEFAULT'+CONSTANT_QUOTE;
      Stmt.Result.SQL.Text := Stmt.Result.SQL.Text+
        ')';
WriteToLog('    execute:'+Stmt.Result.SQL.Text);
      try
        Stmt.Result.ExecSQL;
      except
      on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
      end;
    end;
  EDB.Free;
  TablesList.Free;

  // Select using the TableName mask
  if Integer(TableName)<>SQL_NULL_HANDLE
    then
      begin
        if TableLength = SQL_NTS
          then str:=TableName//StrCopy(pChar(str),TableName)
          else str := Copy(TableName,1,TableLength);
        str := StringReplace(str,'''',' ',[rfReplaceAll]);
        str := StringReplace(str,'"',' ',[rfReplaceAll]);
        str := Trim(str);
WriteToLog('    str='+str);
        if str='' then str:='%';
        str := 'select * from memory Tables where (TABLE_NAME like '+CONSTANT_QUOTE+str+CONSTANT_QUOTE+')'
      end
    else
        str := 'select * from memory Tables where (TABLE_NAME like '+CONSTANT_QUOTE+'%'+CONSTANT_QUOTE+')';
WriteToLog('    str='+str);
  Stmt.Result.SQL.Text := str;
WriteToLog('    SQL.Text='+Stmt.Result.SQL.Text);
  if Integer(TableType)=SQL_NULL_HANDLE
    then
      str:=''
    else
      if TypeLength = SQL_NTS
          then str:=TableType//StrCopy(pChar(str),TableType)
          else str := Copy(TableType,1,TableLength);
WriteToLog('    str='+str);
{
  str := StringReplace(str,'''',' ',[rfReplaceAll]);
  str := StringReplace(str,'"',' ',[rfReplaceAll]);
  str := StringReplace(str,'VIEW',' ',[rfReplaceAll]);
  str := StringReplace(str,',',' ',[rfReplaceAll]);
  str := Trim(str);
}
  str := StringReplace(str,'''','',[rfReplaceAll]);
  str := StringReplace(str,'"','',[rfReplaceAll]);
  str := StringReplace(str,'VIEW','',[rfReplaceAll]);           // not supported
  str := StringReplace(str,'SYSTEM TABLE','',[rfReplaceAll]);   // not supported
  str := StringReplace(str,'ALIAS','',[rfReplaceAll]);          // not supported
  str := StringReplace(str,'SYNONYM','',[rfReplaceAll]);        // not supported
  str := StringReplace(str,',','',[rfReplaceAll]);
  str := Trim(str);
  if str='' then str:='%';
  str := ' and (TABLE_TYPE like '+CONSTANT_QUOTE+str+CONSTANT_QUOTE+')';
  Stmt.Result.SQL.Text := Stmt.Result.SQL.Text+str;
WriteToLog('    SQL.Text='+Stmt.Result.SQL.Text);
WriteToLog('    SQL.Active=True');
    try
  Stmt.Result.Active := True;
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    RecordCount='+IntToStr(Stmt.Result.RecordCount));
  Stmt.FreshResult:=True;
WriteToLog('### SQLTables');
	Result:=SQL_SUCCESS;
end;

///// SQLColumns /////

Function SQLColumns(
             Stmt:PStmt;//:HSTMT;
             CatalogName:UCHAR;
             CatalogLength:SWORD;
             SchemaName:UCHAR;
             SchemaLength:SWORD;
             TableName:UCHAR;
             TableLength:SWORD;
             ColumnName:UCHAR;
             ColumnLength:SWORD
                    ): RETCODE; stdcall;
const
  MaxLen=100;
var
{$IFDEF SQLCOLUMNS_TABLE_NOT_FOUND_DEBUG_LOG}
  EDB:TEasyDatabase;
{$ENDIF}
  ET:TEasyTable;
  TablesList:TStringList;
  i,j:Integer;
  str,str2:String;
  pStr:pChar;
  NumericAttributePtr:PInteger;
  ColumnNumber:WORD;
label
  Finish;
begin
	WriteToLog('>>> SQLColumns called');
{$IFDEF SQLCOLUMNS_TABLE_NOT_FOUND_DEBUG_LOG}
WriteToLog('==================================================');
EDB := TEasyDatabase.Create(Nil);
EDB.DatabaseName:='test';
EDB.DatabaseFileName := 'S:\DelphiProjects\_eodbc-test\test.edb';
if EDB.Exists
then WriteToLog('Database test Exists')
else WriteToLog('Database test Not Exists');
if EDB.TableExists('Table123')
then WriteToLog('Table123 Exists')
else WriteToLog('Table123 Not Exists');

if EDB.IsEasyTableDatabaseFile('S:\DelphiProjects\_eodbc-test\test.edb')
then WriteToLog('Database test.edb Exists')
else WriteToLog('Database test.edb Not Exists');
if EDB.TableExists('Table123')
then WriteToLog('Table123 Exists')
else WriteToLog('Table123 Not Exists');
if EDB.TableExists('Table1')
then WriteToLog('Table1 Exists')
else WriteToLog('Table1 Not Exists');
TablesList:=TStringList.Create;

  try
EDB.GetTablesList(TablesList);
  except
  on e: Exception do
    begin
WriteToLog('GetTablesList - Error: ' + e.Message);
    end;
  end;

for i:=0 to TablesList.Count-1 do
begin
WriteToLog('=> Table #'+IntToStr(i)+' = "'+TablesList[i]+'"');
if EDB.TableExists(TablesList[i])
then WriteToLog('=> Table Exists')
else WriteToLog('=> Table Not Exists');
end;

TablesList.Free;
EDB.Free;
WriteToLog('==================================================');
{$ENDIF}

if Integer(CatalogName)=SQL_NULL_HANDLE then WriteToLog('    CatalogName=0') else WriteToLog('    CatalogName="'+CatalogName+'"');
WriteToLog('    CatalogLength='+IntToStr(CatalogLength));
if Integer(SchemaName)=SQL_NULL_HANDLE then WriteToLog('    SchemaName=0') else WriteToLog('    SchemaName="'+SchemaName+'"');
WriteToLog('    SchemaLength='+IntToStr(SchemaLength));
if Integer(TableName)=SQL_NULL_HANDLE then WriteToLog('    TableName=0') else WriteToLog('    TableName="'+TableName+'"');
WriteToLog('    TableLength='+IntToStr(TableLength));
if Integer(ColumnName)=SQL_NULL_HANDLE then WriteToLog('    ColumnName=0') else WriteToLog('    ColumnName="'+ColumnName+'"');
WriteToLog('    ColumnLength='+IntToStr(ColumnLength));

  if not Stmt.TypeInfo.Exists then InitTypeInfo(Stmt);

  Result:=SQLTables( Stmt,CatalogName,CatalogLength,SchemaName,SchemaLength,
                     TableName,TableLength,PChar('TABLE'),6);
  if Result=SQL_ERROR then
    begin
WriteToLog('### SQLColumns: SQLTables returns SQL_ERROR');
      Exit;
    end;

  WriteToLog('    TStringList.Create');
  TablesList:=TStringList.Create;
  while not Stmt.Result.Eof do
    begin
      TablesList.Add(Stmt.Result.FieldByName('TABLE_NAME').AsString);
      Stmt.Result.Next;
    end;

{$IFDEF DEBUG_LOG}
WriteToLog('    Tables Found:');
for i:=0 to TablesList.Count-1 do
WriteToLog('    - '+TablesList[i]);
{$ENDIF}

WriteToLog('    TEasyTable.Create');
    ET := TEasyTable.Create(Nil);
WriteToLog('    DatabaseFileName');
    if Integer(CatalogName)=SQL_NULL_HANDLE
      then ET.DatabaseFileName := Stmt.Database
      else
        if ( Trim(CatalogName)=''  )
        or ( Trim(CatalogName)='%' )
          then ET.DatabaseFileName := Stmt.Database
          else
            if CatalogLength = SQL_NTS
              then ET.DatabaseFileName := CatalogName
              else ET.DatabaseFileName := Copy(CatalogName,1,CatalogLength);
WriteToLog('    "'+ET.DatabaseFileName+'"');

    // Create Result table
WriteToLog('    Active=False');
    Stmt.Result.Active:=False;
WriteToLog('    InMemory');
    Stmt.Result.InMemory:=True;
WriteToLog('    Drop table');
    Stmt.Result.SQL.Text := 'drop table Columns';
    try
      Stmt.Result.ExecSQL;
    except
    on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
        Result:=SQL_ERROR;
        Exit;
      end;
    end; // try
WriteToLog('    Create Table');
    Stmt.Result.SQL.Text :=
    'create table Columns('+
    'TABLE_QUALIFIER STRING('+IntToStr(_MAX_PATH)+'),'+
    'TABLE_OWNER STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'TABLE_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'COLUMN_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'DATA_TYPE SMALLINT,'+
    'TYPE_NAME STRING('+IntToStr(25)+'),'+
//    'COLUMN_SIZE INTEGER,'+  // v.3.xx
    'PRECISION INTEGER,'+ // v.2.xx
    'LENGTH INTEGER,' + // v.2.xx
//    'BUFFER_LENGTH INTEGER,' + // v.3.xx
    'SCALE SMALLINT,' + // v.2.xx
//    'DECIMAL_DIGITS SMALLINT,' + // v.3.xx
    'RADIX SMALLINT,' + // v.2.xx
//    'NUM_PREC_RADIX SMALLINT,' + // v.3.xx
    'NULLABLE SMALLINT,' +
    'REMARKS STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+')'+
{
    'LITERAL_PREFIX ,'+
    'LITERAL_SUFFIX, '+
    'CREATE_PARAMS, '+
    'NULLABLE, '+
    'CASE_SENSITIVE, '+
    'SEARCHABLE, '+
    'UNSIGNED_ATTRIBUTE, '+
//    'FIXED_PREC_SCALE, '+ // v.3.xx
    'MONEY, '+              // v.2.xx
//    'AUTO_UNIQUE_VALUE, '+  // v.3.xx
    'AUTO_INCREMENT, '+       // v.2.xx
    'LOCAL_TYPE_NAME, '+
    'MINIMUM_SCALE, '+
    'MAXIMUM_SCALE'+//, '+
//    'SQL_DATATYPE, '+   // v.3.xx
//    'SQL_DATETIME_SUB, '+    // v.3.xx
//    'NUM_PREC_RADIX, '+       // v.3.xx
//    'INTERVAL_PRECISION, '+  // v.3.xx
}
    ')'; // v.2
    try
      Stmt.Result.ExecSQL;
    except
    on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
        Result:=SQL_ERROR;
        Exit;
      end;
    end;// try
WriteToLog('    Table Columns created');

{
WriteToLog('    TStringList.Create');
  ColumnsList:=TStringList.Create;
}

  for i:=0 to TablesList.Count-1 do
    begin
WriteToLog('    Open table #'+IntToStr(i)+' = '+TablesList[i]);
      ET.Close;
      ET.TableName:=TablesList[i];
      try
        ET.Open;
      except
      on e: Exception do
          begin
WriteToLog('Error: ' + e.Message);
WriteToLog('TableName="'+ET.TableName+'"');
WriteToLog('DatabaseName="'+ET.DatabaseName+'"');
WriteToLog('DatabaseFileName="'+ET.DatabaseFileName+'"');
if ET.InMemory
then WriteToLog('InMemory=True')
else WriteToLog('InMemory=False');
            Result:=SQL_ERROR;
            Exit;
          end;
      end;
WriteToLog('    Table opened');
    // insert columns records for table #i
    for j:=0 to ET.FieldCount-1 do
      begin
WriteToLog('    insert '+IntToStr(j)+' = '+ET.Fields[j].FieldName);

        // select all columns to enable SQLColAttributes using
        Stmt.Result.DatabaseFileName:=Stmt.Database;
        Stmt.Result.InMemory:=False;
        Stmt.Result.Active:=False;
        Stmt.Result.SQL.Text := 'select * from '+TablesList[i];
        try
          Stmt.Result.Active := True;
        except
        on e: Exception do
            begin
WriteToLog('Error: ' + e.Message);
              Result:=SQL_ERROR;
              Exit;
            end;
        end; // try

if Stmt.Result.Active then
WriteToLog('    Result.RecordCount='+IntToStr(Stmt.Result.RecordCount))
else
WriteToLog('    Result.Active=False!!!');

        // Prepare to insert new record about column # j
WriteToLog('    Prepare SQL Statement:');
        str :=
          'insert into Columns('+
          'TABLE_QUALIFIER,'+
//        'TABLE_OWNER,'+  //NULL
          'TABLE_NAME,'+
          'COLUMN_NAME,'+
          'DATA_TYPE,'+
          'TYPE_NAME,'+
      //    'COLUMN_SIZE,'+  // v.3.xx
          'PRECISION,'+ // v.2.xx
          'LENGTH,' + // v.2.xx
      //    'BUFFER_LENGTH,' + // v.3.xx
          'SCALE,' + // v.2.xx
      //    'DECIMAL_DIGITS,' + // v.3.xx
          'RADIX,' + // v.2.xx
      //    'NUM_PREC_RADIX,' + // v.3.xx
          'NULLABLE,' +
{
          'LITERAL_PREFIX ,'+
          'LITERAL_SUFFIX, '+
          'CREATE_PARAMS, '+
          'NULLABLE, '+
          'CASE_SENSITIVE, '+
          'SEARCHABLE, '+
          'UNSIGNED_ATTRIBUTE, '+
      //    'FIXED_PREC_SCALE, '+ // v.3.xx
          'MONEY, '+              // v.2.xx
      //    'AUTO_UNIQUE_VALUE, '+  // v.3.xx
          'AUTO_INCREMENT, '+       // v.2.xx
          'LOCAL_TYPE_NAME, '+
          'MINIMUM_SCALE, '+
          'MAXIMUM_SCALE'+//, '+
      //    'SQL_DATATYPE, '+   // v.3.xx
      //    'SQL_DATETIME_SUB, '+    // v.3.xx
      //    'NUM_PREC_RADIX, '+       // v.3.xx
      //    'INTERVAL_PRECISION, '+  // v.3.xx
}
          'REMARKS'+
          ') values('+
          CONSTANT_QUOTE+Stmt.Database+CONSTANT_QUOTE+','+
//        CONSTANT_QUOTE+SchemaName+CONSTANT_QUOTE+','+ //NULL
          CONSTANT_QUOTE+TablesList[i]+CONSTANT_QUOTE+','+
          CONSTANT_QUOTE+ET.Fields[j].FieldName+CONSTANT_QUOTE+','; // Column_Name

WriteToLog('    str:'+str);
        NumericAttributePtr:=AllocMem(4); // Integer
        pStr:=AllocMem(MaxLen);
        ColumnNumber := Word(j+1);

        // DATA_TYPE
        if SQLColAttributes(Stmt,ColumnNumber,SQL_COLUMN_TYPE,pStr,-3,Pointer(SQL_NULL_HANDLE),NumericAttributePtr)=SQL_ERROR
          then str2:=''
          else str2:=IntToStr(NumericAttributePtr^);
WriteToLog('    '+str2);
        str := str+str2+',';
WriteToLog('    str:'+str);

        // TYPE_NAME
        if SQLColAttributes(Stmt,ColumnNumber,SQL_COLUMN_TYPE_NAME,pStr,MaxLen,Pointer(SQL_NULL_HANDLE),Pointer(SQL_NULL_HANDLE))=SQL_ERROR
          then pStr:='';
WriteToLog('    str:'+str);
WriteToLog('    pStr='+pStr);
WriteToLog('    str:'+str);
        str := str+CONSTANT_QUOTE+pStr+CONSTANT_QUOTE+',';
WriteToLog('    str:'+str);

        // [PRECISION]
        if SQLColAttributes(Stmt,ColumnNumber,SQL_COLUMN_PRECISION,pStr,-3,Pointer(SQL_NULL_HANDLE),NumericAttributePtr)=SQL_ERROR
          then str2:=''
          else str2:=IntToStr(NumericAttributePtr^);
WriteToLog('    '+str2);
        str := str+str2+',';
WriteToLog('    str:'+str);

        // LENGTH = precision
        if SQLColAttributes(Stmt,ColumnNumber,SQL_COLUMN_LENGTH,pStr,-3,Pointer(SQL_NULL_HANDLE),NumericAttributePtr)=SQL_ERROR
          then str2:=''
          else str2:=IntToStr(NumericAttributePtr^);
WriteToLog('    '+str2);
        str := str+str2+',';
WriteToLog('    str:'+str);

        // SCALE
        if SQLColAttributes(Stmt,ColumnNumber,SQL_COLUMN_SCALE,pStr,-3,Pointer(SQL_NULL_HANDLE),NumericAttributePtr)=SQL_ERROR
          then str2:=''
          else str2:=IntToStr(NumericAttributePtr^);
WriteToLog('    '+str2);
        str := str+str2+',';
WriteToLog('    str:'+str);

        // RADIX
        if SQLColAttributes(Stmt,ColumnNumber,SQL_DESC_NUM_PREC_RADIX,pStr,-3,Pointer(SQL_NULL_HANDLE),NumericAttributePtr)=SQL_ERROR
          then
            str2:='NULL'
          else if NumericAttributePtr^=0 then
            str2:='NULL'
          else
            str2:=IntToStr(NumericAttributePtr^);
WriteToLog('    '+str2);
        str := str+str2+',';
WriteToLog('    str:'+str);

        // NULLABLE
        if SQLColAttributes(Stmt,ColumnNumber,SQL_DESC_NULLABLE,pStr,-3,Pointer(SQL_NULL_HANDLE),NumericAttributePtr)=SQL_ERROR
          then str2:=''
          else str2:=IntToStr(NumericAttributePtr^);
WriteToLog('    '+str2);
        str := str+str2+',';
WriteToLog('    str:'+str);

{
---------------------------
Other fields should be here
---------------------------
}

        // REMARKS
        str2:='';
        str := str+CONSTANT_QUOTE+str2+CONSTANT_QUOTE

          +')';
WriteToLog('    str:'+str);

        FreeMem(pStr);
        FreeMem(NumericAttributePtr);

        // insert new record about column # j
WriteToLog('    Insert:');
        Stmt.Result.SQL.Text := str; // SQL.Text sets Stmt.Result.Active:=False;
WriteToLog('    Result.SQL.Text='+Stmt.Result.SQL.Text);
        Stmt.Result.InMemory:=True;
WriteToLog('    Try...');
        try
          Stmt.Result.ExecSQL;
        except
        on e: Exception do
          begin
WriteToLog('Error: ' + e.Message);
            Result:=SQL_ERROR;
            Exit;
          end;
        end; // try
WriteToLog('    ...inserted!');

if Stmt.Result.Active then
WriteToLog('    Result.RecordCount='+IntToStr(Stmt.Result.RecordCount))
else
WriteToLog('    Result.Active=False!!!');

      end; // for: next field
  end; //for: next table

  // Select using the TableName and ColumnName patterns
  if Integer(TableName)<>SQL_NULL_HANDLE
    then
      begin
        if TableLength = SQL_NTS
          then str := TableName//StrCopy(pChar(str),TableName)
          else str := Copy(TableName,1,TableLength);
        str := StringReplace(str,'''',' ',[rfReplaceAll]);
        str := StringReplace(str,'"',' ',[rfReplaceAll]);
        str := Trim(str);
WriteToLog('    str='+str);
        if str='' then str:='%';
        str := 'select * from memory Columns where (TABLE_NAME like '+CONSTANT_QUOTE+str+CONSTANT_QUOTE+')'
      end
    else
        str := 'select * from memory Columns where (TABLE_NAME like ''%'')';
  Stmt.Result.SQL.Text := str;
WriteToLog('    SQL.Text='+Stmt.Result.SQL.Text);
  if Integer(ColumnName)<>SQL_NULL_HANDLE
    then
      begin
        if ColumnLength = SQL_NTS
          then str := ColumnName//StrCopy(pChar(str),ColumnName)
          else str := Copy(ColumnName,1,ColumnLength);
        str := StringReplace(str,'''',' ',[rfReplaceAll]);
        str := StringReplace(str,'"',' ',[rfReplaceAll]);
        str := Trim(str);
WriteToLog('    str='+str);
        if str='' then str:='%';
        Stmt.Result.SQL.Text := Stmt.Result.SQL.Text
            + 'and (Column_NAME like '+CONSTANT_QUOTE+str+CONSTANT_QUOTE+')'
      end;
WriteToLog('    SQL.Text='+Stmt.Result.SQL.Text);

WriteToLog('    SQL.Active=True');
  try
    Stmt.Result.Active := True;
  except
  on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
       	Result:=SQL_ERROR;
        Exit;
      end;
  end; // try
WriteToLog('    RecordCount='+IntToStr(Stmt.Result.RecordCount));
  Stmt.Result.First;
  Stmt.FreshResult:=True;

	Result:=SQL_SUCCESS;

 Finish:
WriteToLog('    TablesList.Free');
  try
    TablesList.Free;
  except
  on e: Exception do
    begin
WriteToLog('Error: ' + e.Message);
      Result:=SQL_ERROR;
      Exit;
    end;
  end;
WriteToLog('    ET.Free');
  try
    ET.Free;
  except
  on e: Exception do
    begin
WriteToLog('Error: ' + e.Message);
      Result:=SQL_ERROR;
      Exit;
    end;
  end;
WriteToLog('### SQLColumns');
end;

///// SQLParamData /////

Function SQLParamData  (arg0:HSTMT;
		 var arg1:PTR): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLParamData called');
	Result:=SQL_SUCCESS;
end;

///// SQLPutData /////

Function SQLPutData  (arg0:HSTMT;
		 arg1:PTR;
		 arg2:SDWORD): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLPutData called');
	Result:=SQL_SUCCESS;
end;

///// SQLSpecialColumns /////

Function SQLSpecialColumns(
          Stmt:               PStmt;
          IdentifierType:     SmallInt;
          CatalogName:        PChar;
          CatalogLength:      SmallInt;
          SchemaName:         PChar;
          SchemaLength:       SmallInt;
          TableName:          PChar;
          TableLength:        SmallInt;
          Scope:              SmallInt;
          Nullable:           SmallInt
                            ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLSpecialColumns called');

WriteToLog('    IdentifierType='+IntToStr(IdentifierType));
WriteToLog('    Scope='+IntToStr(Scope));
WriteToLog('    Nullable='+IntToStr(Nullable));

if Integer(CatalogName)=SQL_NULL_HANDLE then WriteToLog('    CatalogName=0') else WriteToLog('    CatalogName="'+CatalogName+'"');
WriteToLog('    CatalogLength='+IntToStr(CatalogLength));
if Integer(SchemaName)=SQL_NULL_HANDLE then WriteToLog('    SchemaName=0') else WriteToLog('    SchemaName="'+SchemaName+'"');
WriteToLog('    SchemaLength='+IntToStr(SchemaLength));
if Integer(TableName)=SQL_NULL_HANDLE then WriteToLog('    TableName=0') else WriteToLog('    TableName="'+TableName+'"');
WriteToLog('    TableLength='+IntToStr(TableLength));

WriteToLog('    Active=False...');
  Stmt.Result.Active:=False;
WriteToLog('    InMemory...');
  if not Stmt.Result.InMemory then
    Stmt.Result.InMemory:=True;
WriteToLog('    Drop table...');
  Stmt.Result.SQL.Text := 'drop table memory SpecialColumns';
    try
      Stmt.Result.ExecSQL;
    except
    on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
        Result:=SQL_ERROR;
        Exit;
      end;
    end;// try
WriteToLog('    In-Memory Table "SpecialColumns" droped');

    Stmt.Result.SQL.Text :=
    'create table memory SpecialColumns('+
    'SCOPE SMALLINT,'+
    'COLUMN_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'DATA_TYPE SMALLINT,'+
    'TYPE_NAME STRING('+IntToStr(25)+'),'+
    'COLUMN_SIZE INTEGER,'+  // v.3.xx
//    'PRECISION INTEGER,'+ // v.2.xx
//    'LENGTH INTEGER,' + // v.2.xx
    'BUFFER_LENGTH INTEGER,' + // v.3.xx
//    'SCALE SMALLINT,' + // v.2.xx
    'DECIMAL_DIGITS SMALLINT,' + // v.3.xx
    'PSEUDO_COLUMN SMALLINT'+
    ')'; // v.2
    try
      Stmt.Result.ExecSQL;
    except
    on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
        Result:=SQL_ERROR;
        Exit;
      end;
    end;// try
WriteToLog('    In-Memory Table "SpecialColumns" created');

  Stmt.Result.SQL.Text := 'select * from memory SpecialColumns';
WriteToLog('    Stmt.Result.SQL.Text='+Stmt.Result.SQL.Text);

    try
  Stmt.Result.Active := True;
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    Stmt.Result.RecordCount='+IntToStr(Stmt.Result.RecordCount));

  Stmt.Result.First;
  Stmt.FreshResult:=True;
	Result:=SQL_SUCCESS;

WriteToLog('### SQLSpecialColumns');
end; // SQLSpecialColumns

///// SQLStatistics /////

Function SQLStatistics(
          Stmt:               PStmt;
          CatalogName:        PChar;
          CatalogLength:      SmallInt;
          SchemaName:         PChar;
          SchemaLength:       SmallInt;
          TableName:          PChar;
          TableLength:        SmallInt;
          Unique:             SmallInt;
          Reserved:           SmallInt
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLStatistics called');
if Integer(CatalogName)=SQL_NULL_HANDLE then WriteToLog('    CatalogName=0') else WriteToLog('    CatalogName="'+CatalogName+'"');
WriteToLog('    CatalogLength='+IntToStr(CatalogLength));
if Integer(SchemaName)=SQL_NULL_HANDLE then WriteToLog('    SchemaName=0') else WriteToLog('    SchemaName="'+SchemaName+'"');
WriteToLog('    SchemaLength='+IntToStr(SchemaLength));
if Integer(TableName)=SQL_NULL_HANDLE then WriteToLog('    TableName=0') else WriteToLog('    TableName="'+TableName+'"');
WriteToLog('    TableLength='+IntToStr(TableLength));
WriteToLog('    Unique='+IntToStr(Unique));
WriteToLog('    Reserved='+IntToStr(Reserved));

WriteToLog('    Active=False...');
  Stmt.Result.Active:=False;
WriteToLog('    InMemory...');
  if not Stmt.Result.InMemory then
    Stmt.Result.InMemory:=True;
WriteToLog('    Drop table...');
  Stmt.Result.SQL.Text := 'drop table memory Statistics';
    try
      Stmt.Result.ExecSQL;
    except
    on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
        Result:=SQL_ERROR;
        Exit;
      end;
    end;// try
WriteToLog('    In-Memory Table "Statistics" droped');

    Stmt.Result.SQL.Text :=
    'create table memory Statistics('+
    'TABLE_CAT STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'TABLE_SCHEM STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'TABLE_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'NON_UNIQUE SMALLINT,'+
    'INDEX_QUALIFIER STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'INDEX_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'TYPE SMALLINT,'+
    'ORDINAL_POSITION SMALLINT,'+
    'COLUMN_NAME STRING('+IntToStr(MAX_IDENTIFIER_LENGTH)+'),'+
    'ASC_OR_DESC STRING(1),'+
    'CARDINALITY INTEGER,'+
    'PAGES INTEGER,'+
    'FILTER_CONDITION STRING('+IntToStr(MAX_SQL_TEXT_LENGTH)+')'+
    ')';
    try
      Stmt.Result.ExecSQL;
    except
    on e: Exception do
      begin
WriteToLog('Error: ' + e.Message);
        Result:=SQL_ERROR;
        Exit;
      end;
    end;// try
WriteToLog('    In-Memory Table "Statistics" created');

  Stmt.Result.SQL.Text := 'select * from memory Statistics';
WriteToLog('    Stmt.Result.SQL.Text='+Stmt.Result.SQL.Text);

    try
  Stmt.Result.Active := True;
    except
    on e: Exception do
        begin
WriteToLog('Error: ' + e.Message);
         	Result:=SQL_ERROR;
          Exit;
        end;
    end;
WriteToLog('    Stmt.Result.RecordCount='+IntToStr(Stmt.Result.RecordCount));

  Stmt.Result.First;
  Stmt.FreshResult:=True;
	Result:=SQL_SUCCESS;
end; // SQLStatistics

///// SQLBrowseConnect /////

Function SQLBrowseConnect  (arg0:HDBC;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5: {UNALIGNED} SWORD
                     ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLBrowseConnect called');
	Result:=SQL_SUCCESS;
end;

///// SQLColumnPrivileges /////

Function SQLColumnPrivileges  (
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD;
		 arg7:UCHAR;
		 arg8:SWORD
                     ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLColumnPrivileges called');
	Result:=SQL_SUCCESS;
end;

///// SQLDataSources /////

Function SQLDataSources  (
     arg0:HENV;
		 arg1:UWORD;
		 arg2:UCHAR;
		 arg3:SWORD;
		 var arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD;
		 var arg7:SWORD
                     ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLDataSources called');
	Result:=SQL_SUCCESS;
end;

///// SQLDescribeParam /////

Function SQLDescribeParam  (
     arg1:HSTMT;
		 arg2:UWORD;
		 var arg3: {UNALIGNED} SWORD;
		 var arg4: {UNALIGNED} UDWORD;
		 var arg5: {UNALIGNED} SWORD;
		 var arg6: {UNALIGNED} SWORD
                     ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLDescribeParam called');
	Result:=SQL_SUCCESS;
end;

///// SQLForeignKeys /////

Function SQLForeignKeys  (
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD;
		 arg7:UCHAR;
		 arg8:SWORD;
		 arg9:UCHAR;
		 arg10:SWORD;
		 arg11:UCHAR;
		 arg12:SWORD
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLForeignKeys called');
	Result:=SQL_SUCCESS;
end;

///// SQLMoreResults /////

Function SQLMoreResults  (arg0:HSTMT): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLMoreResults');

//	Result:=SQL_SUCCESS;
  Result:=SQL_NO_DATA;
	WriteToLog('### SQLMoreResults');
end;

///// SQLNativeSql /////

Function SQLNativeSql  (
     arg0:HDBC;
		 arg1:UCHAR;
		 arg2:SDWORD;
		 arg3:UCHAR;
		 arg4:SDWORD;
		 var arg5: {UNALIGNED} SDWORD
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLNativeSql called');
	Result:=SQL_SUCCESS;
end;

///// SQLNumParams /////

Function SQLNumParams  ( arg0:HSTMT;
		 var arg1: {UNALIGNED} SWORD): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLNumParams called');
	Result:=SQL_SUCCESS;
end;

///// SQLParamOptions /////

Function SQLParamOptions  (
     arg0:HSTMT;
		 arg1:UDWORD;
		 var arg2: {UNALIGNED} UDWORD): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLParamOptions called');
	Result:=SQL_SUCCESS;
end;

///// SQLPrimaryKeys /////

Function SQLPrimaryKeys(
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLPrimaryKeys called');
	Result:=SQL_SUCCESS;
end;

///// SQLProcedureColumns /////

Function SQLProcedureColumns(
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD;
		 arg7:UCHAR;
		 arg8:SWORD
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLProcedureColumns called');
	Result:=SQL_SUCCESS;
end;

///// SQLProcedures /////

Function SQLProcedures  (
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLProcedures called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetPos /////

Function SQLSetPos  (
     arg0:HSTMT;
		 arg1:UWORD;
		 arg2:UWORD;
		 arg3:UWORD
                      ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetPos called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetScrollOptions /////

Function SQLSetScrollOptions  (
     arg0:HSTMT;
		 arg1:UWORD;
		 arg2:SDWORD;
		 arg3:UWORD
                                ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetScrollOptions called');
	Result:=SQL_SUCCESS;
end;

///// SQLTablePrivileges /////

Function SQLTablePrivileges  (
     arg0:HSTMT;
		 arg1:UCHAR;
		 arg2:SWORD;
		 arg3:UCHAR;
		 arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD
                              ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLTablePrivileges called');
	Result:=SQL_SUCCESS;
end;

///// SQLDrivers /////

Function SQLDrivers  (
     arg0:HENV;
		 arg1:UWORD;
		 arg2:UCHAR;
		 arg3:SWORD;
		 var arg4:SWORD;
		 arg5:UCHAR;
		 arg6:SWORD;
		 arg7:SWORD
                      ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLDrivers called');
	Result:=SQL_SUCCESS;
end;

///// SQLBindParameter /////

Function SQLBindParameter  (
             Stmt:pStmt;//HSTMT;
        		 ParameterNumber:UWORD;
        		 IOType:SWORD;
        		 ValueType:SWORD;
        		 ParameterType:SWORD;
        		 ColumnSize:UDWORD;
        		 DecimalDigits:SWORD;
        		 ParameterValuePtr:PTR;
        		 BufferLength:SDWORD;
        		 StrLen_or_IndPtr:PInteger //{UNALIGNED} SDWORD
                             ): RETCODE; stdcall;
begin
WriteToLog('>>> SQLBindParameter called');
  // Array starting with index 0
  if Length(Stmt.BindParam)<ParameterNumber then SetLength(Stmt.BindParam,ParameterNumber); //resize
  Stmt.BindParam[ParameterNumber-1].IOType:=IOType;
  Stmt.BindParam[ParameterNumber-1].ValueType:=ValueType;
  Stmt.BindParam[ParameterNumber-1].ParameterType:=ParameterType;
  Stmt.BindParam[ParameterNumber-1].ColumnSize:=ColumnSize;
  Stmt.BindParam[ParameterNumber-1].DecimalDigits:=DecimalDigits;
  Stmt.BindParam[ParameterNumber-1].ParameterValuePtr:=ParameterValuePtr;
  Stmt.BindParam[ParameterNumber-1].BufferLength:=BufferLength;
  Stmt.BindParam[ParameterNumber-1].StrLen_or_IndPtr:=StrLen_or_IndPtr;

WriteToLog('    ParameterNumber='+IntToStr(ParameterNumber)+';');
WriteToLog('    IOType='+IntToStr(IOType)+';');
WriteToLog('    ValueType='+IntToStr(ValueType)+';');
WriteToLog('    ParameterType='+IntToStr(ParameterType)+';');
WriteToLog('    ColumnSize='+IntToStr(ColumnSize)+';');
WriteToLog('    DecimalDigits='+IntToStr(DecimalDigits)+';');
if Integer(ParameterValuePtr)=SQL_NULL_HANDLE then  WriteToLog('    ParameterValuePtr=0') else WriteToLog('    ParameterValuePtr='+IntToHex(Integer(ParameterValuePtr),8)+'.');
WriteToLog('    BufferLength='+IntToStr(BufferLength)+';');
if Integer(StrLen_or_IndPtr)=SQL_NULL_HANDLE then  WriteToLog('    @StrLen_or_Ind=0') else WriteToLog('    @StrLen_or_Ind='+IntToStr(Integer(StrLen_or_IndPtr))+'.');

WriteToLog('### SQLBindParameter');

	Result:=SQL_SUCCESS;
end;

///// SQLBindParam /////

Function SQLBindParam  (
     arg0:SQLHSTMT;
		 arg1:SQLUSMALLINT;
		 arg2:SQLSMALLINT;
		 arg3:SQLSMALLINT;
		 arg4:SQLUINTEGER;
		 arg5:SQLSMALLINT;
		 arg6:SQLPOINTER;
		 var arg7:SQLINTEGER
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLBindParam called');
	Result:=SQL_SUCCESS;
end;

///// SQLCloseCursor /////

Function SQLCloseCursor  (arg0:SQLHSTMT): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLCloseCursor called');
	Result:=SQL_SUCCESS;
end;

///// SQLCopyDesc /////

Function SQLCopyDesc  (arg0:SQLHDESC;
		 arg1:SQLHDESC): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLCopyDesc called');
	Result:=SQL_SUCCESS;
end;

///// SQLEndTran /////

Function SQLEndTran  (
     arg0:SQLSMALLINT;
		 arg1:SQLHANDLE;
		 arg2:SQLSMALLINT): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLEndTran called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetConnectAttr /////

Function SQLGetConnectAttr  (arg0:SQLHDBC;
		 arg1:SQLINTEGER;
		 arg2:SQLPOINTER;
		 arg3:SQLINTEGER;
		 var arg4: {UNALIGNED} SQLINTEGER): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetConnectAttr called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetDescField /////

Function SQLGetDescField  (
     arg0:SQLHDESC;
		 arg1:SQLSMALLINT;
		 arg2:SQLSMALLINT;
		 arg3:SQLPOINTER;
		 arg4:SQLINTEGER;
		 var arg5: {UNALIGNED} SQLINTEGER
                           ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetDescField called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetDescRec /////

Function SQLGetDescRec  (
     arg0:SQLHDESC;
		 arg1:SQLSMALLINT;
		 var arg2:SQLCHAR;
		 arg3:SQLSMALLINT;
		 var arg4: {UNALIGNED} SQLSMALLINT;
		 var arg5: {UNALIGNED} SQLSMALLINT;
		 var arg6: {UNALIGNED} SQLSMALLINT;
		 var arg7: {UNALIGNED} SQLINTEGER ;
		 var arg8: {UNALIGNED} SQLSMALLINT;
		 var arg9: {UNALIGNED} SQLSMALLINT;
		 var arg10: {UNALIGNED} SQLSMALLINT
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetDescRec called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetDiagField /////

Function SQLGetDiagField  (
     arg0:SQLSMALLINT;
		 arg1:SQLHANDLE;
		 arg2:SQLSMALLINT;
		 arg3:SQLSMALLINT;
		 arg4:SQLPOINTER;
		 arg5:SQLSMALLINT;
		 arg6: {UNALIGNED} SQLSMALLINT
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetDiagField called');
	Result:=SQL_NO_DATA_FOUND;
end;

///// SQLGetDiagRec /////

Function SQLGetDiagRec  (
     arg0:SQLSMALLINT;
		 arg1:SQLHANDLE;
		 arg2:SQLSMALLINT;
		 var arg3:SQLCHAR;
		 var arg4: {UNALIGNED} SQLINTEGER;
		 var arg5:SQLCHAR;
		 arg6:SQLSMALLINT;
		 var arg7: {UNALIGNED} SQLSMALLINT
                             ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetDiagRec called');
	Result:=SQL_NO_DATA_FOUND;
end;

///// SQLGetEnvAttr /////

Function SQLGetEnvAttr  (
     arg0:SQLHENV;
		 arg1:SQLINTEGER;
		 arg2:SQLPOINTER;
		 arg3:SQLINTEGER;
     var arg4: {UNALIGNED} SQLINTEGER
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetEnvAttr called');
	Result:=SQL_SUCCESS;
end;

///// SQLGetStmtAttr /////

Function SQLGetStmtAttr  (
     arg0:SQLHSTMT;
		 arg1:SQLINTEGER;
		 arg2:SQLPOINTER;
		 arg3:SQLINTEGER;
		 var arg4: {UNALIGNED} SQLINTEGER
                          ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLGetStmtAttr called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetConnectAttr /////

Function SQLSetConnectAttr  (
     arg0:SQLHDBC;
		 arg1:SQLINTEGER;
		 arg2:SQLPOINTER;
		 arg3:SQLINTEGER
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetConnectAttr called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetDescField /////

Function SQLSetDescField  (
     arg0:SQLHDESC;
		 arg1:SQLSMALLINT;
		 arg2:SQLSMALLINT;
		 arg3:SQLPOINTER;
		 arg4:SQLINTEGER
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetDescField called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetDescRec /////

Function SQLSetDescRec  (
     arg0:SQLHDESC;
		 arg1:SQLSMALLINT;
		 arg2:SQLSMALLINT;
		 arg3:SQLSMALLINT;
		 arg4:SQLINTEGER;
		 arg5:SQLSMALLINT;
		 arg6:SQLSMALLINT;
		 arg7:SQLPOINTER;
		 var arg8: {UNALIGNED} SQLINTEGER;
		 var arg9: {UNALIGNED} SQLINTEGER
                            ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetDescRec called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetEnvAttr /////

Function SQLSetEnvAttr  (
     arg0:SQLHENV;
		 arg1:SQLINTEGER;
		 arg2:SQLPOINTER;
		 arg3:SQLINTEGER
                        ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetEnvAttr called');
	Result:=SQL_SUCCESS;
end;

///// SQLSetStmtAttr /////

Function SQLSetStmtAttr  (
     arg0:SQLHSTMT;
		 arg1:SQLINTEGER;
		 arg2:SQLPOINTER;
		 arg3:SQLINTEGER
                          ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLSetStmtAttr called');
	Result:=SQL_SUCCESS;
end;

///// SQLBulkOperations /////

Function SQLBulkOperations  (
     arg0:SQLHSTMT;
		 arg1:SQLSMALLINT
                              ): RETCODE; stdcall;
begin
	WriteToLog('>>> SQLBulkOperations called');
	Result:=SQL_SUCCESS;
end;

////////////////////////////////
//         Setup DLL          //
////////////////////////////////

Function ConfigDSN(
     hwndParent:HWND;
     fRequest:WORD;
     lpszDriver:LPCSTR;
     lpszAttributes:LPCSTR
                   ): BOOLEAN; stdcall;

label
  AddDSN,
  RemoveDSN,
  ConfigDSN,
  Finish;
var
  DSNstr,DatabasePath : String;
//  str1,str2: String;
  Description,FileName:PChar;

const
  MaxDescriptionSize = 512;
begin
  Description:=AllocMem(MaxDescriptionSize);
  FileName:=AllocMem(_MAX_PATH+1);
  StrCopy(FileName,'ODBC.INI');

  Result:=False; // Will be changed to True if it will be available to prepare the data

  // get datasource name
  DSNstr:=lpszAttributes;
  if pos('DSN=',DSNstr)=0 then DSNstr:='' else
    begin
      DSNstr:=copy(DSNstr,pos('DSN=',DSNstr)+4,length(DSNstr));
      Result:=True;
    end;

  // get database path - special keyword Path
  DatabasePath:=lpszAttributes;
  if pos('Path=',DatabasePath)=0 then // Try to read from ODBC.INI
    begin
      SQLGetPrivateProfileString(PChar(DSNstr),pchar('Path'),pchar(''),Description,MaxDescriptionSize-1,FileName); // Get Description in Windows NT / Windows 2000
      DatabasePath:=Description;
    end
  else // Set from lpszAttributes
      DatabasePath:=copy(DatabasePath,Pos('Path=',DatabasePath)+5,length(DatabasePath));

  // get database path - special keyword Description
  StrCopy(Description,lpszAttributes);
  if pos('Description=',Description)=0 then // Try to read from ODBC.INI
      SQLGetPrivateProfileString(pchar(DSNstr),pchar('Description'),pchar('EasyTable database'),Description,MaxDescriptionSize-1,FileName) // Get Description in Windows NT / Windows 2000
  else // Set from lpszAttributes
      StrCopy(Description,pchar(copy(Description,pos('Description=',Description)+12,length(Description))));
  if Description='' then Description:='EasyTable database';
{
fRequest:
=========
ODBC_ADD_DSN: Add a new data source.
ODBC_CONFIG_DSN: Configure (modify) an existing data source.
ODBC_REMOVE_DSN: Remove an existing data source.
}
  if fRequest=ODBC_REMOVE_DSN then goto RemoveDSN;

  // Show dialog
  if hwndParent<>0 then // Show dialog
    begin
      DSNsetupForm := TDSNsetupForm.Create(Nil);
      if not (lpszAttributes^=#0) then // Show dialog with Attributes
        begin
          DSNsetupForm.DSN.Text:=DSNstr;
          DSNsetupForm.DatabaseFile.Text:=DatabasePath;
          DSNsetupForm.Description.Text:=Description;
        end;
    end; // Copy Attributes to Dialog fields
      try
        DSNsetupForm.Show;
      except
      on E: Exception do
WriteToLog('DSNsetupForm.Show failed: ' + e.Message);
      end;
    repeat
     Application.ProcessMessages;
    until not DSNsetupForm.Visible;
  	case DSNsetupForm.Button of
      btnOK:       Result:=True;
      btnCancel:   Result:=False;
    end; //case
{
fRequest:
=========
ODBC_ADD_DSN: Add a new data source.
ODBC_CONFIG_DSN: Configure (modify) an existing data source.
ODBC_REMOVE_DSN: Remove an existing data source.
}
 case fRequest of
  ODBC_ADD_DSN:     goto AddDSN;    // Adding DSN
  ODBC_CONFIG_DSN:  goto ConfigDSN; // Configuring DSN
 end;

 AddDSN: // Adding DSN
  if Result=True then // Set parameters
    begin
      DSNstr:=DSNsetupForm.DSN.Text;
      DatabasePath:=DSNsetupForm.DatabaseFile.Text;
      StrCopy(Description,PChar(DSNsetupForm.Description.Text));
    end;
  DSNsetupForm.Free;
  if Result=True then // Write DSN
    if not SQLWriteDSNToIni(pchar(DSNstr),lpszDriver) then
      Result:=False; // Writing was not successful
  if DatabasePath='' then
    Result:=False
   else
    if SQLWritePrivateProfileString (pchar(DSNstr),pchar('Path'),pchar(DatabasePath),FileName) // Write DatabasePath in Windows NT / Windows 2000
     then Result:=False; // Writing DatabasePath was not successful
  SQLWritePrivateProfileString (pchar(DSNstr),pchar('Description'),Description,FileName); // Write Description in Windows NT / Windows 2000
  goto Finish;
// End of Adding DSN

 RemoveDSN: // Removing DSN
  if not SQLRemoveDSNFromIni(pchar(DSNstr)) then Result:=False; // Writing was not successful
  goto Finish;
// End of removing DSN

 ConfigDSN: // Configuring DSN
  if Result=True then  // Save changes
    begin
      if hwndParent<>0 then // dialog is showed
        begin
          if not (DSNstr=DSNsetupForm.DSN.Text) then // Name was changed
            begin
              if not SQLRemoveDSNFromIni(pchar(DSNstr)) then // Delete old DSN
                begin
                  Result:=False; // Writing was not successful
                  goto Finish;
                end;
              DSNstr:=DSNsetupForm.DSN.Text;
              if not SQLWriteDSNToIni(pchar(DSNstr),lpszDriver) // Write new DSN
                then Result:=False; // Writing was not successful
            end; // Save name changes
          DatabasePath:=DSNsetupForm.DatabaseFile.Text;
          StrCopy(Description,pchar(DSNsetupForm.Description.Text));
          DSNsetupForm.Free;
        end;
      if DatabasePath='' then Result:=False else
      if SQLWritePrivateProfileString (pchar(DSNstr),pchar('Path'),pchar(DatabasePath),FileName) // Write DatabasePath in Windows NT / Windows 2000
      then Result:=False; // Writing DatabasePath was not successful
      SQLWritePrivateProfileString (pchar(DSNstr),pchar('Description'),Description,FileName); // Write Description in Windows NT / Windows 2000
      goto Finish;
    end; // Save changes
// End of cinfiguring DSN

 Finish:
  FreeMem(FileName);
  FreeMem(Description);
end;

Function ConfigDriver(
     hwndParent:HWND;
     fRequest:WORD;
     lpszDriver:LPCSTR;
     lpszArgs:LPCSTR;
     lpszMsg:LPSTR;
     cbMsgMax:WORD;
     var pcbMsgOut:WORD
                       ): BOOLEAN; stdcall;
begin
	Result:=ConfigDSN(hwndParent,fRequest,lpszDriver,lpszArgs);
end;

Function ConfigTranslator(
     hwndParent:HWND;
     var pvOption:DWORD
                       ): BOOLEAN; stdcall;
begin
	WriteToLog('>>> ConfigTranslator called');
	Result:=True;
end;

////////////////////////////////
//      Translation DLL       //
////////////////////////////////

exports

////////////////////////////////
//         Driver DLL         //
////////////////////////////////

//SQLAllocHandle, // v.3.x
SQLAllocConnect,  // v.2.x
SQLAllocEnv,      // v.2.x
SQLAllocStmt,     // v.2.x

SQLBindCol,
SQLBindParameter,
SQLBrowseConnect, //Level1

SQLBulkOperations, // Level1  v.3.x
SQLSetPos,         // Level1  v.2.x

SQLCancel,
//SQLCloseCursor,   // v.3.x

//SQLColAttribute,  // v.3.x
SQLColAttributes,  // v.2.x

//SQLColumnPrivileges, //Level2
SQLColumns,
SQLConnect,
//SQLCopyDesc,  // v.3.x
SQLDataSources,
SQLDescribeCol,
//SQLDescribeParam, //Level2
SQLDisconnect,
SQLDriverConnect,
SQLDrivers,

//SQLEndTran,  // v.3.x
SQLTransact,  // v.2.x

SQLExecDirect,
SQLExecute,

SQLFetch,  // v.2.x & v.3.xx
//SQLFetchScroll,  // v.3.x
SQLExtendedFetch,  // v.2.x

//SQLForeignKeys, //Level2

//SQLFreeHandle,  // v.3.x
SQLFreeEnv,       // v.2.x
SQLFreeConnect,   // v.2.x
SQLFreeStmt,      // v.2.x

//SQLGetConnectAttr,  // v.3.x
SQLGetConnectOption,  // v.2.x

SQLGetCursorName,
SQLGetData,
//SQLGetDescField,  // v.3.x
//SQLGetDescRec,  // v.3.x
//SQLGetDiagField,  // v.3.x

//SQLGetDiagRec,  // v.3.x
SQLError,  // v.2.x

//SQLGetEnvAttr,     // v.3.x
SQLGetFunctions,
SQLGetInfo,

//SQLGetStmtAttr, // v.3.x
SQLGetStmtOption, // v.2.x

SQLGetTypeInfo,
SQLMoreResults, //Level1 - for MFC
SQLNativeSql,
SQLNumParams,
SQLNumResultCols,
SQLParamData,
SQLPrepare,
//SQLPrimaryKeys, //Level1
//SQLProcedureColumns, //Level1
//SQLProcedures, //Level1
SQLPutData,
SQLRowCount,

//SQLSetConnectAttr,  // v.3.x
SQLSetConnectOption,  // v.2.x

SQLSetCursorName,
//SQLSetDescField,    // v.3.x
//SQLSetDescRec,  // v.3.x
//SQLSetEnvAttr,  // v.3.x
//SQLSetPos, //Level1

//SQLSetStmtAttr,  // v.3.x
SQLSetStmtOption,  // v.2.x

SQLSpecialColumns,
SQLStatistics,
//SQLTablePrivileges, //Level2
SQLTables,

////////////////////////////////
//         Setup DLL          //
////////////////////////////////
ConfigDriver,
ConfigDSN
//ConfigTranslator - not released yet

////////////////////////////////
//       Installer DLL        //
////////////////////////////////
{
odbccp32.dll
============
SQLConfigDriver,
SQLGetInstalledDrivers,
SQLInstallDriverEx,
SQLInstallDriverManager,
SQLInstallerError,
SQLInstallTranslatorEx,
SQLPostInstallerError,
SQLRemoveDriver,
SQLRemoveDriverManager,
SQLRemoveTranslator,
SQLConfigDataSource,
SQLCreateDataSource,
SQLGetConfigMode,
SQLGetPrivateProfileString,
SQLGetTranslator,
SQLManageDataSources,
SQLReadFileDSN,
SQLRemoveDefaultDataSource,
SQLRemoveDSNFromIni,
SQLSetConfigMode,
SQLValidDSN,
SQLWriteDSNToIni,
SQLWriteFileDSN,
SQLWritePrivateProfileString,
}

////////////////////////////////
//      Translation DLL       //
////////////////////////////////
{
SQLDataSourceToDriver,
SQLDriverToDataSource
}

; // end exports
{
var
  str: pchar;
}
begin
  {$IFDEF DEBUG_MEMCHECK}
WriteToLog('Try to run MemCheck...');
//  GetModuleFileName(NULL,str,_MAX_PATH);//GetModuleHandle('eodbc.dll'),str,_MAX_PATH);//PChar(MemCheckLogFileName),_MAX_PATH);
//  MemCheckLogFileName := ExtractFilePath(MemCheckLogFileName)+'MemCheck.log';
  MemCheckLogFileName := 'S:\DelphiProjects\EasyTable-ODBC-driver\__test\MemCheck.log';
WriteToLog(MemCheckLogFileName);
  MemChk;
WriteToLog('MemCheck started!');
  {$ENDIF}
end.
