unit ACRNetworkUDP;

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
  ACRTypes,
  ACRConst,
  ACRExcept,
  ACRMemory;

type

////////////////////////////////////////////////////////////////////////////////
//
// TACRUDPSocket
//
////////////////////////////////////////////////////////////////////////////////

  TACRUDPSocketListenerThread = class;

  TACRUDPSocket = class (TACRapiNetwork)
   private
//    FListener:            TACRUDPSocketListenerThread;  -- defined in base class
   protected
    procedure Open; override;
    procedure StartListening; override;
    procedure StopListening; override;
   public
    constructor Create(Owner: TObject);
{
    destructor Destroy; override;
    procedure SendBuffer(
                            Buffer:     PAnsiChar;
                            Count:      Integer
                         );
}
   public
  end; // TACRUDPSocket

  TACRUDPSocketListenerThread = class(TACRListenerThread)
  private
   FOwner:          TACRUDPSocket;
  protected
   procedure Execute; override;
  public
   constructor Create(Owner: TACRUDPSocket);
   destructor Destroy; override;
  end;// TACRUDPSocketListenerThread


implementation


////////////////////////////////////////////////////////////////////////////////
//
// TACRUDPSocket
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRUDPSocket.Create(Owner: TObject);
begin
  FListener := nil;
  FIOMode := ACR_Blocking;
  inherited Create(Owner, ACR_UDP);
end;// Create


//------------------------------------------------------------------------------
// Open
//------------------------------------------------------------------------------
procedure TACRUDPSocket.Open;
begin
 inherited;
 BindSocket;
end; // Open


//------------------------------------------------------------------------------
// StartListening
//------------------------------------------------------------------------------
procedure TACRUDPSocket.StartListening;
begin
  inherited;
  if FListener <> nil then
    raise EACRException.Create(40028, ErrorRNetworkListenerStarted, [SocketError]);
  FListener := TACRUDPSocketListenerThread.Create(self);
  if FListener = nil then
    raise EACRException.Create(40029, ErrorRNetworkListenerNotStarted, [SocketError]);
end; // StartListening


//------------------------------------------------------------------------------
// StopListening
//------------------------------------------------------------------------------
procedure TACRUDPSocket.StopListening;
begin
{$IFDEF LOG_NETWORK_UDP_DESTROY}
aaWriteToLog('TACRUDPSocket.StopListening> START');
{$ENDIF}
  if FListener <> nil then
   begin
    FListener.FRecreate := False;
{$IFDEF LOG_NETWORK_UDP_DESTROY}
aaWriteToLog('TACRUDPSocket.StopListening> free listener...');
{$ENDIF}
    FListener.Free;
    FListener := nil;
   end;
{$IFDEF LOG_NETWORK_UDP_DESTROY}
aaWriteToLog('TACRUDPSocket.StopListening> close...');
{$ENDIF}
  Close;
  inherited;
end; // StopListening


// TACRUDPSocket



////////////////////////////////////////////////////////////////////////////////
//
// TACRUDPSocketListenerThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRUDPSocketListenerThread.Create(Owner: TACRUDPSocket);
begin
  FOwner := Owner;
  inherited Create;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRUDPSocketListenerThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TACRUDPSocketListenerThread.Destroy> Listener Thread finishing...');
{$ENDIF}
  inherited Destroy;
  if not Terminated then
  if FRecreate then
  if FOwner <> nil then
   begin
{$IFDEF DEBUG_LOG_NETWORK_THREADS}
aaWriteToLog('TACRListenerThread.Destroy> Recreate UDP Listener Thread...');
{$ENDIF}
    sleep(ACRThreadRecreateSleep);
    if not Terminated then
    if FRecreate then
    if FOwner <> nil then
      FOwner.FListener := TACRUDPSocketListenerThread.Create(FOwner);
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('TACRUDPSocketListenerThread.Destroy> Listener Thread Recreated');
{$ENDIF}
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TACRUDPSocketListenerThread.Create> ERROR: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Destroy


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TACRUDPSocketListenerThread.Execute;
var
  Buffer:     PAnsiChar;
  BufferSize: Integer;
  Count:      Integer;
  State:      TFDSet;
  Time:       TTimeVal;
  Flags:      Integer;
  Addr:       TSockAddr;
  AddrLen:    Integer;
  FromHost:   AnsiString;
  FromPort:   Integer;
  ErrorCode:  Integer;
label
  Start, Receive;
begin
try // except
 BufferSize := FOwner.PacketSize;
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRUDPSocketListenerThread.Execute> BufferSize = '+IntToStr(BufferSize));
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
     Exit;
   SelectParams(FOwner.FSocket, State, Time);
   Count := IsDataReceived(FOwner.FSocket, @State, @Time);
  until (Count > 0);
Receive:
   // receive packet
{$IFDEF MSWINDOWS}
   Count := recvfrom(FOwner.FSocket, Buffer^, BufferSize, Flags, Addr, AddrLen);
{$ENDIF}
{$IFDEF LINUX}
   Count := Libc.recvfrom(FOwner.FSocket, Buffer^, BufferSize, Flags, @Addr, @AddrLen);
{$ENDIF}
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRUDPSocketListenerThread.Execute - "recvfrom" returned Count='+IntToStr(Count));
{$ENDIF}
   if Count = SOCKET_ERROR then
    begin
     ErrorCode := SocketError;
{$IFDEF DEBUG_LOG_NETWORK_ERRORS}
aaWriteToLog('**************************************************************');
aaWriteToLog('TACRUDPSocketListenerThread.Execute - "recvfrom" returned SOCKET_ERROR='+IntToStr(ErrorCode));
if ErrorCode = 10040 then
 aaWriteToLog('TACRUDPSocketListenerThread.Execute - BufferSize = '+IntToStr(BufferSize));
aaWriteToLog('**************************************************************');
{$ENDIF}
      if (ErrorCode=10040) then // packet too long
       begin
        MemoryManager.FreeAndNilMem(Buffer);
        BufferSize := ACRMaxPacketSize;
        Buffer := MemoryManager.GetMem(BufferSize);
        goto Receive;
       end;
      if (Assigned(FOwner.FOnDisconnect))
      and (ErrorCode=10054)
      then
       begin
        TACROnDisconnectThread.Create(FOwner, True);
        Exit;
       end
      else
        raise EACRException.Create(40031, ErrorRNetReceive, ['recvfrom', ErrorCode]);
    end;
   // get parameters
   AddrFromSock(Addr, FromHost, FromPort);
{$IFDEF LOG_NETWORK_RECV}
aaWriteToLog('TACRUDPSocketListenerThread.Execute> '+IntToStr(Count)+' bytes received in UDP Socket # '+IntToStr(FOwner.FSocket)+', from '+FromHost+':'+IntToStr(FromPort));
{$ENDIF}
   // send event
   if Assigned(FOwner.FOnDataReceived) then
     FOwner.FOnDataReceived(Buffer, Count, FromHost, FromPort);
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
aaWriteToLog('TACRUDPSocketListenerThread> ERROR:');
aaWriteToLog(E.Message);
aaWriteToLog('Thread # '+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
aaWriteToLog('**************************************************************');
    end;
{$ENDIF}
 end;
end; // Execute


// TACRUDPSocketListenerThread

end.

