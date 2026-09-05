unit constSQL;

interface

uses SysUtils;

CONST
  // return values from functions
  SQL_SUCCESS  = 0;
  SQL_SUCCESS_WITH_INFO =  1;
  SQL_NO_DATA           =  100;
  SQL_ERROR             = (-1);
  SQL_INVALID_HANDLE    = (-2);
  SQL_NEED_DATA         =  99;
  SQL_NTS               = (-3);

  SQL_PARAM_TYPE_UNKNOWN = 0;
  SQL_PARAM_INPUT        = 1;
  SQL_PARAM_INPUT_OUTPUT = 2;
  SQL_RESULT_COL         = 3;
  SQL_PARAM_OUTPUT       = 4;
  SQL_RETURN_VALUE       = 5;


// Codes used for FetchOrientation in SQLFetchScroll(),
//   and in SQLDataSources()

  SQL_FETCH_NEXT     = 1;
  SQL_FETCH_FIRST    = 2;
  SQL_FETCH_LAST     = 3;
  SQL_FETCH_PRIOR    = 4;
  SQL_FETCH_ABSOLUTE = 5;
  SQL_FETCH_RELATIVE = 6;

{ handle type identifiers }
  SQL_HANDLE_ENV   = 1;
  SQL_HANDLE_DBC   = 2;
  SQL_HANDLE_STMT  = 3;
  SQL_HANDLE_DESC  = 4;

{ Operations in SQLSetPos }
  SQL_POSITION                = 0;
  SQL_REFRESH                 = 1;
  SQL_UPDATE                  = 2;
  SQL_DELETE                  = 3;

{ Lock options in SQLSetPos }
  SQL_LOCK_NO_CHANGE          = 0;
  SQL_LOCK_EXCLUSIVE          = 1;
  SQL_LOCK_UNLOCK             = 2;

  { statement attributes }
  SQL_ATTR_APP_ROW_DESC       = 10010;
  SQL_ATTR_APP_PARAM_DESC     = 10011;
  SQL_ATTR_IMP_ROW_DESC       = 10012;
  SQL_ATTR_IMP_PARAM_DESC     = 10013;
  SQL_ATTR_CURSOR_SCROLLABLE  = (-1);
  SQL_ATTR_CURSOR_SENSITIVITY = (-2);
  SQL_QUERY_TIMEOUT           =0;
  SQL_MAX_ROWS                =1;
  SQL_NOSCAN                  =2;
  SQL_MAX_LENGTH              =3;
  SQL_ASYNC_ENABLE            =4;       // same as SQL_ATTR_ASYNC_ENABLE */
  SQL_BIND_TYPE               =5;
  SQL_CURSOR_TYPE             = 6;
  SQL_CONCURRENCY             = 7;
  SQL_KEYSET_SIZE             =8;
  SQL_ROWSET_SIZE             =9;
  SQL_SIMULATE_CURSOR         =10;
  SQL_RETRIEVE_DATA           =11;
  SQL_USE_BOOKMARKS           =12;
  SQL_GET_BOOKMARK            =13;      //      GetStmtOption Only */
  SQL_ROW_NUMBER              = 14;     //      GetStmtOption Only */
  SQL_ATTR_CURSOR_TYPE        = SQL_CURSOR_TYPE;
  SQL_ATTR_CONCURRENCY        = SQL_CONCURRENCY;
  SQL_ATTR_FETCH_BOOKMARK_PTR = 16;
  SQL_ATTR_ROW_STATUS_PTR     = 25;
  SQL_ATTR_ROWS_FETCHED_PTR   = 26;
  SQL_AUTOCOMMIT              = 102;
  SQL_ATTR_AUTOCOMMIT         = SQL_AUTOCOMMIT;

  SQL_ATTR_ROW_NUMBER         = SQL_ROW_NUMBER;
  SQL_TXN_ISOLATION           = 108;
  SQL_ATTR_TXN_ISOLATION      = SQL_TXN_ISOLATION;
  SQL_ATTR_MAX_ROWS           = SQL_MAX_ROWS;
  SQL_ATTR_USE_BOOKMARKS      = SQL_USE_BOOKMARKS;

{ SQL_ATTR_CURSOR_SCROLLABLE values }
  SQL_NONSCROLLABLE              = 0;
  SQL_SCROLLABLE                 = 1;
  { SQL_CURSOR_TYPE options }
  SQL_CURSOR_FORWARD_ONLY     = 0;
  SQL_CURSOR_KEYSET_DRIVEN    = 1;
  SQL_CURSOR_DYNAMIC          = 2;
  SQL_CURSOR_STATIC           = 3;
  SQL_CURSOR_TYPE_DEFAULT     = SQL_CURSOR_FORWARD_ONLY;{ Default value }

{ whether an attribute is a pointer or not }
  SQL_IS_POINTER    = (-4);
  SQL_IS_UINTEGER   = (-5);
  SQL_IS_INTEGER    = (-6);
  SQL_IS_USMALLINT  = (-7);
  SQL_IS_SMALLINT   = (-8);
  { SQLExtendedFetch "fFetchType" values }
  SQL_FETCH_BOOKMARK = 8;
  SQL_SCROLL_OPTIONS = 44;

{ SQLGetData() code indicating that the application row descriptor
    specifies the data type }
  SQL_ARD_TYPE      = (-99);

// Cursor typ
type TCursorType = (FORWARD_ONLY,STATIC,KEYSET_DRIVEN,DYNAMIC);



const
  { values of NULLABLE field in descriptor }
  SQL_NO_NULLS = 0;
  SQL_NULLABLE = 1;
  { Value returned by SQLGetTypeInfo() to denote that it is
   not known whether or not a data type supports null values. }
  SQL_NULLABLE_UNKNOWN = 2;

{ SQL data type codes }
const
  SQL_UNKNOWN_TYPE  = 0;
  SQL_LONGVARCHAR   =(-1);
  SQL_BINARY        =(-2);
  SQL_VARBINARY     =(-3);
  SQL_LONGVARBINARY =(-4);
  SQL_BIGINT        =(-5);
  SQL_TINYINT       =(-6);
  SQL_BIT           =(-7);
  SQL_WCHAR         =(-8);
  SQL_WVARCHAR      =(-9);
  SQL_WLONGVARCHAR  =(-10);
  SQL_CHAR          = 1;
  SQL_NUMERIC       = 2;
  SQL_DECIMAL       = 3;
  SQL_INTEGER       = 4;
  SQL_SMALLINT      = 5;
  SQL_FLOAT         = 6;
  SQL_REAL          = 7;
  SQL_DOUBLE        = 8;
  SQL_DATETIME      = 9;
  SQL_VARCHAR       = 12;
  SQL_TYPE_DATE     = 91;
  SQL_TYPE_TIME     = 92;
  SQL_TYPE_TIMESTAMP= 93;
  SQL_NO_TOTAL   = -4;
  SQL_NULL_DATA  = (-1);
{ C data type codes }
  SQL_C_CHAR =   SQL_CHAR ; //            /* CHAR, VARCHAR, DECIMAL, NUMERIC */
  SQL_C_LONG        = SQL_INTEGER;
  SQL_C_SHORT       = SQL_SMALLINT;
  SQL_C_TYPE_DATE   = SQL_TYPE_DATE;
  SQL_C_TYPE_TIME   = SQL_TYPE_TIME;
  SQL_C_DATETIME    = SQL_DATETIME;
  SQL_C_TYPE_TIMESTAMP  = SQL_TYPE_TIMESTAMP;
  SQL_C_NUMERIC         = SQL_NUMERIC;
  SQL_C_BIT             = SQL_BIT;
  SQL_C_BINARY          = SQL_BINARY;
  SQL_C_DOUBLE          = SQL_DOUBLE;
  SQL_MAX_NUMERIC_LEN   = 16;

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
        precision:Byte  ;
        scale:Byte      ;
        sign:Byte       ;    { 1 if positive, 0 if negative }
        val:array [0..SQL_MAX_NUMERIC_LEN-1] of Byte;
  end;
  PSQL_NUMERIC_STRUCT = ^SQL_NUMERIC_STRUCT;



type
  SQL_DATE_STRUCT = packed record
    Year : SQLSMALLINT;
    Month : SQLUSMALLINT;
    Day : SQLUSMALLINT;
  end;
  PSQL_DATE_STRUCT = ^SQL_DATE_STRUCT;

  SQL_TIME_STRUCT = packed record
    Hour : SQLUSMALLINT;
    Minute : SQLUSMALLINT;
    Second : SQLUSMALLINT;
  end;
  PSQL_TIME_STRUCT = ^SQL_TIME_STRUCT;

  SQL_TIMESTAMP_STRUCT = packed record
    Year :     SQLUSMALLINT;
    Month :    SQLUSMALLINT;
    Day :      SQLUSMALLINT;
    Hour :     SQLUSMALLINT;
    Minute :   SQLUSMALLINT;
    Second :   SQLUSMALLINT;
    Fraction : SQLUINTEGER;
  end;
  PSQL_TIMESTAMP_STRUCT = ^SQL_TIMESTAMP_STRUCT;



TFieldType = (ftUnknown, ftString,
               ftSmallint, ftInteger, ftWord,
               ftBoolean, ftFloat, ftCurrency, ftBCD,
               ftDate, ftTime,
               ftDateTime, ftBytes, ftVarBytes,
               ftAutoInc, ftBlob,
               ftMemo, ftGraphic, ftFmtMemo,
               ftParadoxOle, ftDBaseOle,
                ftTypedBinary, ftCursor);

implementation

end.


