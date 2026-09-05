unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Gauges, ComCtrls, CPSMain, Buttons;

type
  TfmMain = class(TForm)
    CPSManager1: TCPSManager;
    reLog: TRichEdit;
    Gauge1: TGauge;
    bnFileStream: TButton;
    bnMemoryStream: TButton;
    Button3: TButton;
    bnClose: TButton;
    Label1: TLabel;
    reText: TRichEdit;
    Label2: TLabel;
    lbOperation: TLabel;
    bnAbort: TBitBtn;
    procedure Button3Click(Sender: TObject);
    procedure bnCloseClick(Sender: TObject);
    procedure CPSManager1Progress(Sender: TObject; Progress: Double;
      Operation: TCPSOperation; var Abort: Boolean);
    procedure bnAbortClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnMemoryStreamClick(Sender: TObject);
    procedure bnFileStreamClick(Sender: TObject);
  private
    { Private declarations }
    FAbort : Boolean;
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

const Description = 'Stream Description';

implementation

{$R *.dfm}

procedure TfmMain.Button3Click(Sender: TObject);
var fs:     TFileStream;
    cs:     TCPSCryptoPressStream;
    t:      Cardinal;
    d:      Double;
    sz,csz: Int64;
begin
 FAbort := False;
 Gauge1.Progress := 0;
 reLog.Lines.Add('CryptoPressStream with TFileStream...');
 Application.ProcessMessages;
 t := GetTickCount;
 fs := TFileStream.Create('test_cps_stream.dat',fmCreate);
 cs := CPSManager1.CreateCryptoPressStream(fs,True,True,PChar(Description),Length(Description));
 reText.Lines.SaveToStream(cs);
 d := cs.Ratio;
 csz := cs.CompressedSize;
 sz := cs.Size;
 cs.Free; // no need in calling fs.Free as we forced CryptoPressStream to free base stream on destroy
 t := GetTickCount - t;
 reLog.Lines.Add('Size = '+IntToStr(sz));
 reLog.Lines.Add('Compressed Size = '+IntToStr(csz));
 reLog.Lines.Add('Ratio = '+FormatFloat('0.00',d));
 reLog.Lines.Add('Compression Time, ms = '+IntToStr(t));

 t := GetTickCount;
 fs := TFileStream.Create('test_cps_stream.dat',fmOpenRead);
 cs := CPSManager1.CreateCryptoPressStream(fs);
 reText.Lines.LoadFromStream(cs);
 cs.Free; // no need in calling fs.Free as we forced CryptoPressStream to free base stream on destroy
 t := GetTickCount - t;
 reLog.Lines.Add('Decompression Time, ms = '+IntToStr(t));

 reLog.Lines.Add('CryptoPressStream with TFileStream... OK'+#13#10);
 Application.ProcessMessages;
end;

procedure TfmMain.bnCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TfmMain.CPSManager1Progress(Sender: TObject; Progress: Double;
  Operation: TCPSOperation; var Abort: Boolean);
begin
 if (Operation in [cpsopLoadFromStream,cpsopSaveToStream]) then
  begin
   Gauge1.Progress := TRUNC(Progress);
   Abort := FAbort;
   case Operation of
     cpsopLoadFromStream: lbOperation.Caption := 'LoadFromStream';
     cpsopSaveToStream: lbOperation.Caption := 'SaveToStream';
    end;
   Application.ProcessMessages;
  end;
end;

procedure TfmMain.bnAbortClick(Sender: TObject);
begin
 FAbort := True;
 Application.ProcessMessages;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
 reText.Lines.Clear;
 reText.Lines.LoadFromFile('uMain.pas');
end;

procedure TfmMain.bnMemoryStreamClick(Sender: TObject);
var ms: TCPSCryptoPressMemoryStream;
    fs: TCPSFileStream;
    t:  Cardinal;
    d:      Double;
    sz,csz: Int64;
begin
 fs := TCPSFileStream.Create(Application.ExeName,fmOpenRead or fmShareDenyNone);
 try
   ms := CPSManager1.CreateCryptoPressMemoryStream();
   t := GetTickCount;
   ms.LoadFromStream(fs);
   t := GetTickCount - t;
   d := ms.Ratio;
   csz := ms.CompressedSize;
   sz := ms.Size;
   reLog.Lines.Add('Size = '+IntToStr(sz));
   reLog.Lines.Add('Compressed Size = '+IntToStr(csz));
   reLog.Lines.Add('Ratio = '+FormatFloat('0.00',d));
   reLog.Lines.Add('Compression Time, ms = '+IntToStr(t));
   ms.Free;
 finally
   fs.Free;
 end;
end;

procedure TfmMain.bnFileStreamClick(Sender: TObject);
var fs1: TCPSCryptoPressFileStream;
    fs: TCPSFileStream;
    t:  Cardinal;
    d:      Double;
    sz,csz: Int64;
begin
 fs := TCPSFileStream.Create(Application.ExeName,fmOpenRead or fmShareDenyNone);
 try
   fs1 := CPSManager1.CreateCryptoPressFileStream('test.dat',fmCreate);
   t := GetTickCount;
   fs1.LoadFromStream(fs);
   t := GetTickCount - t;
   d := fs1.Ratio;
   csz := fs1.CompressedSize;
   sz := fs1.Size;
   reLog.Lines.Add('Size = '+IntToStr(sz));
   reLog.Lines.Add('Compressed Size = '+IntToStr(csz));
   reLog.Lines.Add('Ratio = '+FormatFloat('0.00',d));
   reLog.Lines.Add('Compression Time, ms = '+IntToStr(t));
   fs1.Free;
 finally
   fs.Free;
 end;end;

end.
