const

  NextErrorRCode = 40167;

resourcestring

// #1
  ErrorRTableListFileNotOpened = 'TableListFile is not opened';
  ErrorRTableListFileInvalidStructure = 'Invalid structure of TableListFile. File size = %d, record size = %d';
  ErrorRTableNotFound = 'Table ''%s'' is not found';
  ErrorRTableMostUpdatedFileAlreadyOpened = 'MostUpdatedFile of the table starting with page #%d is already opened';
  ErrorRTableMostUpdatedFileIsNotOpened = 'MostUpdatedFile of the table is not opened';
  ErrorRTableMetadataFileAlreadyOpened = 'MetadataFile of the table starting with page #%d is already opened';
  ErrorRTableMetadataFileIsNotOpened = 'MetadataFile of the table is not opened';
  ErrorRLockObjectFailed = 'Cannot lock ''%s'' with %d retries and delay = %d ms';
  ErrorRUnlockObjectFailed = 'Cannot unlock ''%s'' with %d retries and delay = %d ms';
  ErrorRTableLocked = 'Table ''%s'' is locked';
// #11
  ErrorRCannotLockTable =  'Cannot lock %s table ''%s''';
  ErrorRCannotUnlockTable =  'Cannot unlock %s table ''%s''';
  ErrorRCannotUnlockLockedXTable =  'Locks sequence error: Try to unlock %s on table ''%s'' while it is locked X in other session';
  ErrorRCannotLockLockedXTable =  'Try to lock %s on table ''%s'' while it is locked X';
  ErrorRCannotStartNewSession =  'Locks sequence error: Try to open new session (SessionID=%d) while there are %d S locks in old session (SessionID=%d)';
  ErrorRCannotUlockSNotLocked =  'Locks sequence error: Try to unlock S while table is not S locked';
  ErrorRCannotGetTempFileName =  'Cannot get temporary file name';
  ErrorRStatFileError = 'Cannot get %s of file:''%s''. Error code: %d. System error message: %s';
  ErrorRCannotSetNewSize = 'Cannot set new size of file handle #%d. Old size %d bytes, new size %d bytes. System error code: %d. System error message: %s';
// SQLMemConnection
  ErrorRPacketSizeTooSmall = 'PacketSize is too small. PacketSize is %d bytes, but nedeed at least %d bytes.';
//#21
  ErrorRSessionNotConnected = 'Session @%d is not connected.';
  ErrorRUnknownControlCode = 'Unknown control code: %d.';

{******************************************************************************}
// SQLMemConnection: Timeouts
{******************************************************************************}
  ErrorRCannotConnect = 'Cannot connect to %s ID=%d for %d retries with %d msec delay.';
  ErrorRCannotDisconnect = 'Cannot disconnect %s %d for %d retries with %d msec delay.';
  ErrorRTimeoutStartReceive = 'Cannot receive any answer packet for session %d for %d msec.'; // 40103
  ErrorRTimeoutFullReceive = 'Cannot receive all the packets for session %d for %d msec.';
  ErrorRCannotAccess = 'Cannot access %s %s:%d for %d retries with %d msec delay.';
{******************************************************************************}

  ErrorRDisconnected = 'Session %d was disconnected by the server.';

{******************************************************************************}
// Socket Errors
{******************************************************************************}
  ErrorRNetworkListenerStarted = 'Network listener is already started. Socket error %d';
  ErrorRNetworkListenerNotStarted = 'Network listener is not started. Socket error %d';
  ErrorRNetSend = 'Unable to send packet to network. Socket error %d';
//#31
  ErrorRNetReceive = 'Unable to receive packet from network. Function "%s" returned socket error %d';
  ErrorRCannotOpenSocket = 'Cannot open socket. Function "%s" returned socket error %d';
  ErrorRCannotCloseSocket = 'Cannot close socket. Socket error %d';
{******************************************************************************}

  ErrorRWSAStartup = 'WSAStartup socket error %d';
  ErrorRWSACleanup = 'WSACleanup socket error %d';
  ErrorRThreadHangs = 'Cannot free object "%s" due to some threads have not been finished yet: %s.';
  ErrorRSessionNotFound = '%s session ID=%d not found';
  ErrorRWaitForTimeOut = 'Waiting for %s finishing - time out %d msec';

{******************************************************************************}
// Client network failed due to socket error
{******************************************************************************}
  ErrorRCannotConnetToServer = 'Cannot connect to remote database server. Test network, then check connection parameters on both client and server sides, and start server. RemoteHost = %s, RemotePort = %d, LocalPort = %d, ServerID = %d.';
  ErrorRCannotSendToServer = 'Cannot send request to server. Could be network error occurs or server went off-line. Check network connection and be sure that server is configured and works properly. RemoteHost = %s, RemotePort = %d, LocalPort = %d, ServerID = %d.';
//#41
  ErrorRCannotReceiveFromServer = 'Cannot receive answer from server. Could be network error occurs or server went off-line. Check network connection and be sure that server is configured and works properly. RemoteHost = %s, RemotePort = %d, LocalPort = %d, ServerID = %d.';
{******************************************************************************}
  ErrorRSessionTerminated = 'Cannot send a message to client. Session %d has been terminated. Could be user went off-line.';
//#71
  ErrorRSessionDeleted = 'Session has been delited. Could be user went off-line.';
  ErrorRSendSessionTerminated = 'Session has been terminated. Could be user went off-line.';
  ErrorRTimeoutMessageSent = 'Cannot send message to user ID=%d for %d msec. Could be another message are still sending.';
  ErrorRSendMessageThruServer = 'Cannot send message to user ID=%d through server. Could be server went off-line.';
  ErrorRSendMessageDirectly = 'Cannot send message to user ID=%d directly. Could be user went off-line.';
  ErrorRSendMessageToServer = 'Cannot send message to server ID=%d. Could be server went off-line or this client is not connected to it.';
  ErrorRTimeOutSending = 'Cannot send %s to server ID=%d for %d msec. Could be server is overloaded.';
  ErrorRServerTimeOutSending = 'Cannot send %s to client ID=%d for %d msec due it does not answer.';
  ErrorRCommandSessionTerminated = 'Cannot send an answer to client %s. Session %d has been terminated at point #%d. Could be user went off-line.';
  ErrorRClientSessionTerminated = 'Cannot send a command. Session %d has been terminated. Could be server went off-line.';
//#81
  ErrorRClientMsgSessionTerminated = 'Cannot send a message. Session %d has been terminated. Could be user went off-line.';
////////////////////////////////////////////////////////////////////////////////
// from MsgCommunicator v.4.10
////////////////////////////////////////////////////////////////////////////////
  ErrorRClientLogOnCannotSaveUserIDToStream = 'Client LogOn: Cannot Save UserID To Stream.';
  ErrorRClientLogOnCannotSavePasswordStream = 'Client LogOn: Cannot Save Password To Stream.';
  ErrorRClientLogoffCannotSaveUserIDToStream = 'Client Logoff: Cannot Save UserID To Stream.';
  ErrorRClientLogoffCannotSavePasswordStream = 'Client Logoff: Cannot Save Password To Stream.';
  ErrorRServerLogOnCannotLoadUserIDToStream = 'Server LogOn: Cannot Load UserID To Stream.';
  ErrorRServerLogOnCannotLoadPasswordStream = 'Server LogOn: Cannot Load Password To Stream.';
  ErrorRServerLogoffCannotLoadUserIDToStream = 'Server Logoff: Cannot Load UserID To Stream.';
  ErrorRServerLogoffCannotLoadPasswordStream = 'Server Logoff: Cannot Load Password To Stream.';
  ErrorRServerLogonCannotSaveAnswer = 'Server Logon: Cannot Save Answer.';
//#91
  ErrorRServerLogoffCannotSaveAnswer = 'Server Logoff: Cannot Save Answer.';
  ErrorRClientRegisterNewUserLoadUserID = 'Client RegisterNewUser: Cannot load UserID.';
  ErrorRServerRegisterNewUserSaveUserID = 'Server RegisterNewUser: Cannot save UserID.';
  ErrorRServerOnLineCannotChangeUserStatus = 'Server OnLineUser: Cannot change user status in the database, UserID = ';
  ErrorRServerOnLine = ' to UserID = ';
  ErrorRServerOnLineCannotSendOnLineEvent = 'Server OnLineUser: Cannot send on-line event of UserID = ';
  ErrorRServerOffLineCannotChangeUserStatus = 'Server OffLineUser: Cannot change user status in the database, UserID = ';
  ErrorRServerOffLineCannotSendOffLineEvent = 'Server OffLineUser: Cannot send off-line event of UserID = ';
  ErrorRTimeOutSendDirectly = 'Cannot send %s to UserID = %d for %d msec. Could be user went off-line.';
  ErrorRCannotConnectUser = 'Cannot conect UserID = %d. Error code = %d.';
//#126
  ErrorRServerUnknownCannotChangeUserStatus = 'Cannot send logon/logof event of UserID = ';
  ErrorRServerUnknownCannotChangeUserStatus2 = ': Unknown event type = ';
//#154
  ErrorRUnknownComponentType = 'Fatal error in Send Large Object Thread: Unknown Component Type.';
  ErrorRClientSessionDelete = 'Cannot delete client session object %s due it is in queue for using %d times.';
  ErrorRSessionIsNil = 'Client cannot send buffer due session is absent;';
//#157 - Error codes added for TCP network
  ErrorRUnknownProtocol = 'Unknown network protocol = %d';
  ErrorRNetworkConnect = 'Client cannot set TCP connection to server %s:%d, Error # %d.';
  ErrorRNetworkListen = 'Server cannot listen TCP port at address %s:%d, Error # %d.';
  ErrorRNetworkAccept = 'Cannot accept new TCP connection at address %s:%d. Function "%s" returned socket error %d.';
  ErrorRNetworkConnectNotBlocked = 'Due uncknown behavior of the connect function with nonblocking socket, client cannot set TCP connection to server %s:%d, socket error # %d.';
// ErrorRNetworkConnect
  ErrorRNetworkConnectTimeOut = 'Client cannot set TCP connection to server %s:%d for %d msec.';
// ErrorRNetworkConnect
// ErrorRNetReceive
  ErrorRNetSendBufSmall = '%d bytes send only of the buffer size of %d bytes to %s:%d.';
////////////////////////////////////////////////////////////////////////////////

{******************************************************************************}
// Both MsgCommunicator and Accuracer, codes startind with 40500
{******************************************************************************}
  ErrorRClient = 'Client';
  ErrorRServer = 'Server';

  ErrorRSendThread = ' Send thread (progress support) # ';
  ErrorRListenerThread = ' Command listener thread # ';
  ErrorRListenerMsgThread = ' Message listener thread # ';
  ErrorRResendRequestThread = ' Resend request thread # ';
  ErrorRMsgResendRequestThread = ' Message resend request thread # ';
  ErrorRServerSessionThread = ' Command session thread # ';
  ErrorRServerSessionMsgThread = ' Message session thread # ';
  ErrorRServerSessionDisconnectThread = ' Disconnect session thread # ';
  ErrorRServerSessionTerminatorThread = ' Session terminator thread # ';
  ErrorRServerPingClientsThread = ' Ping clients thread # ';
  ErrorRServerEventsThread = ' Events thread # ';
  ErrorRDisconnectThread = ' Disconnect thread # ';
  ErrorRMainThread = ' Main thread';
  ErrorRPacketProcessorThread = ' Packet Processor thread # ';
  ErrorRCommandProcessorThread = ' Command Processor thread # ';
  ErrorRMessageProcessorThread = ' Message Processor thread # ';
  ErrorRCommandThread = ' Command thread # ';
  ErrorRMessageThread = ' Message thread # ';
  ErrorRSendingThread = ' Sending thread # ';
  ErrorRCommandResendRequestThread = ' Command Resend Request thread # ';
  ErrorRMessageResendRequestThread = ' Message Resend Request thread # ';

  ErrorRCreate = ' - Error in Create method: ';
  ErrorRDestroy = ' - Error in Destroy method: ';
  ErrorRExecute = ' - Error in Execute method: ';

const
  ErrorRBuf = 'buffer.';
  ErrorRMsg = 'message.';
  ErrorREcho = 'echo buffer.';

  ErrorRDND = ' cannot decompress and decrypt received ';
  ErrorRCannotDND = ErrorRDND + ErrorRBuf;                            // # 40500
  ErrorRCannotDNDMsg = ErrorRDND + ErrorRMsg;                         // # 40501
  ErrorRCannotDNDEcho = ErrorRDND + ErrorREcho;                       // # 40502

  ErrorRSend = ' cannot send ';
  ErrorRCannotSend = ErrorRSend + ErrorRBuf;                          // # 40503
  ErrorRCannotSendMsg = ErrorRSend + ErrorRMsg;                       // # 40504
  ErrorRCannotSendEcho = ErrorRSend + ErrorREcho;                     // # 40505

  ErrorRRecv = ' cannot receive ';
  ErrorRCannotReceive = ErrorRRecv + ErrorRBuf;                       // # 40506
  ErrorRCannotReceiveMsg = ErrorRRecv + ErrorRMsg;                    // # 40507
  ErrorRCannotReceiveEcho = ErrorRRecv + ErrorREcho;                  // # 40508

{******************************************************************************}

resourcestring

{******************************************************************************}

  ErrorRDoDisconnect = 'Error in disconnect process.';                // # 40509
  ErrorRGetConnectParams = 'SQLMemConnect section - Error getting parameters. '; // # 40510
  ErrorRSendConnectAckn = 'Cannot send connect acknowledgement.';     // # 40511

  ErrorRSessionReceiveMessage = 'Error in Session.ReceiveMessage.';   // # 40512
  ErrorRSessionReceiveData = 'Error in Session.ReceiveData.';         // # 40513

  ErrorRServerSessionNotFinished = ' - Server session is not finished yet.'; // # 40514

  ErrorRThreadsLeft = 'Some threads left. Threads count=';            // # 40515

  ErrorRCannotCreateListenerThread = 'Cannot create listener thread -- too many threads. Maximum threads count must be > 8. MaxThreadCount='; // # 40516

  ErrorRCannotTerminateThread = 'Thread ignored termanate signal. Timeout, msec = ';   // # 40517
  ErrorRCannotKillThread = 'Cannot kill thread. Last error code = ';                   // # 40518

  ErrorRAckn = 'Cannot send acknowledgement.';                        // # 40519

  ErrorRDisconnect = 'Cannot disconnect session.';                    // # 40520

{******************************************************************************}

const
// Client / Server error codes in Leo's modules
  SQLMem_CS_CommandSendError = 40900;

resourcestring
// imported from Leo's modules
  ErrorLInvalidIndex = 'Invalid index %d, count = %d';
  ErrorLInvalidCapacity = 'Invalid capacity = $d';


