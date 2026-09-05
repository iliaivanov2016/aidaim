unit uMain;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ExtCtrls, Grids, ComCtrls,
  MsgServer, MsgComBase, MsgConst, MsgTypes, MsgDatabase,
  MsgDatabaseTempTableSQLMemTable, DBTables, MsgDatabaseParadox;

const
  Guest = ' - GUEST -';

type
  TfmMain = class(TForm)
    Pages: TPageControl;
    Control: TTabSheet;
    Send: TTabSheet;
    Incoming: TTabSheet;
    ServerStart: TButton;
    ServerStop: TButton;
    Label1: TLabel;
    Label10: TLabel;
    sgConnectedUsers: TStringGrid;
    ServerSend: TButton;
    ServerToID: TEdit;
    ServerMsg: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    ServerIncoming: TMemo;
    Sent: TTabSheet;
    Label4: TLabel;
    ServerSent: TMemo;
    Users: TTabSheet;
    sgAllUsers: TStringGrid;
    Label5: TLabel;
    SelectedUserID: TEdit;
    DeleteUser: TButton;
    DisconnectUser: TButton;
    Label6: TLabel;
    LocalPort: TEdit;
    Database1: TDatabase;
    MsgTempTableSQLMemTable1: TMsgTempTableSQLMemTable;
    MsgServer1: TMsgServer;
    Timer1: TTimer;
    MsgDatabaseParadox1: TMsgDatabaseParadox;
    procedure FormCreate(Sender: TObject);
    procedure ServerStartClick(Sender: TObject);
    procedure ServerStopClick(Sender: TObject);
    procedure MsgServer1ReceiveTextMessage(const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: String);
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
    procedure ClearGrid(Grid: TStringGrid);
    procedure Timer1Timer(Sender: TObject);
    procedure MsgServer1AfterServerStart(Sender: TObject);
    procedure MsgServer1BeforeServerStop(Sender: TObject);
    procedure MsgServer1AfterDisconnect(Sender: TObject);
    procedure MsgServer1ReceiveUnicodeTextMessage(
      const FromUserID: Cardinal; const SendingDate,
      DeliveryDate: TDateTime; const Text: WideString);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TServerDisplayThread = class (TThread)
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
  LocalPort.Text := IntToStr(MsgServer1.ConnectionParams.LocalPort);
// grids headers
  sgConnectedUsers.ColCount := 4;
  sgConnectedUsers.RowCount := 1;
  sgConnectedUsers.ColWidths[0] := 20;
  sgConnectedUsers.ColWidths[2] := 60;
  sgConnectedUsers.ColWidths[3] := 40;
  sgConnectedUsers.ColWidths[1] := sgConnectedUsers.ClientWidth -
                          sgConnectedUsers.ColWidths[3] -
                          sgConnectedUsers.ColWidths[2] -
                          sgConnectedUsers.ColWidths[0];
  sgConnectedUsers.Cells[0,0] := 'ID';
  sgConnectedUsers.Cells[1,0] := 'Name';
  sgConnectedUsers.Cells[2,0] := 'Host';
  sgConnectedUsers.Cells[3,0] := 'Port';
  sgAllUsers.ColCount := 6;
  sgAllUsers.RowCount := 1;
  sgAllUsers.ColWidths[0] := 10;
  sgAllUsers.ColWidths[1] := 40;
  sgAllUsers.ColWidths[3] := 40;
  sgAllUsers.ColWidths[4] := 60;
  sgAllUsers.ColWidths[5] := 40;
  sgAllUsers.ColWidths[2] := sgAllUsers.ClientWidth-
                          sgAllUsers.ColWidths[0] -
                          sgAllUsers.ColWidths[1] -
                          sgAllUsers.ColWidths[3] -
                          sgAllUsers.ColWidths[4] -
                          sgAllUsers.ColWidths[5];
  sgAllUsers.Cells[0,0] := '?';
  sgAllUsers.Cells[1,0] := 'ID';
  sgAllUsers.Cells[2,0] := 'Name';
  sgAllUsers.Cells[3,0] := 'Dept';
  sgAllUsers.Cells[4,0] := 'Host';
  sgAllUsers.Cells[5,0] := 'Port';
// start server
  ServerStartClick(Sender);
  ServerIncoming.Lines.Add(''); // work around bug with the first add
  ServerIncoming.Lines.Clear;   // work around bug with the first add
  FillGrids;
  Pages.ActivePage := Users;
end;

procedure TfmMain.ServerStartClick(Sender: TObject);
begin
  MsgServer1.ConnectionParams.LocalPort := StrToInt(LocalPort.Text);
// start server
  MsgServer1.Active := True;
// show LocalPort
  LocalPort.Text := IntToStr(MsgServer1.ConnectionParams.LocalPort);
// disable/enable buttons
  LocalPort.Enabled := False;
  ServerStart.Enabled := False;
  ServerStop.Enabled := True;
  DisconnectUser.Enabled := False;
  DeleteUser.Enabled := False;
end;

procedure TfmMain.ServerStopClick(Sender: TObject);
begin
// stop server
  MsgServer1.Active := False;
// disable/enable buttons
  LocalPort.Enabled := True;
  LocalPort.Text := IntToStr(MsgServer1.ConnectionParams.LocalPort);
  ServerStart.Enabled := True;
  ServerStop.Enabled := False;
  DisconnectUser.Enabled := False;
  DeleteUser.Enabled := False;
// clear form
  ClearGrid(sgConnectedUsers);
  ClearGrid(sgallUsers);
{
  sgConnectedUsers.Enabled := False; // hide table header
}
  ServerToID.Text := '';
end;

procedure TfmMain.MsgServer1ReceiveTextMessage(const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: String);
var
  str:          AnsiString;
  UserInfo:     TMsgUserInfo;
  sdt:          TServerDisplayThread;
begin
  str := '#' + IntToStr(FromUserID) + ', ' + DateTimeToStr(SendingDate) + ':';
  try
   UserInfo := MsgServer1.GetUserInfo(FromUserID);
   if (UserInfo.UserID <> MSG_INVALID_USER_ID) then
    str := UserInfo.UserName + ' ' + str;
  except
    str := 'Unregistered User ID = '+IntToStr(FromUserID)+' '+ str;
  end;
  str := str + AnsiString(#13#10) + Text;
  sdt := TServerDisplayThread.Create(True);
  sdt.Text := str;
  sdt.Resume;
//  ServerIncoming.Lines.Add(str);
//  ServerIncoming.Lines.Add(Text);
//  Pages.ActivePageIndex := i;  // work around bug with add to non-active page
end;

procedure TfmMain.ServerSendClick(Sender: TObject);
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

procedure TfmMain.MsgServer1AfterConnect(Sender: TObject);
begin
//  FillGrids;
end;

procedure TfmMain.sgConnectedUsersSelectCell(Sender: TObject; ACol,
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

procedure TfmMain.sgAllUsersSelectCell(Sender: TObject; ACol,
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

procedure TfmMain.MsgServer1BeforeDisconnect(Sender: TObject);
begin
  ServerToID.Text := '';
//  FillGrids;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MsgServer1.Active := False;
end;

procedure TfmMain.DisconnectUserClick(Sender: TObject);
begin
  MsgServer1.DisconnectUser(Cardinal(StrToInt(SelectedUserID.Text)));
  DisconnectUser.Enabled := False;
  DeleteUser.Enabled := True;
  FillGrids;
end;

procedure TfmMain.DeleteUserClick(Sender: TObject);
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


procedure TfmMain.FillGrids;
var Users:    TMsgUserInfoArray;
    i,na,nc:  Integer;
    Clients:  TMsgClientInfoArray;
    id1,id2:  String;
    gr1,gr2:  TGridRect;
begin
  try
    MsgServer1.GetUsers(Users);
    MsgServer1.GetClients(Clients);
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
          sgConnectedUsers.Cells[3,nc] := Users[i].Host;
          sgConnectedUsers.Cells[4,nc] := IntToStr(Users[i].Port);
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
          sgConnectedUsers.Cells[3,nc] := Clients[i].Host;
          sgConnectedUsers.Cells[4,nc] := IntToStr(Clients[i].Port);
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
  except
  end;
end; // FillGrids


procedure TfmMain.ClearGrid(Grid: TStringGrid);
var i: Integer;
begin
  Grid.RowCount := 2;
  Grid.FixedRows := 1;
  for i := 0 to Grid.ColCount-1 do
   Grid.Cells[i,1] := '';
end;

procedure TfmMain.Timer1Timer(Sender: TObject);
begin
 FillGrids;
end;

procedure TfmMain.MsgServer1AfterServerStart(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

procedure TfmMain.MsgServer1BeforeServerStop(Sender: TObject);
begin
  Timer1.Enabled := False;
end;

procedure TfmMain.MsgServer1AfterDisconnect(Sender: TObject);
begin
//  FillGrids;
end;

////////////////////////////////////////////////////////////////////////////////
//
// TServerDisplayThread
//
////////////////////////////////////////////////////////////////////////////////


constructor TServerDisplayThread.Create(text: AnsiString);
begin
  inherited Create(True);
  FText := text;
  FUnicodeText := '';
end;

constructor TServerDisplayThread.Create(text: WideString);
begin
  inherited Create(True);
  FText := '';
  FUnicodeText := text;
end;

procedure TServerDisplayThread.DisplayMessage;
begin
  if (FText = '') then
   fmMain.ServerIncoming.Lines.Add(FUnicodeText)
  else
   fmMain.ServerIncoming.Lines.Add(FText);
end;

procedure TServerDisplayThread.Execute;
begin
  Synchronize(DisplayMessage);
end;


procedure TfmMain.MsgServer1ReceiveUnicodeTextMessage(
  const FromUserID: Cardinal; const SendingDate, DeliveryDate: TDateTime;
  const Text: WideString);
var
  str:          WideString;
  UserInfo:     TMsgUserInfo;
  sdt:          TServerDisplayThread;
begin
  str := '#' + IntToStr(FromUserID) + ', ' + DateTimeToStr(SendingDate) + ':';
  try
   UserInfo := MsgServer1.GetUserInfo(FromUserID);
   if (UserInfo.UserID <> MSG_INVALID_USER_ID) then
    str := UserInfo.UserName + ' ' + str;
  except
    str := 'Unregistered User ID = '+IntToStr(FromUserID)+' '+ str;
  end;
  str := str + WideString(#13#10) + Text;
  sdt := TServerDisplayThread.Create(true);
  sdt.UnicodeText := str;
  sdt.Resume;
end;

end.
