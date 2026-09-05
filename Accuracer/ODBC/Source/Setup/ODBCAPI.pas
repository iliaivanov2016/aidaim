unit ODBCAPI;

interface

uses SysUtils, db;

type
  SQLCHAR      = Char;
  SQLSMALLINT  = smallint;
  SQLUSMALLINT = Word;
  SQLRETURN    = SQLSMALLINT;
  SQLHANDLE    = LongInt;
  SQLHENV      = SQLHANDLE;
  SQLHDBC      = SQLHANDLE;
  SQLHSTMT     = SQLHANDLE;
  SQLINTEGER   = LongInt;
  SQLUINTEGER  = Cardinal;
  SQLPOINTER   = Pointer;
  SQLREAL      = real;
  SQLDOUBLE    = Double;
  SQLFLOAT     = Double;
  PSQLCHAR      = PChar;
  PSQLINTEGER   = ^SQLINTEGER;
  PSQLUINTEGER  = ^SQLUINTEGER;
  PSQLSMALLINT  = ^SQLSMALLINT;
  PSQLUSMALLINT = ^SQLUSMALLINT;
  PSQLREAL      = ^SQLREAL;
  PSQLDOUBLE    = ^SQLDOUBLE;
  PSQLFLOAT     = ^SQLFLOAT;
  PSQLHandle    = ^SQLHANDLE;

//typedef struct tagSQL_NUMERIC_STRUCT
//{
//        SQLCHAR         precision;
//        SQLSCHAR        scale;
//        SQLCHAR         sign;   /* 1 if positive, 0 if negative */
//        SQLCHAR         val[SQL_MAX_NUMERIC_LEN];
//} SQL_NUMERIC_STRUCT;

type
  SQL_NUMERIC_STRUCT = packed record
        precision:  Byte  ;
        scale:      Byte      ;
        sign:       Byte       ;    { 1 if positive, 0 if negative }
        val:        array [0..SQL_MAX_NUMERIC_LEN-1] of Byte;
  end;
  PSQL_NUMERIC_STRUCT = ^SQL_NUMERIC_STRUCT;

type
  SQL_DATE_STRUCT = packed record
    Year: SQLSMALLINT;
    Month: SQLUSMALLINT;
    Day: SQLUSMALLINT;
  end;
  PSQL_DATE_STRUCT = ^SQL_DATE_STRUCT;

  SQL_TIME_STRUCT = packed record
    Hour:   SQLUSMALLINT;
    Minute: SQLUSMALLINT;
    Second: SQLUSMALLINT;
  end;
  PSQL_TIME_STRUCT = ^SQL_TIME_STRUCT;

  SQL_TIMESTAMP_STRUCT = packed record
    Year:     SQLUSMALLINT;
    Month:    SQLUSMALLINT;
    Day:      SQLUSMALLINT;
    Hour:     SQLUSMALLINT;
    Minute:   SQLUSMALLINT;
    Second:   SQLUSMALLINT;
    Fraction: SQLUINTEGER;
  end;
  PSQL_TIMESTAMP_STRUCT = ^SQL_TIMESTAMP_STRUCT;

{
// uses db
  TFieldType = (ftUnknown, ftString,
               ftSmallint, ftInteger, ftWord,
               ftBoolean, ftFloat, ftCurrency, ftBCD,
               ftDate, ftTime,
               ftDateTime, ftBytes, ftVarBytes,
               ftAutoInc, ftBlob,
               ftMemo, ftGraphic, ftFmtMemo,
               ftParadoxOle, ftDBaseOle,
                ftTypedBinary, ftCursor);
}
Function SQLAllocEnv(var phenv:LongInt):Smallint;stdcall;far;
Function SQLAllocConnect(henv:LongInt; var phdbc:Integer):Smallint;stdcall;far;
Function SQLFreeEnv( henv:LongInt) :Smallint;stdcall; far;
Function SQLFreeConnect( hdbc:LongInt) :Smallint;stdcall; far;
Function SQLConnect(hdbc:Integer; szDSN:PCHAR; cbDSN:Smallint; szUID:PCHAR; cbUID:Smallint; szAuthStr:PCHAR; cbAuthStr:Smallint) :Smallint;stdcall; far;
Function SQLDisconnect( hdbc:Integer) :Smallint;stdcall; far;
Function SQLAllocStmt(hdbc:Integer; var phstmt:Integer):Smallint;stdcall;far;
Function SQLFreeStmt( hstmt:Integer;  fOption:Smallint) :Smallint;stdcall; far;
Function SQLExecDirect( hstmt:Integer;  szSqlStr:PCHAR;  cbSqlStr:Integer) :Smallint;stdcall; far;
function SQLFetchScroll(hstmt:Integer;
            FetchOrientation: Smallint; FetchOffset: Integer) :Smallint;stdcall; far;
function SQLGetDiagRec(
               HandleType:   SQLSMALLINT;
               Handle:       SQLHANDLE;
               RecNumber:    SQLSMALLINT;
               Sqlstate:     PSQLCHAR;
               var NativeError: SQLRETURN;
               MessageText:     PSQLCHAR;
               BufferLength:    SQLSMALLINT;
               var TextLength:  SQLSMALLINT ):SQLRETURN;stdcall;far;
function SQLSetPos(
               hstmt:SQLHSTMT;
               irow:SQLUSMALLINT;
               fOption:SQLUSMALLINT;
               fLock:SQLUSMALLINT):SQLRETURN;stdcall;far;

function SQLSetStmtAttr(
               StatementHandle:SQLHSTMT;
               Attribute:SQLINTEGER;
               Value:SQLPOINTER;
               StringLength:SQLINTEGER):SQLRETURN;stdcall; far;
function SQLNumResultCols(
               StatementHandle:SQLHSTMT;
               var ColumnCount:SQLSMALLINT):SQLRETURN;stdcall; far;
function SQLDescribeCol(
               StatementHandle:SQLHSTMT;
               ColumnNumber:SQLUSMALLINT;
               ColumnName:PSQLCHAR;
               BufferLength:SQLSMALLINT;
               var NameLength:SQLSMALLINT;
               var DataType:SQLSMALLINT;
               var ColumnSize:SQLUINTEGER;
               var DecimalDigits:SQLSMALLINT;
               var Nullable:SQLSMALLINT):SQLRETURN;stdcall; far;
function SQLBindCol(
               StatementHandle:SQLHSTMT;
               ColumnNumber:SQLUSMALLINT;
               TargetType:SQLSMALLINT;
               TargetValue:SQLPOINTER;
               BufferLength:SQLINTEGER;
               StrLen_or_Ind:PSQLINTEGER):SQLRETURN;stdcall; far;
function SQLGetData(
               StatementHandle:SQLHSTMT;
               ColumnNumber:SQLUSMALLINT;
               TargetType:SQLSMALLINT;
               TargetValue:SQLPOINTER;
               BufferLength:SQLINTEGER;
               StrLen_or_Ind:PSQLINTEGER):SQLRETURN;stdcall; far;
function SQLBindParameter(
               hstmt:SQLHSTMT;
               ipar:SQLUSMALLINT;
               fParamType:SQLSMALLINT;
               fCType:SQLSMALLINT;
               fSqlType:SQLSMALLINT;
               cbColDef:SQLUINTEGER;
               ibScale:SQLSMALLINT;
               rgbValue:SQLPOINTER;
               cbValueMax:SQLINTEGER;
               pcbValue:PSQLINTEGER):SQLRETURN;stdcall; far;
function SQLPrepare(
               StatementHandle:SQLHSTMT;
               StatementText:PSQLCHAR;
               TextLength:SQLINTEGER):SQLRETURN;stdcall; far;

function SQLExecute(
               StatementHandle:SQLHSTMT):SQLRETURN;stdcall; far;

Function SQLSetParam( hstmt:Integer;  ipar:Smallint;
                     fCType:Smallint;  fSqlType:Smallint;
                     cbColDef:Integer;  ibScale:Smallint;
                     var RGBValue:PCHAR;
                     var pcbValue:Integer) :SQLRETURN;stdcall; far;

implementation

Function SQLAllocEnv(var phenv:LongInt):Smallint;far;external 'odbc32.dll';
Function SQLAllocConnect(henv:LongInt; var phdbc:LongInt):Smallint;far;external 'odbc32.dll';
Function SQLFreeEnv( henv:LongInt) :Smallint;far;external 'odbc32.dll';
Function SQLFreeConnect( hdbc:Integer) :Smallint;far;external 'odbc32.dll';
Function SQLConnect(hdbc:Integer; szDSN:PCHAR; cbDSN:Smallint; szUID:PCHAR; cbUID:Smallint; szAuthStr:PCHAR; cbAuthStr:Smallint) :Smallint;far;external 'odbc32.dll';
Function SQLDisconnect( hdbc:Integer) :Smallint;far;external 'odbc32.dll';
Function SQLAllocStmt(hdbc:Integer; var phstmt:Integer):Smallint;far;external 'odbc32.dll';
Function SQLFreeStmt(hstmt:Integer;  fOption:Smallint) :Smallint;far;external 'odbc32.dll';
Function SQLExecDirect( hstmt:Integer;  szSqlStr:PCHAR;  cbSqlStr:Integer) :Smallint;far;external 'odbc32.dll';
function SQLFetchScroll(hstmt:Integer;
            FetchOrientation: Smallint; FetchOffset: Integer) :Smallint;far;external 'odbc32.dll';
function SQLGetDiagRec(
               HandleType:   SQLSMALLINT;
               Handle:       SQLHANDLE;
               RecNumber:    SQLSMALLINT;
               Sqlstate:     PSQLCHAR;
               var NativeError: SQLRETURN;
               MessageText:     PSQLCHAR;
               BufferLength:    SQLSMALLINT;
               var TextLength:  SQLSMALLINT ):SQLRETURN;far;external 'odbc32.dll';
function SQLSetPos(
               hstmt:SQLHSTMT;
               irow:SQLUSMALLINT;
               fOption:SQLUSMALLINT;
               fLock:SQLUSMALLINT):SQLRETURN;far;external 'ODBC32.DLL';

function SQLSetStmtAttr(
               StatementHandle:SQLHSTMT;
               Attribute:SQLINTEGER;
               Value:SQLPOINTER;
               StringLength:SQLINTEGER):SQLRETURN;far;external 'ODBC32.DLL';
function SQLNumResultCols(
               StatementHandle:SQLHSTMT;
               var ColumnCount:SQLSMALLINT):SQLRETURN;far;external 'ODBC32.DLL';
function SQLDescribeCol(
               StatementHandle:SQLHSTMT;
               ColumnNumber:SQLUSMALLINT;
               ColumnName:PSQLCHAR;
               BufferLength:SQLSMALLINT;
               var NameLength:SQLSMALLINT;
               var DataType:SQLSMALLINT;
               var ColumnSize:SQLUINTEGER;
               var DecimalDigits:SQLSMALLINT;
               var Nullable:SQLSMALLINT):SQLRETURN;far;external 'ODBC32.DLL';
function SQLBindCol(
               StatementHandle:SQLHSTMT;
               ColumnNumber:SQLUSMALLINT;
               TargetType:SQLSMALLINT;
               TargetValue:SQLPOINTER;
               BufferLength:SQLINTEGER;
               StrLen_or_Ind:PSQLINTEGER):SQLRETURN;far;external 'ODBC32.DLL';
function SQLGetData(
               StatementHandle:SQLHSTMT;
               ColumnNumber:SQLUSMALLINT;
               TargetType:SQLSMALLINT;
               TargetValue:SQLPOINTER;
               BufferLength:SQLINTEGER;
               StrLen_or_Ind:PSQLINTEGER):SQLRETURN;far;external 'ODBC32.DLL';

function SQLBindParameter(
               hstmt:SQLHSTMT;
               ipar:SQLUSMALLINT;
               fParamType:SQLSMALLINT;
               fCType:SQLSMALLINT;
               fSqlType:SQLSMALLINT;
               cbColDef:SQLUINTEGER;
               ibScale:SQLSMALLINT;
               rgbValue:SQLPOINTER;
               cbValueMax:SQLINTEGER;
               pcbValue:PSQLINTEGER):SQLRETURN;far;external 'ODBC32.DLL';
function SQLPrepare(
               StatementHandle:SQLHSTMT;
               StatementText:PSQLCHAR;
               TextLength:SQLINTEGER):SQLRETURN;far;external 'ODBC32.DLL';

function SQLExecute(
               StatementHandle:SQLHSTMT):SQLRETURN;far;external 'ODBC32.DLL';


Function SQLSetParam( hstmt:Integer;  ipar:Smallint;
                     fCType:Smallint;  fSqlType:Smallint;
                     cbColDef:Integer;  ibScale:Smallint;
                     var RGBValue:PCHAR;
                     var pcbValue:Integer) :SQLRETURN;far;external 'ODBC32.DLL';

end.


