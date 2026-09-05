unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, MsgClient, MsgComBase, MsgServer, MsgConst, MsgTypes;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    ServerSend: TButton;
    Directly: TRadioButton;
    RadioButton1: TRadioButton;
    ClientSend: TButton;
    Memo2: TMemo;
    Label1: TLabel;
    MsgServer1: TMsgServer;
    MsgClient1: TMsgClient;
    MsgClient2: TMsgClient;
    MsgClient3: TMsgClient;
    procedure FormCreate(Sender: TObject);
    procedure ServerSendClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure MsgClient2ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure MsgClient3ReceiveTextMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const Text: String);
    procedure ClientSendClick(Sender: TObject);
  private
  public
  end;

  TShowThread = class(TThread)
  private
  public
   Text: String;
   procedure Execute; override;
   procedure LogMessage;
  end;

var
  Form1:      TForm1;
  ToUserIDs:  TMsgIntegerArray;
  ShowThread: TShowThread;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
 UserInfo:  TMsgUserInfo;
 i:         Integer;
begin
 Memo1.Text := 'Hello!';
 ToUserIDs := TMsgIntegerArray.Create(3);
 MsgServer1.NetworkSettings.PingClients := False;
 MsgServer1.Active := True;
 MsgClient1.Connect;
 for i := 1 to 3 do
  begin
   ToUserIDs.Items[i-1] := i;
   if (MsgClient1.IsUserExisting(i) <> MSG_COMMAND_RESULT_TRUE) then
    begin
     UserInfo.UserID := i;
     MsgClient1.RegisterNewUser(UserInfo);
    end;
  end;
 MsgClient1.Disconnect;
 MsgClient1.Active := False;
 MsgClient1.UserID := 1;
 MsgClient1.Connect;
 MsgClient2.UserID := 2;
 MsgClient2.Connect;
 MsgClient3.UserID := 3;
 MsgClient3.Connect;
end;

procedure TForm1.ServerSendClick(Sender: TObject);
var
 Results: TMsgIntegerArray;
 str:     String;
begin
 Results := TMsgIntegerArray.Create(3);
 MsgServer1.SendMessageMultiple(ToUserIDs,Memo1.Text,Results);
// log results of sending
 str := 'Server sent message with the following results: '+#13+#10+
        IntToStr(Results.Items[0])+', '+IntToStr(Results.Items[1])+', '+IntToStr(Results.Items[2])+'.';
 ShowThread := TShowThread.Create(True);
 ShowThread.Text := str;
 ShowThread.Resume;
 Results.Free;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 ToUserIDs.Free;
end;

procedure TForm1.MsgClient1ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
begin
 ShowThread := TShowThread.Create(True);
 ShowThread.Text := IntToStr(FromUserID)+'->1: '+Text;
 ShowThread.Resume;
end;

procedure TForm1.MsgClient2ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
begin
 ShowThread := TShowThread.Create(True);
 ShowThread.Text := IntToStr(FromUserID)+'->2: '+Text;
 ShowThread.Resume;
end;

procedure TForm1.MsgClient3ReceiveTextMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const Text: String);
begin
 ShowThread := TShowThread.Create(True);
 ShowThread.Text := IntToStr(FromUserID)+'->3: '+Text;
 ShowThread.Resume;
end;

procedure TShowThread.Execute;
begin
 Synchronize(LogMessage);
end;

procedure TShowThread.LogMessage;
begin
 Form1.Memo2.Lines.Add(Text);
end;

procedure TForm1.ClientSendClick(Sender: TObject);
var
 direct:    boolean;
 Results:   TMsgIntegerArray;
 str:       String;
begin
 if Directly.Checked then
   direct := true
 else
   direct := false;
 Results := TMsgIntegerArray.Create(3);
 MsgClient1.SendMessageMultiple(ToUserIDs,Memo1.Text,Results,direct);
// log results of sending
 str := 'Client1 sent message with the following results: '+#13+#10+
        IntToStr(Results.Items[0])+', '+IntToStr(Results.Items[1])+', '+IntToStr(Results.Items[2])+'.';
 ShowThread := TShowThread.Create(True);
 ShowThread.Text := str;
 ShowThread.Resume;
 Results.Free;
end;

end.

