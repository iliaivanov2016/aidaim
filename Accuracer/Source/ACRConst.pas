unit ACRConst;

interface

{$I ACRVer.inc}

uses
 SysUtils
{$IFDEF MSWINDOWS}
 ,Windows
{$ENDIF}
{$IFDEF LINUX}
 ,Types
 ,Libc
{$ENDIF}
;

{$WARNINGS OFF}
{$HINTS OFF}

{$I ACRErrorL.inc}
{$I ACRErrorA.inc}
{$I ACRErrorG.inc}
{$I ACRErrorR.inc}
{$I ACRErrorF.inc}

type  TACRSignature = Array [0..3] of AnsiChar;
type  TACROSType = (osUnknown,
                    osLinux,
                    osWinCE,
                    osWin3,
                    osWin95, osWin98, osWinME,
                    osWinNT351, osWinNT4, osWin2K, osWinXP, osWinNET, osWinVista, osWin7
                     );

{$IFDEF RELEASE_BUILD}
const ACRVersionText = '';
{$ELSE}
const ACRVersionText = 'Beta Version #1';
{$ENDIF}

{$IFDEF X64_ON}
const ACR_X64 = true;
{$ELSE}
const ACR_X64 = false;
{$ENDIF}

{$IFDEF SQLMEMTABLE}
const ACRVersion = 23.00; // SQLMemTable
const ACRStoredFunctionManagerFirstVersion = 5.00;
{$ELSE}
const ACRVersion = 24.00; // Accuracer
const ACRStoredFunctionManagerFirstVersion = 5.10;
const ACRMaxVersion = 99.999999; // for disk engine
      ACRMinVersion = 5.0; // for disk engine
{$ENDIF}
//      ACRDiskSignature = 'ACS2';
      ACRSignature = 'ACS5'; // memory tables
      ACRDiskPageSignature = 'ACSP';
      ACRInternalDBFileSignature = 'ACSF';
      ACRBackupSignature = 'ACRB';
      ACRMemoryDatabaseName = 'MEMORY';
      ACRTemporaryDatabaseName = 'TEMP';
      ACRTemporaryIndexName = 'TEMPORARY_INDEX_';
      ACRTemporaryTableIndexName = 'TEMPORARY_TABLE_INDEX_';
      ACRTemporaryTableName = 'TEMPORARY_TABLE_';
      ACRExpressionFieldName = 'Expr';
      ACRDefaultIndexName = 'Index';
      ACRConstraintFKName = 'FOREIGN_KEY_';
const ACRConstraintFKTemporaryNamePrefix = 'ACRFKTNP_';
const ACRDiskSignature1 = 'A';
const ACRDatabaseFileExtension = '.adb';
const ACRBackupFileExtension = '.abk';
// modified in v.5
//var   ACRDiskSignature: TACRSignature = #0+'CS2'; // invalid first symbol
// beta 5.0
//var   ACRDiskSignature: TACRSignature = #0+'C50'; // invalid first symbol
// beta 5.3, 5.4
//var   ACRDiskSignature: TACRSignature = #0+'C53'; // invalid first symbol
var ACRDiskSignature: TACRSignature = #0+'CR5'; // invalid first symbol
var ACR_OS_Type:             TACROSType;
var ACR_OS_WINNT_COMPATIBLE: Boolean;
var ACR_ENCRYPTED_DB_USED:   Boolean;
var IsDesignMode:            Boolean;

const ACRPSQuoteChar = ' @ ';

const ACRServerConfigFileExtension = '.ini';
const
{$IFDEF TRIAL_VERSION}
 {$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
  {$IFDEF TRIAL_VERSION_WITH_FULL_SQL}
     ACRBuildInfo = 'Trial Without Nag-Screen Full SQL';
  {$ELSE}
     ACRBuildInfo = 'Trial Without Nag-Screen Only SELECT';
  {$ENDIF}
 {$ELSE}
  {$IFDEF TRIAL_VERSION_WITH_FULL_SQL}
    ACRBuildInfo = 'Trial With Nag-Screen Full SQL';
  {$ELSE}
    ACRBuildInfo = 'Trial With Nag-Screen Only SELECT';
  {$ENDIF}
 {$ENDIF}
{$ELSE}
 ACRBuildInfo = 'Full';
{$ENDIF}


//------------------------------------------------------------------------------
// ACRVariant
//------------------------------------------------------------------------------
{$IFDEF LINUX}
// const MAX_INTEGER = 2147483647;
 const MAX_STRING_LENGTH = 99 * 1024; // To avoid memory problem with old libc.so
// 4 * 1024 * 1024 - 4 - 1;  // WideAnsiUpperCase works slow
// 2147483647 div 32 - 4; // really works, but too slow
{$ENDIF}
 const ACRExpressionMaxStringSize = 1024;
 const ACRExpressionMaxVarcharSize = 1024;
 const ACRMaxRoundCharacters = 324; // max double
 // binary value of hash for NULL value
 const ACR_NULL_HASH:          Cardinal = $73B58EAF; // random value
 const ACR_FIELD_HASH_BASE:    Cardinal = $DE3C6A08; // random value
 const ACR_RECORD_HASH_BASE:   Cardinal = $F37ADE3B; // random value
 const ACR_HASH_VALUE_SIZE:    Integer = 4; // SizeOf(TACRRecordHashValue) = SizeOf(Cardinal)
 const ACR_MAX_HASH_KEY_SIZE:  Integer = 32;
 const ACR_MAX_SMALL_VALUE_FOR_SIZE: Integer = 10; // size in byte too small values for CRC to calculate additional checksum
 const ACR_POINTER_SIZE:       Integer = 4;
 const ACRAverageObjectNameLength: Integer = 30*2; // 30 Unicode characters


// const ACRDatabaseFileDeleteTimeout = 120000; // 2 minutes
 const ACRDatabaseFileDeleteTimeout = 100; // 100 ms - try to delete file if it is locked by other users

 var ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK: Cardinal = 256 * 16 * 10; // 4 seconds
// var ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK: Cardinal = 256 * 16; // 4 seconds
// const ACR_CRITICAL_SECTIONS_MAX_READERS_WAIT_LEVEL = 25; // maximum level to wait writers by readers

 const ACRAntifreezeTimeOut = 0; // 3 sec to refresh the form
// ACRAntifreezeTimeOut = 3000; // 3 sec to refresh the form
// ACRAntifreezeSleep   = 50;  // 0.05 sec as max to destroy refreshing thread

//------------------------------------------------------------------------------
// Connection consts
//------------------------------------------------------------------------------

// Network protocols
 ACR_UDP  = 0;
 ACR_TCP  = 1;
 ACR_HTTP = 2;

// Timeout of command execution on the server
 ACRDefaultMaxCommandExecutionTime = 30*60; // time in seconds

{$IFNDEF MsgCommunicator}
// to retry commands in Accuracer
 ACRCommandRetryCount        = 5;
 ACRFirstResendPushUpTimeout = 20;
{$ENDIF}

// Maximum threads number
 ACRMaxThreadCount = MAXINT;// 2147483647; // MAX_INTEGER;;

 ACRLocalMaxThreadCount = MAXINT;
 ACRLANMaxThreadCount = 500;
 ACRWANMaxThreadCount = 1000;
 ACRModemMaxThreadCount = 50;

// Maximum message threads per one client
 ACRMaxMsgThreads = 5;

 ACRLocalMaxACRThreads = 500;
 ACRLANMaxACRThreads = 10;
 ACRWANMaxACRThreads = 5;
 ACRModemMaxACRThreads = 1;

// pause before re-creating thread finished abnormally
 ACRThreadRecreateSleep = 1; // 100;

//------------------------------------------------------------------------------

// Allow connection parameters auto correction
 ACRConnectionParamsTunning = False;
// ACRConnectionParamsTunning = True;

// Number of packets to test network for connection parameters auto tunning
 ACRTestPacketCount = 8;

// To connect - Client only
 ACRLocalConnectRetryCount = 20;
 ACRLocalConnectDelay = 500;

 ACRConnectRetryCount = 30;
 ACRConnectDelay = 1000;

 ACRWANConnectRetryCount = 30;
 ACRWANConnectDelay = 2000;

 ACRModemConnectRetryCount = 60;
 ACRModemConnectDelay = 2000;

// To receive full session buffer
 ACRStartReceiveTimeOut = 180000; // up to 45 min with 5 retry   // - Client only, time to wait for the first packet in answer
 ACRReceiveTimeOut = 360000;      // up to 1.5 hours -"-"-"-"-   // - Client only, time since the first packet to the latest
 ACRReceiveSleep = 1;                           // - Client only, time to sleep while receive buffer to allow incoming packets processing, >=0, <= 100

// ACRCountReceiveSleep = 20;        // - Client, count to do sleep(0) before do sleep(ReceiveSleep)
 ACRPacketProcessTimeOut = 100;    // - Both, time to switch sleep delay from 0 to 1 in case the packet queue is empty

 ACRLocalServerReceiveTimeOut =   30000;  // - Server only
 ACRServerReceiveTimeOut      =  600000;  // 10 min
 ACRWANServerReceiveTimeOut   = 1200000;
 ACRModemServerReceiveTimeOut = 1800000;
 ACRServerReceiveSleep = 0;         // - Server only   >=0, <= 100

// To send buffer
 ACRMinSendTimeOut =      3000;        // - Client only
{$IFDEF MsgCommunicator}
 ACRSendTimeOut =         5000;        // - Client only
{$ELSE}
 ACRSendTimeOut = 60000; // ~15 min with 5 retry     // - Client only
{$ENDIF}
// ------------------------------------------ Server only
 ACRLocalMinServerSendTimeOut =    1000;
 ACRLocalServerSendTimeOut    =  300000; // 5 min

 ACRMinServerSendTimeOut      =    3000;
 ACRServerSendTimeOut         = 1800000; // 30 min

 ACRWANMinServerSendTimeOut   =   10000;
 ACRWANServerSendTimeOut      = 3600000; // 1 hour

 ACRModemMinServerSendTimeOut =  120000;
 ACRModemServerSendTimeOut    = 3600000; // 1 hour

// Wait for end of all other sessions messages sending
 ACRLocalWaitForMessagesSend  =   60000;   // Server only
 ACRWaitForMessagesSend       =  180000;
 ACRWANWaitForMessagesSend    =  600000;
 ACRModemWaitForMessagesSend  = 1200000;

// delay to try to resend block af large object in case of failure
 ACRBlockSendDelay  =   100;   // Server and Client

// To send new request to ask other side to resend broken packet
 ACRWaitForSendSleep = 1;        // - Client only, time to sleep in sending check after MsgMaxSendShortSleepTime exceeding. To avoid 100% CPU usage must be > 0.
 ACRMaxSendShortSleepTime = 200; // - Client only, time to to check sending with 0 interval - sleep 0 - sleep(0) for best speed, after that it will sleep(MsgWaitForSendSleep).

// -------------------------------- - Client only
 ACRLocalResendDelay  = 40;           // delay (msec) before resend requested packet, >=1, <= 100
 ACRLocalRequestDelay = 50;           // delay (msec) before request lost packet, >=1, <= 100

 ACRResendDelay = 300;
 ACRRequestDelay = 300;

 ACRWANResendDelay = 500;
 ACRWANRequestDelay = 500;

 ACRModemResendDelay = 800;
 ACRModemRequestDelay = 1000;
// --------------------------------
 ACRServerWaitForSendSleep = 0;  // - Server only, =0 for best speed
// -------------------------------- - Server only

 ACRLocalServerResendDelay = 35; // >0, <= 100
 ACRLocalServerRequestDelay = 50;// >=0, <= 100

 ACRServerResendDelay  = 300;
 ACRServerRequestDelay = 3000;

 ACRWANServerResendDelay = 500;
 ACRWANServerRequestDelay = 10000;

 ACRModemServerResendDelay = 800;
 ACRModemServerRequestDelay = 10000;

// To Diconnect
 ACRDisconnectRetryCount = 12;   // Both Client and Server
 ACRDisconnectDelay = 300;       // Both Client and Server

 ACRLocalDisconnectRetryCount = 10;
 ACRLocalDisconnectDelay = 20;

 ACRWANDisconnectRetryCount = 20;
 ACRWANDisconnectDelay = 50;

 ACRModemDisconnectRetryCount = 10;
 ACRModemDisconnectDelay = 300;

//------------------------------------------------------------------------------

// Timeout for sending a block of large object (file or stream)
 ACRBlockSendingTimeOut = 600000;

// Wait for Session finishing
{$IFDEF MsgCommunicator}
 ACRWaitForTimeOut =  10000;        // Client only
{$ELSE}
 ACRWaitForTimeOut = 120000;        // Client only
{$ENDIF}

// Wait for Server Session Thread finishing
 ACRWaitForServerSessionThreadFinish  = 16;
{$IFDEF MsgCommunicator}
 ACRWaitForServerSessionThreadTimeOut = 60000;     // Server only
{$ELSE}
 ACRWaitForServerSessionThreadTimeOut = 600000;    // Server only
{$ENDIF}

// Time out in server disconnect session to avoid blocking in DeleteSession
 ACRServerSessionDisconnectTimeOut = 50;   // Server only

// Wait for other threads finish to free shared object
{$IFDEF MsgCommunicator}
 ACRThreadsTerminateDelay =       3000;   // Client
{$ELSE}
 ACRThreadsTerminateDelay =      30000;   // Client
{$ENDIF}
 ACRServerThreadsTerminateDelay = 1000;   // Server

// Pause between loops
 ACRServerSessionTerminatorSleep = 100;   // Server
 
// Enable/Disable disconect by timeout
 ACRPingClients = True;        // Server
// Wait for alive confirmation 
 ACRLocalPingCount       = 3; 
 ACRPingCount            = 8;
 ACRWANPingCount         = 10;
 ACRModemPingCount       = 15;

 ACRLocalWaitForPingAnswer =  30000;
 ACRWaitForPingAnswer      = 120000;
 ACRWANWaitForPingAnswer   = 180000;
 ACRModemWaitForPingAnswer = 300000;

// Pause between pings
 ACRServerPingSleep      = 20; // Server, >=1, low priority thread

// keep connection when IP address or port changes; disable to prevent IP spoofing
 ACRKeepConnection = True;        // Server


//------------------------------------------------------------------------------
// Packet size
//------------------------------------------------------------------------------

 const ACRMinPacketSize = 128;      // PacketHeader = 33
 const ACRMaxPacketSize = 65507;    // 65507 - max UDP datagram size
 const ACRMaxPacketSizeTCP = 1000000000; // about 1GB
{
MTU:
========================
 1500 - Ethernet
 1492 - IEEE 802.3/802.2 -- works without firewalls/routers only!
 1464 - tested on real internet (1472 - max value for up to 200 packets request)
  576 - X.25
}
 const ACRDefaultPacketSizeTCP = 10000000;  // about 10MB
 const ACRLocalDefaultPacketSize = ACRMaxPacketSize;
 const ACRDefaultPacketSize = 1464;
 const ACRWANDefaultPacketSize = 1464;
 const ACRModemDefaultPacketSize = 576; // 1000;
 const ACRDefaultClientPort = 0; // 12009;
 const ACRDefaultServerPort = 12007; // Cannot be the same as ACRDefaultClientPort
 const ACRDefaultServerPortTCP = 12008;

 const ACRMaxFilesToSend = MAXINT;

 const ACRDefaultAuthorizationBufferSize = 512;
 const ACRDefaultServerID = 0;
 const ACRDefaultHost = '127.0.0.1';  // 'localhost' - delay about 100 msec to resolve
 const ACRDefaultServerHost = '';     // 'localhost' - delay about 100 msec to resolve

 const ACR_CONNECT_TIMEOUT = 120000;

//------------------------------------------------------------------------------
// TCP
//------------------------------------------------------------------------------



{$IFDEF MsgCommunicator}
 const ACRDefaultServerConfigFileName = 'ACRServer.ini';
 const ACRServerDescription = 'MsgCommunicator Server';
{$ELSE}
 const ACRServerDescription = 'Accuracer Database Server';
 const ACRDefaultServerConfigFileName = 'AccuracerDatabaseServer.ini';
 const ACRDefaultDBName = 'DBDemos';
 const ACRDefaultDBFileName = '..\..\Demos\Data\DBDemos.adb';
{$ENDIF}


{******************************************************************************}

//------------------------------------------------------------------------------
// lock consts
//------------------------------------------------------------------------------

// const ACRDefaultServerLockRetryCount = 100;
// const ACRDefaultServerLockDelay = 10;
// modified in 4.80
 const ACRDefaultServerLockRetryCount = 40000; // 10 minutes
 const ACRDefaultServerLockDelay = 16; // ms
 // const ACR_CHECK_OTHER_SESSIONS_TIME = 1000; // 1 second between checks
 const ACRMaxLockType = 5; // 0..5
 const ACRSystemWaitTime = 10*1000; // minimum value of maximum wait time for locking FreeSpaceManager, Tables etc.
//------------------------------------------------------------------------------
// disk consts
//------------------------------------------------------------------------------

{$IFDEF LINUX}
 const INVALID_FILE_SIZE = -1;
 const INVALID_HANDLE_VALUE = -1;
{$ENDIF}
 var ACRDefaultTempDir: WideString;
 var ACRDefaultPageMangerCacheCapactiy: Integer = 200; // 1 Mb if page = 4Kb
 var ACRDefaultMemoryPageSize: Integer = 4096;
 var ACRDefaultTemporaryPageSize: Integer = 4*1024; // 4096
 var ACRDefaultMemoryTableAllocBy: Integer = 1000;
 var ACRTempPageManagerMaxMemoryPageCount: Integer = 1000;
 var ACRMaxInternalFileNotCompressedSize: Integer = 0; // set in intialization
 {
 var ACRCacheManagerThreadSleep: Cardinal = 60000; // 1 minute
 var ACRCacheManagerThreadRAMLowBound: Int64 = 20*1024*1024; // 20 MB
 var ACRCacheManagerThreadRAMHighBound: Int64 = 200*1024*1024; // 200 MB
 var ACRCacheManagerThreadMaxPageStoreTime: Cardinal = 3600000; // 1 hour
}
 var ACRCacheManagerThreadSleep: Cardinal = 10000; // 10 seconds
 var ACRCacheManagerThreadRAMLowBound: Int64 = 20*1024*1024; // 20 MB
 var ACRCacheManagerThreadRAMHighBound: Int64 = 200*1024*1024; // 200 MB
 var ACRCacheManagerThreadMaxPageStoreTime: Cardinal = 3600000; // 1 hour
 var ACRCacheManagerThreadMinimumSleep: Cardinal = 100;

 // table cache in client-server
 // SizeOf(TACRCommunicationCommandHeader) = 2, SizeOf(TACRPacketHeader) = 33 bytes
 const ACRMinCacheSize: Int64 = ACRDefaultPacketSize - 2 - 33; // 1 Kb
 const ACRMaxCacheSize: Int64 = 1024*1024; // 1 Mb
 const ACRMinTimeToExtendClientCache = 32; // 32 ms

 const ACRMaxIndexHeaderSize = 128;
 const ACRDefaultPageSize = 4096;
 const ACRMinPageSize = 128;
 const ACRMaxPageSize = 65535; // 65535;
 const ACRDefaultExtentPageCount = 8;
 const ACRMinExtentPageCount = 4;
 const ACRMaxExtentPageCount = 256;
 const ACRDefaultDBHeaderReserved = 0;
 const ACRDatabaseFileLockedBytesCount = 3; // 2 before v.5.10 - stored function manager added
 const ACRMemoryDelay = 1;
 const ACRMemoryRetryCount = 1000;
 const ACRDefaultRetryCount = 1000; // 1 second
 const ACRDefaultDelay = 1; // ms 
 const ACR_MAX_WAIT_LEVEL =  255; // level used in TACRLocksManager
 const ACRTableLockedBytesCount = 3; // X IRW RW

 const ACRMinRetryCount = 1;
 const ACRMinDelay = 0;
// const ACRMAXLastLockRetryTime = 2000; // ms
 const ACRMAXLockFileTime = 600000; // ms  > ACRMAXLastLockRetryTime
 const ACRMinRandomSearchRetryCount = 1;
 const ACRMaxRandomSearchRetryCount = 100;
 const ACRDefaultRandomSearchRetryCount = 10;
 const OffsetToFreeSpaceManagerLockByte = 0;
 const OffsetToTablesLockByte = 1;
 const OffsetToStoredFunctionManagerLockByte = 2; // added in v.5.10
 const ACRMinSystemFilesCount = 2;
 const ACRVarcharSlowDownRate = 5;
 const ACRDefaultBackupBlockSize = ACRDefaultPageSize * 25; // 100 Kb
 const ACRDefaultSaveBlockSize = 1024*1024;

{$IFDEF FILE_SERVER_VERSION}
  {$IFDEF TRIAL_VERSION}
    const ACRMaxSessionCount = 5;
    var  ACRDefaultSessionCount: Integer = 2;
    const ACRMaxSingleUserConnections = 10;
  {$ELSE}
    const ACRMaxSessionCount = 1000000;// 1M
    var ACRDefaultSessionCount: Integer = 2;
    const ACRMaxSingleUserConnections = 1000000; // 1M
  {$ENDIF}
{$ELSE}
 const ACRMaxSessionCount = 2;
 var  ACRDefaultSessionCount: Integer = 2;
  {$IFDEF TRIAL_VERSION}
  const ACRMaxSingleUserConnections = 10;
  {$ELSE}
  const ACRMaxSingleUserConnections = 1000000; // 1M
  {$ENDIF}
{$ENDIF}
 const ACR_MIN_LOCK_WAIT_TIME = 1; // 1 ms

 // System First Pages
 const

{$IFDEF FREE_SPACE_MANAGER_ON}
        ACRFirstPageNoPFS = 0;
        ACRFirstPageNoGAM = 1;
        ACRFirstPageNoSGAM = 2;
        ACRFirstPageNoSystemDirectory = 3;
{$ELSE}
        ACRFirstPageNoGAM = 0;
        ACRFirstPageNoSGAM = 1;
        ACRFirstPageNoPFS = 2;
        ACRFirstPageNoSystemDirectory = 0;
{$ENDIF}

 const ACRObjectIDUnknown = -1;
 const ACRObjectIDSystemDirectory = -2;
 const ACRObjectIDActiveSessionsFile = -3;
 const ACRObjectIDTableListFile = -4;
 const ACRObjectIDFreeSpaceManager = -5;

 // Page Types
 const
        ACRPageTypeIDUnknown =                  0;
        ACRPageTypeIDEmpty =                    1;
        ACRPageTypeIDGAM =                      2;
        ACRPageTypeIDSGAM =                     3;
        ACRPageTypeIDPFS =                      4;
        ACRPageTypeIDFileSystemDirectory =      5;
        ACRPageTypeIDActiveSessionList =        6;
        ACRPageTypeIDTableList =                7;
        ACRPageTypeIDTablePFSMap =              8;
        ACRPageTypeIDTableLocksFile =           9;
        // varchar or blob page with multiple items on the page
        ACRPageTypeIDTableDataSmall =           10;
        // varchar or blob page with single item on the page
        ACRPageTypeIDTableDataLarge =           11;
        ACRPageTypeIDTableRows =                12;
        ACRPageTypeIDTablePFS =                 13;
        ACRPageTypeIDTableMetaData =            14;
        ACRPageTypeIDTableMostUpdatedData =     15;
        ACRPageTypeIDIndexData =                16;
        ACRPageTypeIDStoredFunctionManager =    17;

        ACRPageTypeIDLast =                     17;

 ACRPageTypeNames: array [0..15] of AnsiString = (
        'PageTypeIDUnknown',
        'PageTypeIDEmpty',
        'PageTypeIDGAM',
        'PageTypeIDSGAM',
        'PageTypeIDPFS',
        'PageTypeIDFileSystemDirectory',
        'PageTypeIDActiveSessionList',
        'PageTypeIDTableList',
        'PageTypeIDTablePFSMap',
        'PageTypeIDTableLocks',
        'PageTypeIDTableDataSmall',
        'PageTypeIDTableDataLarge',
        'PageTypeIDTableRows',
        'PageTypeIDTablePFS',
        'ACRPageTypeIDTableMetadata',
        'ACRPageTypeIDTableMostUpdated'
        );

 const ACRTablePFSItemSize = 18; // bits
 const ACRTablePFSEmptyPage = $FFFF;

//------------------- ENCRYPTION CONSTS -------------------------------------------

const ACR_Cipher_None = 0;
const ACR_Cipher_Rijndael_128 = 1;
const ACR_Cipher_Rijndael_256 = 2;
const ACR_Cipher_Blowfish = 3;
const ACR_Cipher_Twofish_128 = 4;
const ACR_Cipher_Twofish_256 = 5;
const ACR_Cipher_Square = 6;
const ACR_Cipher_Des_Single_8 = 7;
const ACR_Cipher_Des_Double_8 = 8;
const ACR_Cipher_Des_Double_16 = 9;
const ACR_Cipher_Des_Triple_8 = 10;
const ACR_Cipher_Des_Triple_16 = 11;
const ACR_Cipher_Des_Triple_24 = 12;
const ACR_MAX_Cipher_Algorithm = 12;

const ACR_Cipher_Mode_CTS = 0;
const ACR_Cipher_Mode_CBC = 1;
const ACR_Cipher_Mode_CFB = 2;
const ACR_Cipher_Mode_OFB = 3;
const ACR_Cipher_Mode_CFS = 4;
const ACR_Cipher_Mode_ECB = 5;
const ACR_Cipher_Mode_CFB8 = 6;
const ACR_Cipher_Mode_OFB8 = 7;
const ACR_Cipher_Mode_CFS8 = 8;
const ACR_MAX_Cipher_Mode = 8;

const ACR_MAX_VECTOR = 31;
const ACR_MAX_KEY = 55;
const ACR_MAX_CONTROL_BLOCK = 255;

const ACRDefaultPassword = 'ACRpassword';

//------------------- GENERAL CONSTS -------------------------------------------

 const ACRDefaultCommitCount = 1000;
 // Invalid ID - returned by find methods in case if object was not found
 const MAX_NAME_LENGTH = 255;
 const INVALID_ID8 = Int64(-1);
 const INVALID_ID4 = Integer(-1);
 const INVALID_PAGE_NO = Integer(-1);
 const ACR_MAX_DISK_SYSTEM_PAGE_NO = 6; // since v.5.11
 const ACR_MAX_DISK_SYSTEM_PAGE_NO_50 = 5; // v.5.00 - v.5.11
 const INVALID_OBJECT_ID = INVALID_ID4;
 const INVALID_PAGE_RECORD_NO = $FFFF;
 const MAX_CARDINAL: Cardinal = $FFFFFFFF;
 const ACR_MAX_STATE: Cardinal = $FFFFFFFF;
 const ACR_MAX_METADATA_STATE: Byte = $FF;
 const OBJECTID_IS_NULL = Integer(-1);
 const ACR_BLOB_NOT_MODIFIED = $F0F0;
 const ACR_BLOB_MODIFIED = $0F0F;
 // DateTime Const
 const TIME_IS_NULL = -1;
// Bug fix in 4.02: time can be set to 0, but not to < 0
// const TIME_IS_NULL = 0;//MaxInt;
{$WARNINGS OFF}
// const DATE_IS_NULL: Cardinal = $80000000;
 const DATE_IS_NULL: Integer = Integer($80000000);
{$WARNINGS ON}
 const MILSECS_IN_DAY = 24*60*60*1000;
 const ACR_DEFAULT_STRING_SIZE_FOR_CREATE_TABLE = 20;

 // BTree
 const BTreeNullFlagSize = 1;
 const BTreeKeyIsNull    = #1;
 const BTreeKeyIsNotNull = #0;

 const INVALID_SESSION_ID = Integer(-1);
 const FSM_SESSION_ID = Integer(-3); // FreeSpaceManager

 // error codes
 // error codes
{$IFDEF MsgCommunicator}
// MsgCommunicator constants
const
  MsgSuccess = 0;
  MsgError = 1;

// command results
const MSG_COMMAND_OK                                             = 60000;
const MSG_COMMAND_RESULT_TRUE                                    = 00001;
const MSG_COMMAND_RESULT_FALSE                                   = 00000;
// error codes
const MSG_Error_GetUserInfo_NotConnected                         = 60003;
const MSG_Error_GetUserInfo_SendCommandFailed                    = 60004;
const MSG_Error_GetUserInfo_ReceiveResultFailed                  = 60005;
const MSG_Error_GetUserInfo_InvalidParams                        = 60006;
const MSG_Error_GetUserInfo_UserDoesNotExist                     = 60007;
const MSG_Error_GetUserInfo_InvalidServerReply                   = 60008;
const MSG_Error_GetContacts_InvalidServerReply                   = 60009;
const MSG_Error_GetContacts_NotConnected                         = 60010;
const MSG_Error_GetContacts_SendCommandFailed                    = 60011;
const MSG_Error_GetContacts_ReceiveResultFailed                  = 60012;
const MSG_Error_GetContacts_Failed                               = 60013;
const MSG_Error_IsUserExisting_NotConnected                      = 60014;
const MSG_Error_IsUserExisting_SendCommandFailed                 = 60015;
const MSG_Error_IsUserExisting_ReceiveResultFailed               = 60016;
const MSG_Error_IsUserExisting_InvalidParams                     = 60017;
const MSG_Error_IsUserExisting_InvalidServerReply                = 60018;
const MSG_Error_IsUserExisting_Failed                            = 60019;
const MSG_Error_IsUserOnline_NotConnected                        = 60020;
const MSG_Error_IsUserOnline_SendCommandFailed                   = 60021;
const MSG_Error_IsUserOnline_ReceiveResultFailed                 = 60022;
const MSG_Error_IsUserOnline_InvalidParams                       = 60023;
const MSG_Error_IsUserOnline_InvalidServerReply                  = 60024;
const MSG_Error_IsUserOnline_Failed                              = 60025;
const MSG_Error_RegisterNewUser_NotConnected                     = 60026;
const MSG_Error_RegisterNewUser_SendCommandFailed                = 60027;
const MSG_Error_RegisterNewUser_ReceiveResultFailed              = 60028;
const MSG_Error_RegisterNewUser_InvalidParams                    = 60029;
const MSG_Error_RegisterNewUser_InvalidServerReply               = 60030;
const MSG_Error_RegisterNewUser_Failed                           = 60031;
const MSG_Error_RegisterNewUser_UserAlreadyExists                = 60032;
const MSG_Error_UpdateUserInfo_NotConnected                      = 60033;
const MSG_Error_UpdateUserInfo_SendCommandFailed                 = 60034;
const MSG_Error_UpdateUserInfo_ReceiveResultFailed               = 60035;
const MSG_Error_UpdateUserInfo_InvalidParams                     = 60036;
const MSG_Error_UpdateUserInfo_InvalidServerReply                = 60037;
const MSG_Error_UpdateUserInfo_Failed                            = 60038;
const MSG_Error_UpdateUserInfo_UserDoesNotExist                  = 60039;
const MSG_Error_AddUserToContacts_NotConnected                   = 60040;
const MSG_Error_AddUserToContacts_SendCommandFailed              = 60041;
const MSG_Error_AddUserToContacts_ReceiveResultFailed            = 60042;
const MSG_Error_AddUserToContacts_InvalidParams                  = 60043;
const MSG_Error_AddUserToContacts_InvalidServerReply             = 60044;
const MSG_Error_AddUserToContacts_Failed                         = 60045;
const MSG_Error_AddUserToContacts_UserDoesNotExist               = 60046;
const MSG_Error_UpdateUserInContacts_NotConnected                = 60047;
const MSG_Error_UpdateUserInContacts_SendCommandFailed           = 60048;
const MSG_Error_UpdateUserInContacts_ReceiveResultFailed         = 60049;
const MSG_Error_UpdateUserInContacts_InvalidParams               = 60050;
const MSG_Error_UpdateUserInContacts_InvalidServerReply          = 60051;
const MSG_Error_UpdateUserInContacts_Failed                      = 60052;
const MSG_Error_UpdateUserInContacts_UserDoesNotExist            = 60053;
const MSG_Error_RemoveUserFromContacts_NotConnected              = 60054;
const MSG_Error_RemoveUserFromContacts_SendCommandFailed         = 60055;
const MSG_Error_RemoveUserFromContacts_ReceiveResultFailed       = 60056;
const MSG_Error_RemoveUserFromContacts_InvalidParams             = 60057;
const MSG_Error_RemoveUserFromContacts_InvalidServerReply        = 60058;
const MSG_Error_RemoveUserFromContacts_Failed                    = 60059;
const MSG_Error_RemoveUserFromContacts_UserDoesNotExist          = 60060;
const MSG_Error_FindUsers_NotConnected                           = 60061;
const MSG_Error_FindUsers_SendCommandFailed                      = 60062;
const MSG_Error_FindUsers_ReceiveResultFailed                    = 60063;
const MSG_Error_FindUsers_InvalidParams                          = 60064;
const MSG_Error_FindUsers_InvalidServerReply                     = 60065;
const MSG_Error_FindUsers_Failed                                 = 60066;
const MSG_Error_FindUsers_DatabaseIsNotAssigned                  = 60067;
const MSG_Error_FindMessages_NotConnected                        = 60068;
const MSG_Error_FindMessages_SendCommandFailed                   = 60069;
const MSG_Error_FindMessages_ReceiveResultFailed                 = 60070;
const MSG_Error_FindMessages_InvalidParams                       = 60071;
const MSG_Error_FindMessages_InvalidServerReply                  = 60072;
const MSG_Error_FindMessages_Failed                              = 60073;
const MSG_Error_FindMessages_Client_TempTableIsNotAssigned       = 60074;
const MSG_Error_FindMessages_Server_TempTableIsNotAssigned       = 60075;
const MSG_Error_FindMessages_Client_DatabaseIsNotAssigned        = 60076;
const MSG_Error_FindMessages_Server_DatabaseIsNotAssigned        = 60077;
const MSG_Error_FindMessages_CannotLoadDatasetFromStream         = 60078;
const MSG_Error_FindMessages_CannotSaveDatasetToStream           = 60079;
const MSG_Error_FindMessages_SenderOrRecepientMustBeSpecified    = 60080;
const MSG_Error_SendMessage_SendFailed                           = 60082;
const MSG_Error_SendMessage_SaveHistoryToDatabaseFailed          = 60083;
const MSG_Error_SendCommand_NotConnected                         = 60084;
const MSG_Error_SendCommand_SendFailed                           = 60085;
const MSG_Error_SendCommand_SaveHistoryToDatabaseFailed          = 60086;
const MSG_Error_CannotConnectDirectly                            = 60087;
const MSG_Error_ClientCannotDisconnectSession                    = 60088;
const MSG_Error_ClientCannotActivate                             = 60089;
const MSG_Error_ClientCannotDeactivate                           = 60090;
const MSG_Error_ServerCannotDisconnectUser                       = 60091;
const MSG_Error_Logon_NotConnected                               = 60092;
const MSG_Error_Logon_SendCommandFailed                          = 60093;
const MSG_Error_Logon_ReceiveResultFailed                        = 60094;
const MSG_Error_Logon_UserDoesNotExist                           = 60095;
const MSG_Error_Logon_InvalidPassword                            = 60096;
const MSG_Error_Logon_InvalidServerReply                         = 60097;
const MSG_Error_Logoff_NotConnected                              = 60098;
const MSG_Error_Logoff_SendCommandFailed                         = 60099;
const MSG_Error_Logoff_ReceiveResultFailed                       = 60100;
const MSG_Error_Logoff_UserDoesNotExist                          = 60101;
const MSG_Error_Logoff_InvalidPassword                           = 60102;
const MSG_Error_Logoff_InvalidServerReply                        = 60103;
const MSG_Error_IsUserOnline_NotLogged                           = 60104;
const MSG_Error_GetUserInfo_NotLogged                            = 60105;
const MSG_Error_UpdateUserInfo_NotLogged                         = 60106;
const MSG_Error_AddUserToContacts_NotLogged                      = 60107;
const MSG_Error_UpdateUserInContacts_NotLogged                   = 60108;
const MSG_Error_RemoveUserFromContacts_NotLogged                 = 60109;
const MSG_Error_GetContacts_NotLoggeed                           = 60110;
const MSG_Error_FindMessages_NotLogged                           = 60111;
const MSG_Error_Logon_InvalidParams                              = 60112;
const MSG_Error_Logon_InternalServerError                        = 60113;
const MSG_Error_Logon_UserAlreadyLogged                          = 60114;
const MSG_Error_Logoff_InvalidParams                             = 60115;
const MSG_Error_Logoff_InternalServerError                       = 60116;
const MSG_Error_Logoff_UserNotLogged                             = 60117;
const MSG_Error_Logon_MaxConnectionsExceeded                     = 60118;
const MSG_Error_SendMessage_NotLogged                            = 60119;
const MSG_Error_SendMessage_ToGuest                              = 60120;
const MSG_Error_SendMessage_SessionNotFound                      = 60121;
const MSG_Error_SendCommand_NotLogged                            = 60122;
const MSG_Error_ReceiveMessage_NotLogged                         = 60123;
const MSG_Error_InitProgressSend_NotConnected                    = 60124;
const MSG_Error_InitProgressSend_SendCommandFailed               = 60125;
const MSG_Error_InitProgressSend_ReceiveResultFailed             = 60126;
const MSG_Error_InitProgressSend_InvalidServerReply              = 60127;
const MSG_Error_ReceiveFile_NotExists                            = -1;
const MSG_Error_ReceiveFile_DiskFull                             = -2;
const MSG_Error_ReceiveFile_FileExists                           = -3;
const MSG_Error_ReceiveFile_CannotCreateFile                     = -4;
const MSG_Error_ReceiveFile_TimeOut                              = -5;
const MSG_Error_ReceiveFile_BlockSize                            = -6;
const MSG_Error_InitProgressRecv_InvalidParams                   = 60128;
const MSG_Error_InitProgressRecv_SendAnswerFailed                = 60129;
const MSG_Error_InitProgressRecv_ServerDeny                      = 60130;
const MSG_Error_InitProgressRecv_Failed                          = 60131;
const MSG_Error_InitProgressRecvClnt_Deny                        = 60132;
const MSG_Error_InitProgressRecvClnt_InvalidParams               = 60133;
const MSG_Error_InitProgressRecvClnt_SendAnswerFailed            = 60134;
const MSG_Error_InitProgressRecvClnt_Failed                      = 60135;
const MSG_Error_InitProgressRecvClnt_UserIDMismatch              = 60136;
const MSG_Error_FindUserID_NotConnected                          = 60137;
const MSG_Error_FindUserID_SendCommandFailed                     = 60138;
const MSG_Error_FindUserID_ReceiveResultFailed                   = 60139;
const MSG_Error_FindUserID_InvalidParams                         = 60140;
const MSG_Error_FindUserID_InvalidServerReply                    = 60141;
const MSG_Error_FindUserID_Failed                                = 60142;
const MSG_Error_SendMessage_InternalDataError                    = 60143;

{$ELSE} // Accuracer error codes


 const ACR_ERR_OK = 0;
 const ACR_ERR_INSERT_RECORD = -1;
 const ACR_ERR_UPDATE_RECORD = -2;
 const ACR_ERR_DELETE_RECORD = -3;
 const ACR_ERR_UPDATE_RECORD_MODIFIED = -4;
 const ACR_ERR_DELETE_RECORD_MODIFIED = -5;
 const ACR_ERR_UPDATE_RECORD_DELETED = -6;
 const ACR_ERR_DELETE_RECORD_DELETED = -7;

 const ACR_ERR_CONSTRAINT_VIOLATED = -8;
 const ACR_ERR_UPDATE_RECORD_PROHIBITED = -9;
 const ACR_ERR_DELETE_RECORD_PROHIBITED = -10;
 const ACR_ERR_CANCEL_PROHIBITED = -11;
 const ACR_ERR_DELETE_RECORD_PROHIBITED_BY_FK_VIOLATION = -12;
 const ACR_ERR_UPDATE_RECORD_PROHIBITED_BY_FK_VIOLATION = -13;

{$ENDIF}  // error codes

 // ASC, DESC, CASE INSENSITIVITY constants
 const ACR_ASC = 'ASC';
       ACR_DESC = 'DESC';
       ACR_NO_CASE = 'NO_CASE';
       ACR_CASE = 'CASE';

 // Auto generation object names
 const
       AutoNameSymbol = '$';
       AutoNameSequenceAutoIncPrefix = 'S_Autoinc';
       AutoNameSequenceLinkedWithColumnPrefix = 'S_Linked';
       AutoNameConstraintNotNullPrefix = 'C_NotNull';
       AutoNameConstraintCheckPrefix = 'C_Check';
       AutoNameConstraintPKPreffix = 'C_PK';
       AutoNameConstraintUniquePreffix = 'C_Unique';
       ACR_Locate_Param_Name_Prefix = AutoNameSymbol + '_Locate_Param_';

// text constants
 const ACRTextFileSignature_Unicode16: AnsiString = #$FF#$FE;
// SQL Lexer constants

const Lf: AnsiString = #$0A;       // binary mode line separator
const Cr: AnsiString = #$0D;       // text mode line separator
const WLf: AnsiString = #$0A;       // binary mode line separator
const WCr: AnsiString = #$0D;       // text mode line separator
{$IFDEF LINUX}
const Crlf: AnsiString = #$0A; // text mode line separator
const CrlfLength = 1;
const WCrlf: WideString = #$0A; // text mode line separator
const WCrlfLength = 2;
{$ELSE}
//AnsiString(#13#10)
const Crlf: AnsiString = #$0D#$0A; // text mode line separator
const CrlfLength = 2;
const WCrlf: WideString = #$0D#$0A; // text mode line separator
const WCrlfLength = 4;
{$ENDIF}
const Tab: AnsiString = #$09; // <tab>
const Comment = '-'; // -- comment <Crlf>
const Comment1 = '#'; // # comment <Crlf>
const Dot = '.';
const Comma = ',';
const SemiColon = ';';
const Asterisk = '*';
const SingleQuote = '''';
const DoubleQuote = '"';
const BackQuote = '`';
const Space = ' ';
const LeftParenthesis = '(';
const RightParenthesis = ')';
const Percent = '%';
const LeftBracket = '[';
const RightBracket = ']';
const Colon = ':';
const ACR_SES_VAR_SIGN = '@'; // @SessionVariable
const ACRDefaultGroupConcatSeparator = ','; // GROUP_CONCAT
const ACR_GUID: AnsiString = 'GUID';
const ACR_GUID_LENGTH = 38;
const ACRLastTableOperationNames: array [0..15] of WideString =
                           (
                            'CREATE TABLE',
                            'INSERT',
                            'UPDATE',
                            'DELETE',
                            'COMMIT',
                            'EMPTY TABLE',
                            'ADD INDEX',
                            'DELETE INDEX',
                            'EMPTY INDEX',
                            'ADD FOREIGN KEY',
                            'DROP CONSTRAINT',
                            'RENAME REFERENCED TABLE',
                            'RENAME TABLE',
                            'RENAME FIELD',
                            'SET AUTO-INC VALUE',
                            'CREATE VIEW' // added in v.6
                           );
var ACRMaxLastTableOperationNamesLength: Integer = 25;


type
  TReservedWord =
  (
   rwABSOLUTE
   ,rwACTION
   ,rwADD
   ,rwALL
   ,rwALLOCATE
   ,rwALTER
   ,rwAND
   ,rwANY
   ,rwARE
   ,rwAS
   ,rwASC
   ,rwASSERTION
   ,rwAT
   ,rwAUTHORIZATION
   ,rwAVG
   ,rwBEGIN
   ,rwBETWEEN
   ,rwBIT
   ,rwBIT_LENGTH
   ,rwBOTH
   ,rwBY
   ,rwCASCADE
   ,rwCASCADED
   ,rwCASE
   ,rwCAST
   ,rwCATALOG
   ,rwCHAR
   ,rwCHARACTER
   ,rwCHAR_LENGTH
   ,rwCHARACTER_LENGTH
   ,rwCHECK
   ,rwCLOSE
   ,rwCOALESCE
   ,rwCOLLATE
   ,rwCOLLATION
   ,rwCOLUMN
   ,rwCOMMIT
   ,rwCONNECT
   ,rwCONNECTION
   ,rwCONSTRAINT
   ,rwCONSTRAINTS
   ,rwCONTINUE
   ,rwCONVERT
   ,rwCORRESPONDING
   ,rwCOUNT
   ,rwCREATE
   ,rwCROSS
   ,rwCURRENT
   ,rwCURRENT_DATE
   ,rwCURRENT_TIME
   ,rwCURRENT_TIMESTAMP
   ,rwCURRENT_USER
   ,rwCURSOR
   ,rwDATE
   ,rwDAY
   ,rwDEALLOCATE
   ,rwDEC
   ,rwDECIMAL
   ,rwDECLARE
   ,rwDEFAULT
   ,rwDEFERRABLE
   ,rwDEFERRED
   ,rwDELETE
   ,rwDESC
   ,rwDESCRIBE
   ,rwDESCRIPTOR
   ,rwDIAGNOSTICS
   ,rwDISCONNECT
   ,rwDISTINCT
   ,rwDOMAIN
   ,rwDOUBLE
   ,rwDROP
   ,rwELSE
   ,rwEND
   ,rwEND_EXEC
   ,rwESCAPE
   ,rwEXCEPT
   ,rwEXCEPTION
   ,rwEXEC
   ,rwEXECUTE
   ,rwEXISTS
   ,rwEXTERNAL
   ,rwEXTRACT
   ,rwFALSE
   ,rwFETCH
   ,rwFIRST
   ,rwFLOAT
   ,rwFOR
   ,rwFOREIGN
   ,rwFOUND
   ,rwFROM
   ,rwFULL
   ,rwGET
   ,rwGLOBAL
   ,rwGO
   ,rwGOTO
   ,rwGRANT
   ,rwGROUP
   ,rwHEX
   ,rwHAVING
   ,rwHOUR
   ,rwIDENTITY
   ,rwIF
   ,rwIMMEDIATE
   ,rwIN
   ,rwINDICATOR
   ,rwINITIALLY
   ,rwINNER
   ,rwINPUT
   ,rwINSENSITIVE
   ,rwINSERT
   ,rwINT
   ,rwINTEGER
   ,rwINTERSECT
   ,rwINTERVAL
   ,rwINTO
   ,rwIS
   ,rwISNULL
   ,rwISOLATION
   ,rwJOIN
   ,rwKEY
   ,rwLANGUAGE
   ,rwLAST
   ,rwLEADING
   ,rwLEFT
   ,rwLEVEL
   ,rwLIKE
   ,rwLOCAL
   ,rwLOWER
   ,rwMATCH
   ,rwMAX
   ,rwMEMORY
   ,rwMIME64
   ,rwMIN
   ,rwMINUS
   ,rwMINUTE
   ,rwMODULE
   ,rwMONTH
   ,rwNAMES
   ,rwNATIONAL
   ,rwNATURAL
   ,rwNAnsiChar
   ,rwNEXT
   ,rwNO
   ,rwNOFLUSH
   ,rwNOT
   ,rwNULL
   ,rwNULLIF
   ,rwNUMERIC
   ,rwOCTET_LENGTH
   ,rwOF
   ,rwON
   ,rwONLY
   ,rwOPEN
   ,rwOPTION
   ,rwOR
   ,rwORDER
   ,rwOUTER
   ,rwOUTPUT
   ,rwOVERLAPS
   ,rwPAD
   ,rwPARTIAL
   ,rwPOSITION
   ,rwPRECISION
   ,rwPREPARE
   ,rwPRESERVE
   ,rwPRIMARY
   ,rwPRIOR
   ,rwPRIVILEGES
   ,rwPROCEDURE
   ,rwPUBLIC
   ,rwREAD
   ,rwREAL
   ,rwREFERENCES
   ,rwRELATIVE
   ,rwRESTRICT
   ,rwREVOKE
   ,rwRIGHT
   ,rwROLLBACK
   ,rwROWS
   ,rwSCHEMA
   ,rwSCROLL
   ,rwSECOND
   ,rwSECTION
   ,rwSELECT
   ,rwSESSION
   ,rwSESSION_USER
   ,rwSET
   ,rwSIZE
   ,rwSMALLINT
   ,rwSOME
   ,rwSPACE
   ,rwSQL
   ,rwSQLCODE
   ,rwSQLERROR
   ,rwSQLSTATE
   ,rwSTART
   ,rwSUBSTRING
   ,rwSUM
   ,rwSYSTEM_USER
   ,rwTABLE
   ,rwTEMPORARY
   ,rwTHEN
   ,rwTIME
   ,rwTIMESTAMP
   ,rwTIMEZONE_HOUR
   ,rwTIMEZONE_MINUTE
   ,rwTO
   ,rwTOP
   ,rwTRAILING
   ,rwTRANSACTION
   ,rwTRANSLATE
   ,rwTRANSLATION
   ,rwTRIM
   ,rwTRUE
   ,rwUNION
   ,rwUNIQUE
   ,rwUNKNOWN
   ,rwUPDATE
   ,rwUPPER
   ,rwUSAGE
   ,rwUSER
   ,rwUSING
   ,rwVALUE
   ,rwVALUES
   ,rwVARCHAR
   ,rwVARYING
   ,rwVIEW
   ,rwWHEN
   ,rwWHENEVER
   ,rwWHERE
   ,rwWITH
   ,rwWORK
   ,rwWRITE
   ,rwYEAR
   ,rwZONE
   ,rwPASSWORD                // for DDL commands
   ,rwBLOBBLOCKSIZE           // for DDL commands
   ,rwBLOBCOMPRESSIONMODE     // for DDL commands
   ,rwBLOBCOMPRESSIONALGORITHM// for DDL commands
   ,rwLAST_AUTOINC            // for DDL commands
   ,rwMODIFY                  // alter table blablabla modify ...
   ,rwNEW                     // for NEW PASSWORD in ALTER TABLE
   ,rwINDEX                   // for CREATE INDEX ...
   ,rwNOCASE                  // for CREATE INDEX ... NOCASE
   ,rwLTRIM
   ,rwRTRIM
   ,rwPOS
   ,rwLENGTH
   ,rwSYSDATE
   ,rwNOW
   ,rwTOBLOB
   ,rwTODATE
   ,rwTOSTRING
   ,rwAUTOINDEXES
   ,rwNOAUTOINDEXES
   ,rwINCREMENT
   ,rwLASTVALUE
   ,rwMAXVALUE
   ,rwMINVALUE
   ,rwCYCLED
   ,rwNOMAXVALUE
   ,rwNOMINVALUE
   ,rwNOCYCLED
   ,rwINITIALVALUE
   ,rwRENAME
   ,rwQUARTER
   ,rwWEEKDAY
   ,rwDAYOFWEEK
   ,rwDAYNAME
   ,rwMONTHNAME
   ,rwMSECOND
   ,rwABS
   ,rwCEILING
   ,rwCEIL
   ,rwFLOOR
   ,rwMOD
   ,rwPOWER
   ,rwPOW
   ,rwRANDOM
   ,rwRAND
   ,rwROUND
   ,rwSIGN
   ,rwTRUNCATE
   ,rwTRUNC
   ,rwSHL
   ,rwSHR
   ,rwXOR
   ,rwDATABASE
   ,rwFILE
   ,rwPAGESIZE
   ,rwMAXSESSIONSCOUNT
   ,rwCUMSUM
   ,rwCUMPROD
   ,rwGROUP_CONCAT
   // v.5
   ,rwCOMMENT
   ,rwTABLES
   // v.5.10
   ,rwFUNCTION
   ,rwVAR
   ,rwRESULT
   // all SQL types are reserved words
   ,rwFIXEDCHAR
   ,rwVARCHAR2
   ,rwSTRING
   ,rwWIDECHAR
   ,rwFIXEDWIDECHAR
   ,rwWIDESTRING
   ,rwWIDEVARCHAR
   ,rwSIGNEDINT16
   ,rwSIGNEDINT32
   ,rwSIGNEDINT64
   ,rwLARGEINT
   ,rwINT64
   ,rwUNSIGNEDINT16
   ,rwWORD
   ,rwSIGNEDINT8
   ,rwSHORTINT
   ,rwUNSIGNEDINT8
   ,rwBYTE
   ,rwUNSIGNEDINT32
   ,rwCARDINAL
   ,rwAUTOINC
   ,rwAUTOINCSHORTINT
   ,rwAUTOINCSMALLINT
   ,rwAUTOINCINTEGER
   ,rwAUTOINCLARGEINT
   ,rwAUTOINCBYTE
   ,rwAUTOINCWORD
   ,rwAUTOINCCARDINAL
   ,rwSINGLE
   ,rwEXTENDED
   ,rwLOGICAL
   ,rwBOOLEAN
   ,rwBOOL
   ,rwCURRENCY
   ,rwMONEY
   ,rwDATETIME
   ,rwBYTES
   ,rwVARBYTES
   ,rwGRAPHIC
   ,rwMEMO
   ,rwCLOB
   ,rwFORMATTEDMEMO
   ,rwWIDEMEMO
   ,rwWIDECLOB
   // v.5.60
   ,rwDATEADD
   ,rwDATEDIFF
   ,rwWEEK
   ,rwMILLISECOND
   // v.5.80
   ,rwFLUSH
   ,rwEMPTY
   ,rwIFNULL
   // v.5.85
   ,rwDAYOFYEAR
   ,rwISOWEEK
   // v.5.90
   ,rwSTDDEV
   ,rwSTDEV
   ,rwCONCAT
   ,rwASCII
   ,rwCHR
   ,rwREPEAT
   ,rwREPLACE
   ,rwEXP
   ,rwLOG
   ,rwLN
   ,rwLOG10
   ,rwCOS
   ,rwSIN
   ,rwACOS
   ,rwASIN
   ,rwATAN
   ,rwATAN2
   ,rwCOT
   ,rwTAN
   ,rwSQR
   ,rwSQRT
   ,rwSQUARE
   ,rwDEGREES
   ,rwRADIANS
   ,rwPI
   ,rwDIV
   // none - not a reserved word
   ,rwNone
  );

const
  ACRMaxSQLReservedWords = 378;
  ACRSQLReservedWords: array[0..ACRMaxSQLReservedWords] of WideString =
  (
// standard reserved words
   'ABSOLUTE'
   ,'ACTION'
   ,'ADD'
   ,'ALL'
   ,'ALLOCATE'
   ,'ALTER'
   ,'AND'
   ,'ANY'
   ,'ARE'
   ,'AS'
   ,'ASC'
   ,'ASSERTION'
   ,'AT'
   ,'AUTHORIZATION'
   ,'AVG'
   ,'BEGIN'
   ,'BETWEEN'
   ,'BIT'
   ,'BIT_LENGTH'
   ,'BOTH'
   ,'BY'
   ,'CASCADE'
   ,'CASCADED'
   ,'CASE'
   ,'CAST'
   ,'CATALOG'
   ,'CHAR'
   ,'CHARACTER'
   ,'CHAR_LENGTH'
   ,'CHARACTER_LENGTH'
   ,'CHECK'
   ,'CLOSE'
   ,'COALESCE'
   ,'COLLATE'
   ,'COLLATION'
   ,'COLUMN'
   ,'COMMIT'
   ,'CONNECT'
   ,'CONNECTION'
   ,'CONSTRAINT'
   ,'CONSTRAINTS'
   ,'CONTINUE'
   ,'CONVERT'
   ,'CORRESPONDING'
   ,'COUNT'
   ,'CREATE'
   ,'CROSS'
   ,'CURRENT'
   ,'CURRENT_DATE'
   ,'CURRENT_TIME'
   ,'CURRENT_TIMESTAMP'
   ,'CURRENT_USER'
   ,'CURSOR'
   ,'DATE'
   ,'DAY'
   ,'DEALLOCATE'
   ,'DEC'
   ,'DECIMAL'
   ,'DECLARE'
   ,'DEFAULT'
   ,'DEFERRABLE'
   ,'DEFERRED'
   ,'DELETE'
   ,'DESC'
   ,'DESCRIBE'
   ,'DESCRIPTOR'
   ,'DIAGNOSTICS'
   ,'DISCONNECT'
   ,'DISTINCT'
   ,'DOMAIN'
   ,'DOUBLE'
   ,'DROP'
   ,'ELSE'
   ,'END'
   ,'END-EXEC'
   ,'ESCAPE'
   ,'EXCEPT'
   ,'EXCEPTION'
   ,'EXEC'
   ,'EXECUTE'
   ,'EXISTS'
   ,'EXTERNAL'
   ,'EXTRACT'
   ,'FALSE'
   ,'FETCH'
   ,'FIRST'
   ,'FLOAT'
   ,'FOR'
   ,'FOREIGN'
   ,'FOUND'
   ,'FROM'
   ,'FULL'
   ,'GET'
   ,'GLOBAL'
   ,'GO'
   ,'GOTO'
   ,'GRANT'
   ,'GROUP'
   ,'HEX'
   ,'HAVING'
   ,'HOUR'
   ,'IDENTITY'
   ,'IF'
   ,'IMMEDIATE'
   ,'IN'
   ,'INDICATOR'
   ,'INITIALLY'
   ,'INNER'
   ,'INPUT'
   ,'INSENSITIVE'
   ,'INSERT'
   ,'INT'
   ,'INTEGER'
   ,'INTERSECT'
   ,'INTERVAL'
   ,'INTO'
   ,'IS'
   ,'ISNULL'
   ,'ISOLATION'
   ,'JOIN'
   ,'KEY'
   ,'LANGUAGE'
   ,'LAST'
   ,'LEADING'
   ,'LEFT'
   ,'LEVEL'
   ,'LIKE'
   ,'LOCAL'
   ,'LOWER'
   ,'MATCH'
   ,'MAX'
   ,'MEMORY'
   ,'MIME64'
   ,'MIN'
   ,'MINUS'
   ,'MINUTE'
   ,'MODULE'
   ,'MONTH'
   ,'NAMES'
   ,'NATIONAL'
   ,'NATURAL'
   ,'NCHAR'
   ,'NEXT'
   ,'NO'
   ,'NOFLUSH'
   ,'NOT'
   ,'NULL'
   ,'NULLIF'
   ,'NUMERIC'
   ,'OCTET_LENGTH'
   ,'OF'
   ,'ON'
   ,'ONLY'
   ,'OPEN'
   ,'OPTION'
   ,'OR'
   ,'ORDER'
   ,'OUTER'
   ,'OUTPUT'
   ,'OVERLAPS'
   ,'PAD'
   ,'PARTIAL'
   ,'POSITION'
   ,'PRECISION'
   ,'PREPARE'
   ,'PRESERVE'
   ,'PRIMARY'
   ,'PRIOR'
   ,'PRIVILEGES'
   ,'PROCEDURE'
   ,'PUBLIC'
   ,'READ'
   ,'REAL'
   ,'REFERENCES'
   ,'RELATIVE'
   ,'RESTRICT'
   ,'REVOKE'
   ,'RIGHT'
   ,'ROLLBACK'
   ,'ROWS'
   ,'SCHEMA'
   ,'SCROLL'
   ,'SECOND'
   ,'SECTION'
   ,'SELECT'
   ,'SESSION'
   ,'SESSION_USER'
   ,'SET'
   ,'SIZE'
   ,'SMALLINT'
   ,'SOME'
   ,'SPACE'
   ,'SQL'
   ,'SQLCODE'
   ,'SQLERROR'
   ,'SQLSTATE'
   ,'START'
   ,'SUBSTRING'
   ,'SUM'
   ,'SYSTEM_USER'
   ,'TABLE'
   ,'TEMPORARY'
   ,'THEN'
   ,'TIME'
   ,'TIMESTAMP'
   ,'TIMEZONE_HOUR'
   ,'TIMEZONE_MINUTE'
   ,'TO'
   ,'TOP'
   ,'TRAILING'
   ,'TRANSACTION'
   ,'TRANSLATE'
   ,'TRANSLATION'
   ,'TRIM'
   ,'TRUE'
   ,'UNION'
   ,'UNIQUE'
   ,'UNKNOWN'
   ,'UPDATE'
   ,'UPPER'
   ,'USAGE'
   ,'USER'
   ,'USING'
   ,'VALUE'
   ,'VALUES'
   ,'VARCHAR'
   ,'VARYING'
   ,'VIEW'
   ,'WHEN'
   ,'WHENEVER'
   ,'WHERE'
   ,'WITH'
   ,'WORK'
   ,'WRITE'
   ,'YEAR'
   ,'ZONE'
// end of standard reserved words

   ,'PASSWORD'              // for DDL commands
   ,'BLOBBLOCKSIZE'         // for DDL commands
   ,'BLOBCOMPRESSIONMODE'   // for DDL commands
   ,'BLOBCOMPRESSIONALGORITHM'// for DDL commands
   ,'LASTAUTOINC'           // for DDL commands
   ,'MODIFY'                // alter table blablabla modify ...
   ,'NEW'                   // for NEW PASSWORD in ALTER TABLE
   ,'INDEX'                 // for CREATE INDEX ...
   ,'NOCASE'                // for CREATE INDEX ... NOCASE ..
   ,'LTRIM'
   ,'RTRIM'
   ,'POS'
   ,'LENGTH'
   ,'SYSDATE'               // DateTime function
   ,'NOW'
   ,'TOBLOB'                // TOBLOB function
   ,'TODATE'                // TODATE function
   ,'TOSTRING'                // TOString function
   ,'AUTOINDEXES'           // for DDL AutoIndexes
   ,'NOAUTOINDEXES'         // for DDL AutoIndexes
   ,'INCREMENT'
   ,'LASTVALUE'
   ,'MAXVALUE'
   ,'MINVALUE'
   ,'CYCLED'
   ,'NOMAXVALUE'
   ,'NOMINVALUE'
   ,'NOCYCLED'
   ,'INITIALVALUE'
   ,'RENAME'
   ,'QUARTER'
   ,'WEEKDAY'
   ,'DAYOFWEEK'
   ,'DAYNAME'
   ,'MONTHNAME'
   ,'MSECOND'
// new 4.40
   ,'ABS'
   ,'CEILING'
   ,'CEIL'
   ,'FLOOR'
   ,'MOD'
   ,'POWER'
   ,'POW'
   ,'RANDOM'
   ,'RAND'
   ,'ROUND'
   ,'SIGN'
   ,'TRUNCATE'
   ,'TRUNC'
   ,'SHL'
   ,'SHR'
   ,'XOR'
   ,'DATABASE' // for CREATE/DROP/OPEN/CLOSE DATABASE
   ,'FILE' // for CREATE/DROP DATABASE FILE
   ,'PAGESIZE' // for CREATE/DROP DATABASE FILE
   ,'MAXSESSIONSCOUNT' // for CREATE/DROP DATABASE FILE
   ,'CUMSUM'
   ,'CUMPROD'
   ,'GROUP_CONCAT'
   // v.5
   ,'COMMENT'
   ,'TABLES' // GET TABLES
             // SELECT * FROM TABLES ORDER BY 2 == GET TABLES 2
   // v.5.10
   // stored functions:
   ,'FUNCTION' // GET TABLES
   ,'VAR'      // VAR - used to declare local variables
   ,'RESULT'   // RESULT of the function
   // all SQL types are reserved words
   ,'FIXEDCHAR'
   ,'VARCHAR2'
   ,'STRING'
   ,'WIDECHAR'
   ,'FIXEDWIDECHAR'
   ,'WIDESTRING'
   ,'WIDEVARCHAR'
   ,'SIGNEDINT16'
   ,'SIGNEDINT32'
   ,'SIGNEDINT64'
   ,'LARGEINT'
   ,'INT64'
   ,'UNSIGNEDINT16'
   ,'WORD'
   ,'SIGNEDINT8'
   ,'SHORTINT'
   ,'UNSIGNEDINT8'
   ,'BYTE'
   ,'UNSIGNEDINT32'
   ,'CARDINAL'
   ,'AUTOINC'
   ,'AUTOINCSHORTINT'
   ,'AUTOINCSMALLINT'
   ,'AUTOINCINTEGER'
   ,'AUTOINCLARGEINT'
   ,'AUTOINCBYTE'
   ,'AUTOINCWORD'
   ,'AUTOINCCARDINAL'
   ,'SINGLE'
   ,'EXTENDED'
   ,'LOGICAL'
   ,'BOOLEAN'
   ,'BOOL'
   ,'CURRENCY'
   ,'MONEY'
   ,'DATETIME'
   ,'BYTES'
   ,'VARBYTES'
   ,'GRAPHIC'
   ,'MEMO'
   ,'CLOB'
   ,'FORMATTEDMEMO'
   ,'WIDEMEMO'
   ,'WIDECLOB'
   // all SQL types are reserved words
   // v.5.60
   ,'DATEADD'
   ,'DATEDIFF'
   ,'WEEK'
   ,'MILLISECOND'
   // v.5.80
   ,'FLUSH'
   ,'EMPTY'
   ,'IFNULL'
   // v.5.85
   ,'DAYOFYEAR'
   ,'ISOWEEK'
   // v.5.90
   ,'STDDEV'
   ,'STDEV'
   ,'CONCAT'
   ,'ASCII'
   ,'CHR'
   ,'REPEAT'
   ,'REPLACE'
   ,'EXP'
   ,'LOG'
   ,'LN'
   ,'LOG10'
   ,'COS'
   ,'SIN'
   ,'ACOS'
   ,'ASIN'
   ,'ATAN'
   ,'ATAN2'
   ,'COT'
   ,'TAN'
   ,'SQR'
   ,'SQRT'
   ,'SQUARE'
   ,'DEGREES'
   ,'RADIANS'
   ,'PI'
   ,'DIV'
  );

var ACRSQLReservedWordsCRC: array[0..ACRMaxSQLReservedWords] of Cardinal;
{$IFNDEF D6H}
function WideUpperCase(const S: WideString): WideString;
{$ENDIF}
function ACR_CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord; assembler; register;
// return crc of the table name
function GetTableNameCRCAnsi(TableName: AnsiString; ToUpper: Boolean = true): Cardinal;
function GetTableNameCRC(TableName: WideString; ToUpper: Boolean = true): Cardinal;

implementation


uses ACRTypes;


{$IFNDEF D6H}
function WideUpperCase(const S: WideString): WideString;
{$IFDEF MSWINDOWS}
var
  Len: Integer;
begin
  Len := Length(S);
  SetString(Result, PWideChar(S), Len);
  if Len > 0 then CharUpperBuffW(Pointer(Result), Len);
end;
{$ENDIF}
{$ENDIF}

{$IFDEF X64_ON}
const
  CRC32_Table : array[0..267] of dword = (
    $000000000,$077073096,$0EE0E612C,$0990951BA,$0076DC419,$0706AF48F,$0E963A535,$09E6495A3,$00EDB8832,$079DCB8A4,
    $0E0D5E91E,$097D2D988,$009B64C2B,$07EB17CBD,$0E7B82D07,$090BF1D91,$01DB71064,$06AB020F2,$0F3B97148,$084BE41DE,
    $01ADAD47D,$06DDDE4EB,$0F4D4B551,$083D385C7,$0136C9856,$0646BA8C0,$0FD62F97A,$08A65C9EC,$014015C4F,$063066CD9,
    $0FA0F3D63,$08D080DF5,$03B6E20C8,$04C69105E,$0D56041E4,$0A2677172,$03C03E4D1,$04B04D447,$0D20D85FD,$0A50AB56B,
    $035B5A8FA,$042B2986C,$0DBBBC9D6,$0ACBCF940,$032D86CE3,$045DF5C75,$0DCD60DCF,$0ABD13D59,$026D930AC,$051DE003A,
    $0C8D75180,$0BFD06116,$021B4F4B5,$056B3C423,$0CFBA9599,$0B8BDA50F,$02802B89E,$05F058808,$0C60CD9B2,$0B10BE924,
    $02F6F7C87,$058684C11,$0C1611DAB,$0B6662D3D,$076DC4190,$001DB7106,$098D220BC,$0EFD5102A,$071B18589,$006B6B51F,
    $09FBFE4A5,$0E8B8D433,$07807C9A2,$00F00F934,$09609A88E,$0E10E9818,$07F6A0DBB,$0086D3D2D,$091646C97,$0E6635C01,
    $06B6B51F4,$01C6C6162,$0856530D8,$0F262004E,$06C0695ED,$01B01A57B,$08208F4C1,$0F50FC457,$065B0D9C6,$012B7E950,
    $08BBEB8EA,$0FCB9887C,$062DD1DDF,$015DA2D49,$08CD37CF3,$0FBD44C65,$04DB26158,$03AB551CE,$0A3BC0074,$0D4BB30E2,
    $04ADFA541,$03DD895D7,$0A4D1C46D,$0D3D6F4FB,$04369E96A,$0346ED9FC,$0AD678846,$0DA60B8D0,$044042D73,$033031DE5,
    $0AA0A4C5F,$0DD0D7CC9,$05005713C,$0270241AA,$0BE0B1010,$0C90C2086,$05768B525,$0206F85B3,$0B966D409,$0CE61E49F,
    $05EDEF90E,$029D9C998,$0B0D09822,$0C7D7A8B4,$059B33D17,$02EB40D81,$0B7BD5C3B,$0C0BA6CAD,$0EDB88320,$09ABFB3B6,
    $003B6E20C,$074B1D29A,$0EAD54739,$09DD277AF,$004DB2615,$073DC1683,$0E3630B12,$094643B84,$00D6D6A3E,$07A6A5AA8,
    $0E40ECF0B,$09309FF9D,$00A00AE27,$07D079EB1,$0F00F9344,$08708A3D2,$01E01F268,$06906C2FE,$0F762575D,$0806567CB,
    $0196C3671,$06E6B06E7,$0FED41B76,$089D32BE0,$010DA7A5A,$067DD4ACC,$0F9B9DF6F,$08EBEEFF9,$017B7BE43,$060B08ED5,
    $0D6D6A3E8,$0A1D1937E,$038D8C2C4,$04FDFF252,$0D1BB67F1,$0A6BC5767,$03FB506DD,$048B2364B,$0D80D2BDA,$0AF0A1B4C,
    $036034AF6,$041047A60,$0DF60EFC3,$0A867DF55,$0316E8EEF,$04669BE79,$0CB61B38C,$0BC66831A,$0256FD2A0,$05268E236,
    $0CC0C7795,$0BB0B4703,$0220216B9,$05505262F,$0C5BA3BBE,$0B2BD0B28,$02BB45A92,$05CB36A04,$0C2D7FFA7,$0B5D0CF31,
    $02CD99E8B,$05BDEAE1D,$09B64C2B0,$0EC63F226,$0756AA39C,$0026D930A,$09C0906A9,$0EB0E363F,$072076785,$005005713,
    $095BF4A82,$0E2B87A14,$07BB12BAE,$00CB61B38,$092D28E9B,$0E5D5BE0D,$07CDCEFB7,$00BDBDF21,$086D3D2D4,$0F1D4E242,
    $068DDB3F8,$01FDA836E,$081BE16CD,$0F6B9265B,$06FB077E1,$018B74777,$088085AE6,$0FF0F6A70,$066063BCA,$011010B5C,
    $08F659EFF,$0F862AE69,$0616BFFD3,$0166CCF45,$0A00AE278,$0D70DD2EE,$04E048354,$03903B3C2,$0A7672661,$0D06016F7,
    $04969474D,$03E6E77DB,$0AED16A4A,$0D9D65ADC,$040DF0B66,$037D83BF0,$0A9BCAE53,$0DEBB9EC5,$047B2CF7F,$030B5FFE9,
    $0BDBDF21C,$0CABAC28A,$053B39330,$024B4A3A6,$0BAD03605,$0CDD70693,$054DE5729,$023D967BF,$0B3667A2E,$0C4614AB8,
    $05D681B02,$02A6F2B94,$0B40BBE37,$0C30C8EA1,$05A05DF1B,$02D02EF8D,$074726F50,$0736E6F69,$0706F4320,$067697279,
    $028207468,$031202963,$020393939,$048207962,$06E656761,$064655220,$06E616D64,$06FBBA36E
  );

function ACR_CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord;  register;
var
  wData : PByteArray absolute Data;
  i     : integer;
begin
  if ( Data <> nil ) and ( DataSize > 0 )
    then
      begin
        {CRC := not CRC;}
        for i := 0 to DataSize - 1 do
          CRC := CRC32_Table[ wData[i] xor byte(CRC) ] xor ( CRC shr 8 );
      end;
  Result := {not} CRC;
end;
{$ELSE}
// DEC 3
function ACR_CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord; assembler; register;
asm
         AND    EDX,EDX
         JZ     @Exit
         AND    ECX,ECX
         JLE    @Exit
         PUSH   EBX
         PUSH   EDI
         XOR    EBX,EBX
         LEA    EDI,CS:[OFFSET @CRC_32]
@Start:  MOV    BL,AL
         SHR    EAX,8
         XOR    BL,[EDX]
         XOR    EAX,[EDI + EBX * 4]
         INC    EDX
         DEC    ECX
         JNZ    @Start
         POP    EDI
         POP    EBX
@Exit:   RET
         DB 0, 0, 0, 0, 0 // Align Table
@CRC_32: DD 000000000h, 077073096h, 0EE0E612Ch, 0990951BAh
         DD 0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h
         DD 00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h
         DD 009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h
         DD 01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh
         DD 01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h
         DD 0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh
         DD 014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h
         DD 03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h
         DD 03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh
         DD 035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h
         DD 032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h
         DD 026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h
         DD 021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh
         DD 02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h
         DD 02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh
         DD 076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah
         DD 071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h
         DD 07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h
         DD 07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h
         DD 06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh
         DD 06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h
         DD 065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch
         DD 062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h
         DD 04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h
         DD 04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh
         DD 04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h
         DD 044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h
         DD 05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h
         DD 05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh
         DD 05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h
         DD 059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh
         DD 0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah
         DD 0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h
         DD 0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h
         DD 0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h
         DD 0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh
         DD 0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h
         DD 0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh
         DD 0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h
         DD 0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h
         DD 0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh
         DD 0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h
         DD 0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h
         DD 0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h
         DD 0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh
         DD 0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h
         DD 0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh
         DD 09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah
         DD 09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h
         DD 095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h
         DD 092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h
         DD 086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh
         DD 081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h
         DD 088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch
         DD 08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h
         DD 0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h
         DD 0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh
         DD 0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h
         DD 0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h
         DD 0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h
         DD 0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh
         DD 0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h
         DD 0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh
         DD 074726F50h, 0736E6F69h, 0706F4320h, 067697279h
         DD 028207468h, 031202963h, 020393939h, 048207962h
         DD 06E656761h, 064655220h, 06E616D64h, 06FBBA36Eh
end;
{$ENDIF}

function GetTableNameCRCAnsi(TableName: AnsiString; ToUpper: Boolean): Cardinal;
var FTableName: AnsiString;
    l:          Integer;
begin
 l := Length(TableName);
 if (l = 0) then
  Result := 0
 else
 if (ToUpper) then
  begin
   if (l <= 0) then
    Result := 0
   else
   begin
    FTableName := AnsiUpperCase(TableName);
    Result := ACR_CRC32(0,PAnsiChar(@FTableName[1]),l)
   end;
  end
 else
  begin
   if (l <= 0) then
    Result := 0
   else
    Result := ACR_CRC32(0,PAnsiChar(@TableName[1]),l);
  end;
end; // GetTableNameCRCAnsi


function GetTableNameCRC(TableName: WideString; ToUpper: Boolean): Cardinal;
var FTableName: WideString;
    l:          Integer;
begin
 l := Length(TableName) * 2;
 if (l = 0) then
  Result := 0
 else
 if (ToUpper) then
  begin
   if (l <= 0) then
    Result := 0
   else
   begin
    FTableName := WideUpperCase(TableName);
    Result := ACR_CRC32(0,PAnsiChar(@FTableName[1]),l)
   end;
  end
 else
  begin
   if (l <= 0) then
    Result := 0
   else
    Result := ACR_CRC32(0,PAnsiChar(@TableName[1]),l);
  end;
end; // GetTableNameCRC


procedure DetectOSType;
var
//  OSVersion:    TOSVersionInfo;
  vers,dwWindowsMajorVersion,dwWindowsMinorVersion: DWORD;
begin
 {$IFDEF LINUX}
 ACR_OS_Type := osLinux;
 {$ELSE}
    // Get Windows Version
// changed in 4.96 - for Wn9x compatibility
    vers := GetVersion;
    dwWindowsMajorVersion := LOBYTE(LOWORD(vers));
    dwWindowsMinorVersion := HIBYTE(LOWORD(vers));
    ACR_OS_Type := osWin95;
    if (dwWindowsMajorVersion >= 7) then
      ACR_OS_Type := osWin7
    else
      case dwWindowsMajorVersion of
        3: ACR_OS_Type := osWinNT351;
        4: case dwWindowsMinorVersion of
            0:
                 // high bit not set
                 if (vers < $80000000) then
                  ACR_OS_Type := osWinNT4;
            10:  ACR_OS_Type := osWin98;
            90:  ACR_OS_Type := osWinME;
          end;
       5: case dwWindowsMinorVersion of
            0:   ACR_OS_Type := osWin2K;
            1:   ACR_OS_Type := osWinXP;
            2:   ACR_OS_Type := osWinNET;
          end;
        6: ACR_OS_Type := osWinVista;
      end;
{
//    FillChar(OSVersion, SizeOf(TOSVersionInfo), 0);
//    OSVersion.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
//    GetVersionEx(OSVersion);
    // Set version to Unknown for default
    ACR_OS_Type := osUnknown;

    if (OSVersion.dwPlatformId = VER_PLATFORM_WIN32s) then
     ACR_OS_Type := osWin3
    else
      case OSVersion.dwMajorVersion of
       3: ACR_OS_Type := osWinNT351;
       4: case OSVersion.dwMinorVersion of
            0:   if OSVersion.dwPlatformId = 1 then ACR_OS_Type := osWin95
                                               else ACR_OS_Type := osWinNT4;
            10:  ACR_OS_Type := osWin98;
            90:  ACR_OS_Type := osWinME;
          end;
       5: case OSVersion.dwMinorVersion of
            0:   ACR_OS_Type := osWin2K;
            1:   ACR_OS_Type := osWinXP;
            2:   ACR_OS_Type := osWinNET;
          end;
       6: ACR_OS_Type := osWinVista;
      end;
}
 {$ENDIF}
 ACR_OS_WINNT_COMPATIBLE := ACR_OS_Type in
    [osWinNT351,osWinNT4,osWin2K,osWinXP,osWinNET,osWinVista,osWin7];
end; // DetectOSType


procedure InitReservedWords;
var i: Cardinal;
begin
  for i := 0 to ACRMaxSQLReservedWords do
   ACRSQLReservedWordsCRC[i] := GetTableNameCRC(ACRSQLReservedWords[i],False);
end; // InitReservedWords


procedure InitTableOperationNames;
var i,l: Cardinal;
begin
  ACRMaxLastTableOperationNamesLength := 1;
  for i := 0 to High(ACRLastTableOperationNames) do
   begin
    l := Length(ACRLastTableOperationNames[i]);
    if (l > ACRMaxLastTableOperationNamesLength) then
     ACRMaxLastTableOperationNamesLength := l;
   end;
end; // InitTableOperationNames


initialization

ACR_ENCRYPTED_DB_USED := False;
ACRDiskSignature[0] := ACRDiskSignature1;
DetectOSType;
InitReservedWords;
InitTableOperationNames;
IsDesignMode := False;
{$IFNDEF TRIAL_VERSION}
{$IFDEF FILE_SERVER_VERSION}
ACRDefaultSessionCount := (ACRDefaultPageSize - ACRTableLockedBytesCount -
    SizeOf(TACRTableLockFileHeader) -
    SizeOf(TACRDiskPageHeader) - SizeOf(TACRInternalFileHeader)) div (4 + SizeOf(TACRRecordID));
{$ENDIF}
{$ENDIF}

end.
