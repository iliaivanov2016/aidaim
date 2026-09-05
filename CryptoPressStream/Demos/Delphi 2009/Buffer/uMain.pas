unit uMain;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, CPSMain, StdCtrls, Gauges, ExtCtrls;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    bnCompress: TButton;
    Label1: TLabel;
    edCompRate: TEdit;
    Label2: TLabel;
    edCompTime: TEdit;
    Label3: TLabel;
    edDecompTime: TEdit;
    bnDecompress: TButton;
    Button3: TButton;
    rgCompression: TRadioGroup;
    cbCompression: TComboBox;
    Label4: TLabel;
    Label5: TLabel;
    edSize: TEdit;
    Label6: TLabel;
    edPassword: TEdit;
    rgCrypto: TRadioGroup;
    edCompSize: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    cbCrypto: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure rgCryptoClick(Sender: TObject);
    procedure rgCompressionClick(Sender: TObject);
    procedure bnCompressClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnDecompressClick(Sender: TObject);
  private
    { Private declarations }
    Buffer,CompBuffer: PAnsiChar;
    Size,CompSize: Integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var i:  Integer;
    fs: TFileStream;
begin
 CompBuffer := nil;
 cbCompression.Items.Clear;
 for i := Low(CPSCompressionModeNames) to High(CPSCompressionModeNames) do
  cbCompression.Items.Add(CPSCompressionModeNames[i]);
 cbCompression.ItemIndex := 5;

 cbCrypto.Items.Clear;
 for i := Low(CPSCryptoModeNames) to High(CPSCryptoModeNames) do
  cbCrypto.Items.Add(CPSCryptoModeNames[i]);
 cbCrypto.ItemIndex := 0;

 rgCompression.Items.Clear;
 for i := Low(CPSCompressionAlgorithmNames) to High(CPSCompressionAlgorithmNames) do
  rgCompression.Items.Add(CPSCompressionAlgorithmNames[i]);
 rgCompression.ItemIndex := 1;

 rgCrypto.Items.Clear;
 for i := Low(CPSCryptoAlgorithmNames) to High(CPSCryptoAlgorithmNames) do
  rgCrypto.Items.Add(CPSCryptoAlgorithmNames[i]);
 rgCrypto.ItemIndex := 2;

 fs := TFileStream.Create(Application.ExeName,fmOpenRead or fmShareDenyNone);
 try
   Size := fs.Size;
   GetMem(Buffer,Size);
   edSize.Text := IntToStr(Size);
   fs.ReadBuffer(Buffer^,Size);
 finally
   fs.Free;
 end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.rgCryptoClick(Sender: TObject);
begin
 if (rgCrypto.ItemIndex = 0) then
  begin
   cbCrypto.Enabled := False;
   edPassword.Enabled := False;
  end
 else
  begin
   cbCrypto.Enabled := True;
   edPassword.Enabled := True;
  end;
end;

procedure TForm1.rgCompressionClick(Sender: TObject);
begin
 if (rgCompression.ItemIndex = 0) then
  begin
   cbCompression.Enabled := False;
  end
 else
  begin
   cbCompression.Enabled := True;
  end;
end;

procedure TForm1.bnCompressClick(Sender: TObject);
var t: Cardinal;
    d: Double;
begin
 if (CompBuffer <> nil) then
  FreeMem(CompBuffer);
 CPSManager1.CompressionAlgorithm := TCPSCompressionAlgorithm(rgCompression.ItemIndex);
 CPSManager1.CompressionMode := cbCompression.ItemIndex+1;
 CPSManager1.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(rgCrypto.ItemIndex);
 CPSManager1.CryptoParams.CryptoMode := TCPSCryptoMode(cbCrypto.ItemIndex);
 CPSManager1.CryptoParams.Password := edPassword.Text;
 t := GetTickCount;
 CPSManager1.CompressBuffer(Buffer,Size,CompBuffer,CompSize);
 edCompTime.Text := IntToStr(GetTickCount-t);
 edCompSize.Text := IntToStr(CompSize);
 d := (Size - compSize) / Size * 100.0;
 edCompRate.Text := FormatFloat('0.00',d)+' %';
 bnDecompress.Enabled := True;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (CompBuffer <> nil) then
  FreeMem(CompBuffer);
 FreeMem(Buffer);
end;

procedure TForm1.bnDecompressClick(Sender: TObject);
var t: Cardinal;
    i: Integer;
    DecompBuffer: PAnsiChar;
    DecompSize: Integer;
begin
 CPSManager1.CryptoParams.Password := edPassword.Text;
 t := GetTickCount;
 CPSManager1.DecompressBuffer(CompBuffer,CompSize,DecompBuffer,DecompSize);
 edDecompTime.Text := IntToStr(GetTickCount-t);
 if (DecompSize <> Size) then
  MessageDlg('Error - invalid decompression size',mtError,[mbOk],0);
 for i := 0 to Size -  1 do
  if (PAnsiChar(Buffer+i)^ <> PAnsiChar(DecompBuffer+i)^) then
   begin
    MessageDlg('Error - invalid decompression buffer',mtError,[mbOk],0);
    break;
   end;
 FreeMem(DecompBuffer);
end;

end.
