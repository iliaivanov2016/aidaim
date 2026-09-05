unit constODBC;

interface

uses SysUtils;

CONST

// install request flags
 	 ODBC_INSTALL_INQUIRY	  = 1;
   ODBC_INSTALL_COMPLETE	= 2;

// config driver flags
  ODBC_INSTALL_DRIVER	    = 1;
  ODBC_REMOVE_DRIVER	    = 2;
  ODBC_CONFIG_DRIVER		  = 3;
  ODBC_CONFIG_DRIVER_MAX  = 100;
{
// SQLInstallerError code
  ODBC_ERROR_GENERAL_ERR                 =  1;
  ODBC_ERROR_INVALID_BUFF_LEN            =  2;
  ODBC_ERROR_INVALID_HWND                =  3;
  ODBC_ERROR_INVALID_STR                 =  4;
  ODBC_ERROR_INVALID_REQUEST_TYPE        =  5;
  ODBC_ERROR_COMPONENT_NOT_FOUND         =  6;
  ODBC_ERROR_INVALID_NAME                =  7;
  ODBC_ERROR_INVALID_KEYWORD_VALUE       =  8;
  ODBC_ERROR_INVALID_DSN                 =  9;
  ODBC_ERROR_INVALID_INF                 = 10;
  ODBC_ERROR_REQUEST_FAILED              = 11;
  ODBC_ERROR_INVALID_PATH                = 12;
  ODBC_ERROR_LOAD_LIB_FAILED             = 13;
  ODBC_ERROR_INVALID_PARAM_SEQUENCE      = 14;
  ODBC_ERROR_INVALID_LOG_FILE            = 15;
  ODBC_ERROR_USER_CANCELED               = 16;
  ODBC_ERROR_USAGE_UPDATE_FAILED         = 17;
  ODBC_ERROR_CREATE_DSN_FAILED           = 18;
  ODBC_ERROR_WRITING_SYSINFO_FAILED      = 19;
  ODBC_ERROR_REMOVE_DSN_FAILED           = 20;
  ODBC_ERROR_OUT_OF_MEM                  = 21;
  ODBC_ERROR_OUTPUT_STRING_TRUNCATED     = 22;

// SQLConfigDataSource request flags
   ODBC_ADD_DSN     = 1;               // Add data source
   ODBC_CONFIG_DSN  = 2;               // Configure (edit) data source
   ODBC_REMOVE_DSN  = 3;               // Remove data source

//#if (ODBCVER >= 0x0250)
   ODBC_ADD_SYS_DSN    = 4;				  // add a system DSN
   ODBC_CONFIG_SYS_DSN = 5;		  // Configure a system DSN
   ODBC_REMOVE_SYS_DSN = 6;		  // remove a system DSN
//#if (ODBCVER >= 0x0300)
 	 ODBC_REMOVE_DEFAULT_DSN = 7;		// remove the default DSN
//#endif  /* ODBCVER >= 0x0300 */

// config driver flags
   ODBC_INSTALL_DRIVER	  = 1;
   ODBC_REMOVE_DRIVER		  = 2;
   ODBC_CONFIG_DRIVER		  = 3;
   ODBC_CONFIG_DRIVER_MAX = 100;
//#endif

// SQLGetConfigMode and SQLSetConfigMode flags
//#if (ODBCVER >= 0x0300)
  ODBC_BOTH_DSN		 = 0;
  ODBC_USER_DSN		 = 1;
  ODBC_SYSTEM_DSN	 = 2;
//#endif  /* ODBCVER >= 0x0300 */

// SQLInstallerError code
//#if (ODBCVER >= 0x0300)
  ODBC_ERROR_GENERAL_ERR                 =  1;
  ODBC_ERROR_INVALID_BUFF_LEN            =  2;
  ODBC_ERROR_INVALID_HWND                =  3;
  ODBC_ERROR_INVALID_STR                 =  4;
  ODBC_ERROR_INVALID_REQUEST_TYPE        =  5;
  ODBC_ERROR_COMPONENT_NOT_FOUND         =  6;
  ODBC_ERROR_INVALID_NAME                =  7;
  ODBC_ERROR_INVALID_KEYWORD_VALUE       =  8;
  ODBC_ERROR_INVALID_DSN                 =  9;
  ODBC_ERROR_INVALID_INF                 = 10;
  ODBC_ERROR_REQUEST_FAILED              = 11;
  ODBC_ERROR_INVALID_PATH                = 12;
  ODBC_ERROR_LOAD_LIB_FAILED             = 13;
  ODBC_ERROR_INVALID_PARAM_SEQUENCE      = 14;
  ODBC_ERROR_INVALID_LOG_FILE            = 15;
  ODBC_ERROR_USER_CANCELED               = 16;
  ODBC_ERROR_USAGE_UPDATE_FAILED         = 17;
  ODBC_ERROR_CREATE_DSN_FAILED           = 18;
  ODBC_ERROR_WRITING_SYSINFO_FAILED      = 19;
  ODBC_ERROR_REMOVE_DSN_FAILED           = 20;
  ODBC_ERROR_OUT_OF_MEM                  = 21;
  ODBC_ERROR_OUTPUT_STRING_TRUNCATED     = 22;
}
implementation

end.


