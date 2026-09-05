unit utConnection;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes, Math,
     uTestList,
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

type
  TUnitTestConnection = class(TUnitTest)
   private
    procedure TestSettings;
    procedure Test (PacketSize, BufferSize: Integer;
                    CompressionAlgorithm:   TACRCompressionAlgorithm = acaNone;
                    CompressionMode:        TACRCompressionMode = 0;
                    Count:                  Integer = 1;
                    Reply:                  Boolean = True);
    procedure Test1;
    procedure Test2;
    procedure Test3;
    procedure TestMultipleRequests;
    procedure TestMultiPacketsMultipleRequests;
    procedure TestMultiConnectionPacketsMultipleRequests;
    procedure TestCompression;
    procedure Test4;
    procedure Test5;
    procedure TestWithoutReply;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestConnection: TUnitTestConnection;


implementation

{ TUnitTestConnection }

procedure TUnitTestConnection.TestSettings;
var
  Server:                   TACRServer;
  ClientSession:            TACRClientSession;
  ConnectParams:            TACRClientConnectParamsEditor;

procedure Connect;
begin
 WriteToProcessLog('Connect...');
 try
  ClientConnectionManager.Connect(ClientSession);
 except
  on e: Exception do
   begin
    UnitTestList.WriteToErrorLog('Connect -> Error:'#13#10 + e.Message);
    raise;
   end;
 end;
 WriteToProcessLog('Connected');
end;

procedure Disconnect;
begin
 WriteToProcessLog('Disconnect...');
 try
  ClientConnectionManager.Disconnect(ClientSession);
 except
  on e: Exception do
   begin
    UnitTestList.WriteToErrorLog('Disconnect -> Error:'#13#10 + e.Message);
    raise;
   end;
 end;
 WriteToProcessLog('Disconnected');
end;

begin
  Server := TACRServer.Create(nil);
  Server.LoadDefaultSettings;
  Server.ServerID := ACRDefaultServerID;
  Server.SaveSettingsToConfigFile;
  Server.Active := True;

  ClientSession := TACRClientSession.Create;
  ConnectParams := TACRClientConnectParamsEditor.Create;
  try
   ConnectParams.NetworkSettings.RestoreDefaultSettings := acrLocal;
   ConnectParams.NetworkSettings.StartReceiveTimeOut := 3000;
   ClientSession.FConnectParams := ConnectParams.GetConnectParams;
   ConnectParams.Free;
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('ConnectParams.Free -> Error:'#13#10 + e.Message);
    end;
  end;

  ClientSession.FConnectParams.MaxThreadCount :=  555;
  ClientSession.FConnectParams.TestPacketCount := 666;
  ClientSession.FConnectParams.PingCount :=       777;

  try
   ClientSession.FConnectParams.UseServerSettings := False;
   Connect;
   if  (ClientSession.FConnectParams.MaxThreadCount  <> 555)
    or (ClientSession.FConnectParams.TestPacketCount <> 666)
    or (ClientSession.FConnectParams.PingCount       <> 777)
   then
     UnitTestList.WriteToErrorLog('Error: client settings has been changed!');
   Disconnect;
   ClientSession.FConnectParams.UseServerSettings := True;
   Connect;
   if   (ClientSession.FConnectParams.MaxThreadCount =  555)
    and (ClientSession.FConnectParams.TestPacketCount = 666)
    and (ClientSession.FConnectParams.PingCount =       777)
   then
     UnitTestList.WriteToErrorLog('Error: client settings was not changed!')
   else
    begin
     if ClientSession.FConnectParams.MaxThreadCount <> Server.ConnectionParams.NetworkSettings.MaxThreadCount then
       UnitTestList.WriteToErrorLog('Error: client got wrong value from server for MaxThreadCount = '+IntToStr(ClientSession.FConnectParams.MaxThreadCount));
     if ClientSession.FConnectParams.TestPacketCount <> Server.ConnectionParams.NetworkSettings.TestPacketCount then
       UnitTestList.WriteToErrorLog('Error: client got wrong value from server for TestPacketCount = '+IntToStr(ClientSession.FConnectParams.MaxThreadCount));
     if ClientSession.FConnectParams.PingCount <> Server.ConnectionParams.NetworkSettings.PingCount then
       UnitTestList.WriteToErrorLog('Error: client got wrong value from server for PingCount = '+IntToStr(ClientSession.FConnectParams.MaxThreadCount));
    end;
  finally
   WriteToProcessLog('Free...');
   try
    ClientSession.Free;
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ClientSession.Free -> Error:'#13#10 + e.Message);
     end;
   end;
   try
    Server.Free; // Frees ServerConnectionManager
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ServerConnectionManager.Free -> Error:'#13#10 + e.Message);
     end;
   end;
  end;
end;


procedure TUnitTestConnection.Test (PacketSize, BufferSize: Integer;
                    CompressionAlgorithm:   TACRCompressionAlgorithm = acaNone;
                    CompressionMode:        TACRCompressionMode = 0;
                    Count:                  Integer = 1;
                    Reply:                  Boolean = True);
var
  ClientSession:            TACRClientSession;
  Server:                   TACRServer;
  ConnectParams:            TACRClientConnectParamsEditor;
  Buffer:     PChar;
  inBuffer:   PChar;
  outBuffer:  PChar;
  inCount:    Integer;
  outCount:   Integer;
  i, j:       Integer;
  EQ:         Boolean;
//buf:  PChar;
begin
 outBuffer := MemoryManager.AllocMem(BufferSize);
 try
  StrPCopy(outBuffer, '->Test Buffer');
  outCount := Length (outBuffer)+1;
  Randomize;
  for i:=outCount to BufferSize-1 do
   PByte(outBuffer+i)^ := Byte(Random(64) + 64);
  outCount := Max(OutCount, BufferSize);

  inCount := 0;

  Server := TACRServer.Create(nil);
  Server.LoadDefaultSettings;
  Server.ServerID := ACRDefaultServerID;
  Server.SaveSettingsToConfigFile;
  Server.Active := True;

  ClientSession := TACRClientSession.Create;

  ConnectParams := TACRClientConnectParamsEditor.Create;
  ConnectParams.NetworkSettings.PacketSize := PacketSize;
  ConnectParams.CompressionAlgorithm := ConvertACRCompressionAlgorithmToCompressionAlgorithm(CompressionAlgorithm);
  ConnectParams.CompressionMode := CompressionMode;
  ConnectParams.NetworkSettings.RestoreDefaultSettings := acrLocal;
  if BufferSize >= 10000000 then
    ConnectParams.NetworkSettings.StartReceiveTimeOut := 15000
  else
    ConnectParams.NetworkSettings.StartReceiveTimeOut := 3000;
  ConnectParams.NetworkSettings.UseServerSettings := False;
  ClientSession.FConnectParams := ConnectParams.GetConnectParams;
  try
   ConnectParams.Free;
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('ConnectParams.Free -> Error:'#13#10 + e.Message);
    end;
  end;
{
buf := AllocMem(100);
StrPCopy(Buf + SizeOf(TACRPAcketHeader), outBuffer);
ServerConnectionManager.FNetwork.RemoteHost:='localhost';
ServerConnectionManager.FNetwork.RemotePort:=6668;
//ServerConnectionManager.FNetwork.SendBuffer(buf, outCount+SizeOf(TACRPacketHeader));
}
 WriteToProcessLog('Test parameters:');
 WriteToProcessLog('BufferSize = '+IntToStr(BufferSize));
 WriteToProcessLog('outCount   = '+IntToStr(outCount));
 WriteToProcessLog('PacketSize = '+IntToStr(ClientSession.FConnectParams.PacketSize));
 WriteToProcessLog('CompressionAlgorithm = '+IntToStr(ClientSession.FConnectParams.CompressionAlgorithm));
 WriteToProcessLog('CompressionMode      = '+IntToStr(ClientSession.FConnectParams.CompressionMode));
 WriteToProcessLog('Test Count = '+IntToStr(Count));
  try
//Connect
   WriteToProcessLog('Connect...');
   try
    ClientConnectionManager.Connect(ClientSession);
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Connect -> Error:'#13#10 + e.Message);
      raise;
     end;
   end;
   WriteToProcessLog('Connected');
// Multiple
  outBuffer[0] := '0';
 for i:=1 to Count do
  begin
   inc(outBuffer[0]);
//Send
   WriteToProcessLog('Client is sending echo request # '+IntToStr(i)+'...');
   try
    Buffer := MemoryManager.AllocMem(outCount);
    try
      Move(outBuffer^,Buffer^,outCount);
      if Reply then
        ClientConnectionManager.SendBuffer(ClientSession, Buffer, outCount, ACREcho)
      else
       begin
        Buffer^ := #255; // command not used, needs to prevent server reply
        ClientConnectionManager.SendBuffer(ClientSession, Buffer, outCount, ACRClientCommand);
       end;
    finally
     MemoryManager.FreeAndNilMem(Buffer);
    end;
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('SendBuffer -> Error:'#13#10 + e.Message);
      raise;
     end;
   end;
   WriteToProcessLog('Sent');
//Receive
   if not Reply then
     continue; // Do not receive
   WriteToProcessLog('Client is receiving...');
   try
    ClientConnectionManager.ReceiveBuffer(ClientSession, inBuffer, inCount);
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ReceiveBuffer -> Error:'#13#10 + e.Message);
      raise;
     end;
   end;
   WriteToProcessLog('Received');
//Compare
  WriteToProcessLog('Compare...');
  EQ := True;
  for j:=0 to Min(inCount-1, outCount-1) do
    if (inBuffer+j)^ <> (outBuffer+j)^ then
     begin
      EQ := False;
      break;
     end;
  if (not EQ)
  or (inCount<>outCount)
    then
     begin
      WriteToProcessLog('Error: Received buffer is not equal to sent buffer');
      WriteToErrorLog('Received buffer is not equal to sent buffer');
      WriteToErrorLog('Received buffer size = '+IntToStr(inCount));
      WriteToErrorLog('Sent buffer size     = '+IntToStr(outCount));
      WriteToErrorLog('Received buffer = "'+PChar(inBuffer)+'"');
      WriteToErrorLog('Sent buffer     = "'+PChar(outBuffer)+'"');
     end
    else
     WriteToProcessLog('Received buffer is equal to sent buffer');
  MemoryManager.FreeAndNilMem(inBuffer);
 end; // Multiple
//Disconnect
   WriteToProcessLog('Disconnect...');
   try
    ClientConnectionManager.Disconnect(ClientSession);
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Disconnect -> Error:'#13#10 + e.Message);
      raise;
     end;
   end;
   WriteToProcessLog('Disconnected');
  finally
   WriteToProcessLog('Free...');
   try
    ClientSession.Free;
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ClientSession.Free -> Error:'#13#10 + e.Message);
     end;
   end;
   try
    Server.Free; // Frees ConnectionManager
   except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('ServerConnectionManager.Free -> Error:'#13#10 + e.Message);
     end;
   end;
  end;
 finally
  MemoryManager.FreeAndNilMem(outBuffer);
 end;
end;


procedure TUnitTestConnection.Test1;
begin
  Test(256, 256-SizeOf(TACRPacketHeader));
end;

procedure TUnitTestConnection.Test2;
begin
  Test(ACRDefaultPacketSize, 5000000);  // 5 MB
end;

procedure TUnitTestConnection.Test3;
begin
  Test(SizeOf(TACRPacketHeader)+14, 14);
end;

procedure TUnitTestConnection.TestMultipleRequests;
begin
  Test(ACRDefaultPacketSize, 100, acaNone, 0, 50);
end;

procedure TUnitTestConnection.TestMultiPacketsMultipleRequests;
begin
  Test(500, 40000, acaNone, 0, 15);
end;

procedure TUnitTestConnection.TestMultiConnectionPacketsMultipleRequests;
begin
  Test(50, 20000, acaNone, 0, 30);
end;

procedure TUnitTestConnection.Test4;
begin
  Test(ACRDefaultPacketSize, 100000000);            // 100 MB
end;

procedure TUnitTestConnection.Test5;
begin
  Test(ACRDefaultPacketSize, 20000000, acaZLIB, 5);            // 20 MB
end;

procedure TUnitTestConnection.TestCompression;
begin
  WriteToProcessLog('TestCompression: NONE');
  try
   Test(ACRDefaultPacketSize, ACRDefaultPacketSize-SizeOf(TACRPacketHeader), acaNone, 0);
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('TestCompression: NONE -> Error:'#13#10 + e.Message);
    end;
  end;
  WriteToProcessLog('NONE - OK!');

  WriteToProcessLog('TestCompression: ZLIB');
  try
   Test(512, 512-SizeOf(TACRPacketHeader), acaZLIB, 7); // memory leaks if Mode=1
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('TestCompression: ZLIB -> Error:'#13#10 + e.Message);
    end;
  end;
  WriteToProcessLog('ZLIB - OK!');

  WriteToProcessLog('TestCompression: BZIP');
  try
   Test(256, 256-SizeOf(TACRPacketHeader), acaBZIP, 5);
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('TestCompression: BZIP -> Error:'#13#10 + e.Message);
    end;
  end;
  WriteToProcessLog('BZIP - OK!');

  WriteToProcessLog('TestCompression: PPM');
  try
   Test(ACRDefaultPacketSize, ACRDefaultPacketSize-SizeOf(TACRPacketHeader), acaPPM, 5);
  except
   on e: Exception do
    begin
     UnitTestList.WriteToErrorLog('TestCompression: PPM -> Error:'#13#10 + e.Message);
    end;
  end;
  WriteToProcessLog('PPM - OK!');
end;

procedure TUnitTestConnection.TestWithoutReply;
begin
  Test(ACRDefaultPacketSize, 200, acaNone, 0, 100, False);
end;

procedure TUnitTestConnection.TestShort;
begin
  WriteToProcessLog('UnitTestConnection - short test started');
{
  CheckAction(TestWithoutReply, 'Connection Test - Client commands without server reply');
  CheckAction(TestSettings, 'Connection Test Settings');
  CheckAction(Test1, 'Connection Test1 - single packet request');
}
  CheckAction(Test2, 'Connection Test2 - multi-packets request');
{
  CheckAction(Test3, 'Connection Test3 - multi-packets connect');
  CheckAction(TestCompression, 'Connection TestCompression');
  CheckAction(TestMultipleRequests, 'Connection TestMultipleRequests');
  CheckAction(TestMultiPacketsMultipleRequests, 'Connection TestMultiPacketsMultipleRequests');
}
  WriteToProcessLog('UnitTestConnection - short test finished'#13#10);
end;


procedure TUnitTestConnection.TestExceptions;
begin
  WriteToProcessLog('UnitTestConnection - Exceptions test started');
  CheckAction(Test4, 'Connection Test - huge buffer - MaxPacketSize');
  CheckAction(Test5, 'Connection Test - huge buffer - DefaultPacketSize');
  CheckAction(TestMultiConnectionPacketsMultipleRequests, 'Connection Test - Multi-Packets Connection then Multi-Packets Multiple Requests');
  WriteToProcessLog('UnitTestConnection - Exceptions test finished'#13#10);
end;

initialization
  UnitTestConnection := TUnitTestConnection.Create(UnitTestList);

finalization
  UnitTestConnection.Free;


end.
