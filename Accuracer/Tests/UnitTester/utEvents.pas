unit utEvents;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes, DB,
{$IFNDEF D6H}
      DBTables,
{$ELSE}
 {$IFDEF MSWINDOWS}
      DBTables,
 {$ENDIF}
{$ENDIF}
      DBClient,
     uTestList,
     ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRServer,
     ACRConst,
     ACRTypes,
     ACRCompression,
     ACRDecUtil,
     ACRCrypto,
     ACRMemory
     ;
const TestBufSize = 65536; // 64 Kb
const TestStreamSize = 1024*1024; // 1 Mb
const Capt = 'TestEvents - ';

type
  TUnitTestEvents = class(TUnitTest)
   private
    FAfterServerStart: Boolean;
    FBeforeServerStop: Boolean;
    FAfterConnect: Boolean;
    FBeforeDisconnect: Boolean;
    FAfterServerShutdown: Boolean;
   protected
    procedure Init;
    procedure Finalize;
    procedure TestEvents;
    function TestFinished: Boolean;
    procedure AfterServerStart(Sender: TObject);
    procedure BeforeServerStop(Sender: TObject);
    procedure AfterConnect(Sender: TObject);
    procedure BeforeDisconnect(Sender: TObject);
    procedure AfterServerShutdown(Sender: TObject);
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestEvents: TUnitTestEvents;


implementation

{ TUnitTestEvents }

procedure TUnitTestEvents.Finalize;
begin
end;

procedure TUnitTestEvents.Init;
begin
  FAfterServerStart := False;
  FBeforeServerStop := False;
  FAfterConnect := False;
  FBeforeDisconnect := False;
  FAfterServerShutdown := False;
end;

procedure TUnitTestEvents.AfterServerStart(Sender: TObject);
begin
  FAfterServerStart := True;
end;

procedure TUnitTestEvents.BeforeServerStop(Sender: TObject);
begin
  FBeforeServerStop := True;
end;

procedure TUnitTestEvents.AfterConnect(Sender: TObject);
begin
  FAfterConnect := True;
end;

procedure TUnitTestEvents.BeforeDisconnect(Sender: TObject);
begin
  FBeforeDisconnect := True;
end;

procedure TUnitTestEvents.AfterServerShutdown(Sender: TObject);
begin
  FAfterServerShutdown := True;
end;

procedure TUnitTestEvents.TestExceptions;
begin
end;

function TUnitTestEvents.TestFinished: Boolean;
begin
  Result :=
    FAfterServerStart and
    FBeforeServerStop and
    FAfterConnect and
    FBeforeDisconnect and
    FAfterServerShutdown;
  if (Result) then
    WriteToProcessLog(Capt + 'TestFinished successfully!')
  else
   begin
    WriteToProcessLog(Capt + 'TestFinished with error:');
    if not FAfterServerStart then
      WriteToProcessLog(#13#10+'AfterServerStart server event is not called!');
    if not FBeforeServerStop then
      WriteToProcessLog(#13#10+'BeforeServerStop server event is not called!');
    if not FAfterConnect then
      WriteToProcessLog(#13#10+'AfterConnect database event is not called!');
    if not FBeforeDisconnect then
      WriteToProcessLog(#13#10+'BeforeDisconnect database event is not called!');
    if not FAfterServerShutdown then
      WriteToProcessLog(#13#10+'AfterServerShutdown database event is not called!');
  end;
end;

procedure TUnitTestEvents.TestEvents;
var db:       TACRDatabase;
    srv:      TACRServer;
    Clients:  TACRClientInfoArray;
begin
  WriteToProcessLog(Capt+'starting...');
  db := TACRDatabase.Create(nil);
  srv := TACRServer.Create(nil);
  Init;
  try
   db.DatabaseFileName := IncludeTrailingBackslash(TempDir)+'test_sm.adb';
   if (db.Exists) then
    db.DeleteDatabase;
   db.CreateDatabase;
   db.LocalDatabase := False;
   db.ConnectionParams.NetworkSettings.ConnectRetryCount := 10;
   db.ConnectionParams.NetworkSettings.ConnectDelay := 10;
   srv.DatabaseNames.Add(db.ConnectionParams.DatabaseName);
   srv.DatabaseFileNames.Add(db.DatabaseFileName);

   srv.AfterServerStart := AfterServerStart;
   srv.BeforeServerStop := BeforeServerStop;

   db.AfterConnect := AfterConnect;
   db.BeforeDisconnect := BeforeDisconnect;
   db.AfterServerShutdown := AfterServerShutdown;

   srv.Active := True;
   db.Open;
   srv.Active := False;
   db.Close;
  finally
   TestFinished;
   Finalize;
   db.Free;
   srv.Free;
   WriteToProcessLog(Capt+'finished.');
  end;
end;

procedure TUnitTestEvents.TestShort;
begin
  CheckAction(TestEvents,'Test Events');
end;

initialization
  UnitTestEvents := TUnitTestEvents.Create(UnitTestList);

finalization
  UnitTestEvents.Free;


end.
