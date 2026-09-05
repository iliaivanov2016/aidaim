unit MsgConst;

interface

uses  SysUtils;

{$I MsgVer.inc}

{$I MsgErrorL.inc}
{$I MsgErrorR.inc}

type  TMsgSignature = Array [0..3] of AnsiChar;

{$IFDEF MsgCommunicator}
{$IFDEF RELEASE_BUILD}
const MsgVersionText = '';
{$ELSE}
const MsgVersionText = 'Pre-release #1';
{$ENDIF}
const MsgVersion = 21.00;
{$ENDIF}

const crlf = #13#10;
const MsgServerConfigFileExtension = '.ini';
{$IFDEF TRIAL_VERSION}
 {$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
    MsgBuildInfo = 'Trial Without Nag-Screen';
 {$ELSE}
    MsgBuildInfo = 'Trial With Nag-Screen';
 {$ENDIF}
{$ELSE}
 MsgBuildInfo = 'Full';
{$ENDIF}

var IsDesignMode:            Boolean;

//------------------------------------------------------------------------------
// MsgVariant
//------------------------------------------------------------------------------
{$IFDEF LINUX}
// const MAX_INTEGER = 2147483647;
 const MAX_STRING_LENGTH = 99 * 1024; // To avoid memory problem with old libc.so
// 4 * 1024 * 1024 - 4 - 1;  // WideUpperCase works slow
// 2147483647 div 32 - 4; // really works, but too slow
{$ENDIF}
 const MsgExpressionMaxStringSize = 255;

 MsgAntifreezeTimeOut = 3000; // 3 sec to refresh the form
// MsgAntifreezeSleep   = 50;  // 0.05 sec as max to destroy refreshing thread

//------------------------------------------------------------------------------
// Connection consts
//------------------------------------------------------------------------------

 MsgFirstResendPushUpTimeout = 20;

// Maximum threads number
 MsgMaxThreadCount = MAXINT;// 2147483647; // MAX_INTEGER;;

 MsgLocalMaxThreadCount = MAXINT;
 MsgLANMaxThreadCount = 500;
 MsgWANMaxThreadCount = 1000;
 MsgModemMaxThreadCount = 50;

// Maximum message threads per one client
 MsgMaxMsgThreads = 5;

 MsgLocalMaxMsgThreads = 500;
 MsgLANMaxMsgThreads = 10;
 MsgWANMaxMsgThreads = 5;
 MsgModemMaxMsgThreads = 1;

// pause before re-creating thread finished abnormally
 MsgThreadRecreateSleep = 1; // 100;

//------------------------------------------------------------------------------

// Allow connection parameters auto correction
 MsgConnectionParamsTunning = False;
// MsgConnectionParamsTunning = True;

// Number of packets to test network for connection parameters auto tunning
 MsgTestPacketCount = 8;

// To connect - Client only
 MsgLocalConnectRetryCount = 20;
 MsgLocalConnectDelay = 500;

 MsgConnectRetryCount = 30;
 MsgConnectDelay = 1000;

 MsgWANConnectRetryCount = 30;
 MsgWANConnectDelay = 2000;

 MsgModemConnectRetryCount = 60;
 MsgModemConnectDelay = 2000;

// To receive full session buffer
 MsgStartReceiveTimeOut = 30000;   // - Client only, time to wait for the first packet in answer
 MsgReceiveTimeOut = 60000;        // - Client only, time since the first packet to the latest
 MsgReceiveSleep = 1;              // - Client only, time to sleep while receive buffer to allow incoming packets processing, >=0, <= 100

 MsgPacketProcessTimeOut = 100;    // - Both, time to switch sleep delay from 0 to 1 in case the packet queue is empty

 MsgLocalServerReceiveTimeOut =  30000;  // - Server only
 MsgServerReceiveTimeOut      =  30000;
 MsgWANServerReceiveTimeOut   =  60000;
 MsgModemServerReceiveTimeOut = 120000;
 MsgServerReceiveSleep = 0;         // - Server only   >=0, <= 100

// To send buffer
 MsgMinSendTimeOut =      30000;        // - Client only
{$IFDEF MsgCommunicator}
 MsgSendTimeOut =         60000;        // - Client only
{$ELSE}
 MsgSendTimeOut =         300000;        // - Client only
{$ENDIF}
// ------------------------------------------ Server only
 MsgLocalMinServerSendTimeOut =    1000;
 MsgLocalServerSendTimeOut    =   10000;

 MsgMinServerSendTimeOut      =    3000;
 MsgServerSendTimeOut         =   20000;

 MsgWANMinServerSendTimeOut   =   10000;
 MsgWANServerSendTimeOut      =   30000;

 MsgModemMinServerSendTimeOut =  120000;
 MsgModemServerSendTimeOut    =  300000;

// Wait for end of all other sessions messages sending
 MsgLocalWaitForMessagesSend  =   60000;   // Server only
 MsgWaitForMessagesSend       =  180000;
 MsgWANWaitForMessagesSend    =  600000;
 MsgModemWaitForMessagesSend  = 1200000;

// delay to try to resend block af large object in case of failure
 MsgBlockSendDelay  =   100;   // Server and Client

// To send new request to ask other side to resend broken packet
 MsgWaitForSendSleep = 1;        // - Client only, time to sleep in sending check after MsgMaxSendShortSleepTime exceeding. To avoid 100% CPU usage must be > 0.
 MsgMaxSendShortSleepTime = 200; // - Client only, time to to check sending with 0 interval - sleep 0 - sleep(0) for best speed, after that it will sleep(MsgWaitForSendSleep).

// -------------------------------- - Client only
 MsgLocalResendDelay  = 40;           // delay (msec) before resend requested packet, >=1, <= 100
 MsgLocalRequestDelay = 50;           // delay (msec) before request lost packet, >=1, <= 100

 MsgResendDelay = 300;
 MsgRequestDelay = 300;

 MsgWANResendDelay = 500;
 MsgWANRequestDelay = 500;

 MsgModemResendDelay = 800;
 MsgModemRequestDelay = 1000;

// --------------------------------
 MsgServerWaitForSendSleep = 0;  // - Server only, =0 for best speed
// -------------------------------- - Server only
 MsgLocalServerResendDelay = 35; // >0, <= 100
 MsgLocalServerRequestDelay = 50;// >=0, <= 100

 MsgServerResendDelay  = 300;
 MsgServerRequestDelay = 3000;

 MsgWANServerResendDelay = 500;
 MsgWANServerRequestDelay = 10000;

 MsgModemServerResendDelay = 800;
 MsgModemServerRequestDelay = 10000;

// To Diconnect
 MsgDisconnectRetryCount = 12;   // Both Client and Server
 MsgDisconnectDelay = 300;       // Both Client and Server

 MsgLocalDisconnectRetryCount = 10;
 MsgLocalDisconnectDelay = 20;

 MsgWANDisconnectRetryCount = 20;
 MsgWANDisconnectDelay = 50;

 MsgModemDisconnectRetryCount = 10;
 MsgModemDisconnectDelay = 300;

//------------------------------------------------------------------------------

// Timeout for sending a block of large omject (file or stream)
 MsgBlockSendingTimeOut = 600000;

// Wait for Session finishing
{$IFDEF MsgCommunicator}
 MsgWaitForTimeOut =  10000;        // Client only
{$ELSE}
 MsgWaitForTimeOut = 120000;        // Client only
{$ENDIF}

// Wait for Server Session Thread finishing
 MsgWaitForServerSessionThreadFinish  = 500;
{$IFDEF MsgCommunicator}
 MsgWaitForServerSessionThreadTimeOut = 60000;     // Server only
{$ELSE}
 MsgWaitForServerSessionThreadTimeOut = 600000;    // Server only
{$ENDIF}

// Wait for other threads finish to free shared object
{$IFDEF MsgCommunicator}
 MsgThreadsTerminateDelay =       3000;   // Client
{$ELSE}
 MsgThreadsTerminateDelay =      30000;   // Client
{$ENDIF}
 MsgServerThreadsTerminateDelay = 1000;   // Server

// Pause between loops
 MsgServerSessionTerminatorSleep = 100; // Server

// Enable/Disable disconect by timeout
 MsgPingClients = True;        // Server
// Wait for alive confirmation
 MsgLocalPingCount       = 3;
 MsgPingCount            = 8;
 MsgWANPingCount         = 10;
 MsgModemPingCount       = 15;

 MsgLocalWaitForPingAnswer =  30000;
 MsgWaitForPingAnswer      = 120000;
 MsgWANWaitForPingAnswer   = 180000;
 MsgModemWaitForPingAnswer = 300000;

// Pause between pings
 MsgServerPingSleep      = 20; // Server, >=1, low priority thread

// keep connection when IP address or port changes; disable to prevent IP spoofing
 MsgKeepConnection = True;        // Server
 
//------------------------------------------------------------------------------
// Packet size
//------------------------------------------------------------------------------

 const MsgMinPacketSize = 128;      // PacketHeader = 33
 const MsgMaxPacketSize = 65507;    // 65507 - max UDP datagram size
{
MTU:
========================
 1500 - Ethernet
 1492 - IEEE 802.3/802.2 -- works without firewalls/routers only!
 1464 - tested on real internet (1472 - max value for up to 200 packets request)
  576 - X.25
}
 const MsgLocalDefaultPacketSize = MsgMaxPacketSize;
 const MsgDefaultPacketSize = 1464;
 const MsgWANDefaultPacketSize = 1464;
 const MsgModemDefaultPacketSize = 576; // 1000;
 const MsgDefaultClientPort = 0; // 12008;
 const MsgDefaultServerPort = 12007;// Cannot be the same as MsgDefaultClientPort

 const MsgMaxFilesToSend = MAXINT;

 const MsgDefaultAuthorizationBufferSize = 512;
 const MsgDefaultServerID = 0;
 const MsgDefaultHost = '127.0.0.1';  // 'localhost' - delay about 100 msec to resolve
 const MsgDefaultServerHost = '';     // 'localhost' - delay about 100 msec to resolve
 
 const WildCardMultipleChar = '*'; 
 const WildCardSingleChar = '?'; 
 const WildCardAnyFile = '*.*'; 
 
{$IFDEF MsgCommunicator} 
 const MsgDefaultServerConfigFileName = 'MsgServer.ini'; 
 const MsgServerDescription = 'MsgCommunicator Server'; 
{$ELSE} 
 const MsgServerDescription = 'Accuracer Database Server'; 
 const MsgDefaultServerConfigFileName = 'AccuracerDatabaseServer.ini';
 const MsgDefaultDBName = 'DBDemos';
 const MsgDefaultDBFileName = '..\..\..\Demos\Data\DBDemos.adb';
{$ENDIF} 

 
{******************************************************************************} 
 
//------------------------------------------------------------------------------ 
// disk consts 
//------------------------------------------------------------------------------ 
 
{$IFDEF LINUX} 
 const INVALID_FILE_SIZE = -1; 
 const INVALID_HANDLE_VALUE = -1; 
{$ENDIF} 
 var MsgDefaultTempDir: AnsiString;
 const MsgDefaultRetryCount = 10; 
 const MsgDefaultDelay = 500; // ms
 const MsgMinRetryCount = 10; 
 const MsgMinDelay = 0; 
 const MsgMAXLastLockRetryTime = 2000; // ms
 const MsgMAXLockFileTime = 2500; // ms  > MsgMAXLastLockRetryTime
 {$IFDEF TRIAL_VERSION}
 const MsgMaxSingleUserConnections = 10; 
 {$ELSE}
 var MsgMaxSingleUserConnections: Integer = 1000000; // 1M
 {$ENDIF} 
 
	
//------------------- ENCRYPTION CONSTS -------------------------------------------
 
const Msg_Cipher_None = 0;
const Msg_Cipher_Rijndael_128 = 1;
const Msg_Cipher_Rijndael_256 = 2; 
const Msg_Cipher_Blowfish = 3;
const Msg_Cipher_Twofish_128 = 4; 
const Msg_Cipher_Twofish_256 = 5;
const Msg_Cipher_Square = 6;
const Msg_Cipher_Des_Single_8 = 7; 
const Msg_Cipher_Des_Double_8 = 8; 
const Msg_Cipher_Des_Double_16 = 9;
const Msg_Cipher_Des_Triple_8 = 10; 
const Msg_Cipher_Des_Triple_16 = 11;
const Msg_Cipher_Des_Triple_24 = 12; 
 
const Msg_Cipher_Mode_CTS = 0;
const Msg_Cipher_Mode_CBC = 1;
const Msg_Cipher_Mode_CFB = 2;
const Msg_Cipher_Mode_OFB = 3;
const Msg_Cipher_Mode_CFS = 4;
const Msg_Cipher_Mode_ECB = 5;
const Msg_Cipher_Mode_CFB8 = 6;
const Msg_Cipher_Mode_OFB8 = 7;
const Msg_Cipher_Mode_CFS8 = 8;
const Msg_MAX_Cipher_Mode = 8;

const Msg_MAX_VECTOR = 31;
const Msg_MAX_KEY = 55;
const Msg_MAX_CONTROL_BLOCK = 255; 
	
const MsgDefaultPassword = 'Msgpassword'; 

//------------------- GENERAL CONSTS -------------------------------------------
	
 // Invalid ID - returned by find methods in case if object was not found 
 const INVALID_SESSION_ID = Integer(-1);
 
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
const MSG_Error_SendMessage_BadResultArray                       = 60144;
const MSG_Error_SendMessage_BadResultArraySize                   = 60145;
const MSG_Error_SendMessageToUserFailed                          = 60146;
{$ENDIF}

implementation

initialization

IsDesignMode := False;

end.
