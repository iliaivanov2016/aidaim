unit SQLMemDecConst;

interface

{$I SQLMemVer.inc}
{$I Ver.inc}

{$IFDEF VER_D3H}
resourcestring
{$ELSE}
const
{$ENDIF}
// DECUTils.pas (all parts)
  sProtectionCircular  = 'Circular Protection detected, Protection Object is invalid.';
  sStringFormatExists  = 'String Format "%d" not exists.';
  sInvalidStringFormat = 'Input is not an valid %s Format.';
  sInvalidFormatString = 'Input can not be convert to %s Format.';
  sFMT_COPY            = 'copy Input to Output';
  sFMT_HEX             = 'Hexadecimal';
  sFMT_HEXL            = 'Hexadecimal lowercase';
  sFMT_MIME64          = 'MIME Base 64';
  sFMT_UU              = 'UU Coding';
  sFMT_XX              = 'XX Coding';
  
// Cipher.pas (Part I)
  sInvalidKey          = 'Encryptionkey is invalid';
  sInvalidCRC          = 'Encrypted Data is corrupt, invalid Checksum';
  sInvalidKeySize      = 'Length from Encryptionkey is invalid.'#13#10+
                         'Keysize for %s must be to %d-%d bytes';
  sNotInitialized      = '%s is not initialized call Init() or InitKey() before.';
  sInvalidMACMode      = 'Invalid Ciphermode selected to produce a MAC.'#13#10 +
                         'Please use Modes cmCBC, cmCTS, cmCFB, cmCBCMAC, cmCFBMAC or cmCTSMAC for CalcMAC.';
  sCantCalc            = 'Invalid Ciphermode selected.';
// RNG.pas    (Part I)
  sInvalidRandomStream = 'Invalid Random Data detected.';
  sRandomDataProtected = 'Random Data are protected.';
// BNG.pas    (Part II)
  sBBSnotSeekable      = 'BBS Generator is not seekable.';
  sBigNumDestroy       = 'Used Bignums in a BBS Generator can be not destroy.';
  sIndexOutOfRange     = 'BBS Error: Index out of Range.';
// BigNum.pas (Part II)
  sBigNumAborted       = 'BigNum aborted by User.';
  sErrGeneric          = 'Bignum Generic Error.';
  sErrAsInteger        = 'BigNum overflow in AsInteger.';
  sErrAsComp           = 'BigNum overflow in AsComp.';
  sErrAsFloat          = 'BigNum overflow in AsFloat.';
  sNumberFormat        = 'BigNum invalid Numberformat for Base %d.'#13#10'Value: %s';
  sDivByZero           = 'BigNum division by Zero.';
  sStackIndex          = 'BigNum Stackindex out of range.';
  sLoadFail            = 'BigNum invalid data format.';
  sParams              = 'BigNum parameter error.'#13#10'%s.';
  sJacobi              = 'BigNum Jacobi(A, B), B must be >= 3, Odd and B < A';
  sSPPrime             = 'BigNum IsSPPrime(A, Base), |Base| must be > 1, |A| > |Base| and |A| >= 3';
  sSetPrime            = 'BigNum SetPrime(Base, Residue, Modulus), Invalid Parameter.'#13#10'%s.';
  sSetPrimeSize        = 'Value must be greater 32767';
  sSetPrimeParam       = 'GCD(Residue, Modulus) must be 1 and Residue < Modulus';
  sSqrt                = 'BigNum Sqrt(A) A must be position';
  sExpMod              = 'BigNum ExpMod(E, M) M must be positive';
  sCalcName            = 'Calculation No %d';
// OTPass.pas   (Part III)
  sInvalidState        = 'Invalid Protector State detected.';
  sIDOutOfRange        = 'Protector Error: ID is out of Range.';
// Compress.pas (Part I)
  sInvalidZIPData      = 'Invalid compressed Data detected.';
// RFC2289.pas  (Part I)
  sInvalidChallenge    = 'Challenge is not an RFC2289 Format.';
  sInvalidPassword     = 'Invalid Passphraselength, must be more than 9 Chars.';
  sInvalidSeed         = 'Invalid Seed Value in OTPCalc.';
  sInvalidCalc         = 'Invalid Parameters in OTPCalc.';
  sInvalidDictionary   = 'Used Dictionary in %s is invalid.';
  sOTPIdent            = 'otp-';                      // RFC2289 Ident
  sOTPExt              = 'ext';                       // RFC2444
  sOTPWord             = 'word:';                     // RFC2444
  sOTPHex              = 'hex:';                      // RFC2444
  sSKeyIdent           = 's/key';                     // RFC1760 Ident

implementation

end.
