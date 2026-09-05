unit Main;

interface


{$I .\..\..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ExtCtrls, Grids, ComCtrls,
  MsgServer, MsgComBase, MsgConst, MsgTypes;

const
  Guest = ' - GUEST -';

type
  TForm1 = class(TForm)
    Pages: TPageControl;
    Control: TTabSheet;
    Send: TTabSheet;
    Incoming: TTabSheet;
    ServerStart: TButton;
    ServerStop: TButton;
    Label1: TLabel;
    MsgServer1: TMsgServer;
    Label10: TLabel;
    sgConnectedUsers: TStringGrid;
    ServerSend: TButton;
    ServerToID: TEdit;
    ServerMsg: TRichEdit;
    Label2: TLabel;
    Label3: TLabel;
    ServerIncoming: TRichEdit;
    Sent: TTabSheet;
    Label4: TLabel;
    ServerSent: TRichEdit;
    Users: TTabSheet;
    sgAllUsers: TStringGrid;
    Label5: TLabel;
    SelectedUserID: TEdit;
    DeleteUser: TButton;
    DisconnectUser: TButton;
    Label6: TLabel;
    LocalPort: TEdit;
    Timer1: TTimer;
    GroupBox1: TGroupBox;
    cbOnTimer: TCheckBox;
    cbConnected: TCheckBox;
    UserCount: TLabel;
    OnLineCount: TLabel;
    GuestCount: TLabel;
    cbLogged: TCheckBox;
    cbRegistration: TCheckBox;
    cbInfoChanged: TCheckBox;
    Interval: TEdit;
    Label7: TLabel;
    ServerSettings: TRichEdit;
    Label8: TLabel;
    Label9: TLabel;
    LocalHost: TEdit;
    ServerID: TEdit;
    Label11: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ServerStartClick(Sender: TObject);
    procedure ServerStopClick(Sender: TObject);
    procedure MsgServer1ReceiveTextMessage(const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: AnsiString);
    procedure ServerSendClick(Sender: TObject);
    procedure MsgServer1AfterConnect(Sender: TObject);
    procedure sgConnectedUsersSelectCell(Sender: TObject; ACol,
      ARow: Integer; var CanSelect: Boolean);
    procedure MsgServer1BeforeDisconnect(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sgAllUsersSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure DisconnectUserClick(Sender: TObject);
    procedure DeleteUserClick(Sender: TObject);
    procedure FillGrids;
    procedure FillCounts;
    procedure ClearGrid(Grid: TStringGrid);
    procedure Timer1Timer(Sender: TObject);
    procedure MsgServer1AfterServerStart(Sender: TObject);
    procedure MsgServer1BeforeServerStop(Sender: TObject);
    procedure MsgServer1AfterDisconnect(Sender: TObject);
    procedure IntervalChange(Sender: TObject);
    procedure MsgServer1UserInfoChanged(const UserID: Cardinal);
    procedure MsgServer1UserRegistered(const UserID: Cardinal);
    procedure MsgServer1UserLogoff(const UserID: Cardinal);
    procedure MsgServer1UserLogon(const UserID: Cardinal);
    procedure SetParams;
    procedure GetParams;
    procedure PagesChanging(Sender: TObject; var AllowChange: Boolean);
    procedure MsgServer1ReceiveUnicodeTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: WideString);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1:            TForm1;
  IncomingMessages: String;

implementation

{$R *.dfm}


procedure TForm1.SetParams;
begin
  ServerID.Text := IntToStr(MsgServer1.ServerID);
  LocalHost.Text := MsgServer1.LocalHost;
  LocalPort.Text := IntToStr(MsgServer1.LocalPort);
end;

procedure TForm1.GetParams;
begin
  MsgServer1.ServerID := StrToInt(ServerID.Text );
  MsgServer1.ConnectionParams.LocalHost := LocalHost.Text;
  MsgServer1.ConnectionParams.LocalPort := StrToInt(LocalPort.Text);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetParams;
// grids headers
  sgConnectedUsers.ColCount := 4;
  sgConnectedUsers.RowCount := 1;
  sgConnectedUsers.ColWidths[0] := 30;
  sgConnectedUsers.ColWidths[1] := 65;
  sgConnectedUsers.ColWidths[3] := 35;
  sgConnectedUsers.ColWidths[2] := sgConnectedUsers.ClientWidth - 5 -
                          sgConnectedUsers.ColWidths[1] -
                          sgConnectedUsers.ColWidths[3] -
                          sgConnectedUsers.ColWidths[0];
  sgConnectedUsers.Cells[0,0] := 'ID';
  sgConnectedUsers.Cells[1,0] := 'Name';
  sgConnectedUsers.Cells[2,0] := 'Host';
  sgConnectedUsers.Cells[3,0] := 'Port';
  sgAllUsers.ColCount := 6;
  sgAllUsers.RowCount := 1;
  sgAllUsers.ColWidths[0] := 10;
  sgAllUsers.ColWidths[1] := 30;
  sgAllUsers.ColWidths[2] := 65;
  sgAllUsers.ColWidths[3] := 30;
  sgAllUsers.ColWidths[5] := 40;
  sgAllUsers.ColWidths[4] := sgAllUsers.ClientWidth - 5 -
                          sgAllUsers.ColWidths[0] -
                          sgAllUsers.ColWidths[1] -
                          sgAllUsers.ColWidths[2] -
                          sgAllUsers.ColWidths[3] -
                          sgAllUsers.ColWidths[5];
  sgAllUsers.Cells[0,0] := '?';
  sgAllUsers.Cells[1,0] := 'ID';
  sgAllUsers.Cells[2,0] := 'Name';
  sgAllUsers.Cells[3,0] := 'Dept';
  sgAllUsers.Cells[4,0] := 'Host';
  sgAllUsers.Cells[5,0] := 'Port';
// start server
  ServerStartClick(Sender);
//  ServerIncoming.Lines.Add(''); // work around bug with the first add
//  ServerIncoming.Lines.Clear;   // work around bug with the first add
  FillGrids;
  Pages.ActivePage := Users;
end;

procedure TForm1.ServerStartClick(Sender: TObject);
begin
  GetParams;
// start server
  MsgServer1.Active := True;
// show LocalPort
  LocalPort.Text := IntToStr(MsgServer1.ConnectionParams.LocalPort);
// disable/enable buttons
  LocalPort.Enabled := False;
  LocalHost.Enabled := False;
  ServerID.Enabled := False;
  ServerStart.Enabled := False;
  ServerStop.Enabled := True;
  DisconnectUser.Enabled := False;
  DeleteUser.Enabled := False;
end;

procedure TForm1.ServerStopClick(Sender: TObject);
begin
// stop server
  MsgServer1.Active := False;
// disable/enable buttons
  LocalPort.Enabled := True;
  LocalHost.Enabled := True;
  ServerID.Enabled := True;
  ServerStart.Enabled := True;
  ServerStop.Enabled := False;
  DisconnectUser.Enabled := False;
  DeleteUser.Enabled := False;
// clear form
  ClearGrid(sgConnectedUsers);
  ClearGrid(sgallUsers);
  ServerToID.Text := '';
end;

procedure TForm1.MsgServer1ReceiveTextMessage(const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: AnsiString);
var
  str:          AnsiString;
  UserInfo:     TMsgUserInfo;
begin
{
 while not Canvas.TryLock do
   sleep(0);
}
 try
  str := '#' + IntToStr(FromUserID) + ', ' + DateTimeToStr(SendingDate) + ':';
  try
   UserInfo := MsgServer1.GetUserInfo(FromUserID);
   if (UserInfo.UserID <> MSG_INVALID_USER_ID) then
    str := UserInfo.UserName + ' ' + str;
  except
    str := 'Unregistered User ID = '+IntToStr(FromUserID)+' '+ str;
  end;
  IncomingMessages := IncomingMessages+str+#13;
  IncomingMessages := IncomingMessages+Text+#13;
  if Pages.ActivePage = Incoming then  // fixed the bug with non-active page
   begin
    ServerIncoming.Lines.Add(str);
    ServerIncoming.Lines.Add(Text);
   end;
{
 finally
  Canvas.Unlock;
}
 except
 end;
end;

procedure TForm1.MsgServer1ReceiveUnicodeTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: WideString);
var
  str:          WideString;
  UserInfo:     TMsgUserInfo;
begin
{
 while not Canvas.TryLock do
   sleep(0);
}
 try
  str := '#' + IntToStr(FromUserID) + ', ' + DateTimeToStr(SendingDate) + ':';
  try
   UserInfo := MsgServer1.GetUserInfo(FromUserID);
   if (UserInfo.UserID <> MSG_INVALID_USER_ID) then
    str := UserInfo.UserName + ' ' + str;
  except
    str := 'Unregistered User ID = '+IntToStr(FromUserID)+' '+ str;
  end;
  IncomingMessages := IncomingMessages+str+#13;
  IncomingMessages := IncomingMessages+Text+#13;
  if Pages.ActivePage = Incoming then  // fixed the bug with non-active page
   begin
    ServerIncoming.Lines.Add(str);
    ServerIncoming.Lines.Add(Text);
   end;
{
 finally
  Canvas.Unlock;
}
 except
 end;
end;

procedure TForm1.ServerSendClick(Sender: TObject);
var
  str:          String;
  UserInfo:     TMsgUserInfo;
begin
  if ServerToID.Text = '' then
    Exit;
  MsgServer1.SendMessage(Cardinal(StrToInt(ServerToID.Text)), ServerMsg.Text);
  str := '#' + ServerToID.Text + ', ' + TimeToStr(Time) + ':';
  UserInfo := MsgServer1.GetUserInfo(StrToInt(ServerToID.Text));
  if UserInfo.UserName <> '' then
    str := UserInfo.UserName + ' ' + str;
  ServerSent.Lines.Add(str);
  ServerSent.Lines.Add(ServerMsg.Text);
  ServerMsg.Text := '';
end;

procedure TForm1.sgConnectedUsersSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  if (ARow <= 0) or (ARow >= sgConnectedUsers.RowCount) then
    Exit;
  ServerToID.Text := '';
  if (sgConnectedUsers.Cells[0,ARow] <> '') then
   begin
    if (sgConnectedUsers.Cells[0,ARow] <> IntToStr(MSG_INVALID_USER_ID)) then
     begin
       ServerSend.Enabled := True;
       ServerToID.Text := sgConnectedUsers.Cells[0,ARow];
     end
    else
     begin
       ServerSend.Enabled := False;
     end;
   end;
end;

procedure TForm1.sgAllUsersSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  if (ARow <= 0) or (ARow >= sgAllUsers.RowCount) then
    Exit;
  SelectedUserID.Text := '';
  if (sgAllUsers.Cells[1,ARow] <> '') then
   begin
    SelectedUserID.Text := sgAllUsers.Cells[1,ARow];
    DisconnectUser.Enabled := (sgAllUsers.Cells[0,ARow] = '+');
    if (sgAllUsers.Cells[1,ARow] <> IntToStr(MSG_INVALID_USER_ID)) then
     DeleteUser.Enabled := True
    else
     begin
      DisconnectUser.Enabled := False;
      DeleteUser.Enabled := False;
     end;
   end;
end;

procedure TForm1.MsgServer1BeforeDisconnect(Sender: TObject);
begin
  ServerToID.Text := '';
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MsgServer1.Active := False;
end;

procedure TForm1.DisconnectUserClick(Sender: TObject);
begin
  MsgServer1.DisconnectUser(Cardinal(StrToInt(SelectedUserID.Text)));
  DisconnectUser.Enabled := False;
  DeleteUser.Enabled := True;
  FillGrids;
end;

procedure TForm1.DeleteUserClick(Sender: TObject);
var
  UID:        Cardinal;
begin
  UID := Cardinal(StrToInt(SelectedUserID.Text));
  if MsgServer1.IsUserConnected(UID) then
    MsgServer1.DisconnectUser(StrToInt(SelectedUserID.Text));
  if MsgServer1.IsUserExisting(UID) then
    MsgServer1.DeleteUser(UID);
  DeleteUser.Enabled := False;
  DisconnectUser.Enabled := False;
  FillGrids;
end;


procedure TForm1.FillCounts;
begin
{
  while not Canvas.TryLock do
    sleep(0);
}
  try
    UserCount.Caption   := 'Users:   '+IntToStr(MsgServer1.UsersCount);
    OnLineCount.Caption := 'OnLine: '+IntToStr(MsgServer1.OnLineUsersCount);
    GuestCount.Caption  := 'Guests: '+IntToStr(MsgServer1.GuestsCount);
{
  finally
   Canvas.Unlock;
}
  except
  end;
end;


procedure TForm1.FillGrids;
var Users:    TMsgUserInfoArray;
    i,na,nc:  Integer;
    Clients:  TMsgClientInfoArray;
    id1,id2:  String;
    gr1,gr2:  TGridRect;
begin
{
  while not Canvas.TryLock do
    sleep(0);
}
  try
    MsgServer1.GetUsers(Users);
    MsgServer1.GetClients(Clients);
    FillCounts;
    id1 := ServerToID.Text;
    id2 := SelectedUserID.Text;
    gr1 := sgConnectedUsers.Selection;
    gr2 := sgAllUsers.Selection;
    try
      ClearGrid(sgAllUsers);
      ClearGrid(sgConnectedUsers);
      na := 0;
      nc := 0;
      for i := Low(Users) to High(Users) do
       begin
        if (Users[i].Status = msgOnLine) then
         begin
          Inc(nc);
          if (nc >= sgConnectedUsers.RowCount) then
           sgConnectedUsers.RowCount := nc+1;
          sgConnectedUsers.Cells[0,nc] := IntToStr(Users[i].UserID);
          sgConnectedUsers.Cells[1,nc] := Users[i].UserName;
          sgConnectedUsers.Cells[2,nc] := Users[i].Host;
          sgConnectedUsers.Cells[3,nc] := IntToStr(Users[i].Port);
         end;
        Inc(na);
        if (na >= sgAllUsers.RowCount) then
         sgAllUsers.RowCount := na+1;
        if (Users[i].Status = msgOnLine) then
         sgAllUsers.Cells[0,na] := '+'
        else
         sgAllUsers.Cells[0,na] := '-';
        sgAllUsers.Cells[1,na] := IntToStr(Users[i].UserID);
        sgAllUsers.Cells[2,na] := Users[i].UserName;
        sgAllUsers.Cells[3,na] := Users[i].Department;
        sgAllUsers.Cells[4,na] := Users[i].Host;
        sgAllUsers.Cells[5,na] := IntToStr(Users[i].Port);
       end;
      for i := Low(Clients) to High(Clients) do
       if (Clients[i].UserID = MSG_INVALID_USER_ID) then
        begin
          Inc(nc);
          if (nc >= sgConnectedUsers.RowCount) then
           sgConnectedUsers.RowCount := nc+1;
          sgConnectedUsers.Cells[0,nc] := IntToStr(MSG_INVALID_USER_ID);
          sgConnectedUsers.Cells[1,nc] := Guest;
          sgConnectedUsers.Cells[2,nc] := Clients[i].Host;
          sgConnectedUsers.Cells[3,nc] := IntToStr(Clients[i].Port);
          Inc(na);
          if (na >= sgAllUsers.RowCount) then
           sgAllUsers.RowCount := na+1;
          sgAllUsers.Cells[0,na] := '+';
          sgAllUsers.Cells[1,na] := IntToStr(MSG_INVALID_USER_ID);
          sgAllUsers.Cells[2,na] := Guest;
          sgAllUsers.Cells[3,na] := '';
          sgAllUsers.Cells[4,na] := Clients[i].Host;
          sgAllUsers.Cells[5,na] := IntToStr(Clients[i].Port);
        end;
     for i := 1 to sgAllUsers.RowCount-1 do
      if (sgAllUsers.Cells[1,i] = id2) then
       begin
        gr2.Top := i;
        gr2.Bottom := i;
        sgAllUsers.Selection := gr2;
        SelectedUserID.Text := id2;
        break;
       end;
     for i := 1 to sgConnectedUsers.RowCount-1 do
      if (sgConnectedUsers.Cells[0,i] = id1) then
       begin
        gr1.Top := i;
        gr1.Bottom := i;
        sgConnectedUsers.Selection := gr1;
        ServerToID.Text := id1;
        break;
       end;
    finally
      SetLength(Users,0);
      SetLength(Clients,0);
    end;
{
  finally
   Canvas.Unlock;
}
  except
  end;
end; // FillGrids


procedure TForm1.ClearGrid(Grid: TStringGrid);
var i: Integer;
begin
  Grid.RowCount := 2;
  Grid.FixedRows := 1;
  for i := 0 to Grid.ColCount-1 do
   Grid.Cells[i,1] := '';
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  FillCounts;
  if cbOnTimer.Checked then
    FillGrids;
end;

procedure TForm1.MsgServer1AfterServerStart(Sender: TObject);
begin
  Timer1.Enabled := True;
  ServerSettings.Lines.Add('Version: '+MsgServer1.CurrentVersion);
  ServerSettings.Lines.Add('Data path: '+MsgServer1.DataPath);
  ServerSettings.Lines.Add('AllowFiles: '+BoolToStr(MsgServer1.AllowFiles));
  ServerSettings.Lines.Add('============================================');
  ServerSettings.Lines.Add('Network settings:');
  ServerSettings.Lines.Add('----------------------------------------------------------------------------------------');
  ServerSettings.Lines.Add('PacketSize: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.PacketSize));
  ServerSettings.Lines.Add('PingClients: '+BoolToStr(MsgServer1.ConnectionParams.NetworkSettings.PingClients));
  ServerSettings.Lines.Add('WaitForPingAnswer: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.WaitForPingAnswer));
  ServerSettings.Lines.Add('ServerPingSleep: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerPingSleep));
  ServerSettings.Lines.Add('ConnectionParamsTunning: '+BoolToStr(MsgServer1.ConnectionParams.NetworkSettings.ConnectionParamsTunning));
  ServerSettings.Lines.Add('TestPacketCount: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.TestPacketCount));
  ServerSettings.Lines.Add('DisconnectRetryCount: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.DisconnectRetryCount));
  ServerSettings.Lines.Add('DisconnectDelay: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.DisconnectDelay));
  ServerSettings.Lines.Add('ServerReceiveTimeOut: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerReceiveTimeOut));
  ServerSettings.Lines.Add('ServerReceiveSleep: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerReceiveSleep));
  ServerSettings.Lines.Add('MinServerSendTimeOut: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.MinServerSendTimeOut));
  ServerSettings.Lines.Add('ServerSendTimeOut: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerSendTimeOut));
  ServerSettings.Lines.Add('ServerWaitForSendSleep: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerWaitForSendSleep));
  ServerSettings.Lines.Add('ServerResendDelay: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerResendDelay));
  ServerSettings.Lines.Add('ServerRequestDelay: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerRequestDelay));
  ServerSettings.Lines.Add('WaitForMessagesSend: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.WaitForMessagesSend));
  ServerSettings.Lines.Add('WaitForServerSessionThreadTimeOut: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.WaitForServerSessionThreadTimeOut));
  ServerSettings.Lines.Add('ServerThreadsTerminateDelay: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerThreadsTerminateDelay));
  ServerSettings.Lines.Add('ServerSessionTerminatorSleep: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.ServerSessionTerminatorSleep));
  ServerSettings.Lines.Add('MaxThreadCount: '+IntToStr(MsgServer1.ConnectionParams.NetworkSettings.MaxThreadCount));
  ServerSettings.Lines.Add('============================================');
  ServerSettings.Lines.Add('Encryption settings:');
  ServerSettings.Lines.Add('----------------------------------------------------------------------------------------');
  ServerSettings.Lines.Add('CryptoAlgorithm: '+IntToStr(Integer(MsgServer1.ConnectionParams.CryptoParams.CryptoAlgorithm)));
  ServerSettings.Lines.Add('CryptoMode: '+IntToStr(Integer(MsgServer1.ConnectionParams.CryptoParams.CryptoMode)));
  ServerSettings.Lines.Add('Password: '+MsgServer1.ConnectionParams.CryptoParams.Password);
  ServerSettings.Lines.Add('============================================');
end;

procedure TForm1.MsgServer1BeforeServerStop(Sender: TObject);
begin
  Timer1.Enabled := False;
  ServerSettings.Text := '';
end;

procedure TForm1.MsgServer1AfterConnect(Sender: TObject);
begin
  FillCounts;
  if cbConnected.Checked then
    FillGrids;
end;

procedure TForm1.MsgServer1AfterDisconnect(Sender: TObject);
begin
  FillCounts;
  if cbConnected.Checked then
    FillGrids;
end;

procedure TForm1.MsgServer1UserInfoChanged(const UserID: Cardinal);
begin
  FillCounts;
  if cbInfoChanged.Checked then
    FillGrids;
end;

procedure TForm1.MsgServer1UserRegistered(const UserID: Cardinal);
begin
  FillCounts;
  if cbRegistration.Checked then
    FillGrids;
end;

procedure TForm1.MsgServer1UserLogoff(const UserID: Cardinal);
begin
  FillCounts;
  if cbLogged.Checked then
    FillGrids;
end;

procedure TForm1.MsgServer1UserLogon(const UserID: Cardinal);
begin
  FillCounts;
  if cbLogged.Checked then
    FillGrids;
end;

procedure TForm1.IntervalChange(Sender: TObject);
begin
  if cbOnTimer.Checked then
   begin
    Timer1.Interval := StrToIntDef(Interval.Text,5000);
    Interval.Text := IntToStr(Timer1.Interval);
   end;
end;

procedure TForm1.PagesChanging(Sender: TObject; var AllowChange: Boolean);
begin
// fixed the bug with non-active page
  ServerIncoming.Lines.Clear;
  ServerIncoming.Lines.Add(IncomingMessages);
end;

end.
