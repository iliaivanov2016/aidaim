unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, CPSMain, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    Label1: TLabel;
    bnRunTest: TButton;
    bnClose: TButton;
    reLog: TRichEdit;
    procedure bnCloseClick(Sender: TObject);
    procedure bnRunTestClick(Sender: TObject);
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

procedure TForm1.bnRunTestClick(Sender: TObject);
const TestCount = 10000; // 10 MB
const TestSize = 1024;
var t1,t2: Cardinal;
    ms:    TMemoryStream;
    cms:   TCPSMemoryStream;
    i:     Integer;
    buf:   array [0..TestSize-1] of Byte;
begin
  // fill test buffer with pseudorandom data
  for i := 0 to TestSize-1 do
   buf[1] := Random(MaxInt) mod 256;
  reLog.Lines.Text := 'Test initialized!';
  Application.ProcessMessages;
  bnRunTest.Enabled := False;
  try
    // test TCPSMemoryStream
    t1 := GetTickCount;
    cms := CPSManager1.CreateMemoryStream;
    try
      for i := 1 to TestCount do
       cms.WriteBuffer(buf[0],TestSize);
    finally
      cms.Free;
    end;
    t1 := GetTickCount-t1;
    reLog.Lines.Add('TCPSMemoryStream time, ms = '+IntToStr(t1));
    reLog.Lines.Add('TestCount = '+IntToStr(TestCount));
    Application.ProcessMessages;
    // test TMemoryStream
    t2 := GetTickCount;
    ms := TMemoryStream.Create;
    try
      for i := 1 to TestCount do
       ms.WriteBuffer(buf[0],TestSize);
    finally
      ms.Free;
    end;
    t2 := GetTickCount-t2;
    reLog.Lines.Add('TMemoryStream time, ms = '+IntToStr(t2));
    reLog.Lines.Add('TestCount = '+IntToStr(TestCount));
    Application.ProcessMessages;
  finally
    bnRunTest.Enabled := True;
  end;
end;

end.
