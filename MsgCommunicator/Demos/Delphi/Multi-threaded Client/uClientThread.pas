unit uClientThread;

interface

{DEFINE DEBUG_MODE}


uses
  Classes, SysUtils,  Dialogs, Windows,
  MsgComBase, MsgClient, MsgConst, MsgTypes, MsgExcept,
  
{$IFDEF DEBUG_MODE}
 MsgDebug,
{$ENDIF}

  MsgMemory;

type
  TClientThread = class(TThread)
  private
    FClient: TMsgClient;
    FUserID: Cardinal;
    FFirstUserID: Cardinal;
    FServerID: Cardinal;
    FSendTextCount:     Integer;
    FTextMessage:       String;
    FSendToClient:      Boolean;
    FSendToServer:      Boolean;
    FConnnectParamsEditor: TMsgClientConnectParamsEditor;
  protected
    procedure OnError(
                       Sender:             TComponent;
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: String
                     );
    procedure OnStart;
    procedure OnFinish;
    procedure RunTest;
    procedure Execute; override;
  public
    property FirstUserID: Cardinal read FFirstUserID write FFirstUserID;
    property UserID: Cardinal read FUserID write FUserID;
    property ServerID: Cardinal read FServerID write FServerID;
    property SendTextCount: Integer read FSendTextCount write FSendTextCount;
    property TextMessage: String read FTextMessage write FTextMessage;
    property SendToClient: Boolean read FSendToClient write FSendToClient;
    property SendToServer: Boolean read FSendToServer write FSendToServer;
    property ConnnectParamsEditor: TMsgClientConnectParamsEditor read FConnnectParamsEditor write FConnnectParamsEditor;
  end;

implementation

uses uMain;
{
  TMsgOnError = procedure (
                       Sender:             TComponent;
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: String
                     ) of object;

}
procedure TClientThread.OnError(Sender: TComponent; const ErrorCode,
  NativeError: Integer; const ErrorMessage: String);
begin
aaWriteToLog('==================================================================');
aaWriteToLog('Error on client #'+IntToStr(FUserID)+' !');
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage: "'+ErrorMessage+'"');
aaWriteToLog('GetTickCount = '+IntToStr(aaGetTickCount));
aaWriteToLog('==================================================================');
end;


procedure TClientThread.OnFinish;
begin
 if (fmMain <> nil) then
  fmMain.FinishThread(FUserID);
end;

procedure TClientThread.OnStart;
begin
 if (fmMain <> nil) then
  fmMain.StartThread(FUserID);
end;

procedure TClientThread.RunTest;
var UserInfo: TMsgUserInfo;
    error,i:  Integer;
    Delay:    Integer;
begin
  Delay := 0; //100;
  FillChar(UserInfo,SizeOf(UserInfo),$00);
  FClient := TMsgClient.Create(nil);
  try
   FClient.AllowDirectly := false;
   FClient.AllowFiles := false;
   FClient.Active := false;
   FClient.OnError := OnError;
   FClient.ConnectionParams.Assign(FConnnectParamsEditor);
   try
    FClient.UserID := MSG_INVALID_USER_ID;
    FClient.Connected := true;
//    sleep(Random(Delay)+Delay);
    error := FClient.IsUserExisting(FUserID);
    if (error <> MSG_COMMAND_RESULT_true) and (error <> MSG_COMMAND_RESULT_false) then
     begin
      FClient.OnError(FClient,error,-1,'Cannot check is user exisitng, UserID = '+IntToStr(FUserID));
      Exit;
     end;
    sleep(Random(Delay)+Delay);
    // register new user if not found
    if (error <> MSG_COMMAND_RESULT_true) then
     begin
      UserInfo.UserID := FUserID;
      UserInfo.UserName := 'User #'+IntToStr(FUserID);
      UserInfo.FirstName := UserInfo.UserName;
      error := FClient.RegisterNewUser(UserInfo);
      if (error <> MSG_COMMAND_OK) then
       begin
        FClient.OnError(FClient,error,-1,'Cannot register user, UserID = '+IntToStr(FUserID));
        Exit;
       end;
{$IFDEF DEBUG_MODE}
      aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' registered');
{$ENDIF}
     end
    else
     begin
    //    sleep(Random(Delay)+Delay);
      FClient.Connected := false;
      FClient.Active := false;
      FClient.AllowDirectly := false;
      FClient.UserID := FUserID;
{$IFDEF DEBUG_MODE}
      aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' disconnected.');
{$ENDIF}
    //    sleep(Random(Delay)+Delay);
      FClient.Connected := true;
     end;

    if (FClient.UserID <> FUserID) then
     begin
      FClient.OnError(FClient,error,-1,'Cannot connect user, UserID = '+IntToStr(FUserID)+', FClient.UserID = '+IntToStr(FClient.UserID));
      Exit;
     end;
{$IFDEF DEBUG_MODE}
    aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' connected');
{$ENDIF}
//    sleep(Random(Delay)+Delay);
    // sending text to server
    for i := 1 to FSendTextCount do
     begin
      if (fmMain <> nil) then
       if (fmMain.Abort) then
        begin
{$IFDEF DEBUG_MODE}
         aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' break on abort');
{$ENDIF}
         break;
        end;
      if (FSendToClient) then
       begin
        error := FClient.SendMessage(FFirstUserID,FTextMessage);
        if (error <> MSG_COMMAND_OK) then
         begin
          FClient.OnError(FClient,error,-1,'Cannot send message to user, UserID = '+IntToStr(FUserID)+', ServerID = '+IntToStr(FFirstUserID));
          Exit;
         end;
       end; // send to client

      if (FSendToServer) then
       begin
        error := FClient.SendMessage(FServerID,FTextMessage);
        if (error <> MSG_COMMAND_OK) then
         begin
          FClient.OnError(FClient,error,-1,'Cannot send message to server, UserID = '+IntToStr(FUserID)+', ServerID = '+IntToStr(FServerID));
          Exit;
         end;
       end; // send to server
     end;
{$IFDEF DEBUG_MODE}
    aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' text messages sent');
{$ENDIF}
   except
    on E: Exception do
     begin
      FClient.OnError(FClient,0,-1,e.Message);
     end;
   end;
  finally
//    sleep(Random(Delay)+Delay);
   try
    FClient.OnError := nil;
    FClient.Free;
   except
    on e: Exception do
     begin
{$IFDEF DEBUG_MODE}
    aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' destroy failed: ');
    aaWriteToLog(e.Message);
{$ENDIF}
     end;
   end;
{$IFDEF DEBUG_MODE}
    aaWriteToLog(IntToStr(aaGetTickCount)+' User #'+IntToStr(FUserID)+' test finished');
{$ENDIF}
  end;
end;

procedure TClientThread.Execute;
begin
  Synchronize(OnStart);
  try
    RunTest;
  finally
    Synchronize(OnFinish);
  end;
end;



end.
