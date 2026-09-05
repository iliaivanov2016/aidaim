unit MsgConnection;

{$DEFINE ClientCommand_Fix} // Fix for client command w/o answer, ACR v.5.90

{DEFINE PACKET_RESEND_REQUEST}

interface

{$I MsgVer.inc}
{$HINTS OFF}

{$IFDEF DEBUG_LOG_NETWORK_THREADS}
{$DEFINE LOG_CLIENT_THREADS}
{DEFINE LOG_SERVER_THREADS}
{$ENDIF}

{DEFINE LOGIC_TEST}
{DEFINE CONNECTION_TEST}
{$IFNDEF CONNECTION_TEST}
 {DEFINE NETWORK_TEST}
{$ENDIF CONNECTION_TEST}

{$IFNDEF API_NETWORK}
 {$IFDEF D6H}
  {$DEFINE ProcessMessages} // Needs for Indy only
 {$ENDIF D6H}
{$ENDIF API_NETWORK}

uses
  Classes, Math, SysUtils,
{$IFDEF MSWINDOWS}
  Windows,
  Forms,
{$ENDIF}
{$IFDEF LINUX}
  Libc,
  QForms,
{$ENDIF}

{$IFNDEF API_NETWORK}
 {$IFDEF D6H}
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, IdUDPServer, IdSocketHandle,
 {$ELSE}
  NMUDP,
 {$ENDIF}
{$ELSE}
// MsgCommunicator units
  MsgNetwork,
  MsgCrypto,
{$ENDIF}

{$IFDEF DEBUG_LOG}
  MsgDebug,
{$ENDIF}
  MsgCompression,
  MsgComBase,
  MsgTypes,
  MsgConst,
  MsgExcept,
  MsgLinux,
  MsgCriticalSection,
  MsgBaseEngine,
  MsgMemory;

const

  kernel32  = 'kernel32.dll';
{$IFDEF MSWINDOWS}
{$NODEFINE TerminateThread}
function TerminateThread(hThread: THandle; dwExitCode: Longword): Boolean; stdcall;
{$ENDIF}

const
{******************************************************************************}
// ControlCode (-128..127):
{******************************************************************************}

// From Client
{$IFNDEF MsgCommunicator}
                     // Accuracer commands
 ACRNewRequest    = 10;        // from Client (Server replies ACRNoAction)
 ACRClientCommand = 31;        // from Client (Server does not reply)
 ACRServerCommand = 32;        // from Server (Client does not reply, in a message)
{$ELSE}
                     // 10...30 -- reserwed for MsgCommunicator commands
                     // 33...63 -- reserwed for custom commands
                     // MsgCommunicator commands
 MsgNewRequest    = 10;        // default
 MsgGetUserInfo = 10;
 MsgRegisterNewUser = 11;
 MsgAddUserToContacts = 12;
 MsgRemoveUserFromContacts = 13;
 MsgGetContacts = 14;
 MsgUpdateUserInfo = 15;
 MsgGetUserID = 16;
 MsgFindUsers = 17;
 MsgFindMessages = 18;
 MsgIsUserExisting = 19;
 MsgIsUserOnline = 20;
 MsgUpdateUserInContacts = 21;
 MsgInitProgressSend = 22;
 MsgFindUserID = 23;
{$ENDIF}

 MsgZippedBuffer = 32;
 MsgConnect = 1;
// From Server
 MsgConnected = 2;
// Both
 MsgNoAction = 0;
 MsgMessage = 3;
// MsgLastPacket: 7th bit = 1, i.e. byte = x1xxxxxx, i.e. code >= 64
 MsgLastPacket = 64;
 MsgEcho = 4;
 MsgTunning = 5;
 MsgServerSessionTunning = 6;
 MsgPing = 7;
 MsgLogon = 8;
 MsgLogoff = 9;
// single packet:
 MsgAllPacketsReceived = -1;
 MsgPacketResendRequest = -2;
 MsgMessageReceived = -3;
 MsgMessagePacketResendRequest = -4;
 MsgMessageAbort = -5;
 MsgDisconnect = -55;

{******************************************************************************}


{******************************************************************************}
// Sending Status - Fof Commands and Messages
{******************************************************************************}
  MsgNotSent = 0;
  MsgSent = -1;
{******************************************************************************}

{******************************************************************************}
// Receiving Status
{******************************************************************************}
 MsgNo = 0;       // no received packets
 MsgStart = 1;    // at least one packet received
 MsgNotFull = 2;  // last packte received, but not all the packets -- needs to request for resending
 MsgFull = -1;    // all the packets received
{******************************************************************************}

{******************************************************************************}
// Session Control Codes
{******************************************************************************}
 MsgExecute = 0;
 MsgSuspend = 1;
 MsgTerminate = -1;
{******************************************************************************}


{******************************************************************************}
// Session Status
{******************************************************************************}
 MsgVacant = 0;
 MsgInUse = 1; // all positive values mean 'in use'
{******************************************************************************}

{******************************************************************************}
// Message Status
{******************************************************************************}
 MsgNotFound  = 0;
 MsgSending   = 1;
 MsgSendOK    = 2; // sent
 MsgReceiving = 3;
 MsgReceived  = 4; // all the packets are received
{******************************************************************************}

 MsgNoResending = 999;

{******************************************************************************}


////////////////////////////////////////////////////////////////////////////////
// Error Codes
////////////////////////////////////////////////////////////////////////////////

{******************************************************************************}
// location
{******************************************************************************}
  // client
  MsgClientPacketProcessorThread =        70;
  MsgClientResendRequestThread =          71;
  MsgClientMsgResendRequestThread =       72;
  MsgClientSendThread =                   73;
  MsgClientPacketProcessorThreadCommand = 74;
  MsgClientCommandProcessorThread =       75;
  MsgClientMesssageProcessorThread =      76;

  MsgClientConnectionManager =       79;

  // server
  MsgServerListenerThread =          80;
  MsgServerResendRequestThread =     81;
  MsgServerMsgResendRequestThread =  82;
  MsgServerSessionThread =           83;
  MsgServerSessionMsgThread =        84;
  MsgServerSessionDisconnectThread = 85;
  MsgServerSessionTerminatorThread = 86;
  MsgServerPingClientsThread =       87;
  MsgServerSessionMsgThreadHang =    88;
  MsgServerEventsThread =            89;

  MsgServerTerminateCommandThreads = 90;
  MsgServerTerminateMessageThreads = 91;

  MsgServerDeleteSession           = 92;

  MsgServerConnectionManager =       99;

  MsgServerError =                  100;

{******************************************************************************}
// functions
{******************************************************************************}
  // client
  MsgClntEchoRecv = 1;
  MsgClntEchoSend = 2;
  MsgClntEchoDND  = 3;
  MsgClntRecvDND  = 4;
  MsgClntMsgDND   = 5;

  // server
  MsgSrvrRecv     = 31;
  MsgSrvrRecvDND  = 32;
  MsgSrvrEchoSend = 33;
  MsgSrvrEchoDND  = 34;
  MsgSrvrMsgRecv  = 35;
  MsgSrvrMsgDND   = 36;



////////////////////////////////////////////////////////////////////////////////
// To avoid multiple realloc
////////////////////////////////////////////////////////////////////////////////

 MsgDefaultPacketsInAnswer = 8;
 MsgDefaultPacketsInRequest = 2;
 MsgDefaultMsgPackets = 1;

// Signatures
{$IFDEF MsgCommunicator}
 MsgClientPacketSign = 'MCM1';
 MsgServerPacketSign = 'MCM2';
{$ELSE}
 ACRClientPacketSign = 'ADS1';
 ACRServerPacketSign = 'ADS2';
{$ENDIF}

{$IFDEF PACKET_RESEND_REQUEST}
const
  Msg_Max_PacketID = 65535;
type
  TMsgPacketID = Word;
{$ENDIF}

type

  PThread = ^TThread;

  TMsgSessionsArray = array of TMsgComBaseSession;

  TMsgNetwork = class;
  TMsgBaseConnectionManager = class;
  TMsgQueueProcessorThread = class;
  TMsgResendRequestThread = class;
{$IFDEF CLIENT_VERSION}
  TMsgClientConnectionManager = class;
  TMsgClientResendRequestThread = class;
//  TMsgClientMsgResendRequestThread = class;
  TMsgClientPacketProcessorThread = class;
{$ENDIF}
{$IFDEF SERVER_VERSION}
  TMsgServerConnectionManager = class;
  TMsgServerSessionThread = class;
  TMsgServerSessionMsgThread = class;
  TMsgServerSessionDisconnectThread = class;
  TMsgServerResendRequestThread = class;
  TMsgServerMsgResendRequestThread = class;
  TMsgServerListenerThread = class;
{$ENDIF}

  TMsgControlCode = ShortInt;
  TMsgNetworkClientID = Integer;
  TMsgConnectionID = Integer;

  TMsgPacketHeader = packed record
    CheckSum:           Cardinal;
    Signature:          array [0..3] of AnsiChar;
    Recepient:          TMsgNetworkClientID;
    Sender:             TMsgNetworkClientID;
    ConnectionID:       TMsgConnectionID;
    SessionID:          TMsgSessionID;
    CurrentRequestID:   Integer;
    PacketID:           Integer;
    ControlCode:        TMsgControlCode;
  end;
  PMsgPacketHeader = ^TMsgPacketHeader;

  TMsgPacket = packed record
    Buffer:             PAnsiChar;
    BufferSize:         Integer;
  end;
  PMsgPacket = ^TMsgPacket;

  TMsgNetworkPacket = packed record
    Network:            TMsgNetwork;
    FromHost:           AnsiString;
    FromPort:           Integer;
    Packet:             PMsgPacket;
  end;
  PMsgNetworkPacket = ^TMsgNetworkPacket;

  TMsgConnectionParams = packed record
    PacketSize:                   Integer;
    CompressionAlgorithm:         Byte;
    CompressionMode:              Byte;
    UseServerSettings:            Boolean;
  end;
  PMsgConnectionParams = ^TMsgConnectionParams;

  TMsgRecvItem = record
    Session:                Pointer; // PMsgClntSession
    RecvStatus:             Integer; // MsgNo, MsgStart, MsgNotFull, MsgFull
    Network:                TMsgNetwork;
    RemotePort:             Integer;
    RemoteHost:             AnsiString;
    Packets:                TMsgThreadList; // list of TMsgPacket
  end;
  PMsgRecvItem = ^TMsgRecvItem;

  TMsgCommand = TMsgRecvItem;
  PMsgCommand = ^TMsgRecvItem;

  TMsgMessage = TMsgRecvItem;
  PMsgMessage = ^TMsgRecvItem;

  TMsgMessageStatus = record
    Status:                 Integer; //  MsgNotFound,
                                     //  MsgSending, MsgSendOK,
                                     //  MsgReceiving, MsgReceived
    MessageID:              Integer;
    NetworkClientID:        TMsgNetworkClientID; // sender for receiving, recepient for sending
    ConnectionID:           TMsgConnectionID;
    SessionID:              TMsgSessionID;
    PacketIDsToResend:      TMsgIntegerArray;
  end;
  PMsgMessageStatus = ^TMsgMessageStatus;

{$IFDEF CLIENT_VERSION}
  TMsgClntSession = record
    Session:                TMsgComBaseSession;
    ServerSessionID:        TMsgSessionID;
    CurrentRequestID:       Integer;
    ConnectionID:           TMsgConnectionID;
    RemoteConnectionID:     TMsgConnectionID;
    AnswerTime:             Cardinal;
    AnswerStatus:           Integer;
    MsgSendStatus:          Integer;
    SendStatus:             Integer;
    ClientMessageID:        Integer;
//    ServerMessageID:        Integer;
    ResendRequestThread:    TMsgThread;
    PacketIDsToResend:      TMsgThreadIntArray;
    MsgPacketIDsToResend:   TMsgThreadIntArray;
    Packets:                TMsgList;
    FCSect:                 TRTLCriticalSection;
    Status:                 Integer;  // inc before FCSect enters to prevent session deleting while it will be used
    ControlCode:            Shortint;  // MsgExecute, MsgTerminate
  end;
  PMsgClntSession = ^TMsgClntSession;

  TMsgClntConnection = packed record
    ConnectionID:       TMsgConnectionID;
    Network:            TMsgNetwork;
  end;
  PMsgClntConnection = ^TMsgClntConnection;
{$ENDIF}

{$IFDEF SERVER_VERSION}
  TMsgSrvrSession = packed record
    Session:                      TMsgComBaseSession;
    CurrentRequestID:             Integer;
    Packets:                      TMsgThreadList; // can be TMsgList
    ReceiveStatus:                Shortint;               // for ReceiveBuffer
    SendStatus:                   Shortint;               // for SendBuffer
    MsgReceiveStatus:             Shortint;
    MsgSendStatus:                Shortint;
    PacketIDsToResend:            TMsgThreadIntArray;
    ClientMessageID:              Integer;
    ServerMessageID:              Integer;
    MsgQueue:                     TMsgThreadList;            // List of MsgPackets
    MsgPackets:                   TMsgThreadList; // incoming packets, can be TMsgList
    MsgReceivedPackets:           TMsgThreadList; // packets to receive buffer, can be TMsgList
    MsgPacketIDsToResend:         TMsgThreadIntArray;
    ClientSessionID:              TMsgSessionID;
    ConnectionID:                 TMsgConnectionID;
    RemoteClientID:               TMsgNetworkClientID;
    RemoteHost:                   AnsiString;
    RemotePort:                   Integer;
    Application:                  AnsiString;
    Thread:                       TMsgServerSessionThread;
    MsgThread:                    TMsgServerSessionMsgThread;
    MsgThreadCount:               Integer;
    DisconnectThread:             TMsgServerSessionDisconnectThread;
    AnswerTime:                   Cardinal;
    LastSendPingTime:             Cardinal;
    LastReceivePingTime:          Cardinal;
    ContactCount:                 Integer; // number of contacts of this user
    Connected:                    Boolean; // used in Ping thread to avoid sending to non-specified remote address
    ControlCode:                  Shortint;
    MsgControlCode:               Shortint;
    Status:                       Shortint;
  end;

  PMsgSrvrSession = ^TMsgSrvrSession;
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TMsgNetwork
//
////////////////////////////////////////////////////////////////////////////////

  TMsgNetwork = class (TObject)
   private
    FCSect:               PRTLCriticalSection;
    FManager:             TMsgBaseConnectionManager;
    FLocalClient:         TMsgNetworkClientID;
{$IFNDEF API_NETWORK}
    FLocalHost:           AnsiString;
    FRemoteHost:          AnsiString;
    FRemotePort:          Integer;
{$ENDIF API_NETWORK}
    function RndClientID: TMsgNetworkClientID;
    procedure SetRemoteHost(Host: AnsiString);
    function GetRemoteHost: AnsiString;
    procedure SetRemotePort(Port: Integer);
    function GetRemotePort: Integer;
    procedure SetLocalHost(Host: AnsiString);
    function GetLocalHost: AnsiString;
    procedure SetLocalPort(Port: Integer);
    function GetLocalPort: Integer;
    procedure SetPacketSize(Size: Integer);
    function GetPacketSize: Integer;
   public
{$IFDEF API_NETWORK}
    FMsgNetwork:          TMsgapiNetwork;
{$ELSE}
 {$IFDEF D6H}
//    FNetworkClient:       TIdUDPClient;
    FNetworkServer:       TIdUDPServer;
 {$ELSE}
    FTransport:           TNMUDP;
 {$ENDIF}
{$ENDIF}
   protected
    procedure CreateNetwork;
    procedure FreeNetwork;
    procedure ReCreateNetwork;
   public
    constructor Create(ConnectionManager: TMsgBaseConnectionManager);
    destructor Destroy; override;
    procedure SendBuffer(
                          Buffer: PAnsiChar;
                          Count:  Integer
                         );
    procedure OnDisconnect(
                             FromHost:  AnsiString;
                             FromPort:  Integer;
                             Recv:      Boolean = False
                             );
{$IFDEF API_NETWORK}
    procedure OnDataReceived(
                             Buffer:    PAnsiChar;
                             Count:     Integer;
                             FromHost:  AnsiString;
                             FromPort:  Integer
                             );
{$ELSE}
 {$IFDEF D6H}
    procedure OnDataReceived(
                             Sender:   TObject;
                             AData:    TStream;
                             ABinding: TIdSocketHandle
                             );
 {$ELSE}
    procedure OnDataReceived(
                             Sender: TComponent;
                             BufferSize: Integer;
                             FromIP: AnsiString;
                             Port: integer
                             );
 {$ENDIF}
{$ENDIF}
   public
    property RemoteHost: AnsiString read GetRemoteHost write SetRemoteHost;
    property RemotePort: Integer read GetRemotePort write SetRemotePort;
    property LocalHost: AnsiString read GetLocalHost write SetLocalHost;
    property LocalPort: Integer read GetLocalPort write SetLocalPort;
    property LocalClientID: Integer read FLocalClient write FLocalClient;
    property PacketSize: Integer read GetPacketSize write SetPacketSize;
  end; // TMsgNetwork



////////////////////////////////////////////////////////////////////////////////
//
// TMsgBaseConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

  TMsgBaseConnectionManager = class (TObject)
   private
    FServer:                TComponent;     // for thread close diagnostic on the server
{$IFDEF CONNECTION_TEST}
    FOtherManager:    TObject;
{$ELSE}
 {$IFDEF NETWORK_TEST}
    FOtherManager:    TObject;
    FClient:          Boolean;
 {$ENDIF}
{$ENDIF}
    FCSect:                 TRTLCriticalSection;
    FSessionID:             TMsgSessionID;
    FListenerStoped:        Boolean;
    FMaxThreadCount:              Integer;
    FReceiveTimeOut:              Integer;
    FPacketQueue:                 TMsgThreadList;
    FMessageQueue:                TMsgThreadList; // list of PMsgRecvItem
    FSendMessages:                TMsgThreadList; // list of PMsgSendMessageStatus
    FRecvMessages:                TMsgThreadList; // list of PMsgRecvMessageStatus
    FPacketProcessorThread:       TMsgClientPacketProcessorThread;
    FCommandProcessorThread:      TMsgQueueProcessorThread;
    FMessageProcessorThread:      TMsgQueueProcessorThread;
    FCommandResendRequestThread:  TMsgResendRequestThread;
    FMessageResendRequestThread:  TMsgResendRequestThread;
    FCommandThreads:              TMsgThreadList;
    FMessageThreads:              TMsgThreadList;
    FSendingThreads:              TMsgThreadList;
   public
    FSessions:              TMsgThreadList;
    FThreadCount:           Integer;
   protected
    procedure FreePackets(Packets: TMsgThreadList);
    procedure PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TMsgNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False
                                 ); virtual; abstract;
    function MessageStatus(
                        Header:                 PMsgPacketHeader;
                        Messages:               TMsgThreadList
                            ): Integer;
    function FindMessageInQueue(Header: PMsgPacketHeader): PMsgRecvItem;
    function FindMessage(
                        Messages:               TMsgThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TMsgNetworkClientID;
                        ConnectionID:           TMsgConnectionID;
                        SessionID:              TMsgSessionID
                                               ): PMsgMessageStatus;
    function SetMessageStatus(
                        Messages:               TMsgThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TMsgNetworkClientID;
                        ConnectionID:           TMsgConnectionID;
                        SessionID:              TMsgSessionID;
                        NewStatus:              Integer
                                               ): Boolean;
    procedure IncThreadCount(Ignore: Boolean = False);
    procedure DecThreadCount(Ignore: Boolean = False);
    procedure SetThreadCount(Value: Integer);
    procedure NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); virtual; abstract;
    procedure OnDisconnect(
                               FNetwork:      TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); virtual; abstract;
    procedure CompressAndEncryptBuffer(
                        Session:              TMsgComBaseSession;
                        InBuffer:             PAnsiChar;
                        InBufferSize:         Integer;
                        var OutBuffer:        PAnsiChar;
                        var OutBufferSize:    Integer
                                        );
    function DecompressAndDecryptBuffer(
                        Session:              TMsgComBaseSession;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                        ): Boolean;
    procedure WaitForThread(
                          Thread:        PThread;
                          TimeOut:       Cardinal;
                          SleepTime:     Cardinal = 1
                            );
    procedure GetBufferFromPackets(
                        Packets:        TMsgThreadList;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                   );
   public
    constructor Create;
    destructor Destroy; override;
    function CloseThread(
                          Thread:        PThread;
                          ErrProcess:    Integer;
                          ErrObject:     AnsiString;
                          WaitTimeOut:   Cardinal = MsgServerThreadsTerminateDelay;
                          SleepTime:     Cardinal = 1
                                      ): Boolean;
    procedure CloseThreads(ThreadList:    TMsgThreadList;
                           WaitTimeOut:   Cardinal = MsgServerThreadsTerminateDelay
                           );
    property ThreadCount: Integer read FThreadCount write SetThreadCount;
  end; // TMsgBaseConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////
  TMsgResendRequestThread = class(TMsgThread)
  private
    FManager:           TMsgBaseConnectionManager;
    FQueue:             TMsgThreadList;
    FCommand:           Boolean;
    FClient:            Boolean;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TMsgBaseConnectionManager;
                       Queue:             TMsgThreadList;
                       Command:           Boolean = True
                       );
    destructor Destroy; override;
  end;// TMsgResendRequestThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

{$IFDEF CLIENT_VERSION}
  TMsgClientConnectionManager = class (TMsgBaseConnectionManager)
   private
    FConnections:                 TMsgThreadList;
    FConnectionID:                TMsgConnectionID;
    FApplication:                 AnsiString;
   protected
    function IsSessionExisting(ClientSession: PMsgClntSession): Boolean;
    procedure PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TMsgNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False
                                 );
    procedure SendConnectRequest(ClientSession: PMsgClntSession);
    procedure SendDisconnectRequest(ClientSession: PMsgClntSession;
                                    WaitForAnswer: Boolean = True);
    procedure SendPing(ClientSession: PMsgClntSession);
    procedure SendAcknowledgement(ClientSession: PMsgClntSession;
                                  Msg:           Boolean = False;
                                  CurrentRequestID:     Integer = -1
                                  );
{$IFDEF MsgCommunicator}
    function IsAuthorizationBufferValid(
                      CryptoInfo: TMsgCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
    procedure SendConnectAckn(
                          ClientSession:        PMsgClntSession;
                          ClientConnection:     PMsgClntConnection;
                          CurrentRequestID:     Integer = -1
                              );
{$ENDIF MsgCommunicator}
    procedure DoDisconnect(Session: TMsgComBaseSession);
    procedure DeleteSession(ClientSession: PMsgClntSession);
    procedure OnDisconnect(
                               FNetwork:      TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
//    function IsExistingPacket: Boolean;
    procedure NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
    procedure WaitForSendingThreads(Session: TMsgNetworkSession);
    procedure DoSendBuffer(
                          ClientSession:    PMsgClntSession;
                          ClientConnection: PMsgClntConnection;
                          Buffer:           PAnsiChar;
                          BufferSize:       Integer;
                          Code:             Integer = MsgNewRequest
                         );
    // if encryption algorithm <> msg_Cipher_None then allocate buffer, fill it and return size
    // otherwise return BufferSize = 0
    procedure CreateAuthorizationBuffer(
                          CryptoInfo:     TMsgCryptoInfo;
                          out Buffer:     PAnsiChar;
                          out BufferSize: Integer
                                        );
   public
    constructor Create;
    destructor Destroy; override;
    procedure TuneConnectionParamaters(ClientSession:  PMsgClntSession);
    procedure Connect(Session: TMsgComBaseSession;
                          ListenOnly: Boolean = False;
                          Tune: Boolean = True
                          );
    procedure Disconnect(Session: TMsgComBaseSession; ListenOnly: Boolean = False);
    procedure DisconnectAll;
    procedure SendBuffer(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = MsgNewRequest
                          );
    procedure ReceiveBuffer(
                          Session:        TMsgComBaseSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer;
                          Connecting:     Boolean = False
                          );
    procedure SendMessage(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TMsgControlCode = MsgMessage
                          );
(*
    procedure ReceiveMessage(
                          ClientSession:  PMsgClntSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
*)
  end; // TMsgClientConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientPacketProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgClientPacketProcessorThread = class(TMsgThread)
  private
    FManager:       TMsgClientConnectionManager;
    Error:          AnsiString;
    ClientSession:  PMsgClntSession;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:       TMsgClientConnectionManager
                       );
    destructor Destroy; override;
  end;// TMsgClientPacketProcessorThread


////////////////////////////////////////////////////////////////////////////////
//
// TMsgQueueProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgQueueProcessorThread = class(TMsgThread)
  private
    FManager:           TMsgBaseConnectionManager;
    FQueue:             TMsgThreadList;
    FCommand:           Boolean;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    ThreadsCount:       Integer;
    MaxThreads:         Integer;
    constructor Create(
                        Manager:        TMsgBaseConnectionManager;
                        Queue:          TMsgThreadList;
                        Command:        Boolean = True;
                        MaxThreadCount: Integer = MsgMaxThreadCount
                       );
    destructor Destroy; override;
  end;// TMsgQueueProcessorThread


////////////////////////////////////////////////////////////////////////////////
//
// TMsgMessageThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgMessageThread = class(TMsgThread)
  private
    FManager:           TMsgBaseConnectionManager;
    FMsg:               PMsgRecvItem;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                        Manager:        TMsgBaseConnectionManager;
                        Msg:            PMsgRecvItem
                       );
    destructor Destroy; override;
  end;// TMsgMessageThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgSendingThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgSendingThread = class(TMsgThread)
  private
    FSession:                       TMsgNetworkSession;
    FManager:                       TMsgBaseConnectionManager;
    FMethod:                        Pointer;
    Farg1,Farg2,Farg3,Farg4,Farg5:  Integer;
    Error:                          AnsiString;
  protected
{$IFDEF MsgCommunicator}
    procedure Connect(
                                NetworkPacket:        PMsgNetworkPacket
                      );
    procedure ExecuteReceivedCommand(
                                ClientSession:        PMsgClntSession;
                                Command:              Integer
                      );

{$ENDIF}
    procedure Echo;
    procedure Execute; override;
  public
    constructor Create(
                          Session:    TMsgNetworkSession;
                          Manager:    TMsgBaseConnectionManager;
                          Method:     Pointer;
                          arg1,arg2,arg3,arg4,arg5: Integer
                       );
    destructor Destroy; override;
  end;// TMsgSendingThread


(*
////////////////////////////////////////////////////////////////////////////////
//
// TMsgCommandProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgCommandProcessorThread = class(TMsgThread)
  private
    FManager:       TMsgClientConnectionManager;
    Error:          AnsiString;
  protected
    procedure Execute; override;
{$IFDEF MsgCommunicator}
    procedure CommandReceived;
{$ENDIF}
  public
    MaxThreads:        Integer;
    constructor Create(
                       Manager:       TMsgBaseConnectionManager
                       );
    destructor Destroy; override;
  end;// TMsgCommandProcessorThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgMessageProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgMessageProcessorThread = class(TMsgThread)
  private
    FManager:       TMsgClientConnectionManager;
    Error:          AnsiString;
  protected
    procedure Execute; override;
{$IFDEF MsgCommunicator}
    procedure MessageReceived;
{$ENDIF}
  public
    constructor Create(
                       Manager:       TMsgBaseConnectionManager
                       );
    destructor Destroy; override;
  end;// TMsgMessageProcessorThread
*)


////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgClientResendRequestThread = class(TMsgThread)
  private
    FManager:           TMsgClientConnectionManager;
    FClientSession:     PMsgClntSession;
    FBuffer:            PAnsiChar;
    FNetwork:           TMsgNetwork;
    FHost:              AnsiString;
    FPort:              Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TMsgClientConnectionManager;
                       ClientSession:     PMsgClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TMsgNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                       );
    destructor Destroy; override;
  end;// TMsgClientResendRequestThread


(*
////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgClientMsgResendRequestThread = class(TMsgThread)
  private
    FManager:           TMsgClientConnectionManager;
    FClientSession:     PMsgClntSession;
    FBuffer:            PAnsiChar;
    FNetwork:           TMsgNetwork;
    FHost:              AnsiString;
    FPort:              Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TMsgClientConnectionManager;
                       ClientSession:     PMsgClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TMsgNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                       );
    destructor Destroy; override;
  end;// TMsgClientMsgResendRequestThread
*)
{$ENDIF} // Client



{$IFDEF SERVER_VERSION} // Server

////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionTerminatorThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerSessionTerminatorThread = class(TMsgThread)
  private
    FManager:                 TMsgServerConnectionManager;
    FTerminatedSessions:      TMsgThreadList;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TMsgServerConnectionManager
                       );
    destructor Destroy; override;
  public
  end;// TMsgServerSessionThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerPingClientsThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerPingClientsThread = class(TMsgThread)
  private
    FManager:                 TMsgServerConnectionManager;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TMsgServerConnectionManager
                       );
    destructor Destroy; override;
  public
  end;// TMsgServerPingClientsThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerConnectionManager
//
////////////////////////////////////////////////////////////////////////////////


  TMsgServerConnectionManager = class (TMsgBaseConnectionManager)
   private
    FMaxMsgThreadCount:     Integer;
    FIncomingPackets:       TMsgThreadList;
    ListenerThread:         TMsgServerListenerThread;
    ResendRequestThread:    TMsgServerResendRequestThread;
    MsgResendRequestThread: TMsgServerMsgResendRequestThread;
    SessionTerminator:      TMsgServerSessionTerminatorThread;
    PingClientsThread:      TMsgServerPingClientsThread;
    FTerminatedSessions:    TMsgThreadList;
//    FCommandQueue:                TMsgThreadList; // list of PMsgRecvItem
//    FCommandResendRequestThread:  TMsgResendRequestThread;
   public
    FNetwork:       TMsgNetwork;
//    property Network: TMsgNetwork read FNetwork write FNetwork;
   protected
    function SessionsCount: Integer;
    function IsSessionTerminated(ClientSession: Pointer): Boolean;
    procedure TerminateAllSessionThreads(ServerSession: PMsgSrvrSession);
    procedure TerminateMessageThreads(ServerSession: PMsgSrvrSession);
    procedure TerminateCommandThreads(ServerSession: PMsgSrvrSession);
    procedure EnableNextCommand(ServerSession: PMsgSrvrSession);
    procedure PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TMsgNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False;
                               Packets:       TMsgThreadList = nil
                                 );
    procedure DeleteSession(ServerSession: PMsgSrvrSession;
                            SkipServerSessionTermination: Boolean = False;
                            SaveMessages: Boolean = True
                            );
    procedure DoDisconnect(Session: TMsgComBaseSession;
                            SkipServerSessionTermination: Boolean = False);
    procedure DoSendBuffer(
                          ServerSession:    PMsgSrvrSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = MsgNoAction
                                                  );
    procedure SendDisconnectRequest(ServerSession: PMsgSrvrSession;
                                    WaitForAnswer: Boolean = True;
                                    PTerminated: Pointer = nil
                                    );
    procedure SendConnectAckn(
                          ServerSession:        PMsgSrvrSession;
                          CurrentRequestID:     Integer = -1
                              );
    procedure SendPing(ServerSession: PMsgSrvrSession);
    procedure SendAcknowledgement(
                          ServerSession:        PMsgSrvrSession;
                          Msg:                  Boolean = False;
                          CurrentRequestID:     Integer = -1
                              );
    procedure OnDisconnect(
                               FNetwork:      TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
    procedure NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
    procedure WaitForServerSessionThread(
                 ServerSession:    PMsgSrvrSession;
                 TimeOut:          Cardinal = MsgWaitForServerSessionThreadTimeOut
                                          );
    procedure WaitForServerSessionMsgThread(
                 ServerSession:    PMsgSrvrSession;
                 TimeOut:          Cardinal = MsgWaitForServerSessionThreadTimeOut
                                          );
    procedure CommandReceived(
                          ServerSession:    PMsgSrvrSession;
                          ControlCode:      TMsgControlCode;
                          CurrentRequestID: Integer
                              );
    procedure MessageReceived(
                               ServerSession:  PMsgSrvrSession;
                               ControlCode:    TMsgControlCode = MsgMessage
                              );
    // if authorization buffer is valid (encrypted by the same crypto settings as in CryptoInfo)
    // then return true else return false
    function IsAuthorizationBufferValid(
                          CryptoInfo: TMsgCryptoInfo;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer
                                        ): Boolean;
   public
    constructor Create(Server: TComponent);
    destructor Destroy; override;
    // disconnect client by Host:Port
    procedure DisconnectClient(const Host: AnsiString; const Port: Integer); overload;
    // disconnect client by SessionID
    procedure DisconnectClient(const SessionID: Integer); overload;
    // disconnect session - internal
    procedure Disconnect(Session: TMsgComBaseSession; PTerminated: Pointer = nil);
   public
    procedure DisconnectAll(WaitForAllDisconnected: Boolean = True);
    procedure SendBuffer(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = MsgNoAction
                          );
    procedure ReceiveBuffer(
                          ServerSession:  PMsgSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
    procedure SendMessage(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TMsgControlCode = MsgMessage
                          );
    procedure ReceiveMessage(
                          ServerSession:  PMsgSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
    function GetClientInfo(
                          Session:          TMsgComBaseSession;
                          var Host:         AnsiString;
                          var Port:         Integer;
                          var Application:  AnsiString
                            ): Boolean;
    // fill array with server session object connected to this server
    procedure GetClientsList(var Clients: TMsgSessionsArray);
    procedure TerminateSession(Session: TMsgComBaseSession);
  end; // TMsgClientConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerSessionThread = class(TMsgThread)
  private
    FServerSession:           PMsgSrvrSession;
    FManager:                 TMsgServerConnectionManager;
    FCode:                    TMsgControlCode;
{$IFDEF ClientCommand_Fix}
    FFinishing:               Boolean;
{$ENDIF}
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TMsgServerConnectionManager;
                          ServerSession:    PMsgSrvrSession;
                          Code:             Integer = MsgNoAction
                       );
    destructor Destroy; override;
  public
  end;// TMsgServerSessionThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionMsgThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerSessionMsgThread = class(TMsgThread)
  private
    FServerSession:           PMsgSrvrSession;
    FManager:                 TMsgServerConnectionManager;
    FCode:                    TMsgControlCode;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TMsgServerConnectionManager;
                          ServerSession:    PMsgSrvrSession;
                          Code:             Integer = MsgMessage
                       );
    destructor Destroy; override;
  public
  end;// TMsgServerSessionMsgThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionDisconnectThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerSessionDisconnectThread = class(TMsgThread)
  private
    FServerSession:           PMsgSrvrSession;
    FManager:                 TMsgServerConnectionManager;
    FCurrentRequestID:        Integer;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TMsgServerConnectionManager;
                          ServerSession:    PMsgSrvrSession;
                          CurrentRequestID: Integer = -1
                       );
    destructor Destroy; override;
  public
  end;// TMsgServerSessionDisconnectThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerListenerThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerListenerThread = class(TMsgThread)
  private
    FManager:       TMsgServerConnectionManager;
    ServerSession:  PMsgSrvrSession;
    SessionFound:   Boolean;
    Error:          AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:       TMsgServerConnectionManager
                       );
    destructor Destroy; override;
  end;// TMsgServerListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerResendRequestThread = class(TMsgThread)
  private
    FManager:           TMsgServerConnectionManager;
    Error:              AnsiString;
    FNeeded:            Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TMsgServerConnectionManager
                       );
    destructor Destroy; override;
  end;// TMsgServerResendRequestThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerMsgResendRequestThread = class(TMsgThread)
  private
    FManager:           TMsgServerConnectionManager;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TMsgServerConnectionManager
                       );
    destructor Destroy; override;
  end;// TMsgServerMsgResendRequestThread

{$ENDIF} // Server



////////////////////////////////////////////////////////////////////////////////
//
// Procedures and Functions
//
////////////////////////////////////////////////////////////////////////////////

  function CheckSum(Buffer: PAnsiChar; BufferSize: Integer): Cardinal;

{$IFNDEF MsgCommunicator}
{IFDEF SERVER_VERSION}
{$ENDIF MsgCommunicator}
  function fnIsAuthorizationBufferValid(
                      CryptoInfo: TMsgCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
{$IFNDEF MsgCommunicator}
{ENDIF SERVER_VERSION}
{$ENDIF MsgCommunicator}

var
  NetLog: String;

implementation

uses
{$IFDEF SERVER_VERSION}
  MsgServer,
{$ENDIF}
{IFDEF MsgCommunicator}
 {$IFDEF CLIENT_VERSION}
  MsgClient,
 {$ENDIF}
{ENDIF}
{$IFNDEF MsgCommunicator}
  MsgCommunication,
  ACRDECCRC,
{$ENDIF}
  MsgComMain;

////////////////////////////////////////////////////////////////////////////////
// CheckSum
////////////////////////////////////////////////////////////////////////////////
function CheckSum(Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
var
 buf: PAnsiChar;
begin
// Start Point = Pointer(Buffer)+4
// Count (in Bytes) = BufferSize-4
  buf := Buffer + 4;
  Result := CRC32(555, PAnsiChar(Buffer+4), BufferSize-4);
(*
// Msg 4.10 & ACR 5.00 difference
  Result := ACR_CRC32(0, buf, BufferSize-4);//ACR_CRC32(555, buf, BufferSize-4);
    { TODO -oAlex : move to msg with new crypto engine}
*)
end;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgNetwork
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// CreateNetwork
//------------------------------------------------------------------------------
procedure TMsgNetwork.CreateNetwork;
begin
{$IFDEF API_NETWORK}
  FMsgNetwork := TMsgapiNetwork.Create(Self);
  FMsgNetwork.OnDataReceived := OnDataReceived;
  FMsgNetwork.OnDisconnect := OnDisconnect;
{$ELSE}
 {$IFDEF D6H}
//  FNetworkClient := TIdUDPClient.Create(nil);
  FNetworkServer := TIdUDPServer.Create(nil);
  FNetworkServer.OnUDPRead := OnDataReceived;
 {$ELSE}
  FTransport := TNMUDP.Create(nil);
  FTransport.OnDataReceived := OnDataReceived;
 {$ENDIF D6H}
{$ENDIF API_NETWORK}
end; // CreateNetwork


//------------------------------------------------------------------------------
// FreeNetwork
//------------------------------------------------------------------------------
procedure TMsgNetwork.FreeNetwork;
begin
{$IFDEF API_NETWORK}
  if FMsgNetwork <> nil then
   begin
    FMsgNetwork.Recreate := False;
    FMsgNetwork.Free;
    FMsgNetwork := nil;
   end;
{$ELSE}
 {$IFDEF D6H}
//  FNetworkClient.Free;
  FNetworkServer.Free;
 {$ELSE}
  FTransport.Free;
 {$ENDIF D6H}
{$ENDIF}
end; // FreeNetwork


//------------------------------------------------------------------------------
// ReCreateNetwork
//------------------------------------------------------------------------------
procedure TMsgNetwork.ReCreateNetwork;
var
  lRemoteHost:       AnsiString;
  lLocalHost:        AnsiString;
  lRemotePort:       Integer;
  lLocalPort:        Integer;
  lPacketSize:       Integer;
begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> START');
{$ENDIF}
  EnterCSect(FCSect^);
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> CS entered');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> RemoteHost="'+RemoteHost+'"');
{$ENDIF}
  lRemoteHost := RemoteHost;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> RemotePort='+IntToStr(RemotePort));
{$ENDIF}
  lRemotePort := RemotePort;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> LocalHost="'+LocalHost+'"');
{$ENDIF}
  lLocalHost := LocalHost;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> LocalPort='+IntToStr(LocalPort));
{$ENDIF}
  lLocalPort := LocalPort;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> Free...');
{$ENDIF}
  lPacketSize := PacketSize;
  FreeNetwork;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> Create...');
{$ENDIF}
  CreateNetwork;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> Set...');
{$ENDIF}
  LocalPort := lLocalPort;
  RemotePort := lRemotePort;
  RemoteHost := lRemoteHost;
  PacketSize := lPacketSize;
  LeaveCSect(FCSect^);
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.ReCreateNetwork> FINISH');
{$ENDIF}
end; // ReCreateNetwork


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgNetwork.Create(ConnectionManager: TMsgBaseConnectionManager);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.Create');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}
  New(FCSect);
  InitCSect(FCSect^);
  inherited Create;
  FManager := ConnectionManager;
  FLocalClient := RndClientID;
  CreateNetwork;
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgNetwork.Destroy;
var
  CSect:          PRTLCriticalSection;
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.Destroy');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}
  CSect := FCSect;
  EnterCSect(CSect^);
  try
   FreeNetwork;
   inherited Destroy;
  finally
   LeaveCSect(CSect^);
   DeleteCSect(CSect^);
   Dispose(CSect);
  end;
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end;// Destoy


//------------------------------------------------------------------------------
// RndClientID
//------------------------------------------------------------------------------
function TMsgNetwork.RndClientID: TMsgNetworkClientID;
label generate;
begin
  Randomize;
generate:
  Result := Random(MAXINT); // - (MAXINT div 2);
  if (Result >= 0) and (Result < 1024) then // Reserved for ServerID
{ TODO -oAll: Add to DevGuide:
ServerID must be unique for each server working at the one machine.
We recomend to set ServerID from the region 0...1023.
}
   goto generate;
end;// RndClientID


//------------------------------------------------------------------------------
// SetPacketSize
//------------------------------------------------------------------------------
procedure TMsgNetwork.SetPacketSize(Size: Integer);
begin
{$IFDEF API_NETWORK}
  FMsgNetwork.PacketSize := Size;
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetPacketSize
//------------------------------------------------------------------------------
function TMsgNetwork.GetPacketSize: Integer;
begin
{$IFDEF API_NETWORK}
  Result := FMsgNetwork.PacketSize;
{$ENDIF}
end;

//------------------------------------------------------------------------------
// SetRemoteHost
//------------------------------------------------------------------------------
procedure TMsgNetwork.SetRemoteHost(Host: AnsiString);
begin
{$IFDEF API_NETWORK}
  FMsgNetwork.RemoteHost := Host;
{$ELSE}
 {$IFDEF D6H}
  FRemoteHost := Host;
//  FNetworkClient.Host := Host;
 {$ELSE}
  FTransport.RemoteHost := Host;
 {$ENDIF}
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetRemoteHost
//------------------------------------------------------------------------------
function TMsgNetwork.GetRemoteHost: AnsiString;
begin
{$IFDEF API_NETWORK}
  Result := FMsgNetwork.RemoteHost;
{$ELSE}
 {$IFDEF D6H}
  Result := FRemoteHost;
//  Result := FNetworkClient.Host;
 {$ELSE}
  Result := FTransport.RemoteHost;
 {$ENDIF}
{$ENDIF}
end;


//------------------------------------------------------------------------------
// SetRemotePort
//------------------------------------------------------------------------------
procedure TMsgNetwork.SetRemotePort(Port: Integer);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.SetRemotePort');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  FMsgNetwork.RemotePort := Port;
{$ELSE}
 {$IFDEF D6H}
  FRemotePort := Port;
//  FNetworkClient.Port := Port;
 {$ELSE}
  FTransport.RemotePort := Port;
 {$ENDIF}
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetRemotePort
//------------------------------------------------------------------------------
function TMsgNetwork.GetRemotePort: Integer;
begin
{$IFDEF API_NETWORK}
  Result := FMsgNetwork.RemotePort;
{$ELSE}
 {$IFDEF D6H}
  Result := FRemotePort;
//  Result := FNetworkClient.Port;
 {$ELSE}
  Result := FTransport.RemotePort;
 {$ENDIF}
{$ENDIF}
end;


//------------------------------------------------------------------------------
// SetLocalPort
//------------------------------------------------------------------------------
procedure TMsgNetwork.SetLocalPort(Port: Integer);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.SetLocalPort');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  FMsgNetwork.LocalPort := Port;
{$ELSE}
 {$IFDEF D6H}
  FNetworkServer.Active := False;
  FNetworkServer.DefaultPort := Port;
  FNetworkServer.Active := True;
 {$ELSE}
  FTransport.LocalPort := Port;
 {$ENDIF}
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end;


//------------------------------------------------------------------------------
// SetLocalHost
//------------------------------------------------------------------------------
procedure TMsgNetwork.SetLocalHost(Host: AnsiString);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.SetLocalHost');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  FMsgNetwork.LocalHost := Host;
{$ELSE}
  FLocalHost := Host;
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetLocalHost
//------------------------------------------------------------------------------
function TMsgNetwork.GetLocalHost: AnsiString;
begin
{$IFDEF API_NETWORK}
  Result := FMsgNetwork.LocalHost;
{$ELSE}
  Result := FLocalHost;
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TMsgNetwork.GetLocalPort: Integer;
begin
{$IFDEF API_NETWORK}
  Result := FMsgNetwork.LocalPort;
{$ELSE}
 {$IFDEF D6H}
  Result := FNetworkServer.DefaultPort;
 {$ELSE}
  Result := FTransport.LocalPort;
 {$ENDIF}
{$ENDIF}
end;


//------------------------------------------------------------------------------
// SendBuffer
//------------------------------------------------------------------------------
procedure TMsgNetwork.SendBuffer(
                          Buffer: PAnsiChar;
                          Count:  Integer);
var
  Header: PMsgPacketHeader;
{$IFNDEF D6H}
  Buff: array [0..MsgMaxPacketSize] of AnsiChar;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
  buf: PAnsiChar;
  i: Integer;
{$ENDIF}
{$IFDEF NETWORK_TEST}
  Connections: TMsgList;
  Connection:  PMsgClntConnection;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_SHORT_PING}
  str: AnsiString;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
  str: AnsiString;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.SendBuffer');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

  Header := PMsgPacketHeader(Buffer);
  Header.Sender := FLocalClient;
  Header.CheckSum := CheckSum(Buffer, Count);
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
if LocalPort = MsgDefaultClientPort then
str := 'Client'
else
if LocalPort = MsgDefaultServerPort then
str := 'Server'
else
str := IntToStr(LocalPort);
str := str + '>>> '
+IntToStr(Header.CurrentRequestID)+' : '
+IntToStr(Header.PacketID)+' / '
+IntToStr(Header.ControlCode)
+' >>> '+RemoteHost+':'+IntToStr(RemotePort)
{$IFDEF API_NETWORK}
+' - '+IntToStr(Count)+' bytes'
{$ENDIF}
//+' - '+IntToStr(GetTickCount)+' msec'
//+' <'+IntToStr(Header.Recepient)+'>'
;
aaWriteToLog(str, NetLog);
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_SHORT_PING}
if Header.ControlCode = MsgPing then
begin
if LocalPort = MsgDefaultClientPort then
str := 'Client'
else
if LocalPort = MsgDefaultServerPort then
str := 'Server'
else
str := IntToStr(LocalPort);
str := str + '>>> '
+IntToStr(Header.CurrentRequestID)+' : '
+IntToStr(Header.PacketID)+' / '
+IntToStr(Header.ControlCode)
+' >>> '+RemoteHost+':'+IntToStr(RemotePort)
+' - '+IntToStr(GetTickCount)+' msec'
//+' <'+IntToStr(Header.Recepient)+'>'
;
aaWriteToLog(str, NetLog);
end;
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------');
aaWriteToLog('MsgConnection>TMsgNetwork.SendBuffer('+IntToHex(Integer(@Buffer),6)+', '+IntToStr(Count)+')');
aaWriteToLog('Sender    : '+IntToStr(FLocalClient));
aaWriteToLog('-----------');
aaWriteToLog('RemoteHost: '+RemoteHost);
aaWriteToLog('RemotePort: '+IntToStr(RemotePort));
aaWriteToLog('LocalHost : '+LocalHost);
aaWriteToLog('LocalPort : '+IntToStr(LocalPort));
aaWriteToLog('>>> Head:');
aaWriteToLog('CheckSum         '+IntToStr(Header.CheckSum));
aaWriteToLog('Signature        '+Header.Signature);
aaWriteToLog('Recepient        '+IntToStr(Header.Recepient));
aaWriteToLog('Sender           '+IntToStr(Header.Sender));
aaWriteToLog('ConnectionID     '+IntToStr(Header.ConnectionID));
aaWriteToLog('SessionID        '+IntToStr(Header.SessionID));
aaWriteToLog('CurrentRequestID '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('PacketID         '+IntToStr(Header.PacketID));
aaWriteToLog('ControlCode      '+IntToStr(Header.ControlCode));
(*
aaWriteToLog('>>> Data:');
buf:=MemoryManager.GetMem(Count-SizeOf(TMsgPacketHeader)+1);
Move(PAnsiChar(Integer(Buffer)+SizeOf(TMsgPacketHeader))^, buf^, Count-SizeOf(TMsgPacketHeader));
for i:= 0 to Count-SizeOf(TMsgPacketHeader)-1 do
  if (buf+i)^=#0 then
    (buf+i)^:='0';
(buf+Count-SizeOf(TMsgPacketHeader))^:=#0;
aaWriteToLog(buf);
aaWriteToLog('###');
MemoryManager.FreeAndNilMem(buf);
*)
{$ENDIF}

{******************************************************************************}
// Send Buffer
{******************************************************************************}
{$IFDEF NETWORK_TEST}
  if FManager.FClient then
   if Assigned(TMsgServerConnectionManager(FManager.FOtherManager).FNetwork.OnDataReceived) then
    TMsgServerConnectionManager(FManager.FOtherManager).FNetwork.OnDataReceived(Buffer, Count, LocalHost, LocalPort)
  else
   begin
    Connections:=TMsgClientConnectionManager(FManager.FOtherManager).FConnections.LockList;
    try
     Connection := Connections.Items[0];
    finally
     TMsgClientConnectionManager(FManager.FOtherManager).FConnections.UnlockList;
    end;
    Connection.Network.OnDataReceived(Buffer, Count, LocalHost, LocalPort);
   end;
{$ELSE}
 {$IFDEF API_NETWORK}
  FMsgNetwork.SendBuffer(Buffer, Count);
//  sleep(0); // TRY TO REMOVE!!!
 {$ELSE}
  {$IFDEF D6H}
  FNetworkServer.SendBuffer(FRemoteHost, FRemotePort, Buffer^, Count);
//  FNetworkClient.SendBuffer(Buffer^, Count);
  {$ELSE}
  Move(Buffer^, Buff[0], Count);
  FTransport.SendBuffer(Buff, Count);
  {$ENDIF D6H}
 {$ENDIF API_NETWORK}
{$ENDIF NETWORK_TEST}
//  LeaveCSect(FCSect);
{******************************************************************************}

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TMsgNetwork.OnDisconnect(
                             FromHost:  AnsiString;
                             FromPort:  Integer;
                             Recv:      Boolean = False
                             );
begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> START - '+IntToStr(GetTickCount)+' msec');
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> socket error from '+FromHost+':'+IntToStr(FromPort));
if Recv then
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> recv error')
else
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> send error');
{$ENDIF}
 try
  if (FManager = nil)
  or FManager.FListenerStoped
  then
   begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> Manager not exist - FINISH');
{$ENDIF}
    Exit;
   end;
  ReCreateNetwork;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> FManager.OnDisconnect...');
{$ENDIF}
  if not Recv then
    FManager.OnDisconnect(self, FromHost, FromPort);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
    raise;
   end;
 end;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('MsgConnection> TMsgNetwork.OnDisconnect> FINISH');
{$ENDIF}
end;// OnDisconnect


//------------------------------------------------------------------------------
// OnDataReceived
//------------------------------------------------------------------------------
{$IFDEF API_NETWORK}
procedure TMsgNetwork.OnDataReceived(
                             Buffer:    PAnsiChar;
                             Count:     Integer;
                             FromHost:  AnsiString;
                             FromPort:  Integer
                             );
{$ELSE}
 {$IFDEF D6H}
procedure TMsgNetwork.OnDataReceived(
                             Sender:   TObject;
                             AData:    TStream;
                             ABinding: TIdSocketHandle
                             );
 {$ELSE}
procedure TMsgNetwork.OnDataReceived(
                             Sender: TComponent;
                             BufferSize: Integer;
                             FromIP: AnsiString;
                             Port: integer
                             );
 {$ENDIF D6H}
{$ENDIF API_NETWORK}
var
  Buf: PAnsiChar;
  BufSize: Integer;
{$IFDEF API_NETWORK}
{$ELSE}
 {$IFDEF D6H}
  FromHost: AnsiString;
  FromPort: Integer;
 {$ELSE}
  Buffer: array [0..MsgMaxPacketSize] of AnsiChar;
 {$ENDIF}
{$ENDIF}
  Header: PMsgPacketHeader;
{$IFDEF DEBUG_LOG_NETWORK}
  buff: PAnsiChar;
  i: integer;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
  str: AnsiString;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_SHORT_PING}
  str: AnsiString;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TMsgNetwork.OnDataReceived');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  Buf := MemoryManager.GetMem(Count);
  Move(Buffer^, Buf^, Count);
  BufSize := Count;
{$ELSE}
 {$IFDEF D6H}
  Buf := MemoryManager.GetMem(MsgMaxPacketSize);
  BufSize := AData.Read(Buf^, MsgMaxPacketSize);
  FromHost := ABinding.PeerIP;
  FromPort := ABinding.PeerPort;
 {$ELSE}
  Buf := MemoryManager.GetMem(BufferSize);
  FTransport.ReadBuffer(Buffer, BufferSize);
  Move(Buffer[0], Buf^, BufferSize);
  BufSize := BufferSize;
 {$ENDIF D6H}
{$ENDIF API_NETWORK}
//  LeaveCSect(FCSect);
  Header := PMsgPacketHeader(Buf);
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
if LocalPort = MsgDefaultClientPort then
str := 'Client'
else
if LocalPort = MsgDefaultServerPort then
str := 'Server'
else
str := IntToStr(LocalPort);
str := str + '<<< '
+IntToStr(Header.CurrentRequestID)+' : '
+IntToStr(Header.PacketID)+' / '
+IntToStr(Header.ControlCode)
+' <<< '+FromHost+':'+IntToStr(FromPort)
{$IFDEF API_NETWORK}
+' - '+IntToStr(Count)+' bytes'
{$ENDIF}
//+' - '+IntToStr(GetTickCount)+' msec'
//+' <'+IntToStr(Header.Recepient)+'>'
;
aaWriteToLog(str, NetLog);
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_SHORT_PING}
if Header.ControlCode = MsgPing then
begin
if LocalPort = MsgDefaultClientPort then
str := 'Client'
else
if LocalPort = MsgDefaultServerPort then
str := 'Server'
else
str := IntToStr(LocalPort);
str := str + '<<< '
+IntToStr(Header.CurrentRequestID)+' : '
+IntToStr(Header.PacketID)+' / '
+IntToStr(Header.ControlCode)
+' <<< '+FromHost+':'+IntToStr(FromPort)
+' - '+IntToStr(GetTickCount)+' msec'
//+' <'+IntToStr(Header.Recepient)+'>'
;
aaWriteToLog(str);
end;
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------');
aaWriteToLog('MsgConnection>TMsgNetwork.OnDataReceived('+IntToHex(Integer(@Buf),6)+', '+IntToStr(BufSize)+')');
aaWriteToLog('Recepient : '+IntToStr(FLocalClient));
aaWriteToLog('-----------');
 {$IFDEF API_NETWORK}
aaWriteToLog('RemoteHost: '+FromHost);
aaWriteToLog('RemotePort: '+IntToStr(FromPort));
 {$ELSE}
  {$IFDEF D6H}
aaWriteToLog('RemoteHost: '+FromHost);
aaWriteToLog('RemotePort: '+IntToStr(FromPort));
  {$ELSE}
aaWriteToLog('RemoteHost: '+FromIP);
aaWriteToLog('RemotePort: '+IntToStr(Port));
  {$ENDIF D6H}
 {$ENDIF API_NETWORK}
aaWriteToLog('LocalHost : '+LocalHost);
aaWriteToLog('LocalPort : '+IntToStr(LocalPort));
aaWriteToLog('>>> Head:');
aaWriteToLog('CheckSum         '+IntToStr(Header.CheckSum));
aaWriteToLog('Signature        '+Header.Signature);
aaWriteToLog('Recepient        '+IntToStr(Header.Recepient));
aaWriteToLog('Sender           '+IntToStr(Header.Sender));
aaWriteToLog('ConnectionID     '+IntToStr(Header.ConnectionID));
aaWriteToLog('SessionID        '+IntToStr(Header.SessionID));
aaWriteToLog('CurrentRequestID '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('PacketID         '+IntToStr(Header.PacketID));
aaWriteToLog('ControlCode      '+IntToStr(Header.ControlCode));
(*
aaWriteToLog('>>> Data:');
buff:=MemoryManager.GetMem(BufSize-SizeOf(TMsgPacketHeader)+1);
Move(PAnsiChar(Integer(Buf)+SizeOf(TMsgPacketHeader))^, buff^, BufSize-SizeOf(TMsgPacketHeader));
for i:= 0 to BufSize-SizeOf(TMsgPacketHeader)-1 do
  if (buff+i)^=#0 then
    (buff+i)^:='0';
(buff+BufSize-SizeOf(TMsgPacketHeader))^:=#0;
aaWriteToLog(buff);
aaWriteToLog('###');
MemoryManager.FreeAndNilMem(buff);
*)
{$ENDIF DEBUG_LOG_NETWORK}

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount)+ ' - buffer prepared');
{$ENDIF}
  if (Header.Recepient = FLocalClient)
{$IFDEF MsgCommunicator}
  or (
//      (Header.Recepient = Integer(MSG_INVALID_USER_ID)) and
      ((Header.ControlCode = MsgConnect) or (Header.ControlCode = MsgConnect+MsgLastPacket))
      and
      (Header.Signature = MsgClientPacketSign)
      )
{$ENDIF MsgCommunicator}
  then
{$IFDEF API_NETWORK}
    FManager.NetworkListener(Buf, BufSize, Self, FromHost, FromPort);
{$ELSE}
 {$IFDEF D6H}
    FManager.NetworkListener(Buf, BufSize, Self, FromHost, FromPort);
 {$ELSE}
    FManager.NetworkListener(Buf, BufSize, Self, FromIP, Port);
 {$ENDIF D6H}

{$ENDIF API_NETWORK}

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount)+' - end of parsing');
aaWriteToLog('');
{$ENDIF}
end;
// TMsgNetwork



////////////////////////////////////////////////////////////////////////////////
//
// TMsgBaseConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

constructor TMsgBaseConnectionManager.Create;
begin
  FMaxThreadCount := MsgMaxThreadCount;
  FSendingThreads := TMsgThreadList.Create;
  inherited Create;
end;

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgBaseConnectionManager.Destroy;
begin
  CloseThreads(FSendingThreads,100);
  inherited Destroy;
end;// Destroy

//------------------------------------------------------------------------------
// TMsgBaseConnectionManager.IncThreadCount
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.IncThreadCount(Ignore: Boolean);
begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgBaseConnectionManager.IncThreadCount> START:  ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
  if not Ignore then
    EnterCSect(FCSect);
  FThreadCount := FThreadCount+1;
  if not Ignore then
    LeaveCSect(FCSect);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgBaseConnectionManager.IncThreadCount> FINISH: ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
end;// TMsgBaseConnectionManager.IncThreadCount

//------------------------------------------------------------------------------
// TMsgBaseConnectionManager.DecThreadCount
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.DecThreadCount(Ignore: Boolean);
begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgBaseConnectionManager.DecThreadCount> START:  ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
  if not Ignore then
    EnterCSect(FCSect);
  FThreadCount := FThreadCount-1;
  if not Ignore then
    LeaveCSect(FCSect);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgBaseConnectionManager.DecThreadCount> FINISH: ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
end;// TMsgBaseConnectionManager.DecThreadCount

//------------------------------------------------------------------------------
// TMsgBaseConnectionManager.SetThreadCount
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.SetThreadCount(Value: Integer);
begin
  EnterCSect(FCSect);
  FThreadCount := Value;
  LeaveCSect(FCSect);
end;// TMsgBaseConnectionManager.SetThreadCount


//------------------------------------------------------------------------------
// WaitForThread
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.WaitForThread(
                          Thread:        PThread;
                          TimeOut:       Cardinal;
                          SleepTime:     Cardinal = 1
                          );
var
  StartTime:      Cardinal;
begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.WaitForThread> TimeOut = '+IntToStr(TimeOut));
{$ENDIF}
  StartTime := GetTickCount;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.WaitForThread> Started at: '+IntToStr(StartTime));
{$ENDIF}
  while ((GetTickCount-StartTime) < TimeOut) do
   begin
    if Thread^ = nil then
      break;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('WaitForThread> Sleep('+IntToStr(SleepTime)+')...');
{$ENDIF}
    sleep(SleepTime);
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('WaitForThread> up!');
{$ENDIF}
   end;
{$IFDEF LOG_TERMINATE_THREAD}
if Thread^ = nil then
aaWriteToLog('TMsgBaseConnectionManager.WaitForThread> Thread Finished at: '+IntToStr(GetTickCount))
else
aaWriteToLog('TMsgBaseConnectionManager.WaitForThread> Thread Not Finished! Timeout at: '+IntToStr(GetTickCount));
{$ENDIF}
end; // Wait for thread finish


//------------------------------------------------------------------------------
// CloseThread
//------------------------------------------------------------------------------
function TMsgBaseConnectionManager.CloseThread(
                          Thread:        PThread;
                          ErrProcess:    Integer;
                          ErrObject:     AnsiString;
                          WaitTimeOut:   Cardinal = MsgServerThreadsTerminateDelay;
                          SleepTime:     Cardinal = 1
                                      ): Boolean;
var
  Error:          AnsiString;
begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> START');
{$ENDIF}
 try
  Result := False;
  if Thread^ = nil then
   begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Thread is not started - OK');
{$ENDIF}
    Result := True;
    Exit;
   end;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Ask to terminate Thread...');
{$ENDIF}
  // AskToTerminate
  if Thread^ is TMsgThread then
    TMsgThread(Thread^).FRecreate := false;
  Thread^.Terminate;
  WaitForThread(Thread, WaitTimeOut, SleepTime);
  if Thread^ = nil then
   begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Terminated!');
{$ENDIF}
    Result := True;
    Exit;
   end
  else
   begin // ForceToTerminate
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Not Terminated!');
{$ENDIF}
    if Self is TMsgServerConnectionManager then
     begin
      Error:= ErrorRServer+ErrObject+IntToStr(Integer(Thread^.ThreadID))+'/'+IntToStr(Integer(Thread^.Handle))+ErrorRExecute;
      TMsgServer(FServer).DoOnConnectionError(ErrProcess,40517,
                    Error+ErrorRCannotTerminateThread+IntToStr(WaitTimeOut));
     end;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Force to terminate Thread...');
{$ENDIF}
    try
     Result := TerminateThread(Thread^.Handle, 0);
    except
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('Exception in TerminateThread!');
{$ENDIF}
    end;
    if not Result then
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Not Terminated! - CloseThread failed');
{$ENDIF}
      if Self is TMsgServerConnectionManager then
       begin
        TMsgServer(FServer).DoOnConnectionError(ErrProcess,40518,
                    Error+'CloseThread failed - '+ErrorRCannotKillThread+IntToStr(GetLastError));
       end;
     end;
    if Thread^.Handle <> 0 then
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> CloseHandle...');
{$ENDIF}
      try
       Result := CloseHandle(Thread^.Handle);
      except
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('Exception in CloseHandle!');
{$ENDIF}
      end;
     end;
    if Result then
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> CloseHandle - ok');
{$ENDIF}
      if Thread^ <> nil then
       begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> free...');
{$ENDIF}
        Thread^.Free;
       end;
      Thread^ := nil;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> DecThreadCount...');
{$ENDIF}
      DecThreadCount(True);
     end
    else
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Not Terminated! - CloseHandle failed');
{$ENDIF}
      if Self is TMsgServerConnectionManager then
       begin
        TMsgServer(FServer).DoOnConnectionError(ErrProcess,40518,
                    Error+'CloseHandle failed - '+ErrorRCannotKillThread+IntToStr(GetLastError));
       end;
     end;
    Result := False;
   end; // ForceToTerminate
 finally
{$IFDEF LOG_TERMINATE_THREAD}
if Result then
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Thread terminated successfully!')
else
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> Thread is not terminated!');
aaWriteToLog('TMsgBaseConnectionManager.CloseThread> finished');
{$ENDIF}
 end;
end;


//------------------------------------------------------------------------------
// CloseThreads
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.CloseThreads(
                           ThreadList:    TMsgThreadList;
                           WaitTimeOut:   Cardinal = MsgServerThreadsTerminateDelay
                                                );
var
  threads:      TMsgList;
  i:            Integer;
  thread:       TMsgThread;
begin
  if ThreadList = nil then
    Exit;
  threads := ThreadList.LockList;
  try
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThreads> START:  threads.Count = '+IntToStr(threads.Count));
{$ENDIF}
   for i:=threads.Count-1 downto 0 do
    begin
     thread := threads.Items[i];
     threads.delete(i);
     CloseThread(@thread,MsgClientConnectionManager,ErrorRMessageResendRequestThread,WaitTimeOut);
    end;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TMsgBaseConnectionManager.CloseThreads> FINISH: threads.Count = '+IntToStr(threads.Count));
{$ENDIF}
  finally
   ThreadList.UnlockList;
  end;
  ThreadList.Free;
end; // CloseThreads


//------------------------------------------------------------------------------
// GetBufferFromPackets
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.GetBufferFromPackets(
                        Packets:        TMsgThreadList;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                                         );
var
  lPackets:     TMsgList;
  Packet:       PMsgPacket;
  pBuf:         PAnsiChar;
  size, i:      Integer;
begin
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> START');
{$ENDIF}
  BufferSize := 0;
  lPackets := Packets.LockList;
  try
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Packets.Count = '+IntToStr(Packets.Count));
{$ENDIF}
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Calculate buffer size...');
{$ENDIF}
   for i := 0 to lPackets.Count - 1 do
    begin
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Packet # '+IntToStr(i));
{$ENDIF}
     Packet := lPackets.Items[i];
     BufferSize := BufferSize + Packet.BufferSize - SizeOf(TMsgPacketHeader);
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Packet.BufferSize = '+IntToStr(Packet.BufferSize));
{$ENDIF}
    end;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
   if BufferSize > 0 then
     Buffer := MemoryManager.GetMem(BufferSize)
   else
    begin
     Buffer := nil;
     Exit;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> ERROR: buffer size = '+IntToStr(BufferSize));
{$ENDIF}
    end;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Buffer memory got');
{$ENDIF}
    pBuf := Buffer;
    for i := 0 to lPackets.Count - 1 do
     begin
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> local list  Packets.Count = '+IntToStr(lPackets.Count));
aaWriteToLog('GetBufferFromPackets> TThreadList Packets.Count = '+IntToStr(Packets.Count));
{$ENDIF}
      Packet := lPackets.Items[i];
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Packet # '+IntToStr(i));
{$ENDIF}
      if Packet <> nil then
       begin
        if Packet.Buffer <> nil then
         begin
          try
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> size...');
{$ENDIF}
          size := Packet.BufferSize-SizeOf(TMsgPacketHeader);
          if (size > 0) then
           begin
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> move...');
{$ENDIF}
            Move(Pointer(Packet.Buffer+SizeOf(TMsgPacketHeader))^, pBuf^, size);
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> inc...');
{$ENDIF}
            inc(pBuf, size);
           end;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> inced'+IntToStr(Packet.BufferSize-SizeOf(TMsgPacketHeader)));
aaWriteToLog('GetBufferFromPackets> free packet buffer...');
{$ENDIF}
          finally
          MemoryManager.FreeAndNilMem(Packet.Buffer);
          end;
         end;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Dispose packet...');
{$ENDIF}
        Dispose(Packet);
       end;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> Clear packets list...');
{$ENDIF}
   end;
   lPackets.Clear;
  finally
   Packets.UnlockList;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> FINISH');
{$ENDIF}
  end
end; // GetBufferFromPackets


//------------------------------------------------------------------------------
// compresses and encrypts buffer
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.CompressAndEncryptBuffer(
                        Session:              TMsgComBaseSession;
                        InBuffer:             PAnsiChar;
                        InBufferSize:         Integer;
                        var OutBuffer:        PAnsiChar;
                        var OutBufferSize:    Integer
                                                              );
begin
 try
  MsgBaseEngine.CompressAndEncryptBuffer(Session.ConnectParams.CryptoInfo,
                                         Session.ConnectParams.CompressionAlgorithm,
                                         Session.ConnectParams.CompressionMode,
                                         InBuffer,  InBufferSize,
                                         OutBuffer, OutBufferSize);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> CompressAndEncryptBuffer - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
    raise;
   end;
 end;
end; // CompressAndEncryptBuffer


//------------------------------------------------------------------------------
// decompresses and decrypts buffer
//------------------------------------------------------------------------------
function TMsgBaseConnectionManager.DecompressAndDecryptBuffer(
                        Session:              TMsgComBaseSession;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                                              ): Boolean;
begin
 if (Buffer = nil)
 or (BufferSize <= 0) then
  begin
   Result := True;
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('DecompressAndDecryptBuffer> ERROR: Empty buffer!');
{$ENDIF}
   Exit;
  end;
 try
  Result := MsgBaseEngine.DecompressAndDecryptBuffer(
                                Session.ConnectParams.CryptoInfo,
                                Session.ConnectParams.CompressionAlgorithm,
                                Session.ConnectParams.CompressionMode,
                                Buffer,
                                BufferSize);
 except
  on E: Exception do
   begin
    Result := False;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> DecompressAndDecryptBuffer - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
   end;
 end;
end; // DecompressAndDecryptBuffer


//------------------------------------------------------------------------------
// FreePackets
//------------------------------------------------------------------------------
procedure TMsgBaseConnectionManager.FreePackets(Packets: TMsgThreadList);
var
  PacketsList:  TMsgList;
  Packet:       PMsgPacket;
  i:            Integer;
begin
 PacketsList := Packets.LockList;
 try
  for i:= 0 to PacketsList.Count-1 do
   begin
    Packet := PMsgPacket(PacketsList.Items[i]);
    if Packet <> nil then
     begin
      if Packet.Buffer <> nil then
        MemoryManager.FreeAndNilMem(Packet.Buffer);
      Dispose(Packet);
     end;
   end;
 finally
  Packets.UnlockList;
 end;
end;// FreePackets


//------------------------------------------------------------------------------
// MessageStatus
//------------------------------------------------------------------------------
function TMsgBaseConnectionManager.MessageStatus(
                        Header:                 PMsgPacketHeader;
                        Messages:               TMsgThreadList
                            ): Integer;
var
  msgStatus:  PMsgMessageStatus;
begin
  Result := MsgNotFound;
  msgStatus := FindMessage(Messages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
  if (msgStatus <> nil) then
    Result := msgStatus.Status;
end; // MessageStatus


//------------------------------------------------------------------------------
// FindMessageInQueue
//------------------------------------------------------------------------------
function TMsgBaseConnectionManager.FindMessageInQueue(Header: PMsgPacketHeader): PMsgRecvItem;
var
  msg:        PMsgRecvItem;
  packets,
  messages:   TMsgList;
  i, j:       Integer;
begin
  Result := nil;
  messages := FMessageQueue.LockList;
  try
   for i:=0 to messages.Count-1 do
    begin
     msg := messages[i];
     if msg = nil then
      begin
       continue;
      end;
     if msg.Packets = nil then
      begin
       continue;
      end;
     packets := msg.Packets.LockList;
     try
       for j:=0 to packets.Count-1 do
         if msg.Packets.Items[j] <> nil then
         if PMsgPacket(msg.Packets.Items[j]).Buffer <> nil then
         if PMsgPacket(msg.Packets.Items[j]).BufferSize >= SizeOf(TMsgPacketHeader) then
          begin
           if CompareMem(PMsgPacket(msg.Packets.Items[j]).Buffer+SizeOf(Cardinal),
                         PAnsiChar(Header)+SizeOf(Cardinal), // exclude CRC
                         SizeOf(TMsgPacketHeader)
                         -SizeOf(Integer)-SizeOf(TMsgControlCode) // exclude PacketID and ControlCode
                         -SizeOf(Cardinal))
           then
            begin
             Result := msg;
             Exit;
            end;
           break;
          end;
     finally
      msg.Packets.UnlockList;
     end;
    end; // i
  finally
   FMessageQueue.UnlockList;
  end;
end; // FindMessageInQueue


//------------------------------------------------------------------------------
// FindMessage
//------------------------------------------------------------------------------
function TMsgBaseConnectionManager.FindMessage(
                        Messages:               TMsgThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TMsgNetworkClientID;
                        ConnectionID:           TMsgConnectionID;
                        SessionID:              TMsgSessionID
                                               ): PMsgMessageStatus;
var
  msgStatus:  PMsgMessageStatus;
  msgs:       TMsgList;
  i:          Integer;
begin
  Result := nil;
  msgs := Messages.LockList;
  try
   for i:=0 to msgs.Count-1 do
    begin
     msgStatus := msgs[i];
     if msgStatus.MessageID = MessageID then
     if msgStatus.NetworkClientID = NetworkClientID then
     if msgStatus.ConnectionID = ConnectionID then
     if msgStatus.SessionID = SessionID then
      begin
       Result := msgStatus;
       break;
      end;
    end;
  finally
   Messages.UnlockList;
  end;
end; // FindMessage


//------------------------------------------------------------------------------
// SetMessageStatus
//------------------------------------------------------------------------------
function TMsgBaseConnectionManager.SetMessageStatus(
                        Messages:               TMsgThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TMsgNetworkClientID;
                        ConnectionID:           TMsgConnectionID;
                        SessionID:              TMsgSessionID;
                        NewStatus:              Integer
                                               ): Boolean;
var
  msgStatus:  PMsgMessageStatus;
begin
  msgStatus := FindMessage(Messages,MessageID,NetworkClientID,ConnectionID,SessionID);
  if msgStatus = nil then
    Result := False
  else
   begin
    msgStatus.Status := NewStatus;
    Result := True;
   end;
end; // SetMessageStatus



////////////////////////////////////////////////////////////////////////////////
//
// TMsgQueueProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgQueueProcessorThread.Create(
                        Manager:        TMsgBaseConnectionManager;
                        Queue:          TMsgThreadList;
                        Command:        Boolean = True;
                        MaxThreadCount: Integer = MsgMaxThreadCount
                                            );
begin
 try
  Manager.IncThreadCount;
  FManager := Manager;
  FQueue := Queue;
  FCommand := Command;
  MaxThreads := MaxThreadCount;
  Error :=  ErrorRClient;
  if Command then
    Error :=  Error + ErrorRCommandProcessorThread
  else
    Error :=  Error + ErrorRMessageProcessorThread;
  Error := Error + IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle));
  inherited Create(False);
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('CLIENT LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRCreate+E.Message);
{$ENDIF}
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgQueueProcessorThread.Destroy;
begin
try
 try
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('CLIENT LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FCommand then
    FManager.FCommandProcessorThread := nil
  else
    FManager.FMessageProcessorThread := nil;
  inherited Destroy;
  FManager.DecThreadCount;
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('CLIENT LISTENER THREAD - FINISHED');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRDestroy+E.Message);
{$ENDIF}
   end;
 end;
finally
  if not Terminated then
  if FRecreate then
   begin
    sleep(MsgThreadRecreateSleep);
    if not Terminated then
    if FCommand then
      FManager.FCommandProcessorThread := TMsgQueueProcessorThread.Create(FManager,FQueue,FCommand,ThreadsCount)
    else
      FManager.FMessageProcessorThread := TMsgQueueProcessorThread.Create(FManager,FQueue,FCommand,ThreadsCount);
   end;
end;
end; // Destroy


//------------------------------------------------------------------------------
// TMsgQueueProcessorThread.Execute
//------------------------------------------------------------------------------
procedure TMsgQueueProcessorThread.Execute;
var
  i,
  SleepTime:      Integer;
  Queue:          TMsgList;
  RecvItem:       PMsgRecvItem;
  Thread:         TMsgThread;
begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> START - '+IntToStr(GetTickCount));
{$ENDIF}
try
 i := 0;
 SleepTime := 1;
 repeat
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
//aaWriteToLog('TMsgQueueProcessorThread.Execute> sleep('+IntToStr(SleepTime)+')...');
{$ENDIF}
  sleep(SleepTime);
  if FCommand then // commands can be lost
    if Terminated then
      Exit;
  try // except - continue loop
   Queue := FQueue.LockList;
   try
    if Terminated then // all the messages should be processed before exit
      if Queue.Count = 0 then
        Exit
      else
       begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> termination signal ignored to process all the messages in queue!');
{$ENDIF}
       end;
    if Queue.Count = 0 then
     begin
      SleepTime := 1; // To avoid 100% CPU usage
      Continue;
     end;
    if i >= Queue.Count then
     begin
      i := 0;
      SleepTime := 16; // last item pause
     end
    else
      SleepTime := 0;

{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> Queue.Count = '+IntToStr(Queue.Count));
aaWriteToLog('TMsgQueueProcessorThread> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}

{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> get item...');
{$ENDIF}
    RecvItem := Queue.Items[i];
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
   finally
    FQueue.UnlockList;
   end;
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgMessageThread> Status = '+IntToStr(PMsgClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PMsgClntSession(RecvItem.Session)),8));
aaWriteToLog('TMsgQueueProcessorThread.Execute> is session existing...');
{$ENDIF}
   if not TMsgClientConnectionManager(FManager).IsSessionExisting(PMsgClntSession(RecvItem.Session)) then
    begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> session terminated');
{$ENDIF}
     FQueue.Delete(i);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> session terminated, deleted RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
     Continue;
    end
   else // session exists
    if RecvItem.RecvStatus = MsgFull then
     begin
      FQueue.Delete(i);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> is full, deleted RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
     end
    else // not full
     begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> Status = '+IntToStr(PMsgClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PMsgClntSession(RecvItem.Session)),8));
{$ENDIF}
      dec(PMsgClntSession(RecvItem.Session).Status);
      LeaveCSect(PMsgClntSession(RecvItem.Session).FCSect);
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> dec in-use counter, Status = '+IntToStr(PMsgClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PMsgClntSession(RecvItem.Session)),8));
aaWriteToLog('TMsgQueueProcessorThread.Execute> i='+IntToStr(i)+', inc...');
{$ENDIF}
      inc(i); // try next item
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> inced!');
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> not full, get next item # '+IntToStr(i));
{$ENDIF}
      Continue;
     end;
   try // session entered CSect
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> full buffer');
{$ENDIF}
    SleepTime := 1;
    while (FManager.ThreadCount >= FManager.FMaxThreadCount)
      or (ThreadsCount >= MaxThreads)
    do
     begin
      sleep(SleepTime);
      if SleepTime < 500 then
        SleepTime := SleepTime * 4;
     end;
    if FCommand then
     begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> command');
{$ENDIF}
//        TMsgThread(TMsgCommandThread.Create(FManager,RecvItem));
     end
    else
     begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> message');
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> create message thread for RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
      TMsgMessageThread.Create(FManager,RecvItem);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> thread created for RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
     end;
    SleepTime := 0;
   finally
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> leave session CS for RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
    LeaveCSect(PMsgClntSession(RecvItem.Session).FCSect);
    dec(PMsgClntSession(RecvItem.Session).Status);
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TMsgMessageThread> Status = '+IntToStr(PMsgClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PMsgClntSession(RecvItem.Session)),8));
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgQueueProcessorThread> get next item with same #');
{$ENDIF}
   end;
  except
   on E: Exception do
    begin
     FRecreate := True;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
     Exit;
    end;
  end;
 until False;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgQueueProcessorThread.Execute> FINISH');
{$ENDIF}
except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
   end;
end;
end; // TMsgQueueProcessorThread.Execute

// TMsgQueueProcessorThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgMessageThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgMessageThread.Create(
                        Manager:          TMsgBaseConnectionManager;
                        Msg:              PMsgRecvItem
                                            );
begin
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Create...');
{$ENDIF}
 try
  Manager.IncThreadCount;
  FManager := Manager;
  FMsg := Msg;
  FManager.FMessageThreads.Add(Self);
  Error :=  ErrorRClient + ErrorRMessageThread
            + IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle));
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> inherited...');
{$ENDIF}
  inherited Create(False);
  FRecreate := False;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Created!');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRCreate + E.Message);
{$ENDIF}
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgMessageThread.Destroy;
begin
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Destroy...');
{$ENDIF}
 try
  try
   FManager.DecThreadCount;
   inherited Destroy;
  except
   on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRDestroy + E.Message);
{$ENDIF}
    end;
  end;
 finally
  FManager.FMessageThreads.Remove(Self);
  if FRecreate then
   begin
    sleep(MsgThreadRecreateSleep);
    TMsgMessageThread.Create(FManager,FMsg);
   end;
 end;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Destroy finished!');
{$ENDIF}
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgMessageThread.Execute;
var
  Buf:                 PAnsiChar;
  BufSize, AuBufSize:  Integer;
  ConnectionParams:    PMsgConnectionParams;
begin
 try // except
    try
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Receive message buffer...');
{$ENDIF}
     FManager.GetBufferFromPackets(FMsg.Packets, Buf, BufSize);
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Free packets list...');
{$ENDIF}
     FMsg.Packets.Free;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> remove message from queue...');
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40507,'MsgMessage section - '+ErrorRCannotReceiveMsg+E.Message);
    end;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> Decompress and decrypt buffer...');
{$ENDIF}
    if FManager.DecompressAndDecryptBuffer(PMsgClntSession(FMsg.Session).Session, Buf, BufSize) then
     begin
      try
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> process new message...');
aaWriteToLog('TMsgMessageThread> Status = '+IntToStr(PMsgClntSession(FMsg.Session).Status)+' @='+IntToHex(Integer(PMsgClntSession(FMsg.Session)),8));
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgMessageThread> receive message for RecvItem = '+IntToStr(Integer(FMsg)));
{$ENDIF}
      TMsgNetworkSession(PMsgClntSession(FMsg.Session).Session).ReceiveMessage(Buf, BufSize);
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> message received!');
aaWriteToLog('TMsgMessageThread> Status = '+IntToStr(PMsgClntSession(FMsg.Session).Status)+' @='+IntToHex(Integer(PMsgClntSession(FMsg.Session)),8));
{$ENDIF}
      except
       on E:Exception do
        raise EMsgException.Create(40512,'MsgMessage section - '+ErrorRSessionReceiveMessage+E.Message);
      end;
     end;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> free...');
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgMessageThread> Dispose RecvItem = '+IntToStr(Integer(FMsg)));
{$ENDIF}
    Dispose(FMsg);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgMessageThread> OK!');
{$ENDIF}
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TMsgMessageThread> execute finished!');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
   end;
 end;
end; // Execute

// TMsgMessageThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgSendingThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgSendingThread.Create(
                          Session:    TMsgNetworkSession;
                          Manager:    TMsgBaseConnectionManager;
                          Method:     Pointer;
                          arg1,arg2,arg3,arg4,arg5: Integer
                                            );
begin
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Create> START');
{$ENDIF}
 try
  Manager.IncThreadCount;
  FSession := Session;
  FManager := Manager;
  FMethod := Method;
  Farg1 := arg1;
  Farg2 := arg2;
  Farg3 := arg3;
  Farg4 := arg4;
  Farg5 := arg5;
  Error :=  ErrorRClient + ErrorRSendingThread
            + IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle));
  inherited Create(False);
  FRecreate := False;
  FManager.FSendingThreads.Add(Self);
 except
  on E: Exception do
   begin
    try
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRCreate + E.Message);
{$ENDIF}
     Destroy;
    except
    end;
   end;
 end;
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Create> FINISH');
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgSendingThread.Destroy;
begin
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Destroy> START');
{$ENDIF}
 try
  try
   FManager.DecThreadCount;
   inherited Destroy;
  except
   on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRDestroy + E.Message);
{$ENDIF}
    end;
  end;
 finally
  FManager.FSendingThreads.Remove(Self);
  if not Terminated then
  if FRecreate then
   begin
    sleep(MsgThreadRecreateSleep);
    if not Terminated then
    TMsgSendingThread.Create(FSession,FManager,FMethod,Farg1,Farg2,Farg3,Farg4,Farg5);
   end;
 end;
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Destroy> FINISH');
{$ENDIF}
end;// Destroy;


{$IFDEF MsgCommunicator}
////////////////////////////////////////////////////////////////////////////////
// Connect
////////////////////////////////////////////////////////////////////////////////
procedure TMsgSendingThread.Connect(
                                NetworkPacket:        PMsgNetworkPacket
                                    );
var
  Header:               PMsgPacketHeader;
  Packet:               PMsgPacket;
  Connections:          TMsgList;
{$IFDEF MsgCommunicator}
  Session:              TMsgComBaseSession;
  ClientSession,
  ClientSession2:       PMsgClntSession;
{$ENDIF}
  ClientConnection:     PMsgClntConnection;
  SessionFound,
  Session2Found,
  ConnectionFound:      Boolean;
  Buf:                  PAnsiChar;
  BufSize:              Integer;
  i:                    Integer;
{$IFDEF MsgCommunicator}
  RemoteUserID,
  AuBufSize:            Integer;
  ConnectionParams:     PMsgConnectionParams;
  Application:          AnsiString;
{$ENDIF}
  CurrentRequestID:     Integer;
  Packets:              TMsgList;
  Sessions:             TMsgList;
  PacketAdded:          Boolean;
  Host:                 AnsiString;
  Port:                 Integer;

procedure GetClientConnection;
var
  i:                    Integer;
begin
  ConnectionFound := False;
  Connections := TMsgClientConnectionManager(FManager).FConnections.LockList;
  try
   for i:=0 to Connections.Count-1 do
    begin
     ClientConnection := Connections.Items[i];
     if ClientConnection.Network = NetworkPacket.Network then
       begin
        ConnectionFound := True;
        break;
       end;
    end;
  finally
   TMsgClientConnectionManager(FManager).FConnections.UnlockList;
  end;
end; // GetClientConnection

begin // Connect
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> Connect');
{$ENDIF}
 try
  ClientConnection := nil;
  Header := PMsgPacketHeader(NetworkPacket.Packet.Buffer);
  PacketAdded := False;
// is direct connection enabled?
  SessionFound := False;
  Session2Found := False;
  Sessions := FManager.FSessions.LockList;
  try
   for i:=0 to Sessions.Count-1 do
    begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> get ClientSession2['+IntToStr(i)+'] of '+IntToStr(Sessions.Count));
{$ENDIF}
     ClientSession2 := Sessions.Items[i];
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> ServerSessionID'+IntToStr(ClientSession2.ServerSessionID));
if TMsgClientSession(ClientSession2.Session)<>nil then
begin
aaWriteToLog('TMsgSendingThread> Session.UserID   = '+IntToStr(TMsgClientSession(ClientSession2.Session).UserID));
aaWriteToLog('TMsgSendingThread> Header.Recepient = '+IntToStr(Header.Recepient));
if TMsgClientSession(ClientSession2.Session).Direct then
aaWriteToLog('TMsgSendingThread> direct session')
else
aaWriteToLog('TMsgSendingThread> session not direct');
if ClientSession2.Session.Connected then
aaWriteToLog('TMsgSendingThread> session connected')
else
aaWriteToLog('TMsgSendingThread> session not connected');
aaWriteToLog('TMsgSendingThread> ClientSession2.Session.SessionID = '+IntToStr(ClientSession2.Session.SessionID));
end;
{$ENDIF}
     if (ClientSession2.ServerSessionID = INVALID_SESSION_ID) then
      if ClientSession2.Session<>nil then
       if ClientSession2.Session.UserID = Header.Recepient then // for connect request only
        if TMsgClientSession(ClientSession2.Session).Direct then
         if ClientSession2.Session.Connected then
          if (ClientSession2.Session.SessionID = INVALID_SESSION_ID) then // special listening session
           begin
            Session := ClientSession2.Session;
            Session2Found := True;
            inc(ClientSession2.Status);
            EnterCSect(ClientSession2.FCSect);
            break;
           end;
    end;
  finally
   FManager.FSessions.UnlockList;
  end;
  if not Session2Found then
   begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> client session not found!!!');
{$ENDIF}
    Exit;
   end;
// does connection already exist?
  SessionFound := False;
  Sessions := FManager.FSessions.LockList;
  try
   for i:=0 to Sessions.Count-1 do
    begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : Check session '+IntToStr(i)+' of '+IntToStr(Sessions.Count));
{$ENDIF}
     ClientSession := Sessions.Items[i];
     if (ClientSession.ServerSessionID = Header.SessionID)
     and (ClientSession.RemoteConnectionID = Header.ConnectionID)
     then
       if (ClientSession.Session = nil) // just added, not finished
        then SessionFound := True
       else if (ClientSession.Session.SessionID = INVALID_SESSION_ID) // buffer received, not finished
        then SessionFound := True
       else if (ClientSession.Session.ConnectParams.ServerID = Header.Sender) // not first connect - session already exist
        then
          begin
           SessionFound := True;
           GetClientConnection;
          end;
       if SessionFound then
        begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : Found: @session='+IntToHex(Integer(ClientSession),6)+', Client SessionID='+IntToStr(ClientSession.ServerSessionID));
{$ENDIF}
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
if ClientSession.Session <> nil then
aaWriteToLog('TMsgSendingThread> : Found: @session='+IntToHex(Integer(ClientSession),6)+', Server SessionID='+IntToStr(ClientSession.Session.SessionID));
{$ENDIF}
         break;
        end;
    end;
  finally
   FManager.FSessions.UnlockList;
  end;
  if not SessionFound then
   begin // First connect
// new ClientSession
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : New ClientSession');
{$ENDIF}
    GetClientConnection;
    if not ConnectionFound then
      Exit;
    New(ClientSession);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('new direct session: @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
    ClientSession.Session := nil;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> InitCSect...');
{$ENDIF}
    SessionFound := True;
    ClientSession.Status := MsgInUse;
    InitCSect(ClientSession.FCSect,'ClientSession, direct connect to '+NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort),true);
    EnterCSect(ClientSession.FCSect);
    FManager.FSessions.Add(ClientSession);
    ClientSession.AnswerTime := 0;
    ClientSession.AnswerStatus := MsgNo;
    ClientSession.RemoteConnectionID := Header.ConnectionID;
    ClientSession.ConnectionID := ClientConnection.ConnectionID;
    ClientSession.ServerSessionID := Header.SessionID;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> :   New: @session='+IntToHex(Integer(ClientSession),6)+', Client SessionID='+IntToStr(ClientSession.ServerSessionID));
{$ENDIF}
    ClientSession.ControlCode := MsgExecute;
    ClientSession.PacketIDsToResend := TMsgThreadIntArray.Create;
    ClientSession.MsgPacketIDsToResend := TMsgThreadIntArray.Create;
    ClientSession.ResendRequestThread := nil;
// Create new packets list
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : Packets list create');
{$ENDIF}
    ClientSession.Packets := TMsgList.Create;
    ClientSession.Packets.Capacity := MsgDefaultPacketsInRequest; // Allocate some place in list
// add new session to list
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : add new session to list');
{$ENDIF}
   end
  else // not first connect - reset and resend connection info
   begin
    // Is buffer receiving now?
    if (ClientSession.AnswerStatus = MsgStart)
    or (ClientSession.AnswerStatus = MsgFull)
    or (ClientSession.Session = nil) // just added, not finished
    or (ClientSession.Session.SessionID = INVALID_SESSION_ID) // buffer received, not finished
    then
     begin
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TMsgSendingThread> : Buffer is receiving now');
  {$ENDIF}
      Exit;
     end;
    if (ClientSession.ControlCode <> MsgExecute) then
     begin
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TMsgSendingThread> : Not Execute - Terminate ListeningThread, ClientSession.ControlCode='+IntToStr(ClientSession.ControlCode));
  {$ENDIF}
      Exit;
     end;
    if (ClientSession.CurrentRequestID > Header.CurrentRequestID) then // packet from old connection request
     begin
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TMsgSendingThread> : OldPacket - SendAckn');
  {$ENDIF}
//        Header.Recepient := Header.Sender;
      if ClientSession.Session<>nil then
        begin
         if ClientConnection = nil then
           GetClientConnection;
         TMsgClientConnectionManager(FManager).SendConnectAckn(ClientSession, ClientConnection, Header.CurrentRequestID);
        end;
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TMsgSendingThread> : OldPacket - Terminate ListeningThread');
  {$ENDIF}
      Exit;
     end;
    ClientSession.PacketIDsToResend.SetSize(0);
  (*
  // Delete old packets from list
    Packets := ClientSession.Packets.LockList;
    try
     for i:=0 to Packets.Count-1 do
       Packets.Items[i] := nil;
     Packets.Count := 0;
    finally
     ClientSession.Packets.UnlockList;
    end;
    Packets := ClientSession.MsgPackets.LockList;
    try
     for i:=0 to Packets.Count-1 do
       Packets.Items[i] := nil;
     Packets.Count := 0;
    finally
     ClientSession.Packets.UnlockList;
    end;
  *)
   end;
  // Put this first packet
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : New Packet');
{$ENDIF}
  Packet := NetworkPacket.Packet;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> : BufferSize='+IntToStr(NetworkPacket.Packet.BufferSize));
aaWriteToLog('TMsgSendingThread> : Packet add');
{$ENDIF}
  ClientSession2.Packets.Add(Packet);
  PacketAdded := True;
  ClientSession.CurrentRequestID := Header.CurrentRequestID;
  ClientSession.ClientMessageID := 0;
//  ClientSession.ServerMessageID := 0;
  Session.FConnectParams.RemoteHost := NetworkPacket.FromHost;
  Session.FConnectParams.RemotePort := NetworkPacket.FromPort;
  Session.FConnectParams.ServerID := Header.Sender; // Allow following communication
// Get connection parameters
  if Header.ControlCode=MsgConnect+MsgLastPacket then
   ClientSession2.AnswerStatus := MsgFull;
 finally
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> Free packet...');
{$ENDIF}
  if SessionFound then
   begin
    LeaveCSect(ClientSession.FCSect);
    dec(ClientSession.Status);
   end;
  if Session2Found then
   begin
    LeaveCSect(ClientSession2.FCSect);
    dec(ClientSession2.Status);
   end;
  if not PacketAdded then
   begin // kill packet
     if NetworkPacket.Packet.Buffer <> nil then
       MemoryManager.FreeAndNilMem(NetworkPacket.Packet.Buffer);
     Dispose(NetworkPacket.Packet);
   end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> connect user from '+NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort));
{$ENDIF}
  Host := NetworkPacket.FromHost;
  Port := NetworkPacket.FromPort;
  Dispose(NetworkPacket);
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> Freed!');
{$ENDIF}
 end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> enter CS...');
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> enter CS2...');
{$ENDIF}
  inc(ClientSession2.Status);
  EnterCSect(ClientSession2.FCSect);
  try
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> receive buffer...');
{$ENDIF}
   TMsgClientConnectionManager(FManager).ReceiveBuffer(ClientSession2.Session, Buf, BufSize, True);
  finally
   LeaveCSect(ClientSession2.FCSect);
   dec(ClientSession2.Status);
  end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> connection - buffer received');
{$ENDIF}
  ClientSession.Session := Session;
  Move(Buf^, RemoteUserID, SizeOf(RemoteUserID));
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> UserID = '+IntToStr(TMsgClientSession(Session).FUserID));
{$ENDIF}
  inc(Buf, SizeOf(RemoteUserID));
  try
    Move(PAnsiChar(Buf + SizeOf(TMsgConnectionParams))^, AuBufSize, SizeOf(AuBufSize));
    if not TMsgClientConnectionManager(FManager).IsAuthorizationBufferValid(
              Session.ConnectParams.CryptoInfo,
              PAnsiChar(Buf + SizeOf(TMsgConnectionParams) + SizeOf(AuBufSize)),
              AuBufSize
                                               )
    then
     begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> authorization buffer is not valid');
{$ENDIF}
      TMsgClientConnectionManager(FManager).SendDisconnectRequest(ClientSession, False);
      FManager.FSessions.Remove(ClientSession);
      TMsgClientConnectionManager(FManager).DeleteSession(ClientSession);
      Exit;
     end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> authorization buffer is valid');
{$ENDIF}
// Get ConnectParams
    ConnectionParams := PMsgConnectionParams(Buf);
// Get client Application name
    SetLength(Application, BufSize-SizeOf(TMsgConnectionParams)
      -SizeOf(AuBufSize)-AuBufSize-1-SizeOf(TMsgClientSession(Session).FUserID));
    StrCopy(PAnsiChar(Application), Buf+SizeOf(TMsgConnectionParams)+SizeOf(AuBufSize)+AuBufSize);
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> Application = "'+Application+'"');
{$ENDIF}
  finally
   dec(Buf, SizeOf(RemoteUserID));
  end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> connect user...');
{$ENDIF}
  ClientSession.Session := Session.ConnectUser(RemoteUserID, Host, Port);
  if ClientSession.Session = nil then
   begin
    ClientSession.Session := Session;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> not connected, send disconnect...');
{$ENDIF}
    TMsgClientConnectionManager(FManager).SendDisconnectRequest(ClientSession, False);
    FManager.FSessions.Remove(ClientSession);
    TMsgClientConnectionManager(FManager).DeleteSession(ClientSession);
    Exit;
   end
  else
   begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> user connected');
{$ENDIF}
    ClientSession.AnswerStatus := MsgStart;
  //      ClientSession.Session.FConnectParams.CryptoInfo := TMsgServer(FManager.FServer).CryptoParams.GetCryptoParams;
    ClientSession.Session.FConnectParams.RemoteHost := Host;
    ClientSession.Session.FConnectParams.RemotePort := Port;
    ClientSession.Session.FConnectParams.ServerID := Session.FConnectParams.ServerID;
   // Set SessionID
    EnterCSect(FManager.FCSect);
    ClientSession.Session.SessionID := FManager.FSessionID;
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TMsgSendingThread> :   New: @session='+IntToHex(Integer(ClientSession),6)+', Server SessionID='+IntToStr(ClientSession.Session.SessionID));
  {$ENDIF}
    dec(FManager.FSessionID);
    if FManager.FSessionID = INVALID_SESSION_ID then
      dec(FManager.FSessionID);
    LeaveCSect(FManager.FCSect);
    if ClientSession.Session.FConnectParams.UseServerSettings then
     begin
      ClientSession.Session.FConnectParams.PacketSize := ConnectionParams.PacketSize;
      ClientSession.Session.FConnectParams.CompressionAlgorithm := ConnectionParams.CompressionAlgorithm;
      ClientSession.Session.FConnectParams.CompressionMode := ConnectionParams.CompressionMode;
     end;
  //      Header.Recepient := Header.Sender;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> send ConnectACKN...');
{$ENDIF}
    if ClientConnection = nil then
      GetClientConnection;
    TMsgClientConnectionManager(FManager).SendConnectAckn(ClientSession, ClientConnection);
    inc(ClientSession.CurrentRequestID);
   end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> free...');
{$ENDIF}
 finally
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> Finishing...');
{$ENDIF}
  if SessionFound then
   begin
    LeaveCSect(ClientSession.FCSect);
    dec(ClientSession.Status);
   end;
  MemoryManager.FreeAndNilMem(Buf);
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> Buffer is freed!');
{$ENDIF}
 end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TMsgSendingThread> OK - connected');
{$ENDIF}
end; // Connect


//------------------------------------------------------------------------------
// CommandReceived
//------------------------------------------------------------------------------
procedure TMsgSendingThread.ExecuteReceivedCommand(
                                ClientSession:        PMsgClntSession;
                                Command:              Integer
                                                                 );
var
  Error:        AnsiString;
  Buf:          PAnsiChar;
  BufSize:      Integer;
begin
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('CommandReceived> START');
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
  ClientSession.AnswerStatus := MsgFull;
  if ClientSession.ControlCode = MsgExecute then
    ClientSession.ControlCode := MsgSuspend;
  try // except
   try
    TMsgClientConnectionManager(FManager).ReceiveBuffer(ClientSession.Session, Buf, BufSize);
   except
    on E:Exception do
     raise EMsgException.Create(40506, ErrorRCannotReceive+E.Message);
   end;
    begin
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('Client started new request #'+IntToStr(ClientSession.CurrentRequestID));
aaWriteBufferToLog(Buf, BufSize);
{$ENDIF}
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgClientSessionThread.Execute - ExecuteReceivedCommand - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
    try
     dec(ClientSession.CurrentRequestID);
     LeaveCSect(ClientSession.FCSect); // needs to send answer
     TMsgClientSession(ClientSession.Session).ExecuteReceivedCommand(Buf, BufSize);
     EnterCSect(ClientSession.FCSect);
     inc(ClientSession.CurrentRequestID);
     if ClientSession.ControlCode = MsgSuspend then
       ClientSession.ControlCode := MsgExecute;
    except
     on E:Exception do
       raise EMsgException.Create(40513,'Command section - '+ErrorRSessionReceiveData+E.Message);
    end;
   end;
 except
  on E: EMsgException do
   begin
    ClientSession.AnswerStatus := MsgNo;
    Error:=
                  ErrorRClient+ErrorRPacketProcessorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ClientSession <> nil)
    or (ClientSession.Session <> nil)
    then
      TMsgNetworkSession(ClientSession.Session).DoOnError(MsgClientPacketProcessorThreadCommand,E.NativeError,Error);
   end;
  on E: Exception do
   begin
    ClientSession.AnswerStatus := MsgNo;
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('ERROR: ' + Error + ErrorRExecute + 'CommandReceived> ' + E.Message);
{$ENDIF}
    TMsgNetworkSession(ClientSession.Session).DoOnError(MsgClientPacketProcessorThreadCommand,-1,Error);
   end;
 end;
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('CommandReceived> FINISHED');
{$ENDIF}
{
              case Command of
               MsgInitProgressSend:
                ClientSession.Session
              end;
}
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
 end;
end;
{$ENDIF MsgCommunicator}


//------------------------------------------------------------------------------
// Echo
//------------------------------------------------------------------------------
procedure TMsgSendingThread.Echo;
var
  Buf:                  PAnsiChar;
  BufSize:              Integer;
begin
  TMsgClientConnectionManager(FManager).ReceiveBuffer(TMsgClientSession(Farg1),Buf,BufSize);
  TMsgClientConnectionManager(FManager).SendBuffer(TMsgClientSession(Farg1),Buf,BufSize,Farg2);
  MemoryManager.FreeAndNilMem(Buf);
end; // Echo

//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgSendingThread.Execute;
begin
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Execute> START');
aaWriteToLog(IntToStr(Integer(FMethod))+' = Method');
aaWriteToLog('0 Connect');
{$IFDEF MsgCommunicator}
aaWriteToLog(IntToStr(Integer(@TMsgSendingThread.ExecuteReceivedCommand))+' ExecuteReceivedCommand');
{$ENDIF}
aaWriteToLog(IntToStr(Integer(@TMsgSendingThread.Echo))+' Echo');
aaWriteToLog(IntToStr(Integer(@TMsgClientConnectionManager.SendAcknowledgement))+' SendAcknowledgement');
aaWriteToLog(IntToStr(Integer(@TMsgClientConnectionManager.SendDisconnectRequest))+' SendDisconnectRequest');
aaWriteToLog(IntToStr(Integer(@TMsgClientConnectionManager.PacketResendRequest))+' PacketResendRequest');
aaWriteToLog(IntToStr(Integer(@TMsgClientConnectionManager.SendPing))+' SendPing');
{$ENDIF}
 try // except
{$IFDEF MsgCommunicator}
  if FMethod = nil then
    Connect(PMsgNetworkPacket(Farg1))
  else
  if FMethod = @TMsgSendingThread.ExecuteReceivedCommand then
    ExecuteReceivedCommand(PMsgClntSession(Farg1),Farg2)
  else
{$ENDIF}
  if FMethod = @TMsgSendingThread.Echo then
    Echo
  else
  if FMethod = @TMsgClientConnectionManager.SendAcknowledgement then
    TMsgClientConnectionManager(FManager).SendAcknowledgement(PMsgClntSession(Farg1),Boolean(Farg2),Farg3)
  else
  if FMethod = @TMsgClientConnectionManager.SendDisconnectRequest then
    TMsgClientConnectionManager(FManager).SendDisconnectRequest(PMsgClntSession(Farg1),Boolean(Farg2))
  else
  if FMethod = @TMsgClientConnectionManager.PacketResendRequest then
    TMsgClientConnectionManager(FManager).PacketResendRequest(PAnsiChar(Farg1),TMsgNetwork(Pointer(Farg2)),AnsiString(PAnsiChar(Farg3)),Farg4)
  else
  if FMethod = @TMsgClientConnectionManager.SendPing then
    TMsgClientConnectionManager(FManager).SendPing(PMsgClntSession(Farg1))
  else
  if FMethod = @TMsgServerSession.ReceiveMessage then
   begin
    inc(PMsgSrvrSession(Farg4).MsgThreadCount);
{$IFDEF LOG_SERVER_MESSAGE_THREAD_CREATE}
aaWriteToLog('process message in new thread start,  threads count = '+IntToStr(PMsgSrvrSession(Farg4).MsgThreadCount));
{$ENDIF}
    TMsgServerSession(Farg1).ReceiveMessage(PAnsiChar(Farg2), Farg3);
    dec(PMsgSrvrSession(Farg4).MsgThreadCount);
{$IFDEF LOG_SERVER_MESSAGE_THREAD_CREATE}
aaWriteToLog('process message in new thread finish, threads count = '+IntToStr(PMsgSrvrSession(Farg4).MsgThreadCount));
{$ENDIF}
   end
  else
   begin
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Execute> Unknown Method = '+IntToStr(Integer(FMethod))+', '+IntToHex(Integer(FMethod),8));
{$ENDIF}
   end;
//    FMethod(Farg1,Farg2,Farg3,Farg4,Farg5)
 except
  on E: Exception do
   begin
    try
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
    except
    end;
   end;
 end;
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TMsgSendingThread.Execute> FINISH');
{$ENDIF}
end; // Execute

// TMsgSendingThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgResendRequestThread.Create(
                       Manager:           TMsgBaseConnectionManager;
                       Queue:             TMsgThreadList;
                       Command:           Boolean = True
                                            );
begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('RESENDING THREAD - Create');
{$ENDIF}
 try
  Manager.IncThreadCount;
  FManager := Manager;
  FQueue := Queue;
  FCommand := Command;
  if FManager is TMsgClientConnectionManager then
    FCLient := True
  else
    FCLient := False;
  Error :=  ErrorRClient;
  if Command then
    Error :=  Error + ErrorRCommandResendRequestThread
  else
    Error :=  Error + ErrorRMessageResendRequestThread;
  Error := Error + IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle));
  inherited Create(False);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRCreate + E.Message);
{$ENDIF}
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgResendRequestThread.Destroy;
begin
try
 try
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread.Destroy');
{$ENDIF}
  if FCommand then
    FManager.FCommandResendRequestThread := nil
  else
    FManager.FMessageResendRequestThread := nil;
  inherited Destroy;
  FManager.DecThreadCount;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread.Destroy - FINISHED');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRDestroy + E.Message);
{$ENDIF}
   end;
 end;
finally
  if not Terminated then
  if FRecreate then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread.Destroy - recreate...');
{$ENDIF}
    sleep(MsgThreadRecreateSleep);
    if not Terminated then
    if FCommand then
     begin
      if not FClient then // Server only
        FManager.FCommandResendRequestThread := TMsgResendRequestThread.Create(FManager,FQueue,FCommand);
     end
    else
      FManager.FMessageResendRequestThread := TMsgResendRequestThread.Create(FManager,FQueue,FCommand);
   end;
end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgResendRequestThread.Execute;
var
  queue:              TMsgList;
  recvItem:           PMsgRecvItem;
  Delay2,
  i, j,
  Delay:              Integer;
  Network:            TMsgNetwork;
  Packets:            TMsgList;
  Packet:             PMsgPacket;
  PacketIDs:          TMsgIntegerArray;
  headerReady:        Boolean;
  AllPacketsReceived: Boolean;
  Header:             TMsgPacketHeader;

function IsRequestNeeded(recvItem: PMsgRecvItem): Boolean;
begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('RESENDING THREAD - IsRequestNeeded?');
{$ENDIF}
  Result := True;
  if recvItem.RecvStatus <> MsgNotFull then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread> RecvStatus <> MsgNotFull');
{$ENDIF}
    Result := False;
    Exit;
   end;
(*
  if ServerSession.MsgControlCode = MsgTerminate then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread> ServerSession.MsgControlCode = MsgTerminate');
{$ENDIF}
    Result := False;
    Exit;
   end;
*)
end;

begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread> START');
{$ENDIF}
 try
  PacketIDs := TMsgIntegerArray.Create;
  try
   try
    j := -1;
    if FClient then
     begin
      Delay := MsgRequestDelay;
      Delay2 := 0; // MsgReceiveSleep;
     end
    else
     begin
      if FManager.FServer = nil then
        Delay := 1 + (MsgServerRequestDelay div (TMsgServerConnectionManager(FManager).SessionsCount+1))
      else
        Delay := 1 + (TMsgServer(FManager.FServer).NetworkSettings.ServerRequestDelay div (TMsgServerConnectionManager(FManager).SessionsCount+1));
      Delay2 := TMsgServer(FManager.FServer).NetworkSettings.ServerReceiveSleep;
  // prepare PacketHeader
      Header.Signature := MsgServerPacketSign;
      Header.Sender := TMsgServerConnectionManager(FManager).FNetwork.FLocalClient;
      Header.ControlCode := MsgMessagePacketResendRequest;
      Network := TMsgServerConnectionManager(FManager).FNetwork;
     end;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread> Delay  ='+IntToStr(Delay));
aaWriteToLog('TMsgResendRequestThread> Delay2 ='+IntToStr(Delay2));
{$ENDIF}
    repeat
     if Terminated then
      begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> Terminated in queue loop');
  {$ENDIF}
       Exit;
      end;
     sleep(Delay);
  // next item
     inc(j);
     queue := FQueue.LockList;
     try
      if j >= queue.Count then
       begin
        j := -1;
        continue;
       end;
      if j < 0 then
        j := 0;
      recvItem := queue.Items[j];
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread> j = '+IntToStr(Integer(j)));
aaWriteToLog('TMsgResendRequestThread> recvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
     finally
      FQueue.UnlockList;
     end;
     if not TMsgClientConnectionManager(FManager).IsSessionExisting(PMsgClntSession(recvItem.Session)) then
      begin
    {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
    aaWriteToLog('TMsgResendRequestThread> session is not existing - remove...');
    {$ENDIF}
       FQueue.Remove(recvItem);
       dec(j);
       continue;
      end;
     try // session entered CS
       if FClient then
        begin
         Delay := PMsgClntSession(recvItem.Session).Session.ConnectParams.RequestDelay;
  //       Delay2 := PMsgClntSession(recvItem.Session).Session.ConnectParams.ReceiveSleep;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgResendRequestThread> Delay  ='+IntToStr(Delay));
{$ENDIF}
        end;
       if not (IsRequestNeeded(recvItem)) then
        begin
    {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
    aaWriteToLog('TMsgResendRequestThread> not needed - next');
    {$ENDIF}
         continue;
        end;
    {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
    aaWriteToLog('TMsgResendRequestThread> prepare...');
    {$ENDIF}
    // Make PacketHeader
        if FClient then
         begin
          Network := recvItem.Network;
          headerReady := false;
         end
        else
         begin
          Header.Recepient := PMsgSrvrSession(recvItem.Session).RemoteClientID;
          Header.ConnectionID := PMsgSrvrSession(recvItem.Session).ConnectionID;
          Header.SessionID := PMsgSrvrSession(recvItem.Session).Session.SessionID;
          Header.PacketID := 0;
          Header.CurrentRequestID := PMsgSrvrSession(recvItem.Session).ClientMessageID;
          headerReady := true;
         end;
    // Search absent packet and send request to resend it
        AllPacketsReceived := True;
        Packets := recvItem.Packets.LockList;
        try
         PacketIDs.SetSize(0);
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> Packets.Count = '+IntToStr(Packets.Count));
  {$ENDIF}
         for i:=0 to Packets.Count-1 do
          begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> i = '+IntToStr(i));
  {$ENDIF}
           Packet := Packets.Items[i];
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> Packet = '+IntToStr(Integer(Packet)));
  {$ENDIF}
           if (Packet = nil) then
            begin
             PacketIDs.Append(i);
             AllPacketsReceived := False;
            end
           else
             if FClient then
              if not headerReady then
               if (Packet.BufferSize >= SizeOf(TMsgPacketHeader)) then
               if (Packet.Buffer <> nil) then
                begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> prepare header...');
  {$ENDIF}
                 Move(Packet.Buffer^,Header,SizeOf(TMsgPacketHeader));
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread>header ready');
  {$ENDIF}
                 headerReady := true;
                end;
          end;
        finally
         recvItem.Packets.UnlockList;
        end;
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> PacketsCount='+IntToStr(PacketIDs.ItemCount));
  {$ENDIF}
        if not AllPacketsReceived then
          if headerReady then
            for i:=0 to PacketIDs.ItemCount-1 do
             begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> i='+IntToStr(i));
  {$ENDIF}
              if Terminated then
               begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> Terminated in packets loop');
  {$ENDIF}
                Exit;
               end;
  // send request
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> PacketMsgResendRequest, i='+IntToStr(i));
  {$ENDIF}
              if FClient then
                TMsgClientConnectionManager(FManager).PacketResendRequest(@Header, Network, recvItem.RemoteHost, recvItem.RemotePort, PacketIDs.Items[i], True)
              else
                TMsgServerConnectionManager(FManager).PacketResendRequest(@Header, Network, recvItem.RemoteHost, recvItem.RemotePort, PacketIDs.Items[i], True);
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> Packet has been requested');
  {$ENDIF}
              Sleep(Delay2);
             end; // next packet for this item
     finally
      LeaveCSect(PMsgClntSession(recvItem.Session).FCsect);
      dec(PMsgClntSession(RecvItem.Session).Status);
     end;
    until False; // Get new incoming item
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TMsgResendRequestThread> FINISH');
  {$ENDIF}
   except
    on E: Exception do
     begin
      FRecreate := True;
  {$IFDEF DEBUG_ONERROR}
  aaWriteToLog('ERROR: ' + Error + ErrorRExecute + E.Message);
  {$ENDIF}
     end;
   end;
  finally
   PacketIDs.Free;
  end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
   end;
 end;
end;// Execute
// TMsgResendRequestThread


{$IFDEF CLIENT_VERSION}

////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgClientConnectionManager.Create;
begin
 try
  InitCSect(FCSect,'TMsgClientConnectionManager',false);
  inherited Create;
  FListenerStoped := False;
  FSessions := TMsgThreadList.Create('ClientConnectionManager.FSessions',true);
  FConnections := TMsgThreadList.Create;
  FSessionID := MAXINT;
  FConnectionID := -MAXINT;
  FApplication := '';
  FApplication := ParamStr(0);
  if FApplication = '' then
    FApplication := 'UNKNOWN';
  ThreadCount := 0;
{$IFDEF CONNECTION_TEST}
//  FOtherManager :=
{$ELSE}
 {$IFDEF NETWORK_TEST}
//  FOtherManager :=
  FClient := True;
 {$ENDIF}
{$ENDIF}
  FReceiveTimeOut := MsgReceiveTimeOut;
  FPacketQueue := TMsgThreadList.Create;
  FPacketProcessorThread := TMsgClientPacketProcessorThread.Create(self);
(*
// for server
  FCommandQueue := TMsgThreadList.Create;
//  FCommandProcessorThread := TMsgCommandProcessorThread.Create(self);
  FCommandProcessorThread := TMsgQueueProcessorThread.Create(self,FCommandQueue);
{$IFDEF MsgCommunicator}
  FCommandProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.4);
{$ELSE}
  FCommandProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.9);
{$ENDIF}
*)
  FCommandThreads := nil; // for client: stored in TVsgClntSession
  FMessageThreads := TMsgThreadList.Create;
  FMessageQueue := TMsgThreadList.Create('message queue',false);
  FSendMessages := TMsgThreadList.Create;
  FRecvMessages := TMsgThreadList.Create;
  FMessageProcessorThread := TMsgQueueProcessorThread.Create(self,FMessageQueue,false);
{$IFDEF MsgCommunicator}
  FMessageProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.9);
{$ELSE}
  FMessageProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.2);
{$ENDIF}
  FMessageProcessorThread.FCommand := False;
// for server
//  FCommandResendRequestThread := TMsgResendRequestThread.Create(self,FCommandQueue);
  FCommandResendRequestThread := nil;
  FMessageResendRequestThread := TMsgResendRequestThread.Create(self,FMessageQueue,false);
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.Create> Application: '+FApplication);
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TMsgClientConnectionManager.Create - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgClientConnectionManager.Destroy;
begin
 try
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> Application: '+FApplication);
{$ENDIF}
  DisconnectAll;
  FListenerStoped := True;

{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> terminate PacketProcessorThread');
{$ENDIF}
  CloseThread(@FPacketProcessorThread,MsgClientConnectionManager,ErrorRPacketProcessorThread);
//  CloseThread(@FCommandProcessorThread,MsgClientConnectionManager,ErrorRCommandProcessorThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> terminate MessageProcessorThread');
{$ENDIF}
  CloseThread(@FMessageProcessorThread,MsgClientConnectionManager,ErrorRMessageProcessorThread);
//  CloseThread(@FCommandResendRequestThread,MsgClientConnectionManager,ErrorRCommandResendRequestThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> terminate MessageResendRequestThread');
{$ENDIF}
  CloseThread(@FMessageResendRequestThread,MsgClientConnectionManager,ErrorRMessageResendRequestThread);

{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> terminate Message Threads');
{$ENDIF}
  CloseThreads(FMessageThreads);
  CloseThreads(FCommandThreads);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> terminate Sending Threads - base manager...');
{$ENDIF}
  inherited Destroy;
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('Threads left:');
if FMessageThreads <> nil then
aaWriteToLog('Message threads: '+IntToStr(FMessageThreads.Count));
if FCommandThreads <> nil then
aaWriteToLog('Command threads: '+IntToStr(FCommandThreads.Count));
if FSendingThreads <> nil then
aaWriteToLog('Sending threads: '+IntToStr(FSendingThreads.Count));
aaWriteToLog('Total ThreadsCount = '+IntToStr(ThreadCount));
{$ENDIF}

{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> free thread lists...');
{$ENDIF}
try
  FPacketQueue.Free;
//  FCommandQueue.Free;
  FMessageQueue.Free;
  FSendMessages.Free;
  FRecvMessages.Free;
except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TMsgClientConnectionManager.Destroy - free thread lists error: '+E.Message);
    end;
{$ENDIF}
end;

{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy> free connections and sessions lists...');
{$ENDIF}
 EnterCSect(FCSect);
 try
  FConnections.Free;
  FSessions.Free;
  FSessions := nil;
 finally
  LeaveCSect(FCSect);
  DeleteCSect(FCSect);
 end;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.Destroy - FINISHED');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TMsgClientConnectionManager.Destroy - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Destroy


//------------------------------------------------------------------------------
// IsSessionExisting: search for client session and enter CSect to block its using
//------------------------------------------------------------------------------
function TMsgClientConnectionManager.IsSessionExisting(ClientSession: PMsgClntSession): Boolean;
var
  Sessions:     TMsgList;
  i:            Integer;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.IsSessionExisting> START');
{$ENDIF}
  Result := False;
  Sessions := FSessions.LockList;
  try
   for i := Sessions.Count-1 downto 0 do
    begin
     if ClientSession = Sessions.Items[i] then
       begin
        Result := True;
        inc(ClientSession.Status);
        EnterCSect(ClientSession.FCsect);
        break;
       end;
    end;
  finally
   FSessions.UnlockList;
  end;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.IsSessionExisting> FINISH');
{$ENDIF}
end;// IsSessionExisting


//------------------------------------------------------------------------------
// PacketResendRequest
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TMsgNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False
                                 );
var
  Header:          PMsgPacketHeader;
begin
  Header := Pointer(Buffer);
  if Msg then
    Header.ControlCode := MsgMessagePacketResendRequest
  else
    Header.ControlCode := MsgPacketResendRequest;
  Header.Signature := MsgClientPacketSign;
  if (PacketID >= 0) then
    Header.PacketID := PacketID
  else
    Header.Recepient := Header.Sender;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgClientConnectionManager.PacketResendRequest> asks to resend packet # '+IntToStr(Header.PacketID));
{$ENDIF}
  EnterCSect(Network.FCSect^);
  try
   Network.RemoteHost := RemoteHost;
   Network.RemotePort := RemotePort;
   Network.SendBuffer(Buffer, SizeOf(TMsgPacketHeader));
  finally
   LeaveCSect(Network.FCSect^);
  end;
end;// PacketResendRequest


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.OnDisconnect(
                               FNetwork:      TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
var
  Sessions:             TMsgList;
  Session:              TMsgComBaseSession;
  ClientSession:        PMsgClntSession;
//  Connections:          TMsgList;
//  ClientConnection:     PMsgClntConnection;
  i, j:                 Integer;
//  Found:                Boolean;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.OnDisconnect - START');
{$ENDIF}
{
  Connections:=FConnections.LockList;
  try
   j := Connections.Count-1;
   for i:=0 to j do
    begin
     ClientConnection := Connections.Items[i];
     if ClientConnection.Network = FNetwork then
      begin
       Found := True;
       break;
      end;
    end;
  finally
   FConnections.UnlockList;
  end;
  if not Found then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(FNetwork)]);
  Found := False;
}
  Sessions:=FSessions.LockList;
  try
   j := Sessions.Count-1;
   for i:=j downto 0 do
    begin
     ClientSession := Sessions.Items[i];
//     if ClientSession.ConnectionID = ClientConnection.ConnectionID then
     if  (FromHost = ClientSession.Session.ConnectParams.RemoteHost)
     and (FromPort = ClientSession.Session.ConnectParams.RemotePort)
     then
      begin
//       Found := True;
       Session := ClientSession.Session;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.OnDisconnect - DoDisconnect');
{$ENDIF}
       FSessions.UnlockList;
       DoDisconnect(Session);
       Sessions := FSessions.LockList;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.OnDisconnect - Session.OnDisconnect');
{$ENDIF}
       if Session<>nil then
         TMsgClientSession(Session).DoCloseSessionOnNetworkError;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.OnDisconnect - Session.OnDisconnect FINISHED');
{$ENDIF}
{$IFDEF MsgCommunicator}
       if Session<>TMsgClient(TMsgClientSession(Session).FOwnerComponent).FDefaultSession then
          Session.Free;
 {$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.OnDisconnect - Session Freed!');
 {$ENDIF}
{$ENDIF}
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
{
  if not Found then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(ClientConnection.ConnectionID)]);
}
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.OnDisconnect - FINISH');
{$ENDIF}
end; // OnDisconnect

(*
//------------------------------------------------------------------------------
// IsExistingPacket
//------------------------------------------------------------------------------
function TMsgClientConnectionManager.IsExistingPacket: Boolean;
var
 i:                    Integer;
 Packets:              TMsgList;
 NetworkPacket:        PMsgNetworkPacket;
begin
 Result := False;
 Packets := FIncomingPackets.LockList;
 try
  for i:=Packets.Count-1 downto 0 do
   begin
     NetworkPacket := Packets.Items[i];
//     if NetworkPacket.Network = Network then
//     if NetworkPacket.FromHost = FromHost then
//     if NetworkPacket.FromPort = FromPort then
     if NetworkPacket.Packet.BufferSize = BufferSize then
     if CompareMem(NetworkPacket.Packet.Buffer, Buffer, SizeOf(TMsgPacketHeader)) then
      begin
       Result := True;
       break;
      end;
   end; // for
 finally
  FIncomingPackets.UnlockList;
 end;
end; // IsExistingPacket
*)

//------------------------------------------------------------------------------
// NetworkListener
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
procedure AddPacket;
var
  NetworkPacket:     PMsgNetworkPacket;
  Packet:            PMsgPacket;
begin
  New(NetworkPacket);
  NetworkPacket.Network := Network;
  NetworkPacket.FromHost := FromHost;
  NetworkPacket.FromPort := FromPort;
  New(Packet);
  Packet.Buffer := Buffer;
  Packet.BufferSize := BufferSize;
  NetworkPacket.Packet := Packet;
  FPacketQueue.Add(NetworkPacket);
{$IFDEF LOG_CLIENT_RESENDING}
if PMsgPacketHeader(Buffer).ControlCode = MsgPacketResendRequest then
aaWriteToLog('NetworkListener> Added Resend Request Packet # '+IntToStr(PMsgPacketHeader(Buffer).PacketID));
{$ENDIF}
end; // AddPacket

begin // NetworkListener
{$IFDEF LOG_CLIENT_RECV}
aaWriteToLog('NetworkListener --------------------------------');
aaWriteToLog('Header.ConnectionID = '+IntToStr(PMsgPacketHeader(Buffer).ConnectionID));
aaWriteToLog('Header.SessionID    = '+IntToStr(PMsgPacketHeader(Buffer).SessionID));
aaWriteToLog('Header.ControlCode  = '+IntToStr(PMsgPacketHeader(Buffer).ControlCode));
aaWriteToLog('NetworkListener --------------------------------');
{$ENDIF}
  if not FListenerStoped then
//    if not IsExistingPacket then
     begin
      AddPacket;
      Exit;
     end;
  MemoryManager.FreeAndNilMem(Buffer);
end;// NetworkListener

(*
procedure TMsgClientConnectionManager.NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
var
  StartTime:        Cardinal;
  Error:            AnsiString;
  Sessions:         TMsgList;
  ClientSession:    PMsgClntSession;
begin
  if not FListenerStoped then
   begin
    StartTime := GetTickCount;
    while ((GetTickCount-StartTime) < FReceiveTimeOut) do
     begin
      if ThreadCount<FMaxThreadCount then
       begin
        TMsgClientPacketProcessorThread.Create(self, Buffer, BufferSize, Network, FromHost, FromPort);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgClientConnectionManager.NetworkListener> Listener Thread Created ! - '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgClientConnectionManager.NetworkListener> Threads Count = '+IntToStr(ThreadCount));
{$ENDIF}
        Exit;
       end;
      sleep(0);
     end;
     Error :=
                  ErrorRCannotCreateListenerThread+
                  IntToStr(FMaxThreadCount);
     Sessions := FSessions.LockList;
     try
       if Sessions.Count > 0 then
        begin
         ClientSession := Sessions.Items[0];
         if ClientSession.Session <> nil then
           TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgServerListenerThread,40516,
                  Error)
         else
          begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
        end;
      finally
       FSessions.UnlockList;
      end;
   end;
  MemoryManager.FreeAndNilMem(Buffer);
end;// NetworkListener
*)

(*
//------------------------------------------------------------------------------
// ReceiveMessage
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.ReceiveMessage(
                          ClientSession:        PMsgClntSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
var
  i:                    Integer;
  Packet:               PMsgPacket;
  pBuf:                 PAnsiChar;
  StartTime:            Cardinal;
begin
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> Start');
{$ENDIF}
 try
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('CLIENT has started to receive message');
{$ENDIF}
  EnterCSect(FCSect);
  inc(ClientSession.Status);
  LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> Wait for starting...');
{$ENDIF}
  if ClientSession.MsgReceiveStatus<>MsgFull then
   begin
    while (ClientSession.MsgReceiveStatus<>MsgStart)
    and (ClientSession.MsgReceiveStatus<>MsgFull)
    do // Wait for starting answer receive
     begin
      if ClientSession.MsgControlCode = MsgTerminate then
       begin
        EnterCSect(FCSect);
        dec(ClientSession.Status);
        LeaveCSect(FCSect);
        raise EMsgException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ClientSession.Session.ConnectParams.ReceiveSleep);
     end;
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> Wait for full arrive...');
{$ENDIF}
    StartTime := GetTickCount;
    while ClientSession.MsgReceiveStatus<>MsgFull do // Wait for all packets to arrive
     begin
      if ClientSession.MsgControlCode = MsgTerminate then
       begin
        EnterCSect(FCSect);
        dec(ClientSession.Status);
        LeaveCSect(FCSect);
        raise EMsgException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
      if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.ReceiveTimeOut then
        raise EMsgException.Create(40026, ErrorRTimeoutFullReceive,
                                [ClientSession.ServerSessionID,
                                ClientSession.Session.ConnectParams.ReceiveTimeOut]);
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ClientSession.Session.ConnectParams.ReceiveSleep);
     end;
   end;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('CLIENT are receiving message from SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
//  TerminateMessageThreads(ClientSession);
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> get buffer size...');
aaWriteToLog('ReceiveMessage> ClientSession.ClientMessageID='+IntToStr(ClientSession.ClientMessageID));
aaWriteToLog('ReceiveMessage> ClientSession.MsgPackets.Count='+IntToStr(ClientSession.MsgPackets.Count));
{$ENDIF}
  EnterCSect(FCSect);
  BufferSize := 0;
  for i := 0 to ClientSession.MsgPackets.Count - 1 do
   begin
    Packet := ClientSession.MsgPackets.Items[i];
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> i:='+IntToStr(i)+' Packet.BufferSize='+IntToStr(Packet.BufferSize));
{$ENDIF}
    BufferSize := BufferSize + Packet.BufferSize - SizeOf(TMsgPacketHeader);
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> BufferSize='+IntToStr(BufferSize));
{$ENDIF}
   end;
  if BufferSize > 0 then
   begin
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> GetMem...');
{$ENDIF}
    Buffer := MemoryManager.GetMem(BufferSize);
    pBuf := Buffer;
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
   end
  else
   begin
aaWriteToLog('ReceiveMessage> ERROR: BufferSize<=0!');
{$ENDIF}
   end;
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> Get full buffer...');
{$ENDIF}
  for i := 0 to ClientSession.MsgPackets.Count - 1 do
   begin
    Packet := ClientSession.MsgPackets.Items[i];
    if Packet <> nil then
     begin
      if Packet.Buffer <> nil then
       begin
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> i:='+IntToStr(i)+' copying...');
{$ENDIF}
        Move(Pointer(Packet.Buffer+SizeOf(TMsgPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TMsgPacketHeader));
        inc(pBuf, Packet.BufferSize-SizeOf(TMsgPacketHeader));
        MemoryManager.FreeAndNilMem(Packet.Buffer);
       end
      else
       begin
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> i:='+IntToStr(i)+' Packet.Buffer = nil');
{$ENDIF}
       end;
      Dispose(Packet);
      ClientSession.MsgPackets.Items[i] := nil;
     end;
   end;
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ClientSession.MsgReceiveStatus='+IntToStr(ClientSession.MsgReceiveStatus));
aaWriteToLog('ReceiveMessage> set ClientSession.MsgPackets.Count=0...');
{$ENDIF}
  ClientSession.MsgPackets.Count := 0;
  LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('CLIENT HAS RECEIVED Message FROM SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
aaWriteToLog('==============================================================');
{$ENDIF}
//  inc(ClientSession.ServerMessageID);
  ClientSession.MsgReceiveStatus := MsgNo;
  EnterCSect(FCSect);
  dec(ClientSession.Status);
  LeaveCSect(FCSect);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('CLIENT - ReceiveMessage> Exception! '+E.Message);
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> TMsgClientConnectionManager.ReceiveMessage - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
    raise;
   end;
 end; // except
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('ReceiveMessage> Finish');
{$ENDIF}
end; // ReceiveMessage
*)

//------------------------------------------------------------------------------
// ReceiveBuffer
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.ReceiveBuffer(
                          Session:        TMsgComBaseSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer;
                          Connecting:     Boolean = False
                          );
label
  Loop;
var
  Sessions:             TMsgList;
  ClientSession:        PMsgClntSession;
  SessionFound:         Boolean;
  i:                    Integer;
  Packet:               PMsgPacket;
  pBuf:                 PAnsiChar;
  EmptyTime,
  StartTime:            Cardinal;
begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> START');
{$ENDIF}
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> START');
{$ENDIF}
try
  SessionFound := False;
  Sessions := FSessions.LockList;
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ClientSession := Sessions.Items[i];
     if (ClientSession.Session = Session)
     then
       begin
        SessionFound := True;
        inc(ClientSession.Status);
        EnterCSect(ClientSession.FCSect);
        break;
       end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if not SessionFound then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
 try // session entered CS
  StartTime := GetTickCount;
  EmptyTime := StartTime;
  if ClientSession.AnswerStatus <> MsgFull then
   begin
    while (ClientSession.AnswerStatus = MsgNo) do // Wait for starting answer receive
     begin
      if ClientSession.ControlCode = MsgTerminate then
       begin
        raise EMsgException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
      if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.StartReceiveTimeOut then
       begin
        raise EMsgException.Create(40104, ErrorRTimeoutStartReceive,
                                [ClientSession.ServerSessionID,
                                ClientSession.Session.ConnectParams.StartReceiveTimeOut]);
       end;
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> sleep1...');
{$ENDIF}
      LeaveCSect(ClientSession.FCSect);
      if (GetTickCount >= (EmptyTime + MsgPacketProcessTimeOut)) then
       begin
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> sleep(ReceiveSleep='+IntToStr(ClientSession.Session.ConnectParams.ReceiveSleep)+')...');
{$ENDIF}
        Sleep(ClientSession.Session.ConnectParams.ReceiveSleep);
       end
      else
       begin
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> sleep(0)...');
{$ENDIF}
        Sleep(0);
       end;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> up!');
{$ENDIF}
      EnterCSect(ClientSession.FCSect);
     end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> answer started');
{$ENDIF}
    StartTime := GetTickCount;
    EmptyTime := StartTime;
    while ClientSession.AnswerStatus <> MsgFull do // Wait for all packets to arrive
     begin
      if ClientSession.ControlCode = MsgTerminate then
       begin
        raise EMsgException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
      if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.ReceiveTimeOut then
       begin
        raise EMsgException.Create(40025, ErrorRTimeoutFullReceive,
                            [ClientSession.ServerSessionID,
                            ClientSession.Session.ConnectParams.ReceiveTimeOut]);
       end;
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> sleep2...');
{$ENDIF}
      LeaveCSect(ClientSession.FCSect);
      if (GetTickCount >= (EmptyTime + MsgPacketProcessTimeOut)) then
       begin
        sleep(ClientSession.Session.ConnectParams.ReceiveSleep);
       end
      else
        sleep(0);;
      EnterCSect(ClientSession.FCSect);
     end;
   end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> answer is full');
{$ENDIF}

  BufferSize := 0;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Packets.Count = '+IntToStr(ClientSession.Packets.Count));
{$ENDIF}
  for i := 0 to ClientSession.Packets.Count - 1 do
   begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Packet # '+IntToStr(i));
{$ENDIF}
    Packet := ClientSession.Packets.Items[i];
    BufferSize := BufferSize + Packet.BufferSize - SizeOf(TMsgPacketHeader);
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Packet.BufferSize = '+IntToStr(Packet.BufferSize));
{$ENDIF}
   end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
   if BufferSize > 0 then
     Buffer := MemoryManager.GetMem(BufferSize)
   else
     Buffer := nil;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Buffer memory got');
{$ENDIF}
  pBuf := Buffer;
  for i := 0 to ClientSession.Packets.Count - 1 do
   begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Packets.Count = '+IntToStr(ClientSession.Packets.Count));
{$ENDIF}
    Packet := ClientSession.Packets.Items[i];
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Packet # '+IntToStr(i));
{$ENDIF}
    if Packet <> nil then
     begin
      if Packet.Buffer <> nil then
       begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Move...');
{$ENDIF}
        if (Packet.BufferSize > SizeOf(TMsgPacketHeader)) then
         begin
          Move(Pointer(Packet.Buffer+SizeOf(TMsgPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TMsgPacketHeader));
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> inc...');
{$ENDIF}
          inc(pBuf, Packet.BufferSize-SizeOf(TMsgPacketHeader));
         end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> inced'+IntToStr(Packet.BufferSize-SizeOf(TMsgPacketHeader)));
{$ENDIF}
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> free packet buffer...');
{$ENDIF}
        MemoryManager.FreeAndNilMem(Packet.Buffer);
       end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> Dispose packet...');
{$ENDIF}
      Dispose(Packet);
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> packet = nil...');
{$ENDIF}
      ClientSession.Packets.Items[i] := nil;
     end;
   end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> ClientSession.Packets.Count := 0 ...');
{$ENDIF}
  ClientSession.Packets.Count := 0;
  if not Connecting then
    DecompressAndDecryptBuffer(ClientSession.Session, Buffer, BufferSize);
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> DecompressAndDecryptBuffer - OK');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('CLIENT HAS RECEIVED BUFFER FROM SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
aaWriteToLog('==============================================================');
{$ENDIF}
  ClientSession.AnswerStatus := MsgNo;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
 end;
except
  on E: Exception do
    begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> TMsgClientConnectionManager.ReceiveBuffer - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
     raise;
    end;
end; // except
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('CLIENT has finished answer receiving');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('CLIENT<<< '+IntToStr(ClientSession.CurrentRequestID)+' :');
aaWriteBufferToLog(Buffer,BufferSize);
{$ENDIF}
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.ReceiveBuffer> FINISH');
{$ENDIF}
end; // ReceiveBuffer


//------------------------------------------------------------------------------
// SendConnectRequest
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendConnectRequest(ClientSession: PMsgClntSession);
var
  Buf, Buffer:                    PAnsiChar;
  BufSize, BufferSize,
  SizeApp, SizeParams:            Integer;
  StartTime:                      Cardinal;
  Retry:                          Integer;
  ConnectionParams:               TMsgConnectionParams;
  RetryCount, Delay,
  ServerID:                       Integer;
{$IFDEF MsgCommunicator}
  Direct:                         Boolean;
{$ENDIF}
begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> START');
{$ENDIF}
// ClientSession.FCSect entered in Connect
 try
  ClientSession.AnswerStatus := MsgNo;
  ClientSession.CurrentRequestID := 0;
  ConnectionParams.PacketSize := ClientSession.Session.ConnectParams.PacketSize;
  ConnectionParams.CompressionAlgorithm := ClientSession.Session.ConnectParams.CompressionAlgorithm;
  ConnectionParams.CompressionMode := ClientSession.Session.ConnectParams.CompressionMode;
  ConnectionParams.UseServerSettings := ClientSession.Session.ConnectParams.UseServerSettings;
  CreateAuthorizationBuffer(ClientSession.Session.ConnectParams.CryptoInfo, Buffer, BufferSize);
//  IsAuthorizationBufferValid(ClientSession.Session.ConnectParams.CryptoInfo, Buffer, BufferSize);
  SizeApp := Length(FApplication) + 1;
  SizeParams := SizeOf(ConnectionParams);
  BufSize := SizeParams + SizeOf(BufferSize) + BufferSize + SizeApp;
{$IFDEF MsgCommunicator}
  inc(BufSize, SizeOf(ClientSession.Session.FUserID));
{$ENDIF}
  Buf := MemoryManager.GetMem(BufSize);
   try
{$IFDEF MsgCommunicator}
    Move(ClientSession.Session.FUserID, Buf^, SizeOf(ClientSession.Session.FUserID));
    inc(Buf, SizeOf(ClientSession.Session.FUserID));
{$ENDIF}
    try
     Move(ConnectionParams, Buf^, SizeParams);
     Move(BufferSize, PAnsiChar(Buf + SizeParams)^, SizeOf(BufferSize));
     if BufferSize > 0 then
      begin
       Move(Buffer^, PAnsiChar(Buf + SizeParams + SizeOf(BufferSize))^, BufferSize);
       MemoryManager.FreeAndNilMem(Buffer);
      end;
     StrPCopy(Buf + SizeParams + SizeOf(BufferSize) + BufferSize, FApplication);
     Retry := 0;
    finally
{$IFDEF MsgCommunicator}
     dec(Buf, SizeOf(ClientSession.Session.FUserID));
{$ENDIF}
    end;
     repeat
      if ClientSession.ControlCode = MsgTerminate then
       begin
        Exit;
       end;
{$IFDEF MsgCommunicator}
      if TMsgClientSession(ClientSession.Session).Direct then
         ClientSession.Session.FConnectParams.ServerID :=
            TMsgClientSession(ClientSession.Session).RemoteUser.UserID; // for connect request only
{$ENDIF}
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> SendBuffer...');
{$ENDIF}
      LeaveCSect(ClientSession.FCSect);
      try
       SendBuffer(ClientSession.Session, Buf, BufSize, MsgConnect);
      finally
       EnterCSect(ClientSession.FCSect);
      end;
  {$IFDEF LOG_CLIENT_CONNECT}
  aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> Sent!');
  {$ENDIF}
  {$IFDEF MsgCommunicator}
      if TMsgClientSession(ClientSession.Session).Direct then
        if ClientSession.Session.FConnectParams.ServerID = TMsgClientSession(ClientSession.Session).RemoteUser.UserID then // Header.Sender from the answer is not set
          ClientSession.Session.FConnectParams.ServerID := Integer(MSG_INVALID_USER_ID);  // allow listen for MsgConnected answer
  {$ENDIF}
      StartTime := GetTickCount;
      while ((GetTickCount - StartTime) < ClientSession.Session.ConnectParams.ConnectDelay) do // pause
       begin
         if ClientSession.ControlCode = MsgTerminate then
           Exit;
         if ClientSession.SendStatus <> MsgSent then
          begin
           LeaveCSect(ClientSession.FCSect);
{$IFDEF ProcessMessages}
           Application.ProcessMessages;
{$ENDIF ProcessMessages}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> sleep('+IntToStr(ClientSession.Session.ConnectParams.WaitForSendSleep)+')...');
{$ENDIF}
           if ((GetTickCount - StartTime) > MsgMaxSendShortSleepTime) then
             Sleep(ClientSession.Session.ConnectParams.WaitForSendSleep)
           else
             Sleep(0);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> sleep('+IntToStr(ClientSession.Session.ConnectParams.WaitForSendSleep)+')...');
{$ENDIF}
           EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> CS entered!');
{$ENDIF}
          end
         else
          Exit;
       end;
      if IsDesignMode then
        break;
      inc(Retry);
     until  (Retry > ClientSession.Session.ConnectParams.ConnectRetryCount);
     if ClientSession.SendStatus <> MsgSent then
      begin
       ServerID := ClientSession.Session.ConnectParams.ServerID;
       RetryCount := ClientSession.Session.ConnectParams.ConnectRetryCount;
       Delay := ClientSession.Session.ConnectParams.ConnectDelay;
  {$IFDEF MsgCommunicator}
       Direct := TMsgClientSession(ClientSession.Session).Direct;
       if Direct then
         ServerID := TMsgClientSession(ClientSession.Session).RemoteUser.UserID
       else
         ServerID := TMsgClient(TMsgClientSession(ClientSession.Session).FOwnerComponent).ConnectionParams.ConnectParams.ServerID;
  {$ENDIF}
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest - DoDisconnect');
{$ENDIF}
       LeaveCSect(ClientSession.FCSect);
       dec(ClientSession.Status);
       DoDisconnect(ClientSession.Session);
  {$IFDEF MsgCommunicator}
       if Direct then
         raise EMsgException.Create(40023, ErrorRCannotConnect,
                             ['user', ServerID, RetryCount, Delay])
       else
  {$ENDIF}
         raise EMsgException.Create(40023, ErrorRCannotConnect,
                             ['server', ServerID, RetryCount, Delay]);
      end;
   finally
    MemoryManager.FreeAndNilMem(Buf);
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> ERROR: '+E.Message);
{$ENDIF}
    raise;
   end;
 end; // except
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendConnectRequest> FINISH');
{$ENDIF}
end;// SendConnectRequest


//------------------------------------------------------------------------------
// Connect
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.Connect(Session: TMsgComBaseSession;
                                              ListenOnly: Boolean = False;
                                              Tune: Boolean = True
                                              );
var
  Connections:          TMsgList;
  Sessions:             TMsgList;
  ClientConnection:     PMsgClntConnection;
  ClientSession:        PMsgClntSession;
//  MaxHeaderSize:        Integer;
  ConnectionID,
  SessionID:            TMsgSessionID;
  Buffer:               PAnsiChar;
  BufferSize,
  SizeParams:           Integer;
  i:                    Integer;
  Raised,
  SessionFound:         Boolean;
  Network:              TMsgNetwork;
  ConnectParams:        PMsgConnectParams;
  ConnectionParams:     PMsgConnectionParams;
begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect - START');
{$ENDIF}
  Raised := false;
  if ListenOnly then
    Session.SessionID := INVALID_SESSION_ID
  else
   begin
    EnterCSect(FCSect);
    Session.SessionID := FSessionID;
    dec(FSessionID);
    if FSessionID = INVALID_SESSION_ID then
      dec(FSessionID);
    LeaveCSect(FCSect);
   end;
{
// To send connect request in one packet:
  MaxHeaderSize := Max (
   SizeOf(TMsgPacketHeader) + SizeOf(TMsgConnectionParams)
//    + SizeOf(TMsgConnectionID)  // set by client
   + SizeOf(TMsgSessionID)        // set by server
   ,
   SizeOf(TMsgPacketHeader) + SizeOf(TMsgConnectionParams)
    + SizeOf(FApplication)
                        );
  if (Session.ConnectParams.PacketSize < MaxHeaderSize) then
   raise EMsgException.Create(40020, ErrorRPacketSizeTooSmall,
                                    [Session.ConnectParams.PacketSize,
                                     MaxHeaderSize]);
}
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> Search session...');
{$ENDIF}
  SessionFound := False;
// Does Session exist?
  Sessions:=FSessions.LockList;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> Locked');
{$ENDIF}
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ClientSession := Sessions.Items[i];
     if ClientSession.Session = Session then
      begin
//       inc(ClientSession.Status);  // From ACR v.5.90
//       EnterCSect(ClientSession.FCSect);
       SessionFound := True;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> session found');
{$ENDIF}
       break;
      end;
    end;
  finally
   FSessions.UnlockList;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> UnLocked');
{$ENDIF}
  end;
  if not SessionFound then
// No. Does Connection exist?
   begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> session not found');
{$ENDIF}
{
    ConnectionFound := False;
    Connections:=FConnections.LockList;
    try
     for i:=0 to Connections.Count-1 do
      begin
       ClientConnection := Connections.Items[i];
       if  (ClientConnection.Network.LocalPort = Session.ConnectParams.LocalPort)
       then
        begin
         ConnectionFound := True;
         break;
        end;
      end;
    finally
     FConnections.UnlockList;
    end;
    if not ConnectionFound then
}
     begin // No Session, no Connection
// Create new connection
      Network := nil;
      Connections:=FConnections.LockList;
      try
       for i:=0 to Connections.Count-1 do
        begin
         ClientConnection := Connections.Items[i];
         if (ClientConnection.Network.LocalPort = Session.ConnectParams.LocalPort)
{
         and
            (ClientConnection.Network.LocalHost := Session.ConnectParams.LocalHost)
}
         then
          begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> Connection found, Session = '+IntToStr(Integer(Session)));
{$ENDIF}
           Network := ClientConnection.Network;
           if Network.PacketSize < Session.ConnectParams.PacketSize then
            begin
             EnterCSect(Network.FCSect^);
             Network.PacketSize := Session.ConnectParams.PacketSize;
             LeaveCSect(Network.FCSect^);
            end;
           break;
          end;
        end;
      if Network = nil then
       begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> Connection not found, Session = '+IntToStr(Integer(Session)));
{$ENDIF}
        New(ClientConnection);
        EnterCSect(FCSect);
        inc(FConnectionID);
        ClientConnection.ConnectionID := FConnectionID;
        LeaveCSect(FCSect);
        IncThreadCount;
        ClientConnection.Network := TMsgNetwork.Create(self);
        EnterCSect(ClientConnection.Network.FCSect^);
        ClientConnection.Network.LocalPort := Session.ConnectParams.LocalPort;
        ClientConnection.Network.PacketSize := Session.ConnectParams.PacketSize;
        Session.FConnectParams.LocalPort := ClientConnection.Network.LocalPort; // if port is already in use
        LeaveCSect(ClientConnection.Network.FCSect^);
// Add new connection to Connections list
        Connections.Add(ClientConnection);
       end;
      finally
       FConnections.UnlockList;
      end;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> ConnectionID = '+IntToStr(ClientConnection.ConnectionID));
{$ENDIF}
     end; // Set new connection
// No Session, Connection Exists
    New(ClientSession);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('new session: @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
    ClientSession.Status := MsgInUse;
    InitCSect(ClientSession.FCSect,'ClientSession, from '+ClientConnection.Network.LocalHost+':'+IntToStr(ClientConnection.Network.LocalPort)+' to '+ClientConnection.Network.RemoteHost+':'+IntToStr(ClientConnection.Network.RemotePort),true);
    EnterCSect(ClientSession.FCSect);
    try
      ClientSession.Session := Session;
      ClientSession.AnswerTime := 0;
      ClientSession.ServerSessionID := ClientSession.Session.SessionID; // Header.SessionID
      ClientSession.ConnectionID := ClientConnection.ConnectionID;
      ClientSession.RemoteConnectionID := ClientConnection.ConnectionID;
      ClientSession.CurrentRequestID := 0;
      ClientSession.ClientMessageID := 0;
  //    ClientSession.ServerMessageID := 0;
      ClientSession.Packets := TMsgList.Create;
      ClientSession.Packets.Capacity := MsgDefaultPacketsInAnswer; // Allocate some place in list
      ClientSession.Packets.Clear; // Set Items to nil
  (*
      ClientSession.MsgPackets := TMsgList.Create;
      ClientSession.MsgPackets.Capacity := MsgDefaultMsgPacketsInAnswer; // Allocate some place in list
      ClientSession.MsgPackets.Clear; // Set Items to nil
  *)
      ClientSession.PacketIDsToResend := TMsgThreadIntArray.Create;
      ClientSession.MsgPacketIDsToResend := TMsgThreadIntArray.Create;
  (*
      ClientSession.ListeningThreads := TMsgThreadList.Create;
      ClientSession.MsgListeningThreads := TMsgThreadList.Create;
      ClientSession.LiveListenerThreads := 0;
  *)
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> ListeningThreads created in @ClientSession='+IntToStr(Integer(ClientSession)));
{$ENDIF}
      ClientSession.ResendRequestThread := nil;
  (*
      ClientSession.MsgResendRequestThread := nil;
      ClientSession.MsgControlCode := MsgExecute;
  *)
      ClientSession.ControlCode := MsgExecute;
      ClientSession.AnswerStatus := MsgNo;
  // Add new Session
      FSessions.Add(ClientSession);
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> Session added');
{$ENDIF}
      if not ListenOnly then
       begin
  // Connect to server
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> SendConnectRequest...');
{$ENDIF}
        try
         SendConnectRequest(ClientSession);
        except
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('ERROR: SendConnectRequest exception!');
{$ENDIF}
         Raised := true;
         raise;
        end;
        if (not Raised) and (ClientSession.SendStatus <> MsgSent) then
         begin
  {$IFDEF LOG_CLIENT_DISCONNECT}
  aaWriteToLog('TMsgClientConnectionManager.Connect - DoDisconnect');
  {$ENDIF}
          DoDisconnect(Session);
          raise EMsgException.Create(40039, ErrorRCannotConnetToServer,
                                    [Session.ConnectParams.RemoteHost,
                                     Session.ConnectParams.RemotePort,
                                     Session.ConnectParams.LocalPort,
                                     Session.ConnectParams.ServerID]);
         end;
        if ClientSession.ControlCode = MsgTerminate then
         begin
          Exit;
         end;
        ClientSession.PacketIDsToResend.SetSize(0); // Do not request broken packets
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect - Receive buffer...');
{$ENDIF}
        ReceiveBuffer(Session, Buffer, BufferSize);
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect - Received!');
{$ENDIF}
    // Get connection parameters
        if ClientSession.Session.ConnectParams.UseServerSettings then
         begin
          ConnectParams := PMsgConnectParams(Buffer);
          ClientSession.Session.FConnectParams.StartReceiveTimeOut := ConnectParams.StartReceiveTimeOut;
          ClientSession.Session.FConnectParams.ReceiveTimeOut := ConnectParams.ReceiveTimeOut;
          ClientSession.Session.FConnectParams.ReceiveSleep := ConnectParams.ReceiveSleep;
          ClientSession.Session.FConnectParams.MinSendTimeOut := ConnectParams.MinSendTimeOut;
          ClientSession.Session.FConnectParams.SendTimeOut := ConnectParams.SendTimeOut;
          ClientSession.Session.FConnectParams.WaitForSendSleep := ConnectParams.WaitForSendSleep;
          ClientSession.Session.FConnectParams.ResendDelay := ConnectParams.ResendDelay;
          ClientSession.Session.FConnectParams.RequestDelay := ConnectParams.RequestDelay;
          ClientSession.Session.FConnectParams.WaitForTimeOut := ConnectParams.WaitForTimeOut;
          ClientSession.Session.FConnectParams.ThreadsTerminateDelay := ConnectParams.ThreadsTerminateDelay;
          ClientSession.Session.FConnectParams.PacketSize := ConnectParams.PacketSize;
          ClientSession.Session.FConnectParams.MaxThreadCount := ConnectParams.MaxThreadCount;
          ClientSession.Session.FConnectParams.TestPacketCount := ConnectParams.TestPacketCount;
          ClientSession.Session.FConnectParams.PingCount := ConnectParams.PingCount;
          EnterCSect(ClientConnection.Network.FCSect^);
          if ClientConnection.Network.PacketSize < ClientSession.Session.ConnectParams.PacketSize then
            ClientConnection.Network.PacketSize := ClientSession.Session.ConnectParams.PacketSize;
          LeaveCSect(ClientConnection.Network.FCSect^);
          ClientSession.Session.FConnectParams.CompressionAlgorithm := ConnectParams.CompressionAlgorithm;
          ClientSession.Session.FConnectParams.CompressionMode := ConnectParams.CompressionMode;
          SizeParams := SizeOf(TMsgConnectParams);
         end
        else
         begin
          ConnectionParams := PMsgConnectionParams(Buffer);
          ClientSession.Session.FConnectParams.PacketSize := ConnectionParams.PacketSize;
          EnterCSect(ClientConnection.Network.FCSect^);
          if ClientConnection.Network.PacketSize < ClientSession.Session.ConnectParams.PacketSize then
            ClientConnection.Network.PacketSize := ClientSession.Session.ConnectParams.PacketSize;
          LeaveCSect(ClientConnection.Network.FCSect^);
          ClientSession.Session.FConnectParams.CompressionAlgorithm := ConnectionParams.CompressionAlgorithm;
          ClientSession.Session.FConnectParams.CompressionMode := ConnectionParams.CompressionMode;
          SizeParams := SizeOf(TMsgConnectionParams);
         end;
        // SessionID
        Move((Buffer+SizeParams)^, SessionID, SizeOf(SessionID));
        ConnectionID := -MAXINT;
  {$IFDEF MsgCommunicator}
        if (BufferSize>=(SizeOf(TMsgConnectParams))+SizeOf(SessionID)+SizeOf(ConnectionID)) then
          Move((Buffer+SizeParams+SizeOf(SessionID))^, ConnectionID, SizeOf(ConnectionID));
  {$ENDIF}
        MemoryManager.FreeAndNilMem(Buffer);
        ClientSession.ServerSessionID := SessionID;
        if (ConnectionID = -MAXINT) then
          ClientSession.RemoteConnectionID := ClientSession.ConnectionID
        else
          ClientSession.RemoteConnectionID := ConnectionID;
          if Tune then
            TuneConnectionParamaters(ClientSession);
       end; // Connect to server
    finally
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> finally...');
{$ENDIF}
     if not Raised then
      begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> Leave CS...');
{$ENDIF}
       LeaveCSect(ClientSession.FCSect);
       dec(ClientSession.Status);
      end;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect> finally Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
    end;
   end; //Session not Found
// Update ClientConnectionManager variables with sessions settings
  if ClientSession.Session <> nil then
   begin
    FMaxThreadCount := ClientSession.Session.ConnectParams.MaxThreadCount;
    FReceiveTimeOut := ClientSession.Session.ConnectParams.ReceiveTimeOut;
   end;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TMsgClientConnectionManager.Connect - FINISH');
{$ENDIF}
end; // Connect


//------------------------------------------------------------------------------
// TuneConnectionParamaters
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.TuneConnectionParamaters(ClientSession:  PMsgClntSession);
var
  Buffer:               PAnsiChar;
  BufferSize:           Integer;
  i:                    Integer;
  StartTime:            Cardinal;
begin
// test network speed for connection parameters tunning
    if ClientSession.Session.ConnectParams.ConnectionParamsTunning then
     begin
      StartTime := GetTickCount;
      BufferSize := (ClientSession.Session.ConnectParams.PacketSize-SizeOf(TMsgPacketHeader)) * ClientSession.Session.ConnectParams.TestPacketCount;
      Buffer := MemoryManager.GetMem(BufferSize);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.Connect - NETWORK TUNNING:');
aaWriteToLog('Buffer size = '+IntToStr(BufferSize)+' Bytes');
{$ENDIF}
      try
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.Connect - NETWORK TUNNING - Sending...');
{$ENDIF}
      SendBuffer(ClientSession.Session, Buffer, BufferSize, MsgTunning);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.Connect - NETWORK TUNNING - Sent!');
{$ENDIF}
      finally
       MemoryManager.FreeAndNilMem(Buffer);
      end;
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.Connect - NETWORK TUNNING - Receiving...');
{$ENDIF}
      ReceiveBuffer(ClientSession.Session,Buffer,BufferSize);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.Connect - NETWORK TUNNING - Received!');
{$ENDIF}
      ClientSession.AnswerTime := GetTickCount - StartTime;
      ClientSession.Session.FConnectParams.SendTimeOut := ClientSession.AnswerTime * 4;
      if ClientSession.Session.ConnectParams.SendTimeOut < ClientSession.Session.ConnectParams.MinSendTimeOut then
        ClientSession.Session.FConnectParams.SendTimeOut := ClientSession.Session.ConnectParams.MinSendTimeOut;
      ClientSession.Session.FConnectParams.ReceiveTimeOut := ClientSession.Session.ConnectParams.SendTimeOut;
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.Connect - NETWORK TUNNING:');
aaWriteToLog('---------------------------------------------------------------');
aaWriteToLog('Packet size = '+IntToStr(ClientSession.Session.ConnectParams.PacketSize)+' Bytes');
aaWriteToLog('Test packets count = '+IntToStr(MsgTestPacketCount));
aaWriteToLog('Answer time  = '+IntToStr(ClientSession.AnswerTime)+' msec');
aaWriteToLog('New timeout  = '+IntToStr(FSendTimeOut)+' msec');
aaWriteToLog('===============================================================');
{$ENDIF}
      BufferSize := SizeOf(ClientSession.AnswerTime);
      Buffer := MemoryManager.GetMem(BufferSize);
      try
       Move(ClientSession.AnswerTime,Buffer^,BufferSize);
       SendBuffer(ClientSession.Session,Buffer,BufferSize,MsgServerSessionTunning);
      finally
       MemoryManager.FreeAndNilMem(Buffer);
      end;
     end;
// end of network testing
end; // TuneConnectionParamaters


//------------------------------------------------------------------------------
// SendPing
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendPing(
                          ClientSession: PMsgClntSession
                          );
var
  Header:               PMsgPacketHeader;
  Connections:          TMsgList;
  ClientConnection:     PMsgClntConnection;
  i:                    Integer;
begin
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - START');
{$ENDIF}
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
   Header.ControlCode := MsgPing;
   Header.Signature := MsgClientPacketSign;
   Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
   Header.ConnectionID := ClientSession.RemoteConnectionID;
   Header.SessionID := ClientSession.ServerSessionID;
   Header.PacketID := 0;
   Header.CurrentRequestID := 0;
   Connections:=FConnections.LockList;
   try
    for i:=0 to Connections.Count-1 do
     begin
      ClientConnection := Connections.Items[i];
      if (ClientConnection.ConnectionID = ClientSession.ConnectionID) then
       break;
     end;
   finally
    FConnections.UnlockList;
   end;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - Enter...');
{$ENDIF}
   EnterCSect(ClientConnection.Network.FCSect^);
   try
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - Entered!');
{$ENDIF}
    ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
    ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - Send...');
aaWriteToLog('TMsgClientConnectionManager.SendPing> ClientSession.Session.ConnectParams.RemoteHost="'+ClientSession.Session.ConnectParams.RemoteHost+'"');
aaWriteToLog('TMsgClientConnectionManager.SendPing> ClientSession.Session.ConnectParams.RemotePort='+IntToStr(ClientSession.Session.ConnectParams.RemotePort));
{$ENDIF}
    ClientConnection.Network.SendBuffer(PAnsiChar(Header), SizeOf(TMsgPacketHeader));
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - Sent!');
{$ENDIF}
   finally
    LeaveCSect(ClientConnection.Network.FCSect^);
   end;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - Left!');
{$ENDIF}
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TMsgClientConnectionManager.SendPing - FINISH');
{$ENDIF}
 end;
end;// SendPing


//------------------------------------------------------------------------------
// SendAcknowledgement
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendAcknowledgement(
                          ClientSession: PMsgClntSession;
                          Msg:           Boolean = False;
                          CurrentRequestID:     Integer = -1
                          );
var
  Header:               PMsgPacketHeader;
  Connections:          TMsgList;
  ClientConnection:     PMsgClntConnection;
  i:                    Integer;
begin
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - START');
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - CS entered');
{$ENDIF}
 try
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
   if Msg then
     Header.ControlCode := MsgMessageReceived
   else
     Header.ControlCode := MsgAllPacketsReceived;
   Header.Signature := MsgClientPacketSign;
   Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
   Header.ConnectionID := ClientSession.RemoteConnectionID;
   Header.SessionID := ClientSession.ServerSessionID;
{$IFDEF MsgCommunicator}
   if TMsgClientSession(ClientSession.Session).Direct then
     Header.SessionID := ClientSession.Session.SessionID;
{$ENDIF}
   Header.PacketID := 0;
   if CurrentRequestID>=0 then
     Header.CurrentRequestID := CurrentRequestID
   else
{
     if Msg then
       Header.CurrentRequestID := ClientSession.ServerMessageID
     else
}
     Header.CurrentRequestID := ClientSession.CurrentRequestID;
   Connections:=FConnections.LockList;
   try
    for i:=0 to Connections.Count-1 do
     begin
      ClientConnection := Connections.Items[i];
      if (ClientConnection.ConnectionID = ClientSession.ConnectionID) then
       break;
     end;
   finally
    FConnections.UnlockList;
   end;
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - Enter...');
{$ENDIF}
   EnterCSect(ClientConnection.Network.FCSect^);
   try
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - Entered!');
{$ENDIF}
    ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
    ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - Send...');
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement> ClientSession.Session.ConnectParams.RemoteHost="'+ClientSession.Session.ConnectParams.RemoteHost+'"');
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement> ClientSession.Session.ConnectParams.RemotePort='+IntToStr(ClientSession.Session.ConnectParams.RemotePort));
{$ENDIF}
    ClientConnection.Network.SendBuffer(PAnsiChar(Header), SizeOf(TMsgPacketHeader));
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - Sent!');
{$ENDIF}
   finally
    LeaveCSect(ClientConnection.Network.FCSect^);
   end;
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendAcknowledgement - Left!');
{$ENDIF}
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
 end;
end;// SendAcknowledgement


{$IFDEF MsgCommunicator}
//------------------------------------------------------------------------------
// SendConnectAckn
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendConnectAckn(
                          ClientSession:        PMsgClntSession;
                          ClientConnection:     PMsgClntConnection;
                          CurrentRequestID:     Integer = -1
                                                      );
var
  Buffer,
  Buf:                            PAnsiChar;
  BufferSize,
  BufSize,
  SizeSID, SizeCID, SizeParams:   Integer;
  ConnectionParams:               TMsgConnectionParams;
  RequestID:                      Integer;
begin
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> START');
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
  if ClientSession.Session.ConnectParams.UseServerSettings then
   begin
    Buf := @ClientSession.Session.FConnectParams;
    SizeParams := SizeOf(TMsgConnectParams);
   end
  else
   begin
    ConnectionParams.PacketSize := ClientSession.Session.ConnectParams.PacketSize;
    ConnectionParams.CompressionAlgorithm := ClientSession.Session.ConnectParams.CompressionAlgorithm;
    ConnectionParams.CompressionMode := ClientSession.Session.ConnectParams.CompressionMode;
    Buf := @ConnectionParams;
    SizeParams := SizeOf(ConnectionParams);
   end;
  SizeSID := SizeOf(ClientSession.Session.SessionID);
  BufferSize := SizeParams + SizeSID;
{$IFDEF MsgCommunicator}
  SizeCID := SizeOf(ClientSession.ConnectionID);
  BufferSize := BufferSize + SizeCID;
{$ENDIF}
  Buffer := MemoryManager.GetMem(BufferSize);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> SessionID='+IntToStr(ClientSession.Session.SessionID));
aaWriteToLog('SizeSID='+IntToStr(SizeSID)+', SizeParams='+IntToStr(SizeParams)+', BufferSize='+IntToStr(BufferSize));
{$ENDIF}
  try
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> copy connection parameters...');
{$ENDIF}
   Move(Buf^, Buffer^, SizeParams); // copy connection parameters
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> copy SessionID...');
{$ENDIF}
   Move(ClientSession.Session.SessionID, (Buffer+SizeParams)^, SizeSID);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> copy ConnectionID...');
{$ENDIF}
{$IFDEF MsgCommunicator}
   Move(ClientSession.ConnectionID, (Buffer+SizeParams+SizeSID)^, SizeCID);
{$ENDIF}
   if CurrentRequestID >= 0 then
    begin
     RequestID := ClientSession.CurrentRequestID;
     ClientSession.CurrentRequestID := CurrentRequestID;
    end;

{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> CompressAndEncryptBuffer...');
{$ENDIF}
   CompressAndEncryptBuffer(ClientSession.Session, Buffer, BufferSize, Buf, BufSize);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> DoSendBuffer...');
{$ENDIF}
   try
    DoSendBuffer(ClientSession, ClientConnection, Buf, BufSize, MsgConnected);
   finally
    if Buf<>Buffer then
      MemoryManager.FreeAndNilMem(Buf);
   end;

   if CurrentRequestID >= 0 then
     ClientSession.CurrentRequestID := RequestID;

   ClientSession.AnswerStatus := MsgNo;
  finally
   MemoryManager.FreeAndNilMem(Buffer);
  end;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TMsgClientConnectionManager.SendConnectAckn> FINISH');
{$ENDIF}
 end;
end;// SendConnectAckn


//------------------------------------------------------------------------------
// IsAuthorizationBufferValid
//------------------------------------------------------------------------------
function TMsgClientConnectionManager.IsAuthorizationBufferValid(
                      CryptoInfo: TMsgCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
begin
  Result := fnIsAuthorizationBufferValid(CryptoInfo, Buffer, BufferSize);
end;// IsAuthorizationBufferValid
{$ENDIF MsgCommunicator}


//------------------------------------------------------------------------------
// SendDisconnectRequest
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendDisconnectRequest(
                                    ClientSession: PMsgClntSession;
                                    WaitForAnswer: Boolean = True);
var
  Header:               PMsgPacketHeader;
  Connections:          TMsgList;
  ClientConnection:     PMsgClntConnection;
  Retry, i:             Integer;
  Delay,
  StartTime:            Cardinal;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> START');
{$ENDIF}
  ClientSession.AnswerStatus := MsgNo;
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
   Header.ControlCode := MsgDisconnect;
   Header.Signature := MsgClientPacketSign;
   Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
   Header.ConnectionID := ClientSession.RemoteConnectionID;
   Header.SessionID := ClientSession.ServerSessionID;
{$IFDEF MsgCommunicator}
   if TMsgClientSession(ClientSession.Session).Direct then
     Header.SessionID := ClientSession.Session.SessionID;
{$ENDIF}
   Header.PacketID := 0;
   Header.CurrentRequestID := ClientSession.CurrentRequestID;
   Connections:=FConnections.LockList;
   try
    for i:=0 to Connections.Count-1 do
     begin
      ClientConnection := Connections.Items[i];
      if (ClientConnection.ConnectionID = ClientSession.ConnectionID) then
        break;
     end;
   finally
    FConnections.UnlockList;
   end;
   Retry := 0;
   Delay := ClientSession.Session.ConnectParams.DisconnectDelay;
   ClientSession.SendStatus := MsgNotSent;
   try
    repeat
     if ClientSession.Session.ConnectParams.RemoteHost = '' then
       Exit; // Session already freed
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> Enter Network.FCSect...');
{$ENDIF}
     EnterCSect(ClientConnection.Network.FCSect^);
     try
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> RemoteHost='+ClientSession.Session.ConnectParams.RemoteHost);
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> RemotePort='+IntToStr(ClientSession.Session.ConnectParams.RemotePort));
{$ENDIF}
      ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
      ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
      ClientConnection.Network.SendBuffer(PAnsiChar(Header), SizeOf(TMsgPacketHeader));
     finally
      LeaveCSect(ClientConnection.Network.FCSect^);
     end;
     if not WaitForAnswer then
       Exit;
     if IsDesignMode then
       break;
     StartTime := GetTickCount;
     while ((GetTickCount - StartTime) < Delay) do // pause
      begin
        if ClientSession.ControlCode = MsgTerminate then
          Exit;
        if ClientSession.SendStatus <> MsgSent then
         begin
          LeaveCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> sleep...');
{$ENDIF}
          if ((GetTickCount - StartTime) > MsgMaxSendShortSleepTime) then
            Sleep(ClientSession.Session.ConnectParams.WaitForSendSleep)
          else
            Sleep(0);
{$IFDEF ProcessMessages}
          Application.ProcessMessages;
{$ENDIF ProcessMessages}
          EnterCSect(ClientSession.FCSect);
         end
        else
         Exit;
      end;
     inc(Retry);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> Retry # '+IntToStr(Retry));
{$ENDIF}
    until (Retry > ClientSession.Session.ConnectParams.DisconnectRetryCount);
   if ClientSession.SendStatus <> MsgSent then
{$IFDEF MsgCommunicator}
    if TMsgClientSession(ClientSession.Session).Direct then
      raise EMsgException.Create(40024, ErrorRCannotDisconnect,
                   ['client session with user', TMsgClientSession(ClientSession.Session).UserID,
                    ClientSession.Session.ConnectParams.DisconnectRetryCount,
                    ClientSession.Session.ConnectParams.DisconnectDelay])
    else
{$ENDIF}
      raise EMsgException.Create(40024, ErrorRCannotDisconnect,
                   ['server session', ClientSession.ServerSessionID,
                    ClientSession.Session.ConnectParams.DisconnectRetryCount,
                    ClientSession.Session.ConnectParams.DisconnectDelay]);
   finally
{$IFDEF LOG_CLIENT_DISCONNECT}
if ClientSession.SendStatus = MsgSent then
aaWriteToLog('CLIENT: SendDisconnectRequest> Answer is received')
else
aaWriteToLog('CLIENT: SendDisconnectRequest> Answer was not received');
{$ENDIF}
   end;
  finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> free...');
{$ENDIF}
   MemoryManager.FreeAndNilMem(Header);
  end;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> FINISH');
{$ENDIF}
end;// SendDisconnectRequest


//------------------------------------------------------------------------------
// DeleteSession
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.DeleteSession(ClientSession: PMsgClntSession);
var
  StartTime:            Cardinal;
  i, Count:             Integer;
  Packet:               PMsgPacket;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> START');
aaWriteToLog('DeleteSession> @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
 EnterCSect(ClientSession.FCSect);
 try
  if ClientSession.CurrentRequestID = MsgTerminate then // <0, illegal value not used
   begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> session is already deleting - FINISH');
{$ENDIF}
    Exit; // session is already deleting - FINISH
   end;
// block deleting ClientSession
  ClientSession.CurrentRequestID := MsgTerminate;
// block using ClientSession
  ClientSession.ControlCode := MsgTerminate;
// allow to finish a waiting for sending
  ClientSession.SendStatus := MsgSent;
// wait for vacant ClientSession
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> wait for vacant ClientSession...');
{$ENDIF}
  StartTime := GetTickCount;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> ClientSession.Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8)+', wait for vacant...');
{$ENDIF}
  repeat
   if (ClientSession.Status <= MsgVacant) then
     break;
   LeaveCSect(ClientSession.FCSect);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> sleep(0)');
{$ENDIF}
   sleep(0);
   EnterCSect(ClientSession.FCSect);
  until ((GetTickCount-StartTime) >= ClientSession.Session.ConnectParams.WaitForTimeOut);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> ClientSession.Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
  if (ClientSession.Status >= MsgInUse) then
    raise EMsgException.Create(40155, ErrorRClientSessionDelete, ['@='+IntToHex(Integer(ClientSession),8),ClientSession.Status]);
// close ResendRequestThread
  CloseThread(@(ClientSession.ResendRequestThread),MsgClientConnectionManager,ErrorRResendRequestThread);
// remove session from using
  ClientSession.Session := nil;
// free command packets
  Count := ClientSession.Packets.Count;
  for i := 0 to Count - 1 do
   begin
    Packet := ClientSession.Packets.Items[i];
    if Packet <> nil then
     begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> Packet # 0: Free Buffer...');
{$ENDIF}
      if Packet.Buffer <> nil then
        MemoryManager.FreeAndNilMem(Packet.Buffer);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> Packet # 0: Dispose Packet...');
{$ENDIF}
      Dispose(Packet);
     end;
   end;
  ClientSession.Packets.Free;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> Packets have been deleted');
{$ENDIF}
  ClientSession.PacketIDsToResend.Free;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('DeleteSession> PacketIDsToResend freed');
{$ENDIF}
  ClientSession.MsgPacketIDsToResend.Free;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('DeleteSession> MsgPacketIDsToResend freed');
{$ENDIF}
 finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('DeleteSession> leave  CS, @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
  LeaveCSect(ClientSession.FCSect);
 end;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('DeleteSession> delete CS, @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
  DeleteCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('DeleteSession> dispose @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
  Dispose(ClientSession);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DeleteSession> FINISH');
{$ENDIF}
end; // DeleteSession


//------------------------------------------------------------------------------
// DoDisconnect
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.DoDisconnect(Session: TMsgComBaseSession);
var
  Connections:          TMsgList;
  Sessions:             TMsgList;
  ClientConnection:     PMsgClntConnection;
  ClientSession:        PMsgClntSession;
  ConnectionID:         TMsgConnectionID;
  i, Count:             Integer;
  NoSessions:           Boolean;
  NoConnections:        Boolean;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> START');
if Session = nil then
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> session is nil - not initialized or prepared for deleting - FINISH');
{$ENDIF}
  if Session = nil then // session is not initialized or prepared for deleting
    Exit;
  NoSessions := True;
  NoConnections := False;  // do not delete connection in case session is not found
  Sessions:=FSessions.LockList;
  try
   Count := Sessions.Count;
   for i:=Count-1 downto 0 do
    begin
     if (i<0)
     or (i>=Sessions.Count) then
       break;
     ClientSession := Sessions.Items[i];
     if (ClientSession.Session = Session) then
      begin
       ConnectionID := ClientSession.ConnectionID;
       ClientSession.ControlCode := MsgTerminate;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> Remove SessionID = '+IntToStr(ClientSession.Session.SessionID));
{$ENDIF}
       Sessions.Delete(i);
       NoSessions := False;
       break;
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
{$IFDEF LOG_CLIENT_DISCONNECT}
if NoSessions then
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> session not found!!!')
else
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> session found');
{$ENDIF}
  if not NoSessions then
   begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> DeleteSession...');
{$ENDIF}
     DeleteSession(ClientSession);
// Search for another session using the same connection
     NoSessions := True;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> Sessions Count = '+IntToStr(Count));
{$ENDIF}
    Sessions:=FSessions.LockList;
    try
     Count := Sessions.Count;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> Sessions Count = '+IntToStr(Count));
{$ENDIF}
     for i:=Count-1 downto 0 do
      begin
       ClientSession := Sessions.Items[i];
       if ClientSession.ConnectionID = ConnectionID then
        begin
         NoSessions := False;
         break;
        end;
      end;
    finally
     FSessions.UnlockList;
    end;
    NoConnections := True;  // Suppose that it is not available to have another connection
                            // with the same localport
{
// Search for another connection with the same localport (= the same network)
    Connections:=FConnections.LockList;
    try
     for i:=0 to Connections.Count-1 do
      begin
       ClientConnection := Connections.Items[i];
       if (ClientConnection.ConnectionID = ConnectionID)
       then
        begin
         Network := ClientConnection.Network;
         break;
        end;
      end;
     NoConnections := True;
     for i:=0 to Connections.Count-1 do
      begin
       ClientConnection := Connections.Items[i];
       if (ClientConnection.ConnectionID <> ConnectionID)
       and (ClientConnection.Network = Network)
       then
        begin
         NoConnections := False;
         break;
        end;
      end;
    finally
     FConnections.UnlockList;
    end;
}
  end;

 if NoSessions then
// There is no another session who uses this connection
 begin
  Connections:=FConnections.LockList;
  try
   Count := Connections.Count;
   for i:=Count-1 downto 0 do
    begin
     ClientConnection := Connections.Items[i];
     if ClientConnection.ConnectionID = ConnectionID then
      begin
       if NoConnections then
        if ClientConnection.Network <> nil then
         begin
          ClientConnection.Network.Free;
          ClientConnection.Network := nil;
          DecThreadCount;
         end;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> Freed ConnectionID = '+IntToStr(ClientConnection.ConnectionID));
{$ENDIF}
       Connections.Delete(i);
       Dispose(ClientConnection);
       break; // session has only one connection
      end;
    end;
  finally
   FConnections.UnlockList;
  end;
 end;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.DoDisconnect> FINISH');
{$ENDIF}
end; // DoDisconnect


//------------------------------------------------------------------------------
// Disconnect
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.Disconnect(Session: TMsgComBaseSession;
                                                  ListenOnly: Boolean = False);
var
  Sessions:             TMsgList;
  ClientSession:        PMsgClntSession;
  i:                    Integer;
  Found:                Boolean;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.Disconnect - START');
{$ENDIF}
 try
  if not ListenOnly then
   begin // Send disconnect request
    Found := False;
    Sessions:=FSessions.LockList;
    try
     for i:=Sessions.Count-1 downto 0 do
      begin
       ClientSession := Sessions.Items[i];
       if ClientSession.Session = Session then
        begin
         Found := True;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> WaitForSendingThreads...');
{$ENDIF}
         WaitForSendingThreads(TMsgNetworkSession(ClientSession.Session));
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> lock session...');
{$ENDIF}
         inc(ClientSession.Status);
         EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.SendDisconnectRequest> session locked');
{$ENDIF}
         break;
        end;
      end;
    finally
     FSessions.UnlockList;
    end;
    if not Found then
      raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
    try
     ClientSession.ControlCode := MsgTerminate;
     inc(ClientSession.CurrentRequestID);
     SendDisconnectRequest(ClientSession);
    finally
     LeaveCSect(ClientSession.FCSect);
     dec(ClientSession.Status);
    end;
   end; // Send disconnect request
 finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.Disconnect - DoDisconnect');
{$ENDIF}
  DoDisconnect(Session);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientConnectionManager.Disconnect - FINISH');
{$ENDIF}
 end;
end; // Disconnect


//------------------------------------------------------------------------------
// DisconnectAll
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.DisconnectAll;
var
  Sessions:             TMsgList;
  Connections:          TMsgList;
  ClientSession:        PMsgClntSession;
  ClientConnection:     PMsgClntConnection;
  i:                    Integer;
begin
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> START');
{$ENDIF}
{$IFDEF CONNECTION_TEST}
  Exit;
{$ENDIF}
// delete sessions
  while FSessions.Count >= 1 do
   begin
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> lock sessions....');
{$ENDIF}
    Sessions:=FSessions.LockList;
    try
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> get session...');
{$ENDIF}
     ClientSession := Sessions.Items[0];
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> delete session...');
{$ENDIF}
     FSessions.Delete(0);
     inc(ClientSession.Status);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> enter CS...');
{$ENDIF}
     EnterCSect(ClientSession.FCSect);
    finally
     FSessions.UnlockList;
    end;
    try
    ClientSession.ControlCode := MsgTerminate;
     try
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> SendDisconnectRequest...');
{$ENDIF}
      SendDisconnectRequest(ClientSession, False);
     except
// do not raise
     end;
    finally
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> Leave CS...');
{$ENDIF}
     LeaveCSect(ClientSession.FCSect);
     dec(ClientSession.Status);
    end;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> All sessions terminated');
{$ENDIF}
    DeleteSession(ClientSession);
   end; // sessions
// delete connections
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> Connections');
{$ENDIF}
  while FConnections.Count >= 1 do
   begin
    Connections:=FConnections.LockList;
    try
     ClientConnection := Connections.Items[0];
     FConnections.Delete(0);
    finally
     FConnections.UnlockList;
    end;
    if ClientConnection.Network <> nil then
     begin
      ClientConnection.Network.Free;
      ClientConnection.Network := nil;
      DecThreadCount;
     end;
    Dispose(ClientConnection);
   end;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClientConnectionManager.DisconnectAll> FINISH');
{$ENDIF}
end; // DisconnectAll


//------------------------------------------------------------------------------
// WaitForSendingThreads
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.WaitForSendingThreads(Session: TMsgNetworkSession);
{$IFDEF MsgCommunicator}
var
  SendingThreads:     TMsgList;
  NoMineThreads:      Boolean;
  i:                  Integer;
{$ENDIF}
begin
// 4.42 Windows 7 problems
exit;
  while (FSendingThreads.Count > 0) do
   begin
{$IFDEF LOG_CLIENT_WAIT_SENDING_THREADS}
aaWriteToLog('MsgConnection> TMsgClientConnectionManager.WaitForSendingThreads> Count = '+IntToStr(FSendingThreads.Count));
{$ENDIF}
{$IFDEF MsgCommunicator}
    NoMineThreads := True;
    SendingThreads := FSendingThreads.LockList;
    try
     for i := SendingThreads.Count-1 downto 0 do
       if TMsgSendingThread(SendingThreads.Items[i]).FSession.FOwnerComponent
        = TMsgClient(Session.FOwnerComponent) then
        begin
         NoMineThreads := False;
         break;
        end;
    finally
     FSendingThreads.UnlockList;
    end;
    if NoMineThreads = True then
      Exit;
{$ENDIF}
    sleep(1);
   end;
end; // WaitForSendingThreads


//------------------------------------------------------------------------------
// SendMessage
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendMessage(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TMsgControlCode = MsgMessage
                                                  );
{
var
  Buf:  PAnsiChar;
}
begin
 try
{
  if (TMsgCompressionAlgorithm1(Session.ConnectParams.CompressionAlgorithm) <> acaNone)
  or (Session.ConnectParams.CryptoInfo.CryptoAlgorithm <> Msg_Cipher_None)
  then
   begin
    Buf := MemoryManager.GetMem(BufferSize);
    Move(Buffer^,Buf^,BufferSize);
    SendBuffer(Session, Buf, BufferSize, MsgMessage);
    MemoryManager.FreeAndNilMem(Buf);
   end
  else
}
  SendBuffer(Session, Buffer, BufferSize, Code);
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> TMsgClientConnectionManager.SendMessage - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
     raise;
    end;
 end;
end; // SendMessage


//------------------------------------------------------------------------------
// SendBuffer
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.SendBuffer(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = MsgNewRequest
                                                  );
var
  Connections:          TMsgList;
  Sessions:             TMsgList;
  ClientConnection:     PMsgClntConnection;
  ClientSession:        PMsgClntSession;
  ConnectionID:         TMsgConnectionID;
  i:                    Integer;
  Found:                Boolean;
  Buf:                  PAnsiChar;
  BufSize:              Integer;
  err:                  AnsiString;

procedure Raise40040;
begin
  raise EMsgException.Create(40040, ErrorRCannotSendToServer,
                                  [ClientSession.Session.ConnectParams.RemoteHost,
                                   ClientSession.Session.ConnectParams.RemotePort,
                                   ClientSession.Session.ConnectParams.LocalPort,
                                   ClientSession.Session.ConnectParams.ServerID,
                                   err]);
end;

begin
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> START');
{$ENDIF}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> START');
{$ENDIF}
 try
  if Session=nil then
   raise EMsgException.Create(40156, ErrorRSessionIsNil);
  if (Session.ConnectParams.PacketSize < SizeOf(TMsgPacketHeader)) then
   raise EMsgException.Create(40020, ErrorRPacketSizeTooSmall,
                                    [Session.ConnectParams.PacketSize,
                                     SizeOf(TMsgPacketHeader)]);
//  ClientSession := FindSession(Session);
  Found := False;
  Sessions := FSessions.LockList;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> Sessions locked');
{$ENDIF}
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ClientSession := Sessions.Items[i];
     if ClientSession.Session = Session then
       begin
        ConnectionID := ClientSession.ConnectionID;
        Found := True;
        break;
       end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if not Found then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> entering ClientSession.FCSect...');
{$ENDIF}
  inc(ClientSession.Status);
  EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> ClientSession.FCSect entered!');
{$ENDIF}
  try
    Found := False;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> Lock Connections...');
{$ENDIF}
    Connections := FConnections.LockList;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> Connections Locked!');
{$ENDIF}
    try
     for i:=0 to Connections.Count-1 do
      begin
       ClientConnection := Connections.Items[i];
       if ClientConnection.ConnectionID = ConnectionID then
         begin
          Found := True;
          break;
         end;
      end;
    finally
     FConnections.UnlockList;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> Connections Unlocked!');
{$ENDIF}
    end;
    if not Found then
      raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('CLIENT>>> '+IntToStr(ClientSession.CurrentRequestID + 1)+' :');
aaWriteBufferToLog(Buffer,BufferSize);
{$ENDIF}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> Code = '+IntToStr(Code));
{$ENDIF}
    if (Code >= MsgNewRequest)
    and (Code <> MsgConnected)
    then
     begin
      LeaveCSect(ClientSession.FCSect);
      dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> WaitForSendingThreads');
{$ENDIF}
      WaitForSendingThreads(TMSgNetworkSession(ClientSession.Session)); // wait for sending ackn of previous command receiving
      inc(ClientSession.Status);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> 2 - Enter CS...');
{$ENDIF}
      EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> 2 - CS entered!');
{$ENDIF}
     end;
    if (Code = MsgConnect)
    or (Code = MsgTunning)
    then
     begin
      Buf := Buffer;
      BufSize := BufferSize;
     end
    else
     begin  // not connect or tunning request, evaluate appropriate parameters
      CompressAndEncryptBuffer(ClientSession.Session, Buffer, BufferSize, Buf, BufSize);
// tune connection parameters
      if ClientSession.Session.ConnectParams.ConnectionParamsTunning then
       begin
        // i = packets count
        i := (BufSize div (ClientSession.Session.ConnectParams.PacketSize-SizeOf(TMsgPacketHeader)));
        if i>ClientSession.Session.ConnectParams.TestPacketCount then
         begin
          if ClientSession.AnswerTime=0 then
            TuneConnectionParamaters(ClientSession);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('Packets count in request,           i = '+IntToStr(i));
aaWriteToLog('sqrt(i*0.1) = '+FloatToStr(sqrt(i*0.1)));
aaWriteToLog('expectancy count of packets to resend = '+FloatToStr( (sqrt(i*0.1)*0.5+1)*(i*0.3) ));
aaWriteToLog('total packets planed to send          = '+IntToStr(trunc((sqrt(i*0.1)*0.5+1)*(i*0.3)+i)));
aaWriteToLog('times more = '+IntToStr(trunc(((sqrt(i*0.1)*0.5+1)*(i*0.3)+i)/MsgTestPacketCount)+1));
aaWriteToLog('answer time / 2 ='+IntToStr(ClientSession.AnswerTime div 2));
aaWriteToLog('time planned    ='+IntToStr((trunc( ((sqrt(i*0.1)*0.5+1)*(i*0.3)+i)/MsgTestPacketCount)+1)*(ClientSession.AnswerTime div 2)));
aaWriteToLog('assurance factor, 1+log10(i)='+IntToStr(1+trunc(log10(i))));
{$ENDIF}
          ClientSession.Session.FConnectParams.SendTimeOut := (trunc( ((sqrt(i*0.1)*0.5+1)*(i*0.3)+i)/ClientSession.Session.ConnectParams.TestPacketCount)+1)*(ClientSession.AnswerTime div 2);
          if ClientSession.AnswerTime < 1000 then
            ClientSession.Session.FConnectParams.SendTimeOut := ClientSession.Session.ConnectParams.SendTimeOut * (1+trunc(log10(i)));
         end;
        if ClientSession.Session.ConnectParams.SendTimeOut < ClientSession.Session.ConnectParams.MinSendTimeOut then
          ClientSession.Session.FConnectParams.SendTimeOut := ClientSession.Session.ConnectParams.MinSendTimeOut;
        ClientSession.Session.FConnectParams.ReceiveTimeOut := ClientSession.Session.ConnectParams.SendTimeOut * 2;
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer - NETWORK TUNNING:');
aaWriteToLog('---------------------------------------------------------------');
aaWriteToLog('Buffer size = '+IntToStr(BufferSize)+' Bytes (original)');
aaWriteToLog('Buffer size = '+IntToStr(BufSize)+' Bytes (compressed)');
aaWriteToLog('Packet size = '+IntToStr(ClientSession.Session.ConnectParams.PacketSize)+' Bytes');
aaWriteToLog('---------------------------------------------------------------');
aaWriteToLog('Packets count to send = '+IntToStr(i));
aaWriteToLog('Test packets count    = '+IntToStr(MsgTestPacketCount));
aaWriteToLog('Answer time = '+IntToStr(ClientSession.AnswerTime)+' msec');
aaWriteToLog('New timeout = '+IntToStr(FSendTimeOut)+' msec');
aaWriteToLog('===============================================================');
{$ENDIF}
       end;
     end;
    try
     DoSendBuffer(ClientSession, ClientConnection, Buf, BufSize, Code);
    finally
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> free Buf...');
{$ENDIF}
     if Buf <> Buffer then
      if Code <> MsgConnect then
       MemoryManager.FreeAndNilMem(Buf);
    end;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer - FINISH');
{$ENDIF}
  finally
   LeaveCSect(ClientSession.FCSect);
   dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer - FINISH');
{$ENDIF}
  end;
 except
  on E: EMsgException do
   begin
    ClientSession.Session.DoOnError(40040,e.NativeError,E.Message);
    err := E.Message;
    Raise40040;
   end;
  on E: Exception do
   begin
    ClientSession.Session.DoOnError(40040,-1,E.Message);
    err := E.Message;
    Raise40040;
   end
  else
   begin
    ClientSession.Session.DoOnError(40040);
    Raise40040;
   end;
 end;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TMsgClientConnectionManager.SendBuffer> FINISH');
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// DoSendBuffer
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.DoSendBuffer(
                          ClientSession:    PMsgClntSession;
                          ClientConnection: PMsgClntConnection;
                          Buffer:           PAnsiChar;
                          BufferSize:       Integer;
                          Code:             Integer = MsgNewRequest
                                                  );
var
  Header:               PMsgPacketHeader;
  Packets:              TMsgList;
  Packet:               PMsgPacket;
  BytesSent, DataSize:  Integer;
  i:                    Integer;
  msgStatus:            PMsgMessageStatus;
  SessionStatus:        Integer;
  err:                  Integer;
  errStr:               AnsiString;

procedure FirstResend;
begin
 // resend last packet for the first time
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('FirstResend');
{$ENDIF}
 Packet := Packets.Items[Packets.Count-1];
 EnterCSect(ClientConnection.Network.FCSect^);
 try
   ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
   ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
   ClientConnection.Network.SendBuffer(Packet.Buffer, Packet.BufferSize);
 finally
  LeaveCSect(ClientConnection.Network.FCSect^);
 end;
end; // FirstResend

procedure WaitForSent(Code: Integer);
var
  PacketID,
  i:                    Integer;
{$IFDEF LOG_CLIENT_RESENDING}
  j:                    Integer;
{$ENDIF}
  Delay,
  StartTime:            Cardinal;
  StartSleepTime:       Cardinal;
  PacketIDsToResend:    TMsgThreadIntArray;
label
  Resend;
begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> waits for all packets');
{$ENDIF}
 try
  if Code = MsgMessage then
    PacketIDsToResend := ClientSession.MsgPacketIDsToResend
  else
    PacketIDsToResend := ClientSession.PacketIDsToResend;
  if not ((Code = MsgConnect) or (Code = (MsgConnect + MsgLastPacket))) then
   begin
{
// code to force push up sending in case of more than 10 packets message
    if (Code = MsgMessage)
    or (Code = MsgMessageAbort)
    then
     begin
      if (ClientSession.MsgSendStatus <> MsgSent) then
       sleep(MsgFirstResendPushUpTimeout);
      if (ClientSession.MsgSendStatus <> MsgSent) then
        FirstResend;
     end
    else
     begin
      if (ClientSession.SendStatus <> MsgSent) then
       sleep(MsgFirstResendPushUpTimeout);
      if (ClientSession.SendStatus <> MsgSent) then
        FirstResend;
     end;
}
    i := PacketIDsToResend.ItemCount;
    Delay := ClientSession.Session.ConnectParams.ResendDelay;
    StartTime := GetTickCount;
    repeat  // resend broken packets
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      if PacketIDsToResend.ItemCount = 0 then // nothing to resend
       begin
        StartSleepTime := GetTickCount;
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> check SendStatus for '+IntToStr(Delay)+' msec');
{$ENDIF}
        while ((GetTickCount - StartSleepTime) < Delay) do  // sleep after last packet send
         begin
          if (Code = MsgMessage)
          or (Code = MsgMessageAbort) then
           begin
            if ClientSession.MsgSendStatus = MsgSent then
             begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> MsgSendStatus = MsgSent, FINISH');
{$ENDIF}
              Exit;
             end;
           end
          else
            if ClientSession.SendStatus = MsgSent then
             begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> SendStatus = MsgSent, FINISH');
{$ENDIF}
              Exit;
             end;
          if ClientSession.ControlCode = MsgTerminate then
           begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> ControlCode = MsgTerminate, EXCEPTION');
{$ENDIF}
            raise EMsgException.Create(err, ErrorRClientSessionTerminated,[Integer(ClientSession.Session.SessionID)]);
           end;
          if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.SendTimeOut then
           begin
{$IFDEF MsgCommunicator}
            if TMsgClientSession(ClientSession.Session).Direct then
            raise EMsgException.Create(40099, ErrorRTimeOutSendDirectly,
                ['message', TMsgClientSession(ClientSession.Session).RemoteUser.UserID,
                            ClientSession.Session.ConnectParams.SendTimeOut])
            else
{$ENDIF}
            raise EMsgException.Create(40077, ErrorRTimeOutSending,
              [errStr, ClientSession.Session.ConnectParams.ServerID,
              ClientSession.Session.ConnectParams.SendTimeOut]);
           end;
// check for resending needed
          PacketIDsToResend.Lock;
          try
           if (PacketIDsToResend.ItemCount > 0) then
            begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> resend request(s) got');
{$ENDIF}
             break;
            end;
          finally
           PacketIDsToResend.Unlock;
          end;
// sleep...
          LeaveCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> sleep(WaitForSendSleep='+IntToStr(ClientSession.Session.ConnectParams.WaitForSendSleep)+')...');
{$ENDIF}
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> sleep... time='+IntToStr(GetTickCount - StartSleepTime));
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> MsgMaxSendShortSleepTime='+IntToStr(MsgMaxSendShortSleepTime));
{$ENDIF}
          if ((GetTickCount - StartSleepTime) > MsgMaxSendShortSleepTime) then
            Sleep(ClientSession.Session.ConnectParams.WaitForSendSleep)
          else
            Sleep(0);
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> up!');
{$ENDIF}
          EnterCSect(ClientSession.FCSect);
         end; // sleep
       end // nothing to resend
      else
       begin
        LeaveCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> sleep(0)');
{$ENDIF}
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> sleep(0)');
{$ENDIF}
        Sleep(0); // Allow to process incoming packet queue
        EnterCSect(ClientSession.FCSect);
       end;
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> prepare to resend...');
aaWriteToLog('CLIENT has '+IntToStr(PacketIDsToResend.ItemCount)+' packets to resend:');
for j:=0 to PacketIDsToResend.ItemCount-1 do
aaWriteToLog(IntToStr(PacketIDsToResend.Items[j]));
{$ENDIF}
      dec(i);
      PacketIDsToResend.Lock;
      try
       if (i<0)
       or (i>=PacketIDsToResend.ItemCount)
       then
         i := PacketIDsToResend.ItemCount - 1;
       if i>=0 then // Packet to resend exists
        begin
         PacketID := PacketIDsToResend.Items[i];
         if PacketID >= Packets.Count then // error! - send nothing
           Continue
         else
           PacketIDsToResend.Delete(i);
        end
       else // No packets to resend - Resend last packet
         PacketID := Packets.Count - 1;
       Packet := Packets.Items[PacketID];
       // resend packet
       EnterCSect(ClientConnection.Network.FCSect^);
       try
Resend:
         ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
         ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
         if ClientSession.ControlCode = MsgTerminate then
          begin
           raise EMsgException.Create(err, ErrorRClientSessionTerminated,[Integer(ClientSession.Session.SessionID)]);
          end;
         try
          ClientConnection.Network.SendBuffer(Packet.Buffer, Packet.BufferSize);
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('Old Delay = '+IntToStr(Delay));
{$ENDIF}
          if i<0 then  // No packets to resend, increase pause
            Delay := Delay * 2
          else  // Restore default pause in case of packets resending
            Delay := ClientSession.Session.ConnectParams.ResendDelay;
          if Delay = 0 then
            Delay := MsgResendDelay;
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('New Delay = '+IntToStr(Delay));
{$ENDIF}
         except
          raise;
         end;
         if i=0 then // all resent -- needs to send last packet
          begin
{$IFNDEF LOG_CLIENT_RESENDING}
           PacketIDsToResend.Unlock;
           try
            Sleep(1); // To allow adding further packets to resend
           finally
            PacketIDsToResend.Lock;
           end;
{$ENDIF}
           if PacketIDsToResend.ItemCount = 0 then
            begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('all resent -- needs to send last packet to forse server to process request');
{$ENDIF}
             PacketID := Packets.Count - 1;
             Packet := Packets.Items[PacketID];
             Delay := (ClientSession.Session.ConnectParams.ResendDelay div 2);
             i := -1;
             goto Resend;
            end;
          end;
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT resent packet # '+IntToStr(PacketID));
{$ENDIF}
       finally
         LeaveCSect(ClientConnection.Network.FCSect^);
       end;
      finally
       PacketIDsToResend.Unlock;
      end; // finally
    until False; // loop
   end; // no Connect
 except
  on E:Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> ERROR:'+E.Message);
{$ENDIF}
    raise;
   end;
 end;
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT received all the packets');
{$ENDIF}
end; // WaitForSent

procedure CheckTermination;
begin
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer.CheckTermination> BEGIN');
{$ENDIF}
  try
    if ClientSession.ControlCode = MsgTerminate then
     begin
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer.CheckTermination> 40080');
{$ENDIF}
      raise EMsgException.Create(err, ErrorRClientSessionTerminated,[Integer(ClientSession.Session.SessionID)]);
     end;
  finally
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer.CheckTermination> END');
{$ENDIF}
  end;
end; // CheckTermination

begin // DoSendBuffer
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> START - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
try
// ClientSession.FCSect is already locked in caller (SendBuffer, Connect)
 try
  err := 40080;
  if (Code = MsgMessage)
  or (Code = MsgMessageAbort) then
   begin
    inc(err);
    errStr := 'message';
   end
  else
   begin
    errStr := 'command';
   end;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('ClientConnectionManager.DoSendBuffer> Refresh...');
aaWriteToLog('ClientConnectionManager.DoSendBuffer> ClientSession.Status = '+IntToStr(ClientSession.Status));
{$ENDIF}
(*
  SessionStatus := ClientSession.Status;
  while ClientSession.Status > MsgVacant do
*)
   begin
    LeaveCSect(ClientSession.FCSect);
    dec(ClientSession.Status);
   end;
  MsgRefresh; // ProcessMessages
//  while ClientSession.Status < SessionStatus do
   begin
    inc(ClientSession.Status);
    EnterCSect(ClientSession.FCSect);
   end;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('ClientConnectionManager.DoSendBuffer> ClientSession.Status = '+IntToStr(ClientSession.Status));
aaWriteToLog('ClientConnectionManager.DoSendBuffer> Refreshed!');
{$ENDIF}
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
    DataSize := ClientSession.Session.ConnectParams.PacketSize - SizeOf(TMsgPacketHeader);
    Header.Signature := MsgClientPacketSign;
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> Code='+IntToStr(Code));
  {$ENDIF}
    Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
    Header.Sender := ClientConnection.Network.LocalClientID;
  //  Header.ConnectionID := ClientConnection.ConnectionID;
    Header.ConnectionID := ClientSession.RemoteConnectionID;
  ////  if Code=MsgConnect then
    Header.SessionID := ClientSession.ServerSessionID;
  {$IFDEF MsgCommunicator}
    if TMsgClientSession(ClientSession.Session).Direct then
     if Code<>MsgConnected then
      Header.SessionID := ClientSession.Session.SessionID;
  {$ENDIF}
    Header.PacketID := 0;
    Header.ControlCode := Code;
    if (Code >= MsgNewRequest)
    or (Code = MsgEcho)
    or (Code = MsgTunning)
    or (Code = MsgServerSessionTunning)
    then
     begin
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('==============================================================');
  aaWriteToLog('CLIENT IS SENDING NEW REQUEST TO SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
  aaWriteToLog('==============================================================');
  {$ENDIF}
      inc(ClientSession.CurrentRequestID);
      ClientSession.Packets.Count := 0; // Delete old packets receved since ReceiveBuffer finished
      ClientSession.AnswerStatus := MsgNo;
      if ClientSession.ControlCode = MsgSuspend then
        ClientSession.ControlCode := MsgExecute;
     end;
    Header.CurrentRequestID := ClientSession.CurrentRequestID;
    if (Code = MsgMessage)
    or (Code = MsgMessageAbort) then
     begin
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('==============================================================');
  aaWriteToLog('CLIENT IS SENDING MESSAGE # '+IntToStr(ClientSession.ClientMessageID)+' TO ID # '+IntToStr(ClientSession.Session.ConnectParams.ServerID));
  aaWriteToLog('==============================================================');
  {$ENDIF}
      ClientSession.MsgSendStatus := MsgNotSent;
      Header.CurrentRequestID := ClientSession.ClientMessageID;
(*
// add to SendMessages
      New(msgStatus);
      msgStatus.Status := MsgSending;
      msgStatus.MessageID := Header.CurrentRequestID;
      msgStatus.NetworkClientID := Header.Recepient;
      msgStatus.ConnectionID := Header.ConnectionID;
      msgStatus.SessionID := Header.SessionID;
      msgStatus.PacketIDsToResend := TMsgThreadIntArray.Create;
      FSendMessages.Add(msgStatus);
*)
     end
    else
      ClientSession.SendStatus := MsgNotSent;
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('DoSendBuffer --------------------------------');
  aaWriteToLog('Header.ConnectionID = '+IntToStr(Header.ConnectionID));
  aaWriteToLog('Header.SessionID    = '+IntToStr(Header.SessionID));
  aaWriteToLog('Header.ControlCode  = '+IntToStr(Header.ControlCode));
  aaWriteToLog('DoSendBuffer --------------------------------');
  {$ENDIF}
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> create packets list...');
  {$ENDIF}
    Packets := TMsgList.Create;
    BytesSent := 0;
    i := DataSize;
{
    if Code = MsgMessage then
     begin
//      ClientSession.MsgSendStatus := MsgNotSent;
     end
    else
      ClientSession.SendStatus := MsgNotSent;
}
    repeat
//    while BytesSent < BufferSize do
//     begin // Create and send all packets
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> create packet #'+IntToStr(Header.PacketID));
{$ENDIF}
      New(Packet);
      Packets.Add(Packet);
      Packet.Buffer := MemoryManager.GetMem(ClientSession.Session.ConnectParams.PacketSize);
      if BytesSent + DataSize > BufferSize then
       DataSize := BufferSize - BytesSent;
      Packet.BufferSize := DataSize + SizeOf(TMsgPacketHeader);
      if BytesSent + DataSize = BufferSize then
        if Header.ControlCode <> MsgMessageAbort then
           Header.ControlCode := Header.ControlCode+MsgLastPacket;
      Move(Header^, Packet.Buffer^, SizeOf(TMsgPacketHeader));
      Move(Pointer(Integer(Buffer)+Header.PacketID*i)^, (Packet.Buffer+SizeOf(TMsgPacketHeader))^, DataSize);
      inc(Header.PacketID);
      // send packet
      EnterCSect(ClientConnection.Network.FCSect^);
      try
       ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
       ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
       CheckTermination;
       ClientConnection.Network.SendBuffer(Packet.Buffer, Packet.BufferSize);
      finally
       LeaveCSect(ClientConnection.Network.FCSect^);
      end;
//      sleep(0); // DO NOT UNCOMMENT!!! - The fastest speed is without sleep !!! - for single-packet requests
(* old optimization - not needed
{$IFDEF MsgCommunicator}
      if ((Header.PacketID) mod 4)=3 then
{$ELSE}
      if ((Header.PacketID) mod 8)=7 then
{$ENDIF}
        sleep(1); // For huge packets requests
*)
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> packet sent');
{$ENDIF}
      // packet has been sent
      BytesSent := BytesSent + DataSize;
    until BytesSent >= BufferSize;
    if Code <> MsgConnected then
      WaitForSent(Code);
  finally
    if (Code = MsgMessage)
    or (Code = MsgMessageAbort) then
     begin
      inc(ClientSession.ClientMessageID);
{$IFDEF LOG_CLIENT_MESSAGE_RESEND}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> ClientSession.ClientMessageID = '+IntToStr(ClientSession.ClientMessageID));
{$ENDIF}
     end;
// Remove all sent packets and free memory
    for i:= 0 to Packets.Count - 1 do
     begin
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> free packet #'+IntToStr(i));
{$ENDIF}
      Packet := Packets.Items[i];
      MemoryManager.FreeAndNilMem(Packet.Buffer);
      Dispose(Packet);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> freed');
{$ENDIF}
     end;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> free packets...');
{$ENDIF}
    Packets.Free;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> freed');
{$ENDIF}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> free header...');
{$ENDIF}
    MemoryManager.FreeAndNilMem(Header);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> freed');
{$ENDIF}
    CheckTermination;
  end;
 except
  if (Code = MsgMessage) then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> Abort Message...');
{$ENDIF}
    try
     dec(ClientSession.ClientMessageID);
     DoSendBuffer(ClientSession,ClientConnection,nil,0,MsgMessageAbort);
    except
    end;
   end; // message abort
  raise;
 end;
finally
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer - FINISH');
{$ENDIF}
end;
end; // DoSendBuffer


//------------------------------------------------------------------------------
// if encryption algorithm <> msg_Cipher_None then allocate buffer, fill it and return size
// otherwise return BufferSize = 0
//------------------------------------------------------------------------------
procedure TMsgClientConnectionManager.CreateAuthorizationBuffer(
                      CryptoInfo:     TMsgCryptoInfo;
                      out Buffer:     PAnsiChar;
                      out BufferSize: Integer
                                    );
var ms:           TMsgMemoryStream;
    buf:          PAnsiChar;
    crc32:        Cardinal;
    size:         Integer;
begin
  if CryptoInfo.CryptoAlgorithm = Msg_Cipher_None then
   begin
    BufferSize := 0;
    Exit;
   end;
  size := MsgDefaultAuthorizationBufferSize;
  buf := MemoryManager.GetMem(size);
  ms := TMsgMemoryStream.Create;
  try
    MsgGenerateRandomBuffer(buf,size);
    crc32 := MsgCountCRC(0,buf,size);
    SaveDataToStream(size,SizeOf(crc32),ms,11319);
    SaveDataToStream(crc32,SizeOf(crc32),ms,11320);
    MsgEncryptBuffer(CryptoInfo,buf,size);
    ms.WriteBuffer(buf^,size);
    BufferSize := ms.Size;
    Buffer := ms.Buffer;
    ms.Buffer := nil;
(*
    ms.SetBuffer(nil,0); // Msg 4.10 & ACR 5.00 difference
    { TODO -oAlex : move to msg with new memory engine }
*)
  finally
    ms.Free;
    MemoryManager.FreeAndNilMem(buf);
  end;
end; // CreateAuthorizationBuffer

// TMsgClientConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientPacketProcessorThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgClientPacketProcessorThread.Create(
                       Manager:       TMsgClientConnectionManager
                                            );
begin
 try
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> create...');
{$ENDIF}
  Manager.IncThreadCount;
  FManager := Manager;
  Error :=  ErrorRClient + ErrorRPacketProcessorThread
            + IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle));
  inherited Create(False);
  FRecreate := True;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('CLIENT LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRCreate + E.Message);
{$ENDIF}
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgClientPacketProcessorThread.Destroy;
begin
try
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> destroy...');
{$ENDIF}
 try
  FManager.FPacketProcessorThread := nil;
  inherited Destroy;
  FManager.DecThreadCount;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error + ErrorRDestroy + E.Message);
{$ENDIF}
   end;
 end;
finally
  if not Terminated then
  if FRecreate then
   begin
    sleep(MsgThreadRecreateSleep);
    if not Terminated then
    FManager.FPacketProcessorThread := TMsgClientPacketProcessorThread.Create(FManager);
   end;
end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgClientPacketProcessorThread.Execute;
label
  CheckFullMessage,
  KillPacket;
var
  Header:               PMsgPacketHeader;
  Connections:          TMsgList;
{$IFDEF MsgCommunicator}
  Session:              TMsgComBaseSession;
  ClientSession2:       PMsgClntSession;
{$ENDIF}
  ClientConnection:     PMsgClntConnection;
  SessionFound,
  ConnectionFound:      Boolean;
  i, j, k:              Integer;
{$IFDEF MsgCommunicator}
  AuBufSize:            Integer;
  UserID:               Cardinal;
  ConnectionParams:     PMsgConnectionParams;
  Application:          AnsiString;
{$ENDIF}
  Packets:              TMsgList;
  NetworkPacket:        PMsgNetworkPacket;
  Sessions:             TMsgList;
  recvItem:             PMsgRecvItem;
  msgStatus:            PMsgMessageStatus;
  AllPacketsReceived:   Boolean;
  Connecting,
  PacketAdded:          Boolean;
  SleepTime,
  EmptyTime:            Cardinal;

////////////////////////////////////////////////////////////////////////////////
function IsPacketActual: Boolean;
////////////////////////////////////////////////////////////////////////////////
begin
 Result := False;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Header.ControlCode = '+IntToStr(Header.ControlCode));
{$ENDIF}
 case Header.ControlCode of
  MsgMessageReceived,
  MsgMessagePacketResendRequest:
   begin
//    if (FManager.MessageStatus(Header,FManager.FSendMessages) <> MsgSending) then
    if ClientSession.MsgSendStatus = MsgSent then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> message is not sending now - kill packet');
{$ENDIF}
      Exit;
     end;
    if ClientSession.ClientMessageID <> Header.CurrentRequestID then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> ClientMessageID='+IntToStr(ClientSession.ClientMessageID)+' <> CurrentRequestID='+IntToStr(Header.CurrentRequestID));
{$ENDIF}
      Exit;
     end;
   end;
  MsgMessage,
  MsgMessageAbort,
  (MsgMessage + MsgLastPacket):
   begin
    if (FManager.MessageStatus(Header,FManager.FRecvMessages) = MsgReceived) then // not receiving or a new
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> message already received - kill packet');
{$ENDIF}
      TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(True),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
      Exit;
     end;
   end;
  MsgDisconnect,
  MsgPing:
   begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> disconnect or ping request is anytime welcome');
{$ENDIF}
    Result := True;
    Exit;
   end;
  else
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> data packet');
{$ENDIF}
    if ClientSession.CurrentRequestID <> Header.CurrentRequestID then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> ClientSession.CurrentRequestID = '+IntToStr(ClientSession.CurrentRequestID)+' <> Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
{$ENDIF}
      if ClientSession.CurrentRequestID > Header.CurrentRequestID then // old comand answer
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> old command - send ackn');
{$ENDIF}
        TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
       end;
      Exit;
     end;
  end; // else of case
 Result := True;
end; // IsPacketActual

////////////////////////////////////////////////////////////////////////////////
function IsAllPacketsReceived: Boolean;
////////////////////////////////////////////////////////////////////////////////
var
  i:                    Integer;
  Packets:              TMsgList;
begin // Are all packets received?
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('IsAllPacketsReceived> start');
{$ENDIF}
Result := False;
try
 Packets := recvItem.Packets.LockList;
 try
  if Packets = nil then
   begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('IsAllPacketsReceived> Packets = nil');
{$ENDIF}
    Exit;
   end;
  if Packets.Count = 0 then
   begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('IsAllPacketsReceived> Packets.Count = 0');
{$ENDIF}
    Exit;
   end;
  Result := True;
  for i:=0 to Packets.Count-1 do
   if Packets.Items[i] = nil then
    begin
     Result := False;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('IsAllPacketsReceived> i = '+IntToStr(i));
{$ENDIF}
     break;
    end;
 finally
  recvItem.Packets.UnlockList;
 end;
finally
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
if Result then
aaWriteToLog('IsAllPacketsReceived> Yes')
else
aaWriteToLog('IsAllPacketsReceived> No')
{$ENDIF}
end;
end; // function IsAllPacketsReceived: Boolean;


procedure StartResendRequest;
begin
  if ClientSession.AnswerStatus <> MsgFull then // Last packet received, but answer is not full
   begin
    EnterCSect(ClientSession.FCSect);
    try
     if ClientSession.ResendRequestThread = nil then
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> : Start resending thread');
{$ENDIF}
       ClientSession.ResendRequestThread := TMsgClientResendRequestThread.Create(FManager, ClientSession, NetworkPacket.Packet.Buffer, ClientConnection.Network, NetworkPacket.FromHost, NetworkPacket.FromPort);
      end;
    finally
     LeaveCSect(ClientSession.FCSect);
    end;
   end;
end; // StartResendRequest


////////////////////////////////////////////////////////////////////////////////
begin // TMsgClientPacketProcessorThread.Execute
////////////////////////////////////////////////////////////////////////////////
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread.Execute> START');
{$ENDIF}
try
 EmptyTime := GetTickCount;
 SleepTime := 1;
 repeat
  PacketAdded := False;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
//aaWriteToLog('TMsgClientPacketProcessorThread.Execute> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
  sleep(SleepTime);
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
//aaWriteToLog('TMsgClientPacketProcessorThread.Execute> up!');
{$ENDIF}
  if Terminated then
    Exit;
  try // except - continue loop
   Packets := FManager.FPacketQueue.LockList;
   try
    if Packets.Count = 0 then
     begin
      if (GetTickCount >= (EmptyTime + MsgPacketProcessTimeOut)) then
       begin
        SleepTime := 1; // To avoid 100% CPU usage
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('ClientPacketProcessorThread.Execute> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
       end;
      Continue;
     end;
    EmptyTime := GetTickCount;
    SleepTime := 0;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('ClientPacketProcessorThread.Execute> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread.Execute> PacketQueue.Count = '+IntToStr(Packets.Count));
{$ENDIF}
    NetworkPacket := PMsgNetworkPacket(Packets.Items[0]);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread.Execute> delete NetworkPacket from queue...');
{$ENDIF}
    Packets.Delete(0);
   finally
    FManager.FPacketQueue.UnlockList;
   end;
   try // finally - free packet
    SessionFound := False;
    Connecting := False;
    Header := Pointer(NetworkPacket.Packet.Buffer);
// Check size
    if (NetworkPacket.Packet.BufferSize < SizeOf(TMsgPacketHeader)) then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('CLIENT: too small packet size = '+IntToStr(NetworkPacket.Packet.BufferSize));
{$ENDIF}
      Exit;
     end;
// Check sign
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread.Execute> Check sign = '+Header.Signature);
{$ENDIF}
    if (Header.Signature <> MsgServerPacketSign)
{$IFDEF MsgCommunicator}
    and (Header.Signature <> MsgClientPacketSign)
{$ENDIF}
    then
      goto KillPacket;
// Check for errors
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread.Execute> CheckSum...');
{$ENDIF}
    if CheckSum(NetworkPacket.Packet.Buffer, NetworkPacket.Packet.BufferSize) <> Header.CheckSum then
     begin
      TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.PacketResendRequest,
                                Integer(NetworkPacket.Packet.Buffer),
                                Integer(Pointer(NetworkPacket.Network)),
                                Integer(PAnsiChar(NetworkPacket.FromHost)),
                                NetworkPacket.FromPort,0); // call PacketResendRequest
      goto KillPacket;
     end;
{$IFDEF MsgCommunicator}
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('sign - OK!');
{$ENDIF}
// Check for direct connect request
    if    // first packet in multi-packet connect request
    ((Header.ControlCode=MsgConnect) and (Header.PacketID=0))
    or    // single-packet connect request
    ((Header.ControlCode=(MsgConnect+MsgLastPacket)) and (Header.PacketID=0))
    then
     begin
      Connecting := True;
      PacketAdded := True;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('create connect thread...');
if ClientSession=nil then
aaWriteToLog('ClientSession=nil')
else
begin
aaWriteToLog('ClientSession='+IntToStr(Integer(ClientSession)));
aaWriteToLog('ClientSession.Session='+IntToStr(Integer(ClientSession.Session)));
end;
{$ENDIF}
      if ClientSession=nil then
        TMsgSendingThread.Create(nil,FManager,nil,Integer(Pointer(NetworkPacket)),0,0,0,0)
      else
        TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,nil,Integer(Pointer(NetworkPacket)),0,0,0,0); // call connect procedure
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('sleep...');
{$ENDIF}
      sleep(0);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('connect thread created!');
{$ENDIF}
      Continue;
     end;
{$ENDIF MsgCommunicator}
    Header.Recepient := Header.Sender;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread>');
aaWriteToLog('  Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('  Header.PacketID         = '+IntToStr(Header.PacketID));
aaWriteToLog('  Header.ControlCode      = '+IntToStr(Header.ControlCode));
aaWriteToLog('  Header.ConnectionID     = '+IntToStr(Header.ConnectionID));
aaWriteToLog('  Header.SessionID        = '+IntToStr(Header.SessionID));
aaWriteToLog('TMsgClientPacketProcessorThread> Connections');
{$ENDIF}
// verify ConnectionID existing
    ConnectionFound := False;
    Connections := FManager.FConnections.LockList;
    try
     for i:=0 to Connections.Count-1 do
      begin
       ClientConnection := Connections.Items[i];
       if (ClientConnection.ConnectionID = Header.ConnectionID)
       or (Header.ControlCode = MsgPacketResendRequest)
       or (Header.ControlCode = MsgMessagePacketResendRequest)
       then
         begin
          ConnectionFound := True;
          break;
         end;
      end;
    finally
     FManager.FConnections.UnlockList;
    end;
    if not ConnectionFound then
      goto KillPacket;
// verify SessionID in this connection
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> '
              +IntToStr(ClientConnection.Network.LocalPort)+'<<< '
              +IntToStr(Header.CurrentRequestID)+' : '
              +IntToStr(Header.PacketID)+' / '
              +IntToStr(Header.ControlCode)+' <<< '
              +NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort));
{$ENDIF}
    Sessions := FManager.FSessions.LockList;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Sessions locked');
{$ENDIF}
    try
     for i := Sessions.Count-1 downto 0 do
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread>');
aaWriteToLog('           Sessions.Count='+IntToStr(Sessions.Count));
aaWriteToLog('           i='+IntToStr(i));
{$ENDIF}
       ClientSession := Sessions.Items[i];
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('           Header.ConnectionID             = '+IntToStr(Header.ConnectionID));
aaWriteToLog('           ClientSession.ConnectionID      = '+IntToStr(ClientSession.ConnectionID));
aaWriteToLog('           RemoteConnectionID              = '+IntToStr(ClientSession.RemoteConnectionID));
aaWriteToLog('           @ClientSession = '+IntToHex(Integer(ClientSession),8));
aaWriteToLog('           Header.SessionID                = '+IntToStr(Integer(Header.SessionID)));
aaWriteToLog('           ClientSession.ServerSessionID   = '+IntToStr(Integer(ClientSession.ServerSessionID)));
if ClientSession.Session <> nil then
aaWriteToLog('           ClientSession.Session.SessionID = '+IntToStr(Integer(ClientSession.Session.SessionID)))
else
aaWriteToLog('           ClientSession.Session = nil');
{$ENDIF}
       if ClientSession.Session = nil then
         continue;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> check session...');
{$ENDIF}
       if
{$IFDEF MsgCommunicator}
          (
            (not (TMsgClientSession(ClientSession.Session).Direct))
            and
            (ClientSession.ConnectionID = Header.ConnectionID)
            and
            (ClientSession.ServerSessionID = Header.SessionID)
          )
       or
{$ELSE}
          (
            (ClientSession.ConnectionID = Header.ConnectionID)
            and
            (ClientSession.ServerSessionID = Header.SessionID)
          )
{$ENDIF}
{$IFDEF MsgCommunicator}
          ( // direct messaging
            (
             (Header.ControlCode <> MsgConnected)
             and
             (Header.ControlCode <> (MsgConnected + MsgLastPacket))
            )
            and
            (TMsgClientSession(ClientSession.Session).Direct)
            and
            (ClientSession.RemoteConnectionID = Header.ConnectionID)
            and
            (ClientSession.ServerSessionID = Header.SessionID)
          )
       or (
            (
//              (Header.ControlCode = MsgAllPacketsReceived) // disconnect ackn (possible, other commands in the future, too)
//              or
              (Header.ControlCode = MsgPacketResendRequest)
              or
              (Header.ControlCode = MsgMessagePacketResendRequest)
              or
              (Header.ControlCode = MsgConnected)
              or
              (Header.ControlCode = (MsgConnected + MsgLastPacket))
            )
            and
            (TMsgClientSession(ClientSession.Session).Direct)
            and
            (ClientSession.Session.SessionID = Header.SessionID)
            and
            (ClientSession.RemoteConnectionID = Header.ConnectionID)
          )
{$ENDIF}
       then
         begin
          SessionFound := True;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
          inc(ClientSession.Status);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('try to enter ClientSession.FCSect...');
{$ENDIF}
          EnterCSect(ClientSession.FCSect);
          break;
         end;
      end;
    finally
     FManager.FSessions.UnlockList;
    end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
if SessionFound then
aaWriteToLog('           Session Found')
else
aaWriteToLog('           Session Not Found')
;
{$ENDIF}
    if not SessionFound then
      goto KillPacket;

(*
// is listener stoped?
    if (Header.ControlCode = MsgMessage)
    or (Header.ControlCode = MsgMessage + MsgLastPacket)
    then
     begin
      if ClientSession.MsgControlCode <> MsgExecute then
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Messages Listeninig blocked');
{$ENDIF}
        goto KillPacket;
       end;
     end
    else
      if ClientSession.ControlCode <> MsgExecute then
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Commands Listeninig blocked');
{$ENDIF}
       if not // Disconnect acknowledgement
       (
  //      (ClientSession.ControlCode = MsgTerminate)
  //      and
        (ClientSession.CurrentRequestID = Header.CurrentRequestID)
        and
        (Header.ControlCode = MsgAllPacketsReceived)
       )
       then
          goto KillPacket;
       end;
*)
// verify Sender
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Sender');
{$ENDIF}
    if ClientSession.Session.ConnectParams.ServerID <> Header.Sender then
     begin
{$IFDEF MsgCommunicator}
      if (ClientSession.Session.ConnectParams.ServerID = Integer(MSG_INVALID_USER_ID)) // new direct session
      and ((Header.ControlCode = MsgConnected)                // just connected
        or (Header.ControlCode = MsgConnected+MsgLastPacket))
      then
       begin
        ClientSession.Session.FConnectParams.ServerID := Header.Sender;
       end
      else
{$ENDIF}
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> (ServerID = '+IntToStr(ClientSession.Session.ConnectParams.ServerID)+') <> (Sender = '+IntToStr(Header.Sender)+')');
aaWriteToLog('TMsgClientPacketProcessorThread> Recepient = '+IntToStr(Header.Recepient)+')');
{$ENDIF}
        goto KillPacket;
       end;
     end;
// check CurrentRequestID
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
{$ENDIF}
    if not IsPacketActual then
      goto KillPacket;
// Process service packet
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Process service packet');
{$ENDIF}
    if (Header.ControlCode = MsgConnected)
    or (Header.ControlCode = (MsgConnected+MsgLastPacket))
      then ClientSession.ServerSessionID := Header.SessionID; // To allow disconnect immediately
    case Header.ControlCode of
//------------------------------------------------------------------------------
     MsgDisconnect:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> MsgDisconnect');
{$ENDIF}
       if Header.SessionID = INVALID_SESSION_ID then
        begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> Header.SessionID = INVALID_SESSION_ID -> Kill!');
{$ENDIF}
         goto KillPacket;
        end;
(*
       if ClientSession.LiveListenerThreads > 0 then
        begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('Listener Thread # '+'TMsgClientPacketProcessorThread> : ClientSession.LiveListenerThreads='+IntToStr(ClientSession.LiveListenerThreads)+' -> Kill!');
{$ENDIF}
         goto KillPacket;
        end;
       inc(ClientSession.LiveListenerThreads);
*)
       try
        ClientSession.ControlCode := MsgTerminate;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> SendACKN');
{$ENDIF}
        FManager.SendAcknowledgement(ClientSession,False,Header.CurrentRequestID);
(* Do not use thread - must finish before session deleting
       TMsgSendingThread.Create(FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
*)
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> Session.OnDisconnect');
{$ENDIF}
        if ClientSession.Session <> nil then
          TMsgClientSession(ClientSession.Session).OnDisconnect;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> FSessions.Remove...');
{$ENDIF}
        if not FManager.FListenerStoped then
          if FManager.FSessions <> nil then
            FManager.FSessions.Remove(ClientSession);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> DeleteSession...');
{$ENDIF}
        LeaveCSect(ClientSession.FCSect);
        dec(ClientSession.Status); // allow deleting
        SessionFound := False; // CS left, to do not leave CS in finally section
        if not FManager.FListenerStoped then
          FManager.DeleteSession(ClientSession);
       finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TMsgClientPacketProcessorThread> End of Disconnect');
{$ENDIF}
       end;
      end;
//------------------------------------------------------------------------------
     MsgPing:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> send ping answer...');
{$ENDIF}
       TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendPing,
                               Integer(Pointer(ClientSession)),0,0,0,0); // call SendPing
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     MsgPacketResendRequest:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> MsgPacketResendRequest ID='+IntToStr(Header.PacketID));
{$ENDIF}
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('TMsgClientPacketProcessorThread> Request ID = '+IntToStr(Header.PacketID));
{$ENDIF}
       ClientSession.PacketIDsToResend.Add(Header.PacketID);
{$IFDEF PACKET_RESEND_REQUEST}
       j := (NetworkPacket.Packet.BufferSize - SizeOf(TMsgPacketHeader)) div SizeOf(TMsgPacketID);
       for i:=0 to j-1 do
        begin
         k := Integer(TMsgPacketID((NetworkPacket.Packet.Buffer+SizeOf(TMsgPacketHeader)+(i*SizeOf(TMsgPacketID)))^));
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('TMsgClientPacketProcessorThread> Request ID = '+IntToStr(k));
{$ENDIF}
         ClientSession.PacketIDsToResend.Add(k);
        end;
{$ENDIF}
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     MsgMessagePacketResendRequest:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> MsgMessagePacketResendRequest');
{$ENDIF}
(*
       msgStatus := FManager.FindMessage(FManager.FSendMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
       if msgStatus <> nil then
        begin
         msgStatus.PacketIDsToResend.Add(Header.PacketID);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> resend request added');
{$ENDIF}
        end;
*)
       ClientSession.MsgPacketIDsToResend.Add(Header.PacketID);
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     MsgAllPacketsReceived:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> MsgAllPacketsReceived');
{$ENDIF}
       ClientSession.SendStatus := MsgSent;
       ClientSession.PacketIDsToResend.SetSize(0);
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     MsgMessageReceived:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> MsgMessageReceived');
{$ENDIF}
{
       msgStatus := FManager.FindMessage(FManager.FSendMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
       if msgStatus <> nil then
        begin
         msgStatus.Status := MsgSendOK;
         msgStatus.PacketIDsToResend.SetSize(0);
        end;
}
       ClientSession.MsgSendStatus := MsgSent;
       ClientSession.MsgPacketIDsToResend.SetSize(0);
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     MsgMessageAbort:
//------------------------------------------------------------------------------
      begin
       try
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> SendAcknowledgement...');
{$ENDIF}
         TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                                 Integer(Pointer(ClientSession)),Integer(True),
                                 Header.CurrentRequestID,0,0); // call SendAcknowledgement
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> FindMessage...');
{$ENDIF}
         msgStatus := FManager.FindMessage(FManager.FRecvMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
         if (msgStatus <> nil) then
          begin
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> Remove status...');
{$ENDIF}
           FManager.FRecvMessages.Remove(msgStatus);
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> free packets ID to resend...');
{$ENDIF}
           if msgStatus.PacketIDsToResend <> nil then
             msgStatus.PacketIDsToResend.Free;
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> Dispose status...');
{$ENDIF}
           Dispose(msgStatus);
          end;
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> FindMessageInQueue');
{$ENDIF}
         recvItem := FManager.FindMessageInQueue(Header);
         if (recvItem <> nil) then
          begin
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> Remove...');
{$ENDIF}
           FManager.FMessageQueue.Remove(recvItem);
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> Free packets...');
{$ENDIF}
           FManager.FreePackets(recvItem.Packets);
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> packets free...');
{$ENDIF}
           recvItem.Packets.Free;
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TMsgClientPacketProcessorThread> Dispose...');
{$ENDIF}
           Dispose(recvItem);
          end;
        finally
        end;
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     MsgMessage,
     (MsgMessage+MsgLastPacket):
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> message packet');
{$ENDIF}
       msgStatus := FManager.FindMessage(FManager.FRecvMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
       if (msgStatus <> nil) then
        if (msgStatus.Status = MsgReceived) then
         begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Message is already received - Send ACKN');
{$ENDIF}
          TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(True),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
          goto KillPacket;
         end;
       if FManager.MessageStatus(Header,FManager.FRecvMessages) = MsgNotFound then
        begin
// add to RecvMessages
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> New message - add to RecvMessages');
{$ENDIF}
         New(msgStatus);
         msgStatus.Status := MsgReceiving;
         msgStatus.MessageID := Header.CurrentRequestID;
         msgStatus.NetworkClientID := Header.Recepient;
         msgStatus.ConnectionID := Header.ConnectionID;
         msgStatus.SessionID := Header.SessionID;
         msgStatus.PacketIDsToResend := nil;
         FManager.FRecvMessages.Add(msgStatus);
// add to MessageQueue
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> New message - add to MessageQueue');
{$ENDIF}
         New(recvItem);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgClientPacketProcessorThread> New RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
         recvItem.Session := ClientSession;
         recvItem.RecvStatus := MsgStart;
         recvItem.Network := NetworkPacket.Network;
         recvItem.RemotePort := NetworkPacket.FromPort;
         recvItem.RemoteHost := NetworkPacket.FromHost;
         recvItem.Packets := TMsgThreadList.Create('recvItem from '+recvItem.RemoteHost+':'+IntToStr(recvItem.RemotePort), false, MsgDefaultMsgPackets);
         FManager.FMessageQueue.Add(recvItem);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Added RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgClientPacketProcessorThread> Added RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TMsgClientPacketProcessorThread> Added RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
        end
       else // MessageStatus = MsgReceiving
        begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> MessageStatus = MsgReceiving');
{$ENDIF}
         recvItem := FManager.FindMessageInQueue(Header);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> OK');
{$ENDIF}
         if (recvItem = nil) then
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> ERROR: Message not found in queue');
{$ENDIF}
           goto KillPacket;
          end;
        end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> OK 2');
aaWriteToLog('TMsgClientPacketProcessorThread> Found RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
// Is this message packet already stored?
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Is this message packet already stored?');
{$ENDIF}
//       if recvItem.Packets.Count > 0 then // list exists
        if ((Header.PacketID+1) <= recvItem.Packets.Count) then // old packet
         if (recvItem.Packets.Items[Header.PacketID] <> nil) then // already received
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Existing packet');
aaWriteToLog('Packets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
{$ENDIF}
          if (Header.ControlCode >= MsgLastPacket) then // Last packet
           goto CheckFullMessage // to allow extracting after resending
          else
           goto KillPacket; // Do not replace correct packets with doubles
          end;
// Add correct received message packet
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> New packet');
if ((Header.PacketID+1) <= recvItem.Packets.Count) then // old packet
aaWriteToLog('@Items='+IntToStr(Integer(recvItem.Packets.Items[Header.PacketID])));
{$ENDIF}
       if recvItem.Packets.Count < (Header.PacketID + 1) then // New Packet - Allocate
        begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Allocate');
aaWriteToLog('MsgPackets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
{$ENDIF}
         recvItem.Packets.Count := (Header.PacketID + 1); // List fills hole by Nils
        end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Add packet');
aaWriteToLog('MsgPackets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
{$ENDIF}
       recvItem.Packets.Items[Header.PacketID] := NetworkPacket.Packet;
       PacketAdded := True;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> packet added');
aaWriteToLog('MsgPackets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
aaWriteToLog('@Items='+IntToStr(Integer(recvItem.Packets.Items[Header.PacketID])));
aaWriteToLog('TMsgClientPacketProcessorThread> 6 Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
CheckFullMessage: // Is it the last packet?
       if (Header.ControlCode >= MsgLastPacket) then // Last packet
        begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Are all packets received?');
{$ENDIF}
         Header.ControlCode := Header.ControlCode - MsgLastPacket;
// Are all packets received?
         msgStatus := FManager.FindMessage(FManager.FRecvMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
         if IsAllPacketsReceived then
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> AllPacketsReceived!');
{$ENDIF}
           recvItem.RecvStatus := MsgFull;  // Allow to extract buffer
           if (msgStatus <> nil) then
             msgStatus.Status := MsgReceived;
           TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(True),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> SendAcknowledgement - finish');
{$ENDIF}
          end
         else
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> mark for request resending');
{$ENDIF}
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TMsgClientPacketProcessorThread> mark for request resending recvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
           recvItem.RecvStatus := MsgNotFull;  // Allow to request a resending of absent packets
          end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> finish message processing!!!');
{$ENDIF}
        end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> message processing finished!!');
{$ENDIF}
      end; // message packet process
//------------------------------------------------------------------------------
     MsgNewRequest,
{$IFNDEF MsgCommunicator}
     ACRClientCommand,
     ACRServerCommand,
{$ENDIF}
     MsgConnected,
     MsgLastPacket..(MsgMessage+MsgLastPacket-1),
     (MsgMessage+MsgLastPacket+1)..127,
     MsgNoAction:
//------------------------------------------------------------------------------
      begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : Data packet');
  {$ENDIF}
       if Header.CurrentRequestID > 0 then // to allow MsgConnected receiving
       if (ClientSession.CurrentRequestID = Header.CurrentRequestID) then
       if (ClientSession.AnswerStatus = MsgFull) then // lost acknowledgement
        begin
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientPacketProcessorThread> lost acknowledgement - Send ACKN');
{$ENDIF}
         TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
  {$IFDEF DEBUG_LOG_NETWORK}
  aaWriteToLog('--------------------------------------------------------------');
  aaWriteToLog('CLIENT received existing packet while the answer received fully');
  {$ENDIF}
         goto KillPacket; // Do not replace correct packets with doubles
        end;
       if (ClientSession.CurrentRequestID > Header.CurrentRequestID) then // old request
        begin
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TMsgClientPacketProcessorThread> old request - Send ACKN');
{$ENDIF}
         TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
  {$IFDEF DEBUG_LOG_NETWORK}
  aaWriteToLog('--------------------------------------------------------------');
  aaWriteToLog('CLIENT received existing packet while the answer received fully');
  {$ENDIF}
         goto KillPacket; // Do not replace correct packets with doubles
        end;
// is the answer was fully received?
        if ClientSession.ControlCode = MsgSuspend then
         begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> the answer was fully received!');
{$ENDIF}
           goto KillPacket;
         end;
// Is this packet already stored?
        if ClientSession.Packets <> nil then // list exists
         if ((Header.PacketID+1) <= ClientSession.Packets.Count) then // old packet
         if (ClientSession.Packets.Items[Header.PacketID] <> nil) then // already received
          begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  {$ENDIF}
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : Existing packet');
  aaWriteToLog('           @Items='+IntToStr(Integer(ClientSession.Packets.Items[Header.PacketID])));
  {$ENDIF}
  {$IFDEF DEBUG_LOG_NETWORK}
  aaWriteToLog('--------------------------------------------------------------');
  aaWriteToLog('CLIENT received existing packet');
  {$ENDIF}
           if Header.ControlCode >= MsgLastPacket then
             StartResendRequest;
           goto KillPacket; // Do not replace correct packets with doubles
          end;
  // Add correct received data packet
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : New packet');
  if ((Header.PacketID+1) <= ClientSession.Packets.Count) then // old packet
  aaWriteToLog('           @Items='+IntToStr(Integer(ClientSession.Packets.Items[Header.PacketID])));
  {$ENDIF}
       if ClientSession.Packets = nil then
         begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Packets = nil');
  {$ENDIF}
          goto KillPacket;
         end;
       if Terminated then
         begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Terminated');
  {$ENDIF}
          goto KillPacket;
         end;
  // Add packet
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> : BufferSize='+IntToStr(NetworkPacket.Packet.BufferSize));
{$ENDIF}
       if ClientSession.Packets.Count < (Header.PacketID + 1) then // New Packet - Allocate
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : Allocate');
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  {$ENDIF}
         ClientSession.Packets.Count := (Header.PacketID + 1); // List fills hole by Nils
        end;
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  aaWriteToLog('TMsgClientPacketProcessorThread> : Add packet');
  {$ENDIF}
       ClientSession.Packets.Items[Header.PacketID] := NetworkPacket.Packet;
       PacketAdded := True;
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  aaWriteToLog('TMsgClientPacketProcessorThread> : packet added');
  {$ENDIF}
  // Are all packets received?
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           @Items='+IntToStr(Integer(ClientSession.Packets.Items[Header.PacketID])));
  aaWriteToLog('TMsgClientPacketProcessorThread> : Are all packets received?');
  {$ENDIF}
       AllPacketsReceived := False;
       if
        (
          (ClientSession.AnswerStatus = MsgNotFull) and
          (ClientSession.Packets.Count > (Header.PacketID + 1)) // maybe last hole
        )
        or
        (Header.ControlCode >= MsgLastPacket) // Last packet
       then
        begin
         AllPacketsReceived := True;
         for i:=0 to ClientSession.Packets.Count-1 do
          if ClientSession.Packets.Items[i] = nil then
           begin
            AllPacketsReceived := False;
            break;
           end;
        end;
       if AllPacketsReceived then
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : Yes');
  {$ENDIF}
         ClientSession.AnswerStatus := MsgFull;  // Allow to extract buffer
         ClientSession.ControlCode := MsgSuspend;
        end
       else
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : No');
  {$ENDIF}
         if ClientSession.AnswerStatus = MsgNo then
           ClientSession.AnswerStatus := MsgStart;
        end;
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : Left!');
  {$ENDIF}
  // Is it the last packet?
       if Header.ControlCode >= MsgLastPacket then
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : MsgLastPacket');
  {$ENDIF}
         if ClientSession.AnswerStatus <> MsgFull then // Last packet received, but answer is not full
           ClientSession.AnswerStatus := MsgNotFull;
         Header.ControlCode := Header.ControlCode - MsgLastPacket;
         StartResendRequest;
        end;
  // Is Answer full?
         if ClientSession.AnswerStatus = MsgFull then
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> : Full answer');
{$ENDIF}
           if ClientSession.ResendRequestThread <> nil then
            begin
             try
              ClientSession.ResendRequestThread.Terminate;
             except
             end;
             ClientSession.ResendRequestThread := nil;
            end;
  // To allow GetAnswer=Connected while Connect procedure
           if (Header.ControlCode = MsgConnected)
            then
             begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : MsgConnected');
  {$ENDIF}
              ClientSession.SendStatus := MsgSent;
  {$IFDEF MsgCommunicator}
              if TMsgClientSession(ClientSession.Session).Direct then
                ClientSession.Session.ConnectedUser(
                  TMsgClientSession(ClientSession.Session).RemoteUser.UserID,
                  NetworkPacket.FromHost, NetworkPacket.FromPort
                                                  );
              Continue;
   {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TMsgClientPacketProcessorThread> : ConnectedUser!');
   {$ENDIF}
  {$ENDIF}
             end
            else
             begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> : SendAcknowledgement - start');
{$ENDIF}
              FManager.SendAcknowledgement(ClientSession,False,Header.CurrentRequestID);
(* Do not use thread - 16 msec delay on network
              TMsgSendingThread.Create(FManager,@TMsgClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
*)
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> : SendAcknowledgement - finish');
{$ENDIF}
  {$IFDEF MsgCommunicator}
              if TMsgClientSession(ClientSession.Session).Direct then
                if (Header.ControlCode = MsgInitProgressSend)
//              or (Header.ControlCode = )
                then  // enabled commands
                 begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Received Command = '+IntToStr(Header.ControlCode));
{$ENDIF}
                  sleep(0); // to start send ackn first
                  TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgSendingThread.ExecuteReceivedCommand,
                               Integer(Pointer(ClientSession)),Header.ControlCode,
                               0,0,0); // call ExecuteReceivedCommand

                  Continue;
                 end;
  {$ENDIF}
             end;
           if (Header.ControlCode = MsgEcho)
           or (Header.ControlCode = MsgTunning)
           then
            begin
             TMsgSendingThread.Create(TMsgNetworkSession(ClientSession.Session),
                               FManager,@TMsgSendingThread.Echo,
                                Integer(ClientSession.Session),
                                Integer(MsgNoAction),0,0,0); // receive then send echo
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('CLIENT SENT ECHO TO SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
{$ENDIF}
            end;
          end; // answer is full
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> : ***** END OF DATA PACKET *****');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
      end // data packet process
     else
       raise EMsgException.Create(40022, ErrorRUnknownControlCode, [Header.ControlCode]);
    end; // packet process
KillPacket:
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> KillPacket:');
{$ENDIF}
   finally
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> finally...');
{$ENDIF}
    if SessionFound then
     begin
      LeaveCSect(ClientSession.FCSect);
      dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> CS left!');
{$ENDIF}
     end;
    if not PacketAdded then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('Free Buffer...');
{$ENDIF}
       if NetworkPacket.Packet.Buffer <> nil then
         MemoryManager.FreeAndNilMem(NetworkPacket.Packet.Buffer);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('Dispose Packet...');
{$ENDIF}
       Dispose(NetworkPacket.Packet);
     end; // kill packet
    if not Connecting then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('Dispose NetworkPacket...');
{$ENDIF}
      Dispose(NetworkPacket);
     end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('Finalization OK! Get next packet...');
{$ENDIF}
   end;
  except
   on E: Exception do
   begin
   try
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('ERROR: ' + Error + ErrorRExecute + E.Message);
{$ENDIF}
    if (ClientSession = nil)
    or (ClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRPacketProcessorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  ' Session does not exist. '+
                  E.Message;
      Sessions := FManager.FSessions.LockList;
      try
       if Sessions.Count > 0 then
        begin
         ClientSession := Sessions.Items[0];
         if ClientSession.Session <> nil then
           TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgClientPacketProcessorThread,-1,
                  Error);
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgClientPacketProcessorThread,-1,
                  ErrorRClient+ErrorRPacketProcessorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message);
    FRecreate := True;
    Exit;
   except
   end;
   end;
  end;
 until False;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TMsgClientPacketProcessorThread> Execute finished!');
{$ENDIF}
except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
   end;
end;
end; // TMsgClientPacketProcessorThread.Execute



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgClientResendRequestThread.Create(
                       Manager:           TMsgClientConnectionManager;
                       ClientSession:     PMsgClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TMsgNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                                            );
var
  Error:        AnsiString;
  Header:       PMsgPacketHeader;
  Sessions:     TMsgList;
begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> START');
aaWriteToLog('ClientResendRequestThread> '+Network.LocalHost+':'+IntToStr(Network.LocalPort)
                                          +', request # '+IntToStr(PMsgPacketHeader(Buffer).CurrentRequestID)
                                          +' - START', NetLog);
{$ENDIF}
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FClientSession := ClientSession;
  FBuffer := MemoryManager.AllocMem(SizeOf(TMsgPacketHeader));
  Move(Buffer^,FBuffer^,SizeOf(TMsgPacketHeader));
  Header := PMsgPacketHeader(FBuffer);
  Header.Recepient := FClientSession.Session.ConnectParams.ServerID;
  FNetwork := Network;
  FHost := FromHost;
  FPort := FromPort;
  inherited Create(False);
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog('CLIENT RESEND REQUEST THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - STARTED');
{$ENDIF}
 except
  on E: Exception do
   begin
    try
    if (ClientSession = nil)
    or (ClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  ' Session does not exist. '+
                  E.Message;
      Sessions := FManager.FSessions.LockList;
      try
       if Sessions.Count > 0 then
        begin
         ClientSession := Sessions.Items[0];
         if ClientSession.Session <> nil then
           TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgClientResendRequestThread,-1,
                  Error)
         else
          begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgClientResendRequestThread,-1,
                  ErrorRClient+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message);
    except
    end;
    Destroy;
   end;
 end;
 FRecreate := True;
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> Started');
aaWriteToLog('ClientResendRequestThread> '+Network.LocalHost+':'+IntToStr(Network.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(Buffer).CurrentRequestID)+' - STARTED', NetLog);
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgClientResendRequestThread.Destroy;
var
  Error:        AnsiString;
  Sessions:     TMsgList;
begin
 try
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> Finish');
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(FBuffer).CurrentRequestID)+' - FINISH...', NetLog);
{$ENDIF}
  if not Terminated then
  if FRecreate = True then
    if (FClientSession <> nil) then
      if (FClientSession.Session <> nil) then
        if (FClientSession.AnswerStatus = MsgNotFull) then
          if (FClientSession.CurrentRequestID = PMsgPacketHeader(FBuffer).CurrentRequestID) then
           begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(FBuffer).CurrentRequestID)+' - RECREATE...', NetLog);
{$ENDIF}
            sleep(MsgThreadRecreateSleep);
            if not Terminated then
              FClientSession.ResendRequestThread := TMsgClientResendRequestThread.Create(FManager, FClientSession,
                                                      FBuffer,FNetwork,FHost,FPort);
           end;
  MemoryManager.FreeAndNilMem(FBuffer);
  EnterCSect(FClientSession.FCSect);
  if FClientSession.ResendRequestThread <> nil then
    FClientSession.ResendRequestThread := nil;
  LeaveCSect(FClientSession.FCSect);
  inherited Destroy;
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog('CLIENT ResendRequest THREAD - FINISHED');
{$ENDIF}
  FManager.DecThreadCount;
 except
  on E: Exception do
   begin
    try
    FRecreate := True;
    if (FClientSession = nil)
    or (FClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  ' Session does not exist. '+
                  E.Message;
      Sessions := FManager.FSessions.LockList;
      try
       if Sessions.Count > 0 then
        begin
         FClientSession := Sessions.Items[0];
         if FClientSession.Session <> nil then
           TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  Error)
         else
          begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message);
    except
    end;
   end;
 end;
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> Finished');
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+' - FINISHED', NetLog);
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgClientResendRequestThread.Execute;
var
  Error:              AnsiString;
  i, j, Count:        Integer;
//  AllPacketsReceived: Boolean;
  Sessions:           TMsgList;
begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(FBuffer).CurrentRequestID)+' - EXECUTE...', NetLog);
{$ENDIF}
 try
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** CLIENT RESEND REQUEST START *****');
{$ENDIF}
  repeat
//   AllPacketsReceived := True;
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgClientResendRequestThread');
{$ENDIF}
   j := 0;
   Count := FClientSession.Packets.Count;
   for i:=0 to Count-1 do
    begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': i='+IntToStr(i));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Count='+IntToStr(Count));
{$ENDIF}
     if Terminated then
      begin
       FRecreate := False;
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread.Execute> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(FBuffer).CurrentRequestID)+' - Terminated!', NetLog);
{$ENDIF}
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog('ClientResendRequestThread.Execute> Terminated!');
{$ENDIF}
       Exit;
      end;
     EnterCSect(FClientSession.FCSect);
     try
       if (FClientSession.CurrentRequestID > PMsgPacketHeader(FBuffer).CurrentRequestID) then
        begin
         FRecreate := False;
  {$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
  aaWriteToLog('ClientResendRequestThread.Execute> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(FBuffer).CurrentRequestID)+' - old request - finish...', NetLog);
  {$ENDIF}
  {$IFDEF LOG_CLIENT_RESEND_REQUEST}
  aaWriteToLog('ClientResendRequestThread.Execute> old request - finish...');
  {$ENDIF}
         Exit;
        end;
       if FClientSession.Packets <> nil then
     if FClientSession.Packets <> nil then
     if FClientSession.Packets.Count > i then
     if FClientSession.Packets.Items[i] = nil then
      begin
       LeaveCSect(FClientSession.FCSect);
//       AllPacketsReceived := False;
       inc(j);
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': PacketResendRequest, i='+IntToStr(i));
{$ENDIF}
       FManager.PacketResendRequest(FBuffer, FNetwork, FHost, FPort, i);
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Packet has been requested');
{$ENDIF}
       Sleep(FClientSession.Session.ConnectParams.ReceiveSleep);
       EnterCSect(FClientSession.FCSect);
      end;
     finally
      LeaveCSect(FClientSession.FCSect);
     end;
    end;
(*
   if AllPacketsReceived then
    begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': AllPacketsReceived');
{$ENDIF}
     FClientSession.AnswerStatus := MsgFull;
//     FManager.SendAcknowledgement(FClientSession);
    end;
*)
   if FClientSession.Session.ConnectParams.ConnectionParamsTunning then
     Sleep((FClientSession.AnswerTime div 16) * j)
   else
     Sleep(FClientSession.Session.ConnectParams.RequestDelay);
  until not (FClientSession.AnswerStatus = MsgNotFull);
 except
  on E: Exception do
   begin
   try
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread.Execute>  - EXCEPTION!', NetLog);
aaWriteToLog('ClientResendRequestThread.Execute> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PMsgPacketHeader(FBuffer).CurrentRequestID), NetLog);
{$ENDIF}
    if (FClientSession = nil)
    or (FClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  ' Session does not exist. '+
                  E.Message;
      Sessions := FManager.FSessions.LockList;
      try
       if Sessions.Count > 0 then
        begin
         FClientSession := Sessions.Items[0];
         if FClientSession.Session <> nil then
           TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientResendRequestThread,-1,
                  Error)
         else
          begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientResendRequestThread,-1,
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message);
   except
   end;
   end;
 end;
end;// Execute

(*
////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgClientMsgResendRequestThread.Create(
                       Manager:           TMsgClientConnectionManager;
                       ClientSession:     PMsgClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TMsgNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                                            );
var
  Error:        AnsiString;
  Header:       PMsgPacketHeader;
  Sessions:     TMsgList;
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FClientSession := ClientSession;
  FBuffer := MemoryManager.AllocMem(SizeOf(TMsgPacketHeader));
  Move(Buffer^,FBuffer^,SizeOf(TMsgPacketHeader));
  Header := PMsgPacketHeader(FBuffer);
  Header.Recepient := FClientSession.Session.ConnectParams.ServerID;
  FNetwork := Network;
  FHost := FromHost;
  FPort := FromPort;
  inherited Create(False);
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('CLIENT RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    if (ClientSession = nil)
    or (ClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  ' Session does not exist. '+
                  E.Message;
      Sessions := FManager.FSessions.LockList;
      try
       if Sessions.Count > 0 then
        begin
         ClientSession := Sessions.Items[0];
         if ClientSession.Session <> nil then
           TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  Error)
         else
          begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TMsgNetworkSession(ClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgClientMsgResendRequestThread.Destroy;
var
  Error:        AnsiString;
  Sessions:     TMsgList;
begin
 try
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('CLIENT RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  MemoryManager.FreeAndNilMem(FBuffer);
  EnterCSect(FManager.FCSect);
  if FClientSession.MsgResendRequestThread <> nil then
    FClientSession.MsgResendRequestThread := nil;
  LeaveCSect(FManager.FCSect);
  inherited Destroy;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('CLIENT RESENDING THREAD - FINISHED');
{$ENDIF}
  FManager.DecThreadCount;
 except
  on E: Exception do
   begin
    if (FClientSession = nil)
    or (FClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  ' Session does not exist. '+
                  E.Message;
      Sessions := FManager.FSessions.LockList;
      try
       if Sessions.Count > 0 then
        begin
         FClientSession := Sessions.Items[0];
         if FClientSession.Session <> nil then
           TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  Error)
         else
          begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}

aaWriteToLog('ERROR: ' + Error);

{$ENDIF}
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgClientMsgResendRequestThread.Execute;
var
  Error:              AnsiString;
  i, j, Count:        Integer;
  AllPacketsReceived: Boolean;
  Sessions:           TMsgList;
begin
 try
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** CLIENT RESEND REQUEST START *****');
{$ENDIF}
  repeat
   AllPacketsReceived := True;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgClientMsgResendingThread');
{$ENDIF}
   j := 0;
   Count := FClientSession.MsgPackets.Count;
   for i:=0 to Count-1 do
    begin
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': i='+IntToStr(i));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Count='+IntToStr(Count));
{$ENDIF}
     if Terminated then
      begin
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Count='+IntToStr(Count));
{$ENDIF}
       Exit;
      end;
//     Sleep(0);
     EnterCSect(FManager.FCSect);
     if FClientSession.MsgPackets <> nil then
     if FClientSession.MsgPackets.Count > i then
     if FClientSession.MsgPackets.Items[i] = nil then
      begin
       LeaveCSect(FManager.FCSect);
       AllPacketsReceived := False;
       inc(j);
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': PacketResendRequest, i='+IntToStr(i));
{$ENDIF}
       FManager.PacketResendRequest(FBuffer, FNetwork, FHost, FPort, i, True);
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Packet has been resent');
{$ENDIF}
//       Sleep(MsgRequestDelay);
       Sleep(FClientSession.Session.ConnectParams.ReceiveSleep);
       EnterCSect(FManager.FCSect);
      end;
     LeaveCSect(FManager.FCSect);
    end;
   if AllPacketsReceived then
    begin
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': AllPacketsReceived');
{$ENDIF}
     FClientSession.MsgReceiveStatus := MsgFull;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': 9th ClientSession.MsgReceiveStatus='+IntToStr(FClientSession.MsgReceiveStatus));
{$ENDIF}
//     FManager.SendAcknowledgement(FClientSession, True);
    end;
   if FClientSession.Session.ConnectParams.ConnectionParamsTunning then
     Sleep((FClientSession.AnswerTime div 16) * j)
   else
     Sleep(FClientSession.Session.ConnectParams.RequestDelay);
  until FClientSession.MsgReceiveStatus = MsgFull;
 except
  on E: Exception do
   begin
    FRecreate := True;
    if (FClientSession = nil)
    or (FClientSession.Session = nil)
    then
     begin
      Error :=
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  ' Session does not exist. '+
                  E.Message; 
      Sessions := FManager.FSessions.LockList; 
      try 
       if Sessions.Count > 0 then
        begin 
         FClientSession := Sessions.Items[0];
         if FClientSession.Session <> nil then 
           TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  Error)
         else
          begin 
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
          end;
        end
       else
        begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: ' + Error);
{$ENDIF}
        end;
      finally 
       FManager.FSessions.UnlockList;
      end; 
     end
    else
      TMsgNetworkSession(FClientSession.Session).DoOnError(
                  MsgClientMsgResendRequestThread,-1,
                  ErrorRClient+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message);
   end;
 end;
end;// Execute
*)	
{$ENDIF} // Client



{$IFDEF SERVER_VERSION}

////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerConnectionManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerConnectionManager.Create(Server: TComponent);
begin
 try
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TMsgServerConnectionManager.Create> @Server='+IntToStr(Integer(FServer)));
{$ENDIF}
  FListenerStoped := True;
  InitCSect(FCSect);
  inherited Create;
  FMaxMsgThreadCount := MsgMaxMsgThreads;
  FSessions := TMsgThreadList.Create;
  FIncomingPackets := TMsgThreadList.Create;
  FSessionID := -MAXINT;
  FServer := Server;
  ThreadCount := 1;
  FNetwork := TMsgNetwork.Create(self);
  if Server = nil then
   begin
    FNetwork.FLocalClient := 1;
    FNetwork.LocalPort := MsgDefaultServerPort;
   end
  else
   begin
    FNetwork.FLocalClient := TMsgServer(FServer).ServerID;
    FNetwork.LocalHost := TMsgServer(FServer).LocalHost;
    FNetwork.LocalPort := TMsgServer(FServer).LocalPort;
{$IFDEF MsgCommunicator}
    FNetwork.PacketSize := TMsgServer(FServer).ConnectionParams.NetworkSettings.PacketSize;
    TMsgServer(FServer).ConnectionParams.LocalPort := FNetwork.LocalPort;
    TMsgServer(FServer).ConnectionParams.LocalHost := FNetwork.LocalHost;
{$ELSE}
    FNetwork.PacketSize := TMsgServer(FServer).NetworkSettings.PacketSize;
    TMsgServer(FServer).LocalPort := FNetwork.LocalPort;
    TMsgServer(FServer).LocalHost := FNetwork.LocalHost;
{$ENDIF}
   end;
  ListenerThread := TMsgServerListenerThread.Create(self);
  ResendRequestThread := TMsgServerResendRequestThread.Create(self);
  MsgResendRequestThread := TMsgServerMsgResendRequestThread.Create(self);
  SessionTerminator := TMsgServerSessionTerminatorThread.Create(self);
  if Server <> nil then
    if TMsgServer(FServer).NetworkSettings.PingClients then
      PingClientsThread := TMsgServerPingClientsThread.Create(self);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TMsgServerConnectionManager.Create> FINISHED');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TMsgServerConnectionManager.Create - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerConnectionManager.Destroy;
var
  Error:          AnsiString;
  StartTime:      Cardinal;
  Abnormal:       Boolean;
  i,
  Delay:          Integer;
  Packets:        TMsgList;
  NetworkPacket:  PMsgNetworkPacket;
begin
 try
  Abnormal := False;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> @Server='+IntToStr(Integer(FServer)));
{$ENDIF}
  FListenerStoped := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> DisconnectAll...');
{$ENDIF}
  DisconnectAll(False);
// Terminate ResendRequestThread
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> Terminate ResendRequestThread');
{$ENDIF}
{
  if ResendRequestThread <> nil then
    ResendRequestThread.Terminate;
  StartTime := GetTickCount;
  repeat
   sleep(0);
   if (ResendRequestThread=nil)
    then break
    else
     begin
      if (GetTickCount - StartTime) > MsgServerThreadsTerminateDelay then
       begin
        Error := 'command resend requesting thread';
        raise EMsgException.Create(40036, ErrorRThreadHangs,
                                          ['ServerConnectionManager',
                                                                  Error]);
       end;
     end;
  until False;
}
  if not CloseThread(@ListenerThread,MsgServerConnectionManager,ErrorRListenerThread) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> listener thread terminated');
{$ENDIF}
  if not CloseThread(@ResendRequestThread,MsgServerConnectionManager,ErrorRResendRequestThread,500) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> command resend thread terminated');
{$ENDIF}
  if not CloseThread(@MsgResendRequestThread,MsgServerConnectionManager,ErrorRMsgResendRequestThread,500) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> message resend thread terminated');
{$ENDIF}
  if not CloseThread(@SessionTerminator,MsgServerConnectionManager,ErrorRServerSessionTerminatorThread,300) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> session terminator thread terminated');
{$ENDIF}
  if not CloseThread(@PingClientsThread,MsgServerConnectionManager,ErrorRServerPingClientsThread,MsgServerPingSleep*2) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> Ping Clients thread terminated');
{$ENDIF}
// Wait for Sessions Threads
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy> Wait for Sessions Threads');
{$ENDIF}
  if FServer = nil then
    Delay := MsgServerThreadsTerminateDelay
  else
    Delay := TMsgServer(FServer).NetworkSettings.ServerThreadsTerminateDelay;
  StartTime := GetTickCount;
  while (GetTickCount - StartTime) < Delay do
   begin
    sleep(0);
    if (ThreadCount=1) then
      break;
   end;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - Delete Sessions...');
{$ENDIF}
  if not Abnormal then
    EnterCSect(FCSect);
  try
   FSessions.Free;
   FSessions := nil;
  except
  end;
// free packets queue
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - free packets queue...');
{$ENDIF}
  Packets := FIncomingPackets.LockList;
  try
   for i := (Packets.Count - 1) downto 0 do
    begin
     NetworkPacket := Packets.Items[i];
     MemoryManager.FreeAndNilMem(NetworkPacket.Packet.Buffer);
     Dispose(NetworkPacket.Packet);
//     Packets.Delete(i);
   end;
//   Packets.Clear;
  finally
   FIncomingPackets.UnlockList;
   FIncomingPackets.Free;
   FIncomingPackets := nil;
  end;
// free network
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - Free Network...');
{$ENDIF}
  if FNetwork <> nil then
   begin
    FNetwork.Free;
    FNetwork := nil;
    DecThreadCount(Abnormal);
   end;
  FNetwork := nil;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - Leave CS...');
{$ENDIF}
  if not Abnormal then
    LeaveCSect(FCSect);
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - Delete CS...');
{$ENDIF}
  DeleteCSect(FCSect);
  inherited Destroy;
// Check for threads
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - check ThreadCount...');
{$ENDIF}
  if ThreadCount <> 0 then
    TMsgServer(FServer).DoOnConnectionError(
                  MsgServerConnectionManager,40515,
                  ErrorRServer+
                  ErrorRDestroy+
                  ErrorRThreadsLeft+
                  IntToStr(ThreadCount)
                  );
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgServerConnectionManager.Destroy> Threads Count = '+IntToStr(ThreadCount));
{$ENDIF}
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TMsgServerConnectionManager.Destroy - FINISHED');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TMsgServerConnectionManager.Destroy - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Destoy


//------------------------------------------------------------------------------
// PacketResendRequest
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TMsgNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False;
                               Packets:       TMsgThreadList = nil
                                 );
var
  Header:           PMsgPacketHeader;
  Buf:              PAnsiChar;
  BufSize:          Integer;
{$IFDEF PACKET_RESEND_REQUEST}
  i, j:             Integer;
  packs, IDs:       TMsgList;
  packID:           TMsgPacketID;
{$ENDIF}
begin
  Header := Pointer(Buffer);
  Header.Signature := MsgServerPacketSign;
  if Msg then
    Header.ControlCode := MsgMessagePacketResendRequest
  else
    Header.ControlCode := MsgPacketResendRequest;
  if (PacketID >= 0) then
    Header.PacketID := PacketID
  else
    Header.Recepient := Header.Sender;
{$IFDEF DEBUG_LOG_NETWORK_RESENDING}
aaWriteToLog('SERVER asks to resend packet # '+IntToStr(Header.PacketID));
{$ENDIF}
{$IFDEF PACKET_RESEND_REQUEST}
  if Packets <> nil then
   begin
    packs := Packets.LockList;
    IDs := TMsgList.Create;
    try
     j := packs.Count;
     if j >((Network.PacketSize - SizeOf(TMsgPacketHeader)) div SizeOf(TMsgPacketID)) then
       j := (Network.PacketSize - SizeOf(TMsgPacketHeader)) div SizeOf(TMsgPacketID);
     if j >= Msg_Max_PacketID then
       j := Msg_Max_PacketID - 1;
     for i := PacketID + 1 to j do
      begin
       if packs.Items[i] = nil then
         IDs.Add(i);
      end;
    finally
     Packets.UnlockList;
     IDs.Free;
    end;
    BufSize := SizeOf(TMsgPacketHeader);
    if IDs.ItemsCount = 0 then
     begin
      Buf := Buffer;
     end
    else
     begin
      BufSize := BufSize + (IDs.ItemsCount * SizeOf(TMsgPacketID));
      Buf:=MemoryManager.GetMem(BufSize);
      Move(Buffer^, Buf, SizeOf(TMsgPacketHeader));
      for i := 0 to IDs.ItemsCount-1 do
       begin
        packID := TMsgPacketID(IDs.Items[i]);
        Move(packID, Buffer^ + SizeOf(TMsgPacketHeader) + (i * SizeOf(TMsgPacketID), SizeOf(TMsgPacketID));
       end;
     end;
   end;
{$ELSE}
  BufSize := SizeOf(TMsgPacketHeader);
  Buf := Buffer;
{$ENDIF}
  EnterCSect(FCSect);
  try
   Network.RemoteHost := RemoteHost;
   Network.RemotePort := RemotePort;
   Network.SendBuffer(Buf, BufSize);
  finally
   LeaveCSect(FCSect);
{$IFDEF PACKET_RESEND_REQUEST}
   if BufSize > SizeOf(TMsgPacketHeader) then
     MemoryManager.FreeAndNilMem(Buf);
{$ENDIF}
  end;
end;// PacketResendRequest


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.OnDisconnect(
                               FNetwork:      TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
{$IFDEF MsgCommunicator}
  SSessions:            array of TMsgServerSession;
{$ENDIF}
begin
{ TODO -oAlex : Re-write OnDisconnect to use DoDisconnect. In MsgCommunicator DisconnectUser move to Session.Destroy}

{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.OnDisconnect> START');
aaWriteToLog('OnDisconnect> Broken client: '+FromHost+':'+IntToStr(FromPort));
{$ENDIF}
 try
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> FSessions');
aaWriteToLog(IntToStr(Integer(FSessions)));
 {$ENDIF LOG_SERVER_DISCONNECT}
{$IFDEF MsgCommunicator}
  SetLength(SSessions, 0);
{$ENDIF}
  Sessions:=FSessions.LockList;
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> FSessions Locked!');
 {$ENDIF LOG_SERVER_DISCONNECT}
   try
    for i:=Sessions.Count-1 downto 0 do
     begin
      if (i<0)
      or (i>=Sessions.Count)
      then
        break;
      ServerSession := Sessions.Items[i];
      if (ServerSession.RemoteHost = FromHost)
      and (ServerSession.RemotePort = FromPort)
      then
       begin
(* REMOVED IN Msg --------------------------------------------------------------
{$IFDEF MsgCommunicator}
        SetLength(SSessions, Length(SSessions)+1);
        SSessions[Length(SSessions)-1] := TMsgServerSession(ServerSession.Session);
{$ENDIF}
REMOVED IN Msg -------------------------------------------------------------- *)
        EnterCSect(FCSect);
        if (ServerSession.ControlCode <> MsgTerminate)
        or (ServerSession.MsgControlCode <> MsgTerminate)
        then
         begin
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('OnDisconnect> SERVER SESSION TERMINATE');
{$ENDIF}
          // Terminate sending threads
          ServerSession.ControlCode := MsgTerminate;
          ServerSession.MsgControlCode := MsgTerminate;
          LeaveCSect(FCSect);
          // Block send message
{$IFDEF MsgCommunicator}
          if ServerSession.Session <> nil then
            EnterCSect(TMsgServerSession(ServerSession.Session).FCSect);
          try
{$ENDIF}
          FSessions.UnlockList;
          // Terminate listening threads
          TerminateAllSessionThreads(ServerSession);
(*
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> Terminate command listening threads...');
{$ENDIF}
          TerminateCommandThreads(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> Terminate message listening threads...');
{$ENDIF}
          TerminateMessageThreads(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> All sessions terminated');
{$ENDIF}
*)
          // delete session from list
          FSessions.Remove(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> Removed SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
{$IFDEF MsgCommunicator}
          finally
           if ServerSession.Session <> nil then
             LeaveCSect(TMsgServerSession(ServerSession.Session).FCSect);
          end;
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> Session CS left');
{$ENDIF}
          // free memory and session
          DeleteSession(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> Session deleted');
{$ENDIF}
          Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> Sessions locked');
{$ENDIF}
         end
        else
          LeaveCSect(FCSect);
       end;
     end;
   finally
    FSessions.UnlockList;
   end;

(*
  EnterCSect(FCSect);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> OLD: FNetwork=');
aaWriteToLog(IntToHex(Integer(FNetwork),6));
{$ENDIF}
  if FNetwork <> nil then
   begin
    FNetwork.Free;
    DecThreadCount;
   end;
  FNetwork := nil;
  FNetwork := TMsgNetwork.Create(self);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> NEW: FNetwork=');
aaWriteToLog(IntToHex(Integer(FNetwork),6));
{$ENDIF}
  if FServer = nil then
   begin
    FNetwork.FLocalClient := 1;
    FNetwork.LocalPort := MsgDefaultServerPort;
   end
  else
   begin
    FNetwork.FLocalClient := TMsgServer(FServer).ServerID;
    FNetwork.LocalHost := TMsgServer(FServer).LocalHost;
    FNetwork.LocalPort := TMsgServer(FServer).LocalPort;
   end;
  LeaveCSect(FCSect);
*)

{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog(IntToStr(GetTickCount)+':');
aaWriteToLog('OnDisconnect> FNetwork=');
aaWriteToLog(IntToHex(Integer(FNetwork),6));
{$ENDIF}

(* REMOVED IN Msg --------------------------------------------------------------
{$IFDEF MsgCommunicator}
  if not FListenerStoped then
   // Send off-line events
   for i:=0 to Length(SSessions)-1 do
    begin
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> DisconnectUser...');
 {$ENDIF}
     SSessions[i].DisconnectUser;
{
     ServerSession := Sessions.Items[0];
     TMsgServerSession(ServerSession.Session).DisconnectUser(Users.Items[i]);
}
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> DisconnectUser finished');
 {$ENDIF}
    end;
{$ENDIF}
--------------------------------------------------------------- REMOVED IN Msg*)
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> FINISH');
{$ENDIF LOG_SERVER_DISCONNECT}
 except
  on E: Exception do
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> TMsgServerConnectionManager.OnDisconnect - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
    raise;
   end;
 end;
end; // OnDisconnect


//------------------------------------------------------------------------------
// NetworkListener
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TMsgNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
(*
var
  StartTime:        Cardinal;
*)
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
var
 Packets:              TMsgList;
{$ENDIF}

function IsExistingPacket: Boolean;
var
 i:                    Integer;
 Packets:              TMsgList;
 NetworkPacket:        PMsgNetworkPacket;
{
function IsSameHeader: Boolean;
begin
 Result := CompareMem(PMsgPacketHeader(NetworkPacket.Packet.Buffer),
                      PMsgPacketHeader(Buffer),
                      SizeOf(TMsgPacketHeader));
end;
}
begin // IsExistingPacket
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> IsExistingPacket - START');
aaWriteToLog('SERVER-IsExistingPacket> SERVER<<< '
              +IntToStr(PMsgPacketHeader(Buffer).CurrentRequestID)+' : '
              +IntToStr(PMsgPacketHeader(Buffer).PacketID)+' / '
              +IntToStr(PMsgPacketHeader(Buffer).ControlCode)+' <<< '
              +FromHost+':'+IntToStr(FromPort));
{$ENDIF}
 Result := False;
 try
   Packets := FIncomingPackets.LockList;
   try
    for i:=Packets.Count-1 downto 0 do
     begin
       NetworkPacket := Packets.Items[i];
       if NetworkPacket.Network = Network then
       if NetworkPacket.FromHost = FromHost then
       if NetworkPacket.FromPort = FromPort then
       if NetworkPacket.Packet.BufferSize = BufferSize then
       if Buffer <> nil then
       if NetworkPacket.Packet.Buffer <> nil then
       if CompareMem(NetworkPacket.Packet.Buffer, Buffer, SizeOf(TMsgPacketHeader)) then
        begin
         Result := True;
         break;
        end;
     end; // for
   finally
    FIncomingPackets.UnlockList;
   end;
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
if Result = True then
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> IsExistingPacket - FINISH - Existing Packet')
else
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> IsExistingPacket - FINISH - Original Packet');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> ERROR!!!');
{$ENDIF}
 end;
end; // IsExistingPacket

procedure AddPacket;
var
 NetworkPacket:     PMsgNetworkPacket;
 Packet:            PMsgPacket;
 Packets:           TMsgList;
begin
 New(NetworkPacket);
 NetworkPacket.Network := Network;
 NetworkPacket.FromHost := FromHost;
 NetworkPacket.FromPort := FromPort;
 New(Packet);
 Packet.Buffer := Buffer;
 Packet.BufferSize := BufferSize;
 NetworkPacket.Packet := Packet;
 FIncomingPackets.Add(NetworkPacket);
end; // AddPacket

begin // NetworkListener
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('NetworkListener --------------------------------');
aaWriteToLog('Header.ConnectionID = '+IntToStr(PMsgPacketHeader(Buffer).ConnectionID));
aaWriteToLog('Header.SessionID    = '+IntToStr(PMsgPacketHeader(Buffer).SessionID));
aaWriteToLog('Header.ControlCode  = '+IntToStr(PMsgPacketHeader(Buffer).ControlCode));
aaWriteToLog('NetworkListener --------------------------------');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PMsgPacketHeader(Buffer).ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TMsgServerConnectionManager.NetworkListener> message received from SessionID = '+IntToStr(PMsgPacketHeader(Buffer).SessionID));
{$ENDIF}
  if not FListenerStoped then
   begin
    if not IsExistingPacket then
     begin
      AddPacket;
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PMsgPacketHeader(Buffer).ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TMsgServerConnectionManager.NetworkListener> message added from SessionID = '+IntToStr(PMsgPacketHeader(Buffer).SessionID));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
Packets := FIncomingPackets.LockList;
try
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Packets Count = '+IntToStr(Packets.Count));
finally
FIncomingPackets.UnlockList;
end;
{$ENDIF}
      Exit;
     end
    else
     begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PMsgPacketHeader(Buffer).ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TMsgServerConnectionManager.NetworkListener> not added: Existing packet from SessionID = '+IntToStr(PMsgPacketHeader(Buffer).SessionID));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Existing packet received')
{$ENDIF}
     end;
   end
  else
   begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PMsgPacketHeader(Buffer).ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TMsgServerConnectionManager.NetworkListener> not added from SessionID = '+IntToStr(PMsgPacketHeader(Buffer).SessionID)+': Listener Stoped!');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Listener Stoped!!!');
{$ENDIF}
   end;
  MemoryManager.FreeAndNilMem(Buffer);
(*
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> START - '+IntToStr(GetTickCount));
{$ENDIF}
  if not FListenerStoped then
   begin
    StartTime := GetTickCount;
    while ((GetTickCount-StartTime) < TMsgServer(FServer).NetworkSettings.ServerReceiveTimeOut) do
     begin
      if ThreadCount<TMsgServer(FServer).NetworkSettings.MaxThreadCount then
       begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Create Listener Thread... - '+IntToStr(GetTickCount));
{$ENDIF}
        TMsgServerListenerThread.Create(self, Buffer, BufferSize, FromHost, FromPort);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Listener Thread Created ! - '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Threads Count = '+IntToStr(ThreadCount));
{$ENDIF}
        Exit;
       end;
      sleep(0);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.NetworkListener> Sleeped ! - '+IntToStr(GetTickCount));
{$ENDIF}
     end;
    TMsgServer(FServer).DoOnConnectionError(
                  MsgServerListenerThread,40516,
                  ErrorRCannotCreateListenerThread+
                  IntToStr(TMsgServer(FServer).NetworkSettings.MaxThreadCount));
   end;
  MemoryManager.FreeAndNilMem(Buffer);
*)
end;// NetworkListener


//------------------------------------------------------------------------------
// WaitForServerSessionThread
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.WaitForServerSessionThread(
                          ServerSession:    PMsgSrvrSession;
                          TimeOut:          Cardinal = MsgWaitForServerSessionThreadTimeOut
                          );
var
  StartTime:      Cardinal;
begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.WaitForServerSessionThread> Started at: '+IntToStr(GetTickCount));
{$ENDIF}
//  WaitForThread(@ServerSession.Thread, TimeOut);
  StartTime := GetTickCount;
  while ((GetTickCount-StartTime) < TimeOut) do
   begin
    if ServerSession.ReceiveStatus = MsgNo then
      break;
    sleep(1);
   end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
//if ServerSession.Thread = nil then
if ServerSession.ReceiveStatus = MsgNo then
aaWriteToLog('TMsgServerConnectionManager.WaitForServerSessionThread> Finished at: '+IntToStr(GetTickCount))
else
aaWriteToLog('TMsgServerConnectionManager.WaitForServerSessionThread> Not Finished! Timeout at: '+IntToStr(GetTickCount));
{$ENDIF}
end; // Wait for server session thread


//------------------------------------------------------------------------------
// WaitForServerSessionMsgThread
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.WaitForServerSessionMsgThread(
                          ServerSession:    PMsgSrvrSession;
                          TimeOut:          Cardinal = MsgWaitForServerSessionThreadTimeOut
                          );
begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.WaitForServerSessionMsgThread> Started at: '+IntToStr(GetTickCount));
{$ENDIF}
//  WaitForThread(@ServerSession.MsgThread, TimeOut);
  CloseThread(@ServerSession.MsgThread,MsgServerSessionMsgThreadHang,ErrorRServerSessionMsgThread,
                        TimeOut);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
if ServerSession.Thread = nil then
aaWriteToLog('TMsgServerConnectionManager.WaitForServerSessionMsgThread> Finished at: '+IntToStr(GetTickCount))
else
aaWriteToLog('TMsgServerConnectionManager.WaitForServerSessionMsgThread> Not Finished! Timeout at: '+IntToStr(GetTickCount));
{$ENDIF}
end; // Wait for server session message thread


//------------------------------------------------------------------------------
// CommandReceived
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.CommandReceived(
                          ServerSession:    PMsgSrvrSession;
                          ControlCode:      TMsgControlCode;
                          CurrentRequestID: Integer
                                                      );
var
  Error:        AnsiString;
(*
function IsNotSingle: Boolean;
begin
  Result := False;
   if (ControlCode <> MsgDisconnect) then
     if (CurrentRequestID < ServerSession.CurrentRequestID) then
      begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> (CurrentRequestID < ServerSession.CurrentRequestID) ==> Exit, old command already processed');
{$ENDIF}
       Result := True;
       Exit;
      end;
   if ServerSession.ReceiveStatus = MsgFull then
    begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> (ReceiveStatus = MsgFull) ==> Exit');
{$ENDIF}
     Result := True;
     Exit;
    end;
   ServerSession.ReceiveStatus := MsgFull;
   if ServerSession.ControlCode = MsgExecute then
     ServerSession.ControlCode := MsgSuspend
   else
    begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> (ControlCode <> MsgExecute) ==> Exit');
{$ENDIF}
     Result := True;
     Exit;
    end;
end;
*)
begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> STARTED - GetTickCount='+IntToStr(GetTickCount));
aaWriteToLog(' CurrentRequestID='+IntToStr(ServerSession.CurrentRequestID));
aaWriteToLog(' Code='+IntToStr(ControlCode));
aaWriteToLog(' ReceiveStatus = '+IntToStr(ServerSession.ReceiveStatus));
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-CommandReceived> START');
{$ENDIF}
  if (ControlCode >= MsgLastPacket) then
    ControlCode := ControlCode - MsgLastPacket;
  ServerSession.ReceiveStatus := MsgFull;
  EnterCSect(FCSect);
  if ServerSession.ControlCode = MsgExecute then
    ServerSession.ControlCode := MsgSuspend;
  LeaveCSect(FCSect);
  if ServerSession.Thread <> nil then
    CloseThread(@ServerSession.Thread,MsgServerDeleteSession,
        ErrorRServerSessionThread,
        ServerSession.Session.ConnectParams.WaitForTimeOut, 0);
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-CommandReceived> create session thread...');
{$ENDIF}
  if ServerSession.Thread = nil then
    ServerSession.Thread := TMsgServerSessionThread.Create(self,
                                                 ServerSession, ControlCode);
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-CommandReceived> sleep(0)...');
{$ENDIF}
  sleep(0);  // Do not change -- the fastest speed!!!
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-CommandReceived> up! - FINISH');
{$ENDIF}
(*
  if (CurrentRequestID-1)=ServerSession.CurrentRequestID then // next command already received, could be previous was without answer and still executed...
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> previous session still executes...');
{$ENDIF}
    WaitForServerSessionThread(ServerSession);
   end;
  if CurrentRequestID=ServerSession.CurrentRequestID then
   begin
    if (ControlCode >= MsgLastPacket) then
      ControlCode := ControlCode - MsgLastPacket;
    ServerSession.Thread.FCode := ControlCode;
    ServerSession.ReceiveStatus := MsgFull;
   end;
//  sleep(0); // NEVER SET IT!!!
  Exit;


// Disconnect - wait for session end
  if (ControlCode = MsgDisconnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> Disconnect - SendAcknowledgement');
{$ENDIF}
    SendAcknowledgement(ServerSession);
    WaitForServerSessionThread(ServerSession);
   end;

// check for single execution and block other calls
  EnterCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> CS Entered!');
{$ENDIF}
  try
  if IsNotSingle then
    Exit;
  finally
   LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> CS Left!');
{$ENDIF}
  end;
  if (ControlCode <> MsgConnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> SendAcknowledgement');
{$ENDIF}
    if (ControlCode <> MsgDisconnect) then
     begin
      SendAcknowledgement(ServerSession, False, CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> SendAcknowledgement - SENT');
{$ENDIF}
     end;
    if CurrentRequestID>ServerSession.CurrentRequestID then
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> previous session still executes...');
{$ENDIF}
      WaitForServerSessionThread(ServerSession);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> previous session finished, block...');
{$ENDIF}
      EnterCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> CS Entered!');
{$ENDIF}
      try
       if IsNotSingle then
         Exit;
      finally
       LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> CS Left!');
{$ENDIF}
      end;
     end;
    if ServerSession.Thread = nil then
     begin
      ServerSession.Thread := TMsgServerSessionThread.Create(self,
                                                   ServerSession, ControlCode);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> CREATED # '+IntToStr(Integer(ServerSession.Thread.ThreadID))+'/'+IntToStr(Integer(ServerSession.Thread.Handle)));
{$ENDIF}
     end
    else
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> Server Session already exists');
{$ENDIF}
      Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(ServerSession.Thread.ThreadID))+'/'+IntToStr(Integer(ServerSession.Thread.Handle))+
                  ErrorRServerSessionNotFinished+
                  ' SessionID='+IntToStr(ServerSession.Session.SessionID)+
                  ', current comand: CurrentRequestID='+IntToStr(CurrentRequestID)+
                  ', ControlCode='+IntToStr(ControlCode)+
                  ', previous command still executed: CurrentRequestID='+IntToStr(ServerSession.CurrentRequestID)+
                  ', ControlCode='+IntToStr(ServerSession.Thread.FCode)+'.';
      try
       TMsgNetworkSession(ServerSession.Session).DoOnError(MsgServerSessionThread,40514,Error);
      except
       TMsgServer(FServer).DoOnConnectionError(MsgServerSessionThread,40514,Error);
      end;
     end;
   end;
*)
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> FINISHED');
{$ENDIF}
end; // CommandReceived


//------------------------------------------------------------------------------
// MessageReceived
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.MessageReceived(
                                  ServerSession:  PMsgSrvrSession;
                                  ControlCode:    TMsgControlCode = MsgMessage
                                                      );
var
  Packets:     TMsgList;
begin
(*
  while ServerSession.MsgThread <> nil do
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerConnectionManager.CommandReceived> previous session still executes...');
{$ENDIF}
    WaitForServerSessionMsgThread(ServerSession);
   end;
  if (ControlCode >= MsgLastPacket) then
    ControlCode := ControlCode - MsgLastPacket;
*)
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog('All packets in message queue. ');
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID));
  Packets := ServerSession.MsgQueue.LockList;
  try
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID)+': Old Queue.Count = '+IntToStr(Integer(Packets.Count)));
  finally
   ServerSession.MsgQueue.UnlockList;
  end;
  Packets := ServerSession.MsgPackets.LockList;
  try
aaWriteToLog('Packets.Count = '+IntToStr(Integer(Packets.Count)));
aaWriteToLog('Message        # '+IntToStr(ServerSession.ClientMessageID));
aaWriteToLog('Header.Message # '+IntToStr(Integer(PMsgPacketHeader(PMsgPacket(Packets.Items[0]).Buffer).CurrentRequestID)));
  finally
   ServerSession.MsgPackets.UnlockList;
  end;
aaWriteToLog('Adding new message...');
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID)+': old list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
  ServerSession.MsgReceiveStatus := MsgFull;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('old list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
// ServerSession.MsgQueue.Add(ServerSession.MsgPackets);
// equal to following code,
// which is without problems with the same pointer reallocated
  Packets := ServerSession.MsgQueue.LockList;
  try
   Packets.Add(ServerSession.MsgPackets);
  finally
   ServerSession.MsgQueue.UnlockList;
  end;
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
  Packets := ServerSession.MsgQueue.LockList;
  try
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID)+': New Queue.Count = '+IntToStr(Integer(Packets.Count)));
  finally
   ServerSession.MsgQueue.UnlockList;
  end;
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('list added to queue');
{$ENDIF}
  ServerSession.MsgPackets := TMsgThreadList.Create;
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID)+': new list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('new list created');
{$ENDIF}
  Packets := ServerSession.MsgPackets.LockList;
  try
   Packets.Capacity := MsgDefaultPacketsInRequest; // Allocate some place in list
  finally
   ServerSession.MsgPackets.UnlockList;
  end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('new list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
  inc(ServerSession.ClientMessageID);
  ServerSession.MsgReceiveStatus := MsgNo;
  if ServerSession.MsgThread = nil then
    ServerSession.MsgThread := TMsgServerSessionMsgThread.Create(self,
                                                 ServerSession, ControlCode);
  sleep(0);
end; // MessageReceived


//------------------------------------------------------------------------------
// ReceiveMessage
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.ReceiveMessage(
                          ServerSession:  PMsgSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
var
  i:                    Integer;
  Packets:              TMsgList;
  Packet:               PMsgPacket;
  pBuf:                 PAnsiChar;
begin
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('SERVER are receiving message from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
{$ENDIF}
(*
  if ServerSession.MsgReceiveStatus<>MsgFull then
   begin
    while (ServerSession.MsgReceiveStatus<>MsgStart)
    and (ServerSession.MsgReceiveStatus<>MsgFull)
    do // Wait for starting answer receive
     begin
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
     end;
    StartTime := GetTickCount;
    while (ServerSession.MsgReceiveStatus<>MsgFull)
    do // Wait for all packets to arrive
     begin
      if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerReceiveTimeOut then
       raise EMsgException.Create(40026, ErrorRTimeoutFullReceive,
                                [ServerSession.Session.SessionID, ServerSession.Session.ConnectParams.ServerReceiveTimeOut]);
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
     end;
   end;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received request from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
{
  EnterCSect(FCSect);
  if ServerSession.MsgControlCode = MsgExecute then
    ServerSession.MsgControlCode := MsgSuspend;
  LeaveCSect(FCSect);
}
*)
  Packets := ServerSession.MsgReceivedPackets.LockList;
  try
// Send Ackn
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog('ServerConnectionManager.ReceiveMessage> Header.Message # '+
  IntToStr(PMsgPacketHeader(PMsgPacket(Packets.Items[0]).Buffer).CurrentRequestID));
{$ENDIF}
    try
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> ServerConnectionManager.ReceiveMessage');
{$ENDIF}
     SendAcknowledgement(ServerSession,True,PMsgPacketHeader(PMsgPacket(Packets.Items[0]).Buffer).CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerConnectionManager.ReceiveMessage> Acknowledgement sent!');
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40519, ErrorRAckn+E.Message);
    end;
   BufferSize := 0;
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     BufferSize := BufferSize + Packet.BufferSize - SizeOf(TMsgPacketHeader);
    end;
   Buffer := MemoryManager.GetMem(BufferSize);
   pBuf := Buffer;
  // Copy to buffer then free MsgPackets
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     if Packet <> nil then
      begin
       if Packet.Buffer <> nil then
        begin
         Move(Pointer(Packet.Buffer+SizeOf(TMsgPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TMsgPacketHeader));
         inc(pBuf, Packet.BufferSize-SizeOf(TMsgPacketHeader));
         MemoryManager.FreeAndNilMem(Packet.Buffer);
        end;
       Dispose(Packet);
       Packets.Items[i] := nil;
      end;
    end;
   Packets.Count := 0;
  finally
   ServerSession.MsgReceivedPackets.UnlockList;
  end;
//  inc(ServerSession.ClientMessageID);
//  ServerSession.MsgReceiveStatus := MsgNo;
{
  EnterCSect(FCSect);
  if ServerSession.MsgControlCode = MsgSuspend then
    ServerSession.MsgControlCode := MsgExecute;
  LeaveCSect(FCSect);
}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('SERVER received full message from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
aaWriteToLog('==============================================================');
{$ENDIF}
end; // ReceiveMessage


//------------------------------------------------------------------------------
// ReceiveBuffer
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.ReceiveBuffer(
                          ServerSession:  PMsgSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
var
  i:                    Integer;
  Packet:               PMsgPacket;
  Packets:              TMsgList;
  pBuf:                 PAnsiChar;
  StartTime:            Cardinal;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.ReceiveBuffer - START');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('SERVER are receiving request from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
{$ENDIF}
  if ServerSession.ReceiveStatus <> MsgFull then
   begin
    while (ServerSession.ReceiveStatus <> MsgStart)
    and (ServerSession.ReceiveStatus <> MsgFull)
    do // Wait for starting answer receive
     begin
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
     end;
    StartTime := GetTickCount;
    while (ServerSession.ReceiveStatus <> MsgFull)
    do // Wait for all packets to arrive
     begin
      if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerReceiveTimeOut then
       raise EMsgException.Create(40025, ErrorRTimeoutFullReceive,
                                [ServerSession.Session.SessionID,
                                ServerSession.Session.ConnectParams.ServerReceiveTimeOut]);
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
     end;
   end;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received request from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.ReceiveBuffer> All packets received');
{$ENDIF}
  EnterCSect(FCSect);
  if ServerSession.ControlCode = MsgExecute then
    ServerSession.ControlCode := MsgSuspend;
  LeaveCSect(FCSect);
  BufferSize := 0;
  Packets := ServerSession.Packets.LockList;
  try
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     BufferSize := BufferSize + Packet.BufferSize - SizeOf(TMsgPacketHeader);
    end;
   if BufferSize > 0 then
     Buffer := MemoryManager.GetMem(BufferSize)
   else
     Buffer := nil;
   pBuf := Buffer;
  // Copy to buffer then free MsgPackets
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     if Packet <> nil then
      begin
       if Packet.Buffer <> nil then
        begin
         if (Packet.BufferSize > SizeOf(TMsgPacketHeader)) then
          begin
           Move(Pointer(Packet.Buffer+SizeOf(TMsgPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TMsgPacketHeader));
           inc(pBuf, Packet.BufferSize-SizeOf(TMsgPacketHeader));
          end;
         MemoryManager.FreeAndNilMem(Packet.Buffer);
        end;
       Dispose(Packet);
       Packets.Items[i] := nil;
      end;
    end;
   Packets.Count := 0;
  finally
   ServerSession.Packets.UnlockList;
  end;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('SERVER received full buffer from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
aaWriteToLog('==============================================================');
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.ReceiveBuffer - FINISH');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('SERVER<<< '+IntToStr(ServerSession.CurrentRequestID)+' :');
aaWriteBufferToLog(Buffer,BufferSize);
{$ENDIF}
end; // ReceiveBuffer


//------------------------------------------------------------------------------
// SendConnectAckn
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.SendConnectAckn(
                          ServerSession:        PMsgSrvrSession;
                          CurrentRequestID:     Integer = -1
                                                      );
var
  Buffer,
  Buf:                            PAnsiChar;
  BufSize, BufferSize,
  SizeSID, SizeParams:            Integer;
  ConnectParams:                  TMsgConnectParams;
  ConnectionParams:               TMsgConnectionParams;
  RequestID:                      Integer;
begin
  if ServerSession.Session.ConnectParams.UseServerSettings then
   begin
    TMsgServer(FServer).NetworkSettings.CopySettingsToConnectParams(ConnectParams);
    ConnectParams.CompressionAlgorithm := ServerSession.Session.ConnectParams.CompressionAlgorithm;
    ConnectParams.CompressionMode := ServerSession.Session.ConnectParams.CompressionMode;
    Buf := @ConnectParams;
    SizeParams := SizeOf(ConnectParams);
   end
  else
   begin
    ConnectionParams.PacketSize := ServerSession.Session.ConnectParams.PacketSize;
    ConnectionParams.CompressionAlgorithm := ServerSession.Session.ConnectParams.CompressionAlgorithm;
    ConnectionParams.CompressionMode := ServerSession.Session.ConnectParams.CompressionMode;
    Buf := @ConnectionParams;
    SizeParams := SizeOf(ConnectionParams);
   end;
  SizeSID := SizeOf(ServerSession.Session.SessionID);
  BufferSize := SizeParams + SizeSID;
  Buffer := MemoryManager.GetMem(BufferSize);
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('SERVER: SessionID='+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('SizeSID='+IntToStr(SizeSID)+', SizeParams='+IntToStr(SizeParams)+', BufferSize='+IntToStr(BufferSize));
{$ENDIF}
  try
   Move(Buf^, Buffer^, SizeParams); // copy connection parameters
   Move(ServerSession.Session.SessionID, (Buffer+SizeParams)^, SizeSID);
   if CurrentRequestID >= 0 then
    begin
     RequestID := ServerSession.CurrentRequestID;
     ServerSession.CurrentRequestID := CurrentRequestID;
    end;
   CompressAndEncryptBuffer(ServerSession.Session, Buffer, BufferSize, Buf, BufSize);
   try
    DoSendBuffer(ServerSession, Buf, BufSize, MsgConnected);
   finally
    if Buf<>Buffer then
      MemoryManager.FreeAndNilMem(Buf);
   end;

   if CurrentRequestID >= 0 then
     ServerSession.CurrentRequestID := RequestID;

   ServerSession.ReceiveStatus := MsgNo;
  finally
   MemoryManager.FreeAndNilMem(Buffer);
  end;
end;// SendConnectAckn


//------------------------------------------------------------------------------
// SendDisconnectRequest
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.SendDisconnectRequest(
                                    ServerSession: PMsgSrvrSession;
                                    WaitForAnswer: Boolean = True;
                                    PTerminated: Pointer = nil);
var
  Header:           PMsgPacketHeader;
  Retry:            Integer;
  StartTime:        Cardinal;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.SendDisconnectRequest> START');
{$ENDIF}
 try
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
   Header.ControlCode := MsgDisconnect;
   Header.Signature := MsgServerPacketSign;
   Header.Recepient := ServerSession.RemoteClientID;
   EnterCSect(FCSect);
   Header.Sender := FNetwork.FLocalClient;
   LeaveCSect(FCSect);
   Header.ConnectionID := ServerSession.ConnectionID;
   Header.SessionID := ServerSession.Session.SessionID;
   Header.PacketID := 0;
   Header.CurrentRequestID := ServerSession.CurrentRequestID;
   Retry := 0;
   ServerSession.SendStatus := MsgNotSent;
   repeat
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.SendDisconnectRequest> Retry = '+IntToStr(Retry));
aaWriteToLog('TMsgServerConnectionManager.SendDisconnectRequest> Delay = '+IntToStr(ServerSession.Session.ConnectParams.DisconnectDelay));
{$ENDIF}
     EnterCSect(FCSect);
     try
      FNetwork.RemoteHost := ServerSession.RemoteHost;
      FNetwork.RemotePort := ServerSession.RemotePort;
{
      if ServerSession.ControlCode = MsgTerminate then
//        raise EMSGException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession)],1);
}
      FNetwork.SendBuffer(PAnsiChar(Header), SizeOf(TMsgPacketHeader));
     finally
      LeaveCSect(FCSect);
     end;
     if not WaitForAnswer then
       Exit;
     StartTime := GetTickCount;
     while ((GetTickCount - StartTime) < ServerSession.Session.ConnectParams.DisconnectDelay) do // pause
      if ServerSession.SendStatus <> MsgSent then
       begin
        if Boolean(PTerminated^) = True then
         begin
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TMsgServerConnectionManager.SendDisconnectRequest>  Thread terminated!');
{$ENDIF}
          Exit;
         end;
        Sleep(ServerSession.Session.ConnectParams.ServerWaitForSendSleep);
{$IFDEF ProcessMessages}
        Application.ProcessMessages;
{$ENDIF ProcessMessages}
       end
      else
       Exit;
     inc(Retry);
   until  (Retry > ServerSession.Session.ConnectParams.DisconnectRetryCount);
   if ServerSession.SendStatus <> MsgSent then
    raise EMsgException.Create(40024, ErrorRCannotDisconnect,
                   ['client', ServerSession.ClientSessionID,
                    ServerSession.Session.ConnectParams.DisconnectRetryCount,
                    ServerSession.Session.ConnectParams.DisconnectDelay]);
  finally
   MemoryManager.FreeAndNilMem(Header);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.SendDisconnectRequest> FINISH');
{$ENDIF}
  end;
 except
{$IFDEF LOG_SERVER_DISCONNECT}
  on E: Exception do
    begin
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgConnection> TMsgServerSessionThread.Execute - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
     raise;
    end;
{$ELSE}
  raise;
{$ENDIF}
 end;
end;// SendDisconnectRequest


//------------------------------------------------------------------------------
// DeleteSession
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.DeleteSession(ServerSession: PMsgSrvrSession;
                            SkipServerSessionTermination: Boolean = False;
                            SaveMessages: Boolean = True);
var
  i,j:                  Integer;
  Packet:               PMsgPacket;
  Queue,
  Packets:              TMsgList;
  StartTime:            Cardinal;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> START');
{$ENDIF}
{$IFDEF MsgCommunicator}
  if ServerSession.Session <> nil then
    EnterCSect(TMsgServerSession(ServerSession.Session).FCSect);
  try
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
  EnterCSect(FCSect);
  try

   if ServerSession.CurrentRequestID = MsgTerminate then // <0, illegal value not used
    begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> session is already deleting - FINISH');
{$ENDIF}
     Exit;
    end;
   // block deleting ServerSession
   ServerSession.CurrentRequestID := MsgTerminate;

   // block using ServerSession
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DeleteSession> SERVER SESSION TERMINATE');
{$ENDIF}
   ServerSession.ControlCode := MsgTerminate;
   ServerSession.MsgControlCode := MsgTerminate;
   // free listenning threads lists
{
   ServerSession.ListeningThreads.Free;
   ServerSession.ListeningThreads := nil;
   ServerSession.MsgListeningThreads.Free;
   ServerSession.MsgListeningThreads := nil;
}
  finally
   LeaveCSect(FCSect);
  end;
  if not SkipServerSessionTermination then // No needs to terminate in connecting
    // wait for the end of current request execution
    CloseThread(@ServerSession.Thread,MsgServerDeleteSession,
        ErrorRServerSessionThread,
        ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut);
{
  WaitForServerSessionThread(ServerSession);
  if ServerSession.Thread <> nil then
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(ServerSession.Thread.ThreadID))+'/'+IntToStr(Integer(ServerSession.Thread.Handle))+
                  ErrorRExecute;
    try
     TMsgNetworkSession(ServerSession.Session).DoOnError(MsgServerDeleteSession,
                  40517,Error+
                  ErrorRCannotCloseThread+
                  IntToStr(MsgWaitForServerSessionThreadTimeOut));
    except
     TMsgServer(FServer).DoOnConnectionError(MsgServerDeleteSession,
                  40517,Error+
                  ErrorRCannotCloseThread+
                  IntToStr(MsgWaitForServerSessionThreadTimeOut));
    end;
    CloseThread(ServerSession.Thread.Handle, 0);
    WaitForServerSessionThread(ServerSession, MsgWaitForKillTimeOut);
    if ServerSession.Thread <> nil then
     begin
      try
       TMsgNetworkSession(ServerSession.Session).DoOnError(MsgServerDeleteSession,
                  40518,Error+
                  ErrorRCannotKillThread+
                  IntToStr(MsgWaitForKillTimeOut));
      except
       TMsgServer(FServer).DoOnConnectionError(MsgServerDeleteSession,
                  40518,Error+
                  ErrorRCannotKillThread+
                  IntToStr(MsgWaitForKillTimeOut));
      end;
     end;
   end;
}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free Session...');
{$ENDIF}
  // free PacketIDsToResend
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> wait for resending broken packets...');
{$ENDIF}
  // wait for resending broken packets
  StartTime := GetTickCount;
  repeat
    if ServerSession.PacketIDsToResend.ItemCount = 0 then
      break;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> sleep(1)');
{$ENDIF}
    sleep(1);
  until ((GetTickCount - StartTime) >= ServerSession.Session.ConnectParams.ServerSendTimeOut);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free PacketIDsToResend...');
{$ENDIF}
  ServerSession.PacketIDsToResend.Free;
  // free packets
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free packets...');
{$ENDIF}
  Packets := ServerSession.Packets.LockList;
  try
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     if Packet <> nil then
      begin
       if Packet.Buffer <> nil then
         MemoryManager.FreeAndNilMem(Packet.Buffer);
       Dispose(Packet);
      end;
    end;
  finally
   ServerSession.Packets.UnlockList;
  end;
  // free packets list
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free packet list...');
{$ENDIF}
  ServerSession.Packets.Free;
(*
  repeat
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> SessionID='+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> WaitFor message Session thread...');
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> MsgThread='+IntToStr(Integer(ServerSession.MsgThread)));
{$ENDIF}
    if ServerSession.MsgThread = nil then
      break;
    sleep(0);
  until False;
*)
  // free MsgPacketIDsToResend
{$IFDEF MsgCommunicator}
  EnterCSect(TMsgServerSession(ServerSession.Session).FCSect);
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> wait for resending broken message packets...');
{$ENDIF}
  repeat
    if ServerSession.MsgPacketIDsToResend.ItemCount = 0 then // wait for resending broken packets
      break;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> sleep(0) - 2');
{$ENDIF}
    sleep(0);
  until False;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free MsgPacketIDsToResend...');
{$ENDIF}
  ServerSession.MsgPacketIDsToResend.Free;
{$IFDEF MsgCommunicator}
  LeaveCSect(TMsgServerSession(ServerSession.Session).FCSect);
{$ENDIF}
  // free message packets
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free message packets...');
{$ENDIF}
  Packets := ServerSession.MsgPackets.LockList;
  try
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     if Packet <> nil then
      begin
       if Packet.Buffer <> nil then
         MemoryManager.FreeAndNilMem(Packet.Buffer);
       Dispose(Packet);
      end;
    end;
  finally
   ServerSession.MsgPackets.UnlockList;
  end;
  // free message packets list
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free message packet list...');
{$ENDIF}
  ServerSession.MsgPackets.Free;
  // Wait for message thread
  if ServerSession.MsgThread <> nil then
   begin
    if SaveMessages then
     begin
      Queue := ServerSession.MsgQueue.LockList;
      try
       if Queue.Count > 0 then
        begin
         if ServerSession.MsgThread = nil then
           ServerSession.MsgThread := TMsgServerSessionMsgThread.Create(self,
                                                                ServerSession);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> sleep(0) - 3');
{$ENDIF}
         sleep(0);
        end;
      finally
       ServerSession.MsgQueue.UnlockList;
      end;
     end;
    CloseThread(@ServerSession.MsgThread,MsgServerDeleteSession,ErrorRServerSessionMsgThread,
                          ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut);
   end;
  // release packets from queue
   Queue := ServerSession.MsgQueue.LockList;
   try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog('SERVER - DeleteSession> SessionID = '+IntToStr(ServerSession.Session.SessionID)+', Old Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    for i := 0 to Queue.Count - 1 do
     begin
      Packets := TMsgThreadList(Queue.Items[i]).LockList;
      try
       for j := 0 to Packets.Count - 1 do
        begin
         Packet := Packets.Items[j];
         if Packet <> nil then
          begin
           if Packet.Buffer <> nil then
             MemoryManager.FreeAndNilMem(Packet.Buffer);
           Dispose(Packet);
          end;
        end;
      Packets.Clear;
      finally
       TMsgThreadList(Queue.Items[i]).UnlockList;
       TMsgThreadList(Queue.Items[i]).Free;
      end;
     end;
   Queue.Clear;
   finally
    ServerSession.MsgQueue.UnlockList;
    ServerSession.MsgQueue.Free;
    ServerSession.MsgQueue := nil;
   end;
  // free Received message packets
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free Received message packets...');
{$ENDIF}
  if ServerSession.MsgReceivedPackets <> nil then
   begin
  Packets := ServerSession.MsgReceivedPackets.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> List Locked!');
{$ENDIF}
    try
     for i := 0 to Packets.Count - 1 do
      begin
       Packet := Packets.Items[i];
       if Packet <> nil then
        begin
         if Packet.Buffer <> nil then
           MemoryManager.FreeAndNilMem(Packet.Buffer);
         Dispose(Packet);
        end;
      end;
    finally
     ServerSession.MsgReceivedPackets.UnlockList;
    end;
  // free Received message packets list
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> free Received message packet list...');
{$ENDIF}
    ServerSession.MsgReceivedPackets.Free;
   end;
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DeleteSession> wait for vacant ServerSession - SERVER SESSION TERMINATE');
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> wait for vacant ServerSession...');
{$ENDIF}
  // wait for vacant ServerSession
  repeat
    // block using ServerSession
    EnterCSect(FCSect);
    ServerSession.ControlCode := MsgTerminate;
    ServerSession.MsgControlCode := MsgTerminate;
    LeaveCSect(FCSect);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> sleep(0) - 4');
{$ENDIF}
    sleep(0);
    if (ServerSession.Status = MsgVacant) then
      break;
  until False;
{$IFDEF MsgCommunicator}
  finally
   if ServerSession.Session <> nil then
     LeaveCSect(TMsgServerSession(ServerSession.Session).FCSect);
  end;
{$ENDIF}
  // free session
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
  if ServerSession.Session <> nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> Free Session...');
{$ENDIF}
    ServerSession.Session.Free;
    ServerSession.Session := nil;
   end;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> Dispose(ServerSession)...');
{$ENDIF}
  Dispose(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DeleteSession> FINISH');
{$ENDIF}
end; // DeleteSession


//------------------------------------------------------------------------------
// DoDisconnect
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.DoDisconnect(Session: TMsgComBaseSession;
                            SkipServerSessionTermination: Boolean = False);
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> START');
aaWriteToLog('Session = '+IntToStr(Integer(Session)));
{$ENDIF}
(*
{$IFDEF MsgCommunicator}
       if not FListenerStoped then
         TMsgServerSession(Session).DisconnectUser;
{$ENDIF}
*)
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> LockSessions...');
{$ENDIF}
  Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> FSessions Locked');
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> Sessions.Count='+IntToStr(Sessions.Count));
{$ENDIF}
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     if (i<0)
     or (i>=Sessions.Count)
     then
       break;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> get Session...');
{$ENDIF}
     ServerSession := Sessions.Items[i];
     if ServerSession <> nil then
     if ServerSession.Session = Session then
      begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> SessionID = '+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> enter CS...');
{$ENDIF}
       EnterCSect(FCSect);
       if (ServerSession.ControlCode <> MsgTerminate)
       or (ServerSession.MsgControlCode <> MsgTerminate)
       then
        begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> stop ping...');
{$ENDIF}
         // Stop ping
         ServerSession.Connected := False;
         // Terminate sending threads
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DoDisconnect> SERVER SESSION TERMINATE');
{$ENDIF}
         ServerSession.ControlCode := MsgTerminate;
         ServerSession.MsgControlCode := MsgTerminate;
         LeaveCSect(FCSect);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Session = '+IntToStr(Integer(Session)));
aaWriteToLog('ServerSession.Session = '+IntToStr(Integer(ServerSession.Session)));
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> CS leaved...');
{$ENDIF}

{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Terminate message listening threads...');
{$ENDIF}
//         TerminateMessageThreads(ServerSession);

{$IFDEF MsgCommunicator}
         // block sendmessage
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> Session CS entering...');
 {$ENDIF}
         if ServerSession.Session <> nil then
           EnterCSect(TMsgServerSession(ServerSession.Session).FCSect);
         try
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> Unlock Session list...');
{$ENDIF}
         FSessions.UnlockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> remove incoming session packets...');
{$ENDIF}
         // Terminate listening threads
//         TerminateCommandThreads(ServerSession);
         TerminateAllSessionThreads(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> All sessions terminated');
{$ENDIF}
         // delete session from list
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Remove SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
         FSessions.Remove(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Removed SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
{$IFDEF MsgCommunicator}
         finally
          if ServerSession.Session <> nil then
            LeaveCSect(TMsgServerSession(ServerSession.Session).FCSect);
         end;
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Session CS left');
 {$ENDIF}
{$ENDIF}
         // free memory and session
         DeleteSession(ServerSession,SkipServerSessionTermination);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Session deleted');
{$ENDIF}
         Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Sessions locked');
{$ENDIF}
        end
       else
         LeaveCSect(FCSect);
(*
       // Terminate all threads
       FSessions.UnlockList;
       TerminateAllSessionThreads(ServerSession);
       // delete session from list
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> Session remove session from list...');
{$ENDIF}
       FSessions.Remove(ServerSession);
       // free memory and session
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> Delete SessionID='+IntToStr(ServerSession.Session.SessionID)+'...');
{$ENDIF}
       DeleteSession(ServerSession);
       Sessions:=FSessions.LockList;
*)
       break;
      end;
    end;
  finally
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DoDisconnect> Sessions.Count='+IntToStr(Sessions.Count));
{$ENDIF}
   FSessions.UnlockList;
  end;
end; // DoDisconnect


//------------------------------------------------------------------------------
// TerminateSession
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.TerminateSession(Session: TMsgComBaseSession);
begin
  if SessionTerminator <> nil then
    if SessionTerminator.FTerminatedSessions <> nil then
      SessionTerminator.FTerminatedSessions.Add(Session);
end;// TerminateSession


//------------------------------------------------------------------------------
// disconnect client by Host:Port
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.DisconnectClient(const Host: AnsiString; const Port: Integer);
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  Session:              TMsgComBaseSession;
  i:                    Integer;
  Found:                Boolean;
begin
  Found := False;
  Session := nil;
  Sessions:=FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     ServerSession := Sessions.Items[i];
     if (
            (Host = ServerSession.RemoteHost)
            and
            (Port = ServerSession.RemotePort)
         )
     then
      begin
       Session := ServerSession.Session;
       Found := True;
       break;
      end;
    end; // for
  finally
   FSessions.UnlockList;
  end;
  if Found then
    TerminateSession(Session);
end; // disconnect client by Host:Port


//------------------------------------------------------------------------------
// disconnect client by SessionID
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.DisconnectClient(const SessionID: Integer);
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  Session:              TMsgComBaseSession;
  i:                    Integer;
  Found:                Boolean;
begin
  Found := False;
  Session := nil;
  Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.Disconnect> FSessions Locked');
{$ENDIF}
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session.SessionID = SessionID then
      begin
       Session := ServerSession.Session;
       Found := True;
       break;
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if Found then
    TerminateSession(Session);
end; // disconnect client by SessionID


//------------------------------------------------------------------------------
// Disconnect
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.Disconnect(Session: TMsgComBaseSession; PTerminated: Pointer = nil);
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
  Found:                Boolean;
begin
  Found := False;
  Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.Disconnect> FSessions Locked');
{$ENDIF}
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session = Session then
      begin
       Found := True;
       break;
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if not Found then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);

  EnterCSect(FCSect);
  ServerSession.ControlCode := MsgSuspend;
  ServerSession.MsgControlCode := MsgSuspend;
  LeaveCSect(FCSect);

  try
   SendDisconnectRequest(ServerSession);
  finally
{
  EnterCSect(FCSect);
  ServerSession.ControlCode := MsgTerminate;
  ServerSession.MsgControlCode := MsgTerminate;
  LeaveCSect(FCSect);
}

   DoDisconnect(Session);
  end;

end; // Disconnect


//------------------------------------------------------------------------------
// DisconnectAll
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.DisconnectAll(WaitForAllDisconnected: Boolean = True);
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> START');
{$ENDIF}
if FSessions<>nil then
begin
try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> Lock FSessions...');
{$ENDIF}
 Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> FSessions Locked');
{$ENDIF}
 try
//  while Sessions.Count>=1 do
  for i:=Sessions.Count-1 downto 0 do
   begin
    if (i<0)
    or (i>=Sessions.Count)
    then
      break;
    ServerSession := Sessions.Items[i];
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> EnterCSect...');
{$ENDIF}
    EnterCSect(FCSect);
    if (ServerSession.ControlCode <> MsgTerminate)
    or (ServerSession.MsgControlCode <> MsgTerminate)
    then
     begin
      // Stop ping
      ServerSession.Connected := False;
      // Terminate sending threads
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> Terminate sending threads...');
{$ENDIF}
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DisconnectAll> SERVER SESSION TERMINATE');
{$ENDIF}
      ServerSession.ControlCode := MsgTerminate;
      ServerSession.MsgControlCode := MsgTerminate;
      LeaveCSect(FCSect);
      // Block sending message
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> Block sending message...');
{$ENDIF}
{$IFDEF MsgCommunicator}
      if ServerSession.Session <> nil then
        EnterCSect(TMsgServerSession(ServerSession.Session).FCSect);
      try
{$ENDIF}
      FSessions.UnlockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> SendDisconnectRequest');
{$ENDIF}
      // send
      try
       SendDisconnectRequest(ServerSession, False);
      except
       // ignore all exceptions while disconnecting
      end;
      // Terminate all threads
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> TerminateAllSessionThreads...');
{$ENDIF}
      TerminateAllSessionThreads(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> All session threads terminated');
{$ENDIF}
      // delete session from list
      FSessions.Remove(ServerSession);
      // free memory and session
{$IFDEF MsgCommunicator}
      finally
       if ServerSession.Session <> nil then
        LeaveCSect(TMsgServerSession(ServerSession.Session).FCSect);
      end;
{$ENDIF}
      DeleteSession(ServerSession,False,WaitForAllDisconnected);
      Sessions:=FSessions.LockList;
     end
    else
      LeaveCSect(FCSect);
   end;
 finally
  FSessions.UnlockList;
 end;
  // Wait for all sessions be disconnected
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> WaitForAllDisconnected...');
{$ENDIF}
  if WaitForAllDisconnected then
    repeat
      Sessions:=FSessions.LockList;
      try
       if Sessions.Count = 0 then
         break;
      finally
       FSessions.UnlockList;
      end;
      sleep(1);
    until False;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> All Disconected!');
{$ENDIF}
except
{$IFDEF LOG_SERVER_DISCONNECT}
  on E: Exception do
    begin
aaWriteToLog('**************************************************************');
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
    end;
{$ENDIF}
end;
end;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.DisconnectAll> FINISH');
{$ENDIF}
end; // DisconnectAll


//------------------------------------------------------------------------------
// SessionsCount
//------------------------------------------------------------------------------
function TMsgServerConnectionManager.SessionsCount: Integer;
var
  Sessions:           TMsgList;
begin
  Sessions := FSessions.LockList;
  try
    Result := Sessions.Count;
  finally
    FSessions.UnlockList;
  end;
end;// SessionsCount


//------------------------------------------------------------------------------
// is session terminated
//------------------------------------------------------------------------------
function TMsgServerConnectionManager.IsSessionTerminated(ClientSession: Pointer): Boolean;
var
  Sessions:     TMsgList;
  i:            Integer;
begin
  Result := False;
  Sessions := FTerminatedSessions.LockList;
  try
   for i := Sessions.Count-1 downto 0 do
     if (Sessions.Items[i] = ClientSession)
      then
       begin
        Result := True;
        break;
       end;
  finally
   FTerminatedSessions.UnlockList;
  end;
end; // is terminated session


//------------------------------------------------------------------------------
// TerminateMessageThreads
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.TerminateMessageThreads(ServerSession: PMsgSrvrSession);
var
  i:                    Integer;
//  Count:                Integer;
  WaitFor,
  StartTime:            Cardinal;
//  Threads:              TMsgList;
//  Thread:               TThread;
//  Error:                AnsiString;
  Queue:                TMsgList;
  found:                Boolean;
begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> START');
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> START');
{$ENDIF}
try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> Check incoming queue...');
{$ENDIF}
// Check incoming queue
  repeat
   found := false;
   Queue := FIncomingPackets.LockList;
   try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> start Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    for i:=Queue.Count-1 downto 1 do // 0 element will be processed by listener thread
     begin
      if ServerSession.Session = nil then
        begin
         found := true;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> nil - break');
{$ENDIF}
         break;
        end;
      if PMsgPacketHeader(PMsgNetworkPacket(Queue.Items[i]).Packet.Buffer).SessionID = ServerSession.Session.SessionID then
       if (PMsgPacketHeader(PMsgNetworkPacket(Queue.Items[i]).Packet.Buffer).ControlCode = MsgMessage)
       or (PMsgPacketHeader(PMsgNetworkPacket(Queue.Items[i]).Packet.Buffer).ControlCode = MsgMessage+MsgLastPacket)
       then
        begin
         found := true;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> found! - wait...');
{$ENDIF}
         break;
        end;
     end; // for
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> end Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
   finally
    FIncomingPackets.UnlockList;
   end;
   sleep(1);
  until not found;

{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> Check session queue...');
{$ENDIF}
// Check session queue
  StartTime := GetTickCount;
  if ServerSession.Session <> nil then
   begin
    WaitFor := ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> check for nil... ');
{$ENDIF}
    if ServerSession.MsgQueue <> nil then
       repeat
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> lock... ');
{$ENDIF}
        Queue := ServerSession.MsgQueue.LockList;
        try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
         if Queue.Count = 0 then
           break;
        finally
         ServerSession.MsgQueue.UnlockList;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> unlock... ');
{$ENDIF}
        end;
        if (GetTickCount - StartTime) > WaitFor then
          break;
        sleep(1); // waite for message processing
       until false;
   end;

{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> Check msgthread...');
{$ENDIF}
// Check msgthread
       while (ServerSession.MsgThread <> nil) do
         sleep(1); // white for message processing

{$IFDEF MsgCommunicator}
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> DisconnectUser...');
{$ENDIF}
       if not FListenerStoped then
         TMsgServerSession(ServerSession.Session).DisconnectUser;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> User disconnected!');
{$ENDIF}
{$ENDIF}



(*
  sleep(0); // to allow finishing listening threads
  Threads := ServerSession.MsgListeningThreads.LockList;
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
  try
   for i := 0 to Threads.Count-1 do
    begin
     Thread := Threads.Items[i];
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
     CloseThread(@Thread,MsgServerConnectionManager,ErrorRListenerMsgThread);
    end;
  finally
   ServerSession.MsgListeningThreads.UnlockList;
  end;
*)
(*
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> START');
{$ENDIF}
  if ServerSession.MsgListeningThreads = nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> MsgListeningThreads = nil - FINISH');
{$ENDIF}
    Exit;
   end;
  EnterCSect(FCSect);
  ServerSession.MsgControlCode := MsgTerminate;
  LeaveCSect(FCSect);
  // Wait for finishes of all the threads
  StartTime := GetTickCount;
  repeat
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> MsgListeningThreads.LockList...');
{$ENDIF}
   // Terminate message listening threads
   Threads := ServerSession.MsgListeningThreads.LockList;
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> MsgListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
   try
    for i := 0 to Threads.Count-1 do
     begin
      Thread := Threads.Items[i];
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
      if (Thread <> nil) then
        Thread.Terminate;
      sleep(0);
     end;
   finally
    ServerSession.MsgListeningThreads.UnlockList;
   end;
   sleep(0);
   // Check
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> CHECKING...');
{$ENDIF}
   Threads := ServerSession.MsgListeningThreads.LockList;
   try
    Count := Threads.Count;
   finally
    ServerSession.MsgListeningThreads.UnlockList;
   end;
   if (Count = 0) then break
   else
    begin
     if (GetTickCount - StartTime) > MsgServerThreadsTerminateDelay then
      begin
       Error := IntToStr(Count)+' message listening threads';
       raise EMsgException.Create(40036, ErrorRThreadHangs,
            ['Server session # '+IntToStr(ServerSession.Session.SessionID),
            Error]);
      end;
    end;
  until False;
*)
finally
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateMessageThreads> FINISH');
{$ENDIF}
end;
end; // TerminateMessageThreads


//------------------------------------------------------------------------------
// TerminateCommandThreads
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.TerminateCommandThreads(ServerSession: PMsgSrvrSession);
var
  i:                    Integer;
{
  Count:                Integer;
  StartTime:            Cardinal;
  Threads:              TMsgList;
  Thread:               TThread;
var
 Packet:            PMsgPacket;
}
 NetworkPacket:     PMsgNetworkPacket;
 Packets:           TMsgList;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> START');
{$ENDIF}
  if (ServerSession = nil)
  or (ServerSession.Session = nil) then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> nil - Exit!');
{$ENDIF}
    Exit;
   end;
  Packets := FIncomingPackets.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> locked!');
{$ENDIF}
  try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> Packets.Count = '+IntToStr(Packets.Count));
{$ENDIF}
   for i:=Packets.Count-1 downto 1 do // 0 element will be processed by listener thread
    begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> check #'+IntToStr(i));
{$ENDIF}
     if PMsgPacketHeader(PMsgNetworkPacket(Packets.Items[i]).Packet.Buffer).SessionID = ServerSession.Session.SessionID then
     if (PMsgPacketHeader(PMsgNetworkPacket(Packets.Items[i]).Packet.Buffer).ControlCode <> MsgMessage) then
     if (PMsgPacketHeader(PMsgNetworkPacket(Packets.Items[i]).Packet.Buffer).ControlCode <> MsgMessage+MsgLastPacket) then
      begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> found #'+IntToStr(i));
{$ENDIF}
       NetworkPacket := Packets.Items[i];
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> free buffer...');
{$ENDIF}
       if (NetworkPacket.Packet.Buffer <> nil) then
         MemoryManager.FreeAndNilMem(NetworkPacket.Packet.Buffer);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> dispose packet...');
{$ENDIF}
       Dispose(NetworkPacket.Packet);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> dispose network packet...');
{$ENDIF}
       Dispose(NetworkPacket);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> delete packet fro incoming queue...');
{$ENDIF}
       Packets.Delete(i);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> OK - find next...');
{$ENDIF}
      end;
    end; // for
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> finishing - OK...');
{$ENDIF}
  finally
   FIncomingPackets.UnlockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> unlocked!');
{$ENDIF}
  end;
  Exit;
try
(*
  sleep(0); // to allow finishing listening threads
  Threads := ServerSession.ListeningThreads.LockList;
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
  try
   for i := 0 to Threads.Count-1 do
    begin
     Thread := Threads.Items[i];
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
     CloseThread(@Thread,MsgServerConnectionManager,ErrorRListenerThread);
    end;
  finally
   ServerSession.ListeningThreads.UnlockList;
  end;
*)
(*
  Error:                AnsiString;

procedure LogHangedThreads(EMessage: AnsiString; ENativeCode: Integer; Kill: Boolean = False);
var
  i:                    Integer;
begin
    Threads := ServerSession.ListeningThreads.LockList;
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
    try
     for i := 0 to Threads.Count-1 do
      begin
       Thread := Threads.Items[i];
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
       if (Thread <> nil) then
        begin
         Error:=
                  EMessage+
                  ErrorRServer+ErrorRListenerThread+
                  IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle))+
                  ErrorRExecute;
         if Kill then
           Error := Error+ErrorRCannotKillThread+IntToStr(MsgWaitForKillTimeOut)
         else
           Error := Error+ErrorRCannotCloseThread+IntToStr(MsgServerThreadsTerminateDelay);
         try
          TMsgNetworkSession(ServerSession.Session).DoOnError(MsgServerTerminateCommandThreads,ENativeCode,Error);
         except
          TMsgServer(FServer).DoOnConnectionError(MsgServerTerminateCommandThreads,ENativeCode,Error);
         end;
         if not Kill then
           CloseThread(Thread.Handle, 0);
//         sleep(0);
        end;
      end;
    finally
     ServerSession.ListeningThreads.UnlockList;
    end;
end; // LogHangedThreads

function IsListeningThreadExisting(TimeOut: Cardinal): Boolean;
begin
 Result := True;
 Threads := ServerSession.ListeningThreads.LockList;
 try
  Count := Threads.Count;
 finally
  ServerSession.ListeningThreads.UnlockList;
 end;
 if (Count = 0) then
  begin
   Result := False;
   Exit;
  end
 else
  begin
   if (GetTickCount - StartTime) > TimeOut then
    begin
     Error := IntToStr(Count)+' command listening threads';
     raise EMsgException.Create(40036, ErrorRThreadHangs,
           ['Server session # '+IntToStr(ServerSession.Session.SessionID),
            Error]);
    end;
  end;
end; // IsListeningThreadExisting

begin //TerminateCommandThreads
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> START');
{$ENDIF}
try // finally
  if ServerSession.ListeningThreads = nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> ListeningThreads = nil - FINISH');
{$ENDIF}
    Exit;
   end;
  EnterCSect(FCSect);
  ServerSession.ControlCode := MsgTerminate;
  LeaveCSect(FCSect);
 try // except
  StartTime := GetTickCount;
  repeat   // Wait for finishes of all the threads
    // Terminate all command listening threads
    Threads := ServerSession.ListeningThreads.LockList;
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
    try
     for i := 0 to Threads.Count-1 do
      begin
       Thread := Threads.Items[i];
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
       if (Thread <> nil) then
         Thread.Terminate;
       sleep(0);
      end;
    finally
     ServerSession.ListeningThreads.UnlockList;
    end;
    sleep(0);
    if not IsListeningThreadExisting(MsgServerThreadsTerminateDelay) then
      Exit;
  until False;
 except
  on E: EMsgException do
    LogHangedThreads(E.Message,E.NativeError,False);
 end; // exception
 try
  StartTime := GetTickCount;
  IsListeningThreadExisting(MsgWaitForKillTimeOut);
 except
  on E: EMsgException do
    LogHangedThreads(E.Message,E.NativeError,True);
 end; // exception
*)
finally
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.TerminateCommandThreads> FINISH');
{$ENDIF}
end;
end; // TerminateCommandThreads


//------------------------------------------------------------------------------
// TerminateAllSessionThreads
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.TerminateAllSessionThreads(ServerSession: PMsgSrvrSession);
begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateAllSessionThreads> TerminateCommandThreads...');
{$ENDIF}
  TerminateCommandThreads(ServerSession);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateAllSessionThreads> TerminateMessageThreads...');
{$ENDIF}
  TerminateMessageThreads(ServerSession);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.TerminateAllSessionThreads> finish');
{$ENDIF}
end; // TerminateAllSessionThreads


//------------------------------------------------------------------------------
// DoSendBuffer
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.DoSendBuffer(
                          ServerSession:    PMsgSrvrSession;
                          Buffer:           PAnsiChar;
                          BufferSize:       Integer;
                          Code:             Integer = MsgNoAction
                                                  );
var
  Header:               PMsgPacketHeader;
  Packets:              TMsgList;
  Packet:               PMsgPacket;
  BytesSent, DataSize:  Integer;
  i:                    Integer;

procedure FirstResend;
begin
 // resend last packet for the first time
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('FirstResend');
{$ENDIF}
 Packet := Packets.Items[Packets.Count-1];
 EnterCSect(FCSect);
 try
  FNetwork.RemoteHost := ServerSession.RemoteHost;
  FNetwork.RemotePort := ServerSession.RemotePort;
  FNetwork.SendBuffer(Packet.Buffer, Packet.BufferSize);
 finally
  LeaveCSect(FCSect);
 end;
end; // FirstResend

procedure WaitForCommandSent;
var
  PacketID,
  ControlCode,
  i:                    Integer;
{$IFDEF LOG_SERVER_RESENDING}
  j:                    Integer;
  Retry:                 Integer;
{$ENDIF}
  Delay,
  StartTime,
  StartSleepTime:       Cardinal;
begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForCommandSent> - START');
{$ENDIF}
 try
  EnterCSect(FCSect);
  ControlCode := ServerSession.ControlCode;
  ServerSession.ControlCode := MsgExecute;
  LeaveCSect(FCSect);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server waits for all packets');
{$ENDIF}
  if not ((Code = MsgConnect) or (Code = (MsgConnect + MsgLastPacket))) then
   begin
(*
{$IFDEF ProcessMessages}
    Application.ProcessMessages;
{$ENDIF ProcessMessages}
    Sleep(MsgServerReceiveSleep); // To avoid delay if full answer is already received
*)
{
// code to force push up sending in case of more than 10 packets message
    if (ServerSession.SendStatus <> MsgSent) then
      sleep(MsgFirstResendPushUpTimeout);
    if (ServerSession.SendStatus <> MsgSent) then
      FirstResend;
}
    i := ServerSession.PacketIDsToResend.ItemCount;
    Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
    StartTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartTime = '+IntToStr(StartTime));
Retry := 0;
{$ENDIF}
    while not (ServerSession.SendStatus = MsgSent) do  // resend broken packets
     begin
{$IFDEF LOG_SERVER_RESENDING}
inc(Retry);
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer>WaitForCommandSent> Retry = '+IntToStr(Retry));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer>WaitForCommandSent> Delay = '+IntToStr(ServerSession.Session.ConnectParams.DisconnectDelay));
aaWriteToLog('SendStatus <> MsgSent = '+IntToStr(ServerSession.SendStatus)+' <> '+IntToStr(MsgSent));
{$ENDIF}
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
//      Sleep(MsgServerResendDelay);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server has '+IntToStr(ServerSession.PacketIDsToResend.ItemCount)+' packets to resend:');
{$ENDIF}
      if ServerSession.PacketIDsToResend.ItemCount = 0 then
       begin // no packets to resend -- sleep
        StartSleepTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartSleepTime = '+IntToStr(StartSleepTime));
aaWriteToLog('Delay = '+IntToStr(Delay));
{$ENDIF}
        while ((GetTickCount - StartSleepTime) < Delay) do  // sleep after last packet send
         begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('GetTickCount = '+IntToStr(GetTickCount)+' < (StartSleepTime + ServerResendDelay = '+IntToStr(ServerSession.Session.ConnectParams.ServerResendDelay)+')');
{$ENDIF}
          if ServerSession.SendStatus = MsgSent then
            Exit;
          if ServerSession.ControlCode = MsgTerminate then // added as analogue of client
            raise EMsgException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),2]);
          if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerSendTimeOut then
           begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TimeOut: StartTime='+IntToStr(StartTime)+', ServerSendTimeOut='+IntToStr(ServerSession.Session.ConnectParams.ServerSendTimeOut));
{$ENDIF}
            raise EMsgException.Create(40078, ErrorRServerTimeOutSending,
              ['command',
{$IFDEF MsgCommunicator}
              ServerSession.Session.UserID,
{$ELSE}
              ServerSession.Session.SessionID,
{$ENDIF}
              ServerSession.Session.ConnectParams.ServerSendTimeOut]);
           end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('SleepTime = '+IntToStr(ServerSession.Session.ConnectParams.ServerWaitForSendSleep));
{$ENDIF}
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer-WaitForCommandSent> sleep for '+IntToStr(ServerSession.Session.ConnectParams.ServerWaitForSendSleep));
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-DoSendBuffer-WaitForCommandSent> Sleep('+IntToStr(ServerSession.Session.ConnectParams.ServerWaitForSendSleep)+'...');
{$ENDIF}
          Sleep(ServerSession.Session.ConnectParams.ServerWaitForSendSleep);
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-DoSendBuffer-WaitForCommandSent> up!');
{$ENDIF}
         end; // sleep
       end // no packets to resend
      else
       begin
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer-WaitForCommandSent> sleep(0)');
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-DoSendBuffer-WaitForCommandSent> no packets to resend - Sleep(0)...');
{$ENDIF}
        Sleep(0);
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-DoSendBuffer-WaitForCommandSent> no packets to resend - up!');
{$ENDIF}
       end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server has '+IntToStr(ServerSession.PacketIDsToResend.ItemCount)+' packets to resend:');
for j:=0 to ServerSession.PacketIDsToResend.ItemCount-1 do
aaWriteToLog(IntToStr(ServerSession.PacketIDsToResend.Items[j]));
{$ENDIF}
      dec(i);
      if (i<0) then
        i := ServerSession.PacketIDsToResend.ItemCount - 1;
      try
       ServerSession.PacketIDsToResend.Lock;
       if (ServerSession.PacketIDsToResend.ItemCount > i) then
        begin
         if i>=0 then // Packet to resend exists
          begin
           PacketID := ServerSession.PacketIDsToResend.Items[i];
           ServerSession.PacketIDsToResend.Unlock;
           if PacketID >= Packets.Count then // Erroneous situation which is must not exist
             Continue;
          end
         else // No packets to resend - Resend last packet
          begin
           ServerSession.PacketIDsToResend.Unlock;
           PacketID := Packets.Count - 1;
          end;
         Packet := Packets.Items[PacketID];
         // resend packet
         EnterCSect(FCSect);
         try
          FNetwork.RemoteHost := ServerSession.RemoteHost;
          FNetwork.RemotePort := ServerSession.RemotePort;
          if ServerSession.ControlCode = MsgTerminate then
            raise EMsgException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),3]);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Current Time = '+IntToStr(GetTickCount));
{$ENDIF}
          FNetwork.SendBuffer(Packet.Buffer, Packet.BufferSize);
          if i<0 then  // No packets to resend, increase pause
            Delay := Delay * 2
          else  // Restore default pause in case of packets resending
            Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
          if Delay = 0 then
            Delay := MsgServerResendDelay;
         finally
          LeaveCSect(FCSect);
         end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server resent packet # '+IntToStr(PacketID));
{$ENDIF}
        end
      else
        ServerSession.PacketIDsToResend.Unlock;
      finally
       ServerSession.PacketIDsToResend.Lock;
       if  (ServerSession.PacketIDsToResend.ItemCount > 0)
       and (ServerSession.PacketIDsToResend.ItemCount > i)
       then
//         ServerSession.PacketIDsToResend.Delete(i);
         ServerSession.PacketIDsToResend.Remove(PacketID);
       ServerSession.PacketIDsToResend.Unlock;
      end; // finally
     end; // loop
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('SendStatus = MsgSent, Time = '+IntToStr(GetTickCount));
{$ENDIF}
   end; // no Connect
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server sent all the packets');
{$ENDIF}
  EnterCSect(FCSect);
  ServerSession.ControlCode := ControlCode;
  LeaveCSect(FCSect);
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('**************************************************************');
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForCommandSent> - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
     raise;
    end;
 end;
end; // WaitForCommandSent

procedure WaitForMessageSent;
var
  PacketID,
  ControlCode,
  i:                    Integer;
  Delay,
  StartTime,
  StartSleepTime:       Cardinal;
begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> - START');
{$ENDIF}
 try
  EnterCSect(FCSect);
  ControlCode := ServerSession.MsgControlCode;
  ServerSession.MsgControlCode := MsgExecute;
  LeaveCSect(FCSect);
(*
{$IFDEF ProcessMessages}
    Application.ProcessMessages;
{$ENDIF ProcessMessages}
    Sleep(MsgServerReceiveSleep); // To avoid delay if full answer is already received
*)
{
// code to force push up sending in case of more than 10 packets message
  if (ServerSession.MsgSendStatus <> MsgSent) then
    sleep(20);
  if (ServerSession.MsgSendStatus <> MsgSent) then
    FirstResend;
}
  i := ServerSession.MsgPacketIDsToResend.ItemCount;
  Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
  StartTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartTime = '+IntToStr(StartTime));
{$ENDIF}
  while not (ServerSession.MsgSendStatus = MsgSent) do  // resend broken packets
     begin
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
//      Sleep(MsgServerResendDelay);
      if ServerSession.MsgPacketIDsToResend.ItemCount = 0 then
       begin
        StartSleepTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartSleepTime = '+IntToStr(StartSleepTime));
aaWriteToLog('Delay = '+IntToStr(Delay));
{$ENDIF}
        while ((GetTickCount - StartSleepTime) < Delay) do  // sleep after last packet send
         begin
          if ServerSession.MsgSendStatus = MsgSent then
            Exit;
          if ServerSession.MsgControlCode = MsgTerminate then // added as analogue of client
            raise EMsgException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
          if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerSendTimeOut then
            raise EMsgException.Create(40078, ErrorRServerTimeOutSending,
              ['message',
{$IFDEF MsgCommunicator}
              ServerSession.Session.UserID,
{$ELSE}
              ServerSession.Session.SessionID,
{$ENDIF}
              ServerSession.Session.ConnectParams.ServerSendTimeOut]);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer-WaitForMessageSent> sleep for '+IntToStr(ServerSession.Session.ConnectParams.ServerWaitForSendSleep));
{$ENDIF}
          Sleep(ServerSession.Session.ConnectParams.ServerWaitForSendSleep);
         end; // sleep loop
       end
      else
       begin
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer-WaitForMessageSent> sleep(0)');
{$ENDIF}
        Sleep(0);
       end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> New step');
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> SessionID='+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.Session='+IntToStr(Integer(ServerSession.Session)));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> i='+IntToStr(i));
{$ENDIF}
      dec(i);
      if i<0 then
        i := ServerSession.MsgPacketIDsToResend.ItemCount - 1;
      try
       ServerSession.MsgPacketIDsToResend.Lock;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> MsgPacketIDsToResend.ItemCount = '+IntToStr(ServerSession.MsgPacketIDsToResend.ItemCount));
{$ENDIF}
       if (ServerSession.MsgPacketIDsToResend.ItemCount > i) then
        begin
         if i>=0 then // Packet to resend exists
          begin
           PacketID := ServerSession.MsgPacketIDsToResend.Items[i];
           ServerSession.MsgPacketIDsToResend.Unlock;
           if PacketID >= Packets.Count then
             Continue;
          end
         else // No packets to resend - Resend last packet
          begin
           ServerSession.MsgPacketIDsToResend.Unlock;
           PacketID := Packets.Count - 1;
          end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> PacketID = '+IntToStr(PacketID));
{$ENDIF}
         Packet := Packets.Items[PacketID];
         // resend packet
         EnterCSect(FCSect);
         try
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog(IntToStr(GetTickCount)+':');
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> FNetwork=');
aaWriteToLog(IntToHex(Integer(FNetwork),6));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> RemoteHost=');
aaWriteToLog(ServerSession.RemoteHost);
{$ENDIF}
          FNetwork.RemoteHost := ServerSession.RemoteHost;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> RemotePort=');
aaWriteToLog(IntToStr(ServerSession.RemotePort));
{$ENDIF}
          FNetwork.RemotePort := ServerSession.RemotePort;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> Sending...');
{$ENDIF}
          if ServerSession.MsgControlCode = MsgTerminate then
            raise EMsgException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
          FNetwork.SendBuffer(Packet.Buffer, Packet.BufferSize);
          if i<0 then  // No packets to resend, increase pause
            Delay := Delay * 2
          else  // Restore default pause in case of packets resending
            Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
          if Delay = 0 then
            Delay := MsgServerResendDelay;
         finally
          LeaveCSect(FCSect);
         end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> Sent!');
{$ENDIF}
        end
      else
        ServerSession.MsgPacketIDsToResend.Unlock;
      finally
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> Locking...');
{$ENDIF}
       ServerSession.MsgPacketIDsToResend.Lock;
       if  (ServerSession.MsgPacketIDsToResend.ItemCount > 0)
       and (ServerSession.MsgPacketIDsToResend.ItemCount > i)
       then
        begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> Removing PacketID = '+IntToStr(PacketID));
{$ENDIF}
         ServerSession.MsgPacketIDsToResend.Remove(PacketID);
        end;
       ServerSession.MsgPacketIDsToResend.Unlock;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> UnlLocked');
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.Session=');
aaWriteToLog(IntToStr(Integer(ServerSession.Session)));
{$ENDIF}
      end; // finally
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.Session=');
aaWriteToLog(IntToStr(Integer(ServerSession.Session)));
{$ENDIF}
     end; // loop
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> Ending...');
{$ENDIF}
  EnterCSect(FCSect);
  ServerSession.MsgControlCode := ControlCode;
  LeaveCSect(FCSect);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.MsgSendStatus = '+IntToStr(ServerSession.MsgSendStatus));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> SessionID = '+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> End!');
{$ENDIF}
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('**************************************************************');
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> WaitForMessageSent> - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
     raise;
    end;
 end;
end; // WaitForMessageSent

begin // DoSendBuffer
 try
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER are sending buffer...');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
 if (ServerSession.Session.ConnectParams.PacketSize < SizeOf(TMsgPacketHeader)) then
   raise EMsgException.Create(40020, ErrorRPacketSizeTooSmall,
                              [ServerSession.Session.ConnectParams.PacketSize,
                                     SizeOf(TMsgPacketHeader)]);

 Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
 try
  DataSize := ServerSession.Session.ConnectParams.PacketSize - SizeOf(TMsgPacketHeader);
  Header.Signature := MsgServerPacketSign;
  Header.Recepient := ServerSession.RemoteClientID;
  EnterCSect(FCSect);
  Header.Sender := FNetwork.FLocalClient;
  LeaveCSect(FCSect);
  Header.ConnectionID := ServerSession.ConnectionID;
  if Code = MsgConnected then
    Header.SessionID := ServerSession.ClientSessionID
  else
    Header.SessionID := ServerSession.Session.SessionID;
  Header.PacketID := 0;
  Header.ControlCode := Code;
  if (Code = MsgMessage)
  or (Code = MsgMessageAbort) then
   begin
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SERVER IS SENDING MESSAGE # '+IntToStr(ServerSession.ClientMessageID)+' TO CLIENT ID='+IntToStr(ServerSession.RemoteClientID));
{$ENDIF}
    Header.CurrentRequestID := ServerSession.ServerMessageID;
   end
  else
    Header.CurrentRequestID := ServerSession.CurrentRequestID;
  Packets := TMsgList.Create;
   try
    BytesSent := 0;
    i := DataSize;
    if (Code = MsgMessage)
    or (Code = MsgMessageAbort) then
     begin
      ServerSession.MsgSendStatus := MsgNotSent;
     end
    else
      ServerSession.SendStatus := MsgNotSent;
    repeat
//    while BytesSent < BufferSize do
//     begin // Create and send all packets
      New(Packet);
      Packets.Add(Packet);
      Packet.Buffer := MemoryManager.GetMem(ServerSession.Session.ConnectParams.PacketSize);
      if BytesSent + DataSize > BufferSize then
       DataSize := BufferSize - BytesSent;
      Packet.BufferSize := DataSize + SizeOf(TMsgPacketHeader);
      if BytesSent + DataSize = BufferSize then
        if Header.ControlCode <> MsgMessageAbort then
          Header.ControlCode := Header.ControlCode+MsgLastPacket;
      Move(Header^, Packet.Buffer^, SizeOf(TMsgPacketHeader));
      Move(Pointer(Integer(Buffer)+Header.PacketID*i)^, Pointer(Integer(Packet.Buffer)+SizeOf(TMsgPacketHeader))^, DataSize);
      inc(Header.PacketID);
      // send packet
      EnterCSect(FCSect);
      try
       FNetwork.RemoteHost := ServerSession.RemoteHost;
       FNetwork.RemotePort := ServerSession.RemotePort;
       if (Code = MsgMessage)
       or (Code = MsgMessageAbort) then
        begin
         if ServerSession.MsgControlCode = MsgTerminate then
           raise EMsgException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
        end
       else
         if ServerSession.ControlCode = MsgTerminate then
           raise EMsgException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),4]);
       FNetwork.SendBuffer(Packet.Buffer, Packet.BufferSize);
      finally
       LeaveCSect(FCSect);
      end;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer> sleep(0)');
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-DoSendBuffer> Sleep(0)...');
{$ENDIF}
      sleep(0); // - The fastest speed is with sleep !!!
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-DoSendBuffer> up!');
{$ENDIF}
      // packet has been sent
      BytesSent := BytesSent + DataSize;
//     end;
    until BytesSent >= BufferSize;
    // Wait for the end of sending...
    if (Code = MsgMessage)
    or (Code = MsgMessageAbort) then
     begin
       if ServerSession.MsgControlCode <> MsgTerminate then
         WaitForMessageSent;
     end
    else
     begin
      if Code <> MsgConnected then
       if ServerSession.ControlCode <> MsgTerminate then
         WaitForCommandSent;
     end;
   finally
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('Remove all sent packets and free memory...');
{$ENDIF}
    // Remove all sent packets and free memory
    for i:= 0 to Packets.Count - 1 do
     begin
      Packet := Packets.Items[i];
      MemoryManager.FreeAndNilMem(Packet.Buffer);
      Dispose(Packet);
     end;
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SERVER-DoSendBuffer> free packets...');
{$ENDIF}
    Packets.Free;
    // Allow to add new packets
    if (Code = MsgMessage)
    or (Code = MsgMessageAbort) then
     begin
      if ServerSession.MsgControlCode = MsgTerminate then
        raise EMsgException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
      inc(ServerSession.ServerMessageID);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer> sleep(0) - 2');
{$ENDIF}
      sleep(0);
      ServerSession.MsgPacketIDsToResend.Lock;
      if ServerSession.MsgControlCode <> MsgTerminate then
        ServerSession.MsgPacketIDsToResend.SetSize(0);
      ServerSession.MsgPacketIDsToResend.Unlock;
     end
    else
     begin
      if ServerSession.ControlCode = MsgTerminate then
        raise EMsgException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),5]);
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SendBuffer> EnableNextCommand');
{$ENDIF}
      EnableNextCommand(ServerSession);
     end;
   end; // try
 finally
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SendBuffer> FreeAndNilMem(Header)');
{$ENDIF}
  MemoryManager.FreeAndNilMem(Header);
 end;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> ServerSession.MsgSendStatus = '+IntToStr(ServerSession.MsgSendStatus));
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> End!');
{$ENDIF}
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SERVER sent buffer');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('**************************************************************');
aaWriteToLog('TMsgServerConnectionManager.DoSendBuffer> - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
     if (Code = MsgMessage) then
      begin
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TMsgClientConnectionManager.DoSendBuffer> Abort Message...');
{$ENDIF}
       dec(ServerSession.ServerMessageID);
       try
        DoSendBuffer(ServerSession,nil,0,MsgMessageAbort);
       except
       end;
      end;
     raise;
    end;
 end;
end; // DoSendBuffer


//------------------------------------------------------------------------------
// EnableNextCommand
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.EnableNextCommand(ServerSession: PMsgSrvrSession);
begin
{$IFDEF LOG_SERVER_ENABLE_NEXT_COMMAND}
aaWriteToLog('EnableNextCommand> START');
{$ENDIF}
      ServerSession.PacketIDsToResend.Lock;
      ServerSession.PacketIDsToResend.SetSize(0);
      ServerSession.PacketIDsToResend.Unlock;
      inc(ServerSession.CurrentRequestID);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('ServerSession.ControlCode = '+IntToStr(ServerSession.ControlCode));
{$ENDIF}
      EnterCSect(FCSect);
      if ServerSession.ControlCode = MsgSuspend then
        ServerSession.ControlCode := MsgExecute;
      LeaveCSect(FCSect);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgServerConnectionManager.EnableNextCommand> sleep(0)');
{$ENDIF}
//      sleep(0);  // DO NOT UNCOMMENT -- THE FASTEST SPEED!!!
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('ServerSession.ControlCode = '+IntToStr(ServerSession.ControlCode));
{$ENDIF}
{$IFDEF LOG_SERVER_ENABLE_NEXT_COMMAND}
aaWriteToLog('EnableNextCommand> FINISH');
{$ENDIF}
end;// EnableNextCommand


//------------------------------------------------------------------------------
// SendBuffer
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.SendBuffer(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = MsgNoAction
                                                  );
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  SessionFound:         Boolean;
  i:                    Integer;
  Buf:                  PAnsiChar;
  BufSize:              Integer;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.SendBuffer> - START');
{$ENDIF}
  SessionFound := False;
  Sessions := FSessions.LockList;
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session = Session then
       begin
        SessionFound := True;
        break;
       end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if not SessionFound then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('SERVER>>> '+IntToStr(ServerSession.CurrentRequestID)+' :');
aaWriteBufferToLog(Buffer,BufferSize);
{$ENDIF}

  inc(ServerSession.Status);
  try
   CompressAndEncryptBuffer(ServerSession.Session, Buffer, BufferSize, Buf, BufSize);
   try
    DoSendBuffer(ServerSession, Buf, BufSize, Code);
   finally
    if Buf <> Buffer then
      MemoryManager.FreeAndNilMem(Buf);
   end;
   dec(ServerSession.Status);
  except
   dec(ServerSession.Status);
   raise;
  end;

  (*
  if Code <> MsgMessage then
   begin
    ServerSession.ReceiveStatus := MsgNo;
    Packets := ServerSession.Packets.LockList;
    try
     for i:=0 to Packets.Count-1 do
       Packets.Items[i] := nil;
     Packets.Count := 0;
    finally
     ServerSession.Packets.UnlockList;
    end;
   end
  else
   begin
    ServerSession.MsgReceiveStatus := MsgNo;
    Packets := ServerSession.MsgPackets.LockList;
    try
     for i:=0 to Packets.Count-1 do
       Packets.Items[i] := nil;
     Packets.Count := 0;
    finally
     ServerSession.MsgPackets.UnlockList;
    end;
   end;

  DoSendBuffer(ServerSession, Buffer, BufferSize, Code);

  if Code <> MsgMessage then
   begin
//     if ServerSession.ReceiveStatus = MsgNo then
//       inc(ServerSession.CurrentRequestID);
   end
  else
   begin
     inc(ServerSession.ServerMessageID);
   end;
*)
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TMsgServerConnectionManager.SendBuffer> - FINISH');
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// SendMessage
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.SendMessage(
                          Session:    TMsgComBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TMsgControlCode = MsgMessage
                                                  );
var
  SessionFound:   Boolean;
  Sessions:       TMsgList;
  i:              Integer;
  ServerSession:  PMsgSrvrSession;
  StartTime:      Cardinal;
begin
  SessionFound := False;
  Sessions := FSessions.LockList;
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session = Session then
       begin
        SessionFound := True;
        break;
       end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if not SessionFound then
    raise EMsgException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
  // wait for Session be vacant
  StartTime := GetTickCount;
  repeat
   if Session = nil then
     raise EMsgException.Create(40071, ErrorRSessionDeleted);
   if ServerSession.MsgControlCode = MsgTerminate then
     raise EMsgException.Create(40072, ErrorRSendSessionTerminated);
   if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.WaitForMessagesSend then
     raise EMsgException.Create(40073, ErrorRTimeoutMessageSent,[
{$IFDEF MsgCommunicator}
          ServerSession.Session.UserID,
{$ELSE}
          ServerSession.Session.SessionID,
{$ENDIF}
          ServerSession.Session.ConnectParams.WaitForMessagesSend]);
   if (ServerSession.Status = MsgVacant) then
      break;
{$IFDEF ProcessMessages}
   Application.ProcessMessages;
{$ENDIF ProcessMessages}
   Sleep(ServerSession.Session.ConnectParams.ServerResendDelay);
  until False;
  // block other threads to send at the same time
{$IFDEF MsgCommunicator}
  EnterCSect(TMsgServerSession(Session).FCSect);
{$ENDIF}
  try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.SendMessage> - Start');
{$ENDIF}
(*
   if (TMsgCompressionAlgorithm1(Session.ConnectParams.CompressionAlgorithm) <> acaNone)
   or (Session.ConnectParams.CryptoInfo.CryptoAlgorithm <> Msg_Cipher_None)
   then
    begin
     Buf := MemoryManager.GetMem(BufferSize);
     Move(Buffer^,Buf^,BufferSize);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.SendMessage> - SendBuffer SessionID='+IntToStr(Session.SessionID));
{$ENDIF}
     SendBuffer(Session, Buf, BufferSize, MsgMessage);
     MemoryManager.FreeAndNilMem(Buf);
    end
   else
*)
    begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.SendMessage> - SendBuffer SessionID='+IntToStr(Session.SessionID));
{$ENDIF}
     SendBuffer(Session, Buffer, BufferSize, Code);
    end;
  finally
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerConnectionManager.SendMessage> - SessionID='+IntToStr(Session.SessionID));
aaWriteToLog('TMsgServerConnectionManager.SendMessage> - FINISH');
{$ENDIF}
{$IFDEF MsgCommunicator}
   LeaveCSect(TMsgServerSession(Session).FCSect);
{$ENDIF}
  end;
end; // SendMessage


//------------------------------------------------------------------------------
// SendPing
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.SendPing(
                          ServerSession:        PMsgSrvrSession
                                                          );
var
  Header:          PMsgPacketHeader;
begin
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
   Header.ControlCode := MsgPing;
   Header.Signature := MsgServerPacketSign;
   Header.Recepient := ServerSession.RemoteClientID;
   Header.ConnectionID := ServerSession.ConnectionID;
   Header.SessionID := ServerSession.Session.SessionID;
   Header.PacketID := 0;
   Header.CurrentRequestID := 0;
   EnterCSect(FCSect);
   try
    FNetwork.RemoteHost := ServerSession.RemoteHost;
    FNetwork.RemotePort := ServerSession.RemotePort;
    FNetwork.SendBuffer(PAnsiChar(Header), SizeOf(TMsgPacketHeader));
   finally
    LeaveCSect(FCSect);
   end;
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
end;// SendPing


//------------------------------------------------------------------------------
// SendAcknowledgement
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.SendAcknowledgement(
                          ServerSession:        PMsgSrvrSession;
                          Msg:                  Boolean = False;
                          CurrentRequestID:     Integer = -1
                                                          );
var
  Header:          PMsgPacketHeader;
begin
  Header := MemoryManager.GetMem(SizeOf(TMsgPacketHeader));
  try
   if Msg then
     Header.ControlCode := MsgMessageReceived
   else
     Header.ControlCode := MsgAllPacketsReceived;
   Header.Signature := MsgServerPacketSign;
   Header.Recepient := ServerSession.RemoteClientID;
   Header.ConnectionID := ServerSession.ConnectionID;
   Header.SessionID := ServerSession.Session.SessionID;
   Header.PacketID := 0;
   if CurrentRequestID>=0 then
     Header.CurrentRequestID := CurrentRequestID
   else
    begin
     if Msg then
       Header.CurrentRequestID := ServerSession.ClientMessageID
     else
       Header.CurrentRequestID := ServerSession.CurrentRequestID;
    end;
   EnterCSect(FCSect);
   try
    FNetwork.RemoteHost := ServerSession.RemoteHost;
    FNetwork.RemotePort := ServerSession.RemotePort;
    FNetwork.SendBuffer(PAnsiChar(Header), SizeOf(TMsgPacketHeader));
   finally
    LeaveCSect(FCSect);
   end;
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
end;// SendAcknowledgement


//------------------------------------------------------------------------------
// GetClientInfo
//------------------------------------------------------------------------------
function TMsgServerConnectionManager.GetClientInfo(
                          Session:          TMsgComBaseSession;
                          var Host:         AnsiString;
                          var Port:         Integer;
                          var Application:  AnsiString
                                                    ): Boolean;
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
begin
  Host := '';
  Port := -1;
  Application := '';
  Result := False;
  if Session = nil
    then Exit;
  Sessions:=FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session = Session then
      begin
       Host := ServerSession.RemoteHost;
       Port := ServerSession.RemotePort;
       Application := ServerSession.Application;
       Result := True;
       break;
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
{
  if not Found then
    raise EMsgException.Create(40037, ErrorRSessionNotFound,
                                ['Server', Session.SessionID]);
}
end; // GetClientInfo


//------------------------------------------------------------------------------
// GetClientsList
//------------------------------------------------------------------------------
procedure TMsgServerConnectionManager.GetClientsList(var Clients: TMsgSessionsArray);
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
begin
  Sessions:=FSessions.LockList;
  try
   SetLength(Clients, Sessions.Count);
   for i:=0 to Sessions.Count-1 do
    begin
     ServerSession := Sessions.Items[i];
     Clients[i] := ServerSession.Session;
    end;
  finally
   FSessions.UnlockList;
  end;
end; // GetClientsList


//------------------------------------------------------------------------------
// if authorization buffer is valid (encrypted by the same crypto settings as in CryptoInfo)
// then return true else return false
//------------------------------------------------------------------------------
function TMsgServerConnectionManager.IsAuthorizationBufferValid(
                      CryptoInfo: TMsgCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
begin
// --> added by Leo Martin, 4.03 pr#1, 19 July 2005
  if (CryptoInfo.CryptoAlgorithm <> Byte(TMsgServer(FServer).CryptoParams.CryptoAlgorithm)) then
   Result := False
  else
// <-- added by Leo Martin, 4.03 pr#1, 19 July 2005
   Result := fnIsAuthorizationBufferValid(CryptoInfo, Buffer, BufferSize);
end; // IsAuthorizationBufferValid

// TMsgServerConnectionManager




////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerSessionThread.Create(
                          Manager:          TMsgServerConnectionManager;
                          ServerSession:    PMsgSrvrSession;
                          Code:             Integer = MsgNoAction
                                            );
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FServerSession := ServerSession;
  FCode := Code;
{$IFDEF ClientCommand_Fix}
  FFinishing := False;
{$ENDIF}
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerSessionThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgServerSessionThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FServerSession.Session <> nil then
    FServerSession.Thread := nil;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD - FINISHED');
{$ENDIF}
  if (FManager<>nil) then
    FManager.DecThreadCount;
  inherited Destroy;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionThread,-1,
                  Error)
    else
      TMsgNetworkSession(FServerSession.Session).DoOnError(
                  MsgServerSessionThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerSessionThread.Execute;
var
  Buf:                 PAnsiChar;
  BufSize, AuBufSize:  Integer;
  ConnectionParams:    PMsgConnectionParams;
begin
try // finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionThread.Execute - START - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('ServerSessionThread> START');
{$ENDIF}
 if (Terminated or (FServerSession = nil)) then
   Exit;
 if FServerSession.ControlCode = MsgTerminate then
   Exit;
 try // except
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionThread.Execute - New Command - GetTickCount='+IntToStr(GetTickCount));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': CurrentRequestID='+IntToStr(FServerSession.CurrentRequestID));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Code='+IntToStr(FCode));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ReceiveStatus = '+IntToStr(FServerSession.ReceiveStatus));
{$ENDIF}
  if (FCode <> MsgDisconnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSession.ControlCode='+IntToStr(FServerSession.ControlCode));
{$ENDIF}
    try
     if FCode<>MsgConnect then
      begin
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TMsgServerSessionThread.Execute');
{$ENDIF}
//aaWriteToLog('TMsgServerSessionThread.Execute 1:'+#13#10+IntToStr(GetTickCount));
       FManager.SendAcknowledgement(FServerSession);
//aaWriteToLog('TMsgServerSessionThread.Execute 2:'+#13#10+IntToStr(GetTickCount));
      end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Acknowledgement sent! - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40519, ErrorRAckn+E.Message);
    end;
    try
//aaWriteToLog('TMsgServerSessionThread.Execute 3:'+#13#10+IntToStr(GetTickCount));
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('ServerSessionThread> ReceiveBuffer...');
{$ENDIF}
     try
      FManager.ReceiveBuffer(FServerSession, Buf, BufSize);
     finally
      FServerSession.ReceiveStatus := MsgNo;
     end;
//aaWriteToLog('TMsgServerSessionThread.Execute 4:'+#13#10+IntToStr(GetTickCount));
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Buffer received!      - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
    except
     on E:Exception do
      begin
{$IFDEF LOG_SERVER_COMMAND_RETRY}
aaWriteToLog('SERVER_SESSION_THREAD> Receive buffer exception');
{$ENDIF}
       FManager.EnableNextCommand(FServerSession);
       raise EMsgException.Create(40506, ErrorRCannotReceive+E.Message);
      end
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Buffer received');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSession.ControlCode='+IntToStr(FServerSession.ControlCode));
{$ENDIF}
   end;
//  FServerSession.ReceiveStatus := MsgNo; // Removed as in ACR v.5.90
  if (FCode = MsgConnect) then
   begin
    try
(*
    if not FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('Decompress/Decrypt - Error!');
{$ENDIF}
      Exit;
     end;
*)
//aaWriteToLog('TMsgServerSessionThread.Execute 5:'+#13#10+IntToStr(GetTickCount));

{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': IsAuthorizationBufferValid');
{$ENDIF}
{$IFDEF MsgCommunicator}
    Move(Buf^, FServerSession.Session.FUserID, SizeOf(FServerSession.Session.FUserID));
    inc(Buf, SizeOf(FServerSession.Session.FUserID));
{$ENDIF}
    Move(PAnsiChar(Buf + SizeOf(TMsgConnectionParams))^, AuBufSize, SizeOf(AuBufSize));
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER> AuthorizationBuffer:');
aaWriteBufferToLog(PAnsiChar(Buf + SizeOf(TMsgConnectionParams) + SizeOf(AuBufSize)),AuBufSize);
{$ENDIF}
//aaWriteToLog('TMsgServerSessionThread.Execute 5:'+#13#10+IntToStr(GetTickCount));
    if not FManager.IsAuthorizationBufferValid(
              FServerSession.Session.ConnectParams.CryptoInfo,
              PAnsiChar(Buf + SizeOf(TMsgConnectionParams) + SizeOf(AuBufSize)),
              AuBufSize
                                               )
    then
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('IsAuthorizationBufferValid - Invalid!!!');
{$ENDIF}
      try
       if FManager <> nil then
         if FServerSession <> nil then
           if FServerSession.Session <> nil then
             FManager.DoDisconnect(FServerSession.Session, True);
      except
       on E:Exception do
         raise EMsgException.Create(40509, 'MsgConnect section - '+ErrorRDoDisconnect+E.Message);
      end;
{$IFDEF MsgCommunicator}
      dec(Buf, SizeOf(FServerSession.Session.FUserID));
{$ENDIF}
      Exit;
     end;
//aaWriteToLog('TMsgServerSessionThread.Execute 6:'+#13#10+IntToStr(GetTickCount));
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('IsAuthorizationBufferValid - OK!');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ConnectionParams');
{$ENDIF}
    try
    // Get ConnectParams
//aaWriteToLog('TMsgServerSessionThread.Execute 7:'+#13#10+IntToStr(GetTickCount));
    ConnectionParams := PMsgConnectionParams(Buf);
    FServerSession.Session.FConnectParams.PacketSize := ConnectionParams.PacketSize;
    FServerSession.Session.FConnectParams.CompressionAlgorithm := ConnectionParams.CompressionAlgorithm;
    FServerSession.Session.FConnectParams.CompressionMode := ConnectionParams.CompressionMode;
    FServerSession.Session.FConnectParams.UseServerSettings := ConnectionParams.UseServerSettings;
    // Get client Application name
    SetLength(FServerSession.Application, BufSize-SizeOf(TMsgConnectionParams)-SizeOf(AuBufSize)-AuBufSize-1
{$IFDEF MsgCommunicator}
    -SizeOf(FServerSession.Session.FUserID)
{$ENDIF}
    );
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteBufferToLog(Buf+SizeOf(TMsgConnectionParams)+SizeOf(AuBufSize)+AuBufSize,BufSize-SizeOf(TMsgConnectionParams)-SizeOf(AuBufSize)-AuBufSize-1);
{$ENDIF}
    StrCopy(PAnsiChar(FServerSession.Application), Buf+SizeOf(TMsgConnectionParams)+SizeOf(AuBufSize)+AuBufSize);
//aaWriteToLog('TMsgServerSessionThread.Execute 8:'+#13#10+IntToStr(GetTickCount));
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('Application="'+FServerSession.Application+'"');
{$ENDIF}
    // Free
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Free Buf');
{$ENDIF}
{$IFDEF MsgCommunicator}
    dec(Buf, SizeOf(FServerSession.Session.FUserID));
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40510, ErrorRGetConnectParams+E.Message);
    end;
    finally
     MemoryManager.FreeAndNilMem(Buf);
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER_SESSION_THREAD> SendConnectAckn...');
{$ENDIF}
    try
//aaWriteToLog('TMsgServerSessionThread.Execute 9:'+#13#10+IntToStr(GetTickCount));
     FManager.SendConnectAckn(FServerSession);
//aaWriteToLog('TMsgServerSessionThread.Execute 10:'+#13#10+IntToStr(GetTickCount));
     FServerSession.Connected := True;
     FFinishing := True;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER_SESSION_THREAD> Finishing...');
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40511, 'MsgConnect section - '+ErrorRSendConnectAckn+E.Message);
    end;
{$IFDEF MsgCommunicator}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('ServerSessionThread> ConnectUser...');
{$ENDIF}
//aaWriteToLog('TMsgServerSessionThread.Execute 11:'+#13#10+IntToStr(GetTickCount));
    if not (TMsgServerSession(FServerSession.Session).ConnectUser) then
      FManager.Disconnect(FServerSession.Session);
//aaWriteToLog('TMsgServerSessionThread.Execute 12:'+#13#10+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER CONNECTED CLIENT #'+IntToStr(FServerSession.RemoteClientID));
aaWriteToLog('PacketSize='+IntToStr(FServerSession.Session.ConnectParams.PacketSize));
aaWriteToLog('CompressionAlgorithm='+IntToStr(FServerSession.Session.ConnectParams.CompressionAlgorithm));
aaWriteToLog('CompressionMode='+IntToStr(FServerSession.Session.ConnectParams.CompressionMode));
aaWriteToLog('CryptoAlgorithm='+IntToStr(FServerSession.Session.ConnectParams.CryptoInfo.CryptoAlgorithm));
aaWriteToLog('Application="'+FServerSession.Application+'"');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
   end
  else
(*
  if (FCode = MsgDisconnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Disconnect...');
{$ENDIF}
    if FServerSession.Session <> nil then
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': DoDisconnect');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': SessionID='+IntToStr(Integer(FServerSession.Session.SessionID)));
{$ENDIF}
      try
      FManager.DoDisconnect(FServerSession.Session);
      except
       on E:Exception do
        raise EMsgException.Create(40509, 'MsgDisconnect section - '+ErrorRDoDisconnect+E.Message);
      end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Disconnected');
{$ENDIF}
     end;
   end
  else
*)
  if (FCode = MsgServerSessionTunning) then
   begin
    try
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgServerSessionTunning...');
{$ENDIF}
    if FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
      Move(Buf^,FServerSession.AnswerTime,BufSize);
    finally
     MemoryManager.FreeAndNilMem(Buf);
    end;
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': AnswerTime='+IntToStr(FServerSession.AnswerTime));
{$ENDIF}
{$IFDEF LOG_SERVER_ENABLE_NEXT_COMMAND}
aaWriteToLog('ServerSessionThread> EnableNextCommand');
{$ENDIF}
    FManager.EnableNextCommand(FServerSession);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Tuned!');
{$ENDIF}
   end
  else
  if (FCode = MsgEcho)
  or (FCode = MsgTunning)
  then
   begin
    try
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Echo...');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': CurrentRequestID = '+IntToStr(FServerSession.CurrentRequestID));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': BufSize = '+IntToStr(BufSize));
{$ENDIF}
    if (FCode <> MsgTunning) then
      if not FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
        Exit;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Decompressed BufSize = '+IntToStr(BufSize));
{$ENDIF}
    try
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('send answer...');
{$ENDIF}
    FManager.SendBuffer(FServerSession.Session, Buf, BufSize, MsgNoAction);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('sent!');
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40505, 'Echo section, Code='+IntToStr(FCode)+' - '+ErrorRCannotSendEcho+E.Message);
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Compressed BufSize = '+IntToStr(BufSize));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': CurrentRequestID = '+IntToStr(FServerSession.CurrentRequestID));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Echo sent');
{$ENDIF}
    finally
     MemoryManager.FreeAndNilMem(Buf);
    end;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER SENT ECHO TO CLIENT #'+IntToStr(FServerSession.RemoteClientID));
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
   end
  else
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionThread.Execute - TerminateCommandThreads... - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
//    FManager.TerminateCommandThreads(FServerSession); Does not work in IDE
//    FServerSession.ControlCode := MsgSuspend;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionThread.Execute - TerminateCommandThreads OK - GetTickCount='+IntToStr(GetTickCount));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': BufSize = '+IntToStr(BufSize));
{$ENDIF}
//aaWriteToLog('TMsgServerSessionThread.Execute 13:'+#13#10+IntToStr(GetTickCount));
    if FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
     begin
//aaWriteToLog('TMsgServerSessionThread.Execute 14:'+#13#10+IntToStr(GetTickCount));
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('Server started new request #'+IntToStr(FServerSession.CurrentRequestID));
aaWriteBufferToLog(Buf, BufSize);
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionThread.Execute - Session.ReceiveData - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
      if Terminated then
        Exit;
      try
{$IFDEF MsgCommunicator}
//aaWriteToLog('TMsgServerSessionThread.Execute 15:'+#13#10+IntToStr(GetTickCount));
 {$IFDEF LOG_SERVER_THREAD_SWITCHING}
 aaWriteToLog('ServerSessionThread> ReceiveData...');
 {$ENDIF}
      FServerSession.Session.ReceiveData(Buf, BufSize);
//aaWriteToLog('TMsgServerSessionThread.Execute 16:'+#13#10+IntToStr(GetTickCount));
{$ELSE}
      if FCode = MsgClientCommand then
       begin
        FManager.EnableNextCommand(FServerSession);
 {$IFDEF ClientCommand_Fix}
        FFinishing := True;
 {$ENDIF}
       end;
 {$IFDEF LOG_SERVER_THREAD_SWITCHING}
 aaWriteToLog('ServerSessionThread> ReceiveData...');
 {$ENDIF}
      FServerSession.Session.ReceiveData(Buf, BufSize);
{$ENDIF}
{$IFDEF ClientCommand_Fix}
      FFinishing := True;
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TMsgServerSessionThread.Execute> data received');
{$ENDIF}
      except
       on E:Exception do
        begin
{$IFDEF LOG_SERVER_COMMAND_RETRY}
aaWriteToLog('SERVER_SESSION_THREAD> Receive buffer exception');
{$ENDIF}
         raise EMsgException.Create(40513,'Command section - '+ErrorRSessionReceiveData+E.Message);
        end;
      end;
     end;
//aaWriteToLog('TMsgServerSessionThread.Execute 14:'+#13#10+IntToStr(GetTickCount));
//    FManager.TerminateCommandThreads(FServerSession); // - Could be better instead of befor ReceiveData
  end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER: FINISHED EXECUTE SESSION *****************************');
{$ENDIF}
 except
  on E: EMsgException do
   begin
    try
    FServerSession.ReceiveStatus := MsgNo;
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(MsgServerSessionThread,E.NativeError,Error)
    else
      TMsgNetworkSession(FServerSession.Session).DoOnError(MsgServerSessionThread,E.NativeError,Error);
    except
    end;
   end;
  on E: Exception do
   begin
    try
    FServerSession.ReceiveStatus := MsgNo;
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    try
     TMsgNetworkSession(FServerSession.Session).DoOnError(MsgServerSessionThread,-1,Error);
    except
     TMsgServer(FManager.FServer).DoOnConnectionError(MsgServerSessionThread,-1,Error);
    end;
    except
    end;
   end;
 end;
finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionThread.Execute - FINISH');
{$ENDIF}
//aaWriteToLog('TMsgServerSessionThread.Execute ok:'+#13#10+IntToStr(GetTickCount));
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TMsgServerSessionThread> FINISH');
{$ENDIF}
end;
end; // Execute

// TMsgServerSessionThread




////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionMsgThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerSessionMsgThread.Create(
                          Manager:          TMsgServerConnectionManager;
                          ServerSession:    PMsgSrvrSession;
                          Code:             Integer = MsgMessage
                                            );
begin
 try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session # '+IntToStr(ServerSession.Session.SessionID)+'SessionMsgThread creating...');
{$ENDIF}
  FManager := Manager;
  FManager.IncThreadCount;
  FServerSession := ServerSession;
  FCode := Code;
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionMsgThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionMsgThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerSessionMsgThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgServerSessionMsgThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session # '+IntToStr(FServerSession.Session.SessionID)+'SessionMsgThread finishing...');
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FServerSession.Session <> nil then
    FServerSession.MsgThread := nil;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD - FINISHED');
{$ENDIF}
  if (FManager<>nil) then
    FManager.DecThreadCount;
  inherited Destroy;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionMsgThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionMsgThread,-1,
                  Error)
    else
      TMsgNetworkSession(FServerSession.Session).DoOnError(
                  MsgServerSessionMsgThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerSessionMsgThread.Execute;
var
  Buf:                 PAnsiChar;
  BufSize:             Integer;
  Queue:               TMsgList;
begin
try // finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionMsgThread.Execute - START - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
 try // except
  repeat
   Queue := FServerSession.MsgQueue.LockList;
   try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSessionMsgThread.Execute> SessionID = '+IntToStr(FServerSession.Session.SessionID)+', TOP Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    if Queue.Count = 0 then
      Exit;
    FServerSession.MsgReceivedPackets := Queue.Items[0];
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Get  list '+IntToStr(Integer(Pointer(FServerSession.MsgReceivedPackets))));
{$ENDIF}
   finally
    FServerSession.MsgQueue.UnlockList;
   end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionMsgThread.Execute - New Message - GetTickCount='+IntToStr(GetTickCount));
//aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ClientMessageID='+IntToStr(FServerSession.ClientMessageID));
//aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Code='+IntToStr(FCode));
//aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgReceiveStatus = '+IntToStr(FServerSession.MsgReceiveStatus));
{$ENDIF}
//  if (FCode = MsgMessage) then
   begin
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('MsgServerSessionMsgThread.Execute> Call FManager.ReceiveMessage');
{$ENDIF}
    EnterCSect(FManager.FCSect);
    if FServerSession.MsgControlCode = MsgExecute then
      FServerSession.MsgControlCode := MsgSuspend;
    LeaveCSect(FManager.FCSect);
    try
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Receive buffer...');
{$ENDIF}
    FManager.ReceiveMessage(FServerSession, Buf, BufSize);
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Free list '+IntToStr(Integer(Pointer(FServerSession.MsgReceivedPackets))));
{$ENDIF}
   Queue := FServerSession.MsgQueue.LockList;
   try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSessionMsgThread.Execute> SessionID = '+IntToStr(FServerSession.Session.SessionID)+', Old Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    FServerSession.MsgReceivedPackets.Free;
    FServerSession.MsgReceivedPackets := nil;
    Queue.Delete(0);
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSessionMsgThread.Execute> SessionID = '+IntToStr(FServerSession.Session.SessionID)+', New Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
   finally
    FServerSession.MsgQueue.UnlockList;
   end;
    except
     on E:Exception do
      raise EMsgException.Create(40507,'MsgMessage section - '+ErrorRCannotReceiveMsg+E.Message);
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Decompress and decrypt buffer...');
{$ENDIF}
    if FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
     begin
//      FManager.TerminateMessageThreads(FServerSession);
      FServerSession.MsgControlCode := MsgExecute;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER: Call ServerSession.ReceiveMessage');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
      try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Run server session to process message...');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerSessionMsgThread.Execute> Server session processes new message...');
aaWriteToLog('FManager.ThreadCount = '+IntToStr(FManager.ThreadCount));
aaWriteToLog('FServerSession.MsgThreadCount = '+IntToStr(FServerSession.MsgThreadCount));
{$ENDIF}
        while // too many total threads, reserve to process newcomers
          (FManager.ThreadCount >= (FManager.FMaxThreadCount-(FManager.FSessions.Count*4)))
           or // too many message threads for this client
          (FServerSession.MsgThreadCount >= FManager.FMaxMsgThreadCount)
         do sleep(1); // wait for thread count be lower
        TMsgSendingThread.Create(nil,
                                 FManager,@TMsgServerSession.ReceiveMessage,
                                 Integer(FServerSession.Session),
                                 Integer(Buf), BufSize,
                                 Integer(Pointer(FServerSession)), 0); // process message in new thread
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSessionMsgThread.Execute> Server session finished!');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Server message session finished!');
{$ENDIF}
      except
       on E:Exception do
        raise EMsgException.Create(40512,'MsgMessage section - '+ErrorRSessionReceiveMessage+E.Message);
      end;
     end;
   end;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TMsgServerSessionMsgThread.Execute> sleep(0)');
{$ENDIF}
   sleep(0);
  until False;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('SERVER: FINISHED EXECUTE SESSION *****************************');
aaWriteToLog('==============================================================');
{$ENDIF}
 except
  on E: EMsgException do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRServerSessionMsgThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(MsgServerSessionMsgThread,E.NativeError,Error)
    else
      TMsgNetworkSession(FServerSession.Session).DoOnError(MsgServerSessionMsgThread,E.NativeError,Error);
    except
    end;
   end;
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRServerSessionMsgThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    try
     TMsgNetworkSession(FServerSession.Session).DoOnError(MsgServerSessionMsgThread,-1,Error);
    except
     TMsgServer(FManager.FServer).DoOnConnectionError(MsgServerSessionMsgThread,-1,Error);
    end;
    except
    end;
   end;
 end;
finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionMsgThread.Execute - FINISH');
{$ENDIF}
end;
end; // Execute

// TMsgServerSessionMsgThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionDisconnectThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerSessionDisconnectThread.Create(
                          Manager:          TMsgServerConnectionManager;
                          ServerSession:    PMsgSrvrSession;
                          CurrentRequestID: Integer = -1
                                            );
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FServerSession := ServerSession;
  FCurrentRequestID := CurrentRequestID;
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionDisconnectThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionDisconnectThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerSessionDisconnectThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgServerSessionDisconnectThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if (FManager<>nil) then
    FManager.DecThreadCount;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER SESSION THREAD - FINISHED');
{$ENDIF}
  inherited Destroy;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionDisconnectThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionDisconnectThread,-1,
                  Error)
    else
      TMsgNetworkSession(FServerSession.Session).DoOnError(
                  MsgServerSessionDisconnectThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerSessionDisconnectThread.Execute;
begin
try // finally
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionDisconnectThread.Execute - START - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
 try // except
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Disconnect...');
{$ENDIF}
    try
     if FServerSession.ControlCode = MsgTerminate then
       Exit
     else
       inc(FServerSession.Status);
     try
      FManager.SendAcknowledgement(FServerSession, False, FCurrentRequestID);
     finally
      dec(FServerSession.Status);
     end;
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TMsgServerSessionDisconnectThread.Execute');
{$ENDIF}
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Acknowledgement sent!');
{$ENDIF}
    except
     on E:Exception do
      raise EMsgException.Create(40519, ErrorRAckn+E.Message);
    end;
    if FServerSession.Session <> nil then
     begin
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': DoDisconnect');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': SessionID='+IntToStr(Integer(FServerSession.Session.SessionID)));
{$ENDIF}
      try
       FManager.DoDisconnect(FServerSession.Session);
      except
       on E:Exception do
        raise EMsgException.Create(40509, ErrorRDoDisconnect+E.Message);
      end;
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Disconnected');
{$ENDIF}
     end;
 except
  on E: EMsgException do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRServerSessionDisconnectThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(MsgServerSessionDisconnectThread,E.NativeError,Error)
    else
      TMsgNetworkSession(FServerSession.Session).DoOnError(MsgServerSessionDisconnectThread,E.NativeError,Error);
    except
    end;
   end;
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRServerSessionDisconnectThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    try
     TMsgNetworkSession(FServerSession.Session).DoOnError(MsgServerSessionDisconnectThread,-1,Error);
    except
     TMsgServer(FManager.FServer).DoOnConnectionError(MsgServerSessionDisconnectThread,-1,Error);
    end;
    except
    end;
   end;
 end;
finally
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TMsgServerSessionDisconnectThread.Execute - FINISH');
{$ENDIF}
end;
end; // Execute

// TMsgServerSessionDisconnectThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSessionTerminatorThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerSessionTerminatorThread.Create(
                          Manager:          TMsgServerConnectionManager
                                            );
begin
 try
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - START - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FTerminatedSessions := nil;
  FManager := Manager;
  FManager.IncThreadCount;
  FTerminatedSessions := TMsgThreadList.Create;
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - STARTED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionTerminatorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionTerminatorThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgServerSessionTerminatorThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - FINISH - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  if FManager.SessionTerminator <> nil then
    FManager.SessionTerminator := nil;
  FTerminatedSessions.Free;
  FTerminatedSessions := nil;
  inherited Destroy;
  FManager.DecThreadCount;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionTerminatorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionTerminatorThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerSessionTerminatorThread.Execute;
var
  Sessions:             TMsgList;
  Session:              TMsgComBaseSession;
  i, Delay, Retry:      Integer;
  StartTime:            Cardinal;
  Sent:                 Boolean;
begin
try
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
try
{$ENDIF}
 repeat
  if Terminated then
    Exit;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - Lock Sessions... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  Sessions := FTerminatedSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - i='+IntToStr(i)+'- THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
     if Terminated then
       Exit;
     Session := Sessions.Items[i];
     Sessions.Delete(i);
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - DoDisconect... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
     try
      FManager.Disconnect(Session, @Terminated);
     except
      on E:Exception do
       raise EMsgException.Create(40520, ErrorRDisconnect+E.Message);
     end;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - Delete... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - Session Deleted! - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
    end;
  finally
   FTerminatedSessions.UnlockList;
  end;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - Sleep... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  if FManager.FServer = nil then
    sleep(MsgServerSessionTerminatorSleep)
  else
    sleep(TMsgServer(FManager.FServer).NetworkSettings.ServerSessionTerminatorSleep);
 until False;
{$IFDEF LOG_SERVER_TERMINATOR}
finally
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
end;
{$ENDIF}
 except
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRServerSessionTerminatorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerSessionTerminatorThread,-1,
                  Error)
    else
      TMsgNetworkSession(Session).DoOnError(
                  MsgServerSessionTerminatorThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerPingClientsThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerPingClientsThread.Create(
                          Manager:          TMsgServerConnectionManager
                                            );
begin
 try
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - START - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FManager := Manager;
  FManager.IncThreadCount;
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - STARTED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerPingClientsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerPingClientsThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgServerPingClientsThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - FINISH - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  if FManager.PingClientsThread <> nil then
    FManager.PingClientsThread := nil;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD> manager = '+IntToStr(Integer(FManager)));
{$ENDIF}
  FManager.DecThreadCount;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD> success!');
{$ENDIF}
  inherited Destroy;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerPingClientsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerPingClientsThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------

procedure TMsgServerPingClientsThread.Execute;
var
  Sessions:             TMsgList;
  ServerSession:        PMsgSrvrSession;
  i:                    Integer;
  Delay:                Integer;
  MinWaitForPingAnswer: Integer;
begin
 try
{$IFDEF DEBUG_LOG_PING}
try
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
 repeat
  if Terminated then
    Exit;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE - Lock Sessions... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  for i:=0 to FManager.SessionsCount do
   begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> i='+IntToStr(i));
{$ENDIF}
    if Terminated then
      Exit;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> EnterCSect...');
{$ENDIF}
    EnterCSect(FManager.FCSect);
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> Sessions.LockList...');
{$ENDIF}
    Sessions := FManager.FSessions.LockList;
    try
     if i>= Sessions.Count then
      begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> (i='+IntToStr(i)+') >= (Sessions.Count='+IntToStr(Sessions.Count)+')');
{$ENDIF}
       continue;
      end;
     ServerSession := Sessions.Items[i];
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> ServerSession = '+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
     if ServerSession.ControlCode = MsgTerminate then
       continue;
     inc(ServerSession.Status);
     Delay := ServerSession.Session.ConnectParams.ServerPingSleep;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> ServerSession.Session.ConnectParams.WaitForPingAnswer = '+IntToStr(ServerSession.Session.ConnectParams.WaitForPingAnswer));
{$ENDIF}
     if FManager.FIncomingPackets.Count = 0 then
       ServerSession.Session.FConnectParams.WaitForPingAnswer := TMsgServer(FManager.FServer).NetworkSettings.WaitForPingAnswer
     else
      begin
       MinWaitForPingAnswer := (
        (Sessions.Count + 1) * (ServerSession.Session.ConnectParams.ServerPingSleep +
         ServerSession.Session.ConnectParams.ServerResendDelay + MsgResendDelay) * 2);
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> MinWaitForPingAnswer = '+IntToStr(MinWaitForPingAnswer));
{$ENDIF}
       if (MinWaitForPingAnswer > ServerSession.Session.ConnectParams.WaitForPingAnswer) then
         ServerSession.Session.FConnectParams.WaitForPingAnswer := MinWaitForPingAnswer;
      end;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> ServerSession.Session.ConnectParams.WaitForPingAnswer = '+IntToStr(ServerSession.Session.ConnectParams.WaitForPingAnswer));
{$ENDIF}
    finally
     FManager.FSessions.UnlockList;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> Sessions List Unlocked!');
{$ENDIF}
     LeaveCSect(FManager.FCSect);
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> CriticalSection Leaved!');
{$ENDIF}
    end;
    try
(*
     if not ServerSession.Session.Connected then
      begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> Session not Connected, i='+IntToStr(i));
{$ENDIF}
       continue;
      end;
*)
     if ServerSession.Connected then
      begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('LastReceivePingTime =' + IntToStr(ServerSession.LastReceivePingTime));
aaWriteToLog('LastSendPingTime    =' + IntToStr(ServerSession.LastSendPingTime));
{$ENDIF}
       if (ServerSession.LastSendPingTime >= ServerSession.LastReceivePingTime) and
          ( (GetTickCount - ServerSession.LastSendPingTime) >
            (ServerSession.Session.ConnectParams.WaitForPingAnswer / (ServerSession.Session.ConnectParams.PingCount + 1)))
       or (ServerSession.LastSendPingTime < ServerSession.LastReceivePingTime) and
          ( (GetTickCount - ServerSession.LastReceivePingTime) >
            (ServerSession.Session.ConnectParams.WaitForPingAnswer / (ServerSession.Session.ConnectParams.PingCount + 1)))
       then
        begin //ping answer not received yet
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> Sending Ping...');
{$ENDIF}
           FManager.SendPing(ServerSession);
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> Sent!');
{$ENDIF}
           ServerSession.LastSendPingTime := GetTickCount;
(*
           if ServerSession.LastReceivePingTime = 0 then // first ping
             ServerSession.LastReceivePingTime := ServerSession.LastSendPingTime;
moved to connect
*)
        end;
       if ((GetTickCount - ServerSession.LastReceivePingTime) >
              ServerSession.Session.ConnectParams.WaitForPingAnswer) then
          begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('LastReceivePingTime =' + IntToStr(ServerSession.LastReceivePingTime));
aaWriteToLog('WaitForPingAnswer   =' + IntToStr(ServerSession.Session.ConnectParams.WaitForPingAnswer));
aaWriteToLog('Waited              =' + IntToStr(GetTickCount-ServerSession.LastReceivePingTime));
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> DoDisconnect...');
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> DoDisconnect...');
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
           dec(ServerSession.Status);
           FManager.DoDisconnect(ServerSession.Session);
           ServerSession := nil;
           Delay := 0;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> Disconnected!');
{$ENDIF}
          end;
      end;
    finally
     if ServerSession <> nil then
       dec(ServerSession.Status);
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> session sleep...');
{$ENDIF}
    sleep(Delay);
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> next Session');
{$ENDIF}
    end;
   end; // next Session
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> loop sleep...');
{$ENDIF}
  if FManager.FServer = nil then
    sleep(MsgServerPingSleep)
  else
    sleep(TMsgServer(FManager.FServer).NetworkSettings.ServerPingSleep);
 until False;
{$IFDEF DEBUG_LOG_PING}
finally
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
end;
{$ENDIF}
 except
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRServerPingClientsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerPingClientsThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerPingClientsThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute




////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerListenerThread.Create(
                       Manager:       TMsgServerConnectionManager
                                            );
begin
 try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TMsgServerListenerThread.Create> START');
{$ENDIF}
  FManager := Manager;
  FManager.IncThreadCount;
  FManager.ListenerThread := Self;
  FManager.FListenerStoped := False;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerListenerThread.Create> inherited... - '+IntToStr(GetTickCount));
{$ENDIF}
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TMsgServerListenerThread.Create> FINISH - '+IntToStr(GetTickCount));
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerListenerThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerListenerThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerListenerThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER LISTENER THREAD - FINISH');
{$ENDIF}
  FManager.FListenerStoped := True;
  FManager.ListenerThread := nil;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER LISTENER THREAD - inherited Destroy');
{$ENDIF}
  if (FManager<>nil) then
    FManager.DecThreadCount;
  inherited Destroy;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('SERVER LISTENER THREAD - FINISHED');
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerListenerThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerListenerThread,-1,
                  Error);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerListenerThread.Execute;
label
  StartProcessing,
  KillPacket;
var
  Header:               PMsgPacketHeader;
  Packets:              TMsgList;
  NetworkPacket:        PMsgNetworkPacket;
  Sessions:             TMsgList;
  i:                    Integer;
  Bool:                 Boolean;
  EmptyTime,
  SleepTime,
  StartTime:            Cardinal;


function AllMsgPacketsReceived: Boolean;
var
  i:                    Integer;
  Packets:              TMsgList;
begin
// Are all packets received?
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Are all message packets received?');
{$ENDIF}
 Result := True;
 Packets := ServerSession.MsgPackets.LockList;
 try
  for i:=0 to Packets.Count-1 do
   if Packets.Items[i] = nil then
    begin
     Result := False;
     break;
    end;
  finally
  ServerSession.MsgPackets.UnlockList;
  end;
end; // function AllPacketsReceived: Boolean;


function AllPacketsReceived: Boolean;
var
  i:                    Integer;
  Packets:              TMsgList;
begin
// Are all packets received?
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Are all command packets received?');
{$ENDIF}
 Result := True;
 Packets := ServerSession.Packets.LockList;
 try
  for i:=0 to Packets.Count-1 do
   if Packets.Items[i] = nil then
    begin
     Result := False;
     break;
    end;
 finally
  ServerSession.Packets.UnlockList;
 end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
if Result then
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Yes')
else
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': No');
{$ENDIF}
end; // function AllPacketsReceived: Boolean;


function IsHeaderValid: Boolean;
begin
  Result := False;
// Check size
  if (NetworkPacket.Packet.BufferSize < SizeOf(TMsgPacketHeader)) then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER: too small packet size = '+IntToStr(NetworkPacket.Packet.BufferSize));
{$ENDIF}
    Exit;
   end;
// Check sign
  if (Header.Signature <> MsgClientPacketSign) then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER: invalid Signature');
{$ENDIF}
    Exit;
   end;
// Check for errors
  if CheckSum(NetworkPacket.Packet.Buffer, NetworkPacket.Packet.BufferSize) <> Header.CheckSum then
   begin
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('SERVER: invalid CheckSum');
{$ENDIF}
    FManager.PacketResendRequest(NetworkPacket.Packet.Buffer, FManager.FNetwork, NetworkPacket.FromHost, NetworkPacket.FromPort);
    Exit;
   end;
// Check ServerID
  if (Header.Recepient <> TMsgServer(FManager.FServer).ServerID) then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER: invalid ServerID');
{$ENDIF}
    Exit;
   end;
  Result := True;
end; // IsHeaderValid


function IsConnectionValid: Boolean;
var
  i:                    Integer;
begin
  Result := False;
// verify ConnectionID existing and SessionID existing in this connection
  SessionFound := False;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Sessions');
{$ENDIF}
  Sessions := FManager.FSessions.LockList;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Sessions Locked');
{$ENDIF}
  try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           @Sessions='+IntToStr(Integer(Sessions)));
aaWriteToLog('           Sessions.Count='+IntToStr(Integer(Sessions.Count)));
{$ENDIF}
   for i:=0 to Sessions.Count-1 do
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           i='+IntToStr(i));
aaWriteToLog('           Sessions.Count='+IntToStr(Integer(Sessions.Count)));
{$ENDIF}
     ServerSession := Sessions.Items[i];
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           @ServerSession='+IntToStr(Integer(ServerSession)));
aaWriteToLog('ServerSession.ConnectionID = '+IntToStr(ServerSession.ConnectionID));
aaWriteToLog('Header.ConnectionID        = '+IntToStr(Header.ConnectionID));
aaWriteToLog('ServerSession.Session.SessionID = '+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('Header.SessionID                = '+IntToStr(Header.SessionID));
aaWriteToLog('ServerSession.ClientSessionID   = '+IntToStr(ServerSession.ClientSessionID));
aaWriteToLog('Header.ControlCode = '+IntToStr(Header.ControlCode));
{$ENDIF}
     if (ServerSession.ConnectionID = Header.ConnectionID)
     and ( (ServerSession.Session.SessionID = Header.SessionID)
           or ( (ServerSession.ClientSessionID = Header.SessionID)
                and  ( (Header.ControlCode = MsgConnect)
                    or (Header.ControlCode = (MsgConnect + MsgLastPacket))
                     )
              )
         )
     then
       begin
        SessionFound := True;
        break;
       end;
    end;
  finally
   FManager.FSessions.UnlockList;
  end;
  if not SessionFound then
  if (Header.ControlCode <> MsgConnect) then // packet is not from Connect request
  if (Header.ControlCode <> (MsgConnect+MsgLastPacket)) then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session not found');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER: invalid SessionID or ConnectionID');
{$ENDIF}
    // client try to continue work with new server without loggin first
    // instead of old server it was loggin into
    New(ServerSession);
    ServerSession.Connected := False;
    ServerSession.AnswerTime := 0;
    ServerSession.LastSendPingTime := GetTickCount;
    ServerSession.LastReceivePingTime := ServerSession.LastSendPingTime;
    ServerSession.CurrentRequestID := Header.CurrentRequestID;
    ServerSession.RemoteClientID := Header.Sender;
    ServerSession.ConnectionID := Header.ConnectionID;
    ServerSession.Session := TMsgServerSession.Create(FManager.FServer);
    TMsgServerSession(ServerSession.Session).SetServerSession(ServerSession);
    ServerSession.Session.SessionID := Header.SessionID;
    ServerSession.RemoteHost := NetworkPacket.FromHost;
    ServerSession.RemotePort := NetworkPacket.FromPort;
    ServerSession.ContactCount := 0;

    ServerSession.Thread := nil;
    ServerSession.MsgThread := nil;
    ServerSession.MsgThreadCount := 0;
    ServerSession.DisconnectThread := nil;
    ServerSession.PacketIDsToResend := nil;
    ServerSession.MsgPacketIDsToResend := nil;
    ServerSession.MsgQueue := nil;
    ServerSession.MsgPackets := nil;
    ServerSession.MsgReceivedPackets := nil;

{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Try to send ACKN to old client...');
{$ENDIF}
    if Header.ControlCode = MsgDisconnect then
     begin
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TMsgServerListenerThread.Execute - IsConnectionValid');
{$ENDIF}
      FManager.SendAcknowledgement(ServerSession);
     end
    else
      FManager.SendDisconnectRequest(ServerSession, False);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': remove session packets from incoming queue...');
{$ENDIF}
    FManager.TerminateAllSessionThreads(ServerSession);
    if ServerSession.Session <> nil then
     begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session.Free...');
{$ENDIF}
      ServerSession.Session.Free;
     end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Dispose...');
{$ENDIF}
    Dispose(ServerSession);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Old client is disconnected');
{$ENDIF}
    Exit;
   end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session found');
{$ENDIF}
// verify Sender
  if ServerSession.RemoteClientID <> Header.Sender then
   begin
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER: invalid Sender');
{$ENDIF}
    Exit;
   end;
// update network address
  if ServerSession.Session.FConnectParams.KeepConnection then
   begin
    ServerSession.RemoteHost := NetworkPacket.FromHost;
    ServerSession.RemotePort := NetworkPacket.FromPort;
   end;
  Result := True;
end; // IsConnectionValid


function IsCommandLock: Boolean;
begin
  Result := True;
  if ServerSession.ControlCode <> MsgExecute then
   begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('IsCommandLock> ControlCode <> MsgExecute');
{$ENDIF}
    Exit;
   end;
  if Header.CurrentRequestID > ServerSession.CurrentRequestID then // could be packets re-sorted
   begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('IsCommandLock> could be packets re-sorted');
{$ENDIF}
    Exit;
   end;
  if ServerSession.Thread <> nil then // Command session started
{$IFDEF ClientCommand_Fix}
   if ServerSession.Thread.FFinishing <> True then
{$ENDIF}
    if Header.CurrentRequestID = ServerSession.CurrentRequestID then
     begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('IsCommandLock> session not finished and packet with CurrentRequestID ');
{$ENDIF}
// check for CurrentID inced but session not finished - Result := True
      if ServerSession.SendStatus = MsgNotSent then // sending answer, current request
       begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('IsCommandLock> thread is sending answer, current request - will be killed by IsCurrentRequestIDValid');
{$ENDIF}
        Result := False; // process this packet - will be killed by IsCurrentRequestIDValid
       end
      else
       begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('IsCommandLock> thread sent answer, could be CurrentID inced but session not finished: new request - get another packet');
{$ENDIF}
       end;
      Exit;
     end;
  Result := False;
end; // IsCommandLock


function IsCurrentRequestIDValid: Boolean;
begin
  Result := False;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - ServerSession.CurrentRequestID = '+IntToStr(ServerSession.CurrentRequestID));
{$ENDIF}
  if Header.CurrentRequestID > ServerSession.CurrentRequestID then // Error!
   begin // disconnect
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - Header.CurrentRequestID > ServerSession.CurrentRequestID, create disconnect thread... ');
{$ENDIF}
    if ServerSession.DisconnectThread = nil then // are not deleting
      ServerSession.DisconnectThread :=
             TMsgServerSessionDisconnectThread.Create(FManager, ServerSession,
                                                      Header.CurrentRequestID);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - disconnect thread created');
{$ENDIF}
    Exit;
   end;
  if Header.CurrentRequestID < ServerSession.CurrentRequestID then // old request
   begin // request already processed - kill old packet
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - Header.CurrentRequestID < ServerSession.CurrentRequestID');
{$ENDIF}
    Exit; // client received answer - no needs to ackn
   end;
// CurrentRequestID is valid
  if ServerSession.Thread <> nil then  // request is processing now
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - ServerSession.Thread <> nil');
try
if ServerSession.Thread.FFinishing = True then
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - FFinishing = True - wait for session finish...')
else
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - FFinishing = False');
except
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - FFinishing - EXCEPTION!');
end;
{$ENDIF}
{$IFDEF ClientCommand_Fix}
    if ServerSession.Thread.FFinishing = True then // wait for session finish
     begin
      StartTime := GetTickCount;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - while...');
{$ENDIF}
      while ((GetTickCount - StartTime) < MsgWaitForServerSessionThreadFinish) do
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
//aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - (GetTickCount - StartTime)='+IntToStr(GetTickCount - StartTime));
{$ENDIF}
        if ServerSession.Thread = nil then
         begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - server session finished for '+IntToStr(GetTickCount - StartTime)+' msec');
{$ENDIF}
          break;
         end;
        sleep(1);
       end;
     end;
{$ENDIF}
    if ServerSession.Thread <> nil then  // request is still processing
     begin
      if ServerSession.ReceiveStatus = MsgFull then // all packets received, buffer not received - current request
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER-IsCurrentRequestIDValid> all packets received, buffer not received: current request - ackn, kill packet');
{$ENDIF}
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('SERVER-IsCurrentRequestIDValid> all packets received, buffer not received: current request - ackn, kill packet');
{$ENDIF}
        FManager.SendAcknowledgement(ServerSession,False,Header.CurrentRequestID);
       end;
      if ServerSession.SendStatus = MsgNotSent then // client is sending answer, old request
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('IsCurrentRequestIDValid> client is sending answer, old request');
{$ENDIF}
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('IsCurrentRequestIDValid> client is sending answer, old request');
{$ENDIF}
        FManager.SendAcknowledgement(ServerSession,False,Header.CurrentRequestID);
       end;
      Exit;
     end;
   end
  else
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> IsCurrentRequestIDValid - ServerSession.Thread = nil');
{$ENDIF}
   end;
  Result := True;
end; // IsCurrentRequestIDValid


begin // TMsgServerListenerThread.Execute;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** SERVER LISTENER START *****');
{$ENDIF}
 EmptyTime := GetTickCount;
 SleepTime := 1;
 repeat
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SleepTime = '+IntToStr(SleepTime)+' sleep...');
{$ENDIF}
//  if SleepTime > 0 then //-- Do not uncomment: sleep(0) must be for maximal speed. For local client-server communication removing sleep(0) takes no effect for server speed but decrease client speed
    sleep(SleepTime);
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('Up!');
{$ENDIF}
  if Terminated then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Terminated!');
{$ENDIF}
    Exit;
   end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
//aaWriteToLog('ServerListenerThread> Starting Packet Processing... - time = '+IntToStr(GetTickCount));
{$ENDIF}
 try // except - continue loop
  Packets := FManager.FIncomingPackets.LockList;
  try
   if Packets.Count = 0 then
    begin
      if (GetTickCount >= (EmptyTime + MsgPacketProcessTimeOut)) then
       begin
        SleepTime := 1; // To avoid 100% CPU usage
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('ServerListenerThread.Execute> new SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
       end;
     Continue;
    end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter21);
aaStartTime(time21);
{$ENDIF}
  EmptyTime := GetTickCount;
  SleepTime := 0;
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('ServerListenerThread.Execute> new SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Packets Count = '+IntToStr(Packets.Count));
{$ENDIF}
   NetworkPacket := PMsgNetworkPacket(Packets.Items[0]);
  finally
   FManager.FIncomingPackets.UnlockList;
  end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> Packet added to queue - time = '+IntToStr(GetTickCount));
{$ENDIF}
 try // finally - free packet
StartProcessing:
  Header := Pointer(NetworkPacket.Packet.Buffer);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TMsgServerListenerThread.Execute> SERVER<<< '
              +IntToStr(Header.CurrentRequestID)+' : '
              +IntToStr(Header.PacketID)+' / '
              +IntToStr(Header.ControlCode)+' <<< '
              +NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort));
aaWriteToLog('           Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('           Header.PacketID         = '+IntToStr(Header.PacketID));
aaWriteToLog('           Header.ControlCode      = '+IntToStr(Header.ControlCode));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Connections');
{$ENDIF}
//EnterCSect(FManager.FCSect);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
//aaWriteToLog('ENTERED!');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> IsHeaderValid... - time = '+IntToStr(GetTickCount));
{$ENDIF}
  if not IsHeaderValid then
   begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> Header not valid, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TMsgServerListenerThread.Execute> Header not valid');
{$ENDIF}
    goto KillPacket;
   end;
  if    // first packet in multi-packet connect request
  ((Header.ControlCode=MsgConnect) and (Header.PacketID=0))
  or    // single-packet connect request
  ((Header.ControlCode=(MsgConnect+MsgLastPacket)) and (Header.PacketID=0))
  then
   begin // Connect
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Connect');
{$ENDIF}
    SessionFound := False;
    Sessions := FManager.FSessions.LockList;
    try
     for i:=0 to Sessions.Count-1 do
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Check session '+IntToStr(i)+' of '+IntToStr(Sessions.Count));
{$ENDIF}
       ServerSession := Sessions.Items[i];
       if (ServerSession.ClientSessionID = Header.SessionID)
       and (ServerSession.ConnectionID = Header.ConnectionID)
       and (ServerSession.RemoteClientID = Header.Sender)
       then
        begin
         SessionFound := True;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Found: @session='+IntToHex(Integer(ServerSession),6)+', Client SessionID='+IntToStr(ServerSession.ClientSessionID));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Found: @session='+IntToHex(Integer(ServerSession),6)+', Server SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
         break;
        end;
      end;
    finally
     FManager.FSessions.UnlockList;
    end;
    if not SessionFound then
     begin // First connect
// new ServerSession
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': New ServerSession');
{$ENDIF}
      New(ServerSession);
      ServerSession.Connected := False;
      ServerSession.AnswerTime := 0;
      ServerSession.LastSendPingTime := GetTickCount;
      ServerSession.LastReceivePingTime := ServerSession.LastSendPingTime;
      ServerSession.Status := MsgVacant;
      ServerSession.ReceiveStatus := MsgStart;
      ServerSession.MsgReceiveStatus := MsgNo;
      ServerSession.RemoteHost := NetworkPacket.FromHost;
      ServerSession.RemotePort := NetworkPacket.FromPort;
      ServerSession.ConnectionID := Header.ConnectionID;
      ServerSession.ClientSessionID := Header.SessionID;
      ServerSession.ContactCount := 0;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+':   New: @session='+IntToHex(Integer(ServerSession),6)+', Client SessionID='+IntToStr(ServerSession.ClientSessionID));
{$ENDIF}
      ServerSession.RemoteClientID := Header.Sender;
      ServerSession.Session := nil;
      ServerSession.Session := TMsgServerSession.Create(FManager.FServer);
      TMsgServerSession(ServerSession.Session).SetServerSession(ServerSession);
      ServerSession.Session.FConnectParams.CryptoInfo := TMsgServer(FManager.FServer).CryptoParams.GetCryptoParams;
      ServerSession.Thread := nil;
      ServerSession.MsgThread := nil;
      ServerSession.MsgThreadCount := 0;
      ServerSession.DisconnectThread := nil;
//      ServerSession.ListeningThreads := TMsgThreadList.Create;
      ServerSession.ControlCode := MsgExecute;
//      ServerSession.ListeningThreads.Add(self);
//      ServerSession.MsgListeningThreads := TMsgThreadList.Create;
      ServerSession.MsgControlCode := MsgExecute;
// Set SessionID
      EnterCSect(FManager.FCSect);
      ServerSession.Session.SessionID := FManager.FSessionID;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+':   New: @session='+IntToHex(Integer(ServerSession),6)+', Server SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
      inc(FManager.FSessionID);
      if FManager.FSessionID = INVALID_SESSION_ID then
       inc(FManager.FSessionID);
      LeaveCSect(FManager.FCSect);
// Create PacketIDsToResend
      ServerSession.PacketIDsToResend := TMsgThreadIntArray.Create;
      ServerSession.MsgPacketIDsToResend := TMsgThreadIntArray.Create;
// Create new packets list
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Packets list create');
{$ENDIF}
      ServerSession.Packets := TMsgThreadList.Create;
      Packets := ServerSession.Packets.LockList;
      try
       Packets.Capacity := MsgDefaultPacketsInRequest; // Allocate some place in list
      finally
       ServerSession.Packets.UnlockList;
      end;
      ServerSession.MsgQueue := TMsgThreadList.Create;
      ServerSession.MsgPackets := TMsgThreadList.Create;
      ServerSession.MsgReceivedPackets := nil;
      Packets := ServerSession.MsgPackets.LockList;
      try
       Packets.Capacity := MsgDefaultPacketsInRequest; // Allocate some place in list
      finally
       ServerSession.MsgPackets.UnlockList;
      end;
// add new session to list
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': add new session to list');
{$ENDIF}
      FManager.FSessions.Add(ServerSession);
      SessionFound := True;
     end
    else // not first connect - reset and resend connection info
     begin
      if ServerSession.Thread <> nil then // Is NetworkPacket.Packet.Buffer receiving now?
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': NetworkPacket.Packet.Buffer is receiving now');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> ServerSession.Thread <> nil, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
      if (ServerSession.ControlCode <> MsgExecute) then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Not Execute - Terminate ListeningThread, ServerSession.ControlCode='+IntToStr(ServerSession.ControlCode));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> ControlCode <> MsgExecute, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
      if (ServerSession.CurrentRequestID > Header.CurrentRequestID) then // packet from old connection request
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': OldPacket - SendAckn');
{$ENDIF}
        FManager.SendConnectAckn(ServerSession, Header.CurrentRequestID);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': OldPacket - Terminate ListeningThread');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> ServerSession.Thread <> nil, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
      if ServerSession.MsgThread <> nil then
        FManager.CloseThread(@ServerSession.MsgThread,MsgServerListenerThread,ErrorRServerSessionMsgThread,
            ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut);
      if ServerSession.DisconnectThread <> nil then
        FManager.CloseThread(@ServerSession.DisconnectThread,MsgServerListenerThread,ErrorRServerSessionDisconnectThread,
            ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut);
//      ServerSession.MsgThread := nil;
//      ServerSession.ListeningThreads.Add(self);
// Set PacketIDsToResend
      ServerSession.PacketIDsToResend.Lock;
      ServerSession.PacketIDsToResend.SetSize(0);
      ServerSession.PacketIDsToResend.Unlock;
      ServerSession.MsgPacketIDsToResend.Lock;
      ServerSession.MsgPacketIDsToResend.SetSize(0);
      ServerSession.MsgPacketIDsToResend.Unlock;
(*
// Delete old packets NetworkPacket.From list
      Packets := ServerSession.Packets.LockList;
      try
       for i:=0 to Packets.Count-1 do
         Packets.Items[i] := nil;
       Packets.Count := 0;
      finally
       ServerSession.Packets.UnlockList;
      end;
      Packets := ServerSession.MsgPackets.LockList;
      try
       for i:=0 to Packets.Count-1 do
         Packets.Items[i] := nil;
       Packets.Count := 0;
      finally
       ServerSession.Packets.UnlockList;
      end;
*)
     end;
// Put this first packet
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': New Packet');
{$ENDIF}
    ServerSession.Packets.Add(NetworkPacket.Packet);
    ServerSession.CurrentRequestID := Header.CurrentRequestID;
    ServerSession.ClientMessageID := 0;
    ServerSession.ServerMessageID := 0;
// Get connection parameters
    if Header.ControlCode=MsgConnect+MsgLastPacket then
     ServerSession.ReceiveStatus := MsgFull;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSessionThread.Create');
{$ENDIF}
    ServerSession.Thread := TMsgServerSessionThread.Create(FManager,
                                                  ServerSession, MsgConnect);
    Continue;
   end; // Connect
// check SessionID and ConnactionID
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> IsConnectionValid... - time = '+IntToStr(GetTickCount));
{$ENDIF}
   if not IsConnectionValid then
    begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> Invalid connection, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TMsgServerListenerThread.Execute> Invalid connection');
{$ENDIF}
     goto KillPacket;
    end;
// check CurrentRequestID
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> check CurrentRequestID... - time = '+IntToStr(GetTickCount));
{$ENDIF}
  if (Header.ControlCode = MsgMessageReceived)
  or (Header.ControlCode = MsgMessagePacketResendRequest)
  then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSession.ServerMessageID = '+IntToStr(ServerSession.ServerMessageID));
{$ENDIF}
    if ServerSession.ServerMessageID <> Header.CurrentRequestID then
     begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('ServerListenerThread> ServerSession.ServerMessageID <> Header.CurrentRequestID');
{$ENDIF}
      goto KillPacket;
    end;
   end
  else
  if (Header.ControlCode = MsgMessage)
  or (Header.ControlCode = (MsgMessage + MsgLastPacket))
  or (Header.ControlCode = MsgMessageAbort)
  then
   begin
     if (Header.CurrentRequestID < ServerSession.ClientMessageID)
     or ((Header.CurrentRequestID = ServerSession.ClientMessageID) and
         (ServerSession.MsgReceiveStatus = MsgFull))
     then // lost acknowledgement
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Send Ackn');
{$ENDIF}
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TMsgServerListenerThread.Execute - check message CurrentRequestID');
{$ENDIF}
       FManager.SendAcknowledgement(ServerSession, True, Header.CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> lost acknowledgement, SessionID = '+IntToStr(Header.SessionID));
aaWriteToLog('Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('ServerSession.ClientMessageID = '+IntToStr(ServerSession.ClientMessageID));
if ServerSession.MsgReceiveStatus = MsgFull then
aaWriteToLog('MsgFull')
else
aaWriteToLog('not MsgFull');
{$ENDIF}
       goto KillPacket; // Do not replace correct packets with doubles
      end;
(*
    if ServerSession.ClientMessageID > Header.CurrentRequestID then // old message
     begin
      goto KillPacket;
     end;
    if ServerSession.ClientMessageID < Header.CurrentRequestID then // lost acknowledgement NetworkPacket.From client
      ServerSession.MsgSendStatus := MsgSent;
*)
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('ServerListenerThread>  Add Listening Thread in '+IntToStr(Integer(ServerSession)));
{$ENDIF}
(*
    if ServerSession.MsgListeningThreads = nil then
     begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgListeningThreads = nil');
{$ENDIF}
      goto KillPacket;
     end
    else
*)
     begin
      if (ServerSession.MsgControlCode <> MsgExecute) then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgControlCode <> MsgExecute -- kill packet');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> ServerSession.MsgControlCode <> MsgExecute, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
//      ServerSession.MsgListeningThreads.Add(self);
     end;
   end
  else // Command, not message
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('Command, not message');
{$ENDIF}
    if Header.ControlCode <> MsgDisconnect then
    if Header.ControlCode <> MsgPing then
    if (Header.ControlCode <> MsgAllPacketsReceived) then
// added as a fix to ACR v.5.50
    if Header.ControlCode <> MsgLogon then
    if Header.ControlCode <> MsgLogoff then
    if Header.ControlCode <> MsgAllPacketsReceived then
    if Header.ControlCode <> MsgPacketResendRequest then
    if Header.ControlCode <> MsgMessageReceived then
    if Header.ControlCode <> MsgMessagePacketResendRequest then
    if Header.ControlCode <> MsgMessageAbort then
     begin
      if IsCommandLock then
       begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('TMsgServerListenerThread> command lock, current command executed # '+IntToStr(ServerSession.CurrentRequestID)+', request # '+IntToStr(Header.CurrentRequestID)+', packet # '+IntToStr(Header.PacketID));
{$ENDIF}
//        if Header.ControlCode > MsgLastPacket then
         begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
if ServerSession.SendStatus = MsgSent then
aaWriteToLog('next command enabled, thread is finishing')
else
aaWriteToLog('packets re-sorted');
{$ENDIF}
          Packets := FManager.FIncomingPackets.LockList;
          try
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('Packets.Count = '+IntToStr(Packets.Count));
{$ENDIF}
           if Packets.Count <= 1 then // no other packets
            begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('wait for session thread finishing...');
{$ENDIF}
             i:= ServerSession.Session.ConnectParams.ServerRequestDelay div 4;
             if i < 17 then
               i := 17
             else
             if i > 100 then
               i := 100;
             StartTime := GetTickCount;
             while ((GetTickCount-StartTime) < i) do // wait for session thread finishing
              begin
               if not IsCommandLock then
                begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('not IsCommandLock, session finished -- break');
{$ENDIF}
                 break;
                end;
               FManager.FIncomingPackets.UnlockList;
               sleep(0);
               Packets := FManager.FIncomingPackets.LockList;
               if Packets.Count > 1 then
                begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('Packets.Count > 1 -- break');
{$ENDIF}
                 break;
                end;
              end;
             if (GetTickCount-StartTime) >= i then
              begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('session thread not finished!');
{$ENDIF}
               Continue;
              end;
            end;
           if Packets.Count <= 1 then
            begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('previous command finished, process this new command');
{$ENDIF}
            end
           else
            begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('get next packet...');
{$ENDIF}
             i := Packets.IndexOf(NetworkPacket);
             if i = (Packets.Count - 1) then // all queue processed, packet not found
              begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('all queue processed, packet not found...');
{$ENDIF}
               NetworkPacket := PMsgNetworkPacket(Packets.Items[0]);
               Continue;
              end;
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('get packet # '+IntToStr(i+1)+' ...');
{$ENDIF}
             NetworkPacket := PMsgNetworkPacket(Packets.Items[i+1]);
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('sleep...');
{$ENDIF}
//             sleep(1);
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('wake up - process packet # '+IntToStr(i+1)+' ...');
{$ENDIF}
            end;
          finally
           FManager.FIncomingPackets.UnlockList;
          end;
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('restart processing...');
{$ENDIF}
          goto StartProcessing;
         end;
       end;
      if not IsCurrentRequestIDValid then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('Current RequestID Not Valid -- kill');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> Command Lock, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
     end;
   end; // command checking
// Process service packet
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> Process service packet... - time = '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('ServerListenerThread> Process service packet...');
{$ENDIF}
  case Header.ControlCode of
   MsgDisconnect:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgDisconnect');
{$ENDIF}
//     FManager.CommandReceived(ServerSession,Header.ControlCode,Header.CurrentRequestID);
{
     EnterCSect(FManager.FCSect);
     ServerSession.ControlCode := MsgTerminate;
     ServerSession.MsgControlCode := MsgSuspend;
     LeaveCSect(FManager.FCSect);
}
(*
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Acknowledgement...');
{$ENDIF}
     FManager.SendAcknowledgement(ServerSession, False, Header.CurrentRequestID);
*)
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Acknowledgement has been sent');
{$ENDIF}
     if ServerSession.Session <> nil then // nothing to delete
       if ServerSession.DisconnectThread = nil then // are not deleting
         ServerSession.DisconnectThread :=
              TMsgServerSessionDisconnectThread.Create(FManager, ServerSession,
                                                      Header.CurrentRequestID);
     goto KillPacket;
    end;
   MsgPing:
    begin
     ServerSession.LastReceivePingTime := GetTickCount;
     goto KillPacket;
    end;
   MsgPacketResendRequest:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgPacketResendRequest');
{$ENDIF}
     ServerSession.PacketIDsToResend.Lock;
     ServerSession.PacketIDsToResend.Add(Header.PacketID);
     ServerSession.PacketIDsToResend.Unlock;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received Resend Request');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
     goto KillPacket;
    end;
   MsgMessagePacketResendRequest:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgMessagePacketResendRequest');
{$ENDIF}
     ServerSession.MsgPacketIDsToResend.Lock;
     ServerSession.MsgPacketIDsToResend.Add(Header.PacketID);
     ServerSession.MsgPacketIDsToResend.Unlock;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received Message Resend Request');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
     goto KillPacket;
    end;
   MsgAllPacketsReceived:
    begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('AllPacketsReceived');
aaWriteToLog('CurrentRequestID = '+IntToStr(ServerSession.CurrentRequestID)+', CurrentRequestID ='+IntToStr(Header.CurrentRequestID));
{$ENDIF}
     if ServerSession.CurrentRequestID = Header.CurrentRequestID then
      begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('request ID - OK');
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgAllPacketsReceived');
{$ENDIF}
       ServerSession.SendStatus := MsgSent;
       ServerSession.PacketIDsToResend.Lock;
       ServerSession.PacketIDsToResend.SetSize(0);
       ServerSession.PacketIDsToResend.Unlock;
//       SleepTime := 1; -- Do not uncomment, will sleep(0) in any case
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TMsgServerListenerThread.Execute> new SleepTime = '+IntToStr(SleepTime)+' - MsgAllPacketsReceived');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received Command Acknowledgement');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
      end;
     goto KillPacket;
    end;
   MsgMessageReceived:
    begin
     ServerSession.MsgSendStatus := MsgSent;
     ServerSession.MsgPacketIDsToResend.Lock;
     ServerSession.MsgPacketIDsToResend.SetSize(0);
     ServerSession.MsgPacketIDsToResend.Unlock;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received Message Acknowledgement');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
     goto KillPacket;
    end;
//------------------------------------------------------------------------------
     MsgMessageAbort:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('MsgMessageAbort...');
aaWriteToLog('ServerSession.ClientMessageID = '+IntToStr(ServerSession.ClientMessageID));
aaWriteToLog('ServerSession.ServerMessageID = '+IntToStr(ServerSession.ServerMessageID));
{$ENDIF}
       if ServerSession.ClientMessageID = Header.CurrentRequestID then
         try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('MsgMessageAbort try intered');
{$ENDIF}
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TMsgServerPacketProcessorThread> free packets...');
{$ENDIF}
          FManager.FreePackets(ServerSession.MsgPackets);
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TMsgServerPacketProcessorThread> count = 0...');
{$ENDIF}
          ServerSession.MsgPackets.LockList;
          ServerSession.MsgPackets.Count := 0;
          ServerSession.MsgPackets.UnlockList;
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TMsgServerPacketProcessorThread> SendAcknowledgement...');
{$ENDIF}
          FManager.SendAcknowledgement(ServerSession,true);
         finally
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('MsgMessageAbort fianally intered');
{$ENDIF}
          inc(ServerSession.ClientMessageID);
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TMsgServerPacketProcessorThread> ServerSession.ClientMessageID='+IntToStr(ServerSession.ClientMessageID));
{$ENDIF}
         end;
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
   MsgMessage,
   (MsgMessage+MsgLastPacket):
//------------------------------------------------------------------------------
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': message packet');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> MsgMessage packet - starting... - time = '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TMsgServerListenerThread.Execute> message with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}

//     if Header.ControlCode < MsgLastPacket then // Enable LastPacket to start session thread
(*
 moved to CurrentRequestID checking
     if (Header.CurrentRequestID  ServerSession.ClientMessageID)
     or ((Header.CurrentRequestID = ServerSession.ClientMessageID) and
         (ServerSession.MsgReceiveStatus = MsgFull))
     then // lost acknowledgement
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Full Answer!');
{$ENDIF}
       FManager.SendAcknowledgement(ServerSession, True, Header.CurrentRequestID);
       goto KillPacket; // Do not replace correct packets with doubles
      end;
*)
// new request?
// Is this packet already stored?
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Is this packet already stored?');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('Get list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets)))+' time = '+IntToStr(GetTickCount));
{$ENDIF}
     if ServerSession.MsgPackets = nil then // list absent
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': list absent');
{$ENDIF}
       goto KillPacket;
      end;
     Packets := ServerSession.MsgPackets.LockList;
      if ((Header.PacketID+1) <= Packets.Count) then // old packet
       if (Packets.Items[Header.PacketID] <> nil) then // already received
        begin
         ServerSession.MsgPackets.UnlockList;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           Packets.Count='+IntToStr(Integer(Packets.Count)));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Existing message packet');
aaWriteToLog('           @Items='+IntToStr(Integer(Packets.Items[Header.PacketID])));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('Server received existing packet');
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('MsgAllPacketsReceived?');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> AllMsgPacketsReceived? - time = '+IntToStr(GetTickCount));
{$ENDIF}
         if AllMsgPacketsReceived then
          begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('Yes');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TMsgServerListenerThread.Execute> AllMsgPacketsReceived: receive message with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}
           FManager.MessageReceived(ServerSession);
          end;
{
         else
           if (Header.ControlCode >= MsgLastPacket) then
             ServerSession.ReceiveStatus := MsgNotFull; // start requesting
}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Old message packet will be killed');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> doubled packet, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
         goto KillPacket; // Do not replace correct packets with doubles
        end;
// First packet in new request?
     if Packets.Count = 0 then
      begin
       ServerSession.MsgReceiveStatus := MsgStart;
      end;
     ServerSession.MsgPackets.UnlockList;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> MsgPackets list unlocked - time = '+IntToStr(GetTickCount));
{$ENDIF}
// Add correct received data packet
(*
     if Terminated then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           Terminated');
{$ENDIF}
        goto KillPacket;
       end;
*)
     ServerSession.LastReceivePingTime := GetTickCount;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('ServerSession '+IntToStr(ServerSession.Session.SessionID)+' LastReceivePingTime = '+IntToStr(ServerSession.LastReceivePingTime));
{$ENDIF}
{$IFDEF LOG_SERVER_RESENDING}
if ((Header.PacketID+1) <= Packets.Count) then // old packet
if (Packets.Items[Header.PacketID] = nil) then // not received yet
aaWriteToLog('SERVER received packet #'+IntToStr(Header.PacketID));
{$ENDIF}
     Packets := ServerSession.MsgPackets.LockList;
     try
      Bool := False;
      if Packets.Count < (Header.PacketID + 1) then
        Packets.Count := Header.PacketID + 1; // List fills hole by Nil
      if (ServerSession.MsgReceiveStatus <> MsgFull) then
        Packets.Items[Header.PacketID] := NetworkPacket.Packet
      else
       begin
        Bool := True;
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TMsgServerListenerThread.Execute> kill doubled message packet with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}
       end;
     finally
      ServerSession.MsgPackets.UnlockList;
     end;
     if Bool then
      begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = MsgMessage+MsgLastPacket then
  aaWriteToLog('TMsgServerListenerThread.Execute> bool, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
       goto KillPacket;
      end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': server has added new packet');
{$ENDIF}
(*
     if Terminated then
      begin
//       Dispose(Packet);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           Terminated');
{$ENDIF}
       goto KillPacket;
      end;
*)
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('SERVER has added new packet');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
// test last packet
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Last Packet');
{$ENDIF}
     if (Header.ControlCode >= MsgLastPacket) then
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgLastPacket');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> AllMsgPacketsReceived?? - time = '+IntToStr(GetTickCount));
{$ENDIF}
       if AllMsgPacketsReceived then
        begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Yes');
{$ENDIF}
         ServerSession.MsgReceiveStatus := MsgFull;  // Allow to extract NetworkPacket.Packet.Buffer
        end
       else
        begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': No');
{$ENDIF}
         // start resend requesting
         ServerSession.MsgReceiveStatus := MsgNotFull;
        end;
      end; // Last Packet
// Full Answer
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> Full message? - time = '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ClientMessageID = '+IntToStr(ServerSession.ClientMessageID));
{$ENDIF}
     if ServerSession.MsgReceiveStatus = MsgFull then
{
       if Terminated then
         goto KillPacket
       else
}
        begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TMsgServerListenerThread.Execute> MsgReceiveStatus = MsgFull: receive message with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}
         FManager.MessageReceived(ServerSession);
        end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** END OF DATA PACKET *****');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
// End message packet process
      Continue;
    end; // Message packet process
   MsgEcho,
   MsgTunning,
   MsgServerSessionTunning,
   MsgConnect, // for packets with ID>0, not for first packet
   MsgNewRequest,
{$IFNDEF MsgCommunicator}
     ACRClientCommand,
     ACRServerCommand,
{$ENDIF}
   MsgLastPacket..(MsgMessage+MsgLastPacket-1),
   (MsgMessage+MsgLastPacket+1)..127,
   MsgNoAction:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TMsgServerListenerThread> Data packet');
{$ENDIF}
// Check for if the previous data received fully:
{
     if Header.ControlCode then
      begin
       discontinue the previous sending;
      end;
Suppose client session should not send new request if it did not receive the previous fully
}
     if (Header.CurrentRequestID <= ServerSession.CurrentRequestID) then // lost acknowledgement
     if (ServerSession.ReceiveStatus = MsgFull) then // lost acknowledgement
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TMsgServerListenerThread> ServerSession.CurrentRequestID = '+IntToStr(ServerSession.CurrentRequestID));
aaWriteToLog('TMsgServerListenerThread> Full Answer!');
{$ENDIF}
       if (Header.ControlCode <> MsgConnect)
       and (Header.ControlCode <> (MsgConnect+MsgLastPacket))
       then
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TMsgServerListenerThread.Execute - Command process, full answer and old packet check');
{$ENDIF}
         FManager.SendAcknowledgement(ServerSession, False, Header.CurrentRequestID);
       goto KillPacket; // Do not replace correct packets with doubles
      end;
// new request?
(*
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('new request?');
{$ENDIF}
     if Header.ControlCode >= MsgNewRequest then
      if ServerSession.CurrentRequestID < Header.CurrentRequestID then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('Yes');
{$ENDIF}
        ServerSession.ReceiveStatus := MsgStart;
        ServerSession.CurrentRequestID := Header.CurrentRequestID;
        Packets := ServerSession.Packets.LockList;
        try
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('Packets.Count='+IntToStr(Packets.Count));
{$ENDIF}
         for i:=0 to Packets.Count-1 do
           Packets.Items[i] := nil;
         Packets.Count := 0;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('Packets.Count='+IntToStr(Packets.Count));
{$ENDIF}
        finally
         ServerSession.Packets.UnlockList;
        end;
       end;
*)
// Is this packet already stored?
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Is this packet already stored?');
{$ENDIF}
     if Packets.Count = 0 then // list absent
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': list absent');
{$ENDIF}
       goto KillPacket;
      end;
     // list exists
     Packets := ServerSession.Packets.LockList;
      if ((Header.PacketID+1) <= Packets.Count) then // old packet
       if (Packets.Items[Header.PacketID] <> nil) then // already received
        begin
         ServerSession.Packets.UnlockList;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           Packets.Count='+IntToStr(Integer(Packets.Count)));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Existing packet');
aaWriteToLog('           @Items='+IntToStr(Integer(Packets.Items[Header.PacketID])));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('Server received existing packet');
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('AllPacketsReceived?');
{$ENDIF}
         if AllPacketsReceived then
          begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': All Packets on Repeated Packet - '+IntToStr(GetTickCount));
{$ENDIF}
           FManager.CommandReceived(ServerSession, Header.ControlCode, Header.CurrentRequestID);
          end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Old command packet will be killed');
{$ENDIF}
         goto KillPacket; // Do not replace correct packets with doubles
        end;
// First packet in new request?
     if Packets.Count = 0 then
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': First packet in new request!');
{$ENDIF}
       ServerSession.ReceiveStatus := MsgStart;
       ServerSession.LastReceivePingTime := GetTickCount;
      end;
     ServerSession.Packets.UnlockList;
// Add correct received data packet
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Add correct received data packet');
{$ENDIF}
     if Terminated then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           Terminated');
{$ENDIF}
        goto KillPacket;
       end;
     ServerSession.LastReceivePingTime := GetTickCount;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('ServerSession '+IntToStr(ServerSession.Session.SessionID)+' LastReceivePingTime = '+IntToStr(ServerSession.LastReceivePingTime));
{$ENDIF}
{$IFDEF LOG_SERVER_RESENDING}
if ((Header.PacketID+1) <= Packets.Count) then // old packet
if (Packets.Items[Header.PacketID] = nil) then // not received yet
aaWriteToLog('SERVER received packet #'+IntToStr(Header.PacketID));
{$ENDIF}
     Packets := ServerSession.Packets.LockList;
     try
      Bool := False;
      if Packets.Count < (Header.PacketID + 1) then
        Packets.Count := Header.PacketID + 1; // List fills hole by Nil
      if (ServerSession.ReceiveStatus <> MsgFull) then
        Packets.Items[Header.PacketID] := NetworkPacket.Packet
      else
       begin
        Bool := True;
       end;
     finally
      ServerSession.Packets.UnlockList;
     end;
     if Bool then
       goto KillPacket;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': server has added new packet');
{$ENDIF}
(*
      if Terminated
      then
       begin
//        Dispose(Packet);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('           Terminated');
{$ENDIF}
        goto KillPacket;
       end;
*)
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('SERVER has added new packet');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
// test last packet
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Last Packet');
{$ENDIF}
     if (Header.ControlCode >= MsgLastPacket) then
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgLastPacket');
{$ENDIF}
       if AllPacketsReceived then
        begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': All Packets on Last Packet - '+IntToStr(GetTickCount));
{$ENDIF}
         FManager.CommandReceived(ServerSession, Header.ControlCode, Header.CurrentRequestID);
        end
       else
        begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': No');
{$ENDIF}
         // start resend requesting
         ServerSession.ReceiveStatus := MsgNotFull;
         FManager.ResendRequestThread.FNeeded := True;
        end;
      end; // Last Packet
// End data packet process
     Continue;
    end // data packet process
   else
     raise EMsgException.Create(40022, ErrorRUnknownControlCode, [Header.ControlCode]);
   end; // packet process
KillPacket:
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER KILLED PACKET # '+ IntToStr(Header.PacketID)+ ' with control code ' +IntToStr(Header.ControlCode));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': FreeAndNilMem(NetworkPacket.Packet.Buffer)');
{$ENDIF}
  FManager.FIncomingPackets.LockList;
  try
   if NetworkPacket.Packet.Buffer <> nil then
     MemoryManager.FreeAndNilMem(NetworkPacket.Packet.Buffer);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - Free packet...');
{$ENDIF}
   Dispose(NetworkPacket.Packet);
  finally
   FManager.FIncomingPackets.UnlockList;
  end;
 finally
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - Remove incoming packet...');
{$ENDIF}
  FManager.FIncomingPackets.Remove(NetworkPacket);
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER LISTENER THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - Free incoming packet...');
{$ENDIF}
  Dispose(NetworkPacket);
//LeaveCSect(FManager.FCSect);
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('SERVER: '+IntToStr(GetTickCount)+' > Listener finished');
aaWriteToLog('==============================================================');
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER LISTENER THREAD - FINISHED');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> Packet Processed - time = '+IntToStr(GetTickCount));
{$ENDIF}
 end;
 except
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRListenerThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerListenerThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerListenerThread,-1,
                  Error);
    except
    end;
   end;
 end;
 until False;
end; // Execute

// TMsgServerListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerResendRequestThread.Create(
                       Manager:           TMsgServerConnectionManager
                                            );
begin
 try
  FNeeded := False;
  FManager := Manager;
  FManager.IncThreadCount;
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Server RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerResendRequestThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerResendRequestThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Server RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FManager.ResendRequestThread <> nil then
    FManager.ResendRequestThread := nil;
  inherited Destroy;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Server RESENDING THREAD - FINISHED');
{$ENDIF}
  FManager.DecThreadCount;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerResendRequestThread,-1,
                  Error);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerResendRequestThread.Execute;
var
  i, j, k,
  PacketsCount:       Integer;
  Packets:            TMsgList;
  Sessions:           TMsgList;
  ServerSession:      PMsgSrvrSession;
  Header:             TMsgPacketHeader;
  StartTime,
  Delay:              Cardinal;

function IsRequestNeeded(ServerSession: PMsgSrvrSession): Boolean;
begin
  Result := True;
  if ServerSession.ReceiveStatus <> MsgNotFull then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> MsgNotFull <> (ServerSession.ReceiveStatus='+IntToStr(ServerSession.ReceiveStatus)+')');
{$ENDIF}
    Result := False;
    Exit;
   end;
  if ServerSession.ControlCode = MsgTerminate then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> ServerSession.ControlCode = MsgTerminate');
{$ENDIF}
    Result := False;
    Exit;
   end;
end;

begin
 try
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> ***** SERVER RESEND REQUEST START *****');
{$ENDIF}
  j:=0;
  repeat
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Session # j='+IntToStr(j));
{$ENDIF}
    if FNeeded then
     begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Needed, skip sleep');
{$ENDIF}
     end
    else
     begin
      if FManager.FServer = nil then
        Delay := (1 + (MsgServerRequestDelay
                                                div (FManager.SessionsCount+1)))
      else
        Delay := (1 + (TMsgServer(FManager.FServer).NetworkSettings.ServerRequestDelay
                                                div (FManager.SessionsCount+1)));
      StartTime := GetTickCount;
      while ((GetTickCount-StartTime) < Delay) do
       begin
        if Terminated then
         begin
  {$IFDEF LOG_SERVER_RESENDING}
  aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Terminated in sessions loop');
  {$ENDIF}
          Exit;
         end;
        sleep((Delay div 16)+1);
       end;
     end;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Lock Sessions...');
{$ENDIF}
    Sessions := FManager.FSessions.LockList;
    try
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Locked!');
{$ENDIF}
     if j >= Sessions.Count then
      begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> j >= (Sessions.Count='+IntToStr(Sessions.Count)+')');
{$ENDIF}
       FNeeded := False;
       for k:=Sessions.Count-1 downto 0 do
        begin
         ServerSession := Sessions.Items[k];
         if ServerSession.ReceiveStatus = MsgNotFull then
          begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Needed for # '+IntToStr(j));
{$ENDIF}
           FNeeded := True;
           j := k-1;
           break;
          end;
        end;
       if not FNeeded then
        begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Not Needed!');
{$ENDIF}
         j := -1;
        end;
       continue;
      end;
     ServerSession := Sessions.Items[j];
     if ServerSession.ControlCode = MsgTerminate then
      begin
       inc(j);
       continue;
      end;
     inc(ServerSession.Status);
     if not (IsRequestNeeded(ServerSession)) then
      begin
       dec(ServerSession.Status);
       continue;
      end;
    finally
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> UnLock Sessions');
{$ENDIF}
     FManager.FSessions.UnlockList;
     inc(j);
    end;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> TMsgServerResendRequestThread');
{$ENDIF}
    // Make PacketHeader
    Header.Signature := MsgServerPacketSign;
    Header.Recepient := ServerSession.RemoteClientID;
    EnterCSect(FManager.FCSect);
    Header.Sender := FManager.FNetwork.FLocalClient;
    LeaveCSect(FManager.FCSect);
    Header.ConnectionID := ServerSession.ConnectionID;
    Header.SessionID := ServerSession.Session.SessionID;
    Header.PacketID := 0;
    Header.ControlCode := MsgPacketResendRequest;
    Header.CurrentRequestID := ServerSession.CurrentRequestID;
    // Search absent packet and send request to resend it
    Packets := ServerSession.Packets.LockList;
    try
     PacketsCount := Packets.Count;
    finally
     ServerSession.Packets.UnlockList;
    end;
    dec(ServerSession.Status);
    for i:=0 to PacketsCount-1 do
     begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> i='+IntToStr(i));
aaWriteToLog('ServerResendRequuestThread> PacketsCount='+IntToStr(PacketsCount));
{$ENDIF}
      if Terminated then
       begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Terminated in packets loop');
{$ENDIF}
        Exit;
       end;
      if ServerSession.ControlCode = MsgTerminate then
        break;
      inc(ServerSession.Status);
      if ServerSession.Packets <> nil then
       begin
        Packets := ServerSession.Packets.LockList;
        if Packets.Count <= i then
         begin
          ServerSession.Packets.UnlockList;
          dec(ServerSession.Status);
         end
        else if Packets.Items[i] <> nil then
         begin
          ServerSession.Packets.UnlockList;
          dec(ServerSession.Status);
         end
        else // send request
         begin
          ServerSession.Packets.UnlockList;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> PacketResendRequest, i='+IntToStr(i));
{$ENDIF}
{$IFDEF PACKET_RESEND_REQUEST}
          FManager.PacketResendRequest(@Header, FManager.FNetwork, ServerSession.RemoteHost, ServerSession.RemotePort, i, ServerSession.Packets);
{$ELSE}
          FManager.PacketResendRequest(@Header, FManager.FNetwork, ServerSession.RemoteHost, ServerSession.RemotePort, i);
{$ENDIF}
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Packet has been requested to resent');
{$ENDIF}
          if not (IsRequestNeeded(ServerSession)) then
           begin
            dec(ServerSession.Status);
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('break');
{$ENDIF}
            break;
           end;
          dec(ServerSession.Status);
          Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
(*
          for k:=0 to (MsgServerRequestDelay div 2) do
           begin // Pause
            if not (IsRequestNeeded(ServerSession)) then
              break;
            if Terminated then
             begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Terminated in sleep loop');
{$ENDIF}
              Exit;
             end;
            Sleep(2);
           end; // Pause
*)
         end;// send request
       end
      else
       dec(ServerSession.Status);
{$IFDEF PACKET_RESEND_REQUEST}
      break;
{$ENDIF}
     end; // next packet
(*
    if AllPacketsReceived then
     begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> AllPacketsReceived');
{$ENDIF}
{
      EnterCSect(FManager.FCSect);
      if ServerSession.ControlCode = MsgExecute then
        ServerSession.ControlCode := MsgSuspend;
      LeaveCSect(FManager.FCSect);
}
//      ServerSession.ReceiveStatus := MsgFull;
      Packets := ServerSession.Packets.LockList;
      try
       if Packets.Count > 0 then
        begin
         Packet := Packets.Items[0];
         PHeader := PMsgPacketHeader(Packet.Buffer);
         Code := PHeader.ControlCode;
        end;
      finally
       ServerSession.Packets.UnlockList;
      end;
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('ServerResendRequuestThread> All Packets on Request thread - '+IntToStr(GetTickCount));
{$ENDIF}
       FManager.CommandReceived(ServerSession, Code, ServerSession.CurrentRequestID);
     end;
*)
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Get New Session');
{$ENDIF}
   until False; // Get new Session
 except
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerResendRequestThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerResendRequestThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerMsgResendRequestThread.Create(
                       Manager:           TMsgServerConnectionManager
                                            );
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Server MESSAGE RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRMsgResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerMsgResendRequestThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerMsgResendRequestThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Server MESSAGE RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FManager.MsgResendRequestThread <> nil then
    FManager.MsgResendRequestThread := nil;
  inherited Destroy;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Server MESSAGE RESENDING THREAD - FINISHED');
{$ENDIF}
  FManager.DecThreadCount;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRMsgResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerMsgResendRequestThread,-1,
                  Error);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerMsgResendRequestThread.Execute;
var
  i, j,
  PacketsCount:       Integer;
  Packets:            TMsgList;
  Sessions:           TMsgList;
  ServerSession:      PMsgSrvrSession;
  Header:             TMsgPacketHeader;
  StartTime,
  Delay:              Cardinal;

function IsRequestNeeded(ServerSession: PMsgSrvrSession): Boolean;
begin
  Result := True;
  if ServerSession.MsgReceiveStatus <> MsgNotFull then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> MsgNotFull <> (ServerSession.MsgReceiveStatus='+IntToStr(ServerSession.MsgReceiveStatus)+')');
{$ENDIF}
    Result := False;
    Exit;
   end;
  if ServerSession.MsgControlCode = MsgTerminate then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> ServerSession.MsgControlCode = MsgTerminate');
{$ENDIF}
    Result := False;
    Exit;
   end;
end;

begin
 try
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> ***** SERVER MESSAGE RESEND REQUEST START *****');
{$ENDIF}
  j:=0;
  repeat
    if FManager.FServer = nil then
      Delay := (1 + (MsgServerRequestDelay
                                              div (FManager.SessionsCount+1)))
    else
      Delay := (1 + (TMsgServer(FManager.FServer).NetworkSettings.ServerRequestDelay
                                              div (FManager.SessionsCount+1)));
    StartTime := GetTickCount;
    while ((GetTickCount-StartTime) < Delay) do
     begin
      if Terminated then
       begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> Terminated in sessions loop');
{$ENDIF}
        Exit;
       end;
      sleep((Delay div 16)+1);
     end;
    Sessions := FManager.FSessions.LockList;
    try
     if j >= Sessions.Count then
      begin
       j := -1;
       continue;
      end;
     ServerSession := Sessions.Items[j];
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('TMsgServerMsgResendRequestThread> @ServerSession='+IntToStr(Integer(ServerSession)));
{$ENDIF}
     if ServerSession.ControlCode = MsgTerminate then
      begin
       continue;
      end;
     inc(ServerSession.Status);
     if not (IsRequestNeeded(ServerSession)) then
      begin
       dec(ServerSession.Status);
       continue;
      end;
    finally
     FManager.FSessions.UnlockList;
     inc(j);
    end;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('TMsgServerMsgResendRequestThread> Make PacketHeader...');
{$ENDIF}
    // Make PacketHeader
    Header.Signature := MsgServerPacketSign;
    Header.Recepient := ServerSession.RemoteClientID;
    EnterCSect(FManager.FCSect);
    Header.Sender := FManager.FNetwork.FLocalClient;
    LeaveCSect(FManager.FCSect);
    Header.ConnectionID := ServerSession.ConnectionID;
    Header.SessionID := ServerSession.Session.SessionID;
    Header.PacketID := 0;
    Header.ControlCode := MsgMessagePacketResendRequest;
    Header.CurrentRequestID := ServerSession.ClientMessageID;
    // Search absent packet and send request to resend it
    Packets := ServerSession.MsgPackets.LockList;
    try
     PacketsCount := Packets.Count;
    finally
     ServerSession.MsgPackets.UnlockList;
    end;
    dec(ServerSession.Status);
    for i:=0 to PacketsCount-1 do
     begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> i='+IntToStr(i));
aaWriteToLog('ServerMsgResendRequuestThread> PacketsCount='+IntToStr(PacketsCount));
{$ENDIF}
      if Terminated then
       begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> PacketsCount='+IntToStr(PacketsCount));
{$ENDIF}
        Exit;
       end;
      if ServerSession.MsgControlCode = MsgTerminate then
        break;
      inc(ServerSession.Status);
      if ServerSession.MsgPackets <> nil then
       begin
        Packets := ServerSession.MsgPackets.LockList;
        if Packets.Count <= i then
         begin
          ServerSession.MsgPackets.UnlockList;
          dec(ServerSession.Status);
         end
        else if Packets.Items[i] <> nil then
         begin
          ServerSession.MsgPackets.UnlockList;
          dec(ServerSession.Status);
         end
        else // send request
         begin
          ServerSession.MsgPackets.UnlockList;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> PacketMsgResendRequest, i='+IntToStr(i));
{$ENDIF}
          FManager.PacketResendRequest(@Header, FManager.FNetwork, ServerSession.RemoteHost, ServerSession.RemotePort, i, True);
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> Packet has been resent');
{$ENDIF}
          if not (IsRequestNeeded(ServerSession)) then
           begin
            dec(ServerSession.Status);
            break;
           end;
          dec(ServerSession.Status);
          Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
(*
          for k:=0 to (MsgServerRequestDelay div 2) do
           begin // Pause
            if not (IsRequestNeeded(ServerSession)) then
              break;
            if Terminated then
             begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> Terminated in sleep loop');
{$ENDIF}
              Exit;
             end;
            Sleep(2);
           end; // Pause
*)
         end;// send request
       end
      else
       dec(ServerSession.Status);
     end; // next packet
(*
    if AllPacketsReceived then
     begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> AllPacketsReceived');
{$ENDIF}
{
      EnterCSect(FManager.FCSect);
      if ServerSession.MsgControlCode = MsgExecute then
        ServerSession.MsgControlCode := MsgSuspend;
      LeaveCSect(FManager.FCSect);
}
//      ServerSession.MsgReceiveStatus := MsgFull;
      FManager.MessageReceived(ServerSession);
     end;
*)
   until False; // Get new Session
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('ServerMsgResendRequuestThread> TMsgServerSessionThread.Execute - START');
{$ENDIF}
 except
  on E: Exception do
   begin
    try
    Error:=
                  ErrorRServer+ErrorRMsgResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ServerSession = nil)
    or (ServerSession.Session = nil)
    then
      TMsgServer(FManager.FServer).DoOnConnectionError(
                  MsgServerMsgResendRequestThread,-1,
                  Error)
    else
      TMsgNetworkSession(ServerSession.Session).DoOnError(
                  MsgServerMsgResendRequestThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute

{$ENDIF} // Server


{$IFDEF SERVER_VERSION}
//------------------------------------------------------------------------------
// if authorization buffer is valid (encrypted by the same crypto settings as in CryptoInfo)
// then return true else return false
//------------------------------------------------------------------------------
function fnIsAuthorizationBufferValid(
                      CryptoInfo: TMsgCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
var ms:             TMsgMemoryStream;
    crc32, crc32_1: Cardinal;
    size:           Integer;
begin
  Result := True;
  if BufferSize = 0 then
   begin
    if CryptoInfo.CryptoAlgorithm <> 0 then
      Result:= False;
    Exit;
   end;
  ms := TMsgMemoryStream.Create(Buffer, BufferSize);
  try
   try
    LoadDataFromStream(size,SizeOf(crc32),ms,11322);
    LoadDataFromStream(crc32,SizeOf(crc32),ms,11323);
    if (ms.Size - ms.Position <> size) then
     raise EMsgException.Create(11325,ErrorLInvalidStreamSize,[ms.Size,(ms.Position+size)]);
   except
     Result := False;
     Exit;
   end;
    MsgDecryptBuffer(CryptoInfo,PAnsiChar(Buffer+ms.Position),size);
    crc32_1 := MsgCountCRC(0,PAnsiChar(Buffer+ms.Position),size);
    Result := (crc32 = crc32_1);
  finally
    ms.Buffer := nil;
(*
    ms.SetBuffer(nil,0); // Msg 4.10 & ACR 5.00 difference
    { TODO -oAlex : move to msg with new memory engine - 2 }
*)
    ms.Free;
  end;
end; // fnIsAuthorizationBufferValid
{$ENDIF SERVER_VERSION}

{$IFDEF MSWINDOWS}
function TerminateThread;   external    kernel32  name 'TerminateThread';
{$ENDIF}

initialization

 NetLog := ExtractFilePath(ParamStr(0))+'msg_NetLog.txt';

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgConnection> initialized');
{$ENDIF}

finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgConnection> finalized');
{$ENDIF}

end.

