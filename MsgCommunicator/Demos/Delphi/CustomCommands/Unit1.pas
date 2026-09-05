unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, MsgServer, MsgComBase, MsgClient;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    Edit2: TEdit;
    Memo2: TMemo;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Button2: TButton;
    MsgClient1: TMsgClient;
    MsgServer1: TMsgServer;
    Label7: TLabel;
    Label8: TLabel;
    ClientReceivedTime: TEdit;
    ClientSentTime: TEdit;
    Label9: TLabel;
    ServerSentTime: TEdit;
    ServerReceivedTime: TEdit;
    Label10: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MsgServer1ReceiveCommand(const FromID, Command: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; Buffer: PAnsiChar;
      Size: Integer);
    procedure MsgClient1ReceiveCommand(const FromID, Command: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; Buffer: PAnsiChar;
      Size: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  Buffer: String;
begin
  Buffer := Memo1.Text;
  MsgClient1.SendCommand(StrToInt(Edit1.Text),PChar(Buffer),Length(Memo1.Text));
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  Buffer: String;
begin
  Buffer := Memo2.Text;
  MsgServer1.SendCommand(MsgClient1.UserID,StrToInt(Edit2.Text),PChar(Buffer),Length(Memo2.Text));
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  UserInfo: TMsgUserInfo;
begin
  MsgServer1.Active := True;
  MsgClient1.UserID := 1;
  try
   MsgClient1.Connect;
  except
   if not MsgClient1.Logged then
    begin
     UserInfo.UserID := 1;
     UserInfo.UserName := 'User1';
     MsgClient1.RegisterNewUser(UserInfo);
    end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MsgClient1.Connected := False;
  MsgServer1.Active := False;
end;

procedure TForm1.MsgServer1ReceiveCommand(const FromID, Command: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; Buffer: PAnsiChar;
  Size: Integer);
begin
  Memo2.Text := Copy(Buffer,0,Size);
  Edit2.Text := IntToStr(Command);
  ServerSentTime.Text := DateTimeToStr(SendingDate);
  ServerReceivedTime.Text := DateTimeToStr(DeliveryDate);
end;

procedure TForm1.MsgClient1ReceiveCommand(const FromID, Command: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; Buffer: PAnsiChar;
  Size: Integer);
begin
  Memo1.Text := Copy(Buffer,0,Size);
  Edit1.Text := IntToStr(Command);
  ClientSentTime.Text := DateTimeToStr(SendingDate);
  ClientReceivedTime.Text := DateTimeToStr(DeliveryDate);
end;

end.
