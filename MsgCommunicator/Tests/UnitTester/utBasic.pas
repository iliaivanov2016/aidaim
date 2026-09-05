

unit utBasic;

interface

{$I MsgVer.Inc}

uses uTestList, SysUtils,
Classes,
MsgComBase,
MsgClient,
MsgServer,
MsgDebug,
MsgConst,
MsgCrypto,
MsgTypes,
MsgMemory;

const TestBlockSize: Integer = 1024; // Bytes

type
  TUnitTestBasic = class(TUnitTest)
   private
    Test1: Boolean;
   protected
    function CompareBuffers(Buffer1,Buffer2: PChar; BufferSize: Integer): Boolean;
    function CompareStreams(Stream1,Stream2: TStream): Boolean;
    procedure TestBasic;
    procedure TestBasicExceptions;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestBasic: TUnitTestBasic;


implementation



function TUnitTestBasic.CompareBuffers(Buffer1,Buffer2: PChar; BufferSize: Integer): Boolean;
var i: Integer;
begin
 Result := False;
 for i := 0 to BufferSize-1 do
  if (PByte(Buffer1 + i)^ <> PByte(Buffer2 + i)^) then
   Exit;
 Result := True;
end; // CompareBuffers


function TUnitTestBasic.CompareStreams(Stream1,Stream2: TStream): Boolean;
var buf1, buf2:     PChar;
    BufferSize,x:   Integer;
    ReadSize:       Integer;
    oldPos,oldPos1: Int64;
begin
 Result := False;
 oldPos := Stream1.Position;
 oldPos1 := Stream2.Position;
 if (Stream1.Position <> Stream2.Position) then
  UnitTestList.WriteToErrorLog('CompareStreams failed: positions not equal #1')
 else
  try
   if (Stream1.Size <> Stream2.Size) then
    begin
     UnitTestList.WriteToErrorLog('CompareStreams failed: sizes not equal #3');
    end
   else
    begin
     if (Stream1.Size = 0) then
      Result := True
     else
      begin
       BufferSize := TestBlockSize;
       buf1 := MemoryManager.GetMem(BufferSize);
       buf2 := MemoryManager.GetMem(BufferSize);
       try
        Stream1.Position := 0;
        Stream2.Position := 0;
        Result := True;
        while (Stream1.Position < Stream1.Size) do
         begin
          if (Stream1.Size - Stream1.Position < BufferSize) then
           ReadSize := Stream1.Size - Stream1.Position
          else
           ReadSize := BufferSize;
          x := Stream1.Read(buf1^,ReadSize);
          if (x <> ReadSize) then
           begin
            Result := False;
            UnitTestList.WriteToErrorLog('CompareStreams failed: stream1 read failed #5');
            break;
           end;
          x := Stream2.Read(buf2^,ReadSize);
          if (x <> ReadSize) then
           begin
            Result := False;
            UnitTestList.WriteToErrorLog('CompareStreams failed: stream2 read failed #6');
            break;
           end;
          if (not CompareBuffers(buf1,buf2,ReadSize)) then
           begin
            Result := False;
            UnitTestList.WriteToErrorLog('CompareStreams failed: data not equal #4');
            break;
           end;
         end;
       finally
        MemoryManager.FreeAndNilMem(buf1);
        MemoryManager.FreeAndNilMem(buf2);
       end;
      end;
    end;
  finally
   Stream1.Position := oldPos;
   Stream2.Position := oldPos1;
   if (Stream1.Position <> Stream2.Position) then
    UnitTestList.WriteToErrorLog('CompareStreams failed: positions not equal #2');
  end;
end; // CompareStreams


procedure TUnitTestBasic.TestBasic;
var Caption:      String;
    cl1:          TMsgClient;
    srv:          TMsgServer;
    UserInfo:     TMsgUserInfo;
begin
 if (Test1) then
  Caption := 'TestBasic - test1 '
 else
  Caption := 'TestBasic - test2 ';
 srv := TMsgServer.Create(nil);
 cl1 := TMsgClient.Create(nil);
 try
  srv.DataPath := Self.TempDir;
  srv.UseConfigFile := False;
  srv.Active := True;
  cl1.UserID := MSG_INVALID_USER_ID;
  cl1.Connect;
  UserInfo.UserID := cl1.UserID;
  UserInfo.UserName := 'user1';
  UserInfo.FirstName := 'Leo';
  UserInfo.LastName := 'Martin';
  UserInfo.Organization := 'AidAim Software LLC';
  UserInfo.Department := 'Development Department';
  if (cl1.IsUserExisting(cl1.UserID) = MSG_COMMAND_RESULT_TRUE) then
   WriteToErrorLog(Caption+'user exists')
  else
   begin
    cl1.RegisterNewUser(UserInfo);
    if (cl1.UserID <> 1) then
     WriteToErrorLog(Caption+'user id changed');
    if (cl1.IsUserExisting(cl1.UserID) <> MSG_COMMAND_RESULT_TRUE) then
     WriteToErrorLog(Caption+'user does not exist');
    srv.DeleteUser(cl1.UserID);
    if (cl1.IsUserExisting(cl1.UserID) = MSG_COMMAND_RESULT_TRUE) then
     WriteToErrorLog(Caption+'user was not deleted')
   end;
  cl1.Disconnect;
 finally
  if (Test1) then
   begin
    srv.Free;
    cl1.Free;
   end
  else
   begin
    cl1.Free;
    srv.Free;
   end;
 end;
end; // TestBasic


procedure TUnitTestBasic.TestBasicExceptions;
var Caption: String;
begin
 Caption := 'TestBasic Exceptions ';
end; // TestBasicExceptions


procedure TUnitTestBasic.TestShort;
begin
 Test1 := True;
 CheckAction(TestBasic,'Test MsgCommunicator Basic Operations');
 Test1 := False;
 CheckAction(TestBasic,'Test MsgCommunicator Basic Operations');
end;

procedure TUnitTestBasic.TestExceptions;
begin
 CheckAction(TestBasicExceptions,'Test MsgCommunicator Basic Operations With Exceptions');
end;

initialization
  UnitTestBasic := TUnitTestBasic.Create(UnitTestList);

finalization
  UnitTestBasic.Free;
end.
