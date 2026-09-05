unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IdBaseComponent, IdComponent, IdTCPServer, CPSMain, StdCtrls, ComCtrls,
  ExtCtrls, MsgComBase, MsgServer;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    Panel1: TPanel;
    Label1: TLabel;
    RichEdit1: TRichEdit;
    bnClose: TButton;
    MsgServer1: TMsgServer;
    procedure FormCreate(Sender: TObject);
    procedure bnCloseClick(Sender: TObject);
    procedure MsgServer1ReceiveStreamMessage(const FromUserID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; Stream: TStream);
  private
    { Private declarations }
    cs: TCPSCryptoPressMemoryStream;
    FReceived: Boolean;
  public
    procedure ReadData;
    { Public declarations }
  end;

  TShowDataThread = class (TThread)
   private
    FForm: TForm1;
   public
    constructor Create(aForm: TForm1);
    procedure ReadData;
    procedure Execute; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
var ui: TMsgUserInfo;
begin
 cs := nil;
 MsgServer1.Active := True;
 FillChar(ui,SizeOf(ui),$00);
 ui.UserID := 1;
 ui.UserName := 'test';
 if (not MsgServer1.IsUserExisting(1)) then
  MsgServer1.InsertUser(ui,'');
end;

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.ReadData;
var s: String;
    i: Integer;
begin
 FReceived := False;
 if (cs <> nil) then
  begin
    cs.LoadString(s,20001);
    cs.LoadInteger(i,20002);
    RichEdit1.Lines.LoadFromStream(cs);
    cs.Size := cs.Position;
    Application.ProcessMessages;
    ShowMessage('Data received. Size = '+IntToStr(cs.Size)
                +#13#10+'Compressed size = '+IntToStr(cs.CompressedSize)
                +#13#10+'Rate = '+FormatFloat('###.##',cs.Ratio)
                +#13#10+'String = '+s
                +#13#10+'Integer = '+IntToStr(i));
    FReceived := True;
   end;
end;

procedure TForm1.MsgServer1ReceiveStreamMessage(const FromUserID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; Stream: TStream);
var th: TShowDataThread;
begin
 cs := CPSManager1.CreateCryptoPressMemoryStream;
 try
   cs.DirectAccessStream.Size := 0;
   cs.DirectAccessStream.Position := 0;
   // receive compressed and encrypted stream
   TCPSMemoryStream(cs.DirectAccessStream).LoadFromStream(Stream);
   // load all headers - prepare stream for reading data
   cs.Refresh;
   th := TShowDataThread.Create(Self);
   th.Resume;
   while (not FReceived) do
    begin
     sleep(100);
     Application.ProcessMessages;
    end;
 finally
   cs.Free;
 end;
end;

{ TShowDataThread }

constructor TShowDataThread.Create(aForm: TForm1);
begin
 FForm := aForm;
end;

procedure TShowDataThread.Execute;
begin
  Synchronize(ReadData);
end;

procedure TShowDataThread.ReadData;
begin
 FForm.ReadData;
end;

end.
