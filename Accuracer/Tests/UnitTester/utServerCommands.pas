unit utServerCommands;

{$I UTConfig.Inc}

interface

uses SysUtils, Classes, Math, Windows,
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
  TUnitTestServerCommands = class(TUnitTest)
   private
    procedure Test(BufSize: Integer = 1000);
    procedure Test1;
    procedure Test2;
    procedure Test3;
    procedure Test4;
    procedure Test5;
    procedure Test6;
    procedure Test7;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
    procedure ReceiveCommand(Buffer: PAnsiChar; Size: Integer);
    procedure CompareBuffers(recvBuffer: PAnsiChar; recvBufSize: Integer);
  end;


var
  UnitTestServerCommands: TUnitTestServerCommands;
  Received: Boolean;
  TimeCompare,
  StartTimeRecv:      Cardinal;
  sendBuffer: PAnsiChar;
  sendBufSize: Integer;

const
  TimeOut = 1000; // msec

implementation

{ TUnitTestConnection }

procedure TUnitTestServerCommands.ReceiveCommand(Buffer: PAnsiChar; Size: Integer);
begin
  StartTimeRecv := GetTickCount;
  Received := True;
  CompareBuffers(Buffer,Size);
end;

procedure TUnitTestServerCommands.CompareBuffers(recvBuffer: PAnsiChar; recvBufSize: Integer);
var
  eq: Boolean;
  i : Integer;
begin
 eq := False;
 try
  if recvBufSize <> sendBufSize then
    Exit; // error
{
  for i := 0 to (recvBufSize-1) do
    if Byte((recvBuffer+i)^) <> Byte((sendBuffer+i)^) then
      Exit; // error
}
  eq := CompareMem(sendBuffer,recvBuffer,recvBufSize);
 finally
   TimeCompare := GetTickCount;
   if eq then
     WriteToProcessLog('Received buffer is equal to the buffer was sent')
   else
     WriteToErrorLog('Received buffer is not equal to the buffer was sent!')
 end;
end;

procedure TUnitTestServerCommands.Test(BufSize: Integer = 1000);
var
  Server:                   TACRServer;
  ClientSession:            TACRClientSession;
  ConnectParams:            TACRClientConnectParamsEditor;
  Buf:            PAnsiChar;
  StartTimeSend,
  StartTime:      Cardinal;

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
  try
   Received := False;
   ClientSession.OnReceiveCommandMessage := ReceiveCommand;
   Connect;
   Buf := MemoryManager.GetMem(BufSize);
   sendBuffer := Buf;
   sendBufSize := BufSize;
   try
    try
     StartTimeSend := GetTickCount;
     TACRServerSEssion(PACRSrvrSession(Server.ConnectionManager.FSessions.Items[0]).Session).
       SendServerCommand(Buf,BufSize);
     WriteToProcessLog('Command sent for '+IntToStr(GetTickCount - StartTimeSend)+' msec');
    except
      on e: Exception do
       begin
        UnitTestList.WriteToErrorLog('SendServerCommand -> Error:'#13#10 + e.Message);
       end;
    end;
     WriteToProcessLog('Wait for command to be received...');
     StartTime := GetTickCount;
     while GetTickCount < (StartTime+TimeOut) do
       if Received then
         break
       else
         sleep(1);
     if Received then
       WriteToProcessLog('Command received for '+IntToStr(GetTickCount - StartTime)+' msec, '
                         +CRLF+'total time for send/receive = '+IntToStr((GetTickCount - StartTimeSend))+' msec, '
                         +CRLF+'real time to receive = '+IntToStr((GetTickCount - StartTimeRecv))+' msec, '
                         +CRLF+'time to compare buffers = '+IntToStr((StartTimeRecv - TimeCompare))+' msec'
                         )
     else
       WriteToErrorLog('Command is not received by client for '+IntToStr(TimeOut)+' msec!')
   finally
    MemoryManager.FreeAndNilMem(Buf);
   end;
   Disconnect;
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

procedure TUnitTestServerCommands.Test1;
begin
  Test(100);
end;

procedure TUnitTestServerCommands.Test2;
begin
  Test(1000);
end;

procedure TUnitTestServerCommands.Test3;
begin
  Test(10000);
end;

procedure TUnitTestServerCommands.Test4;
begin
  Test(100000);
end;

procedure TUnitTestServerCommands.Test5;
begin
  Test(1000000);
end;

procedure TUnitTestServerCommands.Test6;
begin
  Test(10000000);
end;

procedure TUnitTestServerCommands.Test7;
begin
  Test(100000000);
end;

procedure TUnitTestServerCommands.TestShort;
begin
  WriteToProcessLog('UnitTestServerCommands - short test started');
  CheckAction(Test1, 'Server Commands Test 100 bytes');
  CheckAction(Test2, 'Server Commands Test 1000 bytes');
  CheckAction(Test3, 'Server Commands Test 10 Kbytes');
  CheckAction(Test4, 'Server Commands Test 100 Kbytes');
  CheckAction(Test5, 'Server Commands Test 1 Mbytes');
//  CheckAction(Test6, 'Server Commands Test 10 Mbytes');
//  CheckAction(Test7, 'Server Commands Test 100 Mbytes');
  WriteToProcessLog('UnitTestServerCommands - short test finished'#13#10);
end;

procedure TUnitTestServerCommands.TestExceptions;
begin
  WriteToProcessLog('UnitTestConnection - Exceptions test started');
  WriteToProcessLog('UnitTestConnection - Exceptions test finished'#13#10);
end;

initialization
  UnitTestServerCommands := TUnitTestServerCommands.Create(UnitTestList);

finalization
  UnitTestServerCommands.Free;

end.
