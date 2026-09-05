unit SQLMemDateFormat;

//Example:  "Today is" mm/dd/yyyy hh24:nn:ss ' Wow !!!'

interface

{$I SQLMemVer.Inc}

uses SysUtils, Math,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF}
     SQLMemExcept,
     SQLMemConst
;

Type
    TDateFormatType  = ( dfYYYY, dfYY, dfYEAR,                        // year
                         dfQ,                                         // quarter
                         dfMONTH, dfMON, dfMM, dfM, dfRM,             // month
                         dfDDD, dfDD, dfDAY, dfDY, dfDW, dfD,         // days
                         dfHH12, dfHH24, dfHH, dfH12, dfH24, dfH,     // hours
                         dfNN, dfN,                                   // minutes
                         dfSS, dfS,                                   // seconds
                         dfZZZ, dfZ,                                  // milliseconds
                         dfAMPM,                                      // am/pm
                         dfText);
const
    DateFormatReservedWordsCount = 28;
    DateFormatReservedWords: array[0..DateFormatReservedWordsCount-1] of WideString = (
                         'YYYY', 'YY', 'YEAR',
                         'Q',
                         'MONTH', 'MON', 'MM', 'M', 'RM',
                         'DDD', 'DD', 'DAY', 'DY', 'DW', 'D',
                         'HH12', 'HH24', 'HH', 'H12', 'H24', 'H',
                         'NN', 'N',
                         'SS', 'S',
                         'ZZZ', 'Z',
                         'AMPM');

    DayNames: array[1..7] of WideString = (
                         'Sunday',
                         'Monday',
                         'Tuesday',
                         'Wednesday',
                         'Thursday',
                         'Friday',
                         'Saturday'
    );

    MonthNames: array[1..12] of WideString = (
                         'January',
                         'February',
                         'March',
                         'April',
                         'May',
                         'June',
                         'July',
                         'August',
                         'September',
                         'October',
                         'November',
                         'December'
    );

    Delimeters = '-/,.;:';

    TwoDigitYearCenturyWindow = 1930; // 1930 - 2029
var
   DateFormatReservedWordsMaxLength: integer;
Type

  TDateFormatToken = record
    TokenType: TDateFormatType;
    Text:      WideString;
  end;

  TDateFormater = class
  private
   FDateFormat: array of TDateFormatToken;
   procedure ParseDateFormat(const DateFormatStr: WideString);
   function GetReservedWord(const Text: WideString): TDateFormatType;
  public
   constructor Create(DateFormat: WideString);
   destructor Destroy; override;

   function DebugGetTokenList: WideString;
   procedure ConvertStrToWord(
                     const MaxSigns: Integer;
                     const Str:      WideString;
                     var Start:      Integer;
                     var w:          Word
                    );
   procedure ConvertRMToWord(
                     const Str:      WideString;
                     var Start:      Integer;
                     var w:          Word
                    );
   function ToDate(str: WideString): TDateTime;
   function TOString(dt: TDateTime): WideString;
   function GetStringMaxSize: Integer;
   procedure Assign(Source: TDateFormater);
  end; // TDateFormater

function aaDayOfTheWeek(const AValue: TDateTime): Word;
function aaDayOfWeek(const DateTime: TDateTime): Word;
function aaDayOfYear(const DateTime: TDateTime): Word;
function aaWeek(const DateTime: TDateTime): Word;
function aaISOWeek(const DateTime: TDateTime): Word;

implementation

const
  AM = 'AM';
  PM = 'PM';

// DateUtils Functions...

function YearOf(const AValue: TDateTime): Word;
var
  LMonth, LDay: Word;
begin
  DecodeDate(AValue, Result, LMonth, LDay);
end;

function StartOfTheYear(const AValue: TDateTime): TDateTime;
begin
  Result := EncodeDate(YearOf(AValue), 1, 1);
end;

function DayOfTheYear(const AValue: TDateTime): Word;
begin
  Result := Trunc(AValue - StartOfTheYear(AValue)) + 1;
end;

function MonthOf(const AValue: TDateTime): Word;
var
  LYear, LDay: Word;
begin
  DecodeDate(AValue, LYear, Result, LDay);
end;

function aaDayOfTheWeek(const AValue: TDateTime): Word;
begin
  Result := (DateTimeToTimeStamp(AValue).Date - 1) mod 7 + 1;
end;

function aaDayOfWeek(const DateTime: TDateTime): Word;
begin
  Result := DateTimeToTimeStamp(DateTime).Date mod 7 + 1;
end;

function aaDayOfYear(const DateTime: TDateTime): Word;
begin
  Result := Trunc(Datetime - StartOfTheYear(DateTime)) + 1;
end;

function DayOfTheWeek(const AValue: TDateTime): Word;
begin
  Result := (DateTimeToTimeStamp(AValue).Date - 1) mod 7 + 1;
end;

procedure aaDecodeDateIsoWeek(const AValue: TDateTime; out AYear, AWeekOfYear,
  ADayOfWeek: Word);
const
  CDayMap: array [1..7] of Word = (7, 1, 2, 3, 4, 5, 6);
  DayMonday = 1;
  DayTuesday = 2;
  DayWednesday = 3;
  DayThursday = 4;
  DayFriday = 5;
  DaySaturday = 6;
  DaySunday = 7;
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
    aaDecodeDateIsoWeek(LStart - 1, AYear, AWeekOfYear, LDay)
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

function aaWeek(const DateTime: TDateTime): Word;
const
  CDayMap: array [1..7] of Word = (7, 1, 2, 3, 4, 5, 6);
  DayMonday = 1;
  DayTuesday = 2;
  DayWednesday = 3;
  DayThursday = 4;
  DayFriday = 5;
  DaySaturday = 6;
  DaySunday = 7;
var
  LDayOfYear: Integer;
  ADayOfWeek, LYear, LMonth, LDay: Word;
  LStart: TDateTime;
  LStartDayOfWeek, LEndDayOfWeek: Word;
  LLeap: Boolean;
begin
  LLeap := DecodeDateFully(DateTime, LYear, LMonth, LDay, ADayOfWeek);
  ADayOfWeek := CDayMap[ADayOfWeek];
  LStart := EncodeDate(LYear, 1, 1);
  LDayOfYear := Trunc(DateTime - LStart + 1);
  LStartDayOfWeek := DayOfTheWeek(LStart);
  Result := 1;
  Dec(LDayOfYear);
  while (LDayOfYear > 0) do
  begin
   if (LStartDayOfWeek < 7) then
    Inc(LStartDayOfWeek)
   else
   begin
    LStartDayOfWeek := 1;
    Inc(Result);
   end;
   Dec(LDayOfYear);
  end;
end;

function aaISOWeek(const DateTime: TDateTime): Word;
var
  LYear, LDOW: Word;
begin
  aaDecodeDateIsoWeek(DateTime, LYear, Result, LDOW);
end;

function HourOf(const AValue: TDateTime): Word;
var
  LMinute, LSecond, LMilliSecond: Word;
begin
  DecodeTime(AValue, Result, LMinute, LSecond, LMilliSecond);
end;

function HourOfTheDay(const AValue: TDateTime): Word;
begin
  Result := HourOf(AValue);
end;

{ TDateFormater }

constructor TDateFormater.Create(DateFormat: WideString);
begin
  SetLength(FDateFormat,0);
  ParseDateFormat(DateFormat);
end;

destructor TDateFormater.Destroy;
begin
  SetLength(FDateFormat,0);
  inherited;
end;

procedure TDateFormater.ParseDateFormat(const DateFormatStr: WideString);
var
  i,j,L:  integer;
  start:  integer;
  s:      WideString;
  dft: TDateFormatType;
  charsLen: integer;
  isQuotedText: boolean;
  isDoubleQuotedText: boolean;
begin
 i := 0;
 start := 1;
 isQuotedText := false;
 isDoubleQuotedText := false;
 L := Length(DateFormatStr);
 while i < L do
  begin
   inc(i);
   // Quoted Text...
   if (DateFormatStr[i] = '''') or (DateFormatStr[i] = '"') then
    if isQuotedText or isDoubleQuotedText then
     begin
      if (DateFormatStr[i] = '''') and isQuotedText or
         (DateFormatStr[i] = '"') and isDoubleQuotedText then
       begin
        // Close QuotedText or DoubleQuotedText
        SetLength(FDateFormat, Length(FDateFormat)+1);
        FDateFormat[Length(FDateFormat)-1].TokenType := dfText;
        FDateFormat[Length(FDateFormat)-1].text :=
          Copy(DateFormatStr, start, i-start);
        if DateFormatStr[i] = '"' then
          isDoubleQuotedText := false
        else
          isQuotedText := false;
        start := i + 1;
        continue;
       end
     end
    else
     begin
      if start <> i then
       begin
        // close previous Section 'Text'
        SetLength(FDateFormat, Length(FDateFormat)+1);
        FDateFormat[Length(FDateFormat)-1].TokenType := dfText;
        FDateFormat[Length(FDateFormat)-1].text :=
          Copy(DateFormatStr, start, i-start);
       end;

      start := i + 1;
      if DateFormatStr[i] = '"' then
        isDoubleQuotedText := true
      else
        isQuotedText := true;
      continue;
     end;
   if isQuotedText or isDoubleQuotedText then continue;

   // look on 4-5 next chars
   charsLen := min(DateFormatReservedWordsMaxLength,L+1-i);
   for j:=charsLen downto 1 do
    begin
     s := Copy(DateFormatStr, i, j);
     dft := GetReservedWord(s);
     // Is it Reserded word ?
     if dft <> dfText then
      begin
       if i <> start then
        begin
         SetLength(FDateFormat, Length(FDateFormat)+1);
         FDateFormat[Length(FDateFormat)-1].TokenType := dfText;
         FDateFormat[Length(FDateFormat)-1].text :=
           copy(DateFormatStr, start, i-start);
        end;
       SetLength(FDateFormat, Length(FDateFormat)+1);
       FDateFormat[Length(FDateFormat)-1].TokenType := dft;
       FDateFormat[Length(FDateFormat)-1].text :=
         copy(DateFormatStr, i, j);
       i := i + j - 1;
       start := i + 1;
       break;
      end;
    end;//for
  end;
 if i+1 <> start then
  begin
   SetLength(FDateFormat, Length(FDateFormat)+1);
   FDateFormat[Length(FDateFormat)-1].TokenType := dfText;
   FDateFormat[Length(FDateFormat)-1].text :=
     copy(DateFormatStr, start, i+1-start);
  end;
end;

function TDateFormater.GetReservedWord(const Text: WideString): TDateFormatType;
var i,n: integer;
    s: WideString;
begin
 n := DateFormatReservedWordsCount;
 s := WideUpperCase(Text);
 for i := 0 to DateFormatReservedWordsCount-1 do
   if (s = DateFormatReservedWords[i]) then
    begin
     n := i;
     break;
    end;
 Result := TDateFormatType(n);
end;

function TDateFormater.DebugGetTokenList: WideString;
var
 i: Integer;
begin
 Result := '';
 for i:=0 to Length(FDateFormat)-1 do
  begin
    Result := Result + IntToStr(i+1);
    if FDateFormat[i].TokenType = dfText then
      Result := Result + ' <dfText> = '''
    else
      Result := Result + ' <df' +
            DateFormatReservedWords[integer(FDateFormat[i].TokenType)] + '> = ''';
    Result := Result + FDateFormat[i].Text + ''''#13#10;
  end;
end;


procedure TDateFormater.ConvertStrToWord(
                     const MaxSigns: Integer;
                     const Str:      WideString;
                     var Start:      Integer;
                     var w:          Word
                    );
var l,s,n: Integer;
begin
 n := 1;
 s := Start;
 Inc(Start);
 l := Length(str);
 while (Start <= l) and (n < MaxSigns) do
  begin
   if (not (AnsiChar(Str[Start]) in ['0'..'9'])) then
    break;
   Inc(Start);
   Inc(n);
  end;
 w := StrToInt(Copy(Str,s,n));
end; // ConvertStrToWord


procedure TDateFormater.ConvertRMToWord(
                 const Str:      WideString;
                 var Start:      Integer;
                 var w:          Word
                );
var l,s,n: Integer;
begin
{
  'I':    w := 1;
  'II':   w := 2;
  'III':  w := 3;
  'IV':   w := 4;
  'V':    w := 5;
  'VI':   w := 6;
  'VII':  w := 7;
  'VIII': w := 8;
  'IX':   w := 9;
  'X':    w := 10;
  'XI':   w := 11;
  'XII':  w := 12
}
 n := 1;
 s := Start;
 Inc(Start);
 l := Length(str);
 while (Start <= l) and (n < 4) do
  begin
   if (not (AnsiChar(Str[Start]) in ['I','V','X'])) then
    break;
   Inc(Start);
   Inc(n);
  end;
  case n of
   4:
     w := 8;
   3:
     begin
      if (Str[s] = 'I') then
       w := 3
      else
      if (Str[s] = 'V') then
       w := 7
      else
       w := 12;
     end;
   2:
     begin
      if (Str[s] = 'I') then
       w := 2
      else
      if (Str[s] = 'V') then
       w := 6
      else
       w := 11;
     end;
   1:
     begin
      if (Str[s] = 'I') then
       w := 1
      else
      if (Str[s] = 'V') then
       w := 5
      else
       w := 10;
     end
   else
    w := 0;
  end;
end; // ConvertRMToWord


function TDateFormater.ToDate(str: WideString): TDateTime;
var
 y,m,d,h,mi,s,z: word;
 i, l, start: Integer;
begin
 y:=0; m:=0; d:=0;
 h:=0; mi:=0; s:=0; z := 0;
 l := Length(FDateFormat)-1;
 // First WideChar
 start := 1;
  for i:=0 to l do
  begin
   case FDateFormat[i].TokenType of
     dfYYYY,
     dfYEAR:   begin
                y := StrToInt(copy(str,start,4));
                Inc(Start,4);
               end;
     dfYY:     begin
                y := StrToInt(copy(str,start,2));
                Inc(Start,2);
                if y < (TwoDigitYearCenturyWindow mod 100) then
                  y := y + 100;
                y := y + (TwoDigitYearCenturyWindow div 100) * 100; // + 1900
               end;

     dfQ:      begin
                m := (StrToInt(copy(str,start,1))-1)*3;
                Inc(Start,1);
               end;

     {dfMONTH:  begin
                m := (StrToInt(copy(str,start,1))-1)*3;
                Inc(Start,1);
                m:=StrToDateTime
               end;}
     //dfMON:    s := FormatDateTime('mmm',dt);
     dfM,dfMM:
                ConvertStrToWord(2,str,start,m);
     dfRM:
                ConvertRMToWord(str,start,m);

     //dfDDD:    s := Format('%d',[DayOfTheYear(dt)]);
     dfD,dfDD:
                ConvertStrToWord(2,str,start,d);
     //dfDAY:    s:=FormatDateTime('dddd',dt);
     //dfDY:     s:=FormatDateTime('ddd',dt);
     //dfD:      s := Format('%d',[DayOfTheWeek(dt)]);

     dfH12,
     dfH,
     dfHH12,
     dfHH,
     dfHH24,dfH24:
                ConvertStrToWord(2,str,start,h);

     dfNN,dfN:
                ConvertStrToWord(2,str,start,mi);

     dfSS,dfS:
                ConvertStrToWord(2,str,start,s);

     dfZZZ,dfZ:
                ConvertStrToWord(3,str,start,z);


     dfAMPM:   begin
                if WideUpperCase(copy(str,start,2))='PM' then
                 h := h + 12
                else
                 if WideUpperCase(copy(str,start,2))<>'AM' then
                  raise ESQLMemException.Create(30129, ErrorGAmPmExpected, [copy(str,start,2)]);
                Inc(Start,2);
               end;

     dfText:   begin
                Inc(Start, Length(FDateFormat[i].Text));
               end;
     else
      Inc(Start, Length(FDateFormat[i].Text));
      //raise Exception.Create('Unsupported DateFormatType');
   end;
  end;
  if (y=0) or (m=0) or (d=0) then
   begin
     y:=1899; m:=12; d:=30;
   end;
 Result := EncodeDate(y,m,d) + EncodeTime(h,mi,s,z);
end;

function TDateFormater.TOString(dt: TDateTime): WideString;
var
 i: Integer;
 s: WideString;
begin
 Result := '';
 for i:=0 to Length(FDateFormat)-1 do
  begin
   case FDateFormat[i].TokenType of
     dfYYYY,
     dfYEAR:   s := FormatDateTime('yyyy',dt);
     dfYY:     s := FormatDateTime('yy',dt);

     dfQ:      s := Format('%d',[(((MonthOf(dt)-1) div 3) + 1)]);

     dfMONTH:  s := FormatDateTime('mmmm',dt);
     dfMON:    s := FormatDateTime('mmm',dt);
     dfMM:     s := FormatDateTime('mm',dt);
     dfM:      s := FormatDateTime('m',dt);
     dfRM:     case MonthOf(dt) of
                01: s := 'I';
                02: s := 'II';
                03: s := 'III';
                04: s := 'IV';
                05: s := 'V';
                06: s := 'VI';
                07: s := 'VII';
                08: s := 'VIII';
                09: s := 'IX';
                10: s := 'X';
                11: s := 'XI';
                12: s := 'XII';
               end;

     dfDDD:    s := Format('%d',[DayOfTheYear(dt)]);
     dfDD:     s := FormatDateTime('dd',dt);
     dfD:      s := FormatDateTime('d',dt);
     dfDAY:    s:=FormatDateTime('dddd',dt);
     dfDY:     s:=FormatDateTime('ddd',dt);
     dfDW:     s := Format('%d',[aaDayOfTheWeek(dt)]);

     dfHH24:   s := FormatDateTime('hh',dt);
     dfHH,
     dfHH12:   s := Format('%.2d', [HourOfTheDay(dt) mod 12]);

     dfH24:   s := FormatDateTime('h',dt);
     dfH,
     dfH12:   s := Format('%d', [HourOfTheDay(dt) mod 12]);

     dfNN:     s := FormatDateTime('nn',dt);
     dfN:     s := FormatDateTime('n',dt);

     dfSS:     s := FormatDateTime('ss',dt);
     dfS:      s := FormatDateTime('s',dt);

     dfZZZ:     s := FormatDateTime('zzz',dt);
     dfZ:      s := FormatDateTime('z',dt);

     dfAMPM:   begin
                 if HourOfTheDay(dt) < 12 then
                   s := AM
                 else
                   s := PM
               end;
     dfText:   s := FDateFormat[i].Text;
     else
      raise Exception.Create('Unknown DateFormatType');
   end;
   Result := Result + s;
  end;

end;


function TDateFormater.GetStringMaxSize: Integer;
var
 i, s: Integer;
begin
 Result := 0;
 for i:=0 to Length(FDateFormat)-1 do
  begin
   case FDateFormat[i].TokenType of
     dfYYYY,
     dfYEAR:   s := 4;
     dfYY:     s := 2;

     dfQ:      s := 1;

     dfMONTH:  s := 9;
     dfMON:    s := 3;
     dfMM:     s := 2;
     dfM:      s := 2;
     dfRM:     s := 2;
     dfDDD:    s := 3;
     dfDD:     s := 2;
     dfDAY:    s := 12;
     dfDY:     s := 3;
     dfD:      s := 2;
     dfDW:     s := 2;

     dfH24,
     dfH,
     dfH12,
     dfHH24,
     dfHH,
     dfHH12:   s := 2;

     dfNN,
     dfN:      s := 2;

     dfS,
     dfSS:     s := 2;

     dfZ,
     dfZZZ:    s := 3;

     dfAMPM:   s := 2;

     dfText:   s := length(FDateFormat[i].Text);
     else
      raise Exception.Create('Unknown DateFormatType');
   end;
   Result := Result + s;
  end;
end;


procedure TDateFormater.Assign(Source: TDateFormater);
var i,l: Integer;
begin
  if (Source = nil) then
    raise ESQLMemException.Create(12200,ErrorLNilPointer);
  if (Self.ClassName <> Source.ClassName) then
    raise ESQLMemException.Create(12201,ErrorLErrorInAssignInvalidClass,
      [Self.ClassName,Source.ClassName]);
  l := Length(Source.FDateFormat);
  SetLength(FDateFormat,l);
  for i := 0 to l-1 do
   begin
    FDateFormat[i].TokenType := Source.FDateFormat[i].TokenType;
    FDateFormat[i].Text := Source.FDateFormat[i].Text;
   end;
end; // Assign


var i: integer;
begin
  // INIT DateFormatReservedWordsMaxLength value

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemDateFormat> init started');
{$ENDIF}

  DateFormatReservedWordsMaxLength := 0;
  for i:=0 to DateFormatReservedWordsCount-1 do
   if length(DateFormatReservedWords[i]) > DateFormatReservedWordsMaxLength then
     DateFormatReservedWordsMaxLength := length(DateFormatReservedWords[i]);

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemDateFormat> init finished');
{$ENDIF}

end.

