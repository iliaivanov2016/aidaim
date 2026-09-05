unit Main;

interface

uses
  Windows, Messages, SysUtils,
  Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, DB, ExtCtrls, Grids,
  MsgClient, MsgComBase, MsgTypes, MsgConst;

type
  TForm1 = class(TForm)
    U1Incoming: TMemo;
    U2Incoming: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    U1Msg: TMemo;
    U2Msg: TMemo;
    Label3: TLabel;
    Label4: TLabel;
    U1Send: TButton;
    Label5: TLabel;
    U1To: TComboBox;
    Label7: TLabel;
    U2Send: TButton;
    U2To: TComboBox;
    U1Start: TButton;
    U1Stop: TButton;
    Label9: TLabel;
    U3Incoming: TMemo;
    Label10: TLabel;
    U3Msg: TMemo;
    U3Send: TButton;
    Label13: TLabel;
    Label14: TLabel;
    U2Start: TButton;
    U2Stop: TButton;
    Label15: TLabel;
    U3Start: TButton;
    U3Stop: TButton;
    Label11: TLabel;
    U3To: TComboBox;
    U1Connect: TButton;
    U1Disconnect: TButton;
    U2Connect: TButton;
    U2Disconnect: TButton;
    U3Connect: TButton;
    U3Disconnect: TButton;
    MsgClient1: TMsgClient;
    MsgClient2: TMsgClient;
    MsgClient3: TMsgClient;
    procedure FormCreate(Sender: TObject);
    procedure U1StartClick(Sender: TObject);
    procedure U2StartClick(Sender: TObject);
    procedure U3StartClick(Sender: TObject);
    procedure U1StopClick(Sender: TObject);
    procedure U2StopClick(Sender: TObject);
    procedure U3StopClick(Sender: TObject);
    procedure U1ConnectClick(Sender: TObject);
    procedure U2ConnectClick(Sender: TObject);
    procedure U3ConnectClick(Sender: TObject);
    procedure U1DisconnectClick(Sender: TObject);
    procedure U2DisconnectClick(Sender: TObject);
    procedure U3DisconnectClick(Sender: TObject);
    procedure U1SendClick(Sender: TObject);
    procedure U2SendClick(Sender: TObject);
    procedure U3SendClick(Sender: TObject);
    procedure MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure MsgClient2ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure MsgClient3ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  MsgClient1.ConnectionParams.NetworkSettings.SetDefaultSettings(msgLocal);
  MsgClient2.ConnectionParams.NetworkSettings.SetDefaultSettings(msgLocal);
  MsgClient3.ConnectionParams.NetworkSettings.SetDefaultSettings(msgLocal);
  MsgClient1.ConnectionParams.NetworkSettings.ConnectRetryCount := 3;
  MsgClient2.ConnectionParams.NetworkSettings.ConnectRetryCount := 3;
  MsgClient3.ConnectionParams.NetworkSettings.ConnectRetryCount := 3;
  MsgClient1.ConnectionParams.NetworkSettings.ConnectDelay := 300;
  MsgClient2.ConnectionParams.NetworkSettings.ConnectDelay := 300;
  MsgClient3.ConnectionParams.NetworkSettings.ConnectDelay := 300;
  U1StartClick(Sender);
  U2StartClick(Sender);
  U3StartClick(Sender);
  U1ConnectClick(Sender);
  U2ConnectClick(Sender);
  U3ConnectClick(Sender);
end;

procedure TForm1.U1SendClick(Sender: TObject);
var
  res: Integer;
begin
  if (U1To.ItemIndex<0) or (U1To.ItemIndex>3)
    then Exit;
  res := MsgClient1.SendMessage(U1To.ItemIndex+1, U1Msg.Text, True);
  if res <> MSG_COMMAND_OK then
    ShowError('MsgClient1.SendMessage',res);
  U1Msg.Text := '!';
end;

procedure TForm1.U2SendClick(Sender: TObject);
var
  res: Integer;
begin
  if (U2To.ItemIndex<0) or (U2To.ItemIndex>3)
    then Exit;
  res := MsgClient2.SendMessage(U2To.ItemIndex+1, U2Msg.Text, True);
  if res <> MSG_COMMAND_OK then
    ShowError('MsgClient2 SendMessage',res);
  U2Msg.Text := '!!';
end;

procedure TForm1.U3SendClick(Sender: TObject);
var
  res: Integer;
begin
  if (U3To.ItemIndex<0) or (U3To.ItemIndex>3)
    then Exit;
  res := MsgClient3.SendMessage(U3To.ItemIndex+1, U3Msg.Text, True);
  if res <> MSG_COMMAND_OK then
    ShowError('MsgClient3 SendMessage',res);
  U3Msg.Text := '!!!';
end;

procedure TForm1.U1StartClick(Sender: TObject);
begin
  MsgClient1.Active := True;
  U1Start.Enabled := False;
  U1Stop.Enabled := True;
end;

procedure TForm1.U1StopClick(Sender: TObject);
begin
  MsgClient1.Active := False;
  U1Start.Enabled := True;
  U1Stop.Enabled := False;
end;

procedure TForm1.U1ConnectClick(Sender: TObject);
begin
  MsgClient1.ConnectDirectly(MsgClient2.UserID, 'localhost', MsgClient2.ConnectionParams.LocalPort);
  MsgClient1.ConnectDirectly(MsgClient3.UserID, 'localhost', MsgClient3.ConnectionParams.LocalPort);
  U1Connect.Enabled := False;
  U1Disconnect.Enabled := True;
end;

procedure TForm1.U1DisconnectClick(Sender: TObject);
begin
  MsgClient1.DisconnectAll;
  U1Connect.Enabled := True;
  U1Disconnect.Enabled := False;
end;

procedure TForm1.U2StartClick(Sender: TObject);
begin
  MsgClient2.Active := True;
  U2Start.Enabled := False;
  U2Stop.Enabled := True;
end;

procedure TForm1.U2StopClick(Sender: TObject);
begin
  MsgClient2.Active := False;
  U2Start.Enabled := True;
  U2Stop.Enabled := False;
end;

procedure TForm1.U2ConnectClick(Sender: TObject);
begin
  MsgClient2.ConnectDirectly(MsgClient1.UserID, 'localhost', MsgClient1.ConnectionParams.LocalPort);
  MsgClient2.ConnectDirectly(MsgClient3.UserID, 'localhost', MsgClient3.ConnectionParams.LocalPort);
  U2Connect.Enabled := False;
  U2Disconnect.Enabled := True;
end;

procedure TForm1.U2DisconnectClick(Sender: TObject);
begin
  MsgClient2.DisconnectAll;
  U2Connect.Enabled := True;
  U2Disconnect.Enabled := False;
end;

procedure TForm1.U3StartClick(Sender: TObject);
begin
  MsgClient3.Active := True;
  U3Start.Enabled := False;
  U3Stop.Enabled := True;
end;

procedure TForm1.U3StopClick(Sender: TObject);
begin
  MsgClient3.Active := False;
  U3Start.Enabled := True;
  U3Stop.Enabled := False;
end;

procedure TForm1.U3ConnectClick(Sender: TObject);
begin
  MsgClient3.ConnectDirectly(MsgClient1.UserID, 'localhost', MsgClient1.ConnectionParams.LocalPort);
  MsgClient3.ConnectDirectly(MsgClient2.UserID, 'localhost', MsgClient2.ConnectionParams.LocalPort);
  U3Connect.Enabled := False;
  U3Disconnect.Enabled := True;
end;

procedure TForm1.U3DisconnectClick(Sender: TObject);
begin
  MsgClient3.DisconnectAll;
  U3Connect.Enabled := True;
  U3Disconnect.Enabled := False;
end;

procedure TForm1.MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
var
  str:          String;
begin
  str := '#' + IntToStr(FromUserID) + ', ' + TimeToStr(Time) + ':';
  U1Incoming.Lines.Add(str);
  U1Incoming.Lines.Add(Text);
end;

procedure TForm1.MsgClient2ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
var
  str:          String;
begin
  str := '#' + IntToStr(FromUserID) + ', ' + TimeToStr(Time) + ':';
  U2Incoming.Lines.Add(str);
  U2Incoming.Lines.Add(Text);
end;

procedure TForm1.MsgClient3ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
var
  str:          String;
begin
  str := '#' + IntToStr(FromUserID) + ', ' + TimeToStr(Time) + ':';
  U3Incoming.Lines.Add(str);
  U3Incoming.Lines.Add(Text);
end;

procedure TForm1.ShowError(Operation: String; ErrorCode: Integer);
begin
  case ErrorCode of
   MSG_Error_SendMessage_SessionNotFound:
     Operation := 'Cannot send message due connection to recepient is not set. ' + #10#13 + Operation;
   MSG_Error_SendMessage_SendFailed:
     Operation := 'Failed to send message. ' + #10#13 + Operation;
   end;
  MessageDlg(Operation+' failed. Error code = '+IntToStr(ErrorCode),mtWarning,[mbOk], 0);
end;

end.
