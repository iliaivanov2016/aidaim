unit CPSCrypto;

interface

uses SysUtils,Classes,Windows,

{$I CPSVer.inc}
// Accuracer units

 {$IFDEF DEBUG_LOG}
     CPSDebug,
 {$ENDIF}
     CPSExcept,
     CPSConst,
{$IFDEF ENCRYPTION_ON}
 {$IFDEF ENCRYPTION_DEC5}
     CPSDECRandom,
     CPSDECCipher,
     CPSDECCRC,
     CPSDECHash,
     CPSDECUtil
 {$ELSE}
     CPSRng,
     CPSCipher,
     CPSCipher1,
     CPSHash,
     CPSDecUtil
 {$ENDIF}
{$ENDIF}
     ;

//------------------------------------------------------------------------------
// Encryption types
//------------------------------------------------------------------------------
type

  TCPSCryptoKey = packed record
   Key:             array [0..CPS_MAX_KEY] of Byte;
   KeySize:         Word; // 0 by default
  end;

  TCPSCryptoParams = packed record
   KeyInfo:         TCPSCryptoKey;
   InitVector:      array [0..CPS_MAX_VECTOR] of Byte;
   InitVectorSize:  Word;
   CryptoAlgorithm: Byte;  // CPS_Cipher_None by Default
   CryptoMode:      Byte;  // CPS_CTS by Default
   UseInitVector:   Boolean; // False by default
   Password:        AnsiString; // CPSDefaultPassword by default
  end;

  TCPSCryptoControlBlock = packed record
   Data:            array [0..CPS_MAX_CONTROL_BLOCK] of Byte;
  end; // 256

  TCPSCryptoHeader = packed record
   ControlBlock:      TCPSCryptoControlBlock;
   ControlBlockCRC:   Cardinal;
   CryptoAlgorithm:   Byte;
   CryptoMode:        Byte;
   CryptoAskPassword: Byte; // ask password (1) or key (0)
   Reserverd:         array[0..4] of Byte;
  end; // 268

  procedure CPSEncryptBuffer(const CryptoInfo: TCPSCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  procedure CPSDecryptBuffer(const CryptoInfo: TCPSCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
  function CPS_CRC32(CRC: Cardinal; Data: Pointer; DataSize: Cardinal): Cardinal; assembler; register;
  function CPSCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
  function CPSCountCRC16(Value: Word; Buffer: PAnsiChar; BufferSize: Integer): Word;
{$IFDEF ENCRYPTION_DEC5}
  procedure CPSGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer); overload;
  procedure CPSGenerateRandomBuffer(
                        Buffer:           PAnsiChar;
                        BufferSize:       Integer;
                        SeedBuffer:       PAnsiChar;
                        SeedBufferSize:   Integer
                                   ); overload;
{$ELSE}
  procedure CPSGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
{$ENDIF}
  function CPSCreateCryptoHeader(const CryptoInfo: TCPSCryptoParams): TCPSCryptoHeader;
  function CPSIsKeyValid(const CryptoHeader: TCPSCryptoHeader; const CryptoInfo: TCPSCryptoParams): Boolean;

implementation


//------------------------------------------------------------------------------
// encrypt buffer
//------------------------------------------------------------------------------


{$IFDEF ENCRYPTION_DEC5}

//----------------------------- DEC v.5. ---------------------------------------
procedure CPSEncryptBuffer(const CryptoInfo: TCPSCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr:   TDECCipher;
    hs:   TDECHash;
    hv:   Binary;
    l:    Integer;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 CPS_ENCRYPTED_DB_USED := True;
 hs := nil;
 l := Length(CryptoInfo.Password);
 case CryptoInfo.CryptoAlgorithm of
  CPS_Cipher_Rijndael_128, CPS_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create;
  CPS_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create;
  CPS_Cipher_Twofish_128,CPS_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create;
  CPS_Cipher_Square:
     cr := TCipher_Square.Create;
  CPS_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create;
  CPS_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create;
  CPS_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create;
  CPS_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create;
  CPS_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create;
  CPS_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create
 else
  raise ECPSException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 if (l > 0) then
  begin
   if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_Rijndael_128) or
      (CryptoInfo.CryptoAlgorithm = CPS_Cipher_Twofish_128) then
    hs := THash_RipeMD128.Create
   else
    hs := THash_RipeMD256.Create;
  end;
 try
  case CryptoInfo.CryptoMode of
   CPS_Cipher_Mode_CTS:   cr.Mode := cmCTSx;
   CPS_Cipher_Mode_CBC:   cr.Mode := cmCBCx; // 8?
   CPS_Cipher_Mode_CFB:   cr.Mode := cmCFBx; // 8?
   CPS_Cipher_Mode_OFB:   cr.Mode := cmOFBx; // 8?
   CPS_Cipher_Mode_CFS:   cr.Mode := cmCFSx;
   CPS_Cipher_Mode_ECB:   cr.Mode := cmECBx;
   CPS_Cipher_Mode_CFB8:  cr.Mode := cmCFB8;
   CPS_Cipher_Mode_OFB8:  cr.Mode := cmOFB8;
   CPS_Cipher_Mode_CFS8:  cr.Mode := cmOFB8
  else
   raise ECPSException.Create(10028,ErrorLUnknownCryptoMode,
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
 raise ECPSException.Create(10029,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // CPSEncryptBuffer

//------------------------------------------------------------------------------
// decrypt buffer
//------------------------------------------------------------------------------
procedure CPSDecryptBuffer(const CryptoInfo: TCPSCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr:   TDECCipher;
    hs:   TDECHash;
    hv:   Binary;
    l:    Integer;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 CPS_ENCRYPTED_DB_USED := True;
 hs := nil;
 l := Length(CryptoInfo.Password);
 case CryptoInfo.CryptoAlgorithm of
  CPS_Cipher_Rijndael_128, CPS_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create;
  CPS_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create;
  CPS_Cipher_Twofish_128,CPS_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create;
  CPS_Cipher_Square:
     cr := TCipher_Square.Create;
  CPS_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create;
  CPS_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create;
  CPS_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create;
  CPS_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create;
  CPS_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create;
  CPS_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create
 else
  raise ECPSException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 if (l > 0) then
  begin
   if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_Rijndael_128) or
      (CryptoInfo.CryptoAlgorithm = CPS_Cipher_Twofish_128) then
    hs := THash_RipeMD128.Create
   else
    hs := THash_RipeMD256.Create;
  end;
 try
  case CryptoInfo.CryptoMode of
   CPS_Cipher_Mode_CTS:   cr.Mode := cmCTSx;
   CPS_Cipher_Mode_CBC:   cr.Mode := cmCBCx; // 8?
   CPS_Cipher_Mode_CFB:   cr.Mode := cmCFBx; // 8?
   CPS_Cipher_Mode_OFB:   cr.Mode := cmOFBx; // 8?
   CPS_Cipher_Mode_CFS:   cr.Mode := cmCFSx;
   CPS_Cipher_Mode_ECB:   cr.Mode := cmECBx;
   CPS_Cipher_Mode_CFB8:  cr.Mode := cmCFB8;
   CPS_Cipher_Mode_OFB8:  cr.Mode := cmOFB8;
   CPS_Cipher_Mode_CFS8:  cr.Mode := cmOFB8
  else
   raise ECPSException.Create(10028,ErrorLUnknownCryptoMode,
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
 raise ECPSException.Create(10032,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // CPSDecryptBuffer


{$IFDEF X64_ON}
{$IFOPT R+} {$DEFINE RangeChecks_ON}    {$ENDIF}
{$IFOPT Q+} {$DEFINE OverflowChecks_ON} {$ENDIF}

{$RANGECHECKS OFF} {$OVERFLOWCHECKS OFF}
(*
const
  CRC32_Table : array[0..267] of dword = (
    $000000000,$077073096,$0EE0E612C,$0990951BA,$0076DC419,$0706AF48F,$0E963A535,$09E6495A3,$00EDB8832,$079DCB8A4,
    $0E0D5E91E,$097D2D988,$009B64C2B,$07EB17CBD,$0E7B82D07,$090BF1D91,$01DB71064,$06AB020F2,$0F3B97148,$084BE41DE,
    $01ADAD47D,$06DDDE4EB,$0F4D4B551,$083D385C7,$0136C9856,$0646BA8C0,$0FD62F97A,$08A65C9EC,$014015C4F,$063066CD9,
    $0FA0F3D63,$08D080DF5,$03B6E20C8,$04C69105E,$0D56041E4,$0A2677172,$03C03E4D1,$04B04D447,$0D20D85FD,$0A50AB56B,
    $035B5A8FA,$042B2986C,$0DBBBC9D6,$0ACBCF940,$032D86CE3,$045DF5C75,$0DCD60DCF,$0ABD13D59,$026D930AC,$051DE003A,
    $0C8D75180,$0BFD06116,$021B4F4B5,$056B3C423,$0CFBA9599,$0B8BDA50F,$02802B89E,$05F058808,$0C60CD9B2,$0B10BE924,
    $02F6F7C87,$058684C11,$0C1611DAB,$0B6662D3D,$076DC4190,$001DB7106,$098D220BC,$0EFD5102A,$071B18589,$006B6B51F,
    $09FBFE4A5,$0E8B8D433,$07807C9A2,$00F00F934,$09609A88E,$0E10E9818,$07F6A0DBB,$0086D3D2D,$091646C97,$0E6635C01,
    $06B6B51F4,$01C6C6162,$0856530D8,$0F262004E,$06C0695ED,$01B01A57B,$08208F4C1,$0F50FC457,$065B0D9C6,$012B7E950,
    $08BBEB8EA,$0FCB9887C,$062DD1DDF,$015DA2D49,$08CD37CF3,$0FBD44C65,$04DB26158,$03AB551CE,$0A3BC0074,$0D4BB30E2,
    $04ADFA541,$03DD895D7,$0A4D1C46D,$0D3D6F4FB,$04369E96A,$0346ED9FC,$0AD678846,$0DA60B8D0,$044042D73,$033031DE5,
    $0AA0A4C5F,$0DD0D7CC9,$05005713C,$0270241AA,$0BE0B1010,$0C90C2086,$05768B525,$0206F85B3,$0B966D409,$0CE61E49F,
    $05EDEF90E,$029D9C998,$0B0D09822,$0C7D7A8B4,$059B33D17,$02EB40D81,$0B7BD5C3B,$0C0BA6CAD,$0EDB88320,$09ABFB3B6,
    $003B6E20C,$074B1D29A,$0EAD54739,$09DD277AF,$004DB2615,$073DC1683,$0E3630B12,$094643B84,$00D6D6A3E,$07A6A5AA8,
    $0E40ECF0B,$09309FF9D,$00A00AE27,$07D079EB1,$0F00F9344,$08708A3D2,$01E01F268,$06906C2FE,$0F762575D,$0806567CB,
    $0196C3671,$06E6B06E7,$0FED41B76,$089D32BE0,$010DA7A5A,$067DD4ACC,$0F9B9DF6F,$08EBEEFF9,$017B7BE43,$060B08ED5,
    $0D6D6A3E8,$0A1D1937E,$038D8C2C4,$04FDFF252,$0D1BB67F1,$0A6BC5767,$03FB506DD,$048B2364B,$0D80D2BDA,$0AF0A1B4C,
    $036034AF6,$041047A60,$0DF60EFC3,$0A867DF55,$0316E8EEF,$04669BE79,$0CB61B38C,$0BC66831A,$0256FD2A0,$05268E236,
    $0CC0C7795,$0BB0B4703,$0220216B9,$05505262F,$0C5BA3BBE,$0B2BD0B28,$02BB45A92,$05CB36A04,$0C2D7FFA7,$0B5D0CF31,
    $02CD99E8B,$05BDEAE1D,$09B64C2B0,$0EC63F226,$0756AA39C,$0026D930A,$09C0906A9,$0EB0E363F,$072076785,$005005713,
    $095BF4A82,$0E2B87A14,$07BB12BAE,$00CB61B38,$092D28E9B,$0E5D5BE0D,$07CDCEFB7,$00BDBDF21,$086D3D2D4,$0F1D4E242,
    $068DDB3F8,$01FDA836E,$081BE16CD,$0F6B9265B,$06FB077E1,$018B74777,$088085AE6,$0FF0F6A70,$066063BCA,$011010B5C,
    $08F659EFF,$0F862AE69,$0616BFFD3,$0166CCF45,$0A00AE278,$0D70DD2EE,$04E048354,$03903B3C2,$0A7672661,$0D06016F7,
    $04969474D,$03E6E77DB,$0AED16A4A,$0D9D65ADC,$040DF0B66,$037D83BF0,$0A9BCAE53,$0DEBB9EC5,$047B2CF7F,$030B5FFE9,
    $0BDBDF21C,$0CABAC28A,$053B39330,$024B4A3A6,$0BAD03605,$0CDD70693,$054DE5729,$023D967BF,$0B3667A2E,$0C4614AB8,
    $05D681B02,$02A6F2B94,$0B40BBE37,$0C30C8EA1,$05A05DF1B,$02D02EF8D,$074726F50,$0736E6F69,$0706F4320,$067697279,
    $028207468,$031202963,$020393939,$048207962,$06E656761,$064655220,$06E616D64,$06FBBA36E
  );

function CPS_CRC32(CRC: Cardinal; Data: Pointer; DataSize: Cardinal): Cardinal;  register;
var
  wData : PByteArray absolute Data;
  i     : integer;
begin
  if ( Data <> nil ) and ( DataSize > 0 )
    then
      begin
        {CRC := not CRC;}
        for i := 0 to DataSize - 1 do
          CRC := CRC32_Table[ wData[i] xor byte(CRC) ] xor ( CRC shr 8 );
      end;
  Result := {not} CRC;
end;
*)
const
  CRC32_Table : array[0..267] of dword = (
    $000000000,$077073096,$0EE0E612C,$0990951BA,$0076DC419,$0706AF48F,$0E963A535,$09E6495A3,$00EDB8832,$079DCB8A4,
    $0E0D5E91E,$097D2D988,$009B64C2B,$07EB17CBD,$0E7B82D07,$090BF1D91,$01DB71064,$06AB020F2,$0F3B97148,$084BE41DE,
    $01ADAD47D,$06DDDE4EB,$0F4D4B551,$083D385C7,$0136C9856,$0646BA8C0,$0FD62F97A,$08A65C9EC,$014015C4F,$063066CD9,
    $0FA0F3D63,$08D080DF5,$03B6E20C8,$04C69105E,$0D56041E4,$0A2677172,$03C03E4D1,$04B04D447,$0D20D85FD,$0A50AB56B,
    $035B5A8FA,$042B2986C,$0DBBBC9D6,$0ACBCF940,$032D86CE3,$045DF5C75,$0DCD60DCF,$0ABD13D59,$026D930AC,$051DE003A,
    $0C8D75180,$0BFD06116,$021B4F4B5,$056B3C423,$0CFBA9599,$0B8BDA50F,$02802B89E,$05F058808,$0C60CD9B2,$0B10BE924,
    $02F6F7C87,$058684C11,$0C1611DAB,$0B6662D3D,$076DC4190,$001DB7106,$098D220BC,$0EFD5102A,$071B18589,$006B6B51F,
    $09FBFE4A5,$0E8B8D433,$07807C9A2,$00F00F934,$09609A88E,$0E10E9818,$07F6A0DBB,$0086D3D2D,$091646C97,$0E6635C01,
    $06B6B51F4,$01C6C6162,$0856530D8,$0F262004E,$06C0695ED,$01B01A57B,$08208F4C1,$0F50FC457,$065B0D9C6,$012B7E950,
    $08BBEB8EA,$0FCB9887C,$062DD1DDF,$015DA2D49,$08CD37CF3,$0FBD44C65,$04DB26158,$03AB551CE,$0A3BC0074,$0D4BB30E2,
    $04ADFA541,$03DD895D7,$0A4D1C46D,$0D3D6F4FB,$04369E96A,$0346ED9FC,$0AD678846,$0DA60B8D0,$044042D73,$033031DE5,
    $0AA0A4C5F,$0DD0D7CC9,$05005713C,$0270241AA,$0BE0B1010,$0C90C2086,$05768B525,$0206F85B3,$0B966D409,$0CE61E49F,
    $05EDEF90E,$029D9C998,$0B0D09822,$0C7D7A8B4,$059B33D17,$02EB40D81,$0B7BD5C3B,$0C0BA6CAD,$0EDB88320,$09ABFB3B6,
    $003B6E20C,$074B1D29A,$0EAD54739,$09DD277AF,$004DB2615,$073DC1683,$0E3630B12,$094643B84,$00D6D6A3E,$07A6A5AA8,
    $0E40ECF0B,$09309FF9D,$00A00AE27,$07D079EB1,$0F00F9344,$08708A3D2,$01E01F268,$06906C2FE,$0F762575D,$0806567CB,
    $0196C3671,$06E6B06E7,$0FED41B76,$089D32BE0,$010DA7A5A,$067DD4ACC,$0F9B9DF6F,$08EBEEFF9,$017B7BE43,$060B08ED5,
    $0D6D6A3E8,$0A1D1937E,$038D8C2C4,$04FDFF252,$0D1BB67F1,$0A6BC5767,$03FB506DD,$048B2364B,$0D80D2BDA,$0AF0A1B4C,
    $036034AF6,$041047A60,$0DF60EFC3,$0A867DF55,$0316E8EEF,$04669BE79,$0CB61B38C,$0BC66831A,$0256FD2A0,$05268E236,
    $0CC0C7795,$0BB0B4703,$0220216B9,$05505262F,$0C5BA3BBE,$0B2BD0B28,$02BB45A92,$05CB36A04,$0C2D7FFA7,$0B5D0CF31,
    $02CD99E8B,$05BDEAE1D,$09B64C2B0,$0EC63F226,$0756AA39C,$0026D930A,$09C0906A9,$0EB0E363F,$072076785,$005005713,
    $095BF4A82,$0E2B87A14,$07BB12BAE,$00CB61B38,$092D28E9B,$0E5D5BE0D,$07CDCEFB7,$00BDBDF21,$086D3D2D4,$0F1D4E242,
    $068DDB3F8,$01FDA836E,$081BE16CD,$0F6B9265B,$06FB077E1,$018B74777,$088085AE6,$0FF0F6A70,$066063BCA,$011010B5C,
    $08F659EFF,$0F862AE69,$0616BFFD3,$0166CCF45,$0A00AE278,$0D70DD2EE,$04E048354,$03903B3C2,$0A7672661,$0D06016F7,
    $04969474D,$03E6E77DB,$0AED16A4A,$0D9D65ADC,$040DF0B66,$037D83BF0,$0A9BCAE53,$0DEBB9EC5,$047B2CF7F,$030B5FFE9,
    $0BDBDF21C,$0CABAC28A,$053B39330,$024B4A3A6,$0BAD03605,$0CDD70693,$054DE5729,$023D967BF,$0B3667A2E,$0C4614AB8,
    $05D681B02,$02A6F2B94,$0B40BBE37,$0C30C8EA1,$05A05DF1B,$02D02EF8D,$074726F50,$0736E6F69,$0706F4320,$067697279,
    $028207468,$031202963,$020393939,$048207962,$06E656761,$064655220,$06E616D64,$06FBBA36E
  );

function CPS_CRC32(CRC: Cardinal; Data: Pointer; DataSize: Cardinal): Cardinal;  register;
var
  wData : PByteArray absolute Data;
  i     : integer;
begin
  if ( Data <> nil ) and ( DataSize > 0 )
    then
      begin
        {CRC := not CRC;}
        for i := 0 to DataSize - 1 do
          CRC := CRC32_Table[ Byte(wData[i]) xor byte(CRC) ] xor ( CRC shr 8 );
      end;
  Result := {not} CRC;
end;
{$IFDEF RangeChecks_ON}    {$RANGECHECKS ON}    {$UNDEF RangeChecks_ON}    {$ENDIF}
{$IFDEF OverflowChecks_ON} {$OVERFLOWCHECKS ON} {$UNDEF OverflowChecks_ON} {$ENDIF}

{$ELSE}

// DEC 3
function CPS_CRC32(CRC: Cardinal; Data: Pointer; DataSize: Cardinal): Cardinal; assembler; register;
asm
         AND    EDX,EDX
         JZ     @Exit
         AND    ECX,ECX
         JLE    @Exit
         PUSH   EBX
         PUSH   EDI
         XOR    EBX,EBX
         LEA    EDI,CS:[OFFSET @CRC_32]
@Start:  MOV    BL,AL
         SHR    EAX,8
         XOR    BL,[EDX]
         XOR    EAX,[EDI + EBX * 4]
         INC    EDX
         DEC    ECX
         JNZ    @Start
         POP    EDI
         POP    EBX
@Exit:   RET
         DB 0, 0, 0, 0, 0 // Align Table
@CRC_32: DD 000000000h, 077073096h, 0EE0E612Ch, 0990951BAh
         DD 0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h
         DD 00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h
         DD 009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h
         DD 01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh
         DD 01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h
         DD 0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh
         DD 014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h
         DD 03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h
         DD 03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh
         DD 035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h
         DD 032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h
         DD 026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h
         DD 021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh
         DD 02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h
         DD 02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh
         DD 076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah
         DD 071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h
         DD 07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h
         DD 07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h
         DD 06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh
         DD 06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h
         DD 065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch
         DD 062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h
         DD 04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h
         DD 04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh
         DD 04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h
         DD 044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h
         DD 05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h
         DD 05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh
         DD 05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h
         DD 059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh
         DD 0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah
         DD 0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h
         DD 0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h
         DD 0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h
         DD 0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh
         DD 0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h
         DD 0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh
         DD 0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h
         DD 0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h
         DD 0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh
         DD 0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h
         DD 0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h
         DD 0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h
         DD 0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh
         DD 0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h
         DD 0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh
         DD 09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah
         DD 09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h
         DD 095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h
         DD 092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h
         DD 086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh
         DD 081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h
         DD 088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch
         DD 08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h
         DD 0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h
         DD 0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh
         DD 0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h
         DD 0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h
         DD 0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h
         DD 0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh
         DD 0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h
         DD 0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh
         DD 074726F50h, 0736E6F69h, 0706F4320h, 067697279h
         DD 028207468h, 031202963h, 020393939h, 048207962h
         DD 06E656761h, 064655220h, 06E616D64h, 06FBBA36Eh
end; // CPS_CRC32
{$ENDIF}

//------------------------------------------------------------------------------
// calculate CRC32
//------------------------------------------------------------------------------
function CPSCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
begin
  Result := Cardinal(CPS_CRC32(Value,Buffer,BufferSize));
end; // CPSCountCRC


//------------------------------------------------------------------------------
// calculate CRC16
//------------------------------------------------------------------------------
function CPSCountCRC16(Value: Word; Buffer: PAnsiChar; BufferSize: Integer): Word; 
begin
{$IFDEF ENCRYPTION_ON}
  Result := CRC16(Value,Buffer^,BufferSize); 
{$ELSE} 
  Result := Word(CPS_CRC32(Value,Buffer,BufferSize)); 
{$ENDIF}
end; // CPSCountCRC16
	
	
//------------------------------------------------------------------------------
// generate random buffer 
//------------------------------------------------------------------------------ 
procedure CPSGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer); 
begin 
{$IFDEF ENCRYPTION_ON} 
 DoRandomSeed(Buffer^,-1);
 DoRandomBuffer(Buffer^,BufferSize);
{$ELSE} 
 raise ECPSException.Create(10035,ErrorLEncryptionIsSwitchedOff); 
{$ENDIF} 
end; // CPSGenerateRandomBuffer 
	
	
//------------------------------------------------------------------------------ 
// generate random buffer based on seed received from human input 
//------------------------------------------------------------------------------ 
procedure CPSGenerateRandomBuffer( 
                      Buffer:           PAnsiChar; 
                      BufferSize:       Integer; 
                      SeedBuffer:       PAnsiChar;
                      SeedBufferSize:   Integer
                                 );
begin
{$IFDEF ENCRYPTION_ON} 
 DoRandomSeed(SeedBuffer^,SeedBufferSize); 
 DoRandomBuffer(Buffer^,BufferSize);
{$ELSE} 
 raise ECPSException.Create(10096,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // CPSGenerateRandomBuffer


//----------------------------- DEC v.5. ---------------------------------------

{$ELSE}

//----------------------------- DEC v.3. ---------------------------------------

procedure CPSEncryptBuffer(const CryptoInfo: TCPSCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
{$IFDEF ENCRYPTION_ON}
var cr: TCipher;
{$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 case CryptoInfo.CryptoAlgorithm of
  CPS_Cipher_Rijndael_128:
   begin
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end;
  CPS_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Twofish_128:
   begin
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end;
  CPS_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Square:
     cr := TCipher_Square.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create(CryptoInfo.Password,nil)
 else
  raise ECPSException.Create(10027,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 try
  case CryptoInfo.CryptoMode of
   CPS_Cipher_Mode_CTS: cr.Mode := cmCTS;
   CPS_Cipher_Mode_CBC: cr.Mode := cmCBC;
   CPS_Cipher_Mode_CFB: cr.Mode := cmCFB;
   CPS_Cipher_Mode_OFB: cr.Mode := cmOFB;
  else
   raise ECPSException.Create(10028,ErrorLUnknownCryptoMode,
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
 raise ECPSException.Create(10029,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // CPSEncryptBuffer


//------------------------------------------------------------------------------
// decrypt buffer
//------------------------------------------------------------------------------
procedure CPSDecryptBuffer(const CryptoInfo: TCPSCryptoParams;
                                     Buffer: PAnsiChar; BufferSize: Integer);
 {$IFDEF ENCRYPTION_DEC5}
var cr: TDECCipher;
 {$ELSE}
var cr: TCipher;
 {$ENDIF}
begin
 if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_None) then
  Exit;
{$IFDEF ENCRYPTION_ON}
 CPS_ENCRYPTED_DB_USED := True;
 case CryptoInfo.CryptoAlgorithm of
  CPS_Cipher_Rijndael_128:
   begin
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end;
  CPS_Cipher_Rijndael_256:
     cr := TCipher_Rijndael.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Blowfish:
     cr := TCipher_Blowfish.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Twofish_128:
   begin
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
     cr.HashClass := THash_RipeMD128;
   end;
  CPS_Cipher_Twofish_256:
     cr := TCipher_Twofish.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Square:
     cr := TCipher_Square.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Single_8:
     cr := TCipher_1DES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Double_8:
     cr := TCipher_2DES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Double_16:
     cr := TCipher_2DDES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Triple_8:
     cr := TCipher_3DES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Triple_16:
     cr := TCipher_3DDES.Create(CryptoInfo.Password,nil);
  CPS_Cipher_Des_Triple_24:
     cr := TCipher_3TDES.Create(CryptoInfo.Password,nil)
 else
  raise ECPSException.Create(10030,ErrorLUnknownCryptoAlgorithm,
    [CryptoInfo.CryptoAlgorithm]);
 end;
 try
  case CryptoInfo.CryptoMode of
   CPS_Cipher_Mode_CTS: cr.Mode := cmCTS;
   CPS_Cipher_Mode_CBC: cr.Mode := cmCBC;
   CPS_Cipher_Mode_CFB: cr.Mode := cmCFB;
   CPS_Cipher_Mode_OFB: cr.Mode := cmOFB;
  else
   raise ECPSException.Create(10031,ErrorLUnknownCryptoMode,
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
 raise ECPSException.Create(10032,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // CPSDecryptBuffer


// DEC 3
function CPS_CRC32(CRC: Cardinal; Data: Pointer; DataSize: Cardinal): Cardinal; assembler; register;
asm
         AND    EDX,EDX
         JZ     @Exit
         AND    ECX,ECX
         JLE    @Exit
         PUSH   EBX
         PUSH   EDI
         XOR    EBX,EBX
         LEA    EDI,CS:[OFFSET @CRC_32]
@Start:  MOV    BL,AL
         SHR    EAX,8
         XOR    BL,[EDX]
         XOR    EAX,[EDI + EBX * 4]
         INC    EDX
         DEC    ECX
         JNZ    @Start
         POP    EDI
         POP    EBX
@Exit:   RET
         DB 0, 0, 0, 0, 0 // Align Table
@CRC_32: DD 000000000h, 077073096h, 0EE0E612Ch, 0990951BAh
         DD 0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h
         DD 00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h
         DD 009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h
         DD 01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh
         DD 01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h
         DD 0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh
         DD 014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h
         DD 03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h
         DD 03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh
         DD 035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h
         DD 032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h
         DD 026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h
         DD 021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh
         DD 02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h
         DD 02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh
         DD 076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah
         DD 071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h
         DD 07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h
         DD 07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h
         DD 06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh
         DD 06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h
         DD 065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch
         DD 062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h
         DD 04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h
         DD 04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh
         DD 04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h
         DD 044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h
         DD 05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h
         DD 05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh
         DD 05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h
         DD 059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh
         DD 0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah
         DD 0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h
         DD 0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h
         DD 0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h
         DD 0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh
         DD 0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h
         DD 0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh
         DD 0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h
         DD 0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h
         DD 0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh
         DD 0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h
         DD 0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h
         DD 0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h
         DD 0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh
         DD 0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h
         DD 0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh
         DD 09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah
         DD 09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h
         DD 095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h
         DD 092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h
         DD 086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh
         DD 081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h
         DD 088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch
         DD 08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h
         DD 0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h
         DD 0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh
         DD 0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h
         DD 0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h
         DD 0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h
         DD 0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh
         DD 0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h
         DD 0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh
         DD 074726F50h, 0736E6F69h, 0706F4320h, 067697279h
         DD 028207468h, 031202963h, 020393939h, 048207962h
         DD 06E656761h, 064655220h, 06E616D64h, 06FBBA36Eh
end; // CPS_CRC32


//------------------------------------------------------------------------------
// calculate CRC32
//------------------------------------------------------------------------------
function CPSCountCRC(Value: Cardinal; Buffer: PAnsiChar; BufferSize: Integer): Cardinal;
begin
  Result := CPS_CRC32(Value,Buffer,BufferSize);
end; // CPSCountCRC


//------------------------------------------------------------------------------
// calculate CRC16
//------------------------------------------------------------------------------
function CPSCountCRC16(Value: Word; Buffer: PAnsiChar; BufferSize: Integer): Word;
begin
{$IFDEF ENCRYPTION_ON}
  Result := CRC16(Value,Buffer,BufferSize);
{$ELSE}
  Result := Word(CPS_CRC32(Value,Buffer,BufferSize));
{$ENDIF}
end; // CPSCountCRC16


//------------------------------------------------------------------------------
// generate random buffer
//------------------------------------------------------------------------------
procedure CPSGenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
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
 raise ECPSException.Create(10035,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
end; // CPSGenerateRandomBuffer


//----------------------------- DEC v.3. ---------------------------------------
{$ENDIF}

//------------------------------------------------------------------------------
// create crypto header
//------------------------------------------------------------------------------
function CPSCreateCryptoHeader(const CryptoInfo: TCPSCryptoParams): TCPSCryptoHeader;
begin
 Result.CryptoAlgorithm := CryptoInfo.CryptoAlgorithm;
 if (Result.CryptoAlgorithm <> CPS_Cipher_None) then
  begin
{$IFDEF ENCRYPTION_ON}
   CPSGenerateRandomBuffer(@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.ControlBlockCRC := CPSCountCRC(0,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   Result.CryptoMode := CryptoInfo.CryptoMode;
   CPSEncryptBuffer(CryptoInfo,@Result.ControlBlock,Sizeof(Result.ControlBlock));
   // ask password or key if crypto info was not set
   if (CryptoInfo.Password = '') then
     Result.CryptoAskPassword := 0
   else
     Result.CryptoAskPassword := 1;
{$ELSE}
 raise ECPSException.Create(10036,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // CPSCreateCryptoHeader


//------------------------------------------------------------------------------
// Return true if CryptoHeader can be decrypted by KeyInfo
//------------------------------------------------------------------------------
function CPSIsKeyValid(const CryptoHeader: TCPSCryptoHeader; const CryptoInfo: TCPSCryptoParams): Boolean;
var ch: TCPSCryptoHeader;
begin
 if (CryptoInfo.CryptoAlgorithm = CPS_Cipher_None) then
  Result := True
 else
  begin
{$IFDEF ENCRYPTION_ON}
   ch := CryptoHeader;
   CPSDecryptBuffer(CryptoInfo,@ch.ControlBlock,Sizeof(ch.ControlBlock));
   Result := (ch.ControlBlockCRC = CPSCountCRC(0,@ch.ControlBlock,Sizeof(ch.ControlBlock)));
{$ELSE}
 raise ECPSException.Create(10037,ErrorLEncryptionIsSwitchedOff);
{$ENDIF}
  end;
end; // CPSIsKeyValid

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSCrypto> initialized');
{$ENDIF}

end.
