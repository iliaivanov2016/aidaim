unit uRegister;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, MsgComBase, MsgConst;

type
  TfmRegister = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Label12: TLabel;
    Label10: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    RegUserDepartment: TEdit;
    RegUserCompany: TEdit;
    RegUserLastName: TEdit;
    RegUserFirstName: TEdit;
    RegUserName: TEdit;
    RegUserID: TEdit;
    bnRegister: TButton;
    bnCancel: TButton;
    edPassword: TEdit;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    edHost: TEdit;
    edPort: TEdit;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnCancelClick(Sender: TObject);
    procedure bnRegisterClick(Sender: TObject);
  private
    { Private declarations }
    FClose: Boolean;
  public
    { Public declarations }
  end;

var
  fmRegister: TfmRegister;

implementation

uses uMain, MsgClient;

{$R *.dfm}

procedure TfmRegister.FormShow(Sender: TObject);
begin
  edHost.Text := fmMain.MsgClient1.ConnectionParams.RemoteHost;
  edPort.Text := IntToStr(fmMain.MsgClient1.ConnectionParams.RemotePort);
  FClose := False;
  ModalResult := mrCancel;
end;

procedure TfmRegister.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (not FClose) then
   Action := TCloseAction(caNone);
end;

procedure TfmRegister.bnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  FClose := True;
end;

procedure TfmRegister.bnRegisterClick(Sender: TObject);
var UserInfo: TMsgUserInfo;
    res:      Integer;
begin
  // clear UserInfo
  FillChar(UserInfo,SizeOf(UserInfo),$00);
  ModalResult := mrOK;
  fmMain.MsgClient1.ConnectionParams.RemoteHost := edHost.Text;
  // if UserID empty then UserID will be assigned by the server
  if (RegUserID.Text = '') then
   UserInfo.UserID := MSG_INVALID_USER_ID
  else
   try
    UserInfo.UserID := Cardinal(StrToIntDef(RegUserID.Text,Integer(MSG_INVALID_USER_ID)));
   except
    ShowMessage('Invalid UserID');
    Exit;
   end;
  try
    fmMain.MsgClient1.ConnectionParams.RemotePort := StrToInt(edPort.Text);
  except
    ShowMessage('Invalid Port');
    Exit;
  end;
  bnRegister.Enabled := False;
  fmMain.MsgClient1.UserID := MSG_INVALID_USER_ID;
//  fmMain.MsgClient1.UserID := UserInfo.UserID;
  // fill UserInfo
  UserInfo.UserName := RegUserName.Text;
  UserInfo.FirstName := RegUserFirstName.Text;
  UserInfo.LastName := RegUserLastName.Text;
  UserInfo.Organization := RegUserCompany.Text;
  UserInfo.Department := RegUserDepartment.Text;
  try
    fmMain.MsgClient1.Connected := True;
  except
    ShowMessage('Registration failed. Cannot connect to server. Check parameters and ensure that server is started.')
  end;

  res := fmMain.MsgClient1.RegisterNewUser(UserInfo,edPassword.Text,True);
  if (res <> MSG_COMMAND_OK) then
   begin
    fmMain.MsgClient1.Connected := False;
    ShowMessage('Registration failed. Error code #'+IntToStr(res)+'. Check parameters.');
   end
  else
   begin
    fmMain.MsgClient1.Connected := False;
    fmMain.MsgClient1.Active := False;
    fmMain.MsgClient1.UserID := UserInfo.UserID;
    fmMain.MsgClient1.Password := edPassword.Text;
    if (fmMain.Login) then
      FClose := True
    else
      ShowMessage('Login failed. Check parameters and ensure that server is started.');
   end;
  bnRegister.Enabled := True;
end;

end.
