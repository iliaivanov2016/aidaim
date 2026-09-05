unit ESFSDecUtil;

interface

{$I ESFSVer.inc}
{$I Ver.inc}

uses SysUtils, Classes
{$IFDEF D12H}
     ,ESFS_d12h
{$ENDIF}
{$IFDEF LINUX}
     ,ESFSLinux
{$ENDIF}
 {$IFDEF DEBUG_LOG}
     ,ESFSDebug
 {$ENDIF}
     ;

const
// AnsiString Formats
  fmtDEFAULT     =    -1;     // use DefaultStringFormat
  fmtNONE        =     0;     // allways an Empty String, nothing Action
  fmtCOPY        =     1;     // One to One binary (input = output)
  fmtHEX         =    16;     // Hexadecimal
  fmtHEXL        =  1016;     // Hexadecimal lowercase
  fmtMIME64      = $1064;     // MIME Base 64
  fmtUU          = $5555;     // UU Coding  $5555 = 'UU'
  fmtXX          = $5858;     // XX Coding  $5858 = 'XX'

// 2 - 64 reserved for Formats to the Base 2 - 64
// over 1000 all other Formats

type
{$IFNDEF VER_D4H}
  LongWord       = LongInt;
  PLongWord      = ^LongWord;
{$ENDIF}
  PByte          = ^Byte;
  PInteger       = ^LongWord;
  PWord          = ^Word;
  PIntArray      = ^TIntArray;
  TIntArray      = array[0..1023] of LongWord;

  EProtection    = class(Exception);
  EStringFormat  = class(Exception);

// basic Class for all Protection Classes, TCipher, THash, TRandom
// TProtect can build a chain with varios Encryption Algos.
// i.E. CodeBuffer() can en/decode the Buffer with more as one Cipher when
// property Protection is set to a other Cipher :-)
  TPAction  = (paEncode, paDecode, paScramble, paCalc, paWipe);
  TPActions = set of TPAction;

{$IFDEF VER_D3H}
  TProtection = class(TInterfacedObject)
  private
{$ELSE}
  TProtection = class(TObject)
  private
    FRefCount: Integer;
{$ENDIF}
    FProtection: TProtection;
    FActions: TPActions;
    function GetProtection: TProtection;
    procedure SetProtection(Value: TProtection);
  protected
    procedure CodeInit(Action: TPAction); virtual;
    procedure CodeDone(Action: TPAction); virtual;
    procedure CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction); virtual;
  public
    constructor Create(AProtection: TProtection);
    destructor Destroy; override;

    class function Identity: Word;

    function Release: Integer;
    function AddRef: Integer;

    procedure CodeStream(Source, Dest: TStream; DataSize: Integer; Action: TPAction); virtual;
    procedure CodeFile(const Source, Dest: AnsiString; Action: TPAction); virtual;
    function  CodeAnsiString(const Source: AnsiString; Action: TPAction; Format: Integer): AnsiString; virtual;
    function  CodeBuffer(var Buffer; BufferSize: Integer; Action: TPAction): Integer; virtual;
// Protection Object, to cascade more Protection
    property Protection: TProtection read GetProtection write SetProtection;
    property Actions: TPActions read FActions write FActions default [paEncode..paWipe];
{$IFNDEF VER_D3H}
    property RefCount: Integer read FRefCount;
{$ENDIF}
  end;

// AnsiString converting
  
  TStringFormatClass = class of TStringFormat;

  TStringFormat = class(TObject) // for binary one to one convert = fmtCOPY
  public
    class function ToStr(Value: PAnsiChar; Len: Integer): AnsiString; virtual;
    class function StrTo(Value: PAnsiChar; Len: Integer): AnsiString; virtual;
    class function Name: AnsiString; virtual;
    class function Format: Integer; virtual;
    class function IsValid(Value: PAnsiChar; Len: Integer; ToStr: Boolean): Boolean; virtual;
  end;

  TStringFormat_HEX = class(TStringFormat) // Hexadecimal = fmtHEX
  public
    class function ToStr(Value: PAnsiChar; Len: Integer): AnsiString; override;
    class function StrTo(Value: PAnsiChar; Len: Integer): AnsiString; override;
    class function Name: AnsiString; override;
    class function Format: Integer; override;
    class function IsValid(Value: PAnsiChar; Len: Integer; ToStr: Boolean): Boolean; override;
    class function CharTable: PAnsiChar; virtual;
  end;

  TStringFormat_HEXL = class(TStringFormat_HEX) // Hexadecimal lowercase = fmtHEXL
  public
    class function Name: AnsiString; override;
    class function Format: Integer; override;
    class function CharTable: PAnsiChar; override;
  end;

  TStringFormat_MIME64 = class(TStringFormat_HEX)  // MIME Base 64 = fmtMIME64
  public
    class function ToStr(Value: PAnsiChar; Len: Integer): AnsiString; override;
    class function StrTo(Value: PAnsiChar; Len: Integer): AnsiString; override;
    class function Name: AnsiString; override;
    class function Format: Integer; override;
    class function CharTable: PAnsiChar; override;
  end;

  TStringFormat_UU = class(TStringFormat) // UU Encode = fmtUU
  public
    class function ToStr(Value: PAnsiChar; Len: Integer): AnsiString; override;
    class function StrTo(Value: PAnsiChar; Len: Integer): AnsiString; override;
    class function Name: AnsiString; override;
    class function Format: Integer; override;
    class function IsValid(Value: PAnsiChar; Len: Integer; ToStr: Boolean): Boolean; override;
    class function CharTable: PAnsiChar; virtual;
  end;

  TStringFormat_XX = class(TStringFormat_UU) // XX Encode = fmtXX
  public
    class function Name: AnsiString; override;
    class function Format: Integer; override;
    class function CharTable: PAnsiChar; override;
  end;

{Progress (gauge) for Hash and Cipher}
  TProgressEvent = procedure(Sender: TObject; Current, Maximal: Integer) of Object;

{$IFDEF LINUX}
const
  libc = 'libc.so.6';
  function _time(P: Pointer): Integer; cdecl;
    external libc name 'time';
{$ENDIF}

//calculate CRCR16/CRC32 Checksum, CRC is default $FFFFFFFF,
//after calc you must inverse Result with NOT
function CRC16(CRC: Word; Data: Pointer; DataSize: LongWord): Word;
function CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord; register;
// the basicly used TestVector for all Hash/Cipher classes
// used for SelfTest, random Data, don't modify
function GetTestVector: PAnsiChar; register;

// String/Format routines
// convert any AnsiString to Format
function StrToFormat(Value: PAnsiChar; Len, Format: Integer): AnsiString;
// convert any Format to AnsiString
function FormatToStr(Value: PAnsiChar; Len, Format: Integer): AnsiString;
// convert any Format to Format
function ConvertFormat(Value: PAnsiChar; Len, FromFormat, ToFormat: Integer): AnsiString;
// Check is AnsiString convertable to Format
function IsValidAnsiString(Value: PAnsiChar; Len, Format: Integer): Boolean;
// Check is Format an valid Format
function IsValidFormat(Value: PAnsiChar; Len, Format: Integer): Boolean;
// register a new Format
procedure RegisterStringFormats(const StringFormats: array of TStringFormatClass);
// give all registered Formats in Strings
procedure GetStringFormats(Strings: TStrings);
// the Default, = fmtMIME64
function DefaultStringFormat: Integer;
// set the Default
procedure SetDefaultStringFormat(Format: Integer);
// give StringFormatClass from Format
function StringFormat(Format: Integer): TStringFormatClass;
// insert #13#10 Chars in Blocks from BlockSize
function InsertCR(const Value: AnsiString; BlockSize: Integer): AnsiString;
// delete all #13 and #10 Chars
function DeleteCR(const Value: AnsiString): AnsiString;
// format any AnsiString to a Block
function InsertBlocks(const Value, BlockStart, BlockEnd: AnsiString; BlockSize: Integer): AnsiString;
// remove any Block format
function RemoveBlocks(const Value, BlockStart, BlockEnd: AnsiString): AnsiString;
// give back a shorter Name, i.E. THash_MD4 -> "MD4" or TCipher_Blowfish -> "Blowfish"
function GetShortClassName(Value: TClass): AnsiString;

// Result := Value shl Shift or Value shr (32 - Shift)
function ROL(Value: LongWord; Shift: Integer): LongWord;
// Result := ROL(Value, Shift) + Add
function ROLADD(Value, Add: LongWord; Shift: Integer): LongWord;
// Result := ROL(Value, Shift) - Sub
function ROLSUB(Value, Sub: LongWord; Shift: Integer): LongWord;
// Result := Value shr Shift or Value shl (32 - Shift)
function ROR(Value: LongWord; Shift: Integer): LongWord;
// Result := ROR(Value, Shift) + Add
function RORADD(Value, Add: LongWord; Shift: Integer): LongWord;
// Result := ROR(Value, Shift) - Sub
function RORSUB(Value, Sub: LongWord; Shift: Integer): LongWord;
// Reverse the Bitorder from Value
function SwapBits(Value: LongWord): LongWord;
// Index of Least Significant Bit from Value
function LSBit(Value: Integer): Integer;
// Index of Most Significant Bit from Value
function MSBit(Value: Integer): Integer;
// Check iff only One Bit is set and give back the Index
function OneBit(Value: Integer): Integer;
// Compare Memory, D2 have no CompareMem, Result can be -1, 0, 1
function MemCompare(P1, P2: Pointer; Size: Integer): Integer;
// XOR's Buffers I1 and I2 Size Bytes to Dest
procedure XORBuffers(I1, I2: Pointer; Size: Integer; Dest: Pointer);
// Processor Type
//function CPUType: Integer; {3 = 386, 4 = 486, 5 = Pentium, 6 > Pentium i.E. PII}
// call a installed Progress Event
procedure DoProgress(Sender: TObject; Current, Maximal: Integer);
// saver Test
function IsObject(AObject: Pointer; AClass: TClass): Boolean;
// Time Seed produced from GetSystemTime and QueryPerformanceCounter
function RndTimeSeed: Integer;
// XOR Buffer Size Bytes with Seed Randoms,
// the initial State from Buffer have effect on the Output
function RndXORBuffer(Seed: Integer; var Buffer; Size: Integer): Integer;
// encapsulate QueryPerformanceCounter/Frequency
function PerfCounter: Comp;
function PerfFreq: Comp;

const
  InitTestIsOk        : Boolean  = True;
  IdentityBase        : Word     = $1234;

{this is set to SwapInt for <= 386 and BSwapInt >= 486 CPU, don't modify}
  SwapInteger       : function(Value: LongWord): LongWord; register  = nil;
{Count of Integers Buffer}
  SwapIntegerBuffer : procedure(Source, Dest: Pointer; Count: Integer); register = nil;
{Progress callback function, set this to your Progresscallback}
  Progress: TProgressEvent = nil;


const //!!
  ReversedBits : array[0..255] of byte = (
      $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0,
      $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8,
      $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4,
      $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC,
      $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2,
      $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA,
      $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6,
      $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE,
      $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1,
      $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9,
      $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5,
      $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD,
      $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3,
      $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB,
      $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7,
      $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF
    );

implementation

uses
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
     ESFSDecConst;

const
  FStrFMTs : TList = nil;         // registered Stringformats
  FStrFMT  : Integer = fmtMIME64; // Default Stringformat

function PerfCounter: Comp;
{$IFDEF D12H}
var temp64: Int64;
    b:      Boolean;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
 {$IFDEF D12H}
  b := QueryPerformanceCounter(temp64);
  if b then
   Result := temp64
  else
 {$ELSE}
   {$IFDEF VER_D4H}
    if not QueryPerformanceCounter(TULargeInteger(Result).QuadPart) then
   {$ELSE}
    if not QueryPerformanceCounter(TLargeInteger(Result)) then
   {$ENDIF}
 {$ENDIF}
{$ENDIF}
    Result := GetTickCount;
end;

function PerfFreq: Comp;
{$IFDEF D12H}
var temp64: Int64;
    b:      Boolean;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
 {$IFDEF D12H}
  b := QueryPerformanceFrequency(temp64);
  if b then
   Result := temp64
  else
 {$ELSE}
  {$IFDEF VER_D4H}
   if not QueryPerformanceFrequency(TULargeInteger(Result).QuadPart) then
  {$ELSE}
   if not QueryPerformanceFrequency(TLargeInteger(Result)) then
  {$ENDIF}
 {$ENDIF}
{$ENDIF}
    Result := 1000;
end;


function DefaultStringFormat: Integer;
begin
  Result := FStrFMT;
end;

procedure SetDefaultStringFormat(Format: Integer);
begin
  if (Format = fmtDEFAULT) or (StringFormat(Format) = nil) then FStrFMT := fmtMIME64
    else FStrFMT := Format;
end;

// TProtection Class
function TProtection.GetProtection: TProtection;
begin
  if (FProtection <> nil) and not IsObject(FProtection, TProtection) then FProtection := nil;
  Result := FProtection;
end;

procedure TProtection.SetProtection(Value: TProtection);

  function CheckProtection(P: TProtection): Boolean;
  begin
    Result := True;
    if IsObject(P, TProtection) then
      if P = Self then Result := False
        else Result := CheckProtection(P.FProtection)
  end;

begin
  if Value <> FProtection then
    if CheckProtection(Value) then
    begin
      FProtection.Release;
      FProtection := Value;
      FProtection.AddRef;
    end else raise EProtection.Create(sProtectionCircular)
end;

procedure TProtection.CodeInit(Action: TPAction);
begin
  if Protection <> nil then Protection.CodeInit(Action);
end;

procedure TProtection.CodeDone(Action: TPAction);
begin
  if Protection <> nil then Protection.CodeDone(Action);
end;

procedure TProtection.CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction);
begin
  if Protection <> nil then Protection.CodeBuf(Buffer, BufferSize, Action);
end;

function TProtection.Release: Integer;
begin
  if IsObject(Self, TProtection) then
  begin
{$IFDEF VER_D3H}
    Result := IUnknown(Self)._Release;
{$ELSE}
    Dec(FRefCount);
    Result := FRefCount;
    if FRefCount = 0 then Destroy;
{$ENDIF}
  end else Result := 0;
end;

function TProtection.AddRef: Integer;
begin
  if IsObject(Self, TProtection) then
  begin
{$IFDEF VER_D3H}
    Result := IUnknown(Self)._AddRef;
{$ELSE}
    Inc(FRefCount);
    Result := FRefCount;
{$ENDIF}
  end else Result := 0;
end;

procedure TProtection.CodeStream(Source, Dest: TStream; DataSize: Integer; Action: TPAction);
const
  maxBufSize = 1024 * 4;
var
  Buf: PAnsiChar;
  SPos: Integer;
  DPos: Integer;
  Len: Integer;
  Size: Integer;
begin
  if Source = nil then Exit;
  if Dest = nil then Dest := Source;
  if DataSize < 0 then
  begin
    DataSize := Source.Size;
    Source.Position := 0;
  end;
  CodeInit(Action);
  Buf := nil;
  Size := DataSize;
  DoProgress(Self, 0, Size);
  try
    Buf    := AllocMem(maxBufSize);
    DPos   := Dest.Position;
    SPos   := Source.Position;
    if Action = paCalc then
    begin
      while DataSize > 0 do
      begin
        Len := DataSize;
        if Len > maxBufSize then Len := maxBufSize;
        Len := Source.Read(Buf^, Len);
        if Len <= 0 then Break;
        CodeBuf(Buf^, Len, paCalc);
        Dec(DataSize, Len);
        DoProgress(Self, Size - DataSize, Size);
      end;
    end else
    begin
      while DataSize > 0 do
      begin
        Source.Position := SPos;
        Len := DataSize;
        if Len > maxBufSize then Len := maxBufSize;
        Len := Source.Read(Buf^, Len);
        SPos := Source.Position;
        if Len <= 0 then Break;
        CodeBuf(Buf^, Len, Action);
        Dest.Position := DPos;
        Dest.Write(Buf^, Len);
        DPos := Dest.Position;
        Dec(DataSize, Len);
        DoProgress(Self, Size - DataSize, Size);
      end;
    end;
  finally
    DoProgress(Self, 0, 0);
    ReallocMem(Buf, 0);
    CodeDone(Action);
  end;
end;

procedure TProtection.CodeFile(const Source, Dest: AnsiString; Action: TPAction);
var
  S,D: TFileStream;
begin
  S := nil;
  D := nil;
  try
    if (AnsiCompareText(Source, Dest) <> 0) and ((Trim(Dest) <> '') or (Action = paCalc)) then
    begin
      S := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
      if Action = paCalc then D := S
        else D := TFileStream.Create(Dest, fmCreate);
    end else
    begin
      S := TFileStream.Create(Source, fmOpenReadWrite);
      D := S;
    end;
    CodeStream(S, D, S.Size, Action);
  finally
    S.Free;
    if S <> D then
    begin
{$IFDEF VER_D3H}
      D.Size := D.Position;
{$ENDIF}
      D.Free;
    end;
  end;
end;

function TProtection.CodeBuffer(var Buffer; BufferSize: Integer; Action: TPAction): Integer;
begin
  Result := BufferSize;
  CodeInit(Action);
  try
    CodeBuf(Buffer, BufferSize, Action);
  finally
    CodeDone(Action);
  end;
end;

function TProtection.CodeAnsiString(const Source: AnsiString; Action: TPAction; Format: Integer): AnsiString;
var
  M: TMemoryStream;
begin
  Result := '';
  if Length(Source) <= 0 then Exit;
  M := TMemoryStream.Create;
  try
    if Action <> paDecode then Result := Source
      else Result := FormatToStr(PAnsiChar(Source), Length(Source), Format);
    M.Write(PAnsiChar(Result)^, Length(Result));
    M.Position := 0;
    CodeStream(M, M, M.Size, Action);
    if Action = paDecode then
    begin
      SetLength(Result, M.Size);
      Move(M.Memory^, PAnsiChar(Result)^, M.Size);
    end else
      Result := StrToFormat(M.Memory, M.Size, Format);
  finally
    M.Free;
  end;
end;

constructor TProtection.Create(AProtection: TProtection);
begin
  inherited Create;
  Protection := AProtection;
  FActions := [paEncode..paWipe];
end;

destructor TProtection.Destroy;
begin
  Protection := nil;
  inherited Destroy;
end;

class function TProtection.Identity: Word;
var
  S: AnsiString;
begin
  S := ClassName;
  Result := not CRC16(IdentityBase, PAnsiChar(S), Length(S));
end;

class function TStringFormat.ToStr(Value: PAnsiChar; Len: Integer): AnsiString;
begin
  SetLength(Result, Len);
  Move(Value^, PAnsiChar(Result)^, Len);
end;

class function TStringFormat.StrTo(Value: PAnsiChar; Len: Integer): AnsiString;
begin
  SetLength(Result, Len);
  Move(Value^, PAnsiChar(Result)^, Len);
end;

class function TStringFormat.Name: AnsiString;
begin
  if Self = TStringFormat then Result := sFMT_COPY
    else Result := GetShortClassName(Self);
end;

class function TStringFormat.Format: Integer;
begin
  Result := fmtCOPY;
end;

class function TStringFormat.IsValid(Value: PAnsiChar; Len: Integer; ToStr: Boolean): Boolean;
begin
  Result := True;
end;

function TableFind(Value: AnsiChar; Table: PAnsiChar; Len: Integer): Integer;
begin // Utility for TStringFormat_XXXXX
  for Result := 0 to Len do
    if Table[Result] = Value
      then exit;
  Result := -1;
end;

class function TStringFormat_HEX.ToStr(Value: PAnsiChar; Len: Integer): AnsiString;
var
  D: PByte;
  T: PAnsiChar;
  I,P: Integer;
  HasIdent: Boolean;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len = 0 then Exit;
  SetLength(Result, Len div 2 +1);
  T := CharTable;
  D := PByte(Result);
  I := 0;
  HasIdent := False;
  while Len > 0 do
  begin

    // bug fix for lower hex by AidAim Software
    if (Format = fmtHEX) then
     P := TableFind(UpCase(Value^), T, 18)
    else
     P := TableFind(Value^, T, 18);
    // bug fix for lower hex by AidAim Software

    Inc(Value);
    if P >= 0 then
      if P > 16 then
      begin
        if not HasIdent then
        begin
          HasIdent := True;
          I := 0;
          D := PByte(Result);
        end;
      end else
      begin
        if Odd(I) then
        begin
          D^ := D^ or P;
          Inc(D);
        end else D^ := P shl 4;
        Inc(I);
      end;
    Dec(Len);
  end;
  SetLength(Result, PAnsiChar(D) - PAnsiChar(Result));
end;

class function TStringFormat_HEX.StrTo(Value: PAnsiChar; Len: Integer): AnsiString;
var
  D,T: PAnsiChar;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len = 0 then Exit;
  SetLength(Result, Len * 2);
  T := CharTable;
  D := PAnsiChar(Result);
  while Len > 0 do
  begin
    D[0] := T[Byte(Value^) shr  4];
    D[1] := T[Byte(Value^) and $F];
    Inc(D, 2);
    Inc(Value);
    Dec(Len);
  end;
end;

class function TStringFormat_HEX.IsValid(Value: PAnsiChar; Len: Integer; ToStr: Boolean): Boolean;
var
  T: PAnsiChar;
  L: Integer;
begin
  Result := not ToStr;
  if not Result then
  begin
    T := CharTable;
    L := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}T);
    while Len > 0 do
      if TableFind(Value^, T, L) >= 0 then
      begin
        Dec(Len);
        Inc(Value);
      end else Exit;
  end;
  Result := True;
end;

class function TStringFormat_HEX.Name: AnsiString;
begin
  Result := sFMT_HEX;
end;

class function TStringFormat_HEX.Format: Integer;
begin
  Result := fmtHEX;
end;

const
  TStringFormat_HEX_CharTable : PAnsiChar = '0123456789ABCDEFX$ abcdefhHx()[]{},;:-_/\*+"'''#9#10#13#0;

class function TStringFormat_HEX.CharTable: PAnsiChar; 
begin
  Result := TStringFormat_HEX_CharTable;
end;

class function TStringFormat_HEXL.Name: AnsiString;
begin
  Result := sFMT_HEXL;
end;

class function TStringFormat_HEXL.Format: Integer;
begin
  Result := fmtHEXL;
end;

const
  TStringFormat_HEXL_CharTable : PAnsiChar = '0123456789abcdefX$ ABCDEFhHx()[]{},;:-_/\*+"'''#9#10#13#0;

class function TStringFormat_HEXL.CharTable: PAnsiChar;
begin
  Result := TStringFormat_HEXL_CharTable;
end;

class function TStringFormat_MIME64.ToStr(Value: PAnsiChar; Len: Integer): AnsiString;
var
  B: Cardinal;
  J,I: Integer;
  S,D,L,T: PAnsiChar;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := Length(Value);
  if Len = 0 then Exit;
  SetLength(Result, Len);
  Move(PAnsiChar(Value)^, PAnsiChar(Result)^, Len);
  T := CharTable;
  while Len mod 4 <> 0 do
  begin
    Result := Result + T[64];
    Inc(Len);
  end;
  D := PAnsiChar(Result);
  S := D;
  L := S + Len;
  Len := Len * 3 div 4;
  while Len > 0 do
  begin
    B := 0;
    J := 4;
    while (J > 0) and (S <= L) do
    begin
      I := TableFind(S^, T, 65);
      if I >= 0 then
      begin
        B := B shl 6;
        if I >= 64 then Dec(Len) else B := B or Byte(I);
        Dec(J);
      end;
      Inc(S);
    end;
    J := 2;
    repeat
      D[J] := AnsiChar(B);
      B := B shr 8;
      Dec(J);
    until J < 0;
    if Len > 3 then Inc(D, 3) else Inc(D, Len);
    Dec(Len, 3);
  end;
  SetLength(Result, D - PAnsiChar(Result));
end;

class function TStringFormat_MIME64.StrTo(Value: PAnsiChar; Len: Integer): AnsiString;
var
  B: Cardinal;
  I: Integer;
  D,T: PAnsiChar;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len = 0 then Exit;
  SetLength(Result, Len * 4 div 3 + 4);
  D := PAnsiChar(Result);
  T := CharTable;
  while Len > 0 do
  begin
    B := 0;
    for I := 0 to 2 do
    begin
      B := B shl 8;
      if Len > 0 then
      begin
        B := B or Byte(Value^);
        Inc(Value);
      end;
      Dec(Len);
    end;
    for I := 3 downto 0 do
    begin
      if Len < 0 then
      begin
        D[I] := T[64];
        Inc(Len);
      end else D[I] := T[B and $3F];
      B := B shr 6;
    end;
    Inc(D, 4);
  end;
  SetLength(Result, D - PAnsiChar(Result));
end;

class function TStringFormat_MIME64.Name: AnsiString;
begin
  Result := sFMT_MIME64;
end;

class function TStringFormat_MIME64.Format: Integer;
begin
  Result := fmtMIME64;
end;

const
  TStringFormat_MIME64_CharTable : PAnsiChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/= $()[]{},;:-_\*"'''#9#10#13#0;

class function TStringFormat_MIME64.CharTable: PAnsiChar; 
begin
  Result := TStringFormat_MIME64_CharTable;
end;

class function TStringFormat_UU.ToStr(Value: PAnsiChar; Len: Integer): AnsiString;
var 
  T,D,L: PAnsiChar;
  I,E: Integer; 
  B: Cardinal; 
begin 
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value); 
  if Len = 0 then Exit;
  SetLength(Result, Len);
  L := Value + Len;
  D := PAnsiChar(Result); 
  T := CharTable; 
  repeat
    Len := TableFind(Value^, T, 64); 
    if (Len < 0) or (Len > 45) then
      raise EStringFormat.CreateFMT(sInvalidStringFormat, [Name]);
    Inc(Value); 
    while Len > 0 do
    begin
      B := 0;
      I := 4; 
      while (I > 0) and (Value <= L) do
      begin
        E := TableFind(Value^, T, 64);
        if E >= 0 then 
        begin 
          B := B shl 6 or Byte(E);
          Dec(I); 
        end; 
        Inc(Value);
      end;
      I := 2;
      repeat
        D[I] := AnsiChar(B);
        B    := B shr 8; 
        Dec(I);
      until I < 0;
      if Len > 3 then Inc(D, 3) else Inc(D, Len); 
      Dec(Len, 3);
    end; 
  until Value >= L; 
  SetLength(Result, D - PAnsiChar(Result));
end;
	
class function TStringFormat_UU.StrTo(Value: PAnsiChar; Len: Integer): AnsiString; 
var 
  T,D: PAnsiChar; 
  L,I: Integer; 
  B: Cardinal; 
begin 
  Result := ''; 
  if Value = nil then Exit; 
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value); 
  if Len = 0 then Exit; 
  SetLength(Result, Len * 4 div 3 + Len div 45 + 10); 
  D := PAnsiChar(Result);
  T := CharTable;
  while Len > 0 do
  begin 
    L := Len;
    if L > 45 then L := 45; 
    Dec(Len, L);
    D^ := T[L]; 
    while L > 0 do 
    begin 
      B := 0; 
      for I := 0 to 2 do 
      begin 
        B := B shl 8;
        if L > 0 then 
        begin 
          B := B or Byte(Value^);
          Inc(Value); 
        end;
        Dec(L); 
      end; 
      for I := 4 downto 1 do
      begin
        D[I] := T[B and $3F];
        B := B shr 6; 
      end;
      Inc(D, 4);
    end; 
    Inc(D); 
  end;
  SetLength(Result, D - PAnsiChar(Result));
end; 

class function TStringFormat_UU.Name: AnsiString; 
begin 
  Result := sFMT_UU;
end; 
	
class function TStringFormat_UU.Format: Integer;
begin 
  Result := fmtUU; 
end;
 
class function TStringFormat_UU.IsValid(Value: PAnsiChar; Len: Integer; ToStr: Boolean): Boolean;
var 
  T: PAnsiChar; 
  L,I,P: Integer;
begin
  Result := not ToStr;
  if not Result then
  begin
    T := CharTable;
    L := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}T);
    P := 0; 
    while Len > 0 do
    begin 
      I := TableFind(Value^, T, L);
      if I >= 0 then
      begin
        Dec(Len); 
        Inc(Value);
        if P = 0 then 
        begin
          if I > 45 then Exit;
          P := (I * 4 + 2) div 3;
        end else
          if I < 64 then Dec(P);
      end else Exit;
    end;
    if P <> 0 then Exit;
  end;
  Result := True;
end;

const
  TStringFormat_UU_CharTable : PAnsiChar = '`!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_ '#9#10#13#0;

class function TStringFormat_UU.CharTable: PAnsiChar;
begin
  Result := TStringFormat_UU_CharTable;
end;

class function TStringFormat_XX.Name: AnsiString;
begin
  Result := sFMT_XX;
end;

class function TStringFormat_XX.Format: Integer;
begin
  Result := fmtXX;
end;

const
  TStringFormat_XX_CharTable : PAnsiChar = '+-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz "()[]'''#9#10#13#0;

class function TStringFormat_XX.CharTable: PAnsiChar;
begin
  Result := TStringFormat_XX_CharTable;
end;

function IsObject(AObject: Pointer; AClass: TClass): Boolean;
var
  E: Pointer;
begin
  Result := False;
  if AObject = nil then Exit;
  E := ExceptionClass;
  ExceptionClass := nil;
  try
    if TObject(AObject) is AClass then Result := True;
  except
  end;
  ExceptionClass := E;
end;

function ROL(Value: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shl Shift ) or ( Value shr (32 - Shift) )
end;

function ROLADD(Value, Add: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shl Shift ) or ( Value shr (32 - Shift) ) + Add;
end;

function ROLSUB(Value, Sub: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shl Shift ) or ( Value shr (32 - Shift) ) - Sub;
end;

function ROR(Value: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shr Shift ) or ( Value shl (32 - Shift) );
end;

function RORADD(Value, Add: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shr Shift ) or ( Value shl (32 - Shift) ) + Add;
end;

function RORSUB(Value, Sub: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shr Shift ) or ( Value shl (32 - Shift) ) - Sub;
end;

{swap 4 Bytes Intel, Little/Big Endian Conversion}
function SwapInt(Value: LongWord): LongWord;
begin
  Result := ( ( Value and $FF000000 ) shr 24) or
            ( ( Value and $FF0000   ) shr  8) or
            ( ( Value and $FF00     ) shl  8) or
            ( ( Value and $FF       ) shl 24);
end;

procedure SwapIntBuf(Source,Dest: Pointer; Count: Integer);
var
  wSource : PByteArray absolute Source;
  wDest   : PByteArray absolute Dest;
  i : integer;
begin
  for i := 0 to Count - 1 do
    wDest[Count - i] := wSource[i];
end;

{reverse the bit order from a integer}
type
  TLongAsBytes = packed record
      b0, b1, b2, b3 : byte;
    end;

function SwapBits(Value: LongWord): LongWord;
var
  wValue  : TLongAsBytes absolute Value;
  wResult : TLongAsBytes absolute Result;
begin
  assert( sizeof( wValue ) = sizeof( Value ), '!!?' );

  wResult.b0 := ReversedBits[ wValue.b3 ];
  wResult.b1 := ReversedBits[ wValue.b2 ];
  wResult.b2 := ReversedBits[ wValue.b1 ];
  wResult.b3 := ReversedBits[ wValue.b0 ];
end;
//asm
//       BSWAP  EAX
//       MOV    EDX,EAX
//       AND    EAX,0AAAAAAAAh
//       SHR    EAX,1
//       AND    EDX,055555555h
//       SHL    EDX,1
//       OR     EAX,EDX
//       MOV    EDX,EAX
//       AND    EAX,0CCCCCCCCh
//       SHR    EAX,2
//       AND    EDX,033333333h
//       SHL    EDX,2
//       OR     EAX,EDX
//       MOV    EDX,EAX
//       AND    EAX,0F0F0F0F0h
//       SHR    EAX,4
//       AND    EDX,00F0F0F0Fh
//       SHL    EDX,4
//       OR     EAX,EDX
//end;

function LSBit(Value: Integer): Integer;
begin
  for Result := 0 to 31 do
    if Value and ( 1 shl Result ) <> 0
      then exit;
end;

function MSBit(Value: Integer): Integer;
begin
  for Result := 31 downto 0 do
    if Value and ( 1 shl Result ) <> 0
      then exit;
end;

function OneBit(Value: Integer): Integer;
var
  wLeft  : integer;
  wRight : integer;
begin
  for wLeft := 0 to 31 do
    if Value and ( 1 shl wLeft ) <> 0
      then break;
  for wRight := 31 downto wLeft do
    if Value and ( 1 shl wRight ) <> 0
      then break;
  if wLeft <> wRight
    then Result := 0
    else Result := wLeft;
end;
//asm
//       MOV   ECX,EAX
//       MOV   EDX,EAX
//       BSF   EDX,EDX
//       JZ    @@1
//       BSR   ECX,ECX
//       CMP   ECX,EDX
//       JNE   @@1
//       MOV   EAX,EDX
//       RET
//@@1:   XOR   EAX,EAX
//end;

function MemCompare(P1, P2: Pointer; Size: Integer): Integer;
var
  wP1 : PByteArray absolute P1;
  wP2 : PByteArray absolute P2;
  i : integer;
begin
  for i := 0 to Size - 1 do
    begin
      Result := wP1[i] - wP2[i];
      if Result <> 0
        then exit;
    end;
end;
//asm
//       PUSH    ESI
//       PUSH    EDI
//       MOV     ESI,P1
//       MOV     EDI,P2
//       XOR     EAX,EAX
//       REPE    CMPSB
//       JE      @@1
//       MOVZX   EAX,BYTE PTR [ESI-1]
//       MOVZX   EDX,BYTE PTR [EDI-1]
//       SUB     EAX,EDX
//@@1:   POP     EDI
//       POP     ESI
//end;

procedure XORBuffers(I1, I2: Pointer; Size: Integer; Dest: Pointer);
var
  wDest : PByteArray absolute Dest;
  wI1   : PByteArray absolute I1;
  wI2   : PByteArray absolute I2;
  i     : integer;
begin
  for i := 0 to Size - 1 do
    wDest[i] := wI1[i] xor wI2[i];
end;
//asm
//       AND   ECX,ECX
//       JZ    @@5
//       PUSH  ESI
//       PUSH  EDI
//       MOV   ESI,EAX
//       MOV   EDI,Dest
//@@1:   TEST  ECX,3
//       JNZ   @@3
//@@2:   SUB   ECX,4
//       JL    @@4
//       MOV   EAX,[ESI + ECX]
//       XOR   EAX,[EDX + ECX]
//       MOV   [EDI + ECX],EAX
//       JMP   @@2
//@@3:   DEC   ECX
//       MOV   AL,[ESI + ECX]
//       XOR   AL,[EDX + ECX]
//       MOV   [EDI + ECX],AL
//       JMP   @@1
//@@4:   POP   EDI
//       POP   ESI
//@@5:
//end;

procedure DoProgress(Sender: TObject; Current, Maximal: Integer);
begin
{saver access}
  if (TMethod(Progress).Code <> nil) and
     ((TMethod(Progress).Data = nil) or
       IsObject(TMethod(Progress).Data, TObject)) then
    Progress(Sender, Current, Maximal);
end;

function StringFormat(Format: Integer): TStringFormatClass;
var
  I: Integer;
begin
  if Format = fmtDefault then Format := DefaultStringFormat;
  Result := nil;
  if FStrFmts <> nil then
    for I := 0 to FStrFMTs.Count-1 do
      if TStringFormatClass(FStrFmts[I]).Format = Format then
      begin
        Result := FStrFMTS[I];
        Exit;
      end;
end;

function StrToFormat(Value: PAnsiChar; Len, Format: Integer): AnsiString;
var
  Fmt: TStringFormatClass;
begin
  Result := '';
  if (Value = nil) or (Format = fmtNONE) then Exit;
  if Len <  0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len <= 0 then Exit;
  Fmt := StringFormat(Format);
  if Fmt <> nil then
    if Fmt.IsValid(Value, Len, False) then Result := Fmt.StrTo(Value, Len)
      else raise EStringFormat.CreateFMT(sInvalidFormatString, [FMT.Name])
    else raise EStringFormat.CreateFMT(sStringFormatExists, [Format]);
end;

function FormatToStr(Value: PAnsiChar; Len, Format: Integer): AnsiString;
var
  Fmt: TStringFormatClass;
begin
  Result := '';
  if (Value = nil) or (Format = fmtNONE) then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len = 0 then Exit;
  Fmt := StringFormat(Format);
  if Fmt <> nil then
    if Fmt.IsValid(Value, Len, True) then Result := Fmt.ToStr(Value, Len)
      else raise EStringFormat.CreateFMT(sInvalidStringFormat, [FMT.Name])
    else raise EStringFormat.CreateFMT(sStringFormatExists, [Format]);
end;

function ConvertFormat(Value: PAnsiChar; Len, FromFormat, ToFormat: Integer): AnsiString;
begin
  Result := '';
  if (FromFormat = fmtNONE) or (ToFormat = fmtNONE) then Exit;
  if FromFormat <> ToFormat then
  begin
    Result := FormatToStr(Value, Len, FromFormat);
    Result := StrToFormat(PAnsiChar(Result), Length(Result), ToFormat);
  end else
  begin
    if Value = nil then Exit;
    if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
    if Len = 0 then Exit;
    SetLength(Result, Len);
    Move(Value^, PAnsiChar(Result)^, Len);
  end;
end;

function IsValidFormat(Value: PAnsiChar; Len, Format: Integer): Boolean;
var
  Fmt: TStringFormatClass;
begin
  Result := True;
  if Value = nil then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len = 0 then Exit;
  Fmt := StringFormat(Format);
  if Fmt = nil then Result := False
    else Result := Fmt.IsValid(Value, Len, True);
end;

function IsValidAnsiString(Value: PAnsiChar; Len, Format: Integer): Boolean;
var
  Fmt: TStringFormatClass;
begin
  Result := True;
  if Value = nil then Exit;
  if Len < 0 then Len := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Value);
  if Len = 0 then Exit;
  Fmt := StringFormat(Format);
  if Fmt = nil then Result := False
    else Result := Fmt.IsValid(Value, Len, False);
end;

procedure RegisterStringFormats(const StringFormats: array of TStringFormatClass);
var
  I,J: Integer;
  FMT: TStringFormatClass;
begin
  if FStrFMTs = nil then FStrFMTs := TList.Create;
  for I := Low(StringFormats) to High(StringFormats) do
    if (StringFormats[I] <> nil) and
       (StringFormats[I].Format <> fmtDEFAULT) then
    begin
      FMT := StringFormat(StringFormats[I].Format);
      if FMT <> nil then
      begin
        J := FStrFMTs.IndexOf(FMT);
        FStrFMTs[J] := StringFormats[I];
      end else FStrFMTs.Add(StringFormats[I]);
    end;
end;

procedure GetStringFormats(Strings: TStrings);
var
  I: Integer;
begin
  if IsObject(Strings, TStrings) and (FStrFMTs <> nil) then
    for I := 0 to FStrFMTs.Count-1 do
      Strings.AddObject(TStringFormatClass(FStrFMTs[I]).Name, FStrFMTs[I]);
end;

function InsertCR(const Value: AnsiString; BlockSize: Integer): AnsiString;
var
  I: Integer;
  S,D: PAnsiChar;
begin
  if (BlockSize <= 0) or (Length(Value) <= BlockSize) then
  begin
    Result := Value;
    Exit;
  end;
  I := Length(Value);
  SetLength(Result, I + I * 2 div BlockSize + 2);
  S := PAnsiChar(Value);
  D := PAnsiChar(Result);
  repeat
    Move(S^, D^, BlockSize);
    Inc(S, BlockSize);
    Inc(D, BlockSize);
    D^ := #13; Inc(D);
    D^ := #10; Inc(D);
    Dec(I, BlockSize);
  until I < BlockSize;
  Move(S^, D^, I);
  Inc(D, I);
  SetLength(Result, D - PAnsiChar(Result));
end;

function DeleteCR(const Value: AnsiString): AnsiString;
var
  S,D: PAnsiChar;
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  D := PAnsiChar(Result);
  S := PAnsiChar(Value);
  while I > 0 do
  begin
    if (S^ <> #10) and (S^ <> #13) then
    begin
      D^ := S^;
      Inc(D);
    end;
    Inc(S);
    Dec(I);
  end;
  SetLength(Result, D - PAnsiChar(Result));
end;

function InsertBlocks(const Value, BlockStart, BlockEnd: AnsiString; BlockSize: Integer): AnsiString;
var
  I,LS,LE: Integer;
  D,S: PAnsiChar;
begin
  if (BlockSize <= 0) or (Length(Value) <= BlockSize) then
  begin
    Result := Value;
    Exit;
  end;
  I := Length(Value);
  LS := Length(BlockStart);
  LE := Length(BlockEnd);
  SetLength(Result, I + (I div BlockSize + 1) * (LS + LE));
  S := PAnsiChar(Value);
  D := PAnsiChar(Result);
  repeat
    Move(PAnsiChar(BlockStart)^, D^, LS); Inc(D, LS);
    Move(S^, D^, BlockSize);          Inc(D, BlockSize);
    Move(PAnsiChar(BlockEnd)^, D^, LE);   Inc(D, LE);
    Dec(I, BlockSize);
    Inc(S, BlockSize);
  until I < BlockSize;
  if I > 0 then
  begin
    Move(PAnsiChar(BlockStart)^, D^, LS); Inc(D, LS);
    Move(S^, D^, I);                  Inc(D, I);
    Move(PAnsiChar(BlockEnd)^, D^, LE);   Inc(D, LE);
  end;
  SetLength(Result, D - PAnsiChar(Result));
end;

function RemoveBlocks(const Value, BlockStart, BlockEnd: AnsiString): AnsiString;
var
  LS,LE: Integer;
  S,D,L,K: PAnsiChar;
begin
  SetLength(Result, Length(Value));
  LS := Length(BlockStart);
  LE := Length(BlockEnd);
  D := PAnsiChar(Result);
  S := PAnsiChar(Value);
  L := S + Length(Value);

  repeat
    if S > L then Break;
    if LS > 0 then
    begin
      S := StrPos(S, PAnsiChar(BlockStart));
      if S = nil then Break;
      Inc(S, LS);
      if S > L then Break;
    end;
    K := StrPos(S, PAnsiChar(BlockEnd));
    if K = nil then K := L;
    Move(S^, D^, K - S);
    Inc(D, K - S);
    S := K + LE;
  until S >= L;
  SetLength(Result, D - PAnsiChar(Result));
end;

function GetShortClassName(Value: TClass): AnsiString;
var
  I: Integer;
begin
  Result := '';
  if Value = nil then Exit;
  Result := Value.ClassName;
  I := Pos('_', Result);
  if I > 0 then Delete(Result, 1, I);
end;

function RndXORBuffer(Seed: Integer; var Buffer; Size: Integer): integer;
var
  wBuffer : TByteArray absolute Buffer;
  i       : integer;
begin
  if ( @Buffer <> nil ) and ( Size > 0 )
    then
      begin
        for i := 0 to Size - 1 do
          begin
            Seed       := ( ( Seed xor integer( wBuffer[i] ) ) * 134775813 ) + 1;
            wBuffer[i] := Seed shr 24;
          end;
      end
    else Result := Seed;
end;
//asm
//      AND     EDX,EDX
//      JZ      @@2
//      AND     ECX,ECX
//      JLE     @@2
//      PUSH    EBX
//@@1:  XOR     AL,[EDX]
//      IMUL    EAX,EAX,134775813
//      INC     EAX
//      MOV     EBX,EAX
//      SHR     EBX,24
//      MOV     [EDX],BL
//      INC     EDX
//      DEC     ECX
//      JNZ     @@1
//      POP     EBX
//@@2:
//end;

{$IFDEF LINUX}
function RndTimeSeed: Integer;
begin
  Result := _time(nil);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
// use Systemtime and XOR's with PerformanceCounter
function RndTimeSeed: Integer; 
var
  wSysTime : _SYSTEMTIME;
  SysTime : record
               Year: Word;
               Month: Word;
               DayOfWeek: Word;
               Day: Word;
               Hour: Word;
               Minute: Word;
               Second: Word;
               MilliSeconds: Word;
               Reserved: array [0..7] of Byte;
             end absolute wSysTime;
var
  wCounter : int64;
  Counter: record
             Lo,Hi: Integer;
           end absolute wCounter;
begin
  GetSystemTime( wSysTime );
  QueryPerformanceCounter( wCounter );

  Result := SysTime.MilliSeconds + 1000 * ( SysTime.Second + 60 * ( SysTime.Minute + 60 * SysTime.Hour )  );
  Result := Result xor Counter.Lo xor Counter.Hi;
end;
//asm
//      LEA     EAX,SysTime
//      PUSH    EAX
//      CALL    GetSystemTime
//      MOVZX   EAX,Word Ptr SysTime.Hour
//      IMUL    EAX,60
//      ADD     AX,SysTime.Minute
//      IMUL    EAX,60
//      MOVZX   EDX,Word Ptr SysTime.Second
//      ADD     EAX,EDX
//      IMUL    EAX,1000
//      MOV     DX,SysTime.MilliSeconds
//      ADD     EAX,EDX
//      PUSH    EAX
//      LEA     EAX,Counter
//      PUSH    EAX
//      CALL    QueryPerformanceCounter
//      POP     EAX
//      XOR     EAX,Counter.Lo
//      XOR     EAX,Counter.Hi
//end;
{$ENDIF}

const
  CRC16_Table: array[0..255] of word = (
    $00000,$0C0C1,$0C181,$00140,$0C301,$003C0,$00280,$0C241,$0C601,$006C0,$00780,$0C741,$00500,$0C5C1,$0C481,$00440,
    $0CC01,$00CC0,$00D80,$0CD41,$00F00,$0CFC1,$0CE81,$00E40,$00A00,$0CAC1,$0CB81,$00B40,$0C901,$009C0,$00880,$0C841,
    $0D801,$018C0,$01980,$0D941,$01B00,$0DBC1,$0DA81,$01A40,$01E00,$0DEC1,$0DF81,$01F40,$0DD01,$01DC0,$01C80,$0DC41,
    $01400,$0D4C1,$0D581,$01540,$0D701,$017C0,$01680,$0D641,$0D201,$012C0,$01380,$0D341,$01100,$0D1C1,$0D081,$01040,
    $0F001,$030C0,$03180,$0F141,$03300,$0F3C1,$0F281,$03240,$03600,$0F6C1,$0F781,$03740,$0F501,$035C0,$03480,$0F441,
    $03C00,$0FCC1,$0FD81,$03D40,$0FF01,$03FC0,$03E80,$0FE41,$0FA01,$03AC0,$03B80,$0FB41,$03900,$0F9C1,$0F881,$03840,
    $02800,$0E8C1,$0E981,$02940,$0EB01,$02BC0,$02A80,$0EA41,$0EE01,$02EC0,$02F80,$0EF41,$02D00,$0EDC1,$0EC81,$02C40,
    $0E401,$024C0,$02580,$0E541,$02700,$0E7C1,$0E681,$02640,$02200,$0E2C1,$0E381,$02340,$0E101,$021C0,$02080,$0E041,
    $0A001,$060C0,$06180,$0A141,$06300,$0A3C1,$0A281,$06240,$06600,$0A6C1,$0A781,$06740,$0A501,$065C0,$06480,$0A441,
    $06C00,$0ACC1,$0AD81,$06D40,$0AF01,$06FC0,$06E80,$0AE41,$0AA01,$06AC0,$06B80,$0AB41,$06900,$0A9C1,$0A881,$06840,
    $07800,$0B8C1,$0B981,$07940,$0BB01,$07BC0,$07A80,$0BA41,$0BE01,$07EC0,$07F80,$0BF41,$07D00,$0BDC1,$0BC81,$07C40,
    $0B401,$074C0,$07580,$0B541,$07700,$0B7C1,$0B681,$07640,$07200,$0B2C1,$0B381,$07340,$0B101,$071C0,$07080,$0B041,
    $05000,$090C1,$09181,$05140,$09301,$053C0,$05280,$09241,$09601,$056C0,$05780,$09741,$05500,$095C1,$09481,$05440,
    $09C01,$05CC0,$05D80,$09D41,$05F00,$09FC1,$09E81,$05E40,$05A00,$09AC1,$09B81,$05B40,$09901,$059C0,$05880,$09841,
    $08801,$048C0,$04980,$08941,$04B00,$08BC1,$08A81,$04A40,$04E00,$08EC1,$08F81,$04F40,$08D01,$04DC0,$04C80,$08C41,
    $04400,$084C1,$08581,$04540,$08701,$047C0,$04680,$08641,$08201,$042C0,$04380,$08341,$04100,$081C1,$08081,$04040
  );

function CRC16(CRC: Word; Data: Pointer; DataSize: LongWord): Word;
var
  wData : PByteArray absolute Data;
  i     : integer;
begin
  if ( Data <> nil ) and ( DataSize > 0 )
    then
      begin
        for i := 0 to DataSize - 1 do
          CRC := CRC16_Table[ wData[i] xor byte(CRC) ] xor ( CRC shr 8 );
      end;
  Result := CRC;
end;
//asm
//         AND    EDX,EDX
//         JZ     @Exit
//         AND    ECX,ECX
//         JLE    @Exit
//         PUSH   EBX
//         PUSH   EDI
//         XOR    EBX,EBX
//         LEA    EDI,[OFFSET CRC16_Table]
//@Start:  MOV    BL,[EDX]
//         XOR    BL,AL
//         SHR    AX,8
//         XOR    AX,[EDI + EBX * 2]
//         INC    EDX
//         DEC    ECX
//         JNZ    @Start
//         POP    EDI
//         POP    EBX
//@Exit:
//end;

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

function CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord;  register;
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
//asm
//         AND    EDX,EDX
//         JZ     @Exit
//         AND    ECX,ECX
//         JLE    @Exit
//         PUSH   EBX
//         PUSH   EDI
//         XOR    EBX,EBX
//         LEA    EDI,[OFFSET CRC32_Table]
//@Start:  MOV    BL,AL
//         SHR    EAX,8
//         XOR    BL,[EDX]
//         XOR    EAX,[EDI + EBX * 4]
//         INC    EDX
//         DEC    ECX
//         JNZ    @Start
//         POP    EDI
//         POP    EBX
//@Exit:
//end;

{a Random generated Testvector 256bit - 32 Bytes, it's used for Self Test}
const
  _TTestVector : array[0..39] of byte =
    ( $30,$44,$ED,$6E,$45,$A4,$96,$F5,$F6,$35,$A2,$EB,$3D,$1A,$5D,$D6,$CB,$1D,$09,$82,$2D,$BD,$F5,$60,$C2,$B8,$58,$A1,$91,$F9,$81,$B1,$00,$00,$00,$00,$00,$00,$00,$00 );

function GetTestVector: PAnsiChar;
begin
  Result := @_TTestVector;
end;

//{get the CPU Type from your system}
//function GetCPUType: Integer;
//asm
//         PUSH   EBX
//         PUSH   ECX
//         PUSH   EDX
//         MOV    EBX,ESP
//         AND    ESP,0FFFFFFFCh
//         PUSHFD
//         PUSHFD
//         POP    EAX
//         MOV    ECX,EAX
//         XOR    EAX,40000h
//         PUSH   EAX
//         POPFD
//         PUSHFD
//         POP    EAX
//         XOR    EAX,ECX
//         MOV    EAX,3
//         JE     @Exit
//         PUSHFD
//         POP    EAX
//         MOV    ECX,EAX
//         XOR    EAX,200000h
//         PUSH   EAX
//         POPFD
//         PUSHFD
//         POP    EAX
//         XOR    EAX,ECX
//         MOV    EAX,4
//         JE     @Exit
//         PUSH   EBX
//         MOV    EAX,1
//         DB     0Fh,0A2h      //CPUID
//         MOV    AL,AH
//         AND    EAX,0Fh
//         POP    EBX
//@Exit:   POPFD
//         MOV    ESP,EBX
//         POP    EDX
//         POP    ECX
//         POP    EBX
//end;

procedure ModuleUnload(Instance: Integer);
var // automaticaly deregistration
  I: Integer;
begin
  if FStrFMTs <> nil then
    for I := FStrFMTs.Count-1 downto 0 do
      if FindClassHInstance(TClass(FStrFMTs[I])) = Instance then
        FStrFMTs.Delete(I);
end;

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSDecUtil> initialization started');
{$ENDIF}
{$IFDEF D16H}
//
{$ELSE}
  AddModuleUnloadProc(ModuleUnload);
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
//aaWriteToLog('ESFSDecUtil> CPU type = '+IntToStr(FCPUType));
{$ENDIF}
  SwapInteger       := SwapInt; //!!
  SwapIntegerBuffer := SwapIntBuf;

  RegisterStringFormats([TStringFormat, TStringFormat_HEX, TStringFormat_HEXL,
      TStringFormat_MIME64, TStringFormat_UU, TStringFormat_XX]);
{this calculate a Checksum (CRC32) over the function CRC32 and the TestVector,
 if InitTestIsOk = False any modification from Testvector or CRC32() detected, :-) }

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSDecUtil> Before CRC32:');
if InitTestIsOk
then
aaWriteToLog('InitTestIsOk')
else
aaWriteToLog('not InitTestIsOk!!!');
{$ENDIF}

//  InitTestIsOk  := CRC32(CRC32($29524828, PAnsiChar(@CRC32_Table), 1076), GetTestVector, 32) = $848B5964; // Reddmann
{$IFNDEF LINUX}
  InitTestIsOk  := CRC32(CRC32($29524828, PAnsiChar(@CRC32_Table), 1072), GetTestVector, 32) = $8D0C4372; // AidAim
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSDecUtil> After CRC32:');
if InitTestIsOk
then
aaWriteToLog('InitTestIsOk')
else
aaWriteToLog('not InitTestIsOk!!!');
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSDecUtil> initialization finished');
{$ENDIF}

finalization
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSDecUtil> finalization started');
{$ENDIF}
{$IFDEF D16H}
//
{$ELSE}
  RemoveModuleUnloadProc(ModuleUnload);
{$ENDIF}
  FStrFMTs.Free;
  FStrFMTs := nil;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ESFSDecUtil> finalization finished');
{$ENDIF}
end.
