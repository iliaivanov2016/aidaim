unit ACRNetworkTCP;

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
  ACRNetwork,
  ACRNetworkUDP,
  ACRTypes,
  ACRTypesThread,
  ACRConst,
  ACRExcept,
  ACRMemory;


{$IFDEF LINUX}
(*$HPPEMIT '#include <sys/socket.h>'*)
{$ENDIF}
{$IFDEF MSWINDOWS}
function accept(s: TSocket; var addr: TSockAddr; addrlen: PInteger): TSocket; stdcall;
function connect(s: TSocket; var name: TSockAddr; namelen: Integer): Integer; stdcall;
function listen(s: TSocket; backlog: Integer): Integer; stdcall;
function recv(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
function getpeername(s: TSocket; var name: TSockAddr; var namelen: Integer): Integer; stdcall;
function getsockname(s: TSocket; var name: TSockAddr; var namelen: Integer): Integer; stdcall;
{$ENDIF}

const

  SOMAXCONN       = 5;    // max server listen queue size

  INVALID_SOCKET    = TSocket(NOT(0));

type

  TACRClient = packed record
    Socket:       Integer;
    SessionID:    Integer;
  end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRTCPClient
//
////////////////////////////////////////////////////////////////////////////////

  TACRTCPClientListenerThread = class;

  TACRTCPClient = class (TACRapiNetwork)
   private
//    FListener:            TACRTCPClientListenerThread;  -- defined in base class
    FOpened,
    FConnected:           Boolean;
   protected
    procedure Open; override;
    procedure Close(Socket: Integer = 0); override;
    procedure StartListening; override;
    procedure StopListening; override;
    procedure DoConnect;
    procedure SetConnected(Value: Boolean);
   public
    constructor Create(Owner: TObject);
    procedure SendBuffer(
                          Buffer:     PAnsiChar;
                          Count:      Integer;
                          aSocket:     Integer;
                          aRemoteHost: AnsiString;
                          aRemotePort: Integer
                         ); override;
  published
   property Connected: Boolean read FConnected write SetConnected;
  end; // TACRTCPClient

  TACRTCPClientListenerThread = class(TACRListenerThread)
  private
//   FOwner:            TACRTCPClient;  -- defined in base class
  protected
   procedure Execute; override;
  public
   constructor Create(Owner: TACRTCPClient);
   destructor Destroy; override;
  end;// TACRTCPClientListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRTCPServer
//
////////////////////////////////////////////////////////////////////////////////

  TACRTCPServerListenerThread = class;

  TACRTCPServer = class (TACRapiNetwork)
   private
//    FListener:            TACRTCPServerListenerThread; -- defined in base class
    FQueueSize:           Integer;
    FSockets:             TACRThreadIntArray;   // list of connected sockets
//  FSocket defined in base class is using for listening and accepting new connections
   protected
    procedure Open; override;
    procedure Close(Socket: Integer = 0); override;
    procedure StartListening; override;
    procedure StopListening; override;
    procedure DoListen;
   public
    constructor Create(Owner: TObject);
    destructor Destroy; override;
    procedure SendBuffer(
                          Buffer:     PAnsiChar;
                          Count:      Integer;
                          aSocket:     Integer;
                          aRemoteHost: AnsiString;
                          aRemotePort: Integer
                         ); override;
   published
    property QueueSize: Integer read FQueueSize write FQueueSize;
  end; // TACRTCPServer

  TACRTCPServerListenerThread = class(TACRListenerThread)
  private
//   FOwner:            TACRTCPServer;  -- defined in base class
  protected
   procedure Execute; override;
  public
   constructor Create(Owner: TACRTCPServer);
   destructor Destroy; override;
  end;// TACRTCPServerListenerThread


procedure GetSockLocalAddr(Socket: TSocket; out Host: AnsiString; out Port: Integer);
procedure GetSockRemoteAddr(Socket: TSocket; out Host: AnsiString; out Port: Integer);

implementation


////////////////////////////////////////////////////////////////////////////////
//
// TACRTCPClient
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTCPClient.Create(Owner: TObject);
begin
  FOpened := False;
  FConnected := False;
  FListener := nil;
  FIOMode := ACR_Blocking;
  inherited Create(Owner, ACR_TCP);
end;// Create

//------------------------------------------------------------------------------
// Open
//------------------------------------------------------------------------------
procedure TACRTCPClient.Open;
begin
  if FOpened then
    Exit;
  inherited; // opens socket, does not do connect
end; // Open

//------------------------------------------------------------------------------
// Close
//------------------------------------------------------------------------------
procedure TACRTCPClient.Close;
begin
  if FOpened then
   begin
    inherited;
    FOpened := False;
   end;
  FConnected := False;
end; // Close

//------------------------------------------------------------------------------
// StartListening
//------------------------------------------------------------------------------
procedure TACRTCPClient.StartListening;
begin
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StartListening> START');
{$ENDIF}
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StartListening> inherited...');
{$ENDIF}
  inherited;
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StartListening> inherited OK!');
{$ENDIF}
  if FListener <> nil then
    raise EACRException.Create(40028, ErrorRNetworkListenerStarted, [SocketError]);
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StartListening> create listening thread...');
{$ENDIF}
  FListener := TACRTCPClientListenerThread.Create(self);
  if FListener = nil then
    raise EACRException.Create(40029, ErrorRNetworkListenerNotStarted, [SocketError]);
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StartListening> FINISH');
{$ENDIF}
end; // StartListening

//------------------------------------------------------------------------------
// StopListening
//------------------------------------------------------------------------------
procedure TACRTCPClient.StopListening;
begin
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StopListening> START');
{$ENDIF}
  if FListener <> nil then
   begin
    FListener.FRecreate := False;
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPServer.StopListening> free...');
{$ENDIF}
    FListener.Free;
    FListener := nil;
   end;
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StopListening> close...');
{$ENDIF}
  Close;
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StopListening> inherited...');
{$ENDIF}
  inherited;
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPClient.StopListening> FINISH');
{$ENDIF}
end; // StopListening

//------------------------------------------------------------------------------
// SetConnected
//------------------------------------------------------------------------------
procedure TACRTCPClient.SetConnected(Value: Boolean);
begin
 if (Value = FConnected) then
   Exit;
 if Value then
  begin
   Open;
   DoConnect;
  end
 else
   Close;
end; // SetConnected

//------------------------------------------------------------------------------
// Connect
//------------------------------------------------------------------------------
procedure TACRTCPClient.DoConnect;
var
 RetCode:     Integer;
 Addr:        TSockAddr;
 State:       TFDSet;
 Time:        TTimeVal;
begin
{
// stub for UDP mode
 BindSocket;
 Exit;
}
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> START');
{$ENDIF}
 FConnected := False;
 Addr := AddrToSock(RemoteHost, RemotePort, true);
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> Connect from '+LocalHost+':'+IntToStr(localPort)+' to '+RemoteHost+':'+IntToStr(RemotePort));
aaWriteToLog('TACRTCPClient.DoConnect> FSocket = '+IntToStr(FSocket));
{$ENDIF}
{$IFDEF MSWINDOWS}
 RetCode := connect(FSocket, Addr, sizeof(Addr));
{$ENDIF}
{$IFDEF LINUX}
 RetCode := Libc.connect(FSocket, Addr, sizeof(Addr));
{$ENDIF}
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> RetCode = '+IntToStr(RetCode));
aaWriteToLog('TACRTCPClient.DoConnect> FSocket = '+IntToStr(FSocket));
{$ENDIF}
 if RetCode <> 0 then
   if (RetCode <> SOCKET_ERROR) then
     raise EACRException.Create(40161, ErrorRNetworkConnectNotBlocked, [RemoteHost, RemotePort, RetCode])
   else
    begin
     RetCode := SocketError;
     raise EACRException.Create(40162, ErrorRNetworkConnect, [RemoteHost, RemotePort, RetCode]);
    end;
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> SelectParams...');
{$ENDIF}
 TACRTCPServerListenerThread(FListener).SelectParams(FSocket, State, Time);
 Time.tv_sec := Trunc(ConnectTimeOut / 1000);                    // sec
 Time.tv_usec := (ConnectTimeOut - (Time.tv_sec * 1000)) * 1000; // microsec
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> IsReadyToSend...');
{$ENDIF}
 RetCode := TACRTCPServerListenerThread(FListener).IsReadyToSend(FSocket, @State, @Time);
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> RetCode = '+IntToStr(RetCode));
{$ENDIF}
 if RetCode = 0 then
   raise EACRException.Create(40163, ErrorRNetworkConnectTimeOut, [RemoteHost, RemotePort, ConnectTimeOut]);
 if (RetCode = SOCKET_ERROR) then
  begin
   RetCode := SocketError;
   raise EACRException.Create(40158, ErrorRNetworkConnect, [RemoteHost, RemotePort, RetCode]);
  end;
 if RetCode <> 1 then
   raise EACRException.Create(40164, ErrorRNetworkConnect, [RemoteHost, RemotePort, RetCode]);
 FConnected := True;
 GetSockLocalAddr(FSocket, FLocalHost, FLocalPort);
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPClient.DoConnect> Local addr - '+FLocalHost+':'+IntToStr(FLocalPort));
aaWriteToLog('TACRTCPClient.DoConnect> FINISH');
{$ENDIF}
end; // DoConnect

procedure TACRTCPClient.SendBuffer(
                          Buffer:      PAnsiChar;
                          Count:       Integer;
                          aSocket:     Integer;
                          aRemoteHost: AnsiString;
                          aRemotePort: Integer
                                    );
begin
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPClient.SendBuffer> START');
{$ENDIF}
  Connected := True;
  inherited SendBuffer(Buffer, Count, aSocket, aRemoteHost, aRemotePort)
end; // SendBuffer

// TACRTCPClient



////////////////////////////////////////////////////////////////////////////////
//
// TACRTCPClientListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTCPClientListenerThread.Create(Owner: TACRTCPClient);
begin
  FOwner := Owner;
  inherited Create;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTCPClientListenerThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPClientListenerThread.Destroy> START');
{$ENDIF}
  inherited Destroy;
  if not Terminated then
  if FRecreate then
  if FOwner <> nil then
   begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Destroy> Wait for Client Listener Thread to be terminated for ACRThreadRecreateSleep...');
{$ENDIF}
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
    if FRecreate then
    if FOwner <> nil then
     begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Destroy> Recreate Client Listener Thread...');
{$ENDIF}
      TACRTCPClient(FOwner).FListener := TACRTCPClientListenerThread.Create(TACRTCPClient(FOwner));
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Destroy> Client Listener Thread Recreated!');
{$ENDIF}
     end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPClientListenerThread.Destroy> Listener Thread Recreated');
{$ENDIF}
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRTCPClientListenerThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPClientListenerThread.Destroy> FINISH');
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRTCPClientListenerThread.Execute;
var
  Buffer:     PAnsiChar;
  BufferSize: Integer;
  Count:      Integer;
  State:      TFDSet;
  Time:       TTimeVal;
  Flags:      Integer;
  Addr:       TSockAddr;
  AddrLen:    Integer;
  ErrorCode:  Integer;
label
  Start, Receive;

procedure DoReconnect;
var
  bCon:     Boolean;
begin
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRTCPClientListenerThread.Execute> Reconnect...');
{$ENDIF}
 try
  bCon := TACRTCPClient(FOwner).Connected;
  TACRTCPClient(FOwner).Close;
 except
 end;
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRTCPClientListenerThread.Execute> Reconnect - socket closed');
{$ENDIF}
   TACRTCPClient(FOwner).Open;
   if bCon then
     TACRTCPClient(FOwner).DoConnect;
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRTCPClientListenerThread.Execute> Reconnect - socket opened');
{$ENDIF}
end;

begin
try // except
 BufferSize := TACRTCPClient(FOwner).PacketSize;
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPClientListenerThread.Execute> BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
 Buffer := MemoryManager.GetMem(BufferSize);
 try // finally - free buffer
  // set parameters
  Flags := 0;
  AddrLen := sizeof(Addr);
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
Start:
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPClientListenerThread.Execute> Start...');
{$ENDIF}
  // wait for incoming packet
  repeat
   if Terminated then
     Exit;
   // check for received data
   SelectParams(TACRTCPClient(FOwner).FSocket, State, Time);
   Count := IsDataReceived(TACRTCPClient(FOwner).FSocket, @State, @Time);
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPClientListenerThread.Execute> select Count = '+IntToStr(Count));
{$ENDIF}
  until (Count > 0);
Receive: // receive data
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPClientListenerThread.Execute> Receive, Socket # '+IntToStr(TACRTCPClient(FOwner).FSocket));
{$ENDIF}
   // receive packet
{$IFDEF MSWINDOWS}
   Count := recv(TACRTCPClient(FOwner).FSocket, Buffer^, BufferSize, Flags);
{$ENDIF}
{$IFDEF LINUX}
   Count := Libc.recv(FOwner.FSocket, Buffer^, BufferSize, Flags);
{$ENDIF}
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPClientListenerThread.Execute> "recv" returned Count = '+IntToStr(Count));
{$ENDIF}
   if (Count = 0) then // no data
    begin
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPClientListenerThread.Execute> socket closed gracefully');
{$ENDIF}
     DoReconnect;
     goto Start; // select <> 0 signaled that socket closed gracefully
    end;
   if Count = SOCKET_ERROR then
    begin
     ErrorCode := SocketError;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRClientListenerThread.Execute> ERROR: "recv" returned SOCKET_ERROR='+IntToStr(ErrorCode));
if ErrorCode = 10040 then
 aaWriteToLog('TACRClientListenerThread.Execute> BufferSize = '+IntToStr(BufferSize));
aaWriteToLog('**************************************************************');
{$ENDIF}
     if (ErrorCode = 10035) then // 10035 is a nonfatal error, and the operation can be retried later
       goto Start;
     if (ErrorCode = 0) then // select <> 0 signaled that socket closed
      begin // Re-create socket and connect it
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPClientListenerThread.Execute> Re-create socket and connect it...');
{$ENDIF}
       DoReconnect;
       goto Start;
      end;
     if (ErrorCode = 10040) then // packet too long
      begin
       MemoryManager.FreeAndNilMem(Buffer);
       BufferSize := ACRMaxPacketSize;
       Buffer := MemoryManager.GetMem(BufferSize);
       goto Receive;
      end;
     if (Assigned(TACRTCPClient(FOwner).FOnDisconnect))
      and (ErrorCode=10054)
     then
      begin
       TACROnDisconnectThread.Create(TACRTCPClient(FOwner), True);
       Exit;
      end
     else
       raise EACRException.Create(40031, ErrorRNetReceive, ['recv', ErrorCode]);
    end;
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPClientListenerThread.Execute> '+IntToStr(Count)+' bytes received in Socket # '+IntToStr(TACRTCPClient(FOwner).FSocket)+', from '+TACRTCPClient(FOwner).RemoteHost+':'+IntToStr(TACRTCPClient(FOwner).RemotePort));
{$ENDIF}
   // send event
   if Assigned(TACRTCPClient(FOwner).FOnDataReceived) then
     TACRTCPClient(FOwner).FOnDataReceived(Buffer, Count, TACRTCPClient(FOwner).RemoteHost, TACRTCPClient(FOwner).RemotePort);
  goto Start;
 finally
  MemoryManager.FreeAndNilMem(Buffer);
 end;
 except
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
  on E: Exception do
    begin
     FRecreate := True;
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRTCPClientListenerThread> ERROR:');
aaWriteToLog(E.Message);
aaWriteToLog('Thread # '+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
aaWriteToLog('**************************************************************');
    end;
{$ENDIF}
 end;
end; // Execute

// TACRTCPClientListenerThread



////////////////////////////////////////////////////////////////////////////////
//
// TACRTCPServer
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTCPServer.Create(Owner: TObject);
begin
  FQueueSize := SOMAXCONN;
  FListener := nil;
  FSockets := TACRThreadIntArray.Create;
  FIOMode := ACR_NonBlocking;
  inherited Create(Owner, ACR_TCP);
end;// Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTCPServer.Destroy;
begin
  inherited Destroy;
  FSockets.Free;
end;// Destroy

//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
procedure TACRTCPServer.SendBuffer(
                          Buffer:      PAnsiChar;
                          Count:       Integer;
                          aSocket:     Integer;
                          aRemoteHost: AnsiString;
                          aRemotePort: Integer
                                    );
var
  Host:       AnsiString;
  Port,
  Socket,
  i:          Integer;
  found:      Boolean;
begin
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPServer.SendBuffer> search for '+aRemoteHost+':'+IntToStr(aRemotePort));
{$ENDIF}
 found := false;
 FSockets.Lock;
 try
  for i := 0 to FSockets.ItemCount - 1 do
   begin
    Socket := FSockets.Items[i];
    GetSockRemoteAddr(Socket, Host, Port);
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPServer.SendBuffer> '+Host+':'+IntToStr(Port));
{$ENDIF}
    if (Host = aRemoteHost)
      and (Port = aRemotePort)
    then
     begin
{$IFDEF LOG_NETWORK_SEND}
aaWriteToLog('TACRTCPServer.SendBuffer> Socket found: # '+IntToStr(Socket));
{$ENDIF}
      found := true;
      break;
     end;
   end;
 finally
  FSockets.Unlock;
 end;
 if found then
   inherited SendBuffer(Buffer, Count, Socket, aRemoteHost, aRemotePort)
{$IFDEF LOG_NETWORK_SEND}
 else
aaWriteToLog('TACRTCPServer.SendBuffer> Socket not found!')
{$ENDIF}
 ;
end; // SendBuffer

//------------------------------------------------------------------------------
// Open
//------------------------------------------------------------------------------
procedure TACRTCPServer.Open;
begin
 inherited;
 BindSocket;
 DoListen;
end; // Open

//------------------------------------------------------------------------------
// Close
//------------------------------------------------------------------------------
procedure TACRTCPServer.Close(Socket: Integer = 0);
var
 i: Integer;
begin
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.Close> START');
{$ENDIF}
 if Socket > 0 then
  begin
   inherited Close(Socket);
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.Close> server sockets count = '+IntToStr(FSockets.ItemCount));
{$ENDIF}
   FSockets.Lock;
   try
     for i := FSockets.ItemCount - 1 downto 0 do
      begin
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.Close> #'+IntToStr(i)+FLocalHost+': Socket='+IntToStr(FSockets.Items[i]));
{$ENDIF}
       inherited Close(FSockets.Items[i]);
       FSockets.Delete(i);
      end;
   finally
    FSockets.Unlock;
   end;
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.Close> listening Socket='+IntToStr(FSocket));
{$ENDIF}
   inherited Close(FSocket);
  end;
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.Close> FINISH');
{$ENDIF}
end; // Close

//------------------------------------------------------------------------------
// ListenSocket
//------------------------------------------------------------------------------
procedure TACRTCPServer.DoListen;
begin
 if (QueueSize > SOMAXCONN)
 or (QueueSize <= 0)
 then
   QueueSize := SOMAXCONN;
 if (listen(FSocket, QueueSize) = SOCKET_ERROR) then
  begin
   FActive := False;
   raise EACRException.Create(40159, ErrorRNetworkListen, [LocalHost, LocalPort, SocketError])
  end;
 GetSockLocalAddr(FSocket, FLocalHost, FLocalPort);
{$IFDEF LOG_NETWORK_CONNECT}
aaWriteToLog('TACRTCPServer.DoListen> Local addr - '+FLocalHost+':'+IntToStr(FLocalPort));
{$ENDIF}
end; // ListenSocket

//------------------------------------------------------------------------------
// StartListening
//------------------------------------------------------------------------------
procedure TACRTCPServer.StartListening;
begin
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPServer.StartListening> inherited...');
{$ENDIF}
  inherited;
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPServer.StartListening> inherited OK!');
{$ENDIF}
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPServer.StartListening> START');
{$ENDIF}
  if FListener <> nil then
    raise EACRException.Create(40028, ErrorRNetworkListenerStarted, [SocketError]);
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPServer.StartListening> create listening thread...');
{$ENDIF}
  FListener := TACRTCPServerListenerThread.Create(self);
  if FListener = nil then
    raise EACRException.Create(40029, ErrorRNetworkListenerNotStarted, [SocketError]);
{$IFDEF LOG_NETWORK_LISTENER}
aaWriteToLog('TACRTCPServer.StartListening> FINISH');
{$ENDIF}
end; // StartListening

//------------------------------------------------------------------------------
// StopListening
//------------------------------------------------------------------------------
procedure TACRTCPServer.StopListening;
begin
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.StopListening> START');
{$ENDIF}
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.StopListening> Close...');
{$ENDIF}
  Close;
  if FListener <> nil then
   begin
    FListener.FRecreate := False;
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.StopListening> free listener...');
{$ENDIF}
    FListener.Free;
    FListener := nil;
   end;
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.StopListening> inherited...');
{$ENDIF}
  inherited;
{$IFDEF LOG_NETWORK_SERVER_CLOSE}
aaWriteToLog('TACRTCPServer.StopListening> FINISH');
{$ENDIF}
end; // StopListening

// TACRTCPServer



////////////////////////////////////////////////////////////////////////////////
//
// TACRTCPServerListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRTCPServerListenerThread.Create(Owner: TACRTCPServer);
begin
  FOwner := Owner;
  inherited Create;
end; // Create

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRTCPServerListenerThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPServerListenerThread.Destroy> START');
{$ENDIF}
  inherited Destroy;
  if not Terminated then
  if FRecreate then
  if FOwner <> nil then
   begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPServerListenerThread.Destroy> Wait for Server Listener Thread to be terminated for ACRThreadRecreateSleep...');
{$ENDIF}
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
    if FRecreate then
    if FOwner <> nil then
     begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPServerListenerThread.Destroy> Recreate Server Listener Thread...');
{$ENDIF}
      TACRTCPServer(FOwner).FListener := TACRTCPServerListenerThread.Create(TACRTCPServer(FOwner));
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TACRTCPServerListenerThread.Destroy> Listener Thread Recreated');
{$ENDIF}
     end;
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRTCPServerListenerThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRTCPServerListenerThread.Destroy> FINISH');
{$ENDIF}
end; // Destroy

//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRTCPServerListenerThread.Execute;
var
  Buffer:     PAnsiChar;
  BufferSize: Integer;
  Count:      Integer;
  Socket:     Integer;
  State:      TFDSet;
  Time:       TTimeVal;
  Flags:      Integer;
  Addr:       TSockAddr;
  AddrLen:    Integer;
  FromHost:   AnsiString;
  FromPort:   Integer;
  ErrorCode:  Integer;
  i:          Integer;
  Mode:       LongInt;
label
  Accepting, Start, Receive;


procedure DoDisconnect(Socket,i: Integer);
begin
  TACRTCPServer(FOwner).FSockets.Lock;
  try
//      TACRTCPServer(FOwner).FSockets.Remove(Socket);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> delete socket No. '+IntToStr(i));
{$ENDIF}
   TACRTCPServer(FOwner).FSockets.Delete(i);
  finally
   TACRTCPServer(FOwner).FSockets.Unlock;
  end;
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> socket deleted');
{$ENDIF}
  try
   TACRTCPServer(FOwner).Close(Socket);
  except
  end;
end;

begin
try // except
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> START');
{$ENDIF}
 BufferSize := TACRTCPServer(FOwner).PacketSize;
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
 Buffer := MemoryManager.GetMem(BufferSize);
 try // finally - free buffer
Accepting:
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Sleep...');
{$ENDIF}
  Sleep(1);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Accepting...');
{$ENDIF}
  if Terminated then
   begin
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Terminated!');
{$ENDIF}
    Exit;
   end;
  // accept incomming connection
{$IFDEF LOG_NETWORK_ACCEPT}
aaWriteToLog('TACRTCPServerListenerThread.Execute> try to accept incomming connections thru socket '+IntToStr(TACRTCPServer(FOwner).FSocket));
{$ENDIF}
  Socket := accept(TACRTCPServer(FOwner).FSocket, Addr, 0);
  if Socket = INVALID_SOCKET then
    ErrorCode := SocketError;
  // get parameters
  GetSockRemoteAddr(Socket, FromHost, FromPort);
{$IFDEF LOG_NETWORK_ACCEPT}
if (Socket = -1) then
 aaWriteToLog('TACRTCPServerListenerThread.Execute> no incomming connections')
else
 aaWriteToLog('TACRTCPServerListenerThread.Execute> new Socket = '+IntToStr(Socket)+', '+FromHost+':'+IntToStr(FromPort));
{$ENDIF}
  if Socket = INVALID_SOCKET then
   begin
    if (ErrorCode <> 0)  // = 0 - no incoming connection requests
    and (ErrorCode <> 10035) then // 10035 is a nonfatal error, and the operation can be retried later
      raise EACRException.Create(40160, ErrorRNetworkAccept, [FromHost, FromPort, 'accept', ErrorCode]);
   end
  else
   begin // add new socket
//  if TACRTCPServer(FOwner).FIOMode = ACR_NonBlocking then
   begin
{$IFDEF LOG_NETWORK_SOCKET}
aaWriteToLog('TACRapiNetwork.Open> non-blocking...');
{$ENDIF}
    Mode := 1; // <> 0 - non-blocking, = 0 - blocking
    ioctlsocket(Socket, FIONBIO, Mode);
   end;
    TACRTCPServer(FOwner).FSockets.Lock;
    try
{$IFDEF LOG_NETWORK_ACCEPT}
aaWriteToLog('TACRTCPServerListenerThread.Execute> add...');
{$ENDIF}
     TACRTCPServer(FOwner).FSockets.Append(Socket);
{$IFDEF LOG_NETWORK_ACCEPT}
aaWriteToLog('TACRTCPServerListenerThread.Execute> FSockets.ItemCount = '+IntToStr(TACRTCPServer(FOwner).FSockets.ItemCount));
{$ENDIF}
    finally
     TACRTCPServer(FOwner).FSockets.Unlock;
    end;
   end;
Start:
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Start receiving...');
{$ENDIF}
  Sleep(1);
  Count := 0;
  TACRTCPServer(FOwner).FSockets.Lock;
  try
  for i := TACRTCPServer(FOwner).FSockets.ItemCount-1 downto 0 do
   begin
  Sleep(1);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> i = '+IntToStr(i));
{$ENDIF}
    if Terminated then
     begin
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Terminated!');
{$ENDIF}
      Exit;
     end;
    // search for socket with incoming data
    Socket := TACRTCPServer(FOwner).FSockets.Items[i];
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Socket = '+IntToStr(Socket));
{$ENDIF}
    // set parameters
    SelectParams(Socket, State, Time);
    Count := IsDataReceived(Socket, @State, @Time);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> select Count = '+IntToStr(Count));
{$ENDIF}
    if Count > 0 then
      break;
   end;
  finally
   TACRTCPServer(FOwner).FSockets.Unlock;
  end;
   if Count = 0 then
     goto Accepting;
Receive:
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> Receive...');
{$ENDIF}
   // receive packet
   Flags := 0;
{$IFDEF MSWINDOWS}
   Count := recv(Socket, Buffer^, BufferSize, Flags);
{$ENDIF}
{$IFDEF LINUX}
   Count := Libc.recv(Socket, Buffer^, BufferSize, Flags);
{$ENDIF}
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> recv Count = '+IntToStr(Count));
{$ENDIF}
   if (Count = 0) then // no data
    begin // select <> 0 signaled that socket closed gracefully
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> socket closed gracefully');
{$ENDIF}
     DoDisconnect(Socket,i);
//     sleep(1);
     goto Start;
    end;
   if Count = SOCKET_ERROR then
    begin
     ErrorCode := SocketError;
     if (ErrorCode = 10035) // 10035 is a nonfatal error, and the operation can be retried later
     or (ErrorCode = 10038) // socket is not ready, try later
     then
      begin
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRTCPServerListenerThread.Execute - "recv" returned SOCKET_ERROR='+IntToStr(ErrorCode)+', go to Start');
aaWriteToLog('**************************************************************');
{$ENDIF}
        goto Start;
      end;
     if (ErrorCode = 0) then // no data
      begin // socket closed
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> socket closed');
{$ENDIF}
       DoDisconnect(Socket,i);
//       sleep(1);
       goto Start;
      end;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRTCPServerListenerThread.Execute - "recv" returned SOCKET_ERROR='+IntToStr(ErrorCode));
if ErrorCode = 10040 then
 aaWriteToLog('TACRTCPServerListenerThread.Execute - BufferSize = '+IntToStr(BufferSize));
aaWriteToLog('**************************************************************');
{$ENDIF}
     if (ErrorCode=10040) then // packet too long
      begin
       MemoryManager.FreeAndNilMem(Buffer);
       BufferSize := ACRMaxPacketSizeTCP;
       Buffer := MemoryManager.GetMem(BufferSize);
//     sleep(1);
       goto Receive;
      end;
     if (Assigned(TACRTCPServer(FOwner).FOnDisconnect))
      and (ErrorCode=10054)
     then
      begin
       TACROnDisconnectThread.Create(TACRTCPServer(FOwner), True);
       Exit;
      end
     else
       raise EACRException.Create(40165, ErrorRNetReceive, ['recv', ErrorCode]);
    end;
   // get parameters
   GetSockRemoteAddr(Socket, FromHost, FromPort);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> remote - '+FromHost+':'+IntToStr(FromPort));
{$ENDIF}
   // send event
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('FOwner='+IntToStr(Integer(FOwner)));
aaWriteToLog('FOnDataReceived='+IntToStr(Integer(@TACRTCPServer(FOwner).FOnDataReceived)));
aaWriteToLog('Buffer='+IntToStr(Integer(Buffer)));
aaWriteToLog('Count='+IntToStr(Integer(Count)));
{$ENDIF}
   if Assigned(FOwner.OnDataReceived) then
     FOwner.OnDataReceived(Buffer, Count, FromHost, FromPort);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> goto Start...');
{$ENDIF}
//     sleep(1);
 goto Start;
 finally
  MemoryManager.FreeAndNilMem(Buffer);
 end;
 except
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
  on E: Exception do
    begin
     FRecreate := True;
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRTCPServerListenerThread.Execute> ERROR:');
aaWriteToLog(E.Message);
aaWriteToLog('Thread # '+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
aaWriteToLog('**************************************************************');
    end;
{$ENDIF}
 end;
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRTCPServerListenerThread.Execute> FINISH');
{$ENDIF}
end; // Execute

// TACRTCPServerListenerThread


////////////////////////////////////////////////////////////////////////////////
// Procedures
////////////////////////////////////////////////////////////////////////////////

procedure GetSockLocalAddr(Socket: TSocket; out Host: AnsiString; out Port: Integer);
var
  Addr:       TSockAddr;
  AddrLen:    Integer;
begin
  AddrLen := sizeof(Addr);
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  getsockname(Socket, Addr, AddrLen);
  AddrFromSock(Addr, Host, Port);
end;

procedure GetSockRemoteAddr(Socket: TSocket; out Host: AnsiString; out Port: Integer);
var
  Addr:       TSockAddr;
  AddrLen:    Integer;
begin
  AddrLen := sizeof(Addr);
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  getpeername(Socket, Addr, AddrLen);
  AddrFromSock(Addr, Host, Port);
end;

{$IFDEF MSWINDOWS}
function accept;            external    winsocket name 'accept';
function connect;           external    winsocket name 'connect';
function listen;            external    winsocket name 'listen';
function recv;              external    winsocket name 'recv';
function getpeername;       external    winsocket name 'getpeername';
function getsockname;       external    winsocket name 'getsockname';
{$ENDIF}

end.

