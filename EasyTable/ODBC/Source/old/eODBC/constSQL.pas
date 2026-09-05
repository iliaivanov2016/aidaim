unit constSQL;

interface

uses SysUtils;

CONST

///////////////////////////////////////////////////////
// SQL.H - The main include for ODBC Core functions. //
///////////////////////////////////////////////////////

  SQL_NULL_HANDLE = 0;
{ null handles returned by SQLAllocHandle() }
   SQL_NULL_HENV      = 0;
   SQL_NULL_HDBC      = 0;
   SQL_NULL_HSTMT     = 0;
//#if (ODBCVER >= 0x0300)
   SQL_NULL_HDESC     = 0;
//#endif


  SQL_FALSE           = 0;
  SQL_TRUE            = 1;

// FreeStmt() options
  SQL_CLOSE           = 0;
  SQL_DROP            = 1;
  SQL_UNBIND          = 2;
  SQL_RESET_PARAMS    = 3;

// SQLGetTypes
  SQL_ALL_TYPES       = 0;

// SQLGetFunctions() values to identify ODBC APIs
  SQL_API_SQLALLOCCONNECT     =    1;
  SQL_API_SQLALLOCENV         =    2;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLALLOCHANDLE      = 1001;
////#endif
  SQL_API_SQLALLOCSTMT        =    3;
  SQL_API_SQLBINDCOL          =    4;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLBINDPARAM        = 1002;
////#endif
  SQL_API_SQLCANCEL           =    5;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLCLOSECURSOR      = 1003;
  SQL_API_SQLCOLATTRIBUTE     =    6;
////#endif
  SQL_API_SQLCOLUMNS          =   40;
  SQL_API_SQLCONNECT          =    7;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLCOPYDESC         = 1004;
////#endif
  SQL_API_SQLDATASOURCES      =   57;
  SQL_API_SQLDESCRIBECOL      =    8;
  SQL_API_SQLDISCONNECT       =    9;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLENDTRAN          = 1005;
////#endif
  SQL_API_SQLERROR            =   10;
  SQL_API_SQLEXECDIRECT       =   11;
  SQL_API_SQLEXECUTE          =   12;
  SQL_API_SQLFETCH            =   13;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLFETCHSCROLL      = 1021;
////#endif
  SQL_API_SQLFREECONNECT      =   14;
  SQL_API_SQLFREEENV          =   15;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLFREEHANDLE       = 1006;
////#endif
  SQL_API_SQLFREESTMT         =   16;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLGETCONNECTATTR   = 1007;
////#endif
  SQL_API_SQLGETCONNECTOPTION =   42;
  SQL_API_SQLGETCURSORNAME    =   17;
  SQL_API_SQLGETDATA          =   43;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLGETDESCFIELD     = 1008;
  SQL_API_SQLGETDESCREC       = 1009;
  SQL_API_SQLGETDIAGFIELD     = 1010;
  SQL_API_SQLGETDIAGREC       = 1011;
  SQL_API_SQLGETENVATTR       = 1012;
////#endif
  SQL_API_SQLGETFUNCTIONS     =   44;
  SQL_API_SQLGETINFO          =   45;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLGETSTMTATTR      = 1014;
////#endif
  SQL_API_SQLGETSTMTOPTION    =   46;
  SQL_API_SQLGETTYPEINFO      =   47;
  SQL_API_SQLNUMRESULTCOLS    =   18;
  SQL_API_SQLPARAMDATA        =   48;
  SQL_API_SQLPREPARE          =   19;
  SQL_API_SQLPUTDATA          =   49;
  SQL_API_SQLROWCOUNT         =   20;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLSETCONNECTATTR   = 1016;
////#endif
  SQL_API_SQLSETCONNECTOPTION =   50;
  SQL_API_SQLSETCURSORNAME    =   21;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLSETDESCFIELD     = 1017;
  SQL_API_SQLSETDESCREC       = 1018;
  SQL_API_SQLSETENVATTR       = 1019;
////#endif
  SQL_API_SQLSETPARAM         =   22;
////#if (ODBCVER >= = $0300)
  SQL_API_SQLSETSTMTATTR      = 1020;
////#endif
  SQL_API_SQLSETSTMTOPTION    =   51;
  SQL_API_SQLSPECIALCOLUMNS   =   52;
  SQL_API_SQLSTATISTICS       =   53;
  SQL_API_SQLTABLES           =   54;
  SQL_API_SQLTRANSACT         =   23;

// SQLGetInfo
  SQL_MAX_DRIVER_CONNECTIONS          = 0;
  SQL_MAXIMUM_DRIVER_CONNECTIONS		= SQL_MAX_DRIVER_CONNECTIONS;
  SQL_MAX_CONCURRENT_ACTIVITIES      =  1;
  SQL_MAXIMUM_CONCURRENT_ACTIVITIES	= SQL_MAX_CONCURRENT_ACTIVITIES;
  SQL_DATA_SOURCE_NAME               =  2;
  SQL_FETCH_DIRECTION                =  8;
  SQL_SERVER_NAME                    = 13;
  SQL_SEARCH_PATTERN_ESCAPE          = 14;
  SQL_DBMS_NAME                      = 17;
  SQL_DBMS_VER                       = 18;
  SQL_ACCESSIBLE_TABLES              = 19;
  SQL_ACCESSIBLE_PROCEDURES        	 = 20;
  SQL_CURSOR_COMMIT_BEHAVIOR         = 23;
  SQL_DATA_SOURCE_READ_ONLY          = 25;
  SQL_DEFAULT_TXN_ISOLATION          = 26;
  SQL_IDENTIFIER_CASE                = 28;
  SQL_IDENTIFIER_QUOTE_CHAR          = 29;
  SQL_MAX_COLUMN_NAME_LEN            = 30;
  SQL_MAXIMUM_COLUMN_NAME_LENGTH		= SQL_MAX_COLUMN_NAME_LEN;
  SQL_MAX_CURSOR_NAME_LEN            = 31;
  SQL_MAXIMUM_CURSOR_NAME_LENGTH		= SQL_MAX_CURSOR_NAME_LEN;
  SQL_MAX_SCHEMA_NAME_LEN            = 32;
  SQL_MAXIMUM_SCHEMA_NAME_LENGTH		= SQL_MAX_SCHEMA_NAME_LEN;
  SQL_MAX_CATALOG_NAME_LEN          =  34;
  SQL_MAXIMUM_CATALOG_NAME_LENGTH		= SQL_MAX_CATALOG_NAME_LEN;
  SQL_MAX_TABLE_NAME_LEN            =  35;
  SQL_SCROLL_CONCURRENCY            =  43;
  SQL_TXN_CAPABLE                   =  46;
  SQL_TRANSACTION_CAPABLE				= SQL_TXN_CAPABLE;
  SQL_USER_NAME                      = 47;
  SQL_TXN_ISOLATION_OPTION           = 72;
  SQL_TRANSACTION_ISOLATION_OPTION	= SQL_TXN_ISOLATION_OPTION;
  SQL_INTEGRITY                     =  73;
  SQL_GETDATA_EXTENSIONS            =  81;
  SQL_NULL_COLLATION                =  85;
  SQL_ALTER_TABLE                   =  86;
  SQL_ORDER_BY_COLUMNS_IN_SELECT    =  90;
  SQL_SPECIAL_CHARACTERS            =  94;
  SQL_MAX_COLUMNS_IN_GROUP_BY       =  97;
  SQL_MAXIMUM_COLUMNS_IN_GROUP_BY	  =	SQL_MAX_COLUMNS_IN_GROUP_BY;
  SQL_MAX_COLUMNS_IN_INDEX          =  98;
  SQL_MAXIMUM_COLUMNS_IN_INDEX		  = SQL_MAX_COLUMNS_IN_INDEX;
  SQL_MAX_COLUMNS_IN_ORDER_BY       =  99;
  SQL_MAXIMUM_COLUMNS_IN_ORDER_BY		= SQL_MAX_COLUMNS_IN_ORDER_BY;
  SQL_MAX_COLUMNS_IN_SELECT         = 100;
  SQL_MAXIMUM_COLUMNS_IN_SELECT	    = SQL_MAX_COLUMNS_IN_SELECT;
  SQL_MAX_COLUMNS_IN_TABLE          = 101;
  SQL_MAX_INDEX_SIZE                = 102;
  SQL_MAXIMUM_INDEX_SIZE			      = SQL_MAX_INDEX_SIZE;
  SQL_MAX_ROW_SIZE                  = 104;
  SQL_MAXIMUM_ROW_SIZE			        = SQL_MAX_ROW_SIZE;
  SQL_MAX_STATEMENT_LEN             = 105;
  SQL_MAXIMUM_STATEMENT_LENGTH	    = SQL_MAX_STATEMENT_LEN;
  SQL_MAX_TABLES_IN_SELECT          = 106;
  SQL_MAXIMUM_TABLES_IN_SELECT	    = SQL_MAX_TABLES_IN_SELECT;
  SQL_MAX_USER_NAME_LEN             = 107;
  SQL_MAXIMUM_USER_NAME_LENGTH	    = SQL_MAX_USER_NAME_LEN;
{
//#if (ODBCVER >= = $0300)
  SQL_OJ_CAPABILITIES               = 115;
  SQL_OUTER_JOIN_CAPABILITIES		   = SQL_OJ_CAPABILITIES;
//#endif // ODBCVER >= = $0300
}
//#if (ODBCVER >= = $0300)
  SQL_XOPEN_CLI_YEAR               =10000;
  SQL_CURSOR_SENSITIVITY           =10001;

  SQL_DESCRIBE_PARAMETER           = 10002;
  SQL_CATALOG_NAME                 = 10003;
  SQL_COLLATION_SEQ                = 10004;
  SQL_MAX_IDENTIFIER_LEN           = 10005;

  SQL_MAXIMUM_IDENTIFIER_LENGTH	 = SQL_MAX_IDENTIFIER_LEN;
//#endif { ODBCVER >= = $0300 }

{ SQL_ALTER_TABLE bitmasks }
//#if (ODBCVER >= = $0200)
  SQL_AT_ADD_COLUMN                   	= $00000001;
  SQL_AT_DROP_COLUMN                  	= $00000002;
//#endif { ODBCVER >= = $0200 }

//#if (ODBCVER >= = $0300)
  SQL_AT_ADD_CONSTRAINT               	= $00000008;

{ The following bitmasks are ODBC extensions and defined in sqlext.h
* 	SQL_AT_COLUMN_SINGLE					= $00000020;
* 	SQL_AT_ADD_COLUMN_DEFAULT				= $00000040;
* 	SQL_AT_ADD_COLUMN_COLLATION				= $00000080;
* 	SQL_AT_SET_COLUMN_DEFAULT				= $00000100;
* 	SQL_AT_DROP_COLUMN_DEFAULT				= $00000200;
* 	SQL_AT_DROP_COLUMN_CASCADE				= $00000400;
* 	SQL_AT_DROP_COLUMN_RESTRICT				= $00000800;
*  SQL_AT_ADD_TABLE_CONSTRAINT				= $00001000;
*  SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE		= $00002000;
*  SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT		= $00004000;
*  SQL_AT_CONSTRAINT_NAME_DEFINITION			= $00008000;
*  SQL_AT_CONSTRAINT_INITIALLY_DEFERRED		= $00010000;
*  SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE		= $00020000;
*  SQL_AT_CONSTRAINT_DEFERRABLE				= $00040000;
*  SQL_AT_CONSTRAINT_NON_DEFERRABLE			= $00080000;
}
//#endif  { ODBCVER >= = $0300 }

{ SQL_ASYNC_MODE values }
//#if (ODBCVER >= = $0300)
  SQL_AM_NONE                         = 0;
  SQL_AM_CONNECTION                   = 1;
  SQL_AM_STATEMENT                    = 2;
//#endif


{ SQL_CURSOR_COMMIT_BEHAVIOR values }
  SQL_CB_DELETE                      = 0;
  SQL_CB_CLOSE                       = 1;
  SQL_CB_PRESERVE                    = 2;

{
{ SQL_FETCH_DIRECTION bitmasks }
  SQL_FD_FETCH_NEXT                   = $00000001;
  SQL_FD_FETCH_FIRST                  = $00000002;
  SQL_FD_FETCH_LAST                   = $00000004;
  SQL_FD_FETCH_PRIOR                  = $00000008;
  SQL_FD_FETCH_ABSOLUTE               = $00000010;
  SQL_FD_FETCH_RELATIVE               = $00000020;

{ SQL_GETDATA_EXTENSIONS bitmasks }
  SQL_GD_ANY_COLUMN                   = $00000001;
  SQL_GD_ANY_ORDER                    = $00000002;

{ SQL_IDENTIFIER_CASE values }
  SQL_IC_UPPER                        = 1;
  SQL_IC_LOWER                        = 2;
  SQL_IC_SENSITIVE                    = 3;
  SQL_IC_MIXED                        = 4;

{ SQL_OJ_CAPABILITIES bitmasks }
{ NB: this means 'outer join', not what  you may be thinking }

//#if (ODBCVER >= = $0201)
  SQL_OJ_LEFT                         = $00000001;
  SQL_OJ_RIGHT                        = $00000002;
  SQL_OJ_FULL                         = $00000004;
  SQL_OJ_NESTED                       = $00000008;
  SQL_OJ_NOT_ORDERED                  = $00000010;
  SQL_OJ_INNER                        = $00000020;
  SQL_OJ_ALL_COMPARISON_OPS           = $00000040;
//#endif

{ SQL_SCROLL_CONCURRENCY bitmasks }
  SQL_SCCO_READ_ONLY                  = $00000001;
  SQL_SCCO_LOCK                       = $00000002;
  SQL_SCCO_OPT_ROWVER                 = $00000004;
  SQL_SCCO_OPT_VALUES                 = $00000008;

{ SQL_TXN_CAPABLE values }
  SQL_TC_NONE                         = 0;
  SQL_TC_DML                          = 1;
  SQL_TC_ALL                          = 2;
  SQL_TC_DDL_COMMIT                   = 3;
  SQL_TC_DDL_IGNORE                   = 4;

{ SQL_TXN_ISOLATION_OPTION bitmasks }
  SQL_TXN_READ_UNCOMMITTED            = $00000001;
  SQL_TRANSACTION_READ_UNCOMMITTED	= SQL_TXN_READ_UNCOMMITTED;
  SQL_TXN_READ_COMMITTED              = $00000002;
  SQL_TRANSACTION_READ_COMMITTED		= SQL_TXN_READ_COMMITTED;
  SQL_TXN_REPEATABLE_READ             = $00000004;
  SQL_TRANSACTION_REPEATABLE_READ		= SQL_TXN_REPEATABLE_READ;
  SQL_TXN_SERIALIZABLE                = $00000008;
  SQL_TRANSACTION_SERIALIZABLE		  = SQL_TXN_SERIALIZABLE;

{ SQL_NULL_COLLATION values }
  SQL_NC_HIGH                         = 0;
  SQL_NC_LOW                          = 1;

///////////////////////////////////////////////
// ODBCInst.h -- Prototypes for ODBCCP32.DLL //
///////////////////////////////////////////////

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
  SQL_QUERY_TIMEOUT           = 0;
  SQL_MAX_ROWS                = 1;
  SQL_NOSCAN                  = 2;
  SQL_MAX_LENGTH              = 3;
  SQL_ASYNC_ENABLE            = 4;       // same as SQL_ATTR_ASYNC_ENABLE }
  SQL_BIND_TYPE               = 5;
  SQL_CURSOR_TYPE             = 6;
  SQL_CONCURRENCY             = 7;
  SQL_KEYSET_SIZE             = 8;
  SQL_ROWSET_SIZE             = 9;
  SQL_SIMULATE_CURSOR         = 10;
  SQL_RETRIEVE_DATA           = 11;
  SQL_USE_BOOKMARKS           = 12;
  SQL_GET_BOOKMARK            = 13;      //      GetStmtOption Only }
  SQL_ROW_NUMBER              = 14;     //      GetStmtOption Only }
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

// for ODBC<3.0
  SQL_STMT_OPT_MAX = SQL_ROW_NUMBER;
  SQL_STMT_OPT_MIN = SQL_QUERY_TIMEOUT;

// SQL_BIND_TYPE options
  SQL_BIND_BY_COLUMN              = 0;
  SQL_BIND_TYPE_DEFAULT     =      SQL_BIND_BY_COLUMN;

{ SQL_USE_BOOKMARKS options }
  SQL_UB_OFF                    =  0;
  SQL_UB_ON					    	      =  1;
  SQL_UB_DEFAULT                =  SQL_UB_OFF;

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
//  SQL_SCROLL_OPTIONS = 44;

{ SQLGetData() code indicating that the application row descriptor
    specifies the data type }
  SQL_ARD_TYPE      = (-99);

////////////////////////////////////////////////////////////////////////////
// SQLEXT.H - include for applications using the Microsoft SQL Extensions //
////////////////////////////////////////////////////////////////////////////

// Options for SQLExtendedFetch
{ SQLExtendedFetch "fFetchType" values }
//  SQL_FETCH_BOOKMARK              = 8;

{ SQLExtendedFetch "rgfRowStatus" element values }
  SQL_ROW_SUCCESS                 = 0;
  SQL_ROW_DELETED                 = 1;
  SQL_ROW_UPDATED                 = 2;
  SQL_ROW_NOROW                   = 3;
  SQL_ROW_ADDED                   = 4;
  SQL_ROW_ERROR                   = 5;
{
#if (ODBCVER >= 0x0300)
#define SQL_ROW_SUCCESS_WITH_INFO		 6
#define SQL_ROW_PROCEED					 0
#define SQL_ROW_IGNORE					 1
#endif
}
{ Options for SQLDriverConnect }
  SQL_DRIVER_NOPROMPT            = 0;
  SQL_DRIVER_COMPLETE            = 1;
  SQL_DRIVER_PROMPT              = 2;
  SQL_DRIVER_COMPLETE_REQUIRED   = 3;

// Attributes

{ connection attributes }
  SQL_ACCESS_MODE                 = 101;
//  SQL_AUTOCOMMIT                  = 102;
  SQL_LOGIN_TIMEOUT               = 103;
  SQL_OPT_TRACE                   = 104;
  SQL_OPT_TRACEFILE               = 105;
  SQL_TRANSLATE_DLL               = 106;
  SQL_TRANSLATE_OPTION            = 107;
//  SQL_TXN_ISOLATION               = 108;
  SQL_CURRENT_QUALIFIER           = 109;
  SQL_ODBC_CURSORS                = 110;
  SQL_QUIET_MODE                  = 111;
  SQL_PACKET_SIZE                 = 112;

//#if (ODBCVER >= 0x0300)
  SQL_ATTR_ACCESS_MODE		=SQL_ACCESS_MODE;
//  SQL_ATTR_AUTOCOMMIT			=SQL_AUTOCOMMIT;
  SQL_ATTR_CONNECTION_TIMEOUT	=113       ;
  SQL_ATTR_CURRENT_CATALOG	=SQL_CURRENT_QUALIFIER;
  SQL_ATTR_DISCONNECT_BEHAVIOR=	114              ;
  SQL_ATTR_ENLIST_IN_DTC		=1207                 ;
  SQL_ATTR_ENLIST_IN_XA		=1208                   ;
  SQL_ATTR_LOGIN_TIMEOUT	=	SQL_LOGIN_TIMEOUT    ;
  SQL_ATTR_ODBC_CURSORS		=SQL_ODBC_CURSORS       ;
  SQL_ATTR_PACKET_SIZE		=SQL_PACKET_SIZE        ;
  SQL_ATTR_QUIET_MODE			=SQL_QUIET_MODE         ;
  SQL_ATTR_TRACE				=SQL_OPT_TRACE            ;
  SQL_ATTR_TRACEFILE		=	SQL_OPT_TRACEFILE      ;
  SQL_ATTR_TRANSLATE_LIB =		SQL_TRANSLATE_DLL    ;
  SQL_ATTR_TRANSLATE_OPTION	=SQL_TRANSLATE_OPTION ;
//  SQL_ATTR_TXN_ISOLATION		=SQL_TXN_ISOLATION    ;
//#endif  { ODBCVER >= 0x0300 }

 SQL_ATTR_CONNECTION_DEAD	= 1209;	{ GetConnectAttr only }
{
#if (ODBCVER >= 0x0351)
	ODBC Driver Manager sets this connection attribute to a unicode driver
	(which supports SQLConnectW) when the application is an ANSI application
	(which calls SQLConnect, SQLDriverConnect, or SQLBrowseConnect).
	This is SetConnectAttr only and application does not set this attribute
	This attribute was introduced because some unicode driver's some APIs may
	need to behave differently on ANSI or Unicode applications. A unicode
	driver, which  has same behavior for both ANSI or Unicode applications,
	shoUL;d return SQL_ERROR when the driver manager sets this connection
	attribute. When a unicode driver returns SQL_SUCCESS on this attribute,
	the driver manager treates ANSI and Unicode connections differently in
	connection pooling.

  SQL_ATTR_ANSI_APP			= 115;
#endif
}

{ SQL_CONNECT_OPT_DRVR_START is not meaningfUL; for 3.0 driver }
//#if (ODBCVER < 0x0300)
  SQL_CONNECT_OPT_DRVR_START    =  1000;
//#endif  { ODBCVER < 0x0300 }

//#if (ODBCVER < 0x0300)
  SQL_CONN_OPT_MAX              =  SQL_PACKET_SIZE;
  SQL_CONN_OPT_MIN              =  SQL_ACCESS_MODE;
//#endif { ODBCVER < 0x0300 }

{ SQL_ACCESS_MODE options }
  SQL_MODE_READ_WRITE          =   0;
  SQL_MODE_READ_ONLY           =   1;
  SQL_MODE_DEFAULT             =   SQL_MODE_READ_WRITE;

{ SQL_AUTOCOMMIT options }
  SQL_AUTOCOMMIT_OFF           =   0;
  SQL_AUTOCOMMIT_ON            =   1;
  SQL_AUTOCOMMIT_DEFAULT       =   SQL_AUTOCOMMIT_ON   ;

{ SQL_LOGIN_TIMEOUT options }
  SQL_LOGIN_TIMEOUT_DEFAULT    =   15;

{ SQL_OPT_TRACE options }
  SQL_OPT_TRACE_OFF               = 0;
  SQL_OPT_TRACE_ON                = 1;
  SQL_OPT_TRACE_DEFAULT          = SQL_OPT_TRACE_OFF    ;
  SQL_OPT_TRACE_FILE_DEFAULT     = '\\SQL.LOG';

{ SQL_ODBC_CURSORS options }
  SQL_CUR_USE_IF_NEEDED         =  0;
  SQL_CUR_USE_ODBC              =  1;
  SQL_CUR_USE_DRIVER            =  2;
  SQL_CUR_DEFAULT               =  SQL_CUR_USE_DRIVER;

  { values for SQL_ATTR_DISCONNECT_BEHAVIOR }
{
#if (ODBCVER >= 0x0300)
  SQL_DB_RETURN_TO_POOL			0UL;
  SQL_DB_DISCONNECT				1UL;
  SQL_DB_DEFAULT					= SQL_DB_RETURN_TO_POOL
// values for SQL_ATTR_ENLIST_IN_DTC
  SQL_DTC_DONE					= 0L;
}
//#endif  { ODBCVER >= 0x0300 }

{ values for SQL_ATTR_CONNECTION_DEAD }
  SQL_CD_TRUE					= 1;		{ Connection is closed/dead }
  SQL_CD_FALSE				= 0;		{ Connection is open/available }

{ values for SQL_ATTR_ANSI_APP }
{
#if (ODBCVER >= 0x0351)
  SQL_AA_TRUE					1L;	 // the application is an ANSI app
  SQL_AA_FALSE					0L;	// the application is a Unicode app
#endif
}
  SQL_NO_DATA_FOUND =	SQL_NO_DATA;

// SQL_NULL_COLLATION values
  SQL_NC_START                        = $0002;
  SQL_NC_END                          = $0004;


{******************************************}
{ SQLGetFunctions: additional values for   }
{ fFunction to represent functions that    }
{ are not in the X/Open spec.				       }
{******************************************}

////#if (ODBCVER >= = $0300)
  SQL_API_SQLALLOCHANDLESTD	= 73;
  SQL_API_SQLBULKOPERATIONS	= 24;
////#endif { ODBCVER >= = $0300 }
  SQL_API_SQLBINDPARAMETER  = 72;
  SQL_API_SQLBROWSECONNECT  = 55;
  SQL_API_SQLCOLATTRIBUTES  = 6;
  SQL_API_SQLCOLUMNPRIVILEGES = 56;
  SQL_API_SQLDESCRIBEPARAM    = 58;
 	SQL_API_SQLDRIVERCONNECT    =	41;
  SQL_API_SQLDRIVERS          = 71;
  SQL_API_SQLEXTENDEDFETCH    = 59;
  SQL_API_SQLFOREIGNKEYS      = 60;
  SQL_API_SQLMORERESULTS      = 61;
  SQL_API_SQLNATIVESQL        = 62;
  SQL_API_SQLNUMPARAMS        = 63;
  SQL_API_SQLPARAMOPTIONS     = 64;
  SQL_API_SQLPRIMARYKEYS      = 65;
  SQL_API_SQLPROCEDURECOLUMNS = 66;
  SQL_API_SQLPROCEDURES       = 67;
  SQL_API_SQLSETPOS           = 68;
  SQL_API_SQLSETSCROLLOPTIONS = 69;
  SQL_API_SQLTABLEPRIVILEGES  = 70;

{
{-------------------------------------------}
{ SQL_EXT_API_LAST is not useful with ODBC  }
{ version 3.0 because some of the values    }
{ from X/Open are in the 10000 range.       }
{-------------------------------------------}

////#if (ODBCVER < = $0300)
  SQL_EXT_API_LAST            = SQL_API_SQLBINDPARAMETER;
  SQL_NUM_FUNCTIONS           = 23;
  SQL_EXT_API_START           = 40;
  SQL_NUM_EXTENSIONS = (SQL_EXT_API_LAST-SQL_EXT_API_START+1);
////#endif

{***************************************************}
{ Extended definitions for SQLGetInfo from SQLEXT.H }
{***************************************************}

{---------------------------------}
{ Values in ODBC 2.0 that are not }
{ in the X/Open spec              }
{---------------------------------}

  SQL_INFO_FIRST                   =    0;
  SQL_ACTIVE_CONNECTIONS           =    0;	{ MAX_DRIVER_CONNECTIONS }
  SQL_ACTIVE_STATEMENTS            =    1;	{ MAX_CONCURRENT_ACTIVITIES }
  SQL_DRIVER_HDBC                  =    3;
  SQL_DRIVER_HENV                  =    4;
  SQL_DRIVER_HSTMT                 =    5;
  SQL_DRIVER_NAME                  =    6;
  SQL_DRIVER_VER                   =    7;
  SQL_ODBC_API_CONFORMANCE         =    9;
  SQL_ODBC_VER                     =   10;
  SQL_ROW_UPDATES                  =   11;
  SQL_ODBC_SAG_CLI_CONFORMANCE     =   12;
  SQL_ODBC_SQL_CONFORMANCE         =   15;
  SQL_DATABASE_NAME                =   16;
  SQL_PROCEDURES                   =   21;
  SQL_CONCAT_NULL_BEHAVIOR         =   22;
  SQL_CURSOR_ROLLBACK_BEHAVIOR     =   24;
  SQL_EXPRESSIONS_IN_ORDERBY       =   27;
  SQL_MAX_OWNER_NAME_LEN           =   32;	{ MAX_SCHEMA_NAME_LEN }
  SQL_MAX_PROCEDURE_NAME_LEN       =   33;
  SQL_MAX_QUALIFIER_NAME_LEN       =   34;	{ MAX_CATALOG_NAME_LEN }
  SQL_MULT_RESULT_SETS             =   36;
  SQL_MULTIPLE_ACTIVE_TXN          =   37;
  SQL_OUTER_JOINS                  =   38;
  SQL_OWNER_TERM                   =   39;
  SQL_PROCEDURE_TERM               =   40;
  SQL_QUALIFIER_NAME_SEPARATOR     =   41;
  SQL_QUALIFIER_TERM               =   42;
  SQL_SCROLL_OPTIONS               =   44;
  SQL_TABLE_TERM                   =   45;
  SQL_CONVERT_FUNCTIONS            =   48;
  SQL_NUMERIC_FUNCTIONS            =   49;
  SQL_STRING_FUNCTIONS             =   50;
  SQL_SYSTEM_FUNCTIONS             =   51;
  SQL_TIMEDATE_FUNCTIONS           =   52;
  SQL_CONVERT_BIGINT               =   53;
  SQL_CONVERT_BINARY               =   54;
  SQL_CONVERT_BIT                  =   55;
  SQL_CONVERT_CHAR                 =   56;
  SQL_CONVERT_DATE                 =   57;
  SQL_CONVERT_DECIMAL              =   58;
  SQL_CONVERT_DOUBLE               =   59;
  SQL_CONVERT_FLOAT                =   60;
  SQL_CONVERT_INTEGER              =   61;
  SQL_CONVERT_LONGVARCHAR          =   62;
  SQL_CONVERT_NUMERIC              =   63;
  SQL_CONVERT_REAL                 =   64;
  SQL_CONVERT_SMALLINT             =   65;
  SQL_CONVERT_TIME                 =   66;
  SQL_CONVERT_TIMESTAMP            =   67;
  SQL_CONVERT_TINYINT              =   68;
  SQL_CONVERT_VARBINARY            =   69;
  SQL_CONVERT_VARCHAR              =   70;
  SQL_CONVERT_LONGVARBINARY        =   71;
  SQL_ODBC_SQL_OPT_IEF             =   73;		{ SQL_INTEGRITY }
  SQL_CORRELATION_NAME             =   74;
  SQL_NON_NULLABLE_COLUMNS         =   75;
  SQL_DRIVER_HLIB                  =   76;
  SQL_DRIVER_ODBC_VER              =   77;
  SQL_LOCK_TYPES                   =   78;
  SQL_POS_OPERATIONS               =   79;
  SQL_POSITIONED_STATEMENTS        =   80;
  SQL_BOOKMARK_PERSISTENCE         =   82;
  SQL_STATIC_SENSITIVITY           =   83;
  SQL_FILE_USAGE                   =   84;
  SQL_COLUMN_ALIAS                 =   87;
  SQL_GROUP_BY                     =   88;
  SQL_KEYWORDS                     =   89;
  SQL_OWNER_USAGE                  =   91;
  SQL_QUALIFIER_USAGE              =   92;
  SQL_QUOTED_IDENTIFIER_CASE       =   93;
  SQL_SUBQUERIES                   =   95;
  SQL_UNION                        =   96;
  SQL_MAX_ROW_SIZE_INCLUDES_LONG   =   103;
  SQL_MAX_CHAR_LITERAL_LEN         =   108;
  SQL_TIMEDATE_ADD_INTERVALS       =   109;
  SQL_TIMEDATE_DIFF_INTERVALS      =   110;
  SQL_NEED_LONG_DATA_LEN           =   111;
  SQL_MAX_BINARY_LITERAL_LEN       =   112;
  SQL_LIKE_ESCAPE_CLAUSE           =   113;
  SQL_QUALIFIER_LOCATION           =   114;

////#if (ODBCVER >= = $0201 && ODBCVER < = $0300)
  SQL_OJ_CAPABILITIES         = 65003;  { Temp value until ODBC 3.0 }
////#endif  { ODBCVER >= = $0201 && ODBCVER < = $0300 }

{----------------------------------------------}
{ SQL_INFO_LAST and SQL_INFO_DRIVER_START are  }
{ not useful anymore, because  X/Open has      }
{ values in the 10000 range.   You  			}
{ must contact X/Open directly to get a range	}
{ of numbers for driver-specific values.	    }
{----------------------------------------------}
////#if (ODBCVER < = $0300)
  SQL_INFO_LAST				 =		SQL_QUALIFIER_LOCATION;
  SQL_CATALOG_LOCATION =		SQL_QUALIFIER_LOCATION;
  SQL_INFO_DRIVER_START			 =	1000              ;
////#endif { ODBCVER < = $0300 }
{
{-----------------------------------------------}
{ ODBC 3.0 SQLGetInfo values that are not part  }
{ of the X/Open standard at this time.   X/Open }
{ standard values are in sql.h.				 }
{-----------------------------------------------}

//#if (ODBCVER >= = $0300)
  SQL_ACTIVE_ENVIRONMENTS			=		116;
 	SQL_ALTER_DOMAIN						= 117    ;

 	SQL_SQL_CONFORMANCE					 =	118  ;
  SQL_DATETIME_LITERALS				 =	119  ;

 	SQL_ASYNC_MODE							=10021	 ;{ new X/Open spec }
  SQL_BATCH_ROW_COUNT					 =	120  ;
  SQL_BATCH_SUPPORT						=121    ;
//  SQL_CATALOG_LOCATION				 =	SQL_QUALIFIER_LOCATION;
  SQL_CATALOG_NAME_SEPARATOR	=			SQL_QUALIFIER_NAME_SEPARATOR;
  SQL_CATALOG_TERM						=SQL_QUALIFIER_TERM                 ;
  SQL_CATALOG_USAGE						=SQL_QUALIFIER_USAGE                ;
 	SQL_CONVERT_WCHAR						=122                                ;
  SQL_CONVERT_INTERVAL_DAY_TIME			=123                          ;
  SQL_CONVERT_INTERVAL_YEAR_MONTH			=124                        ;
 	SQL_CONVERT_WLONGVARCHAR		 =		125                            ;
 	SQL_CONVERT_WVARCHAR				=	126                              ;
 	SQL_CREATE_ASSERTION				=	127                              ;
 	SQL_CREATE_CHARACTER_SET		=		128                            ;
 	SQL_CREATE_COLLATION				=	129                              ;
 	SQL_CREATE_DOMAIN						=130                                ;
 	SQL_CREATE_SCHEMA						=131                                ;
 	SQL_CREATE_TABLE						=132                                ;
 	SQL_CREATE_TRANSLATION			=		133                            ;
 	SQL_CREATE_VIEW							=134                                ;
  SQL_DRIVER_HDESC						=135                                ;
 	SQL_DROP_ASSERTION					=	136                              ;
 	SQL_DROP_CHARACTER_SET			=		137                            ;
 	SQL_DROP_COLLATION					=	138                              ;
 	SQL_DROP_DOMAIN							=139                                ;
 	SQL_DROP_SCHEMA							=140                                ;
 	SQL_DROP_TABLE							=141                                ;
 	SQL_DROP_TRANSLATION			 =		142                              ;
 	SQL_DROP_VIEW							=143                                  ;
  SQL_DYNAMIC_CURSOR_ATTRIBUTES1			=144                        ;
  SQL_DYNAMIC_CURSOR_ATTRIBUTES2			=145                        ;
  SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1		=146                      ;
  SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2		=147                      ;
  SQL_INDEX_KEYWORDS						=148                              ;
  SQL_INFO_SCHEMA_VIEWS					=149                              ;
  SQL_KEYSET_CURSOR_ATTRIBUTES1			=150                          ;
  SQL_KEYSET_CURSOR_ATTRIBUTES2			=151                          ;
 	SQL_MAX_ASYNC_CONCURRENT_STATEMENTS		=10022	{ new X/Open spec };
  SQL_ODBC_INTERFACE_CONFORMANCE =			152                        ;
  SQL_PARAM_ARRAY_ROW_COUNTS    = 			153                        ;
  SQL_PARAM_ARRAY_SELECTS      =			154                          ;
  SQL_SCHEMA_TERM							=SQL_OWNER_TERM                     ;
  SQL_SCHEMA_USAGE						=SQL_OWNER_USAGE                    ;
  SQL_SQL92_DATETIME_FUNCTIONS			=155                          ;
  SQL_SQL92_FOREIGN_KEY_DELETE_RULE		=156                        ;
  SQL_SQL92_FOREIGN_KEY_UPDATE_RULE		=157                        ;
  SQL_SQL92_GRANT							=158                                ;
  SQL_SQL92_NUMERIC_VALUE_FUNCTIONS		=159                        ;
  SQL_SQL92_PREDICATES					=160                              ;
  SQL_SQL92_RELATIONAL_JOIN_OPERATORS		=161                      ;
  SQL_SQL92_REVOKE					 =	162                                ;
  SQL_SQL92_ROW_VALUE_CONSTRUCTOR		=	163                        ;
  SQL_SQL92_STRING_FUNCTIONS				=164                          ;
  SQL_SQL92_VALUE_EXPRESSIONS				=165                          ;
  SQL_STANDARD_CLI_CONFORMANCE			=166                          ;
  SQL_STATIC_CURSOR_ATTRIBUTES1			=167                          ;
  SQL_STATIC_CURSOR_ATTRIBUTES2			=168                          ;

  SQL_AGGREGATE_FUNCTIONS	 =				169;
  SQL_DDL_INDEX						=	170      ;
  SQL_DM_VER							=	171      ;
  SQL_INSERT_STATEMENT					=172  ;
  SQL_UNION_STATEMENT						=SQL_UNION;
//#endif  { ODBCVER >= = $0300 }

 	SQL_DTC_TRANSITION_COST				 =	1750    ;

{ SQL_ALTER_TABLE bitmasks }
//#if (ODBCVER >= = $0300)
{ the following 5 bitmasks are defined in sql.h
*  SQL_AT_ADD_COLUMN                   	= $00000001;
*  SQL_AT_DROP_COLUMN                  	= $00000002;
*  SQL_AT_ADD_CONSTRAINT               	= $00000008;
}
 	SQL_AT_ADD_COLUMN_SINGLE				= $00000020;
 	SQL_AT_ADD_COLUMN_DEFAULT				= $00000040;
 	SQL_AT_ADD_COLUMN_COLLATION				= $00000080;
 	SQL_AT_SET_COLUMN_DEFAULT				= $00000100;
 	SQL_AT_DROP_COLUMN_DEFAULT				= $00000200;
 	SQL_AT_DROP_COLUMN_CASCADE				= $00000400;
 	SQL_AT_DROP_COLUMN_RESTRICT				= $00000800;
  SQL_AT_ADD_TABLE_CONSTRAINT				= $00001000;
  SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE	= $00002000;
  SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT	= $00004000;
  SQL_AT_CONSTRAINT_NAME_DEFINITION		= $00008000;
  SQL_AT_CONSTRAINT_INITIALLY_DEFERRED	= $00010000;
  SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE	= $00020000;
  SQL_AT_CONSTRAINT_DEFERRABLE			= $00040000;
  SQL_AT_CONSTRAINT_NON_DEFERRABLE		= $00080000;
//#endif	{ ODBCVER >= = $0300 }

{ SQL_CONVERT_*  return value bitmasks }

  SQL_CVT_CHAR                        = $00000001;
  SQL_CVT_NUMERIC                     = $00000002;
  SQL_CVT_DECIMAL                     = $00000004;
  SQL_CVT_INTEGER                     = $00000008;
  SQL_CVT_SMALLINT                    = $00000010;
  SQL_CVT_FLOAT                       = $00000020;
  SQL_CVT_REAL                        = $00000040;
  SQL_CVT_DOUBLE                      = $00000080;
  SQL_CVT_VARCHAR                     = $00000100;
  SQL_CVT_LONGVARCHAR                 = $00000200;
  SQL_CVT_BINARY                      = $00000400;
  SQL_CVT_VARBINARY                   = $00000800;
  SQL_CVT_BIT                         = $00001000;
  SQL_CVT_TINYINT                     = $00002000;
  SQL_CVT_BIGINT                      = $00004000;
  SQL_CVT_DATE                        = $00008000;
  SQL_CVT_TIME                        = $00010000;
  SQL_CVT_TIMESTAMP                   = $00020000;
  SQL_CVT_LONGVARBINARY               = $00040000;
//#if (ODBCVER >= = $0300)
  SQL_CVT_INTERVAL_YEAR_MONTH	    	= $00080000;
  SQL_CVT_INTERVAL_DAY_TIME	    	= $00100000;
 	SQL_CVT_WCHAR						= $00200000;
 	SQL_CVT_WLONGVARCHAR				= $00400000;
 	SQL_CVT_WVARCHAR					= $00800000;
//#endif  { ODBCVER >= = $0300 }

{ SQL_CONVERT_FUNCTIONS functions }
  SQL_FN_CVT_CONVERT                  = $00000001;
//#if (ODBCVER >= = $0300)
  SQL_FN_CVT_CAST						= $00000002;
//#endif  { ODBCVER >= = $0300 }

{ SQL_STRING_FUNCTIONS functions }
  SQL_FN_STR_CONCAT                   = $00000001;
  SQL_FN_STR_INSERT                   = $00000002;
  SQL_FN_STR_LEFT                     = $00000004;
  SQL_FN_STR_LTRIM                    = $00000008;
  SQL_FN_STR_LENGTH                   = $00000010;
  SQL_FN_STR_LOCATE                   = $00000020;
  SQL_FN_STR_LCASE                    = $00000040;
  SQL_FN_STR_REPEAT                   = $00000080;
  SQL_FN_STR_REPLACE                  = $00000100;
  SQL_FN_STR_RIGHT                    = $00000200;
  SQL_FN_STR_RTRIM                    = $00000400;
  SQL_FN_STR_SUBSTRING                = $00000800;
  SQL_FN_STR_UCASE                    = $00001000;
  SQL_FN_STR_ASCII                    = $00002000;
  SQL_FN_STR_CHAR                     = $00004000;
  SQL_FN_STR_DIFFERENCE               = $00008000;
  SQL_FN_STR_LOCATE_2                 = $00010000;
  SQL_FN_STR_SOUNDEX                  = $00020000;
  SQL_FN_STR_SPACE                    = $00040000;
////#if (ODBCVER >= = $0300)
  SQL_FN_STR_BIT_LENGTH				= $00080000;
  SQL_FN_STR_CHAR_LENGTH				= $00100000;
  SQL_FN_STR_CHARACTER_LENGTH			= $00200000;
  SQL_FN_STR_OCTET_LENGTH				= $00400000;
  SQL_FN_STR_POSITION					= $00800000;
////#endif  { ODBCVER >= = $0300 }

{ SQL_SQL92_STRING_FUNCTIONS }
////#if (ODBCVER >= = $0300)
  SQL_SSF_CONVERT						= $00000001;
  SQL_SSF_LOWER						= $00000002;
  SQL_SSF_UPPER						= $00000004;
  SQL_SSF_SUBSTRING					= $00000008;
  SQL_SSF_TRANSLATE					= $00000010;
  SQL_SSF_TRIM_BOTH					= $00000020;
  SQL_SSF_TRIM_LEADING				= $00000040;
  SQL_SSF_TRIM_TRAILING				= $00000080;
//#endif { ODBCVER >= = $0300 }

{ SQL_NUMERIC_FUNCTIONS functions }

  SQL_FN_NUM_ABS                      = $00000001;
  SQL_FN_NUM_ACOS                     = $00000002;
  SQL_FN_NUM_ASIN                     = $00000004;
  SQL_FN_NUM_ATAN                     = $00000008;
  SQL_FN_NUM_ATAN2                    = $00000010;
  SQL_FN_NUM_CEILING                  = $00000020;
  SQL_FN_NUM_COS                      = $00000040;
  SQL_FN_NUM_COT                      = $00000080;
  SQL_FN_NUM_EXP                      = $00000100;
  SQL_FN_NUM_FLOOR                    = $00000200;
  SQL_FN_NUM_LOG                      = $00000400;
  SQL_FN_NUM_MOD                      = $00000800;
  SQL_FN_NUM_SIGN                     = $00001000;
  SQL_FN_NUM_SIN                      = $00002000;
  SQL_FN_NUM_SQRT                     = $00004000;
  SQL_FN_NUM_TAN                      = $00008000;
  SQL_FN_NUM_PI                       = $00010000;
  SQL_FN_NUM_RAND                     = $00020000;
  SQL_FN_NUM_DEGREES                  = $00040000;
  SQL_FN_NUM_LOG10                    = $00080000;
  SQL_FN_NUM_POWER                    = $00100000;
  SQL_FN_NUM_RADIANS                  = $00200000;
  SQL_FN_NUM_ROUND                    = $00400000;
  SQL_FN_NUM_TRUNCATE                 = $00800000;

{ SQL_SQL92_NUMERIC_VALUE_FUNCTIONS }
//#if (ODBCVER >= = $0300)
  SQL_SNVF_BIT_LENGTH					= $00000001;
  SQL_SNVF_CHAR_LENGTH				= $00000002;
  SQL_SNVF_CHARACTER_LENGTH			= $00000004;
  SQL_SNVF_EXTRACT					= $00000008;
  SQL_SNVF_OCTET_LENGTH				= $00000010;
  SQL_SNVF_POSITION					= $00000020;
//#endif  { ODBCVER >= = $0300 }

{ SQL_TIMEDATE_FUNCTIONS functions }

  SQL_FN_TD_NOW                       = $00000001;
  SQL_FN_TD_CURDATE                   = $00000002;
  SQL_FN_TD_DAYOFMONTH                = $00000004;
  SQL_FN_TD_DAYOFWEEK                 = $00000008;
  SQL_FN_TD_DAYOFYEAR                 = $00000010;
  SQL_FN_TD_MONTH                     = $00000020;
  SQL_FN_TD_QUARTER                   = $00000040;
  SQL_FN_TD_WEEK                      = $00000080;
  SQL_FN_TD_YEAR                      = $00000100;
  SQL_FN_TD_CURTIME                   = $00000200;
  SQL_FN_TD_HOUR                      = $00000400;
  SQL_FN_TD_MINUTE                    = $00000800;
  SQL_FN_TD_SECOND                    = $00001000;
  SQL_FN_TD_TIMESTAMPADD              = $00002000;
  SQL_FN_TD_TIMESTAMPDIFF             = $00004000;
  SQL_FN_TD_DAYNAME                   = $00008000;
  SQL_FN_TD_MONTHNAME                 = $00010000;
//#if (ODBCVER >= = $0300)
  SQL_FN_TD_CURRENT_DATE				= $00020000;
  SQL_FN_TD_CURRENT_TIME				= $00040000;
  SQL_FN_TD_CURRENT_TIMESTAMP			= $00080000;
  SQL_FN_TD_EXTRACT					= $00100000;
//#endif  { ODBCVER >= = $0300 }

{ SQL_SQL92_DATETIME_FUNCTIONS }
//#if (ODBCVER >= = $0300)
  SQL_SDF_CURRENT_DATE				= $00000001;
  SQL_SDF_CURRENT_TIME				= $00000002;
  SQL_SDF_CURRENT_TIMESTAMP			= $00000004;
//#endif { ODBCVER >= = $0300 }

{ SQL_SYSTEM_FUNCTIONS functions }

  SQL_FN_SYS_USERNAME                 = $00000001;
  SQL_FN_SYS_DBNAME                   = $00000002;
  SQL_FN_SYS_IFNULL                   = $00000004;

{ SQL_TIMEDATE_ADD_INTERVALS and SQL_TIMEDATE_DIFF_INTERVALS functions }

  SQL_FN_TSI_FRAC_SECOND              = $00000001;
  SQL_FN_TSI_SECOND                   = $00000002;
  SQL_FN_TSI_MINUTE                   = $00000004;
  SQL_FN_TSI_HOUR                     = $00000008;
  SQL_FN_TSI_DAY                      = $00000010;
  SQL_FN_TSI_WEEK                     = $00000020;
  SQL_FN_TSI_MONTH                    = $00000040;
  SQL_FN_TSI_QUARTER                  = $00000080;
  SQL_FN_TSI_YEAR                     = $00000100;

{ bitmasks for SQL_DYNAMIC_CURSOR_ATTRIBUTES1,
 * SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1,
 * SQL_KEYSET_CURSOR_ATTRIBUTES1, and SQL_STATIC_CURSOR_ATTRIBUTES1
 }
//#if (ODBCVER >= = $0300)
{ supported SQLFetchScroll FetchOrientation's }
  SQL_CA1_NEXT						= $00000001;
  SQL_CA1_ABSOLUTE					= $00000002;
  SQL_CA1_RELATIVE					= $00000004;
  SQL_CA1_BOOKMARK					= $00000008;

{ supported SQLSetPos LockType's }
  SQL_CA1_LOCK_NO_CHANGE				= $00000040;
  SQL_CA1_LOCK_EXCLUSIVE				= $00000080;
  SQL_CA1_LOCK_UNLOCK					= $00000100;

{ supported SQLSetPos Operations }
  SQL_CA1_POS_POSITION				= $00000200;
  SQL_CA1_POS_UPDATE					= $00000400;
  SQL_CA1_POS_DELETE					= $00000800;
  SQL_CA1_POS_REFRESH					= $00001000;

{ positioned updates and deletes }
  SQL_CA1_POSITIONED_UPDATE			= $00002000;
  SQL_CA1_POSITIONED_DELETE			= $00004000;
  SQL_CA1_SELECT_FOR_UPDATE			= $00008000;

{ supported SQLBulkOperations operations }
  SQL_CA1_BULK_ADD					= $00010000;
  SQL_CA1_BULK_UPDATE_BY_BOOKMARK		= $00020000;
  SQL_CA1_BULK_DELETE_BY_BOOKMARK		= $00040000;
  SQL_CA1_BULK_FETCH_BY_BOOKMARK		= $00080000;
//#endif  { ODBCVER >= = $0300 }

{ bitmasks for SQL_DYNAMIC_CURSOR_ATTRIBUTES2,
 * SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2,
 * SQL_KEYSET_CURSOR_ATTRIBUTES2, and SQL_STATIC_CURSOR_ATTRIBUTES2
 }
//#if (ODBCVER >= = $0300)
{ supported values for SQL_ATTR_SCROLL_CONCURRENCY }
  SQL_CA2_READ_ONLY_CONCURRENCY		= $00000001;
  SQL_CA2_LOCK_CONCURRENCY			= $00000002;
  SQL_CA2_OPT_ROWVER_CONCURRENCY		= $00000004;
  SQL_CA2_OPT_VALUES_CONCURRENCY		= $00000008;

{ sensitivity of the cursor to its own inserts, deletes, and updates }
  SQL_CA2_SENSITIVITY_ADDITIONS		= $00000010;
  SQL_CA2_SENSITIVITY_DELETIONS		= $00000020;
  SQL_CA2_SENSITIVITY_UPDATES			= $00000040;

{ semantics of SQL_ATTR_MAX_ROWS }
  SQL_CA2_MAX_ROWS_SELECT				= $00000080;
  SQL_CA2_MAX_ROWS_INSERT				= $00000100;
  SQL_CA2_MAX_ROWS_DELETE				= $00000200;
  SQL_CA2_MAX_ROWS_UPDATE				= $00000400;
  SQL_CA2_MAX_ROWS_CATALOG			= $00000800;
{
  SQL_CA2_MAX_ROWS_AFFECTS_ALL	 =	(SQL_CA2_MAX_ROWS_SELECT | \
					SQL_CA2_MAX_ROWS_INSERT | SQL_CA2_MAX_ROWS_DELETE | \
					SQL_CA2_MAX_ROWS_UPDATE | SQL_CA2_MAX_ROWS_CATALOG)
}

{ semantics of SQL_DIAG_CURSOR_ROW_COUNT }
  SQL_CA2_CRC_EXACT					= $00001000;
  SQL_CA2_CRC_APPROXIMATE				= $00002000;

{ the kinds of positioned statements that can be simulated }
  SQL_CA2_SIMULATE_NON_UNIQUE			= $00004000;
  SQL_CA2_SIMULATE_TRY_UNIQUE			= $00008000;
  SQL_CA2_SIMULATE_UNIQUE				= $00010000;
//#endif  { ODBCVER >= = $0300 }

{ SQL_ODBC_API_CONFORMANCE values }

  SQL_OAC_NONE                        = $0000;
  SQL_OAC_LEVEL1                      = $0001;
  SQL_OAC_LEVEL2                      = $0002;

{ SQL_ODBC_SAG_CLI_CONFORMANCE values }

  SQL_OSCC_NOT_COMPLIANT              = $0000;
  SQL_OSCC_COMPLIANT                  = $0001;

{ SQL_ODBC_SQL_CONFORMANCE values }

  SQL_OSC_MINIMUM                     = $0000;
  SQL_OSC_CORE                        = $0001;
  SQL_OSC_EXTENDED                    = $0002;


{ SQL_CONCAT_NULL_BEHAVIOR values }

  SQL_CB_NULL                         = $0000;
  SQL_CB_NON_NULL                     = $0001;

{ SQL_SCROLL_OPTIONS masks }

  SQL_SO_FORWARD_ONLY                 = $00000001;
  SQL_SO_KEYSET_DRIVEN                = $00000002;
  SQL_SO_DYNAMIC                      = $00000004;
  SQL_SO_MIXED                        = $00000008;
  SQL_SO_STATIC                       = $00000010;

{ SQL_FETCH_DIRECTION masks }

{ SQL_FETCH_RESUME is no longer supported
  SQL_FD_FETCH_RESUME                 = $00000040;
}
  SQL_FD_FETCH_BOOKMARK               = $00000080;

{ SQL_TXN_ISOLATION_OPTION masks }
{ SQL_TXN_VERSIONING is no longer supported
  SQL_TXN_VERSIONING                  = $00000010;
}

{ SQL_CORRELATION_NAME values }

  SQL_CN_NONE                         = $0000;
  SQL_CN_DIFFERENT                    = $0001;
  SQL_CN_ANY                          = $0002;

{ SQL_NON_NULLABLE_COLUMNS values }

  SQL_NNC_NULL                        = $0000;
  SQL_NNC_NON_NULL                    = $0001;


{ SQL_NULL_COLLATION values }
{
  SQL_NC_START                        = $0002;
  SQL_NC_END                          = $0004;
}

{ SQL_FILE_USAGE values }

  SQL_FILE_NOT_SUPPORTED              = $0000;
  SQL_FILE_TABLE                      = $0001;
  SQL_FILE_QUALIFIER                  = $0002;
  SQL_FILE_CATALOG					=SQL_FILE_QUALIFIER;	// ODBC 3.0


{ SQL_GETDATA_EXTENSIONS values }

  SQL_GD_BLOCK                        = $00000004;
  SQL_GD_BOUND                        = $00000008;

{ SQL_POSITIONED_STATEMENTS masks }

  SQL_PS_POSITIONED_DELETE            = $00000001;
  SQL_PS_POSITIONED_UPDATE            = $00000002;
  SQL_PS_SELECT_FOR_UPDATE            = $00000004;

{ SQL_GROUP_BY values }

  SQL_GB_NOT_SUPPORTED                = $0000;
  SQL_GB_GROUP_BY_EQUALS_SELECT       = $0001;
  SQL_GB_GROUP_BY_CONTAINS_SELECT     = $0002;
  SQL_GB_NO_RELATION                  = $0003;
//#if (ODBCVER >= = $0300)
 	SQL_GB_COLLATE						= $0004           ;

//#endif  { ODBCVER >= = $0300 }

{ SQL_OWNER_USAGE masks }

  SQL_OU_DML_STATEMENTS               = $00000001;
  SQL_OU_PROCEDURE_INVOCATION         = $00000002;
  SQL_OU_TABLE_DEFINITION             = $00000004;
  SQL_OU_INDEX_DEFINITION             = $00000008;
  SQL_OU_PRIVILEGE_DEFINITION         = $00000010;

{ SQL_SCHEMA_USAGE masks }
//#if (ODBCVER >= = $0300)
{
  SQL_SU_DML_STATEMENTS			SQL_OU_DML_STATEMENTS
  SQL_SU_PROCEDURE_INVOCATION		SQL_OU_PROCEDURE_INVOCATION
  SQL_SU_TABLE_DEFINITION			SQL_OU_TABLE_DEFINITION
  SQL_SU_INDEX_DEFINITION			SQL_OU_INDEX_DEFINITION
  SQL_SU_PRIVILEGE_DEFINITION		SQL_OU_PRIVILEGE_DEFINITION
}
//#endif  { ODBCVER >= = $0300 }

{ SQL_QUALIFIER_USAGE masks }

  SQL_QU_DML_STATEMENTS               = $00000001;
  SQL_QU_PROCEDURE_INVOCATION         = $00000002;
  SQL_QU_TABLE_DEFINITION             = $00000004;
  SQL_QU_INDEX_DEFINITION             = $00000008;
  SQL_QU_PRIVILEGE_DEFINITION         = $00000010;

//#if (ODBCVER >= = $0300)
{ SQL_CATALOG_USAGE masks }
{
  SQL_CU_DML_STATEMENTS			SQL_QU_DML_STATEMENTS
  SQL_CU_PROCEDURE_INVOCATION		SQL_QU_PROCEDURE_INVOCATION
  SQL_CU_TABLE_DEFINITION			SQL_QU_TABLE_DEFINITION
  SQL_CU_INDEX_DEFINITION			SQL_QU_INDEX_DEFINITION
  SQL_CU_PRIVILEGE_DEFINITION		SQL_QU_PRIVILEGE_DEFINITION
}
//#endif  { ODBCVER >= = $0300 }

{ SQL_SUBQUERIES masks }

  SQL_SQ_COMPARISON                   = $00000001;
  SQL_SQ_EXISTS                       = $00000002;
  SQL_SQ_IN                           = $00000004;
  SQL_SQ_QUANTIFIED                   = $00000008;
  SQL_SQ_CORRELATED_SUBQUERIES        = $00000010;

{ SQL_UNION masks }

  SQL_U_UNION                         = $00000001;
  SQL_U_UNION_ALL                     = $00000002;

{ SQL_BOOKMARK_PERSISTENCE values }

  SQL_BP_CLOSE                        = $00000001;
  SQL_BP_DELETE                       = $00000002;
  SQL_BP_DROP                         = $00000004;
  SQL_BP_TRANSACTION                  = $00000008;
  SQL_BP_UPDATE                       = $00000010;
  SQL_BP_OTHER_HSTMT                  = $00000020;
  SQL_BP_SCROLL                       = $00000040;

{ SQL_STATIC_SENSITIVITY values }

  SQL_SS_ADDITIONS                    = $00000001;
  SQL_SS_DELETIONS                    = $00000002;
  SQL_SS_UPDATES                      = $00000004;

{ SQL_VIEW values }
 	SQL_CV_CREATE_VIEW					= $00000001;
 	SQL_CV_CHECK_OPTION					= $00000002;
 	SQL_CV_CASCADED						= $00000004;
 	SQL_CV_LOCAL						= $00000008;

{ SQL_LOCK_TYPES masks }

  SQL_LCK_NO_CHANGE                   = $00000001;
  SQL_LCK_EXCLUSIVE                   = $00000002;
  SQL_LCK_UNLOCK                      = $00000004;

{ SQL_POS_OPERATIONS masks }

  SQL_POS_POSITION                    = $00000001;
  SQL_POS_REFRESH                     = $00000002;
  SQL_POS_UPDATE                      = $00000004;
  SQL_POS_DELETE                      = $00000008;
  SQL_POS_ADD                         = $00000010;

{ SQL_QUALIFIER_LOCATION values }

  SQL_QL_START                        = $0001;
  SQL_QL_END                          = $0002;

{ Here start return values for ODBC 3.0 SQLGetInfo }

//#if (ODBCVER >= = $0300)
{ SQL_AGGREGATE_FUNCTIONS bitmasks }
  SQL_AF_AVG						= $00000001;
  SQL_AF_COUNT					= $00000002;
  SQL_AF_MAX						= $00000004;
  SQL_AF_MIN						= $00000008;
  SQL_AF_SUM						= $00000010;
  SQL_AF_DISTINCT					= $00000020;
  SQL_AF_ALL						= $00000040;	

{ SQL_SQL_CONFORMANCE bit masks }
 	SQL_SC_SQL92_ENTRY				= $00000001;
 	SQL_SC_FIPS127_2_TRANSITIONAL	= $00000002;
 	SQL_SC_SQL92_INTERMEDIATE		= $00000004;
 	SQL_SC_SQL92_FULL				= $00000008;

{ SQL_DATETIME_LITERALS masks }
  SQL_DL_SQL92_DATE						= $00000001;
  SQL_DL_SQL92_TIME						= $00000002;
  SQL_DL_SQL92_TIMESTAMP					= $00000004;
  SQL_DL_SQL92_INTERVAL_YEAR				= $00000008;
  SQL_DL_SQL92_INTERVAL_MONTH				= $00000010;
  SQL_DL_SQL92_INTERVAL_DAY				= $00000020;
  SQL_DL_SQL92_INTERVAL_HOUR				= $00000040;
 	SQL_DL_SQL92_INTERVAL_MINUTE			= $00000080;
  SQL_DL_SQL92_INTERVAL_SECOND			= $00000100;
  SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH		= $00000200;
  SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR		= $00000400;
  SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE		= $00000800;
  SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND		= $00001000;
  SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE	= $00002000;
  SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND	= $00004000;
  SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND	= $00008000;

{ SQL_CATALOG_LOCATION values }
  SQL_CL_START			 =			SQL_QL_START;
  SQL_CL_END				 =			SQL_QL_END  ;

{ values for SQL_BATCH_ROW_COUNT }
  SQL_BRC_PROCEDURES			= $0000001;
 	SQL_BRC_EXPLICIT			= $0000002  ;
 	SQL_BRC_ROLLED_UP			= $0000004  ;

{ bitmasks for SQL_BATCH_SUPPORT }
  SQL_BS_SELECT_EXPLICIT				= $00000001;
  SQL_BS_ROW_COUNT_EXPLICIT			= $00000002;
  SQL_BS_SELECT_PROC					= $00000004;
  SQL_BS_ROW_COUNT_PROC				= $00000008;

{ Values for SQL_PARAM_ARRAY_ROW_COUNTS getinfo }
  SQL_PARC_BATCH		= 1 ;
  SQL_PARC_NO_BATCH	= 2 ;

{ values for SQL_PARAM_ARRAY_SELECTS }
  SQL_PAS_BATCH				= 1;
  SQL_PAS_NO_BATCH		= 2;
  SQL_PAS_NO_SELECT		= 3;

{ Bitmasks for SQL_INDEX_KEYWORDS }
  SQL_IK_NONE							= $00000000;
  SQL_IK_ASC							= $00000001;
  SQL_IK_DESC							= $00000002;
{
  SQL_IK_ALL							= (SQL_IK_ASC | SQL_IK_DESC);
}
{ Bitmasks for SQL_INFO_SCHEMA_VIEWS }

  SQL_ISV_ASSERTIONS					= $00000001;
  SQL_ISV_CHARACTER_SETS				= $00000002;
  SQL_ISV_CHECK_CONSTRAINTS			= $00000004;
  SQL_ISV_COLLATIONS					= $00000008;
  SQL_ISV_COLUMN_DOMAIN_USAGE			= $00000010;
  SQL_ISV_COLUMN_PRIVILEGES			= $00000020;
  SQL_ISV_COLUMNS						= $00000040;
  SQL_ISV_CONSTRAINT_COLUMN_USAGE		= $00000080;
  SQL_ISV_CONSTRAINT_TABLE_USAGE		= $00000100;
  SQL_ISV_DOMAIN_CONSTRAINTS			= $00000200;
  SQL_ISV_DOMAINS						= $00000400;
  SQL_ISV_KEY_COLUMN_USAGE			= $00000800;
  SQL_ISV_REFERENTIAL_CONSTRAINTS		= $00001000;
  SQL_ISV_SCHEMATA					= $00002000;
  SQL_ISV_SQL_LANGUAGES				= $00004000;
 	SQL_ISV_TABLE_CONSTRAINTS			= $00008000;
  SQL_ISV_TABLE_PRIVILEGES			= $00010000;
  SQL_ISV_TABLES						= $00020000;
  SQL_ISV_TRANSLATIONS				= $00040000;
  SQL_ISV_USAGE_PRIVILEGES			= $00080000;
  SQL_ISV_VIEW_COLUMN_USAGE			= $00100000;
  SQL_ISV_VIEW_TABLE_USAGE			= $00200000;
  SQL_ISV_VIEWS						= $00400000;

{ Bitmasks for SQL_ASYNC_MODE }
{
 	SQL_AM_NONE			  = 0;
 	SQL_AM_CONNECTION	= 1;
 	SQL_AM_STATEMENT	= 2;
}

{ Bitmasks for SQL_ALTER_DOMAIN }
  SQL_AD_CONSTRAINT_NAME_DEFINITION			= $00000001;	
 	SQL_AD_ADD_DOMAIN_CONSTRAINT	 			= $00000002;
 	SQL_AD_DROP_DOMAIN_CONSTRAINT	 			= $00000004;
 	SQL_AD_ADD_DOMAIN_DEFAULT   	 			= $00000008;
 	SQL_AD_DROP_DOMAIN_DEFAULT   	 			= $00000010;
  SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED	= $00000020;
  SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE	= $00000040;
  SQL_AD_ADD_CONSTRAINT_DEFERRABLE			= $00000080;
  SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE		= $00000100;


{ SQL_CREATE_SCHEMA bitmasks }
 	SQL_CS_CREATE_SCHEMA				= $00000001;
 	SQL_CS_AUTHORIZATION				= $00000002;
 	SQL_CS_DEFAULT_CHARACTER_SET		= $00000004;

{ SQL_CREATE_TRANSLATION bitmasks }
 	SQL_CTR_CREATE_TRANSLATION			= $00000001;

{ SQL_CREATE_ASSERTION bitmasks }
 	SQL_CA_CREATE_ASSERTION					= $00000001;
 	SQL_CA_CONSTRAINT_INITIALLY_DEFERRED	= $00000010;
 	SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE	= $00000020;
 	SQL_CA_CONSTRAINT_DEFERRABLE			= $00000040;
 	SQL_CA_CONSTRAINT_NON_DEFERRABLE		= $00000080;

{ SQL_CREATE_CHARACTER_SET bitmasks }
 	SQL_CCS_CREATE_CHARACTER_SET		= $00000001;
 	SQL_CCS_COLLATE_CLAUSE				= $00000002;
 	SQL_CCS_LIMITED_COLLATION			= $00000004;

{ SQL_CREATE_COLLATION bitmasks }
 	SQL_CCOL_CREATE_COLLATION			= $00000001;

{ SQL_CREATE_DOMAIN bitmasks }
 	SQL_CDO_CREATE_DOMAIN					= $00000001;
 	SQL_CDO_DEFAULT							= $00000002;
 	SQL_CDO_CONSTRAINT						= $00000004;
 	SQL_CDO_COLLATION						= $00000008;
  SQL_CDO_CONSTRAINT_NAME_DEFINITION		= $00000010;
  SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED	= $00000020;
  SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE	= $00000040;
  SQL_CDO_CONSTRAINT_DEFERRABLE			= $00000080;
  SQL_CDO_CONSTRAINT_NON_DEFERRABLE		= $00000100;

{ SQL_CREATE_TABLE bitmasks }
 	SQL_CT_CREATE_TABLE						= $00000001;
 	SQL_CT_COMMIT_PRESERVE					= $00000002;
 	SQL_CT_COMMIT_DELETE					= $00000004;
 	SQL_CT_GLOBAL_TEMPORARY					= $00000008;
 	SQL_CT_LOCAL_TEMPORARY					= $00000010;
 	SQL_CT_CONSTRAINT_INITIALLY_DEFERRED	= $00000020;
 	SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE	= $00000040;
 	SQL_CT_CONSTRAINT_DEFERRABLE			= $00000080;
 	SQL_CT_CONSTRAINT_NON_DEFERRABLE		= $00000100;
  SQL_CT_COLUMN_CONSTRAINT				= $00000200;
  SQL_CT_COLUMN_DEFAULT					= $00000400;
  SQL_CT_COLUMN_COLLATION					= $00000800;
  SQL_CT_TABLE_CONSTRAINT					= $00001000;
  SQL_CT_CONSTRAINT_NAME_DEFINITION		= $00002000;

{ SQL_DDL_INDEX bitmasks }
  SQL_DI_CREATE_INDEX						= $00000001;
  SQL_DI_DROP_INDEX						= $00000002;

{ SQL_DROP_COLLATION bitmasks }
 	SQL_DC_DROP_COLLATION					= $00000001;

{ SQL_DROP_DOMAIN bitmasks }
 	SQL_DD_DROP_DOMAIN						= $00000001;
 	SQL_DD_RESTRICT							= $00000002;
 	SQL_DD_CASCADE							= $00000004;

{ SQL_DROP_SCHEMA bitmasks }
 	SQL_DS_DROP_SCHEMA						= $00000001;
  SQL_DS_RESTRICT							= $00000002;
 	SQL_DS_CASCADE							= $00000004;

{ SQL_DROP_CHARACTER_SET bitmasks }
 	SQL_DCS_DROP_CHARACTER_SET				= $00000001;

{ SQL_DROP_ASSERTION bitmasks }
 	SQL_DA_DROP_ASSERTION					= $00000001;

{ SQL_DROP_TABLE bitmasks }
 	SQL_DT_DROP_TABLE						= $00000001;
 	SQL_DT_RESTRICT							= $00000002;
 	SQL_DT_CASCADE							= $00000004;

{ SQL_DROP_TRANSLATION bitmasks }
 	SQL_DTR_DROP_TRANSLATION				= $00000001;

{ SQL_DROP_VIEW bitmasks }
 	SQL_DV_DROP_VIEW						= $00000001;
 	SQL_DV_RESTRICT							= $00000002;
 	SQL_DV_CASCADE							= $00000004;

{ SQL_INSERT_STATEMENT bitmasks }
 	SQL_IS_INSERT_LITERALS					= $00000001;
  SQL_IS_INSERT_SEARCHED					= $00000002;
  SQL_IS_SELECT_INTO						= $00000004;

{ SQL_ODBC_INTERFACE_CONFORMANCE values }
  SQL_OIC_CORE							 = 1;//UL
  SQL_OIC_LEVEL1						 =	2;//UL
  SQL_OIC_LEVEL2						 =	3;//UL

{ SQL_SQL92_FOREIGN_KEY_DELETE_RULE bitmasks }
  SQL_SFKD_CASCADE						= $00000001;
  SQL_SFKD_NO_ACTION						= $00000002;
  SQL_SFKD_SET_DEFAULT					= $00000004;
  SQL_SFKD_SET_NULL						= $00000008;

{ SQL_SQL92_FOREIGN_KEY_UPDATE_RULE bitmasks }
  SQL_SFKU_CASCADE						= $00000001;
  SQL_SFKU_NO_ACTION						= $00000002;
  SQL_SFKU_SET_DEFAULT					= $00000004;
  SQL_SFKU_SET_NULL						= $00000008;

{ SQL_SQL92_GRANT	bitmasks }
  SQL_SG_USAGE_ON_DOMAIN					= $00000001;
  SQL_SG_USAGE_ON_CHARACTER_SET			= $00000002;
  SQL_SG_USAGE_ON_COLLATION				= $00000004;
  SQL_SG_USAGE_ON_TRANSLATION				= $00000008;
  SQL_SG_WITH_GRANT_OPTION				= $00000010;
  SQL_SG_DELETE_TABLE						= $00000020;
  SQL_SG_INSERT_TABLE						= $00000040;
  SQL_SG_INSERT_COLUMN					= $00000080;
  SQL_SG_REFERENCES_TABLE					= $00000100;
  SQL_SG_REFERENCES_COLUMN				= $00000200;
  SQL_SG_SELECT_TABLE						= $00000400;
  SQL_SG_UPDATE_TABLE						= $00000800;
  SQL_SG_UPDATE_COLUMN					= $00001000;	

{ SQL_SQL92_PREDICATES bitmasks }
  SQL_SP_EXISTS							= $00000001;
  SQL_SP_ISNOTNULL						= $00000002;
  SQL_SP_ISNULL							= $00000004;
  SQL_SP_MATCH_FULL						= $00000008;
  SQL_SP_MATCH_PARTIAL					= $00000010;
  SQL_SP_MATCH_UNIQUE_FULL				= $00000020;
  SQL_SP_MATCH_UNIQUE_PARTIAL				= $00000040;
  SQL_SP_OVERLAPS							= $00000080;
  SQL_SP_UNIQUE							= $00000100;
  SQL_SP_LIKE								= $00000200;
  SQL_SP_IN								= $00000400;
  SQL_SP_BETWEEN							= $00000800;
  SQL_SP_COMPARISON						= $00001000;
  SQL_SP_QUANTIFIED_COMPARISON			= $00002000;

{ SQL_SQL92_RELATIONAL_JOIN_OPERATORS bitmasks }
  SQL_SRJO_CORRESPONDING_CLAUSE			= $00000001;
  SQL_SRJO_CROSS_JOIN						= $00000002;
  SQL_SRJO_EXCEPT_JOIN					= $00000004;
  SQL_SRJO_FULL_OUTER_JOIN				= $00000008;
  SQL_SRJO_INNER_JOIN						= $00000010;
  SQL_SRJO_INTERSECT_JOIN					= $00000020;
  SQL_SRJO_LEFT_OUTER_JOIN				= $00000040;
  SQL_SRJO_NATURAL_JOIN					= $00000080;
  SQL_SRJO_RIGHT_OUTER_JOIN				= $00000100;
  SQL_SRJO_UNION_JOIN						= $00000200;

{ SQL_SQL92_REVOKE bitmasks }
  SQL_SR_USAGE_ON_DOMAIN					= $00000001;
  SQL_SR_USAGE_ON_CHARACTER_SET			= $00000002;
  SQL_SR_USAGE_ON_COLLATION				= $00000004;
  SQL_SR_USAGE_ON_TRANSLATION				= $00000008;
  SQL_SR_GRANT_OPTION_FOR					= $00000010;
  SQL_SR_CASCADE							= $00000020;
  SQL_SR_RESTRICT							= $00000040;
  SQL_SR_DELETE_TABLE						= $00000080;
  SQL_SR_INSERT_TABLE						= $00000100;
  SQL_SR_INSERT_COLUMN					= $00000200;
  SQL_SR_REFERENCES_TABLE					= $00000400;
  SQL_SR_REFERENCES_COLUMN				= $00000800;
  SQL_SR_SELECT_TABLE						= $00001000;
  SQL_SR_UPDATE_TABLE						= $00002000;
  SQL_SR_UPDATE_COLUMN					= $00004000;

{ SQL_SQL92_ROW_VALUE_CONSTRUCTOR bitmasks }
  SQL_SRVC_VALUE_EXPRESSION				= $00000001;
  SQL_SRVC_NULL							= $00000002;
  SQL_SRVC_DEFAULT						= $00000004;
  SQL_SRVC_ROW_SUBQUERY					= $00000008;

{ SQL_SQL92_VALUE_EXPRESSIONS bitmasks }
  SQL_SVE_CASE							= $00000001;
  SQL_SVE_CAST							= $00000002;
  SQL_SVE_COALESCE						= $00000004;
  SQL_SVE_NULLIF							= $00000008;

{ SQL_STANDARD_CLI_CONFORMANCE bitmasks }
  SQL_SCC_XOPEN_CLI_VERSION1				= $00000001;
  SQL_SCC_ISO92_CLI						= $00000002;

{ SQL_UNION_STATEMENT bitmasks }
  SQL_US_UNION							= SQL_U_UNION;
  SQL_US_UNION_ALL					=	SQL_U_UNION_ALL;

//#endif  { ODBCVER >= = $0300 }

{ SQL_DTC_TRANSITION_COST bitmasks }
  SQL_DTC_ENLIST_EXPENSIVE				= $00000001;
  SQL_DTC_UNENLIST_EXPENSIVE				= $00000002;

////////// SQLGetInfo - end //////////////

{ SQLColAttributes defines }
  SQL_COLUMN_COUNT               = 0;
  SQL_COLUMN_NAME                = 1;
  SQL_COLUMN_TYPE                = 2;
  SQL_COLUMN_LENGTH              = 3;
  SQL_COLUMN_PRECISION           = 4;
  SQL_COLUMN_SCALE               = 5;
  SQL_COLUMN_DISPLAY_SIZE        = 6;
  SQL_COLUMN_NULLABLE            = 7;
  SQL_COLUMN_UNSIGNED            = 8;
  SQL_COLUMN_MONEY               = 9;
  SQL_COLUMN_UPDATABLE           = 10;
  SQL_COLUMN_AUTO_INCREMENT      = 11;
  SQL_COLUMN_CASE_SENSITIVE      = 12;
  SQL_COLUMN_SEARCHABLE          = 13;
  SQL_COLUMN_TYPE_NAME           = 14;
  SQL_COLUMN_TABLE_NAME          = 15;
  SQL_COLUMN_OWNER_NAME          = 16;
  SQL_COLUMN_QUALIFIER_NAME      = 17;
  SQL_COLUMN_LABEL               = 18;
  SQL_COLATT_OPT_MAX             = SQL_COLUMN_LABEL;
//#if (ODBCVER < 0x0300)
  SQL_COLUMN_DRIVER_START        = 1000;
//#endif  { ODBCVER < 0x0300 }

  SQL_COLATT_OPT_MIN             = SQL_COLUMN_COUNT;

// SQLEXT.H
{ extended descriptor field }
{
#if (ODBCVER >= 0x0300)
#define SQL_DESC_ARRAY_SIZE						20
#define SQL_DESC_ARRAY_STATUS_PTR				21
#define SQL_DESC_AUTO_UNIQUE_VALUE				SQL_COLUMN_AUTO_INCREMENT
#define SQL_DESC_BASE_COLUMN_NAME				22
#define SQL_DESC_BASE_TABLE_NAME				23
#define SQL_DESC_BIND_OFFSET_PTR				24
#define SQL_DESC_BIND_TYPE						25
#define SQL_DESC_CASE_SENSITIVE					SQL_COLUMN_CASE_SENSITIVE
#define SQL_DESC_CATALOG_NAME					SQL_COLUMN_QUALIFIER_NAME
#define SQL_DESC_CONCISE_TYPE					SQL_COLUMN_TYPE
#define SQL_DESC_DATETIME_INTERVAL_PRECISION	26
#define SQL_DESC_DISPLAY_SIZE					SQL_COLUMN_DISPLAY_SIZE
#define SQL_DESC_FIXED_PREC_SCALE				SQL_COLUMN_MONEY
#define SQL_DESC_LABEL							SQL_COLUMN_LABEL
#define SQL_DESC_LITERAL_PREFIX					27
#define SQL_DESC_LITERAL_SUFFIX					28
#define SQL_DESC_LOCAL_TYPE_NAME				29
#define	SQL_DESC_MAXIMUM_SCALE					30
#define SQL_DESC_MINIMUM_SCALE					31
}
  SQL_DESC_NUM_PREC_RADIX					=32;
{
#define SQL_DESC_PARAMETER_TYPE					33
#define SQL_DESC_ROWS_PROCESSED_PTR				34
#if (ODBCVER >= 0x0350)
#define SQL_DESC_ROWVER							35
#endif /* ODBCVER >= 0x0350 */
#define SQL_DESC_SCHEMA_NAME					SQL_COLUMN_OWNER_NAME
#define SQL_DESC_SEARCHABLE						SQL_COLUMN_SEARCHABLE
#define SQL_DESC_TYPE_NAME						SQL_COLUMN_TYPE_NAME
#define SQL_DESC_TABLE_NAME						SQL_COLUMN_TABLE_NAME
#define SQL_DESC_UNSIGNED						SQL_COLUMN_UNSIGNED
#define SQL_DESC_UPDATABLE						SQL_COLUMN_UPDATABLE
#endif /* ODBCVER >= 0x0300 */

//SQL.H
/* identifiers of fields in the SQL descriptor */
#if (ODBCVER >= 0x0300)
#define SQL_DESC_COUNT                  1001
#define SQL_DESC_TYPE                   1002
#define SQL_DESC_LENGTH                 1003
#define SQL_DESC_OCTET_LENGTH_PTR       1004
#define SQL_DESC_PRECISION              1005
#define SQL_DESC_SCALE                  1006
#define SQL_DESC_DATETIME_INTERVAL_CODE 1007
}
  SQL_DESC_NULLABLE               = 1008;
{
#define SQL_DESC_INDICATOR_PTR          1009
#define SQL_DESC_DATA_PTR               1010
#define SQL_DESC_NAME                   1011
#define SQL_DESC_UNNAMED                1012
#define SQL_DESC_OCTET_LENGTH           1013
#define SQL_DESC_ALLOC_TYPE             1099
#endif

/* values of ALLOC_TYPE field in descriptor */
#if (ODBCVER >= 0x0300)
#define SQL_DESC_ALLOC_AUTO 1
#define SQL_DESC_ALLOC_USER 2
#endif
}

{ SQLColAttributes subdefines for SQL_COLUMN_UPDATABLE }
  SQL_ATTR_READONLY              = 0;
  SQL_ATTR_WRITE                 = 1;
  SQL_ATTR_READWRITE_UNKNOWN     = 2;

{ SQLColAttributes subdefines for SQL_COLUMN_SEARCHABLE }
{ These are also used by SQLGetInfo                     }
  SQL_UNSEARCHABLE               = 0;
  SQL_LIKE_ONLY                  = 1;
  SQL_ALL_EXCEPT_LIKE            = 2;
  SQL_SEARCHABLE                 = 3;
  SQL_PRED_SEARCHABLE				= SQL_SEARCHABLE;


  SQL_API_ALL_FUNCTIONS       = 0;

////#if (ODBCVER >= = $0300)
  SQL_API_ODBC3_ALL_FUNCTIONS	      = 999;
 	SQL_API_ODBC3_ALL_FUNCTIONS_SIZE	= 250;		// { array of 250 words }

{
  SQL_FUNC_EXISTS(pfExists, uwAPI) \
				((*(((UWORD*) (pfExists)) + ((uwAPI) >> 4)) \
					& (1 << ((uwAPI) & = $000F)) \
 				 ) ? SQL_TRUE : SQL_FALSE \
				)
}
//#endif  { ODBCVER >= = $0300 }


// Cursor type
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
  SQL_GUID				=(-11); // v > 3.50
  SQL_CHAR          = 1;
  SQL_NUMERIC       = 2;
  SQL_DECIMAL       = 3;
  SQL_INTEGER       = 4;
  SQL_SMALLINT      = 5;
  SQL_FLOAT         = 6;
  SQL_REAL          = 7;
  SQL_DOUBLE        = 8;
  SQL_DATETIME      = 9; // v.3.xx
  SQL_DATE          = 9; // v.2.xx
  SQL_INTERVAL			=	10; // v.3.xx
  SQL_TIME          = 10; // v.2.xx
  SQL_TIMESTAMP     = 11; // v.2.xx
  SQL_VARCHAR       = 12;
  SQL_TYPE_DATE     = 91;
  SQL_TYPE_TIME     = 92;
  SQL_TYPE_TIMESTAMP= 93;
  SQL_NO_TOTAL   = -4;
  SQL_NULL_DATA  = (-1);
// sqlext.h for v.2.xx:
  SQL_INTERVAL_YEAR                       = -80;
  SQL_INTERVAL_MONTH                      = -81;
  SQL_INTERVAL_YEAR_TO_MONTH              = -82;
  SQL_INTERVAL_DAY                        = -83;
  SQL_INTERVAL_HOUR                       = -84;
  SQL_INTERVAL_MINUTE                     = -85;
  SQL_INTERVAL_SECOND                     = -86;
  SQL_INTERVAL_DAY_TO_HOUR                = -87;
  SQL_INTERVAL_DAY_TO_MINUTE              = -88;
  SQL_INTERVAL_DAY_TO_SECOND              = -89;
  SQL_INTERVAL_HOUR_TO_MINUTE             = -90;
  SQL_INTERVAL_HOUR_TO_SECOND             = -91;
  SQL_INTERVAL_MINUTE_TO_SECOND           = -92;


{ C data type codes }
  SQL_C_CHAR =   SQL_CHAR ; //            { CHAR, VARCHAR, DECIMAL, NUMERIC }
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
///////////////////////////////////////////////////////////
// SQLTYPES.H - This file defines the types used in ODBC //
///////////////////////////////////////////////////////////
  SQLCHAR      = Char;
  SQLSMALLINT  = smallint;
  SQLUSMALLINT = Word;
  SQLRETURN    = SQLSMALLINT;
  SQLHANDLE    = LongInt;
  SQLHENV      = SQLHANDLE;
  SQLHDBC      = SQLHANDLE;
  SQLHSTMT     = SQLHANDLE;
  SQLHDESC     = SQLHANDLE;
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
//        SQLCHAR         sign;   { 1 if positive, 0 if negative }
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


{ //db.pas
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
implementation

end.


