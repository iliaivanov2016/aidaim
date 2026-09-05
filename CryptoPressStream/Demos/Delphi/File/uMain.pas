unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, CPSMain, StdCtrls, Gauges, ExtCtrls, Buttons;

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
    Gauge1: TGauge;
    bnAbort: TBitBtn;
    edFileName: TEdit;
    bnBrowse: TButton;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure rgCryptoClick(Sender: TObject);
    procedure rgCompressionClick(Sender: TObject);
    procedure bnCompressClick(Sender: TObject);
    procedure bnDecompressClick(Sender: TObject);
    procedure bnAbortClick(Sender: TObject);
    procedure CPSManager1Progress(Sender: TObject; Progress: Double;
      Operation: TCPSOperation; var Abort: Boolean);
    procedure bnBrowseClick(Sender: TObject);
  private
    { Private declarations }
    FAbort: Boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var i: Integer;
begin
 edFileName.Text := Application.ExeName;
 OpenDialog1.FileName := Application.ExeName;

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
    compSize,Size: Int64;
    fs: TFileStream;
    newName: String;
begin
 FAbort := False;
 CPSManager1.CompressionAlgorithm := TCPSCompressionAlgorithm(rgCompression.ItemIndex);
 CPSManager1.CompressionMode := cbCompression.ItemIndex+1;
 CPSManager1.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(rgCrypto.ItemIndex);
 CPSManager1.CryptoParams.CryptoMode := TCPSCryptoMode(cbCrypto.ItemIndex);
 CPSManager1.CryptoParams.Password := edPassword.Text;
 t := GetTickCount;
 fs := TFileStream.Create(edFileName.Text,fmOpenRead or fmShareDenyNone);
 try
   Size := fs.Size;
 finally
   fs.Free;
 end;
 newName := ChangeFileExt(edFileName.Text,'.cps');
 CPSManager1.CompressFile(edFileName.Text,NewName);
 edCompTime.Text := IntToStr(GetTickCount-t);
 fs := TFileStream.Create(NewName,fmOpenRead or fmShareDenyNone);
 try
   CompSize := fs.Size;
 finally
   fs.Free;
 end;
 edSize.Text := IntToStr(Size);
 edCompSize.Text := IntToStr(CompSize);
 d := (Size - compSize) / Size * 100.0;
 edCompRate.Text := FormatFloat('0.00',d)+' %';
 bnDecompress.Enabled := True;
end;

procedure TForm1.bnDecompressClick(Sender: TObject);
var t: Cardinal;
    newName: String;
begin
 FAbort := False;
 CPSManager1.CryptoParams.Password := edPassword.Text;
 newName := ChangeFileExt(edFileName.Text,'.src');
 t := GetTickCount;
 CPSManager1.DecompressFile(ChangeFileExt(edFileName.Text,'.cps'),newName);
 edDecompTime.Text := IntToStr(GetTickCount-t);
end;

procedure TForm1.bnAbortClick(Sender: TObject);
begin
 FAbort := True;
 Application.ProcessMessages;
end;

procedure TForm1.CPSManager1Progress(Sender: TObject; Progress: Double;
  Operation: TCPSOperation; var Abort: Boolean);
begin
 Gauge1.Progress := Round(Progress);
 Abort := FAbort;
end;

procedure TForm1.bnBrowseClick(Sender: TObject);
begin
 if (OpenDialog1.Execute) then
   edFileName.Text := OpenDialog1.FileName;
end;

end.
