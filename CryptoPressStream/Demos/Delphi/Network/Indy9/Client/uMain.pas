unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, CPSMain, StdCtrls, ComCtrls, ExtCtrls, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdIOHandler,
  IdIOHandlerStream, IdAntiFreezeBase, IdAntiFreeze;

type
  TForm1 = class(TForm)
    IdTCPClient1: TIdTCPClient;
    Panel1: TPanel;
    RichEdit1: TRichEdit;
    bnSend: TButton;
    bnClose: TButton;
    CPSManager1: TCPSManager;
    Label1: TLabel;
    IdAntiFreeze1: TIdAntiFreeze;
    procedure bnCloseClick(Sender: TObject);
    procedure bnSendClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.bnSendClick(Sender: TObject);
var ms:  TCPSMemoryStream;
    cs:  TCPSCryptoPressMemoryStream;
begin
  bnSend.Enabled := False;
  // create memory stream if we need to save multiple values
  ms := TCPSMemoryStream.Create;
  try
    ms.SaveString('Some String Data',20001);
    ms.SaveInteger(Integer(Self),20002);
    RichEdit1.Lines.SaveToStream(ms);
    ms.Position := 0;
    cs := CPSManager1.CreateCryptoPressMemoryStream;
    try
      cs.WriteBuffer(ms.Memory^,ms.Size);
      cs.ClearCache;
      cs.DirectAccessStream.Position := 0;
      IdTCPClient1.Connect;
      while IdTCPClient1.Connected do
       begin
        IdTCPClient1.OpenWriteBuffer;
        IdTCPClient1.WriteStream(cs.DirectAccessStream);
        IdTCPClient1.CloseWriteBuffer;
        IdTCPClient1.Disconnect;
       end;
    finally
      ShowMessage('Data sent. Size = '+IntToStr(cs.Size)+#13#10+'Compressed size = '+IntToStr(cs.CompressedSize)+
                  #13#10+'Rate = '+FormatFloat('###.##',cs.Ratio));
      cs.Free;
    end;
  finally
    ms.Free;
    bnSend.Enabled := True;
  end;
end;

end.
