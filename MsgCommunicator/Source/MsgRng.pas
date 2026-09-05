{Copyright:      Hagen Reddmann  mailto:HaReddmann@AOL.COM
 Author:         Hagen Reddmann
 Remarks:        freeware, but this Copyright must be included
 known Problems: none
 Version:        3.0
                 Delphi 2-4, designed and testet under D3 and D4
 Description:    Linear Feedback Shift Register (LFSR)
                 Random Number Generator with variable Period
                 from 2^32 -1 to 2^2032 -1, Standard is 2^128 -1
                 with .Seed('', -1) absolutly random
                 The Period have theoretical no effect on the Speed.

 Speed:          ca. 40 Mb/sec of a PII MMX 266 MHz 64Mb RAM

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


  Speed: all times for PII MMX 266Mhz 64Mb
         theoretical have the Period (Size of LFSR) no effect on the Speed,
         but a greater Period will run faster. (Cache, little Branches on Pentium, etc.)
         except the Period 2^128-1, this use a specially optimized method.

              >   14.5 Mb/sec
              >   40.5 Mb/sec with 128bit LFSR
Version 3.0

  TRandom is now a descend from TProtect, see Unit DECUtil.pas

 }

////////////////////////////////////////////////////////////////////////////////
//
// Updated to support x64 platform by AidAim Software in 2012, www.aidaim.com
//
////////////////////////////////////////////////////////////////////////////////

unit MsgRng;

interface

{$I MsgVer.inc}
{$I Ver.inc}

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgDecUtil;

type
  ERandom = class(Exception);

  TRandom = class(TProtection)    // Basicly RNG, equal to Borland's Random()
  private
    FRegister: Integer;
    FPassword: AnsiString;
  protected
    FCount: Integer;          // not as private Fields, easier access for descends
    FSize: Integer;
    FBasicSeed: Integer;
    procedure SetSize(Value: Integer); virtual;
    function GetState: AnsiString; virtual;
    procedure SetState(Value: AnsiString); virtual;
// override TProtect Methods
    procedure CodeInit(Action: TPAction); override;
    procedure CodeDone(Action: TPAction); override;
    procedure CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction); override;
  public
    constructor Create(const APassword: AnsiString; ASize: Integer; ARandomize: Boolean; AProtection: TProtection); virtual;
    destructor Destroy; override;
// set the Seed register
//  Size =  0 -> Seed to initial Value
//  Size <  0 -> Seed to randomness Value, equal to Randomize
//  Size >  0 -> Seed is set to Buffer
    procedure Seed(const ABuffer; ASize: Integer); virtual;
// fill out ABuffer ASize Bytes randomly
    procedure Buffer(var ABuffer; ASize: Integer); virtual;
// gives Random Integer in ARange
    function Int(ARange: Integer): Integer; virtual;
// Stream loading/saving
    procedure SaveToStream(Stream: TStream); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
// File loading/saving
    procedure SaveToFile(const FileName: AnsiString);
    procedure LoadFromFile(const FileName: AnsiString);
// Count of Bytes that Int() or Buffer() has generated
    property Count: Integer read FCount write FCount;
// the Size in Bits
    property Size: Integer read FSize write SetSize;
// basicly Seed Value for use in .Seed(), Standard is DefaultSeed
    property BasicSeed: Integer read FBasicSeed write FBasicSeed;
// the internal State as MIMIE Base64 AnsiString
    property State: AnsiString read GetState write SetState;
  end;

  TRandom_LFSR = class(TRandom)       // Linear Feedback Shift Register
  private
    FPtr: Integer;                    // Current Position in FRegister
    FLast: Integer;                   // Highest Position in FRegister
    FTable: array[0..255] of Word;    // Lookup Table for FRegister
    FRegister: array[0..255] of Byte; // Linear Feedback Shift Register
    FFunc: procedure(Self: Pointer; var Buffer; Size: Integer);
  protected
    procedure SetSize(Value: Integer); override;
    function GetState: AnsiString; override;
    procedure SetState(Value: AnsiString); override;
  public
    procedure Seed(const ABuffer; ASize: Integer); override;
    procedure Buffer(var ABuffer; ASize: Integer); override;
  end;

{   Follow the used polynomial's for TRandom_LFSR
     size in bytes of register, XORCode, Polynomial, Period

   4, $F5, x^32   + x^7 + x^5 + x^3 + x^2 + x + 1,   2^32   -1
   5, $9C, x^40   + x^5 + x^4 + x^3 + 1,             2^40   -1
   6, $ED, x^48   + x^7 + x^5 + x^4 + x^2 + x + 1,   2^48   -1
   7, $A9, x^56   + x^7 + x^4 + x^2 + 1,             2^56   -1
   8, $D8, x^64   + x^4 + x^3 + x + 1,               2^64   -1
   9, $FA, x^72   + x^6 + x^4 + x^3 + x^2 + x + 1,   2^72   -1
  10, $F5, x^80   + x^7 + x^5 + x^3 + x^2 + x + 1,   2^80   -1
  12, $BB, x^96   + x^7 + x^6 + x^4 + x^3 + x^2 + 1, 2^96   -1
  15, $E7, x^120  + x^7 + x^6 + x^5 + x^2 + x + 1,   2^120  -1
  16, $E1, x^128  + x^7 + x^2 + x + 1,               2^128  -1
  18, $A9, x^144  + x^7 + x^4 + x^2 + 1,             2^144  -1
  19, $B2, x^152  + x^6 + x^3 + x^2 + 1,             2^152  -1
  20, $B4, x^160  + x^5 + x^3 + x^2 + 1,             2^160  -1
  22, $BD, x^176  + x^7 + x^5 + x^4 + x^3 + x^2 + 1, 2^176  -1
  25, $B4, x^200  + x^5 + x^3 + x^2 + 1,             2^200  -1
  27, $D1, x^216  + x^7 + x^3 + x + 1,               2^216  -1
  38, $FC, x^304  + x^5 + x^4 + x^3 + x^2 + x + 1,   2^304  -1
  40, $D8, x^320  + x^4 + x^3 + x + 1,               2^320  -1
  42, $C9, x^336  + x^7 + x^4 + x + 1,               2^336  -1
  44, $BD, x^352  + x^7 + x^5 + x^4 + x^3 + x^2 + 1, 2^352  -1
  50, $B4, x^400  + x^5 + x^3 + x^2 + 1,             2^400  -1
  51, $FA, x^408  + x^6 + x^4 + x^3 + x^2 + x + 1,   2^408  -1
  55, $D8, x^440  + x^4 + x^3 + x + 1,               2^440  -1
  60, $BB, x^480  + x^7 + x^6 + x^4 + x^3 + x^2 + 1, 2^480  -1
  61, $D8, x^488  + x^4 + x^3 + x + 1,               2^488  -1
  63, $FA, x^504  + x^6 + x^4 + x^3 + x^2 + x + 1,   2^504  -1
  67, $95, x^536  + x^7 + x^5 + x^3 + 1,             2^536  -1
  84, $F6, x^672  + x^6 + x^5 + x^3 + x^2 + x + 1,   2^672  -1
  89, $9C, x^712  + x^5 + x^4 + x^3 + 1,             2^712  -1
  91, $B8, x^728  + x^4 + x^3 + x^2 + 1,             2^728  -1
 103, $FC, x^824  + x^5 + x^4 + x^3 + x^2 + x + 1,   2^824  -1
 141, $D1, x^1128 + x^7 + x^3 + x + 1,               2^1128 -1
 154, $F3, x^1232 + x^7 + x^6 + x^3 + x^2 + x + 1,   2^1232 -1
 254, $A3, x^2032 + x^7 + x^6 + x^2 + 1,             2^2032 -1

  follow various Periods
--------------------------------------------------------------------------------
  2^32-1   = 4294967295
  2^64-1   = 18446744073709551615
  2^128-1  = 340282366920938463463374607431768211455
  2^2032-1 = it's one Number
   49311837877366649323600580884811328064642490645928167773636391338386009428204
   17921935608125537553934278674005267623599165972833122328326583112816221076703
   35702985799671951234310153163915857728680359766210694390385082889078409114931
   66867209378778336289339669574030006474132653643098550122997363890264786354861
   31947843882498538312526670313197249581325688984118966381501107686008635362008
   71492771279798342546336760614070411100118371556871830774626226863061725361438
   46476937385117828689155818331492509954024778049592066494651864619855274961300
   9880449926596639031121858756000207590413184793166384097191709192063287295
--------------------------------------------------------------------------------
}

// Your actual Random Class, per default TRandom_LFSR.Create(128, False)
function RND: TRandom;

// internal used for the random initialization of the Seed Initial Value
// change this to produce Application dependent Randomness
const
  DefaultSeed: Integer = 693258280;

{$IFDEF X64_ON}
//!!<>
procedure LFSRBuf(Self: Pointer; var Buffer; Size: Integer);
procedure LFSRBuf128(Self: Pointer; var Buffer; Size: Integer);
//!!</>
{$ENDIF}

implementation

uses MsgDECConst;

const
  FRND: TRandom = nil;

// avaible Periods for the LFSR
  LFSRPeriod: array[0..33, 0..1] of Word =
   ((   32, $F5), (   40, $9C), (   48, $ED), (   56, $A9),
    (   64, $D8), (   72, $FA), (   80, $F5), (   96, $BB),
    (  120, $E7), (  128, $E1), (  144, $A9), (  152, $B2),
    (  160, $B4), (  176, $BD), (  200, $B4), (  216, $D1),
    (  304, $FC), (  320, $D8), (  336, $C9), (  352, $BD),
    (  400, $B4), (  408, $FA), (  440, $D8), (  480, $BB),
    (  488, $D8), (  504, $FA), (  536, $95), (  672, $F6),
    (  712, $9C), (  728, $B8), (  824, $FC), ( 1128, $D1),
    ( 1232, $F3), ( 2032, $A3));

function RND: TRandom;
begin
  if FRND = nil then
  begin
    FRND := TRandom_LFSR.Create('', 0, False, nil);
    FRND.AddRef;
  end;
  Result := FRND;
end;

procedure TRandom.SetSize(Value: Integer);
begin
  FSize := 32; // allways 32
end;

function TRandom.GetState: AnsiString;
var
  CRC: Word;
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
// write a Randomized Word to begin,
// any Encryption produce allways other outputs
    RndXORBuffer(RndTimeSeed, CRC, SizeOf(CRC));
    M.Write(CRC, SizeOf(CRC));
    M.Write(FSize, SizeOf(FSize));
    M.Write(FBasicSeed, SizeOf(FBasicSeed));
    M.Write(FCount, SizeOf(FCount));
    M.Write(FRegister, SizeOf(FRegister));
    CRC := not CRC16($FFFF, M.Memory, M.Size);
    M.Write(CRC, SizeOf(CRC));
    CRC := $0100; // Version 1 without Protection
    if Protection <> nil then
    begin
      CRC := CRC or 1; // with Protection
      M.Position := 0;
      Protection.CodeStream(M, M, M.Size, paEncode);
      M.Position := M.Size;
    end;
    M.Write(CRC, SizeOf(CRC));
    Result := StrToFormat(M.Memory, M.Size, fmtMIME64);
  finally
    M.Free;
  end;
end;

procedure TRandom.SetState(Value: AnsiString);
var
  CRC: Word;
  I: Integer;
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    Value := FormatToStr(PAnsiChar(Value), Length(Value), fmtMIME64);
    M.Write(PAnsiChar(Value)^, Length(Value));
    M.Position := M.Size - SizeOf(CRC);
    M.Read(CRC, SizeOf(CRC));
    if CRC and $FF00 <> $0100 then // it's Version $0100 ?
      raise ERandom.Create(sInvalidRandomStream);
    if CRC and 1 <> 0 then
      if Protection <> nil then
      begin
        M.Position := 0;
        Protection.CodeStream(M, M, M.Size - SizeOf(CRC), paDecode);
      end else raise ERandom.Create(sRandomDataProtected);
    M.Position := M.Size - SizeOf(CRC) * 2;
    M.Read(CRC, SizeOf(CRC));
    if CRC <> not CRC16($FFFF, M.Memory, M.Size - SizeOf(CRC) * 2) then
      raise ERandom.Create(sInvalidRandomStream);
    M.Position := SizeOf(CRC); // skip Dummy Random Word
    M.Read(I, SizeOf(FSize));
    SetSize(I);
    M.Read(FCount, SizeOf(FCount));
    M.Read(FBasicSeed, SizeOf(FBasicSeed));
    M.Read(FRegister, SizeOf(FRegister));
  finally
    M.Free;
  end;
end;

constructor TRandom.Create(const APassword: AnsiString; ASize: Integer; ARandomize: Boolean; AProtection: TProtection);
begin
  inherited Create(AProtection);
  FBasicSeed := DefaultSeed;
  FSize := -1;
  FPassword := APassword;
  SetSize(ASize);
  if ASize > 0 then
    if not ARandomize then Seed(PAnsiChar(FPassword)^, Length(FPassword))
      else Seed('', -1);
end;

destructor TRandom.Destroy;
begin
  Seed('', 0); 
  if Self = FRND then FRND := nil; 
  inherited Destroy;
end; 
 
procedure TRandom.Seed(const ABuffer; ASize: Integer); 
var 
  I: Integer; 
  R: PByteArray;
begin
  if (ASize > 0) and (@ABuffer <> nil) then 
  begin
    FRegister := FBasicSeed; 
    FillChar(FRegister, SizeOf(FRegister), 0); 
    R := @FRegister; 
    for I := 0 to ASize -1 do
      R[I and 3] := R[I and 3] + TByteArray(ABuffer)[I];
  end else 
    if ASize < 0 then FRegister := RndTimeSeed + (FCount +1)
      else FRegister := FBasicSeed;
  if Protection <> nil then
    Protection.CodeBuffer(FRegister, SizeOf(FRegister), paScramble); 
end; 
	
function TRandom.Int(ARange: Integer): Integer; 
begin
  Buffer(Result, SizeOf(Result));
  if (ARange = 0) or (Result = 0) then Exit; 
  if (ARange >= 0) and (Result < 0) then Result := -Result else
    if ARange < 0 then ARange := -ARange;
  Result := Result mod (ARange +1);
  Inc(FCount, SizeOf(Result)); 
end;
	
procedure TRandom.Buffer(var ABuffer; ASize: Integer);
begin 
  if ASize <= 0 then Exit; 
  FillChar(ABuffer, ASize, 0);
  FRegister := RndXORBuffer(FRegister, ABuffer, ASize); 
  Inc(FCount, ASize); 
  if Protection <> nil then 
    Protection.CodeBuffer(ABuffer, ASize, paScramble);
end;
	
procedure TRandom.SaveToStream(Stream: TStream);
var 
  I: Integer; 
  S,C: AnsiString;
begin 
  C := ClassName;
  if C[1] = 'T' then Delete(C, 1, 1); 
  I := Pos('_', C); 
  if I > 0 then Delete(C, 1, I);
  S := InsertCR(State, 64);
  C := C + IntToHex(Length(S), 4) + #13#10 + S;
  Stream.Write(PAnsiChar(C)^, Length(C)); 
end; 
 
procedure TRandom.LoadFromStream(Stream: TStream); 
var 
  C,S: AnsiString; 
  I: Integer; 
begin 
// write the Name from ClassName (i.E. TRandom_LFSR -> "LFSR"), 
// the Size as a 4 AnsiChar HEX AnsiString and State. 
// i.E. LFSR0FCB <CR> State 
  C := ClassName;
  if C[1] = 'T' then Delete(C, 1, 1);
  I  := Pos('_', C);
  if I > 0 then Delete(C, 1, I); 
  SetLength(S, Length(C));
  Stream.Read(PAnsiChar(S)^, Length(C)); 
  if S <> C then Abort; 
  SetLength(S, 6); 
  Stream.Read(PAnsiChar(S)^, 6); 
  SetLength(S, 4); 
  I := StrToInt('$' + S); 
  SetLength(S, I); 
  Stream.Read(PAnsiChar(S)^, I); 
  State := DeleteCR(S); 
end; 
 
procedure TRandom.SaveToFile(const FileName: AnsiString);
var 
  S: TStream;
begin 
  S := TFileStream.Create(FileName, fmCreate); 
  try
    SaveToStream(S);
  finally
    S.Free; 
  end;
end;
 
procedure TRandom.LoadFromFile(const FileName: AnsiString); 
var
  S: TStream;
begin 
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try 
    LoadFromStream(S); 
  finally
    S.Free; 
  end;
end;
 
procedure TRandom.CodeInit(Action: TPAction); 
begin
  if Action = paWipe then Seed('', -1) 
    else Seed(PAnsiChar(FPassword)^, Length(FPassword));
  inherited CodeInit(Action); 
end; 
	
procedure TRandom.CodeDone(Action: TPAction);
begin
  inherited CodeDone(Action);
  if Action = paWipe then Seed('', -1)
    else Seed(PAnsiChar(FPassword)^, Length(FPassword));
end;
 
procedure TRandom.CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction);
const 
  maxBufSize = 1024 * 4;
var
  Buf: Pointer;
  BPtr: PByte; 
  BSize,CSize: Integer;
begin 
  if Action <> paDecode then inherited CodeBuf(Buffer, BufferSize, Action);
  if Action in Actions then
  begin
    BPtr := @Buffer;
    if BPtr = nil then Exit;
    BSize := maxBufSize;
    if BSize > BufferSize then BSize := BufferSize;
    Buf := AllocMem(BSize);
    CSize := BufferSize;
    try
      if Action = paCalc then
      begin
        while CSize > 0 do
        begin
          BSize := CSize;
          if BSize > maxBufSize then BSize := maxBufSize;
          Self.Buffer(Buf^, BSize);
          XORBuffers(Buf, BPtr, BSize, Buf);
          Inc(BPtr, BSize);
          Dec(CSize, BSize);
        end
      end else
      begin
        while CSize > 0 do
        begin
          BSize := CSize;
          if BSize > maxBufSize then BSize := maxBufSize;
          Self.Buffer(Buf^, BSize);
          XORBuffers(Buf, BPtr, BSize, BPtr);
          Inc(BPtr, BSize);
          Dec(CSize, BSize);
        end;
      end;
    finally
      ReallocMem(Buf, 0);
    end;
  end;
  if Action = paDecode then
    inherited CodeBuf(Buffer, BufferSize, Action);
end;

{$IFDEF X64_ON}
// internal for TRandom_LFSR
procedure LFSRBuf(Self: Pointer; var Buffer; Size: Integer);
var
  wSelf         : TRandom_LFSR absolute Self;
  wBuffer       : TByteArray absolute Buffer;
  wRegister     : word;
  wRegisterWord : WordRec absolute wRegister;
  i             : integer;
//////  FPtr: Integer;                    // Current Position in FRegister
//////  FLast: Integer;                   // Highest Position in FRegister
//////  FTable: array[0..255] of Word;    // Lookup Table for FRegister
//////  FRegister: array[0..255] of Byte; // Linear Feedback Shift Register
//////  FFunc: procedure(Self: Pointer; var Buffer; Size: Integer);
begin
  if ( @Buffer <> nil ) and ( Size > 0 )
    then
      begin
        for i := Size - 1 downto 0 do
          begin
            wBuffer[i] := wSelf.FRegister[wSelf.FPtr];
            wRegister  := wSelf.FTable[ wBuffer[i] ];

            wSelf.FRegister[wSelf.FPtr] := wRegisterWord.Lo;
            if wSelf.FPtr >= 0
              then
                begin
                  wSelf.FRegister[wSelf.FPtr] := wSelf.FRegister[wSelf.FPtr] xor wRegisterWord.Hi;
                  inc( wSelf.FPtr, 2 );
                  if wSelf.FPtr > wSelf.FLast
                    then wSelf.FPtr := 0;
                end
              else
                begin
                  wSelf.FRegister[wSelf.FLast] := wRegisterWord.Hi;
                  wSelf.FPtr := 1;
                end
          end;
      end;
end;
//asm
//      AND     EDX,EDX    // Buffer = nil ?
//      JZ      @@9
//      AND     ECX,ECX    // BufferSize <= 0 ?
//      JLE     @@9
//
//      PUSH    EDI
//      PUSH    ESI
//      PUSH    EBX
//      PUSH    EBP
//      PUSH    EAX
//
//      MOV     EDI,[EAX].TRandom_LFSR.FPtr
//      MOV     EBP,[EAX].TRandom_LFSR.FLast
//      LEA     ESI,[EAX].TRandom_LFSR.FRegister
//      LEA     EBX,[EAX].TRandom_LFSR.FTable
//      DEC     EDX
//
//@@1:  MOVZX   EAX,Byte Ptr [ESI + EDI]
//      MOV     [EDX + ECX],AL
//      MOV     AX,[EBX + EAX * 2]
//      MOV     [ESI + EDI],AL
//      DEC     EDI
//      JS      @@2
//      XOR     [ESI + EDI],AH
//      ADD     EDI,2
//      CMP     EDI,EBP
//      JLE     @@3
//      XOR     EDI,EDI
//      JMP     @@3
//@@2:  MOV     EDI,EBP
//      XOR     [ESI + EDI],AH
//      MOV     EDI,1
//@@3:  DEC     ECX
//      JNZ     @@1
//
//      POP     EAX
//      MOV     [EAX].TRandom_LFSR.FPtr,EDI
//
//      POP     EBP
//      POP     EBX
//      POP     ESI
//      POP     EDI
//
//@@9:
//end;

procedure LFSRBuf128(Self: Pointer; var Buffer; Size: Integer);
var
  wSelf         : TRandom_LFSR absolute Self;
  wBuffer       : TByteArray absolute Buffer;
  i             : integer;
  wRegister     : word;
  wRegisterWord : WordRec absolute wRegister;
begin
  if ( @Buffer <> nil ) and ( Size > 0 )
    then
      begin
        for i := Size - 1 downto 0 do
          begin
            wBuffer[i] := wSelf.FRegister[wSelf.FPtr];
            wRegister  := wSelf.FTable[ wBuffer[i] ];

            wSelf.FRegister[wSelf.FPtr] := wRegisterWord.Lo;
            wSelf.FPtr := ( wSelf.FPtr - 1 ) and $0F;

            wSelf.FRegister[wSelf.FPtr] := wSelf.FRegister[wSelf.FPtr] xor wRegisterWord.Hi;
            wSelf.FPtr := ( wSelf.FPtr + 2 ) and $0F;
          end;
      end;
end;
//asm
//      AND     EDX,EDX    // Buffer = nil ?
//      JZ      @@9
//      AND     ECX,ECX    // BufferSize <= 0 ?
//      JLE     @@9
//
//      PUSH    EDI
//      PUSH    ESI
//      PUSH    EBX
//      PUSH    EBP
//      PUSH    EAX
//
//      MOV     EDI,[EAX].TRandom_LFSR.FPtr
//      LEA     EBP,[EAX].TRandom_LFSR.FTable
//      LEA     ESI,[EAX].TRandom_LFSR.FRegister
//      DEC     EDX
//      XOR     EAX,EAX
//
//@@1:  MOV     AL,[ESI + EDI]
//      MOV     BX,[EBP + EAX * 2]
//      MOV     [EDX + ECX],AL
//      MOV     [ESI + EDI],BL
//      DEC     EDI
//      AND     EDI,0Fh
//      XOR     [ESI + EDI],BH
//      ADD     EDI,2
//      AND     EDI,0Fh
//      DEC     ECX
//      JNZ     @@1
//
//      POP     EAX
//      MOV     [EAX].TRandom_LFSR.FPtr,EDI
//
//      POP     EBP
//      POP     EBX
//      POP     ESI
//      POP     EDI
//
//@@9:
//end;

procedure TRandom_LFSR.SetSize(Value: Integer);

  procedure CalcLFSRTable(XORCode: Byte);
  var
    I,J,Z: Integer;
  begin
    XorCode := ReversedBits[XorCode];
//    asm // Reverse the bitorder
//      XOR   AX,AX
//      MOV   AL,XORCode
//      MOV   CL,8
//@@1:  RCR   AL,1
//      RCL   AH,1
//      DEC   CL
//      JNZ   @@1
//      MOV   XORCode,AH
//    end;
    FillChar(FTable, SizeOf(FTable), 0);
    for I := 0 to 255 do
    begin
      Z := I;
      for J := 0 to 7 do
      begin
        FTable[I] := FTable[I] shl 1;
        if Z and $80 <> 0 then FTable[I] := FTable[I] xor XORCode;
        Z := Z shl 1;
      end;
    end;
  end;
{$ELSE}
// internal for TRandom_LFSR
procedure LFSRBuf(Self: Pointer; var Buffer; Size: Integer); assembler;
asm
      AND     EDX,EDX    // Buffer = nil ?
      JZ      @@9
      AND     ECX,ECX    // BufferSize <= 0 ?
      JLE     @@9

      PUSH    EDI
      PUSH    ESI
      PUSH    EBX
      PUSH    EBP
      PUSH    EAX

      MOV     EDI,[EAX].TRandom_LFSR.FPtr
      MOV     EBP,[EAX].TRandom_LFSR.FLast
      LEA     ESI,[EAX].TRandom_LFSR.FRegister
      LEA     EBX,[EAX].TRandom_LFSR.FTable
      DEC     EDX

@@1:  MOVZX   EAX,Byte Ptr [ESI + EDI]
      MOV     [EDX + ECX],AL
      MOV     AX,[EBX + EAX * 2]
      MOV     [ESI + EDI],AL
      DEC     EDI
      JS      @@2
      XOR     [ESI + EDI],AH
      ADD     EDI,2
      CMP     EDI,EBP
      JLE     @@3
      XOR     EDI,EDI
      JMP     @@3
@@2:  MOV     EDI,EBP
      XOR     [ESI + EDI],AH
      MOV     EDI,1
@@3:  DEC     ECX
      JNZ     @@1

      POP     EAX
      MOV     [EAX].TRandom_LFSR.FPtr,EDI

      POP     EBP
      POP     EBX
      POP     ESI
      POP     EDI

@@9:
end;

procedure LFSRBuf128(Self: Pointer; var Buffer; Size: Integer); assembler;
asm
      AND     EDX,EDX    // Buffer = nil ?
      JZ      @@9
      AND     ECX,ECX    // BufferSize <= 0 ?
      JLE     @@9

      PUSH    EDI
      PUSH    ESI
      PUSH    EBX
      PUSH    EBP
      PUSH    EAX

      MOV     EDI,[EAX].TRandom_LFSR.FPtr
      LEA     EBP,[EAX].TRandom_LFSR.FTable
      LEA     ESI,[EAX].TRandom_LFSR.FRegister
      DEC     EDX
      XOR     EAX,EAX

@@1:  MOV     AL,[ESI + EDI]
      MOV     BX,[EBP + EAX * 2]
      MOV     [EDX + ECX],AL
      MOV     [ESI + EDI],BL
      DEC     EDI
      AND     EDI,0Fh
      XOR     [ESI + EDI],BH
      ADD     EDI,2
      AND     EDI,0Fh
      DEC     ECX
      JNZ     @@1

      POP     EAX
      MOV     [EAX].TRandom_LFSR.FPtr,EDI

      POP     EBP
      POP     EBX
      POP     ESI
      POP     EDI

@@9:
end;

procedure TRandom_LFSR.SetSize(Value: Integer);

  procedure CalcLFSRTable(XORCode: Byte);
  var
    I,J,Z: Integer;
  begin
    asm // Reverse the bitorder
      XOR   AX,AX
      MOV   AL,XORCode
      MOV   CL,8
@@1:  RCR   AL,1
      RCL   AH,1
      DEC   CL
      JNZ   @@1
      MOV   XORCode,AH
    end;
    FillChar(FTable, SizeOf(FTable), 0);
    for I := 0 to 255 do
    begin
      Z := I;
      for J := 0 to 7 do
      begin
        FTable[I] := FTable[I] shl 1;
        if Z and $80 <> 0 then FTable[I] := FTable[I] xor XORCode;
        Z := Z shl 1;
      end;
    end;
  end;
{$ENDIF}

  procedure DoSet(Index: Integer);
  begin
    FSize := LFSRPeriod[Index, 0];
    FLast := LFSRPeriod[Index, 0] div 8 -1;
    if FSize = 128 then FFunc := LFSRBuf128 else FFunc := LFSRBuf;
    CalcLFSRTable(LFSRPeriod[Index, 1]);
    Seed('', 0);
  end;

var
  I: Integer;
begin
  if Value <= 0 then Value := 128;
  if Value <> FSize then
  begin
    for I := 33 downto 0 do
      if Value >= LFSRPeriod[I, 0] then
      begin
        DoSet(I);
        Exit;
      end;
    DoSet(9);  // The Standard fast 2^128-1 Period
  end;
end;

function TRandom_LFSR.GetState: AnsiString;
var
  CRC: Word;
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
// write randomized Dummy Word
    RndXORBuffer(RndTimeSeed, CRC, SizeOf(CRC));
    M.Write(CRC, SizeOf(CRC));
    M.Write(FSize, SizeOf(FSize));
    M.Write(FRegister, SizeOf(FRegister));
    M.Write(FBasicSeed, SizeOf(FBasicSeed));
    M.Write(FCount, SizeOf(FCount));
    M.Write(FPtr, SizeOf(FPtr));
    M.Write(FLast, SizeOf(FLast));
    CRC := not CRC16($FFFF, M.Memory, M.Size);
    M.Write(CRC, SizeOf(CRC));
    CRC := $0100; // Version 1 without Protection
    if Protection <> nil then
    begin
      CRC := CRC or 1; // with Protection
      M.Position := 0;
      Protection.CodeStream(M, M, M.Size, paEncode);
      M.Position := M.Size;
    end;
    M.Write(CRC, SizeOf(CRC));
    Result := StrToFormat(M.Memory, M.Size, fmtMIME64);
  finally
    M.Free;
  end;
end;

procedure TRandom_LFSR.SetState(Value: AnsiString);
var
  P: Integer;
  CRC: Word;
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    Value := FormatToStr(PAnsiChar(Value), Length(Value), fmtMIME64);
    M.Write(PAnsiChar(Value)^, Length(Value));
    M.Position := M.Size - SizeOf(CRC);
    M.Read(CRC, SizeOf(CRC));
    if CRC and $FF00 <> $0100 then // it's Version $0100 ?
      raise ERandom.Create(sInvalidRandomStream);
    if CRC and 1 <> 0 then
      if Protection <> nil then
      begin
        M.Position := 0;
        Protection.CodeStream(M, M, M.Size - SizeOf(CRC), paDecode);
      end else raise ERandom.Create(sRandomDataProtected);
    M.Position := M.Size - SizeOf(CRC) * 2;
    M.Read(CRC, SizeOf(CRC));
    if CRC <> not CRC16($FFFF, M.Memory, M.Size - SizeOf(CRC) * 2) then
      raise ERandom.Create(sInvalidRandomStream);
    M.Position := SizeOf(CRC); // skip Dummy word
    M.Read(P, SizeOf(FSize));
    SetSize(P);
    M.Read(FRegister, SizeOf(FRegister));
    M.Read(FBasicSeed, SizeOf(FBasicSeed));
    M.Read(FCount, SizeOf(FCount));
    M.Read(FPtr, SizeOf(FPtr));
    M.Read(FLast, SizeOf(FLast));
  finally
    M.Free;
  end;
end;

procedure TRandom_LFSR.Seed(const ABuffer; ASize: Integer);
var
  I,S: Integer;
begin
  FPtr := 0;
  if (ASize > 0) and (@ABuffer <> nil) then
  begin
    FillChar(FRegister, SizeOf(FRegister), 0);
    S := FSize div 8;
    for I := 0 to ASize -1 do
      FRegister[I mod S] := FRegister[I mod S] + TByteArray(ABuffer)[I];
  end else
    if ASize < 0 then RndXORBuffer(RndTimeSeed + (FCount +1), FRegister, SizeOf(FRegister))
      else FillChar(FRegister, SizeOf(FRegister), 0);
  RndXORBuffer(FBasicSeed, FRegister, SizeOf(FRegister));
  if Protection <> nil then
    Protection.CodeBuffer(FRegister, SizeOf(FRegister), paScramble);
end;

procedure TRandom_LFSR.Buffer(var ABuffer; ASize: Integer);
begin
  if ASize <= 0 then Exit;
  FFunc(Self, ABuffer, ASize);
  if Protection <> nil then
    Protection.CodeBuffer(ABuffer, ASize, paScramble);
  Inc(FCount, ASize);
end;

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgRng> initialized');
{$ENDIF}

finalization
  FRND.Release;
end.
