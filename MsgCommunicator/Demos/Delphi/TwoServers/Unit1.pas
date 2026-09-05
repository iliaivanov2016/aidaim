unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, MsgComBase, MsgServer, StdCtrls;

type
  TForm1 = class(TForm)
    MsgServer1: TMsgServer;
    MsgServer2: TMsgServer;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    S1ServerID: TEdit;
    S1Host: TEdit;
    S1Port: TEdit;
    GroupBox3: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    S2ServerID: TEdit;
    S2Host: TEdit;
    S2Port: TEdit;
    procedure FormCreate(Sender: TObject);
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
begin
  MsgServer1.Active := True;
  S1ServerID.Text := IntToStr(MsgServer1.ServerID);
  S1Host.Text := MsgServer1.LocalHost;
  S1Port.Text := IntToStr(MsgServer1.LocalPort);

  MsgServer2.Active := True;
  S2ServerID.Text := IntToStr(MsgServer2.ServerID);
  S2Host.Text := MsgServer2.LocalHost;
  S2Port.Text := IntToStr(MsgServer2.LocalPort);
end;

end.
