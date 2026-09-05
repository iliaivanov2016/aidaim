unit utNetworkTCP;

{$I ACRVer.inc}

interface

uses
     Controls, SysUtils, Math, Classes, Forms,
     uTestList,
     ACRCriticalSection,
     ACRLinux,
     ACRConst,
     ACRConnection,
     ACRClient;

type

  TUnitTestNetworkTCP = class(TUnitTest)
   private
    StartTime,
    TimeOut:          Integer;
    ClientReceived:   Boolean;
    ServerReceived:   Boolean;
    ClientCompared:   Boolean;
    ServerCompared:   Boolean;
    outBuffer:        PChar;
    inBuffer:         PChar;
    inCount,
    outCount:         Integer;
    ServerManager:    TACRServerConnectionManager;
    Client,
    Server:           TACRNetwork;
    FCSect:           TRTLCriticalSection;
    procedure Test1;
    procedure Test2;
    procedure OnClientReceived(
                             Buffer:    PChar;
                             Count:     Integer;
                             FromHost:  String;
                             FromPort:  Integer
                             );
    procedure OnServerReceived(
                             Buffer:    PChar;
                             Count:     Integer;
                             FromHost:  String;
                             FromPort:  Integer
                             );
    procedure Compare;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestNetworkTCP: TUnitTestNetworkTCP;

implementation


{ TUnitTestNetworkTCP }

procedure TUnitTestNetworkTCP.OnClientReceived(
                             Buffer:    PChar;
                             Count:     Integer;
                             FromHost:  String;
                             FromPort:  Integer
                              );
begin
  WriteToProcessLog('Client has received a buffer');
  ClientReceived := True;
  EnterCriticalSection(FCSect);
  inCount := Count;
  Move(Buffer^, inBuffer^, inCount);
  WriteToProcessLog('Client is checking received buffer...');
  Compare;
  LeaveCriticalSection(FCSect);
  ClientCompared := True;
end;

procedure TUnitTestNetworkTCP.OnServerReceived(
                             Buffer:    PChar;
                             Count:     Integer;
                             FromHost:  String;
                             FromPort:  Integer
                              );
begin
  WriteToProcessLog('Server has received a buffer');
  ServerReceived := True;
  EnterCriticalSection(FCSect);
  inCount := Count;
  Move(Buffer^, inBuffer^, inCount);
  WriteToProcessLog('Server is checking received buffer...');
  Compare;
  LeaveCriticalSection(FCSect);
  ServerCompared := True;
end;

procedure TUnitTestNetworkTCP.Test1;
var
  PacketHeader: PACRPacketHeader;
  str:          string;
begin

  TimeOut := 300;

  inBuffer := AllocMem(ACRMaxPacketSize);
  outBuffer := AllocMem(ACRMaxPacketSize);
 try // except
  WriteToProcessLog('=== Create server');
  ServerManager := TACRServerConnectionManager.Create(nil,ACR_TCP);

  WriteToProcessLog('=== Create client');
  ClientConnectionManager := TACRClientConnectionManager.Create;
  Client := TACRNetwork.Create(ClientConnectionManager,ACR_TCP);
  Client.FACRNetwork.OnDataReceived := OnClientReceived;

 try // finally
  PacketHeader := PACRPacketHeader(outBuffer);
  PacketHeader.Signature := 'ACR!';

  str := 'Test Buffer!!!';
  StrPCopy(outBuffer + SizeOf(TACRPAcketHeader), str);
  outCount := Length(str) + SizeOf(TACRPAcketHeader);
  inCount := 0;

  WriteToProcessLog('=== Set client params');
  Client.LocalHost  := ACRDefaultHost;
  Client.LocalPort  := ACRDefaultClientPort; // 12008; //
  Client.RemoteHost := ACRDefaultHost;
  Client.RemotePort := ACRDefaultServerPort;
  WriteToProcessLog('Client local  = '+Client.LocalHost+':'+IntToStr(Client.LocalPort));
  WriteToProcessLog('Client remote = '+Client.RemoteHost+':'+IntToStr(Client.RemotePort));

  Server := ServerManager.FNetwork; // Created by ServerManager.Create
  Server.FACRNetwork.OnDataReceived := OnServerReceived;

//To test client #2 instead of server:
{
  Server := TACRNetwork.Create(ClientManager);
  Server.LocalPort  := ACRDefaultServerPort; // Set in ServerManager.Create
}
  WriteToProcessLog('=== Set server params');
{
  Server.LocalHost := ACRDefaultServerHost;
  Server.LocalPort := ACRDefaultServerPort;
}
  Server.RemoteHost := ACRDefaultHost;
  Server.RemotePort := 12008; // ACRDefaultClientPort;
  sleep(100); // needs for server to accept connections
  WriteToProcessLog('Server local  = '+Server.LocalHost+':'+IntToStr(Server.LocalPort));
  WriteToProcessLog('Server remote = '+Server.RemoteHost+':'+IntToStr(Server.RemotePort));

  ServerReceived := False;
  ServerCompared := False;
  ClientReceived := False;
  ClientCompared := False;

  WriteToProcessLog('=== Client send');
  Client.SendBuffer(outBuffer, outCount);
  WriteToProcessLog('Client has sent the buffer');

  WriteToProcessLog('=== Server send');
  Server.SendBuffer(outBuffer, outCount, 0, Client.FACRNetwork.LocalHost, Client.FACRNetwork.LocalPort);
  WriteToProcessLog('Server has sent the buffer');

  WriteToProcessLog('=== Check');
  StartTime := GetTickCount;
  while not (ClientReceived and ServerReceived) do // waiting for receive
   begin
    Application.ProcessMessages;
    Sleep(1);
    if (GetTickCount - StartTime) > TimeOut then
      Break;
   end;

  if not ServerReceived then
   begin
    WriteToProcessLog('Error: Buffer was not received by Server for '+IntToStr(TimeOut)+' msec');
    WriteToErrorLog('Buffer was not received by Server for '+IntToStr(TimeOut)+' msec');
   end;

  if not ClientReceived then
   begin
    WriteToProcessLog('Error: Buffer was not received by Client for '+IntToStr(TimeOut)+' msec');
    WriteToErrorLog('Buffer was not received by Client for '+IntToStr(TimeOut)+' msec');
   end;

  StartTime := GetTickCount;
  while not (ClientCompared and ServerCompared) do // waiting for compare
   begin
    Application.ProcessMessages; // Needed to compare!!!
    Sleep(1);
    if (GetTickCount - StartTime) > TimeOut then
      Break;
   end;

  if not ServerCompared then
   begin
    WriteToProcessLog('Error: Buffer was not Compared by Server for '+IntToStr(TimeOut)+' msec');
    WriteToErrorLog('Buffer was not Compared by Server for '+IntToStr(TimeOut)+' msec');
   end;

  if not ClientCompared then
   begin
    WriteToProcessLog('Error: Buffer was not Compared by Client for '+IntToStr(TimeOut)+' msec');
    WriteToErrorLog('Buffer was not Compared by Client for '+IntToStr(TimeOut)+' msec');
   end;
 finally
  FreeMem(inBuffer);
  FreeMem(outBuffer);
  Client.Free;
  ServerManager.Free; // release Server itself - does not require Server.Free;
 end;
 except
  WriteToErrorLog('!!! Exception occurs !!!');
  raise;
 end;
end;

procedure TUnitTestNetworkTCP.Compare;
var
EQ : Boolean;
i:   Integer;
begin
  EQ := True;
  for i:= SizeOf(TACRPacketHeader) to Min(inCount-1, outCount-1) do
    if (inBuffer+i)^ <> (outBuffer+i)^ then
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
      WriteToErrorLog('Received buffer = "'+PChar(inBuffer+SizeOf(TACRPacketHeader))+'"');
      WriteToErrorLog('Sent buffer     = "'+PChar(outBuffer+SizeOf(TACRPacketHeader))+'"');
     end
    else
      WriteToProcessLog('Received buffer is equal to sent buffer');
  inCount := 0;
end;

procedure TUnitTestNetworkTCP.Test2;
begin
end;


procedure TUnitTestNetworkTCP.TestShort;
begin
  InitializeCriticalSection(FCSect);
  WriteToProcessLog('UnitTestNetworkTCP - short test started');
  CheckAction(Test1, 'Network Test1');
  WriteToProcessLog('UnitTestNetworkTCP - short test finished'#13#10);
  DeleteCriticalSection(FCSect);
end;


procedure TUnitTestNetworkTCP.TestExceptions;
begin
  WriteToProcessLog('UnitTestNetworkTCP - exceptions test started');
  CheckAction(Test2, 'Network Test2');
  WriteToProcessLog('UnitTestNetworkTCP - exceptions test finished'#13#10);
end;

initialization
  UnitTestNetworkTCP := TUnitTestNetworkTCP.Create(UnitTestList);

finalization
  UnitTestNetworkTCP.Free;

end.
