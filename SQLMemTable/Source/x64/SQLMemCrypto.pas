unit SQLMemCrypto;

interface

uses Windows,SysUtils,Classes,

{$I SQLMemVer.inc}

// SQLMemTable units

 {$IFDEF DEBUG_LOG}
     SQLMemDebug,
 {$ENDIF}
     SQLMemExcept,
     SQLMemConst,
     SQLMemDECCRC,
     SQLMemTypes
{$IFDEF ENCRYPTION_ON}
     ,
     SQLMemRng,
     SQLMemDECCipher,
     SQLMemDECHash,
     SQLMemDECUtil
{$ENDIF}
     ;

  procedure SQLMemEncryptBuffer(const CryptoInfo: TSQLMemCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  procedure SQLMemDecryptBuffer(const CryptoInfo: TSQLMemCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  function SQLMemCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
  procedure SQLMemGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer); overload;
  function SQLMemCreateCryptoHeader(const CryptoInfo: TSQLMemCryptoParams): TSQLMemCryptoHeader;
  function SQLMemIsKeyValid(const CryptoHeader: TSQLMemCryptoHeader; const CryptoInfo: TSQLMemCryptoParams): Boolean;

implementation

//----------------------------- DEC v.5. ---------------------------------------


//------------------------------------------------------------------------------
// encrypt buffer
//------------------------------------------------------------------------------
procedure SQLMemEncryptBuffer(const CryptoInfo: TSQLMemCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr:   TDECCipher;
    hs:   TDECHash;
    hv:   Binary;
    l:    Integer;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 SQLMem_ENCRYPTED_DB_USED := True;
 hs := nil;
 l := Length(CryptoInfo.Password);
 case CryptoInfo.CryptoAlgorithm of
  SQLMem_Cipher_Rijndael_128, SQLMem_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create;
  SQLMem_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create;
  SQLMem_Cipher_Twofish_128,SQLMem_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create;
  SQLMem_Cipher_Square:
     cr := TCipher_Square.Create;
  SQLMem_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create;
  SQLMem_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create;
  SQLMem_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create;
  SQLMem_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create;
  SQLMem_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create;
  SQLMem_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create
 else
  raise ESQLMemException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 if (l > 0) then
  begin
   if (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_Rijndael_128) or
      (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_Twofish_128) then
    hs := THash_RipeMD128.Create
   else
    hs := THash_RipeMD256.Create;
  end;
 try
  case CryptoInfo.CryptoMode of
   SQLMem_Cipher_Mode_CTS:   cr.Mode := cmCTSx;
   SQLMem_Cipher_Mode_CBC:   cr.Mode := cmCBCx; // 8?
   SQLMem_Cipher_Mode_CFB:   cr.Mode := cmCFBx; // 8?
   SQLMem_Cipher_Mode_OFB:   cr.Mode := cmOFBx; // 8?
   SQLMem_Cipher_Mode_CFS:   cr.Mode := cmCFSx;
   SQLMem_Cipher_Mode_ECB:   cr.Mode := cmECBx;
   SQLMem_Cipher_Mode_CFB8:  cr.Mode := cmCFB8;
   SQLMem_Cipher_Mode_OFB8:  cr.Mode := cmOFB8;
   SQLMem_Cipher_Mode_CFS8:  cr.Mode := cmOFB8
  else
   raise ESQLMemException.Create(10028,ErrorLUnknownCryptoMode,
    [CryptoInfo.CryptoMode]);
  end;
  if (l = 0) then
   begin
    // encode by binary key
    if (CryptoInfo.UseInitVector) then
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,CryptoInfo.InitVector,CryptoInfo.InitVectorSize)
    else
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,CryptoInfo.InitVector,0);
   end
  else
   begin
    // encode by password
    hv := hs.CalcBuffer(CryptoInfo.Password[1],l,nil);
    if (CryptoInfo.UseInitVector) then
     cr.Init(hv,Length(hv),CryptoInfo.InitVector,CryptoInfo.InitVectorSize)
    else
     cr.Init(hv);
   end;
  cr.Encode(Buffer^,Buffer^,BufferSize);
 finally
  if (cr <> nil) then
   cr.Free;
  if (l > 0) then
   ProtectBinary(hv);
  if (hs <> nil) then
   hs.Free;
 end;
{$ELSE}
 raise ESQLMemException.Create(10029,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // SQLMemEncryptBuffer

//------------------------------------------------------------------------------
// decrypt buffer
//------------------------------------------------------------------------------
procedure SQLMemDecryptBuffer(const CryptoInfo: TSQLMemCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr:   TDECCipher;
    hs:   TDECHash;
    hv:   Binary;
    l:    Integer;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
{$IFDEF DEBUG_DECRYPTION_TIME}
aaIncCounter(counter1);
if (BufferSize > 4000) then
 aaIncCounter(counter2);
aaStartTime(time1);
{$ENDIF}
 SQLMem_ENCRYPTED_DB_USED := True;
 hs := nil;
 l := Length(CryptoInfo.Password);
 case CryptoInfo.CryptoAlgorithm of
  SQLMem_Cipher_Rijndael_128, SQLMem_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create;
  SQLMem_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create;
  SQLMem_Cipher_Twofish_128,SQLMem_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create;
  SQLMem_Cipher_Square:
     cr := TCipher_Square.Create;
  SQLMem_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create;
  SQLMem_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create;
  SQLMem_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create;
  SQLMem_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create;
  SQLMem_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create;
  SQLMem_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create
 else
  raise ESQLMemException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 if (l > 0) then
  begin
   if (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_Rijndael_128) or
      (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_Twofish_128) then
    hs := THash_RipeMD128.Create
   else
    hs := THash_RipeMD256.Create;
  end;
 try
  case CryptoInfo.CryptoMode of
   SQLMem_Cipher_Mode_CTS:   cr.Mode := cmCTSx;
   SQLMem_Cipher_Mode_CBC:   cr.Mode := cmCBCx; // 8?
   SQLMem_Cipher_Mode_CFB:   cr.Mode := cmCFBx; // 8?
   SQLMem_Cipher_Mode_OFB:   cr.Mode := cmOFBx; // 8?
   SQLMem_Cipher_Mode_CFS:   cr.Mode := cmCFSx;
   SQLMem_Cipher_Mode_ECB:   cr.Mode := cmECBx;
   SQLMem_Cipher_Mode_CFB8:  cr.Mode := cmCFB8;
   SQLMem_Cipher_Mode_OFB8:  cr.Mode := cmOFB8;
   SQLMem_Cipher_Mode_CFS8:  cr.Mode := cmOFB8
  else
   raise ESQLMemException.Create(10028,ErrorLUnknownCryptoMode,
    [CryptoInfo.CryptoMode]);
  end;
  if (l = 0) then
   begin
    // encode by binary key
    if (CryptoInfo.UseInitVector) then
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,CryptoInfo.InitVector,CryptoInfo.InitVectorSize)
    else
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,CryptoInfo.InitVector,0);
   end
  else
   begin
    // encode by password
    hv := hs.CalcBuffer(CryptoInfo.Password[1],l,nil);
    if (CryptoInfo.UseInitVector) then
     cr.Init(hv,Length(hv),CryptoInfo.InitVector,CryptoInfo.InitVectorSize)
    else
     cr.Init(hv);
   end;
  cr.Decode(Buffer^,Buffer^,BufferSize);
 finally
  if (cr <> nil) then
   cr.Free;
  if (l > 0) then
   ProtectBinary(hv);
  if (hs <> nil) then
   hs.Free;
 end;
{$ELSE}
 raise ESQLMemException.Create(10032,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
{$IFDEF DEBUG_DECRYPTION_TIME}
aaStopTime(time1);
{$ENDIF}
end; // SQLMemDecryptBuffer


//------------------------------------------------------------------------------
// calculate CRC32
//------------------------------------------------------------------------------
function SQLMemCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
begin
{$IFDEF ENCRYPTION_ON}
 Result := SQLMem_CRC32(Value,Buffer,BufferSize);
{$ELSE}
 raise ESQLMemException.Create(10033,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // SQLMemCountCRC


//------------------------------------------------------------------------------
// generate random buffer
//------------------------------------------------------------------------------
procedure SQLMemGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var rng:  TRandom;
    size: Integer;

 function GenRndAnsiString(Len: Integer): AnsiString;
 var i: Integer;
 begin
  Result := '';
  for i := 1 to Len do
   Result := Result + Chr((Cardinal(Random(MaxInt)) xor aaGetTickCount) mod 255+1);
 end;

{$ENDIF}
begin
{$IFDEF ENCRYPTION_ON}
 Size := 100;
 rng := TRandom_LFSR.Create(GenRndAnsiString(Size),2032,False,nil);
 try
   rng.Seed('',-1);
   rng.Buffer(Buffer^,BufferSize);
 finally
   rng.Free;
 end;
{$ELSE}
 raise ESQLMemException.Create(10711,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // SQLMemGenerateRandomBuffer

//------------------------------------------------------------------------------
// create crypto header
//------------------------------------------------------------------------------
function SQLMemCreateCryptoHeader(const CryptoInfo: TSQLMemCryptoParams): TSQLMemCryptoHeader;
begin
 Result.CryptoAlgorithm := CryptoInfo.CryptoAlgorithm;
 if (Result.CryptoAlgorithm <> SQLMem_Cipher_None) then
  begin
{$IFDEF ENCRYPTION_ON}
   SQLMemGenerateRandomBuffer(@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.ControlBlockCRC := SQLMemCountCRC(0,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.CryptoMode := CryptoInfo.CryptoMode;
   SQLMemEncryptBuffer(CryptoInfo,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   // ask password or key if crypto info was not set
   if (CryptoInfo.Password = '') then
     Result.CryptoAskPassword := 0
   else
     Result.CryptoAskPassword := 1;
{$ELSE}
 raise ESQLMemException.Create(10036,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // SQLMemCreateCryptoHeader


//------------------------------------------------------------------------------
// Return true if CryptoHeader can be decrypted by KeyInfo
//------------------------------------------------------------------------------
function SQLMemIsKeyValid(const CryptoHeader: TSQLMemCryptoHeader; const CryptoInfo: TSQLMemCryptoParams): Boolean;
var ch: TSQLMemCryptoHeader;
begin
 if (CryptoInfo.CryptoAlgorithm = SQLMem_Cipher_None) then
  Result := True
 else
  begin
{$IFDEF ENCRYPTION_ON}
   ch := CryptoHeader;
   SQLMemDecryptBuffer(CryptoInfo,@ch.ControlBlock,Sizeof(ch.ControlBlock));
   Result := (ch.ControlBlockCRC = SQLMemCountCRC(0,@ch.ControlBlock,Sizeof(ch.ControlBlock)));
{$ELSE}
 raise ESQLMemException.Create(10037,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // SQLMemIsKeyValid


//----------------------------- DEC v.5. ---------------------------------------



initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemCrypto> initialized');
{$ENDIF}

end.
