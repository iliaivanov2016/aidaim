unit ACRD4Routines;

interface

{$I ACRVer.inc}

uses
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
     Classes, SysUtils,
{$IFNDEF D5H}
     DB,
{$ENDIF}
     ACRExcept,
     ACRConst

//Accuracer
 {$IFDEF DEBUG_LOG}
  ,ACRDebug
{$IFDEF LINUX}
  ,QDialogs
{$ENDIF}
 {$ENDIF}
     ;

const
  oleaut = 'oleaut32.dll';

var
  ClearAnyProc: Pointer;  { Handler clearing a varAny }

const
  varShortInt = $0010; { vt_i1          16 }
  varByte     = $0011; { vt_ui1         17 }
  varWord     = $0012; { vt_ui2         18 }
  varLongWord = $0013; { vt_ui4         19 }
  varInt64    = $0014; { vt_i8          20 }
resourcestring  SDateEncodeError = 'Invalid argument to date encode';
resourcestring  
  SInvalidDateDay = '(%d, %d) is not a valid DateDay pair';
  SInvalidDateWeek = '(%d, %d, %d) is not a valid DateWeek triplet';
  SInvalidDateMonthWeek = '(%d, %d, %d, %d) is not a valid DateMonthWeek quad';
  SInvalidDayOfWeekInMonth = '(%d, %d, %d, %d) is not a valid DayOfWeekInMonth quad';
  SInvalidJulianDate = '%f Julian cannot be represented as a DateTime';
  SMissingDateTimeField = '?';

  SInvalidDate = '''''%s'''' is not a valid date' ;
  SInvalidDateTime = '''''%s'''' is not a valid date and time' ;
  SInvalidInteger = '''''%s'''' is not a valid integer value' ;
  SInvalidTime = '''''%s'''' is not a valid time' ;
  STimeEncodeError = 'Invalid argument to time encode';

type

{$IFNDEF D5H}
{ TMasterDataLink }

  TMasterDataLink = class(TDetailDataLink)
  private
    FDataSet: TDataSet;
    FFieldNames: string;
    FFields: TList;
    FOnMasterChange: TNotifyEvent;
    FOnMasterDisable: TNotifyEvent;
    procedure SetFieldNames(const Value: string);
  protected
    procedure ActiveChanged; override;
    procedure CheckBrowseMode; override;
    function GetDetailDataSet: TDataSet; override;
    procedure LayoutChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(DataSet: TDataSet);
    destructor Destroy; override;
    property FieldNames: string read FFieldNames write SetFieldNames;
    property Fields: TList read FFields;
    property OnMasterChange: TNotifyEvent read FOnMasterChange write FOnMasterChange;
    property OnMasterDisable: TNotifyEvent read FOnMasterDisable write FOnMasterDisable;
  end;
{$ENDIF}

  StrRec = packed record
    allocSiz: Longint;
    refCnt: Longint;
    length: Longint;
  end;
{ FloatToText, FloatToTextFmt, TextToFloat, and FloatToDecimal type codes }

//  TFloatValue = (fvExtended, fvCurrency);

{ FloatToText format codes }

//  TFloatFormat = (ffGeneral, ffExponent, ffFixed, ffNumber, ffCurrency);

{ FloatToDecimal result record }

  TFloatRec = packed record
    Exponent: Smallint;
    Negative: Boolean;
    Digits: array[0..20] of Char;
  end;


  PMemoryManager = ^TMemoryManager;
  TMemoryManager = record
    GetMem: function(Size: Integer): Pointer;
    FreeMem: function(P: Pointer): Integer;
    ReallocMem: function(P: Pointer; Size: Integer): Pointer;
  end;
  TFormatSettings = record
    CurrencyFormat: Byte;
    NegCurrFormat: Byte;
    ThousandSeparator: Char;
    DecimalSeparator: Char;
    CurrencyDecimals: Byte;
    DateSeparator: Char;
    TimeSeparator: Char;
    ListSeparator: Char;
    CurrencyString: string;
    ShortDateFormat: string;
    LongDateFormat: string;
    TimeAMString: string;
    TimePMString: string;
    ShortTimeFormat: string;
    LongTimeFormat: string;
    ShortMonthNames: array[1..12] of string;
    LongMonthNames: array[1..12] of string;
    ShortDayNames: array[1..7] of string;
    LongDayNames: array[1..7] of string;
    TwoDigitYearCenturyWindow: Word;
  end;

  PBoolean = ^Boolean;
  EConvertError = class(Exception);

const
        skew = sizeof(StrRec);
        rOff = sizeof(StrRec) - sizeof(Longint); { refCnt offset }
        overHead = sizeof(StrRec) + 1;

const
  MinCurrency: Currency = -922337203685477.5807 {$IFDEF LINUX} + 1 {$ENDIF};  //!! overflow?
  MaxCurrency: Currency =  922337203685477.5807 {$IFDEF LINUX} - 1 {$ENDIF};  //!! overflow?

const


  reInvalidPtr        = 2;
  reVarInvalidOp      = 16;
(*
  reOutOfMemory       = 1;
  reDivByZero         = 3;
  reRangeError        = 4;
  reIntOverflow       = 5;
  reInvalidOp         = 6;
  reZeroDivide        = 7;
  reOverflow          = 8;
  reUnderflow         = 9;
  reInvalidCast       = 10;
  reAccessViolation   = 11;
  reStackOverflow     = 12;
  reControlBreak      = 13;
  rePrivInstruction   = 14;
  reVarTypeCast       = 15;
  reVarDispatch       = 17;
  reVarArrayCreate    = 18;
  reVarNotArray       = 19;
  reVarArrayBounds    = 20;
  reAssertionFailed   = 21;
  reExternalException = 22;     { not used here; in SysUtils }
  reIntfCastError     = 23;
  reSafeCallError     = 24;
*)
function ACR_VarArrayGet(var A: Variant; IndexCount: Integer;
  Indices: Integer): Variant; cdecl;
function VarArrayGet(const A: Variant; const Indices: array of Integer): Variant;

{ Memory manager support }

procedure GetMemoryManager(var MemMgr: TMemoryManager);
procedure SetMemoryManager(const MemMgr: TMemoryManager);
function IsMemoryManagerSet: Boolean;
procedure Error(errorCode: Byte);

{ FloatToCurr will range validate a value to make sure it falls
  within the acceptable currency range }
{ FloatToCurr will range validate a value to make sure it falls
  within the acceptable currency range }

function FloatToCurr(const Value: Extended): Currency;
function TryFloatToCurr(const Value: Extended; out AResult: Currency): Boolean;

function TryStrToFloat(const S: string; out Value: Extended): Boolean; overload;

function TryStrToFloat(const S: string; out Value: Double): Boolean; overload;

function TryStrToFloat(const S: string; out Value: Single): Boolean; overload;


(*
function FloatToStr(Value: Extended): string; overload;
function FloatToStr(Value: Extended;
  const FormatSettings: TFormatSettings): string; overload;
  
{ StrToFloat converts the given string to a floating-point value. The string
  must consist of an optional sign (+ or -), a string of digits with an
  optional decimal point, and an optional 'E' or 'e' followed by a signed
  integer. Leading and trailing blanks in the string are ignored. The
  DecimalSeparator global variable defines the character that must be used
  as a decimal point. Thousand separators and currency symbols are not
  allowed in the string. If the string doesn't contain a valid value, an
  EConvertError exception is raised. }

function StrToFloat(const S: string): Extended; overload;
function StrToFloat(const S: string;
  const FormatSettings: TFormatSettings): Extended; overload;

function StrToFloatDef(const S: string;
  const Default: Extended): Extended; overload;
function StrToFloatDef(const S: string; const Default: Extended;
  const FormatSettings: TFormatSettings): Extended; overload;


{ FloatToText converts the given floating-point value to its decimal
  representation using the specified format, precision, and digits. The
  Value parameter must be a variable of type Extended or Currency, as
  indicated by the ValueType parameter. The resulting string of characters
  is stored in the given buffer, and the returned value is the number of
  characters stored. The resulting string is not null-terminated. For
  further details, see the description of the FloatToStrF function. }

function FloatToText(BufferArg: PChar; const Value; ValueType: TFloatValue;
  Format: TFloatFormat; Precision, Digits: Integer): Integer; overload;
function FloatToText(BufferArg: PChar; const Value; ValueType: TFloatValue;
  Format: TFloatFormat; Precision, Digits: Integer;
  const FormatSettings: TFormatSettings): Integer; overload;

function FloatToCurr(const Value: Extended): Currency;
function TryFloatToCurr(const Value: Extended; out AResult: Currency): Boolean;


*)

{ StrToBool converts the given string to a boolean value.  If the string
  doesn't contain a valid value, an EConvertError exception is raised.
  BoolToStr converts boolean to a string value that in turn can be converted
  back into a boolean.  BoolToStr will always pick the first element of
  the TrueStrs/FalseStrs arrays. }

var
  TrueBoolStrs: array of String;
  FalseBoolStrs: array of String;

const
  DefaultTrueBoolStr = 'True';   // DO NOT LOCALIZE
  DefaultFalseBoolStr = 'False'; // DO NOT LOCALIZE

function StrToBool(const S: string): Boolean;
function StrToBoolDef(const S: string; const Default: Boolean): Boolean;
function TryStrToBool(const S: string; out Value: Boolean): Boolean;
function BoolToStr(B: Boolean; UseBoolStrs: Boolean = False): string;
{$IFNDEF D5H}
{ AnsiSameText compares S1 to S2, without case-sensitivity. The compare
  operation is controlled by the current Windows locale. The return value
  is True if AnsiCompareText would have returned 0. }

function AnsiSameText(const S1, S2: string): Boolean;

{$ENDIF}


{ WideCompareStr compares S1 to S2, with case-sensitivity. The return value
  is the same as for CompareStr. }

function WideCompareStr(const S1, S2: WideString): Integer;

{ WideSameStr compares S1 to S2, with case-sensitivity. The return value
  is True if WideCompareStr would have returned 0. }

function WideSameStr(const S1, S2: WideString): Boolean;

{ WideCompareText compares S1 to S2, without case-sensitivity. The return value
  is the same as for CompareStr. }

function WideCompareText(const S1, S2: WideString): Integer;

procedure FreeAndNil(var Obj);

// DATE AND TIME STUFF  
function StartOfADay(const AYear, AMonth, ADay: Word): TDateTime; overload;
function EndOfADay(const AYear, AMonth, ADay: Word): TDateTime; overload;
function StartOfADay(const AYear, ADayOfYear: Word): TDateTime; overload;
function EndOfADay(const AYear, ADayOfYear: Word): TDateTime; overload;

procedure DivMod(Dividend: Integer; Divisor: Word;
  var Result, Remainder: Word);
function TryEncodeDateDay(const AYear, ADayOfYear: Word;
  out AValue: TDateTime): Boolean;
function EncodeDateDay(const AYear, ADayOfYear: Word): TDateTime;
procedure DecodeDateDay(const AValue: TDateTime; out AYear, ADayOfYear: Word);
function DayOfTheYear(const AValue: TDateTime): Word;
function WeekOfTheYear(const AValue: TDateTime): Word; overload;      {ISO 8601}
function WeekOfTheYear(const AValue: TDateTime;                       {ISO 8601}
  var AYear: Word): Word; overload;
function WeekOfTheMonth(const AValue: TDateTime): Word; overload;    {ISO 8601x}
function WeekOfTheMonth(const AValue: TDateTime; var AYear,          {ISO 8601x}
  AMonth: Word): Word; overload;

{ Range query functions }

function YearsBetween(const ANow, AThen: TDateTime): Integer;
function MonthsBetween(const ANow, AThen: TDateTime): Integer;
function WeeksBetween(const ANow, AThen: TDateTime): Integer;
function DaysBetween(const ANow, AThen: TDateTime): Integer;
function HoursBetween(const ANow, AThen: TDateTime): Int64;
function MinutesBetween(const ANow, AThen: TDateTime): Int64;
function SecondsBetween(const ANow, AThen: TDateTime): Int64;
function MilliSecondsBetween(const ANow, AThen: TDateTime): Int64;

{ Range spanning functions }
{ YearSpan and MonthSpan are approximates, not exact but pretty darn close }
function YearSpan(const ANow, AThen: TDateTime): Double;
function MonthSpan(const ANow, AThen: TDateTime): Double;
function WeekSpan(const ANow, AThen: TDateTime): Double;
function DaySpan(const ANow, AThen: TDateTime): Double;
function HourSpan(const ANow, AThen: TDateTime): Double;
function MinuteSpan(const ANow, AThen: TDateTime): Double;
function SecondSpan(const ANow, AThen: TDateTime): Double;
function MilliSecondSpan(const ANow, AThen: TDateTime): Double;

procedure InvalidDateTimeError(const AYear, AMonth, ADay, AHour, AMinute,
  ASecond, AMilliSecond: Word; const ABaseDate: TDateTime = 0);
procedure InvalidDateWeekError(const AYear, AWeekOfYear, ADayOfWeek: Word);
procedure InvalidDateDayError(const AYear, ADayOfYear: Word);
procedure InvalidDateMonthWeekError(const AYear, AMonth, AWeekOfMonth,
  ADayOfWeek: Word);
procedure InvalidDayOfWeekInMonthError(const AYear, AMonth, ANthDayOfWeek,
  ADayOfWeek: Word);

function EndOfTheDay(const AValue: TDateTime): TDateTime;
function StartOfAYear(const AYear: Word): TDateTime;
function IsInLeapYear(const AValue: TDateTime): Boolean;
function IsPM(const AValue: TDateTime): Boolean;
function IsValidDate(const AYear, AMonth, ADay: Word): Boolean;
function IsValidTime(const AHour, AMinute, ASecond, AMilliSecond: Word): Boolean;
function IsValidDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AMilliSecond: Word): Boolean;
function IsValidDateDay(const AYear, ADayOfYear: Word): Boolean;
function IsValidDateWeek(const AYear, AWeekOfYear,                    {ISO 8601}
  ADayOfWeek: Word): Boolean;
function IsValidDateMonthWeek(const AYear, AMonth, AWeekOfMonth,     {ISO 8601x}
  ADayOfWeek: Word): Boolean;

function DayOfTheWeek(const AValue: TDateTime): Word;                 {ISO 8601}
function HourOfTheWeek(const AValue: TDateTime): Word;                {ISO 8601}
function MinuteOfTheWeek(const AValue: TDateTime): Word;              {ISO 8601}
function SecondOfTheWeek(const AValue: TDateTime): LongWord;          {ISO 8601}
function MilliSecondOfTheWeek(const AValue: TDateTime): LongWord;     {ISO 8601}

function WeeksInYear(const AValue: TDateTime): Word;                  {ISO 8601}
function WeeksInAYear(const AYear: Word): Word;                       {ISO 8601}
function DaysInYear(const AValue: TDateTime): Word;
function DaysInAYear(const AYear: Word): Word;
function DaysInMonth(const AValue: TDateTime): Word;
function DaysInAMonth(const AYear, AMonth: Word): Word;
function Today: TDateTime;
function Yesterday: TDateTime;
function Tomorrow: TDateTime;
function IsToday(const AValue: TDateTime): Boolean;
function IsSameDay(const AValue, ABasis: TDateTime): Boolean;
function RecodeYear(const AValue: TDateTime; const AYear: Word): TDateTime;
function RecodeMonth(const AValue: TDateTime; const AMonth: Word): TDateTime;
function RecodeDay(const AValue: TDateTime; const ADay: Word): TDateTime;
function RecodeHour(const AValue: TDateTime; const AHour: Word): TDateTime;
function RecodeMinute(const AValue: TDateTime; const AMinute: Word): TDateTime;
function RecodeSecond(const AValue: TDateTime; const ASecond: Word): TDateTime;
function RecodeMilliSecond(const AValue: TDateTime;
  const AMilliSecond: Word): TDateTime;

function RecodeDate(const AValue: TDateTime; const AYear, AMonth,
  ADay: Word): TDateTime;
function RecodeTime(const AValue: TDateTime; const AHour, AMinute, ASecond,
  AMilliSecond: Word): TDateTime;
function RecodeDateTime(const AValue: TDateTime; const AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word): TDateTime;
function TryRecodeDateTime(const AValue: TDateTime; const AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word; out AResult: TDateTime): Boolean;
function YearOf(const AValue: TDateTime): Word;
function MonthOf(const AValue: TDateTime): Word;
function WeekOf(const AValue: TDateTime): Word;                       {ISO 8601}
function DayOf(const AValue: TDateTime): Word;
function HourOf(const AValue: TDateTime): Word;
function MinuteOf(const AValue: TDateTime): Word;
function SecondOf(const AValue: TDateTime): Word;
function MilliSecondOf(const AValue: TDateTime): Word;
function TryEncodeDate(Year, Month, Day: Word; out Date: TDateTime): Boolean;
function EncodeDate(Year, Month, Day: Word): TDateTime;
procedure DecodeDate(const DateTime: TDateTime; var Year, Month, Day: Word);
function TryEncodeTime(Hour, Min, Sec, MSec: Word; out Time: TDateTime): Boolean;
function DayOfWeek(const DateTime: TDateTime): Word;
function TryEncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AMilliSecond: Word; out AValue: TDateTime): Boolean;
function EncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AMilliSecond: Word): TDateTime;
procedure DecodeDateTime(const AValue: TDateTime; out AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word);
function DecodeDateFully(const DateTime: TDateTime; var Year, Month, Day, DOW: Word): Boolean;

type
  PDayTable = ^TDayTable;
  TDayTable = array[1..12] of Word;

{ The MonthDays array can be used to quickly find the number of
  days in a month:  MonthDays[IsLeapYear(Y), M]      }

const
  MonthDays: array [Boolean] of TDayTable =
    ((31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31),
     (31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31));
const
  HoursPerDay   = 24;
  MinsPerDay    = HoursPerDay * 60;
  SecsPerDay    = MinsPerDay * 60;
  MSecsPerDay   = SecsPerDay * 1000;
  CDayMap: array [1..7] of Word = (7, 1, 2, 3, 4, 5, 6);

{ Days between 1/1/0001 and 12/31/1899 }

  DateDelta = 693594;

{ Days between TDateTime basis (12/31/1899) and Unix time_t basis (1/1/1970) }

  UnixDateDelta = 25569;

  DaysPerWeek = 7;
  WeeksPerFortnight = 2;
  MonthsPerYear = 12;
  YearsPerDecade = 10;
  YearsPerCentury = 100;
  YearsPerMillennium = 1000;

  DayMonday = 1;
  DayTuesday = 2;
  DayWednesday = 3;
  DayThursday = 4;
  DayFriday = 5;
  DaySaturday = 6;
  DaySunday = 7;

  OneHour = 1 / HoursPerDay;
  OneMinute = 1 / MinsPerDay;
  OneSecond = 1 / SecsPerDay;
  OneMillisecond = 1 / MSecsPerDay;

  { This is actual days per year but you need to know if it's a leap year}
  DaysPerYear: array [Boolean] of Word = (365, 366);

  { Used in RecodeDate, RecodeTime and RecodeDateTime for those datetime }
  {  fields you want to leave alone }
  RecodeLeaveFieldAsIs = High(Word);

{ Global variable used in this unit }

var

  { average over a 4 year span }
  ApproxDaysPerMonth: Double = 30.4375;
  ApproxDaysPerYear: Double  = 365.25;

  { The above are the average days per month/year over a normal 4 year period. }
  { We use these approximations because they are more accurate for the next }
  {  century or so.  After that you may want to switch over to these 400 year }
  {  approximations... }
  {    ApproxDaysPerMonth = 30.436875 }
  {    ApproxDaysPerYear  = 365.2425 }

implementation

var
  MemoryManager: TMemoryManager = (
    GetMem: SysGetMem;
    FreeMem: SysFreeMem;
    ReallocMem: SysReallocMem);

{$IFDEF MSWINDOWS}
{$I ACRGetmem.inc }
{$ENDIF}

function VariantClear(var V: Variant): Integer; stdcall;
  external oleaut name 'VariantClear';

function SafeArrayPtrOfIndex(VarArray: PVarArray; Indices: Pointer;
  var pvData: Pointer): HResult; stdcall;
  external oleaut name 'SafeArrayPtrOfIndex';

function SafeArrayGetElement(VarArray: PVarArray; Indices,
  Data: Pointer): Integer; stdcall;
  external oleaut name 'SafeArrayGetElement';

function GetVarArray(const A: Variant): PVarArray;
begin
  if TVarData(A).VType and varArray = 0 then
   raise EACRException.Create(10434,ErrorLVarNotArray);
  if TVarData(A).VType and varByRef <> 0 then
    Result := PVarArray(TVarData(A).VPointer^) else
    Result := TVarData(A).VArray;
end;

procedure _FreeMem;
asm
        TEST    EAX,EAX
        JE      @@1
        CALL    MemoryManager.FreeMem
        OR      EAX,EAX
        JNE     @@2
@@1:    RET
@@2:    MOV     AL,reInvalidPtr
        JMP     Error
end;

procedure Error(errorCode: Byte);
begin
 raise EACRException.Create(10437,ErrorLSystemError,[errorCode]);
end;

procedure _LStrClr(var S: AnsiString);
asm
        { ->    EAX pointer to str      }

        MOV     EDX,[EAX]                       { fetch str                     }
        TEST    EDX,EDX                         { if nil, nothing to do         }
        JE      @@done
        MOV     dword ptr [EAX],0               { clear str                     }
        MOV     ECX,[EDX-skew].StrRec.refCnt    { fetch refCnt                  }
        DEC     ECX                             { if < 0: literal str           }
        JL      @@done
   LOCK DEC     [EDX-skew].StrRec.refCnt        { threadsafe dec refCount       }
        JNE     @@done
        PUSH    EAX
        LEA     EAX,[EDX-skew].StrRec.refCnt    { if refCnt now zero, deallocate}
        CALL    _FreeMem
        POP     EAX
@@done:
end;

procedure VarInvalidOp;
asm
        MOV     AL,reVarInvalidOp
        JMP     Error
end;


procedure _VarClear(var V : Variant);
asm
        XOR     EDX,EDX
        MOV     DX,[EAX].TVarData.VType
        TEST    EDX,varByRef
        JNE     @@2
        CMP     EDX,varOleStr
        JB      @@2
        CMP     EDX,varString
        JE      @@1
        CMP     EDX,varAny
        JNE     @@3
        JMP     [ClearAnyProc]
@@1:    MOV     [EAX].TVarData.VType,varEmpty
        ADD     EAX,OFFSET TVarData.VString
        JMP     _LStrClr
@@2:    MOV     [EAX].TVarData.VType,varEmpty
        RET
@@3:    PUSH    EAX
        CALL    VariantClear
end;


function ACR_VarArrayGet(var A: Variant; IndexCount: Integer;
  Indices: Integer): Variant; cdecl;
var
  VarArrayPtr: PVarArray;
  VarType: Integer;
  P: Pointer;
begin
  if TVarData(A).VType and varArray = 0 then
   raise EACRException.Create(10433,ErrorLVarNotArray);
  VarArrayPtr := GetVarArray(A);
  if VarArrayPtr^.DimCount <> IndexCount then
   raise EACRException.Create(10435,ErrorLVarArrayBounds,
    [VarArrayPtr^.DimCount,IndexCount]);
  VarType := TVarData(A).VType and varTypeMask;
  _VarClear(Result);
  if VarType = varVariant then
  begin
    if SafeArrayPtrOfIndex(VarArrayPtr, @Indices, P) <> 0 then
     raise EACRException.Create(10436,ErrorLVarArrayBounds,
      [-1,-1]);

    Result := PVariant(P)^;
  end else
  begin
  if SafeArrayGetElement(VarArrayPtr, @Indices,
      @TVarData(Result).VPointer) <> 0 then
       raise EACRException.Create(10438,ErrorLVarArrayBounds,
        [-1,-1]);
    TVarData(Result).VType := VarType;
  end;
end; //ACR_VarArrayGet


function VarArrayGet(const A: Variant; const Indices: array of Integer): Variant;
asm
        {     ->EAX     Pointer to A            }
        {       EDX     Pointer to Indices      }
        {       ECX     High bound of Indices   }
        {       [EBP+8] Pointer to result       }

        PUSH    EBX

        MOV     EBX,ECX
        INC     EBX
        JLE     @@endLoop
@@loop:
        PUSH    [EDX+ECX*4].Integer
        DEC     ECX
        JNS     @@loop
@@endLoop:
        PUSH    EBX
        PUSH    EAX
        MOV     EAX,[EBP+8]
        PUSH    EAX
        CALL    ACR_VarArrayGet
        LEA     ESP,[ESP+EBX*4+3*4]

        POP     EBX
end; //VarArrayGet

procedure GetMemoryManager(var MemMgr: TMemoryManager);
begin
  MemMgr := MemoryManager;
end;

procedure SetMemoryManager(const MemMgr: TMemoryManager);
begin
  MemoryManager := MemMgr;
end;

function IsMemoryManagerSet: Boolean;
begin
  with MemoryManager do
    Result := (@GetMem <> @SysGetMem) or (@FreeMem <> @SysFreeMem) or
      (@ReallocMem <> @SysReallocMem);
end;

(*
function StrToFloat(const S: string): Extended;
begin
  if not TextToFloat(PChar(S), Result, fvExtended) then
    raise EACRException.Create(10441,ErrorLInvalidFloat,[S]);
end;

function StrToFloat(const S: string;
  const FormatSettings: TFormatSettings): Extended;
begin
  if not TextToFloat(PChar(S), Result, fvExtended, FormatSettings) then
    raise EACRException.Create(10442,ErrorLInvalidFloat,[S]);
end;

function StrToFloatDef(const S: string; const Default: Extended): Extended;
begin
  if not TextToFloat(PChar(S), Result, fvExtended) then
    Result := Default;
end;

function StrToFloatDef(const S: string; const Default: Extended;
  const FormatSettings: TFormatSettings): Extended;
begin
  if not TextToFloat(PChar(S), Result, fvExtended, FormatSettings) then
    Result := Default;
end;



function FloatToStr(Value: Extended): string;
var
  Buffer: array[0..63] of Char;
begin
  SetString(Result, Buffer, FloatToText(Buffer, Value, fvExtended,
    ffGeneral, 15, 0));
end;

function FloatToStr(Value: Extended;
  const FormatSettings: TFormatSettings): string;
var
  Buffer: array[0..63] of Char;
begin
  SetString(Result, Buffer, FloatToText(Buffer, Value, fvExtended,
    ffGeneral, 15, 0, FormatSettings));
end;

*)

function TryFloatToCurr(const Value: Extended; out AResult: Currency): Boolean;
begin
  Result := (Value >= MinCurrency) and (Value <= MaxCurrency);
  if Result then
    AResult := Value;
end;

function FloatToCurr(const Value: Extended): Currency;
begin
  if not TryFloatToCurr(Value, Result) then
    raise EACRException.Create(10439,ErrorLInvalidCurrency,[FloatToStr(Value)]);
end;

procedure VerifyBoolStrArray;
begin
  if Length(TrueBoolStrs) = 0 then
  begin
    SetLength(TrueBoolStrs, 1);
    TrueBoolStrs[0] := DefaultTrueBoolStr;
  end;
  if Length(FalseBoolStrs) = 0 then
  begin
    SetLength(FalseBoolStrs, 1);
    FalseBoolStrs[0] := DefaultFalseBoolStr;
  end;
end;

function StrToBool(const S: string): Boolean;
begin
  if not TryStrToBool(S, Result) then
    raise EACRException.Create(10440,ErrorLInvalidBoolean,[s]);
end;

function StrToBoolDef(const S: string; const Default: Boolean): Boolean;
begin
  if not TryStrToBool(S, Result) then
    Result := Default;
end;


function TryStrToBool(const S: string; out Value: Boolean): Boolean;
  function CompareWith(const aArray: array of string): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := Low(aArray) to High(aArray) do
      if AnsiSameText(S, aArray[I]) then
      begin
        Result := True;
        Break;
      end;
  end;
var
  LResult: Extended;
begin
  Result := TryStrToFloat(S, LResult);
  if Result then
    Value := LResult <> 0
  else
  begin
    VerifyBoolStrArray;
    Result := CompareWith(TrueBoolStrs);
    if Result then
      Value := True
    else
    begin
      Result := CompareWith(FalseBoolStrs);
      if Result then
        Value := False;
    end;
  end;
end;

function BoolToStr(B: Boolean; UseBoolStrs: Boolean = False): string;
const
  cSimpleBoolStrs: array [boolean] of String = ('0', '-1');
begin
  if UseBoolStrs then
  begin
    VerifyBoolStrArray;
    if B then
      Result := TrueBoolStrs[0]
    else
      Result := FalseBoolStrs[0];
  end
  else
    Result := cSimpleBoolStrs[B];
end;


function TryStrToFloat(const S: string; out Value: Extended): Boolean;
begin
  Result := TextToFloat(PChar(S), Value, fvExtended);
end;

function TryStrToFloat(const S: string; out Value: Double): Boolean;
var
  LValue: Extended;
begin
  Result := TextToFloat(PChar(S), LValue, fvExtended);
  if Result then
    Value := LValue;
end;


function TryStrToFloat(const S: string; out Value: Single): Boolean;
var
  LValue: Extended;
begin
  Result := TextToFloat(PChar(S), LValue, fvExtended);
  if Result then
    Value := LValue;
end;

{$IFNDEF D5H}
{ AnsiSameText compares S1 to S2, without case-sensitivity. The compare
  operation is controlled by the current Windows locale. The return value
  is True if AnsiCompareText would have returned 0. }

function AnsiSameText(const S1, S2: string): Boolean;
begin
  Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PChar(S1),
    Length(S1), PChar(S2), Length(S2)) = 2;
end;


{$ENDIF}


function WideCompareStr(const S1, S2: WideString): Integer;
{$IFDEF MSWINDOWS}
begin
  SetLastError(0);
  Result := CompareStringW(LOCALE_USER_DEFAULT, 0, PWideChar(S1), Length(S1),
    PWideChar(S2), Length(S2)) - 2;
  case GetLastError of
    0: ;
    ERROR_CALL_NOT_IMPLEMENTED:
      Result := 0;
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  UCS4_S1, UCS4_S2: UCS4String;
begin
  UCS4_S1 := WideStringToUCS4String(S1);
  UCS4_S2 := WideStringToUCS4String(S2);
  // glibc 2.1.2 / 2.1.3 implementations of wcscoll() and wcsxfrm()
  // have severe capacity limits.  Comparing two 100k strings may
  // exhaust the stack and kill the process.
  // Fixed in glibc 2.1.91 and later.
  SetLastError(0);
  Result := wcscoll(PUCS4Chars(UCS4_S1), PUCS4Chars(UCS4_S2));
  if GetLastError <> 0 then
    RaiseLastOSError;
end;
{$ENDIF}

function WideSameStr(const S1, S2: WideString): Boolean;
begin
  Result := WideCompareStr(S1, S2) = 0;
end;

function WideCompareText(const S1, S2: WideString): Integer;
begin
{$IFDEF MSWINDOWS}
  SetLastError(0);
  Result := CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PWideChar(S1),
    Length(S1), PWideChar(S2), Length(S2)) - 2;
  case GetLastError of
    0: ;
    ERROR_CALL_NOT_IMPLEMENTED:
        Result := 0;
  end;
{$ENDIF}
{$IFDEF LINUX}
  Result := WideCompareStr(WideUpperCase(S1), WideUpperCase(S2));
{$ENDIF}
end;


{$IFNDEF D5H}
{ TMasterDataLink }

constructor TMasterDataLink.Create(DataSet: TDataSet);
begin
  inherited Create;
  FDataSet := DataSet;
  FFields := TList.Create;
end;

destructor TMasterDataLink.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

procedure TMasterDataLink.ActiveChanged;
begin
  FFields.Clear;
  if Active then
    try
      DataSet.GetFieldList(FFields, FFieldNames);
    except
      FFields.Clear;
      raise;
    end;
  if FDataSet.Active and not (csDestroying in FDataSet.ComponentState) then
    if Active and (FFields.Count > 0) then
    begin
      if Assigned(FOnMasterChange) then FOnMasterChange(Self);
    end else
      if Assigned(FOnMasterDisable) then FOnMasterDisable(Self);
end;

procedure TMasterDataLink.CheckBrowseMode;
begin
  if FDataSet.Active then FDataSet.CheckBrowseMode;
end;

function TMasterDataLink.GetDetailDataSet: TDataSet;
begin
  Result := FDataSet;
end;

procedure TMasterDataLink.LayoutChanged;
begin
  ActiveChanged;
end;

procedure TMasterDataLink.RecordChanged(Field: TField);
begin
  if (DataSource.State <> dsSetKey) and FDataSet.Active and
    (FFields.Count > 0) and ((Field = nil) or
    (FFields.IndexOf(Field) >= 0)) and
     Assigned(FOnMasterChange) then
    FOnMasterChange(Self);
end;

procedure TMasterDataLink.SetFieldNames(const Value: string);
begin
  if FFieldNames <> Value then
  begin
    FFieldNames := Value;
    ActiveChanged;
  end;
end;
{$ENDIF}

procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;


{ Date encoding and decoding }

function YearsBetween(const ANow, AThen: TDateTime): Integer;
begin
  Result := Trunc(YearSpan(ANow, AThen));
end;

function MonthsBetween(const ANow, AThen: TDateTime): Integer;
begin
  Result := Trunc(MonthSpan(ANow, AThen));
end;

function WeeksBetween(const ANow, AThen: TDateTime): Integer;
begin
  Result := Trunc(WeekSpan(ANow, AThen));
end;

function DaysBetween(const ANow, AThen: TDateTime): Integer;
begin
  Result := Trunc(DaySpan(ANow, AThen));
end;

function HoursBetween(const ANow, AThen: TDateTime): Int64;
begin
  Result := Trunc(HourSpan(ANow, AThen));
end;

function MinutesBetween(const ANow, AThen: TDateTime): Int64;
begin
  Result := Trunc(MinuteSpan(ANow, AThen));
end;

function SecondsBetween(const ANow, AThen: TDateTime): Int64;
begin
  Result := Trunc(SecondSpan(ANow, AThen));
end;

function MilliSecondsBetween(const ANow, AThen: TDateTime): Int64;
begin
  Result := Trunc(MilliSecondSpan(ANow, AThen));
end;


function SpanOfNowAndThen(const ANow, AThen: TDateTime): TDateTime;
begin
  if ANow < AThen then
    Result := AThen - ANow
  else
    Result := ANow - AThen;
end;

function YearSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := DaySpan(ANow, AThen) / ApproxDaysPerYear;
end;

function MonthSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := DaySpan(ANow, AThen) / ApproxDaysPerMonth;
end;

function WeekSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := DaySpan(ANow, AThen) / DaysPerWeek;
end;

function DaySpan(const ANow, AThen: TDateTime): Double;
begin
  Result := SpanOfNowAndThen(ANow, AThen);
end;

function HourSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := HoursPerDay * SpanOfNowAndThen(ANow, AThen);
end;

function MinuteSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := MinsPerDay * SpanOfNowAndThen(ANow, AThen);
end;

function SecondSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := SecsPerDay * SpanOfNowAndThen(ANow, AThen);
end;

function MilliSecondSpan(const ANow, AThen: TDateTime): Double;
begin
  Result := MSecsPerDay * SpanOfNowAndThen(ANow, AThen);
end;


function EncodeDateDay(const AYear, ADayOfYear: Word): TDateTime;
begin
  if not TryEncodeDateDay(AYear, ADayOfYear, Result) then
    InvalidDateDayError(AYear, ADayOfYear);
end;

procedure DecodeDateDay(const AValue: TDateTime; out AYear, ADayOfYear: Word);
begin
  AYear := YearOf(AValue);
  ADayOfYear := DayOfTheYear(AValue);
end;

{ Error reporting }

procedure InvalidDateTimeError(const AYear, AMonth, ADay, AHour, AMinute,
  ASecond, AMilliSecond: Word; const ABaseDate: TDateTime);
  function Translate(AOrig, AValue: Word): string;
  begin
    if AValue = RecodeLeaveFieldAsIs then
      if ABaseDate = 0 then
        Result := SMissingDateTimeField
      else
        Result := IntToStr(AOrig)
    else
      Result := IntToStr(AValue);
  end;
begin
  raise EConvertError.CreateFmt(SInvalidDateTime,
                                [Translate(YearOf(ABaseDate), AYear) + DateSeparator +
                                 Translate(MonthOf(ABaseDate), AMonth) + DateSeparator +
                                 Translate(DayOf(ABaseDate), ADay) + ' ' +
                                 Translate(HourOf(ABaseDate), AHour) + TimeSeparator +
                                 Translate(MinuteOf(ABaseDate), AMinute) + TimeSeparator +
                                 Translate(SecondOf(ABaseDate), ASecond) + DecimalSeparator +
                                 Translate(MilliSecondOf(ABaseDate), AMilliSecond)]);
end;

procedure InvalidDateWeekError(const AYear, AWeekOfYear, ADayOfWeek: Word);
begin
  raise EConvertError.CreateFmt(SInvalidDateWeek, [AYear, AWeekOfYear, ADayOfWeek]);
end;

procedure InvalidDateDayError(const AYear, ADayOfYear: Word);
begin
  raise EConvertError.CreateFmt(SInvalidDateDay, [AYear, ADayOfYear]);
end;

procedure InvalidDateMonthWeekError(const AYear, AMonth, AWeekOfMonth,
  ADayOfWeek: Word);
begin
  raise EConvertError.CreateFmt(SInvalidDateMonthWeek, [AYear, AMonth,
    AWeekOfMonth, ADayOfWeek]);
end;

procedure InvalidDayOfWeekInMonthError(const AYear, AMonth, ANthDayOfWeek,
  ADayOfWeek: Word);
begin
  raise EConvertError.CreateFmt(SInvalidDayOfWeekInMonth, [AYear, AMonth,
    ANthDayOfWeek, ADayOfWeek]);
end;

function IsInLeapYear(const AValue: TDateTime): Boolean;
begin
  Result := IsLeapYear(YearOf(AValue));
end;

function IsPM(const AValue: TDateTime): Boolean;
begin
  Result := HourOf(AValue) >= 12;
end;

function IsValidDate(const AYear, AMonth, ADay: Word): Boolean;
begin
  Result := (AYear >= 1) and (AYear <= 9999) and
            (AMonth >= 1) and (AMonth <= 12) and
            (ADay >= 1) and (ADay <= DaysInAMonth(AYear, AMonth));
end;

function IsValidTime(const AHour, AMinute, ASecond, AMilliSecond: Word): Boolean;
begin
  Result := ((AHour < 24) and (AMinute < 60) and
             (ASecond < 60) and (AMilliSecond < 1000)) or
            ((AHour = 24) and (AMinute = 0) and
             (ASecond = 0) and (AMilliSecond = 0));
end;

function IsValidDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AMilliSecond: Word): Boolean;
begin
  Result := IsValidDate(AYear, AMonth, ADay) and
            IsValidTime(AHour, AMinute, ASecond, AMilliSecond);
end;

function IsValidDateMonthWeek(const AYear, AMonth, AWeekOfMonth,
  ADayOfWeek: Word): Boolean;
begin
  Result := (AYear >= 1) and (AYear <= 9999) and
            (AMonth >= 1) and (AMonth <= 12) and
            (AWeekOfMonth >= 1) and (AWeekOfMonth <= 5) and
            (ADayOfWeek >= DayMonday) and (ADayOfWeek <= DaySunday);
end;

function DayOfTheWeek(const AValue: TDateTime): Word;
begin
  Result := (DateTimeToTimeStamp(AValue).Date - 1) mod 7 + 1;
end;

function HourOfTheWeek(const AValue: TDateTime): Word;
begin
  Result := HourOf(AValue) + (DayOfTheWeek(AValue) - 1) * HoursPerDay;
end;

function MinuteOfTheWeek(const AValue: TDateTime): Word;
begin
  Result := MinuteOf(AValue) + HourOfTheWeek(AValue) * 60;
end;

function SecondOfTheWeek(const AValue: TDateTime): LongWord;
begin
  Result := SecondOf(AValue) + MinuteOfTheWeek(AValue) * 60;
end;

function MilliSecondOfTheWeek(const AValue: TDateTime): LongWord;
begin
  Result := MilliSecondOf(AValue) + SecondOfTheWeek(AValue) + 1000;
end;


function IsValidDateDay(const AYear, ADayOfYear: Word): Boolean;
begin
  Result := (AYear >= 1) and (AYear <= 9999) and
            (ADayOfYear >= 1) and (ADayOfYear <= DaysInAYear(AYear));
end;

function IsValidDateWeek(const AYear, AWeekOfYear, ADayOfWeek: Word): Boolean;
begin
  Result := (AYear >= 1) and (AYear <= 9999) and
            (AWeekOfYear >= 1) and (AWeekOfYear <= WeeksInAYear(AYear)) and
            (ADayOfWeek >= DayMonday) and (ADayOfWeek <= DaySunday);
end;

function DaysInYear(const AValue: TDateTime): Word;
begin
  Result := DaysInAYear(YearOf(AValue));
end;

function DaysInAYear(const AYear: Word): Word;
begin
  Result := DaysPerYear[IsLeapYear(AYear)];
end;

function DaysInMonth(const AValue: TDateTime): Word;
begin
  Result := DaysInAMonth(YearOf(AValue), MonthOf(AValue));
end;

function DaysInAMonth(const AYear, AMonth: Word): Word;
begin
  Result := MonthDays[(AMonth = 2) and IsLeapYear(AYear), AMonth];
end;

function WeeksInYear(const AValue: TDateTime): Word;
begin
  Result := WeeksInAYear(YearOf(AValue));
end;

function WeeksInAYear(const AYear: Word): Word;
var
  LDayOfWeek: Word;
begin
  Result := 52;
  LDayOfWeek := DayOfTheWeek(EncodeDate(AYear, 1, 1));
  if (LDayOfWeek = DayThursday) or
     ((LDayOfWeek = DayWednesday) and IsLeapYear(AYear)) then
    Inc(Result);
end;

function Today: TDateTime;
begin
  Result := Date;
end;

function Yesterday: TDateTime;
begin
  Result := Date - 1;
end;

function Tomorrow: TDateTime;
begin
  Result := Date + 1;
end;

function IsToday(const AValue: TDateTime): Boolean;
begin
  Result := IsSameDay(AValue, Date);
end;

function IsSameDay(const AValue, ABasis: TDateTime): Boolean;
begin
  Result := (AValue >= Trunc(ABasis)) and
            (AValue < Trunc(ABasis) + 1);
end;

function TryEncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AMilliSecond: Word; out AValue: TDateTime): Boolean;
var
  LTime: TDateTime;
begin
  Result := TryEncodeDate(AYear, AMonth, ADay, AValue);
  if Result then
  begin
    Result := TryEncodeTime(AHour, AMinute, ASecond, AMilliSecond, LTime);
    if Result then
      AValue := AValue + LTime;
  end;
end;

function TryEncodeDateWeek(const AYear, AWeekOfYear: Word;
  out AValue: TDateTime; const ADayOfWeek: Word): Boolean;
var
  LDayOfYear: Integer;
  LStartDayOfWeek: Word;
begin
  Result := IsValidDateWeek(AYear, AWeekOfYear, ADayOfWeek);
  if Result then
  begin
    AValue := EncodeDate(AYear, 1, 1);
    LStartDayOfWeek := DayOfTheWeek(AValue);
    LDayOfYear := (AWeekOfYear - 1) * 7 + ADayOfWeek - 1;
    if LStartDayOfWeek in [DayFriday, DaySaturday, DaySunday] then
      Inc(LDayOfYear, 8 - LStartDayOfWeek)
    else
      Dec(LDayOfYear, LStartDayOfWeek - 1);
    AValue := AValue + LDayOfYear;
  end;
end;

function TryEncodeDateDay(const AYear, ADayOfYear: Word;
  out AValue: TDateTime): Boolean;
begin
  Result := IsValidDateDay(AYear, ADayOfYear);
  if Result then
    AValue := StartOfAYear(AYear) + ADayOfYear - 1;
end;

function TryEncodeDateMonthWeek(const AYear, AMonth, AWeekOfMonth,
  ADayOfWeek: Word; var AValue: TDateTime): Boolean;
var
  LStartDayOfWeek: Word;
  LDayOfMonth: Integer;
begin
  Result := IsValidDateMonthWeek(AYear, AMonth, AWeekOfMonth, ADayOfWeek);
  if Result then
  begin
    AValue := EncodeDate(AYear, AMonth, 1);
    LStartDayOfWeek := DayOfTheWeek(AValue);
    LDayOfMonth := (AWeekOfMonth - 1) * 7 + ADayOfWeek - 1;
    if LStartDayOfWeek in [DayFriday, DaySaturday, DaySunday] then
      Inc(LDayOfMonth, 8 - LStartDayOfWeek)
    else
      Dec(LDayOfMonth, LStartDayOfWeek - 1);
    AValue := AValue + LDayOfMonth;
  end;
end;

function RecodeYear(const AValue: TDateTime; const AYear: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, AYear, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs);
end;

function RecodeMonth(const AValue: TDateTime; const AMonth: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, AMonth,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs);
end;

function RecodeDay(const AValue: TDateTime; const ADay: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    ADay, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs);
end;

function RecodeHour(const AValue: TDateTime; const AHour: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, AHour, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs);
end;

function RecodeMinute(const AValue: TDateTime; const AMinute: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, AMinute, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs);
end;

function RecodeSecond(const AValue: TDateTime; const ASecond: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, ASecond,
    RecodeLeaveFieldAsIs);
end;

function RecodeMilliSecond(const AValue: TDateTime;
  const AMilliSecond: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, AMilliSecond);
end;

function RecodeDate(const AValue: TDateTime; const AYear, AMonth,
  ADay: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, AYear, AMonth, ADay, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs);
end;

function RecodeTime(const AValue: TDateTime; const AHour, AMinute, ASecond,
  AMilliSecond: Word): TDateTime;
begin
  Result := RecodeDateTime(AValue, RecodeLeaveFieldAsIs, RecodeLeaveFieldAsIs,
    RecodeLeaveFieldAsIs, AHour, AMinute, ASecond, AMilliSecond);
end;

function RecodeDateTime(const AValue: TDateTime; const AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word): TDateTime;
begin
  if not TryRecodeDateTime(AValue, AYear, AMonth, ADay,
                           AHour, AMinute, ASecond, AMilliSecond, Result) then
    InvalidDateTimeError(AYear, AMonth, ADay,
                         AHour, AMinute, ASecond, AMilliSecond,
                         AValue);
end;

function TryRecodeDateTime(const AValue: TDateTime; const AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word; out AResult: TDateTime): Boolean;
var
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilliSecond: Word;
begin
  DecodeDateTime(AValue, LYear, LMonth, LDay,
                         LHour, LMinute, LSecond, LMilliSecond);
  if AYear <> RecodeLeaveFieldAsIs then LYear := AYear;
  if AMonth <> RecodeLeaveFieldAsIs then LMonth := AMonth;
  if ADay <> RecodeLeaveFieldAsIs then LDay := ADay;
  if AHour <> RecodeLeaveFieldAsIs then LHour := AHour;
  if AMinute <> RecodeLeaveFieldAsIs then LMinute := AMinute;
  if ASecond <> RecodeLeaveFieldAsIs then LSecond := ASecond;
  if AMilliSecond <> RecodeLeaveFieldAsIs then LMilliSecond := AMilliSecond;
  Result := TryEncodeDateTime(LYear, LMonth, LDay,
                              LHour, LMinute, LSecond, LMilliSecond, AResult);
end;

function StartOfAYear(const AYear: Word): TDateTime;
begin
  Result := EncodeDate(AYear, 1, 1);
end;

function EndOfAYear(const AYear: Word): TDateTime;
begin
  Result := EndOfTheDay(EncodeDate(AYear, 12, 31));
end;

function StartOfAMonth(const AYear, AMonth: Word): TDateTime;
begin
  Result := EncodeDate(AYear, AMonth, 1);
end;

function EndOfAMonth(const AYear, AMonth: Word): TDateTime;
begin
  Result := EndOfTheDay(EncodeDate(AYear, AMonth, DaysInAMonth(AYear, AMonth)));
end;
function StartOfTheDay(const AValue: TDateTime): TDateTime;
begin
  Result := Trunc(AValue);
end;

function EndOfTheDay(const AValue: TDateTime): TDateTime;
begin
  Result := RecodeTime(AValue, 23, 59, 59, 999);
end;

function StartOfTheYear(const AValue: TDateTime): TDateTime;
begin
  Result := EncodeDate(YearOf(AValue), 1, 1);
end;

function EndOfTheYear(const AValue: TDateTime): TDateTime;
begin
  Result := EndOfTheDay(EncodeDate(YearOf(AValue), 12, 31));
end;

function StartOfTheMonth(const AValue: TDateTime): TDateTime;
var
  LYear, LMonth, LDay: Word;
begin
  DecodeDate(AValue, LYear, LMonth, LDay);
  Result := EncodeDate(LYear, LMonth, 1);
end;

function EndOfTheMonth(const AValue: TDateTime): TDateTime;
var
  LYear, LMonth, LDay: Word;
begin
  DecodeDate(AValue, LYear, LMonth, LDay);
  Result := EndOfTheDay(EncodeDate(LYear, LMonth, DaysInAMonth(LYear, LMonth)));
end;

function StartOfTheWeek(const AValue: TDateTime): TDateTime;
begin
  Result := Trunc(AValue) - (DayOfTheWeek(AValue) - 1);
end;

function EndOfTheWeek(const AValue: TDateTime): TDateTime;
begin
  Result := EndOfTheDay(StartOfTheWeek(AValue) + 6);
end;



function EncodeDateWeek(const AYear, AWeekOfYear, ADayOfWeek: Word): TDateTime;
begin
  if not TryEncodeDateWeek(AYear, AWeekOfYear, Result, ADayOfWeek) then
    InvalidDateWeekError(AYear, AWeekOfYear, ADayOfWeek);
end;

function DecodeDateFully(const DateTime: TDateTime; var Year, Month, Day, DOW: Word): Boolean;
const
  D1 = 365;
  D4 = D1 * 4 + 1;
  D100 = D4 * 25 - 1;
  D400 = D100 * 4 + 1;
var
  Y, M, D, I: Word;
  T: Integer;
  DayTable: PDayTable;
begin
  T := DateTimeToTimeStamp(DateTime).Date;
  if T <= 0 then
  begin
    Year := 0;
    Month := 0;
    Day := 0;
    DOW := 0;
    Result := False;
  end else
  begin
    DOW := T mod 7 + 1;
    Dec(T);
    Y := 1;
    while T >= D400 do
    begin
      Dec(T, D400);
      Inc(Y, 400);
    end;
    DivMod(T, D100, I, D);
    if I = 4 then
    begin
      Dec(I);
      Inc(D, D100);
    end;
    Inc(Y, I * 100);
    DivMod(D, D4, I, D);
    Inc(Y, I * 4);
    DivMod(D, D1, I, D);
    if I = 4 then
    begin
      Dec(I);
      Inc(D, D1);
    end;
    Inc(Y, I);
    Result := IsLeapYear(Y);
    DayTable := @MonthDays[Result];
    M := 1;
    while True do
    begin
      I := DayTable^[M];
      if D < I then Break;
      Dec(D, I);
      Inc(M);
    end;
    Year := Y;
    Month := M;
    Day := D + 1;
  end;
end;

procedure DecodeDateWeek(const AValue: TDateTime; out AYear, AWeekOfYear,
  ADayOfWeek: Word);
var
  LDayOfYear: Integer;
  LMonth, LDay: Word;
  LStart: TDateTime;
  LStartDayOfWeek, LEndDayOfWeek: Word;
  LLeap: Boolean;
begin
  LLeap := DecodeDateFully(AValue, AYear, LMonth, LDay, ADayOfWeek);
  ADayOfWeek := CDayMap[ADayOfWeek];
  LStart := EncodeDate(AYear, 1, 1);
  LDayOfYear := Trunc(AValue - LStart + 1);
  LStartDayOfWeek := DayOfTheWeek(LStart);
  if LStartDayOfWeek in [DayFriday, DaySaturday, DaySunday] then
    Dec(LDayOfYear, 8 - LStartDayOfWeek)
  else
    Inc(LDayOfYear, LStartDayOfWeek - 1);
  if LDayOfYear <= 0 then
    DecodeDateWeek(LStart - 1, AYear, AWeekOfYear, LDay)
  else
  begin
    AWeekOfYear := LDayOfYear div 7;
    if LDayOfYear mod 7 <> 0 then
      Inc(AWeekOfYear);
    if AWeekOfYear > 52 then
    begin
      LEndDayOfWeek := LStartDayOfWeek;
      if LLeap then
      begin
        if LEndDayOfWeek = DaySunday then
          LEndDayOfWeek := DayMonday
        else
          Inc(LEndDayOfWeek);
      end;
      if LEndDayOfWeek in [DayMonday, DayTuesday, DayWednesday] then
      begin
        Inc(AYear);
        AWeekOfYear := 1;
      end;
    end;
  end;
end;

function StartOfAWeek(const AYear, AWeekOfYear, ADayOfWeek: Word): TDateTime;
begin
  Result := EncodeDateWeek(AYear, AWeekOfYear, ADayOfWeek);
end;

function EndOfAWeek(const AYear, AWeekOfYear, ADayOfWeek: Word): TDateTime;
begin
  Result := EndOfTheDay(EncodeDateWeek(AYear, AWeekOfYear, ADayOfWeek));
end;

function StartOfADay(const AYear, ADayOfYear: Word): TDateTime;
begin
  Result := EncodeDateDay(AYear, ADayOfYear);
end;

function EndOfADay(const AYear, ADayOfYear: Word): TDateTime;
begin
  Result := EndOfTheDay(EncodeDateDay(AYear, ADayOfYear));
end;

function StartOfADay(const AYear, AMonth, ADay: Word): TDateTime;
begin
  Result := StartOfAMonth(AYear, AMonth) + ADay - 1;
end;

function EndOfADay(const AYear, AMonth, ADay: Word): TDateTime;
begin
  Result := EndOfAMonth(AYear, AMonth) + ADay - 1;
end;


function MonthOfTheYear(const AValue: TDateTime): Word;
begin
  Result := MonthOf(AValue);
end;

function WeekOfTheYear(const AValue: TDateTime): Word;
var
  LYear, LDOW: Word;
begin
  DecodeDateWeek(AValue, LYear, Result, LDOW);
end;

function WeekOfTheYear(const AValue: TDateTime; var AYear: Word): Word;
var
  LDOW: Word;
begin
  DecodeDateWeek(AValue, AYear, Result, LDOW);
end;

function DayOfTheYear(const AValue: TDateTime): Word;
begin
  Result := Trunc(AValue - StartOfTheYear(AValue)) + 1;
end;

function HourOfTheYear(const AValue: TDateTime): Word;
begin
  Result := HourOf(AValue) + (DayOfTheYear(AValue) - 1) * HoursPerDay;
end;

function MinuteOfTheYear(const AValue: TDateTime): LongWord;
begin
  Result := MinuteOf(AValue) + HourOfTheYear(AValue) * 60;
end;

function SecondOfTheYear(const AValue: TDateTime): LongWord;
begin
  Result := SecondOf(AValue) + MinuteOfTheYear(AValue) * 60;
end;

function MilliSecondOfTheYear(const AValue: TDateTime): Int64;
begin
  Result := MilliSecondOf(AValue) + SecondOfTheYear(AValue) + 1000;
end;

procedure DecodeDateMonthWeek(const AValue: TDateTime;
  out AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word);
var
  LDay, LDaysInMonth: Word;
  LDayOfMonth: Integer;
  LStart: TDateTime;
  LStartDayOfWeek, LEndOfMonthDayOfWeek: Word;
begin
  DecodeDateFully(AValue, AYear, AMonth, LDay, ADayOfWeek);
  ADayOfWeek := CDayMap[ADayOfWeek];
  LStart := EncodeDate(AYear, AMonth, 1);
  LStartDayOfWeek := DayOfTheWeek(LStart);
  LDayOfMonth := LDay;
  if LStartDayOfWeek in [DayFriday, DaySaturday, DaySunday] then
    Dec(LDayOfMonth, 8 - LStartDayOfWeek)
  else
    Inc(LDayOfMonth, LStartDayOfWeek - 1);
  if LDayOfMonth <= 0 then
    DecodeDateMonthWeek(LStart - 1, AYear, AMonth, AWeekOfMonth, LDay)
  else
  begin
    AWeekOfMonth := LDayOfMonth div 7;
    if LDayOfMonth mod 7 <> 0 then
      Inc(AWeekOfMonth);
    LDaysInMonth := DaysInAMonth(AYear, AMonth);
    LEndOfMonthDayOfWeek := DayOfTheWeek(EncodeDate(AYear, AMonth, LDaysInMonth));
    if (LEndOfMonthDayOfWeek in [DayMonday, DayTuesday, DayWednesday]) and
       (LDaysInMonth - LDay < LEndOfMonthDayOfWeek) then
    begin
      Inc(AMonth);
      if AMonth = 13 then
      begin
        AMonth := 1;
        Inc(AYear);
      end;
      AWeekOfMonth := 1;
    end;
  end;
end;


function WeekOfTheMonth(const AValue: TDateTime): Word;
var
  LYear, LMonth, LDayOfWeek: Word;
begin
  DecodeDateMonthWeek(AValue, LYear, LMonth, Result, LDayOfWeek);
end;

function WeekOfTheMonth(const AValue: TDateTime; var AYear, AMonth: Word): Word;
var
  LDayOfWeek: Word;
begin
  DecodeDateMonthWeek(AValue, AYear, AMonth, Result, LDayOfWeek);
end;

function DayOfTheMonth(const AValue: TDateTime): Word;
begin
  Result := DayOf(AValue);
end;

function HourOfTheMonth(const AValue: TDateTime): Word;
begin
  Result := HourOf(AValue) + (DayOfTheMonth(AValue) - 1) * HoursPerDay;
end;

function MinuteOfTheMonth(const AValue: TDateTime): Word;
begin
  Result := MinuteOf(AValue) + HourOfTheMonth(AValue) * 60;
end;

function SecondOfTheMonth(const AValue: TDateTime): LongWord;
begin
  Result := SecondOf(AValue) + MinuteOfTheMonth(AValue) * 60;
end;

function MilliSecondOfTheMonth(const AValue: TDateTime): LongWord;
begin
  Result := MilliSecondOf(AValue) + SecondOfTheMonth(AValue) + 1000;
end;

function HourOfTheDay(const AValue: TDateTime): Word;
begin
  Result := HourOf(AValue);
end;

function MinuteOfTheDay(const AValue: TDateTime): Word;
var
  LHours, LMinutes, LSeconds, LMilliSeconds: Word;
begin
  DecodeTime(AValue, LHours, LMinutes, LSeconds, LMilliSeconds);
  Result := LMinutes + LHours * 60;
end;

function SecondOfTheDay(const AValue: TDateTime): LongWord;
var
  LHours, LMinutes, LSeconds, LMilliSeconds: Word;
begin
  DecodeTime(AValue, LHours, LMinutes, LSeconds, LMilliSeconds);
  Result := LSeconds + (LMinutes + LHours * 60) * 60;
end;

function MilliSecondOfTheDay(const AValue: TDateTime): LongWord;
var
  LHours, LMinutes, LSeconds, LMilliSeconds: Word;
begin
  DecodeTime(AValue, LHours, LMinutes, LSeconds, LMilliSeconds);
  Result := LMilliSeconds + (LSeconds + (LMinutes + LHours * 60) * 60) * 1000;
end;


function MinuteOfTheHour(const AValue: TDateTime): Word;
begin
  Result := MinuteOf(AValue);
end;

function SecondOfTheHour(const AValue: TDateTime): Word;
var
  LHours, LMinutes, LSeconds, LMilliSeconds: Word;
begin
  DecodeTime(AValue, LHours, LMinutes, LSeconds, LMilliSeconds);
  Result := LSeconds + (LMinutes * 60);
end;

function MilliSecondOfTheHour(const AValue: TDateTime): LongWord;
var
  LHours, LMinutes, LSeconds, LMilliSeconds: Word;
begin
  DecodeTime(AValue, LHours, LMinutes, LSeconds, LMilliSeconds);
  Result := LMilliSeconds + (LSeconds + LMinutes * 60) * 1000;
end;


function SecondOfTheMinute(const AValue: TDateTime): Word;
begin
  Result := SecondOf(AValue);
end;

function MilliSecondOfTheMinute(const AValue: TDateTime): LongWord;
var
  LHours, LMinutes, LSeconds, LMilliSeconds: Word;
begin
  DecodeTime(AValue, LHours, LMinutes, LSeconds, LMilliSeconds);
  Result := LMilliSeconds + LSeconds * 1000;
end;


function MilliSecondOfTheSecond(const AValue: TDateTime): Word;
begin
  Result := MilliSecondOf(AValue);
end;


function WithinPastYears(const ANow, AThen: TDateTime;
  const AYears: Integer): Boolean;
begin
  Result := YearsBetween(ANow, AThen) <= AYears;
end;

function WithinPastMonths(const ANow, AThen: TDateTime;
  const AMonths: Integer): Boolean;
begin
  Result := MonthsBetween(ANow, AThen) <= AMonths;
end;

function WithinPastWeeks(const ANow, AThen: TDateTime;
  const AWeeks: Integer): Boolean;
begin
  Result := WeeksBetween(ANow, AThen) <= AWeeks;
end;

function WithinPastDays(const ANow, AThen: TDateTime;
  const ADays: Integer): Boolean;
begin
  Result := DaysBetween(ANow, AThen) <= ADays;
end;

function WithinPastHours(const ANow, AThen: TDateTime;
  const AHours: Int64): Boolean;
begin
  Result := HoursBetween(ANow, AThen) <= AHours;
end;

function WithinPastMinutes(const ANow, AThen: TDateTime;
  const AMinutes: Int64): Boolean;
begin
  Result := MinutesBetween(ANow, AThen) <= AMinutes;
end;

function WithinPastSeconds(const ANow, AThen: TDateTime;
  const ASeconds: Int64): Boolean;
begin
  Result := SecondsBetween(ANow, AThen) <= ASeconds;
end;

function WithinPastMilliSeconds(const ANow, AThen: TDateTime;
  const AMilliSeconds: Int64): Boolean;
begin
  Result := MilliSecondsBetween(ANow, AThen) <= AMilliSeconds;
end;




function IncYear(const AValue: TDateTime;
  const ANumberOfYears: Integer): TDateTime;
begin
  Result := IncMonth(AValue, ANumberOfYears * MonthsPerYear);
end;

function IncWeek(const AValue: TDateTime;
  const ANumberOfWeeks: Integer): TDateTime;
begin
  Result := AValue + ANumberOfWeeks * DaysPerWeek;
end;

function IncDay(const AValue: TDateTime;
  const ANumberOfDays: Integer): TDateTime;
begin
  Result := AValue + ANumberOfDays;
end;

function IncHour(const AValue: TDateTime;
  const ANumberOfHours: Int64): TDateTime;
begin
  Result := ((AValue * HoursPerDay) + ANumberOfHours) / HoursPerDay;
end;

function IncMinute(const AValue: TDateTime;
  const ANumberOfMinutes: Int64): TDateTime;
begin
  Result := ((AValue * MinsPerDay) + ANumberOfMinutes) / MinsPerDay;
end;

function IncSecond(const AValue: TDateTime;
  const ANumberOfSeconds: Int64): TDateTime;
begin
  Result := ((AValue * SecsPerDay) + ANumberOfSeconds) / SecsPerDay;
end;

function IncMilliSecond(const AValue: TDateTime;
  const ANumberOfMilliSeconds: Int64): TDateTime;
begin
  Result := ((AValue * MSecsPerDay) + ANumberOfMilliSeconds) / MSecsPerDay;
end;

function YearOf(const AValue: TDateTime): Word;
var
  LMonth, LDay: Word;
begin
  DecodeDate(AValue, Result, LMonth, LDay);
end;

function MonthOf(const AValue: TDateTime): Word;
var
  LYear, LDay: Word;
begin
  DecodeDate(AValue, LYear, Result, LDay);
end;

function WeekOf(const AValue: TDateTime): Word;
begin
  Result := WeekOfTheYear(AValue);
end;

function DayOf(const AValue: TDateTime): Word;
var
  LYear, LMonth: Word;
begin
  DecodeDate(AValue, LYear, LMonth, Result);
end;

function HourOf(const AValue: TDateTime): Word;
var
  LMinute, LSecond, LMilliSecond: Word;
begin
  DecodeTime(AValue, Result, LMinute, LSecond, LMilliSecond);
end;

function MinuteOf(const AValue: TDateTime): Word;
var
  LHour, LSecond, LMilliSecond: Word;
begin
  DecodeTime(AValue, LHour, Result, LSecond, LMilliSecond);
end;

function SecondOf(const AValue: TDateTime): Word;
var
  LHour, LMinute, LMilliSecond: Word;
begin
  DecodeTime(AValue, LHour, LMinute, Result, LMilliSecond);
end;

function MilliSecondOf(const AValue: TDateTime): Word;
var
  LHour, LMinute, LSecond: Word;
begin
  DecodeTime(AValue, LHour, LMinute, LSecond, Result);
end;


function IsLeapYear(Year: Word): Boolean;
begin
  Result := (Year mod 4 = 0) and ((Year mod 100 <> 0) or (Year mod 400 = 0));
end;

function TryEncodeDate(Year, Month, Day: Word; out Date: TDateTime): Boolean;
var
  I: Integer;
  DayTable: PDayTable;
begin
  Result := False;
  DayTable := @MonthDays[IsLeapYear(Year)];
  if (Year >= 1) and (Year <= 9999) and (Month >= 1) and (Month <= 12) and
    (Day >= 1) and (Day <= DayTable^[Month]) then
  begin
    for I := 1 to Month - 1 do Inc(Day, DayTable^[I]);
    I := Year - 1;
    Date := I * 365 + I div 4 - I div 100 + I div 400 + Day - DateDelta;
    Result := True;
  end;
end;

procedure ConvertError(ResString: PResStringRec); 
begin
  raise EConvertError.CreateRes(ResString);
end;

function EncodeDate(Year, Month, Day: Word): TDateTime;
begin
  if not TryEncodeDate(Year, Month, Day, Result) then
    ConvertError(@SDateEncodeError);
end;

procedure DivMod(Dividend: Integer; Divisor: Word;
  var Result, Remainder: Word);
asm
        PUSH    EBX
        MOV     EBX,EDX
        MOV     EDX,EAX
        SHR     EDX,16
        DIV     BX
        MOV     EBX,Remainder
        MOV     [ECX],AX
        MOV     [EBX],DX
        POP     EBX
end;



function InternalDecodeDate(const DateTime: TDateTime; var Year, Month, Day, DOW: Word): Boolean;
begin
  Result := DecodeDateFully(DateTime, Year, Month, Day, DOW);
  Dec(DOW);
end;

procedure DecodeDate(const DateTime: TDateTime; var Year, Month, Day: Word);
var
  Dummy: Word;
begin
  DecodeDateFully(DateTime, Year, Month, Day, Dummy);
end;

function TryEncodeTime(Hour, Min, Sec, MSec: Word; out Time: TDateTime): Boolean;
begin
  Result := False;
  if (Hour < 24) and (Min < 60) and (Sec < 60) and (MSec < 1000) then
  begin
    Time := (Hour * 3600000 + Min * 60000 + Sec * 1000 + MSec) / MSecsPerDay;
    Result := True;
  end;
end;

{$IFDEF MSWINDOWS}
procedure DateTimeToSystemTime(const DateTime: TDateTime; var SystemTime: TSystemTime);
begin
  with SystemTime do
  begin
    DecodeDateFully(DateTime, wYear, wMonth, wDay, wDayOfWeek);
    Dec(wDayOfWeek);
    DecodeTime(DateTime, wHour, wMinute, wSecond, wMilliseconds);
  end;
end;

function SystemTimeToDateTime(const SystemTime: TSystemTime): TDateTime;
begin
  with SystemTime do
  begin
    Result := EncodeDate(wYear, wMonth, wDay);
    if Result >= 0 then
      Result := Result + EncodeTime(wHour, wMinute, wSecond, wMilliSeconds)
    else
      Result := Result - EncodeTime(wHour, wMinute, wSecond, wMilliSeconds);
  end;
end;
{$ENDIF}

function DayOfWeek(const DateTime: TDateTime): Word;
begin
  Result := DateTimeToTimeStamp(DateTime).Date mod 7 + 1;
end;


function EncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AMilliSecond: Word): TDateTime;
begin
  if not TryEncodeDateTime(AYear, AMonth, ADay,
                           AHour, AMinute, ASecond, AMilliSecond, Result) then
    InvalidDateTimeError(AYear, AMonth, ADay,
                         AHour, AMinute, ASecond, AMilliSecond);
end;

procedure DecodeDateTime(const AValue: TDateTime; out AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word);
begin
  DecodeDate(AValue, AYear, AMonth, ADay);
  DecodeTime(AValue, AHour, AMinute, ASecond, AMilliSecond);
end;


initialization

{$IFDEF DEBUG_LOG_INIT}
// ShowMessage('ACRD4Routines initialization started');
aaWriteToLog('ACRD4Routines> initialization started');
{$ENDIF}

  ClearAnyProc := @VarInvalidOp;

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRD4Routines> initialization finished');
{$ENDIF}

end.

