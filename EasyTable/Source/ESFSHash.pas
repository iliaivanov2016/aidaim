{
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

unit ESFSHash;

interface

{$I ESFSVer.inc}
{$I Ver.inc}

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     ESFSDebug,
 {$ENDIF}
     ESFSDECUtil;

type
{all Hash Classes}
  THash_MD4             = class;
  THash_RipeMD256       = class;
  THash_RipeMD128       = class;

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

  THash_RipeMD128 = class(THash_MD4) {RACE Integrity Primitives Evaluation Message Digest}
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
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

function DefaultHashClass: THashClass;
procedure SetDefaultHashClass(HashClass: THashClass);
function RegisterHash(const AHash: THashClass; const AName, ADescription: AnsiString): Boolean;
function UnregisterHash(const AHash: THashClass): Boolean;
function HashList: TStrings;
procedure HashNames(List: TStrings);
function GetHashClass(const Name: AnsiString): THashClass;
function GetHashName(HashClass: THashClass): AnsiString;

implementation


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
{
  if Protection <> nil then
    if IsObject(Protection, TMAC) then
    begin
      with TMAC(Protection) do
        if IsInit then Init(Self) else Done(Self);
    end else
      if not IsInit then
        Protection.CodeBuffer(DigestKey^, DigestKeySize, paScramble);
}        
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
 
 
const
  THash_MD4_TestVector : array[0..15] of byte =
    ( $25,$EA,$BF,$CC,$8C,$C9,$6F,$D9,$2D,$CF,$7E,$BD,$7F,$87,$7C,$7C );

class function THash_MD4.TestVector: Pointer; assembler;
begin
  Result := @THash_MD4_TestVector;
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

const
  THash_RipeMD128_TestVector : array[0..15] of byte =
    ( $CF,$A0,$32,$CF,$D0,$8F,$87,$3A,$78,$DF,$13,$E7,$EB,$CD,$98,$0F );

class function THash_RipeMD128.TestVector: Pointer;
begin
  Result := @THash_RipeMD128_TestVector;
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

const
  THash_RipeMD256_TestVector : array[0..31] of byte =
    ( $C3,$B1,$D7,$AC,$A8,$9A,$47,$7A,$38,$D3,$6D,$39,$EF,$00,$FB,$45,$FC,$4E,$C3,$1A,$71,$21,$DB,$9E,$1C,$76,$C5,$DE,$99,$88,$18,$C2 );

class function THash_RipeMD256.TestVector: Pointer;
begin
  Result := @THash_RipeMD256_TestVector;
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
aaWriteToLog('ESFSHash> initialization started');
{$ENDIF}

{$IFDEF VER_D3H}
{$IFDEF D16H}
//
{$ELSE}
  AddModuleUnloadProc(ModuleUnload);
{$ENDIF}
{$ENDIF}
{$IFNDEF ManualRegisterClasses}
  RegisterHash(THash_MD4, 'Message Digest 4', 'Hash');
  RegisterHash(THash_RipeMD256, 'Ripe Message Digest 256', 'Hash');
  RegisterHash(THash_RipeMD128, 'Ripe Message Digest 128', 'Hash');
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSHash> initialization finished');
{$ENDIF}

finalization
{$IFDEF VER_D3H}
{$IFDEF D16H}
//
{$ELSE}
  RemoveModuleUnloadProc(ModuleUnload);
{$ENDIF}
{$ENDIF}
  FHashList.Free;
  FHashList := nil;
end.

