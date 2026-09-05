unit uMain;

interface

{$I cpsdemo_ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, CPSMain, FileCtrl;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
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
var ws:  widestring;
    cfs: TCPSCryptoPressFileStream;
begin
  SetLength(ws,4);
  ws[1] := #$8DC4;
  ws[2] := #$87C4;
  ws[3] := #$BEC5;
  ws[4] := #$A1C5;
  {$IFDEF D6H}
  cfs := CPSManager1.CreateCryptoPressFileStream(ws,fmCreate);
  {$ELSE}
  cfs := CPSManager1.CreateCryptoPressFileStream(ws,fmCreate,false);
  {$ENDIF}
  try
   cfs.LoadFromFile(ParamStr(0));
   ShowMessage('Compressed size = '+IntToStr(cfs.DirectAccessStream.Size));
  finally
   cfs.Free;
  end;
  Close;
  Application.Terminate;
end;

end.
