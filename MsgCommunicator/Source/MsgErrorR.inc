const

  NextErrorRCode = 40157;

const

{******************************************************************************}
// MsgConnection
{******************************************************************************}
  ErrorRPacketSizeTooSmall = 'PacketSize is too small. PacketSize is %d bytes, but nedeed at least %d bytes.';
//#21
  ErrorRSessionNotConnected = 'Session @%d is not connected.';
  ErrorRUnknownControlCode = 'Unknown control code: %d.';

{******************************************************************************}
// MsgConnection: Timeouts
{******************************************************************************}
  ErrorRCannotConnect = 'Cannot connect to %s ID=%d for %d retries with %d msec delay.';
  ErrorRCannotDisconnect = 'Cannot disconnect %s ID=%d for %d retries with %d msec delay.';
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
  ErrorRThreadHangs = 'Cannot free object "%s" due some threads have not been finished yet: %s.';
  ErrorRSessionNotFound = '%s session ID=%d not found';
  ErrorRWaitForTimeOut = 'Waiting for %s finishing - time out %d msec';

{******************************************************************************}
// Client network failed due to socket error
{******************************************************************************}
  ErrorRCannotConnetToServer = 'Cannot connect to remote server. Test network, then check connection parameters on both client and server sides, and start server. RemoteHost = %s, RemotePort = %d, LocalPort = %d, ServerID = %d.';
  ErrorRCannotSendToServer = 'Cannot send request to server. Could be network error occurs or server went off-line. Check network connection and be sure that server is configured and works properly. RemoteHost = %s, RemotePort = %d, LocalPort = %d, ServerID = %d. Error occurs: "%s"';
//#41
  ErrorRCannotReceiveFromServer = 'Cannot receive answer from server. Could be network error occurs or server went off-line. Check network connection and be sure that server is configured and works properly. RemoteHost = %s, RemotePort = %d, LocalPort = %d, ServerID = %d.';
{******************************************************************************}


{******************************************************************************}
// MsgCommunicator errors
{******************************************************************************}
  ErrorRNotConnected = 'Client is not connected to the server';
  ErrorRConnected = 'Client is connected to the server';
  ErrorRLoadUserInfo = 'Load UserInfo error';
  ErrorRSaveUserInfo = 'Save UserInfo error';
  ErrorRAnswerNotCorrect = '%s answer is not correct';
  ErrorRLoadContactInfo = 'Load ContactInfo error';
  ErrorRSaveContactInfo = 'Save ContactInfo error';
  ErrorRUnknownCommand = 'Server has received unknown command from User # %d';
  ErrorRSaveUserID = 'Save UserID error';
//#51
  ErrorRLoadUserID = 'Load UserID error';
  ErrorRLoadUserContacts = 'Load user''s contacts error';
  ErrorRSaveUserContacts = 'Save user''s contacts error';
  ErrorRLoadUsers = 'Load all users information error';
  ErrorRSaveUsers = 'Save all users information error';
  ErrorRUnknownMessageType = 'Unknown message type';
  ErrorRSaveServerID = 'Save ServerID error';
  ErrorRSaveCommand = 'Save command code error';
  ErrorRSaveSize = 'Save Size error';
  ErrorRSaveBuffer = 'Save command data error';
//#61
  ErrorRLoadCommand = 'Load command code error';
  ErrorRLoadBuffer = 'Load command data error';
  ErrorRObjectNotCreated = 'Object %s has not been created.';
  ErrorRSaveFileName = 'Save file name error';
  ErrorRSaveMessage = 'Save message error';
  ErrorRLoadFileName = 'Load file name error';
  ErrorRLoadMessage = 'Load message error';
  ErrorRNoServerConnection = 'Cannot connect to user ID=%d directly. RemoteHost = %s, RemotePort = %d. There is no connection to the server. Please specify host and port or try to connect to the server.';
  ErrorRUserIsNotOnLine = 'Cannot connect to user ID=%d directly. This user is not on-line now.';
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
  ErrorRClientSessionTerminated = 'Cannot send a comand. Session %d has been terminated. Could be server went off-line.';
//#81
  ErrorRClientMsgSessionTerminated = 'Cannot send a message. Session %d has been terminated. Could be user went off-line.';
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
//#157 - Error codes added to TCP network
  ErrorRUnknownProtocol = 'Unknown network protocol = %d';
  ErrorRNetworkConnect = 'Client cannot set TCP connection to server %s:%d, Error # %d.';
  ErrorRNetworkListen = 'Server cannot listen TCP port at address %s:%d, Error # %d.';

{******************************************************************************}


// Both MsgCommunicator and Accuracer, startind with 40500
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

  ErrorRDoDisconnect = 'Error in disconnect process.';                // # 40509
  ErrorRGetConnectParams = 'ACRConnect section - Error getting parameters. '; // # 40510
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

  ErrorREventsThread = 'LogEventsThread terminated abnormally.';            // # 40521

{******************************************************************************}
