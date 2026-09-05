unit uMain;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ExtCtrls, Grids, CheckLst, IniFiles,
  MsgClient, MsgComBase, MsgConst, MsgTypes, MsgDatabase,
  MsgCriticalSection,
  {$IFDEF DEBUG_LOG}
  MsgDebug,
  {$ENDIF}
  ComCtrls, uStart, uRegister, uLogin, uFind, uHistory,
  MsgDatabaseMySQLDAC, MsgDatabaseTempTableSQLMemTable, mySQLDbTables;

type
  TfmMain = class(TForm)
    gbContacts: TGroupBox;
    pContactsControl: TPanel;
    bnFind: TButton;
    bnHistory: TButton;
    bnSend: TButton;
    Splitter1: TSplitter;
    pMain: TPanel;
    gbMessageDialog: TGroupBox;
    GroupBox1: TGroupBox;
    Splitter2: TSplitter;
    reSend: TRichEdit;
    reView: TRichEdit;
    lbContacts: TCheckListBox;
    Timer1: TTimer;
    MsgClient1: TMsgClient;
    MsgDatabaseMySQLDAC1: TMsgDatabaseMySQLDAC;
    MsgTempTableSQLMemTable1: TMsgTempTableSQLMemTable;
    mySQLDatabase1: TmySQLDatabase;
    procedure FormCreate(Sender: TObject);
    procedure bnFindClick(Sender: TObject);
    procedure bnSendClick(Sender: TObject);
    procedure lbContactsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbContactsClick(Sender: TObject);
    procedure MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure MsgClient1UserOffLine(const UserID: Cardinal);
    procedure MsgClient1UserOnLine(const UserID: Cardinal);
    procedure bnHistoryClick(Sender: TObject);
    procedure MsgClient1ReceiveUnicodeTextMessage(
      const FromUserID: Cardinal; const SendingDate,
      DeliveryDate: TDateTime; const Text: WideString);
  private
    { Private declarations }
    FConfigFileName:  String;
    FUserInfo:        TMsgUserInfo;
    FTemp:            TStringList;
    FCSect:           TRTLCriticalSection;
    FStarting:        Boolean;
  public
    { Public declarations }
    procedure LoadSettings;
    procedure SaveSettings;
    procedure DoLogin;
    procedure DoRegister;
    function Login: Boolean;
    procedure FillContacts;
    procedure ClearContacts;
    procedure Lock;
    procedure Unlock;
  end;

  TClientContact = class (TObject)
   private
    FContactInfo: TMsgContactInfo;
   public
    property ContactInfo: TMsgContactInfo read FContactInfo write FContactInfo;
  end;

  TClientDisplayThread = class (TThread)
   private
    FText:        AnsiString;
    FUnicodeText: WideString;
   public
     constructor Create(text: AnsiString); overload;
     constructor Create(text: WideString); overload;
     procedure DisplayMessage;
     procedure Execute; override;
     property Text: AnsiString read FText write FText;
     property UnicodeText: WideString read FUnicodeText write FUnicodeText;
  end;

var
  fmMain:          TfmMain;

implementation

{$R *.dfm}


procedure TfmMain.FormCreate(Sender: TObject);
begin
  InitializeCriticalSection(FCSect);
  FTemp := TStringList.Create;
  FStarting := True;
  {$IFDEF D5H}
  FConfigFileName := IncludeTrailingBackslash(
                      ExtractFilePath(Application.ExeName))+'Client.ini';
  {$ELSE}
  FConfigFileName := ExtractFilePath(Application.ExeName)+'Client.ini';
  {$ENDIF}
  MsgClient1.UserID := MSG_INVALID_USER_ID;
  if (FileExists(FConfigFileName)) then
   LoadSettings;
end; // FormCreate

procedure TfmMain.LoadSettings;
var IniFile: TIniFile;
begin
 IniFile := TIniFile.Create(FConfigFileName);
 try
   MsgClient1.UserID := Cardinal(IniFile.ReadInteger('Client Settings','UserID',Integer(MsgClient1.UserID)));
   MsgClient1.Password := IniFile.ReadString('Client Settings','Password',MsgClient1.Password);
   MsgClient1.ConnectionParams.LocalPort := IniFile.ReadInteger('Client Settings','Port',MsgClient1.ConnectionParams.LocalPort);
   MsgClient1.ConnectionParams.RemoteHost := IniFile.ReadString('Server Settings','Host',MsgClient1.ConnectionParams.RemoteHost);
   MsgClient1.ConnectionParams.RemotePort := IniFile.ReadInteger('Server Settings','Port',MsgClient1.ConnectionParams.RemotePort);
 finally
   IniFile.Free;
 end;
end;

procedure TfmMain.SaveSettings;
var IniFile: TIniFile;
begin
 IniFile := TIniFile.Create(FConfigFileName);
 try
   IniFile.WriteInteger('Client Settings','UserID',MsgClient1.UserID);
   IniFile.WriteString('Client Settings','Password',MsgClient1.Password);
   IniFile.WriteInteger('Client Settings','Port',MsgClient1.ConnectionParams.LocalPort);
   IniFile.WriteString('Server Settings','Host',MsgClient1.ConnectionParams.RemoteHost);
   IniFile.WriteInteger('Server Settings','Port',MsgClient1.ConnectionParams.RemotePort);
 finally
   IniFile.Free;
 end;
end;

procedure TfmMain.bnFindClick(Sender: TObject);
begin
  if (fmFind.ShowModal <> mrCancel) then
   begin
    // add to contacts
    FillContacts;
   end;
end;

procedure TfmMain.DoLogin;
begin
  fmLogin.ShowModal;
end;


procedure TfmMain.DoRegister;
begin
  fmRegister.ShowModal;
end;


function TfmMain.Login: Boolean;
begin
  try
    MsgClient1.Connected := True;
    MsgClient1.GetUserInfo(MsgClient1.UserID,FUserInfo);
  except
   on e: Exception do
    begin
     Result := False;
     MsgClient1.Disconnect;
     if (Pos('60095',e.Message) > 0) then
      ShowMessage('Error - user does not exists')
     else
     if (Pos('60096',e.Message) > 0) then
      ShowMessage('Error - invalid password')
     else
      ShowMessage('Error - '+e.Message);
     Exit;
    end;
  end;
  Result := MsgClient1.Connected;
  if (Result) then
   begin
    SaveSettings;
    gbContacts.Caption := ' UserID #'+IntToStr(Integer(MsgClient1.UserID))+' Contacts: ';
    FillContacts;
   end;
end;


procedure TfmMain.FillContacts;
var i:        Integer;
begin
  ClearContacts;
  Lock;
  try
   bnSend.Enabled := False;
   for i := 0 to MsgClient1.ContactCount-1 do
     lbContacts.Items.Add(
      MsgClient1.GetContactDisplayName(MsgClient1.Contacts[i]));
   lbContacts.Repaint;
  finally
   Unlock;
  end;
end;

procedure TfmMain.ClearContacts;
begin
  Lock;
  try
    lbContacts.Clear;
  finally
    Unlock;
  end;
end;


procedure TfmMain.lbContactsDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
    col: TColor;
begin
  col := clRed;
  if (Index < MsgClient1.ContactCount) then
   if (MsgClient1.Contacts[Index].UserInfo.Status = msgOnline) then
     col := clGreen;
  lbContacts.Canvas.Font.Color := col;
  lbContacts.Canvas.Brush.Color := clWindow;
  lbContacts.Canvas.FillRect(Rect);
  lbContacts.Canvas.TextOut(Rect.Left+1,
    Rect.Top+1,lbContacts.Items[Index]);
end;

procedure TfmMain.lbContactsClick(Sender: TObject);
var i: Integer;
begin
  bnSend.Enabled := False;
  for i := 0 to lbContacts.Items.Count-1 do
   if (lbContacts.Checked[i]) then
    begin
     bnSend.Enabled := True;
     break;
    end;
end;

procedure TfmMain.MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
var Capt: AnsiString;
    i: Integer;
    dt: TClientDisplayThread;
begin
  Capt := 'User #'+IntToStr(FromUserID);
  for i := 0 to MsgClient1.ContactCount-1 do
   if (MsgClient1.Contacts[i].UserInfo.UserID = FromUserID) then
    begin
     Capt := MsgClient1.GetContactDisplayName(MsgClient1.Contacts[i]);
     break;
    end;
  Capt := Capt+' '+TimeToStr(SendingDate)+' : '+#13#10+Text;
  if (FStarting) then
   begin
    // store messages to temp string list to avoid hanging of the reView
    FTemp.Add(Capt);
   end
  else
   begin
    dt := TClientDisplayThread.Create(True);
    dt.Text := Capt;
    dt.Resume;
   end;
end;


procedure TfmMain.bnSendClick(Sender: TObject);
var Code,i:   Integer;
    UserID:   Cardinal;
    Capt,s:   String;
    dt:       TDateTime;
    cdt:      TClientDisplayThread;
begin
  bnSend.Enabled := False;
  dt := Now;
  Lock;
  try
   s := reSend.Text;
   for i := 0 to lbContacts.Items.Count-1 do
    if (lbContacts.Checked[i]) then
     begin
      UserID := MsgClient1.Contacts[i].UserInfo.UserID;
      Code := MsgClient1.SendMessage(UserID,s,True);
      if (i = 0) then
       dt := Now;
      if (Code <> MSG_COMMAND_OK) then
       ShowMessage('Cannot send message to user # '+
         IntToStr(UserID)+'. Error code = '+IntToStr(Code));
     end;
    reSend.Clear;
    Capt := FUserInfo.UserName+' '+TimeToStr(dt)+' : '+#13#10+s;
    cdt := TClientDisplayThread.Create(True);
    cdt.Text := Capt;
    cdt.Resume;
  finally
    bnSend.Enabled := True;
    Unlock;
  end;
end;


procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DeleteCriticalSection(FCSect);
  FTemp.Free;
end;

procedure TfmMain.Lock;
begin
  EnterCriticalSection(FCSect);
end;

procedure TfmMain.Unlock;
begin
  LeaveCriticalSection(FCSect);
end;

procedure TfmMain.FormActivate(Sender: TObject);
begin
 if (MsgClient1.Connected) then
  Exit;
   while (not MsgClient1.Connected) do
     begin
       if (MsgClient1.UserID <> MSG_INVALID_USER_ID) then
         begin
           if (Login) then
            break
           else
            DoLogin;
           if (not MsgClient1.Connected) then
            MsgClient1.UserID := MSG_INVALID_USER_ID;
           continue;
         end;
       if (fmStart.ShowModal <> mrOK) then
        begin
         Application.Terminate;
         break;
        end
       else
        begin
         if (fmStart.rgAction.ItemIndex = 0) then
          DoRegister
         else
          DoLogin;
         if (not MsgClient1.Connected) then
          MsgClient1.UserID := MSG_INVALID_USER_ID;
        end;
     end;
end;

procedure TfmMain.Timer1Timer(Sender: TObject);
var 
    dt: TClientDisplayThread;
begin
 if (FTemp.Count <> 0) then
  begin
   // copy messages from temp string list to reView
   dt := TClientDisplayThread.Create(true);
   dt.Text := FTemp.Text;
   dt.Resume;
   FTemp.Clear;
   Timer1.Enabled := False;
   FStarting := False;
  end;
end;

procedure TfmMain.MsgClient1UserOffLine(const UserID: Cardinal);
begin
  FillContacts;
end;

procedure TfmMain.MsgClient1UserOnLine(const UserID: Cardinal);
begin
  FillContacts;
end;

procedure TfmMain.bnHistoryClick(Sender: TObject);
begin
  fmHistory.ShowModal;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TClientDisplayThread
//
////////////////////////////////////////////////////////////////////////////////


constructor TClientDisplayThread.Create(text: AnsiString);
begin
  inherited Create(True);
  FText := text;
  FUnicodeText := '';
end;

constructor TClientDisplayThread.Create(text: WideString);
begin
  inherited Create(True);
  FText := '';
  FUnicodeText := text;
end;

procedure TClientDisplayThread.DisplayMessage;
begin
  if (FText = '') then
   fmMain.reView.Lines.Add(FUnicodeText)
  else
   fmMain.reView.Lines.Add(FText);
end;

procedure TClientDisplayThread.Execute;
begin
  Synchronize(DisplayMessage);
end;

procedure TfmMain.MsgClient1ReceiveUnicodeTextMessage(
  const FromUserID: Cardinal; const SendingDate, DeliveryDate: TDateTime;
  const Text: WideString);
var Capt: WideString;
    i: Integer;
    dt: TClientDisplayThread;
begin
  Capt := 'User #'+IntToStr(FromUserID);
  for i := 0 to MsgClient1.ContactCount-1 do
   if (MsgClient1.Contacts[i].UserInfo.UserID = FromUserID) then
    begin
     Capt := MsgClient1.GetContactDisplayName(MsgClient1.Contacts[i]);
     break;
    end;
  Capt := Capt+' '+TimeToStr(SendingDate)+' : '+#13#10+Text;
  if (FStarting) then
   begin
    // store messages to temp string list to avoid hanging of the reView
    FTemp.Add(Capt);
   end
  else
   begin
    dt := TClientDisplayThread.Create(True);
    dt.UnicodeText := Capt;
    dt.Resume;
   end;
end;

end.
