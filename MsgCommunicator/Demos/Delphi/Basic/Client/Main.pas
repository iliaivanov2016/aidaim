unit Main;

interface

{$IFNDEF VER120}
  {$IFNDEF VER125}
    {$IFNDEF VER130}
      {$IFNDEF VER135}
        {$DEFINE D6H}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ExtCtrls, Grids, CheckLst,
  MsgClient, MsgComBase, MsgConst, MsgTypes, ComCtrls;

type
  TForm1 = class(TForm)
    MsgClient1: TMsgClient;
    U1Incoming: TRichEdit;
    U1Msg: TRichEdit;
    Label3: TLabel;
    U1Send: TButton;
    Label5: TLabel;
    U1To: TComboBox;
    U1ToID: TEdit;
    Label6: TLabel;
    U1Connect: TButton;
    U1Disconnect: TButton;
    ServerID: TEdit;
    Label2: TLabel;
    Label4: TLabel;
    ServerHost: TEdit;
    Label7: TLabel;
    ServerPort: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    UserID: TEdit;
    ClientPort: TEdit;
    gbConnection: TGroupBox;
    gbMessages: TGroupBox;
    gbSend: TGroupBox;
    pLeft: TPanel;
    pCenter: TPanel;
    pRight: TPanel;
    gbContacts: TGroupBox;
    pContactsTop: TPanel;
    btnGetContactList: TButton;
    pContactsBottom: TPanel;
    clbContactList: TCheckListBox;
    Label1: TLabel;
    UserID2Add: TEdit;
    btnAddUserToContacts: TButton;
    gbRegistration: TGroupBox;
    RegUserID: TEdit;
    RegUserName: TEdit;
    RegUserFirstName: TEdit;
    RegUserLastName: TEdit;
    RegUserDepartment: TEdit;
    pRegTop: TPanel;
    gbUserInfo: TGroupBox;
    InfoUserName: TEdit;
    InfoUserFirstName: TEdit;
    InfoUserLastName: TEdit;
    InfoUserDepartment: TEdit;
    pUserInfoTop: TPanel;
    Label11: TLabel;
    UserID2GetInfo: TEdit;
    btnGetUserInfo: TButton;
    btnRegister: TButton;
    RegUserCompany: TEdit;
    InfoUserCompany: TEdit;
    Label12: TLabel;
    Label10: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    pGap: TPanel;
    btnRemoveUserFromContacts: TButton;
    btnLogon: TButton;
    btnLogoff: TButton;
    Label17: TLabel;
    Password: TEdit;
    Label23: TLabel;
    Label24: TLabel;
    RegPassword: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure U1ConnectClick(Sender: TObject);
    procedure U1DisconnectClick(Sender: TObject);
    procedure U1ToChange(Sender: TObject);
    procedure U1ToIDChange(Sender: TObject);
    procedure U1SendClick(Sender: TObject);
    procedure AddMessage(const FromUserID: Cardinal; const Text: String; Const MsgDate: TDateTime);
    procedure MsgClient1ReceiveTextMessage(const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: String);
    procedure MsgClient1ServerShutdown(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SetConnectParams;
    procedure GetConnectParams;
    procedure Connected;
    function GetUserID(Str: String):Cardinal;
    procedure btnGetUserInfoClick(Sender: TObject);
    procedure UserIDChange(Sender: TObject);
    procedure btnAddUserToContactsClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
    procedure MsgClient1UserOnLine(const UserID: Cardinal);
    procedure MsgClient1UserOffLine(const UserID: Cardinal);
    procedure btnRemoveUserFromContactsClick(Sender: TObject);
    procedure btnGetContactListClick(Sender: TObject);
    procedure btnLogonClick(Sender: TObject);
    procedure btnLogoffClick(Sender: TObject);
    procedure VisualizeContactList;
    procedure VisualizeLogged;
    procedure VisualizeUserInfo;
    procedure ShowError(Operation: String; ErrorCode: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1:          TForm1;

implementation

{$R *.dfm}


const
  NoExistingUser = ' - NO USER -';

procedure TForm1.FormCreate(Sender: TObject);
begin
  MsgClient1.ConnectionParams.NetworkSettings.SetDefaultSettings(msgLocal);
  MsgClient1.ConnectionParams.NetworkSettings.ConnectRetryCount := 3;
  MsgClient1.ConnectionParams.NetworkSettings.ConnectDelay := 300;
  clbContactList.Color := clMenu;
  MsgClient1ServerShutdown(Sender);
  SetConnectParams;
  VisualizeLogged;
end;

procedure TForm1.U1ToChange(Sender: TObject);
begin
  if (U1To.ItemIndex >= 0)
  and (U1To.ItemIndex < MsgClient1.ContactCount)
  then
   begin
    U1ToID.Text := IntToStr(MsgClient1.Contacts[U1To.ItemIndex].UserInfo.UserID);
   end
  else
   begin
    U1ToID.Text := ServerID.Text;
    U1To.ItemIndex := MsgClient1.ContactCount;
   end;
end;

procedure TForm1.U1ToIDChange(Sender: TObject);
var
  i:            Integer;
begin
  for i:= 0 to MsgClient1.ContactCount-1 do
   begin
    if (MsgClient1.Contacts[i].UserInfo.UserID = GetUserID(U1ToID.Text)) then
     begin
      U1To.ItemIndex := i;
      Exit;
     end;
   end;
  U1To.ItemIndex := MsgClient1.ContactCount;
  U1ToID.Text := ServerID.Text;
end;

procedure TForm1.U1SendClick(Sender: TObject);
var
  UserID: Cardinal;
  res:    Integer;
begin
  UserID := GetUserID(U1ToID.Text);
  if UserID = MSG_INVALID_USER_ID then
    Exit;
  res := MsgClient1.SendMessage(UserID, U1Msg.Text);
  if (res = MSG_COMMAND_OK) then
   begin
    AddMessage(GetUserID(U1ToID.Text), U1Msg.Text, Now);
    U1Msg.Text := '';
   end
  else
    ShowError('SendMessage', res)
end;

procedure TForm1.MsgClient1ReceiveTextMessage(const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: String);
begin
 while not Canvas.TryLock do
  sleep(0);
 try
  AddMessage(FromUserID, Text, SendingDate);
 finally
  Canvas.Unlock;
 end;
end;

procedure TForm1.AddMessage(const FromUserID: Cardinal; const Text: String; Const MsgDate: TDateTime);
var
  str, str2:    String;
  i:            Integer;
begin
  str := '#' + IntToStr(FromUserID) + ', ' + DateTimeToStr(MsgDate) + ':';
  for i:=0 to MsgClient1.ContactCount-1 do
   begin
    if (MsgClient1.Contacts[i].UserInfo.UserID = FromUserID) then
     begin
      str2 := MsgClient1.GetContactDisplayName(MsgClient1.Contacts[i]);
      str := str2 + ' ' + str;
      break;
     end;
   end;
  if U1Msg.Text = Text then
    str := '>>> ' + str
  else
    str := '<<< ' + str;
  U1Incoming.Lines.Add(str);
  U1Incoming.Lines.Add(Text);
end;

procedure TForm1.U1ConnectClick(Sender: TObject);
var
  i:            Integer;
  str:          String;
  UserInfo:     TMsgUserInfo;
begin
 GetConnectParams;
 try
   MsgClient1.Connect;
 finally
  if MsgClient1.Connected then
   begin
    SetConnectParams;
    Connected;
    RegUserID.Text := IntToStr(MsgClient1.UserID);
    if (MsgClient1.GetUserInfo(MsgClient1.UserID,UserInfo) <> MSG_COMMAND_OK) then
     begin
      RegUserName.Text := 'User' + RegUserID.Text;
      RegUserFirstName.Text := '';
      RegUserLastName.Text := '';
      RegUserDepartment.Text := '';
      RegUserCompany.Text := '';
     end
    else
     begin
      RegUserName.Text := UserInfo.UserName;
      RegUserFirstName.Text := UserInfo.FirstName;
      RegUserLastName.Text := UserInfo.LastName;
      RegUserDepartment.Text := UserInfo.Department;
      RegUserCompany.Text := UserInfo.Organization;
     end;
    U1To.Clear;
    clbContactList.Clear;
    if MsgClient1.UserID <> MSG_INVALID_USER_ID then
      for i:=0 to MsgClient1.ContactCount-1 do
       begin
        str := MsgClient1.GetContactDisplayName(MsgClient1.Contacts[i]);
        U1To.Items.Add(str);
        clbContactList.Items.Add(str);
        if (MsgClient1.Contacts[i].UserInfo.Status <> msgOffLine) then
          clbContactList.Checked[clbContactList.Items.Count-1] := True;
       end;
    U1To.Items.Add('Server');
    VisualizeLogged;
   end
  else // not Connected
   begin
    UserID.Text := IntToStr(MsgClient1.UserID);
    MsgClient1ServerShutdown(Sender); // calls VisualizeLogged
   end;
 end;
end;

procedure TForm1.U1DisconnectClick(Sender: TObject);
begin
// disconnect from server
  MsgClient1.Disconnect;
// update form
  clbContactList.Clear;
  MsgClient1ServerShutdown(Sender);
end;

procedure TForm1.MsgClient1ServerShutdown(Sender: TObject);
begin
  ServerHost.Enabled := True;
  ServerPort.Enabled := True;
  ClientPort.Enabled := True;
  ServerID.Enabled := True;
  UserID.Enabled := True;
// disable/enable buttons
  U1Connect.Enabled := True;
  U1Disconnect.Enabled := False;
  VisualizeLogged;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  U1DisconnectClick(Sender);
end;

procedure TForm1.SetConnectParams;
begin
  ServerHost.Text := MsgClient1.ConnectionParams.RemoteHost;
  ServerPort.Text := IntToStr(MsgClient1.ConnectionParams.RemotePort);
  ClientPort.Text := IntToStr(MsgClient1.ConnectionParams.LocalPort);
  ServerID.Text := IntToStr(MsgClient1.ConnectionParams.ServerID);
  UserID.Text := IntToStr(MsgClient1.UserID);
end;

procedure TForm1.GetConnectParams;
var
  UID:        Int64;
begin
  MsgClient1.ConnectionParams.RemoteHost := ServerHost.Text;
  MsgClient1.ConnectionParams.RemotePort := StrToIntDef(ServerPort.Text,MsgDefaultServerPort);
  MsgClient1.ConnectionParams.LocalPort := StrToIntDef(ClientPort.Text,MsgDefaultClientPort);
  MsgClient1.ConnectionParams.ServerID := StrToIntDef(ServerID.Text,MsgDefaultServerID);
  UID := StrToInt64Def(UserID.Text,MSG_INVALID_USER_ID);
  if UID > MSG_INVALID_USER_ID then
    UID := MSG_INVALID_USER_ID;
  MsgClient1.Password := Password.Text;
  MsgClient1.Connected := False;
  MsgClient1.Active := False;
  MsgClient1.UserID := Cardinal(UID);
end;

procedure TForm1.Connected;
begin
  ServerHost.Enabled := False;
  ServerPort.Enabled := False;
  ClientPort.Enabled := False;
  ServerID.Enabled := False;
  UserID.Enabled := False;
  Password.Enabled := False;
// disable/enable buttons
  U1Connect.Enabled := False;
  U1Disconnect.Enabled := True;
end;

function TForm1.GetUserID(Str: String):Cardinal;
var
  UID:        Int64;
begin
  UID := StrToInt64Def(Str,MSG_INVALID_USER_ID);
  if UID > MSG_INVALID_USER_ID then
    UID := MSG_INVALID_USER_ID;
  Result := UID;
end;

procedure TForm1.btnGetUserInfoClick(Sender: TObject);
var
  UserInfo:       TMsgUserInfo;
  res:            Integer;
begin
  res := MsgClient1.GetUserInfo(GetUserID(UserID2GetInfo.Text),UserInfo);
  if (res <> MSG_COMMAND_OK) then
   begin
    if (res = MSG_Error_GetUserInfo_UserDoesNotExist) then
      InfoUserName.Text := NoExistingUser
    else
      InfoUserName.Text := '';
    InfoUserFirstName.Text := '';
    InfoUserLastName.Text := '';
    InfoUserCompany.Text := '';
    InfoUserDepartment.Text := '';
    ShowError('GetUserInfo',res);
   end
  else
   begin
    InfoUserName.Text := UserInfo.UserName;
    InfoUserFirstName.Text := UserInfo.FirstName;
    InfoUserLastName.Text := UserInfo.LastName;
    InfoUserCompany.Text := UserInfo.Organization;
    InfoUserDepartment.Text := UserInfo.Department;
   end;
end;

procedure TForm1.UserIDChange(Sender: TObject);
begin
  TEdit(Sender).Text := IntToStr(GetUserID(TEdit(Sender).Text));
end;

procedure TForm1.VisualizeContactList;
var
  i:   Integer;
begin
  clbContactList.Clear;
  for i := 0 to MsgClient1.ContactCount-1 do
   begin
    clbContactList.Items.Add(MsgClient1.GetContactDisplayName(MsgClient1.Contacts[i]));
    if (MsgClient1.Contacts[i].UserInfo.Status <> msgOffLine) then
      clbContactList.Checked[clbContactList.Items.Count-1] := True;
   end;
end;

procedure TForm1.btnGetContactListClick(Sender: TObject);
var
  res: Integer;
begin
  res := MsgClient1.GetContacts;
  if (res <> MSG_COMMAND_OK) then
    ShowError('GetContacts',res);
  VisualizeContactList;
end;

procedure TForm1.btnRegisterClick(Sender: TObject);
var
  UserInfo:       TMsgUserInfo;
  res:            Integer;
  oper:           String;
begin
  FillChar(UserInfo,SizeOf(UserInfo),$00);
  UserInfo.UserID := MsgClient1.UserID;
  UserInfo.UserName := RegUserName.Text;
  UserInfo.FirstName := RegUserFirstName.Text;
  UserInfo.LastName := RegUserLastName.Text;
  UserInfo.Organization := RegUserCompany.Text;
  UserInfo.Department := RegUserDepartment.Text;
  if (MsgClient1.IsUserExisting(MsgClient1.UserID) = MSG_COMMAND_RESULT_TRUE) then
   begin
    res := MsgClient1.UpdateUserInfo(UserInfo,True,RegPassword.Text);
    oper := 'UpdateUserInfo';
   end
  else
   begin
    MsgClient1.Password := RegPassword.Text;
    res := MsgClient1.RegisterNewUser(UserInfo,MsgClient1.Password);
    oper := 'RegisterNewUser';
    VisualizeLogged;
    // Save UserID
    UserID.Text := IntToStr(MsgClient1.UserID);
    RegUserID.Text := IntToStr(MsgClient1.UserID);
   end;
  if (res <> MSG_COMMAND_OK) then
    ShowError(oper,res);
end;

procedure TForm1.MsgClient1UserOnLine(const UserID: Cardinal);
var
  i:              Integer;
begin
  for i := 0 to MsgClient1.ContactCount-1 do
   begin
    if (MsgClient1.Contacts[i].UserInfo.UserID = UserID) then
     clbContactList.Checked[i] := True;
   end;
end;

procedure TForm1.MsgClient1UserOffLine(const UserID: Cardinal);
var
  i:              Integer;
begin
  for i := 0 to MsgClient1.ContactCount-1 do
   begin
    if (MsgClient1.Contacts[i].UserInfo.UserID = UserID) then
     clbContactList.Checked[i] := False;
   end;
end;

procedure TForm1.btnAddUserToContactsClick(Sender: TObject);
var
  res: Integer;
begin
  // show user as FirstName + LastName
  res := MsgClient1.AddUserToContacts(GetUserID(UserID2Add.Text),mcnsFullName,'');
  if (res <> MSG_COMMAND_OK) then
    ShowError('AddUserToContacts',res);
  btnGetContactListClick(Sender);
end;

procedure TForm1.btnRemoveUserFromContactsClick(Sender: TObject);
var
  res: Integer;
begin
  res := MsgClient1.RemoveUserFromContacts(GetUserID(UserID2Add.Text));
  if (res <> MSG_COMMAND_OK) then
    ShowError('RemoveUserFromContacts',res);
  btnGetContactListClick(Sender);
end;

procedure TForm1.VisualizeUserInfo;
var
  UserInfo:       TMsgUserInfo;
  res:            Integer;
  oper:           String;
begin
  FillChar(UserInfo,SizeOf(UserInfo),$00);
  UserInfo.UserID := MsgClient1.UserID;
  oper := 'GetUserInfo';
  res :=  MsgClient1.GetUserInfo(MsgClient1.UserID, UserInfo);
  if (res <> MSG_COMMAND_OK) then
   begin
    ShowError(oper,res);
    Exit;
   end;
  UserID.Text := IntToStr(UserInfo.UserID);
  RegUserID.Text := UserID.Text;
  RegUserName.Text := UserInfo.UserName;
  RegUserFirstName.Text := UserInfo.FirstName;
  RegUserLastName.Text := UserInfo.LastName;
  RegUserCompany.Text := UserInfo.Organization;
  RegUserDepartment.Text := UserInfo.Department;
end;

procedure TForm1.VisualizeLogged;
begin
  if MsgClient1.Logged then
   begin
    btnLogon.Enabled := False;
    btnLogoff.Enabled := True;
    UserID.Enabled := False;
    Password.Enabled := False;
   end
  else
   begin
    btnLogon.Enabled := True;
    btnLogoff.Enabled := False;
    UserID.Enabled := True;
    Password.Enabled := True;
   end;
end;

procedure TForm1.btnLogonClick(Sender: TObject);
var res: Integer;
begin
  MsgClient1.UserID := GetUserID(UserID.Text);
  res := MsgClient1.Logon;
  case res of
   MSG_Error_Logon_NotConnected:
      MessageDlg('Logon failed. You should connect to the server before logon. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_SendCommandFailed:
      MessageDlg('Logon failed. Cannot send request to server. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_ReceiveResultFailed:
      MessageDlg('Logon failed. Cannot get reply from server. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_InvalidServerReply:
      MessageDlg('Logon failed. Invalid reply received from server. Please, check the versions of MsgCommunicator on both client and server sides and contact AidAim software if they are the same. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_MaxConnectionsExceeded:
      MessageDlg('Logon failed. Maximum number of allowed connections exceeded. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_UserDoesNotExist:
     if MsgClient1.UserID = MSG_INVALID_USER_ID then
      MessageDlg('Logon failed. You cannot logon as a guest (UserID = MSG_INVALID_USER_ID). Server replied: User does not exist. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0)
     else
      MessageDlg('Logon failed. User does not exist. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_InvalidPassword:
      MessageDlg('Logon failed. Invalid password. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_InvalidParams:
      MessageDlg('Logon failed. Server detected invalid parameters in client request. Please, check the versions of MsgCommunicator on both client and server sides and contact AidAim software if they are the same. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_InternalServerError:
      MessageDlg('Logon failed. Internal server error.  Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
   MSG_Error_Logon_UserAlreadyLogged:
      MessageDlg('Logon failed. User is already logged. Error code = '
        +IntToStr(res),mtWarning,[mbOk], 0);
  else
    VisualizeLogged;
    VisualizeContactList;
    VisualizeUserInfo;
  end;
end;

procedure TForm1.btnLogoffClick(Sender: TObject);
begin
  MsgClient1.Logoff;
  VisualizeLogged;
  clbContactList.Clear;
end;

procedure TForm1.ShowError(Operation: String; ErrorCode: Integer);
begin
  MessageDlg(Operation+' failed. Error code = '+IntToStr(ErrorCode),mtWarning,[mbOk], 0);
end;

end.
