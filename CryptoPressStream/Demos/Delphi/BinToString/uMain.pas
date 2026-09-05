unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, CPSMain;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    rgFormats: TRadioGroup;
    bnStringToFormat: TButton;
    bnFormatToString: TButton;
    Button1: TButton;
    GroupBox1: TGroupBox;
    reSource: TRichEdit;
    GroupBox2: TGroupBox;
    reEncoded: TRichEdit;
    GroupBox3: TGroupBox;
    reDecoded: TRichEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    tSize: TEdit;
    tEncodedSize: TEdit;
    tEncodingTime: TEdit;
    tDecodingTime: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnStringToFormatClick(Sender: TObject);
    procedure bnFormatToStringClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    Buffer: PChar;
    Size:   Integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:  Integer;
    fs: TFileStream;
    s:  String;
begin
 fs := TFileStream.Create(Application.ExeName,fmOpenRead or fmShareDenyNone);
 Size := fs.Size;
 GetMem(Buffer,Size);
 fs.ReadBuffer(Buffer^,Size);
 fs.Free;
 SetLength(s,Size);
 Move(Buffer^,PChar(s)^,Size);
 reSource.Text := s;
 tSize.Text := IntToStr(Size);
 rgFormats.Items.Clear;
 for i := Low(CPSStringFormatNames) to High(CPSStringFormatNames) do
  rgFormats.Items.Add(CPSStringFormatNames[i]);
 rgFormats.ItemIndex := 0;
end;

procedure TForm1.bnStringToFormatClick(Sender: TObject);
var t: Cardinal;
begin
 t := GetTickCount;
 reEncoded.Text := CPSManager1.BufferToFormat(Buffer,Size,TCPSStringFormat(rgFormats.ItemIndex));
 tEncodingTime.Text := IntToStr(GetTickCount - t);
 tEncodedSize.Text := IntToStr(Length(reEncoded.Text));
 bnFormatToString.Enabled := True;
end;


procedure TForm1.bnFormatToStringClick(Sender: TObject);
var DecodedBuffer:  PChar;
    DecodedSize,i:  Integer;
    s:              String;
    t:              Cardinal;
begin
 t := GetTickCount;
 CPSManager1.FormatToBuffer(reEncoded.Text,TCPSStringFormat(rgFormats.ItemIndex),
                            DecodedBuffer,DecodedSize);
 tDecodingTime.Text := IntToStr(GetTickCount - t);
 try
   if (DecodedSize <> Size) then
    begin
     MessageDlg('Error - decoded size is not equal to source buffer size',mtError,[mbOK],0);
     Exit;
    end;
   SetLength(s,DecodedSize);
   Move(DecodedBuffer^,PChar(s)^,DecodedSize);
   reDecoded.Text := s;
   for i := 0 to Size-1 do
    if (PChar(Buffer+i)^ <> PChar(DecodedBuffer+i)^) then
     begin
      MessageDlg('Error - decoded buffer is not equal to source buffer',mtError,[mbOK],0);
      break;
     end;
 finally
   FreeMem(DecodedBuffer);
 end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FreeMem(Buffer);
end;

end.
