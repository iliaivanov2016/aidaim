unit utEncryption;

interface

{$I CPSVer.Inc}

// compare with v.1.
{DEFINE SKIP_ENCODE}

uses uTestList, SysUtils,
Classes,
CPSMain, CPSCompression, CPSDebug, CPSConst, CPSCrypto
{$IFDEF ENCRYPTION_DEC5}
,CPSDecHash, CPSDecCipher, CPSDecUtil
{$ELSE}
,CPSHash,CPSCipher,CPSCipher1,CPSDecUtil
{$ENDIF}
,CPSMemory;

type
  TUnitTestEncryption = class(TUnitTest)
   private
    FCPSManager: TCPSManager;
    FBuf_src:    PAnsiChar;
    FBuf_enc:    PAnsiChar;
    FBuf_dec:    PAnsiChar;
    FSize:       Cardinal;
   protected
    function CompareBuf: Integer;
    procedure DoTestEncode(var Num: Integer);
    procedure TestEncode;
    procedure DoTestDecode(var Num: Integer);
    procedure TestDecode;
    procedure TestRijndaelCBC;
   public
    constructor Create(UnitTestList: TTestList);
    destructor Destroy; override;
    procedure TestShort; override;
  end;

var
//128 bit
TEST_KEY_128     : packed array [0..15] of Byte = ($2b, $7e, $15, $16, $28, $ae, $d2,
$a6, $ab, $f7, $15, $88, $09, $cf, $4f, $3c);
 //192 bit
TEST_KEY_192     : packed array [0..23] of Byte = ($8e, $73, $b0, $f7, $da, $0e, $64,
$52, $c8, $10, $f3, $2b, $80, $90, $79, $e5, $62, $f8, $ea, $d2, $52, $2c, $6b, $7b);
 //256 bit
TEST_KEY_256 : packed array [0..31] of Byte =
($60,$3d,$eb,$10,$15,$ca,$71,$be,$2b,$73,$ae,$f0,$85,$7d,$77,$81,$1f,$35,$2c,
 $07,$3b,$61,$08,$d7,$2d,$98,$10,$a3,$09,$14,$df,$f4); //Key
TEST_IV      : packed array [0..15] of Byte =
($00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f); //IV
TestFileName: AnsiString = 'Data\utStreams.pas';
EncDir: AnsiString = 'Enc_data\';
TestPassword: AnsiString = 'AESGvd%E9w238sddkg4$9sm@r3';

var
  UnitTestEncryption: TUnitTestEncryption;

implementation

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TUnitTestEncryption.Create(UnitTestList: TTestList);
var fs: TCPSFileStream;
begin
  inherited Create(UnitTestList);
  FBuf_src := nil;
  FBuf_enc := nil;
  FBuf_dec := nil;
  FCPSManager := TCPSManager.Create(nil);
  fs := TCPSFileStream.Create(TestFileName,fmOpenRead or fmShareDenyWrite);
  try
   FSize := fs.Size;
   if (FSize > 0) then
    begin
      FBuf_src := MemoryManager.GetMem(FSize);
      FBuf_enc := MemoryManager.GetMem(FSize);
      FBuf_dec := MemoryManager.GetMem(FSize);
      fs.ReadBuffer(FBuf_src^,FSize);
    end;
  finally
    fs.Free;
  end;
end; // Create


//------------------------------------------------------------------------------
// destoy
//------------------------------------------------------------------------------
destructor TUnitTestEncryption.Destroy;
begin
  if (FBuf_src <> nil) then
   MemoryManager.FreeAndNilMem(FBuf_src);
  if (FBuf_enc <> nil) then
   MemoryManager.FreeAndNilMem(FBuf_enc);
  if (FBuf_dec <> nil) then
   MemoryManager.FreeAndNilMem(FBuf_dec);
  FCPSManager.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
//  http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
//  page 27-29, mode CBC
//------------------------------------------------------------------------------
procedure TUnitTestEncryption.TestRijndaelCBC;
const Capt = 'Test Rijndael CBC - ';
const
//128 bit
KEY_128     : packed array [0..15] of Byte = ($2b, $7e, $15, $16, $28, $ae, $d2,
$a6, $ab, $f7, $15, $88, $09, $cf, $4f, $3c);
SRC         : packed array [0..15] of Byte = ($6b, $c1, $be, $e2, $2e, $40, $9f,
$96, $e9, $3d, $7e, $11, $73, $93, $17, $2a);
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
IV      : packed array [0..15] of Byte =
($00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f); //IV
var
OUT_BUF:   PAnsiChar;
OUT_SIZE:  Integer;
OUT_BUF2:  PAnsiChar;
OUT_SIZE2: Integer;
i:         Integer;
begin
 WriteToProcessLog(Capt+'starting...');
 FCPSManager.CompressionAlgorithm := caNone;
// 128
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_128;
 FCPSManager.CryptoParams.CryptoMode := acmCBC;
 FCPSManager.CryptoParams.SetKey(@KEY_128[0],Length(KEY_128));
 {$IFDEF ENCRYPTION_DEC5}
 FCPSManager.CryptoParams.SetInitVector(@IV[0],Length(IV));
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE,True);
 {$ELSE}
 FCPSManager.CryptoParams.SetInitVector(@IV[0]);
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE);
 {$ENDIF}
 if (OUT_SIZE <> LENGTH(SRC)) then
  WriteToErrorLog(Capt+'error, invalid OUT_SIZE = '+IntToStr(OUT_SIZE))
 else
  begin
   for i := 0 to High(ENC_128) do
    if (pByte(OUT_BUF+i)^ <> ENC_128[i]) then
     begin
      WriteToErrorLog(Capt+'error, CBC 128 encryption i = '+IntToStr(i)+#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_128[i],2));
      break;
     end;
  end;
 WriteToProcessLog('CBC 128 encryption complete');
 {$IFDEF ENCRYPTION_DEC5}
 FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2,True);
 {$ELSE}
 FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2);
 {$ENDIF}
 if (OUT_SIZE <> OUT_SIZE2) then
  WriteToErrorLog(Capt+'error, invalid OUT_SIZE2 = '+IntToStr(OUT_SIZE2))
 else
  begin
   for i := 0 to High(SRC) do
    if (pByte(OUT_BUF2+i)^ <> SRC[i]) then
     begin
      WriteToErrorLog(Capt+'error, CBC 128 decryption i = '+IntToStr(i)+#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_128[i],2));
      break;
     end;
  end;
 CPSFreeMem(OUT_BUF);
 CPSFreeMem(OUT_BUF2);
 WriteToProcessLog('CBC 128 decryption complete');
// 192
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
 FCPSManager.CryptoParams.CryptoMode := acmCBC;
 FCPSManager.CryptoParams.SetKey(@KEY_192[0],Length(KEY_192));
 {$IFDEF ENCRYPTION_DEC5}
 FCPSManager.CryptoParams.SetInitVector(@IV[0],Length(IV));
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE,True);
 {$ELSE}
 FCPSManager.CryptoParams.SetInitVector(@IV[0]);
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE);
 {$ENDIF}
 if (OUT_SIZE <> LENGTH(SRC)) then
  WriteToErrorLog(Capt+'error, invalid OUT_SIZE = '+IntToStr(OUT_SIZE))
 else
  begin
   for i := 0 to High(ENC_192) do
    if (pByte(OUT_BUF+i)^ <> ENC_192[i]) then
     begin
      WriteToErrorLog(Capt+'error, CBC 192 encryption i = '+IntToStr(i)+#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_192[i],2));
      break;
     end;
  end;
 WriteToProcessLog('CBC 192 encryption complete');
 {$IFDEF ENCRYPTION_DEC5}
 FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2,True);
 {$ELSE}
 FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2);
 {$ENDIF}
 if (OUT_SIZE <> OUT_SIZE2) then
  WriteToErrorLog(Capt+'error, invalid OUT_SIZE2 = '+IntToStr(OUT_SIZE2))
 else
  begin
   for i := 0 to High(SRC) do
    if (pByte(OUT_BUF2+i)^ <> SRC[i]) then
     begin
      WriteToErrorLog(Capt+'error, CBC 192 decryption i = '+IntToStr(i)+#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_192[i],2));
      break;
     end;
  end;
 CPSFreeMem(OUT_BUF);
 CPSFreeMem(OUT_BUF2);
 WriteToProcessLog('CBC 192 decryption complete');
// 256
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
 FCPSManager.CryptoParams.CryptoMode := acmCBC;
 FCPSManager.CryptoParams.SetKey(@KEY_256[0],Length(KEY_256));
 {$IFDEF ENCRYPTION_DEC5}
 FCPSManager.CryptoParams.SetInitVector(@IV[0],Length(IV));
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE,True);
 {$ELSE}
 FCPSManager.CryptoParams.SetInitVector(@IV[0]);
 FCPSManager.CompressBuffer(@SRC[0],Length(SRC),OUT_BUF,OUT_SIZE);
 {$ENDIF}
 if (OUT_SIZE <> LENGTH(SRC)) then
  WriteToErrorLog(Capt+'error, invalid OUT_SIZE = '+IntToStr(OUT_SIZE))
 else
  begin
   for i := 0 to High(ENC_256) do
    if (pByte(OUT_BUF+i)^ <> ENC_256[i]) then
     begin
      WriteToErrorLog(Capt+'error, CBC 256 encryption i = '+IntToStr(i)+#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_256[i],2));
      break;
     end;
  end;
 WriteToProcessLog('CBC 256 encryption complete');
 {$IFDEF ENCRYPTION_DEC5}
 FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2,True);
 {$ELSE}
 FCPSManager.DecompressBuffer(OUT_BUF,OUT_SIZE,OUT_BUF2,OUT_SIZE2);
 {$ENDIF}
 if (OUT_SIZE <> OUT_SIZE2) then
  WriteToErrorLog(Capt+'error, invalid OUT_SIZE2 = '+IntToStr(OUT_SIZE2))
 else
  begin
   for i := 0 to High(SRC) do
    if (pByte(OUT_BUF2+i)^ <> SRC[i]) then
     begin
      WriteToErrorLog(Capt+'error, CBC 256 decryption i = '+IntToStr(i)+#13#10+IntToHex(pByte(OUT_BUF+i)^,2)+#9+IntToHex(ENC_256[i],2));
      break;
     end;
  end;
 CPSFreeMem(OUT_BUF);
 CPSFreeMem(OUT_BUF2);
 WriteToProcessLog('CBC 256 decryption complete');
end;

procedure TUnitTestEncryption.TestShort;
begin
{$IFNDEF SKIP_ENCODE}
  CheckAction(TestEncode,'Test Encode');
{$ENDIF}
  CheckAction(TestDecode,'Test Decode');
  CheckAction(TestRijndaelCBC,'Test Rijndael CBC');
end;

//------------------------------------------------------------------------------
// return -1 if buffers equal, or index of first not equal byte
//------------------------------------------------------------------------------
function TUnitTestEncryption.CompareBuf: Integer;
var i: Integer;
begin
 Result := -1;
 for i := 0 to FSize - 1 do
  if (PByte(FBuf_src+i)^ <> PByte(FBuf_dec+i)^) then
   begin
    Result := i;
    break;
   end;
end;

procedure TUnitTestEncryption.DoTestEncode(var Num: Integer);
var Capt: String;
    fs:   TCPSCryptoPressFileStream;
    e:    Extended;
    sz:   Integer;
begin
  e := Num;
  Capt := 'Encode #'+IntToStr(Num);
  Inc(num);
  WriteToProcessLog('> '+Capt);
    // ECB size must be: x * 24 bytes
    sz := FSize;
    if (FCPSManager.CryptoParams.CryptoMode = acmECB) then
     begin
      if (FCPSManager.CryptoParams.CryptoAlgorithm = craDES_Triple_24) then
//       sz := (FSize div 24) * 24
       Exit
      else
       sz := (FSize div 16) * 16;
     end;

  fs := FCPSManager.CreateCryptoPressFileStream(EncDir+FormatFloat('00000',e),fmCreate);
  try
    fs.WriteBuffer(FBuf_src^,sz);
  finally
    fs.Free;
    WriteToProcessLog('< '+Capt);
  end;
end;


procedure TUnitTestEncryption.DoTestDecode(var Num: Integer);
var Capt: String;
    fs:   TCPSCryptoPressFileStream;
    e:    Extended;
    cmp:  Integer;
    sz:   Integer;
begin
  e := Num;
  Capt := 'Decode #'+IntToStr(Num);
  Inc(num);
  WriteToProcessLog('> '+Capt);
  try
    // ECB size must be: x * 24 bytes
    sz := FSize;
    if (FCPSManager.CryptoParams.CryptoMode = acmECB) then
     begin
      if (FCPSManager.CryptoParams.CryptoAlgorithm = craDES_Triple_24) then
       Exit
//         sz := (FSize div 24) * 24
      else
       sz := (FSize div 16) * 16;
     end;
    fs := FCPSManager.CreateCryptoPressFileStream(EncDir+FormatFloat('00000',e),fmOpenReadWrite or fmShareDenyWrite);
    try
      fs.ReadBuffer(FBuf_dec^,sz);
      cmp := CompareBuf;
      if (cmp >= 0) then
       WriteToErrorLog(Capt+#9+'error in byte: '+IntToStr(cmp));
    finally
      fs.Free;
    end;
   WriteToProcessLog('< '+Capt);
  except
    on e: Exception do
     begin
     WriteToProcessLog('< '+Capt);
     WriteToErrorLog(Capt+#9+'error: '+#13#10+e.Message);
     end;
  end;
end;

procedure TUnitTestEncryption.TestEncode;
var i,j,n: Integer;
begin
 n := 1;
 FCPSManager.CompressionAlgorithm := caNone;
 // text password, no compression
 FCPSManager.CryptoParams.Password := TestPassword;
 FCPSManager.CryptoParams.UseInitVector := False;
 for i := 1 to CPS_MAX_Cipher do
  for j := 0 to CPS_MAX_Cipher_Mode do
   begin
    FCPSManager.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(i);
    FCPSManager.CryptoParams.CryptoMode := TCPSCryptoMode(j);
    DoTestEncode(n);
   end;
 // binary key  
 FCPSManager.CryptoParams.Password := '';
{$IFDEF SKIP_ENCODE}
 for i := 1 to 12 do
  for j := 0 to 3 do
{$ELSE}
 for i := 1 to CPS_MAX_Cipher do
  for j := 0 to CPS_MAX_Cipher_Mode do
{$ENDIF}
   begin
    FCPSManager.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(i);
    if (FCPSManager.CryptoParams.CryptoAlgorithm = craRijndael_128) or
       (FCPSManager.CryptoParams.CryptoAlgorithm = craTwofish_128) then
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_128[0],SizeOf(TEST_KEY_128))
    else
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_256[0],SizeOf(TEST_KEY_256));
    FCPSManager.CryptoParams.CryptoMode := TCPSCryptoMode(j);
    DoTestEncode(n);
   end;
 // initial vector and binary key
 FCPSManager.CryptoParams.Password := '';
 FCPSManager.CryptoParams.UseInitVector := True;
 FCPSManager.CryptoParams.SetInitVector(@TEST_IV[0],SizeOf(TEST_IV));
{$IFDEF SKIP_ENCODE}
 for i := 1 to 12 do
  for j := 0 to 3 do
{$ELSE}
 for i := 1 to CPS_MAX_Cipher do
  for j := 0 to CPS_MAX_Cipher_Mode do
{$ENDIF}
   begin
    FCPSManager.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(i);
    if (FCPSManager.CryptoParams.CryptoAlgorithm = craRijndael_128) or
       (FCPSManager.CryptoParams.CryptoAlgorithm = craTwofish_128) then
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_128[0],SizeOf(TEST_KEY_128))
    else
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_256[0],SizeOf(TEST_KEY_256));
    FCPSManager.CryptoParams.CryptoMode := TCPSCryptoMode(j);
    DoTestEncode(n);
   end;
end;

procedure TUnitTestEncryption.TestDecode;
var i,j,n,l: Integer;
hs: THash_RipeMD256;
s: AnsiString;
hv: AnsiString;
fs: TFileStream;
{$IFDEF ENCRYPTION_DEC5}
{$ELSE}
// cr: TCipher_Rijndael;
{$ENDIF}
begin
 s := 'test';
 l := Length(s);
{$IFDEF ENCRYPTION_DEC5}
 hs := THash_RipeMD256.Create;
 hv := hs.CalcBuffer(s[1],l,nil);
{$ELSE}
 hs := THash_RipeMD256.Create(nil);
 hs.Init;
 hs.Calc(s[1], l);
 SetLength(hv,hs.DigestKeySize);
 if (hs.DigestKeySize > 0) then
  Move(hs.DigestKey^,hv[1],hs.DigestKeySize);
 hs.Done;
// hv := hs.CalcBuffer(s,l,nil);
// cr := TCipher_Rijndael.Create(s,nil);

{$ENDIF}
fs := TFileStream.Create(EncDir+'hash.dat',fmCreate);
fs.WriteBuffer(hv[1],Length(hv));
fs.Free;
 hs.Free;

 n := 1;
 FCPSManager.CompressionAlgorithm := caNone;
 // text password, no compression
 FCPSManager.CryptoParams.Password := TestPassword;
 FCPSManager.CryptoParams.UseInitVector := False;
{$IFDEF SKIP_ENCODE}
 for i := 1 to 12 do
  for j := 0 to 3 do
{$ELSE}
 for i := 1 to CPS_MAX_Cipher do
  for j := 0 to CPS_MAX_Cipher_Mode do
{$ENDIF}
   begin
    FCPSManager.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(i);
    FCPSManager.CryptoParams.CryptoMode := TCPSCryptoMode(j);
    DoTestDecode(n);
   end;
 // binary key
 FCPSManager.CryptoParams.Password := '';
{$IFDEF SKIP_ENCODE}
 for i := 1 to 12 do
  for j := 0 to 3 do
{$ELSE}
 for i := 1 to CPS_MAX_Cipher do
  for j := 0 to CPS_MAX_Cipher_Mode do
{$ENDIF}
   begin
    FCPSManager.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(i);
    if (FCPSManager.CryptoParams.CryptoAlgorithm = craRijndael_128) or
       (FCPSManager.CryptoParams.CryptoAlgorithm = craTwofish_128) then
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_128[0],SizeOf(TEST_KEY_128))
    else
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_256[0],SizeOf(TEST_KEY_256));
    FCPSManager.CryptoParams.CryptoMode := TCPSCryptoMode(j);
    DoTestDecode(n);
   end;
 // initial vector and binary key
 // binary key
 FCPSManager.CryptoParams.Password := '';
 FCPSManager.CryptoParams.UseInitVector := True;
 FCPSManager.CryptoParams.SetInitVector(@TEST_IV[0],SizeOf(TEST_IV));
{$IFDEF SKIP_ENCODE}
 for i := 1 to 12 do
  for j := 0 to 3 do
{$ELSE}
 for i := 1 to CPS_MAX_Cipher do
  for j := 0 to CPS_MAX_Cipher_Mode do
{$ENDIF}
   begin
    FCPSManager.CryptoParams.CryptoAlgorithm := TCPSCryptoAlgorithm(i);
    if (FCPSManager.CryptoParams.CryptoAlgorithm = craRijndael_128) or
       (FCPSManager.CryptoParams.CryptoAlgorithm = craTwofish_128) then
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_128[0],SizeOf(TEST_KEY_128))
    else
     FCPSManager.CryptoParams.SetKey(@TEST_KEY_256[0],SizeOf(TEST_KEY_256));
    FCPSManager.CryptoParams.CryptoMode := TCPSCryptoMode(j);
    DoTestDecode(n);
   end;
end;



initialization
  UnitTestEncryption := TUnitTestEncryption.Create(UnitTestList);

finalization
  UnitTestEncryption.Free;

end.
