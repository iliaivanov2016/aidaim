unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, CPSMain, CPSCrypto;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    Panel1: TPanel;
    Label1: TLabel;
    reLog: TRichEdit;
    bnSave: TButton;
    bnClose: TButton;
    bnLoad: TButton;
    procedure bnCloseClick(Sender: TObject);
    procedure bnSaveClick(Sender: TObject);
    procedure bnLoadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
const TestFileName = 'test.cps';

implementation

{$R *.DFM}

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close();
 Application.Terminate;
end;

procedure TForm1.bnSaveClick(Sender: TObject);
var fs:  TCPSCryptoPressFileStream;
    buf: array [1..10000] of Byte;
    sh:  ShortString;
    s:   AnsiString;
    ws:  WideString;
    i:   Integer;
    i64: Int64;
    c:   Cardinal;
    b:   Boolean;
begin
 FillChar(buf[1],sizeOf(buf),$FF);
 sh := 'Test ShortString';
 s := 'Test AnsiString';
 ws := 'Test WideString';
 i := Random(MaxInt);
 i64 := Int64(Random(MaxInt))*Int64(i);
 c := CPSCountCRC(0,@buf[1],SizeOf(buf));
 b := True;
 reLog.Lines.Clear;
 fs := CPSManager1.CreateCryptoPressFileStream(TestFileName,fmCreate);
 try
   fs.SaveData(buf[1],SizeOf(buf),20001);
   fs.SaveShortString(sh,20002);
   fs.SaveAnsiString(s,20003);
   fs.SaveWideString(ws,20004);
   fs.SaveInteger(i,20005);
   fs.SaveInt64(i64,20006);
   fs.SaveCardinal(c,20007);
   fs.SaveBoolean(b,20008);
   reLog.Lines.Add('Data saved. Size = '+IntToStr(fs.Size)+#13#10+'Compressed size = '+IntToStr(fs.CompressedSize)+
            #13#10+'Rate = '+FormatFloat('###.##',fs.Ratio));
 finally
   fs.Free;
   bnLoad.Enabled := True;
 end;
end;

procedure TForm1.bnLoadClick(Sender: TObject);
var fs:   TCPSCryptoPressFileStream;
    buf:  array [1..10000] of Byte;
    sh:   ShortString;
    s:    AnsiString;
    ws:   WideString;
    i:    Integer;
    i64:  Int64;
    c,c1: Cardinal;
    b:    Boolean;
begin
 // random data to check if buffer loaded successfully
 CPSGenerateRandomBuffer(@buf[1],SizeOf(buf));
 fs := CPSManager1.CreateCryptoPressFileStream(TestFileName,fmOpenRead);
 reLog.Lines.Clear;
 try
   fs.LoadData(buf[1],SizeOf(buf),21001);
   fs.LoadShortString(sh,21002);
   reLog.Lines.Add('sh = '+sh);
   fs.LoadAnsiString(s,21003);
   reLog.Lines.Add('s = '+s);
   fs.LoadWideString(ws,21004);
   reLog.Lines.Add('ws = '+ws);
   fs.LoadInteger(i,21005);
   reLog.Lines.Add('i = '+IntToStr(i));
   fs.LoadInt64(i64,21006);
   reLog.Lines.Add('i64 = '+IntToStr(i64));
   fs.LoadCardinal(c,21007);
   fs.LoadBoolean(b,21008);
   if (b) then
    reLog.Lines.Add('b = True')
   else
    reLog.Lines.Add('b = False');
   c1 := CPSCountCRC(0,@buf[1],SizeOf(buf));
   if (c1 <> c) then
    reLog.Lines.Add('CRC32 error. '+#13#10+'c1 = '+IntToHex(c1,8)
      +#13#10+'c = '+IntToHex(c,8))
   else
    reLog.Lines.Add('CRC32 OK. '+#13#10+'c1 = '+IntToHex(c1,8)
      +#13#10+'c = '+IntToHex(c,8));
 finally
   fs.Free;
 end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 bnLoad.Enabled := SysUtils.FileExists(TestFileName);
end;


end.
