unit uLogin;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, MsgComBase;

type
  TfmLogin = class(TForm)
    Panel1: TPanel;
    bnLogin: TButton;
    bnCancel: TButton;
    Panel2: TPanel;
    Label12: TLabel;
    Label10: TLabel;
    edPassword: TEdit;
    RegUserID: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    edHost: TEdit;
    edPort: TEdit;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnCancelClick(Sender: TObject);
    procedure bnLoginClick(Sender: TObject);
  private
    { Private declarations }
    FClose: Boolean;
  public
    { Public declarations }
  end;

var
  fmLogin: TfmLogin;

implementation

uses uMain;

{$R *.dfm}

procedure TfmLogin.FormShow(Sender: TObject);
begin
  if (fmMain.MsgClient1.UserID <> MSG_INVALID_USER_ID) then
   RegUserID.Text := IntToStr(fmMain.MsgClient1.UserID);
  edHost.Text := fmMain.MsgClient1.ConnectionParams.RemoteHost;
  edPort.Text := IntToStr(fmMain.MsgClient1.ConnectionParams.RemotePort);
  FClose := False;
  ModalResult := mrCancel;
end;

procedure TfmLogin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (not FClose) then
   Action := caNone;
end;

procedure TfmLogin.bnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  FClose := True;
end;

procedure TfmLogin.bnLoginClick(Sender: TObject);
begin
  ModalResult := mrOK;
  fmMain.MsgClient1.ConnectionParams.RemoteHost := edHost.Text;
  try
    fmMain.MsgClient1.UserID := StrToInt(RegUserID.Text);
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
  fmMain.MsgClient1.Password := edPassword.Text;
  bnLogin.Enabled := False;
  if (fmMain.Login) then
    FClose := True
  else
   ShowMessage('Login failed. Check parameters and ensure that server is started.');
  bnLogin.Enabled := True;
end;

end.
