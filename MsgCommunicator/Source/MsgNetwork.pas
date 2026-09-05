unit MsgNetwork;

interface

{$I MsgVer.inc}

uses
  Classes, SysUtils,
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Libc,
{$ENDIF}

// MsgCommunicator units

{$IFDEF DEBUG_LOG}
  MsgDebug,
{$ENDIF}
  MsgTypes,
//  ACRTypesThread,
  MsgConst,
  MsgExcept,
  MsgMemory;

const
  MAX_PORT = 2147483646;

{$NODEFINE PF_INET}
  PF_INET         =  2;
{$NODEFINE SOCK_DGRAM}
  SOCK_DGRAM      =  2;
{$NODEFINE SOCKET_ERROR}
  SOCKET_ERROR    = -1;
{$NODEFINE AF_INET}
  AF_INET         =  2;
{$NODEFINE IPPROTO_UDP}
  IPPROTO_UDP     = 17;             { user datagram protocol }
{$NODEFINE INADDR_NONE}
  INADDR_NONE     = -1;

{$NODEFINE FD_SETSIZE}
  FD_SETSIZE      =  1; // default value = 64;

type

  TSocket = Integer;

  SunB = packed record
    s_b1, s_b2, s_b3, s_b4: Byte;
  end;

  SunW = packed record
    s_w1, s_w2: Word;
  end;

  PInAddr = ^TInAddr;
  TMsgin_addr = record
    case integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: LongInt);
  end;
  TInAddr = TMsgin_addr;

  TMsgsockaddr_in = record
    case Integer of
      0: (sin_family: Word;
          sin_port:   Word;
          sin_addr:   TInAddr;
          sin_zero:   array[0..7] of AnsiChar);
      1: (sa_family:  Word;
          sa_data:    array[0..13] of AnsiChar)
  end;
  TSockAddr = TMsgsockaddr_in;

  PHostEnt = ^THostEnt;
  TMsghostent = record
    h_name: PAnsiChar;
    h_aliases: ^PChar;
    h_addrtype: Smallint;
    h_length: Smallint;
    case Byte of
      0: (h_addr_list: ^PChar);
      1: (h_addr: ^PChar)
  end;
  THostEnt = TMsghostent;

  PFDSet = ^TFDSet;
  TFDSet = record
    fd_count: Integer;
    fd_array: array[0..FD_SETSIZE-1] of TSocket;
  end;

  PTimeVal = ^TTimeVal;
  TMsgtimeval = record
    tv_sec: Longint;
    tv_usec: Longint;
  end;
  TTimeVal = TMsgtimeval;

const
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

{$IFDEF LINUX}

(*$HPPEMIT '#include <sys/socket.h>'*)

{$ENDIF}


// Forward Declarations

  TMsgListenerThread = class;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgapiNetwork
//
////////////////////////////////////////////////////////////////////////////////

  TMsgDataReceivedNotifyEvent = procedure(
                             Buffer:    PAnsiChar;
                             Count:     Integer;
                             FromHost:  AnsiString;
                             FromPort:  Integer
                                          ) of object;

  TMsgDisconnectNotifyEvent = procedure(
                             FromHost:  AnsiString;
                             FromPort:  Integer;
                             Recv:      Boolean = False
                                          ) of object;

  TMsgapiNetwork = class (TObject)
   public
    Recreate:             Boolean;
   private
    FOwner:               TObject;
    FOnDataReceived:      TMsgDataReceivedNotifyEvent;
    FOnDisconnect:        TMsgDisconnectNotifyEvent;
    FSocket:              Integer;
    FPacketSize:          Integer;
    FLocalHost:           AnsiString;
    FLocalPort:           Integer;
    FRemoteHost:          AnsiString;
    FRemotePort:          Integer;
    FListener:            TMsgListenerThread;
    FActive:              Boolean;
    FDisconnected:        Boolean;
   protected
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
    procedure StartListening;
    procedure StopListening;
    procedure Open;
    procedure Close;
   public
//   protected
    property OnDataReceived: TMsgDataReceivedNotifyEvent
                                    read FOnDataReceived write FOnDataReceived;
    property OnDisconnect: TMsgDisconnectNotifyEvent
                                    read FOnDisconnect write FOnDisconnect;
   public
    constructor Create(Owner: TObject);
    destructor Destroy; override;
    procedure SendBuffer(
                            Buffer:     PAnsiChar;
                            Count:      Integer
                         );
   public
    property Active: Boolean read FActive write SetActive;
    property RemoteHost: AnsiString read GetRemoteHost write SetRemoteHost;
    property RemotePort: Integer read GetRemotePort write SetRemotePort;
    property LocalHost: AnsiString read GetLocalHost write SetLocalHost;
    property LocalPort: Integer read GetLocalPort write SetLocalPort;
    property PacketSize: Integer read FPacketSize write SetPacketSize;
  end; // TMsgapiNetwork


  TMsgListenerThread = class(TMsgThread)
  private
    FapiNetwork:  TMsgapiNetwork;
  protected
    procedure Execute; override;
  public
    constructor Create(apiNetwork: TMsgapiNetwork);
    destructor Destroy; override;
  end;// TMsgListenerThread


  TMsgOnDisconnectThread = class(TMsgThread)
  private
    FapiNetwork:    TMsgapiNetwork;
    FRecv:          Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(
                        apiNetwork:     TMsgapiNetwork;
                        Recv:           Boolean = False
                      );
    destructor Destroy; override;
  end;// TMsgOnDisconnectThread



// Procedures

function SocketError: Integer;
function LookupHostAddr(const hn: AnsiString): AnsiString;

{$IFDEF MSWINDOWS}
const
  winsocket = 'wsock32.dll';
  kernel32  = 'kernel32.dll';

function socket(af, Struct, protocol: Integer): TSocket; stdcall;
function bind(s: TSocket; var addr: TSockAddr; namelen: Integer): Integer; stdcall;
function getsockname(s: TSocket; var addr: TSockAddr; var namelen: Integer): Integer; stdcall;
function sendto(s: TSocket; var Buf; len, flags: Integer;
                  var addrto: TSockAddr; tolen: Integer): Integer; stdcall;
function recvfrom(s: TSocket; var Buf; len, flags: Integer;
                  var from: TSockAddr; var fromlen: Integer): Integer; stdcall;
function select(nfds: Integer; readfds, writefds, exceptfds: PFDSet;
                  timeout: PTimeVal): Longint; stdcall;
function inet_addr(cp: PAnsiChar): Longint; stdcall; {PInAddr;}  { TInAddr }
{$NODEFINE gethostbyname}
function gethostbyname(name: PAnsiChar): PHostEnt; stdcall;
function htons(hostshort: Word): Word; stdcall;
function ntohs(netshort: Word): Word; stdcall;
function closesocket(s: TSocket): Integer; stdcall;
{$NODEFINE WSAStartup}
function WSAStartup(wVersionRequired: Word; var WSData: TWSAData): Integer; stdcall;
function WSACleanup: Integer; stdcall;
function WSAGetLastError: Integer; stdcall;
{$NODEFINE TerminateThread}
function TerminateThread(hThread: THandle; dwExitCode: Longword): Boolean; stdcall;
{$ENDIF}

var
  FNetworkThreads:     TMsgThreadList;

implementation

uses MsgConnection;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgapiNetwork
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgapiNetwork.Create(Owner: TObject);
begin
  FOwner := Owner;
  inherited Create;
  Recreate := True;
  FActive := False;
  FDisconnected := False;
  FPacketSize := MsgDefaultPacketSize;
  FLocalHost := '';
  FLocalPort := MsgDefaultClientPort;
  FRemoteHost := MsgDefaultHost;
  FRemotePort := MsgDefaultServerPort;
  FListener := nil;
  StartListening;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgapiNetwork.Create>  Socket #'+IntToStr(Integer(FSocket)));
{$ENDIF}
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgapiNetwork.Destroy;
begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgapiNetwork.Destroy>  Socket #'+IntToStr(Integer(FSocket)));
{$ENDIF}
 try
  StopListening;
  FDisconnected := True;
 except
 end;
  inherited Destroy;
  if Recreate then
   begin
    TMsgNetwork(FOwner).FMsgNetwork := TMsgapiNetwork.Create(FOwner);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgapiNetwork.Destroy> API Network Thread Recreated');
{$ENDIF}
   end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgapiNetwork.Destroy - FINISHED');
{$ENDIF}
end;// Destoy


//------------------------------------------------------------------------------
// SetRemoteHost
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.SetRemoteHost(Host: AnsiString);
begin
  FRemoteHost := Host;
end;


//------------------------------------------------------------------------------
// GetRemoteHost
//------------------------------------------------------------------------------
function TMsgapiNetwork.GetRemoteHost: AnsiString;
begin
  Result := FRemoteHost;
end;


//------------------------------------------------------------------------------
// SetRemotePort
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.SetRemotePort(Port: Integer);
begin
  FRemotePort := Port;
end;


//------------------------------------------------------------------------------
// GetRemotePort
//------------------------------------------------------------------------------
function TMsgapiNetwork.GetRemotePort: Integer;
begin
  Result := FRemotePort;
end;


//------------------------------------------------------------------------------
// GetLocalHost
//------------------------------------------------------------------------------
function TMsgapiNetwork.GetLocalHost: AnsiString;
begin
  Result := FLocalHost;
end;


//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TMsgapiNetwork.GetLocalPort: Integer;
begin
  Result := FLocalPort;
end;


//------------------------------------------------------------------------------
// SetPacketSize
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.SetPacketSize(Size: Integer);
begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgapiNetwork.SetPacketSize> old PacketSize = '+IntToStr(FPacketSize));
aaWriteToLog('TMsgapiNetwork.SetPacketSize> new PacketSize = '+IntToStr(Size));
{$ENDIF}
  if FPacketSize = Size then Exit;
  if FListener <> nil then
   begin
    FListener.FRecreate := False;
    FListener.Terminate;
    FListener := nil;
   end;
  FPacketSize := Size;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgapiNetwork.SetPacketSize> Create Listener Thread...');
{$ENDIF}
  FListener := TMsgListenerThread.Create(self);
end;


//------------------------------------------------------------------------------
// SetLocalPort
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.SetLocalPort(Port: Integer);
begin
  if FLocalPort = Port then Exit;
  if FListener <> nil then
    StopListening; // you must close socket to change Local parameter
  FLocalPort := Port;
  StartListening;
end;


//------------------------------------------------------------------------------
// SetLocalHost
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.SetLocalHost(Host: AnsiString);
begin
  if FLocalHost = Host then Exit;
  if FListener <> nil then
    StopListening; // you must close socket to change Local parameter
  FLocalHost := Host;
  StartListening;
end;


//------------------------------------------------------------------------------
// SetActive
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.SetActive(Value: Boolean);
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
procedure TMsgapiNetwork.StartListening;
begin
  if FListener <> nil then
    raise EMsgException.Create(40028, ErrorRNetworkListenerStarted, [SocketError]);
  if Active = False then
    Open;
  FListener := TMsgListenerThread.Create(self);
end; // StartListening


//------------------------------------------------------------------------------
// StopListening
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.StopListening;
begin
  if FListener = nil then
    raise EMsgException.Create(40029, ErrorRNetworkListenerNotStarted, [SocketError]);
  FListener.FRecreate := False;
  FListener.Terminate;
  FListener := nil;
  FActive := False;
  Close;
end; // StopListening


//------------------------------------------------------------------------------ 
// Open
//------------------------------------------------------------------------------
procedure TMsgapiNetwork.Open; 
var
  RetCode:    Integer;
  Addr:       TSockAddr;
  Bound:      Boolean; 
  i:          Integer; 
begin
  // open socket 
  FSocket := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if FSocket = SOCKET_ERROR then
    raise EMsgException.Create(40032, ErrorRCannotOpenSocket, ['socket', SocketError]); 
  // set parameters
  Addr.sin_family := AF_INET;
  Addr.sin_addr.s_addr := inet_addr(pAnsiChar(LookupHostAddr(FLocalHost)));
  // binding 
  Bound := False;
  for i:=FLocalPort to MAX_PORT do
   begin
    Addr.sin_port := htons(FLocalPort); 
    if bind(FSocket, Addr, sizeof(Addr)) = SOCKET_ERROR then 
      RetCode := SocketError
    else 
     begin 
      Bound := True; 
      break; // bound
     end;
    if RetCode = 10048 then // port is already in use
      inc(FLocalPort)       // search for another port
    else
      raise EMsgException.Create(40032, ErrorRCannotOpenSocket, ['bind', RetCode]);
   end; // binding
  if not Bound then
    raise EMsgException.Create(40032, ErrorRCannotOpenSocket, ['bind: cannot bound', RetCode]);
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
end; // Open 
 
	
//------------------------------------------------------------------------------
// Close
//------------------------------------------------------------------------------ 
procedure TMsgapiNetwork.Close; 
var 
  RetCode:    Integer; 
begin 
{$IFDEF MSWINDOWS} 
  RetCode := closesocket(FSocket); 
{$ENDIF} 
{$IFDEF LINUX} 
  RetCode := Libc.__close(FSocket); 
{$ENDIF} 
  if RetCode = SOCKET_ERROR then
    raise EMsgException.Create(40033, ErrorRCannotCloseSocket, [SocketError]);
end; // Close
 
	
//------------------------------------------------------------------------------ 
// SendBuffer 
//------------------------------------------------------------------------------ 
procedure TMsgapiNetwork.SendBuffer( 
                          Buffer: PAnsiChar; 
                          Count:  Integer); 
var 
  Flags:  Integer; 
  Addr: TSockAddr; 
begin 
  // set parameters 
  Flags := 0;
  Addr.sin_family := AF_INET; 
  Addr.sin_addr.s_addr := inet_addr(pAnsiChar(LookupHostAddr(FRemoteHost)));
  Addr.sin_port := htons(FRemotePort); 
  FillChar(Addr.sin_zero, SizeOf(Addr.sin_zero), 0); 
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
 try
{$ENDIF}
  // send packet 
  if FDisconnected then
    Exit
  else 
    if sendto(FSocket, Buffer^, Count, Flags, Addr, sizeof(Addr)) = SOCKET_ERROR then 
      raise EMsgException.Create(40030, ErrorRNetSend, [SocketError]);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
 except 
  on E: Exception do
    begin 
aaWriteToLog('**************************************************************'); 
aaWriteToLog('MsgNetwork> TMsgapiNetwork.SendBuffer - Error:');
aaWriteToLog(E.Message); 
aaWriteToLog('**************************************************************');
    end;
 end; 
{$ENDIF} 
end; // SendBuffer
 
	
// TMsgapiNetwork 
 
	
	
////////////////////////////////////////////////////////////////////////////////
//
// TMsgListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgListenerThread.Create(apiNetwork: TMsgapiNetwork);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
var
  NetworkThreads:     TMsgList;
{$ENDIF}
begin
 try
  inherited Create(False);
  FreeOnTerminate := True;
  FRecreate := True;
  FapiNetwork := apiNetwork;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgListenerThread.Create> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FNetworkThreads.Add(Self);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> Listener Thread Added');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TMsgNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgListenerThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgListenerThread.Destroy;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
var
  NetworkThreads:     TMsgList;
{$ENDIF}
begin
 try
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgListenerThread.Destroy> START');
{$ENDIF}
{$IFDEF MSWINDOWS}
//  TerminateThread(Handle, 0);
{$ENDIF}
{$IFDEF LINUX}
{$ENDIF}
  inherited Destroy;
  FNetworkThreads.Remove(Self);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> Listener Thread Removed');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TMsgNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
  if not Terminated then
  if FRecreate then
   begin
    sleep(MsgThreadRecreateSleep);
    if not Terminated then
      FapiNetwork.FListener := TMsgListenerThread.Create(FapiNetwork);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgListenerThread.Destroy> Listener Thread Recreated');
{$ENDIF}
   end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgListenerThread.Destroy> FINISH');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgListenerThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgListenerThread.Execute;
var
  Buffer:     PAnsiChar;
  BufferSize: Integer;
  Count:      Integer;
  FromHost:   AnsiString;
  FromPort:   Integer;
  Flags:      Integer;
  Addr:       TSockAddr;
  AddrLen:    Integer;
  Time:       TTimeVal;
  pTime:      PTimeVal;
  State:      TFDSet;
  pState:     PFDSet;
  ErrorCode:  Integer;
label
  Start, Receive;
begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgListenerThread.Execute> START');
{$ENDIF}
try // except
 BufferSize := FapiNetwork.FPacketSize;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgListenerThread.Execute> BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
 Buffer := MemoryManager.GetMem(BufferSize);
 try // finally - free buffer
  // set parameters
  Flags := 0;
  AddrLen := sizeof(Addr);
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
Start: // receive data
   // wait for incoming packet
   repeat
    if Terminated then
     begin
      Exit;
     end;
    State.fd_count := 1;
    State.fd_array[0] := FapiNetwork.FSocket;
    pState := @State;
    Time.tv_sec := 0;
    Time.tv_usec := 1;
    pTime := @Time;
    Count := select(0, pState, nil, nil, pTime);
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - "select" returned Count='+IntToStr(Count));
{$ENDIF}
    if Count = SOCKET_ERROR then
     begin
      ErrorCode := SocketError;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - "select" returned SOCKET_ERROR='+IntToStr(ErrorCode));
{$ENDIF}
      if (Assigned(FapiNetwork.FOnDisconnect))
      and (ErrorCode=10054)
      then
       begin
        TMsgOnDisconnectThread.Create(FapiNetwork);
        Exit;
       end
      else
        raise EMsgException.Create(40031, ErrorRNetReceive, ['select', ErrorCode]);
     end;
   until (Count > 0) and (State.fd_array[0] = FapiNetwork.FSocket);
Receive:
   if Terminated then
    begin
     Exit;
    end;
   // receive packet
{$IFDEF MSWINDOWS}
   Count := recvfrom(FapiNetwork.FSocket, Buffer^, BufferSize, Flags, Addr, AddrLen);
{$ENDIF}
{$IFDEF LINUX}
   Count := Libc.recvfrom(FapiNetwork.FSocket, Buffer^, BufferSize, Flags, @Addr, @AddrLen);
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK}
aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - "recvfrom" returned Count='+IntToStr(Count));
{$ENDIF}
   if Count = SOCKET_ERROR then
    begin
     ErrorCode := SocketError;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - "recvfrom" returned SOCKET_ERROR='+IntToStr(ErrorCode));
if ErrorCode = 10040 then
 aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
      if (ErrorCode=10040) then // packet too long
       begin
        MemoryManager.FreeAndNilMem(Buffer);
        BufferSize := MsgMaxPacketSize;
        Buffer := MemoryManager.GetMem(BufferSize);
        goto Receive;
       end;
      if (Assigned(FapiNetwork.FOnDisconnect))
      and (ErrorCode=10054)
      then
       begin
        TMsgOnDisconnectThread.Create(FapiNetwork, True);
        Exit;
       end
      else
        raise EMsgException.Create(40031, ErrorRNetReceive, ['recvfrom', ErrorCode]);
    end;
   // get parameters
   FromHost := IntToStr(Addr.sin_addr.S_un_b.s_b1)+'.'+
               IntToStr(Addr.sin_addr.S_un_b.s_b2)+'.'+
               IntToStr(Addr.sin_addr.S_un_b.s_b3)+'.'+
               IntToStr(Addr.sin_addr.S_un_b.s_b4);
   FromPort := Integer (ntohs(Addr.sin_port));
   // send event
   if Assigned(FapiNetwork.FOnDataReceived) then
     FapiNetwork.FOnDataReceived(Buffer, Count, FromHost, FromPort);
  goto Start;
 finally
  MemoryManager.FreeAndNilMem(Buffer);
 end;
 except
  on E: Exception do
    begin
     FRecreate := True;
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - ERROR: '+E.Message);
{$ENDIF}
    end;
 end;
end; // Execute

// TMsgListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TMsgOnDisconnectThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgOnDisconnectThread.Create(
                        apiNetwork:     TMsgapiNetwork;
                        Recv:           Boolean = False

                                          );
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
var
  NetworkThreads:     TMsgList;
{$ENDIF}
begin
 try
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
  FapiNetwork := apiNetwork;
  FRecv := Recv;
  FNetworkThreads.Add(Self);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> OnDisconnect Thread Added');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TMsgNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgOnDisconnectThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgOnDisconnectThread.Destroy;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
var
  NetworkThreads:     TMsgList;
{$ENDIF}
begin
 try
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('MsgNetwork> TMsgOnDisconnectThread.Destroy - START');
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TMsgOnDisconnectThread.Destroy> Thread #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  inherited Destroy;
  FNetworkThreads.Remove(Self);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> OnDisconnect Thread Removed');
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TMsgNetwork> Network Threads Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('MsgNetwork> TMsgOnDisconnectThread.Destroy - FINISH');
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgOnDisconnectThread.Destroy> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgOnDisconnectThread.Execute;
begin
 try
  FapiNetwork.FDisconnected := True;
  FapiNetwork.FOnDisconnect(FapiNetwork.RemoteHost, FapiNetwork.RemotePort, FRecv);
 except
{$IFDEF DEBUG_ONERROR}
  on E: Exception do
    begin
aaWriteToLog('MsgNetwork> TMsgListenerThread.Execute - ERROR: '+E.Message);
    end;
{$ENDIF}
 end;
end; // Execute

// TMsgOnDisconnectThread



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

{$IFDEF MSWINDOWS}
function socket;            external    winsocket name 'socket';
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
  NetworkThreads:     TMsgList;
  i:                  Integer;
  Err:                Boolean;

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgNetwork> initialized');
{$ENDIF}

//  MsgMemoryIncUseCount; // rewmrite wemmory module as is in ACR
  FNetworkThreads := TMsgThreadList.Create;

{$IFDEF MSWINDOWS}
  if WSAStartup($0101, WSAData) = SOCKET_ERROR then
    raise EMsgException.Create(40034, ErrorRWSAStartup, [SocketError]);
{$ENDIF}

finalization

// Terminate all network threads...
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> Terminate all network threads...');
{$ENDIF}
  NetworkThreads := FNetworkThreads.LockList;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> Hang Count='+IntToStr(NetworkThreads.Count));
{$ENDIF}
  try
   for i:= NetworkThreads.Count-1 downto 0 do
    begin
     Err := TerminateThread(TThread(NetworkThreads[i]).Handle, 0);
     if not Err then
      begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> TerminateThread failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
     if TThread(NetworkThreads[i]).Handle <> 0 then
       Err := CloseHandle(TThread(NetworkThreads[i]).Handle);
     if not Err then
      begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> TerminateThread failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> Count='+IntToStr(NetworkThreads.Count));
{$ENDIF}
    end;
  finally
   FNetworkThreads.UnlockList;
  end;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
  sleep(1000);
  NetworkThreads := FNetworkThreads.LockList;
  try
aaWriteToLog('TMsgNetwork> Rest Count='+IntToStr(NetworkThreads.Count));
  finally
   FNetworkThreads.UnlockList;
  end;
{$ENDIF}

{$IFDEF MSWINDOWS}
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> WSACleanup...');
{$ENDIF}
  if WSACleanup = SOCKET_ERROR then
    raise EMsgException.Create(40035, ErrorRWSACleanup, [SocketError]);
{$ENDIF}

  FNetworkThreads.Free;

{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> Before MsgDecMemoryUseCount');
{$ENDIF}

//  MsgMemoryDecUseCount; // rewmrite wemmory module as is in ACR

{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TMsgNetwork> FINISH');
{$ENDIF}

end.

