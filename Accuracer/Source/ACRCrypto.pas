unit ACRCrypto;

interface

uses Windows,SysUtils,Classes,

{$I ACRVer.inc}

// Accuracer units

 {$IFDEF DEBUG_LOG}
     ACRDebug,
 {$ENDIF}
     ACRExcept,
     ACRConst,
     ACRDECCRC,
     ACRTypes
{$IFDEF ENCRYPTION_ON}
     ,
     ACRRng,
     ACRDECCipher,
     ACRDECHash,
     ACRDECUtil
{$ENDIF}
     ;

  procedure ACREncryptBuffer(const CryptoInfo: TACRCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  procedure ACRDecryptBuffer(const CryptoInfo: TACRCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  function ACRCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
  procedure ACRGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer); overload;
  function ACRCreateCryptoHeader(const CryptoInfo: TACRCryptoParams): TACRCryptoHeader;
  function ACRIsKeyValid(const CryptoHeader: TACRCryptoHeader; const CryptoInfo: TACRCryptoParams): Boolean;

implementation

//----------------------------- DEC v.5. ---------------------------------------


//------------------------------------------------------------------------------
// encrypt buffer
//------------------------------------------------------------------------------
procedure ACREncryptBuffer(const CryptoInfo: TACRCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr:   TDECCipher;
    hs:   TDECHash;
    hv:   Binary;
    l:    Integer;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 ACR_ENCRYPTED_DB_USED := True;
 hs := nil;
 l := Length(CryptoInfo.Password);
 case CryptoInfo.CryptoAlgorithm of
  ACR_Cipher_Rijndael_128, ACR_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create;
  ACR_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create;
  ACR_Cipher_Twofish_128,ACR_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create;
  ACR_Cipher_Square:
     cr := TCipher_Square.Create;
  ACR_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create;
  ACR_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create;
  ACR_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create;
  ACR_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create;
  ACR_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create;
  ACR_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create
 else
  raise EACRException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 if (l > 0) then
  begin
   if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_Rijndael_128) or
      (CryptoInfo.CryptoAlgorithm = ACR_Cipher_Twofish_128) then
    hs := THash_RipeMD128.Create
   else
    hs := THash_RipeMD256.Create;
  end;
 try
  case CryptoInfo.CryptoMode of
   ACR_Cipher_Mode_CTS:   cr.Mode := cmCTSx;
   ACR_Cipher_Mode_CBC:   cr.Mode := cmCBCx; // 8?
   ACR_Cipher_Mode_CFB:   cr.Mode := cmCFBx; // 8?
   ACR_Cipher_Mode_OFB:   cr.Mode := cmOFBx; // 8?
   ACR_Cipher_Mode_CFS:   cr.Mode := cmCFSx;
   ACR_Cipher_Mode_ECB:   cr.Mode := cmECBx;
   ACR_Cipher_Mode_CFB8:  cr.Mode := cmCFB8;
   ACR_Cipher_Mode_OFB8:  cr.Mode := cmOFB8;
   ACR_Cipher_Mode_CFS8:  cr.Mode := cmOFB8
  else
   raise EACRException.Create(10028,ErrorLUnknownCryptoMode,
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
 raise EACRException.Create(10029,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // ACREncryptBuffer

//------------------------------------------------------------------------------
// decrypt buffer
//------------------------------------------------------------------------------
procedure ACRDecryptBuffer(const CryptoInfo: TACRCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr:   TDECCipher;
    hs:   TDECHash;
    hv:   Binary;
    l:    Integer;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
{$IFDEF DEBUG_DECRYPTION_TIME}
aaIncCounter(counter1);
if (BufferSize > 4000) then
 aaIncCounter(counter2);
aaStartTime(time1);
{$ENDIF}
 ACR_ENCRYPTED_DB_USED := True;
 hs := nil;
 l := Length(CryptoInfo.Password);
 case CryptoInfo.CryptoAlgorithm of
  ACR_Cipher_Rijndael_128, ACR_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create;
  ACR_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create;
  ACR_Cipher_Twofish_128,ACR_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create;
  ACR_Cipher_Square:
     cr := TCipher_Square.Create;
  ACR_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create;
  ACR_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create;
  ACR_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create;
  ACR_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create;
  ACR_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create;
  ACR_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create
 else
  raise EACRException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 if (l > 0) then
  begin
   if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_Rijndael_128) or
      (CryptoInfo.CryptoAlgorithm = ACR_Cipher_Twofish_128) then
    hs := THash_RipeMD128.Create
   else
    hs := THash_RipeMD256.Create;
  end;
 try
  case CryptoInfo.CryptoMode of
   ACR_Cipher_Mode_CTS:   cr.Mode := cmCTSx;
   ACR_Cipher_Mode_CBC:   cr.Mode := cmCBCx; // 8?
   ACR_Cipher_Mode_CFB:   cr.Mode := cmCFBx; // 8?
   ACR_Cipher_Mode_OFB:   cr.Mode := cmOFBx; // 8?
   ACR_Cipher_Mode_CFS:   cr.Mode := cmCFSx;
   ACR_Cipher_Mode_ECB:   cr.Mode := cmECBx;
   ACR_Cipher_Mode_CFB8:  cr.Mode := cmCFB8;
   ACR_Cipher_Mode_OFB8:  cr.Mode := cmOFB8;
   ACR_Cipher_Mode_CFS8:  cr.Mode := cmOFB8
  else
   raise EACRException.Create(10028,ErrorLUnknownCryptoMode,
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
 raise EACRException.Create(10032,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
{$IFDEF DEBUG_DECRYPTION_TIME}
aaStopTime(time1);
{$ENDIF}
end; // ACRDecryptBuffer


//------------------------------------------------------------------------------
// calculate CRC32
//------------------------------------------------------------------------------
function ACRCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
begin
{$IFDEF ENCRYPTION_ON}
 Result := ACR_CRC32(Value,Buffer,BufferSize);
{$ELSE}
 raise EACRException.Create(10033,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // ACRCountCRC


//------------------------------------------------------------------------------
// generate random buffer
//------------------------------------------------------------------------------
procedure ACRGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
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
 raise EACRException.Create(10711,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // ACRGenerateRandomBuffer

//------------------------------------------------------------------------------
// create crypto header
//------------------------------------------------------------------------------
function ACRCreateCryptoHeader(const CryptoInfo: TACRCryptoParams): TACRCryptoHeader;
begin
 Result.CryptoAlgorithm := CryptoInfo.CryptoAlgorithm;
 if (Result.CryptoAlgorithm <> ACR_Cipher_None) then
  begin
{$IFDEF ENCRYPTION_ON}
   ACRGenerateRandomBuffer(@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.ControlBlockCRC := ACRCountCRC(0,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.CryptoMode := CryptoInfo.CryptoMode;
   ACREncryptBuffer(CryptoInfo,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   // ask password or key if crypto info was not set
   if (CryptoInfo.Password = '') then
     Result.CryptoAskPassword := 0
   else
     Result.CryptoAskPassword := 1;
{$ELSE}
 raise EACRException.Create(10036,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // ACRCreateCryptoHeader


//------------------------------------------------------------------------------
// Return true if CryptoHeader can be decrypted by KeyInfo
//------------------------------------------------------------------------------
function ACRIsKeyValid(const CryptoHeader: TACRCryptoHeader; const CryptoInfo: TACRCryptoParams): Boolean;
var ch: TACRCryptoHeader;
begin
 if (CryptoInfo.CryptoAlgorithm = ACR_Cipher_None) then
  Result := True
 else
  begin
{$IFDEF ENCRYPTION_ON}
   ch := CryptoHeader;
   ACRDecryptBuffer(CryptoInfo,@ch.ControlBlock,Sizeof(ch.ControlBlock));
   Result := (ch.ControlBlockCRC = ACRCountCRC(0,@ch.ControlBlock,Sizeof(ch.ControlBlock)));
{$ELSE}
 raise EACRException.Create(10037,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // ACRIsKeyValid


//----------------------------- DEC v.5. ---------------------------------------



initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRCrypto> initialized');
{$ENDIF}

end.
