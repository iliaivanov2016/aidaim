unit MsgCrypto;

interface

uses SysUtils,Classes,

{$I MsgVer.inc}

// Accuracer units

 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgExcept,
     MsgConst,
     MsgTypes,
{$IFDEF ENCRYPTION_ON}
     MsgRng,
     MsgCipher,
     MsgCipher1,
     MsgHash,
     MsgDecUtil,
{$ENDIF}
     MsgMemory
     ;

  const MsgPasswordBufferRandomDataSize = 15;
  const MsgDefaultEncKey = '[{26898FC6-3449-4101-B352-313A84817BD0}]';

  procedure MsgEncryptBuffer(const CryptoInfo: TMsgCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  procedure MsgDecryptBuffer(const CryptoInfo: TMsgCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  function MsgCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
  function MsgCountCRC16(Value: Word; Buffer: PAnsiChar; BufferSize: Integer): Word;
  procedure MsgGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
  function MsgCreateCryptoHeader(const CryptoInfo: TMsgCryptoParams): TMsgCryptoHeader;
  function MsgIsKeyValid(const CryptoHeader: TMsgCryptoHeader; const CryptoInfo: TMsgCryptoParams): Boolean;
  function GetCryptoHeaderForPassword(const Password: AnsiString): TMsgCryptoHeader;

implementation


//------------------------------------------------------------------------------
// encrypt buffer
//------------------------------------------------------------------------------
procedure MsgEncryptBuffer(const CryptoInfo: TMsgCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr: TCipher;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = Msg_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 case CryptoInfo.CryptoAlgorithm of
  Msg_Cipher_Rijndael_128:
   begin
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end;
  Msg_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Twofish_128:
   begin
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end;
  Msg_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Square:
     cr := TCipher_Square.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create(CryptoInfo.Password,nil)
 else
  raise EMsgException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 try
  case CryptoInfo.CryptoMode of
   Msg_Cipher_Mode_CTS: cr.Mode := cmCTS;
   Msg_Cipher_Mode_CBC: cr.Mode := cmCBC;
   Msg_Cipher_Mode_CFB: cr.Mode := cmCFB;
   Msg_Cipher_Mode_OFB: cr.Mode := cmOFB;
  else
   raise EMsgException.Create(10028,ErrorLUnknownCryptoMode,
    [CryptoInfo.CryptoMode]);
  end;
  cr.Initialized := False;
  if (CryptoInfo.Password = '') then
   begin
    if (CryptoInfo.UseInitVector) then
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,@CryptoInfo.InitVector)
    else
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,cr.Vector);
   end
  else
   begin
    if (CryptoInfo.UseInitVector) then
     cr.InitKey(CryptoInfo.Password,@CryptoInfo.InitVector)
    else
     cr.InitKey(CryptoInfo.Password,cr.Vector);
   end;
  cr.EncodeBuffer(Buffer^,Buffer^,BufferSize);
 finally 
  cr.Free; 
 end;
{$ELSE} 
 raise EMsgException.Create(10029,ErrorLEncryptionIsSwitchedOff); 
{$ENDIF} 
end; // MsgEncryptBuffer 
 
	
//------------------------------------------------------------------------------
// decrypt buffer 
//------------------------------------------------------------------------------
procedure MsgDecryptBuffer(const CryptoInfo: TMsgCryptoParams; 
                                     Buffer: PAnsiChar; BufferSize: Integer); 
{$IFDEF ENCRYPTION_ON} 
var cr: TCipher;
{$ENDIF}
begin 
 if (CryptoInfo.CryptoAlgorithm = Msg_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 case CryptoInfo.CryptoAlgorithm of 
  Msg_Cipher_Rijndael_128: 
   begin
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil); 
     cr.HashClass := THash_RipeMD128;
   end;
  Msg_Cipher_Rijndael_256: 
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Twofish_128: 
   begin
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end; 
  Msg_Cipher_Twofish_256: 
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Square: 
     cr := TCipher_Square.Create(CryptoInfo.Password,nil); 
  Msg_Cipher_Des_Single_8: 
     cr := TCipher_1DES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create(CryptoInfo.Password,nil); 
  Msg_Cipher_Des_Triple_8: 
     cr := TCipher_3DES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Triple_16: 
     cr := TCipher_3DDES.Create(CryptoInfo.Password,nil);
  Msg_Cipher_Des_Triple_24: 
     cr := TCipher_3TDES.Create(CryptoInfo.Password,nil) 
 else
  raise EMsgException.Create(10030,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end; 
 try 
  case CryptoInfo.CryptoMode of 
   Msg_Cipher_Mode_CTS: cr.Mode := cmCTS; 
   Msg_Cipher_Mode_CBC: cr.Mode := cmCBC; 
   Msg_Cipher_Mode_CFB: cr.Mode := cmCFB; 
   Msg_Cipher_Mode_OFB: cr.Mode := cmOFB; 
  else 
   raise EMsgException.Create(10031,ErrorLUnknownCryptoMode, 
    [CryptoInfo.CryptoMode]); 
  end; 
  cr.Initialized := False;
  if (CryptoInfo.Password = '') then
   begin
    if (CryptoInfo.UseInitVector) then 
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,@CryptoInfo.InitVector)
    else 
     cr.Init(CryptoInfo.KeyInfo.Key,CryptoInfo.KeyInfo.KeySize,cr.Vector); 
   end 
  else 
   begin 
    if (CryptoInfo.UseInitVector) then 
     cr.InitKey(CryptoInfo.Password,@CryptoInfo.InitVector) 
    else 
     cr.InitKey(CryptoInfo.Password,cr.Vector); 
   end; 
  cr.DecodeBuffer(Buffer^,Buffer^,BufferSize); 
 finally
  cr.Free; 
 end;
{$ELSE} 
 raise EMsgException.Create(10032,ErrorLEncryptionIsSwitchedOff); 
{$ENDIF}
end; // MsgDecryptBuffer
	
 
//------------------------------------------------------------------------------
// calculate CRC32
//------------------------------------------------------------------------------ 
function MsgCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal; 
begin
{$IFDEF ENCRYPTION_ON}
 Result := CRC32(Value,Buffer,BufferSize); 
{$ELSE}
 raise EMsgException.Create(10033,ErrorLEncryptionIsSwitchedOff); 
{$ENDIF} 
end; // MsgCountCRC
 
	
//------------------------------------------------------------------------------
// calculate CRC16 
//------------------------------------------------------------------------------ 
function MsgCountCRC16(Value: Word; Buffer: PAnsiChar; BufferSize: Integer): Word;
begin 
{$IFDEF ENCRYPTION_ON}
 Result := CRC16(Value,Buffer,BufferSize); 
{$ELSE} 
 raise EMsgException.Create(10034,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // MsgCountCRC16
	
	
//------------------------------------------------------------------------------
// generate random buffer
//------------------------------------------------------------------------------ 
procedure MsgGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON} 
var rng:  TRandom;
    size: Integer;
	
 function GenRndAnsiString(Len: Integer): AnsiString; 
 var i: Integer;
 begin 
  Result := '';
  for i := 1 to Len do
   Result := Result + Chr(Random(MaxInt) mod 255+1);
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
 raise EMsgException.Create(10035,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // MsgGenerateRandomBuffer


//------------------------------------------------------------------------------
// create crypto header
//------------------------------------------------------------------------------
function MsgCreateCryptoHeader(const CryptoInfo: TMsgCryptoParams): TMsgCryptoHeader;
begin
 Result.CryptoAlgorithm := CryptoInfo.CryptoAlgorithm;
 if (Result.CryptoAlgorithm <> Msg_Cipher_None) then
  begin
{$IFDEF ENCRYPTION_ON}
   MsgGenerateRandomBuffer(@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.ControlBlockCRC := MsgCountCRC(0,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.CryptoMode := CryptoInfo.CryptoMode;
   MsgEncryptBuffer(CryptoInfo,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   // ask password or key if crypto info was not set
   if (CryptoInfo.Password = '') then
     Result.CryptoAskPassword := 0
   else
     Result.CryptoAskPassword := 1;
{$ELSE}
 raise EMsgException.Create(10036,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // MsgCreateCryptoHeader


//------------------------------------------------------------------------------
// Return true if CryptoHeader can be decrypted by KeyInfo
//------------------------------------------------------------------------------
function MsgIsKeyValid(const CryptoHeader: TMsgCryptoHeader; const CryptoInfo: TMsgCryptoParams): Boolean;
var ch: TMsgCryptoHeader;
begin
 if (CryptoInfo.CryptoAlgorithm = Msg_Cipher_None) then
  Result := True
 else
  begin
{$IFDEF ENCRYPTION_ON}
   ch := CryptoHeader;
   MsgDecryptBuffer(CryptoInfo,@ch.ControlBlock,Sizeof(ch.ControlBlock));
   Result := (ch.ControlBlockCRC = MsgCountCRC(0,@ch.ControlBlock,Sizeof(ch.ControlBlock)));
{$ELSE}
 raise EMsgException.Create(10037,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // MsgIsKeyValid


//------------------------------------------------------------------------------
// return AnsiString hash of the text
//------------------------------------------------------------------------------
function MsgGetHash(const Text: AnsiString): AnsiString;
{$IFDEF ENCRYPTION_ON}
var hash: THash_RipeMD256;
{$ENDIF}
begin
{$IFDEF ENCRYPTION_ON}
 hash := THash_RipeMD256.Create(nil);
 try
  Result := hash.CalcAnsiString(Text,nil,fmtMIME64);
 finally
  hash.Free;
 end;
{$ELSE}
 raise EMsgException.Create(11343,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // MsgGetHash


//------------------------------------------------------------------------------
// Generates crypto header for specified password
//------------------------------------------------------------------------------
function GetCryptoHeaderForPassword(const Password: AnsiString): TMsgCryptoHeader;
var
  ci:           TMsgCryptoInfo;
begin
  if (Password <> '') then
   begin
    ci.CryptoAlgorithm := Msg_Cipher_Rijndael_256;
    ci.CryptoMode := Msg_Cipher_Mode_CTS;
    ci.Password := Password;
    ci.UseInitVector := False;
    Result := MsgCreateCryptoHeader(ci);
   end
  else
   begin
    FillChar(Result,SizeOf(Result),$00);
    Result.CryptoAlgorithm := Msg_Cipher_None;
   end;
end; // GetCryptoHeaderForPassword


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgCrypto> initialized');
{$ENDIF}

end.
