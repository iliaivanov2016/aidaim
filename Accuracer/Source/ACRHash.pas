{Copyright:      Hagen Reddmann  mailto:HaReddmann@AOL.COM
 Author:         Hagen Reddmann
 Remarks:        freeware, but this Copyright must be included
 known Problems: none
 Version:        3.0,  Part I from Delphi Encryption Compendium (DEC Part I)
                 Delphi 2-4, BCB 3-4, designed and testet under D3 and D4
 Description:    Include Objects for calculating various Hash's (fingerprints)
                 used Hash-Algorithm:
                   MD4, MD5, SHA, SHA1, RipeMD (128 - 320),
                   Haval (128 - 256), Snefru, Square, Tiger,
                   Sapphire II (128 - 320)
                 used Checksum-Algo:
                   CRC32, XOR32bit, XOR16bit, CRC16-CCITT, CRC16-Standard

 Comments:       for Designer's, the Buffer from Method Transform must be readonly

 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Digest size, Result from DigestKeySize and Datasize for Digest
   MD4         16 byte   128 bit   4x Integer
   MD5         16 byte   128 bit   4x Integer
   SHA         20 byte   160 bit   5x Integer
   SHA1        20 byte   160 bit   5x Integer
   RMD128      16 byte   128 bit   4x Integer
   RMD160      20 byte   160 bit   5x Integer
   RMD256      32 byte   256 bit   8x Integer
   RMD320      40 byte   320 bit  10x Integer
   Haval256    32 byte   256 bit   8x Integer
   Haval224    28 byte   224 bit   7x Integer
   Haval192    24 byte   192 bit   6x Integer
   Haval160    20 byte   160 bit   5x Integer
   Haval128    16 byte   128 bit   4x Integer
   Sapphire320 40 byte   320 bit  10x Integer
   Sapphire288 36 byte   288 bit   9x Integer
   Sapphire256 32 byte   256 bit   8x Integer
   Sapphire224 28 byte   224 bit   7x Integer
   Sapphire192 24 byte   192 bit   6x Integer
   Sapphire160 20 byte   160 bit   5x Integer
   Sapphire128 16 byte   128 bit   4x Integer
   Snefru      32 byte   256 bit   8x Integer
   Square      16 byte   128 bit   4x Integer
   Tiger       24 byte   192 bit   6x Integer   in D4 used 64bit Arithmetic

   XOR16     2 byte    16 bit   1x Word
   XOR32     4 byte    32 bit   1x Integer
   CRC32     4 byte    32 bit   1x Integer
   CRC16     2 byte    16 bit   1x Word
}

unit ACRHash;

interface

{$I ACRVer.inc}
{$I Ver.inc}

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     ACRDebug,
 {$ENDIF}
     ACRDECUtil;

type
{all Hash Classes}
  THash_MD4             = class;
  THash_MD5             = class;
  THash_RipeMD128       = class;
  THash_RipeMD160       = class;
  THash_RipeMD256       = class;
  THash_RipeMD320       = class;
  THash_SHA             = class;
  THash_SHA1            = class;
  THash_Square          = class; {demonstrate the using from a Cipher to hashing}
{all Checksum Classes}
  THash_XOR16           = class;
  THash_XOR32           = class;
  THash_CRC16_CCITT     = class;
  Thash_CRC16_Standard  = class;
  THash_CRC32           = class;


 {the Base-Class of all Hashs}

  THashClass = class of THash;

  THash = class(TProtection)
  protected
    class function TestVector: Pointer; virtual; {must override}
    procedure CodeInit(Action: TPAction); override; {TProtection Methods, You can use a Hash to En/Decode}
    procedure CodeDone(Action: TPAction); override; {TProtection Methods}
    procedure CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction); override; {TProtection Methods}
    procedure Protect(IsInit: Boolean); {calls any installed Protection}
  public
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Calc(const Data; DataSize: Integer); virtual; {must override}
    procedure Done; virtual;
    function DigestKey: Pointer; virtual; {must override}
    function DigestStr(Format: Integer): AnsiString;

    class function DigestKeySize: Integer; virtual; {must override}
{$IFDEF VER_D4H} // new features from D4
    class function CalcBuffer(const Buffer; BufferSize: Integer; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
    class function CalcStream(const Stream: TStream; StreamSize: Integer; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
    class function CalcAnsiString(const Data: AnsiString; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
    class function CalcFile(const FileName: AnsiString; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
{$ELSE}
    class function CalcBuffer(const Buffer; BufferSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
    class function CalcStream(const Stream: TStream; StreamSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
    class function CalcAnsiString(const Data: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
    class function CalcFile(const FileName: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
{$ENDIF}    
{test the correct working}
    class function SelfTest: Boolean;
  end;

// HMAC's - Hash Message Authentication Code's
  TMAC = class(TProtection) // generic MAC, encrypt Password with any AProtection and XOR's with
  protected                 // the Initstate from the Hash (DigestKey)
    FPassword: AnsiString;      // final Digest is encrypted with AProtecion
    procedure Init(Hash: THash); virtual;    // Only used in all THash Descends
    procedure Done(Hash: THash); virtual;    // Only used in all THash Descends
  public
    constructor Create(const Password: AnsiString; AProtection: TProtection);
    destructor Destroy; override;
  end;

  TMAC_RFC2104 = class(TMAC) // RFC2104 HMAC Protection, these make from any THash_XXX an HMAC-XXXX
  private                    // full compatible with RFC2104 Standard, see Docus\RFC2104 & RFC2202
    function CalcPad(Hash: Thash; XORCode: Byte): AnsiString;
  protected
    procedure Init(Hash: THash); override;
    procedure Done(Hash: THash); override;
  end;

  THash_MD4 = class(THash)
  private
    FCount: LongWord;
    FBuffer: array[0..63] of Byte;
    FDigest: array[0..9] of LongWord;
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); virtual;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Done; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

  THash_MD5 = class(THash_MD4)
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  end;

  THash_RipeMD128 = class(THash_MD4) {RACE Integrity Primitives Evaluation Message Digest}
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  end;

  THash_RipeMD160 = class(THash_MD4)
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  public
{DigestKey-Size 160 bit}
    class function DigestKeySize: Integer; override;
  end;

  THash_RipeMD256 = class(THash_MD4)
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  public
{DigestKey-Size 256 bit}
    class function DigestKeySize: Integer; override;
    procedure Init; override;
  end;

  THash_RipeMD320 = class(THash_MD4)
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  public
{DigestKey-Size 320 bit}
    class function DigestKeySize: Integer; override;
  end;

  THash_SHA = class(THash_RipeMD160)
  private
    FRotate: Boolean;
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  public
    procedure Done; override;
  end;

  THash_SHA1 = class(THash_SHA)
  protected
    class function TestVector: Pointer; override;
  public
    procedure Init; override;
  end;


  THash_Square = class(THash)
  private
    FCount: Integer;
    FBuffer: array[0..15] of Byte;
    FDigest: array[0..3] of LongWord;
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray);
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Done; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

  TChecksum = class(THash);
  
  THash_XOR16 = class(TChecksum)
  private
    FCRC: Word;
  protected
    class function TestVector: Pointer; override;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

  THash_XOR32 = class(TChecksum)
  private
    FCRC: LongWord;
  protected
    class function TestVector: Pointer; override;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

  THash_CRC32 = class(THash_XOR32)
  private
  protected
    class function TestVector: Pointer; override;
  public
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    procedure Done; override;
  end;

  THash_CRC16_CCITT = class(THash_XOR16)
  private
  protected
    class function TestVector: Pointer; override;
  public
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
  end;

  THash_CRC16_Standard = class(THash_XOR16)
  private
  protected
    class function TestVector: Pointer; override;
  public
    procedure Calc(const Data; DataSize: Integer); override;
  end;

function DefaultHashClass: THashClass;
procedure SetDefaultHashClass(HashClass: THashClass);
function RegisterHash(const AHash: THashClass; const AName, ADescription: AnsiString): Boolean;
function UnregisterHash(const AHash: THashClass): Boolean;
function HashList: TStrings;
procedure HashNames(List: TStrings);
function GetHashClass(const Name: AnsiString): THashClass;
function GetHashName(HashClass: THashClass): AnsiString;

implementation

{$I square.inc}

const
// used as default for TCipher in .InitKey(),
// the hashed Password is used as real Key,
// RipeMD256 produce a 256 bit Key (32 Bytes)
// a Key Attack have 2^256 Variants to test, when the
// Cipher all Bit's use, i.E. Blowfish, Gost, SCOP, Twofish
  FDefaultHashClass: THashClass = THash_RipeMD256;
  FHashList: TStringList = nil;

// RFC2104 HMAC Algorithm Parameters
  RFC2104_Size = 64;  // Size of Padding in Bytes
  RFC2104_IPad = $36; // XOR Value from Inner Pad
  RFC2104_OPad = $5C; // XOR Value from outer Pad

function DefaultHashClass: THashClass;
begin
  Result := FDefaultHashClass;
end;

procedure SetDefaultHashClass(HashClass: THashClass);
begin
  if HashClass = nil then FDefaultHashClass := THash_RipeMD256
    else FDefaultHashClass := HashClass;
end;

function RegisterHash(const AHash: THashClass; const AName, ADescription: AnsiString): Boolean;
var
  I: Integer;
  S: AnsiString;
begin
  Result := False;
  if AHash = nil then Exit;
  S := Trim(AName);
  if S = '' then
  begin
    S := AHash.ClassName;
    if S[1] = 'T' then Delete(S, 1, 1);
    I := Pos('_', S);
    if I > 0 then Delete(S, 1, I);
  end;
  S := S + '=' + ADescription;
  I := HashList.IndexOfObject(Pointer(AHash));
  if I < 0 then HashList.AddObject(S, Pointer(AHash))
    else HashList[I] := S;
  Result := True;
end;

function UnregisterHash(const AHash: THashClass): Boolean;
var
  I: Integer;
begin
  Result := False;
  repeat
    I := HashList.IndexOfObject(Pointer(AHash));
    if I < 0 then Break;
    Result := True;
    HashList.Delete(I);
  until False;
end;

function HashList: TStrings;
begin
  if not IsObject(FHashList, TStringList) then FHashList := TStringList.Create;
  Result := FHashList;
end;

procedure HashNames(List: TStrings);
var
  I: Integer;
begin
  if not IsObject(List, TStrings) then Exit;
  for I := 0 to HashList.Count-1 do
    List.AddObject(FHashList.Names[I], FHashList.Objects[I]);
end;

function GetHashClass(const Name: AnsiString): THashClass;
var
  I: Integer;
  N: AnsiString;
begin
  Result := nil;
  N := Name;
  I := Pos('_', N);
  if I > 0 then Delete(N, 1, I);
  for I := 0 to HashList.Count-1 do
    if AnsiCompareText(N, GetShortClassName(TClass(FHashList.Objects[I]))) = 0 then
    begin
      Result := THashClass(FHashList.Objects[I]);
      Exit;
    end;
  I := FHashList.IndexOfName(N);
  if I >= 0 then Result := THashClass(FHashList.Objects[I]);
end;

function GetHashName(HashClass: THashClass): AnsiString;
var
  I: Integer;
begin
  I := HashList.IndexOfObject(Pointer(HashClass));
  if I >= 0 then Result := FHashList.Names[I]
    else Result := GetShortClassName(HashClass);
end;

destructor THash.Destroy;
begin
  FillChar(DigestKey^, DigestKeySize, 0);
  inherited Destroy;
end;

procedure THash.Init;
begin
  Protect(True);
end;

procedure THash.Calc(const Data; DataSize: Integer);
begin
end;

procedure THash.Protect(IsInit: Boolean);
begin
  if Protection <> nil then
    if IsObject(Protection, TMAC) then
    begin
      with TMAC(Protection) do
        if IsInit then Init(Self) else Done(Self);
    end else
      if not IsInit then
        Protection.CodeBuffer(DigestKey^, DigestKeySize, paScramble);
end;

procedure THash.Done;
begin
  Protect(False);
end;

function THash.DigestKey: Pointer;
begin
  Result := GetTestVector;
end;

class function THash.DigestKeySize: Integer;
begin
  Result := 0;
end;

function THash.DigestStr(Format: Integer): AnsiString;
begin
  Result := StrToFormat(DigestKey, DigestKeySize, Format);
end;

class function THash.TestVector: Pointer;
begin
  Result := GetTestVector;
end;

class function THash.CalcStream(const Stream: TStream; StreamSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
const
  maxBufSize = 1024 * 4;  {Buffersize for File, Stream-Access}
var
  Buf: Pointer;
  BufSize: Integer;
  Size: Integer;
  Hash: THash;
begin
  Hash := Create(Protection);
  with Hash do
  try
    Buf := AllocMem(maxBufSize);
    Init;
    if StreamSize < 0 then
 {if Size < 0 then reset the Position, otherwise, calc with the specific
  Size and from the aktual Position in the Stream}
    begin
      Stream.Position := 0;
      StreamSize := Stream.Size;
    end;
    Size := StreamSize;
    DoProgress(Hash, 0, Size);
    repeat
      BufSize := StreamSize;
      if BufSize > maxBufSize then BufSize := maxBufSize;
      BufSize := Stream.Read(Buf^, BufSize);
      if BufSize <= 0 then Break;
      Calc(Buf^, BufSize);
      Dec(StreamSize, BufSize);
      DoProgress(Hash, Size - StreamSize, Size);
    until BufSize <= 0;
    Done;
    Result := StrToFormat(DigestKey, DigestKeySize, Format);
  finally
    DoProgress(Hash, 0, 0);
    Free;
    ReallocMem(Buf, 0);
  end;
end;

class function THash.CalcAnsiString(const Data: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
begin
  with Create(Protection) do
  try
    Init;
    Calc(PAnsiChar(Data)^, Length(Data));
    Done;
    Result := StrToFormat(DigestKey, DigestKeySize, Format);
  finally
    Free;
  end;
end;

class function THash.CalcFile(const FileName: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
var
  S: TFileStream;
begin
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := CalcStream(S, S.Size, Protection, Format);
  finally
    S.Free;
  end;
end;

class function THash.CalcBuffer(const Buffer; BufferSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
begin
  with Create(Protection) do {create an Object from my Classtype}
  try
    Init;
    Calc(Buffer, BufferSize);
    Done;
    Result := StrToFormat(DigestKey, DigestKeySize, Format);
  finally
    Free; {destroy it}
  end;
end;

class function THash.SelfTest: Boolean;
var
  Test: AnsiString;
begin
  Test := CalcBuffer(GetTestVector^, 32, nil, fmtCOPY);
  Result := InitTestIsOk and (MemCompare(PAnsiChar(Test), TestVector, Length(Test)) = 0);
end;

procedure THash.CodeInit(Action: TPAction);
begin
  Init;
  if Action = paWipe then RndXORBuffer(RndTimeSeed, DigestKey^, DigestKeySize);
  inherited CodeInit(Action);
end;

procedure THash.CodeDone(Action: TPAction);
begin
  inherited CodeDone(Action);
  if (Action <> paCalc) then Init else Done;
end;

procedure THash.CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction);
var
  BPtr: PByte;
  CSize,DSize,BSize: Integer;
begin
  if Action <> paDecode then inherited CodeBuf(Buffer, BufferSize, Action);
  if Action in Actions then
  begin
    BPtr := @Buffer;
    if BPtr = nil then Exit;
    DSize := DigestKeySize;
    CSize := BufferSize;
    if Action = paCalc then
    begin
      Calc(Buffer, BufferSize);
    end else
    begin
      if Action in [paScramble, paWipe] then
      begin
        while CSize > 0 do
        begin
          BSize := CSize;
          if BSize > DSize then BSize := DSize;
          Calc(BPtr^, BSize);
          Done;
          Move(DigestKey^, BPtr^, BSize);
          Dec(CSize, BSize);
          Inc(BPtr, BSize);
        end;
      end else
        while CSize > 0 do
        begin
          BSize := DSize;
          if BSize > CSize then BSize := CSize;
          Calc(DigestKey^, DSize);
          Done;
          XORBuffers(DigestKey, BPtr, BSize, BPtr);
          Dec(CSize, BSize);
          Inc(BPtr, BSize);
        end;
    end;
  end;
  if Action = paDecode then
    inherited CodeBuf(Buffer, BufferSize, Action);
end;

procedure TMAC.Init(Hash: THash);
var
  Key: AnsiString;
begin
  if Length(FPassword) > 0 then
  begin
    Key := Hash.CalcAnsiString(FPassword, Protection, fmtCOPY);
    XORBuffers(Hash.DigestKey, PAnsiChar(Key), Length(Key), Hash.DigestKey);
    FillChar(PAnsiChar(Key)^, Length(Key), $AA);
    FillChar(PAnsiChar(Key)^, Length(Key), $55);
    FillChar(PAnsiChar(Key)^, Length(Key), 0);
  end;
end;

procedure TMAC.Done(Hash: THash);
begin
  if Protection <> nil then
    Protection.CodeBuffer(Hash.DigestKey^, Hash.DigestKeySize, paScramble);
end;

constructor TMAC.Create(const Password: AnsiString; AProtection: TProtection);
begin
  inherited Create(AProtection);
  SetLength(FPassword, Length(Password));
  Move(PAnsiChar(Password)^, PAnsiChar(FPassword)^, Length(Password));
end;

destructor TMAC.Destroy;
var
  I: Integer;
begin
  I := Length(FPassword);
  if I > 0 then
  begin
    FillChar(PAnsiChar(FPassword)^, I, $AA);
    FillChar(PAnsiChar(FPassword)^, I, $55);
    FillChar(PAnsiChar(FPassword)^, I, 0);
  end;
  FPassword := '';
  inherited Destroy;
end;

function TMAC_RFC2104.CalcPad(Hash: THash; XORCode: Byte): AnsiString;
var
  I: Integer;
begin
  I := Length(FPassword);
  if I > RFC2104_Size then Result := Hash.CalcAnsiString(FPassword, nil, fmtCOPY)
    else Result := FPassword;
  UniqueString(Result);
  for I := 1 to Length(Result) do
    Byte(Result[I]) := Byte(Result[I]) xor XORCode;
  I := Length(Result);
  SetLength(Result, RFC2104_Size);
  FillChar(Result[I +1], RFC2104_Size - I, XORCode);
end;

procedure TMAC_RFC2104.Init(Hash: THash);
var
  IPad: AnsiString;
begin
  if Length(FPassword) > 0 then
  begin
    IPad := CalcPad(Hash, RFC2104_IPad);
    Hash.Calc(PAnsiChar(IPad)^, Length(IPad));
  end;
end;

procedure TMAC_RFC2104.Done(Hash: THash);
var
  OPad: AnsiString;
begin
  if Length(FPassword) > 0 then
  begin
    OPad := CalcPad(Hash, RFC2104_OPad);
    with THashClass(Hash.ClassType).Create(nil) do
    try
      Init;
      Calc(PAnsiChar(OPad)^, Length(OPad));
      Calc(Hash.DigestKey^, DigestKeySize);
      Done;
      Move(DigestKey^, Hash.DigestKey^, DigestKeySize);
    finally
      Free;
    end;
  end;
  if Protection <> nil then
    Protection.CodeBuffer(Hash.DigestKey^, Hash.DigestKeySize, paScramble);
end;

class function THash_MD4.TestVector: Pointer; assembler;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    025h,0EAh,0BFh,0CCh,08Ch,0C9h,06Fh,0D9h
         DB    02Dh,0CFh,07Eh,0BDh,07Fh,087h,07Ch,07Ch
end;

procedure THash_MD4.Transform(Buffer: PIntArray);
{calculate the Digest, fast}
var
  A, B, C, D: LongWord;
begin
  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];

  Inc(A, Buffer[ 0] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 1] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[ 2] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[ 3] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[ 4] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 5] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[ 6] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[ 7] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[ 8] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 9] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[10] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[11] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[12] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[13] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[14] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[15] + (C and D or not C and A)); B := B shl 19 or B shr 13;

  Inc(A, Buffer[ 0] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 4] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[ 8] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[12] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 1] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 5] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[ 9] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[13] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 2] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 6] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[10] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[14] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 3] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 7] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[11] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[15] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;

  Inc(A, Buffer[ 0] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 8] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 4] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[12] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 2] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[10] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 6] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[14] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 1] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 9] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 5] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[13] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 3] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[11] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 7] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[15] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
end;

class function THash_MD4.DigestKeySize: Integer;
begin
  Result := 16;
end;

function THash_MD4.DigestKey: Pointer;
begin
  Result := @FDigest;
end;

procedure THash_MD4.Init;
begin
  FillChar(FBuffer, SizeOf(FBuffer), 0);
{all Descend from MD4 (MD4, SHA1, RipeMD128, RipeMD160, RipeMD256) use this Init-Key}
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FDigest[4] := $C3D2E1F0;
{for RMD320}
  FDigest[5] := $76543210;
  FDigest[6] := $FEDCBA98;
  FDigest[7] := $89ABCDEF;
  FDigest[8] := $01234567;
  FDigest[9] := $3C2D1E0F;
  FCount := 0;
  Protect(True);
end;

procedure THash_MD4.Done;
var
  I: Integer;
  S: Comp;
begin
  I := FCount and $3F;
  FBuffer[I] := $80;
  Inc(I);
  if I > 64 - 8 then
  begin
    FillChar(FBuffer[I], 64 - I, 0);
    Transform(@FBuffer);
    I := 0;
  end;
  FillChar(FBuffer[I], 64 - I, 0);
  S := FCount * 8;
  Move(S, FBuffer[64 - 8], SizeOf(S));
  Transform(@FBuffer);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  Protect(False);
end;

procedure THash_MD4.Calc(const Data; DataSize: Integer);
var
  Index: Integer;
  P: PAnsiChar;
begin
  if DataSize <= 0 then Exit;
  Index := FCount and $3F;
  Inc(FCount, DataSize);
  if Index > 0 then
  begin
    if DataSize < 64 - Index then
    begin
      Move(Data, FBuffer[Index], DataSize);
      Exit;
    end;
    Move(Data, FBuffer[Index], 64 - Index);
    Transform(@FBuffer);
    Index := 64 - Index;
    Dec(DataSize, Index);
  end;
  P := @TByteArray(Data)[Index];
  Inc(Index, DataSize and not $3F);
  while DataSize >= 64 do
  begin
    Transform(Pointer(P));
    Inc(P, 64);
    Dec(DataSize, 64);
  end;
  Move(TByteArray(Data)[Index], FBuffer, DataSize);
end;

class function THash_MD5.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    03Eh,0D8h,034h,08Ch,0D2h,0A4h,045h,0D6h
         DB    075h,05Dh,04Bh,0C9h,0FEh,0DCh,0C2h,0C6h
end;

procedure THash_MD5.Transform(Buffer: PIntArray);
var
  A, B, C, D: LongWord;
begin
  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];

  Inc(A, Buffer[ 0] + $D76AA478 + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 1] + $E8C7B756 + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[ 2] + $242070DB + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[ 3] + $C1BDCEEE + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[ 4] + $F57C0FAF + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 5] + $4787C62A + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[ 6] + $A8304613 + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[ 7] + $FD469501 + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[ 8] + $698098D8 + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 9] + $8B44F7AF + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[10] + $FFFF5BB1 + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[11] + $895CD7BE + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[12] + $6B901122 + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[13] + $FD987193 + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[14] + $A679438E + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[15] + $49B40821 + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;

  Inc(A, Buffer[ 1] + $F61E2562 + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[ 6] + $C040B340 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[11] + $265E5A51 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 0] + $E9B6C7AA + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[ 5] + $D62F105D + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[10] + $02441453 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[15] + $D8A1E681 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 4] + $E7D3FBC8 + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[ 9] + $21E1CDE6 + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[14] + $C33707D6 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[ 3] + $F4D50D87 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 8] + $455A14ED + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[13] + $A9E3E905 + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[ 2] + $FCEFA3F8 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[ 7] + $676F02D9 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[12] + $8D2A4C8A + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;

  Inc(A, Buffer[ 5] + $FFFA3942 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 8] + $8771F681 + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[11] + $6D9D6122 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[14] + $FDE5380C + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[ 1] + $A4BEEA44 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 4] + $4BDECFA9 + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[ 7] + $F6BB4B60 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[10] + $BEBFBC70 + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[13] + $289B7EC6 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 0] + $EAA127FA + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[ 3] + $D4EF3085 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[ 6] + $04881D05 + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[ 9] + $D9D4D039 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[12] + $E6DB99E5 + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[15] + $1FA27CF8 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[ 2] + $C4AC5665 + (C xor D xor A)); B := B shl 23 or B shr  9 + C;

  Inc(A, Buffer[ 0] + $F4292244 + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[ 7] + $432AFF97 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[14] + $AB9423A7 + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 5] + $FC93A039 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[12] + $655B59C3 + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[ 3] + $8F0CCC92 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[10] + $FFEFF47D + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 1] + $85845DD1 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[ 8] + $6FA87E4F + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[15] + $FE2CE6E0 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[ 6] + $A3014314 + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[13] + $4E0811A1 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[ 4] + $F7537E82 + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[11] + $BD3AF235 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[ 2] + $2AD7D2BB + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 9] + $EB86D391 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
end;

class function THash_RipeMD128.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0CFh,0A0h,032h,0CFh,0D0h,08Fh,087h,03Ah
         DB    078h,0DFh,013h,0E7h,0EBh,0CDh,098h,00Fh
end;

procedure THash_RipeMD128.Transform(Buffer: PIntArray);
var
  A1, B1, C1, D1: LongWord;
  A2, B2, C2, D2: LongWord;
begin
  A1 := FDigest[0];
  B1 := FDigest[1];
  C1 := FDigest[2];
  D1 := FDigest[3];
  A2 := A1;
  B2 := B1;
  C2 := C1;
  D2 := D1;

  Inc(A1, B1 xor C1 xor D1 + Buffer[ 0]); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 1]); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 2]); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 3]); B1 := B1 shl 12 or B1 shr 20;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 4]); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 5]); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 6]); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 7]); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 8]); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 9]); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 xor A1 xor B1 + Buffer[10]); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 xor D1 xor A1 + Buffer[11]); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 xor C1 xor D1 + Buffer[12]); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 xor B1 xor C1 + Buffer[13]); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 xor A1 xor B1 + Buffer[14]); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 xor D1 xor A1 + Buffer[15]); B1 := B1 shl  8 or B1 shr 24;

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + $5A827999); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 4] + $5A827999); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[13] + $5A827999); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 1] + $5A827999); B1 := B1 shl 13 or B1 shr 19;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + $5A827999); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 6] + $5A827999); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[15] + $5A827999); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + $5A827999); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[12] + $5A827999); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + $5A827999); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 9] + $5A827999); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 5] + $5A827999); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 2] + $5A827999); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + $5A827999); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[11] + $5A827999); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 8] + $5A827999); B1 := B1 shl 12 or B1 shr 20;

  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 3] + $6ED9EBA1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[10] + $6ED9EBA1); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[14] + $6ED9EBA1); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 4] + $6ED9EBA1); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 9] + $6ED9EBA1); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[15] + $6ED9EBA1); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 8] + $6ED9EBA1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 1] + $6ED9EBA1); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 2] + $6ED9EBA1); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[ 7] + $6ED9EBA1); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 0] + $6ED9EBA1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 6] + $6ED9EBA1); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[13] + $6ED9EBA1); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[11] + $6ED9EBA1); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 5] + $6ED9EBA1); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[12] + $6ED9EBA1); B1 := B1 shl  5 or B1 shr 27;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + $8F1BBCDC); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 9] + $8F1BBCDC); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + $8F1BBCDC); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[10] + $8F1BBCDC); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 0] + $8F1BBCDC); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 8] + $8F1BBCDC); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[12] + $8F1BBCDC); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + $8F1BBCDC); B1 := B1 shl  8 or B1 shr 24;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + $8F1BBCDC); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 3] + $8F1BBCDC); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + $8F1BBCDC); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[15] + $8F1BBCDC); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[14] + $8F1BBCDC); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 5] + $8F1BBCDC); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 6] + $8F1BBCDC); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 2] + $8F1BBCDC); B1 := B1 shl 12 or B1 shr 20;

  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 5] + $50A28BE6); A2 := A2 shl  8 or A2 shr 24;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[14] + $50A28BE6); D2 := D2 shl  9 or D2 shr 23;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[ 7] + $50A28BE6); C2 := C2 shl  9 or C2 shr 23;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 0] + $50A28BE6); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 9] + $50A28BE6); A2 := A2 shl 13 or A2 shr 19;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[ 2] + $50A28BE6); D2 := D2 shl 15 or D2 shr 17;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[11] + $50A28BE6); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 4] + $50A28BE6); B2 := B2 shl  5 or B2 shr 27;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[13] + $50A28BE6); A2 := A2 shl  7 or A2 shr 25;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[ 6] + $50A28BE6); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[15] + $50A28BE6); C2 := C2 shl  8 or C2 shr 24;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 8] + $50A28BE6); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 1] + $50A28BE6); A2 := A2 shl 14 or A2 shr 18;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[10] + $50A28BE6); D2 := D2 shl 14 or D2 shr 18;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[ 3] + $50A28BE6); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[12] + $50A28BE6); B2 := B2 shl  6 or B2 shr 26;

  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 6] + $5C4DD124); A2 := A2 shl  9 or A2 shr 23;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[11] + $5C4DD124); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 3] + $5C4DD124); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[ 7] + $5C4DD124); B2 := B2 shl  7 or B2 shr 25;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 0] + $5C4DD124); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[13] + $5C4DD124); D2 := D2 shl  8 or D2 shr 24;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 5] + $5C4DD124); C2 := C2 shl  9 or C2 shr 23;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[10] + $5C4DD124); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[14] + $5C4DD124); A2 := A2 shl  7 or A2 shr 25;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[15] + $5C4DD124); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 8] + $5C4DD124); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[12] + $5C4DD124); B2 := B2 shl  7 or B2 shr 25;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 4] + $5C4DD124); A2 := A2 shl  6 or A2 shr 26;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[ 9] + $5C4DD124); D2 := D2 shl 15 or D2 shr 17;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 1] + $5C4DD124); C2 := C2 shl 13 or C2 shr 19;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[ 2] + $5C4DD124); B2 := B2 shl 11 or B2 shr 21;

  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[15] + $6D703EF3); A2 := A2 shl  9 or A2 shr 23;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 5] + $6D703EF3); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 1] + $6D703EF3); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 3] + $6D703EF3); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[ 7] + $6D703EF3); A2 := A2 shl  8 or A2 shr 24;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[14] + $6D703EF3); D2 := D2 shl  6 or D2 shr 26;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 6] + $6D703EF3); C2 := C2 shl  6 or C2 shr 26;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 9] + $6D703EF3); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[11] + $6D703EF3); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 8] + $6D703EF3); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[12] + $6D703EF3); C2 := C2 shl  5 or C2 shr 27;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 2] + $6D703EF3); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[10] + $6D703EF3); A2 := A2 shl 13 or A2 shr 19;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 0] + $6D703EF3); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 4] + $6D703EF3); C2 := C2 shl  7 or C2 shr 25;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[13] + $6D703EF3); B2 := B2 shl  5 or B2 shr 27;

  Inc(A2, B2 xor C2 xor D2 + Buffer[ 8]); A2 := A2 shl 15 or A2 shr 17;
  Inc(D2, A2 xor B2 xor C2 + Buffer[ 6]); D2 := D2 shl  5 or D2 shr 27;
  Inc(C2, D2 xor A2 xor B2 + Buffer[ 4]); C2 := C2 shl  8 or C2 shr 24;
  Inc(B2, C2 xor D2 xor A2 + Buffer[ 1]); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 3]); A2 := A2 shl 14 or A2 shr 18;
  Inc(D2, A2 xor B2 xor C2 + Buffer[11]); D2 := D2 shl 14 or D2 shr 18;
  Inc(C2, D2 xor A2 xor B2 + Buffer[15]); C2 := C2 shl  6 or C2 shr 26;
  Inc(B2, C2 xor D2 xor A2 + Buffer[ 0]); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 5]); A2 := A2 shl  6 or A2 shr 26;
  Inc(D2, A2 xor B2 xor C2 + Buffer[12]); D2 := D2 shl  9 or D2 shr 23;
  Inc(C2, D2 xor A2 xor B2 + Buffer[ 2]); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, C2 xor D2 xor A2 + Buffer[13]); B2 := B2 shl  9 or B2 shr 23;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 9]); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, A2 xor B2 xor C2 + Buffer[ 7]); D2 := D2 shl  5 or D2 shr 27;
  Inc(C2, D2 xor A2 xor B2 + Buffer[10]); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 xor D2 xor A2 + Buffer[14]); B2 := B2 shl  8 or B2 shr 24;

  Inc(D2, C1 + FDigest[1]);
  FDigest[1] := FDigest[2] + D1 + A2;
  FDigest[2] := FDigest[3] + A1 + B2;
  FDigest[3] := FDIgest[0] + B1 + C2;
  FDigest[0] := D2;
end;

class function THash_RipeMD160.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    019h,054h,0DEh,0BCh,01Bh,055h,035h,030h
         DB    008h,01Dh,09Bh,080h,070h,0A0h,0F2h,04Ah
         DB    09Dh,0F7h,034h,004h
end;

procedure THash_RipeMD160.Transform(Buffer: PIntArray);
var
  A1, B1, C1, D1, E1: LongWord;
  A, B, C, D, E: LongWord;
begin
  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];
  E := FDigest[4];

  Inc(A, Buffer[ 0] + (B xor C xor D)); A := A shl 11 or A shr 21 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 1] + (A xor B xor C)); E := E shl 14 or E shr 18 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 2] + (E xor A xor B)); D := D shl 15 or D shr 17 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 3] + (D xor E xor A)); C := C shl 12 or C shr 20 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 4] + (C xor D xor E)); B := B shl  5 or B shr 27 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 5] + (B xor C xor D)); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 6] + (A xor B xor C)); E := E shl  7 or E shr 25 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 7] + (E xor A xor B)); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 8] + (D xor E xor A)); C := C shl 11 or C shr 21 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 9] + (C xor D xor E)); B := B shl 13 or B shr 19 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[10] + (B xor C xor D)); A := A shl 14 or A shr 18 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[11] + (A xor B xor C)); E := E shl 15 or E shr 17 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[12] + (E xor A xor B)); D := D shl  6 or D shr 26 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[13] + (D xor E xor A)); C := C shl  7 or C shr 25 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[14] + (C xor D xor E)); B := B shl  9 or B shr 23 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[15] + (B xor C xor D)); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;

  Inc(E, Buffer[ 7] + $5A827999 + ((A and B) or (not A and C))); E := E shl  7 or E shr 25 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 4] + $5A827999 + ((E and A) or (not E and B))); D := D shl  6 or D shr 26 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[13] + $5A827999 + ((D and E) or (not D and A))); C := C shl  8 or C shr 24 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 1] + $5A827999 + ((C and D) or (not C and E))); B := B shl 13 or B shr 19 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[10] + $5A827999 + ((B and C) or (not B and D))); A := A shl 11 or A shr 21 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 6] + $5A827999 + ((A and B) or (not A and C))); E := E shl  9 or E shr 23 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[15] + $5A827999 + ((E and A) or (not E and B))); D := D shl  7 or D shr 25 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 3] + $5A827999 + ((D and E) or (not D and A))); C := C shl 15 or C shr 17 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[12] + $5A827999 + ((C and D) or (not C and E))); B := B shl  7 or B shr 25 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 0] + $5A827999 + ((B and C) or (not B and D))); A := A shl 12 or A shr 20 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 9] + $5A827999 + ((A and B) or (not A and C))); E := E shl 15 or E shr 17 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 5] + $5A827999 + ((E and A) or (not E and B))); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 2] + $5A827999 + ((D and E) or (not D and A))); C := C shl 11 or C shr 21 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[14] + $5A827999 + ((C and D) or (not C and E))); B := B shl  7 or B shr 25 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[11] + $5A827999 + ((B and C) or (not B and D))); A := A shl 13 or A shr 19 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 8] + $5A827999 + ((A and B) or (not A and C))); E := E shl 12 or E shr 20 + D; B := B shl 10 or B shr 22;

  Inc(D, Buffer[ 3] + $6ED9EBA1 + ((E or not A) xor B)); D := D shl 11 or D shr 21 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[10] + $6ED9EBA1 + ((D or not E) xor A)); C := C shl 13 or C shr 19 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[14] + $6ED9EBA1 + ((C or not D) xor E)); B := B shl  6 or B shr 26 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 4] + $6ED9EBA1 + ((B or not C) xor D)); A := A shl  7 or A shr 25 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 9] + $6ED9EBA1 + ((A or not B) xor C)); E := E shl 14 or E shr 18 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[15] + $6ED9EBA1 + ((E or not A) xor B)); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 8] + $6ED9EBA1 + ((D or not E) xor A)); C := C shl 13 or C shr 19 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 1] + $6ED9EBA1 + ((C or not D) xor E)); B := B shl 15 or B shr 17 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 2] + $6ED9EBA1 + ((B or not C) xor D)); A := A shl 14 or A shr 18 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 7] + $6ED9EBA1 + ((A or not B) xor C)); E := E shl  8 or E shr 24 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 0] + $6ED9EBA1 + ((E or not A) xor B)); D := D shl 13 or D shr 19 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 6] + $6ED9EBA1 + ((D or not E) xor A)); C := C shl  6 or C shr 26 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[13] + $6ED9EBA1 + ((C or not D) xor E)); B := B shl  5 or B shr 27 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[11] + $6ED9EBA1 + ((B or not C) xor D)); A := A shl 12 or A shr 20 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 5] + $6ED9EBA1 + ((A or not B) xor C)); E := E shl  7 or E shr 25 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[12] + $6ED9EBA1 + ((E or not A) xor B)); D := D shl  5 or D shr 27 + C; A := A shl 10 or A shr 22;

  Inc(C, Buffer[ 1] + $8F1BBCDC + ((D and A) or (E and not A))); C := C shl 11 or C shr 21 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 9] + $8F1BBCDC + ((C and E) or (D and not E))); B := B shl 12 or B shr 20 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[11] + $8F1BBCDC + ((B and D) or (C and not D))); A := A shl 14 or A shr 18 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[10] + $8F1BBCDC + ((A and C) or (B and not C))); E := E shl 15 or E shr 17 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 0] + $8F1BBCDC + ((E and B) or (A and not B))); D := D shl 14 or D shr 18 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 8] + $8F1BBCDC + ((D and A) or (E and not A))); C := C shl 15 or C shr 17 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[12] + $8F1BBCDC + ((C and E) or (D and not E))); B := B shl  9 or B shr 23 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 4] + $8F1BBCDC + ((B and D) or (C and not D))); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[13] + $8F1BBCDC + ((A and C) or (B and not C))); E := E shl  9 or E shr 23 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 3] + $8F1BBCDC + ((E and B) or (A and not B))); D := D shl 14 or D shr 18 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 7] + $8F1BBCDC + ((D and A) or (E and not A))); C := C shl  5 or C shr 27 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[15] + $8F1BBCDC + ((C and E) or (D and not E))); B := B shl  6 or B shr 26 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[14] + $8F1BBCDC + ((B and D) or (C and not D))); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 5] + $8F1BBCDC + ((A and C) or (B and not C))); E := E shl  6 or E shr 26 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 6] + $8F1BBCDC + ((E and B) or (A and not B))); D := D shl  5 or D shr 27 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 2] + $8F1BBCDC + ((D and A) or (E and not A))); C := C shl 12 or C shr 20 + B; E := E shl 10 or E shr 22;

  Inc(B, Buffer[ 4] + $A953FD4E + (C xor (D or not E))); B := B shl  9 or B shr 23 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 0] + $A953FD4E + (B xor (C or not D))); A := A shl 15 or A shr 17 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 5] + $A953FD4E + (A xor (B or not C))); E := E shl  5 or E shr 27 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 9] + $A953FD4E + (E xor (A or not B))); D := D shl 11 or D shr 21 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 7] + $A953FD4E + (D xor (E or not A))); C := C shl  6 or C shr 26 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[12] + $A953FD4E + (C xor (D or not E))); B := B shl  8 or B shr 24 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 2] + $A953FD4E + (B xor (C or not D))); A := A shl 13 or A shr 19 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[10] + $A953FD4E + (A xor (B or not C))); E := E shl 12 or E shr 20 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[14] + $A953FD4E + (E xor (A or not B))); D := D shl  5 or D shr 27 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 1] + $A953FD4E + (D xor (E or not A))); C := C shl 12 or C shr 20 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 3] + $A953FD4E + (C xor (D or not E))); B := B shl 13 or B shr 19 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 8] + $A953FD4E + (B xor (C or not D))); A := A shl 14 or A shr 18 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[11] + $A953FD4E + (A xor (B or not C))); E := E shl 11 or E shr 21 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 6] + $A953FD4E + (E xor (A or not B))); D := D shl  8 or D shr 24 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[15] + $A953FD4E + (D xor (E or not A))); C := C shl  5 or C shr 27 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[13] + $A953FD4E + (C xor (D or not E))); B := B shl  6 or B shr 26 + A; D := D shl 10 or D shr 22;

  A1 := A;
  B1 := B;
  C1 := C;
  D1 := D;
  E1 := E;

  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];
  E := FDigest[4];

  Inc(A, Buffer[ 5] + $50A28BE6 + (B xor (C or not D))); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[14] + $50A28BE6 + (A xor (B or not C))); E := E shl  9 or E shr 23 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 7] + $50A28BE6 + (E xor (A or not B))); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 0] + $50A28BE6 + (D xor (E or not A))); C := C shl 11 or C shr 21 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 9] + $50A28BE6 + (C xor (D or not E))); B := B shl 13 or B shr 19 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 2] + $50A28BE6 + (B xor (C or not D))); A := A shl 15 or A shr 17 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[11] + $50A28BE6 + (A xor (B or not C))); E := E shl 15 or E shr 17 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 4] + $50A28BE6 + (E xor (A or not B))); D := D shl  5 or D shr 27 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[13] + $50A28BE6 + (D xor (E or not A))); C := C shl  7 or C shr 25 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 6] + $50A28BE6 + (C xor (D or not E))); B := B shl  7 or B shr 25 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[15] + $50A28BE6 + (B xor (C or not D))); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 8] + $50A28BE6 + (A xor (B or not C))); E := E shl 11 or E shr 21 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 1] + $50A28BE6 + (E xor (A or not B))); D := D shl 14 or D shr 18 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[10] + $50A28BE6 + (D xor (E or not A))); C := C shl 14 or C shr 18 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 3] + $50A28BE6 + (C xor (D or not E))); B := B shl 12 or B shr 20 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[12] + $50A28BE6 + (B xor (C or not D))); A := A shl  6 or A shr 26 + E; C := C shl 10 or C shr 22;

  Inc(E, Buffer[ 6] + $5C4DD124 + ((A and C) or (B and not C))); E := E shl  9 or E shr 23 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[11] + $5C4DD124 + ((E and B) or (A and not B))); D := D shl 13 or D shr 19 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 3] + $5C4DD124 + ((D and A) or (E and not A))); C := C shl 15 or C shr 17 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 7] + $5C4DD124 + ((C and E) or (D and not E))); B := B shl  7 or B shr 25 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 0] + $5C4DD124 + ((B and D) or (C and not D))); A := A shl 12 or A shr 20 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[13] + $5C4DD124 + ((A and C) or (B and not C))); E := E shl  8 or E shr 24 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 5] + $5C4DD124 + ((E and B) or (A and not B))); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[10] + $5C4DD124 + ((D and A) or (E and not A))); C := C shl 11 or C shr 21 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[14] + $5C4DD124 + ((C and E) or (D and not E))); B := B shl  7 or B shr 25 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[15] + $5C4DD124 + ((B and D) or (C and not D))); A := A shl  7 or A shr 25 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 8] + $5C4DD124 + ((A and C) or (B and not C))); E := E shl 12 or E shr 20 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[12] + $5C4DD124 + ((E and B) or (A and not B))); D := D shl  7 or D shr 25 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 4] + $5C4DD124 + ((D and A) or (E and not A))); C := C shl  6 or C shr 26 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 9] + $5C4DD124 + ((C and E) or (D and not E))); B := B shl 15 or B shr 17 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 1] + $5C4DD124 + ((B and D) or (C and not D))); A := A shl 13 or A shr 19 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 2] + $5C4DD124 + ((A and C) or (B and not C))); E := E shl 11 or E shr 21 + D; B := B shl 10 or B shr 22;

  Inc(D, Buffer[15] + $6D703EF3 + ((E or not A) xor B)); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 5] + $6D703EF3 + ((D or not E) xor A)); C := C shl  7 or C shr 25 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 1] + $6D703EF3 + ((C or not D) xor E)); B := B shl 15 or B shr 17 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 3] + $6D703EF3 + ((B or not C) xor D)); A := A shl 11 or A shr 21 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 7] + $6D703EF3 + ((A or not B) xor C)); E := E shl  8 or E shr 24 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[14] + $6D703EF3 + ((E or not A) xor B)); D := D shl  6 or D shr 26 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 6] + $6D703EF3 + ((D or not E) xor A)); C := C shl  6 or C shr 26 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 9] + $6D703EF3 + ((C or not D) xor E)); B := B shl 14 or B shr 18 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[11] + $6D703EF3 + ((B or not C) xor D)); A := A shl 12 or A shr 20 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 8] + $6D703EF3 + ((A or not B) xor C)); E := E shl 13 or E shr 19 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[12] + $6D703EF3 + ((E or not A) xor B)); D := D shl  5 or D shr 27 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 2] + $6D703EF3 + ((D or not E) xor A)); C := C shl 14 or C shr 18 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[10] + $6D703EF3 + ((C or not D) xor E)); B := B shl 13 or B shr 19 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 0] + $6D703EF3 + ((B or not C) xor D)); A := A shl 13 or A shr 19 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 4] + $6D703EF3 + ((A or not B) xor C)); E := E shl  7 or E shr 25 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[13] + $6D703EF3 + ((E or not A) xor B)); D := D shl  5 or D shr 27 + C; A := A shl 10 or A shr 22;

  Inc(C, Buffer[ 8] + $7A6D76E9 + ((D and E) or (not D and A))); C := C shl 15 or C shr 17 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 6] + $7A6D76E9 + ((C and D) or (not C and E))); B := B shl  5 or B shr 27 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 4] + $7A6D76E9 + ((B and C) or (not B and D))); A := A shl  8 or A shr 24 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 1] + $7A6D76E9 + ((A and B) or (not A and C))); E := E shl 11 or E shr 21 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 3] + $7A6D76E9 + ((E and A) or (not E and B))); D := D shl 14 or D shr 18 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[11] + $7A6D76E9 + ((D and E) or (not D and A))); C := C shl 14 or C shr 18 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[15] + $7A6D76E9 + ((C and D) or (not C and E))); B := B shl  6 or B shr 26 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 0] + $7A6D76E9 + ((B and C) or (not B and D))); A := A shl 14 or A shr 18 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 5] + $7A6D76E9 + ((A and B) or (not A and C))); E := E shl  6 or E shr 26 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[12] + $7A6D76E9 + ((E and A) or (not E and B))); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 2] + $7A6D76E9 + ((D and E) or (not D and A))); C := C shl 12 or C shr 20 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[13] + $7A6D76E9 + ((C and D) or (not C and E))); B := B shl  9 or B shr 23 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 9] + $7A6D76E9 + ((B and C) or (not B and D))); A := A shl 12 or A shr 20 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 7] + $7A6D76E9 + ((A and B) or (not A and C))); E := E shl  5 or E shr 27 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[10] + $7A6D76E9 + ((E and A) or (not E and B))); D := D shl 15 or D shr 17 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[14] + $7A6D76E9 + ((D and E) or (not D and A))); C := C shl  8 or C shr 24 + B; E := E shl 10 or E shr 22;

  Inc(B, Buffer[12] + (C xor D xor E)); B := B shl  8 or B shr 24 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[15] + (B xor C xor D)); A := A shl  5 or A shr 27 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[10] + (A xor B xor C)); E := E shl 12 or E shr 20 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 4] + (E xor A xor B)); D := D shl  9 or D shr 23 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 1] + (D xor E xor A)); C := C shl 12 or C shr 20 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[ 5] + (C xor D xor E)); B := B shl  5 or B shr 27 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[ 8] + (B xor C xor D)); A := A shl 14 or A shr 18 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 7] + (A xor B xor C)); E := E shl  6 or E shr 26 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 6] + (E xor A xor B)); D := D shl  8 or D shr 24 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 2] + (D xor E xor A)); C := C shl 13 or C shr 19 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[13] + (C xor D xor E)); B := B shl  6 or B shr 26 + A; D := D shl 10 or D shr 22;
  Inc(A, Buffer[14] + (B xor C xor D)); A := A shl  5 or A shr 27 + E; C := C shl 10 or C shr 22;
  Inc(E, Buffer[ 0] + (A xor B xor C)); E := E shl 15 or E shr 17 + D; B := B shl 10 or B shr 22;
  Inc(D, Buffer[ 3] + (E xor A xor B)); D := D shl 13 or D shr 19 + C; A := A shl 10 or A shr 22;
  Inc(C, Buffer[ 9] + (D xor E xor A)); C := C shl 11 or C shr 21 + B; E := E shl 10 or E shr 22;
  Inc(B, Buffer[11] + (C xor D xor E)); B := B shl 11 or B shr 21 + A; D := D shl 10 or D shr 22;

  Inc(D, C1 + FDigest[1]);
  FDigest[1] := FDigest[2] + D1 + E;
  FDigest[2] := FDigest[3] + E1 + A;
  FDigest[3] := FDigest[4] + A1 + B;
  FDigest[4] := FDigest[0] + B1 + C;
  FDigest[0] := D;
end;

class function THash_RipeMD160.DigestKeySize: Integer;
begin
  Result := 20;
end;

class function THash_RipeMD256.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0C3h,0B1h,0D7h,0ACh,0A8h,09Ah,047h,07Ah
         DB    038h,0D3h,06Dh,039h,0EFh,000h,0FBh,045h
         DB    0FCh,04Eh,0C3h,01Ah,071h,021h,0DBh,09Eh
         DB    01Ch,076h,0C5h,0DEh,099h,088h,018h,0C2h
end;

procedure THash_RipeMD256.Transform(Buffer: PIntArray);
var
  A1, B1, C1, D1: LongWord;
  A2, B2, C2, D2: LongWord;
  T: LongWord;
begin
  A1 := FDigest[0];
  B1 := FDigest[1];
  C1 := FDigest[2];
  D1 := FDigest[3];
  A2 := FDigest[4];
  B2 := FDigest[5];
  C2 := FDigest[6];
  D2 := FDigest[7];

  Inc(A1, B1 xor C1 xor D1 + Buffer[ 0]); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 1]); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 2]); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 3]); B1 := B1 shl 12 or B1 shr 20;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 4]); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 5]); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 6]); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 7]); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 8]); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 9]); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 xor A1 xor B1 + Buffer[10]); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 xor D1 xor A1 + Buffer[11]); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 xor C1 xor D1 + Buffer[12]); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 xor B1 xor C1 + Buffer[13]); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 xor A1 xor B1 + Buffer[14]); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 xor D1 xor A1 + Buffer[15]); B1 := B1 shl  8 or B1 shr 24;

  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 5] + $50A28BE6); A2 := A2 shl  8 or A2 shr 24;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[14] + $50A28BE6); D2 := D2 shl  9 or D2 shr 23;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[ 7] + $50A28BE6); C2 := C2 shl  9 or C2 shr 23;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 0] + $50A28BE6); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 9] + $50A28BE6); A2 := A2 shl 13 or A2 shr 19;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[ 2] + $50A28BE6); D2 := D2 shl 15 or D2 shr 17;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[11] + $50A28BE6); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 4] + $50A28BE6); B2 := B2 shl  5 or B2 shr 27;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[13] + $50A28BE6); A2 := A2 shl  7 or A2 shr 25;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[ 6] + $50A28BE6); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[15] + $50A28BE6); C2 := C2 shl  8 or C2 shr 24;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 8] + $50A28BE6); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 1] + $50A28BE6); A2 := A2 shl 14 or A2 shr 18;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[10] + $50A28BE6); D2 := D2 shl 14 or D2 shr 18;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[ 3] + $50A28BE6); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[12] + $50A28BE6); B2 := B2 shl  6 or B2 shr 26;

  T := A1; A1 := A2; A2 := T;

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + $5A827999); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 4] + $5A827999); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[13] + $5A827999); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 1] + $5A827999); B1 := B1 shl 13 or B1 shr 19;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + $5A827999); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 6] + $5A827999); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[15] + $5A827999); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + $5A827999); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[12] + $5A827999); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + $5A827999); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 9] + $5A827999); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 5] + $5A827999); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 2] + $5A827999); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + $5A827999); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[11] + $5A827999); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 8] + $5A827999); B1 := B1 shl 12 or B1 shr 20;

  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 6] + $5C4DD124); A2 := A2 shl  9 or A2 shr 23;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[11] + $5C4DD124); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 3] + $5C4DD124); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[ 7] + $5C4DD124); B2 := B2 shl  7 or B2 shr 25;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 0] + $5C4DD124); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[13] + $5C4DD124); D2 := D2 shl  8 or D2 shr 24;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 5] + $5C4DD124); C2 := C2 shl  9 or C2 shr 23;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[10] + $5C4DD124); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[14] + $5C4DD124); A2 := A2 shl  7 or A2 shr 25;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[15] + $5C4DD124); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 8] + $5C4DD124); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[12] + $5C4DD124); B2 := B2 shl  7 or B2 shr 25;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 4] + $5C4DD124); A2 := A2 shl  6 or A2 shr 26;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[ 9] + $5C4DD124); D2 := D2 shl 15 or D2 shr 17;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 1] + $5C4DD124); C2 := C2 shl 13 or C2 shr 19;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[ 2] + $5C4DD124); B2 := B2 shl 11 or B2 shr 21;

  T := B1; B1 := B2; B2 := T;

  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 3] + $6ED9EBA1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[10] + $6ED9EBA1); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[14] + $6ED9EBA1); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 4] + $6ED9EBA1); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 9] + $6ED9EBA1); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[15] + $6ED9EBA1); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 8] + $6ED9EBA1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 1] + $6ED9EBA1); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 2] + $6ED9EBA1); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[ 7] + $6ED9EBA1); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 0] + $6ED9EBA1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 6] + $6ED9EBA1); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[13] + $6ED9EBA1); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[11] + $6ED9EBA1); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 5] + $6ED9EBA1); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[12] + $6ED9EBA1); B1 := B1 shl  5 or B1 shr 27;

  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[15] + $6D703EF3); A2 := A2 shl  9 or A2 shr 23;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 5] + $6D703EF3); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 1] + $6D703EF3); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 3] + $6D703EF3); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[ 7] + $6D703EF3); A2 := A2 shl  8 or A2 shr 24;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[14] + $6D703EF3); D2 := D2 shl  6 or D2 shr 26;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 6] + $6D703EF3); C2 := C2 shl  6 or C2 shr 26;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 9] + $6D703EF3); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[11] + $6D703EF3); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 8] + $6D703EF3); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[12] + $6D703EF3); C2 := C2 shl  5 or C2 shr 27;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 2] + $6D703EF3); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[10] + $6D703EF3); A2 := A2 shl 13 or A2 shr 19;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 0] + $6D703EF3); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 4] + $6D703EF3); C2 := C2 shl  7 or C2 shr 25;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[13] + $6D703EF3); B2 := B2 shl  5 or B2 shr 27;

  T := C1; C1 := C2; C2 := T;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + $8F1BBCDC); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 9] + $8F1BBCDC); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + $8F1BBCDC); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[10] + $8F1BBCDC); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 0] + $8F1BBCDC); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 8] + $8F1BBCDC); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[12] + $8F1BBCDC); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + $8F1BBCDC); B1 := B1 shl  8 or B1 shr 24;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + $8F1BBCDC); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 3] + $8F1BBCDC); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + $8F1BBCDC); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[15] + $8F1BBCDC); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[14] + $8F1BBCDC); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 5] + $8F1BBCDC); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 6] + $8F1BBCDC); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 2] + $8F1BBCDC); B1 := B1 shl 12 or B1 shr 20;

  Inc(A2, B2 xor C2 xor D2 + Buffer[ 8]); A2 := A2 shl 15 or A2 shr 17;
  Inc(D2, A2 xor B2 xor C2 + Buffer[ 6]); D2 := D2 shl  5 or D2 shr 27;
  Inc(C2, D2 xor A2 xor B2 + Buffer[ 4]); C2 := C2 shl  8 or C2 shr 24;
  Inc(B2, C2 xor D2 xor A2 + Buffer[ 1]); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 3]); A2 := A2 shl 14 or A2 shr 18;
  Inc(D2, A2 xor B2 xor C2 + Buffer[11]); D2 := D2 shl 14 or D2 shr 18;
  Inc(C2, D2 xor A2 xor B2 + Buffer[15]); C2 := C2 shl  6 or C2 shr 26;
  Inc(B2, C2 xor D2 xor A2 + Buffer[ 0]); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 5]); A2 := A2 shl  6 or A2 shr 26;
  Inc(D2, A2 xor B2 xor C2 + Buffer[12]); D2 := D2 shl  9 or D2 shr 23;
  Inc(C2, D2 xor A2 xor B2 + Buffer[ 2]); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, C2 xor D2 xor A2 + Buffer[13]); B2 := B2 shl  9 or B2 shr 23;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 9]); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, A2 xor B2 xor C2 + Buffer[ 7]); D2 := D2 shl  5 or D2 shr 27;
  Inc(C2, D2 xor A2 xor B2 + Buffer[10]); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 xor D2 xor A2 + Buffer[14]); B2 := B2 shl  8 or B2 shr 24;

  T := D1; D1 := D2; D2 := T;

  Inc(FDigest[0], A1);
  Inc(FDigest[1], B1);
  Inc(FDigest[2], C1);
  Inc(FDigest[3], D1);
  Inc(FDigest[4], A2);
  Inc(FDigest[5], B2);
  Inc(FDigest[6], C2);
  Inc(FDigest[7], D2);
end;

class function THash_RipeMD256.DigestKeySize: Integer;
begin
  Result := 32;
end;

procedure THash_RipeMD256.Init;
begin
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FDigest[4] := $76543210;
  FDigest[5] := $FEDCBA98;
  FDigest[6] := $89ABCDEF;
  FDigest[7] := $01234567;
  FDigest[8] := $01234567;
  FDigest[9] := $3C2D1E0F;
  FCount := 0;
  Protect(True);
end;

class function THash_RipeMD320.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0B7h,0BDh,02Ch,075h,0B7h,013h,050h,091h
         DB    0E4h,067h,009h,046h,0F1h,041h,05Ah,048h
         DB    045h,0DFh,08Eh,007h,0BAh,067h,04Eh,0A9h
         DB    0FDh,066h,0EDh,001h,0D9h,06Fh,023h,020h
         DB    0B5h,011h,012h,0C5h,0A7h,041h,0A6h,05Ch
end;

procedure THash_RipeMD320.Transform(Buffer: PIntArray);
var
  A1, B1, C1, D1, E1: LongWord;
  A2, B2, C2, D2, E2: LongWord;
  T: LongWord;
begin
  A1 := FDigest[0];
  B1 := FDigest[1];
  C1 := FDigest[2];
  D1 := FDigest[3];
  E1 := FDigest[4];
  A2 := FDigest[5];
  B2 := FDigest[6];
  C2 := FDigest[7];
  D2 := FDigest[8];
  E2 := FDigest[9];

  Inc(A1, Buffer[ 0] + (B1 xor C1 xor D1)); A1 := A1 shl 11 or A1 shr 21 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 1] + (A1 xor B1 xor C1)); E1 := E1 shl 14 or E1 shr 18 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 2] + (E1 xor A1 xor B1)); D1 := D1 shl 15 or D1 shr 17 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 3] + (D1 xor E1 xor A1)); C1 := C1 shl 12 or C1 shr 20 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[ 4] + (C1 xor D1 xor E1)); B1 := B1 shl  5 or B1 shr 27 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 5] + (B1 xor C1 xor D1)); A1 := A1 shl  8 or A1 shr 24 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 6] + (A1 xor B1 xor C1)); E1 := E1 shl  7 or E1 shr 25 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 7] + (E1 xor A1 xor B1)); D1 := D1 shl  9 or D1 shr 23 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 8] + (D1 xor E1 xor A1)); C1 := C1 shl 11 or C1 shr 21 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[ 9] + (C1 xor D1 xor E1)); B1 := B1 shl 13 or B1 shr 19 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[10] + (B1 xor C1 xor D1)); A1 := A1 shl 14 or A1 shr 18 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[11] + (A1 xor B1 xor C1)); E1 := E1 shl 15 or E1 shr 17 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[12] + (E1 xor A1 xor B1)); D1 := D1 shl  6 or D1 shr 26 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[13] + (D1 xor E1 xor A1)); C1 := C1 shl  7 or C1 shr 25 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[14] + (C1 xor D1 xor E1)); B1 := B1 shl  9 or B1 shr 23 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[15] + (B1 xor C1 xor D1)); A1 := A1 shl  8 or A1 shr 24 + E1; C1 := C1 shl 10 or C1 shr 22;

  Inc(A2, Buffer[ 5] + $50A28BE6 + (B2 xor (C2 or not D2))); A2 := A2 shl  8 or A2 shr 24 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[14] + $50A28BE6 + (A2 xor (B2 or not C2))); E2 := E2 shl  9 or E2 shr 23 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 7] + $50A28BE6 + (E2 xor (A2 or not B2))); D2 := D2 shl  9 or D2 shr 23 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 0] + $50A28BE6 + (D2 xor (E2 or not A2))); C2 := C2 shl 11 or C2 shr 21 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 9] + $50A28BE6 + (C2 xor (D2 or not E2))); B2 := B2 shl 13 or B2 shr 19 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 2] + $50A28BE6 + (B2 xor (C2 or not D2))); A2 := A2 shl 15 or A2 shr 17 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[11] + $50A28BE6 + (A2 xor (B2 or not C2))); E2 := E2 shl 15 or E2 shr 17 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 4] + $50A28BE6 + (E2 xor (A2 or not B2))); D2 := D2 shl  5 or D2 shr 27 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[13] + $50A28BE6 + (D2 xor (E2 or not A2))); C2 := C2 shl  7 or C2 shr 25 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 6] + $50A28BE6 + (C2 xor (D2 or not E2))); B2 := B2 shl  7 or B2 shr 25 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[15] + $50A28BE6 + (B2 xor (C2 or not D2))); A2 := A2 shl  8 or A2 shr 24 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 8] + $50A28BE6 + (A2 xor (B2 or not C2))); E2 := E2 shl 11 or E2 shr 21 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 1] + $50A28BE6 + (E2 xor (A2 or not B2))); D2 := D2 shl 14 or D2 shr 18 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[10] + $50A28BE6 + (D2 xor (E2 or not A2))); C2 := C2 shl 14 or C2 shr 18 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 3] + $50A28BE6 + (C2 xor (D2 or not E2))); B2 := B2 shl 12 or B2 shr 20 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[12] + $50A28BE6 + (B2 xor (C2 or not D2))); A2 := A2 shl  6 or A2 shr 26 + E2; C2 := C2 shl 10 or C2 shr 22;

  T := A1; A1 := A2; A2 := T;

  Inc(E1, Buffer[ 7] + $5A827999 + ((A1 and B1) or (not A1 and C1))); E1 := E1 shl  7 or E1 shr 25 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 4] + $5A827999 + ((E1 and A1) or (not E1 and B1))); D1 := D1 shl  6 or D1 shr 26 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[13] + $5A827999 + ((D1 and E1) or (not D1 and A1))); C1 := C1 shl  8 or C1 shr 24 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[ 1] + $5A827999 + ((C1 and D1) or (not C1 and E1))); B1 := B1 shl 13 or B1 shr 19 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[10] + $5A827999 + ((B1 and C1) or (not B1 and D1))); A1 := A1 shl 11 or A1 shr 21 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 6] + $5A827999 + ((A1 and B1) or (not A1 and C1))); E1 := E1 shl  9 or E1 shr 23 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[15] + $5A827999 + ((E1 and A1) or (not E1 and B1))); D1 := D1 shl  7 or D1 shr 25 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 3] + $5A827999 + ((D1 and E1) or (not D1 and A1))); C1 := C1 shl 15 or C1 shr 17 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[12] + $5A827999 + ((C1 and D1) or (not C1 and E1))); B1 := B1 shl  7 or B1 shr 25 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 0] + $5A827999 + ((B1 and C1) or (not B1 and D1))); A1 := A1 shl 12 or A1 shr 20 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 9] + $5A827999 + ((A1 and B1) or (not A1 and C1))); E1 := E1 shl 15 or E1 shr 17 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 5] + $5A827999 + ((E1 and A1) or (not E1 and B1))); D1 := D1 shl  9 or D1 shr 23 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 2] + $5A827999 + ((D1 and E1) or (not D1 and A1))); C1 := C1 shl 11 or C1 shr 21 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[14] + $5A827999 + ((C1 and D1) or (not C1 and E1))); B1 := B1 shl  7 or B1 shr 25 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[11] + $5A827999 + ((B1 and C1) or (not B1 and D1))); A1 := A1 shl 13 or A1 shr 19 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 8] + $5A827999 + ((A1 and B1) or (not A1 and C1))); E1 := E1 shl 12 or E1 shr 20 + D1; B1 := B1 shl 10 or B1 shr 22;

  Inc(E2, Buffer[ 6] + $5C4DD124 + ((A2 and C2) or (B2 and not C2))); E2 := E2 shl  9 or E2 shr 23 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[11] + $5C4DD124 + ((E2 and B2) or (A2 and not B2))); D2 := D2 shl 13 or D2 shr 19 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 3] + $5C4DD124 + ((D2 and A2) or (E2 and not A2))); C2 := C2 shl 15 or C2 shr 17 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 7] + $5C4DD124 + ((C2 and E2) or (D2 and not E2))); B2 := B2 shl  7 or B2 shr 25 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 0] + $5C4DD124 + ((B2 and D2) or (C2 and not D2))); A2 := A2 shl 12 or A2 shr 20 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[13] + $5C4DD124 + ((A2 and C2) or (B2 and not C2))); E2 := E2 shl  8 or E2 shr 24 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 5] + $5C4DD124 + ((E2 and B2) or (A2 and not B2))); D2 := D2 shl  9 or D2 shr 23 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[10] + $5C4DD124 + ((D2 and A2) or (E2 and not A2))); C2 := C2 shl 11 or C2 shr 21 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[14] + $5C4DD124 + ((C2 and E2) or (D2 and not E2))); B2 := B2 shl  7 or B2 shr 25 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[15] + $5C4DD124 + ((B2 and D2) or (C2 and not D2))); A2 := A2 shl  7 or A2 shr 25 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 8] + $5C4DD124 + ((A2 and C2) or (B2 and not C2))); E2 := E2 shl 12 or E2 shr 20 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[12] + $5C4DD124 + ((E2 and B2) or (A2 and not B2))); D2 := D2 shl  7 or D2 shr 25 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 4] + $5C4DD124 + ((D2 and A2) or (E2 and not A2))); C2 := C2 shl  6 or C2 shr 26 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 9] + $5C4DD124 + ((C2 and E2) or (D2 and not E2))); B2 := B2 shl 15 or B2 shr 17 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 1] + $5C4DD124 + ((B2 and D2) or (C2 and not D2))); A2 := A2 shl 13 or A2 shr 19 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 2] + $5C4DD124 + ((A2 and C2) or (B2 and not C2))); E2 := E2 shl 11 or E2 shr 21 + D2; B2 := B2 shl 10 or B2 shr 22;

  T := B1; B1 := B2; B2 := T;

  Inc(D1, Buffer[ 3] + $6ED9EBA1 + ((E1 or not A1) xor B1)); D1 := D1 shl 11 or D1 shr 21 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[10] + $6ED9EBA1 + ((D1 or not E1) xor A1)); C1 := C1 shl 13 or C1 shr 19 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[14] + $6ED9EBA1 + ((C1 or not D1) xor E1)); B1 := B1 shl  6 or B1 shr 26 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 4] + $6ED9EBA1 + ((B1 or not C1) xor D1)); A1 := A1 shl  7 or A1 shr 25 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 9] + $6ED9EBA1 + ((A1 or not B1) xor C1)); E1 := E1 shl 14 or E1 shr 18 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[15] + $6ED9EBA1 + ((E1 or not A1) xor B1)); D1 := D1 shl  9 or D1 shr 23 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 8] + $6ED9EBA1 + ((D1 or not E1) xor A1)); C1 := C1 shl 13 or C1 shr 19 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[ 1] + $6ED9EBA1 + ((C1 or not D1) xor E1)); B1 := B1 shl 15 or B1 shr 17 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 2] + $6ED9EBA1 + ((B1 or not C1) xor D1)); A1 := A1 shl 14 or A1 shr 18 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 7] + $6ED9EBA1 + ((A1 or not B1) xor C1)); E1 := E1 shl  8 or E1 shr 24 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 0] + $6ED9EBA1 + ((E1 or not A1) xor B1)); D1 := D1 shl 13 or D1 shr 19 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 6] + $6ED9EBA1 + ((D1 or not E1) xor A1)); C1 := C1 shl  6 or C1 shr 26 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[13] + $6ED9EBA1 + ((C1 or not D1) xor E1)); B1 := B1 shl  5 or B1 shr 27 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[11] + $6ED9EBA1 + ((B1 or not C1) xor D1)); A1 := A1 shl 12 or A1 shr 20 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 5] + $6ED9EBA1 + ((A1 or not B1) xor C1)); E1 := E1 shl  7 or E1 shr 25 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[12] + $6ED9EBA1 + ((E1 or not A1) xor B1)); D1 := D1 shl  5 or D1 shr 27 + C1; A1 := A1 shl 10 or A1 shr 22;

  Inc(D2, Buffer[15] + $6D703EF3 + ((E2 or not A2) xor B2)); D2 := D2 shl  9 or D2 shr 23 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 5] + $6D703EF3 + ((D2 or not E2) xor A2)); C2 := C2 shl  7 or C2 shr 25 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 1] + $6D703EF3 + ((C2 or not D2) xor E2)); B2 := B2 shl 15 or B2 shr 17 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 3] + $6D703EF3 + ((B2 or not C2) xor D2)); A2 := A2 shl 11 or A2 shr 21 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 7] + $6D703EF3 + ((A2 or not B2) xor C2)); E2 := E2 shl  8 or E2 shr 24 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[14] + $6D703EF3 + ((E2 or not A2) xor B2)); D2 := D2 shl  6 or D2 shr 26 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 6] + $6D703EF3 + ((D2 or not E2) xor A2)); C2 := C2 shl  6 or C2 shr 26 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 9] + $6D703EF3 + ((C2 or not D2) xor E2)); B2 := B2 shl 14 or B2 shr 18 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[11] + $6D703EF3 + ((B2 or not C2) xor D2)); A2 := A2 shl 12 or A2 shr 20 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 8] + $6D703EF3 + ((A2 or not B2) xor C2)); E2 := E2 shl 13 or E2 shr 19 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[12] + $6D703EF3 + ((E2 or not A2) xor B2)); D2 := D2 shl  5 or D2 shr 27 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 2] + $6D703EF3 + ((D2 or not E2) xor A2)); C2 := C2 shl 14 or C2 shr 18 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[10] + $6D703EF3 + ((C2 or not D2) xor E2)); B2 := B2 shl 13 or B2 shr 19 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 0] + $6D703EF3 + ((B2 or not C2) xor D2)); A2 := A2 shl 13 or A2 shr 19 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 4] + $6D703EF3 + ((A2 or not B2) xor C2)); E2 := E2 shl  7 or E2 shr 25 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[13] + $6D703EF3 + ((E2 or not A2) xor B2)); D2 := D2 shl  5 or D2 shr 27 + C2; A2 := A2 shl 10 or A2 shr 22;

  T := C1; C1 := C2; C2 := T;

  Inc(C1, Buffer[ 1] + $8F1BBCDC + ((D1 and A1) or (E1 and not A1))); C1 := C1 shl 11 or C1 shr 21 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[ 9] + $8F1BBCDC + ((C1 and E1) or (D1 and not E1))); B1 := B1 shl 12 or B1 shr 20 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[11] + $8F1BBCDC + ((B1 and D1) or (C1 and not D1))); A1 := A1 shl 14 or A1 shr 18 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[10] + $8F1BBCDC + ((A1 and C1) or (B1 and not C1))); E1 := E1 shl 15 or E1 shr 17 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 0] + $8F1BBCDC + ((E1 and B1) or (A1 and not B1))); D1 := D1 shl 14 or D1 shr 18 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 8] + $8F1BBCDC + ((D1 and A1) or (E1 and not A1))); C1 := C1 shl 15 or C1 shr 17 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[12] + $8F1BBCDC + ((C1 and E1) or (D1 and not E1))); B1 := B1 shl  9 or B1 shr 23 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 4] + $8F1BBCDC + ((B1 and D1) or (C1 and not D1))); A1 := A1 shl  8 or A1 shr 24 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[13] + $8F1BBCDC + ((A1 and C1) or (B1 and not C1))); E1 := E1 shl  9 or E1 shr 23 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 3] + $8F1BBCDC + ((E1 and B1) or (A1 and not B1))); D1 := D1 shl 14 or D1 shr 18 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 7] + $8F1BBCDC + ((D1 and A1) or (E1 and not A1))); C1 := C1 shl  5 or C1 shr 27 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[15] + $8F1BBCDC + ((C1 and E1) or (D1 and not E1))); B1 := B1 shl  6 or B1 shr 26 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[14] + $8F1BBCDC + ((B1 and D1) or (C1 and not D1))); A1 := A1 shl  8 or A1 shr 24 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 5] + $8F1BBCDC + ((A1 and C1) or (B1 and not C1))); E1 := E1 shl  6 or E1 shr 26 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 6] + $8F1BBCDC + ((E1 and B1) or (A1 and not B1))); D1 := D1 shl  5 or D1 shr 27 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 2] + $8F1BBCDC + ((D1 and A1) or (E1 and not A1))); C1 := C1 shl 12 or C1 shr 20 + B1; E1 := E1 shl 10 or E1 shr 22;

  Inc(C2, Buffer[ 8] + $7A6D76E9 + ((D2 and E2) or (not D2 and A2))); C2 := C2 shl 15 or C2 shr 17 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 6] + $7A6D76E9 + ((C2 and D2) or (not C2 and E2))); B2 := B2 shl  5 or B2 shr 27 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 4] + $7A6D76E9 + ((B2 and C2) or (not B2 and D2))); A2 := A2 shl  8 or A2 shr 24 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 1] + $7A6D76E9 + ((A2 and B2) or (not A2 and C2))); E2 := E2 shl 11 or E2 shr 21 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 3] + $7A6D76E9 + ((E2 and A2) or (not E2 and B2))); D2 := D2 shl 14 or D2 shr 18 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[11] + $7A6D76E9 + ((D2 and E2) or (not D2 and A2))); C2 := C2 shl 14 or C2 shr 18 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[15] + $7A6D76E9 + ((C2 and D2) or (not C2 and E2))); B2 := B2 shl  6 or B2 shr 26 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 0] + $7A6D76E9 + ((B2 and C2) or (not B2 and D2))); A2 := A2 shl 14 or A2 shr 18 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 5] + $7A6D76E9 + ((A2 and B2) or (not A2 and C2))); E2 := E2 shl  6 or E2 shr 26 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[12] + $7A6D76E9 + ((E2 and A2) or (not E2 and B2))); D2 := D2 shl  9 or D2 shr 23 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 2] + $7A6D76E9 + ((D2 and E2) or (not D2 and A2))); C2 := C2 shl 12 or C2 shr 20 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[13] + $7A6D76E9 + ((C2 and D2) or (not C2 and E2))); B2 := B2 shl  9 or B2 shr 23 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 9] + $7A6D76E9 + ((B2 and C2) or (not B2 and D2))); A2 := A2 shl 12 or A2 shr 20 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 7] + $7A6D76E9 + ((A2 and B2) or (not A2 and C2))); E2 := E2 shl  5 or E2 shr 27 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[10] + $7A6D76E9 + ((E2 and A2) or (not E2 and B2))); D2 := D2 shl 15 or D2 shr 17 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[14] + $7A6D76E9 + ((D2 and E2) or (not D2 and A2))); C2 := C2 shl  8 or C2 shr 24 + B2; E2 := E2 shl 10 or E2 shr 22;

  T := D1; D1 := D2; D2 := T;

  Inc(B1, Buffer[ 4] + $A953FD4E + (C1 xor (D1 or not E1))); B1 := B1 shl  9 or B1 shr 23 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 0] + $A953FD4E + (B1 xor (C1 or not D1))); A1 := A1 shl 15 or A1 shr 17 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[ 5] + $A953FD4E + (A1 xor (B1 or not C1))); E1 := E1 shl  5 or E1 shr 27 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 9] + $A953FD4E + (E1 xor (A1 or not B1))); D1 := D1 shl 11 or D1 shr 21 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 7] + $A953FD4E + (D1 xor (E1 or not A1))); C1 := C1 shl  6 or C1 shr 26 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[12] + $A953FD4E + (C1 xor (D1 or not E1))); B1 := B1 shl  8 or B1 shr 24 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 2] + $A953FD4E + (B1 xor (C1 or not D1))); A1 := A1 shl 13 or A1 shr 19 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[10] + $A953FD4E + (A1 xor (B1 or not C1))); E1 := E1 shl 12 or E1 shr 20 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[14] + $A953FD4E + (E1 xor (A1 or not B1))); D1 := D1 shl  5 or D1 shr 27 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[ 1] + $A953FD4E + (D1 xor (E1 or not A1))); C1 := C1 shl 12 or C1 shr 20 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[ 3] + $A953FD4E + (C1 xor (D1 or not E1))); B1 := B1 shl 13 or B1 shr 19 + A1; D1 := D1 shl 10 or D1 shr 22;
  Inc(A1, Buffer[ 8] + $A953FD4E + (B1 xor (C1 or not D1))); A1 := A1 shl 14 or A1 shr 18 + E1; C1 := C1 shl 10 or C1 shr 22;
  Inc(E1, Buffer[11] + $A953FD4E + (A1 xor (B1 or not C1))); E1 := E1 shl 11 or E1 shr 21 + D1; B1 := B1 shl 10 or B1 shr 22;
  Inc(D1, Buffer[ 6] + $A953FD4E + (E1 xor (A1 or not B1))); D1 := D1 shl  8 or D1 shr 24 + C1; A1 := A1 shl 10 or A1 shr 22;
  Inc(C1, Buffer[15] + $A953FD4E + (D1 xor (E1 or not A1))); C1 := C1 shl  5 or C1 shr 27 + B1; E1 := E1 shl 10 or E1 shr 22;
  Inc(B1, Buffer[13] + $A953FD4E + (C1 xor (D1 or not E1))); B1 := B1 shl  6 or B1 shr 26 + A1; D1 := D1 shl 10 or D1 shr 22;

  Inc(B2, Buffer[12] + (C2 xor D2 xor E2)); B2 := B2 shl  8 or B2 shr 24 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[15] + (B2 xor C2 xor D2)); A2 := A2 shl  5 or A2 shr 27 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[10] + (A2 xor B2 xor C2)); E2 := E2 shl 12 or E2 shr 20 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 4] + (E2 xor A2 xor B2)); D2 := D2 shl  9 or D2 shr 23 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 1] + (D2 xor E2 xor A2)); C2 := C2 shl 12 or C2 shr 20 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[ 5] + (C2 xor D2 xor E2)); B2 := B2 shl  5 or B2 shr 27 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[ 8] + (B2 xor C2 xor D2)); A2 := A2 shl 14 or A2 shr 18 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 7] + (A2 xor B2 xor C2)); E2 := E2 shl  6 or E2 shr 26 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 6] + (E2 xor A2 xor B2)); D2 := D2 shl  8 or D2 shr 24 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 2] + (D2 xor E2 xor A2)); C2 := C2 shl 13 or C2 shr 19 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[13] + (C2 xor D2 xor E2)); B2 := B2 shl  6 or B2 shr 26 + A2; D2 := D2 shl 10 or D2 shr 22;
  Inc(A2, Buffer[14] + (B2 xor C2 xor D2)); A2 := A2 shl  5 or A2 shr 27 + E2; C2 := C2 shl 10 or C2 shr 22;
  Inc(E2, Buffer[ 0] + (A2 xor B2 xor C2)); E2 := E2 shl 15 or E2 shr 17 + D2; B2 := B2 shl 10 or B2 shr 22;
  Inc(D2, Buffer[ 3] + (E2 xor A2 xor B2)); D2 := D2 shl 13 or D2 shr 19 + C2; A2 := A2 shl 10 or A2 shr 22;
  Inc(C2, Buffer[ 9] + (D2 xor E2 xor A2)); C2 := C2 shl 11 or C2 shr 21 + B2; E2 := E2 shl 10 or E2 shr 22;
  Inc(B2, Buffer[11] + (C2 xor D2 xor E2)); B2 := B2 shl 11 or B2 shr 21 + A2; D2 := D2 shl 10 or D2 shr 22;

  T := E1; E1 := E2; E2 := T;

  Inc(FDigest[0], A1);
  Inc(FDigest[1], B1);
  Inc(FDigest[2], C1);
  Inc(FDigest[3], D1);
  Inc(FDigest[4], E1);
  Inc(FDigest[5], A2);
  Inc(FDigest[6], B2);
  Inc(FDigest[7], C2);
  Inc(FDigest[8], D2);
  Inc(FDigest[9], E2);
end;

class function THash_RipeMD320.DigestKeySize: Integer;
begin
  Result := 40;
end;

class function THash_SHA.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0DCh,01Fh,07Dh,07Ch,096h,0DDh,0C7h,0FCh
         DB    04Dh,00Ah,0F2h,0CCh,012h,0E7h,0F7h,066h
         DB    05Bh,0B1h,085h,0ACh
end;

procedure SHABuffer386(S, D: Pointer; Rotate: Boolean); assembler;
asm
     PUSH  EBX
     PUSH  ECX
     MOV   EBX,EAX
     XOR   ECX,ECX
@@1: MOV   EAX,[EDX + ECX * 4]
     XCHG  AL,AH
     ROL   EAX,16
     XCHG  AL,AH
     MOV   [EBX],EAX
     ADD   EBX,4
     INC   ECX
     CMP   ECX,16
     JNZ   @@1
     MOV   ECX,64
     POP   EDX
     CMP   DL,0
     JZ    @@3
@@2: MOV   EAX,[EBX -  3 * 4]
     XOR   EAX,[EBX -  8 * 4]
     XOR   EAX,[EBX - 14 * 4]
     XOR   EAX,[EBX - 16 * 4]
     ROL   EAX,1
     MOV   [EBX],EAX
     ADD   EBX,4
     DEC   ECX
     JNZ   @@2
     JMP   @@4

@@3: MOV   EAX,[EBX -  3 * 4]
     XOR   EAX,[EBX -  8 * 4]
     XOR   EAX,[EBX - 14 * 4]
     XOR   EAX,[EBX - 16 * 4]
     MOV   [EBX],EAX
     ADD   EBX,4
     DEC   ECX
     JNZ   @@3

@@4: POP   EBX
end;

procedure SHABuffer486(S, D: Pointer; Rotate: Boolean); assembler;
asm
     PUSH  EBX
     PUSH  ECX
     MOV   EBX,EAX
     XOR   ECX,ECX
@@1: MOV   EAX,[EDX + ECX * 4]
     BSWAP EAX
     MOV   [EBX],EAX
     ADD   EBX,4
     INC   ECX
     CMP   ECX,16
     JNZ   @@1
     MOV   ECX,64
     POP   EDX
     CMP   DL,0
     JZ    @@3
@@2: MOV   EAX,[EBX -  3 * 4]
     XOR   EAX,[EBX -  8 * 4]
     XOR   EAX,[EBX - 14 * 4]
     XOR   EAX,[EBX - 16 * 4]
     ROL   EAX,1
     MOV   [EBX],EAX
     ADD   EBX,4
     DEC   ECX
     JNZ   @@2
     JMP   @@4

@@3: MOV   EAX,[EBX -  3 * 4]
     XOR   EAX,[EBX -  8 * 4]
     XOR   EAX,[EBX - 14 * 4]
     XOR   EAX,[EBX - 16 * 4]
     MOV   [EBX],EAX
     ADD   EBX,4
     DEC   ECX
     JNZ   @@3

@@4: POP   EBX
end;

const
  SHABuffer: procedure(S, D: Pointer; Rotate: Boolean) = SHABuffer486;

procedure THash_SHA.Transform(Buffer: PIntArray);
var
  A, B, C, D, E: LongWord;
  W: array[0..79] of LongWord;
begin
  SHABuffer(@W, Buffer, FRotate);

  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];
  E := FDigest[4];

  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[ 0] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[ 1] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[ 2] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[ 3] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[ 4] + $5A827999); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[ 5] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[ 6] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[ 7] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[ 8] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[ 9] + $5A827999); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[10] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[11] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[12] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[13] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[14] + $5A827999); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[15] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[16] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[17] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[18] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[19] + $5A827999); C := C shr 2 or C shl 30;

  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[20] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[21] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[22] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[23] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[24] + $6ED9EBA1); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[25] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[26] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[27] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[28] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[29] + $6ED9EBA1); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[30] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[31] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[32] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[33] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[34] + $6ED9EBA1); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[35] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[36] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[37] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[38] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[39] + $6ED9EBA1); C := C shr 2 or C shl 30;

  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[40] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[41] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[42] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[43] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[44] + $8F1BBCDC); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[45] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[46] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[47] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[48] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[49] + $8F1BBCDC); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[50] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[51] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[52] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[53] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[54] + $8F1BBCDC); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[55] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[56] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[57] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[58] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[59] + $8F1BBCDC); C := C shr 2 or C shl 30;

  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[60] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[61] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[62] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[63] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[64] + $CA62C1D6); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[65] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[66] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[67] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[68] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[69] + $CA62C1D6); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[70] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[71] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[72] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[73] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[74] + $CA62C1D6); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[75] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[76] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[77] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[78] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[79] + $CA62C1D6); C := C shr 2 or C shl 30;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
  Inc(FDigest[4], E);
end;

procedure THash_SHA.Done;
var
  I: Integer;
  S: Comp;
begin
  I := FCount mod 64;
  FBuffer[I] := $80;
  Inc(I);
  if I > 64 - 8 then
  begin
    FillChar(FBuffer[I], 64 - I, 0);
    Transform(@FBuffer);
    I := 0;
  end;
  FillChar(FBuffer[I], 64 - I, 0);
  S := FCount * 8;
  for I := 0 to 7 do FBuffer[63 - I] := PByteArray(@S)^[I];
  Transform(@FBuffer);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
{and here the Endian conversion}
  SwapIntegerBuffer(@FDigest, @FDigest, 5);
  Protect(False);
end;

class function THash_SHA1.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    09Ah,001h,02Eh,063h,096h,02Ah,092h,0EBh
         DB    0D8h,02Eh,0F0h,0BCh,01Ch,0A4h,051h,06Ah
         DB    008h,069h,02Eh,068h
end;

procedure THash_SHA1.Init;
begin
  FRotate := True;
  inherited Init;
end;


class function THash_Square.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    080h,08Fh,035h,0EAh,000h,0A7h,077h,033h
         DB    037h,0CEh,055h,098h,026h,0DDh,0B3h,024h
end;

procedure THash_Square.Transform(Buffer: PIntArray);
var
  E: array[0..8, 0..3] of LongWord;
  A,B,C,D: LongWord;
  AA,BB,CC,DD: LongWord;
  I,J: Integer;
  Key: PInteger;
begin
{Build and expand the Key, Digest include the Key}
  Move(FDigest, E, 16);
  for I := 1 to 8 do
  begin
    E[I, 0] := E[I -1, 0] xor ROR(E[I -1, 3], 8) xor 1 shl (I - 1);
    E[I, 1] := E[I -1, 1] xor E[I, 0];
    E[I, 2] := E[I -1, 2] xor E[I, 1];
    E[I, 3] := E[I -1, 3] xor E[I, 2];
    for J := 0 to 3 do
      E[I -1, J] :=     Square_PHI[E[I -1, J]        and $FF]      xor
                    ROL(Square_PHI[E[I -1, J] shr  8 and $FF],  8) xor
                    ROL(Square_PHI[E[I -1, J] shr 16 and $FF], 16) xor
                    ROL(Square_PHI[E[I -1, J] shr 24        ], 24);
  end;
{Encrypt begin here, same TCipher_Square.Encode}
  Key := @E;
  A := Buffer[0] xor Key^; Inc(Key);
  B := Buffer[1] xor Key^; Inc(Key);
  C := Buffer[2] xor Key^; Inc(Key);
  D := Buffer[3] xor Key^; Inc(Key);
  for I := 0 to 6 do
  begin
    AA := Square_TE[0, A        and $FF] xor
          Square_TE[1, B        and $FF] xor
          Square_TE[2, C        and $FF] xor
          Square_TE[3, D        and $FF] xor Key^; Inc(Key);
    BB := Square_TE[0, A shr  8 and $FF] xor
          Square_TE[1, B shr  8 and $FF] xor
          Square_TE[2, C shr  8 and $FF] xor
          Square_TE[3, D shr  8 and $FF] xor Key^; Inc(Key);
    CC := Square_TE[0, A shr 16 and $FF] xor
          Square_TE[1, B shr 16 and $FF] xor
          Square_TE[2, C shr 16 and $FF] xor
          Square_TE[3, D shr 16 and $FF] xor Key^; Inc(Key);
    DD := Square_TE[0, A shr 24        ] xor
          Square_TE[1, B shr 24        ] xor
          Square_TE[2, C shr 24        ] xor
          Square_TE[3, D shr 24        ] xor Key^; Inc(Key);

    A := AA; B := BB; C := CC; D := DD;
  end;

  FDigest[0] := FBuffer[0] xor
                LongWord(Square_SE[A        and $FF])        xor
                LongWord(Square_SE[B        and $FF]) shl  8 xor
                LongWord(Square_SE[C        and $FF]) shl 16 xor
                LongWord(Square_SE[D        and $FF]) shl 24 xor Key^; Inc(Key);
  FDigest[1] := FBuffer[1] xor
                LongWord(Square_SE[A shr  8 and $FF])        xor
                LongWord(Square_SE[B shr  8 and $FF]) shl  8 xor
                LongWord(Square_SE[C shr  8 and $FF]) shl 16 xor
                LongWord(Square_SE[D shr  8 and $FF]) shl 24 xor Key^; Inc(Key);
  FDigest[2] := FBuffer[2] xor
                LongWord(Square_SE[A shr 16 and $FF])        xor
                LongWord(Square_SE[B shr 16 and $FF]) shl  8 xor
                LongWord(Square_SE[C shr 16 and $FF]) shl 16 xor
                LongWord(Square_SE[D shr 16 and $FF]) shl 24 xor Key^; Inc(Key);
  FDigest[3] := FBuffer[3] xor
                LongWord(Square_SE[A shr 24        ])        xor
                LongWord(Square_SE[B shr 24        ]) shl  8 xor
                LongWord(Square_SE[C shr 24        ]) shl 16 xor
                LongWord(Square_SE[D shr 24        ]) shl 24 xor Key^;
end;

class function THash_Square.DigestKeySize: Integer;
begin
  Result := 16;
end;

function THash_Square.DigestKey: Pointer;
begin
  Result := @FDigest;
end;

procedure THash_Square.Init;
begin
  FillChar(FBuffer, SizeOf(FBuffer), 0);
{here using the same Magic codes from MD4, in the original was this set to zero,
 this is the Square Encryption Key,
 you can change this with Move(My4xIntKey, Hash_Square.DigestKey^, 4 * SizeOf(Integer))
 to produce private Results}
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FCount := 0;
  Protect(True);
end;

procedure THash_Square.Done;
var
  I: Integer;
  S: Comp;
begin
  I := FCount and $0F;
  FBuffer[I] := $80;
  Inc(I);
  if I > 16 - 8 then
  begin
    FillChar(FBuffer[I], 16 - I, 0);
    Transform(@FBuffer);
    I := 0;
  end;
  FillChar(FBuffer[I], 16 - I, 0);
  S := FCount * 8; {in Bits}
  Move(S, FBuffer[16 - 8], SizeOf(S));
  Transform(@FBuffer);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  Protect(False);
end;

procedure THash_Square.Calc(const Data; DataSize: Integer);
var
  Index: Integer;
  P: PAnsiChar;
begin
  if DataSize <= 0 then Exit;
  Index := FCount and $0F;
  Inc(FCount, DataSize);
  if Index > 0 then
  begin
    if DataSize < 16 - Index then
    begin
      Move(Data, FBuffer[Index], DataSize);
      Exit;
    end;
    Move(Data, FBuffer[Index], 16 - Index);
    Transform(@FBuffer);
    Index := 16 - Index;
    Dec(DataSize, Index);
  end;
  P := @TByteArray(Data)[Index];
  Inc(Index, DataSize and not $0F);
  while DataSize >= 16 do
  begin
    Transform(Pointer(P));
    Inc(P, 16);
    Dec(DataSize, 16);
  end;
  Move(TByteArray(Data)[Index], FBuffer, DataSize);
end;

class function THash_XOR16.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    079h,0E8h
end;

class function THash_XOR16.DigestKeySize: Integer;
begin
  Result := 2;
end;

procedure THash_XOR16.Init;
begin
  FCRC := 0;
  Protect(True);
end;

procedure THash_XOR16.Calc(const Data; DataSize: Integer); assembler; register;
asm
         TEST    ECX,ECX
         JLE     @Exit
         PUSH    EAX
         MOV     AX,[EAX].THash_XOR16.FCRC
@@1:     ROL     AX,5
         XOR     AL,[EDX]
         INC     EDX
         DEC     ECX
         JNZ     @@1
         POP     EDX
         MOV     [EDX].THash_XOR16.FCRC,AX
@Exit:
end;

function THash_XOR16.DigestKey: Pointer;
begin
  Result := @FCRC;
end;

class function THash_XOR32.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    08Dh,0ADh,089h,07Fh
end;

class function THash_XOR32.DigestKeySize: Integer;
begin
  Result := 4;
end;

procedure THash_XOR32.Init;
begin
  FCRC := 0;
  Protect(True);
end;

procedure THash_XOR32.Calc(const Data; DataSize: Integer); assembler; register;
asm
         TEST    ECX,ECX
         JLE     @Exit
         PUSH    EAX
         MOV     EAX,[EAX].THash_XOR32.FCRC
         TEST    ECX,1
         JE      @@1
         XOR     AX,[EDX]
         INC     EDX
@@1:     SHR     ECX,1
         JECXZ   @@3
@@2:     ROL     EAX,5
         XOR     AX,[EDX]
         ADD     EDX,2
         DEC     ECX
         JNZ     @@2
@@3:     POP     EDX
         MOV     [EDX].THash_XOR32.FCRC,EAX
@Exit:
end;

function THash_XOR32.DigestKey: Pointer;
begin
  Result := @FCRC;
end;

class function THash_CRC32.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    058h,0EEh,01Fh,031h
end;

procedure THash_CRC32.Init;
begin
  FCRC := $FFFFFFFF;
  Protect(True);
end;

procedure THash_CRC32.Calc(const Data; DataSize: Integer); assembler; register;
asm
         PUSH   EAX
         MOV    EAX,[EAX].THash_CRC32.FCRC
         CALL   CRC32
         POP    EDX
         MOV    [EDX].THash_CRC32.FCRC,EAX
end;

procedure THash_CRC32.Done;
begin
  FCRC := not FCRC;
  Protect(False);
end;

class function THash_CRC16_CCITT.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0B0h,0D1h
end;

procedure THash_CRC16_CCITT.Init;
begin
  FCRC := $FFFF;
  Protect(True);
end;

procedure THash_CRC16_CCITT.Calc(const Data; DataSize: Integer);
asm
         AND    EDX,EDX
         JZ     @Exit
         AND    ECX,ECX
         JLE    @Exit
         PUSH   EAX
         MOV    AX,[EAX].THash_CRC16_CCITT.FCRC
         PUSH   EBX
         PUSH   EDI
         XOR    EBX,EBX
         LEA    EDI,CS:[OFFSET @CRC16]
@Start:  MOV    BL,AH
         SHL    AX,8
         MOV    AL,[EDX]
         XOR    AX,[EDI + EBX * 2]
         INC    EDX
         DEC    ECX
         JNZ    @Start
         POP    EDI
         POP    EBX
         POP    EDX
         MOV    [EDX].THash_CRC16_CCITT.FCRC,AX
@Exit:   RET

@CRC16:  DW     00000h, 01021h, 02042h, 03063h, 04084h, 050A5h, 060C6h, 070E7h
         DW     08108h, 09129h, 0A14Ah, 0B16Bh, 0C18Ch, 0D1ADh, 0E1CEh, 0F1EFh
         DW     01231h, 00210h, 03273h, 02252h, 052B5h, 04294h, 072F7h, 062D6h
         DW     09339h, 08318h, 0B37Bh, 0A35Ah, 0D3BDh, 0C39Ch, 0F3FFh, 0E3DEh
         DW     02462h, 03443h, 00420h, 01401h, 064E6h, 074C7h, 044A4h, 05485h
         DW     0A56Ah, 0B54Bh, 08528h, 09509h, 0E5EEh, 0F5CFh, 0C5ACh, 0D58Dh
         DW     03653h, 02672h, 01611h, 00630h, 076D7h, 066F6h, 05695h, 046B4h
         DW     0B75Bh, 0A77Ah, 09719h, 08738h, 0F7DFh, 0E7FEh, 0D79Dh, 0C7BCh
         DW     048C4h, 058E5h, 06886h, 078A7h, 00840h, 01861h, 02802h, 03823h
         DW     0C9CCh, 0D9EDh, 0E98Eh, 0F9AFh, 08948h, 09969h, 0A90Ah, 0B92Bh
         DW     05AF5h, 04AD4h, 07AB7h, 06A96h, 01A71h, 00A50h, 03A33h, 02A12h
         DW     0DBFDh, 0CBDCh, 0FBBFh, 0EB9Eh, 09B79h, 08B58h, 0BB3Bh, 0AB1Ah
         DW     06CA6h, 07C87h, 04CE4h, 05CC5h, 02C22h, 03C03h, 00C60h, 01C41h
         DW     0EDAEh, 0FD8Fh, 0CDECh, 0DDCDh, 0AD2Ah, 0BD0Bh, 08D68h, 09D49h
         DW     07E97h, 06EB6h, 05ED5h, 04EF4h, 03E13h, 02E32h, 01E51h, 00E70h
         DW     0FF9Fh, 0EFBEh, 0DFDDh, 0CFFCh, 0BF1Bh, 0AF3Ah, 09F59h, 08F78h
         DW     09188h, 081A9h, 0B1CAh, 0A1EBh, 0D10Ch, 0C12Dh, 0F14Eh, 0E16Fh
         DW     01080h, 000A1h, 030C2h, 020E3h, 05004h, 04025h, 07046h, 06067h
         DW     083B9h, 09398h, 0A3FBh, 0B3DAh, 0C33Dh, 0D31Ch, 0E37Fh, 0F35Eh
         DW     002B1h, 01290h, 022F3h, 032D2h, 04235h, 05214h, 06277h, 07256h
         DW     0B5EAh, 0A5CBh, 095A8h, 08589h, 0F56Eh, 0E54Fh, 0D52Ch, 0C50Dh
         DW     034E2h, 024C3h, 014A0h, 00481h, 07466h, 06447h, 05424h, 04405h
         DW     0A7DBh, 0B7FAh, 08799h, 097B8h, 0E75Fh, 0F77Eh, 0C71Dh, 0D73Ch
         DW     026D3h, 036F2h, 00691h, 016B0h, 06657h, 07676h, 04615h, 05634h
         DW     0D94Ch, 0C96Dh, 0F90Eh, 0E92Fh, 099C8h, 089E9h, 0B98Ah, 0A9ABh
         DW     05844h, 04865h, 07806h, 06827h, 018C0h, 008E1h, 03882h, 028A3h
         DW     0CB7Dh, 0DB5Ch, 0EB3Fh, 0FB1Eh, 08BF9h, 09BD8h, 0ABBBh, 0BB9Ah
         DW     04A75h, 05A54h, 06A37h, 07A16h, 00AF1h, 01AD0h, 02AB3h, 03A92h
         DW     0FD2Eh, 0ED0Fh, 0DD6Ch, 0CD4Dh, 0BDAAh, 0AD8Bh, 09DE8h, 08DC9h
         DW     07C26h, 06C07h, 05C64h, 04C45h, 03CA2h, 02C83h, 01CE0h, 00CC1h
         DW     0EF1Fh, 0FF3Eh, 0CF5Dh, 0DF7Ch, 0AF9Bh, 0BFBAh, 08FD9h, 09FF8h
         DW     06E17h, 07E36h, 04E55h, 05E74h, 02E93h, 03EB2h, 00ED1h, 01EF0h
end;

class function THash_CRC16_Standard.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0EDh,075h
end;

procedure THash_CRC16_Standard.Calc(const Data; DataSize: Integer);
asm
         PUSH   EAX
         MOV    AX,[EAX].THash_CRC16_Standard.FCRC
         CALL   CRC16
         POP    EDX
         MOV    [EDX].THash_CRC16_Standard.FCRC,AX
end;
{$IFDEF VER_D3H}
procedure ModuleUnload(Module: Integer);
var
  I: Integer;
begin
  if IsObject(FHashList, TStringList) then
    for I := HashList.Count-1 downto 0 do
      if Integer(FindClassHInstance(TClass(FHashList.Objects[I]))) = Module then
        FHashList.Delete(I);
end;
{$ENDIF}

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRHash> initialization started');
{$ENDIF}

  if CPUType <= 3 then SHABuffer := SHABuffer386 else SHABuffer := SHABuffer486;
{$IFDEF VER_D3H}
  AddModuleUnloadProc(ModuleUnload);
{$ENDIF}
{$IFNDEF ManualRegisterClasses}
  RegisterHash(THash_MD4, 'Message Digest 4', 'Hash');
  RegisterHash(THash_MD5, 'Message Digest 5', 'Hash');
  RegisterHash(THash_SHA, 'Secure Hash Algorithm', 'Hash');
  RegisterHash(THash_SHA1, 'Secure Hash Algorithm 1', 'Hash');
  RegisterHash(THash_RipeMD128, 'Ripe Message Digest 128', 'Hash');
  RegisterHash(THash_RipeMD160, 'Ripe Message Digest 160', 'Hash');
  RegisterHash(THash_RipeMD256, 'Ripe Message Digest 256', 'Hash');
  RegisterHash(THash_RipeMD320, 'Ripe Message Digest 320', 'Hash');
  RegisterHash(THash_Square, 'Square', 'Hash');
  RegisterHash(THash_XOR16, 'XOR-16', 'Checksum');
  RegisterHash(THash_XOR32, 'XOR-32', 'Checksum');
  RegisterHash(THash_CRC16_CCITT, 'CRC-16 CCITT', 'Checksum');
  RegisterHash(THash_CRC16_Standard, 'CRC-16 Standard', 'Checksum');
  RegisterHash(THash_CRC32, 'CRC-32', 'Checksum');
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRHash> initialization finished');
{$ENDIF}

finalization
{$IFDEF VER_D3H}
  RemoveModuleUnloadProc(ModuleUnload);
{$ENDIF}
  FHashList.Free;
  FHashList := nil;
end.

