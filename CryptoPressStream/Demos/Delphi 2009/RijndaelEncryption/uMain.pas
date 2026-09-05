////////////////////////////////////////////////////////////////////////////////
//
// (c) AidAim Software, 2009.
// http://www.aidaim.com
//
// All test data is exactly same as in the NIST specification:
// http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
// page 27-29, mode CBC
//
////////////////////////////////////////////////////////////////////////////////

unit uMain;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CPSMain;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    bn128: TButton;
    bnExit: TButton;
    Button1: TButton;
    Button2: TButton;
    FCPSManager: TCPSManager;
    procedure bnExitClick(Sender: TObject);
    procedure bn128Click(Sender: TObject);
    procedure ShowError(msg: String);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  IV      : packed array [0..15] of Byte =
($00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f); //IV
  SRC     : packed array [0..15] of Byte = ($6b, $c1, $be, $e2, $2e, $40, $9f,
$96, $e9, $3d, $7e, $11, $73, $93, $17, $2a);
//128 bit
KEY_128     : packed array [0..15] of Byte = ($2b, $7e, $15, $16, $28, $ae, $d2,
$a6, $ab, $f7, $15, $88, $09, $cf, $4f, $3c);
ENC_128     : packed array [0..15] of Byte = ($76, $49, $ab, $ac, $81, $19, $b2,
$46, $ce, $e9, $8e, $9b, $12, $e9, $19, $7d);
 //192 bit
KEY_192     : packed array [0..23] of Byte = ($8e, $73, $b0, $f7, $da, $0e, $64,
$52, $c8, $10, $f3, $2b, $80, $90, $79, $e5, $62, $f8, $ea, $d2, $52, $2c, $6b, $7b);
ENC_192     : packed array [0..15] of Byte = ($4f, $02, $1d, $b2, $43, $bc, $63,
$3d, $71, $78, $18, $3a, $9f, $a0, $71, $e8);
 //256 bit
KEY_256 : packed array [0..31] of Byte =
($60,$3d,$eb,$10,$15,$ca,$71,$be,$2b,$73,$ae,$f0,$85,$7d,$77,$81,$1f,$35,$2c,
 $07,$3b,$61,$08,$d7,$2d,$98,$10,$a3,$09,$14,$df,$f4); //Key
ENC_256     : packed array [0..15] of Byte = ($f5, $8c, $4c, $04, $d6, $e5, $f1,
$ba, $77, $9e, $ab, $fb, $5f, $7b, $fb, $d6);

implementation

{$R *.dfm}

procedure TForm1.bnExitClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.bn128Click(Sender: TObject);
var
    OUT_BUF:   PAnsiChar;
    OUT_SIZE:  Integer;
    OUT_BUF2:  PAnsiChar;
    OUT_SIZE2: Integer;
    i:         Integer;
begin
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_128;
 FCPSManager.CryptoParams.CryptoMode := acmCBC;
 FCPSManager.CryptoParams.SetKey(@KEY_128[0],Length(KEY_128));
 FCPSManager.CryptoParams.SetInitVector(@IV[0],Length(IV));
 // encrypt test data
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE,True);
 if (OUT_SIZE <> LENGTH(SRC)) then
  ShowError('Error - invalid OUT_SIZE = '+IntToStr(OUT_SIZE))
 else
  begin
   // compare encrypted data with data from NIST specification
   for i := 0 to High(ENC_128) do
    if (pByte(OUT_BUF+i)^ <> ENC_128[i]) then
     begin
      ShowError('Error, CBC 128 encryption, i = '+IntToStr(i)+
        #13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_128[i],2));
      Exit;
     end;
   // decrypt test data
   FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2,True);
   if (OUT_SIZE <> OUT_SIZE2) then
    ShowError('Error, invalid OUT_SIZE2 = '+IntToStr(OUT_SIZE2))
   else
    begin
     for i := 0 to High(SRC) do
      if (pByte(OUT_BUF2+i)^ <> SRC[i]) then
       begin
        ShowError('Error, CBC 128 decryption, i = '+IntToStr(i)
          +#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_128[i],2));
        Exit;
       end;
     ShowMessage('CBC 128 key encryption - OK!');
    end;
  end;
end;

procedure TForm1.ShowError(msg: String);
begin
  MessageDlg(msg,mtError,[mbOK],0);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
    OUT_BUF:   PAnsiChar;
    OUT_SIZE:  Integer;
    OUT_BUF2:  PAnsiChar;
    OUT_SIZE2: Integer;
    i:         Integer;
begin
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_128;
 FCPSManager.CryptoParams.CryptoMode := acmCBC;
 FCPSManager.CryptoParams.SetKey(@KEY_192[0],Length(KEY_192));
 FCPSManager.CryptoParams.SetInitVector(@IV[0],Length(IV));
 // encrypt test data
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE,True);
 if (OUT_SIZE <> LENGTH(SRC)) then
  ShowError('Error - invalid OUT_SIZE = '+IntToStr(OUT_SIZE))
 else
  begin
   // compare encrypted data with data from NIST specification
   for i := 0 to High(ENC_192) do
    if (pByte(OUT_BUF+i)^ <> ENC_192[i]) then
     begin
      ShowError('Error, CBC 192 encryption, i = '+IntToStr(i)+
        #13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_192[i],2));
      Exit;
     end;
   // decrypt test data
   FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2,True);
   if (OUT_SIZE <> OUT_SIZE2) then
    ShowError('Error, invalid OUT_SIZE2 = '+IntToStr(OUT_SIZE2))
   else
    begin
     for i := 0 to High(SRC) do
      if (pByte(OUT_BUF2+i)^ <> SRC[i]) then
       begin
        ShowError('Error, CBC 192 decryption, i = '+IntToStr(i)
          +#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_192[i],2));
        Exit;
       end;
     ShowMessage('CBC 192 key encryption - OK!');
    end;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
    OUT_BUF:   PAnsiChar;
    OUT_SIZE:  Integer;
    OUT_BUF2:  PAnsiChar;
    OUT_SIZE2: Integer;
    i:         Integer;
begin
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
 FCPSManager.CryptoParams.CryptoMode := acmCBC;
 FCPSManager.CryptoParams.SetKey(@KEY_256[0],Length(KEY_256));
 FCPSManager.CryptoParams.SetInitVector(@IV[0],Length(IV));
 // encrypt test data
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE,True);
 if (OUT_SIZE <> LENGTH(SRC)) then
  ShowError('Error - invalid OUT_SIZE = '+IntToStr(OUT_SIZE))
 else
  begin
   // compare encrypted data with data from NIST specification
   for i := 0 to High(ENC_256) do
    if (pByte(OUT_BUF+i)^ <> ENC_256[i]) then
     begin
      ShowError('Error, CBC 256 encryption, i = '+IntToStr(i)+
        #13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_256[i],2));
      Exit;
     end;
   // decrypt test data
   FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2,True);
   if (OUT_SIZE <> OUT_SIZE2) then
    ShowError('Error, invalid OUT_SIZE2 = '+IntToStr(OUT_SIZE2))
   else
    begin
     for i := 0 to High(SRC) do
      if (pByte(OUT_BUF2+i)^ <> SRC[i]) then
       begin
        ShowError('Error, CBC 256 decryption, i = '+IntToStr(i)
          +#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_256[i],2));
        Exit;
       end;
     ShowMessage('CBC 256 key encryption - OK!');
    end;
  end;
end;

end.
