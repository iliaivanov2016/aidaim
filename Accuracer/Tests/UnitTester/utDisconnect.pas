unit utDisconnect;

interface

{$I UTConfig.Inc}

uses Forms, SysUtils, Classes, Math,
     uTestList,
     ACRLinux,
     ACRConst,
     ACRTypes,
     ACRClient,
     ACRServer,
     ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRConnection,
     ACRCompression,
     ACRMemory;

const

  TimeOut = 500;

type
  TUnitTestDisconnect = class(TUnitTest)
   private
    procedure OnDisconnect(Server: Boolean);
    procedure OnFree(Server: Boolean);
    procedure TestServerDisconnectClient;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestDisconnect: TUnitTestDisconnect;


implementation

{ TUnitTestDisconnect }

procedure TUnitTestDisconnect.OnDisconnect(Server: Boolean);
begin
 if Server then
   WriteToProcessLog('Client disconnected by server - OK!')
 else
  begin
   WriteToProcessLog('Client disconnection occurs - Error!');
   WriteToErrorLog('OnDisconnect -> Error: abnormal disconnection occurs on the client!');
  end;
end;

procedure TUnitTestDisconnect.OnFree(Server: Boolean);
begin
 if Server then
   WriteToProcessLog('Client disconnected by server stopping - OK!')
 else
  begin
   WriteToProcessLog('Client disconnection by server stopping occurs - Error!');
   WriteToErrorLog('OnFree -> Error: abnormal disconnection occurs on the client!');
  end;
end;

procedure TUnitTestDisconnect.TestServerDisconnectClient;
var
  Server:                   TACRServer;
  ClientSession:            TACRClientSession;
  ConnectParams:            TACRClientConnectParamsEditor;
  Clients:                  TACRClientInfoArray;

procedure WaitForTimeOut;
var
  StartTime:                Cardinal;
begin
  StartTime := GetTickCount;
  while (GetTickCount - StartTime) < TimeOut do
   begin
    Application.ProcessMessages;
    Sleep(1);
   end;
end;

procedure Connect;
begin
 WriteToProcessLog('Connect...');
 try
  ClientConnectionManager.Connect(ClientSession);
  if not ClientSession.Connected then
    ClientSession.FConnected := True; 
 except
  on e: Exception do
   begin
    UnitTestList.WriteToErrorLog('Connect -> Error:'#13#10 + e.Message);
    raise;
   end;
 end;
 WriteToProcessLog('Connected');
end;

begin
// create then start server
  Server := TACRServer.Create(nil);
  Server.Active := True;
// create then connect client
  ClientSession := TACRClientSession.Create;
  ClientSession.OnDisconnectRemoteDatasets := OnDisconnect;
  ConnectParams := TACRClientConnectParamsEditor.Create;
{
  ConnectParams.NetworkSettings.PacketSize := PacketSize;
  ConnectParams.CompressionAlgorithm := ConvertACRCompressionAlgorithmToCompressionAlgorithm(CompressionAlgorithm);
  ConnectParams.CompressionMode := CompressionMode;
  ConnectParams.NetworkSettings.RestoreDefaultSettings := acrLocal;
  if BufferSize >= 10000000 then
    ConnectParams.NetworkSettings.StartReceiveTimeOut := 15000
  else
    ConnectParams.NetworkSettings.StartReceiveTimeOut := 3000;
  ConnectParams.NetworkSettings.UseServerSettings := False;
}
  ClientSession.FConnectParams := ConnectParams.GetConnectParams;
  try
   ConnectParams.Free;
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('ConnectParams.Free -> Error:'#13#10 + e.Message);
    end;
  end;
  try
// Disconnect by Host:Port
   Connect;
   try
    WriteToProcessLog('Disconnect by Host:Port...');
    Server.Disconnect(ClientSession.ConnectParams.RemoteHost,ClientSession.ConnectParams.LocalPort);
    WriteToProcessLog('Disconnection by Host:Port finished');
   except
    WriteToErrorLog('Error disconnection by Host:Port!');
    WriteToProcessLog('Error disconnection by Host:Port!');
   end;
   WaitForTimeOut;
// Disconnect by SessionID
   Connect;
   try
    WriteToProcessLog('Disconnect by SessionID...');
    Server.GetClients(Clients);
    if Length(Clients) <> 1 then
     begin
      WriteToErrorLog('Error: clients count = '+IntToStr(Length(Clients)));
      WriteToProcessLog('Error: clients count = '+IntToStr(Length(Clients)));
      raise Exception.Create('Error: clients count = '+IntToStr(Length(Clients)));
     end;
    Server.Disconnect(Clients[0].SessionID);
    WriteToProcessLog('Disconnection by SessionID finished');
   except
    WriteToErrorLog('Error disconnection by SessionID!');
    WriteToProcessLog('Error disconnection by SessionID!');
   end;
   WaitForTimeOut;
// free
  ClientSession.OnDisconnectRemoteDatasets := OnFree;
  finally
   WriteToProcessLog('Free...');
   try
    Server.Free; // Frees ServerConnectionManager
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ServerConnectionManager.Free -> Error:'#13#10 + e.Message);
     end;
   end;
   try // free client... 
    ClientSession.Free;
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ClientSession.Free -> Error:'#13#10 + e.Message);
     end;
   end;
  end;
end;


procedure TUnitTestDisconnect.TestShort;
begin
  WriteToProcessLog('UnitTestDisconnect - short test started');
  CheckAction(TestServerDisconnectClient, 'Disconnection Test - Server disconnect Client');
  WriteToProcessLog('UnitTestDisconnect - short test finished'#13#10);
end;


procedure TUnitTestDisconnect.TestExceptions;
begin
  WriteToProcessLog('UnitTestDisconnect - Exceptions test started');
//  CheckAction(Test, 'Disconnection Test - ');
  WriteToProcessLog('UnitTestDisconnect - Exceptions test finished'#13#10);
end;

initialization
  UnitTestDisconnect := TUnitTestDisconnect.Create(UnitTestList);

finalization
  UnitTestDisconnect.Free;

end.
