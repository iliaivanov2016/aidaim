unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, MsgComBase, MsgClient, MsgTypes, StdCtrls;

type
  TForm1 = class(TForm)
    cbLogin: TComboBox;
    Password: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    MsgClient1: TMsgClient;
    btnLogin: TButton;
    lbUserID: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  UserID:   Cardinal;
  UserInfo: TMsgUserInfo;
begin
  MsgClient1.ConnectionParams.NetworkSettings.SetDefaultSettings(msgLocal);
  MsgClient1.ConnectionParams.NetworkSettings.ConnectRetryCount := 3;
  MsgClient1.ConnectionParams.NetworkSettings.ConnectDelay := 300;
  MsgClient1.Connect;
  lbUserID.Caption := 'UserID: '+ IntToStr(MsgClient1.UserID);
  cbLogin.Items.Add('Leo');
  cbLogin.Items.Add('Ray');
  cbLogin.Items.Add('Ella');
  cbLogin.Items.Add('Netty');
end;

procedure TForm1.btnLoginClick(Sender: TObject);
var
  UserID:   Cardinal;
  res:      Integer;
begin
  if MsgClient1.Logged then MsgClient1.Logoff;
  MsgClient1.FindUserID(cbLogin.Items[cbLogin.ItemIndex],UserID);
  MsgClient1.UserID := UserID;
  MsgClient1.Password := Password.Text;
  res := MsgClient1.Logon;
  lbUserID.Caption := 'UserID: '+ IntToStr(MsgClient1.UserID);
  if MsgClient1.UserID <> UserID then
    MessageDlg('UserID: '+IntToStr(UserID)+' - Logon failed. Error code = '+IntToStr(res),mtWarning,[mbOk], 0);
end;

end.
