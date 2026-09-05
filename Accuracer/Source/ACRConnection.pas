unit ACRConnection;

interface

{$I ACRVer.inc}
{$HINTS OFF}

{$DEFINE ClientCommand_Fix} // Fix for client command w/o answer, v.5.90

{DEFINE PACKET_RESEND_REQUEST}

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
// Accuracer units
  ACRNetwork,
  ACRNetworkTCP,
  ACRNetworkUDP,
  ACRCrypto,
{$ENDIF}

{$IFDEF DEBUG_LOG}
  ACRDebug,
{$ENDIF}
  ACRCompression,
  ACRCommunication,
  ACRBase,
  ACRTypes,
  ACRTypesNetwork,
  ACRTypesThread,
  ACRConst,
  ACRExcept,
  ACRLinux,
  ACRCriticalSection,
  ACRBaseEngine,
  ACRMemory;

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

  ACR_DefaultClientPort = 12009;

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
 ACRGetUserInfo = 10;
 ACRRegisterNewUser = 11;
 ACRAddUserToContacts = 12;
 ACRRemoveUserFromContacts = 13;
 ACRGetContacts = 14;
 ACRUpdateUserInfo = 15;
 ACRGetUserID = 16;
 ACRFindUsers = 17;
 ACRFindMessages = 18;
 ACRIsUserExisting = 19;
 ACRIsUserOnline = 20;
 ACRUpdateUserInContacts = 21;
 ACRInitProgressSend = 22;
 ACRFindUserID = 23;
{$ENDIF}

 ACRZippedBuffer = 32;
 ACRConnect = 1;
// From Server
 ACRConnected = 2;
// Both
 ACRNoAction = 0;
 ACRMessage = 3;
// ACRLastPacket: 7th bit = 1, i.e. byte = x1xxxxxx, i.e. code >= 64
 ACRLastPacket = 64;
 ACREcho = 4;
 ACRTunning = 5;
 ACRServerSessionTunning = 6;
 ACRPing = 7;
 ACRLogon = 8;
 ACRLogoff = 9;
// single packet:
 ACRAllPacketsReceived = -1;
 ACRPacketResendRequest = -2;
 ACRMessageReceived = -3;
 ACRMessagePacketResendRequest = -4;
 ACRMessageAbort = -5;
 ACRDisconnect = -55;

{******************************************************************************}


{******************************************************************************}
// Sending Status - Fof Commands and Messages
{******************************************************************************}
  ACRNotSent = 0;
  ACRSent = -1;
{******************************************************************************}

{******************************************************************************}
// Receiving Status
{******************************************************************************}
 ACRNo = 0;       // no received packets
 ACRStart = 1;    // at least one packet received
 ACRNotFull = 2;  // last packte received, but not all the packets -- needs to request for resending
 ACRFull = -1;    // all the packets received
{******************************************************************************}

{******************************************************************************}
// Session Control Codes
{******************************************************************************}
 ACRExecute = 0;
 ACRSuspend = 1;
 ACRTerminate = -1;
{******************************************************************************}


{******************************************************************************}
// Session Status
{******************************************************************************}
 ACRVacant = 0;
 ACRInUse = 1; // all positive values mean 'in use'
{******************************************************************************}

{******************************************************************************}
// Message Status
{******************************************************************************}
 ACRNotFound  = 0;
 ACRSending   = 1;
 ACRSendOK    = 2; // sent
 ACRReceiving = 3;
 ACRReceived  = 4; // all the packets are received
{******************************************************************************}

 ACRNoResending = 999;

{******************************************************************************}


////////////////////////////////////////////////////////////////////////////////
// Error Codes
////////////////////////////////////////////////////////////////////////////////

{******************************************************************************}
// location
{******************************************************************************}
  // both client amd server - BaseConnectionManager
  ACRSendingThread =                      60;

  // client
  ACRClientPacketProcessorThread =        70;
  ACRClientResendRequestThread =          71;
  ACRClienTACRResendRequestThread =       72;
  ACRClientSendThread =                   73;
  ACRClientPacketProcessorThreadCommand = 74;
  ACRClientCommandProcessorThread =       75;
  ACRClientMesssageProcessorThread =      76;

  ACRClientConnectionManager =            79;

  // server
  ACRServerListenerThread =          80;
  ACRServerResendRequestThread =     81;
  ACRServerMsgResendRequestThread =  82;
  ACRServerSessionThread =           83;
  ACRServerSessionMsgThread =        84;
  ACRServerSessionDisconnectThread = 85;
  ACRServerSessionTerminatorThread = 86;
  ACRServerPingClientsThread =       87;
  ACRServerSessionMsgThreadHang =    88;
  ACRServerEventsThread =            89;

  ACRServerTerminateCommandThreads = 90;
  ACRServerTerminateMessageThreads = 91;

  ACRServerDeleteSession           = 92;

  ACRServerConnectionManager =       99;

  ACRServerError =                  100;

{******************************************************************************}
// functions
{******************************************************************************}
  // client
  ACRClntEchoRecv = 1;
  ACRClntEchoSend = 2;
  ACRClntEchoDND  = 3;
  ACRClntRecvDND  = 4;
  ACRClntMsgDND   = 5;

  // server
  ACRSrvrRecv     = 31;
  ACRSrvrRecvDND  = 32;
  ACRSrvrEchoSend = 33;
  ACRSrvrEchoDND  = 34;
  ACRSrvrMsgRecv  = 35;
  ACRSrvrMsgDND   = 36;



////////////////////////////////////////////////////////////////////////////////
// To avoid multiple realloc
////////////////////////////////////////////////////////////////////////////////

 ACRDefaultPacketsInAnswer = 8;
 ACRDefaultPacketsInRequest = 2;
 ACRDefaultMsgPackets = 1;

// Signatures
{$IFDEF MsgCommunicator}
 ACRClientPacketSign = 'MCM1';
 ACRServerPacketSign = 'MCM2';
{$ELSE}
 ACRClientPacketSign = 'ADS1';
 ACRServerPacketSign = 'ADS2';
{$ENDIF}

{$IFDEF PACKET_RESEND_REQUEST}
const
  ACR_Max_PacketID = 65535;
type
  TACRPacketID = Word;
{$ENDIF}

type

  PThread = ^TThread;

  TACRSessionsArray = array of TACRBaseSession;

  TACRNetwork = class;
  TACRBaseConnectionManager = class;
  TACRQueueProcessorThread = class;
  TACRResendRequestThread = class;
{$IFDEF CLIENT_VERSION}
  TACRClientConnectionManager = class;
  TACRClientResendRequestThread = class;
//  TACRClienTACRResendRequestThread = class;
  TACRClientPacketProcessorThread = class;
{$ENDIF}
{$IFDEF SERVER_VERSION}
  TACRServerConnectionManager = class;
  TACRServerSessionThread = class;
  TACRServerSessionMsgThread = class;
  TACRServerSessionDisconnectThread = class;
  TACRServerResendRequestThread = class;
  TACRServerMsgResendRequestThread = class;
  TACRServerListenerThread = class;
{$ENDIF}

  TACRControlCode = ShortInt;
  TACRNetworkClientID = Integer;
  TACRConnectionID = Integer;

  TACRPacketHeader = packed record
    CheckSum:           Cardinal;
    Signature:          array [0..3] of AnsiChar;
    Recepient:          TACRNetworkClientID;
    Sender:             TACRNetworkClientID;
    ConnectionID:       TACRConnectionID;
    SessionID:          TACRSessionID;
    CurrentRequestID:   Integer;
    PacketID:           Integer;
    ControlCode:        TACRControlCode;
  end;
  PACRPacketHeader = ^TACRPacketHeader;

  TACRPacket = packed record
    Buffer:             PAnsiChar;
    BufferSize:         Integer;
  end;
  PACRPacket = ^TACRPacket;

  TACRNetworkPacket = packed record
    Network:            TACRNetwork;
    FromHost:           AnsiString;
    FromPort:           Integer;
    Packet:             PACRPacket;
  end;
  PACRNetworkPacket = ^TACRNetworkPacket;

  TACRConnectionParams = packed record
    PacketSize:                   Integer;
    UseServerSettings:            Boolean;
    CompressionAlgorithm:         Byte;
    CompressionMode:              Byte;
    Protocol:                     Byte;
  end;
  PACRConnectionParams = ^TACRConnectionParams;

  TACRRecvItem = record
    Session:                Pointer; // PACRClntSession
    RecvStatus:             Integer; // ACRNo, ACRStart, ACRNotFull, ACRFull
    Network:                TACRNetwork;
    RemotePort:             Integer;
    RemoteHost:             AnsiString;
    Packets:                TACRThreadList; // list of TACRPacket
  end;
  PACRRecvItem = ^TACRRecvItem;

  TACRCommand = TACRRecvItem;
  PACRCommand = ^TACRRecvItem;

  TACRMessage = TACRRecvItem;
  PACRMessage = ^TACRRecvItem;

  TACRMessageStatus = record
    Status:                 Integer; //  ACRNotFound,
                                     //  ACRSending, ACRSendOK,
                                     //  ACRReceiving, ACRReceived
    MessageID:              Integer;
    NetworkClientID:        TACRNetworkClientID; // sender for receiving, recepient for sending
    ConnectionID:           TACRConnectionID;
    SessionID:              TACRSessionID;
    PacketIDsToResend:      TACRIntegerArray;
  end;
  PACRMessageStatus = ^TACRMessageStatus;

{$IFDEF CLIENT_VERSION}
  TACRClntSession = record
    FCSect:                 TRTLCriticalSection;
    Session:                TACRBaseSession;
    ServerSessionID:        TACRSessionID;
    CurrentRequestID:       Integer;
    ConnectionID:           TACRConnectionID;
    RemoteConnectionID:     TACRConnectionID;
    AnswerTime:             Cardinal;
    AnswerStatus:           Integer;
    MsgSendStatus:          Integer;
    SendStatus:             Integer;
    ClientMessageID:        Integer;
//    ServerMessageID:        Integer;
    ResendRequestThread:    TACRThread;
    PacketIDsToResend:      TACRThreadIntArray;
    MsgPacketIDsToResend:   TACRThreadIntArray;
    Packets:                TACRList;
    Status:                 Integer;  // inc before FCSect enters to prevent session deleting while it will be used
    ControlCode:            Shortint;  // ACRExecute, ACRTerminate
  end;
  PACRClntSession = ^TACRClntSession;

  TACRClntConnection = packed record
    ConnectionID:       TACRConnectionID;
    Network:            TACRNetwork;
  end;
  PACRClntConnection = ^TACRClntConnection;
{$ENDIF}

{$IFDEF SERVER_VERSION}
  TACRSrvrSession = packed record
    FCSect:                       TRTLCriticalSection;
    Session:                      TACRBaseSession;
    Network:                      TACRNetwork;
    CurrentRequestID:             Integer;
    Packets:                      TACRThreadList; // can be TACRList
    ReceiveStatus:                Shortint;               // for ReceiveBuffer
    SendStatus:                   Shortint;               // for SendBuffer
    MsgReceiveStatus:             Shortint;
    MsgSendStatus:                Shortint;
    PacketIDsToResend:            TACRThreadIntArray;
    ClientMessageID:              Integer;
    ServerMessageID:              Integer;
    MsgQueue:                     TACRThreadList;            // List of MsgPackets
    MsgPackets:                   TACRThreadList; // incoming packets, can be TACRList
    MsgReceivedPackets:           TACRThreadList; // packets to receive buffer, can be TACRList
    MsgPacketIDsToResend:         TACRThreadIntArray;
    ClientSessionID:              TACRSessionID;
    ConnectionID:                 TACRConnectionID;
    RemoteClientID:               TACRNetworkClientID;
    RemoteHost:                   AnsiString;
    RemotePort:                   Integer;
    Application:                  AnsiString;
    Thread:                       TACRServerSessionThread;
    MsgThread:                    TACRServerSessionMsgThread;
    MsgThreadCount:               Integer;
    DisconnectThread:             TACRServerSessionDisconnectThread;
    AnswerTime:                   Cardinal;
    LastSendPingTime:             Cardinal;
    LastReceivePingTime:          Cardinal;
    ContactCount:                 Integer; // number of contacts of this user
    Connected:                    Boolean; // used in Ping thread to avoid sending to non-specified remote address
    ControlCode:                  Shortint;
    MsgControlCode:               Shortint;
    Status:                       Shortint;
  end;

  PACRSrvrSession = ^TACRSrvrSession;
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TACRNetwork
//
////////////////////////////////////////////////////////////////////////////////

  TACRNetwork = class (TObject)
   private
    FCSect:               TRTLCriticalSection;
    FManager:             TACRBaseConnectionManager;
    FLocalClient:         TACRNetworkClientID;
    FProtocol:            Integer;
{$IFNDEF API_NETWORK}
    FLocalHost:           AnsiString;
    FRemoteHost:          AnsiString;
    FRemotePort:          Integer;
{$ENDIF API_NETWORK}
    function RndClientID: TACRNetworkClientID;
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
    FACRNetwork:          TACRapiNetwork;
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
    constructor Create(ConnectionManager: TACRBaseConnectionManager;
                       Protocol: Integer = ACR_UDP
                       );
    destructor Destroy; override;
    procedure SendBuffer(
                          Buffer: PAnsiChar;
                          Count:       Integer;
                          aSocket:     Integer = 0;
                          aRemoteHost: AnsiString = '###';
                          aRemotePort: Integer = 0
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
    property Protocol: Integer read FProtocol write FProtocol;
    property RemoteHost: AnsiString read GetRemoteHost write SetRemoteHost;
    property RemotePort: Integer read GetRemotePort write SetRemotePort;
    property LocalHost: AnsiString read GetLocalHost write SetLocalHost;
    property LocalPort: Integer read GetLocalPort write SetLocalPort;
    property LocalClientID: Integer read FLocalClient write FLocalClient;
    property PacketSize: Integer read GetPacketSize write SetPacketSize;
  end; // TACRNetwork



////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

  TACRBaseConnectionManager = class (TObject)
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
    FSessionID:             TACRSessionID;
    FListenerStoped:        Boolean;
    FMaxThreadCount:              Integer;
    FReceiveTimeOut:              Integer;
    FPacketQueue:                 TACRThreadList;
    FMessageQueue:                TACRThreadList; // list of PACRRecvItem
    FSendMessages:                TACRThreadList; // list of PACRSendMessageStatus
    FRecvMessages:                TACRThreadList; // list of PACRRecvMessageStatus
    FPacketProcessorThread:       TACRClientPacketProcessorThread;
    FCommandProcessorThread:      TACRQueueProcessorThread;
    FMessageProcessorThread:      TACRQueueProcessorThread;
    FCommandResendRequestThread:  TACRResendRequestThread;
    FMessageResendRequestThread:  TACRResendRequestThread;
    FCommandThreads:              TACRThreadList;
    FMessageThreads:              TACRThreadList;
    FSendingThreads:              TACRThreadList;
   public
    FSessions:              TACRThreadList;
    FThreadCount:           Integer;
   protected
    procedure FreePackets(Packets: TACRThreadList);
    procedure PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TACRNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False
                                 ); virtual; abstract;
    function MessageStatus(
                        Header:                 PACRPacketHeader;
                        Messages:               TACRThreadList
                            ): Integer;
    function FindMessageInQueue(Header: PACRPacketHeader): PACRRecvItem;
    function FindMessage(
                        Messages:               TACRThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TACRNetworkClientID;
                        ConnectionID:           TACRConnectionID;
                        SessionID:              TACRSessionID
                                               ): PACRMessageStatus;
    function SetMessageStatus(
                        Messages:               TACRThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TACRNetworkClientID;
                        ConnectionID:           TACRConnectionID;
                        SessionID:              TACRSessionID;
                        NewStatus:              Integer
                                               ): Boolean;
    procedure IncThreadCount(Ignore: Boolean = False);
    procedure DecThreadCount(Ignore: Boolean = False);
    procedure SetThreadCount(Value: Integer);
    procedure NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); virtual; abstract;
    procedure OnDisconnect(
                               FNetwork:      TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); virtual; abstract;
    procedure CompressAndEncryptBuffer(
                        Session:              TACRBaseSession;
                        InBuffer:             PAnsiChar;
                        InBufferSize:         Integer;
                        var OutBuffer:        PAnsiChar;
                        var OutBufferSize:    Integer
                                        );
    function DecompressAndDecryptBuffer(
                        Session:              TACRBaseSession;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                        ): Boolean;
    procedure WaitForThread(
                          Thread:        PThread;
                          TimeOut:       Cardinal;
                          SleepTime:     Cardinal = 1
                            );
    procedure GetBufferFromPackets(
                        Packets:        TACRThreadList;
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
                          WaitTimeOut:   Cardinal = ACRServerThreadsTerminateDelay;
                          SleepTime:     Cardinal = 1
                                      ): Boolean;
    procedure CloseThreads(ThreadList:    TACRThreadList;
                           ErrObject:     AnsiString;
                           WaitTimeOut:   Cardinal = ACRServerThreadsTerminateDelay
                           );
    property ThreadCount: Integer read FThreadCount write SetThreadCount;
  end; // TACRBaseConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TACRResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////
  TACRResendRequestThread = class(TACRThread)
  private
    FManager:           TACRBaseConnectionManager;
    FQueue:             TACRThreadList;
    FCommand:           Boolean;
    FClient:            Boolean;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TACRBaseConnectionManager;
                       Queue:             TACRThreadList;
                       Command:           Boolean = True
                       );
    destructor Destroy; override;
  end;// TACRResendRequestThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRClientConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

{$IFDEF CLIENT_VERSION}
  TACRClientConnectionManager = class (TACRBaseConnectionManager)
   private
    FConnections:                 TACRThreadList;
    FConnectionID:                TACRConnectionID;
    FApplication:                 AnsiString;
   protected
    function IsSessionExisting(ClientSession: PACRClntSession): Boolean;
    procedure PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TACRNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False
                                 );
    procedure SendConnectRequest(ClientSession: PACRClntSession);
    procedure SendDisconnectRequest(ClientSession: PACRClntSession;
                                    WaitForAnswer: Boolean = True);
    procedure SendPing(ClientSession: PACRClntSession);
    procedure SendAcknowledgement(ClientSession: PACRClntSession;
                                  Msg:           Boolean = False;
                                  CurrentRequestID:     Integer = -1
                                  );
{$IFDEF MsgCommunicator}
    function IsAuthorizationBufferValid(
                      CryptoInfo: TACRCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
    procedure SendConnectAckn(
                          ClientSession:        PACRClntSession;
                          ClientConnection:     PACRClntConnection;
                          CurrentRequestID:     Integer = -1
                              );
{$ENDIF MsgCommunicator}
    procedure DoDisconnect(Session: TACRBaseSession);
    procedure DeleteSession(ClientSession: PACRClntSession);
    procedure OnDisconnect(
                               FNetwork:      TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
//    function IsExistingPacket: Boolean;
    procedure NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
    procedure WaitForSendingThreads(Session: TACRNetworkSession);
    procedure DoSendBuffer(
                          ClientSession:    PACRClntSession;
                          ClientConnection: PACRClntConnection;
                          Buffer:           PAnsiChar;
                          BufferSize:       Integer;
                          Code:             Integer = ACRNewRequest
                         );
    // if encryption algorithm <> acr_Cipher_None then allocate buffer, fill it and return size
    // otherwise return BufferSize = 0
    procedure CreateAuthorizationBuffer(
                          CryptoInfo:     TACRCryptoInfo;
                          out Buffer:     PAnsiChar;
                          out BufferSize: Integer
                                        );
   public
    constructor Create;
    destructor Destroy; override;
    procedure TuneConnectionParamaters(ClientSession:  PACRClntSession);
    procedure Connect(Session: TACRBaseSession;
                          ListenOnly: Boolean = False;
                          Tune: Boolean = True
                          );
    procedure Disconnect(Session: TACRBaseSession; ListenOnly: Boolean = False);
    procedure DisconnectAll;
    procedure SendBuffer(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = ACRNewRequest
                          );
    procedure ReceiveBuffer(
                          Session:        TACRBaseSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer;
                          Connecting:     Boolean = False
                          );
    procedure SendMessage(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TACRControlCode = ACRMessage
                          );
(*
    procedure ReceiveMessage(
                          ClientSession:  PACRClntSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
*)
  end; // TACRClientConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TACRClientPacketProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRClientPacketProcessorThread = class(TACRThread)
  private
    FManager:       TACRClientConnectionManager;
    Error:          AnsiString;
    ClientSession:  PACRClntSession;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:       TACRClientConnectionManager
                       );
    destructor Destroy; override;
  end;// TACRClientPacketProcessorThread


////////////////////////////////////////////////////////////////////////////////
//
// TACRQueueProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRQueueProcessorThread = class(TACRThread)
  private
    FManager:           TACRBaseConnectionManager;
    FQueue:             TACRThreadList;
    FCommand:           Boolean;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    ThreadsCount:       Integer;
    MaxThreads:         Integer;
    constructor Create(
                        Manager:        TACRBaseConnectionManager;
                        Queue:          TACRThreadList;
                        Command:        Boolean = True;
                        MaxThreadCount: Integer = ACRMaxThreadCount
                       );
    destructor Destroy; override;
  end;// TACRQueueProcessorThread


////////////////////////////////////////////////////////////////////////////////
//
// TACRMessageThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRMessageThread = class(TACRThread)
  private
    FManager:           TACRBaseConnectionManager;
    FMsg:               PACRRecvItem;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                        Manager:        TACRBaseConnectionManager;
                        Msg:            PACRRecvItem
                       );
    destructor Destroy; override;
  end;// TACRMessageThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRSendingThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRSendingThread = class(TACRThread)
  private
    FSession:                       TACRNetworkSession;
    FManager:                       TACRBaseConnectionManager;
    FMethod:                        Pointer;
    Farg1,Farg2,Farg3,Farg4,Farg5:  Integer;
    Error:                          AnsiString;
  protected
{$IFDEF MsgCommunicator}
    procedure Connect(
                                NetworkPacket:        PACRNetworkPacket
                      );
    procedure ExecuteReceivedCommand(
                                ClientSession:        PACRClntSession;
                                Command:              Integer
                      );

{$ENDIF}
    procedure Echo;
    procedure Execute; override;
  public
    constructor Create(
                          Session:    TACRNetworkSession;
                          Manager:    TACRBaseConnectionManager;
                          Method:     Pointer;
                          arg1,arg2,arg3,arg4,arg5: Integer
                       );
    destructor Destroy; override;
  end;// TACRSendingThread


(*
////////////////////////////////////////////////////////////////////////////////
//
// TACRCommandProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRCommandProcessorThread = class(TACRThread)
  private
    FManager:       TACRClientConnectionManager;
    Error:          AnsiString;
  protected
    procedure Execute; override;
{$IFDEF MsgCommunicator}
    procedure CommandReceived;
{$ENDIF}
  public
    MaxThreads:        Integer;
    constructor Create(
                       Manager:       TACRBaseConnectionManager
                       );
    destructor Destroy; override;
  end;// TACRCommandProcessorThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRMessageProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRMessageProcessorThread = class(TACRThread)
  private
    FManager:       TACRClientConnectionManager;
    Error:          AnsiString;
  protected
    procedure Execute; override;
{$IFDEF MsgCommunicator}
    procedure MessageReceived;
{$ENDIF}
  public
    constructor Create(
                       Manager:       TACRBaseConnectionManager
                       );
    destructor Destroy; override;
  end;// TACRMessageProcessorThread
*)


////////////////////////////////////////////////////////////////////////////////
//
// TACRClientResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRClientResendRequestThread = class(TACRThread)
  private
    FManager:           TACRClientConnectionManager;
    FClientSession:     PACRClntSession;
    FBuffer:            PAnsiChar;
    FNetwork:           TACRNetwork;
    FHost:              AnsiString;
    FPort:              Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TACRClientConnectionManager;
                       ClientSession:     PACRClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TACRNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                       );
    destructor Destroy; override;
  end;// TACRClientResendRequestThread


(*
////////////////////////////////////////////////////////////////////////////////
//
// TACRClienTACRResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRClienTACRResendRequestThread = class(TACRThread)
  private
    FManager:           TACRClientConnectionManager;
    FClientSession:     PACRClntSession;
    FBuffer:            PAnsiChar;
    FNetwork:           TACRNetwork;
    FHost:              AnsiString;
    FPort:              Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TACRClientConnectionManager;
                       ClientSession:     PACRClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TACRNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                       );
    destructor Destroy; override;
  end;// TACRClienTACRResendRequestThread
*)
{$ENDIF} // Client



{$IFDEF SERVER_VERSION} // Server

////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionTerminatorThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerSessionTerminatorThread = class(TACRThread)
  private
    FManager:                 TACRServerConnectionManager;
    FTerminatedSessions:      TACRThreadList;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TACRServerConnectionManager
                       );
    destructor Destroy; override;
  public
  end;// TACRServerSessionThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerPingClientsThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerPingClientsThread = class(TACRThread)
  private
    FManager:                 TACRServerConnectionManager;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TACRServerConnectionManager
                       );
    destructor Destroy; override;
  public
  end;// TACRServerPingClientsThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerConnectionManager
//
////////////////////////////////////////////////////////////////////////////////


  TACRServerConnectionManager = class (TACRBaseConnectionManager)
   private
    FActive:                Boolean;
    FMaxMsgThreadCount:     Integer;
    FIncomingPackets:       TACRThreadList;
    ListenerThread:         TACRServerListenerThread;
    ResendRequestThread:    TACRServerResendRequestThread;
    MsgResendRequestThread: TACRServerMsgResendRequestThread;
    SessionTerminator:      TACRServerSessionTerminatorThread;
    PingClientsThread:      TACRServerPingClientsThread;
    FTerminatedSessions:    TACRThreadList;
    FProtocol:              TACRServerProtocol;
    FDisconnectThreads:     TACRThreadList;
//    FCommandQueue:                TACRThreadList; // list of PACRRecvItem
//    FCommandResendRequestThread:  TACRResendRequestThread;
   public
    FNetwork:           TACRNetwork;
    FNetworkTCP:        TACRNetwork;
//    property Network: TACRNetwork read FNetwork write FNetwork;
   protected
    function SessionsCount: Integer;
    function IsSessionTerminated(ClientSession: Pointer): Boolean;
    procedure TerminateAllSessionThreads(ServerSession: PACRSrvrSession);
    procedure TerminateMessageThreads(ServerSession: PACRSrvrSession);
    procedure TerminateCommandThreads(ServerSession: PACRSrvrSession);
    procedure EnableNextCommand(ServerSession: PACRSrvrSession);
    procedure PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TACRNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False;
                               Packets:       TACRThreadList = nil
                                 );
    procedure DeleteSession(ServerSession: PACRSrvrSession;
                            SkipServerSessionTermination: Boolean = False;
                            SaveMessages: Boolean = True
                            );
    procedure DoDisconnect(Session: TACRBaseSession;
                           SkipServerSessionTermination: Boolean = False);
    procedure DoSendBuffer(
                          ServerSession:    PACRSrvrSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = ACRNoAction
                                                  );
    procedure SendDisconnectRequest(ServerSession: PACRSrvrSession;
                                    WaitForAnswer: Boolean = True;
                                    PTerminated: Pointer = nil
                                    );
    procedure SendConnectAckn(
                          ServerSession:        PACRSrvrSession;
                          CurrentRequestID:     Integer = -1
                              );
    procedure SendPing(ServerSession: PACRSrvrSession);
    procedure SendAcknowledgement(
                          ServerSession:        PACRSrvrSession;
                          Msg:                  Boolean = False;
                          CurrentRequestID:     Integer = -1
                              );
    procedure OnDisconnect(
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
    procedure NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              ); override;
    procedure WaitForServerSessionThread(
                 ServerSession:    PACRSrvrSession;
                 TimeOut:          Cardinal = ACRWaitForServerSessionThreadTimeOut
                                          );
    procedure WaitForServerSessionMsgThread(
                 ServerSession:    PACRSrvrSession;
                 TimeOut:          Cardinal = ACRWaitForServerSessionThreadTimeOut
                                          );
    procedure CommandReceived(
                          ServerSession:    PACRSrvrSession;
                          ControlCode:      TACRControlCode;
                          CurrentRequestID: Integer
                              );
    procedure MessageReceived(
                               ServerSession:  PACRSrvrSession;
                               ControlCode:    TACRControlCode = ACRMessage
                              );
    // if authorization buffer is valid (encrypted by the same crypto settings as in CryptoInfo)
    // then return true else return false
    function IsAuthorizationBufferValid(
                          CryptoInfo: TACRCryptoInfo;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer
                                        ): Boolean;
   public
    constructor Create(Server: TComponent;
                       Protocol: TACRServerProtocol = acrsUDP
                       );
    destructor Destroy; override;
    // disconnect client by Host:Port
    procedure DisconnectClient(const Host: AnsiString; const Port: Integer); overload;
    // disconnect client by SessionID
    procedure DisconnectClient(const SessionID: Integer); overload;
   protected
    // disconnect session - internal
    procedure Disconnect(Session: TACRBaseSession; PTerminated: Pointer = nil);
   public
    procedure DisconnectAll(WaitForAllDisconnected: Boolean = True);
    procedure SendBuffer(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = ACRNoAction
                          );
    procedure ReceiveBuffer(
                          ServerSession:  PACRSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
    procedure SendMessage(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TACRControlCode = ACRMessage
                          );
    procedure ReceiveMessage(
                          ServerSession:  PACRSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
    function GetClientInfo(
                          Session:          TACRBaseSession;
                          var Protocol:     TACRClientProtocol;
                          var Host:         AnsiString;
                          var Port:         Integer;
                          var Application:  AnsiString
                            ): Boolean;
    // fill array with server session object connected to this server
    procedure GetClientsList(var Clients: TACRSessionsArray);
    procedure TerminateSession(Session: TACRBaseSession);
  end; // TACRClientConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerSessionThread = class(TACRThread)
  private
    FServerSession:           PACRSrvrSession;
    FManager:                 TACRServerConnectionManager;
    FCode:                    TACRControlCode;
{$IFDEF ClientCommand_Fix}
    FFinishing:               Boolean;
{$ENDIF}
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TACRServerConnectionManager;
                          ServerSession:    PACRSrvrSession;
                          Code:             Integer = ACRNoAction
                       );
    destructor Destroy; override;
  public
  end;// TACRServerSessionThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionMsgThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerSessionMsgThread = class(TACRThread)
  private
    FServerSession:           PACRSrvrSession;
    FManager:                 TACRServerConnectionManager;
    FCode:                    TACRControlCode;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TACRServerConnectionManager;
                          ServerSession:    PACRSrvrSession;
                          Code:             Integer = ACRMessage
                       );
    destructor Destroy; override;
  public
  end;// TACRServerSessionMsgThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionDisconnectThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerSessionDisconnectThread = class(TACRThread)
  private
    FServerSession:           PACRSrvrSession;
    FManager:                 TACRServerConnectionManager;
    FCurrentRequestID:        Integer;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                          Manager:          TACRServerConnectionManager;
                          ServerSession:    PACRSrvrSession;
                          CurrentRequestID: Integer = -1
                       );
    destructor Destroy; override;
  public
  end;// TACRServerSessionDisconnectThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerListenerThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerListenerThread = class(TACRThread)
  private
    FManager:       TACRServerConnectionManager;
    ServerSession:  PACRSrvrSession;
    SessionFound:   Boolean;
    Error:          AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:       TACRServerConnectionManager
                       );
    destructor Destroy; override;
  end;// TACRServerListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerResendRequestThread = class(TACRThread)
  private
    FManager:           TACRServerConnectionManager;
    Error:              AnsiString;
    FNeeded:            Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TACRServerConnectionManager
                       );
    destructor Destroy; override;
  end;// TACRServerResendRequestThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

  TACRServerMsgResendRequestThread = class(TACRThread)
  private
    FManager:           TACRServerConnectionManager;
    Error:              AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(
                       Manager:           TACRServerConnectionManager
                       );
    destructor Destroy; override;
  end;// TACRServerMsgResendRequestThread

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
                      CryptoInfo: TACRCryptoInfo;
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
  ACRServer,
{$ENDIF}
{IFDEF MsgCommunicator}
 {$IFDEF CLIENT_VERSION}
  ACRClient,
 {$ENDIF}
{ENDIF}
{$IFNDEF MsgCommunicator}
  ACRDECCRC,
{$ENDIF}
  ACRMain;

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
  Result := ACR_CRC32(0, buf, BufferSize-4);//ACR_CRC32(555, buf, BufferSize-4);
end;



////////////////////////////////////////////////////////////////////////////////
//
// TACRNetwork
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// CreateNetwork
//------------------------------------------------------------------------------
procedure TACRNetwork.CreateNetwork;
begin
{$IFDEF API_NETWORK}
  if FProtocol = ACR_UDP then
    FACRNetwork := TACRUDPSocket.Create(Self)
  else
  if FProtocol = ACR_TCP then
    if FManager is TACRClientConnectionManager then
      FACRNetwork := TACRTCPClient.Create(Self)
    else
      FACRNetwork := TACRTCPServer.Create(Self);
  FACRNetwork.OnDataReceived := OnDataReceived;
  FACRNetwork.OnDisconnect := OnDisconnect;
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
procedure TACRNetwork.FreeNetwork;
begin
{$IFDEF API_NETWORK}
  if FACRNetwork <> nil then
   begin
    FACRNetwork.Recreate := False;
    FACRNetwork.Free;
    FACRNetwork := nil;
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
procedure TACRNetwork.ReCreateNetwork;
var
  lRemoteHost:       AnsiString;
  lLocalHost:        AnsiString;
  lRemotePort:       Integer;
  lLocalPort:        Integer;
  lPacketSize:       Integer;
begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> START');
{$ENDIF}
  EnterCSect(FCSect);
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> CS entered');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> RemoteHost="'+RemoteHost+'"');
{$ENDIF}
  lRemoteHost := RemoteHost;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> RemotePort='+IntToStr(RemotePort));
{$ENDIF}
  lRemotePort := RemotePort;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> LocalHost="'+LocalHost+'"');
{$ENDIF}
  lLocalHost := LocalHost;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> LocalPort='+IntToStr(LocalPort));
{$ENDIF}
  lLocalPort := LocalPort;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> Free...');
{$ENDIF}
  lPacketSize := PacketSize;
  FreeNetwork;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> Create...');
{$ENDIF}
  CreateNetwork;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> Set...');
{$ENDIF}
  LocalPort := lLocalPort;
  RemotePort := lRemotePort;
  RemoteHost := lRemoteHost;
  PacketSize := lPacketSize;
  LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.ReCreateNetwork> FINISH');
{$ENDIF}
end; // ReCreateNetwork


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRNetwork.Create(ConnectionManager: TACRBaseConnectionManager;
                               Protocol: Integer = ACR_UDP);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.Create');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}
  InitCSect(FCSect);
  inherited Create;
  FProtocol := Protocol;
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
destructor TACRNetwork.Destroy;
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.Destroy');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}
  EnterCSect(FCSect);
  try
   FreeNetwork;
   inherited Destroy;
  finally
   LeaveCSect(FCSect);
   DeleteCSect(FCSect);
  end;
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount));
aaWriteToLog('');
{$ENDIF}
end;// Destoy


//------------------------------------------------------------------------------
// RndClientID
//------------------------------------------------------------------------------
function TACRNetwork.RndClientID: TACRNetworkClientID;
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
procedure TACRNetwork.SetPacketSize(Size: Integer);
begin
{$IFDEF API_NETWORK}
  FACRNetwork.PacketSize := Size;
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetPacketSize
//------------------------------------------------------------------------------
function TACRNetwork.GetPacketSize: Integer;
begin
{$IFDEF API_NETWORK}
  Result := FACRNetwork.PacketSize;
{$ENDIF}
end;

//------------------------------------------------------------------------------
// SetRemoteHost
//------------------------------------------------------------------------------
procedure TACRNetwork.SetRemoteHost(Host: AnsiString);
begin
{$IFDEF API_NETWORK}
  FACRNetwork.RemoteHost := Host;
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
function TACRNetwork.GetRemoteHost: AnsiString;
begin
{$IFDEF API_NETWORK}
  Result := FACRNetwork.RemoteHost;
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
procedure TACRNetwork.SetRemotePort(Port: Integer);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.SetRemotePort');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  FACRNetwork.RemotePort := Port;
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
function TACRNetwork.GetRemotePort: Integer;
begin
{$IFDEF API_NETWORK}
  Result := FACRNetwork.RemotePort;
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
procedure TACRNetwork.SetLocalPort(Port: Integer);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.SetLocalPort');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  FACRNetwork.LocalPort := Port;
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
procedure TACRNetwork.SetLocalHost(Host: AnsiString);
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.SetLocalHost');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
  FACRNetwork.LocalHost := Host;
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
function TACRNetwork.GetLocalHost: AnsiString;
begin
{$IFDEF API_NETWORK}
  Result := FACRNetwork.LocalHost;
{$ELSE}
  Result := FLocalHost;
{$ENDIF}
end;


//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TACRNetwork.GetLocalPort: Integer;
begin
{$IFDEF API_NETWORK}
  Result := FACRNetwork.LocalPort;
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
procedure TACRNetwork.SendBuffer(
                          Buffer: PAnsiChar;
                          Count:  Integer;
                          aSocket:     Integer = 0;
                          aRemoteHost: AnsiString = '###';
                          aRemotePort: Integer = 0
                                );
var
  Header: PACRPacketHeader;
{$IFNDEF D6H}
  Buff: array [0..ACRMaxPacketSize] of AnsiChar;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
  buf: PAnsiChar;
  i: Integer;
{$ENDIF}
{$IFDEF NETWORK_TEST}
  Connections: TACRList;
  Connection:  PACRClntConnection;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_SHORT_PING}
  str: AnsiString;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
  str: AnsiString;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.SendBuffer');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

  Header := PACRPacketHeader(Buffer);
  Header.Sender := FLocalClient;
  Header.CheckSum := CheckSum(Buffer, Count);
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
if Protocol = ACR_UDP then
str := 'UDP:'
else
if Protocol = ACR_TCP then
str := 'TCP:'
else
if Protocol = ACR_HTTP then
str := 'HTTP:'
else
str := '';
if LocalPort = ACR_DefaultClientPort then
str := str + 'Client'
else
if (LocalPort = ACRDefaultServerPort)
or (LocalPort = ACRDefaultServerPortTCP)
then
str := str + 'Server'
else
str := str + IntToStr(LocalPort);
str := str + '>>> '
+IntToStr(Header.CurrentRequestID)+' : '
+IntToStr(Header.PacketID)+' / '
+IntToStr(Header.ControlCode)
+' >>> ';
if aRemotePort <> 0 then
 str := str+aRemoteHost+':'+IntToStr(aRemotePort)
else
 str := str+RemoteHost+':'+IntToStr(RemotePort);
{$IFDEF API_NETWORK}
str := str
+' - '+IntToStr(Count)+' bytes'
{$ENDIF}
//+' - '+IntToStr(GetTickCount)+' msec'
//+' <'+IntToStr(Header.Recepient)+'>'
;
aaWriteToLog(str, NetLog);
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK_SHORT_PING}
if Header.ControlCode = ACRPing then
begin
if Protocol = ACR_UDP then
str := 'UDP:'
else
if Protocol = ACR_TCP then
str := 'TCP:'
else
if Protocol = ACR_HTTP then
str := 'HTTP:'
else
str := '';
if LocalPort = ACR_DefaultClientPort then
str := str + 'Client'
else
if LocalPort = ACRDefaultServerPort then
str := str + 'Server'
else
str := str + IntToStr(LocalPort);
str := str + '>>> '
+IntToStr(Header.CurrentRequestID)+' : '
+IntToStr(Header.PacketID)+' / '
+IntToStr(Header.ControlCode)
+' >>> '+RemoteHost+':'+IntToStr(RemotePort)
+' - '+IntToStr(GetTickCount)+' msec'
//+' <'+IntToStr(Header.Recepient)+'>'
;
aaWriteToLog(str, Netlog);
end;
{$ENDIF}

{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------');
aaWriteToLog('ACRConnection>TACRNetwork.SendBuffer('+IntToHex(Integer(@Buffer),6)+', '+IntToStr(Count)+')');
aaWriteToLog('Sender    : '+IntToStr(FLocalClient));
aaWriteToLog('-----------');
aaWriteToLog('aSocket: '+IntToStr(aSocket));
aaWriteToLog('aRemoteHost: '+aRemoteHost);
aaWriteToLog('aRemotePort: '+IntToStr(aRemotePort));
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
buf:=MemoryManager.GetMem(Count-SizeOf(TACRPacketHeader)+1);
Move(PAnsiChar(Integer(Buffer)+SizeOf(TACRPacketHeader))^, buf^, Count-SizeOf(TACRPacketHeader));
for i:= 0 to Count-SizeOf(TACRPacketHeader)-1 do
  if (buf+i)^=#0 then
    (buf+i)^:='0';
(buf+Count-SizeOf(TACRPacketHeader))^:=#0;
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
   if Assigned(TACRServerConnectionManager(FManager.FOtherManager).FNetwork.OnDataReceived) then
    TACRServerConnectionManager(FManager.FOtherManager).FNetwork.OnDataReceived(Buffer, Count, LocalHost, LocalPort)
  else
   begin
    Connections:=TACRClientConnectionManager(FManager.FOtherManager).FConnections.LockList;
    try
     Connection := Connections.Items[0];
    finally
     TACRClientConnectionManager(FManager.FOtherManager).FConnections.UnlockList;
    end;
    Connection.Network.OnDataReceived(Buffer, Count, LocalHost, LocalPort);
   end;
{$ELSE}
 {$IFDEF API_NETWORK}
  FACRNetwork.SendBuffer(Buffer, Count, aSocket, aRemoteHost, aRemotePort);
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
procedure TACRNetwork.OnDisconnect(
                             FromHost:  AnsiString;
                             FromPort:  Integer;
                             Recv:      Boolean = False
                             );
begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> START - '+IntToStr(GetTickCount)+' msec');
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> socket error from '+FromHost+':'+IntToStr(FromPort));
if Recv then
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> recv error')
else
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> send error');
{$ENDIF}
 try
  if (FManager = nil)
  or FManager.FListenerStoped
  then
   begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> Manager not exist - FINISH');
{$ENDIF}
    Exit;
   end;
  ReCreateNetwork;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> FManager.OnDisconnect...');
{$ENDIF}
  if not Recv then
    FManager.OnDisconnect(self, FromHost, FromPort);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
    raise;
   end;
 end;
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('ACRConnection> TACRNetwork.OnDisconnect> FINISH');
{$ENDIF}
end;// OnDisconnect


//------------------------------------------------------------------------------
// OnDataReceived
//------------------------------------------------------------------------------
{$IFDEF API_NETWORK}
procedure TACRNetwork.OnDataReceived(
                             Buffer:    PAnsiChar;
                             Count:     Integer;
                             FromHost:  AnsiString;
                             FromPort:  Integer
                             );
{$ELSE}
 {$IFDEF D6H}
procedure TACRNetwork.OnDataReceived(
                             Sender:   TObject;
                             AData:    TStream;
                             ABinding: TIdSocketHandle
                             );
 {$ELSE}
procedure TACRNetwork.OnDataReceived(
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
  Buffer: array [0..ACRMaxPacketSize] of AnsiChar;
 {$ENDIF}
{$ENDIF}
  Header: PACRPacketHeader;
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
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaIncCounter;aaStartTime;try {$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog('TACRNetwork.OnDataReceived');
aaWriteToLog(IntToStr(gettickcount));
{$ENDIF}

{$IFDEF API_NETWORK}
{
if (PACRPacketHeader(Buffer).ControlCode <> (ACRConnect + ACRLastPacket))
and (PACRPacketHeader(Buffer).ControlCode <> (ACRConnected + ACRLastPacket))
and (PACRPacketHeader(Buffer).ControlCode <> (ACRAllPacketsReceived))
then Exit;
}
  if Count = 0 then
    Buf := nil
  else
   begin
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStartTime(time1);{$ENDIF}
    Buf := MemoryManager.GetMem(Count);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStopTime(time1);aaStartTime(time2);{$ENDIF}
    Move(Buffer^, Buf^, Count);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStopTime(time2);{$ENDIF}
   end;
  BufSize := Count;
{$ELSE}
 {$IFDEF D6H}
  Buf := MemoryManager.GetMem(ACRMaxPacketSize);
  BufSize := AData.Read(Buf^, ACRMaxPacketSize);
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
  Header := PACRPacketHeader(Buf);
{$IFDEF DEBUG_LOG_NETWORK_SHORT}
if Protocol = ACR_UDP then
str := 'UDP:'
else
if Protocol = ACR_TCP then
str := 'TCP:'
else
if Protocol = ACR_HTTP then
str := 'HTTP:'
else
str := '';
if LocalPort = ACR_DefaultClientPort then
str := str + 'Client'
else
if (LocalPort = ACRDefaultServerPort)
or (LocalPort = ACRDefaultServerPortTCP)
then
str := str + 'Server'
else
str := str + IntToStr(LocalPort);
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
if Protocol = ACR_UDP then
str := 'UDP:'
else
if Protocol = ACR_TCP then
str := 'TCP:'
else
if Protocol = ACR_HTTP then
str := 'HTTP:'
else
str := '';
if Header.ControlCode = ACRPing then
begin
if LocalPort = ACR_DefaultClientPort then
str := str + 'Client'
else
if LocalPort = ACRDefaultServerPort then
str := str + 'Server'
else
str := str + IntToStr(LocalPort);
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
aaWriteToLog('ACRConnection>TACRNetwork.OnDataReceived('+IntToHex(Integer(@Buf),6)+', '+IntToStr(BufSize)+')');
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
buff:=MemoryManager.GetMem(BufSize-SizeOf(TACRPacketHeader)+1);
Move(PAnsiChar(Integer(Buf)+SizeOf(TACRPacketHeader))^, buff^, BufSize-SizeOf(TACRPacketHeader));
for i:= 0 to BufSize-SizeOf(TACRPacketHeader)-1 do
  if (buff+i)^=#0 then
    (buff+i)^:='0';
(buff+BufSize-SizeOf(TACRPacketHeader))^:=#0;
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
      ((Header.ControlCode = ACRConnect) or (Header.ControlCode = ACRConnect+ACRLastPacket))
      and
      (Header.Signature = ACRClientPacketSign)
      )
{$ENDIF MsgCommunicator}
  then
  begin
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaIncCounter(counter3); aaStartTime(time3); try {$ENDIF}
{$IFDEF API_NETWORK}
    FManager.NetworkListener(Buf, BufSize, Self, FromHost, FromPort);
{$ELSE}
 {$IFDEF D6H}
    FManager.NetworkListener(Buf, BufSize, Self, FromHost, FromPort);
 {$ELSE}
    FManager.NetworkListener(Buf, BufSize, Self, FromIP, Port);
 {$ENDIF D6H}
{$ENDIF API_NETWORK}
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME} finally aaStopTime(time3); end;{$ENDIF}
  end;

{$IFDEF DEBUG_LOG_NETWORK_TIME}
aaWriteToLog(IntToStr(gettickcount)+' - end of parsing');
aaWriteToLog('');
{$ENDIF}
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME} finally aaStopTime; end;{$ENDIF}
end;
// TACRNetwork



////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

constructor TACRBaseConnectionManager.Create;
begin
  FMaxThreadCount := ACRMaxThreadCount;
  FSendingThreads := TACRThreadList.Create;
  inherited Create;
end;

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRBaseConnectionManager.Destroy;
begin
  CloseThreads(FSendingThreads,ErrorRSendingThread,100);
  inherited Destroy;
end;// Destroy

//------------------------------------------------------------------------------
// TACRBaseConnectionManager.IncThreadCount
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.IncThreadCount(Ignore: Boolean);
begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRBaseConnectionManager.IncThreadCount> START:  ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
  if not Ignore then
    EnterCSect(FCSect, false);
  FThreadCount := FThreadCount+1;
  if not Ignore then
    LeaveCSect(FCSect);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRBaseConnectionManager.IncThreadCount> FINISH: ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
end;// TACRBaseConnectionManager.IncThreadCount

//------------------------------------------------------------------------------
// TACRBaseConnectionManager.DecThreadCount
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.DecThreadCount(Ignore: Boolean);
begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRBaseConnectionManager.DecThreadCount> START:  ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
  if not Ignore then
    EnterCSect(FCSect, false);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRBaseConnectionManager.DecThreadCount> dec...');
{$ENDIF}
  FThreadCount := FThreadCount-1;
  if not Ignore then
    LeaveCSect(FCSect);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRBaseConnectionManager.DecThreadCount> FINISH: ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
end;// TACRBaseConnectionManager.DecThreadCount

//------------------------------------------------------------------------------
// TACRBaseConnectionManager.SetThreadCount
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.SetThreadCount(Value: Integer);
begin
  EnterCSect(FCSect, false);
  FThreadCount := Value;
  LeaveCSect(FCSect);
end;// TACRBaseConnectionManager.SetThreadCount


//------------------------------------------------------------------------------
// WaitForThread
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.WaitForThread(
                          Thread:        PThread;
                          TimeOut:       Cardinal;
                          SleepTime:     Cardinal = 1
                          );
var
  StartTime:      Cardinal;
begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.WaitForThread> TimeOut = '+IntToStr(TimeOut));
{$ENDIF}
  StartTime := GetTickCount;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.WaitForThread> Started at: '+IntToStr(StartTime));
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
aaWriteToLog('TACRBaseConnectionManager.WaitForThread> Thread Finished at: '+IntToStr(GetTickCount))
else
aaWriteToLog('TACRBaseConnectionManager.WaitForThread> Thread Not Finished! Timeout at: '+IntToStr(GetTickCount));
{$ENDIF}
end; // Wait for thread finish


//------------------------------------------------------------------------------
// CloseThread
//------------------------------------------------------------------------------
function TACRBaseConnectionManager.CloseThread(
                          Thread:        PThread;
                          ErrProcess:    Integer;
                          ErrObject:     AnsiString;
                          WaitTimeOut:   Cardinal = ACRServerThreadsTerminateDelay;
                          SleepTime:     Cardinal = 1
                                      ): Boolean;
var
  Error:          AnsiString;
begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> START');
{$ENDIF}
 try
  Result := False;
  if Thread^ = nil then
   begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Thread is not started - OK');
{$ENDIF}
    Result := True;
    Exit;
   end;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Ask to terminate Thread...');
{$ENDIF}
  // AskToTerminate
  if Thread^ is TACRThread then
    TACRThread(Thread^).FRecreate := false;
  Thread^.Terminate;
  WaitForThread(Thread, WaitTimeOut, SleepTime);
  if Thread^ = nil then
   begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Finished!');
{$ENDIF}
    Result := True;
    Exit;
   end
  else
   begin // ForceToTerminate
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Not Finished!');
{$ENDIF}
    if Self is TACRServerConnectionManager then
     begin
      Error:= ErrorRServer+ErrObject+IntToStr(Integer(Thread^.ThreadID))+'/'+IntToStr(Integer(Thread^.Handle))+ErrorRExecute;
      TACRServer(FServer).DoOnConnectionError(ErrProcess,40517,
                    Error+ErrorRCannotTerminateThread+IntToStr(WaitTimeOut));
     end;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Force to terminate Thread...');
{$ENDIF}
    try
     Result := TerminateThread(Thread^.Handle, 0);
     sleep(1);
    except
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('Exception in TerminateThread!');
{$ENDIF}
    end;
    if not Result then
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Not Terminated! - CloseThread failed');
{$ENDIF}
      if Self is TACRServerConnectionManager then
       begin
        TACRServer(FServer).DoOnConnectionError(ErrProcess,40518,
                    Error+'CloseThread failed - '+ErrorRCannotKillThread+IntToStr(GetLastError));
       end;
     end;
    if Thread^.Handle <> 0 then
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> CloseHandle...');
{$ENDIF}
      try
       Result := CloseHandle(Thread^.Handle);
       sleep(1);
      except
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('Exception in CloseHandle!');
{$ENDIF}
      end;
     end;
    if Result then
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> CloseHandle - ok');
{$ENDIF}
(*
      if Thread^ <> nil then
       begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> free...');
{$ENDIF}
        Thread^.Free;
        sleep(1);
       end;
*)
      Thread^ := nil;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> DecThreadCount...');
{$ENDIF}
      DecThreadCount(True);
     end
    else
     begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Not Terminated! - CloseHandle failed');
{$ENDIF}
      if Self is TACRServerConnectionManager then
       begin
        TACRServer(FServer).DoOnConnectionError(ErrProcess,40518,
                    Error+'CloseHandle failed - '+ErrorRCannotKillThread+IntToStr(GetLastError));
       end;
     end;
   end; // ForceToTerminate
 finally
{$IFDEF LOG_TERMINATE_THREAD}
if Result then
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Thread terminated successfully!')
else
aaWriteToLog('TACRBaseConnectionManager.CloseThread> Thread is not terminated!');
aaWriteToLog('TACRBaseConnectionManager.CloseThread> finished');
{$ENDIF}
 end;
end;


//------------------------------------------------------------------------------
// CloseThreads
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.CloseThreads(
                           ThreadList:    TACRThreadList;
                           ErrObject:     AnsiString;
                           WaitTimeOut:   Cardinal = ACRServerThreadsTerminateDelay
                                                );
var
  threads:      TACRList;
  i:            Integer;
  thread:       TACRThread;
begin
  if ThreadList = nil then
    Exit;
  threads := ThreadList.LockList;
  try
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThreads> START:  threads.Count = '+IntToStr(threads.Count));
{$ENDIF}
   for i:=threads.Count-1 downto 0 do
    begin
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThreads> Item # '+IntToStr(i));
{$ENDIF}
     thread := threads.Items[i];
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThreads> delete...');
{$ENDIF}
     threads.delete(i);
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThreads> close...');
{$ENDIF}
     CloseThread(@thread,ACRClientConnectionManager,ErrObject,WaitTimeOut);
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThreads> OK!');
{$ENDIF}
    end;
{$IFDEF LOG_TERMINATE_THREAD}
aaWriteToLog('TACRBaseConnectionManager.CloseThreads> FINISH: threads.Count = '+IntToStr(threads.Count));
{$ENDIF}
  finally
   ThreadList.UnlockList;
  end;
  ThreadList.Free;
end; // CloseThreads


//------------------------------------------------------------------------------
// GetBufferFromPackets
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.GetBufferFromPackets(
                        Packets:        TACRThreadList;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                                         );
var
  lPackets:     TACRList;
  Packet:       PACRPacket;
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
     BufferSize := BufferSize + Packet.BufferSize - SizeOf(TACRPacketHeader);
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
          size := Packet.BufferSize-SizeOf(TACRPacketHeader);
          if (size > 0) then
           begin
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> move...');
{$ENDIF}
            Move(Pointer(Packet.Buffer+SizeOf(TACRPacketHeader))^, pBuf^, size);
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> inc...');
{$ENDIF}
            inc(pBuf, size);
           end;
{$IFDEF LOG_GET_BUFFER}
aaWriteToLog('GetBufferFromPackets> inced'+IntToStr(Packet.BufferSize-SizeOf(TACRPacketHeader)));
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
procedure TACRBaseConnectionManager.CompressAndEncryptBuffer(
                        Session:              TACRBaseSession;
                        InBuffer:             PAnsiChar;
                        InBufferSize:         Integer;
                        var OutBuffer:        PAnsiChar;
                        var OutBufferSize:    Integer
                                                              );
begin
 try
  ACRBaseEngine.CompressAndEncryptBuffer(Session.ConnectParams.CryptoInfo,
                                         Session.ConnectParams.CompressionAlgorithm,
                                         Session.ConnectParams.CompressionMode,
                                         InBuffer,  InBufferSize,
                                         OutBuffer, OutBufferSize);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> CompressAndEncryptBuffer - Error:');
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
function TACRBaseConnectionManager.DecompressAndDecryptBuffer(
                        Session:              TACRBaseSession;
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
  Result := ACRBaseEngine.DecompressAndDecryptBuffer(
                                Session.ConnectParams.CryptoInfo,
                                Session.ConnectParams.CompressionAlgorithm,
                                Session.ConnectParams.CompressionMode,
                                Buffer,
                                BufferSize);
 except
  on E: Exception do
   begin
    Result := False;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> DecompressAndDecryptBuffer - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
   end;
 end;
end; // DecompressAndDecryptBuffer


//------------------------------------------------------------------------------
// FreePackets
//------------------------------------------------------------------------------
procedure TACRBaseConnectionManager.FreePackets(Packets: TACRThreadList);
var
  PacketsList:  TACRList;
  Packet:       PACRPacket;
  i:            Integer;
begin
 PacketsList := Packets.LockList;
 try
  for i:= 0 to PacketsList.Count-1 do
   begin
    Packet := PACRPacket(PacketsList.Items[i]);
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
function TACRBaseConnectionManager.MessageStatus(
                        Header:                 PACRPacketHeader;
                        Messages:               TACRThreadList
                            ): Integer;
var
  msgStatus:  PACRMessageStatus;
begin
  Result := ACRNotFound;
  msgStatus := FindMessage(Messages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
  if (msgStatus <> nil) then
    Result := msgStatus.Status;
end; // MessageStatus


//------------------------------------------------------------------------------
// FindMessageInQueue
//------------------------------------------------------------------------------
function TACRBaseConnectionManager.FindMessageInQueue(Header: PACRPacketHeader): PACRRecvItem;
var
  msg:        PACRRecvItem;
  packets,
  messages:   TACRList;
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
         if PACRPacket(msg.Packets.Items[j]).Buffer <> nil then
         if PACRPacket(msg.Packets.Items[j]).BufferSize >= SizeOf(TACRPacketHeader) then
          begin
           if CompareMem(PACRPacket(msg.Packets.Items[j]).Buffer+SizeOf(Cardinal),
                         PChar(Header)+SizeOf(Cardinal), // exclude CRC
                         SizeOf(TACRPacketHeader)
                         -SizeOf(Integer)-SizeOf(TACRControlCode) // exclude PacketID and ControlCode
                         -SizeOf(Cardinal)) then
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
function TACRBaseConnectionManager.FindMessage(
                        Messages:               TACRThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TACRNetworkClientID;
                        ConnectionID:           TACRConnectionID;
                        SessionID:              TACRSessionID
                                               ): PACRMessageStatus;
var
  msgStatus:  PACRMessageStatus;
  msgs:       TACRList;
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
function TACRBaseConnectionManager.SetMessageStatus(
                        Messages:               TACRThreadList;
                        MessageID:              Integer;
                        NetworkClientID:        TACRNetworkClientID;
                        ConnectionID:           TACRConnectionID;
                        SessionID:              TACRSessionID;
                        NewStatus:              Integer
                                               ): Boolean;
var
  msgStatus:  PACRMessageStatus;
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
// TACRQueueProcessorThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRQueueProcessorThread.Create(
                        Manager:        TACRBaseConnectionManager;
                        Queue:          TACRThreadList;
                        Command:        Boolean = True;
                        MaxThreadCount: Integer = ACRMaxThreadCount
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
destructor TACRQueueProcessorThread.Destroy;
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
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
    if FCommand then
      FManager.FCommandProcessorThread := TACRQueueProcessorThread.Create(FManager,FQueue,FCommand,ThreadsCount)
    else
      FManager.FMessageProcessorThread := TACRQueueProcessorThread.Create(FManager,FQueue,FCommand,ThreadsCount);
   end;
end;
end; // Destroy


//------------------------------------------------------------------------------
// TACRQueueProcessorThread.Execute
//------------------------------------------------------------------------------
procedure TACRQueueProcessorThread.Execute;
var
  i,
  SleepTime:      Integer;
  Queue:          TACRList;
  RecvItem:       PACRRecvItem;
  Thread:         TACRThread;
begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> START - '+IntToStr(GetTickCount));
{$ENDIF}
try
 i := 0;
 SleepTime := 1;
 repeat
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
//aaWriteToLog('TACRQueueProcessorThread.Execute> sleep('+IntToStr(SleepTime)+')...');
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
aaWriteToLog('TACRQueueProcessorThread.Execute> termination signal ignored to process all the messages in queue!');
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
aaWriteToLog('TACRQueueProcessorThread> Queue.Count = '+IntToStr(Queue.Count));
aaWriteToLog('TACRQueueProcessorThread> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> get item...');
{$ENDIF}
    RecvItem := Queue.Items[i];
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
   finally
    FQueue.UnlockList;
   end;
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRMessageThread> Status = '+IntToStr(PACRClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PACRClntSession(RecvItem.Session)),8));
aaWriteToLog('TACRQueueProcessorThread.Execute> is session existing...');
{$ENDIF}
   if not TACRClientConnectionManager(FManager).IsSessionExisting(PACRClntSession(RecvItem.Session)) then
    begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> session terminated');
{$ENDIF}
     FQueue.Delete(i);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> session terminated, deleted RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
     Continue;
    end
   else // session exists
    if RecvItem.RecvStatus = ACRFull then
     begin
      FQueue.Delete(i);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> is full, deleted RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
     end
    else // not full
     begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> Status = '+IntToStr(PACRClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PACRClntSession(RecvItem.Session)),8));
{$ENDIF}
      dec(PACRClntSession(RecvItem.Session).Status);
      LeaveCSect(PACRClntSession(RecvItem.Session).FCSect);
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> dec in-use counter, Status = '+IntToStr(PACRClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PACRClntSession(RecvItem.Session)),8));
aaWriteToLog('TACRQueueProcessorThread.Execute> i='+IntToStr(i)+', inc...');
{$ENDIF}
      inc(i); // try next item
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> inced!');
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> not full, get next item # '+IntToStr(i));
{$ENDIF}
      Continue;
     end;
   try // session entered CSect
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> full buffer');
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
aaWriteToLog('TACRQueueProcessorThread.Execute> command');
{$ENDIF}
//        TACRThread(TACRCommandThread.Create(FManager,RecvItem));
     end
    else
     begin
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRQueueProcessorThread.Execute> message');
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> create message thread for RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
      TACRMessageThread.Create(FManager,RecvItem);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> thread created for RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
     end;
    SleepTime := 0;
   finally
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> leave session CS for RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
    LeaveCSect(PACRClntSession(RecvItem.Session).FCSect);
    dec(PACRClntSession(RecvItem.Session).Status);
{$IFDEF LOG_QUEUE_PROCESSOR_THREADS}
aaWriteToLog('TACRMessageThread> Status = '+IntToStr(PACRClntSession(RecvItem.Session).Status)+' @='+IntToHex(Integer(PACRClntSession(RecvItem.Session)),8));
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRQueueProcessorThread> get next item with same #');
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
aaWriteToLog('TACRQueueProcessorThread.Execute> FINISH - '+IntToStr(GetTickCount));
{$ENDIF}
except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
   end;
end;
end; // TACRQueueProcessorThread.Execute

// TACRQueueProcessorThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRMessageThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRMessageThread.Create(
                        Manager:          TACRBaseConnectionManager;
                        Msg:              PACRRecvItem
                                            );
begin
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Create...');
{$ENDIF}
 try
  Manager.IncThreadCount;
  FManager := Manager;
  FMsg := Msg;
  FManager.FMessageThreads.Add(Self);
  Error :=  ErrorRClient + ErrorRMessageThread
            + IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle));
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> inherited...');
{$ENDIF}
  inherited Create(False);
  FRecreate := False;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Created!');
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
destructor TACRMessageThread.Destroy;
begin
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Destroy...');
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
  if not Terminated then
  if FRecreate then
   begin
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      TACRMessageThread.Create(FManager,FMsg);
   end;
 end;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Destroy finished!');
{$ENDIF}
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRMessageThread.Execute;
var
  Buf:                 PAnsiChar;
  BufSize, AuBufSize:  Integer;
  ConnectionParams:    PACRConnectionParams;
begin
 try // except
    try
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Receive message buffer...');
{$ENDIF}
     FManager.GetBufferFromPackets(FMsg.Packets, Buf, BufSize);
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Free packets list...');
{$ENDIF}
     FMsg.Packets.Free;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> remove message from queue...');
{$ENDIF}
    except
     on E:Exception do
      raise EACRException.Create(40507,'ACRMessage section - '+ErrorRCannotReceiveMsg+E.Message);
    end;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> Decompress and decrypt buffer...');
{$ENDIF}
    if FManager.DecompressAndDecryptBuffer(PACRClntSession(FMsg.Session).Session, Buf, BufSize) then
     begin
      try
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> process new message...');
aaWriteToLog('TACRMessageThread> Status = '+IntToStr(PACRClntSession(FMsg.Session).Status)+' @='+IntToHex(Integer(PACRClntSession(FMsg.Session)),8));
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRMessageThread> receive message for RecvItem = '+IntToStr(Integer(FMsg)));
{$ENDIF}
      TACRNetworkSession(PACRClntSession(FMsg.Session).Session).ReceiveMessage(Buf, BufSize);
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> message received!');
aaWriteToLog('TACRMessageThread> Status = '+IntToStr(PACRClntSession(FMsg.Session).Status)+' @='+IntToHex(Integer(PACRClntSession(FMsg.Session)),8));
{$ENDIF}
      except
       on E:Exception do
        raise EACRException.Create(40512,'ACRMessage section - '+ErrorRSessionReceiveMessage+E.Message);
      end;
     end;
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> free...');
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRMessageThread> Dispose RecvItem = '+IntToStr(Integer(FMsg)));
{$ENDIF}
    Dispose(FMsg);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRMessageThread> OK!');
{$ENDIF}
{$IFDEF LOG_MESSAGE_THREAD}
aaWriteToLog('TACRMessageThread> execute finished!');
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

// TACRMessageThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRSendingThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRSendingThread.Create(
                          Session:    TACRNetworkSession;
                          Manager:    TACRBaseConnectionManager;
                          Method:     Pointer;
                          arg1,arg2,arg3,arg4,arg5: Integer
                                            );
begin
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
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TACRSendingThread.Destroy;
begin
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
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      TACRSendingThread.Create(FSession,FManager,FMethod,Farg1,Farg2,Farg3,Farg4,Farg5);
   end;
 end;
end;// Destroy;


{$IFDEF MsgCommunicator}
////////////////////////////////////////////////////////////////////////////////
// Connect
////////////////////////////////////////////////////////////////////////////////
procedure TACRSendingThread.Connect(
                                NetworkPacket:        PACRNetworkPacket
                                    );
var
  Header:               PACRPacketHeader;
  Packet:               PACRPacket;
  Connections:          TACRList;
{$IFDEF MsgCommunicator}
  Session:              TACRBaseSession;
  ClientSession,
  ClientSession2:       PACRClntSession;
{$ENDIF}
  ClientConnection:     PACRClntConnection;
  SessionFound,
  Session2Found,
  ConnectionFound:      Boolean;
  Buf:                  PAnsiChar;
  BufSize:              Integer;
  i:                    Integer;
{$IFDEF MsgCommunicator}
  RemoteUserID,
  AuBufSize:            Integer;
  ConnectionParams:     PACRConnectionParams;
  Application:          AnsiString;
{$ENDIF}
  CurrentRequestID:     Integer;
  Packets:              TACRList;
  Sessions:             TACRList;
  PacketAdded:          Boolean;
  Host:                 AnsiString;
  Port:                 Integer;

procedure GetClientConnection;
var
  i:                    Integer;
begin
  ConnectionFound := False;
  Connections := TACRClientConnectionManager(FManager).FConnections.LockList;
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
   TACRClientConnectionManager(FManager).FConnections.UnlockList;
  end;
end; // GetClientConnection

begin // Connect
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> Connect');
{$ENDIF}
 try
  ClientConnection := nil;
  Header := PACRPacketHeader(NetworkPacket.Packet.Buffer);
  PacketAdded := False;
// is direct connection enabled?
  SessionFound := False;
  Session2Found := False;
  Sessions := FManager.FSessions.LockList;
  try
   for i:=0 to Sessions.Count-1 do
    begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> get ClientSession2['+IntToStr(i)+'] of '+IntToStr(Sessions.Count));
{$ENDIF}
     ClientSession2 := Sessions.Items[i];
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> ServerSessionID'+IntToStr(ClientSession2.ServerSessionID));
if TACRClientSession(ClientSession2.Session)<>nil then
begin
aaWriteToLog('TACRSendingThread> Session.UserID   = '+IntToStr(TACRClientSession(ClientSession2.Session).UserID));
aaWriteToLog('TACRSendingThread> Header.Recepient = '+IntToStr(Header.Recepient));
if TACRClientSession(ClientSession2.Session).Direct then
aaWriteToLog('TACRSendingThread> direct session')
else
aaWriteToLog('TACRSendingThread> session not direct');
if ClientSession2.Session.Connected then
aaWriteToLog('TACRSendingThread> session connected')
else
aaWriteToLog('TACRSendingThread> session not connected');
aaWriteToLog('TACRSendingThread> ClientSession2.Session.SessionID = '+IntToStr(ClientSession2.Session.SessionID));
end;
{$ENDIF}
     if (ClientSession2.ServerSessionID = INVALID_SESSION_ID) then
      if ClientSession2.Session<>nil then
       if ClientSession2.Session.UserID = Header.Recepient then // for connect request only
        if TACRClientSession(ClientSession2.Session).Direct then
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
aaWriteToLog('TACRSendingThread> client session not found!!!');
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
aaWriteToLog('TACRSendingThread> : Check session '+IntToStr(i)+' of '+IntToStr(Sessions.Count));
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
aaWriteToLog('TACRSendingThread> : Found: @session='+IntToHex(Integer(ClientSession),6)+', Client SessionID='+IntToStr(ClientSession.ServerSessionID));
{$ENDIF}
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
if ClientSession.Session <> nil then
aaWriteToLog('TACRSendingThread> : Found: @session='+IntToHex(Integer(ClientSession),6)+', Server SessionID='+IntToStr(ClientSession.Session.SessionID));
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
aaWriteToLog('TACRSendingThread> : New ClientSession');
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
aaWriteToLog('TACRSendingThread> InitCSect...');
{$ENDIF}
    SessionFound := True;
    ClientSession.Status := ACRInUse;
    InitCSect(ClientSession.FCSect,'ClientSession, direct connect to '+NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort),false);
    EnterCSect(ClientSession.FCSect);
    FManager.FSessions.Add(ClientSession);
    ClientSession.AnswerTime := 0;
    ClientSession.AnswerStatus := ACRNo;
    ClientSession.RemoteConnectionID := Header.ConnectionID;
    ClientSession.ConnectionID := ClientConnection.ConnectionID;
    ClientSession.ServerSessionID := Header.SessionID;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> :   New: @session='+IntToHex(Integer(ClientSession),6)+', Client SessionID='+IntToStr(ClientSession.ServerSessionID));
{$ENDIF}
    ClientSession.ControlCode := ACRExecute;
    ClientSession.PacketIDsToResend := TACRThreadIntArray.Create;
    ClientSession.MsgPacketIDsToResend := TACRThreadIntArray.Create;
    ClientSession.ResendRequestThread := nil;
// Create new packets list
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> : Packets list create');
{$ENDIF}
    ClientSession.Packets := TACRList.Create;
    ClientSession.Packets.Capacity := ACRDefaultPacketsInRequest; // Allocate some place in list
// add new session to list
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> : add new session to list');
{$ENDIF}
   end
  else // not first connect - reset and resend connection info
   begin
    // Is buffer receiving now?
    if (ClientSession.AnswerStatus = ACRStart)
    or (ClientSession.AnswerStatus = ACRFull)
    or (ClientSession.Session = nil) // just added, not finished
    or (ClientSession.Session.SessionID = INVALID_SESSION_ID) // buffer received, not finished
    then
     begin
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TACRSendingThread> : Buffer is receiving now');
  {$ENDIF}
      Exit;
     end;
    if (ClientSession.ControlCode <> ACRExecute) then
     begin
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TACRSendingThread> : Not Execute - Terminate ListeningThread, ClientSession.ControlCode='+IntToStr(ClientSession.ControlCode));
  {$ENDIF}
      Exit;
     end;
    if (ClientSession.CurrentRequestID > Header.CurrentRequestID) then // packet from old connection request
     begin
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TACRSendingThread> : Connection exists - SendConnectAckn');
  {$ENDIF}
//        Header.Recepient := Header.Sender;
      if ClientSession.Session<>nil then
       begin
        if ClientConnection = nil then
          GetClientConnection;
        TACRClientConnectionManager(FManager).SendConnectAckn(ClientSession, ClientConnection, Header.CurrentRequestID);
       end;
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
aaWriteToLog('TACRSendingThread> : New Packet');
{$ENDIF}
  Packet := NetworkPacket.Packet;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> : BufferSize='+IntToStr(NetworkPacket.Packet.BufferSize));
aaWriteToLog('TACRSendingThread> : Packet add');
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
  if Header.ControlCode=ACRConnect+ACRLastPacket then
   ClientSession2.AnswerStatus := ACRFull;
 finally
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> Free packet...');
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
aaWriteToLog('TACRSendingThread> connect user from '+NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort));
{$ENDIF}
  Host := NetworkPacket.FromHost;
  Port := NetworkPacket.FromPort;
  Dispose(NetworkPacket);
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> Freed!');
{$ENDIF}
 end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> enter CS...');
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> enter CS2...');
{$ENDIF}
 inc(ClientSession2.Status);
 EnterCSect(ClientSession2.FCSect);
 try
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> receive buffer...');
{$ENDIF}
  TACRClientConnectionManager(FManager).ReceiveBuffer(ClientSession2.Session, Buf, BufSize, True);
  finally
   LeaveCSect(ClientSession2.FCSect);
   dec(ClientSession2.Status);
  end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> connection - buffer received');
{$ENDIF}
  ClientSession.Session := Session;
  Move(Buf^, RemoteUserID, SizeOf(RemoteUserID));
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> UserID = '+IntToStr(TACRClientSession(Session).FUserID));
{$ENDIF}
  inc(Buf, SizeOf(RemoteUserID));
  try
    Move(PAnsiChar(Buf + SizeOf(TACRConnectionParams))^, AuBufSize, SizeOf(AuBufSize));
    if not TACRClientConnectionManager(FManager).IsAuthorizationBufferValid(
              Session.ConnectParams.CryptoInfo,
              PAnsiChar(Buf + SizeOf(TACRConnectionParams) + SizeOf(AuBufSize)),
              AuBufSize
                                               )
    then
     begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> authorization buffer is not valid');
{$ENDIF}
      TACRClientConnectionManager(FManager).SendDisconnectRequest(ClientSession, False);
      FManager.FSessions.Remove(ClientSession);
      TACRClientConnectionManager(FManager).DeleteSession(ClientSession);
      Exit;
     end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> authorization buffer is valid');
{$ENDIF}
// Get ConnectParams
    ConnectionParams := PACRConnectionParams(Buf);
// Get client Application name
    SetLength(Application, BufSize-SizeOf(TACRConnectionParams)
      -SizeOf(AuBufSize)-AuBufSize-1-SizeOf(TACRClientSession(Session).FUserID));
    StrCopy(PAnsiChar(Application), Buf+SizeOf(TACRConnectionParams)+SizeOf(AuBufSize)+AuBufSize);
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> Application = "'+Application+'"');
{$ENDIF}
  finally
   dec(Buf, SizeOf(RemoteUserID));
  end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> connect user...');
{$ENDIF}
  ClientSession.Session := Session.ConnectUser(RemoteUserID, Host, Port);
  if ClientSession.Session = nil then
   begin
    ClientSession.Session := Session;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> not connected, send disconnect...');
{$ENDIF}
    TACRClientConnectionManager(FManager).SendDisconnectRequest(ClientSession, False);
    FManager.FSessions.Remove(ClientSession);
    TACRClientConnectionManager(FManager).DeleteSession(ClientSession);
    Exit;
   end
  else
   begin
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> user connected');
{$ENDIF}
    ClientSession.AnswerStatus := ACRStart;
  //      ClientSession.Session.FConnectParams.CryptoInfo := TACRServer(FManager.FServer).CryptoParams.GetCryptoParams;
    ClientSession.Session.FConnectParams.RemoteHost := Host;
    ClientSession.Session.FConnectParams.RemotePort := Port;
    ClientSession.Session.FConnectParams.ServerID := Session.FConnectParams.ServerID;
   // Set SessionID
    EnterCSect(FManager.FCSect);
    ClientSession.Session.SessionID := FManager.FSessionID;
  {$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
  aaWriteToLog('TACRSendingThread> :   New: @session='+IntToHex(Integer(ClientSession),6)+', Server SessionID='+IntToStr(ClientSession.Session.SessionID));
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
aaWriteToLog('TACRSendingThread> send ConnectACKN...');
{$ENDIF}
    if ClientConnection = nil then
      GetClientConnection;
    TACRClientConnectionManager(FManager).SendConnectAckn(ClientSession, ClientConnection);
    inc(ClientSession.CurrentRequestID);
   end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> free...');
{$ENDIF}
 finally
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> Finishing...');
{$ENDIF}
  if SessionFound then
   begin
    LeaveCSect(ClientSession.FCSect);
    dec(ClientSession.Status);
   end;
  MemoryManager.FreeAndNilMem(Buf);
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> Buffer is freed!');
{$ENDIF}
 end;
{$IFDEF LOG_CLIENT_ACCEPT_DIRECT_CONNECTING}
aaWriteToLog('TACRSendingThread> OK - connected');
{$ENDIF}
end; // Connect


//------------------------------------------------------------------------------
// CommandReceived
//------------------------------------------------------------------------------
procedure TACRSendingThread.ExecuteReceivedCommand(
                                ClientSession:        PACRClntSession;
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
  ClientSession.AnswerStatus := ACRFull;
  if ClientSession.ControlCode = ACRExecute then
    ClientSession.ControlCode := ACRSuspend;
  try // except
   try
    TACRClientConnectionManager(FManager).ReceiveBuffer(ClientSession.Session, Buf, BufSize);
   except
    on E:Exception do
     raise EACRException.Create(40506, ErrorRCannotReceive+E.Message);
   end;
    begin
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('Client started new request #'+IntToStr(ClientSession.CurrentRequestID));
aaWriteBufferToLog(Buf, BufSize);
{$ENDIF}
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRClientSessionThread.Execute - ExecuteReceivedCommand - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
    try
     dec(ClientSession.CurrentRequestID);
     LeaveCSect(ClientSession.FCSect); // needs to send answer
     TACRClientSession(ClientSession.Session).ExecuteReceivedCommand(Buf, BufSize);
     EnterCSect(ClientSession.FCSect);
     inc(ClientSession.CurrentRequestID);
     if ClientSession.ControlCode = ACRSuspend then
       ClientSession.ControlCode := ACRExecute;
    except
     on E:Exception do
       raise EACRException.Create(40513,'Command section - '+ErrorRSessionReceiveData+E.Message);
    end;
   end;
 except
  on E: EACRException do
   begin
    ClientSession.AnswerStatus := ACRNo;
    Error:=
                  ErrorRClient+ErrorRPacketProcessorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ClientSession <> nil)
    or (ClientSession.Session <> nil)
    then
      TACRNetworkSession(ClientSession.Session).DoOnError(MsgClientPacketProcessorThreadCommand,E.NativeError,Error);
   end;
  on E: Exception do
   begin
    ClientSession.AnswerStatus := ACRNo;
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('ERROR: ' + Error + ErrorRExecute + 'CommandReceived> ' + E.Message);
{$ENDIF}
    TACRNetworkSession(ClientSession.Session).DoOnError(MsgClientPacketProcessorThreadCommand,-1,Error);
   end;
 end;
{$IFDEF LOG_CLIENT_COMMAND_EXECUTE}
aaWriteToLog('CommandReceived> FINISHED');
{$ENDIF}
{
              case Command of
               ACRInitProgressSend:
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
procedure TACRSendingThread.Echo;
var
  Buf:                  PAnsiChar;
  BufSize:              Integer;
begin
  TACRClientConnectionManager(FManager).ReceiveBuffer(TACRClientSession(Farg1),Buf,BufSize);
  TACRClientConnectionManager(FManager).SendBuffer(TACRClientSession(Farg1),Buf,BufSize,Farg2);
  MemoryManager.FreeAndNilMem(Buf);
end; // Echo

//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRSendingThread.Execute;
begin
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TACRSendingThread.Execute> START');
aaWriteToLog(IntToStr(Integer(FMethod))+' = Method');
aaWriteToLog('0 Connect');
{$IFDEF MsgCommunicator}
aaWriteToLog(IntToStr(Integer(@TACRSendingThread.ExecuteReceivedCommand))+' ExecuteReceivedCommand');
{$ENDIF}
aaWriteToLog(IntToStr(Integer(@TACRSendingThread.Echo))+' Echo');
aaWriteToLog(IntToStr(Integer(@TACRClientConnectionManager.SendAcknowledgement))+' SendAcknowledgement');
aaWriteToLog(IntToStr(Integer(@TACRClientConnectionManager.SendDisconnectRequest))+' SendDisconnectRequest');
aaWriteToLog(IntToStr(Integer(@TACRClientConnectionManager.PacketResendRequest))+' PacketResendRequest');
aaWriteToLog(IntToStr(Integer(@TACRClientConnectionManager.SendPing))+' SendPing');
{$ENDIF}
 try // except
{$IFDEF MsgCommunicator}
  if FMethod = nil then
    Connect(PACRNetworkPacket(Farg1))
  else
  if FMethod = @TACRSendingThread.ExecuteReceivedCommand then
    ExecuteReceivedCommand(PACRClntSession(Farg1),Farg2)
  else
{$ENDIF}
  if FMethod = @TACRSendingThread.Echo then
    Echo
  else
  if FMethod = @TACRClientConnectionManager.SendAcknowledgement then
    TACRClientConnectionManager(FManager).SendAcknowledgement(PACRClntSession(Farg1),Boolean(Farg2),Farg3)
  else
  if FMethod = @TACRClientConnectionManager.SendDisconnectRequest then
    TACRClientConnectionManager(FManager).SendDisconnectRequest(PACRClntSession(Farg1),Boolean(Farg2))
  else
  if FMethod = @TACRClientConnectionManager.PacketResendRequest then
    TACRClientConnectionManager(FManager).PacketResendRequest(PAnsiChar(Farg1),TACRNetwork(Pointer(Farg2)),AnsiString(PAnsiChar(Farg3)),Farg4)
  else
  if FMethod = @TACRClientConnectionManager.SendPing then
    TACRClientConnectionManager(FManager).SendPing(PACRClntSession(Farg1))
  else
  if FMethod = @TACRServerSession.ReceiveMessage then
   begin
    inc(PACRSrvrSession(Farg4).MsgThreadCount);
{$IFDEF LOG_SERVER_MESSAGE_THREAD_CREATE}
aaWriteToLog('process message in new thread start,  threads count = '+IntToStr(PACRSrvrSession(Farg4).MsgThreadCount));
{$ENDIF}
    TACRServerSession(Farg1).ReceiveMessage(PAnsiChar(Farg2), Farg3);
    dec(PACRSrvrSession(Farg4).MsgThreadCount);
{$IFDEF LOG_SERVER_MESSAGE_THREAD_CREATE}
aaWriteToLog('process message in new thread finish, threads count = '+IntToStr(PACRSrvrSession(Farg4).MsgThreadCount));
{$ENDIF}
   end
  else
   begin
{$IFDEF LOG_CLIENT_SEND_THREAD}
aaWriteToLog('TACRSendingThread.Execute> Unknown Method = '+IntToStr(Integer(FMethod))+', '+IntToHex(Integer(FMethod),8));
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
aaWriteToLog('TACRSendingThread.Execute> FINISH');
{$ENDIF}
end; // Execute

// TACRSendingThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRResendRequestThread.Create(
                       Manager:           TACRBaseConnectionManager;
                       Queue:             TACRThreadList;
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
  if FManager is TACRClientConnectionManager then
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
destructor TACRResendRequestThread.Destroy;
begin
try
 try
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread.Destroy');
{$ENDIF}
  if FCommand then
    FManager.FCommandResendRequestThread := nil
  else
    FManager.FMessageResendRequestThread := nil;
  inherited Destroy;
  FManager.DecThreadCount;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread.Destroy - FINISHED');
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
aaWriteToLog('TACRResendRequestThread.Destroy - recreate...');
{$ENDIF}
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
    if FCommand then
     begin
      if not FClient then // Server only
        FManager.FCommandResendRequestThread := TACRResendRequestThread.Create(FManager,FQueue,FCommand);
     end
    else
      FManager.FMessageResendRequestThread := TACRResendRequestThread.Create(FManager,FQueue,FCommand);
   end;
end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRResendRequestThread.Execute;
var
  queue:              TACRList;
  recvItem:           PACRRecvItem;
  Delay2,
  i, j,
  Delay:              Integer;
  Network:            TACRNetwork;
  Packets:            TACRList;
  Packet:             PACRPacket;
  PacketIDs:          TACRIntegerArray;
  headerReady:        Boolean;
  AllPacketsReceived: Boolean;
  Header:             TACRPacketHeader;

function IsRequestNeeded(recvItem: PACRRecvItem): Boolean;
begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('RESENDING THREAD - IsRequestNeeded?');
{$ENDIF}
  Result := True;
  if recvItem.RecvStatus <> ACRNotFull then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread> RecvStatus <> ACRNotFull');
{$ENDIF}
    Result := False;
    Exit;
   end;
(*
  if ServerSession.MsgControlCode = ACRTerminate then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread> ServerSession.MsgControlCode = ACRTerminate');
{$ENDIF}
    Result := False;
    Exit;
   end;
*)
end;

begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread> START');
{$ENDIF}
try
  PacketIDs := TACRIntegerArray.Create;
  try
   try
    j := -1;
    if FClient then
     begin
      Delay := ACRRequestDelay;
      Delay2 := 0; // ACRReceiveSleep;
     end
    else
     begin
      if FManager.FServer = nil then
        Delay := 1 + (ACRServerRequestDelay div (TACRServerConnectionManager(FManager).SessionsCount+1))
      else
        Delay := 1 + (TACRServer(FManager.FServer).NetworkSettings.ServerRequestDelay div (TACRServerConnectionManager(FManager).SessionsCount+1));
      Delay2 := TACRServer(FManager.FServer).NetworkSettings.ServerReceiveSleep;
  // prepare PacketHeader
      Header.Signature := ACRServerPacketSign;
      Header.Sender := TACRServerConnectionManager(FManager).FNetwork.FLocalClient;
      Header.ControlCode := ACRMessagePacketResendRequest;
      Network := TACRServerConnectionManager(FManager).FNetwork;
     end;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread> Delay  ='+IntToStr(Delay));
aaWriteToLog('TACRResendRequestThread> Delay2 ='+IntToStr(Delay2));
{$ENDIF}
    repeat
     if Terminated then
      begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> Terminated in queue loop');
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
aaWriteToLog('TACRResendRequestThread> j = '+IntToStr(Integer(j)));
aaWriteToLog('TACRResendRequestThread> recvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
     finally
      FQueue.UnlockList;
     end;
     if not TACRClientConnectionManager(FManager).IsSessionExisting(PACRClntSession(recvItem.Session)) then
      begin
    {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
    aaWriteToLog('TACRResendRequestThread> session is not existing - remove...');
    {$ENDIF}
       FQueue.Remove(recvItem);
       dec(j);
       continue;
      end;
     try // session entered CS
       if FClient then
        begin
         Delay := PACRClntSession(recvItem.Session).Session.ConnectParams.RequestDelay;
  //       Delay2 := PACRClntSession(recvItem.Session).Session.ConnectParams.ReceiveSleep;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRResendRequestThread> Delay  ='+IntToStr(Delay));
{$ENDIF}
        end;
       if not (IsRequestNeeded(recvItem)) then
        begin
    {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
    aaWriteToLog('TACRResendRequestThread> not needed - next');
    {$ENDIF}
         continue;
        end;
    {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
    aaWriteToLog('TACRResendRequestThread> prepare...');
    {$ENDIF}
    // Make PacketHeader
        if FClient then
         begin
          Network := recvItem.Network;
          headerReady := false;
         end
        else
         begin
          Header.Recepient := PACRSrvrSession(recvItem.Session).RemoteClientID;
          Header.ConnectionID := PACRSrvrSession(recvItem.Session).ConnectionID;
          Header.SessionID := PACRSrvrSession(recvItem.Session).Session.SessionID;
          Header.PacketID := 0;
          Header.CurrentRequestID := PACRSrvrSession(recvItem.Session).ClientMessageID;
          headerReady := true;
         end;
    // Search absent packet and send request to resend it
        AllPacketsReceived := True;
        Packets := recvItem.Packets.LockList;
        try
         PacketIDs.SetSize(0);
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> Packets.Count = '+IntToStr(Packets.Count));
  {$ENDIF}
         for i:=0 to Packets.Count-1 do
          begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> i = '+IntToStr(i));
  {$ENDIF}
           Packet := Packets.Items[i];
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> Packet = '+IntToStr(Integer(Packet)));
  {$ENDIF}
           if (Packet = nil) then
            begin
             PacketIDs.Append(i);
             AllPacketsReceived := False;
            end
           else
             if FClient then
              if not headerReady then
               if (Packet.BufferSize >= SizeOf(TACRPacketHeader)) then
               if (Packet.Buffer <> nil) then
                begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> prepare header...');
  {$ENDIF}
                 Move(Packet.Buffer^,Header,SizeOf(TACRPacketHeader));
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread>header ready');
  {$ENDIF}
                 headerReady := true;
                end;
          end;
        finally
         recvItem.Packets.UnlockList;
        end;
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> PacketsCount='+IntToStr(PacketIDs.ItemCount));
  {$ENDIF}
        if not AllPacketsReceived then
          if headerReady then
            for i:=0 to PacketIDs.ItemCount-1 do
             begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> i='+IntToStr(i));
  {$ENDIF}
              if Terminated then
               begin
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> Terminated in packets loop');
  {$ENDIF}
                Exit;
               end;
  // send request
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> PacketMsgResendRequest, i='+IntToStr(i));
  {$ENDIF}
              if FClient then
                TACRClientConnectionManager(FManager).PacketResendRequest(@Header, Network, recvItem.RemoteHost, recvItem.RemotePort, PacketIDs.Items[i], True)
              else
                TACRServerConnectionManager(FManager).PacketResendRequest(@Header, Network, recvItem.RemoteHost, recvItem.RemotePort, PacketIDs.Items[i], True);
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> Packet has been requested');
  {$ENDIF}
              Sleep(Delay2);
             end; // next packet for this item
     finally
      LeaveCSect(PACRClntSession(recvItem.Session).FCsect);
      dec(PACRClntSession(RecvItem.Session).Status);
     end;
    until False; // Get new incoming item
  {$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
  aaWriteToLog('TACRResendRequestThread> FINISH');
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
// TACRResendRequestThread


{$IFDEF CLIENT_VERSION}

////////////////////////////////////////////////////////////////////////////////
//
// TACRClientConnectionManager
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientConnectionManager.Create;
begin
 try
  InitCSect(FCSect,'TACRClientConnectionManager',false);
  inherited Create;
  FListenerStoped := False;
  FSessions := TACRThreadList.Create('ClientConnectionManager.FSessions',false);
  FConnections := TACRThreadList.Create;
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
  FReceiveTimeOut := ACRReceiveTimeOut;
  FPacketQueue := TACRThreadList.Create;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.Create> TACRClientPacketProcessorThread.Create...');
{$ENDIF}
  FPacketProcessorThread := TACRClientPacketProcessorThread.Create(self);
(*
// for server
  FCommandQueue := TACRThreadList.Create;
//  FCommandProcessorThread := TACRCommandProcessorThread.Create(self);
  FCommandProcessorThread := TACRQueueProcessorThread.Create(self,FCommandQueue);
{$IFDEF MsgCommunicator}
  FCommandProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.4);
{$ELSE}
  FCommandProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.9);
{$ENDIF}
*)
  FCommandThreads := nil; // for client: stored in TVsgClntSession
  FMessageThreads := TACRThreadList.Create;
  FMessageQueue := TACRThreadList.Create('message queue',false);
  FSendMessages := TACRThreadList.Create;
  FRecvMessages := TACRThreadList.Create;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.Create> TACRQueueProcessorThread.Create...');
{$ENDIF}
  FMessageProcessorThread := TACRQueueProcessorThread.Create(self,FMessageQueue,false);
{$IFDEF MsgCommunicator}
  FMessageProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.9);
{$ELSE}
  FMessageProcessorThread.MaxThreads := trunc(FMaxThreadCount*0.2);
{$ENDIF}
  FMessageProcessorThread.FCommand := False;
// for server
//  FCommandResendRequestThread := TACRResendRequestThread.Create(self,FCommandQueue);
  FCommandResendRequestThread := nil;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.Create> TACRResendRequestThread.Create...');
{$ENDIF}
  FMessageResendRequestThread := TACRResendRequestThread.Create(self,FMessageQueue,false);
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.Create> TACRResendRequestThread.Created, ThreadID = '+IntToStr(FMessageResendRequestThread.ThreadID));
aaWriteToLog('TACRClientConnectionManager.Create> Application: '+FApplication);
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TACRClientConnectionManager.Create - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRClientConnectionManager.Destroy;
begin
 try
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> Application: '+FApplication);
{$ENDIF}
  DisconnectAll;
  FListenerStoped := True;

{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> terminate PacketProcessorThread');
{$ENDIF}
  CloseThread(@FPacketProcessorThread,ACRClientConnectionManager,ErrorRPacketProcessorThread);
//  CloseThread(@FCommandProcessorThread,ACRClientConnectionManager,ErrorRCommandProcessorThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> terminate MessageProcessorThread');
{$ENDIF}
  CloseThread(@FMessageProcessorThread,ACRClientConnectionManager,ErrorRMessageProcessorThread);
//  CloseThread(@FCommandResendRequestThread,ACRClientConnectionManager,ErrorRCommandResendRequestThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> terminate MessageResendRequestThread');
{$ENDIF}
  CloseThread(@FMessageResendRequestThread,ACRClientConnectionManager,ErrorRMessageResendRequestThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> terminate Message Threads...');
{$ENDIF}
  CloseThreads(FMessageThreads,ErrorRMessageThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> terminate Command Threads...');
{$ENDIF}
  CloseThreads(FCommandThreads,ErrorRCommandThread);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> terminate Sending Threads - base manager...');
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
aaWriteToLog('TACRClientConnectionManager.Destroy> free thread lists...');
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
aaWriteToLog('TACRClientConnectionManager.Destroy - free thread lists error: '+E.Message);
    end;
{$ENDIF}
end;

{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.Destroy> free connections and sessions lists...');
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
aaWriteToLog('TACRClientConnectionManager.Destroy - FINISHED');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TACRClientConnectionManager.Destroy - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Destroy


//------------------------------------------------------------------------------
// IsSessionExisting: search for client session and enter CSect to block its using
//------------------------------------------------------------------------------
function TACRClientConnectionManager.IsSessionExisting(ClientSession: PACRClntSession): Boolean;
var
  Sessions:     TACRList;
  i:            Integer;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.IsSessionExisting> START');
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
aaWriteToLog('TACRClientConnectionManager.IsSessionExisting> FINISH');
{$ENDIF}
end;// IsSessionExisting


//------------------------------------------------------------------------------
// PacketResendRequest
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TACRNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False
                                 );
var
  Header:          PACRPacketHeader;
begin
  Header := Pointer(Buffer);
  if Msg then
    Header.ControlCode := ACRMessagePacketResendRequest
  else
    Header.ControlCode := ACRPacketResendRequest;
  Header.Signature := ACRClientPacketSign;
  if (PacketID >= 0) then
    Header.PacketID := PacketID
  else
    Header.Recepient := Header.Sender;
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRClientConnectionManager.PacketResendRequest> asks to resend packet # '+IntToStr(Header.PacketID));
{$ENDIF}
  EnterCSect(Network.FCSect);
  try
   Network.RemoteHost := RemoteHost;
   Network.RemotePort := RemotePort;
   Network.SendBuffer(Buffer, SizeOf(TACRPacketHeader));
  finally
   LeaveCSect(Network.FCSect);
  end;
end;// PacketResendRequest


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.OnDisconnect(
                               FNetwork:      TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
var
  Sessions:             TACRList;
  Session:              TACRBaseSession;
  ClientSession:        PACRClntSession;
//  Connections:          TACRList;
//  ClientConnection:     PACRClntConnection;
  i, j:                 Integer;
//  Found:                Boolean;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.OnDisconnect - START');
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
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(FNetwork)]);
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
aaWriteToLog('TACRClientConnectionManager.OnDisconnect - DoDisconnect');
{$ENDIF}
       FSessions.UnlockList;
       DoDisconnect(Session);
       Sessions := FSessions.LockList;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.OnDisconnect - Session.OnDisconnect');
{$ENDIF}
       if Session<>nil then
         TACRClientSession(Session).DoCloseSessionOnNetworkError;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.OnDisconnect - Session.OnDisconnect FINISHED');
{$ENDIF}
{$IFDEF MsgCommunicator}
       if Session<>TACRClient(TACRClientSession(Session).FOwnerComponent).FDefaultSession then
          Session.Free;
 {$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.OnDisconnect - Session Freed!');
 {$ENDIF}
{$ENDIF}
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
{
  if not Found then
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(ClientConnection.ConnectionID)]);
}
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.OnDisconnect - FINISH');
{$ENDIF}
end; // OnDisconnect

(*
//------------------------------------------------------------------------------
// IsExistingPacket
//------------------------------------------------------------------------------
function TACRClientConnectionManager.IsExistingPacket: Boolean;
var
 i:                    Integer;
 Packets:              TACRList;
 NetworkPacket:        PACRNetworkPacket;
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
     if CompareMem(NetworkPacket.Packet.Buffer, Buffer, SizeOf(TACRPacketHeader)) then
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
procedure TACRClientConnectionManager.NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
procedure AddPacket;
var
  NetworkPacket:     PACRNetworkPacket;
  Packet:            PACRPacket;
begin
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaIncCounter(counter10); aaStartTime(time10); try aaStartTime(time11); {$ENDIF}
  New(NetworkPacket);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStopTime(time11);{$ENDIF}
  NetworkPacket.Network := Network;
  NetworkPacket.FromHost := FromHost;
  NetworkPacket.FromPort := FromPort;
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStartTime(time12);{$ENDIF}
  New(Packet);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStopTime(time12);{$ENDIF}
  Packet.Buffer := Buffer;
  Packet.BufferSize := BufferSize;
  NetworkPacket.Packet := Packet;
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStartTime(time13);{$ENDIF}
  FPacketQueue.Add(NetworkPacket);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME} finally aaStopTime(time13); aaStopTime(time10); end; {$ENDIF}
{$IFDEF LOG_CLIENT_RESENDING}
if PACRPacketHeader(Buffer).ControlCode = ACRPacketResendRequest then
aaWriteToLog('NetworkListener> Added Resend Request Packet # '+IntToStr(PACRPacketHeader(Buffer).PacketID));
{$ENDIF}
end; // AddPacket

begin // NetworkListener
{$IFDEF LOG_CLIENT_RECV}
aaWriteToLog('NetworkListener --------------------------------');
aaWriteToLog('Header.ConnectionID = '+IntToStr(PACRPacketHeader(Buffer).ConnectionID));
aaWriteToLog('Header.SessionID    = '+IntToStr(PACRPacketHeader(Buffer).SessionID));
aaWriteToLog('Header.ControlCode  = '+IntToStr(PACRPacketHeader(Buffer).ControlCode));
aaWriteToLog('NetworkListener --------------------------------');
{$ENDIF}
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaIncCounter(counter9); aaStartTime(time9); try {$ENDIF}
  if not FListenerStoped then
//    if not IsExistingPacket then
     begin
      AddPacket;
      Exit;
     end;
  MemoryManager.FreeAndNilMem(Buffer);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME} finally aaStopTime(time9); end; {$ENDIF}
end;// NetworkListener

(*
procedure TACRClientConnectionManager.NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
var
  StartTime:        Cardinal;
  Error:            AnsiString;
  Sessions:         TACRList;
  ClientSession:    PACRClntSession;
begin
  if not FListenerStoped then
   begin
    StartTime := GetTickCount;
    while ((GetTickCount-StartTime) < FReceiveTimeOut) do
     begin
      if ThreadCount<FMaxThreadCount then
       begin
        TACRClientPacketProcessorThread.Create(self, Buffer, BufferSize, Network, FromHost, FromPort);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRClientConnectionManager.NetworkListener> Listener Thread Created ! - '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRClientConnectionManager.NetworkListener> Threads Count = '+IntToStr(ThreadCount));
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
           TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRServerListenerThread,40516,
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
procedure TACRClientConnectionManager.ReceiveMessage(
                          ClientSession:        PACRClntSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
var
  i:                    Integer;
  Packet:               PACRPacket;
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
      if ClientSession.MsgControlCode = ACRTerminate then
       begin
        EnterCSect(FCSect);
        dec(ClientSession.Status);
        LeaveCSect(FCSect);
        raise EACRException.Create(40041, ErrorRCannotReceiveFromServer,
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
      if ClientSession.MsgControlCode = ACRTerminate then
       begin
        EnterCSect(FCSect);
        dec(ClientSession.Status);
        LeaveCSect(FCSect);
        raise EACRException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
      if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.ReceiveTimeOut then
        raise EACRException.Create(40026, ErrorRTimeoutFullReceive,
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
    BufferSize := BufferSize + Packet.BufferSize - SizeOf(TACRPacketHeader);
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
        Move(Pointer(Packet.Buffer+SizeOf(TACRPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TACRPacketHeader));
        inc(pBuf, Packet.BufferSize-SizeOf(TACRPacketHeader));
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
  ClientSession.MsgReceiveStatus := ACRNo;
  EnterCSect(FCSect);
  dec(ClientSession.Status);
  LeaveCSect(FCSect);
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_CLIENT_ReceiveMessage}
aaWriteToLog('CLIENT - ReceiveMessage> Exception! '+E.Message);
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> TACRClientConnectionManager.ReceiveMessage - Error:');
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
procedure TACRClientConnectionManager.ReceiveBuffer(
                          Session:        TACRBaseSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer;
                          Connecting:     Boolean = False
                          );
label
  Loop;
var
  Sessions:             TACRList;
  ClientSession:        PACRClntSession;
  SessionFound:         Boolean;
  i:                    Integer;
  Packet:               PACRPacket;
  pBuf:                 PAnsiChar;
  EmptyTime,
  StartTime:            Cardinal;
begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> START');
{$ENDIF}
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> START');
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
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
 try // session entered CS
  StartTime := aaGetTickCount;
  EmptyTime := StartTime;
  if ClientSession.AnswerStatus <> ACRFull then
   begin
    while (ClientSession.AnswerStatus = ACRNo) do // Wait for starting answer receive
     begin
      if ClientSession.ControlCode = ACRTerminate then
       begin
        raise EACRException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
      if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.StartReceiveTimeOut then
       begin
        raise EACRException.Create(40104, ErrorRTimeoutStartReceive,
                                [ClientSession.ServerSessionID,
                                ClientSession.Session.ConnectParams.StartReceiveTimeOut]);
       end;
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> sleep1...');
{$ENDIF}
      LeaveCSect(ClientSession.FCSect);
      if (aaGetTickCount >= (EmptyTime + ACRPacketProcessTimeOut)) then
       begin
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> sleep(ReceiveSleep='+IntToStr(ClientSession.Session.ConnectParams.ReceiveSleep)+')...');
{$ENDIF}
        Sleep(ClientSession.Session.ConnectParams.ReceiveSleep);
        EmptyTime := aaGetTickCount;
       end
      else
       begin
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> sleep(0)...');
{$ENDIF}
        Sleep(0);
       end;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> up!');
{$ENDIF}
      EnterCSect(ClientSession.FCSect);
     end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> answer started');
{$ENDIF}
    StartTime := aaGetTickCount;
    EmptyTime := StartTime;
    while ClientSession.AnswerStatus <> ACRFull do // Wait for all packets to arrive
     begin
      if ClientSession.ControlCode = ACRTerminate then
       begin
        raise EACRException.Create(40041, ErrorRCannotReceiveFromServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID]);
       end;
      if (aaGetTickCount - StartTime) > ClientSession.Session.ConnectParams.ReceiveTimeOut then
       begin
        try
         ClientSession.ResendRequestThread.Free;
        finally
         raise EACRException.Create(40025, ErrorRTimeoutFullReceive,
                            [ClientSession.ServerSessionID,
                            ClientSession.Session.ConnectParams.ReceiveTimeOut]);
        end;
       end;
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> sleep2...');
{$ENDIF}
      LeaveCSect(ClientSession.FCSect);
      if (aaGetTickCount >= (EmptyTime + ACRPacketProcessTimeOut)) then
       begin
        sleep(ClientSession.Session.ConnectParams.ReceiveSleep);
        EmptyTime := aaGetTickCount;
       end
      else
        sleep(0);
      EnterCSect(ClientSession.FCSect);
     end;
   end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> answer is full');
{$ENDIF}
  BufferSize := 0;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Packets.Count = '+IntToStr(ClientSession.Packets.Count));
{$ENDIF}
  for i := 0 to ClientSession.Packets.Count - 1 do
   begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Packet # '+IntToStr(i));
{$ENDIF}
    Packet := ClientSession.Packets.Items[i];
    BufferSize := BufferSize + Packet.BufferSize - SizeOf(TACRPacketHeader);
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Packet.BufferSize = '+IntToStr(Packet.BufferSize));
{$ENDIF}
   end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
   if BufferSize > 0 then
     Buffer := MemoryManager.GetMem(BufferSize)
   else
     Buffer := nil;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Buffer memory got');
{$ENDIF}
  pBuf := Buffer;
  for i := 0 to ClientSession.Packets.Count - 1 do
   begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Packets.Count = '+IntToStr(ClientSession.Packets.Count));
{$ENDIF}
    Packet := ClientSession.Packets.Items[i];
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Packet # '+IntToStr(i));
{$ENDIF}
    if Packet <> nil then
     begin
      if Packet.Buffer <> nil then
       begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Move...');
{$ENDIF}
        if (Packet.BufferSize > SizeOf(TACRPacketHeader)) then
         begin
          Move(Pointer(Packet.Buffer+SizeOf(TACRPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TACRPacketHeader));
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> inc...');
{$ENDIF}
          inc(pBuf, Packet.BufferSize-SizeOf(TACRPacketHeader));
         end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> inced'+IntToStr(Packet.BufferSize-SizeOf(TACRPacketHeader)));
{$ENDIF}
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> free packet buffer...');
{$ENDIF}
        MemoryManager.FreeAndNilMem(Packet.Buffer);
       end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> Dispose packet...');
{$ENDIF}
      Dispose(Packet);
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> packet = nil...');
{$ENDIF}
      ClientSession.Packets.Items[i] := nil;
     end;
   end;
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> ClientSession.Packets.Count := 0 ...');
{$ENDIF}
  ClientSession.Packets.Count := 0;
  if not Connecting then
    DecompressAndDecryptBuffer(ClientSession.Session, Buffer, BufferSize);
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> DecompressAndDecryptBuffer - OK');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('CLIENT HAS RECEIVED BUFFER FROM SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
aaWriteToLog('==============================================================');
{$ENDIF}
  ClientSession.AnswerStatus := ACRNo;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
 end;
except
  on E: Exception do
    begin
{$IFDEF LOG_CLIENT_RECEIVE_ANSWER}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> TACRClientConnectionManager.ReceiveBuffer - Error:');
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
aaWriteToLog('TACRClientConnectionManager.ReceiveBuffer> FINISH');
{$ENDIF}
end; // ReceiveBuffer


//------------------------------------------------------------------------------
// SendConnectRequest
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.SendConnectRequest(ClientSession: PACRClntSession);
var
  Buf, Buffer:                    PAnsiChar;
  BufSize, BufferSize,
  SizeApp, SizeParams:            Integer;
  StartTime:                      Cardinal;
  Retry:                          Integer;
  ConnectionParams:               TACRConnectionParams;
  RetryCount, Delay,
  ServerID:                       Integer;
{$IFDEF MsgCommunicator}
  Direct:                         Boolean;
{$ENDIF}
begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.SendConnectRequest> START');
{$ENDIF}
// ClientSession.FCSect entered in Connect
 try
  ClientSession.AnswerStatus := ACRNo;
  ClientSession.CurrentRequestID := 0;
  ConnectionParams.Protocol := ClientSession.Session.ConnectParams.Protocol;
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
      if ClientSession.ControlCode = ACRTerminate then
       begin
        Exit;
       end;
{$IFDEF MsgCommunicator}
      if TACRClientSession(ClientSession.Session).Direct then
         ClientSession.Session.FConnectParams.ServerID :=
            TACRClientSession(ClientSession.Session).RemoteUser.UserID; // for connect request only
{$ENDIF}
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.SendConnectRequest> SendBuffer...');
{$ENDIF}
      LeaveCSect(ClientSession.FCSect);
      try
       SendBuffer(ClientSession.Session, Buf, BufSize, ACRConnect);
      finally
       EnterCSect(ClientSession.FCSect);
      end;
  {$IFDEF LOG_CLIENT_CONNECT}
  aaWriteToLog('TACRClientConnectionManager.SendConnectRequest> Sent!');
  {$ENDIF}
  {$IFDEF MsgCommunicator}
      if TACRClientSession(ClientSession.Session).Direct then
        if ClientSession.Session.FConnectParams.ServerID = TACRClientSession(ClientSession.Session).RemoteUser.UserID then // Header.Sender from the answer is not set
          ClientSession.Session.FConnectParams.ServerID := Integer(MSG_INVALID_USER_ID);  // allow listen for ACRConnected answer
  {$ENDIF}
      StartTime := GetTickCount;
      while ((GetTickCount - StartTime) < ClientSession.Session.ConnectParams.ConnectDelay) do // pause
       begin
         if ClientSession.ControlCode = ACRTerminate then
           Exit;
         if ClientSession.SendStatus <> ACRSent then
          begin
           LeaveCSect(ClientSession.FCSect);
{$IFDEF ProcessMessages}
           Application.ProcessMessages;
{$ENDIF ProcessMessages}
           if ((GetTickCount - StartTime) > ACRMaxSendShortSleepTime) then
             Sleep(ClientSession.Session.ConnectParams.WaitForSendSleep)
           else
             Sleep(0);
           EnterCSect(ClientSession.FCSect);
          end
         else
          Exit;
       end;
      if IsDesignMode then
        break;
      inc(Retry);
     until  (Retry > ClientSession.Session.ConnectParams.ConnectRetryCount);
     if ClientSession.SendStatus <> ACRSent then
      begin
       ServerID := ClientSession.Session.ConnectParams.ServerID;
       RetryCount := ClientSession.Session.ConnectParams.ConnectRetryCount;
       Delay := ClientSession.Session.ConnectParams.ConnectDelay;
  {$IFDEF MsgCommunicator}
       Direct := TACRClientSession(ClientSession.Session).Direct;
       if Direct then
         ServerID := TACRClientSession(ClientSession.Session).RemoteUser.UserID
       else
         ServerID := TACRClient(TACRClientSession(ClientSession.Session).FOwnerComponent).ConnectionParams.ConnectParams.ServerID;
  {$ENDIF}
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendConnectRequest - DoDisconnect');
{$ENDIF}
       LeaveCSect(ClientSession.FCSect);
       dec(ClientSession.Status);
       DoDisconnect(ClientSession.Session);
  {$IFDEF MsgCommunicator}
       if Direct then
         raise EACRException.Create(40023, ErrorRCannotConnect,
                             ['user', ServerID, RetryCount, Delay])
       else
  {$ENDIF}
         raise EACRException.Create(40023, ErrorRCannotConnect,
                             ['server', ServerID, RetryCount, Delay]);
      end;
   finally
    MemoryManager.FreeAndNilMem(Buf);
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRClientConnectionManager.SendConnectRequest> ERROR: '+E.Message);
{$ENDIF}
    raise;
   end;
 end; // except
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.SendConnectRequest> FINISH');
{$ENDIF}
end;// SendConnectRequest


//------------------------------------------------------------------------------
// Connect
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.Connect(Session: TACRBaseSession;
                                              ListenOnly: Boolean = False;
                                              Tune: Boolean = True
                                              );
var
  Connections:          TACRList;
  Sessions:             TACRList;
  ClientConnection:     PACRClntConnection;
  ClientSession:        PACRClntSession;
//  MaxHeaderSize:        Integer;
  ConnectionID,
  SessionID:            TACRSessionID;
  Buffer:               PAnsiChar;
  BufferSize,
  SizeParams:           Integer;
  i:                    Integer;
  Raised,
  SessionFound:         Boolean;
  Network:              TACRNetwork;
  ConnectParams:        PACRConnectParams;
  ConnectionParams:     PACRConnectionParams;
  Protocol:             Integer;
begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect - START');
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
   SizeOf(TACRPacketHeader) + SizeOf(TACRConnectionParams)
//    + SizeOf(TACRConnectionID)  // set by client
   + SizeOf(TACRSessionID)        // set by server
   ,
   SizeOf(TACRPacketHeader) + SizeOf(TACRConnectionParams)
    + SizeOf(FApplication)
                        );
  if (Session.ConnectParams.PacketSize < MaxHeaderSize) then
   raise EACRException.Create(40020, ErrorRPacketSizeTooSmall,
                                    [Session.ConnectParams.PacketSize,
                                     MaxHeaderSize]);
}
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> Search session...');
{$ENDIF}
  SessionFound := False;
// Does Session exist?
  Sessions:=FSessions.LockList;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> Locked');
{$ENDIF}
  try
   for i:=0 to Sessions.Count-1 do
    begin
     ClientSession := Sessions.Items[i];
     if ClientSession.Session = Session then
      begin
//       inc(ClientSession.Status);  // ACR v.5.90
//       EnterCSect(ClientSession.FCSect);
       SessionFound := True;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> session found');
{$ENDIF}
       break;
      end;
    end;
  finally
   FSessions.UnlockList;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> UnLocked');
{$ENDIF}
  end;
  if not SessionFound then
// No. Does Connection exist?
   begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> session not found');
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
aaWriteToLog('TACRClientConnectionManager.Connect> Connection found, Session = '+IntToStr(Integer(Session)));
{$ENDIF}
           Network := ClientConnection.Network;
           if Network.PacketSize < Session.ConnectParams.PacketSize then
            begin
             EnterCSect(Network.FCSect);
             Network.PacketSize := Session.ConnectParams.PacketSize;
             LeaveCSect(Network.FCSect);
            end;
           break;
          end;
        end;
      if Network = nil then
       begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> Connection not found, Session = '+IntToStr(Integer(Session)));
{$ENDIF}
        New(ClientConnection);
        EnterCSect(FCSect);
        inc(FConnectionID);
        ClientConnection.ConnectionID := FConnectionID;
        LeaveCSect(FCSect);
        IncThreadCount;
        if Session.ConnectParams.Protocol = 1 then
          Protocol := ACR_UDP
        else
          Protocol := ACR_TCP;
        ClientConnection.Network := TACRNetwork.Create(Self, Protocol);
        EnterCSect(ClientConnection.Network.FCSect);
        ClientConnection.Network.LocalPort := Session.ConnectParams.LocalPort;
        ClientConnection.Network.PacketSize := Session.ConnectParams.PacketSize;
        Session.FConnectParams.LocalPort := ClientConnection.Network.LocalPort; // if port is already in use
        LeaveCSect(ClientConnection.Network.FCSect);
// Add new connection to Connections list
        Connections.Add(ClientConnection);
       end;
      finally
       FConnections.UnlockList;
      end;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> ConnectionID = '+IntToStr(ClientConnection.ConnectionID));
{$ENDIF}
     end; // Set new connection
// No Session, Connection Exists
    New(ClientSession);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('new session: @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
    ClientSession.Status := ACRInUse;
    InitCSect(ClientSession.FCSect,'ClientSession, from '+ClientConnection.Network.LocalHost+':'+IntToStr(ClientConnection.Network.LocalPort)+' to '+ClientConnection.Network.RemoteHost+':'+IntToStr(ClientConnection.Network.RemotePort),false);
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
      ClientSession.Packets := TACRList.Create;
      ClientSession.Packets.Capacity := ACRDefaultPacketsInAnswer; // Allocate some place in list
      ClientSession.Packets.Clear; // Set Items to nil
  (*
      ClientSession.MsgPackets := TACRList.Create;
      ClientSession.MsgPackets.Capacity := ACRDefaultMsgPacketsInAnswer; // Allocate some place in list
      ClientSession.MsgPackets.Clear; // Set Items to nil
  *)
      ClientSession.PacketIDsToResend := TACRThreadIntArray.Create;
      ClientSession.MsgPacketIDsToResend := TACRThreadIntArray.Create;
  (*
      ClientSession.ListeningThreads := TACRThreadList.Create;
      ClientSession.MsgListeningThreads := TACRThreadList.Create;
      ClientSession.LiveListenerThreads := 0;
  *)
  {$IFDEF LOG_CLIENT_CONNECT}
  aaWriteToLog('           ListeningThreads created in @ClientSession='+IntToStr(Integer(ClientSession)));
  {$ENDIF}
      ClientSession.ResendRequestThread := nil;
  (*
      ClientSession.MsgResendRequestThread := nil;
      ClientSession.MsgControlCode := ACRExecute;
  *)
      ClientSession.ControlCode := ACRExecute;
      ClientSession.AnswerStatus := ACRNo;
  // Add new Session
      FSessions.Add(ClientSession);
  {$IFDEF LOG_CLIENT_CONNECT}
  aaWriteToLog('TACRClientConnectionManager.Connect> ');
  {$ENDIF}
      if not ListenOnly then
       begin
  // Connect to server
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> SendConnectRequest...');
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
        if (not Raised) and (ClientSession.SendStatus <> ACRSent) then
         begin
  {$IFDEF LOG_CLIENT_DISCONNECT}
  aaWriteToLog('TACRClientConnectionManager.Connect - DoDisconnect');
  {$ENDIF}
          DoDisconnect(Session);
          raise EACRException.Create(40039, ErrorRCannotConnetToServer,
                                    [Session.ConnectParams.RemoteHost,
                                     Session.ConnectParams.RemotePort,
                                     Session.ConnectParams.LocalPort,
                                     Session.ConnectParams.ServerID]);
         end;
        if ClientSession.ControlCode = ACRTerminate then
         begin
          Exit;
         end;
        ClientSession.PacketIDsToResend.SetSize(0); // Do not request broken packets
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect - Receive buffer...');
{$ENDIF}
        ReceiveBuffer(Session, Buffer, BufferSize);
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect - Received!');
{$ENDIF}
    // Get connection parameters
        if ClientSession.Session.ConnectParams.UseServerSettings then
         begin
          ConnectParams := PACRConnectParams(Buffer);
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
          EnterCSect(ClientConnection.Network.FCSect);
          if ClientConnection.Network.PacketSize < ClientSession.Session.ConnectParams.PacketSize then
            ClientConnection.Network.PacketSize := ClientSession.Session.ConnectParams.PacketSize;
          LeaveCSect(ClientConnection.Network.FCSect);
          ClientSession.Session.FConnectParams.CompressionAlgorithm := ConnectParams.CompressionAlgorithm;
          ClientSession.Session.FConnectParams.CompressionMode := ConnectParams.CompressionMode;
          SizeParams := SizeOf(TACRConnectParams);
         end
        else
         begin
          ConnectionParams := PACRConnectionParams(Buffer);
          ClientSession.Session.FConnectParams.PacketSize := ConnectionParams.PacketSize;
          EnterCSect(ClientConnection.Network.FCSect);
          if ClientConnection.Network.PacketSize < ClientSession.Session.ConnectParams.PacketSize then
            ClientConnection.Network.PacketSize := ClientSession.Session.ConnectParams.PacketSize;
          LeaveCSect(ClientConnection.Network.FCSect);
          ClientSession.Session.FConnectParams.CompressionAlgorithm := ConnectionParams.CompressionAlgorithm;
          ClientSession.Session.FConnectParams.CompressionMode := ConnectionParams.CompressionMode;
          SizeParams := SizeOf(TACRConnectionParams);
         end;
        // SessionID
        Move((Buffer+SizeParams)^, SessionID, SizeOf(SessionID));
        ConnectionID := -MAXINT;
  {$IFDEF MsgCommunicator}
        if (BufferSize>=(SizeOf(TACRConnectParams))+SizeOf(SessionID)+SizeOf(ConnectionID)) then
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
     if not Raised then
      begin
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> Leave CS...');
{$ENDIF}
       LeaveCSect(ClientSession.FCSect);
       dec(ClientSession.Status);
      end;
{$IFDEF LOG_CLIENT_CONNECT}
aaWriteToLog('TACRClientConnectionManager.Connect> finally Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
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
aaWriteToLog('TACRClientConnectionManager.Connect - FINISH');
{$ENDIF}
end; // Connect


//------------------------------------------------------------------------------
// TuneConnectionParamaters
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.TuneConnectionParamaters(ClientSession:  PACRClntSession);
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
      BufferSize := (ClientSession.Session.ConnectParams.PacketSize-SizeOf(TACRPacketHeader)) * ClientSession.Session.ConnectParams.TestPacketCount;
      Buffer := MemoryManager.GetMem(BufferSize);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TACRClientConnectionManager.Connect - NETWORK TUNNING:');
aaWriteToLog('Buffer size = '+IntToStr(BufferSize)+' Bytes');
{$ENDIF}
      try
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TACRClientConnectionManager.Connect - NETWORK TUNNING - Sending...');
{$ENDIF}
      SendBuffer(ClientSession.Session,Buffer,BufferSize,ACRTunning);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TACRClientConnectionManager.Connect - NETWORK TUNNING - Sent!');
{$ENDIF}
      finally
       MemoryManager.FreeAndNilMem(Buffer);
      end;
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TACRClientConnectionManager.Connect - NETWORK TUNNING - Receiving...');
{$ENDIF}
      ReceiveBuffer(ClientSession.Session,Buffer,BufferSize);
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TACRClientConnectionManager.Connect - NETWORK TUNNING - Received!');
{$ENDIF}
      ClientSession.AnswerTime := GetTickCount - StartTime;
      ClientSession.Session.FConnectParams.SendTimeOut := ClientSession.AnswerTime * 4;
      if ClientSession.Session.ConnectParams.SendTimeOut < ClientSession.Session.ConnectParams.MinSendTimeOut then
        ClientSession.Session.FConnectParams.SendTimeOut := ClientSession.Session.ConnectParams.MinSendTimeOut;
      ClientSession.Session.FConnectParams.ReceiveTimeOut := ClientSession.Session.ConnectParams.SendTimeOut;
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog('TACRClientConnectionManager.Connect - NETWORK TUNNING:');
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
       SendBuffer(ClientSession.Session,Buffer,BufferSize,ACRServerSessionTunning);
      finally
       MemoryManager.FreeAndNilMem(Buffer);
      end;
     end;
// end of network testing
end; // TuneConnectionParamaters


//------------------------------------------------------------------------------
// SendPing
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.SendPing(
                          ClientSession: PACRClntSession
                          );
var
  Header:               PACRPacketHeader;
  Connections:          TACRList;
  ClientConnection:     PACRClntConnection;
  i:                    Integer;
begin
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.SendPing - START');
{$ENDIF}
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
   Header.ControlCode := ACRPing;
   Header.Signature := ACRClientPacketSign;
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
aaWriteToLog('TACRClientConnectionManager.SendPing - Enter...');
{$ENDIF}
   EnterCSect(ClientConnection.Network.FCSect);
   try
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.SendPing - Entered!');
{$ENDIF}
    ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
    ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.SendPing - Send...');
aaWriteToLog('TACRClientConnectionManager.SendPing> ClientSession.Session.ConnectParams.RemoteHost="'+ClientSession.Session.ConnectParams.RemoteHost+'"');
aaWriteToLog('TACRClientConnectionManager.SendPing> ClientSession.Session.ConnectParams.RemotePort='+IntToStr(ClientSession.Session.ConnectParams.RemotePort));
{$ENDIF}
    ClientConnection.Network.SendBuffer(PAnsiChar(Header), SizeOf(TACRPacketHeader));
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.SendPing - Sent!');
{$ENDIF}
   finally
    LeaveCSect(ClientConnection.Network.FCSect);
   end;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.SendPing - Left!');
{$ENDIF}
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog('TACRClientConnectionManager.SendPing - FINISH');
{$ENDIF}
 end;
end;// SendPing


//------------------------------------------------------------------------------
// SendAcknowledgement
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.SendAcknowledgement(
                          ClientSession: PACRClntSession;
                          Msg:           Boolean = False;
                          CurrentRequestID:     Integer = -1
                          );
var
  Header:               PACRPacketHeader;
  Connections:          TACRList;
  ClientConnection:     PACRClntConnection;
  i:                    Integer;
begin
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - START');
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - CS entered');
{$ENDIF}
 try
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
   if Msg then
     Header.ControlCode := ACRMessageReceived
   else
     Header.ControlCode := ACRAllPacketsReceived;
   Header.Signature := ACRClientPacketSign;
   Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
   Header.ConnectionID := ClientSession.RemoteConnectionID;
   Header.SessionID := ClientSession.ServerSessionID;
{$IFDEF MsgCommunicator}
   if TACRClientSession(ClientSession.Session).Direct then
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
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - Enter...');
{$ENDIF}
   EnterCSect(ClientConnection.Network.FCSect);
   try
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - Entered!');
{$ENDIF}
    ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
    ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - Send...');
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement> ClientSession.Session.ConnectParams.RemoteHost="'+ClientSession.Session.ConnectParams.RemoteHost+'"');
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement> ClientSession.Session.ConnectParams.RemotePort='+IntToStr(ClientSession.Session.ConnectParams.RemotePort));
{$ENDIF}
    ClientConnection.Network.SendBuffer(PAnsiChar(Header), SizeOf(TACRPacketHeader));
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - Sent!');
{$ENDIF}
   finally
    LeaveCSect(ClientConnection.Network.FCSect);
   end;
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendAcknowledgement - Left!');
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
procedure TACRClientConnectionManager.SendConnectAckn(
                          ClientSession:        PACRClntSession;
                          ClientConnection:     PACRClntConnection;
                          CurrentRequestID:     Integer = -1
                                                      );
var
  Buffer,
  Buf:                            PAnsiChar;
  BufferSize,
  BufSize,
  SizeSID, SizeCID, SizeParams:   Integer;
  ConnectionParams:               TACRConnectionParams;
  RequestID:                      Integer;
begin
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> START');
{$ENDIF}
 inc(ClientSession.Status);
 EnterCSect(ClientSession.FCSect);
 try
  if ClientSession.Session.ConnectParams.UseServerSettings then
   begin
    Buf := @ClientSession.Session.FConnectParams;
    SizeParams := SizeOf(TACRConnectParams);
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
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> SessionID='+IntToStr(ClientSession.Session.SessionID));
aaWriteToLog('SizeSID='+IntToStr(SizeSID)+', SizeParams='+IntToStr(SizeParams)+', BufferSize='+IntToStr(BufferSize));
{$ENDIF}
  try
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> copy connection parameters...');
{$ENDIF}
   Move(Buf^, Buffer^, SizeParams); // copy connection parameters
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> copy SessionID...');
{$ENDIF}
   Move(ClientSession.Session.SessionID, (Buffer+SizeParams)^, SizeSID);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> copy ConnectionID...');
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
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> CompressAndEncryptBuffer...');
{$ENDIF}
   CompressAndEncryptBuffer(ClientSession.Session, Buffer, BufferSize, Buf, BufSize);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> DoSendBuffer...');
{$ENDIF}
   try
    DoSendBuffer(ClientSession, ClientConnection, Buf, BufSize, ACRConnected);
   finally
    if Buf<>Buffer then
      MemoryManager.FreeAndNilMem(Buf);
   end;

   if CurrentRequestID >= 0 then
     ClientSession.CurrentRequestID := RequestID;

   ClientSession.AnswerStatus := ACRNo;
  finally
   MemoryManager.FreeAndNilMem(Buffer);
  end;
 finally
  LeaveCSect(ClientSession.FCSect);
  dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_CONNECT_ACKN}
aaWriteToLog('TACRClientConnectionManager.SendConnectAckn> FINISH');
{$ENDIF}
 end;
end;// SendConnectAckn


//------------------------------------------------------------------------------
// IsAuthorizationBufferValid
//------------------------------------------------------------------------------
function TACRClientConnectionManager.IsAuthorizationBufferValid(
                      CryptoInfo: TACRCryptoInfo;
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
procedure TACRClientConnectionManager.SendDisconnectRequest(
                                    ClientSession: PACRClntSession;
                                    WaitForAnswer: Boolean = True);
var
  Header:               PACRPacketHeader;
  Connections:          TACRList;
  ClientConnection:     PACRClntConnection;
  Retry, i:             Integer;
  SleepTime,
  Delay,
  StartTime:            Cardinal;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> START');
{$ENDIF}
  ClientSession.AnswerStatus := ACRNo;
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
   Header.ControlCode := ACRDisconnect;
   Header.Signature := ACRClientPacketSign;
   Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
   Header.ConnectionID := ClientSession.RemoteConnectionID;
   Header.SessionID := ClientSession.ServerSessionID;
{$IFDEF MsgCommunicator}
   if TACRClientSession(ClientSession.Session).Direct then
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
   SleepTime := ClientSession.Session.ConnectParams.WaitForSendSleep;
   Delay := ClientSession.Session.ConnectParams.DisconnectDelay;
   ClientSession.SendStatus := ACRNotSent;
   try
    repeat
     if ClientSession.Session.ConnectParams.RemoteHost = '' then
       Exit; // Session already freed
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> Enter Network.FCSect...');
{$ENDIF}
     EnterCSect(ClientConnection.Network.FCSect);
     try
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> RemoteHost='+ClientSession.Session.ConnectParams.RemoteHost);
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> RemotePort='+IntToStr(ClientSession.Session.ConnectParams.RemotePort));
{$ENDIF}
      ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
      ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
      ClientConnection.Network.SendBuffer(PAnsiChar(Header), SizeOf(TACRPacketHeader));
     finally
      LeaveCSect(ClientConnection.Network.FCSect);
     end;
     if not WaitForAnswer then
       Exit;
     if IsDesignMode then
       break;
     StartTime := GetTickCount;
     while ((GetTickCount - StartTime) < Delay) do // pause
      begin
        if ClientSession.ControlCode = ACRTerminate then
          Exit;
        if ClientSession.SendStatus <> ACRSent then
         begin
          LeaveCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> sleep...');
{$ENDIF}
          if ((GetTickCount - StartTime) > ACRMaxSendShortSleepTime) then
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
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> Retry # '+IntToStr(Retry));
{$ENDIF}
    until (Retry > ClientSession.Session.ConnectParams.DisconnectRetryCount);
   if ClientSession.SendStatus <> ACRSent then
{$IFDEF MsgCommunicator}
    if TACRClientSession(ClientSession.Session).Direct then
      raise EACRException.Create(40024, ErrorRCannotDisconnect,
                   ['client session with user', TACRClientSession(ClientSession.Session).UserID,
                    ClientSession.Session.ConnectParams.DisconnectRetryCount,
                    ClientSession.Session.ConnectParams.DisconnectDelay])
    else
{$ENDIF}
      raise EACRException.Create(40024, ErrorRCannotDisconnect,
                   ['server session', ClientSession.ServerSessionID,
                    ClientSession.Session.ConnectParams.DisconnectRetryCount,
                    ClientSession.Session.ConnectParams.DisconnectDelay]);
   finally
{$IFDEF LOG_CLIENT_DISCONNECT}
if ClientSession.SendStatus = ACRSent then
aaWriteToLog('CLIENT: SendDisconnectRequest> Answer is received')
else
aaWriteToLog('CLIENT: SendDisconnectRequest> Answer was not received');
{$ENDIF}
   end;
  finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> free...');
{$ENDIF}
   MemoryManager.FreeAndNilMem(Header);
  end;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> FINISH');
{$ENDIF}
end;// SendDisconnectRequest


//------------------------------------------------------------------------------
// DeleteSession
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.DeleteSession(ClientSession: PACRClntSession);
var
  StartTime:            Cardinal;
  i, Count:             Integer;
  Packet:               PACRPacket;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> START');
aaWriteToLog('DeleteSession> @ClientSession = '+IntToHex(Integer(ClientSession),8));
{$ENDIF}
 EnterCSect(ClientSession.FCSect);
 try
  if ClientSession.CurrentRequestID = ACRTerminate then // <0, illegal value not used
   begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> session is already deleting - FINISH');
{$ENDIF}
    Exit; // session is already deleting - FINISH
   end;
// block deleting ClientSession
  ClientSession.CurrentRequestID := ACRTerminate;
// block using ClientSession
  ClientSession.ControlCode := ACRTerminate;
// allow to finish a waiting for sending
  ClientSession.SendStatus := ACRSent;
// wait for vacant ClientSession
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> wait for vacant ClientSession...');
{$ENDIF}
  StartTime := GetTickCount;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> ClientSession.Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8)+', wait for vacant...');
{$ENDIF}
  repeat
   if (ClientSession.Status <= ACRVacant) then
     break;
   LeaveCSect(ClientSession.FCSect);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> sleep(0)');
{$ENDIF}
   sleep(0);
   EnterCSect(ClientSession.FCSect);
  until ((GetTickCount-StartTime) >= ClientSession.Session.ConnectParams.WaitForTimeOut);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> ClientSession.Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
  if (ClientSession.Status >= ACRInUse) then
    raise EACRException.Create(40155, ErrorRClientSessionDelete, ['@='+IntToHex(Integer(ClientSession),8),ClientSession.Status]);
// close ResendRequestThread
  CloseThread(@(ClientSession.ResendRequestThread),ACRClientConnectionManager,ErrorRResendRequestThread);
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
aaWriteToLog('TACRClientConnectionManager.DeleteSession> Packet # 0: Free Buffer...');
{$ENDIF}
      if Packet.Buffer <> nil then
        MemoryManager.FreeAndNilMem(Packet.Buffer);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> Packet # 0: Dispose Packet...');
{$ENDIF}
      Dispose(Packet);
     end;
   end;
  ClientSession.Packets.Free;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DeleteSession> Packets have been deleted');
{$ENDIF}
  ClientSession.PacketIDsToResend.Free;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('DeleteSession> PacketIDsToResend freed');
{$ENDIF}
  ClientSession.MsgPacketIDsToResend.Free;
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
aaWriteToLog('TACRClientConnectionManager.DeleteSession> FINISH');
{$ENDIF}
end; // DeleteSession


//------------------------------------------------------------------------------
// DoDisconnect
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.DoDisconnect(Session: TACRBaseSession);
var
  Connections:          TACRList;
  Sessions:             TACRList;
  ClientConnection:     PACRClntConnection;
  ClientSession:        PACRClntSession;
  ConnectionID:         TACRConnectionID;
  i, Count:             Integer;
  NoSessions:           Boolean;
  NoConnections:        Boolean;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> START');
if Session = nil then
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> session is nil - not initialized or prepared for deleting - FINISH');
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
       ClientSession.ControlCode := ACRTerminate;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> Remove SessionID = '+IntToStr(ClientSession.Session.SessionID));
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
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> session not found!!!')
else
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> session found');
{$ENDIF}
  if not NoSessions then
   begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> DeleteSession...');
{$ENDIF}
     DeleteSession(ClientSession);
// Search for another session using the same connection
     NoSessions := True;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> Sessions Count = '+IntToStr(Count));
{$ENDIF}
    Sessions:=FSessions.LockList;
    try
     Count := Sessions.Count;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> Sessions Count = '+IntToStr(Count));
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
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> Freed ConnectionID = '+IntToStr(ClientConnection.ConnectionID));
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
aaWriteToLog('TACRClientConnectionManager.DoDisconnect> FINISH');
{$ENDIF}
end; // DoDisconnect


//------------------------------------------------------------------------------
// Disconnect
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.Disconnect(Session: TACRBaseSession;
                                                  ListenOnly: Boolean = False);
var
  Sessions:             TACRList;
  ClientSession:        PACRClntSession;
  i:                    Integer;
  Found:                Boolean;
begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.Disconnect - START');
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
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> WaitForSendingThreads...');
{$ENDIF}
         WaitForSendingThreads(TACRNetworkSession(ClientSession.Session));
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> lock session...');
{$ENDIF}
         inc(ClientSession.Status);
         EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.SendDisconnectRequest> session locked');
{$ENDIF}
         break;
        end;
      end;
    finally
     FSessions.UnlockList;
    end;
    if not Found then
      raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
    try
     ClientSession.ControlCode := ACRTerminate;
     inc(ClientSession.CurrentRequestID);
     SendDisconnectRequest(ClientSession);
    finally
     LeaveCSect(ClientSession.FCSect);
     dec(ClientSession.Status);
    end;
   end; // Send disconnect request
 finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.Disconnect - DoDisconnect');
{$ENDIF}
  DoDisconnect(Session);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientConnectionManager.Disconnect - FINISH');
{$ENDIF}
 end;
end; // Disconnect


//------------------------------------------------------------------------------
// DisconnectAll
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.DisconnectAll;
var
  Sessions:             TACRList;
  Connections:          TACRList;
  ClientSession:        PACRClntSession;
  ClientConnection:     PACRClntConnection;
  i:                    Integer;
begin
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> START');
{$ENDIF}
{$IFDEF CONNECTION_TEST}
  Exit;
{$ENDIF}
// delete sessions
  while FSessions.Count >= 1 do
   begin
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> lock sessions....');
{$ENDIF}
    Sessions:=FSessions.LockList;
    try
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> get session...');
{$ENDIF}
     ClientSession := Sessions.Items[0];
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> delete session...');
{$ENDIF}
     FSessions.Delete(0);
     inc(ClientSession.Status);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> enter CS...');
{$ENDIF}
     EnterCSect(ClientSession.FCSect);
    finally
     FSessions.UnlockList;
    end;
    try
    ClientSession.ControlCode := ACRTerminate;
     try
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> SendDisconnectRequest...');
{$ENDIF}
      SendDisconnectRequest(ClientSession, False);
     except
// do not raise
     end;
    finally
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> Leave CS...');
{$ENDIF}
     LeaveCSect(ClientSession.FCSect);
     dec(ClientSession.Status);
    end;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> All sessions terminated');
{$ENDIF}
    DeleteSession(ClientSession);
   end; // sessions
// delete connections
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> Connections');
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
aaWriteToLog('TACRClientConnectionManager.DisconnectAll> FINISH');
{$ENDIF}
end; // DisconnectAll


//------------------------------------------------------------------------------
// WaitForSendingThreads
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.WaitForSendingThreads(Session: TACRNetworkSession);
{$IFDEF MsgCommunicator}
var
  SendingThreads:     TACRList;
  NoMineThreads:      Boolean;
  i:                  Integer;
{$ENDIF}
begin
// Msg v.4.42 Windows 7 problems
exit;
  while (FSendingThreads.Count > 0) do
   begin
{$IFDEF LOG_CLIENT_WAIT_SENDING_THREADS}
aaWriteToLog('ACRConnection> TACRClientConnectionManager.WaitForSendingThreads> Count = '+IntToStr(FSendingThreads.Count));
{$ENDIF}
{$IFDEF MsgCommunicator}
    NoMineThreads := True;
    SendingThreads := FSendingThreads.LockList;
    try
     for i := SendingThreads.Count-1 downto 0 do
       if TACRSendingThread(SendingThreads.Items[i]).FSession.FOwnerComponent
        = TACRClient(Session.FOwnerComponent) then
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
procedure TACRClientConnectionManager.SendMessage(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TACRControlCode = ACRMessage
                                                  );
{
var
  Buf:  PAnsiChar;
}
begin
 try
{
  if (TACRCompressionAlgorithm(Session.ConnectParams.CompressionAlgorithm) <> acaNone)
  or (Session.ConnectParams.CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None)
  then
   begin
    Buf := MemoryManager.GetMem(BufferSize);
    Move(Buffer^,Buf^,BufferSize);
    SendBuffer(Session, Buf, BufferSize, ACRMessage);
    MemoryManager.FreeAndNilMem(Buf);
   end
  else
}
  SendBuffer(Session, Buffer, BufferSize, Code);
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> TACRClientConnectionManager.SendMessage - Error:');
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
procedure TACRClientConnectionManager.SendBuffer(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = ACRNewRequest
                                                  );
var
  Connections:          TACRList;
  Sessions:             TACRList;
  ClientConnection:     PACRClntConnection;
  ClientSession:        PACRClntSession;
  ConnectionID:         TACRConnectionID;
  i:                    Integer;
  Found:                Boolean;
  Buf:                  PAnsiChar;
  BufSize:              Integer;
  err:                  AnsiString;

procedure Raise40040;
begin
  raise EACRException.Create(40040, ErrorRCannotSendToServer,
                                [ClientSession.Session.ConnectParams.RemoteHost,
                                 ClientSession.Session.ConnectParams.RemotePort,
                                 ClientSession.Session.ConnectParams.LocalPort,
                                 ClientSession.Session.ConnectParams.ServerID,
                                 err]);
end;

begin
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> START');
{$ENDIF}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> START');
{$ENDIF}
 try
  if Session=nil then
   raise EACRException.Create(40156, ErrorRSessionIsNil);
  if (Session.ConnectParams.PacketSize < SizeOf(TACRPacketHeader)) then
   raise EACRException.Create(40020, ErrorRPacketSizeTooSmall,
                                    [Session.ConnectParams.PacketSize,
                                     SizeOf(TACRPacketHeader)]);
//  ClientSession := FindSession(Session);
  Found := False;
  Sessions := FSessions.LockList;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> Sessions locked');
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
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> entering ClientSession.FCSect...');
{$ENDIF}
  inc(ClientSession.Status);
  EnterCSect(ClientSession.FCSect);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> ClientSession.FCSect entered!');
{$ENDIF}
  try
    Found := False;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> Lock Connections...');
{$ENDIF}
    Connections := FConnections.LockList;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> Connections Locked!');
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
aaWriteToLog('TACRClientConnectionManager.SendBuffer> Connections Unlocked!');
{$ENDIF}
    end;
    if not Found then
      raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('CLIENT>>> '+IntToStr(ClientSession.CurrentRequestID + 1)+' :');
aaWriteBufferToLog(Buffer,BufferSize);
{$ENDIF}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> Code = '+IntToStr(Code));
{$ENDIF}
    if (Code >= ACRNewRequest) then
     begin
      LeaveCSect(ClientSession.FCSect);
      dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> WaitForSendingThreads');
{$ENDIF}
      WaitForSendingThreads(TACRNetworkSession(ClientSession.Session)); // wait for sending ackn of previous command receiving
      inc(ClientSession.Status);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> 2 - Enter CS...');
{$ENDIF}
      EnterCSect(ClientSession.FCSect);
     end;
    if (Code = ACRConnect)
    or (Code = ACRTunning)
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
        i := (BufSize div (ClientSession.Session.ConnectParams.PacketSize-SizeOf(TACRPacketHeader)));
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
aaWriteToLog('TACRClientConnectionManager.SendBuffer - NETWORK TUNNING:');
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
aaWriteToLog('TACRClientConnectionManager.SendBuffer> free Buf...');
{$ENDIF}
     if Buf <> Buffer then
      if Code <> ACRConnect then
       MemoryManager.FreeAndNilMem(Buf);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> freed!');
{$ENDIF}
    end;
  finally
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> leave CSect...');
{$ENDIF}
   LeaveCSect(ClientSession.FCSect);
   dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer - FINISH');
{$ENDIF}
  end;
 except
  on E: EACRException do
   begin
    ClientSession.Session.DoOnError(40040,e.NativeError,E.Message);
    err := E.Message;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRClientConnectionManager.SendBuffer - ERROR 40040 - CannotSendToServer: '+err);
{$ENDIF}
    Raise40040;
   end;
  on E: Exception do
   begin
    ClientSession.Session.DoOnError(40040,-1,E.Message);
    err := E.Message;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRClientConnectionManager.SendBuffer - ERROR 40040 - CannotSendToServer: '+err);
{$ENDIF}
    Raise40040;
   end
  else
    ClientSession.Session.DoOnError(40040);
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRClientConnectionManager.SendBuffer - ERROR 40040 - CannotSendToServer: '+err);
{$ENDIF}
    Raise40040;
 end;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientConnectionManager.SendBuffer> FINISH');
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// DoSendBuffer
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.DoSendBuffer(
                          ClientSession:    PACRClntSession;
                          ClientConnection: PACRClntConnection;
                          Buffer:           PAnsiChar;
                          BufferSize:       Integer;
                          Code:             Integer = ACRNewRequest
                                                  );
var
  Header:               PACRPacketHeader;
  Packets:              TACRList;
  Packet:               PACRPacket;
  BytesSent, DataSize:  Integer;
  i:                    Integer;
  msgStatus:            PACRMessageStatus;
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
 EnterCSect(ClientConnection.Network.FCSect);
 try
   ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
   ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
   ClientConnection.Network.SendBuffer(Packet.Buffer, Packet.BufferSize);
 finally
  LeaveCSect(ClientConnection.Network.FCSect);
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
  PacketIDsToResend:    TACRThreadIntArray;
label
  Resend;
begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> waits for all packets');
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter12);
aaStartTime(time12);
try
{$ENDIF}
 try
  if Code = ACRMessage then
    PacketIDsToResend := ClientSession.MsgPacketIDsToResend
  else
    PacketIDsToResend := ClientSession.PacketIDsToResend;
  if not ((Code = ACRConnect) or (Code = (ACRConnect + ACRLastPacket))) then
   begin
{
// code to force push up sending in case of more than 10 packets message
    if (Code = ACRMessage)
    or (Code = ACRMessageAbort)
    then
     begin
      if (ClientSession.MsgSendStatus <> ACRSent) then
       sleep(MsgFirstResendPushUpTimeout);
      if (ClientSession.MsgSendStatus <> ACRSent) then
        FirstResend;
     end
    else
     begin
      if (ClientSession.SendStatus <> ACRSent) then
       sleep(MsgFirstResendPushUpTimeout);
      if (ClientSession.SendStatus <> ACRSent) then
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
          if (Code = ACRMessage)
          or (Code = ACRMessageAbort) then
           begin
            if ClientSession.MsgSendStatus = ACRSent then
             begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> MsgSendStatus = ACRSent, FINISH');
{$ENDIF}
              Exit;
             end;
           end
          else
            if ClientSession.SendStatus = ACRSent then
             begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> SendStatus = ACRSent, FINISH');
{$ENDIF}
              Exit;
             end;
          if ClientSession.ControlCode = ACRTerminate then
           begin
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT-DoSendBuffer-WaitForSent> ControlCode = ACRTerminate, EXCEPTION');
{$ENDIF}
            raise EACRException.Create(err, ErrorRClientSessionTerminated,[Integer(ClientSession.Session.SessionID)]);
           end;
          if (GetTickCount - StartTime) > ClientSession.Session.ConnectParams.SendTimeOut then
           begin
{$IFDEF MsgCommunicator}
            if TACRClientSession(ClientSession.Session).Direct then
            raise EACRException.Create(40099, ErrorRTimeOutSendDirectly,
                ['message', TACRClientSession(ClientSession.Session).RemoteUser.UserID,
                            ClientSession.Session.ConnectParams.SendTimeOut])
            else
{$ENDIF}
            raise EACRException.Create(40077, ErrorRTimeOutSending,
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
          if ((GetTickCount - StartTime) > ACRMaxSendShortSleepTime) then
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
       EnterCSect(ClientConnection.Network.FCSect);
       try
Resend:
         ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
         ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
         if ClientSession.ControlCode = ACRTerminate then
          begin
           raise EACRException.Create(err, ErrorRClientSessionTerminated,[Integer(ClientSession.Session.SessionID)]);
          end;
         try
          ClientConnection.Network.SendBuffer(Packet.Buffer, Packet.BufferSize);
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('Old Delay = '+IntToStr(Delay));
{$ENDIF}
          if i<0 then  // No packets to resend, increase pause
            Delay := Delay * 2
          else // Restore default pause in case of packets resending
            Delay := ClientSession.Session.ConnectParams.ResendDelay;
          if Delay = 0 then
            Delay := ACRResendDelay;
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
         LeaveCSect(ClientConnection.Network.FCSect);
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
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
finally
aaStopTime(time12);
end;
{$ENDIF}
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('CLIENT received all the packets');
{$ENDIF}
end; // WaitForSent

procedure CheckTermination;
begin
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer.CheckTermination> BEGIN');
{$ENDIF}
  try
    if ClientSession.ControlCode = ACRTerminate then
     begin
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer.CheckTermination> 40080');
{$ENDIF}
      raise EACRException.Create(err, ErrorRClientSessionTerminated,[Integer(ClientSession.Session.SessionID)]);
     end;
  finally
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer.CheckTermination> END');
{$ENDIF}
  end;
end; // CheckTermination

begin // DoSendBuffer
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter11);
aaStartTime(time11);
{$ENDIF}

{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> START');
{$ENDIF}
try
// ClientSession.FCSect is already locked in caller (SendBuffer, Connect)
 try
  err := 40080;
  if (Code = ACRMessage)
  or (Code = ACRMessageAbort) then
   begin
    inc(err);
    errStr := 'message';
   end
  else
   begin
    errStr := 'command';
   end;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> Refresh...');
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> ClientSession.Status = '+IntToStr(ClientSession.Status));
{$ENDIF}
(*
  SessionStatus := ClientSession.Status;
  while ClientSession.Status > ACRVacant do
*)
   begin
    LeaveCSect(ClientSession.FCSect);
    dec(ClientSession.Status);
   end;
  ACRRefresh; // ProcessMessages
//  while ClientSession.Status < SessionStatus do
   begin
    inc(ClientSession.Status);
    EnterCSect(ClientSession.FCSect);
   end;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> ClientSession.Status = '+IntToStr(ClientSession.Status));
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> Refreshed!');
{$ENDIF}
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
    DataSize := ClientSession.Session.ConnectParams.PacketSize - SizeOf(TACRPacketHeader);
    Header.Signature := ACRClientPacketSign;
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> Code='+IntToStr(Code));
  {$ENDIF}
    Header.Recepient := ClientSession.Session.ConnectParams.ServerID;
    Header.Sender := ClientConnection.Network.LocalClientID;
  //  Header.ConnectionID := ClientConnection.ConnectionID;
    Header.ConnectionID := ClientSession.RemoteConnectionID;
  ////  if Code=ACRConnect then
    Header.SessionID := ClientSession.ServerSessionID;
  {$IFDEF MsgCommunicator}
    if TACRClientSession(ClientSession.Session).Direct then
     if Code<>ACRConnected then
      Header.SessionID := ClientSession.Session.SessionID;
  {$ENDIF}
    Header.PacketID := 0;
    Header.ControlCode := Code;
    if (Code >= ACRNewRequest)
    or (Code = ACREcho)
    or (Code = ACRTunning)
    or (Code = ACRServerSessionTunning)
    then
     begin
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('==============================================================');
  aaWriteToLog('CLIENT IS SENDING NEW REQUEST TO SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
  aaWriteToLog('==============================================================');
  {$ENDIF}
      inc(ClientSession.CurrentRequestID);
      ClientSession.Packets.Count := 0; // Delete old packets receved since ReceiveBuffer finished
      ClientSession.AnswerStatus := ACRNo;
      if ClientSession.ControlCode = ACRSuspend then
        ClientSession.ControlCode := ACRExecute;
     end;
    Header.CurrentRequestID := ClientSession.CurrentRequestID;
    if (Code = ACRMessage)
    or (Code = ACRMessageAbort) then
     begin
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('==============================================================');
  aaWriteToLog('CLIENT IS SENDING MESSAGE # '+IntToStr(ClientSession.ClientMessageID)+' TO ID # '+IntToStr(ClientSession.Session.ConnectParams.ServerID));
  aaWriteToLog('==============================================================');
  {$ENDIF}
      ClientSession.MsgSendStatus := ACRNotSent;
      Header.CurrentRequestID := ClientSession.ClientMessageID;
(*
// add to SendMessages
      New(msgStatus);
      msgStatus.Status := ACRSending;
      msgStatus.MessageID := Header.CurrentRequestID;
      msgStatus.NetworkClientID := Header.Recepient;
      msgStatus.ConnectionID := Header.ConnectionID;
      msgStatus.SessionID := Header.SessionID;
      msgStatus.PacketIDsToResend := TACRThreadIntArray.Create;
      FSendMessages.Add(msgStatus);
*)
     end
    else
      ClientSession.SendStatus := ACRNotSent;
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('DoSendBuffer --------------------------------');
  aaWriteToLog('Header.ConnectionID = '+IntToStr(Header.ConnectionID));
  aaWriteToLog('Header.SessionID    = '+IntToStr(Header.SessionID));
  aaWriteToLog('Header.ControlCode  = '+IntToStr(Header.ControlCode));
  aaWriteToLog('DoSendBuffer --------------------------------');
  {$ENDIF}
  {$IFDEF LOG_CLIENT_SENDING}
  aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> create packets list...');
  {$ENDIF}
    Packets := TACRList.Create;
    BytesSent := 0;
    i := DataSize;
{
    if Code = ACRMessage then
     begin
//      ClientSession.MsgSendStatus := ACRNotSent;
     end
    else
      ClientSession.SendStatus := ACRNotSent;
}
    repeat
//    while BytesSent < BufferSize do
//     begin // Create and send all packets
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> create packet #'+IntToStr(Header.PacketID));
{$ENDIF}
      New(Packet);
      Packets.Add(Packet);
      Packet.Buffer := MemoryManager.GetMem(ClientSession.Session.ConnectParams.PacketSize);
      if BytesSent + DataSize > BufferSize then
       DataSize := BufferSize - BytesSent;
      Packet.BufferSize := DataSize + SizeOf(TACRPacketHeader);
      if BytesSent + DataSize = BufferSize then
        if Header.ControlCode <> ACRMessageAbort then
           Header.ControlCode := Header.ControlCode+ACRLastPacket;
      Move(Header^, Packet.Buffer^, SizeOf(TACRPacketHeader));
      Move(Pointer(Integer(Buffer)+Header.PacketID*i)^, (Packet.Buffer+SizeOf(TACRPacketHeader))^, DataSize);
      inc(Header.PacketID);
      // send packet
      EnterCSect(ClientConnection.Network.FCSect);
      try
       ClientConnection.Network.RemoteHost := ClientSession.Session.ConnectParams.RemoteHost;
       ClientConnection.Network.RemotePort := ClientSession.Session.ConnectParams.RemotePort;
       CheckTermination;
       ClientConnection.Network.SendBuffer(Packet.Buffer, Packet.BufferSize);
      finally
       LeaveCSect(ClientConnection.Network.FCSect);
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
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> packet sent');
{$ENDIF}
      // packet has been sent
      BytesSent := BytesSent + DataSize;
    until BytesSent >= BufferSize;
    if Code <> ACRConnected then
      WaitForSent(Code);
  finally
    if (Code = ACRMessage)
    or (Code = ACRMessageAbort) then
     begin
      inc(ClientSession.ClientMessageID);
{$IFDEF LOG_CLIENT_MESSAGE_RESEND}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> ClientSession.ClientMessageID = '+IntToStr(ClientSession.ClientMessageID));
{$ENDIF}
     end;
// Remove all sent packets and free memory
    for i:= 0 to Packets.Count - 1 do
     begin
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> free packet #'+IntToStr(i));
{$ENDIF}
      Packet := Packets.Items[i];
      MemoryManager.FreeAndNilMem(Packet.Buffer);
      Dispose(Packet);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> freed');
{$ENDIF}
     end;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> free packets...');
{$ENDIF}
    Packets.Free;
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> freed');
{$ENDIF}
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> free header...');
{$ENDIF}
    MemoryManager.FreeAndNilMem(Header);
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> freed');
{$ENDIF}
    CheckTermination;
  end;
 except
  if (Code = ACRMessage) then
   begin
{$IFDEF LOG_CLIENT_MESSAGE_RESEND}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> Abort Message...');
{$ENDIF}
    try
     dec(ClientSession.ClientMessageID);
     DoSendBuffer(ClientSession,ClientConnection,nil,0,ACRMessageAbort);
    except
    end;
   end; // message abort
  raise;
 end;
finally
{$IFDEF LOG_CLIENT_SENDING}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer - FINISH');
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time11);
{$ENDIF}
end;
end; // DoSendBuffer


//------------------------------------------------------------------------------
// if encryption algorithm <> acr_Cipher_None then allocate buffer, fill it and return size
// otherwise return BufferSize = 0
//------------------------------------------------------------------------------
procedure TACRClientConnectionManager.CreateAuthorizationBuffer(
                      CryptoInfo:     TACRCryptoInfo;
                      out Buffer:     PAnsiChar;
                      out BufferSize: Integer
                                    );
var ms:           TACRMemoryStream;
    buf:          PAnsiChar;
    crc32:        Cardinal;
    size:         Integer;
begin
  if CryptoInfo.CryptoAlgorithm = ACR_Cipher_None then
   begin
    BufferSize := 0;
    Exit;
   end;
  size := ACRDefaultAuthorizationBufferSize;
  buf := MemoryManager.GetMem(size);
  ms := TACRMemoryStream.Create;
  try
    ACRGenerateRandomBuffer(buf,size);
    crc32 := ACRCountCRC(0,buf,size);
    SaveDataToStream(size,SizeOf(crc32),ms,11319);
    SaveDataToStream(crc32,SizeOf(crc32),ms,11320);
    ACREncryptBuffer(CryptoInfo,buf,size);
    ms.WriteBuffer(buf^,size);
    BufferSize := ms.Size;
    Buffer := ms.Buffer;
    ms.SetBuffer(nil,0); // Msg 4.10 difference
    { TODO -oAlex : move to msg with new memory engine }
  finally
    ms.Free;
    MemoryManager.FreeAndNilMem(buf);
  end;
end; // CreateAuthorizationBuffer

// TACRClientConnectionManager



////////////////////////////////////////////////////////////////////////////////
//
// TACRClientPacketProcessorThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientPacketProcessorThread.Create(
                       Manager:       TACRClientConnectionManager
                                            );
begin
 try
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> create...');
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
destructor TACRClientPacketProcessorThread.Destroy;
begin
try
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> destroy...');
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
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      FManager.FPacketProcessorThread := TACRClientPacketProcessorThread.Create(FManager);
   end;
end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread.destroy> FINISHED');
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRClientPacketProcessorThread.Execute;
label
  CheckFullMessage,
  KillPacket;
var
  Header:               PACRPacketHeader;
  Connections:          TACRList;
{$IFDEF MsgCommunicator}
  Session:              TACRBaseSession;
  ClientSession2:       PACRClntSession;
{$ENDIF}
  ClientConnection:     PACRClntConnection;
  SessionFound,
  ConnectionFound:      Boolean;
  i, j, k:              Integer;
{$IFDEF MsgCommunicator}
  AuBufSize:            Integer;
  UserID:               Cardinal;
  ConnectionParams:     PACRConnectionParams;
  Application:          AnsiString;
{$ENDIF}
  Packets:              TACRList;
  NetworkPacket:        PACRNetworkPacket;
  Sessions:             TACRList;
  recvItem:             PACRRecvItem;
  msgStatus:            PACRMessageStatus;
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
aaWriteToLog('TACRClientPacketProcessorThread> Header.ControlCode = '+IntToStr(Header.ControlCode));
{$ENDIF}
 case Header.ControlCode of
  ACRMessageReceived,
  ACRMessagePacketResendRequest:
   begin
//    if (FManager.MessageStatus(Header,FManager.FSendMessages) <> ACRSending) then
    if ClientSession.MsgSendStatus = ACRSent then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> message is not sending now - kill packet');
{$ENDIF}
      Exit;
     end;
    if ClientSession.ClientMessageID <> Header.CurrentRequestID then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ClientMessageID='+IntToStr(ClientSession.ClientMessageID)+' <> CurrentRequestID='+IntToStr(Header.CurrentRequestID));
{$ENDIF}
      Exit;
     end;
   end;
  ACRMessage,
  ACRMessageAbort,
  (ACRMessage + ACRLastPacket):
   begin
    if (FManager.MessageStatus(Header,FManager.FRecvMessages) = ACRReceived) then // not receiving or a new
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> message already received - kill packet');
{$ENDIF}
      TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(True),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
      Exit;
     end;
   end;
  ACRDisconnect,
  ACRPing:
   begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> disconnect or ping request is anytime welcome');
{$ENDIF}
    Result := True;
    Exit;
   end;
  else
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> data packet');
{$ENDIF}
    if ClientSession.CurrentRequestID <> Header.CurrentRequestID then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ClientSession.CurrentRequestID = '+IntToStr(ClientSession.CurrentRequestID)+' <> Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
{$ENDIF}
      if ClientSession.CurrentRequestID > Header.CurrentRequestID then // old comand answer
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> old command - send ackn');
{$ENDIF}
        TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendAcknowledgement,
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
  Packets:              TACRList;
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
  if ClientSession.AnswerStatus <> ACRFull then // Last packet received, but answer is not full
   begin
    EnterCSect(ClientSession.FCSect);
    try
     if ClientSession.ResendRequestThread = nil then
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> : Start resending thread');
{$ENDIF}
       ClientSession.ResendRequestThread := TACRClientResendRequestThread.Create(FManager, ClientSession, NetworkPacket.Packet.Buffer, ClientConnection.Network, NetworkPacket.FromHost, NetworkPacket.FromPort);
      end;
    finally
     LeaveCSect(ClientSession.FCSect);
    end;
   end;
end; // StartResendRequest


////////////////////////////////////////////////////////////////////////////////
begin // TACRClientPacketProcessorThread.Execute
////////////////////////////////////////////////////////////////////////////////
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> START');
{$ENDIF}
try
 EmptyTime := aaGetTickCount;
 SleepTime := 1;
 repeat
  PacketAdded := False;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
//aaWriteToLog('TACRClientPacketProcessorThread.Execute> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
  sleep(SleepTime);
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
//aaWriteToLog('TACRClientPacketProcessorThread.Execute> up!');
{$ENDIF}
  if Terminated then
    Exit;
  try // except - continue loop
   Packets := FManager.FPacketQueue.LockList;
   try
    if Packets.Count = 0 then
     begin
      if (aaGetTickCount >= (EmptyTime + ACRPacketProcessTimeOut)) then
       begin
        SleepTime := 1; // To avoid 100% CPU usage
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
       end;
      Continue;
     end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter19);
aaStartTime(time19);
{$ENDIF}
    EmptyTime := aaGetTickCount;
    SleepTime := 0;
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> PacketQueue.Count = '+IntToStr(Packets.Count));
{$ENDIF}
    NetworkPacket := PACRNetworkPacket(Packets.Items[0]);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> delete NetworkPacket from queue...');
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
    if (NetworkPacket.Packet.BufferSize < SizeOf(TACRPacketHeader)) then
     begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('CLIENT: too small packet size = '+IntToStr(NetworkPacket.Packet.BufferSize));
{$ENDIF}
      Exit;
     end;
// Check sign
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> Check sign...');
{$ENDIF}
    if (Header.Signature <> ACRServerPacketSign)
{$IFDEF MsgCommunicator}
    and (Header.Signature <> ACRClientPacketSign)
{$ENDIF}
    then
      goto KillPacket;
// Check for errors
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread.Execute> CheckSum...');
{$ENDIF}
    if CheckSum(NetworkPacket.Packet.Buffer, NetworkPacket.Packet.BufferSize) <> Header.CheckSum then
     begin
      TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                                FManager,@TACRClientConnectionManager.PacketResendRequest,
                                Integer(NetworkPacket.Packet.Buffer),
                                Integer(Pointer(NetworkPacket.Network)),
                                Integer(PAnsiChar(NetworkPacket.FromHost)),
                                NetworkPacket.FromPort,0); // call PacketResendRequest
      goto KillPacket;
     end;
{$IFDEF MsgCommunicator}
// Check for direct connect request
    if    // first packet in multi-packet connect request
    ((Header.ControlCode=ACRConnect) and (Header.PacketID=0))
    or    // single-packet connect request
    ((Header.ControlCode=(ACRConnect+ACRLastPacket)) and (Header.PacketID=0))
    then
     begin
      Connecting := True;
      PacketAdded := True;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('create connect thread...');
{$ENDIF}
      if ClientSession=nil then
        TACRSendingThread.Create(nil,FManager,nil,Integer(Pointer(NetworkPacket)),0,0,0,0)
      else
        TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,nil,Integer(Pointer(NetworkPacket)),0,0,0,0); // call connect procedure
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('sleep...');
{$ENDIF}
      sleep(0); // From Msg 4.40
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('connect thread created!');
{$ENDIF}
      Continue;
     end;
{$ENDIF MsgCommunicator}
    Header.Recepient := Header.Sender;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread>');
aaWriteToLog('  Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('  Header.PacketID         = '+IntToStr(Header.PacketID));
aaWriteToLog('  Header.ControlCode      = '+IntToStr(Header.ControlCode));
aaWriteToLog('  Header.ConnectionID     = '+IntToStr(Header.ConnectionID));
aaWriteToLog('  Header.SessionID        = '+IntToStr(Header.SessionID));
aaWriteToLog('TACRClientPacketProcessorThread> Connections');
{$ENDIF}
// verify ConnectionID existing
    ConnectionFound := False;
    Connections := FManager.FConnections.LockList;
    try
     for i:=0 to Connections.Count-1 do
      begin
       ClientConnection := Connections.Items[i];
       if (ClientConnection.ConnectionID = Header.ConnectionID)
       or (Header.ControlCode = ACRPacketResendRequest)
       or (Header.ControlCode = ACRMessagePacketResendRequest)
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
aaWriteToLog('TACRClientPacketProcessorThread> '
              +IntToStr(ClientConnection.Network.LocalPort)+'<<< '
              +IntToStr(Header.CurrentRequestID)+' : '
              +IntToStr(Header.PacketID)+' / '
              +IntToStr(Header.ControlCode)+' <<< '
              +NetworkPacket.FromHost+':'+IntToStr(NetworkPacket.FromPort));
{$ENDIF}
    Sessions := FManager.FSessions.LockList;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Sessions locked');
{$ENDIF}
    try
     for i := Sessions.Count-1 downto 0 do
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread>');
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
aaWriteToLog('TACRClientPacketProcessorThread> check session...');
{$ENDIF}
       if
{$IFDEF MsgCommunicator}
          (
            (not (TACRClientSession(ClientSession.Session).Direct))
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
             (Header.ControlCode <> ACRConnected)
             and
             (Header.ControlCode <> (ACRConnected + ACRLastPacket))
            )
            and
            (TACRClientSession(ClientSession.Session).Direct)
            and
            (ClientSession.RemoteConnectionID = Header.ConnectionID)
            and
            (ClientSession.ServerSessionID = Header.SessionID)
          )
       or (
            (
//              (Header.ControlCode = ACRAllPacketsReceived) // disconnect ackn (possible, other commands in the future, too)
//              or
              (Header.ControlCode = ACRPacketResendRequest)
              or
              (Header.ControlCode = ACRMessagePacketResendRequest)
              or
              (Header.ControlCode = ACRConnected)
              or
              (Header.ControlCode = (ACRConnected + ACRLastPacket))
            )
            and
            (TACRClientSession(ClientSession.Session).Direct)
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
aaWriteToLog('TACRClientPacketProcessorThread> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
          inc(ClientSession.Status);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
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
    if (Header.ControlCode = ACRMessage)
    or (Header.ControlCode = ACRMessage + ACRLastPacket)
    then
     begin

      if ClientSession.MsgControlCode <> ACRExecute then
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Messages Listeninig blocked');
{$ENDIF}
        goto KillPacket;
       end;
     end
    else
      if ClientSession.ControlCode <> ACRExecute then
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Commands Listeninig blocked');
{$ENDIF}
       if not // Disconnect acknowledgement
       (
  //      (ClientSession.ControlCode = ACRTerminate)
  //      and
        (ClientSession.CurrentRequestID = Header.CurrentRequestID)
        and
        (Header.ControlCode = ACRAllPacketsReceived)
       )
       then
          goto KillPacket;
       end;
*)
// verify Sender
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Sender');
{$ENDIF}
    if ClientSession.Session.ConnectParams.ServerID <> Header.Sender then
     begin
{$IFDEF MsgCommunicator}
      if (ClientSession.Session.ConnectParams.ServerID = Integer(MSG_INVALID_USER_ID)) // new direct session
      and ((Header.ControlCode = ACRConnected)                // just connected
        or (Header.ControlCode = ACRConnected+ACRLastPacket))
      then
       begin
        ClientSession.Session.FConnectParams.ServerID := Header.Sender;
       end
      else
{$ENDIF}
       begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> (ServerID = '+IntToStr(ClientSession.Session.ConnectParams.ServerID)+') <> (Sender = '+IntToStr(Header.Sender)+')');
aaWriteToLog('TACRClientPacketProcessorThread> Recepient = '+IntToStr(Header.Recepient)+')');
{$ENDIF}
        goto KillPacket;
       end;
     end;
// check CurrentRequestID
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
{$ENDIF}
    if not IsPacketActual then
      goto KillPacket;
// Process service packet
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Process service packet');
{$ENDIF}
    if (Header.ControlCode = ACRConnected)
    or (Header.ControlCode = (ACRConnected+ACRLastPacket))
      then ClientSession.ServerSessionID := Header.SessionID; // To allow disconnect immediately
    case Header.ControlCode of
//------------------------------------------------------------------------------
     ACRDisconnect:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> ACRDisconnect');
{$ENDIF}
       if Header.SessionID = INVALID_SESSION_ID then
        begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> Header.SessionID = INVALID_SESSION_ID -> Kill!');
{$ENDIF}
         goto KillPacket;
        end;
(*
       if ClientSession.LiveListenerThreads > 0 then
        begin
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('Listener Thread # '+'TACRClientPacketProcessorThread> : ClientSession.LiveListenerThreads='+IntToStr(ClientSession.LiveListenerThreads)+' -> Kill!');
{$ENDIF}
         goto KillPacket;
        end;
       inc(ClientSession.LiveListenerThreads);
*)
       try
        ClientSession.ControlCode := ACRTerminate;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> SendACKN');
{$ENDIF}
        FManager.SendAcknowledgement(ClientSession,False,Header.CurrentRequestID);
(* Do not use thread - must finish before session deleting
       TACRSendingThread.Create(FManager,@TACRClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
*)
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> Session.OnDisconnect');
{$ENDIF}
        if ClientSession.Session <> nil then
          TACRClientSession(ClientSession.Session).OnDisconnect;
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> FSessions.Remove...');
{$ENDIF}
        if not FManager.FListenerStoped then
          if FManager.FSessions <> nil then
            FManager.FSessions.Remove(ClientSession);
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> DeleteSession...');
{$ENDIF}
        LeaveCSect(ClientSession.FCSect);
        dec(ClientSession.Status); // allow deleting
        SessionFound := False; // CS left, to do not leave CS in finally section
        if not FManager.FListenerStoped then
          FManager.DeleteSession(ClientSession);
       finally
{$IFDEF LOG_CLIENT_DISCONNECT}
aaWriteToLog('TACRClientPacketProcessorThread> End of Disconnect');
{$ENDIF}
       end;
      end;
//------------------------------------------------------------------------------
     ACRPing:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> send ping answer...');
{$ENDIF}
       TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendPing,
                               Integer(Pointer(ClientSession)),0,0,0,0); // call SendPing
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     ACRPacketResendRequest:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ACRPacketResendRequest ID='+IntToStr(Header.PacketID));
{$ENDIF}
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('TACRClientPacketProcessorThread> Request ID = '+IntToStr(Header.PacketID));
{$ENDIF}
       ClientSession.PacketIDsToResend.Add(Header.PacketID);
{$IFDEF PACKET_RESEND_REQUEST}
       j := (NetworkPacket.Packet.BufferSize - SizeOf(TACRPacketHeader)) div SizeOf(TACRPacketID);
       for i:=0 to j-1 do
        begin
         k := Integer(TACRPacketID((NetworkPacket.Packet.Buffer+SizeOf(TACRPacketHeader)+(i*SizeOf(TACRPacketID)))^));
{$IFDEF LOG_CLIENT_RESENDING}
aaWriteToLog('TACRClientPacketProcessorThread> Request ID = '+IntToStr(k));
{$ENDIF}
         ClientSession.PacketIDsToResend.Add(k);
        end;
{$ENDIF}
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     ACRMessagePacketResendRequest:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ACRMessagePacketResendRequest');
{$ENDIF}
(*
       msgStatus := FManager.FindMessage(FManager.FSendMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
       if msgStatus <> nil then
        begin
         msgStatus.PacketIDsToResend.Add(Header.PacketID);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> resend request added');
{$ENDIF}
        end;
*)
       ClientSession.MsgPacketIDsToResend.Add(Header.PacketID);
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     ACRAllPacketsReceived:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ACRAllPacketsReceived');
{$ENDIF}
       ClientSession.SendStatus := ACRSent;
       ClientSession.PacketIDsToResend.SetSize(0);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ACRAllPacketsReceived - sleep...');
{$ENDIF}
//       sleep(0); // working well w/o sleep
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ACRAllPacketsReceived - up!');
{$ENDIF}
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     ACRMessageReceived:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ACRMessageReceived');
{$ENDIF}
{
       msgStatus := FManager.FindMessage(FManager.FSendMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
       if msgStatus <> nil then
        begin
         msgStatus.Status := ACRSendOK;
         msgStatus.PacketIDsToResend.SetSize(0);
        end;
}
       ClientSession.MsgSendStatus := ACRSent;
       ClientSession.MsgPacketIDsToResend.SetSize(0);
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     ACRMessageAbort:
//------------------------------------------------------------------------------
      begin
       try
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> SendAcknowledgement...');
{$ENDIF}
         TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                                 FManager,@TACRClientConnectionManager.SendAcknowledgement,
                                 Integer(Pointer(ClientSession)),Integer(True),
                                 Header.CurrentRequestID,0,0); // call SendAcknowledgement
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> FindMessage...');
{$ENDIF}
         msgStatus := FManager.FindMessage(FManager.FRecvMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
         if (msgStatus <> nil) then
          begin
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> Remove status...');
{$ENDIF}
           FManager.FRecvMessages.Remove(msgStatus);
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> free packets ID to resend...');
{$ENDIF}
           if msgStatus.PacketIDsToResend <> nil then
             msgStatus.PacketIDsToResend.Free;
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> Dispose status...');
{$ENDIF}
           Dispose(msgStatus);
          end;
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> FindMessageInQueue');
{$ENDIF}
         recvItem := FManager.FindMessageInQueue(Header);
         if (recvItem <> nil) then
          begin
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> Remove...');
{$ENDIF}
           FManager.FMessageQueue.Remove(recvItem);
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> Free packets...');
{$ENDIF}
           FManager.FreePackets(recvItem.Packets);
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> packets free...');
{$ENDIF}
           recvItem.Packets.Free;
{$IFDEF LOG_CLIENT_MESSAGE_ABORT}
aaWriteToLog('TACRClientPacketProcessorThread> Dispose...');
{$ENDIF}
           Dispose(recvItem);
          end;
        finally
        end;
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
     ACRMessage,
     (ACRMessage+ACRLastPacket):
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> message packet');
{$ENDIF}
       msgStatus := FManager.FindMessage(FManager.FRecvMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
       if (msgStatus <> nil) then
        if (msgStatus.Status = ACRReceived) then
         begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Message is already received - Send ACKN');
{$ENDIF}
          TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(True),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
          goto KillPacket;
         end;
       if FManager.MessageStatus(Header,FManager.FRecvMessages) = ACRNotFound then
        begin
// add to RecvMessages
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> New message - add to RecvMessages');
{$ENDIF}
         New(msgStatus);
         msgStatus.Status := ACRReceiving;
         msgStatus.MessageID := Header.CurrentRequestID;
         msgStatus.NetworkClientID := Header.Recepient;
         msgStatus.ConnectionID := Header.ConnectionID;
         msgStatus.SessionID := Header.SessionID;
         msgStatus.PacketIDsToResend := nil;
         FManager.FRecvMessages.Add(msgStatus);
// add to MessageQueue
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> New message - add to MessageQueue');
{$ENDIF}
         New(recvItem);
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRClientPacketProcessorThread> New RecvItem = '+IntToStr(Integer(RecvItem)));
{$ENDIF}
         recvItem.Session := ClientSession;
         recvItem.RecvStatus := ACRStart;
         recvItem.Network := NetworkPacket.Network;
         recvItem.RemotePort := NetworkPacket.FromPort;
         recvItem.RemoteHost := NetworkPacket.FromHost;
         recvItem.Packets := TACRThreadList.Create('recvItem from '+recvItem.RemoteHost+':'+IntToStr(recvItem.RemotePort), false, ACRDefaultMsgPackets);
         FManager.FMessageQueue.Add(recvItem);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Added RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRClientPacketProcessorThread> Added RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
{$IFDEF LOG_RECVITEM}
aaWriteToLog('TACRClientPacketProcessorThread> Added RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
        end
       else // MessageStatus = ACRReceiving
        begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> MessageStatus = ACRReceiving');
{$ENDIF}
         recvItem := FManager.FindMessageInQueue(Header);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> OK');
{$ENDIF}
         if (recvItem = nil) then
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> ERROR: Message not found in queue');
{$ENDIF}
           goto KillPacket;
          end;
        end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> OK 2');
aaWriteToLog('TACRClientPacketProcessorThread> Found RecvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
// Is this message packet already stored?
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Is this message packet already stored?');
{$ENDIF}
//       if recvItem.Packets.Count > 0 then // list exists
        if ((Header.PacketID+1) <= recvItem.Packets.Count) then // old packet
         if (recvItem.Packets.Items[Header.PacketID] <> nil) then // already received
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Existing packet');
aaWriteToLog('Packets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
{$ENDIF}
          if (Header.ControlCode >= ACRLastPacket) then // Last packet
           goto CheckFullMessage // to allow extracting after resending
          else
           goto KillPacket; // Do not replace correct packets with doubles
          end;
// Add correct received message packet
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> New packet');
if ((Header.PacketID+1) <= recvItem.Packets.Count) then // old packet
aaWriteToLog('@Items='+IntToStr(Integer(recvItem.Packets.Items[Header.PacketID])));
{$ENDIF}
       if recvItem.Packets.Count < (Header.PacketID + 1) then // New Packet - Allocate
        begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Allocate');
aaWriteToLog('MsgPackets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
{$ENDIF}
         recvItem.Packets.Count := (Header.PacketID + 1); // List fills hole by Nils
        end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Add packet');
aaWriteToLog('MsgPackets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
{$ENDIF}
       recvItem.Packets.Items[Header.PacketID] := NetworkPacket.Packet;
       PacketAdded := True;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> packet added');
aaWriteToLog('MsgPackets.Count='+IntToStr(Integer(recvItem.Packets.Count)));
aaWriteToLog('@Items='+IntToStr(Integer(recvItem.Packets.Items[Header.PacketID])));
aaWriteToLog('TACRClientPacketProcessorThread> 6 Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
CheckFullMessage: // Is it the last packet?
       if (Header.ControlCode >= ACRLastPacket) then // Last packet
        begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Are all packets received?');
{$ENDIF}
         Header.ControlCode := Header.ControlCode - ACRLastPacket;
// Are all packets received?
         msgStatus := FManager.FindMessage(FManager.FRecvMessages,Header.CurrentRequestID,Header.Sender,Header.ConnectionID,Header.SessionID);
         if IsAllPacketsReceived then
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> All Packets Received!');
{$ENDIF}
           recvItem.RecvStatus := ACRFull;  // Allow to extract buffer
           if (msgStatus <> nil) then
             msgStatus.Status := ACRReceived;
           TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(True),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> SendAcknowledgement - finish');
{$ENDIF}
          end
         else
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> mark for request resending');
{$ENDIF}
{$IFDEF LOG_CLIENT_MESSAGE_RESEND_REQUEST}
aaWriteToLog('TACRClientPacketProcessorThread> mark for request resending recvItem = '+IntToStr(Integer(recvItem)));
{$ENDIF}
           recvItem.RecvStatus := ACRNotFull;  // Allow to request a resending of absent packets
          end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> finish message processing!!!');
{$ENDIF}
        end;
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> message processing finished!!');
{$ENDIF}
      end; // message packet process
//------------------------------------------------------------------------------
     ACRNewRequest,
{$IFNDEF MsgCommunicator}
     ACRClientCommand,
     ACRServerCommand,
{$ENDIF}
     ACRConnected,
     ACRLastPacket..(ACRMessage+ACRLastPacket-1),
     (ACRMessage+ACRLastPacket+1)..127,
     ACRNoAction:
//------------------------------------------------------------------------------
      begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : Data packet');
  {$ENDIF}
       if Header.CurrentRequestID > 0 then // to allow ACRConnected receiving
       if (ClientSession.CurrentRequestID = Header.CurrentRequestID) then
       if (ClientSession.AnswerStatus = ACRFull) then // lost acknowledgement
        begin
  {$IFDEF LOG_CLIENT_SEND_ACKN}
  aaWriteToLog('TACRClientPacketProcessorThread> lost acknowledgement - Send ACKN');
  {$ENDIF}
         TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendAcknowledgement,
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
  aaWriteToLog('TACRClientPacketProcessorThread> old request - Send ACKN');
  {$ENDIF}
         TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
  {$IFDEF DEBUG_LOG_NETWORK}
  aaWriteToLog('--------------------------------------------------------------');
  aaWriteToLog('CLIENT received existing packet while the answer received fully');
  {$ENDIF}
         goto KillPacket; // Do not replace correct packets with doubles
        end;
// is the answer was fully received?
        if ClientSession.ControlCode = ACRSuspend then
         begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> the answer was fully received!');
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
aaWriteToLog('TACRClientPacketProcessorThread> : Existing packet');
aaWriteToLog('           @Items='+IntToStr(Integer(ClientSession.Packets.Items[Header.PacketID])));
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('CLIENT received existing packet');
{$ENDIF}
           if Header.ControlCode >= ACRLastPacket then
             StartResendRequest;
           goto KillPacket; // Do not replace correct packets with doubles
          end;
  // Add correct received data packet
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : New packet');
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
aaWriteToLog('TACRClientPacketProcessorThread> : BufferSize='+IntToStr(NetworkPacket.Packet.BufferSize));
{$ENDIF}
       if ClientSession.Packets.Count < (Header.PacketID + 1) then // New Packet - Allocate
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : Allocate');
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  {$ENDIF}
         ClientSession.Packets.Count := (Header.PacketID + 1); // List fills hole by Nils
        end;
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  aaWriteToLog('TACRClientPacketProcessorThread> : Add packet');
  {$ENDIF}
       ClientSession.Packets.Items[Header.PacketID] := NetworkPacket.Packet;
       PacketAdded := True;
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           Packets.Count='+IntToStr(Integer(ClientSession.Packets.Count)));
  aaWriteToLog('TACRClientPacketProcessorThread> : packet added');
  {$ENDIF}
  // Are all packets received?
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('           @Items='+IntToStr(Integer(ClientSession.Packets.Items[Header.PacketID])));
  aaWriteToLog('TACRClientPacketProcessorThread> : Are all packets received?');
  {$ENDIF}
       AllPacketsReceived := False;
       if
        (
         (ClientSession.AnswerStatus = ACRNotFull) and
         (ClientSession.Packets.Count > (Header.PacketID + 1)) // maybe last hole
        )
       or
        (Header.ControlCode >= ACRLastPacket) // last packet
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
  aaWriteToLog('TACRClientPacketProcessorThread> : Yes');
  {$ENDIF}
         ClientSession.AnswerStatus := ACRFull;  // Allow to extract buffer
         ClientSession.ControlCode := ACRSuspend;
        end
       else
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : No');
  {$ENDIF}
         if ClientSession.AnswerStatus = ACRNo then
           ClientSession.AnswerStatus := ACRStart;
        end;
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : Left!');
  {$ENDIF}
  // Is it the last packet?
       if Header.ControlCode >= ACRLastPacket then
        begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : ACRLastPacket');
  {$ENDIF}
         if ClientSession.AnswerStatus <> ACRFull then
           ClientSession.AnswerStatus := ACRNotFull;
         Header.ControlCode := Header.ControlCode - ACRLastPacket;
         StartResendRequest;
        end;
  // Is Answer full?
         if ClientSession.AnswerStatus = ACRFull then
          begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> : Full answer');
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
           if (Header.ControlCode = ACRConnected)
            then
             begin
  {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : ACRConnected');
  {$ENDIF}
              ClientSession.SendStatus := ACRSent;
  {$IFDEF MsgCommunicator}
              if TACRClientSession(ClientSession.Session).Direct then
                ClientSession.Session.ConnectedUser(
                  TACRClientSession(ClientSession.Session).RemoteUser.UserID,
                  NetworkPacket.FromHost, NetworkPacket.FromPort
                                                  );
              Continue;
   {$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
  aaWriteToLog('TACRClientPacketProcessorThread> : ConnectedUser!');
   {$ENDIF}
  {$ENDIF}
             end
            else
             begin
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientPacketProcessorThread> : SendAcknowledgement - start');
{$ENDIF}
              FManager.SendAcknowledgement(ClientSession,False,Header.CurrentRequestID);
(* Do not use thread - 16 msec delay on network
              TACRSendingThread.Create(FManager,@TACRClientConnectionManager.SendAcknowledgement,
                               Integer(Pointer(ClientSession)),Integer(False),
                               Header.CurrentRequestID,0,0); // call SendAcknowledgement
*)
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
//aaWriteToLog('TACRClientPacketProcessorThread> switch to ReceiveBuffer - sleep...');
{$ENDIF}
//              sleep(0); // switch to ReceiveBuffer -- not needed
{$IFDEF LOG_CLIENT_THREAD_SWITCHING}
//aaWriteToLog('TACRClientPacketProcessorThread> switch to ReceiveBuffer - up!');
{$ENDIF}
{$IFDEF LOG_CLIENT_SEND_ACKN}
aaWriteToLog('TACRClientPacketProcessorThread> : SendAcknowledgement - finish');
{$ENDIF}
  {$IFDEF MsgCommunicator}
              if TACRClientSession(ClientSession.Session).Direct then
                if (Header.ControlCode = ACRInitProgressSend)
//              or (Header.ControlCode = )
                then  // enabled commands
                 begin
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Received Command = '+IntToStr(Header.ControlCode));
{$ENDIF}
                  sleep(0); // to start send ackn first
                  TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                               FManager,@TACRSendingThread.ExecuteReceivedCommand,
                               Integer(Pointer(ClientSession)),Header.ControlCode,
                               0,0,0); // call ExecuteReceivedCommand

                  Continue;
                 end;
  {$ENDIF}
             end;
           if (Header.ControlCode = ACREcho)
           or (Header.ControlCode = ACRTunning)
           then
            begin
             TACRSendingThread.Create(TACRNetworkSession(ClientSession.Session),
                                FManager,@TACRSendingThread.Echo,
                                Integer(ClientSession.Session),
                                Integer(ACRNoAction),0,0,0); // receive then send echo
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('CLIENT SENT ECHO TO SERVER #'+IntToStr(ClientSession.Session.ConnectParams.ServerID));
{$ENDIF}
            end;
          end; // answer is full
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> : ***** END OF DATA PACKET *****');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
      end // data packet process
     else
       raise EACRException.Create(40022, ErrorRUnknownControlCode, [Header.ControlCode]);
    end; // packet process
KillPacket:
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> KillPacket:');
{$ENDIF}
   finally
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> finally...');
{$ENDIF}
    if SessionFound then
     begin
      LeaveCSect(ClientSession.FCSect);
      dec(ClientSession.Status);
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> Status = '+IntToStr(ClientSession.Status)+' @='+IntToHex(Integer(ClientSession),8));
{$ENDIF}
{$IFDEF LOG_CLIENT_PACKET_PROCESSOR}
aaWriteToLog('TACRClientPacketProcessorThread> CS left!');
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
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time19);
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
           TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRClientPacketProcessorThread,-1,
                  Error);
        end;
      finally
       FManager.FSessions.UnlockList;
      end;
     end
    else
      TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRClientPacketProcessorThread,-1,
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
aaWriteToLog('TACRClientPacketProcessorThread> Execute finished!');
{$ENDIF}
except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR: '+Error+ErrorRExecute+E.Message);
{$ENDIF}
   end;
end;
end; // TACRClientPacketProcessorThread.Execute



////////////////////////////////////////////////////////////////////////////////
//
// TACRClientResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClientResendRequestThread.Create(
                       Manager:           TACRClientConnectionManager;
                       ClientSession:     PACRClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TACRNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                                            );
var
  Error:        AnsiString;
  Header:       PACRPacketHeader;
  Sessions:     TACRList;
begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> START');
aaWriteToLog('ClientResendRequestThread> '+Network.LocalHost+':'+IntToStr(Network.LocalPort)
                                          +', request # '+IntToStr(PACRPacketHeader(Buffer).CurrentRequestID)
                                          +' - START', NetLog);
{$ENDIF}
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FClientSession := ClientSession;
  FBuffer := MemoryManager.AllocMem(SizeOf(TACRPacketHeader));
  Move(Buffer^,FBuffer^,SizeOf(TACRPacketHeader));
  Header := PACRPacketHeader(FBuffer);
  Header.Recepient := FClientSession.Session.ConnectParams.ServerID;
  FNetwork := Network;
  FHost := FromHost;
  FPort := FromPort;
  inherited Create(False);
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
           TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRClientResendRequestThread,-1,
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
      TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRClientResendRequestThread,-1,
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
aaWriteToLog('ClientResendRequestThread> '+Network.LocalHost+':'+IntToStr(Network.LocalPort)+', request # '+IntToStr(PACRPacketHeader(Buffer).CurrentRequestID)+' - STARTED', NetLog);
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRClientResendRequestThread.Destroy;
var
  Error:        AnsiString;
  Sessions:     TACRList;
begin
 try
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> Finish');
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PACRPacketHeader(FBuffer).CurrentRequestID)+' - FINISH...', NetLog);
{$ENDIF}
  if not Terminated then
  if FRecreate = True then
    if (FClientSession <> nil) then
      if (FClientSession.Session <> nil) then
        if (FClientSession.AnswerStatus = ACRNotFull) then
          if (FClientSession.CurrentRequestID = PACRPacketHeader(FBuffer).CurrentRequestID) then
           begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PACRPacketHeader(FBuffer).CurrentRequestID)+' - RECREATE...', NetLog);
{$ENDIF}
            sleep(ACRThreadRecreateSleep);
            if not Terminated then
              FClientSession.ResendRequestThread := TACRClientResendRequestThread.Create(FManager, FClientSession,
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
           TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
      TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
procedure TACRClientResendRequestThread.Execute;
var
  Error:              AnsiString;
  i, j, Count:        Integer;
//  AllPacketsReceived: Boolean;
  Sessions:           TACRList;
begin
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PACRPacketHeader(FBuffer).CurrentRequestID)+' - EXECUTE...', NetLog);
{$ENDIF}
 try
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** CLIENT RESEND REQUEST START *****');
{$ENDIF}
  repeat
//   AllPacketsReceived := True;
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRClientResendRequestThread');
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
aaWriteToLog('ClientResendRequestThread.Execute> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PACRPacketHeader(FBuffer).CurrentRequestID)+' - Terminated!', NetLog);
{$ENDIF}
{$IFDEF LOG_CLIENT_RESEND_REQUEST}
aaWriteToLog('ClientResendRequestThread.Execute> Terminated!');
{$ENDIF}
       Exit;
      end;
     EnterCSect(FClientSession.FCSect);
     try
       if (FClientSession.CurrentRequestID > PACRPacketHeader(FBuffer).CurrentRequestID) then
        begin
         FRecreate := False;
  {$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
  aaWriteToLog('ClientResendRequestThread.Execute> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PACRPacketHeader(FBuffer).CurrentRequestID)+' - old request - finish...', NetLog);
  {$ENDIF}
  {$IFDEF LOG_CLIENT_RESEND_REQUEST}
  aaWriteToLog('ClientResendRequestThread.Execute> old request - finish...');
  {$ENDIF}
         Exit;
        end;
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
     FClientSession.AnswerStatus := ACRFull;
//     FManager.SendAcknowledgement(FClientSession);
    end;
*)
   if FClientSession.Session.ConnectParams.ConnectionParamsTunning then
     Sleep((FClientSession.AnswerTime div 16) * j)
   else
     Sleep(FClientSession.Session.ConnectParams.RequestDelay);
  until not (FClientSession.AnswerStatus = ACRNotFull);
 except
  on E: Exception do
   begin
   try
{$IFDEF LOG_CLIENT_RESEND_REQUEST_START-FINISH}
aaWriteToLog('ClientResendRequestThread.Execute>  - EXCEPTION!', NetLog);
aaWriteToLog('ClientResendRequestThread.Execute> '+FNetwork.LocalHost+':'+IntToStr(FNetwork.LocalPort)+', request # '+IntToStr(PACRPacketHeader(FBuffer).CurrentRequestID), NetLog);
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
           TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClientResendRequestThread,-1,
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
      TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClientResendRequestThread,-1,
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
// TACRClienTACRResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRClienTACRResendRequestThread.Create(
                       Manager:           TACRClientConnectionManager;
                       ClientSession:     PACRClntSession;
                       Buffer:            PAnsiChar;
                       Network:           TACRNetwork;
                       FromHost:          AnsiString;
                       FromPort:          Integer
                                            );
var
  Error:        AnsiString;
  Header:       PACRPacketHeader;
  Sessions:     TACRList;
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FClientSession := ClientSession;
  FBuffer := MemoryManager.AllocMem(SizeOf(TACRPacketHeader));
  Move(Buffer^,FBuffer^,SizeOf(TACRPacketHeader));
  Header := PACRPacketHeader(FBuffer);
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
           TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
      TACRNetworkSession(ClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
destructor TACRClienTACRResendRequestThread.Destroy;
var
  Error:        AnsiString;
  Sessions:     TACRList;
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
           TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
      TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
procedure TACRClienTACRResendRequestThread.Execute;
var
  Error:              AnsiString;
  i, j, Count:        Integer;
  AllPacketsReceived: Boolean;
  Sessions:           TACRList;
begin
 try
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** CLIENT RESEND REQUEST START *****');
{$ENDIF}
  repeat
   AllPacketsReceived := True;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRClientMsgResendingThread');
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
//       Sleep(ACRRequestDelay);
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
     FClientSession.MsgReceiveStatus := ACRFull;
{$IFDEF LOG_CLIENT_THREADS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': 9th ClientSession.MsgReceiveStatus='+IntToStr(FClientSession.MsgReceiveStatus));
{$ENDIF}
//     FManager.SendAcknowledgement(FClientSession, True);
    end;
   if FClientSession.Session.ConnectParams.ConnectionParamsTunning then
     Sleep((FClientSession.AnswerTime div 16) * j)
   else
     Sleep(FClientSession.Session.ConnectParams.RequestDelay);
  until FClientSession.MsgReceiveStatus = ACRFull;
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
           TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
      TACRNetworkSession(FClientSession.Session).DoOnError(
                  ACRClienTACRResendRequestThread,-1,
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
// TACRServerConnectionManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerConnectionManager.Create(Server: TComponent;
                                               Protocol: TACRServerProtocol = acrsUDP);
begin
 try
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> @Server='+IntToStr(Integer(FServer)));
{$ENDIF}
  FActive := False;
  FListenerStoped := True;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> InitCSect...');
{$ENDIF}
  InitCSect(FCSect,'ServerConnectionManager',true);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> inherited ...');
{$ENDIF}
  inherited Create;
  FProtocol := Protocol;
  FMaxMsgThreadCount := ACRMaxMsgThreads;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> Sessions list create ...');
{$ENDIF}
  FSessions := TACRThreadList.Create;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> Incoming Packets list create ...');
{$ENDIF}
  FIncomingPackets := TACRThreadList.Create;
  FSessionID := -MAXINT;
  FServer := Server;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> ThreadCount := 0');
{$ENDIF}
  ThreadCount := 0;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> OK');
{$ENDIF}
  FNetwork := nil;
  FNetworkTCP := nil;
  if (FProtocol = acrsUDP) or (FProtocol = acrsTCPandUDP) then
   begin
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> UDP network create...');
{$ENDIF}
    FNetwork := TACRNetwork.Create(self, ACR_UDP);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> OK');
{$ENDIF}
    IncThreadCount;
    if Server = nil then
     begin
      FNetwork.FLocalClient := 1;
      FNetwork.LocalPort := ACRDefaultServerPort;
     end
    else
     begin
      FNetwork.FLocalClient := TACRServer(FServer).ServerID;
      FNetwork.LocalHost := TACRServer(FServer).LocalHost;
      FNetwork.LocalPort := TACRServer(FServer).LocalPort;
      FNetwork.PacketSize := TACRServer(FServer).ConnectionParams.NetworkSettings.PacketSize;
  {$IFDEF MsgCommunicator}
      TACRServer(FServer).ConnectionParams.LocalPort := FNetwork.LocalPort;
      TACRServer(FServer).ConnectionParams.LocalHost := FNetwork.LocalHost;
  {$ELSE}
      TACRServer(FServer).LocalPort := FNetwork.LocalPort;
      TACRServer(FServer).LocalHost := FNetwork.LocalHost;
  {$ENDIF}
     end;
   end;
  if (FProtocol = acrsTCP) or (FProtocol = acrsTCPandUDP) then
   begin
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> UDP network create...');
{$ENDIF}
    FNetworkTCP := TACRNetwork.Create(self, ACR_TCP);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> OK');
{$ENDIF}
    IncThreadCount;
    if Server = nil then
     begin
      FNetworkTCP.FLocalClient := 1;
      FNetworkTCP.LocalPort := ACRDefaultServerPortTCP;
     end
    else
     begin
      FNetworkTCP.FLocalClient := TACRServer(FServer).ServerID;
      FNetworkTCP.LocalHost := TACRServer(FServer).ConnectionParams.LocalHost;
      FNetworkTCP.LocalPort := TACRServer(FServer).ConnectionParams.LocalPortTCP;
      FNetworkTCP.PacketSize := TACRServer(FServer).ConnectionParams.NetworkSettings.PacketSize;
      TACRServer(FServer).ConnectionParams.LocalPortTCP := FNetworkTCP.LocalPort;
      TACRServer(FServer).ConnectionParams.LocalHost := FNetworkTCP.LocalHost;
     end;
   end;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> ListenerThread create...');
{$ENDIF}
  ListenerThread := TACRServerListenerThread.Create(self);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> ResendRequestThread create...');
{$ENDIF}
  ResendRequestThread := TACRServerResendRequestThread.Create(self);
  MsgResendRequestThread := TACRServerMsgResendRequestThread.Create(self);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> SessionTerminator create...');
{$ENDIF}
  SessionTerminator := TACRServerSessionTerminatorThread.Create(self);
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> PingClientsThread create...');
{$ENDIF}
  if Server <> nil then
    if TACRServer(FServer).NetworkSettings.PingClients then
      PingClientsThread := TACRServerPingClientsThread.Create(self);
  FDisconnectThreads := TACRThreadList.Create;
  FActive := True;
{$IFDEF LOG_SERVER_MANAGER_CREATE}
aaWriteToLog('TACRServerConnectionManager.Create> FINISHED');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TACRServerConnectionManager.Create - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerConnectionManager.Destroy;
var
  Error:          AnsiString;
  StartTime:      Cardinal;
  Abnormal:       Boolean;
  i,
  Delay:          Integer;
  Packets:        TACRList;
  NetworkPacket:  PACRNetworkPacket;
begin
 try
  FActive := False;
  Abnormal := False;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy> @Server='+IntToStr(Integer(FServer)));
{$ENDIF}
  FListenerStoped := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy> DisconnectAll...');
{$ENDIF}
  DisconnectAll(False);
// Terminate ResendRequestThread
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
//aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
//aaWriteToLog('TACRServerConnectionManager.Destroy> Terminate ResendRequestThread');
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
      if (GetTickCount - StartTime) > ACRServerThreadsTerminateDelay then
       begin
        Error := 'command resend requesting thread';
        raise EACRException.Create(40036, ErrorRThreadHangs,
                                          ['ServerConnectionManager',
                                                                  Error]);
       end;
     end;
  until False;
}
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
{$ENDIF}
  if not CloseThread(@ListenerThread,ACRServerConnectionManager,ErrorRListenerThread) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> listener thread terminated');
if Abnormal then
aaWriteToLog('Abnormal');
{$ENDIF}
  if not CloseThread(@ResendRequestThread,ACRServerConnectionManager,ErrorRResendRequestThread,500) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> command resend thread terminated');
if Abnormal then
aaWriteToLog('Abnormal');
{$ENDIF}
  if not CloseThread(@MsgResendRequestThread,ACRServerConnectionManager,ErrorRMsgResendRequestThread,500) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> message resend thread terminated');
if Abnormal then
aaWriteToLog('Abnormal');
{$ENDIF}
  if not CloseThread(@SessionTerminator,ACRServerConnectionManager,ErrorRServerSessionTerminatorThread,300) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> session terminator thread terminated');
if PingClientsThread = nil then
aaWriteToLog('PingClientsThread not exist')
else
if Abnormal then
aaWriteToLog('Abnormal');
{$ENDIF}
  if not CloseThread(@PingClientsThread,ACRServerConnectionManager,ErrorRServerPingClientsThread,ACRServerPingSleep*2) then
    Abnormal := True;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> Ping Clients thread terminated');
if Abnormal then
aaWriteToLog('Abnormal');
{$ENDIF}
// Wait for Sessions Threads
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> Wait for Sessions Threads...');
{$ENDIF}
  if FProtocol = acrsTCPandUDP then
    i := 2
  else
    i := 1;
  if FServer = nil then
    Delay := ACRServerThreadsTerminateDelay
  else
    Delay := TACRServer(FServer).NetworkSettings.ServerThreadsTerminateDelay;
  StartTime := GetTickCount;
  while (GetTickCount - StartTime) < Delay do
   begin
    sleep(0);
    if (ThreadCount=i) then
      break;
   end;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy - Delete Sessions...');
{$ENDIF}
  if not Abnormal then
    EnterCSect(FCSect);
  try
    FSessions.Free;
    FSessions := nil;
  except
  end;
// close disconnect threads
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - ThreadCount = '+IntToStr(ThreadCount));
aaWriteToLog('TACRServerConnectionManager.Destroy> Close disconnect threads...');
{$ENDIF}
  CloseThreads(FDisconnectThreads, ErrorRDisconnectThread);
  FDisconnectThreads := nil;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
if FDisconnectThreads <> nil then
aaWriteToLog('Disconnect threads left: '+IntToStr(FDisconnectThreads.Count));
{$ENDIF}
// free packets queue
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - free packets queue...');
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
aaWriteToLog('TACRServerConnectionManager.Destroy - Free Network...');
{$ENDIF}
  if FNetwork <> nil then
   begin
    FNetwork.Free;
    FNetwork := nil;
    DecThreadCount(Abnormal);
   end;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - Free NetworkTCP...');
{$ENDIF}
  if FNetworkTCP <> nil then
   begin
    FNetworkTCP.Free;
    FNetworkTCP := nil;
    DecThreadCount(Abnormal);
   end;
  FNetwork := nil;
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - Leave CS...');
{$ENDIF}
  if not Abnormal then
    LeaveCSect(FCSect);
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - Delete CS...');
{$ENDIF}
  DeleteCSect(FCSect);
  inherited Destroy;
// Check for threads
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - check ThreadCount...');
{$ENDIF}
  if ThreadCount <> 0 then
    TACRServer(FServer).DoOnConnectionError(
                  ACRServerConnectionManager,40515,
                  ErrorRServer+
                  ErrorRDestroy+
                  ErrorRThreadsLeft+
                  IntToStr(ThreadCount)
                  );
{$IFDEF LOG_THREADS_COUNT}
//aaWriteToLog('TACRServerConnectionManager.Destroy> Threads Count = '+IntToStr(ThreadCount));
{$ENDIF}
{$IFDEF LOG_SERVER_MANAGER_DESTROY}
aaWriteToLog('TACRServerConnectionManager.Destroy - FINISHED');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('TACRServerConnectionManager.Destroy - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end;// Destoy


//------------------------------------------------------------------------------
// PacketResendRequest
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.PacketResendRequest(
                               Buffer:        PAnsiChar;
                               Network:       TACRNetwork;
                               RemoteHost:    AnsiString;
                               RemotePort:    Integer;
                               PacketID:      Integer = -1;
                               Msg:           Boolean = False;
                               Packets:       TACRThreadList = nil
                                 );
var
  Header:           PACRPacketHeader;
  Buf:              PAnsiChar;
  BufSize:          Integer;
{$IFDEF PACKET_RESEND_REQUEST}
  i, j:             Integer;
  packs, IDs:       TACRList;
  packID:           TACRPacketID;
{$ENDIF}
begin
  if not FActive then
    Exit;
  Header := Pointer(Buffer);
  Header.Signature := ACRServerPacketSign;
  if Msg then
    Header.ControlCode := ACRMessagePacketResendRequest
  else
    Header.ControlCode := ACRPacketResendRequest;
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
    IDs := TACRList.Create;
    try
     j := packs.Count;
     if j >((Network.PacketSize - SizeOf(TACRPacketHeader)) div SizeOf(TACRPacketID)) then
       j := (Network.PacketSize - SizeOf(TACRPacketHeader)) div SizeOf(TACRPacketID);
     if j >= ACR_Max_PacketID then
       j := ACR_Max_PacketID - 1;
     for i := PacketID + 1 to j do
      begin
       if packs.Items[i] = nil then
         IDs.Add(i);
      end;
    finally
     Packets.UnlockList;
     IDs.Free;
    end;
    BufSize := SizeOf(TACRPacketHeader);
    if IDs.ItemsCount = 0 then
     begin
      Buf := Buffer;
     end
    else
     begin
      BufSize := BufSize + (IDs.ItemsCount * SizeOf(TACRPacketID));
      Buf:=MemoryManager.GetMem(BufSize);
      Move(Buffer^, Buf, SizeOf(TACRPacketHeader));
      for i := 0 to IDs.ItemsCount-1 do
       begin
        packID := TACRPacketID(IDs.Items[i]);
        Move(packID, Buffer^ + SizeOf(TACRPacketHeader) + (i * SizeOf(TACRPacketID), SizeOf(TACRPacketID));
       end;
     end;
   end;
{$ELSE}
  BufSize := SizeOf(TACRPacketHeader);
  Buf := Buffer;
{$ENDIF}
  EnterCSect(Network.FCSect);
  try
   Network.RemoteHost := RemoteHost;
   Network.RemotePort := RemotePort;
   Network.SendBuffer(Buf, BufSize);
  finally
   LeaveCSect(Network.FCSect);
{$IFDEF PACKET_RESEND_REQUEST}
   if BufSize > SizeOf(TACRPacketHeader) then
     MemoryManager.FreeAndNilMem(Buf);
{$ENDIF}
  end;
end;// PacketResendRequest


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.OnDisconnect(
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  i:                    Integer;
{$IFDEF MsgCommunicator}
  SSessions:            array of TACRServerSession;
{$ENDIF}
begin
{ TODO -oAlex : Re-write OnDisconnect to use DoDisconnect. In MsgCommunicator DisconnectUser move to Session.Destroy}

{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.OnDisconnect> START');
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
(* REMOVED IN ACR --------------------------------------------------------------
{$IFDEF MsgCommunicator}
        SetLength(SSessions, Length(SSessions)+1);
        SSessions[Length(SSessions)-1] := TACRServerSession(ServerSession.Session);
{$ENDIF}
REMOVED IN ACR -------------------------------------------------------------- *)
        EnterCSect(ServerSession.FCSect);
        if (ServerSession.ControlCode <> ACRTerminate)
        or (ServerSession.MsgControlCode <> ACRTerminate)
        then
         begin
          // Terminate sending threads
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('OnDisconnect> SERVER SESSION TERMINATE');
{$ENDIF}
          ServerSession.ControlCode := ACRTerminate;
          ServerSession.MsgControlCode := ACRTerminate;
          LeaveCSect(ServerSession.FCSect);
          // Block send message
{$IFDEF MsgCommunicator}
          if ServerSession.Session <> nil then
            EnterCSect(TACRServerSession(ServerSession.Session).FCSect);
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
             LeaveCSect(TACRServerSession(ServerSession.Session).FCSect);
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
          LeaveCSect(ServerSession.FCSect);
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
  FNetwork := TACRNetwork.Create(self);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> NEW: FNetwork=');
aaWriteToLog(IntToHex(Integer(FNetwork),6));
{$ENDIF}
  if FServer = nil then
   begin
    FNetwork.FLocalClient := 1;
    FNetwork.LocalPort := ACRDefaultServerPort;
   end
  else
   begin
    FNetwork.FLocalClient := TACRServer(FServer).ServerID;
    FNetwork.LocalHost := TACRServer(FServer).LocalHost;
    FNetwork.LocalPort := TACRServer(FServer).LocalPort;
   end;
  LeaveCSect(FCSect);
*)

{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog(IntToStr(GetTickCount)+':');
aaWriteToLog('OnDisconnect> FNetwork=');
aaWriteToLog(IntToHex(Integer(Network),6));
{$ENDIF}

(* REMOVED IN ACR --------------------------------------------------------------
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
     TACRServerSession(ServerSession.Session).DisconnectUser(Users.Items[i]);
}
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> DisconnectUser finished');
 {$ENDIF}
    end;
{$ENDIF}
--------------------------------------------------------------- REMOVED IN ACR*)
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('OnDisconnect> FINISH');
{$ENDIF LOG_SERVER_DISCONNECT}
 except
  on E: Exception do
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> TACRServerConnectionManager.OnDisconnect - Error:');
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
procedure TACRServerConnectionManager.NetworkListener(
                               Buffer:        PAnsiChar;
                               BufferSize:    Integer;
                               Network:       TACRNetwork;
                               FromHost:      AnsiString;
                               FromPort:      Integer
                              );
(*
var
  StartTime:        Cardinal;
*)
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
var
 Packets:              TACRList;
{$ENDIF}

function IsExistingPacket: Boolean;
var
 i:                    Integer;
 Packets:              TACRList;
 NetworkPacket:        PACRNetworkPacket;
{
function IsSameHeader: Boolean;
begin
 Result := CompareMem(PACRPacketHeader(NetworkPacket.Packet.Buffer),
                      PACRPacketHeader(Buffer),
                      SizeOf(TACRPacketHeader));
end;
}
begin // IsExistingPacket
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> IsExistingPacket - START');
aaWriteToLog('SERVER-IsExistingPacket> SERVER<<< '
              +IntToStr(PACRPacketHeader(Buffer).CurrentRequestID)+' : '
              +IntToStr(PACRPacketHeader(Buffer).PacketID)+' / '
              +IntToStr(PACRPacketHeader(Buffer).ControlCode)+' <<< '
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
       if CompareMem(NetworkPacket.Packet.Buffer, Buffer, SizeOf(TACRPacketHeader)) then
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
aaWriteToLog('TACRServerConnectionManager.NetworkListener> IsExistingPacket - FINISH - Existing Packet')
else
aaWriteToLog('TACRServerConnectionManager.NetworkListener> IsExistingPacket - FINISH - Original Packet');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> ERROR!!!');
{$ENDIF}
 end;
end; // IsExistingPacket

procedure AddPacket;
var
 NetworkPacket:     PACRNetworkPacket;
 Packet:            PACRPacket;
 Packets:           TACRList;
begin
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaIncCounter(counter5);aaStartTime(time5); try aaStartTime(time6);{$ENDIF}
 New(NetworkPacket);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStopTime(time6);{$ENDIF}
 NetworkPacket.Network := Network;
 NetworkPacket.FromHost := FromHost;
 NetworkPacket.FromPort := FromPort;
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStartTime(time7);{$ENDIF}
 New(Packet);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStopTime(time7);{$ENDIF}
 Packet.Buffer := Buffer;
 Packet.BufferSize := BufferSize;
 NetworkPacket.Packet := Packet;
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaStartTime(time8);{$ENDIF}
 FIncomingPackets.Add(NetworkPacket);
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME} finally aaStopTime(time8);  aaStopTime(time5); end; {$ENDIF}
end; // AddPacket

begin // NetworkListener
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME}aaIncCounter(counter4);aaStartTime(time4); try {$ENDIF}
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('NetworkListener --------------------------------');
aaWriteToLog('Header.ConnectionID = '+IntToStr(PACRPacketHeader(Buffer).ConnectionID));
aaWriteToLog('Header.SessionID    = '+IntToStr(PACRPacketHeader(Buffer).SessionID));
aaWriteToLog('Header.ControlCode  = '+IntToStr(PACRPacketHeader(Buffer).ControlCode));
aaWriteToLog('NetworkListener --------------------------------');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PACRPacketHeader(Buffer).ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TACRServerConnectionManager.NetworkListener> message received from SessionID = '+IntToStr(PACRPacketHeader(Buffer).SessionID));
{$ENDIF}
  if not FListenerStoped then
   begin
    if not IsExistingPacket then
     begin
      AddPacket;
//      sleep(1);
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PACRPacketHeader(Buffer).ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TACRServerConnectionManager.NetworkListener> message added from SessionID = '+IntToStr(PACRPacketHeader(Buffer).SessionID));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
Packets := FIncomingPackets.LockList;
try
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Packets Count = '+IntToStr(Packets.Count));
finally
FIncomingPackets.UnlockList;
end;
{$ENDIF}
      Exit;
     end
    else
     begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PACRPacketHeader(Buffer).ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TACRServerConnectionManager.NetworkListener> not added: Existing packet from SessionID = '+IntToStr(PACRPacketHeader(Buffer).SessionID));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Existing packet received')
{$ENDIF}
     end;
   end
  else
   begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if PACRPacketHeader(Buffer).ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog(IntToStr(GetTickCount)+': TACRServerConnectionManager.NetworkListener> not added from SessionID = '+IntToStr(PACRPacketHeader(Buffer).SessionID)+': Listener Stoped!');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Listener Stoped!!!');
{$ENDIF}
   end;
  MemoryManager.FreeAndNilMem(Buffer);
(*
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> START - '+IntToStr(GetTickCount));
{$ENDIF}
  if not FListenerStoped then
   begin
    StartTime := GetTickCount;
    while ((GetTickCount-StartTime) < TACRServer(FServer).NetworkSettings.ServerReceiveTimeOut) do
     begin
      if ThreadCount<TACRServer(FServer).NetworkSettings.MaxThreadCount then
       begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Create Listener Thread... - '+IntToStr(GetTickCount));
{$ENDIF}
        TACRServerListenerThread.Create(self, Buffer, BufferSize, FromHost, FromPort);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Listener Thread Created ! - '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Threads Count = '+IntToStr(ThreadCount));
{$ENDIF}
        Exit;
       end;
      sleep(0);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.NetworkListener> Sleeped ! - '+IntToStr(GetTickCount));
{$ENDIF}
     end;
    TACRServer(FServer).DoOnConnectionError(
                  ACRServerListenerThread,40516,
                  ErrorRCannotCreateListenerThread+
                  IntToStr(TACRServer(FServer).NetworkSettings.MaxThreadCount));
   end;
  MemoryManager.FreeAndNilMem(Buffer);
*)
{$IFDEF DEBUG_LOG_RECEIVEDATA_TIME} finally aaStopTime(time4); end; {$ENDIF}
end;// NetworkListener


//------------------------------------------------------------------------------
// WaitForServerSessionThread
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.WaitForServerSessionThread(
                          ServerSession:    PACRSrvrSession;
                          TimeOut:          Cardinal = ACRWaitForServerSessionThreadTimeOut
                          );
var
  StartTime:      Cardinal;
begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.WaitForServerSessionThread> Started at: '+IntToStr(GetTickCount));
{$ENDIF}
//  WaitForThread(@ServerSession.Thread, TimeOut);
  StartTime := GetTickCount;
  while ((GetTickCount-StartTime) < TimeOut) do
   begin
    if ServerSession.ReceiveStatus = ACRNo then
      break;
    sleep(1);
   end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
//if ServerSession.Thread = nil then
if ServerSession.ReceiveStatus = ACRNo then
aaWriteToLog('TACRServerConnectionManager.WaitForServerSessionThread> Finished at: '+IntToStr(GetTickCount))
else
aaWriteToLog('TACRServerConnectionManager.WaitForServerSessionThread> Not Finished! Timeout at: '+IntToStr(GetTickCount));
{$ENDIF}
end; // Wait for server session thread


//------------------------------------------------------------------------------
// WaitForServerSessionMsgThread
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.WaitForServerSessionMsgThread(
                          ServerSession:    PACRSrvrSession;
                          TimeOut:          Cardinal = ACRWaitForServerSessionThreadTimeOut
                          );
begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.WaitForServerSessionMsgThread> Started at: '+IntToStr(GetTickCount));
{$ENDIF}
//  WaitForThread(@ServerSession.MsgThread, TimeOut);
  CloseThread(@ServerSession.MsgThread,ACRServerSessionMsgThreadHang,ErrorRServerSessionMsgThread,
                        TimeOut);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
if ServerSession.Thread = nil then
aaWriteToLog('TACRServerConnectionManager.WaitForServerSessionMsgThread> Finished at: '+IntToStr(GetTickCount))
else
aaWriteToLog('TACRServerConnectionManager.WaitForServerSessionMsgThread> Not Finished! Timeout at: '+IntToStr(GetTickCount));
{$ENDIF}
end; // Wait for server session message thread


//------------------------------------------------------------------------------
// CommandReceived
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.CommandReceived(
                          ServerSession:    PACRSrvrSession;
                          ControlCode:      TACRControlCode;
                          CurrentRequestID: Integer
                                                      );
var
  Error:        AnsiString;
(*
function IsNotSingle: Boolean;
begin
  Result := False;
   if (ControlCode <> ACRDisconnect) then
     if (CurrentRequestID < ServerSession.CurrentRequestID) then
      begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> (CurrentRequestID < ServerSession.CurrentRequestID) ==> Exit, old command already processed');
{$ENDIF}
       Result := True;
       Exit;
      end;
   if ServerSession.ReceiveStatus = ACRFull then
    begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> (ReceiveStatus = ACRFull) ==> Exit');
{$ENDIF}
     Result := True;
     Exit;
    end;
   ServerSession.ReceiveStatus := ACRFull;
   if ServerSession.ControlCode = ACRExecute then
     ServerSession.ControlCode := ACRSuspend
   else
    begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> (ControlCode <> ACRExecute) ==> Exit');
{$ENDIF}
     Result := True;
     Exit;
    end;
end;
*)
begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> STARTED - GetTickCount='+IntToStr(GetTickCount));
aaWriteToLog(' CurrentRequestID='+IntToStr(ServerSession.CurrentRequestID));
aaWriteToLog(' Code='+IntToStr(ControlCode));
aaWriteToLog(' ReceiveStatus = '+IntToStr(ServerSession.ReceiveStatus));
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-CommandReceived> START');
{$ENDIF}
  if (ControlCode >= ACRLastPacket) then
    ControlCode := ControlCode - ACRLastPacket;
  EnterCSect(ServerSession.FCSect);
  try
   ServerSession.ReceiveStatus := ACRFull;
   if ServerSession.ControlCode = ACRExecute then
     ServerSession.ControlCode := ACRSuspend;
  finally
   LeaveCSect(ServerSession.FCSect);
  end;
  if ServerSession.Thread <> nil then
    CloseThread(@ServerSession.Thread,ACRServerDeleteSession,
        ErrorRServerSessionThread,
        ServerSession.Session.ConnectParams.WaitForTimeOut, 0);
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('SERVER-CommandReceived> create session thread...');
{$ENDIF}
  if ServerSession.Thread = nil then
    ServerSession.Thread := TACRServerSessionThread.Create(self,
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
aaWriteToLog('TACRServerConnectionManager.CommandReceived> previous session still executes...');
{$ENDIF}
    WaitForServerSessionThread(ServerSession);
   end;
  if CurrentRequestID=ServerSession.CurrentRequestID then
   begin
    if (ControlCode >= ACRLastPacket) then
      ControlCode := ControlCode - ACRLastPacket;
    ServerSession.Thread.FCode := ControlCode;
    ServerSession.ReceiveStatus := ACRFull;
   end;
//  sleep(0); // NEVER SET IT!!!
  Exit;


// Disconnect - wait for session end
  if (ControlCode = ACRDisconnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> Disconnect - SendAcknowledgement');
{$ENDIF}
    SendAcknowledgement(ServerSession);
    WaitForServerSessionThread(ServerSession);
   end;

// check for single execution and block other calls
  EnterCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> CS Entered!');
{$ENDIF}
  try
  if IsNotSingle then
    Exit;
  finally
   LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> CS Left!');
{$ENDIF}
  end;
  if (ControlCode <> ACRConnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> SendAcknowledgement');
{$ENDIF}
    if (ControlCode <> ACRDisconnect) then
     begin
      SendAcknowledgement(ServerSession, False, CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> SendAcknowledgement - SENT');
{$ENDIF}
     end;
    if CurrentRequestID>ServerSession.CurrentRequestID then
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> previous session still executes...');
{$ENDIF}
      WaitForServerSessionThread(ServerSession);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> previous session finished, block...');
{$ENDIF}
      EnterCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> CS Entered!');
{$ENDIF}
      try
       if IsNotSingle then
         Exit;
      finally
       LeaveCSect(FCSect);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> CS Left!');
{$ENDIF}
      end;
     end;
    if ServerSession.Thread = nil then
     begin
      ServerSession.Thread := TACRServerSessionThread.Create(self,
                                                   ServerSession, ControlCode);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> CREATED # '+IntToStr(Integer(ServerSession.Thread.ThreadID))+'/'+IntToStr(Integer(ServerSession.Thread.Handle)));
{$ENDIF}
     end
    else
     begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> Server Session already exists');
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
       TACRNetworkSession(ServerSession.Session).DoOnError(ACRServerSessionThread,40514,Error);
      except
       TACRServer(FServer).DoOnConnectionError(ACRServerSessionThread,40514,Error);
      end;
     end;
   end;
*)
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> FINISHED');
{$ENDIF}
end; // CommandReceived


//------------------------------------------------------------------------------
// MessageReceived
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.MessageReceived(
                                  ServerSession:  PACRSrvrSession;
                                  ControlCode:    TACRControlCode = ACRMessage
                                                      );
var
  Packets:     TACRList;
begin
(*
  while ServerSession.MsgThread <> nil do
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerConnectionManager.CommandReceived> previous session still executes...');
{$ENDIF}
    WaitForServerSessionMsgThread(ServerSession);
   end;
  if (ControlCode >= ACRLastPacket) then
    ControlCode := ControlCode - ACRLastPacket;
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
aaWriteToLog('Header.Message # '+IntToStr(Integer(PACRPacketHeader(PACRPacket(Packets.Items[0]).Buffer).CurrentRequestID)));
  finally
   ServerSession.MsgPackets.UnlockList;
  end;
aaWriteToLog('Adding new message...');
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID)+': old list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
  ServerSession.MsgReceiveStatus := ACRFull;
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
  ServerSession.MsgPackets := TACRThreadList.Create;
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog('SessionID = '+IntToStr(ServerSession.Session.SessionID)+': new list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('new list created');
{$ENDIF}
  Packets := ServerSession.MsgPackets.LockList;
  try
   Packets.Capacity := ACRDefaultPacketsInRequest; // Allocate some place in list
  finally
   ServerSession.MsgPackets.UnlockList;
  end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('new list '+IntToStr(Integer(Pointer(ServerSession.MsgPackets))));
{$ENDIF}
  inc(ServerSession.ClientMessageID);
  ServerSession.MsgReceiveStatus := ACRNo;
  if ServerSession.MsgThread = nil then
    ServerSession.MsgThread := TACRServerSessionMsgThread.Create(self,
                                                 ServerSession, ControlCode);
  sleep(0);
end; // MessageReceived


//------------------------------------------------------------------------------
// ReceiveMessage
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.ReceiveMessage(
                          ServerSession:  PACRSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
var
  i:                    Integer;
  Packets:              TACRList;
  Packet:               PACRPacket;
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
       raise EACRException.Create(40026, ErrorRTimeoutFullReceive,
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
  if ServerSession.MsgControlCode = ACRExecute then
    ServerSession.MsgControlCode := ACRSuspend;
  LeaveCSect(FCSect);
}
*)
  Packets := ServerSession.MsgReceivedPackets.LockList;
  try
// Send Ackn
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog('ServerConnectionManager.ReceiveMessage> Header.Message # '+
  IntToStr(PACRPacketHeader(PACRPacket(Packets.Items[0]).Buffer).CurrentRequestID));
{$ENDIF}
    try
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> ServerConnectionManager.ReceiveMessage');
{$ENDIF}
     SendAcknowledgement(ServerSession,True,PACRPacketHeader(PACRPacket(Packets.Items[0]).Buffer).CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerConnectionManager.ReceiveMessage> Acknowledgement sent!');
{$ENDIF}
    except
     on E:Exception do
      raise EACRException.Create(40519, ErrorRAckn+E.Message);
    end;
   BufferSize := 0;
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     BufferSize := BufferSize + Packet.BufferSize - SizeOf(TACRPacketHeader);
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
         Move(Pointer(Packet.Buffer+SizeOf(TACRPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TACRPacketHeader));
         inc(pBuf, Packet.BufferSize-SizeOf(TACRPacketHeader));
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
//  ServerSession.MsgReceiveStatus := ACRNo;
{
  EnterCSect(FCSect);
  if ServerSession.MsgControlCode = ACRSuspend then
    ServerSession.MsgControlCode := ACRExecute;
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
procedure TACRServerConnectionManager.ReceiveBuffer(
                          ServerSession:  PACRSrvrSession;
                          var Buffer:     PAnsiChar;
                          var BufferSize: Integer
                          );
var
  i:                    Integer;
  Packet:               PACRPacket;
  Packets:              TACRList;
  pBuf:                 PAnsiChar;
  StartTime:            Cardinal;
begin
{$IFDEF LOG_SERVER_RECEIVE}
aaWriteToLog('TACRServerConnectionManager.ReceiveBuffer - START');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('SERVER are receiving request from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
{$ENDIF}
  if ServerSession.ReceiveStatus <> ACRFull then
   begin
    while (ServerSession.ReceiveStatus <> ACRStart)
    and (ServerSession.ReceiveStatus <> ACRFull)
    do // Wait for starting answer receive
     begin
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
     end;
    StartTime := GetTickCount;
    while (ServerSession.ReceiveStatus <> ACRFull)
    do // Wait for all packets to arrive
     begin
      if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerReceiveTimeOut then
       raise EACRException.Create(40025, ErrorRTimeoutFullReceive,
                                [ServerSession.Session.SessionID,
                                ServerSession.Session.ConnectParams.ServerReceiveTimeOut]);
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
      Sleep(ServerSession.Session.ConnectParams.ServerReceiveSleep);
     end;
   end;
{$IFDEF LOG_SERVER_RECEIVE}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received request from CLIENT #'+IntToStr(ServerSession.RemoteClientID));
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
{$IFDEF LOG_SERVER_RECEIVE}
aaWriteToLog('TACRServerConnectionManager.ReceiveBuffer> All packets received');
{$ENDIF}
  EnterCSect(ServerSession.FCSect);
  if ServerSession.ControlCode = ACRExecute then
    ServerSession.ControlCode := ACRSuspend;
  LeaveCSect(ServerSession.FCSect);
  BufferSize := 0;
  Packets := ServerSession.Packets.LockList;
  try
   for i := 0 to Packets.Count - 1 do
    begin
     Packet := Packets.Items[i];
     BufferSize := BufferSize + Packet.BufferSize - SizeOf(TACRPacketHeader);
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
         if (Packet.BufferSize > SizeOf(TACRPacketHeader)) then
          begin
           Move(Pointer(Packet.Buffer+SizeOf(TACRPacketHeader))^, pBuf^, Packet.BufferSize-SizeOf(TACRPacketHeader));
           inc(pBuf, Packet.BufferSize-SizeOf(TACRPacketHeader));
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
{$IFDEF LOG_SERVER_RECEIVE}
aaWriteToLog('TACRServerConnectionManager.ReceiveBuffer - FINISH');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('SERVER<<< '+IntToStr(ServerSession.CurrentRequestID)+' :');
aaWriteBufferToLog(Buffer,BufferSize);
{$ENDIF}
end; // ReceiveBuffer


//------------------------------------------------------------------------------
// SendConnectAckn
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.SendConnectAckn(
                          ServerSession:        PACRSrvrSession;
                          CurrentRequestID:     Integer = -1
                                                      );
var
  Buffer,
  Buf:                            PAnsiChar;
  BufSize, BufferSize,
  SizeSID, SizeParams:            Integer;
  ConnectParams:                  TACRConnectParams;
  ConnectionParams:               TACRConnectionParams;
  RequestID:                      Integer;
begin
  if not FActive then
    Exit;
  if ServerSession.Session.ConnectParams.UseServerSettings then
   begin
    ConnectParams.Protocol := ServerSession.Session.ConnectParams.Protocol;
    TACRServer(FServer).NetworkSettings.CopySettingsToConnectParams(ConnectParams);
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
    DoSendBuffer(ServerSession, Buf, BufSize, ACRConnected);
   finally
    if Buf<>Buffer then
      MemoryManager.FreeAndNilMem(Buf);
   end;

   if CurrentRequestID >= 0 then
     ServerSession.CurrentRequestID := RequestID;

   ServerSession.ReceiveStatus := ACRNo;
  finally
   MemoryManager.FreeAndNilMem(Buffer);
  end;
end;// SendConnectAckn


//------------------------------------------------------------------------------
// SendDisconnectRequest
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.SendDisconnectRequest(
                                    ServerSession: PACRSrvrSession;
                                    WaitForAnswer: Boolean = True;
                                    PTerminated: Pointer = nil);
var
  Header:           PACRPacketHeader;
  Retry:            Integer;
  StartTime:        Cardinal;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.SendDisconnectRequest> START');
{$ENDIF}
 if not FActive then
   Exit;
 try
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
   Header.ControlCode := ACRDisconnect;
   Header.Signature := ACRServerPacketSign;
   Header.Recepient := ServerSession.RemoteClientID;
   EnterCSect(ServerSession.Network.FCSect);
    Header.Sender := ServerSession.Network.FLocalClient;
   LeaveCSect(ServerSession.Network.FCSect);
   Header.ConnectionID := ServerSession.ConnectionID;
   Header.SessionID := ServerSession.Session.SessionID;
   Header.PacketID := 0;
   Header.CurrentRequestID := ServerSession.CurrentRequestID;
   Retry := 0;
   ServerSession.SendStatus := ACRNotSent;
   repeat
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.SendDisconnectRequest> Retry = '+IntToStr(Retry));
aaWriteToLog('TACRServerConnectionManager.SendDisconnectRequest> Delay = '+IntToStr(ServerSession.Session.ConnectParams.DisconnectDelay));
{$ENDIF}
     EnterCSect(ServerSession.Network.FCSect);
     try
{
      if ServerSession.ControlCode = ACRTerminate then
//            raise EACRException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession)],1);
}
      ServerSession.Network.SendBuffer(PAnsiChar(Header), SizeOf(TACRPacketHeader), 0, ServerSession.RemoteHost, ServerSession.RemotePort);
     finally
      LeaveCSect(ServerSession.Network.FCSect);
     end;
     if not WaitForAnswer then
       Exit;
     StartTime := GetTickCount;
     while ((GetTickCount - StartTime) < ServerSession.Session.ConnectParams.DisconnectDelay) do // pause
      if ServerSession.SendStatus <> ACRSent then
       begin
        if Boolean(PTerminated^) = True then
         begin
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TACRServerConnectionManager.SendDisconnectRequest>  Thread terminated!');
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
   if ServerSession.SendStatus <> ACRSent then
    raise EACRException.Create(40024, ErrorRCannotDisconnect,
                   ['client', ServerSession.ClientSessionID,
                    ServerSession.Session.ConnectParams.DisconnectRetryCount,
                    ServerSession.Session.ConnectParams.DisconnectDelay]);
  finally
   MemoryManager.FreeAndNilMem(Header);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.SendDisconnectRequest> FINISH');
{$ENDIF}
  end;
 except
{$IFDEF LOG_SERVER_DISCONNECT}
  on E: Exception do
    begin
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRConnection> TACRServerSessionThread.Execute - Error:');
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
procedure TACRServerConnectionManager.DeleteSession(ServerSession: PACRSrvrSession;
                            SkipServerSessionTermination: Boolean = False;
                            SaveMessages: Boolean = True);
var
  i,j:                  Integer;
  Packet:               PACRPacket;
  Queue,
  Packets:              TACRList;
  TimeOut,
  StartTime:            Cardinal;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> START');
{$ENDIF}
  if ServerSession = nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> ServerSession = nil - already deleted, exit');
{$ENDIF}
    Exit;
   end;
  if ServerSession.CurrentRequestID = ACRTerminate then // to prevent entering csect
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> session is already deleting - FINISH');
{$ENDIF}
    Exit;
   end;
{$IFDEF MsgCommunicator}
  if ServerSession.Session <> nil then
    EnterCSect(TACRServerSession(ServerSession.Session).FCSect);
  try
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
if ServerSession.Session <> nil then
aaWriteToLog('TACRServerConnectionManager.DeleteSession> SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
//  if @ServerSession.FCSect = nil then
  if ServerSession = nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> ServerSession.FCSect = nil - already deleted, exit');
{$ENDIF}
    Exit;
   end;
  EnterCSect(ServerSession.FCSect);
  try
   if ServerSession.CurrentRequestID = ACRTerminate then // before block to start deleting
    begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> session is already deleting - FINISH');
{$ENDIF}
     Exit;
    end;
   // block deleting ServerSession
   ServerSession.CurrentRequestID := ACRTerminate;
   // block using ServerSession
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DeleteSession> SERVER SESSION TERMINATE');
{$ENDIF}
   ServerSession.ControlCode := ACRTerminate;
   ServerSession.MsgControlCode := ACRTerminate;
   // free listenning threads lists
{
   ServerSession.ListeningThreads.Free;
   ServerSession.ListeningThreads := nil;
   ServerSession.MsgListeningThreads.Free;
   ServerSession.MsgListeningThreads := nil;
}
  finally
   LeaveCSect(ServerSession.FCSect);
  end;
  if ServerSession.Session = nil then
    TimeOut := ACRWaitForServerSessionThreadTimeOut
  else
    TimeOut := ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut;
  if not SkipServerSessionTermination then // No needs to terminate in connecting
    // wait for the end of current request execution
    CloseThread(@ServerSession.Thread,ACRServerDeleteSession,
        ErrorRServerSessionThread, TimeOut);
{
  WaitForServerSessionThread(ServerSession);
  if ServerSession.Thread <> nil then
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(ServerSession.Thread.ThreadID))+'/'+IntToStr(Integer(ServerSession.Thread.Handle))+
                  ErrorRExecute;
    try
     TACRNetworkSession(ServerSession.Session).DoOnError(ACRServerDeleteSession,
                  40517,Error+
                  ErrorRCannotCloseThread+
                  IntToStr(MsgWaitForServerSessionThreadTimeOut));
    except
     TACRServer(FServer).DoOnConnectionError(ACRServerDeleteSession,
                  40517,Error+
                  ErrorRCannotCloseThread+
                  IntToStr(MsgWaitForServerSessionThreadTimeOut));
    end;
    CloseThread(ServerSession.Thread.Handle, 0);
    WaitForServerSessionThread(ServerSession, ACRWaitForKillTimeOut);
    if ServerSession.Thread <> nil then
     begin
      try
       TACRNetworkSession(ServerSession.Session).DoOnError(ACRServerDeleteSession,
                  40518,Error+
                  ErrorRCannotKillThread+
                  IntToStr(MsgWaitForKillTimeOut));
      except
       TACRServer(FServer).DoOnConnectionError(ACRServerDeleteSession,
                  40518,Error+
                  ErrorRCannotKillThread+
                  IntToStr(MsgWaitForKillTimeOut));
      end;
     end;
   end;
}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free Session...');
{$ENDIF}
  // free PacketIDsToResend
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> wait for resending broken packets...');
{$ENDIF}
  // wait for resending broken packets
  StartTime := aaGetTickCount;
  repeat
    if ServerSession.PacketIDsToResend.ItemCount = 0 then
      break;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> sleep(1)');
{$ENDIF}
    sleep(1);
  if ServerSession.Session = nil then
    TimeOut := ACRServerSendTimeOut
  else
    TimeOut := ServerSession.Session.ConnectParams.ServerSendTimeOut;
  until ((aaGetTickCount - StartTime) >= TimeOut);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free PacketIDsToResend...');
{$ENDIF}
  ServerSession.PacketIDsToResend.Free;
  // free packets
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free packets...');
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
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free packet list...');
{$ENDIF}
  ServerSession.Packets.Free;
(*
  repeat
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> SessionID='+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TACRServerConnectionManager.DeleteSession> WaitFor message Session thread...');
aaWriteToLog('TACRServerConnectionManager.DeleteSession> MsgThread='+IntToStr(Integer(ServerSession.MsgThread)));
{$ENDIF}
    if ServerSession.MsgThread = nil then
      break;
    sleep(0);
  until False;
*)
  // free MsgPacketIDsToResend
{$IFDEF MsgCommunicator}
  if ServerSession.Session <> nil then
    EnterCSect(TACRServerSession(ServerSession.Session).FCSect);
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> wait for resending broken message packets...');
{$ENDIF}
  repeat
    if ServerSession.MsgPacketIDsToResend.ItemCount = 0 then // wait for resending broken packets
      break;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> sleep(0) - 2');
{$ENDIF}
    sleep(0);
  until False;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free MsgPacketIDsToResend...');
{$ENDIF}
  ServerSession.MsgPacketIDsToResend.Free;
{$IFDEF MsgCommunicator}
  finally
   if ServerSession.Session <> nil then
     LeaveCSect(TACRServerSession(ServerSession.Session).FCSect);
  end;
{$ENDIF}
  // free message packets
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free message packets...');
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
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free message packet list...');
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
           ServerSession.MsgThread := TACRServerSessionMsgThread.Create(self,
                                                                ServerSession);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> sleep(0) - 3');
{$ENDIF}
         sleep(0);
        end;
      finally
       ServerSession.MsgQueue.UnlockList;
      end;
     end;
    if ServerSession.Session = nil then
      TimeOut := ACRWaitForServerSessionThreadTimeOut
    else
      TimeOut := ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut;
    CloseThread(@ServerSession.MsgThread,ACRServerDeleteSession,ErrorRServerSessionMsgThread,TimeOut);
   end;
  // release packets from queue
   Queue := ServerSession.MsgQueue.LockList;
   try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
if ServerSession.Session <> nil then
aaWriteToLog('SERVER - DeleteSession> SessionID = '+IntToStr(ServerSession.Session.SessionID)+', Old Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    for i := 0 to Queue.Count - 1 do
     begin
      Packets := TACRThreadList(Queue.Items[i]).LockList;
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
       TACRThreadList(Queue.Items[i]).UnlockList;
       TACRThreadList(Queue.Items[i]).Free;
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
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free Received message packets...');
{$ENDIF}
  if ServerSession.MsgReceivedPackets <> nil then
   begin
  Packets := ServerSession.MsgReceivedPackets.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> List Locked!');
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
aaWriteToLog('TACRServerConnectionManager.DeleteSession> free Received message packet list...');
{$ENDIF}
    ServerSession.MsgReceivedPackets.Free;
   end;
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DeleteSession> wait for vacant ServerSession - SERVER SESSION TERMINATE');
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> wait for vacant ServerSession...');
{$ENDIF}
  // wait for vacant ServerSession
  repeat
    // block using ServerSession
    EnterCSect(ServerSession.FCSect);
     ServerSession.ControlCode := ACRTerminate;
     ServerSession.MsgControlCode := ACRTerminate;
    LeaveCSect(ServerSession.FCSect);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> sleep(0) - 4');
{$ENDIF}
    sleep(0);
    if (ServerSession.Status = ACRVacant) then
      break;
  until False;
{$IFDEF MsgCommunicator}
  if ServerSession.Session <> nil then
    LeaveCSect(TACRServerSession(ServerSession.Session).FCSect);
{$ENDIF}
  // free session
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
  if ServerSession.Session <> nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> Free Session...');
{$ENDIF}
    ServerSession.Session.Free;
    ServerSession.Session := nil;
   end;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> Dispose(ServerSession)...');
{$ENDIF}
  DeleteCSect(ServerSession.FCSect);
  Dispose(ServerSession);
  ServerSession := nil;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DeleteSession> FINISH');
{$ENDIF}
end; // DeleteSession


//------------------------------------------------------------------------------
// DoDisconnect
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.DoDisconnect(Session: TACRBaseSession;
                            SkipServerSessionTermination: Boolean = False);
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  i:                    Integer;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> START');
aaWriteToLog('Session = '+IntToStr(Integer(Session)));
{$ENDIF}
  if Session = nil then
    Exit;
  if not FActive then
    Exit;
(*
{$IFDEF MsgCommunicator}
       if not FListenerStoped then
         TACRServerSession(Session).DisconnectUser;
{$ENDIF}
*)
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> LockSessions...');
{$ENDIF}
  Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> FSessions Locked');
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> Sessions.Count='+IntToStr(Sessions.Count));
{$ENDIF}
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     if (i<0)
     or (i>=Sessions.Count)
     then
       break;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> get Session...');
{$ENDIF}
     ServerSession := Sessions.Items[i];
     if ServerSession <> nil then
     if ServerSession.Session = Session then
      begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> SessionID = '+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> enter CS...');
{$ENDIF}
       EnterCSect(ServerSession.FCSect);
       if (ServerSession.ControlCode <> ACRTerminate)
       or (ServerSession.MsgControlCode <> ACRTerminate)
       then
        begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> stop ping...');
{$ENDIF}
         // Stop ping
         ServerSession.Connected := False;
         // Terminate sending threads
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DoDisconnect> SERVER SESSION TERMINATE');
{$ENDIF}
         ServerSession.ControlCode := ACRTerminate;
         ServerSession.MsgControlCode := ACRTerminate;
         LeaveCSect(ServerSession.FCSect);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('Session = '+IntToStr(Integer(Session)));
aaWriteToLog('ServerSession.Session = '+IntToStr(Integer(ServerSession.Session)));
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> CS leaved...');
{$ENDIF}

{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Terminate message listening threads...');
{$ENDIF}
//         TerminateMessageThreads(ServerSession);

{$IFDEF MsgCommunicator}
         // block sendmessage
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> Session CS entering...');
 {$ENDIF}
         if ServerSession.Session <> nil then
           EnterCSect(TACRServerSession(ServerSession.Session).FCSect);
         try
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> Unlock Session list...');
{$ENDIF}
         FSessions.UnlockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> remove incoming session packets...');
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
            LeaveCSect(TACRServerSession(ServerSession.Session).FCSect);
         end;
 {$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('DoDisconnect> Session CS left');
 {$ENDIF}
{$ENDIF}
         // free memory and session
         LeaveCSect(ServerSession.FCSect);
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
         LeaveCSect(ServerSession.FCSect);
(*
       // Terminate all threads
       FSessions.UnlockList;
       TerminateAllSessionThreads(ServerSession);
       // delete session from list
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> Session remove session from list...');
{$ENDIF}
       FSessions.Remove(ServerSession);
       // free memory and session
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> Delete SessionID='+IntToStr(ServerSession.Session.SessionID)+'...');
{$ENDIF}
       DeleteSession(ServerSession);
       Sessions:=FSessions.LockList;
*)
       break;
      end;
    end;
  finally
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DoDisconnect> Sessions.Count='+IntToStr(Sessions.Count));
{$ENDIF}
   FSessions.UnlockList;
  end;
end; // DoDisconnect


//------------------------------------------------------------------------------
// TerminateSession
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.TerminateSession(Session: TACRBaseSession);
begin
  if SessionTerminator <> nil then
    if SessionTerminator.FTerminatedSessions <> nil then
      SessionTerminator.FTerminatedSessions.Add(Session);
end;// TerminateSession


//------------------------------------------------------------------------------
// disconnect client by Host:Port
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.DisconnectClient(const Host: AnsiString; const Port: Integer);
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  Session:              TACRBaseSession;
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
procedure TACRServerConnectionManager.DisconnectClient(const SessionID: Integer);
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  Session:              TACRBaseSession;
  i:                    Integer;
  Found:                Boolean;
begin
  Found := False;
  Session := nil;
  Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.Disconnect> FSessions Locked');
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
procedure TACRServerConnectionManager.Disconnect(Session: TACRBaseSession; PTerminated: Pointer = nil);
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  i:                    Integer;
  Found:                Boolean;
begin
  Found := False;
  Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.Disconnect> FSessions Locked');
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
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);

  EnterCSect(ServerSession.FCSect);
   ServerSession.ControlCode := ACRSuspend;
   ServerSession.MsgControlCode := ACRSuspend;
  LeaveCSect(ServerSession.FCSect);

  try
   SendDisconnectRequest(ServerSession, true, PTerminated);
  finally
{
  EnterCSect(FCSect);
  ServerSession.ControlCode := ACRTerminate;
  ServerSession.MsgControlCode := ACRTerminate;
  LeaveCSect(FCSect);
}

   DoDisconnect(Session);
  end;

end; // Disconnect


//------------------------------------------------------------------------------
// DisconnectAll
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.DisconnectAll(WaitForAllDisconnected: Boolean = True);
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  i:                    Integer;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> START');
{$ENDIF}
  if not FActive then
    Exit;
  if FSessions<>nil then
  begin
    try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> Lock FSessions...');
{$ENDIF}
     Sessions:=FSessions.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> FSessions Locked');
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
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> EnterCSect...');
{$ENDIF}
        EnterCSect(ServerSession.FCSect);
        if (ServerSession.ControlCode <> ACRTerminate)
        or (ServerSession.MsgControlCode <> ACRTerminate)
        then
         begin
          // Stop ping
          ServerSession.Connected := False;
          // Terminate sending threads
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> Terminate sending threads...');
{$ENDIF}
{$IFDEF LOG_SERVER_SESSION_TERMINATE}
aaWriteToLog('DisconnectAll> SERVER SESSION TERMINATE');
{$ENDIF}
          ServerSession.ControlCode := ACRTerminate;
          ServerSession.MsgControlCode := ACRTerminate;
          LeaveCSect(ServerSession.FCSect);
          // Block sending message
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> Block sending message...');
{$ENDIF}
{$IFDEF MsgCommunicator}
          if ServerSession.Session <> nil then
            EnterCSect(TACRServerSession(ServerSession.Session).FCSect);
          try
{$ENDIF}
          FSessions.UnlockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> SendDisconnectRequest');
{$ENDIF}
          // send
          try
           SendDisconnectRequest(ServerSession, False);
          except
           // ignore all exceptions while disconnecting
          end;
          // Terminate all threads
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> TerminateAllSessionThreads...');
{$ENDIF}
          TerminateAllSessionThreads(ServerSession);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> All session threads terminated');
{$ENDIF}
          // delete session from list
          FSessions.Remove(ServerSession);
          // free memory and session
{$IFDEF MsgCommunicator}
          finally
           if ServerSession.Session <> nil then
            LeaveCSect(TACRServerSession(ServerSession.Session).FCSect);
          end;
{$ENDIF}
          DeleteSession(ServerSession,False,WaitForAllDisconnected);
          Sessions:=FSessions.LockList;
         end
        else
          LeaveCSect(ServerSession.FCSect);
       end;
     finally
      FSessions.UnlockList;
     end;
      // Wait for all sessions be disconnected
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> WaitForAllDisconnected...');
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
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> All Disconected!');
{$ENDIF}
    except
{$IFDEF LOG_SERVER_DISCONNECT}
      on E: Exception do
        begin
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
        end;
{$ENDIF}
    end;
  end;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.DisconnectAll> FINISH');
{$ENDIF}
end; // DisconnectAll


//------------------------------------------------------------------------------
// SessionsCount
//------------------------------------------------------------------------------
function TACRServerConnectionManager.SessionsCount: Integer;
var
  Sessions:           TACRList;
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
function TACRServerConnectionManager.IsSessionTerminated(ClientSession: Pointer): Boolean;
var
  Sessions:     TACRList;
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
procedure TACRServerConnectionManager.TerminateMessageThreads(ServerSession: PACRSrvrSession);
var
  i:                    Integer;
//  Count:                Integer;
  WaitFor,
  StartTime:            Cardinal;
//  Threads:              TACRList;
//  Thread:               TThread;
//  Error:                AnsiString;
  Queue:                TACRList;
  found:                Boolean;
begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> START');
{$ENDIF}
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> START');
{$ENDIF}
try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> Check incoming queue...');
{$ENDIF}
// Check incoming queue
  repeat
   found := false;
   Queue := FIncomingPackets.LockList;
   try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> start Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    for i:=Queue.Count-1 downto 1 do // 0 element will be processed by listener thread
     begin
      if ServerSession.Session = nil then
        begin
         found := true;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> nil - break');
{$ENDIF}
         break;
        end;
      if PACRPacketHeader(PACRNetworkPacket(Queue.Items[i]).Packet.Buffer).SessionID = ServerSession.Session.SessionID then
       if (PACRPacketHeader(PACRNetworkPacket(Queue.Items[i]).Packet.Buffer).ControlCode = ACRMessage)
       or (PACRPacketHeader(PACRNetworkPacket(Queue.Items[i]).Packet.Buffer).ControlCode = ACRMessage+ACRLastPacket)
       then
        begin
         found := true;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> found! - wait...');
{$ENDIF}
         break;
        end;
     end; // for
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> end Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
   finally
    FIncomingPackets.UnlockList;
   end;
   sleep(1);
  until not found;

{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> Check session queue...');
{$ENDIF}
// Check session queue
  StartTime := GetTickCount;
  if ServerSession.Session <> nil then
   begin
    WaitFor := ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> check for nil... ');
{$ENDIF}
    if ServerSession.MsgQueue <> nil then
       repeat
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> lock... ');
{$ENDIF}
        Queue := ServerSession.MsgQueue.LockList;
        try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
         if Queue.Count = 0 then
           break;
        finally
         ServerSession.MsgQueue.UnlockList;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> unlock... ');
{$ENDIF}
        end;
        if (GetTickCount - StartTime) > WaitFor then
          break;
        sleep(1); // waite for message processing
       until false;
   end;

{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> Check msgthread...');
{$ENDIF}
// Check msgthread
       while (ServerSession.MsgThread <> nil) do
         sleep(1); // white for message processing

{$IFDEF MsgCommunicator}
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> DisconnectUser...');
{$ENDIF}
       if not FListenerStoped then
         TACRServerSession(ServerSession.Session).DisconnectUser;
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> User disconnected!');
{$ENDIF}
{$ENDIF}



(*
  sleep(0); // to allow finishing listening threads
  Threads := ServerSession.MsgListeningThreads.LockList;
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
  try
   for i := 0 to Threads.Count-1 do
    begin
     Thread := Threads.Items[i];
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
     CloseThread(@Thread,ACRServerConnectionManager,ErrorRListenerMsgThread);
    end;
  finally
   ServerSession.MsgListeningThreads.UnlockList;
  end;
*)
(*
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> START');
{$ENDIF}
  if ServerSession.MsgListeningThreads = nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> MsgListeningThreads = nil - FINISH');
{$ENDIF}
    Exit;
   end;
  EnterCSect(FCSect);
  ServerSession.MsgControlCode := ACRTerminate;
  LeaveCSect(FCSect);
  // Wait for finishes of all the threads
  StartTime := GetTickCount;
  repeat
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> MsgListeningThreads.LockList...');
{$ENDIF}
   // Terminate message listening threads
   Threads := ServerSession.MsgListeningThreads.LockList;
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> MsgListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
   try
    for i := 0 to Threads.Count-1 do
     begin
      Thread := Threads.Items[i];
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
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
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> CHECKING...');
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
     if (GetTickCount - StartTime) > ACRServerThreadsTerminateDelay then
      begin
       Error := IntToStr(Count)+' message listening threads';
       raise EACRException.Create(40036, ErrorRThreadHangs,
            ['Server session # '+IntToStr(ServerSession.Session.SessionID),
            Error]);
      end;
    end;
  until False;
*)
finally
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateMessageThreads> FINISH');
{$ENDIF}
end;
end; // TerminateMessageThreads


//------------------------------------------------------------------------------
// TerminateCommandThreads
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.TerminateCommandThreads(ServerSession: PACRSrvrSession);
var
  i:                    Integer;
{
  Count:                Integer;
  StartTime:            Cardinal;
  Threads:              TACRList;
  Thread:               TThread;
var
 Packet:            PACRPacket;
}
 NetworkPacket:     PACRNetworkPacket;
 Packets:           TACRList;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> START');
{$ENDIF}
  if (ServerSession = nil)
  or (ServerSession.Session = nil) then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> nil - Exit!');
{$ENDIF}
    Exit;
   end;
  Packets := FIncomingPackets.LockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> locked!');
{$ENDIF}
  try
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> Packets.Count = '+IntToStr(Packets.Count));
{$ENDIF}
   for i:=Packets.Count-1 downto 1 do // 0 element will be processed by listener thread
    begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> check #'+IntToStr(i));
{$ENDIF}
     if PACRPacketHeader(PACRNetworkPacket(Packets.Items[i]).Packet.Buffer).SessionID = ServerSession.Session.SessionID then
     if (PACRPacketHeader(PACRNetworkPacket(Packets.Items[i]).Packet.Buffer).ControlCode <> ACRMessage) then
     if (PACRPacketHeader(PACRNetworkPacket(Packets.Items[i]).Packet.Buffer).ControlCode <> ACRMessage+ACRLastPacket) then
      begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> found #'+IntToStr(i));
{$ENDIF}
       NetworkPacket := Packets.Items[i];
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> free buffer...');
{$ENDIF}
       if (NetworkPacket.Packet.Buffer <> nil) then
         MemoryManager.FreeAndNilMem(NetworkPacket.Packet.Buffer);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> dispose packet...');
{$ENDIF}
       Dispose(NetworkPacket.Packet);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> dispose network packet...');
{$ENDIF}
       Dispose(NetworkPacket);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> delete packet fro incoming queue...');
{$ENDIF}
       Packets.Delete(i);
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> OK - find next...');
{$ENDIF}
      end;
    end; // for
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> finishing - OK...');
{$ENDIF}
  finally
   FIncomingPackets.UnlockList;
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> unlocked!');
{$ENDIF}
  end;
  Exit;
try
(*
  sleep(0); // to allow finishing listening threads
  Threads := ServerSession.ListeningThreads.LockList;
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
  try
   for i := 0 to Threads.Count-1 do
    begin
     Thread := Threads.Items[i];
{$IFDEF DEBUG_LOG_SERVER_TERMINATE}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
{$ENDIF}
     CloseThread(@Thread,ACRServerConnectionManager,ErrorRListenerThread);
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
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
    try
     for i := 0 to Threads.Count-1 do
      begin
       Thread := Threads.Items[i];
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
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
          TACRNetworkSession(ServerSession.Session).DoOnError(MsgServerTerminateCommandThreads,ENativeCode,Error);
         except
          TACRServer(FServer).DoOnConnectionError(MsgServerTerminateCommandThreads,ENativeCode,Error);
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
     raise EACRException.Create(40036, ErrorRThreadHangs,
           ['Server session # '+IntToStr(ServerSession.Session.SessionID),
            Error]);
    end;
  end;
end; // IsListeningThreadExisting

begin //TerminateCommandThreads
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> START');
{$ENDIF}
try // finally
  if ServerSession.ListeningThreads = nil then
   begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> ListeningThreads = nil - FINISH');
{$ENDIF}
    Exit;
   end;
  EnterCSect(FCSect);
  ServerSession.ControlCode := ACRTerminate;
  LeaveCSect(FCSect);
 try // except
  StartTime := GetTickCount;
  repeat   // Wait for finishes of all the threads
    // Terminate all command listening threads
    Threads := ServerSession.ListeningThreads.LockList;
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> ListeningThreads.Count='+IntToStr(Threads.Count));
{$ENDIF}
    try
     for i := 0 to Threads.Count-1 do
      begin
       Thread := Threads.Items[i];
{$IFDEF LOG_Server_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> Terminate # '+IntToStr(Integer(Thread.ThreadID))+'/'+IntToStr(Integer(Thread.Handle)));
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
  on E: EACRException do
    LogHangedThreads(E.Message,E.NativeError,False);
 end; // exception
 try
  StartTime := GetTickCount;
  IsListeningThreadExisting(MsgWaitForKillTimeOut);
 except
  on E: EACRException do
    LogHangedThreads(E.Message,E.NativeError,True);
 end; // exception
*)
finally
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.TerminateCommandThreads> FINISH');
{$ENDIF}
end;
end; // TerminateCommandThreads


//------------------------------------------------------------------------------
// TerminateAllSessionThreads
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.TerminateAllSessionThreads(ServerSession: PACRSrvrSession);
begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateAllSessionThreads> TerminateCommandThreads...');
{$ENDIF}
  TerminateCommandThreads(ServerSession);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateAllSessionThreads> TerminateMessageThreads...');
{$ENDIF}
  TerminateMessageThreads(ServerSession);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.TerminateAllSessionThreads> finish');
{$ENDIF}
end; // TerminateAllSessionThreads


//------------------------------------------------------------------------------
// DoSendBuffer
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.DoSendBuffer(
                          ServerSession:    PACRSrvrSession;
                          Buffer:           PAnsiChar;
                          BufferSize:       Integer;
                          Code:             Integer = ACRNoAction
                                                  );
var
  Header:               PACRPacketHeader;
  Packets:              TACRList;
  Packet:               PACRPacket;
  BytesSent, DataSize:  Integer;
  i:                    Integer;

procedure FirstResend;
begin
 // resend last packet for the first time
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('FirstResend');
{$ENDIF}
 Packet := Packets.Items[Packets.Count-1];
 EnterCSect(ServerSession.Network.FCSect);
 try
  ServerSession.Network.SendBuffer(Packet.Buffer, Packet.BufferSize, 0, ServerSession.RemoteHost, ServerSession.RemotePort);
 finally
  LeaveCSect(ServerSession.Network.FCSect);
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
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForCommandSent> - START');
{$ENDIF}
 try
  EnterCSect(ServerSession.FCSect);
   ControlCode := ServerSession.ControlCode;
   ServerSession.ControlCode := ACRExecute;
  LeaveCSect(ServerSession.FCSect);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server waits for all packets');
{$ENDIF}
  if not ((Code = ACRConnect) or (Code = (ACRConnect + ACRLastPacket))) then
   begin
(*
{$IFDEF ProcessMessages}
    Application.ProcessMessages;
{$ENDIF ProcessMessages}
    Sleep(ACRServerReceiveSleep); // To avoid delay if full answer is already received
*)
{
// code to force push up sending in case of more than 10 packets message
    if (ServerSession.SendStatus <> ACRSent) then
      sleep(MsgFirstResendPushUpTimeout);
    if (ServerSession.SendStatus <> ACRSent) then
      FirstResend;
}
    i := ServerSession.PacketIDsToResend.ItemCount;
    Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
    StartTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartTime = '+IntToStr(StartTime));
Retry := 0;
{$ENDIF}
    while not (ServerSession.SendStatus = ACRSent) do  // resend broken packets
     begin
{$IFDEF LOG_SERVER_RESENDING}
inc(Retry);
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer>WaitForCommandSent> Retry = '+IntToStr(Retry));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer>WaitForCommandSent> Delay = '+IntToStr(ServerSession.Session.ConnectParams.DisconnectDelay));
aaWriteToLog('SendStatus <> ACRSent = '+IntToStr(ServerSession.SendStatus)+' <> '+IntToStr(ACRSent));
{$ENDIF}
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
//      Sleep(ACRServerResendDelay);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server has '+IntToStr(ServerSession.PacketIDsToResend.ItemCount)+' packets to resend');
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
          if ServerSession.SendStatus = ACRSent then
            Exit;
          if ServerSession.ControlCode = ACRTerminate then // added as analogue of client
            raise EACRException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),2]);
          if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerSendTimeOut then
           begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TimeOut: StartTime='+IntToStr(StartTime)+', ServerSendTimeOut='+IntToStr(ServerSession.Session.ConnectParams.ServerSendTimeOut));
{$ENDIF}
            raise EACRException.Create(40078, ErrorRServerTimeOutSending,
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
         EnterCSect(ServerSession.FCSect);
         try
          if ServerSession.ControlCode = ACRTerminate then
            raise EACRException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),3]);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Current Time = '+IntToStr(GetTickCount));
{$ENDIF}
          EnterCSect(ServerSession.Network.FCSect);
          try
           ServerSession.Network.SendBuffer(Packet.Buffer, Packet.BufferSize, 0, ServerSession.RemoteHost, ServerSession.RemotePort);
          finally
           LeaveCSect(ServerSession.Network.FCSect);
          end;
          if i<0 then  // No packets to resend, increase pause
            Delay := Delay * 2
          else  // Restore default pause in case of packets resending
            Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
          if Delay = 0 then
            Delay := ACRServerResendDelay;
         finally
          LeaveCSect(ServerSession.FCSect);
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
aaWriteToLog('SendStatus = ACRSent, Time = '+IntToStr(GetTickCount));
{$ENDIF}
   end; // no Connect
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('Server sent all the packets');
{$ENDIF}
  EnterCSect(ServerSession.FCSect);
   ServerSession.ControlCode := ControlCode;
  LeaveCSect(ServerSession.FCSect);
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForCommandSent> - Error:');
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
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> - START');
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter18);
aaStartTime(time18);
try
{$ENDIF}
 try
  EnterCSect(ServerSession.FCSect);
   ControlCode := ServerSession.MsgControlCode;
   ServerSession.MsgControlCode := ACRExecute;
  LeaveCSect(ServerSession.FCSect);
(*
{$IFDEF ProcessMessages}
    Application.ProcessMessages;
{$ENDIF ProcessMessages}
    Sleep(ACRServerReceiveSleep); // To avoid delay if full answer is already received
*)
{
// code to force push up sending in case of more than 10 packets message
  if (ServerSession.MsgSendStatus <> ACRSent) then
    sleep(20);
  if (ServerSession.MsgSendStatus <> ACRSent) then
    FirstResend;
}
  i := ServerSession.MsgPacketIDsToResend.ItemCount;
  Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
  StartTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartTime = '+IntToStr(StartTime));
{$ENDIF}
  while not (ServerSession.MsgSendStatus = ACRSent) do  // resend broken packets
     begin
{$IFDEF ProcessMessages}
      Application.ProcessMessages;
{$ENDIF ProcessMessages}
//      Sleep(ACRServerResendDelay);
      if ServerSession.MsgPacketIDsToResend.ItemCount = 0 then
       begin
        StartSleepTime := GetTickCount;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('StartSleepTime = '+IntToStr(StartSleepTime));
aaWriteToLog('Delay = '+IntToStr(Delay));
{$ENDIF}
        while ((GetTickCount - StartSleepTime) < Delay) do  // sleep after last packet send
         begin
          if ServerSession.MsgSendStatus = ACRSent then
            Exit;
          if ServerSession.MsgControlCode = ACRTerminate then // added as analogue of client
            raise EACRException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
          if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.ServerSendTimeOut then
            raise EACRException.Create(40078, ErrorRServerTimeOutSending,
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
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> New step');
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> SessionID='+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.Session='+IntToStr(Integer(ServerSession.Session)));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> i='+IntToStr(i));
{$ENDIF}
      dec(i);
      if i<0 then
        i := ServerSession.MsgPacketIDsToResend.ItemCount - 1;
      try
       ServerSession.MsgPacketIDsToResend.Lock;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> MsgPacketIDsToResend.ItemCount = '+IntToStr(ServerSession.MsgPacketIDsToResend.ItemCount));
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
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> PacketID = '+IntToStr(PacketID));
{$ENDIF}
         Packet := Packets.Items[PacketID];
         // resend packet
         EnterCSect(ServerSession.FCSect);
         try
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog(IntToStr(GetTickCount)+':');
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> Network=');
aaWriteToLog(IntToHex(Integer(Network),6));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> RemoteHost=');
aaWriteToLog(ServerSession.RemoteHost);
{$ENDIF}
          if ServerSession.MsgControlCode = ACRTerminate then
            raise EACRException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
          ServerSession.Network.SendBuffer(Packet.Buffer, Packet.BufferSize, 0, ServerSession.RemoteHost, ServerSession.RemotePort);
          if i<0 then  // No packets to resend, increase pause
            Delay := Delay * 2
          else  // Restore default pause in case of packets resending
            Delay := ServerSession.Session.ConnectParams.ServerResendDelay;
          if Delay = 0 then
            Delay := ACRServerResendDelay;
         finally
          LeaveCSect(ServerSession.FCSect);
         end;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> Sent!');
{$ENDIF}
        end
      else
        ServerSession.MsgPacketIDsToResend.Unlock;
      finally
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> Locking...');
{$ENDIF}
       ServerSession.MsgPacketIDsToResend.Lock;
       if  (ServerSession.MsgPacketIDsToResend.ItemCount > 0)
       and (ServerSession.MsgPacketIDsToResend.ItemCount > i)
       then
        begin
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> Removing PacketID = '+IntToStr(PacketID));
{$ENDIF}
         ServerSession.MsgPacketIDsToResend.Remove(PacketID);
        end;
       ServerSession.MsgPacketIDsToResend.Unlock;
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> UnlLocked');
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.Session=');
aaWriteToLog(IntToStr(Integer(ServerSession.Session)));
{$ENDIF}
      end; // finally
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.Session=');
aaWriteToLog(IntToStr(Integer(ServerSession.Session)));
{$ENDIF}
     end; // loop
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> Ending...');
{$ENDIF}
  EnterCSect(ServerSession.FCSect);
   ServerSession.MsgControlCode := ControlCode;
  LeaveCSect(ServerSession.FCSect);
{$IFDEF LOG_SERVER_RESENDING}
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> ServerSession.MsgSendStatus = '+IntToStr(ServerSession.MsgSendStatus));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> SessionID = '+IntToStr(ServerSession.Session.SessionID));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> End!');
{$ENDIF}
 except
  on E: Exception do
    begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> WaitForMessageSent> - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
{$ENDIF}
     raise;
    end;
 end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
finally
aaStopTime(time18);
end;
{$ENDIF}
end; // WaitForMessageSent

begin // DoSendBuffer
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter17);
aaStartTime(time17);
try
{$ENDIF}
 try
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER are sending buffer...');
{$ENDIF}
 if not FActive then
    Exit;
 if (ServerSession.Session.ConnectParams.PacketSize < SizeOf(TACRPacketHeader)) then
   raise EACRException.Create(40020, ErrorRPacketSizeTooSmall,
                              [ServerSession.Session.ConnectParams.PacketSize,
                                     SizeOf(TACRPacketHeader)]);
 Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
 try
  DataSize := ServerSession.Session.ConnectParams.PacketSize - SizeOf(TACRPacketHeader);
  Header.Signature := ACRServerPacketSign;
  Header.Recepient := ServerSession.RemoteClientID;
  Header.Sender := ServerSession.Network.FLocalClient;
  Header.ConnectionID := ServerSession.ConnectionID;
  if Code = ACRConnected then
    Header.SessionID := ServerSession.ClientSessionID
  else
    Header.SessionID := ServerSession.Session.SessionID;
  Header.PacketID := 0;
  Header.ControlCode := Code;
  if (Code = ACRMessage)
  or (Code = ACRMessageAbort) then
   begin
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SERVER IS SENDING MESSAGE # '+IntToStr(ServerSession.ClientMessageID)+' TO CLIENT ID='+IntToStr(ServerSession.RemoteClientID));
{$ENDIF}
    Header.CurrentRequestID := ServerSession.ServerMessageID;
   end
  else
    Header.CurrentRequestID := ServerSession.CurrentRequestID;
  Packets := TACRList.Create;
   try
    BytesSent := 0;
    i := DataSize;
    if (Code = ACRMessage)
    or (Code = ACRMessageAbort) then
     begin
      ServerSession.MsgSendStatus := ACRNotSent;
     end
    else
      ServerSession.SendStatus := ACRNotSent;
    repeat
//    while BytesSent < BufferSize do
//     begin // Create and send all packets
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SERVER.DoSendBuffer> Sending packet # '+IntToStr(Header.PacketID));
{$ENDIF}
      New(Packet);
      Packets.Add(Packet);
      Packet.Buffer := MemoryManager.GetMem(ServerSession.Session.ConnectParams.PacketSize);
      if BytesSent + DataSize > BufferSize then
       DataSize := BufferSize - BytesSent;
      Packet.BufferSize := DataSize + SizeOf(TACRPacketHeader);
      if BytesSent + DataSize = BufferSize then
        if Header.ControlCode <> ACRMessageAbort then
          Header.ControlCode := Header.ControlCode+ACRLastPacket;
      Move(Header^, Packet.Buffer^, SizeOf(TACRPacketHeader));
      Move(Pointer(Integer(Buffer)+Header.PacketID*i)^, Pointer(Integer(Packet.Buffer)+SizeOf(TACRPacketHeader))^, DataSize);
      inc(Header.PacketID);
      // send packet
      EnterCSect(ServerSession.FCSect);
      try
       if (Code = ACRMessage)
       or (Code = ACRMessageAbort) then
        begin
         if ServerSession.MsgControlCode = ACRTerminate then
           raise EACRException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
        end
       else
         if ServerSession.ControlCode = ACRTerminate then
           raise EACRException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),4]);
       EnterCSect(ServerSession.Network.FCSect);
       try
        ServerSession.Network.SendBuffer(Packet.Buffer, Packet.BufferSize, 0, ServerSession.RemoteHost, ServerSession.RemotePort);
       finally
        LeaveCSect(ServerSession.Network.FCSect);
       end;
{$IFDEF LOG_SERVER_SEND}
aaWriteToLog('SERVER.DoSendBuffer> Sent-OK, next packet # '+IntToStr(Header.PacketID));
{$ENDIF}
      finally
       LeaveCSect(ServerSession.FCSect);
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
    if (Code = ACRMessage)
    or (Code = ACRMessageAbort) then
     begin
       if ServerSession.MsgControlCode <> ACRTerminate then
         WaitForMessageSent;
     end
    else
     begin
      if Code <> ACRConnected then
       if ServerSession.ControlCode <> ACRTerminate then
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
    if (Code = ACRMessage)
    or (Code = ACRMessageAbort) then
     begin
      if ServerSession.MsgControlCode = ACRTerminate then
        raise EACRException.Create(40070, ErrorRSessionTerminated,[Integer(ServerSession)]);
      inc(ServerSession.ServerMessageID);
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('SERVER-DoSendBuffer> sleep(0) - 2');
{$ENDIF}
      sleep(0);
      ServerSession.MsgPacketIDsToResend.Lock;
      if ServerSession.MsgControlCode <> ACRTerminate then
        ServerSession.MsgPacketIDsToResend.SetSize(0);
      ServerSession.MsgPacketIDsToResend.Unlock;
     end
    else
     begin
      if ServerSession.ControlCode = ACRTerminate then
        raise EACRException.Create(40079, ErrorRCommandSessionTerminated,[ServerSession.RemoteHost+':'+IntToStr(ServerSession.RemotePort),Integer(ServerSession),5]);
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
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> ServerSession.MsgSendStatus = '+IntToStr(ServerSession.MsgSendStatus));
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> End!');
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
aaWriteToLog('TACRServerConnectionManager.DoSendBuffer> - Error:');
aaWriteToLog(E.Message);
try
aaWriteToLog('Command # '+IntToStr(ServerSession.CurrentRequestID-1));
aaWriteToLog('Local port = '+IntToStr(ServerSession.Network.LocalPort));
except
end;
aaWriteToLog('**************************************************************');
{$ENDIF}
     if (Code = ACRMessage) then
      begin
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TACRClientConnectionManager.DoSendBuffer> Abort Message...');
{$ENDIF}
       dec(ServerSession.ServerMessageID);
       try
        DoSendBuffer(ServerSession,nil,0,ACRMessageAbort);
       except
       end;
      end;
     raise;
    end;
 end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
finally
aaStopTime(time17);
end;
{$ENDIF}
end; // DoSendBuffer


//------------------------------------------------------------------------------
// EnableNextCommand
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.EnableNextCommand(ServerSession: PACRSrvrSession);
begin
{$IFDEF LOG_SERVER_ENABLE_NEXT_COMMAND}
aaWriteToLog('EnableNextCommand> START');
{$ENDIF}
      ServerSession.PacketIDsToResend.Lock;
      ServerSession.PacketIDsToResend.SetSize(0);
      ServerSession.PacketIDsToResend.Unlock;
{$IFDEF LOG_SERVER_ENABLE_NEXT_COMMAND}
aaWriteToLog('EnableNextCommand> inc CurrentRequestID...');
{$ENDIF}
      inc(ServerSession.CurrentRequestID);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('ServerSession.ControlCode = '+IntToStr(ServerSession.ControlCode));
{$ENDIF}
      EnterCSect(ServerSession.FCSect);
      if ServerSession.ControlCode = ACRSuspend then
        ServerSession.ControlCode := ACRExecute;
      LeaveCSect(ServerSession.FCSect);
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
procedure TACRServerConnectionManager.SendBuffer(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       Integer = ACRNoAction
                                                  );
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
  SessionFound:         Boolean;
  i:                    Integer;
  Buf:                  PAnsiChar;
  BufSize:              Integer;
begin
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.SendBuffer> - START');
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
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
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
  if Code <> ACRMessage then
   begin
    ServerSession.ReceiveStatus := ACRNo;
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
    ServerSession.MsgReceiveStatus := ACRNo;
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

  if Code <> ACRMessage then
   begin
//     if ServerSession.ReceiveStatus = ACRNo then
//       inc(ServerSession.CurrentRequestID);
   end
  else
   begin
     inc(ServerSession.ServerMessageID);
   end;
*)
{$IFDEF LOG_SERVER_DISCONNECT}
aaWriteToLog('TACRServerConnectionManager.SendBuffer> - FINISH');
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// SendMessage
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.SendMessage(
                          Session:    TACRBaseSession;
                          Buffer:     PAnsiChar;
                          BufferSize: Integer;
                          Code:       TACRControlCode = ACRMessage
                                                  );
var
  SessionFound:   Boolean;
  Sessions:       TACRList;
  i:              Integer;
  ServerSession:  PACRSrvrSession;
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
    raise EACRException.Create(40021, ErrorRSessionNotConnected, [Integer(Session)]);
  // wait for Session be vacant
  StartTime := GetTickCount;
  repeat
   if Session = nil then
     raise EACRException.Create(40071, ErrorRSessionDeleted);
   if ServerSession.MsgControlCode = ACRTerminate then
     raise EACRException.Create(40072, ErrorRSendSessionTerminated);
   if (GetTickCount - StartTime) > ServerSession.Session.ConnectParams.WaitForMessagesSend then
     raise EACRException.Create(40073, ErrorRTimeoutMessageSent,[
{$IFDEF MsgCommunicator}
          ServerSession.Session.UserID,
{$ELSE}
          ServerSession.Session.SessionID,
{$ENDIF}
          ServerSession.Session.ConnectParams.WaitForMessagesSend]);
   if (ServerSession.Status = ACRVacant) then
      break;
{$IFDEF ProcessMessages}
   Application.ProcessMessages;
{$ENDIF ProcessMessages}
   Sleep(ServerSession.Session.ConnectParams.ServerResendDelay);
  until False;
  // block other threads to send at the same time
{$IFDEF MsgCommunicator}
  EnterCSect(TACRServerSession(Session).FCSect);
{$ENDIF}
  try
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.SendMessage> - Start');
{$ENDIF}
(*
   if (TACRCompressionAlgorithm(Session.ConnectParams.CompressionAlgorithm) <> acaNone)
   or (Session.ConnectParams.CryptoInfo.CryptoAlgorithm <> ACR_Cipher_None)
   then
    begin
     Buf := MemoryManager.GetMem(BufferSize);
     Move(Buffer^,Buf^,BufferSize);
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.SendMessage> - SendBuffer SessionID='+IntToStr(Session.SessionID));
{$ENDIF}
     SendBuffer(Session, Buf, BufferSize, ACRMessage);
     MemoryManager.FreeAndNilMem(Buf);
    end
   else
*)
    begin
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.SendMessage> - SendBuffer SessionID='+IntToStr(Session.SessionID));
{$ENDIF}
     SendBuffer(Session, Buffer, BufferSize, Code);
    end;
  finally
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('TACRServerConnectionManager.SendMessage> - SessionID='+IntToStr(Session.SessionID));
aaWriteToLog('TACRServerConnectionManager.SendMessage> - FINISH');
{$ENDIF}
{$IFDEF MsgCommunicator}
   LeaveCSect(TACRServerSession(Session).FCSect);
{$ENDIF}
  end;
end; // SendMessage


//------------------------------------------------------------------------------
// SendPing
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.SendPing(
                          ServerSession:        PACRSrvrSession
                                                          );
var
  Header:          PACRPacketHeader;
begin
  if not FActive then
    Exit;
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
   Header.ControlCode := ACRPing;
   Header.Signature := ACRServerPacketSign;
   Header.Recepient := ServerSession.RemoteClientID;
   Header.ConnectionID := ServerSession.ConnectionID;
   Header.SessionID := ServerSession.Session.SessionID;
   Header.PacketID := 0;
   Header.CurrentRequestID := 0;
   EnterCSect(ServerSession.Network.FCSect);
   try
    ServerSession.Network.SendBuffer(PAnsiChar(Header), SizeOf(TACRPacketHeader), 0, ServerSession.RemoteHost, ServerSession.RemotePort);
   finally
    LeaveCSect(ServerSession.Network.FCSect);
   end;
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
end;// SendPing


//------------------------------------------------------------------------------
// SendAcknowledgement
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.SendAcknowledgement(
                          ServerSession:        PACRSrvrSession;
                          Msg:                  Boolean = False;
                          CurrentRequestID:     Integer = -1
                                                          );
var
  Header:          PACRPacketHeader;
begin
  if not FActive then
    Exit;
  Header := MemoryManager.GetMem(SizeOf(TACRPacketHeader));
  try
   if Msg then
     Header.ControlCode := ACRMessageReceived
   else
     Header.ControlCode := ACRAllPacketsReceived;
   Header.Signature := ACRServerPacketSign;
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
   EnterCSect(ServerSession.Network.FCSect);
   try
    ServerSession.Network.SendBuffer(PAnsiChar(Header), SizeOf(TACRPacketHeader), 0, ServerSession.RemoteHost, ServerSession.RemotePort);
   finally
    LeaveCSect(ServerSession.Network.FCSect);
   end;
  finally
   MemoryManager.FreeAndNilMem(Header);
  end;
end;// SendAcknowledgement


//------------------------------------------------------------------------------
// GetClientInfo
//------------------------------------------------------------------------------
function TACRServerConnectionManager.GetClientInfo(
                          Session:          TACRBaseSession;
                          var Protocol:     TACRClientProtocol;
                          var Host:         AnsiString;
                          var Port:         Integer;
                          var Application:  AnsiString
                                                    ): Boolean;
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
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
       Protocol := acrUDP;
       if ServerSession.Network = FNetwork then
         Protocol := acrUDP
       else
       if ServerSession.Network = FNetworkTCP then
         Protocol := acrTCP;
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
    raise EACRException.Create(40037, ErrorRSessionNotFound,
                                ['Server', Session.SessionID]);
}
end; // GetClientInfo


//------------------------------------------------------------------------------
// GetClientsList
//------------------------------------------------------------------------------
procedure TACRServerConnectionManager.GetClientsList(var Clients: TACRSessionsArray);
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
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
function TACRServerConnectionManager.IsAuthorizationBufferValid(
                      CryptoInfo: TACRCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
begin
// --> added by Leo Martin, 4.03 pr#1, 19 July 2005
  if (CryptoInfo.CryptoAlgorithm <> Byte(TACRServer(FServer).CryptoParams.CryptoAlgorithm)) then
   Result := False
  else
// <-- added by Leo Martin, 4.03 pr#1, 19 July 2005
   Result := fnIsAuthorizationBufferValid(CryptoInfo, Buffer, BufferSize);
end; // IsAuthorizationBufferValid

// TACRServerConnectionManager




////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerSessionThread.Create(
                          Manager:          TACRServerConnectionManager;
                          ServerSession:    PACRSrvrSession;
                          Code:             Integer = ACRNoAction
                                            );
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter20);
aaStartTime(time20);
{$ENDIF}
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
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerSessionThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TACRServerSessionThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER SESSION THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FServerSession.Session <> nil then
    FServerSession.Thread := nil;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionThread,-1,
                  Error)
    else
      TACRNetworkSession(FServerSession.Session).DoOnError(
                  ACRServerSessionThread,-1,
                  Error);
   end;
 end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time20);
{$ENDIF}
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerSessionThread.Execute;
var
  Buf:                 PAnsiChar;
  BufSize, AuBufSize:  Integer;
  ConnectionParams:    PACRConnectionParams;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter13);
aaStartTime(time13);
{$ENDIF}
try // finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionThread.Execute - START - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TACRServerSessionThread> START');
{$ENDIF}
 if (Terminated or (FServerSession = nil)) then
   Exit;
 if FServerSession.ControlCode = ACRTerminate then
   Exit;
 try // except
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionThread.Execute - New Command - GetTickCount='+IntToStr(GetTickCount));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': CurrentRequestID='+IntToStr(FServerSession.CurrentRequestID));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Code='+IntToStr(FCode));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ReceiveStatus = '+IntToStr(FServerSession.ReceiveStatus));
{$ENDIF}
  if (FCode <> ACRDisconnect) then
   begin
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSession.ControlCode='+IntToStr(FServerSession.ControlCode));
{$ENDIF}
    try
     if FCode<>ACRConnect then
      begin
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TACRServerSessionThread.Execute');
{$ENDIF}
//aaWriteToLog('TACRServerSessionThread.Execute 1:'+#13#10+IntToStr(aaGetTickCount));
       FManager.SendAcknowledgement(FServerSession);
//aaWriteToLog('TACRServerSessionThread.Execute 2:'+#13#10+IntToStr(aaGetTickCount));
      end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Acknowledgement sent! - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
    except
     on E:Exception do
      raise EACRException.Create(40519, ErrorRAckn+E.Message);
    end;
    try
//aaWriteToLog('TACRServerSessionThread.Execute 3:'+#13#10+IntToStr(aaGetTickCount));
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TACRServerSessionThread> ReceiveBuffer...');
{$ENDIF}
     try
      FManager.ReceiveBuffer(FServerSession, Buf, BufSize);
     finally
      FServerSession.ReceiveStatus := ACRNo;
     end;
//aaWriteToLog('TACRServerSessionThread.Execute 4:'+#13#10+IntToStr(aaGetTickCount));
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
       raise EACRException.Create(40506, ErrorRCannotReceive+E.Message);
      end
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Buffer received');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSession.ControlCode='+IntToStr(FServerSession.ControlCode));
{$ENDIF}
   end;
  if (FCode = ACRConnect) then
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
//aaWriteToLog('TACRServerSessionThread.Execute 5:'+#13#10+IntToStr(aaGetTickCount));

{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': IsAuthorizationBufferValid');
{$ENDIF}
{$IFDEF MsgCommunicator}
    Move(Buf^, FServerSession.Session.FUserID, SizeOf(FServerSession.Session.FUserID));
    inc(Buf, SizeOf(FServerSession.Session.FUserID));
{$ENDIF}
    Move(PAnsiChar(Buf + SizeOf(TACRConnectionParams))^, AuBufSize, SizeOf(AuBufSize));
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER> AuthorizationBuffer:');
aaWriteBufferToLog(PAnsiChar(Buf + SizeOf(TACRConnectionParams) + SizeOf(AuBufSize)),AuBufSize);
{$ENDIF}
//aaWriteToLog('TACRServerSessionThread.Execute 5:'+#13#10+IntToStr(aaGetTickCount));
    if not FManager.IsAuthorizationBufferValid(
              FServerSession.Session.ConnectParams.CryptoInfo,
              PAnsiChar(Buf + SizeOf(TACRConnectionParams) + SizeOf(AuBufSize)),
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
         raise EACRException.Create(40509, 'ACRConnect section - '+ErrorRDoDisconnect+E.Message);
      end;
{$IFDEF MsgCommunicator}
      dec(Buf, SizeOf(FServerSession.Session.FUserID));
{$ENDIF}
      Exit;
     end;
//aaWriteToLog('TACRServerSessionThread.Execute 6:'+#13#10+IntToStr(aaGetTickCount));
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('IsAuthorizationBufferValid - OK!');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ConnectionParams');
{$ENDIF}
    try
    // Get ConnectParams
//aaWriteToLog('TACRServerSessionThread.Execute 7:'+#13#10+IntToStr(aaGetTickCount));
    ConnectionParams := PACRConnectionParams(Buf);
    FServerSession.Session.FConnectParams.Protocol := ConnectionParams.Protocol;
    FServerSession.Session.FConnectParams.PacketSize := ConnectionParams.PacketSize;
    FServerSession.Session.FConnectParams.CompressionAlgorithm := ConnectionParams.CompressionAlgorithm;
    FServerSession.Session.FConnectParams.CompressionMode := ConnectionParams.CompressionMode;
    FServerSession.Session.FConnectParams.UseServerSettings := ConnectionParams.UseServerSettings;
    // Get client Application name
    SetLength(FServerSession.Application, BufSize-SizeOf(TACRConnectionParams)-SizeOf(AuBufSize)-AuBufSize-1
{$IFDEF MsgCommunicator}
    -SizeOf(FServerSession.Session.FUserID)
{$ENDIF}
    );
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteBufferToLog(Buf+SizeOf(TACRConnectionParams)+SizeOf(AuBufSize)+AuBufSize,BufSize-SizeOf(TACRConnectionParams)-SizeOf(AuBufSize)-AuBufSize-1);
{$ENDIF}
    StrCopy(PAnsiChar(FServerSession.Application), Buf+SizeOf(TACRConnectionParams)+SizeOf(AuBufSize)+AuBufSize);
//aaWriteToLog('TACRServerSessionThread.Execute 8:'+#13#10+IntToStr(aaGetTickCount));
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
      raise EACRException.Create(40510, ErrorRGetConnectParams+E.Message);
    end;
    finally
     MemoryManager.FreeAndNilMem(Buf);
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': SendConnectAckn');
{$ENDIF}
    try
//aaWriteToLog('TACRServerSessionThread.Execute 9:'+#13#10+IntToStr(aaGetTickCount));
     FManager.SendConnectAckn(FServerSession);
//aaWriteToLog('TACRServerSessionThread.Execute 10:'+#13#10+IntToStr(aaGetTickCount));
     FServerSession.Connected := True;
     FFinishing := True;
    except
     on E:Exception do
      raise EACRException.Create(40511, 'ACRConnect section - '+ErrorRSendConnectAckn+E.Message);
    end;
{$IFDEF MsgCommunicator}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ConnectUser...');
{$ENDIF}
//aaWriteToLog('TACRServerSessionThread.Execute 11:'+#13#10+IntToStr(aaGetTickCount));
    if not (TACRServerSession(FServerSession.Session).ConnectUser) then
      FManager.Disconnect(FServerSession.Session);
//aaWriteToLog('TACRServerSessionThread.Execute 12:'+#13#10+IntToStr(aaGetTickCount));
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
  if (FCode = ACRDisconnect) then
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
        raise EACRException.Create(40509, 'ACRDisconnect section - '+ErrorRDoDisconnect+E.Message);
      end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Disconnected');
{$ENDIF}
     end;
   end
  else
*)
  if (FCode = ACRServerSessionTunning) then
   begin
    try
{$IFDEF DEBUG_LOG_NETWORK_TUNER}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRServerSessionTunning...');
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
  if (FCode = ACREcho)
  or (FCode = ACRTunning)
  then
   begin
    try
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Echo...');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': CurrentRequestID = '+IntToStr(FServerSession.CurrentRequestID));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': BufSize = '+IntToStr(BufSize));
{$ENDIF}
    if (FCode <> ACRTunning) then
      if not FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
        Exit;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Decompressed BufSize = '+IntToStr(BufSize));
{$ENDIF}
    try
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('send answer...');
{$ENDIF}
    FManager.SendBuffer(FServerSession.Session, Buf, BufSize, ACRNoAction);
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('sent!');
{$ENDIF}
    except
     on E:Exception do
      raise EACRException.Create(40505, 'Echo section, Code='+IntToStr(FCode)+' - '+ErrorRCannotSendEcho+E.Message);
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
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionThread.Execute - TerminateCommandThreads... - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
//    FManager.TerminateCommandThreads(FServerSession); Does not work in IDE
//    FServerSession.ControlCode := ACRSuspend;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionThread.Execute - TerminateCommandThreads OK - GetTickCount='+IntToStr(GetTickCount));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': BufSize = '+IntToStr(BufSize));
{$ENDIF}
//aaWriteToLog('TACRServerSessionThread.Execute 13:'+#13#10+IntToStr(aaGetTickCount));
    if FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
     begin
//aaWriteToLog('TACRServerSessionThread.Execute 14:'+#13#10+IntToStr(aaGetTickCount));
{$IFDEF DEBUG_LOG_NETWORK_COMMUNICATION}
aaWriteToLog('Server started new request #'+IntToStr(FServerSession.CurrentRequestID));
aaWriteBufferToLog(Buf, BufSize);
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionThread.Execute - Session.ReceiveData - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
      if Terminated then
        Exit;
      try
{$IFDEF MsgCommunicator}
//aaWriteToLog('TACRServerSessionThread.Execute 15:'+#13#10+IntToStr(aaGetTickCount));
      FServerSession.Session.ReceiveData(Buf, BufSize);
//aaWriteToLog('TACRServerSessionThread.Execute 16:'+#13#10+IntToStr(aaGetTickCount));
{$ELSE}
      if FCode = ACRClientCommand then
       begin
        FManager.EnableNextCommand(FServerSession);
 {$IFDEF ClientCommand_Fix}
        FFinishing := True;
 {$ENDIF}
       end;
 {$IFDEF LOG_SERVER_THREAD_SWITCHING}
 aaWriteToLog('TACRServerSessionThread> ReceiveData...');
 {$ENDIF}
      FServerSession.Session.ReceiveData(Buf, BufSize);
{$ENDIF}
{$IFDEF ClientCommand_Fix}
      FFinishing := True;
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('TACRServerSessionThread.Execute> data received');
{$ENDIF}
      except
       on E:Exception do
        begin
{$IFDEF LOG_SERVER_COMMAND_RETRY}
aaWriteToLog('SERVER_SESSION_THREAD> Receive buffer exception');
{$ENDIF}
         raise EACRException.Create(40513,'Command section - '+ErrorRSessionReceiveData+E.Message);
        end;
      end;
     end;
//aaWriteToLog('TACRServerSessionThread.Execute 14:'+#13#10+IntToStr(aaGetTickCount));
//    FManager.TerminateCommandThreads(FServerSession); // - Could be better instead of befor ReceiveData
  end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog('SERVER: FINISHED EXECUTE SESSION *****************************');
{$ENDIF}
 except
  on E: EACRException do
   begin
    try
    FServerSession.ReceiveStatus := ACRNo;
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (FServerSession = nil)
    or (FServerSession.Session = nil)
    then
      TACRServer(FManager.FServer).DoOnConnectionError(ACRServerSessionThread,E.NativeError,Error)
    else
      TACRNetworkSession(FServerSession.Session).DoOnError(ACRServerSessionThread,E.NativeError,Error);
    except
    end;
   end;
  on E: Exception do
   begin
    try
    FServerSession.ReceiveStatus := ACRNo;
    Error:=
                  ErrorRServer+ErrorRServerSessionThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    try
     TACRNetworkSession(FServerSession.Session).DoOnError(ACRServerSessionThread,-1,Error);
    except
     TACRServer(FManager.FServer).DoOnConnectionError(ACRServerSessionThread,-1,Error);
    end;
    except
    end;
   end;
 end;
finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionThread.Execute - FINISH');
{$ENDIF}
//aaWriteToLog('TACRServerSessionThread.Execute ok:'+#13#10+IntToStr(aaGetTickCount));
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TACRServerSessionThread> FINISH');
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time13);
{$ENDIF}
end;
end; // Execute

// TACRServerSessionThread




////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionMsgThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerSessionMsgThread.Create(
                          Manager:          TACRServerConnectionManager;
                          ServerSession:    PACRSrvrSession;
                          Code:             Integer = ACRMessage
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
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('SERVER SESSION MESSAGE THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionMsgThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerSessionMsgThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TACRServerSessionMsgThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session # '+IntToStr(FServerSession.Session.SessionID)+'SessionMsgThread finishing...');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('SERVER SESSION MESSAGE THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FServerSession.Session <> nil then
    FServerSession.MsgThread := nil;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('SERVER SESSION MESSAGE THREAD - FINISHED');
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionMsgThread,-1,
                  Error)
    else
      TACRNetworkSession(FServerSession.Session).DoOnError(
                  ACRServerSessionMsgThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerSessionMsgThread.Execute;
var
  Buf:                 PAnsiChar;
  BufSize:             Integer;
  Queue:               TACRList;
begin
try // finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionMsgThread.Execute - START - GetTickCount='+IntToStr(GetTickCount));
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
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionMsgThread.Execute - New Message - GetTickCount='+IntToStr(GetTickCount));
//aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ClientMessageID='+IntToStr(FServerSession.ClientMessageID));
//aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Code='+IntToStr(FCode));
//aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgReceiveStatus = '+IntToStr(FServerSession.MsgReceiveStatus));
{$ENDIF}
//  if (FCode = ACRMessage) then
   begin
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('ACRServerSessionMsgThread.Execute> Call FManager.ReceiveMessage');
{$ENDIF}
    EnterCSect(FServerSession.FCSect);
    if FServerSession.MsgControlCode = ACRExecute then
      FServerSession.MsgControlCode := ACRSuspend;
    LeaveCSect(FServerSession.FCSect);
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
      raise EACRException.Create(40507,'ACRMessage section - '+ErrorRCannotReceiveMsg+E.Message);
    end;
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Decompress and decrypt buffer...');
{$ENDIF}
    if FManager.DecompressAndDecryptBuffer(FServerSession.Session, Buf, BufSize) then
     begin
//      FManager.TerminateMessageThreads(FServerSession);
      FServerSession.MsgControlCode := ACRExecute;
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
        TACRSendingThread.Create(nil,
                                FManager,@TACRServerSession.ReceiveMessage,
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
        raise EACRException.Create(40512,'ACRMessage section - '+ErrorRSessionReceiveMessage+E.Message);
      end;
     end;
   end;
{$IFDEF LOG_SLEEP-0}
aaWriteToLog('TACRServerSessionMsgThread.Execute> sleep(0)');
{$ENDIF}
   sleep(0);
  until False;
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('==============================================================');
aaWriteToLog('SERVER: FINISHED EXECUTE SESSION *****************************');
aaWriteToLog('==============================================================');
{$ENDIF}
 except
  on E: EACRException do
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
      TACRServer(FManager.FServer).DoOnConnectionError(ACRServerSessionMsgThread,E.NativeError,Error)
    else
      TACRNetworkSession(FServerSession.Session).DoOnError(ACRServerSessionMsgThread,E.NativeError,Error);
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
     TACRNetworkSession(FServerSession.Session).DoOnError(ACRServerSessionMsgThread,-1,Error);
    except
     TACRServer(FManager.FServer).DoOnConnectionError(ACRServerSessionMsgThread,-1,Error);
    end;
    except
    end;
   end;
 end;
finally
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionMsgThread.Execute - FINISH');
{$ENDIF}
end;
end; // Execute

// TACRServerSessionMsgThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionDisconnectThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerSessionDisconnectThread.Create(
                          Manager:          TACRServerConnectionManager;
                          ServerSession:    PACRSrvrSession;
                          CurrentRequestID: Integer = -1
                                            );
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  FManager.FDisconnectThreads.Add(Self);
  FServerSession := ServerSession;
  FCurrentRequestID := CurrentRequestID;
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('SERVER SESSION DISCONNECT THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - START');
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionDisconnectThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerSessionDisconnectThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TACRServerSessionDisconnectThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Destroy - START');
aaWriteToLog('SERVER SESSION DISCONNECT THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  inherited Destroy;
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Destroy> inherited - OK');
{$ENDIF}
  if (FManager<>nil) then
    FManager.DecThreadCount;
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Destroy> DecThreadCount - OK');
{$ENDIF}
  if (FManager<>nil) then
    if (FManager.FDisconnectThreads<>nil) then
      FManager.FDisconnectThreads.Remove(Self);
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('SERVER SESSION DISCONNECT THREAD - FINISHED');
{$ENDIF}
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionDisconnectThread,-1,
                  Error)
    else
      TACRNetworkSession(FServerSession.Session).DoOnError(
                  ACRServerSessionDisconnectThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerSessionDisconnectThread.Execute;
begin
try // finally
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Execute> START - GetTickCount='+IntToStr(GetTickCount));
{$ENDIF}
 try // except
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Execute> Disconnect...');
{$ENDIF}
    try
     if FServerSession.ControlCode = ACRTerminate then
       Exit
     else
       inc(FServerSession.Status);
     try
      FManager.SendAcknowledgement(FServerSession, False, FCurrentRequestID);
     finally
      dec(FServerSession.Status);
     end;
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Execute> Acknowledgement sent!');
{$ENDIF}
    except
     on E:Exception do
      raise EACRException.Create(40519, ErrorRAckn+E.Message);
    end;
    sleep(ACRServerSessionDisconnectTimeOut);
    if Terminated then
      Exit;
    if FServerSession.Session <> nil then
     begin
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Execute> DoDisconnect');
aaWriteToLog('TACRServerSessionDisconnectThread.Execute> SessionID='+IntToStr(Integer(FServerSession.Session.SessionID)));
{$ENDIF}
      try
       FManager.DoDisconnect(FServerSession.Session);
      except
       on E:Exception do
        raise EACRException.Create(40509, ErrorRDoDisconnect+E.Message);
      end;
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog('TACRServerSessionDisconnectThread.Execute> Disconnected');
{$ENDIF}
     end;
 except
  on E: EACRException do
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
      TACRServer(FManager.FServer).DoOnConnectionError(ACRServerSessionDisconnectThread,E.NativeError,Error)
    else
      TACRNetworkSession(FServerSession.Session).DoOnError(ACRServerSessionDisconnectThread,E.NativeError,Error);
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
     TACRNetworkSession(FServerSession.Session).DoOnError(ACRServerSessionDisconnectThread,-1,Error);
    except
     TACRServer(FManager.FServer).DoOnConnectionError(ACRServerSessionDisconnectThread,-1,Error);
    end;
    except
    end;
   end;
 end;
finally
{$IFDEF LOG_SERVER_SESSION_DISCONNECT_THREAD}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': TACRServerSessionDisconnectThread.Execute - FINISH');
{$ENDIF}
end;
end; // Execute

// TACRServerSessionDisconnectThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerSessionTerminatorThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerSessionTerminatorThread.Create(
                          Manager:          TACRServerConnectionManager
                                            );
begin
 try
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - START - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FTerminatedSessions := nil;
  FManager := Manager;
  FManager.IncThreadCount;
  FTerminatedSessions := TACRThreadList.Create('',false,0,10,100,false);
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
  FRecreate := True;
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
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionTerminatorThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TACRServerSessionTerminatorThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TACRServerSessionTerminatorThread.Destroy> START');
{$ENDIF}
  if FManager.SessionTerminator <> nil then
    FManager.SessionTerminator := nil;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TACRServerSessionTerminatorThread.Destroy> Free...');
{$ENDIF}
  FTerminatedSessions.Free;
  FTerminatedSessions := nil;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TACRServerSessionTerminatorThread.Destroy> inherited...');
{$ENDIF}
  inherited Destroy;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TACRServerSessionTerminatorThread.Destroy> dec...');
{$ENDIF}
  FManager.DecThreadCount;
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('TACRServerSessionTerminatorThread.Destroy> FINISH');
{$ENDIF}
  if not Terminated then
  if FRecreate then
   begin
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      FManager.SessionTerminator := TACRServerSessionTerminatorThread.Create(FManager);
   end;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerSessionTerminatorThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionTerminatorThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerSessionTerminatorThread.Execute;
var
  Sessions:             TACRList;
  Session:              TACRBaseSession;
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
   begin
    FRecreate := False;
    Exit;
   end;
  Sessions := FTerminatedSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - i='+IntToStr(i)+'- THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
     if Terminated then
      begin
       FRecreate := False;
       Exit;
      end;
     Session := Sessions.Items[i];
     Sessions.Delete(i);
{$IFDEF LOG_SERVER_TERMINATOR}
aaWriteToLog('SERVER Session Terminator THREAD - EXECUTE - DoDisconect... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
     try
      FManager.Disconnect(Session, @Terminated);
     except
      on E:Exception do
       raise EACRException.Create(40520, ErrorRDisconnect+E.Message);
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
  if FManager.FServer = nil then
    sleep(ACRServerSessionTerminatorSleep)
  else
    sleep(TACRServer(FManager.FServer).NetworkSettings.ServerSessionTerminatorSleep);
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerSessionTerminatorThread,-1,
                  Error)
    else
      TACRNetworkSession(Session).DoOnError(
                  ACRServerSessionTerminatorThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerPingClientsThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerPingClientsThread.Create(
                          Manager:          TACRServerConnectionManager
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
  FRecreate := True;
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
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerPingClientsThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TACRServerPingClientsThread.Destroy;
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
  if not Terminated then
  if FRecreate then
   begin
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      FManager.PingClientsThread := TACRServerPingClientsThread.Create(FManager);
   end;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerPingClientsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerPingClientsThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------

procedure TACRServerPingClientsThread.Execute;
var
  Sessions:             TACRList;
  ServerSession:        PACRSrvrSession;
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
   begin
    FRecreate := False;
    Exit;
   end;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE - Lock Sessions... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  for i:=0 to FManager.SessionsCount do
   begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> i='+IntToStr(i));
{$ENDIF}
    if Terminated then
     begin
      FRecreate := False;
      Exit;
     end;
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
     EnterCSect(ServerSession.FCSect);
     try
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> ServerSession = '+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
       if ServerSession.ControlCode = ACRTerminate then
         continue;
       inc(ServerSession.Status);
       Delay := ServerSession.Session.ConnectParams.ServerPingSleep;
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('SERVER Ping Clients THREAD - EXECUTE> ServerSession.Session.ConnectParams.WaitForPingAnswer = '+IntToStr(ServerSession.Session.ConnectParams.WaitForPingAnswer));
{$ENDIF}
       if FManager.FIncomingPackets.Count = 0 then
         ServerSession.Session.FConnectParams.WaitForPingAnswer := TACRServer(FManager.FServer).NetworkSettings.WaitForPingAnswer
       else
        begin
         MinWaitForPingAnswer := (
          (Sessions.Count + 1) * (ServerSession.Session.ConnectParams.ServerPingSleep +
           ServerSession.Session.ConnectParams.ServerResendDelay + ACRResendDelay) * 2);
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
      LeaveCSect(ServerSession.FCSect);
     end;
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
       if ((aaGetTickCount - ServerSession.LastReceivePingTime) >
              ServerSession.Session.ConnectParams.WaitForPingAnswer) then
          begin
{$IFDEF DEBUG_LOG_PING}
aaWriteToLog('LastReceivePingTime =' + IntToStr(ServerSession.LastReceivePingTime));
aaWriteToLog('WaitForPingAnswer   =' + IntToStr(ServerSession.Session.ConnectParams.WaitForPingAnswer));
aaWriteToLog('Waited              =' + IntToStr(aaGetTickCount-ServerSession.LastReceivePingTime));
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
    sleep(ACRServerPingSleep)
  else
    sleep(TACRServer(FManager.FServer).NetworkSettings.ServerPingSleep);
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerPingClientsThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerPingClientsThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute




////////////////////////////////////////////////////////////////////////////////
//
// TACRServerListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerListenerThread.Create(
                       Manager:       TACRServerConnectionManager
                                            );
begin
 try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Create> START - '+IntToStr(GetTickCount));
{$ENDIF}
  FManager := Manager;
  FManager.IncThreadCount;
  FManager.ListenerThread := Self;
  FManager.FListenerStoped := False;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Create> inherited... - '+IntToStr(GetTickCount));
{$ENDIF}
  inherited Create(False);
  Priority := tpNormal;//tpHigher;
  FreeOnTerminate := True;
  FRecreate := True;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Create> FINISH - '+IntToStr(GetTickCount));
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerListenerThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerListenerThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerListenerThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Destroy> START');
{$ENDIF}
  FManager.FListenerStoped := True;
  FManager.ListenerThread := nil;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Destroy> DecThreadCount');
{$ENDIF}
  if (FManager<>nil) then
    FManager.DecThreadCount;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Destroy> inherited Destroy');
{$ENDIF}
  inherited Destroy;
  if not Terminated then
  if FRecreate then
   begin
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
     begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Destroy> Recreate packet processor thread...');
{$ENDIF}
      FManager.ListenerThread := TACRServerListenerThread.Create(FManager);
     end;
   end;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Destroy> FINISHED');
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerListenerThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerListenerThread,-1,
                  Error);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerListenerThread.Execute;
label
  StartProcessing,
  KillPacket;
var
  Header:               PACRPacketHeader;
  Packets:              TACRList;
  NetworkPacket:        PACRNetworkPacket;
  Sessions:             TACRList;
  i:                    Integer;
  Bool:                 Boolean;
  EmptyTime,
  SleepTime,
  StartTime:            Cardinal;

function AllMsgPacketsReceived: Boolean;
var
  i:                    Integer;
  Packets:              TACRList;
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
  Packets:              TACRList;
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
  if (NetworkPacket.Packet.BufferSize < SizeOf(TACRPacketHeader)) then
   begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER: too small packet size = '+IntToStr(NetworkPacket.Packet.BufferSize));
{$ENDIF}
    Exit;
   end;
// Check sign
  if (Header.Signature <> ACRClientPacketSign) then
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
    FManager.PacketResendRequest(NetworkPacket.Packet.Buffer, ServerSession.Network, NetworkPacket.FromHost, NetworkPacket.FromPort);
    Exit;
   end;
// Check ServerID
  if (Header.Recepient <> TACRServer(FManager.FServer).ServerID) then
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
                and  ( (Header.ControlCode = ACRConnect)
                    or (Header.ControlCode = (ACRConnect + ACRLastPacket))
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
  if (Header.ControlCode <> ACRConnect) then // packet is not from Connect request
  if (Header.ControlCode <> (ACRConnect+ACRLastPacket)) then
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
    ServerSession.Session := TACRServerSession.Create(FManager.FServer);
    TACRServerSession(ServerSession.Session).SetServerSession(ServerSession);
    ServerSession.Session.SessionID := Header.SessionID;
    ServerSession.RemoteHost := NetworkPacket.FromHost;
    ServerSession.RemotePort := NetworkPacket.FromPort;
    ServerSession.ContactCount := 0;
    InitCSect(ServerSession.FCSect,'ServerSession='+IntToStr(ServerSession.Session.SessionID),true);

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
    if Header.ControlCode = ACRDisconnect then
     begin
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TACRServerListenerThread.Execute - IsConnectionValid');
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
    DeleteCSect(ServerSession.FCSect);
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
  if ServerSession.ControlCode <> ACRExecute then
   begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('IsCommandLock> ControlCode <> ACRExecute');
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
      if ServerSession.SendStatus = ACRNotSent then // sending answer, current request
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
  if Header.CurrentRequestID > ServerSession.CurrentRequestID then // Error!
   begin // disconnect
    if ServerSession.DisconnectThread = nil then // are not deleting
      ServerSession.DisconnectThread :=
             TACRServerSessionDisconnectThread.Create(FManager, ServerSession,
                                                      Header.CurrentRequestID);
    Exit;
   end;
  if Header.CurrentRequestID < ServerSession.CurrentRequestID then // old request
   begin // request already processed - kill old packet
    Exit; // client received answer - no needs to ackn
   end;
// CurrentRequestID is valid
  if ServerSession.Thread <> nil then  // request is processing now
   begin
{$IFDEF ClientCommand_Fix}
    if ServerSession.Thread.FFinishing = True then // wait for session finish
     begin
      StartTime := GetTickCount;
      while ((GetTickCount - StartTime) < ACRWaitForServerSessionThreadFinish) do
       begin
        if ServerSession.Thread = nil then
         begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('SERVER PACKET PROCESSOR> server session finished for '+IntToStr(GetTickCount - StartTime)+' msec');
{$ENDIF}
          break;
         end;
        sleep(1);
       end;
     end;
{$ENDIF}
    if ServerSession.Thread <> nil then  // request is still processing
     begin
      if ServerSession.ReceiveStatus = ACRFull then // all packets received, buffer not received - current request
       begin
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('SERVER-IsCurrentRequestIDValid> all packets received, buffer not received: current request - ackn, kill packet');
{$ENDIF}
        FManager.SendAcknowledgement(ServerSession,False,Header.CurrentRequestID);
       end;
      if ServerSession.SendStatus = ACRNotSent then // client is sending answer, old request
       begin
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TACRServerListenerThread.Execute - IsCurrentRequestIDValid');
{$ENDIF}
        FManager.SendAcknowledgement(ServerSession,False,Header.CurrentRequestID);
       end;
      Exit;
     end;
   end;
  Result := True;
end; // IsCurrentRequestIDValid


begin // TACRServerListenerThread.Execute;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ***** SERVER LISTENER START *****');
{$ENDIF}
 EmptyTime := aaGetTickCount;
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
    FRecreate := False;
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
      if (aaGetTickCount >= (EmptyTime + ACRPacketProcessTimeOut)) then
       begin
        SleepTime := 1; // To avoid 100% CPU usage
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TACRServerListenerThread.Execute> new SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
       end;
     Continue;
    end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter21);
aaStartTime(time21);
{$ENDIF}
  EmptyTime := aaGetTickCount;
  SleepTime := 0;
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TACRServerListenerThread.Execute> new SleepTime = '+IntToStr(SleepTime));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_INCOMING_PACKETS_QUEUE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Packets Count = '+IntToStr(Packets.Count));
{$ENDIF}
   NetworkPacket := PACRNetworkPacket(Packets.Items[0]);
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
aaWriteToLog('TACRServerListenerThread.Execute> SERVER<<< '
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
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> Header not valid, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Execute> Header not valid');
{$ENDIF}
    goto KillPacket;
   end;
  if    // first packet in multi-packet connect request
  ((Header.ControlCode=ACRConnect) and (Header.PacketID=0))
  or    // single-packet connect request
  ((Header.ControlCode=(ACRConnect+ACRLastPacket)) and (Header.PacketID=0))
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
      InitCSect(ServerSession.FCSect);
      ServerSession.Network := NetworkPacket.Network;
      ServerSession.Connected := False;
      ServerSession.AnswerTime := 0;
      ServerSession.LastSendPingTime := GetTickCount;
      ServerSession.LastReceivePingTime := ServerSession.LastSendPingTime;
      ServerSession.Status := ACRVacant;
      ServerSession.ReceiveStatus := ACRStart;
      ServerSession.MsgReceiveStatus := ACRNo;
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
      ServerSession.Session := TACRServerSession.Create(FManager.FServer);
      TACRServerSession(ServerSession.Session).SetServerSession(ServerSession);
      ServerSession.Session.FConnectParams.CryptoInfo := TACRServer(FManager.FServer).CryptoParams.GetCryptoParams;
      ServerSession.Thread := nil;
      ServerSession.MsgThread := nil;
      ServerSession.MsgThreadCount := 0;
      ServerSession.DisconnectThread := nil;
//      ServerSession.ListeningThreads := TACRThreadList.Create;
      ServerSession.ControlCode := ACRExecute;
//      ServerSession.ListeningThreads.Add(self);
//      ServerSession.MsgListeningThreads := TACRThreadList.Create;
      ServerSession.MsgControlCode := ACRExecute;
// Set SessionID
      EnterCSect(FManager.FCSect);
      EnterCSect(ServerSession.FCSect);
      ServerSession.Session.SessionID := FManager.FSessionID;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+':   New: @session='+IntToHex(Integer(ServerSession),6)+', Server SessionID='+IntToStr(ServerSession.Session.SessionID));
{$ENDIF}
      inc(FManager.FSessionID);
      if FManager.FSessionID = INVALID_SESSION_ID then
       inc(FManager.FSessionID);
      LeaveCSect(FManager.FCSect);
      LeaveCSect(ServerSession.FCSect);
// Create PacketIDsToResend
      ServerSession.PacketIDsToResend := TACRThreadIntArray.Create;
      ServerSession.MsgPacketIDsToResend := TACRThreadIntArray.Create;
// Create new packets list
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Packets list create');
{$ENDIF}
      ServerSession.Packets := TACRThreadList.Create;
      Packets := ServerSession.Packets.LockList;
      try
       Packets.Capacity := ACRDefaultPacketsInRequest; // Allocate some place in list
      finally
       ServerSession.Packets.UnlockList;
      end;
      ServerSession.MsgQueue := TACRThreadList.Create;
      ServerSession.MsgPackets := TACRThreadList.Create;
      ServerSession.MsgReceivedPackets := nil;
      Packets := ServerSession.MsgPackets.LockList;
      try
       Packets.Capacity := ACRDefaultPacketsInRequest; // Allocate some place in list
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
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> ServerSession.Thread <> nil, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
      if (ServerSession.ControlCode <> ACRExecute) then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Not Execute - Terminate ListeningThread, ServerSession.ControlCode='+IntToStr(ServerSession.ControlCode));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> ControlCode <> ACRExecute, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
      if (ServerSession.CurrentRequestID > Header.CurrentRequestID) then // packet from old connection request
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Connection exists - SendConnectAckn');
{$ENDIF}
        FManager.SendConnectAckn(ServerSession, Header.CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> ServerSession.Thread <> nil, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
        goto KillPacket;
       end;
      if ServerSession.MsgThread <> nil then
        FManager.CloseThread(@ServerSession.MsgThread,ACRServerListenerThread,ErrorRServerSessionMsgThread,
            ServerSession.Session.ConnectParams.WaitForServerSessionThreadTimeOut);
      if ServerSession.DisconnectThread <> nil then
        FManager.CloseThread(@ServerSession.DisconnectThread,ACRServerListenerThread,ErrorRServerSessionDisconnectThread,
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
    if Header.ControlCode=ACRConnect+ACRLastPacket then
     ServerSession.ReceiveStatus := ACRFull;
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ServerSessionThread.Create');
{$ENDIF}
    ServerSession.Thread := TACRServerSessionThread.Create(FManager,
                                                  ServerSession, ACRConnect);
    Continue;
   end; // Connect
// check SessionID and ConnactionID
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> IsConnectionValid... - time = '+IntToStr(GetTickCount));
{$ENDIF}
   if not IsConnectionValid then
    begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> Invalid connection, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread.Execute> Invalid connection');
{$ENDIF}
     goto KillPacket;
    end;
// check CurrentRequestID
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('TACRServerListenerThread> Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> check CurrentRequestID... - time = '+IntToStr(GetTickCount));
{$ENDIF}
  if (Header.ControlCode = ACRMessageReceived)
  or (Header.ControlCode = ACRMessagePacketResendRequest)
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
  if (Header.ControlCode = ACRMessage)
  or (Header.ControlCode = (ACRMessage + ACRLastPacket))
  or (Header.ControlCode = ACRMessageAbort)
  then
   begin
     if (Header.CurrentRequestID < ServerSession.ClientMessageID)
     or ((Header.CurrentRequestID = ServerSession.ClientMessageID) and
         (ServerSession.MsgReceiveStatus = ACRFull))
     then // lost acknowledgement
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Send Ackn');
{$ENDIF}
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TACRServerListenerThread.Execute - check message CurrentRequestID');
{$ENDIF}
       FManager.SendAcknowledgement(ServerSession, True, Header.CurrentRequestID);
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> lost acknowledgement, SessionID = '+IntToStr(Header.SessionID));
aaWriteToLog('Header.CurrentRequestID = '+IntToStr(Header.CurrentRequestID));
aaWriteToLog('ServerSession.ClientMessageID = '+IntToStr(ServerSession.ClientMessageID));
if ServerSession.MsgReceiveStatus = ACRFull then
aaWriteToLog('MsgFull')
else
aaWriteToLog('not ACRFull');
{$ENDIF}
       goto KillPacket; // Do not replace correct packets with doubles
      end;
(*
    if ServerSession.ClientMessageID > Header.CurrentRequestID then // old message
     begin
      goto KillPacket;
     end;
    if ServerSession.ClientMessageID < Header.CurrentRequestID then // lost acknowledgement NetworkPacket.From client
      ServerSession.MsgSendStatus := ACRSent;
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
      if (ServerSession.MsgControlCode <> ACRExecute) then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': MsgControlCode <> ACRExecute -- kill packet');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> ServerSession.MsgControlCode <> ACRExecute, SessionID = '+IntToStr(Header.SessionID));
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

    if Header.ControlCode <> ACRDisconnect then
    if Header.ControlCode <> ACRPing then
    if (Header.ControlCode <> ACRAllPacketsReceived) then
// added as a fix to ACR v.5.50
    if Header.ControlCode <> ACRLogon then
    if Header.ControlCode <> ACRLogoff then
    if Header.ControlCode <> ACRAllPacketsReceived then
    if Header.ControlCode <> ACRPacketResendRequest then
    if Header.ControlCode <> ACRMessageReceived then
    if Header.ControlCode <> ACRMessagePacketResendRequest then
    if Header.ControlCode <> ACRMessageAbort then
     begin
      if IsCommandLock then
       begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('TACRServerListenerThread> command lock, current command executed # '+IntToStr(ServerSession.CurrentRequestID)+', request # '+IntToStr(Header.CurrentRequestID)+', packet # '+IntToStr(Header.PacketID));
{$ENDIF}
(*
        if ServerSession.ReceiveStatus = ACRFull then // buffer not received
         begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('all packets received, buffer not received -- kill packet');
{$ENDIF}
          goto KillPacket;
         end;
        if Header.CurrentRequestID < ServerSession.CurrentRequestID then
        if Header.CurrentRequestID = ServerSession.CurrentRequestID then // could be equal if session sent answer but not finished yet
        if ServerSession.SendStatus = ACRNotSent then // client is sending answer, old request
*)
(*
        if Header.CurrentRequestID = ServerSession.CurrentRequestID then
         begin
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('packet from current request that executed now -- kill packet');
{$ENDIF}
          goto KillPacket;
         end;
*)
//        if Header.ControlCode > ACRLastPacket then
         begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter23);
aaStartTime(time23);
{$ENDIF}
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
if ServerSession.SendStatus = ACRSent then
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
               NetworkPacket := PACRNetworkPacket(Packets.Items[0]);
               Continue;
              end;
{$IFDEF LOG_SERVER_IS_COMMAND_LOCK}
aaWriteToLog('get packet # '+IntToStr(i+1)+' ...');
{$ENDIF}
             NetworkPacket := PACRNetworkPacket(Packets.Items[i+1]);
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
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time23);
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
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> Command Lock, SessionID = '+IntToStr(Header.SessionID));
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
   ACRDisconnect:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRDisconnect');
{$ENDIF}
//     FManager.CommandReceived(ServerSession,Header.ControlCode,Header.CurrentRequestID);
{
     EnterCSect(FManager.FCSect);
     ServerSession.ControlCode := ACRTerminate;
     ServerSession.MsgControlCode := ACRSuspend;
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
              TACRServerSessionDisconnectThread.Create(FManager, ServerSession,
                                                      Header.CurrentRequestID);
     goto KillPacket;
    end;
   ACRPing:
    begin
     ServerSession.LastReceivePingTime := GetTickCount;
     goto KillPacket;
    end;
   ACRPacketResendRequest:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRPacketResendRequest');
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
   ACRMessagePacketResendRequest:
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRMessagePacketResendRequest');
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
   ACRAllPacketsReceived:
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
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRAllPacketsReceived');
{$ENDIF}
       ServerSession.SendStatus := ACRSent;
       ServerSession.PacketIDsToResend.Lock;
       ServerSession.PacketIDsToResend.SetSize(0);
       ServerSession.PacketIDsToResend.Unlock;
//       SleepTime := 1; -- Do not uncomment, will sleep(0) in any case
{$IFDEF LOG_SERVER_THREAD_SWITCHING}
aaWriteToLog('TACRServerListenerThread.Execute> new SleepTime = '+IntToStr(SleepTime)+' - ACRAllPacketsReceived');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('--------------------------------------------------------------');
aaWriteToLog('SERVER received Command Acknowledgement');
aaWriteToLog('--------------------------------------------------------------');
{$ENDIF}
      end;
     goto KillPacket;
    end;
   ACRMessageReceived:
    begin
     ServerSession.MsgSendStatus := ACRSent;
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
     ACRMessageAbort:
//------------------------------------------------------------------------------
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('ACRMessageAbort...');
aaWriteToLog('ServerSession.ClientMessageID = '+IntToStr(ServerSession.ClientMessageID));
aaWriteToLog('ServerSession.ServerMessageID = '+IntToStr(ServerSession.ServerMessageID));
{$ENDIF}
       if ServerSession.ClientMessageID = Header.CurrentRequestID then
         try
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('ACRMessageAbort try intered');
{$ENDIF}
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TACRServerPacketProcessorThread> free packets...');
{$ENDIF}
          FManager.FreePackets(ServerSession.MsgPackets);
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TACRServerPacketProcessorThread> count = 0...');
{$ENDIF}
          ServerSession.MsgPackets.LockList;
          ServerSession.MsgPackets.Count := 0;
          ServerSession.MsgPackets.UnlockList;
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TACRServerPacketProcessorThread> SendAcknowledgement...');
{$ENDIF}
          FManager.SendAcknowledgement(ServerSession,true);
         finally
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('ACRMessageAbort fianally intered');
{$ENDIF}
          inc(ServerSession.ClientMessageID);
{$IFDEF LOG_SERVER_MESSAGE_ABORT}
aaWriteToLog('TACRServerPacketProcessorThread> ServerSession.ClientMessageID='+IntToStr(ServerSession.ClientMessageID));
{$ENDIF}
         end;
       goto KillPacket;
      end;
//------------------------------------------------------------------------------
   ACRMessage,
   (ACRMessage+ACRLastPacket):
//------------------------------------------------------------------------------
    begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': message packet');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> ACRMessage packet - starting... - time = '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TACRServerListenerThread.Execute> message with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}

//     if Header.ControlCode < ACRLastPacket then // Enable LastPacket to start session thread
(*
 moved to CurrentRequestID checking
     if (Header.CurrentRequestID  ServerSession.ClientMessageID)
     or ((Header.CurrentRequestID = ServerSession.ClientMessageID) and
         (ServerSession.MsgReceiveStatus = ACRFull))
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
aaWriteToLog('TACRServerListenerThread.Execute> AllMsgPacketsReceived: receive message with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}
           FManager.MessageReceived(ServerSession);
          end;
{
         else
           if (Header.ControlCode >= ACRLastPacket) then
             ServerSession.ReceiveStatus := ACRNotFull; // start requesting
}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Old message packet will be killed');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> doubled packet, SessionID = '+IntToStr(Header.SessionID));
{$ENDIF}
         goto KillPacket; // Do not replace correct packets with doubles
        end;
// First packet in new request?
     if Packets.Count = 0 then
      begin
       ServerSession.MsgReceiveStatus := ACRStart;
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
      if (ServerSession.MsgReceiveStatus <> ACRFull) then
        Packets.Items[Header.PacketID] := NetworkPacket.Packet
      else
       begin
        Bool := True;
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TACRServerListenerThread.Execute> kill doubled message packet with SessionID = '+IntToStr(Integer(Header.SessionID)));
{$ENDIF}
       end;
     finally
      ServerSession.MsgPackets.UnlockList;
     end;
     if Bool then
      begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
if Header.ControlCode = ACRMessage+ACRLastPacket then
  aaWriteToLog('TACRServerListenerThread.Execute> bool, SessionID = '+IntToStr(Header.SessionID));
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
     if (Header.ControlCode >= ACRLastPacket) then
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRLastPacket');
{$ENDIF}
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> AllMsgPacketsReceived?? - time = '+IntToStr(GetTickCount));
{$ENDIF}
       if AllMsgPacketsReceived then
        begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Yes');
{$ENDIF}
         ServerSession.MsgReceiveStatus := ACRFull;  // Allow to extract NetworkPacket.Packet.Buffer
        end
       else
        begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': No');
{$ENDIF}
         // start resend requesting
         ServerSession.MsgReceiveStatus := ACRNotFull;
        end;
      end; // Last Packet
// Full Answer
{$IFDEF DEBUG_LOG_SERVER_SESSION_MESSAGE_THREAD}
aaWriteToLog('ServerListenerThread> Full message? - time = '+IntToStr(GetTickCount));
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ClientMessageID = '+IntToStr(ServerSession.ClientMessageID));
{$ENDIF}
     if ServerSession.MsgReceiveStatus = ACRFull then
{
       if Terminated then
         goto KillPacket
       else
}
        begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
aaWriteToLog('TACRServerListenerThread.Execute> MsgReceiveStatus = ACRFull: receive message with SessionID = '+IntToStr(Integer(Header.SessionID)));
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
   ACREcho,
   ACRTunning,
   ACRServerSessionTunning,
   ACRConnect, // for packets with ID>0, not for first packet
   ACRNewRequest,
{$IFNDEF MsgCommunicator}
   ACRClientCommand,
   ACRServerCommand,
{$ENDIF}
   ACRLastPacket..(ACRMessage+ACRLastPacket-1),
   (ACRMessage+ACRLastPacket+1)..127,
   ACRNoAction:
    begin
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter22);
aaStartTime(time22);
{$ENDIF}
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Data packet - '+IntToStr(GetTickCount));
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
     if (ServerSession.ReceiveStatus = ACRFull) then // lost acknowledgement
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Full Answer!');
{$ENDIF}
       if (Header.ControlCode <> ACRConnect)
       and (Header.ControlCode <> (ACRConnect+ACRLastPacket))
       then
{$IFDEF DEBUG_LOG_ACKN}
aaWriteToLog('ACKN> TACRServerListenerThread.Execute - Command process, full answer and old packet check');
{$ENDIF}
         FManager.SendAcknowledgement(ServerSession, False, Header.CurrentRequestID);
       goto KillPacket; // Do not replace correct packets with doubles
      end;
// new request?
(*
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('new request?');
{$ENDIF}
     if Header.ControlCode >= ACRNewRequest then
      if ServerSession.CurrentRequestID < Header.CurrentRequestID then
       begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog('Yes');
{$ENDIF}
        ServerSession.ReceiveStatus := ACRStart;
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
       ServerSession.ReceiveStatus := ACRStart;
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
      if (ServerSession.ReceiveStatus <> ACRFull) then
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
     if (Header.ControlCode >= ACRLastPacket) then
      begin
{$IFDEF LOG_SERVER_PACKET_PROCESSOR}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': ACRLastPacket');
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
         ServerSession.ReceiveStatus := ACRNotFull;
         FManager.ResendRequestThread.FNeeded := True;
        end;
      end; // Last Packet
// End data packet process
     Continue;
    end // data packet process
   else
     raise EACRException.Create(40022, ErrorRUnknownControlCode, [Header.ControlCode]);
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
  if FManager.FIncomingPackets <> nil then
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
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time22);
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time21);
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerListenerThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerListenerThread,-1,
                  Error);
    except
    end;
   end;
 end;
 until False;
end; // Execute

// TACRServerListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerResendRequestThread.Create(
                       Manager:           TACRServerConnectionManager
                                            );
begin
 try
  FNeeded := False;
  FManager := Manager;
  FManager.IncThreadCount;
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
  FRecreate := True;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
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
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerResendRequestThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerResendRequestThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('Server RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FManager.ResendRequestThread <> nil then
    FManager.ResendRequestThread := nil;
  inherited Destroy;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('Server RESENDING THREAD - FINISHED');
{$ENDIF}
  FManager.DecThreadCount;
  if not Terminated then
  if FRecreate then
   begin
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      FManager.ResendRequestThread := TACRServerResendRequestThread.Create(FManager);
   end;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerResendRequestThread,-1,
                  Error);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerResendRequestThread.Execute;
var
  i, j, k,
  PacketsCount:       Integer;
  Packets:            TACRList;
  Sessions:           TACRList;
  ServerSession:      PACRSrvrSession;
  Header:             TACRPacketHeader;
  StartTime,
  Delay:              Cardinal;

function IsRequestNeeded(ServerSession: PACRSrvrSession): Boolean;
begin
  Result := True;
  if ServerSession.ReceiveStatus <> ACRNotFull then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> ACRNotFull <> (ServerSession.ReceiveStatus='+IntToStr(ServerSession.ReceiveStatus)+')');
{$ENDIF}
    Result := False;
    Exit;
   end;
  if ServerSession.ControlCode = ACRTerminate then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> ServerSession.ControlCode = ACRTerminate');
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
        Delay := (1 + (ACRServerRequestDelay
                                                div (FManager.SessionsCount+1)))
      else
        Delay := (1 + (TACRServer(FManager.FServer).NetworkSettings.ServerRequestDelay
                                                div (FManager.SessionsCount+1)));
      StartTime := GetTickCount;
      while ((GetTickCount-StartTime) < Delay) do
       begin
        if Terminated then
         begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> Terminated in sessions loop');
{$ENDIF}
          FRecreate := False;
          Exit;
         end;
        if (FNeeded = True) then
         begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerResendRequuestThread> needed, break - skip sleep');
{$ENDIF}
          break;
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
         if ServerSession.ReceiveStatus = ACRNotFull then
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
     if ServerSession.ControlCode = ACRTerminate then
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
aaWriteToLog('ServerResendRequuestThread> TACRServerResendRequestThread');
{$ENDIF}
    // Make PacketHeader
    Header.Signature := ACRServerPacketSign;
    Header.Recepient := ServerSession.RemoteClientID;
    Header.Sender := ServerSession.Network.FLocalClient;
    Header.ConnectionID := ServerSession.ConnectionID;
    Header.SessionID := ServerSession.Session.SessionID;
    Header.PacketID := 0;
    Header.ControlCode := ACRPacketResendRequest;
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
        FRecreate := False;
        Exit;
       end;
      if ServerSession.ControlCode = ACRTerminate then
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
          FManager.PacketResendRequest(@Header, ServerSession.Network, ServerSession.RemoteHost, ServerSession.RemotePort, i, ServerSession.Packets);
{$ELSE}
          FManager.PacketResendRequest(@Header, ServerSession.Network, ServerSession.RemoteHost, ServerSession.RemotePort, i);
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
          for k:=0 to (ACRServerRequestDelay div 2) do
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
      if ServerSession.ControlCode = ACRExecute then
        ServerSession.ControlCode := ACRSuspend;
      LeaveCSect(FManager.FCSect);
}
//      ServerSession.ReceiveStatus := ACRFull;
      Packets := ServerSession.Packets.LockList;
      try
       if Packets.Count > 0 then
        begin
         Packet := Packets.Items[0];
         PHeader := PACRPacketHeader(Packet.Buffer);
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerResendRequestThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerResendRequestThread,-1,
                  Error);
    except
    end;
   end;
 end;
end;// Execute



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerMsgResendRequestThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRServerMsgResendRequestThread.Create(
                       Manager:           TACRServerConnectionManager
                                            );
begin
 try
  FManager := Manager;
  FManager.IncThreadCount;
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
  FRecreate := True;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
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
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerMsgResendRequestThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRServerMsgResendRequestThread.Destroy;
begin
 try
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('Server MESSAGE RESENDING THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' - FINISH');
{$ENDIF}
  if FManager.MsgResendRequestThread <> nil then
    FManager.MsgResendRequestThread := nil;
  inherited Destroy;
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('Server MESSAGE RESENDING THREAD - FINISHED');
{$ENDIF}
  FManager.DecThreadCount;
  if not Terminated then
  if FRecreate then
   begin
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
      FManager.MsgResendRequestThread := TACRServerMsgResendRequestThread.Create(FManager);
   end;
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRMsgResendRequestThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerMsgResendRequestThread,-1,
                  Error);
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRServerMsgResendRequestThread.Execute;
var
  i, j,
  PacketsCount:       Integer;
  Packets:            TACRList;
  Sessions:           TACRList;
  ServerSession:      PACRSrvrSession;
  Header:             TACRPacketHeader;
  StartTime,
  Delay:              Cardinal;

function IsRequestNeeded(ServerSession: PACRSrvrSession): Boolean;
begin
  Result := True;
  if ServerSession.MsgReceiveStatus <> ACRNotFull then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> ACRNotFull <> (ServerSession.MsgReceiveStatus='+IntToStr(ServerSession.MsgReceiveStatus)+')');
{$ENDIF}
    Result := False;
    Exit;
   end;
  if ServerSession.MsgControlCode = ACRTerminate then
   begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> ServerSession.MsgControlCode = ACRTerminate');
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
      Delay := (1 + (ACRServerRequestDelay
                                              div (FManager.SessionsCount+1)))
    else
      Delay := (1 + (TACRServer(FManager.FServer).NetworkSettings.ServerRequestDelay
                                              div (FManager.SessionsCount+1)));
    StartTime := GetTickCount;
    while ((GetTickCount-StartTime) < Delay) do
     begin
      if Terminated then
       begin
{$IFDEF LOG_SERVER_REQUEST_RESENDING}
aaWriteToLog('ServerMsgResendRequuestThread> Terminated in sessions loop');
{$ENDIF}
        FRecreate := False;
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
aaWriteToLog('TACRServerMsgResendRequestThread> @ServerSession='+IntToStr(Integer(ServerSession)));
{$ENDIF}
     if ServerSession.ControlCode = ACRTerminate then
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
aaWriteToLog('TACRServerMsgResendRequestThread> Make PacketHeader...');
{$ENDIF}
    // Make PacketHeader
    Header.Signature := ACRServerPacketSign;
    Header.Recepient := ServerSession.RemoteClientID;
    Header.Sender := ServerSession.Network.FLocalClient;
    Header.ConnectionID := ServerSession.ConnectionID;
    Header.SessionID := ServerSession.Session.SessionID;
    Header.PacketID := 0;
    Header.ControlCode := ACRMessagePacketResendRequest;
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
        FRecreate := False;
        Exit;
       end;
      if ServerSession.MsgControlCode = ACRTerminate then
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
          FManager.PacketResendRequest(@Header, ServerSession.Network, ServerSession.RemoteHost, ServerSession.RemotePort, i, True);
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
          for k:=0 to (ACRServerRequestDelay div 2) do
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
      if ServerSession.MsgControlCode = ACRExecute then
        ServerSession.MsgControlCode := ACRSuspend;
      LeaveCSect(FManager.FCSect);
}
//      ServerSession.MsgReceiveStatus := ACRFull;
      FManager.MessageReceived(ServerSession);
     end;
*)
   until False; // Get new Session
{$IFDEF LOG_SERVER_THREADS}
aaWriteToLog('ServerMsgResendRequuestThread> TACRServerSessionThread.Execute - START');
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
      TACRServer(FManager.FServer).DoOnConnectionError(
                  ACRServerMsgResendRequestThread,-1,
                  Error)
    else
      TACRNetworkSession(ServerSession.Session).DoOnError(
                  ACRServerMsgResendRequestThread,-1,
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
                      CryptoInfo: TACRCryptoInfo;
                      Buffer:     PAnsiChar;
                      BufferSize: Integer
                                    ): Boolean;
var ms:             TACRMemoryStream;
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
  ms := TACRMemoryStream.Create(Buffer, BufferSize);
  try
   try
    LoadDataFromStream(size,SizeOf(crc32),ms,11322);
    LoadDataFromStream(crc32,SizeOf(crc32),ms,11323);
    if (ms.Size - ms.Position <> size) then
     raise EACRException.Create(11325,ErrorLInvalidStreamSize,[ms.Size,(ms.Position+size)]);
   except
     Result := False;
     Exit;
   end;
    ACRDecryptBuffer(CryptoInfo,PAnsiChar(Buffer+ms.Position),size);
    crc32_1 := ACRCountCRC(0,PAnsiChar(Buffer+ms.Position),size);
    Result := (crc32 = crc32_1);
  finally
    ms.SetBuffer(nil,0); // Msg 4.10 difference
    { TODO -oAlex : move to msg with new memory engine - 2 }
    ms.Free;
  end;
end; // fnIsAuthorizationBufferValid
{$ENDIF SERVER_VERSION}

{$IFDEF MSWINDOWS}
function TerminateThread;   external    kernel32  name 'TerminateThread';
{$ENDIF}

initialization

 NetLog := ExtractFilePath(ParamStr(0))+'acr_NetLog.txt';

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRConnection> initialized');
{$ENDIF}

finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRConnection> finalized');
{$ENDIF}

end.

