unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IdBaseComponent, IdComponent, IdTCPServer, CPSMain, StdCtrls, ComCtrls,
  ExtCtrls;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    IdTCPServer1: TIdTCPServer;
    Panel1: TPanel;
    Label1: TLabel;
    RichEdit1: TRichEdit;
    bnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure IdTCPServer1Execute(AThread: TIdPeerThread);
    procedure bnCloseClick(Sender: TObject);
  private
    { Private declarations }
    cs: TCPSCryptoPressMemoryStream;
  public
    procedure ReadData;
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
begin
 cs := nil;
 IdTCPServer1.Active := True;
end;

procedure TForm1.IdTCPServer1Execute(AThread: TIdPeerThread);
begin
 cs := CPSManager1.CreateCryptoPressMemoryStream;
 try
   cs.DirectAccessStream.Size := 0;
   cs.DirectAccessStream.Position := 0;
   // receive compressed and encrypted stream
   AThread.Connection.ReadStream(cs.DirectAccessStream,-1,True);
   // load all headers - prepare stream for reading data
   cs.Refresh;
   AThread.Synchronize(Self.ReadData);
 finally
   AThread.Connection.Disconnect;
   cs.Free;
 end;
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
   end;
end;

end.
