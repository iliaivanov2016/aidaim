unit uMain;

interface

{DEFINE DEBUG_MODE}


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls,

  uClientThread,
  uDisplayThread,
  MsgServer,MsgComBase,MsgClient,MsgConst,
{$IFDEF DEBUG_MODE}
  MsgDebug,
{$ENDIF}

  CheckLst,Spin
{$IFDEF DEBUG_MODE}
//  , MemCheck
{$ENDIF}
  ;

const StartUserID = 1000001;
const DisplayMessages: Boolean = true;

type
  TfmMain = class(TForm)
    Panel1: TPanel;
    gbTextMessage: TGroupBox;
    reTestMessage: TRichEdit;
    Splitter2: TSplitter;
    GroupBox1: TGroupBox;
    Panel2: TPanel;
    Splitter3: TSplitter;
    gbClientThreads: TGroupBox;
    Splitter1: TSplitter;
    GroupBox4: TGroupBox;
    reLog: TRichEdit;
    Splitter4: TSplitter;
    GroupBox5: TGroupBox;
    reMessages: TRichEdit;
    bnRun: TButton;
    bnAbort: TButton;
    bnExit: TButton;
    Timer1: TTimer;
    MsgClient1: TMsgClient;
    MsgServer1: TMsgServer;
    seNumClients: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    seNumRepeats: TSpinEdit;
    cbSendToClient: TCheckBox;
    cbSendToServer: TCheckBox;
    clbClients: TCheckListBox;
    GroupBox6: TGroupBox;
    Splitter5: TSplitter;
    lbClientMessages: TLabel;
    lbServerMessages: TLabel;
    lbElapsedTime: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure bnAbortClick(Sender: TObject);
    procedure MsgClient1Error(Sender: TComponent; const ErrorCode,
      NativeError: Integer; const ErrorMessage: String);
    procedure MsgServer1Error(Sender: TComponent; const ErrorCode,
      NativeError: Integer; const ErrorMessage: String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnRunClick(Sender: TObject);
    procedure MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure MsgClient1AfterLogon(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure MsgServer1ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
  private
    { Private declarations }
//    FClients:     array of TClientThread;
    FThreadCount: Integer;
    FAbort:       Boolean;
  public
    { Public declarations }
    procedure ClearClients;
    procedure RunTest;
    procedure StartThread(UserID: Integer);
    procedure FinishThread(UserID: Integer);
    property Abort: Boolean read FAbort;
  end;


var
  fmMain:       TfmMain;
  AppPath:      String;
  TestStarted:  Boolean;
  NumClients:   Integer;
  NumRepeats:   Integer;
  SendToClient: Boolean;
  SendToServer: Boolean;
  StartTime:    Cardinal;
  NumClientMsg: Integer;
  NumServerMsg: Integer;
  TestMsg:      String;

{$IFNDEF DEBUG_MODE}
procedure aaWriteToLog(s: string);
function aaGetTickCount: Cardinal;
{$ENDIF}

implementation

{$R *.dfm}

{$IFNDEF DEBUG_MODE}
procedure aaWriteToLog(s: string);
begin
  if (fmMain <> nil) then
   fmMain.reLog.Lines.Add(s);
end;


function aaGetTickCount: Cardinal;
begin
  Result := Windows.GetTickCount;
end; // aaGetTickCount
{$ENDIF}

procedure TfmMain.FormCreate(Sender: TObject);
var userID:   Cardinal;
    error:    Integer;
    userInfo: TMsguserInfo;
begin
//  FClients := nil;
  TestStarted := false;
  AppPath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
  MsgServer1.DataPath := AppPath + 'Data\';
  try
    MsgServer1.Active := true;
  except
    on e: Exception do
     begin
      ShowMessage('Error starting server: '+#13#10+e.Message);
      Close;
      Application.Terminate;
      exit;
     end;
  end;

  bnRun.Enabled := true;
  bnAbort.Enabled := false;
  bnExit.Enabled := true;

  MsgClient1.IncomingPath := AppPath + 'Incoming\';
  userID := MsgClient1.UserID;
  MsgClient1.UserID := MSG_INVALID_USER_ID;
  try
    MsgClient1.Connected := True;
  except
    on e: Exception do
     begin
      ShowMessage('Error connecting to server: '+#13#10+e.Message);
      Close;
      Application.Terminate;
      exit;
     end;
  end;

  error := MsgClient1.IsUserExisting(userID);
  if (error <> MSG_COMMAND_RESULT_TRUE) and (error <> MSG_COMMAND_RESULT_FALSE) then
   begin
     MsgClient1.OnError(MsgClient1,error,-1,'Cannot check is user exisitng, UserID = '+IntToStr(userID));
     Exit;
   end;

  // register new user if not found
  if (error <> MSG_COMMAND_RESULT_TRUE) then
   begin
    FillChar(userInfo,SizeOf(userInfo),0);
    userInfo.UserID := userID;
    userInfo.UserName := 'User #'+IntToStr(userID);
    userInfo.FirstName := userInfo.UserName;
    error := MsgClient1.RegisterNewUser(userInfo);
    if (error <> MSG_COMMAND_OK) then
     begin
      MsgClient1.OnError(MsgClient1,error,-1,'Cannot register user, UserID = '+IntToStr(userID));
      Exit;
     end;
    aaWriteToLog(IntToStr(aaGetTickCount)+#9+'User #'+IntToStr(userID)+' registered and logged');
   end
  else
   begin
    MsgClient1.Active := false;
    MsgClient1.Connected := false;
    MsgClient1.UserID := userID;
    MsgClient1.Connected := True;
    if (MsgClient1.UserID <> userID) then
     begin
      MsgClient1.OnError(MsgClient1,error,-1,'Cannot connect user, UserID = '+IntToStr(userID)+', MsgClient1.UserID = '+IntToStr(MsgClient1.UserID));
      Exit;
     end;
   end;
end;

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TfmMain.bnAbortClick(Sender: TObject);
begin
  StartTime := aaGetTickCount - StartTime;
  aaWriteToLog(IntToStr(aaGetTickCount)+#9+'Test aborted');
  aaWriteToLog('Time, ms = '+#9+IntToStr(StartTime));
  Timer1.Enabled := false;
  FAbort := true;
  // abort test
  try
   ClearClients;
   MsgClient1.Connected := false;
  except
  end;
  try
   MsgServer1.Active := false;
  except
  end;
  // restart server
  try
   MsgServer1.Active := true;
   MsgClient1.Connected := true;
  except
   on e: Exception do
    begin
      ShowMessage('Error restarting to server: '+#13#10+e.Message);
      Close;
      Application.Terminate;
      exit;
    end;
  end;

  TestStarted := false;
  bnRun.Enabled := true;
  bnAbort.Enabled := false;
  bnExit.Enabled := true;

  seNumClients.Enabled := true;
  seNumRepeats.Enabled := true;
  cbSendToClient.Enabled := true;
  cbSendToServer.Enabled := true;
end;

procedure TfmMain.MsgClient1Error(Sender: TComponent; const ErrorCode,
  NativeError: Integer; const ErrorMessage: String);
begin
aaWriteToLog('==================================================================');
aaWriteToLog('Error on client !');
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage: "'+ErrorMessage+'"');
aaWriteToLog('GetTickCount = '+IntToStr(aaGetTickCount));
aaWriteToLog('==================================================================');
end;

procedure TfmMain.MsgServer1Error(Sender: TComponent; const ErrorCode,
  NativeError: Integer; const ErrorMessage: String);
begin
aaWriteToLog('==================================================================');
aaWriteToLog('Error on server !');
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage: "'+ErrorMessage+'"');
aaWriteToLog('GetTickCount = '+IntToStr(aaGetTickCount));
aaWriteToLog('==================================================================');
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (bnAbort.Enabled) then
  bnAbortClick(Sender);
 MsgClient1.Connected := False;
 MsgServer1.Active := False;
 Application.Terminate;
end;

procedure TfmMain.bnRunClick(Sender: TObject);
begin
  reMessages.Lines.Clear;
  reLog.Lines.Clear;
  FAbort := false;
  NumClients := seNumClients.Value;
  NumRepeats := seNumRepeats.Value;
  SendToClient := cbSendToClient.Checked;
  SendToServer := cbSendToServer.Checked;
  NumClientMsg := 0;
  NumServerMsg := 0;
  TestMsg := reTestMessage.Text;

  TestStarted := true;
  bnRun.Enabled := false;
  bnAbort.Enabled := true;
  bnExit.Enabled := true;

  seNumClients.Enabled := false;
  seNumRepeats.Enabled := false;
  cbSendToClient.Enabled := false;
  cbSendToServer.Enabled := false;
  reTestMessage.Enabled := false;
  gbTextMessage.Caption := ' Test Message: '+IntToStr(Length(TestMsg))+' bytes ';

  StartTime := aaGetTickCount;
  aaWriteToLog(#13#10+IntToStr(StartTime)+#9+'Test started');
  Timer1.Enabled := true;
  try
   RunTest;
  finally
    Timer1Timer(Self);
    StartTime := aaGetTickCount - StartTime;
    Timer1.Enabled := false;
    aaWriteToLog(IntToStr(aaGetTickCount)+#9+'Test finished');
    aaWriteToLog('Time, ms = '+#9+IntToStr(StartTime)+#13#10);
    bnRun.Enabled := true;
    bnAbort.Enabled := false;
    bnExit.Enabled := true;

    seNumClients.Enabled := true;
    seNumRepeats.Enabled := true;
    cbSendToClient.Enabled := true;
    cbSendToServer.Enabled := true;
    reTestMessage.Enabled := true;
  end;
end;

procedure TfmMain.MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
var dt: TDisplayThread;
    s:  String;
begin
  Inc(NumClientMsg);
  if (Text <> TestMsg) then
   begin
    s := 'Error receiving message on client: message text is not equal to original: '
         +#13#10+'Text length = '+IntToStr(Length(Text))
         +'TestMsg length = '+IntToStr(Length(TestMsg));
    dt := TDisplayThread.Create(true);
    dt.Text := s;
    dt.RichEdit := reLog;
    dt.Resume;
   end;
  if (DisplayMessages) then
   begin
    dt := TDisplayThread.Create(true);
    dt.Text := 'User #'+IntToStr(FromUserID)+#9+DateTimeToStr(SendingDate)+':'+#13#10+Text;
    dt.RichEdit := reMessages;
    dt.Resume;
   end;
end;

procedure TfmMain.MsgClient1AfterLogon(Sender: TObject);
begin
  aaWriteToLog(IntToStr(aaGetTickCount)+#9+'User #'+IntToStr(MsgClient1.UserID)+' logged');
end;

procedure TfmMain.ClearClients;
//var i: Integer;
begin
{
  if (FClients <> nil) then
   begin
     for i := 0 to Length(FClients)-1 do
      if (FClients[i] <> nil) then
       try
        FClients[i].Free;
        FClients[i] := nil;
       except
       end;
     FClients := nil;
   end;
}   
end;

procedure TfmMain.RunTest;
var i:            Integer;
    s:            String;
    ClientThread: TClientThread;
    bStop:        Boolean;

begin
  FThreadCount := NumClients;
  ClearClients;
  try
//    SetLength(FClients,NumClients);
    clbClients.Clear;
    for i := 1 to NumClients do
     begin
      s := 'User #'+IntToStr(StartUserID+(i-1));
      clbClients.Items.Add(s);
     end;

    for i := 1 to NumClients do
     begin
      ClientThread := TClientThread.Create(True);
      ClientThread.Priority := tpNormal;
      ClientThread.UserID := StartUserID+(i-1);
      ClientThread.FirstUserID := MsgClient1.UserID;
      ClientThread.ServerID := MsgServer1.ServerID;
      ClientThread.SendTextCount := NumRepeats;
      ClientThread.TextMessage := TestMsg;
      ClientThread.ConnnectParamsEditor := MsgClient1.ConnectionParams;
      ClientThread.SendToClient := SendToClient;
      ClientThread.SendToServer := SendToServer;
//      FClients[i] := ClientThread;
      ClientThread.Resume;
      Application.ProcessMessages;
     end;
    bStop := false;
    while (not bStop) do
     begin
      sleep(Timer1.Interval+1);
      Application.ProcessMessages;
      bStop := (FThreadCount <= 0);
      if (bStop) then
       begin
        if (SendToClient) then
         bStop := (NumClientMsg = (NumClients * NumRepeats));
       end;
      if (bStop) then
       begin
        if (SendToServer) then
         bStop := (NumServerMsg = (NumClients * NumRepeats));
       end;
     end;
  finally
    ClearClients;
  end;
end;

procedure TfmMain.Timer1Timer(Sender: TObject);
var x: Extended;
begin
  x := (aaGetTickCount - StartTime) / 1000.0;
  lbClientMessages.Caption := 'Client: '+IntToStr(NumClientMsg);
  lbServerMessages.Caption := 'Server: '+IntToStr(NumServerMsg);
  lbElapsedTime.Caption := 'Time: '+FormatFloat('0.000',x);
  gbClientThreads.Caption := ' Client Threads: '+IntToStr(FThreadCount)+' ';
  Application.ProcessMessages;
end;

procedure TfmMain.MsgServer1ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
var dt: TDisplayThread;  
begin
  Inc(NumServerMsg);
  if (DisplayMessages) then
   begin
    dt := TDisplayThread.Create(true);
    dt.Text := 'User #'+IntToStr(FromUserID)+#9+DateTimeToStr(SendingDate)+':'+#13#10+Text;
    dt.RichEdit := reMessages;
    dt.Resume;
   end;
end;

procedure TfmMain.StartThread(UserID: Integer);
var
    i: Integer;
begin
  i := UserID-StartUserID;
  clbClients.Checked[i] := true;
end;

procedure TfmMain.FinishThread(UserID: Integer);
var
    i: Integer;
begin
  Dec(FThreadCount);
  i := UserID-StartUserID;
  clbClients.Checked[i] := false;
end;


end.
