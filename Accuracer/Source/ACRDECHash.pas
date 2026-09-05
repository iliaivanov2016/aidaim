{*****************************************************************************

  Delphi Encryption Compendium (DEC Part I)
  Version 5.2, Part I, for Delphi 7 - 2009

  Remarks:          Freeware, Copyright must be included

  Original Author:  (c) 2006 Hagen Reddmann, HaReddmann [at] T-Online [dot] de
  Modifications:    (c) 2008 Arvid Winkelsdorf, info [at] digivendo [dot] de

  Modifications:    (c) 2009 AidAim Software, http://www.aidaim.com
    
  Last change:      02. November 2008

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

*****************************************************************************}

unit ACRDECHash;


interface

{$I ACRVer.INC}
{$I VER.INC}

{$WARNINGS OFF}
{$RANGECHECKS OFF}

{$IFNDEF X64_ON}
 {$DEFINE THash_RipeMD128_asm}
 {$DEFINE THash_RipeMD256_asm}
{$ENDIF}


uses SysUtils, Classes, ACRDECUtil, ACRDECFmt;


type
{all Hash Classes}
  THash_RipeMD128       = class;
  THash_RipeMD256       = class;

  TDECHashClass = class of TDECHash;

  TDECHash = class(TDECObject)
  protected
    FCount: array[0..7] of LongWord;
    FBuffer: PByteArray;
    FBufferSize: Integer;
    FBufferIndex: Integer;
    FPaddingByte: Byte;
    procedure DoTransform(Buffer: PLongArray); virtual;
    procedure DoInit; virtual;
    procedure DoDone; virtual;
  public
    destructor Destroy; override;

    procedure Init;
    procedure Calc(const Data; DataSize: Integer); virtual;
    procedure Done;

    function Digest: PByteArray; virtual;
    function DigestStr(Format: TDECFormatClass = nil): Binary; virtual;

    class function DigestSize: Integer; virtual;
    class function BlockSize: Integer; virtual;

    class function CalcBuffer(const Buffer; BufferSize: Integer; Format: TDECFormatClass = nil): Binary;
    class function CalcStream(const Stream: TStream; Size: Int64; Format: TDECFormatClass = nil; const Progress: IDECProgress = nil): Binary;
    class function CalcBinary(const Data: Binary; Format: TDECFormatClass = nil): Binary;
    class function CalcFile(const FileName: String; Format: TDECFormatClass = nil; const Progress: IDECProgress = nil): Binary;

    class function MGF1(const Data: Binary; MaskSize: Integer; Format: TDECFormatClass = nil): Binary; overload;
    class function MGF1(const Data; DataSize, MaskSize: Integer; Format: TDECFormatClass = nil): Binary; overload;
    class function KDF2(const Data,Seed: Binary; MaskSize: Integer; Format: TDECFormatClass = nil): Binary; overload;
    class function KDF2(const Data; DataSize: Integer; const Seed; SeedSize, MaskSize: Integer; Format: TDECFormatClass = nil): Binary; overload;
   // DEC's own KDF+MGF
    class function MGFx(const Data; DataSize, MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary; overload;
    class function MGFx(const Data: Binary; MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary; overload;
    class function KDFx(const Data,Seed: Binary; MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary; overload;
    class function KDFx(const Data; DataSize: Integer; const Seed; SeedSize, MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary; overload;
  published
    property PaddingByte: Byte read FPaddingByte write FPaddingByte;
  end;

  THashBaseMD4 = class(TDECHash)
  private
    FDigest: array[0..9] of LongWord;
  protected
    procedure DoInit; override;
    procedure DoDone; override;
  public
    class function DigestSize: Integer; override;
    class function BlockSize: Integer; override;
    function Digest: PByteArray; override;
  end;

  THash_RipeMD128 = class(THashBaseMD4)
  protected
    procedure DoTransform(Buffer: PLongArray); override;
  end;

  THash_RipeMD256 = class(THashBaseMD4)
  protected
    procedure DoTransform(Buffer: PLongArray); override;
    procedure DoInit; override;
  public
    class function DigestSize: Integer; override;
  end;


function  ValidHash(HashClass: TDECHashClass = nil): TDECHashClass;
function  HashByName(const Name: String): TDECHashClass;
function  HashByIdentity(Identity: LongWord): TDECHashClass;
procedure SetDefaultHashClass(HashClass: TDECHashClass);

var
  StreamBufferSize: Integer = 8192;

implementation

{$I *.inc}

{                                        assembler                             pascal
THash_SHA512        :       85.1 cycles/byte      17.62 Mb/sec      220.9 cycles/byte       6.79 Mb/sec  159%
THash_SHA384        :       85.2 cycles/byte      17.61 Mb/sec      220.0 cycles/byte       6.82 Mb/sec  158%
THash_Tiger         :       24.6 cycles/byte      60.98 Mb/sec       60.7 cycles/byte      24.69 Mb/sec  147%
THash_Haval128      :       13.3 cycles/byte     112.55 Mb/sec       26.0 cycles/byte      57.77 Mb/sec   95%
THash_SHA1          :       20.1 cycles/byte      74.80 Mb/sec       36.1 cycles/byte      41.51 Mb/sec   80%
THash_SHA           :       20.0 cycles/byte      75.03 Mb/sec       35.5 cycles/byte      42.21 Mb/sec   78%
THash_Haval160      :       13.2 cycles/byte     113.30 Mb/sec       22.7 cycles/byte      66.12 Mb/sec   71%
THash_Haval256      :       25.9 cycles/byte      57.84 Mb/sec       40.5 cycles/byte      37.07 Mb/sec   56%
THash_Snefru128     :      159.7 cycles/byte       9.39 Mb/sec      248.2 cycles/byte       6.04 Mb/sec   55%
THash_Snefru256     :      239.3 cycles/byte       6.27 Mb/sec      367.9 cycles/byte       4.08 Mb/sec   54%
THash_RipeMD256     :       14.5 cycles/byte     103.16 Mb/sec       21.4 cycles/byte      70.08 Mb/sec   47%
THash_MD4           :        5.8 cycles/byte     256.73 Mb/sec        8.5 cycles/byte     176.92 Mb/sec   45%

THash_MD2           :      251.6 cycles/byte       5.96 Mb/sec      366.1 cycles/byte       4.10 Mb/sec   45%
THash_RipeMD128     :       15.2 cycles/byte      98.89 Mb/sec       21.2 cycles/byte      70.61 Mb/sec   40%
THash_RipeMD320     :       25.5 cycles/byte      58.73 Mb/sec       35.8 cycles/byte      41.87 Mb/sec   40%
THash_MD5           :        8.9 cycles/byte     169.43 Mb/sec       11.4 cycles/byte     131.01 Mb/sec   29%
THash_RipeMD160     :       26.5 cycles/byte      56.66 Mb/sec       31.4 cycles/byte      47.79 Mb/sec   19%
THash_Square        :       44.7 cycles/byte      33.58 Mb/sec       53.1 cycles/byte      28.23 Mb/sec   19%
THash_Haval192      :       32.5 cycles/byte      46.17 Mb/sec       37.6 cycles/byte      39.87 Mb/sec   18%
THash_Whirlpool1    :      104.9 cycles/byte      14.30 Mb/sec      122.8 cycles/byte      12.22 Mb/sec   17%
THash_Whirlpool     :      104.7 cycles/byte      14.33 Mb/sec      119.9 cycles/byte      12.51 Mb/sec   15%
THash_Sapphire      :       52.9 cycles/byte      28.35 Mb/sec       53.8 cycles/byte      27.86 Mb/sec    2%
THash_Haval224      :       32.0 cycles/byte      46.82 Mb/sec       32.3 cycles/byte      46.46 Mb/sec    1%
THash_SHA256        :       47.8 cycles/byte      31.35 Mb/sec       47.8 cycles/byte      31.39 Mb/sec    0%
THash_Panama        :        8.9 cycles/byte     169.01 Mb/sec        7.3 cycles/byte     206.55 Mb/sec  -18%
}

resourcestring
  sHashingOverflowError = 'Hash function have to many bits processed';
  sHashNotInitialized   = 'Hash must be initialized';
  sHashNoDefault        = 'No default hash are registered';

var
  FDefaultHashClass: TDECHashClass = nil;


function ValidHash(HashClass: TDECHashClass): TDECHashClass;
begin
  if HashClass <> nil then Result := HashClass
    else Result := FDefaultHashClass;
  if Result = nil then raise EDECException.Create(sHashNoDefault);
end;

function HashByName(const Name: String): TDECHashClass;
begin
  Result := TDECHashClass(DECClassByName(Name, TDECHash));
end;

function HashByIdentity(Identity: LongWord): TDECHashClass;
begin
  Result := TDECHashClass(DECClassByIdentity(Identity, TDECHash));
end;

procedure SetDefaultHashClass(HashClass: TDECHashClass);
begin
  if HashClass <> nil then HashClass.Register;
  FDefaultHashClass := HashClass;
end;



// .TDECHash
procedure TDECHash.DoTransform(Buffer: PLongArray);
begin
end;


procedure TDECHash.DoInit;
begin
end;


procedure TDECHash.DoDone;
var x: integer;
begin
 x := 0;
end;

destructor TDECHash.Destroy;
begin
  ProtectBuffer(Digest^, DigestSize);
  ProtectBuffer(FBuffer^, FBufferSize);
  ReallocMem(FBuffer, 0);
  inherited Destroy;
end;

procedure TDECHash.Init;
begin
  FBufferIndex := 0;
  FBufferSize := BlockSize;
  ReallocMem(FBuffer, FBufferSize);
  FillChar(FBuffer^, FBufferSize, 0);
  FillChar(FCount, SizeOf(FCount), 0);
  DoInit;
end;

procedure TDECHash.Done;
begin
  DoDone;
  ProtectBuffer(FBuffer^, FBufferSize);
  FBufferSize := 0;
  ReallocMem(FBuffer, 0);
end;

function TDECHash.Digest: PByteArray;
begin
 Result := nil;
end;

procedure HashingOverflowError;
begin
  raise EDECException.Create(sHashingOverflowError);
end;

procedure HashNotInitialized;
begin
  raise EDECException.Create(sHashNotInitialized);
end;

// fixed in 12.10
procedure Increment8(var Value; Add: Cardinal);
{$IFDEF X64_ON}
var x,x1: int64;
begin
{ TODO : todo: write it correctly }
 Move(PByte(PAnsiChar(@Value))^,x,SizeOf(x));
 x1 := Int64(x + 8 * Int64(add));
 if (x1<x) then
 begin
  Move(x1,PByte(PAnsiChar(@Value)+SizeOf(x))^,SizeOf(x));
  HashingOverflowError;
 end
 else
  Move(x1,PByte(PAnsiChar(@Value))^,SizeOf(x));
{$ELSE}
// Value := Value + 8 * Add
// Value: array[0..7] of Cardinal
asm
    MOV  ECX,EDX
    LEA  EDX,[EDX * 8]
    SHR  ECX,25
    ADD  [EAX].DWord[ 0],EDX
    ADC  [EAX].DWord[ 4],ECX
    ADC  [EAX].DWord[ 8],0
    ADC  [EAX].DWord[12],0
    ADC  [EAX].DWord[16],0
    ADC  [EAX].DWord[20],0
    ADC  [EAX].DWord[24],0
    ADC  [EAX].DWord[28],0
    JC   HashingOverflowError
{$ENDIF}
end;


procedure TDECHash.Calc(const Data; DataSize: Integer);
var
  Remain: Integer;
  Source: PByte;
begin
  if DataSize <= 0 then Exit;
  if FBuffer = nil then HashNotInitialized;
  Increment8(FCount, DataSize);
  Source := @TByteArray(Data)[0];
  if FBufferIndex > 0 then
  begin
    Remain := FBufferSize - FBufferIndex;
    if DataSize < Remain then
    begin
      Move(Source^, FBuffer[FBufferIndex], DataSize);
      Inc(FBufferIndex, DataSize);
      Exit;
    end;
    Move(Source^, FBuffer[FBufferIndex], Remain);
    DoTransform(Pointer(FBuffer));
    Dec(DataSize, Remain);
    Inc(Source, Remain);
  end;
  while DataSize >= FBufferSize do
  begin
    DoTransform(Pointer(Source));
    Inc(Source, FBufferSize);
    Dec(DataSize, FBufferSize);
  end;
  Move(Source^, FBuffer^, DataSize);
  FBufferIndex := DataSize;
end;

function TDECHash.DigestStr(Format: TDECFormatClass): Binary;
begin
  Result := ValidFormat(Format).Encode(Digest[0], DigestSize);
end;

class function TDECHash.DigestSize: Integer;
begin
 Result := 0;
end;

class function TDECHash.BlockSize: Integer;
begin
 Result := 0;
end;

class function TDECHash.CalcStream(const Stream: TStream; Size: Int64; Format: TDECFormatClass; const Progress: IDECProgress): Binary;
var
  Buffer: Binary;
  Bytes: Integer;
  Min,Max,Pos: Int64;
begin
  Min := 0;
  Max := 0;
  with Create do
  try
    Init;
    if StreamBufferSize <= 0 then StreamBufferSize := 8192;
    if Size < 0 then
    begin
      Stream.Position := 0;
      Size := Stream.Size;
      Pos := 0;
    end else Pos := Stream.Position;
    Bytes := StreamBufferSize mod FBufferSize;
    if Bytes = 0 then Bytes := StreamBufferSize
      else Bytes := StreamBufferSize + FBufferSize - Bytes;
    if Bytes > Size then SetLength(Buffer, Size)
      else SetLength(Buffer, Bytes);
    Min := Pos;
    Max := Pos + Size;
    while Size > 0 do
    begin
      if Assigned(Progress) then Progress.Process(Min, Max, Pos);
      Bytes := Length(Buffer);
      if Bytes > Size then Bytes := Size;
      Stream.ReadBuffer(Buffer[1], Bytes);
      Calc(Buffer[1], Bytes);
      Dec(Size, Bytes);
      Inc(Pos, Bytes);
    end;
    Done;
    Result := DigestStr(Format);
  finally
    Free;
    ProtectBinary(Buffer);
    if Assigned(Progress) then Progress.Process(Min, Max, Max);
  end;
end;

class function TDECHash.CalcBinary(const Data: Binary; Format: TDECFormatClass): Binary;
begin
  Result := CalcBuffer(Data[1], Length(Data), Format);
end;

class function TDECHash.CalcFile(const FileName: String; Format: TDECFormatClass; const Progress: IDECProgress): Binary;
var
  S: TFileStream;
begin
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := CalcStream(S, S.Size, Format, Progress);
  finally
    S.Free;
  end;
end;

class function TDECHash.CalcBuffer(const Buffer; BufferSize: Integer; Format: TDECFormatClass): Binary;
begin
  with Create do
  try
    Init;
    Calc(Buffer, BufferSize);
    Done;
    Result := DigestStr(Format);
  finally
    Free;
  end;
end;

class function TDECHash.MGF1(const Data; DataSize, MaskSize: Integer; Format: TDECFormatClass = nil): Binary;
// indexed Mask generation function, IEEE P1363 Working Group
// equal to KDF2 except without Seed
begin
  Result := KDF2(Data, DataSize, EmptyStr[1], 0, MaskSize, Format);
end;

class function TDECHash.MGF1(const Data: Binary; MaskSize: Integer; Format: TDECFormatClass = nil): Binary;
begin
  Result := KDF2(Data, Length(Data), EmptyStr[1], 0, MaskSize, Format);
end;

class function TDECHash.KDF2(const Data; DataSize: Integer; const Seed; SeedSize, MaskSize: Integer; Format: TDECFormatClass = nil): Binary;
// Key Generation Function 2, IEEE P1363 Working Group
var
  I,Rounds,DigestBytes: Integer;
  Dest: PByteArray;
  Count: LongWord;
begin
  DigestBytes := DigestSize;
  Assert(MaskSize >= 0);
  Assert(DataSize >= 0);
  Assert(SeedSize >= 0);
  Assert(DigestBytes >= 0);
  with Create do
  try
    Rounds := (MaskSize + DigestBytes -1) div DigestBytes;
    SetLength(Result, Rounds * DigestBytes);
    Dest := @Result[1];
    for I := 0 to Rounds -1 do
    begin
      Count := SwapLong(I);
      Init;
      Calc(Data, DataSize);
      Calc(Count, SizeOf(Count));
      Calc(Seed, SeedSize);
      Done;
      Move(Digest[0], Dest[I * DigestBytes], DigestBytes);
    end;
  finally
    Free;
  end;
  SetLength(Result, MaskSize);
  Result := ValidFormat(Format).Encode(Result[1], MaskSize);
end;

class function TDECHash.KDF2(const Data, Seed: Binary; MaskSize: Integer; Format: TDECFormatClass = nil): Binary;
begin
  Result := KDF2(Data[1], Length(Data), Seed[1], Length(Seed), MaskSize, Format);
end;

class function TDECHash.KDFx(const Data; DataSize: Integer; const Seed; SeedSize, MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary;
// DEC's own KDF, even stronger
var
  I,J: Integer;
  Count: LongWord;
  R: Byte;
begin
  Assert(MaskSize >= 0);
  Assert(DataSize >= 0);
  Assert(SeedSize >= 0);
  Assert(DigestSize >= 0);

  SetLength(Result, MaskSize);
  Index := SwapLong(Index);
  with Create do
  try
    for I := 0 to MaskSize -1 do
    begin
      Init;

      Count := SwapLong(I);
      Calc(Count, SizeOf(Count));
      Calc(Result[1], I);

      Calc(Index, SizeOf(Index));

      Count := SwapLong(SeedSize);
      Calc(Count, SizeOf(Count));
      Calc(Seed, SeedSize);

      Count := SwapLong(DataSize);
      Calc(Count, SizeOf(Count));
      Calc(Data, DataSize);

      Done;

      R := 0;
      for J := 0 to DigestSize -1 do
        R := R xor Digest[J];

      Result[I +1] := AnsiChar(R);
    end;
  finally
    Free;
  end;
  Result := ValidFormat(Format).Encode(Result[1], MaskSize);
end;

class function TDECHash.KDFx(const Data, Seed: Binary; MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary;
begin
  Result := KDFx(Data[1], Length(Data), Seed[1], Length(Seed), MaskSize, Format, Index);
end;

class function TDECHash.MGFx(const Data; DataSize, MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary;
begin
  Result := KDFx(Data, DataSize, EmptyStr[1], 0, MaskSize, Format, Index);
end;

class function TDECHash.MGFx(const Data: Binary; MaskSize: Integer; Format: TDECFormatClass = nil; Index: LongWord = 1): Binary;
begin
  Result := KDFx(Data[1], Length(Data), EmptyStr[1], 0, MaskSize, Format, Index);
end;


// .THashBaseMD4
class function THashBaseMD4.DigestSize: Integer;
begin
  Result := 16;
end;

class function THashBaseMD4.BlockSize: Integer;
begin
  Result := 64;
end;

function THashBaseMD4.Digest: PByteArray;
begin
  Result := @FDigest;
end;

procedure THashBaseMD4.DoInit;
begin
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FDigest[4] := $C3D2E1F0;
  FDigest[5] := $76543210;
  FDigest[6] := $FEDCBA98;
  FDigest[7] := $89ABCDEF;
  FDigest[8] := $01234567;
  FDigest[9] := $3C2D1E0F;
end;

procedure THashBaseMD4.DoDone;
begin
  if FCount[2] or FCount[3] <> 0 then HashingOverflowError;
  if FPaddingByte = 0 then FPaddingByte := $80;
  FBuffer[FBufferIndex] := FPaddingByte;
  Inc(FBufferIndex);
  if FBufferIndex > FBufferSize - 8 then
  begin
    FillChar(FBuffer[FBufferIndex], FBufferSize - FBufferIndex, 0);
    DoTransform(Pointer(FBuffer));
    FBufferIndex := 0;
  end;
  FillChar(FBuffer[FBufferIndex], FBufferSize - FBufferIndex, 0);
  Move(FCount, FBuffer[FBufferSize - 8], 8);
  DoTransform(Pointer(FBuffer));
end;

// .THash_RipeMD128
const
  RipeS1 = $5A827999;
  RipeS2 = $6ED9EBA1;
  RipeS3 = $8F1BBCDC;
  RipeS4 = $A953FD4E;
  RipeS5 = $50A28BE6;
  RipeS6 = $5C4DD124;
  RipeS7 = $6D703EF3;
  RipeS8 = $7A6D76E9;

{$IFNDEF THash_RipeMD128_asm}
procedure THash_RipeMD128.DoTransform(Buffer: PLongArray);
var
  A1,B1,C1,D1: LongWord;
  A2,B2,C2,D2: LongWord;
  T: LongWord;
begin
  A1 := FDigest[0];
  B1 := FDigest[1];
  C1 := FDigest[2];
  D1 := FDigest[3];
  A2 := FDigest[0];
  B2 := FDigest[1];
  C2 := FDigest[2];
  D2 := FDigest[3];

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

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + RipeS1); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 4] + RipeS1); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[13] + RipeS1); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 1] + RipeS1); B1 := B1 shl 13 or B1 shr 19;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + RipeS1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 6] + RipeS1); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[15] + RipeS1); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + RipeS1); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[12] + RipeS1); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + RipeS1); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 9] + RipeS1); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 5] + RipeS1); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 2] + RipeS1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + RipeS1); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[11] + RipeS1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 8] + RipeS1); B1 := B1 shl 12 or B1 shr 20;

  Inc(A1, B1 or not C1 xor D1 + Buffer[ 3] + RipeS2); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 or not B1 xor C1 + Buffer[10] + RipeS2); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 or not A1 xor B1 + Buffer[14] + RipeS2); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 4] + RipeS2); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 9] + RipeS2); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 or not B1 xor C1 + Buffer[15] + RipeS2); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 8] + RipeS2); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 1] + RipeS2); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 2] + RipeS2); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 or not B1 xor C1 + Buffer[ 7] + RipeS2); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 0] + RipeS2); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 6] + RipeS2); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 or not C1 xor D1 + Buffer[13] + RipeS2); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, A1 or not B1 xor C1 + Buffer[11] + RipeS2); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 5] + RipeS2); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 or not D1 xor A1 + Buffer[12] + RipeS2); B1 := B1 shl  5 or B1 shr 27;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + RipeS3); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 9] + RipeS3); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + RipeS3); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[10] + RipeS3); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 0] + RipeS3); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 8] + RipeS3); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[12] + RipeS3); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + RipeS3); B1 := B1 shl  8 or B1 shr 24;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + RipeS3); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 3] + RipeS3); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + RipeS3); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[15] + RipeS3); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[14] + RipeS3); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 5] + RipeS3); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 6] + RipeS3); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 2] + RipeS3); B1 := B1 shl 12 or B1 shr 20;

  T := A1; A1 := A2; A2 := T;
  T := B1; B1 := B2; B2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 5] + RipeS5); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[14] + RipeS5); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + RipeS5); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 0] + RipeS5); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 9] + RipeS5); A1 := A1 shl 13 or A1 shr 19;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 2] + RipeS5); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + RipeS5); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + RipeS5); B1 := B1 shl  5 or B1 shr 27;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + RipeS5); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 6] + RipeS5); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[15] + RipeS5); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 8] + RipeS5); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + RipeS5); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[10] + RipeS5); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 3] + RipeS5); C1 := C1 shl 12 or C1 shr 20;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[12] + RipeS5); B1 := B1 shl  6 or B1 shr 26;

  Inc(A1, B1 or not C1 xor D1 + Buffer[ 6] + RipeS6); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 or not B1 xor C1 + Buffer[11] + RipeS6); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 3] + RipeS6); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 7] + RipeS6); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 0] + RipeS6); A1 := A1 shl 12 or A1 shr 20;
  Inc(D1, A1 or not B1 xor C1 + Buffer[13] + RipeS6); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 5] + RipeS6); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 or not D1 xor A1 + Buffer[10] + RipeS6); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 or not C1 xor D1 + Buffer[14] + RipeS6); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 or not B1 xor C1 + Buffer[15] + RipeS6); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 8] + RipeS6); C1 := C1 shl 12 or C1 shr 20;
  Inc(B1, C1 or not D1 xor A1 + Buffer[12] + RipeS6); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 4] + RipeS6); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 or not B1 xor C1 + Buffer[ 9] + RipeS6); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 1] + RipeS6); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 2] + RipeS6); B1 := B1 shl 11 or B1 shr 21;

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[15] + RipeS7); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 5] + RipeS7); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 1] + RipeS7); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + RipeS7); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + RipeS7); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + RipeS7); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 6] + RipeS7); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 9] + RipeS7); B1 := B1 shl 14 or B1 shr 18;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[11] + RipeS7); A1 := A1 shl 12 or A1 shr 20;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 8] + RipeS7); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[12] + RipeS7); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 2] + RipeS7); B1 := B1 shl 14 or B1 shr 18;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + RipeS7); A1 := A1 shl 13 or A1 shr 19;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + RipeS7); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 4] + RipeS7); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[13] + RipeS7); B1 := B1 shl  5 or B1 shr 27;

  Inc(A1, B1 xor C1 xor D1 + Buffer[ 8]); A1 := A1 shl 15 or A1 shr 17;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 6]); D1 := D1 shl  5 or D1 shr 27;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 4]); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 1]); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 3]); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 xor B1 xor C1 + Buffer[11]); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 xor A1 xor B1 + Buffer[15]); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 0]); B1 := B1 shl 14 or B1 shr 18;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 5]); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 xor B1 xor C1 + Buffer[12]); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 2]); C1 := C1 shl 12 or C1 shr 20;
  Inc(B1, C1 xor D1 xor A1 + Buffer[13]); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 9]); A1 := A1 shl 12 or A1 shr 20;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 7]); D1 := D1 shl  5 or D1 shr 27;
  Inc(C1, D1 xor A1 xor B1 + Buffer[10]); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 xor D1 xor A1 + Buffer[14]); B1 := B1 shl  8 or B1 shr 24;

  Inc(D1, C2 + FDigest[1]);
  FDigest[1] := FDigest[2] + D2 + A1;
  FDigest[2] := FDigest[3] + A2 + B1;
  FDigest[3] := FDIgest[0] + B2 + C1;
  FDigest[0] := D1;
end;
{$ENDIF}

// fixed in 12.10
// .THash_RipeMD256
// .THash_RipeMD256
{$IFNDEF THash_RipeMD256_asm}
  /// Save & set compiler options
  {$IFOPT R+} {$DEFINE DoRangeChecks}    {$ENDIF}
  {$IFOPT Q+} {$DEFINE DoOverflowChecks} {$ENDIF}

  {$OVERFLOWCHECKS OFF} {$RANGECHECKS OFF}
procedure THash_RipeMD256.DoTransform(Buffer: PLongArray);
var
  A1,B1,C1,D1: Cardinal;
  A2,B2,C2,D2: Cardinal;
  T: Cardinal;
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

  T := A1; A1 := A2; A2 := T;
  T := B1; B1 := B2; B2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 5] + RipeS5); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[14] + RipeS5); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + RipeS5); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 0] + RipeS5); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 9] + RipeS5); A1 := A1 shl 13 or A1 shr 19;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 2] + RipeS5); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + RipeS5); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + RipeS5); B1 := B1 shl  5 or B1 shr 27;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + RipeS5); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 6] + RipeS5); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[15] + RipeS5); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 8] + RipeS5); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + RipeS5); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[10] + RipeS5); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 3] + RipeS5); C1 := C1 shl 12 or C1 shr 20;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[12] + RipeS5); B1 := B1 shl  6 or B1 shr 26;

  T := B1; B1 := B2; B2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + RipeS1); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 4] + RipeS1); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[13] + RipeS1); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 1] + RipeS1); B1 := B1 shl 13 or B1 shr 19;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + RipeS1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 6] + RipeS1); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[15] + RipeS1); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + RipeS1); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[12] + RipeS1); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + RipeS1); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 9] + RipeS1); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 5] + RipeS1); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 2] + RipeS1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + RipeS1); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[11] + RipeS1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 8] + RipeS1); B1 := B1 shl 12 or B1 shr 20;

  T := A1; A1 := A2; A2 := T;
  T := B1; B1 := B2; B2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 or not C1 xor D1 + Buffer[ 6] + RipeS6); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 or not B1 xor C1 + Buffer[11] + RipeS6); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 3] + RipeS6); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 7] + RipeS6); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 0] + RipeS6); A1 := A1 shl 12 or A1 shr 20;
  Inc(D1, A1 or not B1 xor C1 + Buffer[13] + RipeS6); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 5] + RipeS6); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 or not D1 xor A1 + Buffer[10] + RipeS6); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 or not C1 xor D1 + Buffer[14] + RipeS6); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 or not B1 xor C1 + Buffer[15] + RipeS6); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 8] + RipeS6); C1 := C1 shl 12 or C1 shr 20;
  Inc(B1, C1 or not D1 xor A1 + Buffer[12] + RipeS6); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 4] + RipeS6); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 or not B1 xor C1 + Buffer[ 9] + RipeS6); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 1] + RipeS6); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 2] + RipeS6); B1 := B1 shl 11 or B1 shr 21;

  T := A1; A1 := A2; A2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 or not C1 xor D1 + Buffer[ 3] + RipeS2); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 or not B1 xor C1 + Buffer[10] + RipeS2); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 or not A1 xor B1 + Buffer[14] + RipeS2); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 4] + RipeS2); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 9] + RipeS2); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 or not B1 xor C1 + Buffer[15] + RipeS2); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 8] + RipeS2); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 1] + RipeS2); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 or not C1 xor D1 + Buffer[ 2] + RipeS2); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 or not B1 xor C1 + Buffer[ 7] + RipeS2); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 0] + RipeS2); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 or not D1 xor A1 + Buffer[ 6] + RipeS2); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 or not C1 xor D1 + Buffer[13] + RipeS2); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, A1 or not B1 xor C1 + Buffer[11] + RipeS2); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 or not A1 xor B1 + Buffer[ 5] + RipeS2); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 or not D1 xor A1 + Buffer[12] + RipeS2); B1 := B1 shl  5 or B1 shr 27;

  T := A1; A1 := A2; A2 := T;
  T := B1; B1 := B2; B2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[15] + RipeS7); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 5] + RipeS7); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 1] + RipeS7); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + RipeS7); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + RipeS7); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + RipeS7); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 6] + RipeS7); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 9] + RipeS7); B1 := B1 shl 14 or B1 shr 18;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[11] + RipeS7); A1 := A1 shl 12 or A1 shr 20;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 8] + RipeS7); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[12] + RipeS7); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 2] + RipeS7); B1 := B1 shl 14 or B1 shr 18;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + RipeS7); A1 := A1 shl 13 or A1 shr 19;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + RipeS7); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 4] + RipeS7); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[13] + RipeS7); B1 := B1 shl  5 or B1 shr 27;

  T := A1; A1 := A2; A2 := T;
  T := B1; B1 := B2; B2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + RipeS3); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 9] + RipeS3); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + RipeS3); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[10] + RipeS3); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 0] + RipeS3); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 8] + RipeS3); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[12] + RipeS3); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + RipeS3); B1 := B1 shl  8 or B1 shr 24;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + RipeS3); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 3] + RipeS3); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + RipeS3); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[15] + RipeS3); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[14] + RipeS3); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 5] + RipeS3); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 6] + RipeS3); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 2] + RipeS3); B1 := B1 shl 12 or B1 shr 20;

  T := A1; A1 := A2; A2 := T;
  T := B1; B1 := B2; B2 := T;
  T := C1; C1 := C2; C2 := T;
  T := D1; D1 := D2; D2 := T;

  Inc(A1, B1 xor C1 xor D1 + Buffer[ 8]); A1 := A1 shl 15 or A1 shr 17;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 6]); D1 := D1 shl  5 or D1 shr 27;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 4]); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 1]); B1 := B1 shl 11 or B1 shr 21;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 3]); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 xor B1 xor C1 + Buffer[11]); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 xor A1 xor B1 + Buffer[15]); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 0]); B1 := B1 shl 14 or B1 shr 18;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 5]); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 xor B1 xor C1 + Buffer[12]); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 2]); C1 := C1 shl 12 or C1 shr 20;
  Inc(B1, C1 xor D1 xor A1 + Buffer[13]); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 9]); A1 := A1 shl 12 or A1 shr 20;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 7]); D1 := D1 shl  5 or D1 shr 27;
  Inc(C1, D1 xor A1 xor B1 + Buffer[10]); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 xor D1 xor A1 + Buffer[14]); B1 := B1 shl  8 or B1 shr 24;

  Inc(FDigest[0], A2);
  Inc(FDigest[1], B2);
  Inc(FDigest[2], C2);
  Inc(FDigest[3], D1);

  Inc(FDigest[4], A1);
  Inc(FDigest[5], B1);
  Inc(FDigest[6], C1);
  Inc(FDigest[7], D2);
end;
  /// Restore compiler options
  {$IFDEF DoRangeChecks}    {$RANGECHECKS ON}    {$UNDEF DoRangeChecks}    {$ENDIF}
  {$IFDEF DoOverflowChecks} {$OVERFLOWCHECKS ON} {$UNDEF DoOverflowChecks} {$ENDIF}
{$ENDIF}

procedure THash_RipeMD256.DoInit;
begin
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
end;

class function THash_RipeMD256.DigestSize: Integer;
begin
  Result := 32;
end;

end.
