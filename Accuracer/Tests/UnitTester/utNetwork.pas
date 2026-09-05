unit utNetwork;

{$I ACRVer.inc}
{$I UTConfig.Inc}

interface

uses
     Controls, SysUtils, Math, Classes,
{$IFNDEF API_NETWORK}
 {$IFDEF D6H}
     IdSocketHandle,
 {$ENDIF}
{$ENDIF}
     Forms,
     uTestList,
     ACRCriticalSection,
     ACRLinux,
     ACRConst,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRConnection,
     ACRClient;

type

  TUnitTestNetwork = class(TUnitTest)
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
{$IFDEF API_NETWORK}
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
{$ELSE}
 {$IFDEF D6H}
    procedure OnClientReceived(
                              Sender:   TObject;
                              AData:    TStream;
                              ABinding: TIdSocketHandle
                             );
    procedure OnServerReceived(
                              Sender:   TObject;
                              AData:    TStream;
                              ABinding: TIdSocketHandle
                              );
 {$ELSE}
    procedure OnClientReceived(
                             Sender: TComponent;
                             BufferSize: Integer;
                             FromIP: string;
                             Port: integer
                             );
    procedure OnServerReceived(
                             Sender: TComponent;
                             BufferSize: Integer;
                             FromIP: string;
                             Port: integer
                              );
 {$ENDIF}
{$ENDIF API_NETWORK}
    procedure Compare;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestNetwork: TUnitTestNetwork;

implementation


{ TUnitTestNetwork }

{$IFDEF API_NETWORK}
procedure TUnitTestNetwork.OnClientReceived(
                             Buffer:    PChar;
                             Count:     Integer;
                             FromHost:  String;
                             FromPort:  Integer
                              );
begin
 try
  ClientReceived := True;
  WriteToProcessLog('Client has received a buffer');
  EnterCriticalSection(FCSect);
  inCount := Count;
  Move(Buffer^, inBuffer^, inCount);
  WriteToProcessLog('Client is checking received buffer...');
  Compare;
  LeaveCriticalSection(FCSect);
  ClientCompared := True;
 except
  WriteToErrorLog('OnClientReceived failed');
 end;
end;

procedure TUnitTestNetwork.OnServerReceived(
                             Buffer:    PChar;
                             Count:     Integer;
                             FromHost:  String;
                             FromPort:  Integer
                              );
begin
 try
  ServerReceived := True;
  WriteToProcessLog('Server has received a buffer');
  EnterCriticalSection(FCSect);
  inCount := Count;
  Move(Buffer^, inBuffer^, inCount);
  WriteToProcessLog('Server is checking received buffer...');
  Compare;
  LeaveCriticalSection(FCSect);
  ServerCompared := True;
 except
  WriteToErrorLog('OnServerReceived failed');
 end;
end;
{$ELSE}
{$IFDEF D6H}
procedure TUnitTestNetwork.OnClientReceived(
                              Sender:   TObject;
                              AData:    TStream;
                              ABinding: TIdSocketHandle
                              );
var
  buf: pchar;
begin
  buf := AllocMem(ACRMaxPacketSize);
  ClientReceived := True;
  WriteToProcessLog('Client has received a buffer');
  inCount := AData.Read(buf^, ACRMaxPacketSize);
  Move(buf^, inBuffer^, inCount);
  Compare;
end;

procedure TUnitTestNetwork.OnServerReceived(
                              Sender:   TObject;
                              AData:    TStream;
                              ABinding: TIdSocketHandle
                              );
var
  buf: pchar;
begin
  buf := AllocMem(ACRMaxPacketSize);
  ServerReceived := True;
  WriteToProcessLog('Server has received a buffer');
  inCount := AData.Read(buf^, ACRMaxPacketSize);
  Move(buf^, inBuffer^, inCount);
  Compare;
end;
{$ELSE}
procedure TUnitTestNetwork.OnClientReceived(
                             Sender: TComponent;
                             BufferSize: Integer;
                             FromIP: string;
                             Port: integer
                              );
var
  buf: array [0..ACRMaxPacketSize] of Char;
begin
  ClientReceived := True;
  WriteToProcessLog('Client has received a buffer');
  inCount := BufferSize;
  Client.FTransport.ReadBuffer(buf, BufferSize);
  Move(buf[0], inBuffer^, BufferSize);
  Compare;
 except
  WriteToErrorLog('');
 end;
end;

procedure TUnitTestNetwork.OnServerReceived(
                             Sender: TComponent;
                             BufferSize: Integer;
                             FromIP: string;
                             Port: integer
                              );
var
  buf: array [0..ACRMaxPacketSize] of Char;
begin
  ServerReceived := True;
  WriteToProcessLog('Server has received a buffer');
  inCount := BufferSize;
  Server.FTransport.ReadBuffer(buf, BufferSize);
  Move(buf[0], inBuffer^, BufferSize);
  Compare;
 except
  WriteToErrorLog('');
 end;
end;
{$ENDIF}
{$ENDIF}

procedure TUnitTestNetwork.Test1;
var
  PacketHeader: PACRPacketHeader;
  str:          string;
begin
 try

  TimeOut := 50;

  inBuffer := AllocMem(ACRMaxPacketSize);
  outBuffer := AllocMem(ACRMaxPacketSize);
  Client := TACRNetwork.Create(ClientConnectionManager);
  ServerManager := TACRServerConnectionManager.Create(nil);

 try
  PacketHeader := PACRPacketHeader(outBuffer);
  PacketHeader.Signature := 'ACR!';

  str := 'Test Buffer!!!';
  StrPCopy(outBuffer + SizeOf(TACRPAcketHeader), str);
  outCount := Length(str) + SizeOf(TACRPAcketHeader);
  inCount := 0;

  Client.RemoteHost := ACRDefaultHost;
  Client.RemotePort := ACRDefaultServerPort;
  Client.LocalPort  := ACRDefaultClientPort;

  Server := ServerManager.FNetwork; // Created by ServerManager.Create
{
//To test client #2 instead of server:
  Server := TACRNetwork.Create(ClientManager);
  Server.LocalPort  := ACRDefaultServerPort; // Set in ServerManager.Create
}
  Server.RemoteHost := ACRDefaultHost;
  Server.RemotePort := Client.LocalPort;
  Server.LocalPort  := ACRDefaultServerPort;

  ServerReceived := False;
  ServerCompared := False;
{$IFDEF API_NETWORK}
  Server.FACRNetwork.OnDataReceived := OnServerReceived;
{$ELSE}
 {$IFDEF D6H}
  Server.FNetworkServer.OnUDPRead := OnServerReceived;
 {$ELSE}
  Server.FTransport.OnDataReceived := OnServerReceived;
 {$ENDIF}
{$ENDIF}
  Client.SendBuffer(outBuffer, outCount);
  WriteToProcessLog('Client has sent the buffer');

  ClientReceived := False;
  ClientCompared := False;
{$IFDEF API_NETWORK}
  Client.FACRNetwork.OnDataReceived := OnClientReceived;
{$ELSE}
 {$IFDEF D6H}
  Client.FNetworkServer.OnUDPRead := OnClientReceived;
 {$ELSE}
  Client.FTransport.OnDataReceived := OnClientReceived;
 {$ENDIF}
{$ENDIF}
  Server.SendBuffer(outBuffer, outCount);
  WriteToProcessLog('Server has sent the buffer');

  StartTime := GetTickCount;
  while not (ClientReceived and ServerReceived) do // waiting for receive
   begin
{$IFNDEF API_NETWORK}
 {$IFDEF D6H}
    Application.ProcessMessages; // Needed for Indy only
 {$ENDIF D6H}
{$ENDIF API_NETWORK}
    Sleep(0);
    if (GetTickCount - StartTime) > TimeOut then
      Break;
   end;

  if not ServerReceived then
   begin
    WriteToErrorLog('Buffer was not received by Server for '+IntToStr(TimeOut)+' msec');
   end;

  if not ClientReceived then
   begin
    WriteToErrorLog('Buffer was not received by Client for '+IntToStr(TimeOut)+' msec');
   end;

  StartTime := GetTickCount;
  while not (ClientCompared and ServerCompared) do // waiting for compare
   begin
    Application.ProcessMessages; // Needed to compare!!!
    Sleep(0);
    if (GetTickCount - StartTime) > TimeOut then
      Break;
   end;

  if not ServerCompared then
   begin
    WriteToProcessLog('Warning: Buffer was not Compared by Server for '+IntToStr(TimeOut)+' msec');
   end;

  if not ClientCompared then
   begin
    WriteToProcessLog('Warning: Buffer was not Compared by Client for '+IntToStr(TimeOut)+' msec');
   end;

 finally
  FreeMem(inBuffer);
  FreeMem(outBuffer);
  Client.Free;
  ServerManager.Free; // release Server itself - does not require Server.Free;
 end;
 except
  WriteToErrorLog('Test1 failed');
 end;
end;

procedure TUnitTestNetwork.Compare;
var
EQ : Boolean;
i:   Integer;
begin
 try
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
 except
  WriteToErrorLog('Compare procedure failed');
 end;
end;

procedure TUnitTestNetwork.Test2;
begin
 try
 except
  WriteToErrorLog('Test2 failed');
 end;
end;


procedure TUnitTestNetwork.TestShort;
begin
 try
  InitializeCriticalSection(FCSect);
  WriteToProcessLog('UnitTestNetwork - short test started');
  CheckAction(Test1, 'Network Test1');
  WriteToProcessLog('UnitTestNetwork - short test finished'#13#10);
  DeleteCriticalSection(FCSect);
 except
  WriteToErrorLog('TestShort failed');
 end;
end;


procedure TUnitTestNetwork.TestExceptions;
begin
 try
  WriteToProcessLog('UnitTestNetwork - exceptions test started');
  CheckAction(Test2, 'Network Test2');
  WriteToProcessLog('UnitTestNetwork - exceptions test finished'#13#10);
 except
  WriteToErrorLog('TestExceptions failed');
 end;
end;

initialization
  UnitTestNetwork := TUnitTestNetwork.Create(UnitTestList);
finalization
  UnitTestNetwork.Free;
end.
