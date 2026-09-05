unit CPSConst;

interface

{$I CPSVer.inc}

{$I CPSErrorL.inc}

type TCPSSignature = array [0..3] of AnsiChar;

const CPSVersionText = '';
//const CPSVersionText = 'Prerelease version #2';
const CPSVersion = 4.00; // CryptoPressStream
var CPSSignaturev1: TCPSSignature = #0+'PS1'; // invalid first symbol
var CPSSignature: TCPSSignature = #0+'PS2'; // invalid first symbol
var CPS_ENCRYPTED_DB_USED: Boolean;
const CPSMaxVersion = 100.00001; // max version
      CPSMinVersion = 0.999999; // min version


const
{$IFDEF TRIAL_VERSION}
 {$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
    CPSBuildInfo = 'Trial Without Nag-Screen';
 {$ELSE}
    CPSBuildInfo = 'Trial With Nag-Screen';
 {$ENDIF}
{$ELSE}
 CPSBuildInfo = 'Full';
{$ENDIF}

//------------------------------------------------------------------------------
// disk consts
//------------------------------------------------------------------------------

{$IFDEF LINUX}
 const INVALID_FILE_SIZE = -1;
 const INVALID_HANDLE_VALUE = -1;
{$ENDIF}
 const CPSMinBlockSize = 10; // 10 bytes
 const CPSDefaultBlockSize = 1*1024*1024; // 1 Mb
 const CPSMinCompressionMode = 1;
 const CPSDefaultCompressionMode= 6;
 const CPSMaxCompressionMode = 9;
 const CPSMinNumCachedBlocks = 1;
 const CPSDefaultNumCachedBlocks = 1;
 const CPSMinMaxTempBufferSize = 1024;
 const CPSDefaultMaxTempBufferSize = 10*1024*1024;

//------------------- ENCRYPTION CONSTS -------------------------------------------

const CPS_Cipher_None = 0;
const CPS_Cipher_Rijndael_128 = 1;
const CPS_Cipher_Rijndael_256 = 2;
const CPS_Cipher_Blowfish = 3;
const CPS_Cipher_Twofish_128 = 4;
const CPS_Cipher_Twofish_256 = 5;
const CPS_Cipher_Square = 6;
const CPS_Cipher_Des_Single_8 = 7;
const CPS_Cipher_Des_Double_8 = 8;
const CPS_Cipher_Des_Double_16 = 9;
const CPS_Cipher_Des_Triple_8 = 10;
const CPS_Cipher_Des_Triple_16 = 11;
const CPS_Cipher_Des_Triple_24 = 12;
const CPS_MAX_Cipher = 12;

const CPS_Cipher_Mode_CTS = 0;
const CPS_Cipher_Mode_CBC = 1;
const CPS_Cipher_Mode_CFB = 2;
const CPS_Cipher_Mode_OFB = 3;
const CPS_Cipher_Mode_CFS = 4;
const CPS_Cipher_Mode_ECB = 5;
const CPS_Cipher_Mode_CFB8 = 6;
const CPS_Cipher_Mode_OFB8 = 7;
const CPS_Cipher_Mode_CFS8 = 8;
{$IFDEF ENCRYPTION_DEC5}
const CPS_MAX_Cipher_Mode = 8;
{$ELSE}
const CPS_MAX_Cipher_Mode = 3;
//const CPS_Cipher_Mode_ECB = 4;
{$ENDIF}
{
v 3
  cmCTS     Cipher Text Stealing, a Variant from cmCBC, but relaxes
            the restriction that the DataSize must be a mulitply from BufSize,
            this is the Defaultmode, fast and Bytewise
  cmCBC     Cipher Block Chaining
  cmCFB     K-bit Cipher Feedback, here is K = 8 -> 1 Byte
  cmOFB     K-bit Output Feedback, here is K = 8 -> 1 Byte
  cmECB *   Electronic Codebook, DataSize must be a multiply from BufSize

  cmCTSMAC  Build a Message Authentication Code in cmCTS Mode
  cmCBCMAC  Build a CBC-MAC
  cmCFBMAC  Build a CFB-MAC
v 5
  cmCTSx = double CBC, with CFS8 padding of truncated final block
  cmCBCx = Cipher Block Chainung, with CFB8 padding of truncated final block
  cmCFB8 = 8bit Cipher Feedback mode
  cmCFBx = CFB on Blocksize of Cipher
  cmOFB8 = 8bit Output Feedback mode
  cmOFBx = OFB on Blocksize bytes
  cmCFS8 = 8Bit CFS, double CFB
  cmCFSx = CFS on Blocksize bytes
  cmECBx = Electronic Code Book
}


const CPS_MAX_VECTOR = 31;
const CPS_MAX_KEY = 55;
const CPS_MAX_CONTROL_BLOCK = 31;

const CPSDefaultPassword = 'CPSpassword';
const Crlf: AnsiString = #$0D#$0A; // text mode line separator
const CPSSignature1 = 'C';

implementation

initialization


{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSConst initialization');
{$ENDIF}

CPSSignaturev1[0] := CPSSignature1;
CPSSignature[0] := CPSSignature1;
CPS_ENCRYPTED_DB_USED := False;

end.
