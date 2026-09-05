unit ACRNetwork;

interface

{$I ACRVer.inc}

uses
  Classes, SysUtils,
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Libc,
{$ENDIF}

// Accuracer units
{$IFDEF DEBUG_LOG}
  ACRDebug,
{$ENDIF}
  ACRTypes,
  ACRTypesThread,
  ACRConst,
  ACRExcept,
  ACRMemory;          // last

const

  MAX_PORT = 2147483646;

///////////////////////////////////////////////////////////////////////////////
// I/O Modes
// ----------------------------------------------------------------------------
  ACR_Blocking      = 1;
  ACR_NonBlocking   = 2;
  ACR_OverlappedIO  = 3;
///////////////////////////////////////////////////////////////////////////////

  PF_INET         =  2;
  SOCK_STREAM     =  1;             { stream socket }
  SOCK_DGRAM      =  2;             { datagram socket }
  SOCKET_ERROR    = -1;
  AF_INET         =  2;
  IPPROTO_TCP     =  6;             { TCP }
  IPPROTO_UDP     = 17;             { user datagram protocol }
  INADDR_NONE     = -1;

  FD_SETSIZE      =  1; // default value = 64;

type

{$NODEFINE TSocket}
{$IFDEF X64_ON}
  TSocket = NativeInt; // 8 bytes
{$ELSE}
  TSocket = Integer;
{$ENDIF}

  SunB = packed record
    s_b1, s_b2, s_b3, s_b4: Byte;
  end;

  SunW = packed record
    s_w1, s_w2: Word;
  end;

  PInAddr = ^TInAddr;
  TACRin_addr = record
    case integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: LongInt);
  end;
  TInAddr = TACRin_addr;

  TACRsockaddr_in = record
    case Integer of
      0: (sin_family: Word;
          sin_port:   Word;
          sin_addr:   TInAddr;
          sin_zero:   array[0..7] of AnsiChar);
      1: (sa_family:  Word;
          sa_data:    array[0..13] of AnsiChar)
  end;
  TSockAddr = TACRsockaddr_in;

  PHostEnt = ^THostEnt;
  TACRhostent = record
    h_name: PAnsiChar;
    h_aliases: ^PChar;
    h_addrtype: Smallint;
    h_length: Smallint;
    case Byte of
      0: (h_addr_list: ^PChar);
      1: (h_addr: ^PChar)
  end;
  THostEnt = TACRhostent;

  PFDSet = ^TFDSet;
  TFDSet = record
    fd_count: Integer;
    fd_array: array[0..FD_SETSIZE-1] of TSocket;
  end;

  PTimeVal = ^TTimeVal;
  TACRtimeval = record
    tv_sec: Longint;
    tv_usec: Longint;
  end;
  TTimeVal = TACRtimeval;

const
  IOCPARM_MASK = $7f;
  IOC_IN       = $80000000;
  FIONBIO      = IOC_IN or { set/clear non-blocking i/o }
    ((Longint(SizeOf(Longint)) and IOCPARM_MASK) shl 16) or
    (Longint(Byte('f')) shl 8) or 126;

  WSADESCRIPTION_LEN     =   256;
  WSASYS_STATUS_LEN      =   128;

type
  TWSAData = record
    wVersion: Word;
    wHighVersion: Word;
    szDescription: array[0..WSADESCRIPTION_LEN] of AnsiChar;
    szSystemStatus: array[0..WSASYS_STATUS_LEN] of AnsiChar;
    iMaxSockets: Word;
    iMaxUdpDg: Word;
    lpVendorInfo: PAnsiChar;
  end;

// Procedures
function SocketError: Integer;
function LookupHostAddr(const hn: AnsiString): AnsiString;
function AddrToSock(Host: AnsiString; Port: Integer; Zero: Boolean = false): TSockAddr;
procedure AddrFromSock(Addr: TSockAddr; out Host: AnsiString; out Port: Integer);

{$IFDEF LINUX}
(*$HPPEMIT '#include <sys/socket.h>'*)
{$ENDIF}
{$IFDEF MSWINDOWS}
const
  winsocket = 'wsock32.dll';
  kernel32  = 'kernel32.dll';
function socket(af, Struct, protocol: Integer): TSocket; stdcall;
function ioctlsocket(s: TSocket; cmd: DWORD; var arg: Longint): Integer; stdcall;
function bind(s: TSocket; var addr: TSockAddr; namelen: Integer): Integer; stdcall;
function getsockname(s: TSocket; var addr: TSockAddr; var namelen: Integer): Integer; stdcall;
function sendto(s: TSocket; var Buf; len, flags: Integer;
                  var addrto: TSockAddr; tolen: Integer): Integer; stdcall;
function recvfrom(s: TSocket; var Buf; len, flags: Integer;
                  var from: TSockAddr; var fromlen: Integer): Integer; stdcall;
function select(nfds: Integer; readfds, writefds, exceptfds: PFDSet;
                  timeout: PTimeVal): Longint; stdcall;
function inet_addr(cp: PAnsiChar): Longint; stdcall; {PInAddr;}  { TInAddr }
function gethostbyname(name: PAnsiChar): PHostEnt; stdcall;
function htons(hostshort: Word): Word; stdcall;
function ntohs(netshort: Word): Word; stdcall;
function closesocket(s: TSocket): Integer; stdcall;
function WSAStartup(wVersionRequired: Word; var WSData: TWSAData): Integer; stdcall;
function WSACleanup: Integer; stdcall;
function WSAGetLastError: Integer; stdcall;
function TerminateThread(hThread: THandle; dwExitCode: Longword): Boolean; stdcall;
{$ENDIF}

var
  FNetworkThreads:     TACRThreadList;

// Forward Declarations

type
  TACRListenerThread = class;

////////////////////////////////////////////////////////////////////////////////
//
// TACRapiNetwork
//
////////////////////////////////////////////////////////////////////////////////

  TACRDataReceivedNotifyEvent = procedure(
                             Buffer:    PAnsiChar;
                             Count:     Integer;
                             FromHost:  AnsiString;
                             FromPort:  Integer
                                          ) of object;

  TACRDisconnectNotifyEvent = procedure(
                             FromHost:  AnsiString;
                             FromPort:  Integer;
                             Recv:      Boolean = False
                                          ) of object;

  TACRapiNetwork = class (TObject)
   public
    Recreate:             Boolean;
   private
    FOwner:               TObject;
    FDisconnected:        Boolean;
    FPacketSize:          Integer;
    FProtocol:            Integer;
    FConnectTimeOut:      Integer;
    FRemoteHost:          AnsiString;
    FRemotePort:          Integer;
   protected
    FLocalHost:           AnsiString;
    FLocalPort:           Integer;
    FSocket:              Integer;
    FListener:            TACRListenerThread;
    FActive:              Boolean;
    FIOMode:              Byte;
    FOnDataReceived:      TACRDataReceivedNotifyEvent;
    FOnDisconnect:        TACRDisconnectNotifyEvent;
    procedure SetActive(Value: Boolean);
    procedure SetRemoteHost(Host: AnsiString);
    function GetRemoteHost: AnsiString;
    procedure SetRemotePort(Port: Integer);
    function GetRemotePort: Integer;
    procedure SetLocalHost(Host: AnsiString);
    function GetLocalHost: AnsiString;
    procedure SetPacketSize(Size: Integer);
    procedure SetLocalPort(Port: Integer);
    function GetLocalPort: Integer;
    procedure StartListening; dynamic;
    procedure StopListening; dynamic;
    procedure Open; dynamic;
    procedure BindSocket;
    procedure Close(Socket: Integer = 0); dynamic;
   public
    property OnDataReceived: TACRDataReceivedNotifyEvent read FOnDataReceived write FOnDataReceived;
    property OnDisconnect: TACRDisconnectNotifyEvent read FOnDisconnect write FOnDisconnect;
    constructor Create(Owner: TObject; Protocol: Integer = ACR_UDP;
                       aConnectTimeOut: Integer = ACR_CONNECT_TIMEOUT);
    destructor Destroy; override;
    procedure SendBuffer(
                          Buffer:     PAnsiChar;
                          Count:      Integer;
                          aSocket:     Integer = 0;
                          aRemoteHost: AnsiString = '###';
                          aRemotePort: Integer = 0
                         ); dynamic;
   public
    property Active: Boolean read FActive write SetActive;
    property RemoteHost: AnsiString read GetRemoteHost write SetRemoteHost;
    property RemotePort: Integer read GetRemotePort write SetRemotePort;
    property LocalHost: AnsiString read GetLocalHost write SetLocalHost;
    property LocalPort: Integer read GetLocalPort write SetLocalPort;
    property PacketSize: Integer read FPacketSize write SetPacketSize;
    property ConnectTimeOut: Integer read FConnectTimeOut write FConnectTimeOut;
  end; // TACRapiNetwork


  TACRListenerThread = class(TACRThread)
  private
  public
   FOwner:          TACRapiNetwork;
  protected
    procedure SelectParams(Socket: Integer; out State: TFDSet; out Time: TTimeVal);
    function IsDataReceived(Socket: Integer; pState: PFDSet; pTime: PTimeVal): Integer;
    function IsReadyToSend(Socket: Integer; pState: PFDSet; pTime: PTimeVal): Integer;
  public
    constructor Create;
    destructor Destroy; override;
  end;// TACRListenerThread


  TACROnDisconnectThread = class(TACRThread)
  private
    FapiNetwork:    TACRapiNetwork;
    FRecv:          Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(
                        apiNetwork:     TACRapiNetwork;
                        Recv:           Boolean = False
                      );
    destructor Destroy; override;
  end;// TACROnDisconnectThread



implementation

uses
  ACRNetworkUDP,
  ACRNetworkTCP,
  ACRConnection;


////////////////////////////////////////////////////////////////////////////////
//
// TACRapiNetwork
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRapiNetwork.Create(Owner: TObject; Protocol: Integer = ACR_UDP;
                                  aConnectTimeOut: Integer = ACR_CONNECT_TIMEOUT);
begin
  FOwner := Owner;
  inherited Create;
  Recreate := True;
  FProtocol := Protocol;
  FActive := False;
  FDisconnected := False;
  FPacketSize := ACRDefaultPacketSize;
  FLocalHost := '';
  FLocalPort := ACRDefaultClientPort;
  FRemoteHost := ACRDefaultHost;
  if Protocol = ACR_UDP then
    FRemotePort := ACRDefaultServerPort
  else
    FRemotePort := ACRDefaultServerPortTCP;
  FConnectTimeOut := aConnectTimeOut;
  FListener := nil;
  StartListening;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRapiNetwork.Create>  Socket #'+IntToStr(Integer(FSocket)));
{$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRapiNetwork.Destroy;
begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRapiNetwork.Destroy>  Socket #'+IntToStr(Integer(FSocket)));
{$ENDIF}
 try
  StopListening;
  FDisconnected := True;
 except
 end;
 inherited Destroy;
 if Recreate then
  begin
    TACRNetwork(FOwner).FACRNetwork := TACRapiNetwork.Create(FOwner);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgapiNetwork.Destroy> API Network Thread Recreated');
{$ENDIF}
  end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRapiNetwork.Destroy - FINISHED');
{$ENDIF}
end;// Destoy


//------------------------------------------------------------------------------
// SetRemoteHost
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SetRemoteHost(Host: AnsiString);
begin
  FRemoteHost := Host;
end;


//------------------------------------------------------------------------------
// GetRemoteHost
//------------------------------------------------------------------------------
function TACRapiNetwork.GetRemoteHost: AnsiString;
begin
  Result := FRemoteHost;
end;


//------------------------------------------------------------------------------
// SetRemotePort
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SetRemotePort(Port: Integer);
begin
  FRemotePort := Port;
end;


//------------------------------------------------------------------------------
// GetRemotePort
//------------------------------------------------------------------------------
function TACRapiNetwork.GetRemotePort: Integer;
begin
  Result := FRemotePort;
end;


//------------------------------------------------------------------------------
// GetLocalHost
//------------------------------------------------------------------------------
function TACRapiNetwork.GetLocalHost: AnsiString;
begin
  Result := FLocalHost;
end;


//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TACRapiNetwork.GetLocalPort: Integer;
begin
  Result := FLocalPort;
end;


//------------------------------------------------------------------------------
// SetPacketSize
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SetPacketSize(Size: Integer);
begin
{$IFDEF DEBUG_LOG_NETWORK_PACKET_SIZE}
aaWriteToLog('TACRapiNetwork.SetPacketSize> old PacketSize = '+IntToStr(FPacketSize));
aaWriteToLog('TACRapiNetwork.SetPacketSize> new PacketSize = '+IntToStr(Size));
{$ENDIF}
  if FPacketSize = Size then Exit;
{
  if FListener <> nil then
    StopListening;
}
  FPacketSize := Size;
{
  StartListening;
}
end;


//------------------------------------------------------------------------------
// SetLocalPort
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SetLocalPort(Port: Integer);
begin
{$IFDEF LOG_NETWORK_LOCAL_PORT}
aaWriteToLog('TACRapiNetwork.SetLocalPort> Socket # '+IntToStr(FSocket)+'; local port: old '+IntToStr(FLocalPort)+', new '+IntToStr(Port));
{$ENDIF}
  if FLocalPort = Port then Exit;
{$IFDEF LOG_NETWORK_LOCAL_PORT}
aaWriteToLog('TACRapiNetwork.SetLocalPort> StopListening...');
{$ENDIF}
  if FListener <> nil then
    StopListening; // you must close socket to change Local parameter
  FLocalPort := Port;
{$IFDEF LOG_NETWORK_LOCAL_PORT}
aaWriteToLog('TACRapiNetwork.SetLocalPort> StartListening...');
{$ENDIF}
  StartListening;
{$IFDEF LOG_NETWORK_LOCAL_PORT}
aaWriteToLog('TACRapiNetwork.SetLocalPort> FINISH');
{$ENDIF}
end;


//------------------------------------------------------------------------------
// SetLocalHost
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SetLocalHost(Host: AnsiString);
begin
  if FLocalHost = Host then Exit;
  StopListening; // you must close socket to change Local parameter
  FLocalHost := Host;
  StartListening;
end;


//------------------------------------------------------------------------------
// SetActive
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SetActive(Value: Boolean);
begin
  if Value = FActive then Exit; // you must close socket to change Local parameters
  if Value then
    Open
  else
    Close;
  FActive := Value;
end;// SetActive


//------------------------------------------------------------------------------
// StartListening
//------------------------------------------------------------------------------
procedure TACRapiNetwork.StartListening;
begin
  if Active = False then
    Open;
end; // StartListening


//------------------------------------------------------------------------------
// StopListening
//------------------------------------------------------------------------------
procedure TACRapiNetwork.StopListening;
begin
  FActive := False;
end; // StopListening


//------------------------------------------------------------------------------
// Open
//------------------------------------------------------------------------------
procedure TACRapiNetwork.Open;
var
  Mode:      LongInt;
  struct,
  proto:      Integer;
begin
  // prepare params
  if (FProtocol = ACR_UDP) then
   begin
    struct := SOCK_DGRAM;
    proto := IPPROTO_UDP;
   end
  else
  if (FProtocol = ACR_TCP) then
   begin
    struct := SOCK_STREAM;
    proto := IPPROTO_TCP;
   end
  else
   raise EACRException.Create(40157, ErrorRUnknownProtocol, [FProtocol]);
  // open socket
  FSocket := socket(PF_INET, struct, proto);
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRapiNetwork.Open> new socket # '+IntToStr(FSocket));
{$ENDIF}
  if FSocket = SOCKET_ERROR then
    raise EACRException.Create(40032, ErrorRCannotOpenSocket, ['socket', SocketError]);
  if FIOMode = ACR_NonBlocking then
   begin
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRapiNetwork.Open> non-blocking...');
{$ENDIF}
    Mode := 1; // <> 0 - non-blocking, = 0 - blocking
    ioctlsocket(FSocket, FIONBIO, Mode);
   end;
end; // Open


//------------------------------------------------------------------------------
// Bind
//------------------------------------------------------------------------------
procedure TACRapiNetwork.BindSocket;
var
  RetCode:    Integer;
  Addr:       TSockAddr;
  Bound:      Boolean;
  i:          Integer;
begin
  // set parameters
  Addr := AddrToSock(FLocalHost, FLocalPort);
  // binding
  Bound := False;
  for i:=FLocalPort to MAX_PORT do
   begin
    if bind(FSocket, Addr, sizeof(Addr)) = SOCKET_ERROR then
      RetCode := SocketError
    else
     begin
      Bound := True;
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRapiNetwork.BindSocket> Bound socket # '+IntToStr(FSocket)+' to '+FLocalHost+':'+IntToStr(FLocalPort));
{$ENDIF}
      break; // bound
     end;
    if RetCode = 10048 then // port is already in use
     begin                  // search for another port
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRapiNetwork.BindSocket> port '+IntToStr(FLocalPort)+' is already in use, search for another port...');
{$ENDIF}
      inc(FLocalPort);
      Addr.sin_port := htons(FLocalPort);
     end
    else
      raise EACRException.Create(40032, ErrorRCannotOpenSocket, ['bind', RetCode]);
   end; // binding
  if not Bound then
    raise EACRException.Create(40032, ErrorRCannotOpenSocket, ['bind: cannot bound', RetCode]);
  if FLocalPort = 0 then
   begin
    i := sizeof(Addr);
    RetCode := getsockname(FSocket, Addr, i);
    if RetCode = SOCKET_ERROR then
     begin
      RetCode := SocketError;  // Do not raise an exception: socket is bound but port is unknown
     end
    else
      FLocalPort := Integer(ntohs(Addr.sin_port));
   end;
end; // Bind


//------------------------------------------------------------------------------
// Close
//------------------------------------------------------------------------------
procedure TACRapiNetwork.Close(Socket: Integer = 0);
var
  RetCode:    Integer;
begin
  if (Socket = 0) then
    Socket := FSocket;
{$IFDEF MSWINDOWS}
  RetCode := closesocket(Socket);
{$ENDIF}
{$IFDEF LINUX}
  RetCode := Libc.__close(Socket);
{$ENDIF}
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRapiNetwork.Close> Socket # '+IntToStr(Socket)+' closed!');
{$ENDIF}
  if RetCode = SOCKET_ERROR then
    raise EACRException.Create(40033, ErrorRCannotCloseSocket, [SocketError]);
end; // Close


//------------------------------------------------------------------------------
// SendBuffer
//------------------------------------------------------------------------------
procedure TACRapiNetwork.SendBuffer(
                          Buffer:     PAnsiChar;
                          Count:      Integer;
                          aSocket:     Integer = 0;
                          aRemoteHost: AnsiString = '###';
                          aRemotePort: Integer = 0
                                    );
var
  RetCode,
  Flags:  Integer;
  Addr: TSockAddr;
begin
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRapiNetwork.SendBuffer> START');
{$ENDIF}
  if aSocket = 0 then
    aSocket := FSocket;
  if aRemoteHost = '###' then
    aRemoteHost := FRemoteHost;
  if aRemotePort = 0 then
    aRemotePort := FRemotePort;
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRapiNetwork.SendBuffer> Socket # '+IntToStr(aSocket)+'; '+IntToStr(Count)+' bytes sending via Protocol='+IntToStr(FProtocol)+' from '+LocalHost+':'+IntToStr(LocalPort)+', to '+aRemoteHost+':'+IntToStr(aRemotePort));
{$ENDIF}
  // set parameters
  Flags := 0;
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRapiNetwork.SendBuffer> get addr...');
{$ENDIF}
  if FProtocol = ACR_UDP then
    Addr := AddrToSock(aRemoteHost, aRemotePort, true);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
 try
{$ENDIF}
  // send...
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRapiNetwork.SendBuffer> sending...');
{$ENDIF}
  if FDisconnected then
    Exit
  else
    RetCode := sendto(aSocket, Buffer^, Count, Flags, Addr, sizeof(Addr));
  if RetCode = SOCKET_ERROR then
    raise EACRException.Create(40030, ErrorRNetSend, [SocketError]);
  if RetCode < Count then
    raise EACRException.Create(40166, ErrorRNetSendBufSmall, [RetCode, Count, aRemoteHost, aRemotePort]);
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRapiNetwork.SendBuffer> sent succesfully!');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
 except
  on E: Exception do
    begin
aaWriteToLog('**************************************************************');
aaWriteToLog('ACRNetwork> TACRapiNetwork.SendBuffer - Error:');
aaWriteToLog(E.Message);
aaWriteToLog('**************************************************************');
    end;
 end;
{$ENDIF}
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRapiNetwork.SendBuffer> FINISH');
{$ENDIF}
end; // SendBuffer


// TACRapiNetwork



////////////////////////////////////////////////////////////////////////////////
//
// TACRListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRListenerThread.Create;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
var
  NetworkThreads:     TACRList;
{$ENDIF}
begin
 try
  inherited Create(False);
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Create> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FreeOnTerminate := False;
  FRecreate := True;
  if FNetworkThreads <> nil then
    FNetworkThreads.Add(Self);
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Listener Thread Added');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TACRNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRListenerThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRListenerThread.Destroy;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
var
  NetworkThreads:     TACRList;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Destroy> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
{$IFDEF MSWINDOWS}
//  TerminateThread(Handle, 0);
{$ENDIF}
{$IFDEF LINUX}
{$ENDIF}
  inherited Destroy;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Listener Thread Remove...');
{$ENDIF}
  if FNetworkThreads <> nil then
    FNetworkThreads.Remove(Self);
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Listener Thread Removed');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TACRNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Destroy> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' TERMINATED');
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// SelectParams
//------------------------------------------------------------------------------
procedure TACRListenerThread.SelectParams(Socket: Integer; out State: TFDSet; out Time: TTimeVal);
var
  ErrorCode:  Integer;
begin
  State.fd_count := 1;
  State.fd_array[0] := Socket;
  Time.tv_sec := 0;
  Time.tv_usec := 1;
end;


//------------------------------------------------------------------------------
// IsDataReceived
//------------------------------------------------------------------------------
function TACRListenerThread.IsDataReceived(Socket: Integer; pState: PFDSet; pTime: PTimeVal): Integer;
var
  ErrorCode:  Integer;
begin
 // wait for incoming packet
 repeat
  Result := select(0, pState, nil, nil, pTime);
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRListenerThread.IsDataReceived - "select" returned '+IntToStr(Result));
{$ENDIF}
  if Result = SOCKET_ERROR then
   begin
    ErrorCode := SocketError;
    if (ErrorCode=10038) then
     begin
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRListenerThread.IsDataReceived - "select" returned SOCKET_ERROR='+IntToStr(ErrorCode)+' - recreate socket');
{$ENDIF}
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRListenerThread.IsDataReceived - reopen socket...');
{$ENDIF}
      try
       FOwner.Close;
      except
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRListenerThread.IsDataReceived - close socket exception!');
{$ENDIF}
      end;
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRListenerThread.IsDataReceived - socket closed, open new socket...');
{$ENDIF}
      FOwner.Open;
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRListenerThread.IsDataReceived - socket recreated');
      Continue;
{$ENDIF}
     end;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRListenerThread.IsDataReceived - "select" returned SOCKET_ERROR='+IntToStr(ErrorCode));
aaWriteToLog('**************************************************************');
{$ENDIF}
    if (Assigned(TACRapiNetwork(FOwner).FOnDisconnect))
    and (ErrorCode=10054)
    then
     begin
      TACROnDisconnectThread.Create(TACRapiNetwork(FOwner));
      Exit;
     end
    else
      raise EACRException.Create(40031, ErrorRNetReceive, ['select', ErrorCode]);
   end;
 until (pState^.fd_array[0] = Socket);
end; // IsDataReceived


//------------------------------------------------------------------------------
// IsReadyToSend
//------------------------------------------------------------------------------
function TACRListenerThread.IsReadyToSend(Socket: Integer; pState: PFDSet; pTime: PTimeVal): Integer;
var
  ErrorCode:  Integer;
begin
  Result := select(0, nil, pState, nil, pTime);
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('MsgNetwork> TACRListenerThread.IsReadyToSend - "select" returned '+IntToStr(Result));
{$ENDIF}
end; // IsReadyToSend


// TACRListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TACROnDisconnectThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACROnDisconnectThread.Create(
                        apiNetwork:     TACRapiNetwork;
                        Recv:           Boolean = False

                                          );
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
var
  NetworkThreads:     TACRList;
{$ENDIF}
begin
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
  FapiNetwork := apiNetwork;
  FRecv := Recv;
  if FNetworkThreads <> nil then
    FNetworkThreads.Add(Self);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TACRNetwork> OnDisconnect Thread Added');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TACRNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACROnDisconnectThread.Destroy;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
var
  NetworkThreads:     TACRList;
{$ENDIF}
begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('MsgNetwork> TACROnDisconnectThread.Destroy - START');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACROnDisconnectThread.Destroy> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  inherited Destroy;
  if FNetworkThreads <> nil then
    FNetworkThreads.Remove(Self);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TACRNetwork> OnDisconnect Thread Removed');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TACRNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACROnDisconnectThread.Destroy> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+' TERMINATED');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('MsgNetwork> TACROnDisconnectThread.Destroy - FINISH');
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACROnDisconnectThread.Execute;
begin
  FapiNetwork.FDisconnected := True;
  FapiNetwork.FOnDisconnect(FapiNetwork.RemoteHost, FapiNetwork.RemotePort, FRecv);
end; // Execute

// TACROnDisconnectThread



////////////////////////////////////////////////////////////////////////////////
//
// Procedures
//
////////////////////////////////////////////////////////////////////////////////

function SocketError: Integer;
begin
 {$IFDEF MSWINDOWS}
  Result := WSAGetLastError;
 {$ENDIF}
 {$IFDEF LINUX}
  Result := errno;
 {$ENDIF}

{$IFNDEF MSWINDOWS}
 {$IFNDEF LINUX}
  Result := 0;
 {$ENDIF}
{$ENDIF}
end;


function LookupHostAddr(const hn: AnsiString): AnsiString;
var
  h: PHostEnt;
begin
  Result := '';
  if hn <> '' then
  begin
    if hn[1] in ['0'..'9'] then
    begin
      if inet_addr(pAnsiChar(hn)) <> INADDR_NONE then
        Result := hn;
    end
    else
    begin
      h := gethostbyname(pAnsiChar(hn));
      if h <> nil then
        with h^ do
        Result := format('%d.%d.%d.%d', [ord(h_addr^[0]), ord(h_addr^[1]),
      		  ord(h_addr^[2]), ord(h_addr^[3])]);
    end;
  end
  else Result := '0.0.0.0';
end;


function AddrToSock(Host: AnsiString; Port: Integer; Zero: Boolean = false): TSockAddr;
begin
 Result.sin_family := AF_INET;
 Result.sin_addr.s_addr := inet_addr(pAnsiChar(LookupHostAddr(Host)));
 Result.sin_port := htons(Port);
 if Zero then
   FillChar(Result.sin_zero, SizeOf(Result.sin_zero), 0);
end;


procedure AddrFromSock(Addr: TSockAddr; out Host: AnsiString; out Port: Integer);
begin
 Host := IntToStr(Addr.sin_addr.S_un_b.s_b1)+'.'+
         IntToStr(Addr.sin_addr.S_un_b.s_b2)+'.'+
         IntToStr(Addr.sin_addr.S_un_b.s_b3)+'.'+
         IntToStr(Addr.sin_addr.S_un_b.s_b4);
 Port := Integer (ntohs(Addr.sin_port));
end;

{$IFDEF MSWINDOWS}
function socket;            external    winsocket name 'socket';
function ioctlsocket;       external    winsocket name 'ioctlsocket';
function bind;              external    winsocket name 'bind';
function getsockname;       external    winsocket name 'getsockname';
function sendto;            external    winsocket name 'sendto';
function select;            external    winsocket name 'select';
function recvfrom;          external    winsocket name 'recvfrom';
function inet_addr;         external    winsocket name 'inet_addr';
function gethostbyname;     external    winsocket name 'gethostbyname';
function htons;             external    winsocket name 'htons';
function ntohs;             external    winsocket name 'ntohs';
function closesocket;       external    winsocket name 'closesocket';
function WSAStartup;        external    winsocket name 'WSAStartup';
function WSACleanup;        external    winsocket name 'WSACleanup';
function WSAGetLastError;   external    winsocket name 'WSAGetLastError';
function TerminateThread;   external    kernel32  name 'TerminateThread';
{$ENDIF}

var
{$IFDEF MSWINDOWS}
  WSAData:            TWSAData;
{$ENDIF}
  NetworkThreads:     TACRList;
  i:                  Integer;
  Err:                Boolean;

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgNetwork> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

  FNetworkThreads := TACRThreadList.Create;

{$IFDEF MSWINDOWS}
  if WSAStartup($0101, WSAData) = SOCKET_ERROR then
    raise EACRException.Create(40034, ErrorRWSAStartup, [SocketError]);
{$ENDIF}

finalization

// Terminate all network threads...
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Terminate all network threads...');
{$ENDIF}
  NetworkThreads := FNetworkThreads.LockList;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Hang Count='+IntToStr(NetworkThreads.Count));
{$ENDIF}
  try
   for i:= NetworkThreads.Count-1 downto 0 do
    begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Thread #'+IntToStr(TThread(NetworkThreads[i]).ThreadID)+'/'+IntToStr(TThread(NetworkThreads[i]).Handle));
{$ENDIF}
     if TThread(NetworkThreads[i]) <> nil then
      begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Ask Thread to Terminate...');
{$ENDIF}
       TThread(NetworkThreads[i]).Terminate;
       sleep(1);
      end;
     if TThread(NetworkThreads[i]) <> nil then
      begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> TerminateThread...');
{$ENDIF}
       Err := TerminateThread(TThread(NetworkThreads[i]).Handle, 0);
       sleep(1);
      end;
     if not Err then
      begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> TerminateThread failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
     if TThread(NetworkThreads[i]) <> nil then
      if TThread(NetworkThreads[i]).Handle <> 0 then
       begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> CloseHandle...');
{$ENDIF}
        Err := CloseHandle(TThread(NetworkThreads[i]).Handle);
        sleep(1);
       end;
     if not Err then
      begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> CloseHandle failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
(*
     if TThread(NetworkThreads[i]) <> nil then
       begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> free...');
{$ENDIF}
        TThread(NetworkThreads[i]).Free;
        sleep(1);
       end;
*)
     NetworkThreads.Delete(i);
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Count='+IntToStr(NetworkThreads.Count));
{$ENDIF}
    end;
  finally
   FNetworkThreads.UnlockList;
  end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
  sleep(1);
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TACRNetwork> Rest Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}

{$IFDEF MSWINDOWS}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> WSACleanup...');
{$ENDIF}
  if WSACleanup = SOCKET_ERROR then
    raise EACRException.Create(40035, ErrorRWSACleanup, [SocketError]);
{$ENDIF}

  if FNetworkThreads <> nil then
    FNetworkThreads.Free;
  FNetworkThreads := nil;

{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> Before ACRDecMemoryUseCount');
{$ENDIF}
  ACRMemoryDecUseCount;

{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRNetwork> FINISH');
{$ENDIF}

end.

