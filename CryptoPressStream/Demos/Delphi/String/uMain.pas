unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, CPSMain, StdCtrls, Gauges, ExtCtrls, ComCtrls;

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
    reText: TRichEdit;
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure rgCryptoClick(Sender: TObject);
    procedure rgCompressionClick(Sender: TObject);
    procedure bnCompressClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnDecompressClick(Sender: TObject);
  private
    { Private declarations }
    Str: String;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var i:  Integer;
begin
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

 reText.Lines.LoadFromFile('uMain.pas');
 edSize.Text := IntToStr(Length(reText.Text));
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
 CPSManager1.CompressionAlgorithm := TCPSCompressionAlgorithm(rgCompression.ItemIndex);
 CPSManager1.CompressionMode := cbCompression.ItemIndex+1;
 CPSManager1.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(rgCrypto.ItemIndex);
 CPSManager1.CryptoParams.CryptoMode := TCPSCryptoMode(cbCrypto.ItemIndex);
 CPSManager1.CryptoParams.Password := edPassword.Text;
 t := GetTickCount;
 Str := CPSManager1.CompressString(reText.Text);
 edCompTime.Text := IntToStr(GetTickCount-t);
 edCompSize.Text := IntToStr(Length(Str));
 d := (Length(reText.Text) - Length(Str)) / Length(reText.Text) * 100.0;
 edCompRate.Text := FormatFloat('0.00',d)+' %';
 bnDecompress.Enabled := True;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Str := '';
end;

procedure TForm1.bnDecompressClick(Sender: TObject);
var t: Cardinal;
    s: String;
begin
 CPSManager1.CryptoParams.Password := edPassword.Text;
 t := GetTickCount;
 s := CPSManager1.DecompressString(Str);
 edDecompTime.Text := IntToStr(GetTickCount-t);
 if (s <> reText.Text) then
  MessageDlg('Error - decompressed string "'+s+'" does not match source string',mtError,[mbOk],0);
end;

end.
